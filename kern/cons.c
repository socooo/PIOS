/*
 * Main console driver for PIOS, which manages lower-level console devices
 * such as video (dev/video.*), keyboard (dev/kbd.*), and serial (dev/serial.*)
 *
 * Copyright (c) 2010 Yale University.
 * Copyright (c) 1993, 1994, 1995 Charles Hannum.
 * Copyright (c) 1990 The Regents of the University of California.
 * See section "BSD License" in the file LICENSES for licensing terms.
 *
 * This code is derived from the NetBSD pcons driver, and in turn derived
 * from software contributed to Berkeley by William Jolitz and Don Ahn.
 * Adapted for PIOS by Bryan Ford at Yale University.
 */

#include <inc/stdio.h>
#include <inc/stdarg.h>
#include <inc/x86.h>
#include <inc/string.h>
#include <inc/assert.h>
#include <inc/syscall.h>

#include <kern/cpu.h>
#include <kern/cons.h>
#include <kern/mem.h>
#include <kern/spinlock.h>
#include <kern/file.h>

#include <dev/video.h>
#include <dev/kbd.h>
#include <dev/serial.h>

void cons_intr(int (*proc)(void));
static void cons_putc(int c);

spinlock cons_lock;	// Spinlock to make console output atomic

/***** General device-independent console code *****/
// Here we manage the console input buffer,
// where we stash characters received from the keyboard or serial port
// whenever the corresponding interrupt occurs.

#define CONSBUFSIZE 512

static struct {
	uint8_t buf[CONSBUFSIZE];
	uint32_t rpos;
	uint32_t wpos;
} s_consin;

static struct {
	uint8_t buf[CONSBUFSIZE];
	uint32_t rpos;
	uint32_t wpos;
} s_consout;

static int fi_read_pos = (uint32_t)FILEDATA(FILEINO_CONSIN);
// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
	int c;
	spinlock_acquire(&cons_lock);
	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
		s_consin.buf[s_consin.wpos++] = c;
		if (s_consin.wpos == CONSBUFSIZE)
			s_consin.wpos = 0;
	}
	spinlock_release(&cons_lock);

	// Wake the root process
	file_wakeroot();
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (s_consin.rpos != s_consin.wpos) {
		c = s_consin.buf[s_consin.rpos++];
		if (s_consin.rpos == CONSBUFSIZE)
			s_consin.rpos = 0;
		return c;
	}
	return 0;
}

// output a character to the console
static void
cons_putc(int c)
{
	serial_putc(c);
	video_putc(c);
}

// initialize the console devices
void
cons_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;

	spinlock_init(&cons_lock);
	video_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
		warn("Serial port does not exist!\n");
}

// Enable console interrupts.
void
cons_intenable(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;

	kbd_intenable();
	serial_intenable();
}

// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
	if (read_cs() & 3)
		return sys_cputs(str);	// use syscall from user mode

	// Hold the console spinlock while printing the entire string,
	// so that the output of different cputs calls won't get mixed.
	// Implement ad hoc recursive locking for debugging convenience.
	bool already = spinlock_holding(&cons_lock);
	if (!already)
		spinlock_acquire(&cons_lock);

	char ch;
	while (*str)
		cons_putc(*str++);

	if (!already)
		spinlock_release(&cons_lock);
}

// Synchronize the root process's console special files
// with the actual console I/O device.
bool
cons_io(void)
{
	// Lab 4: your console I/O code here.
	//warn("cons_io() not implemented");
	fileinode* stdout = &files->fi[FILEINO_CONSOUT];
	fileinode* stdin = &files->fi[FILEINO_CONSIN];
	int status = 0;
	int ind = 0;
	spinlock_acquire(&cons_lock);
	if(s_consout.wpos < stdout->size){
		while(s_consout.wpos < stdout->size){
			if(ind >= CONSBUFSIZE){
				int n = 0;
				//cputs((char*)s_consout.buf);
				for(n; n < CONSBUFSIZE; n++){
					cons_putc(s_consout.buf[n]);
				}
				memset(s_consout.buf,0,CONSBUFSIZE);
				ind = 0;
			}
			s_consout.buf[ind++] = *(uint8_t*)((uint32_t)FILEDATA(FILEINO_CONSOUT) + s_consout.wpos);
			s_consout.wpos++;
		}
		if(ind > 0){
			int n = 0;
			//cputs((char*)s_consout.buf);
			for(n; n < ind; n++){
					cons_putc(s_consout.buf[n]);
				}
			memset(s_consout.buf,0,CONSBUFSIZE);
			ind = 0;
		}
		status = 1;
	}
	if(s_consin.rpos != s_consin.wpos){
		while(s_consin.rpos != s_consin.wpos){
			memcpy((void*)fi_read_pos, &s_consin.buf[s_consin.rpos++], 1);
			fi_read_pos++;
			stdin->size++;
		}
		status = 1;
	}
	spinlock_release(&cons_lock);
	return status;	// 0 indicates no I/O done
}

