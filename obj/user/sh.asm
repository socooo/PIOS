
obj/user/sh:     file format elf32-i386


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
4000010c:	e8 a7 05 00 00       	call   400006b8 <main>
	pushl	%eax	// use with main's return value as exit status
40000111:	50                   	push   %eax
	call	exit
40000112:	e8 39 34 00 00       	call   40003550 <exit>
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

40000144 <runcmd>:
// runcmd() is called in a forked child,
// so it's OK to manipulate file descriptor state.
#define MAXARGS 256
void gcc_noreturn
runcmd(char* s)
{
40000144:	55                   	push   %ebp
40000145:	89 e5                	mov    %esp,%ebp
40000147:	81 ec 38 08 00 00    	sub    $0x838,%esp
	char *argv[MAXARGS], *t, argv0buf[BUFSIZ];
	int argc, c, i, r, p[2], fd, pipe_child;

	pipe_child = 0;
4000014d:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	gettoken(s, 0);
40000154:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000015b:	00 
4000015c:	8b 45 08             	mov    0x8(%ebp),%eax
4000015f:	89 04 24             	mov    %eax,(%esp)
40000162:	e8 c2 04 00 00       	call   40000629 <gettoken>
	
again:
	argc = 0;
40000167:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	while (1) {
		switch ((c = gettoken(0, &t))) {
4000016e:	8d 85 e0 fb ff ff    	lea    -0x420(%ebp),%eax
40000174:	89 44 24 04          	mov    %eax,0x4(%esp)
40000178:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000017f:	e8 a5 04 00 00       	call   40000629 <gettoken>
40000184:	89 45 e8             	mov    %eax,-0x18(%ebp)
40000187:	8b 45 e8             	mov    -0x18(%ebp),%eax
4000018a:	83 f8 3e             	cmp    $0x3e,%eax
4000018d:	0f 84 02 01 00 00    	je     40000295 <runcmd+0x151>
40000193:	83 f8 3e             	cmp    $0x3e,%eax
40000196:	7f 12                	jg     400001aa <runcmd+0x66>
40000198:	85 c0                	test   %eax,%eax
4000019a:	0f 84 ce 01 00 00    	je     4000036e <runcmd+0x22a>
400001a0:	83 f8 3c             	cmp    $0x3c,%eax
400001a3:	74 48                	je     400001ed <runcmd+0xa9>
400001a5:	e9 98 01 00 00       	jmp    40000342 <runcmd+0x1fe>
400001aa:	83 f8 77             	cmp    $0x77,%eax
400001ad:	0f 85 8f 01 00 00    	jne    40000342 <runcmd+0x1fe>

		case 'w':	// Add an argument
			if (argc == MAXARGS) {
400001b3:	81 7d f4 00 01 00 00 	cmpl   $0x100,-0xc(%ebp)
400001ba:	75 18                	jne    400001d4 <runcmd+0x90>
				cprintf("sh: too many arguments\n");
400001bc:	c7 04 24 80 59 00 40 	movl   $0x40005980,(%esp)
400001c3:	e8 10 0b 00 00       	call   40000cd8 <cprintf>
				exit(EXIT_FAILURE);
400001c8:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
400001cf:	e8 7c 33 00 00       	call   40003550 <exit>
			}
			argv[argc++] = t;
400001d4:	8b 95 e0 fb ff ff    	mov    -0x420(%ebp),%edx
400001da:	8b 45 f4             	mov    -0xc(%ebp),%eax
400001dd:	89 94 85 e4 fb ff ff 	mov    %edx,-0x41c(%ebp,%eax,4)
400001e4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
			break;
400001e8:	e9 7c 01 00 00       	jmp    40000369 <runcmd+0x225>
			
		case '<':	// Input redirection
			// Grab the filename from the argument list
			if (gettoken(0, &t) != 'w') {
400001ed:	8d 85 e0 fb ff ff    	lea    -0x420(%ebp),%eax
400001f3:	89 44 24 04          	mov    %eax,0x4(%esp)
400001f7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400001fe:	e8 26 04 00 00       	call   40000629 <gettoken>
40000203:	83 f8 77             	cmp    $0x77,%eax
40000206:	74 18                	je     40000220 <runcmd+0xdc>
				cprintf("syntax error: < not followed by word\n");
40000208:	c7 04 24 98 59 00 40 	movl   $0x40005998,(%esp)
4000020f:	e8 c4 0a 00 00       	call   40000cd8 <cprintf>
				exit(EXIT_FAILURE);
40000214:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
4000021b:	e8 30 33 00 00       	call   40003550 <exit>
			}
			if ((fd = open(t, O_RDONLY)) < 0) {
40000220:	8b 85 e0 fb ff ff    	mov    -0x420(%ebp),%eax
40000226:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
4000022d:	00 
4000022e:	89 04 24             	mov    %eax,(%esp)
40000231:	e8 90 33 00 00       	call   400035c6 <open>
40000236:	89 45 e4             	mov    %eax,-0x1c(%ebp)
40000239:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
4000023d:	79 29                	jns    40000268 <runcmd+0x124>
				cprintf("open %s for read: %e", t, fd);
4000023f:	8b 85 e0 fb ff ff    	mov    -0x420(%ebp),%eax
40000245:	8b 55 e4             	mov    -0x1c(%ebp),%edx
40000248:	89 54 24 08          	mov    %edx,0x8(%esp)
4000024c:	89 44 24 04          	mov    %eax,0x4(%esp)
40000250:	c7 04 24 be 59 00 40 	movl   $0x400059be,(%esp)
40000257:	e8 7c 0a 00 00       	call   40000cd8 <cprintf>
				exit(EXIT_FAILURE);
4000025c:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
40000263:	e8 e8 32 00 00       	call   40003550 <exit>
			}
			if (fd != 0) {
40000268:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
4000026c:	0f 84 f3 00 00 00    	je     40000365 <runcmd+0x221>
				dup2(fd, 0);
40000272:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000279:	00 
4000027a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000027d:	89 04 24             	mov    %eax,(%esp)
40000280:	e8 b6 34 00 00       	call   4000373b <dup2>
				close(fd);
40000285:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40000288:	89 04 24             	mov    %eax,(%esp)
4000028b:	e8 ac 33 00 00       	call   4000363c <close>
			}
			break;
40000290:	e9 d0 00 00 00       	jmp    40000365 <runcmd+0x221>
			
		case '>':	// Output redirection
			// Grab the filename from the argument list
			if (gettoken(0, &t) != 'w') {
40000295:	8d 85 e0 fb ff ff    	lea    -0x420(%ebp),%eax
4000029b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000029f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400002a6:	e8 7e 03 00 00       	call   40000629 <gettoken>
400002ab:	83 f8 77             	cmp    $0x77,%eax
400002ae:	74 18                	je     400002c8 <runcmd+0x184>
				cprintf("syntax error: > not followed by word\n");
400002b0:	c7 04 24 d4 59 00 40 	movl   $0x400059d4,(%esp)
400002b7:	e8 1c 0a 00 00       	call   40000cd8 <cprintf>
				exit(EXIT_FAILURE);
400002bc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
400002c3:	e8 88 32 00 00       	call   40003550 <exit>
			}
			if ((fd = open(t, O_WRONLY | O_CREAT | O_TRUNC)) < 0) {
400002c8:	8b 85 e0 fb ff ff    	mov    -0x420(%ebp),%eax
400002ce:	c7 44 24 04 62 00 00 	movl   $0x62,0x4(%esp)
400002d5:	00 
400002d6:	89 04 24             	mov    %eax,(%esp)
400002d9:	e8 e8 32 00 00       	call   400035c6 <open>
400002de:	89 45 e4             	mov    %eax,-0x1c(%ebp)
400002e1:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
400002e5:	79 35                	jns    4000031c <runcmd+0x1d8>
				cprintf("open %s for write: %s", t,
					strerror(errno));
400002e7:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
			if (gettoken(0, &t) != 'w') {
				cprintf("syntax error: > not followed by word\n");
				exit(EXIT_FAILURE);
			}
			if ((fd = open(t, O_WRONLY | O_CREAT | O_TRUNC)) < 0) {
				cprintf("open %s for write: %s", t,
400002ec:	8b 00                	mov    (%eax),%eax
400002ee:	89 04 24             	mov    %eax,(%esp)
400002f1:	e8 6e 50 00 00       	call   40005364 <strerror>
400002f6:	8b 95 e0 fb ff ff    	mov    -0x420(%ebp),%edx
400002fc:	89 44 24 08          	mov    %eax,0x8(%esp)
40000300:	89 54 24 04          	mov    %edx,0x4(%esp)
40000304:	c7 04 24 fa 59 00 40 	movl   $0x400059fa,(%esp)
4000030b:	e8 c8 09 00 00       	call   40000cd8 <cprintf>
					strerror(errno));
				exit(EXIT_FAILURE);
40000310:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
40000317:	e8 34 32 00 00       	call   40003550 <exit>
			}
			if (fd != 1) {
4000031c:	83 7d e4 01          	cmpl   $0x1,-0x1c(%ebp)
40000320:	74 46                	je     40000368 <runcmd+0x224>
				dup2(fd, 1);
40000322:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40000329:	00 
4000032a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000032d:	89 04 24             	mov    %eax,(%esp)
40000330:	e8 06 34 00 00       	call   4000373b <dup2>
				close(fd);
40000335:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40000338:	89 04 24             	mov    %eax,(%esp)
4000033b:	e8 fc 32 00 00       	call   4000363c <close>
			}
			break;
40000340:	eb 26                	jmp    40000368 <runcmd+0x224>
		case 0:		// String is complete
			// Run the current command!
			goto runit;
			
		default:
			panic("bad return %d from gettoken", c);
40000342:	8b 45 e8             	mov    -0x18(%ebp),%eax
40000345:	89 44 24 0c          	mov    %eax,0xc(%esp)
40000349:	c7 44 24 08 10 5a 00 	movl   $0x40005a10,0x8(%esp)
40000350:	40 
40000351:	c7 44 24 04 62 00 00 	movl   $0x62,0x4(%esp)
40000358:	00 
40000359:	c7 04 24 2c 5a 00 40 	movl   $0x40005a2c,(%esp)
40000360:	e8 df 06 00 00       	call   40000a44 <debug_panic>
			}
			if (fd != 0) {
				dup2(fd, 0);
				close(fd);
			}
			break;
40000365:	90                   	nop
40000366:	eb 01                	jmp    40000369 <runcmd+0x225>
			}
			if (fd != 1) {
				dup2(fd, 1);
				close(fd);
			}
			break;
40000368:	90                   	nop
		default:
			panic("bad return %d from gettoken", c);
			break;
			
		}
	}
40000369:	e9 00 fe ff ff       	jmp    4000016e <runcmd+0x2a>
			}
			break;
			
		case 0:		// String is complete
			// Run the current command!
			goto runit;
4000036e:	90                   	nop
		}
	}

runit:
	// Return immediately if command line was empty.
	if(argc == 0) {
4000036f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40000373:	75 21                	jne    40000396 <runcmd+0x252>
		if (debug)
40000375:	a1 00 84 00 40       	mov    0x40008400,%eax
4000037a:	85 c0                	test   %eax,%eax
4000037c:	74 0c                	je     4000038a <runcmd+0x246>
			cprintf("EMPTY COMMAND\n");
4000037e:	c7 04 24 36 5a 00 40 	movl   $0x40005a36,(%esp)
40000385:	e8 4e 09 00 00       	call   40000cd8 <cprintf>
		exit(EXIT_SUCCESS);
4000038a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000391:	e8 ba 31 00 00       	call   40003550 <exit>

	// Clean up command line.
	// Read all commands from the filesystem: add an initial '/' to
	// the command name.
	// This essentially acts like 'PATH=/'.
	if (argv[0][0] != '/') {
40000396:	8b 85 e4 fb ff ff    	mov    -0x41c(%ebp),%eax
4000039c:	0f b6 00             	movzbl (%eax),%eax
4000039f:	3c 2f                	cmp    $0x2f,%al
400003a1:	74 2e                	je     400003d1 <runcmd+0x28d>
		argv0buf[0] = '/';
400003a3:	c6 85 e0 f7 ff ff 2f 	movb   $0x2f,-0x820(%ebp)
		strcpy(argv0buf + 1, argv[0]);
400003aa:	8b 85 e4 fb ff ff    	mov    -0x41c(%ebp),%eax
400003b0:	89 44 24 04          	mov    %eax,0x4(%esp)
400003b4:	8d 85 e0 f7 ff ff    	lea    -0x820(%ebp),%eax
400003ba:	83 c0 01             	add    $0x1,%eax
400003bd:	89 04 24             	mov    %eax,(%esp)
400003c0:	e8 19 10 00 00       	call   400013de <strcpy>
		argv[0] = argv0buf;
400003c5:	8d 85 e0 f7 ff ff    	lea    -0x820(%ebp),%eax
400003cb:	89 85 e4 fb ff ff    	mov    %eax,-0x41c(%ebp)
	}
	argv[argc] = 0;
400003d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
400003d4:	c7 84 85 e4 fb ff ff 	movl   $0x0,-0x41c(%ebp,%eax,4)
400003db:	00 00 00 00 

	// Print the command.
	if (debug) {
400003df:	a1 00 84 00 40       	mov    0x40008400,%eax
400003e4:	85 c0                	test   %eax,%eax
400003e6:	74 4d                	je     40000435 <runcmd+0x2f1>
		cprintf("execv:");
400003e8:	c7 04 24 45 5a 00 40 	movl   $0x40005a45,(%esp)
400003ef:	e8 e4 08 00 00       	call   40000cd8 <cprintf>
		for (i = 0; argv[i]; i++)
400003f4:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
400003fb:	eb 1e                	jmp    4000041b <runcmd+0x2d7>
			cprintf(" %s", argv[i]);
400003fd:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000400:	8b 84 85 e4 fb ff ff 	mov    -0x41c(%ebp,%eax,4),%eax
40000407:	89 44 24 04          	mov    %eax,0x4(%esp)
4000040b:	c7 04 24 4c 5a 00 40 	movl   $0x40005a4c,(%esp)
40000412:	e8 c1 08 00 00       	call   40000cd8 <cprintf>
	argv[argc] = 0;

	// Print the command.
	if (debug) {
		cprintf("execv:");
		for (i = 0; argv[i]; i++)
40000417:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
4000041b:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000041e:	8b 84 85 e4 fb ff ff 	mov    -0x41c(%ebp,%eax,4),%eax
40000425:	85 c0                	test   %eax,%eax
40000427:	75 d4                	jne    400003fd <runcmd+0x2b9>
			cprintf(" %s", argv[i]);
		cprintf("\n");
40000429:	c7 04 24 50 5a 00 40 	movl   $0x40005a50,(%esp)
40000430:	e8 a3 08 00 00       	call   40000cd8 <cprintf>
	}

	// Run the command!
	if (execv(argv[0], argv) < 0)
40000435:	8b 85 e4 fb ff ff    	mov    -0x41c(%ebp),%eax
4000043b:	8d 95 e4 fb ff ff    	lea    -0x41c(%ebp),%edx
40000441:	89 54 24 04          	mov    %edx,0x4(%esp)
40000445:	89 04 24             	mov    %eax,(%esp)
40000448:	e8 1d 46 00 00       	call   40004a6a <execv>
4000044d:	85 c0                	test   %eax,%eax
4000044f:	79 29                	jns    4000047a <runcmd+0x336>
		cprintf("exec %s: %s\n", argv[0], strerror(errno));
40000451:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40000456:	8b 00                	mov    (%eax),%eax
40000458:	89 04 24             	mov    %eax,(%esp)
4000045b:	e8 04 4f 00 00       	call   40005364 <strerror>
40000460:	8b 95 e4 fb ff ff    	mov    -0x41c(%ebp),%edx
40000466:	89 44 24 08          	mov    %eax,0x8(%esp)
4000046a:	89 54 24 04          	mov    %edx,0x4(%esp)
4000046e:	c7 04 24 52 5a 00 40 	movl   $0x40005a52,(%esp)
40000475:	e8 5e 08 00 00       	call   40000cd8 <cprintf>
	exit(EXIT_FAILURE);
4000047a:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
40000481:	e8 ca 30 00 00       	call   40003550 <exit>

40000486 <_gettoken>:
#define WHITESPACE " \t\r\n"
#define SYMBOLS "<|>&;()"

int
_gettoken(char *s, char **p1, char **p2)
{
40000486:	55                   	push   %ebp
40000487:	89 e5                	mov    %esp,%ebp
40000489:	83 ec 28             	sub    $0x28,%esp
	int t;

	if (s == 0) {
4000048c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40000490:	75 20                	jne    400004b2 <_gettoken+0x2c>
		if (debug > 1)
40000492:	a1 00 84 00 40       	mov    0x40008400,%eax
40000497:	83 f8 01             	cmp    $0x1,%eax
4000049a:	7e 0c                	jle    400004a8 <_gettoken+0x22>
			cprintf("GETTOKEN NULL\n");
4000049c:	c7 04 24 5f 5a 00 40 	movl   $0x40005a5f,(%esp)
400004a3:	e8 30 08 00 00       	call   40000cd8 <cprintf>
		return 0;
400004a8:	b8 00 00 00 00       	mov    $0x0,%eax
400004ad:	e9 75 01 00 00       	jmp    40000627 <_gettoken+0x1a1>
	}

	if (debug > 1)
400004b2:	a1 00 84 00 40       	mov    0x40008400,%eax
400004b7:	83 f8 01             	cmp    $0x1,%eax
400004ba:	7e 13                	jle    400004cf <_gettoken+0x49>
		cprintf("GETTOKEN: %s\n", s);
400004bc:	8b 45 08             	mov    0x8(%ebp),%eax
400004bf:	89 44 24 04          	mov    %eax,0x4(%esp)
400004c3:	c7 04 24 6e 5a 00 40 	movl   $0x40005a6e,(%esp)
400004ca:	e8 09 08 00 00       	call   40000cd8 <cprintf>

	*p1 = 0;
400004cf:	8b 45 0c             	mov    0xc(%ebp),%eax
400004d2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*p2 = 0;
400004d8:	8b 45 10             	mov    0x10(%ebp),%eax
400004db:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	while (*s && strchr(WHITESPACE, *s))
400004e1:	eb 0a                	jmp    400004ed <_gettoken+0x67>
		*s++ = 0;
400004e3:	8b 45 08             	mov    0x8(%ebp),%eax
400004e6:	c6 00 00             	movb   $0x0,(%eax)
400004e9:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		cprintf("GETTOKEN: %s\n", s);

	*p1 = 0;
	*p2 = 0;

	while (*s && strchr(WHITESPACE, *s))
400004ed:	8b 45 08             	mov    0x8(%ebp),%eax
400004f0:	0f b6 00             	movzbl (%eax),%eax
400004f3:	84 c0                	test   %al,%al
400004f5:	74 1d                	je     40000514 <_gettoken+0x8e>
400004f7:	8b 45 08             	mov    0x8(%ebp),%eax
400004fa:	0f b6 00             	movzbl (%eax),%eax
400004fd:	0f be c0             	movsbl %al,%eax
40000500:	89 44 24 04          	mov    %eax,0x4(%esp)
40000504:	c7 04 24 7c 5a 00 40 	movl   $0x40005a7c,(%esp)
4000050b:	e8 2d 10 00 00       	call   4000153d <strchr>
40000510:	85 c0                	test   %eax,%eax
40000512:	75 cf                	jne    400004e3 <_gettoken+0x5d>
		*s++ = 0;
	if (*s == 0) {
40000514:	8b 45 08             	mov    0x8(%ebp),%eax
40000517:	0f b6 00             	movzbl (%eax),%eax
4000051a:	84 c0                	test   %al,%al
4000051c:	75 20                	jne    4000053e <_gettoken+0xb8>
		if (debug > 1)
4000051e:	a1 00 84 00 40       	mov    0x40008400,%eax
40000523:	83 f8 01             	cmp    $0x1,%eax
40000526:	7e 0c                	jle    40000534 <_gettoken+0xae>
			cprintf("EOL\n");
40000528:	c7 04 24 81 5a 00 40 	movl   $0x40005a81,(%esp)
4000052f:	e8 a4 07 00 00       	call   40000cd8 <cprintf>
		return 0;
40000534:	b8 00 00 00 00       	mov    $0x0,%eax
40000539:	e9 e9 00 00 00       	jmp    40000627 <_gettoken+0x1a1>
	}
	if (strchr(SYMBOLS, *s)) {
4000053e:	8b 45 08             	mov    0x8(%ebp),%eax
40000541:	0f b6 00             	movzbl (%eax),%eax
40000544:	0f be c0             	movsbl %al,%eax
40000547:	89 44 24 04          	mov    %eax,0x4(%esp)
4000054b:	c7 04 24 86 5a 00 40 	movl   $0x40005a86,(%esp)
40000552:	e8 e6 0f 00 00       	call   4000153d <strchr>
40000557:	85 c0                	test   %eax,%eax
40000559:	74 4b                	je     400005a6 <_gettoken+0x120>
		t = *s;
4000055b:	8b 45 08             	mov    0x8(%ebp),%eax
4000055e:	0f b6 00             	movzbl (%eax),%eax
40000561:	0f be c0             	movsbl %al,%eax
40000564:	89 45 f4             	mov    %eax,-0xc(%ebp)
		*p1 = s;
40000567:	8b 45 0c             	mov    0xc(%ebp),%eax
4000056a:	8b 55 08             	mov    0x8(%ebp),%edx
4000056d:	89 10                	mov    %edx,(%eax)
		*s++ = 0;
4000056f:	8b 45 08             	mov    0x8(%ebp),%eax
40000572:	c6 00 00             	movb   $0x0,(%eax)
40000575:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		*p2 = s;
40000579:	8b 45 10             	mov    0x10(%ebp),%eax
4000057c:	8b 55 08             	mov    0x8(%ebp),%edx
4000057f:	89 10                	mov    %edx,(%eax)
		if (debug > 1)
40000581:	a1 00 84 00 40       	mov    0x40008400,%eax
40000586:	83 f8 01             	cmp    $0x1,%eax
40000589:	7e 13                	jle    4000059e <_gettoken+0x118>
			cprintf("TOK %c\n", t);
4000058b:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000058e:	89 44 24 04          	mov    %eax,0x4(%esp)
40000592:	c7 04 24 8e 5a 00 40 	movl   $0x40005a8e,(%esp)
40000599:	e8 3a 07 00 00       	call   40000cd8 <cprintf>
		return t;
4000059e:	8b 45 f4             	mov    -0xc(%ebp),%eax
400005a1:	e9 81 00 00 00       	jmp    40000627 <_gettoken+0x1a1>
	}
	*p1 = s;
400005a6:	8b 45 0c             	mov    0xc(%ebp),%eax
400005a9:	8b 55 08             	mov    0x8(%ebp),%edx
400005ac:	89 10                	mov    %edx,(%eax)
	while (*s && !strchr(WHITESPACE SYMBOLS, *s))
400005ae:	eb 04                	jmp    400005b4 <_gettoken+0x12e>
		s++;
400005b0:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		if (debug > 1)
			cprintf("TOK %c\n", t);
		return t;
	}
	*p1 = s;
	while (*s && !strchr(WHITESPACE SYMBOLS, *s))
400005b4:	8b 45 08             	mov    0x8(%ebp),%eax
400005b7:	0f b6 00             	movzbl (%eax),%eax
400005ba:	84 c0                	test   %al,%al
400005bc:	74 1d                	je     400005db <_gettoken+0x155>
400005be:	8b 45 08             	mov    0x8(%ebp),%eax
400005c1:	0f b6 00             	movzbl (%eax),%eax
400005c4:	0f be c0             	movsbl %al,%eax
400005c7:	89 44 24 04          	mov    %eax,0x4(%esp)
400005cb:	c7 04 24 96 5a 00 40 	movl   $0x40005a96,(%esp)
400005d2:	e8 66 0f 00 00       	call   4000153d <strchr>
400005d7:	85 c0                	test   %eax,%eax
400005d9:	74 d5                	je     400005b0 <_gettoken+0x12a>
		s++;
	*p2 = s;
400005db:	8b 45 10             	mov    0x10(%ebp),%eax
400005de:	8b 55 08             	mov    0x8(%ebp),%edx
400005e1:	89 10                	mov    %edx,(%eax)
	if (debug > 1) {
400005e3:	a1 00 84 00 40       	mov    0x40008400,%eax
400005e8:	83 f8 01             	cmp    $0x1,%eax
400005eb:	7e 35                	jle    40000622 <_gettoken+0x19c>
		t = **p2;
400005ed:	8b 45 10             	mov    0x10(%ebp),%eax
400005f0:	8b 00                	mov    (%eax),%eax
400005f2:	0f b6 00             	movzbl (%eax),%eax
400005f5:	0f be c0             	movsbl %al,%eax
400005f8:	89 45 f4             	mov    %eax,-0xc(%ebp)
		**p2 = 0;
400005fb:	8b 45 10             	mov    0x10(%ebp),%eax
400005fe:	8b 00                	mov    (%eax),%eax
40000600:	c6 00 00             	movb   $0x0,(%eax)
		cprintf("WORD: %s\n", *p1);
40000603:	8b 45 0c             	mov    0xc(%ebp),%eax
40000606:	8b 00                	mov    (%eax),%eax
40000608:	89 44 24 04          	mov    %eax,0x4(%esp)
4000060c:	c7 04 24 a2 5a 00 40 	movl   $0x40005aa2,(%esp)
40000613:	e8 c0 06 00 00       	call   40000cd8 <cprintf>
		**p2 = t;
40000618:	8b 45 10             	mov    0x10(%ebp),%eax
4000061b:	8b 00                	mov    (%eax),%eax
4000061d:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000620:	88 10                	mov    %dl,(%eax)
	}
	return 'w';
40000622:	b8 77 00 00 00       	mov    $0x77,%eax
}
40000627:	c9                   	leave  
40000628:	c3                   	ret    

40000629 <gettoken>:

int
gettoken(char *s, char **p1)
{
40000629:	55                   	push   %ebp
4000062a:	89 e5                	mov    %esp,%ebp
4000062c:	83 ec 18             	sub    $0x18,%esp
	static int c, nc;
	static char* np1, *np2;

	if (s) {
4000062f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40000633:	74 27                	je     4000065c <gettoken+0x33>
		nc = _gettoken(s, &np1, &np2);
40000635:	c7 44 24 08 08 84 00 	movl   $0x40008408,0x8(%esp)
4000063c:	40 
4000063d:	c7 44 24 04 04 84 00 	movl   $0x40008404,0x4(%esp)
40000644:	40 
40000645:	8b 45 08             	mov    0x8(%ebp),%eax
40000648:	89 04 24             	mov    %eax,(%esp)
4000064b:	e8 36 fe ff ff       	call   40000486 <_gettoken>
40000650:	a3 0c 84 00 40       	mov    %eax,0x4000840c
		return 0;
40000655:	b8 00 00 00 00       	mov    $0x0,%eax
4000065a:	eb 3c                	jmp    40000698 <gettoken+0x6f>
	}
	c = nc;
4000065c:	a1 0c 84 00 40       	mov    0x4000840c,%eax
40000661:	a3 10 84 00 40       	mov    %eax,0x40008410
	*p1 = np1;
40000666:	8b 15 04 84 00 40    	mov    0x40008404,%edx
4000066c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000066f:	89 10                	mov    %edx,(%eax)
	nc = _gettoken(np2, &np1, &np2);
40000671:	a1 08 84 00 40       	mov    0x40008408,%eax
40000676:	c7 44 24 08 08 84 00 	movl   $0x40008408,0x8(%esp)
4000067d:	40 
4000067e:	c7 44 24 04 04 84 00 	movl   $0x40008404,0x4(%esp)
40000685:	40 
40000686:	89 04 24             	mov    %eax,(%esp)
40000689:	e8 f8 fd ff ff       	call   40000486 <_gettoken>
4000068e:	a3 0c 84 00 40       	mov    %eax,0x4000840c
	return c;
40000693:	a1 10 84 00 40       	mov    0x40008410,%eax
}
40000698:	c9                   	leave  
40000699:	c3                   	ret    

4000069a <usage>:


void
usage(void)
{
4000069a:	55                   	push   %ebp
4000069b:	89 e5                	mov    %esp,%ebp
4000069d:	83 ec 18             	sub    $0x18,%esp
	cprintf("usage: sh [-dix] [command-file]\n");
400006a0:	c7 04 24 ac 5a 00 40 	movl   $0x40005aac,(%esp)
400006a7:	e8 2c 06 00 00       	call   40000cd8 <cprintf>
	exit(EXIT_FAILURE);
400006ac:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
400006b3:	e8 98 2e 00 00       	call   40003550 <exit>

400006b8 <main>:
}

int
main(int argc, char **argv)
{
400006b8:	55                   	push   %ebp
400006b9:	89 e5                	mov    %esp,%ebp
400006bb:	83 e4 f0             	and    $0xfffffff0,%esp
400006be:	83 ec 40             	sub    $0x40,%esp
	int r, interactive, echocmds;

	interactive = '?';
400006c1:	c7 44 24 3c 3f 00 00 	movl   $0x3f,0x3c(%esp)
400006c8:	00 
	echocmds = 0;
400006c9:	c7 44 24 38 00 00 00 	movl   $0x0,0x38(%esp)
400006d0:	00 
	ARGBEGIN{
400006d1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400006d5:	75 06                	jne    400006dd <main+0x25>
400006d7:	8d 45 08             	lea    0x8(%ebp),%eax
400006da:	89 45 0c             	mov    %eax,0xc(%ebp)
400006dd:	a1 60 88 00 40       	mov    0x40008860,%eax
400006e2:	85 c0                	test   %eax,%eax
400006e4:	75 0a                	jne    400006f0 <main+0x38>
400006e6:	8b 45 0c             	mov    0xc(%ebp),%eax
400006e9:	8b 00                	mov    (%eax),%eax
400006eb:	a3 60 88 00 40       	mov    %eax,0x40008860
400006f0:	83 45 0c 04          	addl   $0x4,0xc(%ebp)
400006f4:	8b 45 08             	mov    0x8(%ebp),%eax
400006f7:	83 e8 01             	sub    $0x1,%eax
400006fa:	89 45 08             	mov    %eax,0x8(%ebp)
400006fd:	e9 b6 00 00 00       	jmp    400007b8 <main+0x100>
40000702:	8b 45 0c             	mov    0xc(%ebp),%eax
40000705:	8b 00                	mov    (%eax),%eax
40000707:	83 c0 01             	add    $0x1,%eax
4000070a:	89 44 24 34          	mov    %eax,0x34(%esp)
4000070e:	8b 44 24 34          	mov    0x34(%esp),%eax
40000712:	0f b6 00             	movzbl (%eax),%eax
40000715:	3c 2d                	cmp    $0x2d,%al
40000717:	75 20                	jne    40000739 <main+0x81>
40000719:	8b 44 24 34          	mov    0x34(%esp),%eax
4000071d:	83 c0 01             	add    $0x1,%eax
40000720:	0f b6 00             	movzbl (%eax),%eax
40000723:	84 c0                	test   %al,%al
40000725:	75 12                	jne    40000739 <main+0x81>
40000727:	8b 45 08             	mov    0x8(%ebp),%eax
4000072a:	83 e8 01             	sub    $0x1,%eax
4000072d:	89 45 08             	mov    %eax,0x8(%ebp)
40000730:	83 45 0c 04          	addl   $0x4,0xc(%ebp)
40000734:	e9 a7 00 00 00       	jmp    400007e0 <main+0x128>
40000739:	c6 44 24 33 00       	movb   $0x0,0x33(%esp)
4000073e:	eb 3c                	jmp    4000077c <main+0xc4>
40000740:	0f be 44 24 33       	movsbl 0x33(%esp),%eax
40000745:	83 f8 69             	cmp    $0x69,%eax
40000748:	74 19                	je     40000763 <main+0xab>
4000074a:	83 f8 78             	cmp    $0x78,%eax
4000074d:	74 1e                	je     4000076d <main+0xb5>
4000074f:	83 f8 64             	cmp    $0x64,%eax
40000752:	75 23                	jne    40000777 <main+0xbf>
	case 'd':
		debug++;
40000754:	a1 00 84 00 40       	mov    0x40008400,%eax
40000759:	83 c0 01             	add    $0x1,%eax
4000075c:	a3 00 84 00 40       	mov    %eax,0x40008400
		break;
40000761:	eb 19                	jmp    4000077c <main+0xc4>
	case 'i':
		interactive = 1;
40000763:	c7 44 24 3c 01 00 00 	movl   $0x1,0x3c(%esp)
4000076a:	00 
		break;
4000076b:	eb 0f                	jmp    4000077c <main+0xc4>
	case 'x':
		echocmds = 1;
4000076d:	c7 44 24 38 01 00 00 	movl   $0x1,0x38(%esp)
40000774:	00 
		break;
40000775:	eb 05                	jmp    4000077c <main+0xc4>
	default:
		usage();
40000777:	e8 1e ff ff ff       	call   4000069a <usage>
{
	int r, interactive, echocmds;

	interactive = '?';
	echocmds = 0;
	ARGBEGIN{
4000077c:	8b 44 24 34          	mov    0x34(%esp),%eax
40000780:	0f b6 00             	movzbl (%eax),%eax
40000783:	84 c0                	test   %al,%al
40000785:	74 1c                	je     400007a3 <main+0xeb>
40000787:	8b 44 24 34          	mov    0x34(%esp),%eax
4000078b:	0f b6 00             	movzbl (%eax),%eax
4000078e:	88 44 24 33          	mov    %al,0x33(%esp)
40000792:	80 7c 24 33 00       	cmpb   $0x0,0x33(%esp)
40000797:	0f 95 c0             	setne  %al
4000079a:	83 44 24 34 01       	addl   $0x1,0x34(%esp)
4000079f:	84 c0                	test   %al,%al
400007a1:	75 9d                	jne    40000740 <main+0x88>
	case 'x':
		echocmds = 1;
		break;
	default:
		usage();
	}ARGEND
400007a3:	c7 44 24 2c 00 00 00 	movl   $0x0,0x2c(%esp)
400007aa:	00 
{
	int r, interactive, echocmds;

	interactive = '?';
	echocmds = 0;
	ARGBEGIN{
400007ab:	8b 45 08             	mov    0x8(%ebp),%eax
400007ae:	83 e8 01             	sub    $0x1,%eax
400007b1:	89 45 08             	mov    %eax,0x8(%ebp)
400007b4:	83 45 0c 04          	addl   $0x4,0xc(%ebp)
400007b8:	8b 45 0c             	mov    0xc(%ebp),%eax
400007bb:	8b 00                	mov    (%eax),%eax
400007bd:	85 c0                	test   %eax,%eax
400007bf:	74 1f                	je     400007e0 <main+0x128>
400007c1:	8b 45 0c             	mov    0xc(%ebp),%eax
400007c4:	8b 00                	mov    (%eax),%eax
400007c6:	0f b6 00             	movzbl (%eax),%eax
400007c9:	3c 2d                	cmp    $0x2d,%al
400007cb:	75 13                	jne    400007e0 <main+0x128>
400007cd:	8b 45 0c             	mov    0xc(%ebp),%eax
400007d0:	8b 00                	mov    (%eax),%eax
400007d2:	83 c0 01             	add    $0x1,%eax
400007d5:	0f b6 00             	movzbl (%eax),%eax
400007d8:	84 c0                	test   %al,%al
400007da:	0f 85 22 ff ff ff    	jne    40000702 <main+0x4a>
		break;
	default:
		usage();
	}ARGEND

	if (argc > 1)
400007e0:	8b 45 08             	mov    0x8(%ebp),%eax
400007e3:	83 f8 01             	cmp    $0x1,%eax
400007e6:	7e 05                	jle    400007ed <main+0x135>
		usage();
400007e8:	e8 ad fe ff ff       	call   4000069a <usage>
	if (argc == 1) {
400007ed:	8b 45 08             	mov    0x8(%ebp),%eax
400007f0:	83 f8 01             	cmp    $0x1,%eax
400007f3:	0f 85 8f 00 00 00    	jne    40000888 <main+0x1d0>
		close(0);
400007f9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000800:	e8 37 2e 00 00       	call   4000363c <close>
		if ((r = open(argv[0], O_RDONLY)) < 0)
40000805:	8b 45 0c             	mov    0xc(%ebp),%eax
40000808:	8b 00                	mov    (%eax),%eax
4000080a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40000811:	00 
40000812:	89 04 24             	mov    %eax,(%esp)
40000815:	e8 ac 2d 00 00       	call   400035c6 <open>
4000081a:	89 44 24 28          	mov    %eax,0x28(%esp)
4000081e:	83 7c 24 28 00       	cmpl   $0x0,0x28(%esp)
40000823:	79 38                	jns    4000085d <main+0x1a5>
			panic("open %s: %s", argv[0], strerror(errno));
40000825:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
4000082a:	8b 00                	mov    (%eax),%eax
4000082c:	89 04 24             	mov    %eax,(%esp)
4000082f:	e8 30 4b 00 00       	call   40005364 <strerror>
40000834:	8b 55 0c             	mov    0xc(%ebp),%edx
40000837:	8b 12                	mov    (%edx),%edx
40000839:	89 44 24 10          	mov    %eax,0x10(%esp)
4000083d:	89 54 24 0c          	mov    %edx,0xc(%esp)
40000841:	c7 44 24 08 cd 5a 00 	movl   $0x40005acd,0x8(%esp)
40000848:	40 
40000849:	c7 44 24 04 f8 00 00 	movl   $0xf8,0x4(%esp)
40000850:	00 
40000851:	c7 04 24 2c 5a 00 40 	movl   $0x40005a2c,(%esp)
40000858:	e8 e7 01 00 00       	call   40000a44 <debug_panic>
		assert(r == 0);
4000085d:	83 7c 24 28 00       	cmpl   $0x0,0x28(%esp)
40000862:	74 24                	je     40000888 <main+0x1d0>
40000864:	c7 44 24 0c d9 5a 00 	movl   $0x40005ad9,0xc(%esp)
4000086b:	40 
4000086c:	c7 44 24 08 e0 5a 00 	movl   $0x40005ae0,0x8(%esp)
40000873:	40 
40000874:	c7 44 24 04 f9 00 00 	movl   $0xf9,0x4(%esp)
4000087b:	00 
4000087c:	c7 04 24 2c 5a 00 40 	movl   $0x40005a2c,(%esp)
40000883:	e8 bc 01 00 00       	call   40000a44 <debug_panic>
	}
	if (interactive == '?')
40000888:	83 7c 24 3c 3f       	cmpl   $0x3f,0x3c(%esp)
4000088d:	75 10                	jne    4000089f <main+0x1e7>
		interactive = isatty(0);
4000088f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000896:	e8 80 30 00 00       	call   4000391b <isatty>
4000089b:	89 44 24 3c          	mov    %eax,0x3c(%esp)

	while (1) {
		char *buf;

		buf = readline(interactive ? "$ " : NULL);
4000089f:	83 7c 24 3c 00       	cmpl   $0x0,0x3c(%esp)
400008a4:	74 07                	je     400008ad <main+0x1f5>
400008a6:	b8 f5 5a 00 40       	mov    $0x40005af5,%eax
400008ab:	eb 05                	jmp    400008b2 <main+0x1fa>
400008ad:	b8 00 00 00 00       	mov    $0x0,%eax
400008b2:	89 04 24             	mov    %eax,(%esp)
400008b5:	e8 f6 4a 00 00       	call   400053b0 <readline>
400008ba:	89 44 24 24          	mov    %eax,0x24(%esp)
		if (buf == NULL) {
400008be:	83 7c 24 24 00       	cmpl   $0x0,0x24(%esp)
400008c3:	75 21                	jne    400008e6 <main+0x22e>
			if (debug)
400008c5:	a1 00 84 00 40       	mov    0x40008400,%eax
400008ca:	85 c0                	test   %eax,%eax
400008cc:	74 0c                	je     400008da <main+0x222>
				cprintf("EXITING\n");
400008ce:	c7 04 24 f8 5a 00 40 	movl   $0x40005af8,(%esp)
400008d5:	e8 fe 03 00 00       	call   40000cd8 <cprintf>
			exit(EXIT_SUCCESS);	// end of file
400008da:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400008e1:	e8 6a 2c 00 00       	call   40003550 <exit>
		}
		if (debug)
400008e6:	a1 00 84 00 40       	mov    0x40008400,%eax
400008eb:	85 c0                	test   %eax,%eax
400008ed:	74 14                	je     40000903 <main+0x24b>
			cprintf("LINE: %s\n", buf);
400008ef:	8b 44 24 24          	mov    0x24(%esp),%eax
400008f3:	89 44 24 04          	mov    %eax,0x4(%esp)
400008f7:	c7 04 24 01 5b 00 40 	movl   $0x40005b01,(%esp)
400008fe:	e8 d5 03 00 00       	call   40000cd8 <cprintf>
		if (buf[0] == '#')
40000903:	8b 44 24 24          	mov    0x24(%esp),%eax
40000907:	0f b6 00             	movzbl (%eax),%eax
4000090a:	3c 23                	cmp    $0x23,%al
4000090c:	0f 84 2a 01 00 00    	je     40000a3c <main+0x384>
			continue;
		if (echocmds)
40000912:	83 7c 24 38 00       	cmpl   $0x0,0x38(%esp)
40000917:	74 1d                	je     40000936 <main+0x27e>
			fprintf(stdout, "# %s\n", buf);
40000919:	a1 8c 60 00 40       	mov    0x4000608c,%eax
4000091e:	8b 54 24 24          	mov    0x24(%esp),%edx
40000922:	89 54 24 08          	mov    %edx,0x8(%esp)
40000926:	c7 44 24 04 0b 5b 00 	movl   $0x40005b0b,0x4(%esp)
4000092d:	40 
4000092e:	89 04 24             	mov    %eax,(%esp)
40000931:	e8 cd 49 00 00       	call   40005303 <fprintf>
		if (strcmp(buf, "exit") == 0)	// built-in command
40000936:	c7 44 24 04 11 5b 00 	movl   $0x40005b11,0x4(%esp)
4000093d:	40 
4000093e:	8b 44 24 24          	mov    0x24(%esp),%eax
40000942:	89 04 24             	mov    %eax,(%esp)
40000945:	e8 5a 0b 00 00       	call   400014a4 <strcmp>
4000094a:	85 c0                	test   %eax,%eax
4000094c:	75 0c                	jne    4000095a <main+0x2a2>
			exit(0);
4000094e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000955:	e8 f6 2b 00 00       	call   40003550 <exit>
		if (strcmp(buf, "cwd") == 0) {
4000095a:	c7 44 24 04 16 5b 00 	movl   $0x40005b16,0x4(%esp)
40000961:	40 
40000962:	8b 44 24 24          	mov    0x24(%esp),%eax
40000966:	89 04 24             	mov    %eax,(%esp)
40000969:	e8 36 0b 00 00       	call   400014a4 <strcmp>
4000096e:	85 c0                	test   %eax,%eax
40000970:	75 30                	jne    400009a2 <main+0x2ea>
			printf("%s\n", files->fi[files->cwd].de.d_name);
40000972:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40000978:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
4000097d:	8b 40 04             	mov    0x4(%eax),%eax
40000980:	6b c0 5c             	imul   $0x5c,%eax,%eax
40000983:	05 10 10 00 00       	add    $0x1010,%eax
40000988:	01 d0                	add    %edx,%eax
4000098a:	83 c0 04             	add    $0x4,%eax
4000098d:	89 44 24 04          	mov    %eax,0x4(%esp)
40000991:	c7 04 24 1a 5b 00 40 	movl   $0x40005b1a,(%esp)
40000998:	e8 96 49 00 00       	call   40005333 <printf>
			continue;
4000099d:	e9 9b 00 00 00       	jmp    40000a3d <main+0x385>
		}
		if (debug)
400009a2:	a1 00 84 00 40       	mov    0x40008400,%eax
400009a7:	85 c0                	test   %eax,%eax
400009a9:	74 0c                	je     400009b7 <main+0x2ff>
			cprintf("BEFORE FORK\n");
400009ab:	c7 04 24 1e 5b 00 40 	movl   $0x40005b1e,(%esp)
400009b2:	e8 21 03 00 00       	call   40000cd8 <cprintf>
		if ((r = fork()) < 0)
400009b7:	e8 88 31 00 00       	call   40003b44 <fork>
400009bc:	89 44 24 28          	mov    %eax,0x28(%esp)
400009c0:	83 7c 24 28 00       	cmpl   $0x0,0x28(%esp)
400009c5:	79 24                	jns    400009eb <main+0x333>
			panic("fork: %e", r);
400009c7:	8b 44 24 28          	mov    0x28(%esp),%eax
400009cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
400009cf:	c7 44 24 08 2b 5b 00 	movl   $0x40005b2b,0x8(%esp)
400009d6:	40 
400009d7:	c7 44 24 04 16 01 00 	movl   $0x116,0x4(%esp)
400009de:	00 
400009df:	c7 04 24 2c 5a 00 40 	movl   $0x40005a2c,(%esp)
400009e6:	e8 59 00 00 00       	call   40000a44 <debug_panic>
		if (debug)
400009eb:	a1 00 84 00 40       	mov    0x40008400,%eax
400009f0:	85 c0                	test   %eax,%eax
400009f2:	74 14                	je     40000a08 <main+0x350>
			cprintf("FORK: %d\n", r);
400009f4:	8b 44 24 28          	mov    0x28(%esp),%eax
400009f8:	89 44 24 04          	mov    %eax,0x4(%esp)
400009fc:	c7 04 24 34 5b 00 40 	movl   $0x40005b34,(%esp)
40000a03:	e8 d0 02 00 00       	call   40000cd8 <cprintf>
		if (r == 0) {
40000a08:	83 7c 24 28 00       	cmpl   $0x0,0x28(%esp)
40000a0d:	75 0c                	jne    40000a1b <main+0x363>
			runcmd(buf);
40000a0f:	8b 44 24 24          	mov    0x24(%esp),%eax
40000a13:	89 04 24             	mov    %eax,(%esp)
40000a16:	e8 29 f7 ff ff       	call   40000144 <runcmd>
			exit(EXIT_SUCCESS);
		} else
			waitpid(r, NULL, 0);
40000a1b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
40000a22:	00 
40000a23:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000a2a:	00 
40000a2b:	8b 44 24 28          	mov    0x28(%esp),%eax
40000a2f:	89 04 24             	mov    %eax,(%esp)
40000a32:	e8 90 33 00 00       	call   40003dc7 <waitpid>
	}
40000a37:	e9 63 fe ff ff       	jmp    4000089f <main+0x1e7>
			exit(EXIT_SUCCESS);	// end of file
		}
		if (debug)
			cprintf("LINE: %s\n", buf);
		if (buf[0] == '#')
			continue;
40000a3c:	90                   	nop
		if (r == 0) {
			runcmd(buf);
			exit(EXIT_SUCCESS);
		} else
			waitpid(r, NULL, 0);
	}
40000a3d:	e9 5d fe ff ff       	jmp    4000089f <main+0x1e7>
40000a42:	66 90                	xchg   %ax,%ax

40000a44 <debug_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: <message>", then causes a breakpoint exception.
 */
void
debug_panic(const char *file, int line, const char *fmt,...)
{
40000a44:	55                   	push   %ebp
40000a45:	89 e5                	mov    %esp,%ebp
40000a47:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	va_start(ap, fmt);
40000a4a:	8d 45 10             	lea    0x10(%ebp),%eax
40000a4d:	83 c0 04             	add    $0x4,%eax
40000a50:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Print the panic message
	if (argv0)
40000a53:	a1 60 88 00 40       	mov    0x40008860,%eax
40000a58:	85 c0                	test   %eax,%eax
40000a5a:	74 15                	je     40000a71 <debug_panic+0x2d>
		cprintf("%s: ", argv0);
40000a5c:	a1 60 88 00 40       	mov    0x40008860,%eax
40000a61:	89 44 24 04          	mov    %eax,0x4(%esp)
40000a65:	c7 04 24 40 5b 00 40 	movl   $0x40005b40,(%esp)
40000a6c:	e8 67 02 00 00       	call   40000cd8 <cprintf>
	cprintf("user panic at %s:%d: ", file, line);
40000a71:	8b 45 0c             	mov    0xc(%ebp),%eax
40000a74:	89 44 24 08          	mov    %eax,0x8(%esp)
40000a78:	8b 45 08             	mov    0x8(%ebp),%eax
40000a7b:	89 44 24 04          	mov    %eax,0x4(%esp)
40000a7f:	c7 04 24 45 5b 00 40 	movl   $0x40005b45,(%esp)
40000a86:	e8 4d 02 00 00       	call   40000cd8 <cprintf>
	vcprintf(fmt, ap);
40000a8b:	8b 45 10             	mov    0x10(%ebp),%eax
40000a8e:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000a91:	89 54 24 04          	mov    %edx,0x4(%esp)
40000a95:	89 04 24             	mov    %eax,(%esp)
40000a98:	e8 d3 01 00 00       	call   40000c70 <vcprintf>
	cprintf("\n");
40000a9d:	c7 04 24 5b 5b 00 40 	movl   $0x40005b5b,(%esp)
40000aa4:	e8 2f 02 00 00       	call   40000cd8 <cprintf>

	abort();
40000aa9:	e8 e2 2a 00 00       	call   40003590 <abort>

40000aae <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
40000aae:	55                   	push   %ebp
40000aaf:	89 e5                	mov    %esp,%ebp
40000ab1:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
40000ab4:	8d 45 10             	lea    0x10(%ebp),%eax
40000ab7:	83 c0 04             	add    $0x4,%eax
40000aba:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("user warning at %s:%d: ", file, line);
40000abd:	8b 45 0c             	mov    0xc(%ebp),%eax
40000ac0:	89 44 24 08          	mov    %eax,0x8(%esp)
40000ac4:	8b 45 08             	mov    0x8(%ebp),%eax
40000ac7:	89 44 24 04          	mov    %eax,0x4(%esp)
40000acb:	c7 04 24 5d 5b 00 40 	movl   $0x40005b5d,(%esp)
40000ad2:	e8 01 02 00 00       	call   40000cd8 <cprintf>
	vcprintf(fmt, ap);
40000ad7:	8b 45 10             	mov    0x10(%ebp),%eax
40000ada:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000add:	89 54 24 04          	mov    %edx,0x4(%esp)
40000ae1:	89 04 24             	mov    %eax,(%esp)
40000ae4:	e8 87 01 00 00       	call   40000c70 <vcprintf>
	cprintf("\n");
40000ae9:	c7 04 24 5b 5b 00 40 	movl   $0x40005b5b,(%esp)
40000af0:	e8 e3 01 00 00       	call   40000cd8 <cprintf>
	va_end(ap);
}
40000af5:	c9                   	leave  
40000af6:	c3                   	ret    

40000af7 <debug_dump>:

// Dump a block of memory as 32-bit words and ASCII bytes
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
40000af7:	55                   	push   %ebp
40000af8:	89 e5                	mov    %esp,%ebp
40000afa:	56                   	push   %esi
40000afb:	53                   	push   %ebx
40000afc:	81 ec a0 00 00 00    	sub    $0xa0,%esp
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
40000b02:	8b 55 14             	mov    0x14(%ebp),%edx
40000b05:	8b 45 10             	mov    0x10(%ebp),%eax
40000b08:	01 d0                	add    %edx,%eax
40000b0a:	89 44 24 10          	mov    %eax,0x10(%esp)
40000b0e:	8b 45 10             	mov    0x10(%ebp),%eax
40000b11:	89 44 24 0c          	mov    %eax,0xc(%esp)
40000b15:	8b 45 0c             	mov    0xc(%ebp),%eax
40000b18:	89 44 24 08          	mov    %eax,0x8(%esp)
40000b1c:	8b 45 08             	mov    0x8(%ebp),%eax
40000b1f:	89 44 24 04          	mov    %eax,0x4(%esp)
40000b23:	c7 04 24 78 5b 00 40 	movl   $0x40005b78,(%esp)
40000b2a:	e8 a9 01 00 00       	call   40000cd8 <cprintf>
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
40000b2f:	8b 45 14             	mov    0x14(%ebp),%eax
40000b32:	83 c0 0f             	add    $0xf,%eax
40000b35:	83 e0 f0             	and    $0xfffffff0,%eax
40000b38:	89 45 14             	mov    %eax,0x14(%ebp)
40000b3b:	e9 bb 00 00 00       	jmp    40000bfb <debug_dump+0x104>
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
40000b40:	8b 45 10             	mov    0x10(%ebp),%eax
40000b43:	89 45 f0             	mov    %eax,-0x10(%ebp)
		for (i = 0; i < 16; i++)
40000b46:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
40000b4d:	eb 4d                	jmp    40000b9c <debug_dump+0xa5>
			buf[i] = isprint(c[i]) ? c[i] : '.';
40000b4f:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000b52:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000b55:	01 d0                	add    %edx,%eax
40000b57:	0f b6 00             	movzbl (%eax),%eax
40000b5a:	0f b6 c0             	movzbl %al,%eax
40000b5d:	89 45 e8             	mov    %eax,-0x18(%ebp)
static gcc_inline int isalnum(int c)	{ return isalpha(c) || isdigit(c); }
static gcc_inline int iscntrl(int c)	{ return c < ' '; }
static gcc_inline int isblank(int c)	{ return c == ' ' || c == '\t'; }
static gcc_inline int isspace(int c)	{ return c == ' '
						|| (c >= '\t' && c <= '\r'); }
static gcc_inline int isprint(int c)	{ return c >= ' ' && c <= '~'; }
40000b60:	83 7d e8 1f          	cmpl   $0x1f,-0x18(%ebp)
40000b64:	7e 0d                	jle    40000b73 <debug_dump+0x7c>
40000b66:	83 7d e8 7e          	cmpl   $0x7e,-0x18(%ebp)
40000b6a:	7f 07                	jg     40000b73 <debug_dump+0x7c>
40000b6c:	b8 01 00 00 00       	mov    $0x1,%eax
40000b71:	eb 05                	jmp    40000b78 <debug_dump+0x81>
40000b73:	b8 00 00 00 00       	mov    $0x0,%eax
40000b78:	85 c0                	test   %eax,%eax
40000b7a:	74 0d                	je     40000b89 <debug_dump+0x92>
40000b7c:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000b7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000b82:	01 d0                	add    %edx,%eax
40000b84:	0f b6 00             	movzbl (%eax),%eax
40000b87:	eb 05                	jmp    40000b8e <debug_dump+0x97>
40000b89:	b8 2e 00 00 00       	mov    $0x2e,%eax
40000b8e:	8d 4d 84             	lea    -0x7c(%ebp),%ecx
40000b91:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000b94:	01 ca                	add    %ecx,%edx
40000b96:	88 02                	mov    %al,(%edx)
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
		for (i = 0; i < 16; i++)
40000b98:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40000b9c:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
40000ba0:	7e ad                	jle    40000b4f <debug_dump+0x58>
			buf[i] = isprint(c[i]) ? c[i] : '.';
		buf[16] = 0;
40000ba2:	c6 45 94 00          	movb   $0x0,-0x6c(%ebp)

		// Hex words
		const uint32_t *v = ptr;
40000ba6:	8b 45 10             	mov    0x10(%ebp),%eax
40000ba9:	89 45 ec             	mov    %eax,-0x14(%ebp)

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
			ptr, v[0], v[1], v[2], v[3], buf);
40000bac:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000baf:	83 c0 0c             	add    $0xc,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40000bb2:	8b 18                	mov    (%eax),%ebx
			ptr, v[0], v[1], v[2], v[3], buf);
40000bb4:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000bb7:	83 c0 08             	add    $0x8,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40000bba:	8b 08                	mov    (%eax),%ecx
			ptr, v[0], v[1], v[2], v[3], buf);
40000bbc:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000bbf:	83 c0 04             	add    $0x4,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40000bc2:	8b 10                	mov    (%eax),%edx
40000bc4:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000bc7:	8b 00                	mov    (%eax),%eax
			ptr, v[0], v[1], v[2], v[3], buf);
40000bc9:	8d 75 84             	lea    -0x7c(%ebp),%esi
40000bcc:	89 74 24 18          	mov    %esi,0x18(%esp)

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40000bd0:	89 5c 24 14          	mov    %ebx,0x14(%esp)
40000bd4:	89 4c 24 10          	mov    %ecx,0x10(%esp)
40000bd8:	89 54 24 0c          	mov    %edx,0xc(%esp)
40000bdc:	89 44 24 08          	mov    %eax,0x8(%esp)
40000be0:	8b 45 10             	mov    0x10(%ebp),%eax
40000be3:	89 44 24 04          	mov    %eax,0x4(%esp)
40000be7:	c7 04 24 a1 5b 00 40 	movl   $0x40005ba1,(%esp)
40000bee:	e8 e5 00 00 00       	call   40000cd8 <cprintf>
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
40000bf3:	83 6d 14 10          	subl   $0x10,0x14(%ebp)
40000bf7:	83 45 10 10          	addl   $0x10,0x10(%ebp)
40000bfb:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40000bff:	0f 8f 3b ff ff ff    	jg     40000b40 <debug_dump+0x49>

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
			ptr, v[0], v[1], v[2], v[3], buf);
	}
}
40000c05:	81 c4 a0 00 00 00    	add    $0xa0,%esp
40000c0b:	5b                   	pop    %ebx
40000c0c:	5e                   	pop    %esi
40000c0d:	5d                   	pop    %ebp
40000c0e:	c3                   	ret    
40000c0f:	90                   	nop

40000c10 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
40000c10:	55                   	push   %ebp
40000c11:	89 e5                	mov    %esp,%ebp
40000c13:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
40000c16:	8b 45 0c             	mov    0xc(%ebp),%eax
40000c19:	8b 00                	mov    (%eax),%eax
40000c1b:	8b 55 08             	mov    0x8(%ebp),%edx
40000c1e:	89 d1                	mov    %edx,%ecx
40000c20:	8b 55 0c             	mov    0xc(%ebp),%edx
40000c23:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
40000c27:	8d 50 01             	lea    0x1(%eax),%edx
40000c2a:	8b 45 0c             	mov    0xc(%ebp),%eax
40000c2d:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
40000c2f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000c32:	8b 00                	mov    (%eax),%eax
40000c34:	3d ff 00 00 00       	cmp    $0xff,%eax
40000c39:	75 24                	jne    40000c5f <putch+0x4f>
		b->buf[b->idx] = 0;
40000c3b:	8b 45 0c             	mov    0xc(%ebp),%eax
40000c3e:	8b 00                	mov    (%eax),%eax
40000c40:	8b 55 0c             	mov    0xc(%ebp),%edx
40000c43:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
40000c48:	8b 45 0c             	mov    0xc(%ebp),%eax
40000c4b:	83 c0 08             	add    $0x8,%eax
40000c4e:	89 04 24             	mov    %eax,(%esp)
40000c51:	e8 9a 48 00 00       	call   400054f0 <cputs>
		b->idx = 0;
40000c56:	8b 45 0c             	mov    0xc(%ebp),%eax
40000c59:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
40000c5f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000c62:	8b 40 04             	mov    0x4(%eax),%eax
40000c65:	8d 50 01             	lea    0x1(%eax),%edx
40000c68:	8b 45 0c             	mov    0xc(%ebp),%eax
40000c6b:	89 50 04             	mov    %edx,0x4(%eax)
}
40000c6e:	c9                   	leave  
40000c6f:	c3                   	ret    

40000c70 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
40000c70:	55                   	push   %ebp
40000c71:	89 e5                	mov    %esp,%ebp
40000c73:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
40000c79:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
40000c80:	00 00 00 
	b.cnt = 0;
40000c83:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
40000c8a:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
40000c8d:	8b 45 0c             	mov    0xc(%ebp),%eax
40000c90:	89 44 24 0c          	mov    %eax,0xc(%esp)
40000c94:	8b 45 08             	mov    0x8(%ebp),%eax
40000c97:	89 44 24 08          	mov    %eax,0x8(%esp)
40000c9b:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
40000ca1:	89 44 24 04          	mov    %eax,0x4(%esp)
40000ca5:	c7 04 24 10 0c 00 40 	movl   $0x40000c10,(%esp)
40000cac:	e8 70 03 00 00       	call   40001021 <vprintfmt>

	b.buf[b.idx] = 0;
40000cb1:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
40000cb7:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
40000cbe:	00 
	cputs(b.buf);
40000cbf:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
40000cc5:	83 c0 08             	add    $0x8,%eax
40000cc8:	89 04 24             	mov    %eax,(%esp)
40000ccb:	e8 20 48 00 00       	call   400054f0 <cputs>

	return b.cnt;
40000cd0:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
40000cd6:	c9                   	leave  
40000cd7:	c3                   	ret    

40000cd8 <cprintf>:

int
cprintf(const char *fmt, ...)
{
40000cd8:	55                   	push   %ebp
40000cd9:	89 e5                	mov    %esp,%ebp
40000cdb:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
40000cde:	8d 45 0c             	lea    0xc(%ebp),%eax
40000ce1:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
40000ce4:	8b 45 08             	mov    0x8(%ebp),%eax
40000ce7:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000cea:	89 54 24 04          	mov    %edx,0x4(%esp)
40000cee:	89 04 24             	mov    %eax,(%esp)
40000cf1:	e8 7a ff ff ff       	call   40000c70 <vcprintf>
40000cf6:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
40000cf9:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40000cfc:	c9                   	leave  
40000cfd:	c3                   	ret    
40000cfe:	66 90                	xchg   %ax,%ax

40000d00 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
40000d00:	55                   	push   %ebp
40000d01:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
40000d03:	8b 45 08             	mov    0x8(%ebp),%eax
40000d06:	8b 40 18             	mov    0x18(%eax),%eax
40000d09:	83 e0 02             	and    $0x2,%eax
40000d0c:	85 c0                	test   %eax,%eax
40000d0e:	74 1c                	je     40000d2c <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
40000d10:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d13:	8b 00                	mov    (%eax),%eax
40000d15:	8d 50 08             	lea    0x8(%eax),%edx
40000d18:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d1b:	89 10                	mov    %edx,(%eax)
40000d1d:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d20:	8b 00                	mov    (%eax),%eax
40000d22:	83 e8 08             	sub    $0x8,%eax
40000d25:	8b 50 04             	mov    0x4(%eax),%edx
40000d28:	8b 00                	mov    (%eax),%eax
40000d2a:	eb 47                	jmp    40000d73 <getuint+0x73>
	else if (st->flags & F_L)
40000d2c:	8b 45 08             	mov    0x8(%ebp),%eax
40000d2f:	8b 40 18             	mov    0x18(%eax),%eax
40000d32:	83 e0 01             	and    $0x1,%eax
40000d35:	85 c0                	test   %eax,%eax
40000d37:	74 1e                	je     40000d57 <getuint+0x57>
		return va_arg(*ap, unsigned long);
40000d39:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d3c:	8b 00                	mov    (%eax),%eax
40000d3e:	8d 50 04             	lea    0x4(%eax),%edx
40000d41:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d44:	89 10                	mov    %edx,(%eax)
40000d46:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d49:	8b 00                	mov    (%eax),%eax
40000d4b:	83 e8 04             	sub    $0x4,%eax
40000d4e:	8b 00                	mov    (%eax),%eax
40000d50:	ba 00 00 00 00       	mov    $0x0,%edx
40000d55:	eb 1c                	jmp    40000d73 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
40000d57:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d5a:	8b 00                	mov    (%eax),%eax
40000d5c:	8d 50 04             	lea    0x4(%eax),%edx
40000d5f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d62:	89 10                	mov    %edx,(%eax)
40000d64:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d67:	8b 00                	mov    (%eax),%eax
40000d69:	83 e8 04             	sub    $0x4,%eax
40000d6c:	8b 00                	mov    (%eax),%eax
40000d6e:	ba 00 00 00 00       	mov    $0x0,%edx
}
40000d73:	5d                   	pop    %ebp
40000d74:	c3                   	ret    

40000d75 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
40000d75:	55                   	push   %ebp
40000d76:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
40000d78:	8b 45 08             	mov    0x8(%ebp),%eax
40000d7b:	8b 40 18             	mov    0x18(%eax),%eax
40000d7e:	83 e0 02             	and    $0x2,%eax
40000d81:	85 c0                	test   %eax,%eax
40000d83:	74 1c                	je     40000da1 <getint+0x2c>
		return va_arg(*ap, long long);
40000d85:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d88:	8b 00                	mov    (%eax),%eax
40000d8a:	8d 50 08             	lea    0x8(%eax),%edx
40000d8d:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d90:	89 10                	mov    %edx,(%eax)
40000d92:	8b 45 0c             	mov    0xc(%ebp),%eax
40000d95:	8b 00                	mov    (%eax),%eax
40000d97:	83 e8 08             	sub    $0x8,%eax
40000d9a:	8b 50 04             	mov    0x4(%eax),%edx
40000d9d:	8b 00                	mov    (%eax),%eax
40000d9f:	eb 47                	jmp    40000de8 <getint+0x73>
	else if (st->flags & F_L)
40000da1:	8b 45 08             	mov    0x8(%ebp),%eax
40000da4:	8b 40 18             	mov    0x18(%eax),%eax
40000da7:	83 e0 01             	and    $0x1,%eax
40000daa:	85 c0                	test   %eax,%eax
40000dac:	74 1e                	je     40000dcc <getint+0x57>
		return va_arg(*ap, long);
40000dae:	8b 45 0c             	mov    0xc(%ebp),%eax
40000db1:	8b 00                	mov    (%eax),%eax
40000db3:	8d 50 04             	lea    0x4(%eax),%edx
40000db6:	8b 45 0c             	mov    0xc(%ebp),%eax
40000db9:	89 10                	mov    %edx,(%eax)
40000dbb:	8b 45 0c             	mov    0xc(%ebp),%eax
40000dbe:	8b 00                	mov    (%eax),%eax
40000dc0:	83 e8 04             	sub    $0x4,%eax
40000dc3:	8b 00                	mov    (%eax),%eax
40000dc5:	89 c2                	mov    %eax,%edx
40000dc7:	c1 fa 1f             	sar    $0x1f,%edx
40000dca:	eb 1c                	jmp    40000de8 <getint+0x73>
	else
		return va_arg(*ap, int);
40000dcc:	8b 45 0c             	mov    0xc(%ebp),%eax
40000dcf:	8b 00                	mov    (%eax),%eax
40000dd1:	8d 50 04             	lea    0x4(%eax),%edx
40000dd4:	8b 45 0c             	mov    0xc(%ebp),%eax
40000dd7:	89 10                	mov    %edx,(%eax)
40000dd9:	8b 45 0c             	mov    0xc(%ebp),%eax
40000ddc:	8b 00                	mov    (%eax),%eax
40000dde:	83 e8 04             	sub    $0x4,%eax
40000de1:	8b 00                	mov    (%eax),%eax
40000de3:	89 c2                	mov    %eax,%edx
40000de5:	c1 fa 1f             	sar    $0x1f,%edx
}
40000de8:	5d                   	pop    %ebp
40000de9:	c3                   	ret    

40000dea <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
40000dea:	55                   	push   %ebp
40000deb:	89 e5                	mov    %esp,%ebp
40000ded:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
40000df0:	eb 1a                	jmp    40000e0c <putpad+0x22>
		st->putch(st->padc, st->putdat);
40000df2:	8b 45 08             	mov    0x8(%ebp),%eax
40000df5:	8b 00                	mov    (%eax),%eax
40000df7:	8b 55 08             	mov    0x8(%ebp),%edx
40000dfa:	8b 4a 04             	mov    0x4(%edx),%ecx
40000dfd:	8b 55 08             	mov    0x8(%ebp),%edx
40000e00:	8b 52 08             	mov    0x8(%edx),%edx
40000e03:	89 4c 24 04          	mov    %ecx,0x4(%esp)
40000e07:	89 14 24             	mov    %edx,(%esp)
40000e0a:	ff d0                	call   *%eax

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
40000e0c:	8b 45 08             	mov    0x8(%ebp),%eax
40000e0f:	8b 40 0c             	mov    0xc(%eax),%eax
40000e12:	8d 50 ff             	lea    -0x1(%eax),%edx
40000e15:	8b 45 08             	mov    0x8(%ebp),%eax
40000e18:	89 50 0c             	mov    %edx,0xc(%eax)
40000e1b:	8b 45 08             	mov    0x8(%ebp),%eax
40000e1e:	8b 40 0c             	mov    0xc(%eax),%eax
40000e21:	85 c0                	test   %eax,%eax
40000e23:	79 cd                	jns    40000df2 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
40000e25:	c9                   	leave  
40000e26:	c3                   	ret    

40000e27 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
40000e27:	55                   	push   %ebp
40000e28:	89 e5                	mov    %esp,%ebp
40000e2a:	53                   	push   %ebx
40000e2b:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
40000e2e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000e32:	79 18                	jns    40000e4c <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
40000e34:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e3b:	00 
40000e3c:	8b 45 0c             	mov    0xc(%ebp),%eax
40000e3f:	89 04 24             	mov    %eax,(%esp)
40000e42:	e8 f6 06 00 00       	call   4000153d <strchr>
40000e47:	89 45 f4             	mov    %eax,-0xc(%ebp)
40000e4a:	eb 2e                	jmp    40000e7a <putstr+0x53>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
40000e4c:	8b 45 10             	mov    0x10(%ebp),%eax
40000e4f:	89 44 24 08          	mov    %eax,0x8(%esp)
40000e53:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e5a:	00 
40000e5b:	8b 45 0c             	mov    0xc(%ebp),%eax
40000e5e:	89 04 24             	mov    %eax,(%esp)
40000e61:	e8 d4 08 00 00       	call   4000173a <memchr>
40000e66:	89 45 f4             	mov    %eax,-0xc(%ebp)
40000e69:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40000e6d:	75 0b                	jne    40000e7a <putstr+0x53>
		lim = str + maxlen;
40000e6f:	8b 55 10             	mov    0x10(%ebp),%edx
40000e72:	8b 45 0c             	mov    0xc(%ebp),%eax
40000e75:	01 d0                	add    %edx,%eax
40000e77:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
40000e7a:	8b 45 08             	mov    0x8(%ebp),%eax
40000e7d:	8b 40 0c             	mov    0xc(%eax),%eax
40000e80:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40000e83:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000e86:	89 cb                	mov    %ecx,%ebx
40000e88:	29 d3                	sub    %edx,%ebx
40000e8a:	89 da                	mov    %ebx,%edx
40000e8c:	01 c2                	add    %eax,%edx
40000e8e:	8b 45 08             	mov    0x8(%ebp),%eax
40000e91:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
40000e94:	8b 45 08             	mov    0x8(%ebp),%eax
40000e97:	8b 40 18             	mov    0x18(%eax),%eax
40000e9a:	83 e0 10             	and    $0x10,%eax
40000e9d:	85 c0                	test   %eax,%eax
40000e9f:	75 32                	jne    40000ed3 <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
40000ea1:	8b 45 08             	mov    0x8(%ebp),%eax
40000ea4:	89 04 24             	mov    %eax,(%esp)
40000ea7:	e8 3e ff ff ff       	call   40000dea <putpad>
	while (str < lim) {
40000eac:	eb 25                	jmp    40000ed3 <putstr+0xac>
		char ch = *str++;
40000eae:	8b 45 0c             	mov    0xc(%ebp),%eax
40000eb1:	0f b6 00             	movzbl (%eax),%eax
40000eb4:	88 45 f3             	mov    %al,-0xd(%ebp)
40000eb7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
40000ebb:	8b 45 08             	mov    0x8(%ebp),%eax
40000ebe:	8b 00                	mov    (%eax),%eax
40000ec0:	8b 55 08             	mov    0x8(%ebp),%edx
40000ec3:	8b 4a 04             	mov    0x4(%edx),%ecx
40000ec6:	0f be 55 f3          	movsbl -0xd(%ebp),%edx
40000eca:	89 4c 24 04          	mov    %ecx,0x4(%esp)
40000ece:	89 14 24             	mov    %edx,(%esp)
40000ed1:	ff d0                	call   *%eax
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
40000ed3:	8b 45 0c             	mov    0xc(%ebp),%eax
40000ed6:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40000ed9:	72 d3                	jb     40000eae <putstr+0x87>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
40000edb:	8b 45 08             	mov    0x8(%ebp),%eax
40000ede:	89 04 24             	mov    %eax,(%esp)
40000ee1:	e8 04 ff ff ff       	call   40000dea <putpad>
}
40000ee6:	83 c4 24             	add    $0x24,%esp
40000ee9:	5b                   	pop    %ebx
40000eea:	5d                   	pop    %ebp
40000eeb:	c3                   	ret    

40000eec <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
40000eec:	55                   	push   %ebp
40000eed:	89 e5                	mov    %esp,%ebp
40000eef:	53                   	push   %ebx
40000ef0:	83 ec 24             	sub    $0x24,%esp
40000ef3:	8b 45 10             	mov    0x10(%ebp),%eax
40000ef6:	89 45 f0             	mov    %eax,-0x10(%ebp)
40000ef9:	8b 45 14             	mov    0x14(%ebp),%eax
40000efc:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
40000eff:	8b 45 08             	mov    0x8(%ebp),%eax
40000f02:	8b 40 1c             	mov    0x1c(%eax),%eax
40000f05:	89 c2                	mov    %eax,%edx
40000f07:	c1 fa 1f             	sar    $0x1f,%edx
40000f0a:	3b 55 f4             	cmp    -0xc(%ebp),%edx
40000f0d:	77 4e                	ja     40000f5d <genint+0x71>
40000f0f:	3b 55 f4             	cmp    -0xc(%ebp),%edx
40000f12:	72 05                	jb     40000f19 <genint+0x2d>
40000f14:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40000f17:	77 44                	ja     40000f5d <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
40000f19:	8b 45 08             	mov    0x8(%ebp),%eax
40000f1c:	8b 40 1c             	mov    0x1c(%eax),%eax
40000f1f:	89 c2                	mov    %eax,%edx
40000f21:	c1 fa 1f             	sar    $0x1f,%edx
40000f24:	89 44 24 08          	mov    %eax,0x8(%esp)
40000f28:	89 54 24 0c          	mov    %edx,0xc(%esp)
40000f2c:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000f2f:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000f32:	89 04 24             	mov    %eax,(%esp)
40000f35:	89 54 24 04          	mov    %edx,0x4(%esp)
40000f39:	e8 62 47 00 00       	call   400056a0 <__udivdi3>
40000f3e:	89 44 24 08          	mov    %eax,0x8(%esp)
40000f42:	89 54 24 0c          	mov    %edx,0xc(%esp)
40000f46:	8b 45 0c             	mov    0xc(%ebp),%eax
40000f49:	89 44 24 04          	mov    %eax,0x4(%esp)
40000f4d:	8b 45 08             	mov    0x8(%ebp),%eax
40000f50:	89 04 24             	mov    %eax,(%esp)
40000f53:	e8 94 ff ff ff       	call   40000eec <genint>
40000f58:	89 45 0c             	mov    %eax,0xc(%ebp)
40000f5b:	eb 1b                	jmp    40000f78 <genint+0x8c>
	else if (st->signc >= 0)
40000f5d:	8b 45 08             	mov    0x8(%ebp),%eax
40000f60:	8b 40 14             	mov    0x14(%eax),%eax
40000f63:	85 c0                	test   %eax,%eax
40000f65:	78 11                	js     40000f78 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
40000f67:	8b 45 08             	mov    0x8(%ebp),%eax
40000f6a:	8b 40 14             	mov    0x14(%eax),%eax
40000f6d:	89 c2                	mov    %eax,%edx
40000f6f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000f72:	88 10                	mov    %dl,(%eax)
40000f74:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
40000f78:	8b 45 08             	mov    0x8(%ebp),%eax
40000f7b:	8b 40 1c             	mov    0x1c(%eax),%eax
40000f7e:	89 c1                	mov    %eax,%ecx
40000f80:	89 c3                	mov    %eax,%ebx
40000f82:	c1 fb 1f             	sar    $0x1f,%ebx
40000f85:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000f88:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000f8b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40000f8f:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
40000f93:	89 04 24             	mov    %eax,(%esp)
40000f96:	89 54 24 04          	mov    %edx,0x4(%esp)
40000f9a:	e8 51 48 00 00       	call   400057f0 <__umoddi3>
40000f9f:	05 c0 5b 00 40       	add    $0x40005bc0,%eax
40000fa4:	0f b6 10             	movzbl (%eax),%edx
40000fa7:	8b 45 0c             	mov    0xc(%ebp),%eax
40000faa:	88 10                	mov    %dl,(%eax)
40000fac:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
40000fb0:	8b 45 0c             	mov    0xc(%ebp),%eax
}
40000fb3:	83 c4 24             	add    $0x24,%esp
40000fb6:	5b                   	pop    %ebx
40000fb7:	5d                   	pop    %ebp
40000fb8:	c3                   	ret    

40000fb9 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
40000fb9:	55                   	push   %ebp
40000fba:	89 e5                	mov    %esp,%ebp
40000fbc:	83 ec 58             	sub    $0x58,%esp
40000fbf:	8b 45 0c             	mov    0xc(%ebp),%eax
40000fc2:	89 45 c0             	mov    %eax,-0x40(%ebp)
40000fc5:	8b 45 10             	mov    0x10(%ebp),%eax
40000fc8:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
40000fcb:	8d 45 d6             	lea    -0x2a(%ebp),%eax
40000fce:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
40000fd1:	8b 45 08             	mov    0x8(%ebp),%eax
40000fd4:	8b 55 14             	mov    0x14(%ebp),%edx
40000fd7:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
40000fda:	8b 45 c0             	mov    -0x40(%ebp),%eax
40000fdd:	8b 55 c4             	mov    -0x3c(%ebp),%edx
40000fe0:	89 44 24 08          	mov    %eax,0x8(%esp)
40000fe4:	89 54 24 0c          	mov    %edx,0xc(%esp)
40000fe8:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000feb:	89 44 24 04          	mov    %eax,0x4(%esp)
40000fef:	8b 45 08             	mov    0x8(%ebp),%eax
40000ff2:	89 04 24             	mov    %eax,(%esp)
40000ff5:	e8 f2 fe ff ff       	call   40000eec <genint>
40000ffa:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
40000ffd:	8b 55 f4             	mov    -0xc(%ebp),%edx
40001000:	8d 45 d6             	lea    -0x2a(%ebp),%eax
40001003:	89 d1                	mov    %edx,%ecx
40001005:	29 c1                	sub    %eax,%ecx
40001007:	89 c8                	mov    %ecx,%eax
40001009:	89 44 24 08          	mov    %eax,0x8(%esp)
4000100d:	8d 45 d6             	lea    -0x2a(%ebp),%eax
40001010:	89 44 24 04          	mov    %eax,0x4(%esp)
40001014:	8b 45 08             	mov    0x8(%ebp),%eax
40001017:	89 04 24             	mov    %eax,(%esp)
4000101a:	e8 08 fe ff ff       	call   40000e27 <putstr>
}
4000101f:	c9                   	leave  
40001020:	c3                   	ret    

40001021 <vprintfmt>:


// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
40001021:	55                   	push   %ebp
40001022:	89 e5                	mov    %esp,%ebp
40001024:	53                   	push   %ebx
40001025:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
40001028:	8d 55 cc             	lea    -0x34(%ebp),%edx
4000102b:	b9 00 00 00 00       	mov    $0x0,%ecx
40001030:	b8 20 00 00 00       	mov    $0x20,%eax
40001035:	89 c3                	mov    %eax,%ebx
40001037:	83 e3 fc             	and    $0xfffffffc,%ebx
4000103a:	b8 00 00 00 00       	mov    $0x0,%eax
4000103f:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
40001042:	83 c0 04             	add    $0x4,%eax
40001045:	39 d8                	cmp    %ebx,%eax
40001047:	72 f6                	jb     4000103f <vprintfmt+0x1e>
40001049:	01 c2                	add    %eax,%edx
4000104b:	8b 45 08             	mov    0x8(%ebp),%eax
4000104e:	89 45 cc             	mov    %eax,-0x34(%ebp)
40001051:	8b 45 0c             	mov    0xc(%ebp),%eax
40001054:	89 45 d0             	mov    %eax,-0x30(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40001057:	eb 17                	jmp    40001070 <vprintfmt+0x4f>
			if (ch == '\0')
40001059:	85 db                	test   %ebx,%ebx
4000105b:	0f 84 50 03 00 00    	je     400013b1 <vprintfmt+0x390>
				return;
			putch(ch, putdat);
40001061:	8b 45 0c             	mov    0xc(%ebp),%eax
40001064:	89 44 24 04          	mov    %eax,0x4(%esp)
40001068:	89 1c 24             	mov    %ebx,(%esp)
4000106b:	8b 45 08             	mov    0x8(%ebp),%eax
4000106e:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40001070:	8b 45 10             	mov    0x10(%ebp),%eax
40001073:	0f b6 00             	movzbl (%eax),%eax
40001076:	0f b6 d8             	movzbl %al,%ebx
40001079:	83 fb 25             	cmp    $0x25,%ebx
4000107c:	0f 95 c0             	setne  %al
4000107f:	83 45 10 01          	addl   $0x1,0x10(%ebp)
40001083:	84 c0                	test   %al,%al
40001085:	75 d2                	jne    40001059 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
40001087:	c7 45 d4 20 00 00 00 	movl   $0x20,-0x2c(%ebp)
		st.width = -1;
4000108e:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.prec = -1;
40001095:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.signc = -1;
4000109c:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		st.flags = 0;
400010a3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		st.base = 10;
400010aa:	c7 45 e8 0a 00 00 00 	movl   $0xa,-0x18(%ebp)
400010b1:	eb 04                	jmp    400010b7 <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
400010b3:	90                   	nop
400010b4:	eb 01                	jmp    400010b7 <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
400010b6:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
400010b7:	8b 45 10             	mov    0x10(%ebp),%eax
400010ba:	0f b6 00             	movzbl (%eax),%eax
400010bd:	0f b6 d8             	movzbl %al,%ebx
400010c0:	89 d8                	mov    %ebx,%eax
400010c2:	83 45 10 01          	addl   $0x1,0x10(%ebp)
400010c6:	83 e8 20             	sub    $0x20,%eax
400010c9:	83 f8 58             	cmp    $0x58,%eax
400010cc:	0f 87 ae 02 00 00    	ja     40001380 <vprintfmt+0x35f>
400010d2:	8b 04 85 d8 5b 00 40 	mov    0x40005bd8(,%eax,4),%eax
400010d9:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
400010db:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400010de:	83 c8 10             	or     $0x10,%eax
400010e1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
400010e4:	eb d1                	jmp    400010b7 <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
400010e6:	c7 45 e0 2b 00 00 00 	movl   $0x2b,-0x20(%ebp)
			goto reswitch;
400010ed:	eb c8                	jmp    400010b7 <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
400010ef:	8b 45 e0             	mov    -0x20(%ebp),%eax
400010f2:	85 c0                	test   %eax,%eax
400010f4:	79 bd                	jns    400010b3 <vprintfmt+0x92>
				st.signc = ' ';
400010f6:	c7 45 e0 20 00 00 00 	movl   $0x20,-0x20(%ebp)
			goto reswitch;
400010fd:	eb b4                	jmp    400010b3 <vprintfmt+0x92>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
400010ff:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001102:	83 e0 08             	and    $0x8,%eax
40001105:	85 c0                	test   %eax,%eax
40001107:	75 07                	jne    40001110 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
40001109:	c7 45 d4 30 00 00 00 	movl   $0x30,-0x2c(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
40001110:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
				st.prec = st.prec * 10 + ch - '0';
40001117:	8b 55 dc             	mov    -0x24(%ebp),%edx
4000111a:	89 d0                	mov    %edx,%eax
4000111c:	c1 e0 02             	shl    $0x2,%eax
4000111f:	01 d0                	add    %edx,%eax
40001121:	01 c0                	add    %eax,%eax
40001123:	01 d8                	add    %ebx,%eax
40001125:	83 e8 30             	sub    $0x30,%eax
40001128:	89 45 dc             	mov    %eax,-0x24(%ebp)
				ch = *fmt;
4000112b:	8b 45 10             	mov    0x10(%ebp),%eax
4000112e:	0f b6 00             	movzbl (%eax),%eax
40001131:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
40001134:	83 fb 2f             	cmp    $0x2f,%ebx
40001137:	7e 21                	jle    4000115a <vprintfmt+0x139>
40001139:	83 fb 39             	cmp    $0x39,%ebx
4000113c:	7f 1c                	jg     4000115a <vprintfmt+0x139>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
4000113e:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
40001142:	eb d3                	jmp    40001117 <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
40001144:	8b 45 14             	mov    0x14(%ebp),%eax
40001147:	83 c0 04             	add    $0x4,%eax
4000114a:	89 45 14             	mov    %eax,0x14(%ebp)
4000114d:	8b 45 14             	mov    0x14(%ebp),%eax
40001150:	83 e8 04             	sub    $0x4,%eax
40001153:	8b 00                	mov    (%eax),%eax
40001155:	89 45 dc             	mov    %eax,-0x24(%ebp)
40001158:	eb 01                	jmp    4000115b <vprintfmt+0x13a>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
4000115a:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
4000115b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000115e:	83 e0 08             	and    $0x8,%eax
40001161:	85 c0                	test   %eax,%eax
40001163:	0f 85 4d ff ff ff    	jne    400010b6 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
40001169:	8b 45 dc             	mov    -0x24(%ebp),%eax
4000116c:	89 45 d8             	mov    %eax,-0x28(%ebp)
				st.prec = -1;
4000116f:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
			}
			goto reswitch;
40001176:	e9 3b ff ff ff       	jmp    400010b6 <vprintfmt+0x95>

		case '.':
			st.flags |= F_DOT;
4000117b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000117e:	83 c8 08             	or     $0x8,%eax
40001181:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
40001184:	e9 2e ff ff ff       	jmp    400010b7 <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
40001189:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000118c:	83 c8 04             	or     $0x4,%eax
4000118f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
40001192:	e9 20 ff ff ff       	jmp    400010b7 <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
40001197:	8b 55 e4             	mov    -0x1c(%ebp),%edx
4000119a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000119d:	83 e0 01             	and    $0x1,%eax
400011a0:	85 c0                	test   %eax,%eax
400011a2:	74 07                	je     400011ab <vprintfmt+0x18a>
400011a4:	b8 02 00 00 00       	mov    $0x2,%eax
400011a9:	eb 05                	jmp    400011b0 <vprintfmt+0x18f>
400011ab:	b8 01 00 00 00       	mov    $0x1,%eax
400011b0:	09 d0                	or     %edx,%eax
400011b2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
400011b5:	e9 fd fe ff ff       	jmp    400010b7 <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
400011ba:	8b 45 14             	mov    0x14(%ebp),%eax
400011bd:	83 c0 04             	add    $0x4,%eax
400011c0:	89 45 14             	mov    %eax,0x14(%ebp)
400011c3:	8b 45 14             	mov    0x14(%ebp),%eax
400011c6:	83 e8 04             	sub    $0x4,%eax
400011c9:	8b 00                	mov    (%eax),%eax
400011cb:	8b 55 0c             	mov    0xc(%ebp),%edx
400011ce:	89 54 24 04          	mov    %edx,0x4(%esp)
400011d2:	89 04 24             	mov    %eax,(%esp)
400011d5:	8b 45 08             	mov    0x8(%ebp),%eax
400011d8:	ff d0                	call   *%eax
			break;
400011da:	e9 cc 01 00 00       	jmp    400013ab <vprintfmt+0x38a>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
400011df:	8b 45 14             	mov    0x14(%ebp),%eax
400011e2:	83 c0 04             	add    $0x4,%eax
400011e5:	89 45 14             	mov    %eax,0x14(%ebp)
400011e8:	8b 45 14             	mov    0x14(%ebp),%eax
400011eb:	83 e8 04             	sub    $0x4,%eax
400011ee:	8b 00                	mov    (%eax),%eax
400011f0:	89 45 ec             	mov    %eax,-0x14(%ebp)
400011f3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
400011f7:	75 07                	jne    40001200 <vprintfmt+0x1df>
				s = "(null)";
400011f9:	c7 45 ec d1 5b 00 40 	movl   $0x40005bd1,-0x14(%ebp)
			putstr(&st, s, st.prec);
40001200:	8b 45 dc             	mov    -0x24(%ebp),%eax
40001203:	89 44 24 08          	mov    %eax,0x8(%esp)
40001207:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000120a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000120e:	8d 45 cc             	lea    -0x34(%ebp),%eax
40001211:	89 04 24             	mov    %eax,(%esp)
40001214:	e8 0e fc ff ff       	call   40000e27 <putstr>
			break;
40001219:	e9 8d 01 00 00       	jmp    400013ab <vprintfmt+0x38a>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
4000121e:	8d 45 14             	lea    0x14(%ebp),%eax
40001221:	89 44 24 04          	mov    %eax,0x4(%esp)
40001225:	8d 45 cc             	lea    -0x34(%ebp),%eax
40001228:	89 04 24             	mov    %eax,(%esp)
4000122b:	e8 45 fb ff ff       	call   40000d75 <getint>
40001230:	89 45 f0             	mov    %eax,-0x10(%ebp)
40001233:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((intmax_t) num < 0) {
40001236:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001239:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000123c:	85 d2                	test   %edx,%edx
4000123e:	79 1a                	jns    4000125a <vprintfmt+0x239>
				num = -(intmax_t) num;
40001240:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001243:	8b 55 f4             	mov    -0xc(%ebp),%edx
40001246:	f7 d8                	neg    %eax
40001248:	83 d2 00             	adc    $0x0,%edx
4000124b:	f7 da                	neg    %edx
4000124d:	89 45 f0             	mov    %eax,-0x10(%ebp)
40001250:	89 55 f4             	mov    %edx,-0xc(%ebp)
				st.signc = '-';
40001253:	c7 45 e0 2d 00 00 00 	movl   $0x2d,-0x20(%ebp)
			}
			putint(&st, num, 10);
4000125a:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
40001261:	00 
40001262:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001265:	8b 55 f4             	mov    -0xc(%ebp),%edx
40001268:	89 44 24 04          	mov    %eax,0x4(%esp)
4000126c:	89 54 24 08          	mov    %edx,0x8(%esp)
40001270:	8d 45 cc             	lea    -0x34(%ebp),%eax
40001273:	89 04 24             	mov    %eax,(%esp)
40001276:	e8 3e fd ff ff       	call   40000fb9 <putint>
			break;
4000127b:	e9 2b 01 00 00       	jmp    400013ab <vprintfmt+0x38a>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
40001280:	8d 45 14             	lea    0x14(%ebp),%eax
40001283:	89 44 24 04          	mov    %eax,0x4(%esp)
40001287:	8d 45 cc             	lea    -0x34(%ebp),%eax
4000128a:	89 04 24             	mov    %eax,(%esp)
4000128d:	e8 6e fa ff ff       	call   40000d00 <getuint>
40001292:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
40001299:	00 
4000129a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000129e:	89 54 24 08          	mov    %edx,0x8(%esp)
400012a2:	8d 45 cc             	lea    -0x34(%ebp),%eax
400012a5:	89 04 24             	mov    %eax,(%esp)
400012a8:	e8 0c fd ff ff       	call   40000fb9 <putint>
			break;
400012ad:	e9 f9 00 00 00       	jmp    400013ab <vprintfmt+0x38a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
400012b2:	8d 45 14             	lea    0x14(%ebp),%eax
400012b5:	89 44 24 04          	mov    %eax,0x4(%esp)
400012b9:	8d 45 cc             	lea    -0x34(%ebp),%eax
400012bc:	89 04 24             	mov    %eax,(%esp)
400012bf:	e8 3c fa ff ff       	call   40000d00 <getuint>
400012c4:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
400012cb:	00 
400012cc:	89 44 24 04          	mov    %eax,0x4(%esp)
400012d0:	89 54 24 08          	mov    %edx,0x8(%esp)
400012d4:	8d 45 cc             	lea    -0x34(%ebp),%eax
400012d7:	89 04 24             	mov    %eax,(%esp)
400012da:	e8 da fc ff ff       	call   40000fb9 <putint>
			break;
400012df:	e9 c7 00 00 00       	jmp    400013ab <vprintfmt+0x38a>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
400012e4:	8d 45 14             	lea    0x14(%ebp),%eax
400012e7:	89 44 24 04          	mov    %eax,0x4(%esp)
400012eb:	8d 45 cc             	lea    -0x34(%ebp),%eax
400012ee:	89 04 24             	mov    %eax,(%esp)
400012f1:	e8 0a fa ff ff       	call   40000d00 <getuint>
400012f6:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
400012fd:	00 
400012fe:	89 44 24 04          	mov    %eax,0x4(%esp)
40001302:	89 54 24 08          	mov    %edx,0x8(%esp)
40001306:	8d 45 cc             	lea    -0x34(%ebp),%eax
40001309:	89 04 24             	mov    %eax,(%esp)
4000130c:	e8 a8 fc ff ff       	call   40000fb9 <putint>
			break;
40001311:	e9 95 00 00 00       	jmp    400013ab <vprintfmt+0x38a>

		// pointer
		case 'p':
			putch('0', putdat);
40001316:	8b 45 0c             	mov    0xc(%ebp),%eax
40001319:	89 44 24 04          	mov    %eax,0x4(%esp)
4000131d:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
40001324:	8b 45 08             	mov    0x8(%ebp),%eax
40001327:	ff d0                	call   *%eax
			putch('x', putdat);
40001329:	8b 45 0c             	mov    0xc(%ebp),%eax
4000132c:	89 44 24 04          	mov    %eax,0x4(%esp)
40001330:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
40001337:	8b 45 08             	mov    0x8(%ebp),%eax
4000133a:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
4000133c:	8b 45 14             	mov    0x14(%ebp),%eax
4000133f:	83 c0 04             	add    $0x4,%eax
40001342:	89 45 14             	mov    %eax,0x14(%ebp)
40001345:	8b 45 14             	mov    0x14(%ebp),%eax
40001348:	83 e8 04             	sub    $0x4,%eax
4000134b:	8b 00                	mov    (%eax),%eax
4000134d:	ba 00 00 00 00       	mov    $0x0,%edx
40001352:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
40001359:	00 
4000135a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000135e:	89 54 24 08          	mov    %edx,0x8(%esp)
40001362:	8d 45 cc             	lea    -0x34(%ebp),%eax
40001365:	89 04 24             	mov    %eax,(%esp)
40001368:	e8 4c fc ff ff       	call   40000fb9 <putint>
			break;
4000136d:	eb 3c                	jmp    400013ab <vprintfmt+0x38a>


		// escaped '%' character
		case '%':
			putch(ch, putdat);
4000136f:	8b 45 0c             	mov    0xc(%ebp),%eax
40001372:	89 44 24 04          	mov    %eax,0x4(%esp)
40001376:	89 1c 24             	mov    %ebx,(%esp)
40001379:	8b 45 08             	mov    0x8(%ebp),%eax
4000137c:	ff d0                	call   *%eax
			break;
4000137e:	eb 2b                	jmp    400013ab <vprintfmt+0x38a>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
40001380:	8b 45 0c             	mov    0xc(%ebp),%eax
40001383:	89 44 24 04          	mov    %eax,0x4(%esp)
40001387:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
4000138e:	8b 45 08             	mov    0x8(%ebp),%eax
40001391:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
40001393:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40001397:	eb 04                	jmp    4000139d <vprintfmt+0x37c>
40001399:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
4000139d:	8b 45 10             	mov    0x10(%ebp),%eax
400013a0:	83 e8 01             	sub    $0x1,%eax
400013a3:	0f b6 00             	movzbl (%eax),%eax
400013a6:	3c 25                	cmp    $0x25,%al
400013a8:	75 ef                	jne    40001399 <vprintfmt+0x378>
				/* do nothing */;
			break;
400013aa:	90                   	nop
		}
	}
400013ab:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
400013ac:	e9 bf fc ff ff       	jmp    40001070 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
400013b1:	83 c4 44             	add    $0x44,%esp
400013b4:	5b                   	pop    %ebx
400013b5:	5d                   	pop    %ebp
400013b6:	c3                   	ret    
400013b7:	90                   	nop

400013b8 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
400013b8:	55                   	push   %ebp
400013b9:	89 e5                	mov    %esp,%ebp
400013bb:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
400013be:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
400013c5:	eb 08                	jmp    400013cf <strlen+0x17>
		n++;
400013c7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
400013cb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400013cf:	8b 45 08             	mov    0x8(%ebp),%eax
400013d2:	0f b6 00             	movzbl (%eax),%eax
400013d5:	84 c0                	test   %al,%al
400013d7:	75 ee                	jne    400013c7 <strlen+0xf>
		n++;
	return n;
400013d9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
400013dc:	c9                   	leave  
400013dd:	c3                   	ret    

400013de <strcpy>:

char *
strcpy(char *dst, const char *src)
{
400013de:	55                   	push   %ebp
400013df:	89 e5                	mov    %esp,%ebp
400013e1:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
400013e4:	8b 45 08             	mov    0x8(%ebp),%eax
400013e7:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
400013ea:	90                   	nop
400013eb:	8b 45 0c             	mov    0xc(%ebp),%eax
400013ee:	0f b6 10             	movzbl (%eax),%edx
400013f1:	8b 45 08             	mov    0x8(%ebp),%eax
400013f4:	88 10                	mov    %dl,(%eax)
400013f6:	8b 45 08             	mov    0x8(%ebp),%eax
400013f9:	0f b6 00             	movzbl (%eax),%eax
400013fc:	84 c0                	test   %al,%al
400013fe:	0f 95 c0             	setne  %al
40001401:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40001405:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
40001409:	84 c0                	test   %al,%al
4000140b:	75 de                	jne    400013eb <strcpy+0xd>
		/* do nothing */;
	return ret;
4000140d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
40001410:	c9                   	leave  
40001411:	c3                   	ret    

40001412 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
40001412:	55                   	push   %ebp
40001413:	89 e5                	mov    %esp,%ebp
40001415:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
40001418:	8b 45 08             	mov    0x8(%ebp),%eax
4000141b:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
4000141e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
40001425:	eb 21                	jmp    40001448 <strncpy+0x36>
		*dst++ = *src;
40001427:	8b 45 0c             	mov    0xc(%ebp),%eax
4000142a:	0f b6 10             	movzbl (%eax),%edx
4000142d:	8b 45 08             	mov    0x8(%ebp),%eax
40001430:	88 10                	mov    %dl,(%eax)
40001432:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
40001436:	8b 45 0c             	mov    0xc(%ebp),%eax
40001439:	0f b6 00             	movzbl (%eax),%eax
4000143c:	84 c0                	test   %al,%al
4000143e:	74 04                	je     40001444 <strncpy+0x32>
			src++;
40001440:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
40001444:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40001448:	8b 45 fc             	mov    -0x4(%ebp),%eax
4000144b:	3b 45 10             	cmp    0x10(%ebp),%eax
4000144e:	72 d7                	jb     40001427 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
40001450:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
40001453:	c9                   	leave  
40001454:	c3                   	ret    

40001455 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
40001455:	55                   	push   %ebp
40001456:	89 e5                	mov    %esp,%ebp
40001458:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
4000145b:	8b 45 08             	mov    0x8(%ebp),%eax
4000145e:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
40001461:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40001465:	74 2f                	je     40001496 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
40001467:	eb 13                	jmp    4000147c <strlcpy+0x27>
			*dst++ = *src++;
40001469:	8b 45 0c             	mov    0xc(%ebp),%eax
4000146c:	0f b6 10             	movzbl (%eax),%edx
4000146f:	8b 45 08             	mov    0x8(%ebp),%eax
40001472:	88 10                	mov    %dl,(%eax)
40001474:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40001478:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
4000147c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40001480:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40001484:	74 0a                	je     40001490 <strlcpy+0x3b>
40001486:	8b 45 0c             	mov    0xc(%ebp),%eax
40001489:	0f b6 00             	movzbl (%eax),%eax
4000148c:	84 c0                	test   %al,%al
4000148e:	75 d9                	jne    40001469 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
40001490:	8b 45 08             	mov    0x8(%ebp),%eax
40001493:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
40001496:	8b 55 08             	mov    0x8(%ebp),%edx
40001499:	8b 45 fc             	mov    -0x4(%ebp),%eax
4000149c:	89 d1                	mov    %edx,%ecx
4000149e:	29 c1                	sub    %eax,%ecx
400014a0:	89 c8                	mov    %ecx,%eax
}
400014a2:	c9                   	leave  
400014a3:	c3                   	ret    

400014a4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
400014a4:	55                   	push   %ebp
400014a5:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
400014a7:	eb 08                	jmp    400014b1 <strcmp+0xd>
		p++, q++;
400014a9:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400014ad:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
400014b1:	8b 45 08             	mov    0x8(%ebp),%eax
400014b4:	0f b6 00             	movzbl (%eax),%eax
400014b7:	84 c0                	test   %al,%al
400014b9:	74 10                	je     400014cb <strcmp+0x27>
400014bb:	8b 45 08             	mov    0x8(%ebp),%eax
400014be:	0f b6 10             	movzbl (%eax),%edx
400014c1:	8b 45 0c             	mov    0xc(%ebp),%eax
400014c4:	0f b6 00             	movzbl (%eax),%eax
400014c7:	38 c2                	cmp    %al,%dl
400014c9:	74 de                	je     400014a9 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
400014cb:	8b 45 08             	mov    0x8(%ebp),%eax
400014ce:	0f b6 00             	movzbl (%eax),%eax
400014d1:	0f b6 d0             	movzbl %al,%edx
400014d4:	8b 45 0c             	mov    0xc(%ebp),%eax
400014d7:	0f b6 00             	movzbl (%eax),%eax
400014da:	0f b6 c0             	movzbl %al,%eax
400014dd:	89 d1                	mov    %edx,%ecx
400014df:	29 c1                	sub    %eax,%ecx
400014e1:	89 c8                	mov    %ecx,%eax
}
400014e3:	5d                   	pop    %ebp
400014e4:	c3                   	ret    

400014e5 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
400014e5:	55                   	push   %ebp
400014e6:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
400014e8:	eb 0c                	jmp    400014f6 <strncmp+0x11>
		n--, p++, q++;
400014ea:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
400014ee:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400014f2:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
400014f6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400014fa:	74 1a                	je     40001516 <strncmp+0x31>
400014fc:	8b 45 08             	mov    0x8(%ebp),%eax
400014ff:	0f b6 00             	movzbl (%eax),%eax
40001502:	84 c0                	test   %al,%al
40001504:	74 10                	je     40001516 <strncmp+0x31>
40001506:	8b 45 08             	mov    0x8(%ebp),%eax
40001509:	0f b6 10             	movzbl (%eax),%edx
4000150c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000150f:	0f b6 00             	movzbl (%eax),%eax
40001512:	38 c2                	cmp    %al,%dl
40001514:	74 d4                	je     400014ea <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
40001516:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
4000151a:	75 07                	jne    40001523 <strncmp+0x3e>
		return 0;
4000151c:	b8 00 00 00 00       	mov    $0x0,%eax
40001521:	eb 18                	jmp    4000153b <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
40001523:	8b 45 08             	mov    0x8(%ebp),%eax
40001526:	0f b6 00             	movzbl (%eax),%eax
40001529:	0f b6 d0             	movzbl %al,%edx
4000152c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000152f:	0f b6 00             	movzbl (%eax),%eax
40001532:	0f b6 c0             	movzbl %al,%eax
40001535:	89 d1                	mov    %edx,%ecx
40001537:	29 c1                	sub    %eax,%ecx
40001539:	89 c8                	mov    %ecx,%eax
}
4000153b:	5d                   	pop    %ebp
4000153c:	c3                   	ret    

4000153d <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
4000153d:	55                   	push   %ebp
4000153e:	89 e5                	mov    %esp,%ebp
40001540:	83 ec 04             	sub    $0x4,%esp
40001543:	8b 45 0c             	mov    0xc(%ebp),%eax
40001546:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
40001549:	eb 1a                	jmp    40001565 <strchr+0x28>
		if (*s++ == 0)
4000154b:	8b 45 08             	mov    0x8(%ebp),%eax
4000154e:	0f b6 00             	movzbl (%eax),%eax
40001551:	84 c0                	test   %al,%al
40001553:	0f 94 c0             	sete   %al
40001556:	83 45 08 01          	addl   $0x1,0x8(%ebp)
4000155a:	84 c0                	test   %al,%al
4000155c:	74 07                	je     40001565 <strchr+0x28>
			return NULL;
4000155e:	b8 00 00 00 00       	mov    $0x0,%eax
40001563:	eb 0e                	jmp    40001573 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
40001565:	8b 45 08             	mov    0x8(%ebp),%eax
40001568:	0f b6 00             	movzbl (%eax),%eax
4000156b:	3a 45 fc             	cmp    -0x4(%ebp),%al
4000156e:	75 db                	jne    4000154b <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
40001570:	8b 45 08             	mov    0x8(%ebp),%eax
}
40001573:	c9                   	leave  
40001574:	c3                   	ret    

40001575 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
40001575:	55                   	push   %ebp
40001576:	89 e5                	mov    %esp,%ebp
40001578:	57                   	push   %edi
	char *p;

	if (n == 0)
40001579:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
4000157d:	75 05                	jne    40001584 <memset+0xf>
		return v;
4000157f:	8b 45 08             	mov    0x8(%ebp),%eax
40001582:	eb 5c                	jmp    400015e0 <memset+0x6b>
	if ((int)v%4 == 0 && n%4 == 0) {
40001584:	8b 45 08             	mov    0x8(%ebp),%eax
40001587:	83 e0 03             	and    $0x3,%eax
4000158a:	85 c0                	test   %eax,%eax
4000158c:	75 41                	jne    400015cf <memset+0x5a>
4000158e:	8b 45 10             	mov    0x10(%ebp),%eax
40001591:	83 e0 03             	and    $0x3,%eax
40001594:	85 c0                	test   %eax,%eax
40001596:	75 37                	jne    400015cf <memset+0x5a>
		c &= 0xFF;
40001598:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
4000159f:	8b 45 0c             	mov    0xc(%ebp),%eax
400015a2:	89 c2                	mov    %eax,%edx
400015a4:	c1 e2 18             	shl    $0x18,%edx
400015a7:	8b 45 0c             	mov    0xc(%ebp),%eax
400015aa:	c1 e0 10             	shl    $0x10,%eax
400015ad:	09 c2                	or     %eax,%edx
400015af:	8b 45 0c             	mov    0xc(%ebp),%eax
400015b2:	c1 e0 08             	shl    $0x8,%eax
400015b5:	09 d0                	or     %edx,%eax
400015b7:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
400015ba:	8b 45 10             	mov    0x10(%ebp),%eax
400015bd:	89 c1                	mov    %eax,%ecx
400015bf:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
400015c2:	8b 55 08             	mov    0x8(%ebp),%edx
400015c5:	8b 45 0c             	mov    0xc(%ebp),%eax
400015c8:	89 d7                	mov    %edx,%edi
400015ca:	fc                   	cld    
400015cb:	f3 ab                	rep stos %eax,%es:(%edi)
400015cd:	eb 0e                	jmp    400015dd <memset+0x68>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
400015cf:	8b 55 08             	mov    0x8(%ebp),%edx
400015d2:	8b 45 0c             	mov    0xc(%ebp),%eax
400015d5:	8b 4d 10             	mov    0x10(%ebp),%ecx
400015d8:	89 d7                	mov    %edx,%edi
400015da:	fc                   	cld    
400015db:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
400015dd:	8b 45 08             	mov    0x8(%ebp),%eax
}
400015e0:	5f                   	pop    %edi
400015e1:	5d                   	pop    %ebp
400015e2:	c3                   	ret    

400015e3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
400015e3:	55                   	push   %ebp
400015e4:	89 e5                	mov    %esp,%ebp
400015e6:	57                   	push   %edi
400015e7:	56                   	push   %esi
400015e8:	53                   	push   %ebx
400015e9:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
400015ec:	8b 45 0c             	mov    0xc(%ebp),%eax
400015ef:	89 45 f0             	mov    %eax,-0x10(%ebp)
	d = dst;
400015f2:	8b 45 08             	mov    0x8(%ebp),%eax
400015f5:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (s < d && s + n > d) {
400015f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
400015fb:	3b 45 ec             	cmp    -0x14(%ebp),%eax
400015fe:	73 6d                	jae    4000166d <memmove+0x8a>
40001600:	8b 45 10             	mov    0x10(%ebp),%eax
40001603:	8b 55 f0             	mov    -0x10(%ebp),%edx
40001606:	01 d0                	add    %edx,%eax
40001608:	3b 45 ec             	cmp    -0x14(%ebp),%eax
4000160b:	76 60                	jbe    4000166d <memmove+0x8a>
		s += n;
4000160d:	8b 45 10             	mov    0x10(%ebp),%eax
40001610:	01 45 f0             	add    %eax,-0x10(%ebp)
		d += n;
40001613:	8b 45 10             	mov    0x10(%ebp),%eax
40001616:	01 45 ec             	add    %eax,-0x14(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
40001619:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000161c:	83 e0 03             	and    $0x3,%eax
4000161f:	85 c0                	test   %eax,%eax
40001621:	75 2f                	jne    40001652 <memmove+0x6f>
40001623:	8b 45 ec             	mov    -0x14(%ebp),%eax
40001626:	83 e0 03             	and    $0x3,%eax
40001629:	85 c0                	test   %eax,%eax
4000162b:	75 25                	jne    40001652 <memmove+0x6f>
4000162d:	8b 45 10             	mov    0x10(%ebp),%eax
40001630:	83 e0 03             	and    $0x3,%eax
40001633:	85 c0                	test   %eax,%eax
40001635:	75 1b                	jne    40001652 <memmove+0x6f>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
40001637:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000163a:	83 e8 04             	sub    $0x4,%eax
4000163d:	8b 55 f0             	mov    -0x10(%ebp),%edx
40001640:	83 ea 04             	sub    $0x4,%edx
40001643:	8b 4d 10             	mov    0x10(%ebp),%ecx
40001646:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
40001649:	89 c7                	mov    %eax,%edi
4000164b:	89 d6                	mov    %edx,%esi
4000164d:	fd                   	std    
4000164e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
40001650:	eb 18                	jmp    4000166a <memmove+0x87>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
40001652:	8b 45 ec             	mov    -0x14(%ebp),%eax
40001655:	8d 50 ff             	lea    -0x1(%eax),%edx
40001658:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000165b:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
4000165e:	8b 45 10             	mov    0x10(%ebp),%eax
40001661:	89 d7                	mov    %edx,%edi
40001663:	89 de                	mov    %ebx,%esi
40001665:	89 c1                	mov    %eax,%ecx
40001667:	fd                   	std    
40001668:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
4000166a:	fc                   	cld    
4000166b:	eb 45                	jmp    400016b2 <memmove+0xcf>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
4000166d:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001670:	83 e0 03             	and    $0x3,%eax
40001673:	85 c0                	test   %eax,%eax
40001675:	75 2b                	jne    400016a2 <memmove+0xbf>
40001677:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000167a:	83 e0 03             	and    $0x3,%eax
4000167d:	85 c0                	test   %eax,%eax
4000167f:	75 21                	jne    400016a2 <memmove+0xbf>
40001681:	8b 45 10             	mov    0x10(%ebp),%eax
40001684:	83 e0 03             	and    $0x3,%eax
40001687:	85 c0                	test   %eax,%eax
40001689:	75 17                	jne    400016a2 <memmove+0xbf>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
4000168b:	8b 45 10             	mov    0x10(%ebp),%eax
4000168e:	89 c1                	mov    %eax,%ecx
40001690:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
40001693:	8b 45 ec             	mov    -0x14(%ebp),%eax
40001696:	8b 55 f0             	mov    -0x10(%ebp),%edx
40001699:	89 c7                	mov    %eax,%edi
4000169b:	89 d6                	mov    %edx,%esi
4000169d:	fc                   	cld    
4000169e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
400016a0:	eb 10                	jmp    400016b2 <memmove+0xcf>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
400016a2:	8b 45 ec             	mov    -0x14(%ebp),%eax
400016a5:	8b 55 f0             	mov    -0x10(%ebp),%edx
400016a8:	8b 4d 10             	mov    0x10(%ebp),%ecx
400016ab:	89 c7                	mov    %eax,%edi
400016ad:	89 d6                	mov    %edx,%esi
400016af:	fc                   	cld    
400016b0:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
400016b2:	8b 45 08             	mov    0x8(%ebp),%eax
}
400016b5:	83 c4 10             	add    $0x10,%esp
400016b8:	5b                   	pop    %ebx
400016b9:	5e                   	pop    %esi
400016ba:	5f                   	pop    %edi
400016bb:	5d                   	pop    %ebp
400016bc:	c3                   	ret    

400016bd <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
400016bd:	55                   	push   %ebp
400016be:	89 e5                	mov    %esp,%ebp
400016c0:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
400016c3:	8b 45 10             	mov    0x10(%ebp),%eax
400016c6:	89 44 24 08          	mov    %eax,0x8(%esp)
400016ca:	8b 45 0c             	mov    0xc(%ebp),%eax
400016cd:	89 44 24 04          	mov    %eax,0x4(%esp)
400016d1:	8b 45 08             	mov    0x8(%ebp),%eax
400016d4:	89 04 24             	mov    %eax,(%esp)
400016d7:	e8 07 ff ff ff       	call   400015e3 <memmove>
}
400016dc:	c9                   	leave  
400016dd:	c3                   	ret    

400016de <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
400016de:	55                   	push   %ebp
400016df:	89 e5                	mov    %esp,%ebp
400016e1:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
400016e4:	8b 45 08             	mov    0x8(%ebp),%eax
400016e7:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
400016ea:	8b 45 0c             	mov    0xc(%ebp),%eax
400016ed:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
400016f0:	eb 32                	jmp    40001724 <memcmp+0x46>
		if (*s1 != *s2)
400016f2:	8b 45 fc             	mov    -0x4(%ebp),%eax
400016f5:	0f b6 10             	movzbl (%eax),%edx
400016f8:	8b 45 f8             	mov    -0x8(%ebp),%eax
400016fb:	0f b6 00             	movzbl (%eax),%eax
400016fe:	38 c2                	cmp    %al,%dl
40001700:	74 1a                	je     4000171c <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
40001702:	8b 45 fc             	mov    -0x4(%ebp),%eax
40001705:	0f b6 00             	movzbl (%eax),%eax
40001708:	0f b6 d0             	movzbl %al,%edx
4000170b:	8b 45 f8             	mov    -0x8(%ebp),%eax
4000170e:	0f b6 00             	movzbl (%eax),%eax
40001711:	0f b6 c0             	movzbl %al,%eax
40001714:	89 d1                	mov    %edx,%ecx
40001716:	29 c1                	sub    %eax,%ecx
40001718:	89 c8                	mov    %ecx,%eax
4000171a:	eb 1c                	jmp    40001738 <memcmp+0x5a>
		s1++, s2++;
4000171c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40001720:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
40001724:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40001728:	0f 95 c0             	setne  %al
4000172b:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
4000172f:	84 c0                	test   %al,%al
40001731:	75 bf                	jne    400016f2 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
40001733:	b8 00 00 00 00       	mov    $0x0,%eax
}
40001738:	c9                   	leave  
40001739:	c3                   	ret    

4000173a <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
4000173a:	55                   	push   %ebp
4000173b:	89 e5                	mov    %esp,%ebp
4000173d:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
40001740:	8b 45 10             	mov    0x10(%ebp),%eax
40001743:	8b 55 08             	mov    0x8(%ebp),%edx
40001746:	01 d0                	add    %edx,%eax
40001748:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
4000174b:	eb 16                	jmp    40001763 <memchr+0x29>
		if (*(const unsigned char *) s == (unsigned char) c)
4000174d:	8b 45 08             	mov    0x8(%ebp),%eax
40001750:	0f b6 10             	movzbl (%eax),%edx
40001753:	8b 45 0c             	mov    0xc(%ebp),%eax
40001756:	38 c2                	cmp    %al,%dl
40001758:	75 05                	jne    4000175f <memchr+0x25>
			return (void *) s;
4000175a:	8b 45 08             	mov    0x8(%ebp),%eax
4000175d:	eb 11                	jmp    40001770 <memchr+0x36>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
4000175f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40001763:	8b 45 08             	mov    0x8(%ebp),%eax
40001766:	3b 45 fc             	cmp    -0x4(%ebp),%eax
40001769:	72 e2                	jb     4000174d <memchr+0x13>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
4000176b:	b8 00 00 00 00       	mov    $0x0,%eax
}
40001770:	c9                   	leave  
40001771:	c3                   	ret    
40001772:	66 90                	xchg   %ax,%ax

40001774 <fileino_alloc>:

// Find and return the index of a currently unused file inode in this process.
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_alloc(void)
{
40001774:	55                   	push   %ebp
40001775:	89 e5                	mov    %esp,%ebp
40001777:	83 ec 28             	sub    $0x28,%esp
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
4000177a:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
40001781:	eb 24                	jmp    400017a7 <fileino_alloc+0x33>
		if (files->fi[i].de.d_name[0] == 0)
40001783:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40001789:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000178c:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000178f:	01 d0                	add    %edx,%eax
40001791:	05 10 10 00 00       	add    $0x1010,%eax
40001796:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000179a:	84 c0                	test   %al,%al
4000179c:	75 05                	jne    400017a3 <fileino_alloc+0x2f>
			return i;
4000179e:	8b 45 f4             	mov    -0xc(%ebp),%eax
400017a1:	eb 39                	jmp    400017dc <fileino_alloc+0x68>
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_alloc(void)
{
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
400017a3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
400017a7:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
400017ae:	7e d3                	jle    40001783 <fileino_alloc+0xf>
		if (files->fi[i].de.d_name[0] == 0)
			return i;

	warn("fileino_alloc: no free inodes\n");
400017b0:	c7 44 24 08 40 5d 00 	movl   $0x40005d40,0x8(%esp)
400017b7:	40 
400017b8:	c7 44 24 04 29 00 00 	movl   $0x29,0x4(%esp)
400017bf:	00 
400017c0:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
400017c7:	e8 e2 f2 ff ff       	call   40000aae <debug_warn>
	errno = ENOSPC;
400017cc:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400017d1:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
	return -1;
400017d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
400017dc:	c9                   	leave  
400017dd:	c3                   	ret    

400017de <fileino_create>:
// Returns the index of the inode found or created.
// A newly-created inode is left in the "deleted" state, with mode == 0.
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_create(filestate *fs, int dino, const char *name)
{
400017de:	55                   	push   %ebp
400017df:	89 e5                	mov    %esp,%ebp
400017e1:	83 ec 28             	sub    $0x28,%esp
	assert(dino != 0);
400017e4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400017e8:	75 24                	jne    4000180e <fileino_create+0x30>
400017ea:	c7 44 24 0c 6a 5d 00 	movl   $0x40005d6a,0xc(%esp)
400017f1:	40 
400017f2:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
400017f9:	40 
400017fa:	c7 44 24 04 35 00 00 	movl   $0x35,0x4(%esp)
40001801:	00 
40001802:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40001809:	e8 36 f2 ff ff       	call   40000a44 <debug_panic>
	assert(name != NULL && name[0] != 0);
4000180e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40001812:	74 0a                	je     4000181e <fileino_create+0x40>
40001814:	8b 45 10             	mov    0x10(%ebp),%eax
40001817:	0f b6 00             	movzbl (%eax),%eax
4000181a:	84 c0                	test   %al,%al
4000181c:	75 24                	jne    40001842 <fileino_create+0x64>
4000181e:	c7 44 24 0c 89 5d 00 	movl   $0x40005d89,0xc(%esp)
40001825:	40 
40001826:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
4000182d:	40 
4000182e:	c7 44 24 04 36 00 00 	movl   $0x36,0x4(%esp)
40001835:	00 
40001836:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
4000183d:	e8 02 f2 ff ff       	call   40000a44 <debug_panic>
	assert(strlen(name) <= NAME_MAX);
40001842:	8b 45 10             	mov    0x10(%ebp),%eax
40001845:	89 04 24             	mov    %eax,(%esp)
40001848:	e8 6b fb ff ff       	call   400013b8 <strlen>
4000184d:	83 f8 3f             	cmp    $0x3f,%eax
40001850:	7e 24                	jle    40001876 <fileino_create+0x98>
40001852:	c7 44 24 0c a6 5d 00 	movl   $0x40005da6,0xc(%esp)
40001859:	40 
4000185a:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40001861:	40 
40001862:	c7 44 24 04 37 00 00 	movl   $0x37,0x4(%esp)
40001869:	00 
4000186a:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40001871:	e8 ce f1 ff ff       	call   40000a44 <debug_panic>

	// First see if an inode already exists for this directory and name.
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40001876:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
4000187d:	eb 4a                	jmp    400018c9 <fileino_create+0xeb>
		if (fs->fi[i].dino == dino
4000187f:	8b 55 08             	mov    0x8(%ebp),%edx
40001882:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001885:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001888:	01 d0                	add    %edx,%eax
4000188a:	05 10 10 00 00       	add    $0x1010,%eax
4000188f:	8b 00                	mov    (%eax),%eax
40001891:	3b 45 0c             	cmp    0xc(%ebp),%eax
40001894:	75 2f                	jne    400018c5 <fileino_create+0xe7>
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
40001896:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001899:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000189c:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400018a2:	8b 45 08             	mov    0x8(%ebp),%eax
400018a5:	01 d0                	add    %edx,%eax
400018a7:	8d 50 04             	lea    0x4(%eax),%edx
400018aa:	8b 45 10             	mov    0x10(%ebp),%eax
400018ad:	89 44 24 04          	mov    %eax,0x4(%esp)
400018b1:	89 14 24             	mov    %edx,(%esp)
400018b4:	e8 eb fb ff ff       	call   400014a4 <strcmp>
400018b9:	85 c0                	test   %eax,%eax
400018bb:	75 08                	jne    400018c5 <fileino_create+0xe7>
			return i;
400018bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
400018c0:	e9 a5 00 00 00       	jmp    4000196a <fileino_create+0x18c>
	assert(name != NULL && name[0] != 0);
	assert(strlen(name) <= NAME_MAX);

	// First see if an inode already exists for this directory and name.
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
400018c5:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
400018c9:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
400018d0:	7e ad                	jle    4000187f <fileino_create+0xa1>
		if (fs->fi[i].dino == dino
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
			return i;

	// No inode allocated to this name - find a free one to allocate.
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
400018d2:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
400018d9:	eb 5a                	jmp    40001935 <fileino_create+0x157>
		if (fs->fi[i].de.d_name[0] == 0) {
400018db:	8b 55 08             	mov    0x8(%ebp),%edx
400018de:	8b 45 f4             	mov    -0xc(%ebp),%eax
400018e1:	6b c0 5c             	imul   $0x5c,%eax,%eax
400018e4:	01 d0                	add    %edx,%eax
400018e6:	05 10 10 00 00       	add    $0x1010,%eax
400018eb:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400018ef:	84 c0                	test   %al,%al
400018f1:	75 3e                	jne    40001931 <fileino_create+0x153>
			fs->fi[i].dino = dino;
400018f3:	8b 55 08             	mov    0x8(%ebp),%edx
400018f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
400018f9:	6b c0 5c             	imul   $0x5c,%eax,%eax
400018fc:	01 d0                	add    %edx,%eax
400018fe:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40001904:	8b 45 0c             	mov    0xc(%ebp),%eax
40001907:	89 02                	mov    %eax,(%edx)
			strcpy(fs->fi[i].de.d_name, name);
40001909:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000190c:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000190f:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40001915:	8b 45 08             	mov    0x8(%ebp),%eax
40001918:	01 d0                	add    %edx,%eax
4000191a:	8d 50 04             	lea    0x4(%eax),%edx
4000191d:	8b 45 10             	mov    0x10(%ebp),%eax
40001920:	89 44 24 04          	mov    %eax,0x4(%esp)
40001924:	89 14 24             	mov    %edx,(%esp)
40001927:	e8 b2 fa ff ff       	call   400013de <strcpy>
			return i;
4000192c:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000192f:	eb 39                	jmp    4000196a <fileino_create+0x18c>
		if (fs->fi[i].dino == dino
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
			return i;

	// No inode allocated to this name - find a free one to allocate.
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40001931:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40001935:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
4000193c:	7e 9d                	jle    400018db <fileino_create+0xfd>
			fs->fi[i].dino = dino;
			strcpy(fs->fi[i].de.d_name, name);
			return i;
		}

	warn("fileino_create: no free inodes\n");
4000193e:	c7 44 24 08 c0 5d 00 	movl   $0x40005dc0,0x8(%esp)
40001945:	40 
40001946:	c7 44 24 04 48 00 00 	movl   $0x48,0x4(%esp)
4000194d:	00 
4000194e:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40001955:	e8 54 f1 ff ff       	call   40000aae <debug_warn>
	errno = ENOSPC;
4000195a:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
4000195f:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
	return -1;
40001965:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
4000196a:	c9                   	leave  
4000196b:	c3                   	ret    

4000196c <fileino_read>:
// The number of elements returned is normally equal to the 'count' parameter,
// but may be less (without resulting in an error)
// if the file is not large enough to read that many elements.
ssize_t
fileino_read(int ino, off_t ofs, void *buf, size_t eltsize, size_t count)
{
4000196c:	55                   	push   %ebp
4000196d:	89 e5                	mov    %esp,%ebp
4000196f:	83 ec 28             	sub    $0x28,%esp
	assert(fileino_isreg(ino));
40001972:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001976:	7e 45                	jle    400019bd <fileino_read+0x51>
40001978:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
4000197f:	7f 3c                	jg     400019bd <fileino_read+0x51>
40001981:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40001987:	8b 45 08             	mov    0x8(%ebp),%eax
4000198a:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000198d:	01 d0                	add    %edx,%eax
4000198f:	05 10 10 00 00       	add    $0x1010,%eax
40001994:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40001998:	84 c0                	test   %al,%al
4000199a:	74 21                	je     400019bd <fileino_read+0x51>
4000199c:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
400019a2:	8b 45 08             	mov    0x8(%ebp),%eax
400019a5:	6b c0 5c             	imul   $0x5c,%eax,%eax
400019a8:	01 d0                	add    %edx,%eax
400019aa:	05 58 10 00 00       	add    $0x1058,%eax
400019af:	8b 00                	mov    (%eax),%eax
400019b1:	25 00 70 00 00       	and    $0x7000,%eax
400019b6:	3d 00 10 00 00       	cmp    $0x1000,%eax
400019bb:	74 24                	je     400019e1 <fileino_read+0x75>
400019bd:	c7 44 24 0c e0 5d 00 	movl   $0x40005de0,0xc(%esp)
400019c4:	40 
400019c5:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
400019cc:	40 
400019cd:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
400019d4:	00 
400019d5:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
400019dc:	e8 63 f0 ff ff       	call   40000a44 <debug_panic>
	assert(ofs >= 0);
400019e1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400019e5:	79 24                	jns    40001a0b <fileino_read+0x9f>
400019e7:	c7 44 24 0c f3 5d 00 	movl   $0x40005df3,0xc(%esp)
400019ee:	40 
400019ef:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
400019f6:	40 
400019f7:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
400019fe:	00 
400019ff:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40001a06:	e8 39 f0 ff ff       	call   40000a44 <debug_panic>
	assert(eltsize > 0);
40001a0b:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40001a0f:	75 24                	jne    40001a35 <fileino_read+0xc9>
40001a11:	c7 44 24 0c fc 5d 00 	movl   $0x40005dfc,0xc(%esp)
40001a18:	40 
40001a19:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40001a20:	40 
40001a21:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
40001a28:	00 
40001a29:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40001a30:	e8 0f f0 ff ff       	call   40000a44 <debug_panic>

	ssize_t return_number = 0;
40001a35:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	fileinode *fi = &files->fi[ino];
40001a3c:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40001a41:	8b 55 08             	mov    0x8(%ebp),%edx
40001a44:	6b d2 5c             	imul   $0x5c,%edx,%edx
40001a47:	81 c2 10 10 00 00    	add    $0x1010,%edx
40001a4d:	01 d0                	add    %edx,%eax
40001a4f:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint32_t tmp_ofs = ofs;
40001a52:	8b 45 0c             	mov    0xc(%ebp),%eax
40001a55:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint8_t* read_pointer = FILEDATA(ino) + ofs;
40001a58:	8b 45 08             	mov    0x8(%ebp),%eax
40001a5b:	c1 e0 16             	shl    $0x16,%eax
40001a5e:	89 c2                	mov    %eax,%edx
40001a60:	8b 45 0c             	mov    0xc(%ebp),%eax
40001a63:	01 d0                	add    %edx,%eax
40001a65:	05 00 00 00 80       	add    $0x80000000,%eax
40001a6a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(fi->size <= FILE_MAXSIZE);
40001a6d:	8b 45 e8             	mov    -0x18(%ebp),%eax
40001a70:	8b 40 4c             	mov    0x4c(%eax),%eax
40001a73:	3d 00 00 40 00       	cmp    $0x400000,%eax
40001a78:	76 7a                	jbe    40001af4 <fileino_read+0x188>
40001a7a:	c7 44 24 0c 08 5e 00 	movl   $0x40005e08,0xc(%esp)
40001a81:	40 
40001a82:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40001a89:	40 
40001a8a:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
40001a91:	00 
40001a92:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40001a99:	e8 a6 ef ff ff       	call   40000a44 <debug_panic>
	// Lab 4: insert your file reading code here.
	//warn("fileino_read() not implemented");
	while(count > 0){
		if(tmp_ofs >= fi->size){
40001a9e:	8b 45 e8             	mov    -0x18(%ebp),%eax
40001aa1:	8b 40 4c             	mov    0x4c(%eax),%eax
40001aa4:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40001aa7:	77 18                	ja     40001ac1 <fileino_read+0x155>
			if(fi->mode & S_IFPART)
40001aa9:	8b 45 e8             	mov    -0x18(%ebp),%eax
40001aac:	8b 40 48             	mov    0x48(%eax),%eax
40001aaf:	25 00 80 00 00       	and    $0x8000,%eax
40001ab4:	85 c0                	test   %eax,%eax
40001ab6:	74 44                	je     40001afc <fileino_read+0x190>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001ab8:	b8 03 00 00 00       	mov    $0x3,%eax
40001abd:	cd 30                	int    $0x30
40001abf:	eb 33                	jmp    40001af4 <fileino_read+0x188>
				sys_ret();
			else
				break;
		}else{
			memcpy(buf, read_pointer, eltsize);
40001ac1:	8b 45 14             	mov    0x14(%ebp),%eax
40001ac4:	89 44 24 08          	mov    %eax,0x8(%esp)
40001ac8:	8b 45 ec             	mov    -0x14(%ebp),%eax
40001acb:	89 44 24 04          	mov    %eax,0x4(%esp)
40001acf:	8b 45 10             	mov    0x10(%ebp),%eax
40001ad2:	89 04 24             	mov    %eax,(%esp)
40001ad5:	e8 e3 fb ff ff       	call   400016bd <memcpy>
			return_number++;
40001ada:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
			buf += eltsize;
40001ade:	8b 45 14             	mov    0x14(%ebp),%eax
40001ae1:	01 45 10             	add    %eax,0x10(%ebp)
			read_pointer += eltsize;
40001ae4:	8b 45 14             	mov    0x14(%ebp),%eax
40001ae7:	01 45 ec             	add    %eax,-0x14(%ebp)
			tmp_ofs += eltsize;
40001aea:	8b 45 14             	mov    0x14(%ebp),%eax
40001aed:	01 45 f0             	add    %eax,-0x10(%ebp)
			count--;
40001af0:	83 6d 18 01          	subl   $0x1,0x18(%ebp)
	uint32_t tmp_ofs = ofs;
	uint8_t* read_pointer = FILEDATA(ino) + ofs;
	assert(fi->size <= FILE_MAXSIZE);
	// Lab 4: insert your file reading code here.
	//warn("fileino_read() not implemented");
	while(count > 0){
40001af4:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
40001af8:	75 a4                	jne    40001a9e <fileino_read+0x132>
40001afa:	eb 01                	jmp    40001afd <fileino_read+0x191>
		if(tmp_ofs >= fi->size){
			if(fi->mode & S_IFPART)
				sys_ret();
			else
				break;
40001afc:	90                   	nop
			read_pointer += eltsize;
			tmp_ofs += eltsize;
			count--;
		}
	}
	return return_number;
40001afd:	8b 45 f4             	mov    -0xc(%ebp),%eax
//	errno = EINVAL;
//	return -1;
}
40001b00:	c9                   	leave  
40001b01:	c3                   	ret    

40001b02 <fileino_write>:
// one particular reason an error might occur is if an application
// tries to grow a file beyond this maximum file size,
// in which case this function generates the EFBIG error.
ssize_t
fileino_write(int ino, off_t ofs, const void *buf, size_t eltsize, size_t count)
{
40001b02:	55                   	push   %ebp
40001b03:	89 e5                	mov    %esp,%ebp
40001b05:	57                   	push   %edi
40001b06:	56                   	push   %esi
40001b07:	53                   	push   %ebx
40001b08:	83 ec 6c             	sub    $0x6c,%esp
	assert(fileino_isreg(ino));
40001b0b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001b0f:	7e 45                	jle    40001b56 <fileino_write+0x54>
40001b11:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40001b18:	7f 3c                	jg     40001b56 <fileino_write+0x54>
40001b1a:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40001b20:	8b 45 08             	mov    0x8(%ebp),%eax
40001b23:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001b26:	01 d0                	add    %edx,%eax
40001b28:	05 10 10 00 00       	add    $0x1010,%eax
40001b2d:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40001b31:	84 c0                	test   %al,%al
40001b33:	74 21                	je     40001b56 <fileino_write+0x54>
40001b35:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40001b3b:	8b 45 08             	mov    0x8(%ebp),%eax
40001b3e:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001b41:	01 d0                	add    %edx,%eax
40001b43:	05 58 10 00 00       	add    $0x1058,%eax
40001b48:	8b 00                	mov    (%eax),%eax
40001b4a:	25 00 70 00 00       	and    $0x7000,%eax
40001b4f:	3d 00 10 00 00       	cmp    $0x1000,%eax
40001b54:	74 24                	je     40001b7a <fileino_write+0x78>
40001b56:	c7 44 24 0c e0 5d 00 	movl   $0x40005de0,0xc(%esp)
40001b5d:	40 
40001b5e:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40001b65:	40 
40001b66:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
40001b6d:	00 
40001b6e:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40001b75:	e8 ca ee ff ff       	call   40000a44 <debug_panic>
	assert(ofs >= 0);
40001b7a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40001b7e:	79 24                	jns    40001ba4 <fileino_write+0xa2>
40001b80:	c7 44 24 0c f3 5d 00 	movl   $0x40005df3,0xc(%esp)
40001b87:	40 
40001b88:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40001b8f:	40 
40001b90:	c7 44 24 04 84 00 00 	movl   $0x84,0x4(%esp)
40001b97:	00 
40001b98:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40001b9f:	e8 a0 ee ff ff       	call   40000a44 <debug_panic>
	assert(eltsize > 0);
40001ba4:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40001ba8:	75 24                	jne    40001bce <fileino_write+0xcc>
40001baa:	c7 44 24 0c fc 5d 00 	movl   $0x40005dfc,0xc(%esp)
40001bb1:	40 
40001bb2:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40001bb9:	40 
40001bba:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
40001bc1:	00 
40001bc2:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40001bc9:	e8 76 ee ff ff       	call   40000a44 <debug_panic>

	int i = 0;
40001bce:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	ssize_t return_number = 0;
40001bd5:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	fileinode *fi = &files->fi[ino];
40001bdc:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40001be1:	8b 55 08             	mov    0x8(%ebp),%edx
40001be4:	6b d2 5c             	imul   $0x5c,%edx,%edx
40001be7:	81 c2 10 10 00 00    	add    $0x1010,%edx
40001bed:	01 d0                	add    %edx,%eax
40001bef:	89 45 d8             	mov    %eax,-0x28(%ebp)
	assert(fi->size <= FILE_MAXSIZE);
40001bf2:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001bf5:	8b 40 4c             	mov    0x4c(%eax),%eax
40001bf8:	3d 00 00 40 00       	cmp    $0x400000,%eax
40001bfd:	76 24                	jbe    40001c23 <fileino_write+0x121>
40001bff:	c7 44 24 0c 08 5e 00 	movl   $0x40005e08,0xc(%esp)
40001c06:	40 
40001c07:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40001c0e:	40 
40001c0f:	c7 44 24 04 8a 00 00 	movl   $0x8a,0x4(%esp)
40001c16:	00 
40001c17:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40001c1e:	e8 21 ee ff ff       	call   40000a44 <debug_panic>
	uint8_t* write_start = FILEDATA(ino) + ofs;
40001c23:	8b 45 08             	mov    0x8(%ebp),%eax
40001c26:	c1 e0 16             	shl    $0x16,%eax
40001c29:	89 c2                	mov    %eax,%edx
40001c2b:	8b 45 0c             	mov    0xc(%ebp),%eax
40001c2e:	01 d0                	add    %edx,%eax
40001c30:	05 00 00 00 80       	add    $0x80000000,%eax
40001c35:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	uint8_t* write_pointer = write_start;
40001c38:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40001c3b:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uint32_t after_write_size = ofs + eltsize * count;
40001c3e:	8b 45 14             	mov    0x14(%ebp),%eax
40001c41:	89 c2                	mov    %eax,%edx
40001c43:	0f af 55 18          	imul   0x18(%ebp),%edx
40001c47:	8b 45 0c             	mov    0xc(%ebp),%eax
40001c4a:	01 d0                	add    %edx,%eax
40001c4c:	89 45 d0             	mov    %eax,-0x30(%ebp)

	if(after_write_size > FILE_MAXSIZE){
40001c4f:	81 7d d0 00 00 40 00 	cmpl   $0x400000,-0x30(%ebp)
40001c56:	76 15                	jbe    40001c6d <fileino_write+0x16b>
		errno = EFBIG;
40001c58:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40001c5d:	c7 00 03 00 00 00    	movl   $0x3,(%eax)
		return -1;
40001c63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40001c68:	e9 28 01 00 00       	jmp    40001d95 <fileino_write+0x293>
	}
	if(after_write_size > fi->size){
40001c6d:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001c70:	8b 40 4c             	mov    0x4c(%eax),%eax
40001c73:	3b 45 d0             	cmp    -0x30(%ebp),%eax
40001c76:	0f 83 0d 01 00 00    	jae    40001d89 <fileino_write+0x287>
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
40001c7c:	c7 45 cc 00 10 00 00 	movl   $0x1000,-0x34(%ebp)
40001c83:	8b 45 cc             	mov    -0x34(%ebp),%eax
40001c86:	8b 55 d0             	mov    -0x30(%ebp),%edx
40001c89:	01 d0                	add    %edx,%eax
40001c8b:	83 e8 01             	sub    $0x1,%eax
40001c8e:	89 45 c8             	mov    %eax,-0x38(%ebp)
40001c91:	8b 45 c8             	mov    -0x38(%ebp),%eax
40001c94:	ba 00 00 00 00       	mov    $0x0,%edx
40001c99:	f7 75 cc             	divl   -0x34(%ebp)
40001c9c:	89 d0                	mov    %edx,%eax
40001c9e:	8b 55 c8             	mov    -0x38(%ebp),%edx
40001ca1:	89 d1                	mov    %edx,%ecx
40001ca3:	29 c1                	sub    %eax,%ecx
40001ca5:	89 c8                	mov    %ecx,%eax
40001ca7:	89 c1                	mov    %eax,%ecx
40001ca9:	c7 45 c4 00 10 00 00 	movl   $0x1000,-0x3c(%ebp)
40001cb0:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001cb3:	8b 50 4c             	mov    0x4c(%eax),%edx
40001cb6:	8b 45 c4             	mov    -0x3c(%ebp),%eax
40001cb9:	01 d0                	add    %edx,%eax
40001cbb:	83 e8 01             	sub    $0x1,%eax
40001cbe:	89 45 c0             	mov    %eax,-0x40(%ebp)
40001cc1:	8b 45 c0             	mov    -0x40(%ebp),%eax
40001cc4:	ba 00 00 00 00       	mov    $0x0,%edx
40001cc9:	f7 75 c4             	divl   -0x3c(%ebp)
40001ccc:	89 d0                	mov    %edx,%eax
40001cce:	8b 55 c0             	mov    -0x40(%ebp),%edx
40001cd1:	89 d3                	mov    %edx,%ebx
40001cd3:	29 c3                	sub    %eax,%ebx
40001cd5:	89 d8                	mov    %ebx,%eax
	if(after_write_size > FILE_MAXSIZE){
		errno = EFBIG;
		return -1;
	}
	if(after_write_size > fi->size){
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
40001cd7:	29 c1                	sub    %eax,%ecx
40001cd9:	8b 45 08             	mov    0x8(%ebp),%eax
40001cdc:	c1 e0 16             	shl    $0x16,%eax
40001cdf:	89 c3                	mov    %eax,%ebx
40001ce1:	c7 45 bc 00 10 00 00 	movl   $0x1000,-0x44(%ebp)
40001ce8:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001ceb:	8b 50 4c             	mov    0x4c(%eax),%edx
40001cee:	8b 45 bc             	mov    -0x44(%ebp),%eax
40001cf1:	01 d0                	add    %edx,%eax
40001cf3:	83 e8 01             	sub    $0x1,%eax
40001cf6:	89 45 b8             	mov    %eax,-0x48(%ebp)
40001cf9:	8b 45 b8             	mov    -0x48(%ebp),%eax
40001cfc:	ba 00 00 00 00       	mov    $0x0,%edx
40001d01:	f7 75 bc             	divl   -0x44(%ebp)
40001d04:	89 d0                	mov    %edx,%eax
40001d06:	8b 55 b8             	mov    -0x48(%ebp),%edx
40001d09:	89 d6                	mov    %edx,%esi
40001d0b:	29 c6                	sub    %eax,%esi
40001d0d:	89 f0                	mov    %esi,%eax
40001d0f:	01 d8                	add    %ebx,%eax
40001d11:	05 00 00 00 80       	add    $0x80000000,%eax
40001d16:	c7 45 b4 00 07 00 00 	movl   $0x700,-0x4c(%ebp)
40001d1d:	66 c7 45 b2 00 00    	movw   $0x0,-0x4e(%ebp)
40001d23:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
40001d2a:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
40001d31:	89 45 a4             	mov    %eax,-0x5c(%ebp)
40001d34:	89 4d a0             	mov    %ecx,-0x60(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001d37:	8b 45 b4             	mov    -0x4c(%ebp),%eax
40001d3a:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001d3d:	8b 5d ac             	mov    -0x54(%ebp),%ebx
40001d40:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
40001d44:	8b 75 a8             	mov    -0x58(%ebp),%esi
40001d47:	8b 7d a4             	mov    -0x5c(%ebp),%edi
40001d4a:	8b 4d a0             	mov    -0x60(%ebp),%ecx
40001d4d:	cd 30                	int    $0x30
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
		fi->size = after_write_size;
40001d4f:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001d52:	8b 55 d0             	mov    -0x30(%ebp),%edx
40001d55:	89 50 4c             	mov    %edx,0x4c(%eax)
	}
	for(i; i < count; i++){
40001d58:	eb 2f                	jmp    40001d89 <fileino_write+0x287>
		memcpy(write_pointer, buf, eltsize);
40001d5a:	8b 45 14             	mov    0x14(%ebp),%eax
40001d5d:	89 44 24 08          	mov    %eax,0x8(%esp)
40001d61:	8b 45 10             	mov    0x10(%ebp),%eax
40001d64:	89 44 24 04          	mov    %eax,0x4(%esp)
40001d68:	8b 45 dc             	mov    -0x24(%ebp),%eax
40001d6b:	89 04 24             	mov    %eax,(%esp)
40001d6e:	e8 4a f9 ff ff       	call   400016bd <memcpy>
		return_number++;
40001d73:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
		buf += eltsize;
40001d77:	8b 45 14             	mov    0x14(%ebp),%eax
40001d7a:	01 45 10             	add    %eax,0x10(%ebp)
		write_pointer += eltsize;
40001d7d:	8b 45 14             	mov    0x14(%ebp),%eax
40001d80:	01 45 dc             	add    %eax,-0x24(%ebp)
	if(after_write_size > fi->size){
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
		fi->size = after_write_size;
	}
	for(i; i < count; i++){
40001d83:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
40001d87:	eb 01                	jmp    40001d8a <fileino_write+0x288>
40001d89:	90                   	nop
40001d8a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001d8d:	3b 45 18             	cmp    0x18(%ebp),%eax
40001d90:	72 c8                	jb     40001d5a <fileino_write+0x258>
		memcpy(write_pointer, buf, eltsize);
		return_number++;
		buf += eltsize;
		write_pointer += eltsize;
	}
	return return_number;
40001d92:	8b 45 e0             	mov    -0x20(%ebp),%eax

	// Lab 4: insert your file writing code here.
	//warn("fileino_write() not implemented");
	//errno = EINVAL;
	//return -1;
}
40001d95:	83 c4 6c             	add    $0x6c,%esp
40001d98:	5b                   	pop    %ebx
40001d99:	5e                   	pop    %esi
40001d9a:	5f                   	pop    %edi
40001d9b:	5d                   	pop    %ebp
40001d9c:	c3                   	ret    

40001d9d <fileino_stat>:
// Return file statistics about a particular inode.
// The specified inode must indicate a file that exists,
// but it can be any type of object: e.g., file, directory, special file, etc.
int
fileino_stat(int ino, struct stat *st)
{
40001d9d:	55                   	push   %ebp
40001d9e:	89 e5                	mov    %esp,%ebp
40001da0:	83 ec 28             	sub    $0x28,%esp
	assert(fileino_exists(ino));
40001da3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001da7:	7e 3d                	jle    40001de6 <fileino_stat+0x49>
40001da9:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40001db0:	7f 34                	jg     40001de6 <fileino_stat+0x49>
40001db2:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40001db8:	8b 45 08             	mov    0x8(%ebp),%eax
40001dbb:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001dbe:	01 d0                	add    %edx,%eax
40001dc0:	05 10 10 00 00       	add    $0x1010,%eax
40001dc5:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40001dc9:	84 c0                	test   %al,%al
40001dcb:	74 19                	je     40001de6 <fileino_stat+0x49>
40001dcd:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40001dd3:	8b 45 08             	mov    0x8(%ebp),%eax
40001dd6:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001dd9:	01 d0                	add    %edx,%eax
40001ddb:	05 58 10 00 00       	add    $0x1058,%eax
40001de0:	8b 00                	mov    (%eax),%eax
40001de2:	85 c0                	test   %eax,%eax
40001de4:	75 24                	jne    40001e0a <fileino_stat+0x6d>
40001de6:	c7 44 24 0c 21 5e 00 	movl   $0x40005e21,0xc(%esp)
40001ded:	40 
40001dee:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40001df5:	40 
40001df6:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
40001dfd:	00 
40001dfe:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40001e05:	e8 3a ec ff ff       	call   40000a44 <debug_panic>

	fileinode *fi = &files->fi[ino];
40001e0a:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40001e0f:	8b 55 08             	mov    0x8(%ebp),%edx
40001e12:	6b d2 5c             	imul   $0x5c,%edx,%edx
40001e15:	81 c2 10 10 00 00    	add    $0x1010,%edx
40001e1b:	01 d0                	add    %edx,%eax
40001e1d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert(fileino_isdir(fi->dino));	// Should be in a directory!
40001e20:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001e23:	8b 00                	mov    (%eax),%eax
40001e25:	85 c0                	test   %eax,%eax
40001e27:	7e 4c                	jle    40001e75 <fileino_stat+0xd8>
40001e29:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001e2c:	8b 00                	mov    (%eax),%eax
40001e2e:	3d ff 00 00 00       	cmp    $0xff,%eax
40001e33:	7f 40                	jg     40001e75 <fileino_stat+0xd8>
40001e35:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40001e3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001e3e:	8b 00                	mov    (%eax),%eax
40001e40:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001e43:	01 d0                	add    %edx,%eax
40001e45:	05 10 10 00 00       	add    $0x1010,%eax
40001e4a:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40001e4e:	84 c0                	test   %al,%al
40001e50:	74 23                	je     40001e75 <fileino_stat+0xd8>
40001e52:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40001e58:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001e5b:	8b 00                	mov    (%eax),%eax
40001e5d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001e60:	01 d0                	add    %edx,%eax
40001e62:	05 58 10 00 00       	add    $0x1058,%eax
40001e67:	8b 00                	mov    (%eax),%eax
40001e69:	25 00 70 00 00       	and    $0x7000,%eax
40001e6e:	3d 00 20 00 00       	cmp    $0x2000,%eax
40001e73:	74 24                	je     40001e99 <fileino_stat+0xfc>
40001e75:	c7 44 24 0c 35 5e 00 	movl   $0x40005e35,0xc(%esp)
40001e7c:	40 
40001e7d:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40001e84:	40 
40001e85:	c7 44 24 04 af 00 00 	movl   $0xaf,0x4(%esp)
40001e8c:	00 
40001e8d:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40001e94:	e8 ab eb ff ff       	call   40000a44 <debug_panic>
	st->st_ino = ino;
40001e99:	8b 45 0c             	mov    0xc(%ebp),%eax
40001e9c:	8b 55 08             	mov    0x8(%ebp),%edx
40001e9f:	89 10                	mov    %edx,(%eax)
	st->st_mode = fi->mode;
40001ea1:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001ea4:	8b 50 48             	mov    0x48(%eax),%edx
40001ea7:	8b 45 0c             	mov    0xc(%ebp),%eax
40001eaa:	89 50 04             	mov    %edx,0x4(%eax)
	st->st_size = fi->size;
40001ead:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001eb0:	8b 40 4c             	mov    0x4c(%eax),%eax
40001eb3:	89 c2                	mov    %eax,%edx
40001eb5:	8b 45 0c             	mov    0xc(%ebp),%eax
40001eb8:	89 50 08             	mov    %edx,0x8(%eax)

	return 0;
40001ebb:	b8 00 00 00 00       	mov    $0x0,%eax
}
40001ec0:	c9                   	leave  
40001ec1:	c3                   	ret    

40001ec2 <fileino_truncate>:
// Grow or shrink a file to exactly a specified size.
// If growing a file, then fills the new space with zeros.
// Returns 0 if successful, or returns -1 and sets errno on error.
int
fileino_truncate(int ino, off_t newsize)
{
40001ec2:	55                   	push   %ebp
40001ec3:	89 e5                	mov    %esp,%ebp
40001ec5:	57                   	push   %edi
40001ec6:	56                   	push   %esi
40001ec7:	53                   	push   %ebx
40001ec8:	81 ec 8c 00 00 00    	sub    $0x8c,%esp
	assert(fileino_isvalid(ino));
40001ece:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001ed2:	7e 09                	jle    40001edd <fileino_truncate+0x1b>
40001ed4:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40001edb:	7e 24                	jle    40001f01 <fileino_truncate+0x3f>
40001edd:	c7 44 24 0c 4d 5e 00 	movl   $0x40005e4d,0xc(%esp)
40001ee4:	40 
40001ee5:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40001eec:	40 
40001eed:	c7 44 24 04 bd 00 00 	movl   $0xbd,0x4(%esp)
40001ef4:	00 
40001ef5:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40001efc:	e8 43 eb ff ff       	call   40000a44 <debug_panic>
	assert(newsize >= 0 && newsize <= FILE_MAXSIZE);
40001f01:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40001f05:	78 09                	js     40001f10 <fileino_truncate+0x4e>
40001f07:	81 7d 0c 00 00 40 00 	cmpl   $0x400000,0xc(%ebp)
40001f0e:	7e 24                	jle    40001f34 <fileino_truncate+0x72>
40001f10:	c7 44 24 0c 64 5e 00 	movl   $0x40005e64,0xc(%esp)
40001f17:	40 
40001f18:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40001f1f:	40 
40001f20:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
40001f27:	00 
40001f28:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40001f2f:	e8 10 eb ff ff       	call   40000a44 <debug_panic>

	size_t oldsize = files->fi[ino].size;
40001f34:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40001f3a:	8b 45 08             	mov    0x8(%ebp),%eax
40001f3d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001f40:	01 d0                	add    %edx,%eax
40001f42:	05 5c 10 00 00       	add    $0x105c,%eax
40001f47:	8b 00                	mov    (%eax),%eax
40001f49:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	size_t oldpagelim = ROUNDUP(files->fi[ino].size, PAGESIZE);
40001f4c:	c7 45 e0 00 10 00 00 	movl   $0x1000,-0x20(%ebp)
40001f53:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40001f59:	8b 45 08             	mov    0x8(%ebp),%eax
40001f5c:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001f5f:	01 d0                	add    %edx,%eax
40001f61:	05 5c 10 00 00       	add    $0x105c,%eax
40001f66:	8b 10                	mov    (%eax),%edx
40001f68:	8b 45 e0             	mov    -0x20(%ebp),%eax
40001f6b:	01 d0                	add    %edx,%eax
40001f6d:	83 e8 01             	sub    $0x1,%eax
40001f70:	89 45 dc             	mov    %eax,-0x24(%ebp)
40001f73:	8b 45 dc             	mov    -0x24(%ebp),%eax
40001f76:	ba 00 00 00 00       	mov    $0x0,%edx
40001f7b:	f7 75 e0             	divl   -0x20(%ebp)
40001f7e:	89 d0                	mov    %edx,%eax
40001f80:	8b 55 dc             	mov    -0x24(%ebp),%edx
40001f83:	89 d1                	mov    %edx,%ecx
40001f85:	29 c1                	sub    %eax,%ecx
40001f87:	89 c8                	mov    %ecx,%eax
40001f89:	89 45 d8             	mov    %eax,-0x28(%ebp)
	size_t newpagelim = ROUNDUP(newsize, PAGESIZE);
40001f8c:	c7 45 d4 00 10 00 00 	movl   $0x1000,-0x2c(%ebp)
40001f93:	8b 55 0c             	mov    0xc(%ebp),%edx
40001f96:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40001f99:	01 d0                	add    %edx,%eax
40001f9b:	83 e8 01             	sub    $0x1,%eax
40001f9e:	89 45 d0             	mov    %eax,-0x30(%ebp)
40001fa1:	8b 45 d0             	mov    -0x30(%ebp),%eax
40001fa4:	ba 00 00 00 00       	mov    $0x0,%edx
40001fa9:	f7 75 d4             	divl   -0x2c(%ebp)
40001fac:	89 d0                	mov    %edx,%eax
40001fae:	8b 55 d0             	mov    -0x30(%ebp),%edx
40001fb1:	89 d1                	mov    %edx,%ecx
40001fb3:	29 c1                	sub    %eax,%ecx
40001fb5:	89 c8                	mov    %ecx,%eax
40001fb7:	89 45 cc             	mov    %eax,-0x34(%ebp)
	if (newsize > oldsize) {
40001fba:	8b 45 0c             	mov    0xc(%ebp),%eax
40001fbd:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
40001fc0:	0f 86 8a 00 00 00    	jbe    40002050 <fileino_truncate+0x18e>
		// Grow the file and fill the new space with zeros.
		sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
40001fc6:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001fc9:	8b 55 cc             	mov    -0x34(%ebp),%edx
40001fcc:	89 d1                	mov    %edx,%ecx
40001fce:	29 c1                	sub    %eax,%ecx
40001fd0:	89 c8                	mov    %ecx,%eax
			FILEDATA(ino) + oldpagelim,
40001fd2:	8b 55 08             	mov    0x8(%ebp),%edx
40001fd5:	c1 e2 16             	shl    $0x16,%edx
40001fd8:	89 d1                	mov    %edx,%ecx
40001fda:	8b 55 d8             	mov    -0x28(%ebp),%edx
40001fdd:	01 ca                	add    %ecx,%edx
	size_t oldsize = files->fi[ino].size;
	size_t oldpagelim = ROUNDUP(files->fi[ino].size, PAGESIZE);
	size_t newpagelim = ROUNDUP(newsize, PAGESIZE);
	if (newsize > oldsize) {
		// Grow the file and fill the new space with zeros.
		sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
40001fdf:	81 c2 00 00 00 80    	add    $0x80000000,%edx
40001fe5:	c7 45 c8 00 07 00 00 	movl   $0x700,-0x38(%ebp)
40001fec:	66 c7 45 c6 00 00    	movw   $0x0,-0x3a(%ebp)
40001ff2:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
40001ff9:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
40002000:	89 55 b8             	mov    %edx,-0x48(%ebp)
40002003:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40002006:	8b 45 c8             	mov    -0x38(%ebp),%eax
40002009:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000200c:	8b 5d c0             	mov    -0x40(%ebp),%ebx
4000200f:	0f b7 55 c6          	movzwl -0x3a(%ebp),%edx
40002013:	8b 75 bc             	mov    -0x44(%ebp),%esi
40002016:	8b 7d b8             	mov    -0x48(%ebp),%edi
40002019:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
4000201c:	cd 30                	int    $0x30
			FILEDATA(ino) + oldpagelim,
			newpagelim - oldpagelim);
		memset(FILEDATA(ino) + oldsize, 0, newsize - oldsize);
4000201e:	8b 45 0c             	mov    0xc(%ebp),%eax
40002021:	2b 45 e4             	sub    -0x1c(%ebp),%eax
40002024:	8b 55 08             	mov    0x8(%ebp),%edx
40002027:	c1 e2 16             	shl    $0x16,%edx
4000202a:	89 d1                	mov    %edx,%ecx
4000202c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
4000202f:	01 ca                	add    %ecx,%edx
40002031:	81 c2 00 00 00 80    	add    $0x80000000,%edx
40002037:	89 44 24 08          	mov    %eax,0x8(%esp)
4000203b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002042:	00 
40002043:	89 14 24             	mov    %edx,(%esp)
40002046:	e8 2a f5 ff ff       	call   40001575 <memset>
4000204b:	e9 a4 00 00 00       	jmp    400020f4 <fileino_truncate+0x232>
	} else if (newsize > 0) {
40002050:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40002054:	7e 56                	jle    400020ac <fileino_truncate+0x1ea>
		// Shrink the file, but not all the way to empty.
		// Would prefer to use SYS_ZERO to free the file content,
		// but SYS_ZERO isn't guaranteed to work at page granularity.
		sys_get(SYS_PERM, 0, NULL, NULL,
40002056:	b8 00 00 40 00       	mov    $0x400000,%eax
4000205b:	2b 45 cc             	sub    -0x34(%ebp),%eax
			FILEDATA(ino) + newpagelim, FILE_MAXSIZE - newpagelim);
4000205e:	8b 55 08             	mov    0x8(%ebp),%edx
40002061:	c1 e2 16             	shl    $0x16,%edx
40002064:	89 d1                	mov    %edx,%ecx
40002066:	8b 55 cc             	mov    -0x34(%ebp),%edx
40002069:	01 ca                	add    %ecx,%edx
		memset(FILEDATA(ino) + oldsize, 0, newsize - oldsize);
	} else if (newsize > 0) {
		// Shrink the file, but not all the way to empty.
		// Would prefer to use SYS_ZERO to free the file content,
		// but SYS_ZERO isn't guaranteed to work at page granularity.
		sys_get(SYS_PERM, 0, NULL, NULL,
4000206b:	81 c2 00 00 00 80    	add    $0x80000000,%edx
40002071:	c7 45 b0 00 01 00 00 	movl   $0x100,-0x50(%ebp)
40002078:	66 c7 45 ae 00 00    	movw   $0x0,-0x52(%ebp)
4000207e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
40002085:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
4000208c:	89 55 a0             	mov    %edx,-0x60(%ebp)
4000208f:	89 45 9c             	mov    %eax,-0x64(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40002092:	8b 45 b0             	mov    -0x50(%ebp),%eax
40002095:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40002098:	8b 5d a8             	mov    -0x58(%ebp),%ebx
4000209b:	0f b7 55 ae          	movzwl -0x52(%ebp),%edx
4000209f:	8b 75 a4             	mov    -0x5c(%ebp),%esi
400020a2:	8b 7d a0             	mov    -0x60(%ebp),%edi
400020a5:	8b 4d 9c             	mov    -0x64(%ebp),%ecx
400020a8:	cd 30                	int    $0x30
400020aa:	eb 48                	jmp    400020f4 <fileino_truncate+0x232>
			FILEDATA(ino) + newpagelim, FILE_MAXSIZE - newpagelim);
	} else {
		// Shrink the file to empty.  Use SYS_ZERO to free completely.
		sys_get(SYS_ZERO, 0, NULL, NULL, FILEDATA(ino), FILE_MAXSIZE);
400020ac:	8b 45 08             	mov    0x8(%ebp),%eax
400020af:	c1 e0 16             	shl    $0x16,%eax
400020b2:	05 00 00 00 80       	add    $0x80000000,%eax
400020b7:	c7 45 98 00 00 01 00 	movl   $0x10000,-0x68(%ebp)
400020be:	66 c7 45 96 00 00    	movw   $0x0,-0x6a(%ebp)
400020c4:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
400020cb:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
400020d2:	89 45 88             	mov    %eax,-0x78(%ebp)
400020d5:	c7 45 84 00 00 40 00 	movl   $0x400000,-0x7c(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400020dc:	8b 45 98             	mov    -0x68(%ebp),%eax
400020df:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400020e2:	8b 5d 90             	mov    -0x70(%ebp),%ebx
400020e5:	0f b7 55 96          	movzwl -0x6a(%ebp),%edx
400020e9:	8b 75 8c             	mov    -0x74(%ebp),%esi
400020ec:	8b 7d 88             	mov    -0x78(%ebp),%edi
400020ef:	8b 4d 84             	mov    -0x7c(%ebp),%ecx
400020f2:	cd 30                	int    $0x30
	}
	files->fi[ino].size = newsize;
400020f4:	8b 0d 3c 5d 00 40    	mov    0x40005d3c,%ecx
400020fa:	8b 45 0c             	mov    0xc(%ebp),%eax
400020fd:	8b 55 08             	mov    0x8(%ebp),%edx
40002100:	6b d2 5c             	imul   $0x5c,%edx,%edx
40002103:	01 ca                	add    %ecx,%edx
40002105:	81 c2 5c 10 00 00    	add    $0x105c,%edx
4000210b:	89 02                	mov    %eax,(%edx)
	files->fi[ino].ver++;	// truncation is always an exclusive change
4000210d:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40002112:	8b 55 08             	mov    0x8(%ebp),%edx
40002115:	6b d2 5c             	imul   $0x5c,%edx,%edx
40002118:	01 c2                	add    %eax,%edx
4000211a:	81 c2 54 10 00 00    	add    $0x1054,%edx
40002120:	8b 12                	mov    (%edx),%edx
40002122:	83 c2 01             	add    $0x1,%edx
40002125:	8b 4d 08             	mov    0x8(%ebp),%ecx
40002128:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
4000212b:	01 c8                	add    %ecx,%eax
4000212d:	05 54 10 00 00       	add    $0x1054,%eax
40002132:	89 10                	mov    %edx,(%eax)
	return 0;
40002134:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002139:	81 c4 8c 00 00 00    	add    $0x8c,%esp
4000213f:	5b                   	pop    %ebx
40002140:	5e                   	pop    %esi
40002141:	5f                   	pop    %edi
40002142:	5d                   	pop    %ebp
40002143:	c3                   	ret    

40002144 <fileino_flush>:

// Flush any outstanding writes on this file to our parent process.
// (XXX should flushes propagate across multiple levels?)
int
fileino_flush(int ino)
{
40002144:	55                   	push   %ebp
40002145:	89 e5                	mov    %esp,%ebp
40002147:	83 ec 18             	sub    $0x18,%esp
	assert(fileino_isvalid(ino));
4000214a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
4000214e:	7e 09                	jle    40002159 <fileino_flush+0x15>
40002150:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40002157:	7e 24                	jle    4000217d <fileino_flush+0x39>
40002159:	c7 44 24 0c 4d 5e 00 	movl   $0x40005e4d,0xc(%esp)
40002160:	40 
40002161:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40002168:	40 
40002169:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
40002170:	00 
40002171:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40002178:	e8 c7 e8 ff ff       	call   40000a44 <debug_panic>

	if (files->fi[ino].size > files->fi[ino].rlen)
4000217d:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002183:	8b 45 08             	mov    0x8(%ebp),%eax
40002186:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002189:	01 d0                	add    %edx,%eax
4000218b:	05 5c 10 00 00       	add    $0x105c,%eax
40002190:	8b 10                	mov    (%eax),%edx
40002192:	8b 0d 3c 5d 00 40    	mov    0x40005d3c,%ecx
40002198:	8b 45 08             	mov    0x8(%ebp),%eax
4000219b:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000219e:	01 c8                	add    %ecx,%eax
400021a0:	05 68 10 00 00       	add    $0x1068,%eax
400021a5:	8b 00                	mov    (%eax),%eax
400021a7:	39 c2                	cmp    %eax,%edx
400021a9:	76 07                	jbe    400021b2 <fileino_flush+0x6e>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400021ab:	b8 03 00 00 00       	mov    $0x3,%eax
400021b0:	cd 30                	int    $0x30
		sys_ret();	// synchronize and reconcile with parent
	return 0;
400021b2:	b8 00 00 00 00       	mov    $0x0,%eax
}
400021b7:	c9                   	leave  
400021b8:	c3                   	ret    

400021b9 <filedesc_alloc>:
// Search the file descriptor table for the first free file descriptor,
// and return a pointer to that file descriptor.
// If no file descriptors are available,
// returns NULL and set errno appropriately.
filedesc *filedesc_alloc(void)
{
400021b9:	55                   	push   %ebp
400021ba:	89 e5                	mov    %esp,%ebp
400021bc:	83 ec 10             	sub    $0x10,%esp
	int i;
	for (i = 0; i < OPEN_MAX; i++)
400021bf:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
400021c6:	eb 2c                	jmp    400021f4 <filedesc_alloc+0x3b>
		if (files->fd[i].ino == FILEINO_NULL)
400021c8:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400021cd:	8b 55 fc             	mov    -0x4(%ebp),%edx
400021d0:	83 c2 01             	add    $0x1,%edx
400021d3:	c1 e2 04             	shl    $0x4,%edx
400021d6:	01 d0                	add    %edx,%eax
400021d8:	8b 00                	mov    (%eax),%eax
400021da:	85 c0                	test   %eax,%eax
400021dc:	75 12                	jne    400021f0 <filedesc_alloc+0x37>
			return &files->fd[i];
400021de:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400021e3:	8b 55 fc             	mov    -0x4(%ebp),%edx
400021e6:	83 c2 01             	add    $0x1,%edx
400021e9:	c1 e2 04             	shl    $0x4,%edx
400021ec:	01 d0                	add    %edx,%eax
400021ee:	eb 1d                	jmp    4000220d <filedesc_alloc+0x54>
// If no file descriptors are available,
// returns NULL and set errno appropriately.
filedesc *filedesc_alloc(void)
{
	int i;
	for (i = 0; i < OPEN_MAX; i++)
400021f0:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
400021f4:	81 7d fc ff 00 00 00 	cmpl   $0xff,-0x4(%ebp)
400021fb:	7e cb                	jle    400021c8 <filedesc_alloc+0xf>
		if (files->fd[i].ino == FILEINO_NULL)
			return &files->fd[i];
	errno = EMFILE;
400021fd:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40002202:	c7 00 04 00 00 00    	movl   $0x4,(%eax)
	return NULL;
40002208:	b8 00 00 00 00       	mov    $0x0,%eax
}
4000220d:	c9                   	leave  
4000220e:	c3                   	ret    

4000220f <filedesc_open>:
// The 'openflags' determines whether the file is created, truncated, etc.
// Returns the opened file descriptor on success,
// or returns NULL and sets errno on failure.
filedesc *
filedesc_open(filedesc *fd, const char *path, int openflags, mode_t mode)
{
4000220f:	55                   	push   %ebp
40002210:	89 e5                	mov    %esp,%ebp
40002212:	83 ec 28             	sub    $0x28,%esp
	if (!fd && !(fd = filedesc_alloc()))
40002215:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40002219:	75 18                	jne    40002233 <filedesc_open+0x24>
4000221b:	e8 99 ff ff ff       	call   400021b9 <filedesc_alloc>
40002220:	89 45 08             	mov    %eax,0x8(%ebp)
40002223:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40002227:	75 0a                	jne    40002233 <filedesc_open+0x24>
		return NULL;
40002229:	b8 00 00 00 00       	mov    $0x0,%eax
4000222e:	e9 04 02 00 00       	jmp    40002437 <filedesc_open+0x228>
	assert(fd->ino == FILEINO_NULL);
40002233:	8b 45 08             	mov    0x8(%ebp),%eax
40002236:	8b 00                	mov    (%eax),%eax
40002238:	85 c0                	test   %eax,%eax
4000223a:	74 24                	je     40002260 <filedesc_open+0x51>
4000223c:	c7 44 24 0c 8c 5e 00 	movl   $0x40005e8c,0xc(%esp)
40002243:	40 
40002244:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
4000224b:	40 
4000224c:	c7 44 24 04 00 01 00 	movl   $0x100,0x4(%esp)
40002253:	00 
40002254:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
4000225b:	e8 e4 e7 ff ff       	call   40000a44 <debug_panic>

	// Determine the complete file mode if it is to be created.
	mode_t createmode = (openflags & O_CREAT) ? S_IFREG | (mode & 0777) : 0;
40002260:	8b 45 10             	mov    0x10(%ebp),%eax
40002263:	83 e0 20             	and    $0x20,%eax
40002266:	85 c0                	test   %eax,%eax
40002268:	74 0d                	je     40002277 <filedesc_open+0x68>
4000226a:	8b 45 14             	mov    0x14(%ebp),%eax
4000226d:	25 ff 01 00 00       	and    $0x1ff,%eax
40002272:	80 cc 10             	or     $0x10,%ah
40002275:	eb 05                	jmp    4000227c <filedesc_open+0x6d>
40002277:	b8 00 00 00 00       	mov    $0x0,%eax
4000227c:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Walk the directory tree to find the desired directory entry,
	// creating an entry if it doesn't exist and O_CREAT is set.
	int ino = dir_walk(path, createmode);
4000227f:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002282:	89 44 24 04          	mov    %eax,0x4(%esp)
40002286:	8b 45 0c             	mov    0xc(%ebp),%eax
40002289:	89 04 24             	mov    %eax,(%esp)
4000228c:	e8 d7 05 00 00       	call   40002868 <dir_walk>
40002291:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (ino < 0)
40002294:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002298:	79 0a                	jns    400022a4 <filedesc_open+0x95>
		return NULL;
4000229a:	b8 00 00 00 00       	mov    $0x0,%eax
4000229f:	e9 93 01 00 00       	jmp    40002437 <filedesc_open+0x228>
	assert(fileino_exists(ino));
400022a4:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400022a8:	7e 3d                	jle    400022e7 <filedesc_open+0xd8>
400022aa:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
400022b1:	7f 34                	jg     400022e7 <filedesc_open+0xd8>
400022b3:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
400022b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
400022bc:	6b c0 5c             	imul   $0x5c,%eax,%eax
400022bf:	01 d0                	add    %edx,%eax
400022c1:	05 10 10 00 00       	add    $0x1010,%eax
400022c6:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400022ca:	84 c0                	test   %al,%al
400022cc:	74 19                	je     400022e7 <filedesc_open+0xd8>
400022ce:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
400022d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
400022d7:	6b c0 5c             	imul   $0x5c,%eax,%eax
400022da:	01 d0                	add    %edx,%eax
400022dc:	05 58 10 00 00       	add    $0x1058,%eax
400022e1:	8b 00                	mov    (%eax),%eax
400022e3:	85 c0                	test   %eax,%eax
400022e5:	75 24                	jne    4000230b <filedesc_open+0xfc>
400022e7:	c7 44 24 0c 21 5e 00 	movl   $0x40005e21,0xc(%esp)
400022ee:	40 
400022ef:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
400022f6:	40 
400022f7:	c7 44 24 04 0a 01 00 	movl   $0x10a,0x4(%esp)
400022fe:	00 
400022ff:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40002306:	e8 39 e7 ff ff       	call   40000a44 <debug_panic>

	// Refuse to open conflict-marked files;
	// the user needs to resolve the conflict and clear the conflict flag,
	// or just delete the conflicted file.
	if (files->fi[ino].mode & S_IFCONF) {
4000230b:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002311:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002314:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002317:	01 d0                	add    %edx,%eax
40002319:	05 58 10 00 00       	add    $0x1058,%eax
4000231e:	8b 00                	mov    (%eax),%eax
40002320:	25 00 00 01 00       	and    $0x10000,%eax
40002325:	85 c0                	test   %eax,%eax
40002327:	74 15                	je     4000233e <filedesc_open+0x12f>
		errno = ECONFLICT;
40002329:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
4000232e:	c7 00 0a 00 00 00    	movl   $0xa,(%eax)
		return NULL;
40002334:	b8 00 00 00 00       	mov    $0x0,%eax
40002339:	e9 f9 00 00 00       	jmp    40002437 <filedesc_open+0x228>
	}

	// Truncate the file if we were asked to
	if (openflags & O_TRUNC) {
4000233e:	8b 45 10             	mov    0x10(%ebp),%eax
40002341:	83 e0 40             	and    $0x40,%eax
40002344:	85 c0                	test   %eax,%eax
40002346:	74 5c                	je     400023a4 <filedesc_open+0x195>
		if (!(openflags & O_WRONLY)) {
40002348:	8b 45 10             	mov    0x10(%ebp),%eax
4000234b:	83 e0 02             	and    $0x2,%eax
4000234e:	85 c0                	test   %eax,%eax
40002350:	75 31                	jne    40002383 <filedesc_open+0x174>
			warn("filedesc_open: can't truncate non-writable file");
40002352:	c7 44 24 08 a4 5e 00 	movl   $0x40005ea4,0x8(%esp)
40002359:	40 
4000235a:	c7 44 24 04 17 01 00 	movl   $0x117,0x4(%esp)
40002361:	00 
40002362:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40002369:	e8 40 e7 ff ff       	call   40000aae <debug_warn>
			errno = EINVAL;
4000236e:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40002373:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
			return NULL;
40002379:	b8 00 00 00 00       	mov    $0x0,%eax
4000237e:	e9 b4 00 00 00       	jmp    40002437 <filedesc_open+0x228>
		}
		if (fileino_truncate(ino, 0) < 0)
40002383:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000238a:	00 
4000238b:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000238e:	89 04 24             	mov    %eax,(%esp)
40002391:	e8 2c fb ff ff       	call   40001ec2 <fileino_truncate>
40002396:	85 c0                	test   %eax,%eax
40002398:	79 0a                	jns    400023a4 <filedesc_open+0x195>
			return NULL;
4000239a:	b8 00 00 00 00       	mov    $0x0,%eax
4000239f:	e9 93 00 00 00       	jmp    40002437 <filedesc_open+0x228>
	}

	// Initialize the file descriptor
	fd->ino = ino;
400023a4:	8b 45 08             	mov    0x8(%ebp),%eax
400023a7:	8b 55 f0             	mov    -0x10(%ebp),%edx
400023aa:	89 10                	mov    %edx,(%eax)
	fd->flags = openflags;
400023ac:	8b 45 08             	mov    0x8(%ebp),%eax
400023af:	8b 55 10             	mov    0x10(%ebp),%edx
400023b2:	89 50 04             	mov    %edx,0x4(%eax)
	fd->ofs = (openflags & O_APPEND) ? files->fi[ino].size : 0;
400023b5:	8b 45 10             	mov    0x10(%ebp),%eax
400023b8:	83 e0 10             	and    $0x10,%eax
400023bb:	85 c0                	test   %eax,%eax
400023bd:	74 17                	je     400023d6 <filedesc_open+0x1c7>
400023bf:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
400023c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
400023c8:	6b c0 5c             	imul   $0x5c,%eax,%eax
400023cb:	01 d0                	add    %edx,%eax
400023cd:	05 5c 10 00 00       	add    $0x105c,%eax
400023d2:	8b 00                	mov    (%eax),%eax
400023d4:	eb 05                	jmp    400023db <filedesc_open+0x1cc>
400023d6:	b8 00 00 00 00       	mov    $0x0,%eax
400023db:	8b 55 08             	mov    0x8(%ebp),%edx
400023de:	89 42 08             	mov    %eax,0x8(%edx)
	fd->err = 0;
400023e1:	8b 45 08             	mov    0x8(%ebp),%eax
400023e4:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)

	assert(filedesc_isopen(fd));
400023eb:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400023f0:	83 c0 10             	add    $0x10,%eax
400023f3:	3b 45 08             	cmp    0x8(%ebp),%eax
400023f6:	77 18                	ja     40002410 <filedesc_open+0x201>
400023f8:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400023fd:	05 10 10 00 00       	add    $0x1010,%eax
40002402:	3b 45 08             	cmp    0x8(%ebp),%eax
40002405:	76 09                	jbe    40002410 <filedesc_open+0x201>
40002407:	8b 45 08             	mov    0x8(%ebp),%eax
4000240a:	8b 00                	mov    (%eax),%eax
4000240c:	85 c0                	test   %eax,%eax
4000240e:	75 24                	jne    40002434 <filedesc_open+0x225>
40002410:	c7 44 24 0c d4 5e 00 	movl   $0x40005ed4,0xc(%esp)
40002417:	40 
40002418:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
4000241f:	40 
40002420:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
40002427:	00 
40002428:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
4000242f:	e8 10 e6 ff ff       	call   40000a44 <debug_panic>
	return fd;
40002434:	8b 45 08             	mov    0x8(%ebp),%eax
}
40002437:	c9                   	leave  
40002438:	c3                   	ret    

40002439 <filedesc_read>:
// If the file is a special device input file such as the console,
// this function pretends the file has no end and instead
// uses sys_ret() to wait for the file to extend the special file.
ssize_t
filedesc_read(filedesc *fd, void *buf, size_t eltsize, size_t count)
{
40002439:	55                   	push   %ebp
4000243a:	89 e5                	mov    %esp,%ebp
4000243c:	83 ec 38             	sub    $0x38,%esp
	assert(filedesc_isreadable(fd));
4000243f:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40002444:	83 c0 10             	add    $0x10,%eax
40002447:	3b 45 08             	cmp    0x8(%ebp),%eax
4000244a:	77 25                	ja     40002471 <filedesc_read+0x38>
4000244c:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40002451:	05 10 10 00 00       	add    $0x1010,%eax
40002456:	3b 45 08             	cmp    0x8(%ebp),%eax
40002459:	76 16                	jbe    40002471 <filedesc_read+0x38>
4000245b:	8b 45 08             	mov    0x8(%ebp),%eax
4000245e:	8b 00                	mov    (%eax),%eax
40002460:	85 c0                	test   %eax,%eax
40002462:	74 0d                	je     40002471 <filedesc_read+0x38>
40002464:	8b 45 08             	mov    0x8(%ebp),%eax
40002467:	8b 40 04             	mov    0x4(%eax),%eax
4000246a:	83 e0 01             	and    $0x1,%eax
4000246d:	85 c0                	test   %eax,%eax
4000246f:	75 24                	jne    40002495 <filedesc_read+0x5c>
40002471:	c7 44 24 0c e8 5e 00 	movl   $0x40005ee8,0xc(%esp)
40002478:	40 
40002479:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40002480:	40 
40002481:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
40002488:	00 
40002489:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40002490:	e8 af e5 ff ff       	call   40000a44 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40002495:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
4000249b:	8b 45 08             	mov    0x8(%ebp),%eax
4000249e:	8b 00                	mov    (%eax),%eax
400024a0:	6b c0 5c             	imul   $0x5c,%eax,%eax
400024a3:	05 10 10 00 00       	add    $0x1010,%eax
400024a8:	01 d0                	add    %edx,%eax
400024aa:	89 45 f4             	mov    %eax,-0xc(%ebp)

	ssize_t actual = fileino_read(fd->ino, fd->ofs, buf, eltsize, count);
400024ad:	8b 45 08             	mov    0x8(%ebp),%eax
400024b0:	8b 50 08             	mov    0x8(%eax),%edx
400024b3:	8b 45 08             	mov    0x8(%ebp),%eax
400024b6:	8b 00                	mov    (%eax),%eax
400024b8:	8b 4d 14             	mov    0x14(%ebp),%ecx
400024bb:	89 4c 24 10          	mov    %ecx,0x10(%esp)
400024bf:	8b 4d 10             	mov    0x10(%ebp),%ecx
400024c2:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
400024c6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
400024c9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
400024cd:	89 54 24 04          	mov    %edx,0x4(%esp)
400024d1:	89 04 24             	mov    %eax,(%esp)
400024d4:	e8 93 f4 ff ff       	call   4000196c <fileino_read>
400024d9:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (actual < 0) {
400024dc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400024e0:	79 14                	jns    400024f6 <filedesc_read+0xbd>
		fd->err = errno;	// save error indication for ferror()
400024e2:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400024e7:	8b 10                	mov    (%eax),%edx
400024e9:	8b 45 08             	mov    0x8(%ebp),%eax
400024ec:	89 50 0c             	mov    %edx,0xc(%eax)
		return -1;
400024ef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400024f4:	eb 56                	jmp    4000254c <filedesc_read+0x113>
	}

	// Advance the file position
	fd->ofs += eltsize * actual;
400024f6:	8b 45 08             	mov    0x8(%ebp),%eax
400024f9:	8b 40 08             	mov    0x8(%eax),%eax
400024fc:	89 c2                	mov    %eax,%edx
400024fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002501:	0f af 45 10          	imul   0x10(%ebp),%eax
40002505:	01 d0                	add    %edx,%eax
40002507:	89 c2                	mov    %eax,%edx
40002509:	8b 45 08             	mov    0x8(%ebp),%eax
4000250c:	89 50 08             	mov    %edx,0x8(%eax)
	assert(actual == 0 || fi->size >= fd->ofs);
4000250f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002513:	74 34                	je     40002549 <filedesc_read+0x110>
40002515:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002518:	8b 50 4c             	mov    0x4c(%eax),%edx
4000251b:	8b 45 08             	mov    0x8(%ebp),%eax
4000251e:	8b 40 08             	mov    0x8(%eax),%eax
40002521:	39 c2                	cmp    %eax,%edx
40002523:	73 24                	jae    40002549 <filedesc_read+0x110>
40002525:	c7 44 24 0c 00 5f 00 	movl   $0x40005f00,0xc(%esp)
4000252c:	40 
4000252d:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40002534:	40 
40002535:	c7 44 24 04 42 01 00 	movl   $0x142,0x4(%esp)
4000253c:	00 
4000253d:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40002544:	e8 fb e4 ff ff       	call   40000a44 <debug_panic>

	return actual;
40002549:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
4000254c:	c9                   	leave  
4000254d:	c3                   	ret    

4000254e <filedesc_write>:
// The size of 'buf' must be at least 'count * eltsize' bytes.
// On success, returns the number of objects written (NOT the number of bytes).
// If an error occurs, returns -1 and sets errno appropriately.
ssize_t
filedesc_write(filedesc *fd, const void *buf, size_t eltsize, size_t count)
{
4000254e:	55                   	push   %ebp
4000254f:	89 e5                	mov    %esp,%ebp
40002551:	83 ec 38             	sub    $0x38,%esp
	assert(filedesc_iswritable(fd));
40002554:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40002559:	83 c0 10             	add    $0x10,%eax
4000255c:	3b 45 08             	cmp    0x8(%ebp),%eax
4000255f:	77 25                	ja     40002586 <filedesc_write+0x38>
40002561:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40002566:	05 10 10 00 00       	add    $0x1010,%eax
4000256b:	3b 45 08             	cmp    0x8(%ebp),%eax
4000256e:	76 16                	jbe    40002586 <filedesc_write+0x38>
40002570:	8b 45 08             	mov    0x8(%ebp),%eax
40002573:	8b 00                	mov    (%eax),%eax
40002575:	85 c0                	test   %eax,%eax
40002577:	74 0d                	je     40002586 <filedesc_write+0x38>
40002579:	8b 45 08             	mov    0x8(%ebp),%eax
4000257c:	8b 40 04             	mov    0x4(%eax),%eax
4000257f:	83 e0 02             	and    $0x2,%eax
40002582:	85 c0                	test   %eax,%eax
40002584:	75 24                	jne    400025aa <filedesc_write+0x5c>
40002586:	c7 44 24 0c 23 5f 00 	movl   $0x40005f23,0xc(%esp)
4000258d:	40 
4000258e:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40002595:	40 
40002596:	c7 44 24 04 4f 01 00 	movl   $0x14f,0x4(%esp)
4000259d:	00 
4000259e:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
400025a5:	e8 9a e4 ff ff       	call   40000a44 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
400025aa:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
400025b0:	8b 45 08             	mov    0x8(%ebp),%eax
400025b3:	8b 00                	mov    (%eax),%eax
400025b5:	6b c0 5c             	imul   $0x5c,%eax,%eax
400025b8:	05 10 10 00 00       	add    $0x1010,%eax
400025bd:	01 d0                	add    %edx,%eax
400025bf:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// If we're appending to the file, seek to the end first.
	if (fd->flags & O_APPEND)
400025c2:	8b 45 08             	mov    0x8(%ebp),%eax
400025c5:	8b 40 04             	mov    0x4(%eax),%eax
400025c8:	83 e0 10             	and    $0x10,%eax
400025cb:	85 c0                	test   %eax,%eax
400025cd:	74 0e                	je     400025dd <filedesc_write+0x8f>
		fd->ofs = fi->size;
400025cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
400025d2:	8b 40 4c             	mov    0x4c(%eax),%eax
400025d5:	89 c2                	mov    %eax,%edx
400025d7:	8b 45 08             	mov    0x8(%ebp),%eax
400025da:	89 50 08             	mov    %edx,0x8(%eax)

	// Write the data, growing the file as necessary.
	ssize_t actual = fileino_write(fd->ino, fd->ofs, buf, eltsize, count);
400025dd:	8b 45 08             	mov    0x8(%ebp),%eax
400025e0:	8b 50 08             	mov    0x8(%eax),%edx
400025e3:	8b 45 08             	mov    0x8(%ebp),%eax
400025e6:	8b 00                	mov    (%eax),%eax
400025e8:	8b 4d 14             	mov    0x14(%ebp),%ecx
400025eb:	89 4c 24 10          	mov    %ecx,0x10(%esp)
400025ef:	8b 4d 10             	mov    0x10(%ebp),%ecx
400025f2:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
400025f6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
400025f9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
400025fd:	89 54 24 04          	mov    %edx,0x4(%esp)
40002601:	89 04 24             	mov    %eax,(%esp)
40002604:	e8 f9 f4 ff ff       	call   40001b02 <fileino_write>
40002609:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (actual < 0) {
4000260c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002610:	79 17                	jns    40002629 <filedesc_write+0xdb>
		fd->err = errno;	// save error indication for ferror()
40002612:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40002617:	8b 10                	mov    (%eax),%edx
40002619:	8b 45 08             	mov    0x8(%ebp),%eax
4000261c:	89 50 0c             	mov    %edx,0xc(%eax)
		return -1;
4000261f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002624:	e9 98 00 00 00       	jmp    400026c1 <filedesc_write+0x173>
	}
	assert(actual == count);
40002629:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000262c:	3b 45 14             	cmp    0x14(%ebp),%eax
4000262f:	74 24                	je     40002655 <filedesc_write+0x107>
40002631:	c7 44 24 0c 3b 5f 00 	movl   $0x40005f3b,0xc(%esp)
40002638:	40 
40002639:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40002640:	40 
40002641:	c7 44 24 04 5c 01 00 	movl   $0x15c,0x4(%esp)
40002648:	00 
40002649:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40002650:	e8 ef e3 ff ff       	call   40000a44 <debug_panic>

	// Non-append-only writes constitute exclusive modifications,
	// so must bump the file's version number.
	if (!(fd->flags & O_APPEND))
40002655:	8b 45 08             	mov    0x8(%ebp),%eax
40002658:	8b 40 04             	mov    0x4(%eax),%eax
4000265b:	83 e0 10             	and    $0x10,%eax
4000265e:	85 c0                	test   %eax,%eax
40002660:	75 0f                	jne    40002671 <filedesc_write+0x123>
		fi->ver++;
40002662:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002665:	8b 40 44             	mov    0x44(%eax),%eax
40002668:	8d 50 01             	lea    0x1(%eax),%edx
4000266b:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000266e:	89 50 44             	mov    %edx,0x44(%eax)

	// Advance the file position
	fd->ofs += eltsize * count;
40002671:	8b 45 08             	mov    0x8(%ebp),%eax
40002674:	8b 40 08             	mov    0x8(%eax),%eax
40002677:	89 c2                	mov    %eax,%edx
40002679:	8b 45 10             	mov    0x10(%ebp),%eax
4000267c:	0f af 45 14          	imul   0x14(%ebp),%eax
40002680:	01 d0                	add    %edx,%eax
40002682:	89 c2                	mov    %eax,%edx
40002684:	8b 45 08             	mov    0x8(%ebp),%eax
40002687:	89 50 08             	mov    %edx,0x8(%eax)
	assert(fi->size >= fd->ofs);
4000268a:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000268d:	8b 50 4c             	mov    0x4c(%eax),%edx
40002690:	8b 45 08             	mov    0x8(%ebp),%eax
40002693:	8b 40 08             	mov    0x8(%eax),%eax
40002696:	39 c2                	cmp    %eax,%edx
40002698:	73 24                	jae    400026be <filedesc_write+0x170>
4000269a:	c7 44 24 0c 4b 5f 00 	movl   $0x40005f4b,0xc(%esp)
400026a1:	40 
400026a2:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
400026a9:	40 
400026aa:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
400026b1:	00 
400026b2:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
400026b9:	e8 86 e3 ff ff       	call   40000a44 <debug_panic>
	return count;
400026be:	8b 45 14             	mov    0x14(%ebp),%eax
}
400026c1:	c9                   	leave  
400026c2:	c3                   	ret    

400026c3 <filedesc_seek>:
// which may be relative to the file start, end, or corrent position,
// depending on 'whence' (SEEK_SET, SEEK_CUR, or SEEK_END).
// Returns the resulting absolute file position,
// or returns -1 and sets errno appropriately on error.
off_t filedesc_seek(filedesc *fd, off_t offset, int whence)
{
400026c3:	55                   	push   %ebp
400026c4:	89 e5                	mov    %esp,%ebp
400026c6:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isopen(fd));
400026c9:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400026ce:	83 c0 10             	add    $0x10,%eax
400026d1:	3b 45 08             	cmp    0x8(%ebp),%eax
400026d4:	77 18                	ja     400026ee <filedesc_seek+0x2b>
400026d6:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400026db:	05 10 10 00 00       	add    $0x1010,%eax
400026e0:	3b 45 08             	cmp    0x8(%ebp),%eax
400026e3:	76 09                	jbe    400026ee <filedesc_seek+0x2b>
400026e5:	8b 45 08             	mov    0x8(%ebp),%eax
400026e8:	8b 00                	mov    (%eax),%eax
400026ea:	85 c0                	test   %eax,%eax
400026ec:	75 24                	jne    40002712 <filedesc_seek+0x4f>
400026ee:	c7 44 24 0c d4 5e 00 	movl   $0x40005ed4,0xc(%esp)
400026f5:	40 
400026f6:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
400026fd:	40 
400026fe:	c7 44 24 04 70 01 00 	movl   $0x170,0x4(%esp)
40002705:	00 
40002706:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
4000270d:	e8 32 e3 ff ff       	call   40000a44 <debug_panic>
	assert(whence == SEEK_SET || whence == SEEK_CUR || whence == SEEK_END);
40002712:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40002716:	74 30                	je     40002748 <filedesc_seek+0x85>
40002718:	83 7d 10 01          	cmpl   $0x1,0x10(%ebp)
4000271c:	74 2a                	je     40002748 <filedesc_seek+0x85>
4000271e:	83 7d 10 02          	cmpl   $0x2,0x10(%ebp)
40002722:	74 24                	je     40002748 <filedesc_seek+0x85>
40002724:	c7 44 24 0c 60 5f 00 	movl   $0x40005f60,0xc(%esp)
4000272b:	40 
4000272c:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40002733:	40 
40002734:	c7 44 24 04 71 01 00 	movl   $0x171,0x4(%esp)
4000273b:	00 
4000273c:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40002743:	e8 fc e2 ff ff       	call   40000a44 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40002748:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
4000274e:	8b 45 08             	mov    0x8(%ebp),%eax
40002751:	8b 00                	mov    (%eax),%eax
40002753:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002756:	05 10 10 00 00       	add    $0x1010,%eax
4000275b:	01 d0                	add    %edx,%eax
4000275d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	ino_t ino = fd->ino;
40002760:	8b 45 08             	mov    0x8(%ebp),%eax
40002763:	8b 00                	mov    (%eax),%eax
40002765:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint8_t* start_pos = FILEDATA(ino);
40002768:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000276b:	c1 e0 16             	shl    $0x16,%eax
4000276e:	05 00 00 00 80       	add    $0x80000000,%eax
40002773:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// Lab 4: insert your file descriptor seek implementation here.
	//warn("filedesc_seek() not implemented");
	//errno = EINVAL;
	//return -1;
	switch(whence){
40002776:	8b 45 10             	mov    0x10(%ebp),%eax
40002779:	83 f8 01             	cmp    $0x1,%eax
4000277c:	74 14                	je     40002792 <filedesc_seek+0xcf>
4000277e:	83 f8 02             	cmp    $0x2,%eax
40002781:	74 22                	je     400027a5 <filedesc_seek+0xe2>
40002783:	85 c0                	test   %eax,%eax
40002785:	75 33                	jne    400027ba <filedesc_seek+0xf7>
	case SEEK_SET:
		fd->ofs = offset;
40002787:	8b 45 08             	mov    0x8(%ebp),%eax
4000278a:	8b 55 0c             	mov    0xc(%ebp),%edx
4000278d:	89 50 08             	mov    %edx,0x8(%eax)
		break;
40002790:	eb 3a                	jmp    400027cc <filedesc_seek+0x109>
	case SEEK_CUR:
		fd->ofs += offset;
40002792:	8b 45 08             	mov    0x8(%ebp),%eax
40002795:	8b 50 08             	mov    0x8(%eax),%edx
40002798:	8b 45 0c             	mov    0xc(%ebp),%eax
4000279b:	01 c2                	add    %eax,%edx
4000279d:	8b 45 08             	mov    0x8(%ebp),%eax
400027a0:	89 50 08             	mov    %edx,0x8(%eax)
		break;
400027a3:	eb 27                	jmp    400027cc <filedesc_seek+0x109>
	case SEEK_END:
		fd->ofs = (fi->size) + offset;
400027a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
400027a8:	8b 50 4c             	mov    0x4c(%eax),%edx
400027ab:	8b 45 0c             	mov    0xc(%ebp),%eax
400027ae:	01 d0                	add    %edx,%eax
400027b0:	89 c2                	mov    %eax,%edx
400027b2:	8b 45 08             	mov    0x8(%ebp),%eax
400027b5:	89 50 08             	mov    %edx,0x8(%eax)
		break;
400027b8:	eb 12                	jmp    400027cc <filedesc_seek+0x109>
	default:
		errno = EINVAL;
400027ba:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400027bf:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
		return -1;
400027c5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400027ca:	eb 06                	jmp    400027d2 <filedesc_seek+0x10f>
	}
	return fd->ofs;
400027cc:	8b 45 08             	mov    0x8(%ebp),%eax
400027cf:	8b 40 08             	mov    0x8(%eax),%eax
}
400027d2:	c9                   	leave  
400027d3:	c3                   	ret    

400027d4 <filedesc_close>:

void
filedesc_close(filedesc *fd)
{
400027d4:	55                   	push   %ebp
400027d5:	89 e5                	mov    %esp,%ebp
400027d7:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
400027da:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400027df:	83 c0 10             	add    $0x10,%eax
400027e2:	3b 45 08             	cmp    0x8(%ebp),%eax
400027e5:	77 18                	ja     400027ff <filedesc_close+0x2b>
400027e7:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400027ec:	05 10 10 00 00       	add    $0x1010,%eax
400027f1:	3b 45 08             	cmp    0x8(%ebp),%eax
400027f4:	76 09                	jbe    400027ff <filedesc_close+0x2b>
400027f6:	8b 45 08             	mov    0x8(%ebp),%eax
400027f9:	8b 00                	mov    (%eax),%eax
400027fb:	85 c0                	test   %eax,%eax
400027fd:	75 24                	jne    40002823 <filedesc_close+0x4f>
400027ff:	c7 44 24 0c d4 5e 00 	movl   $0x40005ed4,0xc(%esp)
40002806:	40 
40002807:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
4000280e:	40 
4000280f:	c7 44 24 04 8e 01 00 	movl   $0x18e,0x4(%esp)
40002816:	00 
40002817:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
4000281e:	e8 21 e2 ff ff       	call   40000a44 <debug_panic>
	assert(fileino_isvalid(fd->ino));
40002823:	8b 45 08             	mov    0x8(%ebp),%eax
40002826:	8b 00                	mov    (%eax),%eax
40002828:	85 c0                	test   %eax,%eax
4000282a:	7e 0c                	jle    40002838 <filedesc_close+0x64>
4000282c:	8b 45 08             	mov    0x8(%ebp),%eax
4000282f:	8b 00                	mov    (%eax),%eax
40002831:	3d ff 00 00 00       	cmp    $0xff,%eax
40002836:	7e 24                	jle    4000285c <filedesc_close+0x88>
40002838:	c7 44 24 0c 9f 5f 00 	movl   $0x40005f9f,0xc(%esp)
4000283f:	40 
40002840:	c7 44 24 08 74 5d 00 	movl   $0x40005d74,0x8(%esp)
40002847:	40 
40002848:	c7 44 24 04 8f 01 00 	movl   $0x18f,0x4(%esp)
4000284f:	00 
40002850:	c7 04 24 5f 5d 00 40 	movl   $0x40005d5f,(%esp)
40002857:	e8 e8 e1 ff ff       	call   40000a44 <debug_panic>

	fd->ino = FILEINO_NULL;		// mark the fd free
4000285c:	8b 45 08             	mov    0x8(%ebp),%eax
4000285f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
40002865:	c9                   	leave  
40002866:	c3                   	ret    
40002867:	90                   	nop

40002868 <dir_walk>:
#include <inc/dirent.h>


int
dir_walk(const char *path, mode_t createmode)
{
40002868:	55                   	push   %ebp
40002869:	89 e5                	mov    %esp,%ebp
4000286b:	83 ec 28             	sub    $0x28,%esp
	assert(path != 0 && *path != 0);
4000286e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40002872:	74 0a                	je     4000287e <dir_walk+0x16>
40002874:	8b 45 08             	mov    0x8(%ebp),%eax
40002877:	0f b6 00             	movzbl (%eax),%eax
4000287a:	84 c0                	test   %al,%al
4000287c:	75 24                	jne    400028a2 <dir_walk+0x3a>
4000287e:	c7 44 24 0c b8 5f 00 	movl   $0x40005fb8,0xc(%esp)
40002885:	40 
40002886:	c7 44 24 08 d0 5f 00 	movl   $0x40005fd0,0x8(%esp)
4000288d:	40 
4000288e:	c7 44 24 04 15 00 00 	movl   $0x15,0x4(%esp)
40002895:	00 
40002896:	c7 04 24 e5 5f 00 40 	movl   $0x40005fe5,(%esp)
4000289d:	e8 a2 e1 ff ff       	call   40000a44 <debug_panic>

	// Start at the current or root directory as appropriate
	int dino = files->cwd;
400028a2:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400028a7:	8b 40 04             	mov    0x4(%eax),%eax
400028aa:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (*path == '/') {
400028ad:	8b 45 08             	mov    0x8(%ebp),%eax
400028b0:	0f b6 00             	movzbl (%eax),%eax
400028b3:	3c 2f                	cmp    $0x2f,%al
400028b5:	75 27                	jne    400028de <dir_walk+0x76>
		dino = FILEINO_ROOTDIR;
400028b7:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
		do { path++; } while (*path == '/');	// skip leading slashes
400028be:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400028c2:	8b 45 08             	mov    0x8(%ebp),%eax
400028c5:	0f b6 00             	movzbl (%eax),%eax
400028c8:	3c 2f                	cmp    $0x2f,%al
400028ca:	74 f2                	je     400028be <dir_walk+0x56>
		if (*path == 0)
400028cc:	8b 45 08             	mov    0x8(%ebp),%eax
400028cf:	0f b6 00             	movzbl (%eax),%eax
400028d2:	84 c0                	test   %al,%al
400028d4:	75 08                	jne    400028de <dir_walk+0x76>
			return dino;	// Just looking up root directory
400028d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
400028d9:	e9 61 05 00 00       	jmp    40002e3f <dir_walk+0x5d7>
	}

	// Search for the appropriate entry in this directory
	searchdir:
	assert(fileino_isdir(dino));
400028de:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
400028e2:	7e 45                	jle    40002929 <dir_walk+0xc1>
400028e4:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
400028eb:	7f 3c                	jg     40002929 <dir_walk+0xc1>
400028ed:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
400028f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
400028f6:	6b c0 5c             	imul   $0x5c,%eax,%eax
400028f9:	01 d0                	add    %edx,%eax
400028fb:	05 10 10 00 00       	add    $0x1010,%eax
40002900:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002904:	84 c0                	test   %al,%al
40002906:	74 21                	je     40002929 <dir_walk+0xc1>
40002908:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
4000290e:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002911:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002914:	01 d0                	add    %edx,%eax
40002916:	05 58 10 00 00       	add    $0x1058,%eax
4000291b:	8b 00                	mov    (%eax),%eax
4000291d:	25 00 70 00 00       	and    $0x7000,%eax
40002922:	3d 00 20 00 00       	cmp    $0x2000,%eax
40002927:	74 24                	je     4000294d <dir_walk+0xe5>
40002929:	c7 44 24 0c ef 5f 00 	movl   $0x40005fef,0xc(%esp)
40002930:	40 
40002931:	c7 44 24 08 d0 5f 00 	movl   $0x40005fd0,0x8(%esp)
40002938:	40 
40002939:	c7 44 24 04 22 00 00 	movl   $0x22,0x4(%esp)
40002940:	00 
40002941:	c7 04 24 e5 5f 00 40 	movl   $0x40005fe5,(%esp)
40002948:	e8 f7 e0 ff ff       	call   40000a44 <debug_panic>
	assert(fileino_isdir(files->fi[dino].dino));
4000294d:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002953:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002956:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002959:	01 d0                	add    %edx,%eax
4000295b:	05 10 10 00 00       	add    $0x1010,%eax
40002960:	8b 00                	mov    (%eax),%eax
40002962:	85 c0                	test   %eax,%eax
40002964:	7e 7c                	jle    400029e2 <dir_walk+0x17a>
40002966:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
4000296c:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000296f:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002972:	01 d0                	add    %edx,%eax
40002974:	05 10 10 00 00       	add    $0x1010,%eax
40002979:	8b 00                	mov    (%eax),%eax
4000297b:	3d ff 00 00 00       	cmp    $0xff,%eax
40002980:	7f 60                	jg     400029e2 <dir_walk+0x17a>
40002982:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002988:	8b 0d 3c 5d 00 40    	mov    0x40005d3c,%ecx
4000298e:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002991:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002994:	01 c8                	add    %ecx,%eax
40002996:	05 10 10 00 00       	add    $0x1010,%eax
4000299b:	8b 00                	mov    (%eax),%eax
4000299d:	6b c0 5c             	imul   $0x5c,%eax,%eax
400029a0:	01 d0                	add    %edx,%eax
400029a2:	05 10 10 00 00       	add    $0x1010,%eax
400029a7:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400029ab:	84 c0                	test   %al,%al
400029ad:	74 33                	je     400029e2 <dir_walk+0x17a>
400029af:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
400029b5:	8b 0d 3c 5d 00 40    	mov    0x40005d3c,%ecx
400029bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
400029be:	6b c0 5c             	imul   $0x5c,%eax,%eax
400029c1:	01 c8                	add    %ecx,%eax
400029c3:	05 10 10 00 00       	add    $0x1010,%eax
400029c8:	8b 00                	mov    (%eax),%eax
400029ca:	6b c0 5c             	imul   $0x5c,%eax,%eax
400029cd:	01 d0                	add    %edx,%eax
400029cf:	05 58 10 00 00       	add    $0x1058,%eax
400029d4:	8b 00                	mov    (%eax),%eax
400029d6:	25 00 70 00 00       	and    $0x7000,%eax
400029db:	3d 00 20 00 00       	cmp    $0x2000,%eax
400029e0:	74 24                	je     40002a06 <dir_walk+0x19e>
400029e2:	c7 44 24 0c 04 60 00 	movl   $0x40006004,0xc(%esp)
400029e9:	40 
400029ea:	c7 44 24 08 d0 5f 00 	movl   $0x40005fd0,0x8(%esp)
400029f1:	40 
400029f2:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
400029f9:	00 
400029fa:	c7 04 24 e5 5f 00 40 	movl   $0x40005fe5,(%esp)
40002a01:	e8 3e e0 ff ff       	call   40000a44 <debug_panic>

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
40002a06:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
40002a0d:	e9 3d 02 00 00       	jmp    40002c4f <dir_walk+0x3e7>
		if (!fileino_alloced(ino) || files->fi[ino].dino != dino)
40002a12:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002a16:	0f 8e 28 02 00 00    	jle    40002c44 <dir_walk+0x3dc>
40002a1c:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40002a23:	0f 8f 1b 02 00 00    	jg     40002c44 <dir_walk+0x3dc>
40002a29:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002a2f:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002a32:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002a35:	01 d0                	add    %edx,%eax
40002a37:	05 10 10 00 00       	add    $0x1010,%eax
40002a3c:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002a40:	84 c0                	test   %al,%al
40002a42:	0f 84 fc 01 00 00    	je     40002c44 <dir_walk+0x3dc>
40002a48:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002a4e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002a51:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002a54:	01 d0                	add    %edx,%eax
40002a56:	05 10 10 00 00       	add    $0x1010,%eax
40002a5b:	8b 00                	mov    (%eax),%eax
40002a5d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40002a60:	0f 85 de 01 00 00    	jne    40002c44 <dir_walk+0x3dc>
			continue;	// not an entry in directory 'dino'

		// Does this inode's name match our next path component?
		len = strlen(files->fi[ino].de.d_name);
40002a66:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40002a6b:	8b 55 f0             	mov    -0x10(%ebp),%edx
40002a6e:	6b d2 5c             	imul   $0x5c,%edx,%edx
40002a71:	81 c2 10 10 00 00    	add    $0x1010,%edx
40002a77:	01 d0                	add    %edx,%eax
40002a79:	83 c0 04             	add    $0x4,%eax
40002a7c:	89 04 24             	mov    %eax,(%esp)
40002a7f:	e8 34 e9 ff ff       	call   400013b8 <strlen>
40002a84:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (memcmp(path, files->fi[ino].de.d_name, len) != 0)
40002a87:	8b 45 ec             	mov    -0x14(%ebp),%eax
40002a8a:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002a90:	8b 4d f0             	mov    -0x10(%ebp),%ecx
40002a93:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
40002a96:	81 c1 10 10 00 00    	add    $0x1010,%ecx
40002a9c:	01 ca                	add    %ecx,%edx
40002a9e:	83 c2 04             	add    $0x4,%edx
40002aa1:	89 44 24 08          	mov    %eax,0x8(%esp)
40002aa5:	89 54 24 04          	mov    %edx,0x4(%esp)
40002aa9:	8b 45 08             	mov    0x8(%ebp),%eax
40002aac:	89 04 24             	mov    %eax,(%esp)
40002aaf:	e8 2a ec ff ff       	call   400016de <memcmp>
40002ab4:	85 c0                	test   %eax,%eax
40002ab6:	0f 85 8b 01 00 00    	jne    40002c47 <dir_walk+0x3df>
			continue;	// no match
		found:
		if (path[len] == 0) {
40002abc:	8b 55 ec             	mov    -0x14(%ebp),%edx
40002abf:	8b 45 08             	mov    0x8(%ebp),%eax
40002ac2:	01 d0                	add    %edx,%eax
40002ac4:	0f b6 00             	movzbl (%eax),%eax
40002ac7:	84 c0                	test   %al,%al
40002ac9:	0f 85 c7 00 00 00    	jne    40002b96 <dir_walk+0x32e>
			// Exact match at end of path - but does it exist?
			if (fileino_exists(ino))
40002acf:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002ad3:	7e 45                	jle    40002b1a <dir_walk+0x2b2>
40002ad5:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40002adc:	7f 3c                	jg     40002b1a <dir_walk+0x2b2>
40002ade:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002ae4:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002ae7:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002aea:	01 d0                	add    %edx,%eax
40002aec:	05 10 10 00 00       	add    $0x1010,%eax
40002af1:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002af5:	84 c0                	test   %al,%al
40002af7:	74 21                	je     40002b1a <dir_walk+0x2b2>
40002af9:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002aff:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002b02:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002b05:	01 d0                	add    %edx,%eax
40002b07:	05 58 10 00 00       	add    $0x1058,%eax
40002b0c:	8b 00                	mov    (%eax),%eax
40002b0e:	85 c0                	test   %eax,%eax
40002b10:	74 08                	je     40002b1a <dir_walk+0x2b2>
				return ino;	// yes - return it
40002b12:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002b15:	e9 25 03 00 00       	jmp    40002e3f <dir_walk+0x5d7>

			// no - existed, but was deleted.  re-create?
			if (!createmode) {
40002b1a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40002b1e:	75 15                	jne    40002b35 <dir_walk+0x2cd>
				errno = ENOENT;
40002b20:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40002b25:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
				return -1;
40002b2b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002b30:	e9 0a 03 00 00       	jmp    40002e3f <dir_walk+0x5d7>
			}
			files->fi[ino].ver++;	// an exclusive change
40002b35:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40002b3a:	8b 55 f0             	mov    -0x10(%ebp),%edx
40002b3d:	6b d2 5c             	imul   $0x5c,%edx,%edx
40002b40:	01 c2                	add    %eax,%edx
40002b42:	81 c2 54 10 00 00    	add    $0x1054,%edx
40002b48:	8b 12                	mov    (%edx),%edx
40002b4a:	83 c2 01             	add    $0x1,%edx
40002b4d:	8b 4d f0             	mov    -0x10(%ebp),%ecx
40002b50:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
40002b53:	01 c8                	add    %ecx,%eax
40002b55:	05 54 10 00 00       	add    $0x1054,%eax
40002b5a:	89 10                	mov    %edx,(%eax)
			files->fi[ino].mode = createmode;
40002b5c:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002b62:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002b65:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002b68:	01 d0                	add    %edx,%eax
40002b6a:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
40002b70:	8b 45 0c             	mov    0xc(%ebp),%eax
40002b73:	89 02                	mov    %eax,(%edx)
			files->fi[ino].size = 0;
40002b75:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002b7b:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002b7e:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002b81:	01 d0                	add    %edx,%eax
40002b83:	05 5c 10 00 00       	add    $0x105c,%eax
40002b88:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			return ino;
40002b8e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002b91:	e9 a9 02 00 00       	jmp    40002e3f <dir_walk+0x5d7>
		}
		if (path[len] != '/')
40002b96:	8b 55 ec             	mov    -0x14(%ebp),%edx
40002b99:	8b 45 08             	mov    0x8(%ebp),%eax
40002b9c:	01 d0                	add    %edx,%eax
40002b9e:	0f b6 00             	movzbl (%eax),%eax
40002ba1:	3c 2f                	cmp    $0x2f,%al
40002ba3:	0f 85 a1 00 00 00    	jne    40002c4a <dir_walk+0x3e2>
			continue;	// no match

		// Make sure this dirent refers to a directory
		if (!fileino_isdir(ino)) {
40002ba9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002bad:	7e 45                	jle    40002bf4 <dir_walk+0x38c>
40002baf:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40002bb6:	7f 3c                	jg     40002bf4 <dir_walk+0x38c>
40002bb8:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002bbe:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002bc1:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002bc4:	01 d0                	add    %edx,%eax
40002bc6:	05 10 10 00 00       	add    $0x1010,%eax
40002bcb:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002bcf:	84 c0                	test   %al,%al
40002bd1:	74 21                	je     40002bf4 <dir_walk+0x38c>
40002bd3:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002bd9:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002bdc:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002bdf:	01 d0                	add    %edx,%eax
40002be1:	05 58 10 00 00       	add    $0x1058,%eax
40002be6:	8b 00                	mov    (%eax),%eax
40002be8:	25 00 70 00 00       	and    $0x7000,%eax
40002bed:	3d 00 20 00 00       	cmp    $0x2000,%eax
40002bf2:	74 15                	je     40002c09 <dir_walk+0x3a1>
			errno = ENOTDIR;
40002bf4:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40002bf9:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
			return -1;
40002bff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002c04:	e9 36 02 00 00       	jmp    40002e3f <dir_walk+0x5d7>
		}

		// Skip slashes to find next component
		do { len++; } while (path[len] == '/');
40002c09:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
40002c0d:	8b 55 ec             	mov    -0x14(%ebp),%edx
40002c10:	8b 45 08             	mov    0x8(%ebp),%eax
40002c13:	01 d0                	add    %edx,%eax
40002c15:	0f b6 00             	movzbl (%eax),%eax
40002c18:	3c 2f                	cmp    $0x2f,%al
40002c1a:	74 ed                	je     40002c09 <dir_walk+0x3a1>
		if (path[len] == 0)
40002c1c:	8b 55 ec             	mov    -0x14(%ebp),%edx
40002c1f:	8b 45 08             	mov    0x8(%ebp),%eax
40002c22:	01 d0                	add    %edx,%eax
40002c24:	0f b6 00             	movzbl (%eax),%eax
40002c27:	84 c0                	test   %al,%al
40002c29:	75 08                	jne    40002c33 <dir_walk+0x3cb>
			return ino;	// matched directory at end of path
40002c2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002c2e:	e9 0c 02 00 00       	jmp    40002e3f <dir_walk+0x5d7>

		// Walk the next directory in the path
		dino = ino;
40002c33:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002c36:	89 45 f4             	mov    %eax,-0xc(%ebp)
		path += len;
40002c39:	8b 45 ec             	mov    -0x14(%ebp),%eax
40002c3c:	01 45 08             	add    %eax,0x8(%ebp)
		goto searchdir;
40002c3f:	e9 9a fc ff ff       	jmp    400028de <dir_walk+0x76>

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
		if (!fileino_alloced(ino) || files->fi[ino].dino != dino)
			continue;	// not an entry in directory 'dino'
40002c44:	90                   	nop
40002c45:	eb 04                	jmp    40002c4b <dir_walk+0x3e3>

		// Does this inode's name match our next path component?
		len = strlen(files->fi[ino].de.d_name);
		if (memcmp(path, files->fi[ino].de.d_name, len) != 0)
			continue;	// no match
40002c47:	90                   	nop
40002c48:	eb 01                	jmp    40002c4b <dir_walk+0x3e3>
			files->fi[ino].mode = createmode;
			files->fi[ino].size = 0;
			return ino;
		}
		if (path[len] != '/')
			continue;	// no match
40002c4a:	90                   	nop
	assert(fileino_isdir(dino));
	assert(fileino_isdir(files->fi[dino].dino));

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
40002c4b:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
40002c4f:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40002c56:	0f 8e b6 fd ff ff    	jle    40002a12 <dir_walk+0x1aa>
		path += len;
		goto searchdir;
	}

	// Looking for one of the special entries '.' or '..'?
	if (path[0] == '.' && (path[1] == 0 || path[1] == '/')) {
40002c5c:	8b 45 08             	mov    0x8(%ebp),%eax
40002c5f:	0f b6 00             	movzbl (%eax),%eax
40002c62:	3c 2e                	cmp    $0x2e,%al
40002c64:	75 2c                	jne    40002c92 <dir_walk+0x42a>
40002c66:	8b 45 08             	mov    0x8(%ebp),%eax
40002c69:	83 c0 01             	add    $0x1,%eax
40002c6c:	0f b6 00             	movzbl (%eax),%eax
40002c6f:	84 c0                	test   %al,%al
40002c71:	74 0d                	je     40002c80 <dir_walk+0x418>
40002c73:	8b 45 08             	mov    0x8(%ebp),%eax
40002c76:	83 c0 01             	add    $0x1,%eax
40002c79:	0f b6 00             	movzbl (%eax),%eax
40002c7c:	3c 2f                	cmp    $0x2f,%al
40002c7e:	75 12                	jne    40002c92 <dir_walk+0x42a>
		len = 1;
40002c80:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		ino = dino;	// just leads to this same directory
40002c87:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002c8a:	89 45 f0             	mov    %eax,-0x10(%ebp)
		goto found;
40002c8d:	e9 2a fe ff ff       	jmp    40002abc <dir_walk+0x254>
	}
	if (path[0] == '.' && path[1] == '.'
40002c92:	8b 45 08             	mov    0x8(%ebp),%eax
40002c95:	0f b6 00             	movzbl (%eax),%eax
40002c98:	3c 2e                	cmp    $0x2e,%al
40002c9a:	75 4b                	jne    40002ce7 <dir_walk+0x47f>
40002c9c:	8b 45 08             	mov    0x8(%ebp),%eax
40002c9f:	83 c0 01             	add    $0x1,%eax
40002ca2:	0f b6 00             	movzbl (%eax),%eax
40002ca5:	3c 2e                	cmp    $0x2e,%al
40002ca7:	75 3e                	jne    40002ce7 <dir_walk+0x47f>
			&& (path[2] == 0 || path[2] == '/')) {
40002ca9:	8b 45 08             	mov    0x8(%ebp),%eax
40002cac:	83 c0 02             	add    $0x2,%eax
40002caf:	0f b6 00             	movzbl (%eax),%eax
40002cb2:	84 c0                	test   %al,%al
40002cb4:	74 0d                	je     40002cc3 <dir_walk+0x45b>
40002cb6:	8b 45 08             	mov    0x8(%ebp),%eax
40002cb9:	83 c0 02             	add    $0x2,%eax
40002cbc:	0f b6 00             	movzbl (%eax),%eax
40002cbf:	3c 2f                	cmp    $0x2f,%al
40002cc1:	75 24                	jne    40002ce7 <dir_walk+0x47f>
		len = 2;
40002cc3:	c7 45 ec 02 00 00 00 	movl   $0x2,-0x14(%ebp)
		ino = files->fi[dino].dino;	// leads to root directory
40002cca:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002cd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002cd3:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002cd6:	01 d0                	add    %edx,%eax
40002cd8:	05 10 10 00 00       	add    $0x1010,%eax
40002cdd:	8b 00                	mov    (%eax),%eax
40002cdf:	89 45 f0             	mov    %eax,-0x10(%ebp)
		goto found;
40002ce2:	e9 d5 fd ff ff       	jmp    40002abc <dir_walk+0x254>
	}

	// Path component not found - see if we should create it
	if (!createmode || strchr(path, '/') != NULL) {
40002ce7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40002ceb:	74 17                	je     40002d04 <dir_walk+0x49c>
40002ced:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
40002cf4:	00 
40002cf5:	8b 45 08             	mov    0x8(%ebp),%eax
40002cf8:	89 04 24             	mov    %eax,(%esp)
40002cfb:	e8 3d e8 ff ff       	call   4000153d <strchr>
40002d00:	85 c0                	test   %eax,%eax
40002d02:	74 15                	je     40002d19 <dir_walk+0x4b1>
		errno = ENOENT;
40002d04:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40002d09:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
		return -1;
40002d0f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002d14:	e9 26 01 00 00       	jmp    40002e3f <dir_walk+0x5d7>
	}
	if (strlen(path) > NAME_MAX) {
40002d19:	8b 45 08             	mov    0x8(%ebp),%eax
40002d1c:	89 04 24             	mov    %eax,(%esp)
40002d1f:	e8 94 e6 ff ff       	call   400013b8 <strlen>
40002d24:	83 f8 3f             	cmp    $0x3f,%eax
40002d27:	7e 15                	jle    40002d3e <dir_walk+0x4d6>
		errno = ENAMETOOLONG;
40002d29:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40002d2e:	c7 00 06 00 00 00    	movl   $0x6,(%eax)
		return -1;
40002d34:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002d39:	e9 01 01 00 00       	jmp    40002e3f <dir_walk+0x5d7>
	}

	// Allocate a new inode and create this entry with the given mode.
	ino = fileino_alloc();
40002d3e:	e8 31 ea ff ff       	call   40001774 <fileino_alloc>
40002d43:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (ino < 0)
40002d46:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002d4a:	79 0a                	jns    40002d56 <dir_walk+0x4ee>
		return -1;
40002d4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002d51:	e9 e9 00 00 00       	jmp    40002e3f <dir_walk+0x5d7>
	assert(fileino_isvalid(ino) && !fileino_alloced(ino));
40002d56:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002d5a:	7e 33                	jle    40002d8f <dir_walk+0x527>
40002d5c:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40002d63:	7f 2a                	jg     40002d8f <dir_walk+0x527>
40002d65:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002d69:	7e 48                	jle    40002db3 <dir_walk+0x54b>
40002d6b:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40002d72:	7f 3f                	jg     40002db3 <dir_walk+0x54b>
40002d74:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002d7a:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002d7d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002d80:	01 d0                	add    %edx,%eax
40002d82:	05 10 10 00 00       	add    $0x1010,%eax
40002d87:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002d8b:	84 c0                	test   %al,%al
40002d8d:	74 24                	je     40002db3 <dir_walk+0x54b>
40002d8f:	c7 44 24 0c 28 60 00 	movl   $0x40006028,0xc(%esp)
40002d96:	40 
40002d97:	c7 44 24 08 d0 5f 00 	movl   $0x40005fd0,0x8(%esp)
40002d9e:	40 
40002d9f:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
40002da6:	00 
40002da7:	c7 04 24 e5 5f 00 40 	movl   $0x40005fe5,(%esp)
40002dae:	e8 91 dc ff ff       	call   40000a44 <debug_panic>
	strcpy(files->fi[ino].de.d_name, path);
40002db3:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40002db8:	8b 55 f0             	mov    -0x10(%ebp),%edx
40002dbb:	6b d2 5c             	imul   $0x5c,%edx,%edx
40002dbe:	81 c2 10 10 00 00    	add    $0x1010,%edx
40002dc4:	01 d0                	add    %edx,%eax
40002dc6:	8d 50 04             	lea    0x4(%eax),%edx
40002dc9:	8b 45 08             	mov    0x8(%ebp),%eax
40002dcc:	89 44 24 04          	mov    %eax,0x4(%esp)
40002dd0:	89 14 24             	mov    %edx,(%esp)
40002dd3:	e8 06 e6 ff ff       	call   400013de <strcpy>
	files->fi[ino].dino = dino;
40002dd8:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002dde:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002de1:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002de4:	01 d0                	add    %edx,%eax
40002de6:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40002dec:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002def:	89 02                	mov    %eax,(%edx)
	files->fi[ino].ver = 0;
40002df1:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002df7:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002dfa:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002dfd:	01 d0                	add    %edx,%eax
40002dff:	05 54 10 00 00       	add    $0x1054,%eax
40002e04:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	files->fi[ino].mode = createmode;
40002e0a:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002e10:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002e13:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002e16:	01 d0                	add    %edx,%eax
40002e18:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
40002e1e:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e21:	89 02                	mov    %eax,(%edx)
	files->fi[ino].size = 0;
40002e23:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002e29:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002e2c:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002e2f:	01 d0                	add    %edx,%eax
40002e31:	05 5c 10 00 00       	add    $0x105c,%eax
40002e36:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return ino;
40002e3c:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40002e3f:	c9                   	leave  
40002e40:	c3                   	ret    

40002e41 <opendir>:
// Open a directory for scanning.
// For simplicity, DIR is simply a filedesc like other file descriptors,
// except we interpret fd->ofs as an inode number for scanning,
// instead of as a byte offset as in a regular file.
DIR *opendir(const char *path)
{
40002e41:	55                   	push   %ebp
40002e42:	89 e5                	mov    %esp,%ebp
40002e44:	83 ec 28             	sub    $0x28,%esp
	filedesc *fd = filedesc_open(NULL, path, O_RDONLY, 0);
40002e47:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
40002e4e:	00 
40002e4f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40002e56:	00 
40002e57:	8b 45 08             	mov    0x8(%ebp),%eax
40002e5a:	89 44 24 04          	mov    %eax,0x4(%esp)
40002e5e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002e65:	e8 a5 f3 ff ff       	call   4000220f <filedesc_open>
40002e6a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (fd == NULL)
40002e6d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002e71:	75 0a                	jne    40002e7d <opendir+0x3c>
		return NULL;
40002e73:	b8 00 00 00 00       	mov    $0x0,%eax
40002e78:	e9 bb 00 00 00       	jmp    40002f38 <opendir+0xf7>

	// Make sure it's a directory
	assert(fileino_exists(fd->ino));
40002e7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002e80:	8b 00                	mov    (%eax),%eax
40002e82:	85 c0                	test   %eax,%eax
40002e84:	7e 44                	jle    40002eca <opendir+0x89>
40002e86:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002e89:	8b 00                	mov    (%eax),%eax
40002e8b:	3d ff 00 00 00       	cmp    $0xff,%eax
40002e90:	7f 38                	jg     40002eca <opendir+0x89>
40002e92:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002e98:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002e9b:	8b 00                	mov    (%eax),%eax
40002e9d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002ea0:	01 d0                	add    %edx,%eax
40002ea2:	05 10 10 00 00       	add    $0x1010,%eax
40002ea7:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002eab:	84 c0                	test   %al,%al
40002ead:	74 1b                	je     40002eca <opendir+0x89>
40002eaf:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002eb5:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002eb8:	8b 00                	mov    (%eax),%eax
40002eba:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002ebd:	01 d0                	add    %edx,%eax
40002ebf:	05 58 10 00 00       	add    $0x1058,%eax
40002ec4:	8b 00                	mov    (%eax),%eax
40002ec6:	85 c0                	test   %eax,%eax
40002ec8:	75 24                	jne    40002eee <opendir+0xad>
40002eca:	c7 44 24 0c 56 60 00 	movl   $0x40006056,0xc(%esp)
40002ed1:	40 
40002ed2:	c7 44 24 08 d0 5f 00 	movl   $0x40005fd0,0x8(%esp)
40002ed9:	40 
40002eda:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
40002ee1:	00 
40002ee2:	c7 04 24 e5 5f 00 40 	movl   $0x40005fe5,(%esp)
40002ee9:	e8 56 db ff ff       	call   40000a44 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40002eee:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002ef4:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002ef7:	8b 00                	mov    (%eax),%eax
40002ef9:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002efc:	05 10 10 00 00       	add    $0x1010,%eax
40002f01:	01 d0                	add    %edx,%eax
40002f03:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (!S_ISDIR(fi->mode)) {
40002f06:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002f09:	8b 40 48             	mov    0x48(%eax),%eax
40002f0c:	25 00 70 00 00       	and    $0x7000,%eax
40002f11:	3d 00 20 00 00       	cmp    $0x2000,%eax
40002f16:	74 1d                	je     40002f35 <opendir+0xf4>
		filedesc_close(fd);
40002f18:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002f1b:	89 04 24             	mov    %eax,(%esp)
40002f1e:	e8 b1 f8 ff ff       	call   400027d4 <filedesc_close>
		errno = ENOTDIR;
40002f23:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40002f28:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
		return NULL;
40002f2e:	b8 00 00 00 00       	mov    $0x0,%eax
40002f33:	eb 03                	jmp    40002f38 <opendir+0xf7>
	}

	return fd;
40002f35:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
40002f38:	c9                   	leave  
40002f39:	c3                   	ret    

40002f3a <closedir>:

int closedir(DIR *dir)
{
40002f3a:	55                   	push   %ebp
40002f3b:	89 e5                	mov    %esp,%ebp
40002f3d:	83 ec 18             	sub    $0x18,%esp
	filedesc_close(dir);
40002f40:	8b 45 08             	mov    0x8(%ebp),%eax
40002f43:	89 04 24             	mov    %eax,(%esp)
40002f46:	e8 89 f8 ff ff       	call   400027d4 <filedesc_close>
	return 0;
40002f4b:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002f50:	c9                   	leave  
40002f51:	c3                   	ret    

40002f52 <readdir>:

// Scan an open directory filedesc and return the next entry.
// Returns a pointer to the next matching file inode's 'dirent' struct,
// or NULL if the directory being scanned contains no more entries.
struct dirent *readdir(DIR *dir)
{
40002f52:	55                   	push   %ebp
40002f53:	89 e5                	mov    %esp,%ebp
40002f55:	83 ec 28             	sub    $0x28,%esp
	// Hint: a fileinode's 'dino' field indicates
	// what directory the file is in;
	// this function shouldn't return entries from other directories!
	//warn("readdir() not implemented");
	//return NULL;
	assert(fileino_isdir(dir->ino));
40002f58:	8b 45 08             	mov    0x8(%ebp),%eax
40002f5b:	8b 00                	mov    (%eax),%eax
40002f5d:	85 c0                	test   %eax,%eax
40002f5f:	7e 4c                	jle    40002fad <readdir+0x5b>
40002f61:	8b 45 08             	mov    0x8(%ebp),%eax
40002f64:	8b 00                	mov    (%eax),%eax
40002f66:	3d ff 00 00 00       	cmp    $0xff,%eax
40002f6b:	7f 40                	jg     40002fad <readdir+0x5b>
40002f6d:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002f73:	8b 45 08             	mov    0x8(%ebp),%eax
40002f76:	8b 00                	mov    (%eax),%eax
40002f78:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002f7b:	01 d0                	add    %edx,%eax
40002f7d:	05 10 10 00 00       	add    $0x1010,%eax
40002f82:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002f86:	84 c0                	test   %al,%al
40002f88:	74 23                	je     40002fad <readdir+0x5b>
40002f8a:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40002f90:	8b 45 08             	mov    0x8(%ebp),%eax
40002f93:	8b 00                	mov    (%eax),%eax
40002f95:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002f98:	01 d0                	add    %edx,%eax
40002f9a:	05 58 10 00 00       	add    $0x1058,%eax
40002f9f:	8b 00                	mov    (%eax),%eax
40002fa1:	25 00 70 00 00       	and    $0x7000,%eax
40002fa6:	3d 00 20 00 00       	cmp    $0x2000,%eax
40002fab:	74 24                	je     40002fd1 <readdir+0x7f>
40002fad:	c7 44 24 0c 6e 60 00 	movl   $0x4000606e,0xc(%esp)
40002fb4:	40 
40002fb5:	c7 44 24 08 d0 5f 00 	movl   $0x40005fd0,0x8(%esp)
40002fbc:	40 
40002fbd:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
40002fc4:	00 
40002fc5:	c7 04 24 e5 5f 00 40 	movl   $0x40005fe5,(%esp)
40002fcc:	e8 73 da ff ff       	call   40000a44 <debug_panic>
	int i = dir->ofs;
40002fd1:	8b 45 08             	mov    0x8(%ebp),%eax
40002fd4:	8b 40 08             	mov    0x8(%eax),%eax
40002fd7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	for(i; i < FILE_INODES; i++){
40002fda:	eb 3c                	jmp    40003018 <readdir+0xc6>
		fileinode* tmp_fi = &files->fi[i];
40002fdc:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40002fe1:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002fe4:	6b d2 5c             	imul   $0x5c,%edx,%edx
40002fe7:	81 c2 10 10 00 00    	add    $0x1010,%edx
40002fed:	01 d0                	add    %edx,%eax
40002fef:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if(tmp_fi->dino == dir->ino){
40002ff2:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002ff5:	8b 10                	mov    (%eax),%edx
40002ff7:	8b 45 08             	mov    0x8(%ebp),%eax
40002ffa:	8b 00                	mov    (%eax),%eax
40002ffc:	39 c2                	cmp    %eax,%edx
40002ffe:	75 14                	jne    40003014 <readdir+0xc2>
			dir->ofs = i+1;
40003000:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003003:	8d 50 01             	lea    0x1(%eax),%edx
40003006:	8b 45 08             	mov    0x8(%ebp),%eax
40003009:	89 50 08             	mov    %edx,0x8(%eax)
			return &tmp_fi->de;
4000300c:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000300f:	83 c0 04             	add    $0x4,%eax
40003012:	eb 1c                	jmp    40003030 <readdir+0xde>
	// this function shouldn't return entries from other directories!
	//warn("readdir() not implemented");
	//return NULL;
	assert(fileino_isdir(dir->ino));
	int i = dir->ofs;
	for(i; i < FILE_INODES; i++){
40003014:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40003018:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
4000301f:	7e bb                	jle    40002fdc <readdir+0x8a>
		if(tmp_fi->dino == dir->ino){
			dir->ofs = i+1;
			return &tmp_fi->de;
		}
	}
	dir->ofs = 0;
40003021:	8b 45 08             	mov    0x8(%ebp),%eax
40003024:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
	return NULL;
4000302b:	b8 00 00 00 00       	mov    $0x0,%eax
}
40003030:	c9                   	leave  
40003031:	c3                   	ret    

40003032 <rewinddir>:

void rewinddir(DIR *dir)
{
40003032:	55                   	push   %ebp
40003033:	89 e5                	mov    %esp,%ebp
	dir->ofs = 0;
40003035:	8b 45 08             	mov    0x8(%ebp),%eax
40003038:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
4000303f:	5d                   	pop    %ebp
40003040:	c3                   	ret    

40003041 <seekdir>:

void seekdir(DIR *dir, long ofs)
{
40003041:	55                   	push   %ebp
40003042:	89 e5                	mov    %esp,%ebp
	dir->ofs = ofs;
40003044:	8b 45 08             	mov    0x8(%ebp),%eax
40003047:	8b 55 0c             	mov    0xc(%ebp),%edx
4000304a:	89 50 08             	mov    %edx,0x8(%eax)
}
4000304d:	5d                   	pop    %ebp
4000304e:	c3                   	ret    

4000304f <telldir>:

long telldir(DIR *dir)
{
4000304f:	55                   	push   %ebp
40003050:	89 e5                	mov    %esp,%ebp
	return dir->ofs;
40003052:	8b 45 08             	mov    0x8(%ebp),%eax
40003055:	8b 40 08             	mov    0x8(%eax),%eax
}
40003058:	5d                   	pop    %ebp
40003059:	c3                   	ret    
4000305a:	66 90                	xchg   %ax,%ax

4000305c <fopen>:
FILE *const stdout = &FILES->fd[1];
FILE *const stderr = &FILES->fd[2];

FILE *
fopen(const char *path, const char *mode)
{
4000305c:	55                   	push   %ebp
4000305d:	89 e5                	mov    %esp,%ebp
4000305f:	83 ec 28             	sub    $0x28,%esp
	// Find an unused file descriptor and use it for the open
	FILE *fd = filedesc_alloc();
40003062:	e8 52 f1 ff ff       	call   400021b9 <filedesc_alloc>
40003067:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (fd == NULL)
4000306a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
4000306e:	75 07                	jne    40003077 <fopen+0x1b>
		return NULL;
40003070:	b8 00 00 00 00       	mov    $0x0,%eax
40003075:	eb 19                	jmp    40003090 <fopen+0x34>

	return freopen(path, mode, fd);
40003077:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000307a:	89 44 24 08          	mov    %eax,0x8(%esp)
4000307e:	8b 45 0c             	mov    0xc(%ebp),%eax
40003081:	89 44 24 04          	mov    %eax,0x4(%esp)
40003085:	8b 45 08             	mov    0x8(%ebp),%eax
40003088:	89 04 24             	mov    %eax,(%esp)
4000308b:	e8 02 00 00 00       	call   40003092 <freopen>
}
40003090:	c9                   	leave  
40003091:	c3                   	ret    

40003092 <freopen>:

FILE *
freopen(const char *path, const char *mode, FILE *fd)
{
40003092:	55                   	push   %ebp
40003093:	89 e5                	mov    %esp,%ebp
40003095:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isvalid(fd));
40003098:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
4000309d:	83 c0 10             	add    $0x10,%eax
400030a0:	3b 45 10             	cmp    0x10(%ebp),%eax
400030a3:	77 0f                	ja     400030b4 <freopen+0x22>
400030a5:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400030aa:	05 10 10 00 00       	add    $0x1010,%eax
400030af:	3b 45 10             	cmp    0x10(%ebp),%eax
400030b2:	77 24                	ja     400030d8 <freopen+0x46>
400030b4:	c7 44 24 0c 94 60 00 	movl   $0x40006094,0xc(%esp)
400030bb:	40 
400030bc:	c7 44 24 08 a9 60 00 	movl   $0x400060a9,0x8(%esp)
400030c3:	40 
400030c4:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
400030cb:	00 
400030cc:	c7 04 24 be 60 00 40 	movl   $0x400060be,(%esp)
400030d3:	e8 6c d9 ff ff       	call   40000a44 <debug_panic>
	if (filedesc_isopen(fd))
400030d8:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400030dd:	83 c0 10             	add    $0x10,%eax
400030e0:	3b 45 10             	cmp    0x10(%ebp),%eax
400030e3:	77 23                	ja     40003108 <freopen+0x76>
400030e5:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400030ea:	05 10 10 00 00       	add    $0x1010,%eax
400030ef:	3b 45 10             	cmp    0x10(%ebp),%eax
400030f2:	76 14                	jbe    40003108 <freopen+0x76>
400030f4:	8b 45 10             	mov    0x10(%ebp),%eax
400030f7:	8b 00                	mov    (%eax),%eax
400030f9:	85 c0                	test   %eax,%eax
400030fb:	74 0b                	je     40003108 <freopen+0x76>
		fclose(fd);
400030fd:	8b 45 10             	mov    0x10(%ebp),%eax
40003100:	89 04 24             	mov    %eax,(%esp)
40003103:	e8 b4 00 00 00       	call   400031bc <fclose>

	// Parse the open mode string
	int flags;
	switch (*mode++) {
40003108:	8b 45 0c             	mov    0xc(%ebp),%eax
4000310b:	0f b6 00             	movzbl (%eax),%eax
4000310e:	0f be c0             	movsbl %al,%eax
40003111:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
40003115:	83 f8 72             	cmp    $0x72,%eax
40003118:	74 0c                	je     40003126 <freopen+0x94>
4000311a:	83 f8 77             	cmp    $0x77,%eax
4000311d:	74 10                	je     4000312f <freopen+0x9d>
4000311f:	83 f8 61             	cmp    $0x61,%eax
40003122:	74 14                	je     40003138 <freopen+0xa6>
40003124:	eb 1b                	jmp    40003141 <freopen+0xaf>
	case 'r':	flags = O_RDONLY; break;
40003126:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
4000312d:	eb 3f                	jmp    4000316e <freopen+0xdc>
	case 'w':	flags = O_WRONLY | O_CREAT | O_TRUNC; break;
4000312f:	c7 45 f4 62 00 00 00 	movl   $0x62,-0xc(%ebp)
40003136:	eb 36                	jmp    4000316e <freopen+0xdc>
	case 'a':	flags = O_WRONLY | O_CREAT | O_APPEND; break;
40003138:	c7 45 f4 32 00 00 00 	movl   $0x32,-0xc(%ebp)
4000313f:	eb 2d                	jmp    4000316e <freopen+0xdc>
	default:	panic("freopen: unknown file mode '%c'\n", *--mode);
40003141:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
40003145:	8b 45 0c             	mov    0xc(%ebp),%eax
40003148:	0f b6 00             	movzbl (%eax),%eax
4000314b:	0f be c0             	movsbl %al,%eax
4000314e:	89 44 24 0c          	mov    %eax,0xc(%esp)
40003152:	c7 44 24 08 cc 60 00 	movl   $0x400060cc,0x8(%esp)
40003159:	40 
4000315a:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
40003161:	00 
40003162:	c7 04 24 be 60 00 40 	movl   $0x400060be,(%esp)
40003169:	e8 d6 d8 ff ff       	call   40000a44 <debug_panic>
	}
	if (*mode == 'b')	// binary flag - compatibility only
4000316e:	8b 45 0c             	mov    0xc(%ebp),%eax
40003171:	0f b6 00             	movzbl (%eax),%eax
40003174:	3c 62                	cmp    $0x62,%al
40003176:	75 04                	jne    4000317c <freopen+0xea>
		mode++;
40003178:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	if (*mode == '+')
4000317c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000317f:	0f b6 00             	movzbl (%eax),%eax
40003182:	3c 2b                	cmp    $0x2b,%al
40003184:	75 04                	jne    4000318a <freopen+0xf8>
		flags |= O_RDWR;
40003186:	83 4d f4 03          	orl    $0x3,-0xc(%ebp)

	if (filedesc_open(fd, path, flags, 0666) != fd)
4000318a:	c7 44 24 0c b6 01 00 	movl   $0x1b6,0xc(%esp)
40003191:	00 
40003192:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003195:	89 44 24 08          	mov    %eax,0x8(%esp)
40003199:	8b 45 08             	mov    0x8(%ebp),%eax
4000319c:	89 44 24 04          	mov    %eax,0x4(%esp)
400031a0:	8b 45 10             	mov    0x10(%ebp),%eax
400031a3:	89 04 24             	mov    %eax,(%esp)
400031a6:	e8 64 f0 ff ff       	call   4000220f <filedesc_open>
400031ab:	3b 45 10             	cmp    0x10(%ebp),%eax
400031ae:	74 07                	je     400031b7 <freopen+0x125>
		return NULL;
400031b0:	b8 00 00 00 00       	mov    $0x0,%eax
400031b5:	eb 03                	jmp    400031ba <freopen+0x128>
	return fd;
400031b7:	8b 45 10             	mov    0x10(%ebp),%eax
}
400031ba:	c9                   	leave  
400031bb:	c3                   	ret    

400031bc <fclose>:

int
fclose(FILE *fd)
{
400031bc:	55                   	push   %ebp
400031bd:	89 e5                	mov    %esp,%ebp
400031bf:	83 ec 18             	sub    $0x18,%esp
	filedesc_close(fd);
400031c2:	8b 45 08             	mov    0x8(%ebp),%eax
400031c5:	89 04 24             	mov    %eax,(%esp)
400031c8:	e8 07 f6 ff ff       	call   400027d4 <filedesc_close>
	return 0;
400031cd:	b8 00 00 00 00       	mov    $0x0,%eax
}
400031d2:	c9                   	leave  
400031d3:	c3                   	ret    

400031d4 <fgetc>:

int
fgetc(FILE *fd)
{
400031d4:	55                   	push   %ebp
400031d5:	89 e5                	mov    %esp,%ebp
400031d7:	83 ec 28             	sub    $0x28,%esp
	unsigned char ch;
	if (filedesc_read(fd, &ch, 1, 1) < 1)
400031da:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
400031e1:	00 
400031e2:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
400031e9:	00 
400031ea:	8d 45 f7             	lea    -0x9(%ebp),%eax
400031ed:	89 44 24 04          	mov    %eax,0x4(%esp)
400031f1:	8b 45 08             	mov    0x8(%ebp),%eax
400031f4:	89 04 24             	mov    %eax,(%esp)
400031f7:	e8 3d f2 ff ff       	call   40002439 <filedesc_read>
400031fc:	85 c0                	test   %eax,%eax
400031fe:	7f 07                	jg     40003207 <fgetc+0x33>
		return EOF;
40003200:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40003205:	eb 07                	jmp    4000320e <fgetc+0x3a>
	return ch;
40003207:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
4000320b:	0f b6 c0             	movzbl %al,%eax
}
4000320e:	c9                   	leave  
4000320f:	c3                   	ret    

40003210 <fputc>:

int
fputc(int c, FILE *fd)
{
40003210:	55                   	push   %ebp
40003211:	89 e5                	mov    %esp,%ebp
40003213:	83 ec 28             	sub    $0x28,%esp
	unsigned char ch = c;
40003216:	8b 45 08             	mov    0x8(%ebp),%eax
40003219:	88 45 f7             	mov    %al,-0x9(%ebp)
	if (filedesc_write(fd, &ch, 1, 1) < 1)
4000321c:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
40003223:	00 
40003224:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
4000322b:	00 
4000322c:	8d 45 f7             	lea    -0x9(%ebp),%eax
4000322f:	89 44 24 04          	mov    %eax,0x4(%esp)
40003233:	8b 45 0c             	mov    0xc(%ebp),%eax
40003236:	89 04 24             	mov    %eax,(%esp)
40003239:	e8 10 f3 ff ff       	call   4000254e <filedesc_write>
4000323e:	85 c0                	test   %eax,%eax
40003240:	7f 07                	jg     40003249 <fputc+0x39>
		return EOF;
40003242:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40003247:	eb 07                	jmp    40003250 <fputc+0x40>
	return ch;
40003249:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
4000324d:	0f b6 c0             	movzbl %al,%eax
}
40003250:	c9                   	leave  
40003251:	c3                   	ret    

40003252 <fread>:

size_t
fread(void *buf, size_t eltsize, size_t count, FILE *fd)
{
40003252:	55                   	push   %ebp
40003253:	89 e5                	mov    %esp,%ebp
40003255:	83 ec 28             	sub    $0x28,%esp
	ssize_t actual = filedesc_read(fd, buf, eltsize, count);
40003258:	8b 45 10             	mov    0x10(%ebp),%eax
4000325b:	89 44 24 0c          	mov    %eax,0xc(%esp)
4000325f:	8b 45 0c             	mov    0xc(%ebp),%eax
40003262:	89 44 24 08          	mov    %eax,0x8(%esp)
40003266:	8b 45 08             	mov    0x8(%ebp),%eax
40003269:	89 44 24 04          	mov    %eax,0x4(%esp)
4000326d:	8b 45 14             	mov    0x14(%ebp),%eax
40003270:	89 04 24             	mov    %eax,(%esp)
40003273:	e8 c1 f1 ff ff       	call   40002439 <filedesc_read>
40003278:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return actual >= 0 ? actual : 0;	// no error indication
4000327b:	b8 00 00 00 00       	mov    $0x0,%eax
40003280:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40003284:	0f 49 45 f4          	cmovns -0xc(%ebp),%eax
}
40003288:	c9                   	leave  
40003289:	c3                   	ret    

4000328a <fwrite>:

size_t
fwrite(const void *buf, size_t eltsize, size_t count, FILE *fd)
{
4000328a:	55                   	push   %ebp
4000328b:	89 e5                	mov    %esp,%ebp
4000328d:	83 ec 28             	sub    $0x28,%esp
	ssize_t actual = filedesc_write(fd, buf, eltsize, count);
40003290:	8b 45 10             	mov    0x10(%ebp),%eax
40003293:	89 44 24 0c          	mov    %eax,0xc(%esp)
40003297:	8b 45 0c             	mov    0xc(%ebp),%eax
4000329a:	89 44 24 08          	mov    %eax,0x8(%esp)
4000329e:	8b 45 08             	mov    0x8(%ebp),%eax
400032a1:	89 44 24 04          	mov    %eax,0x4(%esp)
400032a5:	8b 45 14             	mov    0x14(%ebp),%eax
400032a8:	89 04 24             	mov    %eax,(%esp)
400032ab:	e8 9e f2 ff ff       	call   4000254e <filedesc_write>
400032b0:	89 45 f4             	mov    %eax,-0xc(%ebp)

		
	return actual >= 0 ? actual : 0;	// no error indication
400032b3:	b8 00 00 00 00       	mov    $0x0,%eax
400032b8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
400032bc:	0f 49 45 f4          	cmovns -0xc(%ebp),%eax
}
400032c0:	c9                   	leave  
400032c1:	c3                   	ret    

400032c2 <fseek>:

int
fseek(FILE *fd, off_t offset, int whence)
{
400032c2:	55                   	push   %ebp
400032c3:	89 e5                	mov    %esp,%ebp
400032c5:	83 ec 18             	sub    $0x18,%esp
	if (filedesc_seek(fd, offset, whence) < 0)
400032c8:	8b 45 10             	mov    0x10(%ebp),%eax
400032cb:	89 44 24 08          	mov    %eax,0x8(%esp)
400032cf:	8b 45 0c             	mov    0xc(%ebp),%eax
400032d2:	89 44 24 04          	mov    %eax,0x4(%esp)
400032d6:	8b 45 08             	mov    0x8(%ebp),%eax
400032d9:	89 04 24             	mov    %eax,(%esp)
400032dc:	e8 e2 f3 ff ff       	call   400026c3 <filedesc_seek>
400032e1:	85 c0                	test   %eax,%eax
400032e3:	79 07                	jns    400032ec <fseek+0x2a>
		return -1;
400032e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400032ea:	eb 05                	jmp    400032f1 <fseek+0x2f>
	return 0;	// fseek() returns 0 on success, not the new position
400032ec:	b8 00 00 00 00       	mov    $0x0,%eax
}
400032f1:	c9                   	leave  
400032f2:	c3                   	ret    

400032f3 <ftell>:

long
ftell(FILE *fd)
{
400032f3:	55                   	push   %ebp
400032f4:	89 e5                	mov    %esp,%ebp
400032f6:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
400032f9:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400032fe:	83 c0 10             	add    $0x10,%eax
40003301:	3b 45 08             	cmp    0x8(%ebp),%eax
40003304:	77 18                	ja     4000331e <ftell+0x2b>
40003306:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
4000330b:	05 10 10 00 00       	add    $0x1010,%eax
40003310:	3b 45 08             	cmp    0x8(%ebp),%eax
40003313:	76 09                	jbe    4000331e <ftell+0x2b>
40003315:	8b 45 08             	mov    0x8(%ebp),%eax
40003318:	8b 00                	mov    (%eax),%eax
4000331a:	85 c0                	test   %eax,%eax
4000331c:	75 24                	jne    40003342 <ftell+0x4f>
4000331e:	c7 44 24 0c ed 60 00 	movl   $0x400060ed,0xc(%esp)
40003325:	40 
40003326:	c7 44 24 08 a9 60 00 	movl   $0x400060a9,0x8(%esp)
4000332d:	40 
4000332e:	c7 44 24 04 7a 00 00 	movl   $0x7a,0x4(%esp)
40003335:	00 
40003336:	c7 04 24 be 60 00 40 	movl   $0x400060be,(%esp)
4000333d:	e8 02 d7 ff ff       	call   40000a44 <debug_panic>
	return fd->ofs;
40003342:	8b 45 08             	mov    0x8(%ebp),%eax
40003345:	8b 40 08             	mov    0x8(%eax),%eax
}
40003348:	c9                   	leave  
40003349:	c3                   	ret    

4000334a <feof>:

int
feof(FILE *fd)
{
4000334a:	55                   	push   %ebp
4000334b:	89 e5                	mov    %esp,%ebp
4000334d:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isopen(fd));
40003350:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003355:	83 c0 10             	add    $0x10,%eax
40003358:	3b 45 08             	cmp    0x8(%ebp),%eax
4000335b:	77 18                	ja     40003375 <feof+0x2b>
4000335d:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003362:	05 10 10 00 00       	add    $0x1010,%eax
40003367:	3b 45 08             	cmp    0x8(%ebp),%eax
4000336a:	76 09                	jbe    40003375 <feof+0x2b>
4000336c:	8b 45 08             	mov    0x8(%ebp),%eax
4000336f:	8b 00                	mov    (%eax),%eax
40003371:	85 c0                	test   %eax,%eax
40003373:	75 24                	jne    40003399 <feof+0x4f>
40003375:	c7 44 24 0c ed 60 00 	movl   $0x400060ed,0xc(%esp)
4000337c:	40 
4000337d:	c7 44 24 08 a9 60 00 	movl   $0x400060a9,0x8(%esp)
40003384:	40 
40003385:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
4000338c:	00 
4000338d:	c7 04 24 be 60 00 40 	movl   $0x400060be,(%esp)
40003394:	e8 ab d6 ff ff       	call   40000a44 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40003399:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
4000339f:	8b 45 08             	mov    0x8(%ebp),%eax
400033a2:	8b 00                	mov    (%eax),%eax
400033a4:	6b c0 5c             	imul   $0x5c,%eax,%eax
400033a7:	05 10 10 00 00       	add    $0x1010,%eax
400033ac:	01 d0                	add    %edx,%eax
400033ae:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return fd->ofs >= fi->size && !(fi->mode & S_IFPART);
400033b1:	8b 45 08             	mov    0x8(%ebp),%eax
400033b4:	8b 40 08             	mov    0x8(%eax),%eax
400033b7:	89 c2                	mov    %eax,%edx
400033b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
400033bc:	8b 40 4c             	mov    0x4c(%eax),%eax
400033bf:	39 c2                	cmp    %eax,%edx
400033c1:	72 16                	jb     400033d9 <feof+0x8f>
400033c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
400033c6:	8b 40 48             	mov    0x48(%eax),%eax
400033c9:	25 00 80 00 00       	and    $0x8000,%eax
400033ce:	85 c0                	test   %eax,%eax
400033d0:	75 07                	jne    400033d9 <feof+0x8f>
400033d2:	b8 01 00 00 00       	mov    $0x1,%eax
400033d7:	eb 05                	jmp    400033de <feof+0x94>
400033d9:	b8 00 00 00 00       	mov    $0x0,%eax
}
400033de:	c9                   	leave  
400033df:	c3                   	ret    

400033e0 <ferror>:

int
ferror(FILE *fd)
{
400033e0:	55                   	push   %ebp
400033e1:	89 e5                	mov    %esp,%ebp
400033e3:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
400033e6:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400033eb:	83 c0 10             	add    $0x10,%eax
400033ee:	3b 45 08             	cmp    0x8(%ebp),%eax
400033f1:	77 18                	ja     4000340b <ferror+0x2b>
400033f3:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400033f8:	05 10 10 00 00       	add    $0x1010,%eax
400033fd:	3b 45 08             	cmp    0x8(%ebp),%eax
40003400:	76 09                	jbe    4000340b <ferror+0x2b>
40003402:	8b 45 08             	mov    0x8(%ebp),%eax
40003405:	8b 00                	mov    (%eax),%eax
40003407:	85 c0                	test   %eax,%eax
40003409:	75 24                	jne    4000342f <ferror+0x4f>
4000340b:	c7 44 24 0c ed 60 00 	movl   $0x400060ed,0xc(%esp)
40003412:	40 
40003413:	c7 44 24 08 a9 60 00 	movl   $0x400060a9,0x8(%esp)
4000341a:	40 
4000341b:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
40003422:	00 
40003423:	c7 04 24 be 60 00 40 	movl   $0x400060be,(%esp)
4000342a:	e8 15 d6 ff ff       	call   40000a44 <debug_panic>
	return fd->err;
4000342f:	8b 45 08             	mov    0x8(%ebp),%eax
40003432:	8b 40 0c             	mov    0xc(%eax),%eax
}
40003435:	c9                   	leave  
40003436:	c3                   	ret    

40003437 <clearerr>:

void
clearerr(FILE *fd)
{
40003437:	55                   	push   %ebp
40003438:	89 e5                	mov    %esp,%ebp
4000343a:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
4000343d:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003442:	83 c0 10             	add    $0x10,%eax
40003445:	3b 45 08             	cmp    0x8(%ebp),%eax
40003448:	77 18                	ja     40003462 <clearerr+0x2b>
4000344a:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
4000344f:	05 10 10 00 00       	add    $0x1010,%eax
40003454:	3b 45 08             	cmp    0x8(%ebp),%eax
40003457:	76 09                	jbe    40003462 <clearerr+0x2b>
40003459:	8b 45 08             	mov    0x8(%ebp),%eax
4000345c:	8b 00                	mov    (%eax),%eax
4000345e:	85 c0                	test   %eax,%eax
40003460:	75 24                	jne    40003486 <clearerr+0x4f>
40003462:	c7 44 24 0c ed 60 00 	movl   $0x400060ed,0xc(%esp)
40003469:	40 
4000346a:	c7 44 24 08 a9 60 00 	movl   $0x400060a9,0x8(%esp)
40003471:	40 
40003472:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
40003479:	00 
4000347a:	c7 04 24 be 60 00 40 	movl   $0x400060be,(%esp)
40003481:	e8 be d5 ff ff       	call   40000a44 <debug_panic>
	fd->err = 0;
40003486:	8b 45 08             	mov    0x8(%ebp),%eax
40003489:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
}
40003490:	c9                   	leave  
40003491:	c3                   	ret    

40003492 <fflush>:


int
fflush(FILE *f)
{
40003492:	55                   	push   %ebp
40003493:	89 e5                	mov    %esp,%ebp
40003495:	83 ec 18             	sub    $0x18,%esp
	if (f == NULL) {	// flush all open streams
40003498:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
4000349c:	75 57                	jne    400034f5 <fflush+0x63>
		for (f = &files->fd[0]; f < &files->fd[OPEN_MAX]; f++)
4000349e:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400034a3:	83 c0 10             	add    $0x10,%eax
400034a6:	89 45 08             	mov    %eax,0x8(%ebp)
400034a9:	eb 34                	jmp    400034df <fflush+0x4d>
			if (filedesc_isopen(f))
400034ab:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400034b0:	83 c0 10             	add    $0x10,%eax
400034b3:	3b 45 08             	cmp    0x8(%ebp),%eax
400034b6:	77 23                	ja     400034db <fflush+0x49>
400034b8:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400034bd:	05 10 10 00 00       	add    $0x1010,%eax
400034c2:	3b 45 08             	cmp    0x8(%ebp),%eax
400034c5:	76 14                	jbe    400034db <fflush+0x49>
400034c7:	8b 45 08             	mov    0x8(%ebp),%eax
400034ca:	8b 00                	mov    (%eax),%eax
400034cc:	85 c0                	test   %eax,%eax
400034ce:	74 0b                	je     400034db <fflush+0x49>
				fflush(f);
400034d0:	8b 45 08             	mov    0x8(%ebp),%eax
400034d3:	89 04 24             	mov    %eax,(%esp)
400034d6:	e8 b7 ff ff ff       	call   40003492 <fflush>

int
fflush(FILE *f)
{
	if (f == NULL) {	// flush all open streams
		for (f = &files->fd[0]; f < &files->fd[OPEN_MAX]; f++)
400034db:	83 45 08 10          	addl   $0x10,0x8(%ebp)
400034df:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400034e4:	05 10 10 00 00       	add    $0x1010,%eax
400034e9:	3b 45 08             	cmp    0x8(%ebp),%eax
400034ec:	77 bd                	ja     400034ab <fflush+0x19>
			if (filedesc_isopen(f))
				fflush(f);
		return 0;
400034ee:	b8 00 00 00 00       	mov    $0x0,%eax
400034f3:	eb 56                	jmp    4000354b <fflush+0xb9>
	}

	assert(filedesc_isopen(f));
400034f5:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400034fa:	83 c0 10             	add    $0x10,%eax
400034fd:	3b 45 08             	cmp    0x8(%ebp),%eax
40003500:	77 18                	ja     4000351a <fflush+0x88>
40003502:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003507:	05 10 10 00 00       	add    $0x1010,%eax
4000350c:	3b 45 08             	cmp    0x8(%ebp),%eax
4000350f:	76 09                	jbe    4000351a <fflush+0x88>
40003511:	8b 45 08             	mov    0x8(%ebp),%eax
40003514:	8b 00                	mov    (%eax),%eax
40003516:	85 c0                	test   %eax,%eax
40003518:	75 24                	jne    4000353e <fflush+0xac>
4000351a:	c7 44 24 0c 01 61 00 	movl   $0x40006101,0xc(%esp)
40003521:	40 
40003522:	c7 44 24 08 a9 60 00 	movl   $0x400060a9,0x8(%esp)
40003529:	40 
4000352a:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
40003531:	00 
40003532:	c7 04 24 be 60 00 40 	movl   $0x400060be,(%esp)
40003539:	e8 06 d5 ff ff       	call   40000a44 <debug_panic>
	return fileino_flush(f->ino);
4000353e:	8b 45 08             	mov    0x8(%ebp),%eax
40003541:	8b 00                	mov    (%eax),%eax
40003543:	89 04 24             	mov    %eax,(%esp)
40003546:	e8 f9 eb ff ff       	call   40002144 <fileino_flush>
}
4000354b:	c9                   	leave  
4000354c:	c3                   	ret    
4000354d:	66 90                	xchg   %ax,%ax
4000354f:	90                   	nop

40003550 <exit>:
#include <inc/assert.h>
#include <inc/string.h>

void gcc_noreturn
exit(int status)
{
40003550:	55                   	push   %ebp
40003551:	89 e5                	mov    %esp,%ebp
40003553:	83 ec 18             	sub    $0x18,%esp
	// To exit a PIOS user process, by convention,
	// we just set our exit status in our filestate area
	// and return to our parent process.
	files->status = status;
40003556:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
4000355b:	8b 55 08             	mov    0x8(%ebp),%edx
4000355e:	89 50 0c             	mov    %edx,0xc(%eax)
	files->exited = 1;
40003561:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003566:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
4000356d:	b8 03 00 00 00       	mov    $0x3,%eax
40003572:	cd 30                	int    $0x30
	sys_ret();
	panic("exit: sys_ret shouldn't have returned");
40003574:	c7 44 24 08 14 61 00 	movl   $0x40006114,0x8(%esp)
4000357b:	40 
4000357c:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
40003583:	00 
40003584:	c7 04 24 3a 61 00 40 	movl   $0x4000613a,(%esp)
4000358b:	e8 b4 d4 ff ff       	call   40000a44 <debug_panic>

40003590 <abort>:
}

void gcc_noreturn
abort(void)
{
40003590:	55                   	push   %ebp
40003591:	89 e5                	mov    %esp,%ebp
40003593:	83 ec 18             	sub    $0x18,%esp
	exit(EXIT_FAILURE);
40003596:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
4000359d:	e8 ae ff ff ff       	call   40003550 <exit>
400035a2:	66 90                	xchg   %ax,%ax

400035a4 <creat>:
#include <inc/assert.h>
#include <inc/stdarg.h>

int
creat(const char *path, mode_t mode)
{
400035a4:	55                   	push   %ebp
400035a5:	89 e5                	mov    %esp,%ebp
400035a7:	83 ec 18             	sub    $0x18,%esp
	return open(path, O_CREAT | O_TRUNC | O_WRONLY, mode);
400035aa:	8b 45 0c             	mov    0xc(%ebp),%eax
400035ad:	89 44 24 08          	mov    %eax,0x8(%esp)
400035b1:	c7 44 24 04 62 00 00 	movl   $0x62,0x4(%esp)
400035b8:	00 
400035b9:	8b 45 08             	mov    0x8(%ebp),%eax
400035bc:	89 04 24             	mov    %eax,(%esp)
400035bf:	e8 02 00 00 00       	call   400035c6 <open>
}
400035c4:	c9                   	leave  
400035c5:	c3                   	ret    

400035c6 <open>:

int
open(const char *path, int flags, ...)
{
400035c6:	55                   	push   %ebp
400035c7:	89 e5                	mov    %esp,%ebp
400035c9:	83 ec 28             	sub    $0x28,%esp
	// Get the optional mode argument, which applies only with O_CREAT.
	mode_t mode = 0;
400035cc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	if (flags & O_CREAT) {
400035d3:	8b 45 0c             	mov    0xc(%ebp),%eax
400035d6:	83 e0 20             	and    $0x20,%eax
400035d9:	85 c0                	test   %eax,%eax
400035db:	74 18                	je     400035f5 <open+0x2f>
		va_list ap;
		va_start(ap, flags);
400035dd:	8d 45 0c             	lea    0xc(%ebp),%eax
400035e0:	83 c0 04             	add    $0x4,%eax
400035e3:	89 45 f0             	mov    %eax,-0x10(%ebp)
		mode = va_arg(ap, mode_t);
400035e6:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
400035ea:	8b 45 f0             	mov    -0x10(%ebp),%eax
400035ed:	83 e8 04             	sub    $0x4,%eax
400035f0:	8b 00                	mov    (%eax),%eax
400035f2:	89 45 f4             	mov    %eax,-0xc(%ebp)
		va_end(ap);
	}

	filedesc *fd = filedesc_open(NULL, path, flags, mode);
400035f5:	8b 45 0c             	mov    0xc(%ebp),%eax
400035f8:	8b 55 f4             	mov    -0xc(%ebp),%edx
400035fb:	89 54 24 0c          	mov    %edx,0xc(%esp)
400035ff:	89 44 24 08          	mov    %eax,0x8(%esp)
40003603:	8b 45 08             	mov    0x8(%ebp),%eax
40003606:	89 44 24 04          	mov    %eax,0x4(%esp)
4000360a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40003611:	e8 f9 eb ff ff       	call   4000220f <filedesc_open>
40003616:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (fd == NULL)
40003619:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
4000361d:	75 07                	jne    40003626 <open+0x60>
		return -1;
4000361f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40003624:	eb 14                	jmp    4000363a <open+0x74>

	return fd - files->fd;
40003626:	8b 55 ec             	mov    -0x14(%ebp),%edx
40003629:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
4000362e:	83 c0 10             	add    $0x10,%eax
40003631:	89 d1                	mov    %edx,%ecx
40003633:	29 c1                	sub    %eax,%ecx
40003635:	89 c8                	mov    %ecx,%eax
40003637:	c1 f8 04             	sar    $0x4,%eax
}
4000363a:	c9                   	leave  
4000363b:	c3                   	ret    

4000363c <close>:

int
close(int fn)
{
4000363c:	55                   	push   %ebp
4000363d:	89 e5                	mov    %esp,%ebp
4000363f:	83 ec 18             	sub    $0x18,%esp
	filedesc_close(&files->fd[fn]);
40003642:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003647:	8b 55 08             	mov    0x8(%ebp),%edx
4000364a:	83 c2 01             	add    $0x1,%edx
4000364d:	c1 e2 04             	shl    $0x4,%edx
40003650:	01 d0                	add    %edx,%eax
40003652:	89 04 24             	mov    %eax,(%esp)
40003655:	e8 7a f1 ff ff       	call   400027d4 <filedesc_close>
	return 0;
4000365a:	b8 00 00 00 00       	mov    $0x0,%eax
}
4000365f:	c9                   	leave  
40003660:	c3                   	ret    

40003661 <read>:

ssize_t
read(int fn, void *buf, size_t nbytes)
{
40003661:	55                   	push   %ebp
40003662:	89 e5                	mov    %esp,%ebp
40003664:	83 ec 18             	sub    $0x18,%esp
	return filedesc_read(&files->fd[fn], buf, 1, nbytes);
40003667:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
4000366c:	8b 55 08             	mov    0x8(%ebp),%edx
4000366f:	83 c2 01             	add    $0x1,%edx
40003672:	c1 e2 04             	shl    $0x4,%edx
40003675:	01 c2                	add    %eax,%edx
40003677:	8b 45 10             	mov    0x10(%ebp),%eax
4000367a:	89 44 24 0c          	mov    %eax,0xc(%esp)
4000367e:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40003685:	00 
40003686:	8b 45 0c             	mov    0xc(%ebp),%eax
40003689:	89 44 24 04          	mov    %eax,0x4(%esp)
4000368d:	89 14 24             	mov    %edx,(%esp)
40003690:	e8 a4 ed ff ff       	call   40002439 <filedesc_read>
}
40003695:	c9                   	leave  
40003696:	c3                   	ret    

40003697 <write>:

ssize_t
write(int fn, const void *buf, size_t nbytes)
{
40003697:	55                   	push   %ebp
40003698:	89 e5                	mov    %esp,%ebp
4000369a:	83 ec 18             	sub    $0x18,%esp
	return filedesc_write(&files->fd[fn], buf, 1, nbytes);
4000369d:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400036a2:	8b 55 08             	mov    0x8(%ebp),%edx
400036a5:	83 c2 01             	add    $0x1,%edx
400036a8:	c1 e2 04             	shl    $0x4,%edx
400036ab:	01 c2                	add    %eax,%edx
400036ad:	8b 45 10             	mov    0x10(%ebp),%eax
400036b0:	89 44 24 0c          	mov    %eax,0xc(%esp)
400036b4:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
400036bb:	00 
400036bc:	8b 45 0c             	mov    0xc(%ebp),%eax
400036bf:	89 44 24 04          	mov    %eax,0x4(%esp)
400036c3:	89 14 24             	mov    %edx,(%esp)
400036c6:	e8 83 ee ff ff       	call   4000254e <filedesc_write>
}
400036cb:	c9                   	leave  
400036cc:	c3                   	ret    

400036cd <lseek>:

off_t
lseek(int fn, off_t offset, int whence)
{
400036cd:	55                   	push   %ebp
400036ce:	89 e5                	mov    %esp,%ebp
400036d0:	83 ec 18             	sub    $0x18,%esp
	return filedesc_seek(&files->fd[fn], offset, whence);
400036d3:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400036d8:	8b 55 08             	mov    0x8(%ebp),%edx
400036db:	83 c2 01             	add    $0x1,%edx
400036de:	c1 e2 04             	shl    $0x4,%edx
400036e1:	01 c2                	add    %eax,%edx
400036e3:	8b 45 10             	mov    0x10(%ebp),%eax
400036e6:	89 44 24 08          	mov    %eax,0x8(%esp)
400036ea:	8b 45 0c             	mov    0xc(%ebp),%eax
400036ed:	89 44 24 04          	mov    %eax,0x4(%esp)
400036f1:	89 14 24             	mov    %edx,(%esp)
400036f4:	e8 ca ef ff ff       	call   400026c3 <filedesc_seek>
}
400036f9:	c9                   	leave  
400036fa:	c3                   	ret    

400036fb <dup>:

int
dup(int oldfn)
{
400036fb:	55                   	push   %ebp
400036fc:	89 e5                	mov    %esp,%ebp
400036fe:	83 ec 28             	sub    $0x28,%esp
	filedesc *newfd = filedesc_alloc();
40003701:	e8 b3 ea ff ff       	call   400021b9 <filedesc_alloc>
40003706:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (!newfd)
40003709:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
4000370d:	75 07                	jne    40003716 <dup+0x1b>
		return -1;
4000370f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40003714:	eb 23                	jmp    40003739 <dup+0x3e>
	return dup2(oldfn, newfd - files->fd);
40003716:	8b 55 f4             	mov    -0xc(%ebp),%edx
40003719:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
4000371e:	83 c0 10             	add    $0x10,%eax
40003721:	89 d1                	mov    %edx,%ecx
40003723:	29 c1                	sub    %eax,%ecx
40003725:	89 c8                	mov    %ecx,%eax
40003727:	c1 f8 04             	sar    $0x4,%eax
4000372a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000372e:	8b 45 08             	mov    0x8(%ebp),%eax
40003731:	89 04 24             	mov    %eax,(%esp)
40003734:	e8 02 00 00 00       	call   4000373b <dup2>
}
40003739:	c9                   	leave  
4000373a:	c3                   	ret    

4000373b <dup2>:

int
dup2(int oldfn, int newfn)
{
4000373b:	55                   	push   %ebp
4000373c:	89 e5                	mov    %esp,%ebp
4000373e:	83 ec 28             	sub    $0x28,%esp
	filedesc *oldfd = &files->fd[oldfn];
40003741:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003746:	8b 55 08             	mov    0x8(%ebp),%edx
40003749:	83 c2 01             	add    $0x1,%edx
4000374c:	c1 e2 04             	shl    $0x4,%edx
4000374f:	01 d0                	add    %edx,%eax
40003751:	89 45 f4             	mov    %eax,-0xc(%ebp)
	filedesc *newfd = &files->fd[newfn];
40003754:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003759:	8b 55 0c             	mov    0xc(%ebp),%edx
4000375c:	83 c2 01             	add    $0x1,%edx
4000375f:	c1 e2 04             	shl    $0x4,%edx
40003762:	01 d0                	add    %edx,%eax
40003764:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(filedesc_isopen(oldfd));
40003767:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
4000376c:	83 c0 10             	add    $0x10,%eax
4000376f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40003772:	77 18                	ja     4000378c <dup2+0x51>
40003774:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003779:	05 10 10 00 00       	add    $0x1010,%eax
4000377e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40003781:	76 09                	jbe    4000378c <dup2+0x51>
40003783:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003786:	8b 00                	mov    (%eax),%eax
40003788:	85 c0                	test   %eax,%eax
4000378a:	75 24                	jne    400037b0 <dup2+0x75>
4000378c:	c7 44 24 0c 48 61 00 	movl   $0x40006148,0xc(%esp)
40003793:	40 
40003794:	c7 44 24 08 5f 61 00 	movl   $0x4000615f,0x8(%esp)
4000379b:	40 
4000379c:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
400037a3:	00 
400037a4:	c7 04 24 74 61 00 40 	movl   $0x40006174,(%esp)
400037ab:	e8 94 d2 ff ff       	call   40000a44 <debug_panic>
	assert(filedesc_isvalid(newfd));
400037b0:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400037b5:	83 c0 10             	add    $0x10,%eax
400037b8:	3b 45 f0             	cmp    -0x10(%ebp),%eax
400037bb:	77 0f                	ja     400037cc <dup2+0x91>
400037bd:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400037c2:	05 10 10 00 00       	add    $0x1010,%eax
400037c7:	3b 45 f0             	cmp    -0x10(%ebp),%eax
400037ca:	77 24                	ja     400037f0 <dup2+0xb5>
400037cc:	c7 44 24 0c 81 61 00 	movl   $0x40006181,0xc(%esp)
400037d3:	40 
400037d4:	c7 44 24 08 5f 61 00 	movl   $0x4000615f,0x8(%esp)
400037db:	40 
400037dc:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
400037e3:	00 
400037e4:	c7 04 24 74 61 00 40 	movl   $0x40006174,(%esp)
400037eb:	e8 54 d2 ff ff       	call   40000a44 <debug_panic>

	if (filedesc_isopen(newfd))
400037f0:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400037f5:	83 c0 10             	add    $0x10,%eax
400037f8:	3b 45 f0             	cmp    -0x10(%ebp),%eax
400037fb:	77 23                	ja     40003820 <dup2+0xe5>
400037fd:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003802:	05 10 10 00 00       	add    $0x1010,%eax
40003807:	3b 45 f0             	cmp    -0x10(%ebp),%eax
4000380a:	76 14                	jbe    40003820 <dup2+0xe5>
4000380c:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000380f:	8b 00                	mov    (%eax),%eax
40003811:	85 c0                	test   %eax,%eax
40003813:	74 0b                	je     40003820 <dup2+0xe5>
		close(newfn);
40003815:	8b 45 0c             	mov    0xc(%ebp),%eax
40003818:	89 04 24             	mov    %eax,(%esp)
4000381b:	e8 1c fe ff ff       	call   4000363c <close>

	*newfd = *oldfd;
40003820:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003823:	8b 55 f4             	mov    -0xc(%ebp),%edx
40003826:	8b 0a                	mov    (%edx),%ecx
40003828:	89 08                	mov    %ecx,(%eax)
4000382a:	8b 4a 04             	mov    0x4(%edx),%ecx
4000382d:	89 48 04             	mov    %ecx,0x4(%eax)
40003830:	8b 4a 08             	mov    0x8(%edx),%ecx
40003833:	89 48 08             	mov    %ecx,0x8(%eax)
40003836:	8b 52 0c             	mov    0xc(%edx),%edx
40003839:	89 50 0c             	mov    %edx,0xc(%eax)

	return newfn;
4000383c:	8b 45 0c             	mov    0xc(%ebp),%eax
}
4000383f:	c9                   	leave  
40003840:	c3                   	ret    

40003841 <truncate>:

int
truncate(const char *path, off_t newlength)
{
40003841:	55                   	push   %ebp
40003842:	89 e5                	mov    %esp,%ebp
40003844:	83 ec 28             	sub    $0x28,%esp
	int ino = dir_walk(path, 0);
40003847:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000384e:	00 
4000384f:	8b 45 08             	mov    0x8(%ebp),%eax
40003852:	89 04 24             	mov    %eax,(%esp)
40003855:	e8 0e f0 ff ff       	call   40002868 <dir_walk>
4000385a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (ino < 0)
4000385d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40003861:	79 07                	jns    4000386a <truncate+0x29>
		return -1;
40003863:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40003868:	eb 12                	jmp    4000387c <truncate+0x3b>
	return fileino_truncate(ino, newlength);
4000386a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000386d:	89 44 24 04          	mov    %eax,0x4(%esp)
40003871:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003874:	89 04 24             	mov    %eax,(%esp)
40003877:	e8 46 e6 ff ff       	call   40001ec2 <fileino_truncate>
}
4000387c:	c9                   	leave  
4000387d:	c3                   	ret    

4000387e <ftruncate>:

int
ftruncate(int fn, off_t newlength)
{
4000387e:	55                   	push   %ebp
4000387f:	89 e5                	mov    %esp,%ebp
40003881:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
40003884:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003889:	8b 55 08             	mov    0x8(%ebp),%edx
4000388c:	83 c2 01             	add    $0x1,%edx
4000388f:	c1 e2 04             	shl    $0x4,%edx
40003892:	01 c2                	add    %eax,%edx
40003894:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003899:	83 c0 10             	add    $0x10,%eax
4000389c:	39 c2                	cmp    %eax,%edx
4000389e:	72 34                	jb     400038d4 <ftruncate+0x56>
400038a0:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400038a5:	8b 55 08             	mov    0x8(%ebp),%edx
400038a8:	83 c2 01             	add    $0x1,%edx
400038ab:	c1 e2 04             	shl    $0x4,%edx
400038ae:	01 c2                	add    %eax,%edx
400038b0:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400038b5:	05 10 10 00 00       	add    $0x1010,%eax
400038ba:	39 c2                	cmp    %eax,%edx
400038bc:	73 16                	jae    400038d4 <ftruncate+0x56>
400038be:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400038c3:	8b 55 08             	mov    0x8(%ebp),%edx
400038c6:	83 c2 01             	add    $0x1,%edx
400038c9:	c1 e2 04             	shl    $0x4,%edx
400038cc:	01 d0                	add    %edx,%eax
400038ce:	8b 00                	mov    (%eax),%eax
400038d0:	85 c0                	test   %eax,%eax
400038d2:	75 24                	jne    400038f8 <ftruncate+0x7a>
400038d4:	c7 44 24 0c 9c 61 00 	movl   $0x4000619c,0xc(%esp)
400038db:	40 
400038dc:	c7 44 24 08 5f 61 00 	movl   $0x4000615f,0x8(%esp)
400038e3:	40 
400038e4:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
400038eb:	00 
400038ec:	c7 04 24 74 61 00 40 	movl   $0x40006174,(%esp)
400038f3:	e8 4c d1 ff ff       	call   40000a44 <debug_panic>
	return fileino_truncate(files->fd[fn].ino, newlength);
400038f8:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400038fd:	8b 55 08             	mov    0x8(%ebp),%edx
40003900:	83 c2 01             	add    $0x1,%edx
40003903:	c1 e2 04             	shl    $0x4,%edx
40003906:	01 d0                	add    %edx,%eax
40003908:	8b 00                	mov    (%eax),%eax
4000390a:	8b 55 0c             	mov    0xc(%ebp),%edx
4000390d:	89 54 24 04          	mov    %edx,0x4(%esp)
40003911:	89 04 24             	mov    %eax,(%esp)
40003914:	e8 a9 e5 ff ff       	call   40001ec2 <fileino_truncate>
}
40003919:	c9                   	leave  
4000391a:	c3                   	ret    

4000391b <isatty>:

int
isatty(int fn)
{
4000391b:	55                   	push   %ebp
4000391c:	89 e5                	mov    %esp,%ebp
4000391e:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
40003921:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003926:	8b 55 08             	mov    0x8(%ebp),%edx
40003929:	83 c2 01             	add    $0x1,%edx
4000392c:	c1 e2 04             	shl    $0x4,%edx
4000392f:	01 c2                	add    %eax,%edx
40003931:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003936:	83 c0 10             	add    $0x10,%eax
40003939:	39 c2                	cmp    %eax,%edx
4000393b:	72 34                	jb     40003971 <isatty+0x56>
4000393d:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003942:	8b 55 08             	mov    0x8(%ebp),%edx
40003945:	83 c2 01             	add    $0x1,%edx
40003948:	c1 e2 04             	shl    $0x4,%edx
4000394b:	01 c2                	add    %eax,%edx
4000394d:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003952:	05 10 10 00 00       	add    $0x1010,%eax
40003957:	39 c2                	cmp    %eax,%edx
40003959:	73 16                	jae    40003971 <isatty+0x56>
4000395b:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003960:	8b 55 08             	mov    0x8(%ebp),%edx
40003963:	83 c2 01             	add    $0x1,%edx
40003966:	c1 e2 04             	shl    $0x4,%edx
40003969:	01 d0                	add    %edx,%eax
4000396b:	8b 00                	mov    (%eax),%eax
4000396d:	85 c0                	test   %eax,%eax
4000396f:	75 24                	jne    40003995 <isatty+0x7a>
40003971:	c7 44 24 0c 9c 61 00 	movl   $0x4000619c,0xc(%esp)
40003978:	40 
40003979:	c7 44 24 08 5f 61 00 	movl   $0x4000615f,0x8(%esp)
40003980:	40 
40003981:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
40003988:	00 
40003989:	c7 04 24 74 61 00 40 	movl   $0x40006174,(%esp)
40003990:	e8 af d0 ff ff       	call   40000a44 <debug_panic>
	return files->fd[fn].ino == FILEINO_CONSIN
40003995:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
4000399a:	8b 55 08             	mov    0x8(%ebp),%edx
4000399d:	83 c2 01             	add    $0x1,%edx
400039a0:	c1 e2 04             	shl    $0x4,%edx
400039a3:	01 d0                	add    %edx,%eax
400039a5:	8b 00                	mov    (%eax),%eax
		|| files->fd[fn].ino == FILEINO_CONSOUT;
400039a7:	83 f8 01             	cmp    $0x1,%eax
400039aa:	74 17                	je     400039c3 <isatty+0xa8>
400039ac:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400039b1:	8b 55 08             	mov    0x8(%ebp),%edx
400039b4:	83 c2 01             	add    $0x1,%edx
400039b7:	c1 e2 04             	shl    $0x4,%edx
400039ba:	01 d0                	add    %edx,%eax
400039bc:	8b 00                	mov    (%eax),%eax
400039be:	83 f8 02             	cmp    $0x2,%eax
400039c1:	75 07                	jne    400039ca <isatty+0xaf>
400039c3:	b8 01 00 00 00       	mov    $0x1,%eax
400039c8:	eb 05                	jmp    400039cf <isatty+0xb4>
400039ca:	b8 00 00 00 00       	mov    $0x0,%eax
}
400039cf:	c9                   	leave  
400039d0:	c3                   	ret    

400039d1 <stat>:

int
stat(const char *path, struct stat *statbuf)
{
400039d1:	55                   	push   %ebp
400039d2:	89 e5                	mov    %esp,%ebp
400039d4:	83 ec 28             	sub    $0x28,%esp
	int ino = dir_walk(path, 0);
400039d7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400039de:	00 
400039df:	8b 45 08             	mov    0x8(%ebp),%eax
400039e2:	89 04 24             	mov    %eax,(%esp)
400039e5:	e8 7e ee ff ff       	call   40002868 <dir_walk>
400039ea:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (ino < 0)
400039ed:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
400039f1:	79 07                	jns    400039fa <stat+0x29>
		return -1;
400039f3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400039f8:	eb 12                	jmp    40003a0c <stat+0x3b>
	return fileino_stat(ino, statbuf);
400039fa:	8b 45 0c             	mov    0xc(%ebp),%eax
400039fd:	89 44 24 04          	mov    %eax,0x4(%esp)
40003a01:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003a04:	89 04 24             	mov    %eax,(%esp)
40003a07:	e8 91 e3 ff ff       	call   40001d9d <fileino_stat>
}
40003a0c:	c9                   	leave  
40003a0d:	c3                   	ret    

40003a0e <fstat>:

int
fstat(int fn, struct stat *statbuf)
{
40003a0e:	55                   	push   %ebp
40003a0f:	89 e5                	mov    %esp,%ebp
40003a11:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
40003a14:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003a19:	8b 55 08             	mov    0x8(%ebp),%edx
40003a1c:	83 c2 01             	add    $0x1,%edx
40003a1f:	c1 e2 04             	shl    $0x4,%edx
40003a22:	01 c2                	add    %eax,%edx
40003a24:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003a29:	83 c0 10             	add    $0x10,%eax
40003a2c:	39 c2                	cmp    %eax,%edx
40003a2e:	72 34                	jb     40003a64 <fstat+0x56>
40003a30:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003a35:	8b 55 08             	mov    0x8(%ebp),%edx
40003a38:	83 c2 01             	add    $0x1,%edx
40003a3b:	c1 e2 04             	shl    $0x4,%edx
40003a3e:	01 c2                	add    %eax,%edx
40003a40:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003a45:	05 10 10 00 00       	add    $0x1010,%eax
40003a4a:	39 c2                	cmp    %eax,%edx
40003a4c:	73 16                	jae    40003a64 <fstat+0x56>
40003a4e:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003a53:	8b 55 08             	mov    0x8(%ebp),%edx
40003a56:	83 c2 01             	add    $0x1,%edx
40003a59:	c1 e2 04             	shl    $0x4,%edx
40003a5c:	01 d0                	add    %edx,%eax
40003a5e:	8b 00                	mov    (%eax),%eax
40003a60:	85 c0                	test   %eax,%eax
40003a62:	75 24                	jne    40003a88 <fstat+0x7a>
40003a64:	c7 44 24 0c 9c 61 00 	movl   $0x4000619c,0xc(%esp)
40003a6b:	40 
40003a6c:	c7 44 24 08 5f 61 00 	movl   $0x4000615f,0x8(%esp)
40003a73:	40 
40003a74:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
40003a7b:	00 
40003a7c:	c7 04 24 74 61 00 40 	movl   $0x40006174,(%esp)
40003a83:	e8 bc cf ff ff       	call   40000a44 <debug_panic>
	return fileino_stat(files->fd[fn].ino, statbuf);
40003a88:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003a8d:	8b 55 08             	mov    0x8(%ebp),%edx
40003a90:	83 c2 01             	add    $0x1,%edx
40003a93:	c1 e2 04             	shl    $0x4,%edx
40003a96:	01 d0                	add    %edx,%eax
40003a98:	8b 00                	mov    (%eax),%eax
40003a9a:	8b 55 0c             	mov    0xc(%ebp),%edx
40003a9d:	89 54 24 04          	mov    %edx,0x4(%esp)
40003aa1:	89 04 24             	mov    %eax,(%esp)
40003aa4:	e8 f4 e2 ff ff       	call   40001d9d <fileino_stat>
}
40003aa9:	c9                   	leave  
40003aaa:	c3                   	ret    

40003aab <fsync>:

int
fsync(int fn)
{
40003aab:	55                   	push   %ebp
40003aac:	89 e5                	mov    %esp,%ebp
40003aae:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
40003ab1:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003ab6:	8b 55 08             	mov    0x8(%ebp),%edx
40003ab9:	83 c2 01             	add    $0x1,%edx
40003abc:	c1 e2 04             	shl    $0x4,%edx
40003abf:	01 c2                	add    %eax,%edx
40003ac1:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003ac6:	83 c0 10             	add    $0x10,%eax
40003ac9:	39 c2                	cmp    %eax,%edx
40003acb:	72 34                	jb     40003b01 <fsync+0x56>
40003acd:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003ad2:	8b 55 08             	mov    0x8(%ebp),%edx
40003ad5:	83 c2 01             	add    $0x1,%edx
40003ad8:	c1 e2 04             	shl    $0x4,%edx
40003adb:	01 c2                	add    %eax,%edx
40003add:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003ae2:	05 10 10 00 00       	add    $0x1010,%eax
40003ae7:	39 c2                	cmp    %eax,%edx
40003ae9:	73 16                	jae    40003b01 <fsync+0x56>
40003aeb:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003af0:	8b 55 08             	mov    0x8(%ebp),%edx
40003af3:	83 c2 01             	add    $0x1,%edx
40003af6:	c1 e2 04             	shl    $0x4,%edx
40003af9:	01 d0                	add    %edx,%eax
40003afb:	8b 00                	mov    (%eax),%eax
40003afd:	85 c0                	test   %eax,%eax
40003aff:	75 24                	jne    40003b25 <fsync+0x7a>
40003b01:	c7 44 24 0c 9c 61 00 	movl   $0x4000619c,0xc(%esp)
40003b08:	40 
40003b09:	c7 44 24 08 5f 61 00 	movl   $0x4000615f,0x8(%esp)
40003b10:	40 
40003b11:	c7 44 24 04 87 00 00 	movl   $0x87,0x4(%esp)
40003b18:	00 
40003b19:	c7 04 24 74 61 00 40 	movl   $0x40006174,(%esp)
40003b20:	e8 1f cf ff ff       	call   40000a44 <debug_panic>
	return fileino_flush(files->fd[fn].ino);
40003b25:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003b2a:	8b 55 08             	mov    0x8(%ebp),%edx
40003b2d:	83 c2 01             	add    $0x1,%edx
40003b30:	c1 e2 04             	shl    $0x4,%edx
40003b33:	01 d0                	add    %edx,%eax
40003b35:	8b 00                	mov    (%eax),%eax
40003b37:	89 04 24             	mov    %eax,(%esp)
40003b3a:	e8 05 e6 ff ff       	call   40002144 <fileino_flush>
}
40003b3f:	c9                   	leave  
40003b40:	c3                   	ret    
40003b41:	66 90                	xchg   %ax,%ax
40003b43:	90                   	nop

40003b44 <fork>:
bool reconcile(pid_t pid, filestate *cfiles);
bool reconcile_inode(pid_t pid, filestate *cfiles, int pino, int cino);
bool reconcile_merge(pid_t pid, filestate *cfiles, int pino, int cino);

pid_t fork(void)
{
40003b44:	55                   	push   %ebp
40003b45:	89 e5                	mov    %esp,%ebp
40003b47:	57                   	push   %edi
40003b48:	56                   	push   %esi
40003b49:	53                   	push   %ebx
40003b4a:	81 ec 9c 02 00 00    	sub    $0x29c,%esp
	// even though child slots are process-local in PIOS
	// whereas PIDs are global in Unix.
	// This means that commands like 'ps' and 'kill'
	// have to be shell-builtin commands under PIOS.
	pid_t pid;
	for (pid = 1; pid < 256; pid++)
40003b50:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
40003b57:	eb 19                	jmp    40003b72 <fork+0x2e>
		if (files->child[pid].state == PROC_FREE)
40003b59:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003b5e:	8b 55 e0             	mov    -0x20(%ebp),%edx
40003b61:	81 c2 04 1b 00 00    	add    $0x1b04,%edx
40003b67:	8b 04 90             	mov    (%eax,%edx,4),%eax
40003b6a:	85 c0                	test   %eax,%eax
40003b6c:	74 0f                	je     40003b7d <fork+0x39>
	// even though child slots are process-local in PIOS
	// whereas PIDs are global in Unix.
	// This means that commands like 'ps' and 'kill'
	// have to be shell-builtin commands under PIOS.
	pid_t pid;
	for (pid = 1; pid < 256; pid++)
40003b6e:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
40003b72:	81 7d e0 ff 00 00 00 	cmpl   $0xff,-0x20(%ebp)
40003b79:	7e de                	jle    40003b59 <fork+0x15>
40003b7b:	eb 01                	jmp    40003b7e <fork+0x3a>
		if (files->child[pid].state == PROC_FREE)
			break;
40003b7d:	90                   	nop
	if (pid == 256) {
40003b7e:	81 7d e0 00 01 00 00 	cmpl   $0x100,-0x20(%ebp)
40003b85:	75 31                	jne    40003bb8 <fork+0x74>
		warn("fork: no child process available");
40003b87:	c7 44 24 08 bc 61 00 	movl   $0x400061bc,0x8(%esp)
40003b8e:	40 
40003b8f:	c7 44 24 04 2c 00 00 	movl   $0x2c,0x4(%esp)
40003b96:	00 
40003b97:	c7 04 24 dd 61 00 40 	movl   $0x400061dd,(%esp)
40003b9e:	e8 0b cf ff ff       	call   40000aae <debug_warn>
		errno = EAGAIN;
40003ba3:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003ba8:	c7 00 08 00 00 00    	movl   $0x8,(%eax)
		return -1;
40003bae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40003bb3:	e9 e1 01 00 00       	jmp    40003d99 <fork+0x255>
	}

	// Set up the register state for the child
	struct procstate ps;
	memset(&ps, 0, sizeof(ps));
40003bb8:	c7 44 24 08 50 02 00 	movl   $0x250,0x8(%esp)
40003bbf:	00 
40003bc0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40003bc7:	00 
40003bc8:	8d 85 68 fd ff ff    	lea    -0x298(%ebp),%eax
40003bce:	89 04 24             	mov    %eax,(%esp)
40003bd1:	e8 9f d9 ff ff       	call   40001575 <memset>

	// Use some assembly magic to propagate registers to child
	// and generate an appropriate starting eip
	int isparent;
	asm volatile(
40003bd6:	89 b5 6c fd ff ff    	mov    %esi,-0x294(%ebp)
40003bdc:	89 bd 68 fd ff ff    	mov    %edi,-0x298(%ebp)
40003be2:	89 ad 70 fd ff ff    	mov    %ebp,-0x290(%ebp)
40003be8:	89 a5 ac fd ff ff    	mov    %esp,-0x254(%ebp)
40003bee:	c7 85 a0 fd ff ff fd 	movl   $0x40003bfd,-0x260(%ebp)
40003bf5:	3b 00 40 
40003bf8:	b8 01 00 00 00       	mov    $0x1,%eax
40003bfd:	89 c6                	mov    %eax,%esi
40003bff:	89 75 dc             	mov    %esi,-0x24(%ebp)
		  "=m" (ps.tf.esp),
		  "=m" (ps.tf.eip),
		  "=a" (isparent)
		:
		: "ebx", "ecx", "edx");
	if (!isparent) {
40003c02:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
40003c06:	0f 85 f9 00 00 00    	jne    40003d05 <fork+0x1c1>
		// Clear our child state array, since we have no children yet.
		memset(&files->child, 0, sizeof(files->child));
40003c0c:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003c11:	05 10 6c 00 00       	add    $0x6c10,%eax
40003c16:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
40003c1d:	00 
40003c1e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40003c25:	00 
40003c26:	89 04 24             	mov    %eax,(%esp)
40003c29:	e8 47 d9 ff ff       	call   40001575 <memset>
		files->child[0].state = PROC_RESERVED;
40003c2e:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003c33:	c7 80 10 6c 00 00 ff 	movl   $0xffffffff,0x6c10(%eax)
40003c3a:	ff ff ff 
		for (i = 1; i < FILE_INODES; i++)
40003c3d:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
40003c44:	e9 a5 00 00 00       	jmp    40003cee <fork+0x1aa>
			if (fileino_alloced(i)) {
40003c49:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
40003c4d:	0f 8e 97 00 00 00    	jle    40003cea <fork+0x1a6>
40003c53:	81 7d e4 ff 00 00 00 	cmpl   $0xff,-0x1c(%ebp)
40003c5a:	0f 8f 8a 00 00 00    	jg     40003cea <fork+0x1a6>
40003c60:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40003c66:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40003c69:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003c6c:	01 d0                	add    %edx,%eax
40003c6e:	05 10 10 00 00       	add    $0x1010,%eax
40003c73:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40003c77:	84 c0                	test   %al,%al
40003c79:	74 6f                	je     40003cea <fork+0x1a6>
				files->fi[i].rino = i;	// 1-to-1 mapping
40003c7b:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40003c81:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40003c84:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003c87:	01 d0                	add    %edx,%eax
40003c89:	8d 90 60 10 00 00    	lea    0x1060(%eax),%edx
40003c8f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40003c92:	89 02                	mov    %eax,(%edx)
				files->fi[i].rver = files->fi[i].ver;
40003c94:	8b 0d 3c 5d 00 40    	mov    0x40005d3c,%ecx
40003c9a:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40003ca0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40003ca3:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003ca6:	01 d0                	add    %edx,%eax
40003ca8:	05 54 10 00 00       	add    $0x1054,%eax
40003cad:	8b 00                	mov    (%eax),%eax
40003caf:	8b 55 e4             	mov    -0x1c(%ebp),%edx
40003cb2:	6b d2 5c             	imul   $0x5c,%edx,%edx
40003cb5:	01 ca                	add    %ecx,%edx
40003cb7:	81 c2 64 10 00 00    	add    $0x1064,%edx
40003cbd:	89 02                	mov    %eax,(%edx)
				files->fi[i].rlen = files->fi[i].size;
40003cbf:	8b 0d 3c 5d 00 40    	mov    0x40005d3c,%ecx
40003cc5:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40003ccb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40003cce:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003cd1:	01 d0                	add    %edx,%eax
40003cd3:	05 5c 10 00 00       	add    $0x105c,%eax
40003cd8:	8b 00                	mov    (%eax),%eax
40003cda:	8b 55 e4             	mov    -0x1c(%ebp),%edx
40003cdd:	6b d2 5c             	imul   $0x5c,%edx,%edx
40003ce0:	01 ca                	add    %ecx,%edx
40003ce2:	81 c2 68 10 00 00    	add    $0x1068,%edx
40003ce8:	89 02                	mov    %eax,(%edx)
		: "ebx", "ecx", "edx");
	if (!isparent) {
		// Clear our child state array, since we have no children yet.
		memset(&files->child, 0, sizeof(files->child));
		files->child[0].state = PROC_RESERVED;
		for (i = 1; i < FILE_INODES; i++)
40003cea:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
40003cee:	81 7d e4 ff 00 00 00 	cmpl   $0xff,-0x1c(%ebp)
40003cf5:	0f 8e 4e ff ff ff    	jle    40003c49 <fork+0x105>
				files->fi[i].rino = i;	// 1-to-1 mapping
				files->fi[i].rver = files->fi[i].ver;
				files->fi[i].rlen = files->fi[i].size;
			}

		return 0;	// indicate that we're the child.
40003cfb:	b8 00 00 00 00       	mov    $0x0,%eax
40003d00:	e9 94 00 00 00       	jmp    40003d99 <fork+0x255>
	}

	// Copy our entire user address space into the child and start it.
	ps.tf.regs.eax = 0;	// isparent == 0 in the child
40003d05:	c7 85 84 fd ff ff 00 	movl   $0x0,-0x27c(%ebp)
40003d0c:	00 00 00 
	sys_put(SYS_REGS | SYS_COPY | SYS_START, pid, &ps,
40003d0f:	8b 45 e0             	mov    -0x20(%ebp),%eax
40003d12:	0f b7 c0             	movzwl %ax,%eax
40003d15:	c7 45 d8 10 10 02 00 	movl   $0x21010,-0x28(%ebp)
40003d1c:	66 89 45 d6          	mov    %ax,-0x2a(%ebp)
40003d20:	8d 85 68 fd ff ff    	lea    -0x298(%ebp),%eax
40003d26:	89 45 d0             	mov    %eax,-0x30(%ebp)
40003d29:	c7 45 cc 00 00 00 40 	movl   $0x40000000,-0x34(%ebp)
40003d30:	c7 45 c8 00 00 00 40 	movl   $0x40000000,-0x38(%ebp)
40003d37:	c7 45 c4 00 00 00 b0 	movl   $0xb0000000,-0x3c(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40003d3e:	8b 45 d8             	mov    -0x28(%ebp),%eax
40003d41:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40003d44:	8b 5d d0             	mov    -0x30(%ebp),%ebx
40003d47:	0f b7 55 d6          	movzwl -0x2a(%ebp),%edx
40003d4b:	8b 75 cc             	mov    -0x34(%ebp),%esi
40003d4e:	8b 7d c8             	mov    -0x38(%ebp),%edi
40003d51:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
40003d54:	cd 30                	int    $0x30
		ALLVA, ALLVA, ALLSIZE);

	// Record the inode generation numbers of all inodes at fork time,
	// so that we can reconcile them later when we synchronize with it.
	memset(&files->child[pid], 0, sizeof(files->child[pid]));
40003d56:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003d5b:	8b 55 e0             	mov    -0x20(%ebp),%edx
40003d5e:	81 c2 04 1b 00 00    	add    $0x1b04,%edx
40003d64:	c1 e2 02             	shl    $0x2,%edx
40003d67:	01 d0                	add    %edx,%eax
40003d69:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
40003d70:	00 
40003d71:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40003d78:	00 
40003d79:	89 04 24             	mov    %eax,(%esp)
40003d7c:	e8 f4 d7 ff ff       	call   40001575 <memset>
	files->child[pid].state = PROC_FORKED;
40003d81:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003d86:	8b 55 e0             	mov    -0x20(%ebp),%edx
40003d89:	81 c2 04 1b 00 00    	add    $0x1b04,%edx
40003d8f:	c7 04 90 01 00 00 00 	movl   $0x1,(%eax,%edx,4)

	return pid;
40003d96:	8b 45 e0             	mov    -0x20(%ebp),%eax
}
40003d99:	81 c4 9c 02 00 00    	add    $0x29c,%esp
40003d9f:	5b                   	pop    %ebx
40003da0:	5e                   	pop    %esi
40003da1:	5f                   	pop    %edi
40003da2:	5d                   	pop    %ebp
40003da3:	c3                   	ret    

40003da4 <wait>:

pid_t
wait(int *status)
{
40003da4:	55                   	push   %ebp
40003da5:	89 e5                	mov    %esp,%ebp
40003da7:	83 ec 18             	sub    $0x18,%esp
	return waitpid(-1, status, 0);
40003daa:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
40003db1:	00 
40003db2:	8b 45 08             	mov    0x8(%ebp),%eax
40003db5:	89 44 24 04          	mov    %eax,0x4(%esp)
40003db9:	c7 04 24 ff ff ff ff 	movl   $0xffffffff,(%esp)
40003dc0:	e8 02 00 00 00       	call   40003dc7 <waitpid>
}
40003dc5:	c9                   	leave  
40003dc6:	c3                   	ret    

40003dc7 <waitpid>:

pid_t
waitpid(pid_t pid, int *status, int options)
{
40003dc7:	55                   	push   %ebp
40003dc8:	89 e5                	mov    %esp,%ebp
40003dca:	57                   	push   %edi
40003dcb:	56                   	push   %esi
40003dcc:	53                   	push   %ebx
40003dcd:	81 ec cc 02 00 00    	sub    $0x2cc,%esp
	assert(pid >= -1 && pid < 256);
40003dd3:	83 7d 08 ff          	cmpl   $0xffffffff,0x8(%ebp)
40003dd7:	7c 09                	jl     40003de2 <waitpid+0x1b>
40003dd9:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40003de0:	7e 24                	jle    40003e06 <waitpid+0x3f>
40003de2:	c7 44 24 0c e8 61 00 	movl   $0x400061e8,0xc(%esp)
40003de9:	40 
40003dea:	c7 44 24 08 ff 61 00 	movl   $0x400061ff,0x8(%esp)
40003df1:	40 
40003df2:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
40003df9:	00 
40003dfa:	c7 04 24 dd 61 00 40 	movl   $0x400061dd,(%esp)
40003e01:	e8 3e cc ff ff       	call   40000a44 <debug_panic>
	// Find a process to wait for.
	// Of course for interactive or load-balancing purposes
	// we would like to have a way to wait for
	// whichever child process happens to finish first -
	// that requires a (nondeterministic) kernel API extension.
	if (pid <= 0)
40003e06:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003e0a:	7f 2f                	jg     40003e3b <waitpid+0x74>
		for (pid = 1; pid < 256; pid++)
40003e0c:	c7 45 08 01 00 00 00 	movl   $0x1,0x8(%ebp)
40003e13:	eb 1a                	jmp    40003e2f <waitpid+0x68>
			if (files->child[pid].state == PROC_FORKED)
40003e15:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003e1a:	8b 55 08             	mov    0x8(%ebp),%edx
40003e1d:	81 c2 04 1b 00 00    	add    $0x1b04,%edx
40003e23:	8b 04 90             	mov    (%eax,%edx,4),%eax
40003e26:	83 f8 01             	cmp    $0x1,%eax
40003e29:	74 0f                	je     40003e3a <waitpid+0x73>
	// Of course for interactive or load-balancing purposes
	// we would like to have a way to wait for
	// whichever child process happens to finish first -
	// that requires a (nondeterministic) kernel API extension.
	if (pid <= 0)
		for (pid = 1; pid < 256; pid++)
40003e2b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003e2f:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40003e36:	7e dd                	jle    40003e15 <waitpid+0x4e>
40003e38:	eb 01                	jmp    40003e3b <waitpid+0x74>
			if (files->child[pid].state == PROC_FORKED)
				break;
40003e3a:	90                   	nop
	if (pid == 256 || files->child[pid].state != PROC_FORKED) {
40003e3b:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
40003e42:	74 16                	je     40003e5a <waitpid+0x93>
40003e44:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003e49:	8b 55 08             	mov    0x8(%ebp),%edx
40003e4c:	81 c2 04 1b 00 00    	add    $0x1b04,%edx
40003e52:	8b 04 90             	mov    (%eax,%edx,4),%eax
40003e55:	83 f8 01             	cmp    $0x1,%eax
40003e58:	74 15                	je     40003e6f <waitpid+0xa8>
		errno = ECHILD;
40003e5a:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003e5f:	c7 00 09 00 00 00    	movl   $0x9,(%eax)
		return -1;
40003e65:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40003e6a:	e9 bb 01 00 00       	jmp    4000402a <waitpid+0x263>
	// Repeatedly synchronize with the chosen child until it exits.
	while (1) {
		// Wait for the child to finish whatever it's doing,
		// and extract its CPU and process/file state.
		struct procstate ps;
		sys_get(SYS_COPY | SYS_REGS, pid, &ps,
40003e6f:	8b 45 08             	mov    0x8(%ebp),%eax
40003e72:	0f b7 c0             	movzwl %ax,%eax
40003e75:	c7 45 dc 00 10 02 00 	movl   $0x21000,-0x24(%ebp)
40003e7c:	66 89 45 da          	mov    %ax,-0x26(%ebp)
40003e80:	8d 85 48 fd ff ff    	lea    -0x2b8(%ebp),%eax
40003e86:	89 45 d4             	mov    %eax,-0x2c(%ebp)
40003e89:	c7 45 d0 00 00 00 80 	movl   $0x80000000,-0x30(%ebp)
40003e90:	c7 45 cc 00 00 00 c0 	movl   $0xc0000000,-0x34(%ebp)
40003e97:	c7 45 c8 00 00 40 00 	movl   $0x400000,-0x38(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40003e9e:	8b 45 dc             	mov    -0x24(%ebp),%eax
40003ea1:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40003ea4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
40003ea7:	0f b7 55 da          	movzwl -0x26(%ebp),%edx
40003eab:	8b 75 d0             	mov    -0x30(%ebp),%esi
40003eae:	8b 7d cc             	mov    -0x34(%ebp),%edi
40003eb1:	8b 4d c8             	mov    -0x38(%ebp),%ecx
40003eb4:	cd 30                	int    $0x30
			(void*)FILESVA, (void*)VM_SCRATCHLO, PTSIZE);
		filestate *cfiles = (filestate*)VM_SCRATCHLO;
40003eb6:	c7 45 e4 00 00 00 c0 	movl   $0xc0000000,-0x1c(%ebp)

		// Did the child take a trap?
		if (ps.tf.trapno != T_SYSCALL) {
40003ebd:	8b 85 78 fd ff ff    	mov    -0x288(%ebp),%eax
40003ec3:	83 f8 30             	cmp    $0x30,%eax
40003ec6:	0f 84 b2 00 00 00    	je     40003f7e <waitpid+0x1b7>
			// Yes - terminate the child WITHOUT reconciling,
			// since the child's results are probably invalid.
			warn("child %d took trap %d, eip %x\n",
40003ecc:	8b 95 80 fd ff ff    	mov    -0x280(%ebp),%edx
40003ed2:	8b 85 78 fd ff ff    	mov    -0x288(%ebp),%eax
40003ed8:	89 54 24 14          	mov    %edx,0x14(%esp)
40003edc:	89 44 24 10          	mov    %eax,0x10(%esp)
40003ee0:	8b 45 08             	mov    0x8(%ebp),%eax
40003ee3:	89 44 24 0c          	mov    %eax,0xc(%esp)
40003ee7:	c7 44 24 08 14 62 00 	movl   $0x40006214,0x8(%esp)
40003eee:	40 
40003eef:	c7 44 24 04 8a 00 00 	movl   $0x8a,0x4(%esp)
40003ef6:	00 
40003ef7:	c7 04 24 dd 61 00 40 	movl   $0x400061dd,(%esp)
40003efe:	e8 ab cb ff ff       	call   40000aae <debug_warn>
				pid, ps.tf.trapno, ps.tf.eip);
			if (status != NULL)
40003f03:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40003f07:	74 13                	je     40003f1c <waitpid+0x155>
				*status = WSIGNALED | ps.tf.trapno;
40003f09:	8b 85 78 fd ff ff    	mov    -0x288(%ebp),%eax
40003f0f:	80 cc 02             	or     $0x2,%ah
40003f12:	89 c2                	mov    %eax,%edx
40003f14:	8b 45 0c             	mov    0xc(%ebp),%eax
40003f17:	89 10                	mov    %edx,(%eax)
40003f19:	eb 01                	jmp    40003f1c <waitpid+0x155>

		// Has the child exited gracefully?
		if (cfiles->exited) {
			if (status != NULL)
				*status = WEXITED | (cfiles->status & 0xff);
			goto done;
40003f1b:	90                   	nop
			if (status != NULL)
				*status = WSIGNALED | ps.tf.trapno;

			done:
			// Clear out the child's address space.
			sys_put(SYS_ZERO, pid, NULL, ALLVA, ALLVA, ALLSIZE);
40003f1c:	8b 45 08             	mov    0x8(%ebp),%eax
40003f1f:	0f b7 c0             	movzwl %ax,%eax
40003f22:	c7 45 c4 00 00 01 00 	movl   $0x10000,-0x3c(%ebp)
40003f29:	66 89 45 c2          	mov    %ax,-0x3e(%ebp)
40003f2d:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
40003f34:	c7 45 b8 00 00 00 40 	movl   $0x40000000,-0x48(%ebp)
40003f3b:	c7 45 b4 00 00 00 40 	movl   $0x40000000,-0x4c(%ebp)
40003f42:	c7 45 b0 00 00 00 b0 	movl   $0xb0000000,-0x50(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40003f49:	8b 45 c4             	mov    -0x3c(%ebp),%eax
40003f4c:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40003f4f:	8b 5d bc             	mov    -0x44(%ebp),%ebx
40003f52:	0f b7 55 c2          	movzwl -0x3e(%ebp),%edx
40003f56:	8b 75 b8             	mov    -0x48(%ebp),%esi
40003f59:	8b 7d b4             	mov    -0x4c(%ebp),%edi
40003f5c:	8b 4d b0             	mov    -0x50(%ebp),%ecx
40003f5f:	cd 30                	int    $0x30
			files->child[pid].state = PROC_FREE;
40003f61:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
40003f66:	8b 55 08             	mov    0x8(%ebp),%edx
40003f69:	81 c2 04 1b 00 00    	add    $0x1b04,%edx
40003f6f:	c7 04 90 00 00 00 00 	movl   $0x0,(%eax,%edx,4)
			return pid;
40003f76:	8b 45 08             	mov    0x8(%ebp),%eax
40003f79:	e9 ac 00 00 00       	jmp    4000402a <waitpid+0x263>
		}

		// Reconcile our file system state with the child's.
		bool didio = reconcile(pid, cfiles);
40003f7e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40003f81:	89 44 24 04          	mov    %eax,0x4(%esp)
40003f85:	8b 45 08             	mov    0x8(%ebp),%eax
40003f88:	89 04 24             	mov    %eax,(%esp)
40003f8b:	e8 a5 00 00 00       	call   40004035 <reconcile>
40003f90:	89 45 e0             	mov    %eax,-0x20(%ebp)

		// Has the child exited gracefully?
		if (cfiles->exited) {
40003f93:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40003f96:	8b 40 08             	mov    0x8(%eax),%eax
40003f99:	85 c0                	test   %eax,%eax
40003f9b:	74 24                	je     40003fc1 <waitpid+0x1fa>
			if (status != NULL)
40003f9d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40003fa1:	0f 84 74 ff ff ff    	je     40003f1b <waitpid+0x154>
				*status = WEXITED | (cfiles->status & 0xff);
40003fa7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40003faa:	8b 40 0c             	mov    0xc(%eax),%eax
40003fad:	25 ff 00 00 00       	and    $0xff,%eax
40003fb2:	89 c2                	mov    %eax,%edx
40003fb4:	80 ce 01             	or     $0x1,%dh
40003fb7:	8b 45 0c             	mov    0xc(%ebp),%eax
40003fba:	89 10                	mov    %edx,(%eax)
			goto done;
40003fbc:	e9 5a ff ff ff       	jmp    40003f1b <waitpid+0x154>
		}

		// If the child is waiting for new input
		// and the reconciliation above didn't provide anything new,
		// then wait for something new from OUR parent in turn.
		if (!didio)
40003fc1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
40003fc5:	75 07                	jne    40003fce <waitpid+0x207>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40003fc7:	b8 03 00 00 00       	mov    $0x3,%eax
40003fcc:	cd 30                	int    $0x30
			sys_ret();

		// Reconcile again, to forward any new I/O to the child.
		(void)reconcile(pid, cfiles);
40003fce:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40003fd1:	89 44 24 04          	mov    %eax,0x4(%esp)
40003fd5:	8b 45 08             	mov    0x8(%ebp),%eax
40003fd8:	89 04 24             	mov    %eax,(%esp)
40003fdb:	e8 55 00 00 00       	call   40004035 <reconcile>

		// Push the child's updated file state back into the child.
		sys_put(SYS_COPY | SYS_START, pid, NULL,
40003fe0:	8b 45 08             	mov    0x8(%ebp),%eax
40003fe3:	0f b7 c0             	movzwl %ax,%eax
40003fe6:	c7 45 ac 10 00 02 00 	movl   $0x20010,-0x54(%ebp)
40003fed:	66 89 45 aa          	mov    %ax,-0x56(%ebp)
40003ff1:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
40003ff8:	c7 45 a0 00 00 00 c0 	movl   $0xc0000000,-0x60(%ebp)
40003fff:	c7 45 9c 00 00 00 80 	movl   $0x80000000,-0x64(%ebp)
40004006:	c7 45 98 00 00 40 00 	movl   $0x400000,-0x68(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
4000400d:	8b 45 ac             	mov    -0x54(%ebp),%eax
40004010:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40004013:	8b 5d a4             	mov    -0x5c(%ebp),%ebx
40004016:	0f b7 55 aa          	movzwl -0x56(%ebp),%edx
4000401a:	8b 75 a0             	mov    -0x60(%ebp),%esi
4000401d:	8b 7d 9c             	mov    -0x64(%ebp),%edi
40004020:	8b 4d 98             	mov    -0x68(%ebp),%ecx
40004023:	cd 30                	int    $0x30
			(void*)VM_SCRATCHLO, (void*)FILESVA, PTSIZE);
	}
40004025:	e9 45 fe ff ff       	jmp    40003e6f <waitpid+0xa8>
}
4000402a:	81 c4 cc 02 00 00    	add    $0x2cc,%esp
40004030:	5b                   	pop    %ebx
40004031:	5e                   	pop    %esi
40004032:	5f                   	pop    %edi
40004033:	5d                   	pop    %ebp
40004034:	c3                   	ret    

40004035 <reconcile>:
// Reconcile our file system state, whose metadata is in 'files',
// with the file system state of child 'pid', whose metadata is in 'cfiles'.
// Returns nonzero if any changes were propagated, false otherwise.
bool
reconcile(pid_t pid, filestate *cfiles)
{
40004035:	55                   	push   %ebp
40004036:	89 e5                	mov    %esp,%ebp
40004038:	57                   	push   %edi
40004039:	56                   	push   %esi
4000403a:	53                   	push   %ebx
4000403b:	81 ec 6c 08 00 00    	sub    $0x86c,%esp
	bool didio = 0;
40004041:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int i;

	// Compute a parent-to-child and child-to-parent inode mapping table.
	int p2c[FILE_INODES], c2p[FILE_INODES];
	memset(p2c, 0, sizeof(p2c)); memset(c2p, 0, sizeof(c2p));
40004048:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
4000404f:	00 
40004050:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40004057:	00 
40004058:	8d 85 cc fb ff ff    	lea    -0x434(%ebp),%eax
4000405e:	89 04 24             	mov    %eax,(%esp)
40004061:	e8 0f d5 ff ff       	call   40001575 <memset>
40004066:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
4000406d:	00 
4000406e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40004075:	00 
40004076:	8d 85 cc f7 ff ff    	lea    -0x834(%ebp),%eax
4000407c:	89 04 24             	mov    %eax,(%esp)
4000407f:	e8 f1 d4 ff ff       	call   40001575 <memset>
	p2c[FILEINO_CONSIN] = c2p[FILEINO_CONSIN] = FILEINO_CONSIN;
40004084:	c7 85 d0 f7 ff ff 01 	movl   $0x1,-0x830(%ebp)
4000408b:	00 00 00 
4000408e:	8b 85 d0 f7 ff ff    	mov    -0x830(%ebp),%eax
40004094:	89 85 d0 fb ff ff    	mov    %eax,-0x430(%ebp)
	p2c[FILEINO_CONSOUT] = c2p[FILEINO_CONSOUT] = FILEINO_CONSOUT;
4000409a:	c7 85 d4 f7 ff ff 02 	movl   $0x2,-0x82c(%ebp)
400040a1:	00 00 00 
400040a4:	8b 85 d4 f7 ff ff    	mov    -0x82c(%ebp),%eax
400040aa:	89 85 d4 fb ff ff    	mov    %eax,-0x42c(%ebp)
	p2c[FILEINO_ROOTDIR] = c2p[FILEINO_ROOTDIR] = FILEINO_ROOTDIR;
400040b0:	c7 85 d8 f7 ff ff 03 	movl   $0x3,-0x828(%ebp)
400040b7:	00 00 00 
400040ba:	8b 85 d8 f7 ff ff    	mov    -0x828(%ebp),%eax
400040c0:	89 85 d8 fb ff ff    	mov    %eax,-0x428(%ebp)

	// First make sure all the child's allocated inodes
	// have a mapping in the parent, creating mappings as needed.
	// Also keep track of the parent inodes we find mappings for.
	int cino;
	for (cino = 1; cino < FILE_INODES; cino++) {
400040c6:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
400040cd:	e9 f3 01 00 00       	jmp    400042c5 <reconcile+0x290>
		fileinode *cfi = &cfiles->fi[cino];
400040d2:	8b 45 e0             	mov    -0x20(%ebp),%eax
400040d5:	6b c0 5c             	imul   $0x5c,%eax,%eax
400040d8:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400040de:	8b 45 0c             	mov    0xc(%ebp),%eax
400040e1:	01 d0                	add    %edx,%eax
400040e3:	89 45 d8             	mov    %eax,-0x28(%ebp)
		if (cfi->de.d_name[0] == 0)
400040e6:	8b 45 d8             	mov    -0x28(%ebp),%eax
400040e9:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400040ed:	84 c0                	test   %al,%al
400040ef:	0f 84 c5 01 00 00    	je     400042ba <reconcile+0x285>
			continue;	// not allocated in the child
		if (cfi->mode == 0 && cfi->rino == 0)
400040f5:	8b 45 d8             	mov    -0x28(%ebp),%eax
400040f8:	8b 40 48             	mov    0x48(%eax),%eax
400040fb:	85 c0                	test   %eax,%eax
400040fd:	75 0e                	jne    4000410d <reconcile+0xd8>
400040ff:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004102:	8b 40 50             	mov    0x50(%eax),%eax
40004105:	85 c0                	test   %eax,%eax
40004107:	0f 84 b0 01 00 00    	je     400042bd <reconcile+0x288>
			continue;	// existed only ephemerally in child
		if (cfi->rino == 0) {
4000410d:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004110:	8b 40 50             	mov    0x50(%eax),%eax
40004113:	85 c0                	test   %eax,%eax
40004115:	0f 85 88 00 00 00    	jne    400041a3 <reconcile+0x16e>
			// No corresponding parent inode known: find/create one.
			// The parent directory should already have a mapping.
			if (cfi->dino <= 0 || cfi->dino >= FILE_INODES
4000411b:	8b 45 d8             	mov    -0x28(%ebp),%eax
4000411e:	8b 00                	mov    (%eax),%eax
40004120:	85 c0                	test   %eax,%eax
40004122:	7e 1c                	jle    40004140 <reconcile+0x10b>
40004124:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004127:	8b 00                	mov    (%eax),%eax
40004129:	3d ff 00 00 00       	cmp    $0xff,%eax
4000412e:	7f 10                	jg     40004140 <reconcile+0x10b>
				|| c2p[cfi->dino] == 0) {
40004130:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004133:	8b 00                	mov    (%eax),%eax
40004135:	8b 84 85 cc f7 ff ff 	mov    -0x834(%ebp,%eax,4),%eax
4000413c:	85 c0                	test   %eax,%eax
4000413e:	75 28                	jne    40004168 <reconcile+0x133>
				warn("reconcile: cino %d has invalid parent",
40004140:	8b 45 e0             	mov    -0x20(%ebp),%eax
40004143:	89 44 24 0c          	mov    %eax,0xc(%esp)
40004147:	c7 44 24 08 34 62 00 	movl   $0x40006234,0x8(%esp)
4000414e:	40 
4000414f:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
40004156:	00 
40004157:	c7 04 24 dd 61 00 40 	movl   $0x400061dd,(%esp)
4000415e:	e8 4b c9 ff ff       	call   40000aae <debug_warn>
					cino);
				continue;	// don't reconcile it
40004163:	e9 59 01 00 00       	jmp    400042c1 <reconcile+0x28c>
			}
			cfi->rino = fileino_create(files, c2p[cfi->dino],
							cfi->de.d_name);
40004168:	8b 45 d8             	mov    -0x28(%ebp),%eax
4000416b:	8d 48 04             	lea    0x4(%eax),%ecx
				|| c2p[cfi->dino] == 0) {
				warn("reconcile: cino %d has invalid parent",
					cino);
				continue;	// don't reconcile it
			}
			cfi->rino = fileino_create(files, c2p[cfi->dino],
4000416e:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004171:	8b 00                	mov    (%eax),%eax
40004173:	8b 94 85 cc f7 ff ff 	mov    -0x834(%ebp,%eax,4),%edx
4000417a:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
4000417f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40004183:	89 54 24 04          	mov    %edx,0x4(%esp)
40004187:	89 04 24             	mov    %eax,(%esp)
4000418a:	e8 4f d6 ff ff       	call   400017de <fileino_create>
4000418f:	8b 55 d8             	mov    -0x28(%ebp),%edx
40004192:	89 42 50             	mov    %eax,0x50(%edx)
							cfi->de.d_name);
			if (cfi->rino <= 0)
40004195:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004198:	8b 40 50             	mov    0x50(%eax),%eax
4000419b:	85 c0                	test   %eax,%eax
4000419d:	0f 8e 1d 01 00 00    	jle    400042c0 <reconcile+0x28b>
		}

		// Check the validity of the child's existing mapping.
		// If something's fishy, just don't reconcile it,
		// since we don't want the child to kill the parent this way.
		int pino = cfi->rino;
400041a3:	8b 45 d8             	mov    -0x28(%ebp),%eax
400041a6:	8b 40 50             	mov    0x50(%eax),%eax
400041a9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		fileinode *pfi = &files->fi[pino];
400041ac:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400041b1:	8b 55 d4             	mov    -0x2c(%ebp),%edx
400041b4:	6b d2 5c             	imul   $0x5c,%edx,%edx
400041b7:	81 c2 10 10 00 00    	add    $0x1010,%edx
400041bd:	01 d0                	add    %edx,%eax
400041bf:	89 45 d0             	mov    %eax,-0x30(%ebp)
		if (pino <= 0 || pino >= FILE_INODES
400041c2:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
400041c6:	7e 5a                	jle    40004222 <reconcile+0x1ed>
400041c8:	81 7d d4 ff 00 00 00 	cmpl   $0xff,-0x2c(%ebp)
400041cf:	7f 51                	jg     40004222 <reconcile+0x1ed>
				|| p2c[pfi->dino] != cfi->dino
400041d1:	8b 45 d0             	mov    -0x30(%ebp),%eax
400041d4:	8b 00                	mov    (%eax),%eax
400041d6:	8b 94 85 cc fb ff ff 	mov    -0x434(%ebp,%eax,4),%edx
400041dd:	8b 45 d8             	mov    -0x28(%ebp),%eax
400041e0:	8b 00                	mov    (%eax),%eax
400041e2:	39 c2                	cmp    %eax,%edx
400041e4:	75 3c                	jne    40004222 <reconcile+0x1ed>
				|| strcmp(pfi->de.d_name, cfi->de.d_name) != 0
400041e6:	8b 45 d8             	mov    -0x28(%ebp),%eax
400041e9:	8d 50 04             	lea    0x4(%eax),%edx
400041ec:	8b 45 d0             	mov    -0x30(%ebp),%eax
400041ef:	83 c0 04             	add    $0x4,%eax
400041f2:	89 54 24 04          	mov    %edx,0x4(%esp)
400041f6:	89 04 24             	mov    %eax,(%esp)
400041f9:	e8 a6 d2 ff ff       	call   400014a4 <strcmp>
400041fe:	85 c0                	test   %eax,%eax
40004200:	75 20                	jne    40004222 <reconcile+0x1ed>
				|| cfi->rver > pfi->ver
40004202:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004205:	8b 50 54             	mov    0x54(%eax),%edx
40004208:	8b 45 d0             	mov    -0x30(%ebp),%eax
4000420b:	8b 40 44             	mov    0x44(%eax),%eax
4000420e:	39 c2                	cmp    %eax,%edx
40004210:	7f 10                	jg     40004222 <reconcile+0x1ed>
				|| cfi->rver > cfi->ver) {
40004212:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004215:	8b 50 54             	mov    0x54(%eax),%edx
40004218:	8b 45 d8             	mov    -0x28(%ebp),%eax
4000421b:	8b 40 44             	mov    0x44(%eax),%eax
4000421e:	39 c2                	cmp    %eax,%edx
40004220:	7e 7c                	jle    4000429e <reconcile+0x269>
			warn("reconcile: mapping %d/%d: "
40004222:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004225:	8b 70 54             	mov    0x54(%eax),%esi
40004228:	8b 45 d8             	mov    -0x28(%ebp),%eax
4000422b:	8b 58 44             	mov    0x44(%eax),%ebx
4000422e:	8b 45 d0             	mov    -0x30(%ebp),%eax
40004231:	8b 48 44             	mov    0x44(%eax),%ecx
40004234:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004237:	83 c0 04             	add    $0x4,%eax
4000423a:	89 85 c4 f7 ff ff    	mov    %eax,-0x83c(%ebp)
40004240:	8b 45 d0             	mov    -0x30(%ebp),%eax
40004243:	8d 78 04             	lea    0x4(%eax),%edi
40004246:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004249:	8b 10                	mov    (%eax),%edx
4000424b:	8b 45 d0             	mov    -0x30(%ebp),%eax
4000424e:	8b 00                	mov    (%eax),%eax
40004250:	89 74 24 2c          	mov    %esi,0x2c(%esp)
40004254:	89 5c 24 28          	mov    %ebx,0x28(%esp)
40004258:	89 4c 24 24          	mov    %ecx,0x24(%esp)
4000425c:	8b 8d c4 f7 ff ff    	mov    -0x83c(%ebp),%ecx
40004262:	89 4c 24 20          	mov    %ecx,0x20(%esp)
40004266:	89 7c 24 1c          	mov    %edi,0x1c(%esp)
4000426a:	89 54 24 18          	mov    %edx,0x18(%esp)
4000426e:	89 44 24 14          	mov    %eax,0x14(%esp)
40004272:	8b 45 e0             	mov    -0x20(%ebp),%eax
40004275:	89 44 24 10          	mov    %eax,0x10(%esp)
40004279:	8b 45 d4             	mov    -0x2c(%ebp),%eax
4000427c:	89 44 24 0c          	mov    %eax,0xc(%esp)
40004280:	c7 44 24 08 5c 62 00 	movl   $0x4000625c,0x8(%esp)
40004287:	40 
40004288:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
4000428f:	00 
40004290:	c7 04 24 dd 61 00 40 	movl   $0x400061dd,(%esp)
40004297:	e8 12 c8 ff ff       	call   40000aae <debug_warn>
				"dir %d/%d name %s/%s ver %d/%d(%d)",
				pino, cino, pfi->dino, cfi->dino,
				pfi->de.d_name, cfi->de.d_name,
				pfi->ver, cfi->ver, cfi->rver);
			continue;
4000429c:	eb 23                	jmp    400042c1 <reconcile+0x28c>
		}

		// Record the mapping.
		p2c[pino] = cino;
4000429e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
400042a1:	8b 55 e0             	mov    -0x20(%ebp),%edx
400042a4:	89 94 85 cc fb ff ff 	mov    %edx,-0x434(%ebp,%eax,4)
		c2p[cino] = pino;
400042ab:	8b 45 e0             	mov    -0x20(%ebp),%eax
400042ae:	8b 55 d4             	mov    -0x2c(%ebp),%edx
400042b1:	89 94 85 cc f7 ff ff 	mov    %edx,-0x834(%ebp,%eax,4)
400042b8:	eb 07                	jmp    400042c1 <reconcile+0x28c>
	// Also keep track of the parent inodes we find mappings for.
	int cino;
	for (cino = 1; cino < FILE_INODES; cino++) {
		fileinode *cfi = &cfiles->fi[cino];
		if (cfi->de.d_name[0] == 0)
			continue;	// not allocated in the child
400042ba:	90                   	nop
400042bb:	eb 04                	jmp    400042c1 <reconcile+0x28c>
		if (cfi->mode == 0 && cfi->rino == 0)
			continue;	// existed only ephemerally in child
400042bd:	90                   	nop
400042be:	eb 01                	jmp    400042c1 <reconcile+0x28c>
				continue;	// don't reconcile it
			}
			cfi->rino = fileino_create(files, c2p[cfi->dino],
							cfi->de.d_name);
			if (cfi->rino <= 0)
				continue;	// no free inodes!
400042c0:	90                   	nop

	// First make sure all the child's allocated inodes
	// have a mapping in the parent, creating mappings as needed.
	// Also keep track of the parent inodes we find mappings for.
	int cino;
	for (cino = 1; cino < FILE_INODES; cino++) {
400042c1:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
400042c5:	81 7d e0 ff 00 00 00 	cmpl   $0xff,-0x20(%ebp)
400042cc:	0f 8e 00 fe ff ff    	jle    400040d2 <reconcile+0x9d>
	}

	// Now make sure all the parent's allocated inodes
	// have a mapping in the child, creating mappings as needed.
	int pino;
	for (pino = 1; pino < FILE_INODES; pino++) {
400042d2:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
400042d9:	e9 a4 00 00 00       	jmp    40004382 <reconcile+0x34d>
		fileinode *pfi = &files->fi[pino];
400042de:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400042e3:	8b 55 dc             	mov    -0x24(%ebp),%edx
400042e6:	6b d2 5c             	imul   $0x5c,%edx,%edx
400042e9:	81 c2 10 10 00 00    	add    $0x1010,%edx
400042ef:	01 d0                	add    %edx,%eax
400042f1:	89 45 cc             	mov    %eax,-0x34(%ebp)
		if (pfi->de.d_name[0] == 0 || pfi->mode == 0)
400042f4:	8b 45 cc             	mov    -0x34(%ebp),%eax
400042f7:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400042fb:	84 c0                	test   %al,%al
400042fd:	74 78                	je     40004377 <reconcile+0x342>
400042ff:	8b 45 cc             	mov    -0x34(%ebp),%eax
40004302:	8b 40 48             	mov    0x48(%eax),%eax
40004305:	85 c0                	test   %eax,%eax
40004307:	74 6e                	je     40004377 <reconcile+0x342>
			continue; // not in use or already deleted
		if (p2c[pino] != 0)
40004309:	8b 45 dc             	mov    -0x24(%ebp),%eax
4000430c:	8b 84 85 cc fb ff ff 	mov    -0x434(%ebp,%eax,4),%eax
40004313:	85 c0                	test   %eax,%eax
40004315:	75 63                	jne    4000437a <reconcile+0x345>
			continue; // already mapped
		cino = fileino_create(cfiles, p2c[pfi->dino], pfi->de.d_name);
40004317:	8b 45 cc             	mov    -0x34(%ebp),%eax
4000431a:	8d 50 04             	lea    0x4(%eax),%edx
4000431d:	8b 45 cc             	mov    -0x34(%ebp),%eax
40004320:	8b 00                	mov    (%eax),%eax
40004322:	8b 84 85 cc fb ff ff 	mov    -0x434(%ebp,%eax,4),%eax
40004329:	89 54 24 08          	mov    %edx,0x8(%esp)
4000432d:	89 44 24 04          	mov    %eax,0x4(%esp)
40004331:	8b 45 0c             	mov    0xc(%ebp),%eax
40004334:	89 04 24             	mov    %eax,(%esp)
40004337:	e8 a2 d4 ff ff       	call   400017de <fileino_create>
4000433c:	89 45 e0             	mov    %eax,-0x20(%ebp)
		if (cino <= 0)
4000433f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
40004343:	7e 38                	jle    4000437d <reconcile+0x348>
			continue;	// no free inodes!
		cfiles->fi[cino].rino = pino;
40004345:	8b 55 0c             	mov    0xc(%ebp),%edx
40004348:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000434b:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000434e:	01 d0                	add    %edx,%eax
40004350:	8d 90 60 10 00 00    	lea    0x1060(%eax),%edx
40004356:	8b 45 dc             	mov    -0x24(%ebp),%eax
40004359:	89 02                	mov    %eax,(%edx)
		p2c[pino] = cino;
4000435b:	8b 45 dc             	mov    -0x24(%ebp),%eax
4000435e:	8b 55 e0             	mov    -0x20(%ebp),%edx
40004361:	89 94 85 cc fb ff ff 	mov    %edx,-0x434(%ebp,%eax,4)
		c2p[cino] = pino;
40004368:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000436b:	8b 55 dc             	mov    -0x24(%ebp),%edx
4000436e:	89 94 85 cc f7 ff ff 	mov    %edx,-0x834(%ebp,%eax,4)
40004375:	eb 07                	jmp    4000437e <reconcile+0x349>
	// have a mapping in the child, creating mappings as needed.
	int pino;
	for (pino = 1; pino < FILE_INODES; pino++) {
		fileinode *pfi = &files->fi[pino];
		if (pfi->de.d_name[0] == 0 || pfi->mode == 0)
			continue; // not in use or already deleted
40004377:	90                   	nop
40004378:	eb 04                	jmp    4000437e <reconcile+0x349>
		if (p2c[pino] != 0)
			continue; // already mapped
4000437a:	90                   	nop
4000437b:	eb 01                	jmp    4000437e <reconcile+0x349>
		cino = fileino_create(cfiles, p2c[pfi->dino], pfi->de.d_name);
		if (cino <= 0)
			continue;	// no free inodes!
4000437d:	90                   	nop
	}

	// Now make sure all the parent's allocated inodes
	// have a mapping in the child, creating mappings as needed.
	int pino;
	for (pino = 1; pino < FILE_INODES; pino++) {
4000437e:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
40004382:	81 7d dc ff 00 00 00 	cmpl   $0xff,-0x24(%ebp)
40004389:	0f 8e 4f ff ff ff    	jle    400042de <reconcile+0x2a9>
		p2c[pino] = cino;
		c2p[cino] = pino;
	}

	// Finally, reconcile each corresponding pair of inodes.
	for (pino = 1; pino < FILE_INODES; pino++) {
4000438f:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
40004396:	eb 78                	jmp    40004410 <reconcile+0x3db>
		if (!p2c[pino])
40004398:	8b 45 dc             	mov    -0x24(%ebp),%eax
4000439b:	8b 84 85 cc fb ff ff 	mov    -0x434(%ebp,%eax,4),%eax
400043a2:	85 c0                	test   %eax,%eax
400043a4:	74 65                	je     4000440b <reconcile+0x3d6>
			continue;	// no corresponding inode in child
		cino = p2c[pino];
400043a6:	8b 45 dc             	mov    -0x24(%ebp),%eax
400043a9:	8b 84 85 cc fb ff ff 	mov    -0x434(%ebp,%eax,4),%eax
400043b0:	89 45 e0             	mov    %eax,-0x20(%ebp)
		assert(c2p[cino] == pino);
400043b3:	8b 45 e0             	mov    -0x20(%ebp),%eax
400043b6:	8b 84 85 cc f7 ff ff 	mov    -0x834(%ebp,%eax,4),%eax
400043bd:	3b 45 dc             	cmp    -0x24(%ebp),%eax
400043c0:	74 24                	je     400043e6 <reconcile+0x3b1>
400043c2:	c7 44 24 0c 99 62 00 	movl   $0x40006299,0xc(%esp)
400043c9:	40 
400043ca:	c7 44 24 08 ff 61 00 	movl   $0x400061ff,0x8(%esp)
400043d1:	40 
400043d2:	c7 44 24 04 04 01 00 	movl   $0x104,0x4(%esp)
400043d9:	00 
400043da:	c7 04 24 dd 61 00 40 	movl   $0x400061dd,(%esp)
400043e1:	e8 5e c6 ff ff       	call   40000a44 <debug_panic>

		didio |= reconcile_inode(pid, cfiles, pino, cino);
400043e6:	8b 45 e0             	mov    -0x20(%ebp),%eax
400043e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
400043ed:	8b 45 dc             	mov    -0x24(%ebp),%eax
400043f0:	89 44 24 08          	mov    %eax,0x8(%esp)
400043f4:	8b 45 0c             	mov    0xc(%ebp),%eax
400043f7:	89 44 24 04          	mov    %eax,0x4(%esp)
400043fb:	8b 45 08             	mov    0x8(%ebp),%eax
400043fe:	89 04 24             	mov    %eax,(%esp)
40004401:	e8 25 00 00 00       	call   4000442b <reconcile_inode>
40004406:	09 45 e4             	or     %eax,-0x1c(%ebp)
40004409:	eb 01                	jmp    4000440c <reconcile+0x3d7>
	}

	// Finally, reconcile each corresponding pair of inodes.
	for (pino = 1; pino < FILE_INODES; pino++) {
		if (!p2c[pino])
			continue;	// no corresponding inode in child
4000440b:	90                   	nop
		p2c[pino] = cino;
		c2p[cino] = pino;
	}

	// Finally, reconcile each corresponding pair of inodes.
	for (pino = 1; pino < FILE_INODES; pino++) {
4000440c:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
40004410:	81 7d dc ff 00 00 00 	cmpl   $0xff,-0x24(%ebp)
40004417:	0f 8e 7b ff ff ff    	jle    40004398 <reconcile+0x363>
		assert(c2p[cino] == pino);

		didio |= reconcile_inode(pid, cfiles, pino, cino);
	}

	return didio;
4000441d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
}
40004420:	81 c4 6c 08 00 00    	add    $0x86c,%esp
40004426:	5b                   	pop    %ebx
40004427:	5e                   	pop    %esi
40004428:	5f                   	pop    %edi
40004429:	5d                   	pop    %ebp
4000442a:	c3                   	ret    

4000442b <reconcile_inode>:

bool
reconcile_inode(pid_t pid, filestate *cfiles, int pino, int cino)
{
4000442b:	55                   	push   %ebp
4000442c:	89 e5                	mov    %esp,%ebp
4000442e:	57                   	push   %edi
4000442f:	56                   	push   %esi
40004430:	53                   	push   %ebx
40004431:	83 ec 5c             	sub    $0x5c,%esp
	assert(pino > 0 && pino < FILE_INODES);
40004434:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40004438:	7e 09                	jle    40004443 <reconcile_inode+0x18>
4000443a:	81 7d 10 ff 00 00 00 	cmpl   $0xff,0x10(%ebp)
40004441:	7e 24                	jle    40004467 <reconcile_inode+0x3c>
40004443:	c7 44 24 0c ac 62 00 	movl   $0x400062ac,0xc(%esp)
4000444a:	40 
4000444b:	c7 44 24 08 ff 61 00 	movl   $0x400061ff,0x8(%esp)
40004452:	40 
40004453:	c7 44 24 04 0f 01 00 	movl   $0x10f,0x4(%esp)
4000445a:	00 
4000445b:	c7 04 24 dd 61 00 40 	movl   $0x400061dd,(%esp)
40004462:	e8 dd c5 ff ff       	call   40000a44 <debug_panic>
	assert(cino > 0 && cino < FILE_INODES);
40004467:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
4000446b:	7e 09                	jle    40004476 <reconcile_inode+0x4b>
4000446d:	81 7d 14 ff 00 00 00 	cmpl   $0xff,0x14(%ebp)
40004474:	7e 24                	jle    4000449a <reconcile_inode+0x6f>
40004476:	c7 44 24 0c cc 62 00 	movl   $0x400062cc,0xc(%esp)
4000447d:	40 
4000447e:	c7 44 24 08 ff 61 00 	movl   $0x400061ff,0x8(%esp)
40004485:	40 
40004486:	c7 44 24 04 10 01 00 	movl   $0x110,0x4(%esp)
4000448d:	00 
4000448e:	c7 04 24 dd 61 00 40 	movl   $0x400061dd,(%esp)
40004495:	e8 aa c5 ff ff       	call   40000a44 <debug_panic>
	fileinode *pfi = &files->fi[pino];
4000449a:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
4000449f:	8b 55 10             	mov    0x10(%ebp),%edx
400044a2:	6b d2 5c             	imul   $0x5c,%edx,%edx
400044a5:	81 c2 10 10 00 00    	add    $0x1010,%edx
400044ab:	01 d0                	add    %edx,%eax
400044ad:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	fileinode *cfi = &cfiles->fi[cino];
400044b0:	8b 45 14             	mov    0x14(%ebp),%eax
400044b3:	6b c0 5c             	imul   $0x5c,%eax,%eax
400044b6:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400044bc:	8b 45 0c             	mov    0xc(%ebp),%eax
400044bf:	01 d0                	add    %edx,%eax
400044c1:	89 45 e0             	mov    %eax,-0x20(%ebp)

	// Find the reference version number and length for reconciliation
	int rver = cfi->rver;
400044c4:	8b 45 e0             	mov    -0x20(%ebp),%eax
400044c7:	8b 40 54             	mov    0x54(%eax),%eax
400044ca:	89 45 dc             	mov    %eax,-0x24(%ebp)
	int rlen = cfi->rlen;
400044cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
400044d0:	8b 40 58             	mov    0x58(%eax),%eax
400044d3:	89 45 d8             	mov    %eax,-0x28(%ebp)

	// Check some invariants that should hold between
	// the parent's and child's current version numbers and lengths
	// and the reference version number and length stored in the child.
	// XXX should protect the parent better from state corruption by child.
	assert(cfi->ver >= rver);	// version # only increases
400044d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
400044d9:	8b 40 44             	mov    0x44(%eax),%eax
400044dc:	3b 45 dc             	cmp    -0x24(%ebp),%eax
400044df:	7d 24                	jge    40004505 <reconcile_inode+0xda>
400044e1:	c7 44 24 0c eb 62 00 	movl   $0x400062eb,0xc(%esp)
400044e8:	40 
400044e9:	c7 44 24 08 ff 61 00 	movl   $0x400061ff,0x8(%esp)
400044f0:	40 
400044f1:	c7 44 24 04 1c 01 00 	movl   $0x11c,0x4(%esp)
400044f8:	00 
400044f9:	c7 04 24 dd 61 00 40 	movl   $0x400061dd,(%esp)
40004500:	e8 3f c5 ff ff       	call   40000a44 <debug_panic>
	assert(pfi->ver >= rver);
40004505:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004508:	8b 40 44             	mov    0x44(%eax),%eax
4000450b:	3b 45 dc             	cmp    -0x24(%ebp),%eax
4000450e:	7d 24                	jge    40004534 <reconcile_inode+0x109>
40004510:	c7 44 24 0c fc 62 00 	movl   $0x400062fc,0xc(%esp)
40004517:	40 
40004518:	c7 44 24 08 ff 61 00 	movl   $0x400061ff,0x8(%esp)
4000451f:	40 
40004520:	c7 44 24 04 1d 01 00 	movl   $0x11d,0x4(%esp)
40004527:	00 
40004528:	c7 04 24 dd 61 00 40 	movl   $0x400061dd,(%esp)
4000452f:	e8 10 c5 ff ff       	call   40000a44 <debug_panic>
	if (cfi->ver == rver)		// within a version, length only grows
40004534:	8b 45 e0             	mov    -0x20(%ebp),%eax
40004537:	8b 40 44             	mov    0x44(%eax),%eax
4000453a:	3b 45 dc             	cmp    -0x24(%ebp),%eax
4000453d:	75 31                	jne    40004570 <reconcile_inode+0x145>
		assert(cfi->size >= rlen);
4000453f:	8b 45 e0             	mov    -0x20(%ebp),%eax
40004542:	8b 50 4c             	mov    0x4c(%eax),%edx
40004545:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004548:	39 c2                	cmp    %eax,%edx
4000454a:	73 24                	jae    40004570 <reconcile_inode+0x145>
4000454c:	c7 44 24 0c 0d 63 00 	movl   $0x4000630d,0xc(%esp)
40004553:	40 
40004554:	c7 44 24 08 ff 61 00 	movl   $0x400061ff,0x8(%esp)
4000455b:	40 
4000455c:	c7 44 24 04 1f 01 00 	movl   $0x11f,0x4(%esp)
40004563:	00 
40004564:	c7 04 24 dd 61 00 40 	movl   $0x400061dd,(%esp)
4000456b:	e8 d4 c4 ff ff       	call   40000a44 <debug_panic>
	if (pfi->ver == rver)
40004570:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004573:	8b 40 44             	mov    0x44(%eax),%eax
40004576:	3b 45 dc             	cmp    -0x24(%ebp),%eax
40004579:	75 31                	jne    400045ac <reconcile_inode+0x181>
		assert(pfi->size >= rlen);
4000457b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000457e:	8b 50 4c             	mov    0x4c(%eax),%edx
40004581:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004584:	39 c2                	cmp    %eax,%edx
40004586:	73 24                	jae    400045ac <reconcile_inode+0x181>
40004588:	c7 44 24 0c 1f 63 00 	movl   $0x4000631f,0xc(%esp)
4000458f:	40 
40004590:	c7 44 24 08 ff 61 00 	movl   $0x400061ff,0x8(%esp)
40004597:	40 
40004598:	c7 44 24 04 21 01 00 	movl   $0x121,0x4(%esp)
4000459f:	00 
400045a0:	c7 04 24 dd 61 00 40 	movl   $0x400061dd,(%esp)
400045a7:	e8 98 c4 ff ff       	call   40000a44 <debug_panic>
	// and the other process has NOT bumped its inode's version number
	// but has performed append-only writes increasing the file's length,
	// that situation still constitutes a conflict
	// because we don't have a clean way to resolve it automatically.
	//warn("reconcile_inode not implemented");
	if(pfi->ver == cfi->rver && cfi->ver == cfi->rver){
400045ac:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400045af:	8b 50 44             	mov    0x44(%eax),%edx
400045b2:	8b 45 e0             	mov    -0x20(%ebp),%eax
400045b5:	8b 40 54             	mov    0x54(%eax),%eax
400045b8:	39 c2                	cmp    %eax,%edx
400045ba:	75 35                	jne    400045f1 <reconcile_inode+0x1c6>
400045bc:	8b 45 e0             	mov    -0x20(%ebp),%eax
400045bf:	8b 50 44             	mov    0x44(%eax),%edx
400045c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
400045c5:	8b 40 54             	mov    0x54(%eax),%eax
400045c8:	39 c2                	cmp    %eax,%edx
400045ca:	75 25                	jne    400045f1 <reconcile_inode+0x1c6>
		return reconcile_merge(pid, cfiles, pino, cino);
400045cc:	8b 45 14             	mov    0x14(%ebp),%eax
400045cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
400045d3:	8b 45 10             	mov    0x10(%ebp),%eax
400045d6:	89 44 24 08          	mov    %eax,0x8(%esp)
400045da:	8b 45 0c             	mov    0xc(%ebp),%eax
400045dd:	89 44 24 04          	mov    %eax,0x4(%esp)
400045e1:	8b 45 08             	mov    0x8(%ebp),%eax
400045e4:	89 04 24             	mov    %eax,(%esp)
400045e7:	e8 b0 01 00 00       	call   4000479c <reconcile_merge>
400045ec:	e9 a3 01 00 00       	jmp    40004794 <reconcile_inode+0x369>
	}
	if((pfi->ver > cfi->rver || pfi->size > cfi->rlen) && (cfi->ver > cfi->rver || cfi->size > cfi->rlen)){
400045f1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400045f4:	8b 50 44             	mov    0x44(%eax),%edx
400045f7:	8b 45 e0             	mov    -0x20(%ebp),%eax
400045fa:	8b 40 54             	mov    0x54(%eax),%eax
400045fd:	39 c2                	cmp    %eax,%edx
400045ff:	7f 10                	jg     40004611 <reconcile_inode+0x1e6>
40004601:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004604:	8b 50 4c             	mov    0x4c(%eax),%edx
40004607:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000460a:	8b 40 58             	mov    0x58(%eax),%eax
4000460d:	39 c2                	cmp    %eax,%edx
4000460f:	76 52                	jbe    40004663 <reconcile_inode+0x238>
40004611:	8b 45 e0             	mov    -0x20(%ebp),%eax
40004614:	8b 50 44             	mov    0x44(%eax),%edx
40004617:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000461a:	8b 40 54             	mov    0x54(%eax),%eax
4000461d:	39 c2                	cmp    %eax,%edx
4000461f:	7f 10                	jg     40004631 <reconcile_inode+0x206>
40004621:	8b 45 e0             	mov    -0x20(%ebp),%eax
40004624:	8b 50 4c             	mov    0x4c(%eax),%edx
40004627:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000462a:	8b 40 58             	mov    0x58(%eax),%eax
4000462d:	39 c2                	cmp    %eax,%edx
4000462f:	76 32                	jbe    40004663 <reconcile_inode+0x238>
		pfi->mode |= S_IFCONF;
40004631:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004634:	8b 40 48             	mov    0x48(%eax),%eax
40004637:	89 c2                	mov    %eax,%edx
40004639:	81 ca 00 00 01 00    	or     $0x10000,%edx
4000463f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004642:	89 50 48             	mov    %edx,0x48(%eax)
		cfi->mode |= S_IFCONF;
40004645:	8b 45 e0             	mov    -0x20(%ebp),%eax
40004648:	8b 40 48             	mov    0x48(%eax),%eax
4000464b:	89 c2                	mov    %eax,%edx
4000464d:	81 ca 00 00 01 00    	or     $0x10000,%edx
40004653:	8b 45 e0             	mov    -0x20(%ebp),%eax
40004656:	89 50 48             	mov    %edx,0x48(%eax)
		return 1;
40004659:	b8 01 00 00 00       	mov    $0x1,%eax
4000465e:	e9 31 01 00 00       	jmp    40004794 <reconcile_inode+0x369>
	}
	if(pfi->ver > cfi->rver || pfi->size > cfi->rlen){
40004663:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004666:	8b 50 44             	mov    0x44(%eax),%edx
40004669:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000466c:	8b 40 54             	mov    0x54(%eax),%eax
4000466f:	39 c2                	cmp    %eax,%edx
40004671:	7f 10                	jg     40004683 <reconcile_inode+0x258>
40004673:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004676:	8b 50 4c             	mov    0x4c(%eax),%edx
40004679:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000467c:	8b 40 58             	mov    0x58(%eax),%eax
4000467f:	39 c2                	cmp    %eax,%edx
40004681:	76 7b                	jbe    400046fe <reconcile_inode+0x2d3>
		sys_put(SYS_COPY, pid, NULL, FILEDATA(pino),FILEDATA(cino),FILE_MAXSIZE);
40004683:	8b 45 14             	mov    0x14(%ebp),%eax
40004686:	c1 e0 16             	shl    $0x16,%eax
40004689:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
4000468f:	8b 45 10             	mov    0x10(%ebp),%eax
40004692:	c1 e0 16             	shl    $0x16,%eax
40004695:	8d 88 00 00 00 80    	lea    -0x80000000(%eax),%ecx
4000469b:	8b 45 08             	mov    0x8(%ebp),%eax
4000469e:	0f b7 c0             	movzwl %ax,%eax
400046a1:	c7 45 d4 00 00 02 00 	movl   $0x20000,-0x2c(%ebp)
400046a8:	66 89 45 d2          	mov    %ax,-0x2e(%ebp)
400046ac:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
400046b3:	89 4d c8             	mov    %ecx,-0x38(%ebp)
400046b6:	89 55 c4             	mov    %edx,-0x3c(%ebp)
400046b9:	c7 45 c0 00 00 40 00 	movl   $0x400000,-0x40(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
400046c0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
400046c3:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400046c6:	8b 5d cc             	mov    -0x34(%ebp),%ebx
400046c9:	0f b7 55 d2          	movzwl -0x2e(%ebp),%edx
400046cd:	8b 75 c8             	mov    -0x38(%ebp),%esi
400046d0:	8b 7d c4             	mov    -0x3c(%ebp),%edi
400046d3:	8b 4d c0             	mov    -0x40(%ebp),%ecx
400046d6:	cd 30                	int    $0x30
		cfi->mode = pfi->mode;
400046d8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400046db:	8b 50 48             	mov    0x48(%eax),%edx
400046de:	8b 45 e0             	mov    -0x20(%ebp),%eax
400046e1:	89 50 48             	mov    %edx,0x48(%eax)
		cfi->ver = pfi->ver;
400046e4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400046e7:	8b 50 44             	mov    0x44(%eax),%edx
400046ea:	8b 45 e0             	mov    -0x20(%ebp),%eax
400046ed:	89 50 44             	mov    %edx,0x44(%eax)
		cfi->size = pfi->size;
400046f0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400046f3:	8b 50 4c             	mov    0x4c(%eax),%edx
400046f6:	8b 45 e0             	mov    -0x20(%ebp),%eax
400046f9:	89 50 4c             	mov    %edx,0x4c(%eax)
400046fc:	eb 79                	jmp    40004777 <reconcile_inode+0x34c>
	}else{
		sys_get(SYS_COPY, pid, NULL, FILEDATA(cino),FILEDATA(pino), FILE_MAXSIZE);
400046fe:	8b 45 10             	mov    0x10(%ebp),%eax
40004701:	c1 e0 16             	shl    $0x16,%eax
40004704:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
4000470a:	8b 45 14             	mov    0x14(%ebp),%eax
4000470d:	c1 e0 16             	shl    $0x16,%eax
40004710:	8d 88 00 00 00 80    	lea    -0x80000000(%eax),%ecx
40004716:	8b 45 08             	mov    0x8(%ebp),%eax
40004719:	0f b7 c0             	movzwl %ax,%eax
4000471c:	c7 45 bc 00 00 02 00 	movl   $0x20000,-0x44(%ebp)
40004723:	66 89 45 ba          	mov    %ax,-0x46(%ebp)
40004727:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)
4000472e:	89 4d b0             	mov    %ecx,-0x50(%ebp)
40004731:	89 55 ac             	mov    %edx,-0x54(%ebp)
40004734:	c7 45 a8 00 00 40 00 	movl   $0x400000,-0x58(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
4000473b:	8b 45 bc             	mov    -0x44(%ebp),%eax
4000473e:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40004741:	8b 5d b4             	mov    -0x4c(%ebp),%ebx
40004744:	0f b7 55 ba          	movzwl -0x46(%ebp),%edx
40004748:	8b 75 b0             	mov    -0x50(%ebp),%esi
4000474b:	8b 7d ac             	mov    -0x54(%ebp),%edi
4000474e:	8b 4d a8             	mov    -0x58(%ebp),%ecx
40004751:	cd 30                	int    $0x30
		pfi->mode = cfi->mode;
40004753:	8b 45 e0             	mov    -0x20(%ebp),%eax
40004756:	8b 50 48             	mov    0x48(%eax),%edx
40004759:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000475c:	89 50 48             	mov    %edx,0x48(%eax)
		pfi->ver = cfi->ver;
4000475f:	8b 45 e0             	mov    -0x20(%ebp),%eax
40004762:	8b 50 44             	mov    0x44(%eax),%edx
40004765:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004768:	89 50 44             	mov    %edx,0x44(%eax)
		pfi->size = cfi->size;
4000476b:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000476e:	8b 50 4c             	mov    0x4c(%eax),%edx
40004771:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004774:	89 50 4c             	mov    %edx,0x4c(%eax)
	}
	cfi->rver = pfi->ver;
40004777:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000477a:	8b 50 44             	mov    0x44(%eax),%edx
4000477d:	8b 45 e0             	mov    -0x20(%ebp),%eax
40004780:	89 50 54             	mov    %edx,0x54(%eax)
	cfi->rlen = pfi->size;
40004783:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004786:	8b 50 4c             	mov    0x4c(%eax),%edx
40004789:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000478c:	89 50 58             	mov    %edx,0x58(%eax)
	return 1;
4000478f:	b8 01 00 00 00       	mov    $0x1,%eax
}
40004794:	83 c4 5c             	add    $0x5c,%esp
40004797:	5b                   	pop    %ebx
40004798:	5e                   	pop    %esi
40004799:	5f                   	pop    %edi
4000479a:	5d                   	pop    %ebp
4000479b:	c3                   	ret    

4000479c <reconcile_merge>:

bool
reconcile_merge(pid_t pid, filestate *cfiles, int pino, int cino)
{
4000479c:	55                   	push   %ebp
4000479d:	89 e5                	mov    %esp,%ebp
4000479f:	57                   	push   %edi
400047a0:	56                   	push   %esi
400047a1:	53                   	push   %ebx
400047a2:	83 ec 6c             	sub    $0x6c,%esp
	fileinode *pfi = &files->fi[pino];
400047a5:	a1 3c 5d 00 40       	mov    0x40005d3c,%eax
400047aa:	8b 55 10             	mov    0x10(%ebp),%edx
400047ad:	6b d2 5c             	imul   $0x5c,%edx,%edx
400047b0:	81 c2 10 10 00 00    	add    $0x1010,%edx
400047b6:	01 d0                	add    %edx,%eax
400047b8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	fileinode *cfi = &cfiles->fi[cino];
400047bb:	8b 45 14             	mov    0x14(%ebp),%eax
400047be:	6b c0 5c             	imul   $0x5c,%eax,%eax
400047c1:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400047c7:	8b 45 0c             	mov    0xc(%ebp),%eax
400047ca:	01 d0                	add    %edx,%eax
400047cc:	89 45 e0             	mov    %eax,-0x20(%ebp)
	assert(pino > 0 && pino < FILE_INODES);
400047cf:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400047d3:	7e 09                	jle    400047de <reconcile_merge+0x42>
400047d5:	81 7d 10 ff 00 00 00 	cmpl   $0xff,0x10(%ebp)
400047dc:	7e 24                	jle    40004802 <reconcile_merge+0x66>
400047de:	c7 44 24 0c ac 62 00 	movl   $0x400062ac,0xc(%esp)
400047e5:	40 
400047e6:	c7 44 24 08 ff 61 00 	movl   $0x400061ff,0x8(%esp)
400047ed:	40 
400047ee:	c7 44 24 04 4e 01 00 	movl   $0x14e,0x4(%esp)
400047f5:	00 
400047f6:	c7 04 24 dd 61 00 40 	movl   $0x400061dd,(%esp)
400047fd:	e8 42 c2 ff ff       	call   40000a44 <debug_panic>
	assert(cino > 0 && cino < FILE_INODES);
40004802:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40004806:	7e 09                	jle    40004811 <reconcile_merge+0x75>
40004808:	81 7d 14 ff 00 00 00 	cmpl   $0xff,0x14(%ebp)
4000480f:	7e 24                	jle    40004835 <reconcile_merge+0x99>
40004811:	c7 44 24 0c cc 62 00 	movl   $0x400062cc,0xc(%esp)
40004818:	40 
40004819:	c7 44 24 08 ff 61 00 	movl   $0x400061ff,0x8(%esp)
40004820:	40 
40004821:	c7 44 24 04 4f 01 00 	movl   $0x14f,0x4(%esp)
40004828:	00 
40004829:	c7 04 24 dd 61 00 40 	movl   $0x400061dd,(%esp)
40004830:	e8 0f c2 ff ff       	call   40000a44 <debug_panic>
	assert(pfi->ver == cfi->ver);
40004835:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004838:	8b 50 44             	mov    0x44(%eax),%edx
4000483b:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000483e:	8b 40 44             	mov    0x44(%eax),%eax
40004841:	39 c2                	cmp    %eax,%edx
40004843:	74 24                	je     40004869 <reconcile_merge+0xcd>
40004845:	c7 44 24 0c 31 63 00 	movl   $0x40006331,0xc(%esp)
4000484c:	40 
4000484d:	c7 44 24 08 ff 61 00 	movl   $0x400061ff,0x8(%esp)
40004854:	40 
40004855:	c7 44 24 04 50 01 00 	movl   $0x150,0x4(%esp)
4000485c:	00 
4000485d:	c7 04 24 dd 61 00 40 	movl   $0x400061dd,(%esp)
40004864:	e8 db c1 ff ff       	call   40000a44 <debug_panic>
	assert(pfi->mode == cfi->mode);
40004869:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000486c:	8b 50 48             	mov    0x48(%eax),%edx
4000486f:	8b 45 e0             	mov    -0x20(%ebp),%eax
40004872:	8b 40 48             	mov    0x48(%eax),%eax
40004875:	39 c2                	cmp    %eax,%edx
40004877:	74 24                	je     4000489d <reconcile_merge+0x101>
40004879:	c7 44 24 0c 46 63 00 	movl   $0x40006346,0xc(%esp)
40004880:	40 
40004881:	c7 44 24 08 ff 61 00 	movl   $0x400061ff,0x8(%esp)
40004888:	40 
40004889:	c7 44 24 04 51 01 00 	movl   $0x151,0x4(%esp)
40004890:	00 
40004891:	c7 04 24 dd 61 00 40 	movl   $0x400061dd,(%esp)
40004898:	e8 a7 c1 ff ff       	call   40000a44 <debug_panic>

	if (!S_ISREG(pfi->mode))
4000489d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400048a0:	8b 40 48             	mov    0x48(%eax),%eax
400048a3:	25 00 70 00 00       	and    $0x7000,%eax
400048a8:	3d 00 10 00 00       	cmp    $0x1000,%eax
400048ad:	74 0a                	je     400048b9 <reconcile_merge+0x11d>
		return 0;	// only regular files have data to merge
400048af:	b8 00 00 00 00       	mov    $0x0,%eax
400048b4:	e9 8f 01 00 00       	jmp    40004a48 <reconcile_merge+0x2ac>
	// copy the parent's appends since last reconciliation into the child,
	// and the child's appends since last reconciliation into the parent.
	// Parent and child should be left with files of the same size,
	// although the writes they contain may be in a different order.
	// warn("reconcile_merge not implemented");
	if((pfi->size == cfi->rlen) && (cfi->size == cfi->rlen))
400048b9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400048bc:	8b 50 4c             	mov    0x4c(%eax),%edx
400048bf:	8b 45 e0             	mov    -0x20(%ebp),%eax
400048c2:	8b 40 58             	mov    0x58(%eax),%eax
400048c5:	39 c2                	cmp    %eax,%edx
400048c7:	75 1a                	jne    400048e3 <reconcile_merge+0x147>
400048c9:	8b 45 e0             	mov    -0x20(%ebp),%eax
400048cc:	8b 50 4c             	mov    0x4c(%eax),%edx
400048cf:	8b 45 e0             	mov    -0x20(%ebp),%eax
400048d2:	8b 40 58             	mov    0x58(%eax),%eax
400048d5:	39 c2                	cmp    %eax,%edx
400048d7:	75 0a                	jne    400048e3 <reconcile_merge+0x147>
		return 1;
400048d9:	b8 01 00 00 00       	mov    $0x1,%eax
400048de:	e9 65 01 00 00       	jmp    40004a48 <reconcile_merge+0x2ac>

	void* tmpmem = (void*)(VM_SCRATCHLO + PTSIZE);	//Can't use VM_SCRATCHLO, cause the child process may use it for load elf concurrently..
400048e3:	c7 45 dc 00 00 40 c0 	movl   $0xc0400000,-0x24(%ebp)
	size_t cgrow = cfi->size - cfi->rlen;
400048ea:	8b 45 e0             	mov    -0x20(%ebp),%eax
400048ed:	8b 50 4c             	mov    0x4c(%eax),%edx
400048f0:	8b 45 e0             	mov    -0x20(%ebp),%eax
400048f3:	8b 40 58             	mov    0x58(%eax),%eax
400048f6:	89 d1                	mov    %edx,%ecx
400048f8:	29 c1                	sub    %eax,%ecx
400048fa:	89 c8                	mov    %ecx,%eax
400048fc:	89 45 d8             	mov    %eax,-0x28(%ebp)
	size_t pgrow = pfi->size - cfi->rlen;
400048ff:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004902:	8b 50 4c             	mov    0x4c(%eax),%edx
40004905:	8b 45 e0             	mov    -0x20(%ebp),%eax
40004908:	8b 40 58             	mov    0x58(%eax),%eax
4000490b:	89 d1                	mov    %edx,%ecx
4000490d:	29 c1                	sub    %eax,%ecx
4000490f:	89 c8                	mov    %ecx,%eax
40004911:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	size_t newlen = cfi->rlen + cgrow + pgrow;
40004914:	8b 45 e0             	mov    -0x20(%ebp),%eax
40004917:	8b 50 58             	mov    0x58(%eax),%edx
4000491a:	8b 45 d8             	mov    -0x28(%ebp),%eax
4000491d:	01 c2                	add    %eax,%edx
4000491f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40004922:	01 d0                	add    %edx,%eax
40004924:	89 45 d0             	mov    %eax,-0x30(%ebp)

	sys_get(SYS_COPY, pid, NULL, FILEDATA(cino), tmpmem, FILE_MAXSIZE);
40004927:	8b 45 14             	mov    0x14(%ebp),%eax
4000492a:	c1 e0 16             	shl    $0x16,%eax
4000492d:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
40004933:	8b 45 08             	mov    0x8(%ebp),%eax
40004936:	0f b7 c0             	movzwl %ax,%eax
40004939:	c7 45 cc 00 00 02 00 	movl   $0x20000,-0x34(%ebp)
40004940:	66 89 45 ca          	mov    %ax,-0x36(%ebp)
40004944:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)
4000494b:	89 55 c0             	mov    %edx,-0x40(%ebp)
4000494e:	8b 45 dc             	mov    -0x24(%ebp),%eax
40004951:	89 45 bc             	mov    %eax,-0x44(%ebp)
40004954:	c7 45 b8 00 00 40 00 	movl   $0x400000,-0x48(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
4000495b:	8b 45 cc             	mov    -0x34(%ebp),%eax
4000495e:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40004961:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
40004964:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
40004968:	8b 75 c0             	mov    -0x40(%ebp),%esi
4000496b:	8b 7d bc             	mov    -0x44(%ebp),%edi
4000496e:	8b 4d b8             	mov    -0x48(%ebp),%ecx
40004971:	cd 30                	int    $0x30
	memcpy(FILEDATA(pino) + pfi->size, tmpmem + cfi->rlen, cgrow);
40004973:	8b 45 e0             	mov    -0x20(%ebp),%eax
40004976:	8b 50 58             	mov    0x58(%eax),%edx
40004979:	8b 45 dc             	mov    -0x24(%ebp),%eax
4000497c:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
4000497f:	8b 45 10             	mov    0x10(%ebp),%eax
40004982:	c1 e0 16             	shl    $0x16,%eax
40004985:	89 c2                	mov    %eax,%edx
40004987:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000498a:	8b 40 4c             	mov    0x4c(%eax),%eax
4000498d:	01 d0                	add    %edx,%eax
4000498f:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
40004995:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004998:	89 44 24 08          	mov    %eax,0x8(%esp)
4000499c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
400049a0:	89 14 24             	mov    %edx,(%esp)
400049a3:	e8 15 cd ff ff       	call   400016bd <memcpy>
	memcpy(tmpmem + cfi->size, FILEDATA(pino) + pfi->rlen, pgrow);
400049a8:	8b 45 10             	mov    0x10(%ebp),%eax
400049ab:	c1 e0 16             	shl    $0x16,%eax
400049ae:	89 c2                	mov    %eax,%edx
400049b0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400049b3:	8b 40 58             	mov    0x58(%eax),%eax
400049b6:	01 d0                	add    %edx,%eax
400049b8:	8d 88 00 00 00 80    	lea    -0x80000000(%eax),%ecx
400049be:	8b 45 e0             	mov    -0x20(%ebp),%eax
400049c1:	8b 50 4c             	mov    0x4c(%eax),%edx
400049c4:	8b 45 dc             	mov    -0x24(%ebp),%eax
400049c7:	01 c2                	add    %eax,%edx
400049c9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
400049cc:	89 44 24 08          	mov    %eax,0x8(%esp)
400049d0:	89 4c 24 04          	mov    %ecx,0x4(%esp)
400049d4:	89 14 24             	mov    %edx,(%esp)
400049d7:	e8 e1 cc ff ff       	call   400016bd <memcpy>
	pfi->size = newlen;
400049dc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400049df:	8b 55 d0             	mov    -0x30(%ebp),%edx
400049e2:	89 50 4c             	mov    %edx,0x4c(%eax)
	cfi->size = newlen;
400049e5:	8b 45 e0             	mov    -0x20(%ebp),%eax
400049e8:	8b 55 d0             	mov    -0x30(%ebp),%edx
400049eb:	89 50 4c             	mov    %edx,0x4c(%eax)
	cfi->rlen = newlen;
400049ee:	8b 45 e0             	mov    -0x20(%ebp),%eax
400049f1:	8b 55 d0             	mov    -0x30(%ebp),%edx
400049f4:	89 50 58             	mov    %edx,0x58(%eax)
	sys_put(SYS_COPY, pid, NULL, tmpmem, FILEDATA(cino), FILE_MAXSIZE);
400049f7:	8b 45 14             	mov    0x14(%ebp),%eax
400049fa:	c1 e0 16             	shl    $0x16,%eax
400049fd:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
40004a03:	8b 45 08             	mov    0x8(%ebp),%eax
40004a06:	0f b7 c0             	movzwl %ax,%eax
40004a09:	c7 45 b4 00 00 02 00 	movl   $0x20000,-0x4c(%ebp)
40004a10:	66 89 45 b2          	mov    %ax,-0x4e(%ebp)
40004a14:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
40004a1b:	8b 45 dc             	mov    -0x24(%ebp),%eax
40004a1e:	89 45 a8             	mov    %eax,-0x58(%ebp)
40004a21:	89 55 a4             	mov    %edx,-0x5c(%ebp)
40004a24:	c7 45 a0 00 00 40 00 	movl   $0x400000,-0x60(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40004a2b:	8b 45 b4             	mov    -0x4c(%ebp),%eax
40004a2e:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40004a31:	8b 5d ac             	mov    -0x54(%ebp),%ebx
40004a34:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
40004a38:	8b 75 a8             	mov    -0x58(%ebp),%esi
40004a3b:	8b 7d a4             	mov    -0x5c(%ebp),%edi
40004a3e:	8b 4d a0             	mov    -0x60(%ebp),%ecx
40004a41:	cd 30                	int    $0x30
	return 1;
40004a43:	b8 01 00 00 00       	mov    $0x1,%eax
}
40004a48:	83 c4 6c             	add    $0x6c,%esp
40004a4b:	5b                   	pop    %ebx
40004a4c:	5e                   	pop    %esi
40004a4d:	5f                   	pop    %edi
40004a4e:	5d                   	pop    %ebp
40004a4f:	c3                   	ret    

40004a50 <execl>:
int exec_readelf(const char *path);
intptr_t exec_copyargs(char *const argv[]);

int
execl(const char *path, const char *arg0, ...)
{
40004a50:	55                   	push   %ebp
40004a51:	89 e5                	mov    %esp,%ebp
40004a53:	83 ec 18             	sub    $0x18,%esp
	return execv(path, (char *const *) &arg0);
40004a56:	8d 45 0c             	lea    0xc(%ebp),%eax
40004a59:	89 44 24 04          	mov    %eax,0x4(%esp)
40004a5d:	8b 45 08             	mov    0x8(%ebp),%eax
40004a60:	89 04 24             	mov    %eax,(%esp)
40004a63:	e8 02 00 00 00       	call   40004a6a <execv>
}
40004a68:	c9                   	leave  
40004a69:	c3                   	ret    

40004a6a <execv>:

int
execv(const char *path, char *const argv[])
{
40004a6a:	55                   	push   %ebp
40004a6b:	89 e5                	mov    %esp,%ebp
40004a6d:	57                   	push   %edi
40004a6e:	56                   	push   %esi
40004a6f:	53                   	push   %ebx
40004a70:	83 ec 5c             	sub    $0x5c,%esp
40004a73:	c7 45 e0 00 00 01 00 	movl   $0x10000,-0x20(%ebp)
40004a7a:	66 c7 45 de 00 00    	movw   $0x0,-0x22(%ebp)
40004a80:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
40004a87:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
40004a8e:	c7 45 d0 00 00 00 40 	movl   $0x40000000,-0x30(%ebp)
40004a95:	c7 45 cc 00 00 00 b0 	movl   $0xb0000000,-0x34(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40004a9c:	8b 45 e0             	mov    -0x20(%ebp),%eax
40004a9f:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40004aa2:	8b 5d d8             	mov    -0x28(%ebp),%ebx
40004aa5:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
40004aa9:	8b 75 d4             	mov    -0x2c(%ebp),%esi
40004aac:	8b 7d d0             	mov    -0x30(%ebp),%edi
40004aaf:	8b 4d cc             	mov    -0x34(%ebp),%ecx
40004ab2:	cd 30                	int    $0x30
	// which never represents a forked child since 0 is an invalid pid.
	// First clear out the new program's entire address space.
	sys_put(SYS_ZERO, 0, NULL, NULL, (void*)VM_USERLO, VM_USERHI-VM_USERLO);

	// Load the ELF executable into child 0.
	if (exec_readelf(path) < 0)
40004ab4:	8b 45 08             	mov    0x8(%ebp),%eax
40004ab7:	89 04 24             	mov    %eax,(%esp)
40004aba:	e8 6d 00 00 00       	call   40004b2c <exec_readelf>
40004abf:	85 c0                	test   %eax,%eax
40004ac1:	79 07                	jns    40004aca <execv+0x60>
		return -1;
40004ac3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40004ac8:	eb 5a                	jmp    40004b24 <execv+0xba>

	// Setup child 0's stack with the argument array.
	intptr_t esp = exec_copyargs(argv);
40004aca:	8b 45 0c             	mov    0xc(%ebp),%eax
40004acd:	89 04 24             	mov    %eax,(%esp)
40004ad0:	e8 3a 05 00 00       	call   4000500f <exec_copyargs>
40004ad5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
40004ad8:	c7 45 c8 00 00 02 00 	movl   $0x20000,-0x38(%ebp)
40004adf:	66 c7 45 c6 00 00    	movw   $0x0,-0x3a(%ebp)
40004ae5:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
40004aec:	c7 45 bc 00 00 00 80 	movl   $0x80000000,-0x44(%ebp)
40004af3:	c7 45 b8 00 00 00 80 	movl   $0x80000000,-0x48(%ebp)
40004afa:	c7 45 b4 00 00 00 40 	movl   $0x40000000,-0x4c(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40004b01:	8b 45 c8             	mov    -0x38(%ebp),%eax
40004b04:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40004b07:	8b 5d c0             	mov    -0x40(%ebp),%ebx
40004b0a:	0f b7 55 c6          	movzwl -0x3a(%ebp),%edx
40004b0e:	8b 75 bc             	mov    -0x44(%ebp),%esi
40004b11:	8b 7d b8             	mov    -0x48(%ebp),%edi
40004b14:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
40004b17:	cd 30                	int    $0x30
	sys_put(SYS_COPY, 0, NULL, (void*)VM_FILELO, (void*)VM_FILELO,
		VM_FILEHI-VM_FILELO);

	// Copy child 0's entire memory state onto ours
	// and start the new program.  See lib/entry.S for details.
	exec_start(esp);
40004b19:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004b1c:	89 04 24             	mov    %eax,(%esp)
40004b1f:	e8 f5 b5 ff ff       	call   40000119 <exec_start>
}
40004b24:	83 c4 5c             	add    $0x5c,%esp
40004b27:	5b                   	pop    %ebx
40004b28:	5e                   	pop    %esi
40004b29:	5f                   	pop    %edi
40004b2a:	5d                   	pop    %ebp
40004b2b:	c3                   	ret    

40004b2c <exec_readelf>:

int
exec_readelf(const char *path)
{
40004b2c:	55                   	push   %ebp
40004b2d:	89 e5                	mov    %esp,%ebp
40004b2f:	57                   	push   %edi
40004b30:	56                   	push   %esi
40004b31:	53                   	push   %ebx
40004b32:	81 ec fc 00 00 00    	sub    $0xfc,%esp
	// We'll load the ELF image into a scratch area in our address space.
	sys_get(SYS_ZERO, 0, NULL, NULL, (void*)VM_SCRATCHLO, EXEMAX);
40004b38:	c7 45 e0 00 00 00 40 	movl   $0x40000000,-0x20(%ebp)
40004b3f:	c7 45 dc 00 00 00 10 	movl   $0x10000000,-0x24(%ebp)
40004b46:	8b 45 dc             	mov    -0x24(%ebp),%eax
40004b49:	39 45 e0             	cmp    %eax,-0x20(%ebp)
40004b4c:	0f 46 45 e0          	cmovbe -0x20(%ebp),%eax
40004b50:	c7 85 7c ff ff ff 00 	movl   $0x10000,-0x84(%ebp)
40004b57:	00 01 00 
40004b5a:	66 c7 85 7a ff ff ff 	movw   $0x0,-0x86(%ebp)
40004b61:	00 00 
40004b63:	c7 85 74 ff ff ff 00 	movl   $0x0,-0x8c(%ebp)
40004b6a:	00 00 00 
40004b6d:	c7 85 70 ff ff ff 00 	movl   $0x0,-0x90(%ebp)
40004b74:	00 00 00 
40004b77:	c7 85 6c ff ff ff 00 	movl   $0xc0000000,-0x94(%ebp)
40004b7e:	00 00 c0 
40004b81:	89 85 68 ff ff ff    	mov    %eax,-0x98(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40004b87:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
40004b8d:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40004b90:	8b 9d 74 ff ff ff    	mov    -0x8c(%ebp),%ebx
40004b96:	0f b7 95 7a ff ff ff 	movzwl -0x86(%ebp),%edx
40004b9d:	8b b5 70 ff ff ff    	mov    -0x90(%ebp),%esi
40004ba3:	8b bd 6c ff ff ff    	mov    -0x94(%ebp),%edi
40004ba9:	8b 8d 68 ff ff ff    	mov    -0x98(%ebp),%ecx
40004baf:	cd 30                	int    $0x30

	// Open the ELF image to load.
	filedesc *fd = filedesc_open(NULL, path, O_RDONLY, 0);
40004bb1:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
40004bb8:	00 
40004bb9:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40004bc0:	00 
40004bc1:	8b 45 08             	mov    0x8(%ebp),%eax
40004bc4:	89 44 24 04          	mov    %eax,0x4(%esp)
40004bc8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40004bcf:	e8 3b d6 ff ff       	call   4000220f <filedesc_open>
40004bd4:	89 45 d8             	mov    %eax,-0x28(%ebp)
	if (fd == NULL)
40004bd7:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
40004bdb:	75 0a                	jne    40004be7 <exec_readelf+0xbb>
		return -1;
40004bdd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40004be2:	e9 1d 04 00 00       	jmp    40005004 <exec_readelf+0x4d8>
	void *imgdata = FILEDATA(fd->ino);
40004be7:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004bea:	8b 00                	mov    (%eax),%eax
40004bec:	c1 e0 16             	shl    $0x16,%eax
40004bef:	05 00 00 00 80       	add    $0x80000000,%eax
40004bf4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	size_t imgsize = files->fi[fd->ino].size;
40004bf7:	8b 15 3c 5d 00 40    	mov    0x40005d3c,%edx
40004bfd:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004c00:	8b 00                	mov    (%eax),%eax
40004c02:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004c05:	01 d0                	add    %edx,%eax
40004c07:	05 5c 10 00 00       	add    $0x105c,%eax
40004c0c:	8b 00                	mov    (%eax),%eax
40004c0e:	89 45 d0             	mov    %eax,-0x30(%ebp)

	// Make sure it looks like an ELF image.
	elfhdr *eh = imgdata;
40004c11:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40004c14:	89 45 cc             	mov    %eax,-0x34(%ebp)
	if (imgsize < sizeof(*eh) || eh->e_magic != ELF_MAGIC) {
40004c17:	83 7d d0 33          	cmpl   $0x33,-0x30(%ebp)
40004c1b:	76 0c                	jbe    40004c29 <exec_readelf+0xfd>
40004c1d:	8b 45 cc             	mov    -0x34(%ebp),%eax
40004c20:	8b 00                	mov    (%eax),%eax
40004c22:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
40004c27:	74 21                	je     40004c4a <exec_readelf+0x11e>
		warn("exec_readelf: ELF header not found");
40004c29:	c7 44 24 08 60 63 00 	movl   $0x40006360,0x8(%esp)
40004c30:	40 
40004c31:	c7 44 24 04 4d 00 00 	movl   $0x4d,0x4(%esp)
40004c38:	00 
40004c39:	c7 04 24 83 63 00 40 	movl   $0x40006383,(%esp)
40004c40:	e8 69 be ff ff       	call   40000aae <debug_warn>
		goto err;
40004c45:	e9 aa 03 00 00       	jmp    40004ff4 <exec_readelf+0x4c8>
	}

	// Load each program segment into the scratch area
	proghdr *ph = imgdata + eh->e_phoff;
40004c4a:	8b 45 cc             	mov    -0x34(%ebp),%eax
40004c4d:	8b 50 1c             	mov    0x1c(%eax),%edx
40004c50:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40004c53:	01 d0                	add    %edx,%eax
40004c55:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	proghdr *eph = ph + eh->e_phnum;
40004c58:	8b 45 cc             	mov    -0x34(%ebp),%eax
40004c5b:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
40004c5f:	0f b7 c0             	movzwl %ax,%eax
40004c62:	89 c2                	mov    %eax,%edx
40004c64:	c1 e2 05             	shl    $0x5,%edx
40004c67:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004c6a:	01 d0                	add    %edx,%eax
40004c6c:	89 45 c8             	mov    %eax,-0x38(%ebp)
	if (imgsize < (void*)eph - imgdata) {
40004c6f:	8b 55 c8             	mov    -0x38(%ebp),%edx
40004c72:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40004c75:	89 d1                	mov    %edx,%ecx
40004c77:	29 c1                	sub    %eax,%ecx
40004c79:	89 c8                	mov    %ecx,%eax
40004c7b:	3b 45 d0             	cmp    -0x30(%ebp),%eax
40004c7e:	0f 86 ac 02 00 00    	jbe    40004f30 <exec_readelf+0x404>
		warn("exec_readelf: ELF program header truncated");
40004c84:	c7 44 24 08 90 63 00 	movl   $0x40006390,0x8(%esp)
40004c8b:	40 
40004c8c:	c7 44 24 04 55 00 00 	movl   $0x55,0x4(%esp)
40004c93:	00 
40004c94:	c7 04 24 83 63 00 40 	movl   $0x40006383,(%esp)
40004c9b:	e8 0e be ff ff       	call   40000aae <debug_warn>
		goto err;
40004ca0:	e9 4f 03 00 00       	jmp    40004ff4 <exec_readelf+0x4c8>
	}
	for (; ph < eph; ph++) {
		if (ph->p_type != ELF_PROG_LOAD)
40004ca5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004ca8:	8b 00                	mov    (%eax),%eax
40004caa:	83 f8 01             	cmp    $0x1,%eax
40004cad:	0f 85 78 02 00 00    	jne    40004f2b <exec_readelf+0x3ff>
			continue;

		// The executable should fit in the first 4MB of user space.
		intptr_t valo = ph->p_va;
40004cb3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004cb6:	8b 40 08             	mov    0x8(%eax),%eax
40004cb9:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		intptr_t vahi = valo + ph->p_memsz;
40004cbc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004cbf:	8b 50 14             	mov    0x14(%eax),%edx
40004cc2:	8b 45 c4             	mov    -0x3c(%ebp),%eax
40004cc5:	01 d0                	add    %edx,%eax
40004cc7:	89 45 c0             	mov    %eax,-0x40(%ebp)
		if (valo < VM_USERLO || valo > VM_USERLO+EXEMAX ||
40004cca:	81 7d c4 ff ff ff 3f 	cmpl   $0x3fffffff,-0x3c(%ebp)
40004cd1:	7e 50                	jle    40004d23 <exec_readelf+0x1f7>
40004cd3:	8b 55 c4             	mov    -0x3c(%ebp),%edx
40004cd6:	c7 45 bc 00 00 00 40 	movl   $0x40000000,-0x44(%ebp)
40004cdd:	c7 45 b8 00 00 00 10 	movl   $0x10000000,-0x48(%ebp)
40004ce4:	8b 45 b8             	mov    -0x48(%ebp),%eax
40004ce7:	39 45 bc             	cmp    %eax,-0x44(%ebp)
40004cea:	0f 46 45 bc          	cmovbe -0x44(%ebp),%eax
40004cee:	05 00 00 00 40       	add    $0x40000000,%eax
40004cf3:	39 c2                	cmp    %eax,%edx
40004cf5:	77 2c                	ja     40004d23 <exec_readelf+0x1f7>
40004cf7:	8b 45 c0             	mov    -0x40(%ebp),%eax
40004cfa:	3b 45 c4             	cmp    -0x3c(%ebp),%eax
40004cfd:	7c 24                	jl     40004d23 <exec_readelf+0x1f7>
				vahi < valo || vahi > VM_USERLO+EXEMAX) {
40004cff:	8b 55 c0             	mov    -0x40(%ebp),%edx
40004d02:	c7 45 b4 00 00 00 40 	movl   $0x40000000,-0x4c(%ebp)
40004d09:	c7 45 b0 00 00 00 10 	movl   $0x10000000,-0x50(%ebp)
40004d10:	8b 45 b0             	mov    -0x50(%ebp),%eax
40004d13:	39 45 b4             	cmp    %eax,-0x4c(%ebp)
40004d16:	0f 46 45 b4          	cmovbe -0x4c(%ebp),%eax
40004d1a:	05 00 00 00 40       	add    $0x40000000,%eax
40004d1f:	39 c2                	cmp    %eax,%edx
40004d21:	76 4d                	jbe    40004d70 <exec_readelf+0x244>
			warn("exec_readelf: executable image too large "
40004d23:	c7 45 8c 00 00 00 40 	movl   $0x40000000,-0x74(%ebp)
40004d2a:	c7 45 88 00 00 00 10 	movl   $0x10000000,-0x78(%ebp)
40004d31:	8b 45 88             	mov    -0x78(%ebp),%eax
40004d34:	39 45 8c             	cmp    %eax,-0x74(%ebp)
40004d37:	0f 46 45 8c          	cmovbe -0x74(%ebp),%eax
40004d3b:	8b 55 c4             	mov    -0x3c(%ebp),%edx
40004d3e:	8b 4d c0             	mov    -0x40(%ebp),%ecx
40004d41:	89 cb                	mov    %ecx,%ebx
40004d43:	29 d3                	sub    %edx,%ebx
40004d45:	89 da                	mov    %ebx,%edx
40004d47:	89 44 24 10          	mov    %eax,0x10(%esp)
40004d4b:	89 54 24 0c          	mov    %edx,0xc(%esp)
40004d4f:	c7 44 24 08 bc 63 00 	movl   $0x400063bc,0x8(%esp)
40004d56:	40 
40004d57:	c7 44 24 04 62 00 00 	movl   $0x62,0x4(%esp)
40004d5e:	00 
40004d5f:	c7 04 24 83 63 00 40 	movl   $0x40006383,(%esp)
40004d66:	e8 43 bd ff ff       	call   40000aae <debug_warn>
				"(%d bytes > %d max)", vahi-valo, EXEMAX);
			goto err;
40004d6b:	e9 84 02 00 00       	jmp    40004ff4 <exec_readelf+0x4c8>
		}

		// Map all pages the segment touches in our scratch region.
		// They've already been zeroed by the SYS_ZERO above.
		intptr_t scratchofs = VM_SCRATCHLO - VM_USERLO;
40004d70:	c7 45 ac 00 00 00 80 	movl   $0x80000000,-0x54(%ebp)
		intptr_t pagelo = ROUNDDOWN(valo, PAGESIZE);
40004d77:	8b 45 c4             	mov    -0x3c(%ebp),%eax
40004d7a:	89 45 a8             	mov    %eax,-0x58(%ebp)
40004d7d:	8b 45 a8             	mov    -0x58(%ebp),%eax
40004d80:	25 00 f0 ff ff       	and    $0xfffff000,%eax
40004d85:	89 45 a4             	mov    %eax,-0x5c(%ebp)
		intptr_t pagehi = ROUNDUP(vahi, PAGESIZE);
40004d88:	c7 45 a0 00 10 00 00 	movl   $0x1000,-0x60(%ebp)
40004d8f:	8b 55 c0             	mov    -0x40(%ebp),%edx
40004d92:	8b 45 a0             	mov    -0x60(%ebp),%eax
40004d95:	01 d0                	add    %edx,%eax
40004d97:	83 e8 01             	sub    $0x1,%eax
40004d9a:	89 45 9c             	mov    %eax,-0x64(%ebp)
40004d9d:	8b 45 9c             	mov    -0x64(%ebp),%eax
40004da0:	ba 00 00 00 00       	mov    $0x0,%edx
40004da5:	f7 75 a0             	divl   -0x60(%ebp)
40004da8:	89 d0                	mov    %edx,%eax
40004daa:	8b 55 9c             	mov    -0x64(%ebp),%edx
40004dad:	89 d1                	mov    %edx,%ecx
40004daf:	29 c1                	sub    %eax,%ecx
40004db1:	89 c8                	mov    %ecx,%eax
40004db3:	89 45 98             	mov    %eax,-0x68(%ebp)
		sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
			(void*)pagelo + scratchofs, pagehi - pagelo);
40004db6:	8b 45 a4             	mov    -0x5c(%ebp),%eax
40004db9:	8b 55 98             	mov    -0x68(%ebp),%edx
40004dbc:	89 d3                	mov    %edx,%ebx
40004dbe:	29 c3                	sub    %eax,%ebx
40004dc0:	89 d8                	mov    %ebx,%eax
40004dc2:	8b 4d ac             	mov    -0x54(%ebp),%ecx
40004dc5:	8b 55 a4             	mov    -0x5c(%ebp),%edx
40004dc8:	01 ca                	add    %ecx,%edx
40004dca:	c7 85 64 ff ff ff 00 	movl   $0x700,-0x9c(%ebp)
40004dd1:	07 00 00 
40004dd4:	66 c7 85 62 ff ff ff 	movw   $0x0,-0x9e(%ebp)
40004ddb:	00 00 
40004ddd:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
40004de4:	00 00 00 
40004de7:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
40004dee:	00 00 00 
40004df1:	89 95 54 ff ff ff    	mov    %edx,-0xac(%ebp)
40004df7:	89 85 50 ff ff ff    	mov    %eax,-0xb0(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40004dfd:	8b 85 64 ff ff ff    	mov    -0x9c(%ebp),%eax
40004e03:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40004e06:	8b 9d 5c ff ff ff    	mov    -0xa4(%ebp),%ebx
40004e0c:	0f b7 95 62 ff ff ff 	movzwl -0x9e(%ebp),%edx
40004e13:	8b b5 58 ff ff ff    	mov    -0xa8(%ebp),%esi
40004e19:	8b bd 54 ff ff ff    	mov    -0xac(%ebp),%edi
40004e1f:	8b 8d 50 ff ff ff    	mov    -0xb0(%ebp),%ecx
40004e25:	cd 30                	int    $0x30

		// Initialize the file-loaded part of the ELF image.
		// (We could use copy-on-write if SYS_COPY
		// supports copying at arbitrary page boundaries.)
		intptr_t filelo = ph->p_offset;
40004e27:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004e2a:	8b 40 04             	mov    0x4(%eax),%eax
40004e2d:	89 45 94             	mov    %eax,-0x6c(%ebp)
		intptr_t filehi = filelo + ph->p_filesz;
40004e30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004e33:	8b 50 10             	mov    0x10(%eax),%edx
40004e36:	8b 45 94             	mov    -0x6c(%ebp),%eax
40004e39:	01 d0                	add    %edx,%eax
40004e3b:	89 45 90             	mov    %eax,-0x70(%ebp)
		if (filelo < 0 || filelo > imgsize
40004e3e:	83 7d 94 00          	cmpl   $0x0,-0x6c(%ebp)
40004e42:	78 18                	js     40004e5c <exec_readelf+0x330>
40004e44:	8b 45 94             	mov    -0x6c(%ebp),%eax
40004e47:	3b 45 d0             	cmp    -0x30(%ebp),%eax
40004e4a:	77 10                	ja     40004e5c <exec_readelf+0x330>
				|| filehi < filelo || filehi > imgsize) {
40004e4c:	8b 45 90             	mov    -0x70(%ebp),%eax
40004e4f:	3b 45 94             	cmp    -0x6c(%ebp),%eax
40004e52:	7c 08                	jl     40004e5c <exec_readelf+0x330>
40004e54:	8b 45 90             	mov    -0x70(%ebp),%eax
40004e57:	3b 45 d0             	cmp    -0x30(%ebp),%eax
40004e5a:	76 21                	jbe    40004e7d <exec_readelf+0x351>
			warn("exec_readelf: loaded section out of bounds");
40004e5c:	c7 44 24 08 fc 63 00 	movl   $0x400063fc,0x8(%esp)
40004e63:	40 
40004e64:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
40004e6b:	00 
40004e6c:	c7 04 24 83 63 00 40 	movl   $0x40006383,(%esp)
40004e73:	e8 36 bc ff ff       	call   40000aae <debug_warn>
			goto err;
40004e78:	e9 77 01 00 00       	jmp    40004ff4 <exec_readelf+0x4c8>
		}
		memcpy((void*)valo + scratchofs, imgdata + filelo,
			filehi - filelo);
40004e7d:	8b 45 94             	mov    -0x6c(%ebp),%eax
40004e80:	8b 55 90             	mov    -0x70(%ebp),%edx
40004e83:	89 d1                	mov    %edx,%ecx
40004e85:	29 c1                	sub    %eax,%ecx
40004e87:	89 c8                	mov    %ecx,%eax
		if (filelo < 0 || filelo > imgsize
				|| filehi < filelo || filehi > imgsize) {
			warn("exec_readelf: loaded section out of bounds");
			goto err;
		}
		memcpy((void*)valo + scratchofs, imgdata + filelo,
40004e89:	89 c2                	mov    %eax,%edx
40004e8b:	8b 4d 94             	mov    -0x6c(%ebp),%ecx
40004e8e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40004e91:	01 c1                	add    %eax,%ecx
40004e93:	8b 5d ac             	mov    -0x54(%ebp),%ebx
40004e96:	8b 45 c4             	mov    -0x3c(%ebp),%eax
40004e99:	01 d8                	add    %ebx,%eax
40004e9b:	89 54 24 08          	mov    %edx,0x8(%esp)
40004e9f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
40004ea3:	89 04 24             	mov    %eax,(%esp)
40004ea6:	e8 12 c8 ff ff       	call   400016bd <memcpy>
			filehi - filelo);

		// Finally, remove write permissions on read-only segments.
		if (!(ph->p_flags & ELF_PROG_FLAG_WRITE))
40004eab:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004eae:	8b 40 18             	mov    0x18(%eax),%eax
40004eb1:	83 e0 02             	and    $0x2,%eax
40004eb4:	85 c0                	test   %eax,%eax
40004eb6:	75 74                	jne    40004f2c <exec_readelf+0x400>
			sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL,
				(void*)pagelo + scratchofs, pagehi - pagelo);
40004eb8:	8b 45 a4             	mov    -0x5c(%ebp),%eax
40004ebb:	8b 55 98             	mov    -0x68(%ebp),%edx
40004ebe:	89 d3                	mov    %edx,%ebx
40004ec0:	29 c3                	sub    %eax,%ebx
40004ec2:	89 d8                	mov    %ebx,%eax
40004ec4:	8b 4d ac             	mov    -0x54(%ebp),%ecx
40004ec7:	8b 55 a4             	mov    -0x5c(%ebp),%edx
40004eca:	01 ca                	add    %ecx,%edx
40004ecc:	c7 85 4c ff ff ff 00 	movl   $0x300,-0xb4(%ebp)
40004ed3:	03 00 00 
40004ed6:	66 c7 85 4a ff ff ff 	movw   $0x0,-0xb6(%ebp)
40004edd:	00 00 
40004edf:	c7 85 44 ff ff ff 00 	movl   $0x0,-0xbc(%ebp)
40004ee6:	00 00 00 
40004ee9:	c7 85 40 ff ff ff 00 	movl   $0x0,-0xc0(%ebp)
40004ef0:	00 00 00 
40004ef3:	89 95 3c ff ff ff    	mov    %edx,-0xc4(%ebp)
40004ef9:	89 85 38 ff ff ff    	mov    %eax,-0xc8(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40004eff:	8b 85 4c ff ff ff    	mov    -0xb4(%ebp),%eax
40004f05:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40004f08:	8b 9d 44 ff ff ff    	mov    -0xbc(%ebp),%ebx
40004f0e:	0f b7 95 4a ff ff ff 	movzwl -0xb6(%ebp),%edx
40004f15:	8b b5 40 ff ff ff    	mov    -0xc0(%ebp),%esi
40004f1b:	8b bd 3c ff ff ff    	mov    -0xc4(%ebp),%edi
40004f21:	8b 8d 38 ff ff ff    	mov    -0xc8(%ebp),%ecx
40004f27:	cd 30                	int    $0x30
40004f29:	eb 01                	jmp    40004f2c <exec_readelf+0x400>
		warn("exec_readelf: ELF program header truncated");
		goto err;
	}
	for (; ph < eph; ph++) {
		if (ph->p_type != ELF_PROG_LOAD)
			continue;
40004f2b:	90                   	nop
	proghdr *eph = ph + eh->e_phnum;
	if (imgsize < (void*)eph - imgdata) {
		warn("exec_readelf: ELF program header truncated");
		goto err;
	}
	for (; ph < eph; ph++) {
40004f2c:	83 45 e4 20          	addl   $0x20,-0x1c(%ebp)
40004f30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40004f33:	3b 45 c8             	cmp    -0x38(%ebp),%eax
40004f36:	0f 82 69 fd ff ff    	jb     40004ca5 <exec_readelf+0x179>
				(void*)pagelo + scratchofs, pagehi - pagelo);
	}

	// Copy the ELF image into its correct position in child 0.
	sys_put(SYS_COPY, 0, NULL, (void*)VM_SCRATCHLO,
		(void*)VM_USERLO, EXEMAX);
40004f3c:	c7 45 84 00 00 00 40 	movl   $0x40000000,-0x7c(%ebp)
40004f43:	c7 45 80 00 00 00 10 	movl   $0x10000000,-0x80(%ebp)
40004f4a:	8b 45 80             	mov    -0x80(%ebp),%eax
40004f4d:	39 45 84             	cmp    %eax,-0x7c(%ebp)
40004f50:	0f 46 45 84          	cmovbe -0x7c(%ebp),%eax
40004f54:	c7 85 34 ff ff ff 00 	movl   $0x20000,-0xcc(%ebp)
40004f5b:	00 02 00 
40004f5e:	66 c7 85 32 ff ff ff 	movw   $0x0,-0xce(%ebp)
40004f65:	00 00 
40004f67:	c7 85 2c ff ff ff 00 	movl   $0x0,-0xd4(%ebp)
40004f6e:	00 00 00 
40004f71:	c7 85 28 ff ff ff 00 	movl   $0xc0000000,-0xd8(%ebp)
40004f78:	00 00 c0 
40004f7b:	c7 85 24 ff ff ff 00 	movl   $0x40000000,-0xdc(%ebp)
40004f82:	00 00 40 
40004f85:	89 85 20 ff ff ff    	mov    %eax,-0xe0(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40004f8b:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
40004f91:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40004f94:	8b 9d 2c ff ff ff    	mov    -0xd4(%ebp),%ebx
40004f9a:	0f b7 95 32 ff ff ff 	movzwl -0xce(%ebp),%edx
40004fa1:	8b b5 28 ff ff ff    	mov    -0xd8(%ebp),%esi
40004fa7:	8b bd 24 ff ff ff    	mov    -0xdc(%ebp),%edi
40004fad:	8b 8d 20 ff ff ff    	mov    -0xe0(%ebp),%ecx
40004fb3:	cd 30                	int    $0x30

	// The new program should have the same entrypoint as we do!
	if (eh->e_entry != (intptr_t)start) {
40004fb5:	8b 45 cc             	mov    -0x34(%ebp),%eax
40004fb8:	8b 50 18             	mov    0x18(%eax),%edx
40004fbb:	b8 00 01 00 40       	mov    $0x40000100,%eax
40004fc0:	39 c2                	cmp    %eax,%edx
40004fc2:	74 1e                	je     40004fe2 <exec_readelf+0x4b6>
		warn("exec_readelf: executable has a different start address");
40004fc4:	c7 44 24 08 28 64 00 	movl   $0x40006428,0x8(%esp)
40004fcb:	40 
40004fcc:	c7 44 24 04 87 00 00 	movl   $0x87,0x4(%esp)
40004fd3:	00 
40004fd4:	c7 04 24 83 63 00 40 	movl   $0x40006383,(%esp)
40004fdb:	e8 ce ba ff ff       	call   40000aae <debug_warn>
		goto err;
40004fe0:	eb 12                	jmp    40004ff4 <exec_readelf+0x4c8>
	}

	filedesc_close(fd);	// Done with the ELF file
40004fe2:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004fe5:	89 04 24             	mov    %eax,(%esp)
40004fe8:	e8 e7 d7 ff ff       	call   400027d4 <filedesc_close>
	return 0;
40004fed:	b8 00 00 00 00       	mov    $0x0,%eax
40004ff2:	eb 10                	jmp    40005004 <exec_readelf+0x4d8>

err:
	filedesc_close(fd);
40004ff4:	8b 45 d8             	mov    -0x28(%ebp),%eax
40004ff7:	89 04 24             	mov    %eax,(%esp)
40004ffa:	e8 d5 d7 ff ff       	call   400027d4 <filedesc_close>
	return -1;
40004fff:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
40005004:	81 c4 fc 00 00 00    	add    $0xfc,%esp
4000500a:	5b                   	pop    %ebx
4000500b:	5e                   	pop    %esi
4000500c:	5f                   	pop    %edi
4000500d:	5d                   	pop    %ebp
4000500e:	c3                   	ret    

4000500f <exec_copyargs>:

intptr_t
exec_copyargs(char *const argv[])
{
4000500f:	55                   	push   %ebp
40005010:	89 e5                	mov    %esp,%ebp
40005012:	57                   	push   %edi
40005013:	56                   	push   %esi
40005014:	53                   	push   %ebx
40005015:	83 ec 7c             	sub    $0x7c,%esp
	int i = 0;
40005018:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
4000501f:	c7 45 bc 00 07 01 00 	movl   $0x10700,-0x44(%ebp)
40005026:	66 c7 45 ba 00 00    	movw   $0x0,-0x46(%ebp)
4000502c:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)
40005033:	c7 45 b0 00 00 00 00 	movl   $0x0,-0x50(%ebp)
4000503a:	c7 45 ac 00 00 00 c0 	movl   $0xc0000000,-0x54(%ebp)
40005041:	c7 45 a8 00 00 40 00 	movl   $0x400000,-0x58(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40005048:	8b 45 bc             	mov    -0x44(%ebp),%eax
4000504b:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000504e:	8b 5d b4             	mov    -0x4c(%ebp),%ebx
40005051:	0f b7 55 ba          	movzwl -0x46(%ebp),%edx
40005055:	8b 75 b0             	mov    -0x50(%ebp),%esi
40005058:	8b 7d ac             	mov    -0x54(%ebp),%edi
4000505b:	8b 4d a8             	mov    -0x58(%ebp),%ecx
4000505e:	cd 30                	int    $0x30
	// in _our_ address space while we're copying the arguments,
	// but the pointers we're writing into this space will be
	// interpreted by the newly executed process,
	// where the stack will be mapped from VM_STACKHI-PTSIZE to VM_STACKHI.
	//warn("exec_copyargs not implemented yet");
	uint32_t argc= 0;
40005060:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	while(argv[argc]){
40005067:	eb 04                	jmp    4000506d <exec_copyargs+0x5e>
		argc++;
40005069:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
	// but the pointers we're writing into this space will be
	// interpreted by the newly executed process,
	// where the stack will be mapped from VM_STACKHI-PTSIZE to VM_STACKHI.
	//warn("exec_copyargs not implemented yet");
	uint32_t argc= 0;
	while(argv[argc]){
4000506d:	8b 45 e0             	mov    -0x20(%ebp),%eax
40005070:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
40005077:	8b 45 08             	mov    0x8(%ebp),%eax
4000507a:	01 d0                	add    %edx,%eax
4000507c:	8b 00                	mov    (%eax),%eax
4000507e:	85 c0                	test   %eax,%eax
40005080:	75 e7                	jne    40005069 <exec_copyargs+0x5a>
		argc++;
	}

	uint32_t ofs = VM_STACKHI - VM_SCRATCHLO - PTSIZE;
40005082:	c7 45 d8 00 00 c0 2f 	movl   $0x2fc00000,-0x28(%ebp)
	intptr_t esp_start = VM_SCRATCHLO + PTSIZE;
40005089:	c7 45 d4 00 00 40 c0 	movl   $0xc0400000,-0x2c(%ebp)
	intptr_t esp = esp_start;
40005090:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40005093:	89 45 dc             	mov    %eax,-0x24(%ebp)
	esp -=4 * (argc+1);
40005096:	8b 45 dc             	mov    -0x24(%ebp),%eax
40005099:	8b 55 e0             	mov    -0x20(%ebp),%edx
4000509c:	83 c2 01             	add    $0x1,%edx
4000509f:	c1 e2 02             	shl    $0x2,%edx
400050a2:	29 d0                	sub    %edx,%eax
400050a4:	89 45 dc             	mov    %eax,-0x24(%ebp)
	intptr_t init_argv_pos = esp;
400050a7:	8b 45 dc             	mov    -0x24(%ebp),%eax
400050aa:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for(i = argc-1; i >= 0; i--){
400050ad:	8b 45 e0             	mov    -0x20(%ebp),%eax
400050b0:	83 e8 01             	sub    $0x1,%eax
400050b3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
400050b6:	eb 62                	jmp    4000511a <exec_copyargs+0x10b>
		int len = strlen(argv[i]) + 1;
400050b8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400050bb:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
400050c2:	8b 45 08             	mov    0x8(%ebp),%eax
400050c5:	01 d0                	add    %edx,%eax
400050c7:	8b 00                	mov    (%eax),%eax
400050c9:	89 04 24             	mov    %eax,(%esp)
400050cc:	e8 e7 c2 ff ff       	call   400013b8 <strlen>
400050d1:	83 c0 01             	add    $0x1,%eax
400050d4:	89 45 cc             	mov    %eax,-0x34(%ebp)
		esp -= len;
400050d7:	8b 45 cc             	mov    -0x34(%ebp),%eax
400050da:	29 45 dc             	sub    %eax,-0x24(%ebp)
		strcpy((void*)esp, argv[i]);
400050dd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400050e0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
400050e7:	8b 45 08             	mov    0x8(%ebp),%eax
400050ea:	01 d0                	add    %edx,%eax
400050ec:	8b 10                	mov    (%eax),%edx
400050ee:	8b 45 dc             	mov    -0x24(%ebp),%eax
400050f1:	89 54 24 04          	mov    %edx,0x4(%esp)
400050f5:	89 04 24             	mov    %eax,(%esp)
400050f8:	e8 e1 c2 ff ff       	call   400013de <strcpy>
		((intptr_t*)init_argv_pos)[i]= esp + ofs;
400050fd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40005100:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
40005107:	8b 45 d0             	mov    -0x30(%ebp),%eax
4000510a:	01 d0                	add    %edx,%eax
4000510c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
4000510f:	8b 55 d8             	mov    -0x28(%ebp),%edx
40005112:	01 ca                	add    %ecx,%edx
40005114:	89 10                	mov    %edx,(%eax)
	uint32_t ofs = VM_STACKHI - VM_SCRATCHLO - PTSIZE;
	intptr_t esp_start = VM_SCRATCHLO + PTSIZE;
	intptr_t esp = esp_start;
	esp -=4 * (argc+1);
	intptr_t init_argv_pos = esp;
	for(i = argc-1; i >= 0; i--){
40005116:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
4000511a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
4000511e:	79 98                	jns    400050b8 <exec_copyargs+0xa9>
		int len = strlen(argv[i]) + 1;
		esp -= len;
		strcpy((void*)esp, argv[i]);
		((intptr_t*)init_argv_pos)[i]= esp + ofs;
	}
	int strsize = ROUNDUP(init_argv_pos - esp, 4);
40005120:	c7 45 c8 04 00 00 00 	movl   $0x4,-0x38(%ebp)
40005127:	8b 45 dc             	mov    -0x24(%ebp),%eax
4000512a:	8b 55 d0             	mov    -0x30(%ebp),%edx
4000512d:	89 d1                	mov    %edx,%ecx
4000512f:	29 c1                	sub    %eax,%ecx
40005131:	89 c8                	mov    %ecx,%eax
40005133:	89 c2                	mov    %eax,%edx
40005135:	8b 45 c8             	mov    -0x38(%ebp),%eax
40005138:	01 d0                	add    %edx,%eax
4000513a:	83 e8 01             	sub    $0x1,%eax
4000513d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
40005140:	8b 45 c4             	mov    -0x3c(%ebp),%eax
40005143:	ba 00 00 00 00       	mov    $0x0,%edx
40005148:	f7 75 c8             	divl   -0x38(%ebp)
4000514b:	89 d0                	mov    %edx,%eax
4000514d:	8b 55 c4             	mov    -0x3c(%ebp),%edx
40005150:	89 d1                	mov    %edx,%ecx
40005152:	29 c1                	sub    %eax,%ecx
40005154:	89 c8                	mov    %ecx,%eax
40005156:	89 45 c0             	mov    %eax,-0x40(%ebp)
	esp = init_argv_pos - strsize;
40005159:	8b 45 c0             	mov    -0x40(%ebp),%eax
4000515c:	8b 55 d0             	mov    -0x30(%ebp),%edx
4000515f:	89 d1                	mov    %edx,%ecx
40005161:	29 c1                	sub    %eax,%ecx
40005163:	89 c8                	mov    %ecx,%eax
40005165:	89 45 dc             	mov    %eax,-0x24(%ebp)
	esp -= 4;
40005168:	83 6d dc 04          	subl   $0x4,-0x24(%ebp)
	*(intptr_t*)esp = init_argv_pos + ofs;
4000516c:	8b 45 dc             	mov    -0x24(%ebp),%eax
4000516f:	8b 4d d0             	mov    -0x30(%ebp),%ecx
40005172:	8b 55 d8             	mov    -0x28(%ebp),%edx
40005175:	01 ca                	add    %ecx,%edx
40005177:	89 10                	mov    %edx,(%eax)
	esp -= 4;
40005179:	83 6d dc 04          	subl   $0x4,-0x24(%ebp)
	*(intptr_t*)esp = argc;
4000517d:	8b 45 dc             	mov    -0x24(%ebp),%eax
40005180:	8b 55 e0             	mov    -0x20(%ebp),%edx
40005183:	89 10                	mov    %edx,(%eax)
	esp = esp + ofs;
40005185:	8b 55 dc             	mov    -0x24(%ebp),%edx
40005188:	8b 45 d8             	mov    -0x28(%ebp),%eax
4000518b:	01 d0                	add    %edx,%eax
4000518d:	89 45 dc             	mov    %eax,-0x24(%ebp)
40005190:	c7 45 a4 00 00 02 00 	movl   $0x20000,-0x5c(%ebp)
40005197:	66 c7 45 a2 00 00    	movw   $0x0,-0x5e(%ebp)
4000519d:	c7 45 9c 00 00 00 00 	movl   $0x0,-0x64(%ebp)
400051a4:	c7 45 98 00 00 00 c0 	movl   $0xc0000000,-0x68(%ebp)
400051ab:	c7 45 94 00 00 c0 ef 	movl   $0xefc00000,-0x6c(%ebp)
400051b2:	c7 45 90 00 00 40 00 	movl   $0x400000,-0x70(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
400051b9:	8b 45 a4             	mov    -0x5c(%ebp),%eax
400051bc:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400051bf:	8b 5d 9c             	mov    -0x64(%ebp),%ebx
400051c2:	0f b7 55 a2          	movzwl -0x5e(%ebp),%edx
400051c6:	8b 75 98             	mov    -0x68(%ebp),%esi
400051c9:	8b 7d 94             	mov    -0x6c(%ebp),%edi
400051cc:	8b 4d 90             	mov    -0x70(%ebp),%ecx
400051cf:	cd 30                	int    $0x30
	// Copy the stack into its correct position in child 0.
	sys_put(SYS_COPY, 0, NULL, (void*)VM_SCRATCHLO,
		(void*)VM_STACKHI-PTSIZE, PTSIZE);
	return esp;
400051d1:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
400051d4:	83 c4 7c             	add    $0x7c,%esp
400051d7:	5b                   	pop    %ebx
400051d8:	5e                   	pop    %esi
400051d9:	5f                   	pop    %edi
400051da:	5d                   	pop    %ebp
400051db:	c3                   	ret    

400051dc <writebuf>:
};


static void
writebuf(struct printbuf *b)
{
400051dc:	55                   	push   %ebp
400051dd:	89 e5                	mov    %esp,%ebp
400051df:	83 ec 28             	sub    $0x28,%esp
	if (!b->err) {
400051e2:	8b 45 08             	mov    0x8(%ebp),%eax
400051e5:	8b 40 0c             	mov    0xc(%eax),%eax
400051e8:	85 c0                	test   %eax,%eax
400051ea:	75 56                	jne    40005242 <writebuf+0x66>
		size_t result = fwrite(b->buf, 1, b->idx, b->fh);
400051ec:	8b 45 08             	mov    0x8(%ebp),%eax
400051ef:	8b 10                	mov    (%eax),%edx
400051f1:	8b 45 08             	mov    0x8(%ebp),%eax
400051f4:	8b 40 04             	mov    0x4(%eax),%eax
400051f7:	8b 4d 08             	mov    0x8(%ebp),%ecx
400051fa:	83 c1 10             	add    $0x10,%ecx
400051fd:	89 54 24 0c          	mov    %edx,0xc(%esp)
40005201:	89 44 24 08          	mov    %eax,0x8(%esp)
40005205:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
4000520c:	00 
4000520d:	89 0c 24             	mov    %ecx,(%esp)
40005210:	e8 75 e0 ff ff       	call   4000328a <fwrite>
40005215:	89 45 f4             	mov    %eax,-0xc(%ebp)
		b->result += result;
40005218:	8b 45 08             	mov    0x8(%ebp),%eax
4000521b:	8b 40 08             	mov    0x8(%eax),%eax
4000521e:	89 c2                	mov    %eax,%edx
40005220:	8b 45 f4             	mov    -0xc(%ebp),%eax
40005223:	01 d0                	add    %edx,%eax
40005225:	89 c2                	mov    %eax,%edx
40005227:	8b 45 08             	mov    0x8(%ebp),%eax
4000522a:	89 50 08             	mov    %edx,0x8(%eax)
		if (result != b->idx) // error, or wrote less than supplied
4000522d:	8b 45 08             	mov    0x8(%ebp),%eax
40005230:	8b 40 04             	mov    0x4(%eax),%eax
40005233:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40005236:	74 0a                	je     40005242 <writebuf+0x66>
			b->err = 1;
40005238:	8b 45 08             	mov    0x8(%ebp),%eax
4000523b:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
	}
}
40005242:	c9                   	leave  
40005243:	c3                   	ret    

40005244 <putch>:

static void
putch(int ch, void *thunk)
{
40005244:	55                   	push   %ebp
40005245:	89 e5                	mov    %esp,%ebp
40005247:	83 ec 28             	sub    $0x28,%esp
	struct printbuf *b = (struct printbuf *) thunk;
4000524a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000524d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	b->buf[b->idx++] = ch;
40005250:	8b 45 f4             	mov    -0xc(%ebp),%eax
40005253:	8b 40 04             	mov    0x4(%eax),%eax
40005256:	8b 55 08             	mov    0x8(%ebp),%edx
40005259:	89 d1                	mov    %edx,%ecx
4000525b:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000525e:	88 4c 02 10          	mov    %cl,0x10(%edx,%eax,1)
40005262:	8d 50 01             	lea    0x1(%eax),%edx
40005265:	8b 45 f4             	mov    -0xc(%ebp),%eax
40005268:	89 50 04             	mov    %edx,0x4(%eax)
	if (b->idx == 256) {
4000526b:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000526e:	8b 40 04             	mov    0x4(%eax),%eax
40005271:	3d 00 01 00 00       	cmp    $0x100,%eax
40005276:	75 15                	jne    4000528d <putch+0x49>
		writebuf(b);
40005278:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000527b:	89 04 24             	mov    %eax,(%esp)
4000527e:	e8 59 ff ff ff       	call   400051dc <writebuf>
		b->idx = 0;
40005283:	8b 45 f4             	mov    -0xc(%ebp),%eax
40005286:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	}
}
4000528d:	c9                   	leave  
4000528e:	c3                   	ret    

4000528f <vfprintf>:

int
vfprintf(FILE *fh, const char *fmt, va_list ap)
{
4000528f:	55                   	push   %ebp
40005290:	89 e5                	mov    %esp,%ebp
40005292:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.fh = fh;
40005298:	8b 45 08             	mov    0x8(%ebp),%eax
4000529b:	89 85 e8 fe ff ff    	mov    %eax,-0x118(%ebp)
	b.idx = 0;
400052a1:	c7 85 ec fe ff ff 00 	movl   $0x0,-0x114(%ebp)
400052a8:	00 00 00 
	b.result = 0;
400052ab:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
400052b2:	00 00 00 
	b.err = 0;
400052b5:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
400052bc:	00 00 00 
	vprintfmt(putch, &b, fmt, ap);
400052bf:	8b 45 10             	mov    0x10(%ebp),%eax
400052c2:	89 44 24 0c          	mov    %eax,0xc(%esp)
400052c6:	8b 45 0c             	mov    0xc(%ebp),%eax
400052c9:	89 44 24 08          	mov    %eax,0x8(%esp)
400052cd:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
400052d3:	89 44 24 04          	mov    %eax,0x4(%esp)
400052d7:	c7 04 24 44 52 00 40 	movl   $0x40005244,(%esp)
400052de:	e8 3e bd ff ff       	call   40001021 <vprintfmt>
	if (b.idx > 0)
400052e3:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
400052e9:	85 c0                	test   %eax,%eax
400052eb:	7e 0e                	jle    400052fb <vfprintf+0x6c>
		writebuf(&b);
400052ed:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
400052f3:	89 04 24             	mov    %eax,(%esp)
400052f6:	e8 e1 fe ff ff       	call   400051dc <writebuf>

	return b.result;
400052fb:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
}
40005301:	c9                   	leave  
40005302:	c3                   	ret    

40005303 <fprintf>:

int
fprintf(FILE *fh, const char *fmt, ...)
{
40005303:	55                   	push   %ebp
40005304:	89 e5                	mov    %esp,%ebp
40005306:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
40005309:	8d 45 0c             	lea    0xc(%ebp),%eax
4000530c:	83 c0 04             	add    $0x4,%eax
4000530f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vfprintf(fh, fmt, ap);
40005312:	8b 45 0c             	mov    0xc(%ebp),%eax
40005315:	8b 55 f4             	mov    -0xc(%ebp),%edx
40005318:	89 54 24 08          	mov    %edx,0x8(%esp)
4000531c:	89 44 24 04          	mov    %eax,0x4(%esp)
40005320:	8b 45 08             	mov    0x8(%ebp),%eax
40005323:	89 04 24             	mov    %eax,(%esp)
40005326:	e8 64 ff ff ff       	call   4000528f <vfprintf>
4000532b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
4000532e:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40005331:	c9                   	leave  
40005332:	c3                   	ret    

40005333 <printf>:

int
printf(const char *fmt, ...)
{
40005333:	55                   	push   %ebp
40005334:	89 e5                	mov    %esp,%ebp
40005336:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
40005339:	8d 45 0c             	lea    0xc(%ebp),%eax
4000533c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vfprintf(stdout, fmt, ap);
4000533f:	8b 55 08             	mov    0x8(%ebp),%edx
40005342:	a1 8c 60 00 40       	mov    0x4000608c,%eax
40005347:	8b 4d f4             	mov    -0xc(%ebp),%ecx
4000534a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
4000534e:	89 54 24 04          	mov    %edx,0x4(%esp)
40005352:	89 04 24             	mov    %eax,(%esp)
40005355:	e8 35 ff ff ff       	call   4000528f <vfprintf>
4000535a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
4000535d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40005360:	c9                   	leave  
40005361:	c3                   	ret    
40005362:	66 90                	xchg   %ax,%ax

40005364 <strerror>:
#include <inc/stdio.h>

char *
strerror(int err)
{
40005364:	55                   	push   %ebp
40005365:	89 e5                	mov    %esp,%ebp
40005367:	83 ec 28             	sub    $0x28,%esp
		"No child processes",
		"Conflict detected",
	};
	static char errbuf[64];

	const int tablen = sizeof(errtab)/sizeof(errtab[0]);
4000536a:	c7 45 f4 0b 00 00 00 	movl   $0xb,-0xc(%ebp)
	if (err >= 0 && err < sizeof(errtab)/sizeof(errtab[0]))
40005371:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40005375:	78 14                	js     4000538b <strerror+0x27>
40005377:	8b 45 08             	mov    0x8(%ebp),%eax
4000537a:	83 f8 0a             	cmp    $0xa,%eax
4000537d:	77 0c                	ja     4000538b <strerror+0x27>
		return errtab[err];
4000537f:	8b 45 08             	mov    0x8(%ebp),%eax
40005382:	8b 04 85 c0 83 00 40 	mov    0x400083c0(,%eax,4),%eax
40005389:	eb 20                	jmp    400053ab <strerror+0x47>

	sprintf(errbuf, "Unknown error code %d", err);
4000538b:	8b 45 08             	mov    0x8(%ebp),%eax
4000538e:	89 44 24 08          	mov    %eax,0x8(%esp)
40005392:	c7 44 24 04 60 64 00 	movl   $0x40006460,0x4(%esp)
40005399:	40 
4000539a:	c7 04 24 20 84 00 40 	movl   $0x40008420,(%esp)
400053a1:	e8 0f 02 00 00       	call   400055b5 <sprintf>
	return errbuf;
400053a6:	b8 20 84 00 40       	mov    $0x40008420,%eax
}
400053ab:	c9                   	leave  
400053ac:	c3                   	ret    
400053ad:	66 90                	xchg   %ax,%ax
400053af:	90                   	nop

400053b0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
400053b0:	55                   	push   %ebp
400053b1:	89 e5                	mov    %esp,%ebp
400053b3:	83 ec 28             	sub    $0x28,%esp
	int i, c, echoing;

	if (prompt != NULL)
400053b6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400053ba:	74 1c                	je     400053d8 <readline+0x28>
		fprintf(stdout, "%s", prompt);
400053bc:	a1 8c 60 00 40       	mov    0x4000608c,%eax
400053c1:	8b 55 08             	mov    0x8(%ebp),%edx
400053c4:	89 54 24 08          	mov    %edx,0x8(%esp)
400053c8:	c7 44 24 04 52 65 00 	movl   $0x40006552,0x4(%esp)
400053cf:	40 
400053d0:	89 04 24             	mov    %eax,(%esp)
400053d3:	e8 2b ff ff ff       	call   40005303 <fprintf>

	i = 0;
400053d8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	echoing = isatty(0);
400053df:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400053e6:	e8 30 e5 ff ff       	call   4000391b <isatty>
400053eb:	89 45 f0             	mov    %eax,-0x10(%ebp)
400053ee:	eb 01                	jmp    400053f1 <readline+0x41>
				fflush(stdout);
			}
			buf[i] = 0;
			return buf;
		}
	}
400053f0:	90                   	nop
		fprintf(stdout, "%s", prompt);

	i = 0;
	echoing = isatty(0);
	while (1) {
		c = getchar();
400053f1:	a1 88 60 00 40       	mov    0x40006088,%eax
400053f6:	89 04 24             	mov    %eax,(%esp)
400053f9:	e8 d6 dd ff ff       	call   400031d4 <fgetc>
400053fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (c < 0) {
40005401:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
40005405:	79 23                	jns    4000542a <readline+0x7a>
			if (c != EOF)
40005407:	83 7d ec ff          	cmpl   $0xffffffff,-0x14(%ebp)
4000540b:	74 13                	je     40005420 <readline+0x70>
				cprintf("read error: %e\n", c);
4000540d:	8b 45 ec             	mov    -0x14(%ebp),%eax
40005410:	89 44 24 04          	mov    %eax,0x4(%esp)
40005414:	c7 04 24 55 65 00 40 	movl   $0x40006555,(%esp)
4000541b:	e8 b8 b8 ff ff       	call   40000cd8 <cprintf>
			return NULL;
40005420:	b8 00 00 00 00       	mov    $0x0,%eax
40005425:	e9 c2 00 00 00       	jmp    400054ec <readline+0x13c>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
4000542a:	83 7d ec 08          	cmpl   $0x8,-0x14(%ebp)
4000542e:	74 06                	je     40005436 <readline+0x86>
40005430:	83 7d ec 7f          	cmpl   $0x7f,-0x14(%ebp)
40005434:	75 2a                	jne    40005460 <readline+0xb0>
40005436:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
4000543a:	7e 24                	jle    40005460 <readline+0xb0>
			if (echoing)
4000543c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40005440:	74 15                	je     40005457 <readline+0xa7>
				putchar('\b');
40005442:	a1 8c 60 00 40       	mov    0x4000608c,%eax
40005447:	89 44 24 04          	mov    %eax,0x4(%esp)
4000544b:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
40005452:	e8 b9 dd ff ff       	call   40003210 <fputc>
			i--;
40005457:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
4000545b:	e9 87 00 00 00       	jmp    400054e7 <readline+0x137>
		} else if (c >= ' ' && i < BUFLEN-1) {
40005460:	83 7d ec 1f          	cmpl   $0x1f,-0x14(%ebp)
40005464:	7e 37                	jle    4000549d <readline+0xed>
40005466:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
4000546d:	7f 2e                	jg     4000549d <readline+0xed>
			if (echoing)
4000546f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40005473:	74 14                	je     40005489 <readline+0xd9>
				putchar(c);
40005475:	a1 8c 60 00 40       	mov    0x4000608c,%eax
4000547a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000547e:	8b 45 ec             	mov    -0x14(%ebp),%eax
40005481:	89 04 24             	mov    %eax,(%esp)
40005484:	e8 87 dd ff ff       	call   40003210 <fputc>
			buf[i++] = c;
40005489:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000548c:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000548f:	81 c2 60 84 00 40    	add    $0x40008460,%edx
40005495:	88 02                	mov    %al,(%edx)
40005497:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
4000549b:	eb 4a                	jmp    400054e7 <readline+0x137>
		} else if (c == '\n' || c == '\r') {
4000549d:	83 7d ec 0a          	cmpl   $0xa,-0x14(%ebp)
400054a1:	74 0a                	je     400054ad <readline+0xfd>
400054a3:	83 7d ec 0d          	cmpl   $0xd,-0x14(%ebp)
400054a7:	0f 85 43 ff ff ff    	jne    400053f0 <readline+0x40>
			if (echoing) {
400054ad:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400054b1:	74 22                	je     400054d5 <readline+0x125>
				putchar('\n');
400054b3:	a1 8c 60 00 40       	mov    0x4000608c,%eax
400054b8:	89 44 24 04          	mov    %eax,0x4(%esp)
400054bc:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
400054c3:	e8 48 dd ff ff       	call   40003210 <fputc>
				fflush(stdout);
400054c8:	a1 8c 60 00 40       	mov    0x4000608c,%eax
400054cd:	89 04 24             	mov    %eax,(%esp)
400054d0:	e8 bd df ff ff       	call   40003492 <fflush>
			}
			buf[i] = 0;
400054d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
400054d8:	05 60 84 00 40       	add    $0x40008460,%eax
400054dd:	c6 00 00             	movb   $0x0,(%eax)
			return buf;
400054e0:	b8 60 84 00 40       	mov    $0x40008460,%eax
400054e5:	eb 05                	jmp    400054ec <readline+0x13c>
		}
	}
400054e7:	e9 04 ff ff ff       	jmp    400053f0 <readline+0x40>
}
400054ec:	c9                   	leave  
400054ed:	c3                   	ret    
400054ee:	66 90                	xchg   %ax,%ax

400054f0 <cputs>:

#include <inc/stdio.h>
#include <inc/syscall.h>

void cputs(const char *str)
{
400054f0:	55                   	push   %ebp
400054f1:	89 e5                	mov    %esp,%ebp
400054f3:	53                   	push   %ebx
400054f4:	83 ec 10             	sub    $0x10,%esp
400054f7:	8b 45 08             	mov    0x8(%ebp),%eax
400054fa:	89 45 f8             	mov    %eax,-0x8(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
400054fd:	b8 00 00 00 00       	mov    $0x0,%eax
40005502:	8b 55 f8             	mov    -0x8(%ebp),%edx
40005505:	89 d3                	mov    %edx,%ebx
40005507:	cd 30                	int    $0x30
	sys_cputs(str);
}
40005509:	83 c4 10             	add    $0x10,%esp
4000550c:	5b                   	pop    %ebx
4000550d:	5d                   	pop    %ebp
4000550e:	c3                   	ret    
4000550f:	90                   	nop

40005510 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
40005510:	55                   	push   %ebp
40005511:	89 e5                	mov    %esp,%ebp
	b->cnt++;
40005513:	8b 45 0c             	mov    0xc(%ebp),%eax
40005516:	8b 40 08             	mov    0x8(%eax),%eax
40005519:	8d 50 01             	lea    0x1(%eax),%edx
4000551c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000551f:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
40005522:	8b 45 0c             	mov    0xc(%ebp),%eax
40005525:	8b 10                	mov    (%eax),%edx
40005527:	8b 45 0c             	mov    0xc(%ebp),%eax
4000552a:	8b 40 04             	mov    0x4(%eax),%eax
4000552d:	39 c2                	cmp    %eax,%edx
4000552f:	73 12                	jae    40005543 <sprintputch+0x33>
		*b->buf++ = ch;
40005531:	8b 45 0c             	mov    0xc(%ebp),%eax
40005534:	8b 00                	mov    (%eax),%eax
40005536:	8b 55 08             	mov    0x8(%ebp),%edx
40005539:	88 10                	mov    %dl,(%eax)
4000553b:	8d 50 01             	lea    0x1(%eax),%edx
4000553e:	8b 45 0c             	mov    0xc(%ebp),%eax
40005541:	89 10                	mov    %edx,(%eax)
}
40005543:	5d                   	pop    %ebp
40005544:	c3                   	ret    

40005545 <vsprintf>:

int
vsprintf(char *buf, const char *fmt, va_list ap)
{
40005545:	55                   	push   %ebp
40005546:	89 e5                	mov    %esp,%ebp
40005548:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL);
4000554b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
4000554f:	75 24                	jne    40005575 <vsprintf+0x30>
40005551:	c7 44 24 0c 65 65 00 	movl   $0x40006565,0xc(%esp)
40005558:	40 
40005559:	c7 44 24 08 71 65 00 	movl   $0x40006571,0x8(%esp)
40005560:	40 
40005561:	c7 44 24 04 19 00 00 	movl   $0x19,0x4(%esp)
40005568:	00 
40005569:	c7 04 24 86 65 00 40 	movl   $0x40006586,(%esp)
40005570:	e8 cf b4 ff ff       	call   40000a44 <debug_panic>
	struct sprintbuf b = {buf, (char*)(intptr_t)~0, 0};
40005575:	8b 45 08             	mov    0x8(%ebp),%eax
40005578:	89 45 ec             	mov    %eax,-0x14(%ebp)
4000557b:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
40005582:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
40005589:	8b 45 10             	mov    0x10(%ebp),%eax
4000558c:	89 44 24 0c          	mov    %eax,0xc(%esp)
40005590:	8b 45 0c             	mov    0xc(%ebp),%eax
40005593:	89 44 24 08          	mov    %eax,0x8(%esp)
40005597:	8d 45 ec             	lea    -0x14(%ebp),%eax
4000559a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000559e:	c7 04 24 10 55 00 40 	movl   $0x40005510,(%esp)
400055a5:	e8 77 ba ff ff       	call   40001021 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
400055aa:	8b 45 ec             	mov    -0x14(%ebp),%eax
400055ad:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
400055b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
400055b3:	c9                   	leave  
400055b4:	c3                   	ret    

400055b5 <sprintf>:

int
sprintf(char *buf, const char *fmt, ...)
{
400055b5:	55                   	push   %ebp
400055b6:	89 e5                	mov    %esp,%ebp
400055b8:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
400055bb:	8d 45 0c             	lea    0xc(%ebp),%eax
400055be:	83 c0 04             	add    $0x4,%eax
400055c1:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsprintf(buf, fmt, ap);
400055c4:	8b 45 0c             	mov    0xc(%ebp),%eax
400055c7:	8b 55 f4             	mov    -0xc(%ebp),%edx
400055ca:	89 54 24 08          	mov    %edx,0x8(%esp)
400055ce:	89 44 24 04          	mov    %eax,0x4(%esp)
400055d2:	8b 45 08             	mov    0x8(%ebp),%eax
400055d5:	89 04 24             	mov    %eax,(%esp)
400055d8:	e8 68 ff ff ff       	call   40005545 <vsprintf>
400055dd:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
400055e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
400055e3:	c9                   	leave  
400055e4:	c3                   	ret    

400055e5 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
400055e5:	55                   	push   %ebp
400055e6:	89 e5                	mov    %esp,%ebp
400055e8:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL && n > 0);
400055eb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400055ef:	74 06                	je     400055f7 <vsnprintf+0x12>
400055f1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400055f5:	7f 24                	jg     4000561b <vsnprintf+0x36>
400055f7:	c7 44 24 0c 94 65 00 	movl   $0x40006594,0xc(%esp)
400055fe:	40 
400055ff:	c7 44 24 08 71 65 00 	movl   $0x40006571,0x8(%esp)
40005606:	40 
40005607:	c7 44 24 04 35 00 00 	movl   $0x35,0x4(%esp)
4000560e:	00 
4000560f:	c7 04 24 86 65 00 40 	movl   $0x40006586,(%esp)
40005616:	e8 29 b4 ff ff       	call   40000a44 <debug_panic>
	struct sprintbuf b = {buf, buf+n-1, 0};
4000561b:	8b 45 08             	mov    0x8(%ebp),%eax
4000561e:	89 45 ec             	mov    %eax,-0x14(%ebp)
40005621:	8b 45 0c             	mov    0xc(%ebp),%eax
40005624:	8d 50 ff             	lea    -0x1(%eax),%edx
40005627:	8b 45 08             	mov    0x8(%ebp),%eax
4000562a:	01 d0                	add    %edx,%eax
4000562c:	89 45 f0             	mov    %eax,-0x10(%ebp)
4000562f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
40005636:	8b 45 14             	mov    0x14(%ebp),%eax
40005639:	89 44 24 0c          	mov    %eax,0xc(%esp)
4000563d:	8b 45 10             	mov    0x10(%ebp),%eax
40005640:	89 44 24 08          	mov    %eax,0x8(%esp)
40005644:	8d 45 ec             	lea    -0x14(%ebp),%eax
40005647:	89 44 24 04          	mov    %eax,0x4(%esp)
4000564b:	c7 04 24 10 55 00 40 	movl   $0x40005510,(%esp)
40005652:	e8 ca b9 ff ff       	call   40001021 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
40005657:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000565a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
4000565d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
40005660:	c9                   	leave  
40005661:	c3                   	ret    

40005662 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
40005662:	55                   	push   %ebp
40005663:	89 e5                	mov    %esp,%ebp
40005665:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
40005668:	8d 45 10             	lea    0x10(%ebp),%eax
4000566b:	83 c0 04             	add    $0x4,%eax
4000566e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
40005671:	8b 45 10             	mov    0x10(%ebp),%eax
40005674:	8b 55 f4             	mov    -0xc(%ebp),%edx
40005677:	89 54 24 0c          	mov    %edx,0xc(%esp)
4000567b:	89 44 24 08          	mov    %eax,0x8(%esp)
4000567f:	8b 45 0c             	mov    0xc(%ebp),%eax
40005682:	89 44 24 04          	mov    %eax,0x4(%esp)
40005686:	8b 45 08             	mov    0x8(%ebp),%eax
40005689:	89 04 24             	mov    %eax,(%esp)
4000568c:	e8 54 ff ff ff       	call   400055e5 <vsnprintf>
40005691:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
40005694:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40005697:	c9                   	leave  
40005698:	c3                   	ret    
40005699:	66 90                	xchg   %ax,%ax
4000569b:	66 90                	xchg   %ax,%ax
4000569d:	66 90                	xchg   %ax,%ax
4000569f:	90                   	nop

400056a0 <__udivdi3>:
400056a0:	83 ec 1c             	sub    $0x1c,%esp
400056a3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
400056a7:	89 7c 24 14          	mov    %edi,0x14(%esp)
400056ab:	8b 4c 24 28          	mov    0x28(%esp),%ecx
400056af:	89 6c 24 18          	mov    %ebp,0x18(%esp)
400056b3:	8b 7c 24 20          	mov    0x20(%esp),%edi
400056b7:	8b 6c 24 24          	mov    0x24(%esp),%ebp
400056bb:	85 c0                	test   %eax,%eax
400056bd:	89 74 24 10          	mov    %esi,0x10(%esp)
400056c1:	89 7c 24 08          	mov    %edi,0x8(%esp)
400056c5:	89 ea                	mov    %ebp,%edx
400056c7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
400056cb:	75 33                	jne    40005700 <__udivdi3+0x60>
400056cd:	39 e9                	cmp    %ebp,%ecx
400056cf:	77 6f                	ja     40005740 <__udivdi3+0xa0>
400056d1:	85 c9                	test   %ecx,%ecx
400056d3:	89 ce                	mov    %ecx,%esi
400056d5:	75 0b                	jne    400056e2 <__udivdi3+0x42>
400056d7:	b8 01 00 00 00       	mov    $0x1,%eax
400056dc:	31 d2                	xor    %edx,%edx
400056de:	f7 f1                	div    %ecx
400056e0:	89 c6                	mov    %eax,%esi
400056e2:	31 d2                	xor    %edx,%edx
400056e4:	89 e8                	mov    %ebp,%eax
400056e6:	f7 f6                	div    %esi
400056e8:	89 c5                	mov    %eax,%ebp
400056ea:	89 f8                	mov    %edi,%eax
400056ec:	f7 f6                	div    %esi
400056ee:	89 ea                	mov    %ebp,%edx
400056f0:	8b 74 24 10          	mov    0x10(%esp),%esi
400056f4:	8b 7c 24 14          	mov    0x14(%esp),%edi
400056f8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
400056fc:	83 c4 1c             	add    $0x1c,%esp
400056ff:	c3                   	ret    
40005700:	39 e8                	cmp    %ebp,%eax
40005702:	77 24                	ja     40005728 <__udivdi3+0x88>
40005704:	0f bd c8             	bsr    %eax,%ecx
40005707:	83 f1 1f             	xor    $0x1f,%ecx
4000570a:	89 0c 24             	mov    %ecx,(%esp)
4000570d:	75 49                	jne    40005758 <__udivdi3+0xb8>
4000570f:	8b 74 24 08          	mov    0x8(%esp),%esi
40005713:	39 74 24 04          	cmp    %esi,0x4(%esp)
40005717:	0f 86 ab 00 00 00    	jbe    400057c8 <__udivdi3+0x128>
4000571d:	39 e8                	cmp    %ebp,%eax
4000571f:	0f 82 a3 00 00 00    	jb     400057c8 <__udivdi3+0x128>
40005725:	8d 76 00             	lea    0x0(%esi),%esi
40005728:	31 d2                	xor    %edx,%edx
4000572a:	31 c0                	xor    %eax,%eax
4000572c:	8b 74 24 10          	mov    0x10(%esp),%esi
40005730:	8b 7c 24 14          	mov    0x14(%esp),%edi
40005734:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40005738:	83 c4 1c             	add    $0x1c,%esp
4000573b:	c3                   	ret    
4000573c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40005740:	89 f8                	mov    %edi,%eax
40005742:	f7 f1                	div    %ecx
40005744:	31 d2                	xor    %edx,%edx
40005746:	8b 74 24 10          	mov    0x10(%esp),%esi
4000574a:	8b 7c 24 14          	mov    0x14(%esp),%edi
4000574e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40005752:	83 c4 1c             	add    $0x1c,%esp
40005755:	c3                   	ret    
40005756:	66 90                	xchg   %ax,%ax
40005758:	0f b6 0c 24          	movzbl (%esp),%ecx
4000575c:	89 c6                	mov    %eax,%esi
4000575e:	b8 20 00 00 00       	mov    $0x20,%eax
40005763:	8b 6c 24 04          	mov    0x4(%esp),%ebp
40005767:	2b 04 24             	sub    (%esp),%eax
4000576a:	8b 7c 24 08          	mov    0x8(%esp),%edi
4000576e:	d3 e6                	shl    %cl,%esi
40005770:	89 c1                	mov    %eax,%ecx
40005772:	d3 ed                	shr    %cl,%ebp
40005774:	0f b6 0c 24          	movzbl (%esp),%ecx
40005778:	09 f5                	or     %esi,%ebp
4000577a:	8b 74 24 04          	mov    0x4(%esp),%esi
4000577e:	d3 e6                	shl    %cl,%esi
40005780:	89 c1                	mov    %eax,%ecx
40005782:	89 74 24 04          	mov    %esi,0x4(%esp)
40005786:	89 d6                	mov    %edx,%esi
40005788:	d3 ee                	shr    %cl,%esi
4000578a:	0f b6 0c 24          	movzbl (%esp),%ecx
4000578e:	d3 e2                	shl    %cl,%edx
40005790:	89 c1                	mov    %eax,%ecx
40005792:	d3 ef                	shr    %cl,%edi
40005794:	09 d7                	or     %edx,%edi
40005796:	89 f2                	mov    %esi,%edx
40005798:	89 f8                	mov    %edi,%eax
4000579a:	f7 f5                	div    %ebp
4000579c:	89 d6                	mov    %edx,%esi
4000579e:	89 c7                	mov    %eax,%edi
400057a0:	f7 64 24 04          	mull   0x4(%esp)
400057a4:	39 d6                	cmp    %edx,%esi
400057a6:	72 30                	jb     400057d8 <__udivdi3+0x138>
400057a8:	8b 6c 24 08          	mov    0x8(%esp),%ebp
400057ac:	0f b6 0c 24          	movzbl (%esp),%ecx
400057b0:	d3 e5                	shl    %cl,%ebp
400057b2:	39 c5                	cmp    %eax,%ebp
400057b4:	73 04                	jae    400057ba <__udivdi3+0x11a>
400057b6:	39 d6                	cmp    %edx,%esi
400057b8:	74 1e                	je     400057d8 <__udivdi3+0x138>
400057ba:	89 f8                	mov    %edi,%eax
400057bc:	31 d2                	xor    %edx,%edx
400057be:	e9 69 ff ff ff       	jmp    4000572c <__udivdi3+0x8c>
400057c3:	90                   	nop
400057c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
400057c8:	31 d2                	xor    %edx,%edx
400057ca:	b8 01 00 00 00       	mov    $0x1,%eax
400057cf:	e9 58 ff ff ff       	jmp    4000572c <__udivdi3+0x8c>
400057d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
400057d8:	8d 47 ff             	lea    -0x1(%edi),%eax
400057db:	31 d2                	xor    %edx,%edx
400057dd:	8b 74 24 10          	mov    0x10(%esp),%esi
400057e1:	8b 7c 24 14          	mov    0x14(%esp),%edi
400057e5:	8b 6c 24 18          	mov    0x18(%esp),%ebp
400057e9:	83 c4 1c             	add    $0x1c,%esp
400057ec:	c3                   	ret    
400057ed:	66 90                	xchg   %ax,%ax
400057ef:	90                   	nop

400057f0 <__umoddi3>:
400057f0:	83 ec 2c             	sub    $0x2c,%esp
400057f3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
400057f7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
400057fb:	89 74 24 20          	mov    %esi,0x20(%esp)
400057ff:	8b 74 24 38          	mov    0x38(%esp),%esi
40005803:	89 7c 24 24          	mov    %edi,0x24(%esp)
40005807:	8b 7c 24 34          	mov    0x34(%esp),%edi
4000580b:	85 c0                	test   %eax,%eax
4000580d:	89 c2                	mov    %eax,%edx
4000580f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
40005813:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
40005817:	89 7c 24 0c          	mov    %edi,0xc(%esp)
4000581b:	89 74 24 10          	mov    %esi,0x10(%esp)
4000581f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
40005823:	89 7c 24 18          	mov    %edi,0x18(%esp)
40005827:	75 1f                	jne    40005848 <__umoddi3+0x58>
40005829:	39 fe                	cmp    %edi,%esi
4000582b:	76 63                	jbe    40005890 <__umoddi3+0xa0>
4000582d:	89 c8                	mov    %ecx,%eax
4000582f:	89 fa                	mov    %edi,%edx
40005831:	f7 f6                	div    %esi
40005833:	89 d0                	mov    %edx,%eax
40005835:	31 d2                	xor    %edx,%edx
40005837:	8b 74 24 20          	mov    0x20(%esp),%esi
4000583b:	8b 7c 24 24          	mov    0x24(%esp),%edi
4000583f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
40005843:	83 c4 2c             	add    $0x2c,%esp
40005846:	c3                   	ret    
40005847:	90                   	nop
40005848:	39 f8                	cmp    %edi,%eax
4000584a:	77 64                	ja     400058b0 <__umoddi3+0xc0>
4000584c:	0f bd e8             	bsr    %eax,%ebp
4000584f:	83 f5 1f             	xor    $0x1f,%ebp
40005852:	75 74                	jne    400058c8 <__umoddi3+0xd8>
40005854:	8b 7c 24 14          	mov    0x14(%esp),%edi
40005858:	39 7c 24 10          	cmp    %edi,0x10(%esp)
4000585c:	0f 87 0e 01 00 00    	ja     40005970 <__umoddi3+0x180>
40005862:	8b 7c 24 0c          	mov    0xc(%esp),%edi
40005866:	29 f1                	sub    %esi,%ecx
40005868:	19 c7                	sbb    %eax,%edi
4000586a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
4000586e:	89 7c 24 18          	mov    %edi,0x18(%esp)
40005872:	8b 44 24 14          	mov    0x14(%esp),%eax
40005876:	8b 54 24 18          	mov    0x18(%esp),%edx
4000587a:	8b 74 24 20          	mov    0x20(%esp),%esi
4000587e:	8b 7c 24 24          	mov    0x24(%esp),%edi
40005882:	8b 6c 24 28          	mov    0x28(%esp),%ebp
40005886:	83 c4 2c             	add    $0x2c,%esp
40005889:	c3                   	ret    
4000588a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
40005890:	85 f6                	test   %esi,%esi
40005892:	89 f5                	mov    %esi,%ebp
40005894:	75 0b                	jne    400058a1 <__umoddi3+0xb1>
40005896:	b8 01 00 00 00       	mov    $0x1,%eax
4000589b:	31 d2                	xor    %edx,%edx
4000589d:	f7 f6                	div    %esi
4000589f:	89 c5                	mov    %eax,%ebp
400058a1:	8b 44 24 0c          	mov    0xc(%esp),%eax
400058a5:	31 d2                	xor    %edx,%edx
400058a7:	f7 f5                	div    %ebp
400058a9:	89 c8                	mov    %ecx,%eax
400058ab:	f7 f5                	div    %ebp
400058ad:	eb 84                	jmp    40005833 <__umoddi3+0x43>
400058af:	90                   	nop
400058b0:	89 c8                	mov    %ecx,%eax
400058b2:	89 fa                	mov    %edi,%edx
400058b4:	8b 74 24 20          	mov    0x20(%esp),%esi
400058b8:	8b 7c 24 24          	mov    0x24(%esp),%edi
400058bc:	8b 6c 24 28          	mov    0x28(%esp),%ebp
400058c0:	83 c4 2c             	add    $0x2c,%esp
400058c3:	c3                   	ret    
400058c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
400058c8:	8b 44 24 10          	mov    0x10(%esp),%eax
400058cc:	be 20 00 00 00       	mov    $0x20,%esi
400058d1:	89 e9                	mov    %ebp,%ecx
400058d3:	29 ee                	sub    %ebp,%esi
400058d5:	d3 e2                	shl    %cl,%edx
400058d7:	89 f1                	mov    %esi,%ecx
400058d9:	d3 e8                	shr    %cl,%eax
400058db:	89 e9                	mov    %ebp,%ecx
400058dd:	09 d0                	or     %edx,%eax
400058df:	89 fa                	mov    %edi,%edx
400058e1:	89 44 24 0c          	mov    %eax,0xc(%esp)
400058e5:	8b 44 24 10          	mov    0x10(%esp),%eax
400058e9:	d3 e0                	shl    %cl,%eax
400058eb:	89 f1                	mov    %esi,%ecx
400058ed:	89 44 24 10          	mov    %eax,0x10(%esp)
400058f1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
400058f5:	d3 ea                	shr    %cl,%edx
400058f7:	89 e9                	mov    %ebp,%ecx
400058f9:	d3 e7                	shl    %cl,%edi
400058fb:	89 f1                	mov    %esi,%ecx
400058fd:	d3 e8                	shr    %cl,%eax
400058ff:	89 e9                	mov    %ebp,%ecx
40005901:	09 f8                	or     %edi,%eax
40005903:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
40005907:	f7 74 24 0c          	divl   0xc(%esp)
4000590b:	d3 e7                	shl    %cl,%edi
4000590d:	89 7c 24 18          	mov    %edi,0x18(%esp)
40005911:	89 d7                	mov    %edx,%edi
40005913:	f7 64 24 10          	mull   0x10(%esp)
40005917:	39 d7                	cmp    %edx,%edi
40005919:	89 c1                	mov    %eax,%ecx
4000591b:	89 54 24 14          	mov    %edx,0x14(%esp)
4000591f:	72 3b                	jb     4000595c <__umoddi3+0x16c>
40005921:	39 44 24 18          	cmp    %eax,0x18(%esp)
40005925:	72 31                	jb     40005958 <__umoddi3+0x168>
40005927:	8b 44 24 18          	mov    0x18(%esp),%eax
4000592b:	29 c8                	sub    %ecx,%eax
4000592d:	19 d7                	sbb    %edx,%edi
4000592f:	89 e9                	mov    %ebp,%ecx
40005931:	89 fa                	mov    %edi,%edx
40005933:	d3 e8                	shr    %cl,%eax
40005935:	89 f1                	mov    %esi,%ecx
40005937:	d3 e2                	shl    %cl,%edx
40005939:	89 e9                	mov    %ebp,%ecx
4000593b:	09 d0                	or     %edx,%eax
4000593d:	89 fa                	mov    %edi,%edx
4000593f:	d3 ea                	shr    %cl,%edx
40005941:	8b 74 24 20          	mov    0x20(%esp),%esi
40005945:	8b 7c 24 24          	mov    0x24(%esp),%edi
40005949:	8b 6c 24 28          	mov    0x28(%esp),%ebp
4000594d:	83 c4 2c             	add    $0x2c,%esp
40005950:	c3                   	ret    
40005951:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
40005958:	39 d7                	cmp    %edx,%edi
4000595a:	75 cb                	jne    40005927 <__umoddi3+0x137>
4000595c:	8b 54 24 14          	mov    0x14(%esp),%edx
40005960:	89 c1                	mov    %eax,%ecx
40005962:	2b 4c 24 10          	sub    0x10(%esp),%ecx
40005966:	1b 54 24 0c          	sbb    0xc(%esp),%edx
4000596a:	eb bb                	jmp    40005927 <__umoddi3+0x137>
4000596c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40005970:	3b 44 24 18          	cmp    0x18(%esp),%eax
40005974:	0f 82 e8 fe ff ff    	jb     40005862 <__umoddi3+0x72>
4000597a:	e9 f3 fe ff ff       	jmp    40005872 <__umoddi3+0x82>
