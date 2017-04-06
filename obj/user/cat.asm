
obj/user/cat:     file format elf32-i386


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
4000010c:	e8 f3 00 00 00       	call   40000204 <main>
	pushl	%eax	// use with main's return value as exit status
40000111:	50                   	push   %eax
	call	exit
40000112:	e8 f5 27 00 00       	call   4000290c <exit>
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

40000144 <cat>:

char buf[8192];

void
cat(int f, char *s)
{
40000144:	55                   	push   %ebp
40000145:	89 e5                	mov    %esp,%ebp
40000147:	83 ec 38             	sub    $0x38,%esp
	long n;
	int r;
	while ((n = read(f, buf, sizeof(buf))) > 0)
4000014a:	eb 56                	jmp    400001a2 <cat+0x5e>
		if (write(1, buf, n) != n)
4000014c:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000014f:	89 44 24 08          	mov    %eax,0x8(%esp)
40000153:	c7 44 24 04 80 55 00 	movl   $0x40005580,0x4(%esp)
4000015a:	40 
4000015b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
40000162:	e8 ec 28 00 00       	call   40002a53 <write>
40000167:	3b 45 f4             	cmp    -0xc(%ebp),%eax
4000016a:	74 36                	je     400001a2 <cat+0x5e>
			panic("write error copying %s: %s", s, strerror(errno));
4000016c:	a1 34 36 00 40       	mov    0x40003634,%eax
40000171:	8b 00                	mov    (%eax),%eax
40000173:	89 04 24             	mov    %eax,(%esp)
40000176:	e8 85 2d 00 00       	call   40002f00 <strerror>
4000017b:	89 44 24 10          	mov    %eax,0x10(%esp)
4000017f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000182:	89 44 24 0c          	mov    %eax,0xc(%esp)
40000186:	c7 44 24 08 e0 33 00 	movl   $0x400033e0,0x8(%esp)
4000018d:	40 
4000018e:	c7 44 24 04 18 00 00 	movl   $0x18,0x4(%esp)
40000195:	00 
40000196:	c7 04 24 fb 33 00 40 	movl   $0x400033fb,(%esp)
4000019d:	e8 52 01 00 00       	call   400002f4 <debug_panic>
void
cat(int f, char *s)
{
	long n;
	int r;
	while ((n = read(f, buf, sizeof(buf))) > 0)
400001a2:	c7 44 24 08 00 20 00 	movl   $0x2000,0x8(%esp)
400001a9:	00 
400001aa:	c7 44 24 04 80 55 00 	movl   $0x40005580,0x4(%esp)
400001b1:	40 
400001b2:	8b 45 08             	mov    0x8(%ebp),%eax
400001b5:	89 04 24             	mov    %eax,(%esp)
400001b8:	e8 60 28 00 00       	call   40002a1d <read>
400001bd:	89 45 f4             	mov    %eax,-0xc(%ebp)
400001c0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
400001c4:	7f 86                	jg     4000014c <cat+0x8>
		if (write(1, buf, n) != n)
			panic("write error copying %s: %s", s, strerror(errno));
	if (n < 0)
400001c6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
400001ca:	79 36                	jns    40000202 <cat+0xbe>
		panic("error reading %s: %s", s, strerror(errno));
400001cc:	a1 34 36 00 40       	mov    0x40003634,%eax
400001d1:	8b 00                	mov    (%eax),%eax
400001d3:	89 04 24             	mov    %eax,(%esp)
400001d6:	e8 25 2d 00 00       	call   40002f00 <strerror>
400001db:	89 44 24 10          	mov    %eax,0x10(%esp)
400001df:	8b 45 0c             	mov    0xc(%ebp),%eax
400001e2:	89 44 24 0c          	mov    %eax,0xc(%esp)
400001e6:	c7 44 24 08 06 34 00 	movl   $0x40003406,0x8(%esp)
400001ed:	40 
400001ee:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
400001f5:	00 
400001f6:	c7 04 24 fb 33 00 40 	movl   $0x400033fb,(%esp)
400001fd:	e8 f2 00 00 00       	call   400002f4 <debug_panic>
}
40000202:	c9                   	leave  
40000203:	c3                   	ret    

40000204 <main>:

int
main(int argc, char **argv)
{
40000204:	55                   	push   %ebp
40000205:	89 e5                	mov    %esp,%ebp
40000207:	83 e4 f0             	and    $0xfffffff0,%esp
4000020a:	83 ec 30             	sub    $0x30,%esp
	int f, i;

	if (argc == 1)
4000020d:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
40000211:	75 19                	jne    4000022c <main+0x28>
		cat(0, "<stdin>");
40000213:	c7 44 24 04 1b 34 00 	movl   $0x4000341b,0x4(%esp)
4000021a:	40 
4000021b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000222:	e8 1d ff ff ff       	call   40000144 <cat>
40000227:	e9 bf 00 00 00       	jmp    400002eb <main+0xe7>
	else
		for (i = 1; i < argc; i++) {
4000022c:	c7 44 24 2c 01 00 00 	movl   $0x1,0x2c(%esp)
40000233:	00 
40000234:	e9 a5 00 00 00       	jmp    400002de <main+0xda>
			f = open(argv[i], O_RDONLY);
40000239:	8b 44 24 2c          	mov    0x2c(%esp),%eax
4000023d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
40000244:	8b 45 0c             	mov    0xc(%ebp),%eax
40000247:	01 d0                	add    %edx,%eax
40000249:	8b 00                	mov    (%eax),%eax
4000024b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40000252:	00 
40000253:	89 04 24             	mov    %eax,(%esp)
40000256:	e8 27 27 00 00       	call   40002982 <open>
4000025b:	89 44 24 28          	mov    %eax,0x28(%esp)
			if (f < 0)
4000025f:	83 7c 24 28 00       	cmpl   $0x0,0x28(%esp)
40000264:	79 45                	jns    400002ab <main+0xa7>
				panic("can't open %s: %s", argv[i],
40000266:	a1 34 36 00 40       	mov    0x40003634,%eax
4000026b:	8b 00                	mov    (%eax),%eax
4000026d:	89 04 24             	mov    %eax,(%esp)
40000270:	e8 8b 2c 00 00       	call   40002f00 <strerror>
40000275:	8b 54 24 2c          	mov    0x2c(%esp),%edx
40000279:	8d 0c 95 00 00 00 00 	lea    0x0(,%edx,4),%ecx
40000280:	8b 55 0c             	mov    0xc(%ebp),%edx
40000283:	01 ca                	add    %ecx,%edx
40000285:	8b 12                	mov    (%edx),%edx
40000287:	89 44 24 10          	mov    %eax,0x10(%esp)
4000028b:	89 54 24 0c          	mov    %edx,0xc(%esp)
4000028f:	c7 44 24 08 23 34 00 	movl   $0x40003423,0x8(%esp)
40000296:	40 
40000297:	c7 44 24 04 29 00 00 	movl   $0x29,0x4(%esp)
4000029e:	00 
4000029f:	c7 04 24 fb 33 00 40 	movl   $0x400033fb,(%esp)
400002a6:	e8 49 00 00 00       	call   400002f4 <debug_panic>
					strerror(errno));
			else {
				cat(f, argv[i]);
400002ab:	8b 44 24 2c          	mov    0x2c(%esp),%eax
400002af:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
400002b6:	8b 45 0c             	mov    0xc(%ebp),%eax
400002b9:	01 d0                	add    %edx,%eax
400002bb:	8b 00                	mov    (%eax),%eax
400002bd:	89 44 24 04          	mov    %eax,0x4(%esp)
400002c1:	8b 44 24 28          	mov    0x28(%esp),%eax
400002c5:	89 04 24             	mov    %eax,(%esp)
400002c8:	e8 77 fe ff ff       	call   40000144 <cat>
				close(f);
400002cd:	8b 44 24 28          	mov    0x28(%esp),%eax
400002d1:	89 04 24             	mov    %eax,(%esp)
400002d4:	e8 1f 27 00 00       	call   400029f8 <close>
	int f, i;

	if (argc == 1)
		cat(0, "<stdin>");
	else
		for (i = 1; i < argc; i++) {
400002d9:	83 44 24 2c 01       	addl   $0x1,0x2c(%esp)
400002de:	8b 44 24 2c          	mov    0x2c(%esp),%eax
400002e2:	3b 45 08             	cmp    0x8(%ebp),%eax
400002e5:	0f 8c 4e ff ff ff    	jl     40000239 <main+0x35>
				cat(f, argv[i]);
				close(f);
			}
		}

	return 0;
400002eb:	b8 00 00 00 00       	mov    $0x0,%eax
}
400002f0:	c9                   	leave  
400002f1:	c3                   	ret    
400002f2:	66 90                	xchg   %ax,%ax

400002f4 <debug_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: <message>", then causes a breakpoint exception.
 */
void
debug_panic(const char *file, int line, const char *fmt,...)
{
400002f4:	55                   	push   %ebp
400002f5:	89 e5                	mov    %esp,%ebp
400002f7:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	va_start(ap, fmt);
400002fa:	8d 45 10             	lea    0x10(%ebp),%eax
400002fd:	83 c0 04             	add    $0x4,%eax
40000300:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Print the panic message
	if (argv0)
40000303:	a1 80 75 00 40       	mov    0x40007580,%eax
40000308:	85 c0                	test   %eax,%eax
4000030a:	74 15                	je     40000321 <debug_panic+0x2d>
		cprintf("%s: ", argv0);
4000030c:	a1 80 75 00 40       	mov    0x40007580,%eax
40000311:	89 44 24 04          	mov    %eax,0x4(%esp)
40000315:	c7 04 24 38 34 00 40 	movl   $0x40003438,(%esp)
4000031c:	e8 67 02 00 00       	call   40000588 <cprintf>
	cprintf("user panic at %s:%d: ", file, line);
40000321:	8b 45 0c             	mov    0xc(%ebp),%eax
40000324:	89 44 24 08          	mov    %eax,0x8(%esp)
40000328:	8b 45 08             	mov    0x8(%ebp),%eax
4000032b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000032f:	c7 04 24 3d 34 00 40 	movl   $0x4000343d,(%esp)
40000336:	e8 4d 02 00 00       	call   40000588 <cprintf>
	vcprintf(fmt, ap);
4000033b:	8b 45 10             	mov    0x10(%ebp),%eax
4000033e:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000341:	89 54 24 04          	mov    %edx,0x4(%esp)
40000345:	89 04 24             	mov    %eax,(%esp)
40000348:	e8 d3 01 00 00       	call   40000520 <vcprintf>
	cprintf("\n");
4000034d:	c7 04 24 53 34 00 40 	movl   $0x40003453,(%esp)
40000354:	e8 2f 02 00 00       	call   40000588 <cprintf>

	abort();
40000359:	e8 ee 25 00 00       	call   4000294c <abort>

4000035e <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
4000035e:	55                   	push   %ebp
4000035f:	89 e5                	mov    %esp,%ebp
40000361:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
40000364:	8d 45 10             	lea    0x10(%ebp),%eax
40000367:	83 c0 04             	add    $0x4,%eax
4000036a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("user warning at %s:%d: ", file, line);
4000036d:	8b 45 0c             	mov    0xc(%ebp),%eax
40000370:	89 44 24 08          	mov    %eax,0x8(%esp)
40000374:	8b 45 08             	mov    0x8(%ebp),%eax
40000377:	89 44 24 04          	mov    %eax,0x4(%esp)
4000037b:	c7 04 24 55 34 00 40 	movl   $0x40003455,(%esp)
40000382:	e8 01 02 00 00       	call   40000588 <cprintf>
	vcprintf(fmt, ap);
40000387:	8b 45 10             	mov    0x10(%ebp),%eax
4000038a:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000038d:	89 54 24 04          	mov    %edx,0x4(%esp)
40000391:	89 04 24             	mov    %eax,(%esp)
40000394:	e8 87 01 00 00       	call   40000520 <vcprintf>
	cprintf("\n");
40000399:	c7 04 24 53 34 00 40 	movl   $0x40003453,(%esp)
400003a0:	e8 e3 01 00 00       	call   40000588 <cprintf>
	va_end(ap);
}
400003a5:	c9                   	leave  
400003a6:	c3                   	ret    

400003a7 <debug_dump>:

// Dump a block of memory as 32-bit words and ASCII bytes
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
400003a7:	55                   	push   %ebp
400003a8:	89 e5                	mov    %esp,%ebp
400003aa:	56                   	push   %esi
400003ab:	53                   	push   %ebx
400003ac:	81 ec a0 00 00 00    	sub    $0xa0,%esp
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
400003b2:	8b 55 14             	mov    0x14(%ebp),%edx
400003b5:	8b 45 10             	mov    0x10(%ebp),%eax
400003b8:	01 d0                	add    %edx,%eax
400003ba:	89 44 24 10          	mov    %eax,0x10(%esp)
400003be:	8b 45 10             	mov    0x10(%ebp),%eax
400003c1:	89 44 24 0c          	mov    %eax,0xc(%esp)
400003c5:	8b 45 0c             	mov    0xc(%ebp),%eax
400003c8:	89 44 24 08          	mov    %eax,0x8(%esp)
400003cc:	8b 45 08             	mov    0x8(%ebp),%eax
400003cf:	89 44 24 04          	mov    %eax,0x4(%esp)
400003d3:	c7 04 24 70 34 00 40 	movl   $0x40003470,(%esp)
400003da:	e8 a9 01 00 00       	call   40000588 <cprintf>
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
400003df:	8b 45 14             	mov    0x14(%ebp),%eax
400003e2:	83 c0 0f             	add    $0xf,%eax
400003e5:	83 e0 f0             	and    $0xfffffff0,%eax
400003e8:	89 45 14             	mov    %eax,0x14(%ebp)
400003eb:	e9 bb 00 00 00       	jmp    400004ab <debug_dump+0x104>
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
400003f0:	8b 45 10             	mov    0x10(%ebp),%eax
400003f3:	89 45 f0             	mov    %eax,-0x10(%ebp)
		for (i = 0; i < 16; i++)
400003f6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
400003fd:	eb 4d                	jmp    4000044c <debug_dump+0xa5>
			buf[i] = isprint(c[i]) ? c[i] : '.';
400003ff:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000402:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000405:	01 d0                	add    %edx,%eax
40000407:	0f b6 00             	movzbl (%eax),%eax
4000040a:	0f b6 c0             	movzbl %al,%eax
4000040d:	89 45 e8             	mov    %eax,-0x18(%ebp)
static gcc_inline int isalnum(int c)	{ return isalpha(c) || isdigit(c); }
static gcc_inline int iscntrl(int c)	{ return c < ' '; }
static gcc_inline int isblank(int c)	{ return c == ' ' || c == '\t'; }
static gcc_inline int isspace(int c)	{ return c == ' '
						|| (c >= '\t' && c <= '\r'); }
static gcc_inline int isprint(int c)	{ return c >= ' ' && c <= '~'; }
40000410:	83 7d e8 1f          	cmpl   $0x1f,-0x18(%ebp)
40000414:	7e 0d                	jle    40000423 <debug_dump+0x7c>
40000416:	83 7d e8 7e          	cmpl   $0x7e,-0x18(%ebp)
4000041a:	7f 07                	jg     40000423 <debug_dump+0x7c>
4000041c:	b8 01 00 00 00       	mov    $0x1,%eax
40000421:	eb 05                	jmp    40000428 <debug_dump+0x81>
40000423:	b8 00 00 00 00       	mov    $0x0,%eax
40000428:	85 c0                	test   %eax,%eax
4000042a:	74 0d                	je     40000439 <debug_dump+0x92>
4000042c:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000042f:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000432:	01 d0                	add    %edx,%eax
40000434:	0f b6 00             	movzbl (%eax),%eax
40000437:	eb 05                	jmp    4000043e <debug_dump+0x97>
40000439:	b8 2e 00 00 00       	mov    $0x2e,%eax
4000043e:	8d 4d 84             	lea    -0x7c(%ebp),%ecx
40000441:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000444:	01 ca                	add    %ecx,%edx
40000446:	88 02                	mov    %al,(%edx)
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
		for (i = 0; i < 16; i++)
40000448:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
4000044c:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
40000450:	7e ad                	jle    400003ff <debug_dump+0x58>
			buf[i] = isprint(c[i]) ? c[i] : '.';
		buf[16] = 0;
40000452:	c6 45 94 00          	movb   $0x0,-0x6c(%ebp)

		// Hex words
		const uint32_t *v = ptr;
40000456:	8b 45 10             	mov    0x10(%ebp),%eax
40000459:	89 45 ec             	mov    %eax,-0x14(%ebp)

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
			ptr, v[0], v[1], v[2], v[3], buf);
4000045c:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000045f:	83 c0 0c             	add    $0xc,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40000462:	8b 18                	mov    (%eax),%ebx
			ptr, v[0], v[1], v[2], v[3], buf);
40000464:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000467:	83 c0 08             	add    $0x8,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
4000046a:	8b 08                	mov    (%eax),%ecx
			ptr, v[0], v[1], v[2], v[3], buf);
4000046c:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000046f:	83 c0 04             	add    $0x4,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40000472:	8b 10                	mov    (%eax),%edx
40000474:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000477:	8b 00                	mov    (%eax),%eax
			ptr, v[0], v[1], v[2], v[3], buf);
40000479:	8d 75 84             	lea    -0x7c(%ebp),%esi
4000047c:	89 74 24 18          	mov    %esi,0x18(%esp)

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40000480:	89 5c 24 14          	mov    %ebx,0x14(%esp)
40000484:	89 4c 24 10          	mov    %ecx,0x10(%esp)
40000488:	89 54 24 0c          	mov    %edx,0xc(%esp)
4000048c:	89 44 24 08          	mov    %eax,0x8(%esp)
40000490:	8b 45 10             	mov    0x10(%ebp),%eax
40000493:	89 44 24 04          	mov    %eax,0x4(%esp)
40000497:	c7 04 24 99 34 00 40 	movl   $0x40003499,(%esp)
4000049e:	e8 e5 00 00 00       	call   40000588 <cprintf>
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
400004a3:	83 6d 14 10          	subl   $0x10,0x14(%ebp)
400004a7:	83 45 10 10          	addl   $0x10,0x10(%ebp)
400004ab:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
400004af:	0f 8f 3b ff ff ff    	jg     400003f0 <debug_dump+0x49>

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
			ptr, v[0], v[1], v[2], v[3], buf);
	}
}
400004b5:	81 c4 a0 00 00 00    	add    $0xa0,%esp
400004bb:	5b                   	pop    %ebx
400004bc:	5e                   	pop    %esi
400004bd:	5d                   	pop    %ebp
400004be:	c3                   	ret    
400004bf:	90                   	nop

400004c0 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
400004c0:	55                   	push   %ebp
400004c1:	89 e5                	mov    %esp,%ebp
400004c3:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
400004c6:	8b 45 0c             	mov    0xc(%ebp),%eax
400004c9:	8b 00                	mov    (%eax),%eax
400004cb:	8b 55 08             	mov    0x8(%ebp),%edx
400004ce:	89 d1                	mov    %edx,%ecx
400004d0:	8b 55 0c             	mov    0xc(%ebp),%edx
400004d3:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
400004d7:	8d 50 01             	lea    0x1(%eax),%edx
400004da:	8b 45 0c             	mov    0xc(%ebp),%eax
400004dd:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
400004df:	8b 45 0c             	mov    0xc(%ebp),%eax
400004e2:	8b 00                	mov    (%eax),%eax
400004e4:	3d ff 00 00 00       	cmp    $0xff,%eax
400004e9:	75 24                	jne    4000050f <putch+0x4f>
		b->buf[b->idx] = 0;
400004eb:	8b 45 0c             	mov    0xc(%ebp),%eax
400004ee:	8b 00                	mov    (%eax),%eax
400004f0:	8b 55 0c             	mov    0xc(%ebp),%edx
400004f3:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
400004f8:	8b 45 0c             	mov    0xc(%ebp),%eax
400004fb:	83 c0 08             	add    $0x8,%eax
400004fe:	89 04 24             	mov    %eax,(%esp)
40000501:	e8 46 2a 00 00       	call   40002f4c <cputs>
		b->idx = 0;
40000506:	8b 45 0c             	mov    0xc(%ebp),%eax
40000509:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
4000050f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000512:	8b 40 04             	mov    0x4(%eax),%eax
40000515:	8d 50 01             	lea    0x1(%eax),%edx
40000518:	8b 45 0c             	mov    0xc(%ebp),%eax
4000051b:	89 50 04             	mov    %edx,0x4(%eax)
}
4000051e:	c9                   	leave  
4000051f:	c3                   	ret    

40000520 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
40000520:	55                   	push   %ebp
40000521:	89 e5                	mov    %esp,%ebp
40000523:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
40000529:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
40000530:	00 00 00 
	b.cnt = 0;
40000533:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
4000053a:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
4000053d:	8b 45 0c             	mov    0xc(%ebp),%eax
40000540:	89 44 24 0c          	mov    %eax,0xc(%esp)
40000544:	8b 45 08             	mov    0x8(%ebp),%eax
40000547:	89 44 24 08          	mov    %eax,0x8(%esp)
4000054b:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
40000551:	89 44 24 04          	mov    %eax,0x4(%esp)
40000555:	c7 04 24 c0 04 00 40 	movl   $0x400004c0,(%esp)
4000055c:	e8 70 03 00 00       	call   400008d1 <vprintfmt>

	b.buf[b.idx] = 0;
40000561:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
40000567:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
4000056e:	00 
	cputs(b.buf);
4000056f:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
40000575:	83 c0 08             	add    $0x8,%eax
40000578:	89 04 24             	mov    %eax,(%esp)
4000057b:	e8 cc 29 00 00       	call   40002f4c <cputs>

	return b.cnt;
40000580:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
40000586:	c9                   	leave  
40000587:	c3                   	ret    

40000588 <cprintf>:

int
cprintf(const char *fmt, ...)
{
40000588:	55                   	push   %ebp
40000589:	89 e5                	mov    %esp,%ebp
4000058b:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
4000058e:	8d 45 0c             	lea    0xc(%ebp),%eax
40000591:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
40000594:	8b 45 08             	mov    0x8(%ebp),%eax
40000597:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000059a:	89 54 24 04          	mov    %edx,0x4(%esp)
4000059e:	89 04 24             	mov    %eax,(%esp)
400005a1:	e8 7a ff ff ff       	call   40000520 <vcprintf>
400005a6:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
400005a9:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
400005ac:	c9                   	leave  
400005ad:	c3                   	ret    
400005ae:	66 90                	xchg   %ax,%ax

400005b0 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
400005b0:	55                   	push   %ebp
400005b1:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
400005b3:	8b 45 08             	mov    0x8(%ebp),%eax
400005b6:	8b 40 18             	mov    0x18(%eax),%eax
400005b9:	83 e0 02             	and    $0x2,%eax
400005bc:	85 c0                	test   %eax,%eax
400005be:	74 1c                	je     400005dc <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
400005c0:	8b 45 0c             	mov    0xc(%ebp),%eax
400005c3:	8b 00                	mov    (%eax),%eax
400005c5:	8d 50 08             	lea    0x8(%eax),%edx
400005c8:	8b 45 0c             	mov    0xc(%ebp),%eax
400005cb:	89 10                	mov    %edx,(%eax)
400005cd:	8b 45 0c             	mov    0xc(%ebp),%eax
400005d0:	8b 00                	mov    (%eax),%eax
400005d2:	83 e8 08             	sub    $0x8,%eax
400005d5:	8b 50 04             	mov    0x4(%eax),%edx
400005d8:	8b 00                	mov    (%eax),%eax
400005da:	eb 47                	jmp    40000623 <getuint+0x73>
	else if (st->flags & F_L)
400005dc:	8b 45 08             	mov    0x8(%ebp),%eax
400005df:	8b 40 18             	mov    0x18(%eax),%eax
400005e2:	83 e0 01             	and    $0x1,%eax
400005e5:	85 c0                	test   %eax,%eax
400005e7:	74 1e                	je     40000607 <getuint+0x57>
		return va_arg(*ap, unsigned long);
400005e9:	8b 45 0c             	mov    0xc(%ebp),%eax
400005ec:	8b 00                	mov    (%eax),%eax
400005ee:	8d 50 04             	lea    0x4(%eax),%edx
400005f1:	8b 45 0c             	mov    0xc(%ebp),%eax
400005f4:	89 10                	mov    %edx,(%eax)
400005f6:	8b 45 0c             	mov    0xc(%ebp),%eax
400005f9:	8b 00                	mov    (%eax),%eax
400005fb:	83 e8 04             	sub    $0x4,%eax
400005fe:	8b 00                	mov    (%eax),%eax
40000600:	ba 00 00 00 00       	mov    $0x0,%edx
40000605:	eb 1c                	jmp    40000623 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
40000607:	8b 45 0c             	mov    0xc(%ebp),%eax
4000060a:	8b 00                	mov    (%eax),%eax
4000060c:	8d 50 04             	lea    0x4(%eax),%edx
4000060f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000612:	89 10                	mov    %edx,(%eax)
40000614:	8b 45 0c             	mov    0xc(%ebp),%eax
40000617:	8b 00                	mov    (%eax),%eax
40000619:	83 e8 04             	sub    $0x4,%eax
4000061c:	8b 00                	mov    (%eax),%eax
4000061e:	ba 00 00 00 00       	mov    $0x0,%edx
}
40000623:	5d                   	pop    %ebp
40000624:	c3                   	ret    

40000625 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
40000625:	55                   	push   %ebp
40000626:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
40000628:	8b 45 08             	mov    0x8(%ebp),%eax
4000062b:	8b 40 18             	mov    0x18(%eax),%eax
4000062e:	83 e0 02             	and    $0x2,%eax
40000631:	85 c0                	test   %eax,%eax
40000633:	74 1c                	je     40000651 <getint+0x2c>
		return va_arg(*ap, long long);
40000635:	8b 45 0c             	mov    0xc(%ebp),%eax
40000638:	8b 00                	mov    (%eax),%eax
4000063a:	8d 50 08             	lea    0x8(%eax),%edx
4000063d:	8b 45 0c             	mov    0xc(%ebp),%eax
40000640:	89 10                	mov    %edx,(%eax)
40000642:	8b 45 0c             	mov    0xc(%ebp),%eax
40000645:	8b 00                	mov    (%eax),%eax
40000647:	83 e8 08             	sub    $0x8,%eax
4000064a:	8b 50 04             	mov    0x4(%eax),%edx
4000064d:	8b 00                	mov    (%eax),%eax
4000064f:	eb 47                	jmp    40000698 <getint+0x73>
	else if (st->flags & F_L)
40000651:	8b 45 08             	mov    0x8(%ebp),%eax
40000654:	8b 40 18             	mov    0x18(%eax),%eax
40000657:	83 e0 01             	and    $0x1,%eax
4000065a:	85 c0                	test   %eax,%eax
4000065c:	74 1e                	je     4000067c <getint+0x57>
		return va_arg(*ap, long);
4000065e:	8b 45 0c             	mov    0xc(%ebp),%eax
40000661:	8b 00                	mov    (%eax),%eax
40000663:	8d 50 04             	lea    0x4(%eax),%edx
40000666:	8b 45 0c             	mov    0xc(%ebp),%eax
40000669:	89 10                	mov    %edx,(%eax)
4000066b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000066e:	8b 00                	mov    (%eax),%eax
40000670:	83 e8 04             	sub    $0x4,%eax
40000673:	8b 00                	mov    (%eax),%eax
40000675:	89 c2                	mov    %eax,%edx
40000677:	c1 fa 1f             	sar    $0x1f,%edx
4000067a:	eb 1c                	jmp    40000698 <getint+0x73>
	else
		return va_arg(*ap, int);
4000067c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000067f:	8b 00                	mov    (%eax),%eax
40000681:	8d 50 04             	lea    0x4(%eax),%edx
40000684:	8b 45 0c             	mov    0xc(%ebp),%eax
40000687:	89 10                	mov    %edx,(%eax)
40000689:	8b 45 0c             	mov    0xc(%ebp),%eax
4000068c:	8b 00                	mov    (%eax),%eax
4000068e:	83 e8 04             	sub    $0x4,%eax
40000691:	8b 00                	mov    (%eax),%eax
40000693:	89 c2                	mov    %eax,%edx
40000695:	c1 fa 1f             	sar    $0x1f,%edx
}
40000698:	5d                   	pop    %ebp
40000699:	c3                   	ret    

4000069a <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
4000069a:	55                   	push   %ebp
4000069b:	89 e5                	mov    %esp,%ebp
4000069d:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
400006a0:	eb 1a                	jmp    400006bc <putpad+0x22>
		st->putch(st->padc, st->putdat);
400006a2:	8b 45 08             	mov    0x8(%ebp),%eax
400006a5:	8b 00                	mov    (%eax),%eax
400006a7:	8b 55 08             	mov    0x8(%ebp),%edx
400006aa:	8b 4a 04             	mov    0x4(%edx),%ecx
400006ad:	8b 55 08             	mov    0x8(%ebp),%edx
400006b0:	8b 52 08             	mov    0x8(%edx),%edx
400006b3:	89 4c 24 04          	mov    %ecx,0x4(%esp)
400006b7:	89 14 24             	mov    %edx,(%esp)
400006ba:	ff d0                	call   *%eax

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
400006bc:	8b 45 08             	mov    0x8(%ebp),%eax
400006bf:	8b 40 0c             	mov    0xc(%eax),%eax
400006c2:	8d 50 ff             	lea    -0x1(%eax),%edx
400006c5:	8b 45 08             	mov    0x8(%ebp),%eax
400006c8:	89 50 0c             	mov    %edx,0xc(%eax)
400006cb:	8b 45 08             	mov    0x8(%ebp),%eax
400006ce:	8b 40 0c             	mov    0xc(%eax),%eax
400006d1:	85 c0                	test   %eax,%eax
400006d3:	79 cd                	jns    400006a2 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
400006d5:	c9                   	leave  
400006d6:	c3                   	ret    

400006d7 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
400006d7:	55                   	push   %ebp
400006d8:	89 e5                	mov    %esp,%ebp
400006da:	53                   	push   %ebx
400006db:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
400006de:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400006e2:	79 18                	jns    400006fc <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
400006e4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400006eb:	00 
400006ec:	8b 45 0c             	mov    0xc(%ebp),%eax
400006ef:	89 04 24             	mov    %eax,(%esp)
400006f2:	e8 f6 06 00 00       	call   40000ded <strchr>
400006f7:	89 45 f4             	mov    %eax,-0xc(%ebp)
400006fa:	eb 2e                	jmp    4000072a <putstr+0x53>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
400006fc:	8b 45 10             	mov    0x10(%ebp),%eax
400006ff:	89 44 24 08          	mov    %eax,0x8(%esp)
40000703:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000070a:	00 
4000070b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000070e:	89 04 24             	mov    %eax,(%esp)
40000711:	e8 d4 08 00 00       	call   40000fea <memchr>
40000716:	89 45 f4             	mov    %eax,-0xc(%ebp)
40000719:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
4000071d:	75 0b                	jne    4000072a <putstr+0x53>
		lim = str + maxlen;
4000071f:	8b 55 10             	mov    0x10(%ebp),%edx
40000722:	8b 45 0c             	mov    0xc(%ebp),%eax
40000725:	01 d0                	add    %edx,%eax
40000727:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
4000072a:	8b 45 08             	mov    0x8(%ebp),%eax
4000072d:	8b 40 0c             	mov    0xc(%eax),%eax
40000730:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40000733:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000736:	89 cb                	mov    %ecx,%ebx
40000738:	29 d3                	sub    %edx,%ebx
4000073a:	89 da                	mov    %ebx,%edx
4000073c:	01 c2                	add    %eax,%edx
4000073e:	8b 45 08             	mov    0x8(%ebp),%eax
40000741:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
40000744:	8b 45 08             	mov    0x8(%ebp),%eax
40000747:	8b 40 18             	mov    0x18(%eax),%eax
4000074a:	83 e0 10             	and    $0x10,%eax
4000074d:	85 c0                	test   %eax,%eax
4000074f:	75 32                	jne    40000783 <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
40000751:	8b 45 08             	mov    0x8(%ebp),%eax
40000754:	89 04 24             	mov    %eax,(%esp)
40000757:	e8 3e ff ff ff       	call   4000069a <putpad>
	while (str < lim) {
4000075c:	eb 25                	jmp    40000783 <putstr+0xac>
		char ch = *str++;
4000075e:	8b 45 0c             	mov    0xc(%ebp),%eax
40000761:	0f b6 00             	movzbl (%eax),%eax
40000764:	88 45 f3             	mov    %al,-0xd(%ebp)
40000767:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
4000076b:	8b 45 08             	mov    0x8(%ebp),%eax
4000076e:	8b 00                	mov    (%eax),%eax
40000770:	8b 55 08             	mov    0x8(%ebp),%edx
40000773:	8b 4a 04             	mov    0x4(%edx),%ecx
40000776:	0f be 55 f3          	movsbl -0xd(%ebp),%edx
4000077a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
4000077e:	89 14 24             	mov    %edx,(%esp)
40000781:	ff d0                	call   *%eax
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
40000783:	8b 45 0c             	mov    0xc(%ebp),%eax
40000786:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40000789:	72 d3                	jb     4000075e <putstr+0x87>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
4000078b:	8b 45 08             	mov    0x8(%ebp),%eax
4000078e:	89 04 24             	mov    %eax,(%esp)
40000791:	e8 04 ff ff ff       	call   4000069a <putpad>
}
40000796:	83 c4 24             	add    $0x24,%esp
40000799:	5b                   	pop    %ebx
4000079a:	5d                   	pop    %ebp
4000079b:	c3                   	ret    

4000079c <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
4000079c:	55                   	push   %ebp
4000079d:	89 e5                	mov    %esp,%ebp
4000079f:	53                   	push   %ebx
400007a0:	83 ec 24             	sub    $0x24,%esp
400007a3:	8b 45 10             	mov    0x10(%ebp),%eax
400007a6:	89 45 f0             	mov    %eax,-0x10(%ebp)
400007a9:	8b 45 14             	mov    0x14(%ebp),%eax
400007ac:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
400007af:	8b 45 08             	mov    0x8(%ebp),%eax
400007b2:	8b 40 1c             	mov    0x1c(%eax),%eax
400007b5:	89 c2                	mov    %eax,%edx
400007b7:	c1 fa 1f             	sar    $0x1f,%edx
400007ba:	3b 55 f4             	cmp    -0xc(%ebp),%edx
400007bd:	77 4e                	ja     4000080d <genint+0x71>
400007bf:	3b 55 f4             	cmp    -0xc(%ebp),%edx
400007c2:	72 05                	jb     400007c9 <genint+0x2d>
400007c4:	3b 45 f0             	cmp    -0x10(%ebp),%eax
400007c7:	77 44                	ja     4000080d <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
400007c9:	8b 45 08             	mov    0x8(%ebp),%eax
400007cc:	8b 40 1c             	mov    0x1c(%eax),%eax
400007cf:	89 c2                	mov    %eax,%edx
400007d1:	c1 fa 1f             	sar    $0x1f,%edx
400007d4:	89 44 24 08          	mov    %eax,0x8(%esp)
400007d8:	89 54 24 0c          	mov    %edx,0xc(%esp)
400007dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
400007df:	8b 55 f4             	mov    -0xc(%ebp),%edx
400007e2:	89 04 24             	mov    %eax,(%esp)
400007e5:	89 54 24 04          	mov    %edx,0x4(%esp)
400007e9:	e8 12 29 00 00       	call   40003100 <__udivdi3>
400007ee:	89 44 24 08          	mov    %eax,0x8(%esp)
400007f2:	89 54 24 0c          	mov    %edx,0xc(%esp)
400007f6:	8b 45 0c             	mov    0xc(%ebp),%eax
400007f9:	89 44 24 04          	mov    %eax,0x4(%esp)
400007fd:	8b 45 08             	mov    0x8(%ebp),%eax
40000800:	89 04 24             	mov    %eax,(%esp)
40000803:	e8 94 ff ff ff       	call   4000079c <genint>
40000808:	89 45 0c             	mov    %eax,0xc(%ebp)
4000080b:	eb 1b                	jmp    40000828 <genint+0x8c>
	else if (st->signc >= 0)
4000080d:	8b 45 08             	mov    0x8(%ebp),%eax
40000810:	8b 40 14             	mov    0x14(%eax),%eax
40000813:	85 c0                	test   %eax,%eax
40000815:	78 11                	js     40000828 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
40000817:	8b 45 08             	mov    0x8(%ebp),%eax
4000081a:	8b 40 14             	mov    0x14(%eax),%eax
4000081d:	89 c2                	mov    %eax,%edx
4000081f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000822:	88 10                	mov    %dl,(%eax)
40000824:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
40000828:	8b 45 08             	mov    0x8(%ebp),%eax
4000082b:	8b 40 1c             	mov    0x1c(%eax),%eax
4000082e:	89 c1                	mov    %eax,%ecx
40000830:	89 c3                	mov    %eax,%ebx
40000832:	c1 fb 1f             	sar    $0x1f,%ebx
40000835:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000838:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000083b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
4000083f:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
40000843:	89 04 24             	mov    %eax,(%esp)
40000846:	89 54 24 04          	mov    %edx,0x4(%esp)
4000084a:	e8 01 2a 00 00       	call   40003250 <__umoddi3>
4000084f:	05 b8 34 00 40       	add    $0x400034b8,%eax
40000854:	0f b6 10             	movzbl (%eax),%edx
40000857:	8b 45 0c             	mov    0xc(%ebp),%eax
4000085a:	88 10                	mov    %dl,(%eax)
4000085c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
40000860:	8b 45 0c             	mov    0xc(%ebp),%eax
}
40000863:	83 c4 24             	add    $0x24,%esp
40000866:	5b                   	pop    %ebx
40000867:	5d                   	pop    %ebp
40000868:	c3                   	ret    

40000869 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
40000869:	55                   	push   %ebp
4000086a:	89 e5                	mov    %esp,%ebp
4000086c:	83 ec 58             	sub    $0x58,%esp
4000086f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000872:	89 45 c0             	mov    %eax,-0x40(%ebp)
40000875:	8b 45 10             	mov    0x10(%ebp),%eax
40000878:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
4000087b:	8d 45 d6             	lea    -0x2a(%ebp),%eax
4000087e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
40000881:	8b 45 08             	mov    0x8(%ebp),%eax
40000884:	8b 55 14             	mov    0x14(%ebp),%edx
40000887:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
4000088a:	8b 45 c0             	mov    -0x40(%ebp),%eax
4000088d:	8b 55 c4             	mov    -0x3c(%ebp),%edx
40000890:	89 44 24 08          	mov    %eax,0x8(%esp)
40000894:	89 54 24 0c          	mov    %edx,0xc(%esp)
40000898:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000089b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000089f:	8b 45 08             	mov    0x8(%ebp),%eax
400008a2:	89 04 24             	mov    %eax,(%esp)
400008a5:	e8 f2 fe ff ff       	call   4000079c <genint>
400008aa:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
400008ad:	8b 55 f4             	mov    -0xc(%ebp),%edx
400008b0:	8d 45 d6             	lea    -0x2a(%ebp),%eax
400008b3:	89 d1                	mov    %edx,%ecx
400008b5:	29 c1                	sub    %eax,%ecx
400008b7:	89 c8                	mov    %ecx,%eax
400008b9:	89 44 24 08          	mov    %eax,0x8(%esp)
400008bd:	8d 45 d6             	lea    -0x2a(%ebp),%eax
400008c0:	89 44 24 04          	mov    %eax,0x4(%esp)
400008c4:	8b 45 08             	mov    0x8(%ebp),%eax
400008c7:	89 04 24             	mov    %eax,(%esp)
400008ca:	e8 08 fe ff ff       	call   400006d7 <putstr>
}
400008cf:	c9                   	leave  
400008d0:	c3                   	ret    

400008d1 <vprintfmt>:


// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
400008d1:	55                   	push   %ebp
400008d2:	89 e5                	mov    %esp,%ebp
400008d4:	53                   	push   %ebx
400008d5:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
400008d8:	8d 55 cc             	lea    -0x34(%ebp),%edx
400008db:	b9 00 00 00 00       	mov    $0x0,%ecx
400008e0:	b8 20 00 00 00       	mov    $0x20,%eax
400008e5:	89 c3                	mov    %eax,%ebx
400008e7:	83 e3 fc             	and    $0xfffffffc,%ebx
400008ea:	b8 00 00 00 00       	mov    $0x0,%eax
400008ef:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
400008f2:	83 c0 04             	add    $0x4,%eax
400008f5:	39 d8                	cmp    %ebx,%eax
400008f7:	72 f6                	jb     400008ef <vprintfmt+0x1e>
400008f9:	01 c2                	add    %eax,%edx
400008fb:	8b 45 08             	mov    0x8(%ebp),%eax
400008fe:	89 45 cc             	mov    %eax,-0x34(%ebp)
40000901:	8b 45 0c             	mov    0xc(%ebp),%eax
40000904:	89 45 d0             	mov    %eax,-0x30(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40000907:	eb 17                	jmp    40000920 <vprintfmt+0x4f>
			if (ch == '\0')
40000909:	85 db                	test   %ebx,%ebx
4000090b:	0f 84 50 03 00 00    	je     40000c61 <vprintfmt+0x390>
				return;
			putch(ch, putdat);
40000911:	8b 45 0c             	mov    0xc(%ebp),%eax
40000914:	89 44 24 04          	mov    %eax,0x4(%esp)
40000918:	89 1c 24             	mov    %ebx,(%esp)
4000091b:	8b 45 08             	mov    0x8(%ebp),%eax
4000091e:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40000920:	8b 45 10             	mov    0x10(%ebp),%eax
40000923:	0f b6 00             	movzbl (%eax),%eax
40000926:	0f b6 d8             	movzbl %al,%ebx
40000929:	83 fb 25             	cmp    $0x25,%ebx
4000092c:	0f 95 c0             	setne  %al
4000092f:	83 45 10 01          	addl   $0x1,0x10(%ebp)
40000933:	84 c0                	test   %al,%al
40000935:	75 d2                	jne    40000909 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
40000937:	c7 45 d4 20 00 00 00 	movl   $0x20,-0x2c(%ebp)
		st.width = -1;
4000093e:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.prec = -1;
40000945:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.signc = -1;
4000094c:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		st.flags = 0;
40000953:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		st.base = 10;
4000095a:	c7 45 e8 0a 00 00 00 	movl   $0xa,-0x18(%ebp)
40000961:	eb 04                	jmp    40000967 <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
40000963:	90                   	nop
40000964:	eb 01                	jmp    40000967 <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
40000966:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
40000967:	8b 45 10             	mov    0x10(%ebp),%eax
4000096a:	0f b6 00             	movzbl (%eax),%eax
4000096d:	0f b6 d8             	movzbl %al,%ebx
40000970:	89 d8                	mov    %ebx,%eax
40000972:	83 45 10 01          	addl   $0x1,0x10(%ebp)
40000976:	83 e8 20             	sub    $0x20,%eax
40000979:	83 f8 58             	cmp    $0x58,%eax
4000097c:	0f 87 ae 02 00 00    	ja     40000c30 <vprintfmt+0x35f>
40000982:	8b 04 85 d0 34 00 40 	mov    0x400034d0(,%eax,4),%eax
40000989:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
4000098b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000098e:	83 c8 10             	or     $0x10,%eax
40000991:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
40000994:	eb d1                	jmp    40000967 <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
40000996:	c7 45 e0 2b 00 00 00 	movl   $0x2b,-0x20(%ebp)
			goto reswitch;
4000099d:	eb c8                	jmp    40000967 <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
4000099f:	8b 45 e0             	mov    -0x20(%ebp),%eax
400009a2:	85 c0                	test   %eax,%eax
400009a4:	79 bd                	jns    40000963 <vprintfmt+0x92>
				st.signc = ' ';
400009a6:	c7 45 e0 20 00 00 00 	movl   $0x20,-0x20(%ebp)
			goto reswitch;
400009ad:	eb b4                	jmp    40000963 <vprintfmt+0x92>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
400009af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400009b2:	83 e0 08             	and    $0x8,%eax
400009b5:	85 c0                	test   %eax,%eax
400009b7:	75 07                	jne    400009c0 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
400009b9:	c7 45 d4 30 00 00 00 	movl   $0x30,-0x2c(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
400009c0:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
				st.prec = st.prec * 10 + ch - '0';
400009c7:	8b 55 dc             	mov    -0x24(%ebp),%edx
400009ca:	89 d0                	mov    %edx,%eax
400009cc:	c1 e0 02             	shl    $0x2,%eax
400009cf:	01 d0                	add    %edx,%eax
400009d1:	01 c0                	add    %eax,%eax
400009d3:	01 d8                	add    %ebx,%eax
400009d5:	83 e8 30             	sub    $0x30,%eax
400009d8:	89 45 dc             	mov    %eax,-0x24(%ebp)
				ch = *fmt;
400009db:	8b 45 10             	mov    0x10(%ebp),%eax
400009de:	0f b6 00             	movzbl (%eax),%eax
400009e1:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
400009e4:	83 fb 2f             	cmp    $0x2f,%ebx
400009e7:	7e 21                	jle    40000a0a <vprintfmt+0x139>
400009e9:	83 fb 39             	cmp    $0x39,%ebx
400009ec:	7f 1c                	jg     40000a0a <vprintfmt+0x139>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
400009ee:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
400009f2:	eb d3                	jmp    400009c7 <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
400009f4:	8b 45 14             	mov    0x14(%ebp),%eax
400009f7:	83 c0 04             	add    $0x4,%eax
400009fa:	89 45 14             	mov    %eax,0x14(%ebp)
400009fd:	8b 45 14             	mov    0x14(%ebp),%eax
40000a00:	83 e8 04             	sub    $0x4,%eax
40000a03:	8b 00                	mov    (%eax),%eax
40000a05:	89 45 dc             	mov    %eax,-0x24(%ebp)
40000a08:	eb 01                	jmp    40000a0b <vprintfmt+0x13a>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
40000a0a:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
40000a0b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40000a0e:	83 e0 08             	and    $0x8,%eax
40000a11:	85 c0                	test   %eax,%eax
40000a13:	0f 85 4d ff ff ff    	jne    40000966 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
40000a19:	8b 45 dc             	mov    -0x24(%ebp),%eax
40000a1c:	89 45 d8             	mov    %eax,-0x28(%ebp)
				st.prec = -1;
40000a1f:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
			}
			goto reswitch;
40000a26:	e9 3b ff ff ff       	jmp    40000966 <vprintfmt+0x95>

		case '.':
			st.flags |= F_DOT;
40000a2b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40000a2e:	83 c8 08             	or     $0x8,%eax
40000a31:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
40000a34:	e9 2e ff ff ff       	jmp    40000967 <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
40000a39:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40000a3c:	83 c8 04             	or     $0x4,%eax
40000a3f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
40000a42:	e9 20 ff ff ff       	jmp    40000967 <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
40000a47:	8b 55 e4             	mov    -0x1c(%ebp),%edx
40000a4a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40000a4d:	83 e0 01             	and    $0x1,%eax
40000a50:	85 c0                	test   %eax,%eax
40000a52:	74 07                	je     40000a5b <vprintfmt+0x18a>
40000a54:	b8 02 00 00 00       	mov    $0x2,%eax
40000a59:	eb 05                	jmp    40000a60 <vprintfmt+0x18f>
40000a5b:	b8 01 00 00 00       	mov    $0x1,%eax
40000a60:	09 d0                	or     %edx,%eax
40000a62:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
40000a65:	e9 fd fe ff ff       	jmp    40000967 <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
40000a6a:	8b 45 14             	mov    0x14(%ebp),%eax
40000a6d:	83 c0 04             	add    $0x4,%eax
40000a70:	89 45 14             	mov    %eax,0x14(%ebp)
40000a73:	8b 45 14             	mov    0x14(%ebp),%eax
40000a76:	83 e8 04             	sub    $0x4,%eax
40000a79:	8b 00                	mov    (%eax),%eax
40000a7b:	8b 55 0c             	mov    0xc(%ebp),%edx
40000a7e:	89 54 24 04          	mov    %edx,0x4(%esp)
40000a82:	89 04 24             	mov    %eax,(%esp)
40000a85:	8b 45 08             	mov    0x8(%ebp),%eax
40000a88:	ff d0                	call   *%eax
			break;
40000a8a:	e9 cc 01 00 00       	jmp    40000c5b <vprintfmt+0x38a>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
40000a8f:	8b 45 14             	mov    0x14(%ebp),%eax
40000a92:	83 c0 04             	add    $0x4,%eax
40000a95:	89 45 14             	mov    %eax,0x14(%ebp)
40000a98:	8b 45 14             	mov    0x14(%ebp),%eax
40000a9b:	83 e8 04             	sub    $0x4,%eax
40000a9e:	8b 00                	mov    (%eax),%eax
40000aa0:	89 45 ec             	mov    %eax,-0x14(%ebp)
40000aa3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
40000aa7:	75 07                	jne    40000ab0 <vprintfmt+0x1df>
				s = "(null)";
40000aa9:	c7 45 ec c9 34 00 40 	movl   $0x400034c9,-0x14(%ebp)
			putstr(&st, s, st.prec);
40000ab0:	8b 45 dc             	mov    -0x24(%ebp),%eax
40000ab3:	89 44 24 08          	mov    %eax,0x8(%esp)
40000ab7:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000aba:	89 44 24 04          	mov    %eax,0x4(%esp)
40000abe:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000ac1:	89 04 24             	mov    %eax,(%esp)
40000ac4:	e8 0e fc ff ff       	call   400006d7 <putstr>
			break;
40000ac9:	e9 8d 01 00 00       	jmp    40000c5b <vprintfmt+0x38a>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
40000ace:	8d 45 14             	lea    0x14(%ebp),%eax
40000ad1:	89 44 24 04          	mov    %eax,0x4(%esp)
40000ad5:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000ad8:	89 04 24             	mov    %eax,(%esp)
40000adb:	e8 45 fb ff ff       	call   40000625 <getint>
40000ae0:	89 45 f0             	mov    %eax,-0x10(%ebp)
40000ae3:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((intmax_t) num < 0) {
40000ae6:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000ae9:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000aec:	85 d2                	test   %edx,%edx
40000aee:	79 1a                	jns    40000b0a <vprintfmt+0x239>
				num = -(intmax_t) num;
40000af0:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000af3:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000af6:	f7 d8                	neg    %eax
40000af8:	83 d2 00             	adc    $0x0,%edx
40000afb:	f7 da                	neg    %edx
40000afd:	89 45 f0             	mov    %eax,-0x10(%ebp)
40000b00:	89 55 f4             	mov    %edx,-0xc(%ebp)
				st.signc = '-';
40000b03:	c7 45 e0 2d 00 00 00 	movl   $0x2d,-0x20(%ebp)
			}
			putint(&st, num, 10);
40000b0a:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
40000b11:	00 
40000b12:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000b15:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000b18:	89 44 24 04          	mov    %eax,0x4(%esp)
40000b1c:	89 54 24 08          	mov    %edx,0x8(%esp)
40000b20:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000b23:	89 04 24             	mov    %eax,(%esp)
40000b26:	e8 3e fd ff ff       	call   40000869 <putint>
			break;
40000b2b:	e9 2b 01 00 00       	jmp    40000c5b <vprintfmt+0x38a>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
40000b30:	8d 45 14             	lea    0x14(%ebp),%eax
40000b33:	89 44 24 04          	mov    %eax,0x4(%esp)
40000b37:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000b3a:	89 04 24             	mov    %eax,(%esp)
40000b3d:	e8 6e fa ff ff       	call   400005b0 <getuint>
40000b42:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
40000b49:	00 
40000b4a:	89 44 24 04          	mov    %eax,0x4(%esp)
40000b4e:	89 54 24 08          	mov    %edx,0x8(%esp)
40000b52:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000b55:	89 04 24             	mov    %eax,(%esp)
40000b58:	e8 0c fd ff ff       	call   40000869 <putint>
			break;
40000b5d:	e9 f9 00 00 00       	jmp    40000c5b <vprintfmt+0x38a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
40000b62:	8d 45 14             	lea    0x14(%ebp),%eax
40000b65:	89 44 24 04          	mov    %eax,0x4(%esp)
40000b69:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000b6c:	89 04 24             	mov    %eax,(%esp)
40000b6f:	e8 3c fa ff ff       	call   400005b0 <getuint>
40000b74:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
40000b7b:	00 
40000b7c:	89 44 24 04          	mov    %eax,0x4(%esp)
40000b80:	89 54 24 08          	mov    %edx,0x8(%esp)
40000b84:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000b87:	89 04 24             	mov    %eax,(%esp)
40000b8a:	e8 da fc ff ff       	call   40000869 <putint>
			break;
40000b8f:	e9 c7 00 00 00       	jmp    40000c5b <vprintfmt+0x38a>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
40000b94:	8d 45 14             	lea    0x14(%ebp),%eax
40000b97:	89 44 24 04          	mov    %eax,0x4(%esp)
40000b9b:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000b9e:	89 04 24             	mov    %eax,(%esp)
40000ba1:	e8 0a fa ff ff       	call   400005b0 <getuint>
40000ba6:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
40000bad:	00 
40000bae:	89 44 24 04          	mov    %eax,0x4(%esp)
40000bb2:	89 54 24 08          	mov    %edx,0x8(%esp)
40000bb6:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000bb9:	89 04 24             	mov    %eax,(%esp)
40000bbc:	e8 a8 fc ff ff       	call   40000869 <putint>
			break;
40000bc1:	e9 95 00 00 00       	jmp    40000c5b <vprintfmt+0x38a>

		// pointer
		case 'p':
			putch('0', putdat);
40000bc6:	8b 45 0c             	mov    0xc(%ebp),%eax
40000bc9:	89 44 24 04          	mov    %eax,0x4(%esp)
40000bcd:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
40000bd4:	8b 45 08             	mov    0x8(%ebp),%eax
40000bd7:	ff d0                	call   *%eax
			putch('x', putdat);
40000bd9:	8b 45 0c             	mov    0xc(%ebp),%eax
40000bdc:	89 44 24 04          	mov    %eax,0x4(%esp)
40000be0:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
40000be7:	8b 45 08             	mov    0x8(%ebp),%eax
40000bea:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
40000bec:	8b 45 14             	mov    0x14(%ebp),%eax
40000bef:	83 c0 04             	add    $0x4,%eax
40000bf2:	89 45 14             	mov    %eax,0x14(%ebp)
40000bf5:	8b 45 14             	mov    0x14(%ebp),%eax
40000bf8:	83 e8 04             	sub    $0x4,%eax
40000bfb:	8b 00                	mov    (%eax),%eax
40000bfd:	ba 00 00 00 00       	mov    $0x0,%edx
40000c02:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
40000c09:	00 
40000c0a:	89 44 24 04          	mov    %eax,0x4(%esp)
40000c0e:	89 54 24 08          	mov    %edx,0x8(%esp)
40000c12:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000c15:	89 04 24             	mov    %eax,(%esp)
40000c18:	e8 4c fc ff ff       	call   40000869 <putint>
			break;
40000c1d:	eb 3c                	jmp    40000c5b <vprintfmt+0x38a>


		// escaped '%' character
		case '%':
			putch(ch, putdat);
40000c1f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000c22:	89 44 24 04          	mov    %eax,0x4(%esp)
40000c26:	89 1c 24             	mov    %ebx,(%esp)
40000c29:	8b 45 08             	mov    0x8(%ebp),%eax
40000c2c:	ff d0                	call   *%eax
			break;
40000c2e:	eb 2b                	jmp    40000c5b <vprintfmt+0x38a>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
40000c30:	8b 45 0c             	mov    0xc(%ebp),%eax
40000c33:	89 44 24 04          	mov    %eax,0x4(%esp)
40000c37:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
40000c3e:	8b 45 08             	mov    0x8(%ebp),%eax
40000c41:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
40000c43:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40000c47:	eb 04                	jmp    40000c4d <vprintfmt+0x37c>
40000c49:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40000c4d:	8b 45 10             	mov    0x10(%ebp),%eax
40000c50:	83 e8 01             	sub    $0x1,%eax
40000c53:	0f b6 00             	movzbl (%eax),%eax
40000c56:	3c 25                	cmp    $0x25,%al
40000c58:	75 ef                	jne    40000c49 <vprintfmt+0x378>
				/* do nothing */;
			break;
40000c5a:	90                   	nop
		}
	}
40000c5b:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40000c5c:	e9 bf fc ff ff       	jmp    40000920 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
40000c61:	83 c4 44             	add    $0x44,%esp
40000c64:	5b                   	pop    %ebx
40000c65:	5d                   	pop    %ebp
40000c66:	c3                   	ret    
40000c67:	90                   	nop

40000c68 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
40000c68:	55                   	push   %ebp
40000c69:	89 e5                	mov    %esp,%ebp
40000c6b:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
40000c6e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
40000c75:	eb 08                	jmp    40000c7f <strlen+0x17>
		n++;
40000c77:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
40000c7b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000c7f:	8b 45 08             	mov    0x8(%ebp),%eax
40000c82:	0f b6 00             	movzbl (%eax),%eax
40000c85:	84 c0                	test   %al,%al
40000c87:	75 ee                	jne    40000c77 <strlen+0xf>
		n++;
	return n;
40000c89:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
40000c8c:	c9                   	leave  
40000c8d:	c3                   	ret    

40000c8e <strcpy>:

char *
strcpy(char *dst, const char *src)
{
40000c8e:	55                   	push   %ebp
40000c8f:	89 e5                	mov    %esp,%ebp
40000c91:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
40000c94:	8b 45 08             	mov    0x8(%ebp),%eax
40000c97:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
40000c9a:	90                   	nop
40000c9b:	8b 45 0c             	mov    0xc(%ebp),%eax
40000c9e:	0f b6 10             	movzbl (%eax),%edx
40000ca1:	8b 45 08             	mov    0x8(%ebp),%eax
40000ca4:	88 10                	mov    %dl,(%eax)
40000ca6:	8b 45 08             	mov    0x8(%ebp),%eax
40000ca9:	0f b6 00             	movzbl (%eax),%eax
40000cac:	84 c0                	test   %al,%al
40000cae:	0f 95 c0             	setne  %al
40000cb1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000cb5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
40000cb9:	84 c0                	test   %al,%al
40000cbb:	75 de                	jne    40000c9b <strcpy+0xd>
		/* do nothing */;
	return ret;
40000cbd:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
40000cc0:	c9                   	leave  
40000cc1:	c3                   	ret    

40000cc2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
40000cc2:	55                   	push   %ebp
40000cc3:	89 e5                	mov    %esp,%ebp
40000cc5:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
40000cc8:	8b 45 08             	mov    0x8(%ebp),%eax
40000ccb:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
40000cce:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
40000cd5:	eb 21                	jmp    40000cf8 <strncpy+0x36>
		*dst++ = *src;
40000cd7:	8b 45 0c             	mov    0xc(%ebp),%eax
40000cda:	0f b6 10             	movzbl (%eax),%edx
40000cdd:	8b 45 08             	mov    0x8(%ebp),%eax
40000ce0:	88 10                	mov    %dl,(%eax)
40000ce2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
40000ce6:	8b 45 0c             	mov    0xc(%ebp),%eax
40000ce9:	0f b6 00             	movzbl (%eax),%eax
40000cec:	84 c0                	test   %al,%al
40000cee:	74 04                	je     40000cf4 <strncpy+0x32>
			src++;
40000cf0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
40000cf4:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40000cf8:	8b 45 fc             	mov    -0x4(%ebp),%eax
40000cfb:	3b 45 10             	cmp    0x10(%ebp),%eax
40000cfe:	72 d7                	jb     40000cd7 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
40000d00:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
40000d03:	c9                   	leave  
40000d04:	c3                   	ret    

40000d05 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
40000d05:	55                   	push   %ebp
40000d06:	89 e5                	mov    %esp,%ebp
40000d08:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
40000d0b:	8b 45 08             	mov    0x8(%ebp),%eax
40000d0e:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
40000d11:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000d15:	74 2f                	je     40000d46 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
40000d17:	eb 13                	jmp    40000d2c <strlcpy+0x27>
			*dst++ = *src++;
40000d19:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d1c:	0f b6 10             	movzbl (%eax),%edx
40000d1f:	8b 45 08             	mov    0x8(%ebp),%eax
40000d22:	88 10                	mov    %dl,(%eax)
40000d24:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000d28:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
40000d2c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40000d30:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000d34:	74 0a                	je     40000d40 <strlcpy+0x3b>
40000d36:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d39:	0f b6 00             	movzbl (%eax),%eax
40000d3c:	84 c0                	test   %al,%al
40000d3e:	75 d9                	jne    40000d19 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
40000d40:	8b 45 08             	mov    0x8(%ebp),%eax
40000d43:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
40000d46:	8b 55 08             	mov    0x8(%ebp),%edx
40000d49:	8b 45 fc             	mov    -0x4(%ebp),%eax
40000d4c:	89 d1                	mov    %edx,%ecx
40000d4e:	29 c1                	sub    %eax,%ecx
40000d50:	89 c8                	mov    %ecx,%eax
}
40000d52:	c9                   	leave  
40000d53:	c3                   	ret    

40000d54 <strcmp>:

int
strcmp(const char *p, const char *q)
{
40000d54:	55                   	push   %ebp
40000d55:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
40000d57:	eb 08                	jmp    40000d61 <strcmp+0xd>
		p++, q++;
40000d59:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000d5d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
40000d61:	8b 45 08             	mov    0x8(%ebp),%eax
40000d64:	0f b6 00             	movzbl (%eax),%eax
40000d67:	84 c0                	test   %al,%al
40000d69:	74 10                	je     40000d7b <strcmp+0x27>
40000d6b:	8b 45 08             	mov    0x8(%ebp),%eax
40000d6e:	0f b6 10             	movzbl (%eax),%edx
40000d71:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d74:	0f b6 00             	movzbl (%eax),%eax
40000d77:	38 c2                	cmp    %al,%dl
40000d79:	74 de                	je     40000d59 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
40000d7b:	8b 45 08             	mov    0x8(%ebp),%eax
40000d7e:	0f b6 00             	movzbl (%eax),%eax
40000d81:	0f b6 d0             	movzbl %al,%edx
40000d84:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d87:	0f b6 00             	movzbl (%eax),%eax
40000d8a:	0f b6 c0             	movzbl %al,%eax
40000d8d:	89 d1                	mov    %edx,%ecx
40000d8f:	29 c1                	sub    %eax,%ecx
40000d91:	89 c8                	mov    %ecx,%eax
}
40000d93:	5d                   	pop    %ebp
40000d94:	c3                   	ret    

40000d95 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
40000d95:	55                   	push   %ebp
40000d96:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
40000d98:	eb 0c                	jmp    40000da6 <strncmp+0x11>
		n--, p++, q++;
40000d9a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40000d9e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000da2:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
40000da6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000daa:	74 1a                	je     40000dc6 <strncmp+0x31>
40000dac:	8b 45 08             	mov    0x8(%ebp),%eax
40000daf:	0f b6 00             	movzbl (%eax),%eax
40000db2:	84 c0                	test   %al,%al
40000db4:	74 10                	je     40000dc6 <strncmp+0x31>
40000db6:	8b 45 08             	mov    0x8(%ebp),%eax
40000db9:	0f b6 10             	movzbl (%eax),%edx
40000dbc:	8b 45 0c             	mov    0xc(%ebp),%eax
40000dbf:	0f b6 00             	movzbl (%eax),%eax
40000dc2:	38 c2                	cmp    %al,%dl
40000dc4:	74 d4                	je     40000d9a <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
40000dc6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000dca:	75 07                	jne    40000dd3 <strncmp+0x3e>
		return 0;
40000dcc:	b8 00 00 00 00       	mov    $0x0,%eax
40000dd1:	eb 18                	jmp    40000deb <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
40000dd3:	8b 45 08             	mov    0x8(%ebp),%eax
40000dd6:	0f b6 00             	movzbl (%eax),%eax
40000dd9:	0f b6 d0             	movzbl %al,%edx
40000ddc:	8b 45 0c             	mov    0xc(%ebp),%eax
40000ddf:	0f b6 00             	movzbl (%eax),%eax
40000de2:	0f b6 c0             	movzbl %al,%eax
40000de5:	89 d1                	mov    %edx,%ecx
40000de7:	29 c1                	sub    %eax,%ecx
40000de9:	89 c8                	mov    %ecx,%eax
}
40000deb:	5d                   	pop    %ebp
40000dec:	c3                   	ret    

40000ded <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
40000ded:	55                   	push   %ebp
40000dee:	89 e5                	mov    %esp,%ebp
40000df0:	83 ec 04             	sub    $0x4,%esp
40000df3:	8b 45 0c             	mov    0xc(%ebp),%eax
40000df6:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
40000df9:	eb 1a                	jmp    40000e15 <strchr+0x28>
		if (*s++ == 0)
40000dfb:	8b 45 08             	mov    0x8(%ebp),%eax
40000dfe:	0f b6 00             	movzbl (%eax),%eax
40000e01:	84 c0                	test   %al,%al
40000e03:	0f 94 c0             	sete   %al
40000e06:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000e0a:	84 c0                	test   %al,%al
40000e0c:	74 07                	je     40000e15 <strchr+0x28>
			return NULL;
40000e0e:	b8 00 00 00 00       	mov    $0x0,%eax
40000e13:	eb 0e                	jmp    40000e23 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
40000e15:	8b 45 08             	mov    0x8(%ebp),%eax
40000e18:	0f b6 00             	movzbl (%eax),%eax
40000e1b:	3a 45 fc             	cmp    -0x4(%ebp),%al
40000e1e:	75 db                	jne    40000dfb <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
40000e20:	8b 45 08             	mov    0x8(%ebp),%eax
}
40000e23:	c9                   	leave  
40000e24:	c3                   	ret    

40000e25 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
40000e25:	55                   	push   %ebp
40000e26:	89 e5                	mov    %esp,%ebp
40000e28:	57                   	push   %edi
	char *p;

	if (n == 0)
40000e29:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000e2d:	75 05                	jne    40000e34 <memset+0xf>
		return v;
40000e2f:	8b 45 08             	mov    0x8(%ebp),%eax
40000e32:	eb 5c                	jmp    40000e90 <memset+0x6b>
	if ((int)v%4 == 0 && n%4 == 0) {
40000e34:	8b 45 08             	mov    0x8(%ebp),%eax
40000e37:	83 e0 03             	and    $0x3,%eax
40000e3a:	85 c0                	test   %eax,%eax
40000e3c:	75 41                	jne    40000e7f <memset+0x5a>
40000e3e:	8b 45 10             	mov    0x10(%ebp),%eax
40000e41:	83 e0 03             	and    $0x3,%eax
40000e44:	85 c0                	test   %eax,%eax
40000e46:	75 37                	jne    40000e7f <memset+0x5a>
		c &= 0xFF;
40000e48:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
40000e4f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000e52:	89 c2                	mov    %eax,%edx
40000e54:	c1 e2 18             	shl    $0x18,%edx
40000e57:	8b 45 0c             	mov    0xc(%ebp),%eax
40000e5a:	c1 e0 10             	shl    $0x10,%eax
40000e5d:	09 c2                	or     %eax,%edx
40000e5f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000e62:	c1 e0 08             	shl    $0x8,%eax
40000e65:	09 d0                	or     %edx,%eax
40000e67:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
40000e6a:	8b 45 10             	mov    0x10(%ebp),%eax
40000e6d:	89 c1                	mov    %eax,%ecx
40000e6f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
40000e72:	8b 55 08             	mov    0x8(%ebp),%edx
40000e75:	8b 45 0c             	mov    0xc(%ebp),%eax
40000e78:	89 d7                	mov    %edx,%edi
40000e7a:	fc                   	cld    
40000e7b:	f3 ab                	rep stos %eax,%es:(%edi)
40000e7d:	eb 0e                	jmp    40000e8d <memset+0x68>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
40000e7f:	8b 55 08             	mov    0x8(%ebp),%edx
40000e82:	8b 45 0c             	mov    0xc(%ebp),%eax
40000e85:	8b 4d 10             	mov    0x10(%ebp),%ecx
40000e88:	89 d7                	mov    %edx,%edi
40000e8a:	fc                   	cld    
40000e8b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
40000e8d:	8b 45 08             	mov    0x8(%ebp),%eax
}
40000e90:	5f                   	pop    %edi
40000e91:	5d                   	pop    %ebp
40000e92:	c3                   	ret    

40000e93 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
40000e93:	55                   	push   %ebp
40000e94:	89 e5                	mov    %esp,%ebp
40000e96:	57                   	push   %edi
40000e97:	56                   	push   %esi
40000e98:	53                   	push   %ebx
40000e99:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
40000e9c:	8b 45 0c             	mov    0xc(%ebp),%eax
40000e9f:	89 45 f0             	mov    %eax,-0x10(%ebp)
	d = dst;
40000ea2:	8b 45 08             	mov    0x8(%ebp),%eax
40000ea5:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (s < d && s + n > d) {
40000ea8:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000eab:	3b 45 ec             	cmp    -0x14(%ebp),%eax
40000eae:	73 6d                	jae    40000f1d <memmove+0x8a>
40000eb0:	8b 45 10             	mov    0x10(%ebp),%eax
40000eb3:	8b 55 f0             	mov    -0x10(%ebp),%edx
40000eb6:	01 d0                	add    %edx,%eax
40000eb8:	3b 45 ec             	cmp    -0x14(%ebp),%eax
40000ebb:	76 60                	jbe    40000f1d <memmove+0x8a>
		s += n;
40000ebd:	8b 45 10             	mov    0x10(%ebp),%eax
40000ec0:	01 45 f0             	add    %eax,-0x10(%ebp)
		d += n;
40000ec3:	8b 45 10             	mov    0x10(%ebp),%eax
40000ec6:	01 45 ec             	add    %eax,-0x14(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
40000ec9:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000ecc:	83 e0 03             	and    $0x3,%eax
40000ecf:	85 c0                	test   %eax,%eax
40000ed1:	75 2f                	jne    40000f02 <memmove+0x6f>
40000ed3:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000ed6:	83 e0 03             	and    $0x3,%eax
40000ed9:	85 c0                	test   %eax,%eax
40000edb:	75 25                	jne    40000f02 <memmove+0x6f>
40000edd:	8b 45 10             	mov    0x10(%ebp),%eax
40000ee0:	83 e0 03             	and    $0x3,%eax
40000ee3:	85 c0                	test   %eax,%eax
40000ee5:	75 1b                	jne    40000f02 <memmove+0x6f>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
40000ee7:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000eea:	83 e8 04             	sub    $0x4,%eax
40000eed:	8b 55 f0             	mov    -0x10(%ebp),%edx
40000ef0:	83 ea 04             	sub    $0x4,%edx
40000ef3:	8b 4d 10             	mov    0x10(%ebp),%ecx
40000ef6:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
40000ef9:	89 c7                	mov    %eax,%edi
40000efb:	89 d6                	mov    %edx,%esi
40000efd:	fd                   	std    
40000efe:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
40000f00:	eb 18                	jmp    40000f1a <memmove+0x87>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
40000f02:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000f05:	8d 50 ff             	lea    -0x1(%eax),%edx
40000f08:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000f0b:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
40000f0e:	8b 45 10             	mov    0x10(%ebp),%eax
40000f11:	89 d7                	mov    %edx,%edi
40000f13:	89 de                	mov    %ebx,%esi
40000f15:	89 c1                	mov    %eax,%ecx
40000f17:	fd                   	std    
40000f18:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
40000f1a:	fc                   	cld    
40000f1b:	eb 45                	jmp    40000f62 <memmove+0xcf>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
40000f1d:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000f20:	83 e0 03             	and    $0x3,%eax
40000f23:	85 c0                	test   %eax,%eax
40000f25:	75 2b                	jne    40000f52 <memmove+0xbf>
40000f27:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000f2a:	83 e0 03             	and    $0x3,%eax
40000f2d:	85 c0                	test   %eax,%eax
40000f2f:	75 21                	jne    40000f52 <memmove+0xbf>
40000f31:	8b 45 10             	mov    0x10(%ebp),%eax
40000f34:	83 e0 03             	and    $0x3,%eax
40000f37:	85 c0                	test   %eax,%eax
40000f39:	75 17                	jne    40000f52 <memmove+0xbf>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
40000f3b:	8b 45 10             	mov    0x10(%ebp),%eax
40000f3e:	89 c1                	mov    %eax,%ecx
40000f40:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
40000f43:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000f46:	8b 55 f0             	mov    -0x10(%ebp),%edx
40000f49:	89 c7                	mov    %eax,%edi
40000f4b:	89 d6                	mov    %edx,%esi
40000f4d:	fc                   	cld    
40000f4e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
40000f50:	eb 10                	jmp    40000f62 <memmove+0xcf>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
40000f52:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000f55:	8b 55 f0             	mov    -0x10(%ebp),%edx
40000f58:	8b 4d 10             	mov    0x10(%ebp),%ecx
40000f5b:	89 c7                	mov    %eax,%edi
40000f5d:	89 d6                	mov    %edx,%esi
40000f5f:	fc                   	cld    
40000f60:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
40000f62:	8b 45 08             	mov    0x8(%ebp),%eax
}
40000f65:	83 c4 10             	add    $0x10,%esp
40000f68:	5b                   	pop    %ebx
40000f69:	5e                   	pop    %esi
40000f6a:	5f                   	pop    %edi
40000f6b:	5d                   	pop    %ebp
40000f6c:	c3                   	ret    

40000f6d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
40000f6d:	55                   	push   %ebp
40000f6e:	89 e5                	mov    %esp,%ebp
40000f70:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
40000f73:	8b 45 10             	mov    0x10(%ebp),%eax
40000f76:	89 44 24 08          	mov    %eax,0x8(%esp)
40000f7a:	8b 45 0c             	mov    0xc(%ebp),%eax
40000f7d:	89 44 24 04          	mov    %eax,0x4(%esp)
40000f81:	8b 45 08             	mov    0x8(%ebp),%eax
40000f84:	89 04 24             	mov    %eax,(%esp)
40000f87:	e8 07 ff ff ff       	call   40000e93 <memmove>
}
40000f8c:	c9                   	leave  
40000f8d:	c3                   	ret    

40000f8e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
40000f8e:	55                   	push   %ebp
40000f8f:	89 e5                	mov    %esp,%ebp
40000f91:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
40000f94:	8b 45 08             	mov    0x8(%ebp),%eax
40000f97:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
40000f9a:	8b 45 0c             	mov    0xc(%ebp),%eax
40000f9d:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
40000fa0:	eb 32                	jmp    40000fd4 <memcmp+0x46>
		if (*s1 != *s2)
40000fa2:	8b 45 fc             	mov    -0x4(%ebp),%eax
40000fa5:	0f b6 10             	movzbl (%eax),%edx
40000fa8:	8b 45 f8             	mov    -0x8(%ebp),%eax
40000fab:	0f b6 00             	movzbl (%eax),%eax
40000fae:	38 c2                	cmp    %al,%dl
40000fb0:	74 1a                	je     40000fcc <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
40000fb2:	8b 45 fc             	mov    -0x4(%ebp),%eax
40000fb5:	0f b6 00             	movzbl (%eax),%eax
40000fb8:	0f b6 d0             	movzbl %al,%edx
40000fbb:	8b 45 f8             	mov    -0x8(%ebp),%eax
40000fbe:	0f b6 00             	movzbl (%eax),%eax
40000fc1:	0f b6 c0             	movzbl %al,%eax
40000fc4:	89 d1                	mov    %edx,%ecx
40000fc6:	29 c1                	sub    %eax,%ecx
40000fc8:	89 c8                	mov    %ecx,%eax
40000fca:	eb 1c                	jmp    40000fe8 <memcmp+0x5a>
		s1++, s2++;
40000fcc:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40000fd0:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
40000fd4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000fd8:	0f 95 c0             	setne  %al
40000fdb:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40000fdf:	84 c0                	test   %al,%al
40000fe1:	75 bf                	jne    40000fa2 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
40000fe3:	b8 00 00 00 00       	mov    $0x0,%eax
}
40000fe8:	c9                   	leave  
40000fe9:	c3                   	ret    

40000fea <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
40000fea:	55                   	push   %ebp
40000feb:	89 e5                	mov    %esp,%ebp
40000fed:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
40000ff0:	8b 45 10             	mov    0x10(%ebp),%eax
40000ff3:	8b 55 08             	mov    0x8(%ebp),%edx
40000ff6:	01 d0                	add    %edx,%eax
40000ff8:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
40000ffb:	eb 16                	jmp    40001013 <memchr+0x29>
		if (*(const unsigned char *) s == (unsigned char) c)
40000ffd:	8b 45 08             	mov    0x8(%ebp),%eax
40001000:	0f b6 10             	movzbl (%eax),%edx
40001003:	8b 45 0c             	mov    0xc(%ebp),%eax
40001006:	38 c2                	cmp    %al,%dl
40001008:	75 05                	jne    4000100f <memchr+0x25>
			return (void *) s;
4000100a:	8b 45 08             	mov    0x8(%ebp),%eax
4000100d:	eb 11                	jmp    40001020 <memchr+0x36>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
4000100f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40001013:	8b 45 08             	mov    0x8(%ebp),%eax
40001016:	3b 45 fc             	cmp    -0x4(%ebp),%eax
40001019:	72 e2                	jb     40000ffd <memchr+0x13>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
4000101b:	b8 00 00 00 00       	mov    $0x0,%eax
}
40001020:	c9                   	leave  
40001021:	c3                   	ret    
40001022:	66 90                	xchg   %ax,%ax

40001024 <fileino_alloc>:

// Find and return the index of a currently unused file inode in this process.
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_alloc(void)
{
40001024:	55                   	push   %ebp
40001025:	89 e5                	mov    %esp,%ebp
40001027:	83 ec 28             	sub    $0x28,%esp
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
4000102a:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
40001031:	eb 24                	jmp    40001057 <fileino_alloc+0x33>
		if (files->fi[i].de.d_name[0] == 0)
40001033:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40001039:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000103c:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000103f:	01 d0                	add    %edx,%eax
40001041:	05 10 10 00 00       	add    $0x1010,%eax
40001046:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000104a:	84 c0                	test   %al,%al
4000104c:	75 05                	jne    40001053 <fileino_alloc+0x2f>
			return i;
4000104e:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001051:	eb 39                	jmp    4000108c <fileino_alloc+0x68>
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_alloc(void)
{
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40001053:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40001057:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
4000105e:	7e d3                	jle    40001033 <fileino_alloc+0xf>
		if (files->fi[i].de.d_name[0] == 0)
			return i;

	warn("fileino_alloc: no free inodes\n");
40001060:	c7 44 24 08 38 36 00 	movl   $0x40003638,0x8(%esp)
40001067:	40 
40001068:	c7 44 24 04 29 00 00 	movl   $0x29,0x4(%esp)
4000106f:	00 
40001070:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001077:	e8 e2 f2 ff ff       	call   4000035e <debug_warn>
	errno = ENOSPC;
4000107c:	a1 34 36 00 40       	mov    0x40003634,%eax
40001081:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
	return -1;
40001087:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
4000108c:	c9                   	leave  
4000108d:	c3                   	ret    

4000108e <fileino_create>:
// Returns the index of the inode found or created.
// A newly-created inode is left in the "deleted" state, with mode == 0.
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_create(filestate *fs, int dino, const char *name)
{
4000108e:	55                   	push   %ebp
4000108f:	89 e5                	mov    %esp,%ebp
40001091:	83 ec 28             	sub    $0x28,%esp
	assert(dino != 0);
40001094:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40001098:	75 24                	jne    400010be <fileino_create+0x30>
4000109a:	c7 44 24 0c 62 36 00 	movl   $0x40003662,0xc(%esp)
400010a1:	40 
400010a2:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
400010a9:	40 
400010aa:	c7 44 24 04 35 00 00 	movl   $0x35,0x4(%esp)
400010b1:	00 
400010b2:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
400010b9:	e8 36 f2 ff ff       	call   400002f4 <debug_panic>
	assert(name != NULL && name[0] != 0);
400010be:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400010c2:	74 0a                	je     400010ce <fileino_create+0x40>
400010c4:	8b 45 10             	mov    0x10(%ebp),%eax
400010c7:	0f b6 00             	movzbl (%eax),%eax
400010ca:	84 c0                	test   %al,%al
400010cc:	75 24                	jne    400010f2 <fileino_create+0x64>
400010ce:	c7 44 24 0c 81 36 00 	movl   $0x40003681,0xc(%esp)
400010d5:	40 
400010d6:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
400010dd:	40 
400010de:	c7 44 24 04 36 00 00 	movl   $0x36,0x4(%esp)
400010e5:	00 
400010e6:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
400010ed:	e8 02 f2 ff ff       	call   400002f4 <debug_panic>
	assert(strlen(name) <= NAME_MAX);
400010f2:	8b 45 10             	mov    0x10(%ebp),%eax
400010f5:	89 04 24             	mov    %eax,(%esp)
400010f8:	e8 6b fb ff ff       	call   40000c68 <strlen>
400010fd:	83 f8 3f             	cmp    $0x3f,%eax
40001100:	7e 24                	jle    40001126 <fileino_create+0x98>
40001102:	c7 44 24 0c 9e 36 00 	movl   $0x4000369e,0xc(%esp)
40001109:	40 
4000110a:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
40001111:	40 
40001112:	c7 44 24 04 37 00 00 	movl   $0x37,0x4(%esp)
40001119:	00 
4000111a:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001121:	e8 ce f1 ff ff       	call   400002f4 <debug_panic>

	// First see if an inode already exists for this directory and name.
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40001126:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
4000112d:	eb 4a                	jmp    40001179 <fileino_create+0xeb>
		if (fs->fi[i].dino == dino
4000112f:	8b 55 08             	mov    0x8(%ebp),%edx
40001132:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001135:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001138:	01 d0                	add    %edx,%eax
4000113a:	05 10 10 00 00       	add    $0x1010,%eax
4000113f:	8b 00                	mov    (%eax),%eax
40001141:	3b 45 0c             	cmp    0xc(%ebp),%eax
40001144:	75 2f                	jne    40001175 <fileino_create+0xe7>
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
40001146:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001149:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000114c:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40001152:	8b 45 08             	mov    0x8(%ebp),%eax
40001155:	01 d0                	add    %edx,%eax
40001157:	8d 50 04             	lea    0x4(%eax),%edx
4000115a:	8b 45 10             	mov    0x10(%ebp),%eax
4000115d:	89 44 24 04          	mov    %eax,0x4(%esp)
40001161:	89 14 24             	mov    %edx,(%esp)
40001164:	e8 eb fb ff ff       	call   40000d54 <strcmp>
40001169:	85 c0                	test   %eax,%eax
4000116b:	75 08                	jne    40001175 <fileino_create+0xe7>
			return i;
4000116d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001170:	e9 a5 00 00 00       	jmp    4000121a <fileino_create+0x18c>
	assert(name != NULL && name[0] != 0);
	assert(strlen(name) <= NAME_MAX);

	// First see if an inode already exists for this directory and name.
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40001175:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40001179:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
40001180:	7e ad                	jle    4000112f <fileino_create+0xa1>
		if (fs->fi[i].dino == dino
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
			return i;

	// No inode allocated to this name - find a free one to allocate.
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40001182:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
40001189:	eb 5a                	jmp    400011e5 <fileino_create+0x157>
		if (fs->fi[i].de.d_name[0] == 0) {
4000118b:	8b 55 08             	mov    0x8(%ebp),%edx
4000118e:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001191:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001194:	01 d0                	add    %edx,%eax
40001196:	05 10 10 00 00       	add    $0x1010,%eax
4000119b:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000119f:	84 c0                	test   %al,%al
400011a1:	75 3e                	jne    400011e1 <fileino_create+0x153>
			fs->fi[i].dino = dino;
400011a3:	8b 55 08             	mov    0x8(%ebp),%edx
400011a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
400011a9:	6b c0 5c             	imul   $0x5c,%eax,%eax
400011ac:	01 d0                	add    %edx,%eax
400011ae:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400011b4:	8b 45 0c             	mov    0xc(%ebp),%eax
400011b7:	89 02                	mov    %eax,(%edx)
			strcpy(fs->fi[i].de.d_name, name);
400011b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
400011bc:	6b c0 5c             	imul   $0x5c,%eax,%eax
400011bf:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400011c5:	8b 45 08             	mov    0x8(%ebp),%eax
400011c8:	01 d0                	add    %edx,%eax
400011ca:	8d 50 04             	lea    0x4(%eax),%edx
400011cd:	8b 45 10             	mov    0x10(%ebp),%eax
400011d0:	89 44 24 04          	mov    %eax,0x4(%esp)
400011d4:	89 14 24             	mov    %edx,(%esp)
400011d7:	e8 b2 fa ff ff       	call   40000c8e <strcpy>
			return i;
400011dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
400011df:	eb 39                	jmp    4000121a <fileino_create+0x18c>
		if (fs->fi[i].dino == dino
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
			return i;

	// No inode allocated to this name - find a free one to allocate.
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
400011e1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
400011e5:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
400011ec:	7e 9d                	jle    4000118b <fileino_create+0xfd>
			fs->fi[i].dino = dino;
			strcpy(fs->fi[i].de.d_name, name);
			return i;
		}

	warn("fileino_create: no free inodes\n");
400011ee:	c7 44 24 08 b8 36 00 	movl   $0x400036b8,0x8(%esp)
400011f5:	40 
400011f6:	c7 44 24 04 48 00 00 	movl   $0x48,0x4(%esp)
400011fd:	00 
400011fe:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001205:	e8 54 f1 ff ff       	call   4000035e <debug_warn>
	errno = ENOSPC;
4000120a:	a1 34 36 00 40       	mov    0x40003634,%eax
4000120f:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
	return -1;
40001215:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
4000121a:	c9                   	leave  
4000121b:	c3                   	ret    

4000121c <fileino_read>:
// The number of elements returned is normally equal to the 'count' parameter,
// but may be less (without resulting in an error)
// if the file is not large enough to read that many elements.
ssize_t
fileino_read(int ino, off_t ofs, void *buf, size_t eltsize, size_t count)
{
4000121c:	55                   	push   %ebp
4000121d:	89 e5                	mov    %esp,%ebp
4000121f:	83 ec 28             	sub    $0x28,%esp
	assert(fileino_isreg(ino));
40001222:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001226:	7e 45                	jle    4000126d <fileino_read+0x51>
40001228:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
4000122f:	7f 3c                	jg     4000126d <fileino_read+0x51>
40001231:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40001237:	8b 45 08             	mov    0x8(%ebp),%eax
4000123a:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000123d:	01 d0                	add    %edx,%eax
4000123f:	05 10 10 00 00       	add    $0x1010,%eax
40001244:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40001248:	84 c0                	test   %al,%al
4000124a:	74 21                	je     4000126d <fileino_read+0x51>
4000124c:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40001252:	8b 45 08             	mov    0x8(%ebp),%eax
40001255:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001258:	01 d0                	add    %edx,%eax
4000125a:	05 58 10 00 00       	add    $0x1058,%eax
4000125f:	8b 00                	mov    (%eax),%eax
40001261:	25 00 70 00 00       	and    $0x7000,%eax
40001266:	3d 00 10 00 00       	cmp    $0x1000,%eax
4000126b:	74 24                	je     40001291 <fileino_read+0x75>
4000126d:	c7 44 24 0c d8 36 00 	movl   $0x400036d8,0xc(%esp)
40001274:	40 
40001275:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
4000127c:	40 
4000127d:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
40001284:	00 
40001285:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
4000128c:	e8 63 f0 ff ff       	call   400002f4 <debug_panic>
	assert(ofs >= 0);
40001291:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40001295:	79 24                	jns    400012bb <fileino_read+0x9f>
40001297:	c7 44 24 0c eb 36 00 	movl   $0x400036eb,0xc(%esp)
4000129e:	40 
4000129f:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
400012a6:	40 
400012a7:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
400012ae:	00 
400012af:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
400012b6:	e8 39 f0 ff ff       	call   400002f4 <debug_panic>
	assert(eltsize > 0);
400012bb:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
400012bf:	75 24                	jne    400012e5 <fileino_read+0xc9>
400012c1:	c7 44 24 0c f4 36 00 	movl   $0x400036f4,0xc(%esp)
400012c8:	40 
400012c9:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
400012d0:	40 
400012d1:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
400012d8:	00 
400012d9:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
400012e0:	e8 0f f0 ff ff       	call   400002f4 <debug_panic>

	ssize_t return_number = 0;
400012e5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	fileinode *fi = &files->fi[ino];
400012ec:	a1 34 36 00 40       	mov    0x40003634,%eax
400012f1:	8b 55 08             	mov    0x8(%ebp),%edx
400012f4:	6b d2 5c             	imul   $0x5c,%edx,%edx
400012f7:	81 c2 10 10 00 00    	add    $0x1010,%edx
400012fd:	01 d0                	add    %edx,%eax
400012ff:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint32_t tmp_ofs = ofs;
40001302:	8b 45 0c             	mov    0xc(%ebp),%eax
40001305:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint8_t* read_pointer = FILEDATA(ino) + ofs;
40001308:	8b 45 08             	mov    0x8(%ebp),%eax
4000130b:	c1 e0 16             	shl    $0x16,%eax
4000130e:	89 c2                	mov    %eax,%edx
40001310:	8b 45 0c             	mov    0xc(%ebp),%eax
40001313:	01 d0                	add    %edx,%eax
40001315:	05 00 00 00 80       	add    $0x80000000,%eax
4000131a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(fi->size <= FILE_MAXSIZE);
4000131d:	8b 45 e8             	mov    -0x18(%ebp),%eax
40001320:	8b 40 4c             	mov    0x4c(%eax),%eax
40001323:	3d 00 00 40 00       	cmp    $0x400000,%eax
40001328:	76 7a                	jbe    400013a4 <fileino_read+0x188>
4000132a:	c7 44 24 0c 00 37 00 	movl   $0x40003700,0xc(%esp)
40001331:	40 
40001332:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
40001339:	40 
4000133a:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
40001341:	00 
40001342:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001349:	e8 a6 ef ff ff       	call   400002f4 <debug_panic>
	// Lab 4: insert your file reading code here.
	//warn("fileino_read() not implemented");
	while(count > 0){
		if(tmp_ofs >= fi->size){
4000134e:	8b 45 e8             	mov    -0x18(%ebp),%eax
40001351:	8b 40 4c             	mov    0x4c(%eax),%eax
40001354:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40001357:	77 18                	ja     40001371 <fileino_read+0x155>
			if(fi->mode & S_IFPART)
40001359:	8b 45 e8             	mov    -0x18(%ebp),%eax
4000135c:	8b 40 48             	mov    0x48(%eax),%eax
4000135f:	25 00 80 00 00       	and    $0x8000,%eax
40001364:	85 c0                	test   %eax,%eax
40001366:	74 44                	je     400013ac <fileino_read+0x190>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001368:	b8 03 00 00 00       	mov    $0x3,%eax
4000136d:	cd 30                	int    $0x30
4000136f:	eb 33                	jmp    400013a4 <fileino_read+0x188>
				sys_ret();
			else
				break;
		}else{
			memcpy(buf, read_pointer, eltsize);
40001371:	8b 45 14             	mov    0x14(%ebp),%eax
40001374:	89 44 24 08          	mov    %eax,0x8(%esp)
40001378:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000137b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000137f:	8b 45 10             	mov    0x10(%ebp),%eax
40001382:	89 04 24             	mov    %eax,(%esp)
40001385:	e8 e3 fb ff ff       	call   40000f6d <memcpy>
			return_number++;
4000138a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
			buf += eltsize;
4000138e:	8b 45 14             	mov    0x14(%ebp),%eax
40001391:	01 45 10             	add    %eax,0x10(%ebp)
			read_pointer += eltsize;
40001394:	8b 45 14             	mov    0x14(%ebp),%eax
40001397:	01 45 ec             	add    %eax,-0x14(%ebp)
			tmp_ofs += eltsize;
4000139a:	8b 45 14             	mov    0x14(%ebp),%eax
4000139d:	01 45 f0             	add    %eax,-0x10(%ebp)
			count--;
400013a0:	83 6d 18 01          	subl   $0x1,0x18(%ebp)
	uint32_t tmp_ofs = ofs;
	uint8_t* read_pointer = FILEDATA(ino) + ofs;
	assert(fi->size <= FILE_MAXSIZE);
	// Lab 4: insert your file reading code here.
	//warn("fileino_read() not implemented");
	while(count > 0){
400013a4:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
400013a8:	75 a4                	jne    4000134e <fileino_read+0x132>
400013aa:	eb 01                	jmp    400013ad <fileino_read+0x191>
		if(tmp_ofs >= fi->size){
			if(fi->mode & S_IFPART)
				sys_ret();
			else
				break;
400013ac:	90                   	nop
			read_pointer += eltsize;
			tmp_ofs += eltsize;
			count--;
		}
	}
	return return_number;
400013ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
//	errno = EINVAL;
//	return -1;
}
400013b0:	c9                   	leave  
400013b1:	c3                   	ret    

400013b2 <fileino_write>:
// one particular reason an error might occur is if an application
// tries to grow a file beyond this maximum file size,
// in which case this function generates the EFBIG error.
ssize_t
fileino_write(int ino, off_t ofs, const void *buf, size_t eltsize, size_t count)
{
400013b2:	55                   	push   %ebp
400013b3:	89 e5                	mov    %esp,%ebp
400013b5:	57                   	push   %edi
400013b6:	56                   	push   %esi
400013b7:	53                   	push   %ebx
400013b8:	83 ec 6c             	sub    $0x6c,%esp
	assert(fileino_isreg(ino));
400013bb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400013bf:	7e 45                	jle    40001406 <fileino_write+0x54>
400013c1:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
400013c8:	7f 3c                	jg     40001406 <fileino_write+0x54>
400013ca:	8b 15 34 36 00 40    	mov    0x40003634,%edx
400013d0:	8b 45 08             	mov    0x8(%ebp),%eax
400013d3:	6b c0 5c             	imul   $0x5c,%eax,%eax
400013d6:	01 d0                	add    %edx,%eax
400013d8:	05 10 10 00 00       	add    $0x1010,%eax
400013dd:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400013e1:	84 c0                	test   %al,%al
400013e3:	74 21                	je     40001406 <fileino_write+0x54>
400013e5:	8b 15 34 36 00 40    	mov    0x40003634,%edx
400013eb:	8b 45 08             	mov    0x8(%ebp),%eax
400013ee:	6b c0 5c             	imul   $0x5c,%eax,%eax
400013f1:	01 d0                	add    %edx,%eax
400013f3:	05 58 10 00 00       	add    $0x1058,%eax
400013f8:	8b 00                	mov    (%eax),%eax
400013fa:	25 00 70 00 00       	and    $0x7000,%eax
400013ff:	3d 00 10 00 00       	cmp    $0x1000,%eax
40001404:	74 24                	je     4000142a <fileino_write+0x78>
40001406:	c7 44 24 0c d8 36 00 	movl   $0x400036d8,0xc(%esp)
4000140d:	40 
4000140e:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
40001415:	40 
40001416:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
4000141d:	00 
4000141e:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001425:	e8 ca ee ff ff       	call   400002f4 <debug_panic>
	assert(ofs >= 0);
4000142a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
4000142e:	79 24                	jns    40001454 <fileino_write+0xa2>
40001430:	c7 44 24 0c eb 36 00 	movl   $0x400036eb,0xc(%esp)
40001437:	40 
40001438:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
4000143f:	40 
40001440:	c7 44 24 04 84 00 00 	movl   $0x84,0x4(%esp)
40001447:	00 
40001448:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
4000144f:	e8 a0 ee ff ff       	call   400002f4 <debug_panic>
	assert(eltsize > 0);
40001454:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40001458:	75 24                	jne    4000147e <fileino_write+0xcc>
4000145a:	c7 44 24 0c f4 36 00 	movl   $0x400036f4,0xc(%esp)
40001461:	40 
40001462:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
40001469:	40 
4000146a:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
40001471:	00 
40001472:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001479:	e8 76 ee ff ff       	call   400002f4 <debug_panic>

	int i = 0;
4000147e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	ssize_t return_number = 0;
40001485:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	fileinode *fi = &files->fi[ino];
4000148c:	a1 34 36 00 40       	mov    0x40003634,%eax
40001491:	8b 55 08             	mov    0x8(%ebp),%edx
40001494:	6b d2 5c             	imul   $0x5c,%edx,%edx
40001497:	81 c2 10 10 00 00    	add    $0x1010,%edx
4000149d:	01 d0                	add    %edx,%eax
4000149f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	assert(fi->size <= FILE_MAXSIZE);
400014a2:	8b 45 d8             	mov    -0x28(%ebp),%eax
400014a5:	8b 40 4c             	mov    0x4c(%eax),%eax
400014a8:	3d 00 00 40 00       	cmp    $0x400000,%eax
400014ad:	76 24                	jbe    400014d3 <fileino_write+0x121>
400014af:	c7 44 24 0c 00 37 00 	movl   $0x40003700,0xc(%esp)
400014b6:	40 
400014b7:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
400014be:	40 
400014bf:	c7 44 24 04 8a 00 00 	movl   $0x8a,0x4(%esp)
400014c6:	00 
400014c7:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
400014ce:	e8 21 ee ff ff       	call   400002f4 <debug_panic>
	uint8_t* write_start = FILEDATA(ino) + ofs;
400014d3:	8b 45 08             	mov    0x8(%ebp),%eax
400014d6:	c1 e0 16             	shl    $0x16,%eax
400014d9:	89 c2                	mov    %eax,%edx
400014db:	8b 45 0c             	mov    0xc(%ebp),%eax
400014de:	01 d0                	add    %edx,%eax
400014e0:	05 00 00 00 80       	add    $0x80000000,%eax
400014e5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	uint8_t* write_pointer = write_start;
400014e8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
400014eb:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uint32_t after_write_size = ofs + eltsize * count;
400014ee:	8b 45 14             	mov    0x14(%ebp),%eax
400014f1:	89 c2                	mov    %eax,%edx
400014f3:	0f af 55 18          	imul   0x18(%ebp),%edx
400014f7:	8b 45 0c             	mov    0xc(%ebp),%eax
400014fa:	01 d0                	add    %edx,%eax
400014fc:	89 45 d0             	mov    %eax,-0x30(%ebp)

	if(after_write_size > FILE_MAXSIZE){
400014ff:	81 7d d0 00 00 40 00 	cmpl   $0x400000,-0x30(%ebp)
40001506:	76 15                	jbe    4000151d <fileino_write+0x16b>
		errno = EFBIG;
40001508:	a1 34 36 00 40       	mov    0x40003634,%eax
4000150d:	c7 00 03 00 00 00    	movl   $0x3,(%eax)
		return -1;
40001513:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40001518:	e9 28 01 00 00       	jmp    40001645 <fileino_write+0x293>
	}
	if(after_write_size > fi->size){
4000151d:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001520:	8b 40 4c             	mov    0x4c(%eax),%eax
40001523:	3b 45 d0             	cmp    -0x30(%ebp),%eax
40001526:	0f 83 0d 01 00 00    	jae    40001639 <fileino_write+0x287>
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
4000152c:	c7 45 cc 00 10 00 00 	movl   $0x1000,-0x34(%ebp)
40001533:	8b 45 cc             	mov    -0x34(%ebp),%eax
40001536:	8b 55 d0             	mov    -0x30(%ebp),%edx
40001539:	01 d0                	add    %edx,%eax
4000153b:	83 e8 01             	sub    $0x1,%eax
4000153e:	89 45 c8             	mov    %eax,-0x38(%ebp)
40001541:	8b 45 c8             	mov    -0x38(%ebp),%eax
40001544:	ba 00 00 00 00       	mov    $0x0,%edx
40001549:	f7 75 cc             	divl   -0x34(%ebp)
4000154c:	89 d0                	mov    %edx,%eax
4000154e:	8b 55 c8             	mov    -0x38(%ebp),%edx
40001551:	89 d1                	mov    %edx,%ecx
40001553:	29 c1                	sub    %eax,%ecx
40001555:	89 c8                	mov    %ecx,%eax
40001557:	89 c1                	mov    %eax,%ecx
40001559:	c7 45 c4 00 10 00 00 	movl   $0x1000,-0x3c(%ebp)
40001560:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001563:	8b 50 4c             	mov    0x4c(%eax),%edx
40001566:	8b 45 c4             	mov    -0x3c(%ebp),%eax
40001569:	01 d0                	add    %edx,%eax
4000156b:	83 e8 01             	sub    $0x1,%eax
4000156e:	89 45 c0             	mov    %eax,-0x40(%ebp)
40001571:	8b 45 c0             	mov    -0x40(%ebp),%eax
40001574:	ba 00 00 00 00       	mov    $0x0,%edx
40001579:	f7 75 c4             	divl   -0x3c(%ebp)
4000157c:	89 d0                	mov    %edx,%eax
4000157e:	8b 55 c0             	mov    -0x40(%ebp),%edx
40001581:	89 d3                	mov    %edx,%ebx
40001583:	29 c3                	sub    %eax,%ebx
40001585:	89 d8                	mov    %ebx,%eax
	if(after_write_size > FILE_MAXSIZE){
		errno = EFBIG;
		return -1;
	}
	if(after_write_size > fi->size){
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
40001587:	29 c1                	sub    %eax,%ecx
40001589:	8b 45 08             	mov    0x8(%ebp),%eax
4000158c:	c1 e0 16             	shl    $0x16,%eax
4000158f:	89 c3                	mov    %eax,%ebx
40001591:	c7 45 bc 00 10 00 00 	movl   $0x1000,-0x44(%ebp)
40001598:	8b 45 d8             	mov    -0x28(%ebp),%eax
4000159b:	8b 50 4c             	mov    0x4c(%eax),%edx
4000159e:	8b 45 bc             	mov    -0x44(%ebp),%eax
400015a1:	01 d0                	add    %edx,%eax
400015a3:	83 e8 01             	sub    $0x1,%eax
400015a6:	89 45 b8             	mov    %eax,-0x48(%ebp)
400015a9:	8b 45 b8             	mov    -0x48(%ebp),%eax
400015ac:	ba 00 00 00 00       	mov    $0x0,%edx
400015b1:	f7 75 bc             	divl   -0x44(%ebp)
400015b4:	89 d0                	mov    %edx,%eax
400015b6:	8b 55 b8             	mov    -0x48(%ebp),%edx
400015b9:	89 d6                	mov    %edx,%esi
400015bb:	29 c6                	sub    %eax,%esi
400015bd:	89 f0                	mov    %esi,%eax
400015bf:	01 d8                	add    %ebx,%eax
400015c1:	05 00 00 00 80       	add    $0x80000000,%eax
400015c6:	c7 45 b4 00 07 00 00 	movl   $0x700,-0x4c(%ebp)
400015cd:	66 c7 45 b2 00 00    	movw   $0x0,-0x4e(%ebp)
400015d3:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
400015da:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
400015e1:	89 45 a4             	mov    %eax,-0x5c(%ebp)
400015e4:	89 4d a0             	mov    %ecx,-0x60(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400015e7:	8b 45 b4             	mov    -0x4c(%ebp),%eax
400015ea:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400015ed:	8b 5d ac             	mov    -0x54(%ebp),%ebx
400015f0:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
400015f4:	8b 75 a8             	mov    -0x58(%ebp),%esi
400015f7:	8b 7d a4             	mov    -0x5c(%ebp),%edi
400015fa:	8b 4d a0             	mov    -0x60(%ebp),%ecx
400015fd:	cd 30                	int    $0x30
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
		fi->size = after_write_size;
400015ff:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001602:	8b 55 d0             	mov    -0x30(%ebp),%edx
40001605:	89 50 4c             	mov    %edx,0x4c(%eax)
	}
	for(i; i < count; i++){
40001608:	eb 2f                	jmp    40001639 <fileino_write+0x287>
		memcpy(write_pointer, buf, eltsize);
4000160a:	8b 45 14             	mov    0x14(%ebp),%eax
4000160d:	89 44 24 08          	mov    %eax,0x8(%esp)
40001611:	8b 45 10             	mov    0x10(%ebp),%eax
40001614:	89 44 24 04          	mov    %eax,0x4(%esp)
40001618:	8b 45 dc             	mov    -0x24(%ebp),%eax
4000161b:	89 04 24             	mov    %eax,(%esp)
4000161e:	e8 4a f9 ff ff       	call   40000f6d <memcpy>
		return_number++;
40001623:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
		buf += eltsize;
40001627:	8b 45 14             	mov    0x14(%ebp),%eax
4000162a:	01 45 10             	add    %eax,0x10(%ebp)
		write_pointer += eltsize;
4000162d:	8b 45 14             	mov    0x14(%ebp),%eax
40001630:	01 45 dc             	add    %eax,-0x24(%ebp)
	if(after_write_size > fi->size){
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
		fi->size = after_write_size;
	}
	for(i; i < count; i++){
40001633:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
40001637:	eb 01                	jmp    4000163a <fileino_write+0x288>
40001639:	90                   	nop
4000163a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000163d:	3b 45 18             	cmp    0x18(%ebp),%eax
40001640:	72 c8                	jb     4000160a <fileino_write+0x258>
		memcpy(write_pointer, buf, eltsize);
		return_number++;
		buf += eltsize;
		write_pointer += eltsize;
	}
	return return_number;
40001642:	8b 45 e0             	mov    -0x20(%ebp),%eax

	// Lab 4: insert your file writing code here.
	//warn("fileino_write() not implemented");
	//errno = EINVAL;
	//return -1;
}
40001645:	83 c4 6c             	add    $0x6c,%esp
40001648:	5b                   	pop    %ebx
40001649:	5e                   	pop    %esi
4000164a:	5f                   	pop    %edi
4000164b:	5d                   	pop    %ebp
4000164c:	c3                   	ret    

4000164d <fileino_stat>:
// Return file statistics about a particular inode.
// The specified inode must indicate a file that exists,
// but it can be any type of object: e.g., file, directory, special file, etc.
int
fileino_stat(int ino, struct stat *st)
{
4000164d:	55                   	push   %ebp
4000164e:	89 e5                	mov    %esp,%ebp
40001650:	83 ec 28             	sub    $0x28,%esp
	assert(fileino_exists(ino));
40001653:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001657:	7e 3d                	jle    40001696 <fileino_stat+0x49>
40001659:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40001660:	7f 34                	jg     40001696 <fileino_stat+0x49>
40001662:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40001668:	8b 45 08             	mov    0x8(%ebp),%eax
4000166b:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000166e:	01 d0                	add    %edx,%eax
40001670:	05 10 10 00 00       	add    $0x1010,%eax
40001675:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40001679:	84 c0                	test   %al,%al
4000167b:	74 19                	je     40001696 <fileino_stat+0x49>
4000167d:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40001683:	8b 45 08             	mov    0x8(%ebp),%eax
40001686:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001689:	01 d0                	add    %edx,%eax
4000168b:	05 58 10 00 00       	add    $0x1058,%eax
40001690:	8b 00                	mov    (%eax),%eax
40001692:	85 c0                	test   %eax,%eax
40001694:	75 24                	jne    400016ba <fileino_stat+0x6d>
40001696:	c7 44 24 0c 19 37 00 	movl   $0x40003719,0xc(%esp)
4000169d:	40 
4000169e:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
400016a5:	40 
400016a6:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
400016ad:	00 
400016ae:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
400016b5:	e8 3a ec ff ff       	call   400002f4 <debug_panic>

	fileinode *fi = &files->fi[ino];
400016ba:	a1 34 36 00 40       	mov    0x40003634,%eax
400016bf:	8b 55 08             	mov    0x8(%ebp),%edx
400016c2:	6b d2 5c             	imul   $0x5c,%edx,%edx
400016c5:	81 c2 10 10 00 00    	add    $0x1010,%edx
400016cb:	01 d0                	add    %edx,%eax
400016cd:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert(fileino_isdir(fi->dino));	// Should be in a directory!
400016d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
400016d3:	8b 00                	mov    (%eax),%eax
400016d5:	85 c0                	test   %eax,%eax
400016d7:	7e 4c                	jle    40001725 <fileino_stat+0xd8>
400016d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
400016dc:	8b 00                	mov    (%eax),%eax
400016de:	3d ff 00 00 00       	cmp    $0xff,%eax
400016e3:	7f 40                	jg     40001725 <fileino_stat+0xd8>
400016e5:	8b 15 34 36 00 40    	mov    0x40003634,%edx
400016eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
400016ee:	8b 00                	mov    (%eax),%eax
400016f0:	6b c0 5c             	imul   $0x5c,%eax,%eax
400016f3:	01 d0                	add    %edx,%eax
400016f5:	05 10 10 00 00       	add    $0x1010,%eax
400016fa:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400016fe:	84 c0                	test   %al,%al
40001700:	74 23                	je     40001725 <fileino_stat+0xd8>
40001702:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40001708:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000170b:	8b 00                	mov    (%eax),%eax
4000170d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001710:	01 d0                	add    %edx,%eax
40001712:	05 58 10 00 00       	add    $0x1058,%eax
40001717:	8b 00                	mov    (%eax),%eax
40001719:	25 00 70 00 00       	and    $0x7000,%eax
4000171e:	3d 00 20 00 00       	cmp    $0x2000,%eax
40001723:	74 24                	je     40001749 <fileino_stat+0xfc>
40001725:	c7 44 24 0c 2d 37 00 	movl   $0x4000372d,0xc(%esp)
4000172c:	40 
4000172d:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
40001734:	40 
40001735:	c7 44 24 04 af 00 00 	movl   $0xaf,0x4(%esp)
4000173c:	00 
4000173d:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001744:	e8 ab eb ff ff       	call   400002f4 <debug_panic>
	st->st_ino = ino;
40001749:	8b 45 0c             	mov    0xc(%ebp),%eax
4000174c:	8b 55 08             	mov    0x8(%ebp),%edx
4000174f:	89 10                	mov    %edx,(%eax)
	st->st_mode = fi->mode;
40001751:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001754:	8b 50 48             	mov    0x48(%eax),%edx
40001757:	8b 45 0c             	mov    0xc(%ebp),%eax
4000175a:	89 50 04             	mov    %edx,0x4(%eax)
	st->st_size = fi->size;
4000175d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001760:	8b 40 4c             	mov    0x4c(%eax),%eax
40001763:	89 c2                	mov    %eax,%edx
40001765:	8b 45 0c             	mov    0xc(%ebp),%eax
40001768:	89 50 08             	mov    %edx,0x8(%eax)

	return 0;
4000176b:	b8 00 00 00 00       	mov    $0x0,%eax
}
40001770:	c9                   	leave  
40001771:	c3                   	ret    

40001772 <fileino_truncate>:
// Grow or shrink a file to exactly a specified size.
// If growing a file, then fills the new space with zeros.
// Returns 0 if successful, or returns -1 and sets errno on error.
int
fileino_truncate(int ino, off_t newsize)
{
40001772:	55                   	push   %ebp
40001773:	89 e5                	mov    %esp,%ebp
40001775:	57                   	push   %edi
40001776:	56                   	push   %esi
40001777:	53                   	push   %ebx
40001778:	81 ec 8c 00 00 00    	sub    $0x8c,%esp
	assert(fileino_isvalid(ino));
4000177e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001782:	7e 09                	jle    4000178d <fileino_truncate+0x1b>
40001784:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
4000178b:	7e 24                	jle    400017b1 <fileino_truncate+0x3f>
4000178d:	c7 44 24 0c 45 37 00 	movl   $0x40003745,0xc(%esp)
40001794:	40 
40001795:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
4000179c:	40 
4000179d:	c7 44 24 04 bd 00 00 	movl   $0xbd,0x4(%esp)
400017a4:	00 
400017a5:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
400017ac:	e8 43 eb ff ff       	call   400002f4 <debug_panic>
	assert(newsize >= 0 && newsize <= FILE_MAXSIZE);
400017b1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400017b5:	78 09                	js     400017c0 <fileino_truncate+0x4e>
400017b7:	81 7d 0c 00 00 40 00 	cmpl   $0x400000,0xc(%ebp)
400017be:	7e 24                	jle    400017e4 <fileino_truncate+0x72>
400017c0:	c7 44 24 0c 5c 37 00 	movl   $0x4000375c,0xc(%esp)
400017c7:	40 
400017c8:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
400017cf:	40 
400017d0:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
400017d7:	00 
400017d8:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
400017df:	e8 10 eb ff ff       	call   400002f4 <debug_panic>

	size_t oldsize = files->fi[ino].size;
400017e4:	8b 15 34 36 00 40    	mov    0x40003634,%edx
400017ea:	8b 45 08             	mov    0x8(%ebp),%eax
400017ed:	6b c0 5c             	imul   $0x5c,%eax,%eax
400017f0:	01 d0                	add    %edx,%eax
400017f2:	05 5c 10 00 00       	add    $0x105c,%eax
400017f7:	8b 00                	mov    (%eax),%eax
400017f9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	size_t oldpagelim = ROUNDUP(files->fi[ino].size, PAGESIZE);
400017fc:	c7 45 e0 00 10 00 00 	movl   $0x1000,-0x20(%ebp)
40001803:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40001809:	8b 45 08             	mov    0x8(%ebp),%eax
4000180c:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000180f:	01 d0                	add    %edx,%eax
40001811:	05 5c 10 00 00       	add    $0x105c,%eax
40001816:	8b 10                	mov    (%eax),%edx
40001818:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000181b:	01 d0                	add    %edx,%eax
4000181d:	83 e8 01             	sub    $0x1,%eax
40001820:	89 45 dc             	mov    %eax,-0x24(%ebp)
40001823:	8b 45 dc             	mov    -0x24(%ebp),%eax
40001826:	ba 00 00 00 00       	mov    $0x0,%edx
4000182b:	f7 75 e0             	divl   -0x20(%ebp)
4000182e:	89 d0                	mov    %edx,%eax
40001830:	8b 55 dc             	mov    -0x24(%ebp),%edx
40001833:	89 d1                	mov    %edx,%ecx
40001835:	29 c1                	sub    %eax,%ecx
40001837:	89 c8                	mov    %ecx,%eax
40001839:	89 45 d8             	mov    %eax,-0x28(%ebp)
	size_t newpagelim = ROUNDUP(newsize, PAGESIZE);
4000183c:	c7 45 d4 00 10 00 00 	movl   $0x1000,-0x2c(%ebp)
40001843:	8b 55 0c             	mov    0xc(%ebp),%edx
40001846:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40001849:	01 d0                	add    %edx,%eax
4000184b:	83 e8 01             	sub    $0x1,%eax
4000184e:	89 45 d0             	mov    %eax,-0x30(%ebp)
40001851:	8b 45 d0             	mov    -0x30(%ebp),%eax
40001854:	ba 00 00 00 00       	mov    $0x0,%edx
40001859:	f7 75 d4             	divl   -0x2c(%ebp)
4000185c:	89 d0                	mov    %edx,%eax
4000185e:	8b 55 d0             	mov    -0x30(%ebp),%edx
40001861:	89 d1                	mov    %edx,%ecx
40001863:	29 c1                	sub    %eax,%ecx
40001865:	89 c8                	mov    %ecx,%eax
40001867:	89 45 cc             	mov    %eax,-0x34(%ebp)
	if (newsize > oldsize) {
4000186a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000186d:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
40001870:	0f 86 8a 00 00 00    	jbe    40001900 <fileino_truncate+0x18e>
		// Grow the file and fill the new space with zeros.
		sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
40001876:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001879:	8b 55 cc             	mov    -0x34(%ebp),%edx
4000187c:	89 d1                	mov    %edx,%ecx
4000187e:	29 c1                	sub    %eax,%ecx
40001880:	89 c8                	mov    %ecx,%eax
			FILEDATA(ino) + oldpagelim,
40001882:	8b 55 08             	mov    0x8(%ebp),%edx
40001885:	c1 e2 16             	shl    $0x16,%edx
40001888:	89 d1                	mov    %edx,%ecx
4000188a:	8b 55 d8             	mov    -0x28(%ebp),%edx
4000188d:	01 ca                	add    %ecx,%edx
	size_t oldsize = files->fi[ino].size;
	size_t oldpagelim = ROUNDUP(files->fi[ino].size, PAGESIZE);
	size_t newpagelim = ROUNDUP(newsize, PAGESIZE);
	if (newsize > oldsize) {
		// Grow the file and fill the new space with zeros.
		sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
4000188f:	81 c2 00 00 00 80    	add    $0x80000000,%edx
40001895:	c7 45 c8 00 07 00 00 	movl   $0x700,-0x38(%ebp)
4000189c:	66 c7 45 c6 00 00    	movw   $0x0,-0x3a(%ebp)
400018a2:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
400018a9:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
400018b0:	89 55 b8             	mov    %edx,-0x48(%ebp)
400018b3:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400018b6:	8b 45 c8             	mov    -0x38(%ebp),%eax
400018b9:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400018bc:	8b 5d c0             	mov    -0x40(%ebp),%ebx
400018bf:	0f b7 55 c6          	movzwl -0x3a(%ebp),%edx
400018c3:	8b 75 bc             	mov    -0x44(%ebp),%esi
400018c6:	8b 7d b8             	mov    -0x48(%ebp),%edi
400018c9:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
400018cc:	cd 30                	int    $0x30
			FILEDATA(ino) + oldpagelim,
			newpagelim - oldpagelim);
		memset(FILEDATA(ino) + oldsize, 0, newsize - oldsize);
400018ce:	8b 45 0c             	mov    0xc(%ebp),%eax
400018d1:	2b 45 e4             	sub    -0x1c(%ebp),%eax
400018d4:	8b 55 08             	mov    0x8(%ebp),%edx
400018d7:	c1 e2 16             	shl    $0x16,%edx
400018da:	89 d1                	mov    %edx,%ecx
400018dc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
400018df:	01 ca                	add    %ecx,%edx
400018e1:	81 c2 00 00 00 80    	add    $0x80000000,%edx
400018e7:	89 44 24 08          	mov    %eax,0x8(%esp)
400018eb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400018f2:	00 
400018f3:	89 14 24             	mov    %edx,(%esp)
400018f6:	e8 2a f5 ff ff       	call   40000e25 <memset>
400018fb:	e9 a4 00 00 00       	jmp    400019a4 <fileino_truncate+0x232>
	} else if (newsize > 0) {
40001900:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40001904:	7e 56                	jle    4000195c <fileino_truncate+0x1ea>
		// Shrink the file, but not all the way to empty.
		// Would prefer to use SYS_ZERO to free the file content,
		// but SYS_ZERO isn't guaranteed to work at page granularity.
		sys_get(SYS_PERM, 0, NULL, NULL,
40001906:	b8 00 00 40 00       	mov    $0x400000,%eax
4000190b:	2b 45 cc             	sub    -0x34(%ebp),%eax
			FILEDATA(ino) + newpagelim, FILE_MAXSIZE - newpagelim);
4000190e:	8b 55 08             	mov    0x8(%ebp),%edx
40001911:	c1 e2 16             	shl    $0x16,%edx
40001914:	89 d1                	mov    %edx,%ecx
40001916:	8b 55 cc             	mov    -0x34(%ebp),%edx
40001919:	01 ca                	add    %ecx,%edx
		memset(FILEDATA(ino) + oldsize, 0, newsize - oldsize);
	} else if (newsize > 0) {
		// Shrink the file, but not all the way to empty.
		// Would prefer to use SYS_ZERO to free the file content,
		// but SYS_ZERO isn't guaranteed to work at page granularity.
		sys_get(SYS_PERM, 0, NULL, NULL,
4000191b:	81 c2 00 00 00 80    	add    $0x80000000,%edx
40001921:	c7 45 b0 00 01 00 00 	movl   $0x100,-0x50(%ebp)
40001928:	66 c7 45 ae 00 00    	movw   $0x0,-0x52(%ebp)
4000192e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
40001935:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
4000193c:	89 55 a0             	mov    %edx,-0x60(%ebp)
4000193f:	89 45 9c             	mov    %eax,-0x64(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001942:	8b 45 b0             	mov    -0x50(%ebp),%eax
40001945:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001948:	8b 5d a8             	mov    -0x58(%ebp),%ebx
4000194b:	0f b7 55 ae          	movzwl -0x52(%ebp),%edx
4000194f:	8b 75 a4             	mov    -0x5c(%ebp),%esi
40001952:	8b 7d a0             	mov    -0x60(%ebp),%edi
40001955:	8b 4d 9c             	mov    -0x64(%ebp),%ecx
40001958:	cd 30                	int    $0x30
4000195a:	eb 48                	jmp    400019a4 <fileino_truncate+0x232>
			FILEDATA(ino) + newpagelim, FILE_MAXSIZE - newpagelim);
	} else {
		// Shrink the file to empty.  Use SYS_ZERO to free completely.
		sys_get(SYS_ZERO, 0, NULL, NULL, FILEDATA(ino), FILE_MAXSIZE);
4000195c:	8b 45 08             	mov    0x8(%ebp),%eax
4000195f:	c1 e0 16             	shl    $0x16,%eax
40001962:	05 00 00 00 80       	add    $0x80000000,%eax
40001967:	c7 45 98 00 00 01 00 	movl   $0x10000,-0x68(%ebp)
4000196e:	66 c7 45 96 00 00    	movw   $0x0,-0x6a(%ebp)
40001974:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
4000197b:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
40001982:	89 45 88             	mov    %eax,-0x78(%ebp)
40001985:	c7 45 84 00 00 40 00 	movl   $0x400000,-0x7c(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
4000198c:	8b 45 98             	mov    -0x68(%ebp),%eax
4000198f:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001992:	8b 5d 90             	mov    -0x70(%ebp),%ebx
40001995:	0f b7 55 96          	movzwl -0x6a(%ebp),%edx
40001999:	8b 75 8c             	mov    -0x74(%ebp),%esi
4000199c:	8b 7d 88             	mov    -0x78(%ebp),%edi
4000199f:	8b 4d 84             	mov    -0x7c(%ebp),%ecx
400019a2:	cd 30                	int    $0x30
	}
	files->fi[ino].size = newsize;
400019a4:	8b 0d 34 36 00 40    	mov    0x40003634,%ecx
400019aa:	8b 45 0c             	mov    0xc(%ebp),%eax
400019ad:	8b 55 08             	mov    0x8(%ebp),%edx
400019b0:	6b d2 5c             	imul   $0x5c,%edx,%edx
400019b3:	01 ca                	add    %ecx,%edx
400019b5:	81 c2 5c 10 00 00    	add    $0x105c,%edx
400019bb:	89 02                	mov    %eax,(%edx)
	files->fi[ino].ver++;	// truncation is always an exclusive change
400019bd:	a1 34 36 00 40       	mov    0x40003634,%eax
400019c2:	8b 55 08             	mov    0x8(%ebp),%edx
400019c5:	6b d2 5c             	imul   $0x5c,%edx,%edx
400019c8:	01 c2                	add    %eax,%edx
400019ca:	81 c2 54 10 00 00    	add    $0x1054,%edx
400019d0:	8b 12                	mov    (%edx),%edx
400019d2:	83 c2 01             	add    $0x1,%edx
400019d5:	8b 4d 08             	mov    0x8(%ebp),%ecx
400019d8:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
400019db:	01 c8                	add    %ecx,%eax
400019dd:	05 54 10 00 00       	add    $0x1054,%eax
400019e2:	89 10                	mov    %edx,(%eax)
	return 0;
400019e4:	b8 00 00 00 00       	mov    $0x0,%eax
}
400019e9:	81 c4 8c 00 00 00    	add    $0x8c,%esp
400019ef:	5b                   	pop    %ebx
400019f0:	5e                   	pop    %esi
400019f1:	5f                   	pop    %edi
400019f2:	5d                   	pop    %ebp
400019f3:	c3                   	ret    

400019f4 <fileino_flush>:

// Flush any outstanding writes on this file to our parent process.
// (XXX should flushes propagate across multiple levels?)
int
fileino_flush(int ino)
{
400019f4:	55                   	push   %ebp
400019f5:	89 e5                	mov    %esp,%ebp
400019f7:	83 ec 18             	sub    $0x18,%esp
	assert(fileino_isvalid(ino));
400019fa:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400019fe:	7e 09                	jle    40001a09 <fileino_flush+0x15>
40001a00:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40001a07:	7e 24                	jle    40001a2d <fileino_flush+0x39>
40001a09:	c7 44 24 0c 45 37 00 	movl   $0x40003745,0xc(%esp)
40001a10:	40 
40001a11:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
40001a18:	40 
40001a19:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
40001a20:	00 
40001a21:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001a28:	e8 c7 e8 ff ff       	call   400002f4 <debug_panic>

	if (files->fi[ino].size > files->fi[ino].rlen)
40001a2d:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40001a33:	8b 45 08             	mov    0x8(%ebp),%eax
40001a36:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001a39:	01 d0                	add    %edx,%eax
40001a3b:	05 5c 10 00 00       	add    $0x105c,%eax
40001a40:	8b 10                	mov    (%eax),%edx
40001a42:	8b 0d 34 36 00 40    	mov    0x40003634,%ecx
40001a48:	8b 45 08             	mov    0x8(%ebp),%eax
40001a4b:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001a4e:	01 c8                	add    %ecx,%eax
40001a50:	05 68 10 00 00       	add    $0x1068,%eax
40001a55:	8b 00                	mov    (%eax),%eax
40001a57:	39 c2                	cmp    %eax,%edx
40001a59:	76 07                	jbe    40001a62 <fileino_flush+0x6e>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001a5b:	b8 03 00 00 00       	mov    $0x3,%eax
40001a60:	cd 30                	int    $0x30
		sys_ret();	// synchronize and reconcile with parent
	return 0;
40001a62:	b8 00 00 00 00       	mov    $0x0,%eax
}
40001a67:	c9                   	leave  
40001a68:	c3                   	ret    

40001a69 <filedesc_alloc>:
// Search the file descriptor table for the first free file descriptor,
// and return a pointer to that file descriptor.
// If no file descriptors are available,
// returns NULL and set errno appropriately.
filedesc *filedesc_alloc(void)
{
40001a69:	55                   	push   %ebp
40001a6a:	89 e5                	mov    %esp,%ebp
40001a6c:	83 ec 10             	sub    $0x10,%esp
	int i;
	for (i = 0; i < OPEN_MAX; i++)
40001a6f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
40001a76:	eb 2c                	jmp    40001aa4 <filedesc_alloc+0x3b>
		if (files->fd[i].ino == FILEINO_NULL)
40001a78:	a1 34 36 00 40       	mov    0x40003634,%eax
40001a7d:	8b 55 fc             	mov    -0x4(%ebp),%edx
40001a80:	83 c2 01             	add    $0x1,%edx
40001a83:	c1 e2 04             	shl    $0x4,%edx
40001a86:	01 d0                	add    %edx,%eax
40001a88:	8b 00                	mov    (%eax),%eax
40001a8a:	85 c0                	test   %eax,%eax
40001a8c:	75 12                	jne    40001aa0 <filedesc_alloc+0x37>
			return &files->fd[i];
40001a8e:	a1 34 36 00 40       	mov    0x40003634,%eax
40001a93:	8b 55 fc             	mov    -0x4(%ebp),%edx
40001a96:	83 c2 01             	add    $0x1,%edx
40001a99:	c1 e2 04             	shl    $0x4,%edx
40001a9c:	01 d0                	add    %edx,%eax
40001a9e:	eb 1d                	jmp    40001abd <filedesc_alloc+0x54>
// If no file descriptors are available,
// returns NULL and set errno appropriately.
filedesc *filedesc_alloc(void)
{
	int i;
	for (i = 0; i < OPEN_MAX; i++)
40001aa0:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40001aa4:	81 7d fc ff 00 00 00 	cmpl   $0xff,-0x4(%ebp)
40001aab:	7e cb                	jle    40001a78 <filedesc_alloc+0xf>
		if (files->fd[i].ino == FILEINO_NULL)
			return &files->fd[i];
	errno = EMFILE;
40001aad:	a1 34 36 00 40       	mov    0x40003634,%eax
40001ab2:	c7 00 04 00 00 00    	movl   $0x4,(%eax)
	return NULL;
40001ab8:	b8 00 00 00 00       	mov    $0x0,%eax
}
40001abd:	c9                   	leave  
40001abe:	c3                   	ret    

40001abf <filedesc_open>:
// The 'openflags' determines whether the file is created, truncated, etc.
// Returns the opened file descriptor on success,
// or returns NULL and sets errno on failure.
filedesc *
filedesc_open(filedesc *fd, const char *path, int openflags, mode_t mode)
{
40001abf:	55                   	push   %ebp
40001ac0:	89 e5                	mov    %esp,%ebp
40001ac2:	83 ec 28             	sub    $0x28,%esp
	if (!fd && !(fd = filedesc_alloc()))
40001ac5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001ac9:	75 18                	jne    40001ae3 <filedesc_open+0x24>
40001acb:	e8 99 ff ff ff       	call   40001a69 <filedesc_alloc>
40001ad0:	89 45 08             	mov    %eax,0x8(%ebp)
40001ad3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001ad7:	75 0a                	jne    40001ae3 <filedesc_open+0x24>
		return NULL;
40001ad9:	b8 00 00 00 00       	mov    $0x0,%eax
40001ade:	e9 04 02 00 00       	jmp    40001ce7 <filedesc_open+0x228>
	assert(fd->ino == FILEINO_NULL);
40001ae3:	8b 45 08             	mov    0x8(%ebp),%eax
40001ae6:	8b 00                	mov    (%eax),%eax
40001ae8:	85 c0                	test   %eax,%eax
40001aea:	74 24                	je     40001b10 <filedesc_open+0x51>
40001aec:	c7 44 24 0c 84 37 00 	movl   $0x40003784,0xc(%esp)
40001af3:	40 
40001af4:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
40001afb:	40 
40001afc:	c7 44 24 04 00 01 00 	movl   $0x100,0x4(%esp)
40001b03:	00 
40001b04:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001b0b:	e8 e4 e7 ff ff       	call   400002f4 <debug_panic>

	// Determine the complete file mode if it is to be created.
	mode_t createmode = (openflags & O_CREAT) ? S_IFREG | (mode & 0777) : 0;
40001b10:	8b 45 10             	mov    0x10(%ebp),%eax
40001b13:	83 e0 20             	and    $0x20,%eax
40001b16:	85 c0                	test   %eax,%eax
40001b18:	74 0d                	je     40001b27 <filedesc_open+0x68>
40001b1a:	8b 45 14             	mov    0x14(%ebp),%eax
40001b1d:	25 ff 01 00 00       	and    $0x1ff,%eax
40001b22:	80 cc 10             	or     $0x10,%ah
40001b25:	eb 05                	jmp    40001b2c <filedesc_open+0x6d>
40001b27:	b8 00 00 00 00       	mov    $0x0,%eax
40001b2c:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Walk the directory tree to find the desired directory entry,
	// creating an entry if it doesn't exist and O_CREAT is set.
	int ino = dir_walk(path, createmode);
40001b2f:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001b32:	89 44 24 04          	mov    %eax,0x4(%esp)
40001b36:	8b 45 0c             	mov    0xc(%ebp),%eax
40001b39:	89 04 24             	mov    %eax,(%esp)
40001b3c:	e8 d7 05 00 00       	call   40002118 <dir_walk>
40001b41:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (ino < 0)
40001b44:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40001b48:	79 0a                	jns    40001b54 <filedesc_open+0x95>
		return NULL;
40001b4a:	b8 00 00 00 00       	mov    $0x0,%eax
40001b4f:	e9 93 01 00 00       	jmp    40001ce7 <filedesc_open+0x228>
	assert(fileino_exists(ino));
40001b54:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40001b58:	7e 3d                	jle    40001b97 <filedesc_open+0xd8>
40001b5a:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40001b61:	7f 34                	jg     40001b97 <filedesc_open+0xd8>
40001b63:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40001b69:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001b6c:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001b6f:	01 d0                	add    %edx,%eax
40001b71:	05 10 10 00 00       	add    $0x1010,%eax
40001b76:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40001b7a:	84 c0                	test   %al,%al
40001b7c:	74 19                	je     40001b97 <filedesc_open+0xd8>
40001b7e:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40001b84:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001b87:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001b8a:	01 d0                	add    %edx,%eax
40001b8c:	05 58 10 00 00       	add    $0x1058,%eax
40001b91:	8b 00                	mov    (%eax),%eax
40001b93:	85 c0                	test   %eax,%eax
40001b95:	75 24                	jne    40001bbb <filedesc_open+0xfc>
40001b97:	c7 44 24 0c 19 37 00 	movl   $0x40003719,0xc(%esp)
40001b9e:	40 
40001b9f:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
40001ba6:	40 
40001ba7:	c7 44 24 04 0a 01 00 	movl   $0x10a,0x4(%esp)
40001bae:	00 
40001baf:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001bb6:	e8 39 e7 ff ff       	call   400002f4 <debug_panic>

	// Refuse to open conflict-marked files;
	// the user needs to resolve the conflict and clear the conflict flag,
	// or just delete the conflicted file.
	if (files->fi[ino].mode & S_IFCONF) {
40001bbb:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40001bc1:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001bc4:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001bc7:	01 d0                	add    %edx,%eax
40001bc9:	05 58 10 00 00       	add    $0x1058,%eax
40001bce:	8b 00                	mov    (%eax),%eax
40001bd0:	25 00 00 01 00       	and    $0x10000,%eax
40001bd5:	85 c0                	test   %eax,%eax
40001bd7:	74 15                	je     40001bee <filedesc_open+0x12f>
		errno = ECONFLICT;
40001bd9:	a1 34 36 00 40       	mov    0x40003634,%eax
40001bde:	c7 00 0a 00 00 00    	movl   $0xa,(%eax)
		return NULL;
40001be4:	b8 00 00 00 00       	mov    $0x0,%eax
40001be9:	e9 f9 00 00 00       	jmp    40001ce7 <filedesc_open+0x228>
	}

	// Truncate the file if we were asked to
	if (openflags & O_TRUNC) {
40001bee:	8b 45 10             	mov    0x10(%ebp),%eax
40001bf1:	83 e0 40             	and    $0x40,%eax
40001bf4:	85 c0                	test   %eax,%eax
40001bf6:	74 5c                	je     40001c54 <filedesc_open+0x195>
		if (!(openflags & O_WRONLY)) {
40001bf8:	8b 45 10             	mov    0x10(%ebp),%eax
40001bfb:	83 e0 02             	and    $0x2,%eax
40001bfe:	85 c0                	test   %eax,%eax
40001c00:	75 31                	jne    40001c33 <filedesc_open+0x174>
			warn("filedesc_open: can't truncate non-writable file");
40001c02:	c7 44 24 08 9c 37 00 	movl   $0x4000379c,0x8(%esp)
40001c09:	40 
40001c0a:	c7 44 24 04 17 01 00 	movl   $0x117,0x4(%esp)
40001c11:	00 
40001c12:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001c19:	e8 40 e7 ff ff       	call   4000035e <debug_warn>
			errno = EINVAL;
40001c1e:	a1 34 36 00 40       	mov    0x40003634,%eax
40001c23:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
			return NULL;
40001c29:	b8 00 00 00 00       	mov    $0x0,%eax
40001c2e:	e9 b4 00 00 00       	jmp    40001ce7 <filedesc_open+0x228>
		}
		if (fileino_truncate(ino, 0) < 0)
40001c33:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001c3a:	00 
40001c3b:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001c3e:	89 04 24             	mov    %eax,(%esp)
40001c41:	e8 2c fb ff ff       	call   40001772 <fileino_truncate>
40001c46:	85 c0                	test   %eax,%eax
40001c48:	79 0a                	jns    40001c54 <filedesc_open+0x195>
			return NULL;
40001c4a:	b8 00 00 00 00       	mov    $0x0,%eax
40001c4f:	e9 93 00 00 00       	jmp    40001ce7 <filedesc_open+0x228>
	}

	// Initialize the file descriptor
	fd->ino = ino;
40001c54:	8b 45 08             	mov    0x8(%ebp),%eax
40001c57:	8b 55 f0             	mov    -0x10(%ebp),%edx
40001c5a:	89 10                	mov    %edx,(%eax)
	fd->flags = openflags;
40001c5c:	8b 45 08             	mov    0x8(%ebp),%eax
40001c5f:	8b 55 10             	mov    0x10(%ebp),%edx
40001c62:	89 50 04             	mov    %edx,0x4(%eax)
	fd->ofs = (openflags & O_APPEND) ? files->fi[ino].size : 0;
40001c65:	8b 45 10             	mov    0x10(%ebp),%eax
40001c68:	83 e0 10             	and    $0x10,%eax
40001c6b:	85 c0                	test   %eax,%eax
40001c6d:	74 17                	je     40001c86 <filedesc_open+0x1c7>
40001c6f:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40001c75:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001c78:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001c7b:	01 d0                	add    %edx,%eax
40001c7d:	05 5c 10 00 00       	add    $0x105c,%eax
40001c82:	8b 00                	mov    (%eax),%eax
40001c84:	eb 05                	jmp    40001c8b <filedesc_open+0x1cc>
40001c86:	b8 00 00 00 00       	mov    $0x0,%eax
40001c8b:	8b 55 08             	mov    0x8(%ebp),%edx
40001c8e:	89 42 08             	mov    %eax,0x8(%edx)
	fd->err = 0;
40001c91:	8b 45 08             	mov    0x8(%ebp),%eax
40001c94:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)

	assert(filedesc_isopen(fd));
40001c9b:	a1 34 36 00 40       	mov    0x40003634,%eax
40001ca0:	83 c0 10             	add    $0x10,%eax
40001ca3:	3b 45 08             	cmp    0x8(%ebp),%eax
40001ca6:	77 18                	ja     40001cc0 <filedesc_open+0x201>
40001ca8:	a1 34 36 00 40       	mov    0x40003634,%eax
40001cad:	05 10 10 00 00       	add    $0x1010,%eax
40001cb2:	3b 45 08             	cmp    0x8(%ebp),%eax
40001cb5:	76 09                	jbe    40001cc0 <filedesc_open+0x201>
40001cb7:	8b 45 08             	mov    0x8(%ebp),%eax
40001cba:	8b 00                	mov    (%eax),%eax
40001cbc:	85 c0                	test   %eax,%eax
40001cbe:	75 24                	jne    40001ce4 <filedesc_open+0x225>
40001cc0:	c7 44 24 0c cc 37 00 	movl   $0x400037cc,0xc(%esp)
40001cc7:	40 
40001cc8:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
40001ccf:	40 
40001cd0:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
40001cd7:	00 
40001cd8:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001cdf:	e8 10 e6 ff ff       	call   400002f4 <debug_panic>
	return fd;
40001ce4:	8b 45 08             	mov    0x8(%ebp),%eax
}
40001ce7:	c9                   	leave  
40001ce8:	c3                   	ret    

40001ce9 <filedesc_read>:
// If the file is a special device input file such as the console,
// this function pretends the file has no end and instead
// uses sys_ret() to wait for the file to extend the special file.
ssize_t
filedesc_read(filedesc *fd, void *buf, size_t eltsize, size_t count)
{
40001ce9:	55                   	push   %ebp
40001cea:	89 e5                	mov    %esp,%ebp
40001cec:	83 ec 38             	sub    $0x38,%esp
	assert(filedesc_isreadable(fd));
40001cef:	a1 34 36 00 40       	mov    0x40003634,%eax
40001cf4:	83 c0 10             	add    $0x10,%eax
40001cf7:	3b 45 08             	cmp    0x8(%ebp),%eax
40001cfa:	77 25                	ja     40001d21 <filedesc_read+0x38>
40001cfc:	a1 34 36 00 40       	mov    0x40003634,%eax
40001d01:	05 10 10 00 00       	add    $0x1010,%eax
40001d06:	3b 45 08             	cmp    0x8(%ebp),%eax
40001d09:	76 16                	jbe    40001d21 <filedesc_read+0x38>
40001d0b:	8b 45 08             	mov    0x8(%ebp),%eax
40001d0e:	8b 00                	mov    (%eax),%eax
40001d10:	85 c0                	test   %eax,%eax
40001d12:	74 0d                	je     40001d21 <filedesc_read+0x38>
40001d14:	8b 45 08             	mov    0x8(%ebp),%eax
40001d17:	8b 40 04             	mov    0x4(%eax),%eax
40001d1a:	83 e0 01             	and    $0x1,%eax
40001d1d:	85 c0                	test   %eax,%eax
40001d1f:	75 24                	jne    40001d45 <filedesc_read+0x5c>
40001d21:	c7 44 24 0c e0 37 00 	movl   $0x400037e0,0xc(%esp)
40001d28:	40 
40001d29:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
40001d30:	40 
40001d31:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
40001d38:	00 
40001d39:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001d40:	e8 af e5 ff ff       	call   400002f4 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40001d45:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40001d4b:	8b 45 08             	mov    0x8(%ebp),%eax
40001d4e:	8b 00                	mov    (%eax),%eax
40001d50:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001d53:	05 10 10 00 00       	add    $0x1010,%eax
40001d58:	01 d0                	add    %edx,%eax
40001d5a:	89 45 f4             	mov    %eax,-0xc(%ebp)

	ssize_t actual = fileino_read(fd->ino, fd->ofs, buf, eltsize, count);
40001d5d:	8b 45 08             	mov    0x8(%ebp),%eax
40001d60:	8b 50 08             	mov    0x8(%eax),%edx
40001d63:	8b 45 08             	mov    0x8(%ebp),%eax
40001d66:	8b 00                	mov    (%eax),%eax
40001d68:	8b 4d 14             	mov    0x14(%ebp),%ecx
40001d6b:	89 4c 24 10          	mov    %ecx,0x10(%esp)
40001d6f:	8b 4d 10             	mov    0x10(%ebp),%ecx
40001d72:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
40001d76:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40001d79:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40001d7d:	89 54 24 04          	mov    %edx,0x4(%esp)
40001d81:	89 04 24             	mov    %eax,(%esp)
40001d84:	e8 93 f4 ff ff       	call   4000121c <fileino_read>
40001d89:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (actual < 0) {
40001d8c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40001d90:	79 14                	jns    40001da6 <filedesc_read+0xbd>
		fd->err = errno;	// save error indication for ferror()
40001d92:	a1 34 36 00 40       	mov    0x40003634,%eax
40001d97:	8b 10                	mov    (%eax),%edx
40001d99:	8b 45 08             	mov    0x8(%ebp),%eax
40001d9c:	89 50 0c             	mov    %edx,0xc(%eax)
		return -1;
40001d9f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40001da4:	eb 56                	jmp    40001dfc <filedesc_read+0x113>
	}

	// Advance the file position
	fd->ofs += eltsize * actual;
40001da6:	8b 45 08             	mov    0x8(%ebp),%eax
40001da9:	8b 40 08             	mov    0x8(%eax),%eax
40001dac:	89 c2                	mov    %eax,%edx
40001dae:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001db1:	0f af 45 10          	imul   0x10(%ebp),%eax
40001db5:	01 d0                	add    %edx,%eax
40001db7:	89 c2                	mov    %eax,%edx
40001db9:	8b 45 08             	mov    0x8(%ebp),%eax
40001dbc:	89 50 08             	mov    %edx,0x8(%eax)
	assert(actual == 0 || fi->size >= fd->ofs);
40001dbf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40001dc3:	74 34                	je     40001df9 <filedesc_read+0x110>
40001dc5:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001dc8:	8b 50 4c             	mov    0x4c(%eax),%edx
40001dcb:	8b 45 08             	mov    0x8(%ebp),%eax
40001dce:	8b 40 08             	mov    0x8(%eax),%eax
40001dd1:	39 c2                	cmp    %eax,%edx
40001dd3:	73 24                	jae    40001df9 <filedesc_read+0x110>
40001dd5:	c7 44 24 0c f8 37 00 	movl   $0x400037f8,0xc(%esp)
40001ddc:	40 
40001ddd:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
40001de4:	40 
40001de5:	c7 44 24 04 42 01 00 	movl   $0x142,0x4(%esp)
40001dec:	00 
40001ded:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001df4:	e8 fb e4 ff ff       	call   400002f4 <debug_panic>

	return actual;
40001df9:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40001dfc:	c9                   	leave  
40001dfd:	c3                   	ret    

40001dfe <filedesc_write>:
// The size of 'buf' must be at least 'count * eltsize' bytes.
// On success, returns the number of objects written (NOT the number of bytes).
// If an error occurs, returns -1 and sets errno appropriately.
ssize_t
filedesc_write(filedesc *fd, const void *buf, size_t eltsize, size_t count)
{
40001dfe:	55                   	push   %ebp
40001dff:	89 e5                	mov    %esp,%ebp
40001e01:	83 ec 38             	sub    $0x38,%esp
	assert(filedesc_iswritable(fd));
40001e04:	a1 34 36 00 40       	mov    0x40003634,%eax
40001e09:	83 c0 10             	add    $0x10,%eax
40001e0c:	3b 45 08             	cmp    0x8(%ebp),%eax
40001e0f:	77 25                	ja     40001e36 <filedesc_write+0x38>
40001e11:	a1 34 36 00 40       	mov    0x40003634,%eax
40001e16:	05 10 10 00 00       	add    $0x1010,%eax
40001e1b:	3b 45 08             	cmp    0x8(%ebp),%eax
40001e1e:	76 16                	jbe    40001e36 <filedesc_write+0x38>
40001e20:	8b 45 08             	mov    0x8(%ebp),%eax
40001e23:	8b 00                	mov    (%eax),%eax
40001e25:	85 c0                	test   %eax,%eax
40001e27:	74 0d                	je     40001e36 <filedesc_write+0x38>
40001e29:	8b 45 08             	mov    0x8(%ebp),%eax
40001e2c:	8b 40 04             	mov    0x4(%eax),%eax
40001e2f:	83 e0 02             	and    $0x2,%eax
40001e32:	85 c0                	test   %eax,%eax
40001e34:	75 24                	jne    40001e5a <filedesc_write+0x5c>
40001e36:	c7 44 24 0c 1b 38 00 	movl   $0x4000381b,0xc(%esp)
40001e3d:	40 
40001e3e:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
40001e45:	40 
40001e46:	c7 44 24 04 4f 01 00 	movl   $0x14f,0x4(%esp)
40001e4d:	00 
40001e4e:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001e55:	e8 9a e4 ff ff       	call   400002f4 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40001e5a:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40001e60:	8b 45 08             	mov    0x8(%ebp),%eax
40001e63:	8b 00                	mov    (%eax),%eax
40001e65:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001e68:	05 10 10 00 00       	add    $0x1010,%eax
40001e6d:	01 d0                	add    %edx,%eax
40001e6f:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// If we're appending to the file, seek to the end first.
	if (fd->flags & O_APPEND)
40001e72:	8b 45 08             	mov    0x8(%ebp),%eax
40001e75:	8b 40 04             	mov    0x4(%eax),%eax
40001e78:	83 e0 10             	and    $0x10,%eax
40001e7b:	85 c0                	test   %eax,%eax
40001e7d:	74 0e                	je     40001e8d <filedesc_write+0x8f>
		fd->ofs = fi->size;
40001e7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001e82:	8b 40 4c             	mov    0x4c(%eax),%eax
40001e85:	89 c2                	mov    %eax,%edx
40001e87:	8b 45 08             	mov    0x8(%ebp),%eax
40001e8a:	89 50 08             	mov    %edx,0x8(%eax)

	// Write the data, growing the file as necessary.
	ssize_t actual = fileino_write(fd->ino, fd->ofs, buf, eltsize, count);
40001e8d:	8b 45 08             	mov    0x8(%ebp),%eax
40001e90:	8b 50 08             	mov    0x8(%eax),%edx
40001e93:	8b 45 08             	mov    0x8(%ebp),%eax
40001e96:	8b 00                	mov    (%eax),%eax
40001e98:	8b 4d 14             	mov    0x14(%ebp),%ecx
40001e9b:	89 4c 24 10          	mov    %ecx,0x10(%esp)
40001e9f:	8b 4d 10             	mov    0x10(%ebp),%ecx
40001ea2:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
40001ea6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40001ea9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40001ead:	89 54 24 04          	mov    %edx,0x4(%esp)
40001eb1:	89 04 24             	mov    %eax,(%esp)
40001eb4:	e8 f9 f4 ff ff       	call   400013b2 <fileino_write>
40001eb9:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (actual < 0) {
40001ebc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40001ec0:	79 17                	jns    40001ed9 <filedesc_write+0xdb>
		fd->err = errno;	// save error indication for ferror()
40001ec2:	a1 34 36 00 40       	mov    0x40003634,%eax
40001ec7:	8b 10                	mov    (%eax),%edx
40001ec9:	8b 45 08             	mov    0x8(%ebp),%eax
40001ecc:	89 50 0c             	mov    %edx,0xc(%eax)
		return -1;
40001ecf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40001ed4:	e9 98 00 00 00       	jmp    40001f71 <filedesc_write+0x173>
	}
	assert(actual == count);
40001ed9:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001edc:	3b 45 14             	cmp    0x14(%ebp),%eax
40001edf:	74 24                	je     40001f05 <filedesc_write+0x107>
40001ee1:	c7 44 24 0c 33 38 00 	movl   $0x40003833,0xc(%esp)
40001ee8:	40 
40001ee9:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
40001ef0:	40 
40001ef1:	c7 44 24 04 5c 01 00 	movl   $0x15c,0x4(%esp)
40001ef8:	00 
40001ef9:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001f00:	e8 ef e3 ff ff       	call   400002f4 <debug_panic>

	// Non-append-only writes constitute exclusive modifications,
	// so must bump the file's version number.
	if (!(fd->flags & O_APPEND))
40001f05:	8b 45 08             	mov    0x8(%ebp),%eax
40001f08:	8b 40 04             	mov    0x4(%eax),%eax
40001f0b:	83 e0 10             	and    $0x10,%eax
40001f0e:	85 c0                	test   %eax,%eax
40001f10:	75 0f                	jne    40001f21 <filedesc_write+0x123>
		fi->ver++;
40001f12:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001f15:	8b 40 44             	mov    0x44(%eax),%eax
40001f18:	8d 50 01             	lea    0x1(%eax),%edx
40001f1b:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001f1e:	89 50 44             	mov    %edx,0x44(%eax)

	// Advance the file position
	fd->ofs += eltsize * count;
40001f21:	8b 45 08             	mov    0x8(%ebp),%eax
40001f24:	8b 40 08             	mov    0x8(%eax),%eax
40001f27:	89 c2                	mov    %eax,%edx
40001f29:	8b 45 10             	mov    0x10(%ebp),%eax
40001f2c:	0f af 45 14          	imul   0x14(%ebp),%eax
40001f30:	01 d0                	add    %edx,%eax
40001f32:	89 c2                	mov    %eax,%edx
40001f34:	8b 45 08             	mov    0x8(%ebp),%eax
40001f37:	89 50 08             	mov    %edx,0x8(%eax)
	assert(fi->size >= fd->ofs);
40001f3a:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001f3d:	8b 50 4c             	mov    0x4c(%eax),%edx
40001f40:	8b 45 08             	mov    0x8(%ebp),%eax
40001f43:	8b 40 08             	mov    0x8(%eax),%eax
40001f46:	39 c2                	cmp    %eax,%edx
40001f48:	73 24                	jae    40001f6e <filedesc_write+0x170>
40001f4a:	c7 44 24 0c 43 38 00 	movl   $0x40003843,0xc(%esp)
40001f51:	40 
40001f52:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
40001f59:	40 
40001f5a:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
40001f61:	00 
40001f62:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001f69:	e8 86 e3 ff ff       	call   400002f4 <debug_panic>
	return count;
40001f6e:	8b 45 14             	mov    0x14(%ebp),%eax
}
40001f71:	c9                   	leave  
40001f72:	c3                   	ret    

40001f73 <filedesc_seek>:
// which may be relative to the file start, end, or corrent position,
// depending on 'whence' (SEEK_SET, SEEK_CUR, or SEEK_END).
// Returns the resulting absolute file position,
// or returns -1 and sets errno appropriately on error.
off_t filedesc_seek(filedesc *fd, off_t offset, int whence)
{
40001f73:	55                   	push   %ebp
40001f74:	89 e5                	mov    %esp,%ebp
40001f76:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isopen(fd));
40001f79:	a1 34 36 00 40       	mov    0x40003634,%eax
40001f7e:	83 c0 10             	add    $0x10,%eax
40001f81:	3b 45 08             	cmp    0x8(%ebp),%eax
40001f84:	77 18                	ja     40001f9e <filedesc_seek+0x2b>
40001f86:	a1 34 36 00 40       	mov    0x40003634,%eax
40001f8b:	05 10 10 00 00       	add    $0x1010,%eax
40001f90:	3b 45 08             	cmp    0x8(%ebp),%eax
40001f93:	76 09                	jbe    40001f9e <filedesc_seek+0x2b>
40001f95:	8b 45 08             	mov    0x8(%ebp),%eax
40001f98:	8b 00                	mov    (%eax),%eax
40001f9a:	85 c0                	test   %eax,%eax
40001f9c:	75 24                	jne    40001fc2 <filedesc_seek+0x4f>
40001f9e:	c7 44 24 0c cc 37 00 	movl   $0x400037cc,0xc(%esp)
40001fa5:	40 
40001fa6:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
40001fad:	40 
40001fae:	c7 44 24 04 70 01 00 	movl   $0x170,0x4(%esp)
40001fb5:	00 
40001fb6:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001fbd:	e8 32 e3 ff ff       	call   400002f4 <debug_panic>
	assert(whence == SEEK_SET || whence == SEEK_CUR || whence == SEEK_END);
40001fc2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40001fc6:	74 30                	je     40001ff8 <filedesc_seek+0x85>
40001fc8:	83 7d 10 01          	cmpl   $0x1,0x10(%ebp)
40001fcc:	74 2a                	je     40001ff8 <filedesc_seek+0x85>
40001fce:	83 7d 10 02          	cmpl   $0x2,0x10(%ebp)
40001fd2:	74 24                	je     40001ff8 <filedesc_seek+0x85>
40001fd4:	c7 44 24 0c 58 38 00 	movl   $0x40003858,0xc(%esp)
40001fdb:	40 
40001fdc:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
40001fe3:	40 
40001fe4:	c7 44 24 04 71 01 00 	movl   $0x171,0x4(%esp)
40001feb:	00 
40001fec:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40001ff3:	e8 fc e2 ff ff       	call   400002f4 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40001ff8:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40001ffe:	8b 45 08             	mov    0x8(%ebp),%eax
40002001:	8b 00                	mov    (%eax),%eax
40002003:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002006:	05 10 10 00 00       	add    $0x1010,%eax
4000200b:	01 d0                	add    %edx,%eax
4000200d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	ino_t ino = fd->ino;
40002010:	8b 45 08             	mov    0x8(%ebp),%eax
40002013:	8b 00                	mov    (%eax),%eax
40002015:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint8_t* start_pos = FILEDATA(ino);
40002018:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000201b:	c1 e0 16             	shl    $0x16,%eax
4000201e:	05 00 00 00 80       	add    $0x80000000,%eax
40002023:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// Lab 4: insert your file descriptor seek implementation here.
	//warn("filedesc_seek() not implemented");
	//errno = EINVAL;
	//return -1;
	switch(whence){
40002026:	8b 45 10             	mov    0x10(%ebp),%eax
40002029:	83 f8 01             	cmp    $0x1,%eax
4000202c:	74 14                	je     40002042 <filedesc_seek+0xcf>
4000202e:	83 f8 02             	cmp    $0x2,%eax
40002031:	74 22                	je     40002055 <filedesc_seek+0xe2>
40002033:	85 c0                	test   %eax,%eax
40002035:	75 33                	jne    4000206a <filedesc_seek+0xf7>
	case SEEK_SET:
		fd->ofs = offset;
40002037:	8b 45 08             	mov    0x8(%ebp),%eax
4000203a:	8b 55 0c             	mov    0xc(%ebp),%edx
4000203d:	89 50 08             	mov    %edx,0x8(%eax)
		break;
40002040:	eb 3a                	jmp    4000207c <filedesc_seek+0x109>
	case SEEK_CUR:
		fd->ofs += offset;
40002042:	8b 45 08             	mov    0x8(%ebp),%eax
40002045:	8b 50 08             	mov    0x8(%eax),%edx
40002048:	8b 45 0c             	mov    0xc(%ebp),%eax
4000204b:	01 c2                	add    %eax,%edx
4000204d:	8b 45 08             	mov    0x8(%ebp),%eax
40002050:	89 50 08             	mov    %edx,0x8(%eax)
		break;
40002053:	eb 27                	jmp    4000207c <filedesc_seek+0x109>
	case SEEK_END:
		fd->ofs = (fi->size) + offset;
40002055:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002058:	8b 50 4c             	mov    0x4c(%eax),%edx
4000205b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000205e:	01 d0                	add    %edx,%eax
40002060:	89 c2                	mov    %eax,%edx
40002062:	8b 45 08             	mov    0x8(%ebp),%eax
40002065:	89 50 08             	mov    %edx,0x8(%eax)
		break;
40002068:	eb 12                	jmp    4000207c <filedesc_seek+0x109>
	default:
		errno = EINVAL;
4000206a:	a1 34 36 00 40       	mov    0x40003634,%eax
4000206f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
		return -1;
40002075:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
4000207a:	eb 06                	jmp    40002082 <filedesc_seek+0x10f>
	}
	return fd->ofs;
4000207c:	8b 45 08             	mov    0x8(%ebp),%eax
4000207f:	8b 40 08             	mov    0x8(%eax),%eax
}
40002082:	c9                   	leave  
40002083:	c3                   	ret    

40002084 <filedesc_close>:

void
filedesc_close(filedesc *fd)
{
40002084:	55                   	push   %ebp
40002085:	89 e5                	mov    %esp,%ebp
40002087:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
4000208a:	a1 34 36 00 40       	mov    0x40003634,%eax
4000208f:	83 c0 10             	add    $0x10,%eax
40002092:	3b 45 08             	cmp    0x8(%ebp),%eax
40002095:	77 18                	ja     400020af <filedesc_close+0x2b>
40002097:	a1 34 36 00 40       	mov    0x40003634,%eax
4000209c:	05 10 10 00 00       	add    $0x1010,%eax
400020a1:	3b 45 08             	cmp    0x8(%ebp),%eax
400020a4:	76 09                	jbe    400020af <filedesc_close+0x2b>
400020a6:	8b 45 08             	mov    0x8(%ebp),%eax
400020a9:	8b 00                	mov    (%eax),%eax
400020ab:	85 c0                	test   %eax,%eax
400020ad:	75 24                	jne    400020d3 <filedesc_close+0x4f>
400020af:	c7 44 24 0c cc 37 00 	movl   $0x400037cc,0xc(%esp)
400020b6:	40 
400020b7:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
400020be:	40 
400020bf:	c7 44 24 04 8e 01 00 	movl   $0x18e,0x4(%esp)
400020c6:	00 
400020c7:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
400020ce:	e8 21 e2 ff ff       	call   400002f4 <debug_panic>
	assert(fileino_isvalid(fd->ino));
400020d3:	8b 45 08             	mov    0x8(%ebp),%eax
400020d6:	8b 00                	mov    (%eax),%eax
400020d8:	85 c0                	test   %eax,%eax
400020da:	7e 0c                	jle    400020e8 <filedesc_close+0x64>
400020dc:	8b 45 08             	mov    0x8(%ebp),%eax
400020df:	8b 00                	mov    (%eax),%eax
400020e1:	3d ff 00 00 00       	cmp    $0xff,%eax
400020e6:	7e 24                	jle    4000210c <filedesc_close+0x88>
400020e8:	c7 44 24 0c 97 38 00 	movl   $0x40003897,0xc(%esp)
400020ef:	40 
400020f0:	c7 44 24 08 6c 36 00 	movl   $0x4000366c,0x8(%esp)
400020f7:	40 
400020f8:	c7 44 24 04 8f 01 00 	movl   $0x18f,0x4(%esp)
400020ff:	00 
40002100:	c7 04 24 57 36 00 40 	movl   $0x40003657,(%esp)
40002107:	e8 e8 e1 ff ff       	call   400002f4 <debug_panic>

	fd->ino = FILEINO_NULL;		// mark the fd free
4000210c:	8b 45 08             	mov    0x8(%ebp),%eax
4000210f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
40002115:	c9                   	leave  
40002116:	c3                   	ret    
40002117:	90                   	nop

40002118 <dir_walk>:
#include <inc/dirent.h>


int
dir_walk(const char *path, mode_t createmode)
{
40002118:	55                   	push   %ebp
40002119:	89 e5                	mov    %esp,%ebp
4000211b:	83 ec 28             	sub    $0x28,%esp
	assert(path != 0 && *path != 0);
4000211e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40002122:	74 0a                	je     4000212e <dir_walk+0x16>
40002124:	8b 45 08             	mov    0x8(%ebp),%eax
40002127:	0f b6 00             	movzbl (%eax),%eax
4000212a:	84 c0                	test   %al,%al
4000212c:	75 24                	jne    40002152 <dir_walk+0x3a>
4000212e:	c7 44 24 0c b0 38 00 	movl   $0x400038b0,0xc(%esp)
40002135:	40 
40002136:	c7 44 24 08 c8 38 00 	movl   $0x400038c8,0x8(%esp)
4000213d:	40 
4000213e:	c7 44 24 04 15 00 00 	movl   $0x15,0x4(%esp)
40002145:	00 
40002146:	c7 04 24 dd 38 00 40 	movl   $0x400038dd,(%esp)
4000214d:	e8 a2 e1 ff ff       	call   400002f4 <debug_panic>

	// Start at the current or root directory as appropriate
	int dino = files->cwd;
40002152:	a1 34 36 00 40       	mov    0x40003634,%eax
40002157:	8b 40 04             	mov    0x4(%eax),%eax
4000215a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (*path == '/') {
4000215d:	8b 45 08             	mov    0x8(%ebp),%eax
40002160:	0f b6 00             	movzbl (%eax),%eax
40002163:	3c 2f                	cmp    $0x2f,%al
40002165:	75 27                	jne    4000218e <dir_walk+0x76>
		dino = FILEINO_ROOTDIR;
40002167:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
		do { path++; } while (*path == '/');	// skip leading slashes
4000216e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40002172:	8b 45 08             	mov    0x8(%ebp),%eax
40002175:	0f b6 00             	movzbl (%eax),%eax
40002178:	3c 2f                	cmp    $0x2f,%al
4000217a:	74 f2                	je     4000216e <dir_walk+0x56>
		if (*path == 0)
4000217c:	8b 45 08             	mov    0x8(%ebp),%eax
4000217f:	0f b6 00             	movzbl (%eax),%eax
40002182:	84 c0                	test   %al,%al
40002184:	75 08                	jne    4000218e <dir_walk+0x76>
			return dino;	// Just looking up root directory
40002186:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002189:	e9 61 05 00 00       	jmp    400026ef <dir_walk+0x5d7>
	}

	// Search for the appropriate entry in this directory
	searchdir:
	assert(fileino_isdir(dino));
4000218e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002192:	7e 45                	jle    400021d9 <dir_walk+0xc1>
40002194:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
4000219b:	7f 3c                	jg     400021d9 <dir_walk+0xc1>
4000219d:	8b 15 34 36 00 40    	mov    0x40003634,%edx
400021a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
400021a6:	6b c0 5c             	imul   $0x5c,%eax,%eax
400021a9:	01 d0                	add    %edx,%eax
400021ab:	05 10 10 00 00       	add    $0x1010,%eax
400021b0:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400021b4:	84 c0                	test   %al,%al
400021b6:	74 21                	je     400021d9 <dir_walk+0xc1>
400021b8:	8b 15 34 36 00 40    	mov    0x40003634,%edx
400021be:	8b 45 f4             	mov    -0xc(%ebp),%eax
400021c1:	6b c0 5c             	imul   $0x5c,%eax,%eax
400021c4:	01 d0                	add    %edx,%eax
400021c6:	05 58 10 00 00       	add    $0x1058,%eax
400021cb:	8b 00                	mov    (%eax),%eax
400021cd:	25 00 70 00 00       	and    $0x7000,%eax
400021d2:	3d 00 20 00 00       	cmp    $0x2000,%eax
400021d7:	74 24                	je     400021fd <dir_walk+0xe5>
400021d9:	c7 44 24 0c e7 38 00 	movl   $0x400038e7,0xc(%esp)
400021e0:	40 
400021e1:	c7 44 24 08 c8 38 00 	movl   $0x400038c8,0x8(%esp)
400021e8:	40 
400021e9:	c7 44 24 04 22 00 00 	movl   $0x22,0x4(%esp)
400021f0:	00 
400021f1:	c7 04 24 dd 38 00 40 	movl   $0x400038dd,(%esp)
400021f8:	e8 f7 e0 ff ff       	call   400002f4 <debug_panic>
	assert(fileino_isdir(files->fi[dino].dino));
400021fd:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40002203:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002206:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002209:	01 d0                	add    %edx,%eax
4000220b:	05 10 10 00 00       	add    $0x1010,%eax
40002210:	8b 00                	mov    (%eax),%eax
40002212:	85 c0                	test   %eax,%eax
40002214:	7e 7c                	jle    40002292 <dir_walk+0x17a>
40002216:	8b 15 34 36 00 40    	mov    0x40003634,%edx
4000221c:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000221f:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002222:	01 d0                	add    %edx,%eax
40002224:	05 10 10 00 00       	add    $0x1010,%eax
40002229:	8b 00                	mov    (%eax),%eax
4000222b:	3d ff 00 00 00       	cmp    $0xff,%eax
40002230:	7f 60                	jg     40002292 <dir_walk+0x17a>
40002232:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40002238:	8b 0d 34 36 00 40    	mov    0x40003634,%ecx
4000223e:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002241:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002244:	01 c8                	add    %ecx,%eax
40002246:	05 10 10 00 00       	add    $0x1010,%eax
4000224b:	8b 00                	mov    (%eax),%eax
4000224d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002250:	01 d0                	add    %edx,%eax
40002252:	05 10 10 00 00       	add    $0x1010,%eax
40002257:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000225b:	84 c0                	test   %al,%al
4000225d:	74 33                	je     40002292 <dir_walk+0x17a>
4000225f:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40002265:	8b 0d 34 36 00 40    	mov    0x40003634,%ecx
4000226b:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000226e:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002271:	01 c8                	add    %ecx,%eax
40002273:	05 10 10 00 00       	add    $0x1010,%eax
40002278:	8b 00                	mov    (%eax),%eax
4000227a:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000227d:	01 d0                	add    %edx,%eax
4000227f:	05 58 10 00 00       	add    $0x1058,%eax
40002284:	8b 00                	mov    (%eax),%eax
40002286:	25 00 70 00 00       	and    $0x7000,%eax
4000228b:	3d 00 20 00 00       	cmp    $0x2000,%eax
40002290:	74 24                	je     400022b6 <dir_walk+0x19e>
40002292:	c7 44 24 0c fc 38 00 	movl   $0x400038fc,0xc(%esp)
40002299:	40 
4000229a:	c7 44 24 08 c8 38 00 	movl   $0x400038c8,0x8(%esp)
400022a1:	40 
400022a2:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
400022a9:	00 
400022aa:	c7 04 24 dd 38 00 40 	movl   $0x400038dd,(%esp)
400022b1:	e8 3e e0 ff ff       	call   400002f4 <debug_panic>

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
400022b6:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
400022bd:	e9 3d 02 00 00       	jmp    400024ff <dir_walk+0x3e7>
		if (!fileino_alloced(ino) || files->fi[ino].dino != dino)
400022c2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400022c6:	0f 8e 28 02 00 00    	jle    400024f4 <dir_walk+0x3dc>
400022cc:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
400022d3:	0f 8f 1b 02 00 00    	jg     400024f4 <dir_walk+0x3dc>
400022d9:	8b 15 34 36 00 40    	mov    0x40003634,%edx
400022df:	8b 45 f0             	mov    -0x10(%ebp),%eax
400022e2:	6b c0 5c             	imul   $0x5c,%eax,%eax
400022e5:	01 d0                	add    %edx,%eax
400022e7:	05 10 10 00 00       	add    $0x1010,%eax
400022ec:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400022f0:	84 c0                	test   %al,%al
400022f2:	0f 84 fc 01 00 00    	je     400024f4 <dir_walk+0x3dc>
400022f8:	8b 15 34 36 00 40    	mov    0x40003634,%edx
400022fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002301:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002304:	01 d0                	add    %edx,%eax
40002306:	05 10 10 00 00       	add    $0x1010,%eax
4000230b:	8b 00                	mov    (%eax),%eax
4000230d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40002310:	0f 85 de 01 00 00    	jne    400024f4 <dir_walk+0x3dc>
			continue;	// not an entry in directory 'dino'

		// Does this inode's name match our next path component?
		len = strlen(files->fi[ino].de.d_name);
40002316:	a1 34 36 00 40       	mov    0x40003634,%eax
4000231b:	8b 55 f0             	mov    -0x10(%ebp),%edx
4000231e:	6b d2 5c             	imul   $0x5c,%edx,%edx
40002321:	81 c2 10 10 00 00    	add    $0x1010,%edx
40002327:	01 d0                	add    %edx,%eax
40002329:	83 c0 04             	add    $0x4,%eax
4000232c:	89 04 24             	mov    %eax,(%esp)
4000232f:	e8 34 e9 ff ff       	call   40000c68 <strlen>
40002334:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (memcmp(path, files->fi[ino].de.d_name, len) != 0)
40002337:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000233a:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40002340:	8b 4d f0             	mov    -0x10(%ebp),%ecx
40002343:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
40002346:	81 c1 10 10 00 00    	add    $0x1010,%ecx
4000234c:	01 ca                	add    %ecx,%edx
4000234e:	83 c2 04             	add    $0x4,%edx
40002351:	89 44 24 08          	mov    %eax,0x8(%esp)
40002355:	89 54 24 04          	mov    %edx,0x4(%esp)
40002359:	8b 45 08             	mov    0x8(%ebp),%eax
4000235c:	89 04 24             	mov    %eax,(%esp)
4000235f:	e8 2a ec ff ff       	call   40000f8e <memcmp>
40002364:	85 c0                	test   %eax,%eax
40002366:	0f 85 8b 01 00 00    	jne    400024f7 <dir_walk+0x3df>
			continue;	// no match
		found:
		if (path[len] == 0) {
4000236c:	8b 55 ec             	mov    -0x14(%ebp),%edx
4000236f:	8b 45 08             	mov    0x8(%ebp),%eax
40002372:	01 d0                	add    %edx,%eax
40002374:	0f b6 00             	movzbl (%eax),%eax
40002377:	84 c0                	test   %al,%al
40002379:	0f 85 c7 00 00 00    	jne    40002446 <dir_walk+0x32e>
			// Exact match at end of path - but does it exist?
			if (fileino_exists(ino))
4000237f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002383:	7e 45                	jle    400023ca <dir_walk+0x2b2>
40002385:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
4000238c:	7f 3c                	jg     400023ca <dir_walk+0x2b2>
4000238e:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40002394:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002397:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000239a:	01 d0                	add    %edx,%eax
4000239c:	05 10 10 00 00       	add    $0x1010,%eax
400023a1:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400023a5:	84 c0                	test   %al,%al
400023a7:	74 21                	je     400023ca <dir_walk+0x2b2>
400023a9:	8b 15 34 36 00 40    	mov    0x40003634,%edx
400023af:	8b 45 f0             	mov    -0x10(%ebp),%eax
400023b2:	6b c0 5c             	imul   $0x5c,%eax,%eax
400023b5:	01 d0                	add    %edx,%eax
400023b7:	05 58 10 00 00       	add    $0x1058,%eax
400023bc:	8b 00                	mov    (%eax),%eax
400023be:	85 c0                	test   %eax,%eax
400023c0:	74 08                	je     400023ca <dir_walk+0x2b2>
				return ino;	// yes - return it
400023c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
400023c5:	e9 25 03 00 00       	jmp    400026ef <dir_walk+0x5d7>

			// no - existed, but was deleted.  re-create?
			if (!createmode) {
400023ca:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400023ce:	75 15                	jne    400023e5 <dir_walk+0x2cd>
				errno = ENOENT;
400023d0:	a1 34 36 00 40       	mov    0x40003634,%eax
400023d5:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
				return -1;
400023db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400023e0:	e9 0a 03 00 00       	jmp    400026ef <dir_walk+0x5d7>
			}
			files->fi[ino].ver++;	// an exclusive change
400023e5:	a1 34 36 00 40       	mov    0x40003634,%eax
400023ea:	8b 55 f0             	mov    -0x10(%ebp),%edx
400023ed:	6b d2 5c             	imul   $0x5c,%edx,%edx
400023f0:	01 c2                	add    %eax,%edx
400023f2:	81 c2 54 10 00 00    	add    $0x1054,%edx
400023f8:	8b 12                	mov    (%edx),%edx
400023fa:	83 c2 01             	add    $0x1,%edx
400023fd:	8b 4d f0             	mov    -0x10(%ebp),%ecx
40002400:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
40002403:	01 c8                	add    %ecx,%eax
40002405:	05 54 10 00 00       	add    $0x1054,%eax
4000240a:	89 10                	mov    %edx,(%eax)
			files->fi[ino].mode = createmode;
4000240c:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40002412:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002415:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002418:	01 d0                	add    %edx,%eax
4000241a:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
40002420:	8b 45 0c             	mov    0xc(%ebp),%eax
40002423:	89 02                	mov    %eax,(%edx)
			files->fi[ino].size = 0;
40002425:	8b 15 34 36 00 40    	mov    0x40003634,%edx
4000242b:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000242e:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002431:	01 d0                	add    %edx,%eax
40002433:	05 5c 10 00 00       	add    $0x105c,%eax
40002438:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			return ino;
4000243e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002441:	e9 a9 02 00 00       	jmp    400026ef <dir_walk+0x5d7>
		}
		if (path[len] != '/')
40002446:	8b 55 ec             	mov    -0x14(%ebp),%edx
40002449:	8b 45 08             	mov    0x8(%ebp),%eax
4000244c:	01 d0                	add    %edx,%eax
4000244e:	0f b6 00             	movzbl (%eax),%eax
40002451:	3c 2f                	cmp    $0x2f,%al
40002453:	0f 85 a1 00 00 00    	jne    400024fa <dir_walk+0x3e2>
			continue;	// no match

		// Make sure this dirent refers to a directory
		if (!fileino_isdir(ino)) {
40002459:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
4000245d:	7e 45                	jle    400024a4 <dir_walk+0x38c>
4000245f:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40002466:	7f 3c                	jg     400024a4 <dir_walk+0x38c>
40002468:	8b 15 34 36 00 40    	mov    0x40003634,%edx
4000246e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002471:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002474:	01 d0                	add    %edx,%eax
40002476:	05 10 10 00 00       	add    $0x1010,%eax
4000247b:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000247f:	84 c0                	test   %al,%al
40002481:	74 21                	je     400024a4 <dir_walk+0x38c>
40002483:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40002489:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000248c:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000248f:	01 d0                	add    %edx,%eax
40002491:	05 58 10 00 00       	add    $0x1058,%eax
40002496:	8b 00                	mov    (%eax),%eax
40002498:	25 00 70 00 00       	and    $0x7000,%eax
4000249d:	3d 00 20 00 00       	cmp    $0x2000,%eax
400024a2:	74 15                	je     400024b9 <dir_walk+0x3a1>
			errno = ENOTDIR;
400024a4:	a1 34 36 00 40       	mov    0x40003634,%eax
400024a9:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
			return -1;
400024af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400024b4:	e9 36 02 00 00       	jmp    400026ef <dir_walk+0x5d7>
		}

		// Skip slashes to find next component
		do { len++; } while (path[len] == '/');
400024b9:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
400024bd:	8b 55 ec             	mov    -0x14(%ebp),%edx
400024c0:	8b 45 08             	mov    0x8(%ebp),%eax
400024c3:	01 d0                	add    %edx,%eax
400024c5:	0f b6 00             	movzbl (%eax),%eax
400024c8:	3c 2f                	cmp    $0x2f,%al
400024ca:	74 ed                	je     400024b9 <dir_walk+0x3a1>
		if (path[len] == 0)
400024cc:	8b 55 ec             	mov    -0x14(%ebp),%edx
400024cf:	8b 45 08             	mov    0x8(%ebp),%eax
400024d2:	01 d0                	add    %edx,%eax
400024d4:	0f b6 00             	movzbl (%eax),%eax
400024d7:	84 c0                	test   %al,%al
400024d9:	75 08                	jne    400024e3 <dir_walk+0x3cb>
			return ino;	// matched directory at end of path
400024db:	8b 45 f0             	mov    -0x10(%ebp),%eax
400024de:	e9 0c 02 00 00       	jmp    400026ef <dir_walk+0x5d7>

		// Walk the next directory in the path
		dino = ino;
400024e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
400024e6:	89 45 f4             	mov    %eax,-0xc(%ebp)
		path += len;
400024e9:	8b 45 ec             	mov    -0x14(%ebp),%eax
400024ec:	01 45 08             	add    %eax,0x8(%ebp)
		goto searchdir;
400024ef:	e9 9a fc ff ff       	jmp    4000218e <dir_walk+0x76>

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
		if (!fileino_alloced(ino) || files->fi[ino].dino != dino)
			continue;	// not an entry in directory 'dino'
400024f4:	90                   	nop
400024f5:	eb 04                	jmp    400024fb <dir_walk+0x3e3>

		// Does this inode's name match our next path component?
		len = strlen(files->fi[ino].de.d_name);
		if (memcmp(path, files->fi[ino].de.d_name, len) != 0)
			continue;	// no match
400024f7:	90                   	nop
400024f8:	eb 01                	jmp    400024fb <dir_walk+0x3e3>
			files->fi[ino].mode = createmode;
			files->fi[ino].size = 0;
			return ino;
		}
		if (path[len] != '/')
			continue;	// no match
400024fa:	90                   	nop
	assert(fileino_isdir(dino));
	assert(fileino_isdir(files->fi[dino].dino));

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
400024fb:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
400024ff:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40002506:	0f 8e b6 fd ff ff    	jle    400022c2 <dir_walk+0x1aa>
		path += len;
		goto searchdir;
	}

	// Looking for one of the special entries '.' or '..'?
	if (path[0] == '.' && (path[1] == 0 || path[1] == '/')) {
4000250c:	8b 45 08             	mov    0x8(%ebp),%eax
4000250f:	0f b6 00             	movzbl (%eax),%eax
40002512:	3c 2e                	cmp    $0x2e,%al
40002514:	75 2c                	jne    40002542 <dir_walk+0x42a>
40002516:	8b 45 08             	mov    0x8(%ebp),%eax
40002519:	83 c0 01             	add    $0x1,%eax
4000251c:	0f b6 00             	movzbl (%eax),%eax
4000251f:	84 c0                	test   %al,%al
40002521:	74 0d                	je     40002530 <dir_walk+0x418>
40002523:	8b 45 08             	mov    0x8(%ebp),%eax
40002526:	83 c0 01             	add    $0x1,%eax
40002529:	0f b6 00             	movzbl (%eax),%eax
4000252c:	3c 2f                	cmp    $0x2f,%al
4000252e:	75 12                	jne    40002542 <dir_walk+0x42a>
		len = 1;
40002530:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		ino = dino;	// just leads to this same directory
40002537:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000253a:	89 45 f0             	mov    %eax,-0x10(%ebp)
		goto found;
4000253d:	e9 2a fe ff ff       	jmp    4000236c <dir_walk+0x254>
	}
	if (path[0] == '.' && path[1] == '.'
40002542:	8b 45 08             	mov    0x8(%ebp),%eax
40002545:	0f b6 00             	movzbl (%eax),%eax
40002548:	3c 2e                	cmp    $0x2e,%al
4000254a:	75 4b                	jne    40002597 <dir_walk+0x47f>
4000254c:	8b 45 08             	mov    0x8(%ebp),%eax
4000254f:	83 c0 01             	add    $0x1,%eax
40002552:	0f b6 00             	movzbl (%eax),%eax
40002555:	3c 2e                	cmp    $0x2e,%al
40002557:	75 3e                	jne    40002597 <dir_walk+0x47f>
			&& (path[2] == 0 || path[2] == '/')) {
40002559:	8b 45 08             	mov    0x8(%ebp),%eax
4000255c:	83 c0 02             	add    $0x2,%eax
4000255f:	0f b6 00             	movzbl (%eax),%eax
40002562:	84 c0                	test   %al,%al
40002564:	74 0d                	je     40002573 <dir_walk+0x45b>
40002566:	8b 45 08             	mov    0x8(%ebp),%eax
40002569:	83 c0 02             	add    $0x2,%eax
4000256c:	0f b6 00             	movzbl (%eax),%eax
4000256f:	3c 2f                	cmp    $0x2f,%al
40002571:	75 24                	jne    40002597 <dir_walk+0x47f>
		len = 2;
40002573:	c7 45 ec 02 00 00 00 	movl   $0x2,-0x14(%ebp)
		ino = files->fi[dino].dino;	// leads to root directory
4000257a:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40002580:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002583:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002586:	01 d0                	add    %edx,%eax
40002588:	05 10 10 00 00       	add    $0x1010,%eax
4000258d:	8b 00                	mov    (%eax),%eax
4000258f:	89 45 f0             	mov    %eax,-0x10(%ebp)
		goto found;
40002592:	e9 d5 fd ff ff       	jmp    4000236c <dir_walk+0x254>
	}

	// Path component not found - see if we should create it
	if (!createmode || strchr(path, '/') != NULL) {
40002597:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
4000259b:	74 17                	je     400025b4 <dir_walk+0x49c>
4000259d:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
400025a4:	00 
400025a5:	8b 45 08             	mov    0x8(%ebp),%eax
400025a8:	89 04 24             	mov    %eax,(%esp)
400025ab:	e8 3d e8 ff ff       	call   40000ded <strchr>
400025b0:	85 c0                	test   %eax,%eax
400025b2:	74 15                	je     400025c9 <dir_walk+0x4b1>
		errno = ENOENT;
400025b4:	a1 34 36 00 40       	mov    0x40003634,%eax
400025b9:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
		return -1;
400025bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400025c4:	e9 26 01 00 00       	jmp    400026ef <dir_walk+0x5d7>
	}
	if (strlen(path) > NAME_MAX) {
400025c9:	8b 45 08             	mov    0x8(%ebp),%eax
400025cc:	89 04 24             	mov    %eax,(%esp)
400025cf:	e8 94 e6 ff ff       	call   40000c68 <strlen>
400025d4:	83 f8 3f             	cmp    $0x3f,%eax
400025d7:	7e 15                	jle    400025ee <dir_walk+0x4d6>
		errno = ENAMETOOLONG;
400025d9:	a1 34 36 00 40       	mov    0x40003634,%eax
400025de:	c7 00 06 00 00 00    	movl   $0x6,(%eax)
		return -1;
400025e4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400025e9:	e9 01 01 00 00       	jmp    400026ef <dir_walk+0x5d7>
	}

	// Allocate a new inode and create this entry with the given mode.
	ino = fileino_alloc();
400025ee:	e8 31 ea ff ff       	call   40001024 <fileino_alloc>
400025f3:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (ino < 0)
400025f6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400025fa:	79 0a                	jns    40002606 <dir_walk+0x4ee>
		return -1;
400025fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002601:	e9 e9 00 00 00       	jmp    400026ef <dir_walk+0x5d7>
	assert(fileino_isvalid(ino) && !fileino_alloced(ino));
40002606:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
4000260a:	7e 33                	jle    4000263f <dir_walk+0x527>
4000260c:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40002613:	7f 2a                	jg     4000263f <dir_walk+0x527>
40002615:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002619:	7e 48                	jle    40002663 <dir_walk+0x54b>
4000261b:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40002622:	7f 3f                	jg     40002663 <dir_walk+0x54b>
40002624:	8b 15 34 36 00 40    	mov    0x40003634,%edx
4000262a:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000262d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002630:	01 d0                	add    %edx,%eax
40002632:	05 10 10 00 00       	add    $0x1010,%eax
40002637:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000263b:	84 c0                	test   %al,%al
4000263d:	74 24                	je     40002663 <dir_walk+0x54b>
4000263f:	c7 44 24 0c 20 39 00 	movl   $0x40003920,0xc(%esp)
40002646:	40 
40002647:	c7 44 24 08 c8 38 00 	movl   $0x400038c8,0x8(%esp)
4000264e:	40 
4000264f:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
40002656:	00 
40002657:	c7 04 24 dd 38 00 40 	movl   $0x400038dd,(%esp)
4000265e:	e8 91 dc ff ff       	call   400002f4 <debug_panic>
	strcpy(files->fi[ino].de.d_name, path);
40002663:	a1 34 36 00 40       	mov    0x40003634,%eax
40002668:	8b 55 f0             	mov    -0x10(%ebp),%edx
4000266b:	6b d2 5c             	imul   $0x5c,%edx,%edx
4000266e:	81 c2 10 10 00 00    	add    $0x1010,%edx
40002674:	01 d0                	add    %edx,%eax
40002676:	8d 50 04             	lea    0x4(%eax),%edx
40002679:	8b 45 08             	mov    0x8(%ebp),%eax
4000267c:	89 44 24 04          	mov    %eax,0x4(%esp)
40002680:	89 14 24             	mov    %edx,(%esp)
40002683:	e8 06 e6 ff ff       	call   40000c8e <strcpy>
	files->fi[ino].dino = dino;
40002688:	8b 15 34 36 00 40    	mov    0x40003634,%edx
4000268e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002691:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002694:	01 d0                	add    %edx,%eax
40002696:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
4000269c:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000269f:	89 02                	mov    %eax,(%edx)
	files->fi[ino].ver = 0;
400026a1:	8b 15 34 36 00 40    	mov    0x40003634,%edx
400026a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
400026aa:	6b c0 5c             	imul   $0x5c,%eax,%eax
400026ad:	01 d0                	add    %edx,%eax
400026af:	05 54 10 00 00       	add    $0x1054,%eax
400026b4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	files->fi[ino].mode = createmode;
400026ba:	8b 15 34 36 00 40    	mov    0x40003634,%edx
400026c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
400026c3:	6b c0 5c             	imul   $0x5c,%eax,%eax
400026c6:	01 d0                	add    %edx,%eax
400026c8:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
400026ce:	8b 45 0c             	mov    0xc(%ebp),%eax
400026d1:	89 02                	mov    %eax,(%edx)
	files->fi[ino].size = 0;
400026d3:	8b 15 34 36 00 40    	mov    0x40003634,%edx
400026d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
400026dc:	6b c0 5c             	imul   $0x5c,%eax,%eax
400026df:	01 d0                	add    %edx,%eax
400026e1:	05 5c 10 00 00       	add    $0x105c,%eax
400026e6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return ino;
400026ec:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
400026ef:	c9                   	leave  
400026f0:	c3                   	ret    

400026f1 <opendir>:
// Open a directory for scanning.
// For simplicity, DIR is simply a filedesc like other file descriptors,
// except we interpret fd->ofs as an inode number for scanning,
// instead of as a byte offset as in a regular file.
DIR *opendir(const char *path)
{
400026f1:	55                   	push   %ebp
400026f2:	89 e5                	mov    %esp,%ebp
400026f4:	83 ec 28             	sub    $0x28,%esp
	filedesc *fd = filedesc_open(NULL, path, O_RDONLY, 0);
400026f7:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
400026fe:	00 
400026ff:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40002706:	00 
40002707:	8b 45 08             	mov    0x8(%ebp),%eax
4000270a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000270e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002715:	e8 a5 f3 ff ff       	call   40001abf <filedesc_open>
4000271a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (fd == NULL)
4000271d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002721:	75 0a                	jne    4000272d <opendir+0x3c>
		return NULL;
40002723:	b8 00 00 00 00       	mov    $0x0,%eax
40002728:	e9 bb 00 00 00       	jmp    400027e8 <opendir+0xf7>

	// Make sure it's a directory
	assert(fileino_exists(fd->ino));
4000272d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002730:	8b 00                	mov    (%eax),%eax
40002732:	85 c0                	test   %eax,%eax
40002734:	7e 44                	jle    4000277a <opendir+0x89>
40002736:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002739:	8b 00                	mov    (%eax),%eax
4000273b:	3d ff 00 00 00       	cmp    $0xff,%eax
40002740:	7f 38                	jg     4000277a <opendir+0x89>
40002742:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40002748:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000274b:	8b 00                	mov    (%eax),%eax
4000274d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002750:	01 d0                	add    %edx,%eax
40002752:	05 10 10 00 00       	add    $0x1010,%eax
40002757:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000275b:	84 c0                	test   %al,%al
4000275d:	74 1b                	je     4000277a <opendir+0x89>
4000275f:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40002765:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002768:	8b 00                	mov    (%eax),%eax
4000276a:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000276d:	01 d0                	add    %edx,%eax
4000276f:	05 58 10 00 00       	add    $0x1058,%eax
40002774:	8b 00                	mov    (%eax),%eax
40002776:	85 c0                	test   %eax,%eax
40002778:	75 24                	jne    4000279e <opendir+0xad>
4000277a:	c7 44 24 0c 4e 39 00 	movl   $0x4000394e,0xc(%esp)
40002781:	40 
40002782:	c7 44 24 08 c8 38 00 	movl   $0x400038c8,0x8(%esp)
40002789:	40 
4000278a:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
40002791:	00 
40002792:	c7 04 24 dd 38 00 40 	movl   $0x400038dd,(%esp)
40002799:	e8 56 db ff ff       	call   400002f4 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
4000279e:	8b 15 34 36 00 40    	mov    0x40003634,%edx
400027a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
400027a7:	8b 00                	mov    (%eax),%eax
400027a9:	6b c0 5c             	imul   $0x5c,%eax,%eax
400027ac:	05 10 10 00 00       	add    $0x1010,%eax
400027b1:	01 d0                	add    %edx,%eax
400027b3:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (!S_ISDIR(fi->mode)) {
400027b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
400027b9:	8b 40 48             	mov    0x48(%eax),%eax
400027bc:	25 00 70 00 00       	and    $0x7000,%eax
400027c1:	3d 00 20 00 00       	cmp    $0x2000,%eax
400027c6:	74 1d                	je     400027e5 <opendir+0xf4>
		filedesc_close(fd);
400027c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
400027cb:	89 04 24             	mov    %eax,(%esp)
400027ce:	e8 b1 f8 ff ff       	call   40002084 <filedesc_close>
		errno = ENOTDIR;
400027d3:	a1 34 36 00 40       	mov    0x40003634,%eax
400027d8:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
		return NULL;
400027de:	b8 00 00 00 00       	mov    $0x0,%eax
400027e3:	eb 03                	jmp    400027e8 <opendir+0xf7>
	}

	return fd;
400027e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
400027e8:	c9                   	leave  
400027e9:	c3                   	ret    

400027ea <closedir>:

int closedir(DIR *dir)
{
400027ea:	55                   	push   %ebp
400027eb:	89 e5                	mov    %esp,%ebp
400027ed:	83 ec 18             	sub    $0x18,%esp
	filedesc_close(dir);
400027f0:	8b 45 08             	mov    0x8(%ebp),%eax
400027f3:	89 04 24             	mov    %eax,(%esp)
400027f6:	e8 89 f8 ff ff       	call   40002084 <filedesc_close>
	return 0;
400027fb:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002800:	c9                   	leave  
40002801:	c3                   	ret    

40002802 <readdir>:

// Scan an open directory filedesc and return the next entry.
// Returns a pointer to the next matching file inode's 'dirent' struct,
// or NULL if the directory being scanned contains no more entries.
struct dirent *readdir(DIR *dir)
{
40002802:	55                   	push   %ebp
40002803:	89 e5                	mov    %esp,%ebp
40002805:	83 ec 28             	sub    $0x28,%esp
	// Hint: a fileinode's 'dino' field indicates
	// what directory the file is in;
	// this function shouldn't return entries from other directories!
	//warn("readdir() not implemented");
	//return NULL;
	assert(fileino_isdir(dir->ino));
40002808:	8b 45 08             	mov    0x8(%ebp),%eax
4000280b:	8b 00                	mov    (%eax),%eax
4000280d:	85 c0                	test   %eax,%eax
4000280f:	7e 4c                	jle    4000285d <readdir+0x5b>
40002811:	8b 45 08             	mov    0x8(%ebp),%eax
40002814:	8b 00                	mov    (%eax),%eax
40002816:	3d ff 00 00 00       	cmp    $0xff,%eax
4000281b:	7f 40                	jg     4000285d <readdir+0x5b>
4000281d:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40002823:	8b 45 08             	mov    0x8(%ebp),%eax
40002826:	8b 00                	mov    (%eax),%eax
40002828:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000282b:	01 d0                	add    %edx,%eax
4000282d:	05 10 10 00 00       	add    $0x1010,%eax
40002832:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002836:	84 c0                	test   %al,%al
40002838:	74 23                	je     4000285d <readdir+0x5b>
4000283a:	8b 15 34 36 00 40    	mov    0x40003634,%edx
40002840:	8b 45 08             	mov    0x8(%ebp),%eax
40002843:	8b 00                	mov    (%eax),%eax
40002845:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002848:	01 d0                	add    %edx,%eax
4000284a:	05 58 10 00 00       	add    $0x1058,%eax
4000284f:	8b 00                	mov    (%eax),%eax
40002851:	25 00 70 00 00       	and    $0x7000,%eax
40002856:	3d 00 20 00 00       	cmp    $0x2000,%eax
4000285b:	74 24                	je     40002881 <readdir+0x7f>
4000285d:	c7 44 24 0c 66 39 00 	movl   $0x40003966,0xc(%esp)
40002864:	40 
40002865:	c7 44 24 08 c8 38 00 	movl   $0x400038c8,0x8(%esp)
4000286c:	40 
4000286d:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
40002874:	00 
40002875:	c7 04 24 dd 38 00 40 	movl   $0x400038dd,(%esp)
4000287c:	e8 73 da ff ff       	call   400002f4 <debug_panic>
	int i = dir->ofs;
40002881:	8b 45 08             	mov    0x8(%ebp),%eax
40002884:	8b 40 08             	mov    0x8(%eax),%eax
40002887:	89 45 f4             	mov    %eax,-0xc(%ebp)
	for(i; i < FILE_INODES; i++){
4000288a:	eb 3c                	jmp    400028c8 <readdir+0xc6>
		fileinode* tmp_fi = &files->fi[i];
4000288c:	a1 34 36 00 40       	mov    0x40003634,%eax
40002891:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002894:	6b d2 5c             	imul   $0x5c,%edx,%edx
40002897:	81 c2 10 10 00 00    	add    $0x1010,%edx
4000289d:	01 d0                	add    %edx,%eax
4000289f:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if(tmp_fi->dino == dir->ino){
400028a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
400028a5:	8b 10                	mov    (%eax),%edx
400028a7:	8b 45 08             	mov    0x8(%ebp),%eax
400028aa:	8b 00                	mov    (%eax),%eax
400028ac:	39 c2                	cmp    %eax,%edx
400028ae:	75 14                	jne    400028c4 <readdir+0xc2>
			dir->ofs = i+1;
400028b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
400028b3:	8d 50 01             	lea    0x1(%eax),%edx
400028b6:	8b 45 08             	mov    0x8(%ebp),%eax
400028b9:	89 50 08             	mov    %edx,0x8(%eax)
			return &tmp_fi->de;
400028bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
400028bf:	83 c0 04             	add    $0x4,%eax
400028c2:	eb 1c                	jmp    400028e0 <readdir+0xde>
	// this function shouldn't return entries from other directories!
	//warn("readdir() not implemented");
	//return NULL;
	assert(fileino_isdir(dir->ino));
	int i = dir->ofs;
	for(i; i < FILE_INODES; i++){
400028c4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
400028c8:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
400028cf:	7e bb                	jle    4000288c <readdir+0x8a>
		if(tmp_fi->dino == dir->ino){
			dir->ofs = i+1;
			return &tmp_fi->de;
		}
	}
	dir->ofs = 0;
400028d1:	8b 45 08             	mov    0x8(%ebp),%eax
400028d4:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
	return NULL;
400028db:	b8 00 00 00 00       	mov    $0x0,%eax
}
400028e0:	c9                   	leave  
400028e1:	c3                   	ret    

400028e2 <rewinddir>:

void rewinddir(DIR *dir)
{
400028e2:	55                   	push   %ebp
400028e3:	89 e5                	mov    %esp,%ebp
	dir->ofs = 0;
400028e5:	8b 45 08             	mov    0x8(%ebp),%eax
400028e8:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
400028ef:	5d                   	pop    %ebp
400028f0:	c3                   	ret    

400028f1 <seekdir>:

void seekdir(DIR *dir, long ofs)
{
400028f1:	55                   	push   %ebp
400028f2:	89 e5                	mov    %esp,%ebp
	dir->ofs = ofs;
400028f4:	8b 45 08             	mov    0x8(%ebp),%eax
400028f7:	8b 55 0c             	mov    0xc(%ebp),%edx
400028fa:	89 50 08             	mov    %edx,0x8(%eax)
}
400028fd:	5d                   	pop    %ebp
400028fe:	c3                   	ret    

400028ff <telldir>:

long telldir(DIR *dir)
{
400028ff:	55                   	push   %ebp
40002900:	89 e5                	mov    %esp,%ebp
	return dir->ofs;
40002902:	8b 45 08             	mov    0x8(%ebp),%eax
40002905:	8b 40 08             	mov    0x8(%eax),%eax
}
40002908:	5d                   	pop    %ebp
40002909:	c3                   	ret    
4000290a:	66 90                	xchg   %ax,%ax

4000290c <exit>:
#include <inc/assert.h>
#include <inc/string.h>

void gcc_noreturn
exit(int status)
{
4000290c:	55                   	push   %ebp
4000290d:	89 e5                	mov    %esp,%ebp
4000290f:	83 ec 18             	sub    $0x18,%esp
	// To exit a PIOS user process, by convention,
	// we just set our exit status in our filestate area
	// and return to our parent process.
	files->status = status;
40002912:	a1 34 36 00 40       	mov    0x40003634,%eax
40002917:	8b 55 08             	mov    0x8(%ebp),%edx
4000291a:	89 50 0c             	mov    %edx,0xc(%eax)
	files->exited = 1;
4000291d:	a1 34 36 00 40       	mov    0x40003634,%eax
40002922:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
40002929:	b8 03 00 00 00       	mov    $0x3,%eax
4000292e:	cd 30                	int    $0x30
	sys_ret();
	panic("exit: sys_ret shouldn't have returned");
40002930:	c7 44 24 08 80 39 00 	movl   $0x40003980,0x8(%esp)
40002937:	40 
40002938:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
4000293f:	00 
40002940:	c7 04 24 a6 39 00 40 	movl   $0x400039a6,(%esp)
40002947:	e8 a8 d9 ff ff       	call   400002f4 <debug_panic>

4000294c <abort>:
}

void gcc_noreturn
abort(void)
{
4000294c:	55                   	push   %ebp
4000294d:	89 e5                	mov    %esp,%ebp
4000294f:	83 ec 18             	sub    $0x18,%esp
	exit(EXIT_FAILURE);
40002952:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
40002959:	e8 ae ff ff ff       	call   4000290c <exit>
4000295e:	66 90                	xchg   %ax,%ax

40002960 <creat>:
#include <inc/assert.h>
#include <inc/stdarg.h>

int
creat(const char *path, mode_t mode)
{
40002960:	55                   	push   %ebp
40002961:	89 e5                	mov    %esp,%ebp
40002963:	83 ec 18             	sub    $0x18,%esp
	return open(path, O_CREAT | O_TRUNC | O_WRONLY, mode);
40002966:	8b 45 0c             	mov    0xc(%ebp),%eax
40002969:	89 44 24 08          	mov    %eax,0x8(%esp)
4000296d:	c7 44 24 04 62 00 00 	movl   $0x62,0x4(%esp)
40002974:	00 
40002975:	8b 45 08             	mov    0x8(%ebp),%eax
40002978:	89 04 24             	mov    %eax,(%esp)
4000297b:	e8 02 00 00 00       	call   40002982 <open>
}
40002980:	c9                   	leave  
40002981:	c3                   	ret    

40002982 <open>:

int
open(const char *path, int flags, ...)
{
40002982:	55                   	push   %ebp
40002983:	89 e5                	mov    %esp,%ebp
40002985:	83 ec 28             	sub    $0x28,%esp
	// Get the optional mode argument, which applies only with O_CREAT.
	mode_t mode = 0;
40002988:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	if (flags & O_CREAT) {
4000298f:	8b 45 0c             	mov    0xc(%ebp),%eax
40002992:	83 e0 20             	and    $0x20,%eax
40002995:	85 c0                	test   %eax,%eax
40002997:	74 18                	je     400029b1 <open+0x2f>
		va_list ap;
		va_start(ap, flags);
40002999:	8d 45 0c             	lea    0xc(%ebp),%eax
4000299c:	83 c0 04             	add    $0x4,%eax
4000299f:	89 45 f0             	mov    %eax,-0x10(%ebp)
		mode = va_arg(ap, mode_t);
400029a2:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
400029a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
400029a9:	83 e8 04             	sub    $0x4,%eax
400029ac:	8b 00                	mov    (%eax),%eax
400029ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
		va_end(ap);
	}

	filedesc *fd = filedesc_open(NULL, path, flags, mode);
400029b1:	8b 45 0c             	mov    0xc(%ebp),%eax
400029b4:	8b 55 f4             	mov    -0xc(%ebp),%edx
400029b7:	89 54 24 0c          	mov    %edx,0xc(%esp)
400029bb:	89 44 24 08          	mov    %eax,0x8(%esp)
400029bf:	8b 45 08             	mov    0x8(%ebp),%eax
400029c2:	89 44 24 04          	mov    %eax,0x4(%esp)
400029c6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400029cd:	e8 ed f0 ff ff       	call   40001abf <filedesc_open>
400029d2:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (fd == NULL)
400029d5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
400029d9:	75 07                	jne    400029e2 <open+0x60>
		return -1;
400029db:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400029e0:	eb 14                	jmp    400029f6 <open+0x74>

	return fd - files->fd;
400029e2:	8b 55 ec             	mov    -0x14(%ebp),%edx
400029e5:	a1 34 36 00 40       	mov    0x40003634,%eax
400029ea:	83 c0 10             	add    $0x10,%eax
400029ed:	89 d1                	mov    %edx,%ecx
400029ef:	29 c1                	sub    %eax,%ecx
400029f1:	89 c8                	mov    %ecx,%eax
400029f3:	c1 f8 04             	sar    $0x4,%eax
}
400029f6:	c9                   	leave  
400029f7:	c3                   	ret    

400029f8 <close>:

int
close(int fn)
{
400029f8:	55                   	push   %ebp
400029f9:	89 e5                	mov    %esp,%ebp
400029fb:	83 ec 18             	sub    $0x18,%esp
	filedesc_close(&files->fd[fn]);
400029fe:	a1 34 36 00 40       	mov    0x40003634,%eax
40002a03:	8b 55 08             	mov    0x8(%ebp),%edx
40002a06:	83 c2 01             	add    $0x1,%edx
40002a09:	c1 e2 04             	shl    $0x4,%edx
40002a0c:	01 d0                	add    %edx,%eax
40002a0e:	89 04 24             	mov    %eax,(%esp)
40002a11:	e8 6e f6 ff ff       	call   40002084 <filedesc_close>
	return 0;
40002a16:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002a1b:	c9                   	leave  
40002a1c:	c3                   	ret    

40002a1d <read>:

ssize_t
read(int fn, void *buf, size_t nbytes)
{
40002a1d:	55                   	push   %ebp
40002a1e:	89 e5                	mov    %esp,%ebp
40002a20:	83 ec 18             	sub    $0x18,%esp
	return filedesc_read(&files->fd[fn], buf, 1, nbytes);
40002a23:	a1 34 36 00 40       	mov    0x40003634,%eax
40002a28:	8b 55 08             	mov    0x8(%ebp),%edx
40002a2b:	83 c2 01             	add    $0x1,%edx
40002a2e:	c1 e2 04             	shl    $0x4,%edx
40002a31:	01 c2                	add    %eax,%edx
40002a33:	8b 45 10             	mov    0x10(%ebp),%eax
40002a36:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002a3a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40002a41:	00 
40002a42:	8b 45 0c             	mov    0xc(%ebp),%eax
40002a45:	89 44 24 04          	mov    %eax,0x4(%esp)
40002a49:	89 14 24             	mov    %edx,(%esp)
40002a4c:	e8 98 f2 ff ff       	call   40001ce9 <filedesc_read>
}
40002a51:	c9                   	leave  
40002a52:	c3                   	ret    

40002a53 <write>:

ssize_t
write(int fn, const void *buf, size_t nbytes)
{
40002a53:	55                   	push   %ebp
40002a54:	89 e5                	mov    %esp,%ebp
40002a56:	83 ec 18             	sub    $0x18,%esp
	return filedesc_write(&files->fd[fn], buf, 1, nbytes);
40002a59:	a1 34 36 00 40       	mov    0x40003634,%eax
40002a5e:	8b 55 08             	mov    0x8(%ebp),%edx
40002a61:	83 c2 01             	add    $0x1,%edx
40002a64:	c1 e2 04             	shl    $0x4,%edx
40002a67:	01 c2                	add    %eax,%edx
40002a69:	8b 45 10             	mov    0x10(%ebp),%eax
40002a6c:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002a70:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40002a77:	00 
40002a78:	8b 45 0c             	mov    0xc(%ebp),%eax
40002a7b:	89 44 24 04          	mov    %eax,0x4(%esp)
40002a7f:	89 14 24             	mov    %edx,(%esp)
40002a82:	e8 77 f3 ff ff       	call   40001dfe <filedesc_write>
}
40002a87:	c9                   	leave  
40002a88:	c3                   	ret    

40002a89 <lseek>:

off_t
lseek(int fn, off_t offset, int whence)
{
40002a89:	55                   	push   %ebp
40002a8a:	89 e5                	mov    %esp,%ebp
40002a8c:	83 ec 18             	sub    $0x18,%esp
	return filedesc_seek(&files->fd[fn], offset, whence);
40002a8f:	a1 34 36 00 40       	mov    0x40003634,%eax
40002a94:	8b 55 08             	mov    0x8(%ebp),%edx
40002a97:	83 c2 01             	add    $0x1,%edx
40002a9a:	c1 e2 04             	shl    $0x4,%edx
40002a9d:	01 c2                	add    %eax,%edx
40002a9f:	8b 45 10             	mov    0x10(%ebp),%eax
40002aa2:	89 44 24 08          	mov    %eax,0x8(%esp)
40002aa6:	8b 45 0c             	mov    0xc(%ebp),%eax
40002aa9:	89 44 24 04          	mov    %eax,0x4(%esp)
40002aad:	89 14 24             	mov    %edx,(%esp)
40002ab0:	e8 be f4 ff ff       	call   40001f73 <filedesc_seek>
}
40002ab5:	c9                   	leave  
40002ab6:	c3                   	ret    

40002ab7 <dup>:

int
dup(int oldfn)
{
40002ab7:	55                   	push   %ebp
40002ab8:	89 e5                	mov    %esp,%ebp
40002aba:	83 ec 28             	sub    $0x28,%esp
	filedesc *newfd = filedesc_alloc();
40002abd:	e8 a7 ef ff ff       	call   40001a69 <filedesc_alloc>
40002ac2:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (!newfd)
40002ac5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002ac9:	75 07                	jne    40002ad2 <dup+0x1b>
		return -1;
40002acb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002ad0:	eb 23                	jmp    40002af5 <dup+0x3e>
	return dup2(oldfn, newfd - files->fd);
40002ad2:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002ad5:	a1 34 36 00 40       	mov    0x40003634,%eax
40002ada:	83 c0 10             	add    $0x10,%eax
40002add:	89 d1                	mov    %edx,%ecx
40002adf:	29 c1                	sub    %eax,%ecx
40002ae1:	89 c8                	mov    %ecx,%eax
40002ae3:	c1 f8 04             	sar    $0x4,%eax
40002ae6:	89 44 24 04          	mov    %eax,0x4(%esp)
40002aea:	8b 45 08             	mov    0x8(%ebp),%eax
40002aed:	89 04 24             	mov    %eax,(%esp)
40002af0:	e8 02 00 00 00       	call   40002af7 <dup2>
}
40002af5:	c9                   	leave  
40002af6:	c3                   	ret    

40002af7 <dup2>:

int
dup2(int oldfn, int newfn)
{
40002af7:	55                   	push   %ebp
40002af8:	89 e5                	mov    %esp,%ebp
40002afa:	83 ec 28             	sub    $0x28,%esp
	filedesc *oldfd = &files->fd[oldfn];
40002afd:	a1 34 36 00 40       	mov    0x40003634,%eax
40002b02:	8b 55 08             	mov    0x8(%ebp),%edx
40002b05:	83 c2 01             	add    $0x1,%edx
40002b08:	c1 e2 04             	shl    $0x4,%edx
40002b0b:	01 d0                	add    %edx,%eax
40002b0d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	filedesc *newfd = &files->fd[newfn];
40002b10:	a1 34 36 00 40       	mov    0x40003634,%eax
40002b15:	8b 55 0c             	mov    0xc(%ebp),%edx
40002b18:	83 c2 01             	add    $0x1,%edx
40002b1b:	c1 e2 04             	shl    $0x4,%edx
40002b1e:	01 d0                	add    %edx,%eax
40002b20:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(filedesc_isopen(oldfd));
40002b23:	a1 34 36 00 40       	mov    0x40003634,%eax
40002b28:	83 c0 10             	add    $0x10,%eax
40002b2b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40002b2e:	77 18                	ja     40002b48 <dup2+0x51>
40002b30:	a1 34 36 00 40       	mov    0x40003634,%eax
40002b35:	05 10 10 00 00       	add    $0x1010,%eax
40002b3a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40002b3d:	76 09                	jbe    40002b48 <dup2+0x51>
40002b3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002b42:	8b 00                	mov    (%eax),%eax
40002b44:	85 c0                	test   %eax,%eax
40002b46:	75 24                	jne    40002b6c <dup2+0x75>
40002b48:	c7 44 24 0c b4 39 00 	movl   $0x400039b4,0xc(%esp)
40002b4f:	40 
40002b50:	c7 44 24 08 cb 39 00 	movl   $0x400039cb,0x8(%esp)
40002b57:	40 
40002b58:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
40002b5f:	00 
40002b60:	c7 04 24 e0 39 00 40 	movl   $0x400039e0,(%esp)
40002b67:	e8 88 d7 ff ff       	call   400002f4 <debug_panic>
	assert(filedesc_isvalid(newfd));
40002b6c:	a1 34 36 00 40       	mov    0x40003634,%eax
40002b71:	83 c0 10             	add    $0x10,%eax
40002b74:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40002b77:	77 0f                	ja     40002b88 <dup2+0x91>
40002b79:	a1 34 36 00 40       	mov    0x40003634,%eax
40002b7e:	05 10 10 00 00       	add    $0x1010,%eax
40002b83:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40002b86:	77 24                	ja     40002bac <dup2+0xb5>
40002b88:	c7 44 24 0c ed 39 00 	movl   $0x400039ed,0xc(%esp)
40002b8f:	40 
40002b90:	c7 44 24 08 cb 39 00 	movl   $0x400039cb,0x8(%esp)
40002b97:	40 
40002b98:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
40002b9f:	00 
40002ba0:	c7 04 24 e0 39 00 40 	movl   $0x400039e0,(%esp)
40002ba7:	e8 48 d7 ff ff       	call   400002f4 <debug_panic>

	if (filedesc_isopen(newfd))
40002bac:	a1 34 36 00 40       	mov    0x40003634,%eax
40002bb1:	83 c0 10             	add    $0x10,%eax
40002bb4:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40002bb7:	77 23                	ja     40002bdc <dup2+0xe5>
40002bb9:	a1 34 36 00 40       	mov    0x40003634,%eax
40002bbe:	05 10 10 00 00       	add    $0x1010,%eax
40002bc3:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40002bc6:	76 14                	jbe    40002bdc <dup2+0xe5>
40002bc8:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002bcb:	8b 00                	mov    (%eax),%eax
40002bcd:	85 c0                	test   %eax,%eax
40002bcf:	74 0b                	je     40002bdc <dup2+0xe5>
		close(newfn);
40002bd1:	8b 45 0c             	mov    0xc(%ebp),%eax
40002bd4:	89 04 24             	mov    %eax,(%esp)
40002bd7:	e8 1c fe ff ff       	call   400029f8 <close>

	*newfd = *oldfd;
40002bdc:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002bdf:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002be2:	8b 0a                	mov    (%edx),%ecx
40002be4:	89 08                	mov    %ecx,(%eax)
40002be6:	8b 4a 04             	mov    0x4(%edx),%ecx
40002be9:	89 48 04             	mov    %ecx,0x4(%eax)
40002bec:	8b 4a 08             	mov    0x8(%edx),%ecx
40002bef:	89 48 08             	mov    %ecx,0x8(%eax)
40002bf2:	8b 52 0c             	mov    0xc(%edx),%edx
40002bf5:	89 50 0c             	mov    %edx,0xc(%eax)

	return newfn;
40002bf8:	8b 45 0c             	mov    0xc(%ebp),%eax
}
40002bfb:	c9                   	leave  
40002bfc:	c3                   	ret    

40002bfd <truncate>:

int
truncate(const char *path, off_t newlength)
{
40002bfd:	55                   	push   %ebp
40002bfe:	89 e5                	mov    %esp,%ebp
40002c00:	83 ec 28             	sub    $0x28,%esp
	int ino = dir_walk(path, 0);
40002c03:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002c0a:	00 
40002c0b:	8b 45 08             	mov    0x8(%ebp),%eax
40002c0e:	89 04 24             	mov    %eax,(%esp)
40002c11:	e8 02 f5 ff ff       	call   40002118 <dir_walk>
40002c16:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (ino < 0)
40002c19:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002c1d:	79 07                	jns    40002c26 <truncate+0x29>
		return -1;
40002c1f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002c24:	eb 12                	jmp    40002c38 <truncate+0x3b>
	return fileino_truncate(ino, newlength);
40002c26:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c29:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002c30:	89 04 24             	mov    %eax,(%esp)
40002c33:	e8 3a eb ff ff       	call   40001772 <fileino_truncate>
}
40002c38:	c9                   	leave  
40002c39:	c3                   	ret    

40002c3a <ftruncate>:

int
ftruncate(int fn, off_t newlength)
{
40002c3a:	55                   	push   %ebp
40002c3b:	89 e5                	mov    %esp,%ebp
40002c3d:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
40002c40:	a1 34 36 00 40       	mov    0x40003634,%eax
40002c45:	8b 55 08             	mov    0x8(%ebp),%edx
40002c48:	83 c2 01             	add    $0x1,%edx
40002c4b:	c1 e2 04             	shl    $0x4,%edx
40002c4e:	01 c2                	add    %eax,%edx
40002c50:	a1 34 36 00 40       	mov    0x40003634,%eax
40002c55:	83 c0 10             	add    $0x10,%eax
40002c58:	39 c2                	cmp    %eax,%edx
40002c5a:	72 34                	jb     40002c90 <ftruncate+0x56>
40002c5c:	a1 34 36 00 40       	mov    0x40003634,%eax
40002c61:	8b 55 08             	mov    0x8(%ebp),%edx
40002c64:	83 c2 01             	add    $0x1,%edx
40002c67:	c1 e2 04             	shl    $0x4,%edx
40002c6a:	01 c2                	add    %eax,%edx
40002c6c:	a1 34 36 00 40       	mov    0x40003634,%eax
40002c71:	05 10 10 00 00       	add    $0x1010,%eax
40002c76:	39 c2                	cmp    %eax,%edx
40002c78:	73 16                	jae    40002c90 <ftruncate+0x56>
40002c7a:	a1 34 36 00 40       	mov    0x40003634,%eax
40002c7f:	8b 55 08             	mov    0x8(%ebp),%edx
40002c82:	83 c2 01             	add    $0x1,%edx
40002c85:	c1 e2 04             	shl    $0x4,%edx
40002c88:	01 d0                	add    %edx,%eax
40002c8a:	8b 00                	mov    (%eax),%eax
40002c8c:	85 c0                	test   %eax,%eax
40002c8e:	75 24                	jne    40002cb4 <ftruncate+0x7a>
40002c90:	c7 44 24 0c 08 3a 00 	movl   $0x40003a08,0xc(%esp)
40002c97:	40 
40002c98:	c7 44 24 08 cb 39 00 	movl   $0x400039cb,0x8(%esp)
40002c9f:	40 
40002ca0:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
40002ca7:	00 
40002ca8:	c7 04 24 e0 39 00 40 	movl   $0x400039e0,(%esp)
40002caf:	e8 40 d6 ff ff       	call   400002f4 <debug_panic>
	return fileino_truncate(files->fd[fn].ino, newlength);
40002cb4:	a1 34 36 00 40       	mov    0x40003634,%eax
40002cb9:	8b 55 08             	mov    0x8(%ebp),%edx
40002cbc:	83 c2 01             	add    $0x1,%edx
40002cbf:	c1 e2 04             	shl    $0x4,%edx
40002cc2:	01 d0                	add    %edx,%eax
40002cc4:	8b 00                	mov    (%eax),%eax
40002cc6:	8b 55 0c             	mov    0xc(%ebp),%edx
40002cc9:	89 54 24 04          	mov    %edx,0x4(%esp)
40002ccd:	89 04 24             	mov    %eax,(%esp)
40002cd0:	e8 9d ea ff ff       	call   40001772 <fileino_truncate>
}
40002cd5:	c9                   	leave  
40002cd6:	c3                   	ret    

40002cd7 <isatty>:

int
isatty(int fn)
{
40002cd7:	55                   	push   %ebp
40002cd8:	89 e5                	mov    %esp,%ebp
40002cda:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
40002cdd:	a1 34 36 00 40       	mov    0x40003634,%eax
40002ce2:	8b 55 08             	mov    0x8(%ebp),%edx
40002ce5:	83 c2 01             	add    $0x1,%edx
40002ce8:	c1 e2 04             	shl    $0x4,%edx
40002ceb:	01 c2                	add    %eax,%edx
40002ced:	a1 34 36 00 40       	mov    0x40003634,%eax
40002cf2:	83 c0 10             	add    $0x10,%eax
40002cf5:	39 c2                	cmp    %eax,%edx
40002cf7:	72 34                	jb     40002d2d <isatty+0x56>
40002cf9:	a1 34 36 00 40       	mov    0x40003634,%eax
40002cfe:	8b 55 08             	mov    0x8(%ebp),%edx
40002d01:	83 c2 01             	add    $0x1,%edx
40002d04:	c1 e2 04             	shl    $0x4,%edx
40002d07:	01 c2                	add    %eax,%edx
40002d09:	a1 34 36 00 40       	mov    0x40003634,%eax
40002d0e:	05 10 10 00 00       	add    $0x1010,%eax
40002d13:	39 c2                	cmp    %eax,%edx
40002d15:	73 16                	jae    40002d2d <isatty+0x56>
40002d17:	a1 34 36 00 40       	mov    0x40003634,%eax
40002d1c:	8b 55 08             	mov    0x8(%ebp),%edx
40002d1f:	83 c2 01             	add    $0x1,%edx
40002d22:	c1 e2 04             	shl    $0x4,%edx
40002d25:	01 d0                	add    %edx,%eax
40002d27:	8b 00                	mov    (%eax),%eax
40002d29:	85 c0                	test   %eax,%eax
40002d2b:	75 24                	jne    40002d51 <isatty+0x7a>
40002d2d:	c7 44 24 0c 08 3a 00 	movl   $0x40003a08,0xc(%esp)
40002d34:	40 
40002d35:	c7 44 24 08 cb 39 00 	movl   $0x400039cb,0x8(%esp)
40002d3c:	40 
40002d3d:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
40002d44:	00 
40002d45:	c7 04 24 e0 39 00 40 	movl   $0x400039e0,(%esp)
40002d4c:	e8 a3 d5 ff ff       	call   400002f4 <debug_panic>
	return files->fd[fn].ino == FILEINO_CONSIN
40002d51:	a1 34 36 00 40       	mov    0x40003634,%eax
40002d56:	8b 55 08             	mov    0x8(%ebp),%edx
40002d59:	83 c2 01             	add    $0x1,%edx
40002d5c:	c1 e2 04             	shl    $0x4,%edx
40002d5f:	01 d0                	add    %edx,%eax
40002d61:	8b 00                	mov    (%eax),%eax
		|| files->fd[fn].ino == FILEINO_CONSOUT;
40002d63:	83 f8 01             	cmp    $0x1,%eax
40002d66:	74 17                	je     40002d7f <isatty+0xa8>
40002d68:	a1 34 36 00 40       	mov    0x40003634,%eax
40002d6d:	8b 55 08             	mov    0x8(%ebp),%edx
40002d70:	83 c2 01             	add    $0x1,%edx
40002d73:	c1 e2 04             	shl    $0x4,%edx
40002d76:	01 d0                	add    %edx,%eax
40002d78:	8b 00                	mov    (%eax),%eax
40002d7a:	83 f8 02             	cmp    $0x2,%eax
40002d7d:	75 07                	jne    40002d86 <isatty+0xaf>
40002d7f:	b8 01 00 00 00       	mov    $0x1,%eax
40002d84:	eb 05                	jmp    40002d8b <isatty+0xb4>
40002d86:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002d8b:	c9                   	leave  
40002d8c:	c3                   	ret    

40002d8d <stat>:

int
stat(const char *path, struct stat *statbuf)
{
40002d8d:	55                   	push   %ebp
40002d8e:	89 e5                	mov    %esp,%ebp
40002d90:	83 ec 28             	sub    $0x28,%esp
	int ino = dir_walk(path, 0);
40002d93:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002d9a:	00 
40002d9b:	8b 45 08             	mov    0x8(%ebp),%eax
40002d9e:	89 04 24             	mov    %eax,(%esp)
40002da1:	e8 72 f3 ff ff       	call   40002118 <dir_walk>
40002da6:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (ino < 0)
40002da9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002dad:	79 07                	jns    40002db6 <stat+0x29>
		return -1;
40002daf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002db4:	eb 12                	jmp    40002dc8 <stat+0x3b>
	return fileino_stat(ino, statbuf);
40002db6:	8b 45 0c             	mov    0xc(%ebp),%eax
40002db9:	89 44 24 04          	mov    %eax,0x4(%esp)
40002dbd:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002dc0:	89 04 24             	mov    %eax,(%esp)
40002dc3:	e8 85 e8 ff ff       	call   4000164d <fileino_stat>
}
40002dc8:	c9                   	leave  
40002dc9:	c3                   	ret    

40002dca <fstat>:

int
fstat(int fn, struct stat *statbuf)
{
40002dca:	55                   	push   %ebp
40002dcb:	89 e5                	mov    %esp,%ebp
40002dcd:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
40002dd0:	a1 34 36 00 40       	mov    0x40003634,%eax
40002dd5:	8b 55 08             	mov    0x8(%ebp),%edx
40002dd8:	83 c2 01             	add    $0x1,%edx
40002ddb:	c1 e2 04             	shl    $0x4,%edx
40002dde:	01 c2                	add    %eax,%edx
40002de0:	a1 34 36 00 40       	mov    0x40003634,%eax
40002de5:	83 c0 10             	add    $0x10,%eax
40002de8:	39 c2                	cmp    %eax,%edx
40002dea:	72 34                	jb     40002e20 <fstat+0x56>
40002dec:	a1 34 36 00 40       	mov    0x40003634,%eax
40002df1:	8b 55 08             	mov    0x8(%ebp),%edx
40002df4:	83 c2 01             	add    $0x1,%edx
40002df7:	c1 e2 04             	shl    $0x4,%edx
40002dfa:	01 c2                	add    %eax,%edx
40002dfc:	a1 34 36 00 40       	mov    0x40003634,%eax
40002e01:	05 10 10 00 00       	add    $0x1010,%eax
40002e06:	39 c2                	cmp    %eax,%edx
40002e08:	73 16                	jae    40002e20 <fstat+0x56>
40002e0a:	a1 34 36 00 40       	mov    0x40003634,%eax
40002e0f:	8b 55 08             	mov    0x8(%ebp),%edx
40002e12:	83 c2 01             	add    $0x1,%edx
40002e15:	c1 e2 04             	shl    $0x4,%edx
40002e18:	01 d0                	add    %edx,%eax
40002e1a:	8b 00                	mov    (%eax),%eax
40002e1c:	85 c0                	test   %eax,%eax
40002e1e:	75 24                	jne    40002e44 <fstat+0x7a>
40002e20:	c7 44 24 0c 08 3a 00 	movl   $0x40003a08,0xc(%esp)
40002e27:	40 
40002e28:	c7 44 24 08 cb 39 00 	movl   $0x400039cb,0x8(%esp)
40002e2f:	40 
40002e30:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
40002e37:	00 
40002e38:	c7 04 24 e0 39 00 40 	movl   $0x400039e0,(%esp)
40002e3f:	e8 b0 d4 ff ff       	call   400002f4 <debug_panic>
	return fileino_stat(files->fd[fn].ino, statbuf);
40002e44:	a1 34 36 00 40       	mov    0x40003634,%eax
40002e49:	8b 55 08             	mov    0x8(%ebp),%edx
40002e4c:	83 c2 01             	add    $0x1,%edx
40002e4f:	c1 e2 04             	shl    $0x4,%edx
40002e52:	01 d0                	add    %edx,%eax
40002e54:	8b 00                	mov    (%eax),%eax
40002e56:	8b 55 0c             	mov    0xc(%ebp),%edx
40002e59:	89 54 24 04          	mov    %edx,0x4(%esp)
40002e5d:	89 04 24             	mov    %eax,(%esp)
40002e60:	e8 e8 e7 ff ff       	call   4000164d <fileino_stat>
}
40002e65:	c9                   	leave  
40002e66:	c3                   	ret    

40002e67 <fsync>:

int
fsync(int fn)
{
40002e67:	55                   	push   %ebp
40002e68:	89 e5                	mov    %esp,%ebp
40002e6a:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
40002e6d:	a1 34 36 00 40       	mov    0x40003634,%eax
40002e72:	8b 55 08             	mov    0x8(%ebp),%edx
40002e75:	83 c2 01             	add    $0x1,%edx
40002e78:	c1 e2 04             	shl    $0x4,%edx
40002e7b:	01 c2                	add    %eax,%edx
40002e7d:	a1 34 36 00 40       	mov    0x40003634,%eax
40002e82:	83 c0 10             	add    $0x10,%eax
40002e85:	39 c2                	cmp    %eax,%edx
40002e87:	72 34                	jb     40002ebd <fsync+0x56>
40002e89:	a1 34 36 00 40       	mov    0x40003634,%eax
40002e8e:	8b 55 08             	mov    0x8(%ebp),%edx
40002e91:	83 c2 01             	add    $0x1,%edx
40002e94:	c1 e2 04             	shl    $0x4,%edx
40002e97:	01 c2                	add    %eax,%edx
40002e99:	a1 34 36 00 40       	mov    0x40003634,%eax
40002e9e:	05 10 10 00 00       	add    $0x1010,%eax
40002ea3:	39 c2                	cmp    %eax,%edx
40002ea5:	73 16                	jae    40002ebd <fsync+0x56>
40002ea7:	a1 34 36 00 40       	mov    0x40003634,%eax
40002eac:	8b 55 08             	mov    0x8(%ebp),%edx
40002eaf:	83 c2 01             	add    $0x1,%edx
40002eb2:	c1 e2 04             	shl    $0x4,%edx
40002eb5:	01 d0                	add    %edx,%eax
40002eb7:	8b 00                	mov    (%eax),%eax
40002eb9:	85 c0                	test   %eax,%eax
40002ebb:	75 24                	jne    40002ee1 <fsync+0x7a>
40002ebd:	c7 44 24 0c 08 3a 00 	movl   $0x40003a08,0xc(%esp)
40002ec4:	40 
40002ec5:	c7 44 24 08 cb 39 00 	movl   $0x400039cb,0x8(%esp)
40002ecc:	40 
40002ecd:	c7 44 24 04 87 00 00 	movl   $0x87,0x4(%esp)
40002ed4:	00 
40002ed5:	c7 04 24 e0 39 00 40 	movl   $0x400039e0,(%esp)
40002edc:	e8 13 d4 ff ff       	call   400002f4 <debug_panic>
	return fileino_flush(files->fd[fn].ino);
40002ee1:	a1 34 36 00 40       	mov    0x40003634,%eax
40002ee6:	8b 55 08             	mov    0x8(%ebp),%edx
40002ee9:	83 c2 01             	add    $0x1,%edx
40002eec:	c1 e2 04             	shl    $0x4,%edx
40002eef:	01 d0                	add    %edx,%eax
40002ef1:	8b 00                	mov    (%eax),%eax
40002ef3:	89 04 24             	mov    %eax,(%esp)
40002ef6:	e8 f9 ea ff ff       	call   400019f4 <fileino_flush>
}
40002efb:	c9                   	leave  
40002efc:	c3                   	ret    
40002efd:	66 90                	xchg   %ax,%ax
40002eff:	90                   	nop

40002f00 <strerror>:
#include <inc/stdio.h>

char *
strerror(int err)
{
40002f00:	55                   	push   %ebp
40002f01:	89 e5                	mov    %esp,%ebp
40002f03:	83 ec 28             	sub    $0x28,%esp
		"No child processes",
		"Conflict detected",
	};
	static char errbuf[64];

	const int tablen = sizeof(errtab)/sizeof(errtab[0]);
40002f06:	c7 45 f4 0b 00 00 00 	movl   $0xb,-0xc(%ebp)
	if (err >= 0 && err < sizeof(errtab)/sizeof(errtab[0]))
40002f0d:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40002f11:	78 14                	js     40002f27 <strerror+0x27>
40002f13:	8b 45 08             	mov    0x8(%ebp),%eax
40002f16:	83 f8 0a             	cmp    $0xa,%eax
40002f19:	77 0c                	ja     40002f27 <strerror+0x27>
		return errtab[err];
40002f1b:	8b 45 08             	mov    0x8(%ebp),%eax
40002f1e:	8b 04 85 00 55 00 40 	mov    0x40005500(,%eax,4),%eax
40002f25:	eb 20                	jmp    40002f47 <strerror+0x47>

	sprintf(errbuf, "Unknown error code %d", err);
40002f27:	8b 45 08             	mov    0x8(%ebp),%eax
40002f2a:	89 44 24 08          	mov    %eax,0x8(%esp)
40002f2e:	c7 44 24 04 28 3a 00 	movl   $0x40003a28,0x4(%esp)
40002f35:	40 
40002f36:	c7 04 24 40 55 00 40 	movl   $0x40005540,(%esp)
40002f3d:	e8 cf 00 00 00       	call   40003011 <sprintf>
	return errbuf;
40002f42:	b8 40 55 00 40       	mov    $0x40005540,%eax
}
40002f47:	c9                   	leave  
40002f48:	c3                   	ret    
40002f49:	66 90                	xchg   %ax,%ax
40002f4b:	90                   	nop

40002f4c <cputs>:

#include <inc/stdio.h>
#include <inc/syscall.h>

void cputs(const char *str)
{
40002f4c:	55                   	push   %ebp
40002f4d:	89 e5                	mov    %esp,%ebp
40002f4f:	53                   	push   %ebx
40002f50:	83 ec 10             	sub    $0x10,%esp
40002f53:	8b 45 08             	mov    0x8(%ebp),%eax
40002f56:	89 45 f8             	mov    %eax,-0x8(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40002f59:	b8 00 00 00 00       	mov    $0x0,%eax
40002f5e:	8b 55 f8             	mov    -0x8(%ebp),%edx
40002f61:	89 d3                	mov    %edx,%ebx
40002f63:	cd 30                	int    $0x30
	sys_cputs(str);
}
40002f65:	83 c4 10             	add    $0x10,%esp
40002f68:	5b                   	pop    %ebx
40002f69:	5d                   	pop    %ebp
40002f6a:	c3                   	ret    
40002f6b:	90                   	nop

40002f6c <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
40002f6c:	55                   	push   %ebp
40002f6d:	89 e5                	mov    %esp,%ebp
	b->cnt++;
40002f6f:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f72:	8b 40 08             	mov    0x8(%eax),%eax
40002f75:	8d 50 01             	lea    0x1(%eax),%edx
40002f78:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f7b:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
40002f7e:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f81:	8b 10                	mov    (%eax),%edx
40002f83:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f86:	8b 40 04             	mov    0x4(%eax),%eax
40002f89:	39 c2                	cmp    %eax,%edx
40002f8b:	73 12                	jae    40002f9f <sprintputch+0x33>
		*b->buf++ = ch;
40002f8d:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f90:	8b 00                	mov    (%eax),%eax
40002f92:	8b 55 08             	mov    0x8(%ebp),%edx
40002f95:	88 10                	mov    %dl,(%eax)
40002f97:	8d 50 01             	lea    0x1(%eax),%edx
40002f9a:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f9d:	89 10                	mov    %edx,(%eax)
}
40002f9f:	5d                   	pop    %ebp
40002fa0:	c3                   	ret    

40002fa1 <vsprintf>:

int
vsprintf(char *buf, const char *fmt, va_list ap)
{
40002fa1:	55                   	push   %ebp
40002fa2:	89 e5                	mov    %esp,%ebp
40002fa4:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL);
40002fa7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40002fab:	75 24                	jne    40002fd1 <vsprintf+0x30>
40002fad:	c7 44 24 0c 1a 3b 00 	movl   $0x40003b1a,0xc(%esp)
40002fb4:	40 
40002fb5:	c7 44 24 08 26 3b 00 	movl   $0x40003b26,0x8(%esp)
40002fbc:	40 
40002fbd:	c7 44 24 04 19 00 00 	movl   $0x19,0x4(%esp)
40002fc4:	00 
40002fc5:	c7 04 24 3b 3b 00 40 	movl   $0x40003b3b,(%esp)
40002fcc:	e8 23 d3 ff ff       	call   400002f4 <debug_panic>
	struct sprintbuf b = {buf, (char*)(intptr_t)~0, 0};
40002fd1:	8b 45 08             	mov    0x8(%ebp),%eax
40002fd4:	89 45 ec             	mov    %eax,-0x14(%ebp)
40002fd7:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
40002fde:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
40002fe5:	8b 45 10             	mov    0x10(%ebp),%eax
40002fe8:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002fec:	8b 45 0c             	mov    0xc(%ebp),%eax
40002fef:	89 44 24 08          	mov    %eax,0x8(%esp)
40002ff3:	8d 45 ec             	lea    -0x14(%ebp),%eax
40002ff6:	89 44 24 04          	mov    %eax,0x4(%esp)
40002ffa:	c7 04 24 6c 2f 00 40 	movl   $0x40002f6c,(%esp)
40003001:	e8 cb d8 ff ff       	call   400008d1 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
40003006:	8b 45 ec             	mov    -0x14(%ebp),%eax
40003009:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
4000300c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
4000300f:	c9                   	leave  
40003010:	c3                   	ret    

40003011 <sprintf>:

int
sprintf(char *buf, const char *fmt, ...)
{
40003011:	55                   	push   %ebp
40003012:	89 e5                	mov    %esp,%ebp
40003014:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
40003017:	8d 45 0c             	lea    0xc(%ebp),%eax
4000301a:	83 c0 04             	add    $0x4,%eax
4000301d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsprintf(buf, fmt, ap);
40003020:	8b 45 0c             	mov    0xc(%ebp),%eax
40003023:	8b 55 f4             	mov    -0xc(%ebp),%edx
40003026:	89 54 24 08          	mov    %edx,0x8(%esp)
4000302a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000302e:	8b 45 08             	mov    0x8(%ebp),%eax
40003031:	89 04 24             	mov    %eax,(%esp)
40003034:	e8 68 ff ff ff       	call   40002fa1 <vsprintf>
40003039:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
4000303c:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
4000303f:	c9                   	leave  
40003040:	c3                   	ret    

40003041 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
40003041:	55                   	push   %ebp
40003042:	89 e5                	mov    %esp,%ebp
40003044:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL && n > 0);
40003047:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
4000304b:	74 06                	je     40003053 <vsnprintf+0x12>
4000304d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40003051:	7f 24                	jg     40003077 <vsnprintf+0x36>
40003053:	c7 44 24 0c 49 3b 00 	movl   $0x40003b49,0xc(%esp)
4000305a:	40 
4000305b:	c7 44 24 08 26 3b 00 	movl   $0x40003b26,0x8(%esp)
40003062:	40 
40003063:	c7 44 24 04 35 00 00 	movl   $0x35,0x4(%esp)
4000306a:	00 
4000306b:	c7 04 24 3b 3b 00 40 	movl   $0x40003b3b,(%esp)
40003072:	e8 7d d2 ff ff       	call   400002f4 <debug_panic>
	struct sprintbuf b = {buf, buf+n-1, 0};
40003077:	8b 45 08             	mov    0x8(%ebp),%eax
4000307a:	89 45 ec             	mov    %eax,-0x14(%ebp)
4000307d:	8b 45 0c             	mov    0xc(%ebp),%eax
40003080:	8d 50 ff             	lea    -0x1(%eax),%edx
40003083:	8b 45 08             	mov    0x8(%ebp),%eax
40003086:	01 d0                	add    %edx,%eax
40003088:	89 45 f0             	mov    %eax,-0x10(%ebp)
4000308b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
40003092:	8b 45 14             	mov    0x14(%ebp),%eax
40003095:	89 44 24 0c          	mov    %eax,0xc(%esp)
40003099:	8b 45 10             	mov    0x10(%ebp),%eax
4000309c:	89 44 24 08          	mov    %eax,0x8(%esp)
400030a0:	8d 45 ec             	lea    -0x14(%ebp),%eax
400030a3:	89 44 24 04          	mov    %eax,0x4(%esp)
400030a7:	c7 04 24 6c 2f 00 40 	movl   $0x40002f6c,(%esp)
400030ae:	e8 1e d8 ff ff       	call   400008d1 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
400030b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
400030b6:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
400030b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
400030bc:	c9                   	leave  
400030bd:	c3                   	ret    

400030be <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
400030be:	55                   	push   %ebp
400030bf:	89 e5                	mov    %esp,%ebp
400030c1:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
400030c4:	8d 45 10             	lea    0x10(%ebp),%eax
400030c7:	83 c0 04             	add    $0x4,%eax
400030ca:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
400030cd:	8b 45 10             	mov    0x10(%ebp),%eax
400030d0:	8b 55 f4             	mov    -0xc(%ebp),%edx
400030d3:	89 54 24 0c          	mov    %edx,0xc(%esp)
400030d7:	89 44 24 08          	mov    %eax,0x8(%esp)
400030db:	8b 45 0c             	mov    0xc(%ebp),%eax
400030de:	89 44 24 04          	mov    %eax,0x4(%esp)
400030e2:	8b 45 08             	mov    0x8(%ebp),%eax
400030e5:	89 04 24             	mov    %eax,(%esp)
400030e8:	e8 54 ff ff ff       	call   40003041 <vsnprintf>
400030ed:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
400030f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
400030f3:	c9                   	leave  
400030f4:	c3                   	ret    
400030f5:	66 90                	xchg   %ax,%ax
400030f7:	66 90                	xchg   %ax,%ax
400030f9:	66 90                	xchg   %ax,%ax
400030fb:	66 90                	xchg   %ax,%ax
400030fd:	66 90                	xchg   %ax,%ax
400030ff:	90                   	nop

40003100 <__udivdi3>:
40003100:	83 ec 1c             	sub    $0x1c,%esp
40003103:	8b 44 24 2c          	mov    0x2c(%esp),%eax
40003107:	89 7c 24 14          	mov    %edi,0x14(%esp)
4000310b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
4000310f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
40003113:	8b 7c 24 20          	mov    0x20(%esp),%edi
40003117:	8b 6c 24 24          	mov    0x24(%esp),%ebp
4000311b:	85 c0                	test   %eax,%eax
4000311d:	89 74 24 10          	mov    %esi,0x10(%esp)
40003121:	89 7c 24 08          	mov    %edi,0x8(%esp)
40003125:	89 ea                	mov    %ebp,%edx
40003127:	89 4c 24 04          	mov    %ecx,0x4(%esp)
4000312b:	75 33                	jne    40003160 <__udivdi3+0x60>
4000312d:	39 e9                	cmp    %ebp,%ecx
4000312f:	77 6f                	ja     400031a0 <__udivdi3+0xa0>
40003131:	85 c9                	test   %ecx,%ecx
40003133:	89 ce                	mov    %ecx,%esi
40003135:	75 0b                	jne    40003142 <__udivdi3+0x42>
40003137:	b8 01 00 00 00       	mov    $0x1,%eax
4000313c:	31 d2                	xor    %edx,%edx
4000313e:	f7 f1                	div    %ecx
40003140:	89 c6                	mov    %eax,%esi
40003142:	31 d2                	xor    %edx,%edx
40003144:	89 e8                	mov    %ebp,%eax
40003146:	f7 f6                	div    %esi
40003148:	89 c5                	mov    %eax,%ebp
4000314a:	89 f8                	mov    %edi,%eax
4000314c:	f7 f6                	div    %esi
4000314e:	89 ea                	mov    %ebp,%edx
40003150:	8b 74 24 10          	mov    0x10(%esp),%esi
40003154:	8b 7c 24 14          	mov    0x14(%esp),%edi
40003158:	8b 6c 24 18          	mov    0x18(%esp),%ebp
4000315c:	83 c4 1c             	add    $0x1c,%esp
4000315f:	c3                   	ret    
40003160:	39 e8                	cmp    %ebp,%eax
40003162:	77 24                	ja     40003188 <__udivdi3+0x88>
40003164:	0f bd c8             	bsr    %eax,%ecx
40003167:	83 f1 1f             	xor    $0x1f,%ecx
4000316a:	89 0c 24             	mov    %ecx,(%esp)
4000316d:	75 49                	jne    400031b8 <__udivdi3+0xb8>
4000316f:	8b 74 24 08          	mov    0x8(%esp),%esi
40003173:	39 74 24 04          	cmp    %esi,0x4(%esp)
40003177:	0f 86 ab 00 00 00    	jbe    40003228 <__udivdi3+0x128>
4000317d:	39 e8                	cmp    %ebp,%eax
4000317f:	0f 82 a3 00 00 00    	jb     40003228 <__udivdi3+0x128>
40003185:	8d 76 00             	lea    0x0(%esi),%esi
40003188:	31 d2                	xor    %edx,%edx
4000318a:	31 c0                	xor    %eax,%eax
4000318c:	8b 74 24 10          	mov    0x10(%esp),%esi
40003190:	8b 7c 24 14          	mov    0x14(%esp),%edi
40003194:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40003198:	83 c4 1c             	add    $0x1c,%esp
4000319b:	c3                   	ret    
4000319c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
400031a0:	89 f8                	mov    %edi,%eax
400031a2:	f7 f1                	div    %ecx
400031a4:	31 d2                	xor    %edx,%edx
400031a6:	8b 74 24 10          	mov    0x10(%esp),%esi
400031aa:	8b 7c 24 14          	mov    0x14(%esp),%edi
400031ae:	8b 6c 24 18          	mov    0x18(%esp),%ebp
400031b2:	83 c4 1c             	add    $0x1c,%esp
400031b5:	c3                   	ret    
400031b6:	66 90                	xchg   %ax,%ax
400031b8:	0f b6 0c 24          	movzbl (%esp),%ecx
400031bc:	89 c6                	mov    %eax,%esi
400031be:	b8 20 00 00 00       	mov    $0x20,%eax
400031c3:	8b 6c 24 04          	mov    0x4(%esp),%ebp
400031c7:	2b 04 24             	sub    (%esp),%eax
400031ca:	8b 7c 24 08          	mov    0x8(%esp),%edi
400031ce:	d3 e6                	shl    %cl,%esi
400031d0:	89 c1                	mov    %eax,%ecx
400031d2:	d3 ed                	shr    %cl,%ebp
400031d4:	0f b6 0c 24          	movzbl (%esp),%ecx
400031d8:	09 f5                	or     %esi,%ebp
400031da:	8b 74 24 04          	mov    0x4(%esp),%esi
400031de:	d3 e6                	shl    %cl,%esi
400031e0:	89 c1                	mov    %eax,%ecx
400031e2:	89 74 24 04          	mov    %esi,0x4(%esp)
400031e6:	89 d6                	mov    %edx,%esi
400031e8:	d3 ee                	shr    %cl,%esi
400031ea:	0f b6 0c 24          	movzbl (%esp),%ecx
400031ee:	d3 e2                	shl    %cl,%edx
400031f0:	89 c1                	mov    %eax,%ecx
400031f2:	d3 ef                	shr    %cl,%edi
400031f4:	09 d7                	or     %edx,%edi
400031f6:	89 f2                	mov    %esi,%edx
400031f8:	89 f8                	mov    %edi,%eax
400031fa:	f7 f5                	div    %ebp
400031fc:	89 d6                	mov    %edx,%esi
400031fe:	89 c7                	mov    %eax,%edi
40003200:	f7 64 24 04          	mull   0x4(%esp)
40003204:	39 d6                	cmp    %edx,%esi
40003206:	72 30                	jb     40003238 <__udivdi3+0x138>
40003208:	8b 6c 24 08          	mov    0x8(%esp),%ebp
4000320c:	0f b6 0c 24          	movzbl (%esp),%ecx
40003210:	d3 e5                	shl    %cl,%ebp
40003212:	39 c5                	cmp    %eax,%ebp
40003214:	73 04                	jae    4000321a <__udivdi3+0x11a>
40003216:	39 d6                	cmp    %edx,%esi
40003218:	74 1e                	je     40003238 <__udivdi3+0x138>
4000321a:	89 f8                	mov    %edi,%eax
4000321c:	31 d2                	xor    %edx,%edx
4000321e:	e9 69 ff ff ff       	jmp    4000318c <__udivdi3+0x8c>
40003223:	90                   	nop
40003224:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003228:	31 d2                	xor    %edx,%edx
4000322a:	b8 01 00 00 00       	mov    $0x1,%eax
4000322f:	e9 58 ff ff ff       	jmp    4000318c <__udivdi3+0x8c>
40003234:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003238:	8d 47 ff             	lea    -0x1(%edi),%eax
4000323b:	31 d2                	xor    %edx,%edx
4000323d:	8b 74 24 10          	mov    0x10(%esp),%esi
40003241:	8b 7c 24 14          	mov    0x14(%esp),%edi
40003245:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40003249:	83 c4 1c             	add    $0x1c,%esp
4000324c:	c3                   	ret    
4000324d:	66 90                	xchg   %ax,%ax
4000324f:	90                   	nop

40003250 <__umoddi3>:
40003250:	83 ec 2c             	sub    $0x2c,%esp
40003253:	8b 44 24 3c          	mov    0x3c(%esp),%eax
40003257:	8b 4c 24 30          	mov    0x30(%esp),%ecx
4000325b:	89 74 24 20          	mov    %esi,0x20(%esp)
4000325f:	8b 74 24 38          	mov    0x38(%esp),%esi
40003263:	89 7c 24 24          	mov    %edi,0x24(%esp)
40003267:	8b 7c 24 34          	mov    0x34(%esp),%edi
4000326b:	85 c0                	test   %eax,%eax
4000326d:	89 c2                	mov    %eax,%edx
4000326f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
40003273:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
40003277:	89 7c 24 0c          	mov    %edi,0xc(%esp)
4000327b:	89 74 24 10          	mov    %esi,0x10(%esp)
4000327f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
40003283:	89 7c 24 18          	mov    %edi,0x18(%esp)
40003287:	75 1f                	jne    400032a8 <__umoddi3+0x58>
40003289:	39 fe                	cmp    %edi,%esi
4000328b:	76 63                	jbe    400032f0 <__umoddi3+0xa0>
4000328d:	89 c8                	mov    %ecx,%eax
4000328f:	89 fa                	mov    %edi,%edx
40003291:	f7 f6                	div    %esi
40003293:	89 d0                	mov    %edx,%eax
40003295:	31 d2                	xor    %edx,%edx
40003297:	8b 74 24 20          	mov    0x20(%esp),%esi
4000329b:	8b 7c 24 24          	mov    0x24(%esp),%edi
4000329f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
400032a3:	83 c4 2c             	add    $0x2c,%esp
400032a6:	c3                   	ret    
400032a7:	90                   	nop
400032a8:	39 f8                	cmp    %edi,%eax
400032aa:	77 64                	ja     40003310 <__umoddi3+0xc0>
400032ac:	0f bd e8             	bsr    %eax,%ebp
400032af:	83 f5 1f             	xor    $0x1f,%ebp
400032b2:	75 74                	jne    40003328 <__umoddi3+0xd8>
400032b4:	8b 7c 24 14          	mov    0x14(%esp),%edi
400032b8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
400032bc:	0f 87 0e 01 00 00    	ja     400033d0 <__umoddi3+0x180>
400032c2:	8b 7c 24 0c          	mov    0xc(%esp),%edi
400032c6:	29 f1                	sub    %esi,%ecx
400032c8:	19 c7                	sbb    %eax,%edi
400032ca:	89 4c 24 14          	mov    %ecx,0x14(%esp)
400032ce:	89 7c 24 18          	mov    %edi,0x18(%esp)
400032d2:	8b 44 24 14          	mov    0x14(%esp),%eax
400032d6:	8b 54 24 18          	mov    0x18(%esp),%edx
400032da:	8b 74 24 20          	mov    0x20(%esp),%esi
400032de:	8b 7c 24 24          	mov    0x24(%esp),%edi
400032e2:	8b 6c 24 28          	mov    0x28(%esp),%ebp
400032e6:	83 c4 2c             	add    $0x2c,%esp
400032e9:	c3                   	ret    
400032ea:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
400032f0:	85 f6                	test   %esi,%esi
400032f2:	89 f5                	mov    %esi,%ebp
400032f4:	75 0b                	jne    40003301 <__umoddi3+0xb1>
400032f6:	b8 01 00 00 00       	mov    $0x1,%eax
400032fb:	31 d2                	xor    %edx,%edx
400032fd:	f7 f6                	div    %esi
400032ff:	89 c5                	mov    %eax,%ebp
40003301:	8b 44 24 0c          	mov    0xc(%esp),%eax
40003305:	31 d2                	xor    %edx,%edx
40003307:	f7 f5                	div    %ebp
40003309:	89 c8                	mov    %ecx,%eax
4000330b:	f7 f5                	div    %ebp
4000330d:	eb 84                	jmp    40003293 <__umoddi3+0x43>
4000330f:	90                   	nop
40003310:	89 c8                	mov    %ecx,%eax
40003312:	89 fa                	mov    %edi,%edx
40003314:	8b 74 24 20          	mov    0x20(%esp),%esi
40003318:	8b 7c 24 24          	mov    0x24(%esp),%edi
4000331c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
40003320:	83 c4 2c             	add    $0x2c,%esp
40003323:	c3                   	ret    
40003324:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003328:	8b 44 24 10          	mov    0x10(%esp),%eax
4000332c:	be 20 00 00 00       	mov    $0x20,%esi
40003331:	89 e9                	mov    %ebp,%ecx
40003333:	29 ee                	sub    %ebp,%esi
40003335:	d3 e2                	shl    %cl,%edx
40003337:	89 f1                	mov    %esi,%ecx
40003339:	d3 e8                	shr    %cl,%eax
4000333b:	89 e9                	mov    %ebp,%ecx
4000333d:	09 d0                	or     %edx,%eax
4000333f:	89 fa                	mov    %edi,%edx
40003341:	89 44 24 0c          	mov    %eax,0xc(%esp)
40003345:	8b 44 24 10          	mov    0x10(%esp),%eax
40003349:	d3 e0                	shl    %cl,%eax
4000334b:	89 f1                	mov    %esi,%ecx
4000334d:	89 44 24 10          	mov    %eax,0x10(%esp)
40003351:	8b 44 24 1c          	mov    0x1c(%esp),%eax
40003355:	d3 ea                	shr    %cl,%edx
40003357:	89 e9                	mov    %ebp,%ecx
40003359:	d3 e7                	shl    %cl,%edi
4000335b:	89 f1                	mov    %esi,%ecx
4000335d:	d3 e8                	shr    %cl,%eax
4000335f:	89 e9                	mov    %ebp,%ecx
40003361:	09 f8                	or     %edi,%eax
40003363:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
40003367:	f7 74 24 0c          	divl   0xc(%esp)
4000336b:	d3 e7                	shl    %cl,%edi
4000336d:	89 7c 24 18          	mov    %edi,0x18(%esp)
40003371:	89 d7                	mov    %edx,%edi
40003373:	f7 64 24 10          	mull   0x10(%esp)
40003377:	39 d7                	cmp    %edx,%edi
40003379:	89 c1                	mov    %eax,%ecx
4000337b:	89 54 24 14          	mov    %edx,0x14(%esp)
4000337f:	72 3b                	jb     400033bc <__umoddi3+0x16c>
40003381:	39 44 24 18          	cmp    %eax,0x18(%esp)
40003385:	72 31                	jb     400033b8 <__umoddi3+0x168>
40003387:	8b 44 24 18          	mov    0x18(%esp),%eax
4000338b:	29 c8                	sub    %ecx,%eax
4000338d:	19 d7                	sbb    %edx,%edi
4000338f:	89 e9                	mov    %ebp,%ecx
40003391:	89 fa                	mov    %edi,%edx
40003393:	d3 e8                	shr    %cl,%eax
40003395:	89 f1                	mov    %esi,%ecx
40003397:	d3 e2                	shl    %cl,%edx
40003399:	89 e9                	mov    %ebp,%ecx
4000339b:	09 d0                	or     %edx,%eax
4000339d:	89 fa                	mov    %edi,%edx
4000339f:	d3 ea                	shr    %cl,%edx
400033a1:	8b 74 24 20          	mov    0x20(%esp),%esi
400033a5:	8b 7c 24 24          	mov    0x24(%esp),%edi
400033a9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
400033ad:	83 c4 2c             	add    $0x2c,%esp
400033b0:	c3                   	ret    
400033b1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
400033b8:	39 d7                	cmp    %edx,%edi
400033ba:	75 cb                	jne    40003387 <__umoddi3+0x137>
400033bc:	8b 54 24 14          	mov    0x14(%esp),%edx
400033c0:	89 c1                	mov    %eax,%ecx
400033c2:	2b 4c 24 10          	sub    0x10(%esp),%ecx
400033c6:	1b 54 24 0c          	sbb    0xc(%esp),%edx
400033ca:	eb bb                	jmp    40003387 <__umoddi3+0x137>
400033cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
400033d0:	3b 44 24 18          	cmp    0x18(%esp),%eax
400033d4:	0f 82 e8 fe ff ff    	jb     400032c2 <__umoddi3+0x72>
400033da:	e9 f3 fe ff ff       	jmp    400032d2 <__umoddi3+0x82>
