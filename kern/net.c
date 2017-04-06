/*
 * Networking code implementing cross-node process migration.
 *
 * Copyright (C) 2010 Yale University.
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Primary author: Bryan Ford
 */

#include <inc/string.h>

#include <kern/cpu.h>
#include <kern/spinlock.h>
#include <kern/trap.h>
#include <kern/proc.h>
#include <kern/net.h>

#include <dev/e100.h>


uint8_t net_node;	// My node number - from net_mac[5]
uint8_t net_mac[6];	// My MAC address from the Ethernet card

spinlock net_lock;
proc *net_migrlist;	// List of currently migrating processes
proc *net_pulllist;	// List of processes currently pulling a page

#define NET_ETHERTYPE	0x9876	// Claim this ethertype for our packets


void net_txmigrq(proc *p);
void net_rxmigrq(net_migrq *migrq);
void net_txmigrp(uint8_t dstnode, uint32_t prochome);
void net_rxmigrp(net_migrp *migrp);

void net_pull(proc *p, uint32_t rr, void *pg, int pglevel);
void net_txpullrq(proc *p);
void net_rxpullrq(net_pullrq *rq);
void net_txpullrp(uint8_t rqnode, uint32_t rr, int pglev, int part, void *pg);
void net_rxpullrp(net_pullrphdr *rp, int len);
bool net_pullpte(proc *p, uint32_t *pte, int pglevel);

void
net_init(void)
{
	if (!cpu_onboot())
		return;

	spinlock_init(&net_lock);

	if (!e100_present) {
		cprintf("No network card found; networking disabled\n");
		return;
	}

	// Ethernet card should already have been initialized
	assert(net_mac[0] != 0 && net_mac[5] != 0);
	net_node = net_mac[5];	// Last byte in MAC addr is our node number
}

// Setup the Ethernet header in a packet to be sent.
static void
net_ethsetup(net_ethhdr *eth, uint8_t destnode)
{
	assert(destnode > 0 && destnode <= NET_MAXNODES);
	assert(destnode != net_node);	// soliloquy isn't a virtue here

	memcpy(eth->dst, net_mac, 6);	eth->dst[5] = destnode;
	memcpy(eth->src, net_mac, 6);
	eth->type = htons(NET_ETHERTYPE);
}

// Just a trivial wrapper for the e100 driver's transmit function.
// The two buffers provided get concatenated to form the transmitted packet;
// this is just a convenience (and optimization) for when the caller has a
// "packet head" and a "packet body" coming from different memory areas.
// To transmit from just one buffer, set blen to zero.
int net_tx(void *hdr, int hlen, void *body, int blen)
{
	//cprintf("net_tx %d+%d\n", hlen, blen);
	return e100_tx(hdr, hlen, body, blen);
}

// The e100 network interface device driver calls this
// from its interrupt handler whenever it receives a packet.
void
net_rx(void *pkt, int len)
{
	//cprintf("net_rx len %d\n", len);
	if (len < sizeof(net_hdr)) {
		warn("net_rx: runt packet (%d bytes)", len);
		return;	// drop
	}
	net_hdr *h = pkt;
	if (memcmp(h->eth.dst, net_mac, 6) != 0) {	// is it for us?
		warn("net_rx: stray packet received for someone else");
		return;	// drop
	}
	if (memcmp(h->eth.src, net_mac, 5) != 0		// from a node we know?
			|| h->eth.src[5] < 1 || h->eth.src[5] > NET_MAXNODES) {
		warn("net_rx: stray packet received from outside cluster");
		return; // drop
	}
	if (h->eth.type != htons(NET_ETHERTYPE)) {
		warn("net_rx: unrecognized ethertype %x", ntohs(h->eth.type));
		return;	// drop
	}

	// Lab 5: your code here to process received messages.
	warn("net_rx: received a message; now what?");
}

// Called by trap() on every timer interrupt,
// so that we can periodically retransmit lost packets.
void
net_tick()
{
	if (!cpu_onboot())
		return;		// count only one CPU's ticks

	static int tick;
	if (++tick & 63)
		return;

	spinlock_acquire(&net_lock);

	// Lab 5: your code here.
	warn("net_tick() should probably be doing something.");

	spinlock_release(&net_lock);
}

// Whenever we send a page containing remote refs to a new node,
// we call this function to account for this sharing
// by ORing the destination node into the pageinfo's sharemask.
void
net_rrshare(void *page, uint8_t dstnode)
{
	pageinfo *pi = mem_ptr2pi(page);
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
	assert(pi != mem_ptr2pi(pmap_zero));	// No remote refs to zero page!

	assert(dstnode > 0 && dstnode <= NET_MAXNODES);
	assert(NET_MAXNODES <= sizeof(pi->shared)*8);
	pi->shared |= 1 << (dstnode-1);		// XXX lock_or?
}

// Called from syscall handlers to migrate to another node if we need to.
// The 'node' argument is the node to migrate to.
// The 'entry' argument is as for proc_save().
void gcc_noinline
net_migrate(trapframe *tf, uint8_t dstnode, int entry)
{
	proc *p = proc_cur();
	proc_save(p, tf, entry);	// save current process's state

	assert(dstnode > 0 && dstnode <= NET_MAXNODES && dstnode != net_node);
	//cprintf("proc %x at eip %x migrating to node %d\n",
	//	p, p->tf.eip, dstnode);

	// Account for the fact that we've shared this process,
	// to make sure the remote refs it contains don't go away.
	// (In the case of a proc it won't anyway, but just for consistency.)
	net_rrshare(p, dstnode);

	// Lab 5: insert your code here to place process in PROC_MIGR state,
	// add it to the list of migrating processes (net_migrlist),
	// and call net_txmigrq() to send out a migrate request packet.
	panic("net_migrate not implemented");
}

// Transmit a process migration request message
// using the state in process 'p'.
// This function does not cause p's state to change,
// since we don't know if this migration request will be received
// until we get a reply via net_rxmigrp().
void
net_txmigrq(proc *p)
{
	assert(p->state == PROC_MIGR);
	assert(spinlock_holding(&net_lock));

	// Lab 5: insert code to create and send out a migrate request
	// for a process waiting to migrate (in the PROC_MIGR state).
	warn("net_txmigrq not implemented");
}

// This gets called by net_rx() to process a received migrq packet.
void net_rxmigrq(net_migrq *migrq)
{
	uint8_t srcnode = migrq->eth.src[5];
	assert(srcnode > 0 && srcnode <= NET_MAXNODES);

	// Do we already have a local proc corresponding to the remote one?
	proc *p = NULL;
	if (RRNODE(migrq->home) == net_node) {	// Our proc returning home
		p = mem_ptr(RRADDR(migrq->home));
	} else {	// Someone else's proc - have we seen it before?
		pageinfo *pi = mem_rrlookup(migrq->home);
		p = pi != NULL ? mem_pi2ptr(pi) : NULL;
	}
	if (p == NULL) {			// Unrecognized proc RR
		p = proc_alloc(NULL, 0);	// Allocate new local proc
		p->state = PROC_AWAY;		// Pretend it's been away
		p->home = migrq->home;		// Record where proc originated
		mem_rrtrack(migrq->home, mem_ptr2pi(p)); // Track for future
	}
	assert(p->home == migrq->home);

	// If the proc isn't in the AWAY state, assume it's a duplicate packet.
	// XXX not very robust - should probably have sequence numbers too.
	if (p->state != PROC_AWAY) {
		warn("net_rxmigrq: proc %x is already local");
		return net_txmigrp(srcnode, p->home);
	}

	// Copy the CPU state and pdir RR into our proc struct
	p->sv = migrq->save;
	p->rrpdir = migrq->pdir;
	p->pullva = VM_USERLO;	// pull all user space from USERLO to USERHI

	// Acknowledge the migration request so the source node stops resending
	net_txmigrp(srcnode, p->home);

	// Free the proc's old page directory and allocate a fresh one.
	// (The old pdir will hang around until all shared copies disappear.)
	mem_decref(mem_ptr2pi(p->pdir), pmap_freepdir);
	p->pdir = pmap_newpdir();	assert(p->pdir);

	// Now we need to pull over the page directory next,
	// before we can do anything else.
	// Just pull it straight into our proc's page directory;
	// XXX first free old contents of pdir
	net_pull(p, p->rrpdir, p->pdir, PGLEV_PDIR);
}

// Transmit a migration reply to a given node, for a given proc's home RR
void
net_txmigrp(uint8_t dstnode, uint32_t prochome)
{
	// Lab 5: insert code to create and send out a migrate reply.
	warn("net_txmigrp not implemented");
}

// Receive a migrate reply message.
void net_rxmigrp(net_migrp *migrp)
{
	uint8_t msgsrcnode = migrp->eth.src[5];
	assert(msgsrcnode > 0 && msgsrcnode <= NET_MAXNODES);

	// Lab 5: insert code to process a migrate reply message.
	// Look for the appropriate migrating proc in the migrlist,
	// and if it's there, remove it and mark it PROC_AWAY.
	// Remember that duplicate packets can arrive due to retransmissions:
	// nothing bad should happen if there's no such proc in the migrlist.
	warn("net_rxmigrp not implemented");
}

// Pull a page via a remote ref and put process p to sleep waiting for it.
void
net_pull(proc *p, uint32_t rr, void *pg, int pglevel)
{
	//cprintf("net_pull: proc %x rr %x -> %x level %d\n",
	//	p, rr, pg, pglevel);
	uint8_t dstnode = RRNODE(rr);
	assert(dstnode > 0 && dstnode <= NET_MAXNODES);
	assert(dstnode != net_node);
	assert(pglevel >= 0 && pglevel <= 2);

	// Lab 5: insert code here to put the process into the PROC_PULL state,
	// save in the proc structure all information needed for the pull,
	// and transmit a pull message using net_txpullrq().
	warn("net_pull not implemented");
}

// Transmit a page pull request on behalf of some process.
void
net_txpullrq(proc *p)
{
	assert(p->state == PROC_PULL);
	assert(spinlock_holding(&net_lock));

	// Lab 5: transmit or retransmit a pull request (net_pullrq).
	warn("net_txpullrq not implemented");
}

// Process a page pull request we've received.
void
net_rxpullrq(net_pullrq *rq)
{
	assert(rq->type == NET_PULLRQ);
	uint8_t rqnode = rq->eth.src[5];
	assert(rqnode > 0 && rqnode <= NET_MAXNODES && rqnode != net_node);

	// Validate the requested node number and page address.
	uint32_t rr = rq->rr;
	if (RRNODE(rr) != net_node) {
		warn("net_rxpullrq: pull request came to wrong node!?");
		return;
	}
	uint32_t addr = RRADDR(rr);
	pageinfo *pi = mem_phys2pi(addr);
	if (pi <= &mem_pageinfo[0] || pi >= &mem_pageinfo[mem_npage]) {
		warn("net_rxpullrq: pull request for invalid page %x", addr);
		return;
	}
	if (pi->refcount == 0) {
		warn("net_rxpullrq: pull request for free page %x", addr);
		return;
	}
	if (pi->home != 0) {
		warn("net_rxpullrq: pull request for unowned page %x", addr);
		return;
	}
	void *pg = mem_pi2ptr(pi);

	// OK, looks legit as far as we can tell.
	// Mark the page shared, since we're about to share it.
	net_rrshare(pg, rqnode);

	// Send back whichever of the three page parts the caller still needs.
	// (We must divide the page into parts to fit into Ethernet packets.)
	// Lab 5: use net_txpullrp() to send the appropriate parts of the page.
	warn("net_rxpullrq not fully implemented");

	// Mark this page shared with the requesting node.
	// (XXX might be necessarily only for pdir/ptab pages.)
	assert(NET_MAXNODES <= sizeof(pi->shared)*8);
	pi->shared |= 1 << (rqnode-1);
}

static const int partlen[3] = {
	NET_PULLPART0, NET_PULLPART1, NET_PULLPART2};

void
net_txpullrp(uint8_t rqnode, uint32_t rr, int pglev, int part, void *pg)
{
	// Find appropriate part of this page
	void *data = pg + NET_PULLPART*part;
	int len = partlen[part];
	assert(len <= NET_PULLPART);
	assert((len & 3) == 0);		// must contain only whole PTEs

	// If we're transmitting part of a page directory or page table,
	// then first convert all PTEs into remote references.
	// XXX it's not ideal that we just believe the requestor's word
	// about whether this is a page table or regular page;
	// would be better if we kept our own type info in struct pageinfo.
	int nrrs = len/4;
	uint32_t rrs[nrrs];
	if (pglev > 0) {
		const uint32_t *pt = data;
		// Lab 5: convert the PDEs or PTEs in pt[0..nrrs-1]
		// into corresponding remote references in rrs[0..nrrs-1].
		// For PDEs/PTEs pointing to PMAP_ZERO,
		// produce an RR that is zero except for the RR_REMOTE
		// and the PDE/PTE's nominal permissions.
		// For page directories, just produce zero RRs
		// for PDEs representing the non-user portions
		// of the address space.
		warn("net_txpullrq not fully implemented");
		data = rrs;	// Send RRs instead of original page.
	}

	// Build and send the message
	net_pullrphdr rph;
	net_ethsetup(&rph.eth, rqnode);
	rph.type = NET_PULLRP;
	rph.rr = rr;
	rph.part = part;
	net_tx(&rph, sizeof(rph), data, len);
}

void
net_rxpullrp(net_pullrphdr *rp, int len)
{
	static const int partlen[3] = {
		NET_PULLPART0, NET_PULLPART1, NET_PULLPART2};

	assert(rp->type == NET_PULLRP);

	spinlock_acquire(&net_lock);

	// Find the process waiting for this pull reply, if any.
	proc *p, **pp;
	for (pp = &net_pulllist; (p = *pp) != NULL; pp = &p->pullnext) {
		assert(p->state == PROC_PULL);
		if (p->pullrr == rp->rr)
			break;
	}
	if (p == NULL) {	// Probably a duplicate due to retransmission
		//warn("net_rxpullrp: no process waiting for RR %x", rp->rr);
		return spinlock_release(&net_lock);
	}
	int part = rp->part;
	if (part < 0 || part > 2) {
		warn("net_rxpullrp: invalid part number %d", part);
		return spinlock_release(&net_lock);
	}
	if (p->arrived & (1 << rp->part)) {
		warn("net_rxpullrp: part %d already arrived", part);
		return spinlock_release(&net_lock);
	}
	int datalen = len - sizeof(*rp);
	if (datalen != partlen[rp->part]) {
		warn("net_rxpullrp: part %d wrong size %d", part, datalen);
		return spinlock_release(&net_lock);
	}

	// Fill in the appropriate part of the page.
	memcpy(p->pullpg + NET_PULLPART*part, rp->data, datalen);
	p->arrived |= 1 << rp->part;	// Mark this part arrived.
	if (p->arrived == 7)		// All three parts arrived?
		*pp = p->pullnext;	// Remove from list of waiting procs.

	spinlock_release(&net_lock);

	if (p->arrived != 7)
		return;			// Wait for remaining parts

	// If this was a page directory, reinitialize the kernel portions.
	if (p->pglev == PGLEV_PDIR) {
		uint32_t *pdir = p->pullpg;
		int i;
		for (i = 0; i < NPDENTRIES; i++) {
			if (i == PDX(VM_USERLO))	// skip user area
				i = PDX(VM_USERHI);
			pdir[i] = pmap_bootpdir[i];
		}
	}

	// Done - what else does this proc need to pull before it can run?
	// Remove/disable this code if the VM system supports pull-on-demand.
	while (p->pullva < VM_USERHI) {

		// Pull or traverse PDE to find page table.
		uint32_t *pde = &p->pdir[PDX(p->pullva)];
		if (*pde & PTE_REMOTE) {	// Need to pull remote ptab?
			if (!net_pullpte(p, pde, PGLEV_PTAB))
				return; // Wait for the pull to complete.
		}
		assert(!(*pde & PTE_REMOTE));
		if (PGADDR(*pde) == PTE_ZERO) {		// Skip empty PDEs
			p->pullva = PTADDR(p->pullva + PTSIZE);
			continue;
		}
		assert(PGADDR(*pde) != 0);
		uint32_t *ptab = mem_ptr(PGADDR(*pde));

		// Pull or traverse PTE to find page.
		uint32_t *pte = &ptab[PTX(p->pullva)];
		if (*pte & PTE_REMOTE) {	// Need to pull remote page?
			if (!net_pullpte(p, pte, PGLEV_PAGE))
				return;	// Wait for the pull to complete.
		}
		assert(!(*pte & PTE_REMOTE));
		assert(PGADDR(*pte) != 0);
		p->pullva += PAGESIZE;	// Page is local - move to next.
	}

	// We've pulled the proc's entire address space: it's ready to go!
	//cprintf("net_rxpullrp: migration complete\n");
	proc_ready(p);
}

// See if we need to pull a page to fill a given PDE or PTE.
// Returns false if we started a pull and need to wait until it's finished,
// or true if we were able to resolve the RR immediately.
bool
net_pullpte(proc *p, uint32_t *pte, int pglevel)
{
	uint32_t rr = *pte;
	assert(rr & RR_REMOTE);

	// Lab 5: Examine an RR that we received in a pdir or ptable,
	// and figure out how to convert it to a local PDE or PTE.
	// There are four important cases to handle:
	// - The RR is zero except for RR_REMOTE and RR_RW (the permissions):
	//   convert it into a PTE_ZERO mapping immediately, and return 1.
	// - The RR refers to a page on OUR node (RRNODE(rr) == net_node):
	//   convert it directly back into a PDE or PTE and return 1.
	// - The RR refers to a page whose home is on another node,
	//   but which we've seen before (mem_rrlookup(rr) != NULL):
	//   convert it directly into a PDE or PTE and return 1.
	// - The RR refers to a remote page we haven't seen before:
	//   allocate a page to hold a local copy,
	//   initiate a pull on that page by calling net_pull(),
	//   and return 0 indicating we have to wait for the pull to complete.
	panic("net_pullpte not implemented");
}

