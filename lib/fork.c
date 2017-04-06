/*
 * More-or-less Unix-compatible process fork and wait functions,
 * which PIOS implements completely in the user space C library.
 *
 * Copyright (C) 2010 Yale University.
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Primary author: Bryan Ford
 */

#include <inc/file.h>
#include <inc/stat.h>
#include <inc/unistd.h>
#include <inc/string.h>
#include <inc/syscall.h>
#include <inc/assert.h>
#include <inc/errno.h>
#include <inc/mmu.h>
#include <inc/vm.h>


#define ALLVA		((void*) VM_USERLO)
#define ALLSIZE		(VM_USERHI - VM_USERLO)

bool reconcile(pid_t pid, filestate *cfiles);
bool reconcile_inode(pid_t pid, filestate *cfiles, int pino, int cino);
bool reconcile_merge(pid_t pid, filestate *cfiles, int pino, int cino);

pid_t fork(void)
{
	int i;

	// Find a free child process slot.
	// We just use child process slot numbers as Unix PIDs,
	// even though child slots are process-local in PIOS
	// whereas PIDs are global in Unix.
	// This means that commands like 'ps' and 'kill'
	// have to be shell-builtin commands under PIOS.
	pid_t pid;
	for (pid = 1; pid < 256; pid++)
		if (files->child[pid].state == PROC_FREE)
			break;
	if (pid == 256) {
		warn("fork: no child process available");
		errno = EAGAIN;
		return -1;
	}

	// Set up the register state for the child
	struct procstate ps;
	memset(&ps, 0, sizeof(ps));

	// Use some assembly magic to propagate registers to child
	// and generate an appropriate starting eip
	int isparent;
	asm volatile(
		"	movl	%%esi,%0;"
		"	movl	%%edi,%1;"
		"	movl	%%ebp,%2;"
		"	movl	%%esp,%3;"
		"	movl	$1f,%4;"
		"	movl	$1,%5;"
		"1:	"
		: "=m" (ps.tf.regs.esi),
		  "=m" (ps.tf.regs.edi),
		  "=m" (ps.tf.regs.ebp),
		  "=m" (ps.tf.esp),
		  "=m" (ps.tf.eip),
		  "=a" (isparent)
		:
		: "ebx", "ecx", "edx");
	if (!isparent) {
		// Clear our child state array, since we have no children yet.
		memset(&files->child, 0, sizeof(files->child));
		files->child[0].state = PROC_RESERVED;
		for (i = 1; i < FILE_INODES; i++)
			if (fileino_alloced(i)) {
				files->fi[i].rino = i;	// 1-to-1 mapping
				files->fi[i].rver = files->fi[i].ver;
				files->fi[i].rlen = files->fi[i].size;
			}

		return 0;	// indicate that we're the child.
	}

	// Copy our entire user address space into the child and start it.
	ps.tf.regs.eax = 0;	// isparent == 0 in the child
	sys_put(SYS_REGS | SYS_COPY | SYS_START, pid, &ps,
		ALLVA, ALLVA, ALLSIZE);

	// Record the inode generation numbers of all inodes at fork time,
	// so that we can reconcile them later when we synchronize with it.
	memset(&files->child[pid], 0, sizeof(files->child[pid]));
	files->child[pid].state = PROC_FORKED;

	return pid;
}

pid_t
wait(int *status)
{
	return waitpid(-1, status, 0);
}

pid_t
waitpid(pid_t pid, int *status, int options)
{
	assert(pid >= -1 && pid < 256);

	// Find a process to wait for.
	// Of course for interactive or load-balancing purposes
	// we would like to have a way to wait for
	// whichever child process happens to finish first -
	// that requires a (nondeterministic) kernel API extension.
	if (pid <= 0)
		for (pid = 1; pid < 256; pid++)
			if (files->child[pid].state == PROC_FORKED)
				break;
	if (pid == 256 || files->child[pid].state != PROC_FORKED) {
		errno = ECHILD;
		return -1;
	}

	// Repeatedly synchronize with the chosen child until it exits.
	while (1) {
		// Wait for the child to finish whatever it's doing,
		// and extract its CPU and process/file state.
		struct procstate ps;
		sys_get(SYS_COPY | SYS_REGS, pid, &ps,
			(void*)FILESVA, (void*)VM_SCRATCHLO, PTSIZE);
		filestate *cfiles = (filestate*)VM_SCRATCHLO;

		// Did the child take a trap?
		if (ps.tf.trapno != T_SYSCALL) {
			// Yes - terminate the child WITHOUT reconciling,
			// since the child's results are probably invalid.
			warn("child %d took trap %d, eip %x\n",
				pid, ps.tf.trapno, ps.tf.eip);
			if (status != NULL)
				*status = WSIGNALED | ps.tf.trapno;

			done:
			// Clear out the child's address space.
			sys_put(SYS_ZERO, pid, NULL, ALLVA, ALLVA, ALLSIZE);
			files->child[pid].state = PROC_FREE;
			return pid;
		}

		// Reconcile our file system state with the child's.
		bool didio = reconcile(pid, cfiles);

		// Has the child exited gracefully?
		if (cfiles->exited) {
			if (status != NULL)
				*status = WEXITED | (cfiles->status & 0xff);
			goto done;
		}

		// If the child is waiting for new input
		// and the reconciliation above didn't provide anything new,
		// then wait for something new from OUR parent in turn.
		if (!didio)
			sys_ret();

		// Reconcile again, to forward any new I/O to the child.
		(void)reconcile(pid, cfiles);

		// Push the child's updated file state back into the child.
		sys_put(SYS_COPY | SYS_START, pid, NULL,
			(void*)VM_SCRATCHLO, (void*)FILESVA, PTSIZE);
	}
}

// Reconcile our file system state, whose metadata is in 'files',
// with the file system state of child 'pid', whose metadata is in 'cfiles'.
// Returns nonzero if any changes were propagated, false otherwise.
bool
reconcile(pid_t pid, filestate *cfiles)
{
	bool didio = 0;
	int i;

	// Compute a parent-to-child and child-to-parent inode mapping table.
	int p2c[FILE_INODES], c2p[FILE_INODES];
	memset(p2c, 0, sizeof(p2c)); memset(c2p, 0, sizeof(c2p));
	p2c[FILEINO_CONSIN] = c2p[FILEINO_CONSIN] = FILEINO_CONSIN;
	p2c[FILEINO_CONSOUT] = c2p[FILEINO_CONSOUT] = FILEINO_CONSOUT;
	p2c[FILEINO_ROOTDIR] = c2p[FILEINO_ROOTDIR] = FILEINO_ROOTDIR;

	// First make sure all the child's allocated inodes
	// have a mapping in the parent, creating mappings as needed.
	// Also keep track of the parent inodes we find mappings for.
	int cino;
	for (cino = 1; cino < FILE_INODES; cino++) {
		fileinode *cfi = &cfiles->fi[cino];
		if (cfi->de.d_name[0] == 0)
			continue;	// not allocated in the child
		if (cfi->mode == 0 && cfi->rino == 0)
			continue;	// existed only ephemerally in child
		if (cfi->rino == 0) {
			// No corresponding parent inode known: find/create one.
			// The parent directory should already have a mapping.
			if (cfi->dino <= 0 || cfi->dino >= FILE_INODES
				|| c2p[cfi->dino] == 0) {
				warn("reconcile: cino %d has invalid parent",
					cino);
				continue;	// don't reconcile it
			}
			cfi->rino = fileino_create(files, c2p[cfi->dino],
							cfi->de.d_name);
			if (cfi->rino <= 0)
				continue;	// no free inodes!
		}

		// Check the validity of the child's existing mapping.
		// If something's fishy, just don't reconcile it,
		// since we don't want the child to kill the parent this way.
		int pino = cfi->rino;
		fileinode *pfi = &files->fi[pino];
		if (pino <= 0 || pino >= FILE_INODES
				|| p2c[pfi->dino] != cfi->dino
				|| strcmp(pfi->de.d_name, cfi->de.d_name) != 0
				|| cfi->rver > pfi->ver
				|| cfi->rver > cfi->ver) {
			warn("reconcile: mapping %d/%d: "
				"dir %d/%d name %s/%s ver %d/%d(%d)",
				pino, cino, pfi->dino, cfi->dino,
				pfi->de.d_name, cfi->de.d_name,
				pfi->ver, cfi->ver, cfi->rver);
			continue;
		}

		// Record the mapping.
		p2c[pino] = cino;
		c2p[cino] = pino;
	}

	// Now make sure all the parent's allocated inodes
	// have a mapping in the child, creating mappings as needed.
	int pino;
	for (pino = 1; pino < FILE_INODES; pino++) {
		fileinode *pfi = &files->fi[pino];
		if (pfi->de.d_name[0] == 0 || pfi->mode == 0)
			continue; // not in use or already deleted
		if (p2c[pino] != 0)
			continue; // already mapped
		cino = fileino_create(cfiles, p2c[pfi->dino], pfi->de.d_name);
		if (cino <= 0)
			continue;	// no free inodes!
		cfiles->fi[cino].rino = pino;
		p2c[pino] = cino;
		c2p[cino] = pino;
	}

	// Finally, reconcile each corresponding pair of inodes.
	for (pino = 1; pino < FILE_INODES; pino++) {
		if (!p2c[pino])
			continue;	// no corresponding inode in child
		cino = p2c[pino];
		assert(c2p[cino] == pino);

		didio |= reconcile_inode(pid, cfiles, pino, cino);
	}

	return didio;
}

bool
reconcile_inode(pid_t pid, filestate *cfiles, int pino, int cino)
{
	assert(pino > 0 && pino < FILE_INODES);
	assert(cino > 0 && cino < FILE_INODES);
	fileinode *pfi = &files->fi[pino];
	fileinode *cfi = &cfiles->fi[cino];

	// Find the reference version number and length for reconciliation
	int rver = cfi->rver;
	int rlen = cfi->rlen;

	// Check some invariants that should hold between
	// the parent's and child's current version numbers and lengths
	// and the reference version number and length stored in the child.
	// XXX should protect the parent better from state corruption by child.
	assert(cfi->ver >= rver);	// version # only increases
	assert(pfi->ver >= rver);
	if (cfi->ver == rver)		// within a version, length only grows
		assert(cfi->size >= rlen);
	if (pfi->ver == rver)
		assert(pfi->size >= rlen);

	// Lab 4: insert your code here to reconcile the two inodes:
	// copy the parent's file to the child if only the parent's has changed,
	// copy the child's file to the parent if only the child's has changed,
	// and mark both files conflicted if both have been modified.
	// Then be sure to update the reconciliation state
	// so that the next reconciliation will start from this point.
	//
	// Note: if only one process has made an exclusive modification
	// that bumps the inode's version number,
	// and the other process has NOT bumped its inode's version number
	// but has performed append-only writes increasing the file's length,
	// that situation still constitutes a conflict
	// because we don't have a clean way to resolve it automatically.
	//warn("reconcile_inode not implemented");
	if(pfi->ver == cfi->rver && cfi->ver == cfi->rver){
		return reconcile_merge(pid, cfiles, pino, cino);
	}
	if((pfi->ver > cfi->rver || pfi->size > cfi->rlen) && (cfi->ver > cfi->rver || cfi->size > cfi->rlen)){
		pfi->mode |= S_IFCONF;
		cfi->mode |= S_IFCONF;
		return 1;
	}
	if(pfi->ver > cfi->rver || pfi->size > cfi->rlen){
		sys_put(SYS_COPY, pid, NULL, FILEDATA(pino),FILEDATA(cino),FILE_MAXSIZE);
		cfi->mode = pfi->mode;
		cfi->ver = pfi->ver;
		cfi->size = pfi->size;
	}else{
		sys_get(SYS_COPY, pid, NULL, FILEDATA(cino),FILEDATA(pino), FILE_MAXSIZE);
		pfi->mode = cfi->mode;
		pfi->ver = cfi->ver;
		pfi->size = cfi->size;
	}
	cfi->rver = pfi->ver;
	cfi->rlen = pfi->size;
	return 1;
}

bool
reconcile_merge(pid_t pid, filestate *cfiles, int pino, int cino)
{
	fileinode *pfi = &files->fi[pino];
	fileinode *cfi = &cfiles->fi[cino];
	assert(pino > 0 && pino < FILE_INODES);
	assert(cino > 0 && cino < FILE_INODES);
	assert(pfi->ver == cfi->ver);
	assert(pfi->mode == cfi->mode);

	if (!S_ISREG(pfi->mode))
		return 0;	// only regular files have data to merge

	// Lab 4: insert your code here to merge inclusive appends:
	// copy the parent's appends since last reconciliation into the child,
	// and the child's appends since last reconciliation into the parent.
	// Parent and child should be left with files of the same size,
	// although the writes they contain may be in a different order.
	// warn("reconcile_merge not implemented");
	if((pfi->size == cfi->rlen) && (cfi->size == cfi->rlen))
		return 1;

	void* tmpmem = (void*)(VM_SCRATCHLO + PTSIZE);	//Can't use VM_SCRATCHLO, cause the child process may use it for load elf concurrently..
	size_t cgrow = cfi->size - cfi->rlen;
	size_t pgrow = pfi->size - cfi->rlen;
	size_t newlen = cfi->rlen + cgrow + pgrow;

	sys_get(SYS_COPY, pid, NULL, FILEDATA(cino), tmpmem, FILE_MAXSIZE);
	memcpy(FILEDATA(pino) + pfi->size, tmpmem + cfi->rlen, cgrow);
	memcpy(tmpmem + cfi->size, FILEDATA(pino) + pfi->rlen, pgrow);
	pfi->size = newlen;
	cfi->size = newlen;
	cfi->rlen = newlen;
	sys_put(SYS_COPY, pid, NULL, tmpmem, FILEDATA(cino), FILE_MAXSIZE);
	return 1;
}

