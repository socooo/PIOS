
obj/user/echo:     file format elf32-i386


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
4000010c:	e8 33 00 00 00       	call   40000144 <main>
	pushl	%eax	// use with main's return value as exit status
40000111:	50                   	push   %eax
	call	exit
40000112:	e8 6d 0c 00 00       	call   40000d84 <exit>
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

40000144 <main>:
#include <inc/stdio.h>
#include <inc/string.h>

int
main(int argc, char **argv)
{	
40000144:	55                   	push   %ebp
40000145:	89 e5                	mov    %esp,%ebp
40000147:	83 e4 f0             	and    $0xfffffff0,%esp
4000014a:	83 ec 20             	sub    $0x20,%esp
	int i, nflag;
	int (*pr)(const char *fmt, ...) = printf;
4000014d:	c7 44 24 14 2f 0f 00 	movl   $0x40000f2f,0x14(%esp)
40000154:	40 
	nflag = 0;
40000155:	c7 44 24 18 00 00 00 	movl   $0x0,0x18(%esp)
4000015c:	00 
	while (argc > 1 && argv[1][0] == '-') {
4000015d:	eb 3e                	jmp    4000019d <main+0x59>
		if (argv[1][1] == 'n')
4000015f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000162:	83 c0 04             	add    $0x4,%eax
40000165:	8b 00                	mov    (%eax),%eax
40000167:	83 c0 01             	add    $0x1,%eax
4000016a:	0f b6 00             	movzbl (%eax),%eax
4000016d:	3c 6e                	cmp    $0x6e,%al
4000016f:	75 0a                	jne    4000017b <main+0x37>
			nflag = 1;
40000171:	c7 44 24 18 01 00 00 	movl   $0x1,0x18(%esp)
40000178:	00 
40000179:	eb 1a                	jmp    40000195 <main+0x51>
		else if (argv[1][1] == 'c')
4000017b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000017e:	83 c0 04             	add    $0x4,%eax
40000181:	8b 00                	mov    (%eax),%eax
40000183:	83 c0 01             	add    $0x1,%eax
40000186:	0f b6 00             	movzbl (%eax),%eax
40000189:	3c 63                	cmp    $0x63,%al
4000018b:	75 27                	jne    400001b4 <main+0x70>
			pr = cprintf;
4000018d:	c7 44 24 14 e8 02 00 	movl   $0x400002e8,0x14(%esp)
40000194:	40 
		else
			break;
		argc--;
40000195:	83 6d 08 01          	subl   $0x1,0x8(%ebp)
		argv++;
40000199:	83 45 0c 04          	addl   $0x4,0xc(%ebp)
main(int argc, char **argv)
{	
	int i, nflag;
	int (*pr)(const char *fmt, ...) = printf;
	nflag = 0;
	while (argc > 1 && argv[1][0] == '-') {
4000019d:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
400001a1:	7e 12                	jle    400001b5 <main+0x71>
400001a3:	8b 45 0c             	mov    0xc(%ebp),%eax
400001a6:	83 c0 04             	add    $0x4,%eax
400001a9:	8b 00                	mov    (%eax),%eax
400001ab:	0f b6 00             	movzbl (%eax),%eax
400001ae:	3c 2d                	cmp    $0x2d,%al
400001b0:	74 ad                	je     4000015f <main+0x1b>
400001b2:	eb 01                	jmp    400001b5 <main+0x71>
		if (argv[1][1] == 'n')
			nflag = 1;
		else if (argv[1][1] == 'c')
			pr = cprintf;
		else
			break;
400001b4:	90                   	nop
		argc--;
		argv++;
	}

	for (i = 1; i < argc; i++) {
400001b5:	c7 44 24 1c 01 00 00 	movl   $0x1,0x1c(%esp)
400001bc:	00 
400001bd:	eb 3c                	jmp    400001fb <main+0xb7>
		if (i > 1)
400001bf:	83 7c 24 1c 01       	cmpl   $0x1,0x1c(%esp)
400001c4:	7e 0d                	jle    400001d3 <main+0x8f>
			pr(" ");
400001c6:	c7 04 24 10 32 00 40 	movl   $0x40003210,(%esp)
400001cd:	8b 44 24 14          	mov    0x14(%esp),%eax
400001d1:	ff d0                	call   *%eax
		pr("%s", argv[i]);
400001d3:	8b 44 24 1c          	mov    0x1c(%esp),%eax
400001d7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
400001de:	8b 45 0c             	mov    0xc(%ebp),%eax
400001e1:	01 d0                	add    %edx,%eax
400001e3:	8b 00                	mov    (%eax),%eax
400001e5:	89 44 24 04          	mov    %eax,0x4(%esp)
400001e9:	c7 04 24 12 32 00 40 	movl   $0x40003212,(%esp)
400001f0:	8b 44 24 14          	mov    0x14(%esp),%eax
400001f4:	ff d0                	call   *%eax
			break;
		argc--;
		argv++;
	}

	for (i = 1; i < argc; i++) {
400001f6:	83 44 24 1c 01       	addl   $0x1,0x1c(%esp)
400001fb:	8b 44 24 1c          	mov    0x1c(%esp),%eax
400001ff:	3b 45 08             	cmp    0x8(%ebp),%eax
40000202:	7c bb                	jl     400001bf <main+0x7b>
		if (i > 1)
			pr(" ");
		pr("%s", argv[i]);
	}
	if (!nflag)
40000204:	83 7c 24 18 00       	cmpl   $0x0,0x18(%esp)
40000209:	75 0d                	jne    40000218 <main+0xd4>
		pr("\n");
4000020b:	c7 04 24 15 32 00 40 	movl   $0x40003215,(%esp)
40000212:	8b 44 24 14          	mov    0x14(%esp),%eax
40000216:	ff d0                	call   *%eax

	return 0;
40000218:	b8 00 00 00 00       	mov    $0x0,%eax
}
4000021d:	c9                   	leave  
4000021e:	c3                   	ret    
4000021f:	90                   	nop

40000220 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
40000220:	55                   	push   %ebp
40000221:	89 e5                	mov    %esp,%ebp
40000223:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
40000226:	8b 45 0c             	mov    0xc(%ebp),%eax
40000229:	8b 00                	mov    (%eax),%eax
4000022b:	8b 55 08             	mov    0x8(%ebp),%edx
4000022e:	89 d1                	mov    %edx,%ecx
40000230:	8b 55 0c             	mov    0xc(%ebp),%edx
40000233:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
40000237:	8d 50 01             	lea    0x1(%eax),%edx
4000023a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000023d:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
4000023f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000242:	8b 00                	mov    (%eax),%eax
40000244:	3d ff 00 00 00       	cmp    $0xff,%eax
40000249:	75 24                	jne    4000026f <putch+0x4f>
		b->buf[b->idx] = 0;
4000024b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000024e:	8b 00                	mov    (%eax),%eax
40000250:	8b 55 0c             	mov    0xc(%ebp),%edx
40000253:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
40000258:	8b 45 0c             	mov    0xc(%ebp),%eax
4000025b:	83 c0 08             	add    $0x8,%eax
4000025e:	89 04 24             	mov    %eax,(%esp)
40000261:	e8 c6 0e 00 00       	call   4000112c <cputs>
		b->idx = 0;
40000266:	8b 45 0c             	mov    0xc(%ebp),%eax
40000269:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
4000026f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000272:	8b 40 04             	mov    0x4(%eax),%eax
40000275:	8d 50 01             	lea    0x1(%eax),%edx
40000278:	8b 45 0c             	mov    0xc(%ebp),%eax
4000027b:	89 50 04             	mov    %edx,0x4(%eax)
}
4000027e:	c9                   	leave  
4000027f:	c3                   	ret    

40000280 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
40000280:	55                   	push   %ebp
40000281:	89 e5                	mov    %esp,%ebp
40000283:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
40000289:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
40000290:	00 00 00 
	b.cnt = 0;
40000293:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
4000029a:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
4000029d:	8b 45 0c             	mov    0xc(%ebp),%eax
400002a0:	89 44 24 0c          	mov    %eax,0xc(%esp)
400002a4:	8b 45 08             	mov    0x8(%ebp),%eax
400002a7:	89 44 24 08          	mov    %eax,0x8(%esp)
400002ab:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
400002b1:	89 44 24 04          	mov    %eax,0x4(%esp)
400002b5:	c7 04 24 20 02 00 40 	movl   $0x40000220,(%esp)
400002bc:	e8 70 03 00 00       	call   40000631 <vprintfmt>

	b.buf[b.idx] = 0;
400002c1:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
400002c7:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
400002ce:	00 
	cputs(b.buf);
400002cf:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
400002d5:	83 c0 08             	add    $0x8,%eax
400002d8:	89 04 24             	mov    %eax,(%esp)
400002db:	e8 4c 0e 00 00       	call   4000112c <cputs>

	return b.cnt;
400002e0:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
400002e6:	c9                   	leave  
400002e7:	c3                   	ret    

400002e8 <cprintf>:

int
cprintf(const char *fmt, ...)
{
400002e8:	55                   	push   %ebp
400002e9:	89 e5                	mov    %esp,%ebp
400002eb:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
400002ee:	8d 45 0c             	lea    0xc(%ebp),%eax
400002f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
400002f4:	8b 45 08             	mov    0x8(%ebp),%eax
400002f7:	8b 55 f4             	mov    -0xc(%ebp),%edx
400002fa:	89 54 24 04          	mov    %edx,0x4(%esp)
400002fe:	89 04 24             	mov    %eax,(%esp)
40000301:	e8 7a ff ff ff       	call   40000280 <vcprintf>
40000306:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
40000309:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
4000030c:	c9                   	leave  
4000030d:	c3                   	ret    
4000030e:	66 90                	xchg   %ax,%ax

40000310 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
40000310:	55                   	push   %ebp
40000311:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
40000313:	8b 45 08             	mov    0x8(%ebp),%eax
40000316:	8b 40 18             	mov    0x18(%eax),%eax
40000319:	83 e0 02             	and    $0x2,%eax
4000031c:	85 c0                	test   %eax,%eax
4000031e:	74 1c                	je     4000033c <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
40000320:	8b 45 0c             	mov    0xc(%ebp),%eax
40000323:	8b 00                	mov    (%eax),%eax
40000325:	8d 50 08             	lea    0x8(%eax),%edx
40000328:	8b 45 0c             	mov    0xc(%ebp),%eax
4000032b:	89 10                	mov    %edx,(%eax)
4000032d:	8b 45 0c             	mov    0xc(%ebp),%eax
40000330:	8b 00                	mov    (%eax),%eax
40000332:	83 e8 08             	sub    $0x8,%eax
40000335:	8b 50 04             	mov    0x4(%eax),%edx
40000338:	8b 00                	mov    (%eax),%eax
4000033a:	eb 47                	jmp    40000383 <getuint+0x73>
	else if (st->flags & F_L)
4000033c:	8b 45 08             	mov    0x8(%ebp),%eax
4000033f:	8b 40 18             	mov    0x18(%eax),%eax
40000342:	83 e0 01             	and    $0x1,%eax
40000345:	85 c0                	test   %eax,%eax
40000347:	74 1e                	je     40000367 <getuint+0x57>
		return va_arg(*ap, unsigned long);
40000349:	8b 45 0c             	mov    0xc(%ebp),%eax
4000034c:	8b 00                	mov    (%eax),%eax
4000034e:	8d 50 04             	lea    0x4(%eax),%edx
40000351:	8b 45 0c             	mov    0xc(%ebp),%eax
40000354:	89 10                	mov    %edx,(%eax)
40000356:	8b 45 0c             	mov    0xc(%ebp),%eax
40000359:	8b 00                	mov    (%eax),%eax
4000035b:	83 e8 04             	sub    $0x4,%eax
4000035e:	8b 00                	mov    (%eax),%eax
40000360:	ba 00 00 00 00       	mov    $0x0,%edx
40000365:	eb 1c                	jmp    40000383 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
40000367:	8b 45 0c             	mov    0xc(%ebp),%eax
4000036a:	8b 00                	mov    (%eax),%eax
4000036c:	8d 50 04             	lea    0x4(%eax),%edx
4000036f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000372:	89 10                	mov    %edx,(%eax)
40000374:	8b 45 0c             	mov    0xc(%ebp),%eax
40000377:	8b 00                	mov    (%eax),%eax
40000379:	83 e8 04             	sub    $0x4,%eax
4000037c:	8b 00                	mov    (%eax),%eax
4000037e:	ba 00 00 00 00       	mov    $0x0,%edx
}
40000383:	5d                   	pop    %ebp
40000384:	c3                   	ret    

40000385 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
40000385:	55                   	push   %ebp
40000386:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
40000388:	8b 45 08             	mov    0x8(%ebp),%eax
4000038b:	8b 40 18             	mov    0x18(%eax),%eax
4000038e:	83 e0 02             	and    $0x2,%eax
40000391:	85 c0                	test   %eax,%eax
40000393:	74 1c                	je     400003b1 <getint+0x2c>
		return va_arg(*ap, long long);
40000395:	8b 45 0c             	mov    0xc(%ebp),%eax
40000398:	8b 00                	mov    (%eax),%eax
4000039a:	8d 50 08             	lea    0x8(%eax),%edx
4000039d:	8b 45 0c             	mov    0xc(%ebp),%eax
400003a0:	89 10                	mov    %edx,(%eax)
400003a2:	8b 45 0c             	mov    0xc(%ebp),%eax
400003a5:	8b 00                	mov    (%eax),%eax
400003a7:	83 e8 08             	sub    $0x8,%eax
400003aa:	8b 50 04             	mov    0x4(%eax),%edx
400003ad:	8b 00                	mov    (%eax),%eax
400003af:	eb 47                	jmp    400003f8 <getint+0x73>
	else if (st->flags & F_L)
400003b1:	8b 45 08             	mov    0x8(%ebp),%eax
400003b4:	8b 40 18             	mov    0x18(%eax),%eax
400003b7:	83 e0 01             	and    $0x1,%eax
400003ba:	85 c0                	test   %eax,%eax
400003bc:	74 1e                	je     400003dc <getint+0x57>
		return va_arg(*ap, long);
400003be:	8b 45 0c             	mov    0xc(%ebp),%eax
400003c1:	8b 00                	mov    (%eax),%eax
400003c3:	8d 50 04             	lea    0x4(%eax),%edx
400003c6:	8b 45 0c             	mov    0xc(%ebp),%eax
400003c9:	89 10                	mov    %edx,(%eax)
400003cb:	8b 45 0c             	mov    0xc(%ebp),%eax
400003ce:	8b 00                	mov    (%eax),%eax
400003d0:	83 e8 04             	sub    $0x4,%eax
400003d3:	8b 00                	mov    (%eax),%eax
400003d5:	89 c2                	mov    %eax,%edx
400003d7:	c1 fa 1f             	sar    $0x1f,%edx
400003da:	eb 1c                	jmp    400003f8 <getint+0x73>
	else
		return va_arg(*ap, int);
400003dc:	8b 45 0c             	mov    0xc(%ebp),%eax
400003df:	8b 00                	mov    (%eax),%eax
400003e1:	8d 50 04             	lea    0x4(%eax),%edx
400003e4:	8b 45 0c             	mov    0xc(%ebp),%eax
400003e7:	89 10                	mov    %edx,(%eax)
400003e9:	8b 45 0c             	mov    0xc(%ebp),%eax
400003ec:	8b 00                	mov    (%eax),%eax
400003ee:	83 e8 04             	sub    $0x4,%eax
400003f1:	8b 00                	mov    (%eax),%eax
400003f3:	89 c2                	mov    %eax,%edx
400003f5:	c1 fa 1f             	sar    $0x1f,%edx
}
400003f8:	5d                   	pop    %ebp
400003f9:	c3                   	ret    

400003fa <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
400003fa:	55                   	push   %ebp
400003fb:	89 e5                	mov    %esp,%ebp
400003fd:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
40000400:	eb 1a                	jmp    4000041c <putpad+0x22>
		st->putch(st->padc, st->putdat);
40000402:	8b 45 08             	mov    0x8(%ebp),%eax
40000405:	8b 00                	mov    (%eax),%eax
40000407:	8b 55 08             	mov    0x8(%ebp),%edx
4000040a:	8b 4a 04             	mov    0x4(%edx),%ecx
4000040d:	8b 55 08             	mov    0x8(%ebp),%edx
40000410:	8b 52 08             	mov    0x8(%edx),%edx
40000413:	89 4c 24 04          	mov    %ecx,0x4(%esp)
40000417:	89 14 24             	mov    %edx,(%esp)
4000041a:	ff d0                	call   *%eax

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
4000041c:	8b 45 08             	mov    0x8(%ebp),%eax
4000041f:	8b 40 0c             	mov    0xc(%eax),%eax
40000422:	8d 50 ff             	lea    -0x1(%eax),%edx
40000425:	8b 45 08             	mov    0x8(%ebp),%eax
40000428:	89 50 0c             	mov    %edx,0xc(%eax)
4000042b:	8b 45 08             	mov    0x8(%ebp),%eax
4000042e:	8b 40 0c             	mov    0xc(%eax),%eax
40000431:	85 c0                	test   %eax,%eax
40000433:	79 cd                	jns    40000402 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
40000435:	c9                   	leave  
40000436:	c3                   	ret    

40000437 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
40000437:	55                   	push   %ebp
40000438:	89 e5                	mov    %esp,%ebp
4000043a:	53                   	push   %ebx
4000043b:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
4000043e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000442:	79 18                	jns    4000045c <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
40000444:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000044b:	00 
4000044c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000044f:	89 04 24             	mov    %eax,(%esp)
40000452:	e8 f6 06 00 00       	call   40000b4d <strchr>
40000457:	89 45 f4             	mov    %eax,-0xc(%ebp)
4000045a:	eb 2e                	jmp    4000048a <putstr+0x53>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
4000045c:	8b 45 10             	mov    0x10(%ebp),%eax
4000045f:	89 44 24 08          	mov    %eax,0x8(%esp)
40000463:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000046a:	00 
4000046b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000046e:	89 04 24             	mov    %eax,(%esp)
40000471:	e8 d4 08 00 00       	call   40000d4a <memchr>
40000476:	89 45 f4             	mov    %eax,-0xc(%ebp)
40000479:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
4000047d:	75 0b                	jne    4000048a <putstr+0x53>
		lim = str + maxlen;
4000047f:	8b 55 10             	mov    0x10(%ebp),%edx
40000482:	8b 45 0c             	mov    0xc(%ebp),%eax
40000485:	01 d0                	add    %edx,%eax
40000487:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
4000048a:	8b 45 08             	mov    0x8(%ebp),%eax
4000048d:	8b 40 0c             	mov    0xc(%eax),%eax
40000490:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40000493:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000496:	89 cb                	mov    %ecx,%ebx
40000498:	29 d3                	sub    %edx,%ebx
4000049a:	89 da                	mov    %ebx,%edx
4000049c:	01 c2                	add    %eax,%edx
4000049e:	8b 45 08             	mov    0x8(%ebp),%eax
400004a1:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
400004a4:	8b 45 08             	mov    0x8(%ebp),%eax
400004a7:	8b 40 18             	mov    0x18(%eax),%eax
400004aa:	83 e0 10             	and    $0x10,%eax
400004ad:	85 c0                	test   %eax,%eax
400004af:	75 32                	jne    400004e3 <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
400004b1:	8b 45 08             	mov    0x8(%ebp),%eax
400004b4:	89 04 24             	mov    %eax,(%esp)
400004b7:	e8 3e ff ff ff       	call   400003fa <putpad>
	while (str < lim) {
400004bc:	eb 25                	jmp    400004e3 <putstr+0xac>
		char ch = *str++;
400004be:	8b 45 0c             	mov    0xc(%ebp),%eax
400004c1:	0f b6 00             	movzbl (%eax),%eax
400004c4:	88 45 f3             	mov    %al,-0xd(%ebp)
400004c7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
400004cb:	8b 45 08             	mov    0x8(%ebp),%eax
400004ce:	8b 00                	mov    (%eax),%eax
400004d0:	8b 55 08             	mov    0x8(%ebp),%edx
400004d3:	8b 4a 04             	mov    0x4(%edx),%ecx
400004d6:	0f be 55 f3          	movsbl -0xd(%ebp),%edx
400004da:	89 4c 24 04          	mov    %ecx,0x4(%esp)
400004de:	89 14 24             	mov    %edx,(%esp)
400004e1:	ff d0                	call   *%eax
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
400004e3:	8b 45 0c             	mov    0xc(%ebp),%eax
400004e6:	3b 45 f4             	cmp    -0xc(%ebp),%eax
400004e9:	72 d3                	jb     400004be <putstr+0x87>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
400004eb:	8b 45 08             	mov    0x8(%ebp),%eax
400004ee:	89 04 24             	mov    %eax,(%esp)
400004f1:	e8 04 ff ff ff       	call   400003fa <putpad>
}
400004f6:	83 c4 24             	add    $0x24,%esp
400004f9:	5b                   	pop    %ebx
400004fa:	5d                   	pop    %ebp
400004fb:	c3                   	ret    

400004fc <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
400004fc:	55                   	push   %ebp
400004fd:	89 e5                	mov    %esp,%ebp
400004ff:	53                   	push   %ebx
40000500:	83 ec 24             	sub    $0x24,%esp
40000503:	8b 45 10             	mov    0x10(%ebp),%eax
40000506:	89 45 f0             	mov    %eax,-0x10(%ebp)
40000509:	8b 45 14             	mov    0x14(%ebp),%eax
4000050c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
4000050f:	8b 45 08             	mov    0x8(%ebp),%eax
40000512:	8b 40 1c             	mov    0x1c(%eax),%eax
40000515:	89 c2                	mov    %eax,%edx
40000517:	c1 fa 1f             	sar    $0x1f,%edx
4000051a:	3b 55 f4             	cmp    -0xc(%ebp),%edx
4000051d:	77 4e                	ja     4000056d <genint+0x71>
4000051f:	3b 55 f4             	cmp    -0xc(%ebp),%edx
40000522:	72 05                	jb     40000529 <genint+0x2d>
40000524:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40000527:	77 44                	ja     4000056d <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
40000529:	8b 45 08             	mov    0x8(%ebp),%eax
4000052c:	8b 40 1c             	mov    0x1c(%eax),%eax
4000052f:	89 c2                	mov    %eax,%edx
40000531:	c1 fa 1f             	sar    $0x1f,%edx
40000534:	89 44 24 08          	mov    %eax,0x8(%esp)
40000538:	89 54 24 0c          	mov    %edx,0xc(%esp)
4000053c:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000053f:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000542:	89 04 24             	mov    %eax,(%esp)
40000545:	89 54 24 04          	mov    %edx,0x4(%esp)
40000549:	e8 e2 29 00 00       	call   40002f30 <__udivdi3>
4000054e:	89 44 24 08          	mov    %eax,0x8(%esp)
40000552:	89 54 24 0c          	mov    %edx,0xc(%esp)
40000556:	8b 45 0c             	mov    0xc(%ebp),%eax
40000559:	89 44 24 04          	mov    %eax,0x4(%esp)
4000055d:	8b 45 08             	mov    0x8(%ebp),%eax
40000560:	89 04 24             	mov    %eax,(%esp)
40000563:	e8 94 ff ff ff       	call   400004fc <genint>
40000568:	89 45 0c             	mov    %eax,0xc(%ebp)
4000056b:	eb 1b                	jmp    40000588 <genint+0x8c>
	else if (st->signc >= 0)
4000056d:	8b 45 08             	mov    0x8(%ebp),%eax
40000570:	8b 40 14             	mov    0x14(%eax),%eax
40000573:	85 c0                	test   %eax,%eax
40000575:	78 11                	js     40000588 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
40000577:	8b 45 08             	mov    0x8(%ebp),%eax
4000057a:	8b 40 14             	mov    0x14(%eax),%eax
4000057d:	89 c2                	mov    %eax,%edx
4000057f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000582:	88 10                	mov    %dl,(%eax)
40000584:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
40000588:	8b 45 08             	mov    0x8(%ebp),%eax
4000058b:	8b 40 1c             	mov    0x1c(%eax),%eax
4000058e:	89 c1                	mov    %eax,%ecx
40000590:	89 c3                	mov    %eax,%ebx
40000592:	c1 fb 1f             	sar    $0x1f,%ebx
40000595:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000598:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000059b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
4000059f:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
400005a3:	89 04 24             	mov    %eax,(%esp)
400005a6:	89 54 24 04          	mov    %edx,0x4(%esp)
400005aa:	e8 d1 2a 00 00       	call   40003080 <__umoddi3>
400005af:	05 18 32 00 40       	add    $0x40003218,%eax
400005b4:	0f b6 10             	movzbl (%eax),%edx
400005b7:	8b 45 0c             	mov    0xc(%ebp),%eax
400005ba:	88 10                	mov    %dl,(%eax)
400005bc:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
400005c0:	8b 45 0c             	mov    0xc(%ebp),%eax
}
400005c3:	83 c4 24             	add    $0x24,%esp
400005c6:	5b                   	pop    %ebx
400005c7:	5d                   	pop    %ebp
400005c8:	c3                   	ret    

400005c9 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
400005c9:	55                   	push   %ebp
400005ca:	89 e5                	mov    %esp,%ebp
400005cc:	83 ec 58             	sub    $0x58,%esp
400005cf:	8b 45 0c             	mov    0xc(%ebp),%eax
400005d2:	89 45 c0             	mov    %eax,-0x40(%ebp)
400005d5:	8b 45 10             	mov    0x10(%ebp),%eax
400005d8:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
400005db:	8d 45 d6             	lea    -0x2a(%ebp),%eax
400005de:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
400005e1:	8b 45 08             	mov    0x8(%ebp),%eax
400005e4:	8b 55 14             	mov    0x14(%ebp),%edx
400005e7:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
400005ea:	8b 45 c0             	mov    -0x40(%ebp),%eax
400005ed:	8b 55 c4             	mov    -0x3c(%ebp),%edx
400005f0:	89 44 24 08          	mov    %eax,0x8(%esp)
400005f4:	89 54 24 0c          	mov    %edx,0xc(%esp)
400005f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
400005fb:	89 44 24 04          	mov    %eax,0x4(%esp)
400005ff:	8b 45 08             	mov    0x8(%ebp),%eax
40000602:	89 04 24             	mov    %eax,(%esp)
40000605:	e8 f2 fe ff ff       	call   400004fc <genint>
4000060a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
4000060d:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000610:	8d 45 d6             	lea    -0x2a(%ebp),%eax
40000613:	89 d1                	mov    %edx,%ecx
40000615:	29 c1                	sub    %eax,%ecx
40000617:	89 c8                	mov    %ecx,%eax
40000619:	89 44 24 08          	mov    %eax,0x8(%esp)
4000061d:	8d 45 d6             	lea    -0x2a(%ebp),%eax
40000620:	89 44 24 04          	mov    %eax,0x4(%esp)
40000624:	8b 45 08             	mov    0x8(%ebp),%eax
40000627:	89 04 24             	mov    %eax,(%esp)
4000062a:	e8 08 fe ff ff       	call   40000437 <putstr>
}
4000062f:	c9                   	leave  
40000630:	c3                   	ret    

40000631 <vprintfmt>:


// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
40000631:	55                   	push   %ebp
40000632:	89 e5                	mov    %esp,%ebp
40000634:	53                   	push   %ebx
40000635:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
40000638:	8d 55 cc             	lea    -0x34(%ebp),%edx
4000063b:	b9 00 00 00 00       	mov    $0x0,%ecx
40000640:	b8 20 00 00 00       	mov    $0x20,%eax
40000645:	89 c3                	mov    %eax,%ebx
40000647:	83 e3 fc             	and    $0xfffffffc,%ebx
4000064a:	b8 00 00 00 00       	mov    $0x0,%eax
4000064f:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
40000652:	83 c0 04             	add    $0x4,%eax
40000655:	39 d8                	cmp    %ebx,%eax
40000657:	72 f6                	jb     4000064f <vprintfmt+0x1e>
40000659:	01 c2                	add    %eax,%edx
4000065b:	8b 45 08             	mov    0x8(%ebp),%eax
4000065e:	89 45 cc             	mov    %eax,-0x34(%ebp)
40000661:	8b 45 0c             	mov    0xc(%ebp),%eax
40000664:	89 45 d0             	mov    %eax,-0x30(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40000667:	eb 17                	jmp    40000680 <vprintfmt+0x4f>
			if (ch == '\0')
40000669:	85 db                	test   %ebx,%ebx
4000066b:	0f 84 50 03 00 00    	je     400009c1 <vprintfmt+0x390>
				return;
			putch(ch, putdat);
40000671:	8b 45 0c             	mov    0xc(%ebp),%eax
40000674:	89 44 24 04          	mov    %eax,0x4(%esp)
40000678:	89 1c 24             	mov    %ebx,(%esp)
4000067b:	8b 45 08             	mov    0x8(%ebp),%eax
4000067e:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40000680:	8b 45 10             	mov    0x10(%ebp),%eax
40000683:	0f b6 00             	movzbl (%eax),%eax
40000686:	0f b6 d8             	movzbl %al,%ebx
40000689:	83 fb 25             	cmp    $0x25,%ebx
4000068c:	0f 95 c0             	setne  %al
4000068f:	83 45 10 01          	addl   $0x1,0x10(%ebp)
40000693:	84 c0                	test   %al,%al
40000695:	75 d2                	jne    40000669 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
40000697:	c7 45 d4 20 00 00 00 	movl   $0x20,-0x2c(%ebp)
		st.width = -1;
4000069e:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.prec = -1;
400006a5:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.signc = -1;
400006ac:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		st.flags = 0;
400006b3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		st.base = 10;
400006ba:	c7 45 e8 0a 00 00 00 	movl   $0xa,-0x18(%ebp)
400006c1:	eb 04                	jmp    400006c7 <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
400006c3:	90                   	nop
400006c4:	eb 01                	jmp    400006c7 <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
400006c6:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
400006c7:	8b 45 10             	mov    0x10(%ebp),%eax
400006ca:	0f b6 00             	movzbl (%eax),%eax
400006cd:	0f b6 d8             	movzbl %al,%ebx
400006d0:	89 d8                	mov    %ebx,%eax
400006d2:	83 45 10 01          	addl   $0x1,0x10(%ebp)
400006d6:	83 e8 20             	sub    $0x20,%eax
400006d9:	83 f8 58             	cmp    $0x58,%eax
400006dc:	0f 87 ae 02 00 00    	ja     40000990 <vprintfmt+0x35f>
400006e2:	8b 04 85 30 32 00 40 	mov    0x40003230(,%eax,4),%eax
400006e9:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
400006eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400006ee:	83 c8 10             	or     $0x10,%eax
400006f1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
400006f4:	eb d1                	jmp    400006c7 <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
400006f6:	c7 45 e0 2b 00 00 00 	movl   $0x2b,-0x20(%ebp)
			goto reswitch;
400006fd:	eb c8                	jmp    400006c7 <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
400006ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
40000702:	85 c0                	test   %eax,%eax
40000704:	79 bd                	jns    400006c3 <vprintfmt+0x92>
				st.signc = ' ';
40000706:	c7 45 e0 20 00 00 00 	movl   $0x20,-0x20(%ebp)
			goto reswitch;
4000070d:	eb b4                	jmp    400006c3 <vprintfmt+0x92>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
4000070f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40000712:	83 e0 08             	and    $0x8,%eax
40000715:	85 c0                	test   %eax,%eax
40000717:	75 07                	jne    40000720 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
40000719:	c7 45 d4 30 00 00 00 	movl   $0x30,-0x2c(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
40000720:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
				st.prec = st.prec * 10 + ch - '0';
40000727:	8b 55 dc             	mov    -0x24(%ebp),%edx
4000072a:	89 d0                	mov    %edx,%eax
4000072c:	c1 e0 02             	shl    $0x2,%eax
4000072f:	01 d0                	add    %edx,%eax
40000731:	01 c0                	add    %eax,%eax
40000733:	01 d8                	add    %ebx,%eax
40000735:	83 e8 30             	sub    $0x30,%eax
40000738:	89 45 dc             	mov    %eax,-0x24(%ebp)
				ch = *fmt;
4000073b:	8b 45 10             	mov    0x10(%ebp),%eax
4000073e:	0f b6 00             	movzbl (%eax),%eax
40000741:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
40000744:	83 fb 2f             	cmp    $0x2f,%ebx
40000747:	7e 21                	jle    4000076a <vprintfmt+0x139>
40000749:	83 fb 39             	cmp    $0x39,%ebx
4000074c:	7f 1c                	jg     4000076a <vprintfmt+0x139>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
4000074e:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
40000752:	eb d3                	jmp    40000727 <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
40000754:	8b 45 14             	mov    0x14(%ebp),%eax
40000757:	83 c0 04             	add    $0x4,%eax
4000075a:	89 45 14             	mov    %eax,0x14(%ebp)
4000075d:	8b 45 14             	mov    0x14(%ebp),%eax
40000760:	83 e8 04             	sub    $0x4,%eax
40000763:	8b 00                	mov    (%eax),%eax
40000765:	89 45 dc             	mov    %eax,-0x24(%ebp)
40000768:	eb 01                	jmp    4000076b <vprintfmt+0x13a>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
4000076a:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
4000076b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000076e:	83 e0 08             	and    $0x8,%eax
40000771:	85 c0                	test   %eax,%eax
40000773:	0f 85 4d ff ff ff    	jne    400006c6 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
40000779:	8b 45 dc             	mov    -0x24(%ebp),%eax
4000077c:	89 45 d8             	mov    %eax,-0x28(%ebp)
				st.prec = -1;
4000077f:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
			}
			goto reswitch;
40000786:	e9 3b ff ff ff       	jmp    400006c6 <vprintfmt+0x95>

		case '.':
			st.flags |= F_DOT;
4000078b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000078e:	83 c8 08             	or     $0x8,%eax
40000791:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
40000794:	e9 2e ff ff ff       	jmp    400006c7 <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
40000799:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000079c:	83 c8 04             	or     $0x4,%eax
4000079f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
400007a2:	e9 20 ff ff ff       	jmp    400006c7 <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
400007a7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
400007aa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400007ad:	83 e0 01             	and    $0x1,%eax
400007b0:	85 c0                	test   %eax,%eax
400007b2:	74 07                	je     400007bb <vprintfmt+0x18a>
400007b4:	b8 02 00 00 00       	mov    $0x2,%eax
400007b9:	eb 05                	jmp    400007c0 <vprintfmt+0x18f>
400007bb:	b8 01 00 00 00       	mov    $0x1,%eax
400007c0:	09 d0                	or     %edx,%eax
400007c2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
400007c5:	e9 fd fe ff ff       	jmp    400006c7 <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
400007ca:	8b 45 14             	mov    0x14(%ebp),%eax
400007cd:	83 c0 04             	add    $0x4,%eax
400007d0:	89 45 14             	mov    %eax,0x14(%ebp)
400007d3:	8b 45 14             	mov    0x14(%ebp),%eax
400007d6:	83 e8 04             	sub    $0x4,%eax
400007d9:	8b 00                	mov    (%eax),%eax
400007db:	8b 55 0c             	mov    0xc(%ebp),%edx
400007de:	89 54 24 04          	mov    %edx,0x4(%esp)
400007e2:	89 04 24             	mov    %eax,(%esp)
400007e5:	8b 45 08             	mov    0x8(%ebp),%eax
400007e8:	ff d0                	call   *%eax
			break;
400007ea:	e9 cc 01 00 00       	jmp    400009bb <vprintfmt+0x38a>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
400007ef:	8b 45 14             	mov    0x14(%ebp),%eax
400007f2:	83 c0 04             	add    $0x4,%eax
400007f5:	89 45 14             	mov    %eax,0x14(%ebp)
400007f8:	8b 45 14             	mov    0x14(%ebp),%eax
400007fb:	83 e8 04             	sub    $0x4,%eax
400007fe:	8b 00                	mov    (%eax),%eax
40000800:	89 45 ec             	mov    %eax,-0x14(%ebp)
40000803:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
40000807:	75 07                	jne    40000810 <vprintfmt+0x1df>
				s = "(null)";
40000809:	c7 45 ec 29 32 00 40 	movl   $0x40003229,-0x14(%ebp)
			putstr(&st, s, st.prec);
40000810:	8b 45 dc             	mov    -0x24(%ebp),%eax
40000813:	89 44 24 08          	mov    %eax,0x8(%esp)
40000817:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000081a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000081e:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000821:	89 04 24             	mov    %eax,(%esp)
40000824:	e8 0e fc ff ff       	call   40000437 <putstr>
			break;
40000829:	e9 8d 01 00 00       	jmp    400009bb <vprintfmt+0x38a>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
4000082e:	8d 45 14             	lea    0x14(%ebp),%eax
40000831:	89 44 24 04          	mov    %eax,0x4(%esp)
40000835:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000838:	89 04 24             	mov    %eax,(%esp)
4000083b:	e8 45 fb ff ff       	call   40000385 <getint>
40000840:	89 45 f0             	mov    %eax,-0x10(%ebp)
40000843:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((intmax_t) num < 0) {
40000846:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000849:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000084c:	85 d2                	test   %edx,%edx
4000084e:	79 1a                	jns    4000086a <vprintfmt+0x239>
				num = -(intmax_t) num;
40000850:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000853:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000856:	f7 d8                	neg    %eax
40000858:	83 d2 00             	adc    $0x0,%edx
4000085b:	f7 da                	neg    %edx
4000085d:	89 45 f0             	mov    %eax,-0x10(%ebp)
40000860:	89 55 f4             	mov    %edx,-0xc(%ebp)
				st.signc = '-';
40000863:	c7 45 e0 2d 00 00 00 	movl   $0x2d,-0x20(%ebp)
			}
			putint(&st, num, 10);
4000086a:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
40000871:	00 
40000872:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000875:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000878:	89 44 24 04          	mov    %eax,0x4(%esp)
4000087c:	89 54 24 08          	mov    %edx,0x8(%esp)
40000880:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000883:	89 04 24             	mov    %eax,(%esp)
40000886:	e8 3e fd ff ff       	call   400005c9 <putint>
			break;
4000088b:	e9 2b 01 00 00       	jmp    400009bb <vprintfmt+0x38a>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
40000890:	8d 45 14             	lea    0x14(%ebp),%eax
40000893:	89 44 24 04          	mov    %eax,0x4(%esp)
40000897:	8d 45 cc             	lea    -0x34(%ebp),%eax
4000089a:	89 04 24             	mov    %eax,(%esp)
4000089d:	e8 6e fa ff ff       	call   40000310 <getuint>
400008a2:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
400008a9:	00 
400008aa:	89 44 24 04          	mov    %eax,0x4(%esp)
400008ae:	89 54 24 08          	mov    %edx,0x8(%esp)
400008b2:	8d 45 cc             	lea    -0x34(%ebp),%eax
400008b5:	89 04 24             	mov    %eax,(%esp)
400008b8:	e8 0c fd ff ff       	call   400005c9 <putint>
			break;
400008bd:	e9 f9 00 00 00       	jmp    400009bb <vprintfmt+0x38a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
400008c2:	8d 45 14             	lea    0x14(%ebp),%eax
400008c5:	89 44 24 04          	mov    %eax,0x4(%esp)
400008c9:	8d 45 cc             	lea    -0x34(%ebp),%eax
400008cc:	89 04 24             	mov    %eax,(%esp)
400008cf:	e8 3c fa ff ff       	call   40000310 <getuint>
400008d4:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
400008db:	00 
400008dc:	89 44 24 04          	mov    %eax,0x4(%esp)
400008e0:	89 54 24 08          	mov    %edx,0x8(%esp)
400008e4:	8d 45 cc             	lea    -0x34(%ebp),%eax
400008e7:	89 04 24             	mov    %eax,(%esp)
400008ea:	e8 da fc ff ff       	call   400005c9 <putint>
			break;
400008ef:	e9 c7 00 00 00       	jmp    400009bb <vprintfmt+0x38a>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
400008f4:	8d 45 14             	lea    0x14(%ebp),%eax
400008f7:	89 44 24 04          	mov    %eax,0x4(%esp)
400008fb:	8d 45 cc             	lea    -0x34(%ebp),%eax
400008fe:	89 04 24             	mov    %eax,(%esp)
40000901:	e8 0a fa ff ff       	call   40000310 <getuint>
40000906:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
4000090d:	00 
4000090e:	89 44 24 04          	mov    %eax,0x4(%esp)
40000912:	89 54 24 08          	mov    %edx,0x8(%esp)
40000916:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000919:	89 04 24             	mov    %eax,(%esp)
4000091c:	e8 a8 fc ff ff       	call   400005c9 <putint>
			break;
40000921:	e9 95 00 00 00       	jmp    400009bb <vprintfmt+0x38a>

		// pointer
		case 'p':
			putch('0', putdat);
40000926:	8b 45 0c             	mov    0xc(%ebp),%eax
40000929:	89 44 24 04          	mov    %eax,0x4(%esp)
4000092d:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
40000934:	8b 45 08             	mov    0x8(%ebp),%eax
40000937:	ff d0                	call   *%eax
			putch('x', putdat);
40000939:	8b 45 0c             	mov    0xc(%ebp),%eax
4000093c:	89 44 24 04          	mov    %eax,0x4(%esp)
40000940:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
40000947:	8b 45 08             	mov    0x8(%ebp),%eax
4000094a:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
4000094c:	8b 45 14             	mov    0x14(%ebp),%eax
4000094f:	83 c0 04             	add    $0x4,%eax
40000952:	89 45 14             	mov    %eax,0x14(%ebp)
40000955:	8b 45 14             	mov    0x14(%ebp),%eax
40000958:	83 e8 04             	sub    $0x4,%eax
4000095b:	8b 00                	mov    (%eax),%eax
4000095d:	ba 00 00 00 00       	mov    $0x0,%edx
40000962:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
40000969:	00 
4000096a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000096e:	89 54 24 08          	mov    %edx,0x8(%esp)
40000972:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000975:	89 04 24             	mov    %eax,(%esp)
40000978:	e8 4c fc ff ff       	call   400005c9 <putint>
			break;
4000097d:	eb 3c                	jmp    400009bb <vprintfmt+0x38a>


		// escaped '%' character
		case '%':
			putch(ch, putdat);
4000097f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000982:	89 44 24 04          	mov    %eax,0x4(%esp)
40000986:	89 1c 24             	mov    %ebx,(%esp)
40000989:	8b 45 08             	mov    0x8(%ebp),%eax
4000098c:	ff d0                	call   *%eax
			break;
4000098e:	eb 2b                	jmp    400009bb <vprintfmt+0x38a>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
40000990:	8b 45 0c             	mov    0xc(%ebp),%eax
40000993:	89 44 24 04          	mov    %eax,0x4(%esp)
40000997:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
4000099e:	8b 45 08             	mov    0x8(%ebp),%eax
400009a1:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
400009a3:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
400009a7:	eb 04                	jmp    400009ad <vprintfmt+0x37c>
400009a9:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
400009ad:	8b 45 10             	mov    0x10(%ebp),%eax
400009b0:	83 e8 01             	sub    $0x1,%eax
400009b3:	0f b6 00             	movzbl (%eax),%eax
400009b6:	3c 25                	cmp    $0x25,%al
400009b8:	75 ef                	jne    400009a9 <vprintfmt+0x378>
				/* do nothing */;
			break;
400009ba:	90                   	nop
		}
	}
400009bb:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
400009bc:	e9 bf fc ff ff       	jmp    40000680 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
400009c1:	83 c4 44             	add    $0x44,%esp
400009c4:	5b                   	pop    %ebx
400009c5:	5d                   	pop    %ebp
400009c6:	c3                   	ret    
400009c7:	90                   	nop

400009c8 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
400009c8:	55                   	push   %ebp
400009c9:	89 e5                	mov    %esp,%ebp
400009cb:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
400009ce:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
400009d5:	eb 08                	jmp    400009df <strlen+0x17>
		n++;
400009d7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
400009db:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400009df:	8b 45 08             	mov    0x8(%ebp),%eax
400009e2:	0f b6 00             	movzbl (%eax),%eax
400009e5:	84 c0                	test   %al,%al
400009e7:	75 ee                	jne    400009d7 <strlen+0xf>
		n++;
	return n;
400009e9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
400009ec:	c9                   	leave  
400009ed:	c3                   	ret    

400009ee <strcpy>:

char *
strcpy(char *dst, const char *src)
{
400009ee:	55                   	push   %ebp
400009ef:	89 e5                	mov    %esp,%ebp
400009f1:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
400009f4:	8b 45 08             	mov    0x8(%ebp),%eax
400009f7:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
400009fa:	90                   	nop
400009fb:	8b 45 0c             	mov    0xc(%ebp),%eax
400009fe:	0f b6 10             	movzbl (%eax),%edx
40000a01:	8b 45 08             	mov    0x8(%ebp),%eax
40000a04:	88 10                	mov    %dl,(%eax)
40000a06:	8b 45 08             	mov    0x8(%ebp),%eax
40000a09:	0f b6 00             	movzbl (%eax),%eax
40000a0c:	84 c0                	test   %al,%al
40000a0e:	0f 95 c0             	setne  %al
40000a11:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000a15:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
40000a19:	84 c0                	test   %al,%al
40000a1b:	75 de                	jne    400009fb <strcpy+0xd>
		/* do nothing */;
	return ret;
40000a1d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
40000a20:	c9                   	leave  
40000a21:	c3                   	ret    

40000a22 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
40000a22:	55                   	push   %ebp
40000a23:	89 e5                	mov    %esp,%ebp
40000a25:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
40000a28:	8b 45 08             	mov    0x8(%ebp),%eax
40000a2b:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
40000a2e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
40000a35:	eb 21                	jmp    40000a58 <strncpy+0x36>
		*dst++ = *src;
40000a37:	8b 45 0c             	mov    0xc(%ebp),%eax
40000a3a:	0f b6 10             	movzbl (%eax),%edx
40000a3d:	8b 45 08             	mov    0x8(%ebp),%eax
40000a40:	88 10                	mov    %dl,(%eax)
40000a42:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
40000a46:	8b 45 0c             	mov    0xc(%ebp),%eax
40000a49:	0f b6 00             	movzbl (%eax),%eax
40000a4c:	84 c0                	test   %al,%al
40000a4e:	74 04                	je     40000a54 <strncpy+0x32>
			src++;
40000a50:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
40000a54:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40000a58:	8b 45 fc             	mov    -0x4(%ebp),%eax
40000a5b:	3b 45 10             	cmp    0x10(%ebp),%eax
40000a5e:	72 d7                	jb     40000a37 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
40000a60:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
40000a63:	c9                   	leave  
40000a64:	c3                   	ret    

40000a65 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
40000a65:	55                   	push   %ebp
40000a66:	89 e5                	mov    %esp,%ebp
40000a68:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
40000a6b:	8b 45 08             	mov    0x8(%ebp),%eax
40000a6e:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
40000a71:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000a75:	74 2f                	je     40000aa6 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
40000a77:	eb 13                	jmp    40000a8c <strlcpy+0x27>
			*dst++ = *src++;
40000a79:	8b 45 0c             	mov    0xc(%ebp),%eax
40000a7c:	0f b6 10             	movzbl (%eax),%edx
40000a7f:	8b 45 08             	mov    0x8(%ebp),%eax
40000a82:	88 10                	mov    %dl,(%eax)
40000a84:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000a88:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
40000a8c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40000a90:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000a94:	74 0a                	je     40000aa0 <strlcpy+0x3b>
40000a96:	8b 45 0c             	mov    0xc(%ebp),%eax
40000a99:	0f b6 00             	movzbl (%eax),%eax
40000a9c:	84 c0                	test   %al,%al
40000a9e:	75 d9                	jne    40000a79 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
40000aa0:	8b 45 08             	mov    0x8(%ebp),%eax
40000aa3:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
40000aa6:	8b 55 08             	mov    0x8(%ebp),%edx
40000aa9:	8b 45 fc             	mov    -0x4(%ebp),%eax
40000aac:	89 d1                	mov    %edx,%ecx
40000aae:	29 c1                	sub    %eax,%ecx
40000ab0:	89 c8                	mov    %ecx,%eax
}
40000ab2:	c9                   	leave  
40000ab3:	c3                   	ret    

40000ab4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
40000ab4:	55                   	push   %ebp
40000ab5:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
40000ab7:	eb 08                	jmp    40000ac1 <strcmp+0xd>
		p++, q++;
40000ab9:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000abd:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
40000ac1:	8b 45 08             	mov    0x8(%ebp),%eax
40000ac4:	0f b6 00             	movzbl (%eax),%eax
40000ac7:	84 c0                	test   %al,%al
40000ac9:	74 10                	je     40000adb <strcmp+0x27>
40000acb:	8b 45 08             	mov    0x8(%ebp),%eax
40000ace:	0f b6 10             	movzbl (%eax),%edx
40000ad1:	8b 45 0c             	mov    0xc(%ebp),%eax
40000ad4:	0f b6 00             	movzbl (%eax),%eax
40000ad7:	38 c2                	cmp    %al,%dl
40000ad9:	74 de                	je     40000ab9 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
40000adb:	8b 45 08             	mov    0x8(%ebp),%eax
40000ade:	0f b6 00             	movzbl (%eax),%eax
40000ae1:	0f b6 d0             	movzbl %al,%edx
40000ae4:	8b 45 0c             	mov    0xc(%ebp),%eax
40000ae7:	0f b6 00             	movzbl (%eax),%eax
40000aea:	0f b6 c0             	movzbl %al,%eax
40000aed:	89 d1                	mov    %edx,%ecx
40000aef:	29 c1                	sub    %eax,%ecx
40000af1:	89 c8                	mov    %ecx,%eax
}
40000af3:	5d                   	pop    %ebp
40000af4:	c3                   	ret    

40000af5 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
40000af5:	55                   	push   %ebp
40000af6:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
40000af8:	eb 0c                	jmp    40000b06 <strncmp+0x11>
		n--, p++, q++;
40000afa:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40000afe:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000b02:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
40000b06:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000b0a:	74 1a                	je     40000b26 <strncmp+0x31>
40000b0c:	8b 45 08             	mov    0x8(%ebp),%eax
40000b0f:	0f b6 00             	movzbl (%eax),%eax
40000b12:	84 c0                	test   %al,%al
40000b14:	74 10                	je     40000b26 <strncmp+0x31>
40000b16:	8b 45 08             	mov    0x8(%ebp),%eax
40000b19:	0f b6 10             	movzbl (%eax),%edx
40000b1c:	8b 45 0c             	mov    0xc(%ebp),%eax
40000b1f:	0f b6 00             	movzbl (%eax),%eax
40000b22:	38 c2                	cmp    %al,%dl
40000b24:	74 d4                	je     40000afa <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
40000b26:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000b2a:	75 07                	jne    40000b33 <strncmp+0x3e>
		return 0;
40000b2c:	b8 00 00 00 00       	mov    $0x0,%eax
40000b31:	eb 18                	jmp    40000b4b <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
40000b33:	8b 45 08             	mov    0x8(%ebp),%eax
40000b36:	0f b6 00             	movzbl (%eax),%eax
40000b39:	0f b6 d0             	movzbl %al,%edx
40000b3c:	8b 45 0c             	mov    0xc(%ebp),%eax
40000b3f:	0f b6 00             	movzbl (%eax),%eax
40000b42:	0f b6 c0             	movzbl %al,%eax
40000b45:	89 d1                	mov    %edx,%ecx
40000b47:	29 c1                	sub    %eax,%ecx
40000b49:	89 c8                	mov    %ecx,%eax
}
40000b4b:	5d                   	pop    %ebp
40000b4c:	c3                   	ret    

40000b4d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
40000b4d:	55                   	push   %ebp
40000b4e:	89 e5                	mov    %esp,%ebp
40000b50:	83 ec 04             	sub    $0x4,%esp
40000b53:	8b 45 0c             	mov    0xc(%ebp),%eax
40000b56:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
40000b59:	eb 1a                	jmp    40000b75 <strchr+0x28>
		if (*s++ == 0)
40000b5b:	8b 45 08             	mov    0x8(%ebp),%eax
40000b5e:	0f b6 00             	movzbl (%eax),%eax
40000b61:	84 c0                	test   %al,%al
40000b63:	0f 94 c0             	sete   %al
40000b66:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000b6a:	84 c0                	test   %al,%al
40000b6c:	74 07                	je     40000b75 <strchr+0x28>
			return NULL;
40000b6e:	b8 00 00 00 00       	mov    $0x0,%eax
40000b73:	eb 0e                	jmp    40000b83 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
40000b75:	8b 45 08             	mov    0x8(%ebp),%eax
40000b78:	0f b6 00             	movzbl (%eax),%eax
40000b7b:	3a 45 fc             	cmp    -0x4(%ebp),%al
40000b7e:	75 db                	jne    40000b5b <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
40000b80:	8b 45 08             	mov    0x8(%ebp),%eax
}
40000b83:	c9                   	leave  
40000b84:	c3                   	ret    

40000b85 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
40000b85:	55                   	push   %ebp
40000b86:	89 e5                	mov    %esp,%ebp
40000b88:	57                   	push   %edi
	char *p;

	if (n == 0)
40000b89:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000b8d:	75 05                	jne    40000b94 <memset+0xf>
		return v;
40000b8f:	8b 45 08             	mov    0x8(%ebp),%eax
40000b92:	eb 5c                	jmp    40000bf0 <memset+0x6b>
	if ((int)v%4 == 0 && n%4 == 0) {
40000b94:	8b 45 08             	mov    0x8(%ebp),%eax
40000b97:	83 e0 03             	and    $0x3,%eax
40000b9a:	85 c0                	test   %eax,%eax
40000b9c:	75 41                	jne    40000bdf <memset+0x5a>
40000b9e:	8b 45 10             	mov    0x10(%ebp),%eax
40000ba1:	83 e0 03             	and    $0x3,%eax
40000ba4:	85 c0                	test   %eax,%eax
40000ba6:	75 37                	jne    40000bdf <memset+0x5a>
		c &= 0xFF;
40000ba8:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
40000baf:	8b 45 0c             	mov    0xc(%ebp),%eax
40000bb2:	89 c2                	mov    %eax,%edx
40000bb4:	c1 e2 18             	shl    $0x18,%edx
40000bb7:	8b 45 0c             	mov    0xc(%ebp),%eax
40000bba:	c1 e0 10             	shl    $0x10,%eax
40000bbd:	09 c2                	or     %eax,%edx
40000bbf:	8b 45 0c             	mov    0xc(%ebp),%eax
40000bc2:	c1 e0 08             	shl    $0x8,%eax
40000bc5:	09 d0                	or     %edx,%eax
40000bc7:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
40000bca:	8b 45 10             	mov    0x10(%ebp),%eax
40000bcd:	89 c1                	mov    %eax,%ecx
40000bcf:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
40000bd2:	8b 55 08             	mov    0x8(%ebp),%edx
40000bd5:	8b 45 0c             	mov    0xc(%ebp),%eax
40000bd8:	89 d7                	mov    %edx,%edi
40000bda:	fc                   	cld    
40000bdb:	f3 ab                	rep stos %eax,%es:(%edi)
40000bdd:	eb 0e                	jmp    40000bed <memset+0x68>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
40000bdf:	8b 55 08             	mov    0x8(%ebp),%edx
40000be2:	8b 45 0c             	mov    0xc(%ebp),%eax
40000be5:	8b 4d 10             	mov    0x10(%ebp),%ecx
40000be8:	89 d7                	mov    %edx,%edi
40000bea:	fc                   	cld    
40000beb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
40000bed:	8b 45 08             	mov    0x8(%ebp),%eax
}
40000bf0:	5f                   	pop    %edi
40000bf1:	5d                   	pop    %ebp
40000bf2:	c3                   	ret    

40000bf3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
40000bf3:	55                   	push   %ebp
40000bf4:	89 e5                	mov    %esp,%ebp
40000bf6:	57                   	push   %edi
40000bf7:	56                   	push   %esi
40000bf8:	53                   	push   %ebx
40000bf9:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
40000bfc:	8b 45 0c             	mov    0xc(%ebp),%eax
40000bff:	89 45 f0             	mov    %eax,-0x10(%ebp)
	d = dst;
40000c02:	8b 45 08             	mov    0x8(%ebp),%eax
40000c05:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (s < d && s + n > d) {
40000c08:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000c0b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
40000c0e:	73 6d                	jae    40000c7d <memmove+0x8a>
40000c10:	8b 45 10             	mov    0x10(%ebp),%eax
40000c13:	8b 55 f0             	mov    -0x10(%ebp),%edx
40000c16:	01 d0                	add    %edx,%eax
40000c18:	3b 45 ec             	cmp    -0x14(%ebp),%eax
40000c1b:	76 60                	jbe    40000c7d <memmove+0x8a>
		s += n;
40000c1d:	8b 45 10             	mov    0x10(%ebp),%eax
40000c20:	01 45 f0             	add    %eax,-0x10(%ebp)
		d += n;
40000c23:	8b 45 10             	mov    0x10(%ebp),%eax
40000c26:	01 45 ec             	add    %eax,-0x14(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
40000c29:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000c2c:	83 e0 03             	and    $0x3,%eax
40000c2f:	85 c0                	test   %eax,%eax
40000c31:	75 2f                	jne    40000c62 <memmove+0x6f>
40000c33:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000c36:	83 e0 03             	and    $0x3,%eax
40000c39:	85 c0                	test   %eax,%eax
40000c3b:	75 25                	jne    40000c62 <memmove+0x6f>
40000c3d:	8b 45 10             	mov    0x10(%ebp),%eax
40000c40:	83 e0 03             	and    $0x3,%eax
40000c43:	85 c0                	test   %eax,%eax
40000c45:	75 1b                	jne    40000c62 <memmove+0x6f>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
40000c47:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000c4a:	83 e8 04             	sub    $0x4,%eax
40000c4d:	8b 55 f0             	mov    -0x10(%ebp),%edx
40000c50:	83 ea 04             	sub    $0x4,%edx
40000c53:	8b 4d 10             	mov    0x10(%ebp),%ecx
40000c56:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
40000c59:	89 c7                	mov    %eax,%edi
40000c5b:	89 d6                	mov    %edx,%esi
40000c5d:	fd                   	std    
40000c5e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
40000c60:	eb 18                	jmp    40000c7a <memmove+0x87>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
40000c62:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000c65:	8d 50 ff             	lea    -0x1(%eax),%edx
40000c68:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000c6b:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
40000c6e:	8b 45 10             	mov    0x10(%ebp),%eax
40000c71:	89 d7                	mov    %edx,%edi
40000c73:	89 de                	mov    %ebx,%esi
40000c75:	89 c1                	mov    %eax,%ecx
40000c77:	fd                   	std    
40000c78:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
40000c7a:	fc                   	cld    
40000c7b:	eb 45                	jmp    40000cc2 <memmove+0xcf>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
40000c7d:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000c80:	83 e0 03             	and    $0x3,%eax
40000c83:	85 c0                	test   %eax,%eax
40000c85:	75 2b                	jne    40000cb2 <memmove+0xbf>
40000c87:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000c8a:	83 e0 03             	and    $0x3,%eax
40000c8d:	85 c0                	test   %eax,%eax
40000c8f:	75 21                	jne    40000cb2 <memmove+0xbf>
40000c91:	8b 45 10             	mov    0x10(%ebp),%eax
40000c94:	83 e0 03             	and    $0x3,%eax
40000c97:	85 c0                	test   %eax,%eax
40000c99:	75 17                	jne    40000cb2 <memmove+0xbf>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
40000c9b:	8b 45 10             	mov    0x10(%ebp),%eax
40000c9e:	89 c1                	mov    %eax,%ecx
40000ca0:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
40000ca3:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000ca6:	8b 55 f0             	mov    -0x10(%ebp),%edx
40000ca9:	89 c7                	mov    %eax,%edi
40000cab:	89 d6                	mov    %edx,%esi
40000cad:	fc                   	cld    
40000cae:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
40000cb0:	eb 10                	jmp    40000cc2 <memmove+0xcf>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
40000cb2:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000cb5:	8b 55 f0             	mov    -0x10(%ebp),%edx
40000cb8:	8b 4d 10             	mov    0x10(%ebp),%ecx
40000cbb:	89 c7                	mov    %eax,%edi
40000cbd:	89 d6                	mov    %edx,%esi
40000cbf:	fc                   	cld    
40000cc0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
40000cc2:	8b 45 08             	mov    0x8(%ebp),%eax
}
40000cc5:	83 c4 10             	add    $0x10,%esp
40000cc8:	5b                   	pop    %ebx
40000cc9:	5e                   	pop    %esi
40000cca:	5f                   	pop    %edi
40000ccb:	5d                   	pop    %ebp
40000ccc:	c3                   	ret    

40000ccd <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
40000ccd:	55                   	push   %ebp
40000cce:	89 e5                	mov    %esp,%ebp
40000cd0:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
40000cd3:	8b 45 10             	mov    0x10(%ebp),%eax
40000cd6:	89 44 24 08          	mov    %eax,0x8(%esp)
40000cda:	8b 45 0c             	mov    0xc(%ebp),%eax
40000cdd:	89 44 24 04          	mov    %eax,0x4(%esp)
40000ce1:	8b 45 08             	mov    0x8(%ebp),%eax
40000ce4:	89 04 24             	mov    %eax,(%esp)
40000ce7:	e8 07 ff ff ff       	call   40000bf3 <memmove>
}
40000cec:	c9                   	leave  
40000ced:	c3                   	ret    

40000cee <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
40000cee:	55                   	push   %ebp
40000cef:	89 e5                	mov    %esp,%ebp
40000cf1:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
40000cf4:	8b 45 08             	mov    0x8(%ebp),%eax
40000cf7:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
40000cfa:	8b 45 0c             	mov    0xc(%ebp),%eax
40000cfd:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
40000d00:	eb 32                	jmp    40000d34 <memcmp+0x46>
		if (*s1 != *s2)
40000d02:	8b 45 fc             	mov    -0x4(%ebp),%eax
40000d05:	0f b6 10             	movzbl (%eax),%edx
40000d08:	8b 45 f8             	mov    -0x8(%ebp),%eax
40000d0b:	0f b6 00             	movzbl (%eax),%eax
40000d0e:	38 c2                	cmp    %al,%dl
40000d10:	74 1a                	je     40000d2c <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
40000d12:	8b 45 fc             	mov    -0x4(%ebp),%eax
40000d15:	0f b6 00             	movzbl (%eax),%eax
40000d18:	0f b6 d0             	movzbl %al,%edx
40000d1b:	8b 45 f8             	mov    -0x8(%ebp),%eax
40000d1e:	0f b6 00             	movzbl (%eax),%eax
40000d21:	0f b6 c0             	movzbl %al,%eax
40000d24:	89 d1                	mov    %edx,%ecx
40000d26:	29 c1                	sub    %eax,%ecx
40000d28:	89 c8                	mov    %ecx,%eax
40000d2a:	eb 1c                	jmp    40000d48 <memcmp+0x5a>
		s1++, s2++;
40000d2c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40000d30:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
40000d34:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000d38:	0f 95 c0             	setne  %al
40000d3b:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40000d3f:	84 c0                	test   %al,%al
40000d41:	75 bf                	jne    40000d02 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
40000d43:	b8 00 00 00 00       	mov    $0x0,%eax
}
40000d48:	c9                   	leave  
40000d49:	c3                   	ret    

40000d4a <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
40000d4a:	55                   	push   %ebp
40000d4b:	89 e5                	mov    %esp,%ebp
40000d4d:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
40000d50:	8b 45 10             	mov    0x10(%ebp),%eax
40000d53:	8b 55 08             	mov    0x8(%ebp),%edx
40000d56:	01 d0                	add    %edx,%eax
40000d58:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
40000d5b:	eb 16                	jmp    40000d73 <memchr+0x29>
		if (*(const unsigned char *) s == (unsigned char) c)
40000d5d:	8b 45 08             	mov    0x8(%ebp),%eax
40000d60:	0f b6 10             	movzbl (%eax),%edx
40000d63:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d66:	38 c2                	cmp    %al,%dl
40000d68:	75 05                	jne    40000d6f <memchr+0x25>
			return (void *) s;
40000d6a:	8b 45 08             	mov    0x8(%ebp),%eax
40000d6d:	eb 11                	jmp    40000d80 <memchr+0x36>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
40000d6f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000d73:	8b 45 08             	mov    0x8(%ebp),%eax
40000d76:	3b 45 fc             	cmp    -0x4(%ebp),%eax
40000d79:	72 e2                	jb     40000d5d <memchr+0x13>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
40000d7b:	b8 00 00 00 00       	mov    $0x0,%eax
}
40000d80:	c9                   	leave  
40000d81:	c3                   	ret    
40000d82:	66 90                	xchg   %ax,%ax

40000d84 <exit>:
#include <inc/assert.h>
#include <inc/string.h>

void gcc_noreturn
exit(int status)
{
40000d84:	55                   	push   %ebp
40000d85:	89 e5                	mov    %esp,%ebp
40000d87:	83 ec 18             	sub    $0x18,%esp
	// To exit a PIOS user process, by convention,
	// we just set our exit status in our filestate area
	// and return to our parent process.
	files->status = status;
40000d8a:	a1 48 34 00 40       	mov    0x40003448,%eax
40000d8f:	8b 55 08             	mov    0x8(%ebp),%edx
40000d92:	89 50 0c             	mov    %edx,0xc(%eax)
	files->exited = 1;
40000d95:	a1 48 34 00 40       	mov    0x40003448,%eax
40000d9a:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000da1:	b8 03 00 00 00       	mov    $0x3,%eax
40000da6:	cd 30                	int    $0x30
	sys_ret();
	panic("exit: sys_ret shouldn't have returned");
40000da8:	c7 44 24 08 94 33 00 	movl   $0x40003394,0x8(%esp)
40000daf:	40 
40000db0:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
40000db7:	00 
40000db8:	c7 04 24 ba 33 00 40 	movl   $0x400033ba,(%esp)
40000dbf:	e8 9c 01 00 00       	call   40000f60 <debug_panic>

40000dc4 <abort>:
}

void gcc_noreturn
abort(void)
{
40000dc4:	55                   	push   %ebp
40000dc5:	89 e5                	mov    %esp,%ebp
40000dc7:	83 ec 18             	sub    $0x18,%esp
	exit(EXIT_FAILURE);
40000dca:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
40000dd1:	e8 ae ff ff ff       	call   40000d84 <exit>
40000dd6:	66 90                	xchg   %ax,%ax

40000dd8 <writebuf>:
};


static void
writebuf(struct printbuf *b)
{
40000dd8:	55                   	push   %ebp
40000dd9:	89 e5                	mov    %esp,%ebp
40000ddb:	83 ec 28             	sub    $0x28,%esp
	if (!b->err) {
40000dde:	8b 45 08             	mov    0x8(%ebp),%eax
40000de1:	8b 40 0c             	mov    0xc(%eax),%eax
40000de4:	85 c0                	test   %eax,%eax
40000de6:	75 56                	jne    40000e3e <writebuf+0x66>
		size_t result = fwrite(b->buf, 1, b->idx, b->fh);
40000de8:	8b 45 08             	mov    0x8(%ebp),%eax
40000deb:	8b 10                	mov    (%eax),%edx
40000ded:	8b 45 08             	mov    0x8(%ebp),%eax
40000df0:	8b 40 04             	mov    0x4(%eax),%eax
40000df3:	8b 4d 08             	mov    0x8(%ebp),%ecx
40000df6:	83 c1 10             	add    $0x10,%ecx
40000df9:	89 54 24 0c          	mov    %edx,0xc(%esp)
40000dfd:	89 44 24 08          	mov    %eax,0x8(%esp)
40000e01:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40000e08:	00 
40000e09:	89 0c 24             	mov    %ecx,(%esp)
40000e0c:	e8 51 1e 00 00       	call   40002c62 <fwrite>
40000e11:	89 45 f4             	mov    %eax,-0xc(%ebp)
		b->result += result;
40000e14:	8b 45 08             	mov    0x8(%ebp),%eax
40000e17:	8b 40 08             	mov    0x8(%eax),%eax
40000e1a:	89 c2                	mov    %eax,%edx
40000e1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000e1f:	01 d0                	add    %edx,%eax
40000e21:	89 c2                	mov    %eax,%edx
40000e23:	8b 45 08             	mov    0x8(%ebp),%eax
40000e26:	89 50 08             	mov    %edx,0x8(%eax)
		if (result != b->idx) // error, or wrote less than supplied
40000e29:	8b 45 08             	mov    0x8(%ebp),%eax
40000e2c:	8b 40 04             	mov    0x4(%eax),%eax
40000e2f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40000e32:	74 0a                	je     40000e3e <writebuf+0x66>
			b->err = 1;
40000e34:	8b 45 08             	mov    0x8(%ebp),%eax
40000e37:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
	}
}
40000e3e:	c9                   	leave  
40000e3f:	c3                   	ret    

40000e40 <putch>:

static void
putch(int ch, void *thunk)
{
40000e40:	55                   	push   %ebp
40000e41:	89 e5                	mov    %esp,%ebp
40000e43:	83 ec 28             	sub    $0x28,%esp
	struct printbuf *b = (struct printbuf *) thunk;
40000e46:	8b 45 0c             	mov    0xc(%ebp),%eax
40000e49:	89 45 f4             	mov    %eax,-0xc(%ebp)
	b->buf[b->idx++] = ch;
40000e4c:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000e4f:	8b 40 04             	mov    0x4(%eax),%eax
40000e52:	8b 55 08             	mov    0x8(%ebp),%edx
40000e55:	89 d1                	mov    %edx,%ecx
40000e57:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000e5a:	88 4c 02 10          	mov    %cl,0x10(%edx,%eax,1)
40000e5e:	8d 50 01             	lea    0x1(%eax),%edx
40000e61:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000e64:	89 50 04             	mov    %edx,0x4(%eax)
	if (b->idx == 256) {
40000e67:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000e6a:	8b 40 04             	mov    0x4(%eax),%eax
40000e6d:	3d 00 01 00 00       	cmp    $0x100,%eax
40000e72:	75 15                	jne    40000e89 <putch+0x49>
		writebuf(b);
40000e74:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000e77:	89 04 24             	mov    %eax,(%esp)
40000e7a:	e8 59 ff ff ff       	call   40000dd8 <writebuf>
		b->idx = 0;
40000e7f:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000e82:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	}
}
40000e89:	c9                   	leave  
40000e8a:	c3                   	ret    

40000e8b <vfprintf>:

int
vfprintf(FILE *fh, const char *fmt, va_list ap)
{
40000e8b:	55                   	push   %ebp
40000e8c:	89 e5                	mov    %esp,%ebp
40000e8e:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.fh = fh;
40000e94:	8b 45 08             	mov    0x8(%ebp),%eax
40000e97:	89 85 e8 fe ff ff    	mov    %eax,-0x118(%ebp)
	b.idx = 0;
40000e9d:	c7 85 ec fe ff ff 00 	movl   $0x0,-0x114(%ebp)
40000ea4:	00 00 00 
	b.result = 0;
40000ea7:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
40000eae:	00 00 00 
	b.err = 0;
40000eb1:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
40000eb8:	00 00 00 
	vprintfmt(putch, &b, fmt, ap);
40000ebb:	8b 45 10             	mov    0x10(%ebp),%eax
40000ebe:	89 44 24 0c          	mov    %eax,0xc(%esp)
40000ec2:	8b 45 0c             	mov    0xc(%ebp),%eax
40000ec5:	89 44 24 08          	mov    %eax,0x8(%esp)
40000ec9:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
40000ecf:	89 44 24 04          	mov    %eax,0x4(%esp)
40000ed3:	c7 04 24 40 0e 00 40 	movl   $0x40000e40,(%esp)
40000eda:	e8 52 f7 ff ff       	call   40000631 <vprintfmt>
	if (b.idx > 0)
40000edf:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
40000ee5:	85 c0                	test   %eax,%eax
40000ee7:	7e 0e                	jle    40000ef7 <vfprintf+0x6c>
		writebuf(&b);
40000ee9:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
40000eef:	89 04 24             	mov    %eax,(%esp)
40000ef2:	e8 e1 fe ff ff       	call   40000dd8 <writebuf>

	return b.result;
40000ef7:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
}
40000efd:	c9                   	leave  
40000efe:	c3                   	ret    

40000eff <fprintf>:

int
fprintf(FILE *fh, const char *fmt, ...)
{
40000eff:	55                   	push   %ebp
40000f00:	89 e5                	mov    %esp,%ebp
40000f02:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
40000f05:	8d 45 0c             	lea    0xc(%ebp),%eax
40000f08:	83 c0 04             	add    $0x4,%eax
40000f0b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vfprintf(fh, fmt, ap);
40000f0e:	8b 45 0c             	mov    0xc(%ebp),%eax
40000f11:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000f14:	89 54 24 08          	mov    %edx,0x8(%esp)
40000f18:	89 44 24 04          	mov    %eax,0x4(%esp)
40000f1c:	8b 45 08             	mov    0x8(%ebp),%eax
40000f1f:	89 04 24             	mov    %eax,(%esp)
40000f22:	e8 64 ff ff ff       	call   40000e8b <vfprintf>
40000f27:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
40000f2a:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40000f2d:	c9                   	leave  
40000f2e:	c3                   	ret    

40000f2f <printf>:

int
printf(const char *fmt, ...)
{
40000f2f:	55                   	push   %ebp
40000f30:	89 e5                	mov    %esp,%ebp
40000f32:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
40000f35:	8d 45 0c             	lea    0xc(%ebp),%eax
40000f38:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vfprintf(stdout, fmt, ap);
40000f3b:	8b 55 08             	mov    0x8(%ebp),%edx
40000f3e:	a1 98 37 00 40       	mov    0x40003798,%eax
40000f43:	8b 4d f4             	mov    -0xc(%ebp),%ecx
40000f46:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40000f4a:	89 54 24 04          	mov    %edx,0x4(%esp)
40000f4e:	89 04 24             	mov    %eax,(%esp)
40000f51:	e8 35 ff ff ff       	call   40000e8b <vfprintf>
40000f56:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
40000f59:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40000f5c:	c9                   	leave  
40000f5d:	c3                   	ret    
40000f5e:	66 90                	xchg   %ax,%ax

40000f60 <debug_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: <message>", then causes a breakpoint exception.
 */
void
debug_panic(const char *file, int line, const char *fmt,...)
{
40000f60:	55                   	push   %ebp
40000f61:	89 e5                	mov    %esp,%ebp
40000f63:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	va_start(ap, fmt);
40000f66:	8d 45 10             	lea    0x10(%ebp),%eax
40000f69:	83 c0 04             	add    $0x4,%eax
40000f6c:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Print the panic message
	if (argv0)
40000f6f:	a1 60 51 00 40       	mov    0x40005160,%eax
40000f74:	85 c0                	test   %eax,%eax
40000f76:	74 15                	je     40000f8d <debug_panic+0x2d>
		cprintf("%s: ", argv0);
40000f78:	a1 60 51 00 40       	mov    0x40005160,%eax
40000f7d:	89 44 24 04          	mov    %eax,0x4(%esp)
40000f81:	c7 04 24 c8 33 00 40 	movl   $0x400033c8,(%esp)
40000f88:	e8 5b f3 ff ff       	call   400002e8 <cprintf>
	cprintf("user panic at %s:%d: ", file, line);
40000f8d:	8b 45 0c             	mov    0xc(%ebp),%eax
40000f90:	89 44 24 08          	mov    %eax,0x8(%esp)
40000f94:	8b 45 08             	mov    0x8(%ebp),%eax
40000f97:	89 44 24 04          	mov    %eax,0x4(%esp)
40000f9b:	c7 04 24 cd 33 00 40 	movl   $0x400033cd,(%esp)
40000fa2:	e8 41 f3 ff ff       	call   400002e8 <cprintf>
	vcprintf(fmt, ap);
40000fa7:	8b 45 10             	mov    0x10(%ebp),%eax
40000faa:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000fad:	89 54 24 04          	mov    %edx,0x4(%esp)
40000fb1:	89 04 24             	mov    %eax,(%esp)
40000fb4:	e8 c7 f2 ff ff       	call   40000280 <vcprintf>
	cprintf("\n");
40000fb9:	c7 04 24 e3 33 00 40 	movl   $0x400033e3,(%esp)
40000fc0:	e8 23 f3 ff ff       	call   400002e8 <cprintf>

	abort();
40000fc5:	e8 fa fd ff ff       	call   40000dc4 <abort>

40000fca <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
40000fca:	55                   	push   %ebp
40000fcb:	89 e5                	mov    %esp,%ebp
40000fcd:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
40000fd0:	8d 45 10             	lea    0x10(%ebp),%eax
40000fd3:	83 c0 04             	add    $0x4,%eax
40000fd6:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("user warning at %s:%d: ", file, line);
40000fd9:	8b 45 0c             	mov    0xc(%ebp),%eax
40000fdc:	89 44 24 08          	mov    %eax,0x8(%esp)
40000fe0:	8b 45 08             	mov    0x8(%ebp),%eax
40000fe3:	89 44 24 04          	mov    %eax,0x4(%esp)
40000fe7:	c7 04 24 e5 33 00 40 	movl   $0x400033e5,(%esp)
40000fee:	e8 f5 f2 ff ff       	call   400002e8 <cprintf>
	vcprintf(fmt, ap);
40000ff3:	8b 45 10             	mov    0x10(%ebp),%eax
40000ff6:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000ff9:	89 54 24 04          	mov    %edx,0x4(%esp)
40000ffd:	89 04 24             	mov    %eax,(%esp)
40001000:	e8 7b f2 ff ff       	call   40000280 <vcprintf>
	cprintf("\n");
40001005:	c7 04 24 e3 33 00 40 	movl   $0x400033e3,(%esp)
4000100c:	e8 d7 f2 ff ff       	call   400002e8 <cprintf>
	va_end(ap);
}
40001011:	c9                   	leave  
40001012:	c3                   	ret    

40001013 <debug_dump>:

// Dump a block of memory as 32-bit words and ASCII bytes
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
40001013:	55                   	push   %ebp
40001014:	89 e5                	mov    %esp,%ebp
40001016:	56                   	push   %esi
40001017:	53                   	push   %ebx
40001018:	81 ec a0 00 00 00    	sub    $0xa0,%esp
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
4000101e:	8b 55 14             	mov    0x14(%ebp),%edx
40001021:	8b 45 10             	mov    0x10(%ebp),%eax
40001024:	01 d0                	add    %edx,%eax
40001026:	89 44 24 10          	mov    %eax,0x10(%esp)
4000102a:	8b 45 10             	mov    0x10(%ebp),%eax
4000102d:	89 44 24 0c          	mov    %eax,0xc(%esp)
40001031:	8b 45 0c             	mov    0xc(%ebp),%eax
40001034:	89 44 24 08          	mov    %eax,0x8(%esp)
40001038:	8b 45 08             	mov    0x8(%ebp),%eax
4000103b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000103f:	c7 04 24 00 34 00 40 	movl   $0x40003400,(%esp)
40001046:	e8 9d f2 ff ff       	call   400002e8 <cprintf>
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
4000104b:	8b 45 14             	mov    0x14(%ebp),%eax
4000104e:	83 c0 0f             	add    $0xf,%eax
40001051:	83 e0 f0             	and    $0xfffffff0,%eax
40001054:	89 45 14             	mov    %eax,0x14(%ebp)
40001057:	e9 bb 00 00 00       	jmp    40001117 <debug_dump+0x104>
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
4000105c:	8b 45 10             	mov    0x10(%ebp),%eax
4000105f:	89 45 f0             	mov    %eax,-0x10(%ebp)
		for (i = 0; i < 16; i++)
40001062:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
40001069:	eb 4d                	jmp    400010b8 <debug_dump+0xa5>
			buf[i] = isprint(c[i]) ? c[i] : '.';
4000106b:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000106e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001071:	01 d0                	add    %edx,%eax
40001073:	0f b6 00             	movzbl (%eax),%eax
40001076:	0f b6 c0             	movzbl %al,%eax
40001079:	89 45 e8             	mov    %eax,-0x18(%ebp)
static gcc_inline int isalnum(int c)	{ return isalpha(c) || isdigit(c); }
static gcc_inline int iscntrl(int c)	{ return c < ' '; }
static gcc_inline int isblank(int c)	{ return c == ' ' || c == '\t'; }
static gcc_inline int isspace(int c)	{ return c == ' '
						|| (c >= '\t' && c <= '\r'); }
static gcc_inline int isprint(int c)	{ return c >= ' ' && c <= '~'; }
4000107c:	83 7d e8 1f          	cmpl   $0x1f,-0x18(%ebp)
40001080:	7e 0d                	jle    4000108f <debug_dump+0x7c>
40001082:	83 7d e8 7e          	cmpl   $0x7e,-0x18(%ebp)
40001086:	7f 07                	jg     4000108f <debug_dump+0x7c>
40001088:	b8 01 00 00 00       	mov    $0x1,%eax
4000108d:	eb 05                	jmp    40001094 <debug_dump+0x81>
4000108f:	b8 00 00 00 00       	mov    $0x0,%eax
40001094:	85 c0                	test   %eax,%eax
40001096:	74 0d                	je     400010a5 <debug_dump+0x92>
40001098:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000109b:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000109e:	01 d0                	add    %edx,%eax
400010a0:	0f b6 00             	movzbl (%eax),%eax
400010a3:	eb 05                	jmp    400010aa <debug_dump+0x97>
400010a5:	b8 2e 00 00 00       	mov    $0x2e,%eax
400010aa:	8d 4d 84             	lea    -0x7c(%ebp),%ecx
400010ad:	8b 55 f4             	mov    -0xc(%ebp),%edx
400010b0:	01 ca                	add    %ecx,%edx
400010b2:	88 02                	mov    %al,(%edx)
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
		for (i = 0; i < 16; i++)
400010b4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
400010b8:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
400010bc:	7e ad                	jle    4000106b <debug_dump+0x58>
			buf[i] = isprint(c[i]) ? c[i] : '.';
		buf[16] = 0;
400010be:	c6 45 94 00          	movb   $0x0,-0x6c(%ebp)

		// Hex words
		const uint32_t *v = ptr;
400010c2:	8b 45 10             	mov    0x10(%ebp),%eax
400010c5:	89 45 ec             	mov    %eax,-0x14(%ebp)

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
			ptr, v[0], v[1], v[2], v[3], buf);
400010c8:	8b 45 ec             	mov    -0x14(%ebp),%eax
400010cb:	83 c0 0c             	add    $0xc,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
400010ce:	8b 18                	mov    (%eax),%ebx
			ptr, v[0], v[1], v[2], v[3], buf);
400010d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
400010d3:	83 c0 08             	add    $0x8,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
400010d6:	8b 08                	mov    (%eax),%ecx
			ptr, v[0], v[1], v[2], v[3], buf);
400010d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
400010db:	83 c0 04             	add    $0x4,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
400010de:	8b 10                	mov    (%eax),%edx
400010e0:	8b 45 ec             	mov    -0x14(%ebp),%eax
400010e3:	8b 00                	mov    (%eax),%eax
			ptr, v[0], v[1], v[2], v[3], buf);
400010e5:	8d 75 84             	lea    -0x7c(%ebp),%esi
400010e8:	89 74 24 18          	mov    %esi,0x18(%esp)

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
400010ec:	89 5c 24 14          	mov    %ebx,0x14(%esp)
400010f0:	89 4c 24 10          	mov    %ecx,0x10(%esp)
400010f4:	89 54 24 0c          	mov    %edx,0xc(%esp)
400010f8:	89 44 24 08          	mov    %eax,0x8(%esp)
400010fc:	8b 45 10             	mov    0x10(%ebp),%eax
400010ff:	89 44 24 04          	mov    %eax,0x4(%esp)
40001103:	c7 04 24 29 34 00 40 	movl   $0x40003429,(%esp)
4000110a:	e8 d9 f1 ff ff       	call   400002e8 <cprintf>
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
4000110f:	83 6d 14 10          	subl   $0x10,0x14(%ebp)
40001113:	83 45 10 10          	addl   $0x10,0x10(%ebp)
40001117:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
4000111b:	0f 8f 3b ff ff ff    	jg     4000105c <debug_dump+0x49>

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
			ptr, v[0], v[1], v[2], v[3], buf);
	}
}
40001121:	81 c4 a0 00 00 00    	add    $0xa0,%esp
40001127:	5b                   	pop    %ebx
40001128:	5e                   	pop    %esi
40001129:	5d                   	pop    %ebp
4000112a:	c3                   	ret    
4000112b:	90                   	nop

4000112c <cputs>:

#include <inc/stdio.h>
#include <inc/syscall.h>

void cputs(const char *str)
{
4000112c:	55                   	push   %ebp
4000112d:	89 e5                	mov    %esp,%ebp
4000112f:	53                   	push   %ebx
40001130:	83 ec 10             	sub    $0x10,%esp
40001133:	8b 45 08             	mov    0x8(%ebp),%eax
40001136:	89 45 f8             	mov    %eax,-0x8(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40001139:	b8 00 00 00 00       	mov    $0x0,%eax
4000113e:	8b 55 f8             	mov    -0x8(%ebp),%edx
40001141:	89 d3                	mov    %edx,%ebx
40001143:	cd 30                	int    $0x30
	sys_cputs(str);
}
40001145:	83 c4 10             	add    $0x10,%esp
40001148:	5b                   	pop    %ebx
40001149:	5d                   	pop    %ebp
4000114a:	c3                   	ret    
4000114b:	90                   	nop

4000114c <fileino_alloc>:

// Find and return the index of a currently unused file inode in this process.
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_alloc(void)
{
4000114c:	55                   	push   %ebp
4000114d:	89 e5                	mov    %esp,%ebp
4000114f:	83 ec 28             	sub    $0x28,%esp
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40001152:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
40001159:	eb 24                	jmp    4000117f <fileino_alloc+0x33>
		if (files->fi[i].de.d_name[0] == 0)
4000115b:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40001161:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001164:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001167:	01 d0                	add    %edx,%eax
40001169:	05 10 10 00 00       	add    $0x1010,%eax
4000116e:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40001172:	84 c0                	test   %al,%al
40001174:	75 05                	jne    4000117b <fileino_alloc+0x2f>
			return i;
40001176:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001179:	eb 39                	jmp    400011b4 <fileino_alloc+0x68>
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_alloc(void)
{
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
4000117b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
4000117f:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
40001186:	7e d3                	jle    4000115b <fileino_alloc+0xf>
		if (files->fi[i].de.d_name[0] == 0)
			return i;

	warn("fileino_alloc: no free inodes\n");
40001188:	c7 44 24 08 4c 34 00 	movl   $0x4000344c,0x8(%esp)
4000118f:	40 
40001190:	c7 44 24 04 29 00 00 	movl   $0x29,0x4(%esp)
40001197:	00 
40001198:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
4000119f:	e8 26 fe ff ff       	call   40000fca <debug_warn>
	errno = ENOSPC;
400011a4:	a1 48 34 00 40       	mov    0x40003448,%eax
400011a9:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
	return -1;
400011af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
400011b4:	c9                   	leave  
400011b5:	c3                   	ret    

400011b6 <fileino_create>:
// Returns the index of the inode found or created.
// A newly-created inode is left in the "deleted" state, with mode == 0.
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_create(filestate *fs, int dino, const char *name)
{
400011b6:	55                   	push   %ebp
400011b7:	89 e5                	mov    %esp,%ebp
400011b9:	83 ec 28             	sub    $0x28,%esp
	assert(dino != 0);
400011bc:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400011c0:	75 24                	jne    400011e6 <fileino_create+0x30>
400011c2:	c7 44 24 0c 76 34 00 	movl   $0x40003476,0xc(%esp)
400011c9:	40 
400011ca:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
400011d1:	40 
400011d2:	c7 44 24 04 35 00 00 	movl   $0x35,0x4(%esp)
400011d9:	00 
400011da:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
400011e1:	e8 7a fd ff ff       	call   40000f60 <debug_panic>
	assert(name != NULL && name[0] != 0);
400011e6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400011ea:	74 0a                	je     400011f6 <fileino_create+0x40>
400011ec:	8b 45 10             	mov    0x10(%ebp),%eax
400011ef:	0f b6 00             	movzbl (%eax),%eax
400011f2:	84 c0                	test   %al,%al
400011f4:	75 24                	jne    4000121a <fileino_create+0x64>
400011f6:	c7 44 24 0c 95 34 00 	movl   $0x40003495,0xc(%esp)
400011fd:	40 
400011fe:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
40001205:	40 
40001206:	c7 44 24 04 36 00 00 	movl   $0x36,0x4(%esp)
4000120d:	00 
4000120e:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
40001215:	e8 46 fd ff ff       	call   40000f60 <debug_panic>
	assert(strlen(name) <= NAME_MAX);
4000121a:	8b 45 10             	mov    0x10(%ebp),%eax
4000121d:	89 04 24             	mov    %eax,(%esp)
40001220:	e8 a3 f7 ff ff       	call   400009c8 <strlen>
40001225:	83 f8 3f             	cmp    $0x3f,%eax
40001228:	7e 24                	jle    4000124e <fileino_create+0x98>
4000122a:	c7 44 24 0c b2 34 00 	movl   $0x400034b2,0xc(%esp)
40001231:	40 
40001232:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
40001239:	40 
4000123a:	c7 44 24 04 37 00 00 	movl   $0x37,0x4(%esp)
40001241:	00 
40001242:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
40001249:	e8 12 fd ff ff       	call   40000f60 <debug_panic>

	// First see if an inode already exists for this directory and name.
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
4000124e:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
40001255:	eb 4a                	jmp    400012a1 <fileino_create+0xeb>
		if (fs->fi[i].dino == dino
40001257:	8b 55 08             	mov    0x8(%ebp),%edx
4000125a:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000125d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001260:	01 d0                	add    %edx,%eax
40001262:	05 10 10 00 00       	add    $0x1010,%eax
40001267:	8b 00                	mov    (%eax),%eax
40001269:	3b 45 0c             	cmp    0xc(%ebp),%eax
4000126c:	75 2f                	jne    4000129d <fileino_create+0xe7>
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
4000126e:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001271:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001274:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
4000127a:	8b 45 08             	mov    0x8(%ebp),%eax
4000127d:	01 d0                	add    %edx,%eax
4000127f:	8d 50 04             	lea    0x4(%eax),%edx
40001282:	8b 45 10             	mov    0x10(%ebp),%eax
40001285:	89 44 24 04          	mov    %eax,0x4(%esp)
40001289:	89 14 24             	mov    %edx,(%esp)
4000128c:	e8 23 f8 ff ff       	call   40000ab4 <strcmp>
40001291:	85 c0                	test   %eax,%eax
40001293:	75 08                	jne    4000129d <fileino_create+0xe7>
			return i;
40001295:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001298:	e9 a5 00 00 00       	jmp    40001342 <fileino_create+0x18c>
	assert(name != NULL && name[0] != 0);
	assert(strlen(name) <= NAME_MAX);

	// First see if an inode already exists for this directory and name.
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
4000129d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
400012a1:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
400012a8:	7e ad                	jle    40001257 <fileino_create+0xa1>
		if (fs->fi[i].dino == dino
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
			return i;

	// No inode allocated to this name - find a free one to allocate.
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
400012aa:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
400012b1:	eb 5a                	jmp    4000130d <fileino_create+0x157>
		if (fs->fi[i].de.d_name[0] == 0) {
400012b3:	8b 55 08             	mov    0x8(%ebp),%edx
400012b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
400012b9:	6b c0 5c             	imul   $0x5c,%eax,%eax
400012bc:	01 d0                	add    %edx,%eax
400012be:	05 10 10 00 00       	add    $0x1010,%eax
400012c3:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400012c7:	84 c0                	test   %al,%al
400012c9:	75 3e                	jne    40001309 <fileino_create+0x153>
			fs->fi[i].dino = dino;
400012cb:	8b 55 08             	mov    0x8(%ebp),%edx
400012ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
400012d1:	6b c0 5c             	imul   $0x5c,%eax,%eax
400012d4:	01 d0                	add    %edx,%eax
400012d6:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400012dc:	8b 45 0c             	mov    0xc(%ebp),%eax
400012df:	89 02                	mov    %eax,(%edx)
			strcpy(fs->fi[i].de.d_name, name);
400012e1:	8b 45 f4             	mov    -0xc(%ebp),%eax
400012e4:	6b c0 5c             	imul   $0x5c,%eax,%eax
400012e7:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400012ed:	8b 45 08             	mov    0x8(%ebp),%eax
400012f0:	01 d0                	add    %edx,%eax
400012f2:	8d 50 04             	lea    0x4(%eax),%edx
400012f5:	8b 45 10             	mov    0x10(%ebp),%eax
400012f8:	89 44 24 04          	mov    %eax,0x4(%esp)
400012fc:	89 14 24             	mov    %edx,(%esp)
400012ff:	e8 ea f6 ff ff       	call   400009ee <strcpy>
			return i;
40001304:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001307:	eb 39                	jmp    40001342 <fileino_create+0x18c>
		if (fs->fi[i].dino == dino
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
			return i;

	// No inode allocated to this name - find a free one to allocate.
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40001309:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
4000130d:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
40001314:	7e 9d                	jle    400012b3 <fileino_create+0xfd>
			fs->fi[i].dino = dino;
			strcpy(fs->fi[i].de.d_name, name);
			return i;
		}

	warn("fileino_create: no free inodes\n");
40001316:	c7 44 24 08 cc 34 00 	movl   $0x400034cc,0x8(%esp)
4000131d:	40 
4000131e:	c7 44 24 04 48 00 00 	movl   $0x48,0x4(%esp)
40001325:	00 
40001326:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
4000132d:	e8 98 fc ff ff       	call   40000fca <debug_warn>
	errno = ENOSPC;
40001332:	a1 48 34 00 40       	mov    0x40003448,%eax
40001337:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
	return -1;
4000133d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
40001342:	c9                   	leave  
40001343:	c3                   	ret    

40001344 <fileino_read>:
// The number of elements returned is normally equal to the 'count' parameter,
// but may be less (without resulting in an error)
// if the file is not large enough to read that many elements.
ssize_t
fileino_read(int ino, off_t ofs, void *buf, size_t eltsize, size_t count)
{
40001344:	55                   	push   %ebp
40001345:	89 e5                	mov    %esp,%ebp
40001347:	83 ec 28             	sub    $0x28,%esp
	assert(fileino_isreg(ino));
4000134a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
4000134e:	7e 45                	jle    40001395 <fileino_read+0x51>
40001350:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40001357:	7f 3c                	jg     40001395 <fileino_read+0x51>
40001359:	8b 15 48 34 00 40    	mov    0x40003448,%edx
4000135f:	8b 45 08             	mov    0x8(%ebp),%eax
40001362:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001365:	01 d0                	add    %edx,%eax
40001367:	05 10 10 00 00       	add    $0x1010,%eax
4000136c:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40001370:	84 c0                	test   %al,%al
40001372:	74 21                	je     40001395 <fileino_read+0x51>
40001374:	8b 15 48 34 00 40    	mov    0x40003448,%edx
4000137a:	8b 45 08             	mov    0x8(%ebp),%eax
4000137d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001380:	01 d0                	add    %edx,%eax
40001382:	05 58 10 00 00       	add    $0x1058,%eax
40001387:	8b 00                	mov    (%eax),%eax
40001389:	25 00 70 00 00       	and    $0x7000,%eax
4000138e:	3d 00 10 00 00       	cmp    $0x1000,%eax
40001393:	74 24                	je     400013b9 <fileino_read+0x75>
40001395:	c7 44 24 0c ec 34 00 	movl   $0x400034ec,0xc(%esp)
4000139c:	40 
4000139d:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
400013a4:	40 
400013a5:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
400013ac:	00 
400013ad:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
400013b4:	e8 a7 fb ff ff       	call   40000f60 <debug_panic>
	assert(ofs >= 0);
400013b9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400013bd:	79 24                	jns    400013e3 <fileino_read+0x9f>
400013bf:	c7 44 24 0c ff 34 00 	movl   $0x400034ff,0xc(%esp)
400013c6:	40 
400013c7:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
400013ce:	40 
400013cf:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
400013d6:	00 
400013d7:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
400013de:	e8 7d fb ff ff       	call   40000f60 <debug_panic>
	assert(eltsize > 0);
400013e3:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
400013e7:	75 24                	jne    4000140d <fileino_read+0xc9>
400013e9:	c7 44 24 0c 08 35 00 	movl   $0x40003508,0xc(%esp)
400013f0:	40 
400013f1:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
400013f8:	40 
400013f9:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
40001400:	00 
40001401:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
40001408:	e8 53 fb ff ff       	call   40000f60 <debug_panic>

	ssize_t return_number = 0;
4000140d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	fileinode *fi = &files->fi[ino];
40001414:	a1 48 34 00 40       	mov    0x40003448,%eax
40001419:	8b 55 08             	mov    0x8(%ebp),%edx
4000141c:	6b d2 5c             	imul   $0x5c,%edx,%edx
4000141f:	81 c2 10 10 00 00    	add    $0x1010,%edx
40001425:	01 d0                	add    %edx,%eax
40001427:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint32_t tmp_ofs = ofs;
4000142a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000142d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint8_t* read_pointer = FILEDATA(ino) + ofs;
40001430:	8b 45 08             	mov    0x8(%ebp),%eax
40001433:	c1 e0 16             	shl    $0x16,%eax
40001436:	89 c2                	mov    %eax,%edx
40001438:	8b 45 0c             	mov    0xc(%ebp),%eax
4000143b:	01 d0                	add    %edx,%eax
4000143d:	05 00 00 00 80       	add    $0x80000000,%eax
40001442:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(fi->size <= FILE_MAXSIZE);
40001445:	8b 45 e8             	mov    -0x18(%ebp),%eax
40001448:	8b 40 4c             	mov    0x4c(%eax),%eax
4000144b:	3d 00 00 40 00       	cmp    $0x400000,%eax
40001450:	76 7a                	jbe    400014cc <fileino_read+0x188>
40001452:	c7 44 24 0c 14 35 00 	movl   $0x40003514,0xc(%esp)
40001459:	40 
4000145a:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
40001461:	40 
40001462:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
40001469:	00 
4000146a:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
40001471:	e8 ea fa ff ff       	call   40000f60 <debug_panic>
	// Lab 4: insert your file reading code here.
	//warn("fileino_read() not implemented");
	while(count > 0){
		if(tmp_ofs >= fi->size){
40001476:	8b 45 e8             	mov    -0x18(%ebp),%eax
40001479:	8b 40 4c             	mov    0x4c(%eax),%eax
4000147c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
4000147f:	77 18                	ja     40001499 <fileino_read+0x155>
			if(fi->mode & S_IFPART)
40001481:	8b 45 e8             	mov    -0x18(%ebp),%eax
40001484:	8b 40 48             	mov    0x48(%eax),%eax
40001487:	25 00 80 00 00       	and    $0x8000,%eax
4000148c:	85 c0                	test   %eax,%eax
4000148e:	74 44                	je     400014d4 <fileino_read+0x190>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001490:	b8 03 00 00 00       	mov    $0x3,%eax
40001495:	cd 30                	int    $0x30
40001497:	eb 33                	jmp    400014cc <fileino_read+0x188>
				sys_ret();
			else
				break;
		}else{
			memcpy(buf, read_pointer, eltsize);
40001499:	8b 45 14             	mov    0x14(%ebp),%eax
4000149c:	89 44 24 08          	mov    %eax,0x8(%esp)
400014a0:	8b 45 ec             	mov    -0x14(%ebp),%eax
400014a3:	89 44 24 04          	mov    %eax,0x4(%esp)
400014a7:	8b 45 10             	mov    0x10(%ebp),%eax
400014aa:	89 04 24             	mov    %eax,(%esp)
400014ad:	e8 1b f8 ff ff       	call   40000ccd <memcpy>
			return_number++;
400014b2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
			buf += eltsize;
400014b6:	8b 45 14             	mov    0x14(%ebp),%eax
400014b9:	01 45 10             	add    %eax,0x10(%ebp)
			read_pointer += eltsize;
400014bc:	8b 45 14             	mov    0x14(%ebp),%eax
400014bf:	01 45 ec             	add    %eax,-0x14(%ebp)
			tmp_ofs += eltsize;
400014c2:	8b 45 14             	mov    0x14(%ebp),%eax
400014c5:	01 45 f0             	add    %eax,-0x10(%ebp)
			count--;
400014c8:	83 6d 18 01          	subl   $0x1,0x18(%ebp)
	uint32_t tmp_ofs = ofs;
	uint8_t* read_pointer = FILEDATA(ino) + ofs;
	assert(fi->size <= FILE_MAXSIZE);
	// Lab 4: insert your file reading code here.
	//warn("fileino_read() not implemented");
	while(count > 0){
400014cc:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
400014d0:	75 a4                	jne    40001476 <fileino_read+0x132>
400014d2:	eb 01                	jmp    400014d5 <fileino_read+0x191>
		if(tmp_ofs >= fi->size){
			if(fi->mode & S_IFPART)
				sys_ret();
			else
				break;
400014d4:	90                   	nop
			read_pointer += eltsize;
			tmp_ofs += eltsize;
			count--;
		}
	}
	return return_number;
400014d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
//	errno = EINVAL;
//	return -1;
}
400014d8:	c9                   	leave  
400014d9:	c3                   	ret    

400014da <fileino_write>:
// one particular reason an error might occur is if an application
// tries to grow a file beyond this maximum file size,
// in which case this function generates the EFBIG error.
ssize_t
fileino_write(int ino, off_t ofs, const void *buf, size_t eltsize, size_t count)
{
400014da:	55                   	push   %ebp
400014db:	89 e5                	mov    %esp,%ebp
400014dd:	57                   	push   %edi
400014de:	56                   	push   %esi
400014df:	53                   	push   %ebx
400014e0:	83 ec 6c             	sub    $0x6c,%esp
	assert(fileino_isreg(ino));
400014e3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400014e7:	7e 45                	jle    4000152e <fileino_write+0x54>
400014e9:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
400014f0:	7f 3c                	jg     4000152e <fileino_write+0x54>
400014f2:	8b 15 48 34 00 40    	mov    0x40003448,%edx
400014f8:	8b 45 08             	mov    0x8(%ebp),%eax
400014fb:	6b c0 5c             	imul   $0x5c,%eax,%eax
400014fe:	01 d0                	add    %edx,%eax
40001500:	05 10 10 00 00       	add    $0x1010,%eax
40001505:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40001509:	84 c0                	test   %al,%al
4000150b:	74 21                	je     4000152e <fileino_write+0x54>
4000150d:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40001513:	8b 45 08             	mov    0x8(%ebp),%eax
40001516:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001519:	01 d0                	add    %edx,%eax
4000151b:	05 58 10 00 00       	add    $0x1058,%eax
40001520:	8b 00                	mov    (%eax),%eax
40001522:	25 00 70 00 00       	and    $0x7000,%eax
40001527:	3d 00 10 00 00       	cmp    $0x1000,%eax
4000152c:	74 24                	je     40001552 <fileino_write+0x78>
4000152e:	c7 44 24 0c ec 34 00 	movl   $0x400034ec,0xc(%esp)
40001535:	40 
40001536:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
4000153d:	40 
4000153e:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
40001545:	00 
40001546:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
4000154d:	e8 0e fa ff ff       	call   40000f60 <debug_panic>
	assert(ofs >= 0);
40001552:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40001556:	79 24                	jns    4000157c <fileino_write+0xa2>
40001558:	c7 44 24 0c ff 34 00 	movl   $0x400034ff,0xc(%esp)
4000155f:	40 
40001560:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
40001567:	40 
40001568:	c7 44 24 04 84 00 00 	movl   $0x84,0x4(%esp)
4000156f:	00 
40001570:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
40001577:	e8 e4 f9 ff ff       	call   40000f60 <debug_panic>
	assert(eltsize > 0);
4000157c:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40001580:	75 24                	jne    400015a6 <fileino_write+0xcc>
40001582:	c7 44 24 0c 08 35 00 	movl   $0x40003508,0xc(%esp)
40001589:	40 
4000158a:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
40001591:	40 
40001592:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
40001599:	00 
4000159a:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
400015a1:	e8 ba f9 ff ff       	call   40000f60 <debug_panic>

	int i = 0;
400015a6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	ssize_t return_number = 0;
400015ad:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	fileinode *fi = &files->fi[ino];
400015b4:	a1 48 34 00 40       	mov    0x40003448,%eax
400015b9:	8b 55 08             	mov    0x8(%ebp),%edx
400015bc:	6b d2 5c             	imul   $0x5c,%edx,%edx
400015bf:	81 c2 10 10 00 00    	add    $0x1010,%edx
400015c5:	01 d0                	add    %edx,%eax
400015c7:	89 45 d8             	mov    %eax,-0x28(%ebp)
	assert(fi->size <= FILE_MAXSIZE);
400015ca:	8b 45 d8             	mov    -0x28(%ebp),%eax
400015cd:	8b 40 4c             	mov    0x4c(%eax),%eax
400015d0:	3d 00 00 40 00       	cmp    $0x400000,%eax
400015d5:	76 24                	jbe    400015fb <fileino_write+0x121>
400015d7:	c7 44 24 0c 14 35 00 	movl   $0x40003514,0xc(%esp)
400015de:	40 
400015df:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
400015e6:	40 
400015e7:	c7 44 24 04 8a 00 00 	movl   $0x8a,0x4(%esp)
400015ee:	00 
400015ef:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
400015f6:	e8 65 f9 ff ff       	call   40000f60 <debug_panic>
	uint8_t* write_start = FILEDATA(ino) + ofs;
400015fb:	8b 45 08             	mov    0x8(%ebp),%eax
400015fe:	c1 e0 16             	shl    $0x16,%eax
40001601:	89 c2                	mov    %eax,%edx
40001603:	8b 45 0c             	mov    0xc(%ebp),%eax
40001606:	01 d0                	add    %edx,%eax
40001608:	05 00 00 00 80       	add    $0x80000000,%eax
4000160d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	uint8_t* write_pointer = write_start;
40001610:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40001613:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uint32_t after_write_size = ofs + eltsize * count;
40001616:	8b 45 14             	mov    0x14(%ebp),%eax
40001619:	89 c2                	mov    %eax,%edx
4000161b:	0f af 55 18          	imul   0x18(%ebp),%edx
4000161f:	8b 45 0c             	mov    0xc(%ebp),%eax
40001622:	01 d0                	add    %edx,%eax
40001624:	89 45 d0             	mov    %eax,-0x30(%ebp)

	if(after_write_size > FILE_MAXSIZE){
40001627:	81 7d d0 00 00 40 00 	cmpl   $0x400000,-0x30(%ebp)
4000162e:	76 15                	jbe    40001645 <fileino_write+0x16b>
		errno = EFBIG;
40001630:	a1 48 34 00 40       	mov    0x40003448,%eax
40001635:	c7 00 03 00 00 00    	movl   $0x3,(%eax)
		return -1;
4000163b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40001640:	e9 28 01 00 00       	jmp    4000176d <fileino_write+0x293>
	}
	if(after_write_size > fi->size){
40001645:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001648:	8b 40 4c             	mov    0x4c(%eax),%eax
4000164b:	3b 45 d0             	cmp    -0x30(%ebp),%eax
4000164e:	0f 83 0d 01 00 00    	jae    40001761 <fileino_write+0x287>
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
40001654:	c7 45 cc 00 10 00 00 	movl   $0x1000,-0x34(%ebp)
4000165b:	8b 45 cc             	mov    -0x34(%ebp),%eax
4000165e:	8b 55 d0             	mov    -0x30(%ebp),%edx
40001661:	01 d0                	add    %edx,%eax
40001663:	83 e8 01             	sub    $0x1,%eax
40001666:	89 45 c8             	mov    %eax,-0x38(%ebp)
40001669:	8b 45 c8             	mov    -0x38(%ebp),%eax
4000166c:	ba 00 00 00 00       	mov    $0x0,%edx
40001671:	f7 75 cc             	divl   -0x34(%ebp)
40001674:	89 d0                	mov    %edx,%eax
40001676:	8b 55 c8             	mov    -0x38(%ebp),%edx
40001679:	89 d1                	mov    %edx,%ecx
4000167b:	29 c1                	sub    %eax,%ecx
4000167d:	89 c8                	mov    %ecx,%eax
4000167f:	89 c1                	mov    %eax,%ecx
40001681:	c7 45 c4 00 10 00 00 	movl   $0x1000,-0x3c(%ebp)
40001688:	8b 45 d8             	mov    -0x28(%ebp),%eax
4000168b:	8b 50 4c             	mov    0x4c(%eax),%edx
4000168e:	8b 45 c4             	mov    -0x3c(%ebp),%eax
40001691:	01 d0                	add    %edx,%eax
40001693:	83 e8 01             	sub    $0x1,%eax
40001696:	89 45 c0             	mov    %eax,-0x40(%ebp)
40001699:	8b 45 c0             	mov    -0x40(%ebp),%eax
4000169c:	ba 00 00 00 00       	mov    $0x0,%edx
400016a1:	f7 75 c4             	divl   -0x3c(%ebp)
400016a4:	89 d0                	mov    %edx,%eax
400016a6:	8b 55 c0             	mov    -0x40(%ebp),%edx
400016a9:	89 d3                	mov    %edx,%ebx
400016ab:	29 c3                	sub    %eax,%ebx
400016ad:	89 d8                	mov    %ebx,%eax
	if(after_write_size > FILE_MAXSIZE){
		errno = EFBIG;
		return -1;
	}
	if(after_write_size > fi->size){
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
400016af:	29 c1                	sub    %eax,%ecx
400016b1:	8b 45 08             	mov    0x8(%ebp),%eax
400016b4:	c1 e0 16             	shl    $0x16,%eax
400016b7:	89 c3                	mov    %eax,%ebx
400016b9:	c7 45 bc 00 10 00 00 	movl   $0x1000,-0x44(%ebp)
400016c0:	8b 45 d8             	mov    -0x28(%ebp),%eax
400016c3:	8b 50 4c             	mov    0x4c(%eax),%edx
400016c6:	8b 45 bc             	mov    -0x44(%ebp),%eax
400016c9:	01 d0                	add    %edx,%eax
400016cb:	83 e8 01             	sub    $0x1,%eax
400016ce:	89 45 b8             	mov    %eax,-0x48(%ebp)
400016d1:	8b 45 b8             	mov    -0x48(%ebp),%eax
400016d4:	ba 00 00 00 00       	mov    $0x0,%edx
400016d9:	f7 75 bc             	divl   -0x44(%ebp)
400016dc:	89 d0                	mov    %edx,%eax
400016de:	8b 55 b8             	mov    -0x48(%ebp),%edx
400016e1:	89 d6                	mov    %edx,%esi
400016e3:	29 c6                	sub    %eax,%esi
400016e5:	89 f0                	mov    %esi,%eax
400016e7:	01 d8                	add    %ebx,%eax
400016e9:	05 00 00 00 80       	add    $0x80000000,%eax
400016ee:	c7 45 b4 00 07 00 00 	movl   $0x700,-0x4c(%ebp)
400016f5:	66 c7 45 b2 00 00    	movw   $0x0,-0x4e(%ebp)
400016fb:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
40001702:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
40001709:	89 45 a4             	mov    %eax,-0x5c(%ebp)
4000170c:	89 4d a0             	mov    %ecx,-0x60(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
4000170f:	8b 45 b4             	mov    -0x4c(%ebp),%eax
40001712:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001715:	8b 5d ac             	mov    -0x54(%ebp),%ebx
40001718:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
4000171c:	8b 75 a8             	mov    -0x58(%ebp),%esi
4000171f:	8b 7d a4             	mov    -0x5c(%ebp),%edi
40001722:	8b 4d a0             	mov    -0x60(%ebp),%ecx
40001725:	cd 30                	int    $0x30
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
		fi->size = after_write_size;
40001727:	8b 45 d8             	mov    -0x28(%ebp),%eax
4000172a:	8b 55 d0             	mov    -0x30(%ebp),%edx
4000172d:	89 50 4c             	mov    %edx,0x4c(%eax)
	}
	for(i; i < count; i++){
40001730:	eb 2f                	jmp    40001761 <fileino_write+0x287>
		memcpy(write_pointer, buf, eltsize);
40001732:	8b 45 14             	mov    0x14(%ebp),%eax
40001735:	89 44 24 08          	mov    %eax,0x8(%esp)
40001739:	8b 45 10             	mov    0x10(%ebp),%eax
4000173c:	89 44 24 04          	mov    %eax,0x4(%esp)
40001740:	8b 45 dc             	mov    -0x24(%ebp),%eax
40001743:	89 04 24             	mov    %eax,(%esp)
40001746:	e8 82 f5 ff ff       	call   40000ccd <memcpy>
		return_number++;
4000174b:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
		buf += eltsize;
4000174f:	8b 45 14             	mov    0x14(%ebp),%eax
40001752:	01 45 10             	add    %eax,0x10(%ebp)
		write_pointer += eltsize;
40001755:	8b 45 14             	mov    0x14(%ebp),%eax
40001758:	01 45 dc             	add    %eax,-0x24(%ebp)
	if(after_write_size > fi->size){
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
		fi->size = after_write_size;
	}
	for(i; i < count; i++){
4000175b:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
4000175f:	eb 01                	jmp    40001762 <fileino_write+0x288>
40001761:	90                   	nop
40001762:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001765:	3b 45 18             	cmp    0x18(%ebp),%eax
40001768:	72 c8                	jb     40001732 <fileino_write+0x258>
		memcpy(write_pointer, buf, eltsize);
		return_number++;
		buf += eltsize;
		write_pointer += eltsize;
	}
	return return_number;
4000176a:	8b 45 e0             	mov    -0x20(%ebp),%eax

	// Lab 4: insert your file writing code here.
	//warn("fileino_write() not implemented");
	//errno = EINVAL;
	//return -1;
}
4000176d:	83 c4 6c             	add    $0x6c,%esp
40001770:	5b                   	pop    %ebx
40001771:	5e                   	pop    %esi
40001772:	5f                   	pop    %edi
40001773:	5d                   	pop    %ebp
40001774:	c3                   	ret    

40001775 <fileino_stat>:
// Return file statistics about a particular inode.
// The specified inode must indicate a file that exists,
// but it can be any type of object: e.g., file, directory, special file, etc.
int
fileino_stat(int ino, struct stat *st)
{
40001775:	55                   	push   %ebp
40001776:	89 e5                	mov    %esp,%ebp
40001778:	83 ec 28             	sub    $0x28,%esp
	assert(fileino_exists(ino));
4000177b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
4000177f:	7e 3d                	jle    400017be <fileino_stat+0x49>
40001781:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40001788:	7f 34                	jg     400017be <fileino_stat+0x49>
4000178a:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40001790:	8b 45 08             	mov    0x8(%ebp),%eax
40001793:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001796:	01 d0                	add    %edx,%eax
40001798:	05 10 10 00 00       	add    $0x1010,%eax
4000179d:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400017a1:	84 c0                	test   %al,%al
400017a3:	74 19                	je     400017be <fileino_stat+0x49>
400017a5:	8b 15 48 34 00 40    	mov    0x40003448,%edx
400017ab:	8b 45 08             	mov    0x8(%ebp),%eax
400017ae:	6b c0 5c             	imul   $0x5c,%eax,%eax
400017b1:	01 d0                	add    %edx,%eax
400017b3:	05 58 10 00 00       	add    $0x1058,%eax
400017b8:	8b 00                	mov    (%eax),%eax
400017ba:	85 c0                	test   %eax,%eax
400017bc:	75 24                	jne    400017e2 <fileino_stat+0x6d>
400017be:	c7 44 24 0c 2d 35 00 	movl   $0x4000352d,0xc(%esp)
400017c5:	40 
400017c6:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
400017cd:	40 
400017ce:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
400017d5:	00 
400017d6:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
400017dd:	e8 7e f7 ff ff       	call   40000f60 <debug_panic>

	fileinode *fi = &files->fi[ino];
400017e2:	a1 48 34 00 40       	mov    0x40003448,%eax
400017e7:	8b 55 08             	mov    0x8(%ebp),%edx
400017ea:	6b d2 5c             	imul   $0x5c,%edx,%edx
400017ed:	81 c2 10 10 00 00    	add    $0x1010,%edx
400017f3:	01 d0                	add    %edx,%eax
400017f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert(fileino_isdir(fi->dino));	// Should be in a directory!
400017f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
400017fb:	8b 00                	mov    (%eax),%eax
400017fd:	85 c0                	test   %eax,%eax
400017ff:	7e 4c                	jle    4000184d <fileino_stat+0xd8>
40001801:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001804:	8b 00                	mov    (%eax),%eax
40001806:	3d ff 00 00 00       	cmp    $0xff,%eax
4000180b:	7f 40                	jg     4000184d <fileino_stat+0xd8>
4000180d:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40001813:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001816:	8b 00                	mov    (%eax),%eax
40001818:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000181b:	01 d0                	add    %edx,%eax
4000181d:	05 10 10 00 00       	add    $0x1010,%eax
40001822:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40001826:	84 c0                	test   %al,%al
40001828:	74 23                	je     4000184d <fileino_stat+0xd8>
4000182a:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40001830:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001833:	8b 00                	mov    (%eax),%eax
40001835:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001838:	01 d0                	add    %edx,%eax
4000183a:	05 58 10 00 00       	add    $0x1058,%eax
4000183f:	8b 00                	mov    (%eax),%eax
40001841:	25 00 70 00 00       	and    $0x7000,%eax
40001846:	3d 00 20 00 00       	cmp    $0x2000,%eax
4000184b:	74 24                	je     40001871 <fileino_stat+0xfc>
4000184d:	c7 44 24 0c 41 35 00 	movl   $0x40003541,0xc(%esp)
40001854:	40 
40001855:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
4000185c:	40 
4000185d:	c7 44 24 04 af 00 00 	movl   $0xaf,0x4(%esp)
40001864:	00 
40001865:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
4000186c:	e8 ef f6 ff ff       	call   40000f60 <debug_panic>
	st->st_ino = ino;
40001871:	8b 45 0c             	mov    0xc(%ebp),%eax
40001874:	8b 55 08             	mov    0x8(%ebp),%edx
40001877:	89 10                	mov    %edx,(%eax)
	st->st_mode = fi->mode;
40001879:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000187c:	8b 50 48             	mov    0x48(%eax),%edx
4000187f:	8b 45 0c             	mov    0xc(%ebp),%eax
40001882:	89 50 04             	mov    %edx,0x4(%eax)
	st->st_size = fi->size;
40001885:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001888:	8b 40 4c             	mov    0x4c(%eax),%eax
4000188b:	89 c2                	mov    %eax,%edx
4000188d:	8b 45 0c             	mov    0xc(%ebp),%eax
40001890:	89 50 08             	mov    %edx,0x8(%eax)

	return 0;
40001893:	b8 00 00 00 00       	mov    $0x0,%eax
}
40001898:	c9                   	leave  
40001899:	c3                   	ret    

4000189a <fileino_truncate>:
// Grow or shrink a file to exactly a specified size.
// If growing a file, then fills the new space with zeros.
// Returns 0 if successful, or returns -1 and sets errno on error.
int
fileino_truncate(int ino, off_t newsize)
{
4000189a:	55                   	push   %ebp
4000189b:	89 e5                	mov    %esp,%ebp
4000189d:	57                   	push   %edi
4000189e:	56                   	push   %esi
4000189f:	53                   	push   %ebx
400018a0:	81 ec 8c 00 00 00    	sub    $0x8c,%esp
	assert(fileino_isvalid(ino));
400018a6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400018aa:	7e 09                	jle    400018b5 <fileino_truncate+0x1b>
400018ac:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
400018b3:	7e 24                	jle    400018d9 <fileino_truncate+0x3f>
400018b5:	c7 44 24 0c 59 35 00 	movl   $0x40003559,0xc(%esp)
400018bc:	40 
400018bd:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
400018c4:	40 
400018c5:	c7 44 24 04 bd 00 00 	movl   $0xbd,0x4(%esp)
400018cc:	00 
400018cd:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
400018d4:	e8 87 f6 ff ff       	call   40000f60 <debug_panic>
	assert(newsize >= 0 && newsize <= FILE_MAXSIZE);
400018d9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400018dd:	78 09                	js     400018e8 <fileino_truncate+0x4e>
400018df:	81 7d 0c 00 00 40 00 	cmpl   $0x400000,0xc(%ebp)
400018e6:	7e 24                	jle    4000190c <fileino_truncate+0x72>
400018e8:	c7 44 24 0c 70 35 00 	movl   $0x40003570,0xc(%esp)
400018ef:	40 
400018f0:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
400018f7:	40 
400018f8:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
400018ff:	00 
40001900:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
40001907:	e8 54 f6 ff ff       	call   40000f60 <debug_panic>

	size_t oldsize = files->fi[ino].size;
4000190c:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40001912:	8b 45 08             	mov    0x8(%ebp),%eax
40001915:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001918:	01 d0                	add    %edx,%eax
4000191a:	05 5c 10 00 00       	add    $0x105c,%eax
4000191f:	8b 00                	mov    (%eax),%eax
40001921:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	size_t oldpagelim = ROUNDUP(files->fi[ino].size, PAGESIZE);
40001924:	c7 45 e0 00 10 00 00 	movl   $0x1000,-0x20(%ebp)
4000192b:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40001931:	8b 45 08             	mov    0x8(%ebp),%eax
40001934:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001937:	01 d0                	add    %edx,%eax
40001939:	05 5c 10 00 00       	add    $0x105c,%eax
4000193e:	8b 10                	mov    (%eax),%edx
40001940:	8b 45 e0             	mov    -0x20(%ebp),%eax
40001943:	01 d0                	add    %edx,%eax
40001945:	83 e8 01             	sub    $0x1,%eax
40001948:	89 45 dc             	mov    %eax,-0x24(%ebp)
4000194b:	8b 45 dc             	mov    -0x24(%ebp),%eax
4000194e:	ba 00 00 00 00       	mov    $0x0,%edx
40001953:	f7 75 e0             	divl   -0x20(%ebp)
40001956:	89 d0                	mov    %edx,%eax
40001958:	8b 55 dc             	mov    -0x24(%ebp),%edx
4000195b:	89 d1                	mov    %edx,%ecx
4000195d:	29 c1                	sub    %eax,%ecx
4000195f:	89 c8                	mov    %ecx,%eax
40001961:	89 45 d8             	mov    %eax,-0x28(%ebp)
	size_t newpagelim = ROUNDUP(newsize, PAGESIZE);
40001964:	c7 45 d4 00 10 00 00 	movl   $0x1000,-0x2c(%ebp)
4000196b:	8b 55 0c             	mov    0xc(%ebp),%edx
4000196e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40001971:	01 d0                	add    %edx,%eax
40001973:	83 e8 01             	sub    $0x1,%eax
40001976:	89 45 d0             	mov    %eax,-0x30(%ebp)
40001979:	8b 45 d0             	mov    -0x30(%ebp),%eax
4000197c:	ba 00 00 00 00       	mov    $0x0,%edx
40001981:	f7 75 d4             	divl   -0x2c(%ebp)
40001984:	89 d0                	mov    %edx,%eax
40001986:	8b 55 d0             	mov    -0x30(%ebp),%edx
40001989:	89 d1                	mov    %edx,%ecx
4000198b:	29 c1                	sub    %eax,%ecx
4000198d:	89 c8                	mov    %ecx,%eax
4000198f:	89 45 cc             	mov    %eax,-0x34(%ebp)
	if (newsize > oldsize) {
40001992:	8b 45 0c             	mov    0xc(%ebp),%eax
40001995:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
40001998:	0f 86 8a 00 00 00    	jbe    40001a28 <fileino_truncate+0x18e>
		// Grow the file and fill the new space with zeros.
		sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
4000199e:	8b 45 d8             	mov    -0x28(%ebp),%eax
400019a1:	8b 55 cc             	mov    -0x34(%ebp),%edx
400019a4:	89 d1                	mov    %edx,%ecx
400019a6:	29 c1                	sub    %eax,%ecx
400019a8:	89 c8                	mov    %ecx,%eax
			FILEDATA(ino) + oldpagelim,
400019aa:	8b 55 08             	mov    0x8(%ebp),%edx
400019ad:	c1 e2 16             	shl    $0x16,%edx
400019b0:	89 d1                	mov    %edx,%ecx
400019b2:	8b 55 d8             	mov    -0x28(%ebp),%edx
400019b5:	01 ca                	add    %ecx,%edx
	size_t oldsize = files->fi[ino].size;
	size_t oldpagelim = ROUNDUP(files->fi[ino].size, PAGESIZE);
	size_t newpagelim = ROUNDUP(newsize, PAGESIZE);
	if (newsize > oldsize) {
		// Grow the file and fill the new space with zeros.
		sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
400019b7:	81 c2 00 00 00 80    	add    $0x80000000,%edx
400019bd:	c7 45 c8 00 07 00 00 	movl   $0x700,-0x38(%ebp)
400019c4:	66 c7 45 c6 00 00    	movw   $0x0,-0x3a(%ebp)
400019ca:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
400019d1:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
400019d8:	89 55 b8             	mov    %edx,-0x48(%ebp)
400019db:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400019de:	8b 45 c8             	mov    -0x38(%ebp),%eax
400019e1:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400019e4:	8b 5d c0             	mov    -0x40(%ebp),%ebx
400019e7:	0f b7 55 c6          	movzwl -0x3a(%ebp),%edx
400019eb:	8b 75 bc             	mov    -0x44(%ebp),%esi
400019ee:	8b 7d b8             	mov    -0x48(%ebp),%edi
400019f1:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
400019f4:	cd 30                	int    $0x30
			FILEDATA(ino) + oldpagelim,
			newpagelim - oldpagelim);
		memset(FILEDATA(ino) + oldsize, 0, newsize - oldsize);
400019f6:	8b 45 0c             	mov    0xc(%ebp),%eax
400019f9:	2b 45 e4             	sub    -0x1c(%ebp),%eax
400019fc:	8b 55 08             	mov    0x8(%ebp),%edx
400019ff:	c1 e2 16             	shl    $0x16,%edx
40001a02:	89 d1                	mov    %edx,%ecx
40001a04:	8b 55 e4             	mov    -0x1c(%ebp),%edx
40001a07:	01 ca                	add    %ecx,%edx
40001a09:	81 c2 00 00 00 80    	add    $0x80000000,%edx
40001a0f:	89 44 24 08          	mov    %eax,0x8(%esp)
40001a13:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001a1a:	00 
40001a1b:	89 14 24             	mov    %edx,(%esp)
40001a1e:	e8 62 f1 ff ff       	call   40000b85 <memset>
40001a23:	e9 a4 00 00 00       	jmp    40001acc <fileino_truncate+0x232>
	} else if (newsize > 0) {
40001a28:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40001a2c:	7e 56                	jle    40001a84 <fileino_truncate+0x1ea>
		// Shrink the file, but not all the way to empty.
		// Would prefer to use SYS_ZERO to free the file content,
		// but SYS_ZERO isn't guaranteed to work at page granularity.
		sys_get(SYS_PERM, 0, NULL, NULL,
40001a2e:	b8 00 00 40 00       	mov    $0x400000,%eax
40001a33:	2b 45 cc             	sub    -0x34(%ebp),%eax
			FILEDATA(ino) + newpagelim, FILE_MAXSIZE - newpagelim);
40001a36:	8b 55 08             	mov    0x8(%ebp),%edx
40001a39:	c1 e2 16             	shl    $0x16,%edx
40001a3c:	89 d1                	mov    %edx,%ecx
40001a3e:	8b 55 cc             	mov    -0x34(%ebp),%edx
40001a41:	01 ca                	add    %ecx,%edx
		memset(FILEDATA(ino) + oldsize, 0, newsize - oldsize);
	} else if (newsize > 0) {
		// Shrink the file, but not all the way to empty.
		// Would prefer to use SYS_ZERO to free the file content,
		// but SYS_ZERO isn't guaranteed to work at page granularity.
		sys_get(SYS_PERM, 0, NULL, NULL,
40001a43:	81 c2 00 00 00 80    	add    $0x80000000,%edx
40001a49:	c7 45 b0 00 01 00 00 	movl   $0x100,-0x50(%ebp)
40001a50:	66 c7 45 ae 00 00    	movw   $0x0,-0x52(%ebp)
40001a56:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
40001a5d:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
40001a64:	89 55 a0             	mov    %edx,-0x60(%ebp)
40001a67:	89 45 9c             	mov    %eax,-0x64(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001a6a:	8b 45 b0             	mov    -0x50(%ebp),%eax
40001a6d:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001a70:	8b 5d a8             	mov    -0x58(%ebp),%ebx
40001a73:	0f b7 55 ae          	movzwl -0x52(%ebp),%edx
40001a77:	8b 75 a4             	mov    -0x5c(%ebp),%esi
40001a7a:	8b 7d a0             	mov    -0x60(%ebp),%edi
40001a7d:	8b 4d 9c             	mov    -0x64(%ebp),%ecx
40001a80:	cd 30                	int    $0x30
40001a82:	eb 48                	jmp    40001acc <fileino_truncate+0x232>
			FILEDATA(ino) + newpagelim, FILE_MAXSIZE - newpagelim);
	} else {
		// Shrink the file to empty.  Use SYS_ZERO to free completely.
		sys_get(SYS_ZERO, 0, NULL, NULL, FILEDATA(ino), FILE_MAXSIZE);
40001a84:	8b 45 08             	mov    0x8(%ebp),%eax
40001a87:	c1 e0 16             	shl    $0x16,%eax
40001a8a:	05 00 00 00 80       	add    $0x80000000,%eax
40001a8f:	c7 45 98 00 00 01 00 	movl   $0x10000,-0x68(%ebp)
40001a96:	66 c7 45 96 00 00    	movw   $0x0,-0x6a(%ebp)
40001a9c:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
40001aa3:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
40001aaa:	89 45 88             	mov    %eax,-0x78(%ebp)
40001aad:	c7 45 84 00 00 40 00 	movl   $0x400000,-0x7c(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001ab4:	8b 45 98             	mov    -0x68(%ebp),%eax
40001ab7:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001aba:	8b 5d 90             	mov    -0x70(%ebp),%ebx
40001abd:	0f b7 55 96          	movzwl -0x6a(%ebp),%edx
40001ac1:	8b 75 8c             	mov    -0x74(%ebp),%esi
40001ac4:	8b 7d 88             	mov    -0x78(%ebp),%edi
40001ac7:	8b 4d 84             	mov    -0x7c(%ebp),%ecx
40001aca:	cd 30                	int    $0x30
	}
	files->fi[ino].size = newsize;
40001acc:	8b 0d 48 34 00 40    	mov    0x40003448,%ecx
40001ad2:	8b 45 0c             	mov    0xc(%ebp),%eax
40001ad5:	8b 55 08             	mov    0x8(%ebp),%edx
40001ad8:	6b d2 5c             	imul   $0x5c,%edx,%edx
40001adb:	01 ca                	add    %ecx,%edx
40001add:	81 c2 5c 10 00 00    	add    $0x105c,%edx
40001ae3:	89 02                	mov    %eax,(%edx)
	files->fi[ino].ver++;	// truncation is always an exclusive change
40001ae5:	a1 48 34 00 40       	mov    0x40003448,%eax
40001aea:	8b 55 08             	mov    0x8(%ebp),%edx
40001aed:	6b d2 5c             	imul   $0x5c,%edx,%edx
40001af0:	01 c2                	add    %eax,%edx
40001af2:	81 c2 54 10 00 00    	add    $0x1054,%edx
40001af8:	8b 12                	mov    (%edx),%edx
40001afa:	83 c2 01             	add    $0x1,%edx
40001afd:	8b 4d 08             	mov    0x8(%ebp),%ecx
40001b00:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
40001b03:	01 c8                	add    %ecx,%eax
40001b05:	05 54 10 00 00       	add    $0x1054,%eax
40001b0a:	89 10                	mov    %edx,(%eax)
	return 0;
40001b0c:	b8 00 00 00 00       	mov    $0x0,%eax
}
40001b11:	81 c4 8c 00 00 00    	add    $0x8c,%esp
40001b17:	5b                   	pop    %ebx
40001b18:	5e                   	pop    %esi
40001b19:	5f                   	pop    %edi
40001b1a:	5d                   	pop    %ebp
40001b1b:	c3                   	ret    

40001b1c <fileino_flush>:

// Flush any outstanding writes on this file to our parent process.
// (XXX should flushes propagate across multiple levels?)
int
fileino_flush(int ino)
{
40001b1c:	55                   	push   %ebp
40001b1d:	89 e5                	mov    %esp,%ebp
40001b1f:	83 ec 18             	sub    $0x18,%esp
	assert(fileino_isvalid(ino));
40001b22:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001b26:	7e 09                	jle    40001b31 <fileino_flush+0x15>
40001b28:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40001b2f:	7e 24                	jle    40001b55 <fileino_flush+0x39>
40001b31:	c7 44 24 0c 59 35 00 	movl   $0x40003559,0xc(%esp)
40001b38:	40 
40001b39:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
40001b40:	40 
40001b41:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
40001b48:	00 
40001b49:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
40001b50:	e8 0b f4 ff ff       	call   40000f60 <debug_panic>

	if (files->fi[ino].size > files->fi[ino].rlen)
40001b55:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40001b5b:	8b 45 08             	mov    0x8(%ebp),%eax
40001b5e:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001b61:	01 d0                	add    %edx,%eax
40001b63:	05 5c 10 00 00       	add    $0x105c,%eax
40001b68:	8b 10                	mov    (%eax),%edx
40001b6a:	8b 0d 48 34 00 40    	mov    0x40003448,%ecx
40001b70:	8b 45 08             	mov    0x8(%ebp),%eax
40001b73:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001b76:	01 c8                	add    %ecx,%eax
40001b78:	05 68 10 00 00       	add    $0x1068,%eax
40001b7d:	8b 00                	mov    (%eax),%eax
40001b7f:	39 c2                	cmp    %eax,%edx
40001b81:	76 07                	jbe    40001b8a <fileino_flush+0x6e>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001b83:	b8 03 00 00 00       	mov    $0x3,%eax
40001b88:	cd 30                	int    $0x30
		sys_ret();	// synchronize and reconcile with parent
	return 0;
40001b8a:	b8 00 00 00 00       	mov    $0x0,%eax
}
40001b8f:	c9                   	leave  
40001b90:	c3                   	ret    

40001b91 <filedesc_alloc>:
// Search the file descriptor table for the first free file descriptor,
// and return a pointer to that file descriptor.
// If no file descriptors are available,
// returns NULL and set errno appropriately.
filedesc *filedesc_alloc(void)
{
40001b91:	55                   	push   %ebp
40001b92:	89 e5                	mov    %esp,%ebp
40001b94:	83 ec 10             	sub    $0x10,%esp
	int i;
	for (i = 0; i < OPEN_MAX; i++)
40001b97:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
40001b9e:	eb 2c                	jmp    40001bcc <filedesc_alloc+0x3b>
		if (files->fd[i].ino == FILEINO_NULL)
40001ba0:	a1 48 34 00 40       	mov    0x40003448,%eax
40001ba5:	8b 55 fc             	mov    -0x4(%ebp),%edx
40001ba8:	83 c2 01             	add    $0x1,%edx
40001bab:	c1 e2 04             	shl    $0x4,%edx
40001bae:	01 d0                	add    %edx,%eax
40001bb0:	8b 00                	mov    (%eax),%eax
40001bb2:	85 c0                	test   %eax,%eax
40001bb4:	75 12                	jne    40001bc8 <filedesc_alloc+0x37>
			return &files->fd[i];
40001bb6:	a1 48 34 00 40       	mov    0x40003448,%eax
40001bbb:	8b 55 fc             	mov    -0x4(%ebp),%edx
40001bbe:	83 c2 01             	add    $0x1,%edx
40001bc1:	c1 e2 04             	shl    $0x4,%edx
40001bc4:	01 d0                	add    %edx,%eax
40001bc6:	eb 1d                	jmp    40001be5 <filedesc_alloc+0x54>
// If no file descriptors are available,
// returns NULL and set errno appropriately.
filedesc *filedesc_alloc(void)
{
	int i;
	for (i = 0; i < OPEN_MAX; i++)
40001bc8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40001bcc:	81 7d fc ff 00 00 00 	cmpl   $0xff,-0x4(%ebp)
40001bd3:	7e cb                	jle    40001ba0 <filedesc_alloc+0xf>
		if (files->fd[i].ino == FILEINO_NULL)
			return &files->fd[i];
	errno = EMFILE;
40001bd5:	a1 48 34 00 40       	mov    0x40003448,%eax
40001bda:	c7 00 04 00 00 00    	movl   $0x4,(%eax)
	return NULL;
40001be0:	b8 00 00 00 00       	mov    $0x0,%eax
}
40001be5:	c9                   	leave  
40001be6:	c3                   	ret    

40001be7 <filedesc_open>:
// The 'openflags' determines whether the file is created, truncated, etc.
// Returns the opened file descriptor on success,
// or returns NULL and sets errno on failure.
filedesc *
filedesc_open(filedesc *fd, const char *path, int openflags, mode_t mode)
{
40001be7:	55                   	push   %ebp
40001be8:	89 e5                	mov    %esp,%ebp
40001bea:	83 ec 28             	sub    $0x28,%esp
	if (!fd && !(fd = filedesc_alloc()))
40001bed:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001bf1:	75 18                	jne    40001c0b <filedesc_open+0x24>
40001bf3:	e8 99 ff ff ff       	call   40001b91 <filedesc_alloc>
40001bf8:	89 45 08             	mov    %eax,0x8(%ebp)
40001bfb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001bff:	75 0a                	jne    40001c0b <filedesc_open+0x24>
		return NULL;
40001c01:	b8 00 00 00 00       	mov    $0x0,%eax
40001c06:	e9 04 02 00 00       	jmp    40001e0f <filedesc_open+0x228>
	assert(fd->ino == FILEINO_NULL);
40001c0b:	8b 45 08             	mov    0x8(%ebp),%eax
40001c0e:	8b 00                	mov    (%eax),%eax
40001c10:	85 c0                	test   %eax,%eax
40001c12:	74 24                	je     40001c38 <filedesc_open+0x51>
40001c14:	c7 44 24 0c 98 35 00 	movl   $0x40003598,0xc(%esp)
40001c1b:	40 
40001c1c:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
40001c23:	40 
40001c24:	c7 44 24 04 00 01 00 	movl   $0x100,0x4(%esp)
40001c2b:	00 
40001c2c:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
40001c33:	e8 28 f3 ff ff       	call   40000f60 <debug_panic>

	// Determine the complete file mode if it is to be created.
	mode_t createmode = (openflags & O_CREAT) ? S_IFREG | (mode & 0777) : 0;
40001c38:	8b 45 10             	mov    0x10(%ebp),%eax
40001c3b:	83 e0 20             	and    $0x20,%eax
40001c3e:	85 c0                	test   %eax,%eax
40001c40:	74 0d                	je     40001c4f <filedesc_open+0x68>
40001c42:	8b 45 14             	mov    0x14(%ebp),%eax
40001c45:	25 ff 01 00 00       	and    $0x1ff,%eax
40001c4a:	80 cc 10             	or     $0x10,%ah
40001c4d:	eb 05                	jmp    40001c54 <filedesc_open+0x6d>
40001c4f:	b8 00 00 00 00       	mov    $0x0,%eax
40001c54:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Walk the directory tree to find the desired directory entry,
	// creating an entry if it doesn't exist and O_CREAT is set.
	int ino = dir_walk(path, createmode);
40001c57:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001c5a:	89 44 24 04          	mov    %eax,0x4(%esp)
40001c5e:	8b 45 0c             	mov    0xc(%ebp),%eax
40001c61:	89 04 24             	mov    %eax,(%esp)
40001c64:	e8 d7 05 00 00       	call   40002240 <dir_walk>
40001c69:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (ino < 0)
40001c6c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40001c70:	79 0a                	jns    40001c7c <filedesc_open+0x95>
		return NULL;
40001c72:	b8 00 00 00 00       	mov    $0x0,%eax
40001c77:	e9 93 01 00 00       	jmp    40001e0f <filedesc_open+0x228>
	assert(fileino_exists(ino));
40001c7c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40001c80:	7e 3d                	jle    40001cbf <filedesc_open+0xd8>
40001c82:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40001c89:	7f 34                	jg     40001cbf <filedesc_open+0xd8>
40001c8b:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40001c91:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001c94:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001c97:	01 d0                	add    %edx,%eax
40001c99:	05 10 10 00 00       	add    $0x1010,%eax
40001c9e:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40001ca2:	84 c0                	test   %al,%al
40001ca4:	74 19                	je     40001cbf <filedesc_open+0xd8>
40001ca6:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40001cac:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001caf:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001cb2:	01 d0                	add    %edx,%eax
40001cb4:	05 58 10 00 00       	add    $0x1058,%eax
40001cb9:	8b 00                	mov    (%eax),%eax
40001cbb:	85 c0                	test   %eax,%eax
40001cbd:	75 24                	jne    40001ce3 <filedesc_open+0xfc>
40001cbf:	c7 44 24 0c 2d 35 00 	movl   $0x4000352d,0xc(%esp)
40001cc6:	40 
40001cc7:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
40001cce:	40 
40001ccf:	c7 44 24 04 0a 01 00 	movl   $0x10a,0x4(%esp)
40001cd6:	00 
40001cd7:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
40001cde:	e8 7d f2 ff ff       	call   40000f60 <debug_panic>

	// Refuse to open conflict-marked files;
	// the user needs to resolve the conflict and clear the conflict flag,
	// or just delete the conflicted file.
	if (files->fi[ino].mode & S_IFCONF) {
40001ce3:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40001ce9:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001cec:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001cef:	01 d0                	add    %edx,%eax
40001cf1:	05 58 10 00 00       	add    $0x1058,%eax
40001cf6:	8b 00                	mov    (%eax),%eax
40001cf8:	25 00 00 01 00       	and    $0x10000,%eax
40001cfd:	85 c0                	test   %eax,%eax
40001cff:	74 15                	je     40001d16 <filedesc_open+0x12f>
		errno = ECONFLICT;
40001d01:	a1 48 34 00 40       	mov    0x40003448,%eax
40001d06:	c7 00 0a 00 00 00    	movl   $0xa,(%eax)
		return NULL;
40001d0c:	b8 00 00 00 00       	mov    $0x0,%eax
40001d11:	e9 f9 00 00 00       	jmp    40001e0f <filedesc_open+0x228>
	}

	// Truncate the file if we were asked to
	if (openflags & O_TRUNC) {
40001d16:	8b 45 10             	mov    0x10(%ebp),%eax
40001d19:	83 e0 40             	and    $0x40,%eax
40001d1c:	85 c0                	test   %eax,%eax
40001d1e:	74 5c                	je     40001d7c <filedesc_open+0x195>
		if (!(openflags & O_WRONLY)) {
40001d20:	8b 45 10             	mov    0x10(%ebp),%eax
40001d23:	83 e0 02             	and    $0x2,%eax
40001d26:	85 c0                	test   %eax,%eax
40001d28:	75 31                	jne    40001d5b <filedesc_open+0x174>
			warn("filedesc_open: can't truncate non-writable file");
40001d2a:	c7 44 24 08 b0 35 00 	movl   $0x400035b0,0x8(%esp)
40001d31:	40 
40001d32:	c7 44 24 04 17 01 00 	movl   $0x117,0x4(%esp)
40001d39:	00 
40001d3a:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
40001d41:	e8 84 f2 ff ff       	call   40000fca <debug_warn>
			errno = EINVAL;
40001d46:	a1 48 34 00 40       	mov    0x40003448,%eax
40001d4b:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
			return NULL;
40001d51:	b8 00 00 00 00       	mov    $0x0,%eax
40001d56:	e9 b4 00 00 00       	jmp    40001e0f <filedesc_open+0x228>
		}
		if (fileino_truncate(ino, 0) < 0)
40001d5b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001d62:	00 
40001d63:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001d66:	89 04 24             	mov    %eax,(%esp)
40001d69:	e8 2c fb ff ff       	call   4000189a <fileino_truncate>
40001d6e:	85 c0                	test   %eax,%eax
40001d70:	79 0a                	jns    40001d7c <filedesc_open+0x195>
			return NULL;
40001d72:	b8 00 00 00 00       	mov    $0x0,%eax
40001d77:	e9 93 00 00 00       	jmp    40001e0f <filedesc_open+0x228>
	}

	// Initialize the file descriptor
	fd->ino = ino;
40001d7c:	8b 45 08             	mov    0x8(%ebp),%eax
40001d7f:	8b 55 f0             	mov    -0x10(%ebp),%edx
40001d82:	89 10                	mov    %edx,(%eax)
	fd->flags = openflags;
40001d84:	8b 45 08             	mov    0x8(%ebp),%eax
40001d87:	8b 55 10             	mov    0x10(%ebp),%edx
40001d8a:	89 50 04             	mov    %edx,0x4(%eax)
	fd->ofs = (openflags & O_APPEND) ? files->fi[ino].size : 0;
40001d8d:	8b 45 10             	mov    0x10(%ebp),%eax
40001d90:	83 e0 10             	and    $0x10,%eax
40001d93:	85 c0                	test   %eax,%eax
40001d95:	74 17                	je     40001dae <filedesc_open+0x1c7>
40001d97:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40001d9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001da0:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001da3:	01 d0                	add    %edx,%eax
40001da5:	05 5c 10 00 00       	add    $0x105c,%eax
40001daa:	8b 00                	mov    (%eax),%eax
40001dac:	eb 05                	jmp    40001db3 <filedesc_open+0x1cc>
40001dae:	b8 00 00 00 00       	mov    $0x0,%eax
40001db3:	8b 55 08             	mov    0x8(%ebp),%edx
40001db6:	89 42 08             	mov    %eax,0x8(%edx)
	fd->err = 0;
40001db9:	8b 45 08             	mov    0x8(%ebp),%eax
40001dbc:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)

	assert(filedesc_isopen(fd));
40001dc3:	a1 48 34 00 40       	mov    0x40003448,%eax
40001dc8:	83 c0 10             	add    $0x10,%eax
40001dcb:	3b 45 08             	cmp    0x8(%ebp),%eax
40001dce:	77 18                	ja     40001de8 <filedesc_open+0x201>
40001dd0:	a1 48 34 00 40       	mov    0x40003448,%eax
40001dd5:	05 10 10 00 00       	add    $0x1010,%eax
40001dda:	3b 45 08             	cmp    0x8(%ebp),%eax
40001ddd:	76 09                	jbe    40001de8 <filedesc_open+0x201>
40001ddf:	8b 45 08             	mov    0x8(%ebp),%eax
40001de2:	8b 00                	mov    (%eax),%eax
40001de4:	85 c0                	test   %eax,%eax
40001de6:	75 24                	jne    40001e0c <filedesc_open+0x225>
40001de8:	c7 44 24 0c e0 35 00 	movl   $0x400035e0,0xc(%esp)
40001def:	40 
40001df0:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
40001df7:	40 
40001df8:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
40001dff:	00 
40001e00:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
40001e07:	e8 54 f1 ff ff       	call   40000f60 <debug_panic>
	return fd;
40001e0c:	8b 45 08             	mov    0x8(%ebp),%eax
}
40001e0f:	c9                   	leave  
40001e10:	c3                   	ret    

40001e11 <filedesc_read>:
// If the file is a special device input file such as the console,
// this function pretends the file has no end and instead
// uses sys_ret() to wait for the file to extend the special file.
ssize_t
filedesc_read(filedesc *fd, void *buf, size_t eltsize, size_t count)
{
40001e11:	55                   	push   %ebp
40001e12:	89 e5                	mov    %esp,%ebp
40001e14:	83 ec 38             	sub    $0x38,%esp
	assert(filedesc_isreadable(fd));
40001e17:	a1 48 34 00 40       	mov    0x40003448,%eax
40001e1c:	83 c0 10             	add    $0x10,%eax
40001e1f:	3b 45 08             	cmp    0x8(%ebp),%eax
40001e22:	77 25                	ja     40001e49 <filedesc_read+0x38>
40001e24:	a1 48 34 00 40       	mov    0x40003448,%eax
40001e29:	05 10 10 00 00       	add    $0x1010,%eax
40001e2e:	3b 45 08             	cmp    0x8(%ebp),%eax
40001e31:	76 16                	jbe    40001e49 <filedesc_read+0x38>
40001e33:	8b 45 08             	mov    0x8(%ebp),%eax
40001e36:	8b 00                	mov    (%eax),%eax
40001e38:	85 c0                	test   %eax,%eax
40001e3a:	74 0d                	je     40001e49 <filedesc_read+0x38>
40001e3c:	8b 45 08             	mov    0x8(%ebp),%eax
40001e3f:	8b 40 04             	mov    0x4(%eax),%eax
40001e42:	83 e0 01             	and    $0x1,%eax
40001e45:	85 c0                	test   %eax,%eax
40001e47:	75 24                	jne    40001e6d <filedesc_read+0x5c>
40001e49:	c7 44 24 0c f4 35 00 	movl   $0x400035f4,0xc(%esp)
40001e50:	40 
40001e51:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
40001e58:	40 
40001e59:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
40001e60:	00 
40001e61:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
40001e68:	e8 f3 f0 ff ff       	call   40000f60 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40001e6d:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40001e73:	8b 45 08             	mov    0x8(%ebp),%eax
40001e76:	8b 00                	mov    (%eax),%eax
40001e78:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001e7b:	05 10 10 00 00       	add    $0x1010,%eax
40001e80:	01 d0                	add    %edx,%eax
40001e82:	89 45 f4             	mov    %eax,-0xc(%ebp)

	ssize_t actual = fileino_read(fd->ino, fd->ofs, buf, eltsize, count);
40001e85:	8b 45 08             	mov    0x8(%ebp),%eax
40001e88:	8b 50 08             	mov    0x8(%eax),%edx
40001e8b:	8b 45 08             	mov    0x8(%ebp),%eax
40001e8e:	8b 00                	mov    (%eax),%eax
40001e90:	8b 4d 14             	mov    0x14(%ebp),%ecx
40001e93:	89 4c 24 10          	mov    %ecx,0x10(%esp)
40001e97:	8b 4d 10             	mov    0x10(%ebp),%ecx
40001e9a:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
40001e9e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40001ea1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40001ea5:	89 54 24 04          	mov    %edx,0x4(%esp)
40001ea9:	89 04 24             	mov    %eax,(%esp)
40001eac:	e8 93 f4 ff ff       	call   40001344 <fileino_read>
40001eb1:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (actual < 0) {
40001eb4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40001eb8:	79 14                	jns    40001ece <filedesc_read+0xbd>
		fd->err = errno;	// save error indication for ferror()
40001eba:	a1 48 34 00 40       	mov    0x40003448,%eax
40001ebf:	8b 10                	mov    (%eax),%edx
40001ec1:	8b 45 08             	mov    0x8(%ebp),%eax
40001ec4:	89 50 0c             	mov    %edx,0xc(%eax)
		return -1;
40001ec7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40001ecc:	eb 56                	jmp    40001f24 <filedesc_read+0x113>
	}

	// Advance the file position
	fd->ofs += eltsize * actual;
40001ece:	8b 45 08             	mov    0x8(%ebp),%eax
40001ed1:	8b 40 08             	mov    0x8(%eax),%eax
40001ed4:	89 c2                	mov    %eax,%edx
40001ed6:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001ed9:	0f af 45 10          	imul   0x10(%ebp),%eax
40001edd:	01 d0                	add    %edx,%eax
40001edf:	89 c2                	mov    %eax,%edx
40001ee1:	8b 45 08             	mov    0x8(%ebp),%eax
40001ee4:	89 50 08             	mov    %edx,0x8(%eax)
	assert(actual == 0 || fi->size >= fd->ofs);
40001ee7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40001eeb:	74 34                	je     40001f21 <filedesc_read+0x110>
40001eed:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001ef0:	8b 50 4c             	mov    0x4c(%eax),%edx
40001ef3:	8b 45 08             	mov    0x8(%ebp),%eax
40001ef6:	8b 40 08             	mov    0x8(%eax),%eax
40001ef9:	39 c2                	cmp    %eax,%edx
40001efb:	73 24                	jae    40001f21 <filedesc_read+0x110>
40001efd:	c7 44 24 0c 0c 36 00 	movl   $0x4000360c,0xc(%esp)
40001f04:	40 
40001f05:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
40001f0c:	40 
40001f0d:	c7 44 24 04 42 01 00 	movl   $0x142,0x4(%esp)
40001f14:	00 
40001f15:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
40001f1c:	e8 3f f0 ff ff       	call   40000f60 <debug_panic>

	return actual;
40001f21:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40001f24:	c9                   	leave  
40001f25:	c3                   	ret    

40001f26 <filedesc_write>:
// The size of 'buf' must be at least 'count * eltsize' bytes.
// On success, returns the number of objects written (NOT the number of bytes).
// If an error occurs, returns -1 and sets errno appropriately.
ssize_t
filedesc_write(filedesc *fd, const void *buf, size_t eltsize, size_t count)
{
40001f26:	55                   	push   %ebp
40001f27:	89 e5                	mov    %esp,%ebp
40001f29:	83 ec 38             	sub    $0x38,%esp
	assert(filedesc_iswritable(fd));
40001f2c:	a1 48 34 00 40       	mov    0x40003448,%eax
40001f31:	83 c0 10             	add    $0x10,%eax
40001f34:	3b 45 08             	cmp    0x8(%ebp),%eax
40001f37:	77 25                	ja     40001f5e <filedesc_write+0x38>
40001f39:	a1 48 34 00 40       	mov    0x40003448,%eax
40001f3e:	05 10 10 00 00       	add    $0x1010,%eax
40001f43:	3b 45 08             	cmp    0x8(%ebp),%eax
40001f46:	76 16                	jbe    40001f5e <filedesc_write+0x38>
40001f48:	8b 45 08             	mov    0x8(%ebp),%eax
40001f4b:	8b 00                	mov    (%eax),%eax
40001f4d:	85 c0                	test   %eax,%eax
40001f4f:	74 0d                	je     40001f5e <filedesc_write+0x38>
40001f51:	8b 45 08             	mov    0x8(%ebp),%eax
40001f54:	8b 40 04             	mov    0x4(%eax),%eax
40001f57:	83 e0 02             	and    $0x2,%eax
40001f5a:	85 c0                	test   %eax,%eax
40001f5c:	75 24                	jne    40001f82 <filedesc_write+0x5c>
40001f5e:	c7 44 24 0c 2f 36 00 	movl   $0x4000362f,0xc(%esp)
40001f65:	40 
40001f66:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
40001f6d:	40 
40001f6e:	c7 44 24 04 4f 01 00 	movl   $0x14f,0x4(%esp)
40001f75:	00 
40001f76:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
40001f7d:	e8 de ef ff ff       	call   40000f60 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40001f82:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40001f88:	8b 45 08             	mov    0x8(%ebp),%eax
40001f8b:	8b 00                	mov    (%eax),%eax
40001f8d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001f90:	05 10 10 00 00       	add    $0x1010,%eax
40001f95:	01 d0                	add    %edx,%eax
40001f97:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// If we're appending to the file, seek to the end first.
	if (fd->flags & O_APPEND)
40001f9a:	8b 45 08             	mov    0x8(%ebp),%eax
40001f9d:	8b 40 04             	mov    0x4(%eax),%eax
40001fa0:	83 e0 10             	and    $0x10,%eax
40001fa3:	85 c0                	test   %eax,%eax
40001fa5:	74 0e                	je     40001fb5 <filedesc_write+0x8f>
		fd->ofs = fi->size;
40001fa7:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001faa:	8b 40 4c             	mov    0x4c(%eax),%eax
40001fad:	89 c2                	mov    %eax,%edx
40001faf:	8b 45 08             	mov    0x8(%ebp),%eax
40001fb2:	89 50 08             	mov    %edx,0x8(%eax)

	// Write the data, growing the file as necessary.
	ssize_t actual = fileino_write(fd->ino, fd->ofs, buf, eltsize, count);
40001fb5:	8b 45 08             	mov    0x8(%ebp),%eax
40001fb8:	8b 50 08             	mov    0x8(%eax),%edx
40001fbb:	8b 45 08             	mov    0x8(%ebp),%eax
40001fbe:	8b 00                	mov    (%eax),%eax
40001fc0:	8b 4d 14             	mov    0x14(%ebp),%ecx
40001fc3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
40001fc7:	8b 4d 10             	mov    0x10(%ebp),%ecx
40001fca:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
40001fce:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40001fd1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40001fd5:	89 54 24 04          	mov    %edx,0x4(%esp)
40001fd9:	89 04 24             	mov    %eax,(%esp)
40001fdc:	e8 f9 f4 ff ff       	call   400014da <fileino_write>
40001fe1:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (actual < 0) {
40001fe4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40001fe8:	79 17                	jns    40002001 <filedesc_write+0xdb>
		fd->err = errno;	// save error indication for ferror()
40001fea:	a1 48 34 00 40       	mov    0x40003448,%eax
40001fef:	8b 10                	mov    (%eax),%edx
40001ff1:	8b 45 08             	mov    0x8(%ebp),%eax
40001ff4:	89 50 0c             	mov    %edx,0xc(%eax)
		return -1;
40001ff7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40001ffc:	e9 98 00 00 00       	jmp    40002099 <filedesc_write+0x173>
	}
	assert(actual == count);
40002001:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002004:	3b 45 14             	cmp    0x14(%ebp),%eax
40002007:	74 24                	je     4000202d <filedesc_write+0x107>
40002009:	c7 44 24 0c 47 36 00 	movl   $0x40003647,0xc(%esp)
40002010:	40 
40002011:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
40002018:	40 
40002019:	c7 44 24 04 5c 01 00 	movl   $0x15c,0x4(%esp)
40002020:	00 
40002021:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
40002028:	e8 33 ef ff ff       	call   40000f60 <debug_panic>

	// Non-append-only writes constitute exclusive modifications,
	// so must bump the file's version number.
	if (!(fd->flags & O_APPEND))
4000202d:	8b 45 08             	mov    0x8(%ebp),%eax
40002030:	8b 40 04             	mov    0x4(%eax),%eax
40002033:	83 e0 10             	and    $0x10,%eax
40002036:	85 c0                	test   %eax,%eax
40002038:	75 0f                	jne    40002049 <filedesc_write+0x123>
		fi->ver++;
4000203a:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000203d:	8b 40 44             	mov    0x44(%eax),%eax
40002040:	8d 50 01             	lea    0x1(%eax),%edx
40002043:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002046:	89 50 44             	mov    %edx,0x44(%eax)

	// Advance the file position
	fd->ofs += eltsize * count;
40002049:	8b 45 08             	mov    0x8(%ebp),%eax
4000204c:	8b 40 08             	mov    0x8(%eax),%eax
4000204f:	89 c2                	mov    %eax,%edx
40002051:	8b 45 10             	mov    0x10(%ebp),%eax
40002054:	0f af 45 14          	imul   0x14(%ebp),%eax
40002058:	01 d0                	add    %edx,%eax
4000205a:	89 c2                	mov    %eax,%edx
4000205c:	8b 45 08             	mov    0x8(%ebp),%eax
4000205f:	89 50 08             	mov    %edx,0x8(%eax)
	assert(fi->size >= fd->ofs);
40002062:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002065:	8b 50 4c             	mov    0x4c(%eax),%edx
40002068:	8b 45 08             	mov    0x8(%ebp),%eax
4000206b:	8b 40 08             	mov    0x8(%eax),%eax
4000206e:	39 c2                	cmp    %eax,%edx
40002070:	73 24                	jae    40002096 <filedesc_write+0x170>
40002072:	c7 44 24 0c 57 36 00 	movl   $0x40003657,0xc(%esp)
40002079:	40 
4000207a:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
40002081:	40 
40002082:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
40002089:	00 
4000208a:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
40002091:	e8 ca ee ff ff       	call   40000f60 <debug_panic>
	return count;
40002096:	8b 45 14             	mov    0x14(%ebp),%eax
}
40002099:	c9                   	leave  
4000209a:	c3                   	ret    

4000209b <filedesc_seek>:
// which may be relative to the file start, end, or corrent position,
// depending on 'whence' (SEEK_SET, SEEK_CUR, or SEEK_END).
// Returns the resulting absolute file position,
// or returns -1 and sets errno appropriately on error.
off_t filedesc_seek(filedesc *fd, off_t offset, int whence)
{
4000209b:	55                   	push   %ebp
4000209c:	89 e5                	mov    %esp,%ebp
4000209e:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isopen(fd));
400020a1:	a1 48 34 00 40       	mov    0x40003448,%eax
400020a6:	83 c0 10             	add    $0x10,%eax
400020a9:	3b 45 08             	cmp    0x8(%ebp),%eax
400020ac:	77 18                	ja     400020c6 <filedesc_seek+0x2b>
400020ae:	a1 48 34 00 40       	mov    0x40003448,%eax
400020b3:	05 10 10 00 00       	add    $0x1010,%eax
400020b8:	3b 45 08             	cmp    0x8(%ebp),%eax
400020bb:	76 09                	jbe    400020c6 <filedesc_seek+0x2b>
400020bd:	8b 45 08             	mov    0x8(%ebp),%eax
400020c0:	8b 00                	mov    (%eax),%eax
400020c2:	85 c0                	test   %eax,%eax
400020c4:	75 24                	jne    400020ea <filedesc_seek+0x4f>
400020c6:	c7 44 24 0c e0 35 00 	movl   $0x400035e0,0xc(%esp)
400020cd:	40 
400020ce:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
400020d5:	40 
400020d6:	c7 44 24 04 70 01 00 	movl   $0x170,0x4(%esp)
400020dd:	00 
400020de:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
400020e5:	e8 76 ee ff ff       	call   40000f60 <debug_panic>
	assert(whence == SEEK_SET || whence == SEEK_CUR || whence == SEEK_END);
400020ea:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400020ee:	74 30                	je     40002120 <filedesc_seek+0x85>
400020f0:	83 7d 10 01          	cmpl   $0x1,0x10(%ebp)
400020f4:	74 2a                	je     40002120 <filedesc_seek+0x85>
400020f6:	83 7d 10 02          	cmpl   $0x2,0x10(%ebp)
400020fa:	74 24                	je     40002120 <filedesc_seek+0x85>
400020fc:	c7 44 24 0c 6c 36 00 	movl   $0x4000366c,0xc(%esp)
40002103:	40 
40002104:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
4000210b:	40 
4000210c:	c7 44 24 04 71 01 00 	movl   $0x171,0x4(%esp)
40002113:	00 
40002114:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
4000211b:	e8 40 ee ff ff       	call   40000f60 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40002120:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40002126:	8b 45 08             	mov    0x8(%ebp),%eax
40002129:	8b 00                	mov    (%eax),%eax
4000212b:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000212e:	05 10 10 00 00       	add    $0x1010,%eax
40002133:	01 d0                	add    %edx,%eax
40002135:	89 45 f4             	mov    %eax,-0xc(%ebp)
	ino_t ino = fd->ino;
40002138:	8b 45 08             	mov    0x8(%ebp),%eax
4000213b:	8b 00                	mov    (%eax),%eax
4000213d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint8_t* start_pos = FILEDATA(ino);
40002140:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002143:	c1 e0 16             	shl    $0x16,%eax
40002146:	05 00 00 00 80       	add    $0x80000000,%eax
4000214b:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// Lab 4: insert your file descriptor seek implementation here.
	//warn("filedesc_seek() not implemented");
	//errno = EINVAL;
	//return -1;
	switch(whence){
4000214e:	8b 45 10             	mov    0x10(%ebp),%eax
40002151:	83 f8 01             	cmp    $0x1,%eax
40002154:	74 14                	je     4000216a <filedesc_seek+0xcf>
40002156:	83 f8 02             	cmp    $0x2,%eax
40002159:	74 22                	je     4000217d <filedesc_seek+0xe2>
4000215b:	85 c0                	test   %eax,%eax
4000215d:	75 33                	jne    40002192 <filedesc_seek+0xf7>
	case SEEK_SET:
		fd->ofs = offset;
4000215f:	8b 45 08             	mov    0x8(%ebp),%eax
40002162:	8b 55 0c             	mov    0xc(%ebp),%edx
40002165:	89 50 08             	mov    %edx,0x8(%eax)
		break;
40002168:	eb 3a                	jmp    400021a4 <filedesc_seek+0x109>
	case SEEK_CUR:
		fd->ofs += offset;
4000216a:	8b 45 08             	mov    0x8(%ebp),%eax
4000216d:	8b 50 08             	mov    0x8(%eax),%edx
40002170:	8b 45 0c             	mov    0xc(%ebp),%eax
40002173:	01 c2                	add    %eax,%edx
40002175:	8b 45 08             	mov    0x8(%ebp),%eax
40002178:	89 50 08             	mov    %edx,0x8(%eax)
		break;
4000217b:	eb 27                	jmp    400021a4 <filedesc_seek+0x109>
	case SEEK_END:
		fd->ofs = (fi->size) + offset;
4000217d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002180:	8b 50 4c             	mov    0x4c(%eax),%edx
40002183:	8b 45 0c             	mov    0xc(%ebp),%eax
40002186:	01 d0                	add    %edx,%eax
40002188:	89 c2                	mov    %eax,%edx
4000218a:	8b 45 08             	mov    0x8(%ebp),%eax
4000218d:	89 50 08             	mov    %edx,0x8(%eax)
		break;
40002190:	eb 12                	jmp    400021a4 <filedesc_seek+0x109>
	default:
		errno = EINVAL;
40002192:	a1 48 34 00 40       	mov    0x40003448,%eax
40002197:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
		return -1;
4000219d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400021a2:	eb 06                	jmp    400021aa <filedesc_seek+0x10f>
	}
	return fd->ofs;
400021a4:	8b 45 08             	mov    0x8(%ebp),%eax
400021a7:	8b 40 08             	mov    0x8(%eax),%eax
}
400021aa:	c9                   	leave  
400021ab:	c3                   	ret    

400021ac <filedesc_close>:

void
filedesc_close(filedesc *fd)
{
400021ac:	55                   	push   %ebp
400021ad:	89 e5                	mov    %esp,%ebp
400021af:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
400021b2:	a1 48 34 00 40       	mov    0x40003448,%eax
400021b7:	83 c0 10             	add    $0x10,%eax
400021ba:	3b 45 08             	cmp    0x8(%ebp),%eax
400021bd:	77 18                	ja     400021d7 <filedesc_close+0x2b>
400021bf:	a1 48 34 00 40       	mov    0x40003448,%eax
400021c4:	05 10 10 00 00       	add    $0x1010,%eax
400021c9:	3b 45 08             	cmp    0x8(%ebp),%eax
400021cc:	76 09                	jbe    400021d7 <filedesc_close+0x2b>
400021ce:	8b 45 08             	mov    0x8(%ebp),%eax
400021d1:	8b 00                	mov    (%eax),%eax
400021d3:	85 c0                	test   %eax,%eax
400021d5:	75 24                	jne    400021fb <filedesc_close+0x4f>
400021d7:	c7 44 24 0c e0 35 00 	movl   $0x400035e0,0xc(%esp)
400021de:	40 
400021df:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
400021e6:	40 
400021e7:	c7 44 24 04 8e 01 00 	movl   $0x18e,0x4(%esp)
400021ee:	00 
400021ef:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
400021f6:	e8 65 ed ff ff       	call   40000f60 <debug_panic>
	assert(fileino_isvalid(fd->ino));
400021fb:	8b 45 08             	mov    0x8(%ebp),%eax
400021fe:	8b 00                	mov    (%eax),%eax
40002200:	85 c0                	test   %eax,%eax
40002202:	7e 0c                	jle    40002210 <filedesc_close+0x64>
40002204:	8b 45 08             	mov    0x8(%ebp),%eax
40002207:	8b 00                	mov    (%eax),%eax
40002209:	3d ff 00 00 00       	cmp    $0xff,%eax
4000220e:	7e 24                	jle    40002234 <filedesc_close+0x88>
40002210:	c7 44 24 0c ab 36 00 	movl   $0x400036ab,0xc(%esp)
40002217:	40 
40002218:	c7 44 24 08 80 34 00 	movl   $0x40003480,0x8(%esp)
4000221f:	40 
40002220:	c7 44 24 04 8f 01 00 	movl   $0x18f,0x4(%esp)
40002227:	00 
40002228:	c7 04 24 6b 34 00 40 	movl   $0x4000346b,(%esp)
4000222f:	e8 2c ed ff ff       	call   40000f60 <debug_panic>

	fd->ino = FILEINO_NULL;		// mark the fd free
40002234:	8b 45 08             	mov    0x8(%ebp),%eax
40002237:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
4000223d:	c9                   	leave  
4000223e:	c3                   	ret    
4000223f:	90                   	nop

40002240 <dir_walk>:
#include <inc/dirent.h>


int
dir_walk(const char *path, mode_t createmode)
{
40002240:	55                   	push   %ebp
40002241:	89 e5                	mov    %esp,%ebp
40002243:	83 ec 28             	sub    $0x28,%esp
	assert(path != 0 && *path != 0);
40002246:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
4000224a:	74 0a                	je     40002256 <dir_walk+0x16>
4000224c:	8b 45 08             	mov    0x8(%ebp),%eax
4000224f:	0f b6 00             	movzbl (%eax),%eax
40002252:	84 c0                	test   %al,%al
40002254:	75 24                	jne    4000227a <dir_walk+0x3a>
40002256:	c7 44 24 0c c4 36 00 	movl   $0x400036c4,0xc(%esp)
4000225d:	40 
4000225e:	c7 44 24 08 dc 36 00 	movl   $0x400036dc,0x8(%esp)
40002265:	40 
40002266:	c7 44 24 04 15 00 00 	movl   $0x15,0x4(%esp)
4000226d:	00 
4000226e:	c7 04 24 f1 36 00 40 	movl   $0x400036f1,(%esp)
40002275:	e8 e6 ec ff ff       	call   40000f60 <debug_panic>

	// Start at the current or root directory as appropriate
	int dino = files->cwd;
4000227a:	a1 48 34 00 40       	mov    0x40003448,%eax
4000227f:	8b 40 04             	mov    0x4(%eax),%eax
40002282:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (*path == '/') {
40002285:	8b 45 08             	mov    0x8(%ebp),%eax
40002288:	0f b6 00             	movzbl (%eax),%eax
4000228b:	3c 2f                	cmp    $0x2f,%al
4000228d:	75 27                	jne    400022b6 <dir_walk+0x76>
		dino = FILEINO_ROOTDIR;
4000228f:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
		do { path++; } while (*path == '/');	// skip leading slashes
40002296:	83 45 08 01          	addl   $0x1,0x8(%ebp)
4000229a:	8b 45 08             	mov    0x8(%ebp),%eax
4000229d:	0f b6 00             	movzbl (%eax),%eax
400022a0:	3c 2f                	cmp    $0x2f,%al
400022a2:	74 f2                	je     40002296 <dir_walk+0x56>
		if (*path == 0)
400022a4:	8b 45 08             	mov    0x8(%ebp),%eax
400022a7:	0f b6 00             	movzbl (%eax),%eax
400022aa:	84 c0                	test   %al,%al
400022ac:	75 08                	jne    400022b6 <dir_walk+0x76>
			return dino;	// Just looking up root directory
400022ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
400022b1:	e9 61 05 00 00       	jmp    40002817 <dir_walk+0x5d7>
	}

	// Search for the appropriate entry in this directory
	searchdir:
	assert(fileino_isdir(dino));
400022b6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
400022ba:	7e 45                	jle    40002301 <dir_walk+0xc1>
400022bc:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
400022c3:	7f 3c                	jg     40002301 <dir_walk+0xc1>
400022c5:	8b 15 48 34 00 40    	mov    0x40003448,%edx
400022cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
400022ce:	6b c0 5c             	imul   $0x5c,%eax,%eax
400022d1:	01 d0                	add    %edx,%eax
400022d3:	05 10 10 00 00       	add    $0x1010,%eax
400022d8:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400022dc:	84 c0                	test   %al,%al
400022de:	74 21                	je     40002301 <dir_walk+0xc1>
400022e0:	8b 15 48 34 00 40    	mov    0x40003448,%edx
400022e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
400022e9:	6b c0 5c             	imul   $0x5c,%eax,%eax
400022ec:	01 d0                	add    %edx,%eax
400022ee:	05 58 10 00 00       	add    $0x1058,%eax
400022f3:	8b 00                	mov    (%eax),%eax
400022f5:	25 00 70 00 00       	and    $0x7000,%eax
400022fa:	3d 00 20 00 00       	cmp    $0x2000,%eax
400022ff:	74 24                	je     40002325 <dir_walk+0xe5>
40002301:	c7 44 24 0c fb 36 00 	movl   $0x400036fb,0xc(%esp)
40002308:	40 
40002309:	c7 44 24 08 dc 36 00 	movl   $0x400036dc,0x8(%esp)
40002310:	40 
40002311:	c7 44 24 04 22 00 00 	movl   $0x22,0x4(%esp)
40002318:	00 
40002319:	c7 04 24 f1 36 00 40 	movl   $0x400036f1,(%esp)
40002320:	e8 3b ec ff ff       	call   40000f60 <debug_panic>
	assert(fileino_isdir(files->fi[dino].dino));
40002325:	8b 15 48 34 00 40    	mov    0x40003448,%edx
4000232b:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000232e:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002331:	01 d0                	add    %edx,%eax
40002333:	05 10 10 00 00       	add    $0x1010,%eax
40002338:	8b 00                	mov    (%eax),%eax
4000233a:	85 c0                	test   %eax,%eax
4000233c:	7e 7c                	jle    400023ba <dir_walk+0x17a>
4000233e:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40002344:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002347:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000234a:	01 d0                	add    %edx,%eax
4000234c:	05 10 10 00 00       	add    $0x1010,%eax
40002351:	8b 00                	mov    (%eax),%eax
40002353:	3d ff 00 00 00       	cmp    $0xff,%eax
40002358:	7f 60                	jg     400023ba <dir_walk+0x17a>
4000235a:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40002360:	8b 0d 48 34 00 40    	mov    0x40003448,%ecx
40002366:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002369:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000236c:	01 c8                	add    %ecx,%eax
4000236e:	05 10 10 00 00       	add    $0x1010,%eax
40002373:	8b 00                	mov    (%eax),%eax
40002375:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002378:	01 d0                	add    %edx,%eax
4000237a:	05 10 10 00 00       	add    $0x1010,%eax
4000237f:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002383:	84 c0                	test   %al,%al
40002385:	74 33                	je     400023ba <dir_walk+0x17a>
40002387:	8b 15 48 34 00 40    	mov    0x40003448,%edx
4000238d:	8b 0d 48 34 00 40    	mov    0x40003448,%ecx
40002393:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002396:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002399:	01 c8                	add    %ecx,%eax
4000239b:	05 10 10 00 00       	add    $0x1010,%eax
400023a0:	8b 00                	mov    (%eax),%eax
400023a2:	6b c0 5c             	imul   $0x5c,%eax,%eax
400023a5:	01 d0                	add    %edx,%eax
400023a7:	05 58 10 00 00       	add    $0x1058,%eax
400023ac:	8b 00                	mov    (%eax),%eax
400023ae:	25 00 70 00 00       	and    $0x7000,%eax
400023b3:	3d 00 20 00 00       	cmp    $0x2000,%eax
400023b8:	74 24                	je     400023de <dir_walk+0x19e>
400023ba:	c7 44 24 0c 10 37 00 	movl   $0x40003710,0xc(%esp)
400023c1:	40 
400023c2:	c7 44 24 08 dc 36 00 	movl   $0x400036dc,0x8(%esp)
400023c9:	40 
400023ca:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
400023d1:	00 
400023d2:	c7 04 24 f1 36 00 40 	movl   $0x400036f1,(%esp)
400023d9:	e8 82 eb ff ff       	call   40000f60 <debug_panic>

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
400023de:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
400023e5:	e9 3d 02 00 00       	jmp    40002627 <dir_walk+0x3e7>
		if (!fileino_alloced(ino) || files->fi[ino].dino != dino)
400023ea:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400023ee:	0f 8e 28 02 00 00    	jle    4000261c <dir_walk+0x3dc>
400023f4:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
400023fb:	0f 8f 1b 02 00 00    	jg     4000261c <dir_walk+0x3dc>
40002401:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40002407:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000240a:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000240d:	01 d0                	add    %edx,%eax
4000240f:	05 10 10 00 00       	add    $0x1010,%eax
40002414:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002418:	84 c0                	test   %al,%al
4000241a:	0f 84 fc 01 00 00    	je     4000261c <dir_walk+0x3dc>
40002420:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40002426:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002429:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000242c:	01 d0                	add    %edx,%eax
4000242e:	05 10 10 00 00       	add    $0x1010,%eax
40002433:	8b 00                	mov    (%eax),%eax
40002435:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40002438:	0f 85 de 01 00 00    	jne    4000261c <dir_walk+0x3dc>
			continue;	// not an entry in directory 'dino'

		// Does this inode's name match our next path component?
		len = strlen(files->fi[ino].de.d_name);
4000243e:	a1 48 34 00 40       	mov    0x40003448,%eax
40002443:	8b 55 f0             	mov    -0x10(%ebp),%edx
40002446:	6b d2 5c             	imul   $0x5c,%edx,%edx
40002449:	81 c2 10 10 00 00    	add    $0x1010,%edx
4000244f:	01 d0                	add    %edx,%eax
40002451:	83 c0 04             	add    $0x4,%eax
40002454:	89 04 24             	mov    %eax,(%esp)
40002457:	e8 6c e5 ff ff       	call   400009c8 <strlen>
4000245c:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (memcmp(path, files->fi[ino].de.d_name, len) != 0)
4000245f:	8b 45 ec             	mov    -0x14(%ebp),%eax
40002462:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40002468:	8b 4d f0             	mov    -0x10(%ebp),%ecx
4000246b:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
4000246e:	81 c1 10 10 00 00    	add    $0x1010,%ecx
40002474:	01 ca                	add    %ecx,%edx
40002476:	83 c2 04             	add    $0x4,%edx
40002479:	89 44 24 08          	mov    %eax,0x8(%esp)
4000247d:	89 54 24 04          	mov    %edx,0x4(%esp)
40002481:	8b 45 08             	mov    0x8(%ebp),%eax
40002484:	89 04 24             	mov    %eax,(%esp)
40002487:	e8 62 e8 ff ff       	call   40000cee <memcmp>
4000248c:	85 c0                	test   %eax,%eax
4000248e:	0f 85 8b 01 00 00    	jne    4000261f <dir_walk+0x3df>
			continue;	// no match
		found:
		if (path[len] == 0) {
40002494:	8b 55 ec             	mov    -0x14(%ebp),%edx
40002497:	8b 45 08             	mov    0x8(%ebp),%eax
4000249a:	01 d0                	add    %edx,%eax
4000249c:	0f b6 00             	movzbl (%eax),%eax
4000249f:	84 c0                	test   %al,%al
400024a1:	0f 85 c7 00 00 00    	jne    4000256e <dir_walk+0x32e>
			// Exact match at end of path - but does it exist?
			if (fileino_exists(ino))
400024a7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400024ab:	7e 45                	jle    400024f2 <dir_walk+0x2b2>
400024ad:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
400024b4:	7f 3c                	jg     400024f2 <dir_walk+0x2b2>
400024b6:	8b 15 48 34 00 40    	mov    0x40003448,%edx
400024bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
400024bf:	6b c0 5c             	imul   $0x5c,%eax,%eax
400024c2:	01 d0                	add    %edx,%eax
400024c4:	05 10 10 00 00       	add    $0x1010,%eax
400024c9:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400024cd:	84 c0                	test   %al,%al
400024cf:	74 21                	je     400024f2 <dir_walk+0x2b2>
400024d1:	8b 15 48 34 00 40    	mov    0x40003448,%edx
400024d7:	8b 45 f0             	mov    -0x10(%ebp),%eax
400024da:	6b c0 5c             	imul   $0x5c,%eax,%eax
400024dd:	01 d0                	add    %edx,%eax
400024df:	05 58 10 00 00       	add    $0x1058,%eax
400024e4:	8b 00                	mov    (%eax),%eax
400024e6:	85 c0                	test   %eax,%eax
400024e8:	74 08                	je     400024f2 <dir_walk+0x2b2>
				return ino;	// yes - return it
400024ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
400024ed:	e9 25 03 00 00       	jmp    40002817 <dir_walk+0x5d7>

			// no - existed, but was deleted.  re-create?
			if (!createmode) {
400024f2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400024f6:	75 15                	jne    4000250d <dir_walk+0x2cd>
				errno = ENOENT;
400024f8:	a1 48 34 00 40       	mov    0x40003448,%eax
400024fd:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
				return -1;
40002503:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002508:	e9 0a 03 00 00       	jmp    40002817 <dir_walk+0x5d7>
			}
			files->fi[ino].ver++;	// an exclusive change
4000250d:	a1 48 34 00 40       	mov    0x40003448,%eax
40002512:	8b 55 f0             	mov    -0x10(%ebp),%edx
40002515:	6b d2 5c             	imul   $0x5c,%edx,%edx
40002518:	01 c2                	add    %eax,%edx
4000251a:	81 c2 54 10 00 00    	add    $0x1054,%edx
40002520:	8b 12                	mov    (%edx),%edx
40002522:	83 c2 01             	add    $0x1,%edx
40002525:	8b 4d f0             	mov    -0x10(%ebp),%ecx
40002528:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
4000252b:	01 c8                	add    %ecx,%eax
4000252d:	05 54 10 00 00       	add    $0x1054,%eax
40002532:	89 10                	mov    %edx,(%eax)
			files->fi[ino].mode = createmode;
40002534:	8b 15 48 34 00 40    	mov    0x40003448,%edx
4000253a:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000253d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002540:	01 d0                	add    %edx,%eax
40002542:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
40002548:	8b 45 0c             	mov    0xc(%ebp),%eax
4000254b:	89 02                	mov    %eax,(%edx)
			files->fi[ino].size = 0;
4000254d:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40002553:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002556:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002559:	01 d0                	add    %edx,%eax
4000255b:	05 5c 10 00 00       	add    $0x105c,%eax
40002560:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			return ino;
40002566:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002569:	e9 a9 02 00 00       	jmp    40002817 <dir_walk+0x5d7>
		}
		if (path[len] != '/')
4000256e:	8b 55 ec             	mov    -0x14(%ebp),%edx
40002571:	8b 45 08             	mov    0x8(%ebp),%eax
40002574:	01 d0                	add    %edx,%eax
40002576:	0f b6 00             	movzbl (%eax),%eax
40002579:	3c 2f                	cmp    $0x2f,%al
4000257b:	0f 85 a1 00 00 00    	jne    40002622 <dir_walk+0x3e2>
			continue;	// no match

		// Make sure this dirent refers to a directory
		if (!fileino_isdir(ino)) {
40002581:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002585:	7e 45                	jle    400025cc <dir_walk+0x38c>
40002587:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
4000258e:	7f 3c                	jg     400025cc <dir_walk+0x38c>
40002590:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40002596:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002599:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000259c:	01 d0                	add    %edx,%eax
4000259e:	05 10 10 00 00       	add    $0x1010,%eax
400025a3:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400025a7:	84 c0                	test   %al,%al
400025a9:	74 21                	je     400025cc <dir_walk+0x38c>
400025ab:	8b 15 48 34 00 40    	mov    0x40003448,%edx
400025b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
400025b4:	6b c0 5c             	imul   $0x5c,%eax,%eax
400025b7:	01 d0                	add    %edx,%eax
400025b9:	05 58 10 00 00       	add    $0x1058,%eax
400025be:	8b 00                	mov    (%eax),%eax
400025c0:	25 00 70 00 00       	and    $0x7000,%eax
400025c5:	3d 00 20 00 00       	cmp    $0x2000,%eax
400025ca:	74 15                	je     400025e1 <dir_walk+0x3a1>
			errno = ENOTDIR;
400025cc:	a1 48 34 00 40       	mov    0x40003448,%eax
400025d1:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
			return -1;
400025d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400025dc:	e9 36 02 00 00       	jmp    40002817 <dir_walk+0x5d7>
		}

		// Skip slashes to find next component
		do { len++; } while (path[len] == '/');
400025e1:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
400025e5:	8b 55 ec             	mov    -0x14(%ebp),%edx
400025e8:	8b 45 08             	mov    0x8(%ebp),%eax
400025eb:	01 d0                	add    %edx,%eax
400025ed:	0f b6 00             	movzbl (%eax),%eax
400025f0:	3c 2f                	cmp    $0x2f,%al
400025f2:	74 ed                	je     400025e1 <dir_walk+0x3a1>
		if (path[len] == 0)
400025f4:	8b 55 ec             	mov    -0x14(%ebp),%edx
400025f7:	8b 45 08             	mov    0x8(%ebp),%eax
400025fa:	01 d0                	add    %edx,%eax
400025fc:	0f b6 00             	movzbl (%eax),%eax
400025ff:	84 c0                	test   %al,%al
40002601:	75 08                	jne    4000260b <dir_walk+0x3cb>
			return ino;	// matched directory at end of path
40002603:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002606:	e9 0c 02 00 00       	jmp    40002817 <dir_walk+0x5d7>

		// Walk the next directory in the path
		dino = ino;
4000260b:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000260e:	89 45 f4             	mov    %eax,-0xc(%ebp)
		path += len;
40002611:	8b 45 ec             	mov    -0x14(%ebp),%eax
40002614:	01 45 08             	add    %eax,0x8(%ebp)
		goto searchdir;
40002617:	e9 9a fc ff ff       	jmp    400022b6 <dir_walk+0x76>

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
		if (!fileino_alloced(ino) || files->fi[ino].dino != dino)
			continue;	// not an entry in directory 'dino'
4000261c:	90                   	nop
4000261d:	eb 04                	jmp    40002623 <dir_walk+0x3e3>

		// Does this inode's name match our next path component?
		len = strlen(files->fi[ino].de.d_name);
		if (memcmp(path, files->fi[ino].de.d_name, len) != 0)
			continue;	// no match
4000261f:	90                   	nop
40002620:	eb 01                	jmp    40002623 <dir_walk+0x3e3>
			files->fi[ino].mode = createmode;
			files->fi[ino].size = 0;
			return ino;
		}
		if (path[len] != '/')
			continue;	// no match
40002622:	90                   	nop
	assert(fileino_isdir(dino));
	assert(fileino_isdir(files->fi[dino].dino));

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
40002623:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
40002627:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
4000262e:	0f 8e b6 fd ff ff    	jle    400023ea <dir_walk+0x1aa>
		path += len;
		goto searchdir;
	}

	// Looking for one of the special entries '.' or '..'?
	if (path[0] == '.' && (path[1] == 0 || path[1] == '/')) {
40002634:	8b 45 08             	mov    0x8(%ebp),%eax
40002637:	0f b6 00             	movzbl (%eax),%eax
4000263a:	3c 2e                	cmp    $0x2e,%al
4000263c:	75 2c                	jne    4000266a <dir_walk+0x42a>
4000263e:	8b 45 08             	mov    0x8(%ebp),%eax
40002641:	83 c0 01             	add    $0x1,%eax
40002644:	0f b6 00             	movzbl (%eax),%eax
40002647:	84 c0                	test   %al,%al
40002649:	74 0d                	je     40002658 <dir_walk+0x418>
4000264b:	8b 45 08             	mov    0x8(%ebp),%eax
4000264e:	83 c0 01             	add    $0x1,%eax
40002651:	0f b6 00             	movzbl (%eax),%eax
40002654:	3c 2f                	cmp    $0x2f,%al
40002656:	75 12                	jne    4000266a <dir_walk+0x42a>
		len = 1;
40002658:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		ino = dino;	// just leads to this same directory
4000265f:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002662:	89 45 f0             	mov    %eax,-0x10(%ebp)
		goto found;
40002665:	e9 2a fe ff ff       	jmp    40002494 <dir_walk+0x254>
	}
	if (path[0] == '.' && path[1] == '.'
4000266a:	8b 45 08             	mov    0x8(%ebp),%eax
4000266d:	0f b6 00             	movzbl (%eax),%eax
40002670:	3c 2e                	cmp    $0x2e,%al
40002672:	75 4b                	jne    400026bf <dir_walk+0x47f>
40002674:	8b 45 08             	mov    0x8(%ebp),%eax
40002677:	83 c0 01             	add    $0x1,%eax
4000267a:	0f b6 00             	movzbl (%eax),%eax
4000267d:	3c 2e                	cmp    $0x2e,%al
4000267f:	75 3e                	jne    400026bf <dir_walk+0x47f>
			&& (path[2] == 0 || path[2] == '/')) {
40002681:	8b 45 08             	mov    0x8(%ebp),%eax
40002684:	83 c0 02             	add    $0x2,%eax
40002687:	0f b6 00             	movzbl (%eax),%eax
4000268a:	84 c0                	test   %al,%al
4000268c:	74 0d                	je     4000269b <dir_walk+0x45b>
4000268e:	8b 45 08             	mov    0x8(%ebp),%eax
40002691:	83 c0 02             	add    $0x2,%eax
40002694:	0f b6 00             	movzbl (%eax),%eax
40002697:	3c 2f                	cmp    $0x2f,%al
40002699:	75 24                	jne    400026bf <dir_walk+0x47f>
		len = 2;
4000269b:	c7 45 ec 02 00 00 00 	movl   $0x2,-0x14(%ebp)
		ino = files->fi[dino].dino;	// leads to root directory
400026a2:	8b 15 48 34 00 40    	mov    0x40003448,%edx
400026a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
400026ab:	6b c0 5c             	imul   $0x5c,%eax,%eax
400026ae:	01 d0                	add    %edx,%eax
400026b0:	05 10 10 00 00       	add    $0x1010,%eax
400026b5:	8b 00                	mov    (%eax),%eax
400026b7:	89 45 f0             	mov    %eax,-0x10(%ebp)
		goto found;
400026ba:	e9 d5 fd ff ff       	jmp    40002494 <dir_walk+0x254>
	}

	// Path component not found - see if we should create it
	if (!createmode || strchr(path, '/') != NULL) {
400026bf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400026c3:	74 17                	je     400026dc <dir_walk+0x49c>
400026c5:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
400026cc:	00 
400026cd:	8b 45 08             	mov    0x8(%ebp),%eax
400026d0:	89 04 24             	mov    %eax,(%esp)
400026d3:	e8 75 e4 ff ff       	call   40000b4d <strchr>
400026d8:	85 c0                	test   %eax,%eax
400026da:	74 15                	je     400026f1 <dir_walk+0x4b1>
		errno = ENOENT;
400026dc:	a1 48 34 00 40       	mov    0x40003448,%eax
400026e1:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
		return -1;
400026e7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400026ec:	e9 26 01 00 00       	jmp    40002817 <dir_walk+0x5d7>
	}
	if (strlen(path) > NAME_MAX) {
400026f1:	8b 45 08             	mov    0x8(%ebp),%eax
400026f4:	89 04 24             	mov    %eax,(%esp)
400026f7:	e8 cc e2 ff ff       	call   400009c8 <strlen>
400026fc:	83 f8 3f             	cmp    $0x3f,%eax
400026ff:	7e 15                	jle    40002716 <dir_walk+0x4d6>
		errno = ENAMETOOLONG;
40002701:	a1 48 34 00 40       	mov    0x40003448,%eax
40002706:	c7 00 06 00 00 00    	movl   $0x6,(%eax)
		return -1;
4000270c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002711:	e9 01 01 00 00       	jmp    40002817 <dir_walk+0x5d7>
	}

	// Allocate a new inode and create this entry with the given mode.
	ino = fileino_alloc();
40002716:	e8 31 ea ff ff       	call   4000114c <fileino_alloc>
4000271b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (ino < 0)
4000271e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002722:	79 0a                	jns    4000272e <dir_walk+0x4ee>
		return -1;
40002724:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002729:	e9 e9 00 00 00       	jmp    40002817 <dir_walk+0x5d7>
	assert(fileino_isvalid(ino) && !fileino_alloced(ino));
4000272e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002732:	7e 33                	jle    40002767 <dir_walk+0x527>
40002734:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
4000273b:	7f 2a                	jg     40002767 <dir_walk+0x527>
4000273d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002741:	7e 48                	jle    4000278b <dir_walk+0x54b>
40002743:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
4000274a:	7f 3f                	jg     4000278b <dir_walk+0x54b>
4000274c:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40002752:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002755:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002758:	01 d0                	add    %edx,%eax
4000275a:	05 10 10 00 00       	add    $0x1010,%eax
4000275f:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002763:	84 c0                	test   %al,%al
40002765:	74 24                	je     4000278b <dir_walk+0x54b>
40002767:	c7 44 24 0c 34 37 00 	movl   $0x40003734,0xc(%esp)
4000276e:	40 
4000276f:	c7 44 24 08 dc 36 00 	movl   $0x400036dc,0x8(%esp)
40002776:	40 
40002777:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
4000277e:	00 
4000277f:	c7 04 24 f1 36 00 40 	movl   $0x400036f1,(%esp)
40002786:	e8 d5 e7 ff ff       	call   40000f60 <debug_panic>
	strcpy(files->fi[ino].de.d_name, path);
4000278b:	a1 48 34 00 40       	mov    0x40003448,%eax
40002790:	8b 55 f0             	mov    -0x10(%ebp),%edx
40002793:	6b d2 5c             	imul   $0x5c,%edx,%edx
40002796:	81 c2 10 10 00 00    	add    $0x1010,%edx
4000279c:	01 d0                	add    %edx,%eax
4000279e:	8d 50 04             	lea    0x4(%eax),%edx
400027a1:	8b 45 08             	mov    0x8(%ebp),%eax
400027a4:	89 44 24 04          	mov    %eax,0x4(%esp)
400027a8:	89 14 24             	mov    %edx,(%esp)
400027ab:	e8 3e e2 ff ff       	call   400009ee <strcpy>
	files->fi[ino].dino = dino;
400027b0:	8b 15 48 34 00 40    	mov    0x40003448,%edx
400027b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
400027b9:	6b c0 5c             	imul   $0x5c,%eax,%eax
400027bc:	01 d0                	add    %edx,%eax
400027be:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400027c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
400027c7:	89 02                	mov    %eax,(%edx)
	files->fi[ino].ver = 0;
400027c9:	8b 15 48 34 00 40    	mov    0x40003448,%edx
400027cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
400027d2:	6b c0 5c             	imul   $0x5c,%eax,%eax
400027d5:	01 d0                	add    %edx,%eax
400027d7:	05 54 10 00 00       	add    $0x1054,%eax
400027dc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	files->fi[ino].mode = createmode;
400027e2:	8b 15 48 34 00 40    	mov    0x40003448,%edx
400027e8:	8b 45 f0             	mov    -0x10(%ebp),%eax
400027eb:	6b c0 5c             	imul   $0x5c,%eax,%eax
400027ee:	01 d0                	add    %edx,%eax
400027f0:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
400027f6:	8b 45 0c             	mov    0xc(%ebp),%eax
400027f9:	89 02                	mov    %eax,(%edx)
	files->fi[ino].size = 0;
400027fb:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40002801:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002804:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002807:	01 d0                	add    %edx,%eax
40002809:	05 5c 10 00 00       	add    $0x105c,%eax
4000280e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return ino;
40002814:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40002817:	c9                   	leave  
40002818:	c3                   	ret    

40002819 <opendir>:
// Open a directory for scanning.
// For simplicity, DIR is simply a filedesc like other file descriptors,
// except we interpret fd->ofs as an inode number for scanning,
// instead of as a byte offset as in a regular file.
DIR *opendir(const char *path)
{
40002819:	55                   	push   %ebp
4000281a:	89 e5                	mov    %esp,%ebp
4000281c:	83 ec 28             	sub    $0x28,%esp
	filedesc *fd = filedesc_open(NULL, path, O_RDONLY, 0);
4000281f:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
40002826:	00 
40002827:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
4000282e:	00 
4000282f:	8b 45 08             	mov    0x8(%ebp),%eax
40002832:	89 44 24 04          	mov    %eax,0x4(%esp)
40002836:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000283d:	e8 a5 f3 ff ff       	call   40001be7 <filedesc_open>
40002842:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (fd == NULL)
40002845:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002849:	75 0a                	jne    40002855 <opendir+0x3c>
		return NULL;
4000284b:	b8 00 00 00 00       	mov    $0x0,%eax
40002850:	e9 bb 00 00 00       	jmp    40002910 <opendir+0xf7>

	// Make sure it's a directory
	assert(fileino_exists(fd->ino));
40002855:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002858:	8b 00                	mov    (%eax),%eax
4000285a:	85 c0                	test   %eax,%eax
4000285c:	7e 44                	jle    400028a2 <opendir+0x89>
4000285e:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002861:	8b 00                	mov    (%eax),%eax
40002863:	3d ff 00 00 00       	cmp    $0xff,%eax
40002868:	7f 38                	jg     400028a2 <opendir+0x89>
4000286a:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40002870:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002873:	8b 00                	mov    (%eax),%eax
40002875:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002878:	01 d0                	add    %edx,%eax
4000287a:	05 10 10 00 00       	add    $0x1010,%eax
4000287f:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002883:	84 c0                	test   %al,%al
40002885:	74 1b                	je     400028a2 <opendir+0x89>
40002887:	8b 15 48 34 00 40    	mov    0x40003448,%edx
4000288d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002890:	8b 00                	mov    (%eax),%eax
40002892:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002895:	01 d0                	add    %edx,%eax
40002897:	05 58 10 00 00       	add    $0x1058,%eax
4000289c:	8b 00                	mov    (%eax),%eax
4000289e:	85 c0                	test   %eax,%eax
400028a0:	75 24                	jne    400028c6 <opendir+0xad>
400028a2:	c7 44 24 0c 62 37 00 	movl   $0x40003762,0xc(%esp)
400028a9:	40 
400028aa:	c7 44 24 08 dc 36 00 	movl   $0x400036dc,0x8(%esp)
400028b1:	40 
400028b2:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
400028b9:	00 
400028ba:	c7 04 24 f1 36 00 40 	movl   $0x400036f1,(%esp)
400028c1:	e8 9a e6 ff ff       	call   40000f60 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
400028c6:	8b 15 48 34 00 40    	mov    0x40003448,%edx
400028cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
400028cf:	8b 00                	mov    (%eax),%eax
400028d1:	6b c0 5c             	imul   $0x5c,%eax,%eax
400028d4:	05 10 10 00 00       	add    $0x1010,%eax
400028d9:	01 d0                	add    %edx,%eax
400028db:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (!S_ISDIR(fi->mode)) {
400028de:	8b 45 f0             	mov    -0x10(%ebp),%eax
400028e1:	8b 40 48             	mov    0x48(%eax),%eax
400028e4:	25 00 70 00 00       	and    $0x7000,%eax
400028e9:	3d 00 20 00 00       	cmp    $0x2000,%eax
400028ee:	74 1d                	je     4000290d <opendir+0xf4>
		filedesc_close(fd);
400028f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
400028f3:	89 04 24             	mov    %eax,(%esp)
400028f6:	e8 b1 f8 ff ff       	call   400021ac <filedesc_close>
		errno = ENOTDIR;
400028fb:	a1 48 34 00 40       	mov    0x40003448,%eax
40002900:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
		return NULL;
40002906:	b8 00 00 00 00       	mov    $0x0,%eax
4000290b:	eb 03                	jmp    40002910 <opendir+0xf7>
	}

	return fd;
4000290d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
40002910:	c9                   	leave  
40002911:	c3                   	ret    

40002912 <closedir>:

int closedir(DIR *dir)
{
40002912:	55                   	push   %ebp
40002913:	89 e5                	mov    %esp,%ebp
40002915:	83 ec 18             	sub    $0x18,%esp
	filedesc_close(dir);
40002918:	8b 45 08             	mov    0x8(%ebp),%eax
4000291b:	89 04 24             	mov    %eax,(%esp)
4000291e:	e8 89 f8 ff ff       	call   400021ac <filedesc_close>
	return 0;
40002923:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002928:	c9                   	leave  
40002929:	c3                   	ret    

4000292a <readdir>:

// Scan an open directory filedesc and return the next entry.
// Returns a pointer to the next matching file inode's 'dirent' struct,
// or NULL if the directory being scanned contains no more entries.
struct dirent *readdir(DIR *dir)
{
4000292a:	55                   	push   %ebp
4000292b:	89 e5                	mov    %esp,%ebp
4000292d:	83 ec 28             	sub    $0x28,%esp
	// Hint: a fileinode's 'dino' field indicates
	// what directory the file is in;
	// this function shouldn't return entries from other directories!
	//warn("readdir() not implemented");
	//return NULL;
	assert(fileino_isdir(dir->ino));
40002930:	8b 45 08             	mov    0x8(%ebp),%eax
40002933:	8b 00                	mov    (%eax),%eax
40002935:	85 c0                	test   %eax,%eax
40002937:	7e 4c                	jle    40002985 <readdir+0x5b>
40002939:	8b 45 08             	mov    0x8(%ebp),%eax
4000293c:	8b 00                	mov    (%eax),%eax
4000293e:	3d ff 00 00 00       	cmp    $0xff,%eax
40002943:	7f 40                	jg     40002985 <readdir+0x5b>
40002945:	8b 15 48 34 00 40    	mov    0x40003448,%edx
4000294b:	8b 45 08             	mov    0x8(%ebp),%eax
4000294e:	8b 00                	mov    (%eax),%eax
40002950:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002953:	01 d0                	add    %edx,%eax
40002955:	05 10 10 00 00       	add    $0x1010,%eax
4000295a:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000295e:	84 c0                	test   %al,%al
40002960:	74 23                	je     40002985 <readdir+0x5b>
40002962:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40002968:	8b 45 08             	mov    0x8(%ebp),%eax
4000296b:	8b 00                	mov    (%eax),%eax
4000296d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002970:	01 d0                	add    %edx,%eax
40002972:	05 58 10 00 00       	add    $0x1058,%eax
40002977:	8b 00                	mov    (%eax),%eax
40002979:	25 00 70 00 00       	and    $0x7000,%eax
4000297e:	3d 00 20 00 00       	cmp    $0x2000,%eax
40002983:	74 24                	je     400029a9 <readdir+0x7f>
40002985:	c7 44 24 0c 7a 37 00 	movl   $0x4000377a,0xc(%esp)
4000298c:	40 
4000298d:	c7 44 24 08 dc 36 00 	movl   $0x400036dc,0x8(%esp)
40002994:	40 
40002995:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
4000299c:	00 
4000299d:	c7 04 24 f1 36 00 40 	movl   $0x400036f1,(%esp)
400029a4:	e8 b7 e5 ff ff       	call   40000f60 <debug_panic>
	int i = dir->ofs;
400029a9:	8b 45 08             	mov    0x8(%ebp),%eax
400029ac:	8b 40 08             	mov    0x8(%eax),%eax
400029af:	89 45 f4             	mov    %eax,-0xc(%ebp)
	for(i; i < FILE_INODES; i++){
400029b2:	eb 3c                	jmp    400029f0 <readdir+0xc6>
		fileinode* tmp_fi = &files->fi[i];
400029b4:	a1 48 34 00 40       	mov    0x40003448,%eax
400029b9:	8b 55 f4             	mov    -0xc(%ebp),%edx
400029bc:	6b d2 5c             	imul   $0x5c,%edx,%edx
400029bf:	81 c2 10 10 00 00    	add    $0x1010,%edx
400029c5:	01 d0                	add    %edx,%eax
400029c7:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if(tmp_fi->dino == dir->ino){
400029ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
400029cd:	8b 10                	mov    (%eax),%edx
400029cf:	8b 45 08             	mov    0x8(%ebp),%eax
400029d2:	8b 00                	mov    (%eax),%eax
400029d4:	39 c2                	cmp    %eax,%edx
400029d6:	75 14                	jne    400029ec <readdir+0xc2>
			dir->ofs = i+1;
400029d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
400029db:	8d 50 01             	lea    0x1(%eax),%edx
400029de:	8b 45 08             	mov    0x8(%ebp),%eax
400029e1:	89 50 08             	mov    %edx,0x8(%eax)
			return &tmp_fi->de;
400029e4:	8b 45 f0             	mov    -0x10(%ebp),%eax
400029e7:	83 c0 04             	add    $0x4,%eax
400029ea:	eb 1c                	jmp    40002a08 <readdir+0xde>
	// this function shouldn't return entries from other directories!
	//warn("readdir() not implemented");
	//return NULL;
	assert(fileino_isdir(dir->ino));
	int i = dir->ofs;
	for(i; i < FILE_INODES; i++){
400029ec:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
400029f0:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
400029f7:	7e bb                	jle    400029b4 <readdir+0x8a>
		if(tmp_fi->dino == dir->ino){
			dir->ofs = i+1;
			return &tmp_fi->de;
		}
	}
	dir->ofs = 0;
400029f9:	8b 45 08             	mov    0x8(%ebp),%eax
400029fc:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
	return NULL;
40002a03:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002a08:	c9                   	leave  
40002a09:	c3                   	ret    

40002a0a <rewinddir>:

void rewinddir(DIR *dir)
{
40002a0a:	55                   	push   %ebp
40002a0b:	89 e5                	mov    %esp,%ebp
	dir->ofs = 0;
40002a0d:	8b 45 08             	mov    0x8(%ebp),%eax
40002a10:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
40002a17:	5d                   	pop    %ebp
40002a18:	c3                   	ret    

40002a19 <seekdir>:

void seekdir(DIR *dir, long ofs)
{
40002a19:	55                   	push   %ebp
40002a1a:	89 e5                	mov    %esp,%ebp
	dir->ofs = ofs;
40002a1c:	8b 45 08             	mov    0x8(%ebp),%eax
40002a1f:	8b 55 0c             	mov    0xc(%ebp),%edx
40002a22:	89 50 08             	mov    %edx,0x8(%eax)
}
40002a25:	5d                   	pop    %ebp
40002a26:	c3                   	ret    

40002a27 <telldir>:

long telldir(DIR *dir)
{
40002a27:	55                   	push   %ebp
40002a28:	89 e5                	mov    %esp,%ebp
	return dir->ofs;
40002a2a:	8b 45 08             	mov    0x8(%ebp),%eax
40002a2d:	8b 40 08             	mov    0x8(%eax),%eax
}
40002a30:	5d                   	pop    %ebp
40002a31:	c3                   	ret    
40002a32:	66 90                	xchg   %ax,%ax

40002a34 <fopen>:
FILE *const stdout = &FILES->fd[1];
FILE *const stderr = &FILES->fd[2];

FILE *
fopen(const char *path, const char *mode)
{
40002a34:	55                   	push   %ebp
40002a35:	89 e5                	mov    %esp,%ebp
40002a37:	83 ec 28             	sub    $0x28,%esp
	// Find an unused file descriptor and use it for the open
	FILE *fd = filedesc_alloc();
40002a3a:	e8 52 f1 ff ff       	call   40001b91 <filedesc_alloc>
40002a3f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (fd == NULL)
40002a42:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002a46:	75 07                	jne    40002a4f <fopen+0x1b>
		return NULL;
40002a48:	b8 00 00 00 00       	mov    $0x0,%eax
40002a4d:	eb 19                	jmp    40002a68 <fopen+0x34>

	return freopen(path, mode, fd);
40002a4f:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002a52:	89 44 24 08          	mov    %eax,0x8(%esp)
40002a56:	8b 45 0c             	mov    0xc(%ebp),%eax
40002a59:	89 44 24 04          	mov    %eax,0x4(%esp)
40002a5d:	8b 45 08             	mov    0x8(%ebp),%eax
40002a60:	89 04 24             	mov    %eax,(%esp)
40002a63:	e8 02 00 00 00       	call   40002a6a <freopen>
}
40002a68:	c9                   	leave  
40002a69:	c3                   	ret    

40002a6a <freopen>:

FILE *
freopen(const char *path, const char *mode, FILE *fd)
{
40002a6a:	55                   	push   %ebp
40002a6b:	89 e5                	mov    %esp,%ebp
40002a6d:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isvalid(fd));
40002a70:	a1 48 34 00 40       	mov    0x40003448,%eax
40002a75:	83 c0 10             	add    $0x10,%eax
40002a78:	3b 45 10             	cmp    0x10(%ebp),%eax
40002a7b:	77 0f                	ja     40002a8c <freopen+0x22>
40002a7d:	a1 48 34 00 40       	mov    0x40003448,%eax
40002a82:	05 10 10 00 00       	add    $0x1010,%eax
40002a87:	3b 45 10             	cmp    0x10(%ebp),%eax
40002a8a:	77 24                	ja     40002ab0 <freopen+0x46>
40002a8c:	c7 44 24 0c a0 37 00 	movl   $0x400037a0,0xc(%esp)
40002a93:	40 
40002a94:	c7 44 24 08 b5 37 00 	movl   $0x400037b5,0x8(%esp)
40002a9b:	40 
40002a9c:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
40002aa3:	00 
40002aa4:	c7 04 24 ca 37 00 40 	movl   $0x400037ca,(%esp)
40002aab:	e8 b0 e4 ff ff       	call   40000f60 <debug_panic>
	if (filedesc_isopen(fd))
40002ab0:	a1 48 34 00 40       	mov    0x40003448,%eax
40002ab5:	83 c0 10             	add    $0x10,%eax
40002ab8:	3b 45 10             	cmp    0x10(%ebp),%eax
40002abb:	77 23                	ja     40002ae0 <freopen+0x76>
40002abd:	a1 48 34 00 40       	mov    0x40003448,%eax
40002ac2:	05 10 10 00 00       	add    $0x1010,%eax
40002ac7:	3b 45 10             	cmp    0x10(%ebp),%eax
40002aca:	76 14                	jbe    40002ae0 <freopen+0x76>
40002acc:	8b 45 10             	mov    0x10(%ebp),%eax
40002acf:	8b 00                	mov    (%eax),%eax
40002ad1:	85 c0                	test   %eax,%eax
40002ad3:	74 0b                	je     40002ae0 <freopen+0x76>
		fclose(fd);
40002ad5:	8b 45 10             	mov    0x10(%ebp),%eax
40002ad8:	89 04 24             	mov    %eax,(%esp)
40002adb:	e8 b4 00 00 00       	call   40002b94 <fclose>

	// Parse the open mode string
	int flags;
	switch (*mode++) {
40002ae0:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ae3:	0f b6 00             	movzbl (%eax),%eax
40002ae6:	0f be c0             	movsbl %al,%eax
40002ae9:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
40002aed:	83 f8 72             	cmp    $0x72,%eax
40002af0:	74 0c                	je     40002afe <freopen+0x94>
40002af2:	83 f8 77             	cmp    $0x77,%eax
40002af5:	74 10                	je     40002b07 <freopen+0x9d>
40002af7:	83 f8 61             	cmp    $0x61,%eax
40002afa:	74 14                	je     40002b10 <freopen+0xa6>
40002afc:	eb 1b                	jmp    40002b19 <freopen+0xaf>
	case 'r':	flags = O_RDONLY; break;
40002afe:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
40002b05:	eb 3f                	jmp    40002b46 <freopen+0xdc>
	case 'w':	flags = O_WRONLY | O_CREAT | O_TRUNC; break;
40002b07:	c7 45 f4 62 00 00 00 	movl   $0x62,-0xc(%ebp)
40002b0e:	eb 36                	jmp    40002b46 <freopen+0xdc>
	case 'a':	flags = O_WRONLY | O_CREAT | O_APPEND; break;
40002b10:	c7 45 f4 32 00 00 00 	movl   $0x32,-0xc(%ebp)
40002b17:	eb 2d                	jmp    40002b46 <freopen+0xdc>
	default:	panic("freopen: unknown file mode '%c'\n", *--mode);
40002b19:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
40002b1d:	8b 45 0c             	mov    0xc(%ebp),%eax
40002b20:	0f b6 00             	movzbl (%eax),%eax
40002b23:	0f be c0             	movsbl %al,%eax
40002b26:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002b2a:	c7 44 24 08 d8 37 00 	movl   $0x400037d8,0x8(%esp)
40002b31:	40 
40002b32:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
40002b39:	00 
40002b3a:	c7 04 24 ca 37 00 40 	movl   $0x400037ca,(%esp)
40002b41:	e8 1a e4 ff ff       	call   40000f60 <debug_panic>
	}
	if (*mode == 'b')	// binary flag - compatibility only
40002b46:	8b 45 0c             	mov    0xc(%ebp),%eax
40002b49:	0f b6 00             	movzbl (%eax),%eax
40002b4c:	3c 62                	cmp    $0x62,%al
40002b4e:	75 04                	jne    40002b54 <freopen+0xea>
		mode++;
40002b50:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	if (*mode == '+')
40002b54:	8b 45 0c             	mov    0xc(%ebp),%eax
40002b57:	0f b6 00             	movzbl (%eax),%eax
40002b5a:	3c 2b                	cmp    $0x2b,%al
40002b5c:	75 04                	jne    40002b62 <freopen+0xf8>
		flags |= O_RDWR;
40002b5e:	83 4d f4 03          	orl    $0x3,-0xc(%ebp)

	if (filedesc_open(fd, path, flags, 0666) != fd)
40002b62:	c7 44 24 0c b6 01 00 	movl   $0x1b6,0xc(%esp)
40002b69:	00 
40002b6a:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002b6d:	89 44 24 08          	mov    %eax,0x8(%esp)
40002b71:	8b 45 08             	mov    0x8(%ebp),%eax
40002b74:	89 44 24 04          	mov    %eax,0x4(%esp)
40002b78:	8b 45 10             	mov    0x10(%ebp),%eax
40002b7b:	89 04 24             	mov    %eax,(%esp)
40002b7e:	e8 64 f0 ff ff       	call   40001be7 <filedesc_open>
40002b83:	3b 45 10             	cmp    0x10(%ebp),%eax
40002b86:	74 07                	je     40002b8f <freopen+0x125>
		return NULL;
40002b88:	b8 00 00 00 00       	mov    $0x0,%eax
40002b8d:	eb 03                	jmp    40002b92 <freopen+0x128>
	return fd;
40002b8f:	8b 45 10             	mov    0x10(%ebp),%eax
}
40002b92:	c9                   	leave  
40002b93:	c3                   	ret    

40002b94 <fclose>:

int
fclose(FILE *fd)
{
40002b94:	55                   	push   %ebp
40002b95:	89 e5                	mov    %esp,%ebp
40002b97:	83 ec 18             	sub    $0x18,%esp
	filedesc_close(fd);
40002b9a:	8b 45 08             	mov    0x8(%ebp),%eax
40002b9d:	89 04 24             	mov    %eax,(%esp)
40002ba0:	e8 07 f6 ff ff       	call   400021ac <filedesc_close>
	return 0;
40002ba5:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002baa:	c9                   	leave  
40002bab:	c3                   	ret    

40002bac <fgetc>:

int
fgetc(FILE *fd)
{
40002bac:	55                   	push   %ebp
40002bad:	89 e5                	mov    %esp,%ebp
40002baf:	83 ec 28             	sub    $0x28,%esp
	unsigned char ch;
	if (filedesc_read(fd, &ch, 1, 1) < 1)
40002bb2:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
40002bb9:	00 
40002bba:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40002bc1:	00 
40002bc2:	8d 45 f7             	lea    -0x9(%ebp),%eax
40002bc5:	89 44 24 04          	mov    %eax,0x4(%esp)
40002bc9:	8b 45 08             	mov    0x8(%ebp),%eax
40002bcc:	89 04 24             	mov    %eax,(%esp)
40002bcf:	e8 3d f2 ff ff       	call   40001e11 <filedesc_read>
40002bd4:	85 c0                	test   %eax,%eax
40002bd6:	7f 07                	jg     40002bdf <fgetc+0x33>
		return EOF;
40002bd8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002bdd:	eb 07                	jmp    40002be6 <fgetc+0x3a>
	return ch;
40002bdf:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
40002be3:	0f b6 c0             	movzbl %al,%eax
}
40002be6:	c9                   	leave  
40002be7:	c3                   	ret    

40002be8 <fputc>:

int
fputc(int c, FILE *fd)
{
40002be8:	55                   	push   %ebp
40002be9:	89 e5                	mov    %esp,%ebp
40002beb:	83 ec 28             	sub    $0x28,%esp
	unsigned char ch = c;
40002bee:	8b 45 08             	mov    0x8(%ebp),%eax
40002bf1:	88 45 f7             	mov    %al,-0x9(%ebp)
	if (filedesc_write(fd, &ch, 1, 1) < 1)
40002bf4:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
40002bfb:	00 
40002bfc:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40002c03:	00 
40002c04:	8d 45 f7             	lea    -0x9(%ebp),%eax
40002c07:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c0b:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c0e:	89 04 24             	mov    %eax,(%esp)
40002c11:	e8 10 f3 ff ff       	call   40001f26 <filedesc_write>
40002c16:	85 c0                	test   %eax,%eax
40002c18:	7f 07                	jg     40002c21 <fputc+0x39>
		return EOF;
40002c1a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002c1f:	eb 07                	jmp    40002c28 <fputc+0x40>
	return ch;
40002c21:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
40002c25:	0f b6 c0             	movzbl %al,%eax
}
40002c28:	c9                   	leave  
40002c29:	c3                   	ret    

40002c2a <fread>:

size_t
fread(void *buf, size_t eltsize, size_t count, FILE *fd)
{
40002c2a:	55                   	push   %ebp
40002c2b:	89 e5                	mov    %esp,%ebp
40002c2d:	83 ec 28             	sub    $0x28,%esp
	ssize_t actual = filedesc_read(fd, buf, eltsize, count);
40002c30:	8b 45 10             	mov    0x10(%ebp),%eax
40002c33:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002c37:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c3a:	89 44 24 08          	mov    %eax,0x8(%esp)
40002c3e:	8b 45 08             	mov    0x8(%ebp),%eax
40002c41:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c45:	8b 45 14             	mov    0x14(%ebp),%eax
40002c48:	89 04 24             	mov    %eax,(%esp)
40002c4b:	e8 c1 f1 ff ff       	call   40001e11 <filedesc_read>
40002c50:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return actual >= 0 ? actual : 0;	// no error indication
40002c53:	b8 00 00 00 00       	mov    $0x0,%eax
40002c58:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002c5c:	0f 49 45 f4          	cmovns -0xc(%ebp),%eax
}
40002c60:	c9                   	leave  
40002c61:	c3                   	ret    

40002c62 <fwrite>:

size_t
fwrite(const void *buf, size_t eltsize, size_t count, FILE *fd)
{
40002c62:	55                   	push   %ebp
40002c63:	89 e5                	mov    %esp,%ebp
40002c65:	83 ec 28             	sub    $0x28,%esp
	ssize_t actual = filedesc_write(fd, buf, eltsize, count);
40002c68:	8b 45 10             	mov    0x10(%ebp),%eax
40002c6b:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002c6f:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c72:	89 44 24 08          	mov    %eax,0x8(%esp)
40002c76:	8b 45 08             	mov    0x8(%ebp),%eax
40002c79:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c7d:	8b 45 14             	mov    0x14(%ebp),%eax
40002c80:	89 04 24             	mov    %eax,(%esp)
40002c83:	e8 9e f2 ff ff       	call   40001f26 <filedesc_write>
40002c88:	89 45 f4             	mov    %eax,-0xc(%ebp)

		
	return actual >= 0 ? actual : 0;	// no error indication
40002c8b:	b8 00 00 00 00       	mov    $0x0,%eax
40002c90:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002c94:	0f 49 45 f4          	cmovns -0xc(%ebp),%eax
}
40002c98:	c9                   	leave  
40002c99:	c3                   	ret    

40002c9a <fseek>:

int
fseek(FILE *fd, off_t offset, int whence)
{
40002c9a:	55                   	push   %ebp
40002c9b:	89 e5                	mov    %esp,%ebp
40002c9d:	83 ec 18             	sub    $0x18,%esp
	if (filedesc_seek(fd, offset, whence) < 0)
40002ca0:	8b 45 10             	mov    0x10(%ebp),%eax
40002ca3:	89 44 24 08          	mov    %eax,0x8(%esp)
40002ca7:	8b 45 0c             	mov    0xc(%ebp),%eax
40002caa:	89 44 24 04          	mov    %eax,0x4(%esp)
40002cae:	8b 45 08             	mov    0x8(%ebp),%eax
40002cb1:	89 04 24             	mov    %eax,(%esp)
40002cb4:	e8 e2 f3 ff ff       	call   4000209b <filedesc_seek>
40002cb9:	85 c0                	test   %eax,%eax
40002cbb:	79 07                	jns    40002cc4 <fseek+0x2a>
		return -1;
40002cbd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002cc2:	eb 05                	jmp    40002cc9 <fseek+0x2f>
	return 0;	// fseek() returns 0 on success, not the new position
40002cc4:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002cc9:	c9                   	leave  
40002cca:	c3                   	ret    

40002ccb <ftell>:

long
ftell(FILE *fd)
{
40002ccb:	55                   	push   %ebp
40002ccc:	89 e5                	mov    %esp,%ebp
40002cce:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
40002cd1:	a1 48 34 00 40       	mov    0x40003448,%eax
40002cd6:	83 c0 10             	add    $0x10,%eax
40002cd9:	3b 45 08             	cmp    0x8(%ebp),%eax
40002cdc:	77 18                	ja     40002cf6 <ftell+0x2b>
40002cde:	a1 48 34 00 40       	mov    0x40003448,%eax
40002ce3:	05 10 10 00 00       	add    $0x1010,%eax
40002ce8:	3b 45 08             	cmp    0x8(%ebp),%eax
40002ceb:	76 09                	jbe    40002cf6 <ftell+0x2b>
40002ced:	8b 45 08             	mov    0x8(%ebp),%eax
40002cf0:	8b 00                	mov    (%eax),%eax
40002cf2:	85 c0                	test   %eax,%eax
40002cf4:	75 24                	jne    40002d1a <ftell+0x4f>
40002cf6:	c7 44 24 0c f9 37 00 	movl   $0x400037f9,0xc(%esp)
40002cfd:	40 
40002cfe:	c7 44 24 08 b5 37 00 	movl   $0x400037b5,0x8(%esp)
40002d05:	40 
40002d06:	c7 44 24 04 7a 00 00 	movl   $0x7a,0x4(%esp)
40002d0d:	00 
40002d0e:	c7 04 24 ca 37 00 40 	movl   $0x400037ca,(%esp)
40002d15:	e8 46 e2 ff ff       	call   40000f60 <debug_panic>
	return fd->ofs;
40002d1a:	8b 45 08             	mov    0x8(%ebp),%eax
40002d1d:	8b 40 08             	mov    0x8(%eax),%eax
}
40002d20:	c9                   	leave  
40002d21:	c3                   	ret    

40002d22 <feof>:

int
feof(FILE *fd)
{
40002d22:	55                   	push   %ebp
40002d23:	89 e5                	mov    %esp,%ebp
40002d25:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isopen(fd));
40002d28:	a1 48 34 00 40       	mov    0x40003448,%eax
40002d2d:	83 c0 10             	add    $0x10,%eax
40002d30:	3b 45 08             	cmp    0x8(%ebp),%eax
40002d33:	77 18                	ja     40002d4d <feof+0x2b>
40002d35:	a1 48 34 00 40       	mov    0x40003448,%eax
40002d3a:	05 10 10 00 00       	add    $0x1010,%eax
40002d3f:	3b 45 08             	cmp    0x8(%ebp),%eax
40002d42:	76 09                	jbe    40002d4d <feof+0x2b>
40002d44:	8b 45 08             	mov    0x8(%ebp),%eax
40002d47:	8b 00                	mov    (%eax),%eax
40002d49:	85 c0                	test   %eax,%eax
40002d4b:	75 24                	jne    40002d71 <feof+0x4f>
40002d4d:	c7 44 24 0c f9 37 00 	movl   $0x400037f9,0xc(%esp)
40002d54:	40 
40002d55:	c7 44 24 08 b5 37 00 	movl   $0x400037b5,0x8(%esp)
40002d5c:	40 
40002d5d:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
40002d64:	00 
40002d65:	c7 04 24 ca 37 00 40 	movl   $0x400037ca,(%esp)
40002d6c:	e8 ef e1 ff ff       	call   40000f60 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40002d71:	8b 15 48 34 00 40    	mov    0x40003448,%edx
40002d77:	8b 45 08             	mov    0x8(%ebp),%eax
40002d7a:	8b 00                	mov    (%eax),%eax
40002d7c:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002d7f:	05 10 10 00 00       	add    $0x1010,%eax
40002d84:	01 d0                	add    %edx,%eax
40002d86:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return fd->ofs >= fi->size && !(fi->mode & S_IFPART);
40002d89:	8b 45 08             	mov    0x8(%ebp),%eax
40002d8c:	8b 40 08             	mov    0x8(%eax),%eax
40002d8f:	89 c2                	mov    %eax,%edx
40002d91:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002d94:	8b 40 4c             	mov    0x4c(%eax),%eax
40002d97:	39 c2                	cmp    %eax,%edx
40002d99:	72 16                	jb     40002db1 <feof+0x8f>
40002d9b:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002d9e:	8b 40 48             	mov    0x48(%eax),%eax
40002da1:	25 00 80 00 00       	and    $0x8000,%eax
40002da6:	85 c0                	test   %eax,%eax
40002da8:	75 07                	jne    40002db1 <feof+0x8f>
40002daa:	b8 01 00 00 00       	mov    $0x1,%eax
40002daf:	eb 05                	jmp    40002db6 <feof+0x94>
40002db1:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002db6:	c9                   	leave  
40002db7:	c3                   	ret    

40002db8 <ferror>:

int
ferror(FILE *fd)
{
40002db8:	55                   	push   %ebp
40002db9:	89 e5                	mov    %esp,%ebp
40002dbb:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
40002dbe:	a1 48 34 00 40       	mov    0x40003448,%eax
40002dc3:	83 c0 10             	add    $0x10,%eax
40002dc6:	3b 45 08             	cmp    0x8(%ebp),%eax
40002dc9:	77 18                	ja     40002de3 <ferror+0x2b>
40002dcb:	a1 48 34 00 40       	mov    0x40003448,%eax
40002dd0:	05 10 10 00 00       	add    $0x1010,%eax
40002dd5:	3b 45 08             	cmp    0x8(%ebp),%eax
40002dd8:	76 09                	jbe    40002de3 <ferror+0x2b>
40002dda:	8b 45 08             	mov    0x8(%ebp),%eax
40002ddd:	8b 00                	mov    (%eax),%eax
40002ddf:	85 c0                	test   %eax,%eax
40002de1:	75 24                	jne    40002e07 <ferror+0x4f>
40002de3:	c7 44 24 0c f9 37 00 	movl   $0x400037f9,0xc(%esp)
40002dea:	40 
40002deb:	c7 44 24 08 b5 37 00 	movl   $0x400037b5,0x8(%esp)
40002df2:	40 
40002df3:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
40002dfa:	00 
40002dfb:	c7 04 24 ca 37 00 40 	movl   $0x400037ca,(%esp)
40002e02:	e8 59 e1 ff ff       	call   40000f60 <debug_panic>
	return fd->err;
40002e07:	8b 45 08             	mov    0x8(%ebp),%eax
40002e0a:	8b 40 0c             	mov    0xc(%eax),%eax
}
40002e0d:	c9                   	leave  
40002e0e:	c3                   	ret    

40002e0f <clearerr>:

void
clearerr(FILE *fd)
{
40002e0f:	55                   	push   %ebp
40002e10:	89 e5                	mov    %esp,%ebp
40002e12:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
40002e15:	a1 48 34 00 40       	mov    0x40003448,%eax
40002e1a:	83 c0 10             	add    $0x10,%eax
40002e1d:	3b 45 08             	cmp    0x8(%ebp),%eax
40002e20:	77 18                	ja     40002e3a <clearerr+0x2b>
40002e22:	a1 48 34 00 40       	mov    0x40003448,%eax
40002e27:	05 10 10 00 00       	add    $0x1010,%eax
40002e2c:	3b 45 08             	cmp    0x8(%ebp),%eax
40002e2f:	76 09                	jbe    40002e3a <clearerr+0x2b>
40002e31:	8b 45 08             	mov    0x8(%ebp),%eax
40002e34:	8b 00                	mov    (%eax),%eax
40002e36:	85 c0                	test   %eax,%eax
40002e38:	75 24                	jne    40002e5e <clearerr+0x4f>
40002e3a:	c7 44 24 0c f9 37 00 	movl   $0x400037f9,0xc(%esp)
40002e41:	40 
40002e42:	c7 44 24 08 b5 37 00 	movl   $0x400037b5,0x8(%esp)
40002e49:	40 
40002e4a:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
40002e51:	00 
40002e52:	c7 04 24 ca 37 00 40 	movl   $0x400037ca,(%esp)
40002e59:	e8 02 e1 ff ff       	call   40000f60 <debug_panic>
	fd->err = 0;
40002e5e:	8b 45 08             	mov    0x8(%ebp),%eax
40002e61:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
}
40002e68:	c9                   	leave  
40002e69:	c3                   	ret    

40002e6a <fflush>:


int
fflush(FILE *f)
{
40002e6a:	55                   	push   %ebp
40002e6b:	89 e5                	mov    %esp,%ebp
40002e6d:	83 ec 18             	sub    $0x18,%esp
	if (f == NULL) {	// flush all open streams
40002e70:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40002e74:	75 57                	jne    40002ecd <fflush+0x63>
		for (f = &files->fd[0]; f < &files->fd[OPEN_MAX]; f++)
40002e76:	a1 48 34 00 40       	mov    0x40003448,%eax
40002e7b:	83 c0 10             	add    $0x10,%eax
40002e7e:	89 45 08             	mov    %eax,0x8(%ebp)
40002e81:	eb 34                	jmp    40002eb7 <fflush+0x4d>
			if (filedesc_isopen(f))
40002e83:	a1 48 34 00 40       	mov    0x40003448,%eax
40002e88:	83 c0 10             	add    $0x10,%eax
40002e8b:	3b 45 08             	cmp    0x8(%ebp),%eax
40002e8e:	77 23                	ja     40002eb3 <fflush+0x49>
40002e90:	a1 48 34 00 40       	mov    0x40003448,%eax
40002e95:	05 10 10 00 00       	add    $0x1010,%eax
40002e9a:	3b 45 08             	cmp    0x8(%ebp),%eax
40002e9d:	76 14                	jbe    40002eb3 <fflush+0x49>
40002e9f:	8b 45 08             	mov    0x8(%ebp),%eax
40002ea2:	8b 00                	mov    (%eax),%eax
40002ea4:	85 c0                	test   %eax,%eax
40002ea6:	74 0b                	je     40002eb3 <fflush+0x49>
				fflush(f);
40002ea8:	8b 45 08             	mov    0x8(%ebp),%eax
40002eab:	89 04 24             	mov    %eax,(%esp)
40002eae:	e8 b7 ff ff ff       	call   40002e6a <fflush>

int
fflush(FILE *f)
{
	if (f == NULL) {	// flush all open streams
		for (f = &files->fd[0]; f < &files->fd[OPEN_MAX]; f++)
40002eb3:	83 45 08 10          	addl   $0x10,0x8(%ebp)
40002eb7:	a1 48 34 00 40       	mov    0x40003448,%eax
40002ebc:	05 10 10 00 00       	add    $0x1010,%eax
40002ec1:	3b 45 08             	cmp    0x8(%ebp),%eax
40002ec4:	77 bd                	ja     40002e83 <fflush+0x19>
			if (filedesc_isopen(f))
				fflush(f);
		return 0;
40002ec6:	b8 00 00 00 00       	mov    $0x0,%eax
40002ecb:	eb 56                	jmp    40002f23 <fflush+0xb9>
	}

	assert(filedesc_isopen(f));
40002ecd:	a1 48 34 00 40       	mov    0x40003448,%eax
40002ed2:	83 c0 10             	add    $0x10,%eax
40002ed5:	3b 45 08             	cmp    0x8(%ebp),%eax
40002ed8:	77 18                	ja     40002ef2 <fflush+0x88>
40002eda:	a1 48 34 00 40       	mov    0x40003448,%eax
40002edf:	05 10 10 00 00       	add    $0x1010,%eax
40002ee4:	3b 45 08             	cmp    0x8(%ebp),%eax
40002ee7:	76 09                	jbe    40002ef2 <fflush+0x88>
40002ee9:	8b 45 08             	mov    0x8(%ebp),%eax
40002eec:	8b 00                	mov    (%eax),%eax
40002eee:	85 c0                	test   %eax,%eax
40002ef0:	75 24                	jne    40002f16 <fflush+0xac>
40002ef2:	c7 44 24 0c 0d 38 00 	movl   $0x4000380d,0xc(%esp)
40002ef9:	40 
40002efa:	c7 44 24 08 b5 37 00 	movl   $0x400037b5,0x8(%esp)
40002f01:	40 
40002f02:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
40002f09:	00 
40002f0a:	c7 04 24 ca 37 00 40 	movl   $0x400037ca,(%esp)
40002f11:	e8 4a e0 ff ff       	call   40000f60 <debug_panic>
	return fileino_flush(f->ino);
40002f16:	8b 45 08             	mov    0x8(%ebp),%eax
40002f19:	8b 00                	mov    (%eax),%eax
40002f1b:	89 04 24             	mov    %eax,(%esp)
40002f1e:	e8 f9 eb ff ff       	call   40001b1c <fileino_flush>
}
40002f23:	c9                   	leave  
40002f24:	c3                   	ret    
40002f25:	66 90                	xchg   %ax,%ax
40002f27:	66 90                	xchg   %ax,%ax
40002f29:	66 90                	xchg   %ax,%ax
40002f2b:	66 90                	xchg   %ax,%ax
40002f2d:	66 90                	xchg   %ax,%ax
40002f2f:	90                   	nop

40002f30 <__udivdi3>:
40002f30:	83 ec 1c             	sub    $0x1c,%esp
40002f33:	8b 44 24 2c          	mov    0x2c(%esp),%eax
40002f37:	89 7c 24 14          	mov    %edi,0x14(%esp)
40002f3b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
40002f3f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
40002f43:	8b 7c 24 20          	mov    0x20(%esp),%edi
40002f47:	8b 6c 24 24          	mov    0x24(%esp),%ebp
40002f4b:	85 c0                	test   %eax,%eax
40002f4d:	89 74 24 10          	mov    %esi,0x10(%esp)
40002f51:	89 7c 24 08          	mov    %edi,0x8(%esp)
40002f55:	89 ea                	mov    %ebp,%edx
40002f57:	89 4c 24 04          	mov    %ecx,0x4(%esp)
40002f5b:	75 33                	jne    40002f90 <__udivdi3+0x60>
40002f5d:	39 e9                	cmp    %ebp,%ecx
40002f5f:	77 6f                	ja     40002fd0 <__udivdi3+0xa0>
40002f61:	85 c9                	test   %ecx,%ecx
40002f63:	89 ce                	mov    %ecx,%esi
40002f65:	75 0b                	jne    40002f72 <__udivdi3+0x42>
40002f67:	b8 01 00 00 00       	mov    $0x1,%eax
40002f6c:	31 d2                	xor    %edx,%edx
40002f6e:	f7 f1                	div    %ecx
40002f70:	89 c6                	mov    %eax,%esi
40002f72:	31 d2                	xor    %edx,%edx
40002f74:	89 e8                	mov    %ebp,%eax
40002f76:	f7 f6                	div    %esi
40002f78:	89 c5                	mov    %eax,%ebp
40002f7a:	89 f8                	mov    %edi,%eax
40002f7c:	f7 f6                	div    %esi
40002f7e:	89 ea                	mov    %ebp,%edx
40002f80:	8b 74 24 10          	mov    0x10(%esp),%esi
40002f84:	8b 7c 24 14          	mov    0x14(%esp),%edi
40002f88:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40002f8c:	83 c4 1c             	add    $0x1c,%esp
40002f8f:	c3                   	ret    
40002f90:	39 e8                	cmp    %ebp,%eax
40002f92:	77 24                	ja     40002fb8 <__udivdi3+0x88>
40002f94:	0f bd c8             	bsr    %eax,%ecx
40002f97:	83 f1 1f             	xor    $0x1f,%ecx
40002f9a:	89 0c 24             	mov    %ecx,(%esp)
40002f9d:	75 49                	jne    40002fe8 <__udivdi3+0xb8>
40002f9f:	8b 74 24 08          	mov    0x8(%esp),%esi
40002fa3:	39 74 24 04          	cmp    %esi,0x4(%esp)
40002fa7:	0f 86 ab 00 00 00    	jbe    40003058 <__udivdi3+0x128>
40002fad:	39 e8                	cmp    %ebp,%eax
40002faf:	0f 82 a3 00 00 00    	jb     40003058 <__udivdi3+0x128>
40002fb5:	8d 76 00             	lea    0x0(%esi),%esi
40002fb8:	31 d2                	xor    %edx,%edx
40002fba:	31 c0                	xor    %eax,%eax
40002fbc:	8b 74 24 10          	mov    0x10(%esp),%esi
40002fc0:	8b 7c 24 14          	mov    0x14(%esp),%edi
40002fc4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40002fc8:	83 c4 1c             	add    $0x1c,%esp
40002fcb:	c3                   	ret    
40002fcc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40002fd0:	89 f8                	mov    %edi,%eax
40002fd2:	f7 f1                	div    %ecx
40002fd4:	31 d2                	xor    %edx,%edx
40002fd6:	8b 74 24 10          	mov    0x10(%esp),%esi
40002fda:	8b 7c 24 14          	mov    0x14(%esp),%edi
40002fde:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40002fe2:	83 c4 1c             	add    $0x1c,%esp
40002fe5:	c3                   	ret    
40002fe6:	66 90                	xchg   %ax,%ax
40002fe8:	0f b6 0c 24          	movzbl (%esp),%ecx
40002fec:	89 c6                	mov    %eax,%esi
40002fee:	b8 20 00 00 00       	mov    $0x20,%eax
40002ff3:	8b 6c 24 04          	mov    0x4(%esp),%ebp
40002ff7:	2b 04 24             	sub    (%esp),%eax
40002ffa:	8b 7c 24 08          	mov    0x8(%esp),%edi
40002ffe:	d3 e6                	shl    %cl,%esi
40003000:	89 c1                	mov    %eax,%ecx
40003002:	d3 ed                	shr    %cl,%ebp
40003004:	0f b6 0c 24          	movzbl (%esp),%ecx
40003008:	09 f5                	or     %esi,%ebp
4000300a:	8b 74 24 04          	mov    0x4(%esp),%esi
4000300e:	d3 e6                	shl    %cl,%esi
40003010:	89 c1                	mov    %eax,%ecx
40003012:	89 74 24 04          	mov    %esi,0x4(%esp)
40003016:	89 d6                	mov    %edx,%esi
40003018:	d3 ee                	shr    %cl,%esi
4000301a:	0f b6 0c 24          	movzbl (%esp),%ecx
4000301e:	d3 e2                	shl    %cl,%edx
40003020:	89 c1                	mov    %eax,%ecx
40003022:	d3 ef                	shr    %cl,%edi
40003024:	09 d7                	or     %edx,%edi
40003026:	89 f2                	mov    %esi,%edx
40003028:	89 f8                	mov    %edi,%eax
4000302a:	f7 f5                	div    %ebp
4000302c:	89 d6                	mov    %edx,%esi
4000302e:	89 c7                	mov    %eax,%edi
40003030:	f7 64 24 04          	mull   0x4(%esp)
40003034:	39 d6                	cmp    %edx,%esi
40003036:	72 30                	jb     40003068 <__udivdi3+0x138>
40003038:	8b 6c 24 08          	mov    0x8(%esp),%ebp
4000303c:	0f b6 0c 24          	movzbl (%esp),%ecx
40003040:	d3 e5                	shl    %cl,%ebp
40003042:	39 c5                	cmp    %eax,%ebp
40003044:	73 04                	jae    4000304a <__udivdi3+0x11a>
40003046:	39 d6                	cmp    %edx,%esi
40003048:	74 1e                	je     40003068 <__udivdi3+0x138>
4000304a:	89 f8                	mov    %edi,%eax
4000304c:	31 d2                	xor    %edx,%edx
4000304e:	e9 69 ff ff ff       	jmp    40002fbc <__udivdi3+0x8c>
40003053:	90                   	nop
40003054:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003058:	31 d2                	xor    %edx,%edx
4000305a:	b8 01 00 00 00       	mov    $0x1,%eax
4000305f:	e9 58 ff ff ff       	jmp    40002fbc <__udivdi3+0x8c>
40003064:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003068:	8d 47 ff             	lea    -0x1(%edi),%eax
4000306b:	31 d2                	xor    %edx,%edx
4000306d:	8b 74 24 10          	mov    0x10(%esp),%esi
40003071:	8b 7c 24 14          	mov    0x14(%esp),%edi
40003075:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40003079:	83 c4 1c             	add    $0x1c,%esp
4000307c:	c3                   	ret    
4000307d:	66 90                	xchg   %ax,%ax
4000307f:	90                   	nop

40003080 <__umoddi3>:
40003080:	83 ec 2c             	sub    $0x2c,%esp
40003083:	8b 44 24 3c          	mov    0x3c(%esp),%eax
40003087:	8b 4c 24 30          	mov    0x30(%esp),%ecx
4000308b:	89 74 24 20          	mov    %esi,0x20(%esp)
4000308f:	8b 74 24 38          	mov    0x38(%esp),%esi
40003093:	89 7c 24 24          	mov    %edi,0x24(%esp)
40003097:	8b 7c 24 34          	mov    0x34(%esp),%edi
4000309b:	85 c0                	test   %eax,%eax
4000309d:	89 c2                	mov    %eax,%edx
4000309f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
400030a3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
400030a7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
400030ab:	89 74 24 10          	mov    %esi,0x10(%esp)
400030af:	89 4c 24 14          	mov    %ecx,0x14(%esp)
400030b3:	89 7c 24 18          	mov    %edi,0x18(%esp)
400030b7:	75 1f                	jne    400030d8 <__umoddi3+0x58>
400030b9:	39 fe                	cmp    %edi,%esi
400030bb:	76 63                	jbe    40003120 <__umoddi3+0xa0>
400030bd:	89 c8                	mov    %ecx,%eax
400030bf:	89 fa                	mov    %edi,%edx
400030c1:	f7 f6                	div    %esi
400030c3:	89 d0                	mov    %edx,%eax
400030c5:	31 d2                	xor    %edx,%edx
400030c7:	8b 74 24 20          	mov    0x20(%esp),%esi
400030cb:	8b 7c 24 24          	mov    0x24(%esp),%edi
400030cf:	8b 6c 24 28          	mov    0x28(%esp),%ebp
400030d3:	83 c4 2c             	add    $0x2c,%esp
400030d6:	c3                   	ret    
400030d7:	90                   	nop
400030d8:	39 f8                	cmp    %edi,%eax
400030da:	77 64                	ja     40003140 <__umoddi3+0xc0>
400030dc:	0f bd e8             	bsr    %eax,%ebp
400030df:	83 f5 1f             	xor    $0x1f,%ebp
400030e2:	75 74                	jne    40003158 <__umoddi3+0xd8>
400030e4:	8b 7c 24 14          	mov    0x14(%esp),%edi
400030e8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
400030ec:	0f 87 0e 01 00 00    	ja     40003200 <__umoddi3+0x180>
400030f2:	8b 7c 24 0c          	mov    0xc(%esp),%edi
400030f6:	29 f1                	sub    %esi,%ecx
400030f8:	19 c7                	sbb    %eax,%edi
400030fa:	89 4c 24 14          	mov    %ecx,0x14(%esp)
400030fe:	89 7c 24 18          	mov    %edi,0x18(%esp)
40003102:	8b 44 24 14          	mov    0x14(%esp),%eax
40003106:	8b 54 24 18          	mov    0x18(%esp),%edx
4000310a:	8b 74 24 20          	mov    0x20(%esp),%esi
4000310e:	8b 7c 24 24          	mov    0x24(%esp),%edi
40003112:	8b 6c 24 28          	mov    0x28(%esp),%ebp
40003116:	83 c4 2c             	add    $0x2c,%esp
40003119:	c3                   	ret    
4000311a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
40003120:	85 f6                	test   %esi,%esi
40003122:	89 f5                	mov    %esi,%ebp
40003124:	75 0b                	jne    40003131 <__umoddi3+0xb1>
40003126:	b8 01 00 00 00       	mov    $0x1,%eax
4000312b:	31 d2                	xor    %edx,%edx
4000312d:	f7 f6                	div    %esi
4000312f:	89 c5                	mov    %eax,%ebp
40003131:	8b 44 24 0c          	mov    0xc(%esp),%eax
40003135:	31 d2                	xor    %edx,%edx
40003137:	f7 f5                	div    %ebp
40003139:	89 c8                	mov    %ecx,%eax
4000313b:	f7 f5                	div    %ebp
4000313d:	eb 84                	jmp    400030c3 <__umoddi3+0x43>
4000313f:	90                   	nop
40003140:	89 c8                	mov    %ecx,%eax
40003142:	89 fa                	mov    %edi,%edx
40003144:	8b 74 24 20          	mov    0x20(%esp),%esi
40003148:	8b 7c 24 24          	mov    0x24(%esp),%edi
4000314c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
40003150:	83 c4 2c             	add    $0x2c,%esp
40003153:	c3                   	ret    
40003154:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003158:	8b 44 24 10          	mov    0x10(%esp),%eax
4000315c:	be 20 00 00 00       	mov    $0x20,%esi
40003161:	89 e9                	mov    %ebp,%ecx
40003163:	29 ee                	sub    %ebp,%esi
40003165:	d3 e2                	shl    %cl,%edx
40003167:	89 f1                	mov    %esi,%ecx
40003169:	d3 e8                	shr    %cl,%eax
4000316b:	89 e9                	mov    %ebp,%ecx
4000316d:	09 d0                	or     %edx,%eax
4000316f:	89 fa                	mov    %edi,%edx
40003171:	89 44 24 0c          	mov    %eax,0xc(%esp)
40003175:	8b 44 24 10          	mov    0x10(%esp),%eax
40003179:	d3 e0                	shl    %cl,%eax
4000317b:	89 f1                	mov    %esi,%ecx
4000317d:	89 44 24 10          	mov    %eax,0x10(%esp)
40003181:	8b 44 24 1c          	mov    0x1c(%esp),%eax
40003185:	d3 ea                	shr    %cl,%edx
40003187:	89 e9                	mov    %ebp,%ecx
40003189:	d3 e7                	shl    %cl,%edi
4000318b:	89 f1                	mov    %esi,%ecx
4000318d:	d3 e8                	shr    %cl,%eax
4000318f:	89 e9                	mov    %ebp,%ecx
40003191:	09 f8                	or     %edi,%eax
40003193:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
40003197:	f7 74 24 0c          	divl   0xc(%esp)
4000319b:	d3 e7                	shl    %cl,%edi
4000319d:	89 7c 24 18          	mov    %edi,0x18(%esp)
400031a1:	89 d7                	mov    %edx,%edi
400031a3:	f7 64 24 10          	mull   0x10(%esp)
400031a7:	39 d7                	cmp    %edx,%edi
400031a9:	89 c1                	mov    %eax,%ecx
400031ab:	89 54 24 14          	mov    %edx,0x14(%esp)
400031af:	72 3b                	jb     400031ec <__umoddi3+0x16c>
400031b1:	39 44 24 18          	cmp    %eax,0x18(%esp)
400031b5:	72 31                	jb     400031e8 <__umoddi3+0x168>
400031b7:	8b 44 24 18          	mov    0x18(%esp),%eax
400031bb:	29 c8                	sub    %ecx,%eax
400031bd:	19 d7                	sbb    %edx,%edi
400031bf:	89 e9                	mov    %ebp,%ecx
400031c1:	89 fa                	mov    %edi,%edx
400031c3:	d3 e8                	shr    %cl,%eax
400031c5:	89 f1                	mov    %esi,%ecx
400031c7:	d3 e2                	shl    %cl,%edx
400031c9:	89 e9                	mov    %ebp,%ecx
400031cb:	09 d0                	or     %edx,%eax
400031cd:	89 fa                	mov    %edi,%edx
400031cf:	d3 ea                	shr    %cl,%edx
400031d1:	8b 74 24 20          	mov    0x20(%esp),%esi
400031d5:	8b 7c 24 24          	mov    0x24(%esp),%edi
400031d9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
400031dd:	83 c4 2c             	add    $0x2c,%esp
400031e0:	c3                   	ret    
400031e1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
400031e8:	39 d7                	cmp    %edx,%edi
400031ea:	75 cb                	jne    400031b7 <__umoddi3+0x137>
400031ec:	8b 54 24 14          	mov    0x14(%esp),%edx
400031f0:	89 c1                	mov    %eax,%ecx
400031f2:	2b 4c 24 10          	sub    0x10(%esp),%ecx
400031f6:	1b 54 24 0c          	sbb    0xc(%esp),%edx
400031fa:	eb bb                	jmp    400031b7 <__umoddi3+0x137>
400031fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003200:	3b 44 24 18          	cmp    0x18(%esp),%eax
40003204:	0f 82 e8 fe ff ff    	jb     400030f2 <__umoddi3+0x72>
4000320a:	e9 f3 fe ff ff       	jmp    40003102 <__umoddi3+0x82>
