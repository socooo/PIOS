/*
 * System call handling.
 *
 * Copyright (C) 1997 Massachusetts Institute of Technology
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Derived from the xv6 instructional operating system from MIT.
 * Adapted for PIOS by Bryan Ford at Yale University.
 */

#include <inc/x86.h>
#include <inc/string.h>
#include <inc/assert.h>
#include <inc/trap.h>
#include <inc/syscall.h>

#include <kern/cpu.h>
#include <kern/trap.h>
#include <kern/proc.h>
#include <kern/syscall.h>
#include <kern/net.h>
#include <kern/file.h>





// This bit mask defines the eflags bits user code is allowed to set.
#define FL_USER		(FL_CF|FL_PF|FL_AF|FL_ZF|FL_SF|FL_DF|FL_OF)


// During a system call, generate a specific processor trap -
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
	utf->trapno = trapno;
	utf->err = err;
	proc_ret(utf, 0);
}

// Recover from a trap that occurs during a copyin or copyout,
// by aborting the system call and reflecting the trap to the parent process,
// behaving as if the user program's INT instruction had caused the trap.
// This uses the 'recover' pointer in the current cpu struct,
// and invokes systrap() above to blame the trap on the user process.
//
// Notes:
// - Be sure the parent gets the correct trapno, err, and eip values.
// - Be sure to release any spinlocks you were holding during the copyin/out.
//
static void gcc_noreturn
sysrecover(trapframe *ktf, void *recoverdata)
{	
	cpu* c = cpu_cur();
	c->recover = NULL;
	trapframe* utf = (trapframe*) recoverdata;
	systrap(utf, ktf->trapno, ktf->err);
}

// Check a user virtual address block for validity:
// i.e., make sure the complete area specified lies in
// the user address space between VM_USERLO and VM_USERHI.
// If not, abort the syscall by sending a T_PGFLT to the parent,
// again as if the user program's INT instruction was to blame.
//
// Note: Be careful that your arithmetic works correctly
// even if size is very large, e.g., if uva+size wraps around!
//
static void checkva(trapframe *utf, uint32_t uva, size_t size)
{
	if(uva < VM_USERLO || uva >= VM_USERHI || uva + size > VM_USERHI){
		systrap(utf, T_PGFLT, 0);
	}
}

// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout,
			void *kva, uint32_t uva, size_t size)
{
	checkva(utf, uva, size);
	cpu* c = cpu_cur();
	assert(c->recover == NULL);
	c->recover = sysrecover;
	// Now do the copy, but recover from page faults.
	if(copyout)
		memmove((void*)uva, kva, size);
	else
		memmove(kva, (void*)uva, size);

	c->recover = NULL;
}

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
	// Print the string supplied by the user: pointer in EBX
	char string[CPUTS_MAX + 1];
	usercopy(tf, 0, string, tf->regs.ebx, CPUTS_MAX);
	cprintf("%s", string);

	trap_return(tf);	// syscall completed
}

static void
do_get(trapframe *tf, uint32_t cmd){
	uint32_t flag = tf->regs.eax;
	size_t size = tf->regs.ecx;
	uint32_t source_add = tf->regs.esi;
	uint32_t dest_add = tf->regs.edi;
	proc* parent = proc_cur();
	proc* child = parent->child[tf->regs.edx];
	procstate *get_state = (procstate*)tf->regs.ebx;
	if(!child)
		child = &proc_null;
	/*assert(size%PTSIZE == 0);
	assert(((uint32_t)source_add)%PTSIZE == 0);
	assert(((uint32_t)dest_add)%PTSIZE == 0);
	*/
	if(child->state != PROC_STOP){
		proc_wait(parent, child, tf);
	}
	if(flag& SYS_REGS){
		usercopy(tf, 1, &child->sv.tf, (uint32_t)(&get_state->tf), sizeof(trapframe));
	}
	switch(flag & SYS_MEMOP){
	case SYS_ZERO:
		assert(size%PTSIZE == 0);
		assert((dest_add)%PTSIZE == 0);
		checkva(tf, dest_add, size);
		pmap_remove(parent->pdir, dest_add, size);
		break;
	case SYS_COPY:
		assert(size%PTSIZE == 0);
		assert((source_add)%PTSIZE == 0);
		assert((dest_add)%PTSIZE == 0);
		checkva(tf, source_add, size);
		checkva(tf, dest_add, size);
		pmap_copy(child->pdir, source_add, parent->pdir, dest_add, size);
		break;
	default:
		break;
	}
	
	if((flag & SYS_MEMOP) == SYS_MERGE){
		assert(size%PTSIZE == 0);
		assert((source_add)%PTSIZE == 0);
		assert((dest_add)%PTSIZE == 0);
		checkva(tf, source_add, size);
		checkva(tf, dest_add, size);		
		pmap_merge(child->rpdir, child->pdir, source_add, parent->pdir, dest_add, size);
	}

	switch(flag & 0x700){
	case SYS_PERM:
		pmap_setperm(parent->pdir, dest_add, size, 0);
		break;
	case SYS_PERM | SYS_READ:
		pmap_setperm(parent->pdir, dest_add, size,  SYS_READ);
		break;
	case SYS_PERM | SYS_READ | SYS_WRITE:
		pmap_setperm(parent->pdir, dest_add, size,  SYS_RW);
		break;
	default:
		break;
	}
	trap_return(tf);
}

static void
do_put(trapframe *tf, uint32_t cmd){	
	uint32_t flag = tf->regs.eax;
	size_t size = tf->regs.ecx;
	uint32_t source_add = tf->regs.esi;
	uint32_t dest_add = tf->regs.edi;
	proc* parent = proc_cur();
	proc* child = parent->child[tf->regs.edx];
	procstate *put_state = (procstate*)tf->regs.ebx;
	if(!child){
		child = proc_alloc(parent, tf->regs.edx);
	}
	if(child->state != PROC_STOP){
		proc_wait(parent, child, tf);
	}
	if(tf->regs.eax & SYS_REGS){
		usercopy(tf, false, &child->sv.tf, (uint32_t)(&put_state->tf), sizeof(trapframe));
		child->sv.tf.cs = CPU_GDT_UCODE | 3;
		child->sv.tf.ds = CPU_GDT_UDATA | 3;
		child->sv.tf.es = CPU_GDT_UDATA | 3;
		child->sv.tf.ss = CPU_GDT_UDATA | 3;
		child->sv.tf.eflags &= FL_USER;
		child->sv.tf.eflags |= FL_IF;
		child->sv.tf.eip = put_state->tf.eip;
		child->sv.tf.esp = put_state->tf.esp;
	}
	switch(flag & SYS_MEMOP){
	case SYS_ZERO:
		assert(size%PTSIZE == 0);
		assert((dest_add)%PTSIZE == 0);
		checkva(tf, dest_add, size);
		pmap_remove(child->pdir, dest_add, size);
		break;
	case SYS_COPY:
		assert(size%PTSIZE == 0);
		assert((source_add)%PTSIZE == 0);
		assert((dest_add)%PTSIZE == 0);
		checkva(tf, source_add, size);
		checkva(tf, dest_add, size);
		if(!pmap_copy(parent->pdir, source_add, child->pdir, dest_add, size))
			panic("pmap_copy does not finished.\n");
		break;
	default:
		break;
	}
	if(flag & SYS_SNAP){
		assert(size%PTSIZE == 0);
		assert((source_add)%PTSIZE == 0);
		assert((dest_add)%PTSIZE == 0);
		checkva(tf, source_add, size);
		checkva(tf, dest_add, size);
		if(!pmap_copy(child->pdir, source_add, child->rpdir, dest_add, size))
			panic("pmap_copy does not finished.\n");
	}
	switch(flag & 0x700){
	case SYS_PERM:
		pmap_setperm(child->pdir, dest_add, size, 0);
		break;
	case SYS_PERM | SYS_READ:
		pmap_setperm(child->pdir, dest_add, size,SYS_READ);
		break;
	case SYS_PERM | SYS_READ | SYS_WRITE:
		pmap_setperm(child->pdir, dest_add, size, SYS_RW);
		break;
	default:
		break;
	}
	if(tf->regs.eax & SYS_START){
		proc_ready(child);
	}
	trap_return(tf);
}

static void
do_ret(trapframe *tf){
	if(proc_cur() == proc_root)
		file_io(tf);
	proc_ret(tf, 1);
}
// Common function to handle all system calls -
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.
void
syscall(trapframe *tf)
{
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
	switch (cmd & SYS_TYPE) {
	case SYS_CPUTS:
		do_cputs(tf, cmd);
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	case SYS_PUT:
		do_put(tf, cmd);
	case SYS_GET:
		do_get(tf, cmd);
	case SYS_RET:
		do_ret(tf);
	default:
		panic("Undefine system call.\n");		// handle as a regular trap
	}
}

