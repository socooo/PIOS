/*
 * PIOS networking protocol definitions.
 *
 * Copyright (C) 2010 Yale University.
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Primary author: Bryan Ford
 */

#ifndef PIOS_KERN_NET_H
#define PIOS_KERN_NET_H
#ifndef PIOS_KERNEL
# error "This is a kernel header; user programs should not #include it"
#endif

#include <inc/cdefs.h>
#include <inc/trap.h>
#include <inc/syscall.h>


// Ethernet header
typedef struct net_ethhdr {
	uint8_t		dst[6];		// Destination MAC address
	uint8_t		src[6];		// Source MAC address
	uint16_t	type;		// Ethernet packet type
} net_ethhdr;

#define NET_ETYPE_IP	0x0800		// Ethernet packet type for IPv4

#define NET_MAXPKT	1514		// Max Ethernet packet size w/o csum

#define NET_MAXNODES	32		// Max number of nodes in system


// Message types
typedef enum net_msgtype {
	NET_INVALID	= 0,
	NET_MIGRQ,		// Migrate request
	NET_MIGRP,		// Migrate reply
	NET_PULLRQ,		// Page pull request
	NET_PULLRP,		// Page pull reply
} net_msgtype;

// Minimal packet header for all our network messages
typedef struct net_hdr {
	net_ethhdr	eth;	// Ethernet header always comes first
	net_msgtype	type;	// Message request/response type
} net_hdr;

typedef struct net_migrq {
	net_ethhdr	eth;
	net_msgtype	type;	// = NET_MIGRQ
	uint32_t	home;	// Remote ref for proc's home node & physaddr
	uint32_t	pdir;	// Remote ref for proc's page directory
	procstate	save;	// Process's saved user-visible state
} net_migrq;

typedef struct net_migrp {
	net_ethhdr	eth;
	net_msgtype	type;	// = NET_MIGRP
	uint32_t	home;	// Remote ref for proc being acknowledged
} net_migrp;

// Pull a page from a remote node
typedef struct net_pullrq {
	net_ethhdr	eth;
	net_msgtype	type;	// = NET_PULLRQ
	uint32_t	rr;	// Remote ref to pdir, ptab, or page
	uint8_t		pglev;	// 0=page, 1=page table, 2=page directory
	uint8_t		need;	// Bits 2-0: which parts of page are needed
} net_pullrq;

// Page pull reply - 3 required per page, to fit in Ethernet packet size.
#define NET_PULLPART	1368		// 1368*3 >= 4096
#define NET_PULLPART0	NET_PULLPART
#define NET_PULLPART1	NET_PULLPART
#define NET_PULLPART2	(PAGESIZE-NET_PULLPART0-NET_PULLPART1)
typedef struct net_pullrphdr {
	net_ethhdr	eth;
	net_msgtype	type;	// = NET_PULLRP
	uint32_t	rr;	// Remote reference
	int		part;	// Which part of the page this is: 0, 1, or 2
	char		data[0]; // Variable-length payload follows pullrphdr
} net_pullrphdr;


// 32-bit remote reference layout.
// Note that bit 0, corresponding to PTE_P, must always be zero,
// so that an RR can coexist with local page refs in page dirs & ptables.
#define RR_ADDR		0xfffff000	// Page's physical address on home node
#define RR_REMOTE	0x00000800	// Set to distinguish from a local ref
#define RR_RW		0x00000600	// Nominal perms for mapping (=SYS_RW)
#define RR_HOME		0x000001fe	// 8-bit home node
#define RR_HOMESHIFT		1	// Home node field starts at bit 1

// Macros to construct and extract fields from remote refs
#define RRCONS(node,addr,perm)	(RR_REMOTE | ((addr) & RR_ADDR) \
				 | ((uint8_t)(node) << 1) | ((perm) & RR_RW))
#define RRNODE(rr)		((uint8_t)((rr) >> RR_HOMESHIFT))
#define RRADDR(rr)		((rr) & RR_ADDR)

#define PTE_REMOTE	RR_REMOTE	// RRs can masquerade as PTEs

#define PGLEV_PAGE		0	// Plain data page
#define PGLEV_PTAB		1	// Page directory
#define PGLEV_PDIR		2	// Page directory


extern uint8_t net_node;	// My node number - from net_mac[5]
extern uint8_t net_mac[6];	// My MAC address from the Ethernet card


struct trapframe;

void net_init(void);
void net_rx(void *ethpkt, int len);
void net_tick(void);
void gcc_noreturn net_migrate(struct trapframe *tf, uint8_t node, int entry);

#endif // !PIOS_KERN_NET_H
