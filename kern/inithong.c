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

#include <kern/init.h>
#include <kern/cons.h>
#include <kern/debug.h>
#include <kern/mem.h>
#include <kern/cpu.h>
#include <kern/trap.h>
#include <kern/spinlock.h>
#include <kern/mp.h>
#include <kern/proc.h>

#include <dev/pic.h>
#include <dev/lapic.h>
#include <dev/ioapic.h>


// User-mode stack for user(), below, to run on.
static char gcc_aligned(16) user_stack[PAGESIZE];

#define ROOTEXE_START _binary_obj_user_sh_start

// Lab 3: ELF executable containing root process, linked into the kernel
#ifndef ROOTEXE_START
#endif
extern char ROOTEXE_START[];

// Called first from entry.S on the bootstrap processor,
// and later from boot/bootother.S on all other processors.
// As a rule, "init" functions in PIOS are called once on EACH processor.
void
init(void)
{
	// hong:
	// can not find start  --> in entry.S
	// edata, end, --> 
	extern char start[], edata[], end[];
	
	// Before anything else, complete the ELF loading process.
	// Clear all uninitialized global data (BSS) in our program
	// ensuring that all static/global variables start out zero.
	if (cpu_onboot())
		memset(edata, 0, end - edata);

	// Initialize the console.
	// Can't call cprintf until after we do this!
	// hong :
	// the first thing the kernel does is initialize the console device driver so that your kernel can produce visible output. 
	cons_init();
	// Lab 1: test cprintf and debug_trace
	cprintf("1234 decimal is %o octal!\n", 1234);
	debug_check();	
	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
	trap_init();
	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
	
	// Lab 2: check spinlock implementation
	if (cpu_onboot())
		spinlock_check();
	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
	pic_init();		// setup the legacy PIC (mainly to disable it)
	ioapic_init();		// prepare to handle external device interrupts
	lapic_init();		// setup this CPU's local APIC
	cpu_bootothers();	// Get other processors started
	
	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
		cpu_onboot() ? "BP" : "AP");

	// Initialize the process management code.
	proc_init();
	
	// Lab 1: change this so it enters user() in user mode,
	// running on the user_stack declared above,
	// instead of just calling user() directly.
	/*
	if (!cpu_onboot())
			while(1);
			
	 trapframe tf = {
		gs: CPU_GDT_UDATA | 3,
		fs: CPU_GDT_UDATA | 3,
		es: CPU_GDT_UDATA | 3,
		ds: CPU_GDT_UDATA | 3,
		cs: CPU_GDT_UCODE | 3,
		ss: CPU_GDT_UDATA | 3,
		eflags: FL_IOPL_3,
		eip: (uint32_t)user,
		esp: (uint32_t)&user_stack[PAGESIZE],
	};
	 	cprintf ("to user\n");
	trap_return(&tf);*/
	proc *user_proc;
	if(cpu_onboot()) {
		
		user_proc = proc_alloc(NULL,0);
		user_proc->sv.tf.esp = (uint32_t)&user_stack[PAGESIZE];
		user_proc->sv.tf.eip =  (uint32_t)user;
		user_proc->sv.tf.eflags = FL_IF;
		user_proc->sv.tf.gs = CPU_GDT_UDATA | 3;
		user_proc->sv.tf.fs = CPU_GDT_UDATA | 3;
		proc_ready(user_proc);
	}
	proc_sched();
	user();
}

// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
	// hong: system haven't complete 
	 cprintf("in user()\n");
	assert(read_esp() > (uint32_t) &user_stack[0]);
	// hong:
	// sizeof(user_stack) == 4096
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

