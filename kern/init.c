/*
 * Kernel initialization.
 *
 * Copyright (C) 1997 Massachusetts Institute of Technology
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Derived from the MIT Exokernel and JOS.
 * Adapted for PIOS by Bryan Ford at Yale University.
 */

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/assert.h>
#include <inc/cdefs.h>
#include <inc/elf.h>
#include <inc/vm.h>

#include <kern/init.h>
#include <kern/cons.h>
#include <kern/debug.h>
#include <kern/mem.h>
#include <kern/cpu.h>
#include <kern/trap.h>
#include <kern/spinlock.h>
#include <kern/mp.h>
#include <kern/proc.h>
#include <kern/file.h>
#include <kern/net.h>

#include <dev/pic.h>
#include <dev/lapic.h>
#include <dev/ioapic.h>
#include <dev/pci.h>


// User-mode stack for user(), below, to run on.
static char gcc_aligned(16) user_stack[PAGESIZE];

// Lab 3: ELF executable containing root process, linked into the kernel
#ifndef ROOTEXE_START
#define ROOTEXE_START _binary_obj_user_sh_start
#endif
extern char ROOTEXE_START[];
uint32_t rootexe_stack_addr = VM_USERHI - PAGESIZE;

void load_elf(char*, proc*);
// Called first from entry.S on the bootstrap processor,
// and later from boot/bootother.S on all other processors.
// As a rule, "init" functions in PIOS are called once on EACH processor.
void
init(void)
{
	extern char start[], edata[], end[];
	
	// Before anything else, complete the ELF loading process.
	// Clear all uninitialized global data (BSS) in our program
	// ensuring that all static/global variables start out zero.
	if (cpu_onboot())
		memset(edata, 0, end - edata);

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
	cprintf("1234 decimal is %o octal!\n", 1234);
	debug_check();
	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
	trap_init();
	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();

	if (cpu_onboot())
		spinlock_check();

	// Initialize the paged virtual memory system.
	pmap_init();
	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
	pic_init();		// setup the legacy PIC (mainly to disable it)
	ioapic_init();		// prepare to handle external device interrupts
	lapic_init();		// setup this CPU's local APIC
	cpu_bootothers();	// Get other processors started
	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
		cpu_onboot() ? "BP" : "AP");

	// Initialize the I/O system.
	file_init();		// Create root directory and console I/O files
	pci_init();		// Initialize the PCI bus and network card
	net_init();		
	cons_intenable();	// Let the console start producing interrupts
	// Initialize the process management code.
	proc_init();
	if(cpu_onboot()){
		proc_root= proc_alloc(NULL, 0);
		file_initroot(proc_root);
		load_elf(ROOTEXE_START,proc_root);
		proc_root->sv.tf.fs = CPU_GDT_UDATA | 3;
		proc_root->sv.tf.gs = CPU_GDT_UDATA | 3;
		proc_root->sv.tf.eip = (uint32_t)(0x40000100);
		proc_root->sv.tf.esp = (uint32_t)(VM_USERHI -1);
		proc_root->sv.tf.eflags = FL_IF;
		proc_ready(proc_root);
	}
	proc_sched();
}

// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
	cprintf("in user()\n");
	assert(read_esp() > (uint32_t) &user_stack[0]);
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
	// Check the system call and process scheduling code.
	proc_check();

	done();
}

// This is a function that we call when the kernel is "done" -
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
	while (1)
		;	// just spin
}

void load_elf(char* elf, proc* p){
	uint32_t va, p_va_start, p_va_end;
	proghdr* phd;
	int i, j;
	pte_t* pte;
	elfhdr* elf_load = (elfhdr*)elf;
	phd = (proghdr*)(elf + elf_load->e_phoff);
	
	for(i = 0; i < elf_load->e_phnum; i++){
		if(phd->p_type != 1){
			phd++;
			continue;
		}
		p_va_start = phd->p_va & (~0xfff);
		p_va_end = (p_va_start + phd->p_memsz - 1) & ~0xfff;
		for(va = p_va_start; va <= p_va_end; va+=PAGESIZE){
			if(pmap_insert(p->pdir, mem_alloc(), va, PTE_P | PTE_W | PTE_U) == NULL){
				panic("no mem in load_elf.\n");
			};
		}
		phd++;
	}
	
	phd = (proghdr*)(elf + elf_load->e_phoff);
	for(i = 0; i < elf_load->e_phnum; i++){
		if(phd->p_type != 1){
			phd++;
			continue;
		}

		char* load_va_start = (char*)phd->p_va;
		char* load_start = elf + phd->p_offset;
		for(j = 0; j < phd->p_filesz; j++){
			*(load_va_start + j) = *(load_start + j);
		}
		if(phd->p_memsz > phd->p_filesz){
			for(j; j < phd->p_memsz; j++)
				*(load_va_start + j) = 0;
		}
		phd++;
	}
	
	phd = (proghdr*)(elf + elf_load->e_phoff);
	for(i = 0; i < elf_load->e_phnum; i++){
		if(phd->p_type != 1){
			phd++;
			continue;
		}
		if(phd->p_flags & ELF_PROG_FLAG_WRITE){
			phd++;
			continue;
		}
		p_va_start = phd->p_va & (~0xfff);
		p_va_end = (p_va_start + phd->p_memsz - 1) & ~0xfff;
		for(va = p_va_start; va <= p_va_end; va+=PAGESIZE){
			pte = pmap_walk(p->pdir,va,1);
			*pte = *pte & (~PTE_W);
		}
	}
	
	if(pmap_insert(p->pdir, mem_alloc(), rootexe_stack_addr,SYS_RW| PTE_U | PTE_P | PTE_W) == NULL)
		panic("Has no mem in load_elf assign stack.\n");
}
