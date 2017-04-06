
obj/boot/bootother.elf:     file format elf32-i386


Disassembly of section .text:

00001000 <start>:
#define SEG_KDATA 2  // kernel data+stack

.code16                       # Assemble for 16-bit mode
.globl start
start:
	cli                         # Disable interrupts
    1000:	fa                   	cli    

	# Set up the important data segment registers (DS, ES, SS).
	xorw    %ax,%ax             # Segment number zero
    1001:	31 c0                	xor    %eax,%eax
	movw    %ax,%ds             # -> Data Segment
    1003:	8e d8                	mov    %eax,%ds
	movw    %ax,%es             # -> Extra Segment
    1005:	8e c0                	mov    %eax,%es
	movw    %ax,%ss             # -> Stack Segment
    1007:	8e d0                	mov    %eax,%ss

	# Switch from real to protected mode, using a bootstrap GDT
	# and segment translation that makes virtual addresses 
	# identical to physical addresses, so that the 
	# effective memory map does not change during the switch.
	lgdt    gdtdesc
    1009:	0f 01 16             	lgdtl  (%esi)
    100c:	64 10 0f             	adc    %cl,%fs:(%edi)
	movl    %cr0, %eax
    100f:	20 c0                	and    %al,%al
	orl     $CR0_PE, %eax
    1011:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
    1015:	0f 22 c0             	mov    %eax,%cr0

	# Jump to next instruction, but in 32-bit code segment.
	# Switches processor into 32-bit mode.
	ljmp    $(SEG_KCODE<<3), $start32
    1018:	ea 1d 10 08 00 66 b8 	ljmp   $0xb866,$0x8101d

0000101d <start32>:

.code32                       # Assemble for 32-bit mode
start32:
	# Set up the protected-mode data segment registers
	movw    $(SEG_KDATA<<3), %ax    # Our data segment selector
    101d:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds                # -> DS: Data Segment
    1021:	8e d8                	mov    %eax,%ds
	movw    %ax, %es                # -> ES: Extra Segment
    1023:	8e c0                	mov    %eax,%es
	movw    %ax, %ss                # -> SS: Stack Segment
    1025:	8e d0                	mov    %eax,%ss
	movw    $0, %ax                 # Zero segments not ready for use
    1027:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs                # -> FS
    102b:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs                # -> GS
    102d:	8e e8                	mov    %eax,%gs

	# Set up the stack pointer and call into C.
	movl    start-4, %esp
    102f:	8b 25 fc 0f 00 00    	mov    0xffc,%esp
	call	*(start-8)
    1035:	ff 15 f8 0f 00 00    	call   *0xff8

	# If the call returns (it shouldn't), trigger a Bochs
	# breakpoint if running under Bochs, then loop.
	movw    $0x8a00, %ax            # 0x8a00 -> port 0x8a00
    103b:	66 b8 00 8a          	mov    $0x8a00,%ax
	movw    %ax, %dx
    103f:	66 89 c2             	mov    %ax,%dx
	outw    %ax, %dx
    1042:	66 ef                	out    %ax,(%dx)
	movw    $0x8e00, %ax            # 0x8e00 -> port 0x8a00
    1044:	66 b8 00 8e          	mov    $0x8e00,%ax
	outw    %ax, %dx
    1048:	66 ef                	out    %ax,(%dx)

0000104a <spin>:
spin:
	jmp     spin
    104a:	eb fe                	jmp    104a <spin>

0000104c <gdt>:
	...
    1054:	ff                   	(bad)  
    1055:	ff 00                	incl   (%eax)
    1057:	00 00                	add    %al,(%eax)
    1059:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
    1060:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

00001064 <gdtdesc>:
    1064:	17                   	pop    %ss
    1065:	00 4c 10 00          	add    %cl,0x0(%eax,%edx,1)
	...
