
obj/user/testvm:     file format elf32-i386


Disassembly of section .text:

40000100 <start>:
// starts us running when we are initially loaded into a new process.
	.globl start
start:
	// See if we were started with arguments on the stack.
	// If not, our esp will start on a nice big power-of-two boundary.
	testl $0x0fffffff, %esp
40000100:	f7 c4 ff ff ff 0f    	test   $0xfffffff,%esp
	jnz args_exist
40000106:	75 04                	jne    4000010c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
40000108:	6a 00                	push   $0x0
	pushl $0
4000010a:	6a 00                	push   $0x0

4000010c <args_exist>:

args_exist:

	call	main	// run the program
4000010c:	e8 ee 29 00 00       	call   40002aff <main>
	pushl	%eax	// use with main's return value as exit status
40000111:	50                   	push   %eax
	call	exit
40000112:	e8 59 37 00 00       	call   40003870 <exit>
1:	jmp 1b
40000117:	eb fe                	jmp    40000117 <args_exist+0xb>

40000119 <exec_start>:
// and at the same location in EVERY user program.
// We guarantee this by putting it in lib/entry.S, which is always the same
// and linked at the beginning of every user program.
	.globl exec_start
exec_start:
	movl	4(%esp),%esp	// Load new executable's initial stack pointer
40000119:	8b 64 24 04          	mov    0x4(%esp),%esp
	xorl	%ebp,%ebp	// New stack will be at its first stack frame
4000011d:	31 ed                	xor    %ebp,%ebp

	movl	$SYS_GET|SYS_COPY,%eax	// Copy child 0's memory onto our own.
4000011f:	b8 02 00 02 00       	mov    $0x20002,%eax
	xorl	%edx,%edx		// edx[0-7] = child 0
40000124:	31 d2                	xor    %edx,%edx
	movl	$VM_USERLO,%esi
40000126:	be 00 00 00 40       	mov    $0x40000000,%esi
	movl	$VM_USERLO,%edi
4000012b:	bf 00 00 00 40       	mov    $0x40000000,%edi
	movl	$VM_USERHI-VM_USERLO,%ecx
40000130:	b9 00 00 00 b0       	mov    $0xb0000000,%ecx
	int	$T_SYSCALL
40000135:	cd 30                	int    $0x30

	movl	$SYS_PUT|SYS_ZERO,%eax	// Zero out child 0's state
40000137:	b8 01 00 01 00       	mov    $0x10001,%eax
	int	$T_SYSCALL
4000013c:	cd 30                	int    $0x30

	jmp	start
4000013e:	e9 bd ff ff ff       	jmp    40000100 <start>
40000143:	90                   	nop

40000144 <fork>:


// Fork a child process, returning 0 in the child and 1 in the parent.
int
fork(int cmd, uint8_t child)
{
40000144:	55                   	push   %ebp
40000145:	89 e5                	mov    %esp,%ebp
40000147:	57                   	push   %edi
40000148:	56                   	push   %esi
40000149:	53                   	push   %ebx
4000014a:	81 ec 9c 02 00 00    	sub    $0x29c,%esp
40000150:	8b 45 0c             	mov    0xc(%ebp),%eax
40000153:	88 85 74 fd ff ff    	mov    %al,-0x28c(%ebp)
	// Set up the register state for the child
	struct procstate ps;
	memset(&ps, 0, sizeof(ps));
40000159:	c7 44 24 08 50 02 00 	movl   $0x250,0x8(%esp)
40000160:	00 
40000161:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000168:	00 
40000169:	8d 85 78 fd ff ff    	lea    -0x288(%ebp),%eax
4000016f:	89 04 24             	mov    %eax,(%esp)
40000172:	e8 fa 34 00 00       	call   40003671 <memset>
	// Use some assembly magic to propagate registers to child
	// and generate an appropriate starting eip
	int isparent;
	asm volatile(
40000177:	89 b5 7c fd ff ff    	mov    %esi,-0x284(%ebp)
4000017d:	89 bd 78 fd ff ff    	mov    %edi,-0x288(%ebp)
40000183:	89 ad 80 fd ff ff    	mov    %ebp,-0x280(%ebp)
40000189:	89 a5 bc fd ff ff    	mov    %esp,-0x244(%ebp)
4000018f:	c7 85 b0 fd ff ff 9e 	movl   $0x4000019e,-0x250(%ebp)
40000196:	01 00 40 
40000199:	b8 01 00 00 00       	mov    $0x1,%eax
4000019e:	89 c6                	mov    %eax,%esi
400001a0:	89 75 e4             	mov    %esi,-0x1c(%ebp)
		  "=m" (ps.tf.esp),
		  "=m" (ps.tf.eip),
		  "=a" (isparent)
		:
		: "ebx", "ecx", "edx");
	if (!isparent){
400001a3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
400001a7:	75 07                	jne    400001b0 <fork+0x6c>
		return 0;	// in the child
400001a9:	b8 00 00 00 00       	mov    $0x0,%eax
400001ae:	eb 5c                	jmp    4000020c <fork+0xc8>
		}
	// Fork the child, copying our entire user address space into it.
	ps.tf.regs.eax = 0;	// isparent == 0 in the child
400001b0:	c7 85 94 fd ff ff 00 	movl   $0x0,-0x26c(%ebp)
400001b7:	00 00 00 
	sys_put(cmd | SYS_REGS | SYS_COPY, child, &ps, ALLVA, ALLVA, ALLSIZE);
400001ba:	0f b6 85 74 fd ff ff 	movzbl -0x28c(%ebp),%eax
400001c1:	8b 55 08             	mov    0x8(%ebp),%edx
400001c4:	81 ca 00 10 02 00    	or     $0x21000,%edx
400001ca:	89 55 e0             	mov    %edx,-0x20(%ebp)
400001cd:	66 89 45 de          	mov    %ax,-0x22(%ebp)
400001d1:	8d 85 78 fd ff ff    	lea    -0x288(%ebp),%eax
400001d7:	89 45 d8             	mov    %eax,-0x28(%ebp)
400001da:	c7 45 d4 00 00 00 40 	movl   $0x40000000,-0x2c(%ebp)
400001e1:	c7 45 d0 00 00 00 40 	movl   $0x40000000,-0x30(%ebp)
400001e8:	c7 45 cc 00 00 00 b0 	movl   $0xb0000000,-0x34(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
400001ef:	8b 45 e0             	mov    -0x20(%ebp),%eax
400001f2:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400001f5:	8b 5d d8             	mov    -0x28(%ebp),%ebx
400001f8:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
400001fc:	8b 75 d4             	mov    -0x2c(%ebp),%esi
400001ff:	8b 7d d0             	mov    -0x30(%ebp),%edi
40000202:	8b 4d cc             	mov    -0x34(%ebp),%ecx
40000205:	cd 30                	int    $0x30
	return 1;
40000207:	b8 01 00 00 00       	mov    $0x1,%eax
}
4000020c:	81 c4 9c 02 00 00    	add    $0x29c,%esp
40000212:	5b                   	pop    %ebx
40000213:	5e                   	pop    %esi
40000214:	5f                   	pop    %edi
40000215:	5d                   	pop    %ebp
40000216:	c3                   	ret    

40000217 <join>:

void
join(int cmd, uint8_t child, int trapexpect)
{
40000217:	55                   	push   %ebp
40000218:	89 e5                	mov    %esp,%ebp
4000021a:	57                   	push   %edi
4000021b:	56                   	push   %esi
4000021c:	53                   	push   %ebx
4000021d:	81 ec ac 02 00 00    	sub    $0x2ac,%esp
40000223:	8b 45 0c             	mov    0xc(%ebp),%eax
40000226:	88 85 74 fd ff ff    	mov    %al,-0x28c(%ebp)
	// Wait for the child and retrieve its CPU state.
	// If merging, leave the highest 4MB containing the stack unmerged,
	// so that the stack acts as a "thread-private" memory area.
	struct procstate ps;
	sys_get(cmd | SYS_REGS, child, &ps, ALLVA, ALLVA, ALLSIZE-PTSIZE);
4000022c:	0f b6 85 74 fd ff ff 	movzbl -0x28c(%ebp),%eax
40000233:	8b 55 08             	mov    0x8(%ebp),%edx
40000236:	80 ce 10             	or     $0x10,%dh
40000239:	89 55 e4             	mov    %edx,-0x1c(%ebp)
4000023c:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
40000240:	8d 85 78 fd ff ff    	lea    -0x288(%ebp),%eax
40000246:	89 45 dc             	mov    %eax,-0x24(%ebp)
40000249:	c7 45 d8 00 00 00 40 	movl   $0x40000000,-0x28(%ebp)
40000250:	c7 45 d4 00 00 00 40 	movl   $0x40000000,-0x2c(%ebp)
40000257:	c7 45 d0 00 00 c0 af 	movl   $0xafc00000,-0x30(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
4000025e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40000261:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000264:	8b 5d dc             	mov    -0x24(%ebp),%ebx
40000267:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
4000026b:	8b 75 d8             	mov    -0x28(%ebp),%esi
4000026e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
40000271:	8b 4d d0             	mov    -0x30(%ebp),%ecx
40000274:	cd 30                	int    $0x30

	// Make sure the child exited with the expected trap number
	if (ps.tf.trapno != trapexpect) {
40000276:	8b 95 a8 fd ff ff    	mov    -0x258(%ebp),%edx
4000027c:	8b 45 10             	mov    0x10(%ebp),%eax
4000027f:	39 c2                	cmp    %eax,%edx
40000281:	74 59                	je     400002dc <join+0xc5>
		cprintf("  eip  0x%08x\n", ps.tf.eip);
40000283:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40000289:	89 44 24 04          	mov    %eax,0x4(%esp)
4000028d:	c7 04 24 c0 54 00 40 	movl   $0x400054c0,(%esp)
40000294:	e8 3b 2b 00 00       	call   40002dd4 <cprintf>
		cprintf("  esp  0x%08x\n", ps.tf.esp);
40000299:	8b 85 bc fd ff ff    	mov    -0x244(%ebp),%eax
4000029f:	89 44 24 04          	mov    %eax,0x4(%esp)
400002a3:	c7 04 24 cf 54 00 40 	movl   $0x400054cf,(%esp)
400002aa:	e8 25 2b 00 00       	call   40002dd4 <cprintf>
		panic("join: unexpected trap %d, expecting %d\n",
400002af:	8b 85 a8 fd ff ff    	mov    -0x258(%ebp),%eax
400002b5:	8b 55 10             	mov    0x10(%ebp),%edx
400002b8:	89 54 24 10          	mov    %edx,0x10(%esp)
400002bc:	89 44 24 0c          	mov    %eax,0xc(%esp)
400002c0:	c7 44 24 08 e0 54 00 	movl   $0x400054e0,0x8(%esp)
400002c7:	40 
400002c8:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
400002cf:	00 
400002d0:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
400002d7:	e8 64 28 00 00       	call   40002b40 <debug_panic>
			ps.tf.trapno, trapexpect);
	}
}
400002dc:	81 c4 ac 02 00 00    	add    $0x2ac,%esp
400002e2:	5b                   	pop    %ebx
400002e3:	5e                   	pop    %esi
400002e4:	5f                   	pop    %edi
400002e5:	5d                   	pop    %ebp
400002e6:	c3                   	ret    

400002e7 <gentrap>:

void
gentrap(int trap)
{
400002e7:	55                   	push   %ebp
400002e8:	89 e5                	mov    %esp,%ebp
400002ea:	83 ec 28             	sub    $0x28,%esp
	int bounds[2] = { 1, 3 };
400002ed:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
400002f4:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
	switch (trap) {
400002fb:	8b 45 08             	mov    0x8(%ebp),%eax
400002fe:	83 f8 30             	cmp    $0x30,%eax
40000301:	77 2e                	ja     40000331 <gentrap+0x4a>
40000303:	8b 04 85 28 55 00 40 	mov    0x40005528(,%eax,4),%eax
4000030a:	ff e0                	jmp    *%eax
	case T_DIVIDE:
		asm volatile("divl %0,%0" : : "r" (0));
4000030c:	b8 00 00 00 00       	mov    $0x0,%eax
40000311:	f7 f0                	div    %eax
	case T_BRKPT:
		asm volatile("int3");
40000313:	cc                   	int3   
	case T_OFLOW:
		asm volatile("addl %0,%0; into" : : "r" (0x70000000));
40000314:	b8 00 00 00 70       	mov    $0x70000000,%eax
40000319:	01 c0                	add    %eax,%eax
4000031b:	ce                   	into   
	case T_BOUND:
		asm volatile("boundl %0,%1" : : "r" (0), "m" (bounds[0]));
4000031c:	b8 00 00 00 00       	mov    $0x0,%eax
40000321:	62 45 f0             	bound  %eax,-0x10(%ebp)
	case T_ILLOP:
		asm volatile("ud2");	// guaranteed to be undefined
40000324:	0f 0b                	ud2    
	case T_GPFLT:
		asm volatile("lidt %0" : : "m" (trap));
40000326:	0f 01 5d 08          	lidtl  0x8(%ebp)
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000032a:	b8 03 00 00 00       	mov    $0x3,%eax
4000032f:	cd 30                	int    $0x30
	case T_SYSCALL:
		sys_ret();
	default:
		panic("unknown trap %d", trap);
40000331:	8b 45 08             	mov    0x8(%ebp),%eax
40000334:	89 44 24 0c          	mov    %eax,0xc(%esp)
40000338:	c7 44 24 08 16 55 00 	movl   $0x40005516,0x8(%esp)
4000033f:	40 
40000340:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
40000347:	00 
40000348:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
4000034f:	e8 ec 27 00 00       	call   40002b40 <debug_panic>

40000354 <trapcheck>:
	}
}

static void
trapcheck(int trapno)
{
40000354:	55                   	push   %ebp
40000355:	89 e5                	mov    %esp,%ebp
40000357:	83 ec 18             	sub    $0x18,%esp
	// cprintf("trapcheck %d\n", trapno);
	if (!fork(SYS_START, 0)) { gentrap(trapno); }
4000035a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000361:	00 
40000362:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000369:	e8 d6 fd ff ff       	call   40000144 <fork>
4000036e:	85 c0                	test   %eax,%eax
40000370:	75 0b                	jne    4000037d <trapcheck+0x29>
40000372:	8b 45 08             	mov    0x8(%ebp),%eax
40000375:	89 04 24             	mov    %eax,(%esp)
40000378:	e8 6a ff ff ff       	call   400002e7 <gentrap>
	join(0, 0, trapno);
4000037d:	8b 45 08             	mov    0x8(%ebp),%eax
40000380:	89 44 24 08          	mov    %eax,0x8(%esp)
40000384:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000038b:	00 
4000038c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000393:	e8 7f fe ff ff       	call   40000217 <join>
}
40000398:	c9                   	leave  
40000399:	c3                   	ret    

4000039a <cputsfaultchild>:
	if (!fork(SYS_START, 0)) \
		{ volatile int *p = (volatile int*)(va); \
		  *p = 0xdeadbeef; sys_ret(); } \
	join(0, 0, T_PGFLT);

static void cputsfaultchild(int arg) {
4000039a:	55                   	push   %ebp
4000039b:	89 e5                	mov    %esp,%ebp
4000039d:	53                   	push   %ebx
4000039e:	83 ec 10             	sub    $0x10,%esp
	sys_cputs((char*)arg);
400003a1:	8b 45 08             	mov    0x8(%ebp),%eax
400003a4:	89 45 f8             	mov    %eax,-0x8(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
400003a7:	b8 00 00 00 00       	mov    $0x0,%eax
400003ac:	8b 55 f8             	mov    -0x8(%ebp),%edx
400003af:	89 d3                	mov    %edx,%ebx
400003b1:	cd 30                	int    $0x30
}
400003b3:	83 c4 10             	add    $0x10,%esp
400003b6:	5b                   	pop    %ebx
400003b7:	5d                   	pop    %ebp
400003b8:	c3                   	ret    

400003b9 <loadcheck>:
		sys_ret(); } \
	join(0, 0, T_PGFLT);

void
loadcheck()
{
400003b9:	55                   	push   %ebp
400003ba:	89 e5                	mov    %esp,%ebp
400003bc:	83 ec 28             	sub    $0x28,%esp
	// Simple ELF loading test: make sure bss is mapped but cleared
	uint8_t *p;
	for (p = edata; p < end; p++) {
400003bf:	c7 45 f4 c0 7b 00 40 	movl   $0x40007bc0,-0xc(%ebp)
400003c6:	eb 5c                	jmp    40000424 <loadcheck+0x6b>
		if (*p != 0) cprintf("%x %d\n", p, *p);
400003c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
400003cb:	0f b6 00             	movzbl (%eax),%eax
400003ce:	84 c0                	test   %al,%al
400003d0:	74 20                	je     400003f2 <loadcheck+0x39>
400003d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
400003d5:	0f b6 00             	movzbl (%eax),%eax
400003d8:	0f b6 c0             	movzbl %al,%eax
400003db:	89 44 24 08          	mov    %eax,0x8(%esp)
400003df:	8b 45 f4             	mov    -0xc(%ebp),%eax
400003e2:	89 44 24 04          	mov    %eax,0x4(%esp)
400003e6:	c7 04 24 ec 55 00 40 	movl   $0x400055ec,(%esp)
400003ed:	e8 e2 29 00 00       	call   40002dd4 <cprintf>
		assert(*p == 0);
400003f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
400003f5:	0f b6 00             	movzbl (%eax),%eax
400003f8:	84 c0                	test   %al,%al
400003fa:	74 24                	je     40000420 <loadcheck+0x67>
400003fc:	c7 44 24 0c f3 55 00 	movl   $0x400055f3,0xc(%esp)
40000403:	40 
40000404:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
4000040b:	40 
4000040c:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
40000413:	00 
40000414:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
4000041b:	e8 20 27 00 00       	call   40002b40 <debug_panic>
void
loadcheck()
{
	// Simple ELF loading test: make sure bss is mapped but cleared
	uint8_t *p;
	for (p = edata; p < end; p++) {
40000420:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40000424:	81 7d f4 e8 9c 00 40 	cmpl   $0x40009ce8,-0xc(%ebp)
4000042b:	72 9b                	jb     400003c8 <loadcheck+0xf>
		if (*p != 0) cprintf("%x %d\n", p, *p);
		assert(*p == 0);
	}
	cprintf("testvm: loadcheck passed\n");
4000042d:	c7 04 24 10 56 00 40 	movl   $0x40005610,(%esp)
40000434:	e8 9b 29 00 00       	call   40002dd4 <cprintf>
}
40000439:	c9                   	leave  
4000043a:	c3                   	ret    

4000043b <forkcheck>:

// Check forking of simple child processes and trap redirection (once more)
void
forkcheck()
{
4000043b:	55                   	push   %ebp
4000043c:	89 e5                	mov    %esp,%ebp
4000043e:	83 ec 18             	sub    $0x18,%esp
	// Our first copy-on-write test: fork and execute a simple child.
	if (!fork(SYS_START, 0))gentrap(T_SYSCALL);
40000441:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000448:	00 
40000449:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000450:	e8 ef fc ff ff       	call   40000144 <fork>
40000455:	85 c0                	test   %eax,%eax
40000457:	75 0c                	jne    40000465 <forkcheck+0x2a>
40000459:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
40000460:	e8 82 fe ff ff       	call   400002e7 <gentrap>
	join(0, 0, T_SYSCALL);
40000465:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
4000046c:	00 
4000046d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000474:	00 
40000475:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000047c:	e8 96 fd ff ff       	call   40000217 <join>

	// Re-check trap handling and reflection from child processes
	trapcheck(T_DIVIDE);
40000481:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000488:	e8 c7 fe ff ff       	call   40000354 <trapcheck>
	trapcheck(T_BRKPT);
4000048d:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
40000494:	e8 bb fe ff ff       	call   40000354 <trapcheck>
	trapcheck(T_OFLOW);
40000499:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
400004a0:	e8 af fe ff ff       	call   40000354 <trapcheck>
	trapcheck(T_BOUND);
400004a5:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
400004ac:	e8 a3 fe ff ff       	call   40000354 <trapcheck>
	trapcheck(T_ILLOP);
400004b1:	c7 04 24 06 00 00 00 	movl   $0x6,(%esp)
400004b8:	e8 97 fe ff ff       	call   40000354 <trapcheck>
	trapcheck(T_GPFLT);
400004bd:	c7 04 24 0d 00 00 00 	movl   $0xd,(%esp)
400004c4:	e8 8b fe ff ff       	call   40000354 <trapcheck>

	// Make sure we can run several children using the same stack area
	// (since each child should get a separate logical copy)
	if (!fork(SYS_START, 0)) gentrap(T_SYSCALL);
400004c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400004d0:	00 
400004d1:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400004d8:	e8 67 fc ff ff       	call   40000144 <fork>
400004dd:	85 c0                	test   %eax,%eax
400004df:	75 0c                	jne    400004ed <forkcheck+0xb2>
400004e1:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
400004e8:	e8 fa fd ff ff       	call   400002e7 <gentrap>
	if (!fork(SYS_START, 1)) gentrap(T_DIVIDE);
400004ed:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400004f4:	00 
400004f5:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400004fc:	e8 43 fc ff ff       	call   40000144 <fork>
40000501:	85 c0                	test   %eax,%eax
40000503:	75 0c                	jne    40000511 <forkcheck+0xd6>
40000505:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000050c:	e8 d6 fd ff ff       	call   400002e7 <gentrap>
	if (!fork(SYS_START, 2)) gentrap(T_BRKPT);
40000511:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
40000518:	00 
40000519:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000520:	e8 1f fc ff ff       	call   40000144 <fork>
40000525:	85 c0                	test   %eax,%eax
40000527:	75 0c                	jne    40000535 <forkcheck+0xfa>
40000529:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
40000530:	e8 b2 fd ff ff       	call   400002e7 <gentrap>
	if (!fork(SYS_START, 3)) gentrap(T_OFLOW);
40000535:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
4000053c:	00 
4000053d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000544:	e8 fb fb ff ff       	call   40000144 <fork>
40000549:	85 c0                	test   %eax,%eax
4000054b:	75 0c                	jne    40000559 <forkcheck+0x11e>
4000054d:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
40000554:	e8 8e fd ff ff       	call   400002e7 <gentrap>
	if (!fork(SYS_START, 4)) gentrap(T_BOUND);
40000559:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
40000560:	00 
40000561:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000568:	e8 d7 fb ff ff       	call   40000144 <fork>
4000056d:	85 c0                	test   %eax,%eax
4000056f:	75 0c                	jne    4000057d <forkcheck+0x142>
40000571:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
40000578:	e8 6a fd ff ff       	call   400002e7 <gentrap>
	if (!fork(SYS_START, 5)) gentrap(T_ILLOP);
4000057d:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
40000584:	00 
40000585:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000058c:	e8 b3 fb ff ff       	call   40000144 <fork>
40000591:	85 c0                	test   %eax,%eax
40000593:	75 0c                	jne    400005a1 <forkcheck+0x166>
40000595:	c7 04 24 06 00 00 00 	movl   $0x6,(%esp)
4000059c:	e8 46 fd ff ff       	call   400002e7 <gentrap>
	if (!fork(SYS_START, 6)) gentrap(T_GPFLT);
400005a1:	c7 44 24 04 06 00 00 	movl   $0x6,0x4(%esp)
400005a8:	00 
400005a9:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400005b0:	e8 8f fb ff ff       	call   40000144 <fork>
400005b5:	85 c0                	test   %eax,%eax
400005b7:	75 0c                	jne    400005c5 <forkcheck+0x18a>
400005b9:	c7 04 24 0d 00 00 00 	movl   $0xd,(%esp)
400005c0:	e8 22 fd ff ff       	call   400002e7 <gentrap>
	join(0, 0, T_SYSCALL);
400005c5:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400005cc:	00 
400005cd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400005d4:	00 
400005d5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400005dc:	e8 36 fc ff ff       	call   40000217 <join>
	join(0, 1, T_DIVIDE);
400005e1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
400005e8:	00 
400005e9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400005f0:	00 
400005f1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400005f8:	e8 1a fc ff ff       	call   40000217 <join>
	join(0, 2, T_BRKPT);
400005fd:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
40000604:	00 
40000605:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
4000060c:	00 
4000060d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000614:	e8 fe fb ff ff       	call   40000217 <join>
	join(0, 3, T_OFLOW);
40000619:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
40000620:	00 
40000621:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
40000628:	00 
40000629:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000630:	e8 e2 fb ff ff       	call   40000217 <join>
	join(0, 4, T_BOUND);
40000635:	c7 44 24 08 05 00 00 	movl   $0x5,0x8(%esp)
4000063c:	00 
4000063d:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
40000644:	00 
40000645:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000064c:	e8 c6 fb ff ff       	call   40000217 <join>
	join(0, 5, T_ILLOP);
40000651:	c7 44 24 08 06 00 00 	movl   $0x6,0x8(%esp)
40000658:	00 
40000659:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
40000660:	00 
40000661:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000668:	e8 aa fb ff ff       	call   40000217 <join>
	join(0, 6, T_GPFLT);
4000066d:	c7 44 24 08 0d 00 00 	movl   $0xd,0x8(%esp)
40000674:	00 
40000675:	c7 44 24 04 06 00 00 	movl   $0x6,0x4(%esp)
4000067c:	00 
4000067d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000684:	e8 8e fb ff ff       	call   40000217 <join>

	// Check that kernel address space is inaccessible to user code
	readfaulttest(0);
40000689:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000690:	00 
40000691:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000698:	e8 a7 fa ff ff       	call   40000144 <fork>
4000069d:	85 c0                	test   %eax,%eax
4000069f:	75 0e                	jne    400006af <forkcheck+0x274>
400006a1:	b8 00 00 00 00       	mov    $0x0,%eax
400006a6:	8b 00                	mov    (%eax),%eax
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400006a8:	b8 03 00 00 00       	mov    $0x3,%eax
400006ad:	cd 30                	int    $0x30
400006af:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400006b6:	00 
400006b7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400006be:	00 
400006bf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400006c6:	e8 4c fb ff ff       	call   40000217 <join>
	readfaulttest(VM_USERLO-4);
400006cb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400006d2:	00 
400006d3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400006da:	e8 65 fa ff ff       	call   40000144 <fork>
400006df:	85 c0                	test   %eax,%eax
400006e1:	75 0e                	jne    400006f1 <forkcheck+0x2b6>
400006e3:	b8 fc ff ff 3f       	mov    $0x3ffffffc,%eax
400006e8:	8b 00                	mov    (%eax),%eax
400006ea:	b8 03 00 00 00       	mov    $0x3,%eax
400006ef:	cd 30                	int    $0x30
400006f1:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400006f8:	00 
400006f9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000700:	00 
40000701:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000708:	e8 0a fb ff ff       	call   40000217 <join>
	readfaulttest(VM_USERHI);
4000070d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000714:	00 
40000715:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000071c:	e8 23 fa ff ff       	call   40000144 <fork>
40000721:	85 c0                	test   %eax,%eax
40000723:	75 0e                	jne    40000733 <forkcheck+0x2f8>
40000725:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
4000072a:	8b 00                	mov    (%eax),%eax
4000072c:	b8 03 00 00 00       	mov    $0x3,%eax
40000731:	cd 30                	int    $0x30
40000733:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000073a:	00 
4000073b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000742:	00 
40000743:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000074a:	e8 c8 fa ff ff       	call   40000217 <join>
	readfaulttest(0-4);
4000074f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000756:	00 
40000757:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000075e:	e8 e1 f9 ff ff       	call   40000144 <fork>
40000763:	85 c0                	test   %eax,%eax
40000765:	75 0e                	jne    40000775 <forkcheck+0x33a>
40000767:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
4000076c:	8b 00                	mov    (%eax),%eax
4000076e:	b8 03 00 00 00       	mov    $0x3,%eax
40000773:	cd 30                	int    $0x30
40000775:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000077c:	00 
4000077d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000784:	00 
40000785:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000078c:	e8 86 fa ff ff       	call   40000217 <join>

	cprintf("testvm: forkcheck passed\n");
40000791:	c7 04 24 2a 56 00 40 	movl   $0x4000562a,(%esp)
40000798:	e8 37 26 00 00       	call   40002dd4 <cprintf>
}
4000079d:	c9                   	leave  
4000079e:	c3                   	ret    

4000079f <protcheck>:

// Check for proper virtual memory protection
void
protcheck()
{
4000079f:	55                   	push   %ebp
400007a0:	89 e5                	mov    %esp,%ebp
400007a2:	57                   	push   %edi
400007a3:	56                   	push   %esi
400007a4:	53                   	push   %ebx
400007a5:	81 ec cc 01 00 00    	sub    $0x1cc,%esp
	// Copyin/copyout protection:
	// make sure we can't use cputs/put/get data in kernel space
	cputsfaulttest(0);
400007ab:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400007b2:	00 
400007b3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400007ba:	e8 85 f9 ff ff       	call   40000144 <fork>
400007bf:	85 c0                	test   %eax,%eax
400007c1:	75 1a                	jne    400007dd <protcheck+0x3e>
400007c3:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
400007ca:	b8 00 00 00 00       	mov    $0x0,%eax
400007cf:	8b 55 dc             	mov    -0x24(%ebp),%edx
400007d2:	89 d3                	mov    %edx,%ebx
400007d4:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400007d6:	b8 03 00 00 00       	mov    $0x3,%eax
400007db:	cd 30                	int    $0x30
400007dd:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400007e4:	00 
400007e5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400007ec:	00 
400007ed:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400007f4:	e8 1e fa ff ff       	call   40000217 <join>
	cputsfaulttest(VM_USERLO-1);
400007f9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000800:	00 
40000801:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000808:	e8 37 f9 ff ff       	call   40000144 <fork>
4000080d:	85 c0                	test   %eax,%eax
4000080f:	75 1a                	jne    4000082b <protcheck+0x8c>
40000811:	c7 45 d8 ff ff ff 3f 	movl   $0x3fffffff,-0x28(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000818:	b8 00 00 00 00       	mov    $0x0,%eax
4000081d:	8b 55 d8             	mov    -0x28(%ebp),%edx
40000820:	89 d3                	mov    %edx,%ebx
40000822:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000824:	b8 03 00 00 00       	mov    $0x3,%eax
40000829:	cd 30                	int    $0x30
4000082b:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000832:	00 
40000833:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000083a:	00 
4000083b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000842:	e8 d0 f9 ff ff       	call   40000217 <join>
	cputsfaulttest(VM_USERHI);
40000847:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000084e:	00 
4000084f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000856:	e8 e9 f8 ff ff       	call   40000144 <fork>
4000085b:	85 c0                	test   %eax,%eax
4000085d:	75 1a                	jne    40000879 <protcheck+0xda>
4000085f:	c7 45 d4 00 00 00 f0 	movl   $0xf0000000,-0x2c(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000866:	b8 00 00 00 00       	mov    $0x0,%eax
4000086b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
4000086e:	89 d3                	mov    %edx,%ebx
40000870:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000872:	b8 03 00 00 00       	mov    $0x3,%eax
40000877:	cd 30                	int    $0x30
40000879:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000880:	00 
40000881:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000888:	00 
40000889:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000890:	e8 82 f9 ff ff       	call   40000217 <join>
	cputsfaulttest(~0);
40000895:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000089c:	00 
4000089d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400008a4:	e8 9b f8 ff ff       	call   40000144 <fork>
400008a9:	85 c0                	test   %eax,%eax
400008ab:	75 1a                	jne    400008c7 <protcheck+0x128>
400008ad:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
400008b4:	b8 00 00 00 00       	mov    $0x0,%eax
400008b9:	8b 55 d0             	mov    -0x30(%ebp),%edx
400008bc:	89 d3                	mov    %edx,%ebx
400008be:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400008c0:	b8 03 00 00 00       	mov    $0x3,%eax
400008c5:	cd 30                	int    $0x30
400008c7:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400008ce:	00 
400008cf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400008d6:	00 
400008d7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400008de:	e8 34 f9 ff ff       	call   40000217 <join>
	putfaulttest(0);
400008e3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400008ea:	00 
400008eb:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400008f2:	e8 4d f8 ff ff       	call   40000144 <fork>
400008f7:	85 c0                	test   %eax,%eax
400008f9:	75 48                	jne    40000943 <protcheck+0x1a4>
400008fb:	c7 45 cc 00 10 00 00 	movl   $0x1000,-0x34(%ebp)
40000902:	66 c7 45 ca 00 00    	movw   $0x0,-0x36(%ebp)
40000908:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)
4000090f:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
40000916:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
4000091d:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40000924:	8b 45 cc             	mov    -0x34(%ebp),%eax
40000927:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
4000092a:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
4000092d:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
40000931:	8b 75 c0             	mov    -0x40(%ebp),%esi
40000934:	8b 7d bc             	mov    -0x44(%ebp),%edi
40000937:	8b 4d b8             	mov    -0x48(%ebp),%ecx
4000093a:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000093c:	b8 03 00 00 00       	mov    $0x3,%eax
40000941:	cd 30                	int    $0x30
40000943:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000094a:	00 
4000094b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000952:	00 
40000953:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000095a:	e8 b8 f8 ff ff       	call   40000217 <join>
	putfaulttest(VM_USERLO-1);
4000095f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000966:	00 
40000967:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000096e:	e8 d1 f7 ff ff       	call   40000144 <fork>
40000973:	85 c0                	test   %eax,%eax
40000975:	75 48                	jne    400009bf <protcheck+0x220>
40000977:	c7 45 b4 00 10 00 00 	movl   $0x1000,-0x4c(%ebp)
4000097e:	66 c7 45 b2 00 00    	movw   $0x0,-0x4e(%ebp)
40000984:	c7 45 ac ff ff ff 3f 	movl   $0x3fffffff,-0x54(%ebp)
4000098b:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
40000992:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
40000999:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
400009a0:	8b 45 b4             	mov    -0x4c(%ebp),%eax
400009a3:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400009a6:	8b 5d ac             	mov    -0x54(%ebp),%ebx
400009a9:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
400009ad:	8b 75 a8             	mov    -0x58(%ebp),%esi
400009b0:	8b 7d a4             	mov    -0x5c(%ebp),%edi
400009b3:	8b 4d a0             	mov    -0x60(%ebp),%ecx
400009b6:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400009b8:	b8 03 00 00 00       	mov    $0x3,%eax
400009bd:	cd 30                	int    $0x30
400009bf:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400009c6:	00 
400009c7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400009ce:	00 
400009cf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400009d6:	e8 3c f8 ff ff       	call   40000217 <join>
	putfaulttest(VM_USERHI);
400009db:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400009e2:	00 
400009e3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400009ea:	e8 55 f7 ff ff       	call   40000144 <fork>
400009ef:	85 c0                	test   %eax,%eax
400009f1:	75 48                	jne    40000a3b <protcheck+0x29c>
400009f3:	c7 45 9c 00 10 00 00 	movl   $0x1000,-0x64(%ebp)
400009fa:	66 c7 45 9a 00 00    	movw   $0x0,-0x66(%ebp)
40000a00:	c7 45 94 00 00 00 f0 	movl   $0xf0000000,-0x6c(%ebp)
40000a07:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
40000a0e:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
40000a15:	c7 45 88 00 00 00 00 	movl   $0x0,-0x78(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40000a1c:	8b 45 9c             	mov    -0x64(%ebp),%eax
40000a1f:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40000a22:	8b 5d 94             	mov    -0x6c(%ebp),%ebx
40000a25:	0f b7 55 9a          	movzwl -0x66(%ebp),%edx
40000a29:	8b 75 90             	mov    -0x70(%ebp),%esi
40000a2c:	8b 7d 8c             	mov    -0x74(%ebp),%edi
40000a2f:	8b 4d 88             	mov    -0x78(%ebp),%ecx
40000a32:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000a34:	b8 03 00 00 00       	mov    $0x3,%eax
40000a39:	cd 30                	int    $0x30
40000a3b:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000a42:	00 
40000a43:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000a4a:	00 
40000a4b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000a52:	e8 c0 f7 ff ff       	call   40000217 <join>
	putfaulttest(~0);
40000a57:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000a5e:	00 
40000a5f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000a66:	e8 d9 f6 ff ff       	call   40000144 <fork>
40000a6b:	85 c0                	test   %eax,%eax
40000a6d:	75 60                	jne    40000acf <protcheck+0x330>
40000a6f:	c7 45 84 00 10 00 00 	movl   $0x1000,-0x7c(%ebp)
40000a76:	66 c7 45 82 00 00    	movw   $0x0,-0x7e(%ebp)
40000a7c:	c7 85 7c ff ff ff ff 	movl   $0xffffffff,-0x84(%ebp)
40000a83:	ff ff ff 
40000a86:	c7 85 78 ff ff ff 00 	movl   $0x0,-0x88(%ebp)
40000a8d:	00 00 00 
40000a90:	c7 85 74 ff ff ff 00 	movl   $0x0,-0x8c(%ebp)
40000a97:	00 00 00 
40000a9a:	c7 85 70 ff ff ff 00 	movl   $0x0,-0x90(%ebp)
40000aa1:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40000aa4:	8b 45 84             	mov    -0x7c(%ebp),%eax
40000aa7:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40000aaa:	8b 9d 7c ff ff ff    	mov    -0x84(%ebp),%ebx
40000ab0:	0f b7 55 82          	movzwl -0x7e(%ebp),%edx
40000ab4:	8b b5 78 ff ff ff    	mov    -0x88(%ebp),%esi
40000aba:	8b bd 74 ff ff ff    	mov    -0x8c(%ebp),%edi
40000ac0:	8b 8d 70 ff ff ff    	mov    -0x90(%ebp),%ecx
40000ac6:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000ac8:	b8 03 00 00 00       	mov    $0x3,%eax
40000acd:	cd 30                	int    $0x30
40000acf:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000ad6:	00 
40000ad7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000ade:	00 
40000adf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000ae6:	e8 2c f7 ff ff       	call   40000217 <join>
	getfaulttest(0);
40000aeb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000af2:	00 
40000af3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000afa:	e8 45 f6 ff ff       	call   40000144 <fork>
40000aff:	85 c0                	test   %eax,%eax
40000b01:	75 6c                	jne    40000b6f <protcheck+0x3d0>
40000b03:	c7 85 6c ff ff ff 00 	movl   $0x1000,-0x94(%ebp)
40000b0a:	10 00 00 
40000b0d:	66 c7 85 6a ff ff ff 	movw   $0x0,-0x96(%ebp)
40000b14:	00 00 
40000b16:	c7 85 64 ff ff ff 00 	movl   $0x0,-0x9c(%ebp)
40000b1d:	00 00 00 
40000b20:	c7 85 60 ff ff ff 00 	movl   $0x0,-0xa0(%ebp)
40000b27:	00 00 00 
40000b2a:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
40000b31:	00 00 00 
40000b34:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
40000b3b:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40000b3e:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
40000b44:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000b47:	8b 9d 64 ff ff ff    	mov    -0x9c(%ebp),%ebx
40000b4d:	0f b7 95 6a ff ff ff 	movzwl -0x96(%ebp),%edx
40000b54:	8b b5 60 ff ff ff    	mov    -0xa0(%ebp),%esi
40000b5a:	8b bd 5c ff ff ff    	mov    -0xa4(%ebp),%edi
40000b60:	8b 8d 58 ff ff ff    	mov    -0xa8(%ebp),%ecx
40000b66:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000b68:	b8 03 00 00 00       	mov    $0x3,%eax
40000b6d:	cd 30                	int    $0x30
40000b6f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000b76:	00 
40000b77:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000b7e:	00 
40000b7f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000b86:	e8 8c f6 ff ff       	call   40000217 <join>
	getfaulttest(VM_USERLO-1);
40000b8b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000b92:	00 
40000b93:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000b9a:	e8 a5 f5 ff ff       	call   40000144 <fork>
40000b9f:	85 c0                	test   %eax,%eax
40000ba1:	75 6c                	jne    40000c0f <protcheck+0x470>
40000ba3:	c7 85 54 ff ff ff 00 	movl   $0x1000,-0xac(%ebp)
40000baa:	10 00 00 
40000bad:	66 c7 85 52 ff ff ff 	movw   $0x0,-0xae(%ebp)
40000bb4:	00 00 
40000bb6:	c7 85 4c ff ff ff ff 	movl   $0x3fffffff,-0xb4(%ebp)
40000bbd:	ff ff 3f 
40000bc0:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
40000bc7:	00 00 00 
40000bca:	c7 85 44 ff ff ff 00 	movl   $0x0,-0xbc(%ebp)
40000bd1:	00 00 00 
40000bd4:	c7 85 40 ff ff ff 00 	movl   $0x0,-0xc0(%ebp)
40000bdb:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40000bde:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
40000be4:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000be7:	8b 9d 4c ff ff ff    	mov    -0xb4(%ebp),%ebx
40000bed:	0f b7 95 52 ff ff ff 	movzwl -0xae(%ebp),%edx
40000bf4:	8b b5 48 ff ff ff    	mov    -0xb8(%ebp),%esi
40000bfa:	8b bd 44 ff ff ff    	mov    -0xbc(%ebp),%edi
40000c00:	8b 8d 40 ff ff ff    	mov    -0xc0(%ebp),%ecx
40000c06:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000c08:	b8 03 00 00 00       	mov    $0x3,%eax
40000c0d:	cd 30                	int    $0x30
40000c0f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000c16:	00 
40000c17:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000c1e:	00 
40000c1f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000c26:	e8 ec f5 ff ff       	call   40000217 <join>
	getfaulttest(VM_USERHI);
40000c2b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000c32:	00 
40000c33:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000c3a:	e8 05 f5 ff ff       	call   40000144 <fork>
40000c3f:	85 c0                	test   %eax,%eax
40000c41:	75 6c                	jne    40000caf <protcheck+0x510>
40000c43:	c7 85 3c ff ff ff 00 	movl   $0x1000,-0xc4(%ebp)
40000c4a:	10 00 00 
40000c4d:	66 c7 85 3a ff ff ff 	movw   $0x0,-0xc6(%ebp)
40000c54:	00 00 
40000c56:	c7 85 34 ff ff ff 00 	movl   $0xf0000000,-0xcc(%ebp)
40000c5d:	00 00 f0 
40000c60:	c7 85 30 ff ff ff 00 	movl   $0x0,-0xd0(%ebp)
40000c67:	00 00 00 
40000c6a:	c7 85 2c ff ff ff 00 	movl   $0x0,-0xd4(%ebp)
40000c71:	00 00 00 
40000c74:	c7 85 28 ff ff ff 00 	movl   $0x0,-0xd8(%ebp)
40000c7b:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40000c7e:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
40000c84:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000c87:	8b 9d 34 ff ff ff    	mov    -0xcc(%ebp),%ebx
40000c8d:	0f b7 95 3a ff ff ff 	movzwl -0xc6(%ebp),%edx
40000c94:	8b b5 30 ff ff ff    	mov    -0xd0(%ebp),%esi
40000c9a:	8b bd 2c ff ff ff    	mov    -0xd4(%ebp),%edi
40000ca0:	8b 8d 28 ff ff ff    	mov    -0xd8(%ebp),%ecx
40000ca6:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000ca8:	b8 03 00 00 00       	mov    $0x3,%eax
40000cad:	cd 30                	int    $0x30
40000caf:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000cb6:	00 
40000cb7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000cbe:	00 
40000cbf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000cc6:	e8 4c f5 ff ff       	call   40000217 <join>
	getfaulttest(~0);
40000ccb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000cd2:	00 
40000cd3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000cda:	e8 65 f4 ff ff       	call   40000144 <fork>
40000cdf:	85 c0                	test   %eax,%eax
40000ce1:	75 6c                	jne    40000d4f <protcheck+0x5b0>
40000ce3:	c7 85 24 ff ff ff 00 	movl   $0x1000,-0xdc(%ebp)
40000cea:	10 00 00 
40000ced:	66 c7 85 22 ff ff ff 	movw   $0x0,-0xde(%ebp)
40000cf4:	00 00 
40000cf6:	c7 85 1c ff ff ff ff 	movl   $0xffffffff,-0xe4(%ebp)
40000cfd:	ff ff ff 
40000d00:	c7 85 18 ff ff ff 00 	movl   $0x0,-0xe8(%ebp)
40000d07:	00 00 00 
40000d0a:	c7 85 14 ff ff ff 00 	movl   $0x0,-0xec(%ebp)
40000d11:	00 00 00 
40000d14:	c7 85 10 ff ff ff 00 	movl   $0x0,-0xf0(%ebp)
40000d1b:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40000d1e:	8b 85 24 ff ff ff    	mov    -0xdc(%ebp),%eax
40000d24:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000d27:	8b 9d 1c ff ff ff    	mov    -0xe4(%ebp),%ebx
40000d2d:	0f b7 95 22 ff ff ff 	movzwl -0xde(%ebp),%edx
40000d34:	8b b5 18 ff ff ff    	mov    -0xe8(%ebp),%esi
40000d3a:	8b bd 14 ff ff ff    	mov    -0xec(%ebp),%edi
40000d40:	8b 8d 10 ff ff ff    	mov    -0xf0(%ebp),%ecx
40000d46:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000d48:	b8 03 00 00 00       	mov    $0x3,%eax
40000d4d:	cd 30                	int    $0x30
40000d4f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000d56:	00 
40000d57:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000d5e:	00 
40000d5f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000d66:	e8 ac f4 ff ff       	call   40000217 <join>

warn("here");
40000d6b:	c7 44 24 08 44 56 00 	movl   $0x40005644,0x8(%esp)
40000d72:	40 
40000d73:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
40000d7a:	00 
40000d7b:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40000d82:	e8 23 1e 00 00       	call   40002baa <debug_warn>
	// Check that unused parts of user space are also inaccessible
	readfaulttest(VM_USERLO+PTSIZE);
40000d87:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000d8e:	00 
40000d8f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000d96:	e8 a9 f3 ff ff       	call   40000144 <fork>
40000d9b:	85 c0                	test   %eax,%eax
40000d9d:	75 0e                	jne    40000dad <protcheck+0x60e>
40000d9f:	b8 00 00 40 40       	mov    $0x40400000,%eax
40000da4:	8b 00                	mov    (%eax),%eax
40000da6:	b8 03 00 00 00       	mov    $0x3,%eax
40000dab:	cd 30                	int    $0x30
40000dad:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000db4:	00 
40000db5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000dbc:	00 
40000dbd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000dc4:	e8 4e f4 ff ff       	call   40000217 <join>
warn("here");
40000dc9:	c7 44 24 08 44 56 00 	movl   $0x40005644,0x8(%esp)
40000dd0:	40 
40000dd1:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
40000dd8:	00 
40000dd9:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40000de0:	e8 c5 1d 00 00       	call   40002baa <debug_warn>
	readfaulttest(VM_USERHI-PTSIZE);
40000de5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000dec:	00 
40000ded:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000df4:	e8 4b f3 ff ff       	call   40000144 <fork>
40000df9:	85 c0                	test   %eax,%eax
40000dfb:	75 0e                	jne    40000e0b <protcheck+0x66c>
40000dfd:	b8 00 00 c0 ef       	mov    $0xefc00000,%eax
40000e02:	8b 00                	mov    (%eax),%eax
40000e04:	b8 03 00 00 00       	mov    $0x3,%eax
40000e09:	cd 30                	int    $0x30
40000e0b:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000e12:	00 
40000e13:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e1a:	00 
40000e1b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000e22:	e8 f0 f3 ff ff       	call   40000217 <join>
warn("here");
40000e27:	c7 44 24 08 44 56 00 	movl   $0x40005644,0x8(%esp)
40000e2e:	40 
40000e2f:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
40000e36:	00 
40000e37:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40000e3e:	e8 67 1d 00 00       	call   40002baa <debug_warn>
	readfaulttest(VM_USERHI-PTSIZE*2);
40000e43:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e4a:	00 
40000e4b:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000e52:	e8 ed f2 ff ff       	call   40000144 <fork>
40000e57:	85 c0                	test   %eax,%eax
40000e59:	75 0e                	jne    40000e69 <protcheck+0x6ca>
40000e5b:	b8 00 00 80 ef       	mov    $0xef800000,%eax
40000e60:	8b 00                	mov    (%eax),%eax
40000e62:	b8 03 00 00 00       	mov    $0x3,%eax
40000e67:	cd 30                	int    $0x30
40000e69:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000e70:	00 
40000e71:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e78:	00 
40000e79:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000e80:	e8 92 f3 ff ff       	call   40000217 <join>
warn("here");
40000e85:	c7 44 24 08 44 56 00 	movl   $0x40005644,0x8(%esp)
40000e8c:	40 
40000e8d:	c7 44 24 04 e1 00 00 	movl   $0xe1,0x4(%esp)
40000e94:	00 
40000e95:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40000e9c:	e8 09 1d 00 00       	call   40002baa <debug_warn>
	cputsfaulttest(VM_USERLO+PTSIZE);
40000ea1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000ea8:	00 
40000ea9:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000eb0:	e8 8f f2 ff ff       	call   40000144 <fork>
40000eb5:	85 c0                	test   %eax,%eax
40000eb7:	75 20                	jne    40000ed9 <protcheck+0x73a>
40000eb9:	c7 85 0c ff ff ff 00 	movl   $0x40400000,-0xf4(%ebp)
40000ec0:	00 40 40 
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000ec3:	b8 00 00 00 00       	mov    $0x0,%eax
40000ec8:	8b 95 0c ff ff ff    	mov    -0xf4(%ebp),%edx
40000ece:	89 d3                	mov    %edx,%ebx
40000ed0:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000ed2:	b8 03 00 00 00       	mov    $0x3,%eax
40000ed7:	cd 30                	int    $0x30
40000ed9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000ee0:	00 
40000ee1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000ee8:	00 
40000ee9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000ef0:	e8 22 f3 ff ff       	call   40000217 <join>
warn("here");
40000ef5:	c7 44 24 08 44 56 00 	movl   $0x40005644,0x8(%esp)
40000efc:	40 
40000efd:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
40000f04:	00 
40000f05:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40000f0c:	e8 99 1c 00 00       	call   40002baa <debug_warn>
	cputsfaulttest(VM_USERHI-PTSIZE);
40000f11:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000f18:	00 
40000f19:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000f20:	e8 1f f2 ff ff       	call   40000144 <fork>
40000f25:	85 c0                	test   %eax,%eax
40000f27:	75 20                	jne    40000f49 <protcheck+0x7aa>
40000f29:	c7 85 08 ff ff ff 00 	movl   $0xefc00000,-0xf8(%ebp)
40000f30:	00 c0 ef 
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000f33:	b8 00 00 00 00       	mov    $0x0,%eax
40000f38:	8b 95 08 ff ff ff    	mov    -0xf8(%ebp),%edx
40000f3e:	89 d3                	mov    %edx,%ebx
40000f40:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000f42:	b8 03 00 00 00       	mov    $0x3,%eax
40000f47:	cd 30                	int    $0x30
40000f49:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000f50:	00 
40000f51:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000f58:	00 
40000f59:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000f60:	e8 b2 f2 ff ff       	call   40000217 <join>
warn("here");
40000f65:	c7 44 24 08 44 56 00 	movl   $0x40005644,0x8(%esp)
40000f6c:	40 
40000f6d:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
40000f74:	00 
40000f75:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40000f7c:	e8 29 1c 00 00       	call   40002baa <debug_warn>
	cputsfaulttest(VM_USERHI-PTSIZE*2);
40000f81:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000f88:	00 
40000f89:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000f90:	e8 af f1 ff ff       	call   40000144 <fork>
40000f95:	85 c0                	test   %eax,%eax
40000f97:	75 20                	jne    40000fb9 <protcheck+0x81a>
40000f99:	c7 85 04 ff ff ff 00 	movl   $0xef800000,-0xfc(%ebp)
40000fa0:	00 80 ef 
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000fa3:	b8 00 00 00 00       	mov    $0x0,%eax
40000fa8:	8b 95 04 ff ff ff    	mov    -0xfc(%ebp),%edx
40000fae:	89 d3                	mov    %edx,%ebx
40000fb0:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000fb2:	b8 03 00 00 00       	mov    $0x3,%eax
40000fb7:	cd 30                	int    $0x30
40000fb9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000fc0:	00 
40000fc1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000fc8:	00 
40000fc9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000fd0:	e8 42 f2 ff ff       	call   40000217 <join>
warn("here");
40000fd5:	c7 44 24 08 44 56 00 	movl   $0x40005644,0x8(%esp)
40000fdc:	40 
40000fdd:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
40000fe4:	00 
40000fe5:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40000fec:	e8 b9 1b 00 00       	call   40002baa <debug_warn>
	putfaulttest(VM_USERLO+PTSIZE);
40000ff1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000ff8:	00 
40000ff9:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001000:	e8 3f f1 ff ff       	call   40000144 <fork>
40001005:	85 c0                	test   %eax,%eax
40001007:	75 6c                	jne    40001075 <protcheck+0x8d6>
40001009:	c7 85 00 ff ff ff 00 	movl   $0x1000,-0x100(%ebp)
40001010:	10 00 00 
40001013:	66 c7 85 fe fe ff ff 	movw   $0x0,-0x102(%ebp)
4000101a:	00 00 
4000101c:	c7 85 f8 fe ff ff 00 	movl   $0x40400000,-0x108(%ebp)
40001023:	00 40 40 
40001026:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
4000102d:	00 00 00 
40001030:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
40001037:	00 00 00 
4000103a:	c7 85 ec fe ff ff 00 	movl   $0x0,-0x114(%ebp)
40001041:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40001044:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
4000104a:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
4000104d:	8b 9d f8 fe ff ff    	mov    -0x108(%ebp),%ebx
40001053:	0f b7 95 fe fe ff ff 	movzwl -0x102(%ebp),%edx
4000105a:	8b b5 f4 fe ff ff    	mov    -0x10c(%ebp),%esi
40001060:	8b bd f0 fe ff ff    	mov    -0x110(%ebp),%edi
40001066:	8b 8d ec fe ff ff    	mov    -0x114(%ebp),%ecx
4000106c:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000106e:	b8 03 00 00 00       	mov    $0x3,%eax
40001073:	cd 30                	int    $0x30
40001075:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000107c:	00 
4000107d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001084:	00 
40001085:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000108c:	e8 86 f1 ff ff       	call   40000217 <join>
warn("here");
40001091:	c7 44 24 08 44 56 00 	movl   $0x40005644,0x8(%esp)
40001098:	40 
40001099:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
400010a0:	00 
400010a1:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
400010a8:	e8 fd 1a 00 00       	call   40002baa <debug_warn>
	putfaulttest(VM_USERHI-PTSIZE);
400010ad:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400010b4:	00 
400010b5:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400010bc:	e8 83 f0 ff ff       	call   40000144 <fork>
400010c1:	85 c0                	test   %eax,%eax
400010c3:	75 6c                	jne    40001131 <protcheck+0x992>
400010c5:	c7 85 e8 fe ff ff 00 	movl   $0x1000,-0x118(%ebp)
400010cc:	10 00 00 
400010cf:	66 c7 85 e6 fe ff ff 	movw   $0x0,-0x11a(%ebp)
400010d6:	00 00 
400010d8:	c7 85 e0 fe ff ff 00 	movl   $0xefc00000,-0x120(%ebp)
400010df:	00 c0 ef 
400010e2:	c7 85 dc fe ff ff 00 	movl   $0x0,-0x124(%ebp)
400010e9:	00 00 00 
400010ec:	c7 85 d8 fe ff ff 00 	movl   $0x0,-0x128(%ebp)
400010f3:	00 00 00 
400010f6:	c7 85 d4 fe ff ff 00 	movl   $0x0,-0x12c(%ebp)
400010fd:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40001100:	8b 85 e8 fe ff ff    	mov    -0x118(%ebp),%eax
40001106:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40001109:	8b 9d e0 fe ff ff    	mov    -0x120(%ebp),%ebx
4000110f:	0f b7 95 e6 fe ff ff 	movzwl -0x11a(%ebp),%edx
40001116:	8b b5 dc fe ff ff    	mov    -0x124(%ebp),%esi
4000111c:	8b bd d8 fe ff ff    	mov    -0x128(%ebp),%edi
40001122:	8b 8d d4 fe ff ff    	mov    -0x12c(%ebp),%ecx
40001128:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000112a:	b8 03 00 00 00       	mov    $0x3,%eax
4000112f:	cd 30                	int    $0x30
40001131:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001138:	00 
40001139:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001140:	00 
40001141:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001148:	e8 ca f0 ff ff       	call   40000217 <join>
warn("here");
4000114d:	c7 44 24 08 44 56 00 	movl   $0x40005644,0x8(%esp)
40001154:	40 
40001155:	c7 44 24 04 eb 00 00 	movl   $0xeb,0x4(%esp)
4000115c:	00 
4000115d:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40001164:	e8 41 1a 00 00       	call   40002baa <debug_warn>
	putfaulttest(VM_USERHI-PTSIZE*2);
40001169:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001170:	00 
40001171:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001178:	e8 c7 ef ff ff       	call   40000144 <fork>
4000117d:	85 c0                	test   %eax,%eax
4000117f:	75 6c                	jne    400011ed <protcheck+0xa4e>
40001181:	c7 85 d0 fe ff ff 00 	movl   $0x1000,-0x130(%ebp)
40001188:	10 00 00 
4000118b:	66 c7 85 ce fe ff ff 	movw   $0x0,-0x132(%ebp)
40001192:	00 00 
40001194:	c7 85 c8 fe ff ff 00 	movl   $0xef800000,-0x138(%ebp)
4000119b:	00 80 ef 
4000119e:	c7 85 c4 fe ff ff 00 	movl   $0x0,-0x13c(%ebp)
400011a5:	00 00 00 
400011a8:	c7 85 c0 fe ff ff 00 	movl   $0x0,-0x140(%ebp)
400011af:	00 00 00 
400011b2:	c7 85 bc fe ff ff 00 	movl   $0x0,-0x144(%ebp)
400011b9:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
400011bc:	8b 85 d0 fe ff ff    	mov    -0x130(%ebp),%eax
400011c2:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400011c5:	8b 9d c8 fe ff ff    	mov    -0x138(%ebp),%ebx
400011cb:	0f b7 95 ce fe ff ff 	movzwl -0x132(%ebp),%edx
400011d2:	8b b5 c4 fe ff ff    	mov    -0x13c(%ebp),%esi
400011d8:	8b bd c0 fe ff ff    	mov    -0x140(%ebp),%edi
400011de:	8b 8d bc fe ff ff    	mov    -0x144(%ebp),%ecx
400011e4:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400011e6:	b8 03 00 00 00       	mov    $0x3,%eax
400011eb:	cd 30                	int    $0x30
400011ed:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400011f4:	00 
400011f5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400011fc:	00 
400011fd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001204:	e8 0e f0 ff ff       	call   40000217 <join>
warn("here");
40001209:	c7 44 24 08 44 56 00 	movl   $0x40005644,0x8(%esp)
40001210:	40 
40001211:	c7 44 24 04 ed 00 00 	movl   $0xed,0x4(%esp)
40001218:	00 
40001219:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40001220:	e8 85 19 00 00       	call   40002baa <debug_warn>
	getfaulttest(VM_USERLO+PTSIZE);
40001225:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000122c:	00 
4000122d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001234:	e8 0b ef ff ff       	call   40000144 <fork>
40001239:	85 c0                	test   %eax,%eax
4000123b:	75 6c                	jne    400012a9 <protcheck+0xb0a>
4000123d:	c7 85 b8 fe ff ff 00 	movl   $0x1000,-0x148(%ebp)
40001244:	10 00 00 
40001247:	66 c7 85 b6 fe ff ff 	movw   $0x0,-0x14a(%ebp)
4000124e:	00 00 
40001250:	c7 85 b0 fe ff ff 00 	movl   $0x40400000,-0x150(%ebp)
40001257:	00 40 40 
4000125a:	c7 85 ac fe ff ff 00 	movl   $0x0,-0x154(%ebp)
40001261:	00 00 00 
40001264:	c7 85 a8 fe ff ff 00 	movl   $0x0,-0x158(%ebp)
4000126b:	00 00 00 
4000126e:	c7 85 a4 fe ff ff 00 	movl   $0x0,-0x15c(%ebp)
40001275:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001278:	8b 85 b8 fe ff ff    	mov    -0x148(%ebp),%eax
4000127e:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001281:	8b 9d b0 fe ff ff    	mov    -0x150(%ebp),%ebx
40001287:	0f b7 95 b6 fe ff ff 	movzwl -0x14a(%ebp),%edx
4000128e:	8b b5 ac fe ff ff    	mov    -0x154(%ebp),%esi
40001294:	8b bd a8 fe ff ff    	mov    -0x158(%ebp),%edi
4000129a:	8b 8d a4 fe ff ff    	mov    -0x15c(%ebp),%ecx
400012a0:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400012a2:	b8 03 00 00 00       	mov    $0x3,%eax
400012a7:	cd 30                	int    $0x30
400012a9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400012b0:	00 
400012b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400012b8:	00 
400012b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400012c0:	e8 52 ef ff ff       	call   40000217 <join>
warn("here");
400012c5:	c7 44 24 08 44 56 00 	movl   $0x40005644,0x8(%esp)
400012cc:	40 
400012cd:	c7 44 24 04 ef 00 00 	movl   $0xef,0x4(%esp)
400012d4:	00 
400012d5:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
400012dc:	e8 c9 18 00 00       	call   40002baa <debug_warn>
	getfaulttest(VM_USERHI-PTSIZE);
400012e1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400012e8:	00 
400012e9:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400012f0:	e8 4f ee ff ff       	call   40000144 <fork>
400012f5:	85 c0                	test   %eax,%eax
400012f7:	75 6c                	jne    40001365 <protcheck+0xbc6>
400012f9:	c7 85 a0 fe ff ff 00 	movl   $0x1000,-0x160(%ebp)
40001300:	10 00 00 
40001303:	66 c7 85 9e fe ff ff 	movw   $0x0,-0x162(%ebp)
4000130a:	00 00 
4000130c:	c7 85 98 fe ff ff 00 	movl   $0xefc00000,-0x168(%ebp)
40001313:	00 c0 ef 
40001316:	c7 85 94 fe ff ff 00 	movl   $0x0,-0x16c(%ebp)
4000131d:	00 00 00 
40001320:	c7 85 90 fe ff ff 00 	movl   $0x0,-0x170(%ebp)
40001327:	00 00 00 
4000132a:	c7 85 8c fe ff ff 00 	movl   $0x0,-0x174(%ebp)
40001331:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001334:	8b 85 a0 fe ff ff    	mov    -0x160(%ebp),%eax
4000133a:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000133d:	8b 9d 98 fe ff ff    	mov    -0x168(%ebp),%ebx
40001343:	0f b7 95 9e fe ff ff 	movzwl -0x162(%ebp),%edx
4000134a:	8b b5 94 fe ff ff    	mov    -0x16c(%ebp),%esi
40001350:	8b bd 90 fe ff ff    	mov    -0x170(%ebp),%edi
40001356:	8b 8d 8c fe ff ff    	mov    -0x174(%ebp),%ecx
4000135c:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000135e:	b8 03 00 00 00       	mov    $0x3,%eax
40001363:	cd 30                	int    $0x30
40001365:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000136c:	00 
4000136d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001374:	00 
40001375:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000137c:	e8 96 ee ff ff       	call   40000217 <join>
warn("here");
40001381:	c7 44 24 08 44 56 00 	movl   $0x40005644,0x8(%esp)
40001388:	40 
40001389:	c7 44 24 04 f1 00 00 	movl   $0xf1,0x4(%esp)
40001390:	00 
40001391:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40001398:	e8 0d 18 00 00       	call   40002baa <debug_warn>
	getfaulttest(VM_USERHI-PTSIZE*2);
4000139d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400013a4:	00 
400013a5:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400013ac:	e8 93 ed ff ff       	call   40000144 <fork>
400013b1:	85 c0                	test   %eax,%eax
400013b3:	75 6c                	jne    40001421 <protcheck+0xc82>
400013b5:	c7 85 88 fe ff ff 00 	movl   $0x1000,-0x178(%ebp)
400013bc:	10 00 00 
400013bf:	66 c7 85 86 fe ff ff 	movw   $0x0,-0x17a(%ebp)
400013c6:	00 00 
400013c8:	c7 85 80 fe ff ff 00 	movl   $0xef800000,-0x180(%ebp)
400013cf:	00 80 ef 
400013d2:	c7 85 7c fe ff ff 00 	movl   $0x0,-0x184(%ebp)
400013d9:	00 00 00 
400013dc:	c7 85 78 fe ff ff 00 	movl   $0x0,-0x188(%ebp)
400013e3:	00 00 00 
400013e6:	c7 85 74 fe ff ff 00 	movl   $0x0,-0x18c(%ebp)
400013ed:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400013f0:	8b 85 88 fe ff ff    	mov    -0x178(%ebp),%eax
400013f6:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400013f9:	8b 9d 80 fe ff ff    	mov    -0x180(%ebp),%ebx
400013ff:	0f b7 95 86 fe ff ff 	movzwl -0x17a(%ebp),%edx
40001406:	8b b5 7c fe ff ff    	mov    -0x184(%ebp),%esi
4000140c:	8b bd 78 fe ff ff    	mov    -0x188(%ebp),%edi
40001412:	8b 8d 74 fe ff ff    	mov    -0x18c(%ebp),%ecx
40001418:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000141a:	b8 03 00 00 00       	mov    $0x3,%eax
4000141f:	cd 30                	int    $0x30
40001421:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001428:	00 
40001429:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001430:	00 
40001431:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001438:	e8 da ed ff ff       	call   40000217 <join>
warn("here");
4000143d:	c7 44 24 08 44 56 00 	movl   $0x40005644,0x8(%esp)
40001444:	40 
40001445:	c7 44 24 04 f3 00 00 	movl   $0xf3,0x4(%esp)
4000144c:	00 
4000144d:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40001454:	e8 51 17 00 00       	call   40002baa <debug_warn>

	// Check that our text segment is mapped read-only
	writefaulttest((int)start);
40001459:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001460:	00 
40001461:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001468:	e8 d7 ec ff ff       	call   40000144 <fork>
4000146d:	85 c0                	test   %eax,%eax
4000146f:	75 17                	jne    40001488 <protcheck+0xce9>
40001471:	c7 45 e4 00 01 00 40 	movl   $0x40000100,-0x1c(%ebp)
40001478:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000147b:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
40001481:	b8 03 00 00 00       	mov    $0x3,%eax
40001486:	cd 30                	int    $0x30
40001488:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000148f:	00 
40001490:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001497:	00 
40001498:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000149f:	e8 73 ed ff ff       	call   40000217 <join>
	writefaulttest((int)etext-4);
400014a4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400014ab:	00 
400014ac:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400014b3:	e8 8c ec ff ff       	call   40000144 <fork>
400014b8:	85 c0                	test   %eax,%eax
400014ba:	75 1b                	jne    400014d7 <protcheck+0xd38>
400014bc:	b8 af 54 00 40       	mov    $0x400054af,%eax
400014c1:	83 e8 04             	sub    $0x4,%eax
400014c4:	89 45 e0             	mov    %eax,-0x20(%ebp)
400014c7:	8b 45 e0             	mov    -0x20(%ebp),%eax
400014ca:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
400014d0:	b8 03 00 00 00       	mov    $0x3,%eax
400014d5:	cd 30                	int    $0x30
400014d7:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400014de:	00 
400014df:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400014e6:	00 
400014e7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400014ee:	e8 24 ed ff ff       	call   40000217 <join>
	getfaulttest((int)start);
400014f3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400014fa:	00 
400014fb:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001502:	e8 3d ec ff ff       	call   40000144 <fork>
40001507:	85 c0                	test   %eax,%eax
40001509:	75 6c                	jne    40001577 <protcheck+0xdd8>
4000150b:	c7 85 70 fe ff ff 00 	movl   $0x1000,-0x190(%ebp)
40001512:	10 00 00 
40001515:	66 c7 85 6e fe ff ff 	movw   $0x0,-0x192(%ebp)
4000151c:	00 00 
4000151e:	c7 85 68 fe ff ff 00 	movl   $0x40000100,-0x198(%ebp)
40001525:	01 00 40 
40001528:	c7 85 64 fe ff ff 00 	movl   $0x0,-0x19c(%ebp)
4000152f:	00 00 00 
40001532:	c7 85 60 fe ff ff 00 	movl   $0x0,-0x1a0(%ebp)
40001539:	00 00 00 
4000153c:	c7 85 5c fe ff ff 00 	movl   $0x0,-0x1a4(%ebp)
40001543:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001546:	8b 85 70 fe ff ff    	mov    -0x190(%ebp),%eax
4000154c:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000154f:	8b 9d 68 fe ff ff    	mov    -0x198(%ebp),%ebx
40001555:	0f b7 95 6e fe ff ff 	movzwl -0x192(%ebp),%edx
4000155c:	8b b5 64 fe ff ff    	mov    -0x19c(%ebp),%esi
40001562:	8b bd 60 fe ff ff    	mov    -0x1a0(%ebp),%edi
40001568:	8b 8d 5c fe ff ff    	mov    -0x1a4(%ebp),%ecx
4000156e:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001570:	b8 03 00 00 00       	mov    $0x3,%eax
40001575:	cd 30                	int    $0x30
40001577:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000157e:	00 
4000157f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001586:	00 
40001587:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000158e:	e8 84 ec ff ff       	call   40000217 <join>
	getfaulttest((int)etext-4);
40001593:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000159a:	00 
4000159b:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400015a2:	e8 9d eb ff ff       	call   40000144 <fork>
400015a7:	85 c0                	test   %eax,%eax
400015a9:	75 70                	jne    4000161b <protcheck+0xe7c>
400015ab:	b8 af 54 00 40       	mov    $0x400054af,%eax
400015b0:	83 e8 04             	sub    $0x4,%eax
400015b3:	c7 85 58 fe ff ff 00 	movl   $0x1000,-0x1a8(%ebp)
400015ba:	10 00 00 
400015bd:	66 c7 85 56 fe ff ff 	movw   $0x0,-0x1aa(%ebp)
400015c4:	00 00 
400015c6:	89 85 50 fe ff ff    	mov    %eax,-0x1b0(%ebp)
400015cc:	c7 85 4c fe ff ff 00 	movl   $0x0,-0x1b4(%ebp)
400015d3:	00 00 00 
400015d6:	c7 85 48 fe ff ff 00 	movl   $0x0,-0x1b8(%ebp)
400015dd:	00 00 00 
400015e0:	c7 85 44 fe ff ff 00 	movl   $0x0,-0x1bc(%ebp)
400015e7:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400015ea:	8b 85 58 fe ff ff    	mov    -0x1a8(%ebp),%eax
400015f0:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400015f3:	8b 9d 50 fe ff ff    	mov    -0x1b0(%ebp),%ebx
400015f9:	0f b7 95 56 fe ff ff 	movzwl -0x1aa(%ebp),%edx
40001600:	8b b5 4c fe ff ff    	mov    -0x1b4(%ebp),%esi
40001606:	8b bd 48 fe ff ff    	mov    -0x1b8(%ebp),%edi
4000160c:	8b 8d 44 fe ff ff    	mov    -0x1bc(%ebp),%ecx
40001612:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001614:	b8 03 00 00 00       	mov    $0x3,%eax
40001619:	cd 30                	int    $0x30
4000161b:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001622:	00 
40001623:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000162a:	00 
4000162b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001632:	e8 e0 eb ff ff       	call   40000217 <join>

	cprintf("testvm: protcheck passed\n");
40001637:	c7 04 24 49 56 00 40 	movl   $0x40005649,(%esp)
4000163e:	e8 91 17 00 00       	call   40002dd4 <cprintf>
}
40001643:	81 c4 cc 01 00 00    	add    $0x1cc,%esp
40001649:	5b                   	pop    %ebx
4000164a:	5e                   	pop    %esi
4000164b:	5f                   	pop    %edi
4000164c:	5d                   	pop    %ebp
4000164d:	c3                   	ret    

4000164e <memopcheck>:

// Test explicit memory management operations
void
memopcheck(void)
{
4000164e:	55                   	push   %ebp
4000164f:	89 e5                	mov    %esp,%ebp
40001651:	57                   	push   %edi
40001652:	56                   	push   %esi
40001653:	53                   	push   %ebx
40001654:	81 ec 5c 02 00 00    	sub    $0x25c,%esp
	// Test page permission changes
	void *va = (void*)VM_USERLO+PTSIZE+PAGESIZE;
4000165a:	c7 45 e4 00 10 40 40 	movl   $0x40401000,-0x1c(%ebp)
	readfaulttest(va);
40001661:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001668:	00 
40001669:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001670:	e8 cf ea ff ff       	call   40000144 <fork>
40001675:	85 c0                	test   %eax,%eax
40001677:	75 0c                	jne    40001685 <memopcheck+0x37>
40001679:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000167c:	8b 00                	mov    (%eax),%eax
4000167e:	b8 03 00 00 00       	mov    $0x3,%eax
40001683:	cd 30                	int    $0x30
40001685:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000168c:	00 
4000168d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001694:	00 
40001695:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000169c:	e8 76 eb ff ff       	call   40000217 <join>
400016a1:	c7 45 bc 00 03 00 00 	movl   $0x300,-0x44(%ebp)
400016a8:	66 c7 45 ba 00 00    	movw   $0x0,-0x46(%ebp)
400016ae:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)
400016b5:	c7 45 b0 00 00 00 00 	movl   $0x0,-0x50(%ebp)
400016bc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400016bf:	89 45 ac             	mov    %eax,-0x54(%ebp)
400016c2:	c7 45 a8 00 10 00 00 	movl   $0x1000,-0x58(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400016c9:	8b 45 bc             	mov    -0x44(%ebp),%eax
400016cc:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400016cf:	8b 5d b4             	mov    -0x4c(%ebp),%ebx
400016d2:	0f b7 55 ba          	movzwl -0x46(%ebp),%edx
400016d6:	8b 75 b0             	mov    -0x50(%ebp),%esi
400016d9:	8b 7d ac             	mov    -0x54(%ebp),%edi
400016dc:	8b 4d a8             	mov    -0x58(%ebp),%ecx
400016df:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, va, PAGESIZE);
	assert(*(volatile int*)va == 0);	// should be readable now
400016e1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400016e4:	8b 00                	mov    (%eax),%eax
400016e6:	85 c0                	test   %eax,%eax
400016e8:	74 24                	je     4000170e <memopcheck+0xc0>
400016ea:	c7 44 24 0c 63 56 00 	movl   $0x40005663,0xc(%esp)
400016f1:	40 
400016f2:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
400016f9:	40 
400016fa:	c7 44 24 04 06 01 00 	movl   $0x106,0x4(%esp)
40001701:	00 
40001702:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40001709:	e8 32 14 00 00       	call   40002b40 <debug_panic>
	writefaulttest(va);			// but not writable
4000170e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001715:	00 
40001716:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000171d:	e8 22 ea ff ff       	call   40000144 <fork>
40001722:	85 c0                	test   %eax,%eax
40001724:	75 16                	jne    4000173c <memopcheck+0xee>
40001726:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001729:	89 45 e0             	mov    %eax,-0x20(%ebp)
4000172c:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000172f:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001735:	b8 03 00 00 00       	mov    $0x3,%eax
4000173a:	cd 30                	int    $0x30
4000173c:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001743:	00 
40001744:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000174b:	00 
4000174c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001753:	e8 bf ea ff ff       	call   40000217 <join>
40001758:	c7 45 a4 00 07 00 00 	movl   $0x700,-0x5c(%ebp)
4000175f:	66 c7 45 a2 00 00    	movw   $0x0,-0x5e(%ebp)
40001765:	c7 45 9c 00 00 00 00 	movl   $0x0,-0x64(%ebp)
4000176c:	c7 45 98 00 00 00 00 	movl   $0x0,-0x68(%ebp)
40001773:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001776:	89 45 94             	mov    %eax,-0x6c(%ebp)
40001779:	c7 45 90 00 10 00 00 	movl   $0x1000,-0x70(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001780:	8b 45 a4             	mov    -0x5c(%ebp),%eax
40001783:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001786:	8b 5d 9c             	mov    -0x64(%ebp),%ebx
40001789:	0f b7 55 a2          	movzwl -0x5e(%ebp),%edx
4000178d:	8b 75 98             	mov    -0x68(%ebp),%esi
40001790:	8b 7d 94             	mov    -0x6c(%ebp),%edi
40001793:	8b 4d 90             	mov    -0x70(%ebp),%ecx
40001796:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL, va, PAGESIZE);
	*(volatile int*)va = 0xdeadbeef;	// should be writable now
40001798:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000179b:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
400017a1:	c7 45 8c 00 01 00 00 	movl   $0x100,-0x74(%ebp)
400017a8:	66 c7 45 8a 00 00    	movw   $0x0,-0x76(%ebp)
400017ae:	c7 45 84 00 00 00 00 	movl   $0x0,-0x7c(%ebp)
400017b5:	c7 45 80 00 00 00 00 	movl   $0x0,-0x80(%ebp)
400017bc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400017bf:	89 85 7c ff ff ff    	mov    %eax,-0x84(%ebp)
400017c5:	c7 85 78 ff ff ff 00 	movl   $0x1000,-0x88(%ebp)
400017cc:	10 00 00 
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400017cf:	8b 45 8c             	mov    -0x74(%ebp),%eax
400017d2:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400017d5:	8b 5d 84             	mov    -0x7c(%ebp),%ebx
400017d8:	0f b7 55 8a          	movzwl -0x76(%ebp),%edx
400017dc:	8b 75 80             	mov    -0x80(%ebp),%esi
400017df:	8b bd 7c ff ff ff    	mov    -0x84(%ebp),%edi
400017e5:	8b 8d 78 ff ff ff    	mov    -0x88(%ebp),%ecx
400017eb:	cd 30                	int    $0x30
	sys_get(SYS_PERM, 0, NULL, NULL, va, PAGESIZE);	// revoke all perms
	readfaulttest(va);
400017ed:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400017f4:	00 
400017f5:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400017fc:	e8 43 e9 ff ff       	call   40000144 <fork>
40001801:	85 c0                	test   %eax,%eax
40001803:	75 0c                	jne    40001811 <memopcheck+0x1c3>
40001805:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001808:	8b 00                	mov    (%eax),%eax
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000180a:	b8 03 00 00 00       	mov    $0x3,%eax
4000180f:	cd 30                	int    $0x30
40001811:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001818:	00 
40001819:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001820:	00 
40001821:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001828:	e8 ea e9 ff ff       	call   40000217 <join>
4000182d:	c7 85 74 ff ff ff 00 	movl   $0x300,-0x8c(%ebp)
40001834:	03 00 00 
40001837:	66 c7 85 72 ff ff ff 	movw   $0x0,-0x8e(%ebp)
4000183e:	00 00 
40001840:	c7 85 6c ff ff ff 00 	movl   $0x0,-0x94(%ebp)
40001847:	00 00 00 
4000184a:	c7 85 68 ff ff ff 00 	movl   $0x0,-0x98(%ebp)
40001851:	00 00 00 
40001854:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001857:	89 85 64 ff ff ff    	mov    %eax,-0x9c(%ebp)
4000185d:	c7 85 60 ff ff ff 00 	movl   $0x1000,-0xa0(%ebp)
40001864:	10 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001867:	8b 85 74 ff ff ff    	mov    -0x8c(%ebp),%eax
4000186d:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001870:	8b 9d 6c ff ff ff    	mov    -0x94(%ebp),%ebx
40001876:	0f b7 95 72 ff ff ff 	movzwl -0x8e(%ebp),%edx
4000187d:	8b b5 68 ff ff ff    	mov    -0x98(%ebp),%esi
40001883:	8b bd 64 ff ff ff    	mov    -0x9c(%ebp),%edi
40001889:	8b 8d 60 ff ff ff    	mov    -0xa0(%ebp),%ecx
4000188f:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, va, PAGESIZE);
	assert(*(volatile int*)va == 0xdeadbeef);	// readable again
40001891:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001894:	8b 00                	mov    (%eax),%eax
40001896:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
4000189b:	74 24                	je     400018c1 <memopcheck+0x273>
4000189d:	c7 44 24 0c 7c 56 00 	movl   $0x4000567c,0xc(%esp)
400018a4:	40 
400018a5:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
400018ac:	40 
400018ad:	c7 44 24 04 0d 01 00 	movl   $0x10d,0x4(%esp)
400018b4:	00 
400018b5:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
400018bc:	e8 7f 12 00 00       	call   40002b40 <debug_panic>
	writefaulttest(va);				// but not writable
400018c1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400018c8:	00 
400018c9:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400018d0:	e8 6f e8 ff ff       	call   40000144 <fork>
400018d5:	85 c0                	test   %eax,%eax
400018d7:	75 16                	jne    400018ef <memopcheck+0x2a1>
400018d9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400018dc:	89 45 dc             	mov    %eax,-0x24(%ebp)
400018df:	8b 45 dc             	mov    -0x24(%ebp),%eax
400018e2:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400018e8:	b8 03 00 00 00       	mov    $0x3,%eax
400018ed:	cd 30                	int    $0x30
400018ef:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400018f6:	00 
400018f7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400018fe:	00 
400018ff:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001906:	e8 0c e9 ff ff       	call   40000217 <join>
4000190b:	c7 85 5c ff ff ff 00 	movl   $0x700,-0xa4(%ebp)
40001912:	07 00 00 
40001915:	66 c7 85 5a ff ff ff 	movw   $0x0,-0xa6(%ebp)
4000191c:	00 00 
4000191e:	c7 85 54 ff ff ff 00 	movl   $0x0,-0xac(%ebp)
40001925:	00 00 00 
40001928:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
4000192f:	00 00 00 
40001932:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001935:	89 85 4c ff ff ff    	mov    %eax,-0xb4(%ebp)
4000193b:	c7 85 48 ff ff ff 00 	movl   $0x1000,-0xb8(%ebp)
40001942:	10 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001945:	8b 85 5c ff ff ff    	mov    -0xa4(%ebp),%eax
4000194b:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000194e:	8b 9d 54 ff ff ff    	mov    -0xac(%ebp),%ebx
40001954:	0f b7 95 5a ff ff ff 	movzwl -0xa6(%ebp),%edx
4000195b:	8b b5 50 ff ff ff    	mov    -0xb0(%ebp),%esi
40001961:	8b bd 4c ff ff ff    	mov    -0xb4(%ebp),%edi
40001967:	8b 8d 48 ff ff ff    	mov    -0xb8(%ebp),%ecx
4000196d:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL, va, PAGESIZE);

	// Test SYS_ZERO with SYS_GET
	va = (void*)VM_USERLO+PTSIZE;	// 4MB-aligned
4000196f:	c7 45 e4 00 00 40 40 	movl   $0x40400000,-0x1c(%ebp)
40001976:	c7 85 44 ff ff ff 00 	movl   $0x10000,-0xbc(%ebp)
4000197d:	00 01 00 
40001980:	66 c7 85 42 ff ff ff 	movw   $0x0,-0xbe(%ebp)
40001987:	00 00 
40001989:	c7 85 3c ff ff ff 00 	movl   $0x0,-0xc4(%ebp)
40001990:	00 00 00 
40001993:	c7 85 38 ff ff ff 00 	movl   $0x0,-0xc8(%ebp)
4000199a:	00 00 00 
4000199d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400019a0:	89 85 34 ff ff ff    	mov    %eax,-0xcc(%ebp)
400019a6:	c7 85 30 ff ff ff 00 	movl   $0x400000,-0xd0(%ebp)
400019ad:	00 40 00 
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400019b0:	8b 85 44 ff ff ff    	mov    -0xbc(%ebp),%eax
400019b6:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400019b9:	8b 9d 3c ff ff ff    	mov    -0xc4(%ebp),%ebx
400019bf:	0f b7 95 42 ff ff ff 	movzwl -0xbe(%ebp),%edx
400019c6:	8b b5 38 ff ff ff    	mov    -0xc8(%ebp),%esi
400019cc:	8b bd 34 ff ff ff    	mov    -0xcc(%ebp),%edi
400019d2:	8b 8d 30 ff ff ff    	mov    -0xd0(%ebp),%ecx
400019d8:	cd 30                	int    $0x30
	sys_get(SYS_ZERO, 0, NULL, NULL, va, PTSIZE);
	readfaulttest(va);		// should be inaccessible again
400019da:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400019e1:	00 
400019e2:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400019e9:	e8 56 e7 ff ff       	call   40000144 <fork>
400019ee:	85 c0                	test   %eax,%eax
400019f0:	75 0c                	jne    400019fe <memopcheck+0x3b0>
400019f2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400019f5:	8b 00                	mov    (%eax),%eax
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400019f7:	b8 03 00 00 00       	mov    $0x3,%eax
400019fc:	cd 30                	int    $0x30
400019fe:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001a05:	00 
40001a06:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001a0d:	00 
40001a0e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001a15:	e8 fd e7 ff ff       	call   40000217 <join>
40001a1a:	c7 85 2c ff ff ff 00 	movl   $0x300,-0xd4(%ebp)
40001a21:	03 00 00 
40001a24:	66 c7 85 2a ff ff ff 	movw   $0x0,-0xd6(%ebp)
40001a2b:	00 00 
40001a2d:	c7 85 24 ff ff ff 00 	movl   $0x0,-0xdc(%ebp)
40001a34:	00 00 00 
40001a37:	c7 85 20 ff ff ff 00 	movl   $0x0,-0xe0(%ebp)
40001a3e:	00 00 00 
40001a41:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001a44:	89 85 1c ff ff ff    	mov    %eax,-0xe4(%ebp)
40001a4a:	c7 85 18 ff ff ff 00 	movl   $0x1000,-0xe8(%ebp)
40001a51:	10 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001a54:	8b 85 2c ff ff ff    	mov    -0xd4(%ebp),%eax
40001a5a:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001a5d:	8b 9d 24 ff ff ff    	mov    -0xdc(%ebp),%ebx
40001a63:	0f b7 95 2a ff ff ff 	movzwl -0xd6(%ebp),%edx
40001a6a:	8b b5 20 ff ff ff    	mov    -0xe0(%ebp),%esi
40001a70:	8b bd 1c ff ff ff    	mov    -0xe4(%ebp),%edi
40001a76:	8b 8d 18 ff ff ff    	mov    -0xe8(%ebp),%ecx
40001a7c:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, va, PAGESIZE);
	assert(*(volatile int*)va == 0);	// and zeroed
40001a7e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001a81:	8b 00                	mov    (%eax),%eax
40001a83:	85 c0                	test   %eax,%eax
40001a85:	74 24                	je     40001aab <memopcheck+0x45d>
40001a87:	c7 44 24 0c 63 56 00 	movl   $0x40005663,0xc(%esp)
40001a8e:	40 
40001a8f:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
40001a96:	40 
40001a97:	c7 44 24 04 16 01 00 	movl   $0x116,0x4(%esp)
40001a9e:	00 
40001a9f:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40001aa6:	e8 95 10 00 00       	call   40002b40 <debug_panic>
	writefaulttest(va);			// but not writable
40001aab:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001ab2:	00 
40001ab3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001aba:	e8 85 e6 ff ff       	call   40000144 <fork>
40001abf:	85 c0                	test   %eax,%eax
40001ac1:	75 16                	jne    40001ad9 <memopcheck+0x48b>
40001ac3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001ac6:	89 45 d8             	mov    %eax,-0x28(%ebp)
40001ac9:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001acc:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001ad2:	b8 03 00 00 00       	mov    $0x3,%eax
40001ad7:	cd 30                	int    $0x30
40001ad9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001ae0:	00 
40001ae1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001ae8:	00 
40001ae9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001af0:	e8 22 e7 ff ff       	call   40000217 <join>
40001af5:	c7 85 14 ff ff ff 00 	movl   $0x10000,-0xec(%ebp)
40001afc:	00 01 00 
40001aff:	66 c7 85 12 ff ff ff 	movw   $0x0,-0xee(%ebp)
40001b06:	00 00 
40001b08:	c7 85 0c ff ff ff 00 	movl   $0x0,-0xf4(%ebp)
40001b0f:	00 00 00 
40001b12:	c7 85 08 ff ff ff 00 	movl   $0x0,-0xf8(%ebp)
40001b19:	00 00 00 
40001b1c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001b1f:	89 85 04 ff ff ff    	mov    %eax,-0xfc(%ebp)
40001b25:	c7 85 00 ff ff ff 00 	movl   $0x400000,-0x100(%ebp)
40001b2c:	00 40 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001b2f:	8b 85 14 ff ff ff    	mov    -0xec(%ebp),%eax
40001b35:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001b38:	8b 9d 0c ff ff ff    	mov    -0xf4(%ebp),%ebx
40001b3e:	0f b7 95 12 ff ff ff 	movzwl -0xee(%ebp),%edx
40001b45:	8b b5 08 ff ff ff    	mov    -0xf8(%ebp),%esi
40001b4b:	8b bd 04 ff ff ff    	mov    -0xfc(%ebp),%edi
40001b51:	8b 8d 00 ff ff ff    	mov    -0x100(%ebp),%ecx
40001b57:	cd 30                	int    $0x30
	sys_get(SYS_ZERO, 0, NULL, NULL, va, PTSIZE);
	readfaulttest(va);			// gone again
40001b59:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001b60:	00 
40001b61:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001b68:	e8 d7 e5 ff ff       	call   40000144 <fork>
40001b6d:	85 c0                	test   %eax,%eax
40001b6f:	75 0c                	jne    40001b7d <memopcheck+0x52f>
40001b71:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001b74:	8b 00                	mov    (%eax),%eax
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001b76:	b8 03 00 00 00       	mov    $0x3,%eax
40001b7b:	cd 30                	int    $0x30
40001b7d:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001b84:	00 
40001b85:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001b8c:	00 
40001b8d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001b94:	e8 7e e6 ff ff       	call   40000217 <join>
40001b99:	c7 85 fc fe ff ff 00 	movl   $0x700,-0x104(%ebp)
40001ba0:	07 00 00 
40001ba3:	66 c7 85 fa fe ff ff 	movw   $0x0,-0x106(%ebp)
40001baa:	00 00 
40001bac:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
40001bb3:	00 00 00 
40001bb6:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
40001bbd:	00 00 00 
40001bc0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001bc3:	89 85 ec fe ff ff    	mov    %eax,-0x114(%ebp)
40001bc9:	c7 85 e8 fe ff ff 00 	movl   $0x1000,-0x118(%ebp)
40001bd0:	10 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001bd3:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
40001bd9:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001bdc:	8b 9d f4 fe ff ff    	mov    -0x10c(%ebp),%ebx
40001be2:	0f b7 95 fa fe ff ff 	movzwl -0x106(%ebp),%edx
40001be9:	8b b5 f0 fe ff ff    	mov    -0x110(%ebp),%esi
40001bef:	8b bd ec fe ff ff    	mov    -0x114(%ebp),%edi
40001bf5:	8b 8d e8 fe ff ff    	mov    -0x118(%ebp),%ecx
40001bfb:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL, va, PAGESIZE);
	*(volatile int*)va = 0xdeadbeef;	// writable now
40001bfd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001c00:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
40001c06:	c7 85 e4 fe ff ff 00 	movl   $0x10000,-0x11c(%ebp)
40001c0d:	00 01 00 
40001c10:	66 c7 85 e2 fe ff ff 	movw   $0x0,-0x11e(%ebp)
40001c17:	00 00 
40001c19:	c7 85 dc fe ff ff 00 	movl   $0x0,-0x124(%ebp)
40001c20:	00 00 00 
40001c23:	c7 85 d8 fe ff ff 00 	movl   $0x0,-0x128(%ebp)
40001c2a:	00 00 00 
40001c2d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001c30:	89 85 d4 fe ff ff    	mov    %eax,-0x12c(%ebp)
40001c36:	c7 85 d0 fe ff ff 00 	movl   $0x400000,-0x130(%ebp)
40001c3d:	00 40 00 
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001c40:	8b 85 e4 fe ff ff    	mov    -0x11c(%ebp),%eax
40001c46:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001c49:	8b 9d dc fe ff ff    	mov    -0x124(%ebp),%ebx
40001c4f:	0f b7 95 e2 fe ff ff 	movzwl -0x11e(%ebp),%edx
40001c56:	8b b5 d8 fe ff ff    	mov    -0x128(%ebp),%esi
40001c5c:	8b bd d4 fe ff ff    	mov    -0x12c(%ebp),%edi
40001c62:	8b 8d d0 fe ff ff    	mov    -0x130(%ebp),%ecx
40001c68:	cd 30                	int    $0x30
	sys_get(SYS_ZERO, 0, NULL, NULL, va, PTSIZE);
	readfaulttest(va);			// gone again
40001c6a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001c71:	00 
40001c72:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001c79:	e8 c6 e4 ff ff       	call   40000144 <fork>
40001c7e:	85 c0                	test   %eax,%eax
40001c80:	75 0c                	jne    40001c8e <memopcheck+0x640>
40001c82:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001c85:	8b 00                	mov    (%eax),%eax
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001c87:	b8 03 00 00 00       	mov    $0x3,%eax
40001c8c:	cd 30                	int    $0x30
40001c8e:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001c95:	00 
40001c96:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001c9d:	00 
40001c9e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001ca5:	e8 6d e5 ff ff       	call   40000217 <join>
40001caa:	c7 85 cc fe ff ff 00 	movl   $0x300,-0x134(%ebp)
40001cb1:	03 00 00 
40001cb4:	66 c7 85 ca fe ff ff 	movw   $0x0,-0x136(%ebp)
40001cbb:	00 00 
40001cbd:	c7 85 c4 fe ff ff 00 	movl   $0x0,-0x13c(%ebp)
40001cc4:	00 00 00 
40001cc7:	c7 85 c0 fe ff ff 00 	movl   $0x0,-0x140(%ebp)
40001cce:	00 00 00 
40001cd1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001cd4:	89 85 bc fe ff ff    	mov    %eax,-0x144(%ebp)
40001cda:	c7 85 b8 fe ff ff 00 	movl   $0x1000,-0x148(%ebp)
40001ce1:	10 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001ce4:	8b 85 cc fe ff ff    	mov    -0x134(%ebp),%eax
40001cea:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001ced:	8b 9d c4 fe ff ff    	mov    -0x13c(%ebp),%ebx
40001cf3:	0f b7 95 ca fe ff ff 	movzwl -0x136(%ebp),%edx
40001cfa:	8b b5 c0 fe ff ff    	mov    -0x140(%ebp),%esi
40001d00:	8b bd bc fe ff ff    	mov    -0x144(%ebp),%edi
40001d06:	8b 8d b8 fe ff ff    	mov    -0x148(%ebp),%ecx
40001d0c:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, va, PAGESIZE);
	assert(*(volatile int*)va == 0);	// and zeroed
40001d0e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001d11:	8b 00                	mov    (%eax),%eax
40001d13:	85 c0                	test   %eax,%eax
40001d15:	74 24                	je     40001d3b <memopcheck+0x6ed>
40001d17:	c7 44 24 0c 63 56 00 	movl   $0x40005663,0xc(%esp)
40001d1e:	40 
40001d1f:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
40001d26:	40 
40001d27:	c7 44 24 04 1f 01 00 	movl   $0x11f,0x4(%esp)
40001d2e:	00 
40001d2f:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40001d36:	e8 05 0e 00 00       	call   40002b40 <debug_panic>

	// Test SYS_COPY with SYS_GET - pull residual stuff out of child 0
	void *sva = (void*)VM_USERLO;
40001d3b:	c7 45 d4 00 00 00 40 	movl   $0x40000000,-0x2c(%ebp)
	void *dva = (void*)VM_USERLO+PTSIZE;
40001d42:	c7 45 d0 00 00 40 40 	movl   $0x40400000,-0x30(%ebp)
40001d49:	c7 85 b4 fe ff ff 00 	movl   $0x20000,-0x14c(%ebp)
40001d50:	00 02 00 
40001d53:	66 c7 85 b2 fe ff ff 	movw   $0x0,-0x14e(%ebp)
40001d5a:	00 00 
40001d5c:	c7 85 ac fe ff ff 00 	movl   $0x0,-0x154(%ebp)
40001d63:	00 00 00 
40001d66:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40001d69:	89 85 a8 fe ff ff    	mov    %eax,-0x158(%ebp)
40001d6f:	8b 45 d0             	mov    -0x30(%ebp),%eax
40001d72:	89 85 a4 fe ff ff    	mov    %eax,-0x15c(%ebp)
40001d78:	c7 85 a0 fe ff ff 00 	movl   $0x400000,-0x160(%ebp)
40001d7f:	00 40 00 
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001d82:	8b 85 b4 fe ff ff    	mov    -0x14c(%ebp),%eax
40001d88:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001d8b:	8b 9d ac fe ff ff    	mov    -0x154(%ebp),%ebx
40001d91:	0f b7 95 b2 fe ff ff 	movzwl -0x14e(%ebp),%edx
40001d98:	8b b5 a8 fe ff ff    	mov    -0x158(%ebp),%esi
40001d9e:	8b bd a4 fe ff ff    	mov    -0x15c(%ebp),%edi
40001da4:	8b 8d a0 fe ff ff    	mov    -0x160(%ebp),%ecx
40001daa:	cd 30                	int    $0x30
	sys_get(SYS_COPY, 0, NULL, sva, dva, PTSIZE);
	assert(memcmp(sva, dva, etext - start) == 0);
40001dac:	ba af 54 00 40       	mov    $0x400054af,%edx
40001db1:	b8 00 01 00 40       	mov    $0x40000100,%eax
40001db6:	89 d1                	mov    %edx,%ecx
40001db8:	29 c1                	sub    %eax,%ecx
40001dba:	89 c8                	mov    %ecx,%eax
40001dbc:	89 44 24 08          	mov    %eax,0x8(%esp)
40001dc0:	8b 45 d0             	mov    -0x30(%ebp),%eax
40001dc3:	89 44 24 04          	mov    %eax,0x4(%esp)
40001dc7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40001dca:	89 04 24             	mov    %eax,(%esp)
40001dcd:	e8 08 1a 00 00       	call   400037da <memcmp>
40001dd2:	85 c0                	test   %eax,%eax
40001dd4:	74 24                	je     40001dfa <memopcheck+0x7ac>
40001dd6:	c7 44 24 0c a0 56 00 	movl   $0x400056a0,0xc(%esp)
40001ddd:	40 
40001dde:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
40001de5:	40 
40001de6:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
40001ded:	00 
40001dee:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40001df5:	e8 46 0d 00 00       	call   40002b40 <debug_panic>
	writefaulttest(dva);
40001dfa:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001e01:	00 
40001e02:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001e09:	e8 36 e3 ff ff       	call   40000144 <fork>
40001e0e:	85 c0                	test   %eax,%eax
40001e10:	75 16                	jne    40001e28 <memopcheck+0x7da>
40001e12:	8b 45 d0             	mov    -0x30(%ebp),%eax
40001e15:	89 45 cc             	mov    %eax,-0x34(%ebp)
40001e18:	8b 45 cc             	mov    -0x34(%ebp),%eax
40001e1b:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001e21:	b8 03 00 00 00       	mov    $0x3,%eax
40001e26:	cd 30                	int    $0x30
40001e28:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001e2f:	00 
40001e30:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001e37:	00 
40001e38:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001e3f:	e8 d3 e3 ff ff       	call   40000217 <join>
	readfaulttest(dva + PTSIZE-4);
40001e44:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001e4b:	00 
40001e4c:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001e53:	e8 ec e2 ff ff       	call   40000144 <fork>
40001e58:	85 c0                	test   %eax,%eax
40001e5a:	75 11                	jne    40001e6d <memopcheck+0x81f>
40001e5c:	8b 45 d0             	mov    -0x30(%ebp),%eax
40001e5f:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
40001e64:	8b 00                	mov    (%eax),%eax
40001e66:	b8 03 00 00 00       	mov    $0x3,%eax
40001e6b:	cd 30                	int    $0x30
40001e6d:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001e74:	00 
40001e75:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001e7c:	00 
40001e7d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001e84:	e8 8e e3 ff ff       	call   40000217 <join>

	// Test SYS_ZERO with SYS_PUT
	void *dva2 = (void*)VM_USERLO+PTSIZE*2;
40001e89:	c7 45 c8 00 00 80 40 	movl   $0x40800000,-0x38(%ebp)
40001e90:	c7 85 9c fe ff ff 00 	movl   $0x10000,-0x164(%ebp)
40001e97:	00 01 00 
40001e9a:	66 c7 85 9a fe ff ff 	movw   $0x0,-0x166(%ebp)
40001ea1:	00 00 
40001ea3:	c7 85 94 fe ff ff 00 	movl   $0x0,-0x16c(%ebp)
40001eaa:	00 00 00 
40001ead:	c7 85 90 fe ff ff 00 	movl   $0x0,-0x170(%ebp)
40001eb4:	00 00 00 
40001eb7:	8b 45 d0             	mov    -0x30(%ebp),%eax
40001eba:	89 85 8c fe ff ff    	mov    %eax,-0x174(%ebp)
40001ec0:	c7 85 88 fe ff ff 00 	movl   $0x400000,-0x178(%ebp)
40001ec7:	00 40 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40001eca:	8b 85 9c fe ff ff    	mov    -0x164(%ebp),%eax
40001ed0:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40001ed3:	8b 9d 94 fe ff ff    	mov    -0x16c(%ebp),%ebx
40001ed9:	0f b7 95 9a fe ff ff 	movzwl -0x166(%ebp),%edx
40001ee0:	8b b5 90 fe ff ff    	mov    -0x170(%ebp),%esi
40001ee6:	8b bd 8c fe ff ff    	mov    -0x174(%ebp),%edi
40001eec:	8b 8d 88 fe ff ff    	mov    -0x178(%ebp),%ecx
40001ef2:	cd 30                	int    $0x30
40001ef4:	c7 85 84 fe ff ff 00 	movl   $0x20000,-0x17c(%ebp)
40001efb:	00 02 00 
40001efe:	66 c7 85 82 fe ff ff 	movw   $0x0,-0x17e(%ebp)
40001f05:	00 00 
40001f07:	c7 85 7c fe ff ff 00 	movl   $0x0,-0x184(%ebp)
40001f0e:	00 00 00 
40001f11:	8b 45 d0             	mov    -0x30(%ebp),%eax
40001f14:	89 85 78 fe ff ff    	mov    %eax,-0x188(%ebp)
40001f1a:	8b 45 c8             	mov    -0x38(%ebp),%eax
40001f1d:	89 85 74 fe ff ff    	mov    %eax,-0x18c(%ebp)
40001f23:	c7 85 70 fe ff ff 00 	movl   $0x400000,-0x190(%ebp)
40001f2a:	00 40 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001f2d:	8b 85 84 fe ff ff    	mov    -0x17c(%ebp),%eax
40001f33:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001f36:	8b 9d 7c fe ff ff    	mov    -0x184(%ebp),%ebx
40001f3c:	0f b7 95 82 fe ff ff 	movzwl -0x17e(%ebp),%edx
40001f43:	8b b5 78 fe ff ff    	mov    -0x188(%ebp),%esi
40001f49:	8b bd 74 fe ff ff    	mov    -0x18c(%ebp),%edi
40001f4f:	8b 8d 70 fe ff ff    	mov    -0x190(%ebp),%ecx
40001f55:	cd 30                	int    $0x30
	sys_put(SYS_ZERO, 0, NULL, NULL, dva, PTSIZE);
	sys_get(SYS_COPY, 0, NULL, dva, dva2, PTSIZE);
	readfaulttest(dva2);
40001f57:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001f5e:	00 
40001f5f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001f66:	e8 d9 e1 ff ff       	call   40000144 <fork>
40001f6b:	85 c0                	test   %eax,%eax
40001f6d:	75 0c                	jne    40001f7b <memopcheck+0x92d>
40001f6f:	8b 45 c8             	mov    -0x38(%ebp),%eax
40001f72:	8b 00                	mov    (%eax),%eax
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001f74:	b8 03 00 00 00       	mov    $0x3,%eax
40001f79:	cd 30                	int    $0x30
40001f7b:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001f82:	00 
40001f83:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001f8a:	00 
40001f8b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001f92:	e8 80 e2 ff ff       	call   40000217 <join>
	readfaulttest(dva2 + PTSIZE-4);
40001f97:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001f9e:	00 
40001f9f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001fa6:	e8 99 e1 ff ff       	call   40000144 <fork>
40001fab:	85 c0                	test   %eax,%eax
40001fad:	75 11                	jne    40001fc0 <memopcheck+0x972>
40001faf:	8b 45 c8             	mov    -0x38(%ebp),%eax
40001fb2:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
40001fb7:	8b 00                	mov    (%eax),%eax
40001fb9:	b8 03 00 00 00       	mov    $0x3,%eax
40001fbe:	cd 30                	int    $0x30
40001fc0:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001fc7:	00 
40001fc8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001fcf:	00 
40001fd0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001fd7:	e8 3b e2 ff ff       	call   40000217 <join>
40001fdc:	c7 85 6c fe ff ff 00 	movl   $0x300,-0x194(%ebp)
40001fe3:	03 00 00 
40001fe6:	66 c7 85 6a fe ff ff 	movw   $0x0,-0x196(%ebp)
40001fed:	00 00 
40001fef:	c7 85 64 fe ff ff 00 	movl   $0x0,-0x19c(%ebp)
40001ff6:	00 00 00 
40001ff9:	c7 85 60 fe ff ff 00 	movl   $0x0,-0x1a0(%ebp)
40002000:	00 00 00 
40002003:	8b 45 c8             	mov    -0x38(%ebp),%eax
40002006:	89 85 5c fe ff ff    	mov    %eax,-0x1a4(%ebp)
4000200c:	c7 85 58 fe ff ff 00 	movl   $0x400000,-0x1a8(%ebp)
40002013:	00 40 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40002016:	8b 85 6c fe ff ff    	mov    -0x194(%ebp),%eax
4000201c:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000201f:	8b 9d 64 fe ff ff    	mov    -0x19c(%ebp),%ebx
40002025:	0f b7 95 6a fe ff ff 	movzwl -0x196(%ebp),%edx
4000202c:	8b b5 60 fe ff ff    	mov    -0x1a0(%ebp),%esi
40002032:	8b bd 5c fe ff ff    	mov    -0x1a4(%ebp),%edi
40002038:	8b 8d 58 fe ff ff    	mov    -0x1a8(%ebp),%ecx
4000203e:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, dva2, PTSIZE);
	assert(*(volatile int*)dva2 == 0);
40002040:	8b 45 c8             	mov    -0x38(%ebp),%eax
40002043:	8b 00                	mov    (%eax),%eax
40002045:	85 c0                	test   %eax,%eax
40002047:	74 24                	je     4000206d <memopcheck+0xa1f>
40002049:	c7 44 24 0c c5 56 00 	movl   $0x400056c5,0xc(%esp)
40002050:	40 
40002051:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
40002058:	40 
40002059:	c7 44 24 04 30 01 00 	movl   $0x130,0x4(%esp)
40002060:	00 
40002061:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40002068:	e8 d3 0a 00 00       	call   40002b40 <debug_panic>
	assert(*(volatile int*)(dva2+PTSIZE-4) == 0);
4000206d:	8b 45 c8             	mov    -0x38(%ebp),%eax
40002070:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
40002075:	8b 00                	mov    (%eax),%eax
40002077:	85 c0                	test   %eax,%eax
40002079:	74 24                	je     4000209f <memopcheck+0xa51>
4000207b:	c7 44 24 0c e0 56 00 	movl   $0x400056e0,0xc(%esp)
40002082:	40 
40002083:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
4000208a:	40 
4000208b:	c7 44 24 04 31 01 00 	movl   $0x131,0x4(%esp)
40002092:	00 
40002093:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
4000209a:	e8 a1 0a 00 00       	call   40002b40 <debug_panic>
4000209f:	c7 85 54 fe ff ff 00 	movl   $0x20000,-0x1ac(%ebp)
400020a6:	00 02 00 
400020a9:	66 c7 85 52 fe ff ff 	movw   $0x0,-0x1ae(%ebp)
400020b0:	00 00 
400020b2:	c7 85 4c fe ff ff 00 	movl   $0x0,-0x1b4(%ebp)
400020b9:	00 00 00 
400020bc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
400020bf:	89 85 48 fe ff ff    	mov    %eax,-0x1b8(%ebp)
400020c5:	8b 45 d0             	mov    -0x30(%ebp),%eax
400020c8:	89 85 44 fe ff ff    	mov    %eax,-0x1bc(%ebp)
400020ce:	c7 85 40 fe ff ff 00 	movl   $0x400000,-0x1c0(%ebp)
400020d5:	00 40 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
400020d8:	8b 85 54 fe ff ff    	mov    -0x1ac(%ebp),%eax
400020de:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400020e1:	8b 9d 4c fe ff ff    	mov    -0x1b4(%ebp),%ebx
400020e7:	0f b7 95 52 fe ff ff 	movzwl -0x1ae(%ebp),%edx
400020ee:	8b b5 48 fe ff ff    	mov    -0x1b8(%ebp),%esi
400020f4:	8b bd 44 fe ff ff    	mov    -0x1bc(%ebp),%edi
400020fa:	8b 8d 40 fe ff ff    	mov    -0x1c0(%ebp),%ecx
40002100:	cd 30                	int    $0x30
40002102:	c7 85 3c fe ff ff 00 	movl   $0x20000,-0x1c4(%ebp)
40002109:	00 02 00 
4000210c:	66 c7 85 3a fe ff ff 	movw   $0x0,-0x1c6(%ebp)
40002113:	00 00 
40002115:	c7 85 34 fe ff ff 00 	movl   $0x0,-0x1cc(%ebp)
4000211c:	00 00 00 
4000211f:	8b 45 d0             	mov    -0x30(%ebp),%eax
40002122:	89 85 30 fe ff ff    	mov    %eax,-0x1d0(%ebp)
40002128:	8b 45 c8             	mov    -0x38(%ebp),%eax
4000212b:	89 85 2c fe ff ff    	mov    %eax,-0x1d4(%ebp)
40002131:	c7 85 28 fe ff ff 00 	movl   $0x400000,-0x1d8(%ebp)
40002138:	00 40 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
4000213b:	8b 85 3c fe ff ff    	mov    -0x1c4(%ebp),%eax
40002141:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40002144:	8b 9d 34 fe ff ff    	mov    -0x1cc(%ebp),%ebx
4000214a:	0f b7 95 3a fe ff ff 	movzwl -0x1c6(%ebp),%edx
40002151:	8b b5 30 fe ff ff    	mov    -0x1d0(%ebp),%esi
40002157:	8b bd 2c fe ff ff    	mov    -0x1d4(%ebp),%edi
4000215d:	8b 8d 28 fe ff ff    	mov    -0x1d8(%ebp),%ecx
40002163:	cd 30                	int    $0x30

	// Test SYS_COPY with SYS_PUT
	sys_put(SYS_COPY, 0, NULL, sva, dva, PTSIZE);
	sys_get(SYS_COPY, 0, NULL, dva, dva2, PTSIZE);
	assert(memcmp(sva, dva2, etext - start) == 0);
40002165:	ba af 54 00 40       	mov    $0x400054af,%edx
4000216a:	b8 00 01 00 40       	mov    $0x40000100,%eax
4000216f:	89 d1                	mov    %edx,%ecx
40002171:	29 c1                	sub    %eax,%ecx
40002173:	89 c8                	mov    %ecx,%eax
40002175:	89 44 24 08          	mov    %eax,0x8(%esp)
40002179:	8b 45 c8             	mov    -0x38(%ebp),%eax
4000217c:	89 44 24 04          	mov    %eax,0x4(%esp)
40002180:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40002183:	89 04 24             	mov    %eax,(%esp)
40002186:	e8 4f 16 00 00       	call   400037da <memcmp>
4000218b:	85 c0                	test   %eax,%eax
4000218d:	74 24                	je     400021b3 <memopcheck+0xb65>
4000218f:	c7 44 24 0c 08 57 00 	movl   $0x40005708,0xc(%esp)
40002196:	40 
40002197:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
4000219e:	40 
4000219f:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
400021a6:	00 
400021a7:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
400021ae:	e8 8d 09 00 00       	call   40002b40 <debug_panic>
	writefaulttest(dva2);
400021b3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400021ba:	00 
400021bb:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400021c2:	e8 7d df ff ff       	call   40000144 <fork>
400021c7:	85 c0                	test   %eax,%eax
400021c9:	75 16                	jne    400021e1 <memopcheck+0xb93>
400021cb:	8b 45 c8             	mov    -0x38(%ebp),%eax
400021ce:	89 45 c4             	mov    %eax,-0x3c(%ebp)
400021d1:	8b 45 c4             	mov    -0x3c(%ebp),%eax
400021d4:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400021da:	b8 03 00 00 00       	mov    $0x3,%eax
400021df:	cd 30                	int    $0x30
400021e1:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400021e8:	00 
400021e9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400021f0:	00 
400021f1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400021f8:	e8 1a e0 ff ff       	call   40000217 <join>
	readfaulttest(dva2 + PTSIZE-4);
400021fd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002204:	00 
40002205:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000220c:	e8 33 df ff ff       	call   40000144 <fork>
40002211:	85 c0                	test   %eax,%eax
40002213:	75 11                	jne    40002226 <memopcheck+0xbd8>
40002215:	8b 45 c8             	mov    -0x38(%ebp),%eax
40002218:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
4000221d:	8b 00                	mov    (%eax),%eax
4000221f:	b8 03 00 00 00       	mov    $0x3,%eax
40002224:	cd 30                	int    $0x30
40002226:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000222d:	00 
4000222e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002235:	00 
40002236:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000223d:	e8 d5 df ff ff       	call   40000217 <join>

	// Hide an easter egg and make sure it survives the two copies
	sva = (void*)VM_USERLO; dva = sva+PTSIZE; dva2 = dva+PTSIZE;
40002242:	c7 45 d4 00 00 00 40 	movl   $0x40000000,-0x2c(%ebp)
40002249:	8b 45 d4             	mov    -0x2c(%ebp),%eax
4000224c:	05 00 00 40 00       	add    $0x400000,%eax
40002251:	89 45 d0             	mov    %eax,-0x30(%ebp)
40002254:	8b 45 d0             	mov    -0x30(%ebp),%eax
40002257:	05 00 00 40 00       	add    $0x400000,%eax
4000225c:	89 45 c8             	mov    %eax,-0x38(%ebp)
	uint32_t ofs = PTSIZE-PAGESIZE;
4000225f:	c7 45 c0 00 f0 3f 00 	movl   $0x3ff000,-0x40(%ebp)
	sys_get(SYS_PERM|SYS_READ|SYS_WRITE, 0, NULL, NULL, sva+ofs, PAGESIZE);
40002266:	8b 45 c0             	mov    -0x40(%ebp),%eax
40002269:	8b 55 d4             	mov    -0x2c(%ebp),%edx
4000226c:	01 d0                	add    %edx,%eax
4000226e:	c7 85 24 fe ff ff 00 	movl   $0x700,-0x1dc(%ebp)
40002275:	07 00 00 
40002278:	66 c7 85 22 fe ff ff 	movw   $0x0,-0x1de(%ebp)
4000227f:	00 00 
40002281:	c7 85 1c fe ff ff 00 	movl   $0x0,-0x1e4(%ebp)
40002288:	00 00 00 
4000228b:	c7 85 18 fe ff ff 00 	movl   $0x0,-0x1e8(%ebp)
40002292:	00 00 00 
40002295:	89 85 14 fe ff ff    	mov    %eax,-0x1ec(%ebp)
4000229b:	c7 85 10 fe ff ff 00 	movl   $0x1000,-0x1f0(%ebp)
400022a2:	10 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400022a5:	8b 85 24 fe ff ff    	mov    -0x1dc(%ebp),%eax
400022ab:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400022ae:	8b 9d 1c fe ff ff    	mov    -0x1e4(%ebp),%ebx
400022b4:	0f b7 95 22 fe ff ff 	movzwl -0x1de(%ebp),%edx
400022bb:	8b b5 18 fe ff ff    	mov    -0x1e8(%ebp),%esi
400022c1:	8b bd 14 fe ff ff    	mov    -0x1ec(%ebp),%edi
400022c7:	8b 8d 10 fe ff ff    	mov    -0x1f0(%ebp),%ecx
400022cd:	cd 30                	int    $0x30
	*(volatile int*)(sva+ofs) = 0xdeadbeef;	// should be writable now
400022cf:	8b 45 c0             	mov    -0x40(%ebp),%eax
400022d2:	8b 55 d4             	mov    -0x2c(%ebp),%edx
400022d5:	01 d0                	add    %edx,%eax
400022d7:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
	sys_get(SYS_PERM, 0, NULL, NULL, sva+ofs, PAGESIZE);
400022dd:	8b 45 c0             	mov    -0x40(%ebp),%eax
400022e0:	8b 55 d4             	mov    -0x2c(%ebp),%edx
400022e3:	01 d0                	add    %edx,%eax
400022e5:	c7 85 0c fe ff ff 00 	movl   $0x100,-0x1f4(%ebp)
400022ec:	01 00 00 
400022ef:	66 c7 85 0a fe ff ff 	movw   $0x0,-0x1f6(%ebp)
400022f6:	00 00 
400022f8:	c7 85 04 fe ff ff 00 	movl   $0x0,-0x1fc(%ebp)
400022ff:	00 00 00 
40002302:	c7 85 00 fe ff ff 00 	movl   $0x0,-0x200(%ebp)
40002309:	00 00 00 
4000230c:	89 85 fc fd ff ff    	mov    %eax,-0x204(%ebp)
40002312:	c7 85 f8 fd ff ff 00 	movl   $0x1000,-0x208(%ebp)
40002319:	10 00 00 
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
4000231c:	8b 85 0c fe ff ff    	mov    -0x1f4(%ebp),%eax
40002322:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40002325:	8b 9d 04 fe ff ff    	mov    -0x1fc(%ebp),%ebx
4000232b:	0f b7 95 0a fe ff ff 	movzwl -0x1f6(%ebp),%edx
40002332:	8b b5 00 fe ff ff    	mov    -0x200(%ebp),%esi
40002338:	8b bd fc fd ff ff    	mov    -0x204(%ebp),%edi
4000233e:	8b 8d f8 fd ff ff    	mov    -0x208(%ebp),%ecx
40002344:	cd 30                	int    $0x30
	readfaulttest(sva+ofs);			// hide it
40002346:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000234d:	00 
4000234e:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40002355:	e8 ea dd ff ff       	call   40000144 <fork>
4000235a:	85 c0                	test   %eax,%eax
4000235c:	75 11                	jne    4000236f <memopcheck+0xd21>
4000235e:	8b 45 c0             	mov    -0x40(%ebp),%eax
40002361:	8b 55 d4             	mov    -0x2c(%ebp),%edx
40002364:	01 d0                	add    %edx,%eax
40002366:	8b 00                	mov    (%eax),%eax
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40002368:	b8 03 00 00 00       	mov    $0x3,%eax
4000236d:	cd 30                	int    $0x30
4000236f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40002376:	00 
40002377:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000237e:	00 
4000237f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002386:	e8 8c de ff ff       	call   40000217 <join>
4000238b:	c7 85 f4 fd ff ff 00 	movl   $0x20000,-0x20c(%ebp)
40002392:	00 02 00 
40002395:	66 c7 85 f2 fd ff ff 	movw   $0x0,-0x20e(%ebp)
4000239c:	00 00 
4000239e:	c7 85 ec fd ff ff 00 	movl   $0x0,-0x214(%ebp)
400023a5:	00 00 00 
400023a8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
400023ab:	89 85 e8 fd ff ff    	mov    %eax,-0x218(%ebp)
400023b1:	8b 45 d0             	mov    -0x30(%ebp),%eax
400023b4:	89 85 e4 fd ff ff    	mov    %eax,-0x21c(%ebp)
400023ba:	c7 85 e0 fd ff ff 00 	movl   $0x400000,-0x220(%ebp)
400023c1:	00 40 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
400023c4:	8b 85 f4 fd ff ff    	mov    -0x20c(%ebp),%eax
400023ca:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400023cd:	8b 9d ec fd ff ff    	mov    -0x214(%ebp),%ebx
400023d3:	0f b7 95 f2 fd ff ff 	movzwl -0x20e(%ebp),%edx
400023da:	8b b5 e8 fd ff ff    	mov    -0x218(%ebp),%esi
400023e0:	8b bd e4 fd ff ff    	mov    -0x21c(%ebp),%edi
400023e6:	8b 8d e0 fd ff ff    	mov    -0x220(%ebp),%ecx
400023ec:	cd 30                	int    $0x30
400023ee:	c7 85 dc fd ff ff 00 	movl   $0x20000,-0x224(%ebp)
400023f5:	00 02 00 
400023f8:	66 c7 85 da fd ff ff 	movw   $0x0,-0x226(%ebp)
400023ff:	00 00 
40002401:	c7 85 d4 fd ff ff 00 	movl   $0x0,-0x22c(%ebp)
40002408:	00 00 00 
4000240b:	8b 45 d0             	mov    -0x30(%ebp),%eax
4000240e:	89 85 d0 fd ff ff    	mov    %eax,-0x230(%ebp)
40002414:	8b 45 c8             	mov    -0x38(%ebp),%eax
40002417:	89 85 cc fd ff ff    	mov    %eax,-0x234(%ebp)
4000241d:	c7 85 c8 fd ff ff 00 	movl   $0x400000,-0x238(%ebp)
40002424:	00 40 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40002427:	8b 85 dc fd ff ff    	mov    -0x224(%ebp),%eax
4000242d:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40002430:	8b 9d d4 fd ff ff    	mov    -0x22c(%ebp),%ebx
40002436:	0f b7 95 da fd ff ff 	movzwl -0x226(%ebp),%edx
4000243d:	8b b5 d0 fd ff ff    	mov    -0x230(%ebp),%esi
40002443:	8b bd cc fd ff ff    	mov    -0x234(%ebp),%edi
40002449:	8b 8d c8 fd ff ff    	mov    -0x238(%ebp),%ecx
4000244f:	cd 30                	int    $0x30
	sys_put(SYS_COPY, 0, NULL, sva, dva, PTSIZE);
	sys_get(SYS_COPY, 0, NULL, dva, dva2, PTSIZE);
	readfaulttest(dva2+ofs);		// stayed hidden?
40002451:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002458:	00 
40002459:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40002460:	e8 df dc ff ff       	call   40000144 <fork>
40002465:	85 c0                	test   %eax,%eax
40002467:	75 11                	jne    4000247a <memopcheck+0xe2c>
40002469:	8b 45 c0             	mov    -0x40(%ebp),%eax
4000246c:	8b 55 c8             	mov    -0x38(%ebp),%edx
4000246f:	01 d0                	add    %edx,%eax
40002471:	8b 00                	mov    (%eax),%eax
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40002473:	b8 03 00 00 00       	mov    $0x3,%eax
40002478:	cd 30                	int    $0x30
4000247a:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40002481:	00 
40002482:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002489:	00 
4000248a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002491:	e8 81 dd ff ff       	call   40000217 <join>
	sys_get(SYS_PERM|SYS_READ, 0, NULL, NULL, dva2+ofs, PAGESIZE);
40002496:	8b 45 c0             	mov    -0x40(%ebp),%eax
40002499:	8b 55 c8             	mov    -0x38(%ebp),%edx
4000249c:	01 d0                	add    %edx,%eax
4000249e:	c7 85 c4 fd ff ff 00 	movl   $0x300,-0x23c(%ebp)
400024a5:	03 00 00 
400024a8:	66 c7 85 c2 fd ff ff 	movw   $0x0,-0x23e(%ebp)
400024af:	00 00 
400024b1:	c7 85 bc fd ff ff 00 	movl   $0x0,-0x244(%ebp)
400024b8:	00 00 00 
400024bb:	c7 85 b8 fd ff ff 00 	movl   $0x0,-0x248(%ebp)
400024c2:	00 00 00 
400024c5:	89 85 b4 fd ff ff    	mov    %eax,-0x24c(%ebp)
400024cb:	c7 85 b0 fd ff ff 00 	movl   $0x1000,-0x250(%ebp)
400024d2:	10 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400024d5:	8b 85 c4 fd ff ff    	mov    -0x23c(%ebp),%eax
400024db:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400024de:	8b 9d bc fd ff ff    	mov    -0x244(%ebp),%ebx
400024e4:	0f b7 95 c2 fd ff ff 	movzwl -0x23e(%ebp),%edx
400024eb:	8b b5 b8 fd ff ff    	mov    -0x248(%ebp),%esi
400024f1:	8b bd b4 fd ff ff    	mov    -0x24c(%ebp),%edi
400024f7:	8b 8d b0 fd ff ff    	mov    -0x250(%ebp),%ecx
400024fd:	cd 30                	int    $0x30
	assert(*(volatile int*)(dva2+ofs) == 0xdeadbeef);	// survived?
400024ff:	8b 45 c0             	mov    -0x40(%ebp),%eax
40002502:	8b 55 c8             	mov    -0x38(%ebp),%edx
40002505:	01 d0                	add    %edx,%eax
40002507:	8b 00                	mov    (%eax),%eax
40002509:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
4000250e:	74 24                	je     40002534 <memopcheck+0xee6>
40002510:	c7 44 24 0c 30 57 00 	movl   $0x40005730,0xc(%esp)
40002517:	40 
40002518:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
4000251f:	40 
40002520:	c7 44 24 04 45 01 00 	movl   $0x145,0x4(%esp)
40002527:	00 
40002528:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
4000252f:	e8 0c 06 00 00       	call   40002b40 <debug_panic>

	cprintf("testvm: memopcheck passed\n");
40002534:	c7 04 24 59 57 00 40 	movl   $0x40005759,(%esp)
4000253b:	e8 94 08 00 00       	call   40002dd4 <cprintf>
}
40002540:	81 c4 5c 02 00 00    	add    $0x25c,%esp
40002546:	5b                   	pop    %ebx
40002547:	5e                   	pop    %esi
40002548:	5f                   	pop    %edi
40002549:	5d                   	pop    %ebp
4000254a:	c3                   	ret    

4000254b <pqsort>:

#define swapints(a,b) ({ int t = (a); (a) = (b); (b) = t; })

void
pqsort(int *lo, int *hi)
{
4000254b:	55                   	push   %ebp
4000254c:	89 e5                	mov    %esp,%ebp
4000254e:	83 ec 38             	sub    $0x38,%esp
	if (lo >= hi)
40002551:	8b 45 08             	mov    0x8(%ebp),%eax
40002554:	3b 45 0c             	cmp    0xc(%ebp),%eax
40002557:	0f 83 23 01 00 00    	jae    40002680 <pqsort+0x135>
		return;

	int pivot = *lo;	// yeah, bad way to choose pivot...
4000255d:	8b 45 08             	mov    0x8(%ebp),%eax
40002560:	8b 00                	mov    (%eax),%eax
40002562:	89 45 ec             	mov    %eax,-0x14(%ebp)
	int *l = lo+1, *h = hi;
40002565:	8b 45 08             	mov    0x8(%ebp),%eax
40002568:	83 c0 04             	add    $0x4,%eax
4000256b:	89 45 f4             	mov    %eax,-0xc(%ebp)
4000256e:	8b 45 0c             	mov    0xc(%ebp),%eax
40002571:	89 45 f0             	mov    %eax,-0x10(%ebp)
	while (l <= h) {
40002574:	eb 42                	jmp    400025b8 <pqsort+0x6d>
		if (*l < pivot)
40002576:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002579:	8b 00                	mov    (%eax),%eax
4000257b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
4000257e:	7d 06                	jge    40002586 <pqsort+0x3b>
			l++;
40002580:	83 45 f4 04          	addl   $0x4,-0xc(%ebp)
40002584:	eb 32                	jmp    400025b8 <pqsort+0x6d>
		else if (*h > pivot)
40002586:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002589:	8b 00                	mov    (%eax),%eax
4000258b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
4000258e:	7e 06                	jle    40002596 <pqsort+0x4b>
			h--;
40002590:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
40002594:	eb 22                	jmp    400025b8 <pqsort+0x6d>
		else
			swapints(*h, *l), l++, h--;
40002596:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002599:	8b 00                	mov    (%eax),%eax
4000259b:	89 45 e8             	mov    %eax,-0x18(%ebp)
4000259e:	8b 45 f4             	mov    -0xc(%ebp),%eax
400025a1:	8b 10                	mov    (%eax),%edx
400025a3:	8b 45 f0             	mov    -0x10(%ebp),%eax
400025a6:	89 10                	mov    %edx,(%eax)
400025a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
400025ab:	8b 55 e8             	mov    -0x18(%ebp),%edx
400025ae:	89 10                	mov    %edx,(%eax)
400025b0:	83 45 f4 04          	addl   $0x4,-0xc(%ebp)
400025b4:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
	if (lo >= hi)
		return;

	int pivot = *lo;	// yeah, bad way to choose pivot...
	int *l = lo+1, *h = hi;
	while (l <= h) {
400025b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
400025bb:	3b 45 f0             	cmp    -0x10(%ebp),%eax
400025be:	76 b6                	jbe    40002576 <pqsort+0x2b>
		else if (*h > pivot)
			h--;
		else
			swapints(*h, *l), l++, h--;
	}
	swapints(*lo, l[-1]);
400025c0:	8b 45 08             	mov    0x8(%ebp),%eax
400025c3:	8b 00                	mov    (%eax),%eax
400025c5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
400025c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
400025cb:	8b 50 fc             	mov    -0x4(%eax),%edx
400025ce:	8b 45 08             	mov    0x8(%ebp),%eax
400025d1:	89 10                	mov    %edx,(%eax)
400025d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
400025d6:	8d 50 fc             	lea    -0x4(%eax),%edx
400025d9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400025dc:	89 02                	mov    %eax,(%edx)

	// Now recursively sort the two halves in parallel subprocesses
	if (!fork(SYS_START | SYS_SNAP, 0)) {
400025de:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400025e5:	00 
400025e6:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
400025ed:	e8 52 db ff ff       	call   40000144 <fork>
400025f2:	85 c0                	test   %eax,%eax
400025f4:	75 1c                	jne    40002612 <pqsort+0xc7>
		pqsort(lo, l-2);
400025f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
400025f9:	83 e8 08             	sub    $0x8,%eax
400025fc:	89 44 24 04          	mov    %eax,0x4(%esp)
40002600:	8b 45 08             	mov    0x8(%ebp),%eax
40002603:	89 04 24             	mov    %eax,(%esp)
40002606:	e8 40 ff ff ff       	call   4000254b <pqsort>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000260b:	b8 03 00 00 00       	mov    $0x3,%eax
40002610:	cd 30                	int    $0x30
		sys_ret();
	}
	if (!fork(SYS_START | SYS_SNAP, 1)) {
40002612:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40002619:	00 
4000261a:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002621:	e8 1e db ff ff       	call   40000144 <fork>
40002626:	85 c0                	test   %eax,%eax
40002628:	75 1c                	jne    40002646 <pqsort+0xfb>
		pqsort(h+1, hi);
4000262a:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000262d:	8d 50 04             	lea    0x4(%eax),%edx
40002630:	8b 45 0c             	mov    0xc(%ebp),%eax
40002633:	89 44 24 04          	mov    %eax,0x4(%esp)
40002637:	89 14 24             	mov    %edx,(%esp)
4000263a:	e8 0c ff ff ff       	call   4000254b <pqsort>
4000263f:	b8 03 00 00 00       	mov    $0x3,%eax
40002644:	cd 30                	int    $0x30
		sys_ret();
	}
	join(SYS_MERGE, 0, T_SYSCALL);
40002646:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
4000264d:	00 
4000264e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002655:	00 
40002656:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
4000265d:	e8 b5 db ff ff       	call   40000217 <join>
	join(SYS_MERGE, 1, T_SYSCALL);
40002662:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
40002669:	00 
4000266a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40002671:	00 
40002672:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002679:	e8 99 db ff ff       	call   40000217 <join>
4000267e:	eb 01                	jmp    40002681 <pqsort+0x136>

void
pqsort(int *lo, int *hi)
{
	if (lo >= hi)
		return;
40002680:	90                   	nop
		pqsort(h+1, hi);
		sys_ret();
	}
	join(SYS_MERGE, 0, T_SYSCALL);
	join(SYS_MERGE, 1, T_SYSCALL);
}
40002681:	c9                   	leave  
40002682:	c3                   	ret    

40002683 <matmult>:
	{149128, 54805, 130652, 140309, 157630, 99208, 115657, 106951},
	{136163, 42930, 132817, 154486, 107399, 83659, 100339, 80010}};

void
matmult(int a[8][8], int b[8][8], int r[8][8])
{
40002683:	55                   	push   %ebp
40002684:	89 e5                	mov    %esp,%ebp
40002686:	83 ec 38             	sub    $0x38,%esp
	int i,j,k;

	// Fork off a thread to compute each cell in the result matrix
	for (i = 0; i < 8; i++)
40002689:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
40002690:	e9 ae 00 00 00       	jmp    40002743 <matmult+0xc0>
		for (j = 0; j < 8; j++) {
40002695:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
4000269c:	e9 94 00 00 00       	jmp    40002735 <matmult+0xb2>
			int child = i*8 + j;
400026a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
400026a4:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
400026ab:	8b 45 f0             	mov    -0x10(%ebp),%eax
400026ae:	01 d0                	add    %edx,%eax
400026b0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			if (!fork(SYS_START | SYS_SNAP, child)) {
400026b3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400026b6:	0f b6 c0             	movzbl %al,%eax
400026b9:	89 44 24 04          	mov    %eax,0x4(%esp)
400026bd:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
400026c4:	e8 7b da ff ff       	call   40000144 <fork>
400026c9:	85 c0                	test   %eax,%eax
400026cb:	75 64                	jne    40002731 <matmult+0xae>
				int sum = 0;	// in child: compute cell i,j
400026cd:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
				for (k = 0; k < 8; k++)
400026d4:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
400026db:	eb 30                	jmp    4000270d <matmult+0x8a>
					sum += a[i][k] * b[k][j];
400026dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
400026e0:	89 c2                	mov    %eax,%edx
400026e2:	c1 e2 05             	shl    $0x5,%edx
400026e5:	8b 45 08             	mov    0x8(%ebp),%eax
400026e8:	01 c2                	add    %eax,%edx
400026ea:	8b 45 ec             	mov    -0x14(%ebp),%eax
400026ed:	8b 14 82             	mov    (%edx,%eax,4),%edx
400026f0:	8b 45 ec             	mov    -0x14(%ebp),%eax
400026f3:	89 c1                	mov    %eax,%ecx
400026f5:	c1 e1 05             	shl    $0x5,%ecx
400026f8:	8b 45 0c             	mov    0xc(%ebp),%eax
400026fb:	01 c1                	add    %eax,%ecx
400026fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002700:	8b 04 81             	mov    (%ecx,%eax,4),%eax
40002703:	0f af c2             	imul   %edx,%eax
40002706:	01 45 e8             	add    %eax,-0x18(%ebp)
	for (i = 0; i < 8; i++)
		for (j = 0; j < 8; j++) {
			int child = i*8 + j;
			if (!fork(SYS_START | SYS_SNAP, child)) {
				int sum = 0;	// in child: compute cell i,j
				for (k = 0; k < 8; k++)
40002709:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
4000270d:	83 7d ec 07          	cmpl   $0x7,-0x14(%ebp)
40002711:	7e ca                	jle    400026dd <matmult+0x5a>
					sum += a[i][k] * b[k][j];
				r[i][j] = sum;
40002713:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002716:	89 c2                	mov    %eax,%edx
40002718:	c1 e2 05             	shl    $0x5,%edx
4000271b:	8b 45 10             	mov    0x10(%ebp),%eax
4000271e:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
40002721:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002724:	8b 55 e8             	mov    -0x18(%ebp),%edx
40002727:	89 14 81             	mov    %edx,(%ecx,%eax,4)
4000272a:	b8 03 00 00 00       	mov    $0x3,%eax
4000272f:	cd 30                	int    $0x30
{
	int i,j,k;

	// Fork off a thread to compute each cell in the result matrix
	for (i = 0; i < 8; i++)
		for (j = 0; j < 8; j++) {
40002731:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
40002735:	83 7d f0 07          	cmpl   $0x7,-0x10(%ebp)
40002739:	0f 8e 62 ff ff ff    	jle    400026a1 <matmult+0x1e>
matmult(int a[8][8], int b[8][8], int r[8][8])
{
	int i,j,k;

	// Fork off a thread to compute each cell in the result matrix
	for (i = 0; i < 8; i++)
4000273f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40002743:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
40002747:	0f 8e 48 ff ff ff    	jle    40002695 <matmult+0x12>
				sys_ret();
			}
		}

	// Now go back and merge in the results of all our children
	for (i = 0; i < 8; i++)
4000274d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
40002754:	eb 47                	jmp    4000279d <matmult+0x11a>
		for (j = 0; j < 8; j++) {
40002756:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
4000275d:	eb 34                	jmp    40002793 <matmult+0x110>
			int child = i*8 + j;
4000275f:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002762:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
40002769:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000276c:	01 d0                	add    %edx,%eax
4000276e:	89 45 e0             	mov    %eax,-0x20(%ebp)
			join(SYS_MERGE, child, T_SYSCALL);
40002771:	8b 45 e0             	mov    -0x20(%ebp),%eax
40002774:	0f b6 c0             	movzbl %al,%eax
40002777:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
4000277e:	00 
4000277f:	89 44 24 04          	mov    %eax,0x4(%esp)
40002783:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
4000278a:	e8 88 da ff ff       	call   40000217 <join>
			}
		}

	// Now go back and merge in the results of all our children
	for (i = 0; i < 8; i++)
		for (j = 0; j < 8; j++) {
4000278f:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
40002793:	83 7d f0 07          	cmpl   $0x7,-0x10(%ebp)
40002797:	7e c6                	jle    4000275f <matmult+0xdc>
				sys_ret();
			}
		}

	// Now go back and merge in the results of all our children
	for (i = 0; i < 8; i++)
40002799:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
4000279d:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
400027a1:	7e b3                	jle    40002756 <matmult+0xd3>
		for (j = 0; j < 8; j++) {
			int child = i*8 + j;
			join(SYS_MERGE, child, T_SYSCALL);
		}
}
400027a3:	c9                   	leave  
400027a4:	c3                   	ret    

400027a5 <mergecheck>:

void
mergecheck()
{
400027a5:	55                   	push   %ebp
400027a6:	89 e5                	mov    %esp,%ebp
400027a8:	83 ec 18             	sub    $0x18,%esp
	// Simple merge test: two children write two adjacent variables
	if (!fork(SYS_START | SYS_SNAP, 0)) { x = 0xdeadbeef; sys_ret(); }
400027ab:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400027b2:	00 
400027b3:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
400027ba:	e8 85 d9 ff ff       	call   40000144 <fork>
400027bf:	85 c0                	test   %eax,%eax
400027c1:	75 11                	jne    400027d4 <mergecheck+0x2f>
400027c3:	c7 05 c0 7b 00 40 ef 	movl   $0xdeadbeef,0x40007bc0
400027ca:	be ad de 
400027cd:	b8 03 00 00 00       	mov    $0x3,%eax
400027d2:	cd 30                	int    $0x30
	if (!fork(SYS_START | SYS_SNAP, 1)) { y = 0xabadcafe; sys_ret(); }
400027d4:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400027db:	00 
400027dc:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
400027e3:	e8 5c d9 ff ff       	call   40000144 <fork>
400027e8:	85 c0                	test   %eax,%eax
400027ea:	75 11                	jne    400027fd <mergecheck+0x58>
400027ec:	c7 05 e0 9c 00 40 fe 	movl   $0xabadcafe,0x40009ce0
400027f3:	ca ad ab 
400027f6:	b8 03 00 00 00       	mov    $0x3,%eax
400027fb:	cd 30                	int    $0x30
	assert(x == 0); assert(y == 0);
400027fd:	a1 c0 7b 00 40       	mov    0x40007bc0,%eax
40002802:	85 c0                	test   %eax,%eax
40002804:	74 24                	je     4000282a <mergecheck+0x85>
40002806:	c7 44 24 0c 80 59 00 	movl   $0x40005980,0xc(%esp)
4000280d:	40 
4000280e:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
40002815:	40 
40002816:	c7 44 24 04 d6 01 00 	movl   $0x1d6,0x4(%esp)
4000281d:	00 
4000281e:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40002825:	e8 16 03 00 00       	call   40002b40 <debug_panic>
4000282a:	a1 e0 9c 00 40       	mov    0x40009ce0,%eax
4000282f:	85 c0                	test   %eax,%eax
40002831:	74 24                	je     40002857 <mergecheck+0xb2>
40002833:	c7 44 24 0c 87 59 00 	movl   $0x40005987,0xc(%esp)
4000283a:	40 
4000283b:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
40002842:	40 
40002843:	c7 44 24 04 d6 01 00 	movl   $0x1d6,0x4(%esp)
4000284a:	00 
4000284b:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40002852:	e8 e9 02 00 00       	call   40002b40 <debug_panic>
	join(SYS_MERGE, 0, T_SYSCALL);
40002857:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
4000285e:	00 
4000285f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002866:	00 
40002867:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
4000286e:	e8 a4 d9 ff ff       	call   40000217 <join>
	join(SYS_MERGE, 1, T_SYSCALL);
40002873:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
4000287a:	00 
4000287b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40002882:	00 
40002883:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
4000288a:	e8 88 d9 ff ff       	call   40000217 <join>
	assert(x == 0xdeadbeef); assert(y == 0xabadcafe);
4000288f:	a1 c0 7b 00 40       	mov    0x40007bc0,%eax
40002894:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
40002899:	74 24                	je     400028bf <mergecheck+0x11a>
4000289b:	c7 44 24 0c 8e 59 00 	movl   $0x4000598e,0xc(%esp)
400028a2:	40 
400028a3:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
400028aa:	40 
400028ab:	c7 44 24 04 d9 01 00 	movl   $0x1d9,0x4(%esp)
400028b2:	00 
400028b3:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
400028ba:	e8 81 02 00 00       	call   40002b40 <debug_panic>
400028bf:	a1 e0 9c 00 40       	mov    0x40009ce0,%eax
400028c4:	3d fe ca ad ab       	cmp    $0xabadcafe,%eax
400028c9:	74 24                	je     400028ef <mergecheck+0x14a>
400028cb:	c7 44 24 0c 9e 59 00 	movl   $0x4000599e,0xc(%esp)
400028d2:	40 
400028d3:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
400028da:	40 
400028db:	c7 44 24 04 d9 01 00 	movl   $0x1d9,0x4(%esp)
400028e2:	00 
400028e3:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
400028ea:	e8 51 02 00 00       	call   40002b40 <debug_panic>

	// A Rube Goldberg approach to swapping two variables
	if (!fork(SYS_START | SYS_SNAP, 0)) { x = y; sys_ret(); }
400028ef:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400028f6:	00 
400028f7:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
400028fe:	e8 41 d8 ff ff       	call   40000144 <fork>
40002903:	85 c0                	test   %eax,%eax
40002905:	75 11                	jne    40002918 <mergecheck+0x173>
40002907:	a1 e0 9c 00 40       	mov    0x40009ce0,%eax
4000290c:	a3 c0 7b 00 40       	mov    %eax,0x40007bc0
40002911:	b8 03 00 00 00       	mov    $0x3,%eax
40002916:	cd 30                	int    $0x30
	if (!fork(SYS_START | SYS_SNAP, 1)) { y = x; sys_ret(); }
40002918:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
4000291f:	00 
40002920:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002927:	e8 18 d8 ff ff       	call   40000144 <fork>
4000292c:	85 c0                	test   %eax,%eax
4000292e:	75 11                	jne    40002941 <mergecheck+0x19c>
40002930:	a1 c0 7b 00 40       	mov    0x40007bc0,%eax
40002935:	a3 e0 9c 00 40       	mov    %eax,0x40009ce0
4000293a:	b8 03 00 00 00       	mov    $0x3,%eax
4000293f:	cd 30                	int    $0x30
	assert(x == 0xdeadbeef); assert(y == 0xabadcafe);
40002941:	a1 c0 7b 00 40       	mov    0x40007bc0,%eax
40002946:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
4000294b:	74 24                	je     40002971 <mergecheck+0x1cc>
4000294d:	c7 44 24 0c 8e 59 00 	movl   $0x4000598e,0xc(%esp)
40002954:	40 
40002955:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
4000295c:	40 
4000295d:	c7 44 24 04 de 01 00 	movl   $0x1de,0x4(%esp)
40002964:	00 
40002965:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
4000296c:	e8 cf 01 00 00       	call   40002b40 <debug_panic>
40002971:	a1 e0 9c 00 40       	mov    0x40009ce0,%eax
40002976:	3d fe ca ad ab       	cmp    $0xabadcafe,%eax
4000297b:	74 24                	je     400029a1 <mergecheck+0x1fc>
4000297d:	c7 44 24 0c 9e 59 00 	movl   $0x4000599e,0xc(%esp)
40002984:	40 
40002985:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
4000298c:	40 
4000298d:	c7 44 24 04 de 01 00 	movl   $0x1de,0x4(%esp)
40002994:	00 
40002995:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
4000299c:	e8 9f 01 00 00       	call   40002b40 <debug_panic>
	join(SYS_MERGE, 0, T_SYSCALL);
400029a1:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400029a8:	00 
400029a9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400029b0:	00 
400029b1:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
400029b8:	e8 5a d8 ff ff       	call   40000217 <join>
	join(SYS_MERGE, 1, T_SYSCALL);
400029bd:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400029c4:	00 
400029c5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400029cc:	00 
400029cd:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
400029d4:	e8 3e d8 ff ff       	call   40000217 <join>
	assert(y == 0xdeadbeef); assert(x == 0xabadcafe);
400029d9:	a1 e0 9c 00 40       	mov    0x40009ce0,%eax
400029de:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
400029e3:	74 24                	je     40002a09 <mergecheck+0x264>
400029e5:	c7 44 24 0c ae 59 00 	movl   $0x400059ae,0xc(%esp)
400029ec:	40 
400029ed:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
400029f4:	40 
400029f5:	c7 44 24 04 e1 01 00 	movl   $0x1e1,0x4(%esp)
400029fc:	00 
400029fd:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40002a04:	e8 37 01 00 00       	call   40002b40 <debug_panic>
40002a09:	a1 c0 7b 00 40       	mov    0x40007bc0,%eax
40002a0e:	3d fe ca ad ab       	cmp    $0xabadcafe,%eax
40002a13:	74 24                	je     40002a39 <mergecheck+0x294>
40002a15:	c7 44 24 0c be 59 00 	movl   $0x400059be,0xc(%esp)
40002a1c:	40 
40002a1d:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
40002a24:	40 
40002a25:	c7 44 24 04 e1 01 00 	movl   $0x1e1,0x4(%esp)
40002a2c:	00 
40002a2d:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40002a34:	e8 07 01 00 00       	call   40002b40 <debug_panic>

	// Parallel quicksort with recursive processes!
	// (though probably not very efficient on arrays this small)
	pqsort(&randints[0], &randints[59]);
40002a39:	c7 44 24 04 ac 79 00 	movl   $0x400079ac,0x4(%esp)
40002a40:	40 
40002a41:	c7 04 24 c0 78 00 40 	movl   $0x400078c0,(%esp)
40002a48:	e8 fe fa ff ff       	call   4000254b <pqsort>
	assert(memcmp(randints, sortints, 60*sizeof(int)) == 0);
40002a4d:	c7 44 24 08 f0 00 00 	movl   $0xf0,0x8(%esp)
40002a54:	00 
40002a55:	c7 44 24 04 80 57 00 	movl   $0x40005780,0x4(%esp)
40002a5c:	40 
40002a5d:	c7 04 24 c0 78 00 40 	movl   $0x400078c0,(%esp)
40002a64:	e8 71 0d 00 00       	call   400037da <memcmp>
40002a69:	85 c0                	test   %eax,%eax
40002a6b:	74 24                	je     40002a91 <mergecheck+0x2ec>
40002a6d:	c7 44 24 0c d0 59 00 	movl   $0x400059d0,0xc(%esp)
40002a74:	40 
40002a75:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
40002a7c:	40 
40002a7d:	c7 44 24 04 e6 01 00 	movl   $0x1e6,0x4(%esp)
40002a84:	00 
40002a85:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40002a8c:	e8 af 00 00 00       	call   40002b40 <debug_panic>

	// Parallel matrix multiply, one child process per result matrix cell
	matmult(ma, mb, mr);
40002a91:	c7 44 24 08 e0 9b 00 	movl   $0x40009be0,0x8(%esp)
40002a98:	40 
40002a99:	c7 44 24 04 c0 7a 00 	movl   $0x40007ac0,0x4(%esp)
40002aa0:	40 
40002aa1:	c7 04 24 c0 79 00 40 	movl   $0x400079c0,(%esp)
40002aa8:	e8 d6 fb ff ff       	call   40002683 <matmult>
	assert(sizeof(mr) == sizeof(int)*8*8);
	assert(sizeof(mc) == sizeof(int)*8*8);
	assert(memcmp(mr, mc, sizeof(mr)) == 0);
40002aad:	c7 44 24 08 00 01 00 	movl   $0x100,0x8(%esp)
40002ab4:	00 
40002ab5:	c7 44 24 04 80 58 00 	movl   $0x40005880,0x4(%esp)
40002abc:	40 
40002abd:	c7 04 24 e0 9b 00 40 	movl   $0x40009be0,(%esp)
40002ac4:	e8 11 0d 00 00       	call   400037da <memcmp>
40002ac9:	85 c0                	test   %eax,%eax
40002acb:	74 24                	je     40002af1 <mergecheck+0x34c>
40002acd:	c7 44 24 0c 00 5a 00 	movl   $0x40005a00,0xc(%esp)
40002ad4:	40 
40002ad5:	c7 44 24 08 fb 55 00 	movl   $0x400055fb,0x8(%esp)
40002adc:	40 
40002add:	c7 44 24 04 ec 01 00 	movl   $0x1ec,0x4(%esp)
40002ae4:	00 
40002ae5:	c7 04 24 08 55 00 40 	movl   $0x40005508,(%esp)
40002aec:	e8 4f 00 00 00       	call   40002b40 <debug_panic>

	cprintf("testvm: mergecheck passed\n");
40002af1:	c7 04 24 20 5a 00 40 	movl   $0x40005a20,(%esp)
40002af8:	e8 d7 02 00 00       	call   40002dd4 <cprintf>
}
40002afd:	c9                   	leave  
40002afe:	c3                   	ret    

40002aff <main>:

int
main()
{
40002aff:	55                   	push   %ebp
40002b00:	89 e5                	mov    %esp,%ebp
40002b02:	83 e4 f0             	and    $0xfffffff0,%esp
40002b05:	83 ec 10             	sub    $0x10,%esp
	cprintf("testvm: in main()\n");
40002b08:	c7 04 24 3b 5a 00 40 	movl   $0x40005a3b,(%esp)
40002b0f:	e8 c0 02 00 00       	call   40002dd4 <cprintf>

	loadcheck();
40002b14:	e8 a0 d8 ff ff       	call   400003b9 <loadcheck>
	forkcheck();
40002b19:	e8 1d d9 ff ff       	call   4000043b <forkcheck>
	protcheck();
40002b1e:	e8 7c dc ff ff       	call   4000079f <protcheck>
	memopcheck();
40002b23:	e8 26 eb ff ff       	call   4000164e <memopcheck>
	mergecheck();
40002b28:	e8 78 fc ff ff       	call   400027a5 <mergecheck>

	cprintf("testvm: all tests completed successfully!\n");
40002b2d:	c7 04 24 50 5a 00 40 	movl   $0x40005a50,(%esp)
40002b34:	e8 9b 02 00 00       	call   40002dd4 <cprintf>
	return 0;
40002b39:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002b3e:	c9                   	leave  
40002b3f:	c3                   	ret    

40002b40 <debug_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: <message>", then causes a breakpoint exception.
 */
void
debug_panic(const char *file, int line, const char *fmt,...)
{
40002b40:	55                   	push   %ebp
40002b41:	89 e5                	mov    %esp,%ebp
40002b43:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	va_start(ap, fmt);
40002b46:	8d 45 10             	lea    0x10(%ebp),%eax
40002b49:	83 c0 04             	add    $0x4,%eax
40002b4c:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Print the panic message
	if (argv0)
40002b4f:	a1 e4 9c 00 40       	mov    0x40009ce4,%eax
40002b54:	85 c0                	test   %eax,%eax
40002b56:	74 15                	je     40002b6d <debug_panic+0x2d>
		cprintf("%s: ", argv0);
40002b58:	a1 e4 9c 00 40       	mov    0x40009ce4,%eax
40002b5d:	89 44 24 04          	mov    %eax,0x4(%esp)
40002b61:	c7 04 24 7c 5a 00 40 	movl   $0x40005a7c,(%esp)
40002b68:	e8 67 02 00 00       	call   40002dd4 <cprintf>
	cprintf("user panic at %s:%d: ", file, line);
40002b6d:	8b 45 0c             	mov    0xc(%ebp),%eax
40002b70:	89 44 24 08          	mov    %eax,0x8(%esp)
40002b74:	8b 45 08             	mov    0x8(%ebp),%eax
40002b77:	89 44 24 04          	mov    %eax,0x4(%esp)
40002b7b:	c7 04 24 81 5a 00 40 	movl   $0x40005a81,(%esp)
40002b82:	e8 4d 02 00 00       	call   40002dd4 <cprintf>
	vcprintf(fmt, ap);
40002b87:	8b 45 10             	mov    0x10(%ebp),%eax
40002b8a:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002b8d:	89 54 24 04          	mov    %edx,0x4(%esp)
40002b91:	89 04 24             	mov    %eax,(%esp)
40002b94:	e8 d3 01 00 00       	call   40002d6c <vcprintf>
	cprintf("\n");
40002b99:	c7 04 24 97 5a 00 40 	movl   $0x40005a97,(%esp)
40002ba0:	e8 2f 02 00 00       	call   40002dd4 <cprintf>

	abort();
40002ba5:	e8 06 0d 00 00       	call   400038b0 <abort>

40002baa <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
40002baa:	55                   	push   %ebp
40002bab:	89 e5                	mov    %esp,%ebp
40002bad:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
40002bb0:	8d 45 10             	lea    0x10(%ebp),%eax
40002bb3:	83 c0 04             	add    $0x4,%eax
40002bb6:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("user warning at %s:%d: ", file, line);
40002bb9:	8b 45 0c             	mov    0xc(%ebp),%eax
40002bbc:	89 44 24 08          	mov    %eax,0x8(%esp)
40002bc0:	8b 45 08             	mov    0x8(%ebp),%eax
40002bc3:	89 44 24 04          	mov    %eax,0x4(%esp)
40002bc7:	c7 04 24 99 5a 00 40 	movl   $0x40005a99,(%esp)
40002bce:	e8 01 02 00 00       	call   40002dd4 <cprintf>
	vcprintf(fmt, ap);
40002bd3:	8b 45 10             	mov    0x10(%ebp),%eax
40002bd6:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002bd9:	89 54 24 04          	mov    %edx,0x4(%esp)
40002bdd:	89 04 24             	mov    %eax,(%esp)
40002be0:	e8 87 01 00 00       	call   40002d6c <vcprintf>
	cprintf("\n");
40002be5:	c7 04 24 97 5a 00 40 	movl   $0x40005a97,(%esp)
40002bec:	e8 e3 01 00 00       	call   40002dd4 <cprintf>
	va_end(ap);
}
40002bf1:	c9                   	leave  
40002bf2:	c3                   	ret    

40002bf3 <debug_dump>:

// Dump a block of memory as 32-bit words and ASCII bytes
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
40002bf3:	55                   	push   %ebp
40002bf4:	89 e5                	mov    %esp,%ebp
40002bf6:	56                   	push   %esi
40002bf7:	53                   	push   %ebx
40002bf8:	81 ec a0 00 00 00    	sub    $0xa0,%esp
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
40002bfe:	8b 55 14             	mov    0x14(%ebp),%edx
40002c01:	8b 45 10             	mov    0x10(%ebp),%eax
40002c04:	01 d0                	add    %edx,%eax
40002c06:	89 44 24 10          	mov    %eax,0x10(%esp)
40002c0a:	8b 45 10             	mov    0x10(%ebp),%eax
40002c0d:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002c11:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c14:	89 44 24 08          	mov    %eax,0x8(%esp)
40002c18:	8b 45 08             	mov    0x8(%ebp),%eax
40002c1b:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c1f:	c7 04 24 b4 5a 00 40 	movl   $0x40005ab4,(%esp)
40002c26:	e8 a9 01 00 00       	call   40002dd4 <cprintf>
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
40002c2b:	8b 45 14             	mov    0x14(%ebp),%eax
40002c2e:	83 c0 0f             	add    $0xf,%eax
40002c31:	83 e0 f0             	and    $0xfffffff0,%eax
40002c34:	89 45 14             	mov    %eax,0x14(%ebp)
40002c37:	e9 bb 00 00 00       	jmp    40002cf7 <debug_dump+0x104>
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
40002c3c:	8b 45 10             	mov    0x10(%ebp),%eax
40002c3f:	89 45 f0             	mov    %eax,-0x10(%ebp)
		for (i = 0; i < 16; i++)
40002c42:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
40002c49:	eb 4d                	jmp    40002c98 <debug_dump+0xa5>
			buf[i] = isprint(c[i]) ? c[i] : '.';
40002c4b:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002c4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002c51:	01 d0                	add    %edx,%eax
40002c53:	0f b6 00             	movzbl (%eax),%eax
40002c56:	0f b6 c0             	movzbl %al,%eax
40002c59:	89 45 e8             	mov    %eax,-0x18(%ebp)
static gcc_inline int isalnum(int c)	{ return isalpha(c) || isdigit(c); }
static gcc_inline int iscntrl(int c)	{ return c < ' '; }
static gcc_inline int isblank(int c)	{ return c == ' ' || c == '\t'; }
static gcc_inline int isspace(int c)	{ return c == ' '
						|| (c >= '\t' && c <= '\r'); }
static gcc_inline int isprint(int c)	{ return c >= ' ' && c <= '~'; }
40002c5c:	83 7d e8 1f          	cmpl   $0x1f,-0x18(%ebp)
40002c60:	7e 0d                	jle    40002c6f <debug_dump+0x7c>
40002c62:	83 7d e8 7e          	cmpl   $0x7e,-0x18(%ebp)
40002c66:	7f 07                	jg     40002c6f <debug_dump+0x7c>
40002c68:	b8 01 00 00 00       	mov    $0x1,%eax
40002c6d:	eb 05                	jmp    40002c74 <debug_dump+0x81>
40002c6f:	b8 00 00 00 00       	mov    $0x0,%eax
40002c74:	85 c0                	test   %eax,%eax
40002c76:	74 0d                	je     40002c85 <debug_dump+0x92>
40002c78:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002c7b:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002c7e:	01 d0                	add    %edx,%eax
40002c80:	0f b6 00             	movzbl (%eax),%eax
40002c83:	eb 05                	jmp    40002c8a <debug_dump+0x97>
40002c85:	b8 2e 00 00 00       	mov    $0x2e,%eax
40002c8a:	8d 4d 84             	lea    -0x7c(%ebp),%ecx
40002c8d:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002c90:	01 ca                	add    %ecx,%edx
40002c92:	88 02                	mov    %al,(%edx)
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
		for (i = 0; i < 16; i++)
40002c94:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40002c98:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
40002c9c:	7e ad                	jle    40002c4b <debug_dump+0x58>
			buf[i] = isprint(c[i]) ? c[i] : '.';
		buf[16] = 0;
40002c9e:	c6 45 94 00          	movb   $0x0,-0x6c(%ebp)

		// Hex words
		const uint32_t *v = ptr;
40002ca2:	8b 45 10             	mov    0x10(%ebp),%eax
40002ca5:	89 45 ec             	mov    %eax,-0x14(%ebp)

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
			ptr, v[0], v[1], v[2], v[3], buf);
40002ca8:	8b 45 ec             	mov    -0x14(%ebp),%eax
40002cab:	83 c0 0c             	add    $0xc,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40002cae:	8b 18                	mov    (%eax),%ebx
			ptr, v[0], v[1], v[2], v[3], buf);
40002cb0:	8b 45 ec             	mov    -0x14(%ebp),%eax
40002cb3:	83 c0 08             	add    $0x8,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40002cb6:	8b 08                	mov    (%eax),%ecx
			ptr, v[0], v[1], v[2], v[3], buf);
40002cb8:	8b 45 ec             	mov    -0x14(%ebp),%eax
40002cbb:	83 c0 04             	add    $0x4,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40002cbe:	8b 10                	mov    (%eax),%edx
40002cc0:	8b 45 ec             	mov    -0x14(%ebp),%eax
40002cc3:	8b 00                	mov    (%eax),%eax
			ptr, v[0], v[1], v[2], v[3], buf);
40002cc5:	8d 75 84             	lea    -0x7c(%ebp),%esi
40002cc8:	89 74 24 18          	mov    %esi,0x18(%esp)

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40002ccc:	89 5c 24 14          	mov    %ebx,0x14(%esp)
40002cd0:	89 4c 24 10          	mov    %ecx,0x10(%esp)
40002cd4:	89 54 24 0c          	mov    %edx,0xc(%esp)
40002cd8:	89 44 24 08          	mov    %eax,0x8(%esp)
40002cdc:	8b 45 10             	mov    0x10(%ebp),%eax
40002cdf:	89 44 24 04          	mov    %eax,0x4(%esp)
40002ce3:	c7 04 24 dd 5a 00 40 	movl   $0x40005add,(%esp)
40002cea:	e8 e5 00 00 00       	call   40002dd4 <cprintf>
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
40002cef:	83 6d 14 10          	subl   $0x10,0x14(%ebp)
40002cf3:	83 45 10 10          	addl   $0x10,0x10(%ebp)
40002cf7:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40002cfb:	0f 8f 3b ff ff ff    	jg     40002c3c <debug_dump+0x49>

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
			ptr, v[0], v[1], v[2], v[3], buf);
	}
}
40002d01:	81 c4 a0 00 00 00    	add    $0xa0,%esp
40002d07:	5b                   	pop    %ebx
40002d08:	5e                   	pop    %esi
40002d09:	5d                   	pop    %ebp
40002d0a:	c3                   	ret    
40002d0b:	90                   	nop

40002d0c <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
40002d0c:	55                   	push   %ebp
40002d0d:	89 e5                	mov    %esp,%ebp
40002d0f:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
40002d12:	8b 45 0c             	mov    0xc(%ebp),%eax
40002d15:	8b 00                	mov    (%eax),%eax
40002d17:	8b 55 08             	mov    0x8(%ebp),%edx
40002d1a:	89 d1                	mov    %edx,%ecx
40002d1c:	8b 55 0c             	mov    0xc(%ebp),%edx
40002d1f:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
40002d23:	8d 50 01             	lea    0x1(%eax),%edx
40002d26:	8b 45 0c             	mov    0xc(%ebp),%eax
40002d29:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
40002d2b:	8b 45 0c             	mov    0xc(%ebp),%eax
40002d2e:	8b 00                	mov    (%eax),%eax
40002d30:	3d ff 00 00 00       	cmp    $0xff,%eax
40002d35:	75 24                	jne    40002d5b <putch+0x4f>
		b->buf[b->idx] = 0;
40002d37:	8b 45 0c             	mov    0xc(%ebp),%eax
40002d3a:	8b 00                	mov    (%eax),%eax
40002d3c:	8b 55 0c             	mov    0xc(%ebp),%edx
40002d3f:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
40002d44:	8b 45 0c             	mov    0xc(%ebp),%eax
40002d47:	83 c0 08             	add    $0x8,%eax
40002d4a:	89 04 24             	mov    %eax,(%esp)
40002d4d:	e8 72 0b 00 00       	call   400038c4 <cputs>
		b->idx = 0;
40002d52:	8b 45 0c             	mov    0xc(%ebp),%eax
40002d55:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
40002d5b:	8b 45 0c             	mov    0xc(%ebp),%eax
40002d5e:	8b 40 04             	mov    0x4(%eax),%eax
40002d61:	8d 50 01             	lea    0x1(%eax),%edx
40002d64:	8b 45 0c             	mov    0xc(%ebp),%eax
40002d67:	89 50 04             	mov    %edx,0x4(%eax)
}
40002d6a:	c9                   	leave  
40002d6b:	c3                   	ret    

40002d6c <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
40002d6c:	55                   	push   %ebp
40002d6d:	89 e5                	mov    %esp,%ebp
40002d6f:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
40002d75:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
40002d7c:	00 00 00 
	b.cnt = 0;
40002d7f:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
40002d86:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
40002d89:	8b 45 0c             	mov    0xc(%ebp),%eax
40002d8c:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002d90:	8b 45 08             	mov    0x8(%ebp),%eax
40002d93:	89 44 24 08          	mov    %eax,0x8(%esp)
40002d97:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
40002d9d:	89 44 24 04          	mov    %eax,0x4(%esp)
40002da1:	c7 04 24 0c 2d 00 40 	movl   $0x40002d0c,(%esp)
40002da8:	e8 70 03 00 00       	call   4000311d <vprintfmt>

	b.buf[b.idx] = 0;
40002dad:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
40002db3:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
40002dba:	00 
	cputs(b.buf);
40002dbb:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
40002dc1:	83 c0 08             	add    $0x8,%eax
40002dc4:	89 04 24             	mov    %eax,(%esp)
40002dc7:	e8 f8 0a 00 00       	call   400038c4 <cputs>

	return b.cnt;
40002dcc:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
40002dd2:	c9                   	leave  
40002dd3:	c3                   	ret    

40002dd4 <cprintf>:

int
cprintf(const char *fmt, ...)
{
40002dd4:	55                   	push   %ebp
40002dd5:	89 e5                	mov    %esp,%ebp
40002dd7:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
40002dda:	8d 45 0c             	lea    0xc(%ebp),%eax
40002ddd:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
40002de0:	8b 45 08             	mov    0x8(%ebp),%eax
40002de3:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002de6:	89 54 24 04          	mov    %edx,0x4(%esp)
40002dea:	89 04 24             	mov    %eax,(%esp)
40002ded:	e8 7a ff ff ff       	call   40002d6c <vcprintf>
40002df2:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
40002df5:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40002df8:	c9                   	leave  
40002df9:	c3                   	ret    
40002dfa:	66 90                	xchg   %ax,%ax

40002dfc <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
40002dfc:	55                   	push   %ebp
40002dfd:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
40002dff:	8b 45 08             	mov    0x8(%ebp),%eax
40002e02:	8b 40 18             	mov    0x18(%eax),%eax
40002e05:	83 e0 02             	and    $0x2,%eax
40002e08:	85 c0                	test   %eax,%eax
40002e0a:	74 1c                	je     40002e28 <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
40002e0c:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e0f:	8b 00                	mov    (%eax),%eax
40002e11:	8d 50 08             	lea    0x8(%eax),%edx
40002e14:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e17:	89 10                	mov    %edx,(%eax)
40002e19:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e1c:	8b 00                	mov    (%eax),%eax
40002e1e:	83 e8 08             	sub    $0x8,%eax
40002e21:	8b 50 04             	mov    0x4(%eax),%edx
40002e24:	8b 00                	mov    (%eax),%eax
40002e26:	eb 47                	jmp    40002e6f <getuint+0x73>
	else if (st->flags & F_L)
40002e28:	8b 45 08             	mov    0x8(%ebp),%eax
40002e2b:	8b 40 18             	mov    0x18(%eax),%eax
40002e2e:	83 e0 01             	and    $0x1,%eax
40002e31:	85 c0                	test   %eax,%eax
40002e33:	74 1e                	je     40002e53 <getuint+0x57>
		return va_arg(*ap, unsigned long);
40002e35:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e38:	8b 00                	mov    (%eax),%eax
40002e3a:	8d 50 04             	lea    0x4(%eax),%edx
40002e3d:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e40:	89 10                	mov    %edx,(%eax)
40002e42:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e45:	8b 00                	mov    (%eax),%eax
40002e47:	83 e8 04             	sub    $0x4,%eax
40002e4a:	8b 00                	mov    (%eax),%eax
40002e4c:	ba 00 00 00 00       	mov    $0x0,%edx
40002e51:	eb 1c                	jmp    40002e6f <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
40002e53:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e56:	8b 00                	mov    (%eax),%eax
40002e58:	8d 50 04             	lea    0x4(%eax),%edx
40002e5b:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e5e:	89 10                	mov    %edx,(%eax)
40002e60:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e63:	8b 00                	mov    (%eax),%eax
40002e65:	83 e8 04             	sub    $0x4,%eax
40002e68:	8b 00                	mov    (%eax),%eax
40002e6a:	ba 00 00 00 00       	mov    $0x0,%edx
}
40002e6f:	5d                   	pop    %ebp
40002e70:	c3                   	ret    

40002e71 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
40002e71:	55                   	push   %ebp
40002e72:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
40002e74:	8b 45 08             	mov    0x8(%ebp),%eax
40002e77:	8b 40 18             	mov    0x18(%eax),%eax
40002e7a:	83 e0 02             	and    $0x2,%eax
40002e7d:	85 c0                	test   %eax,%eax
40002e7f:	74 1c                	je     40002e9d <getint+0x2c>
		return va_arg(*ap, long long);
40002e81:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e84:	8b 00                	mov    (%eax),%eax
40002e86:	8d 50 08             	lea    0x8(%eax),%edx
40002e89:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e8c:	89 10                	mov    %edx,(%eax)
40002e8e:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e91:	8b 00                	mov    (%eax),%eax
40002e93:	83 e8 08             	sub    $0x8,%eax
40002e96:	8b 50 04             	mov    0x4(%eax),%edx
40002e99:	8b 00                	mov    (%eax),%eax
40002e9b:	eb 47                	jmp    40002ee4 <getint+0x73>
	else if (st->flags & F_L)
40002e9d:	8b 45 08             	mov    0x8(%ebp),%eax
40002ea0:	8b 40 18             	mov    0x18(%eax),%eax
40002ea3:	83 e0 01             	and    $0x1,%eax
40002ea6:	85 c0                	test   %eax,%eax
40002ea8:	74 1e                	je     40002ec8 <getint+0x57>
		return va_arg(*ap, long);
40002eaa:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ead:	8b 00                	mov    (%eax),%eax
40002eaf:	8d 50 04             	lea    0x4(%eax),%edx
40002eb2:	8b 45 0c             	mov    0xc(%ebp),%eax
40002eb5:	89 10                	mov    %edx,(%eax)
40002eb7:	8b 45 0c             	mov    0xc(%ebp),%eax
40002eba:	8b 00                	mov    (%eax),%eax
40002ebc:	83 e8 04             	sub    $0x4,%eax
40002ebf:	8b 00                	mov    (%eax),%eax
40002ec1:	89 c2                	mov    %eax,%edx
40002ec3:	c1 fa 1f             	sar    $0x1f,%edx
40002ec6:	eb 1c                	jmp    40002ee4 <getint+0x73>
	else
		return va_arg(*ap, int);
40002ec8:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ecb:	8b 00                	mov    (%eax),%eax
40002ecd:	8d 50 04             	lea    0x4(%eax),%edx
40002ed0:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ed3:	89 10                	mov    %edx,(%eax)
40002ed5:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ed8:	8b 00                	mov    (%eax),%eax
40002eda:	83 e8 04             	sub    $0x4,%eax
40002edd:	8b 00                	mov    (%eax),%eax
40002edf:	89 c2                	mov    %eax,%edx
40002ee1:	c1 fa 1f             	sar    $0x1f,%edx
}
40002ee4:	5d                   	pop    %ebp
40002ee5:	c3                   	ret    

40002ee6 <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
40002ee6:	55                   	push   %ebp
40002ee7:	89 e5                	mov    %esp,%ebp
40002ee9:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
40002eec:	eb 1a                	jmp    40002f08 <putpad+0x22>
		st->putch(st->padc, st->putdat);
40002eee:	8b 45 08             	mov    0x8(%ebp),%eax
40002ef1:	8b 00                	mov    (%eax),%eax
40002ef3:	8b 55 08             	mov    0x8(%ebp),%edx
40002ef6:	8b 4a 04             	mov    0x4(%edx),%ecx
40002ef9:	8b 55 08             	mov    0x8(%ebp),%edx
40002efc:	8b 52 08             	mov    0x8(%edx),%edx
40002eff:	89 4c 24 04          	mov    %ecx,0x4(%esp)
40002f03:	89 14 24             	mov    %edx,(%esp)
40002f06:	ff d0                	call   *%eax

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
40002f08:	8b 45 08             	mov    0x8(%ebp),%eax
40002f0b:	8b 40 0c             	mov    0xc(%eax),%eax
40002f0e:	8d 50 ff             	lea    -0x1(%eax),%edx
40002f11:	8b 45 08             	mov    0x8(%ebp),%eax
40002f14:	89 50 0c             	mov    %edx,0xc(%eax)
40002f17:	8b 45 08             	mov    0x8(%ebp),%eax
40002f1a:	8b 40 0c             	mov    0xc(%eax),%eax
40002f1d:	85 c0                	test   %eax,%eax
40002f1f:	79 cd                	jns    40002eee <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
40002f21:	c9                   	leave  
40002f22:	c3                   	ret    

40002f23 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
40002f23:	55                   	push   %ebp
40002f24:	89 e5                	mov    %esp,%ebp
40002f26:	53                   	push   %ebx
40002f27:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
40002f2a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40002f2e:	79 18                	jns    40002f48 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
40002f30:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002f37:	00 
40002f38:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f3b:	89 04 24             	mov    %eax,(%esp)
40002f3e:	e8 f6 06 00 00       	call   40003639 <strchr>
40002f43:	89 45 f4             	mov    %eax,-0xc(%ebp)
40002f46:	eb 2e                	jmp    40002f76 <putstr+0x53>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
40002f48:	8b 45 10             	mov    0x10(%ebp),%eax
40002f4b:	89 44 24 08          	mov    %eax,0x8(%esp)
40002f4f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002f56:	00 
40002f57:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f5a:	89 04 24             	mov    %eax,(%esp)
40002f5d:	e8 d4 08 00 00       	call   40003836 <memchr>
40002f62:	89 45 f4             	mov    %eax,-0xc(%ebp)
40002f65:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002f69:	75 0b                	jne    40002f76 <putstr+0x53>
		lim = str + maxlen;
40002f6b:	8b 55 10             	mov    0x10(%ebp),%edx
40002f6e:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f71:	01 d0                	add    %edx,%eax
40002f73:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
40002f76:	8b 45 08             	mov    0x8(%ebp),%eax
40002f79:	8b 40 0c             	mov    0xc(%eax),%eax
40002f7c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40002f7f:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002f82:	89 cb                	mov    %ecx,%ebx
40002f84:	29 d3                	sub    %edx,%ebx
40002f86:	89 da                	mov    %ebx,%edx
40002f88:	01 c2                	add    %eax,%edx
40002f8a:	8b 45 08             	mov    0x8(%ebp),%eax
40002f8d:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
40002f90:	8b 45 08             	mov    0x8(%ebp),%eax
40002f93:	8b 40 18             	mov    0x18(%eax),%eax
40002f96:	83 e0 10             	and    $0x10,%eax
40002f99:	85 c0                	test   %eax,%eax
40002f9b:	75 32                	jne    40002fcf <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
40002f9d:	8b 45 08             	mov    0x8(%ebp),%eax
40002fa0:	89 04 24             	mov    %eax,(%esp)
40002fa3:	e8 3e ff ff ff       	call   40002ee6 <putpad>
	while (str < lim) {
40002fa8:	eb 25                	jmp    40002fcf <putstr+0xac>
		char ch = *str++;
40002faa:	8b 45 0c             	mov    0xc(%ebp),%eax
40002fad:	0f b6 00             	movzbl (%eax),%eax
40002fb0:	88 45 f3             	mov    %al,-0xd(%ebp)
40002fb3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
40002fb7:	8b 45 08             	mov    0x8(%ebp),%eax
40002fba:	8b 00                	mov    (%eax),%eax
40002fbc:	8b 55 08             	mov    0x8(%ebp),%edx
40002fbf:	8b 4a 04             	mov    0x4(%edx),%ecx
40002fc2:	0f be 55 f3          	movsbl -0xd(%ebp),%edx
40002fc6:	89 4c 24 04          	mov    %ecx,0x4(%esp)
40002fca:	89 14 24             	mov    %edx,(%esp)
40002fcd:	ff d0                	call   *%eax
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
40002fcf:	8b 45 0c             	mov    0xc(%ebp),%eax
40002fd2:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40002fd5:	72 d3                	jb     40002faa <putstr+0x87>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
40002fd7:	8b 45 08             	mov    0x8(%ebp),%eax
40002fda:	89 04 24             	mov    %eax,(%esp)
40002fdd:	e8 04 ff ff ff       	call   40002ee6 <putpad>
}
40002fe2:	83 c4 24             	add    $0x24,%esp
40002fe5:	5b                   	pop    %ebx
40002fe6:	5d                   	pop    %ebp
40002fe7:	c3                   	ret    

40002fe8 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
40002fe8:	55                   	push   %ebp
40002fe9:	89 e5                	mov    %esp,%ebp
40002feb:	53                   	push   %ebx
40002fec:	83 ec 24             	sub    $0x24,%esp
40002fef:	8b 45 10             	mov    0x10(%ebp),%eax
40002ff2:	89 45 f0             	mov    %eax,-0x10(%ebp)
40002ff5:	8b 45 14             	mov    0x14(%ebp),%eax
40002ff8:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
40002ffb:	8b 45 08             	mov    0x8(%ebp),%eax
40002ffe:	8b 40 1c             	mov    0x1c(%eax),%eax
40003001:	89 c2                	mov    %eax,%edx
40003003:	c1 fa 1f             	sar    $0x1f,%edx
40003006:	3b 55 f4             	cmp    -0xc(%ebp),%edx
40003009:	77 4e                	ja     40003059 <genint+0x71>
4000300b:	3b 55 f4             	cmp    -0xc(%ebp),%edx
4000300e:	72 05                	jb     40003015 <genint+0x2d>
40003010:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40003013:	77 44                	ja     40003059 <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
40003015:	8b 45 08             	mov    0x8(%ebp),%eax
40003018:	8b 40 1c             	mov    0x1c(%eax),%eax
4000301b:	89 c2                	mov    %eax,%edx
4000301d:	c1 fa 1f             	sar    $0x1f,%edx
40003020:	89 44 24 08          	mov    %eax,0x8(%esp)
40003024:	89 54 24 0c          	mov    %edx,0xc(%esp)
40003028:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000302b:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000302e:	89 04 24             	mov    %eax,(%esp)
40003031:	89 54 24 04          	mov    %edx,0x4(%esp)
40003035:	e8 96 21 00 00       	call   400051d0 <__udivdi3>
4000303a:	89 44 24 08          	mov    %eax,0x8(%esp)
4000303e:	89 54 24 0c          	mov    %edx,0xc(%esp)
40003042:	8b 45 0c             	mov    0xc(%ebp),%eax
40003045:	89 44 24 04          	mov    %eax,0x4(%esp)
40003049:	8b 45 08             	mov    0x8(%ebp),%eax
4000304c:	89 04 24             	mov    %eax,(%esp)
4000304f:	e8 94 ff ff ff       	call   40002fe8 <genint>
40003054:	89 45 0c             	mov    %eax,0xc(%ebp)
40003057:	eb 1b                	jmp    40003074 <genint+0x8c>
	else if (st->signc >= 0)
40003059:	8b 45 08             	mov    0x8(%ebp),%eax
4000305c:	8b 40 14             	mov    0x14(%eax),%eax
4000305f:	85 c0                	test   %eax,%eax
40003061:	78 11                	js     40003074 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
40003063:	8b 45 08             	mov    0x8(%ebp),%eax
40003066:	8b 40 14             	mov    0x14(%eax),%eax
40003069:	89 c2                	mov    %eax,%edx
4000306b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000306e:	88 10                	mov    %dl,(%eax)
40003070:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
40003074:	8b 45 08             	mov    0x8(%ebp),%eax
40003077:	8b 40 1c             	mov    0x1c(%eax),%eax
4000307a:	89 c1                	mov    %eax,%ecx
4000307c:	89 c3                	mov    %eax,%ebx
4000307e:	c1 fb 1f             	sar    $0x1f,%ebx
40003081:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003084:	8b 55 f4             	mov    -0xc(%ebp),%edx
40003087:	89 4c 24 08          	mov    %ecx,0x8(%esp)
4000308b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
4000308f:	89 04 24             	mov    %eax,(%esp)
40003092:	89 54 24 04          	mov    %edx,0x4(%esp)
40003096:	e8 85 22 00 00       	call   40005320 <__umoddi3>
4000309b:	05 fc 5a 00 40       	add    $0x40005afc,%eax
400030a0:	0f b6 10             	movzbl (%eax),%edx
400030a3:	8b 45 0c             	mov    0xc(%ebp),%eax
400030a6:	88 10                	mov    %dl,(%eax)
400030a8:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
400030ac:	8b 45 0c             	mov    0xc(%ebp),%eax
}
400030af:	83 c4 24             	add    $0x24,%esp
400030b2:	5b                   	pop    %ebx
400030b3:	5d                   	pop    %ebp
400030b4:	c3                   	ret    

400030b5 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
400030b5:	55                   	push   %ebp
400030b6:	89 e5                	mov    %esp,%ebp
400030b8:	83 ec 58             	sub    $0x58,%esp
400030bb:	8b 45 0c             	mov    0xc(%ebp),%eax
400030be:	89 45 c0             	mov    %eax,-0x40(%ebp)
400030c1:	8b 45 10             	mov    0x10(%ebp),%eax
400030c4:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
400030c7:	8d 45 d6             	lea    -0x2a(%ebp),%eax
400030ca:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
400030cd:	8b 45 08             	mov    0x8(%ebp),%eax
400030d0:	8b 55 14             	mov    0x14(%ebp),%edx
400030d3:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
400030d6:	8b 45 c0             	mov    -0x40(%ebp),%eax
400030d9:	8b 55 c4             	mov    -0x3c(%ebp),%edx
400030dc:	89 44 24 08          	mov    %eax,0x8(%esp)
400030e0:	89 54 24 0c          	mov    %edx,0xc(%esp)
400030e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
400030e7:	89 44 24 04          	mov    %eax,0x4(%esp)
400030eb:	8b 45 08             	mov    0x8(%ebp),%eax
400030ee:	89 04 24             	mov    %eax,(%esp)
400030f1:	e8 f2 fe ff ff       	call   40002fe8 <genint>
400030f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
400030f9:	8b 55 f4             	mov    -0xc(%ebp),%edx
400030fc:	8d 45 d6             	lea    -0x2a(%ebp),%eax
400030ff:	89 d1                	mov    %edx,%ecx
40003101:	29 c1                	sub    %eax,%ecx
40003103:	89 c8                	mov    %ecx,%eax
40003105:	89 44 24 08          	mov    %eax,0x8(%esp)
40003109:	8d 45 d6             	lea    -0x2a(%ebp),%eax
4000310c:	89 44 24 04          	mov    %eax,0x4(%esp)
40003110:	8b 45 08             	mov    0x8(%ebp),%eax
40003113:	89 04 24             	mov    %eax,(%esp)
40003116:	e8 08 fe ff ff       	call   40002f23 <putstr>
}
4000311b:	c9                   	leave  
4000311c:	c3                   	ret    

4000311d <vprintfmt>:


// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
4000311d:	55                   	push   %ebp
4000311e:	89 e5                	mov    %esp,%ebp
40003120:	53                   	push   %ebx
40003121:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
40003124:	8d 55 cc             	lea    -0x34(%ebp),%edx
40003127:	b9 00 00 00 00       	mov    $0x0,%ecx
4000312c:	b8 20 00 00 00       	mov    $0x20,%eax
40003131:	89 c3                	mov    %eax,%ebx
40003133:	83 e3 fc             	and    $0xfffffffc,%ebx
40003136:	b8 00 00 00 00       	mov    $0x0,%eax
4000313b:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
4000313e:	83 c0 04             	add    $0x4,%eax
40003141:	39 d8                	cmp    %ebx,%eax
40003143:	72 f6                	jb     4000313b <vprintfmt+0x1e>
40003145:	01 c2                	add    %eax,%edx
40003147:	8b 45 08             	mov    0x8(%ebp),%eax
4000314a:	89 45 cc             	mov    %eax,-0x34(%ebp)
4000314d:	8b 45 0c             	mov    0xc(%ebp),%eax
40003150:	89 45 d0             	mov    %eax,-0x30(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40003153:	eb 17                	jmp    4000316c <vprintfmt+0x4f>
			if (ch == '\0')
40003155:	85 db                	test   %ebx,%ebx
40003157:	0f 84 50 03 00 00    	je     400034ad <vprintfmt+0x390>
				return;
			putch(ch, putdat);
4000315d:	8b 45 0c             	mov    0xc(%ebp),%eax
40003160:	89 44 24 04          	mov    %eax,0x4(%esp)
40003164:	89 1c 24             	mov    %ebx,(%esp)
40003167:	8b 45 08             	mov    0x8(%ebp),%eax
4000316a:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
4000316c:	8b 45 10             	mov    0x10(%ebp),%eax
4000316f:	0f b6 00             	movzbl (%eax),%eax
40003172:	0f b6 d8             	movzbl %al,%ebx
40003175:	83 fb 25             	cmp    $0x25,%ebx
40003178:	0f 95 c0             	setne  %al
4000317b:	83 45 10 01          	addl   $0x1,0x10(%ebp)
4000317f:	84 c0                	test   %al,%al
40003181:	75 d2                	jne    40003155 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
40003183:	c7 45 d4 20 00 00 00 	movl   $0x20,-0x2c(%ebp)
		st.width = -1;
4000318a:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.prec = -1;
40003191:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.signc = -1;
40003198:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		st.flags = 0;
4000319f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		st.base = 10;
400031a6:	c7 45 e8 0a 00 00 00 	movl   $0xa,-0x18(%ebp)
400031ad:	eb 04                	jmp    400031b3 <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
400031af:	90                   	nop
400031b0:	eb 01                	jmp    400031b3 <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
400031b2:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
400031b3:	8b 45 10             	mov    0x10(%ebp),%eax
400031b6:	0f b6 00             	movzbl (%eax),%eax
400031b9:	0f b6 d8             	movzbl %al,%ebx
400031bc:	89 d8                	mov    %ebx,%eax
400031be:	83 45 10 01          	addl   $0x1,0x10(%ebp)
400031c2:	83 e8 20             	sub    $0x20,%eax
400031c5:	83 f8 58             	cmp    $0x58,%eax
400031c8:	0f 87 ae 02 00 00    	ja     4000347c <vprintfmt+0x35f>
400031ce:	8b 04 85 14 5b 00 40 	mov    0x40005b14(,%eax,4),%eax
400031d5:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
400031d7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400031da:	83 c8 10             	or     $0x10,%eax
400031dd:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
400031e0:	eb d1                	jmp    400031b3 <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
400031e2:	c7 45 e0 2b 00 00 00 	movl   $0x2b,-0x20(%ebp)
			goto reswitch;
400031e9:	eb c8                	jmp    400031b3 <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
400031eb:	8b 45 e0             	mov    -0x20(%ebp),%eax
400031ee:	85 c0                	test   %eax,%eax
400031f0:	79 bd                	jns    400031af <vprintfmt+0x92>
				st.signc = ' ';
400031f2:	c7 45 e0 20 00 00 00 	movl   $0x20,-0x20(%ebp)
			goto reswitch;
400031f9:	eb b4                	jmp    400031af <vprintfmt+0x92>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
400031fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400031fe:	83 e0 08             	and    $0x8,%eax
40003201:	85 c0                	test   %eax,%eax
40003203:	75 07                	jne    4000320c <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
40003205:	c7 45 d4 30 00 00 00 	movl   $0x30,-0x2c(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
4000320c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
				st.prec = st.prec * 10 + ch - '0';
40003213:	8b 55 dc             	mov    -0x24(%ebp),%edx
40003216:	89 d0                	mov    %edx,%eax
40003218:	c1 e0 02             	shl    $0x2,%eax
4000321b:	01 d0                	add    %edx,%eax
4000321d:	01 c0                	add    %eax,%eax
4000321f:	01 d8                	add    %ebx,%eax
40003221:	83 e8 30             	sub    $0x30,%eax
40003224:	89 45 dc             	mov    %eax,-0x24(%ebp)
				ch = *fmt;
40003227:	8b 45 10             	mov    0x10(%ebp),%eax
4000322a:	0f b6 00             	movzbl (%eax),%eax
4000322d:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
40003230:	83 fb 2f             	cmp    $0x2f,%ebx
40003233:	7e 21                	jle    40003256 <vprintfmt+0x139>
40003235:	83 fb 39             	cmp    $0x39,%ebx
40003238:	7f 1c                	jg     40003256 <vprintfmt+0x139>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
4000323a:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
4000323e:	eb d3                	jmp    40003213 <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
40003240:	8b 45 14             	mov    0x14(%ebp),%eax
40003243:	83 c0 04             	add    $0x4,%eax
40003246:	89 45 14             	mov    %eax,0x14(%ebp)
40003249:	8b 45 14             	mov    0x14(%ebp),%eax
4000324c:	83 e8 04             	sub    $0x4,%eax
4000324f:	8b 00                	mov    (%eax),%eax
40003251:	89 45 dc             	mov    %eax,-0x24(%ebp)
40003254:	eb 01                	jmp    40003257 <vprintfmt+0x13a>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
40003256:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
40003257:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000325a:	83 e0 08             	and    $0x8,%eax
4000325d:	85 c0                	test   %eax,%eax
4000325f:	0f 85 4d ff ff ff    	jne    400031b2 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
40003265:	8b 45 dc             	mov    -0x24(%ebp),%eax
40003268:	89 45 d8             	mov    %eax,-0x28(%ebp)
				st.prec = -1;
4000326b:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
			}
			goto reswitch;
40003272:	e9 3b ff ff ff       	jmp    400031b2 <vprintfmt+0x95>

		case '.':
			st.flags |= F_DOT;
40003277:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000327a:	83 c8 08             	or     $0x8,%eax
4000327d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
40003280:	e9 2e ff ff ff       	jmp    400031b3 <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
40003285:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40003288:	83 c8 04             	or     $0x4,%eax
4000328b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
4000328e:	e9 20 ff ff ff       	jmp    400031b3 <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
40003293:	8b 55 e4             	mov    -0x1c(%ebp),%edx
40003296:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40003299:	83 e0 01             	and    $0x1,%eax
4000329c:	85 c0                	test   %eax,%eax
4000329e:	74 07                	je     400032a7 <vprintfmt+0x18a>
400032a0:	b8 02 00 00 00       	mov    $0x2,%eax
400032a5:	eb 05                	jmp    400032ac <vprintfmt+0x18f>
400032a7:	b8 01 00 00 00       	mov    $0x1,%eax
400032ac:	09 d0                	or     %edx,%eax
400032ae:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
400032b1:	e9 fd fe ff ff       	jmp    400031b3 <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
400032b6:	8b 45 14             	mov    0x14(%ebp),%eax
400032b9:	83 c0 04             	add    $0x4,%eax
400032bc:	89 45 14             	mov    %eax,0x14(%ebp)
400032bf:	8b 45 14             	mov    0x14(%ebp),%eax
400032c2:	83 e8 04             	sub    $0x4,%eax
400032c5:	8b 00                	mov    (%eax),%eax
400032c7:	8b 55 0c             	mov    0xc(%ebp),%edx
400032ca:	89 54 24 04          	mov    %edx,0x4(%esp)
400032ce:	89 04 24             	mov    %eax,(%esp)
400032d1:	8b 45 08             	mov    0x8(%ebp),%eax
400032d4:	ff d0                	call   *%eax
			break;
400032d6:	e9 cc 01 00 00       	jmp    400034a7 <vprintfmt+0x38a>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
400032db:	8b 45 14             	mov    0x14(%ebp),%eax
400032de:	83 c0 04             	add    $0x4,%eax
400032e1:	89 45 14             	mov    %eax,0x14(%ebp)
400032e4:	8b 45 14             	mov    0x14(%ebp),%eax
400032e7:	83 e8 04             	sub    $0x4,%eax
400032ea:	8b 00                	mov    (%eax),%eax
400032ec:	89 45 ec             	mov    %eax,-0x14(%ebp)
400032ef:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
400032f3:	75 07                	jne    400032fc <vprintfmt+0x1df>
				s = "(null)";
400032f5:	c7 45 ec 0d 5b 00 40 	movl   $0x40005b0d,-0x14(%ebp)
			putstr(&st, s, st.prec);
400032fc:	8b 45 dc             	mov    -0x24(%ebp),%eax
400032ff:	89 44 24 08          	mov    %eax,0x8(%esp)
40003303:	8b 45 ec             	mov    -0x14(%ebp),%eax
40003306:	89 44 24 04          	mov    %eax,0x4(%esp)
4000330a:	8d 45 cc             	lea    -0x34(%ebp),%eax
4000330d:	89 04 24             	mov    %eax,(%esp)
40003310:	e8 0e fc ff ff       	call   40002f23 <putstr>
			break;
40003315:	e9 8d 01 00 00       	jmp    400034a7 <vprintfmt+0x38a>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
4000331a:	8d 45 14             	lea    0x14(%ebp),%eax
4000331d:	89 44 24 04          	mov    %eax,0x4(%esp)
40003321:	8d 45 cc             	lea    -0x34(%ebp),%eax
40003324:	89 04 24             	mov    %eax,(%esp)
40003327:	e8 45 fb ff ff       	call   40002e71 <getint>
4000332c:	89 45 f0             	mov    %eax,-0x10(%ebp)
4000332f:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((intmax_t) num < 0) {
40003332:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003335:	8b 55 f4             	mov    -0xc(%ebp),%edx
40003338:	85 d2                	test   %edx,%edx
4000333a:	79 1a                	jns    40003356 <vprintfmt+0x239>
				num = -(intmax_t) num;
4000333c:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000333f:	8b 55 f4             	mov    -0xc(%ebp),%edx
40003342:	f7 d8                	neg    %eax
40003344:	83 d2 00             	adc    $0x0,%edx
40003347:	f7 da                	neg    %edx
40003349:	89 45 f0             	mov    %eax,-0x10(%ebp)
4000334c:	89 55 f4             	mov    %edx,-0xc(%ebp)
				st.signc = '-';
4000334f:	c7 45 e0 2d 00 00 00 	movl   $0x2d,-0x20(%ebp)
			}
			putint(&st, num, 10);
40003356:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
4000335d:	00 
4000335e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003361:	8b 55 f4             	mov    -0xc(%ebp),%edx
40003364:	89 44 24 04          	mov    %eax,0x4(%esp)
40003368:	89 54 24 08          	mov    %edx,0x8(%esp)
4000336c:	8d 45 cc             	lea    -0x34(%ebp),%eax
4000336f:	89 04 24             	mov    %eax,(%esp)
40003372:	e8 3e fd ff ff       	call   400030b5 <putint>
			break;
40003377:	e9 2b 01 00 00       	jmp    400034a7 <vprintfmt+0x38a>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
4000337c:	8d 45 14             	lea    0x14(%ebp),%eax
4000337f:	89 44 24 04          	mov    %eax,0x4(%esp)
40003383:	8d 45 cc             	lea    -0x34(%ebp),%eax
40003386:	89 04 24             	mov    %eax,(%esp)
40003389:	e8 6e fa ff ff       	call   40002dfc <getuint>
4000338e:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
40003395:	00 
40003396:	89 44 24 04          	mov    %eax,0x4(%esp)
4000339a:	89 54 24 08          	mov    %edx,0x8(%esp)
4000339e:	8d 45 cc             	lea    -0x34(%ebp),%eax
400033a1:	89 04 24             	mov    %eax,(%esp)
400033a4:	e8 0c fd ff ff       	call   400030b5 <putint>
			break;
400033a9:	e9 f9 00 00 00       	jmp    400034a7 <vprintfmt+0x38a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
400033ae:	8d 45 14             	lea    0x14(%ebp),%eax
400033b1:	89 44 24 04          	mov    %eax,0x4(%esp)
400033b5:	8d 45 cc             	lea    -0x34(%ebp),%eax
400033b8:	89 04 24             	mov    %eax,(%esp)
400033bb:	e8 3c fa ff ff       	call   40002dfc <getuint>
400033c0:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
400033c7:	00 
400033c8:	89 44 24 04          	mov    %eax,0x4(%esp)
400033cc:	89 54 24 08          	mov    %edx,0x8(%esp)
400033d0:	8d 45 cc             	lea    -0x34(%ebp),%eax
400033d3:	89 04 24             	mov    %eax,(%esp)
400033d6:	e8 da fc ff ff       	call   400030b5 <putint>
			break;
400033db:	e9 c7 00 00 00       	jmp    400034a7 <vprintfmt+0x38a>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
400033e0:	8d 45 14             	lea    0x14(%ebp),%eax
400033e3:	89 44 24 04          	mov    %eax,0x4(%esp)
400033e7:	8d 45 cc             	lea    -0x34(%ebp),%eax
400033ea:	89 04 24             	mov    %eax,(%esp)
400033ed:	e8 0a fa ff ff       	call   40002dfc <getuint>
400033f2:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
400033f9:	00 
400033fa:	89 44 24 04          	mov    %eax,0x4(%esp)
400033fe:	89 54 24 08          	mov    %edx,0x8(%esp)
40003402:	8d 45 cc             	lea    -0x34(%ebp),%eax
40003405:	89 04 24             	mov    %eax,(%esp)
40003408:	e8 a8 fc ff ff       	call   400030b5 <putint>
			break;
4000340d:	e9 95 00 00 00       	jmp    400034a7 <vprintfmt+0x38a>

		// pointer
		case 'p':
			putch('0', putdat);
40003412:	8b 45 0c             	mov    0xc(%ebp),%eax
40003415:	89 44 24 04          	mov    %eax,0x4(%esp)
40003419:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
40003420:	8b 45 08             	mov    0x8(%ebp),%eax
40003423:	ff d0                	call   *%eax
			putch('x', putdat);
40003425:	8b 45 0c             	mov    0xc(%ebp),%eax
40003428:	89 44 24 04          	mov    %eax,0x4(%esp)
4000342c:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
40003433:	8b 45 08             	mov    0x8(%ebp),%eax
40003436:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
40003438:	8b 45 14             	mov    0x14(%ebp),%eax
4000343b:	83 c0 04             	add    $0x4,%eax
4000343e:	89 45 14             	mov    %eax,0x14(%ebp)
40003441:	8b 45 14             	mov    0x14(%ebp),%eax
40003444:	83 e8 04             	sub    $0x4,%eax
40003447:	8b 00                	mov    (%eax),%eax
40003449:	ba 00 00 00 00       	mov    $0x0,%edx
4000344e:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
40003455:	00 
40003456:	89 44 24 04          	mov    %eax,0x4(%esp)
4000345a:	89 54 24 08          	mov    %edx,0x8(%esp)
4000345e:	8d 45 cc             	lea    -0x34(%ebp),%eax
40003461:	89 04 24             	mov    %eax,(%esp)
40003464:	e8 4c fc ff ff       	call   400030b5 <putint>
			break;
40003469:	eb 3c                	jmp    400034a7 <vprintfmt+0x38a>


		// escaped '%' character
		case '%':
			putch(ch, putdat);
4000346b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000346e:	89 44 24 04          	mov    %eax,0x4(%esp)
40003472:	89 1c 24             	mov    %ebx,(%esp)
40003475:	8b 45 08             	mov    0x8(%ebp),%eax
40003478:	ff d0                	call   *%eax
			break;
4000347a:	eb 2b                	jmp    400034a7 <vprintfmt+0x38a>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
4000347c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000347f:	89 44 24 04          	mov    %eax,0x4(%esp)
40003483:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
4000348a:	8b 45 08             	mov    0x8(%ebp),%eax
4000348d:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
4000348f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40003493:	eb 04                	jmp    40003499 <vprintfmt+0x37c>
40003495:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40003499:	8b 45 10             	mov    0x10(%ebp),%eax
4000349c:	83 e8 01             	sub    $0x1,%eax
4000349f:	0f b6 00             	movzbl (%eax),%eax
400034a2:	3c 25                	cmp    $0x25,%al
400034a4:	75 ef                	jne    40003495 <vprintfmt+0x378>
				/* do nothing */;
			break;
400034a6:	90                   	nop
		}
	}
400034a7:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
400034a8:	e9 bf fc ff ff       	jmp    4000316c <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
400034ad:	83 c4 44             	add    $0x44,%esp
400034b0:	5b                   	pop    %ebx
400034b1:	5d                   	pop    %ebp
400034b2:	c3                   	ret    
400034b3:	90                   	nop

400034b4 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
400034b4:	55                   	push   %ebp
400034b5:	89 e5                	mov    %esp,%ebp
400034b7:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
400034ba:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
400034c1:	eb 08                	jmp    400034cb <strlen+0x17>
		n++;
400034c3:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
400034c7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400034cb:	8b 45 08             	mov    0x8(%ebp),%eax
400034ce:	0f b6 00             	movzbl (%eax),%eax
400034d1:	84 c0                	test   %al,%al
400034d3:	75 ee                	jne    400034c3 <strlen+0xf>
		n++;
	return n;
400034d5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
400034d8:	c9                   	leave  
400034d9:	c3                   	ret    

400034da <strcpy>:

char *
strcpy(char *dst, const char *src)
{
400034da:	55                   	push   %ebp
400034db:	89 e5                	mov    %esp,%ebp
400034dd:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
400034e0:	8b 45 08             	mov    0x8(%ebp),%eax
400034e3:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
400034e6:	90                   	nop
400034e7:	8b 45 0c             	mov    0xc(%ebp),%eax
400034ea:	0f b6 10             	movzbl (%eax),%edx
400034ed:	8b 45 08             	mov    0x8(%ebp),%eax
400034f0:	88 10                	mov    %dl,(%eax)
400034f2:	8b 45 08             	mov    0x8(%ebp),%eax
400034f5:	0f b6 00             	movzbl (%eax),%eax
400034f8:	84 c0                	test   %al,%al
400034fa:	0f 95 c0             	setne  %al
400034fd:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003501:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
40003505:	84 c0                	test   %al,%al
40003507:	75 de                	jne    400034e7 <strcpy+0xd>
		/* do nothing */;
	return ret;
40003509:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
4000350c:	c9                   	leave  
4000350d:	c3                   	ret    

4000350e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
4000350e:	55                   	push   %ebp
4000350f:	89 e5                	mov    %esp,%ebp
40003511:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
40003514:	8b 45 08             	mov    0x8(%ebp),%eax
40003517:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
4000351a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
40003521:	eb 21                	jmp    40003544 <strncpy+0x36>
		*dst++ = *src;
40003523:	8b 45 0c             	mov    0xc(%ebp),%eax
40003526:	0f b6 10             	movzbl (%eax),%edx
40003529:	8b 45 08             	mov    0x8(%ebp),%eax
4000352c:	88 10                	mov    %dl,(%eax)
4000352e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
40003532:	8b 45 0c             	mov    0xc(%ebp),%eax
40003535:	0f b6 00             	movzbl (%eax),%eax
40003538:	84 c0                	test   %al,%al
4000353a:	74 04                	je     40003540 <strncpy+0x32>
			src++;
4000353c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
40003540:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40003544:	8b 45 fc             	mov    -0x4(%ebp),%eax
40003547:	3b 45 10             	cmp    0x10(%ebp),%eax
4000354a:	72 d7                	jb     40003523 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
4000354c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
4000354f:	c9                   	leave  
40003550:	c3                   	ret    

40003551 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
40003551:	55                   	push   %ebp
40003552:	89 e5                	mov    %esp,%ebp
40003554:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
40003557:	8b 45 08             	mov    0x8(%ebp),%eax
4000355a:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
4000355d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003561:	74 2f                	je     40003592 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
40003563:	eb 13                	jmp    40003578 <strlcpy+0x27>
			*dst++ = *src++;
40003565:	8b 45 0c             	mov    0xc(%ebp),%eax
40003568:	0f b6 10             	movzbl (%eax),%edx
4000356b:	8b 45 08             	mov    0x8(%ebp),%eax
4000356e:	88 10                	mov    %dl,(%eax)
40003570:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003574:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
40003578:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
4000357c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003580:	74 0a                	je     4000358c <strlcpy+0x3b>
40003582:	8b 45 0c             	mov    0xc(%ebp),%eax
40003585:	0f b6 00             	movzbl (%eax),%eax
40003588:	84 c0                	test   %al,%al
4000358a:	75 d9                	jne    40003565 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
4000358c:	8b 45 08             	mov    0x8(%ebp),%eax
4000358f:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
40003592:	8b 55 08             	mov    0x8(%ebp),%edx
40003595:	8b 45 fc             	mov    -0x4(%ebp),%eax
40003598:	89 d1                	mov    %edx,%ecx
4000359a:	29 c1                	sub    %eax,%ecx
4000359c:	89 c8                	mov    %ecx,%eax
}
4000359e:	c9                   	leave  
4000359f:	c3                   	ret    

400035a0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
400035a0:	55                   	push   %ebp
400035a1:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
400035a3:	eb 08                	jmp    400035ad <strcmp+0xd>
		p++, q++;
400035a5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400035a9:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
400035ad:	8b 45 08             	mov    0x8(%ebp),%eax
400035b0:	0f b6 00             	movzbl (%eax),%eax
400035b3:	84 c0                	test   %al,%al
400035b5:	74 10                	je     400035c7 <strcmp+0x27>
400035b7:	8b 45 08             	mov    0x8(%ebp),%eax
400035ba:	0f b6 10             	movzbl (%eax),%edx
400035bd:	8b 45 0c             	mov    0xc(%ebp),%eax
400035c0:	0f b6 00             	movzbl (%eax),%eax
400035c3:	38 c2                	cmp    %al,%dl
400035c5:	74 de                	je     400035a5 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
400035c7:	8b 45 08             	mov    0x8(%ebp),%eax
400035ca:	0f b6 00             	movzbl (%eax),%eax
400035cd:	0f b6 d0             	movzbl %al,%edx
400035d0:	8b 45 0c             	mov    0xc(%ebp),%eax
400035d3:	0f b6 00             	movzbl (%eax),%eax
400035d6:	0f b6 c0             	movzbl %al,%eax
400035d9:	89 d1                	mov    %edx,%ecx
400035db:	29 c1                	sub    %eax,%ecx
400035dd:	89 c8                	mov    %ecx,%eax
}
400035df:	5d                   	pop    %ebp
400035e0:	c3                   	ret    

400035e1 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
400035e1:	55                   	push   %ebp
400035e2:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
400035e4:	eb 0c                	jmp    400035f2 <strncmp+0x11>
		n--, p++, q++;
400035e6:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
400035ea:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400035ee:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
400035f2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400035f6:	74 1a                	je     40003612 <strncmp+0x31>
400035f8:	8b 45 08             	mov    0x8(%ebp),%eax
400035fb:	0f b6 00             	movzbl (%eax),%eax
400035fe:	84 c0                	test   %al,%al
40003600:	74 10                	je     40003612 <strncmp+0x31>
40003602:	8b 45 08             	mov    0x8(%ebp),%eax
40003605:	0f b6 10             	movzbl (%eax),%edx
40003608:	8b 45 0c             	mov    0xc(%ebp),%eax
4000360b:	0f b6 00             	movzbl (%eax),%eax
4000360e:	38 c2                	cmp    %al,%dl
40003610:	74 d4                	je     400035e6 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
40003612:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003616:	75 07                	jne    4000361f <strncmp+0x3e>
		return 0;
40003618:	b8 00 00 00 00       	mov    $0x0,%eax
4000361d:	eb 18                	jmp    40003637 <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
4000361f:	8b 45 08             	mov    0x8(%ebp),%eax
40003622:	0f b6 00             	movzbl (%eax),%eax
40003625:	0f b6 d0             	movzbl %al,%edx
40003628:	8b 45 0c             	mov    0xc(%ebp),%eax
4000362b:	0f b6 00             	movzbl (%eax),%eax
4000362e:	0f b6 c0             	movzbl %al,%eax
40003631:	89 d1                	mov    %edx,%ecx
40003633:	29 c1                	sub    %eax,%ecx
40003635:	89 c8                	mov    %ecx,%eax
}
40003637:	5d                   	pop    %ebp
40003638:	c3                   	ret    

40003639 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
40003639:	55                   	push   %ebp
4000363a:	89 e5                	mov    %esp,%ebp
4000363c:	83 ec 04             	sub    $0x4,%esp
4000363f:	8b 45 0c             	mov    0xc(%ebp),%eax
40003642:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
40003645:	eb 1a                	jmp    40003661 <strchr+0x28>
		if (*s++ == 0)
40003647:	8b 45 08             	mov    0x8(%ebp),%eax
4000364a:	0f b6 00             	movzbl (%eax),%eax
4000364d:	84 c0                	test   %al,%al
4000364f:	0f 94 c0             	sete   %al
40003652:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003656:	84 c0                	test   %al,%al
40003658:	74 07                	je     40003661 <strchr+0x28>
			return NULL;
4000365a:	b8 00 00 00 00       	mov    $0x0,%eax
4000365f:	eb 0e                	jmp    4000366f <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
40003661:	8b 45 08             	mov    0x8(%ebp),%eax
40003664:	0f b6 00             	movzbl (%eax),%eax
40003667:	3a 45 fc             	cmp    -0x4(%ebp),%al
4000366a:	75 db                	jne    40003647 <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
4000366c:	8b 45 08             	mov    0x8(%ebp),%eax
}
4000366f:	c9                   	leave  
40003670:	c3                   	ret    

40003671 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
40003671:	55                   	push   %ebp
40003672:	89 e5                	mov    %esp,%ebp
40003674:	57                   	push   %edi
	char *p;

	if (n == 0)
40003675:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003679:	75 05                	jne    40003680 <memset+0xf>
		return v;
4000367b:	8b 45 08             	mov    0x8(%ebp),%eax
4000367e:	eb 5c                	jmp    400036dc <memset+0x6b>
	if ((int)v%4 == 0 && n%4 == 0) {
40003680:	8b 45 08             	mov    0x8(%ebp),%eax
40003683:	83 e0 03             	and    $0x3,%eax
40003686:	85 c0                	test   %eax,%eax
40003688:	75 41                	jne    400036cb <memset+0x5a>
4000368a:	8b 45 10             	mov    0x10(%ebp),%eax
4000368d:	83 e0 03             	and    $0x3,%eax
40003690:	85 c0                	test   %eax,%eax
40003692:	75 37                	jne    400036cb <memset+0x5a>
		c &= 0xFF;
40003694:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
4000369b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000369e:	89 c2                	mov    %eax,%edx
400036a0:	c1 e2 18             	shl    $0x18,%edx
400036a3:	8b 45 0c             	mov    0xc(%ebp),%eax
400036a6:	c1 e0 10             	shl    $0x10,%eax
400036a9:	09 c2                	or     %eax,%edx
400036ab:	8b 45 0c             	mov    0xc(%ebp),%eax
400036ae:	c1 e0 08             	shl    $0x8,%eax
400036b1:	09 d0                	or     %edx,%eax
400036b3:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
400036b6:	8b 45 10             	mov    0x10(%ebp),%eax
400036b9:	89 c1                	mov    %eax,%ecx
400036bb:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
400036be:	8b 55 08             	mov    0x8(%ebp),%edx
400036c1:	8b 45 0c             	mov    0xc(%ebp),%eax
400036c4:	89 d7                	mov    %edx,%edi
400036c6:	fc                   	cld    
400036c7:	f3 ab                	rep stos %eax,%es:(%edi)
400036c9:	eb 0e                	jmp    400036d9 <memset+0x68>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
400036cb:	8b 55 08             	mov    0x8(%ebp),%edx
400036ce:	8b 45 0c             	mov    0xc(%ebp),%eax
400036d1:	8b 4d 10             	mov    0x10(%ebp),%ecx
400036d4:	89 d7                	mov    %edx,%edi
400036d6:	fc                   	cld    
400036d7:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
400036d9:	8b 45 08             	mov    0x8(%ebp),%eax
}
400036dc:	5f                   	pop    %edi
400036dd:	5d                   	pop    %ebp
400036de:	c3                   	ret    

400036df <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
400036df:	55                   	push   %ebp
400036e0:	89 e5                	mov    %esp,%ebp
400036e2:	57                   	push   %edi
400036e3:	56                   	push   %esi
400036e4:	53                   	push   %ebx
400036e5:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
400036e8:	8b 45 0c             	mov    0xc(%ebp),%eax
400036eb:	89 45 f0             	mov    %eax,-0x10(%ebp)
	d = dst;
400036ee:	8b 45 08             	mov    0x8(%ebp),%eax
400036f1:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (s < d && s + n > d) {
400036f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
400036f7:	3b 45 ec             	cmp    -0x14(%ebp),%eax
400036fa:	73 6d                	jae    40003769 <memmove+0x8a>
400036fc:	8b 45 10             	mov    0x10(%ebp),%eax
400036ff:	8b 55 f0             	mov    -0x10(%ebp),%edx
40003702:	01 d0                	add    %edx,%eax
40003704:	3b 45 ec             	cmp    -0x14(%ebp),%eax
40003707:	76 60                	jbe    40003769 <memmove+0x8a>
		s += n;
40003709:	8b 45 10             	mov    0x10(%ebp),%eax
4000370c:	01 45 f0             	add    %eax,-0x10(%ebp)
		d += n;
4000370f:	8b 45 10             	mov    0x10(%ebp),%eax
40003712:	01 45 ec             	add    %eax,-0x14(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
40003715:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003718:	83 e0 03             	and    $0x3,%eax
4000371b:	85 c0                	test   %eax,%eax
4000371d:	75 2f                	jne    4000374e <memmove+0x6f>
4000371f:	8b 45 ec             	mov    -0x14(%ebp),%eax
40003722:	83 e0 03             	and    $0x3,%eax
40003725:	85 c0                	test   %eax,%eax
40003727:	75 25                	jne    4000374e <memmove+0x6f>
40003729:	8b 45 10             	mov    0x10(%ebp),%eax
4000372c:	83 e0 03             	and    $0x3,%eax
4000372f:	85 c0                	test   %eax,%eax
40003731:	75 1b                	jne    4000374e <memmove+0x6f>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
40003733:	8b 45 ec             	mov    -0x14(%ebp),%eax
40003736:	83 e8 04             	sub    $0x4,%eax
40003739:	8b 55 f0             	mov    -0x10(%ebp),%edx
4000373c:	83 ea 04             	sub    $0x4,%edx
4000373f:	8b 4d 10             	mov    0x10(%ebp),%ecx
40003742:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
40003745:	89 c7                	mov    %eax,%edi
40003747:	89 d6                	mov    %edx,%esi
40003749:	fd                   	std    
4000374a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
4000374c:	eb 18                	jmp    40003766 <memmove+0x87>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
4000374e:	8b 45 ec             	mov    -0x14(%ebp),%eax
40003751:	8d 50 ff             	lea    -0x1(%eax),%edx
40003754:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003757:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
4000375a:	8b 45 10             	mov    0x10(%ebp),%eax
4000375d:	89 d7                	mov    %edx,%edi
4000375f:	89 de                	mov    %ebx,%esi
40003761:	89 c1                	mov    %eax,%ecx
40003763:	fd                   	std    
40003764:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
40003766:	fc                   	cld    
40003767:	eb 45                	jmp    400037ae <memmove+0xcf>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
40003769:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000376c:	83 e0 03             	and    $0x3,%eax
4000376f:	85 c0                	test   %eax,%eax
40003771:	75 2b                	jne    4000379e <memmove+0xbf>
40003773:	8b 45 ec             	mov    -0x14(%ebp),%eax
40003776:	83 e0 03             	and    $0x3,%eax
40003779:	85 c0                	test   %eax,%eax
4000377b:	75 21                	jne    4000379e <memmove+0xbf>
4000377d:	8b 45 10             	mov    0x10(%ebp),%eax
40003780:	83 e0 03             	and    $0x3,%eax
40003783:	85 c0                	test   %eax,%eax
40003785:	75 17                	jne    4000379e <memmove+0xbf>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
40003787:	8b 45 10             	mov    0x10(%ebp),%eax
4000378a:	89 c1                	mov    %eax,%ecx
4000378c:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
4000378f:	8b 45 ec             	mov    -0x14(%ebp),%eax
40003792:	8b 55 f0             	mov    -0x10(%ebp),%edx
40003795:	89 c7                	mov    %eax,%edi
40003797:	89 d6                	mov    %edx,%esi
40003799:	fc                   	cld    
4000379a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
4000379c:	eb 10                	jmp    400037ae <memmove+0xcf>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
4000379e:	8b 45 ec             	mov    -0x14(%ebp),%eax
400037a1:	8b 55 f0             	mov    -0x10(%ebp),%edx
400037a4:	8b 4d 10             	mov    0x10(%ebp),%ecx
400037a7:	89 c7                	mov    %eax,%edi
400037a9:	89 d6                	mov    %edx,%esi
400037ab:	fc                   	cld    
400037ac:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
400037ae:	8b 45 08             	mov    0x8(%ebp),%eax
}
400037b1:	83 c4 10             	add    $0x10,%esp
400037b4:	5b                   	pop    %ebx
400037b5:	5e                   	pop    %esi
400037b6:	5f                   	pop    %edi
400037b7:	5d                   	pop    %ebp
400037b8:	c3                   	ret    

400037b9 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
400037b9:	55                   	push   %ebp
400037ba:	89 e5                	mov    %esp,%ebp
400037bc:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
400037bf:	8b 45 10             	mov    0x10(%ebp),%eax
400037c2:	89 44 24 08          	mov    %eax,0x8(%esp)
400037c6:	8b 45 0c             	mov    0xc(%ebp),%eax
400037c9:	89 44 24 04          	mov    %eax,0x4(%esp)
400037cd:	8b 45 08             	mov    0x8(%ebp),%eax
400037d0:	89 04 24             	mov    %eax,(%esp)
400037d3:	e8 07 ff ff ff       	call   400036df <memmove>
}
400037d8:	c9                   	leave  
400037d9:	c3                   	ret    

400037da <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
400037da:	55                   	push   %ebp
400037db:	89 e5                	mov    %esp,%ebp
400037dd:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
400037e0:	8b 45 08             	mov    0x8(%ebp),%eax
400037e3:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
400037e6:	8b 45 0c             	mov    0xc(%ebp),%eax
400037e9:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
400037ec:	eb 32                	jmp    40003820 <memcmp+0x46>
		if (*s1 != *s2)
400037ee:	8b 45 fc             	mov    -0x4(%ebp),%eax
400037f1:	0f b6 10             	movzbl (%eax),%edx
400037f4:	8b 45 f8             	mov    -0x8(%ebp),%eax
400037f7:	0f b6 00             	movzbl (%eax),%eax
400037fa:	38 c2                	cmp    %al,%dl
400037fc:	74 1a                	je     40003818 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
400037fe:	8b 45 fc             	mov    -0x4(%ebp),%eax
40003801:	0f b6 00             	movzbl (%eax),%eax
40003804:	0f b6 d0             	movzbl %al,%edx
40003807:	8b 45 f8             	mov    -0x8(%ebp),%eax
4000380a:	0f b6 00             	movzbl (%eax),%eax
4000380d:	0f b6 c0             	movzbl %al,%eax
40003810:	89 d1                	mov    %edx,%ecx
40003812:	29 c1                	sub    %eax,%ecx
40003814:	89 c8                	mov    %ecx,%eax
40003816:	eb 1c                	jmp    40003834 <memcmp+0x5a>
		s1++, s2++;
40003818:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
4000381c:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
40003820:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003824:	0f 95 c0             	setne  %al
40003827:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
4000382b:	84 c0                	test   %al,%al
4000382d:	75 bf                	jne    400037ee <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
4000382f:	b8 00 00 00 00       	mov    $0x0,%eax
}
40003834:	c9                   	leave  
40003835:	c3                   	ret    

40003836 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
40003836:	55                   	push   %ebp
40003837:	89 e5                	mov    %esp,%ebp
40003839:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
4000383c:	8b 45 10             	mov    0x10(%ebp),%eax
4000383f:	8b 55 08             	mov    0x8(%ebp),%edx
40003842:	01 d0                	add    %edx,%eax
40003844:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
40003847:	eb 16                	jmp    4000385f <memchr+0x29>
		if (*(const unsigned char *) s == (unsigned char) c)
40003849:	8b 45 08             	mov    0x8(%ebp),%eax
4000384c:	0f b6 10             	movzbl (%eax),%edx
4000384f:	8b 45 0c             	mov    0xc(%ebp),%eax
40003852:	38 c2                	cmp    %al,%dl
40003854:	75 05                	jne    4000385b <memchr+0x25>
			return (void *) s;
40003856:	8b 45 08             	mov    0x8(%ebp),%eax
40003859:	eb 11                	jmp    4000386c <memchr+0x36>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
4000385b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
4000385f:	8b 45 08             	mov    0x8(%ebp),%eax
40003862:	3b 45 fc             	cmp    -0x4(%ebp),%eax
40003865:	72 e2                	jb     40003849 <memchr+0x13>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
40003867:	b8 00 00 00 00       	mov    $0x0,%eax
}
4000386c:	c9                   	leave  
4000386d:	c3                   	ret    
4000386e:	66 90                	xchg   %ax,%ax

40003870 <exit>:
#include <inc/assert.h>
#include <inc/string.h>

void gcc_noreturn
exit(int status)
{
40003870:	55                   	push   %ebp
40003871:	89 e5                	mov    %esp,%ebp
40003873:	83 ec 18             	sub    $0x18,%esp
	// To exit a PIOS user process, by convention,
	// we just set our exit status in our filestate area
	// and return to our parent process.
	files->status = status;
40003876:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
4000387b:	8b 55 08             	mov    0x8(%ebp),%edx
4000387e:	89 50 0c             	mov    %edx,0xc(%eax)
	files->exited = 1;
40003881:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40003886:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
4000388d:	b8 03 00 00 00       	mov    $0x3,%eax
40003892:	cd 30                	int    $0x30
	sys_ret();
	panic("exit: sys_ret shouldn't have returned");
40003894:	c7 44 24 08 78 5c 00 	movl   $0x40005c78,0x8(%esp)
4000389b:	40 
4000389c:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
400038a3:	00 
400038a4:	c7 04 24 9e 5c 00 40 	movl   $0x40005c9e,(%esp)
400038ab:	e8 90 f2 ff ff       	call   40002b40 <debug_panic>

400038b0 <abort>:
}

void gcc_noreturn
abort(void)
{
400038b0:	55                   	push   %ebp
400038b1:	89 e5                	mov    %esp,%ebp
400038b3:	83 ec 18             	sub    $0x18,%esp
	exit(EXIT_FAILURE);
400038b6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
400038bd:	e8 ae ff ff ff       	call   40003870 <exit>
400038c2:	66 90                	xchg   %ax,%ax

400038c4 <cputs>:

#include <inc/stdio.h>
#include <inc/syscall.h>

void cputs(const char *str)
{
400038c4:	55                   	push   %ebp
400038c5:	89 e5                	mov    %esp,%ebp
400038c7:	53                   	push   %ebx
400038c8:	83 ec 10             	sub    $0x10,%esp
400038cb:	8b 45 08             	mov    0x8(%ebp),%eax
400038ce:	89 45 f8             	mov    %eax,-0x8(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
400038d1:	b8 00 00 00 00       	mov    $0x0,%eax
400038d6:	8b 55 f8             	mov    -0x8(%ebp),%edx
400038d9:	89 d3                	mov    %edx,%ebx
400038db:	cd 30                	int    $0x30
	sys_cputs(str);
}
400038dd:	83 c4 10             	add    $0x10,%esp
400038e0:	5b                   	pop    %ebx
400038e1:	5d                   	pop    %ebp
400038e2:	c3                   	ret    
400038e3:	90                   	nop

400038e4 <fileino_alloc>:

// Find and return the index of a currently unused file inode in this process.
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_alloc(void)
{
400038e4:	55                   	push   %ebp
400038e5:	89 e5                	mov    %esp,%ebp
400038e7:	83 ec 28             	sub    $0x28,%esp
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
400038ea:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
400038f1:	eb 24                	jmp    40003917 <fileino_alloc+0x33>
		if (files->fi[i].de.d_name[0] == 0)
400038f3:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
400038f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
400038fc:	6b c0 5c             	imul   $0x5c,%eax,%eax
400038ff:	01 d0                	add    %edx,%eax
40003901:	05 10 10 00 00       	add    $0x1010,%eax
40003906:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000390a:	84 c0                	test   %al,%al
4000390c:	75 05                	jne    40003913 <fileino_alloc+0x2f>
			return i;
4000390e:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003911:	eb 39                	jmp    4000394c <fileino_alloc+0x68>
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_alloc(void)
{
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40003913:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40003917:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
4000391e:	7e d3                	jle    400038f3 <fileino_alloc+0xf>
		if (files->fi[i].de.d_name[0] == 0)
			return i;

	warn("fileino_alloc: no free inodes\n");
40003920:	c7 44 24 08 b0 5c 00 	movl   $0x40005cb0,0x8(%esp)
40003927:	40 
40003928:	c7 44 24 04 29 00 00 	movl   $0x29,0x4(%esp)
4000392f:	00 
40003930:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
40003937:	e8 6e f2 ff ff       	call   40002baa <debug_warn>
	errno = ENOSPC;
4000393c:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40003941:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
	return -1;
40003947:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
4000394c:	c9                   	leave  
4000394d:	c3                   	ret    

4000394e <fileino_create>:
// Returns the index of the inode found or created.
// A newly-created inode is left in the "deleted" state, with mode == 0.
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_create(filestate *fs, int dino, const char *name)
{
4000394e:	55                   	push   %ebp
4000394f:	89 e5                	mov    %esp,%ebp
40003951:	83 ec 28             	sub    $0x28,%esp
	assert(dino != 0);
40003954:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40003958:	75 24                	jne    4000397e <fileino_create+0x30>
4000395a:	c7 44 24 0c da 5c 00 	movl   $0x40005cda,0xc(%esp)
40003961:	40 
40003962:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
40003969:	40 
4000396a:	c7 44 24 04 35 00 00 	movl   $0x35,0x4(%esp)
40003971:	00 
40003972:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
40003979:	e8 c2 f1 ff ff       	call   40002b40 <debug_panic>
	assert(name != NULL && name[0] != 0);
4000397e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003982:	74 0a                	je     4000398e <fileino_create+0x40>
40003984:	8b 45 10             	mov    0x10(%ebp),%eax
40003987:	0f b6 00             	movzbl (%eax),%eax
4000398a:	84 c0                	test   %al,%al
4000398c:	75 24                	jne    400039b2 <fileino_create+0x64>
4000398e:	c7 44 24 0c f9 5c 00 	movl   $0x40005cf9,0xc(%esp)
40003995:	40 
40003996:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
4000399d:	40 
4000399e:	c7 44 24 04 36 00 00 	movl   $0x36,0x4(%esp)
400039a5:	00 
400039a6:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
400039ad:	e8 8e f1 ff ff       	call   40002b40 <debug_panic>
	assert(strlen(name) <= NAME_MAX);
400039b2:	8b 45 10             	mov    0x10(%ebp),%eax
400039b5:	89 04 24             	mov    %eax,(%esp)
400039b8:	e8 f7 fa ff ff       	call   400034b4 <strlen>
400039bd:	83 f8 3f             	cmp    $0x3f,%eax
400039c0:	7e 24                	jle    400039e6 <fileino_create+0x98>
400039c2:	c7 44 24 0c 16 5d 00 	movl   $0x40005d16,0xc(%esp)
400039c9:	40 
400039ca:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
400039d1:	40 
400039d2:	c7 44 24 04 37 00 00 	movl   $0x37,0x4(%esp)
400039d9:	00 
400039da:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
400039e1:	e8 5a f1 ff ff       	call   40002b40 <debug_panic>

	// First see if an inode already exists for this directory and name.
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
400039e6:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
400039ed:	eb 4a                	jmp    40003a39 <fileino_create+0xeb>
		if (fs->fi[i].dino == dino
400039ef:	8b 55 08             	mov    0x8(%ebp),%edx
400039f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
400039f5:	6b c0 5c             	imul   $0x5c,%eax,%eax
400039f8:	01 d0                	add    %edx,%eax
400039fa:	05 10 10 00 00       	add    $0x1010,%eax
400039ff:	8b 00                	mov    (%eax),%eax
40003a01:	3b 45 0c             	cmp    0xc(%ebp),%eax
40003a04:	75 2f                	jne    40003a35 <fileino_create+0xe7>
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
40003a06:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003a09:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003a0c:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40003a12:	8b 45 08             	mov    0x8(%ebp),%eax
40003a15:	01 d0                	add    %edx,%eax
40003a17:	8d 50 04             	lea    0x4(%eax),%edx
40003a1a:	8b 45 10             	mov    0x10(%ebp),%eax
40003a1d:	89 44 24 04          	mov    %eax,0x4(%esp)
40003a21:	89 14 24             	mov    %edx,(%esp)
40003a24:	e8 77 fb ff ff       	call   400035a0 <strcmp>
40003a29:	85 c0                	test   %eax,%eax
40003a2b:	75 08                	jne    40003a35 <fileino_create+0xe7>
			return i;
40003a2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003a30:	e9 a5 00 00 00       	jmp    40003ada <fileino_create+0x18c>
	assert(name != NULL && name[0] != 0);
	assert(strlen(name) <= NAME_MAX);

	// First see if an inode already exists for this directory and name.
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40003a35:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40003a39:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
40003a40:	7e ad                	jle    400039ef <fileino_create+0xa1>
		if (fs->fi[i].dino == dino
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
			return i;

	// No inode allocated to this name - find a free one to allocate.
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40003a42:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
40003a49:	eb 5a                	jmp    40003aa5 <fileino_create+0x157>
		if (fs->fi[i].de.d_name[0] == 0) {
40003a4b:	8b 55 08             	mov    0x8(%ebp),%edx
40003a4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003a51:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003a54:	01 d0                	add    %edx,%eax
40003a56:	05 10 10 00 00       	add    $0x1010,%eax
40003a5b:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40003a5f:	84 c0                	test   %al,%al
40003a61:	75 3e                	jne    40003aa1 <fileino_create+0x153>
			fs->fi[i].dino = dino;
40003a63:	8b 55 08             	mov    0x8(%ebp),%edx
40003a66:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003a69:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003a6c:	01 d0                	add    %edx,%eax
40003a6e:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40003a74:	8b 45 0c             	mov    0xc(%ebp),%eax
40003a77:	89 02                	mov    %eax,(%edx)
			strcpy(fs->fi[i].de.d_name, name);
40003a79:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003a7c:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003a7f:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40003a85:	8b 45 08             	mov    0x8(%ebp),%eax
40003a88:	01 d0                	add    %edx,%eax
40003a8a:	8d 50 04             	lea    0x4(%eax),%edx
40003a8d:	8b 45 10             	mov    0x10(%ebp),%eax
40003a90:	89 44 24 04          	mov    %eax,0x4(%esp)
40003a94:	89 14 24             	mov    %edx,(%esp)
40003a97:	e8 3e fa ff ff       	call   400034da <strcpy>
			return i;
40003a9c:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003a9f:	eb 39                	jmp    40003ada <fileino_create+0x18c>
		if (fs->fi[i].dino == dino
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
			return i;

	// No inode allocated to this name - find a free one to allocate.
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40003aa1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40003aa5:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
40003aac:	7e 9d                	jle    40003a4b <fileino_create+0xfd>
			fs->fi[i].dino = dino;
			strcpy(fs->fi[i].de.d_name, name);
			return i;
		}

	warn("fileino_create: no free inodes\n");
40003aae:	c7 44 24 08 30 5d 00 	movl   $0x40005d30,0x8(%esp)
40003ab5:	40 
40003ab6:	c7 44 24 04 48 00 00 	movl   $0x48,0x4(%esp)
40003abd:	00 
40003abe:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
40003ac5:	e8 e0 f0 ff ff       	call   40002baa <debug_warn>
	errno = ENOSPC;
40003aca:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40003acf:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
	return -1;
40003ad5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
40003ada:	c9                   	leave  
40003adb:	c3                   	ret    

40003adc <fileino_read>:
// The number of elements returned is normally equal to the 'count' parameter,
// but may be less (without resulting in an error)
// if the file is not large enough to read that many elements.
ssize_t
fileino_read(int ino, off_t ofs, void *buf, size_t eltsize, size_t count)
{
40003adc:	55                   	push   %ebp
40003add:	89 e5                	mov    %esp,%ebp
40003adf:	83 ec 28             	sub    $0x28,%esp
	assert(fileino_isreg(ino));
40003ae2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003ae6:	7e 45                	jle    40003b2d <fileino_read+0x51>
40003ae8:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40003aef:	7f 3c                	jg     40003b2d <fileino_read+0x51>
40003af1:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40003af7:	8b 45 08             	mov    0x8(%ebp),%eax
40003afa:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003afd:	01 d0                	add    %edx,%eax
40003aff:	05 10 10 00 00       	add    $0x1010,%eax
40003b04:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40003b08:	84 c0                	test   %al,%al
40003b0a:	74 21                	je     40003b2d <fileino_read+0x51>
40003b0c:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40003b12:	8b 45 08             	mov    0x8(%ebp),%eax
40003b15:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003b18:	01 d0                	add    %edx,%eax
40003b1a:	05 58 10 00 00       	add    $0x1058,%eax
40003b1f:	8b 00                	mov    (%eax),%eax
40003b21:	25 00 70 00 00       	and    $0x7000,%eax
40003b26:	3d 00 10 00 00       	cmp    $0x1000,%eax
40003b2b:	74 24                	je     40003b51 <fileino_read+0x75>
40003b2d:	c7 44 24 0c 50 5d 00 	movl   $0x40005d50,0xc(%esp)
40003b34:	40 
40003b35:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
40003b3c:	40 
40003b3d:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
40003b44:	00 
40003b45:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
40003b4c:	e8 ef ef ff ff       	call   40002b40 <debug_panic>
	assert(ofs >= 0);
40003b51:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40003b55:	79 24                	jns    40003b7b <fileino_read+0x9f>
40003b57:	c7 44 24 0c 63 5d 00 	movl   $0x40005d63,0xc(%esp)
40003b5e:	40 
40003b5f:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
40003b66:	40 
40003b67:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
40003b6e:	00 
40003b6f:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
40003b76:	e8 c5 ef ff ff       	call   40002b40 <debug_panic>
	assert(eltsize > 0);
40003b7b:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40003b7f:	75 24                	jne    40003ba5 <fileino_read+0xc9>
40003b81:	c7 44 24 0c 6c 5d 00 	movl   $0x40005d6c,0xc(%esp)
40003b88:	40 
40003b89:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
40003b90:	40 
40003b91:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
40003b98:	00 
40003b99:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
40003ba0:	e8 9b ef ff ff       	call   40002b40 <debug_panic>

	ssize_t return_number = 0;
40003ba5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	fileinode *fi = &files->fi[ino];
40003bac:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40003bb1:	8b 55 08             	mov    0x8(%ebp),%edx
40003bb4:	6b d2 5c             	imul   $0x5c,%edx,%edx
40003bb7:	81 c2 10 10 00 00    	add    $0x1010,%edx
40003bbd:	01 d0                	add    %edx,%eax
40003bbf:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint32_t tmp_ofs = ofs;
40003bc2:	8b 45 0c             	mov    0xc(%ebp),%eax
40003bc5:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint8_t* read_pointer = FILEDATA(ino) + ofs;
40003bc8:	8b 45 08             	mov    0x8(%ebp),%eax
40003bcb:	c1 e0 16             	shl    $0x16,%eax
40003bce:	89 c2                	mov    %eax,%edx
40003bd0:	8b 45 0c             	mov    0xc(%ebp),%eax
40003bd3:	01 d0                	add    %edx,%eax
40003bd5:	05 00 00 00 80       	add    $0x80000000,%eax
40003bda:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(fi->size <= FILE_MAXSIZE);
40003bdd:	8b 45 e8             	mov    -0x18(%ebp),%eax
40003be0:	8b 40 4c             	mov    0x4c(%eax),%eax
40003be3:	3d 00 00 40 00       	cmp    $0x400000,%eax
40003be8:	76 7a                	jbe    40003c64 <fileino_read+0x188>
40003bea:	c7 44 24 0c 78 5d 00 	movl   $0x40005d78,0xc(%esp)
40003bf1:	40 
40003bf2:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
40003bf9:	40 
40003bfa:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
40003c01:	00 
40003c02:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
40003c09:	e8 32 ef ff ff       	call   40002b40 <debug_panic>
	// Lab 4: insert your file reading code here.
	//warn("fileino_read() not implemented");
	while(count > 0){
		if(tmp_ofs >= fi->size){
40003c0e:	8b 45 e8             	mov    -0x18(%ebp),%eax
40003c11:	8b 40 4c             	mov    0x4c(%eax),%eax
40003c14:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40003c17:	77 18                	ja     40003c31 <fileino_read+0x155>
			if(fi->mode & S_IFPART)
40003c19:	8b 45 e8             	mov    -0x18(%ebp),%eax
40003c1c:	8b 40 48             	mov    0x48(%eax),%eax
40003c1f:	25 00 80 00 00       	and    $0x8000,%eax
40003c24:	85 c0                	test   %eax,%eax
40003c26:	74 44                	je     40003c6c <fileino_read+0x190>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40003c28:	b8 03 00 00 00       	mov    $0x3,%eax
40003c2d:	cd 30                	int    $0x30
40003c2f:	eb 33                	jmp    40003c64 <fileino_read+0x188>
				sys_ret();
			else
				break;
		}else{
			memcpy(buf, read_pointer, eltsize);
40003c31:	8b 45 14             	mov    0x14(%ebp),%eax
40003c34:	89 44 24 08          	mov    %eax,0x8(%esp)
40003c38:	8b 45 ec             	mov    -0x14(%ebp),%eax
40003c3b:	89 44 24 04          	mov    %eax,0x4(%esp)
40003c3f:	8b 45 10             	mov    0x10(%ebp),%eax
40003c42:	89 04 24             	mov    %eax,(%esp)
40003c45:	e8 6f fb ff ff       	call   400037b9 <memcpy>
			return_number++;
40003c4a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
			buf += eltsize;
40003c4e:	8b 45 14             	mov    0x14(%ebp),%eax
40003c51:	01 45 10             	add    %eax,0x10(%ebp)
			read_pointer += eltsize;
40003c54:	8b 45 14             	mov    0x14(%ebp),%eax
40003c57:	01 45 ec             	add    %eax,-0x14(%ebp)
			tmp_ofs += eltsize;
40003c5a:	8b 45 14             	mov    0x14(%ebp),%eax
40003c5d:	01 45 f0             	add    %eax,-0x10(%ebp)
			count--;
40003c60:	83 6d 18 01          	subl   $0x1,0x18(%ebp)
	uint32_t tmp_ofs = ofs;
	uint8_t* read_pointer = FILEDATA(ino) + ofs;
	assert(fi->size <= FILE_MAXSIZE);
	// Lab 4: insert your file reading code here.
	//warn("fileino_read() not implemented");
	while(count > 0){
40003c64:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
40003c68:	75 a4                	jne    40003c0e <fileino_read+0x132>
40003c6a:	eb 01                	jmp    40003c6d <fileino_read+0x191>
		if(tmp_ofs >= fi->size){
			if(fi->mode & S_IFPART)
				sys_ret();
			else
				break;
40003c6c:	90                   	nop
			read_pointer += eltsize;
			tmp_ofs += eltsize;
			count--;
		}
	}
	return return_number;
40003c6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
//	errno = EINVAL;
//	return -1;
}
40003c70:	c9                   	leave  
40003c71:	c3                   	ret    

40003c72 <fileino_write>:
// one particular reason an error might occur is if an application
// tries to grow a file beyond this maximum file size,
// in which case this function generates the EFBIG error.
ssize_t
fileino_write(int ino, off_t ofs, const void *buf, size_t eltsize, size_t count)
{
40003c72:	55                   	push   %ebp
40003c73:	89 e5                	mov    %esp,%ebp
40003c75:	57                   	push   %edi
40003c76:	56                   	push   %esi
40003c77:	53                   	push   %ebx
40003c78:	83 ec 6c             	sub    $0x6c,%esp
	assert(fileino_isreg(ino));
40003c7b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003c7f:	7e 45                	jle    40003cc6 <fileino_write+0x54>
40003c81:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40003c88:	7f 3c                	jg     40003cc6 <fileino_write+0x54>
40003c8a:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40003c90:	8b 45 08             	mov    0x8(%ebp),%eax
40003c93:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003c96:	01 d0                	add    %edx,%eax
40003c98:	05 10 10 00 00       	add    $0x1010,%eax
40003c9d:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40003ca1:	84 c0                	test   %al,%al
40003ca3:	74 21                	je     40003cc6 <fileino_write+0x54>
40003ca5:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40003cab:	8b 45 08             	mov    0x8(%ebp),%eax
40003cae:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003cb1:	01 d0                	add    %edx,%eax
40003cb3:	05 58 10 00 00       	add    $0x1058,%eax
40003cb8:	8b 00                	mov    (%eax),%eax
40003cba:	25 00 70 00 00       	and    $0x7000,%eax
40003cbf:	3d 00 10 00 00       	cmp    $0x1000,%eax
40003cc4:	74 24                	je     40003cea <fileino_write+0x78>
40003cc6:	c7 44 24 0c 50 5d 00 	movl   $0x40005d50,0xc(%esp)
40003ccd:	40 
40003cce:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
40003cd5:	40 
40003cd6:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
40003cdd:	00 
40003cde:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
40003ce5:	e8 56 ee ff ff       	call   40002b40 <debug_panic>
	assert(ofs >= 0);
40003cea:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40003cee:	79 24                	jns    40003d14 <fileino_write+0xa2>
40003cf0:	c7 44 24 0c 63 5d 00 	movl   $0x40005d63,0xc(%esp)
40003cf7:	40 
40003cf8:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
40003cff:	40 
40003d00:	c7 44 24 04 84 00 00 	movl   $0x84,0x4(%esp)
40003d07:	00 
40003d08:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
40003d0f:	e8 2c ee ff ff       	call   40002b40 <debug_panic>
	assert(eltsize > 0);
40003d14:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40003d18:	75 24                	jne    40003d3e <fileino_write+0xcc>
40003d1a:	c7 44 24 0c 6c 5d 00 	movl   $0x40005d6c,0xc(%esp)
40003d21:	40 
40003d22:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
40003d29:	40 
40003d2a:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
40003d31:	00 
40003d32:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
40003d39:	e8 02 ee ff ff       	call   40002b40 <debug_panic>

	int i = 0;
40003d3e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	ssize_t return_number = 0;
40003d45:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	fileinode *fi = &files->fi[ino];
40003d4c:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40003d51:	8b 55 08             	mov    0x8(%ebp),%edx
40003d54:	6b d2 5c             	imul   $0x5c,%edx,%edx
40003d57:	81 c2 10 10 00 00    	add    $0x1010,%edx
40003d5d:	01 d0                	add    %edx,%eax
40003d5f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	assert(fi->size <= FILE_MAXSIZE);
40003d62:	8b 45 d8             	mov    -0x28(%ebp),%eax
40003d65:	8b 40 4c             	mov    0x4c(%eax),%eax
40003d68:	3d 00 00 40 00       	cmp    $0x400000,%eax
40003d6d:	76 24                	jbe    40003d93 <fileino_write+0x121>
40003d6f:	c7 44 24 0c 78 5d 00 	movl   $0x40005d78,0xc(%esp)
40003d76:	40 
40003d77:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
40003d7e:	40 
40003d7f:	c7 44 24 04 8a 00 00 	movl   $0x8a,0x4(%esp)
40003d86:	00 
40003d87:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
40003d8e:	e8 ad ed ff ff       	call   40002b40 <debug_panic>
	uint8_t* write_start = FILEDATA(ino) + ofs;
40003d93:	8b 45 08             	mov    0x8(%ebp),%eax
40003d96:	c1 e0 16             	shl    $0x16,%eax
40003d99:	89 c2                	mov    %eax,%edx
40003d9b:	8b 45 0c             	mov    0xc(%ebp),%eax
40003d9e:	01 d0                	add    %edx,%eax
40003da0:	05 00 00 00 80       	add    $0x80000000,%eax
40003da5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	uint8_t* write_pointer = write_start;
40003da8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40003dab:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uint32_t after_write_size = ofs + eltsize * count;
40003dae:	8b 45 14             	mov    0x14(%ebp),%eax
40003db1:	89 c2                	mov    %eax,%edx
40003db3:	0f af 55 18          	imul   0x18(%ebp),%edx
40003db7:	8b 45 0c             	mov    0xc(%ebp),%eax
40003dba:	01 d0                	add    %edx,%eax
40003dbc:	89 45 d0             	mov    %eax,-0x30(%ebp)

	if(after_write_size > FILE_MAXSIZE){
40003dbf:	81 7d d0 00 00 40 00 	cmpl   $0x400000,-0x30(%ebp)
40003dc6:	76 15                	jbe    40003ddd <fileino_write+0x16b>
		errno = EFBIG;
40003dc8:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40003dcd:	c7 00 03 00 00 00    	movl   $0x3,(%eax)
		return -1;
40003dd3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40003dd8:	e9 28 01 00 00       	jmp    40003f05 <fileino_write+0x293>
	}
	if(after_write_size > fi->size){
40003ddd:	8b 45 d8             	mov    -0x28(%ebp),%eax
40003de0:	8b 40 4c             	mov    0x4c(%eax),%eax
40003de3:	3b 45 d0             	cmp    -0x30(%ebp),%eax
40003de6:	0f 83 0d 01 00 00    	jae    40003ef9 <fileino_write+0x287>
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
40003dec:	c7 45 cc 00 10 00 00 	movl   $0x1000,-0x34(%ebp)
40003df3:	8b 45 cc             	mov    -0x34(%ebp),%eax
40003df6:	8b 55 d0             	mov    -0x30(%ebp),%edx
40003df9:	01 d0                	add    %edx,%eax
40003dfb:	83 e8 01             	sub    $0x1,%eax
40003dfe:	89 45 c8             	mov    %eax,-0x38(%ebp)
40003e01:	8b 45 c8             	mov    -0x38(%ebp),%eax
40003e04:	ba 00 00 00 00       	mov    $0x0,%edx
40003e09:	f7 75 cc             	divl   -0x34(%ebp)
40003e0c:	89 d0                	mov    %edx,%eax
40003e0e:	8b 55 c8             	mov    -0x38(%ebp),%edx
40003e11:	89 d1                	mov    %edx,%ecx
40003e13:	29 c1                	sub    %eax,%ecx
40003e15:	89 c8                	mov    %ecx,%eax
40003e17:	89 c1                	mov    %eax,%ecx
40003e19:	c7 45 c4 00 10 00 00 	movl   $0x1000,-0x3c(%ebp)
40003e20:	8b 45 d8             	mov    -0x28(%ebp),%eax
40003e23:	8b 50 4c             	mov    0x4c(%eax),%edx
40003e26:	8b 45 c4             	mov    -0x3c(%ebp),%eax
40003e29:	01 d0                	add    %edx,%eax
40003e2b:	83 e8 01             	sub    $0x1,%eax
40003e2e:	89 45 c0             	mov    %eax,-0x40(%ebp)
40003e31:	8b 45 c0             	mov    -0x40(%ebp),%eax
40003e34:	ba 00 00 00 00       	mov    $0x0,%edx
40003e39:	f7 75 c4             	divl   -0x3c(%ebp)
40003e3c:	89 d0                	mov    %edx,%eax
40003e3e:	8b 55 c0             	mov    -0x40(%ebp),%edx
40003e41:	89 d3                	mov    %edx,%ebx
40003e43:	29 c3                	sub    %eax,%ebx
40003e45:	89 d8                	mov    %ebx,%eax
	if(after_write_size > FILE_MAXSIZE){
		errno = EFBIG;
		return -1;
	}
	if(after_write_size > fi->size){
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
40003e47:	29 c1                	sub    %eax,%ecx
40003e49:	8b 45 08             	mov    0x8(%ebp),%eax
40003e4c:	c1 e0 16             	shl    $0x16,%eax
40003e4f:	89 c3                	mov    %eax,%ebx
40003e51:	c7 45 bc 00 10 00 00 	movl   $0x1000,-0x44(%ebp)
40003e58:	8b 45 d8             	mov    -0x28(%ebp),%eax
40003e5b:	8b 50 4c             	mov    0x4c(%eax),%edx
40003e5e:	8b 45 bc             	mov    -0x44(%ebp),%eax
40003e61:	01 d0                	add    %edx,%eax
40003e63:	83 e8 01             	sub    $0x1,%eax
40003e66:	89 45 b8             	mov    %eax,-0x48(%ebp)
40003e69:	8b 45 b8             	mov    -0x48(%ebp),%eax
40003e6c:	ba 00 00 00 00       	mov    $0x0,%edx
40003e71:	f7 75 bc             	divl   -0x44(%ebp)
40003e74:	89 d0                	mov    %edx,%eax
40003e76:	8b 55 b8             	mov    -0x48(%ebp),%edx
40003e79:	89 d6                	mov    %edx,%esi
40003e7b:	29 c6                	sub    %eax,%esi
40003e7d:	89 f0                	mov    %esi,%eax
40003e7f:	01 d8                	add    %ebx,%eax
40003e81:	05 00 00 00 80       	add    $0x80000000,%eax
40003e86:	c7 45 b4 00 07 00 00 	movl   $0x700,-0x4c(%ebp)
40003e8d:	66 c7 45 b2 00 00    	movw   $0x0,-0x4e(%ebp)
40003e93:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
40003e9a:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
40003ea1:	89 45 a4             	mov    %eax,-0x5c(%ebp)
40003ea4:	89 4d a0             	mov    %ecx,-0x60(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40003ea7:	8b 45 b4             	mov    -0x4c(%ebp),%eax
40003eaa:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40003ead:	8b 5d ac             	mov    -0x54(%ebp),%ebx
40003eb0:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
40003eb4:	8b 75 a8             	mov    -0x58(%ebp),%esi
40003eb7:	8b 7d a4             	mov    -0x5c(%ebp),%edi
40003eba:	8b 4d a0             	mov    -0x60(%ebp),%ecx
40003ebd:	cd 30                	int    $0x30
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
		fi->size = after_write_size;
40003ebf:	8b 45 d8             	mov    -0x28(%ebp),%eax
40003ec2:	8b 55 d0             	mov    -0x30(%ebp),%edx
40003ec5:	89 50 4c             	mov    %edx,0x4c(%eax)
	}
	for(i; i < count; i++){
40003ec8:	eb 2f                	jmp    40003ef9 <fileino_write+0x287>
		memcpy(write_pointer, buf, eltsize);
40003eca:	8b 45 14             	mov    0x14(%ebp),%eax
40003ecd:	89 44 24 08          	mov    %eax,0x8(%esp)
40003ed1:	8b 45 10             	mov    0x10(%ebp),%eax
40003ed4:	89 44 24 04          	mov    %eax,0x4(%esp)
40003ed8:	8b 45 dc             	mov    -0x24(%ebp),%eax
40003edb:	89 04 24             	mov    %eax,(%esp)
40003ede:	e8 d6 f8 ff ff       	call   400037b9 <memcpy>
		return_number++;
40003ee3:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
		buf += eltsize;
40003ee7:	8b 45 14             	mov    0x14(%ebp),%eax
40003eea:	01 45 10             	add    %eax,0x10(%ebp)
		write_pointer += eltsize;
40003eed:	8b 45 14             	mov    0x14(%ebp),%eax
40003ef0:	01 45 dc             	add    %eax,-0x24(%ebp)
	if(after_write_size > fi->size){
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
		fi->size = after_write_size;
	}
	for(i; i < count; i++){
40003ef3:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
40003ef7:	eb 01                	jmp    40003efa <fileino_write+0x288>
40003ef9:	90                   	nop
40003efa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40003efd:	3b 45 18             	cmp    0x18(%ebp),%eax
40003f00:	72 c8                	jb     40003eca <fileino_write+0x258>
		memcpy(write_pointer, buf, eltsize);
		return_number++;
		buf += eltsize;
		write_pointer += eltsize;
	}
	return return_number;
40003f02:	8b 45 e0             	mov    -0x20(%ebp),%eax

	// Lab 4: insert your file writing code here.
	//warn("fileino_write() not implemented");
	//errno = EINVAL;
	//return -1;
}
40003f05:	83 c4 6c             	add    $0x6c,%esp
40003f08:	5b                   	pop    %ebx
40003f09:	5e                   	pop    %esi
40003f0a:	5f                   	pop    %edi
40003f0b:	5d                   	pop    %ebp
40003f0c:	c3                   	ret    

40003f0d <fileino_stat>:
// Return file statistics about a particular inode.
// The specified inode must indicate a file that exists,
// but it can be any type of object: e.g., file, directory, special file, etc.
int
fileino_stat(int ino, struct stat *st)
{
40003f0d:	55                   	push   %ebp
40003f0e:	89 e5                	mov    %esp,%ebp
40003f10:	83 ec 28             	sub    $0x28,%esp
	assert(fileino_exists(ino));
40003f13:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003f17:	7e 3d                	jle    40003f56 <fileino_stat+0x49>
40003f19:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40003f20:	7f 34                	jg     40003f56 <fileino_stat+0x49>
40003f22:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40003f28:	8b 45 08             	mov    0x8(%ebp),%eax
40003f2b:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003f2e:	01 d0                	add    %edx,%eax
40003f30:	05 10 10 00 00       	add    $0x1010,%eax
40003f35:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40003f39:	84 c0                	test   %al,%al
40003f3b:	74 19                	je     40003f56 <fileino_stat+0x49>
40003f3d:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40003f43:	8b 45 08             	mov    0x8(%ebp),%eax
40003f46:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003f49:	01 d0                	add    %edx,%eax
40003f4b:	05 58 10 00 00       	add    $0x1058,%eax
40003f50:	8b 00                	mov    (%eax),%eax
40003f52:	85 c0                	test   %eax,%eax
40003f54:	75 24                	jne    40003f7a <fileino_stat+0x6d>
40003f56:	c7 44 24 0c 91 5d 00 	movl   $0x40005d91,0xc(%esp)
40003f5d:	40 
40003f5e:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
40003f65:	40 
40003f66:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
40003f6d:	00 
40003f6e:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
40003f75:	e8 c6 eb ff ff       	call   40002b40 <debug_panic>

	fileinode *fi = &files->fi[ino];
40003f7a:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40003f7f:	8b 55 08             	mov    0x8(%ebp),%edx
40003f82:	6b d2 5c             	imul   $0x5c,%edx,%edx
40003f85:	81 c2 10 10 00 00    	add    $0x1010,%edx
40003f8b:	01 d0                	add    %edx,%eax
40003f8d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert(fileino_isdir(fi->dino));	// Should be in a directory!
40003f90:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003f93:	8b 00                	mov    (%eax),%eax
40003f95:	85 c0                	test   %eax,%eax
40003f97:	7e 4c                	jle    40003fe5 <fileino_stat+0xd8>
40003f99:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003f9c:	8b 00                	mov    (%eax),%eax
40003f9e:	3d ff 00 00 00       	cmp    $0xff,%eax
40003fa3:	7f 40                	jg     40003fe5 <fileino_stat+0xd8>
40003fa5:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40003fab:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003fae:	8b 00                	mov    (%eax),%eax
40003fb0:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003fb3:	01 d0                	add    %edx,%eax
40003fb5:	05 10 10 00 00       	add    $0x1010,%eax
40003fba:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40003fbe:	84 c0                	test   %al,%al
40003fc0:	74 23                	je     40003fe5 <fileino_stat+0xd8>
40003fc2:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40003fc8:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003fcb:	8b 00                	mov    (%eax),%eax
40003fcd:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003fd0:	01 d0                	add    %edx,%eax
40003fd2:	05 58 10 00 00       	add    $0x1058,%eax
40003fd7:	8b 00                	mov    (%eax),%eax
40003fd9:	25 00 70 00 00       	and    $0x7000,%eax
40003fde:	3d 00 20 00 00       	cmp    $0x2000,%eax
40003fe3:	74 24                	je     40004009 <fileino_stat+0xfc>
40003fe5:	c7 44 24 0c a5 5d 00 	movl   $0x40005da5,0xc(%esp)
40003fec:	40 
40003fed:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
40003ff4:	40 
40003ff5:	c7 44 24 04 af 00 00 	movl   $0xaf,0x4(%esp)
40003ffc:	00 
40003ffd:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
40004004:	e8 37 eb ff ff       	call   40002b40 <debug_panic>
	st->st_ino = ino;
40004009:	8b 45 0c             	mov    0xc(%ebp),%eax
4000400c:	8b 55 08             	mov    0x8(%ebp),%edx
4000400f:	89 10                	mov    %edx,(%eax)
	st->st_mode = fi->mode;
40004011:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004014:	8b 50 48             	mov    0x48(%eax),%edx
40004017:	8b 45 0c             	mov    0xc(%ebp),%eax
4000401a:	89 50 04             	mov    %edx,0x4(%eax)
	st->st_size = fi->size;
4000401d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004020:	8b 40 4c             	mov    0x4c(%eax),%eax
40004023:	89 c2                	mov    %eax,%edx
40004025:	8b 45 0c             	mov    0xc(%ebp),%eax
40004028:	89 50 08             	mov    %edx,0x8(%eax)

	return 0;
4000402b:	b8 00 00 00 00       	mov    $0x0,%eax
}
40004030:	c9                   	leave  
40004031:	c3                   	ret    

40004032 <fileino_truncate>:
// Grow or shrink a file to exactly a specified size.
// If growing a file, then fills the new space with zeros.
// Returns 0 if successful, or returns -1 and sets errno on error.
int
fileino_truncate(int ino, off_t newsize)
{
40004032:	55                   	push   %ebp
40004033:	89 e5                	mov    %esp,%ebp
40004035:	57                   	push   %edi
40004036:	56                   	push   %esi
40004037:	53                   	push   %ebx
40004038:	81 ec 8c 00 00 00    	sub    $0x8c,%esp
	assert(fileino_isvalid(ino));
4000403e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40004042:	7e 09                	jle    4000404d <fileino_truncate+0x1b>
40004044:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
4000404b:	7e 24                	jle    40004071 <fileino_truncate+0x3f>
4000404d:	c7 44 24 0c bd 5d 00 	movl   $0x40005dbd,0xc(%esp)
40004054:	40 
40004055:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
4000405c:	40 
4000405d:	c7 44 24 04 bd 00 00 	movl   $0xbd,0x4(%esp)
40004064:	00 
40004065:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
4000406c:	e8 cf ea ff ff       	call   40002b40 <debug_panic>
	assert(newsize >= 0 && newsize <= FILE_MAXSIZE);
40004071:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40004075:	78 09                	js     40004080 <fileino_truncate+0x4e>
40004077:	81 7d 0c 00 00 40 00 	cmpl   $0x400000,0xc(%ebp)
4000407e:	7e 24                	jle    400040a4 <fileino_truncate+0x72>
40004080:	c7 44 24 0c d4 5d 00 	movl   $0x40005dd4,0xc(%esp)
40004087:	40 
40004088:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
4000408f:	40 
40004090:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
40004097:	00 
40004098:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
4000409f:	e8 9c ea ff ff       	call   40002b40 <debug_panic>

	size_t oldsize = files->fi[ino].size;
400040a4:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
400040aa:	8b 45 08             	mov    0x8(%ebp),%eax
400040ad:	6b c0 5c             	imul   $0x5c,%eax,%eax
400040b0:	01 d0                	add    %edx,%eax
400040b2:	05 5c 10 00 00       	add    $0x105c,%eax
400040b7:	8b 00                	mov    (%eax),%eax
400040b9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	size_t oldpagelim = ROUNDUP(files->fi[ino].size, PAGESIZE);
400040bc:	c7 45 e0 00 10 00 00 	movl   $0x1000,-0x20(%ebp)
400040c3:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
400040c9:	8b 45 08             	mov    0x8(%ebp),%eax
400040cc:	6b c0 5c             	imul   $0x5c,%eax,%eax
400040cf:	01 d0                	add    %edx,%eax
400040d1:	05 5c 10 00 00       	add    $0x105c,%eax
400040d6:	8b 10                	mov    (%eax),%edx
400040d8:	8b 45 e0             	mov    -0x20(%ebp),%eax
400040db:	01 d0                	add    %edx,%eax
400040dd:	83 e8 01             	sub    $0x1,%eax
400040e0:	89 45 dc             	mov    %eax,-0x24(%ebp)
400040e3:	8b 45 dc             	mov    -0x24(%ebp),%eax
400040e6:	ba 00 00 00 00       	mov    $0x0,%edx
400040eb:	f7 75 e0             	divl   -0x20(%ebp)
400040ee:	89 d0                	mov    %edx,%eax
400040f0:	8b 55 dc             	mov    -0x24(%ebp),%edx
400040f3:	89 d1                	mov    %edx,%ecx
400040f5:	29 c1                	sub    %eax,%ecx
400040f7:	89 c8                	mov    %ecx,%eax
400040f9:	89 45 d8             	mov    %eax,-0x28(%ebp)
	size_t newpagelim = ROUNDUP(newsize, PAGESIZE);
400040fc:	c7 45 d4 00 10 00 00 	movl   $0x1000,-0x2c(%ebp)
40004103:	8b 55 0c             	mov    0xc(%ebp),%edx
40004106:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40004109:	01 d0                	add    %edx,%eax
4000410b:	83 e8 01             	sub    $0x1,%eax
4000410e:	89 45 d0             	mov    %eax,-0x30(%ebp)
40004111:	8b 45 d0             	mov    -0x30(%ebp),%eax
40004114:	ba 00 00 00 00       	mov    $0x0,%edx
40004119:	f7 75 d4             	divl   -0x2c(%ebp)
4000411c:	89 d0                	mov    %edx,%eax
4000411e:	8b 55 d0             	mov    -0x30(%ebp),%edx
40004121:	89 d1                	mov    %edx,%ecx
40004123:	29 c1                	sub    %eax,%ecx
40004125:	89 c8                	mov    %ecx,%eax
40004127:	89 45 cc             	mov    %eax,-0x34(%ebp)
	if (newsize > oldsize) {
4000412a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000412d:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
40004130:	0f 86 8a 00 00 00    	jbe    400041c0 <fileino_truncate+0x18e>
		// Grow the file and fill the new space with zeros.
		sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
40004136:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004139:	8b 55 cc             	mov    -0x34(%ebp),%edx
4000413c:	89 d1                	mov    %edx,%ecx
4000413e:	29 c1                	sub    %eax,%ecx
40004140:	89 c8                	mov    %ecx,%eax
			FILEDATA(ino) + oldpagelim,
40004142:	8b 55 08             	mov    0x8(%ebp),%edx
40004145:	c1 e2 16             	shl    $0x16,%edx
40004148:	89 d1                	mov    %edx,%ecx
4000414a:	8b 55 d8             	mov    -0x28(%ebp),%edx
4000414d:	01 ca                	add    %ecx,%edx
	size_t oldsize = files->fi[ino].size;
	size_t oldpagelim = ROUNDUP(files->fi[ino].size, PAGESIZE);
	size_t newpagelim = ROUNDUP(newsize, PAGESIZE);
	if (newsize > oldsize) {
		// Grow the file and fill the new space with zeros.
		sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
4000414f:	81 c2 00 00 00 80    	add    $0x80000000,%edx
40004155:	c7 45 c8 00 07 00 00 	movl   $0x700,-0x38(%ebp)
4000415c:	66 c7 45 c6 00 00    	movw   $0x0,-0x3a(%ebp)
40004162:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
40004169:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
40004170:	89 55 b8             	mov    %edx,-0x48(%ebp)
40004173:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40004176:	8b 45 c8             	mov    -0x38(%ebp),%eax
40004179:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000417c:	8b 5d c0             	mov    -0x40(%ebp),%ebx
4000417f:	0f b7 55 c6          	movzwl -0x3a(%ebp),%edx
40004183:	8b 75 bc             	mov    -0x44(%ebp),%esi
40004186:	8b 7d b8             	mov    -0x48(%ebp),%edi
40004189:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
4000418c:	cd 30                	int    $0x30
			FILEDATA(ino) + oldpagelim,
			newpagelim - oldpagelim);
		memset(FILEDATA(ino) + oldsize, 0, newsize - oldsize);
4000418e:	8b 45 0c             	mov    0xc(%ebp),%eax
40004191:	2b 45 e4             	sub    -0x1c(%ebp),%eax
40004194:	8b 55 08             	mov    0x8(%ebp),%edx
40004197:	c1 e2 16             	shl    $0x16,%edx
4000419a:	89 d1                	mov    %edx,%ecx
4000419c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
4000419f:	01 ca                	add    %ecx,%edx
400041a1:	81 c2 00 00 00 80    	add    $0x80000000,%edx
400041a7:	89 44 24 08          	mov    %eax,0x8(%esp)
400041ab:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400041b2:	00 
400041b3:	89 14 24             	mov    %edx,(%esp)
400041b6:	e8 b6 f4 ff ff       	call   40003671 <memset>
400041bb:	e9 a4 00 00 00       	jmp    40004264 <fileino_truncate+0x232>
	} else if (newsize > 0) {
400041c0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400041c4:	7e 56                	jle    4000421c <fileino_truncate+0x1ea>
		// Shrink the file, but not all the way to empty.
		// Would prefer to use SYS_ZERO to free the file content,
		// but SYS_ZERO isn't guaranteed to work at page granularity.
		sys_get(SYS_PERM, 0, NULL, NULL,
400041c6:	b8 00 00 40 00       	mov    $0x400000,%eax
400041cb:	2b 45 cc             	sub    -0x34(%ebp),%eax
			FILEDATA(ino) + newpagelim, FILE_MAXSIZE - newpagelim);
400041ce:	8b 55 08             	mov    0x8(%ebp),%edx
400041d1:	c1 e2 16             	shl    $0x16,%edx
400041d4:	89 d1                	mov    %edx,%ecx
400041d6:	8b 55 cc             	mov    -0x34(%ebp),%edx
400041d9:	01 ca                	add    %ecx,%edx
		memset(FILEDATA(ino) + oldsize, 0, newsize - oldsize);
	} else if (newsize > 0) {
		// Shrink the file, but not all the way to empty.
		// Would prefer to use SYS_ZERO to free the file content,
		// but SYS_ZERO isn't guaranteed to work at page granularity.
		sys_get(SYS_PERM, 0, NULL, NULL,
400041db:	81 c2 00 00 00 80    	add    $0x80000000,%edx
400041e1:	c7 45 b0 00 01 00 00 	movl   $0x100,-0x50(%ebp)
400041e8:	66 c7 45 ae 00 00    	movw   $0x0,-0x52(%ebp)
400041ee:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
400041f5:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
400041fc:	89 55 a0             	mov    %edx,-0x60(%ebp)
400041ff:	89 45 9c             	mov    %eax,-0x64(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40004202:	8b 45 b0             	mov    -0x50(%ebp),%eax
40004205:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40004208:	8b 5d a8             	mov    -0x58(%ebp),%ebx
4000420b:	0f b7 55 ae          	movzwl -0x52(%ebp),%edx
4000420f:	8b 75 a4             	mov    -0x5c(%ebp),%esi
40004212:	8b 7d a0             	mov    -0x60(%ebp),%edi
40004215:	8b 4d 9c             	mov    -0x64(%ebp),%ecx
40004218:	cd 30                	int    $0x30
4000421a:	eb 48                	jmp    40004264 <fileino_truncate+0x232>
			FILEDATA(ino) + newpagelim, FILE_MAXSIZE - newpagelim);
	} else {
		// Shrink the file to empty.  Use SYS_ZERO to free completely.
		sys_get(SYS_ZERO, 0, NULL, NULL, FILEDATA(ino), FILE_MAXSIZE);
4000421c:	8b 45 08             	mov    0x8(%ebp),%eax
4000421f:	c1 e0 16             	shl    $0x16,%eax
40004222:	05 00 00 00 80       	add    $0x80000000,%eax
40004227:	c7 45 98 00 00 01 00 	movl   $0x10000,-0x68(%ebp)
4000422e:	66 c7 45 96 00 00    	movw   $0x0,-0x6a(%ebp)
40004234:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
4000423b:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
40004242:	89 45 88             	mov    %eax,-0x78(%ebp)
40004245:	c7 45 84 00 00 40 00 	movl   $0x400000,-0x7c(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
4000424c:	8b 45 98             	mov    -0x68(%ebp),%eax
4000424f:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40004252:	8b 5d 90             	mov    -0x70(%ebp),%ebx
40004255:	0f b7 55 96          	movzwl -0x6a(%ebp),%edx
40004259:	8b 75 8c             	mov    -0x74(%ebp),%esi
4000425c:	8b 7d 88             	mov    -0x78(%ebp),%edi
4000425f:	8b 4d 84             	mov    -0x7c(%ebp),%ecx
40004262:	cd 30                	int    $0x30
	}
	files->fi[ino].size = newsize;
40004264:	8b 0d ac 5c 00 40    	mov    0x40005cac,%ecx
4000426a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000426d:	8b 55 08             	mov    0x8(%ebp),%edx
40004270:	6b d2 5c             	imul   $0x5c,%edx,%edx
40004273:	01 ca                	add    %ecx,%edx
40004275:	81 c2 5c 10 00 00    	add    $0x105c,%edx
4000427b:	89 02                	mov    %eax,(%edx)
	files->fi[ino].ver++;	// truncation is always an exclusive change
4000427d:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40004282:	8b 55 08             	mov    0x8(%ebp),%edx
40004285:	6b d2 5c             	imul   $0x5c,%edx,%edx
40004288:	01 c2                	add    %eax,%edx
4000428a:	81 c2 54 10 00 00    	add    $0x1054,%edx
40004290:	8b 12                	mov    (%edx),%edx
40004292:	83 c2 01             	add    $0x1,%edx
40004295:	8b 4d 08             	mov    0x8(%ebp),%ecx
40004298:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
4000429b:	01 c8                	add    %ecx,%eax
4000429d:	05 54 10 00 00       	add    $0x1054,%eax
400042a2:	89 10                	mov    %edx,(%eax)
	return 0;
400042a4:	b8 00 00 00 00       	mov    $0x0,%eax
}
400042a9:	81 c4 8c 00 00 00    	add    $0x8c,%esp
400042af:	5b                   	pop    %ebx
400042b0:	5e                   	pop    %esi
400042b1:	5f                   	pop    %edi
400042b2:	5d                   	pop    %ebp
400042b3:	c3                   	ret    

400042b4 <fileino_flush>:

// Flush any outstanding writes on this file to our parent process.
// (XXX should flushes propagate across multiple levels?)
int
fileino_flush(int ino)
{
400042b4:	55                   	push   %ebp
400042b5:	89 e5                	mov    %esp,%ebp
400042b7:	83 ec 18             	sub    $0x18,%esp
	assert(fileino_isvalid(ino));
400042ba:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400042be:	7e 09                	jle    400042c9 <fileino_flush+0x15>
400042c0:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
400042c7:	7e 24                	jle    400042ed <fileino_flush+0x39>
400042c9:	c7 44 24 0c bd 5d 00 	movl   $0x40005dbd,0xc(%esp)
400042d0:	40 
400042d1:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
400042d8:	40 
400042d9:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
400042e0:	00 
400042e1:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
400042e8:	e8 53 e8 ff ff       	call   40002b40 <debug_panic>

	if (files->fi[ino].size > files->fi[ino].rlen)
400042ed:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
400042f3:	8b 45 08             	mov    0x8(%ebp),%eax
400042f6:	6b c0 5c             	imul   $0x5c,%eax,%eax
400042f9:	01 d0                	add    %edx,%eax
400042fb:	05 5c 10 00 00       	add    $0x105c,%eax
40004300:	8b 10                	mov    (%eax),%edx
40004302:	8b 0d ac 5c 00 40    	mov    0x40005cac,%ecx
40004308:	8b 45 08             	mov    0x8(%ebp),%eax
4000430b:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000430e:	01 c8                	add    %ecx,%eax
40004310:	05 68 10 00 00       	add    $0x1068,%eax
40004315:	8b 00                	mov    (%eax),%eax
40004317:	39 c2                	cmp    %eax,%edx
40004319:	76 07                	jbe    40004322 <fileino_flush+0x6e>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000431b:	b8 03 00 00 00       	mov    $0x3,%eax
40004320:	cd 30                	int    $0x30
		sys_ret();	// synchronize and reconcile with parent
	return 0;
40004322:	b8 00 00 00 00       	mov    $0x0,%eax
}
40004327:	c9                   	leave  
40004328:	c3                   	ret    

40004329 <filedesc_alloc>:
// Search the file descriptor table for the first free file descriptor,
// and return a pointer to that file descriptor.
// If no file descriptors are available,
// returns NULL and set errno appropriately.
filedesc *filedesc_alloc(void)
{
40004329:	55                   	push   %ebp
4000432a:	89 e5                	mov    %esp,%ebp
4000432c:	83 ec 10             	sub    $0x10,%esp
	int i;
	for (i = 0; i < OPEN_MAX; i++)
4000432f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
40004336:	eb 2c                	jmp    40004364 <filedesc_alloc+0x3b>
		if (files->fd[i].ino == FILEINO_NULL)
40004338:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
4000433d:	8b 55 fc             	mov    -0x4(%ebp),%edx
40004340:	83 c2 01             	add    $0x1,%edx
40004343:	c1 e2 04             	shl    $0x4,%edx
40004346:	01 d0                	add    %edx,%eax
40004348:	8b 00                	mov    (%eax),%eax
4000434a:	85 c0                	test   %eax,%eax
4000434c:	75 12                	jne    40004360 <filedesc_alloc+0x37>
			return &files->fd[i];
4000434e:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40004353:	8b 55 fc             	mov    -0x4(%ebp),%edx
40004356:	83 c2 01             	add    $0x1,%edx
40004359:	c1 e2 04             	shl    $0x4,%edx
4000435c:	01 d0                	add    %edx,%eax
4000435e:	eb 1d                	jmp    4000437d <filedesc_alloc+0x54>
// If no file descriptors are available,
// returns NULL and set errno appropriately.
filedesc *filedesc_alloc(void)
{
	int i;
	for (i = 0; i < OPEN_MAX; i++)
40004360:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40004364:	81 7d fc ff 00 00 00 	cmpl   $0xff,-0x4(%ebp)
4000436b:	7e cb                	jle    40004338 <filedesc_alloc+0xf>
		if (files->fd[i].ino == FILEINO_NULL)
			return &files->fd[i];
	errno = EMFILE;
4000436d:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40004372:	c7 00 04 00 00 00    	movl   $0x4,(%eax)
	return NULL;
40004378:	b8 00 00 00 00       	mov    $0x0,%eax
}
4000437d:	c9                   	leave  
4000437e:	c3                   	ret    

4000437f <filedesc_open>:
// The 'openflags' determines whether the file is created, truncated, etc.
// Returns the opened file descriptor on success,
// or returns NULL and sets errno on failure.
filedesc *
filedesc_open(filedesc *fd, const char *path, int openflags, mode_t mode)
{
4000437f:	55                   	push   %ebp
40004380:	89 e5                	mov    %esp,%ebp
40004382:	83 ec 28             	sub    $0x28,%esp
	if (!fd && !(fd = filedesc_alloc()))
40004385:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40004389:	75 18                	jne    400043a3 <filedesc_open+0x24>
4000438b:	e8 99 ff ff ff       	call   40004329 <filedesc_alloc>
40004390:	89 45 08             	mov    %eax,0x8(%ebp)
40004393:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40004397:	75 0a                	jne    400043a3 <filedesc_open+0x24>
		return NULL;
40004399:	b8 00 00 00 00       	mov    $0x0,%eax
4000439e:	e9 04 02 00 00       	jmp    400045a7 <filedesc_open+0x228>
	assert(fd->ino == FILEINO_NULL);
400043a3:	8b 45 08             	mov    0x8(%ebp),%eax
400043a6:	8b 00                	mov    (%eax),%eax
400043a8:	85 c0                	test   %eax,%eax
400043aa:	74 24                	je     400043d0 <filedesc_open+0x51>
400043ac:	c7 44 24 0c fc 5d 00 	movl   $0x40005dfc,0xc(%esp)
400043b3:	40 
400043b4:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
400043bb:	40 
400043bc:	c7 44 24 04 00 01 00 	movl   $0x100,0x4(%esp)
400043c3:	00 
400043c4:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
400043cb:	e8 70 e7 ff ff       	call   40002b40 <debug_panic>

	// Determine the complete file mode if it is to be created.
	mode_t createmode = (openflags & O_CREAT) ? S_IFREG | (mode & 0777) : 0;
400043d0:	8b 45 10             	mov    0x10(%ebp),%eax
400043d3:	83 e0 20             	and    $0x20,%eax
400043d6:	85 c0                	test   %eax,%eax
400043d8:	74 0d                	je     400043e7 <filedesc_open+0x68>
400043da:	8b 45 14             	mov    0x14(%ebp),%eax
400043dd:	25 ff 01 00 00       	and    $0x1ff,%eax
400043e2:	80 cc 10             	or     $0x10,%ah
400043e5:	eb 05                	jmp    400043ec <filedesc_open+0x6d>
400043e7:	b8 00 00 00 00       	mov    $0x0,%eax
400043ec:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Walk the directory tree to find the desired directory entry,
	// creating an entry if it doesn't exist and O_CREAT is set.
	int ino = dir_walk(path, createmode);
400043ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
400043f2:	89 44 24 04          	mov    %eax,0x4(%esp)
400043f6:	8b 45 0c             	mov    0xc(%ebp),%eax
400043f9:	89 04 24             	mov    %eax,(%esp)
400043fc:	e8 d7 05 00 00       	call   400049d8 <dir_walk>
40004401:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (ino < 0)
40004404:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40004408:	79 0a                	jns    40004414 <filedesc_open+0x95>
		return NULL;
4000440a:	b8 00 00 00 00       	mov    $0x0,%eax
4000440f:	e9 93 01 00 00       	jmp    400045a7 <filedesc_open+0x228>
	assert(fileino_exists(ino));
40004414:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40004418:	7e 3d                	jle    40004457 <filedesc_open+0xd8>
4000441a:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40004421:	7f 34                	jg     40004457 <filedesc_open+0xd8>
40004423:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004429:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000442c:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000442f:	01 d0                	add    %edx,%eax
40004431:	05 10 10 00 00       	add    $0x1010,%eax
40004436:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000443a:	84 c0                	test   %al,%al
4000443c:	74 19                	je     40004457 <filedesc_open+0xd8>
4000443e:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004444:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004447:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000444a:	01 d0                	add    %edx,%eax
4000444c:	05 58 10 00 00       	add    $0x1058,%eax
40004451:	8b 00                	mov    (%eax),%eax
40004453:	85 c0                	test   %eax,%eax
40004455:	75 24                	jne    4000447b <filedesc_open+0xfc>
40004457:	c7 44 24 0c 91 5d 00 	movl   $0x40005d91,0xc(%esp)
4000445e:	40 
4000445f:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
40004466:	40 
40004467:	c7 44 24 04 0a 01 00 	movl   $0x10a,0x4(%esp)
4000446e:	00 
4000446f:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
40004476:	e8 c5 e6 ff ff       	call   40002b40 <debug_panic>

	// Refuse to open conflict-marked files;
	// the user needs to resolve the conflict and clear the conflict flag,
	// or just delete the conflicted file.
	if (files->fi[ino].mode & S_IFCONF) {
4000447b:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004481:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004484:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004487:	01 d0                	add    %edx,%eax
40004489:	05 58 10 00 00       	add    $0x1058,%eax
4000448e:	8b 00                	mov    (%eax),%eax
40004490:	25 00 00 01 00       	and    $0x10000,%eax
40004495:	85 c0                	test   %eax,%eax
40004497:	74 15                	je     400044ae <filedesc_open+0x12f>
		errno = ECONFLICT;
40004499:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
4000449e:	c7 00 0a 00 00 00    	movl   $0xa,(%eax)
		return NULL;
400044a4:	b8 00 00 00 00       	mov    $0x0,%eax
400044a9:	e9 f9 00 00 00       	jmp    400045a7 <filedesc_open+0x228>
	}

	// Truncate the file if we were asked to
	if (openflags & O_TRUNC) {
400044ae:	8b 45 10             	mov    0x10(%ebp),%eax
400044b1:	83 e0 40             	and    $0x40,%eax
400044b4:	85 c0                	test   %eax,%eax
400044b6:	74 5c                	je     40004514 <filedesc_open+0x195>
		if (!(openflags & O_WRONLY)) {
400044b8:	8b 45 10             	mov    0x10(%ebp),%eax
400044bb:	83 e0 02             	and    $0x2,%eax
400044be:	85 c0                	test   %eax,%eax
400044c0:	75 31                	jne    400044f3 <filedesc_open+0x174>
			warn("filedesc_open: can't truncate non-writable file");
400044c2:	c7 44 24 08 14 5e 00 	movl   $0x40005e14,0x8(%esp)
400044c9:	40 
400044ca:	c7 44 24 04 17 01 00 	movl   $0x117,0x4(%esp)
400044d1:	00 
400044d2:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
400044d9:	e8 cc e6 ff ff       	call   40002baa <debug_warn>
			errno = EINVAL;
400044de:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
400044e3:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
			return NULL;
400044e9:	b8 00 00 00 00       	mov    $0x0,%eax
400044ee:	e9 b4 00 00 00       	jmp    400045a7 <filedesc_open+0x228>
		}
		if (fileino_truncate(ino, 0) < 0)
400044f3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400044fa:	00 
400044fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
400044fe:	89 04 24             	mov    %eax,(%esp)
40004501:	e8 2c fb ff ff       	call   40004032 <fileino_truncate>
40004506:	85 c0                	test   %eax,%eax
40004508:	79 0a                	jns    40004514 <filedesc_open+0x195>
			return NULL;
4000450a:	b8 00 00 00 00       	mov    $0x0,%eax
4000450f:	e9 93 00 00 00       	jmp    400045a7 <filedesc_open+0x228>
	}

	// Initialize the file descriptor
	fd->ino = ino;
40004514:	8b 45 08             	mov    0x8(%ebp),%eax
40004517:	8b 55 f0             	mov    -0x10(%ebp),%edx
4000451a:	89 10                	mov    %edx,(%eax)
	fd->flags = openflags;
4000451c:	8b 45 08             	mov    0x8(%ebp),%eax
4000451f:	8b 55 10             	mov    0x10(%ebp),%edx
40004522:	89 50 04             	mov    %edx,0x4(%eax)
	fd->ofs = (openflags & O_APPEND) ? files->fi[ino].size : 0;
40004525:	8b 45 10             	mov    0x10(%ebp),%eax
40004528:	83 e0 10             	and    $0x10,%eax
4000452b:	85 c0                	test   %eax,%eax
4000452d:	74 17                	je     40004546 <filedesc_open+0x1c7>
4000452f:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004535:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004538:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000453b:	01 d0                	add    %edx,%eax
4000453d:	05 5c 10 00 00       	add    $0x105c,%eax
40004542:	8b 00                	mov    (%eax),%eax
40004544:	eb 05                	jmp    4000454b <filedesc_open+0x1cc>
40004546:	b8 00 00 00 00       	mov    $0x0,%eax
4000454b:	8b 55 08             	mov    0x8(%ebp),%edx
4000454e:	89 42 08             	mov    %eax,0x8(%edx)
	fd->err = 0;
40004551:	8b 45 08             	mov    0x8(%ebp),%eax
40004554:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)

	assert(filedesc_isopen(fd));
4000455b:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40004560:	83 c0 10             	add    $0x10,%eax
40004563:	3b 45 08             	cmp    0x8(%ebp),%eax
40004566:	77 18                	ja     40004580 <filedesc_open+0x201>
40004568:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
4000456d:	05 10 10 00 00       	add    $0x1010,%eax
40004572:	3b 45 08             	cmp    0x8(%ebp),%eax
40004575:	76 09                	jbe    40004580 <filedesc_open+0x201>
40004577:	8b 45 08             	mov    0x8(%ebp),%eax
4000457a:	8b 00                	mov    (%eax),%eax
4000457c:	85 c0                	test   %eax,%eax
4000457e:	75 24                	jne    400045a4 <filedesc_open+0x225>
40004580:	c7 44 24 0c 44 5e 00 	movl   $0x40005e44,0xc(%esp)
40004587:	40 
40004588:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
4000458f:	40 
40004590:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
40004597:	00 
40004598:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
4000459f:	e8 9c e5 ff ff       	call   40002b40 <debug_panic>
	return fd;
400045a4:	8b 45 08             	mov    0x8(%ebp),%eax
}
400045a7:	c9                   	leave  
400045a8:	c3                   	ret    

400045a9 <filedesc_read>:
// If the file is a special device input file such as the console,
// this function pretends the file has no end and instead
// uses sys_ret() to wait for the file to extend the special file.
ssize_t
filedesc_read(filedesc *fd, void *buf, size_t eltsize, size_t count)
{
400045a9:	55                   	push   %ebp
400045aa:	89 e5                	mov    %esp,%ebp
400045ac:	83 ec 38             	sub    $0x38,%esp
	assert(filedesc_isreadable(fd));
400045af:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
400045b4:	83 c0 10             	add    $0x10,%eax
400045b7:	3b 45 08             	cmp    0x8(%ebp),%eax
400045ba:	77 25                	ja     400045e1 <filedesc_read+0x38>
400045bc:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
400045c1:	05 10 10 00 00       	add    $0x1010,%eax
400045c6:	3b 45 08             	cmp    0x8(%ebp),%eax
400045c9:	76 16                	jbe    400045e1 <filedesc_read+0x38>
400045cb:	8b 45 08             	mov    0x8(%ebp),%eax
400045ce:	8b 00                	mov    (%eax),%eax
400045d0:	85 c0                	test   %eax,%eax
400045d2:	74 0d                	je     400045e1 <filedesc_read+0x38>
400045d4:	8b 45 08             	mov    0x8(%ebp),%eax
400045d7:	8b 40 04             	mov    0x4(%eax),%eax
400045da:	83 e0 01             	and    $0x1,%eax
400045dd:	85 c0                	test   %eax,%eax
400045df:	75 24                	jne    40004605 <filedesc_read+0x5c>
400045e1:	c7 44 24 0c 58 5e 00 	movl   $0x40005e58,0xc(%esp)
400045e8:	40 
400045e9:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
400045f0:	40 
400045f1:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
400045f8:	00 
400045f9:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
40004600:	e8 3b e5 ff ff       	call   40002b40 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40004605:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
4000460b:	8b 45 08             	mov    0x8(%ebp),%eax
4000460e:	8b 00                	mov    (%eax),%eax
40004610:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004613:	05 10 10 00 00       	add    $0x1010,%eax
40004618:	01 d0                	add    %edx,%eax
4000461a:	89 45 f4             	mov    %eax,-0xc(%ebp)

	ssize_t actual = fileino_read(fd->ino, fd->ofs, buf, eltsize, count);
4000461d:	8b 45 08             	mov    0x8(%ebp),%eax
40004620:	8b 50 08             	mov    0x8(%eax),%edx
40004623:	8b 45 08             	mov    0x8(%ebp),%eax
40004626:	8b 00                	mov    (%eax),%eax
40004628:	8b 4d 14             	mov    0x14(%ebp),%ecx
4000462b:	89 4c 24 10          	mov    %ecx,0x10(%esp)
4000462f:	8b 4d 10             	mov    0x10(%ebp),%ecx
40004632:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
40004636:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40004639:	89 4c 24 08          	mov    %ecx,0x8(%esp)
4000463d:	89 54 24 04          	mov    %edx,0x4(%esp)
40004641:	89 04 24             	mov    %eax,(%esp)
40004644:	e8 93 f4 ff ff       	call   40003adc <fileino_read>
40004649:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (actual < 0) {
4000464c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40004650:	79 14                	jns    40004666 <filedesc_read+0xbd>
		fd->err = errno;	// save error indication for ferror()
40004652:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40004657:	8b 10                	mov    (%eax),%edx
40004659:	8b 45 08             	mov    0x8(%ebp),%eax
4000465c:	89 50 0c             	mov    %edx,0xc(%eax)
		return -1;
4000465f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40004664:	eb 56                	jmp    400046bc <filedesc_read+0x113>
	}

	// Advance the file position
	fd->ofs += eltsize * actual;
40004666:	8b 45 08             	mov    0x8(%ebp),%eax
40004669:	8b 40 08             	mov    0x8(%eax),%eax
4000466c:	89 c2                	mov    %eax,%edx
4000466e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004671:	0f af 45 10          	imul   0x10(%ebp),%eax
40004675:	01 d0                	add    %edx,%eax
40004677:	89 c2                	mov    %eax,%edx
40004679:	8b 45 08             	mov    0x8(%ebp),%eax
4000467c:	89 50 08             	mov    %edx,0x8(%eax)
	assert(actual == 0 || fi->size >= fd->ofs);
4000467f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40004683:	74 34                	je     400046b9 <filedesc_read+0x110>
40004685:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004688:	8b 50 4c             	mov    0x4c(%eax),%edx
4000468b:	8b 45 08             	mov    0x8(%ebp),%eax
4000468e:	8b 40 08             	mov    0x8(%eax),%eax
40004691:	39 c2                	cmp    %eax,%edx
40004693:	73 24                	jae    400046b9 <filedesc_read+0x110>
40004695:	c7 44 24 0c 70 5e 00 	movl   $0x40005e70,0xc(%esp)
4000469c:	40 
4000469d:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
400046a4:	40 
400046a5:	c7 44 24 04 42 01 00 	movl   $0x142,0x4(%esp)
400046ac:	00 
400046ad:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
400046b4:	e8 87 e4 ff ff       	call   40002b40 <debug_panic>

	return actual;
400046b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
400046bc:	c9                   	leave  
400046bd:	c3                   	ret    

400046be <filedesc_write>:
// The size of 'buf' must be at least 'count * eltsize' bytes.
// On success, returns the number of objects written (NOT the number of bytes).
// If an error occurs, returns -1 and sets errno appropriately.
ssize_t
filedesc_write(filedesc *fd, const void *buf, size_t eltsize, size_t count)
{
400046be:	55                   	push   %ebp
400046bf:	89 e5                	mov    %esp,%ebp
400046c1:	83 ec 38             	sub    $0x38,%esp
	assert(filedesc_iswritable(fd));
400046c4:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
400046c9:	83 c0 10             	add    $0x10,%eax
400046cc:	3b 45 08             	cmp    0x8(%ebp),%eax
400046cf:	77 25                	ja     400046f6 <filedesc_write+0x38>
400046d1:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
400046d6:	05 10 10 00 00       	add    $0x1010,%eax
400046db:	3b 45 08             	cmp    0x8(%ebp),%eax
400046de:	76 16                	jbe    400046f6 <filedesc_write+0x38>
400046e0:	8b 45 08             	mov    0x8(%ebp),%eax
400046e3:	8b 00                	mov    (%eax),%eax
400046e5:	85 c0                	test   %eax,%eax
400046e7:	74 0d                	je     400046f6 <filedesc_write+0x38>
400046e9:	8b 45 08             	mov    0x8(%ebp),%eax
400046ec:	8b 40 04             	mov    0x4(%eax),%eax
400046ef:	83 e0 02             	and    $0x2,%eax
400046f2:	85 c0                	test   %eax,%eax
400046f4:	75 24                	jne    4000471a <filedesc_write+0x5c>
400046f6:	c7 44 24 0c 93 5e 00 	movl   $0x40005e93,0xc(%esp)
400046fd:	40 
400046fe:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
40004705:	40 
40004706:	c7 44 24 04 4f 01 00 	movl   $0x14f,0x4(%esp)
4000470d:	00 
4000470e:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
40004715:	e8 26 e4 ff ff       	call   40002b40 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
4000471a:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004720:	8b 45 08             	mov    0x8(%ebp),%eax
40004723:	8b 00                	mov    (%eax),%eax
40004725:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004728:	05 10 10 00 00       	add    $0x1010,%eax
4000472d:	01 d0                	add    %edx,%eax
4000472f:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// If we're appending to the file, seek to the end first.
	if (fd->flags & O_APPEND)
40004732:	8b 45 08             	mov    0x8(%ebp),%eax
40004735:	8b 40 04             	mov    0x4(%eax),%eax
40004738:	83 e0 10             	and    $0x10,%eax
4000473b:	85 c0                	test   %eax,%eax
4000473d:	74 0e                	je     4000474d <filedesc_write+0x8f>
		fd->ofs = fi->size;
4000473f:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004742:	8b 40 4c             	mov    0x4c(%eax),%eax
40004745:	89 c2                	mov    %eax,%edx
40004747:	8b 45 08             	mov    0x8(%ebp),%eax
4000474a:	89 50 08             	mov    %edx,0x8(%eax)

	// Write the data, growing the file as necessary.
	ssize_t actual = fileino_write(fd->ino, fd->ofs, buf, eltsize, count);
4000474d:	8b 45 08             	mov    0x8(%ebp),%eax
40004750:	8b 50 08             	mov    0x8(%eax),%edx
40004753:	8b 45 08             	mov    0x8(%ebp),%eax
40004756:	8b 00                	mov    (%eax),%eax
40004758:	8b 4d 14             	mov    0x14(%ebp),%ecx
4000475b:	89 4c 24 10          	mov    %ecx,0x10(%esp)
4000475f:	8b 4d 10             	mov    0x10(%ebp),%ecx
40004762:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
40004766:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40004769:	89 4c 24 08          	mov    %ecx,0x8(%esp)
4000476d:	89 54 24 04          	mov    %edx,0x4(%esp)
40004771:	89 04 24             	mov    %eax,(%esp)
40004774:	e8 f9 f4 ff ff       	call   40003c72 <fileino_write>
40004779:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (actual < 0) {
4000477c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40004780:	79 17                	jns    40004799 <filedesc_write+0xdb>
		fd->err = errno;	// save error indication for ferror()
40004782:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40004787:	8b 10                	mov    (%eax),%edx
40004789:	8b 45 08             	mov    0x8(%ebp),%eax
4000478c:	89 50 0c             	mov    %edx,0xc(%eax)
		return -1;
4000478f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40004794:	e9 98 00 00 00       	jmp    40004831 <filedesc_write+0x173>
	}
	assert(actual == count);
40004799:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000479c:	3b 45 14             	cmp    0x14(%ebp),%eax
4000479f:	74 24                	je     400047c5 <filedesc_write+0x107>
400047a1:	c7 44 24 0c ab 5e 00 	movl   $0x40005eab,0xc(%esp)
400047a8:	40 
400047a9:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
400047b0:	40 
400047b1:	c7 44 24 04 5c 01 00 	movl   $0x15c,0x4(%esp)
400047b8:	00 
400047b9:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
400047c0:	e8 7b e3 ff ff       	call   40002b40 <debug_panic>

	// Non-append-only writes constitute exclusive modifications,
	// so must bump the file's version number.
	if (!(fd->flags & O_APPEND))
400047c5:	8b 45 08             	mov    0x8(%ebp),%eax
400047c8:	8b 40 04             	mov    0x4(%eax),%eax
400047cb:	83 e0 10             	and    $0x10,%eax
400047ce:	85 c0                	test   %eax,%eax
400047d0:	75 0f                	jne    400047e1 <filedesc_write+0x123>
		fi->ver++;
400047d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
400047d5:	8b 40 44             	mov    0x44(%eax),%eax
400047d8:	8d 50 01             	lea    0x1(%eax),%edx
400047db:	8b 45 f4             	mov    -0xc(%ebp),%eax
400047de:	89 50 44             	mov    %edx,0x44(%eax)

	// Advance the file position
	fd->ofs += eltsize * count;
400047e1:	8b 45 08             	mov    0x8(%ebp),%eax
400047e4:	8b 40 08             	mov    0x8(%eax),%eax
400047e7:	89 c2                	mov    %eax,%edx
400047e9:	8b 45 10             	mov    0x10(%ebp),%eax
400047ec:	0f af 45 14          	imul   0x14(%ebp),%eax
400047f0:	01 d0                	add    %edx,%eax
400047f2:	89 c2                	mov    %eax,%edx
400047f4:	8b 45 08             	mov    0x8(%ebp),%eax
400047f7:	89 50 08             	mov    %edx,0x8(%eax)
	assert(fi->size >= fd->ofs);
400047fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
400047fd:	8b 50 4c             	mov    0x4c(%eax),%edx
40004800:	8b 45 08             	mov    0x8(%ebp),%eax
40004803:	8b 40 08             	mov    0x8(%eax),%eax
40004806:	39 c2                	cmp    %eax,%edx
40004808:	73 24                	jae    4000482e <filedesc_write+0x170>
4000480a:	c7 44 24 0c bb 5e 00 	movl   $0x40005ebb,0xc(%esp)
40004811:	40 
40004812:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
40004819:	40 
4000481a:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
40004821:	00 
40004822:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
40004829:	e8 12 e3 ff ff       	call   40002b40 <debug_panic>
	return count;
4000482e:	8b 45 14             	mov    0x14(%ebp),%eax
}
40004831:	c9                   	leave  
40004832:	c3                   	ret    

40004833 <filedesc_seek>:
// which may be relative to the file start, end, or corrent position,
// depending on 'whence' (SEEK_SET, SEEK_CUR, or SEEK_END).
// Returns the resulting absolute file position,
// or returns -1 and sets errno appropriately on error.
off_t filedesc_seek(filedesc *fd, off_t offset, int whence)
{
40004833:	55                   	push   %ebp
40004834:	89 e5                	mov    %esp,%ebp
40004836:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isopen(fd));
40004839:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
4000483e:	83 c0 10             	add    $0x10,%eax
40004841:	3b 45 08             	cmp    0x8(%ebp),%eax
40004844:	77 18                	ja     4000485e <filedesc_seek+0x2b>
40004846:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
4000484b:	05 10 10 00 00       	add    $0x1010,%eax
40004850:	3b 45 08             	cmp    0x8(%ebp),%eax
40004853:	76 09                	jbe    4000485e <filedesc_seek+0x2b>
40004855:	8b 45 08             	mov    0x8(%ebp),%eax
40004858:	8b 00                	mov    (%eax),%eax
4000485a:	85 c0                	test   %eax,%eax
4000485c:	75 24                	jne    40004882 <filedesc_seek+0x4f>
4000485e:	c7 44 24 0c 44 5e 00 	movl   $0x40005e44,0xc(%esp)
40004865:	40 
40004866:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
4000486d:	40 
4000486e:	c7 44 24 04 70 01 00 	movl   $0x170,0x4(%esp)
40004875:	00 
40004876:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
4000487d:	e8 be e2 ff ff       	call   40002b40 <debug_panic>
	assert(whence == SEEK_SET || whence == SEEK_CUR || whence == SEEK_END);
40004882:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40004886:	74 30                	je     400048b8 <filedesc_seek+0x85>
40004888:	83 7d 10 01          	cmpl   $0x1,0x10(%ebp)
4000488c:	74 2a                	je     400048b8 <filedesc_seek+0x85>
4000488e:	83 7d 10 02          	cmpl   $0x2,0x10(%ebp)
40004892:	74 24                	je     400048b8 <filedesc_seek+0x85>
40004894:	c7 44 24 0c d0 5e 00 	movl   $0x40005ed0,0xc(%esp)
4000489b:	40 
4000489c:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
400048a3:	40 
400048a4:	c7 44 24 04 71 01 00 	movl   $0x171,0x4(%esp)
400048ab:	00 
400048ac:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
400048b3:	e8 88 e2 ff ff       	call   40002b40 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
400048b8:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
400048be:	8b 45 08             	mov    0x8(%ebp),%eax
400048c1:	8b 00                	mov    (%eax),%eax
400048c3:	6b c0 5c             	imul   $0x5c,%eax,%eax
400048c6:	05 10 10 00 00       	add    $0x1010,%eax
400048cb:	01 d0                	add    %edx,%eax
400048cd:	89 45 f4             	mov    %eax,-0xc(%ebp)
	ino_t ino = fd->ino;
400048d0:	8b 45 08             	mov    0x8(%ebp),%eax
400048d3:	8b 00                	mov    (%eax),%eax
400048d5:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint8_t* start_pos = FILEDATA(ino);
400048d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
400048db:	c1 e0 16             	shl    $0x16,%eax
400048de:	05 00 00 00 80       	add    $0x80000000,%eax
400048e3:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// Lab 4: insert your file descriptor seek implementation here.
	//warn("filedesc_seek() not implemented");
	//errno = EINVAL;
	//return -1;
	switch(whence){
400048e6:	8b 45 10             	mov    0x10(%ebp),%eax
400048e9:	83 f8 01             	cmp    $0x1,%eax
400048ec:	74 14                	je     40004902 <filedesc_seek+0xcf>
400048ee:	83 f8 02             	cmp    $0x2,%eax
400048f1:	74 22                	je     40004915 <filedesc_seek+0xe2>
400048f3:	85 c0                	test   %eax,%eax
400048f5:	75 33                	jne    4000492a <filedesc_seek+0xf7>
	case SEEK_SET:
		fd->ofs = offset;
400048f7:	8b 45 08             	mov    0x8(%ebp),%eax
400048fa:	8b 55 0c             	mov    0xc(%ebp),%edx
400048fd:	89 50 08             	mov    %edx,0x8(%eax)
		break;
40004900:	eb 3a                	jmp    4000493c <filedesc_seek+0x109>
	case SEEK_CUR:
		fd->ofs += offset;
40004902:	8b 45 08             	mov    0x8(%ebp),%eax
40004905:	8b 50 08             	mov    0x8(%eax),%edx
40004908:	8b 45 0c             	mov    0xc(%ebp),%eax
4000490b:	01 c2                	add    %eax,%edx
4000490d:	8b 45 08             	mov    0x8(%ebp),%eax
40004910:	89 50 08             	mov    %edx,0x8(%eax)
		break;
40004913:	eb 27                	jmp    4000493c <filedesc_seek+0x109>
	case SEEK_END:
		fd->ofs = (fi->size) + offset;
40004915:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004918:	8b 50 4c             	mov    0x4c(%eax),%edx
4000491b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000491e:	01 d0                	add    %edx,%eax
40004920:	89 c2                	mov    %eax,%edx
40004922:	8b 45 08             	mov    0x8(%ebp),%eax
40004925:	89 50 08             	mov    %edx,0x8(%eax)
		break;
40004928:	eb 12                	jmp    4000493c <filedesc_seek+0x109>
	default:
		errno = EINVAL;
4000492a:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
4000492f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
		return -1;
40004935:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
4000493a:	eb 06                	jmp    40004942 <filedesc_seek+0x10f>
	}
	return fd->ofs;
4000493c:	8b 45 08             	mov    0x8(%ebp),%eax
4000493f:	8b 40 08             	mov    0x8(%eax),%eax
}
40004942:	c9                   	leave  
40004943:	c3                   	ret    

40004944 <filedesc_close>:

void
filedesc_close(filedesc *fd)
{
40004944:	55                   	push   %ebp
40004945:	89 e5                	mov    %esp,%ebp
40004947:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
4000494a:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
4000494f:	83 c0 10             	add    $0x10,%eax
40004952:	3b 45 08             	cmp    0x8(%ebp),%eax
40004955:	77 18                	ja     4000496f <filedesc_close+0x2b>
40004957:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
4000495c:	05 10 10 00 00       	add    $0x1010,%eax
40004961:	3b 45 08             	cmp    0x8(%ebp),%eax
40004964:	76 09                	jbe    4000496f <filedesc_close+0x2b>
40004966:	8b 45 08             	mov    0x8(%ebp),%eax
40004969:	8b 00                	mov    (%eax),%eax
4000496b:	85 c0                	test   %eax,%eax
4000496d:	75 24                	jne    40004993 <filedesc_close+0x4f>
4000496f:	c7 44 24 0c 44 5e 00 	movl   $0x40005e44,0xc(%esp)
40004976:	40 
40004977:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
4000497e:	40 
4000497f:	c7 44 24 04 8e 01 00 	movl   $0x18e,0x4(%esp)
40004986:	00 
40004987:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
4000498e:	e8 ad e1 ff ff       	call   40002b40 <debug_panic>
	assert(fileino_isvalid(fd->ino));
40004993:	8b 45 08             	mov    0x8(%ebp),%eax
40004996:	8b 00                	mov    (%eax),%eax
40004998:	85 c0                	test   %eax,%eax
4000499a:	7e 0c                	jle    400049a8 <filedesc_close+0x64>
4000499c:	8b 45 08             	mov    0x8(%ebp),%eax
4000499f:	8b 00                	mov    (%eax),%eax
400049a1:	3d ff 00 00 00       	cmp    $0xff,%eax
400049a6:	7e 24                	jle    400049cc <filedesc_close+0x88>
400049a8:	c7 44 24 0c 0f 5f 00 	movl   $0x40005f0f,0xc(%esp)
400049af:	40 
400049b0:	c7 44 24 08 e4 5c 00 	movl   $0x40005ce4,0x8(%esp)
400049b7:	40 
400049b8:	c7 44 24 04 8f 01 00 	movl   $0x18f,0x4(%esp)
400049bf:	00 
400049c0:	c7 04 24 cf 5c 00 40 	movl   $0x40005ccf,(%esp)
400049c7:	e8 74 e1 ff ff       	call   40002b40 <debug_panic>

	fd->ino = FILEINO_NULL;		// mark the fd free
400049cc:	8b 45 08             	mov    0x8(%ebp),%eax
400049cf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
400049d5:	c9                   	leave  
400049d6:	c3                   	ret    
400049d7:	90                   	nop

400049d8 <dir_walk>:
#include <inc/dirent.h>


int
dir_walk(const char *path, mode_t createmode)
{
400049d8:	55                   	push   %ebp
400049d9:	89 e5                	mov    %esp,%ebp
400049db:	83 ec 28             	sub    $0x28,%esp
	assert(path != 0 && *path != 0);
400049de:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400049e2:	74 0a                	je     400049ee <dir_walk+0x16>
400049e4:	8b 45 08             	mov    0x8(%ebp),%eax
400049e7:	0f b6 00             	movzbl (%eax),%eax
400049ea:	84 c0                	test   %al,%al
400049ec:	75 24                	jne    40004a12 <dir_walk+0x3a>
400049ee:	c7 44 24 0c 28 5f 00 	movl   $0x40005f28,0xc(%esp)
400049f5:	40 
400049f6:	c7 44 24 08 40 5f 00 	movl   $0x40005f40,0x8(%esp)
400049fd:	40 
400049fe:	c7 44 24 04 15 00 00 	movl   $0x15,0x4(%esp)
40004a05:	00 
40004a06:	c7 04 24 55 5f 00 40 	movl   $0x40005f55,(%esp)
40004a0d:	e8 2e e1 ff ff       	call   40002b40 <debug_panic>

	// Start at the current or root directory as appropriate
	int dino = files->cwd;
40004a12:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40004a17:	8b 40 04             	mov    0x4(%eax),%eax
40004a1a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (*path == '/') {
40004a1d:	8b 45 08             	mov    0x8(%ebp),%eax
40004a20:	0f b6 00             	movzbl (%eax),%eax
40004a23:	3c 2f                	cmp    $0x2f,%al
40004a25:	75 27                	jne    40004a4e <dir_walk+0x76>
		dino = FILEINO_ROOTDIR;
40004a27:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
		do { path++; } while (*path == '/');	// skip leading slashes
40004a2e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40004a32:	8b 45 08             	mov    0x8(%ebp),%eax
40004a35:	0f b6 00             	movzbl (%eax),%eax
40004a38:	3c 2f                	cmp    $0x2f,%al
40004a3a:	74 f2                	je     40004a2e <dir_walk+0x56>
		if (*path == 0)
40004a3c:	8b 45 08             	mov    0x8(%ebp),%eax
40004a3f:	0f b6 00             	movzbl (%eax),%eax
40004a42:	84 c0                	test   %al,%al
40004a44:	75 08                	jne    40004a4e <dir_walk+0x76>
			return dino;	// Just looking up root directory
40004a46:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004a49:	e9 61 05 00 00       	jmp    40004faf <dir_walk+0x5d7>
	}

	// Search for the appropriate entry in this directory
	searchdir:
	assert(fileino_isdir(dino));
40004a4e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40004a52:	7e 45                	jle    40004a99 <dir_walk+0xc1>
40004a54:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
40004a5b:	7f 3c                	jg     40004a99 <dir_walk+0xc1>
40004a5d:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004a63:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004a66:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004a69:	01 d0                	add    %edx,%eax
40004a6b:	05 10 10 00 00       	add    $0x1010,%eax
40004a70:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004a74:	84 c0                	test   %al,%al
40004a76:	74 21                	je     40004a99 <dir_walk+0xc1>
40004a78:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004a7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004a81:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004a84:	01 d0                	add    %edx,%eax
40004a86:	05 58 10 00 00       	add    $0x1058,%eax
40004a8b:	8b 00                	mov    (%eax),%eax
40004a8d:	25 00 70 00 00       	and    $0x7000,%eax
40004a92:	3d 00 20 00 00       	cmp    $0x2000,%eax
40004a97:	74 24                	je     40004abd <dir_walk+0xe5>
40004a99:	c7 44 24 0c 5f 5f 00 	movl   $0x40005f5f,0xc(%esp)
40004aa0:	40 
40004aa1:	c7 44 24 08 40 5f 00 	movl   $0x40005f40,0x8(%esp)
40004aa8:	40 
40004aa9:	c7 44 24 04 22 00 00 	movl   $0x22,0x4(%esp)
40004ab0:	00 
40004ab1:	c7 04 24 55 5f 00 40 	movl   $0x40005f55,(%esp)
40004ab8:	e8 83 e0 ff ff       	call   40002b40 <debug_panic>
	assert(fileino_isdir(files->fi[dino].dino));
40004abd:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004ac3:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004ac6:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004ac9:	01 d0                	add    %edx,%eax
40004acb:	05 10 10 00 00       	add    $0x1010,%eax
40004ad0:	8b 00                	mov    (%eax),%eax
40004ad2:	85 c0                	test   %eax,%eax
40004ad4:	7e 7c                	jle    40004b52 <dir_walk+0x17a>
40004ad6:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004adc:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004adf:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004ae2:	01 d0                	add    %edx,%eax
40004ae4:	05 10 10 00 00       	add    $0x1010,%eax
40004ae9:	8b 00                	mov    (%eax),%eax
40004aeb:	3d ff 00 00 00       	cmp    $0xff,%eax
40004af0:	7f 60                	jg     40004b52 <dir_walk+0x17a>
40004af2:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004af8:	8b 0d ac 5c 00 40    	mov    0x40005cac,%ecx
40004afe:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004b01:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004b04:	01 c8                	add    %ecx,%eax
40004b06:	05 10 10 00 00       	add    $0x1010,%eax
40004b0b:	8b 00                	mov    (%eax),%eax
40004b0d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004b10:	01 d0                	add    %edx,%eax
40004b12:	05 10 10 00 00       	add    $0x1010,%eax
40004b17:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004b1b:	84 c0                	test   %al,%al
40004b1d:	74 33                	je     40004b52 <dir_walk+0x17a>
40004b1f:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004b25:	8b 0d ac 5c 00 40    	mov    0x40005cac,%ecx
40004b2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004b2e:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004b31:	01 c8                	add    %ecx,%eax
40004b33:	05 10 10 00 00       	add    $0x1010,%eax
40004b38:	8b 00                	mov    (%eax),%eax
40004b3a:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004b3d:	01 d0                	add    %edx,%eax
40004b3f:	05 58 10 00 00       	add    $0x1058,%eax
40004b44:	8b 00                	mov    (%eax),%eax
40004b46:	25 00 70 00 00       	and    $0x7000,%eax
40004b4b:	3d 00 20 00 00       	cmp    $0x2000,%eax
40004b50:	74 24                	je     40004b76 <dir_walk+0x19e>
40004b52:	c7 44 24 0c 74 5f 00 	movl   $0x40005f74,0xc(%esp)
40004b59:	40 
40004b5a:	c7 44 24 08 40 5f 00 	movl   $0x40005f40,0x8(%esp)
40004b61:	40 
40004b62:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
40004b69:	00 
40004b6a:	c7 04 24 55 5f 00 40 	movl   $0x40005f55,(%esp)
40004b71:	e8 ca df ff ff       	call   40002b40 <debug_panic>

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
40004b76:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
40004b7d:	e9 3d 02 00 00       	jmp    40004dbf <dir_walk+0x3e7>
		if (!fileino_alloced(ino) || files->fi[ino].dino != dino)
40004b82:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40004b86:	0f 8e 28 02 00 00    	jle    40004db4 <dir_walk+0x3dc>
40004b8c:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40004b93:	0f 8f 1b 02 00 00    	jg     40004db4 <dir_walk+0x3dc>
40004b99:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004b9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004ba2:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004ba5:	01 d0                	add    %edx,%eax
40004ba7:	05 10 10 00 00       	add    $0x1010,%eax
40004bac:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004bb0:	84 c0                	test   %al,%al
40004bb2:	0f 84 fc 01 00 00    	je     40004db4 <dir_walk+0x3dc>
40004bb8:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004bbe:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004bc1:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004bc4:	01 d0                	add    %edx,%eax
40004bc6:	05 10 10 00 00       	add    $0x1010,%eax
40004bcb:	8b 00                	mov    (%eax),%eax
40004bcd:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40004bd0:	0f 85 de 01 00 00    	jne    40004db4 <dir_walk+0x3dc>
			continue;	// not an entry in directory 'dino'

		// Does this inode's name match our next path component?
		len = strlen(files->fi[ino].de.d_name);
40004bd6:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40004bdb:	8b 55 f0             	mov    -0x10(%ebp),%edx
40004bde:	6b d2 5c             	imul   $0x5c,%edx,%edx
40004be1:	81 c2 10 10 00 00    	add    $0x1010,%edx
40004be7:	01 d0                	add    %edx,%eax
40004be9:	83 c0 04             	add    $0x4,%eax
40004bec:	89 04 24             	mov    %eax,(%esp)
40004bef:	e8 c0 e8 ff ff       	call   400034b4 <strlen>
40004bf4:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (memcmp(path, files->fi[ino].de.d_name, len) != 0)
40004bf7:	8b 45 ec             	mov    -0x14(%ebp),%eax
40004bfa:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004c00:	8b 4d f0             	mov    -0x10(%ebp),%ecx
40004c03:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
40004c06:	81 c1 10 10 00 00    	add    $0x1010,%ecx
40004c0c:	01 ca                	add    %ecx,%edx
40004c0e:	83 c2 04             	add    $0x4,%edx
40004c11:	89 44 24 08          	mov    %eax,0x8(%esp)
40004c15:	89 54 24 04          	mov    %edx,0x4(%esp)
40004c19:	8b 45 08             	mov    0x8(%ebp),%eax
40004c1c:	89 04 24             	mov    %eax,(%esp)
40004c1f:	e8 b6 eb ff ff       	call   400037da <memcmp>
40004c24:	85 c0                	test   %eax,%eax
40004c26:	0f 85 8b 01 00 00    	jne    40004db7 <dir_walk+0x3df>
			continue;	// no match
		found:
		if (path[len] == 0) {
40004c2c:	8b 55 ec             	mov    -0x14(%ebp),%edx
40004c2f:	8b 45 08             	mov    0x8(%ebp),%eax
40004c32:	01 d0                	add    %edx,%eax
40004c34:	0f b6 00             	movzbl (%eax),%eax
40004c37:	84 c0                	test   %al,%al
40004c39:	0f 85 c7 00 00 00    	jne    40004d06 <dir_walk+0x32e>
			// Exact match at end of path - but does it exist?
			if (fileino_exists(ino))
40004c3f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40004c43:	7e 45                	jle    40004c8a <dir_walk+0x2b2>
40004c45:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40004c4c:	7f 3c                	jg     40004c8a <dir_walk+0x2b2>
40004c4e:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004c54:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004c57:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004c5a:	01 d0                	add    %edx,%eax
40004c5c:	05 10 10 00 00       	add    $0x1010,%eax
40004c61:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004c65:	84 c0                	test   %al,%al
40004c67:	74 21                	je     40004c8a <dir_walk+0x2b2>
40004c69:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004c6f:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004c72:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004c75:	01 d0                	add    %edx,%eax
40004c77:	05 58 10 00 00       	add    $0x1058,%eax
40004c7c:	8b 00                	mov    (%eax),%eax
40004c7e:	85 c0                	test   %eax,%eax
40004c80:	74 08                	je     40004c8a <dir_walk+0x2b2>
				return ino;	// yes - return it
40004c82:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004c85:	e9 25 03 00 00       	jmp    40004faf <dir_walk+0x5d7>

			// no - existed, but was deleted.  re-create?
			if (!createmode) {
40004c8a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40004c8e:	75 15                	jne    40004ca5 <dir_walk+0x2cd>
				errno = ENOENT;
40004c90:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40004c95:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
				return -1;
40004c9b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40004ca0:	e9 0a 03 00 00       	jmp    40004faf <dir_walk+0x5d7>
			}
			files->fi[ino].ver++;	// an exclusive change
40004ca5:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40004caa:	8b 55 f0             	mov    -0x10(%ebp),%edx
40004cad:	6b d2 5c             	imul   $0x5c,%edx,%edx
40004cb0:	01 c2                	add    %eax,%edx
40004cb2:	81 c2 54 10 00 00    	add    $0x1054,%edx
40004cb8:	8b 12                	mov    (%edx),%edx
40004cba:	83 c2 01             	add    $0x1,%edx
40004cbd:	8b 4d f0             	mov    -0x10(%ebp),%ecx
40004cc0:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
40004cc3:	01 c8                	add    %ecx,%eax
40004cc5:	05 54 10 00 00       	add    $0x1054,%eax
40004cca:	89 10                	mov    %edx,(%eax)
			files->fi[ino].mode = createmode;
40004ccc:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004cd2:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004cd5:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004cd8:	01 d0                	add    %edx,%eax
40004cda:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
40004ce0:	8b 45 0c             	mov    0xc(%ebp),%eax
40004ce3:	89 02                	mov    %eax,(%edx)
			files->fi[ino].size = 0;
40004ce5:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004ceb:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004cee:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004cf1:	01 d0                	add    %edx,%eax
40004cf3:	05 5c 10 00 00       	add    $0x105c,%eax
40004cf8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			return ino;
40004cfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004d01:	e9 a9 02 00 00       	jmp    40004faf <dir_walk+0x5d7>
		}
		if (path[len] != '/')
40004d06:	8b 55 ec             	mov    -0x14(%ebp),%edx
40004d09:	8b 45 08             	mov    0x8(%ebp),%eax
40004d0c:	01 d0                	add    %edx,%eax
40004d0e:	0f b6 00             	movzbl (%eax),%eax
40004d11:	3c 2f                	cmp    $0x2f,%al
40004d13:	0f 85 a1 00 00 00    	jne    40004dba <dir_walk+0x3e2>
			continue;	// no match

		// Make sure this dirent refers to a directory
		if (!fileino_isdir(ino)) {
40004d19:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40004d1d:	7e 45                	jle    40004d64 <dir_walk+0x38c>
40004d1f:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40004d26:	7f 3c                	jg     40004d64 <dir_walk+0x38c>
40004d28:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004d2e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004d31:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004d34:	01 d0                	add    %edx,%eax
40004d36:	05 10 10 00 00       	add    $0x1010,%eax
40004d3b:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004d3f:	84 c0                	test   %al,%al
40004d41:	74 21                	je     40004d64 <dir_walk+0x38c>
40004d43:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004d49:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004d4c:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004d4f:	01 d0                	add    %edx,%eax
40004d51:	05 58 10 00 00       	add    $0x1058,%eax
40004d56:	8b 00                	mov    (%eax),%eax
40004d58:	25 00 70 00 00       	and    $0x7000,%eax
40004d5d:	3d 00 20 00 00       	cmp    $0x2000,%eax
40004d62:	74 15                	je     40004d79 <dir_walk+0x3a1>
			errno = ENOTDIR;
40004d64:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40004d69:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
			return -1;
40004d6f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40004d74:	e9 36 02 00 00       	jmp    40004faf <dir_walk+0x5d7>
		}

		// Skip slashes to find next component
		do { len++; } while (path[len] == '/');
40004d79:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
40004d7d:	8b 55 ec             	mov    -0x14(%ebp),%edx
40004d80:	8b 45 08             	mov    0x8(%ebp),%eax
40004d83:	01 d0                	add    %edx,%eax
40004d85:	0f b6 00             	movzbl (%eax),%eax
40004d88:	3c 2f                	cmp    $0x2f,%al
40004d8a:	74 ed                	je     40004d79 <dir_walk+0x3a1>
		if (path[len] == 0)
40004d8c:	8b 55 ec             	mov    -0x14(%ebp),%edx
40004d8f:	8b 45 08             	mov    0x8(%ebp),%eax
40004d92:	01 d0                	add    %edx,%eax
40004d94:	0f b6 00             	movzbl (%eax),%eax
40004d97:	84 c0                	test   %al,%al
40004d99:	75 08                	jne    40004da3 <dir_walk+0x3cb>
			return ino;	// matched directory at end of path
40004d9b:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004d9e:	e9 0c 02 00 00       	jmp    40004faf <dir_walk+0x5d7>

		// Walk the next directory in the path
		dino = ino;
40004da3:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004da6:	89 45 f4             	mov    %eax,-0xc(%ebp)
		path += len;
40004da9:	8b 45 ec             	mov    -0x14(%ebp),%eax
40004dac:	01 45 08             	add    %eax,0x8(%ebp)
		goto searchdir;
40004daf:	e9 9a fc ff ff       	jmp    40004a4e <dir_walk+0x76>

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
		if (!fileino_alloced(ino) || files->fi[ino].dino != dino)
			continue;	// not an entry in directory 'dino'
40004db4:	90                   	nop
40004db5:	eb 04                	jmp    40004dbb <dir_walk+0x3e3>

		// Does this inode's name match our next path component?
		len = strlen(files->fi[ino].de.d_name);
		if (memcmp(path, files->fi[ino].de.d_name, len) != 0)
			continue;	// no match
40004db7:	90                   	nop
40004db8:	eb 01                	jmp    40004dbb <dir_walk+0x3e3>
			files->fi[ino].mode = createmode;
			files->fi[ino].size = 0;
			return ino;
		}
		if (path[len] != '/')
			continue;	// no match
40004dba:	90                   	nop
	assert(fileino_isdir(dino));
	assert(fileino_isdir(files->fi[dino].dino));

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
40004dbb:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
40004dbf:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40004dc6:	0f 8e b6 fd ff ff    	jle    40004b82 <dir_walk+0x1aa>
		path += len;
		goto searchdir;
	}

	// Looking for one of the special entries '.' or '..'?
	if (path[0] == '.' && (path[1] == 0 || path[1] == '/')) {
40004dcc:	8b 45 08             	mov    0x8(%ebp),%eax
40004dcf:	0f b6 00             	movzbl (%eax),%eax
40004dd2:	3c 2e                	cmp    $0x2e,%al
40004dd4:	75 2c                	jne    40004e02 <dir_walk+0x42a>
40004dd6:	8b 45 08             	mov    0x8(%ebp),%eax
40004dd9:	83 c0 01             	add    $0x1,%eax
40004ddc:	0f b6 00             	movzbl (%eax),%eax
40004ddf:	84 c0                	test   %al,%al
40004de1:	74 0d                	je     40004df0 <dir_walk+0x418>
40004de3:	8b 45 08             	mov    0x8(%ebp),%eax
40004de6:	83 c0 01             	add    $0x1,%eax
40004de9:	0f b6 00             	movzbl (%eax),%eax
40004dec:	3c 2f                	cmp    $0x2f,%al
40004dee:	75 12                	jne    40004e02 <dir_walk+0x42a>
		len = 1;
40004df0:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		ino = dino;	// just leads to this same directory
40004df7:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004dfa:	89 45 f0             	mov    %eax,-0x10(%ebp)
		goto found;
40004dfd:	e9 2a fe ff ff       	jmp    40004c2c <dir_walk+0x254>
	}
	if (path[0] == '.' && path[1] == '.'
40004e02:	8b 45 08             	mov    0x8(%ebp),%eax
40004e05:	0f b6 00             	movzbl (%eax),%eax
40004e08:	3c 2e                	cmp    $0x2e,%al
40004e0a:	75 4b                	jne    40004e57 <dir_walk+0x47f>
40004e0c:	8b 45 08             	mov    0x8(%ebp),%eax
40004e0f:	83 c0 01             	add    $0x1,%eax
40004e12:	0f b6 00             	movzbl (%eax),%eax
40004e15:	3c 2e                	cmp    $0x2e,%al
40004e17:	75 3e                	jne    40004e57 <dir_walk+0x47f>
			&& (path[2] == 0 || path[2] == '/')) {
40004e19:	8b 45 08             	mov    0x8(%ebp),%eax
40004e1c:	83 c0 02             	add    $0x2,%eax
40004e1f:	0f b6 00             	movzbl (%eax),%eax
40004e22:	84 c0                	test   %al,%al
40004e24:	74 0d                	je     40004e33 <dir_walk+0x45b>
40004e26:	8b 45 08             	mov    0x8(%ebp),%eax
40004e29:	83 c0 02             	add    $0x2,%eax
40004e2c:	0f b6 00             	movzbl (%eax),%eax
40004e2f:	3c 2f                	cmp    $0x2f,%al
40004e31:	75 24                	jne    40004e57 <dir_walk+0x47f>
		len = 2;
40004e33:	c7 45 ec 02 00 00 00 	movl   $0x2,-0x14(%ebp)
		ino = files->fi[dino].dino;	// leads to root directory
40004e3a:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004e40:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004e43:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004e46:	01 d0                	add    %edx,%eax
40004e48:	05 10 10 00 00       	add    $0x1010,%eax
40004e4d:	8b 00                	mov    (%eax),%eax
40004e4f:	89 45 f0             	mov    %eax,-0x10(%ebp)
		goto found;
40004e52:	e9 d5 fd ff ff       	jmp    40004c2c <dir_walk+0x254>
	}

	// Path component not found - see if we should create it
	if (!createmode || strchr(path, '/') != NULL) {
40004e57:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40004e5b:	74 17                	je     40004e74 <dir_walk+0x49c>
40004e5d:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
40004e64:	00 
40004e65:	8b 45 08             	mov    0x8(%ebp),%eax
40004e68:	89 04 24             	mov    %eax,(%esp)
40004e6b:	e8 c9 e7 ff ff       	call   40003639 <strchr>
40004e70:	85 c0                	test   %eax,%eax
40004e72:	74 15                	je     40004e89 <dir_walk+0x4b1>
		errno = ENOENT;
40004e74:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40004e79:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
		return -1;
40004e7f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40004e84:	e9 26 01 00 00       	jmp    40004faf <dir_walk+0x5d7>
	}
	if (strlen(path) > NAME_MAX) {
40004e89:	8b 45 08             	mov    0x8(%ebp),%eax
40004e8c:	89 04 24             	mov    %eax,(%esp)
40004e8f:	e8 20 e6 ff ff       	call   400034b4 <strlen>
40004e94:	83 f8 3f             	cmp    $0x3f,%eax
40004e97:	7e 15                	jle    40004eae <dir_walk+0x4d6>
		errno = ENAMETOOLONG;
40004e99:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40004e9e:	c7 00 06 00 00 00    	movl   $0x6,(%eax)
		return -1;
40004ea4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40004ea9:	e9 01 01 00 00       	jmp    40004faf <dir_walk+0x5d7>
	}

	// Allocate a new inode and create this entry with the given mode.
	ino = fileino_alloc();
40004eae:	e8 31 ea ff ff       	call   400038e4 <fileino_alloc>
40004eb3:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (ino < 0)
40004eb6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40004eba:	79 0a                	jns    40004ec6 <dir_walk+0x4ee>
		return -1;
40004ebc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40004ec1:	e9 e9 00 00 00       	jmp    40004faf <dir_walk+0x5d7>
	assert(fileino_isvalid(ino) && !fileino_alloced(ino));
40004ec6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40004eca:	7e 33                	jle    40004eff <dir_walk+0x527>
40004ecc:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40004ed3:	7f 2a                	jg     40004eff <dir_walk+0x527>
40004ed5:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40004ed9:	7e 48                	jle    40004f23 <dir_walk+0x54b>
40004edb:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40004ee2:	7f 3f                	jg     40004f23 <dir_walk+0x54b>
40004ee4:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004eea:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004eed:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004ef0:	01 d0                	add    %edx,%eax
40004ef2:	05 10 10 00 00       	add    $0x1010,%eax
40004ef7:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004efb:	84 c0                	test   %al,%al
40004efd:	74 24                	je     40004f23 <dir_walk+0x54b>
40004eff:	c7 44 24 0c 98 5f 00 	movl   $0x40005f98,0xc(%esp)
40004f06:	40 
40004f07:	c7 44 24 08 40 5f 00 	movl   $0x40005f40,0x8(%esp)
40004f0e:	40 
40004f0f:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
40004f16:	00 
40004f17:	c7 04 24 55 5f 00 40 	movl   $0x40005f55,(%esp)
40004f1e:	e8 1d dc ff ff       	call   40002b40 <debug_panic>
	strcpy(files->fi[ino].de.d_name, path);
40004f23:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40004f28:	8b 55 f0             	mov    -0x10(%ebp),%edx
40004f2b:	6b d2 5c             	imul   $0x5c,%edx,%edx
40004f2e:	81 c2 10 10 00 00    	add    $0x1010,%edx
40004f34:	01 d0                	add    %edx,%eax
40004f36:	8d 50 04             	lea    0x4(%eax),%edx
40004f39:	8b 45 08             	mov    0x8(%ebp),%eax
40004f3c:	89 44 24 04          	mov    %eax,0x4(%esp)
40004f40:	89 14 24             	mov    %edx,(%esp)
40004f43:	e8 92 e5 ff ff       	call   400034da <strcpy>
	files->fi[ino].dino = dino;
40004f48:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004f4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004f51:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004f54:	01 d0                	add    %edx,%eax
40004f56:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40004f5c:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004f5f:	89 02                	mov    %eax,(%edx)
	files->fi[ino].ver = 0;
40004f61:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004f67:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004f6a:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004f6d:	01 d0                	add    %edx,%eax
40004f6f:	05 54 10 00 00       	add    $0x1054,%eax
40004f74:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	files->fi[ino].mode = createmode;
40004f7a:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004f80:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004f83:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004f86:	01 d0                	add    %edx,%eax
40004f88:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
40004f8e:	8b 45 0c             	mov    0xc(%ebp),%eax
40004f91:	89 02                	mov    %eax,(%edx)
	files->fi[ino].size = 0;
40004f93:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40004f99:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004f9c:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004f9f:	01 d0                	add    %edx,%eax
40004fa1:	05 5c 10 00 00       	add    $0x105c,%eax
40004fa6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return ino;
40004fac:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40004faf:	c9                   	leave  
40004fb0:	c3                   	ret    

40004fb1 <opendir>:
// Open a directory for scanning.
// For simplicity, DIR is simply a filedesc like other file descriptors,
// except we interpret fd->ofs as an inode number for scanning,
// instead of as a byte offset as in a regular file.
DIR *opendir(const char *path)
{
40004fb1:	55                   	push   %ebp
40004fb2:	89 e5                	mov    %esp,%ebp
40004fb4:	83 ec 28             	sub    $0x28,%esp
	filedesc *fd = filedesc_open(NULL, path, O_RDONLY, 0);
40004fb7:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
40004fbe:	00 
40004fbf:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40004fc6:	00 
40004fc7:	8b 45 08             	mov    0x8(%ebp),%eax
40004fca:	89 44 24 04          	mov    %eax,0x4(%esp)
40004fce:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40004fd5:	e8 a5 f3 ff ff       	call   4000437f <filedesc_open>
40004fda:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (fd == NULL)
40004fdd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40004fe1:	75 0a                	jne    40004fed <opendir+0x3c>
		return NULL;
40004fe3:	b8 00 00 00 00       	mov    $0x0,%eax
40004fe8:	e9 bb 00 00 00       	jmp    400050a8 <opendir+0xf7>

	// Make sure it's a directory
	assert(fileino_exists(fd->ino));
40004fed:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004ff0:	8b 00                	mov    (%eax),%eax
40004ff2:	85 c0                	test   %eax,%eax
40004ff4:	7e 44                	jle    4000503a <opendir+0x89>
40004ff6:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004ff9:	8b 00                	mov    (%eax),%eax
40004ffb:	3d ff 00 00 00       	cmp    $0xff,%eax
40005000:	7f 38                	jg     4000503a <opendir+0x89>
40005002:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40005008:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000500b:	8b 00                	mov    (%eax),%eax
4000500d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40005010:	01 d0                	add    %edx,%eax
40005012:	05 10 10 00 00       	add    $0x1010,%eax
40005017:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000501b:	84 c0                	test   %al,%al
4000501d:	74 1b                	je     4000503a <opendir+0x89>
4000501f:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40005025:	8b 45 f4             	mov    -0xc(%ebp),%eax
40005028:	8b 00                	mov    (%eax),%eax
4000502a:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000502d:	01 d0                	add    %edx,%eax
4000502f:	05 58 10 00 00       	add    $0x1058,%eax
40005034:	8b 00                	mov    (%eax),%eax
40005036:	85 c0                	test   %eax,%eax
40005038:	75 24                	jne    4000505e <opendir+0xad>
4000503a:	c7 44 24 0c c6 5f 00 	movl   $0x40005fc6,0xc(%esp)
40005041:	40 
40005042:	c7 44 24 08 40 5f 00 	movl   $0x40005f40,0x8(%esp)
40005049:	40 
4000504a:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
40005051:	00 
40005052:	c7 04 24 55 5f 00 40 	movl   $0x40005f55,(%esp)
40005059:	e8 e2 da ff ff       	call   40002b40 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
4000505e:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40005064:	8b 45 f4             	mov    -0xc(%ebp),%eax
40005067:	8b 00                	mov    (%eax),%eax
40005069:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000506c:	05 10 10 00 00       	add    $0x1010,%eax
40005071:	01 d0                	add    %edx,%eax
40005073:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (!S_ISDIR(fi->mode)) {
40005076:	8b 45 f0             	mov    -0x10(%ebp),%eax
40005079:	8b 40 48             	mov    0x48(%eax),%eax
4000507c:	25 00 70 00 00       	and    $0x7000,%eax
40005081:	3d 00 20 00 00       	cmp    $0x2000,%eax
40005086:	74 1d                	je     400050a5 <opendir+0xf4>
		filedesc_close(fd);
40005088:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000508b:	89 04 24             	mov    %eax,(%esp)
4000508e:	e8 b1 f8 ff ff       	call   40004944 <filedesc_close>
		errno = ENOTDIR;
40005093:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40005098:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
		return NULL;
4000509e:	b8 00 00 00 00       	mov    $0x0,%eax
400050a3:	eb 03                	jmp    400050a8 <opendir+0xf7>
	}

	return fd;
400050a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
400050a8:	c9                   	leave  
400050a9:	c3                   	ret    

400050aa <closedir>:

int closedir(DIR *dir)
{
400050aa:	55                   	push   %ebp
400050ab:	89 e5                	mov    %esp,%ebp
400050ad:	83 ec 18             	sub    $0x18,%esp
	filedesc_close(dir);
400050b0:	8b 45 08             	mov    0x8(%ebp),%eax
400050b3:	89 04 24             	mov    %eax,(%esp)
400050b6:	e8 89 f8 ff ff       	call   40004944 <filedesc_close>
	return 0;
400050bb:	b8 00 00 00 00       	mov    $0x0,%eax
}
400050c0:	c9                   	leave  
400050c1:	c3                   	ret    

400050c2 <readdir>:

// Scan an open directory filedesc and return the next entry.
// Returns a pointer to the next matching file inode's 'dirent' struct,
// or NULL if the directory being scanned contains no more entries.
struct dirent *readdir(DIR *dir)
{
400050c2:	55                   	push   %ebp
400050c3:	89 e5                	mov    %esp,%ebp
400050c5:	83 ec 28             	sub    $0x28,%esp
	// Hint: a fileinode's 'dino' field indicates
	// what directory the file is in;
	// this function shouldn't return entries from other directories!
	//warn("readdir() not implemented");
	//return NULL;
	assert(fileino_isdir(dir->ino));
400050c8:	8b 45 08             	mov    0x8(%ebp),%eax
400050cb:	8b 00                	mov    (%eax),%eax
400050cd:	85 c0                	test   %eax,%eax
400050cf:	7e 4c                	jle    4000511d <readdir+0x5b>
400050d1:	8b 45 08             	mov    0x8(%ebp),%eax
400050d4:	8b 00                	mov    (%eax),%eax
400050d6:	3d ff 00 00 00       	cmp    $0xff,%eax
400050db:	7f 40                	jg     4000511d <readdir+0x5b>
400050dd:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
400050e3:	8b 45 08             	mov    0x8(%ebp),%eax
400050e6:	8b 00                	mov    (%eax),%eax
400050e8:	6b c0 5c             	imul   $0x5c,%eax,%eax
400050eb:	01 d0                	add    %edx,%eax
400050ed:	05 10 10 00 00       	add    $0x1010,%eax
400050f2:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400050f6:	84 c0                	test   %al,%al
400050f8:	74 23                	je     4000511d <readdir+0x5b>
400050fa:	8b 15 ac 5c 00 40    	mov    0x40005cac,%edx
40005100:	8b 45 08             	mov    0x8(%ebp),%eax
40005103:	8b 00                	mov    (%eax),%eax
40005105:	6b c0 5c             	imul   $0x5c,%eax,%eax
40005108:	01 d0                	add    %edx,%eax
4000510a:	05 58 10 00 00       	add    $0x1058,%eax
4000510f:	8b 00                	mov    (%eax),%eax
40005111:	25 00 70 00 00       	and    $0x7000,%eax
40005116:	3d 00 20 00 00       	cmp    $0x2000,%eax
4000511b:	74 24                	je     40005141 <readdir+0x7f>
4000511d:	c7 44 24 0c de 5f 00 	movl   $0x40005fde,0xc(%esp)
40005124:	40 
40005125:	c7 44 24 08 40 5f 00 	movl   $0x40005f40,0x8(%esp)
4000512c:	40 
4000512d:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
40005134:	00 
40005135:	c7 04 24 55 5f 00 40 	movl   $0x40005f55,(%esp)
4000513c:	e8 ff d9 ff ff       	call   40002b40 <debug_panic>
	int i = dir->ofs;
40005141:	8b 45 08             	mov    0x8(%ebp),%eax
40005144:	8b 40 08             	mov    0x8(%eax),%eax
40005147:	89 45 f4             	mov    %eax,-0xc(%ebp)
	for(i; i < FILE_INODES; i++){
4000514a:	eb 3c                	jmp    40005188 <readdir+0xc6>
		fileinode* tmp_fi = &files->fi[i];
4000514c:	a1 ac 5c 00 40       	mov    0x40005cac,%eax
40005151:	8b 55 f4             	mov    -0xc(%ebp),%edx
40005154:	6b d2 5c             	imul   $0x5c,%edx,%edx
40005157:	81 c2 10 10 00 00    	add    $0x1010,%edx
4000515d:	01 d0                	add    %edx,%eax
4000515f:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if(tmp_fi->dino == dir->ino){
40005162:	8b 45 f0             	mov    -0x10(%ebp),%eax
40005165:	8b 10                	mov    (%eax),%edx
40005167:	8b 45 08             	mov    0x8(%ebp),%eax
4000516a:	8b 00                	mov    (%eax),%eax
4000516c:	39 c2                	cmp    %eax,%edx
4000516e:	75 14                	jne    40005184 <readdir+0xc2>
			dir->ofs = i+1;
40005170:	8b 45 f4             	mov    -0xc(%ebp),%eax
40005173:	8d 50 01             	lea    0x1(%eax),%edx
40005176:	8b 45 08             	mov    0x8(%ebp),%eax
40005179:	89 50 08             	mov    %edx,0x8(%eax)
			return &tmp_fi->de;
4000517c:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000517f:	83 c0 04             	add    $0x4,%eax
40005182:	eb 1c                	jmp    400051a0 <readdir+0xde>
	// this function shouldn't return entries from other directories!
	//warn("readdir() not implemented");
	//return NULL;
	assert(fileino_isdir(dir->ino));
	int i = dir->ofs;
	for(i; i < FILE_INODES; i++){
40005184:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40005188:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
4000518f:	7e bb                	jle    4000514c <readdir+0x8a>
		if(tmp_fi->dino == dir->ino){
			dir->ofs = i+1;
			return &tmp_fi->de;
		}
	}
	dir->ofs = 0;
40005191:	8b 45 08             	mov    0x8(%ebp),%eax
40005194:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
	return NULL;
4000519b:	b8 00 00 00 00       	mov    $0x0,%eax
}
400051a0:	c9                   	leave  
400051a1:	c3                   	ret    

400051a2 <rewinddir>:

void rewinddir(DIR *dir)
{
400051a2:	55                   	push   %ebp
400051a3:	89 e5                	mov    %esp,%ebp
	dir->ofs = 0;
400051a5:	8b 45 08             	mov    0x8(%ebp),%eax
400051a8:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
400051af:	5d                   	pop    %ebp
400051b0:	c3                   	ret    

400051b1 <seekdir>:

void seekdir(DIR *dir, long ofs)
{
400051b1:	55                   	push   %ebp
400051b2:	89 e5                	mov    %esp,%ebp
	dir->ofs = ofs;
400051b4:	8b 45 08             	mov    0x8(%ebp),%eax
400051b7:	8b 55 0c             	mov    0xc(%ebp),%edx
400051ba:	89 50 08             	mov    %edx,0x8(%eax)
}
400051bd:	5d                   	pop    %ebp
400051be:	c3                   	ret    

400051bf <telldir>:

long telldir(DIR *dir)
{
400051bf:	55                   	push   %ebp
400051c0:	89 e5                	mov    %esp,%ebp
	return dir->ofs;
400051c2:	8b 45 08             	mov    0x8(%ebp),%eax
400051c5:	8b 40 08             	mov    0x8(%eax),%eax
}
400051c8:	5d                   	pop    %ebp
400051c9:	c3                   	ret    
400051ca:	66 90                	xchg   %ax,%ax
400051cc:	66 90                	xchg   %ax,%ax
400051ce:	66 90                	xchg   %ax,%ax

400051d0 <__udivdi3>:
400051d0:	83 ec 1c             	sub    $0x1c,%esp
400051d3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
400051d7:	89 7c 24 14          	mov    %edi,0x14(%esp)
400051db:	8b 4c 24 28          	mov    0x28(%esp),%ecx
400051df:	89 6c 24 18          	mov    %ebp,0x18(%esp)
400051e3:	8b 7c 24 20          	mov    0x20(%esp),%edi
400051e7:	8b 6c 24 24          	mov    0x24(%esp),%ebp
400051eb:	85 c0                	test   %eax,%eax
400051ed:	89 74 24 10          	mov    %esi,0x10(%esp)
400051f1:	89 7c 24 08          	mov    %edi,0x8(%esp)
400051f5:	89 ea                	mov    %ebp,%edx
400051f7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
400051fb:	75 33                	jne    40005230 <__udivdi3+0x60>
400051fd:	39 e9                	cmp    %ebp,%ecx
400051ff:	77 6f                	ja     40005270 <__udivdi3+0xa0>
40005201:	85 c9                	test   %ecx,%ecx
40005203:	89 ce                	mov    %ecx,%esi
40005205:	75 0b                	jne    40005212 <__udivdi3+0x42>
40005207:	b8 01 00 00 00       	mov    $0x1,%eax
4000520c:	31 d2                	xor    %edx,%edx
4000520e:	f7 f1                	div    %ecx
40005210:	89 c6                	mov    %eax,%esi
40005212:	31 d2                	xor    %edx,%edx
40005214:	89 e8                	mov    %ebp,%eax
40005216:	f7 f6                	div    %esi
40005218:	89 c5                	mov    %eax,%ebp
4000521a:	89 f8                	mov    %edi,%eax
4000521c:	f7 f6                	div    %esi
4000521e:	89 ea                	mov    %ebp,%edx
40005220:	8b 74 24 10          	mov    0x10(%esp),%esi
40005224:	8b 7c 24 14          	mov    0x14(%esp),%edi
40005228:	8b 6c 24 18          	mov    0x18(%esp),%ebp
4000522c:	83 c4 1c             	add    $0x1c,%esp
4000522f:	c3                   	ret    
40005230:	39 e8                	cmp    %ebp,%eax
40005232:	77 24                	ja     40005258 <__udivdi3+0x88>
40005234:	0f bd c8             	bsr    %eax,%ecx
40005237:	83 f1 1f             	xor    $0x1f,%ecx
4000523a:	89 0c 24             	mov    %ecx,(%esp)
4000523d:	75 49                	jne    40005288 <__udivdi3+0xb8>
4000523f:	8b 74 24 08          	mov    0x8(%esp),%esi
40005243:	39 74 24 04          	cmp    %esi,0x4(%esp)
40005247:	0f 86 ab 00 00 00    	jbe    400052f8 <__udivdi3+0x128>
4000524d:	39 e8                	cmp    %ebp,%eax
4000524f:	0f 82 a3 00 00 00    	jb     400052f8 <__udivdi3+0x128>
40005255:	8d 76 00             	lea    0x0(%esi),%esi
40005258:	31 d2                	xor    %edx,%edx
4000525a:	31 c0                	xor    %eax,%eax
4000525c:	8b 74 24 10          	mov    0x10(%esp),%esi
40005260:	8b 7c 24 14          	mov    0x14(%esp),%edi
40005264:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40005268:	83 c4 1c             	add    $0x1c,%esp
4000526b:	c3                   	ret    
4000526c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40005270:	89 f8                	mov    %edi,%eax
40005272:	f7 f1                	div    %ecx
40005274:	31 d2                	xor    %edx,%edx
40005276:	8b 74 24 10          	mov    0x10(%esp),%esi
4000527a:	8b 7c 24 14          	mov    0x14(%esp),%edi
4000527e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40005282:	83 c4 1c             	add    $0x1c,%esp
40005285:	c3                   	ret    
40005286:	66 90                	xchg   %ax,%ax
40005288:	0f b6 0c 24          	movzbl (%esp),%ecx
4000528c:	89 c6                	mov    %eax,%esi
4000528e:	b8 20 00 00 00       	mov    $0x20,%eax
40005293:	8b 6c 24 04          	mov    0x4(%esp),%ebp
40005297:	2b 04 24             	sub    (%esp),%eax
4000529a:	8b 7c 24 08          	mov    0x8(%esp),%edi
4000529e:	d3 e6                	shl    %cl,%esi
400052a0:	89 c1                	mov    %eax,%ecx
400052a2:	d3 ed                	shr    %cl,%ebp
400052a4:	0f b6 0c 24          	movzbl (%esp),%ecx
400052a8:	09 f5                	or     %esi,%ebp
400052aa:	8b 74 24 04          	mov    0x4(%esp),%esi
400052ae:	d3 e6                	shl    %cl,%esi
400052b0:	89 c1                	mov    %eax,%ecx
400052b2:	89 74 24 04          	mov    %esi,0x4(%esp)
400052b6:	89 d6                	mov    %edx,%esi
400052b8:	d3 ee                	shr    %cl,%esi
400052ba:	0f b6 0c 24          	movzbl (%esp),%ecx
400052be:	d3 e2                	shl    %cl,%edx
400052c0:	89 c1                	mov    %eax,%ecx
400052c2:	d3 ef                	shr    %cl,%edi
400052c4:	09 d7                	or     %edx,%edi
400052c6:	89 f2                	mov    %esi,%edx
400052c8:	89 f8                	mov    %edi,%eax
400052ca:	f7 f5                	div    %ebp
400052cc:	89 d6                	mov    %edx,%esi
400052ce:	89 c7                	mov    %eax,%edi
400052d0:	f7 64 24 04          	mull   0x4(%esp)
400052d4:	39 d6                	cmp    %edx,%esi
400052d6:	72 30                	jb     40005308 <__udivdi3+0x138>
400052d8:	8b 6c 24 08          	mov    0x8(%esp),%ebp
400052dc:	0f b6 0c 24          	movzbl (%esp),%ecx
400052e0:	d3 e5                	shl    %cl,%ebp
400052e2:	39 c5                	cmp    %eax,%ebp
400052e4:	73 04                	jae    400052ea <__udivdi3+0x11a>
400052e6:	39 d6                	cmp    %edx,%esi
400052e8:	74 1e                	je     40005308 <__udivdi3+0x138>
400052ea:	89 f8                	mov    %edi,%eax
400052ec:	31 d2                	xor    %edx,%edx
400052ee:	e9 69 ff ff ff       	jmp    4000525c <__udivdi3+0x8c>
400052f3:	90                   	nop
400052f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
400052f8:	31 d2                	xor    %edx,%edx
400052fa:	b8 01 00 00 00       	mov    $0x1,%eax
400052ff:	e9 58 ff ff ff       	jmp    4000525c <__udivdi3+0x8c>
40005304:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40005308:	8d 47 ff             	lea    -0x1(%edi),%eax
4000530b:	31 d2                	xor    %edx,%edx
4000530d:	8b 74 24 10          	mov    0x10(%esp),%esi
40005311:	8b 7c 24 14          	mov    0x14(%esp),%edi
40005315:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40005319:	83 c4 1c             	add    $0x1c,%esp
4000531c:	c3                   	ret    
4000531d:	66 90                	xchg   %ax,%ax
4000531f:	90                   	nop

40005320 <__umoddi3>:
40005320:	83 ec 2c             	sub    $0x2c,%esp
40005323:	8b 44 24 3c          	mov    0x3c(%esp),%eax
40005327:	8b 4c 24 30          	mov    0x30(%esp),%ecx
4000532b:	89 74 24 20          	mov    %esi,0x20(%esp)
4000532f:	8b 74 24 38          	mov    0x38(%esp),%esi
40005333:	89 7c 24 24          	mov    %edi,0x24(%esp)
40005337:	8b 7c 24 34          	mov    0x34(%esp),%edi
4000533b:	85 c0                	test   %eax,%eax
4000533d:	89 c2                	mov    %eax,%edx
4000533f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
40005343:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
40005347:	89 7c 24 0c          	mov    %edi,0xc(%esp)
4000534b:	89 74 24 10          	mov    %esi,0x10(%esp)
4000534f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
40005353:	89 7c 24 18          	mov    %edi,0x18(%esp)
40005357:	75 1f                	jne    40005378 <__umoddi3+0x58>
40005359:	39 fe                	cmp    %edi,%esi
4000535b:	76 63                	jbe    400053c0 <__umoddi3+0xa0>
4000535d:	89 c8                	mov    %ecx,%eax
4000535f:	89 fa                	mov    %edi,%edx
40005361:	f7 f6                	div    %esi
40005363:	89 d0                	mov    %edx,%eax
40005365:	31 d2                	xor    %edx,%edx
40005367:	8b 74 24 20          	mov    0x20(%esp),%esi
4000536b:	8b 7c 24 24          	mov    0x24(%esp),%edi
4000536f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
40005373:	83 c4 2c             	add    $0x2c,%esp
40005376:	c3                   	ret    
40005377:	90                   	nop
40005378:	39 f8                	cmp    %edi,%eax
4000537a:	77 64                	ja     400053e0 <__umoddi3+0xc0>
4000537c:	0f bd e8             	bsr    %eax,%ebp
4000537f:	83 f5 1f             	xor    $0x1f,%ebp
40005382:	75 74                	jne    400053f8 <__umoddi3+0xd8>
40005384:	8b 7c 24 14          	mov    0x14(%esp),%edi
40005388:	39 7c 24 10          	cmp    %edi,0x10(%esp)
4000538c:	0f 87 0e 01 00 00    	ja     400054a0 <__umoddi3+0x180>
40005392:	8b 7c 24 0c          	mov    0xc(%esp),%edi
40005396:	29 f1                	sub    %esi,%ecx
40005398:	19 c7                	sbb    %eax,%edi
4000539a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
4000539e:	89 7c 24 18          	mov    %edi,0x18(%esp)
400053a2:	8b 44 24 14          	mov    0x14(%esp),%eax
400053a6:	8b 54 24 18          	mov    0x18(%esp),%edx
400053aa:	8b 74 24 20          	mov    0x20(%esp),%esi
400053ae:	8b 7c 24 24          	mov    0x24(%esp),%edi
400053b2:	8b 6c 24 28          	mov    0x28(%esp),%ebp
400053b6:	83 c4 2c             	add    $0x2c,%esp
400053b9:	c3                   	ret    
400053ba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
400053c0:	85 f6                	test   %esi,%esi
400053c2:	89 f5                	mov    %esi,%ebp
400053c4:	75 0b                	jne    400053d1 <__umoddi3+0xb1>
400053c6:	b8 01 00 00 00       	mov    $0x1,%eax
400053cb:	31 d2                	xor    %edx,%edx
400053cd:	f7 f6                	div    %esi
400053cf:	89 c5                	mov    %eax,%ebp
400053d1:	8b 44 24 0c          	mov    0xc(%esp),%eax
400053d5:	31 d2                	xor    %edx,%edx
400053d7:	f7 f5                	div    %ebp
400053d9:	89 c8                	mov    %ecx,%eax
400053db:	f7 f5                	div    %ebp
400053dd:	eb 84                	jmp    40005363 <__umoddi3+0x43>
400053df:	90                   	nop
400053e0:	89 c8                	mov    %ecx,%eax
400053e2:	89 fa                	mov    %edi,%edx
400053e4:	8b 74 24 20          	mov    0x20(%esp),%esi
400053e8:	8b 7c 24 24          	mov    0x24(%esp),%edi
400053ec:	8b 6c 24 28          	mov    0x28(%esp),%ebp
400053f0:	83 c4 2c             	add    $0x2c,%esp
400053f3:	c3                   	ret    
400053f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
400053f8:	8b 44 24 10          	mov    0x10(%esp),%eax
400053fc:	be 20 00 00 00       	mov    $0x20,%esi
40005401:	89 e9                	mov    %ebp,%ecx
40005403:	29 ee                	sub    %ebp,%esi
40005405:	d3 e2                	shl    %cl,%edx
40005407:	89 f1                	mov    %esi,%ecx
40005409:	d3 e8                	shr    %cl,%eax
4000540b:	89 e9                	mov    %ebp,%ecx
4000540d:	09 d0                	or     %edx,%eax
4000540f:	89 fa                	mov    %edi,%edx
40005411:	89 44 24 0c          	mov    %eax,0xc(%esp)
40005415:	8b 44 24 10          	mov    0x10(%esp),%eax
40005419:	d3 e0                	shl    %cl,%eax
4000541b:	89 f1                	mov    %esi,%ecx
4000541d:	89 44 24 10          	mov    %eax,0x10(%esp)
40005421:	8b 44 24 1c          	mov    0x1c(%esp),%eax
40005425:	d3 ea                	shr    %cl,%edx
40005427:	89 e9                	mov    %ebp,%ecx
40005429:	d3 e7                	shl    %cl,%edi
4000542b:	89 f1                	mov    %esi,%ecx
4000542d:	d3 e8                	shr    %cl,%eax
4000542f:	89 e9                	mov    %ebp,%ecx
40005431:	09 f8                	or     %edi,%eax
40005433:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
40005437:	f7 74 24 0c          	divl   0xc(%esp)
4000543b:	d3 e7                	shl    %cl,%edi
4000543d:	89 7c 24 18          	mov    %edi,0x18(%esp)
40005441:	89 d7                	mov    %edx,%edi
40005443:	f7 64 24 10          	mull   0x10(%esp)
40005447:	39 d7                	cmp    %edx,%edi
40005449:	89 c1                	mov    %eax,%ecx
4000544b:	89 54 24 14          	mov    %edx,0x14(%esp)
4000544f:	72 3b                	jb     4000548c <__umoddi3+0x16c>
40005451:	39 44 24 18          	cmp    %eax,0x18(%esp)
40005455:	72 31                	jb     40005488 <__umoddi3+0x168>
40005457:	8b 44 24 18          	mov    0x18(%esp),%eax
4000545b:	29 c8                	sub    %ecx,%eax
4000545d:	19 d7                	sbb    %edx,%edi
4000545f:	89 e9                	mov    %ebp,%ecx
40005461:	89 fa                	mov    %edi,%edx
40005463:	d3 e8                	shr    %cl,%eax
40005465:	89 f1                	mov    %esi,%ecx
40005467:	d3 e2                	shl    %cl,%edx
40005469:	89 e9                	mov    %ebp,%ecx
4000546b:	09 d0                	or     %edx,%eax
4000546d:	89 fa                	mov    %edi,%edx
4000546f:	d3 ea                	shr    %cl,%edx
40005471:	8b 74 24 20          	mov    0x20(%esp),%esi
40005475:	8b 7c 24 24          	mov    0x24(%esp),%edi
40005479:	8b 6c 24 28          	mov    0x28(%esp),%ebp
4000547d:	83 c4 2c             	add    $0x2c,%esp
40005480:	c3                   	ret    
40005481:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
40005488:	39 d7                	cmp    %edx,%edi
4000548a:	75 cb                	jne    40005457 <__umoddi3+0x137>
4000548c:	8b 54 24 14          	mov    0x14(%esp),%edx
40005490:	89 c1                	mov    %eax,%ecx
40005492:	2b 4c 24 10          	sub    0x10(%esp),%ecx
40005496:	1b 54 24 0c          	sbb    0xc(%esp),%edx
4000549a:	eb bb                	jmp    40005457 <__umoddi3+0x137>
4000549c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
400054a0:	3b 44 24 18          	cmp    0x18(%esp),%eax
400054a4:	0f 82 e8 fe ff ff    	jb     40005392 <__umoddi3+0x72>
400054aa:	e9 f3 fe ff ff       	jmp    400053a2 <__umoddi3+0x82>
