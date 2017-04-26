/*
 * Page mapping and page directory/table management.
 *
 * Copyright (C) 1997 Massachusetts Institute of Technology
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Derived from the MIT Exokernel and JOS.
 * Adapted for PIOS by Bryan Ford at Yale University.
 */


#include <inc/x86.h>
#include <inc/mmu.h>
#include <inc/cdefs.h>
#include <inc/string.h>
#include <inc/assert.h>
#include <inc/syscall.h>
#include <inc/vm.h>

#include <kern/cpu.h>
#include <kern/trap.h>
#include <kern/proc.h>
#include <kern/pmap.h>


// Statically allocated page directory mapping the kernel's address space.
// We use this as a template for all pdirs for user-level processes.
pde_t pmap_bootpdir[1024] gcc_aligned(PAGESIZE);

// Statically allocated page that we always keep set to all zeros.
uint8_t pmap_zero[PAGESIZE] gcc_aligned(PAGESIZE);

static uint32_t va2pa(pde_t *pdir, uintptr_t va);

// --------------------------------------------------------------
// Set up initial memory mappings and turn on MMU.
// --------------------------------------------------------------



// Set up a two-level page table:
// pmap_bootpdir is its linear (virtual) address of the root
// Then turn on paging.
// 
// This function only creates mappings in the kernel part of the address space
// (addresses outside of the range between VM_USERLO and VM_USERHI).
// The user part of the address space remains all PTE_ZERO until later.
//
void
pmap_init(void)
{
	if (cpu_onboot()) {
		// Initialize pmap_bootpdir, the bootstrap page directory.
		// Page directory entries (PDEs) corresponding to the 
		// user-mode address space between VM_USERLO and VM_USERHI
		// should all be initialized to PTE_ZERO (see kern/pmap.h).
		// All virtual addresses below and above this user area
		// should be identity-mapped to the same physical addresses,
		// but only accessible in kernel mode (not in user mode).
		// The easiest way to do this is to use 4MB page mappings.
		// Since these page mappings never change on context switches,
		// we can also mark them global (PTE_G) so the processor
		// doesn't flush these mappings when we reload the PDBR.
		int i = 0;
		int userlo_d = VM_USERLO >> PDXSHIFT;
		int userhi_d = VM_USERHI >> PDXSHIFT;
		for(i; i<userlo_d; i++){
			pmap_bootpdir[i] = i << PDXSHIFT | PTE_P | PTE_PS | PTE_G | PTE_W;
		}
		for(i; i<userhi_d; i++){
			pmap_bootpdir[i] = PTE_ZERO;
		}
		for(i; i < NPDENTRIES; i++){
			pmap_bootpdir[i] = i << PDXSHIFT| PTE_P | PTE_PS | PTE_G | PTE_W;
		}
	}

	// On x86, segmentation maps a VA to a LA (linear addr) and
	// paging maps the LA to a PA.  i.e., VA => LA => PA.  If paging is
	// turned off the LA is used as the PA.  There is no way to
	// turn off segmentation.  At the moment we turn on paging,
	// the code we're executing must be in an identity-mapped memory area
	// where LA == PA according to the page mapping structures.
	// In PIOS this is always the case for the kernel's address space,
	// so we don't have to play any special tricks as in other kernels.

	// Enable 4MB pages and global pages.
	uint32_t cr4 = rcr4();
	cr4 |= CR4_PSE | CR4_PGE;
	lcr4(cr4);

	// Install the bootstrap page directory into the PDBR.
	lcr3(mem_phys(pmap_bootpdir));

	// Turn on paging.
	uint32_t cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_MP|CR0_TS;
	cr0 &= ~(CR0_EM);
	lcr0(cr0);

	// If we survived the lcr0, we're running with paging enabled.
	// Now check the page table management functions below.
	if (cpu_onboot())
		pmap_check();
}

//
// Allocate a new page directory, initialized from the bootstrap pdir.
// Returns the new pdir with a reference count of 1.
//
pte_t *
pmap_newpdir(void)
{
	pageinfo *pi = mem_alloc();
	if (pi == NULL)
		return NULL;
	mem_incref(pi);
	pte_t *pdir = mem_pi2ptr(pi);

	// Initialize it from the bootstrap page directory
	assert(sizeof(pmap_bootpdir) == PAGESIZE);
	memmove(pdir, pmap_bootpdir, PAGESIZE);

	return pdir;
}

// Free a page directory, and all page tables and mappings it may contain.
void
pmap_freepdir(pageinfo *pdirpi)
{
	pmap_remove(mem_pi2ptr(pdirpi), VM_USERLO, VM_USERHI-VM_USERLO);
	mem_free(pdirpi);
}

// Free a page table and all page mappings it may contain.
void
pmap_freeptab(pageinfo *ptabpi)
{
	pte_t *pte = mem_pi2ptr(ptabpi), *ptelim = pte + NPTENTRIES;
	for (; pte < ptelim; pte++) {
		uint32_t pgaddr = PGADDR(*pte);
		if (pgaddr != PTE_ZERO)
			mem_decref(mem_phys2pi(pgaddr), mem_free);
	}
	mem_free(ptabpi);
}

// Given 'pdir', a pointer to a page directory, pmap_walk returns
// a pointer to the page table entry (PTE) for user virtual address 'va'.
// This requires walking the two-level page table structure.
//
// If the relevant page table doesn't exist in the page directory, then:
//    - If writing == 0, pmap_walk returns NULL.
//    - Otherwise, pmap_walk tries to allocate a new page table
//	with mem_alloc.  If this fails, pmap_walk returns NULL.
//    - The new page table is cleared and its refcount set to 1.
//    - Finally, pmap_walk returns a pointer to the requested entry
//	within the new page table.
//
// If the relevant page table does already exist in the page directory,
// but it is read shared and writing != 0, then copy the page table
// to obtain an exclusive copy of it and write-enable the PDE.
//
// Hint: you can turn a pageinfo pointer into the physical address of the
// page it refers to with mem_pi2phys() from kern/mem.h.
//
// Hint 2: the x86 MMU checks permission bits in both the page directory
// and the page table, so it's safe to leave some page permissions
// more permissive than strictly necessary.
pte_t *
pmap_walk(pde_t *pdir, uint32_t va, bool writing)
{
	assert(va >= VM_USERLO && va < VM_USERHI);
	uint32_t pde_i = PDX(va);
	uint32_t pte_i = PTX(va);
	// Fill in this function
	if(pdir[pde_i] == PTE_ZERO){
		if(!writing)
			return NULL;
		pageinfo* page = mem_alloc();
		if(!page)
			return NULL;
		mem_incref(page);
		pdir[pde_i] = mem_pi2phys(page) | PTE_P | PTE_U | PTE_W | PTE_A;
		int i;
		pte_t* ptable = (pte_t*)PGADDR(pdir[pde_i]);
		for(i = 0; i<NPTENTRIES; i++){
			ptable[i] = PTE_ZERO;
		}
		pte_t* pte_ret = (pte_t*) (&(ptable[pte_i]));
		return pte_ret;
	}
	pte_t* pt_has_ret = (pte_t*) (PGADDR(pdir[pde_i]));
	pte_t* pte_ret = (pte_t*) (&(pt_has_ret[pte_i]));
	return pte_ret;
}

//
// Map the physical page 'pi' at user virtual address 'va'.
// The permissions (the low 12 bits) of the page table
//  entry should be set to 'perm | PTE_P'.
//
// Requirements
//   - If there is already a page mapped at 'va', it should be pmap_remove()d.
//   - If necessary, allocate a page able on demand and insert into 'pdir'.
//   - pi->refcount should be incremented if the insertion succeeds.
//   - The TLB must be invalidated if a page was formerly present at 'va'.
//
// Corner-case hint: Make sure to consider what happens when the same 
// pi is re-inserted at the same virtual address in the same pdir.
// What if this is the only reference to that page?
//
// RETURNS: 
//   a pointer to the inserted PTE on success (same as pmap_walk)
//   NULL, if page table couldn't be allocated
//
// Hint: The reference solution uses pmap_walk, pmap_remove, and mem_pi2phys.
//
pte_t *
pmap_insert(pde_t *pdir, pageinfo *pi, uint32_t va, int perm)
{
	// Fill in this function
	uint32_t pte_i = PTX(va);
	uint32_t pde_i = PDX(va);
	pte_t* pt_base = (pte_t *)PGADDR(pdir[pde_i]);
	uint32_t pte = mem_pi2phys(pi) | perm | PTE_P;
	if((pt_base[pte_i] & 0xfffff000) == (pte & 0xfffff000)){
		pt_base[pte_i] = (pte_t)pte;
		pmap_inval(pdir, va, PAGESIZE);
		return (pte_t*)(&(pt_base[pte_i]));
	}
	if((PGADDR(pdir[pde_i]) != PTE_ZERO) && (PGADDR(pt_base[pte_i]) != PTE_ZERO)){
		pmap_remove(pdir, PGADDR(va), PAGESIZE);
	}
	pte_t* pte_add = pmap_walk(pdir, va, 1);
	if(!pte_add)
		return NULL;
	pte_add[0] = pte;
	//cprintf("in pmap insert, pte: %x.\n", *pmap_walk(pdir, va, false));
	mem_incref(pi);
	return (pte_t*)(pte_add);
}

//
// Unmap the physical pages starting at user virtual address 'va'
// and covering a virtual address region of 'size' bytes.
// The caller must ensure that both 'va' and 'size' are page-aligned.
// If there is no mapping at that address, pmap_remove silently does nothing.
// Clears nominal permissions (SYS_RW flags) as well as mappings themselves.
//
// Details:
//   - The refcount on mapped pages should be decremented atomically.
//   - The physical page should be freed if the refcount reaches 0.
//   - The page table entry corresponding to 'va' should be set to 0.
//     (if such a PTE exists)
//   - The TLB must be invalidated if you remove an entry from
//     the pdir/ptab.
//   - If the region to remove covers a whole 4MB page table region,
//     then unmap and free the page table after unmapping all its contents.
//
// Hint: The TA solution is implemented using pmap_lookup,
// 	pmap_inval, and mem_decref.
//
void
pmap_remove(pde_t *pdir, uint32_t va, size_t size)
{
	assert(PGOFF(size) == 0);	// must be page-aligned
	assert(va >= VM_USERLO && va < VM_USERHI);
	assert(size <= VM_USERHI - va);

	uint32_t pde_i = PDX(va);
	uint32_t pte_i = PTX(va);
	int page_account = size/PAGESIZE;
	int remove_pde_no = (page_account+pte_i) / NPTENTRIES;
	int i = 0;
	for(i; i < page_account; i++){
		pte_t* pt_base = (pte_t*)PGADDR(pdir[pde_i + i/NPDENTRIES]);
		if((PGADDR(pdir[pde_i + i/NPDENTRIES]) != PTE_ZERO) && (PGADDR(pt_base[(pte_i + i) % NPTENTRIES]) != PTE_ZERO)){
			pageinfo* pi = (pageinfo*)mem_phys2pi(PGADDR(pt_base[(pte_i + i)%NPTENTRIES]));
			// Fill in this function
			if(pi){
				mem_decref(pi, mem_free);
				pt_base[(pte_i+i)%NPTENTRIES] = PTE_ZERO;
				pmap_inval(pdir, va, PAGESIZE);
			}
		}
	}
	if(remove_pde_no > 0){
		for(i = 1; i <= remove_pde_no; i++){
			if(i == 1){
				if(pte_i == 0){
					if(pdir[pde_i] != PTE_ZERO){
						mem_decref((pageinfo *)mem_phys2pi(PGADDR(pdir[pde_i])), mem_free);
						pdir[pde_i] = PTE_ZERO;
					}
				}
			}else{
				if(pdir[pde_i + i -1] != PTE_ZERO){
					mem_decref((pageinfo *)mem_phys2pi(PGADDR(pdir[pde_i + i -1])), mem_free);
					pdir[pde_i + i -1] = PTE_ZERO;
				}
			}
		}
	}
}

//
// Invalidate the TLB entry or entries for a given virtual address range,
// but only if the page tables being edited are the ones
// currently in use by the processor.
//
void
pmap_inval(pde_t *pdir, uint32_t va, size_t size)
{
	// Flush the entry only if we're modifying the current address space.
	proc *p = proc_cur();
	if (p == NULL || p->pdir == pdir) {
		if (size == PAGESIZE)
			invlpg(mem_ptr(va));	// invalidate one page
		else{
			lcr3(mem_phys(pdir));	// invalidate everything
			cprintf("in pmap_inval, flush done.\n");
		}
	}
}

//
// Virtually copy a range of pages from spdir to dpdir (could be the same).
// Uses copy-on-write to avoid the cost of immediate copying:
// instead just copies the mappings and makes both source and dest read-only.
// Returns true if successfull, false if not enough memory for copy.
//
int
pmap_copy(pde_t *spdir, uint32_t sva, pde_t *dpdir, uint32_t dva,
		size_t size)
{
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
	assert(PTOFF(dva) == 0);
	assert(PTOFF(size) == 0);
	assert(sva >= VM_USERLO && sva < VM_USERHI);
	assert(dva >= VM_USERLO && dva < VM_USERHI);
	assert(size <= VM_USERHI - sva);
	assert(size <= VM_USERHI - dva);

	pte_t* spage;
	pte_t* dpage;
	int page_number = size/PAGESIZE;
	int i = 0;
	for(i; i < page_number; i++){
		if((spage = pmap_walk(spdir, sva, false))){
			if(!(dpage = pmap_walk(dpdir, dva, true)))
				return false;
			if((*spage) & PTE_W)
				*spage |= SYS_WRITE;
			if((*spage) & PTE_P)
				*spage |= SYS_READ;
			*spage &= (~PTE_W);
			*dpage = *spage;
			uint32_t phy_add = PGADDR(*spage);
			pageinfo* pi = mem_phys2pi(phy_add);
			if((PGADDR(*spage)) != PTE_ZERO)
				mem_incref(pi);
		}
		sva += PAGESIZE;
		dva += PAGESIZE;
	}
	return true;
}

//
// Transparently handle a page fault entirely in the kernel, if possible.
// If the page fault was caused by a write to a copy-on-write page,
// then performs the actual page copy on demand and calls trap_return().
// If the fault wasn't due to the kernel's copy on write optimization,
// however, this function just returns so the trap gets blamed on the user.
//
void
pmap_pagefault(trapframe *tf)
{
	// Read processor's CR2 register to find the faulting linear address.
	uint32_t fva = rcr2();
	proc* p = proc_cur();
	pageinfo* origin_pi;	
	if((fva < VM_USERLO)  | (fva >= VM_USERHI)){
		cprintf("in page fault, start. fva: %x err: %x.\n", fva, tf->err);
		cprintf("in page fault, out bound.\n");
		return;
	}
	pte_t* fault_pte_point =  pmap_walk(p->pdir, fva, false);
	uint32_t fault_pte_content = *fault_pte_point;
	if(!fault_pte_point){
		cprintf("in page fault, start. fva: %x err: %x.\n", fva, tf->err);
		cprintf("in page fault, no pte.\n");
		return;
	}
	uint32_t page_flag = fault_pte_content & SYS_WRITE;
	if(!page_flag){
		cprintf("in page fault, no right.\n");
		return;
	}
	if(PGADDR(fault_pte_content) == PTE_ZERO){
		origin_pi = NULL;
	}else{
		origin_pi = mem_phys2pi(PGADDR(fault_pte_content));
	}
	if(page_flag & SYS_WRITE){		
		if(origin_pi->refcount > 1 || (!origin_pi)){
			pageinfo* new_page = mem_alloc();
			memmove((void*)mem_pi2phys(new_page),(void*)PGADDR(fault_pte_content), PAGESIZE);
			pmap_insert(p->pdir, new_page, fva, SYS_RW | PTE_W | PTE_P | PTE_U);
		}
		if(origin_pi->refcount == 1){
			pte_t* pte = pmap_walk(p->pdir, fva, false);
			assert(pte != NULL);
			*pte |= PTE_W;
		}
		pmap_inval(p->pdir, PGADDR(fva), PAGESIZE);
		trap_return(tf);
	}
	return;
}
//
// Helper function for pmap_merge: merge a single memory page
// that has been modified in both the source and destination.
// If conflicting writes to a single byte are detected on the page,
// print a warning to the console and remove the page from the destination.
// If the destination page is read-shared, be sure to copy it before modifying!
//
void
pmap_mergepage(pte_t *rpte, pte_t *spte, pte_t *dpte, uint32_t dva)
{
	uint32_t i = 0;
	if(!rpte || *rpte == PTE_ZERO){
		while( i < PAGESIZE ){
			uint32_t cmp_sadd = PGADDR(*spte);
			uint32_t cmp_dadd = PGADDR(*dpte);
			cmp_dadd += i * 8;
			cmp_sadd += i*8;
			if(*(uint32_t*)cmp_sadd)
				memmove((void*)cmp_dadd, (void*)cmp_sadd, 4);
			i += 4;
		}
	}else{
		while(i < PAGESIZE){
			uint32_t cmp_radd = PGADDR(*rpte);
			uint32_t cmp_sadd = PGADDR(*spte);
			uint32_t cmp_dadd = PGADDR(*dpte);
			cmp_radd += i;
			cmp_dadd += i;
			cmp_sadd += i;
			if(memcmp((void*)cmp_radd,(void*)cmp_sadd, 4))
				memmove((void*)cmp_dadd, (void*)cmp_sadd, 4);
			i += 4;
		}
	}
}

// 
// Merge differences between a reference snapshot represented by rpdir
// and a source address space spdir into a destination address space dpdir.
//
int
pmap_merge(pde_t *rpdir, pde_t *spdir, uint32_t sva,
		pde_t *dpdir, uint32_t dva, size_t size)
{
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
	assert(PTOFF(dva) == 0);
	assert(PTOFF(size) == 0);
	assert(sva >= VM_USERLO && sva < VM_USERHI);
	assert(dva >= VM_USERLO && dva < VM_USERHI);
	assert(size <= VM_USERHI - sva);
	assert(size <= VM_USERHI - dva);

	uint32_t tmp_va = sva;
	while(tmp_va < sva + size){
		uint32_t rpde = rpdir[PDX(tmp_va)];
		uint32_t spde = spdir[PDX(tmp_va)];
		if(PGADDR(spde) == PTE_ZERO){
			tmp_va += PTSIZE;
			continue;
		}
		pte_t* rpte = pmap_walk(rpdir, tmp_va, false);
		pte_t* spte = pmap_walk(spdir, tmp_va, false);
		if(*rpte == *spte){
			tmp_va += PAGESIZE;
			continue;
		}
		if(PGADDR(*spte) == PTE_ZERO){
			tmp_va += PAGESIZE;
			continue;
		}
		pte_t* dpte = pmap_walk(dpdir, tmp_va, true);
		if(!dpte)
			panic("in pmap_merge, has no pte.\n");
		if(PGADDR(*dpte) == PGADDR(*rpte)){
			uint32_t perm = 0;
			pageinfo* dpage = mem_alloc();
			if(!dpage)
				panic("in pmap_merge, has no page.\n");
			mem_incref(dpage);
			mem_pi2phys(dpage);
			memmove((void*)mem_pi2phys(dpage), (void*)PGADDR(*dpte), PAGESIZE);
			if((*dpte & SYS_READ))
				perm = perm | PTE_P | PTE_U;
			if((*dpte & SYS_WRITE))
				perm = perm | PTE_W;
			pmap_insert(dpdir, dpage, tmp_va, perm);
		}
		pmap_mergepage(rpte, spte, dpte, dva);
		tmp_va += PAGESIZE;
	}
	return 1;
}

//
// Set the nominal permission bits on a range of virtual pages to 'perm'.
// Adding permission to a nonexistent page maps zero-filled memory.
// It's OK to add SYS_READ and/or SYS_WRITE permission to a PTE_ZERO mapping;
// this causes the pmap_zero page to be mapped read-only (PTE_P but not PTE_W).
// If the user gives SYS_WRITE permission to a PTE_ZERO mapping,
// the page fault handler copies the zero page when the first write occurs.
//
int
pmap_setperm(pde_t *pdir, uint32_t va, uint32_t size, int perm)
{
	assert(PGOFF(va) == 0);
	assert(PGOFF(size) == 0);
	assert(va >= VM_USERLO && va < VM_USERHI);
	assert(size <= VM_USERHI - va);
	assert((perm & ~(SYS_RW)) == 0);

	uint32_t page_accout = size/PAGESIZE;
	int i = 0;
	pte_t* tmp_pte;
	uint32_t tmp_va = va;
	for(i; i < page_accout; i++){
		if(!(tmp_pte = pmap_walk(pdir, tmp_va, true)))
			return 0;
		switch(perm & SYS_RW){
		case 0:
			if(!((*tmp_pte) & SYS_RW))
				*tmp_pte = *tmp_pte | PTE_U | PTE_P;
			else{
				*tmp_pte &= ~(SYS_RW | PTE_P | PTE_W);
			}
			break;
		case SYS_READ:
			*tmp_pte &= ~(SYS_RW | PTE_P | PTE_W);
			*tmp_pte |= (SYS_READ | PTE_U | PTE_P);
			break;
		case SYS_RW:
			*tmp_pte &= ~(SYS_RW | PTE_P | PTE_W);
			*tmp_pte |= (SYS_RW| PTE_U | PTE_P);
			break;
		default:
			panic("In pmap_setperm,unrecognized perm.\n");
		}
		tmp_va += PAGESIZE;
	}
	return 1;
}

//
// This function returns the physical address of the page containing 'va',
// defined by the page directory 'pdir'.  The hardware normally performs
// this functionality for us!  We define our own version to help check
// the pmap_check() function; it shouldn't be used elsewhere.
//
static uint32_t
va2pa(pde_t *pdir, uintptr_t va)
{
	pde_t* ptmp = pdir;
	pdir = &pdir[PDX(va)];
	if (!(*pdir & PTE_P))
		return ~0;
	pte_t *ptab = mem_ptr(PGADDR(*pdir));
	if (!(ptab[PTX(va)] & PTE_P))
		return ~0;
	return PGADDR(ptab[PTX(va)]);
}

// check pmap_insert, pmap_remove, &c
void
pmap_check(void)
{
	extern pageinfo *mem_freelist;

	pageinfo *pi, *pi0, *pi1, *pi2, *pi3;
	pageinfo *fl;
	pte_t *ptep, *ptep1;
	int i;

	// should be able to allocate three pages
	pi0 = pi1 = pi2 = 0;
	pi0 = mem_alloc();
	pi1 = mem_alloc();
	pi2 = mem_alloc();
	pi3 = mem_alloc();

	assert(pi0);
	assert(pi1 && pi1 != pi0);
	assert(pi2 && pi2 != pi1 && pi2 != pi0);

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
	mem_freelist = NULL;

	// should be no free memory
	assert(mem_alloc() == NULL);

	// there is no free memory, so we can't allocate a page table 
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) == NULL);

	// free pi0 and try again: pi0 should be used for page table
	mem_free(pi0);
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) != NULL);
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi0));
	assert(va2pa(pmap_bootpdir, VM_USERLO) == mem_pi2phys(pi1));
	assert(pi1->refcount == 1);
	assert(pi0->refcount == 1);

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because pi0 is already allocated for page table
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
	assert(pi2->refcount == 1);
	// should be no free memory
	assert(mem_alloc() == NULL);

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because it's already there
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
	assert(pi2->refcount == 1);

	// pi2 should NOT be on the free list
	// could hapien in ref counts are handled slopiily in pmap_insert
	assert(mem_alloc() == NULL);

	// check that pmap_walk returns a pointer to the pte
	ptep = mem_ptr(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PAGESIZE)]));
	assert(pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0)
		== ptep+PTX(VM_USERLO+PAGESIZE));

	// should be able to change permissions too.
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, PTE_U));
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
	assert(pi2->refcount == 1);
	assert(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U);
	assert(pmap_bootpdir[PDX(VM_USERLO)] & PTE_U);
	
	// should not be able to map at VM_USERLO+PTSIZE
	// because we need a free page for a page table
	assert(pmap_insert(pmap_bootpdir, pi0, VM_USERLO+PTSIZE, 0) == NULL);

	// insert pi1 at VM_USERLO+PAGESIZE (replacing pi2)
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO+PAGESIZE, 0));
	assert(!(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U));

	// should have pi1 at both +0 and +PAGESIZE, pi2 nowhere, ...
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == mem_pi2phys(pi1));
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
	// ... and ref counts should reflect this
	assert(pi1->refcount == 2);
	assert(pi2->refcount == 0);

	// pi2 should be returned by mem_alloc
	assert(mem_alloc() == pi2);

	// unmapping pi1 at VM_USERLO+0 should keep pi1 at +PAGESIZE
	pmap_remove(pmap_bootpdir, VM_USERLO+0, PAGESIZE);
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
	assert(pi1->refcount == 1);
	assert(pi2->refcount == 0);
	assert(mem_alloc() == NULL);	// still should have no pages free

	// unmapping pi1 at VM_USERLO+PAGESIZE should free it
	pmap_remove(pmap_bootpdir, VM_USERLO+PAGESIZE, PAGESIZE);
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == ~0);
	assert(pi1->refcount == 0);
	assert(pi2->refcount == 0);

	// so it should be returned by page_alloc
	assert(mem_alloc() == pi1);

	// should once again have no free memory
	assert(mem_alloc() == NULL);

	// should be able to pmap_insert to change a page
	// and see the new data immediately.
	memset(mem_pi2ptr(pi1), 1, PAGESIZE);
	memset(mem_pi2ptr(pi2), 2, PAGESIZE);
	pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0);
	assert(pi1->refcount == 1);
	assert(*(int*)VM_USERLO == 0x01010101);
	pmap_insert(pmap_bootpdir, pi2, VM_USERLO, 0);
	assert(*(int*)VM_USERLO == 0x02020202);
	assert(pi2->refcount == 1);
	assert(pi1->refcount == 0);
	assert(mem_alloc() == pi1);
	pmap_remove(pmap_bootpdir, VM_USERLO, PAGESIZE);
	assert(pi2->refcount == 0);
	assert(mem_alloc() == pi2);

	// now use a pmap_remove on a large region to take pi0 back
	pmap_remove(pmap_bootpdir, VM_USERLO, VM_USERHI-VM_USERLO);
	assert(pmap_bootpdir[PDX(VM_USERLO)] == PTE_ZERO);
	assert(pi0->refcount == 0);
	assert(mem_alloc() == pi0);
	assert(mem_freelist == NULL);

	// test pmap_remove with large, non-ptable-aligned regions
	mem_free(pi1);
	uintptr_t va = VM_USERLO;
	assert(pmap_insert(pmap_bootpdir, pi0, va, 0));
	assert(pmap_insert(pmap_bootpdir, pi0, va+PAGESIZE, 0));
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE-PAGESIZE, 0));
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi1));
	assert(mem_freelist == NULL);
	mem_free(pi2);
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE, 0));
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE+PAGESIZE, 0));
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2-PAGESIZE, 0));
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE)])
		== mem_pi2phys(pi2));
	assert(mem_freelist == NULL);
	mem_free(pi3);
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2, 0));
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2+PAGESIZE, 0));
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE*2, 0));
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE, 0));
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE*2)])
		== mem_pi2phys(pi3));
	assert(mem_freelist == NULL);
	assert(pi0->refcount == 10);
	assert(pi1->refcount == 1);
	assert(pi2->refcount == 1);
	assert(pi3->refcount == 1);
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3-PAGESIZE*2);
	assert(pi0->refcount == 2);
	assert(pi2->refcount == 0); assert(mem_alloc() == pi2);
	assert(mem_freelist == NULL);
	pmap_remove(pmap_bootpdir, va, PTSIZE*3-PAGESIZE);
	assert(pi0->refcount == 1);
	assert(pi1->refcount == 0); assert(mem_alloc() == pi1);
	assert(mem_freelist == NULL);
	pmap_remove(pmap_bootpdir, va+PTSIZE*3-PAGESIZE, PAGESIZE);
	assert(pi0->refcount == 0);	// pi3 might or might not also be freed
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3);
	assert(pi3->refcount == 0);
	mem_alloc(); mem_alloc();	// collect pi0 and pi3
	assert(mem_freelist == NULL);

	// check pointer arithmetic in pmap_walk
	mem_free(pi0);
	va = VM_USERLO + PAGESIZE*NPTENTRIES + PAGESIZE;
	ptep = pmap_walk(pmap_bootpdir, va, 1);
	ptep1 = mem_ptr(PGADDR(pmap_bootpdir[PDX(va)]));
	assert(ptep == ptep1 + PTX(va));
	pmap_bootpdir[PDX(va)] = PTE_ZERO;
	pi0->refcount = 0;

	// check that new page tables get cleared
	memset(mem_pi2ptr(pi0), 0xFF, PAGESIZE);
	mem_free(pi0);
	pmap_walk(pmap_bootpdir, VM_USERHI-PAGESIZE, 1);
	ptep = mem_pi2ptr(pi0);
	for(i=0; i<NPTENTRIES; i++)
		assert(ptep[i] == PTE_ZERO);
	pmap_bootpdir[PDX(VM_USERHI-PAGESIZE)] = PTE_ZERO;
	pi0->refcount = 0;

	// give free list back
	mem_freelist = fl;

	// free the pages we filched
	mem_free(pi0);
	mem_free(pi1);
	mem_free(pi2);
	mem_free(pi3);

	cprintf("pmap_check() succeeded!\n");
}

