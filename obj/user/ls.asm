
obj/user/ls:     file format elf32-i386


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
4000010c:	e8 ed 02 00 00       	call   400003fe <main>
	pushl	%eax	// use with main's return value as exit status
40000111:	50                   	push   %eax
	call	exit
40000112:	e8 4d 2f 00 00       	call   40003064 <exit>
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

40000144 <ls>:
void lsdir(const char *path, const char *realpath);
void lsfile(const char *path, const char *realpath);

void
ls(const char *path)
{
40000144:	55                   	push   %ebp
40000145:	89 e5                	mov    %esp,%ebp
40000147:	83 ec 38             	sub    $0x38,%esp
	int r;
	struct stat st;

	const char *realpath = path[0] ? path : ".";
4000014a:	8b 45 08             	mov    0x8(%ebp),%eax
4000014d:	0f b6 00             	movzbl (%eax),%eax
40000150:	84 c0                	test   %al,%al
40000152:	74 05                	je     40000159 <ls+0x15>
40000154:	8b 45 08             	mov    0x8(%ebp),%eax
40000157:	eb 05                	jmp    4000015e <ls+0x1a>
40000159:	b8 c0 3c 00 40       	mov    $0x40003cc0,%eax
4000015e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (stat(realpath, &st) < 0)
40000161:	8d 45 e8             	lea    -0x18(%ebp),%eax
40000164:	89 44 24 04          	mov    %eax,0x4(%esp)
40000168:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000016b:	89 04 24             	mov    %eax,(%esp)
4000016e:	e8 72 33 00 00       	call   400034e5 <stat>
40000173:	85 c0                	test   %eax,%eax
40000175:	79 36                	jns    400001ad <ls+0x69>
		panic("stat %s: %s", realpath, strerror(errno));
40000177:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000017c:	8b 00                	mov    (%eax),%eax
4000017e:	89 04 24             	mov    %eax,(%esp)
40000181:	e8 e6 37 00 00       	call   4000396c <strerror>
40000186:	89 44 24 10          	mov    %eax,0x10(%esp)
4000018a:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000018d:	89 44 24 0c          	mov    %eax,0xc(%esp)
40000191:	c7 44 24 08 c2 3c 00 	movl   $0x40003cc2,0x8(%esp)
40000198:	40 
40000199:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
400001a0:	00 
400001a1:	c7 04 24 ce 3c 00 40 	movl   $0x40003cce,(%esp)
400001a8:	e8 ab 03 00 00       	call   40000558 <debug_panic>
	if (S_ISDIR(st.st_mode) && !flag['d'])
400001ad:	8b 45 ec             	mov    -0x14(%ebp),%eax
400001b0:	25 00 70 00 00       	and    $0x7000,%eax
400001b5:	3d 00 20 00 00       	cmp    $0x2000,%eax
400001ba:	75 1d                	jne    400001d9 <ls+0x95>
400001bc:	a1 50 63 00 40       	mov    0x40006350,%eax
400001c1:	85 c0                	test   %eax,%eax
400001c3:	75 14                	jne    400001d9 <ls+0x95>
		lsdir(path, realpath);
400001c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
400001c8:	89 44 24 04          	mov    %eax,0x4(%esp)
400001cc:	8b 45 08             	mov    0x8(%ebp),%eax
400001cf:	89 04 24             	mov    %eax,(%esp)
400001d2:	e8 16 00 00 00       	call   400001ed <lsdir>
400001d7:	eb 12                	jmp    400001eb <ls+0xa7>
	else
		lsfile(path, realpath);
400001d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
400001dc:	89 44 24 04          	mov    %eax,0x4(%esp)
400001e0:	8b 45 08             	mov    0x8(%ebp),%eax
400001e3:	89 04 24             	mov    %eax,(%esp)
400001e6:	e8 fe 00 00 00       	call   400002e9 <lsfile>
}
400001eb:	c9                   	leave  
400001ec:	c3                   	ret    

400001ed <lsdir>:

void
lsdir(const char *path, const char *realpath)
{
400001ed:	55                   	push   %ebp
400001ee:	89 e5                	mov    %esp,%ebp
400001f0:	53                   	push   %ebx
400001f1:	81 ec 34 04 00 00    	sub    $0x434,%esp
	DIR *d;
	struct dirent *de;

	if ((d = opendir(realpath)) == NULL)
400001f7:	8b 45 0c             	mov    0xc(%ebp),%eax
400001fa:	89 04 24             	mov    %eax,(%esp)
400001fd:	e8 53 27 00 00       	call   40002955 <opendir>
40000202:	89 45 f4             	mov    %eax,-0xc(%ebp)
40000205:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40000209:	0f 85 ae 00 00 00    	jne    400002bd <lsdir+0xd0>
		panic("opendir %s: %s", realpath, strerror(errno));
4000020f:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40000214:	8b 00                	mov    (%eax),%eax
40000216:	89 04 24             	mov    %eax,(%esp)
40000219:	e8 4e 37 00 00       	call   4000396c <strerror>
4000021e:	89 44 24 10          	mov    %eax,0x10(%esp)
40000222:	8b 45 0c             	mov    0xc(%ebp),%eax
40000225:	89 44 24 0c          	mov    %eax,0xc(%esp)
40000229:	c7 44 24 08 d8 3c 00 	movl   $0x40003cd8,0x8(%esp)
40000230:	40 
40000231:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
40000238:	00 
40000239:	c7 04 24 ce 3c 00 40 	movl   $0x40003cce,(%esp)
40000240:	e8 13 03 00 00       	call   40000558 <debug_panic>
	while ((de = readdir(d)) != NULL) {
		char depath[PATH_MAX];
		snprintf(depath, PATH_MAX, "%s%s%s", path,
			(path[0] && path[strlen(path)-1] != '/') ? "/" : "",
			de->d_name);
40000245:	8b 5d f0             	mov    -0x10(%ebp),%ebx
	if ((d = opendir(realpath)) == NULL)
		panic("opendir %s: %s", realpath, strerror(errno));
	while ((de = readdir(d)) != NULL) {
		char depath[PATH_MAX];
		snprintf(depath, PATH_MAX, "%s%s%s", path,
			(path[0] && path[strlen(path)-1] != '/') ? "/" : "",
40000248:	8b 45 08             	mov    0x8(%ebp),%eax
4000024b:	0f b6 00             	movzbl (%eax),%eax

	if ((d = opendir(realpath)) == NULL)
		panic("opendir %s: %s", realpath, strerror(errno));
	while ((de = readdir(d)) != NULL) {
		char depath[PATH_MAX];
		snprintf(depath, PATH_MAX, "%s%s%s", path,
4000024e:	84 c0                	test   %al,%al
40000250:	74 21                	je     40000273 <lsdir+0x86>
			(path[0] && path[strlen(path)-1] != '/') ? "/" : "",
40000252:	8b 45 08             	mov    0x8(%ebp),%eax
40000255:	89 04 24             	mov    %eax,(%esp)
40000258:	e8 6f 0c 00 00       	call   40000ecc <strlen>
4000025d:	8d 50 ff             	lea    -0x1(%eax),%edx
40000260:	8b 45 08             	mov    0x8(%ebp),%eax
40000263:	01 d0                	add    %edx,%eax
40000265:	0f b6 00             	movzbl (%eax),%eax
40000268:	3c 2f                	cmp    $0x2f,%al
4000026a:	74 07                	je     40000273 <lsdir+0x86>

	if ((d = opendir(realpath)) == NULL)
		panic("opendir %s: %s", realpath, strerror(errno));
	while ((de = readdir(d)) != NULL) {
		char depath[PATH_MAX];
		snprintf(depath, PATH_MAX, "%s%s%s", path,
4000026c:	b8 e7 3c 00 40       	mov    $0x40003ce7,%eax
40000271:	eb 05                	jmp    40000278 <lsdir+0x8b>
40000273:	b8 e9 3c 00 40       	mov    $0x40003ce9,%eax
40000278:	89 5c 24 14          	mov    %ebx,0x14(%esp)
4000027c:	89 44 24 10          	mov    %eax,0x10(%esp)
40000280:	8b 45 08             	mov    0x8(%ebp),%eax
40000283:	89 44 24 0c          	mov    %eax,0xc(%esp)
40000287:	c7 44 24 08 ea 3c 00 	movl   $0x40003cea,0x8(%esp)
4000028e:	40 
4000028f:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
40000296:	00 
40000297:	8d 85 f0 fb ff ff    	lea    -0x410(%ebp),%eax
4000029d:	89 04 24             	mov    %eax,(%esp)
400002a0:	e8 05 35 00 00       	call   400037aa <snprintf>
			(path[0] && path[strlen(path)-1] != '/') ? "/" : "",
			de->d_name);
		lsfile(depath, depath);
400002a5:	8d 85 f0 fb ff ff    	lea    -0x410(%ebp),%eax
400002ab:	89 44 24 04          	mov    %eax,0x4(%esp)
400002af:	8d 85 f0 fb ff ff    	lea    -0x410(%ebp),%eax
400002b5:	89 04 24             	mov    %eax,(%esp)
400002b8:	e8 2c 00 00 00       	call   400002e9 <lsfile>
	DIR *d;
	struct dirent *de;

	if ((d = opendir(realpath)) == NULL)
		panic("opendir %s: %s", realpath, strerror(errno));
	while ((de = readdir(d)) != NULL) {
400002bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
400002c0:	89 04 24             	mov    %eax,(%esp)
400002c3:	e8 9e 27 00 00       	call   40002a66 <readdir>
400002c8:	89 45 f0             	mov    %eax,-0x10(%ebp)
400002cb:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400002cf:	0f 85 70 ff ff ff    	jne    40000245 <lsdir+0x58>
		snprintf(depath, PATH_MAX, "%s%s%s", path,
			(path[0] && path[strlen(path)-1] != '/') ? "/" : "",
			de->d_name);
		lsfile(depath, depath);
	}
	closedir(d);
400002d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
400002d8:	89 04 24             	mov    %eax,(%esp)
400002db:	e8 6e 27 00 00       	call   40002a4e <closedir>
}
400002e0:	81 c4 34 04 00 00    	add    $0x434,%esp
400002e6:	5b                   	pop    %ebx
400002e7:	5d                   	pop    %ebp
400002e8:	c3                   	ret    

400002e9 <lsfile>:

void
lsfile(const char *path, const char *realpath)
{
400002e9:	55                   	push   %ebp
400002ea:	89 e5                	mov    %esp,%ebp
400002ec:	83 ec 38             	sub    $0x38,%esp
	char *sep;

	// Get information about the file
	struct stat st;
	if (stat(realpath, &st) < 0) {
400002ef:	8d 45 e8             	lea    -0x18(%ebp),%eax
400002f2:	89 44 24 04          	mov    %eax,0x4(%esp)
400002f6:	8b 45 0c             	mov    0xc(%ebp),%eax
400002f9:	89 04 24             	mov    %eax,(%esp)
400002fc:	e8 e4 31 00 00       	call   400034e5 <stat>
40000301:	85 c0                	test   %eax,%eax
40000303:	79 3b                	jns    40000340 <lsfile+0x57>
		warn("error reading %s: %s", realpath, strerror(errno));
40000305:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000030a:	8b 00                	mov    (%eax),%eax
4000030c:	89 04 24             	mov    %eax,(%esp)
4000030f:	e8 58 36 00 00       	call   4000396c <strerror>
40000314:	89 44 24 10          	mov    %eax,0x10(%esp)
40000318:	8b 45 0c             	mov    0xc(%ebp),%eax
4000031b:	89 44 24 0c          	mov    %eax,0xc(%esp)
4000031f:	c7 44 24 08 f1 3c 00 	movl   $0x40003cf1,0x8(%esp)
40000326:	40 
40000327:	c7 44 24 04 41 00 00 	movl   $0x41,0x4(%esp)
4000032e:	00 
4000032f:	c7 04 24 ce 3c 00 40 	movl   $0x40003cce,(%esp)
40000336:	e8 87 02 00 00       	call   400005c2 <debug_warn>
4000033b:	e9 95 00 00 00       	jmp    400003d5 <lsfile+0xec>
		return;
	}
	bool isdir = S_ISDIR(st.st_mode);
40000340:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000343:	25 00 70 00 00       	and    $0x7000,%eax
40000348:	3d 00 20 00 00       	cmp    $0x2000,%eax
4000034d:	0f 94 c0             	sete   %al
40000350:	0f b6 c0             	movzbl %al,%eax
40000353:	89 45 f4             	mov    %eax,-0xc(%ebp)

	if(flag['l'])
40000356:	a1 70 63 00 40       	mov    0x40006370,%eax
4000035b:	85 c0                	test   %eax,%eax
4000035d:	74 3c                	je     4000039b <lsfile+0xb2>
		printf("%c %11d ", 
4000035f:	8b 55 f0             	mov    -0x10(%ebp),%edx
			(st.st_mode & S_IFCONF) ? 'C' : isdir ? 'd' : '-',
40000362:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000365:	25 00 00 01 00       	and    $0x10000,%eax
		return;
	}
	bool isdir = S_ISDIR(st.st_mode);

	if(flag['l'])
		printf("%c %11d ", 
4000036a:	85 c0                	test   %eax,%eax
4000036c:	75 14                	jne    40000382 <lsfile+0x99>
			(st.st_mode & S_IFCONF) ? 'C' : isdir ? 'd' : '-',
4000036e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40000372:	74 07                	je     4000037b <lsfile+0x92>
40000374:	b8 64 00 00 00       	mov    $0x64,%eax
40000379:	eb 05                	jmp    40000380 <lsfile+0x97>
4000037b:	b8 2d 00 00 00       	mov    $0x2d,%eax
40000380:	eb 05                	jmp    40000387 <lsfile+0x9e>
		return;
	}
	bool isdir = S_ISDIR(st.st_mode);

	if(flag['l'])
		printf("%c %11d ", 
40000382:	b8 43 00 00 00       	mov    $0x43,%eax
40000387:	89 54 24 08          	mov    %edx,0x8(%esp)
4000038b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000038f:	c7 04 24 06 3d 00 40 	movl   $0x40003d06,(%esp)
40000396:	e8 a0 35 00 00       	call   4000393b <printf>
			(st.st_mode & S_IFCONF) ? 'C' : isdir ? 'd' : '-',
			st.st_size);
	printf("%s", path);
4000039b:	8b 45 08             	mov    0x8(%ebp),%eax
4000039e:	89 44 24 04          	mov    %eax,0x4(%esp)
400003a2:	c7 04 24 0f 3d 00 40 	movl   $0x40003d0f,(%esp)
400003a9:	e8 8d 35 00 00       	call   4000393b <printf>
	if(flag['F'] && isdir)
400003ae:	a1 d8 62 00 40       	mov    0x400062d8,%eax
400003b3:	85 c0                	test   %eax,%eax
400003b5:	74 12                	je     400003c9 <lsfile+0xe0>
400003b7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
400003bb:	74 0c                	je     400003c9 <lsfile+0xe0>
		printf("/");
400003bd:	c7 04 24 e7 3c 00 40 	movl   $0x40003ce7,(%esp)
400003c4:	e8 72 35 00 00       	call   4000393b <printf>
	printf("\n");
400003c9:	c7 04 24 12 3d 00 40 	movl   $0x40003d12,(%esp)
400003d0:	e8 66 35 00 00       	call   4000393b <printf>
}
400003d5:	c9                   	leave  
400003d6:	c3                   	ret    

400003d7 <usage>:

void
usage(void)
{
400003d7:	55                   	push   %ebp
400003d8:	89 e5                	mov    %esp,%ebp
400003da:	83 ec 18             	sub    $0x18,%esp
	fprintf(stderr, "usage: ls [-dFl] [file...]\n");
400003dd:	a1 80 42 00 40       	mov    0x40004280,%eax
400003e2:	c7 44 24 04 14 3d 00 	movl   $0x40003d14,0x4(%esp)
400003e9:	40 
400003ea:	89 04 24             	mov    %eax,(%esp)
400003ed:	e8 19 35 00 00       	call   4000390b <fprintf>
	exit(EXIT_FAILURE);
400003f2:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
400003f9:	e8 66 2c 00 00       	call   40003064 <exit>

400003fe <main>:
}

int
main(int argc, char **argv)
{
400003fe:	55                   	push   %ebp
400003ff:	89 e5                	mov    %esp,%ebp
40000401:	83 e4 f0             	and    $0xfffffff0,%esp
40000404:	83 ec 20             	sub    $0x20,%esp
	int i;
	ARGBEGIN{
40000407:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
4000040b:	75 06                	jne    40000413 <main+0x15>
4000040d:	8d 45 08             	lea    0x8(%ebp),%eax
40000410:	89 45 0c             	mov    %eax,0xc(%ebp)
40000413:	a1 c0 65 00 40       	mov    0x400065c0,%eax
40000418:	85 c0                	test   %eax,%eax
4000041a:	75 0a                	jne    40000426 <main+0x28>
4000041c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000041f:	8b 00                	mov    (%eax),%eax
40000421:	a3 c0 65 00 40       	mov    %eax,0x400065c0
40000426:	83 45 0c 04          	addl   $0x4,0xc(%ebp)
4000042a:	8b 45 08             	mov    0x8(%ebp),%eax
4000042d:	83 e8 01             	sub    $0x1,%eax
40000430:	89 45 08             	mov    %eax,0x8(%ebp)
40000433:	e9 a7 00 00 00       	jmp    400004df <main+0xe1>
40000438:	8b 45 0c             	mov    0xc(%ebp),%eax
4000043b:	8b 00                	mov    (%eax),%eax
4000043d:	83 c0 01             	add    $0x1,%eax
40000440:	89 44 24 18          	mov    %eax,0x18(%esp)
40000444:	8b 44 24 18          	mov    0x18(%esp),%eax
40000448:	0f b6 00             	movzbl (%eax),%eax
4000044b:	3c 2d                	cmp    $0x2d,%al
4000044d:	75 20                	jne    4000046f <main+0x71>
4000044f:	8b 44 24 18          	mov    0x18(%esp),%eax
40000453:	83 c0 01             	add    $0x1,%eax
40000456:	0f b6 00             	movzbl (%eax),%eax
40000459:	84 c0                	test   %al,%al
4000045b:	75 12                	jne    4000046f <main+0x71>
4000045d:	8b 45 08             	mov    0x8(%ebp),%eax
40000460:	83 e8 01             	sub    $0x1,%eax
40000463:	89 45 08             	mov    %eax,0x8(%ebp)
40000466:	83 45 0c 04          	addl   $0x4,0xc(%ebp)
4000046a:	e9 98 00 00 00       	jmp    40000507 <main+0x109>
4000046f:	c6 44 24 17 00       	movb   $0x0,0x17(%esp)
40000474:	eb 2d                	jmp    400004a3 <main+0xa5>
40000476:	0f be 44 24 17       	movsbl 0x17(%esp),%eax
4000047b:	83 f8 64             	cmp    $0x64,%eax
4000047e:	74 0f                	je     4000048f <main+0x91>
40000480:	83 f8 6c             	cmp    $0x6c,%eax
40000483:	74 0a                	je     4000048f <main+0x91>
40000485:	83 f8 46             	cmp    $0x46,%eax
40000488:	74 05                	je     4000048f <main+0x91>
	default:
		usage();
4000048a:	e8 48 ff ff ff       	call   400003d7 <usage>
	case 'd':
	case 'F':
	case 'l':
		flag[(uint8_t)ARGC()] = 1;
4000048f:	0f b6 44 24 17       	movzbl 0x17(%esp),%eax
40000494:	0f b6 c0             	movzbl %al,%eax
40000497:	c7 04 85 c0 61 00 40 	movl   $0x1,0x400061c0(,%eax,4)
4000049e:	01 00 00 00 
		break;
400004a2:	90                   	nop

int
main(int argc, char **argv)
{
	int i;
	ARGBEGIN{
400004a3:	8b 44 24 18          	mov    0x18(%esp),%eax
400004a7:	0f b6 00             	movzbl (%eax),%eax
400004aa:	84 c0                	test   %al,%al
400004ac:	74 1c                	je     400004ca <main+0xcc>
400004ae:	8b 44 24 18          	mov    0x18(%esp),%eax
400004b2:	0f b6 00             	movzbl (%eax),%eax
400004b5:	88 44 24 17          	mov    %al,0x17(%esp)
400004b9:	80 7c 24 17 00       	cmpb   $0x0,0x17(%esp)
400004be:	0f 95 c0             	setne  %al
400004c1:	83 44 24 18 01       	addl   $0x1,0x18(%esp)
400004c6:	84 c0                	test   %al,%al
400004c8:	75 ac                	jne    40000476 <main+0x78>
	case 'd':
	case 'F':
	case 'l':
		flag[(uint8_t)ARGC()] = 1;
		break;
	}ARGEND
400004ca:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
400004d1:	00 

int
main(int argc, char **argv)
{
	int i;
	ARGBEGIN{
400004d2:	8b 45 08             	mov    0x8(%ebp),%eax
400004d5:	83 e8 01             	sub    $0x1,%eax
400004d8:	89 45 08             	mov    %eax,0x8(%ebp)
400004db:	83 45 0c 04          	addl   $0x4,0xc(%ebp)
400004df:	8b 45 0c             	mov    0xc(%ebp),%eax
400004e2:	8b 00                	mov    (%eax),%eax
400004e4:	85 c0                	test   %eax,%eax
400004e6:	74 1f                	je     40000507 <main+0x109>
400004e8:	8b 45 0c             	mov    0xc(%ebp),%eax
400004eb:	8b 00                	mov    (%eax),%eax
400004ed:	0f b6 00             	movzbl (%eax),%eax
400004f0:	3c 2d                	cmp    $0x2d,%al
400004f2:	75 13                	jne    40000507 <main+0x109>
400004f4:	8b 45 0c             	mov    0xc(%ebp),%eax
400004f7:	8b 00                	mov    (%eax),%eax
400004f9:	83 c0 01             	add    $0x1,%eax
400004fc:	0f b6 00             	movzbl (%eax),%eax
400004ff:	84 c0                	test   %al,%al
40000501:	0f 85 31 ff ff ff    	jne    40000438 <main+0x3a>
	case 'l':
		flag[(uint8_t)ARGC()] = 1;
		break;
	}ARGEND

	if (argc > 0) {
40000507:	8b 45 08             	mov    0x8(%ebp),%eax
4000050a:	85 c0                	test   %eax,%eax
4000050c:	7e 34                	jle    40000542 <main+0x144>
		for (i=0; i<argc; i++)
4000050e:	c7 44 24 1c 00 00 00 	movl   $0x0,0x1c(%esp)
40000515:	00 
40000516:	eb 1f                	jmp    40000537 <main+0x139>
			ls(argv[i]);
40000518:	8b 44 24 1c          	mov    0x1c(%esp),%eax
4000051c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
40000523:	8b 45 0c             	mov    0xc(%ebp),%eax
40000526:	01 d0                	add    %edx,%eax
40000528:	8b 00                	mov    (%eax),%eax
4000052a:	89 04 24             	mov    %eax,(%esp)
4000052d:	e8 12 fc ff ff       	call   40000144 <ls>
		flag[(uint8_t)ARGC()] = 1;
		break;
	}ARGEND

	if (argc > 0) {
		for (i=0; i<argc; i++)
40000532:	83 44 24 1c 01       	addl   $0x1,0x1c(%esp)
40000537:	8b 45 08             	mov    0x8(%ebp),%eax
4000053a:	39 44 24 1c          	cmp    %eax,0x1c(%esp)
4000053e:	7c d8                	jl     40000518 <main+0x11a>
40000540:	eb 0c                	jmp    4000054e <main+0x150>
			ls(argv[i]);
	} else
		ls("");
40000542:	c7 04 24 e9 3c 00 40 	movl   $0x40003ce9,(%esp)
40000549:	e8 f6 fb ff ff       	call   40000144 <ls>
	return 0;
4000054e:	b8 00 00 00 00       	mov    $0x0,%eax
}
40000553:	c9                   	leave  
40000554:	c3                   	ret    
40000555:	66 90                	xchg   %ax,%ax
40000557:	90                   	nop

40000558 <debug_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: <message>", then causes a breakpoint exception.
 */
void
debug_panic(const char *file, int line, const char *fmt,...)
{
40000558:	55                   	push   %ebp
40000559:	89 e5                	mov    %esp,%ebp
4000055b:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	va_start(ap, fmt);
4000055e:	8d 45 10             	lea    0x10(%ebp),%eax
40000561:	83 c0 04             	add    $0x4,%eax
40000564:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Print the panic message
	if (argv0)
40000567:	a1 c0 65 00 40       	mov    0x400065c0,%eax
4000056c:	85 c0                	test   %eax,%eax
4000056e:	74 15                	je     40000585 <debug_panic+0x2d>
		cprintf("%s: ", argv0);
40000570:	a1 c0 65 00 40       	mov    0x400065c0,%eax
40000575:	89 44 24 04          	mov    %eax,0x4(%esp)
40000579:	c7 04 24 30 3d 00 40 	movl   $0x40003d30,(%esp)
40000580:	e8 67 02 00 00       	call   400007ec <cprintf>
	cprintf("user panic at %s:%d: ", file, line);
40000585:	8b 45 0c             	mov    0xc(%ebp),%eax
40000588:	89 44 24 08          	mov    %eax,0x8(%esp)
4000058c:	8b 45 08             	mov    0x8(%ebp),%eax
4000058f:	89 44 24 04          	mov    %eax,0x4(%esp)
40000593:	c7 04 24 35 3d 00 40 	movl   $0x40003d35,(%esp)
4000059a:	e8 4d 02 00 00       	call   400007ec <cprintf>
	vcprintf(fmt, ap);
4000059f:	8b 45 10             	mov    0x10(%ebp),%eax
400005a2:	8b 55 f4             	mov    -0xc(%ebp),%edx
400005a5:	89 54 24 04          	mov    %edx,0x4(%esp)
400005a9:	89 04 24             	mov    %eax,(%esp)
400005ac:	e8 d3 01 00 00       	call   40000784 <vcprintf>
	cprintf("\n");
400005b1:	c7 04 24 4b 3d 00 40 	movl   $0x40003d4b,(%esp)
400005b8:	e8 2f 02 00 00       	call   400007ec <cprintf>

	abort();
400005bd:	e8 e2 2a 00 00       	call   400030a4 <abort>

400005c2 <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
400005c2:	55                   	push   %ebp
400005c3:	89 e5                	mov    %esp,%ebp
400005c5:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
400005c8:	8d 45 10             	lea    0x10(%ebp),%eax
400005cb:	83 c0 04             	add    $0x4,%eax
400005ce:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("user warning at %s:%d: ", file, line);
400005d1:	8b 45 0c             	mov    0xc(%ebp),%eax
400005d4:	89 44 24 08          	mov    %eax,0x8(%esp)
400005d8:	8b 45 08             	mov    0x8(%ebp),%eax
400005db:	89 44 24 04          	mov    %eax,0x4(%esp)
400005df:	c7 04 24 4d 3d 00 40 	movl   $0x40003d4d,(%esp)
400005e6:	e8 01 02 00 00       	call   400007ec <cprintf>
	vcprintf(fmt, ap);
400005eb:	8b 45 10             	mov    0x10(%ebp),%eax
400005ee:	8b 55 f4             	mov    -0xc(%ebp),%edx
400005f1:	89 54 24 04          	mov    %edx,0x4(%esp)
400005f5:	89 04 24             	mov    %eax,(%esp)
400005f8:	e8 87 01 00 00       	call   40000784 <vcprintf>
	cprintf("\n");
400005fd:	c7 04 24 4b 3d 00 40 	movl   $0x40003d4b,(%esp)
40000604:	e8 e3 01 00 00       	call   400007ec <cprintf>
	va_end(ap);
}
40000609:	c9                   	leave  
4000060a:	c3                   	ret    

4000060b <debug_dump>:

// Dump a block of memory as 32-bit words and ASCII bytes
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
4000060b:	55                   	push   %ebp
4000060c:	89 e5                	mov    %esp,%ebp
4000060e:	56                   	push   %esi
4000060f:	53                   	push   %ebx
40000610:	81 ec a0 00 00 00    	sub    $0xa0,%esp
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
40000616:	8b 55 14             	mov    0x14(%ebp),%edx
40000619:	8b 45 10             	mov    0x10(%ebp),%eax
4000061c:	01 d0                	add    %edx,%eax
4000061e:	89 44 24 10          	mov    %eax,0x10(%esp)
40000622:	8b 45 10             	mov    0x10(%ebp),%eax
40000625:	89 44 24 0c          	mov    %eax,0xc(%esp)
40000629:	8b 45 0c             	mov    0xc(%ebp),%eax
4000062c:	89 44 24 08          	mov    %eax,0x8(%esp)
40000630:	8b 45 08             	mov    0x8(%ebp),%eax
40000633:	89 44 24 04          	mov    %eax,0x4(%esp)
40000637:	c7 04 24 68 3d 00 40 	movl   $0x40003d68,(%esp)
4000063e:	e8 a9 01 00 00       	call   400007ec <cprintf>
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
40000643:	8b 45 14             	mov    0x14(%ebp),%eax
40000646:	83 c0 0f             	add    $0xf,%eax
40000649:	83 e0 f0             	and    $0xfffffff0,%eax
4000064c:	89 45 14             	mov    %eax,0x14(%ebp)
4000064f:	e9 bb 00 00 00       	jmp    4000070f <debug_dump+0x104>
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
40000654:	8b 45 10             	mov    0x10(%ebp),%eax
40000657:	89 45 f0             	mov    %eax,-0x10(%ebp)
		for (i = 0; i < 16; i++)
4000065a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
40000661:	eb 4d                	jmp    400006b0 <debug_dump+0xa5>
			buf[i] = isprint(c[i]) ? c[i] : '.';
40000663:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000666:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000669:	01 d0                	add    %edx,%eax
4000066b:	0f b6 00             	movzbl (%eax),%eax
4000066e:	0f b6 c0             	movzbl %al,%eax
40000671:	89 45 e8             	mov    %eax,-0x18(%ebp)
static gcc_inline int isalnum(int c)	{ return isalpha(c) || isdigit(c); }
static gcc_inline int iscntrl(int c)	{ return c < ' '; }
static gcc_inline int isblank(int c)	{ return c == ' ' || c == '\t'; }
static gcc_inline int isspace(int c)	{ return c == ' '
						|| (c >= '\t' && c <= '\r'); }
static gcc_inline int isprint(int c)	{ return c >= ' ' && c <= '~'; }
40000674:	83 7d e8 1f          	cmpl   $0x1f,-0x18(%ebp)
40000678:	7e 0d                	jle    40000687 <debug_dump+0x7c>
4000067a:	83 7d e8 7e          	cmpl   $0x7e,-0x18(%ebp)
4000067e:	7f 07                	jg     40000687 <debug_dump+0x7c>
40000680:	b8 01 00 00 00       	mov    $0x1,%eax
40000685:	eb 05                	jmp    4000068c <debug_dump+0x81>
40000687:	b8 00 00 00 00       	mov    $0x0,%eax
4000068c:	85 c0                	test   %eax,%eax
4000068e:	74 0d                	je     4000069d <debug_dump+0x92>
40000690:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000693:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000696:	01 d0                	add    %edx,%eax
40000698:	0f b6 00             	movzbl (%eax),%eax
4000069b:	eb 05                	jmp    400006a2 <debug_dump+0x97>
4000069d:	b8 2e 00 00 00       	mov    $0x2e,%eax
400006a2:	8d 4d 84             	lea    -0x7c(%ebp),%ecx
400006a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
400006a8:	01 ca                	add    %ecx,%edx
400006aa:	88 02                	mov    %al,(%edx)
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
		for (i = 0; i < 16; i++)
400006ac:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
400006b0:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
400006b4:	7e ad                	jle    40000663 <debug_dump+0x58>
			buf[i] = isprint(c[i]) ? c[i] : '.';
		buf[16] = 0;
400006b6:	c6 45 94 00          	movb   $0x0,-0x6c(%ebp)

		// Hex words
		const uint32_t *v = ptr;
400006ba:	8b 45 10             	mov    0x10(%ebp),%eax
400006bd:	89 45 ec             	mov    %eax,-0x14(%ebp)

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
			ptr, v[0], v[1], v[2], v[3], buf);
400006c0:	8b 45 ec             	mov    -0x14(%ebp),%eax
400006c3:	83 c0 0c             	add    $0xc,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
400006c6:	8b 18                	mov    (%eax),%ebx
			ptr, v[0], v[1], v[2], v[3], buf);
400006c8:	8b 45 ec             	mov    -0x14(%ebp),%eax
400006cb:	83 c0 08             	add    $0x8,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
400006ce:	8b 08                	mov    (%eax),%ecx
			ptr, v[0], v[1], v[2], v[3], buf);
400006d0:	8b 45 ec             	mov    -0x14(%ebp),%eax
400006d3:	83 c0 04             	add    $0x4,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
400006d6:	8b 10                	mov    (%eax),%edx
400006d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
400006db:	8b 00                	mov    (%eax),%eax
			ptr, v[0], v[1], v[2], v[3], buf);
400006dd:	8d 75 84             	lea    -0x7c(%ebp),%esi
400006e0:	89 74 24 18          	mov    %esi,0x18(%esp)

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
400006e4:	89 5c 24 14          	mov    %ebx,0x14(%esp)
400006e8:	89 4c 24 10          	mov    %ecx,0x10(%esp)
400006ec:	89 54 24 0c          	mov    %edx,0xc(%esp)
400006f0:	89 44 24 08          	mov    %eax,0x8(%esp)
400006f4:	8b 45 10             	mov    0x10(%ebp),%eax
400006f7:	89 44 24 04          	mov    %eax,0x4(%esp)
400006fb:	c7 04 24 91 3d 00 40 	movl   $0x40003d91,(%esp)
40000702:	e8 e5 00 00 00       	call   400007ec <cprintf>
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
40000707:	83 6d 14 10          	subl   $0x10,0x14(%ebp)
4000070b:	83 45 10 10          	addl   $0x10,0x10(%ebp)
4000070f:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40000713:	0f 8f 3b ff ff ff    	jg     40000654 <debug_dump+0x49>

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
			ptr, v[0], v[1], v[2], v[3], buf);
	}
}
40000719:	81 c4 a0 00 00 00    	add    $0xa0,%esp
4000071f:	5b                   	pop    %ebx
40000720:	5e                   	pop    %esi
40000721:	5d                   	pop    %ebp
40000722:	c3                   	ret    
40000723:	90                   	nop

40000724 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
40000724:	55                   	push   %ebp
40000725:	89 e5                	mov    %esp,%ebp
40000727:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
4000072a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000072d:	8b 00                	mov    (%eax),%eax
4000072f:	8b 55 08             	mov    0x8(%ebp),%edx
40000732:	89 d1                	mov    %edx,%ecx
40000734:	8b 55 0c             	mov    0xc(%ebp),%edx
40000737:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
4000073b:	8d 50 01             	lea    0x1(%eax),%edx
4000073e:	8b 45 0c             	mov    0xc(%ebp),%eax
40000741:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
40000743:	8b 45 0c             	mov    0xc(%ebp),%eax
40000746:	8b 00                	mov    (%eax),%eax
40000748:	3d ff 00 00 00       	cmp    $0xff,%eax
4000074d:	75 24                	jne    40000773 <putch+0x4f>
		b->buf[b->idx] = 0;
4000074f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000752:	8b 00                	mov    (%eax),%eax
40000754:	8b 55 0c             	mov    0xc(%ebp),%edx
40000757:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
4000075c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000075f:	83 c0 08             	add    $0x8,%eax
40000762:	89 04 24             	mov    %eax,(%esp)
40000765:	e8 4e 32 00 00       	call   400039b8 <cputs>
		b->idx = 0;
4000076a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000076d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
40000773:	8b 45 0c             	mov    0xc(%ebp),%eax
40000776:	8b 40 04             	mov    0x4(%eax),%eax
40000779:	8d 50 01             	lea    0x1(%eax),%edx
4000077c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000077f:	89 50 04             	mov    %edx,0x4(%eax)
}
40000782:	c9                   	leave  
40000783:	c3                   	ret    

40000784 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
40000784:	55                   	push   %ebp
40000785:	89 e5                	mov    %esp,%ebp
40000787:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
4000078d:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
40000794:	00 00 00 
	b.cnt = 0;
40000797:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
4000079e:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
400007a1:	8b 45 0c             	mov    0xc(%ebp),%eax
400007a4:	89 44 24 0c          	mov    %eax,0xc(%esp)
400007a8:	8b 45 08             	mov    0x8(%ebp),%eax
400007ab:	89 44 24 08          	mov    %eax,0x8(%esp)
400007af:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
400007b5:	89 44 24 04          	mov    %eax,0x4(%esp)
400007b9:	c7 04 24 24 07 00 40 	movl   $0x40000724,(%esp)
400007c0:	e8 70 03 00 00       	call   40000b35 <vprintfmt>

	b.buf[b.idx] = 0;
400007c5:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
400007cb:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
400007d2:	00 
	cputs(b.buf);
400007d3:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
400007d9:	83 c0 08             	add    $0x8,%eax
400007dc:	89 04 24             	mov    %eax,(%esp)
400007df:	e8 d4 31 00 00       	call   400039b8 <cputs>

	return b.cnt;
400007e4:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
400007ea:	c9                   	leave  
400007eb:	c3                   	ret    

400007ec <cprintf>:

int
cprintf(const char *fmt, ...)
{
400007ec:	55                   	push   %ebp
400007ed:	89 e5                	mov    %esp,%ebp
400007ef:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
400007f2:	8d 45 0c             	lea    0xc(%ebp),%eax
400007f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
400007f8:	8b 45 08             	mov    0x8(%ebp),%eax
400007fb:	8b 55 f4             	mov    -0xc(%ebp),%edx
400007fe:	89 54 24 04          	mov    %edx,0x4(%esp)
40000802:	89 04 24             	mov    %eax,(%esp)
40000805:	e8 7a ff ff ff       	call   40000784 <vcprintf>
4000080a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
4000080d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40000810:	c9                   	leave  
40000811:	c3                   	ret    
40000812:	66 90                	xchg   %ax,%ax

40000814 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
40000814:	55                   	push   %ebp
40000815:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
40000817:	8b 45 08             	mov    0x8(%ebp),%eax
4000081a:	8b 40 18             	mov    0x18(%eax),%eax
4000081d:	83 e0 02             	and    $0x2,%eax
40000820:	85 c0                	test   %eax,%eax
40000822:	74 1c                	je     40000840 <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
40000824:	8b 45 0c             	mov    0xc(%ebp),%eax
40000827:	8b 00                	mov    (%eax),%eax
40000829:	8d 50 08             	lea    0x8(%eax),%edx
4000082c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000082f:	89 10                	mov    %edx,(%eax)
40000831:	8b 45 0c             	mov    0xc(%ebp),%eax
40000834:	8b 00                	mov    (%eax),%eax
40000836:	83 e8 08             	sub    $0x8,%eax
40000839:	8b 50 04             	mov    0x4(%eax),%edx
4000083c:	8b 00                	mov    (%eax),%eax
4000083e:	eb 47                	jmp    40000887 <getuint+0x73>
	else if (st->flags & F_L)
40000840:	8b 45 08             	mov    0x8(%ebp),%eax
40000843:	8b 40 18             	mov    0x18(%eax),%eax
40000846:	83 e0 01             	and    $0x1,%eax
40000849:	85 c0                	test   %eax,%eax
4000084b:	74 1e                	je     4000086b <getuint+0x57>
		return va_arg(*ap, unsigned long);
4000084d:	8b 45 0c             	mov    0xc(%ebp),%eax
40000850:	8b 00                	mov    (%eax),%eax
40000852:	8d 50 04             	lea    0x4(%eax),%edx
40000855:	8b 45 0c             	mov    0xc(%ebp),%eax
40000858:	89 10                	mov    %edx,(%eax)
4000085a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000085d:	8b 00                	mov    (%eax),%eax
4000085f:	83 e8 04             	sub    $0x4,%eax
40000862:	8b 00                	mov    (%eax),%eax
40000864:	ba 00 00 00 00       	mov    $0x0,%edx
40000869:	eb 1c                	jmp    40000887 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
4000086b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000086e:	8b 00                	mov    (%eax),%eax
40000870:	8d 50 04             	lea    0x4(%eax),%edx
40000873:	8b 45 0c             	mov    0xc(%ebp),%eax
40000876:	89 10                	mov    %edx,(%eax)
40000878:	8b 45 0c             	mov    0xc(%ebp),%eax
4000087b:	8b 00                	mov    (%eax),%eax
4000087d:	83 e8 04             	sub    $0x4,%eax
40000880:	8b 00                	mov    (%eax),%eax
40000882:	ba 00 00 00 00       	mov    $0x0,%edx
}
40000887:	5d                   	pop    %ebp
40000888:	c3                   	ret    

40000889 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
40000889:	55                   	push   %ebp
4000088a:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
4000088c:	8b 45 08             	mov    0x8(%ebp),%eax
4000088f:	8b 40 18             	mov    0x18(%eax),%eax
40000892:	83 e0 02             	and    $0x2,%eax
40000895:	85 c0                	test   %eax,%eax
40000897:	74 1c                	je     400008b5 <getint+0x2c>
		return va_arg(*ap, long long);
40000899:	8b 45 0c             	mov    0xc(%ebp),%eax
4000089c:	8b 00                	mov    (%eax),%eax
4000089e:	8d 50 08             	lea    0x8(%eax),%edx
400008a1:	8b 45 0c             	mov    0xc(%ebp),%eax
400008a4:	89 10                	mov    %edx,(%eax)
400008a6:	8b 45 0c             	mov    0xc(%ebp),%eax
400008a9:	8b 00                	mov    (%eax),%eax
400008ab:	83 e8 08             	sub    $0x8,%eax
400008ae:	8b 50 04             	mov    0x4(%eax),%edx
400008b1:	8b 00                	mov    (%eax),%eax
400008b3:	eb 47                	jmp    400008fc <getint+0x73>
	else if (st->flags & F_L)
400008b5:	8b 45 08             	mov    0x8(%ebp),%eax
400008b8:	8b 40 18             	mov    0x18(%eax),%eax
400008bb:	83 e0 01             	and    $0x1,%eax
400008be:	85 c0                	test   %eax,%eax
400008c0:	74 1e                	je     400008e0 <getint+0x57>
		return va_arg(*ap, long);
400008c2:	8b 45 0c             	mov    0xc(%ebp),%eax
400008c5:	8b 00                	mov    (%eax),%eax
400008c7:	8d 50 04             	lea    0x4(%eax),%edx
400008ca:	8b 45 0c             	mov    0xc(%ebp),%eax
400008cd:	89 10                	mov    %edx,(%eax)
400008cf:	8b 45 0c             	mov    0xc(%ebp),%eax
400008d2:	8b 00                	mov    (%eax),%eax
400008d4:	83 e8 04             	sub    $0x4,%eax
400008d7:	8b 00                	mov    (%eax),%eax
400008d9:	89 c2                	mov    %eax,%edx
400008db:	c1 fa 1f             	sar    $0x1f,%edx
400008de:	eb 1c                	jmp    400008fc <getint+0x73>
	else
		return va_arg(*ap, int);
400008e0:	8b 45 0c             	mov    0xc(%ebp),%eax
400008e3:	8b 00                	mov    (%eax),%eax
400008e5:	8d 50 04             	lea    0x4(%eax),%edx
400008e8:	8b 45 0c             	mov    0xc(%ebp),%eax
400008eb:	89 10                	mov    %edx,(%eax)
400008ed:	8b 45 0c             	mov    0xc(%ebp),%eax
400008f0:	8b 00                	mov    (%eax),%eax
400008f2:	83 e8 04             	sub    $0x4,%eax
400008f5:	8b 00                	mov    (%eax),%eax
400008f7:	89 c2                	mov    %eax,%edx
400008f9:	c1 fa 1f             	sar    $0x1f,%edx
}
400008fc:	5d                   	pop    %ebp
400008fd:	c3                   	ret    

400008fe <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
400008fe:	55                   	push   %ebp
400008ff:	89 e5                	mov    %esp,%ebp
40000901:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
40000904:	eb 1a                	jmp    40000920 <putpad+0x22>
		st->putch(st->padc, st->putdat);
40000906:	8b 45 08             	mov    0x8(%ebp),%eax
40000909:	8b 00                	mov    (%eax),%eax
4000090b:	8b 55 08             	mov    0x8(%ebp),%edx
4000090e:	8b 4a 04             	mov    0x4(%edx),%ecx
40000911:	8b 55 08             	mov    0x8(%ebp),%edx
40000914:	8b 52 08             	mov    0x8(%edx),%edx
40000917:	89 4c 24 04          	mov    %ecx,0x4(%esp)
4000091b:	89 14 24             	mov    %edx,(%esp)
4000091e:	ff d0                	call   *%eax

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
40000920:	8b 45 08             	mov    0x8(%ebp),%eax
40000923:	8b 40 0c             	mov    0xc(%eax),%eax
40000926:	8d 50 ff             	lea    -0x1(%eax),%edx
40000929:	8b 45 08             	mov    0x8(%ebp),%eax
4000092c:	89 50 0c             	mov    %edx,0xc(%eax)
4000092f:	8b 45 08             	mov    0x8(%ebp),%eax
40000932:	8b 40 0c             	mov    0xc(%eax),%eax
40000935:	85 c0                	test   %eax,%eax
40000937:	79 cd                	jns    40000906 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
40000939:	c9                   	leave  
4000093a:	c3                   	ret    

4000093b <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
4000093b:	55                   	push   %ebp
4000093c:	89 e5                	mov    %esp,%ebp
4000093e:	53                   	push   %ebx
4000093f:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
40000942:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000946:	79 18                	jns    40000960 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
40000948:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000094f:	00 
40000950:	8b 45 0c             	mov    0xc(%ebp),%eax
40000953:	89 04 24             	mov    %eax,(%esp)
40000956:	e8 f6 06 00 00       	call   40001051 <strchr>
4000095b:	89 45 f4             	mov    %eax,-0xc(%ebp)
4000095e:	eb 2e                	jmp    4000098e <putstr+0x53>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
40000960:	8b 45 10             	mov    0x10(%ebp),%eax
40000963:	89 44 24 08          	mov    %eax,0x8(%esp)
40000967:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000096e:	00 
4000096f:	8b 45 0c             	mov    0xc(%ebp),%eax
40000972:	89 04 24             	mov    %eax,(%esp)
40000975:	e8 d4 08 00 00       	call   4000124e <memchr>
4000097a:	89 45 f4             	mov    %eax,-0xc(%ebp)
4000097d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40000981:	75 0b                	jne    4000098e <putstr+0x53>
		lim = str + maxlen;
40000983:	8b 55 10             	mov    0x10(%ebp),%edx
40000986:	8b 45 0c             	mov    0xc(%ebp),%eax
40000989:	01 d0                	add    %edx,%eax
4000098b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
4000098e:	8b 45 08             	mov    0x8(%ebp),%eax
40000991:	8b 40 0c             	mov    0xc(%eax),%eax
40000994:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40000997:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000099a:	89 cb                	mov    %ecx,%ebx
4000099c:	29 d3                	sub    %edx,%ebx
4000099e:	89 da                	mov    %ebx,%edx
400009a0:	01 c2                	add    %eax,%edx
400009a2:	8b 45 08             	mov    0x8(%ebp),%eax
400009a5:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
400009a8:	8b 45 08             	mov    0x8(%ebp),%eax
400009ab:	8b 40 18             	mov    0x18(%eax),%eax
400009ae:	83 e0 10             	and    $0x10,%eax
400009b1:	85 c0                	test   %eax,%eax
400009b3:	75 32                	jne    400009e7 <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
400009b5:	8b 45 08             	mov    0x8(%ebp),%eax
400009b8:	89 04 24             	mov    %eax,(%esp)
400009bb:	e8 3e ff ff ff       	call   400008fe <putpad>
	while (str < lim) {
400009c0:	eb 25                	jmp    400009e7 <putstr+0xac>
		char ch = *str++;
400009c2:	8b 45 0c             	mov    0xc(%ebp),%eax
400009c5:	0f b6 00             	movzbl (%eax),%eax
400009c8:	88 45 f3             	mov    %al,-0xd(%ebp)
400009cb:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
400009cf:	8b 45 08             	mov    0x8(%ebp),%eax
400009d2:	8b 00                	mov    (%eax),%eax
400009d4:	8b 55 08             	mov    0x8(%ebp),%edx
400009d7:	8b 4a 04             	mov    0x4(%edx),%ecx
400009da:	0f be 55 f3          	movsbl -0xd(%ebp),%edx
400009de:	89 4c 24 04          	mov    %ecx,0x4(%esp)
400009e2:	89 14 24             	mov    %edx,(%esp)
400009e5:	ff d0                	call   *%eax
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
400009e7:	8b 45 0c             	mov    0xc(%ebp),%eax
400009ea:	3b 45 f4             	cmp    -0xc(%ebp),%eax
400009ed:	72 d3                	jb     400009c2 <putstr+0x87>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
400009ef:	8b 45 08             	mov    0x8(%ebp),%eax
400009f2:	89 04 24             	mov    %eax,(%esp)
400009f5:	e8 04 ff ff ff       	call   400008fe <putpad>
}
400009fa:	83 c4 24             	add    $0x24,%esp
400009fd:	5b                   	pop    %ebx
400009fe:	5d                   	pop    %ebp
400009ff:	c3                   	ret    

40000a00 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
40000a00:	55                   	push   %ebp
40000a01:	89 e5                	mov    %esp,%ebp
40000a03:	53                   	push   %ebx
40000a04:	83 ec 24             	sub    $0x24,%esp
40000a07:	8b 45 10             	mov    0x10(%ebp),%eax
40000a0a:	89 45 f0             	mov    %eax,-0x10(%ebp)
40000a0d:	8b 45 14             	mov    0x14(%ebp),%eax
40000a10:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
40000a13:	8b 45 08             	mov    0x8(%ebp),%eax
40000a16:	8b 40 1c             	mov    0x1c(%eax),%eax
40000a19:	89 c2                	mov    %eax,%edx
40000a1b:	c1 fa 1f             	sar    $0x1f,%edx
40000a1e:	3b 55 f4             	cmp    -0xc(%ebp),%edx
40000a21:	77 4e                	ja     40000a71 <genint+0x71>
40000a23:	3b 55 f4             	cmp    -0xc(%ebp),%edx
40000a26:	72 05                	jb     40000a2d <genint+0x2d>
40000a28:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40000a2b:	77 44                	ja     40000a71 <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
40000a2d:	8b 45 08             	mov    0x8(%ebp),%eax
40000a30:	8b 40 1c             	mov    0x1c(%eax),%eax
40000a33:	89 c2                	mov    %eax,%edx
40000a35:	c1 fa 1f             	sar    $0x1f,%edx
40000a38:	89 44 24 08          	mov    %eax,0x8(%esp)
40000a3c:	89 54 24 0c          	mov    %edx,0xc(%esp)
40000a40:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000a43:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000a46:	89 04 24             	mov    %eax,(%esp)
40000a49:	89 54 24 04          	mov    %edx,0x4(%esp)
40000a4d:	e8 8e 2f 00 00       	call   400039e0 <__udivdi3>
40000a52:	89 44 24 08          	mov    %eax,0x8(%esp)
40000a56:	89 54 24 0c          	mov    %edx,0xc(%esp)
40000a5a:	8b 45 0c             	mov    0xc(%ebp),%eax
40000a5d:	89 44 24 04          	mov    %eax,0x4(%esp)
40000a61:	8b 45 08             	mov    0x8(%ebp),%eax
40000a64:	89 04 24             	mov    %eax,(%esp)
40000a67:	e8 94 ff ff ff       	call   40000a00 <genint>
40000a6c:	89 45 0c             	mov    %eax,0xc(%ebp)
40000a6f:	eb 1b                	jmp    40000a8c <genint+0x8c>
	else if (st->signc >= 0)
40000a71:	8b 45 08             	mov    0x8(%ebp),%eax
40000a74:	8b 40 14             	mov    0x14(%eax),%eax
40000a77:	85 c0                	test   %eax,%eax
40000a79:	78 11                	js     40000a8c <genint+0x8c>
		*p++ = st->signc;			// output leading sign
40000a7b:	8b 45 08             	mov    0x8(%ebp),%eax
40000a7e:	8b 40 14             	mov    0x14(%eax),%eax
40000a81:	89 c2                	mov    %eax,%edx
40000a83:	8b 45 0c             	mov    0xc(%ebp),%eax
40000a86:	88 10                	mov    %dl,(%eax)
40000a88:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
40000a8c:	8b 45 08             	mov    0x8(%ebp),%eax
40000a8f:	8b 40 1c             	mov    0x1c(%eax),%eax
40000a92:	89 c1                	mov    %eax,%ecx
40000a94:	89 c3                	mov    %eax,%ebx
40000a96:	c1 fb 1f             	sar    $0x1f,%ebx
40000a99:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000a9c:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000a9f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40000aa3:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
40000aa7:	89 04 24             	mov    %eax,(%esp)
40000aaa:	89 54 24 04          	mov    %edx,0x4(%esp)
40000aae:	e8 7d 30 00 00       	call   40003b30 <__umoddi3>
40000ab3:	05 b0 3d 00 40       	add    $0x40003db0,%eax
40000ab8:	0f b6 10             	movzbl (%eax),%edx
40000abb:	8b 45 0c             	mov    0xc(%ebp),%eax
40000abe:	88 10                	mov    %dl,(%eax)
40000ac0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
40000ac4:	8b 45 0c             	mov    0xc(%ebp),%eax
}
40000ac7:	83 c4 24             	add    $0x24,%esp
40000aca:	5b                   	pop    %ebx
40000acb:	5d                   	pop    %ebp
40000acc:	c3                   	ret    

40000acd <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
40000acd:	55                   	push   %ebp
40000ace:	89 e5                	mov    %esp,%ebp
40000ad0:	83 ec 58             	sub    $0x58,%esp
40000ad3:	8b 45 0c             	mov    0xc(%ebp),%eax
40000ad6:	89 45 c0             	mov    %eax,-0x40(%ebp)
40000ad9:	8b 45 10             	mov    0x10(%ebp),%eax
40000adc:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
40000adf:	8d 45 d6             	lea    -0x2a(%ebp),%eax
40000ae2:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
40000ae5:	8b 45 08             	mov    0x8(%ebp),%eax
40000ae8:	8b 55 14             	mov    0x14(%ebp),%edx
40000aeb:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
40000aee:	8b 45 c0             	mov    -0x40(%ebp),%eax
40000af1:	8b 55 c4             	mov    -0x3c(%ebp),%edx
40000af4:	89 44 24 08          	mov    %eax,0x8(%esp)
40000af8:	89 54 24 0c          	mov    %edx,0xc(%esp)
40000afc:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000aff:	89 44 24 04          	mov    %eax,0x4(%esp)
40000b03:	8b 45 08             	mov    0x8(%ebp),%eax
40000b06:	89 04 24             	mov    %eax,(%esp)
40000b09:	e8 f2 fe ff ff       	call   40000a00 <genint>
40000b0e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
40000b11:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000b14:	8d 45 d6             	lea    -0x2a(%ebp),%eax
40000b17:	89 d1                	mov    %edx,%ecx
40000b19:	29 c1                	sub    %eax,%ecx
40000b1b:	89 c8                	mov    %ecx,%eax
40000b1d:	89 44 24 08          	mov    %eax,0x8(%esp)
40000b21:	8d 45 d6             	lea    -0x2a(%ebp),%eax
40000b24:	89 44 24 04          	mov    %eax,0x4(%esp)
40000b28:	8b 45 08             	mov    0x8(%ebp),%eax
40000b2b:	89 04 24             	mov    %eax,(%esp)
40000b2e:	e8 08 fe ff ff       	call   4000093b <putstr>
}
40000b33:	c9                   	leave  
40000b34:	c3                   	ret    

40000b35 <vprintfmt>:


// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
40000b35:	55                   	push   %ebp
40000b36:	89 e5                	mov    %esp,%ebp
40000b38:	53                   	push   %ebx
40000b39:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
40000b3c:	8d 55 cc             	lea    -0x34(%ebp),%edx
40000b3f:	b9 00 00 00 00       	mov    $0x0,%ecx
40000b44:	b8 20 00 00 00       	mov    $0x20,%eax
40000b49:	89 c3                	mov    %eax,%ebx
40000b4b:	83 e3 fc             	and    $0xfffffffc,%ebx
40000b4e:	b8 00 00 00 00       	mov    $0x0,%eax
40000b53:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
40000b56:	83 c0 04             	add    $0x4,%eax
40000b59:	39 d8                	cmp    %ebx,%eax
40000b5b:	72 f6                	jb     40000b53 <vprintfmt+0x1e>
40000b5d:	01 c2                	add    %eax,%edx
40000b5f:	8b 45 08             	mov    0x8(%ebp),%eax
40000b62:	89 45 cc             	mov    %eax,-0x34(%ebp)
40000b65:	8b 45 0c             	mov    0xc(%ebp),%eax
40000b68:	89 45 d0             	mov    %eax,-0x30(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40000b6b:	eb 17                	jmp    40000b84 <vprintfmt+0x4f>
			if (ch == '\0')
40000b6d:	85 db                	test   %ebx,%ebx
40000b6f:	0f 84 50 03 00 00    	je     40000ec5 <vprintfmt+0x390>
				return;
			putch(ch, putdat);
40000b75:	8b 45 0c             	mov    0xc(%ebp),%eax
40000b78:	89 44 24 04          	mov    %eax,0x4(%esp)
40000b7c:	89 1c 24             	mov    %ebx,(%esp)
40000b7f:	8b 45 08             	mov    0x8(%ebp),%eax
40000b82:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40000b84:	8b 45 10             	mov    0x10(%ebp),%eax
40000b87:	0f b6 00             	movzbl (%eax),%eax
40000b8a:	0f b6 d8             	movzbl %al,%ebx
40000b8d:	83 fb 25             	cmp    $0x25,%ebx
40000b90:	0f 95 c0             	setne  %al
40000b93:	83 45 10 01          	addl   $0x1,0x10(%ebp)
40000b97:	84 c0                	test   %al,%al
40000b99:	75 d2                	jne    40000b6d <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
40000b9b:	c7 45 d4 20 00 00 00 	movl   $0x20,-0x2c(%ebp)
		st.width = -1;
40000ba2:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.prec = -1;
40000ba9:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.signc = -1;
40000bb0:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		st.flags = 0;
40000bb7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		st.base = 10;
40000bbe:	c7 45 e8 0a 00 00 00 	movl   $0xa,-0x18(%ebp)
40000bc5:	eb 04                	jmp    40000bcb <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
40000bc7:	90                   	nop
40000bc8:	eb 01                	jmp    40000bcb <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
40000bca:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
40000bcb:	8b 45 10             	mov    0x10(%ebp),%eax
40000bce:	0f b6 00             	movzbl (%eax),%eax
40000bd1:	0f b6 d8             	movzbl %al,%ebx
40000bd4:	89 d8                	mov    %ebx,%eax
40000bd6:	83 45 10 01          	addl   $0x1,0x10(%ebp)
40000bda:	83 e8 20             	sub    $0x20,%eax
40000bdd:	83 f8 58             	cmp    $0x58,%eax
40000be0:	0f 87 ae 02 00 00    	ja     40000e94 <vprintfmt+0x35f>
40000be6:	8b 04 85 c8 3d 00 40 	mov    0x40003dc8(,%eax,4),%eax
40000bed:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
40000bef:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40000bf2:	83 c8 10             	or     $0x10,%eax
40000bf5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
40000bf8:	eb d1                	jmp    40000bcb <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
40000bfa:	c7 45 e0 2b 00 00 00 	movl   $0x2b,-0x20(%ebp)
			goto reswitch;
40000c01:	eb c8                	jmp    40000bcb <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
40000c03:	8b 45 e0             	mov    -0x20(%ebp),%eax
40000c06:	85 c0                	test   %eax,%eax
40000c08:	79 bd                	jns    40000bc7 <vprintfmt+0x92>
				st.signc = ' ';
40000c0a:	c7 45 e0 20 00 00 00 	movl   $0x20,-0x20(%ebp)
			goto reswitch;
40000c11:	eb b4                	jmp    40000bc7 <vprintfmt+0x92>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
40000c13:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40000c16:	83 e0 08             	and    $0x8,%eax
40000c19:	85 c0                	test   %eax,%eax
40000c1b:	75 07                	jne    40000c24 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
40000c1d:	c7 45 d4 30 00 00 00 	movl   $0x30,-0x2c(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
40000c24:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
				st.prec = st.prec * 10 + ch - '0';
40000c2b:	8b 55 dc             	mov    -0x24(%ebp),%edx
40000c2e:	89 d0                	mov    %edx,%eax
40000c30:	c1 e0 02             	shl    $0x2,%eax
40000c33:	01 d0                	add    %edx,%eax
40000c35:	01 c0                	add    %eax,%eax
40000c37:	01 d8                	add    %ebx,%eax
40000c39:	83 e8 30             	sub    $0x30,%eax
40000c3c:	89 45 dc             	mov    %eax,-0x24(%ebp)
				ch = *fmt;
40000c3f:	8b 45 10             	mov    0x10(%ebp),%eax
40000c42:	0f b6 00             	movzbl (%eax),%eax
40000c45:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
40000c48:	83 fb 2f             	cmp    $0x2f,%ebx
40000c4b:	7e 21                	jle    40000c6e <vprintfmt+0x139>
40000c4d:	83 fb 39             	cmp    $0x39,%ebx
40000c50:	7f 1c                	jg     40000c6e <vprintfmt+0x139>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
40000c52:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
40000c56:	eb d3                	jmp    40000c2b <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
40000c58:	8b 45 14             	mov    0x14(%ebp),%eax
40000c5b:	83 c0 04             	add    $0x4,%eax
40000c5e:	89 45 14             	mov    %eax,0x14(%ebp)
40000c61:	8b 45 14             	mov    0x14(%ebp),%eax
40000c64:	83 e8 04             	sub    $0x4,%eax
40000c67:	8b 00                	mov    (%eax),%eax
40000c69:	89 45 dc             	mov    %eax,-0x24(%ebp)
40000c6c:	eb 01                	jmp    40000c6f <vprintfmt+0x13a>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
40000c6e:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
40000c6f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40000c72:	83 e0 08             	and    $0x8,%eax
40000c75:	85 c0                	test   %eax,%eax
40000c77:	0f 85 4d ff ff ff    	jne    40000bca <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
40000c7d:	8b 45 dc             	mov    -0x24(%ebp),%eax
40000c80:	89 45 d8             	mov    %eax,-0x28(%ebp)
				st.prec = -1;
40000c83:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
			}
			goto reswitch;
40000c8a:	e9 3b ff ff ff       	jmp    40000bca <vprintfmt+0x95>

		case '.':
			st.flags |= F_DOT;
40000c8f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40000c92:	83 c8 08             	or     $0x8,%eax
40000c95:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
40000c98:	e9 2e ff ff ff       	jmp    40000bcb <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
40000c9d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40000ca0:	83 c8 04             	or     $0x4,%eax
40000ca3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
40000ca6:	e9 20 ff ff ff       	jmp    40000bcb <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
40000cab:	8b 55 e4             	mov    -0x1c(%ebp),%edx
40000cae:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40000cb1:	83 e0 01             	and    $0x1,%eax
40000cb4:	85 c0                	test   %eax,%eax
40000cb6:	74 07                	je     40000cbf <vprintfmt+0x18a>
40000cb8:	b8 02 00 00 00       	mov    $0x2,%eax
40000cbd:	eb 05                	jmp    40000cc4 <vprintfmt+0x18f>
40000cbf:	b8 01 00 00 00       	mov    $0x1,%eax
40000cc4:	09 d0                	or     %edx,%eax
40000cc6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
40000cc9:	e9 fd fe ff ff       	jmp    40000bcb <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
40000cce:	8b 45 14             	mov    0x14(%ebp),%eax
40000cd1:	83 c0 04             	add    $0x4,%eax
40000cd4:	89 45 14             	mov    %eax,0x14(%ebp)
40000cd7:	8b 45 14             	mov    0x14(%ebp),%eax
40000cda:	83 e8 04             	sub    $0x4,%eax
40000cdd:	8b 00                	mov    (%eax),%eax
40000cdf:	8b 55 0c             	mov    0xc(%ebp),%edx
40000ce2:	89 54 24 04          	mov    %edx,0x4(%esp)
40000ce6:	89 04 24             	mov    %eax,(%esp)
40000ce9:	8b 45 08             	mov    0x8(%ebp),%eax
40000cec:	ff d0                	call   *%eax
			break;
40000cee:	e9 cc 01 00 00       	jmp    40000ebf <vprintfmt+0x38a>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
40000cf3:	8b 45 14             	mov    0x14(%ebp),%eax
40000cf6:	83 c0 04             	add    $0x4,%eax
40000cf9:	89 45 14             	mov    %eax,0x14(%ebp)
40000cfc:	8b 45 14             	mov    0x14(%ebp),%eax
40000cff:	83 e8 04             	sub    $0x4,%eax
40000d02:	8b 00                	mov    (%eax),%eax
40000d04:	89 45 ec             	mov    %eax,-0x14(%ebp)
40000d07:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
40000d0b:	75 07                	jne    40000d14 <vprintfmt+0x1df>
				s = "(null)";
40000d0d:	c7 45 ec c1 3d 00 40 	movl   $0x40003dc1,-0x14(%ebp)
			putstr(&st, s, st.prec);
40000d14:	8b 45 dc             	mov    -0x24(%ebp),%eax
40000d17:	89 44 24 08          	mov    %eax,0x8(%esp)
40000d1b:	8b 45 ec             	mov    -0x14(%ebp),%eax
40000d1e:	89 44 24 04          	mov    %eax,0x4(%esp)
40000d22:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000d25:	89 04 24             	mov    %eax,(%esp)
40000d28:	e8 0e fc ff ff       	call   4000093b <putstr>
			break;
40000d2d:	e9 8d 01 00 00       	jmp    40000ebf <vprintfmt+0x38a>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
40000d32:	8d 45 14             	lea    0x14(%ebp),%eax
40000d35:	89 44 24 04          	mov    %eax,0x4(%esp)
40000d39:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000d3c:	89 04 24             	mov    %eax,(%esp)
40000d3f:	e8 45 fb ff ff       	call   40000889 <getint>
40000d44:	89 45 f0             	mov    %eax,-0x10(%ebp)
40000d47:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((intmax_t) num < 0) {
40000d4a:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000d4d:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000d50:	85 d2                	test   %edx,%edx
40000d52:	79 1a                	jns    40000d6e <vprintfmt+0x239>
				num = -(intmax_t) num;
40000d54:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000d57:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000d5a:	f7 d8                	neg    %eax
40000d5c:	83 d2 00             	adc    $0x0,%edx
40000d5f:	f7 da                	neg    %edx
40000d61:	89 45 f0             	mov    %eax,-0x10(%ebp)
40000d64:	89 55 f4             	mov    %edx,-0xc(%ebp)
				st.signc = '-';
40000d67:	c7 45 e0 2d 00 00 00 	movl   $0x2d,-0x20(%ebp)
			}
			putint(&st, num, 10);
40000d6e:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
40000d75:	00 
40000d76:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000d79:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000d7c:	89 44 24 04          	mov    %eax,0x4(%esp)
40000d80:	89 54 24 08          	mov    %edx,0x8(%esp)
40000d84:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000d87:	89 04 24             	mov    %eax,(%esp)
40000d8a:	e8 3e fd ff ff       	call   40000acd <putint>
			break;
40000d8f:	e9 2b 01 00 00       	jmp    40000ebf <vprintfmt+0x38a>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
40000d94:	8d 45 14             	lea    0x14(%ebp),%eax
40000d97:	89 44 24 04          	mov    %eax,0x4(%esp)
40000d9b:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000d9e:	89 04 24             	mov    %eax,(%esp)
40000da1:	e8 6e fa ff ff       	call   40000814 <getuint>
40000da6:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
40000dad:	00 
40000dae:	89 44 24 04          	mov    %eax,0x4(%esp)
40000db2:	89 54 24 08          	mov    %edx,0x8(%esp)
40000db6:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000db9:	89 04 24             	mov    %eax,(%esp)
40000dbc:	e8 0c fd ff ff       	call   40000acd <putint>
			break;
40000dc1:	e9 f9 00 00 00       	jmp    40000ebf <vprintfmt+0x38a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
40000dc6:	8d 45 14             	lea    0x14(%ebp),%eax
40000dc9:	89 44 24 04          	mov    %eax,0x4(%esp)
40000dcd:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000dd0:	89 04 24             	mov    %eax,(%esp)
40000dd3:	e8 3c fa ff ff       	call   40000814 <getuint>
40000dd8:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
40000ddf:	00 
40000de0:	89 44 24 04          	mov    %eax,0x4(%esp)
40000de4:	89 54 24 08          	mov    %edx,0x8(%esp)
40000de8:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000deb:	89 04 24             	mov    %eax,(%esp)
40000dee:	e8 da fc ff ff       	call   40000acd <putint>
			break;
40000df3:	e9 c7 00 00 00       	jmp    40000ebf <vprintfmt+0x38a>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
40000df8:	8d 45 14             	lea    0x14(%ebp),%eax
40000dfb:	89 44 24 04          	mov    %eax,0x4(%esp)
40000dff:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000e02:	89 04 24             	mov    %eax,(%esp)
40000e05:	e8 0a fa ff ff       	call   40000814 <getuint>
40000e0a:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
40000e11:	00 
40000e12:	89 44 24 04          	mov    %eax,0x4(%esp)
40000e16:	89 54 24 08          	mov    %edx,0x8(%esp)
40000e1a:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000e1d:	89 04 24             	mov    %eax,(%esp)
40000e20:	e8 a8 fc ff ff       	call   40000acd <putint>
			break;
40000e25:	e9 95 00 00 00       	jmp    40000ebf <vprintfmt+0x38a>

		// pointer
		case 'p':
			putch('0', putdat);
40000e2a:	8b 45 0c             	mov    0xc(%ebp),%eax
40000e2d:	89 44 24 04          	mov    %eax,0x4(%esp)
40000e31:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
40000e38:	8b 45 08             	mov    0x8(%ebp),%eax
40000e3b:	ff d0                	call   *%eax
			putch('x', putdat);
40000e3d:	8b 45 0c             	mov    0xc(%ebp),%eax
40000e40:	89 44 24 04          	mov    %eax,0x4(%esp)
40000e44:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
40000e4b:	8b 45 08             	mov    0x8(%ebp),%eax
40000e4e:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
40000e50:	8b 45 14             	mov    0x14(%ebp),%eax
40000e53:	83 c0 04             	add    $0x4,%eax
40000e56:	89 45 14             	mov    %eax,0x14(%ebp)
40000e59:	8b 45 14             	mov    0x14(%ebp),%eax
40000e5c:	83 e8 04             	sub    $0x4,%eax
40000e5f:	8b 00                	mov    (%eax),%eax
40000e61:	ba 00 00 00 00       	mov    $0x0,%edx
40000e66:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
40000e6d:	00 
40000e6e:	89 44 24 04          	mov    %eax,0x4(%esp)
40000e72:	89 54 24 08          	mov    %edx,0x8(%esp)
40000e76:	8d 45 cc             	lea    -0x34(%ebp),%eax
40000e79:	89 04 24             	mov    %eax,(%esp)
40000e7c:	e8 4c fc ff ff       	call   40000acd <putint>
			break;
40000e81:	eb 3c                	jmp    40000ebf <vprintfmt+0x38a>


		// escaped '%' character
		case '%':
			putch(ch, putdat);
40000e83:	8b 45 0c             	mov    0xc(%ebp),%eax
40000e86:	89 44 24 04          	mov    %eax,0x4(%esp)
40000e8a:	89 1c 24             	mov    %ebx,(%esp)
40000e8d:	8b 45 08             	mov    0x8(%ebp),%eax
40000e90:	ff d0                	call   *%eax
			break;
40000e92:	eb 2b                	jmp    40000ebf <vprintfmt+0x38a>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
40000e94:	8b 45 0c             	mov    0xc(%ebp),%eax
40000e97:	89 44 24 04          	mov    %eax,0x4(%esp)
40000e9b:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
40000ea2:	8b 45 08             	mov    0x8(%ebp),%eax
40000ea5:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
40000ea7:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40000eab:	eb 04                	jmp    40000eb1 <vprintfmt+0x37c>
40000ead:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40000eb1:	8b 45 10             	mov    0x10(%ebp),%eax
40000eb4:	83 e8 01             	sub    $0x1,%eax
40000eb7:	0f b6 00             	movzbl (%eax),%eax
40000eba:	3c 25                	cmp    $0x25,%al
40000ebc:	75 ef                	jne    40000ead <vprintfmt+0x378>
				/* do nothing */;
			break;
40000ebe:	90                   	nop
		}
	}
40000ebf:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40000ec0:	e9 bf fc ff ff       	jmp    40000b84 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
40000ec5:	83 c4 44             	add    $0x44,%esp
40000ec8:	5b                   	pop    %ebx
40000ec9:	5d                   	pop    %ebp
40000eca:	c3                   	ret    
40000ecb:	90                   	nop

40000ecc <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
40000ecc:	55                   	push   %ebp
40000ecd:	89 e5                	mov    %esp,%ebp
40000ecf:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
40000ed2:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
40000ed9:	eb 08                	jmp    40000ee3 <strlen+0x17>
		n++;
40000edb:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
40000edf:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000ee3:	8b 45 08             	mov    0x8(%ebp),%eax
40000ee6:	0f b6 00             	movzbl (%eax),%eax
40000ee9:	84 c0                	test   %al,%al
40000eeb:	75 ee                	jne    40000edb <strlen+0xf>
		n++;
	return n;
40000eed:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
40000ef0:	c9                   	leave  
40000ef1:	c3                   	ret    

40000ef2 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
40000ef2:	55                   	push   %ebp
40000ef3:	89 e5                	mov    %esp,%ebp
40000ef5:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
40000ef8:	8b 45 08             	mov    0x8(%ebp),%eax
40000efb:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
40000efe:	90                   	nop
40000eff:	8b 45 0c             	mov    0xc(%ebp),%eax
40000f02:	0f b6 10             	movzbl (%eax),%edx
40000f05:	8b 45 08             	mov    0x8(%ebp),%eax
40000f08:	88 10                	mov    %dl,(%eax)
40000f0a:	8b 45 08             	mov    0x8(%ebp),%eax
40000f0d:	0f b6 00             	movzbl (%eax),%eax
40000f10:	84 c0                	test   %al,%al
40000f12:	0f 95 c0             	setne  %al
40000f15:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000f19:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
40000f1d:	84 c0                	test   %al,%al
40000f1f:	75 de                	jne    40000eff <strcpy+0xd>
		/* do nothing */;
	return ret;
40000f21:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
40000f24:	c9                   	leave  
40000f25:	c3                   	ret    

40000f26 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
40000f26:	55                   	push   %ebp
40000f27:	89 e5                	mov    %esp,%ebp
40000f29:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
40000f2c:	8b 45 08             	mov    0x8(%ebp),%eax
40000f2f:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
40000f32:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
40000f39:	eb 21                	jmp    40000f5c <strncpy+0x36>
		*dst++ = *src;
40000f3b:	8b 45 0c             	mov    0xc(%ebp),%eax
40000f3e:	0f b6 10             	movzbl (%eax),%edx
40000f41:	8b 45 08             	mov    0x8(%ebp),%eax
40000f44:	88 10                	mov    %dl,(%eax)
40000f46:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
40000f4a:	8b 45 0c             	mov    0xc(%ebp),%eax
40000f4d:	0f b6 00             	movzbl (%eax),%eax
40000f50:	84 c0                	test   %al,%al
40000f52:	74 04                	je     40000f58 <strncpy+0x32>
			src++;
40000f54:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
40000f58:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40000f5c:	8b 45 fc             	mov    -0x4(%ebp),%eax
40000f5f:	3b 45 10             	cmp    0x10(%ebp),%eax
40000f62:	72 d7                	jb     40000f3b <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
40000f64:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
40000f67:	c9                   	leave  
40000f68:	c3                   	ret    

40000f69 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
40000f69:	55                   	push   %ebp
40000f6a:	89 e5                	mov    %esp,%ebp
40000f6c:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
40000f6f:	8b 45 08             	mov    0x8(%ebp),%eax
40000f72:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
40000f75:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000f79:	74 2f                	je     40000faa <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
40000f7b:	eb 13                	jmp    40000f90 <strlcpy+0x27>
			*dst++ = *src++;
40000f7d:	8b 45 0c             	mov    0xc(%ebp),%eax
40000f80:	0f b6 10             	movzbl (%eax),%edx
40000f83:	8b 45 08             	mov    0x8(%ebp),%eax
40000f86:	88 10                	mov    %dl,(%eax)
40000f88:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000f8c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
40000f90:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40000f94:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40000f98:	74 0a                	je     40000fa4 <strlcpy+0x3b>
40000f9a:	8b 45 0c             	mov    0xc(%ebp),%eax
40000f9d:	0f b6 00             	movzbl (%eax),%eax
40000fa0:	84 c0                	test   %al,%al
40000fa2:	75 d9                	jne    40000f7d <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
40000fa4:	8b 45 08             	mov    0x8(%ebp),%eax
40000fa7:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
40000faa:	8b 55 08             	mov    0x8(%ebp),%edx
40000fad:	8b 45 fc             	mov    -0x4(%ebp),%eax
40000fb0:	89 d1                	mov    %edx,%ecx
40000fb2:	29 c1                	sub    %eax,%ecx
40000fb4:	89 c8                	mov    %ecx,%eax
}
40000fb6:	c9                   	leave  
40000fb7:	c3                   	ret    

40000fb8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
40000fb8:	55                   	push   %ebp
40000fb9:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
40000fbb:	eb 08                	jmp    40000fc5 <strcmp+0xd>
		p++, q++;
40000fbd:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40000fc1:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
40000fc5:	8b 45 08             	mov    0x8(%ebp),%eax
40000fc8:	0f b6 00             	movzbl (%eax),%eax
40000fcb:	84 c0                	test   %al,%al
40000fcd:	74 10                	je     40000fdf <strcmp+0x27>
40000fcf:	8b 45 08             	mov    0x8(%ebp),%eax
40000fd2:	0f b6 10             	movzbl (%eax),%edx
40000fd5:	8b 45 0c             	mov    0xc(%ebp),%eax
40000fd8:	0f b6 00             	movzbl (%eax),%eax
40000fdb:	38 c2                	cmp    %al,%dl
40000fdd:	74 de                	je     40000fbd <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
40000fdf:	8b 45 08             	mov    0x8(%ebp),%eax
40000fe2:	0f b6 00             	movzbl (%eax),%eax
40000fe5:	0f b6 d0             	movzbl %al,%edx
40000fe8:	8b 45 0c             	mov    0xc(%ebp),%eax
40000feb:	0f b6 00             	movzbl (%eax),%eax
40000fee:	0f b6 c0             	movzbl %al,%eax
40000ff1:	89 d1                	mov    %edx,%ecx
40000ff3:	29 c1                	sub    %eax,%ecx
40000ff5:	89 c8                	mov    %ecx,%eax
}
40000ff7:	5d                   	pop    %ebp
40000ff8:	c3                   	ret    

40000ff9 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
40000ff9:	55                   	push   %ebp
40000ffa:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
40000ffc:	eb 0c                	jmp    4000100a <strncmp+0x11>
		n--, p++, q++;
40000ffe:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40001002:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40001006:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
4000100a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
4000100e:	74 1a                	je     4000102a <strncmp+0x31>
40001010:	8b 45 08             	mov    0x8(%ebp),%eax
40001013:	0f b6 00             	movzbl (%eax),%eax
40001016:	84 c0                	test   %al,%al
40001018:	74 10                	je     4000102a <strncmp+0x31>
4000101a:	8b 45 08             	mov    0x8(%ebp),%eax
4000101d:	0f b6 10             	movzbl (%eax),%edx
40001020:	8b 45 0c             	mov    0xc(%ebp),%eax
40001023:	0f b6 00             	movzbl (%eax),%eax
40001026:	38 c2                	cmp    %al,%dl
40001028:	74 d4                	je     40000ffe <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
4000102a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
4000102e:	75 07                	jne    40001037 <strncmp+0x3e>
		return 0;
40001030:	b8 00 00 00 00       	mov    $0x0,%eax
40001035:	eb 18                	jmp    4000104f <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
40001037:	8b 45 08             	mov    0x8(%ebp),%eax
4000103a:	0f b6 00             	movzbl (%eax),%eax
4000103d:	0f b6 d0             	movzbl %al,%edx
40001040:	8b 45 0c             	mov    0xc(%ebp),%eax
40001043:	0f b6 00             	movzbl (%eax),%eax
40001046:	0f b6 c0             	movzbl %al,%eax
40001049:	89 d1                	mov    %edx,%ecx
4000104b:	29 c1                	sub    %eax,%ecx
4000104d:	89 c8                	mov    %ecx,%eax
}
4000104f:	5d                   	pop    %ebp
40001050:	c3                   	ret    

40001051 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
40001051:	55                   	push   %ebp
40001052:	89 e5                	mov    %esp,%ebp
40001054:	83 ec 04             	sub    $0x4,%esp
40001057:	8b 45 0c             	mov    0xc(%ebp),%eax
4000105a:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
4000105d:	eb 1a                	jmp    40001079 <strchr+0x28>
		if (*s++ == 0)
4000105f:	8b 45 08             	mov    0x8(%ebp),%eax
40001062:	0f b6 00             	movzbl (%eax),%eax
40001065:	84 c0                	test   %al,%al
40001067:	0f 94 c0             	sete   %al
4000106a:	83 45 08 01          	addl   $0x1,0x8(%ebp)
4000106e:	84 c0                	test   %al,%al
40001070:	74 07                	je     40001079 <strchr+0x28>
			return NULL;
40001072:	b8 00 00 00 00       	mov    $0x0,%eax
40001077:	eb 0e                	jmp    40001087 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
40001079:	8b 45 08             	mov    0x8(%ebp),%eax
4000107c:	0f b6 00             	movzbl (%eax),%eax
4000107f:	3a 45 fc             	cmp    -0x4(%ebp),%al
40001082:	75 db                	jne    4000105f <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
40001084:	8b 45 08             	mov    0x8(%ebp),%eax
}
40001087:	c9                   	leave  
40001088:	c3                   	ret    

40001089 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
40001089:	55                   	push   %ebp
4000108a:	89 e5                	mov    %esp,%ebp
4000108c:	57                   	push   %edi
	char *p;

	if (n == 0)
4000108d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40001091:	75 05                	jne    40001098 <memset+0xf>
		return v;
40001093:	8b 45 08             	mov    0x8(%ebp),%eax
40001096:	eb 5c                	jmp    400010f4 <memset+0x6b>
	if ((int)v%4 == 0 && n%4 == 0) {
40001098:	8b 45 08             	mov    0x8(%ebp),%eax
4000109b:	83 e0 03             	and    $0x3,%eax
4000109e:	85 c0                	test   %eax,%eax
400010a0:	75 41                	jne    400010e3 <memset+0x5a>
400010a2:	8b 45 10             	mov    0x10(%ebp),%eax
400010a5:	83 e0 03             	and    $0x3,%eax
400010a8:	85 c0                	test   %eax,%eax
400010aa:	75 37                	jne    400010e3 <memset+0x5a>
		c &= 0xFF;
400010ac:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
400010b3:	8b 45 0c             	mov    0xc(%ebp),%eax
400010b6:	89 c2                	mov    %eax,%edx
400010b8:	c1 e2 18             	shl    $0x18,%edx
400010bb:	8b 45 0c             	mov    0xc(%ebp),%eax
400010be:	c1 e0 10             	shl    $0x10,%eax
400010c1:	09 c2                	or     %eax,%edx
400010c3:	8b 45 0c             	mov    0xc(%ebp),%eax
400010c6:	c1 e0 08             	shl    $0x8,%eax
400010c9:	09 d0                	or     %edx,%eax
400010cb:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
400010ce:	8b 45 10             	mov    0x10(%ebp),%eax
400010d1:	89 c1                	mov    %eax,%ecx
400010d3:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
400010d6:	8b 55 08             	mov    0x8(%ebp),%edx
400010d9:	8b 45 0c             	mov    0xc(%ebp),%eax
400010dc:	89 d7                	mov    %edx,%edi
400010de:	fc                   	cld    
400010df:	f3 ab                	rep stos %eax,%es:(%edi)
400010e1:	eb 0e                	jmp    400010f1 <memset+0x68>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
400010e3:	8b 55 08             	mov    0x8(%ebp),%edx
400010e6:	8b 45 0c             	mov    0xc(%ebp),%eax
400010e9:	8b 4d 10             	mov    0x10(%ebp),%ecx
400010ec:	89 d7                	mov    %edx,%edi
400010ee:	fc                   	cld    
400010ef:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
400010f1:	8b 45 08             	mov    0x8(%ebp),%eax
}
400010f4:	5f                   	pop    %edi
400010f5:	5d                   	pop    %ebp
400010f6:	c3                   	ret    

400010f7 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
400010f7:	55                   	push   %ebp
400010f8:	89 e5                	mov    %esp,%ebp
400010fa:	57                   	push   %edi
400010fb:	56                   	push   %esi
400010fc:	53                   	push   %ebx
400010fd:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
40001100:	8b 45 0c             	mov    0xc(%ebp),%eax
40001103:	89 45 f0             	mov    %eax,-0x10(%ebp)
	d = dst;
40001106:	8b 45 08             	mov    0x8(%ebp),%eax
40001109:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (s < d && s + n > d) {
4000110c:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000110f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
40001112:	73 6d                	jae    40001181 <memmove+0x8a>
40001114:	8b 45 10             	mov    0x10(%ebp),%eax
40001117:	8b 55 f0             	mov    -0x10(%ebp),%edx
4000111a:	01 d0                	add    %edx,%eax
4000111c:	3b 45 ec             	cmp    -0x14(%ebp),%eax
4000111f:	76 60                	jbe    40001181 <memmove+0x8a>
		s += n;
40001121:	8b 45 10             	mov    0x10(%ebp),%eax
40001124:	01 45 f0             	add    %eax,-0x10(%ebp)
		d += n;
40001127:	8b 45 10             	mov    0x10(%ebp),%eax
4000112a:	01 45 ec             	add    %eax,-0x14(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
4000112d:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001130:	83 e0 03             	and    $0x3,%eax
40001133:	85 c0                	test   %eax,%eax
40001135:	75 2f                	jne    40001166 <memmove+0x6f>
40001137:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000113a:	83 e0 03             	and    $0x3,%eax
4000113d:	85 c0                	test   %eax,%eax
4000113f:	75 25                	jne    40001166 <memmove+0x6f>
40001141:	8b 45 10             	mov    0x10(%ebp),%eax
40001144:	83 e0 03             	and    $0x3,%eax
40001147:	85 c0                	test   %eax,%eax
40001149:	75 1b                	jne    40001166 <memmove+0x6f>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
4000114b:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000114e:	83 e8 04             	sub    $0x4,%eax
40001151:	8b 55 f0             	mov    -0x10(%ebp),%edx
40001154:	83 ea 04             	sub    $0x4,%edx
40001157:	8b 4d 10             	mov    0x10(%ebp),%ecx
4000115a:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
4000115d:	89 c7                	mov    %eax,%edi
4000115f:	89 d6                	mov    %edx,%esi
40001161:	fd                   	std    
40001162:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
40001164:	eb 18                	jmp    4000117e <memmove+0x87>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
40001166:	8b 45 ec             	mov    -0x14(%ebp),%eax
40001169:	8d 50 ff             	lea    -0x1(%eax),%edx
4000116c:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000116f:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
40001172:	8b 45 10             	mov    0x10(%ebp),%eax
40001175:	89 d7                	mov    %edx,%edi
40001177:	89 de                	mov    %ebx,%esi
40001179:	89 c1                	mov    %eax,%ecx
4000117b:	fd                   	std    
4000117c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
4000117e:	fc                   	cld    
4000117f:	eb 45                	jmp    400011c6 <memmove+0xcf>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
40001181:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001184:	83 e0 03             	and    $0x3,%eax
40001187:	85 c0                	test   %eax,%eax
40001189:	75 2b                	jne    400011b6 <memmove+0xbf>
4000118b:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000118e:	83 e0 03             	and    $0x3,%eax
40001191:	85 c0                	test   %eax,%eax
40001193:	75 21                	jne    400011b6 <memmove+0xbf>
40001195:	8b 45 10             	mov    0x10(%ebp),%eax
40001198:	83 e0 03             	and    $0x3,%eax
4000119b:	85 c0                	test   %eax,%eax
4000119d:	75 17                	jne    400011b6 <memmove+0xbf>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
4000119f:	8b 45 10             	mov    0x10(%ebp),%eax
400011a2:	89 c1                	mov    %eax,%ecx
400011a4:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
400011a7:	8b 45 ec             	mov    -0x14(%ebp),%eax
400011aa:	8b 55 f0             	mov    -0x10(%ebp),%edx
400011ad:	89 c7                	mov    %eax,%edi
400011af:	89 d6                	mov    %edx,%esi
400011b1:	fc                   	cld    
400011b2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
400011b4:	eb 10                	jmp    400011c6 <memmove+0xcf>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
400011b6:	8b 45 ec             	mov    -0x14(%ebp),%eax
400011b9:	8b 55 f0             	mov    -0x10(%ebp),%edx
400011bc:	8b 4d 10             	mov    0x10(%ebp),%ecx
400011bf:	89 c7                	mov    %eax,%edi
400011c1:	89 d6                	mov    %edx,%esi
400011c3:	fc                   	cld    
400011c4:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
400011c6:	8b 45 08             	mov    0x8(%ebp),%eax
}
400011c9:	83 c4 10             	add    $0x10,%esp
400011cc:	5b                   	pop    %ebx
400011cd:	5e                   	pop    %esi
400011ce:	5f                   	pop    %edi
400011cf:	5d                   	pop    %ebp
400011d0:	c3                   	ret    

400011d1 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
400011d1:	55                   	push   %ebp
400011d2:	89 e5                	mov    %esp,%ebp
400011d4:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
400011d7:	8b 45 10             	mov    0x10(%ebp),%eax
400011da:	89 44 24 08          	mov    %eax,0x8(%esp)
400011de:	8b 45 0c             	mov    0xc(%ebp),%eax
400011e1:	89 44 24 04          	mov    %eax,0x4(%esp)
400011e5:	8b 45 08             	mov    0x8(%ebp),%eax
400011e8:	89 04 24             	mov    %eax,(%esp)
400011eb:	e8 07 ff ff ff       	call   400010f7 <memmove>
}
400011f0:	c9                   	leave  
400011f1:	c3                   	ret    

400011f2 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
400011f2:	55                   	push   %ebp
400011f3:	89 e5                	mov    %esp,%ebp
400011f5:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
400011f8:	8b 45 08             	mov    0x8(%ebp),%eax
400011fb:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
400011fe:	8b 45 0c             	mov    0xc(%ebp),%eax
40001201:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
40001204:	eb 32                	jmp    40001238 <memcmp+0x46>
		if (*s1 != *s2)
40001206:	8b 45 fc             	mov    -0x4(%ebp),%eax
40001209:	0f b6 10             	movzbl (%eax),%edx
4000120c:	8b 45 f8             	mov    -0x8(%ebp),%eax
4000120f:	0f b6 00             	movzbl (%eax),%eax
40001212:	38 c2                	cmp    %al,%dl
40001214:	74 1a                	je     40001230 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
40001216:	8b 45 fc             	mov    -0x4(%ebp),%eax
40001219:	0f b6 00             	movzbl (%eax),%eax
4000121c:	0f b6 d0             	movzbl %al,%edx
4000121f:	8b 45 f8             	mov    -0x8(%ebp),%eax
40001222:	0f b6 00             	movzbl (%eax),%eax
40001225:	0f b6 c0             	movzbl %al,%eax
40001228:	89 d1                	mov    %edx,%ecx
4000122a:	29 c1                	sub    %eax,%ecx
4000122c:	89 c8                	mov    %ecx,%eax
4000122e:	eb 1c                	jmp    4000124c <memcmp+0x5a>
		s1++, s2++;
40001230:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40001234:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
40001238:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
4000123c:	0f 95 c0             	setne  %al
4000123f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40001243:	84 c0                	test   %al,%al
40001245:	75 bf                	jne    40001206 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
40001247:	b8 00 00 00 00       	mov    $0x0,%eax
}
4000124c:	c9                   	leave  
4000124d:	c3                   	ret    

4000124e <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
4000124e:	55                   	push   %ebp
4000124f:	89 e5                	mov    %esp,%ebp
40001251:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
40001254:	8b 45 10             	mov    0x10(%ebp),%eax
40001257:	8b 55 08             	mov    0x8(%ebp),%edx
4000125a:	01 d0                	add    %edx,%eax
4000125c:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
4000125f:	eb 16                	jmp    40001277 <memchr+0x29>
		if (*(const unsigned char *) s == (unsigned char) c)
40001261:	8b 45 08             	mov    0x8(%ebp),%eax
40001264:	0f b6 10             	movzbl (%eax),%edx
40001267:	8b 45 0c             	mov    0xc(%ebp),%eax
4000126a:	38 c2                	cmp    %al,%dl
4000126c:	75 05                	jne    40001273 <memchr+0x25>
			return (void *) s;
4000126e:	8b 45 08             	mov    0x8(%ebp),%eax
40001271:	eb 11                	jmp    40001284 <memchr+0x36>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
40001273:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40001277:	8b 45 08             	mov    0x8(%ebp),%eax
4000127a:	3b 45 fc             	cmp    -0x4(%ebp),%eax
4000127d:	72 e2                	jb     40001261 <memchr+0x13>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
4000127f:	b8 00 00 00 00       	mov    $0x0,%eax
}
40001284:	c9                   	leave  
40001285:	c3                   	ret    
40001286:	66 90                	xchg   %ax,%ax

40001288 <fileino_alloc>:

// Find and return the index of a currently unused file inode in this process.
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_alloc(void)
{
40001288:	55                   	push   %ebp
40001289:	89 e5                	mov    %esp,%ebp
4000128b:	83 ec 28             	sub    $0x28,%esp
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
4000128e:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
40001295:	eb 24                	jmp    400012bb <fileino_alloc+0x33>
		if (files->fi[i].de.d_name[0] == 0)
40001297:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
4000129d:	8b 45 f4             	mov    -0xc(%ebp),%eax
400012a0:	6b c0 5c             	imul   $0x5c,%eax,%eax
400012a3:	01 d0                	add    %edx,%eax
400012a5:	05 10 10 00 00       	add    $0x1010,%eax
400012aa:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400012ae:	84 c0                	test   %al,%al
400012b0:	75 05                	jne    400012b7 <fileino_alloc+0x2f>
			return i;
400012b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
400012b5:	eb 39                	jmp    400012f0 <fileino_alloc+0x68>
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_alloc(void)
{
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
400012b7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
400012bb:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
400012c2:	7e d3                	jle    40001297 <fileino_alloc+0xf>
		if (files->fi[i].de.d_name[0] == 0)
			return i;

	warn("fileino_alloc: no free inodes\n");
400012c4:	c7 44 24 08 30 3f 00 	movl   $0x40003f30,0x8(%esp)
400012cb:	40 
400012cc:	c7 44 24 04 29 00 00 	movl   $0x29,0x4(%esp)
400012d3:	00 
400012d4:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
400012db:	e8 e2 f2 ff ff       	call   400005c2 <debug_warn>
	errno = ENOSPC;
400012e0:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400012e5:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
	return -1;
400012eb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
400012f0:	c9                   	leave  
400012f1:	c3                   	ret    

400012f2 <fileino_create>:
// Returns the index of the inode found or created.
// A newly-created inode is left in the "deleted" state, with mode == 0.
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_create(filestate *fs, int dino, const char *name)
{
400012f2:	55                   	push   %ebp
400012f3:	89 e5                	mov    %esp,%ebp
400012f5:	83 ec 28             	sub    $0x28,%esp
	assert(dino != 0);
400012f8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400012fc:	75 24                	jne    40001322 <fileino_create+0x30>
400012fe:	c7 44 24 0c 5a 3f 00 	movl   $0x40003f5a,0xc(%esp)
40001305:	40 
40001306:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
4000130d:	40 
4000130e:	c7 44 24 04 35 00 00 	movl   $0x35,0x4(%esp)
40001315:	00 
40001316:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
4000131d:	e8 36 f2 ff ff       	call   40000558 <debug_panic>
	assert(name != NULL && name[0] != 0);
40001322:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40001326:	74 0a                	je     40001332 <fileino_create+0x40>
40001328:	8b 45 10             	mov    0x10(%ebp),%eax
4000132b:	0f b6 00             	movzbl (%eax),%eax
4000132e:	84 c0                	test   %al,%al
40001330:	75 24                	jne    40001356 <fileino_create+0x64>
40001332:	c7 44 24 0c 79 3f 00 	movl   $0x40003f79,0xc(%esp)
40001339:	40 
4000133a:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40001341:	40 
40001342:	c7 44 24 04 36 00 00 	movl   $0x36,0x4(%esp)
40001349:	00 
4000134a:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40001351:	e8 02 f2 ff ff       	call   40000558 <debug_panic>
	assert(strlen(name) <= NAME_MAX);
40001356:	8b 45 10             	mov    0x10(%ebp),%eax
40001359:	89 04 24             	mov    %eax,(%esp)
4000135c:	e8 6b fb ff ff       	call   40000ecc <strlen>
40001361:	83 f8 3f             	cmp    $0x3f,%eax
40001364:	7e 24                	jle    4000138a <fileino_create+0x98>
40001366:	c7 44 24 0c 96 3f 00 	movl   $0x40003f96,0xc(%esp)
4000136d:	40 
4000136e:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40001375:	40 
40001376:	c7 44 24 04 37 00 00 	movl   $0x37,0x4(%esp)
4000137d:	00 
4000137e:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40001385:	e8 ce f1 ff ff       	call   40000558 <debug_panic>

	// First see if an inode already exists for this directory and name.
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
4000138a:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
40001391:	eb 4a                	jmp    400013dd <fileino_create+0xeb>
		if (fs->fi[i].dino == dino
40001393:	8b 55 08             	mov    0x8(%ebp),%edx
40001396:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001399:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000139c:	01 d0                	add    %edx,%eax
4000139e:	05 10 10 00 00       	add    $0x1010,%eax
400013a3:	8b 00                	mov    (%eax),%eax
400013a5:	3b 45 0c             	cmp    0xc(%ebp),%eax
400013a8:	75 2f                	jne    400013d9 <fileino_create+0xe7>
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
400013aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
400013ad:	6b c0 5c             	imul   $0x5c,%eax,%eax
400013b0:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400013b6:	8b 45 08             	mov    0x8(%ebp),%eax
400013b9:	01 d0                	add    %edx,%eax
400013bb:	8d 50 04             	lea    0x4(%eax),%edx
400013be:	8b 45 10             	mov    0x10(%ebp),%eax
400013c1:	89 44 24 04          	mov    %eax,0x4(%esp)
400013c5:	89 14 24             	mov    %edx,(%esp)
400013c8:	e8 eb fb ff ff       	call   40000fb8 <strcmp>
400013cd:	85 c0                	test   %eax,%eax
400013cf:	75 08                	jne    400013d9 <fileino_create+0xe7>
			return i;
400013d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
400013d4:	e9 a5 00 00 00       	jmp    4000147e <fileino_create+0x18c>
	assert(name != NULL && name[0] != 0);
	assert(strlen(name) <= NAME_MAX);

	// First see if an inode already exists for this directory and name.
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
400013d9:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
400013dd:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
400013e4:	7e ad                	jle    40001393 <fileino_create+0xa1>
		if (fs->fi[i].dino == dino
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
			return i;

	// No inode allocated to this name - find a free one to allocate.
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
400013e6:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
400013ed:	eb 5a                	jmp    40001449 <fileino_create+0x157>
		if (fs->fi[i].de.d_name[0] == 0) {
400013ef:	8b 55 08             	mov    0x8(%ebp),%edx
400013f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
400013f5:	6b c0 5c             	imul   $0x5c,%eax,%eax
400013f8:	01 d0                	add    %edx,%eax
400013fa:	05 10 10 00 00       	add    $0x1010,%eax
400013ff:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40001403:	84 c0                	test   %al,%al
40001405:	75 3e                	jne    40001445 <fileino_create+0x153>
			fs->fi[i].dino = dino;
40001407:	8b 55 08             	mov    0x8(%ebp),%edx
4000140a:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000140d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001410:	01 d0                	add    %edx,%eax
40001412:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40001418:	8b 45 0c             	mov    0xc(%ebp),%eax
4000141b:	89 02                	mov    %eax,(%edx)
			strcpy(fs->fi[i].de.d_name, name);
4000141d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001420:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001423:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40001429:	8b 45 08             	mov    0x8(%ebp),%eax
4000142c:	01 d0                	add    %edx,%eax
4000142e:	8d 50 04             	lea    0x4(%eax),%edx
40001431:	8b 45 10             	mov    0x10(%ebp),%eax
40001434:	89 44 24 04          	mov    %eax,0x4(%esp)
40001438:	89 14 24             	mov    %edx,(%esp)
4000143b:	e8 b2 fa ff ff       	call   40000ef2 <strcpy>
			return i;
40001440:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001443:	eb 39                	jmp    4000147e <fileino_create+0x18c>
		if (fs->fi[i].dino == dino
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
			return i;

	// No inode allocated to this name - find a free one to allocate.
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40001445:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40001449:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
40001450:	7e 9d                	jle    400013ef <fileino_create+0xfd>
			fs->fi[i].dino = dino;
			strcpy(fs->fi[i].de.d_name, name);
			return i;
		}

	warn("fileino_create: no free inodes\n");
40001452:	c7 44 24 08 b0 3f 00 	movl   $0x40003fb0,0x8(%esp)
40001459:	40 
4000145a:	c7 44 24 04 48 00 00 	movl   $0x48,0x4(%esp)
40001461:	00 
40001462:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40001469:	e8 54 f1 ff ff       	call   400005c2 <debug_warn>
	errno = ENOSPC;
4000146e:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40001473:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
	return -1;
40001479:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
4000147e:	c9                   	leave  
4000147f:	c3                   	ret    

40001480 <fileino_read>:
// The number of elements returned is normally equal to the 'count' parameter,
// but may be less (without resulting in an error)
// if the file is not large enough to read that many elements.
ssize_t
fileino_read(int ino, off_t ofs, void *buf, size_t eltsize, size_t count)
{
40001480:	55                   	push   %ebp
40001481:	89 e5                	mov    %esp,%ebp
40001483:	83 ec 28             	sub    $0x28,%esp
	assert(fileino_isreg(ino));
40001486:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
4000148a:	7e 45                	jle    400014d1 <fileino_read+0x51>
4000148c:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40001493:	7f 3c                	jg     400014d1 <fileino_read+0x51>
40001495:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
4000149b:	8b 45 08             	mov    0x8(%ebp),%eax
4000149e:	6b c0 5c             	imul   $0x5c,%eax,%eax
400014a1:	01 d0                	add    %edx,%eax
400014a3:	05 10 10 00 00       	add    $0x1010,%eax
400014a8:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400014ac:	84 c0                	test   %al,%al
400014ae:	74 21                	je     400014d1 <fileino_read+0x51>
400014b0:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
400014b6:	8b 45 08             	mov    0x8(%ebp),%eax
400014b9:	6b c0 5c             	imul   $0x5c,%eax,%eax
400014bc:	01 d0                	add    %edx,%eax
400014be:	05 58 10 00 00       	add    $0x1058,%eax
400014c3:	8b 00                	mov    (%eax),%eax
400014c5:	25 00 70 00 00       	and    $0x7000,%eax
400014ca:	3d 00 10 00 00       	cmp    $0x1000,%eax
400014cf:	74 24                	je     400014f5 <fileino_read+0x75>
400014d1:	c7 44 24 0c d0 3f 00 	movl   $0x40003fd0,0xc(%esp)
400014d8:	40 
400014d9:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
400014e0:	40 
400014e1:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
400014e8:	00 
400014e9:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
400014f0:	e8 63 f0 ff ff       	call   40000558 <debug_panic>
	assert(ofs >= 0);
400014f5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400014f9:	79 24                	jns    4000151f <fileino_read+0x9f>
400014fb:	c7 44 24 0c e3 3f 00 	movl   $0x40003fe3,0xc(%esp)
40001502:	40 
40001503:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
4000150a:	40 
4000150b:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
40001512:	00 
40001513:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
4000151a:	e8 39 f0 ff ff       	call   40000558 <debug_panic>
	assert(eltsize > 0);
4000151f:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40001523:	75 24                	jne    40001549 <fileino_read+0xc9>
40001525:	c7 44 24 0c ec 3f 00 	movl   $0x40003fec,0xc(%esp)
4000152c:	40 
4000152d:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40001534:	40 
40001535:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
4000153c:	00 
4000153d:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40001544:	e8 0f f0 ff ff       	call   40000558 <debug_panic>

	ssize_t return_number = 0;
40001549:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	fileinode *fi = &files->fi[ino];
40001550:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40001555:	8b 55 08             	mov    0x8(%ebp),%edx
40001558:	6b d2 5c             	imul   $0x5c,%edx,%edx
4000155b:	81 c2 10 10 00 00    	add    $0x1010,%edx
40001561:	01 d0                	add    %edx,%eax
40001563:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint32_t tmp_ofs = ofs;
40001566:	8b 45 0c             	mov    0xc(%ebp),%eax
40001569:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint8_t* read_pointer = FILEDATA(ino) + ofs;
4000156c:	8b 45 08             	mov    0x8(%ebp),%eax
4000156f:	c1 e0 16             	shl    $0x16,%eax
40001572:	89 c2                	mov    %eax,%edx
40001574:	8b 45 0c             	mov    0xc(%ebp),%eax
40001577:	01 d0                	add    %edx,%eax
40001579:	05 00 00 00 80       	add    $0x80000000,%eax
4000157e:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(fi->size <= FILE_MAXSIZE);
40001581:	8b 45 e8             	mov    -0x18(%ebp),%eax
40001584:	8b 40 4c             	mov    0x4c(%eax),%eax
40001587:	3d 00 00 40 00       	cmp    $0x400000,%eax
4000158c:	76 7a                	jbe    40001608 <fileino_read+0x188>
4000158e:	c7 44 24 0c f8 3f 00 	movl   $0x40003ff8,0xc(%esp)
40001595:	40 
40001596:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
4000159d:	40 
4000159e:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
400015a5:	00 
400015a6:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
400015ad:	e8 a6 ef ff ff       	call   40000558 <debug_panic>
	// Lab 4: insert your file reading code here.
	//warn("fileino_read() not implemented");
	while(count > 0){
		if(tmp_ofs >= fi->size){
400015b2:	8b 45 e8             	mov    -0x18(%ebp),%eax
400015b5:	8b 40 4c             	mov    0x4c(%eax),%eax
400015b8:	3b 45 f0             	cmp    -0x10(%ebp),%eax
400015bb:	77 18                	ja     400015d5 <fileino_read+0x155>
			if(fi->mode & S_IFPART)
400015bd:	8b 45 e8             	mov    -0x18(%ebp),%eax
400015c0:	8b 40 48             	mov    0x48(%eax),%eax
400015c3:	25 00 80 00 00       	and    $0x8000,%eax
400015c8:	85 c0                	test   %eax,%eax
400015ca:	74 44                	je     40001610 <fileino_read+0x190>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400015cc:	b8 03 00 00 00       	mov    $0x3,%eax
400015d1:	cd 30                	int    $0x30
400015d3:	eb 33                	jmp    40001608 <fileino_read+0x188>
				sys_ret();
			else
				break;
		}else{
			memcpy(buf, read_pointer, eltsize);
400015d5:	8b 45 14             	mov    0x14(%ebp),%eax
400015d8:	89 44 24 08          	mov    %eax,0x8(%esp)
400015dc:	8b 45 ec             	mov    -0x14(%ebp),%eax
400015df:	89 44 24 04          	mov    %eax,0x4(%esp)
400015e3:	8b 45 10             	mov    0x10(%ebp),%eax
400015e6:	89 04 24             	mov    %eax,(%esp)
400015e9:	e8 e3 fb ff ff       	call   400011d1 <memcpy>
			return_number++;
400015ee:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
			buf += eltsize;
400015f2:	8b 45 14             	mov    0x14(%ebp),%eax
400015f5:	01 45 10             	add    %eax,0x10(%ebp)
			read_pointer += eltsize;
400015f8:	8b 45 14             	mov    0x14(%ebp),%eax
400015fb:	01 45 ec             	add    %eax,-0x14(%ebp)
			tmp_ofs += eltsize;
400015fe:	8b 45 14             	mov    0x14(%ebp),%eax
40001601:	01 45 f0             	add    %eax,-0x10(%ebp)
			count--;
40001604:	83 6d 18 01          	subl   $0x1,0x18(%ebp)
	uint32_t tmp_ofs = ofs;
	uint8_t* read_pointer = FILEDATA(ino) + ofs;
	assert(fi->size <= FILE_MAXSIZE);
	// Lab 4: insert your file reading code here.
	//warn("fileino_read() not implemented");
	while(count > 0){
40001608:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
4000160c:	75 a4                	jne    400015b2 <fileino_read+0x132>
4000160e:	eb 01                	jmp    40001611 <fileino_read+0x191>
		if(tmp_ofs >= fi->size){
			if(fi->mode & S_IFPART)
				sys_ret();
			else
				break;
40001610:	90                   	nop
			read_pointer += eltsize;
			tmp_ofs += eltsize;
			count--;
		}
	}
	return return_number;
40001611:	8b 45 f4             	mov    -0xc(%ebp),%eax
//	errno = EINVAL;
//	return -1;
}
40001614:	c9                   	leave  
40001615:	c3                   	ret    

40001616 <fileino_write>:
// one particular reason an error might occur is if an application
// tries to grow a file beyond this maximum file size,
// in which case this function generates the EFBIG error.
ssize_t
fileino_write(int ino, off_t ofs, const void *buf, size_t eltsize, size_t count)
{
40001616:	55                   	push   %ebp
40001617:	89 e5                	mov    %esp,%ebp
40001619:	57                   	push   %edi
4000161a:	56                   	push   %esi
4000161b:	53                   	push   %ebx
4000161c:	83 ec 6c             	sub    $0x6c,%esp
	assert(fileino_isreg(ino));
4000161f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001623:	7e 45                	jle    4000166a <fileino_write+0x54>
40001625:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
4000162c:	7f 3c                	jg     4000166a <fileino_write+0x54>
4000162e:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40001634:	8b 45 08             	mov    0x8(%ebp),%eax
40001637:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000163a:	01 d0                	add    %edx,%eax
4000163c:	05 10 10 00 00       	add    $0x1010,%eax
40001641:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40001645:	84 c0                	test   %al,%al
40001647:	74 21                	je     4000166a <fileino_write+0x54>
40001649:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
4000164f:	8b 45 08             	mov    0x8(%ebp),%eax
40001652:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001655:	01 d0                	add    %edx,%eax
40001657:	05 58 10 00 00       	add    $0x1058,%eax
4000165c:	8b 00                	mov    (%eax),%eax
4000165e:	25 00 70 00 00       	and    $0x7000,%eax
40001663:	3d 00 10 00 00       	cmp    $0x1000,%eax
40001668:	74 24                	je     4000168e <fileino_write+0x78>
4000166a:	c7 44 24 0c d0 3f 00 	movl   $0x40003fd0,0xc(%esp)
40001671:	40 
40001672:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40001679:	40 
4000167a:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
40001681:	00 
40001682:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40001689:	e8 ca ee ff ff       	call   40000558 <debug_panic>
	assert(ofs >= 0);
4000168e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40001692:	79 24                	jns    400016b8 <fileino_write+0xa2>
40001694:	c7 44 24 0c e3 3f 00 	movl   $0x40003fe3,0xc(%esp)
4000169b:	40 
4000169c:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
400016a3:	40 
400016a4:	c7 44 24 04 84 00 00 	movl   $0x84,0x4(%esp)
400016ab:	00 
400016ac:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
400016b3:	e8 a0 ee ff ff       	call   40000558 <debug_panic>
	assert(eltsize > 0);
400016b8:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
400016bc:	75 24                	jne    400016e2 <fileino_write+0xcc>
400016be:	c7 44 24 0c ec 3f 00 	movl   $0x40003fec,0xc(%esp)
400016c5:	40 
400016c6:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
400016cd:	40 
400016ce:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
400016d5:	00 
400016d6:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
400016dd:	e8 76 ee ff ff       	call   40000558 <debug_panic>

	int i = 0;
400016e2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	ssize_t return_number = 0;
400016e9:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	fileinode *fi = &files->fi[ino];
400016f0:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400016f5:	8b 55 08             	mov    0x8(%ebp),%edx
400016f8:	6b d2 5c             	imul   $0x5c,%edx,%edx
400016fb:	81 c2 10 10 00 00    	add    $0x1010,%edx
40001701:	01 d0                	add    %edx,%eax
40001703:	89 45 d8             	mov    %eax,-0x28(%ebp)
	assert(fi->size <= FILE_MAXSIZE);
40001706:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001709:	8b 40 4c             	mov    0x4c(%eax),%eax
4000170c:	3d 00 00 40 00       	cmp    $0x400000,%eax
40001711:	76 24                	jbe    40001737 <fileino_write+0x121>
40001713:	c7 44 24 0c f8 3f 00 	movl   $0x40003ff8,0xc(%esp)
4000171a:	40 
4000171b:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40001722:	40 
40001723:	c7 44 24 04 8a 00 00 	movl   $0x8a,0x4(%esp)
4000172a:	00 
4000172b:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40001732:	e8 21 ee ff ff       	call   40000558 <debug_panic>
	uint8_t* write_start = FILEDATA(ino) + ofs;
40001737:	8b 45 08             	mov    0x8(%ebp),%eax
4000173a:	c1 e0 16             	shl    $0x16,%eax
4000173d:	89 c2                	mov    %eax,%edx
4000173f:	8b 45 0c             	mov    0xc(%ebp),%eax
40001742:	01 d0                	add    %edx,%eax
40001744:	05 00 00 00 80       	add    $0x80000000,%eax
40001749:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	uint8_t* write_pointer = write_start;
4000174c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
4000174f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uint32_t after_write_size = ofs + eltsize * count;
40001752:	8b 45 14             	mov    0x14(%ebp),%eax
40001755:	89 c2                	mov    %eax,%edx
40001757:	0f af 55 18          	imul   0x18(%ebp),%edx
4000175b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000175e:	01 d0                	add    %edx,%eax
40001760:	89 45 d0             	mov    %eax,-0x30(%ebp)

	if(after_write_size > FILE_MAXSIZE){
40001763:	81 7d d0 00 00 40 00 	cmpl   $0x400000,-0x30(%ebp)
4000176a:	76 15                	jbe    40001781 <fileino_write+0x16b>
		errno = EFBIG;
4000176c:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40001771:	c7 00 03 00 00 00    	movl   $0x3,(%eax)
		return -1;
40001777:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
4000177c:	e9 28 01 00 00       	jmp    400018a9 <fileino_write+0x293>
	}
	if(after_write_size > fi->size){
40001781:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001784:	8b 40 4c             	mov    0x4c(%eax),%eax
40001787:	3b 45 d0             	cmp    -0x30(%ebp),%eax
4000178a:	0f 83 0d 01 00 00    	jae    4000189d <fileino_write+0x287>
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
40001790:	c7 45 cc 00 10 00 00 	movl   $0x1000,-0x34(%ebp)
40001797:	8b 45 cc             	mov    -0x34(%ebp),%eax
4000179a:	8b 55 d0             	mov    -0x30(%ebp),%edx
4000179d:	01 d0                	add    %edx,%eax
4000179f:	83 e8 01             	sub    $0x1,%eax
400017a2:	89 45 c8             	mov    %eax,-0x38(%ebp)
400017a5:	8b 45 c8             	mov    -0x38(%ebp),%eax
400017a8:	ba 00 00 00 00       	mov    $0x0,%edx
400017ad:	f7 75 cc             	divl   -0x34(%ebp)
400017b0:	89 d0                	mov    %edx,%eax
400017b2:	8b 55 c8             	mov    -0x38(%ebp),%edx
400017b5:	89 d1                	mov    %edx,%ecx
400017b7:	29 c1                	sub    %eax,%ecx
400017b9:	89 c8                	mov    %ecx,%eax
400017bb:	89 c1                	mov    %eax,%ecx
400017bd:	c7 45 c4 00 10 00 00 	movl   $0x1000,-0x3c(%ebp)
400017c4:	8b 45 d8             	mov    -0x28(%ebp),%eax
400017c7:	8b 50 4c             	mov    0x4c(%eax),%edx
400017ca:	8b 45 c4             	mov    -0x3c(%ebp),%eax
400017cd:	01 d0                	add    %edx,%eax
400017cf:	83 e8 01             	sub    $0x1,%eax
400017d2:	89 45 c0             	mov    %eax,-0x40(%ebp)
400017d5:	8b 45 c0             	mov    -0x40(%ebp),%eax
400017d8:	ba 00 00 00 00       	mov    $0x0,%edx
400017dd:	f7 75 c4             	divl   -0x3c(%ebp)
400017e0:	89 d0                	mov    %edx,%eax
400017e2:	8b 55 c0             	mov    -0x40(%ebp),%edx
400017e5:	89 d3                	mov    %edx,%ebx
400017e7:	29 c3                	sub    %eax,%ebx
400017e9:	89 d8                	mov    %ebx,%eax
	if(after_write_size > FILE_MAXSIZE){
		errno = EFBIG;
		return -1;
	}
	if(after_write_size > fi->size){
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
400017eb:	29 c1                	sub    %eax,%ecx
400017ed:	8b 45 08             	mov    0x8(%ebp),%eax
400017f0:	c1 e0 16             	shl    $0x16,%eax
400017f3:	89 c3                	mov    %eax,%ebx
400017f5:	c7 45 bc 00 10 00 00 	movl   $0x1000,-0x44(%ebp)
400017fc:	8b 45 d8             	mov    -0x28(%ebp),%eax
400017ff:	8b 50 4c             	mov    0x4c(%eax),%edx
40001802:	8b 45 bc             	mov    -0x44(%ebp),%eax
40001805:	01 d0                	add    %edx,%eax
40001807:	83 e8 01             	sub    $0x1,%eax
4000180a:	89 45 b8             	mov    %eax,-0x48(%ebp)
4000180d:	8b 45 b8             	mov    -0x48(%ebp),%eax
40001810:	ba 00 00 00 00       	mov    $0x0,%edx
40001815:	f7 75 bc             	divl   -0x44(%ebp)
40001818:	89 d0                	mov    %edx,%eax
4000181a:	8b 55 b8             	mov    -0x48(%ebp),%edx
4000181d:	89 d6                	mov    %edx,%esi
4000181f:	29 c6                	sub    %eax,%esi
40001821:	89 f0                	mov    %esi,%eax
40001823:	01 d8                	add    %ebx,%eax
40001825:	05 00 00 00 80       	add    $0x80000000,%eax
4000182a:	c7 45 b4 00 07 00 00 	movl   $0x700,-0x4c(%ebp)
40001831:	66 c7 45 b2 00 00    	movw   $0x0,-0x4e(%ebp)
40001837:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
4000183e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
40001845:	89 45 a4             	mov    %eax,-0x5c(%ebp)
40001848:	89 4d a0             	mov    %ecx,-0x60(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
4000184b:	8b 45 b4             	mov    -0x4c(%ebp),%eax
4000184e:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001851:	8b 5d ac             	mov    -0x54(%ebp),%ebx
40001854:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
40001858:	8b 75 a8             	mov    -0x58(%ebp),%esi
4000185b:	8b 7d a4             	mov    -0x5c(%ebp),%edi
4000185e:	8b 4d a0             	mov    -0x60(%ebp),%ecx
40001861:	cd 30                	int    $0x30
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
		fi->size = after_write_size;
40001863:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001866:	8b 55 d0             	mov    -0x30(%ebp),%edx
40001869:	89 50 4c             	mov    %edx,0x4c(%eax)
	}
	for(i; i < count; i++){
4000186c:	eb 2f                	jmp    4000189d <fileino_write+0x287>
		memcpy(write_pointer, buf, eltsize);
4000186e:	8b 45 14             	mov    0x14(%ebp),%eax
40001871:	89 44 24 08          	mov    %eax,0x8(%esp)
40001875:	8b 45 10             	mov    0x10(%ebp),%eax
40001878:	89 44 24 04          	mov    %eax,0x4(%esp)
4000187c:	8b 45 dc             	mov    -0x24(%ebp),%eax
4000187f:	89 04 24             	mov    %eax,(%esp)
40001882:	e8 4a f9 ff ff       	call   400011d1 <memcpy>
		return_number++;
40001887:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
		buf += eltsize;
4000188b:	8b 45 14             	mov    0x14(%ebp),%eax
4000188e:	01 45 10             	add    %eax,0x10(%ebp)
		write_pointer += eltsize;
40001891:	8b 45 14             	mov    0x14(%ebp),%eax
40001894:	01 45 dc             	add    %eax,-0x24(%ebp)
	if(after_write_size > fi->size){
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
		fi->size = after_write_size;
	}
	for(i; i < count; i++){
40001897:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
4000189b:	eb 01                	jmp    4000189e <fileino_write+0x288>
4000189d:	90                   	nop
4000189e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400018a1:	3b 45 18             	cmp    0x18(%ebp),%eax
400018a4:	72 c8                	jb     4000186e <fileino_write+0x258>
		memcpy(write_pointer, buf, eltsize);
		return_number++;
		buf += eltsize;
		write_pointer += eltsize;
	}
	return return_number;
400018a6:	8b 45 e0             	mov    -0x20(%ebp),%eax

	// Lab 4: insert your file writing code here.
	//warn("fileino_write() not implemented");
	//errno = EINVAL;
	//return -1;
}
400018a9:	83 c4 6c             	add    $0x6c,%esp
400018ac:	5b                   	pop    %ebx
400018ad:	5e                   	pop    %esi
400018ae:	5f                   	pop    %edi
400018af:	5d                   	pop    %ebp
400018b0:	c3                   	ret    

400018b1 <fileino_stat>:
// Return file statistics about a particular inode.
// The specified inode must indicate a file that exists,
// but it can be any type of object: e.g., file, directory, special file, etc.
int
fileino_stat(int ino, struct stat *st)
{
400018b1:	55                   	push   %ebp
400018b2:	89 e5                	mov    %esp,%ebp
400018b4:	83 ec 28             	sub    $0x28,%esp
	assert(fileino_exists(ino));
400018b7:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400018bb:	7e 3d                	jle    400018fa <fileino_stat+0x49>
400018bd:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
400018c4:	7f 34                	jg     400018fa <fileino_stat+0x49>
400018c6:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
400018cc:	8b 45 08             	mov    0x8(%ebp),%eax
400018cf:	6b c0 5c             	imul   $0x5c,%eax,%eax
400018d2:	01 d0                	add    %edx,%eax
400018d4:	05 10 10 00 00       	add    $0x1010,%eax
400018d9:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400018dd:	84 c0                	test   %al,%al
400018df:	74 19                	je     400018fa <fileino_stat+0x49>
400018e1:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
400018e7:	8b 45 08             	mov    0x8(%ebp),%eax
400018ea:	6b c0 5c             	imul   $0x5c,%eax,%eax
400018ed:	01 d0                	add    %edx,%eax
400018ef:	05 58 10 00 00       	add    $0x1058,%eax
400018f4:	8b 00                	mov    (%eax),%eax
400018f6:	85 c0                	test   %eax,%eax
400018f8:	75 24                	jne    4000191e <fileino_stat+0x6d>
400018fa:	c7 44 24 0c 11 40 00 	movl   $0x40004011,0xc(%esp)
40001901:	40 
40001902:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40001909:	40 
4000190a:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
40001911:	00 
40001912:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40001919:	e8 3a ec ff ff       	call   40000558 <debug_panic>

	fileinode *fi = &files->fi[ino];
4000191e:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40001923:	8b 55 08             	mov    0x8(%ebp),%edx
40001926:	6b d2 5c             	imul   $0x5c,%edx,%edx
40001929:	81 c2 10 10 00 00    	add    $0x1010,%edx
4000192f:	01 d0                	add    %edx,%eax
40001931:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert(fileino_isdir(fi->dino));	// Should be in a directory!
40001934:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001937:	8b 00                	mov    (%eax),%eax
40001939:	85 c0                	test   %eax,%eax
4000193b:	7e 4c                	jle    40001989 <fileino_stat+0xd8>
4000193d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001940:	8b 00                	mov    (%eax),%eax
40001942:	3d ff 00 00 00       	cmp    $0xff,%eax
40001947:	7f 40                	jg     40001989 <fileino_stat+0xd8>
40001949:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
4000194f:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001952:	8b 00                	mov    (%eax),%eax
40001954:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001957:	01 d0                	add    %edx,%eax
40001959:	05 10 10 00 00       	add    $0x1010,%eax
4000195e:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40001962:	84 c0                	test   %al,%al
40001964:	74 23                	je     40001989 <fileino_stat+0xd8>
40001966:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
4000196c:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000196f:	8b 00                	mov    (%eax),%eax
40001971:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001974:	01 d0                	add    %edx,%eax
40001976:	05 58 10 00 00       	add    $0x1058,%eax
4000197b:	8b 00                	mov    (%eax),%eax
4000197d:	25 00 70 00 00       	and    $0x7000,%eax
40001982:	3d 00 20 00 00       	cmp    $0x2000,%eax
40001987:	74 24                	je     400019ad <fileino_stat+0xfc>
40001989:	c7 44 24 0c 25 40 00 	movl   $0x40004025,0xc(%esp)
40001990:	40 
40001991:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40001998:	40 
40001999:	c7 44 24 04 af 00 00 	movl   $0xaf,0x4(%esp)
400019a0:	00 
400019a1:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
400019a8:	e8 ab eb ff ff       	call   40000558 <debug_panic>
	st->st_ino = ino;
400019ad:	8b 45 0c             	mov    0xc(%ebp),%eax
400019b0:	8b 55 08             	mov    0x8(%ebp),%edx
400019b3:	89 10                	mov    %edx,(%eax)
	st->st_mode = fi->mode;
400019b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
400019b8:	8b 50 48             	mov    0x48(%eax),%edx
400019bb:	8b 45 0c             	mov    0xc(%ebp),%eax
400019be:	89 50 04             	mov    %edx,0x4(%eax)
	st->st_size = fi->size;
400019c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
400019c4:	8b 40 4c             	mov    0x4c(%eax),%eax
400019c7:	89 c2                	mov    %eax,%edx
400019c9:	8b 45 0c             	mov    0xc(%ebp),%eax
400019cc:	89 50 08             	mov    %edx,0x8(%eax)

	return 0;
400019cf:	b8 00 00 00 00       	mov    $0x0,%eax
}
400019d4:	c9                   	leave  
400019d5:	c3                   	ret    

400019d6 <fileino_truncate>:
// Grow or shrink a file to exactly a specified size.
// If growing a file, then fills the new space with zeros.
// Returns 0 if successful, or returns -1 and sets errno on error.
int
fileino_truncate(int ino, off_t newsize)
{
400019d6:	55                   	push   %ebp
400019d7:	89 e5                	mov    %esp,%ebp
400019d9:	57                   	push   %edi
400019da:	56                   	push   %esi
400019db:	53                   	push   %ebx
400019dc:	81 ec 8c 00 00 00    	sub    $0x8c,%esp
	assert(fileino_isvalid(ino));
400019e2:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400019e6:	7e 09                	jle    400019f1 <fileino_truncate+0x1b>
400019e8:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
400019ef:	7e 24                	jle    40001a15 <fileino_truncate+0x3f>
400019f1:	c7 44 24 0c 3d 40 00 	movl   $0x4000403d,0xc(%esp)
400019f8:	40 
400019f9:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40001a00:	40 
40001a01:	c7 44 24 04 bd 00 00 	movl   $0xbd,0x4(%esp)
40001a08:	00 
40001a09:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40001a10:	e8 43 eb ff ff       	call   40000558 <debug_panic>
	assert(newsize >= 0 && newsize <= FILE_MAXSIZE);
40001a15:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40001a19:	78 09                	js     40001a24 <fileino_truncate+0x4e>
40001a1b:	81 7d 0c 00 00 40 00 	cmpl   $0x400000,0xc(%ebp)
40001a22:	7e 24                	jle    40001a48 <fileino_truncate+0x72>
40001a24:	c7 44 24 0c 54 40 00 	movl   $0x40004054,0xc(%esp)
40001a2b:	40 
40001a2c:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40001a33:	40 
40001a34:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
40001a3b:	00 
40001a3c:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40001a43:	e8 10 eb ff ff       	call   40000558 <debug_panic>

	size_t oldsize = files->fi[ino].size;
40001a48:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40001a4e:	8b 45 08             	mov    0x8(%ebp),%eax
40001a51:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001a54:	01 d0                	add    %edx,%eax
40001a56:	05 5c 10 00 00       	add    $0x105c,%eax
40001a5b:	8b 00                	mov    (%eax),%eax
40001a5d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	size_t oldpagelim = ROUNDUP(files->fi[ino].size, PAGESIZE);
40001a60:	c7 45 e0 00 10 00 00 	movl   $0x1000,-0x20(%ebp)
40001a67:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40001a6d:	8b 45 08             	mov    0x8(%ebp),%eax
40001a70:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001a73:	01 d0                	add    %edx,%eax
40001a75:	05 5c 10 00 00       	add    $0x105c,%eax
40001a7a:	8b 10                	mov    (%eax),%edx
40001a7c:	8b 45 e0             	mov    -0x20(%ebp),%eax
40001a7f:	01 d0                	add    %edx,%eax
40001a81:	83 e8 01             	sub    $0x1,%eax
40001a84:	89 45 dc             	mov    %eax,-0x24(%ebp)
40001a87:	8b 45 dc             	mov    -0x24(%ebp),%eax
40001a8a:	ba 00 00 00 00       	mov    $0x0,%edx
40001a8f:	f7 75 e0             	divl   -0x20(%ebp)
40001a92:	89 d0                	mov    %edx,%eax
40001a94:	8b 55 dc             	mov    -0x24(%ebp),%edx
40001a97:	89 d1                	mov    %edx,%ecx
40001a99:	29 c1                	sub    %eax,%ecx
40001a9b:	89 c8                	mov    %ecx,%eax
40001a9d:	89 45 d8             	mov    %eax,-0x28(%ebp)
	size_t newpagelim = ROUNDUP(newsize, PAGESIZE);
40001aa0:	c7 45 d4 00 10 00 00 	movl   $0x1000,-0x2c(%ebp)
40001aa7:	8b 55 0c             	mov    0xc(%ebp),%edx
40001aaa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40001aad:	01 d0                	add    %edx,%eax
40001aaf:	83 e8 01             	sub    $0x1,%eax
40001ab2:	89 45 d0             	mov    %eax,-0x30(%ebp)
40001ab5:	8b 45 d0             	mov    -0x30(%ebp),%eax
40001ab8:	ba 00 00 00 00       	mov    $0x0,%edx
40001abd:	f7 75 d4             	divl   -0x2c(%ebp)
40001ac0:	89 d0                	mov    %edx,%eax
40001ac2:	8b 55 d0             	mov    -0x30(%ebp),%edx
40001ac5:	89 d1                	mov    %edx,%ecx
40001ac7:	29 c1                	sub    %eax,%ecx
40001ac9:	89 c8                	mov    %ecx,%eax
40001acb:	89 45 cc             	mov    %eax,-0x34(%ebp)
	if (newsize > oldsize) {
40001ace:	8b 45 0c             	mov    0xc(%ebp),%eax
40001ad1:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
40001ad4:	0f 86 8a 00 00 00    	jbe    40001b64 <fileino_truncate+0x18e>
		// Grow the file and fill the new space with zeros.
		sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
40001ada:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001add:	8b 55 cc             	mov    -0x34(%ebp),%edx
40001ae0:	89 d1                	mov    %edx,%ecx
40001ae2:	29 c1                	sub    %eax,%ecx
40001ae4:	89 c8                	mov    %ecx,%eax
			FILEDATA(ino) + oldpagelim,
40001ae6:	8b 55 08             	mov    0x8(%ebp),%edx
40001ae9:	c1 e2 16             	shl    $0x16,%edx
40001aec:	89 d1                	mov    %edx,%ecx
40001aee:	8b 55 d8             	mov    -0x28(%ebp),%edx
40001af1:	01 ca                	add    %ecx,%edx
	size_t oldsize = files->fi[ino].size;
	size_t oldpagelim = ROUNDUP(files->fi[ino].size, PAGESIZE);
	size_t newpagelim = ROUNDUP(newsize, PAGESIZE);
	if (newsize > oldsize) {
		// Grow the file and fill the new space with zeros.
		sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
40001af3:	81 c2 00 00 00 80    	add    $0x80000000,%edx
40001af9:	c7 45 c8 00 07 00 00 	movl   $0x700,-0x38(%ebp)
40001b00:	66 c7 45 c6 00 00    	movw   $0x0,-0x3a(%ebp)
40001b06:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
40001b0d:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
40001b14:	89 55 b8             	mov    %edx,-0x48(%ebp)
40001b17:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001b1a:	8b 45 c8             	mov    -0x38(%ebp),%eax
40001b1d:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001b20:	8b 5d c0             	mov    -0x40(%ebp),%ebx
40001b23:	0f b7 55 c6          	movzwl -0x3a(%ebp),%edx
40001b27:	8b 75 bc             	mov    -0x44(%ebp),%esi
40001b2a:	8b 7d b8             	mov    -0x48(%ebp),%edi
40001b2d:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
40001b30:	cd 30                	int    $0x30
			FILEDATA(ino) + oldpagelim,
			newpagelim - oldpagelim);
		memset(FILEDATA(ino) + oldsize, 0, newsize - oldsize);
40001b32:	8b 45 0c             	mov    0xc(%ebp),%eax
40001b35:	2b 45 e4             	sub    -0x1c(%ebp),%eax
40001b38:	8b 55 08             	mov    0x8(%ebp),%edx
40001b3b:	c1 e2 16             	shl    $0x16,%edx
40001b3e:	89 d1                	mov    %edx,%ecx
40001b40:	8b 55 e4             	mov    -0x1c(%ebp),%edx
40001b43:	01 ca                	add    %ecx,%edx
40001b45:	81 c2 00 00 00 80    	add    $0x80000000,%edx
40001b4b:	89 44 24 08          	mov    %eax,0x8(%esp)
40001b4f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001b56:	00 
40001b57:	89 14 24             	mov    %edx,(%esp)
40001b5a:	e8 2a f5 ff ff       	call   40001089 <memset>
40001b5f:	e9 a4 00 00 00       	jmp    40001c08 <fileino_truncate+0x232>
	} else if (newsize > 0) {
40001b64:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40001b68:	7e 56                	jle    40001bc0 <fileino_truncate+0x1ea>
		// Shrink the file, but not all the way to empty.
		// Would prefer to use SYS_ZERO to free the file content,
		// but SYS_ZERO isn't guaranteed to work at page granularity.
		sys_get(SYS_PERM, 0, NULL, NULL,
40001b6a:	b8 00 00 40 00       	mov    $0x400000,%eax
40001b6f:	2b 45 cc             	sub    -0x34(%ebp),%eax
			FILEDATA(ino) + newpagelim, FILE_MAXSIZE - newpagelim);
40001b72:	8b 55 08             	mov    0x8(%ebp),%edx
40001b75:	c1 e2 16             	shl    $0x16,%edx
40001b78:	89 d1                	mov    %edx,%ecx
40001b7a:	8b 55 cc             	mov    -0x34(%ebp),%edx
40001b7d:	01 ca                	add    %ecx,%edx
		memset(FILEDATA(ino) + oldsize, 0, newsize - oldsize);
	} else if (newsize > 0) {
		// Shrink the file, but not all the way to empty.
		// Would prefer to use SYS_ZERO to free the file content,
		// but SYS_ZERO isn't guaranteed to work at page granularity.
		sys_get(SYS_PERM, 0, NULL, NULL,
40001b7f:	81 c2 00 00 00 80    	add    $0x80000000,%edx
40001b85:	c7 45 b0 00 01 00 00 	movl   $0x100,-0x50(%ebp)
40001b8c:	66 c7 45 ae 00 00    	movw   $0x0,-0x52(%ebp)
40001b92:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
40001b99:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
40001ba0:	89 55 a0             	mov    %edx,-0x60(%ebp)
40001ba3:	89 45 9c             	mov    %eax,-0x64(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001ba6:	8b 45 b0             	mov    -0x50(%ebp),%eax
40001ba9:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001bac:	8b 5d a8             	mov    -0x58(%ebp),%ebx
40001baf:	0f b7 55 ae          	movzwl -0x52(%ebp),%edx
40001bb3:	8b 75 a4             	mov    -0x5c(%ebp),%esi
40001bb6:	8b 7d a0             	mov    -0x60(%ebp),%edi
40001bb9:	8b 4d 9c             	mov    -0x64(%ebp),%ecx
40001bbc:	cd 30                	int    $0x30
40001bbe:	eb 48                	jmp    40001c08 <fileino_truncate+0x232>
			FILEDATA(ino) + newpagelim, FILE_MAXSIZE - newpagelim);
	} else {
		// Shrink the file to empty.  Use SYS_ZERO to free completely.
		sys_get(SYS_ZERO, 0, NULL, NULL, FILEDATA(ino), FILE_MAXSIZE);
40001bc0:	8b 45 08             	mov    0x8(%ebp),%eax
40001bc3:	c1 e0 16             	shl    $0x16,%eax
40001bc6:	05 00 00 00 80       	add    $0x80000000,%eax
40001bcb:	c7 45 98 00 00 01 00 	movl   $0x10000,-0x68(%ebp)
40001bd2:	66 c7 45 96 00 00    	movw   $0x0,-0x6a(%ebp)
40001bd8:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
40001bdf:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
40001be6:	89 45 88             	mov    %eax,-0x78(%ebp)
40001be9:	c7 45 84 00 00 40 00 	movl   $0x400000,-0x7c(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001bf0:	8b 45 98             	mov    -0x68(%ebp),%eax
40001bf3:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001bf6:	8b 5d 90             	mov    -0x70(%ebp),%ebx
40001bf9:	0f b7 55 96          	movzwl -0x6a(%ebp),%edx
40001bfd:	8b 75 8c             	mov    -0x74(%ebp),%esi
40001c00:	8b 7d 88             	mov    -0x78(%ebp),%edi
40001c03:	8b 4d 84             	mov    -0x7c(%ebp),%ecx
40001c06:	cd 30                	int    $0x30
	}
	files->fi[ino].size = newsize;
40001c08:	8b 0d 2c 3f 00 40    	mov    0x40003f2c,%ecx
40001c0e:	8b 45 0c             	mov    0xc(%ebp),%eax
40001c11:	8b 55 08             	mov    0x8(%ebp),%edx
40001c14:	6b d2 5c             	imul   $0x5c,%edx,%edx
40001c17:	01 ca                	add    %ecx,%edx
40001c19:	81 c2 5c 10 00 00    	add    $0x105c,%edx
40001c1f:	89 02                	mov    %eax,(%edx)
	files->fi[ino].ver++;	// truncation is always an exclusive change
40001c21:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40001c26:	8b 55 08             	mov    0x8(%ebp),%edx
40001c29:	6b d2 5c             	imul   $0x5c,%edx,%edx
40001c2c:	01 c2                	add    %eax,%edx
40001c2e:	81 c2 54 10 00 00    	add    $0x1054,%edx
40001c34:	8b 12                	mov    (%edx),%edx
40001c36:	83 c2 01             	add    $0x1,%edx
40001c39:	8b 4d 08             	mov    0x8(%ebp),%ecx
40001c3c:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
40001c3f:	01 c8                	add    %ecx,%eax
40001c41:	05 54 10 00 00       	add    $0x1054,%eax
40001c46:	89 10                	mov    %edx,(%eax)
	return 0;
40001c48:	b8 00 00 00 00       	mov    $0x0,%eax
}
40001c4d:	81 c4 8c 00 00 00    	add    $0x8c,%esp
40001c53:	5b                   	pop    %ebx
40001c54:	5e                   	pop    %esi
40001c55:	5f                   	pop    %edi
40001c56:	5d                   	pop    %ebp
40001c57:	c3                   	ret    

40001c58 <fileino_flush>:

// Flush any outstanding writes on this file to our parent process.
// (XXX should flushes propagate across multiple levels?)
int
fileino_flush(int ino)
{
40001c58:	55                   	push   %ebp
40001c59:	89 e5                	mov    %esp,%ebp
40001c5b:	83 ec 18             	sub    $0x18,%esp
	assert(fileino_isvalid(ino));
40001c5e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001c62:	7e 09                	jle    40001c6d <fileino_flush+0x15>
40001c64:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40001c6b:	7e 24                	jle    40001c91 <fileino_flush+0x39>
40001c6d:	c7 44 24 0c 3d 40 00 	movl   $0x4000403d,0xc(%esp)
40001c74:	40 
40001c75:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40001c7c:	40 
40001c7d:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
40001c84:	00 
40001c85:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40001c8c:	e8 c7 e8 ff ff       	call   40000558 <debug_panic>

	if (files->fi[ino].size > files->fi[ino].rlen)
40001c91:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40001c97:	8b 45 08             	mov    0x8(%ebp),%eax
40001c9a:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001c9d:	01 d0                	add    %edx,%eax
40001c9f:	05 5c 10 00 00       	add    $0x105c,%eax
40001ca4:	8b 10                	mov    (%eax),%edx
40001ca6:	8b 0d 2c 3f 00 40    	mov    0x40003f2c,%ecx
40001cac:	8b 45 08             	mov    0x8(%ebp),%eax
40001caf:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001cb2:	01 c8                	add    %ecx,%eax
40001cb4:	05 68 10 00 00       	add    $0x1068,%eax
40001cb9:	8b 00                	mov    (%eax),%eax
40001cbb:	39 c2                	cmp    %eax,%edx
40001cbd:	76 07                	jbe    40001cc6 <fileino_flush+0x6e>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001cbf:	b8 03 00 00 00       	mov    $0x3,%eax
40001cc4:	cd 30                	int    $0x30
		sys_ret();	// synchronize and reconcile with parent
	return 0;
40001cc6:	b8 00 00 00 00       	mov    $0x0,%eax
}
40001ccb:	c9                   	leave  
40001ccc:	c3                   	ret    

40001ccd <filedesc_alloc>:
// Search the file descriptor table for the first free file descriptor,
// and return a pointer to that file descriptor.
// If no file descriptors are available,
// returns NULL and set errno appropriately.
filedesc *filedesc_alloc(void)
{
40001ccd:	55                   	push   %ebp
40001cce:	89 e5                	mov    %esp,%ebp
40001cd0:	83 ec 10             	sub    $0x10,%esp
	int i;
	for (i = 0; i < OPEN_MAX; i++)
40001cd3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
40001cda:	eb 2c                	jmp    40001d08 <filedesc_alloc+0x3b>
		if (files->fd[i].ino == FILEINO_NULL)
40001cdc:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40001ce1:	8b 55 fc             	mov    -0x4(%ebp),%edx
40001ce4:	83 c2 01             	add    $0x1,%edx
40001ce7:	c1 e2 04             	shl    $0x4,%edx
40001cea:	01 d0                	add    %edx,%eax
40001cec:	8b 00                	mov    (%eax),%eax
40001cee:	85 c0                	test   %eax,%eax
40001cf0:	75 12                	jne    40001d04 <filedesc_alloc+0x37>
			return &files->fd[i];
40001cf2:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40001cf7:	8b 55 fc             	mov    -0x4(%ebp),%edx
40001cfa:	83 c2 01             	add    $0x1,%edx
40001cfd:	c1 e2 04             	shl    $0x4,%edx
40001d00:	01 d0                	add    %edx,%eax
40001d02:	eb 1d                	jmp    40001d21 <filedesc_alloc+0x54>
// If no file descriptors are available,
// returns NULL and set errno appropriately.
filedesc *filedesc_alloc(void)
{
	int i;
	for (i = 0; i < OPEN_MAX; i++)
40001d04:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40001d08:	81 7d fc ff 00 00 00 	cmpl   $0xff,-0x4(%ebp)
40001d0f:	7e cb                	jle    40001cdc <filedesc_alloc+0xf>
		if (files->fd[i].ino == FILEINO_NULL)
			return &files->fd[i];
	errno = EMFILE;
40001d11:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40001d16:	c7 00 04 00 00 00    	movl   $0x4,(%eax)
	return NULL;
40001d1c:	b8 00 00 00 00       	mov    $0x0,%eax
}
40001d21:	c9                   	leave  
40001d22:	c3                   	ret    

40001d23 <filedesc_open>:
// The 'openflags' determines whether the file is created, truncated, etc.
// Returns the opened file descriptor on success,
// or returns NULL and sets errno on failure.
filedesc *
filedesc_open(filedesc *fd, const char *path, int openflags, mode_t mode)
{
40001d23:	55                   	push   %ebp
40001d24:	89 e5                	mov    %esp,%ebp
40001d26:	83 ec 28             	sub    $0x28,%esp
	if (!fd && !(fd = filedesc_alloc()))
40001d29:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001d2d:	75 18                	jne    40001d47 <filedesc_open+0x24>
40001d2f:	e8 99 ff ff ff       	call   40001ccd <filedesc_alloc>
40001d34:	89 45 08             	mov    %eax,0x8(%ebp)
40001d37:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40001d3b:	75 0a                	jne    40001d47 <filedesc_open+0x24>
		return NULL;
40001d3d:	b8 00 00 00 00       	mov    $0x0,%eax
40001d42:	e9 04 02 00 00       	jmp    40001f4b <filedesc_open+0x228>
	assert(fd->ino == FILEINO_NULL);
40001d47:	8b 45 08             	mov    0x8(%ebp),%eax
40001d4a:	8b 00                	mov    (%eax),%eax
40001d4c:	85 c0                	test   %eax,%eax
40001d4e:	74 24                	je     40001d74 <filedesc_open+0x51>
40001d50:	c7 44 24 0c 7c 40 00 	movl   $0x4000407c,0xc(%esp)
40001d57:	40 
40001d58:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40001d5f:	40 
40001d60:	c7 44 24 04 00 01 00 	movl   $0x100,0x4(%esp)
40001d67:	00 
40001d68:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40001d6f:	e8 e4 e7 ff ff       	call   40000558 <debug_panic>

	// Determine the complete file mode if it is to be created.
	mode_t createmode = (openflags & O_CREAT) ? S_IFREG | (mode & 0777) : 0;
40001d74:	8b 45 10             	mov    0x10(%ebp),%eax
40001d77:	83 e0 20             	and    $0x20,%eax
40001d7a:	85 c0                	test   %eax,%eax
40001d7c:	74 0d                	je     40001d8b <filedesc_open+0x68>
40001d7e:	8b 45 14             	mov    0x14(%ebp),%eax
40001d81:	25 ff 01 00 00       	and    $0x1ff,%eax
40001d86:	80 cc 10             	or     $0x10,%ah
40001d89:	eb 05                	jmp    40001d90 <filedesc_open+0x6d>
40001d8b:	b8 00 00 00 00       	mov    $0x0,%eax
40001d90:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Walk the directory tree to find the desired directory entry,
	// creating an entry if it doesn't exist and O_CREAT is set.
	int ino = dir_walk(path, createmode);
40001d93:	8b 45 f4             	mov    -0xc(%ebp),%eax
40001d96:	89 44 24 04          	mov    %eax,0x4(%esp)
40001d9a:	8b 45 0c             	mov    0xc(%ebp),%eax
40001d9d:	89 04 24             	mov    %eax,(%esp)
40001da0:	e8 d7 05 00 00       	call   4000237c <dir_walk>
40001da5:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (ino < 0)
40001da8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40001dac:	79 0a                	jns    40001db8 <filedesc_open+0x95>
		return NULL;
40001dae:	b8 00 00 00 00       	mov    $0x0,%eax
40001db3:	e9 93 01 00 00       	jmp    40001f4b <filedesc_open+0x228>
	assert(fileino_exists(ino));
40001db8:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40001dbc:	7e 3d                	jle    40001dfb <filedesc_open+0xd8>
40001dbe:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40001dc5:	7f 34                	jg     40001dfb <filedesc_open+0xd8>
40001dc7:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40001dcd:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001dd0:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001dd3:	01 d0                	add    %edx,%eax
40001dd5:	05 10 10 00 00       	add    $0x1010,%eax
40001dda:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40001dde:	84 c0                	test   %al,%al
40001de0:	74 19                	je     40001dfb <filedesc_open+0xd8>
40001de2:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40001de8:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001deb:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001dee:	01 d0                	add    %edx,%eax
40001df0:	05 58 10 00 00       	add    $0x1058,%eax
40001df5:	8b 00                	mov    (%eax),%eax
40001df7:	85 c0                	test   %eax,%eax
40001df9:	75 24                	jne    40001e1f <filedesc_open+0xfc>
40001dfb:	c7 44 24 0c 11 40 00 	movl   $0x40004011,0xc(%esp)
40001e02:	40 
40001e03:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40001e0a:	40 
40001e0b:	c7 44 24 04 0a 01 00 	movl   $0x10a,0x4(%esp)
40001e12:	00 
40001e13:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40001e1a:	e8 39 e7 ff ff       	call   40000558 <debug_panic>

	// Refuse to open conflict-marked files;
	// the user needs to resolve the conflict and clear the conflict flag,
	// or just delete the conflicted file.
	if (files->fi[ino].mode & S_IFCONF) {
40001e1f:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40001e25:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001e28:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001e2b:	01 d0                	add    %edx,%eax
40001e2d:	05 58 10 00 00       	add    $0x1058,%eax
40001e32:	8b 00                	mov    (%eax),%eax
40001e34:	25 00 00 01 00       	and    $0x10000,%eax
40001e39:	85 c0                	test   %eax,%eax
40001e3b:	74 15                	je     40001e52 <filedesc_open+0x12f>
		errno = ECONFLICT;
40001e3d:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40001e42:	c7 00 0a 00 00 00    	movl   $0xa,(%eax)
		return NULL;
40001e48:	b8 00 00 00 00       	mov    $0x0,%eax
40001e4d:	e9 f9 00 00 00       	jmp    40001f4b <filedesc_open+0x228>
	}

	// Truncate the file if we were asked to
	if (openflags & O_TRUNC) {
40001e52:	8b 45 10             	mov    0x10(%ebp),%eax
40001e55:	83 e0 40             	and    $0x40,%eax
40001e58:	85 c0                	test   %eax,%eax
40001e5a:	74 5c                	je     40001eb8 <filedesc_open+0x195>
		if (!(openflags & O_WRONLY)) {
40001e5c:	8b 45 10             	mov    0x10(%ebp),%eax
40001e5f:	83 e0 02             	and    $0x2,%eax
40001e62:	85 c0                	test   %eax,%eax
40001e64:	75 31                	jne    40001e97 <filedesc_open+0x174>
			warn("filedesc_open: can't truncate non-writable file");
40001e66:	c7 44 24 08 94 40 00 	movl   $0x40004094,0x8(%esp)
40001e6d:	40 
40001e6e:	c7 44 24 04 17 01 00 	movl   $0x117,0x4(%esp)
40001e75:	00 
40001e76:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40001e7d:	e8 40 e7 ff ff       	call   400005c2 <debug_warn>
			errno = EINVAL;
40001e82:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40001e87:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
			return NULL;
40001e8d:	b8 00 00 00 00       	mov    $0x0,%eax
40001e92:	e9 b4 00 00 00       	jmp    40001f4b <filedesc_open+0x228>
		}
		if (fileino_truncate(ino, 0) < 0)
40001e97:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001e9e:	00 
40001e9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001ea2:	89 04 24             	mov    %eax,(%esp)
40001ea5:	e8 2c fb ff ff       	call   400019d6 <fileino_truncate>
40001eaa:	85 c0                	test   %eax,%eax
40001eac:	79 0a                	jns    40001eb8 <filedesc_open+0x195>
			return NULL;
40001eae:	b8 00 00 00 00       	mov    $0x0,%eax
40001eb3:	e9 93 00 00 00       	jmp    40001f4b <filedesc_open+0x228>
	}

	// Initialize the file descriptor
	fd->ino = ino;
40001eb8:	8b 45 08             	mov    0x8(%ebp),%eax
40001ebb:	8b 55 f0             	mov    -0x10(%ebp),%edx
40001ebe:	89 10                	mov    %edx,(%eax)
	fd->flags = openflags;
40001ec0:	8b 45 08             	mov    0x8(%ebp),%eax
40001ec3:	8b 55 10             	mov    0x10(%ebp),%edx
40001ec6:	89 50 04             	mov    %edx,0x4(%eax)
	fd->ofs = (openflags & O_APPEND) ? files->fi[ino].size : 0;
40001ec9:	8b 45 10             	mov    0x10(%ebp),%eax
40001ecc:	83 e0 10             	and    $0x10,%eax
40001ecf:	85 c0                	test   %eax,%eax
40001ed1:	74 17                	je     40001eea <filedesc_open+0x1c7>
40001ed3:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40001ed9:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001edc:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001edf:	01 d0                	add    %edx,%eax
40001ee1:	05 5c 10 00 00       	add    $0x105c,%eax
40001ee6:	8b 00                	mov    (%eax),%eax
40001ee8:	eb 05                	jmp    40001eef <filedesc_open+0x1cc>
40001eea:	b8 00 00 00 00       	mov    $0x0,%eax
40001eef:	8b 55 08             	mov    0x8(%ebp),%edx
40001ef2:	89 42 08             	mov    %eax,0x8(%edx)
	fd->err = 0;
40001ef5:	8b 45 08             	mov    0x8(%ebp),%eax
40001ef8:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)

	assert(filedesc_isopen(fd));
40001eff:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40001f04:	83 c0 10             	add    $0x10,%eax
40001f07:	3b 45 08             	cmp    0x8(%ebp),%eax
40001f0a:	77 18                	ja     40001f24 <filedesc_open+0x201>
40001f0c:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40001f11:	05 10 10 00 00       	add    $0x1010,%eax
40001f16:	3b 45 08             	cmp    0x8(%ebp),%eax
40001f19:	76 09                	jbe    40001f24 <filedesc_open+0x201>
40001f1b:	8b 45 08             	mov    0x8(%ebp),%eax
40001f1e:	8b 00                	mov    (%eax),%eax
40001f20:	85 c0                	test   %eax,%eax
40001f22:	75 24                	jne    40001f48 <filedesc_open+0x225>
40001f24:	c7 44 24 0c c4 40 00 	movl   $0x400040c4,0xc(%esp)
40001f2b:	40 
40001f2c:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40001f33:	40 
40001f34:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
40001f3b:	00 
40001f3c:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40001f43:	e8 10 e6 ff ff       	call   40000558 <debug_panic>
	return fd;
40001f48:	8b 45 08             	mov    0x8(%ebp),%eax
}
40001f4b:	c9                   	leave  
40001f4c:	c3                   	ret    

40001f4d <filedesc_read>:
// If the file is a special device input file such as the console,
// this function pretends the file has no end and instead
// uses sys_ret() to wait for the file to extend the special file.
ssize_t
filedesc_read(filedesc *fd, void *buf, size_t eltsize, size_t count)
{
40001f4d:	55                   	push   %ebp
40001f4e:	89 e5                	mov    %esp,%ebp
40001f50:	83 ec 38             	sub    $0x38,%esp
	assert(filedesc_isreadable(fd));
40001f53:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40001f58:	83 c0 10             	add    $0x10,%eax
40001f5b:	3b 45 08             	cmp    0x8(%ebp),%eax
40001f5e:	77 25                	ja     40001f85 <filedesc_read+0x38>
40001f60:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40001f65:	05 10 10 00 00       	add    $0x1010,%eax
40001f6a:	3b 45 08             	cmp    0x8(%ebp),%eax
40001f6d:	76 16                	jbe    40001f85 <filedesc_read+0x38>
40001f6f:	8b 45 08             	mov    0x8(%ebp),%eax
40001f72:	8b 00                	mov    (%eax),%eax
40001f74:	85 c0                	test   %eax,%eax
40001f76:	74 0d                	je     40001f85 <filedesc_read+0x38>
40001f78:	8b 45 08             	mov    0x8(%ebp),%eax
40001f7b:	8b 40 04             	mov    0x4(%eax),%eax
40001f7e:	83 e0 01             	and    $0x1,%eax
40001f81:	85 c0                	test   %eax,%eax
40001f83:	75 24                	jne    40001fa9 <filedesc_read+0x5c>
40001f85:	c7 44 24 0c d8 40 00 	movl   $0x400040d8,0xc(%esp)
40001f8c:	40 
40001f8d:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40001f94:	40 
40001f95:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
40001f9c:	00 
40001f9d:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40001fa4:	e8 af e5 ff ff       	call   40000558 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40001fa9:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40001faf:	8b 45 08             	mov    0x8(%ebp),%eax
40001fb2:	8b 00                	mov    (%eax),%eax
40001fb4:	6b c0 5c             	imul   $0x5c,%eax,%eax
40001fb7:	05 10 10 00 00       	add    $0x1010,%eax
40001fbc:	01 d0                	add    %edx,%eax
40001fbe:	89 45 f4             	mov    %eax,-0xc(%ebp)

	ssize_t actual = fileino_read(fd->ino, fd->ofs, buf, eltsize, count);
40001fc1:	8b 45 08             	mov    0x8(%ebp),%eax
40001fc4:	8b 50 08             	mov    0x8(%eax),%edx
40001fc7:	8b 45 08             	mov    0x8(%ebp),%eax
40001fca:	8b 00                	mov    (%eax),%eax
40001fcc:	8b 4d 14             	mov    0x14(%ebp),%ecx
40001fcf:	89 4c 24 10          	mov    %ecx,0x10(%esp)
40001fd3:	8b 4d 10             	mov    0x10(%ebp),%ecx
40001fd6:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
40001fda:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40001fdd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40001fe1:	89 54 24 04          	mov    %edx,0x4(%esp)
40001fe5:	89 04 24             	mov    %eax,(%esp)
40001fe8:	e8 93 f4 ff ff       	call   40001480 <fileino_read>
40001fed:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (actual < 0) {
40001ff0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40001ff4:	79 14                	jns    4000200a <filedesc_read+0xbd>
		fd->err = errno;	// save error indication for ferror()
40001ff6:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40001ffb:	8b 10                	mov    (%eax),%edx
40001ffd:	8b 45 08             	mov    0x8(%ebp),%eax
40002000:	89 50 0c             	mov    %edx,0xc(%eax)
		return -1;
40002003:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002008:	eb 56                	jmp    40002060 <filedesc_read+0x113>
	}

	// Advance the file position
	fd->ofs += eltsize * actual;
4000200a:	8b 45 08             	mov    0x8(%ebp),%eax
4000200d:	8b 40 08             	mov    0x8(%eax),%eax
40002010:	89 c2                	mov    %eax,%edx
40002012:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002015:	0f af 45 10          	imul   0x10(%ebp),%eax
40002019:	01 d0                	add    %edx,%eax
4000201b:	89 c2                	mov    %eax,%edx
4000201d:	8b 45 08             	mov    0x8(%ebp),%eax
40002020:	89 50 08             	mov    %edx,0x8(%eax)
	assert(actual == 0 || fi->size >= fd->ofs);
40002023:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002027:	74 34                	je     4000205d <filedesc_read+0x110>
40002029:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000202c:	8b 50 4c             	mov    0x4c(%eax),%edx
4000202f:	8b 45 08             	mov    0x8(%ebp),%eax
40002032:	8b 40 08             	mov    0x8(%eax),%eax
40002035:	39 c2                	cmp    %eax,%edx
40002037:	73 24                	jae    4000205d <filedesc_read+0x110>
40002039:	c7 44 24 0c f0 40 00 	movl   $0x400040f0,0xc(%esp)
40002040:	40 
40002041:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40002048:	40 
40002049:	c7 44 24 04 42 01 00 	movl   $0x142,0x4(%esp)
40002050:	00 
40002051:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40002058:	e8 fb e4 ff ff       	call   40000558 <debug_panic>

	return actual;
4000205d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40002060:	c9                   	leave  
40002061:	c3                   	ret    

40002062 <filedesc_write>:
// The size of 'buf' must be at least 'count * eltsize' bytes.
// On success, returns the number of objects written (NOT the number of bytes).
// If an error occurs, returns -1 and sets errno appropriately.
ssize_t
filedesc_write(filedesc *fd, const void *buf, size_t eltsize, size_t count)
{
40002062:	55                   	push   %ebp
40002063:	89 e5                	mov    %esp,%ebp
40002065:	83 ec 38             	sub    $0x38,%esp
	assert(filedesc_iswritable(fd));
40002068:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000206d:	83 c0 10             	add    $0x10,%eax
40002070:	3b 45 08             	cmp    0x8(%ebp),%eax
40002073:	77 25                	ja     4000209a <filedesc_write+0x38>
40002075:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000207a:	05 10 10 00 00       	add    $0x1010,%eax
4000207f:	3b 45 08             	cmp    0x8(%ebp),%eax
40002082:	76 16                	jbe    4000209a <filedesc_write+0x38>
40002084:	8b 45 08             	mov    0x8(%ebp),%eax
40002087:	8b 00                	mov    (%eax),%eax
40002089:	85 c0                	test   %eax,%eax
4000208b:	74 0d                	je     4000209a <filedesc_write+0x38>
4000208d:	8b 45 08             	mov    0x8(%ebp),%eax
40002090:	8b 40 04             	mov    0x4(%eax),%eax
40002093:	83 e0 02             	and    $0x2,%eax
40002096:	85 c0                	test   %eax,%eax
40002098:	75 24                	jne    400020be <filedesc_write+0x5c>
4000209a:	c7 44 24 0c 13 41 00 	movl   $0x40004113,0xc(%esp)
400020a1:	40 
400020a2:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
400020a9:	40 
400020aa:	c7 44 24 04 4f 01 00 	movl   $0x14f,0x4(%esp)
400020b1:	00 
400020b2:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
400020b9:	e8 9a e4 ff ff       	call   40000558 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
400020be:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
400020c4:	8b 45 08             	mov    0x8(%ebp),%eax
400020c7:	8b 00                	mov    (%eax),%eax
400020c9:	6b c0 5c             	imul   $0x5c,%eax,%eax
400020cc:	05 10 10 00 00       	add    $0x1010,%eax
400020d1:	01 d0                	add    %edx,%eax
400020d3:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// If we're appending to the file, seek to the end first.
	if (fd->flags & O_APPEND)
400020d6:	8b 45 08             	mov    0x8(%ebp),%eax
400020d9:	8b 40 04             	mov    0x4(%eax),%eax
400020dc:	83 e0 10             	and    $0x10,%eax
400020df:	85 c0                	test   %eax,%eax
400020e1:	74 0e                	je     400020f1 <filedesc_write+0x8f>
		fd->ofs = fi->size;
400020e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
400020e6:	8b 40 4c             	mov    0x4c(%eax),%eax
400020e9:	89 c2                	mov    %eax,%edx
400020eb:	8b 45 08             	mov    0x8(%ebp),%eax
400020ee:	89 50 08             	mov    %edx,0x8(%eax)

	// Write the data, growing the file as necessary.
	ssize_t actual = fileino_write(fd->ino, fd->ofs, buf, eltsize, count);
400020f1:	8b 45 08             	mov    0x8(%ebp),%eax
400020f4:	8b 50 08             	mov    0x8(%eax),%edx
400020f7:	8b 45 08             	mov    0x8(%ebp),%eax
400020fa:	8b 00                	mov    (%eax),%eax
400020fc:	8b 4d 14             	mov    0x14(%ebp),%ecx
400020ff:	89 4c 24 10          	mov    %ecx,0x10(%esp)
40002103:	8b 4d 10             	mov    0x10(%ebp),%ecx
40002106:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
4000210a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
4000210d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40002111:	89 54 24 04          	mov    %edx,0x4(%esp)
40002115:	89 04 24             	mov    %eax,(%esp)
40002118:	e8 f9 f4 ff ff       	call   40001616 <fileino_write>
4000211d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (actual < 0) {
40002120:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002124:	79 17                	jns    4000213d <filedesc_write+0xdb>
		fd->err = errno;	// save error indication for ferror()
40002126:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000212b:	8b 10                	mov    (%eax),%edx
4000212d:	8b 45 08             	mov    0x8(%ebp),%eax
40002130:	89 50 0c             	mov    %edx,0xc(%eax)
		return -1;
40002133:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002138:	e9 98 00 00 00       	jmp    400021d5 <filedesc_write+0x173>
	}
	assert(actual == count);
4000213d:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002140:	3b 45 14             	cmp    0x14(%ebp),%eax
40002143:	74 24                	je     40002169 <filedesc_write+0x107>
40002145:	c7 44 24 0c 2b 41 00 	movl   $0x4000412b,0xc(%esp)
4000214c:	40 
4000214d:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40002154:	40 
40002155:	c7 44 24 04 5c 01 00 	movl   $0x15c,0x4(%esp)
4000215c:	00 
4000215d:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40002164:	e8 ef e3 ff ff       	call   40000558 <debug_panic>

	// Non-append-only writes constitute exclusive modifications,
	// so must bump the file's version number.
	if (!(fd->flags & O_APPEND))
40002169:	8b 45 08             	mov    0x8(%ebp),%eax
4000216c:	8b 40 04             	mov    0x4(%eax),%eax
4000216f:	83 e0 10             	and    $0x10,%eax
40002172:	85 c0                	test   %eax,%eax
40002174:	75 0f                	jne    40002185 <filedesc_write+0x123>
		fi->ver++;
40002176:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002179:	8b 40 44             	mov    0x44(%eax),%eax
4000217c:	8d 50 01             	lea    0x1(%eax),%edx
4000217f:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002182:	89 50 44             	mov    %edx,0x44(%eax)

	// Advance the file position
	fd->ofs += eltsize * count;
40002185:	8b 45 08             	mov    0x8(%ebp),%eax
40002188:	8b 40 08             	mov    0x8(%eax),%eax
4000218b:	89 c2                	mov    %eax,%edx
4000218d:	8b 45 10             	mov    0x10(%ebp),%eax
40002190:	0f af 45 14          	imul   0x14(%ebp),%eax
40002194:	01 d0                	add    %edx,%eax
40002196:	89 c2                	mov    %eax,%edx
40002198:	8b 45 08             	mov    0x8(%ebp),%eax
4000219b:	89 50 08             	mov    %edx,0x8(%eax)
	assert(fi->size >= fd->ofs);
4000219e:	8b 45 f4             	mov    -0xc(%ebp),%eax
400021a1:	8b 50 4c             	mov    0x4c(%eax),%edx
400021a4:	8b 45 08             	mov    0x8(%ebp),%eax
400021a7:	8b 40 08             	mov    0x8(%eax),%eax
400021aa:	39 c2                	cmp    %eax,%edx
400021ac:	73 24                	jae    400021d2 <filedesc_write+0x170>
400021ae:	c7 44 24 0c 3b 41 00 	movl   $0x4000413b,0xc(%esp)
400021b5:	40 
400021b6:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
400021bd:	40 
400021be:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
400021c5:	00 
400021c6:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
400021cd:	e8 86 e3 ff ff       	call   40000558 <debug_panic>
	return count;
400021d2:	8b 45 14             	mov    0x14(%ebp),%eax
}
400021d5:	c9                   	leave  
400021d6:	c3                   	ret    

400021d7 <filedesc_seek>:
// which may be relative to the file start, end, or corrent position,
// depending on 'whence' (SEEK_SET, SEEK_CUR, or SEEK_END).
// Returns the resulting absolute file position,
// or returns -1 and sets errno appropriately on error.
off_t filedesc_seek(filedesc *fd, off_t offset, int whence)
{
400021d7:	55                   	push   %ebp
400021d8:	89 e5                	mov    %esp,%ebp
400021da:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isopen(fd));
400021dd:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400021e2:	83 c0 10             	add    $0x10,%eax
400021e5:	3b 45 08             	cmp    0x8(%ebp),%eax
400021e8:	77 18                	ja     40002202 <filedesc_seek+0x2b>
400021ea:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400021ef:	05 10 10 00 00       	add    $0x1010,%eax
400021f4:	3b 45 08             	cmp    0x8(%ebp),%eax
400021f7:	76 09                	jbe    40002202 <filedesc_seek+0x2b>
400021f9:	8b 45 08             	mov    0x8(%ebp),%eax
400021fc:	8b 00                	mov    (%eax),%eax
400021fe:	85 c0                	test   %eax,%eax
40002200:	75 24                	jne    40002226 <filedesc_seek+0x4f>
40002202:	c7 44 24 0c c4 40 00 	movl   $0x400040c4,0xc(%esp)
40002209:	40 
4000220a:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40002211:	40 
40002212:	c7 44 24 04 70 01 00 	movl   $0x170,0x4(%esp)
40002219:	00 
4000221a:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40002221:	e8 32 e3 ff ff       	call   40000558 <debug_panic>
	assert(whence == SEEK_SET || whence == SEEK_CUR || whence == SEEK_END);
40002226:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
4000222a:	74 30                	je     4000225c <filedesc_seek+0x85>
4000222c:	83 7d 10 01          	cmpl   $0x1,0x10(%ebp)
40002230:	74 2a                	je     4000225c <filedesc_seek+0x85>
40002232:	83 7d 10 02          	cmpl   $0x2,0x10(%ebp)
40002236:	74 24                	je     4000225c <filedesc_seek+0x85>
40002238:	c7 44 24 0c 50 41 00 	movl   $0x40004150,0xc(%esp)
4000223f:	40 
40002240:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40002247:	40 
40002248:	c7 44 24 04 71 01 00 	movl   $0x171,0x4(%esp)
4000224f:	00 
40002250:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40002257:	e8 fc e2 ff ff       	call   40000558 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
4000225c:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40002262:	8b 45 08             	mov    0x8(%ebp),%eax
40002265:	8b 00                	mov    (%eax),%eax
40002267:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000226a:	05 10 10 00 00       	add    $0x1010,%eax
4000226f:	01 d0                	add    %edx,%eax
40002271:	89 45 f4             	mov    %eax,-0xc(%ebp)
	ino_t ino = fd->ino;
40002274:	8b 45 08             	mov    0x8(%ebp),%eax
40002277:	8b 00                	mov    (%eax),%eax
40002279:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint8_t* start_pos = FILEDATA(ino);
4000227c:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000227f:	c1 e0 16             	shl    $0x16,%eax
40002282:	05 00 00 00 80       	add    $0x80000000,%eax
40002287:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// Lab 4: insert your file descriptor seek implementation here.
	//warn("filedesc_seek() not implemented");
	//errno = EINVAL;
	//return -1;
	switch(whence){
4000228a:	8b 45 10             	mov    0x10(%ebp),%eax
4000228d:	83 f8 01             	cmp    $0x1,%eax
40002290:	74 14                	je     400022a6 <filedesc_seek+0xcf>
40002292:	83 f8 02             	cmp    $0x2,%eax
40002295:	74 22                	je     400022b9 <filedesc_seek+0xe2>
40002297:	85 c0                	test   %eax,%eax
40002299:	75 33                	jne    400022ce <filedesc_seek+0xf7>
	case SEEK_SET:
		fd->ofs = offset;
4000229b:	8b 45 08             	mov    0x8(%ebp),%eax
4000229e:	8b 55 0c             	mov    0xc(%ebp),%edx
400022a1:	89 50 08             	mov    %edx,0x8(%eax)
		break;
400022a4:	eb 3a                	jmp    400022e0 <filedesc_seek+0x109>
	case SEEK_CUR:
		fd->ofs += offset;
400022a6:	8b 45 08             	mov    0x8(%ebp),%eax
400022a9:	8b 50 08             	mov    0x8(%eax),%edx
400022ac:	8b 45 0c             	mov    0xc(%ebp),%eax
400022af:	01 c2                	add    %eax,%edx
400022b1:	8b 45 08             	mov    0x8(%ebp),%eax
400022b4:	89 50 08             	mov    %edx,0x8(%eax)
		break;
400022b7:	eb 27                	jmp    400022e0 <filedesc_seek+0x109>
	case SEEK_END:
		fd->ofs = (fi->size) + offset;
400022b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
400022bc:	8b 50 4c             	mov    0x4c(%eax),%edx
400022bf:	8b 45 0c             	mov    0xc(%ebp),%eax
400022c2:	01 d0                	add    %edx,%eax
400022c4:	89 c2                	mov    %eax,%edx
400022c6:	8b 45 08             	mov    0x8(%ebp),%eax
400022c9:	89 50 08             	mov    %edx,0x8(%eax)
		break;
400022cc:	eb 12                	jmp    400022e0 <filedesc_seek+0x109>
	default:
		errno = EINVAL;
400022ce:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400022d3:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
		return -1;
400022d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400022de:	eb 06                	jmp    400022e6 <filedesc_seek+0x10f>
	}
	return fd->ofs;
400022e0:	8b 45 08             	mov    0x8(%ebp),%eax
400022e3:	8b 40 08             	mov    0x8(%eax),%eax
}
400022e6:	c9                   	leave  
400022e7:	c3                   	ret    

400022e8 <filedesc_close>:

void
filedesc_close(filedesc *fd)
{
400022e8:	55                   	push   %ebp
400022e9:	89 e5                	mov    %esp,%ebp
400022eb:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
400022ee:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400022f3:	83 c0 10             	add    $0x10,%eax
400022f6:	3b 45 08             	cmp    0x8(%ebp),%eax
400022f9:	77 18                	ja     40002313 <filedesc_close+0x2b>
400022fb:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002300:	05 10 10 00 00       	add    $0x1010,%eax
40002305:	3b 45 08             	cmp    0x8(%ebp),%eax
40002308:	76 09                	jbe    40002313 <filedesc_close+0x2b>
4000230a:	8b 45 08             	mov    0x8(%ebp),%eax
4000230d:	8b 00                	mov    (%eax),%eax
4000230f:	85 c0                	test   %eax,%eax
40002311:	75 24                	jne    40002337 <filedesc_close+0x4f>
40002313:	c7 44 24 0c c4 40 00 	movl   $0x400040c4,0xc(%esp)
4000231a:	40 
4000231b:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
40002322:	40 
40002323:	c7 44 24 04 8e 01 00 	movl   $0x18e,0x4(%esp)
4000232a:	00 
4000232b:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
40002332:	e8 21 e2 ff ff       	call   40000558 <debug_panic>
	assert(fileino_isvalid(fd->ino));
40002337:	8b 45 08             	mov    0x8(%ebp),%eax
4000233a:	8b 00                	mov    (%eax),%eax
4000233c:	85 c0                	test   %eax,%eax
4000233e:	7e 0c                	jle    4000234c <filedesc_close+0x64>
40002340:	8b 45 08             	mov    0x8(%ebp),%eax
40002343:	8b 00                	mov    (%eax),%eax
40002345:	3d ff 00 00 00       	cmp    $0xff,%eax
4000234a:	7e 24                	jle    40002370 <filedesc_close+0x88>
4000234c:	c7 44 24 0c 8f 41 00 	movl   $0x4000418f,0xc(%esp)
40002353:	40 
40002354:	c7 44 24 08 64 3f 00 	movl   $0x40003f64,0x8(%esp)
4000235b:	40 
4000235c:	c7 44 24 04 8f 01 00 	movl   $0x18f,0x4(%esp)
40002363:	00 
40002364:	c7 04 24 4f 3f 00 40 	movl   $0x40003f4f,(%esp)
4000236b:	e8 e8 e1 ff ff       	call   40000558 <debug_panic>

	fd->ino = FILEINO_NULL;		// mark the fd free
40002370:	8b 45 08             	mov    0x8(%ebp),%eax
40002373:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
40002379:	c9                   	leave  
4000237a:	c3                   	ret    
4000237b:	90                   	nop

4000237c <dir_walk>:
#include <inc/dirent.h>


int
dir_walk(const char *path, mode_t createmode)
{
4000237c:	55                   	push   %ebp
4000237d:	89 e5                	mov    %esp,%ebp
4000237f:	83 ec 28             	sub    $0x28,%esp
	assert(path != 0 && *path != 0);
40002382:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40002386:	74 0a                	je     40002392 <dir_walk+0x16>
40002388:	8b 45 08             	mov    0x8(%ebp),%eax
4000238b:	0f b6 00             	movzbl (%eax),%eax
4000238e:	84 c0                	test   %al,%al
40002390:	75 24                	jne    400023b6 <dir_walk+0x3a>
40002392:	c7 44 24 0c a8 41 00 	movl   $0x400041a8,0xc(%esp)
40002399:	40 
4000239a:	c7 44 24 08 c0 41 00 	movl   $0x400041c0,0x8(%esp)
400023a1:	40 
400023a2:	c7 44 24 04 15 00 00 	movl   $0x15,0x4(%esp)
400023a9:	00 
400023aa:	c7 04 24 d5 41 00 40 	movl   $0x400041d5,(%esp)
400023b1:	e8 a2 e1 ff ff       	call   40000558 <debug_panic>

	// Start at the current or root directory as appropriate
	int dino = files->cwd;
400023b6:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400023bb:	8b 40 04             	mov    0x4(%eax),%eax
400023be:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (*path == '/') {
400023c1:	8b 45 08             	mov    0x8(%ebp),%eax
400023c4:	0f b6 00             	movzbl (%eax),%eax
400023c7:	3c 2f                	cmp    $0x2f,%al
400023c9:	75 27                	jne    400023f2 <dir_walk+0x76>
		dino = FILEINO_ROOTDIR;
400023cb:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
		do { path++; } while (*path == '/');	// skip leading slashes
400023d2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400023d6:	8b 45 08             	mov    0x8(%ebp),%eax
400023d9:	0f b6 00             	movzbl (%eax),%eax
400023dc:	3c 2f                	cmp    $0x2f,%al
400023de:	74 f2                	je     400023d2 <dir_walk+0x56>
		if (*path == 0)
400023e0:	8b 45 08             	mov    0x8(%ebp),%eax
400023e3:	0f b6 00             	movzbl (%eax),%eax
400023e6:	84 c0                	test   %al,%al
400023e8:	75 08                	jne    400023f2 <dir_walk+0x76>
			return dino;	// Just looking up root directory
400023ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
400023ed:	e9 61 05 00 00       	jmp    40002953 <dir_walk+0x5d7>
	}

	// Search for the appropriate entry in this directory
	searchdir:
	assert(fileino_isdir(dino));
400023f2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
400023f6:	7e 45                	jle    4000243d <dir_walk+0xc1>
400023f8:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
400023ff:	7f 3c                	jg     4000243d <dir_walk+0xc1>
40002401:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40002407:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000240a:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000240d:	01 d0                	add    %edx,%eax
4000240f:	05 10 10 00 00       	add    $0x1010,%eax
40002414:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002418:	84 c0                	test   %al,%al
4000241a:	74 21                	je     4000243d <dir_walk+0xc1>
4000241c:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40002422:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002425:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002428:	01 d0                	add    %edx,%eax
4000242a:	05 58 10 00 00       	add    $0x1058,%eax
4000242f:	8b 00                	mov    (%eax),%eax
40002431:	25 00 70 00 00       	and    $0x7000,%eax
40002436:	3d 00 20 00 00       	cmp    $0x2000,%eax
4000243b:	74 24                	je     40002461 <dir_walk+0xe5>
4000243d:	c7 44 24 0c df 41 00 	movl   $0x400041df,0xc(%esp)
40002444:	40 
40002445:	c7 44 24 08 c0 41 00 	movl   $0x400041c0,0x8(%esp)
4000244c:	40 
4000244d:	c7 44 24 04 22 00 00 	movl   $0x22,0x4(%esp)
40002454:	00 
40002455:	c7 04 24 d5 41 00 40 	movl   $0x400041d5,(%esp)
4000245c:	e8 f7 e0 ff ff       	call   40000558 <debug_panic>
	assert(fileino_isdir(files->fi[dino].dino));
40002461:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40002467:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000246a:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000246d:	01 d0                	add    %edx,%eax
4000246f:	05 10 10 00 00       	add    $0x1010,%eax
40002474:	8b 00                	mov    (%eax),%eax
40002476:	85 c0                	test   %eax,%eax
40002478:	7e 7c                	jle    400024f6 <dir_walk+0x17a>
4000247a:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40002480:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002483:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002486:	01 d0                	add    %edx,%eax
40002488:	05 10 10 00 00       	add    $0x1010,%eax
4000248d:	8b 00                	mov    (%eax),%eax
4000248f:	3d ff 00 00 00       	cmp    $0xff,%eax
40002494:	7f 60                	jg     400024f6 <dir_walk+0x17a>
40002496:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
4000249c:	8b 0d 2c 3f 00 40    	mov    0x40003f2c,%ecx
400024a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
400024a5:	6b c0 5c             	imul   $0x5c,%eax,%eax
400024a8:	01 c8                	add    %ecx,%eax
400024aa:	05 10 10 00 00       	add    $0x1010,%eax
400024af:	8b 00                	mov    (%eax),%eax
400024b1:	6b c0 5c             	imul   $0x5c,%eax,%eax
400024b4:	01 d0                	add    %edx,%eax
400024b6:	05 10 10 00 00       	add    $0x1010,%eax
400024bb:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400024bf:	84 c0                	test   %al,%al
400024c1:	74 33                	je     400024f6 <dir_walk+0x17a>
400024c3:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
400024c9:	8b 0d 2c 3f 00 40    	mov    0x40003f2c,%ecx
400024cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
400024d2:	6b c0 5c             	imul   $0x5c,%eax,%eax
400024d5:	01 c8                	add    %ecx,%eax
400024d7:	05 10 10 00 00       	add    $0x1010,%eax
400024dc:	8b 00                	mov    (%eax),%eax
400024de:	6b c0 5c             	imul   $0x5c,%eax,%eax
400024e1:	01 d0                	add    %edx,%eax
400024e3:	05 58 10 00 00       	add    $0x1058,%eax
400024e8:	8b 00                	mov    (%eax),%eax
400024ea:	25 00 70 00 00       	and    $0x7000,%eax
400024ef:	3d 00 20 00 00       	cmp    $0x2000,%eax
400024f4:	74 24                	je     4000251a <dir_walk+0x19e>
400024f6:	c7 44 24 0c f4 41 00 	movl   $0x400041f4,0xc(%esp)
400024fd:	40 
400024fe:	c7 44 24 08 c0 41 00 	movl   $0x400041c0,0x8(%esp)
40002505:	40 
40002506:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
4000250d:	00 
4000250e:	c7 04 24 d5 41 00 40 	movl   $0x400041d5,(%esp)
40002515:	e8 3e e0 ff ff       	call   40000558 <debug_panic>

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
4000251a:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
40002521:	e9 3d 02 00 00       	jmp    40002763 <dir_walk+0x3e7>
		if (!fileino_alloced(ino) || files->fi[ino].dino != dino)
40002526:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
4000252a:	0f 8e 28 02 00 00    	jle    40002758 <dir_walk+0x3dc>
40002530:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40002537:	0f 8f 1b 02 00 00    	jg     40002758 <dir_walk+0x3dc>
4000253d:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40002543:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002546:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002549:	01 d0                	add    %edx,%eax
4000254b:	05 10 10 00 00       	add    $0x1010,%eax
40002550:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002554:	84 c0                	test   %al,%al
40002556:	0f 84 fc 01 00 00    	je     40002758 <dir_walk+0x3dc>
4000255c:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40002562:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002565:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002568:	01 d0                	add    %edx,%eax
4000256a:	05 10 10 00 00       	add    $0x1010,%eax
4000256f:	8b 00                	mov    (%eax),%eax
40002571:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40002574:	0f 85 de 01 00 00    	jne    40002758 <dir_walk+0x3dc>
			continue;	// not an entry in directory 'dino'

		// Does this inode's name match our next path component?
		len = strlen(files->fi[ino].de.d_name);
4000257a:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000257f:	8b 55 f0             	mov    -0x10(%ebp),%edx
40002582:	6b d2 5c             	imul   $0x5c,%edx,%edx
40002585:	81 c2 10 10 00 00    	add    $0x1010,%edx
4000258b:	01 d0                	add    %edx,%eax
4000258d:	83 c0 04             	add    $0x4,%eax
40002590:	89 04 24             	mov    %eax,(%esp)
40002593:	e8 34 e9 ff ff       	call   40000ecc <strlen>
40002598:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (memcmp(path, files->fi[ino].de.d_name, len) != 0)
4000259b:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000259e:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
400025a4:	8b 4d f0             	mov    -0x10(%ebp),%ecx
400025a7:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
400025aa:	81 c1 10 10 00 00    	add    $0x1010,%ecx
400025b0:	01 ca                	add    %ecx,%edx
400025b2:	83 c2 04             	add    $0x4,%edx
400025b5:	89 44 24 08          	mov    %eax,0x8(%esp)
400025b9:	89 54 24 04          	mov    %edx,0x4(%esp)
400025bd:	8b 45 08             	mov    0x8(%ebp),%eax
400025c0:	89 04 24             	mov    %eax,(%esp)
400025c3:	e8 2a ec ff ff       	call   400011f2 <memcmp>
400025c8:	85 c0                	test   %eax,%eax
400025ca:	0f 85 8b 01 00 00    	jne    4000275b <dir_walk+0x3df>
			continue;	// no match
		found:
		if (path[len] == 0) {
400025d0:	8b 55 ec             	mov    -0x14(%ebp),%edx
400025d3:	8b 45 08             	mov    0x8(%ebp),%eax
400025d6:	01 d0                	add    %edx,%eax
400025d8:	0f b6 00             	movzbl (%eax),%eax
400025db:	84 c0                	test   %al,%al
400025dd:	0f 85 c7 00 00 00    	jne    400026aa <dir_walk+0x32e>
			// Exact match at end of path - but does it exist?
			if (fileino_exists(ino))
400025e3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400025e7:	7e 45                	jle    4000262e <dir_walk+0x2b2>
400025e9:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
400025f0:	7f 3c                	jg     4000262e <dir_walk+0x2b2>
400025f2:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
400025f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
400025fb:	6b c0 5c             	imul   $0x5c,%eax,%eax
400025fe:	01 d0                	add    %edx,%eax
40002600:	05 10 10 00 00       	add    $0x1010,%eax
40002605:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002609:	84 c0                	test   %al,%al
4000260b:	74 21                	je     4000262e <dir_walk+0x2b2>
4000260d:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40002613:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002616:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002619:	01 d0                	add    %edx,%eax
4000261b:	05 58 10 00 00       	add    $0x1058,%eax
40002620:	8b 00                	mov    (%eax),%eax
40002622:	85 c0                	test   %eax,%eax
40002624:	74 08                	je     4000262e <dir_walk+0x2b2>
				return ino;	// yes - return it
40002626:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002629:	e9 25 03 00 00       	jmp    40002953 <dir_walk+0x5d7>

			// no - existed, but was deleted.  re-create?
			if (!createmode) {
4000262e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40002632:	75 15                	jne    40002649 <dir_walk+0x2cd>
				errno = ENOENT;
40002634:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002639:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
				return -1;
4000263f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002644:	e9 0a 03 00 00       	jmp    40002953 <dir_walk+0x5d7>
			}
			files->fi[ino].ver++;	// an exclusive change
40002649:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000264e:	8b 55 f0             	mov    -0x10(%ebp),%edx
40002651:	6b d2 5c             	imul   $0x5c,%edx,%edx
40002654:	01 c2                	add    %eax,%edx
40002656:	81 c2 54 10 00 00    	add    $0x1054,%edx
4000265c:	8b 12                	mov    (%edx),%edx
4000265e:	83 c2 01             	add    $0x1,%edx
40002661:	8b 4d f0             	mov    -0x10(%ebp),%ecx
40002664:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
40002667:	01 c8                	add    %ecx,%eax
40002669:	05 54 10 00 00       	add    $0x1054,%eax
4000266e:	89 10                	mov    %edx,(%eax)
			files->fi[ino].mode = createmode;
40002670:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40002676:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002679:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000267c:	01 d0                	add    %edx,%eax
4000267e:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
40002684:	8b 45 0c             	mov    0xc(%ebp),%eax
40002687:	89 02                	mov    %eax,(%edx)
			files->fi[ino].size = 0;
40002689:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
4000268f:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002692:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002695:	01 d0                	add    %edx,%eax
40002697:	05 5c 10 00 00       	add    $0x105c,%eax
4000269c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			return ino;
400026a2:	8b 45 f0             	mov    -0x10(%ebp),%eax
400026a5:	e9 a9 02 00 00       	jmp    40002953 <dir_walk+0x5d7>
		}
		if (path[len] != '/')
400026aa:	8b 55 ec             	mov    -0x14(%ebp),%edx
400026ad:	8b 45 08             	mov    0x8(%ebp),%eax
400026b0:	01 d0                	add    %edx,%eax
400026b2:	0f b6 00             	movzbl (%eax),%eax
400026b5:	3c 2f                	cmp    $0x2f,%al
400026b7:	0f 85 a1 00 00 00    	jne    4000275e <dir_walk+0x3e2>
			continue;	// no match

		// Make sure this dirent refers to a directory
		if (!fileino_isdir(ino)) {
400026bd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400026c1:	7e 45                	jle    40002708 <dir_walk+0x38c>
400026c3:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
400026ca:	7f 3c                	jg     40002708 <dir_walk+0x38c>
400026cc:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
400026d2:	8b 45 f0             	mov    -0x10(%ebp),%eax
400026d5:	6b c0 5c             	imul   $0x5c,%eax,%eax
400026d8:	01 d0                	add    %edx,%eax
400026da:	05 10 10 00 00       	add    $0x1010,%eax
400026df:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400026e3:	84 c0                	test   %al,%al
400026e5:	74 21                	je     40002708 <dir_walk+0x38c>
400026e7:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
400026ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
400026f0:	6b c0 5c             	imul   $0x5c,%eax,%eax
400026f3:	01 d0                	add    %edx,%eax
400026f5:	05 58 10 00 00       	add    $0x1058,%eax
400026fa:	8b 00                	mov    (%eax),%eax
400026fc:	25 00 70 00 00       	and    $0x7000,%eax
40002701:	3d 00 20 00 00       	cmp    $0x2000,%eax
40002706:	74 15                	je     4000271d <dir_walk+0x3a1>
			errno = ENOTDIR;
40002708:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000270d:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
			return -1;
40002713:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002718:	e9 36 02 00 00       	jmp    40002953 <dir_walk+0x5d7>
		}

		// Skip slashes to find next component
		do { len++; } while (path[len] == '/');
4000271d:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
40002721:	8b 55 ec             	mov    -0x14(%ebp),%edx
40002724:	8b 45 08             	mov    0x8(%ebp),%eax
40002727:	01 d0                	add    %edx,%eax
40002729:	0f b6 00             	movzbl (%eax),%eax
4000272c:	3c 2f                	cmp    $0x2f,%al
4000272e:	74 ed                	je     4000271d <dir_walk+0x3a1>
		if (path[len] == 0)
40002730:	8b 55 ec             	mov    -0x14(%ebp),%edx
40002733:	8b 45 08             	mov    0x8(%ebp),%eax
40002736:	01 d0                	add    %edx,%eax
40002738:	0f b6 00             	movzbl (%eax),%eax
4000273b:	84 c0                	test   %al,%al
4000273d:	75 08                	jne    40002747 <dir_walk+0x3cb>
			return ino;	// matched directory at end of path
4000273f:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002742:	e9 0c 02 00 00       	jmp    40002953 <dir_walk+0x5d7>

		// Walk the next directory in the path
		dino = ino;
40002747:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000274a:	89 45 f4             	mov    %eax,-0xc(%ebp)
		path += len;
4000274d:	8b 45 ec             	mov    -0x14(%ebp),%eax
40002750:	01 45 08             	add    %eax,0x8(%ebp)
		goto searchdir;
40002753:	e9 9a fc ff ff       	jmp    400023f2 <dir_walk+0x76>

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
		if (!fileino_alloced(ino) || files->fi[ino].dino != dino)
			continue;	// not an entry in directory 'dino'
40002758:	90                   	nop
40002759:	eb 04                	jmp    4000275f <dir_walk+0x3e3>

		// Does this inode's name match our next path component?
		len = strlen(files->fi[ino].de.d_name);
		if (memcmp(path, files->fi[ino].de.d_name, len) != 0)
			continue;	// no match
4000275b:	90                   	nop
4000275c:	eb 01                	jmp    4000275f <dir_walk+0x3e3>
			files->fi[ino].mode = createmode;
			files->fi[ino].size = 0;
			return ino;
		}
		if (path[len] != '/')
			continue;	// no match
4000275e:	90                   	nop
	assert(fileino_isdir(dino));
	assert(fileino_isdir(files->fi[dino].dino));

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
4000275f:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
40002763:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
4000276a:	0f 8e b6 fd ff ff    	jle    40002526 <dir_walk+0x1aa>
		path += len;
		goto searchdir;
	}

	// Looking for one of the special entries '.' or '..'?
	if (path[0] == '.' && (path[1] == 0 || path[1] == '/')) {
40002770:	8b 45 08             	mov    0x8(%ebp),%eax
40002773:	0f b6 00             	movzbl (%eax),%eax
40002776:	3c 2e                	cmp    $0x2e,%al
40002778:	75 2c                	jne    400027a6 <dir_walk+0x42a>
4000277a:	8b 45 08             	mov    0x8(%ebp),%eax
4000277d:	83 c0 01             	add    $0x1,%eax
40002780:	0f b6 00             	movzbl (%eax),%eax
40002783:	84 c0                	test   %al,%al
40002785:	74 0d                	je     40002794 <dir_walk+0x418>
40002787:	8b 45 08             	mov    0x8(%ebp),%eax
4000278a:	83 c0 01             	add    $0x1,%eax
4000278d:	0f b6 00             	movzbl (%eax),%eax
40002790:	3c 2f                	cmp    $0x2f,%al
40002792:	75 12                	jne    400027a6 <dir_walk+0x42a>
		len = 1;
40002794:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		ino = dino;	// just leads to this same directory
4000279b:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000279e:	89 45 f0             	mov    %eax,-0x10(%ebp)
		goto found;
400027a1:	e9 2a fe ff ff       	jmp    400025d0 <dir_walk+0x254>
	}
	if (path[0] == '.' && path[1] == '.'
400027a6:	8b 45 08             	mov    0x8(%ebp),%eax
400027a9:	0f b6 00             	movzbl (%eax),%eax
400027ac:	3c 2e                	cmp    $0x2e,%al
400027ae:	75 4b                	jne    400027fb <dir_walk+0x47f>
400027b0:	8b 45 08             	mov    0x8(%ebp),%eax
400027b3:	83 c0 01             	add    $0x1,%eax
400027b6:	0f b6 00             	movzbl (%eax),%eax
400027b9:	3c 2e                	cmp    $0x2e,%al
400027bb:	75 3e                	jne    400027fb <dir_walk+0x47f>
			&& (path[2] == 0 || path[2] == '/')) {
400027bd:	8b 45 08             	mov    0x8(%ebp),%eax
400027c0:	83 c0 02             	add    $0x2,%eax
400027c3:	0f b6 00             	movzbl (%eax),%eax
400027c6:	84 c0                	test   %al,%al
400027c8:	74 0d                	je     400027d7 <dir_walk+0x45b>
400027ca:	8b 45 08             	mov    0x8(%ebp),%eax
400027cd:	83 c0 02             	add    $0x2,%eax
400027d0:	0f b6 00             	movzbl (%eax),%eax
400027d3:	3c 2f                	cmp    $0x2f,%al
400027d5:	75 24                	jne    400027fb <dir_walk+0x47f>
		len = 2;
400027d7:	c7 45 ec 02 00 00 00 	movl   $0x2,-0x14(%ebp)
		ino = files->fi[dino].dino;	// leads to root directory
400027de:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
400027e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
400027e7:	6b c0 5c             	imul   $0x5c,%eax,%eax
400027ea:	01 d0                	add    %edx,%eax
400027ec:	05 10 10 00 00       	add    $0x1010,%eax
400027f1:	8b 00                	mov    (%eax),%eax
400027f3:	89 45 f0             	mov    %eax,-0x10(%ebp)
		goto found;
400027f6:	e9 d5 fd ff ff       	jmp    400025d0 <dir_walk+0x254>
	}

	// Path component not found - see if we should create it
	if (!createmode || strchr(path, '/') != NULL) {
400027fb:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400027ff:	74 17                	je     40002818 <dir_walk+0x49c>
40002801:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
40002808:	00 
40002809:	8b 45 08             	mov    0x8(%ebp),%eax
4000280c:	89 04 24             	mov    %eax,(%esp)
4000280f:	e8 3d e8 ff ff       	call   40001051 <strchr>
40002814:	85 c0                	test   %eax,%eax
40002816:	74 15                	je     4000282d <dir_walk+0x4b1>
		errno = ENOENT;
40002818:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000281d:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
		return -1;
40002823:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002828:	e9 26 01 00 00       	jmp    40002953 <dir_walk+0x5d7>
	}
	if (strlen(path) > NAME_MAX) {
4000282d:	8b 45 08             	mov    0x8(%ebp),%eax
40002830:	89 04 24             	mov    %eax,(%esp)
40002833:	e8 94 e6 ff ff       	call   40000ecc <strlen>
40002838:	83 f8 3f             	cmp    $0x3f,%eax
4000283b:	7e 15                	jle    40002852 <dir_walk+0x4d6>
		errno = ENAMETOOLONG;
4000283d:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002842:	c7 00 06 00 00 00    	movl   $0x6,(%eax)
		return -1;
40002848:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
4000284d:	e9 01 01 00 00       	jmp    40002953 <dir_walk+0x5d7>
	}

	// Allocate a new inode and create this entry with the given mode.
	ino = fileino_alloc();
40002852:	e8 31 ea ff ff       	call   40001288 <fileino_alloc>
40002857:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (ino < 0)
4000285a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
4000285e:	79 0a                	jns    4000286a <dir_walk+0x4ee>
		return -1;
40002860:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002865:	e9 e9 00 00 00       	jmp    40002953 <dir_walk+0x5d7>
	assert(fileino_isvalid(ino) && !fileino_alloced(ino));
4000286a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
4000286e:	7e 33                	jle    400028a3 <dir_walk+0x527>
40002870:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40002877:	7f 2a                	jg     400028a3 <dir_walk+0x527>
40002879:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
4000287d:	7e 48                	jle    400028c7 <dir_walk+0x54b>
4000287f:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40002886:	7f 3f                	jg     400028c7 <dir_walk+0x54b>
40002888:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
4000288e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002891:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002894:	01 d0                	add    %edx,%eax
40002896:	05 10 10 00 00       	add    $0x1010,%eax
4000289b:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000289f:	84 c0                	test   %al,%al
400028a1:	74 24                	je     400028c7 <dir_walk+0x54b>
400028a3:	c7 44 24 0c 18 42 00 	movl   $0x40004218,0xc(%esp)
400028aa:	40 
400028ab:	c7 44 24 08 c0 41 00 	movl   $0x400041c0,0x8(%esp)
400028b2:	40 
400028b3:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
400028ba:	00 
400028bb:	c7 04 24 d5 41 00 40 	movl   $0x400041d5,(%esp)
400028c2:	e8 91 dc ff ff       	call   40000558 <debug_panic>
	strcpy(files->fi[ino].de.d_name, path);
400028c7:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400028cc:	8b 55 f0             	mov    -0x10(%ebp),%edx
400028cf:	6b d2 5c             	imul   $0x5c,%edx,%edx
400028d2:	81 c2 10 10 00 00    	add    $0x1010,%edx
400028d8:	01 d0                	add    %edx,%eax
400028da:	8d 50 04             	lea    0x4(%eax),%edx
400028dd:	8b 45 08             	mov    0x8(%ebp),%eax
400028e0:	89 44 24 04          	mov    %eax,0x4(%esp)
400028e4:	89 14 24             	mov    %edx,(%esp)
400028e7:	e8 06 e6 ff ff       	call   40000ef2 <strcpy>
	files->fi[ino].dino = dino;
400028ec:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
400028f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
400028f5:	6b c0 5c             	imul   $0x5c,%eax,%eax
400028f8:	01 d0                	add    %edx,%eax
400028fa:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40002900:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002903:	89 02                	mov    %eax,(%edx)
	files->fi[ino].ver = 0;
40002905:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
4000290b:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000290e:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002911:	01 d0                	add    %edx,%eax
40002913:	05 54 10 00 00       	add    $0x1054,%eax
40002918:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	files->fi[ino].mode = createmode;
4000291e:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40002924:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002927:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000292a:	01 d0                	add    %edx,%eax
4000292c:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
40002932:	8b 45 0c             	mov    0xc(%ebp),%eax
40002935:	89 02                	mov    %eax,(%edx)
	files->fi[ino].size = 0;
40002937:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
4000293d:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002940:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002943:	01 d0                	add    %edx,%eax
40002945:	05 5c 10 00 00       	add    $0x105c,%eax
4000294a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return ino;
40002950:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40002953:	c9                   	leave  
40002954:	c3                   	ret    

40002955 <opendir>:
// Open a directory for scanning.
// For simplicity, DIR is simply a filedesc like other file descriptors,
// except we interpret fd->ofs as an inode number for scanning,
// instead of as a byte offset as in a regular file.
DIR *opendir(const char *path)
{
40002955:	55                   	push   %ebp
40002956:	89 e5                	mov    %esp,%ebp
40002958:	83 ec 28             	sub    $0x28,%esp
	filedesc *fd = filedesc_open(NULL, path, O_RDONLY, 0);
4000295b:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
40002962:	00 
40002963:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
4000296a:	00 
4000296b:	8b 45 08             	mov    0x8(%ebp),%eax
4000296e:	89 44 24 04          	mov    %eax,0x4(%esp)
40002972:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002979:	e8 a5 f3 ff ff       	call   40001d23 <filedesc_open>
4000297e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (fd == NULL)
40002981:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002985:	75 0a                	jne    40002991 <opendir+0x3c>
		return NULL;
40002987:	b8 00 00 00 00       	mov    $0x0,%eax
4000298c:	e9 bb 00 00 00       	jmp    40002a4c <opendir+0xf7>

	// Make sure it's a directory
	assert(fileino_exists(fd->ino));
40002991:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002994:	8b 00                	mov    (%eax),%eax
40002996:	85 c0                	test   %eax,%eax
40002998:	7e 44                	jle    400029de <opendir+0x89>
4000299a:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000299d:	8b 00                	mov    (%eax),%eax
4000299f:	3d ff 00 00 00       	cmp    $0xff,%eax
400029a4:	7f 38                	jg     400029de <opendir+0x89>
400029a6:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
400029ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
400029af:	8b 00                	mov    (%eax),%eax
400029b1:	6b c0 5c             	imul   $0x5c,%eax,%eax
400029b4:	01 d0                	add    %edx,%eax
400029b6:	05 10 10 00 00       	add    $0x1010,%eax
400029bb:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400029bf:	84 c0                	test   %al,%al
400029c1:	74 1b                	je     400029de <opendir+0x89>
400029c3:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
400029c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
400029cc:	8b 00                	mov    (%eax),%eax
400029ce:	6b c0 5c             	imul   $0x5c,%eax,%eax
400029d1:	01 d0                	add    %edx,%eax
400029d3:	05 58 10 00 00       	add    $0x1058,%eax
400029d8:	8b 00                	mov    (%eax),%eax
400029da:	85 c0                	test   %eax,%eax
400029dc:	75 24                	jne    40002a02 <opendir+0xad>
400029de:	c7 44 24 0c 46 42 00 	movl   $0x40004246,0xc(%esp)
400029e5:	40 
400029e6:	c7 44 24 08 c0 41 00 	movl   $0x400041c0,0x8(%esp)
400029ed:	40 
400029ee:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
400029f5:	00 
400029f6:	c7 04 24 d5 41 00 40 	movl   $0x400041d5,(%esp)
400029fd:	e8 56 db ff ff       	call   40000558 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40002a02:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40002a08:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002a0b:	8b 00                	mov    (%eax),%eax
40002a0d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002a10:	05 10 10 00 00       	add    $0x1010,%eax
40002a15:	01 d0                	add    %edx,%eax
40002a17:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (!S_ISDIR(fi->mode)) {
40002a1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002a1d:	8b 40 48             	mov    0x48(%eax),%eax
40002a20:	25 00 70 00 00       	and    $0x7000,%eax
40002a25:	3d 00 20 00 00       	cmp    $0x2000,%eax
40002a2a:	74 1d                	je     40002a49 <opendir+0xf4>
		filedesc_close(fd);
40002a2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002a2f:	89 04 24             	mov    %eax,(%esp)
40002a32:	e8 b1 f8 ff ff       	call   400022e8 <filedesc_close>
		errno = ENOTDIR;
40002a37:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002a3c:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
		return NULL;
40002a42:	b8 00 00 00 00       	mov    $0x0,%eax
40002a47:	eb 03                	jmp    40002a4c <opendir+0xf7>
	}

	return fd;
40002a49:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
40002a4c:	c9                   	leave  
40002a4d:	c3                   	ret    

40002a4e <closedir>:

int closedir(DIR *dir)
{
40002a4e:	55                   	push   %ebp
40002a4f:	89 e5                	mov    %esp,%ebp
40002a51:	83 ec 18             	sub    $0x18,%esp
	filedesc_close(dir);
40002a54:	8b 45 08             	mov    0x8(%ebp),%eax
40002a57:	89 04 24             	mov    %eax,(%esp)
40002a5a:	e8 89 f8 ff ff       	call   400022e8 <filedesc_close>
	return 0;
40002a5f:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002a64:	c9                   	leave  
40002a65:	c3                   	ret    

40002a66 <readdir>:

// Scan an open directory filedesc and return the next entry.
// Returns a pointer to the next matching file inode's 'dirent' struct,
// or NULL if the directory being scanned contains no more entries.
struct dirent *readdir(DIR *dir)
{
40002a66:	55                   	push   %ebp
40002a67:	89 e5                	mov    %esp,%ebp
40002a69:	83 ec 28             	sub    $0x28,%esp
	// Hint: a fileinode's 'dino' field indicates
	// what directory the file is in;
	// this function shouldn't return entries from other directories!
	//warn("readdir() not implemented");
	//return NULL;
	assert(fileino_isdir(dir->ino));
40002a6c:	8b 45 08             	mov    0x8(%ebp),%eax
40002a6f:	8b 00                	mov    (%eax),%eax
40002a71:	85 c0                	test   %eax,%eax
40002a73:	7e 4c                	jle    40002ac1 <readdir+0x5b>
40002a75:	8b 45 08             	mov    0x8(%ebp),%eax
40002a78:	8b 00                	mov    (%eax),%eax
40002a7a:	3d ff 00 00 00       	cmp    $0xff,%eax
40002a7f:	7f 40                	jg     40002ac1 <readdir+0x5b>
40002a81:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40002a87:	8b 45 08             	mov    0x8(%ebp),%eax
40002a8a:	8b 00                	mov    (%eax),%eax
40002a8c:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002a8f:	01 d0                	add    %edx,%eax
40002a91:	05 10 10 00 00       	add    $0x1010,%eax
40002a96:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40002a9a:	84 c0                	test   %al,%al
40002a9c:	74 23                	je     40002ac1 <readdir+0x5b>
40002a9e:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40002aa4:	8b 45 08             	mov    0x8(%ebp),%eax
40002aa7:	8b 00                	mov    (%eax),%eax
40002aa9:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002aac:	01 d0                	add    %edx,%eax
40002aae:	05 58 10 00 00       	add    $0x1058,%eax
40002ab3:	8b 00                	mov    (%eax),%eax
40002ab5:	25 00 70 00 00       	and    $0x7000,%eax
40002aba:	3d 00 20 00 00       	cmp    $0x2000,%eax
40002abf:	74 24                	je     40002ae5 <readdir+0x7f>
40002ac1:	c7 44 24 0c 5e 42 00 	movl   $0x4000425e,0xc(%esp)
40002ac8:	40 
40002ac9:	c7 44 24 08 c0 41 00 	movl   $0x400041c0,0x8(%esp)
40002ad0:	40 
40002ad1:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
40002ad8:	00 
40002ad9:	c7 04 24 d5 41 00 40 	movl   $0x400041d5,(%esp)
40002ae0:	e8 73 da ff ff       	call   40000558 <debug_panic>
	int i = dir->ofs;
40002ae5:	8b 45 08             	mov    0x8(%ebp),%eax
40002ae8:	8b 40 08             	mov    0x8(%eax),%eax
40002aeb:	89 45 f4             	mov    %eax,-0xc(%ebp)
	for(i; i < FILE_INODES; i++){
40002aee:	eb 3c                	jmp    40002b2c <readdir+0xc6>
		fileinode* tmp_fi = &files->fi[i];
40002af0:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002af5:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002af8:	6b d2 5c             	imul   $0x5c,%edx,%edx
40002afb:	81 c2 10 10 00 00    	add    $0x1010,%edx
40002b01:	01 d0                	add    %edx,%eax
40002b03:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if(tmp_fi->dino == dir->ino){
40002b06:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002b09:	8b 10                	mov    (%eax),%edx
40002b0b:	8b 45 08             	mov    0x8(%ebp),%eax
40002b0e:	8b 00                	mov    (%eax),%eax
40002b10:	39 c2                	cmp    %eax,%edx
40002b12:	75 14                	jne    40002b28 <readdir+0xc2>
			dir->ofs = i+1;
40002b14:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002b17:	8d 50 01             	lea    0x1(%eax),%edx
40002b1a:	8b 45 08             	mov    0x8(%ebp),%eax
40002b1d:	89 50 08             	mov    %edx,0x8(%eax)
			return &tmp_fi->de;
40002b20:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002b23:	83 c0 04             	add    $0x4,%eax
40002b26:	eb 1c                	jmp    40002b44 <readdir+0xde>
	// this function shouldn't return entries from other directories!
	//warn("readdir() not implemented");
	//return NULL;
	assert(fileino_isdir(dir->ino));
	int i = dir->ofs;
	for(i; i < FILE_INODES; i++){
40002b28:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40002b2c:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
40002b33:	7e bb                	jle    40002af0 <readdir+0x8a>
		if(tmp_fi->dino == dir->ino){
			dir->ofs = i+1;
			return &tmp_fi->de;
		}
	}
	dir->ofs = 0;
40002b35:	8b 45 08             	mov    0x8(%ebp),%eax
40002b38:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
	return NULL;
40002b3f:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002b44:	c9                   	leave  
40002b45:	c3                   	ret    

40002b46 <rewinddir>:

void rewinddir(DIR *dir)
{
40002b46:	55                   	push   %ebp
40002b47:	89 e5                	mov    %esp,%ebp
	dir->ofs = 0;
40002b49:	8b 45 08             	mov    0x8(%ebp),%eax
40002b4c:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
40002b53:	5d                   	pop    %ebp
40002b54:	c3                   	ret    

40002b55 <seekdir>:

void seekdir(DIR *dir, long ofs)
{
40002b55:	55                   	push   %ebp
40002b56:	89 e5                	mov    %esp,%ebp
	dir->ofs = ofs;
40002b58:	8b 45 08             	mov    0x8(%ebp),%eax
40002b5b:	8b 55 0c             	mov    0xc(%ebp),%edx
40002b5e:	89 50 08             	mov    %edx,0x8(%eax)
}
40002b61:	5d                   	pop    %ebp
40002b62:	c3                   	ret    

40002b63 <telldir>:

long telldir(DIR *dir)
{
40002b63:	55                   	push   %ebp
40002b64:	89 e5                	mov    %esp,%ebp
	return dir->ofs;
40002b66:	8b 45 08             	mov    0x8(%ebp),%eax
40002b69:	8b 40 08             	mov    0x8(%eax),%eax
}
40002b6c:	5d                   	pop    %ebp
40002b6d:	c3                   	ret    
40002b6e:	66 90                	xchg   %ax,%ax

40002b70 <fopen>:
FILE *const stdout = &FILES->fd[1];
FILE *const stderr = &FILES->fd[2];

FILE *
fopen(const char *path, const char *mode)
{
40002b70:	55                   	push   %ebp
40002b71:	89 e5                	mov    %esp,%ebp
40002b73:	83 ec 28             	sub    $0x28,%esp
	// Find an unused file descriptor and use it for the open
	FILE *fd = filedesc_alloc();
40002b76:	e8 52 f1 ff ff       	call   40001ccd <filedesc_alloc>
40002b7b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (fd == NULL)
40002b7e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002b82:	75 07                	jne    40002b8b <fopen+0x1b>
		return NULL;
40002b84:	b8 00 00 00 00       	mov    $0x0,%eax
40002b89:	eb 19                	jmp    40002ba4 <fopen+0x34>

	return freopen(path, mode, fd);
40002b8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002b8e:	89 44 24 08          	mov    %eax,0x8(%esp)
40002b92:	8b 45 0c             	mov    0xc(%ebp),%eax
40002b95:	89 44 24 04          	mov    %eax,0x4(%esp)
40002b99:	8b 45 08             	mov    0x8(%ebp),%eax
40002b9c:	89 04 24             	mov    %eax,(%esp)
40002b9f:	e8 02 00 00 00       	call   40002ba6 <freopen>
}
40002ba4:	c9                   	leave  
40002ba5:	c3                   	ret    

40002ba6 <freopen>:

FILE *
freopen(const char *path, const char *mode, FILE *fd)
{
40002ba6:	55                   	push   %ebp
40002ba7:	89 e5                	mov    %esp,%ebp
40002ba9:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isvalid(fd));
40002bac:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002bb1:	83 c0 10             	add    $0x10,%eax
40002bb4:	3b 45 10             	cmp    0x10(%ebp),%eax
40002bb7:	77 0f                	ja     40002bc8 <freopen+0x22>
40002bb9:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002bbe:	05 10 10 00 00       	add    $0x1010,%eax
40002bc3:	3b 45 10             	cmp    0x10(%ebp),%eax
40002bc6:	77 24                	ja     40002bec <freopen+0x46>
40002bc8:	c7 44 24 0c 84 42 00 	movl   $0x40004284,0xc(%esp)
40002bcf:	40 
40002bd0:	c7 44 24 08 99 42 00 	movl   $0x40004299,0x8(%esp)
40002bd7:	40 
40002bd8:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
40002bdf:	00 
40002be0:	c7 04 24 ae 42 00 40 	movl   $0x400042ae,(%esp)
40002be7:	e8 6c d9 ff ff       	call   40000558 <debug_panic>
	if (filedesc_isopen(fd))
40002bec:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002bf1:	83 c0 10             	add    $0x10,%eax
40002bf4:	3b 45 10             	cmp    0x10(%ebp),%eax
40002bf7:	77 23                	ja     40002c1c <freopen+0x76>
40002bf9:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002bfe:	05 10 10 00 00       	add    $0x1010,%eax
40002c03:	3b 45 10             	cmp    0x10(%ebp),%eax
40002c06:	76 14                	jbe    40002c1c <freopen+0x76>
40002c08:	8b 45 10             	mov    0x10(%ebp),%eax
40002c0b:	8b 00                	mov    (%eax),%eax
40002c0d:	85 c0                	test   %eax,%eax
40002c0f:	74 0b                	je     40002c1c <freopen+0x76>
		fclose(fd);
40002c11:	8b 45 10             	mov    0x10(%ebp),%eax
40002c14:	89 04 24             	mov    %eax,(%esp)
40002c17:	e8 b4 00 00 00       	call   40002cd0 <fclose>

	// Parse the open mode string
	int flags;
	switch (*mode++) {
40002c1c:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c1f:	0f b6 00             	movzbl (%eax),%eax
40002c22:	0f be c0             	movsbl %al,%eax
40002c25:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
40002c29:	83 f8 72             	cmp    $0x72,%eax
40002c2c:	74 0c                	je     40002c3a <freopen+0x94>
40002c2e:	83 f8 77             	cmp    $0x77,%eax
40002c31:	74 10                	je     40002c43 <freopen+0x9d>
40002c33:	83 f8 61             	cmp    $0x61,%eax
40002c36:	74 14                	je     40002c4c <freopen+0xa6>
40002c38:	eb 1b                	jmp    40002c55 <freopen+0xaf>
	case 'r':	flags = O_RDONLY; break;
40002c3a:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
40002c41:	eb 3f                	jmp    40002c82 <freopen+0xdc>
	case 'w':	flags = O_WRONLY | O_CREAT | O_TRUNC; break;
40002c43:	c7 45 f4 62 00 00 00 	movl   $0x62,-0xc(%ebp)
40002c4a:	eb 36                	jmp    40002c82 <freopen+0xdc>
	case 'a':	flags = O_WRONLY | O_CREAT | O_APPEND; break;
40002c4c:	c7 45 f4 32 00 00 00 	movl   $0x32,-0xc(%ebp)
40002c53:	eb 2d                	jmp    40002c82 <freopen+0xdc>
	default:	panic("freopen: unknown file mode '%c'\n", *--mode);
40002c55:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
40002c59:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c5c:	0f b6 00             	movzbl (%eax),%eax
40002c5f:	0f be c0             	movsbl %al,%eax
40002c62:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002c66:	c7 44 24 08 bc 42 00 	movl   $0x400042bc,0x8(%esp)
40002c6d:	40 
40002c6e:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
40002c75:	00 
40002c76:	c7 04 24 ae 42 00 40 	movl   $0x400042ae,(%esp)
40002c7d:	e8 d6 d8 ff ff       	call   40000558 <debug_panic>
	}
	if (*mode == 'b')	// binary flag - compatibility only
40002c82:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c85:	0f b6 00             	movzbl (%eax),%eax
40002c88:	3c 62                	cmp    $0x62,%al
40002c8a:	75 04                	jne    40002c90 <freopen+0xea>
		mode++;
40002c8c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	if (*mode == '+')
40002c90:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c93:	0f b6 00             	movzbl (%eax),%eax
40002c96:	3c 2b                	cmp    $0x2b,%al
40002c98:	75 04                	jne    40002c9e <freopen+0xf8>
		flags |= O_RDWR;
40002c9a:	83 4d f4 03          	orl    $0x3,-0xc(%ebp)

	if (filedesc_open(fd, path, flags, 0666) != fd)
40002c9e:	c7 44 24 0c b6 01 00 	movl   $0x1b6,0xc(%esp)
40002ca5:	00 
40002ca6:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002ca9:	89 44 24 08          	mov    %eax,0x8(%esp)
40002cad:	8b 45 08             	mov    0x8(%ebp),%eax
40002cb0:	89 44 24 04          	mov    %eax,0x4(%esp)
40002cb4:	8b 45 10             	mov    0x10(%ebp),%eax
40002cb7:	89 04 24             	mov    %eax,(%esp)
40002cba:	e8 64 f0 ff ff       	call   40001d23 <filedesc_open>
40002cbf:	3b 45 10             	cmp    0x10(%ebp),%eax
40002cc2:	74 07                	je     40002ccb <freopen+0x125>
		return NULL;
40002cc4:	b8 00 00 00 00       	mov    $0x0,%eax
40002cc9:	eb 03                	jmp    40002cce <freopen+0x128>
	return fd;
40002ccb:	8b 45 10             	mov    0x10(%ebp),%eax
}
40002cce:	c9                   	leave  
40002ccf:	c3                   	ret    

40002cd0 <fclose>:

int
fclose(FILE *fd)
{
40002cd0:	55                   	push   %ebp
40002cd1:	89 e5                	mov    %esp,%ebp
40002cd3:	83 ec 18             	sub    $0x18,%esp
	filedesc_close(fd);
40002cd6:	8b 45 08             	mov    0x8(%ebp),%eax
40002cd9:	89 04 24             	mov    %eax,(%esp)
40002cdc:	e8 07 f6 ff ff       	call   400022e8 <filedesc_close>
	return 0;
40002ce1:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002ce6:	c9                   	leave  
40002ce7:	c3                   	ret    

40002ce8 <fgetc>:

int
fgetc(FILE *fd)
{
40002ce8:	55                   	push   %ebp
40002ce9:	89 e5                	mov    %esp,%ebp
40002ceb:	83 ec 28             	sub    $0x28,%esp
	unsigned char ch;
	if (filedesc_read(fd, &ch, 1, 1) < 1)
40002cee:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
40002cf5:	00 
40002cf6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40002cfd:	00 
40002cfe:	8d 45 f7             	lea    -0x9(%ebp),%eax
40002d01:	89 44 24 04          	mov    %eax,0x4(%esp)
40002d05:	8b 45 08             	mov    0x8(%ebp),%eax
40002d08:	89 04 24             	mov    %eax,(%esp)
40002d0b:	e8 3d f2 ff ff       	call   40001f4d <filedesc_read>
40002d10:	85 c0                	test   %eax,%eax
40002d12:	7f 07                	jg     40002d1b <fgetc+0x33>
		return EOF;
40002d14:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002d19:	eb 07                	jmp    40002d22 <fgetc+0x3a>
	return ch;
40002d1b:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
40002d1f:	0f b6 c0             	movzbl %al,%eax
}
40002d22:	c9                   	leave  
40002d23:	c3                   	ret    

40002d24 <fputc>:

int
fputc(int c, FILE *fd)
{
40002d24:	55                   	push   %ebp
40002d25:	89 e5                	mov    %esp,%ebp
40002d27:	83 ec 28             	sub    $0x28,%esp
	unsigned char ch = c;
40002d2a:	8b 45 08             	mov    0x8(%ebp),%eax
40002d2d:	88 45 f7             	mov    %al,-0x9(%ebp)
	if (filedesc_write(fd, &ch, 1, 1) < 1)
40002d30:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
40002d37:	00 
40002d38:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40002d3f:	00 
40002d40:	8d 45 f7             	lea    -0x9(%ebp),%eax
40002d43:	89 44 24 04          	mov    %eax,0x4(%esp)
40002d47:	8b 45 0c             	mov    0xc(%ebp),%eax
40002d4a:	89 04 24             	mov    %eax,(%esp)
40002d4d:	e8 10 f3 ff ff       	call   40002062 <filedesc_write>
40002d52:	85 c0                	test   %eax,%eax
40002d54:	7f 07                	jg     40002d5d <fputc+0x39>
		return EOF;
40002d56:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002d5b:	eb 07                	jmp    40002d64 <fputc+0x40>
	return ch;
40002d5d:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
40002d61:	0f b6 c0             	movzbl %al,%eax
}
40002d64:	c9                   	leave  
40002d65:	c3                   	ret    

40002d66 <fread>:

size_t
fread(void *buf, size_t eltsize, size_t count, FILE *fd)
{
40002d66:	55                   	push   %ebp
40002d67:	89 e5                	mov    %esp,%ebp
40002d69:	83 ec 28             	sub    $0x28,%esp
	ssize_t actual = filedesc_read(fd, buf, eltsize, count);
40002d6c:	8b 45 10             	mov    0x10(%ebp),%eax
40002d6f:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002d73:	8b 45 0c             	mov    0xc(%ebp),%eax
40002d76:	89 44 24 08          	mov    %eax,0x8(%esp)
40002d7a:	8b 45 08             	mov    0x8(%ebp),%eax
40002d7d:	89 44 24 04          	mov    %eax,0x4(%esp)
40002d81:	8b 45 14             	mov    0x14(%ebp),%eax
40002d84:	89 04 24             	mov    %eax,(%esp)
40002d87:	e8 c1 f1 ff ff       	call   40001f4d <filedesc_read>
40002d8c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return actual >= 0 ? actual : 0;	// no error indication
40002d8f:	b8 00 00 00 00       	mov    $0x0,%eax
40002d94:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002d98:	0f 49 45 f4          	cmovns -0xc(%ebp),%eax
}
40002d9c:	c9                   	leave  
40002d9d:	c3                   	ret    

40002d9e <fwrite>:

size_t
fwrite(const void *buf, size_t eltsize, size_t count, FILE *fd)
{
40002d9e:	55                   	push   %ebp
40002d9f:	89 e5                	mov    %esp,%ebp
40002da1:	83 ec 28             	sub    $0x28,%esp
	ssize_t actual = filedesc_write(fd, buf, eltsize, count);
40002da4:	8b 45 10             	mov    0x10(%ebp),%eax
40002da7:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002dab:	8b 45 0c             	mov    0xc(%ebp),%eax
40002dae:	89 44 24 08          	mov    %eax,0x8(%esp)
40002db2:	8b 45 08             	mov    0x8(%ebp),%eax
40002db5:	89 44 24 04          	mov    %eax,0x4(%esp)
40002db9:	8b 45 14             	mov    0x14(%ebp),%eax
40002dbc:	89 04 24             	mov    %eax,(%esp)
40002dbf:	e8 9e f2 ff ff       	call   40002062 <filedesc_write>
40002dc4:	89 45 f4             	mov    %eax,-0xc(%ebp)

		
	return actual >= 0 ? actual : 0;	// no error indication
40002dc7:	b8 00 00 00 00       	mov    $0x0,%eax
40002dcc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002dd0:	0f 49 45 f4          	cmovns -0xc(%ebp),%eax
}
40002dd4:	c9                   	leave  
40002dd5:	c3                   	ret    

40002dd6 <fseek>:

int
fseek(FILE *fd, off_t offset, int whence)
{
40002dd6:	55                   	push   %ebp
40002dd7:	89 e5                	mov    %esp,%ebp
40002dd9:	83 ec 18             	sub    $0x18,%esp
	if (filedesc_seek(fd, offset, whence) < 0)
40002ddc:	8b 45 10             	mov    0x10(%ebp),%eax
40002ddf:	89 44 24 08          	mov    %eax,0x8(%esp)
40002de3:	8b 45 0c             	mov    0xc(%ebp),%eax
40002de6:	89 44 24 04          	mov    %eax,0x4(%esp)
40002dea:	8b 45 08             	mov    0x8(%ebp),%eax
40002ded:	89 04 24             	mov    %eax,(%esp)
40002df0:	e8 e2 f3 ff ff       	call   400021d7 <filedesc_seek>
40002df5:	85 c0                	test   %eax,%eax
40002df7:	79 07                	jns    40002e00 <fseek+0x2a>
		return -1;
40002df9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40002dfe:	eb 05                	jmp    40002e05 <fseek+0x2f>
	return 0;	// fseek() returns 0 on success, not the new position
40002e00:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002e05:	c9                   	leave  
40002e06:	c3                   	ret    

40002e07 <ftell>:

long
ftell(FILE *fd)
{
40002e07:	55                   	push   %ebp
40002e08:	89 e5                	mov    %esp,%ebp
40002e0a:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
40002e0d:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002e12:	83 c0 10             	add    $0x10,%eax
40002e15:	3b 45 08             	cmp    0x8(%ebp),%eax
40002e18:	77 18                	ja     40002e32 <ftell+0x2b>
40002e1a:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002e1f:	05 10 10 00 00       	add    $0x1010,%eax
40002e24:	3b 45 08             	cmp    0x8(%ebp),%eax
40002e27:	76 09                	jbe    40002e32 <ftell+0x2b>
40002e29:	8b 45 08             	mov    0x8(%ebp),%eax
40002e2c:	8b 00                	mov    (%eax),%eax
40002e2e:	85 c0                	test   %eax,%eax
40002e30:	75 24                	jne    40002e56 <ftell+0x4f>
40002e32:	c7 44 24 0c dd 42 00 	movl   $0x400042dd,0xc(%esp)
40002e39:	40 
40002e3a:	c7 44 24 08 99 42 00 	movl   $0x40004299,0x8(%esp)
40002e41:	40 
40002e42:	c7 44 24 04 7a 00 00 	movl   $0x7a,0x4(%esp)
40002e49:	00 
40002e4a:	c7 04 24 ae 42 00 40 	movl   $0x400042ae,(%esp)
40002e51:	e8 02 d7 ff ff       	call   40000558 <debug_panic>
	return fd->ofs;
40002e56:	8b 45 08             	mov    0x8(%ebp),%eax
40002e59:	8b 40 08             	mov    0x8(%eax),%eax
}
40002e5c:	c9                   	leave  
40002e5d:	c3                   	ret    

40002e5e <feof>:

int
feof(FILE *fd)
{
40002e5e:	55                   	push   %ebp
40002e5f:	89 e5                	mov    %esp,%ebp
40002e61:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isopen(fd));
40002e64:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002e69:	83 c0 10             	add    $0x10,%eax
40002e6c:	3b 45 08             	cmp    0x8(%ebp),%eax
40002e6f:	77 18                	ja     40002e89 <feof+0x2b>
40002e71:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002e76:	05 10 10 00 00       	add    $0x1010,%eax
40002e7b:	3b 45 08             	cmp    0x8(%ebp),%eax
40002e7e:	76 09                	jbe    40002e89 <feof+0x2b>
40002e80:	8b 45 08             	mov    0x8(%ebp),%eax
40002e83:	8b 00                	mov    (%eax),%eax
40002e85:	85 c0                	test   %eax,%eax
40002e87:	75 24                	jne    40002ead <feof+0x4f>
40002e89:	c7 44 24 0c dd 42 00 	movl   $0x400042dd,0xc(%esp)
40002e90:	40 
40002e91:	c7 44 24 08 99 42 00 	movl   $0x40004299,0x8(%esp)
40002e98:	40 
40002e99:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
40002ea0:	00 
40002ea1:	c7 04 24 ae 42 00 40 	movl   $0x400042ae,(%esp)
40002ea8:	e8 ab d6 ff ff       	call   40000558 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40002ead:	8b 15 2c 3f 00 40    	mov    0x40003f2c,%edx
40002eb3:	8b 45 08             	mov    0x8(%ebp),%eax
40002eb6:	8b 00                	mov    (%eax),%eax
40002eb8:	6b c0 5c             	imul   $0x5c,%eax,%eax
40002ebb:	05 10 10 00 00       	add    $0x1010,%eax
40002ec0:	01 d0                	add    %edx,%eax
40002ec2:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return fd->ofs >= fi->size && !(fi->mode & S_IFPART);
40002ec5:	8b 45 08             	mov    0x8(%ebp),%eax
40002ec8:	8b 40 08             	mov    0x8(%eax),%eax
40002ecb:	89 c2                	mov    %eax,%edx
40002ecd:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002ed0:	8b 40 4c             	mov    0x4c(%eax),%eax
40002ed3:	39 c2                	cmp    %eax,%edx
40002ed5:	72 16                	jb     40002eed <feof+0x8f>
40002ed7:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002eda:	8b 40 48             	mov    0x48(%eax),%eax
40002edd:	25 00 80 00 00       	and    $0x8000,%eax
40002ee2:	85 c0                	test   %eax,%eax
40002ee4:	75 07                	jne    40002eed <feof+0x8f>
40002ee6:	b8 01 00 00 00       	mov    $0x1,%eax
40002eeb:	eb 05                	jmp    40002ef2 <feof+0x94>
40002eed:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002ef2:	c9                   	leave  
40002ef3:	c3                   	ret    

40002ef4 <ferror>:

int
ferror(FILE *fd)
{
40002ef4:	55                   	push   %ebp
40002ef5:	89 e5                	mov    %esp,%ebp
40002ef7:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
40002efa:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002eff:	83 c0 10             	add    $0x10,%eax
40002f02:	3b 45 08             	cmp    0x8(%ebp),%eax
40002f05:	77 18                	ja     40002f1f <ferror+0x2b>
40002f07:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002f0c:	05 10 10 00 00       	add    $0x1010,%eax
40002f11:	3b 45 08             	cmp    0x8(%ebp),%eax
40002f14:	76 09                	jbe    40002f1f <ferror+0x2b>
40002f16:	8b 45 08             	mov    0x8(%ebp),%eax
40002f19:	8b 00                	mov    (%eax),%eax
40002f1b:	85 c0                	test   %eax,%eax
40002f1d:	75 24                	jne    40002f43 <ferror+0x4f>
40002f1f:	c7 44 24 0c dd 42 00 	movl   $0x400042dd,0xc(%esp)
40002f26:	40 
40002f27:	c7 44 24 08 99 42 00 	movl   $0x40004299,0x8(%esp)
40002f2e:	40 
40002f2f:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
40002f36:	00 
40002f37:	c7 04 24 ae 42 00 40 	movl   $0x400042ae,(%esp)
40002f3e:	e8 15 d6 ff ff       	call   40000558 <debug_panic>
	return fd->err;
40002f43:	8b 45 08             	mov    0x8(%ebp),%eax
40002f46:	8b 40 0c             	mov    0xc(%eax),%eax
}
40002f49:	c9                   	leave  
40002f4a:	c3                   	ret    

40002f4b <clearerr>:

void
clearerr(FILE *fd)
{
40002f4b:	55                   	push   %ebp
40002f4c:	89 e5                	mov    %esp,%ebp
40002f4e:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
40002f51:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002f56:	83 c0 10             	add    $0x10,%eax
40002f59:	3b 45 08             	cmp    0x8(%ebp),%eax
40002f5c:	77 18                	ja     40002f76 <clearerr+0x2b>
40002f5e:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002f63:	05 10 10 00 00       	add    $0x1010,%eax
40002f68:	3b 45 08             	cmp    0x8(%ebp),%eax
40002f6b:	76 09                	jbe    40002f76 <clearerr+0x2b>
40002f6d:	8b 45 08             	mov    0x8(%ebp),%eax
40002f70:	8b 00                	mov    (%eax),%eax
40002f72:	85 c0                	test   %eax,%eax
40002f74:	75 24                	jne    40002f9a <clearerr+0x4f>
40002f76:	c7 44 24 0c dd 42 00 	movl   $0x400042dd,0xc(%esp)
40002f7d:	40 
40002f7e:	c7 44 24 08 99 42 00 	movl   $0x40004299,0x8(%esp)
40002f85:	40 
40002f86:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
40002f8d:	00 
40002f8e:	c7 04 24 ae 42 00 40 	movl   $0x400042ae,(%esp)
40002f95:	e8 be d5 ff ff       	call   40000558 <debug_panic>
	fd->err = 0;
40002f9a:	8b 45 08             	mov    0x8(%ebp),%eax
40002f9d:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
}
40002fa4:	c9                   	leave  
40002fa5:	c3                   	ret    

40002fa6 <fflush>:


int
fflush(FILE *f)
{
40002fa6:	55                   	push   %ebp
40002fa7:	89 e5                	mov    %esp,%ebp
40002fa9:	83 ec 18             	sub    $0x18,%esp
	if (f == NULL) {	// flush all open streams
40002fac:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40002fb0:	75 57                	jne    40003009 <fflush+0x63>
		for (f = &files->fd[0]; f < &files->fd[OPEN_MAX]; f++)
40002fb2:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002fb7:	83 c0 10             	add    $0x10,%eax
40002fba:	89 45 08             	mov    %eax,0x8(%ebp)
40002fbd:	eb 34                	jmp    40002ff3 <fflush+0x4d>
			if (filedesc_isopen(f))
40002fbf:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002fc4:	83 c0 10             	add    $0x10,%eax
40002fc7:	3b 45 08             	cmp    0x8(%ebp),%eax
40002fca:	77 23                	ja     40002fef <fflush+0x49>
40002fcc:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002fd1:	05 10 10 00 00       	add    $0x1010,%eax
40002fd6:	3b 45 08             	cmp    0x8(%ebp),%eax
40002fd9:	76 14                	jbe    40002fef <fflush+0x49>
40002fdb:	8b 45 08             	mov    0x8(%ebp),%eax
40002fde:	8b 00                	mov    (%eax),%eax
40002fe0:	85 c0                	test   %eax,%eax
40002fe2:	74 0b                	je     40002fef <fflush+0x49>
				fflush(f);
40002fe4:	8b 45 08             	mov    0x8(%ebp),%eax
40002fe7:	89 04 24             	mov    %eax,(%esp)
40002fea:	e8 b7 ff ff ff       	call   40002fa6 <fflush>

int
fflush(FILE *f)
{
	if (f == NULL) {	// flush all open streams
		for (f = &files->fd[0]; f < &files->fd[OPEN_MAX]; f++)
40002fef:	83 45 08 10          	addl   $0x10,0x8(%ebp)
40002ff3:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40002ff8:	05 10 10 00 00       	add    $0x1010,%eax
40002ffd:	3b 45 08             	cmp    0x8(%ebp),%eax
40003000:	77 bd                	ja     40002fbf <fflush+0x19>
			if (filedesc_isopen(f))
				fflush(f);
		return 0;
40003002:	b8 00 00 00 00       	mov    $0x0,%eax
40003007:	eb 56                	jmp    4000305f <fflush+0xb9>
	}

	assert(filedesc_isopen(f));
40003009:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000300e:	83 c0 10             	add    $0x10,%eax
40003011:	3b 45 08             	cmp    0x8(%ebp),%eax
40003014:	77 18                	ja     4000302e <fflush+0x88>
40003016:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000301b:	05 10 10 00 00       	add    $0x1010,%eax
40003020:	3b 45 08             	cmp    0x8(%ebp),%eax
40003023:	76 09                	jbe    4000302e <fflush+0x88>
40003025:	8b 45 08             	mov    0x8(%ebp),%eax
40003028:	8b 00                	mov    (%eax),%eax
4000302a:	85 c0                	test   %eax,%eax
4000302c:	75 24                	jne    40003052 <fflush+0xac>
4000302e:	c7 44 24 0c f1 42 00 	movl   $0x400042f1,0xc(%esp)
40003035:	40 
40003036:	c7 44 24 08 99 42 00 	movl   $0x40004299,0x8(%esp)
4000303d:	40 
4000303e:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
40003045:	00 
40003046:	c7 04 24 ae 42 00 40 	movl   $0x400042ae,(%esp)
4000304d:	e8 06 d5 ff ff       	call   40000558 <debug_panic>
	return fileino_flush(f->ino);
40003052:	8b 45 08             	mov    0x8(%ebp),%eax
40003055:	8b 00                	mov    (%eax),%eax
40003057:	89 04 24             	mov    %eax,(%esp)
4000305a:	e8 f9 eb ff ff       	call   40001c58 <fileino_flush>
}
4000305f:	c9                   	leave  
40003060:	c3                   	ret    
40003061:	66 90                	xchg   %ax,%ax
40003063:	90                   	nop

40003064 <exit>:
#include <inc/assert.h>
#include <inc/string.h>

void gcc_noreturn
exit(int status)
{
40003064:	55                   	push   %ebp
40003065:	89 e5                	mov    %esp,%ebp
40003067:	83 ec 18             	sub    $0x18,%esp
	// To exit a PIOS user process, by convention,
	// we just set our exit status in our filestate area
	// and return to our parent process.
	files->status = status;
4000306a:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000306f:	8b 55 08             	mov    0x8(%ebp),%edx
40003072:	89 50 0c             	mov    %edx,0xc(%eax)
	files->exited = 1;
40003075:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000307a:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
40003081:	b8 03 00 00 00       	mov    $0x3,%eax
40003086:	cd 30                	int    $0x30
	sys_ret();
	panic("exit: sys_ret shouldn't have returned");
40003088:	c7 44 24 08 04 43 00 	movl   $0x40004304,0x8(%esp)
4000308f:	40 
40003090:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
40003097:	00 
40003098:	c7 04 24 2a 43 00 40 	movl   $0x4000432a,(%esp)
4000309f:	e8 b4 d4 ff ff       	call   40000558 <debug_panic>

400030a4 <abort>:
}

void gcc_noreturn
abort(void)
{
400030a4:	55                   	push   %ebp
400030a5:	89 e5                	mov    %esp,%ebp
400030a7:	83 ec 18             	sub    $0x18,%esp
	exit(EXIT_FAILURE);
400030aa:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
400030b1:	e8 ae ff ff ff       	call   40003064 <exit>
400030b6:	66 90                	xchg   %ax,%ax

400030b8 <creat>:
#include <inc/assert.h>
#include <inc/stdarg.h>

int
creat(const char *path, mode_t mode)
{
400030b8:	55                   	push   %ebp
400030b9:	89 e5                	mov    %esp,%ebp
400030bb:	83 ec 18             	sub    $0x18,%esp
	return open(path, O_CREAT | O_TRUNC | O_WRONLY, mode);
400030be:	8b 45 0c             	mov    0xc(%ebp),%eax
400030c1:	89 44 24 08          	mov    %eax,0x8(%esp)
400030c5:	c7 44 24 04 62 00 00 	movl   $0x62,0x4(%esp)
400030cc:	00 
400030cd:	8b 45 08             	mov    0x8(%ebp),%eax
400030d0:	89 04 24             	mov    %eax,(%esp)
400030d3:	e8 02 00 00 00       	call   400030da <open>
}
400030d8:	c9                   	leave  
400030d9:	c3                   	ret    

400030da <open>:

int
open(const char *path, int flags, ...)
{
400030da:	55                   	push   %ebp
400030db:	89 e5                	mov    %esp,%ebp
400030dd:	83 ec 28             	sub    $0x28,%esp
	// Get the optional mode argument, which applies only with O_CREAT.
	mode_t mode = 0;
400030e0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	if (flags & O_CREAT) {
400030e7:	8b 45 0c             	mov    0xc(%ebp),%eax
400030ea:	83 e0 20             	and    $0x20,%eax
400030ed:	85 c0                	test   %eax,%eax
400030ef:	74 18                	je     40003109 <open+0x2f>
		va_list ap;
		va_start(ap, flags);
400030f1:	8d 45 0c             	lea    0xc(%ebp),%eax
400030f4:	83 c0 04             	add    $0x4,%eax
400030f7:	89 45 f0             	mov    %eax,-0x10(%ebp)
		mode = va_arg(ap, mode_t);
400030fa:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
400030fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003101:	83 e8 04             	sub    $0x4,%eax
40003104:	8b 00                	mov    (%eax),%eax
40003106:	89 45 f4             	mov    %eax,-0xc(%ebp)
		va_end(ap);
	}

	filedesc *fd = filedesc_open(NULL, path, flags, mode);
40003109:	8b 45 0c             	mov    0xc(%ebp),%eax
4000310c:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000310f:	89 54 24 0c          	mov    %edx,0xc(%esp)
40003113:	89 44 24 08          	mov    %eax,0x8(%esp)
40003117:	8b 45 08             	mov    0x8(%ebp),%eax
4000311a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000311e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40003125:	e8 f9 eb ff ff       	call   40001d23 <filedesc_open>
4000312a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (fd == NULL)
4000312d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
40003131:	75 07                	jne    4000313a <open+0x60>
		return -1;
40003133:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40003138:	eb 14                	jmp    4000314e <open+0x74>

	return fd - files->fd;
4000313a:	8b 55 ec             	mov    -0x14(%ebp),%edx
4000313d:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40003142:	83 c0 10             	add    $0x10,%eax
40003145:	89 d1                	mov    %edx,%ecx
40003147:	29 c1                	sub    %eax,%ecx
40003149:	89 c8                	mov    %ecx,%eax
4000314b:	c1 f8 04             	sar    $0x4,%eax
}
4000314e:	c9                   	leave  
4000314f:	c3                   	ret    

40003150 <close>:

int
close(int fn)
{
40003150:	55                   	push   %ebp
40003151:	89 e5                	mov    %esp,%ebp
40003153:	83 ec 18             	sub    $0x18,%esp
	filedesc_close(&files->fd[fn]);
40003156:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000315b:	8b 55 08             	mov    0x8(%ebp),%edx
4000315e:	83 c2 01             	add    $0x1,%edx
40003161:	c1 e2 04             	shl    $0x4,%edx
40003164:	01 d0                	add    %edx,%eax
40003166:	89 04 24             	mov    %eax,(%esp)
40003169:	e8 7a f1 ff ff       	call   400022e8 <filedesc_close>
	return 0;
4000316e:	b8 00 00 00 00       	mov    $0x0,%eax
}
40003173:	c9                   	leave  
40003174:	c3                   	ret    

40003175 <read>:

ssize_t
read(int fn, void *buf, size_t nbytes)
{
40003175:	55                   	push   %ebp
40003176:	89 e5                	mov    %esp,%ebp
40003178:	83 ec 18             	sub    $0x18,%esp
	return filedesc_read(&files->fd[fn], buf, 1, nbytes);
4000317b:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40003180:	8b 55 08             	mov    0x8(%ebp),%edx
40003183:	83 c2 01             	add    $0x1,%edx
40003186:	c1 e2 04             	shl    $0x4,%edx
40003189:	01 c2                	add    %eax,%edx
4000318b:	8b 45 10             	mov    0x10(%ebp),%eax
4000318e:	89 44 24 0c          	mov    %eax,0xc(%esp)
40003192:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40003199:	00 
4000319a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000319d:	89 44 24 04          	mov    %eax,0x4(%esp)
400031a1:	89 14 24             	mov    %edx,(%esp)
400031a4:	e8 a4 ed ff ff       	call   40001f4d <filedesc_read>
}
400031a9:	c9                   	leave  
400031aa:	c3                   	ret    

400031ab <write>:

ssize_t
write(int fn, const void *buf, size_t nbytes)
{
400031ab:	55                   	push   %ebp
400031ac:	89 e5                	mov    %esp,%ebp
400031ae:	83 ec 18             	sub    $0x18,%esp
	return filedesc_write(&files->fd[fn], buf, 1, nbytes);
400031b1:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400031b6:	8b 55 08             	mov    0x8(%ebp),%edx
400031b9:	83 c2 01             	add    $0x1,%edx
400031bc:	c1 e2 04             	shl    $0x4,%edx
400031bf:	01 c2                	add    %eax,%edx
400031c1:	8b 45 10             	mov    0x10(%ebp),%eax
400031c4:	89 44 24 0c          	mov    %eax,0xc(%esp)
400031c8:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
400031cf:	00 
400031d0:	8b 45 0c             	mov    0xc(%ebp),%eax
400031d3:	89 44 24 04          	mov    %eax,0x4(%esp)
400031d7:	89 14 24             	mov    %edx,(%esp)
400031da:	e8 83 ee ff ff       	call   40002062 <filedesc_write>
}
400031df:	c9                   	leave  
400031e0:	c3                   	ret    

400031e1 <lseek>:

off_t
lseek(int fn, off_t offset, int whence)
{
400031e1:	55                   	push   %ebp
400031e2:	89 e5                	mov    %esp,%ebp
400031e4:	83 ec 18             	sub    $0x18,%esp
	return filedesc_seek(&files->fd[fn], offset, whence);
400031e7:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400031ec:	8b 55 08             	mov    0x8(%ebp),%edx
400031ef:	83 c2 01             	add    $0x1,%edx
400031f2:	c1 e2 04             	shl    $0x4,%edx
400031f5:	01 c2                	add    %eax,%edx
400031f7:	8b 45 10             	mov    0x10(%ebp),%eax
400031fa:	89 44 24 08          	mov    %eax,0x8(%esp)
400031fe:	8b 45 0c             	mov    0xc(%ebp),%eax
40003201:	89 44 24 04          	mov    %eax,0x4(%esp)
40003205:	89 14 24             	mov    %edx,(%esp)
40003208:	e8 ca ef ff ff       	call   400021d7 <filedesc_seek>
}
4000320d:	c9                   	leave  
4000320e:	c3                   	ret    

4000320f <dup>:

int
dup(int oldfn)
{
4000320f:	55                   	push   %ebp
40003210:	89 e5                	mov    %esp,%ebp
40003212:	83 ec 28             	sub    $0x28,%esp
	filedesc *newfd = filedesc_alloc();
40003215:	e8 b3 ea ff ff       	call   40001ccd <filedesc_alloc>
4000321a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (!newfd)
4000321d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40003221:	75 07                	jne    4000322a <dup+0x1b>
		return -1;
40003223:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40003228:	eb 23                	jmp    4000324d <dup+0x3e>
	return dup2(oldfn, newfd - files->fd);
4000322a:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000322d:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40003232:	83 c0 10             	add    $0x10,%eax
40003235:	89 d1                	mov    %edx,%ecx
40003237:	29 c1                	sub    %eax,%ecx
40003239:	89 c8                	mov    %ecx,%eax
4000323b:	c1 f8 04             	sar    $0x4,%eax
4000323e:	89 44 24 04          	mov    %eax,0x4(%esp)
40003242:	8b 45 08             	mov    0x8(%ebp),%eax
40003245:	89 04 24             	mov    %eax,(%esp)
40003248:	e8 02 00 00 00       	call   4000324f <dup2>
}
4000324d:	c9                   	leave  
4000324e:	c3                   	ret    

4000324f <dup2>:

int
dup2(int oldfn, int newfn)
{
4000324f:	55                   	push   %ebp
40003250:	89 e5                	mov    %esp,%ebp
40003252:	83 ec 28             	sub    $0x28,%esp
	filedesc *oldfd = &files->fd[oldfn];
40003255:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000325a:	8b 55 08             	mov    0x8(%ebp),%edx
4000325d:	83 c2 01             	add    $0x1,%edx
40003260:	c1 e2 04             	shl    $0x4,%edx
40003263:	01 d0                	add    %edx,%eax
40003265:	89 45 f4             	mov    %eax,-0xc(%ebp)
	filedesc *newfd = &files->fd[newfn];
40003268:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000326d:	8b 55 0c             	mov    0xc(%ebp),%edx
40003270:	83 c2 01             	add    $0x1,%edx
40003273:	c1 e2 04             	shl    $0x4,%edx
40003276:	01 d0                	add    %edx,%eax
40003278:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(filedesc_isopen(oldfd));
4000327b:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40003280:	83 c0 10             	add    $0x10,%eax
40003283:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40003286:	77 18                	ja     400032a0 <dup2+0x51>
40003288:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000328d:	05 10 10 00 00       	add    $0x1010,%eax
40003292:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40003295:	76 09                	jbe    400032a0 <dup2+0x51>
40003297:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000329a:	8b 00                	mov    (%eax),%eax
4000329c:	85 c0                	test   %eax,%eax
4000329e:	75 24                	jne    400032c4 <dup2+0x75>
400032a0:	c7 44 24 0c 38 43 00 	movl   $0x40004338,0xc(%esp)
400032a7:	40 
400032a8:	c7 44 24 08 4f 43 00 	movl   $0x4000434f,0x8(%esp)
400032af:	40 
400032b0:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
400032b7:	00 
400032b8:	c7 04 24 64 43 00 40 	movl   $0x40004364,(%esp)
400032bf:	e8 94 d2 ff ff       	call   40000558 <debug_panic>
	assert(filedesc_isvalid(newfd));
400032c4:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400032c9:	83 c0 10             	add    $0x10,%eax
400032cc:	3b 45 f0             	cmp    -0x10(%ebp),%eax
400032cf:	77 0f                	ja     400032e0 <dup2+0x91>
400032d1:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400032d6:	05 10 10 00 00       	add    $0x1010,%eax
400032db:	3b 45 f0             	cmp    -0x10(%ebp),%eax
400032de:	77 24                	ja     40003304 <dup2+0xb5>
400032e0:	c7 44 24 0c 71 43 00 	movl   $0x40004371,0xc(%esp)
400032e7:	40 
400032e8:	c7 44 24 08 4f 43 00 	movl   $0x4000434f,0x8(%esp)
400032ef:	40 
400032f0:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
400032f7:	00 
400032f8:	c7 04 24 64 43 00 40 	movl   $0x40004364,(%esp)
400032ff:	e8 54 d2 ff ff       	call   40000558 <debug_panic>

	if (filedesc_isopen(newfd))
40003304:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40003309:	83 c0 10             	add    $0x10,%eax
4000330c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
4000330f:	77 23                	ja     40003334 <dup2+0xe5>
40003311:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40003316:	05 10 10 00 00       	add    $0x1010,%eax
4000331b:	3b 45 f0             	cmp    -0x10(%ebp),%eax
4000331e:	76 14                	jbe    40003334 <dup2+0xe5>
40003320:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003323:	8b 00                	mov    (%eax),%eax
40003325:	85 c0                	test   %eax,%eax
40003327:	74 0b                	je     40003334 <dup2+0xe5>
		close(newfn);
40003329:	8b 45 0c             	mov    0xc(%ebp),%eax
4000332c:	89 04 24             	mov    %eax,(%esp)
4000332f:	e8 1c fe ff ff       	call   40003150 <close>

	*newfd = *oldfd;
40003334:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003337:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000333a:	8b 0a                	mov    (%edx),%ecx
4000333c:	89 08                	mov    %ecx,(%eax)
4000333e:	8b 4a 04             	mov    0x4(%edx),%ecx
40003341:	89 48 04             	mov    %ecx,0x4(%eax)
40003344:	8b 4a 08             	mov    0x8(%edx),%ecx
40003347:	89 48 08             	mov    %ecx,0x8(%eax)
4000334a:	8b 52 0c             	mov    0xc(%edx),%edx
4000334d:	89 50 0c             	mov    %edx,0xc(%eax)

	return newfn;
40003350:	8b 45 0c             	mov    0xc(%ebp),%eax
}
40003353:	c9                   	leave  
40003354:	c3                   	ret    

40003355 <truncate>:

int
truncate(const char *path, off_t newlength)
{
40003355:	55                   	push   %ebp
40003356:	89 e5                	mov    %esp,%ebp
40003358:	83 ec 28             	sub    $0x28,%esp
	int ino = dir_walk(path, 0);
4000335b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40003362:	00 
40003363:	8b 45 08             	mov    0x8(%ebp),%eax
40003366:	89 04 24             	mov    %eax,(%esp)
40003369:	e8 0e f0 ff ff       	call   4000237c <dir_walk>
4000336e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (ino < 0)
40003371:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40003375:	79 07                	jns    4000337e <truncate+0x29>
		return -1;
40003377:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
4000337c:	eb 12                	jmp    40003390 <truncate+0x3b>
	return fileino_truncate(ino, newlength);
4000337e:	8b 45 0c             	mov    0xc(%ebp),%eax
40003381:	89 44 24 04          	mov    %eax,0x4(%esp)
40003385:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003388:	89 04 24             	mov    %eax,(%esp)
4000338b:	e8 46 e6 ff ff       	call   400019d6 <fileino_truncate>
}
40003390:	c9                   	leave  
40003391:	c3                   	ret    

40003392 <ftruncate>:

int
ftruncate(int fn, off_t newlength)
{
40003392:	55                   	push   %ebp
40003393:	89 e5                	mov    %esp,%ebp
40003395:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
40003398:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000339d:	8b 55 08             	mov    0x8(%ebp),%edx
400033a0:	83 c2 01             	add    $0x1,%edx
400033a3:	c1 e2 04             	shl    $0x4,%edx
400033a6:	01 c2                	add    %eax,%edx
400033a8:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400033ad:	83 c0 10             	add    $0x10,%eax
400033b0:	39 c2                	cmp    %eax,%edx
400033b2:	72 34                	jb     400033e8 <ftruncate+0x56>
400033b4:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400033b9:	8b 55 08             	mov    0x8(%ebp),%edx
400033bc:	83 c2 01             	add    $0x1,%edx
400033bf:	c1 e2 04             	shl    $0x4,%edx
400033c2:	01 c2                	add    %eax,%edx
400033c4:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400033c9:	05 10 10 00 00       	add    $0x1010,%eax
400033ce:	39 c2                	cmp    %eax,%edx
400033d0:	73 16                	jae    400033e8 <ftruncate+0x56>
400033d2:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400033d7:	8b 55 08             	mov    0x8(%ebp),%edx
400033da:	83 c2 01             	add    $0x1,%edx
400033dd:	c1 e2 04             	shl    $0x4,%edx
400033e0:	01 d0                	add    %edx,%eax
400033e2:	8b 00                	mov    (%eax),%eax
400033e4:	85 c0                	test   %eax,%eax
400033e6:	75 24                	jne    4000340c <ftruncate+0x7a>
400033e8:	c7 44 24 0c 8c 43 00 	movl   $0x4000438c,0xc(%esp)
400033ef:	40 
400033f0:	c7 44 24 08 4f 43 00 	movl   $0x4000434f,0x8(%esp)
400033f7:	40 
400033f8:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
400033ff:	00 
40003400:	c7 04 24 64 43 00 40 	movl   $0x40004364,(%esp)
40003407:	e8 4c d1 ff ff       	call   40000558 <debug_panic>
	return fileino_truncate(files->fd[fn].ino, newlength);
4000340c:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40003411:	8b 55 08             	mov    0x8(%ebp),%edx
40003414:	83 c2 01             	add    $0x1,%edx
40003417:	c1 e2 04             	shl    $0x4,%edx
4000341a:	01 d0                	add    %edx,%eax
4000341c:	8b 00                	mov    (%eax),%eax
4000341e:	8b 55 0c             	mov    0xc(%ebp),%edx
40003421:	89 54 24 04          	mov    %edx,0x4(%esp)
40003425:	89 04 24             	mov    %eax,(%esp)
40003428:	e8 a9 e5 ff ff       	call   400019d6 <fileino_truncate>
}
4000342d:	c9                   	leave  
4000342e:	c3                   	ret    

4000342f <isatty>:

int
isatty(int fn)
{
4000342f:	55                   	push   %ebp
40003430:	89 e5                	mov    %esp,%ebp
40003432:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
40003435:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000343a:	8b 55 08             	mov    0x8(%ebp),%edx
4000343d:	83 c2 01             	add    $0x1,%edx
40003440:	c1 e2 04             	shl    $0x4,%edx
40003443:	01 c2                	add    %eax,%edx
40003445:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000344a:	83 c0 10             	add    $0x10,%eax
4000344d:	39 c2                	cmp    %eax,%edx
4000344f:	72 34                	jb     40003485 <isatty+0x56>
40003451:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40003456:	8b 55 08             	mov    0x8(%ebp),%edx
40003459:	83 c2 01             	add    $0x1,%edx
4000345c:	c1 e2 04             	shl    $0x4,%edx
4000345f:	01 c2                	add    %eax,%edx
40003461:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40003466:	05 10 10 00 00       	add    $0x1010,%eax
4000346b:	39 c2                	cmp    %eax,%edx
4000346d:	73 16                	jae    40003485 <isatty+0x56>
4000346f:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40003474:	8b 55 08             	mov    0x8(%ebp),%edx
40003477:	83 c2 01             	add    $0x1,%edx
4000347a:	c1 e2 04             	shl    $0x4,%edx
4000347d:	01 d0                	add    %edx,%eax
4000347f:	8b 00                	mov    (%eax),%eax
40003481:	85 c0                	test   %eax,%eax
40003483:	75 24                	jne    400034a9 <isatty+0x7a>
40003485:	c7 44 24 0c 8c 43 00 	movl   $0x4000438c,0xc(%esp)
4000348c:	40 
4000348d:	c7 44 24 08 4f 43 00 	movl   $0x4000434f,0x8(%esp)
40003494:	40 
40003495:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
4000349c:	00 
4000349d:	c7 04 24 64 43 00 40 	movl   $0x40004364,(%esp)
400034a4:	e8 af d0 ff ff       	call   40000558 <debug_panic>
	return files->fd[fn].ino == FILEINO_CONSIN
400034a9:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400034ae:	8b 55 08             	mov    0x8(%ebp),%edx
400034b1:	83 c2 01             	add    $0x1,%edx
400034b4:	c1 e2 04             	shl    $0x4,%edx
400034b7:	01 d0                	add    %edx,%eax
400034b9:	8b 00                	mov    (%eax),%eax
		|| files->fd[fn].ino == FILEINO_CONSOUT;
400034bb:	83 f8 01             	cmp    $0x1,%eax
400034be:	74 17                	je     400034d7 <isatty+0xa8>
400034c0:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400034c5:	8b 55 08             	mov    0x8(%ebp),%edx
400034c8:	83 c2 01             	add    $0x1,%edx
400034cb:	c1 e2 04             	shl    $0x4,%edx
400034ce:	01 d0                	add    %edx,%eax
400034d0:	8b 00                	mov    (%eax),%eax
400034d2:	83 f8 02             	cmp    $0x2,%eax
400034d5:	75 07                	jne    400034de <isatty+0xaf>
400034d7:	b8 01 00 00 00       	mov    $0x1,%eax
400034dc:	eb 05                	jmp    400034e3 <isatty+0xb4>
400034de:	b8 00 00 00 00       	mov    $0x0,%eax
}
400034e3:	c9                   	leave  
400034e4:	c3                   	ret    

400034e5 <stat>:

int
stat(const char *path, struct stat *statbuf)
{
400034e5:	55                   	push   %ebp
400034e6:	89 e5                	mov    %esp,%ebp
400034e8:	83 ec 28             	sub    $0x28,%esp
	int ino = dir_walk(path, 0);
400034eb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400034f2:	00 
400034f3:	8b 45 08             	mov    0x8(%ebp),%eax
400034f6:	89 04 24             	mov    %eax,(%esp)
400034f9:	e8 7e ee ff ff       	call   4000237c <dir_walk>
400034fe:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (ino < 0)
40003501:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40003505:	79 07                	jns    4000350e <stat+0x29>
		return -1;
40003507:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
4000350c:	eb 12                	jmp    40003520 <stat+0x3b>
	return fileino_stat(ino, statbuf);
4000350e:	8b 45 0c             	mov    0xc(%ebp),%eax
40003511:	89 44 24 04          	mov    %eax,0x4(%esp)
40003515:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003518:	89 04 24             	mov    %eax,(%esp)
4000351b:	e8 91 e3 ff ff       	call   400018b1 <fileino_stat>
}
40003520:	c9                   	leave  
40003521:	c3                   	ret    

40003522 <fstat>:

int
fstat(int fn, struct stat *statbuf)
{
40003522:	55                   	push   %ebp
40003523:	89 e5                	mov    %esp,%ebp
40003525:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
40003528:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000352d:	8b 55 08             	mov    0x8(%ebp),%edx
40003530:	83 c2 01             	add    $0x1,%edx
40003533:	c1 e2 04             	shl    $0x4,%edx
40003536:	01 c2                	add    %eax,%edx
40003538:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000353d:	83 c0 10             	add    $0x10,%eax
40003540:	39 c2                	cmp    %eax,%edx
40003542:	72 34                	jb     40003578 <fstat+0x56>
40003544:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40003549:	8b 55 08             	mov    0x8(%ebp),%edx
4000354c:	83 c2 01             	add    $0x1,%edx
4000354f:	c1 e2 04             	shl    $0x4,%edx
40003552:	01 c2                	add    %eax,%edx
40003554:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40003559:	05 10 10 00 00       	add    $0x1010,%eax
4000355e:	39 c2                	cmp    %eax,%edx
40003560:	73 16                	jae    40003578 <fstat+0x56>
40003562:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40003567:	8b 55 08             	mov    0x8(%ebp),%edx
4000356a:	83 c2 01             	add    $0x1,%edx
4000356d:	c1 e2 04             	shl    $0x4,%edx
40003570:	01 d0                	add    %edx,%eax
40003572:	8b 00                	mov    (%eax),%eax
40003574:	85 c0                	test   %eax,%eax
40003576:	75 24                	jne    4000359c <fstat+0x7a>
40003578:	c7 44 24 0c 8c 43 00 	movl   $0x4000438c,0xc(%esp)
4000357f:	40 
40003580:	c7 44 24 08 4f 43 00 	movl   $0x4000434f,0x8(%esp)
40003587:	40 
40003588:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
4000358f:	00 
40003590:	c7 04 24 64 43 00 40 	movl   $0x40004364,(%esp)
40003597:	e8 bc cf ff ff       	call   40000558 <debug_panic>
	return fileino_stat(files->fd[fn].ino, statbuf);
4000359c:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400035a1:	8b 55 08             	mov    0x8(%ebp),%edx
400035a4:	83 c2 01             	add    $0x1,%edx
400035a7:	c1 e2 04             	shl    $0x4,%edx
400035aa:	01 d0                	add    %edx,%eax
400035ac:	8b 00                	mov    (%eax),%eax
400035ae:	8b 55 0c             	mov    0xc(%ebp),%edx
400035b1:	89 54 24 04          	mov    %edx,0x4(%esp)
400035b5:	89 04 24             	mov    %eax,(%esp)
400035b8:	e8 f4 e2 ff ff       	call   400018b1 <fileino_stat>
}
400035bd:	c9                   	leave  
400035be:	c3                   	ret    

400035bf <fsync>:

int
fsync(int fn)
{
400035bf:	55                   	push   %ebp
400035c0:	89 e5                	mov    %esp,%ebp
400035c2:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
400035c5:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400035ca:	8b 55 08             	mov    0x8(%ebp),%edx
400035cd:	83 c2 01             	add    $0x1,%edx
400035d0:	c1 e2 04             	shl    $0x4,%edx
400035d3:	01 c2                	add    %eax,%edx
400035d5:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400035da:	83 c0 10             	add    $0x10,%eax
400035dd:	39 c2                	cmp    %eax,%edx
400035df:	72 34                	jb     40003615 <fsync+0x56>
400035e1:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400035e6:	8b 55 08             	mov    0x8(%ebp),%edx
400035e9:	83 c2 01             	add    $0x1,%edx
400035ec:	c1 e2 04             	shl    $0x4,%edx
400035ef:	01 c2                	add    %eax,%edx
400035f1:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
400035f6:	05 10 10 00 00       	add    $0x1010,%eax
400035fb:	39 c2                	cmp    %eax,%edx
400035fd:	73 16                	jae    40003615 <fsync+0x56>
400035ff:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
40003604:	8b 55 08             	mov    0x8(%ebp),%edx
40003607:	83 c2 01             	add    $0x1,%edx
4000360a:	c1 e2 04             	shl    $0x4,%edx
4000360d:	01 d0                	add    %edx,%eax
4000360f:	8b 00                	mov    (%eax),%eax
40003611:	85 c0                	test   %eax,%eax
40003613:	75 24                	jne    40003639 <fsync+0x7a>
40003615:	c7 44 24 0c 8c 43 00 	movl   $0x4000438c,0xc(%esp)
4000361c:	40 
4000361d:	c7 44 24 08 4f 43 00 	movl   $0x4000434f,0x8(%esp)
40003624:	40 
40003625:	c7 44 24 04 87 00 00 	movl   $0x87,0x4(%esp)
4000362c:	00 
4000362d:	c7 04 24 64 43 00 40 	movl   $0x40004364,(%esp)
40003634:	e8 1f cf ff ff       	call   40000558 <debug_panic>
	return fileino_flush(files->fd[fn].ino);
40003639:	a1 2c 3f 00 40       	mov    0x40003f2c,%eax
4000363e:	8b 55 08             	mov    0x8(%ebp),%edx
40003641:	83 c2 01             	add    $0x1,%edx
40003644:	c1 e2 04             	shl    $0x4,%edx
40003647:	01 d0                	add    %edx,%eax
40003649:	8b 00                	mov    (%eax),%eax
4000364b:	89 04 24             	mov    %eax,(%esp)
4000364e:	e8 05 e6 ff ff       	call   40001c58 <fileino_flush>
}
40003653:	c9                   	leave  
40003654:	c3                   	ret    
40003655:	66 90                	xchg   %ax,%ax
40003657:	90                   	nop

40003658 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
40003658:	55                   	push   %ebp
40003659:	89 e5                	mov    %esp,%ebp
	b->cnt++;
4000365b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000365e:	8b 40 08             	mov    0x8(%eax),%eax
40003661:	8d 50 01             	lea    0x1(%eax),%edx
40003664:	8b 45 0c             	mov    0xc(%ebp),%eax
40003667:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
4000366a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000366d:	8b 10                	mov    (%eax),%edx
4000366f:	8b 45 0c             	mov    0xc(%ebp),%eax
40003672:	8b 40 04             	mov    0x4(%eax),%eax
40003675:	39 c2                	cmp    %eax,%edx
40003677:	73 12                	jae    4000368b <sprintputch+0x33>
		*b->buf++ = ch;
40003679:	8b 45 0c             	mov    0xc(%ebp),%eax
4000367c:	8b 00                	mov    (%eax),%eax
4000367e:	8b 55 08             	mov    0x8(%ebp),%edx
40003681:	88 10                	mov    %dl,(%eax)
40003683:	8d 50 01             	lea    0x1(%eax),%edx
40003686:	8b 45 0c             	mov    0xc(%ebp),%eax
40003689:	89 10                	mov    %edx,(%eax)
}
4000368b:	5d                   	pop    %ebp
4000368c:	c3                   	ret    

4000368d <vsprintf>:

int
vsprintf(char *buf, const char *fmt, va_list ap)
{
4000368d:	55                   	push   %ebp
4000368e:	89 e5                	mov    %esp,%ebp
40003690:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL);
40003693:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003697:	75 24                	jne    400036bd <vsprintf+0x30>
40003699:	c7 44 24 0c ac 43 00 	movl   $0x400043ac,0xc(%esp)
400036a0:	40 
400036a1:	c7 44 24 08 b8 43 00 	movl   $0x400043b8,0x8(%esp)
400036a8:	40 
400036a9:	c7 44 24 04 19 00 00 	movl   $0x19,0x4(%esp)
400036b0:	00 
400036b1:	c7 04 24 cd 43 00 40 	movl   $0x400043cd,(%esp)
400036b8:	e8 9b ce ff ff       	call   40000558 <debug_panic>
	struct sprintbuf b = {buf, (char*)(intptr_t)~0, 0};
400036bd:	8b 45 08             	mov    0x8(%ebp),%eax
400036c0:	89 45 ec             	mov    %eax,-0x14(%ebp)
400036c3:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
400036ca:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
400036d1:	8b 45 10             	mov    0x10(%ebp),%eax
400036d4:	89 44 24 0c          	mov    %eax,0xc(%esp)
400036d8:	8b 45 0c             	mov    0xc(%ebp),%eax
400036db:	89 44 24 08          	mov    %eax,0x8(%esp)
400036df:	8d 45 ec             	lea    -0x14(%ebp),%eax
400036e2:	89 44 24 04          	mov    %eax,0x4(%esp)
400036e6:	c7 04 24 58 36 00 40 	movl   $0x40003658,(%esp)
400036ed:	e8 43 d4 ff ff       	call   40000b35 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
400036f2:	8b 45 ec             	mov    -0x14(%ebp),%eax
400036f5:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
400036f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
400036fb:	c9                   	leave  
400036fc:	c3                   	ret    

400036fd <sprintf>:

int
sprintf(char *buf, const char *fmt, ...)
{
400036fd:	55                   	push   %ebp
400036fe:	89 e5                	mov    %esp,%ebp
40003700:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
40003703:	8d 45 0c             	lea    0xc(%ebp),%eax
40003706:	83 c0 04             	add    $0x4,%eax
40003709:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsprintf(buf, fmt, ap);
4000370c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000370f:	8b 55 f4             	mov    -0xc(%ebp),%edx
40003712:	89 54 24 08          	mov    %edx,0x8(%esp)
40003716:	89 44 24 04          	mov    %eax,0x4(%esp)
4000371a:	8b 45 08             	mov    0x8(%ebp),%eax
4000371d:	89 04 24             	mov    %eax,(%esp)
40003720:	e8 68 ff ff ff       	call   4000368d <vsprintf>
40003725:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
40003728:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
4000372b:	c9                   	leave  
4000372c:	c3                   	ret    

4000372d <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
4000372d:	55                   	push   %ebp
4000372e:	89 e5                	mov    %esp,%ebp
40003730:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL && n > 0);
40003733:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003737:	74 06                	je     4000373f <vsnprintf+0x12>
40003739:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
4000373d:	7f 24                	jg     40003763 <vsnprintf+0x36>
4000373f:	c7 44 24 0c db 43 00 	movl   $0x400043db,0xc(%esp)
40003746:	40 
40003747:	c7 44 24 08 b8 43 00 	movl   $0x400043b8,0x8(%esp)
4000374e:	40 
4000374f:	c7 44 24 04 35 00 00 	movl   $0x35,0x4(%esp)
40003756:	00 
40003757:	c7 04 24 cd 43 00 40 	movl   $0x400043cd,(%esp)
4000375e:	e8 f5 cd ff ff       	call   40000558 <debug_panic>
	struct sprintbuf b = {buf, buf+n-1, 0};
40003763:	8b 45 08             	mov    0x8(%ebp),%eax
40003766:	89 45 ec             	mov    %eax,-0x14(%ebp)
40003769:	8b 45 0c             	mov    0xc(%ebp),%eax
4000376c:	8d 50 ff             	lea    -0x1(%eax),%edx
4000376f:	8b 45 08             	mov    0x8(%ebp),%eax
40003772:	01 d0                	add    %edx,%eax
40003774:	89 45 f0             	mov    %eax,-0x10(%ebp)
40003777:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
4000377e:	8b 45 14             	mov    0x14(%ebp),%eax
40003781:	89 44 24 0c          	mov    %eax,0xc(%esp)
40003785:	8b 45 10             	mov    0x10(%ebp),%eax
40003788:	89 44 24 08          	mov    %eax,0x8(%esp)
4000378c:	8d 45 ec             	lea    -0x14(%ebp),%eax
4000378f:	89 44 24 04          	mov    %eax,0x4(%esp)
40003793:	c7 04 24 58 36 00 40 	movl   $0x40003658,(%esp)
4000379a:	e8 96 d3 ff ff       	call   40000b35 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
4000379f:	8b 45 ec             	mov    -0x14(%ebp),%eax
400037a2:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
400037a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
400037a8:	c9                   	leave  
400037a9:	c3                   	ret    

400037aa <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
400037aa:	55                   	push   %ebp
400037ab:	89 e5                	mov    %esp,%ebp
400037ad:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
400037b0:	8d 45 10             	lea    0x10(%ebp),%eax
400037b3:	83 c0 04             	add    $0x4,%eax
400037b6:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
400037b9:	8b 45 10             	mov    0x10(%ebp),%eax
400037bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
400037bf:	89 54 24 0c          	mov    %edx,0xc(%esp)
400037c3:	89 44 24 08          	mov    %eax,0x8(%esp)
400037c7:	8b 45 0c             	mov    0xc(%ebp),%eax
400037ca:	89 44 24 04          	mov    %eax,0x4(%esp)
400037ce:	8b 45 08             	mov    0x8(%ebp),%eax
400037d1:	89 04 24             	mov    %eax,(%esp)
400037d4:	e8 54 ff ff ff       	call   4000372d <vsnprintf>
400037d9:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
400037dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
400037df:	c9                   	leave  
400037e0:	c3                   	ret    
400037e1:	66 90                	xchg   %ax,%ax
400037e3:	90                   	nop

400037e4 <writebuf>:
};


static void
writebuf(struct printbuf *b)
{
400037e4:	55                   	push   %ebp
400037e5:	89 e5                	mov    %esp,%ebp
400037e7:	83 ec 28             	sub    $0x28,%esp
	if (!b->err) {
400037ea:	8b 45 08             	mov    0x8(%ebp),%eax
400037ed:	8b 40 0c             	mov    0xc(%eax),%eax
400037f0:	85 c0                	test   %eax,%eax
400037f2:	75 56                	jne    4000384a <writebuf+0x66>
		size_t result = fwrite(b->buf, 1, b->idx, b->fh);
400037f4:	8b 45 08             	mov    0x8(%ebp),%eax
400037f7:	8b 10                	mov    (%eax),%edx
400037f9:	8b 45 08             	mov    0x8(%ebp),%eax
400037fc:	8b 40 04             	mov    0x4(%eax),%eax
400037ff:	8b 4d 08             	mov    0x8(%ebp),%ecx
40003802:	83 c1 10             	add    $0x10,%ecx
40003805:	89 54 24 0c          	mov    %edx,0xc(%esp)
40003809:	89 44 24 08          	mov    %eax,0x8(%esp)
4000380d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40003814:	00 
40003815:	89 0c 24             	mov    %ecx,(%esp)
40003818:	e8 81 f5 ff ff       	call   40002d9e <fwrite>
4000381d:	89 45 f4             	mov    %eax,-0xc(%ebp)
		b->result += result;
40003820:	8b 45 08             	mov    0x8(%ebp),%eax
40003823:	8b 40 08             	mov    0x8(%eax),%eax
40003826:	89 c2                	mov    %eax,%edx
40003828:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000382b:	01 d0                	add    %edx,%eax
4000382d:	89 c2                	mov    %eax,%edx
4000382f:	8b 45 08             	mov    0x8(%ebp),%eax
40003832:	89 50 08             	mov    %edx,0x8(%eax)
		if (result != b->idx) // error, or wrote less than supplied
40003835:	8b 45 08             	mov    0x8(%ebp),%eax
40003838:	8b 40 04             	mov    0x4(%eax),%eax
4000383b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
4000383e:	74 0a                	je     4000384a <writebuf+0x66>
			b->err = 1;
40003840:	8b 45 08             	mov    0x8(%ebp),%eax
40003843:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
	}
}
4000384a:	c9                   	leave  
4000384b:	c3                   	ret    

4000384c <putch>:

static void
putch(int ch, void *thunk)
{
4000384c:	55                   	push   %ebp
4000384d:	89 e5                	mov    %esp,%ebp
4000384f:	83 ec 28             	sub    $0x28,%esp
	struct printbuf *b = (struct printbuf *) thunk;
40003852:	8b 45 0c             	mov    0xc(%ebp),%eax
40003855:	89 45 f4             	mov    %eax,-0xc(%ebp)
	b->buf[b->idx++] = ch;
40003858:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000385b:	8b 40 04             	mov    0x4(%eax),%eax
4000385e:	8b 55 08             	mov    0x8(%ebp),%edx
40003861:	89 d1                	mov    %edx,%ecx
40003863:	8b 55 f4             	mov    -0xc(%ebp),%edx
40003866:	88 4c 02 10          	mov    %cl,0x10(%edx,%eax,1)
4000386a:	8d 50 01             	lea    0x1(%eax),%edx
4000386d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003870:	89 50 04             	mov    %edx,0x4(%eax)
	if (b->idx == 256) {
40003873:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003876:	8b 40 04             	mov    0x4(%eax),%eax
40003879:	3d 00 01 00 00       	cmp    $0x100,%eax
4000387e:	75 15                	jne    40003895 <putch+0x49>
		writebuf(b);
40003880:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003883:	89 04 24             	mov    %eax,(%esp)
40003886:	e8 59 ff ff ff       	call   400037e4 <writebuf>
		b->idx = 0;
4000388b:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000388e:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	}
}
40003895:	c9                   	leave  
40003896:	c3                   	ret    

40003897 <vfprintf>:

int
vfprintf(FILE *fh, const char *fmt, va_list ap)
{
40003897:	55                   	push   %ebp
40003898:	89 e5                	mov    %esp,%ebp
4000389a:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.fh = fh;
400038a0:	8b 45 08             	mov    0x8(%ebp),%eax
400038a3:	89 85 e8 fe ff ff    	mov    %eax,-0x118(%ebp)
	b.idx = 0;
400038a9:	c7 85 ec fe ff ff 00 	movl   $0x0,-0x114(%ebp)
400038b0:	00 00 00 
	b.result = 0;
400038b3:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
400038ba:	00 00 00 
	b.err = 0;
400038bd:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
400038c4:	00 00 00 
	vprintfmt(putch, &b, fmt, ap);
400038c7:	8b 45 10             	mov    0x10(%ebp),%eax
400038ca:	89 44 24 0c          	mov    %eax,0xc(%esp)
400038ce:	8b 45 0c             	mov    0xc(%ebp),%eax
400038d1:	89 44 24 08          	mov    %eax,0x8(%esp)
400038d5:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
400038db:	89 44 24 04          	mov    %eax,0x4(%esp)
400038df:	c7 04 24 4c 38 00 40 	movl   $0x4000384c,(%esp)
400038e6:	e8 4a d2 ff ff       	call   40000b35 <vprintfmt>
	if (b.idx > 0)
400038eb:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
400038f1:	85 c0                	test   %eax,%eax
400038f3:	7e 0e                	jle    40003903 <vfprintf+0x6c>
		writebuf(&b);
400038f5:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
400038fb:	89 04 24             	mov    %eax,(%esp)
400038fe:	e8 e1 fe ff ff       	call   400037e4 <writebuf>

	return b.result;
40003903:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
}
40003909:	c9                   	leave  
4000390a:	c3                   	ret    

4000390b <fprintf>:

int
fprintf(FILE *fh, const char *fmt, ...)
{
4000390b:	55                   	push   %ebp
4000390c:	89 e5                	mov    %esp,%ebp
4000390e:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
40003911:	8d 45 0c             	lea    0xc(%ebp),%eax
40003914:	83 c0 04             	add    $0x4,%eax
40003917:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vfprintf(fh, fmt, ap);
4000391a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000391d:	8b 55 f4             	mov    -0xc(%ebp),%edx
40003920:	89 54 24 08          	mov    %edx,0x8(%esp)
40003924:	89 44 24 04          	mov    %eax,0x4(%esp)
40003928:	8b 45 08             	mov    0x8(%ebp),%eax
4000392b:	89 04 24             	mov    %eax,(%esp)
4000392e:	e8 64 ff ff ff       	call   40003897 <vfprintf>
40003933:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
40003936:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40003939:	c9                   	leave  
4000393a:	c3                   	ret    

4000393b <printf>:

int
printf(const char *fmt, ...)
{
4000393b:	55                   	push   %ebp
4000393c:	89 e5                	mov    %esp,%ebp
4000393e:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
40003941:	8d 45 0c             	lea    0xc(%ebp),%eax
40003944:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vfprintf(stdout, fmt, ap);
40003947:	8b 55 08             	mov    0x8(%ebp),%edx
4000394a:	a1 7c 42 00 40       	mov    0x4000427c,%eax
4000394f:	8b 4d f4             	mov    -0xc(%ebp),%ecx
40003952:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40003956:	89 54 24 04          	mov    %edx,0x4(%esp)
4000395a:	89 04 24             	mov    %eax,(%esp)
4000395d:	e8 35 ff ff ff       	call   40003897 <vfprintf>
40003962:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
40003965:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40003968:	c9                   	leave  
40003969:	c3                   	ret    
4000396a:	66 90                	xchg   %ax,%ax

4000396c <strerror>:
#include <inc/stdio.h>

char *
strerror(int err)
{
4000396c:	55                   	push   %ebp
4000396d:	89 e5                	mov    %esp,%ebp
4000396f:	83 ec 28             	sub    $0x28,%esp
		"No child processes",
		"Conflict detected",
	};
	static char errbuf[64];

	const int tablen = sizeof(errtab)/sizeof(errtab[0]);
40003972:	c7 45 f4 0b 00 00 00 	movl   $0xb,-0xc(%ebp)
	if (err >= 0 && err < sizeof(errtab)/sizeof(errtab[0]))
40003979:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
4000397d:	78 14                	js     40003993 <strerror+0x27>
4000397f:	8b 45 08             	mov    0x8(%ebp),%eax
40003982:	83 f8 0a             	cmp    $0xa,%eax
40003985:	77 0c                	ja     40003993 <strerror+0x27>
		return errtab[err];
40003987:	8b 45 08             	mov    0x8(%ebp),%eax
4000398a:	8b 04 85 40 61 00 40 	mov    0x40006140(,%eax,4),%eax
40003991:	eb 20                	jmp    400039b3 <strerror+0x47>

	sprintf(errbuf, "Unknown error code %d", err);
40003993:	8b 45 08             	mov    0x8(%ebp),%eax
40003996:	89 44 24 08          	mov    %eax,0x8(%esp)
4000399a:	c7 44 24 04 f0 43 00 	movl   $0x400043f0,0x4(%esp)
400039a1:	40 
400039a2:	c7 04 24 80 61 00 40 	movl   $0x40006180,(%esp)
400039a9:	e8 4f fd ff ff       	call   400036fd <sprintf>
	return errbuf;
400039ae:	b8 80 61 00 40       	mov    $0x40006180,%eax
}
400039b3:	c9                   	leave  
400039b4:	c3                   	ret    
400039b5:	66 90                	xchg   %ax,%ax
400039b7:	90                   	nop

400039b8 <cputs>:

#include <inc/stdio.h>
#include <inc/syscall.h>

void cputs(const char *str)
{
400039b8:	55                   	push   %ebp
400039b9:	89 e5                	mov    %esp,%ebp
400039bb:	53                   	push   %ebx
400039bc:	83 ec 10             	sub    $0x10,%esp
400039bf:	8b 45 08             	mov    0x8(%ebp),%eax
400039c2:	89 45 f8             	mov    %eax,-0x8(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
400039c5:	b8 00 00 00 00       	mov    $0x0,%eax
400039ca:	8b 55 f8             	mov    -0x8(%ebp),%edx
400039cd:	89 d3                	mov    %edx,%ebx
400039cf:	cd 30                	int    $0x30
	sys_cputs(str);
}
400039d1:	83 c4 10             	add    $0x10,%esp
400039d4:	5b                   	pop    %ebx
400039d5:	5d                   	pop    %ebp
400039d6:	c3                   	ret    
400039d7:	66 90                	xchg   %ax,%ax
400039d9:	66 90                	xchg   %ax,%ax
400039db:	66 90                	xchg   %ax,%ax
400039dd:	66 90                	xchg   %ax,%ax
400039df:	90                   	nop

400039e0 <__udivdi3>:
400039e0:	83 ec 1c             	sub    $0x1c,%esp
400039e3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
400039e7:	89 7c 24 14          	mov    %edi,0x14(%esp)
400039eb:	8b 4c 24 28          	mov    0x28(%esp),%ecx
400039ef:	89 6c 24 18          	mov    %ebp,0x18(%esp)
400039f3:	8b 7c 24 20          	mov    0x20(%esp),%edi
400039f7:	8b 6c 24 24          	mov    0x24(%esp),%ebp
400039fb:	85 c0                	test   %eax,%eax
400039fd:	89 74 24 10          	mov    %esi,0x10(%esp)
40003a01:	89 7c 24 08          	mov    %edi,0x8(%esp)
40003a05:	89 ea                	mov    %ebp,%edx
40003a07:	89 4c 24 04          	mov    %ecx,0x4(%esp)
40003a0b:	75 33                	jne    40003a40 <__udivdi3+0x60>
40003a0d:	39 e9                	cmp    %ebp,%ecx
40003a0f:	77 6f                	ja     40003a80 <__udivdi3+0xa0>
40003a11:	85 c9                	test   %ecx,%ecx
40003a13:	89 ce                	mov    %ecx,%esi
40003a15:	75 0b                	jne    40003a22 <__udivdi3+0x42>
40003a17:	b8 01 00 00 00       	mov    $0x1,%eax
40003a1c:	31 d2                	xor    %edx,%edx
40003a1e:	f7 f1                	div    %ecx
40003a20:	89 c6                	mov    %eax,%esi
40003a22:	31 d2                	xor    %edx,%edx
40003a24:	89 e8                	mov    %ebp,%eax
40003a26:	f7 f6                	div    %esi
40003a28:	89 c5                	mov    %eax,%ebp
40003a2a:	89 f8                	mov    %edi,%eax
40003a2c:	f7 f6                	div    %esi
40003a2e:	89 ea                	mov    %ebp,%edx
40003a30:	8b 74 24 10          	mov    0x10(%esp),%esi
40003a34:	8b 7c 24 14          	mov    0x14(%esp),%edi
40003a38:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40003a3c:	83 c4 1c             	add    $0x1c,%esp
40003a3f:	c3                   	ret    
40003a40:	39 e8                	cmp    %ebp,%eax
40003a42:	77 24                	ja     40003a68 <__udivdi3+0x88>
40003a44:	0f bd c8             	bsr    %eax,%ecx
40003a47:	83 f1 1f             	xor    $0x1f,%ecx
40003a4a:	89 0c 24             	mov    %ecx,(%esp)
40003a4d:	75 49                	jne    40003a98 <__udivdi3+0xb8>
40003a4f:	8b 74 24 08          	mov    0x8(%esp),%esi
40003a53:	39 74 24 04          	cmp    %esi,0x4(%esp)
40003a57:	0f 86 ab 00 00 00    	jbe    40003b08 <__udivdi3+0x128>
40003a5d:	39 e8                	cmp    %ebp,%eax
40003a5f:	0f 82 a3 00 00 00    	jb     40003b08 <__udivdi3+0x128>
40003a65:	8d 76 00             	lea    0x0(%esi),%esi
40003a68:	31 d2                	xor    %edx,%edx
40003a6a:	31 c0                	xor    %eax,%eax
40003a6c:	8b 74 24 10          	mov    0x10(%esp),%esi
40003a70:	8b 7c 24 14          	mov    0x14(%esp),%edi
40003a74:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40003a78:	83 c4 1c             	add    $0x1c,%esp
40003a7b:	c3                   	ret    
40003a7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003a80:	89 f8                	mov    %edi,%eax
40003a82:	f7 f1                	div    %ecx
40003a84:	31 d2                	xor    %edx,%edx
40003a86:	8b 74 24 10          	mov    0x10(%esp),%esi
40003a8a:	8b 7c 24 14          	mov    0x14(%esp),%edi
40003a8e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40003a92:	83 c4 1c             	add    $0x1c,%esp
40003a95:	c3                   	ret    
40003a96:	66 90                	xchg   %ax,%ax
40003a98:	0f b6 0c 24          	movzbl (%esp),%ecx
40003a9c:	89 c6                	mov    %eax,%esi
40003a9e:	b8 20 00 00 00       	mov    $0x20,%eax
40003aa3:	8b 6c 24 04          	mov    0x4(%esp),%ebp
40003aa7:	2b 04 24             	sub    (%esp),%eax
40003aaa:	8b 7c 24 08          	mov    0x8(%esp),%edi
40003aae:	d3 e6                	shl    %cl,%esi
40003ab0:	89 c1                	mov    %eax,%ecx
40003ab2:	d3 ed                	shr    %cl,%ebp
40003ab4:	0f b6 0c 24          	movzbl (%esp),%ecx
40003ab8:	09 f5                	or     %esi,%ebp
40003aba:	8b 74 24 04          	mov    0x4(%esp),%esi
40003abe:	d3 e6                	shl    %cl,%esi
40003ac0:	89 c1                	mov    %eax,%ecx
40003ac2:	89 74 24 04          	mov    %esi,0x4(%esp)
40003ac6:	89 d6                	mov    %edx,%esi
40003ac8:	d3 ee                	shr    %cl,%esi
40003aca:	0f b6 0c 24          	movzbl (%esp),%ecx
40003ace:	d3 e2                	shl    %cl,%edx
40003ad0:	89 c1                	mov    %eax,%ecx
40003ad2:	d3 ef                	shr    %cl,%edi
40003ad4:	09 d7                	or     %edx,%edi
40003ad6:	89 f2                	mov    %esi,%edx
40003ad8:	89 f8                	mov    %edi,%eax
40003ada:	f7 f5                	div    %ebp
40003adc:	89 d6                	mov    %edx,%esi
40003ade:	89 c7                	mov    %eax,%edi
40003ae0:	f7 64 24 04          	mull   0x4(%esp)
40003ae4:	39 d6                	cmp    %edx,%esi
40003ae6:	72 30                	jb     40003b18 <__udivdi3+0x138>
40003ae8:	8b 6c 24 08          	mov    0x8(%esp),%ebp
40003aec:	0f b6 0c 24          	movzbl (%esp),%ecx
40003af0:	d3 e5                	shl    %cl,%ebp
40003af2:	39 c5                	cmp    %eax,%ebp
40003af4:	73 04                	jae    40003afa <__udivdi3+0x11a>
40003af6:	39 d6                	cmp    %edx,%esi
40003af8:	74 1e                	je     40003b18 <__udivdi3+0x138>
40003afa:	89 f8                	mov    %edi,%eax
40003afc:	31 d2                	xor    %edx,%edx
40003afe:	e9 69 ff ff ff       	jmp    40003a6c <__udivdi3+0x8c>
40003b03:	90                   	nop
40003b04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003b08:	31 d2                	xor    %edx,%edx
40003b0a:	b8 01 00 00 00       	mov    $0x1,%eax
40003b0f:	e9 58 ff ff ff       	jmp    40003a6c <__udivdi3+0x8c>
40003b14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003b18:	8d 47 ff             	lea    -0x1(%edi),%eax
40003b1b:	31 d2                	xor    %edx,%edx
40003b1d:	8b 74 24 10          	mov    0x10(%esp),%esi
40003b21:	8b 7c 24 14          	mov    0x14(%esp),%edi
40003b25:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40003b29:	83 c4 1c             	add    $0x1c,%esp
40003b2c:	c3                   	ret    
40003b2d:	66 90                	xchg   %ax,%ax
40003b2f:	90                   	nop

40003b30 <__umoddi3>:
40003b30:	83 ec 2c             	sub    $0x2c,%esp
40003b33:	8b 44 24 3c          	mov    0x3c(%esp),%eax
40003b37:	8b 4c 24 30          	mov    0x30(%esp),%ecx
40003b3b:	89 74 24 20          	mov    %esi,0x20(%esp)
40003b3f:	8b 74 24 38          	mov    0x38(%esp),%esi
40003b43:	89 7c 24 24          	mov    %edi,0x24(%esp)
40003b47:	8b 7c 24 34          	mov    0x34(%esp),%edi
40003b4b:	85 c0                	test   %eax,%eax
40003b4d:	89 c2                	mov    %eax,%edx
40003b4f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
40003b53:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
40003b57:	89 7c 24 0c          	mov    %edi,0xc(%esp)
40003b5b:	89 74 24 10          	mov    %esi,0x10(%esp)
40003b5f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
40003b63:	89 7c 24 18          	mov    %edi,0x18(%esp)
40003b67:	75 1f                	jne    40003b88 <__umoddi3+0x58>
40003b69:	39 fe                	cmp    %edi,%esi
40003b6b:	76 63                	jbe    40003bd0 <__umoddi3+0xa0>
40003b6d:	89 c8                	mov    %ecx,%eax
40003b6f:	89 fa                	mov    %edi,%edx
40003b71:	f7 f6                	div    %esi
40003b73:	89 d0                	mov    %edx,%eax
40003b75:	31 d2                	xor    %edx,%edx
40003b77:	8b 74 24 20          	mov    0x20(%esp),%esi
40003b7b:	8b 7c 24 24          	mov    0x24(%esp),%edi
40003b7f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
40003b83:	83 c4 2c             	add    $0x2c,%esp
40003b86:	c3                   	ret    
40003b87:	90                   	nop
40003b88:	39 f8                	cmp    %edi,%eax
40003b8a:	77 64                	ja     40003bf0 <__umoddi3+0xc0>
40003b8c:	0f bd e8             	bsr    %eax,%ebp
40003b8f:	83 f5 1f             	xor    $0x1f,%ebp
40003b92:	75 74                	jne    40003c08 <__umoddi3+0xd8>
40003b94:	8b 7c 24 14          	mov    0x14(%esp),%edi
40003b98:	39 7c 24 10          	cmp    %edi,0x10(%esp)
40003b9c:	0f 87 0e 01 00 00    	ja     40003cb0 <__umoddi3+0x180>
40003ba2:	8b 7c 24 0c          	mov    0xc(%esp),%edi
40003ba6:	29 f1                	sub    %esi,%ecx
40003ba8:	19 c7                	sbb    %eax,%edi
40003baa:	89 4c 24 14          	mov    %ecx,0x14(%esp)
40003bae:	89 7c 24 18          	mov    %edi,0x18(%esp)
40003bb2:	8b 44 24 14          	mov    0x14(%esp),%eax
40003bb6:	8b 54 24 18          	mov    0x18(%esp),%edx
40003bba:	8b 74 24 20          	mov    0x20(%esp),%esi
40003bbe:	8b 7c 24 24          	mov    0x24(%esp),%edi
40003bc2:	8b 6c 24 28          	mov    0x28(%esp),%ebp
40003bc6:	83 c4 2c             	add    $0x2c,%esp
40003bc9:	c3                   	ret    
40003bca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
40003bd0:	85 f6                	test   %esi,%esi
40003bd2:	89 f5                	mov    %esi,%ebp
40003bd4:	75 0b                	jne    40003be1 <__umoddi3+0xb1>
40003bd6:	b8 01 00 00 00       	mov    $0x1,%eax
40003bdb:	31 d2                	xor    %edx,%edx
40003bdd:	f7 f6                	div    %esi
40003bdf:	89 c5                	mov    %eax,%ebp
40003be1:	8b 44 24 0c          	mov    0xc(%esp),%eax
40003be5:	31 d2                	xor    %edx,%edx
40003be7:	f7 f5                	div    %ebp
40003be9:	89 c8                	mov    %ecx,%eax
40003beb:	f7 f5                	div    %ebp
40003bed:	eb 84                	jmp    40003b73 <__umoddi3+0x43>
40003bef:	90                   	nop
40003bf0:	89 c8                	mov    %ecx,%eax
40003bf2:	89 fa                	mov    %edi,%edx
40003bf4:	8b 74 24 20          	mov    0x20(%esp),%esi
40003bf8:	8b 7c 24 24          	mov    0x24(%esp),%edi
40003bfc:	8b 6c 24 28          	mov    0x28(%esp),%ebp
40003c00:	83 c4 2c             	add    $0x2c,%esp
40003c03:	c3                   	ret    
40003c04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003c08:	8b 44 24 10          	mov    0x10(%esp),%eax
40003c0c:	be 20 00 00 00       	mov    $0x20,%esi
40003c11:	89 e9                	mov    %ebp,%ecx
40003c13:	29 ee                	sub    %ebp,%esi
40003c15:	d3 e2                	shl    %cl,%edx
40003c17:	89 f1                	mov    %esi,%ecx
40003c19:	d3 e8                	shr    %cl,%eax
40003c1b:	89 e9                	mov    %ebp,%ecx
40003c1d:	09 d0                	or     %edx,%eax
40003c1f:	89 fa                	mov    %edi,%edx
40003c21:	89 44 24 0c          	mov    %eax,0xc(%esp)
40003c25:	8b 44 24 10          	mov    0x10(%esp),%eax
40003c29:	d3 e0                	shl    %cl,%eax
40003c2b:	89 f1                	mov    %esi,%ecx
40003c2d:	89 44 24 10          	mov    %eax,0x10(%esp)
40003c31:	8b 44 24 1c          	mov    0x1c(%esp),%eax
40003c35:	d3 ea                	shr    %cl,%edx
40003c37:	89 e9                	mov    %ebp,%ecx
40003c39:	d3 e7                	shl    %cl,%edi
40003c3b:	89 f1                	mov    %esi,%ecx
40003c3d:	d3 e8                	shr    %cl,%eax
40003c3f:	89 e9                	mov    %ebp,%ecx
40003c41:	09 f8                	or     %edi,%eax
40003c43:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
40003c47:	f7 74 24 0c          	divl   0xc(%esp)
40003c4b:	d3 e7                	shl    %cl,%edi
40003c4d:	89 7c 24 18          	mov    %edi,0x18(%esp)
40003c51:	89 d7                	mov    %edx,%edi
40003c53:	f7 64 24 10          	mull   0x10(%esp)
40003c57:	39 d7                	cmp    %edx,%edi
40003c59:	89 c1                	mov    %eax,%ecx
40003c5b:	89 54 24 14          	mov    %edx,0x14(%esp)
40003c5f:	72 3b                	jb     40003c9c <__umoddi3+0x16c>
40003c61:	39 44 24 18          	cmp    %eax,0x18(%esp)
40003c65:	72 31                	jb     40003c98 <__umoddi3+0x168>
40003c67:	8b 44 24 18          	mov    0x18(%esp),%eax
40003c6b:	29 c8                	sub    %ecx,%eax
40003c6d:	19 d7                	sbb    %edx,%edi
40003c6f:	89 e9                	mov    %ebp,%ecx
40003c71:	89 fa                	mov    %edi,%edx
40003c73:	d3 e8                	shr    %cl,%eax
40003c75:	89 f1                	mov    %esi,%ecx
40003c77:	d3 e2                	shl    %cl,%edx
40003c79:	89 e9                	mov    %ebp,%ecx
40003c7b:	09 d0                	or     %edx,%eax
40003c7d:	89 fa                	mov    %edi,%edx
40003c7f:	d3 ea                	shr    %cl,%edx
40003c81:	8b 74 24 20          	mov    0x20(%esp),%esi
40003c85:	8b 7c 24 24          	mov    0x24(%esp),%edi
40003c89:	8b 6c 24 28          	mov    0x28(%esp),%ebp
40003c8d:	83 c4 2c             	add    $0x2c,%esp
40003c90:	c3                   	ret    
40003c91:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
40003c98:	39 d7                	cmp    %edx,%edi
40003c9a:	75 cb                	jne    40003c67 <__umoddi3+0x137>
40003c9c:	8b 54 24 14          	mov    0x14(%esp),%edx
40003ca0:	89 c1                	mov    %eax,%ecx
40003ca2:	2b 4c 24 10          	sub    0x10(%esp),%ecx
40003ca6:	1b 54 24 0c          	sbb    0xc(%esp),%edx
40003caa:	eb bb                	jmp    40003c67 <__umoddi3+0x137>
40003cac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003cb0:	3b 44 24 18          	cmp    0x18(%esp),%eax
40003cb4:	0f 82 e8 fe ff ff    	jb     40003ba2 <__umoddi3+0x72>
40003cba:	e9 f3 fe ff ff       	jmp    40003bb2 <__umoddi3+0x82>
