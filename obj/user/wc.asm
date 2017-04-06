
obj/user/wc:     file format elf32-i386


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
4000010c:	e8 2d 01 00 00       	call   4000023e <main>
	pushl	%eax	// use with main's return value as exit status
40000111:	50                   	push   %eax
	call	exit
40000112:	e8 65 26 00 00       	call   4000277c <exit>
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

40000144 <wc>:

char buf[512];

void
wc(int fd, char *name)
{
40000144:	55                   	push   %ebp
40000145:	89 e5                	mov    %esp,%ebp
40000147:	83 ec 48             	sub    $0x48,%esp
	int i, n;
	int l, w, c, inword;

	l = w = c = 0;
4000014a:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
40000151:	8b 45 e8             	mov    -0x18(%ebp),%eax
40000154:	89 45 ec             	mov    %eax,-0x14(%ebp)
40000157:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000015a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	inword = 0;
4000015d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	while ((n = read(fd, buf, sizeof(buf))) > 0) {
40000164:	eb 68                	jmp    400001ce <wc+0x8a>
		for (i=0; i<n; i++) {
40000166:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
4000016d:	eb 57                	jmp    400001c6 <wc+0x82>
			c++;
4000016f:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
			if (buf[i] == '\n')
40000173:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000176:	05 80 50 00 40       	add    $0x40005080,%eax
4000017b:	0f b6 00             	movzbl (%eax),%eax
4000017e:	3c 0a                	cmp    $0xa,%al
40000180:	75 04                	jne    40000186 <wc+0x42>
				l++;
40000182:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
			if (strchr(" \r\t\n\v", buf[i]))
40000186:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000189:	05 80 50 00 40       	add    $0x40005080,%eax
4000018e:	0f b6 00             	movzbl (%eax),%eax
40000191:	0f be c0             	movsbl %al,%eax
40000194:	89 44 24 04          	mov    %eax,0x4(%esp)
40000198:	c7 04 24 90 3a 00 40 	movl   $0x40003a90,(%esp)
4000019f:	e8 b9 0a 00 00       	call   40000c5d <strchr>
400001a4:	85 c0                	test   %eax,%eax
400001a6:	74 09                	je     400001b1 <wc+0x6d>
				inword = 0;
400001a8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
400001af:	eb 11                	jmp    400001c2 <wc+0x7e>
			else if (!inword) {
400001b1:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
400001b5:	75 0b                	jne    400001c2 <wc+0x7e>
				w++;
400001b7:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
				inword = 1;
400001bb:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
	int l, w, c, inword;

	l = w = c = 0;
	inword = 0;
	while ((n = read(fd, buf, sizeof(buf))) > 0) {
		for (i=0; i<n; i++) {
400001c2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
400001c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
400001c9:	3b 45 e0             	cmp    -0x20(%ebp),%eax
400001cc:	7c a1                	jl     4000016f <wc+0x2b>
	int i, n;
	int l, w, c, inword;

	l = w = c = 0;
	inword = 0;
	while ((n = read(fd, buf, sizeof(buf))) > 0) {
400001ce:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
400001d5:	00 
400001d6:	c7 44 24 04 80 50 00 	movl   $0x40005080,0x4(%esp)
400001dd:	40 
400001de:	8b 45 08             	mov    0x8(%ebp),%eax
400001e1:	89 04 24             	mov    %eax,(%esp)
400001e4:	e8 a4 26 00 00       	call   4000288d <read>
400001e9:	89 45 e0             	mov    %eax,-0x20(%ebp)
400001ec:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
400001f0:	0f 8f 70 ff ff ff    	jg     40000166 <wc+0x22>
				w++;
				inword = 1;
			}
		}
	}
	if (n < 0) {
400001f6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
400001fa:	79 18                	jns    40000214 <wc+0xd0>
		cprintf("wc: read error\n");
400001fc:	c7 04 24 96 3a 00 40 	movl   $0x40003a96,(%esp)
40000203:	e8 f0 01 00 00       	call   400003f8 <cprintf>
		exit(1);
40000208:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
4000020f:	e8 68 25 00 00       	call   4000277c <exit>
	}
	printf("%d %d %d %s\n", l, w, c, name);
40000214:	8b 45 0c             	mov    0xc(%ebp),%eax
40000217:	89 44 24 10          	mov    %eax,0x10(%esp)
4000021b:	8b 45 e8             	mov    -0x18(%ebp),%eax
4000021e:	89 44 24 0c          	mov    %eax,0xc(%esp)
40000222:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000225:	89 44 24 08          	mov    %eax,0x8(%esp)
40000229:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000022c:	89 44 24 04          	mov    %eax,0x4(%esp)
40000230:	c7 04 24 a6 3a 00 40 	movl   $0x40003aa6,(%esp)
40000237:	e8 8b 2c 00 00       	call   40002ec7 <printf>
}
4000023c:	c9                   	leave  
4000023d:	c3                   	ret    

4000023e <main>:

int
main(int argc, char *argv[])
{
4000023e:	55                   	push   %ebp
4000023f:	89 e5                	mov    %esp,%ebp
40000241:	83 e4 f0             	and    $0xfffffff0,%esp
40000244:	83 ec 20             	sub    $0x20,%esp
	int fd, i;

	if (argc <= 1) {
40000247:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
4000024b:	7f 1e                	jg     4000026b <main+0x2d>
		wc(0, "");
4000024d:	c7 44 24 04 b3 3a 00 	movl   $0x40003ab3,0x4(%esp)
40000254:	40 
40000255:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000025c:	e8 e3 fe ff ff       	call   40000144 <wc>
		return 0;
40000261:	b8 00 00 00 00       	mov    $0x0,%eax
40000266:	e9 c0 00 00 00       	jmp    4000032b <main+0xed>
	}

	for (i = 1; i < argc; i++) {
4000026b:	c7 44 24 1c 01 00 00 	movl   $0x1,0x1c(%esp)
40000272:	00 
40000273:	e9 a1 00 00 00       	jmp    40000319 <main+0xdb>
		if ((fd = open(argv[i], O_RDONLY)) < 0) {
40000278:	8b 44 24 1c          	mov    0x1c(%esp),%eax
4000027c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
40000283:	8b 45 0c             	mov    0xc(%ebp),%eax
40000286:	01 d0                	add    %edx,%eax
40000288:	8b 00                	mov    (%eax),%eax
4000028a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40000291:	00 
40000292:	89 04 24             	mov    %eax,(%esp)
40000295:	e8 58 25 00 00       	call   400027f2 <open>
4000029a:	89 44 24 18          	mov    %eax,0x18(%esp)
4000029e:	83 7c 24 18 00       	cmpl   $0x0,0x18(%esp)
400002a3:	79 41                	jns    400002e6 <main+0xa8>
			cprintf("cat: cannot open %s: %s\n", argv[i],
				strerror(errno));
400002a5:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
		return 0;
	}

	for (i = 1; i < argc; i++) {
		if ((fd = open(argv[i], O_RDONLY)) < 0) {
			cprintf("cat: cannot open %s: %s\n", argv[i],
400002aa:	8b 00                	mov    (%eax),%eax
400002ac:	89 04 24             	mov    %eax,(%esp)
400002af:	e8 44 2c 00 00       	call   40002ef8 <strerror>
400002b4:	8b 54 24 1c          	mov    0x1c(%esp),%edx
400002b8:	8d 0c 95 00 00 00 00 	lea    0x0(,%edx,4),%ecx
400002bf:	8b 55 0c             	mov    0xc(%ebp),%edx
400002c2:	01 ca                	add    %ecx,%edx
400002c4:	8b 12                	mov    (%edx),%edx
400002c6:	89 44 24 08          	mov    %eax,0x8(%esp)
400002ca:	89 54 24 04          	mov    %edx,0x4(%esp)
400002ce:	c7 04 24 b4 3a 00 40 	movl   $0x40003ab4,(%esp)
400002d5:	e8 1e 01 00 00       	call   400003f8 <cprintf>
				strerror(errno));
			exit(1);
400002da:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
400002e1:	e8 96 24 00 00       	call   4000277c <exit>
		}
		wc(fd, argv[i]);
400002e6:	8b 44 24 1c          	mov    0x1c(%esp),%eax
400002ea:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
400002f1:	8b 45 0c             	mov    0xc(%ebp),%eax
400002f4:	01 d0                	add    %edx,%eax
400002f6:	8b 00                	mov    (%eax),%eax
400002f8:	89 44 24 04          	mov    %eax,0x4(%esp)
400002fc:	8b 44 24 18          	mov    0x18(%esp),%eax
40000300:	89 04 24             	mov    %eax,(%esp)
40000303:	e8 3c fe ff ff       	call   40000144 <wc>
		close(fd);
40000308:	8b 44 24 18          	mov    0x18(%esp),%eax
4000030c:	89 04 24             	mov    %eax,(%esp)
4000030f:	e8 54 25 00 00       	call   40002868 <close>
	if (argc <= 1) {
		wc(0, "");
		return 0;
	}

	for (i = 1; i < argc; i++) {
40000314:	83 44 24 1c 01       	addl   $0x1,0x1c(%esp)
40000319:	8b 44 24 1c          	mov    0x1c(%esp),%eax
4000031d:	3b 45 08             	cmp    0x8(%ebp),%eax
40000320:	0f 8c 52 ff ff ff    	jl     40000278 <main+0x3a>
			exit(1);
		}
		wc(fd, argv[i]);
		close(fd);
	}
	return 0;
40000326:	b8 00 00 00 00       	mov    $0x0,%eax
}
4000032b:	c9                   	leave  
4000032c:	c3                   	ret    
4000032d:	66 90                	xchg   %ax,%ax
4000032f:	90                   	nop

40000330 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
40000330:	55                   	push   %ebp
40000331:	89 e5                	mov    %esp,%ebp
40000333:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
40000336:	8b 45 0c             	mov    0xc(%ebp),%eax
40000339:	8b 00                	mov    (%eax),%eax
4000033b:	8b 55 08             	mov    0x8(%ebp),%edx
4000033e:	89 d1                	mov    %edx,%ecx
40000340:	8b 55 0c             	mov    0xc(%ebp),%edx
40000343:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
40000347:	8d 50 01             	lea    0x1(%eax),%edx
4000034a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000034d:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
4000034f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000352:	8b 00                	mov    (%eax),%eax
40000354:	3d ff 00 00 00       	cmp    $0xff,%eax
40000359:	75 24                	jne    4000037f <putch+0x4f>
		b->buf[b->idx] = 0;
4000035b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000035e:	8b 00                	mov    (%eax),%eax
40000360:	8b 55 0c             	mov    0xc(%ebp),%edx
40000363:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
40000368:	8b 45 0c             	mov    0xc(%ebp),%eax
4000036b:	83 c0 08             	add    $0x8,%eax
4000036e:	89 04 24             	mov    %eax,(%esp)
40000371:	e8 9a 2d 00 00       	call   40003110 <cputs>
		b->idx = 0;
40000376:	8b 45 0c             	mov    0xc(%ebp),%eax
40000379:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
4000037f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000382:	8b 40 04             	mov    0x4(%eax),%eax
40000385:	8d 50 01             	lea    0x1(%eax),%edx
40000388:	8b 45 0c             	mov    0xc(%ebp),%eax
4000038b:	89 50 04             	mov    %edx,0x4(%eax)
}
4000038e:	c9                   	leave  
4000038f:	c3                   	ret    

40000390 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
40000390:	55                   	push   %ebp
40000391:	89 e5                	mov    %esp,%ebp
40000393:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
40000399:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
400003a0:	00 00 00 
	b.cnt = 0;
400003a3:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
400003aa:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
400003ad:	8b 45 0c             	mov    0xc(%ebp),%eax
400003b0:	89 44 24 0c          	mov    %eax,0xc(%esp)
400003b4:	8b 45 08             	mov    0x8(%ebp),%eax
400003b7:	89 44 24 08          	mov    %eax,0x8(%esp)
400003bb:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
400003c1:	89 44 24 04          	mov    %eax,0x4(%esp)
400003c5:	c7 04 24 30 03 00 40 	movl   $0x40000330,(%esp)
400003cc:	e8 70 03 00 00       	call   40000741 <vprintfmt>

	b.buf[b.idx] = 0;
400003d1:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
400003d7:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
400003de:	00 
	cputs(b.buf);
400003df:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
400003e5:	83 c0 08             	add    $0x8,%eax
400003e8:	89 04 24             	mov    %eax,(%esp)
400003eb:	e8 20 2d 00 00       	call   40003110 <cputs>

	return b.cnt;
400003f0:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
400003f6:	c9                   	leave  
400003f7:	c3                   	ret    

400003f8 <cprintf>:

int
cprintf(const char *fmt, ...)
{
400003f8:	55                   	push   %ebp
400003f9:	89 e5                	mov    %esp,%ebp
400003fb:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
400003fe:	8d 45 0c             	lea    0xc(%ebp),%eax
40000401:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
40000404:	8b 45 08             	mov    0x8(%ebp),%eax
40000407:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000040a:	89 54 24 04          	mov    %edx,0x4(%esp)
4000040e:	89 04 24             	mov    %eax,(%esp)
40000411:	e8 7a ff ff ff       	call   40000390 <vcprintf>
40000416:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
40000419:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
4000041c:	c9                   	leave  
4000041d:	c3                   	ret    
4000041e:	66 90                	xchg   %ax,%ax

40000420 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
40000420:	55                   	push   %ebp
40000421:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
40000423:	8b 45 08             	mov    0x8(%ebp),%eax
40000426:	8b 40 18             	mov    0x18(%eax),%eax
40000429:	83 e0 02             	and    $0x2,%eax
4000042c:	85 c0                	test   %eax,%eax
4000042e:	74 1c                	je     4000044c <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
40000430:	8b 45 0c             	mov    0xc(%ebp),%eax
40000433:	8b 00                	mov    (%eax),%eax
40000435:	8d 50 08             	lea    0x8(%eax),%edx
40000438:	8b 45 0c             	mov    0xc(%ebp),%eax
4000043b:	89 10                	mov    %edx,(%eax)
4000043d:	8b 45 0c             	mov    0xc(%ebp),%eax
40000440:	8b 00                	mov    (%eax),%eax
40000442:	83 e8 08             	sub    $0x8,%eax
40000445:	8b 50 04             	mov    0x4(%eax),%edx
40000448:	8b 00                	mov    (%eax),%eax
4000044a:	eb 47                	jmp    40000493 <getuint+0x73>
	else if (st->flags & F_L)
4000044c:	8b 45 08             	mov    0x8(%ebp),%eax
4000044f:	8b 40 18             	mov    0x18(%eax),%eax
40000452:	83 e0 01             	and    $0x1,%eax
40000455:	85 c0                	test   %eax,%eax
40000457:	74 1e                	je     40000477 <getuint+0x57>
		return va_arg(*ap, unsigned long);
40000459:	8b 45 0c             	mov    0xc(%ebp),%eax
4000045c:	8b 00                	mov    (%eax),%eax
4000045e:	8d 50 04             	lea    0x4(%eax),%edx
40000461:	8b 45 0c             	mov    0xc(%ebp),%eax
40000464:	89 10                	mov    %edx,(%eax)
40000466:	8b 45 0c             	mov    0xc(%ebp),%eax
40000469:	8b 00                	mov    (%eax),%eax
4000046b:	83 e8 04             	sub    $0x4,%eax
4000046e:	8b 00                	mov    (%eax),%eax
40000470:	ba 00 00 00 00       	mov    $0x0,%edx
40000475:	eb 1c                	jmp    40000493 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
40000477:	8b 45 0c             	mov    0xc(%ebp),%eax
4000047a:	8b 00                	mov    (%eax),%eax
4000047c:	8d 50 04             	lea    0x4(%eax),%edx
4000047f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000482:	89 10                	mov    %edx,(%eax)
40000484:	8b 45 0c             	mov    0xc(%ebp),%eax
40000487:	8b 00                	mov    (%eax),%eax
40000489:	83 e8 04             	sub    $0x4,%eax
4000048c:	8b 00                	mov    (%eax),%eax
4000048e:	ba 00 00 00 00       	mov    $0x0,%edx
}
40000493:	5d                   	pop    %ebp
40000494:	c3                   	ret    

40000495 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
40000495:	55                   	push   %ebp
40000496:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
40000498:	8b 45 08             	mov    0x8(%ebp),%eax
4000049b:	8b 40 18             	mov    0x18(%eax),%eax
4000049e:	83 e0 02             	and    $0x2,%eax
400004a1:	85 c0                	test   %eax,%eax
400004a3:	74 1c                	je     400004c1 <getint+0x2c>
		return va_arg(*ap, long long);
400004a5:	8b 45 0c             	mov    0xc(%ebp),%eax
400004a8:	8b 00                	mov    (%eax),%eax
400004aa:	8d 50 08             	lea    0x8(%eax),%edx
400004ad:	8b 45 0c             	mov    0xc(%ebp),%eax
400004b0:	89 10                	mov    %edx,(%eax)
400004b2:	8b 45 0c             	mov    0xc(%ebp),%eax
400004b5:	8b 00                	mov    (%eax),%eax
400004b7:	83 e8 08             	sub    $0x8,%eax
400004ba:	8b 50 04             	mov    0x4(%eax),%edx
400004bd:	8b 00                	mov    (%eax),%eax
400004bf:	eb 47                	jmp    40000508 <getint+0x73>
	else if (st->flags & F_L)
400004c1:	8b 45 08             	mov    0x8(%ebp),%eax
400004c4:	8b 40 18             	mov    0x18(%eax),%eax
400004c7:	83 e0 01             	and    $0x1,%eax
400004ca:	85 c0                	test   %eax,%eax
400004cc:	74 1e                	je     400004ec <getint+0x57>
		return va_arg(*ap, long);
400004ce:	8b 45 0c             	mov    0xc(%ebp),%eax
400004d1:	8b 00                	mov    (%eax),%eax
400004d3:	8d 50 04             	lea    0x4(%eax),%edx
400004d6:	8b 45 0c             	mov    0xc(%ebp),%eax
400004d9:	89 10                	mov    %edx,(%eax)
400004db:	8b 45 0c             	mov    0xc(%ebp),%eax
400004de:	8b 00                	mov    (%eax),%eax
400004e0:	83 e8 04             	sub    $0x4,%eax
400004e3:	8b 00                	mov    (%eax),%eax
400004e5:	89 c2                	mov    %eax,%edx
400004e7:	c1 fa 1f             	sar    $0x1f,%edx
400004ea:	eb 1c                	jmp    40000508 <getint+0x73>
	else
		return va_arg(*ap, int);
400004ec:	8b 45 0c             	mov    0xc(%ebp),%eax
400004ef:	8b 00                	mov    (%eax),%eax
400004f1:	8d 50 04             	lea    0x4(%eax),%edx
400004f4:	8b 45 0c             	mov    0xc(%ebp),%eax
400004f7:	89 10                	mov    %edx,(%eax)
400004f9:	8b 45 0c             	mov    0xc(%ebp),%eax
400004fc:	8b 00                	mov    (%eax),%eax
400004fe:	83 e8 04             	sub    $0x4,%eax
40000501:	8b 00                	mov    (%eax),%eax
40000503:	89 c2                	mov    %eax,%edx
40000505:	c1 fa 1f             	sar    $0x1f,%edx
}
40000508:	5d                   	pop    %ebp
40000509:	c3                   	ret    

4000050a <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
4000050a:	55                   	push   %ebp
4000050b:	89 e5                	mov    %esp,%ebp
4000050d:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
40000510:	eb 1a                	jmp    4000052c <putpad+0x22>
		st->putch(st->padc, st->putdat);
40000512:	8b 45 08             	mov    0x8(%ebp),%eax
40000515:	8b 00                	mov    (%eax),%eax
40000517:	8b 55 08             	mov    0x8(%ebp),%edx
4000051a:	8b 4a 04             	mov    0x4(%edx),%ecx
4000051d:	8b 55 08             	mov    0x8(%ebp),%edx
40000520:	8b 52 08             	mov    0x8(%edx),%edx
40000523:	89 4c 24 04          	mov    %ecx,0x4(%esp)
40000527:	89 14 24             	mov    %edx,(%esp)
4000052a:	ff d0                	call   *%eax

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
4000052c:	8b 45 08             	mov    0x8(%ebp),%eax
4000052f:	8b 40 0c             	mov    0xc(%eax),%eax
40000532:	8d 50 ff             	lea    -0x1(%eax),%edx
40000535:	8b 45 08             	mov    0x8(%ebp),%eax
40000538:	89 50 0c             	mov    %edx,0xc(%eax)
4000053b:	8b 45 08             	mov    0x8(%ebp),%eax
4000053e:	8b 40 0c             	mov    0xc(%eax),%eax
40000541:	85 c0                	test   %eax,%eax
40000543:	79 cd                	jns    40000512 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
40000545:	c9                   	leave  
40000546:	c3                   	ret    

40000547 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
40000547:	55                   	push   %ebp
40000548:	89 e5                	mov    %esp,%ebp
4000054a:	53                   	push   %ebx
4000054b:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
4000054e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000552:	79 18                	jns    4000056c <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
40000554:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000055b:	00 
4000055c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000055f:	89 04 24             	mov    %eax,(%esp)
40000562:	e8 f6 06 00 00       	call   40000c5d <strchr>
40000567:	89 45 f4             	mov    %eax,-0xc(%ebp)
4000056a:	eb 2e                	jmp    4000059a <putstr+0x53>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
4000056c:	8b 45 10             	mov    0x10(%ebp),%eax
4000056f:	89 44 24 08          	mov    %eax,0x8(%esp)
40000573:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000057a:	00 
4000057b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000057e:	89 04 24             	mov    %eax,(%esp)
40000581:	e8 d4 08 00 00       	call   40000e5a <memchr>
40000586:	89 45 f4             	mov    %eax,-0xc(%ebp)
40000589:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
4000058d:	75 0b                	jne    4000059a <putstr+0x53>
		lim = str + maxlen;
4000058f:	8b 55 10             	mov    0x10(%ebp),%edx
40000592:	8b 45 0c             	mov    0xc(%ebp),%eax
40000595:	01 d0                	add    %edx,%eax
40000597:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
4000059a:	8b 45 08             	mov    0x8(%ebp),%eax
4000059d:	8b 40 0c             	mov    0xc(%eax),%eax
400005a0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
400005a3:	8b 55 f4             	mov    -0xc(%ebp),%edx
400005a6:	89 cb                	mov    %ecx,%ebx
400005a8:	29 d3                	sub    %edx,%ebx
400005aa:	89 da                	mov    %ebx,%edx
400005ac:	01 c2                	add    %eax,%edx
400005ae:	8b 45 08             	mov    0x8(%ebp),%eax
400005b1:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
400005b4:	8b 45 08             	mov    0x8(%ebp),%eax
400005b7:	8b 40 18             	mov    0x18(%eax),%eax
400005ba:	83 e0 10             	and    $0x10,%eax
400005bd:	85 c0                	test   %eax,%eax
400005bf:	75 32                	jne    400005f3 <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
400005c1:	8b 45 08             	mov    0x8(%ebp),%eax
400005c4:	89 04 24             	mov    %eax,(%esp)
400005c7:	e8 3e ff ff ff       	call   4000050a <putpad>
	while (str < lim) {
400005cc:	eb 25                	jmp    400005f3 <putstr+0xac>
		char ch = *str++;
400005ce:	8b 45 0c             	mov    0xc(%ebp),%eax
400005d1:	0f b6 00             	movzbl (%eax),%eax
400005d4:	88 45 f3             	mov    %al,-0xd(%ebp)
400005d7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
400005db:	8b 45 08             	mov    0x8(%ebp),%eax
400005de:	8b 00                	mov    (%eax),%eax
400005e0:	8b 55 08             	mov    0x8(%ebp),%edx
400005e3:	8b 4a 04             	mov    0x4(%edx),%ecx
400005e6:	0f be 55 f3          	movsbl -0xd(%ebp),%edx
400005ea:	89 4c 24 04          	mov    %ecx,0x4(%esp)
400005ee:	89 14 24             	mov    %edx,(%esp)
400005f1:	ff d0                	call   *%eax
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
400005f3:	8b 45 0c             	mov    0xc(%ebp),%eax
400005f6:	3b 45 f4             	cmp    -0xc(%ebp),%eax
400005f9:	72 d3                	jb     400005ce <putstr+0x87>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
400005fb:	8b 45 08             	mov    0x8(%ebp),%eax
400005fe:	89 04 24             	mov    %eax,(%esp)
40000601:	e8 04 ff ff ff       	call   4000050a <putpad>
}
40000606:	83 c4 24             	add    $0x24,%esp
40000609:	5b                   	pop    %ebx
4000060a:	5d                   	pop    %ebp
4000060b:	c3                   	ret    

4000060c <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
4000060c:	55                   	push   %ebp
4000060d:	89 e5                	mov    %esp,%ebp
4000060f:	53                   	push   %ebx
40000610:	83 ec 24             	sub    $0x24,%esp
40000613:	8b 45 10             	mov    0x10(%ebp),%eax
40000616:	89 45 f0             	mov    %eax,-0x10(%ebp)
40000619:	8b 45 14             	mov    0x14(%ebp),%eax
4000061c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
4000061f:	8b 45 08             	mov    0x8(%ebp),%eax
40000622:	8b 40 1c             	mov    0x1c(%eax),%eax
40000625:	89 c2                	mov    %eax,%edx
40000627:	c1 fa 1f             	sar    $0x1f,%edx
4000062a:	3b 55 f4             	cmp    -0xc(%ebp),%edx
4000062d:	77 4e                	ja     4000067d <genint+0x71>
4000062f:	3b 55 f4             	cmp    -0xc(%ebp),%edx
40000632:	72 05                	jb     40000639 <genint+0x2d>
40000634:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40000637:	77 44                	ja     4000067d <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
40000639:	8b 45 08             	mov    0x8(%ebp),%eax
4000063c:	8b 40 1c             	mov    0x1c(%eax),%eax
4000063f:	89 c2                	mov    %eax,%edx
40000641:	c1 fa 1f             	sar    $0x1f,%edx
40000644:	89 44 24 08          	mov    %eax,0x8(%esp)
40000648:	89 54 24 0c          	mov    %edx,0xc(%esp)
4000064c:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000064f:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000652:	89 04 24             	mov    %eax,(%esp)
40000655:	89 54 24 04          	mov    %edx,0x4(%esp)
40000659:	e8 52 31 00 00       	call   400037b0 <__udivdi3>
4000065e:	89 44 24 08          	mov    %eax,0x8(%esp)
40000662:	89 54 24 0c          	mov    %edx,0xc(%esp)
40000666:	8b 45 0c             	mov    0xc(%ebp),%eax
40000669:	89 44 24 04          	mov    %eax,0x4(%esp)
4000066d:	8b 45 08             	mov    0x8(%ebp),%eax
40000670:	89 04 24             	mov    %eax,(%esp)
40000673:	e8 94 ff ff ff       	call   4000060c <genint>
40000678:	89 45 0c             	mov    %eax,0xc(%ebp)
4000067b:	eb 1b                	jmp    40000698 <genint+0x8c>
	else if (st->signc >= 0)
4000067d:	8b 45 08             	mov    0x8(%ebp),%eax
40000680:	8b 40 14             	mov    0x14(%eax),%eax
40000683:	85 c0                	test   %eax,%eax
40000685:	78 11                	js     40000698 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
40000687:	8b 45 08             	mov    0x8(%ebp),%eax
4000068a:	8b 40 14             	mov    0x14(%eax),%eax
4000068d:	89 c2                	mov    %eax,%edx
4000068f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000692:	88 10                	mov    %dl,(%eax)
40000694:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
40000698:	8b 45 08             	mov    0x8(%ebp),%eax
4000069b:	8b 40 1c             	mov    0x1c(%eax),%eax
4000069e:	89 c1                	mov    %eax,%ecx
400006a0:	89 c3                	mov    %eax,%ebx
400006a2:	c1 fb 1f             	sar    $0x1f,%ebx
400006a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
400006a8:	8b 55 f4             	mov    -0xc(%ebp),%edx
400006ab:	89 4c 24 08          	mov    %ecx,0x8(%esp)
400006af:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
400006b3:	89 04 24             	mov    %eax,(%esp)
400006b6:	89 54 24 04          	mov    %edx,0x4(%esp)
400006ba:	e8 41 32 00 00       	call   40003900 <__umoddi3>
400006bf:	05 d0 3a 00 40       	add    $0x40003ad0,%eax
400006c4:	0f b6 10             	movzbl (%eax),%edx
400006c7:	8b 45 0c             	mov    0xc(%ebp),%eax
400006ca:	88 10                	mov    %dl,(%eax)
400006cc:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
400006d0:	8b 45 0c             	mov    0xc(%ebp),%eax
}
400006d3:	83 c4 24             	add    $0x24,%esp
400006d6:	5b                   	pop    %ebx
400006d7:	5d                   	pop    %ebp
400006d8:	c3                   	ret    

400006d9 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
400006d9:	55                   	push   %ebp
400006da:	89 e5                	mov    %esp,%ebp
400006dc:	83 ec 58             	sub    $0x58,%esp
400006df:	8b 45 0c             	mov    0xc(%ebp),%eax
400006e2:	89 45 c0             	mov    %eax,-0x40(%ebp)
400006e5:	8b 45 10             	mov    0x10(%ebp),%eax
400006e8:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
400006eb:	8d 45 d6             	lea    -0x2a(%ebp),%eax
400006ee:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
400006f1:	8b 45 08             	mov    0x8(%ebp),%eax
400006f4:	8b 55 14             	mov    0x14(%ebp),%edx
400006f7:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
400006fa:	8b 45 c0             	mov    -0x40(%ebp),%eax
400006fd:	8b 55 c4             	mov    -0x3c(%ebp),%edx
40000700:	89 44 24 08          	mov    %eax,0x8(%esp)
40000704:	89 54 24 0c          	mov    %edx,0xc(%esp)
40000708:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000070b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000070f:	8b 45 08             	mov    0x8(%ebp),%eax
40000712:	89 04 24             	mov    %eax,(%esp)
40000715:	e8 f2 fe ff ff       	call   4000060c <genint>
4000071a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
4000071d:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000720:	8d 45 d6             	lea    -0x2a(%ebp),%eax
40000723:	89 d1                	mov    %edx,%ecx
40000725:	29 c1                	sub    %eax,%ecx
40000727:	89 c8                	mov    %ecx,%eax
40000729:	89 44 24 08          	mov    %eax,0x8(%esp)
4000072d:	8d 45 d6             	lea    -0x2a(%ebp),%eax
40000730:	89 44 24 04          	mov    %eax,0x4(%esp)
40000734:	8b 45 08             	mov    0x8(%ebp),%eax
40000737:	89 04 24             	mov    %eax,(%esp)
4000073a:	e8 08 fe ff ff       	call   40000547 <putstr>
}
4000073f:	c9                   	leave  
40000740:	c3                   	ret    

40000741 <vprintfmt>:


// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
40000741:	55                   	push   %ebp
40000742:	89 e5                	mov    %esp,%ebp
40000744:	53                   	push   %ebx
40000745:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
40000748:	8d 55 cc             	lea    -0x34(%ebp),%edx
4000074b:	b9 00 00 00 00       	mov    $0x0,%ecx
40000750:	b8 20 00 00 00       	mov    $0x20,%eax
40000755:	89 c3                	mov    %eax,%ebx
40000757:	83 e3 fc             	and    $0xfffffffc,%ebx
4000075a:	b8 00 00 00 00       	mov    $0x0,%eax
4000075f:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
40000762:	83 c0 04             	add    $0x4,%eax
40000765:	39 d8                	cmp    %ebx,%eax
40000767:	72 f6                	jb     4000075f <vprintfmt+0x1e>
40000769:	01 c2                	add    %eax,%edx
4000076b:	8b 45 08             	mov    0x8(%ebp),%eax
4000076e:	89 45 cc             	mov    %eax,-0x34(%ebp)
40000771:	8b 45 0c             	mov    0xc(%ebp),%eax
40000774:	89 45 d0             	mov    %eax,-0x30(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40000777:	eb 17                	jmp    40000790 <vprintfmt+0x4f>
			if (ch == '\0')
40000779:	85 db                	test   %ebx,%ebx
4000077b:	0f 84 50 03 00 00    	je     40000ad1 <vprintfmt+0x390>
				return;
			putch(ch, putdat);
40000781:	8b 45 0c             	mov    0xc(%ebp),%eax
40000784:	89 44 24 04          	mov    %eax,0x4(%esp)
40000788:	89 1c 24             	mov    %ebx,(%esp)
4000078b:	8b 45 08             	mov    0x8(%ebp),%eax
4000078e:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40000790:	8b 45 10             	mov    0x10(%ebp),%eax
40000793:	0f b6 00             	movzbl (%eax),%eax
40000796:	0f b6 d8             	movzbl %al,%ebx
40000799:	83 fb 25             	cmp    $0x25,%ebx
4000079c:	0f 95 c0             	setne  %al
4000079f:	83 45 10 01          	addl   $0x1,0x10(%ebp)
400007a3:	84 c0                	test   %al,%al
400007a5:	75 d2                	jne    40000779 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
400007a7:	c7 45 d4 20 00 00 00 	movl   $0x20,-0x2c(%ebp)
		st.width = -1;
400007ae:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.prec = -1;
400007b5:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.signc = -1;
400007bc:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		st.flags = 0;
400007c3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		st.base = 10;
400007ca:	c7 45 e8 0a 00 00 00 	movl   $0xa,-0x18(%ebp)
400007d1:	eb 04                	jmp    400007d7 <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
400007d3:	90                   	nop
400007d4:	eb 01                	jmp    400007d7 <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
400007d6:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
400007d7:	8b 45 10             	mov    0x10(%ebp),%eax
400007da:	0f b6 00             	movzbl (%eax),%eax
400007dd:	0f b6 d8             	movzbl %al,%ebx
400007e0:	89 d8                	mov    %ebx,%eax
400007e2:	83 45 10 01          	addl   $0x1,0x10(%ebp)
400007e6:	83 e8 20             	sub    $0x20,%eax
400007e9:	83 f8 58             	cmp    $0x58,%eax
400007ec:	0f 87 ae 02 00 00    	ja     40000aa0 <vprintfmt+0x35f>
400007f2:	8b 04 85 e8 3a 00 40 	mov    0x40003ae8(,%eax,4),%eax
400007f9:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
400007fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400007fe:	83 c8 10             	or     $0x10,%eax
40000801:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
40000804:	eb d1                	jmp    400007d7 <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
40000806:	c7 45 e0 2b 00 00 00 	movl   $0x2b,-0x20(%ebp)
			goto reswitch;
4000080d:	eb c8                	jmp    400007d7 <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
4000080f:	8b 45 e0             	mov    -0x20(%ebp),%eax
40000812:	85 c0                	test   %eax,%eax
40000814:	79 bd                	jns    400007d3 <vprintfmt+0x92>
				st.signc = ' ';
40000816:	c7 45 e0 20 00 00 00 	movl   $0x20,-0x20(%ebp)
			goto reswitch;
4000081d:	eb b4                	jmp    400007d3 <vprintfmt+0x92>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
4000081f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40000822:	83 e0 08             	and    $0x8,%eax
40000825:	85 c0                	test   %eax,%eax
40000827:	75 07                	jne    40000830 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
40000829:	c7 45 d4 30 00 00 00 	movl   $0x30,-0x2c(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
40000830:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
				st.prec = st.prec * 10 + ch - '0';
40000837:	8b 55 dc             	mov    -0x24(%ebp),%edx
4000083a:	89 d0                	mov    %edx,%eax
4000083c:	c1 e0 02             	shl    $0x2,%eax
4000083f:	01 d0                	add    %edx,%eax
40000841:	01 c0                	add    %eax,%eax
40000843:	01 d8                	add    %ebx,%eax
40000845:	83 e8 30             	sub    $0x30,%eax
40000848:	89 45 dc             	mov    %eax,-0x24(%ebp)
				ch = *fmt;
4000084b:	8b 45 10             	mov    0x10(%ebp),%eax
4000084e:	0f b6 00             	movzbl (%eax),%eax
40000851:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
40000854:	83 fb 2f             	cmp    $0x2f,%ebx
40000857:	7e 21                	jle    4000087a <vprintfmt+0x139>
40000859:	83 fb 39             	cmp    $0x39,%ebx
4000085c:	7f 1c                	jg     4000087a <vprintfmt+0x139>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
4000085e:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
40000862:	eb d3                	jmp    40000837 <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
40000864:	8b 45 14             	mov    0x14(%ebp),%eax
40000867:	83 c0 04             	add    $0x4,%eax
4000086a:	89 45 14             	mov    %eax,0x14(%ebp)
4000086d:	8b 45 14             	mov    0x14(%ebp),%eax
40000870:	83 e8 04             	sub    $0x4,%eax
40000873:	8b 00                	mov    (%eax),%eax
40000875:	89 45 dc             	mov    %eax,-0x24(%ebp)
40000878:	eb 01                	jmp    4000087b <vprintfmt+0x13a>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
4000087a:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
4000087b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000087e:	83 e0 08             	and    $0x8,%eax
40000881:	85 c0                	test   %eax,%eax
40000883:	0f 85 4d ff ff ff    	jne    400007d6 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
40000889:	8b 45 dc             	mov    -0x24(%ebp),%eax
4000088c:	89 45 d8             	mov    %eax,-0x28(%ebp)
				st.prec = -1;
4000088f:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
			}
			goto reswitch;
40000896:	e9 3b ff ff ff       	jmp    400007d6 <vprintfmt+0x95>

		case '.':
			st.flags |= F_DOT;
4000089b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000089e:	83 c8 08             	or     $0x8,%eax
400008a1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
400008a4:	e9 2e ff ff ff       	jmp    400007d7 <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
400008a9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400008ac:	83 c8 04             	or     $0x4,%eax
400008af:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
400008b2:	e9 20 ff ff ff       	jmp    400007d7 <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
400008b7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
400008ba:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400008bd:	83 e0 01             	and    $0x1,%eax
400008c0:	85 c0                	test   %eax,%eax
400008c2:	74 07                	je     400008cb <vprintfmt+0x18a>
400008c4:	b8 02 00 00 00       	mov    $0x2,%eax
400008c9:	eb 05                	jmp    400008d0 <vprintfmt+0x18f>
400008cb:	b8 01 00 00 00       	mov    $0x1,%eax
400008d0:	09 d0                	or     %edx,%eax
400008d2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
400008d5:	e9 fd fe ff ff       	jmp    400007d7 <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
400008da:	8b 45 14             	mov    0x14(%ebp),%eax
400008dd:	83 c0 04             	add    $0x4,%eax
400008e0:	89 45 14             	mov    %eax,0x14(%ebp)
400008e3:	8b 45 14             	mov    0x14(%ebp),%eax
400008e6:	83 e8 04             	sub    $0x4,%eax
400008e9:	8b 00                	mov    (%eax),%eax
400008eb:	8b 55 0c             	mov    0xc(%ebp),%edx
400008ee:	89 54 24 04          	mov    %edx,0x4(%esp)
400008f2:	89 04 24             	mov    %eax,(%esp)
400008f5:	8b 45 08             	mov    0x8(%ebp),%eax
400008f8:	ff d0                	call   *%eax
			break;
400008fa:	e9 cc 01 00 00       	jmp    40000acb <vprintfmt+0x38a>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
400008ff:	8b 45 14             	mov    0x14(%ebp),%eax
40000902:	83 c0 04             	add    $0x4,%eax
40000905:	89 45 14             	mov    %eax,0x14(%ebp)
40000908:	8b 45 14             	mov    0x14(%ebp),%eax
4000090b:	83 e8 04             	sub    $0x4,%eax
4000090e:	8b 00                	mov    (%eax),%eax
40000910:	89 45 ec             	mov    %eax,-0x14(%ebp)
40000913:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
40000917:	75 07                	jne    40000920 <vprintfmt+0x1df>
				s = "(null)";
40000919:	c7 45 ec e1 3a 00 40 	movl   $0x40003ae1,-0x14(%ebp)
			putstr(&st, s, st.prec);
40000920:	8b 45 dc             	mov    -0x24(%ebp),%eax
40000923:	89 44 24 08          	mov    %eax,0x8(%esp)
40000927:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000092a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000092e:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000931:	89 04 24             	mov    %eax,(%esp)
40000934:	e8 0e fc ff ff       	call   40000547 <putstr>
			break;
40000939:	e9 8d 01 00 00       	jmp    40000acb <vprintfmt+0x38a>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
4000093e:	8d 45 14             	lea    0x14(%ebp),%eax
40000941:	89 44 24 04          	mov    %eax,0x4(%esp)
40000945:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000948:	89 04 24             	mov    %eax,(%esp)
4000094b:	e8 45 fb ff ff       	call   40000495 <getint>
40000950:	89 45 f0             	mov    %eax,-0x10(%ebp)
40000953:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((intmax_t) num < 0) {
40000956:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000959:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000095c:	85 d2                	test   %edx,%edx
4000095e:	79 1a                	jns    4000097a <vprintfmt+0x239>
				num = -(intmax_t) num;
40000960:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000963:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000966:	f7 d8                	neg    %eax
40000968:	83 d2 00             	adc    $0x0,%edx
4000096b:	f7 da                	neg    %edx
4000096d:	89 45 f0             	mov    %eax,-0x10(%ebp)
40000970:	89 55 f4             	mov    %edx,-0xc(%ebp)
				st.signc = '-';
40000973:	c7 45 e0 2d 00 00 00 	movl   $0x2d,-0x20(%ebp)
			}
			putint(&st, num, 10);
4000097a:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
40000981:	00 
40000982:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000985:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000988:	89 44 24 04          	mov    %eax,0x4(%esp)
4000098c:	89 54 24 08          	mov    %edx,0x8(%esp)
40000990:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000993:	89 04 24             	mov    %eax,(%esp)
40000996:	e8 3e fd ff ff       	call   400006d9 <putint>
			break;
4000099b:	e9 2b 01 00 00       	jmp    40000acb <vprintfmt+0x38a>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
400009a0:	8d 45 14             	lea    0x14(%ebp),%eax
400009a3:	89 44 24 04          	mov    %eax,0x4(%esp)
400009a7:	8d 45 cc             	lea    -0x34(%ebp),%eax
400009aa:	89 04 24             	mov    %eax,(%esp)
400009ad:	e8 6e fa ff ff       	call   40000420 <getuint>
400009b2:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
400009b9:	00 
400009ba:	89 44 24 04          	mov    %eax,0x4(%esp)
400009be:	89 54 24 08          	mov    %edx,0x8(%esp)
400009c2:	8d 45 cc             	lea    -0x34(%ebp),%eax
400009c5:	89 04 24             	mov    %eax,(%esp)
400009c8:	e8 0c fd ff ff       	call   400006d9 <putint>
			break;
400009cd:	e9 f9 00 00 00       	jmp    40000acb <vprintfmt+0x38a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
400009d2:	8d 45 14             	lea    0x14(%ebp),%eax
400009d5:	89 44 24 04          	mov    %eax,0x4(%esp)
400009d9:	8d 45 cc             	lea    -0x34(%ebp),%eax
400009dc:	89 04 24             	mov    %eax,(%esp)
400009df:	e8 3c fa ff ff       	call   40000420 <getuint>
400009e4:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
400009eb:	00 
400009ec:	89 44 24 04          	mov    %eax,0x4(%esp)
400009f0:	89 54 24 08          	mov    %edx,0x8(%esp)
400009f4:	8d 45 cc             	lea    -0x34(%ebp),%eax
400009f7:	89 04 24             	mov    %eax,(%esp)
400009fa:	e8 da fc ff ff       	call   400006d9 <putint>
			break;
400009ff:	e9 c7 00 00 00       	jmp    40000acb <vprintfmt+0x38a>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
40000a04:	8d 45 14             	lea    0x14(%ebp),%eax
40000a07:	89 44 24 04          	mov    %eax,0x4(%esp)
40000a0b:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000a0e:	89 04 24             	mov    %eax,(%esp)
40000a11:	e8 0a fa ff ff       	call   40000420 <getuint>
40000a16:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
40000a1d:	00 
40000a1e:	89 44 24 04          	mov    %eax,0x4(%esp)
40000a22:	89 54 24 08          	mov    %edx,0x8(%esp)
40000a26:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000a29:	89 04 24             	mov    %eax,(%esp)
40000a2c:	e8 a8 fc ff ff       	call   400006d9 <putint>
			break;
40000a31:	e9 95 00 00 00       	jmp    40000acb <vprintfmt+0x38a>

		// pointer
		case 'p':
			putch('0', putdat);
40000a36:	8b 45 0c             	mov    0xc(%ebp),%eax
40000a39:	89 44 24 04          	mov    %eax,0x4(%esp)
40000a3d:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
40000a44:	8b 45 08             	mov    0x8(%ebp),%eax
40000a47:	ff d0                	call   *%eax
			putch('x', putdat);
40000a49:	8b 45 0c             	mov    0xc(%ebp),%eax
40000a4c:	89 44 24 04          	mov    %eax,0x4(%esp)
40000a50:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
40000a57:	8b 45 08             	mov    0x8(%ebp),%eax
40000a5a:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
40000a5c:	8b 45 14             	mov    0x14(%ebp),%eax
40000a5f:	83 c0 04             	add    $0x4,%eax
40000a62:	89 45 14             	mov    %eax,0x14(%ebp)
40000a65:	8b 45 14             	mov    0x14(%ebp),%eax
40000a68:	83 e8 04             	sub    $0x4,%eax
40000a6b:	8b 00                	mov    (%eax),%eax
40000a6d:	ba 00 00 00 00       	mov    $0x0,%edx
40000a72:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
40000a79:	00 
40000a7a:	89 44 24 04          	mov    %eax,0x4(%esp)
40000a7e:	89 54 24 08          	mov    %edx,0x8(%esp)
40000a82:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000a85:	89 04 24             	mov    %eax,(%esp)
40000a88:	e8 4c fc ff ff       	call   400006d9 <putint>
			break;
40000a8d:	eb 3c                	jmp    40000acb <vprintfmt+0x38a>


		// escaped '%' character
		case '%':
			putch(ch, putdat);
40000a8f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000a92:	89 44 24 04          	mov    %eax,0x4(%esp)
40000a96:	89 1c 24             	mov    %ebx,(%esp)
40000a99:	8b 45 08             	mov    0x8(%ebp),%eax
40000a9c:	ff d0                	call   *%eax
			break;
40000a9e:	eb 2b                	jmp    40000acb <vprintfmt+0x38a>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
40000aa0:	8b 45 0c             	mov    0xc(%ebp),%eax
40000aa3:	89 44 24 04          	mov    %eax,0x4(%esp)
40000aa7:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
40000aae:	8b 45 08             	mov    0x8(%ebp),%eax
40000ab1:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
40000ab3:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40000ab7:	eb 04                	jmp    40000abd <vprintfmt+0x37c>
40000ab9:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40000abd:	8b 45 10             	mov    0x10(%ebp),%eax
40000ac0:	83 e8 01             	sub    $0x1,%eax
40000ac3:	0f b6 00             	movzbl (%eax),%eax
40000ac6:	3c 25                	cmp    $0x25,%al
40000ac8:	75 ef                	jne    40000ab9 <vprintfmt+0x378>
				/* do nothing */;
			break;
40000aca:	90                   	nop
		}
	}
40000acb:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40000acc:	e9 bf fc ff ff       	jmp    40000790 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
40000ad1:	83 c4 44             	add    $0x44,%esp
40000ad4:	5b                   	pop    %ebx
40000ad5:	5d                   	pop    %ebp
40000ad6:	c3                   	ret    
40000ad7:	90                   	nop

40000ad8 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
40000ad8:	55                   	push   %ebp
40000ad9:	89 e5                	mov    %esp,%ebp
40000adb:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
40000ade:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
40000ae5:	eb 08                	jmp    40000aef <strlen+0x17>
		n++;
40000ae7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
40000aeb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000aef:	8b 45 08             	mov    0x8(%ebp),%eax
40000af2:	0f b6 00             	movzbl (%eax),%eax
40000af5:	84 c0                	test   %al,%al
40000af7:	75 ee                	jne    40000ae7 <strlen+0xf>
		n++;
	return n;
40000af9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
40000afc:	c9                   	leave  
40000afd:	c3                   	ret    

40000afe <strcpy>:

char *
strcpy(char *dst, const char *src)
{
40000afe:	55                   	push   %ebp
40000aff:	89 e5                	mov    %esp,%ebp
40000b01:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
40000b04:	8b 45 08             	mov    0x8(%ebp),%eax
40000b07:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
40000b0a:	90                   	nop
40000b0b:	8b 45 0c             	mov    0xc(%ebp),%eax
40000b0e:	0f b6 10             	movzbl (%eax),%edx
40000b11:	8b 45 08             	mov    0x8(%ebp),%eax
40000b14:	88 10                	mov    %dl,(%eax)
40000b16:	8b 45 08             	mov    0x8(%ebp),%eax
40000b19:	0f b6 00             	movzbl (%eax),%eax
40000b1c:	84 c0                	test   %al,%al
40000b1e:	0f 95 c0             	setne  %al
40000b21:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000b25:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
40000b29:	84 c0                	test   %al,%al
40000b2b:	75 de                	jne    40000b0b <strcpy+0xd>
		/* do nothing */;
	return ret;
40000b2d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
40000b30:	c9                   	leave  
40000b31:	c3                   	ret    

40000b32 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
40000b32:	55                   	push   %ebp
40000b33:	89 e5                	mov    %esp,%ebp
40000b35:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
40000b38:	8b 45 08             	mov    0x8(%ebp),%eax
40000b3b:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
40000b3e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
40000b45:	eb 21                	jmp    40000b68 <strncpy+0x36>
		*dst++ = *src;
40000b47:	8b 45 0c             	mov    0xc(%ebp),%eax
40000b4a:	0f b6 10             	movzbl (%eax),%edx
40000b4d:	8b 45 08             	mov    0x8(%ebp),%eax
40000b50:	88 10                	mov    %dl,(%eax)
40000b52:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
40000b56:	8b 45 0c             	mov    0xc(%ebp),%eax
40000b59:	0f b6 00             	movzbl (%eax),%eax
40000b5c:	84 c0                	test   %al,%al
40000b5e:	74 04                	je     40000b64 <strncpy+0x32>
			src++;
40000b60:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
40000b64:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40000b68:	8b 45 fc             	mov    -0x4(%ebp),%eax
40000b6b:	3b 45 10             	cmp    0x10(%ebp),%eax
40000b6e:	72 d7                	jb     40000b47 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
40000b70:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
40000b73:	c9                   	leave  
40000b74:	c3                   	ret    

40000b75 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
40000b75:	55                   	push   %ebp
40000b76:	89 e5                	mov    %esp,%ebp
40000b78:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
40000b7b:	8b 45 08             	mov    0x8(%ebp),%eax
40000b7e:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
40000b81:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000b85:	74 2f                	je     40000bb6 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
40000b87:	eb 13                	jmp    40000b9c <strlcpy+0x27>
			*dst++ = *src++;
40000b89:	8b 45 0c             	mov    0xc(%ebp),%eax
40000b8c:	0f b6 10             	movzbl (%eax),%edx
40000b8f:	8b 45 08             	mov    0x8(%ebp),%eax
40000b92:	88 10                	mov    %dl,(%eax)
40000b94:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000b98:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
40000b9c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40000ba0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000ba4:	74 0a                	je     40000bb0 <strlcpy+0x3b>
40000ba6:	8b 45 0c             	mov    0xc(%ebp),%eax
40000ba9:	0f b6 00             	movzbl (%eax),%eax
40000bac:	84 c0                	test   %al,%al
40000bae:	75 d9                	jne    40000b89 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
40000bb0:	8b 45 08             	mov    0x8(%ebp),%eax
40000bb3:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
40000bb6:	8b 55 08             	mov    0x8(%ebp),%edx
40000bb9:	8b 45 fc             	mov    -0x4(%ebp),%eax
40000bbc:	89 d1                	mov    %edx,%ecx
40000bbe:	29 c1                	sub    %eax,%ecx
40000bc0:	89 c8                	mov    %ecx,%eax
}
40000bc2:	c9                   	leave  
40000bc3:	c3                   	ret    

40000bc4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
40000bc4:	55                   	push   %ebp
40000bc5:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
40000bc7:	eb 08                	jmp    40000bd1 <strcmp+0xd>
		p++, q++;
40000bc9:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000bcd:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
40000bd1:	8b 45 08             	mov    0x8(%ebp),%eax
40000bd4:	0f b6 00             	movzbl (%eax),%eax
40000bd7:	84 c0                	test   %al,%al
40000bd9:	74 10                	je     40000beb <strcmp+0x27>
40000bdb:	8b 45 08             	mov    0x8(%ebp),%eax
40000bde:	0f b6 10             	movzbl (%eax),%edx
40000be1:	8b 45 0c             	mov    0xc(%ebp),%eax
40000be4:	0f b6 00             	movzbl (%eax),%eax
40000be7:	38 c2                	cmp    %al,%dl
40000be9:	74 de                	je     40000bc9 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
40000beb:	8b 45 08             	mov    0x8(%ebp),%eax
40000bee:	0f b6 00             	movzbl (%eax),%eax
40000bf1:	0f b6 d0             	movzbl %al,%edx
40000bf4:	8b 45 0c             	mov    0xc(%ebp),%eax
40000bf7:	0f b6 00             	movzbl (%eax),%eax
40000bfa:	0f b6 c0             	movzbl %al,%eax
40000bfd:	89 d1                	mov    %edx,%ecx
40000bff:	29 c1                	sub    %eax,%ecx
40000c01:	89 c8                	mov    %ecx,%eax
}
40000c03:	5d                   	pop    %ebp
40000c04:	c3                   	ret    

40000c05 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
40000c05:	55                   	push   %ebp
40000c06:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
40000c08:	eb 0c                	jmp    40000c16 <strncmp+0x11>
		n--, p++, q++;
40000c0a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40000c0e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000c12:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
40000c16:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000c1a:	74 1a                	je     40000c36 <strncmp+0x31>
40000c1c:	8b 45 08             	mov    0x8(%ebp),%eax
40000c1f:	0f b6 00             	movzbl (%eax),%eax
40000c22:	84 c0                	test   %al,%al
40000c24:	74 10                	je     40000c36 <strncmp+0x31>
40000c26:	8b 45 08             	mov    0x8(%ebp),%eax
40000c29:	0f b6 10             	movzbl (%eax),%edx
40000c2c:	8b 45 0c             	mov    0xc(%ebp),%eax
40000c2f:	0f b6 00             	movzbl (%eax),%eax
40000c32:	38 c2                	cmp    %al,%dl
40000c34:	74 d4                	je     40000c0a <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
40000c36:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000c3a:	75 07                	jne    40000c43 <strncmp+0x3e>
		return 0;
40000c3c:	b8 00 00 00 00       	mov    $0x0,%eax
40000c41:	eb 18                	jmp    40000c5b <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
40000c43:	8b 45 08             	mov    0x8(%ebp),%eax
40000c46:	0f b6 00             	movzbl (%eax),%eax
40000c49:	0f b6 d0             	movzbl %al,%edx
40000c4c:	8b 45 0c             	mov    0xc(%ebp),%eax
40000c4f:	0f b6 00             	movzbl (%eax),%eax
40000c52:	0f b6 c0             	movzbl %al,%eax
40000c55:	89 d1                	mov    %edx,%ecx
40000c57:	29 c1                	sub    %eax,%ecx
40000c59:	89 c8                	mov    %ecx,%eax
}
40000c5b:	5d                   	pop    %ebp
40000c5c:	c3                   	ret    

40000c5d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
40000c5d:	55                   	push   %ebp
40000c5e:	89 e5                	mov    %esp,%ebp
40000c60:	83 ec 04             	sub    $0x4,%esp
40000c63:	8b 45 0c             	mov    0xc(%ebp),%eax
40000c66:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
40000c69:	eb 1a                	jmp    40000c85 <strchr+0x28>
		if (*s++ == 0)
40000c6b:	8b 45 08             	mov    0x8(%ebp),%eax
40000c6e:	0f b6 00             	movzbl (%eax),%eax
40000c71:	84 c0                	test   %al,%al
40000c73:	0f 94 c0             	sete   %al
40000c76:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000c7a:	84 c0                	test   %al,%al
40000c7c:	74 07                	je     40000c85 <strchr+0x28>
			return NULL;
40000c7e:	b8 00 00 00 00       	mov    $0x0,%eax
40000c83:	eb 0e                	jmp    40000c93 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
40000c85:	8b 45 08             	mov    0x8(%ebp),%eax
40000c88:	0f b6 00             	movzbl (%eax),%eax
40000c8b:	3a 45 fc             	cmp    -0x4(%ebp),%al
40000c8e:	75 db                	jne    40000c6b <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
40000c90:	8b 45 08             	mov    0x8(%ebp),%eax
}
40000c93:	c9                   	leave  
40000c94:	c3                   	ret    

40000c95 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
40000c95:	55                   	push   %ebp
40000c96:	89 e5                	mov    %esp,%ebp
40000c98:	57                   	push   %edi
	char *p;

	if (n == 0)
40000c99:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000c9d:	75 05                	jne    40000ca4 <memset+0xf>
		return v;
40000c9f:	8b 45 08             	mov    0x8(%ebp),%eax
40000ca2:	eb 5c                	jmp    40000d00 <memset+0x6b>
	if ((int)v%4 == 0 && n%4 == 0) {
40000ca4:	8b 45 08             	mov    0x8(%ebp),%eax
40000ca7:	83 e0 03             	and    $0x3,%eax
40000caa:	85 c0                	test   %eax,%eax
40000cac:	75 41                	jne    40000cef <memset+0x5a>
40000cae:	8b 45 10             	mov    0x10(%ebp),%eax
40000cb1:	83 e0 03             	and    $0x3,%eax
40000cb4:	85 c0                	test   %eax,%eax
40000cb6:	75 37                	jne    40000cef <memset+0x5a>
		c &= 0xFF;
40000cb8:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
40000cbf:	8b 45 0c             	mov    0xc(%ebp),%eax
40000cc2:	89 c2                	mov    %eax,%edx
40000cc4:	c1 e2 18             	shl    $0x18,%edx
40000cc7:	8b 45 0c             	mov    0xc(%ebp),%eax
40000cca:	c1 e0 10             	shl    $0x10,%eax
40000ccd:	09 c2                	or     %eax,%edx
40000ccf:	8b 45 0c             	mov    0xc(%ebp),%eax
40000cd2:	c1 e0 08             	shl    $0x8,%eax
40000cd5:	09 d0                	or     %edx,%eax
40000cd7:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
40000cda:	8b 45 10             	mov    0x10(%ebp),%eax
40000cdd:	89 c1                	mov    %eax,%ecx
40000cdf:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
40000ce2:	8b 55 08             	mov    0x8(%ebp),%edx
40000ce5:	8b 45 0c             	mov    0xc(%ebp),%eax
40000ce8:	89 d7                	mov    %edx,%edi
40000cea:	fc                   	cld    
40000ceb:	f3 ab                	rep stos %eax,%es:(%edi)
40000ced:	eb 0e                	jmp    40000cfd <memset+0x68>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
40000cef:	8b 55 08             	mov    0x8(%ebp),%edx
40000cf2:	8b 45 0c             	mov    0xc(%ebp),%eax
40000cf5:	8b 4d 10             	mov    0x10(%ebp),%ecx
40000cf8:	89 d7                	mov    %edx,%edi
40000cfa:	fc                   	cld    
40000cfb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
40000cfd:	8b 45 08             	mov    0x8(%ebp),%eax
}
40000d00:	5f                   	pop    %edi
40000d01:	5d                   	pop    %ebp
40000d02:	c3                   	ret    

40000d03 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
40000d03:	55                   	push   %ebp
40000d04:	89 e5                	mov    %esp,%ebp
40000d06:	57                   	push   %edi
40000d07:	56                   	push   %esi
40000d08:	53                   	push   %ebx
40000d09:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
40000d0c:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d0f:	89 45 f0             	mov    %eax,-0x10(%ebp)
	d = dst;
40000d12:	8b 45 08             	mov    0x8(%ebp),%eax
40000d15:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (s < d && s + n > d) {
40000d18:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000d1b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
40000d1e:	73 6d                	jae    40000d8d <memmove+0x8a>
40000d20:	8b 45 10             	mov    0x10(%ebp),%eax
40000d23:	8b 55 f0             	mov    -0x10(%ebp),%edx
40000d26:	01 d0                	add    %edx,%eax
40000d28:	3b 45 ec             	cmp    -0x14(%ebp),%eax
40000d2b:	76 60                	jbe    40000d8d <memmove+0x8a>
		s += n;
40000d2d:	8b 45 10             	mov    0x10(%ebp),%eax
40000d30:	01 45 f0             	add    %eax,-0x10(%ebp)
		d += n;
40000d33:	8b 45 10             	mov    0x10(%ebp),%eax
40000d36:	01 45 ec             	add    %eax,-0x14(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
40000d39:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000d3c:	83 e0 03             	and    $0x3,%eax
40000d3f:	85 c0                	test   %eax,%eax
40000d41:	75 2f                	jne    40000d72 <memmove+0x6f>
40000d43:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000d46:	83 e0 03             	and    $0x3,%eax
40000d49:	85 c0                	test   %eax,%eax
40000d4b:	75 25                	jne    40000d72 <memmove+0x6f>
40000d4d:	8b 45 10             	mov    0x10(%ebp),%eax
40000d50:	83 e0 03             	and    $0x3,%eax
40000d53:	85 c0                	test   %eax,%eax
40000d55:	75 1b                	jne    40000d72 <memmove+0x6f>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
40000d57:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000d5a:	83 e8 04             	sub    $0x4,%eax
40000d5d:	8b 55 f0             	mov    -0x10(%ebp),%edx
40000d60:	83 ea 04             	sub    $0x4,%edx
40000d63:	8b 4d 10             	mov    0x10(%ebp),%ecx
40000d66:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
40000d69:	89 c7                	mov    %eax,%edi
40000d6b:	89 d6                	mov    %edx,%esi
40000d6d:	fd                   	std    
40000d6e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
40000d70:	eb 18                	jmp    40000d8a <memmove+0x87>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
40000d72:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000d75:	8d 50 ff             	lea    -0x1(%eax),%edx
40000d78:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000d7b:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
40000d7e:	8b 45 10             	mov    0x10(%ebp),%eax
40000d81:	89 d7                	mov    %edx,%edi
40000d83:	89 de                	mov    %ebx,%esi
40000d85:	89 c1                	mov    %eax,%ecx
40000d87:	fd                   	std    
40000d88:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
40000d8a:	fc                   	cld    
40000d8b:	eb 45                	jmp    40000dd2 <memmove+0xcf>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
40000d8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000d90:	83 e0 03             	and    $0x3,%eax
40000d93:	85 c0                	test   %eax,%eax
40000d95:	75 2b                	jne    40000dc2 <memmove+0xbf>
40000d97:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000d9a:	83 e0 03             	and    $0x3,%eax
40000d9d:	85 c0                	test   %eax,%eax
40000d9f:	75 21                	jne    40000dc2 <memmove+0xbf>
40000da1:	8b 45 10             	mov    0x10(%ebp),%eax
40000da4:	83 e0 03             	and    $0x3,%eax
40000da7:	85 c0                	test   %eax,%eax
40000da9:	75 17                	jne    40000dc2 <memmove+0xbf>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
40000dab:	8b 45 10             	mov    0x10(%ebp),%eax
40000dae:	89 c1                	mov    %eax,%ecx
40000db0:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
40000db3:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000db6:	8b 55 f0             	mov    -0x10(%ebp),%edx
40000db9:	89 c7                	mov    %eax,%edi
40000dbb:	89 d6                	mov    %edx,%esi
40000dbd:	fc                   	cld    
40000dbe:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
40000dc0:	eb 10                	jmp    40000dd2 <memmove+0xcf>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
40000dc2:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000dc5:	8b 55 f0             	mov    -0x10(%ebp),%edx
40000dc8:	8b 4d 10             	mov    0x10(%ebp),%ecx
40000dcb:	89 c7                	mov    %eax,%edi
40000dcd:	89 d6                	mov    %edx,%esi
40000dcf:	fc                   	cld    
40000dd0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
40000dd2:	8b 45 08             	mov    0x8(%ebp),%eax
}
40000dd5:	83 c4 10             	add    $0x10,%esp
40000dd8:	5b                   	pop    %ebx
40000dd9:	5e                   	pop    %esi
40000dda:	5f                   	pop    %edi
40000ddb:	5d                   	pop    %ebp
40000ddc:	c3                   	ret    

40000ddd <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
40000ddd:	55                   	push   %ebp
40000dde:	89 e5                	mov    %esp,%ebp
40000de0:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
40000de3:	8b 45 10             	mov    0x10(%ebp),%eax
40000de6:	89 44 24 08          	mov    %eax,0x8(%esp)
40000dea:	8b 45 0c             	mov    0xc(%ebp),%eax
40000ded:	89 44 24 04          	mov    %eax,0x4(%esp)
40000df1:	8b 45 08             	mov    0x8(%ebp),%eax
40000df4:	89 04 24             	mov    %eax,(%esp)
40000df7:	e8 07 ff ff ff       	call   40000d03 <memmove>
}
40000dfc:	c9                   	leave  
40000dfd:	c3                   	ret    

40000dfe <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
40000dfe:	55                   	push   %ebp
40000dff:	89 e5                	mov    %esp,%ebp
40000e01:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
40000e04:	8b 45 08             	mov    0x8(%ebp),%eax
40000e07:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
40000e0a:	8b 45 0c             	mov    0xc(%ebp),%eax
40000e0d:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
40000e10:	eb 32                	jmp    40000e44 <memcmp+0x46>
		if (*s1 != *s2)
40000e12:	8b 45 fc             	mov    -0x4(%ebp),%eax
40000e15:	0f b6 10             	movzbl (%eax),%edx
40000e18:	8b 45 f8             	mov    -0x8(%ebp),%eax
40000e1b:	0f b6 00             	movzbl (%eax),%eax
40000e1e:	38 c2                	cmp    %al,%dl
40000e20:	74 1a                	je     40000e3c <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
40000e22:	8b 45 fc             	mov    -0x4(%ebp),%eax
40000e25:	0f b6 00             	movzbl (%eax),%eax
40000e28:	0f b6 d0             	movzbl %al,%edx
40000e2b:	8b 45 f8             	mov    -0x8(%ebp),%eax
40000e2e:	0f b6 00             	movzbl (%eax),%eax
40000e31:	0f b6 c0             	movzbl %al,%eax
40000e34:	89 d1                	mov    %edx,%ecx
40000e36:	29 c1                	sub    %eax,%ecx
40000e38:	89 c8                	mov    %ecx,%eax
40000e3a:	eb 1c                	jmp    40000e58 <memcmp+0x5a>
		s1++, s2++;
40000e3c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40000e40:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
40000e44:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000e48:	0f 95 c0             	setne  %al
40000e4b:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40000e4f:	84 c0                	test   %al,%al
40000e51:	75 bf                	jne    40000e12 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
40000e53:	b8 00 00 00 00       	mov    $0x0,%eax
}
40000e58:	c9                   	leave  
40000e59:	c3                   	ret    

40000e5a <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
40000e5a:	55                   	push   %ebp
40000e5b:	89 e5                	mov    %esp,%ebp
40000e5d:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
40000e60:	8b 45 10             	mov    0x10(%ebp),%eax
40000e63:	8b 55 08             	mov    0x8(%ebp),%edx
40000e66:	01 d0                	add    %edx,%eax
40000e68:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
40000e6b:	eb 16                	jmp    40000e83 <memchr+0x29>
		if (*(const unsigned char *) s == (unsigned char) c)
40000e6d:	8b 45 08             	mov    0x8(%ebp),%eax
40000e70:	0f b6 10             	movzbl (%eax),%edx
40000e73:	8b 45 0c             	mov    0xc(%ebp),%eax
40000e76:	38 c2                	cmp    %al,%dl
40000e78:	75 05                	jne    40000e7f <memchr+0x25>
			return (void *) s;
40000e7a:	8b 45 08             	mov    0x8(%ebp),%eax
40000e7d:	eb 11                	jmp    40000e90 <memchr+0x36>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
40000e7f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000e83:	8b 45 08             	mov    0x8(%ebp),%eax
40000e86:	3b 45 fc             	cmp    -0x4(%ebp),%eax
40000e89:	72 e2                	jb     40000e6d <memchr+0x13>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
40000e8b:	b8 00 00 00 00       	mov    $0x0,%eax
}
40000e90:	c9                   	leave  
40000e91:	c3                   	ret    
40000e92:	66 90                	xchg   %ax,%ax

40000e94 <fileino_alloc>:

// Find and return the index of a currently unused file inode in this process.
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_alloc(void)
{
40000e94:	55                   	push   %ebp
40000e95:	89 e5                	mov    %esp,%ebp
40000e97:	83 ec 28             	sub    $0x28,%esp
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40000e9a:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
40000ea1:	eb 24                	jmp    40000ec7 <fileino_alloc+0x33>
		if (files->fi[i].de.d_name[0] == 0)
40000ea3:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40000ea9:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000eac:	6b c0 5c             	imul   $0x5c,%eax,%eax
40000eaf:	01 d0                	add    %edx,%eax
40000eb1:	05 10 10 00 00       	add    $0x1010,%eax
40000eb6:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40000eba:	84 c0                	test   %al,%al
40000ebc:	75 05                	jne    40000ec3 <fileino_alloc+0x2f>
			return i;
40000ebe:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000ec1:	eb 39                	jmp    40000efc <fileino_alloc+0x68>
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_alloc(void)
{
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40000ec3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40000ec7:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
40000ece:	7e d3                	jle    40000ea3 <fileino_alloc+0xf>
		if (files->fi[i].de.d_name[0] == 0)
			return i;

	warn("fileino_alloc: no free inodes\n");
40000ed0:	c7 44 24 08 50 3c 00 	movl   $0x40003c50,0x8(%esp)
40000ed7:	40 
40000ed8:	c7 44 24 04 29 00 00 	movl   $0x29,0x4(%esp)
40000edf:	00 
40000ee0:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40000ee7:	e8 c2 20 00 00       	call   40002fae <debug_warn>
	errno = ENOSPC;
40000eec:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40000ef1:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
	return -1;
40000ef7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
40000efc:	c9                   	leave  
40000efd:	c3                   	ret    

40000efe <fileino_create>:
// Returns the index of the inode found or created.
// A newly-created inode is left in the "deleted" state, with mode == 0.
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_create(filestate *fs, int dino, const char *name)
{
40000efe:	55                   	push   %ebp
40000eff:	89 e5                	mov    %esp,%ebp
40000f01:	83 ec 28             	sub    $0x28,%esp
	assert(dino != 0);
40000f04:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40000f08:	75 24                	jne    40000f2e <fileino_create+0x30>
40000f0a:	c7 44 24 0c 7a 3c 00 	movl   $0x40003c7a,0xc(%esp)
40000f11:	40 
40000f12:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40000f19:	40 
40000f1a:	c7 44 24 04 35 00 00 	movl   $0x35,0x4(%esp)
40000f21:	00 
40000f22:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40000f29:	e8 16 20 00 00       	call   40002f44 <debug_panic>
	assert(name != NULL && name[0] != 0);
40000f2e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000f32:	74 0a                	je     40000f3e <fileino_create+0x40>
40000f34:	8b 45 10             	mov    0x10(%ebp),%eax
40000f37:	0f b6 00             	movzbl (%eax),%eax
40000f3a:	84 c0                	test   %al,%al
40000f3c:	75 24                	jne    40000f62 <fileino_create+0x64>
40000f3e:	c7 44 24 0c 99 3c 00 	movl   $0x40003c99,0xc(%esp)
40000f45:	40 
40000f46:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40000f4d:	40 
40000f4e:	c7 44 24 04 36 00 00 	movl   $0x36,0x4(%esp)
40000f55:	00 
40000f56:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40000f5d:	e8 e2 1f 00 00       	call   40002f44 <debug_panic>
	assert(strlen(name) <= NAME_MAX);
40000f62:	8b 45 10             	mov    0x10(%ebp),%eax
40000f65:	89 04 24             	mov    %eax,(%esp)
40000f68:	e8 6b fb ff ff       	call   40000ad8 <strlen>
40000f6d:	83 f8 3f             	cmp    $0x3f,%eax
40000f70:	7e 24                	jle    40000f96 <fileino_create+0x98>
40000f72:	c7 44 24 0c b6 3c 00 	movl   $0x40003cb6,0xc(%esp)
40000f79:	40 
40000f7a:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40000f81:	40 
40000f82:	c7 44 24 04 37 00 00 	movl   $0x37,0x4(%esp)
40000f89:	00 
40000f8a:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40000f91:	e8 ae 1f 00 00       	call   40002f44 <debug_panic>

	// First see if an inode already exists for this directory and name.
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40000f96:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
40000f9d:	eb 4a                	jmp    40000fe9 <fileino_create+0xeb>
		if (fs->fi[i].dino == dino
40000f9f:	8b 55 08             	mov    0x8(%ebp),%edx
40000fa2:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000fa5:	6b c0 5c             	imul   $0x5c,%eax,%eax
40000fa8:	01 d0                	add    %edx,%eax
40000faa:	05 10 10 00 00       	add    $0x1010,%eax
40000faf:	8b 00                	mov    (%eax),%eax
40000fb1:	3b 45 0c             	cmp    0xc(%ebp),%eax
40000fb4:	75 2f                	jne    40000fe5 <fileino_create+0xe7>
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
40000fb6:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000fb9:	6b c0 5c             	imul   $0x5c,%eax,%eax
40000fbc:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40000fc2:	8b 45 08             	mov    0x8(%ebp),%eax
40000fc5:	01 d0                	add    %edx,%eax
40000fc7:	8d 50 04             	lea    0x4(%eax),%edx
40000fca:	8b 45 10             	mov    0x10(%ebp),%eax
40000fcd:	89 44 24 04          	mov    %eax,0x4(%esp)
40000fd1:	89 14 24             	mov    %edx,(%esp)
40000fd4:	e8 eb fb ff ff       	call   40000bc4 <strcmp>
40000fd9:	85 c0                	test   %eax,%eax
40000fdb:	75 08                	jne    40000fe5 <fileino_create+0xe7>
			return i;
40000fdd:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000fe0:	e9 a5 00 00 00       	jmp    4000108a <fileino_create+0x18c>
	assert(name != NULL && name[0] != 0);
	assert(strlen(name) <= NAME_MAX);

	// First see if an inode already exists for this directory and name.
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40000fe5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40000fe9:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
40000ff0:	7e ad                	jle    40000f9f <fileino_create+0xa1>
		if (fs->fi[i].dino == dino
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
			return i;

	// No inode allocated to this name - find a free one to allocate.
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40000ff2:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
40000ff9:	eb 5a                	jmp    40001055 <fileino_create+0x157>
		if (fs->fi[i].de.d_name[0] == 0) {
40000ffb:	8b 55 08             	mov    0x8(%ebp),%edx
40000ffe:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001001:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001004:	01 d0                	add    %edx,%eax
40001006:	05 10 10 00 00       	add    $0x1010,%eax
4000100b:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000100f:	84 c0                	test   %al,%al
40001011:	75 3e                	jne    40001051 <fileino_create+0x153>
			fs->fi[i].dino = dino;
40001013:	8b 55 08             	mov    0x8(%ebp),%edx
40001016:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001019:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000101c:	01 d0                	add    %edx,%eax
4000101e:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40001024:	8b 45 0c             	mov    0xc(%ebp),%eax
40001027:	89 02                	mov    %eax,(%edx)
			strcpy(fs->fi[i].de.d_name, name);
40001029:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000102c:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000102f:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40001035:	8b 45 08             	mov    0x8(%ebp),%eax
40001038:	01 d0                	add    %edx,%eax
4000103a:	8d 50 04             	lea    0x4(%eax),%edx
4000103d:	8b 45 10             	mov    0x10(%ebp),%eax
40001040:	89 44 24 04          	mov    %eax,0x4(%esp)
40001044:	89 14 24             	mov    %edx,(%esp)
40001047:	e8 b2 fa ff ff       	call   40000afe <strcpy>
			return i;
4000104c:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000104f:	eb 39                	jmp    4000108a <fileino_create+0x18c>
		if (fs->fi[i].dino == dino
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
			return i;

	// No inode allocated to this name - find a free one to allocate.
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40001051:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40001055:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
4000105c:	7e 9d                	jle    40000ffb <fileino_create+0xfd>
			fs->fi[i].dino = dino;
			strcpy(fs->fi[i].de.d_name, name);
			return i;
		}

	warn("fileino_create: no free inodes\n");
4000105e:	c7 44 24 08 d0 3c 00 	movl   $0x40003cd0,0x8(%esp)
40001065:	40 
40001066:	c7 44 24 04 48 00 00 	movl   $0x48,0x4(%esp)
4000106d:	00 
4000106e:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001075:	e8 34 1f 00 00       	call   40002fae <debug_warn>
	errno = ENOSPC;
4000107a:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
4000107f:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
	return -1;
40001085:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
4000108a:	c9                   	leave  
4000108b:	c3                   	ret    

4000108c <fileino_read>:
// The number of elements returned is normally equal to the 'count' parameter,
// but may be less (without resulting in an error)
// if the file is not large enough to read that many elements.
ssize_t
fileino_read(int ino, off_t ofs, void *buf, size_t eltsize, size_t count)
{
4000108c:	55                   	push   %ebp
4000108d:	89 e5                	mov    %esp,%ebp
4000108f:	83 ec 28             	sub    $0x28,%esp
	assert(fileino_isreg(ino));
40001092:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001096:	7e 45                	jle    400010dd <fileino_read+0x51>
40001098:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
4000109f:	7f 3c                	jg     400010dd <fileino_read+0x51>
400010a1:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
400010a7:	8b 45 08             	mov    0x8(%ebp),%eax
400010aa:	6b c0 5c             	imul   $0x5c,%eax,%eax
400010ad:	01 d0                	add    %edx,%eax
400010af:	05 10 10 00 00       	add    $0x1010,%eax
400010b4:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400010b8:	84 c0                	test   %al,%al
400010ba:	74 21                	je     400010dd <fileino_read+0x51>
400010bc:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
400010c2:	8b 45 08             	mov    0x8(%ebp),%eax
400010c5:	6b c0 5c             	imul   $0x5c,%eax,%eax
400010c8:	01 d0                	add    %edx,%eax
400010ca:	05 58 10 00 00       	add    $0x1058,%eax
400010cf:	8b 00                	mov    (%eax),%eax
400010d1:	25 00 70 00 00       	and    $0x7000,%eax
400010d6:	3d 00 10 00 00       	cmp    $0x1000,%eax
400010db:	74 24                	je     40001101 <fileino_read+0x75>
400010dd:	c7 44 24 0c f0 3c 00 	movl   $0x40003cf0,0xc(%esp)
400010e4:	40 
400010e5:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
400010ec:	40 
400010ed:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
400010f4:	00 
400010f5:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
400010fc:	e8 43 1e 00 00       	call   40002f44 <debug_panic>
	assert(ofs >= 0);
40001101:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40001105:	79 24                	jns    4000112b <fileino_read+0x9f>
40001107:	c7 44 24 0c 03 3d 00 	movl   $0x40003d03,0xc(%esp)
4000110e:	40 
4000110f:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40001116:	40 
40001117:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
4000111e:	00 
4000111f:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001126:	e8 19 1e 00 00       	call   40002f44 <debug_panic>
	assert(eltsize > 0);
4000112b:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
4000112f:	75 24                	jne    40001155 <fileino_read+0xc9>
40001131:	c7 44 24 0c 0c 3d 00 	movl   $0x40003d0c,0xc(%esp)
40001138:	40 
40001139:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40001140:	40 
40001141:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
40001148:	00 
40001149:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001150:	e8 ef 1d 00 00       	call   40002f44 <debug_panic>

	ssize_t return_number = 0;
40001155:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	fileinode *fi = &files->fi[ino];
4000115c:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001161:	8b 55 08             	mov    0x8(%ebp),%edx
40001164:	6b d2 5c             	imul   $0x5c,%edx,%edx
40001167:	81 c2 10 10 00 00    	add    $0x1010,%edx
4000116d:	01 d0                	add    %edx,%eax
4000116f:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint32_t tmp_ofs = ofs;
40001172:	8b 45 0c             	mov    0xc(%ebp),%eax
40001175:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint8_t* read_pointer = FILEDATA(ino) + ofs;
40001178:	8b 45 08             	mov    0x8(%ebp),%eax
4000117b:	c1 e0 16             	shl    $0x16,%eax
4000117e:	89 c2                	mov    %eax,%edx
40001180:	8b 45 0c             	mov    0xc(%ebp),%eax
40001183:	01 d0                	add    %edx,%eax
40001185:	05 00 00 00 80       	add    $0x80000000,%eax
4000118a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(fi->size <= FILE_MAXSIZE);
4000118d:	8b 45 e8             	mov    -0x18(%ebp),%eax
40001190:	8b 40 4c             	mov    0x4c(%eax),%eax
40001193:	3d 00 00 40 00       	cmp    $0x400000,%eax
40001198:	76 7a                	jbe    40001214 <fileino_read+0x188>
4000119a:	c7 44 24 0c 18 3d 00 	movl   $0x40003d18,0xc(%esp)
400011a1:	40 
400011a2:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
400011a9:	40 
400011aa:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
400011b1:	00 
400011b2:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
400011b9:	e8 86 1d 00 00       	call   40002f44 <debug_panic>
	// Lab 4: insert your file reading code here.
	//warn("fileino_read() not implemented");
	while(count > 0){
		if(tmp_ofs >= fi->size){
400011be:	8b 45 e8             	mov    -0x18(%ebp),%eax
400011c1:	8b 40 4c             	mov    0x4c(%eax),%eax
400011c4:	3b 45 f0             	cmp    -0x10(%ebp),%eax
400011c7:	77 18                	ja     400011e1 <fileino_read+0x155>
			if(fi->mode & S_IFPART)
400011c9:	8b 45 e8             	mov    -0x18(%ebp),%eax
400011cc:	8b 40 48             	mov    0x48(%eax),%eax
400011cf:	25 00 80 00 00       	and    $0x8000,%eax
400011d4:	85 c0                	test   %eax,%eax
400011d6:	74 44                	je     4000121c <fileino_read+0x190>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400011d8:	b8 03 00 00 00       	mov    $0x3,%eax
400011dd:	cd 30                	int    $0x30
400011df:	eb 33                	jmp    40001214 <fileino_read+0x188>
				sys_ret();
			else
				break;
		}else{
			memcpy(buf, read_pointer, eltsize);
400011e1:	8b 45 14             	mov    0x14(%ebp),%eax
400011e4:	89 44 24 08          	mov    %eax,0x8(%esp)
400011e8:	8b 45 ec             	mov    -0x14(%ebp),%eax
400011eb:	89 44 24 04          	mov    %eax,0x4(%esp)
400011ef:	8b 45 10             	mov    0x10(%ebp),%eax
400011f2:	89 04 24             	mov    %eax,(%esp)
400011f5:	e8 e3 fb ff ff       	call   40000ddd <memcpy>
			return_number++;
400011fa:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
			buf += eltsize;
400011fe:	8b 45 14             	mov    0x14(%ebp),%eax
40001201:	01 45 10             	add    %eax,0x10(%ebp)
			read_pointer += eltsize;
40001204:	8b 45 14             	mov    0x14(%ebp),%eax
40001207:	01 45 ec             	add    %eax,-0x14(%ebp)
			tmp_ofs += eltsize;
4000120a:	8b 45 14             	mov    0x14(%ebp),%eax
4000120d:	01 45 f0             	add    %eax,-0x10(%ebp)
			count--;
40001210:	83 6d 18 01          	subl   $0x1,0x18(%ebp)
	uint32_t tmp_ofs = ofs;
	uint8_t* read_pointer = FILEDATA(ino) + ofs;
	assert(fi->size <= FILE_MAXSIZE);
	// Lab 4: insert your file reading code here.
	//warn("fileino_read() not implemented");
	while(count > 0){
40001214:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
40001218:	75 a4                	jne    400011be <fileino_read+0x132>
4000121a:	eb 01                	jmp    4000121d <fileino_read+0x191>
		if(tmp_ofs >= fi->size){
			if(fi->mode & S_IFPART)
				sys_ret();
			else
				break;
4000121c:	90                   	nop
			read_pointer += eltsize;
			tmp_ofs += eltsize;
			count--;
		}
	}
	return return_number;
4000121d:	8b 45 f4             	mov    -0xc(%ebp),%eax
//	errno = EINVAL;
//	return -1;
}
40001220:	c9                   	leave  
40001221:	c3                   	ret    

40001222 <fileino_write>:
// one particular reason an error might occur is if an application
// tries to grow a file beyond this maximum file size,
// in which case this function generates the EFBIG error.
ssize_t
fileino_write(int ino, off_t ofs, const void *buf, size_t eltsize, size_t count)
{
40001222:	55                   	push   %ebp
40001223:	89 e5                	mov    %esp,%ebp
40001225:	57                   	push   %edi
40001226:	56                   	push   %esi
40001227:	53                   	push   %ebx
40001228:	83 ec 6c             	sub    $0x6c,%esp
	assert(fileino_isreg(ino));
4000122b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
4000122f:	7e 45                	jle    40001276 <fileino_write+0x54>
40001231:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40001238:	7f 3c                	jg     40001276 <fileino_write+0x54>
4000123a:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40001240:	8b 45 08             	mov    0x8(%ebp),%eax
40001243:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001246:	01 d0                	add    %edx,%eax
40001248:	05 10 10 00 00       	add    $0x1010,%eax
4000124d:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40001251:	84 c0                	test   %al,%al
40001253:	74 21                	je     40001276 <fileino_write+0x54>
40001255:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
4000125b:	8b 45 08             	mov    0x8(%ebp),%eax
4000125e:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001261:	01 d0                	add    %edx,%eax
40001263:	05 58 10 00 00       	add    $0x1058,%eax
40001268:	8b 00                	mov    (%eax),%eax
4000126a:	25 00 70 00 00       	and    $0x7000,%eax
4000126f:	3d 00 10 00 00       	cmp    $0x1000,%eax
40001274:	74 24                	je     4000129a <fileino_write+0x78>
40001276:	c7 44 24 0c f0 3c 00 	movl   $0x40003cf0,0xc(%esp)
4000127d:	40 
4000127e:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40001285:	40 
40001286:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
4000128d:	00 
4000128e:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001295:	e8 aa 1c 00 00       	call   40002f44 <debug_panic>
	assert(ofs >= 0);
4000129a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
4000129e:	79 24                	jns    400012c4 <fileino_write+0xa2>
400012a0:	c7 44 24 0c 03 3d 00 	movl   $0x40003d03,0xc(%esp)
400012a7:	40 
400012a8:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
400012af:	40 
400012b0:	c7 44 24 04 84 00 00 	movl   $0x84,0x4(%esp)
400012b7:	00 
400012b8:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
400012bf:	e8 80 1c 00 00       	call   40002f44 <debug_panic>
	assert(eltsize > 0);
400012c4:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
400012c8:	75 24                	jne    400012ee <fileino_write+0xcc>
400012ca:	c7 44 24 0c 0c 3d 00 	movl   $0x40003d0c,0xc(%esp)
400012d1:	40 
400012d2:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
400012d9:	40 
400012da:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
400012e1:	00 
400012e2:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
400012e9:	e8 56 1c 00 00       	call   40002f44 <debug_panic>

	int i = 0;
400012ee:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	ssize_t return_number = 0;
400012f5:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	fileinode *fi = &files->fi[ino];
400012fc:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001301:	8b 55 08             	mov    0x8(%ebp),%edx
40001304:	6b d2 5c             	imul   $0x5c,%edx,%edx
40001307:	81 c2 10 10 00 00    	add    $0x1010,%edx
4000130d:	01 d0                	add    %edx,%eax
4000130f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	assert(fi->size <= FILE_MAXSIZE);
40001312:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001315:	8b 40 4c             	mov    0x4c(%eax),%eax
40001318:	3d 00 00 40 00       	cmp    $0x400000,%eax
4000131d:	76 24                	jbe    40001343 <fileino_write+0x121>
4000131f:	c7 44 24 0c 18 3d 00 	movl   $0x40003d18,0xc(%esp)
40001326:	40 
40001327:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
4000132e:	40 
4000132f:	c7 44 24 04 8a 00 00 	movl   $0x8a,0x4(%esp)
40001336:	00 
40001337:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
4000133e:	e8 01 1c 00 00       	call   40002f44 <debug_panic>
	uint8_t* write_start = FILEDATA(ino) + ofs;
40001343:	8b 45 08             	mov    0x8(%ebp),%eax
40001346:	c1 e0 16             	shl    $0x16,%eax
40001349:	89 c2                	mov    %eax,%edx
4000134b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000134e:	01 d0                	add    %edx,%eax
40001350:	05 00 00 00 80       	add    $0x80000000,%eax
40001355:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	uint8_t* write_pointer = write_start;
40001358:	8b 45 d4             	mov    -0x2c(%ebp),%eax
4000135b:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uint32_t after_write_size = ofs + eltsize * count;
4000135e:	8b 45 14             	mov    0x14(%ebp),%eax
40001361:	89 c2                	mov    %eax,%edx
40001363:	0f af 55 18          	imul   0x18(%ebp),%edx
40001367:	8b 45 0c             	mov    0xc(%ebp),%eax
4000136a:	01 d0                	add    %edx,%eax
4000136c:	89 45 d0             	mov    %eax,-0x30(%ebp)

	if(after_write_size > FILE_MAXSIZE){
4000136f:	81 7d d0 00 00 40 00 	cmpl   $0x400000,-0x30(%ebp)
40001376:	76 15                	jbe    4000138d <fileino_write+0x16b>
		errno = EFBIG;
40001378:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
4000137d:	c7 00 03 00 00 00    	movl   $0x3,(%eax)
		return -1;
40001383:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40001388:	e9 28 01 00 00       	jmp    400014b5 <fileino_write+0x293>
	}
	if(after_write_size > fi->size){
4000138d:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001390:	8b 40 4c             	mov    0x4c(%eax),%eax
40001393:	3b 45 d0             	cmp    -0x30(%ebp),%eax
40001396:	0f 83 0d 01 00 00    	jae    400014a9 <fileino_write+0x287>
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
4000139c:	c7 45 cc 00 10 00 00 	movl   $0x1000,-0x34(%ebp)
400013a3:	8b 45 cc             	mov    -0x34(%ebp),%eax
400013a6:	8b 55 d0             	mov    -0x30(%ebp),%edx
400013a9:	01 d0                	add    %edx,%eax
400013ab:	83 e8 01             	sub    $0x1,%eax
400013ae:	89 45 c8             	mov    %eax,-0x38(%ebp)
400013b1:	8b 45 c8             	mov    -0x38(%ebp),%eax
400013b4:	ba 00 00 00 00       	mov    $0x0,%edx
400013b9:	f7 75 cc             	divl   -0x34(%ebp)
400013bc:	89 d0                	mov    %edx,%eax
400013be:	8b 55 c8             	mov    -0x38(%ebp),%edx
400013c1:	89 d1                	mov    %edx,%ecx
400013c3:	29 c1                	sub    %eax,%ecx
400013c5:	89 c8                	mov    %ecx,%eax
400013c7:	89 c1                	mov    %eax,%ecx
400013c9:	c7 45 c4 00 10 00 00 	movl   $0x1000,-0x3c(%ebp)
400013d0:	8b 45 d8             	mov    -0x28(%ebp),%eax
400013d3:	8b 50 4c             	mov    0x4c(%eax),%edx
400013d6:	8b 45 c4             	mov    -0x3c(%ebp),%eax
400013d9:	01 d0                	add    %edx,%eax
400013db:	83 e8 01             	sub    $0x1,%eax
400013de:	89 45 c0             	mov    %eax,-0x40(%ebp)
400013e1:	8b 45 c0             	mov    -0x40(%ebp),%eax
400013e4:	ba 00 00 00 00       	mov    $0x0,%edx
400013e9:	f7 75 c4             	divl   -0x3c(%ebp)
400013ec:	89 d0                	mov    %edx,%eax
400013ee:	8b 55 c0             	mov    -0x40(%ebp),%edx
400013f1:	89 d3                	mov    %edx,%ebx
400013f3:	29 c3                	sub    %eax,%ebx
400013f5:	89 d8                	mov    %ebx,%eax
	if(after_write_size > FILE_MAXSIZE){
		errno = EFBIG;
		return -1;
	}
	if(after_write_size > fi->size){
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
400013f7:	29 c1                	sub    %eax,%ecx
400013f9:	8b 45 08             	mov    0x8(%ebp),%eax
400013fc:	c1 e0 16             	shl    $0x16,%eax
400013ff:	89 c3                	mov    %eax,%ebx
40001401:	c7 45 bc 00 10 00 00 	movl   $0x1000,-0x44(%ebp)
40001408:	8b 45 d8             	mov    -0x28(%ebp),%eax
4000140b:	8b 50 4c             	mov    0x4c(%eax),%edx
4000140e:	8b 45 bc             	mov    -0x44(%ebp),%eax
40001411:	01 d0                	add    %edx,%eax
40001413:	83 e8 01             	sub    $0x1,%eax
40001416:	89 45 b8             	mov    %eax,-0x48(%ebp)
40001419:	8b 45 b8             	mov    -0x48(%ebp),%eax
4000141c:	ba 00 00 00 00       	mov    $0x0,%edx
40001421:	f7 75 bc             	divl   -0x44(%ebp)
40001424:	89 d0                	mov    %edx,%eax
40001426:	8b 55 b8             	mov    -0x48(%ebp),%edx
40001429:	89 d6                	mov    %edx,%esi
4000142b:	29 c6                	sub    %eax,%esi
4000142d:	89 f0                	mov    %esi,%eax
4000142f:	01 d8                	add    %ebx,%eax
40001431:	05 00 00 00 80       	add    $0x80000000,%eax
40001436:	c7 45 b4 00 07 00 00 	movl   $0x700,-0x4c(%ebp)
4000143d:	66 c7 45 b2 00 00    	movw   $0x0,-0x4e(%ebp)
40001443:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
4000144a:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
40001451:	89 45 a4             	mov    %eax,-0x5c(%ebp)
40001454:	89 4d a0             	mov    %ecx,-0x60(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001457:	8b 45 b4             	mov    -0x4c(%ebp),%eax
4000145a:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000145d:	8b 5d ac             	mov    -0x54(%ebp),%ebx
40001460:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
40001464:	8b 75 a8             	mov    -0x58(%ebp),%esi
40001467:	8b 7d a4             	mov    -0x5c(%ebp),%edi
4000146a:	8b 4d a0             	mov    -0x60(%ebp),%ecx
4000146d:	cd 30                	int    $0x30
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
		fi->size = after_write_size;
4000146f:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001472:	8b 55 d0             	mov    -0x30(%ebp),%edx
40001475:	89 50 4c             	mov    %edx,0x4c(%eax)
	}
	for(i; i < count; i++){
40001478:	eb 2f                	jmp    400014a9 <fileino_write+0x287>
		memcpy(write_pointer, buf, eltsize);
4000147a:	8b 45 14             	mov    0x14(%ebp),%eax
4000147d:	89 44 24 08          	mov    %eax,0x8(%esp)
40001481:	8b 45 10             	mov    0x10(%ebp),%eax
40001484:	89 44 24 04          	mov    %eax,0x4(%esp)
40001488:	8b 45 dc             	mov    -0x24(%ebp),%eax
4000148b:	89 04 24             	mov    %eax,(%esp)
4000148e:	e8 4a f9 ff ff       	call   40000ddd <memcpy>
		return_number++;
40001493:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
		buf += eltsize;
40001497:	8b 45 14             	mov    0x14(%ebp),%eax
4000149a:	01 45 10             	add    %eax,0x10(%ebp)
		write_pointer += eltsize;
4000149d:	8b 45 14             	mov    0x14(%ebp),%eax
400014a0:	01 45 dc             	add    %eax,-0x24(%ebp)
	if(after_write_size > fi->size){
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
		fi->size = after_write_size;
	}
	for(i; i < count; i++){
400014a3:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
400014a7:	eb 01                	jmp    400014aa <fileino_write+0x288>
400014a9:	90                   	nop
400014aa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400014ad:	3b 45 18             	cmp    0x18(%ebp),%eax
400014b0:	72 c8                	jb     4000147a <fileino_write+0x258>
		memcpy(write_pointer, buf, eltsize);
		return_number++;
		buf += eltsize;
		write_pointer += eltsize;
	}
	return return_number;
400014b2:	8b 45 e0             	mov    -0x20(%ebp),%eax

	// Lab 4: insert your file writing code here.
	//warn("fileino_write() not implemented");
	//errno = EINVAL;
	//return -1;
}
400014b5:	83 c4 6c             	add    $0x6c,%esp
400014b8:	5b                   	pop    %ebx
400014b9:	5e                   	pop    %esi
400014ba:	5f                   	pop    %edi
400014bb:	5d                   	pop    %ebp
400014bc:	c3                   	ret    

400014bd <fileino_stat>:
// Return file statistics about a particular inode.
// The specified inode must indicate a file that exists,
// but it can be any type of object: e.g., file, directory, special file, etc.
int
fileino_stat(int ino, struct stat *st)
{
400014bd:	55                   	push   %ebp
400014be:	89 e5                	mov    %esp,%ebp
400014c0:	83 ec 28             	sub    $0x28,%esp
	assert(fileino_exists(ino));
400014c3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400014c7:	7e 3d                	jle    40001506 <fileino_stat+0x49>
400014c9:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
400014d0:	7f 34                	jg     40001506 <fileino_stat+0x49>
400014d2:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
400014d8:	8b 45 08             	mov    0x8(%ebp),%eax
400014db:	6b c0 5c             	imul   $0x5c,%eax,%eax
400014de:	01 d0                	add    %edx,%eax
400014e0:	05 10 10 00 00       	add    $0x1010,%eax
400014e5:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400014e9:	84 c0                	test   %al,%al
400014eb:	74 19                	je     40001506 <fileino_stat+0x49>
400014ed:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
400014f3:	8b 45 08             	mov    0x8(%ebp),%eax
400014f6:	6b c0 5c             	imul   $0x5c,%eax,%eax
400014f9:	01 d0                	add    %edx,%eax
400014fb:	05 58 10 00 00       	add    $0x1058,%eax
40001500:	8b 00                	mov    (%eax),%eax
40001502:	85 c0                	test   %eax,%eax
40001504:	75 24                	jne    4000152a <fileino_stat+0x6d>
40001506:	c7 44 24 0c 31 3d 00 	movl   $0x40003d31,0xc(%esp)
4000150d:	40 
4000150e:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40001515:	40 
40001516:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
4000151d:	00 
4000151e:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001525:	e8 1a 1a 00 00       	call   40002f44 <debug_panic>

	fileinode *fi = &files->fi[ino];
4000152a:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
4000152f:	8b 55 08             	mov    0x8(%ebp),%edx
40001532:	6b d2 5c             	imul   $0x5c,%edx,%edx
40001535:	81 c2 10 10 00 00    	add    $0x1010,%edx
4000153b:	01 d0                	add    %edx,%eax
4000153d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert(fileino_isdir(fi->dino));	// Should be in a directory!
40001540:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001543:	8b 00                	mov    (%eax),%eax
40001545:	85 c0                	test   %eax,%eax
40001547:	7e 4c                	jle    40001595 <fileino_stat+0xd8>
40001549:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000154c:	8b 00                	mov    (%eax),%eax
4000154e:	3d ff 00 00 00       	cmp    $0xff,%eax
40001553:	7f 40                	jg     40001595 <fileino_stat+0xd8>
40001555:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
4000155b:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000155e:	8b 00                	mov    (%eax),%eax
40001560:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001563:	01 d0                	add    %edx,%eax
40001565:	05 10 10 00 00       	add    $0x1010,%eax
4000156a:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000156e:	84 c0                	test   %al,%al
40001570:	74 23                	je     40001595 <fileino_stat+0xd8>
40001572:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40001578:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000157b:	8b 00                	mov    (%eax),%eax
4000157d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001580:	01 d0                	add    %edx,%eax
40001582:	05 58 10 00 00       	add    $0x1058,%eax
40001587:	8b 00                	mov    (%eax),%eax
40001589:	25 00 70 00 00       	and    $0x7000,%eax
4000158e:	3d 00 20 00 00       	cmp    $0x2000,%eax
40001593:	74 24                	je     400015b9 <fileino_stat+0xfc>
40001595:	c7 44 24 0c 45 3d 00 	movl   $0x40003d45,0xc(%esp)
4000159c:	40 
4000159d:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
400015a4:	40 
400015a5:	c7 44 24 04 af 00 00 	movl   $0xaf,0x4(%esp)
400015ac:	00 
400015ad:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
400015b4:	e8 8b 19 00 00       	call   40002f44 <debug_panic>
	st->st_ino = ino;
400015b9:	8b 45 0c             	mov    0xc(%ebp),%eax
400015bc:	8b 55 08             	mov    0x8(%ebp),%edx
400015bf:	89 10                	mov    %edx,(%eax)
	st->st_mode = fi->mode;
400015c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
400015c4:	8b 50 48             	mov    0x48(%eax),%edx
400015c7:	8b 45 0c             	mov    0xc(%ebp),%eax
400015ca:	89 50 04             	mov    %edx,0x4(%eax)
	st->st_size = fi->size;
400015cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
400015d0:	8b 40 4c             	mov    0x4c(%eax),%eax
400015d3:	89 c2                	mov    %eax,%edx
400015d5:	8b 45 0c             	mov    0xc(%ebp),%eax
400015d8:	89 50 08             	mov    %edx,0x8(%eax)

	return 0;
400015db:	b8 00 00 00 00       	mov    $0x0,%eax
}
400015e0:	c9                   	leave  
400015e1:	c3                   	ret    

400015e2 <fileino_truncate>:
// Grow or shrink a file to exactly a specified size.
// If growing a file, then fills the new space with zeros.
// Returns 0 if successful, or returns -1 and sets errno on error.
int
fileino_truncate(int ino, off_t newsize)
{
400015e2:	55                   	push   %ebp
400015e3:	89 e5                	mov    %esp,%ebp
400015e5:	57                   	push   %edi
400015e6:	56                   	push   %esi
400015e7:	53                   	push   %ebx
400015e8:	81 ec 8c 00 00 00    	sub    $0x8c,%esp
	assert(fileino_isvalid(ino));
400015ee:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400015f2:	7e 09                	jle    400015fd <fileino_truncate+0x1b>
400015f4:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
400015fb:	7e 24                	jle    40001621 <fileino_truncate+0x3f>
400015fd:	c7 44 24 0c 5d 3d 00 	movl   $0x40003d5d,0xc(%esp)
40001604:	40 
40001605:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
4000160c:	40 
4000160d:	c7 44 24 04 bd 00 00 	movl   $0xbd,0x4(%esp)
40001614:	00 
40001615:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
4000161c:	e8 23 19 00 00       	call   40002f44 <debug_panic>
	assert(newsize >= 0 && newsize <= FILE_MAXSIZE);
40001621:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40001625:	78 09                	js     40001630 <fileino_truncate+0x4e>
40001627:	81 7d 0c 00 00 40 00 	cmpl   $0x400000,0xc(%ebp)
4000162e:	7e 24                	jle    40001654 <fileino_truncate+0x72>
40001630:	c7 44 24 0c 74 3d 00 	movl   $0x40003d74,0xc(%esp)
40001637:	40 
40001638:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
4000163f:	40 
40001640:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
40001647:	00 
40001648:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
4000164f:	e8 f0 18 00 00       	call   40002f44 <debug_panic>

	size_t oldsize = files->fi[ino].size;
40001654:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
4000165a:	8b 45 08             	mov    0x8(%ebp),%eax
4000165d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001660:	01 d0                	add    %edx,%eax
40001662:	05 5c 10 00 00       	add    $0x105c,%eax
40001667:	8b 00                	mov    (%eax),%eax
40001669:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	size_t oldpagelim = ROUNDUP(files->fi[ino].size, PAGESIZE);
4000166c:	c7 45 e0 00 10 00 00 	movl   $0x1000,-0x20(%ebp)
40001673:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40001679:	8b 45 08             	mov    0x8(%ebp),%eax
4000167c:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000167f:	01 d0                	add    %edx,%eax
40001681:	05 5c 10 00 00       	add    $0x105c,%eax
40001686:	8b 10                	mov    (%eax),%edx
40001688:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000168b:	01 d0                	add    %edx,%eax
4000168d:	83 e8 01             	sub    $0x1,%eax
40001690:	89 45 dc             	mov    %eax,-0x24(%ebp)
40001693:	8b 45 dc             	mov    -0x24(%ebp),%eax
40001696:	ba 00 00 00 00       	mov    $0x0,%edx
4000169b:	f7 75 e0             	divl   -0x20(%ebp)
4000169e:	89 d0                	mov    %edx,%eax
400016a0:	8b 55 dc             	mov    -0x24(%ebp),%edx
400016a3:	89 d1                	mov    %edx,%ecx
400016a5:	29 c1                	sub    %eax,%ecx
400016a7:	89 c8                	mov    %ecx,%eax
400016a9:	89 45 d8             	mov    %eax,-0x28(%ebp)
	size_t newpagelim = ROUNDUP(newsize, PAGESIZE);
400016ac:	c7 45 d4 00 10 00 00 	movl   $0x1000,-0x2c(%ebp)
400016b3:	8b 55 0c             	mov    0xc(%ebp),%edx
400016b6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
400016b9:	01 d0                	add    %edx,%eax
400016bb:	83 e8 01             	sub    $0x1,%eax
400016be:	89 45 d0             	mov    %eax,-0x30(%ebp)
400016c1:	8b 45 d0             	mov    -0x30(%ebp),%eax
400016c4:	ba 00 00 00 00       	mov    $0x0,%edx
400016c9:	f7 75 d4             	divl   -0x2c(%ebp)
400016cc:	89 d0                	mov    %edx,%eax
400016ce:	8b 55 d0             	mov    -0x30(%ebp),%edx
400016d1:	89 d1                	mov    %edx,%ecx
400016d3:	29 c1                	sub    %eax,%ecx
400016d5:	89 c8                	mov    %ecx,%eax
400016d7:	89 45 cc             	mov    %eax,-0x34(%ebp)
	if (newsize > oldsize) {
400016da:	8b 45 0c             	mov    0xc(%ebp),%eax
400016dd:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
400016e0:	0f 86 8a 00 00 00    	jbe    40001770 <fileino_truncate+0x18e>
		// Grow the file and fill the new space with zeros.
		sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
400016e6:	8b 45 d8             	mov    -0x28(%ebp),%eax
400016e9:	8b 55 cc             	mov    -0x34(%ebp),%edx
400016ec:	89 d1                	mov    %edx,%ecx
400016ee:	29 c1                	sub    %eax,%ecx
400016f0:	89 c8                	mov    %ecx,%eax
			FILEDATA(ino) + oldpagelim,
400016f2:	8b 55 08             	mov    0x8(%ebp),%edx
400016f5:	c1 e2 16             	shl    $0x16,%edx
400016f8:	89 d1                	mov    %edx,%ecx
400016fa:	8b 55 d8             	mov    -0x28(%ebp),%edx
400016fd:	01 ca                	add    %ecx,%edx
	size_t oldsize = files->fi[ino].size;
	size_t oldpagelim = ROUNDUP(files->fi[ino].size, PAGESIZE);
	size_t newpagelim = ROUNDUP(newsize, PAGESIZE);
	if (newsize > oldsize) {
		// Grow the file and fill the new space with zeros.
		sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
400016ff:	81 c2 00 00 00 80    	add    $0x80000000,%edx
40001705:	c7 45 c8 00 07 00 00 	movl   $0x700,-0x38(%ebp)
4000170c:	66 c7 45 c6 00 00    	movw   $0x0,-0x3a(%ebp)
40001712:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
40001719:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
40001720:	89 55 b8             	mov    %edx,-0x48(%ebp)
40001723:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001726:	8b 45 c8             	mov    -0x38(%ebp),%eax
40001729:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000172c:	8b 5d c0             	mov    -0x40(%ebp),%ebx
4000172f:	0f b7 55 c6          	movzwl -0x3a(%ebp),%edx
40001733:	8b 75 bc             	mov    -0x44(%ebp),%esi
40001736:	8b 7d b8             	mov    -0x48(%ebp),%edi
40001739:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
4000173c:	cd 30                	int    $0x30
			FILEDATA(ino) + oldpagelim,
			newpagelim - oldpagelim);
		memset(FILEDATA(ino) + oldsize, 0, newsize - oldsize);
4000173e:	8b 45 0c             	mov    0xc(%ebp),%eax
40001741:	2b 45 e4             	sub    -0x1c(%ebp),%eax
40001744:	8b 55 08             	mov    0x8(%ebp),%edx
40001747:	c1 e2 16             	shl    $0x16,%edx
4000174a:	89 d1                	mov    %edx,%ecx
4000174c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
4000174f:	01 ca                	add    %ecx,%edx
40001751:	81 c2 00 00 00 80    	add    $0x80000000,%edx
40001757:	89 44 24 08          	mov    %eax,0x8(%esp)
4000175b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001762:	00 
40001763:	89 14 24             	mov    %edx,(%esp)
40001766:	e8 2a f5 ff ff       	call   40000c95 <memset>
4000176b:	e9 a4 00 00 00       	jmp    40001814 <fileino_truncate+0x232>
	} else if (newsize > 0) {
40001770:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40001774:	7e 56                	jle    400017cc <fileino_truncate+0x1ea>
		// Shrink the file, but not all the way to empty.
		// Would prefer to use SYS_ZERO to free the file content,
		// but SYS_ZERO isn't guaranteed to work at page granularity.
		sys_get(SYS_PERM, 0, NULL, NULL,
40001776:	b8 00 00 40 00       	mov    $0x400000,%eax
4000177b:	2b 45 cc             	sub    -0x34(%ebp),%eax
			FILEDATA(ino) + newpagelim, FILE_MAXSIZE - newpagelim);
4000177e:	8b 55 08             	mov    0x8(%ebp),%edx
40001781:	c1 e2 16             	shl    $0x16,%edx
40001784:	89 d1                	mov    %edx,%ecx
40001786:	8b 55 cc             	mov    -0x34(%ebp),%edx
40001789:	01 ca                	add    %ecx,%edx
		memset(FILEDATA(ino) + oldsize, 0, newsize - oldsize);
	} else if (newsize > 0) {
		// Shrink the file, but not all the way to empty.
		// Would prefer to use SYS_ZERO to free the file content,
		// but SYS_ZERO isn't guaranteed to work at page granularity.
		sys_get(SYS_PERM, 0, NULL, NULL,
4000178b:	81 c2 00 00 00 80    	add    $0x80000000,%edx
40001791:	c7 45 b0 00 01 00 00 	movl   $0x100,-0x50(%ebp)
40001798:	66 c7 45 ae 00 00    	movw   $0x0,-0x52(%ebp)
4000179e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
400017a5:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
400017ac:	89 55 a0             	mov    %edx,-0x60(%ebp)
400017af:	89 45 9c             	mov    %eax,-0x64(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400017b2:	8b 45 b0             	mov    -0x50(%ebp),%eax
400017b5:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400017b8:	8b 5d a8             	mov    -0x58(%ebp),%ebx
400017bb:	0f b7 55 ae          	movzwl -0x52(%ebp),%edx
400017bf:	8b 75 a4             	mov    -0x5c(%ebp),%esi
400017c2:	8b 7d a0             	mov    -0x60(%ebp),%edi
400017c5:	8b 4d 9c             	mov    -0x64(%ebp),%ecx
400017c8:	cd 30                	int    $0x30
400017ca:	eb 48                	jmp    40001814 <fileino_truncate+0x232>
			FILEDATA(ino) + newpagelim, FILE_MAXSIZE - newpagelim);
	} else {
		// Shrink the file to empty.  Use SYS_ZERO to free completely.
		sys_get(SYS_ZERO, 0, NULL, NULL, FILEDATA(ino), FILE_MAXSIZE);
400017cc:	8b 45 08             	mov    0x8(%ebp),%eax
400017cf:	c1 e0 16             	shl    $0x16,%eax
400017d2:	05 00 00 00 80       	add    $0x80000000,%eax
400017d7:	c7 45 98 00 00 01 00 	movl   $0x10000,-0x68(%ebp)
400017de:	66 c7 45 96 00 00    	movw   $0x0,-0x6a(%ebp)
400017e4:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
400017eb:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
400017f2:	89 45 88             	mov    %eax,-0x78(%ebp)
400017f5:	c7 45 84 00 00 40 00 	movl   $0x400000,-0x7c(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400017fc:	8b 45 98             	mov    -0x68(%ebp),%eax
400017ff:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001802:	8b 5d 90             	mov    -0x70(%ebp),%ebx
40001805:	0f b7 55 96          	movzwl -0x6a(%ebp),%edx
40001809:	8b 75 8c             	mov    -0x74(%ebp),%esi
4000180c:	8b 7d 88             	mov    -0x78(%ebp),%edi
4000180f:	8b 4d 84             	mov    -0x7c(%ebp),%ecx
40001812:	cd 30                	int    $0x30
	}
	files->fi[ino].size = newsize;
40001814:	8b 0d 4c 3c 00 40    	mov    0x40003c4c,%ecx
4000181a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000181d:	8b 55 08             	mov    0x8(%ebp),%edx
40001820:	6b d2 5c             	imul   $0x5c,%edx,%edx
40001823:	01 ca                	add    %ecx,%edx
40001825:	81 c2 5c 10 00 00    	add    $0x105c,%edx
4000182b:	89 02                	mov    %eax,(%edx)
	files->fi[ino].ver++;	// truncation is always an exclusive change
4000182d:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001832:	8b 55 08             	mov    0x8(%ebp),%edx
40001835:	6b d2 5c             	imul   $0x5c,%edx,%edx
40001838:	01 c2                	add    %eax,%edx
4000183a:	81 c2 54 10 00 00    	add    $0x1054,%edx
40001840:	8b 12                	mov    (%edx),%edx
40001842:	83 c2 01             	add    $0x1,%edx
40001845:	8b 4d 08             	mov    0x8(%ebp),%ecx
40001848:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
4000184b:	01 c8                	add    %ecx,%eax
4000184d:	05 54 10 00 00       	add    $0x1054,%eax
40001852:	89 10                	mov    %edx,(%eax)
	return 0;
40001854:	b8 00 00 00 00       	mov    $0x0,%eax
}
40001859:	81 c4 8c 00 00 00    	add    $0x8c,%esp
4000185f:	5b                   	pop    %ebx
40001860:	5e                   	pop    %esi
40001861:	5f                   	pop    %edi
40001862:	5d                   	pop    %ebp
40001863:	c3                   	ret    

40001864 <fileino_flush>:

// Flush any outstanding writes on this file to our parent process.
// (XXX should flushes propagate across multiple levels?)
int
fileino_flush(int ino)
{
40001864:	55                   	push   %ebp
40001865:	89 e5                	mov    %esp,%ebp
40001867:	83 ec 18             	sub    $0x18,%esp
	assert(fileino_isvalid(ino));
4000186a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
4000186e:	7e 09                	jle    40001879 <fileino_flush+0x15>
40001870:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40001877:	7e 24                	jle    4000189d <fileino_flush+0x39>
40001879:	c7 44 24 0c 5d 3d 00 	movl   $0x40003d5d,0xc(%esp)
40001880:	40 
40001881:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40001888:	40 
40001889:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
40001890:	00 
40001891:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001898:	e8 a7 16 00 00       	call   40002f44 <debug_panic>

	if (files->fi[ino].size > files->fi[ino].rlen)
4000189d:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
400018a3:	8b 45 08             	mov    0x8(%ebp),%eax
400018a6:	6b c0 5c             	imul   $0x5c,%eax,%eax
400018a9:	01 d0                	add    %edx,%eax
400018ab:	05 5c 10 00 00       	add    $0x105c,%eax
400018b0:	8b 10                	mov    (%eax),%edx
400018b2:	8b 0d 4c 3c 00 40    	mov    0x40003c4c,%ecx
400018b8:	8b 45 08             	mov    0x8(%ebp),%eax
400018bb:	6b c0 5c             	imul   $0x5c,%eax,%eax
400018be:	01 c8                	add    %ecx,%eax
400018c0:	05 68 10 00 00       	add    $0x1068,%eax
400018c5:	8b 00                	mov    (%eax),%eax
400018c7:	39 c2                	cmp    %eax,%edx
400018c9:	76 07                	jbe    400018d2 <fileino_flush+0x6e>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400018cb:	b8 03 00 00 00       	mov    $0x3,%eax
400018d0:	cd 30                	int    $0x30
		sys_ret();	// synchronize and reconcile with parent
	return 0;
400018d2:	b8 00 00 00 00       	mov    $0x0,%eax
}
400018d7:	c9                   	leave  
400018d8:	c3                   	ret    

400018d9 <filedesc_alloc>:
// Search the file descriptor table for the first free file descriptor,
// and return a pointer to that file descriptor.
// If no file descriptors are available,
// returns NULL and set errno appropriately.
filedesc *filedesc_alloc(void)
{
400018d9:	55                   	push   %ebp
400018da:	89 e5                	mov    %esp,%ebp
400018dc:	83 ec 10             	sub    $0x10,%esp
	int i;
	for (i = 0; i < OPEN_MAX; i++)
400018df:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
400018e6:	eb 2c                	jmp    40001914 <filedesc_alloc+0x3b>
		if (files->fd[i].ino == FILEINO_NULL)
400018e8:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
400018ed:	8b 55 fc             	mov    -0x4(%ebp),%edx
400018f0:	83 c2 01             	add    $0x1,%edx
400018f3:	c1 e2 04             	shl    $0x4,%edx
400018f6:	01 d0                	add    %edx,%eax
400018f8:	8b 00                	mov    (%eax),%eax
400018fa:	85 c0                	test   %eax,%eax
400018fc:	75 12                	jne    40001910 <filedesc_alloc+0x37>
			return &files->fd[i];
400018fe:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001903:	8b 55 fc             	mov    -0x4(%ebp),%edx
40001906:	83 c2 01             	add    $0x1,%edx
40001909:	c1 e2 04             	shl    $0x4,%edx
4000190c:	01 d0                	add    %edx,%eax
4000190e:	eb 1d                	jmp    4000192d <filedesc_alloc+0x54>
// If no file descriptors are available,
// returns NULL and set errno appropriately.
filedesc *filedesc_alloc(void)
{
	int i;
	for (i = 0; i < OPEN_MAX; i++)
40001910:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40001914:	81 7d fc ff 00 00 00 	cmpl   $0xff,-0x4(%ebp)
4000191b:	7e cb                	jle    400018e8 <filedesc_alloc+0xf>
		if (files->fd[i].ino == FILEINO_NULL)
			return &files->fd[i];
	errno = EMFILE;
4000191d:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001922:	c7 00 04 00 00 00    	movl   $0x4,(%eax)
	return NULL;
40001928:	b8 00 00 00 00       	mov    $0x0,%eax
}
4000192d:	c9                   	leave  
4000192e:	c3                   	ret    

4000192f <filedesc_open>:
// The 'openflags' determines whether the file is created, truncated, etc.
// Returns the opened file descriptor on success,
// or returns NULL and sets errno on failure.
filedesc *
filedesc_open(filedesc *fd, const char *path, int openflags, mode_t mode)
{
4000192f:	55                   	push   %ebp
40001930:	89 e5                	mov    %esp,%ebp
40001932:	83 ec 28             	sub    $0x28,%esp
	if (!fd && !(fd = filedesc_alloc()))
40001935:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001939:	75 18                	jne    40001953 <filedesc_open+0x24>
4000193b:	e8 99 ff ff ff       	call   400018d9 <filedesc_alloc>
40001940:	89 45 08             	mov    %eax,0x8(%ebp)
40001943:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001947:	75 0a                	jne    40001953 <filedesc_open+0x24>
		return NULL;
40001949:	b8 00 00 00 00       	mov    $0x0,%eax
4000194e:	e9 04 02 00 00       	jmp    40001b57 <filedesc_open+0x228>
	assert(fd->ino == FILEINO_NULL);
40001953:	8b 45 08             	mov    0x8(%ebp),%eax
40001956:	8b 00                	mov    (%eax),%eax
40001958:	85 c0                	test   %eax,%eax
4000195a:	74 24                	je     40001980 <filedesc_open+0x51>
4000195c:	c7 44 24 0c 9c 3d 00 	movl   $0x40003d9c,0xc(%esp)
40001963:	40 
40001964:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
4000196b:	40 
4000196c:	c7 44 24 04 00 01 00 	movl   $0x100,0x4(%esp)
40001973:	00 
40001974:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
4000197b:	e8 c4 15 00 00       	call   40002f44 <debug_panic>

	// Determine the complete file mode if it is to be created.
	mode_t createmode = (openflags & O_CREAT) ? S_IFREG | (mode & 0777) : 0;
40001980:	8b 45 10             	mov    0x10(%ebp),%eax
40001983:	83 e0 20             	and    $0x20,%eax
40001986:	85 c0                	test   %eax,%eax
40001988:	74 0d                	je     40001997 <filedesc_open+0x68>
4000198a:	8b 45 14             	mov    0x14(%ebp),%eax
4000198d:	25 ff 01 00 00       	and    $0x1ff,%eax
40001992:	80 cc 10             	or     $0x10,%ah
40001995:	eb 05                	jmp    4000199c <filedesc_open+0x6d>
40001997:	b8 00 00 00 00       	mov    $0x0,%eax
4000199c:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Walk the directory tree to find the desired directory entry,
	// creating an entry if it doesn't exist and O_CREAT is set.
	int ino = dir_walk(path, createmode);
4000199f:	8b 45 f4             	mov    -0xc(%ebp),%eax
400019a2:	89 44 24 04          	mov    %eax,0x4(%esp)
400019a6:	8b 45 0c             	mov    0xc(%ebp),%eax
400019a9:	89 04 24             	mov    %eax,(%esp)
400019ac:	e8 d7 05 00 00       	call   40001f88 <dir_walk>
400019b1:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (ino < 0)
400019b4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400019b8:	79 0a                	jns    400019c4 <filedesc_open+0x95>
		return NULL;
400019ba:	b8 00 00 00 00       	mov    $0x0,%eax
400019bf:	e9 93 01 00 00       	jmp    40001b57 <filedesc_open+0x228>
	assert(fileino_exists(ino));
400019c4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400019c8:	7e 3d                	jle    40001a07 <filedesc_open+0xd8>
400019ca:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
400019d1:	7f 34                	jg     40001a07 <filedesc_open+0xd8>
400019d3:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
400019d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
400019dc:	6b c0 5c             	imul   $0x5c,%eax,%eax
400019df:	01 d0                	add    %edx,%eax
400019e1:	05 10 10 00 00       	add    $0x1010,%eax
400019e6:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400019ea:	84 c0                	test   %al,%al
400019ec:	74 19                	je     40001a07 <filedesc_open+0xd8>
400019ee:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
400019f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
400019f7:	6b c0 5c             	imul   $0x5c,%eax,%eax
400019fa:	01 d0                	add    %edx,%eax
400019fc:	05 58 10 00 00       	add    $0x1058,%eax
40001a01:	8b 00                	mov    (%eax),%eax
40001a03:	85 c0                	test   %eax,%eax
40001a05:	75 24                	jne    40001a2b <filedesc_open+0xfc>
40001a07:	c7 44 24 0c 31 3d 00 	movl   $0x40003d31,0xc(%esp)
40001a0e:	40 
40001a0f:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40001a16:	40 
40001a17:	c7 44 24 04 0a 01 00 	movl   $0x10a,0x4(%esp)
40001a1e:	00 
40001a1f:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001a26:	e8 19 15 00 00       	call   40002f44 <debug_panic>

	// Refuse to open conflict-marked files;
	// the user needs to resolve the conflict and clear the conflict flag,
	// or just delete the conflicted file.
	if (files->fi[ino].mode & S_IFCONF) {
40001a2b:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40001a31:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001a34:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001a37:	01 d0                	add    %edx,%eax
40001a39:	05 58 10 00 00       	add    $0x1058,%eax
40001a3e:	8b 00                	mov    (%eax),%eax
40001a40:	25 00 00 01 00       	and    $0x10000,%eax
40001a45:	85 c0                	test   %eax,%eax
40001a47:	74 15                	je     40001a5e <filedesc_open+0x12f>
		errno = ECONFLICT;
40001a49:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001a4e:	c7 00 0a 00 00 00    	movl   $0xa,(%eax)
		return NULL;
40001a54:	b8 00 00 00 00       	mov    $0x0,%eax
40001a59:	e9 f9 00 00 00       	jmp    40001b57 <filedesc_open+0x228>
	}

	// Truncate the file if we were asked to
	if (openflags & O_TRUNC) {
40001a5e:	8b 45 10             	mov    0x10(%ebp),%eax
40001a61:	83 e0 40             	and    $0x40,%eax
40001a64:	85 c0                	test   %eax,%eax
40001a66:	74 5c                	je     40001ac4 <filedesc_open+0x195>
		if (!(openflags & O_WRONLY)) {
40001a68:	8b 45 10             	mov    0x10(%ebp),%eax
40001a6b:	83 e0 02             	and    $0x2,%eax
40001a6e:	85 c0                	test   %eax,%eax
40001a70:	75 31                	jne    40001aa3 <filedesc_open+0x174>
			warn("filedesc_open: can't truncate non-writable file");
40001a72:	c7 44 24 08 b4 3d 00 	movl   $0x40003db4,0x8(%esp)
40001a79:	40 
40001a7a:	c7 44 24 04 17 01 00 	movl   $0x117,0x4(%esp)
40001a81:	00 
40001a82:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001a89:	e8 20 15 00 00       	call   40002fae <debug_warn>
			errno = EINVAL;
40001a8e:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001a93:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
			return NULL;
40001a99:	b8 00 00 00 00       	mov    $0x0,%eax
40001a9e:	e9 b4 00 00 00       	jmp    40001b57 <filedesc_open+0x228>
		}
		if (fileino_truncate(ino, 0) < 0)
40001aa3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001aaa:	00 
40001aab:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001aae:	89 04 24             	mov    %eax,(%esp)
40001ab1:	e8 2c fb ff ff       	call   400015e2 <fileino_truncate>
40001ab6:	85 c0                	test   %eax,%eax
40001ab8:	79 0a                	jns    40001ac4 <filedesc_open+0x195>
			return NULL;
40001aba:	b8 00 00 00 00       	mov    $0x0,%eax
40001abf:	e9 93 00 00 00       	jmp    40001b57 <filedesc_open+0x228>
	}

	// Initialize the file descriptor
	fd->ino = ino;
40001ac4:	8b 45 08             	mov    0x8(%ebp),%eax
40001ac7:	8b 55 f0             	mov    -0x10(%ebp),%edx
40001aca:	89 10                	mov    %edx,(%eax)
	fd->flags = openflags;
40001acc:	8b 45 08             	mov    0x8(%ebp),%eax
40001acf:	8b 55 10             	mov    0x10(%ebp),%edx
40001ad2:	89 50 04             	mov    %edx,0x4(%eax)
	fd->ofs = (openflags & O_APPEND) ? files->fi[ino].size : 0;
40001ad5:	8b 45 10             	mov    0x10(%ebp),%eax
40001ad8:	83 e0 10             	and    $0x10,%eax
40001adb:	85 c0                	test   %eax,%eax
40001add:	74 17                	je     40001af6 <filedesc_open+0x1c7>
40001adf:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40001ae5:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001ae8:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001aeb:	01 d0                	add    %edx,%eax
40001aed:	05 5c 10 00 00       	add    $0x105c,%eax
40001af2:	8b 00                	mov    (%eax),%eax
40001af4:	eb 05                	jmp    40001afb <filedesc_open+0x1cc>
40001af6:	b8 00 00 00 00       	mov    $0x0,%eax
40001afb:	8b 55 08             	mov    0x8(%ebp),%edx
40001afe:	89 42 08             	mov    %eax,0x8(%edx)
	fd->err = 0;
40001b01:	8b 45 08             	mov    0x8(%ebp),%eax
40001b04:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)

	assert(filedesc_isopen(fd));
40001b0b:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001b10:	83 c0 10             	add    $0x10,%eax
40001b13:	3b 45 08             	cmp    0x8(%ebp),%eax
40001b16:	77 18                	ja     40001b30 <filedesc_open+0x201>
40001b18:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001b1d:	05 10 10 00 00       	add    $0x1010,%eax
40001b22:	3b 45 08             	cmp    0x8(%ebp),%eax
40001b25:	76 09                	jbe    40001b30 <filedesc_open+0x201>
40001b27:	8b 45 08             	mov    0x8(%ebp),%eax
40001b2a:	8b 00                	mov    (%eax),%eax
40001b2c:	85 c0                	test   %eax,%eax
40001b2e:	75 24                	jne    40001b54 <filedesc_open+0x225>
40001b30:	c7 44 24 0c e4 3d 00 	movl   $0x40003de4,0xc(%esp)
40001b37:	40 
40001b38:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40001b3f:	40 
40001b40:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
40001b47:	00 
40001b48:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001b4f:	e8 f0 13 00 00       	call   40002f44 <debug_panic>
	return fd;
40001b54:	8b 45 08             	mov    0x8(%ebp),%eax
}
40001b57:	c9                   	leave  
40001b58:	c3                   	ret    

40001b59 <filedesc_read>:
// If the file is a special device input file such as the console,
// this function pretends the file has no end and instead
// uses sys_ret() to wait for the file to extend the special file.
ssize_t
filedesc_read(filedesc *fd, void *buf, size_t eltsize, size_t count)
{
40001b59:	55                   	push   %ebp
40001b5a:	89 e5                	mov    %esp,%ebp
40001b5c:	83 ec 38             	sub    $0x38,%esp
	assert(filedesc_isreadable(fd));
40001b5f:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001b64:	83 c0 10             	add    $0x10,%eax
40001b67:	3b 45 08             	cmp    0x8(%ebp),%eax
40001b6a:	77 25                	ja     40001b91 <filedesc_read+0x38>
40001b6c:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001b71:	05 10 10 00 00       	add    $0x1010,%eax
40001b76:	3b 45 08             	cmp    0x8(%ebp),%eax
40001b79:	76 16                	jbe    40001b91 <filedesc_read+0x38>
40001b7b:	8b 45 08             	mov    0x8(%ebp),%eax
40001b7e:	8b 00                	mov    (%eax),%eax
40001b80:	85 c0                	test   %eax,%eax
40001b82:	74 0d                	je     40001b91 <filedesc_read+0x38>
40001b84:	8b 45 08             	mov    0x8(%ebp),%eax
40001b87:	8b 40 04             	mov    0x4(%eax),%eax
40001b8a:	83 e0 01             	and    $0x1,%eax
40001b8d:	85 c0                	test   %eax,%eax
40001b8f:	75 24                	jne    40001bb5 <filedesc_read+0x5c>
40001b91:	c7 44 24 0c f8 3d 00 	movl   $0x40003df8,0xc(%esp)
40001b98:	40 
40001b99:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40001ba0:	40 
40001ba1:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
40001ba8:	00 
40001ba9:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001bb0:	e8 8f 13 00 00       	call   40002f44 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40001bb5:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40001bbb:	8b 45 08             	mov    0x8(%ebp),%eax
40001bbe:	8b 00                	mov    (%eax),%eax
40001bc0:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001bc3:	05 10 10 00 00       	add    $0x1010,%eax
40001bc8:	01 d0                	add    %edx,%eax
40001bca:	89 45 f4             	mov    %eax,-0xc(%ebp)

	ssize_t actual = fileino_read(fd->ino, fd->ofs, buf, eltsize, count);
40001bcd:	8b 45 08             	mov    0x8(%ebp),%eax
40001bd0:	8b 50 08             	mov    0x8(%eax),%edx
40001bd3:	8b 45 08             	mov    0x8(%ebp),%eax
40001bd6:	8b 00                	mov    (%eax),%eax
40001bd8:	8b 4d 14             	mov    0x14(%ebp),%ecx
40001bdb:	89 4c 24 10          	mov    %ecx,0x10(%esp)
40001bdf:	8b 4d 10             	mov    0x10(%ebp),%ecx
40001be2:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
40001be6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40001be9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40001bed:	89 54 24 04          	mov    %edx,0x4(%esp)
40001bf1:	89 04 24             	mov    %eax,(%esp)
40001bf4:	e8 93 f4 ff ff       	call   4000108c <fileino_read>
40001bf9:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (actual < 0) {
40001bfc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40001c00:	79 14                	jns    40001c16 <filedesc_read+0xbd>
		fd->err = errno;	// save error indication for ferror()
40001c02:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001c07:	8b 10                	mov    (%eax),%edx
40001c09:	8b 45 08             	mov    0x8(%ebp),%eax
40001c0c:	89 50 0c             	mov    %edx,0xc(%eax)
		return -1;
40001c0f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40001c14:	eb 56                	jmp    40001c6c <filedesc_read+0x113>
	}

	// Advance the file position
	fd->ofs += eltsize * actual;
40001c16:	8b 45 08             	mov    0x8(%ebp),%eax
40001c19:	8b 40 08             	mov    0x8(%eax),%eax
40001c1c:	89 c2                	mov    %eax,%edx
40001c1e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001c21:	0f af 45 10          	imul   0x10(%ebp),%eax
40001c25:	01 d0                	add    %edx,%eax
40001c27:	89 c2                	mov    %eax,%edx
40001c29:	8b 45 08             	mov    0x8(%ebp),%eax
40001c2c:	89 50 08             	mov    %edx,0x8(%eax)
	assert(actual == 0 || fi->size >= fd->ofs);
40001c2f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40001c33:	74 34                	je     40001c69 <filedesc_read+0x110>
40001c35:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001c38:	8b 50 4c             	mov    0x4c(%eax),%edx
40001c3b:	8b 45 08             	mov    0x8(%ebp),%eax
40001c3e:	8b 40 08             	mov    0x8(%eax),%eax
40001c41:	39 c2                	cmp    %eax,%edx
40001c43:	73 24                	jae    40001c69 <filedesc_read+0x110>
40001c45:	c7 44 24 0c 10 3e 00 	movl   $0x40003e10,0xc(%esp)
40001c4c:	40 
40001c4d:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40001c54:	40 
40001c55:	c7 44 24 04 42 01 00 	movl   $0x142,0x4(%esp)
40001c5c:	00 
40001c5d:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001c64:	e8 db 12 00 00       	call   40002f44 <debug_panic>

	return actual;
40001c69:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40001c6c:	c9                   	leave  
40001c6d:	c3                   	ret    

40001c6e <filedesc_write>:
// The size of 'buf' must be at least 'count * eltsize' bytes.
// On success, returns the number of objects written (NOT the number of bytes).
// If an error occurs, returns -1 and sets errno appropriately.
ssize_t
filedesc_write(filedesc *fd, const void *buf, size_t eltsize, size_t count)
{
40001c6e:	55                   	push   %ebp
40001c6f:	89 e5                	mov    %esp,%ebp
40001c71:	83 ec 38             	sub    $0x38,%esp
	assert(filedesc_iswritable(fd));
40001c74:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001c79:	83 c0 10             	add    $0x10,%eax
40001c7c:	3b 45 08             	cmp    0x8(%ebp),%eax
40001c7f:	77 25                	ja     40001ca6 <filedesc_write+0x38>
40001c81:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001c86:	05 10 10 00 00       	add    $0x1010,%eax
40001c8b:	3b 45 08             	cmp    0x8(%ebp),%eax
40001c8e:	76 16                	jbe    40001ca6 <filedesc_write+0x38>
40001c90:	8b 45 08             	mov    0x8(%ebp),%eax
40001c93:	8b 00                	mov    (%eax),%eax
40001c95:	85 c0                	test   %eax,%eax
40001c97:	74 0d                	je     40001ca6 <filedesc_write+0x38>
40001c99:	8b 45 08             	mov    0x8(%ebp),%eax
40001c9c:	8b 40 04             	mov    0x4(%eax),%eax
40001c9f:	83 e0 02             	and    $0x2,%eax
40001ca2:	85 c0                	test   %eax,%eax
40001ca4:	75 24                	jne    40001cca <filedesc_write+0x5c>
40001ca6:	c7 44 24 0c 33 3e 00 	movl   $0x40003e33,0xc(%esp)
40001cad:	40 
40001cae:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40001cb5:	40 
40001cb6:	c7 44 24 04 4f 01 00 	movl   $0x14f,0x4(%esp)
40001cbd:	00 
40001cbe:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001cc5:	e8 7a 12 00 00       	call   40002f44 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40001cca:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40001cd0:	8b 45 08             	mov    0x8(%ebp),%eax
40001cd3:	8b 00                	mov    (%eax),%eax
40001cd5:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001cd8:	05 10 10 00 00       	add    $0x1010,%eax
40001cdd:	01 d0                	add    %edx,%eax
40001cdf:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// If we're appending to the file, seek to the end first.
	if (fd->flags & O_APPEND)
40001ce2:	8b 45 08             	mov    0x8(%ebp),%eax
40001ce5:	8b 40 04             	mov    0x4(%eax),%eax
40001ce8:	83 e0 10             	and    $0x10,%eax
40001ceb:	85 c0                	test   %eax,%eax
40001ced:	74 0e                	je     40001cfd <filedesc_write+0x8f>
		fd->ofs = fi->size;
40001cef:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001cf2:	8b 40 4c             	mov    0x4c(%eax),%eax
40001cf5:	89 c2                	mov    %eax,%edx
40001cf7:	8b 45 08             	mov    0x8(%ebp),%eax
40001cfa:	89 50 08             	mov    %edx,0x8(%eax)

	// Write the data, growing the file as necessary.
	ssize_t actual = fileino_write(fd->ino, fd->ofs, buf, eltsize, count);
40001cfd:	8b 45 08             	mov    0x8(%ebp),%eax
40001d00:	8b 50 08             	mov    0x8(%eax),%edx
40001d03:	8b 45 08             	mov    0x8(%ebp),%eax
40001d06:	8b 00                	mov    (%eax),%eax
40001d08:	8b 4d 14             	mov    0x14(%ebp),%ecx
40001d0b:	89 4c 24 10          	mov    %ecx,0x10(%esp)
40001d0f:	8b 4d 10             	mov    0x10(%ebp),%ecx
40001d12:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
40001d16:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40001d19:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40001d1d:	89 54 24 04          	mov    %edx,0x4(%esp)
40001d21:	89 04 24             	mov    %eax,(%esp)
40001d24:	e8 f9 f4 ff ff       	call   40001222 <fileino_write>
40001d29:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (actual < 0) {
40001d2c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40001d30:	79 17                	jns    40001d49 <filedesc_write+0xdb>
		fd->err = errno;	// save error indication for ferror()
40001d32:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001d37:	8b 10                	mov    (%eax),%edx
40001d39:	8b 45 08             	mov    0x8(%ebp),%eax
40001d3c:	89 50 0c             	mov    %edx,0xc(%eax)
		return -1;
40001d3f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40001d44:	e9 98 00 00 00       	jmp    40001de1 <filedesc_write+0x173>
	}
	assert(actual == count);
40001d49:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001d4c:	3b 45 14             	cmp    0x14(%ebp),%eax
40001d4f:	74 24                	je     40001d75 <filedesc_write+0x107>
40001d51:	c7 44 24 0c 4b 3e 00 	movl   $0x40003e4b,0xc(%esp)
40001d58:	40 
40001d59:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40001d60:	40 
40001d61:	c7 44 24 04 5c 01 00 	movl   $0x15c,0x4(%esp)
40001d68:	00 
40001d69:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001d70:	e8 cf 11 00 00       	call   40002f44 <debug_panic>

	// Non-append-only writes constitute exclusive modifications,
	// so must bump the file's version number.
	if (!(fd->flags & O_APPEND))
40001d75:	8b 45 08             	mov    0x8(%ebp),%eax
40001d78:	8b 40 04             	mov    0x4(%eax),%eax
40001d7b:	83 e0 10             	and    $0x10,%eax
40001d7e:	85 c0                	test   %eax,%eax
40001d80:	75 0f                	jne    40001d91 <filedesc_write+0x123>
		fi->ver++;
40001d82:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001d85:	8b 40 44             	mov    0x44(%eax),%eax
40001d88:	8d 50 01             	lea    0x1(%eax),%edx
40001d8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001d8e:	89 50 44             	mov    %edx,0x44(%eax)

	// Advance the file position
	fd->ofs += eltsize * count;
40001d91:	8b 45 08             	mov    0x8(%ebp),%eax
40001d94:	8b 40 08             	mov    0x8(%eax),%eax
40001d97:	89 c2                	mov    %eax,%edx
40001d99:	8b 45 10             	mov    0x10(%ebp),%eax
40001d9c:	0f af 45 14          	imul   0x14(%ebp),%eax
40001da0:	01 d0                	add    %edx,%eax
40001da2:	89 c2                	mov    %eax,%edx
40001da4:	8b 45 08             	mov    0x8(%ebp),%eax
40001da7:	89 50 08             	mov    %edx,0x8(%eax)
	assert(fi->size >= fd->ofs);
40001daa:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001dad:	8b 50 4c             	mov    0x4c(%eax),%edx
40001db0:	8b 45 08             	mov    0x8(%ebp),%eax
40001db3:	8b 40 08             	mov    0x8(%eax),%eax
40001db6:	39 c2                	cmp    %eax,%edx
40001db8:	73 24                	jae    40001dde <filedesc_write+0x170>
40001dba:	c7 44 24 0c 5b 3e 00 	movl   $0x40003e5b,0xc(%esp)
40001dc1:	40 
40001dc2:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40001dc9:	40 
40001dca:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
40001dd1:	00 
40001dd2:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001dd9:	e8 66 11 00 00       	call   40002f44 <debug_panic>
	return count;
40001dde:	8b 45 14             	mov    0x14(%ebp),%eax
}
40001de1:	c9                   	leave  
40001de2:	c3                   	ret    

40001de3 <filedesc_seek>:
// which may be relative to the file start, end, or corrent position,
// depending on 'whence' (SEEK_SET, SEEK_CUR, or SEEK_END).
// Returns the resulting absolute file position,
// or returns -1 and sets errno appropriately on error.
off_t filedesc_seek(filedesc *fd, off_t offset, int whence)
{
40001de3:	55                   	push   %ebp
40001de4:	89 e5                	mov    %esp,%ebp
40001de6:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isopen(fd));
40001de9:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001dee:	83 c0 10             	add    $0x10,%eax
40001df1:	3b 45 08             	cmp    0x8(%ebp),%eax
40001df4:	77 18                	ja     40001e0e <filedesc_seek+0x2b>
40001df6:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001dfb:	05 10 10 00 00       	add    $0x1010,%eax
40001e00:	3b 45 08             	cmp    0x8(%ebp),%eax
40001e03:	76 09                	jbe    40001e0e <filedesc_seek+0x2b>
40001e05:	8b 45 08             	mov    0x8(%ebp),%eax
40001e08:	8b 00                	mov    (%eax),%eax
40001e0a:	85 c0                	test   %eax,%eax
40001e0c:	75 24                	jne    40001e32 <filedesc_seek+0x4f>
40001e0e:	c7 44 24 0c e4 3d 00 	movl   $0x40003de4,0xc(%esp)
40001e15:	40 
40001e16:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40001e1d:	40 
40001e1e:	c7 44 24 04 70 01 00 	movl   $0x170,0x4(%esp)
40001e25:	00 
40001e26:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001e2d:	e8 12 11 00 00       	call   40002f44 <debug_panic>
	assert(whence == SEEK_SET || whence == SEEK_CUR || whence == SEEK_END);
40001e32:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40001e36:	74 30                	je     40001e68 <filedesc_seek+0x85>
40001e38:	83 7d 10 01          	cmpl   $0x1,0x10(%ebp)
40001e3c:	74 2a                	je     40001e68 <filedesc_seek+0x85>
40001e3e:	83 7d 10 02          	cmpl   $0x2,0x10(%ebp)
40001e42:	74 24                	je     40001e68 <filedesc_seek+0x85>
40001e44:	c7 44 24 0c 70 3e 00 	movl   $0x40003e70,0xc(%esp)
40001e4b:	40 
40001e4c:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40001e53:	40 
40001e54:	c7 44 24 04 71 01 00 	movl   $0x171,0x4(%esp)
40001e5b:	00 
40001e5c:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001e63:	e8 dc 10 00 00       	call   40002f44 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40001e68:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40001e6e:	8b 45 08             	mov    0x8(%ebp),%eax
40001e71:	8b 00                	mov    (%eax),%eax
40001e73:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001e76:	05 10 10 00 00       	add    $0x1010,%eax
40001e7b:	01 d0                	add    %edx,%eax
40001e7d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	ino_t ino = fd->ino;
40001e80:	8b 45 08             	mov    0x8(%ebp),%eax
40001e83:	8b 00                	mov    (%eax),%eax
40001e85:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint8_t* start_pos = FILEDATA(ino);
40001e88:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001e8b:	c1 e0 16             	shl    $0x16,%eax
40001e8e:	05 00 00 00 80       	add    $0x80000000,%eax
40001e93:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// Lab 4: insert your file descriptor seek implementation here.
	//warn("filedesc_seek() not implemented");
	//errno = EINVAL;
	//return -1;
	switch(whence){
40001e96:	8b 45 10             	mov    0x10(%ebp),%eax
40001e99:	83 f8 01             	cmp    $0x1,%eax
40001e9c:	74 14                	je     40001eb2 <filedesc_seek+0xcf>
40001e9e:	83 f8 02             	cmp    $0x2,%eax
40001ea1:	74 22                	je     40001ec5 <filedesc_seek+0xe2>
40001ea3:	85 c0                	test   %eax,%eax
40001ea5:	75 33                	jne    40001eda <filedesc_seek+0xf7>
	case SEEK_SET:
		fd->ofs = offset;
40001ea7:	8b 45 08             	mov    0x8(%ebp),%eax
40001eaa:	8b 55 0c             	mov    0xc(%ebp),%edx
40001ead:	89 50 08             	mov    %edx,0x8(%eax)
		break;
40001eb0:	eb 3a                	jmp    40001eec <filedesc_seek+0x109>
	case SEEK_CUR:
		fd->ofs += offset;
40001eb2:	8b 45 08             	mov    0x8(%ebp),%eax
40001eb5:	8b 50 08             	mov    0x8(%eax),%edx
40001eb8:	8b 45 0c             	mov    0xc(%ebp),%eax
40001ebb:	01 c2                	add    %eax,%edx
40001ebd:	8b 45 08             	mov    0x8(%ebp),%eax
40001ec0:	89 50 08             	mov    %edx,0x8(%eax)
		break;
40001ec3:	eb 27                	jmp    40001eec <filedesc_seek+0x109>
	case SEEK_END:
		fd->ofs = (fi->size) + offset;
40001ec5:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001ec8:	8b 50 4c             	mov    0x4c(%eax),%edx
40001ecb:	8b 45 0c             	mov    0xc(%ebp),%eax
40001ece:	01 d0                	add    %edx,%eax
40001ed0:	89 c2                	mov    %eax,%edx
40001ed2:	8b 45 08             	mov    0x8(%ebp),%eax
40001ed5:	89 50 08             	mov    %edx,0x8(%eax)
		break;
40001ed8:	eb 12                	jmp    40001eec <filedesc_seek+0x109>
	default:
		errno = EINVAL;
40001eda:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001edf:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
		return -1;
40001ee5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40001eea:	eb 06                	jmp    40001ef2 <filedesc_seek+0x10f>
	}
	return fd->ofs;
40001eec:	8b 45 08             	mov    0x8(%ebp),%eax
40001eef:	8b 40 08             	mov    0x8(%eax),%eax
}
40001ef2:	c9                   	leave  
40001ef3:	c3                   	ret    

40001ef4 <filedesc_close>:

void
filedesc_close(filedesc *fd)
{
40001ef4:	55                   	push   %ebp
40001ef5:	89 e5                	mov    %esp,%ebp
40001ef7:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
40001efa:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001eff:	83 c0 10             	add    $0x10,%eax
40001f02:	3b 45 08             	cmp    0x8(%ebp),%eax
40001f05:	77 18                	ja     40001f1f <filedesc_close+0x2b>
40001f07:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001f0c:	05 10 10 00 00       	add    $0x1010,%eax
40001f11:	3b 45 08             	cmp    0x8(%ebp),%eax
40001f14:	76 09                	jbe    40001f1f <filedesc_close+0x2b>
40001f16:	8b 45 08             	mov    0x8(%ebp),%eax
40001f19:	8b 00                	mov    (%eax),%eax
40001f1b:	85 c0                	test   %eax,%eax
40001f1d:	75 24                	jne    40001f43 <filedesc_close+0x4f>
40001f1f:	c7 44 24 0c e4 3d 00 	movl   $0x40003de4,0xc(%esp)
40001f26:	40 
40001f27:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40001f2e:	40 
40001f2f:	c7 44 24 04 8e 01 00 	movl   $0x18e,0x4(%esp)
40001f36:	00 
40001f37:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001f3e:	e8 01 10 00 00       	call   40002f44 <debug_panic>
	assert(fileino_isvalid(fd->ino));
40001f43:	8b 45 08             	mov    0x8(%ebp),%eax
40001f46:	8b 00                	mov    (%eax),%eax
40001f48:	85 c0                	test   %eax,%eax
40001f4a:	7e 0c                	jle    40001f58 <filedesc_close+0x64>
40001f4c:	8b 45 08             	mov    0x8(%ebp),%eax
40001f4f:	8b 00                	mov    (%eax),%eax
40001f51:	3d ff 00 00 00       	cmp    $0xff,%eax
40001f56:	7e 24                	jle    40001f7c <filedesc_close+0x88>
40001f58:	c7 44 24 0c af 3e 00 	movl   $0x40003eaf,0xc(%esp)
40001f5f:	40 
40001f60:	c7 44 24 08 84 3c 00 	movl   $0x40003c84,0x8(%esp)
40001f67:	40 
40001f68:	c7 44 24 04 8f 01 00 	movl   $0x18f,0x4(%esp)
40001f6f:	00 
40001f70:	c7 04 24 6f 3c 00 40 	movl   $0x40003c6f,(%esp)
40001f77:	e8 c8 0f 00 00       	call   40002f44 <debug_panic>

	fd->ino = FILEINO_NULL;		// mark the fd free
40001f7c:	8b 45 08             	mov    0x8(%ebp),%eax
40001f7f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
40001f85:	c9                   	leave  
40001f86:	c3                   	ret    
40001f87:	90                   	nop

40001f88 <dir_walk>:
#include <inc/dirent.h>


int
dir_walk(const char *path, mode_t createmode)
{
40001f88:	55                   	push   %ebp
40001f89:	89 e5                	mov    %esp,%ebp
40001f8b:	83 ec 28             	sub    $0x28,%esp
	assert(path != 0 && *path != 0);
40001f8e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001f92:	74 0a                	je     40001f9e <dir_walk+0x16>
40001f94:	8b 45 08             	mov    0x8(%ebp),%eax
40001f97:	0f b6 00             	movzbl (%eax),%eax
40001f9a:	84 c0                	test   %al,%al
40001f9c:	75 24                	jne    40001fc2 <dir_walk+0x3a>
40001f9e:	c7 44 24 0c c8 3e 00 	movl   $0x40003ec8,0xc(%esp)
40001fa5:	40 
40001fa6:	c7 44 24 08 e0 3e 00 	movl   $0x40003ee0,0x8(%esp)
40001fad:	40 
40001fae:	c7 44 24 04 15 00 00 	movl   $0x15,0x4(%esp)
40001fb5:	00 
40001fb6:	c7 04 24 f5 3e 00 40 	movl   $0x40003ef5,(%esp)
40001fbd:	e8 82 0f 00 00       	call   40002f44 <debug_panic>

	// Start at the current or root directory as appropriate
	int dino = files->cwd;
40001fc2:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40001fc7:	8b 40 04             	mov    0x4(%eax),%eax
40001fca:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (*path == '/') {
40001fcd:	8b 45 08             	mov    0x8(%ebp),%eax
40001fd0:	0f b6 00             	movzbl (%eax),%eax
40001fd3:	3c 2f                	cmp    $0x2f,%al
40001fd5:	75 27                	jne    40001ffe <dir_walk+0x76>
		dino = FILEINO_ROOTDIR;
40001fd7:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
		do { path++; } while (*path == '/');	// skip leading slashes
40001fde:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40001fe2:	8b 45 08             	mov    0x8(%ebp),%eax
40001fe5:	0f b6 00             	movzbl (%eax),%eax
40001fe8:	3c 2f                	cmp    $0x2f,%al
40001fea:	74 f2                	je     40001fde <dir_walk+0x56>
		if (*path == 0)
40001fec:	8b 45 08             	mov    0x8(%ebp),%eax
40001fef:	0f b6 00             	movzbl (%eax),%eax
40001ff2:	84 c0                	test   %al,%al
40001ff4:	75 08                	jne    40001ffe <dir_walk+0x76>
			return dino;	// Just looking up root directory
40001ff6:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001ff9:	e9 61 05 00 00       	jmp    4000255f <dir_walk+0x5d7>
	}

	// Search for the appropriate entry in this directory
	searchdir:
	assert(fileino_isdir(dino));
40001ffe:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002002:	7e 45                	jle    40002049 <dir_walk+0xc1>
40002004:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
4000200b:	7f 3c                	jg     40002049 <dir_walk+0xc1>
4000200d:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40002013:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002016:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002019:	01 d0                	add    %edx,%eax
4000201b:	05 10 10 00 00       	add    $0x1010,%eax
40002020:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002024:	84 c0                	test   %al,%al
40002026:	74 21                	je     40002049 <dir_walk+0xc1>
40002028:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
4000202e:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002031:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002034:	01 d0                	add    %edx,%eax
40002036:	05 58 10 00 00       	add    $0x1058,%eax
4000203b:	8b 00                	mov    (%eax),%eax
4000203d:	25 00 70 00 00       	and    $0x7000,%eax
40002042:	3d 00 20 00 00       	cmp    $0x2000,%eax
40002047:	74 24                	je     4000206d <dir_walk+0xe5>
40002049:	c7 44 24 0c ff 3e 00 	movl   $0x40003eff,0xc(%esp)
40002050:	40 
40002051:	c7 44 24 08 e0 3e 00 	movl   $0x40003ee0,0x8(%esp)
40002058:	40 
40002059:	c7 44 24 04 22 00 00 	movl   $0x22,0x4(%esp)
40002060:	00 
40002061:	c7 04 24 f5 3e 00 40 	movl   $0x40003ef5,(%esp)
40002068:	e8 d7 0e 00 00       	call   40002f44 <debug_panic>
	assert(fileino_isdir(files->fi[dino].dino));
4000206d:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40002073:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002076:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002079:	01 d0                	add    %edx,%eax
4000207b:	05 10 10 00 00       	add    $0x1010,%eax
40002080:	8b 00                	mov    (%eax),%eax
40002082:	85 c0                	test   %eax,%eax
40002084:	7e 7c                	jle    40002102 <dir_walk+0x17a>
40002086:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
4000208c:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000208f:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002092:	01 d0                	add    %edx,%eax
40002094:	05 10 10 00 00       	add    $0x1010,%eax
40002099:	8b 00                	mov    (%eax),%eax
4000209b:	3d ff 00 00 00       	cmp    $0xff,%eax
400020a0:	7f 60                	jg     40002102 <dir_walk+0x17a>
400020a2:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
400020a8:	8b 0d 4c 3c 00 40    	mov    0x40003c4c,%ecx
400020ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
400020b1:	6b c0 5c             	imul   $0x5c,%eax,%eax
400020b4:	01 c8                	add    %ecx,%eax
400020b6:	05 10 10 00 00       	add    $0x1010,%eax
400020bb:	8b 00                	mov    (%eax),%eax
400020bd:	6b c0 5c             	imul   $0x5c,%eax,%eax
400020c0:	01 d0                	add    %edx,%eax
400020c2:	05 10 10 00 00       	add    $0x1010,%eax
400020c7:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400020cb:	84 c0                	test   %al,%al
400020cd:	74 33                	je     40002102 <dir_walk+0x17a>
400020cf:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
400020d5:	8b 0d 4c 3c 00 40    	mov    0x40003c4c,%ecx
400020db:	8b 45 f4             	mov    -0xc(%ebp),%eax
400020de:	6b c0 5c             	imul   $0x5c,%eax,%eax
400020e1:	01 c8                	add    %ecx,%eax
400020e3:	05 10 10 00 00       	add    $0x1010,%eax
400020e8:	8b 00                	mov    (%eax),%eax
400020ea:	6b c0 5c             	imul   $0x5c,%eax,%eax
400020ed:	01 d0                	add    %edx,%eax
400020ef:	05 58 10 00 00       	add    $0x1058,%eax
400020f4:	8b 00                	mov    (%eax),%eax
400020f6:	25 00 70 00 00       	and    $0x7000,%eax
400020fb:	3d 00 20 00 00       	cmp    $0x2000,%eax
40002100:	74 24                	je     40002126 <dir_walk+0x19e>
40002102:	c7 44 24 0c 14 3f 00 	movl   $0x40003f14,0xc(%esp)
40002109:	40 
4000210a:	c7 44 24 08 e0 3e 00 	movl   $0x40003ee0,0x8(%esp)
40002111:	40 
40002112:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
40002119:	00 
4000211a:	c7 04 24 f5 3e 00 40 	movl   $0x40003ef5,(%esp)
40002121:	e8 1e 0e 00 00       	call   40002f44 <debug_panic>

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
40002126:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
4000212d:	e9 3d 02 00 00       	jmp    4000236f <dir_walk+0x3e7>
		if (!fileino_alloced(ino) || files->fi[ino].dino != dino)
40002132:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002136:	0f 8e 28 02 00 00    	jle    40002364 <dir_walk+0x3dc>
4000213c:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40002143:	0f 8f 1b 02 00 00    	jg     40002364 <dir_walk+0x3dc>
40002149:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
4000214f:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002152:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002155:	01 d0                	add    %edx,%eax
40002157:	05 10 10 00 00       	add    $0x1010,%eax
4000215c:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002160:	84 c0                	test   %al,%al
40002162:	0f 84 fc 01 00 00    	je     40002364 <dir_walk+0x3dc>
40002168:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
4000216e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002171:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002174:	01 d0                	add    %edx,%eax
40002176:	05 10 10 00 00       	add    $0x1010,%eax
4000217b:	8b 00                	mov    (%eax),%eax
4000217d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40002180:	0f 85 de 01 00 00    	jne    40002364 <dir_walk+0x3dc>
			continue;	// not an entry in directory 'dino'

		// Does this inode's name match our next path component?
		len = strlen(files->fi[ino].de.d_name);
40002186:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
4000218b:	8b 55 f0             	mov    -0x10(%ebp),%edx
4000218e:	6b d2 5c             	imul   $0x5c,%edx,%edx
40002191:	81 c2 10 10 00 00    	add    $0x1010,%edx
40002197:	01 d0                	add    %edx,%eax
40002199:	83 c0 04             	add    $0x4,%eax
4000219c:	89 04 24             	mov    %eax,(%esp)
4000219f:	e8 34 e9 ff ff       	call   40000ad8 <strlen>
400021a4:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (memcmp(path, files->fi[ino].de.d_name, len) != 0)
400021a7:	8b 45 ec             	mov    -0x14(%ebp),%eax
400021aa:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
400021b0:	8b 4d f0             	mov    -0x10(%ebp),%ecx
400021b3:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
400021b6:	81 c1 10 10 00 00    	add    $0x1010,%ecx
400021bc:	01 ca                	add    %ecx,%edx
400021be:	83 c2 04             	add    $0x4,%edx
400021c1:	89 44 24 08          	mov    %eax,0x8(%esp)
400021c5:	89 54 24 04          	mov    %edx,0x4(%esp)
400021c9:	8b 45 08             	mov    0x8(%ebp),%eax
400021cc:	89 04 24             	mov    %eax,(%esp)
400021cf:	e8 2a ec ff ff       	call   40000dfe <memcmp>
400021d4:	85 c0                	test   %eax,%eax
400021d6:	0f 85 8b 01 00 00    	jne    40002367 <dir_walk+0x3df>
			continue;	// no match
		found:
		if (path[len] == 0) {
400021dc:	8b 55 ec             	mov    -0x14(%ebp),%edx
400021df:	8b 45 08             	mov    0x8(%ebp),%eax
400021e2:	01 d0                	add    %edx,%eax
400021e4:	0f b6 00             	movzbl (%eax),%eax
400021e7:	84 c0                	test   %al,%al
400021e9:	0f 85 c7 00 00 00    	jne    400022b6 <dir_walk+0x32e>
			// Exact match at end of path - but does it exist?
			if (fileino_exists(ino))
400021ef:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400021f3:	7e 45                	jle    4000223a <dir_walk+0x2b2>
400021f5:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
400021fc:	7f 3c                	jg     4000223a <dir_walk+0x2b2>
400021fe:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40002204:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002207:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000220a:	01 d0                	add    %edx,%eax
4000220c:	05 10 10 00 00       	add    $0x1010,%eax
40002211:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002215:	84 c0                	test   %al,%al
40002217:	74 21                	je     4000223a <dir_walk+0x2b2>
40002219:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
4000221f:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002222:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002225:	01 d0                	add    %edx,%eax
40002227:	05 58 10 00 00       	add    $0x1058,%eax
4000222c:	8b 00                	mov    (%eax),%eax
4000222e:	85 c0                	test   %eax,%eax
40002230:	74 08                	je     4000223a <dir_walk+0x2b2>
				return ino;	// yes - return it
40002232:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002235:	e9 25 03 00 00       	jmp    4000255f <dir_walk+0x5d7>

			// no - existed, but was deleted.  re-create?
			if (!createmode) {
4000223a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
4000223e:	75 15                	jne    40002255 <dir_walk+0x2cd>
				errno = ENOENT;
40002240:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002245:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
				return -1;
4000224b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002250:	e9 0a 03 00 00       	jmp    4000255f <dir_walk+0x5d7>
			}
			files->fi[ino].ver++;	// an exclusive change
40002255:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
4000225a:	8b 55 f0             	mov    -0x10(%ebp),%edx
4000225d:	6b d2 5c             	imul   $0x5c,%edx,%edx
40002260:	01 c2                	add    %eax,%edx
40002262:	81 c2 54 10 00 00    	add    $0x1054,%edx
40002268:	8b 12                	mov    (%edx),%edx
4000226a:	83 c2 01             	add    $0x1,%edx
4000226d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
40002270:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
40002273:	01 c8                	add    %ecx,%eax
40002275:	05 54 10 00 00       	add    $0x1054,%eax
4000227a:	89 10                	mov    %edx,(%eax)
			files->fi[ino].mode = createmode;
4000227c:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40002282:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002285:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002288:	01 d0                	add    %edx,%eax
4000228a:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
40002290:	8b 45 0c             	mov    0xc(%ebp),%eax
40002293:	89 02                	mov    %eax,(%edx)
			files->fi[ino].size = 0;
40002295:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
4000229b:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000229e:	6b c0 5c             	imul   $0x5c,%eax,%eax
400022a1:	01 d0                	add    %edx,%eax
400022a3:	05 5c 10 00 00       	add    $0x105c,%eax
400022a8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			return ino;
400022ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
400022b1:	e9 a9 02 00 00       	jmp    4000255f <dir_walk+0x5d7>
		}
		if (path[len] != '/')
400022b6:	8b 55 ec             	mov    -0x14(%ebp),%edx
400022b9:	8b 45 08             	mov    0x8(%ebp),%eax
400022bc:	01 d0                	add    %edx,%eax
400022be:	0f b6 00             	movzbl (%eax),%eax
400022c1:	3c 2f                	cmp    $0x2f,%al
400022c3:	0f 85 a1 00 00 00    	jne    4000236a <dir_walk+0x3e2>
			continue;	// no match

		// Make sure this dirent refers to a directory
		if (!fileino_isdir(ino)) {
400022c9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400022cd:	7e 45                	jle    40002314 <dir_walk+0x38c>
400022cf:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
400022d6:	7f 3c                	jg     40002314 <dir_walk+0x38c>
400022d8:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
400022de:	8b 45 f0             	mov    -0x10(%ebp),%eax
400022e1:	6b c0 5c             	imul   $0x5c,%eax,%eax
400022e4:	01 d0                	add    %edx,%eax
400022e6:	05 10 10 00 00       	add    $0x1010,%eax
400022eb:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400022ef:	84 c0                	test   %al,%al
400022f1:	74 21                	je     40002314 <dir_walk+0x38c>
400022f3:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
400022f9:	8b 45 f0             	mov    -0x10(%ebp),%eax
400022fc:	6b c0 5c             	imul   $0x5c,%eax,%eax
400022ff:	01 d0                	add    %edx,%eax
40002301:	05 58 10 00 00       	add    $0x1058,%eax
40002306:	8b 00                	mov    (%eax),%eax
40002308:	25 00 70 00 00       	and    $0x7000,%eax
4000230d:	3d 00 20 00 00       	cmp    $0x2000,%eax
40002312:	74 15                	je     40002329 <dir_walk+0x3a1>
			errno = ENOTDIR;
40002314:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002319:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
			return -1;
4000231f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002324:	e9 36 02 00 00       	jmp    4000255f <dir_walk+0x5d7>
		}

		// Skip slashes to find next component
		do { len++; } while (path[len] == '/');
40002329:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
4000232d:	8b 55 ec             	mov    -0x14(%ebp),%edx
40002330:	8b 45 08             	mov    0x8(%ebp),%eax
40002333:	01 d0                	add    %edx,%eax
40002335:	0f b6 00             	movzbl (%eax),%eax
40002338:	3c 2f                	cmp    $0x2f,%al
4000233a:	74 ed                	je     40002329 <dir_walk+0x3a1>
		if (path[len] == 0)
4000233c:	8b 55 ec             	mov    -0x14(%ebp),%edx
4000233f:	8b 45 08             	mov    0x8(%ebp),%eax
40002342:	01 d0                	add    %edx,%eax
40002344:	0f b6 00             	movzbl (%eax),%eax
40002347:	84 c0                	test   %al,%al
40002349:	75 08                	jne    40002353 <dir_walk+0x3cb>
			return ino;	// matched directory at end of path
4000234b:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000234e:	e9 0c 02 00 00       	jmp    4000255f <dir_walk+0x5d7>

		// Walk the next directory in the path
		dino = ino;
40002353:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002356:	89 45 f4             	mov    %eax,-0xc(%ebp)
		path += len;
40002359:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000235c:	01 45 08             	add    %eax,0x8(%ebp)
		goto searchdir;
4000235f:	e9 9a fc ff ff       	jmp    40001ffe <dir_walk+0x76>

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
		if (!fileino_alloced(ino) || files->fi[ino].dino != dino)
			continue;	// not an entry in directory 'dino'
40002364:	90                   	nop
40002365:	eb 04                	jmp    4000236b <dir_walk+0x3e3>

		// Does this inode's name match our next path component?
		len = strlen(files->fi[ino].de.d_name);
		if (memcmp(path, files->fi[ino].de.d_name, len) != 0)
			continue;	// no match
40002367:	90                   	nop
40002368:	eb 01                	jmp    4000236b <dir_walk+0x3e3>
			files->fi[ino].mode = createmode;
			files->fi[ino].size = 0;
			return ino;
		}
		if (path[len] != '/')
			continue;	// no match
4000236a:	90                   	nop
	assert(fileino_isdir(dino));
	assert(fileino_isdir(files->fi[dino].dino));

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
4000236b:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
4000236f:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40002376:	0f 8e b6 fd ff ff    	jle    40002132 <dir_walk+0x1aa>
		path += len;
		goto searchdir;
	}

	// Looking for one of the special entries '.' or '..'?
	if (path[0] == '.' && (path[1] == 0 || path[1] == '/')) {
4000237c:	8b 45 08             	mov    0x8(%ebp),%eax
4000237f:	0f b6 00             	movzbl (%eax),%eax
40002382:	3c 2e                	cmp    $0x2e,%al
40002384:	75 2c                	jne    400023b2 <dir_walk+0x42a>
40002386:	8b 45 08             	mov    0x8(%ebp),%eax
40002389:	83 c0 01             	add    $0x1,%eax
4000238c:	0f b6 00             	movzbl (%eax),%eax
4000238f:	84 c0                	test   %al,%al
40002391:	74 0d                	je     400023a0 <dir_walk+0x418>
40002393:	8b 45 08             	mov    0x8(%ebp),%eax
40002396:	83 c0 01             	add    $0x1,%eax
40002399:	0f b6 00             	movzbl (%eax),%eax
4000239c:	3c 2f                	cmp    $0x2f,%al
4000239e:	75 12                	jne    400023b2 <dir_walk+0x42a>
		len = 1;
400023a0:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		ino = dino;	// just leads to this same directory
400023a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
400023aa:	89 45 f0             	mov    %eax,-0x10(%ebp)
		goto found;
400023ad:	e9 2a fe ff ff       	jmp    400021dc <dir_walk+0x254>
	}
	if (path[0] == '.' && path[1] == '.'
400023b2:	8b 45 08             	mov    0x8(%ebp),%eax
400023b5:	0f b6 00             	movzbl (%eax),%eax
400023b8:	3c 2e                	cmp    $0x2e,%al
400023ba:	75 4b                	jne    40002407 <dir_walk+0x47f>
400023bc:	8b 45 08             	mov    0x8(%ebp),%eax
400023bf:	83 c0 01             	add    $0x1,%eax
400023c2:	0f b6 00             	movzbl (%eax),%eax
400023c5:	3c 2e                	cmp    $0x2e,%al
400023c7:	75 3e                	jne    40002407 <dir_walk+0x47f>
			&& (path[2] == 0 || path[2] == '/')) {
400023c9:	8b 45 08             	mov    0x8(%ebp),%eax
400023cc:	83 c0 02             	add    $0x2,%eax
400023cf:	0f b6 00             	movzbl (%eax),%eax
400023d2:	84 c0                	test   %al,%al
400023d4:	74 0d                	je     400023e3 <dir_walk+0x45b>
400023d6:	8b 45 08             	mov    0x8(%ebp),%eax
400023d9:	83 c0 02             	add    $0x2,%eax
400023dc:	0f b6 00             	movzbl (%eax),%eax
400023df:	3c 2f                	cmp    $0x2f,%al
400023e1:	75 24                	jne    40002407 <dir_walk+0x47f>
		len = 2;
400023e3:	c7 45 ec 02 00 00 00 	movl   $0x2,-0x14(%ebp)
		ino = files->fi[dino].dino;	// leads to root directory
400023ea:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
400023f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
400023f3:	6b c0 5c             	imul   $0x5c,%eax,%eax
400023f6:	01 d0                	add    %edx,%eax
400023f8:	05 10 10 00 00       	add    $0x1010,%eax
400023fd:	8b 00                	mov    (%eax),%eax
400023ff:	89 45 f0             	mov    %eax,-0x10(%ebp)
		goto found;
40002402:	e9 d5 fd ff ff       	jmp    400021dc <dir_walk+0x254>
	}

	// Path component not found - see if we should create it
	if (!createmode || strchr(path, '/') != NULL) {
40002407:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
4000240b:	74 17                	je     40002424 <dir_walk+0x49c>
4000240d:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
40002414:	00 
40002415:	8b 45 08             	mov    0x8(%ebp),%eax
40002418:	89 04 24             	mov    %eax,(%esp)
4000241b:	e8 3d e8 ff ff       	call   40000c5d <strchr>
40002420:	85 c0                	test   %eax,%eax
40002422:	74 15                	je     40002439 <dir_walk+0x4b1>
		errno = ENOENT;
40002424:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002429:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
		return -1;
4000242f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002434:	e9 26 01 00 00       	jmp    4000255f <dir_walk+0x5d7>
	}
	if (strlen(path) > NAME_MAX) {
40002439:	8b 45 08             	mov    0x8(%ebp),%eax
4000243c:	89 04 24             	mov    %eax,(%esp)
4000243f:	e8 94 e6 ff ff       	call   40000ad8 <strlen>
40002444:	83 f8 3f             	cmp    $0x3f,%eax
40002447:	7e 15                	jle    4000245e <dir_walk+0x4d6>
		errno = ENAMETOOLONG;
40002449:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
4000244e:	c7 00 06 00 00 00    	movl   $0x6,(%eax)
		return -1;
40002454:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002459:	e9 01 01 00 00       	jmp    4000255f <dir_walk+0x5d7>
	}

	// Allocate a new inode and create this entry with the given mode.
	ino = fileino_alloc();
4000245e:	e8 31 ea ff ff       	call   40000e94 <fileino_alloc>
40002463:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (ino < 0)
40002466:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
4000246a:	79 0a                	jns    40002476 <dir_walk+0x4ee>
		return -1;
4000246c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002471:	e9 e9 00 00 00       	jmp    4000255f <dir_walk+0x5d7>
	assert(fileino_isvalid(ino) && !fileino_alloced(ino));
40002476:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
4000247a:	7e 33                	jle    400024af <dir_walk+0x527>
4000247c:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40002483:	7f 2a                	jg     400024af <dir_walk+0x527>
40002485:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002489:	7e 48                	jle    400024d3 <dir_walk+0x54b>
4000248b:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40002492:	7f 3f                	jg     400024d3 <dir_walk+0x54b>
40002494:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
4000249a:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000249d:	6b c0 5c             	imul   $0x5c,%eax,%eax
400024a0:	01 d0                	add    %edx,%eax
400024a2:	05 10 10 00 00       	add    $0x1010,%eax
400024a7:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400024ab:	84 c0                	test   %al,%al
400024ad:	74 24                	je     400024d3 <dir_walk+0x54b>
400024af:	c7 44 24 0c 38 3f 00 	movl   $0x40003f38,0xc(%esp)
400024b6:	40 
400024b7:	c7 44 24 08 e0 3e 00 	movl   $0x40003ee0,0x8(%esp)
400024be:	40 
400024bf:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
400024c6:	00 
400024c7:	c7 04 24 f5 3e 00 40 	movl   $0x40003ef5,(%esp)
400024ce:	e8 71 0a 00 00       	call   40002f44 <debug_panic>
	strcpy(files->fi[ino].de.d_name, path);
400024d3:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
400024d8:	8b 55 f0             	mov    -0x10(%ebp),%edx
400024db:	6b d2 5c             	imul   $0x5c,%edx,%edx
400024de:	81 c2 10 10 00 00    	add    $0x1010,%edx
400024e4:	01 d0                	add    %edx,%eax
400024e6:	8d 50 04             	lea    0x4(%eax),%edx
400024e9:	8b 45 08             	mov    0x8(%ebp),%eax
400024ec:	89 44 24 04          	mov    %eax,0x4(%esp)
400024f0:	89 14 24             	mov    %edx,(%esp)
400024f3:	e8 06 e6 ff ff       	call   40000afe <strcpy>
	files->fi[ino].dino = dino;
400024f8:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
400024fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002501:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002504:	01 d0                	add    %edx,%eax
40002506:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
4000250c:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000250f:	89 02                	mov    %eax,(%edx)
	files->fi[ino].ver = 0;
40002511:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40002517:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000251a:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000251d:	01 d0                	add    %edx,%eax
4000251f:	05 54 10 00 00       	add    $0x1054,%eax
40002524:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	files->fi[ino].mode = createmode;
4000252a:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40002530:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002533:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002536:	01 d0                	add    %edx,%eax
40002538:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
4000253e:	8b 45 0c             	mov    0xc(%ebp),%eax
40002541:	89 02                	mov    %eax,(%edx)
	files->fi[ino].size = 0;
40002543:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40002549:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000254c:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000254f:	01 d0                	add    %edx,%eax
40002551:	05 5c 10 00 00       	add    $0x105c,%eax
40002556:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return ino;
4000255c:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
4000255f:	c9                   	leave  
40002560:	c3                   	ret    

40002561 <opendir>:
// Open a directory for scanning.
// For simplicity, DIR is simply a filedesc like other file descriptors,
// except we interpret fd->ofs as an inode number for scanning,
// instead of as a byte offset as in a regular file.
DIR *opendir(const char *path)
{
40002561:	55                   	push   %ebp
40002562:	89 e5                	mov    %esp,%ebp
40002564:	83 ec 28             	sub    $0x28,%esp
	filedesc *fd = filedesc_open(NULL, path, O_RDONLY, 0);
40002567:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
4000256e:	00 
4000256f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40002576:	00 
40002577:	8b 45 08             	mov    0x8(%ebp),%eax
4000257a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000257e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002585:	e8 a5 f3 ff ff       	call   4000192f <filedesc_open>
4000258a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (fd == NULL)
4000258d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002591:	75 0a                	jne    4000259d <opendir+0x3c>
		return NULL;
40002593:	b8 00 00 00 00       	mov    $0x0,%eax
40002598:	e9 bb 00 00 00       	jmp    40002658 <opendir+0xf7>

	// Make sure it's a directory
	assert(fileino_exists(fd->ino));
4000259d:	8b 45 f4             	mov    -0xc(%ebp),%eax
400025a0:	8b 00                	mov    (%eax),%eax
400025a2:	85 c0                	test   %eax,%eax
400025a4:	7e 44                	jle    400025ea <opendir+0x89>
400025a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
400025a9:	8b 00                	mov    (%eax),%eax
400025ab:	3d ff 00 00 00       	cmp    $0xff,%eax
400025b0:	7f 38                	jg     400025ea <opendir+0x89>
400025b2:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
400025b8:	8b 45 f4             	mov    -0xc(%ebp),%eax
400025bb:	8b 00                	mov    (%eax),%eax
400025bd:	6b c0 5c             	imul   $0x5c,%eax,%eax
400025c0:	01 d0                	add    %edx,%eax
400025c2:	05 10 10 00 00       	add    $0x1010,%eax
400025c7:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400025cb:	84 c0                	test   %al,%al
400025cd:	74 1b                	je     400025ea <opendir+0x89>
400025cf:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
400025d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
400025d8:	8b 00                	mov    (%eax),%eax
400025da:	6b c0 5c             	imul   $0x5c,%eax,%eax
400025dd:	01 d0                	add    %edx,%eax
400025df:	05 58 10 00 00       	add    $0x1058,%eax
400025e4:	8b 00                	mov    (%eax),%eax
400025e6:	85 c0                	test   %eax,%eax
400025e8:	75 24                	jne    4000260e <opendir+0xad>
400025ea:	c7 44 24 0c 66 3f 00 	movl   $0x40003f66,0xc(%esp)
400025f1:	40 
400025f2:	c7 44 24 08 e0 3e 00 	movl   $0x40003ee0,0x8(%esp)
400025f9:	40 
400025fa:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
40002601:	00 
40002602:	c7 04 24 f5 3e 00 40 	movl   $0x40003ef5,(%esp)
40002609:	e8 36 09 00 00       	call   40002f44 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
4000260e:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40002614:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002617:	8b 00                	mov    (%eax),%eax
40002619:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000261c:	05 10 10 00 00       	add    $0x1010,%eax
40002621:	01 d0                	add    %edx,%eax
40002623:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (!S_ISDIR(fi->mode)) {
40002626:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002629:	8b 40 48             	mov    0x48(%eax),%eax
4000262c:	25 00 70 00 00       	and    $0x7000,%eax
40002631:	3d 00 20 00 00       	cmp    $0x2000,%eax
40002636:	74 1d                	je     40002655 <opendir+0xf4>
		filedesc_close(fd);
40002638:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000263b:	89 04 24             	mov    %eax,(%esp)
4000263e:	e8 b1 f8 ff ff       	call   40001ef4 <filedesc_close>
		errno = ENOTDIR;
40002643:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002648:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
		return NULL;
4000264e:	b8 00 00 00 00       	mov    $0x0,%eax
40002653:	eb 03                	jmp    40002658 <opendir+0xf7>
	}

	return fd;
40002655:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
40002658:	c9                   	leave  
40002659:	c3                   	ret    

4000265a <closedir>:

int closedir(DIR *dir)
{
4000265a:	55                   	push   %ebp
4000265b:	89 e5                	mov    %esp,%ebp
4000265d:	83 ec 18             	sub    $0x18,%esp
	filedesc_close(dir);
40002660:	8b 45 08             	mov    0x8(%ebp),%eax
40002663:	89 04 24             	mov    %eax,(%esp)
40002666:	e8 89 f8 ff ff       	call   40001ef4 <filedesc_close>
	return 0;
4000266b:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002670:	c9                   	leave  
40002671:	c3                   	ret    

40002672 <readdir>:

// Scan an open directory filedesc and return the next entry.
// Returns a pointer to the next matching file inode's 'dirent' struct,
// or NULL if the directory being scanned contains no more entries.
struct dirent *readdir(DIR *dir)
{
40002672:	55                   	push   %ebp
40002673:	89 e5                	mov    %esp,%ebp
40002675:	83 ec 28             	sub    $0x28,%esp
	// Hint: a fileinode's 'dino' field indicates
	// what directory the file is in;
	// this function shouldn't return entries from other directories!
	//warn("readdir() not implemented");
	//return NULL;
	assert(fileino_isdir(dir->ino));
40002678:	8b 45 08             	mov    0x8(%ebp),%eax
4000267b:	8b 00                	mov    (%eax),%eax
4000267d:	85 c0                	test   %eax,%eax
4000267f:	7e 4c                	jle    400026cd <readdir+0x5b>
40002681:	8b 45 08             	mov    0x8(%ebp),%eax
40002684:	8b 00                	mov    (%eax),%eax
40002686:	3d ff 00 00 00       	cmp    $0xff,%eax
4000268b:	7f 40                	jg     400026cd <readdir+0x5b>
4000268d:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40002693:	8b 45 08             	mov    0x8(%ebp),%eax
40002696:	8b 00                	mov    (%eax),%eax
40002698:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000269b:	01 d0                	add    %edx,%eax
4000269d:	05 10 10 00 00       	add    $0x1010,%eax
400026a2:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400026a6:	84 c0                	test   %al,%al
400026a8:	74 23                	je     400026cd <readdir+0x5b>
400026aa:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
400026b0:	8b 45 08             	mov    0x8(%ebp),%eax
400026b3:	8b 00                	mov    (%eax),%eax
400026b5:	6b c0 5c             	imul   $0x5c,%eax,%eax
400026b8:	01 d0                	add    %edx,%eax
400026ba:	05 58 10 00 00       	add    $0x1058,%eax
400026bf:	8b 00                	mov    (%eax),%eax
400026c1:	25 00 70 00 00       	and    $0x7000,%eax
400026c6:	3d 00 20 00 00       	cmp    $0x2000,%eax
400026cb:	74 24                	je     400026f1 <readdir+0x7f>
400026cd:	c7 44 24 0c 7e 3f 00 	movl   $0x40003f7e,0xc(%esp)
400026d4:	40 
400026d5:	c7 44 24 08 e0 3e 00 	movl   $0x40003ee0,0x8(%esp)
400026dc:	40 
400026dd:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
400026e4:	00 
400026e5:	c7 04 24 f5 3e 00 40 	movl   $0x40003ef5,(%esp)
400026ec:	e8 53 08 00 00       	call   40002f44 <debug_panic>
	int i = dir->ofs;
400026f1:	8b 45 08             	mov    0x8(%ebp),%eax
400026f4:	8b 40 08             	mov    0x8(%eax),%eax
400026f7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	for(i; i < FILE_INODES; i++){
400026fa:	eb 3c                	jmp    40002738 <readdir+0xc6>
		fileinode* tmp_fi = &files->fi[i];
400026fc:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002701:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002704:	6b d2 5c             	imul   $0x5c,%edx,%edx
40002707:	81 c2 10 10 00 00    	add    $0x1010,%edx
4000270d:	01 d0                	add    %edx,%eax
4000270f:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if(tmp_fi->dino == dir->ino){
40002712:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002715:	8b 10                	mov    (%eax),%edx
40002717:	8b 45 08             	mov    0x8(%ebp),%eax
4000271a:	8b 00                	mov    (%eax),%eax
4000271c:	39 c2                	cmp    %eax,%edx
4000271e:	75 14                	jne    40002734 <readdir+0xc2>
			dir->ofs = i+1;
40002720:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002723:	8d 50 01             	lea    0x1(%eax),%edx
40002726:	8b 45 08             	mov    0x8(%ebp),%eax
40002729:	89 50 08             	mov    %edx,0x8(%eax)
			return &tmp_fi->de;
4000272c:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000272f:	83 c0 04             	add    $0x4,%eax
40002732:	eb 1c                	jmp    40002750 <readdir+0xde>
	// this function shouldn't return entries from other directories!
	//warn("readdir() not implemented");
	//return NULL;
	assert(fileino_isdir(dir->ino));
	int i = dir->ofs;
	for(i; i < FILE_INODES; i++){
40002734:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40002738:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
4000273f:	7e bb                	jle    400026fc <readdir+0x8a>
		if(tmp_fi->dino == dir->ino){
			dir->ofs = i+1;
			return &tmp_fi->de;
		}
	}
	dir->ofs = 0;
40002741:	8b 45 08             	mov    0x8(%ebp),%eax
40002744:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
	return NULL;
4000274b:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002750:	c9                   	leave  
40002751:	c3                   	ret    

40002752 <rewinddir>:

void rewinddir(DIR *dir)
{
40002752:	55                   	push   %ebp
40002753:	89 e5                	mov    %esp,%ebp
	dir->ofs = 0;
40002755:	8b 45 08             	mov    0x8(%ebp),%eax
40002758:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
4000275f:	5d                   	pop    %ebp
40002760:	c3                   	ret    

40002761 <seekdir>:

void seekdir(DIR *dir, long ofs)
{
40002761:	55                   	push   %ebp
40002762:	89 e5                	mov    %esp,%ebp
	dir->ofs = ofs;
40002764:	8b 45 08             	mov    0x8(%ebp),%eax
40002767:	8b 55 0c             	mov    0xc(%ebp),%edx
4000276a:	89 50 08             	mov    %edx,0x8(%eax)
}
4000276d:	5d                   	pop    %ebp
4000276e:	c3                   	ret    

4000276f <telldir>:

long telldir(DIR *dir)
{
4000276f:	55                   	push   %ebp
40002770:	89 e5                	mov    %esp,%ebp
	return dir->ofs;
40002772:	8b 45 08             	mov    0x8(%ebp),%eax
40002775:	8b 40 08             	mov    0x8(%eax),%eax
}
40002778:	5d                   	pop    %ebp
40002779:	c3                   	ret    
4000277a:	66 90                	xchg   %ax,%ax

4000277c <exit>:
#include <inc/assert.h>
#include <inc/string.h>

void gcc_noreturn
exit(int status)
{
4000277c:	55                   	push   %ebp
4000277d:	89 e5                	mov    %esp,%ebp
4000277f:	83 ec 18             	sub    $0x18,%esp
	// To exit a PIOS user process, by convention,
	// we just set our exit status in our filestate area
	// and return to our parent process.
	files->status = status;
40002782:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002787:	8b 55 08             	mov    0x8(%ebp),%edx
4000278a:	89 50 0c             	mov    %edx,0xc(%eax)
	files->exited = 1;
4000278d:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002792:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
40002799:	b8 03 00 00 00       	mov    $0x3,%eax
4000279e:	cd 30                	int    $0x30
	sys_ret();
	panic("exit: sys_ret shouldn't have returned");
400027a0:	c7 44 24 08 98 3f 00 	movl   $0x40003f98,0x8(%esp)
400027a7:	40 
400027a8:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
400027af:	00 
400027b0:	c7 04 24 be 3f 00 40 	movl   $0x40003fbe,(%esp)
400027b7:	e8 88 07 00 00       	call   40002f44 <debug_panic>

400027bc <abort>:
}

void gcc_noreturn
abort(void)
{
400027bc:	55                   	push   %ebp
400027bd:	89 e5                	mov    %esp,%ebp
400027bf:	83 ec 18             	sub    $0x18,%esp
	exit(EXIT_FAILURE);
400027c2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
400027c9:	e8 ae ff ff ff       	call   4000277c <exit>
400027ce:	66 90                	xchg   %ax,%ax

400027d0 <creat>:
#include <inc/assert.h>
#include <inc/stdarg.h>

int
creat(const char *path, mode_t mode)
{
400027d0:	55                   	push   %ebp
400027d1:	89 e5                	mov    %esp,%ebp
400027d3:	83 ec 18             	sub    $0x18,%esp
	return open(path, O_CREAT | O_TRUNC | O_WRONLY, mode);
400027d6:	8b 45 0c             	mov    0xc(%ebp),%eax
400027d9:	89 44 24 08          	mov    %eax,0x8(%esp)
400027dd:	c7 44 24 04 62 00 00 	movl   $0x62,0x4(%esp)
400027e4:	00 
400027e5:	8b 45 08             	mov    0x8(%ebp),%eax
400027e8:	89 04 24             	mov    %eax,(%esp)
400027eb:	e8 02 00 00 00       	call   400027f2 <open>
}
400027f0:	c9                   	leave  
400027f1:	c3                   	ret    

400027f2 <open>:

int
open(const char *path, int flags, ...)
{
400027f2:	55                   	push   %ebp
400027f3:	89 e5                	mov    %esp,%ebp
400027f5:	83 ec 28             	sub    $0x28,%esp
	// Get the optional mode argument, which applies only with O_CREAT.
	mode_t mode = 0;
400027f8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	if (flags & O_CREAT) {
400027ff:	8b 45 0c             	mov    0xc(%ebp),%eax
40002802:	83 e0 20             	and    $0x20,%eax
40002805:	85 c0                	test   %eax,%eax
40002807:	74 18                	je     40002821 <open+0x2f>
		va_list ap;
		va_start(ap, flags);
40002809:	8d 45 0c             	lea    0xc(%ebp),%eax
4000280c:	83 c0 04             	add    $0x4,%eax
4000280f:	89 45 f0             	mov    %eax,-0x10(%ebp)
		mode = va_arg(ap, mode_t);
40002812:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
40002816:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002819:	83 e8 04             	sub    $0x4,%eax
4000281c:	8b 00                	mov    (%eax),%eax
4000281e:	89 45 f4             	mov    %eax,-0xc(%ebp)
		va_end(ap);
	}

	filedesc *fd = filedesc_open(NULL, path, flags, mode);
40002821:	8b 45 0c             	mov    0xc(%ebp),%eax
40002824:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002827:	89 54 24 0c          	mov    %edx,0xc(%esp)
4000282b:	89 44 24 08          	mov    %eax,0x8(%esp)
4000282f:	8b 45 08             	mov    0x8(%ebp),%eax
40002832:	89 44 24 04          	mov    %eax,0x4(%esp)
40002836:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000283d:	e8 ed f0 ff ff       	call   4000192f <filedesc_open>
40002842:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (fd == NULL)
40002845:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
40002849:	75 07                	jne    40002852 <open+0x60>
		return -1;
4000284b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002850:	eb 14                	jmp    40002866 <open+0x74>

	return fd - files->fd;
40002852:	8b 55 ec             	mov    -0x14(%ebp),%edx
40002855:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
4000285a:	83 c0 10             	add    $0x10,%eax
4000285d:	89 d1                	mov    %edx,%ecx
4000285f:	29 c1                	sub    %eax,%ecx
40002861:	89 c8                	mov    %ecx,%eax
40002863:	c1 f8 04             	sar    $0x4,%eax
}
40002866:	c9                   	leave  
40002867:	c3                   	ret    

40002868 <close>:

int
close(int fn)
{
40002868:	55                   	push   %ebp
40002869:	89 e5                	mov    %esp,%ebp
4000286b:	83 ec 18             	sub    $0x18,%esp
	filedesc_close(&files->fd[fn]);
4000286e:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002873:	8b 55 08             	mov    0x8(%ebp),%edx
40002876:	83 c2 01             	add    $0x1,%edx
40002879:	c1 e2 04             	shl    $0x4,%edx
4000287c:	01 d0                	add    %edx,%eax
4000287e:	89 04 24             	mov    %eax,(%esp)
40002881:	e8 6e f6 ff ff       	call   40001ef4 <filedesc_close>
	return 0;
40002886:	b8 00 00 00 00       	mov    $0x0,%eax
}
4000288b:	c9                   	leave  
4000288c:	c3                   	ret    

4000288d <read>:

ssize_t
read(int fn, void *buf, size_t nbytes)
{
4000288d:	55                   	push   %ebp
4000288e:	89 e5                	mov    %esp,%ebp
40002890:	83 ec 18             	sub    $0x18,%esp
	return filedesc_read(&files->fd[fn], buf, 1, nbytes);
40002893:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002898:	8b 55 08             	mov    0x8(%ebp),%edx
4000289b:	83 c2 01             	add    $0x1,%edx
4000289e:	c1 e2 04             	shl    $0x4,%edx
400028a1:	01 c2                	add    %eax,%edx
400028a3:	8b 45 10             	mov    0x10(%ebp),%eax
400028a6:	89 44 24 0c          	mov    %eax,0xc(%esp)
400028aa:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
400028b1:	00 
400028b2:	8b 45 0c             	mov    0xc(%ebp),%eax
400028b5:	89 44 24 04          	mov    %eax,0x4(%esp)
400028b9:	89 14 24             	mov    %edx,(%esp)
400028bc:	e8 98 f2 ff ff       	call   40001b59 <filedesc_read>
}
400028c1:	c9                   	leave  
400028c2:	c3                   	ret    

400028c3 <write>:

ssize_t
write(int fn, const void *buf, size_t nbytes)
{
400028c3:	55                   	push   %ebp
400028c4:	89 e5                	mov    %esp,%ebp
400028c6:	83 ec 18             	sub    $0x18,%esp
	return filedesc_write(&files->fd[fn], buf, 1, nbytes);
400028c9:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
400028ce:	8b 55 08             	mov    0x8(%ebp),%edx
400028d1:	83 c2 01             	add    $0x1,%edx
400028d4:	c1 e2 04             	shl    $0x4,%edx
400028d7:	01 c2                	add    %eax,%edx
400028d9:	8b 45 10             	mov    0x10(%ebp),%eax
400028dc:	89 44 24 0c          	mov    %eax,0xc(%esp)
400028e0:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
400028e7:	00 
400028e8:	8b 45 0c             	mov    0xc(%ebp),%eax
400028eb:	89 44 24 04          	mov    %eax,0x4(%esp)
400028ef:	89 14 24             	mov    %edx,(%esp)
400028f2:	e8 77 f3 ff ff       	call   40001c6e <filedesc_write>
}
400028f7:	c9                   	leave  
400028f8:	c3                   	ret    

400028f9 <lseek>:

off_t
lseek(int fn, off_t offset, int whence)
{
400028f9:	55                   	push   %ebp
400028fa:	89 e5                	mov    %esp,%ebp
400028fc:	83 ec 18             	sub    $0x18,%esp
	return filedesc_seek(&files->fd[fn], offset, whence);
400028ff:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002904:	8b 55 08             	mov    0x8(%ebp),%edx
40002907:	83 c2 01             	add    $0x1,%edx
4000290a:	c1 e2 04             	shl    $0x4,%edx
4000290d:	01 c2                	add    %eax,%edx
4000290f:	8b 45 10             	mov    0x10(%ebp),%eax
40002912:	89 44 24 08          	mov    %eax,0x8(%esp)
40002916:	8b 45 0c             	mov    0xc(%ebp),%eax
40002919:	89 44 24 04          	mov    %eax,0x4(%esp)
4000291d:	89 14 24             	mov    %edx,(%esp)
40002920:	e8 be f4 ff ff       	call   40001de3 <filedesc_seek>
}
40002925:	c9                   	leave  
40002926:	c3                   	ret    

40002927 <dup>:

int
dup(int oldfn)
{
40002927:	55                   	push   %ebp
40002928:	89 e5                	mov    %esp,%ebp
4000292a:	83 ec 28             	sub    $0x28,%esp
	filedesc *newfd = filedesc_alloc();
4000292d:	e8 a7 ef ff ff       	call   400018d9 <filedesc_alloc>
40002932:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (!newfd)
40002935:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002939:	75 07                	jne    40002942 <dup+0x1b>
		return -1;
4000293b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002940:	eb 23                	jmp    40002965 <dup+0x3e>
	return dup2(oldfn, newfd - files->fd);
40002942:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002945:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
4000294a:	83 c0 10             	add    $0x10,%eax
4000294d:	89 d1                	mov    %edx,%ecx
4000294f:	29 c1                	sub    %eax,%ecx
40002951:	89 c8                	mov    %ecx,%eax
40002953:	c1 f8 04             	sar    $0x4,%eax
40002956:	89 44 24 04          	mov    %eax,0x4(%esp)
4000295a:	8b 45 08             	mov    0x8(%ebp),%eax
4000295d:	89 04 24             	mov    %eax,(%esp)
40002960:	e8 02 00 00 00       	call   40002967 <dup2>
}
40002965:	c9                   	leave  
40002966:	c3                   	ret    

40002967 <dup2>:

int
dup2(int oldfn, int newfn)
{
40002967:	55                   	push   %ebp
40002968:	89 e5                	mov    %esp,%ebp
4000296a:	83 ec 28             	sub    $0x28,%esp
	filedesc *oldfd = &files->fd[oldfn];
4000296d:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002972:	8b 55 08             	mov    0x8(%ebp),%edx
40002975:	83 c2 01             	add    $0x1,%edx
40002978:	c1 e2 04             	shl    $0x4,%edx
4000297b:	01 d0                	add    %edx,%eax
4000297d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	filedesc *newfd = &files->fd[newfn];
40002980:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002985:	8b 55 0c             	mov    0xc(%ebp),%edx
40002988:	83 c2 01             	add    $0x1,%edx
4000298b:	c1 e2 04             	shl    $0x4,%edx
4000298e:	01 d0                	add    %edx,%eax
40002990:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(filedesc_isopen(oldfd));
40002993:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002998:	83 c0 10             	add    $0x10,%eax
4000299b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
4000299e:	77 18                	ja     400029b8 <dup2+0x51>
400029a0:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
400029a5:	05 10 10 00 00       	add    $0x1010,%eax
400029aa:	3b 45 f4             	cmp    -0xc(%ebp),%eax
400029ad:	76 09                	jbe    400029b8 <dup2+0x51>
400029af:	8b 45 f4             	mov    -0xc(%ebp),%eax
400029b2:	8b 00                	mov    (%eax),%eax
400029b4:	85 c0                	test   %eax,%eax
400029b6:	75 24                	jne    400029dc <dup2+0x75>
400029b8:	c7 44 24 0c cc 3f 00 	movl   $0x40003fcc,0xc(%esp)
400029bf:	40 
400029c0:	c7 44 24 08 e3 3f 00 	movl   $0x40003fe3,0x8(%esp)
400029c7:	40 
400029c8:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
400029cf:	00 
400029d0:	c7 04 24 f8 3f 00 40 	movl   $0x40003ff8,(%esp)
400029d7:	e8 68 05 00 00       	call   40002f44 <debug_panic>
	assert(filedesc_isvalid(newfd));
400029dc:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
400029e1:	83 c0 10             	add    $0x10,%eax
400029e4:	3b 45 f0             	cmp    -0x10(%ebp),%eax
400029e7:	77 0f                	ja     400029f8 <dup2+0x91>
400029e9:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
400029ee:	05 10 10 00 00       	add    $0x1010,%eax
400029f3:	3b 45 f0             	cmp    -0x10(%ebp),%eax
400029f6:	77 24                	ja     40002a1c <dup2+0xb5>
400029f8:	c7 44 24 0c 05 40 00 	movl   $0x40004005,0xc(%esp)
400029ff:	40 
40002a00:	c7 44 24 08 e3 3f 00 	movl   $0x40003fe3,0x8(%esp)
40002a07:	40 
40002a08:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
40002a0f:	00 
40002a10:	c7 04 24 f8 3f 00 40 	movl   $0x40003ff8,(%esp)
40002a17:	e8 28 05 00 00       	call   40002f44 <debug_panic>

	if (filedesc_isopen(newfd))
40002a1c:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002a21:	83 c0 10             	add    $0x10,%eax
40002a24:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40002a27:	77 23                	ja     40002a4c <dup2+0xe5>
40002a29:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002a2e:	05 10 10 00 00       	add    $0x1010,%eax
40002a33:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40002a36:	76 14                	jbe    40002a4c <dup2+0xe5>
40002a38:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002a3b:	8b 00                	mov    (%eax),%eax
40002a3d:	85 c0                	test   %eax,%eax
40002a3f:	74 0b                	je     40002a4c <dup2+0xe5>
		close(newfn);
40002a41:	8b 45 0c             	mov    0xc(%ebp),%eax
40002a44:	89 04 24             	mov    %eax,(%esp)
40002a47:	e8 1c fe ff ff       	call   40002868 <close>

	*newfd = *oldfd;
40002a4c:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002a4f:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002a52:	8b 0a                	mov    (%edx),%ecx
40002a54:	89 08                	mov    %ecx,(%eax)
40002a56:	8b 4a 04             	mov    0x4(%edx),%ecx
40002a59:	89 48 04             	mov    %ecx,0x4(%eax)
40002a5c:	8b 4a 08             	mov    0x8(%edx),%ecx
40002a5f:	89 48 08             	mov    %ecx,0x8(%eax)
40002a62:	8b 52 0c             	mov    0xc(%edx),%edx
40002a65:	89 50 0c             	mov    %edx,0xc(%eax)

	return newfn;
40002a68:	8b 45 0c             	mov    0xc(%ebp),%eax
}
40002a6b:	c9                   	leave  
40002a6c:	c3                   	ret    

40002a6d <truncate>:

int
truncate(const char *path, off_t newlength)
{
40002a6d:	55                   	push   %ebp
40002a6e:	89 e5                	mov    %esp,%ebp
40002a70:	83 ec 28             	sub    $0x28,%esp
	int ino = dir_walk(path, 0);
40002a73:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002a7a:	00 
40002a7b:	8b 45 08             	mov    0x8(%ebp),%eax
40002a7e:	89 04 24             	mov    %eax,(%esp)
40002a81:	e8 02 f5 ff ff       	call   40001f88 <dir_walk>
40002a86:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (ino < 0)
40002a89:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002a8d:	79 07                	jns    40002a96 <truncate+0x29>
		return -1;
40002a8f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002a94:	eb 12                	jmp    40002aa8 <truncate+0x3b>
	return fileino_truncate(ino, newlength);
40002a96:	8b 45 0c             	mov    0xc(%ebp),%eax
40002a99:	89 44 24 04          	mov    %eax,0x4(%esp)
40002a9d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002aa0:	89 04 24             	mov    %eax,(%esp)
40002aa3:	e8 3a eb ff ff       	call   400015e2 <fileino_truncate>
}
40002aa8:	c9                   	leave  
40002aa9:	c3                   	ret    

40002aaa <ftruncate>:

int
ftruncate(int fn, off_t newlength)
{
40002aaa:	55                   	push   %ebp
40002aab:	89 e5                	mov    %esp,%ebp
40002aad:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
40002ab0:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002ab5:	8b 55 08             	mov    0x8(%ebp),%edx
40002ab8:	83 c2 01             	add    $0x1,%edx
40002abb:	c1 e2 04             	shl    $0x4,%edx
40002abe:	01 c2                	add    %eax,%edx
40002ac0:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002ac5:	83 c0 10             	add    $0x10,%eax
40002ac8:	39 c2                	cmp    %eax,%edx
40002aca:	72 34                	jb     40002b00 <ftruncate+0x56>
40002acc:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002ad1:	8b 55 08             	mov    0x8(%ebp),%edx
40002ad4:	83 c2 01             	add    $0x1,%edx
40002ad7:	c1 e2 04             	shl    $0x4,%edx
40002ada:	01 c2                	add    %eax,%edx
40002adc:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002ae1:	05 10 10 00 00       	add    $0x1010,%eax
40002ae6:	39 c2                	cmp    %eax,%edx
40002ae8:	73 16                	jae    40002b00 <ftruncate+0x56>
40002aea:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002aef:	8b 55 08             	mov    0x8(%ebp),%edx
40002af2:	83 c2 01             	add    $0x1,%edx
40002af5:	c1 e2 04             	shl    $0x4,%edx
40002af8:	01 d0                	add    %edx,%eax
40002afa:	8b 00                	mov    (%eax),%eax
40002afc:	85 c0                	test   %eax,%eax
40002afe:	75 24                	jne    40002b24 <ftruncate+0x7a>
40002b00:	c7 44 24 0c 20 40 00 	movl   $0x40004020,0xc(%esp)
40002b07:	40 
40002b08:	c7 44 24 08 e3 3f 00 	movl   $0x40003fe3,0x8(%esp)
40002b0f:	40 
40002b10:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
40002b17:	00 
40002b18:	c7 04 24 f8 3f 00 40 	movl   $0x40003ff8,(%esp)
40002b1f:	e8 20 04 00 00       	call   40002f44 <debug_panic>
	return fileino_truncate(files->fd[fn].ino, newlength);
40002b24:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002b29:	8b 55 08             	mov    0x8(%ebp),%edx
40002b2c:	83 c2 01             	add    $0x1,%edx
40002b2f:	c1 e2 04             	shl    $0x4,%edx
40002b32:	01 d0                	add    %edx,%eax
40002b34:	8b 00                	mov    (%eax),%eax
40002b36:	8b 55 0c             	mov    0xc(%ebp),%edx
40002b39:	89 54 24 04          	mov    %edx,0x4(%esp)
40002b3d:	89 04 24             	mov    %eax,(%esp)
40002b40:	e8 9d ea ff ff       	call   400015e2 <fileino_truncate>
}
40002b45:	c9                   	leave  
40002b46:	c3                   	ret    

40002b47 <isatty>:

int
isatty(int fn)
{
40002b47:	55                   	push   %ebp
40002b48:	89 e5                	mov    %esp,%ebp
40002b4a:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
40002b4d:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002b52:	8b 55 08             	mov    0x8(%ebp),%edx
40002b55:	83 c2 01             	add    $0x1,%edx
40002b58:	c1 e2 04             	shl    $0x4,%edx
40002b5b:	01 c2                	add    %eax,%edx
40002b5d:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002b62:	83 c0 10             	add    $0x10,%eax
40002b65:	39 c2                	cmp    %eax,%edx
40002b67:	72 34                	jb     40002b9d <isatty+0x56>
40002b69:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002b6e:	8b 55 08             	mov    0x8(%ebp),%edx
40002b71:	83 c2 01             	add    $0x1,%edx
40002b74:	c1 e2 04             	shl    $0x4,%edx
40002b77:	01 c2                	add    %eax,%edx
40002b79:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002b7e:	05 10 10 00 00       	add    $0x1010,%eax
40002b83:	39 c2                	cmp    %eax,%edx
40002b85:	73 16                	jae    40002b9d <isatty+0x56>
40002b87:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002b8c:	8b 55 08             	mov    0x8(%ebp),%edx
40002b8f:	83 c2 01             	add    $0x1,%edx
40002b92:	c1 e2 04             	shl    $0x4,%edx
40002b95:	01 d0                	add    %edx,%eax
40002b97:	8b 00                	mov    (%eax),%eax
40002b99:	85 c0                	test   %eax,%eax
40002b9b:	75 24                	jne    40002bc1 <isatty+0x7a>
40002b9d:	c7 44 24 0c 20 40 00 	movl   $0x40004020,0xc(%esp)
40002ba4:	40 
40002ba5:	c7 44 24 08 e3 3f 00 	movl   $0x40003fe3,0x8(%esp)
40002bac:	40 
40002bad:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
40002bb4:	00 
40002bb5:	c7 04 24 f8 3f 00 40 	movl   $0x40003ff8,(%esp)
40002bbc:	e8 83 03 00 00       	call   40002f44 <debug_panic>
	return files->fd[fn].ino == FILEINO_CONSIN
40002bc1:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002bc6:	8b 55 08             	mov    0x8(%ebp),%edx
40002bc9:	83 c2 01             	add    $0x1,%edx
40002bcc:	c1 e2 04             	shl    $0x4,%edx
40002bcf:	01 d0                	add    %edx,%eax
40002bd1:	8b 00                	mov    (%eax),%eax
		|| files->fd[fn].ino == FILEINO_CONSOUT;
40002bd3:	83 f8 01             	cmp    $0x1,%eax
40002bd6:	74 17                	je     40002bef <isatty+0xa8>
40002bd8:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002bdd:	8b 55 08             	mov    0x8(%ebp),%edx
40002be0:	83 c2 01             	add    $0x1,%edx
40002be3:	c1 e2 04             	shl    $0x4,%edx
40002be6:	01 d0                	add    %edx,%eax
40002be8:	8b 00                	mov    (%eax),%eax
40002bea:	83 f8 02             	cmp    $0x2,%eax
40002bed:	75 07                	jne    40002bf6 <isatty+0xaf>
40002bef:	b8 01 00 00 00       	mov    $0x1,%eax
40002bf4:	eb 05                	jmp    40002bfb <isatty+0xb4>
40002bf6:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002bfb:	c9                   	leave  
40002bfc:	c3                   	ret    

40002bfd <stat>:

int
stat(const char *path, struct stat *statbuf)
{
40002bfd:	55                   	push   %ebp
40002bfe:	89 e5                	mov    %esp,%ebp
40002c00:	83 ec 28             	sub    $0x28,%esp
	int ino = dir_walk(path, 0);
40002c03:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002c0a:	00 
40002c0b:	8b 45 08             	mov    0x8(%ebp),%eax
40002c0e:	89 04 24             	mov    %eax,(%esp)
40002c11:	e8 72 f3 ff ff       	call   40001f88 <dir_walk>
40002c16:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (ino < 0)
40002c19:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002c1d:	79 07                	jns    40002c26 <stat+0x29>
		return -1;
40002c1f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002c24:	eb 12                	jmp    40002c38 <stat+0x3b>
	return fileino_stat(ino, statbuf);
40002c26:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c29:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c2d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002c30:	89 04 24             	mov    %eax,(%esp)
40002c33:	e8 85 e8 ff ff       	call   400014bd <fileino_stat>
}
40002c38:	c9                   	leave  
40002c39:	c3                   	ret    

40002c3a <fstat>:

int
fstat(int fn, struct stat *statbuf)
{
40002c3a:	55                   	push   %ebp
40002c3b:	89 e5                	mov    %esp,%ebp
40002c3d:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
40002c40:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002c45:	8b 55 08             	mov    0x8(%ebp),%edx
40002c48:	83 c2 01             	add    $0x1,%edx
40002c4b:	c1 e2 04             	shl    $0x4,%edx
40002c4e:	01 c2                	add    %eax,%edx
40002c50:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002c55:	83 c0 10             	add    $0x10,%eax
40002c58:	39 c2                	cmp    %eax,%edx
40002c5a:	72 34                	jb     40002c90 <fstat+0x56>
40002c5c:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002c61:	8b 55 08             	mov    0x8(%ebp),%edx
40002c64:	83 c2 01             	add    $0x1,%edx
40002c67:	c1 e2 04             	shl    $0x4,%edx
40002c6a:	01 c2                	add    %eax,%edx
40002c6c:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002c71:	05 10 10 00 00       	add    $0x1010,%eax
40002c76:	39 c2                	cmp    %eax,%edx
40002c78:	73 16                	jae    40002c90 <fstat+0x56>
40002c7a:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002c7f:	8b 55 08             	mov    0x8(%ebp),%edx
40002c82:	83 c2 01             	add    $0x1,%edx
40002c85:	c1 e2 04             	shl    $0x4,%edx
40002c88:	01 d0                	add    %edx,%eax
40002c8a:	8b 00                	mov    (%eax),%eax
40002c8c:	85 c0                	test   %eax,%eax
40002c8e:	75 24                	jne    40002cb4 <fstat+0x7a>
40002c90:	c7 44 24 0c 20 40 00 	movl   $0x40004020,0xc(%esp)
40002c97:	40 
40002c98:	c7 44 24 08 e3 3f 00 	movl   $0x40003fe3,0x8(%esp)
40002c9f:	40 
40002ca0:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
40002ca7:	00 
40002ca8:	c7 04 24 f8 3f 00 40 	movl   $0x40003ff8,(%esp)
40002caf:	e8 90 02 00 00       	call   40002f44 <debug_panic>
	return fileino_stat(files->fd[fn].ino, statbuf);
40002cb4:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002cb9:	8b 55 08             	mov    0x8(%ebp),%edx
40002cbc:	83 c2 01             	add    $0x1,%edx
40002cbf:	c1 e2 04             	shl    $0x4,%edx
40002cc2:	01 d0                	add    %edx,%eax
40002cc4:	8b 00                	mov    (%eax),%eax
40002cc6:	8b 55 0c             	mov    0xc(%ebp),%edx
40002cc9:	89 54 24 04          	mov    %edx,0x4(%esp)
40002ccd:	89 04 24             	mov    %eax,(%esp)
40002cd0:	e8 e8 e7 ff ff       	call   400014bd <fileino_stat>
}
40002cd5:	c9                   	leave  
40002cd6:	c3                   	ret    

40002cd7 <fsync>:

int
fsync(int fn)
{
40002cd7:	55                   	push   %ebp
40002cd8:	89 e5                	mov    %esp,%ebp
40002cda:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
40002cdd:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002ce2:	8b 55 08             	mov    0x8(%ebp),%edx
40002ce5:	83 c2 01             	add    $0x1,%edx
40002ce8:	c1 e2 04             	shl    $0x4,%edx
40002ceb:	01 c2                	add    %eax,%edx
40002ced:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002cf2:	83 c0 10             	add    $0x10,%eax
40002cf5:	39 c2                	cmp    %eax,%edx
40002cf7:	72 34                	jb     40002d2d <fsync+0x56>
40002cf9:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002cfe:	8b 55 08             	mov    0x8(%ebp),%edx
40002d01:	83 c2 01             	add    $0x1,%edx
40002d04:	c1 e2 04             	shl    $0x4,%edx
40002d07:	01 c2                	add    %eax,%edx
40002d09:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002d0e:	05 10 10 00 00       	add    $0x1010,%eax
40002d13:	39 c2                	cmp    %eax,%edx
40002d15:	73 16                	jae    40002d2d <fsync+0x56>
40002d17:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002d1c:	8b 55 08             	mov    0x8(%ebp),%edx
40002d1f:	83 c2 01             	add    $0x1,%edx
40002d22:	c1 e2 04             	shl    $0x4,%edx
40002d25:	01 d0                	add    %edx,%eax
40002d27:	8b 00                	mov    (%eax),%eax
40002d29:	85 c0                	test   %eax,%eax
40002d2b:	75 24                	jne    40002d51 <fsync+0x7a>
40002d2d:	c7 44 24 0c 20 40 00 	movl   $0x40004020,0xc(%esp)
40002d34:	40 
40002d35:	c7 44 24 08 e3 3f 00 	movl   $0x40003fe3,0x8(%esp)
40002d3c:	40 
40002d3d:	c7 44 24 04 87 00 00 	movl   $0x87,0x4(%esp)
40002d44:	00 
40002d45:	c7 04 24 f8 3f 00 40 	movl   $0x40003ff8,(%esp)
40002d4c:	e8 f3 01 00 00       	call   40002f44 <debug_panic>
	return fileino_flush(files->fd[fn].ino);
40002d51:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40002d56:	8b 55 08             	mov    0x8(%ebp),%edx
40002d59:	83 c2 01             	add    $0x1,%edx
40002d5c:	c1 e2 04             	shl    $0x4,%edx
40002d5f:	01 d0                	add    %edx,%eax
40002d61:	8b 00                	mov    (%eax),%eax
40002d63:	89 04 24             	mov    %eax,(%esp)
40002d66:	e8 f9 ea ff ff       	call   40001864 <fileino_flush>
}
40002d6b:	c9                   	leave  
40002d6c:	c3                   	ret    
40002d6d:	66 90                	xchg   %ax,%ax
40002d6f:	90                   	nop

40002d70 <writebuf>:
};


static void
writebuf(struct printbuf *b)
{
40002d70:	55                   	push   %ebp
40002d71:	89 e5                	mov    %esp,%ebp
40002d73:	83 ec 28             	sub    $0x28,%esp
	if (!b->err) {
40002d76:	8b 45 08             	mov    0x8(%ebp),%eax
40002d79:	8b 40 0c             	mov    0xc(%eax),%eax
40002d7c:	85 c0                	test   %eax,%eax
40002d7e:	75 56                	jne    40002dd6 <writebuf+0x66>
		size_t result = fwrite(b->buf, 1, b->idx, b->fh);
40002d80:	8b 45 08             	mov    0x8(%ebp),%eax
40002d83:	8b 10                	mov    (%eax),%edx
40002d85:	8b 45 08             	mov    0x8(%ebp),%eax
40002d88:	8b 40 04             	mov    0x4(%eax),%eax
40002d8b:	8b 4d 08             	mov    0x8(%ebp),%ecx
40002d8e:	83 c1 10             	add    $0x10,%ecx
40002d91:	89 54 24 0c          	mov    %edx,0xc(%esp)
40002d95:	89 44 24 08          	mov    %eax,0x8(%esp)
40002d99:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40002da0:	00 
40002da1:	89 0c 24             	mov    %ecx,(%esp)
40002da4:	e8 b5 05 00 00       	call   4000335e <fwrite>
40002da9:	89 45 f4             	mov    %eax,-0xc(%ebp)
		b->result += result;
40002dac:	8b 45 08             	mov    0x8(%ebp),%eax
40002daf:	8b 40 08             	mov    0x8(%eax),%eax
40002db2:	89 c2                	mov    %eax,%edx
40002db4:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002db7:	01 d0                	add    %edx,%eax
40002db9:	89 c2                	mov    %eax,%edx
40002dbb:	8b 45 08             	mov    0x8(%ebp),%eax
40002dbe:	89 50 08             	mov    %edx,0x8(%eax)
		if (result != b->idx) // error, or wrote less than supplied
40002dc1:	8b 45 08             	mov    0x8(%ebp),%eax
40002dc4:	8b 40 04             	mov    0x4(%eax),%eax
40002dc7:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40002dca:	74 0a                	je     40002dd6 <writebuf+0x66>
			b->err = 1;
40002dcc:	8b 45 08             	mov    0x8(%ebp),%eax
40002dcf:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
	}
}
40002dd6:	c9                   	leave  
40002dd7:	c3                   	ret    

40002dd8 <putch>:

static void
putch(int ch, void *thunk)
{
40002dd8:	55                   	push   %ebp
40002dd9:	89 e5                	mov    %esp,%ebp
40002ddb:	83 ec 28             	sub    $0x28,%esp
	struct printbuf *b = (struct printbuf *) thunk;
40002dde:	8b 45 0c             	mov    0xc(%ebp),%eax
40002de1:	89 45 f4             	mov    %eax,-0xc(%ebp)
	b->buf[b->idx++] = ch;
40002de4:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002de7:	8b 40 04             	mov    0x4(%eax),%eax
40002dea:	8b 55 08             	mov    0x8(%ebp),%edx
40002ded:	89 d1                	mov    %edx,%ecx
40002def:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002df2:	88 4c 02 10          	mov    %cl,0x10(%edx,%eax,1)
40002df6:	8d 50 01             	lea    0x1(%eax),%edx
40002df9:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002dfc:	89 50 04             	mov    %edx,0x4(%eax)
	if (b->idx == 256) {
40002dff:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002e02:	8b 40 04             	mov    0x4(%eax),%eax
40002e05:	3d 00 01 00 00       	cmp    $0x100,%eax
40002e0a:	75 15                	jne    40002e21 <putch+0x49>
		writebuf(b);
40002e0c:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002e0f:	89 04 24             	mov    %eax,(%esp)
40002e12:	e8 59 ff ff ff       	call   40002d70 <writebuf>
		b->idx = 0;
40002e17:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002e1a:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	}
}
40002e21:	c9                   	leave  
40002e22:	c3                   	ret    

40002e23 <vfprintf>:

int
vfprintf(FILE *fh, const char *fmt, va_list ap)
{
40002e23:	55                   	push   %ebp
40002e24:	89 e5                	mov    %esp,%ebp
40002e26:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.fh = fh;
40002e2c:	8b 45 08             	mov    0x8(%ebp),%eax
40002e2f:	89 85 e8 fe ff ff    	mov    %eax,-0x118(%ebp)
	b.idx = 0;
40002e35:	c7 85 ec fe ff ff 00 	movl   $0x0,-0x114(%ebp)
40002e3c:	00 00 00 
	b.result = 0;
40002e3f:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
40002e46:	00 00 00 
	b.err = 0;
40002e49:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
40002e50:	00 00 00 
	vprintfmt(putch, &b, fmt, ap);
40002e53:	8b 45 10             	mov    0x10(%ebp),%eax
40002e56:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002e5a:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e5d:	89 44 24 08          	mov    %eax,0x8(%esp)
40002e61:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
40002e67:	89 44 24 04          	mov    %eax,0x4(%esp)
40002e6b:	c7 04 24 d8 2d 00 40 	movl   $0x40002dd8,(%esp)
40002e72:	e8 ca d8 ff ff       	call   40000741 <vprintfmt>
	if (b.idx > 0)
40002e77:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
40002e7d:	85 c0                	test   %eax,%eax
40002e7f:	7e 0e                	jle    40002e8f <vfprintf+0x6c>
		writebuf(&b);
40002e81:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
40002e87:	89 04 24             	mov    %eax,(%esp)
40002e8a:	e8 e1 fe ff ff       	call   40002d70 <writebuf>

	return b.result;
40002e8f:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
}
40002e95:	c9                   	leave  
40002e96:	c3                   	ret    

40002e97 <fprintf>:

int
fprintf(FILE *fh, const char *fmt, ...)
{
40002e97:	55                   	push   %ebp
40002e98:	89 e5                	mov    %esp,%ebp
40002e9a:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
40002e9d:	8d 45 0c             	lea    0xc(%ebp),%eax
40002ea0:	83 c0 04             	add    $0x4,%eax
40002ea3:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vfprintf(fh, fmt, ap);
40002ea6:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ea9:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002eac:	89 54 24 08          	mov    %edx,0x8(%esp)
40002eb0:	89 44 24 04          	mov    %eax,0x4(%esp)
40002eb4:	8b 45 08             	mov    0x8(%ebp),%eax
40002eb7:	89 04 24             	mov    %eax,(%esp)
40002eba:	e8 64 ff ff ff       	call   40002e23 <vfprintf>
40002ebf:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
40002ec2:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40002ec5:	c9                   	leave  
40002ec6:	c3                   	ret    

40002ec7 <printf>:

int
printf(const char *fmt, ...)
{
40002ec7:	55                   	push   %ebp
40002ec8:	89 e5                	mov    %esp,%ebp
40002eca:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
40002ecd:	8d 45 0c             	lea    0xc(%ebp),%eax
40002ed0:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vfprintf(stdout, fmt, ap);
40002ed3:	8b 55 08             	mov    0x8(%ebp),%edx
40002ed6:	a1 b8 41 00 40       	mov    0x400041b8,%eax
40002edb:	8b 4d f4             	mov    -0xc(%ebp),%ecx
40002ede:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40002ee2:	89 54 24 04          	mov    %edx,0x4(%esp)
40002ee6:	89 04 24             	mov    %eax,(%esp)
40002ee9:	e8 35 ff ff ff       	call   40002e23 <vfprintf>
40002eee:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
40002ef1:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40002ef4:	c9                   	leave  
40002ef5:	c3                   	ret    
40002ef6:	66 90                	xchg   %ax,%ax

40002ef8 <strerror>:
#include <inc/stdio.h>

char *
strerror(int err)
{
40002ef8:	55                   	push   %ebp
40002ef9:	89 e5                	mov    %esp,%ebp
40002efb:	83 ec 28             	sub    $0x28,%esp
		"No child processes",
		"Conflict detected",
	};
	static char errbuf[64];

	const int tablen = sizeof(errtab)/sizeof(errtab[0]);
40002efe:	c7 45 f4 0b 00 00 00 	movl   $0xb,-0xc(%ebp)
	if (err >= 0 && err < sizeof(errtab)/sizeof(errtab[0]))
40002f05:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40002f09:	78 14                	js     40002f1f <strerror+0x27>
40002f0b:	8b 45 08             	mov    0x8(%ebp),%eax
40002f0e:	83 f8 0a             	cmp    $0xa,%eax
40002f11:	77 0c                	ja     40002f1f <strerror+0x27>
		return errtab[err];
40002f13:	8b 45 08             	mov    0x8(%ebp),%eax
40002f16:	8b 04 85 00 50 00 40 	mov    0x40005000(,%eax,4),%eax
40002f1d:	eb 20                	jmp    40002f3f <strerror+0x47>

	sprintf(errbuf, "Unknown error code %d", err);
40002f1f:	8b 45 08             	mov    0x8(%ebp),%eax
40002f22:	89 44 24 08          	mov    %eax,0x8(%esp)
40002f26:	c7 44 24 04 40 40 00 	movl   $0x40004040,0x4(%esp)
40002f2d:	40 
40002f2e:	c7 04 24 40 50 00 40 	movl   $0x40005040,(%esp)
40002f35:	e8 8f 07 00 00       	call   400036c9 <sprintf>
	return errbuf;
40002f3a:	b8 40 50 00 40       	mov    $0x40005040,%eax
}
40002f3f:	c9                   	leave  
40002f40:	c3                   	ret    
40002f41:	66 90                	xchg   %ax,%ax
40002f43:	90                   	nop

40002f44 <debug_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: <message>", then causes a breakpoint exception.
 */
void
debug_panic(const char *file, int line, const char *fmt,...)
{
40002f44:	55                   	push   %ebp
40002f45:	89 e5                	mov    %esp,%ebp
40002f47:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	va_start(ap, fmt);
40002f4a:	8d 45 10             	lea    0x10(%ebp),%eax
40002f4d:	83 c0 04             	add    $0x4,%eax
40002f50:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Print the panic message
	if (argv0)
40002f53:	a1 80 52 00 40       	mov    0x40005280,%eax
40002f58:	85 c0                	test   %eax,%eax
40002f5a:	74 15                	je     40002f71 <debug_panic+0x2d>
		cprintf("%s: ", argv0);
40002f5c:	a1 80 52 00 40       	mov    0x40005280,%eax
40002f61:	89 44 24 04          	mov    %eax,0x4(%esp)
40002f65:	c7 04 24 34 41 00 40 	movl   $0x40004134,(%esp)
40002f6c:	e8 87 d4 ff ff       	call   400003f8 <cprintf>
	cprintf("user panic at %s:%d: ", file, line);
40002f71:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f74:	89 44 24 08          	mov    %eax,0x8(%esp)
40002f78:	8b 45 08             	mov    0x8(%ebp),%eax
40002f7b:	89 44 24 04          	mov    %eax,0x4(%esp)
40002f7f:	c7 04 24 39 41 00 40 	movl   $0x40004139,(%esp)
40002f86:	e8 6d d4 ff ff       	call   400003f8 <cprintf>
	vcprintf(fmt, ap);
40002f8b:	8b 45 10             	mov    0x10(%ebp),%eax
40002f8e:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002f91:	89 54 24 04          	mov    %edx,0x4(%esp)
40002f95:	89 04 24             	mov    %eax,(%esp)
40002f98:	e8 f3 d3 ff ff       	call   40000390 <vcprintf>
	cprintf("\n");
40002f9d:	c7 04 24 4f 41 00 40 	movl   $0x4000414f,(%esp)
40002fa4:	e8 4f d4 ff ff       	call   400003f8 <cprintf>

	abort();
40002fa9:	e8 0e f8 ff ff       	call   400027bc <abort>

40002fae <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
40002fae:	55                   	push   %ebp
40002faf:	89 e5                	mov    %esp,%ebp
40002fb1:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
40002fb4:	8d 45 10             	lea    0x10(%ebp),%eax
40002fb7:	83 c0 04             	add    $0x4,%eax
40002fba:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("user warning at %s:%d: ", file, line);
40002fbd:	8b 45 0c             	mov    0xc(%ebp),%eax
40002fc0:	89 44 24 08          	mov    %eax,0x8(%esp)
40002fc4:	8b 45 08             	mov    0x8(%ebp),%eax
40002fc7:	89 44 24 04          	mov    %eax,0x4(%esp)
40002fcb:	c7 04 24 51 41 00 40 	movl   $0x40004151,(%esp)
40002fd2:	e8 21 d4 ff ff       	call   400003f8 <cprintf>
	vcprintf(fmt, ap);
40002fd7:	8b 45 10             	mov    0x10(%ebp),%eax
40002fda:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002fdd:	89 54 24 04          	mov    %edx,0x4(%esp)
40002fe1:	89 04 24             	mov    %eax,(%esp)
40002fe4:	e8 a7 d3 ff ff       	call   40000390 <vcprintf>
	cprintf("\n");
40002fe9:	c7 04 24 4f 41 00 40 	movl   $0x4000414f,(%esp)
40002ff0:	e8 03 d4 ff ff       	call   400003f8 <cprintf>
	va_end(ap);
}
40002ff5:	c9                   	leave  
40002ff6:	c3                   	ret    

40002ff7 <debug_dump>:

// Dump a block of memory as 32-bit words and ASCII bytes
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
40002ff7:	55                   	push   %ebp
40002ff8:	89 e5                	mov    %esp,%ebp
40002ffa:	56                   	push   %esi
40002ffb:	53                   	push   %ebx
40002ffc:	81 ec a0 00 00 00    	sub    $0xa0,%esp
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
40003002:	8b 55 14             	mov    0x14(%ebp),%edx
40003005:	8b 45 10             	mov    0x10(%ebp),%eax
40003008:	01 d0                	add    %edx,%eax
4000300a:	89 44 24 10          	mov    %eax,0x10(%esp)
4000300e:	8b 45 10             	mov    0x10(%ebp),%eax
40003011:	89 44 24 0c          	mov    %eax,0xc(%esp)
40003015:	8b 45 0c             	mov    0xc(%ebp),%eax
40003018:	89 44 24 08          	mov    %eax,0x8(%esp)
4000301c:	8b 45 08             	mov    0x8(%ebp),%eax
4000301f:	89 44 24 04          	mov    %eax,0x4(%esp)
40003023:	c7 04 24 6c 41 00 40 	movl   $0x4000416c,(%esp)
4000302a:	e8 c9 d3 ff ff       	call   400003f8 <cprintf>
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
4000302f:	8b 45 14             	mov    0x14(%ebp),%eax
40003032:	83 c0 0f             	add    $0xf,%eax
40003035:	83 e0 f0             	and    $0xfffffff0,%eax
40003038:	89 45 14             	mov    %eax,0x14(%ebp)
4000303b:	e9 bb 00 00 00       	jmp    400030fb <debug_dump+0x104>
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
40003040:	8b 45 10             	mov    0x10(%ebp),%eax
40003043:	89 45 f0             	mov    %eax,-0x10(%ebp)
		for (i = 0; i < 16; i++)
40003046:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
4000304d:	eb 4d                	jmp    4000309c <debug_dump+0xa5>
			buf[i] = isprint(c[i]) ? c[i] : '.';
4000304f:	8b 55 f4             	mov    -0xc(%ebp),%edx
40003052:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003055:	01 d0                	add    %edx,%eax
40003057:	0f b6 00             	movzbl (%eax),%eax
4000305a:	0f b6 c0             	movzbl %al,%eax
4000305d:	89 45 e8             	mov    %eax,-0x18(%ebp)
static gcc_inline int isalnum(int c)	{ return isalpha(c) || isdigit(c); }
static gcc_inline int iscntrl(int c)	{ return c < ' '; }
static gcc_inline int isblank(int c)	{ return c == ' ' || c == '\t'; }
static gcc_inline int isspace(int c)	{ return c == ' '
						|| (c >= '\t' && c <= '\r'); }
static gcc_inline int isprint(int c)	{ return c >= ' ' && c <= '~'; }
40003060:	83 7d e8 1f          	cmpl   $0x1f,-0x18(%ebp)
40003064:	7e 0d                	jle    40003073 <debug_dump+0x7c>
40003066:	83 7d e8 7e          	cmpl   $0x7e,-0x18(%ebp)
4000306a:	7f 07                	jg     40003073 <debug_dump+0x7c>
4000306c:	b8 01 00 00 00       	mov    $0x1,%eax
40003071:	eb 05                	jmp    40003078 <debug_dump+0x81>
40003073:	b8 00 00 00 00       	mov    $0x0,%eax
40003078:	85 c0                	test   %eax,%eax
4000307a:	74 0d                	je     40003089 <debug_dump+0x92>
4000307c:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000307f:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003082:	01 d0                	add    %edx,%eax
40003084:	0f b6 00             	movzbl (%eax),%eax
40003087:	eb 05                	jmp    4000308e <debug_dump+0x97>
40003089:	b8 2e 00 00 00       	mov    $0x2e,%eax
4000308e:	8d 4d 84             	lea    -0x7c(%ebp),%ecx
40003091:	8b 55 f4             	mov    -0xc(%ebp),%edx
40003094:	01 ca                	add    %ecx,%edx
40003096:	88 02                	mov    %al,(%edx)
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
		for (i = 0; i < 16; i++)
40003098:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
4000309c:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
400030a0:	7e ad                	jle    4000304f <debug_dump+0x58>
			buf[i] = isprint(c[i]) ? c[i] : '.';
		buf[16] = 0;
400030a2:	c6 45 94 00          	movb   $0x0,-0x6c(%ebp)

		// Hex words
		const uint32_t *v = ptr;
400030a6:	8b 45 10             	mov    0x10(%ebp),%eax
400030a9:	89 45 ec             	mov    %eax,-0x14(%ebp)

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
			ptr, v[0], v[1], v[2], v[3], buf);
400030ac:	8b 45 ec             	mov    -0x14(%ebp),%eax
400030af:	83 c0 0c             	add    $0xc,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
400030b2:	8b 18                	mov    (%eax),%ebx
			ptr, v[0], v[1], v[2], v[3], buf);
400030b4:	8b 45 ec             	mov    -0x14(%ebp),%eax
400030b7:	83 c0 08             	add    $0x8,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
400030ba:	8b 08                	mov    (%eax),%ecx
			ptr, v[0], v[1], v[2], v[3], buf);
400030bc:	8b 45 ec             	mov    -0x14(%ebp),%eax
400030bf:	83 c0 04             	add    $0x4,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
400030c2:	8b 10                	mov    (%eax),%edx
400030c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
400030c7:	8b 00                	mov    (%eax),%eax
			ptr, v[0], v[1], v[2], v[3], buf);
400030c9:	8d 75 84             	lea    -0x7c(%ebp),%esi
400030cc:	89 74 24 18          	mov    %esi,0x18(%esp)

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
400030d0:	89 5c 24 14          	mov    %ebx,0x14(%esp)
400030d4:	89 4c 24 10          	mov    %ecx,0x10(%esp)
400030d8:	89 54 24 0c          	mov    %edx,0xc(%esp)
400030dc:	89 44 24 08          	mov    %eax,0x8(%esp)
400030e0:	8b 45 10             	mov    0x10(%ebp),%eax
400030e3:	89 44 24 04          	mov    %eax,0x4(%esp)
400030e7:	c7 04 24 95 41 00 40 	movl   $0x40004195,(%esp)
400030ee:	e8 05 d3 ff ff       	call   400003f8 <cprintf>
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
400030f3:	83 6d 14 10          	subl   $0x10,0x14(%ebp)
400030f7:	83 45 10 10          	addl   $0x10,0x10(%ebp)
400030fb:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
400030ff:	0f 8f 3b ff ff ff    	jg     40003040 <debug_dump+0x49>

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
			ptr, v[0], v[1], v[2], v[3], buf);
	}
}
40003105:	81 c4 a0 00 00 00    	add    $0xa0,%esp
4000310b:	5b                   	pop    %ebx
4000310c:	5e                   	pop    %esi
4000310d:	5d                   	pop    %ebp
4000310e:	c3                   	ret    
4000310f:	90                   	nop

40003110 <cputs>:

#include <inc/stdio.h>
#include <inc/syscall.h>

void cputs(const char *str)
{
40003110:	55                   	push   %ebp
40003111:	89 e5                	mov    %esp,%ebp
40003113:	53                   	push   %ebx
40003114:	83 ec 10             	sub    $0x10,%esp
40003117:	8b 45 08             	mov    0x8(%ebp),%eax
4000311a:	89 45 f8             	mov    %eax,-0x8(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
4000311d:	b8 00 00 00 00       	mov    $0x0,%eax
40003122:	8b 55 f8             	mov    -0x8(%ebp),%edx
40003125:	89 d3                	mov    %edx,%ebx
40003127:	cd 30                	int    $0x30
	sys_cputs(str);
}
40003129:	83 c4 10             	add    $0x10,%esp
4000312c:	5b                   	pop    %ebx
4000312d:	5d                   	pop    %ebp
4000312e:	c3                   	ret    
4000312f:	90                   	nop

40003130 <fopen>:
FILE *const stdout = &FILES->fd[1];
FILE *const stderr = &FILES->fd[2];

FILE *
fopen(const char *path, const char *mode)
{
40003130:	55                   	push   %ebp
40003131:	89 e5                	mov    %esp,%ebp
40003133:	83 ec 28             	sub    $0x28,%esp
	// Find an unused file descriptor and use it for the open
	FILE *fd = filedesc_alloc();
40003136:	e8 9e e7 ff ff       	call   400018d9 <filedesc_alloc>
4000313b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (fd == NULL)
4000313e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40003142:	75 07                	jne    4000314b <fopen+0x1b>
		return NULL;
40003144:	b8 00 00 00 00       	mov    $0x0,%eax
40003149:	eb 19                	jmp    40003164 <fopen+0x34>

	return freopen(path, mode, fd);
4000314b:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000314e:	89 44 24 08          	mov    %eax,0x8(%esp)
40003152:	8b 45 0c             	mov    0xc(%ebp),%eax
40003155:	89 44 24 04          	mov    %eax,0x4(%esp)
40003159:	8b 45 08             	mov    0x8(%ebp),%eax
4000315c:	89 04 24             	mov    %eax,(%esp)
4000315f:	e8 02 00 00 00       	call   40003166 <freopen>
}
40003164:	c9                   	leave  
40003165:	c3                   	ret    

40003166 <freopen>:

FILE *
freopen(const char *path, const char *mode, FILE *fd)
{
40003166:	55                   	push   %ebp
40003167:	89 e5                	mov    %esp,%ebp
40003169:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isvalid(fd));
4000316c:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40003171:	83 c0 10             	add    $0x10,%eax
40003174:	3b 45 10             	cmp    0x10(%ebp),%eax
40003177:	77 0f                	ja     40003188 <freopen+0x22>
40003179:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
4000317e:	05 10 10 00 00       	add    $0x1010,%eax
40003183:	3b 45 10             	cmp    0x10(%ebp),%eax
40003186:	77 24                	ja     400031ac <freopen+0x46>
40003188:	c7 44 24 0c c0 41 00 	movl   $0x400041c0,0xc(%esp)
4000318f:	40 
40003190:	c7 44 24 08 d5 41 00 	movl   $0x400041d5,0x8(%esp)
40003197:	40 
40003198:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
4000319f:	00 
400031a0:	c7 04 24 ea 41 00 40 	movl   $0x400041ea,(%esp)
400031a7:	e8 98 fd ff ff       	call   40002f44 <debug_panic>
	if (filedesc_isopen(fd))
400031ac:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
400031b1:	83 c0 10             	add    $0x10,%eax
400031b4:	3b 45 10             	cmp    0x10(%ebp),%eax
400031b7:	77 23                	ja     400031dc <freopen+0x76>
400031b9:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
400031be:	05 10 10 00 00       	add    $0x1010,%eax
400031c3:	3b 45 10             	cmp    0x10(%ebp),%eax
400031c6:	76 14                	jbe    400031dc <freopen+0x76>
400031c8:	8b 45 10             	mov    0x10(%ebp),%eax
400031cb:	8b 00                	mov    (%eax),%eax
400031cd:	85 c0                	test   %eax,%eax
400031cf:	74 0b                	je     400031dc <freopen+0x76>
		fclose(fd);
400031d1:	8b 45 10             	mov    0x10(%ebp),%eax
400031d4:	89 04 24             	mov    %eax,(%esp)
400031d7:	e8 b4 00 00 00       	call   40003290 <fclose>

	// Parse the open mode string
	int flags;
	switch (*mode++) {
400031dc:	8b 45 0c             	mov    0xc(%ebp),%eax
400031df:	0f b6 00             	movzbl (%eax),%eax
400031e2:	0f be c0             	movsbl %al,%eax
400031e5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
400031e9:	83 f8 72             	cmp    $0x72,%eax
400031ec:	74 0c                	je     400031fa <freopen+0x94>
400031ee:	83 f8 77             	cmp    $0x77,%eax
400031f1:	74 10                	je     40003203 <freopen+0x9d>
400031f3:	83 f8 61             	cmp    $0x61,%eax
400031f6:	74 14                	je     4000320c <freopen+0xa6>
400031f8:	eb 1b                	jmp    40003215 <freopen+0xaf>
	case 'r':	flags = O_RDONLY; break;
400031fa:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
40003201:	eb 3f                	jmp    40003242 <freopen+0xdc>
	case 'w':	flags = O_WRONLY | O_CREAT | O_TRUNC; break;
40003203:	c7 45 f4 62 00 00 00 	movl   $0x62,-0xc(%ebp)
4000320a:	eb 36                	jmp    40003242 <freopen+0xdc>
	case 'a':	flags = O_WRONLY | O_CREAT | O_APPEND; break;
4000320c:	c7 45 f4 32 00 00 00 	movl   $0x32,-0xc(%ebp)
40003213:	eb 2d                	jmp    40003242 <freopen+0xdc>
	default:	panic("freopen: unknown file mode '%c'\n", *--mode);
40003215:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
40003219:	8b 45 0c             	mov    0xc(%ebp),%eax
4000321c:	0f b6 00             	movzbl (%eax),%eax
4000321f:	0f be c0             	movsbl %al,%eax
40003222:	89 44 24 0c          	mov    %eax,0xc(%esp)
40003226:	c7 44 24 08 f8 41 00 	movl   $0x400041f8,0x8(%esp)
4000322d:	40 
4000322e:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
40003235:	00 
40003236:	c7 04 24 ea 41 00 40 	movl   $0x400041ea,(%esp)
4000323d:	e8 02 fd ff ff       	call   40002f44 <debug_panic>
	}
	if (*mode == 'b')	// binary flag - compatibility only
40003242:	8b 45 0c             	mov    0xc(%ebp),%eax
40003245:	0f b6 00             	movzbl (%eax),%eax
40003248:	3c 62                	cmp    $0x62,%al
4000324a:	75 04                	jne    40003250 <freopen+0xea>
		mode++;
4000324c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	if (*mode == '+')
40003250:	8b 45 0c             	mov    0xc(%ebp),%eax
40003253:	0f b6 00             	movzbl (%eax),%eax
40003256:	3c 2b                	cmp    $0x2b,%al
40003258:	75 04                	jne    4000325e <freopen+0xf8>
		flags |= O_RDWR;
4000325a:	83 4d f4 03          	orl    $0x3,-0xc(%ebp)

	if (filedesc_open(fd, path, flags, 0666) != fd)
4000325e:	c7 44 24 0c b6 01 00 	movl   $0x1b6,0xc(%esp)
40003265:	00 
40003266:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003269:	89 44 24 08          	mov    %eax,0x8(%esp)
4000326d:	8b 45 08             	mov    0x8(%ebp),%eax
40003270:	89 44 24 04          	mov    %eax,0x4(%esp)
40003274:	8b 45 10             	mov    0x10(%ebp),%eax
40003277:	89 04 24             	mov    %eax,(%esp)
4000327a:	e8 b0 e6 ff ff       	call   4000192f <filedesc_open>
4000327f:	3b 45 10             	cmp    0x10(%ebp),%eax
40003282:	74 07                	je     4000328b <freopen+0x125>
		return NULL;
40003284:	b8 00 00 00 00       	mov    $0x0,%eax
40003289:	eb 03                	jmp    4000328e <freopen+0x128>
	return fd;
4000328b:	8b 45 10             	mov    0x10(%ebp),%eax
}
4000328e:	c9                   	leave  
4000328f:	c3                   	ret    

40003290 <fclose>:

int
fclose(FILE *fd)
{
40003290:	55                   	push   %ebp
40003291:	89 e5                	mov    %esp,%ebp
40003293:	83 ec 18             	sub    $0x18,%esp
	filedesc_close(fd);
40003296:	8b 45 08             	mov    0x8(%ebp),%eax
40003299:	89 04 24             	mov    %eax,(%esp)
4000329c:	e8 53 ec ff ff       	call   40001ef4 <filedesc_close>
	return 0;
400032a1:	b8 00 00 00 00       	mov    $0x0,%eax
}
400032a6:	c9                   	leave  
400032a7:	c3                   	ret    

400032a8 <fgetc>:

int
fgetc(FILE *fd)
{
400032a8:	55                   	push   %ebp
400032a9:	89 e5                	mov    %esp,%ebp
400032ab:	83 ec 28             	sub    $0x28,%esp
	unsigned char ch;
	if (filedesc_read(fd, &ch, 1, 1) < 1)
400032ae:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
400032b5:	00 
400032b6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
400032bd:	00 
400032be:	8d 45 f7             	lea    -0x9(%ebp),%eax
400032c1:	89 44 24 04          	mov    %eax,0x4(%esp)
400032c5:	8b 45 08             	mov    0x8(%ebp),%eax
400032c8:	89 04 24             	mov    %eax,(%esp)
400032cb:	e8 89 e8 ff ff       	call   40001b59 <filedesc_read>
400032d0:	85 c0                	test   %eax,%eax
400032d2:	7f 07                	jg     400032db <fgetc+0x33>
		return EOF;
400032d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400032d9:	eb 07                	jmp    400032e2 <fgetc+0x3a>
	return ch;
400032db:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
400032df:	0f b6 c0             	movzbl %al,%eax
}
400032e2:	c9                   	leave  
400032e3:	c3                   	ret    

400032e4 <fputc>:

int
fputc(int c, FILE *fd)
{
400032e4:	55                   	push   %ebp
400032e5:	89 e5                	mov    %esp,%ebp
400032e7:	83 ec 28             	sub    $0x28,%esp
	unsigned char ch = c;
400032ea:	8b 45 08             	mov    0x8(%ebp),%eax
400032ed:	88 45 f7             	mov    %al,-0x9(%ebp)
	if (filedesc_write(fd, &ch, 1, 1) < 1)
400032f0:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
400032f7:	00 
400032f8:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
400032ff:	00 
40003300:	8d 45 f7             	lea    -0x9(%ebp),%eax
40003303:	89 44 24 04          	mov    %eax,0x4(%esp)
40003307:	8b 45 0c             	mov    0xc(%ebp),%eax
4000330a:	89 04 24             	mov    %eax,(%esp)
4000330d:	e8 5c e9 ff ff       	call   40001c6e <filedesc_write>
40003312:	85 c0                	test   %eax,%eax
40003314:	7f 07                	jg     4000331d <fputc+0x39>
		return EOF;
40003316:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
4000331b:	eb 07                	jmp    40003324 <fputc+0x40>
	return ch;
4000331d:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
40003321:	0f b6 c0             	movzbl %al,%eax
}
40003324:	c9                   	leave  
40003325:	c3                   	ret    

40003326 <fread>:

size_t
fread(void *buf, size_t eltsize, size_t count, FILE *fd)
{
40003326:	55                   	push   %ebp
40003327:	89 e5                	mov    %esp,%ebp
40003329:	83 ec 28             	sub    $0x28,%esp
	ssize_t actual = filedesc_read(fd, buf, eltsize, count);
4000332c:	8b 45 10             	mov    0x10(%ebp),%eax
4000332f:	89 44 24 0c          	mov    %eax,0xc(%esp)
40003333:	8b 45 0c             	mov    0xc(%ebp),%eax
40003336:	89 44 24 08          	mov    %eax,0x8(%esp)
4000333a:	8b 45 08             	mov    0x8(%ebp),%eax
4000333d:	89 44 24 04          	mov    %eax,0x4(%esp)
40003341:	8b 45 14             	mov    0x14(%ebp),%eax
40003344:	89 04 24             	mov    %eax,(%esp)
40003347:	e8 0d e8 ff ff       	call   40001b59 <filedesc_read>
4000334c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return actual >= 0 ? actual : 0;	// no error indication
4000334f:	b8 00 00 00 00       	mov    $0x0,%eax
40003354:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40003358:	0f 49 45 f4          	cmovns -0xc(%ebp),%eax
}
4000335c:	c9                   	leave  
4000335d:	c3                   	ret    

4000335e <fwrite>:

size_t
fwrite(const void *buf, size_t eltsize, size_t count, FILE *fd)
{
4000335e:	55                   	push   %ebp
4000335f:	89 e5                	mov    %esp,%ebp
40003361:	83 ec 28             	sub    $0x28,%esp
	ssize_t actual = filedesc_write(fd, buf, eltsize, count);
40003364:	8b 45 10             	mov    0x10(%ebp),%eax
40003367:	89 44 24 0c          	mov    %eax,0xc(%esp)
4000336b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000336e:	89 44 24 08          	mov    %eax,0x8(%esp)
40003372:	8b 45 08             	mov    0x8(%ebp),%eax
40003375:	89 44 24 04          	mov    %eax,0x4(%esp)
40003379:	8b 45 14             	mov    0x14(%ebp),%eax
4000337c:	89 04 24             	mov    %eax,(%esp)
4000337f:	e8 ea e8 ff ff       	call   40001c6e <filedesc_write>
40003384:	89 45 f4             	mov    %eax,-0xc(%ebp)

		
	return actual >= 0 ? actual : 0;	// no error indication
40003387:	b8 00 00 00 00       	mov    $0x0,%eax
4000338c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40003390:	0f 49 45 f4          	cmovns -0xc(%ebp),%eax
}
40003394:	c9                   	leave  
40003395:	c3                   	ret    

40003396 <fseek>:

int
fseek(FILE *fd, off_t offset, int whence)
{
40003396:	55                   	push   %ebp
40003397:	89 e5                	mov    %esp,%ebp
40003399:	83 ec 18             	sub    $0x18,%esp
	if (filedesc_seek(fd, offset, whence) < 0)
4000339c:	8b 45 10             	mov    0x10(%ebp),%eax
4000339f:	89 44 24 08          	mov    %eax,0x8(%esp)
400033a3:	8b 45 0c             	mov    0xc(%ebp),%eax
400033a6:	89 44 24 04          	mov    %eax,0x4(%esp)
400033aa:	8b 45 08             	mov    0x8(%ebp),%eax
400033ad:	89 04 24             	mov    %eax,(%esp)
400033b0:	e8 2e ea ff ff       	call   40001de3 <filedesc_seek>
400033b5:	85 c0                	test   %eax,%eax
400033b7:	79 07                	jns    400033c0 <fseek+0x2a>
		return -1;
400033b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400033be:	eb 05                	jmp    400033c5 <fseek+0x2f>
	return 0;	// fseek() returns 0 on success, not the new position
400033c0:	b8 00 00 00 00       	mov    $0x0,%eax
}
400033c5:	c9                   	leave  
400033c6:	c3                   	ret    

400033c7 <ftell>:

long
ftell(FILE *fd)
{
400033c7:	55                   	push   %ebp
400033c8:	89 e5                	mov    %esp,%ebp
400033ca:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
400033cd:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
400033d2:	83 c0 10             	add    $0x10,%eax
400033d5:	3b 45 08             	cmp    0x8(%ebp),%eax
400033d8:	77 18                	ja     400033f2 <ftell+0x2b>
400033da:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
400033df:	05 10 10 00 00       	add    $0x1010,%eax
400033e4:	3b 45 08             	cmp    0x8(%ebp),%eax
400033e7:	76 09                	jbe    400033f2 <ftell+0x2b>
400033e9:	8b 45 08             	mov    0x8(%ebp),%eax
400033ec:	8b 00                	mov    (%eax),%eax
400033ee:	85 c0                	test   %eax,%eax
400033f0:	75 24                	jne    40003416 <ftell+0x4f>
400033f2:	c7 44 24 0c 19 42 00 	movl   $0x40004219,0xc(%esp)
400033f9:	40 
400033fa:	c7 44 24 08 d5 41 00 	movl   $0x400041d5,0x8(%esp)
40003401:	40 
40003402:	c7 44 24 04 7a 00 00 	movl   $0x7a,0x4(%esp)
40003409:	00 
4000340a:	c7 04 24 ea 41 00 40 	movl   $0x400041ea,(%esp)
40003411:	e8 2e fb ff ff       	call   40002f44 <debug_panic>
	return fd->ofs;
40003416:	8b 45 08             	mov    0x8(%ebp),%eax
40003419:	8b 40 08             	mov    0x8(%eax),%eax
}
4000341c:	c9                   	leave  
4000341d:	c3                   	ret    

4000341e <feof>:

int
feof(FILE *fd)
{
4000341e:	55                   	push   %ebp
4000341f:	89 e5                	mov    %esp,%ebp
40003421:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isopen(fd));
40003424:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40003429:	83 c0 10             	add    $0x10,%eax
4000342c:	3b 45 08             	cmp    0x8(%ebp),%eax
4000342f:	77 18                	ja     40003449 <feof+0x2b>
40003431:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40003436:	05 10 10 00 00       	add    $0x1010,%eax
4000343b:	3b 45 08             	cmp    0x8(%ebp),%eax
4000343e:	76 09                	jbe    40003449 <feof+0x2b>
40003440:	8b 45 08             	mov    0x8(%ebp),%eax
40003443:	8b 00                	mov    (%eax),%eax
40003445:	85 c0                	test   %eax,%eax
40003447:	75 24                	jne    4000346d <feof+0x4f>
40003449:	c7 44 24 0c 19 42 00 	movl   $0x40004219,0xc(%esp)
40003450:	40 
40003451:	c7 44 24 08 d5 41 00 	movl   $0x400041d5,0x8(%esp)
40003458:	40 
40003459:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
40003460:	00 
40003461:	c7 04 24 ea 41 00 40 	movl   $0x400041ea,(%esp)
40003468:	e8 d7 fa ff ff       	call   40002f44 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
4000346d:	8b 15 4c 3c 00 40    	mov    0x40003c4c,%edx
40003473:	8b 45 08             	mov    0x8(%ebp),%eax
40003476:	8b 00                	mov    (%eax),%eax
40003478:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000347b:	05 10 10 00 00       	add    $0x1010,%eax
40003480:	01 d0                	add    %edx,%eax
40003482:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return fd->ofs >= fi->size && !(fi->mode & S_IFPART);
40003485:	8b 45 08             	mov    0x8(%ebp),%eax
40003488:	8b 40 08             	mov    0x8(%eax),%eax
4000348b:	89 c2                	mov    %eax,%edx
4000348d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003490:	8b 40 4c             	mov    0x4c(%eax),%eax
40003493:	39 c2                	cmp    %eax,%edx
40003495:	72 16                	jb     400034ad <feof+0x8f>
40003497:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000349a:	8b 40 48             	mov    0x48(%eax),%eax
4000349d:	25 00 80 00 00       	and    $0x8000,%eax
400034a2:	85 c0                	test   %eax,%eax
400034a4:	75 07                	jne    400034ad <feof+0x8f>
400034a6:	b8 01 00 00 00       	mov    $0x1,%eax
400034ab:	eb 05                	jmp    400034b2 <feof+0x94>
400034ad:	b8 00 00 00 00       	mov    $0x0,%eax
}
400034b2:	c9                   	leave  
400034b3:	c3                   	ret    

400034b4 <ferror>:

int
ferror(FILE *fd)
{
400034b4:	55                   	push   %ebp
400034b5:	89 e5                	mov    %esp,%ebp
400034b7:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
400034ba:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
400034bf:	83 c0 10             	add    $0x10,%eax
400034c2:	3b 45 08             	cmp    0x8(%ebp),%eax
400034c5:	77 18                	ja     400034df <ferror+0x2b>
400034c7:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
400034cc:	05 10 10 00 00       	add    $0x1010,%eax
400034d1:	3b 45 08             	cmp    0x8(%ebp),%eax
400034d4:	76 09                	jbe    400034df <ferror+0x2b>
400034d6:	8b 45 08             	mov    0x8(%ebp),%eax
400034d9:	8b 00                	mov    (%eax),%eax
400034db:	85 c0                	test   %eax,%eax
400034dd:	75 24                	jne    40003503 <ferror+0x4f>
400034df:	c7 44 24 0c 19 42 00 	movl   $0x40004219,0xc(%esp)
400034e6:	40 
400034e7:	c7 44 24 08 d5 41 00 	movl   $0x400041d5,0x8(%esp)
400034ee:	40 
400034ef:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
400034f6:	00 
400034f7:	c7 04 24 ea 41 00 40 	movl   $0x400041ea,(%esp)
400034fe:	e8 41 fa ff ff       	call   40002f44 <debug_panic>
	return fd->err;
40003503:	8b 45 08             	mov    0x8(%ebp),%eax
40003506:	8b 40 0c             	mov    0xc(%eax),%eax
}
40003509:	c9                   	leave  
4000350a:	c3                   	ret    

4000350b <clearerr>:

void
clearerr(FILE *fd)
{
4000350b:	55                   	push   %ebp
4000350c:	89 e5                	mov    %esp,%ebp
4000350e:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
40003511:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40003516:	83 c0 10             	add    $0x10,%eax
40003519:	3b 45 08             	cmp    0x8(%ebp),%eax
4000351c:	77 18                	ja     40003536 <clearerr+0x2b>
4000351e:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40003523:	05 10 10 00 00       	add    $0x1010,%eax
40003528:	3b 45 08             	cmp    0x8(%ebp),%eax
4000352b:	76 09                	jbe    40003536 <clearerr+0x2b>
4000352d:	8b 45 08             	mov    0x8(%ebp),%eax
40003530:	8b 00                	mov    (%eax),%eax
40003532:	85 c0                	test   %eax,%eax
40003534:	75 24                	jne    4000355a <clearerr+0x4f>
40003536:	c7 44 24 0c 19 42 00 	movl   $0x40004219,0xc(%esp)
4000353d:	40 
4000353e:	c7 44 24 08 d5 41 00 	movl   $0x400041d5,0x8(%esp)
40003545:	40 
40003546:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
4000354d:	00 
4000354e:	c7 04 24 ea 41 00 40 	movl   $0x400041ea,(%esp)
40003555:	e8 ea f9 ff ff       	call   40002f44 <debug_panic>
	fd->err = 0;
4000355a:	8b 45 08             	mov    0x8(%ebp),%eax
4000355d:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
}
40003564:	c9                   	leave  
40003565:	c3                   	ret    

40003566 <fflush>:


int
fflush(FILE *f)
{
40003566:	55                   	push   %ebp
40003567:	89 e5                	mov    %esp,%ebp
40003569:	83 ec 18             	sub    $0x18,%esp
	if (f == NULL) {	// flush all open streams
4000356c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003570:	75 57                	jne    400035c9 <fflush+0x63>
		for (f = &files->fd[0]; f < &files->fd[OPEN_MAX]; f++)
40003572:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40003577:	83 c0 10             	add    $0x10,%eax
4000357a:	89 45 08             	mov    %eax,0x8(%ebp)
4000357d:	eb 34                	jmp    400035b3 <fflush+0x4d>
			if (filedesc_isopen(f))
4000357f:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40003584:	83 c0 10             	add    $0x10,%eax
40003587:	3b 45 08             	cmp    0x8(%ebp),%eax
4000358a:	77 23                	ja     400035af <fflush+0x49>
4000358c:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
40003591:	05 10 10 00 00       	add    $0x1010,%eax
40003596:	3b 45 08             	cmp    0x8(%ebp),%eax
40003599:	76 14                	jbe    400035af <fflush+0x49>
4000359b:	8b 45 08             	mov    0x8(%ebp),%eax
4000359e:	8b 00                	mov    (%eax),%eax
400035a0:	85 c0                	test   %eax,%eax
400035a2:	74 0b                	je     400035af <fflush+0x49>
				fflush(f);
400035a4:	8b 45 08             	mov    0x8(%ebp),%eax
400035a7:	89 04 24             	mov    %eax,(%esp)
400035aa:	e8 b7 ff ff ff       	call   40003566 <fflush>

int
fflush(FILE *f)
{
	if (f == NULL) {	// flush all open streams
		for (f = &files->fd[0]; f < &files->fd[OPEN_MAX]; f++)
400035af:	83 45 08 10          	addl   $0x10,0x8(%ebp)
400035b3:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
400035b8:	05 10 10 00 00       	add    $0x1010,%eax
400035bd:	3b 45 08             	cmp    0x8(%ebp),%eax
400035c0:	77 bd                	ja     4000357f <fflush+0x19>
			if (filedesc_isopen(f))
				fflush(f);
		return 0;
400035c2:	b8 00 00 00 00       	mov    $0x0,%eax
400035c7:	eb 56                	jmp    4000361f <fflush+0xb9>
	}

	assert(filedesc_isopen(f));
400035c9:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
400035ce:	83 c0 10             	add    $0x10,%eax
400035d1:	3b 45 08             	cmp    0x8(%ebp),%eax
400035d4:	77 18                	ja     400035ee <fflush+0x88>
400035d6:	a1 4c 3c 00 40       	mov    0x40003c4c,%eax
400035db:	05 10 10 00 00       	add    $0x1010,%eax
400035e0:	3b 45 08             	cmp    0x8(%ebp),%eax
400035e3:	76 09                	jbe    400035ee <fflush+0x88>
400035e5:	8b 45 08             	mov    0x8(%ebp),%eax
400035e8:	8b 00                	mov    (%eax),%eax
400035ea:	85 c0                	test   %eax,%eax
400035ec:	75 24                	jne    40003612 <fflush+0xac>
400035ee:	c7 44 24 0c 2d 42 00 	movl   $0x4000422d,0xc(%esp)
400035f5:	40 
400035f6:	c7 44 24 08 d5 41 00 	movl   $0x400041d5,0x8(%esp)
400035fd:	40 
400035fe:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
40003605:	00 
40003606:	c7 04 24 ea 41 00 40 	movl   $0x400041ea,(%esp)
4000360d:	e8 32 f9 ff ff       	call   40002f44 <debug_panic>
	return fileino_flush(f->ino);
40003612:	8b 45 08             	mov    0x8(%ebp),%eax
40003615:	8b 00                	mov    (%eax),%eax
40003617:	89 04 24             	mov    %eax,(%esp)
4000361a:	e8 45 e2 ff ff       	call   40001864 <fileino_flush>
}
4000361f:	c9                   	leave  
40003620:	c3                   	ret    
40003621:	66 90                	xchg   %ax,%ax
40003623:	90                   	nop

40003624 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
40003624:	55                   	push   %ebp
40003625:	89 e5                	mov    %esp,%ebp
	b->cnt++;
40003627:	8b 45 0c             	mov    0xc(%ebp),%eax
4000362a:	8b 40 08             	mov    0x8(%eax),%eax
4000362d:	8d 50 01             	lea    0x1(%eax),%edx
40003630:	8b 45 0c             	mov    0xc(%ebp),%eax
40003633:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
40003636:	8b 45 0c             	mov    0xc(%ebp),%eax
40003639:	8b 10                	mov    (%eax),%edx
4000363b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000363e:	8b 40 04             	mov    0x4(%eax),%eax
40003641:	39 c2                	cmp    %eax,%edx
40003643:	73 12                	jae    40003657 <sprintputch+0x33>
		*b->buf++ = ch;
40003645:	8b 45 0c             	mov    0xc(%ebp),%eax
40003648:	8b 00                	mov    (%eax),%eax
4000364a:	8b 55 08             	mov    0x8(%ebp),%edx
4000364d:	88 10                	mov    %dl,(%eax)
4000364f:	8d 50 01             	lea    0x1(%eax),%edx
40003652:	8b 45 0c             	mov    0xc(%ebp),%eax
40003655:	89 10                	mov    %edx,(%eax)
}
40003657:	5d                   	pop    %ebp
40003658:	c3                   	ret    

40003659 <vsprintf>:

int
vsprintf(char *buf, const char *fmt, va_list ap)
{
40003659:	55                   	push   %ebp
4000365a:	89 e5                	mov    %esp,%ebp
4000365c:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL);
4000365f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003663:	75 24                	jne    40003689 <vsprintf+0x30>
40003665:	c7 44 24 0c 40 42 00 	movl   $0x40004240,0xc(%esp)
4000366c:	40 
4000366d:	c7 44 24 08 4c 42 00 	movl   $0x4000424c,0x8(%esp)
40003674:	40 
40003675:	c7 44 24 04 19 00 00 	movl   $0x19,0x4(%esp)
4000367c:	00 
4000367d:	c7 04 24 61 42 00 40 	movl   $0x40004261,(%esp)
40003684:	e8 bb f8 ff ff       	call   40002f44 <debug_panic>
	struct sprintbuf b = {buf, (char*)(intptr_t)~0, 0};
40003689:	8b 45 08             	mov    0x8(%ebp),%eax
4000368c:	89 45 ec             	mov    %eax,-0x14(%ebp)
4000368f:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
40003696:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
4000369d:	8b 45 10             	mov    0x10(%ebp),%eax
400036a0:	89 44 24 0c          	mov    %eax,0xc(%esp)
400036a4:	8b 45 0c             	mov    0xc(%ebp),%eax
400036a7:	89 44 24 08          	mov    %eax,0x8(%esp)
400036ab:	8d 45 ec             	lea    -0x14(%ebp),%eax
400036ae:	89 44 24 04          	mov    %eax,0x4(%esp)
400036b2:	c7 04 24 24 36 00 40 	movl   $0x40003624,(%esp)
400036b9:	e8 83 d0 ff ff       	call   40000741 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
400036be:	8b 45 ec             	mov    -0x14(%ebp),%eax
400036c1:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
400036c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
400036c7:	c9                   	leave  
400036c8:	c3                   	ret    

400036c9 <sprintf>:

int
sprintf(char *buf, const char *fmt, ...)
{
400036c9:	55                   	push   %ebp
400036ca:	89 e5                	mov    %esp,%ebp
400036cc:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
400036cf:	8d 45 0c             	lea    0xc(%ebp),%eax
400036d2:	83 c0 04             	add    $0x4,%eax
400036d5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsprintf(buf, fmt, ap);
400036d8:	8b 45 0c             	mov    0xc(%ebp),%eax
400036db:	8b 55 f4             	mov    -0xc(%ebp),%edx
400036de:	89 54 24 08          	mov    %edx,0x8(%esp)
400036e2:	89 44 24 04          	mov    %eax,0x4(%esp)
400036e6:	8b 45 08             	mov    0x8(%ebp),%eax
400036e9:	89 04 24             	mov    %eax,(%esp)
400036ec:	e8 68 ff ff ff       	call   40003659 <vsprintf>
400036f1:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
400036f4:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
400036f7:	c9                   	leave  
400036f8:	c3                   	ret    

400036f9 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
400036f9:	55                   	push   %ebp
400036fa:	89 e5                	mov    %esp,%ebp
400036fc:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL && n > 0);
400036ff:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003703:	74 06                	je     4000370b <vsnprintf+0x12>
40003705:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40003709:	7f 24                	jg     4000372f <vsnprintf+0x36>
4000370b:	c7 44 24 0c 6f 42 00 	movl   $0x4000426f,0xc(%esp)
40003712:	40 
40003713:	c7 44 24 08 4c 42 00 	movl   $0x4000424c,0x8(%esp)
4000371a:	40 
4000371b:	c7 44 24 04 35 00 00 	movl   $0x35,0x4(%esp)
40003722:	00 
40003723:	c7 04 24 61 42 00 40 	movl   $0x40004261,(%esp)
4000372a:	e8 15 f8 ff ff       	call   40002f44 <debug_panic>
	struct sprintbuf b = {buf, buf+n-1, 0};
4000372f:	8b 45 08             	mov    0x8(%ebp),%eax
40003732:	89 45 ec             	mov    %eax,-0x14(%ebp)
40003735:	8b 45 0c             	mov    0xc(%ebp),%eax
40003738:	8d 50 ff             	lea    -0x1(%eax),%edx
4000373b:	8b 45 08             	mov    0x8(%ebp),%eax
4000373e:	01 d0                	add    %edx,%eax
40003740:	89 45 f0             	mov    %eax,-0x10(%ebp)
40003743:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
4000374a:	8b 45 14             	mov    0x14(%ebp),%eax
4000374d:	89 44 24 0c          	mov    %eax,0xc(%esp)
40003751:	8b 45 10             	mov    0x10(%ebp),%eax
40003754:	89 44 24 08          	mov    %eax,0x8(%esp)
40003758:	8d 45 ec             	lea    -0x14(%ebp),%eax
4000375b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000375f:	c7 04 24 24 36 00 40 	movl   $0x40003624,(%esp)
40003766:	e8 d6 cf ff ff       	call   40000741 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
4000376b:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000376e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
40003771:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
40003774:	c9                   	leave  
40003775:	c3                   	ret    

40003776 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
40003776:	55                   	push   %ebp
40003777:	89 e5                	mov    %esp,%ebp
40003779:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
4000377c:	8d 45 10             	lea    0x10(%ebp),%eax
4000377f:	83 c0 04             	add    $0x4,%eax
40003782:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
40003785:	8b 45 10             	mov    0x10(%ebp),%eax
40003788:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000378b:	89 54 24 0c          	mov    %edx,0xc(%esp)
4000378f:	89 44 24 08          	mov    %eax,0x8(%esp)
40003793:	8b 45 0c             	mov    0xc(%ebp),%eax
40003796:	89 44 24 04          	mov    %eax,0x4(%esp)
4000379a:	8b 45 08             	mov    0x8(%ebp),%eax
4000379d:	89 04 24             	mov    %eax,(%esp)
400037a0:	e8 54 ff ff ff       	call   400036f9 <vsnprintf>
400037a5:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
400037a8:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
400037ab:	c9                   	leave  
400037ac:	c3                   	ret    
400037ad:	66 90                	xchg   %ax,%ax
400037af:	90                   	nop

400037b0 <__udivdi3>:
400037b0:	83 ec 1c             	sub    $0x1c,%esp
400037b3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
400037b7:	89 7c 24 14          	mov    %edi,0x14(%esp)
400037bb:	8b 4c 24 28          	mov    0x28(%esp),%ecx
400037bf:	89 6c 24 18          	mov    %ebp,0x18(%esp)
400037c3:	8b 7c 24 20          	mov    0x20(%esp),%edi
400037c7:	8b 6c 24 24          	mov    0x24(%esp),%ebp
400037cb:	85 c0                	test   %eax,%eax
400037cd:	89 74 24 10          	mov    %esi,0x10(%esp)
400037d1:	89 7c 24 08          	mov    %edi,0x8(%esp)
400037d5:	89 ea                	mov    %ebp,%edx
400037d7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
400037db:	75 33                	jne    40003810 <__udivdi3+0x60>
400037dd:	39 e9                	cmp    %ebp,%ecx
400037df:	77 6f                	ja     40003850 <__udivdi3+0xa0>
400037e1:	85 c9                	test   %ecx,%ecx
400037e3:	89 ce                	mov    %ecx,%esi
400037e5:	75 0b                	jne    400037f2 <__udivdi3+0x42>
400037e7:	b8 01 00 00 00       	mov    $0x1,%eax
400037ec:	31 d2                	xor    %edx,%edx
400037ee:	f7 f1                	div    %ecx
400037f0:	89 c6                	mov    %eax,%esi
400037f2:	31 d2                	xor    %edx,%edx
400037f4:	89 e8                	mov    %ebp,%eax
400037f6:	f7 f6                	div    %esi
400037f8:	89 c5                	mov    %eax,%ebp
400037fa:	89 f8                	mov    %edi,%eax
400037fc:	f7 f6                	div    %esi
400037fe:	89 ea                	mov    %ebp,%edx
40003800:	8b 74 24 10          	mov    0x10(%esp),%esi
40003804:	8b 7c 24 14          	mov    0x14(%esp),%edi
40003808:	8b 6c 24 18          	mov    0x18(%esp),%ebp
4000380c:	83 c4 1c             	add    $0x1c,%esp
4000380f:	c3                   	ret    
40003810:	39 e8                	cmp    %ebp,%eax
40003812:	77 24                	ja     40003838 <__udivdi3+0x88>
40003814:	0f bd c8             	bsr    %eax,%ecx
40003817:	83 f1 1f             	xor    $0x1f,%ecx
4000381a:	89 0c 24             	mov    %ecx,(%esp)
4000381d:	75 49                	jne    40003868 <__udivdi3+0xb8>
4000381f:	8b 74 24 08          	mov    0x8(%esp),%esi
40003823:	39 74 24 04          	cmp    %esi,0x4(%esp)
40003827:	0f 86 ab 00 00 00    	jbe    400038d8 <__udivdi3+0x128>
4000382d:	39 e8                	cmp    %ebp,%eax
4000382f:	0f 82 a3 00 00 00    	jb     400038d8 <__udivdi3+0x128>
40003835:	8d 76 00             	lea    0x0(%esi),%esi
40003838:	31 d2                	xor    %edx,%edx
4000383a:	31 c0                	xor    %eax,%eax
4000383c:	8b 74 24 10          	mov    0x10(%esp),%esi
40003840:	8b 7c 24 14          	mov    0x14(%esp),%edi
40003844:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40003848:	83 c4 1c             	add    $0x1c,%esp
4000384b:	c3                   	ret    
4000384c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003850:	89 f8                	mov    %edi,%eax
40003852:	f7 f1                	div    %ecx
40003854:	31 d2                	xor    %edx,%edx
40003856:	8b 74 24 10          	mov    0x10(%esp),%esi
4000385a:	8b 7c 24 14          	mov    0x14(%esp),%edi
4000385e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40003862:	83 c4 1c             	add    $0x1c,%esp
40003865:	c3                   	ret    
40003866:	66 90                	xchg   %ax,%ax
40003868:	0f b6 0c 24          	movzbl (%esp),%ecx
4000386c:	89 c6                	mov    %eax,%esi
4000386e:	b8 20 00 00 00       	mov    $0x20,%eax
40003873:	8b 6c 24 04          	mov    0x4(%esp),%ebp
40003877:	2b 04 24             	sub    (%esp),%eax
4000387a:	8b 7c 24 08          	mov    0x8(%esp),%edi
4000387e:	d3 e6                	shl    %cl,%esi
40003880:	89 c1                	mov    %eax,%ecx
40003882:	d3 ed                	shr    %cl,%ebp
40003884:	0f b6 0c 24          	movzbl (%esp),%ecx
40003888:	09 f5                	or     %esi,%ebp
4000388a:	8b 74 24 04          	mov    0x4(%esp),%esi
4000388e:	d3 e6                	shl    %cl,%esi
40003890:	89 c1                	mov    %eax,%ecx
40003892:	89 74 24 04          	mov    %esi,0x4(%esp)
40003896:	89 d6                	mov    %edx,%esi
40003898:	d3 ee                	shr    %cl,%esi
4000389a:	0f b6 0c 24          	movzbl (%esp),%ecx
4000389e:	d3 e2                	shl    %cl,%edx
400038a0:	89 c1                	mov    %eax,%ecx
400038a2:	d3 ef                	shr    %cl,%edi
400038a4:	09 d7                	or     %edx,%edi
400038a6:	89 f2                	mov    %esi,%edx
400038a8:	89 f8                	mov    %edi,%eax
400038aa:	f7 f5                	div    %ebp
400038ac:	89 d6                	mov    %edx,%esi
400038ae:	89 c7                	mov    %eax,%edi
400038b0:	f7 64 24 04          	mull   0x4(%esp)
400038b4:	39 d6                	cmp    %edx,%esi
400038b6:	72 30                	jb     400038e8 <__udivdi3+0x138>
400038b8:	8b 6c 24 08          	mov    0x8(%esp),%ebp
400038bc:	0f b6 0c 24          	movzbl (%esp),%ecx
400038c0:	d3 e5                	shl    %cl,%ebp
400038c2:	39 c5                	cmp    %eax,%ebp
400038c4:	73 04                	jae    400038ca <__udivdi3+0x11a>
400038c6:	39 d6                	cmp    %edx,%esi
400038c8:	74 1e                	je     400038e8 <__udivdi3+0x138>
400038ca:	89 f8                	mov    %edi,%eax
400038cc:	31 d2                	xor    %edx,%edx
400038ce:	e9 69 ff ff ff       	jmp    4000383c <__udivdi3+0x8c>
400038d3:	90                   	nop
400038d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
400038d8:	31 d2                	xor    %edx,%edx
400038da:	b8 01 00 00 00       	mov    $0x1,%eax
400038df:	e9 58 ff ff ff       	jmp    4000383c <__udivdi3+0x8c>
400038e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
400038e8:	8d 47 ff             	lea    -0x1(%edi),%eax
400038eb:	31 d2                	xor    %edx,%edx
400038ed:	8b 74 24 10          	mov    0x10(%esp),%esi
400038f1:	8b 7c 24 14          	mov    0x14(%esp),%edi
400038f5:	8b 6c 24 18          	mov    0x18(%esp),%ebp
400038f9:	83 c4 1c             	add    $0x1c,%esp
400038fc:	c3                   	ret    
400038fd:	66 90                	xchg   %ax,%ax
400038ff:	90                   	nop

40003900 <__umoddi3>:
40003900:	83 ec 2c             	sub    $0x2c,%esp
40003903:	8b 44 24 3c          	mov    0x3c(%esp),%eax
40003907:	8b 4c 24 30          	mov    0x30(%esp),%ecx
4000390b:	89 74 24 20          	mov    %esi,0x20(%esp)
4000390f:	8b 74 24 38          	mov    0x38(%esp),%esi
40003913:	89 7c 24 24          	mov    %edi,0x24(%esp)
40003917:	8b 7c 24 34          	mov    0x34(%esp),%edi
4000391b:	85 c0                	test   %eax,%eax
4000391d:	89 c2                	mov    %eax,%edx
4000391f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
40003923:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
40003927:	89 7c 24 0c          	mov    %edi,0xc(%esp)
4000392b:	89 74 24 10          	mov    %esi,0x10(%esp)
4000392f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
40003933:	89 7c 24 18          	mov    %edi,0x18(%esp)
40003937:	75 1f                	jne    40003958 <__umoddi3+0x58>
40003939:	39 fe                	cmp    %edi,%esi
4000393b:	76 63                	jbe    400039a0 <__umoddi3+0xa0>
4000393d:	89 c8                	mov    %ecx,%eax
4000393f:	89 fa                	mov    %edi,%edx
40003941:	f7 f6                	div    %esi
40003943:	89 d0                	mov    %edx,%eax
40003945:	31 d2                	xor    %edx,%edx
40003947:	8b 74 24 20          	mov    0x20(%esp),%esi
4000394b:	8b 7c 24 24          	mov    0x24(%esp),%edi
4000394f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
40003953:	83 c4 2c             	add    $0x2c,%esp
40003956:	c3                   	ret    
40003957:	90                   	nop
40003958:	39 f8                	cmp    %edi,%eax
4000395a:	77 64                	ja     400039c0 <__umoddi3+0xc0>
4000395c:	0f bd e8             	bsr    %eax,%ebp
4000395f:	83 f5 1f             	xor    $0x1f,%ebp
40003962:	75 74                	jne    400039d8 <__umoddi3+0xd8>
40003964:	8b 7c 24 14          	mov    0x14(%esp),%edi
40003968:	39 7c 24 10          	cmp    %edi,0x10(%esp)
4000396c:	0f 87 0e 01 00 00    	ja     40003a80 <__umoddi3+0x180>
40003972:	8b 7c 24 0c          	mov    0xc(%esp),%edi
40003976:	29 f1                	sub    %esi,%ecx
40003978:	19 c7                	sbb    %eax,%edi
4000397a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
4000397e:	89 7c 24 18          	mov    %edi,0x18(%esp)
40003982:	8b 44 24 14          	mov    0x14(%esp),%eax
40003986:	8b 54 24 18          	mov    0x18(%esp),%edx
4000398a:	8b 74 24 20          	mov    0x20(%esp),%esi
4000398e:	8b 7c 24 24          	mov    0x24(%esp),%edi
40003992:	8b 6c 24 28          	mov    0x28(%esp),%ebp
40003996:	83 c4 2c             	add    $0x2c,%esp
40003999:	c3                   	ret    
4000399a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
400039a0:	85 f6                	test   %esi,%esi
400039a2:	89 f5                	mov    %esi,%ebp
400039a4:	75 0b                	jne    400039b1 <__umoddi3+0xb1>
400039a6:	b8 01 00 00 00       	mov    $0x1,%eax
400039ab:	31 d2                	xor    %edx,%edx
400039ad:	f7 f6                	div    %esi
400039af:	89 c5                	mov    %eax,%ebp
400039b1:	8b 44 24 0c          	mov    0xc(%esp),%eax
400039b5:	31 d2                	xor    %edx,%edx
400039b7:	f7 f5                	div    %ebp
400039b9:	89 c8                	mov    %ecx,%eax
400039bb:	f7 f5                	div    %ebp
400039bd:	eb 84                	jmp    40003943 <__umoddi3+0x43>
400039bf:	90                   	nop
400039c0:	89 c8                	mov    %ecx,%eax
400039c2:	89 fa                	mov    %edi,%edx
400039c4:	8b 74 24 20          	mov    0x20(%esp),%esi
400039c8:	8b 7c 24 24          	mov    0x24(%esp),%edi
400039cc:	8b 6c 24 28          	mov    0x28(%esp),%ebp
400039d0:	83 c4 2c             	add    $0x2c,%esp
400039d3:	c3                   	ret    
400039d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
400039d8:	8b 44 24 10          	mov    0x10(%esp),%eax
400039dc:	be 20 00 00 00       	mov    $0x20,%esi
400039e1:	89 e9                	mov    %ebp,%ecx
400039e3:	29 ee                	sub    %ebp,%esi
400039e5:	d3 e2                	shl    %cl,%edx
400039e7:	89 f1                	mov    %esi,%ecx
400039e9:	d3 e8                	shr    %cl,%eax
400039eb:	89 e9                	mov    %ebp,%ecx
400039ed:	09 d0                	or     %edx,%eax
400039ef:	89 fa                	mov    %edi,%edx
400039f1:	89 44 24 0c          	mov    %eax,0xc(%esp)
400039f5:	8b 44 24 10          	mov    0x10(%esp),%eax
400039f9:	d3 e0                	shl    %cl,%eax
400039fb:	89 f1                	mov    %esi,%ecx
400039fd:	89 44 24 10          	mov    %eax,0x10(%esp)
40003a01:	8b 44 24 1c          	mov    0x1c(%esp),%eax
40003a05:	d3 ea                	shr    %cl,%edx
40003a07:	89 e9                	mov    %ebp,%ecx
40003a09:	d3 e7                	shl    %cl,%edi
40003a0b:	89 f1                	mov    %esi,%ecx
40003a0d:	d3 e8                	shr    %cl,%eax
40003a0f:	89 e9                	mov    %ebp,%ecx
40003a11:	09 f8                	or     %edi,%eax
40003a13:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
40003a17:	f7 74 24 0c          	divl   0xc(%esp)
40003a1b:	d3 e7                	shl    %cl,%edi
40003a1d:	89 7c 24 18          	mov    %edi,0x18(%esp)
40003a21:	89 d7                	mov    %edx,%edi
40003a23:	f7 64 24 10          	mull   0x10(%esp)
40003a27:	39 d7                	cmp    %edx,%edi
40003a29:	89 c1                	mov    %eax,%ecx
40003a2b:	89 54 24 14          	mov    %edx,0x14(%esp)
40003a2f:	72 3b                	jb     40003a6c <__umoddi3+0x16c>
40003a31:	39 44 24 18          	cmp    %eax,0x18(%esp)
40003a35:	72 31                	jb     40003a68 <__umoddi3+0x168>
40003a37:	8b 44 24 18          	mov    0x18(%esp),%eax
40003a3b:	29 c8                	sub    %ecx,%eax
40003a3d:	19 d7                	sbb    %edx,%edi
40003a3f:	89 e9                	mov    %ebp,%ecx
40003a41:	89 fa                	mov    %edi,%edx
40003a43:	d3 e8                	shr    %cl,%eax
40003a45:	89 f1                	mov    %esi,%ecx
40003a47:	d3 e2                	shl    %cl,%edx
40003a49:	89 e9                	mov    %ebp,%ecx
40003a4b:	09 d0                	or     %edx,%eax
40003a4d:	89 fa                	mov    %edi,%edx
40003a4f:	d3 ea                	shr    %cl,%edx
40003a51:	8b 74 24 20          	mov    0x20(%esp),%esi
40003a55:	8b 7c 24 24          	mov    0x24(%esp),%edi
40003a59:	8b 6c 24 28          	mov    0x28(%esp),%ebp
40003a5d:	83 c4 2c             	add    $0x2c,%esp
40003a60:	c3                   	ret    
40003a61:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
40003a68:	39 d7                	cmp    %edx,%edi
40003a6a:	75 cb                	jne    40003a37 <__umoddi3+0x137>
40003a6c:	8b 54 24 14          	mov    0x14(%esp),%edx
40003a70:	89 c1                	mov    %eax,%ecx
40003a72:	2b 4c 24 10          	sub    0x10(%esp),%ecx
40003a76:	1b 54 24 0c          	sbb    0xc(%esp),%edx
40003a7a:	eb bb                	jmp    40003a37 <__umoddi3+0x137>
40003a7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003a80:	3b 44 24 18          	cmp    0x18(%esp),%eax
40003a84:	0f 82 e8 fe ff ff    	jb     40003972 <__umoddi3+0x72>
40003a8a:	e9 f3 fe ff ff       	jmp    40003982 <__umoddi3+0x82>
