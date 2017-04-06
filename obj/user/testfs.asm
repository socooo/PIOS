
obj/user/testfs:     file format elf32-i386


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
4000010c:	e8 3d 24 00 00       	call   4000254e <main>
	pushl	%eax	// use with main's return value as exit status
40000111:	50                   	push   %eax
	call	exit
40000112:	e8 d9 4f 00 00       	call   400050f0 <exit>
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

40000144 <initfilecheck>:

int initfilecheck_count;

void
initfilecheck()
{
40000144:	55                   	push   %ebp
40000145:	89 e5                	mov    %esp,%ebp
40000147:	53                   	push   %ebx
40000148:	83 ec 24             	sub    $0x24,%esp
	// Manually go through the inodes looking for populated files
	int ino, count = 0, shino = 0, lsino = 0;
4000014b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
40000152:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
40000159:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
	for (ino = 1; ino < FILE_INODES; ino++) {
40000160:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
40000167:	e9 52 02 00 00       	jmp    400003be <initfilecheck+0x27a>
		if (files->fi[ino].de.d_name[0] == 0)
4000016c:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40000172:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000175:	6b c0 5c             	imul   $0x5c,%eax,%eax
40000178:	01 d0                	add    %edx,%eax
4000017a:	05 10 10 00 00       	add    $0x1010,%eax
4000017f:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40000183:	84 c0                	test   %al,%al
40000185:	0f 84 45 02 00 00    	je     400003d0 <initfilecheck+0x28c>
			break;		// first unused entry

		cprintf("initfilecheck: found file '%s' mode 0x%x size %d\n",
			files->fi[ino].de.d_name, files->fi[ino].mode,
			files->fi[ino].size);
4000018b:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
	int ino, count = 0, shino = 0, lsino = 0;
	for (ino = 1; ino < FILE_INODES; ino++) {
		if (files->fi[ino].de.d_name[0] == 0)
			break;		// first unused entry

		cprintf("initfilecheck: found file '%s' mode 0x%x size %d\n",
40000191:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000194:	6b c0 5c             	imul   $0x5c,%eax,%eax
40000197:	01 d0                	add    %edx,%eax
40000199:	05 5c 10 00 00       	add    $0x105c,%eax
4000019e:	8b 10                	mov    (%eax),%edx
			files->fi[ino].de.d_name, files->fi[ino].mode,
400001a0:	8b 0d 8c 80 00 40    	mov    0x4000808c,%ecx
	int ino, count = 0, shino = 0, lsino = 0;
	for (ino = 1; ino < FILE_INODES; ino++) {
		if (files->fi[ino].de.d_name[0] == 0)
			break;		// first unused entry

		cprintf("initfilecheck: found file '%s' mode 0x%x size %d\n",
400001a6:	8b 45 f4             	mov    -0xc(%ebp),%eax
400001a9:	6b c0 5c             	imul   $0x5c,%eax,%eax
400001ac:	01 c8                	add    %ecx,%eax
400001ae:	05 58 10 00 00       	add    $0x1058,%eax
400001b3:	8b 00                	mov    (%eax),%eax
			files->fi[ino].de.d_name, files->fi[ino].mode,
400001b5:	8b 0d 8c 80 00 40    	mov    0x4000808c,%ecx
400001bb:	8b 5d f4             	mov    -0xc(%ebp),%ebx
400001be:	6b db 5c             	imul   $0x5c,%ebx,%ebx
400001c1:	81 c3 10 10 00 00    	add    $0x1010,%ebx
400001c7:	01 d9                	add    %ebx,%ecx
400001c9:	83 c1 04             	add    $0x4,%ecx
	int ino, count = 0, shino = 0, lsino = 0;
	for (ino = 1; ino < FILE_INODES; ino++) {
		if (files->fi[ino].de.d_name[0] == 0)
			break;		// first unused entry

		cprintf("initfilecheck: found file '%s' mode 0x%x size %d\n",
400001cc:	89 54 24 0c          	mov    %edx,0xc(%esp)
400001d0:	89 44 24 08          	mov    %eax,0x8(%esp)
400001d4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
400001d8:	c7 04 24 20 75 00 40 	movl   $0x40007520,(%esp)
400001df:	e8 94 26 00 00       	call   40002878 <cprintf>
			files->fi[ino].de.d_name, files->fi[ino].mode,
			files->fi[ino].size);

		// Make sure general properties are as we expect
		assert(files->fi[ino].ver == 0);
400001e4:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
400001ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
400001ed:	6b c0 5c             	imul   $0x5c,%eax,%eax
400001f0:	01 d0                	add    %edx,%eax
400001f2:	05 54 10 00 00       	add    $0x1054,%eax
400001f7:	8b 00                	mov    (%eax),%eax
400001f9:	85 c0                	test   %eax,%eax
400001fb:	74 24                	je     40000221 <initfilecheck+0xdd>
400001fd:	c7 44 24 0c 52 75 00 	movl   $0x40007552,0xc(%esp)
40000204:	40 
40000205:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
4000020c:	40 
4000020d:	c7 44 24 04 27 00 00 	movl   $0x27,0x4(%esp)
40000214:	00 
40000215:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
4000021c:	e8 c3 23 00 00       	call   400025e4 <debug_panic>
		if (ino >= FILEINO_GENERAL) {
40000221:	83 7d f4 03          	cmpl   $0x3,-0xc(%ebp)
40000225:	0f 8e bb 00 00 00    	jle    400002e6 <initfilecheck+0x1a2>
			// initfiles are all in the root directory
			assert(files->fi[ino].dino == FILEINO_ROOTDIR);
4000022b:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40000231:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000234:	6b c0 5c             	imul   $0x5c,%eax,%eax
40000237:	01 d0                	add    %edx,%eax
40000239:	05 10 10 00 00       	add    $0x1010,%eax
4000023e:	8b 00                	mov    (%eax),%eax
40000240:	83 f8 03             	cmp    $0x3,%eax
40000243:	74 24                	je     40000269 <initfilecheck+0x125>
40000245:	c7 44 24 0c 90 75 00 	movl   $0x40007590,0xc(%esp)
4000024c:	40 
4000024d:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000254:	40 
40000255:	c7 44 24 04 2a 00 00 	movl   $0x2a,0x4(%esp)
4000025c:	00 
4000025d:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000264:	e8 7b 23 00 00       	call   400025e4 <debug_panic>
			// initfiles are all regular files
			assert(files->fi[ino].mode == S_IFREG);
40000269:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
4000026f:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000272:	6b c0 5c             	imul   $0x5c,%eax,%eax
40000275:	01 d0                	add    %edx,%eax
40000277:	05 58 10 00 00       	add    $0x1058,%eax
4000027c:	8b 00                	mov    (%eax),%eax
4000027e:	3d 00 10 00 00       	cmp    $0x1000,%eax
40000283:	74 24                	je     400002a9 <initfilecheck+0x165>
40000285:	c7 44 24 0c b8 75 00 	movl   $0x400075b8,0xc(%esp)
4000028c:	40 
4000028d:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000294:	40 
40000295:	c7 44 24 04 2c 00 00 	movl   $0x2c,0x4(%esp)
4000029c:	00 
4000029d:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400002a4:	e8 3b 23 00 00       	call   400025e4 <debug_panic>
			// and should all contain some file data
			assert(files->fi[ino].size > 0);
400002a9:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
400002af:	8b 45 f4             	mov    -0xc(%ebp),%eax
400002b2:	6b c0 5c             	imul   $0x5c,%eax,%eax
400002b5:	01 d0                	add    %edx,%eax
400002b7:	05 5c 10 00 00       	add    $0x105c,%eax
400002bc:	8b 00                	mov    (%eax),%eax
400002be:	85 c0                	test   %eax,%eax
400002c0:	75 24                	jne    400002e6 <initfilecheck+0x1a2>
400002c2:	c7 44 24 0c d7 75 00 	movl   $0x400075d7,0xc(%esp)
400002c9:	40 
400002ca:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400002d1:	40 
400002d2:	c7 44 24 04 2e 00 00 	movl   $0x2e,0x4(%esp)
400002d9:	00 
400002da:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400002e1:	e8 fe 22 00 00       	call   400025e4 <debug_panic>
		}

		// Make sure a couple specific files we're expecting show up
		if (strcmp(files->fi[ino].de.d_name, "sh") == 0) {
400002e6:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400002eb:	8b 55 f4             	mov    -0xc(%ebp),%edx
400002ee:	6b d2 5c             	imul   $0x5c,%edx,%edx
400002f1:	81 c2 10 10 00 00    	add    $0x1010,%edx
400002f7:	01 d0                	add    %edx,%eax
400002f9:	83 c0 04             	add    $0x4,%eax
400002fc:	c7 44 24 04 ef 75 00 	movl   $0x400075ef,0x4(%esp)
40000303:	40 
40000304:	89 04 24             	mov    %eax,(%esp)
40000307:	e8 38 2d 00 00       	call   40003044 <strcmp>
4000030c:	85 c0                	test   %eax,%eax
4000030e:	75 3e                	jne    4000034e <initfilecheck+0x20a>
			// contents should be an ELF executable!
			assert(*(int*)FILEDATA(ino) == ELF_MAGIC);
40000310:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000313:	c1 e0 16             	shl    $0x16,%eax
40000316:	05 00 00 00 80       	add    $0x80000000,%eax
4000031b:	8b 00                	mov    (%eax),%eax
4000031d:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
40000322:	74 24                	je     40000348 <initfilecheck+0x204>
40000324:	c7 44 24 0c f4 75 00 	movl   $0x400075f4,0xc(%esp)
4000032b:	40 
4000032c:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000333:	40 
40000334:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
4000033b:	00 
4000033c:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000343:	e8 9c 22 00 00       	call   400025e4 <debug_panic>
			shino = ino;
40000348:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000034b:	89 45 ec             	mov    %eax,-0x14(%ebp)
		}
		if (strcmp(files->fi[ino].de.d_name, "ls") == 0) {
4000034e:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40000353:	8b 55 f4             	mov    -0xc(%ebp),%edx
40000356:	6b d2 5c             	imul   $0x5c,%edx,%edx
40000359:	81 c2 10 10 00 00    	add    $0x1010,%edx
4000035f:	01 d0                	add    %edx,%eax
40000361:	83 c0 04             	add    $0x4,%eax
40000364:	c7 44 24 04 16 76 00 	movl   $0x40007616,0x4(%esp)
4000036b:	40 
4000036c:	89 04 24             	mov    %eax,(%esp)
4000036f:	e8 d0 2c 00 00       	call   40003044 <strcmp>
40000374:	85 c0                	test   %eax,%eax
40000376:	75 3e                	jne    400003b6 <initfilecheck+0x272>
			// contents should be an ELF executable!
			assert(*(int*)FILEDATA(ino) == ELF_MAGIC);
40000378:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000037b:	c1 e0 16             	shl    $0x16,%eax
4000037e:	05 00 00 00 80       	add    $0x80000000,%eax
40000383:	8b 00                	mov    (%eax),%eax
40000385:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
4000038a:	74 24                	je     400003b0 <initfilecheck+0x26c>
4000038c:	c7 44 24 0c f4 75 00 	movl   $0x400075f4,0xc(%esp)
40000393:	40 
40000394:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
4000039b:	40 
4000039c:	c7 44 24 04 39 00 00 	movl   $0x39,0x4(%esp)
400003a3:	00 
400003a4:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400003ab:	e8 34 22 00 00       	call   400025e4 <debug_panic>
			lsino = ino;
400003b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
400003b3:	89 45 e8             	mov    %eax,-0x18(%ebp)
		}

		count++;
400003b6:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
void
initfilecheck()
{
	// Manually go through the inodes looking for populated files
	int ino, count = 0, shino = 0, lsino = 0;
	for (ino = 1; ino < FILE_INODES; ino++) {
400003ba:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
400003be:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
400003c5:	0f 8e a1 fd ff ff    	jle    4000016c <initfilecheck+0x28>
			lsino = ino;
		}

		count++;
	}
	for (; ino < FILE_INODES; ino++) {
400003cb:	e9 3d 01 00 00       	jmp    4000050d <initfilecheck+0x3c9>
{
	// Manually go through the inodes looking for populated files
	int ino, count = 0, shino = 0, lsino = 0;
	for (ino = 1; ino < FILE_INODES; ino++) {
		if (files->fi[ino].de.d_name[0] == 0)
			break;		// first unused entry
400003d0:	90                   	nop
			lsino = ino;
		}

		count++;
	}
	for (; ino < FILE_INODES; ino++) {
400003d1:	e9 37 01 00 00       	jmp    4000050d <initfilecheck+0x3c9>
		// all the rest of the inodes should be empty
		assert(files->fi[ino].dino == FILEINO_NULL);
400003d6:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
400003dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
400003df:	6b c0 5c             	imul   $0x5c,%eax,%eax
400003e2:	01 d0                	add    %edx,%eax
400003e4:	05 10 10 00 00       	add    $0x1010,%eax
400003e9:	8b 00                	mov    (%eax),%eax
400003eb:	85 c0                	test   %eax,%eax
400003ed:	74 24                	je     40000413 <initfilecheck+0x2cf>
400003ef:	c7 44 24 0c 1c 76 00 	movl   $0x4000761c,0xc(%esp)
400003f6:	40 
400003f7:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400003fe:	40 
400003ff:	c7 44 24 04 41 00 00 	movl   $0x41,0x4(%esp)
40000406:	00 
40000407:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
4000040e:	e8 d1 21 00 00       	call   400025e4 <debug_panic>
		assert(files->fi[ino].de.d_name[0] == 0);
40000413:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40000419:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000041c:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000041f:	01 d0                	add    %edx,%eax
40000421:	05 10 10 00 00       	add    $0x1010,%eax
40000426:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000042a:	84 c0                	test   %al,%al
4000042c:	74 24                	je     40000452 <initfilecheck+0x30e>
4000042e:	c7 44 24 0c 40 76 00 	movl   $0x40007640,0xc(%esp)
40000435:	40 
40000436:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
4000043d:	40 
4000043e:	c7 44 24 04 42 00 00 	movl   $0x42,0x4(%esp)
40000445:	00 
40000446:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
4000044d:	e8 92 21 00 00       	call   400025e4 <debug_panic>
		assert(files->fi[ino].ver == 0);
40000452:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40000458:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000045b:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000045e:	01 d0                	add    %edx,%eax
40000460:	05 54 10 00 00       	add    $0x1054,%eax
40000465:	8b 00                	mov    (%eax),%eax
40000467:	85 c0                	test   %eax,%eax
40000469:	74 24                	je     4000048f <initfilecheck+0x34b>
4000046b:	c7 44 24 0c 52 75 00 	movl   $0x40007552,0xc(%esp)
40000472:	40 
40000473:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
4000047a:	40 
4000047b:	c7 44 24 04 43 00 00 	movl   $0x43,0x4(%esp)
40000482:	00 
40000483:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
4000048a:	e8 55 21 00 00       	call   400025e4 <debug_panic>
		assert(files->fi[ino].mode == 0);
4000048f:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40000495:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000498:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000049b:	01 d0                	add    %edx,%eax
4000049d:	05 58 10 00 00       	add    $0x1058,%eax
400004a2:	8b 00                	mov    (%eax),%eax
400004a4:	85 c0                	test   %eax,%eax
400004a6:	74 24                	je     400004cc <initfilecheck+0x388>
400004a8:	c7 44 24 0c 61 76 00 	movl   $0x40007661,0xc(%esp)
400004af:	40 
400004b0:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400004b7:	40 
400004b8:	c7 44 24 04 44 00 00 	movl   $0x44,0x4(%esp)
400004bf:	00 
400004c0:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400004c7:	e8 18 21 00 00       	call   400025e4 <debug_panic>
		assert(files->fi[ino].size == 0);
400004cc:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
400004d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
400004d5:	6b c0 5c             	imul   $0x5c,%eax,%eax
400004d8:	01 d0                	add    %edx,%eax
400004da:	05 5c 10 00 00       	add    $0x105c,%eax
400004df:	8b 00                	mov    (%eax),%eax
400004e1:	85 c0                	test   %eax,%eax
400004e3:	74 24                	je     40000509 <initfilecheck+0x3c5>
400004e5:	c7 44 24 0c 7a 76 00 	movl   $0x4000767a,0xc(%esp)
400004ec:	40 
400004ed:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400004f4:	40 
400004f5:	c7 44 24 04 45 00 00 	movl   $0x45,0x4(%esp)
400004fc:	00 
400004fd:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000504:	e8 db 20 00 00       	call   400025e4 <debug_panic>
			lsino = ino;
		}

		count++;
	}
	for (; ino < FILE_INODES; ino++) {
40000509:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
4000050d:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
40000514:	0f 8e bc fe ff ff    	jle    400003d6 <initfilecheck+0x292>
		assert(files->fi[ino].mode == 0);
		assert(files->fi[ino].size == 0);
	}

	// Make sure we found a "reasonable" number of populated entries
	assert(count >= 5);
4000051a:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
4000051e:	7f 24                	jg     40000544 <initfilecheck+0x400>
40000520:	c7 44 24 0c 93 76 00 	movl   $0x40007693,0xc(%esp)
40000527:	40 
40000528:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
4000052f:	40 
40000530:	c7 44 24 04 49 00 00 	movl   $0x49,0x4(%esp)
40000537:	00 
40000538:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
4000053f:	e8 a0 20 00 00       	call   400025e4 <debug_panic>
	assert(shino != 0);
40000544:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
40000548:	75 24                	jne    4000056e <initfilecheck+0x42a>
4000054a:	c7 44 24 0c 9e 76 00 	movl   $0x4000769e,0xc(%esp)
40000551:	40 
40000552:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000559:	40 
4000055a:	c7 44 24 04 4a 00 00 	movl   $0x4a,0x4(%esp)
40000561:	00 
40000562:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000569:	e8 76 20 00 00       	call   400025e4 <debug_panic>
	assert(lsino != 0);
4000056e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
40000572:	75 24                	jne    40000598 <initfilecheck+0x454>
40000574:	c7 44 24 0c a9 76 00 	movl   $0x400076a9,0xc(%esp)
4000057b:	40 
4000057c:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000583:	40 
40000584:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
4000058b:	00 
4000058c:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000593:	e8 4c 20 00 00       	call   400025e4 <debug_panic>
	initfilecheck_count = count;	// save for readdircheck
40000598:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000059b:	a3 80 dc 00 40       	mov    %eax,0x4000dc80

	cprintf("initfilecheck passed\n");
400005a0:	c7 04 24 b4 76 00 40 	movl   $0x400076b4,(%esp)
400005a7:	e8 cc 22 00 00       	call   40002878 <cprintf>
}
400005ac:	83 c4 24             	add    $0x24,%esp
400005af:	5b                   	pop    %ebx
400005b0:	5d                   	pop    %ebp
400005b1:	c3                   	ret    

400005b2 <readwritecheck>:

void
readwritecheck()
{
400005b2:	55                   	push   %ebp
400005b3:	89 e5                	mov    %esp,%ebp
400005b5:	83 ec 48             	sub    $0x48,%esp
	static char buf2[2048];	// a buffer to use for reading/writing data
	static const char zeros[1024];	// a buffer of all zeros

	// Get the initial file size etc.
	struct stat st;
	int rc = stat("ls", &st); assert(rc >= 0);
400005b8:	8d 45 dc             	lea    -0x24(%ebp),%eax
400005bb:	89 44 24 04          	mov    %eax,0x4(%esp)
400005bf:	c7 04 24 16 76 00 40 	movl   $0x40007616,(%esp)
400005c6:	e8 a6 4f 00 00       	call   40005571 <stat>
400005cb:	89 45 f4             	mov    %eax,-0xc(%ebp)
400005ce:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
400005d2:	79 24                	jns    400005f8 <readwritecheck+0x46>
400005d4:	c7 44 24 0c ca 76 00 	movl   $0x400076ca,0xc(%esp)
400005db:	40 
400005dc:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400005e3:	40 
400005e4:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
400005eb:	00 
400005ec:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400005f3:	e8 ec 1f 00 00       	call   400025e4 <debug_panic>
	assert(S_ISREG(st.st_mode));
400005f8:	8b 45 e0             	mov    -0x20(%ebp),%eax
400005fb:	25 00 70 00 00       	and    $0x7000,%eax
40000600:	3d 00 10 00 00       	cmp    $0x1000,%eax
40000605:	74 24                	je     4000062b <readwritecheck+0x79>
40000607:	c7 44 24 0c d2 76 00 	movl   $0x400076d2,0xc(%esp)
4000060e:	40 
4000060f:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000616:	40 
40000617:	c7 44 24 04 5b 00 00 	movl   $0x5b,0x4(%esp)
4000061e:	00 
4000061f:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000626:	e8 b9 1f 00 00       	call   400025e4 <debug_panic>
	assert(st.st_size > 0);
4000062b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000062e:	85 c0                	test   %eax,%eax
40000630:	7f 24                	jg     40000656 <readwritecheck+0xa4>
40000632:	c7 44 24 0c e6 76 00 	movl   $0x400076e6,0xc(%esp)
40000639:	40 
4000063a:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000641:	40 
40000642:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
40000649:	00 
4000064a:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000651:	e8 8e 1f 00 00       	call   400025e4 <debug_panic>

	// Read the first 1KB of one of the initial files,
	// make sure it looks reasonable.
	int fd = open("ls", O_RDONLY); assert(fd > 0);
40000656:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
4000065d:	00 
4000065e:	c7 04 24 16 76 00 40 	movl   $0x40007616,(%esp)
40000665:	e8 fc 4a 00 00       	call   40005166 <open>
4000066a:	89 45 f0             	mov    %eax,-0x10(%ebp)
4000066d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40000671:	7f 24                	jg     40000697 <readwritecheck+0xe5>
40000673:	c7 44 24 0c f5 76 00 	movl   $0x400076f5,0xc(%esp)
4000067a:	40 
4000067b:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000682:	40 
40000683:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
4000068a:	00 
4000068b:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000692:	e8 4d 1f 00 00       	call   400025e4 <debug_panic>
	ssize_t act = read(fd, buf, 2048);
40000697:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
4000069e:	00 
4000069f:	c7 44 24 04 40 c4 00 	movl   $0x4000c440,0x4(%esp)
400006a6:	40 
400006a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
400006aa:	89 04 24             	mov    %eax,(%esp)
400006ad:	e8 4f 4b 00 00       	call   40005201 <read>
400006b2:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(act == 2048);
400006b5:	81 7d ec 00 08 00 00 	cmpl   $0x800,-0x14(%ebp)
400006bc:	74 24                	je     400006e2 <readwritecheck+0x130>
400006be:	c7 44 24 0c fc 76 00 	movl   $0x400076fc,0xc(%esp)
400006c5:	40 
400006c6:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400006cd:	40 
400006ce:	c7 44 24 04 62 00 00 	movl   $0x62,0x4(%esp)
400006d5:	00 
400006d6:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400006dd:	e8 02 1f 00 00       	call   400025e4 <debug_panic>
	elfhdr *eh = (elfhdr*) buf;
400006e2:	c7 45 e8 40 c4 00 40 	movl   $0x4000c440,-0x18(%ebp)
	assert(eh->e_magic == ELF_MAGIC); // should be an ELF file
400006e9:	8b 45 e8             	mov    -0x18(%ebp),%eax
400006ec:	8b 00                	mov    (%eax),%eax
400006ee:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
400006f3:	74 24                	je     40000719 <readwritecheck+0x167>
400006f5:	c7 44 24 0c 08 77 00 	movl   $0x40007708,0xc(%esp)
400006fc:	40 
400006fd:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000704:	40 
40000705:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
4000070c:	00 
4000070d:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000714:	e8 cb 1e 00 00       	call   400025e4 <debug_panic>
	close(fd);
40000719:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000071c:	89 04 24             	mov    %eax,(%esp)
4000071f:	e8 b8 4a 00 00       	call   400051dc <close>

	// Overwrite the first 1K with zeros.
	fd = open("ls", O_WRONLY); assert(fd > 0);
40000724:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
4000072b:	00 
4000072c:	c7 04 24 16 76 00 40 	movl   $0x40007616,(%esp)
40000733:	e8 2e 4a 00 00       	call   40005166 <open>
40000738:	89 45 f0             	mov    %eax,-0x10(%ebp)
4000073b:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
4000073f:	7f 24                	jg     40000765 <readwritecheck+0x1b3>
40000741:	c7 44 24 0c f5 76 00 	movl   $0x400076f5,0xc(%esp)
40000748:	40 
40000749:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000750:	40 
40000751:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
40000758:	00 
40000759:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000760:	e8 7f 1e 00 00       	call   400025e4 <debug_panic>
	act = write(fd, zeros, 1024);
40000765:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
4000076c:	00 
4000076d:	c7 44 24 04 40 cc 00 	movl   $0x4000cc40,0x4(%esp)
40000774:	40 
40000775:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000778:	89 04 24             	mov    %eax,(%esp)
4000077b:	e8 b7 4a 00 00       	call   40005237 <write>
40000780:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(act == 1024);
40000783:	81 7d ec 00 04 00 00 	cmpl   $0x400,-0x14(%ebp)
4000078a:	74 24                	je     400007b0 <readwritecheck+0x1fe>
4000078c:	c7 44 24 0c 21 77 00 	movl   $0x40007721,0xc(%esp)
40000793:	40 
40000794:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
4000079b:	40 
4000079c:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
400007a3:	00 
400007a4:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400007ab:	e8 34 1e 00 00       	call   400025e4 <debug_panic>
	close(fd);
400007b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
400007b3:	89 04 24             	mov    %eax,(%esp)
400007b6:	e8 21 4a 00 00       	call   400051dc <close>

	// Re-read the first 2KB, make sure the right thing happened
	fd = open("ls", O_RDONLY); assert(fd > 0);
400007bb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400007c2:	00 
400007c3:	c7 04 24 16 76 00 40 	movl   $0x40007616,(%esp)
400007ca:	e8 97 49 00 00       	call   40005166 <open>
400007cf:	89 45 f0             	mov    %eax,-0x10(%ebp)
400007d2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400007d6:	7f 24                	jg     400007fc <readwritecheck+0x24a>
400007d8:	c7 44 24 0c f5 76 00 	movl   $0x400076f5,0xc(%esp)
400007df:	40 
400007e0:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400007e7:	40 
400007e8:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
400007ef:	00 
400007f0:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400007f7:	e8 e8 1d 00 00       	call   400025e4 <debug_panic>
	act = read(fd, buf2, 2048);
400007fc:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
40000803:	00 
40000804:	c7 44 24 04 40 d0 00 	movl   $0x4000d040,0x4(%esp)
4000080b:	40 
4000080c:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000080f:	89 04 24             	mov    %eax,(%esp)
40000812:	e8 ea 49 00 00       	call   40005201 <read>
40000817:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(act == 2048);
4000081a:	81 7d ec 00 08 00 00 	cmpl   $0x800,-0x14(%ebp)
40000821:	74 24                	je     40000847 <readwritecheck+0x295>
40000823:	c7 44 24 0c fc 76 00 	movl   $0x400076fc,0xc(%esp)
4000082a:	40 
4000082b:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000832:	40 
40000833:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
4000083a:	00 
4000083b:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000842:	e8 9d 1d 00 00       	call   400025e4 <debug_panic>
	assert(memcmp(buf2, zeros, 1024) == 0); // first 1K should be all zero
40000847:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
4000084e:	00 
4000084f:	c7 44 24 04 40 cc 00 	movl   $0x4000cc40,0x4(%esp)
40000856:	40 
40000857:	c7 04 24 40 d0 00 40 	movl   $0x4000d040,(%esp)
4000085e:	e8 1b 2a 00 00       	call   4000327e <memcmp>
40000863:	85 c0                	test   %eax,%eax
40000865:	74 24                	je     4000088b <readwritecheck+0x2d9>
40000867:	c7 44 24 0c 30 77 00 	movl   $0x40007730,0xc(%esp)
4000086e:	40 
4000086f:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000876:	40 
40000877:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
4000087e:	00 
4000087f:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000886:	e8 59 1d 00 00       	call   400025e4 <debug_panic>
	assert(memcmp(buf2+1024, buf+1024, 1024) == 0); // rest is untouched
4000088b:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
40000892:	00 
40000893:	c7 44 24 04 40 c8 00 	movl   $0x4000c840,0x4(%esp)
4000089a:	40 
4000089b:	c7 04 24 40 d4 00 40 	movl   $0x4000d440,(%esp)
400008a2:	e8 d7 29 00 00       	call   4000327e <memcmp>
400008a7:	85 c0                	test   %eax,%eax
400008a9:	74 24                	je     400008cf <readwritecheck+0x31d>
400008ab:	c7 44 24 0c 50 77 00 	movl   $0x40007750,0xc(%esp)
400008b2:	40 
400008b3:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400008ba:	40 
400008bb:	c7 44 24 04 72 00 00 	movl   $0x72,0x4(%esp)
400008c2:	00 
400008c3:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400008ca:	e8 15 1d 00 00       	call   400025e4 <debug_panic>
	close(fd);
400008cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
400008d2:	89 04 24             	mov    %eax,(%esp)
400008d5:	e8 02 49 00 00       	call   400051dc <close>

	// Restore the first 1K of the file to its initial condition
	fd = open("ls", O_WRONLY); assert(fd > 0);
400008da:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
400008e1:	00 
400008e2:	c7 04 24 16 76 00 40 	movl   $0x40007616,(%esp)
400008e9:	e8 78 48 00 00       	call   40005166 <open>
400008ee:	89 45 f0             	mov    %eax,-0x10(%ebp)
400008f1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400008f5:	7f 24                	jg     4000091b <readwritecheck+0x369>
400008f7:	c7 44 24 0c f5 76 00 	movl   $0x400076f5,0xc(%esp)
400008fe:	40 
400008ff:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000906:	40 
40000907:	c7 44 24 04 76 00 00 	movl   $0x76,0x4(%esp)
4000090e:	00 
4000090f:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000916:	e8 c9 1c 00 00       	call   400025e4 <debug_panic>
	act = write(fd, buf, 1024);
4000091b:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
40000922:	00 
40000923:	c7 44 24 04 40 c4 00 	movl   $0x4000c440,0x4(%esp)
4000092a:	40 
4000092b:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000092e:	89 04 24             	mov    %eax,(%esp)
40000931:	e8 01 49 00 00       	call   40005237 <write>
40000936:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(act == 1024);
40000939:	81 7d ec 00 04 00 00 	cmpl   $0x400,-0x14(%ebp)
40000940:	74 24                	je     40000966 <readwritecheck+0x3b4>
40000942:	c7 44 24 0c 21 77 00 	movl   $0x40007721,0xc(%esp)
40000949:	40 
4000094a:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000951:	40 
40000952:	c7 44 24 04 78 00 00 	movl   $0x78,0x4(%esp)
40000959:	00 
4000095a:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000961:	e8 7e 1c 00 00       	call   400025e4 <debug_panic>
	close(fd);
40000966:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000969:	89 04 24             	mov    %eax,(%esp)
4000096c:	e8 6b 48 00 00       	call   400051dc <close>

	// Make sure the restoration was successful
	fd = open("ls", O_RDONLY); assert(fd > 0);
40000971:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40000978:	00 
40000979:	c7 04 24 16 76 00 40 	movl   $0x40007616,(%esp)
40000980:	e8 e1 47 00 00       	call   40005166 <open>
40000985:	89 45 f0             	mov    %eax,-0x10(%ebp)
40000988:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
4000098c:	7f 24                	jg     400009b2 <readwritecheck+0x400>
4000098e:	c7 44 24 0c f5 76 00 	movl   $0x400076f5,0xc(%esp)
40000995:	40 
40000996:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
4000099d:	40 
4000099e:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
400009a5:	00 
400009a6:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400009ad:	e8 32 1c 00 00       	call   400025e4 <debug_panic>
	act = read(fd, buf2, 2048);
400009b2:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
400009b9:	00 
400009ba:	c7 44 24 04 40 d0 00 	movl   $0x4000d040,0x4(%esp)
400009c1:	40 
400009c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
400009c5:	89 04 24             	mov    %eax,(%esp)
400009c8:	e8 34 48 00 00       	call   40005201 <read>
400009cd:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(act == 2048);
400009d0:	81 7d ec 00 08 00 00 	cmpl   $0x800,-0x14(%ebp)
400009d7:	74 24                	je     400009fd <readwritecheck+0x44b>
400009d9:	c7 44 24 0c fc 76 00 	movl   $0x400076fc,0xc(%esp)
400009e0:	40 
400009e1:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400009e8:	40 
400009e9:	c7 44 24 04 7e 00 00 	movl   $0x7e,0x4(%esp)
400009f0:	00 
400009f1:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400009f8:	e8 e7 1b 00 00       	call   400025e4 <debug_panic>
	assert(memcmp(buf, buf2, 2048) == 0);
400009fd:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
40000a04:	00 
40000a05:	c7 44 24 04 40 d0 00 	movl   $0x4000d040,0x4(%esp)
40000a0c:	40 
40000a0d:	c7 04 24 40 c4 00 40 	movl   $0x4000c440,(%esp)
40000a14:	e8 65 28 00 00       	call   4000327e <memcmp>
40000a19:	85 c0                	test   %eax,%eax
40000a1b:	74 24                	je     40000a41 <readwritecheck+0x48f>
40000a1d:	c7 44 24 0c 77 77 00 	movl   $0x40007777,0xc(%esp)
40000a24:	40 
40000a25:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000a2c:	40 
40000a2d:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
40000a34:	00 
40000a35:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000a3c:	e8 a3 1b 00 00       	call   400025e4 <debug_panic>
	close(fd);
40000a41:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000a44:	89 04 24             	mov    %eax,(%esp)
40000a47:	e8 90 47 00 00       	call   400051dc <close>

	// File size and such shouldn't have changed
	struct stat st2;
	rc = stat("ls", &st2); assert(rc >= 0);
40000a4c:	8d 45 d0             	lea    -0x30(%ebp),%eax
40000a4f:	89 44 24 04          	mov    %eax,0x4(%esp)
40000a53:	c7 04 24 16 76 00 40 	movl   $0x40007616,(%esp)
40000a5a:	e8 12 4b 00 00       	call   40005571 <stat>
40000a5f:	89 45 f4             	mov    %eax,-0xc(%ebp)
40000a62:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40000a66:	79 24                	jns    40000a8c <readwritecheck+0x4da>
40000a68:	c7 44 24 0c ca 76 00 	movl   $0x400076ca,0xc(%esp)
40000a6f:	40 
40000a70:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000a77:	40 
40000a78:	c7 44 24 04 84 00 00 	movl   $0x84,0x4(%esp)
40000a7f:	00 
40000a80:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000a87:	e8 58 1b 00 00       	call   400025e4 <debug_panic>
	assert(memcmp(&st, &st2, sizeof(st)) == 0);
40000a8c:	c7 44 24 08 0c 00 00 	movl   $0xc,0x8(%esp)
40000a93:	00 
40000a94:	8d 45 d0             	lea    -0x30(%ebp),%eax
40000a97:	89 44 24 04          	mov    %eax,0x4(%esp)
40000a9b:	8d 45 dc             	lea    -0x24(%ebp),%eax
40000a9e:	89 04 24             	mov    %eax,(%esp)
40000aa1:	e8 d8 27 00 00       	call   4000327e <memcmp>
40000aa6:	85 c0                	test   %eax,%eax
40000aa8:	74 24                	je     40000ace <readwritecheck+0x51c>
40000aaa:	c7 44 24 0c 94 77 00 	movl   $0x40007794,0xc(%esp)
40000ab1:	40 
40000ab2:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000ab9:	40 
40000aba:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
40000ac1:	00 
40000ac2:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000ac9:	e8 16 1b 00 00       	call   400025e4 <debug_panic>

	cprintf("readwritecheck passed\n");
40000ace:	c7 04 24 b7 77 00 40 	movl   $0x400077b7,(%esp)
40000ad5:	e8 9e 1d 00 00       	call   40002878 <cprintf>
}
40000ada:	c9                   	leave  
40000adb:	c3                   	ret    

40000adc <seekcheck>:

void
seekcheck()
{
40000adc:	55                   	push   %ebp
40000add:	89 e5                	mov    %esp,%ebp
40000adf:	83 ec 48             	sub    $0x48,%esp
	static char buf3[2048];	// a buffer to use for reading/writing data
	static const char zeros[1024];	// a buffer of all zeros
	int i, rc;
	ssize_t act;

	int fd = open("sh", O_RDWR); assert(fd > 0);
40000ae2:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
40000ae9:	00 
40000aea:	c7 04 24 ef 75 00 40 	movl   $0x400075ef,(%esp)
40000af1:	e8 70 46 00 00       	call   40005166 <open>
40000af6:	89 45 f0             	mov    %eax,-0x10(%ebp)
40000af9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40000afd:	7f 24                	jg     40000b23 <seekcheck+0x47>
40000aff:	c7 44 24 0c f5 76 00 	movl   $0x400076f5,0xc(%esp)
40000b06:	40 
40000b07:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000b0e:	40 
40000b0f:	c7 44 24 04 94 00 00 	movl   $0x94,0x4(%esp)
40000b16:	00 
40000b17:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000b1e:	e8 c1 1a 00 00       	call   400025e4 <debug_panic>

	// Get the file's original size etc.
	struct stat st;
	rc = fstat(fd, &st); assert(rc >= 0);
40000b23:	8d 45 d8             	lea    -0x28(%ebp),%eax
40000b26:	89 44 24 04          	mov    %eax,0x4(%esp)
40000b2a:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000b2d:	89 04 24             	mov    %eax,(%esp)
40000b30:	e8 79 4a 00 00       	call   400055ae <fstat>
40000b35:	89 45 ec             	mov    %eax,-0x14(%ebp)
40000b38:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
40000b3c:	79 24                	jns    40000b62 <seekcheck+0x86>
40000b3e:	c7 44 24 0c ca 76 00 	movl   $0x400076ca,0xc(%esp)
40000b45:	40 
40000b46:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000b4d:	40 
40000b4e:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
40000b55:	00 
40000b56:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000b5d:	e8 82 1a 00 00       	call   400025e4 <debug_panic>
	assert(S_ISREG(st.st_mode));
40000b62:	8b 45 dc             	mov    -0x24(%ebp),%eax
40000b65:	25 00 70 00 00       	and    $0x7000,%eax
40000b6a:	3d 00 10 00 00       	cmp    $0x1000,%eax
40000b6f:	74 24                	je     40000b95 <seekcheck+0xb9>
40000b71:	c7 44 24 0c d2 76 00 	movl   $0x400076d2,0xc(%esp)
40000b78:	40 
40000b79:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000b80:	40 
40000b81:	c7 44 24 04 99 00 00 	movl   $0x99,0x4(%esp)
40000b88:	00 
40000b89:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000b90:	e8 4f 1a 00 00       	call   400025e4 <debug_panic>
	assert(st.st_size > 65536);
40000b95:	8b 45 e0             	mov    -0x20(%ebp),%eax
40000b98:	3d 00 00 01 00       	cmp    $0x10000,%eax
40000b9d:	7f 24                	jg     40000bc3 <seekcheck+0xe7>
40000b9f:	c7 44 24 0c ce 77 00 	movl   $0x400077ce,0xc(%esp)
40000ba6:	40 
40000ba7:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000bae:	40 
40000baf:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
40000bb6:	00 
40000bb7:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000bbe:	e8 21 1a 00 00       	call   400025e4 <debug_panic>

	// We should be at the beginning of the file
	assert(lseek(fd, 0, SEEK_CUR) == 0);
40000bc3:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40000bca:	00 
40000bcb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000bd2:	00 
40000bd3:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000bd6:	89 04 24             	mov    %eax,(%esp)
40000bd9:	e8 8f 46 00 00       	call   4000526d <lseek>
40000bde:	85 c0                	test   %eax,%eax
40000be0:	74 24                	je     40000c06 <seekcheck+0x12a>
40000be2:	c7 44 24 0c e1 77 00 	movl   $0x400077e1,0xc(%esp)
40000be9:	40 
40000bea:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000bf1:	40 
40000bf2:	c7 44 24 04 9d 00 00 	movl   $0x9d,0x4(%esp)
40000bf9:	00 
40000bfa:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000c01:	e8 de 19 00 00       	call   400025e4 <debug_panic>
	assert(lseek(fd, 0, SEEK_CUR) == 0); // ...and should have stayed there
40000c06:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40000c0d:	00 
40000c0e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000c15:	00 
40000c16:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000c19:	89 04 24             	mov    %eax,(%esp)
40000c1c:	e8 4c 46 00 00       	call   4000526d <lseek>
40000c21:	85 c0                	test   %eax,%eax
40000c23:	74 24                	je     40000c49 <seekcheck+0x16d>
40000c25:	c7 44 24 0c e1 77 00 	movl   $0x400077e1,0xc(%esp)
40000c2c:	40 
40000c2d:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000c34:	40 
40000c35:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
40000c3c:	00 
40000c3d:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000c44:	e8 9b 19 00 00       	call   400025e4 <debug_panic>

	// Do some seeking and check the seek pointer arithmetic.
	// Note that it's not an error to seek past the end of file;
	// it's just that there's nothing to read there.
	rc = lseek(fd, 65536, SEEK_SET); assert(rc == 65536);
40000c49:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
40000c50:	00 
40000c51:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
40000c58:	00 
40000c59:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000c5c:	89 04 24             	mov    %eax,(%esp)
40000c5f:	e8 09 46 00 00       	call   4000526d <lseek>
40000c64:	89 45 ec             	mov    %eax,-0x14(%ebp)
40000c67:	81 7d ec 00 00 01 00 	cmpl   $0x10000,-0x14(%ebp)
40000c6e:	74 24                	je     40000c94 <seekcheck+0x1b8>
40000c70:	c7 44 24 0c fd 77 00 	movl   $0x400077fd,0xc(%esp)
40000c77:	40 
40000c78:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000c7f:	40 
40000c80:	c7 44 24 04 a3 00 00 	movl   $0xa3,0x4(%esp)
40000c87:	00 
40000c88:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000c8f:	e8 50 19 00 00       	call   400025e4 <debug_panic>
	rc = lseek(fd, 65536, SEEK_SET); assert(rc == 65536);
40000c94:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
40000c9b:	00 
40000c9c:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
40000ca3:	00 
40000ca4:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000ca7:	89 04 24             	mov    %eax,(%esp)
40000caa:	e8 be 45 00 00       	call   4000526d <lseek>
40000caf:	89 45 ec             	mov    %eax,-0x14(%ebp)
40000cb2:	81 7d ec 00 00 01 00 	cmpl   $0x10000,-0x14(%ebp)
40000cb9:	74 24                	je     40000cdf <seekcheck+0x203>
40000cbb:	c7 44 24 0c fd 77 00 	movl   $0x400077fd,0xc(%esp)
40000cc2:	40 
40000cc3:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000cca:	40 
40000ccb:	c7 44 24 04 a4 00 00 	movl   $0xa4,0x4(%esp)
40000cd2:	00 
40000cd3:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000cda:	e8 05 19 00 00       	call   400025e4 <debug_panic>
	rc = lseek(fd, 1024*1024, SEEK_CUR); assert(rc == 65536+1024*1024);
40000cdf:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40000ce6:	00 
40000ce7:	c7 44 24 04 00 00 10 	movl   $0x100000,0x4(%esp)
40000cee:	00 
40000cef:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000cf2:	89 04 24             	mov    %eax,(%esp)
40000cf5:	e8 73 45 00 00       	call   4000526d <lseek>
40000cfa:	89 45 ec             	mov    %eax,-0x14(%ebp)
40000cfd:	81 7d ec 00 00 11 00 	cmpl   $0x110000,-0x14(%ebp)
40000d04:	74 24                	je     40000d2a <seekcheck+0x24e>
40000d06:	c7 44 24 0c 09 78 00 	movl   $0x40007809,0xc(%esp)
40000d0d:	40 
40000d0e:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000d15:	40 
40000d16:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
40000d1d:	00 
40000d1e:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000d25:	e8 ba 18 00 00       	call   400025e4 <debug_panic>
	rc = lseek(fd, -1024*1024, SEEK_CUR); assert(rc == 65536);
40000d2a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40000d31:	00 
40000d32:	c7 44 24 04 00 00 f0 	movl   $0xfff00000,0x4(%esp)
40000d39:	ff 
40000d3a:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000d3d:	89 04 24             	mov    %eax,(%esp)
40000d40:	e8 28 45 00 00       	call   4000526d <lseek>
40000d45:	89 45 ec             	mov    %eax,-0x14(%ebp)
40000d48:	81 7d ec 00 00 01 00 	cmpl   $0x10000,-0x14(%ebp)
40000d4f:	74 24                	je     40000d75 <seekcheck+0x299>
40000d51:	c7 44 24 0c fd 77 00 	movl   $0x400077fd,0xc(%esp)
40000d58:	40 
40000d59:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000d60:	40 
40000d61:	c7 44 24 04 a6 00 00 	movl   $0xa6,0x4(%esp)
40000d68:	00 
40000d69:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000d70:	e8 6f 18 00 00       	call   400025e4 <debug_panic>
	rc = lseek(fd, 0, SEEK_END); assert(rc == st.st_size);
40000d75:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
40000d7c:	00 
40000d7d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000d84:	00 
40000d85:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000d88:	89 04 24             	mov    %eax,(%esp)
40000d8b:	e8 dd 44 00 00       	call   4000526d <lseek>
40000d90:	89 45 ec             	mov    %eax,-0x14(%ebp)
40000d93:	8b 45 e0             	mov    -0x20(%ebp),%eax
40000d96:	3b 45 ec             	cmp    -0x14(%ebp),%eax
40000d99:	74 24                	je     40000dbf <seekcheck+0x2e3>
40000d9b:	c7 44 24 0c 1f 78 00 	movl   $0x4000781f,0xc(%esp)
40000da2:	40 
40000da3:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000daa:	40 
40000dab:	c7 44 24 04 a7 00 00 	movl   $0xa7,0x4(%esp)
40000db2:	00 
40000db3:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000dba:	e8 25 18 00 00       	call   400025e4 <debug_panic>
	rc = lseek(fd, -1024, SEEK_END); assert(rc == st.st_size-1024);
40000dbf:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
40000dc6:	00 
40000dc7:	c7 44 24 04 00 fc ff 	movl   $0xfffffc00,0x4(%esp)
40000dce:	ff 
40000dcf:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000dd2:	89 04 24             	mov    %eax,(%esp)
40000dd5:	e8 93 44 00 00       	call   4000526d <lseek>
40000dda:	89 45 ec             	mov    %eax,-0x14(%ebp)
40000ddd:	8b 45 e0             	mov    -0x20(%ebp),%eax
40000de0:	2d 00 04 00 00       	sub    $0x400,%eax
40000de5:	3b 45 ec             	cmp    -0x14(%ebp),%eax
40000de8:	74 24                	je     40000e0e <seekcheck+0x332>
40000dea:	c7 44 24 0c 30 78 00 	movl   $0x40007830,0xc(%esp)
40000df1:	40 
40000df2:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000df9:	40 
40000dfa:	c7 44 24 04 a8 00 00 	movl   $0xa8,0x4(%esp)
40000e01:	00 
40000e02:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000e09:	e8 d6 17 00 00       	call   400025e4 <debug_panic>
	rc = lseek(fd, 12345, SEEK_END); assert(rc == st.st_size+12345);
40000e0e:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
40000e15:	00 
40000e16:	c7 44 24 04 39 30 00 	movl   $0x3039,0x4(%esp)
40000e1d:	00 
40000e1e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000e21:	89 04 24             	mov    %eax,(%esp)
40000e24:	e8 44 44 00 00       	call   4000526d <lseek>
40000e29:	89 45 ec             	mov    %eax,-0x14(%ebp)
40000e2c:	8b 45 e0             	mov    -0x20(%ebp),%eax
40000e2f:	05 39 30 00 00       	add    $0x3039,%eax
40000e34:	3b 45 ec             	cmp    -0x14(%ebp),%eax
40000e37:	74 24                	je     40000e5d <seekcheck+0x381>
40000e39:	c7 44 24 0c 46 78 00 	movl   $0x40007846,0xc(%esp)
40000e40:	40 
40000e41:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000e48:	40 
40000e49:	c7 44 24 04 a9 00 00 	movl   $0xa9,0x4(%esp)
40000e50:	00 
40000e51:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000e58:	e8 87 17 00 00       	call   400025e4 <debug_panic>

	// Read some blocks sequentially from the beginning of the file,
	// and compare against what we get if we directly seek to a block
	rc = lseek(fd, -st.st_size, SEEK_END); assert(rc == 0);
40000e5d:	8b 45 e0             	mov    -0x20(%ebp),%eax
40000e60:	f7 d8                	neg    %eax
40000e62:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
40000e69:	00 
40000e6a:	89 44 24 04          	mov    %eax,0x4(%esp)
40000e6e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000e71:	89 04 24             	mov    %eax,(%esp)
40000e74:	e8 f4 43 00 00       	call   4000526d <lseek>
40000e79:	89 45 ec             	mov    %eax,-0x14(%ebp)
40000e7c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
40000e80:	74 24                	je     40000ea6 <seekcheck+0x3ca>
40000e82:	c7 44 24 0c 5d 78 00 	movl   $0x4000785d,0xc(%esp)
40000e89:	40 
40000e8a:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000e91:	40 
40000e92:	c7 44 24 04 ad 00 00 	movl   $0xad,0x4(%esp)
40000e99:	00 
40000e9a:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000ea1:	e8 3e 17 00 00       	call   400025e4 <debug_panic>
	act = read(fd, buf, 2048); assert(act == 2048);
40000ea6:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
40000ead:	00 
40000eae:	c7 44 24 04 40 a8 00 	movl   $0x4000a840,0x4(%esp)
40000eb5:	40 
40000eb6:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000eb9:	89 04 24             	mov    %eax,(%esp)
40000ebc:	e8 40 43 00 00       	call   40005201 <read>
40000ec1:	89 45 e8             	mov    %eax,-0x18(%ebp)
40000ec4:	81 7d e8 00 08 00 00 	cmpl   $0x800,-0x18(%ebp)
40000ecb:	74 24                	je     40000ef1 <seekcheck+0x415>
40000ecd:	c7 44 24 0c fc 76 00 	movl   $0x400076fc,0xc(%esp)
40000ed4:	40 
40000ed5:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000edc:	40 
40000edd:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
40000ee4:	00 
40000ee5:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000eec:	e8 f3 16 00 00       	call   400025e4 <debug_panic>
	elfhdr *eh = (elfhdr*) buf;
40000ef1:	c7 45 e4 40 a8 00 40 	movl   $0x4000a840,-0x1c(%ebp)
	assert(eh->e_magic == ELF_MAGIC); // should be an ELF file
40000ef8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40000efb:	8b 00                	mov    (%eax),%eax
40000efd:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
40000f02:	74 24                	je     40000f28 <seekcheck+0x44c>
40000f04:	c7 44 24 0c 08 77 00 	movl   $0x40007708,0xc(%esp)
40000f0b:	40 
40000f0c:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000f13:	40 
40000f14:	c7 44 24 04 b0 00 00 	movl   $0xb0,0x4(%esp)
40000f1b:	00 
40000f1c:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000f23:	e8 bc 16 00 00       	call   400025e4 <debug_panic>
	for (i = 0; i < 32; i++) { // read next 32 2KB chunks
40000f28:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
40000f2f:	eb 4f                	jmp    40000f80 <seekcheck+0x4a4>
		act = read(fd, buf, 2048); assert(act == 2048);
40000f31:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
40000f38:	00 
40000f39:	c7 44 24 04 40 a8 00 	movl   $0x4000a840,0x4(%esp)
40000f40:	40 
40000f41:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000f44:	89 04 24             	mov    %eax,(%esp)
40000f47:	e8 b5 42 00 00       	call   40005201 <read>
40000f4c:	89 45 e8             	mov    %eax,-0x18(%ebp)
40000f4f:	81 7d e8 00 08 00 00 	cmpl   $0x800,-0x18(%ebp)
40000f56:	74 24                	je     40000f7c <seekcheck+0x4a0>
40000f58:	c7 44 24 0c fc 76 00 	movl   $0x400076fc,0xc(%esp)
40000f5f:	40 
40000f60:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000f67:	40 
40000f68:	c7 44 24 04 b2 00 00 	movl   $0xb2,0x4(%esp)
40000f6f:	00 
40000f70:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000f77:	e8 68 16 00 00       	call   400025e4 <debug_panic>
	// and compare against what we get if we directly seek to a block
	rc = lseek(fd, -st.st_size, SEEK_END); assert(rc == 0);
	act = read(fd, buf, 2048); assert(act == 2048);
	elfhdr *eh = (elfhdr*) buf;
	assert(eh->e_magic == ELF_MAGIC); // should be an ELF file
	for (i = 0; i < 32; i++) { // read next 32 2KB chunks
40000f7c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40000f80:	83 7d f4 1f          	cmpl   $0x1f,-0xc(%ebp)
40000f84:	7e ab                	jle    40000f31 <seekcheck+0x455>
		act = read(fd, buf, 2048); assert(act == 2048);
	}
	// should leave file bytes 64KB thru 66KB in buf; verify...
	rc = lseek(fd, 0, SEEK_CUR); assert(rc == 66*1024);
40000f86:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40000f8d:	00 
40000f8e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000f95:	00 
40000f96:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000f99:	89 04 24             	mov    %eax,(%esp)
40000f9c:	e8 cc 42 00 00       	call   4000526d <lseek>
40000fa1:	89 45 ec             	mov    %eax,-0x14(%ebp)
40000fa4:	81 7d ec 00 08 01 00 	cmpl   $0x10800,-0x14(%ebp)
40000fab:	74 24                	je     40000fd1 <seekcheck+0x4f5>
40000fad:	c7 44 24 0c 65 78 00 	movl   $0x40007865,0xc(%esp)
40000fb4:	40 
40000fb5:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40000fbc:	40 
40000fbd:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
40000fc4:	00 
40000fc5:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40000fcc:	e8 13 16 00 00       	call   400025e4 <debug_panic>
	rc = lseek(fd, 65536, SEEK_SET); assert(rc == 65536);
40000fd1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
40000fd8:	00 
40000fd9:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
40000fe0:	00 
40000fe1:	8b 45 f0             	mov    -0x10(%ebp),%eax
40000fe4:	89 04 24             	mov    %eax,(%esp)
40000fe7:	e8 81 42 00 00       	call   4000526d <lseek>
40000fec:	89 45 ec             	mov    %eax,-0x14(%ebp)
40000fef:	81 7d ec 00 00 01 00 	cmpl   $0x10000,-0x14(%ebp)
40000ff6:	74 24                	je     4000101c <seekcheck+0x540>
40000ff8:	c7 44 24 0c fd 77 00 	movl   $0x400077fd,0xc(%esp)
40000fff:	40 
40001000:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001007:	40 
40001008:	c7 44 24 04 b6 00 00 	movl   $0xb6,0x4(%esp)
4000100f:	00 
40001010:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001017:	e8 c8 15 00 00       	call   400025e4 <debug_panic>
	act = read(fd, buf2, 2048); assert(act == 2048);
4000101c:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
40001023:	00 
40001024:	c7 44 24 04 40 b0 00 	movl   $0x4000b040,0x4(%esp)
4000102b:	40 
4000102c:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000102f:	89 04 24             	mov    %eax,(%esp)
40001032:	e8 ca 41 00 00       	call   40005201 <read>
40001037:	89 45 e8             	mov    %eax,-0x18(%ebp)
4000103a:	81 7d e8 00 08 00 00 	cmpl   $0x800,-0x18(%ebp)
40001041:	74 24                	je     40001067 <seekcheck+0x58b>
40001043:	c7 44 24 0c fc 76 00 	movl   $0x400076fc,0xc(%esp)
4000104a:	40 
4000104b:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001052:	40 
40001053:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
4000105a:	00 
4000105b:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001062:	e8 7d 15 00 00       	call   400025e4 <debug_panic>
	rc = lseek(fd, 0, SEEK_CUR); assert(rc == 66*1024);
40001067:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
4000106e:	00 
4000106f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001076:	00 
40001077:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000107a:	89 04 24             	mov    %eax,(%esp)
4000107d:	e8 eb 41 00 00       	call   4000526d <lseek>
40001082:	89 45 ec             	mov    %eax,-0x14(%ebp)
40001085:	81 7d ec 00 08 01 00 	cmpl   $0x10800,-0x14(%ebp)
4000108c:	74 24                	je     400010b2 <seekcheck+0x5d6>
4000108e:	c7 44 24 0c 65 78 00 	movl   $0x40007865,0xc(%esp)
40001095:	40 
40001096:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
4000109d:	40 
4000109e:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
400010a5:	00 
400010a6:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400010ad:	e8 32 15 00 00       	call   400025e4 <debug_panic>
	assert(memcmp(buf, buf2, 2048) == 0);
400010b2:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
400010b9:	00 
400010ba:	c7 44 24 04 40 b0 00 	movl   $0x4000b040,0x4(%esp)
400010c1:	40 
400010c2:	c7 04 24 40 a8 00 40 	movl   $0x4000a840,(%esp)
400010c9:	e8 b0 21 00 00       	call   4000327e <memcmp>
400010ce:	85 c0                	test   %eax,%eax
400010d0:	74 24                	je     400010f6 <seekcheck+0x61a>
400010d2:	c7 44 24 0c 77 77 00 	movl   $0x40007777,0xc(%esp)
400010d9:	40 
400010da:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400010e1:	40 
400010e2:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
400010e9:	00 
400010ea:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400010f1:	e8 ee 14 00 00       	call   400025e4 <debug_panic>

	// overwrite part of this area
	rc = lseek(fd, -1024-512, SEEK_CUR); assert(rc == 65536+512);
400010f6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
400010fd:	00 
400010fe:	c7 44 24 04 00 fa ff 	movl   $0xfffffa00,0x4(%esp)
40001105:	ff 
40001106:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001109:	89 04 24             	mov    %eax,(%esp)
4000110c:	e8 5c 41 00 00       	call   4000526d <lseek>
40001111:	89 45 ec             	mov    %eax,-0x14(%ebp)
40001114:	81 7d ec 00 02 01 00 	cmpl   $0x10200,-0x14(%ebp)
4000111b:	74 24                	je     40001141 <seekcheck+0x665>
4000111d:	c7 44 24 0c 73 78 00 	movl   $0x40007873,0xc(%esp)
40001124:	40 
40001125:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
4000112c:	40 
4000112d:	c7 44 24 04 bc 00 00 	movl   $0xbc,0x4(%esp)
40001134:	00 
40001135:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
4000113c:	e8 a3 14 00 00       	call   400025e4 <debug_panic>
	act = write(fd, zeros, 1024); assert(act == 1024);
40001141:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
40001148:	00 
40001149:	c7 44 24 04 40 b8 00 	movl   $0x4000b840,0x4(%esp)
40001150:	40 
40001151:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001154:	89 04 24             	mov    %eax,(%esp)
40001157:	e8 db 40 00 00       	call   40005237 <write>
4000115c:	89 45 e8             	mov    %eax,-0x18(%ebp)
4000115f:	81 7d e8 00 04 00 00 	cmpl   $0x400,-0x18(%ebp)
40001166:	74 24                	je     4000118c <seekcheck+0x6b0>
40001168:	c7 44 24 0c 21 77 00 	movl   $0x40007721,0xc(%esp)
4000116f:	40 
40001170:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001177:	40 
40001178:	c7 44 24 04 bd 00 00 	movl   $0xbd,0x4(%esp)
4000117f:	00 
40001180:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001187:	e8 58 14 00 00       	call   400025e4 <debug_panic>
	rc = lseek(fd, 65536, SEEK_SET); assert(rc == 65536);
4000118c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
40001193:	00 
40001194:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
4000119b:	00 
4000119c:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000119f:	89 04 24             	mov    %eax,(%esp)
400011a2:	e8 c6 40 00 00       	call   4000526d <lseek>
400011a7:	89 45 ec             	mov    %eax,-0x14(%ebp)
400011aa:	81 7d ec 00 00 01 00 	cmpl   $0x10000,-0x14(%ebp)
400011b1:	74 24                	je     400011d7 <seekcheck+0x6fb>
400011b3:	c7 44 24 0c fd 77 00 	movl   $0x400077fd,0xc(%esp)
400011ba:	40 
400011bb:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400011c2:	40 
400011c3:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
400011ca:	00 
400011cb:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400011d2:	e8 0d 14 00 00       	call   400025e4 <debug_panic>
	act = read(fd, buf2, 2048); assert(act == 2048);
400011d7:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
400011de:	00 
400011df:	c7 44 24 04 40 b0 00 	movl   $0x4000b040,0x4(%esp)
400011e6:	40 
400011e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
400011ea:	89 04 24             	mov    %eax,(%esp)
400011ed:	e8 0f 40 00 00       	call   40005201 <read>
400011f2:	89 45 e8             	mov    %eax,-0x18(%ebp)
400011f5:	81 7d e8 00 08 00 00 	cmpl   $0x800,-0x18(%ebp)
400011fc:	74 24                	je     40001222 <seekcheck+0x746>
400011fe:	c7 44 24 0c fc 76 00 	movl   $0x400076fc,0xc(%esp)
40001205:	40 
40001206:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
4000120d:	40 
4000120e:	c7 44 24 04 bf 00 00 	movl   $0xbf,0x4(%esp)
40001215:	00 
40001216:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
4000121d:	e8 c2 13 00 00       	call   400025e4 <debug_panic>
	assert(memcmp(buf2, buf, 512) == 0);
40001222:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
40001229:	00 
4000122a:	c7 44 24 04 40 a8 00 	movl   $0x4000a840,0x4(%esp)
40001231:	40 
40001232:	c7 04 24 40 b0 00 40 	movl   $0x4000b040,(%esp)
40001239:	e8 40 20 00 00       	call   4000327e <memcmp>
4000123e:	85 c0                	test   %eax,%eax
40001240:	74 24                	je     40001266 <seekcheck+0x78a>
40001242:	c7 44 24 0c 83 78 00 	movl   $0x40007883,0xc(%esp)
40001249:	40 
4000124a:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001251:	40 
40001252:	c7 44 24 04 c0 00 00 	movl   $0xc0,0x4(%esp)
40001259:	00 
4000125a:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001261:	e8 7e 13 00 00       	call   400025e4 <debug_panic>
	assert(memcmp(buf2+512, zeros, 1024) == 0);
40001266:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
4000126d:	00 
4000126e:	c7 44 24 04 40 b8 00 	movl   $0x4000b840,0x4(%esp)
40001275:	40 
40001276:	c7 04 24 40 b2 00 40 	movl   $0x4000b240,(%esp)
4000127d:	e8 fc 1f 00 00       	call   4000327e <memcmp>
40001282:	85 c0                	test   %eax,%eax
40001284:	74 24                	je     400012aa <seekcheck+0x7ce>
40001286:	c7 44 24 0c a0 78 00 	movl   $0x400078a0,0xc(%esp)
4000128d:	40 
4000128e:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001295:	40 
40001296:	c7 44 24 04 c1 00 00 	movl   $0xc1,0x4(%esp)
4000129d:	00 
4000129e:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400012a5:	e8 3a 13 00 00       	call   400025e4 <debug_panic>
	assert(memcmp(buf2+1024+512, buf+1024+512, 512) == 0);
400012aa:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
400012b1:	00 
400012b2:	c7 44 24 04 40 ae 00 	movl   $0x4000ae40,0x4(%esp)
400012b9:	40 
400012ba:	c7 04 24 40 b6 00 40 	movl   $0x4000b640,(%esp)
400012c1:	e8 b8 1f 00 00       	call   4000327e <memcmp>
400012c6:	85 c0                	test   %eax,%eax
400012c8:	74 24                	je     400012ee <seekcheck+0x812>
400012ca:	c7 44 24 0c c4 78 00 	movl   $0x400078c4,0xc(%esp)
400012d1:	40 
400012d2:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400012d9:	40 
400012da:	c7 44 24 04 c2 00 00 	movl   $0xc2,0x4(%esp)
400012e1:	00 
400012e2:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400012e9:	e8 f6 12 00 00       	call   400025e4 <debug_panic>

	// try reading past the end of the file
	rc = lseek(fd, -1024, SEEK_END); assert(rc == st.st_size - 1024);
400012ee:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
400012f5:	00 
400012f6:	c7 44 24 04 00 fc ff 	movl   $0xfffffc00,0x4(%esp)
400012fd:	ff 
400012fe:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001301:	89 04 24             	mov    %eax,(%esp)
40001304:	e8 64 3f 00 00       	call   4000526d <lseek>
40001309:	89 45 ec             	mov    %eax,-0x14(%ebp)
4000130c:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000130f:	2d 00 04 00 00       	sub    $0x400,%eax
40001314:	3b 45 ec             	cmp    -0x14(%ebp),%eax
40001317:	74 24                	je     4000133d <seekcheck+0x861>
40001319:	c7 44 24 0c f2 78 00 	movl   $0x400078f2,0xc(%esp)
40001320:	40 
40001321:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001328:	40 
40001329:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
40001330:	00 
40001331:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001338:	e8 a7 12 00 00       	call   400025e4 <debug_panic>
	act = read(fd, buf2, 2048);assert(act == 1024); // that's all there is
4000133d:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
40001344:	00 
40001345:	c7 44 24 04 40 b0 00 	movl   $0x4000b040,0x4(%esp)
4000134c:	40 
4000134d:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001350:	89 04 24             	mov    %eax,(%esp)
40001353:	e8 a9 3e 00 00       	call   40005201 <read>
40001358:	89 45 e8             	mov    %eax,-0x18(%ebp)
4000135b:	81 7d e8 00 04 00 00 	cmpl   $0x400,-0x18(%ebp)
40001362:	74 24                	je     40001388 <seekcheck+0x8ac>
40001364:	c7 44 24 0c 21 77 00 	movl   $0x40007721,0xc(%esp)
4000136b:	40 
4000136c:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001373:	40 
40001374:	c7 44 24 04 c6 00 00 	movl   $0xc6,0x4(%esp)
4000137b:	00 
4000137c:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001383:	e8 5c 12 00 00       	call   400025e4 <debug_panic>

	// file size shouldn't have changed so far
	struct stat st2;
	rc = fstat(fd, &st2); assert(rc >= 0);
40001388:	8d 45 cc             	lea    -0x34(%ebp),%eax
4000138b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000138f:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001392:	89 04 24             	mov    %eax,(%esp)
40001395:	e8 14 42 00 00       	call   400055ae <fstat>
4000139a:	89 45 ec             	mov    %eax,-0x14(%ebp)
4000139d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
400013a1:	79 24                	jns    400013c7 <seekcheck+0x8eb>
400013a3:	c7 44 24 0c ca 76 00 	movl   $0x400076ca,0xc(%esp)
400013aa:	40 
400013ab:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400013b2:	40 
400013b3:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
400013ba:	00 
400013bb:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400013c2:	e8 1d 12 00 00       	call   400025e4 <debug_panic>
	assert(memcmp(&st, &st2, sizeof(st)) == 0);
400013c7:	c7 44 24 08 0c 00 00 	movl   $0xc,0x8(%esp)
400013ce:	00 
400013cf:	8d 45 cc             	lea    -0x34(%ebp),%eax
400013d2:	89 44 24 04          	mov    %eax,0x4(%esp)
400013d6:	8d 45 d8             	lea    -0x28(%ebp),%eax
400013d9:	89 04 24             	mov    %eax,(%esp)
400013dc:	e8 9d 1e 00 00       	call   4000327e <memcmp>
400013e1:	85 c0                	test   %eax,%eax
400013e3:	74 24                	je     40001409 <seekcheck+0x92d>
400013e5:	c7 44 24 0c 94 77 00 	movl   $0x40007794,0xc(%esp)
400013ec:	40 
400013ed:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400013f4:	40 
400013f5:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
400013fc:	00 
400013fd:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001404:	e8 db 11 00 00       	call   400025e4 <debug_panic>

	// overwrite and extend the last part of the file
	rc = lseek(fd, -1024, SEEK_END); assert(rc == st.st_size - 1024);
40001409:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
40001410:	00 
40001411:	c7 44 24 04 00 fc ff 	movl   $0xfffffc00,0x4(%esp)
40001418:	ff 
40001419:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000141c:	89 04 24             	mov    %eax,(%esp)
4000141f:	e8 49 3e 00 00       	call   4000526d <lseek>
40001424:	89 45 ec             	mov    %eax,-0x14(%ebp)
40001427:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000142a:	2d 00 04 00 00       	sub    $0x400,%eax
4000142f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
40001432:	74 24                	je     40001458 <seekcheck+0x97c>
40001434:	c7 44 24 0c f2 78 00 	movl   $0x400078f2,0xc(%esp)
4000143b:	40 
4000143c:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001443:	40 
40001444:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
4000144b:	00 
4000144c:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001453:	e8 8c 11 00 00       	call   400025e4 <debug_panic>
	act = write(fd, zeros, 2048); assert(act == 2048);
40001458:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
4000145f:	00 
40001460:	c7 44 24 04 40 b8 00 	movl   $0x4000b840,0x4(%esp)
40001467:	40 
40001468:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000146b:	89 04 24             	mov    %eax,(%esp)
4000146e:	e8 c4 3d 00 00       	call   40005237 <write>
40001473:	89 45 e8             	mov    %eax,-0x18(%ebp)
40001476:	81 7d e8 00 08 00 00 	cmpl   $0x800,-0x18(%ebp)
4000147d:	74 24                	je     400014a3 <seekcheck+0x9c7>
4000147f:	c7 44 24 0c fc 76 00 	movl   $0x400076fc,0xc(%esp)
40001486:	40 
40001487:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
4000148e:	40 
4000148f:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
40001496:	00 
40001497:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
4000149e:	e8 41 11 00 00       	call   400025e4 <debug_panic>

	// The file should have grown by 1KB
	rc = fstat(fd, &st2); assert(rc >= 0);
400014a3:	8d 45 cc             	lea    -0x34(%ebp),%eax
400014a6:	89 44 24 04          	mov    %eax,0x4(%esp)
400014aa:	8b 45 f0             	mov    -0x10(%ebp),%eax
400014ad:	89 04 24             	mov    %eax,(%esp)
400014b0:	e8 f9 40 00 00       	call   400055ae <fstat>
400014b5:	89 45 ec             	mov    %eax,-0x14(%ebp)
400014b8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
400014bc:	79 24                	jns    400014e2 <seekcheck+0xa06>
400014be:	c7 44 24 0c ca 76 00 	movl   $0x400076ca,0xc(%esp)
400014c5:	40 
400014c6:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400014cd:	40 
400014ce:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
400014d5:	00 
400014d6:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400014dd:	e8 02 11 00 00       	call   400025e4 <debug_panic>
	assert(st2.st_size == st.st_size + 1024);
400014e2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
400014e5:	8b 55 e0             	mov    -0x20(%ebp),%edx
400014e8:	81 c2 00 04 00 00    	add    $0x400,%edx
400014ee:	39 d0                	cmp    %edx,%eax
400014f0:	74 24                	je     40001516 <seekcheck+0xa3a>
400014f2:	c7 44 24 0c 0c 79 00 	movl   $0x4000790c,0xc(%esp)
400014f9:	40 
400014fa:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001501:	40 
40001502:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
40001509:	00 
4000150a:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001511:	e8 ce 10 00 00       	call   400025e4 <debug_panic>

	// try to read way beyond end-of-file
	rc = lseek(fd, 1234567, SEEK_END); assert(rc == st2.st_size + 1234567);
40001516:	c7 44 24 08 02 00 00 	movl   $0x2,0x8(%esp)
4000151d:	00 
4000151e:	c7 44 24 04 87 d6 12 	movl   $0x12d687,0x4(%esp)
40001525:	00 
40001526:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001529:	89 04 24             	mov    %eax,(%esp)
4000152c:	e8 3c 3d 00 00       	call   4000526d <lseek>
40001531:	89 45 ec             	mov    %eax,-0x14(%ebp)
40001534:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40001537:	05 87 d6 12 00       	add    $0x12d687,%eax
4000153c:	3b 45 ec             	cmp    -0x14(%ebp),%eax
4000153f:	74 24                	je     40001565 <seekcheck+0xa89>
40001541:	c7 44 24 0c 2d 79 00 	movl   $0x4000792d,0xc(%esp)
40001548:	40 
40001549:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001550:	40 
40001551:	c7 44 24 04 d6 00 00 	movl   $0xd6,0x4(%esp)
40001558:	00 
40001559:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001560:	e8 7f 10 00 00       	call   400025e4 <debug_panic>
	memcpy(buf3, buf2, 2048);
40001565:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
4000156c:	00 
4000156d:	c7 44 24 04 40 b0 00 	movl   $0x4000b040,0x4(%esp)
40001574:	40 
40001575:	c7 04 24 40 bc 00 40 	movl   $0x4000bc40,(%esp)
4000157c:	e8 dc 1c 00 00       	call   4000325d <memcpy>
	act = read(fd, buf3, 2048); assert(act == 0);
40001581:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
40001588:	00 
40001589:	c7 44 24 04 40 bc 00 	movl   $0x4000bc40,0x4(%esp)
40001590:	40 
40001591:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001594:	89 04 24             	mov    %eax,(%esp)
40001597:	e8 65 3c 00 00       	call   40005201 <read>
4000159c:	89 45 e8             	mov    %eax,-0x18(%ebp)
4000159f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
400015a3:	74 24                	je     400015c9 <seekcheck+0xaed>
400015a5:	c7 44 24 0c 49 79 00 	movl   $0x40007949,0xc(%esp)
400015ac:	40 
400015ad:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400015b4:	40 
400015b5:	c7 44 24 04 d8 00 00 	movl   $0xd8,0x4(%esp)
400015bc:	00 
400015bd:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400015c4:	e8 1b 10 00 00       	call   400025e4 <debug_panic>
	assert(memcmp(buf3, buf2, 2048) == 0); // shouldn't have touched buf3
400015c9:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
400015d0:	00 
400015d1:	c7 44 24 04 40 b0 00 	movl   $0x4000b040,0x4(%esp)
400015d8:	40 
400015d9:	c7 04 24 40 bc 00 40 	movl   $0x4000bc40,(%esp)
400015e0:	e8 99 1c 00 00       	call   4000327e <memcmp>
400015e5:	85 c0                	test   %eax,%eax
400015e7:	74 24                	je     4000160d <seekcheck+0xb31>
400015e9:	c7 44 24 0c 52 79 00 	movl   $0x40007952,0xc(%esp)
400015f0:	40 
400015f1:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400015f8:	40 
400015f9:	c7 44 24 04 d9 00 00 	movl   $0xd9,0x4(%esp)
40001600:	00 
40001601:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001608:	e8 d7 0f 00 00       	call   400025e4 <debug_panic>

	// try to grow a file too big for PIOS's file system
	memcpy(buf3, FILEDATA(files->fd[fd].ino+1), 2048); // corruption check
4000160d:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40001612:	8b 55 f0             	mov    -0x10(%ebp),%edx
40001615:	83 c2 01             	add    $0x1,%edx
40001618:	c1 e2 04             	shl    $0x4,%edx
4000161b:	01 d0                	add    %edx,%eax
4000161d:	8b 00                	mov    (%eax),%eax
4000161f:	83 c0 01             	add    $0x1,%eax
40001622:	c1 e0 16             	shl    $0x16,%eax
40001625:	05 00 00 00 80       	add    $0x80000000,%eax
4000162a:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
40001631:	00 
40001632:	89 44 24 04          	mov    %eax,0x4(%esp)
40001636:	c7 04 24 40 bc 00 40 	movl   $0x4000bc40,(%esp)
4000163d:	e8 1b 1c 00 00       	call   4000325d <memcpy>
	rc = lseek(fd, FILE_MAXSIZE, SEEK_SET); assert(rc == FILE_MAXSIZE);
40001642:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
40001649:	00 
4000164a:	c7 44 24 04 00 00 40 	movl   $0x400000,0x4(%esp)
40001651:	00 
40001652:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001655:	89 04 24             	mov    %eax,(%esp)
40001658:	e8 10 3c 00 00       	call   4000526d <lseek>
4000165d:	89 45 ec             	mov    %eax,-0x14(%ebp)
40001660:	81 7d ec 00 00 40 00 	cmpl   $0x400000,-0x14(%ebp)
40001667:	74 24                	je     4000168d <seekcheck+0xbb1>
40001669:	c7 44 24 0c 70 79 00 	movl   $0x40007970,0xc(%esp)
40001670:	40 
40001671:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001678:	40 
40001679:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
40001680:	00 
40001681:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001688:	e8 57 0f 00 00       	call   400025e4 <debug_panic>
	act = write(fd, buf, 2048); assert(act < 0); assert(errno == EFBIG);
4000168d:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
40001694:	00 
40001695:	c7 44 24 04 40 a8 00 	movl   $0x4000a840,0x4(%esp)
4000169c:	40 
4000169d:	8b 45 f0             	mov    -0x10(%ebp),%eax
400016a0:	89 04 24             	mov    %eax,(%esp)
400016a3:	e8 8f 3b 00 00       	call   40005237 <write>
400016a8:	89 45 e8             	mov    %eax,-0x18(%ebp)
400016ab:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
400016af:	78 24                	js     400016d5 <seekcheck+0xbf9>
400016b1:	c7 44 24 0c 83 79 00 	movl   $0x40007983,0xc(%esp)
400016b8:	40 
400016b9:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400016c0:	40 
400016c1:	c7 44 24 04 de 00 00 	movl   $0xde,0x4(%esp)
400016c8:	00 
400016c9:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400016d0:	e8 0f 0f 00 00       	call   400025e4 <debug_panic>
400016d5:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400016da:	8b 00                	mov    (%eax),%eax
400016dc:	83 f8 03             	cmp    $0x3,%eax
400016df:	74 24                	je     40001705 <seekcheck+0xc29>
400016e1:	c7 44 24 0c 8b 79 00 	movl   $0x4000798b,0xc(%esp)
400016e8:	40 
400016e9:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400016f0:	40 
400016f1:	c7 44 24 04 de 00 00 	movl   $0xde,0x4(%esp)
400016f8:	00 
400016f9:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001700:	e8 df 0e 00 00       	call   400025e4 <debug_panic>
	assert(memcmp(buf3, FILEDATA(files->fd[fd].ino+1), 2048) == 0);
40001705:	a1 8c 80 00 40       	mov    0x4000808c,%eax
4000170a:	8b 55 f0             	mov    -0x10(%ebp),%edx
4000170d:	83 c2 01             	add    $0x1,%edx
40001710:	c1 e2 04             	shl    $0x4,%edx
40001713:	01 d0                	add    %edx,%eax
40001715:	8b 00                	mov    (%eax),%eax
40001717:	83 c0 01             	add    $0x1,%eax
4000171a:	c1 e0 16             	shl    $0x16,%eax
4000171d:	05 00 00 00 80       	add    $0x80000000,%eax
40001722:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
40001729:	00 
4000172a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000172e:	c7 04 24 40 bc 00 40 	movl   $0x4000bc40,(%esp)
40001735:	e8 44 1b 00 00       	call   4000327e <memcmp>
4000173a:	85 c0                	test   %eax,%eax
4000173c:	74 24                	je     40001762 <seekcheck+0xc86>
4000173e:	c7 44 24 0c 9c 79 00 	movl   $0x4000799c,0xc(%esp)
40001745:	40 
40001746:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
4000174d:	40 
4000174e:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
40001755:	00 
40001756:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
4000175d:	e8 82 0e 00 00       	call   400025e4 <debug_panic>

	// The file should still be 1KB larger than its original size
	rc = fstat(fd, &st2); assert(rc >= 0);
40001762:	8d 45 cc             	lea    -0x34(%ebp),%eax
40001765:	89 44 24 04          	mov    %eax,0x4(%esp)
40001769:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000176c:	89 04 24             	mov    %eax,(%esp)
4000176f:	e8 3a 3e 00 00       	call   400055ae <fstat>
40001774:	89 45 ec             	mov    %eax,-0x14(%ebp)
40001777:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
4000177b:	79 24                	jns    400017a1 <seekcheck+0xcc5>
4000177d:	c7 44 24 0c ca 76 00 	movl   $0x400076ca,0xc(%esp)
40001784:	40 
40001785:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
4000178c:	40 
4000178d:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
40001794:	00 
40001795:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
4000179c:	e8 43 0e 00 00       	call   400025e4 <debug_panic>
	assert(st2.st_size == st.st_size + 1024);
400017a1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
400017a4:	8b 55 e0             	mov    -0x20(%ebp),%edx
400017a7:	81 c2 00 04 00 00    	add    $0x400,%edx
400017ad:	39 d0                	cmp    %edx,%eax
400017af:	74 24                	je     400017d5 <seekcheck+0xcf9>
400017b1:	c7 44 24 0c 0c 79 00 	movl   $0x4000790c,0xc(%esp)
400017b8:	40 
400017b9:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400017c0:	40 
400017c1:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
400017c8:	00 
400017c9:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400017d0:	e8 0f 0e 00 00       	call   400025e4 <debug_panic>

	// Restore the parts of the file we mucked with
	rc = lseek(fd, 65536+512, SEEK_SET); assert(rc == 65536+512);
400017d5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
400017dc:	00 
400017dd:	c7 44 24 04 00 02 01 	movl   $0x10200,0x4(%esp)
400017e4:	00 
400017e5:	8b 45 f0             	mov    -0x10(%ebp),%eax
400017e8:	89 04 24             	mov    %eax,(%esp)
400017eb:	e8 7d 3a 00 00       	call   4000526d <lseek>
400017f0:	89 45 ec             	mov    %eax,-0x14(%ebp)
400017f3:	81 7d ec 00 02 01 00 	cmpl   $0x10200,-0x14(%ebp)
400017fa:	74 24                	je     40001820 <seekcheck+0xd44>
400017fc:	c7 44 24 0c 73 78 00 	movl   $0x40007873,0xc(%esp)
40001803:	40 
40001804:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
4000180b:	40 
4000180c:	c7 44 24 04 e6 00 00 	movl   $0xe6,0x4(%esp)
40001813:	00 
40001814:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
4000181b:	e8 c4 0d 00 00       	call   400025e4 <debug_panic>
	act = write(fd, buf+512, 1024); assert(act == 1024);
40001820:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
40001827:	00 
40001828:	c7 44 24 04 40 aa 00 	movl   $0x4000aa40,0x4(%esp)
4000182f:	40 
40001830:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001833:	89 04 24             	mov    %eax,(%esp)
40001836:	e8 fc 39 00 00       	call   40005237 <write>
4000183b:	89 45 e8             	mov    %eax,-0x18(%ebp)
4000183e:	81 7d e8 00 04 00 00 	cmpl   $0x400,-0x18(%ebp)
40001845:	74 24                	je     4000186b <seekcheck+0xd8f>
40001847:	c7 44 24 0c 21 77 00 	movl   $0x40007721,0xc(%esp)
4000184e:	40 
4000184f:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001856:	40 
40001857:	c7 44 24 04 e7 00 00 	movl   $0xe7,0x4(%esp)
4000185e:	00 
4000185f:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001866:	e8 79 0d 00 00       	call   400025e4 <debug_panic>
	rc = lseek(fd, st.st_size-1024, SEEK_SET);
4000186b:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000186e:	2d 00 04 00 00       	sub    $0x400,%eax
40001873:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
4000187a:	00 
4000187b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000187f:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001882:	89 04 24             	mov    %eax,(%esp)
40001885:	e8 e3 39 00 00       	call   4000526d <lseek>
4000188a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(rc == st.st_size-1024);
4000188d:	8b 45 e0             	mov    -0x20(%ebp),%eax
40001890:	2d 00 04 00 00       	sub    $0x400,%eax
40001895:	3b 45 ec             	cmp    -0x14(%ebp),%eax
40001898:	74 24                	je     400018be <seekcheck+0xde2>
4000189a:	c7 44 24 0c 30 78 00 	movl   $0x40007830,0xc(%esp)
400018a1:	40 
400018a2:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400018a9:	40 
400018aa:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
400018b1:	00 
400018b2:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400018b9:	e8 26 0d 00 00       	call   400025e4 <debug_panic>
	act = write(fd, buf2, 2048); assert(act == 2048);
400018be:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
400018c5:	00 
400018c6:	c7 44 24 04 40 b0 00 	movl   $0x4000b040,0x4(%esp)
400018cd:	40 
400018ce:	8b 45 f0             	mov    -0x10(%ebp),%eax
400018d1:	89 04 24             	mov    %eax,(%esp)
400018d4:	e8 5e 39 00 00       	call   40005237 <write>
400018d9:	89 45 e8             	mov    %eax,-0x18(%ebp)
400018dc:	81 7d e8 00 08 00 00 	cmpl   $0x800,-0x18(%ebp)
400018e3:	74 24                	je     40001909 <seekcheck+0xe2d>
400018e5:	c7 44 24 0c fc 76 00 	movl   $0x400076fc,0xc(%esp)
400018ec:	40 
400018ed:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400018f4:	40 
400018f5:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
400018fc:	00 
400018fd:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001904:	e8 db 0c 00 00       	call   400025e4 <debug_panic>
	rc = ftruncate(fd, st.st_size); assert(rc == 0);
40001909:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000190c:	89 44 24 04          	mov    %eax,0x4(%esp)
40001910:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001913:	89 04 24             	mov    %eax,(%esp)
40001916:	e8 03 3b 00 00       	call   4000541e <ftruncate>
4000191b:	89 45 ec             	mov    %eax,-0x14(%ebp)
4000191e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
40001922:	74 24                	je     40001948 <seekcheck+0xe6c>
40001924:	c7 44 24 0c 5d 78 00 	movl   $0x4000785d,0xc(%esp)
4000192b:	40 
4000192c:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001933:	40 
40001934:	c7 44 24 04 eb 00 00 	movl   $0xeb,0x4(%esp)
4000193b:	00 
4000193c:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001943:	e8 9c 0c 00 00       	call   400025e4 <debug_panic>

	// The file should now be back to its original size
	rc = fstat(fd, &st2); assert(rc >= 0);
40001948:	8d 45 cc             	lea    -0x34(%ebp),%eax
4000194b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000194f:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001952:	89 04 24             	mov    %eax,(%esp)
40001955:	e8 54 3c 00 00       	call   400055ae <fstat>
4000195a:	89 45 ec             	mov    %eax,-0x14(%ebp)
4000195d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
40001961:	79 24                	jns    40001987 <seekcheck+0xeab>
40001963:	c7 44 24 0c ca 76 00 	movl   $0x400076ca,0xc(%esp)
4000196a:	40 
4000196b:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001972:	40 
40001973:	c7 44 24 04 ee 00 00 	movl   $0xee,0x4(%esp)
4000197a:	00 
4000197b:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001982:	e8 5d 0c 00 00       	call   400025e4 <debug_panic>
	assert(memcmp(&st, &st2, sizeof(st)) == 0);
40001987:	c7 44 24 08 0c 00 00 	movl   $0xc,0x8(%esp)
4000198e:	00 
4000198f:	8d 45 cc             	lea    -0x34(%ebp),%eax
40001992:	89 44 24 04          	mov    %eax,0x4(%esp)
40001996:	8d 45 d8             	lea    -0x28(%ebp),%eax
40001999:	89 04 24             	mov    %eax,(%esp)
4000199c:	e8 dd 18 00 00       	call   4000327e <memcmp>
400019a1:	85 c0                	test   %eax,%eax
400019a3:	74 24                	je     400019c9 <seekcheck+0xeed>
400019a5:	c7 44 24 0c 94 77 00 	movl   $0x40007794,0xc(%esp)
400019ac:	40 
400019ad:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400019b4:	40 
400019b5:	c7 44 24 04 ef 00 00 	movl   $0xef,0x4(%esp)
400019bc:	00 
400019bd:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400019c4:	e8 1b 0c 00 00       	call   400025e4 <debug_panic>

	// Check that the restorations happened properly
	rc = lseek(fd, 65536, SEEK_SET); assert(rc == 65536);
400019c9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
400019d0:	00 
400019d1:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
400019d8:	00 
400019d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
400019dc:	89 04 24             	mov    %eax,(%esp)
400019df:	e8 89 38 00 00       	call   4000526d <lseek>
400019e4:	89 45 ec             	mov    %eax,-0x14(%ebp)
400019e7:	81 7d ec 00 00 01 00 	cmpl   $0x10000,-0x14(%ebp)
400019ee:	74 24                	je     40001a14 <seekcheck+0xf38>
400019f0:	c7 44 24 0c fd 77 00 	movl   $0x400077fd,0xc(%esp)
400019f7:	40 
400019f8:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400019ff:	40 
40001a00:	c7 44 24 04 f2 00 00 	movl   $0xf2,0x4(%esp)
40001a07:	00 
40001a08:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001a0f:	e8 d0 0b 00 00       	call   400025e4 <debug_panic>
	act = read(fd, buf3, 2048); assert(act == 2048);
40001a14:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
40001a1b:	00 
40001a1c:	c7 44 24 04 40 bc 00 	movl   $0x4000bc40,0x4(%esp)
40001a23:	40 
40001a24:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001a27:	89 04 24             	mov    %eax,(%esp)
40001a2a:	e8 d2 37 00 00       	call   40005201 <read>
40001a2f:	89 45 e8             	mov    %eax,-0x18(%ebp)
40001a32:	81 7d e8 00 08 00 00 	cmpl   $0x800,-0x18(%ebp)
40001a39:	74 24                	je     40001a5f <seekcheck+0xf83>
40001a3b:	c7 44 24 0c fc 76 00 	movl   $0x400076fc,0xc(%esp)
40001a42:	40 
40001a43:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001a4a:	40 
40001a4b:	c7 44 24 04 f3 00 00 	movl   $0xf3,0x4(%esp)
40001a52:	00 
40001a53:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001a5a:	e8 85 0b 00 00       	call   400025e4 <debug_panic>
	assert(memcmp(buf, buf3, 2048) == 0);
40001a5f:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
40001a66:	00 
40001a67:	c7 44 24 04 40 bc 00 	movl   $0x4000bc40,0x4(%esp)
40001a6e:	40 
40001a6f:	c7 04 24 40 a8 00 40 	movl   $0x4000a840,(%esp)
40001a76:	e8 03 18 00 00       	call   4000327e <memcmp>
40001a7b:	85 c0                	test   %eax,%eax
40001a7d:	74 24                	je     40001aa3 <seekcheck+0xfc7>
40001a7f:	c7 44 24 0c d3 79 00 	movl   $0x400079d3,0xc(%esp)
40001a86:	40 
40001a87:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001a8e:	40 
40001a8f:	c7 44 24 04 f4 00 00 	movl   $0xf4,0x4(%esp)
40001a96:	00 
40001a97:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001a9e:	e8 41 0b 00 00       	call   400025e4 <debug_panic>
	rc = lseek(fd, st.st_size-1024, SEEK_SET);
40001aa3:	8b 45 e0             	mov    -0x20(%ebp),%eax
40001aa6:	2d 00 04 00 00       	sub    $0x400,%eax
40001aab:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
40001ab2:	00 
40001ab3:	89 44 24 04          	mov    %eax,0x4(%esp)
40001ab7:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001aba:	89 04 24             	mov    %eax,(%esp)
40001abd:	e8 ab 37 00 00       	call   4000526d <lseek>
40001ac2:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(rc == st.st_size-1024);
40001ac5:	8b 45 e0             	mov    -0x20(%ebp),%eax
40001ac8:	2d 00 04 00 00       	sub    $0x400,%eax
40001acd:	3b 45 ec             	cmp    -0x14(%ebp),%eax
40001ad0:	74 24                	je     40001af6 <seekcheck+0x101a>
40001ad2:	c7 44 24 0c 30 78 00 	movl   $0x40007830,0xc(%esp)
40001ad9:	40 
40001ada:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001ae1:	40 
40001ae2:	c7 44 24 04 f6 00 00 	movl   $0xf6,0x4(%esp)
40001ae9:	00 
40001aea:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001af1:	e8 ee 0a 00 00       	call   400025e4 <debug_panic>
	memset(buf3, 0, 2048);
40001af6:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
40001afd:	00 
40001afe:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001b05:	00 
40001b06:	c7 04 24 40 bc 00 40 	movl   $0x4000bc40,(%esp)
40001b0d:	e8 03 16 00 00       	call   40003115 <memset>
	act = read(fd, buf3, 2048); assert(act == 1024);
40001b12:	c7 44 24 08 00 08 00 	movl   $0x800,0x8(%esp)
40001b19:	00 
40001b1a:	c7 44 24 04 40 bc 00 	movl   $0x4000bc40,0x4(%esp)
40001b21:	40 
40001b22:	8b 45 f0             	mov    -0x10(%ebp),%eax
40001b25:	89 04 24             	mov    %eax,(%esp)
40001b28:	e8 d4 36 00 00       	call   40005201 <read>
40001b2d:	89 45 e8             	mov    %eax,-0x18(%ebp)
40001b30:	81 7d e8 00 04 00 00 	cmpl   $0x400,-0x18(%ebp)
40001b37:	74 24                	je     40001b5d <seekcheck+0x1081>
40001b39:	c7 44 24 0c 21 77 00 	movl   $0x40007721,0xc(%esp)
40001b40:	40 
40001b41:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001b48:	40 
40001b49:	c7 44 24 04 f8 00 00 	movl   $0xf8,0x4(%esp)
40001b50:	00 
40001b51:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001b58:	e8 87 0a 00 00       	call   400025e4 <debug_panic>
	assert(memcmp(buf3, buf2, 1024) == 0);
40001b5d:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
40001b64:	00 
40001b65:	c7 44 24 04 40 b0 00 	movl   $0x4000b040,0x4(%esp)
40001b6c:	40 
40001b6d:	c7 04 24 40 bc 00 40 	movl   $0x4000bc40,(%esp)
40001b74:	e8 05 17 00 00       	call   4000327e <memcmp>
40001b79:	85 c0                	test   %eax,%eax
40001b7b:	74 24                	je     40001ba1 <seekcheck+0x10c5>
40001b7d:	c7 44 24 0c f0 79 00 	movl   $0x400079f0,0xc(%esp)
40001b84:	40 
40001b85:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001b8c:	40 
40001b8d:	c7 44 24 04 f9 00 00 	movl   $0xf9,0x4(%esp)
40001b94:	00 
40001b95:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001b9c:	e8 43 0a 00 00       	call   400025e4 <debug_panic>
	assert(memcmp(buf3+1024, zeros, 1024) == 0);
40001ba1:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
40001ba8:	00 
40001ba9:	c7 44 24 04 40 b8 00 	movl   $0x4000b840,0x4(%esp)
40001bb0:	40 
40001bb1:	c7 04 24 40 c0 00 40 	movl   $0x4000c040,(%esp)
40001bb8:	e8 c1 16 00 00       	call   4000327e <memcmp>
40001bbd:	85 c0                	test   %eax,%eax
40001bbf:	74 24                	je     40001be5 <seekcheck+0x1109>
40001bc1:	c7 44 24 0c 10 7a 00 	movl   $0x40007a10,0xc(%esp)
40001bc8:	40 
40001bc9:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001bd0:	40 
40001bd1:	c7 44 24 04 fa 00 00 	movl   $0xfa,0x4(%esp)
40001bd8:	00 
40001bd9:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001be0:	e8 ff 09 00 00       	call   400025e4 <debug_panic>

	cprintf("seekcheck passed\n");
40001be5:	c7 04 24 34 7a 00 40 	movl   $0x40007a34,(%esp)
40001bec:	e8 87 0c 00 00       	call   40002878 <cprintf>
}
40001bf1:	c9                   	leave  
40001bf2:	c3                   	ret    

40001bf3 <readdircheck>:

void
readdircheck()
{
40001bf3:	55                   	push   %ebp
40001bf4:	89 e5                	mov    %esp,%ebp
40001bf6:	83 ec 48             	sub    $0x48,%esp
	// Do basically the same thing as initfilecheck(),
	// but this time using the "proper" Unix-like opendir/readdir API.
	DIR *d = opendir("/"); assert(d != NULL);
40001bf9:	c7 04 24 46 7a 00 40 	movl   $0x40007a46,(%esp)
40001c00:	e8 dc 2d 00 00       	call   400049e1 <opendir>
40001c05:	89 45 e8             	mov    %eax,-0x18(%ebp)
40001c08:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
40001c0c:	75 24                	jne    40001c32 <readdircheck+0x3f>
40001c0e:	c7 44 24 0c 48 7a 00 	movl   $0x40007a48,0xc(%esp)
40001c15:	40 
40001c16:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001c1d:	40 
40001c1e:	c7 44 24 04 04 01 00 	movl   $0x104,0x4(%esp)
40001c25:	00 
40001c26:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001c2d:	e8 b2 09 00 00       	call   400025e4 <debug_panic>
	struct dirent *de;
	int count = 0, shfound = 0, lsfound = 0;
40001c32:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
40001c39:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
40001c40:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	while ((de = readdir(d)) != NULL) {
40001c47:	e9 5f 02 00 00       	jmp    40001eab <readdircheck+0x2b8>
		struct stat st;
		int rc = stat(de->d_name, &st); assert(rc == 0);
40001c4c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001c4f:	8d 55 d4             	lea    -0x2c(%ebp),%edx
40001c52:	89 54 24 04          	mov    %edx,0x4(%esp)
40001c56:	89 04 24             	mov    %eax,(%esp)
40001c59:	e8 13 39 00 00       	call   40005571 <stat>
40001c5e:	89 45 e0             	mov    %eax,-0x20(%ebp)
40001c61:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
40001c65:	74 24                	je     40001c8b <readdircheck+0x98>
40001c67:	c7 44 24 0c 5d 78 00 	movl   $0x4000785d,0xc(%esp)
40001c6e:	40 
40001c6f:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001c76:	40 
40001c77:	c7 44 24 04 09 01 00 	movl   $0x109,0x4(%esp)
40001c7e:	00 
40001c7f:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001c86:	e8 59 09 00 00       	call   400025e4 <debug_panic>

		cprintf("readdircheck: found file '%s' mode 0x%x size %d\n",
40001c8b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
40001c8e:	8b 55 d8             	mov    -0x28(%ebp),%edx
			de->d_name, st.st_mode, st.st_size);
40001c91:	8b 45 e4             	mov    -0x1c(%ebp),%eax
	int count = 0, shfound = 0, lsfound = 0;
	while ((de = readdir(d)) != NULL) {
		struct stat st;
		int rc = stat(de->d_name, &st); assert(rc == 0);

		cprintf("readdircheck: found file '%s' mode 0x%x size %d\n",
40001c94:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
40001c98:	89 54 24 08          	mov    %edx,0x8(%esp)
40001c9c:	89 44 24 04          	mov    %eax,0x4(%esp)
40001ca0:	c7 04 24 54 7a 00 40 	movl   $0x40007a54,(%esp)
40001ca7:	e8 cc 0b 00 00       	call   40002878 <cprintf>
			de->d_name, st.st_mode, st.st_size);
		count++;
40001cac:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

		// Make sure general properties are as we expect
		if (strcmp(de->d_name, "consin") == 0) {
40001cb0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001cb3:	c7 44 24 04 85 7a 00 	movl   $0x40007a85,0x4(%esp)
40001cba:	40 
40001cbb:	89 04 24             	mov    %eax,(%esp)
40001cbe:	e8 81 13 00 00       	call   40003044 <strcmp>
40001cc3:	85 c0                	test   %eax,%eax
40001cc5:	75 30                	jne    40001cf7 <readdircheck+0x104>
			assert(st.st_ino == FILEINO_CONSIN);
40001cc7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40001cca:	83 f8 01             	cmp    $0x1,%eax
40001ccd:	0f 84 d1 01 00 00    	je     40001ea4 <readdircheck+0x2b1>
40001cd3:	c7 44 24 0c 8c 7a 00 	movl   $0x40007a8c,0xc(%esp)
40001cda:	40 
40001cdb:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001ce2:	40 
40001ce3:	c7 44 24 04 11 01 00 	movl   $0x111,0x4(%esp)
40001cea:	00 
40001ceb:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001cf2:	e8 ed 08 00 00       	call   400025e4 <debug_panic>
			continue;
		}
		if (strcmp(de->d_name, "consout") == 0) {
40001cf7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001cfa:	c7 44 24 04 a8 7a 00 	movl   $0x40007aa8,0x4(%esp)
40001d01:	40 
40001d02:	89 04 24             	mov    %eax,(%esp)
40001d05:	e8 3a 13 00 00       	call   40003044 <strcmp>
40001d0a:	85 c0                	test   %eax,%eax
40001d0c:	75 30                	jne    40001d3e <readdircheck+0x14b>
			assert(st.st_ino == FILEINO_CONSOUT);
40001d0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40001d11:	83 f8 02             	cmp    $0x2,%eax
40001d14:	0f 84 8d 01 00 00    	je     40001ea7 <readdircheck+0x2b4>
40001d1a:	c7 44 24 0c b0 7a 00 	movl   $0x40007ab0,0xc(%esp)
40001d21:	40 
40001d22:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001d29:	40 
40001d2a:	c7 44 24 04 15 01 00 	movl   $0x115,0x4(%esp)
40001d31:	00 
40001d32:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001d39:	e8 a6 08 00 00       	call   400025e4 <debug_panic>
			continue;
		}
		if (strcmp(de->d_name, "/") == 0) {
40001d3e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001d41:	c7 44 24 04 46 7a 00 	movl   $0x40007a46,0x4(%esp)
40001d48:	40 
40001d49:	89 04 24             	mov    %eax,(%esp)
40001d4c:	e8 f3 12 00 00       	call   40003044 <strcmp>
40001d51:	85 c0                	test   %eax,%eax
40001d53:	75 5e                	jne    40001db3 <readdircheck+0x1c0>
			assert(st.st_ino == FILEINO_ROOTDIR);
40001d55:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40001d58:	83 f8 03             	cmp    $0x3,%eax
40001d5b:	74 24                	je     40001d81 <readdircheck+0x18e>
40001d5d:	c7 44 24 0c cd 7a 00 	movl   $0x40007acd,0xc(%esp)
40001d64:	40 
40001d65:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001d6c:	40 
40001d6d:	c7 44 24 04 19 01 00 	movl   $0x119,0x4(%esp)
40001d74:	00 
40001d75:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001d7c:	e8 63 08 00 00       	call   400025e4 <debug_panic>
			assert(st.st_mode == S_IFDIR);
40001d81:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001d84:	3d 00 20 00 00       	cmp    $0x2000,%eax
40001d89:	0f 84 1b 01 00 00    	je     40001eaa <readdircheck+0x2b7>
40001d8f:	c7 44 24 0c ea 7a 00 	movl   $0x40007aea,0xc(%esp)
40001d96:	40 
40001d97:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001d9e:	40 
40001d9f:	c7 44 24 04 1a 01 00 	movl   $0x11a,0x4(%esp)
40001da6:	00 
40001da7:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001dae:	e8 31 08 00 00       	call   400025e4 <debug_panic>
			continue;
		}

		// everything else should be a regular file
		assert(st.st_ino >= FILEINO_GENERAL);
40001db3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40001db6:	83 f8 03             	cmp    $0x3,%eax
40001db9:	7f 24                	jg     40001ddf <readdircheck+0x1ec>
40001dbb:	c7 44 24 0c 00 7b 00 	movl   $0x40007b00,0xc(%esp)
40001dc2:	40 
40001dc3:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001dca:	40 
40001dcb:	c7 44 24 04 1f 01 00 	movl   $0x11f,0x4(%esp)
40001dd2:	00 
40001dd3:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001dda:	e8 05 08 00 00       	call   400025e4 <debug_panic>
		assert(st.st_ino < FILE_INODES);
40001ddf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40001de2:	3d ff 00 00 00       	cmp    $0xff,%eax
40001de7:	7e 24                	jle    40001e0d <readdircheck+0x21a>
40001de9:	c7 44 24 0c 1d 7b 00 	movl   $0x40007b1d,0xc(%esp)
40001df0:	40 
40001df1:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001df8:	40 
40001df9:	c7 44 24 04 20 01 00 	movl   $0x120,0x4(%esp)
40001e00:	00 
40001e01:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001e08:	e8 d7 07 00 00       	call   400025e4 <debug_panic>
		assert(st.st_mode == S_IFREG);
40001e0d:	8b 45 d8             	mov    -0x28(%ebp),%eax
40001e10:	3d 00 10 00 00       	cmp    $0x1000,%eax
40001e15:	74 24                	je     40001e3b <readdircheck+0x248>
40001e17:	c7 44 24 0c 35 7b 00 	movl   $0x40007b35,0xc(%esp)
40001e1e:	40 
40001e1f:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001e26:	40 
40001e27:	c7 44 24 04 21 01 00 	movl   $0x121,0x4(%esp)
40001e2e:	00 
40001e2f:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001e36:	e8 a9 07 00 00       	call   400025e4 <debug_panic>
		assert(st.st_size > 0);
40001e3b:	8b 45 dc             	mov    -0x24(%ebp),%eax
40001e3e:	85 c0                	test   %eax,%eax
40001e40:	7f 24                	jg     40001e66 <readdircheck+0x273>
40001e42:	c7 44 24 0c e6 76 00 	movl   $0x400076e6,0xc(%esp)
40001e49:	40 
40001e4a:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001e51:	40 
40001e52:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
40001e59:	00 
40001e5a:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001e61:	e8 7e 07 00 00       	call   400025e4 <debug_panic>

		// Make sure a couple specific files we're expecting show up
		if (strcmp(de->d_name, "sh") == 0)
40001e66:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001e69:	c7 44 24 04 ef 75 00 	movl   $0x400075ef,0x4(%esp)
40001e70:	40 
40001e71:	89 04 24             	mov    %eax,(%esp)
40001e74:	e8 cb 11 00 00       	call   40003044 <strcmp>
40001e79:	85 c0                	test   %eax,%eax
40001e7b:	75 07                	jne    40001e84 <readdircheck+0x291>
			shfound = 1;
40001e7d:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
		if (strcmp(de->d_name, "ls") == 0)
40001e84:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40001e87:	c7 44 24 04 16 76 00 	movl   $0x40007616,0x4(%esp)
40001e8e:	40 
40001e8f:	89 04 24             	mov    %eax,(%esp)
40001e92:	e8 ad 11 00 00       	call   40003044 <strcmp>
40001e97:	85 c0                	test   %eax,%eax
40001e99:	75 10                	jne    40001eab <readdircheck+0x2b8>
			lsfound = 1;
40001e9b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
40001ea2:	eb 07                	jmp    40001eab <readdircheck+0x2b8>
		count++;

		// Make sure general properties are as we expect
		if (strcmp(de->d_name, "consin") == 0) {
			assert(st.st_ino == FILEINO_CONSIN);
			continue;
40001ea4:	90                   	nop
40001ea5:	eb 04                	jmp    40001eab <readdircheck+0x2b8>
		}
		if (strcmp(de->d_name, "consout") == 0) {
			assert(st.st_ino == FILEINO_CONSOUT);
			continue;
40001ea7:	90                   	nop
40001ea8:	eb 01                	jmp    40001eab <readdircheck+0x2b8>
		}
		if (strcmp(de->d_name, "/") == 0) {
			assert(st.st_ino == FILEINO_ROOTDIR);
			assert(st.st_mode == S_IFDIR);
			continue;
40001eaa:	90                   	nop
	// Do basically the same thing as initfilecheck(),
	// but this time using the "proper" Unix-like opendir/readdir API.
	DIR *d = opendir("/"); assert(d != NULL);
	struct dirent *de;
	int count = 0, shfound = 0, lsfound = 0;
	while ((de = readdir(d)) != NULL) {
40001eab:	8b 45 e8             	mov    -0x18(%ebp),%eax
40001eae:	89 04 24             	mov    %eax,(%esp)
40001eb1:	e8 3c 2c 00 00       	call   40004af2 <readdir>
40001eb6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
40001eb9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
40001ebd:	0f 85 89 fd ff ff    	jne    40001c4c <readdircheck+0x59>
		if (strcmp(de->d_name, "ls") == 0)
			lsfound = 1;
	}

	// Make sure we found a "reasonable" number of populated entries
	assert(count >= 5);
40001ec3:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
40001ec7:	7f 24                	jg     40001eed <readdircheck+0x2fa>
40001ec9:	c7 44 24 0c 93 76 00 	movl   $0x40007693,0xc(%esp)
40001ed0:	40 
40001ed1:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001ed8:	40 
40001ed9:	c7 44 24 04 2c 01 00 	movl   $0x12c,0x4(%esp)
40001ee0:	00 
40001ee1:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001ee8:	e8 f7 06 00 00       	call   400025e4 <debug_panic>
	assert(shfound != 0);
40001eed:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40001ef1:	75 24                	jne    40001f17 <readdircheck+0x324>
40001ef3:	c7 44 24 0c 4b 7b 00 	movl   $0x40007b4b,0xc(%esp)
40001efa:	40 
40001efb:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001f02:	40 
40001f03:	c7 44 24 04 2d 01 00 	movl   $0x12d,0x4(%esp)
40001f0a:	00 
40001f0b:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001f12:	e8 cd 06 00 00       	call   400025e4 <debug_panic>
	assert(lsfound != 0);
40001f17:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
40001f1b:	75 24                	jne    40001f41 <readdircheck+0x34e>
40001f1d:	c7 44 24 0c 58 7b 00 	movl   $0x40007b58,0xc(%esp)
40001f24:	40 
40001f25:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001f2c:	40 
40001f2d:	c7 44 24 04 2e 01 00 	movl   $0x12e,0x4(%esp)
40001f34:	00 
40001f35:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001f3c:	e8 a3 06 00 00       	call   400025e4 <debug_panic>
	assert(count == initfilecheck_count);
40001f41:	a1 80 dc 00 40       	mov    0x4000dc80,%eax
40001f46:	39 45 f4             	cmp    %eax,-0xc(%ebp)
40001f49:	74 24                	je     40001f6f <readdircheck+0x37c>
40001f4b:	c7 44 24 0c 65 7b 00 	movl   $0x40007b65,0xc(%esp)
40001f52:	40 
40001f53:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40001f5a:	40 
40001f5b:	c7 44 24 04 2f 01 00 	movl   $0x12f,0x4(%esp)
40001f62:	00 
40001f63:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40001f6a:	e8 75 06 00 00       	call   400025e4 <debug_panic>

	cprintf("readdircheck passed\n");
40001f6f:	c7 04 24 82 7b 00 40 	movl   $0x40007b82,(%esp)
40001f76:	e8 fd 08 00 00       	call   40002878 <cprintf>
}
40001f7b:	c9                   	leave  
40001f7c:	c3                   	ret    

40001f7d <consoutcheck>:

void
consoutcheck()
{
40001f7d:	55                   	push   %ebp
40001f7e:	89 e5                	mov    %esp,%ebp
40001f80:	83 ec 48             	sub    $0x48,%esp
	// Write some text to our 'consout' special file in a few ways
	const char outstr[] = "conscheck: write() to STDOUT_FILENO\n";
40001f83:	c7 45 cf 63 6f 6e 73 	movl   $0x736e6f63,-0x31(%ebp)
40001f8a:	c7 45 d3 63 68 65 63 	movl   $0x63656863,-0x2d(%ebp)
40001f91:	c7 45 d7 6b 3a 20 77 	movl   $0x77203a6b,-0x29(%ebp)
40001f98:	c7 45 db 72 69 74 65 	movl   $0x65746972,-0x25(%ebp)
40001f9f:	c7 45 df 28 29 20 74 	movl   $0x74202928,-0x21(%ebp)
40001fa6:	c7 45 e3 6f 20 53 54 	movl   $0x5453206f,-0x1d(%ebp)
40001fad:	c7 45 e7 44 4f 55 54 	movl   $0x54554f44,-0x19(%ebp)
40001fb4:	c7 45 eb 5f 46 49 4c 	movl   $0x4c49465f,-0x15(%ebp)
40001fbb:	c7 45 ef 45 4e 4f 0a 	movl   $0xa4f4e45,-0x11(%ebp)
40001fc2:	c6 45 f3 00          	movb   $0x0,-0xd(%ebp)
	write(STDOUT_FILENO, outstr, strlen(outstr));
40001fc6:	8d 45 cf             	lea    -0x31(%ebp),%eax
40001fc9:	89 04 24             	mov    %eax,(%esp)
40001fcc:	e8 87 0f 00 00       	call   40002f58 <strlen>
40001fd1:	89 44 24 08          	mov    %eax,0x8(%esp)
40001fd5:	8d 45 cf             	lea    -0x31(%ebp),%eax
40001fd8:	89 44 24 04          	mov    %eax,0x4(%esp)
40001fdc:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
40001fe3:	e8 4f 32 00 00       	call   40005237 <write>
	fprintf(stdout, "conscheck: fprintf() to 'stdout'\n");
40001fe8:	a1 dc 83 00 40       	mov    0x400083dc,%eax
40001fed:	c7 44 24 04 98 7b 00 	movl   $0x40007b98,0x4(%esp)
40001ff4:	40 
40001ff5:	89 04 24             	mov    %eax,(%esp)
40001ff8:	e8 a6 4e 00 00       	call   40006ea3 <fprintf>
	FILE *f = fopen("consout", "a"); assert(f != NULL);
40001ffd:	c7 44 24 04 ba 7b 00 	movl   $0x40007bba,0x4(%esp)
40002004:	40 
40002005:	c7 04 24 a8 7a 00 40 	movl   $0x40007aa8,(%esp)
4000200c:	e8 eb 2b 00 00       	call   40004bfc <fopen>
40002011:	89 45 f4             	mov    %eax,-0xc(%ebp)
40002014:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002018:	75 24                	jne    4000203e <consoutcheck+0xc1>
4000201a:	c7 44 24 0c bc 7b 00 	movl   $0x40007bbc,0xc(%esp)
40002021:	40 
40002022:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40002029:	40 
4000202a:	c7 44 24 04 3b 01 00 	movl   $0x13b,0x4(%esp)
40002031:	00 
40002032:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40002039:	e8 a6 05 00 00       	call   400025e4 <debug_panic>
	fprintf(f, "conscheck: fprintf() to 'consout' file\n");
4000203e:	c7 44 24 04 c8 7b 00 	movl   $0x40007bc8,0x4(%esp)
40002045:	40 
40002046:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002049:	89 04 24             	mov    %eax,(%esp)
4000204c:	e8 52 4e 00 00       	call   40006ea3 <fprintf>
	fclose(f);
40002051:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002054:	89 04 24             	mov    %eax,(%esp)
40002057:	e8 00 2d 00 00       	call   40004d5c <fclose>

	cprintf("Buffered console output should NOT have appeared yet\n");
4000205c:	c7 04 24 f0 7b 00 40 	movl   $0x40007bf0,(%esp)
40002063:	e8 10 08 00 00       	call   40002878 <cprintf>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40002068:	b8 03 00 00 00       	mov    $0x3,%eax
4000206d:	cd 30                	int    $0x30
	sys_ret();	// Synchronize with the kernel, deliver console output
	cprintf("Buffered console output SHOULD have appeared now\n");
4000206f:	c7 04 24 28 7c 00 40 	movl   $0x40007c28,(%esp)
40002076:	e8 fd 07 00 00       	call   40002878 <cprintf>

	// More of the same, just all on one line for easy checking...
	write(STDOUT_FILENO, "456", 3);
4000207b:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
40002082:	00 
40002083:	c7 44 24 04 5a 7c 00 	movl   $0x40007c5a,0x4(%esp)
4000208a:	40 
4000208b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
40002092:	e8 a0 31 00 00       	call   40005237 <write>
	cprintf("123");
40002097:	c7 04 24 5e 7c 00 40 	movl   $0x40007c5e,(%esp)
4000209e:	e8 d5 07 00 00       	call   40002878 <cprintf>
400020a3:	b8 03 00 00 00       	mov    $0x3,%eax
400020a8:	cd 30                	int    $0x30
	sys_ret();
	write(STDOUT_FILENO, "\n", 1);
400020aa:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
400020b1:	00 
400020b2:	c7 44 24 04 62 7c 00 	movl   $0x40007c62,0x4(%esp)
400020b9:	40 
400020ba:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
400020c1:	e8 71 31 00 00       	call   40005237 <write>
	cprintf("789");
400020c6:	c7 04 24 64 7c 00 40 	movl   $0x40007c64,(%esp)
400020cd:	e8 a6 07 00 00       	call   40002878 <cprintf>
400020d2:	b8 03 00 00 00       	mov    $0x3,%eax
400020d7:	cd 30                	int    $0x30
	sys_ret();

	cprintf("consoutcheck done\n");
400020d9:	c7 04 24 68 7c 00 40 	movl   $0x40007c68,(%esp)
400020e0:	e8 93 07 00 00       	call   40002878 <cprintf>
}
400020e5:	c9                   	leave  
400020e6:	c3                   	ret    

400020e7 <consincheck>:

void
consincheck()
{
400020e7:	55                   	push   %ebp
400020e8:	89 e5                	mov    %esp,%ebp
400020ea:	83 ec 28             	sub    $0x28,%esp
	char *str = readline("Enter something: ");
400020ed:	c7 04 24 7b 7c 00 40 	movl   $0x40007c7b,(%esp)
400020f4:	e8 57 4e 00 00       	call   40006f50 <readline>
400020f9:	89 45 f4             	mov    %eax,-0xc(%ebp)
	printf("You typed: %s\n", str);
400020fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
400020ff:	89 44 24 04          	mov    %eax,0x4(%esp)
40002103:	c7 04 24 8d 7c 00 40 	movl   $0x40007c8d,(%esp)
4000210a:	e8 c4 4d 00 00       	call   40006ed3 <printf>
4000210f:	b8 03 00 00 00       	mov    $0x3,%eax
40002114:	cd 30                	int    $0x30
	sys_ret();

	cprintf("consincheck done\n");
40002116:	c7 04 24 9c 7c 00 40 	movl   $0x40007c9c,(%esp)
4000211d:	e8 56 07 00 00       	call   40002878 <cprintf>
}
40002122:	c9                   	leave  
40002123:	c3                   	ret    

40002124 <spawn>:

pid_t
spawn(const char *arg0, ...)
{
40002124:	55                   	push   %ebp
40002125:	89 e5                	mov    %esp,%ebp
40002127:	83 ec 28             	sub    $0x28,%esp
	pid_t pid = fork();
4000212a:	e8 b5 35 00 00       	call   400056e4 <fork>
4000212f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (pid == 0) {		// We're the child.
40002132:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002136:	75 41                	jne    40002179 <spawn+0x55>
		execv(arg0, (char *const *)&arg0);
40002138:	8b 45 08             	mov    0x8(%ebp),%eax
4000213b:	8d 55 08             	lea    0x8(%ebp),%edx
4000213e:	89 54 24 04          	mov    %edx,0x4(%esp)
40002142:	89 04 24             	mov    %eax,(%esp)
40002145:	e8 c0 44 00 00       	call   4000660a <execv>
		panic("execl() failed: %s\n", strerror(errno));
4000214a:	a1 8c 80 00 40       	mov    0x4000808c,%eax
4000214f:	8b 00                	mov    (%eax),%eax
40002151:	89 04 24             	mov    %eax,(%esp)
40002154:	e8 ab 4d 00 00       	call   40006f04 <strerror>
40002159:	89 44 24 0c          	mov    %eax,0xc(%esp)
4000215d:	c7 44 24 08 ae 7c 00 	movl   $0x40007cae,0x8(%esp)
40002164:	40 
40002165:	c7 44 24 04 5e 01 00 	movl   $0x15e,0x4(%esp)
4000216c:	00 
4000216d:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40002174:	e8 6b 04 00 00       	call   400025e4 <debug_panic>
	}
	assert(pid > 0);	// We're the parent.
40002179:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
4000217d:	7f 24                	jg     400021a3 <spawn+0x7f>
4000217f:	c7 44 24 0c c2 7c 00 	movl   $0x40007cc2,0xc(%esp)
40002186:	40 
40002187:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
4000218e:	40 
4000218f:	c7 44 24 04 60 01 00 	movl   $0x160,0x4(%esp)
40002196:	00 
40002197:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
4000219e:	e8 41 04 00 00       	call   400025e4 <debug_panic>
	return pid;
400021a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
400021a6:	c9                   	leave  
400021a7:	c3                   	ret    

400021a8 <waitcheckstatus>:

void
waitcheckstatus(pid_t pid, int statexpect)
{
400021a8:	55                   	push   %ebp
400021a9:	89 e5                	mov    %esp,%ebp
400021ab:	83 ec 28             	sub    $0x28,%esp
	// Wait for the child to finish executing, and collect its status.
	int status = 0xdeadbeef;
400021ae:	c7 45 f4 ef be ad de 	movl   $0xdeadbeef,-0xc(%ebp)
	waitpid(pid, &status, 0);
400021b5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
400021bc:	00 
400021bd:	8d 45 f4             	lea    -0xc(%ebp),%eax
400021c0:	89 44 24 04          	mov    %eax,0x4(%esp)
400021c4:	8b 45 08             	mov    0x8(%ebp),%eax
400021c7:	89 04 24             	mov    %eax,(%esp)
400021ca:	e8 98 37 00 00       	call   40005967 <waitpid>
	assert(WIFEXITED(status));
400021cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
400021d2:	25 00 0f 00 00       	and    $0xf00,%eax
400021d7:	3d 00 01 00 00       	cmp    $0x100,%eax
400021dc:	74 24                	je     40002202 <waitcheckstatus+0x5a>
400021de:	c7 44 24 0c ca 7c 00 	movl   $0x40007cca,0xc(%esp)
400021e5:	40 
400021e6:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400021ed:	40 
400021ee:	c7 44 24 04 6a 01 00 	movl   $0x16a,0x4(%esp)
400021f5:	00 
400021f6:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400021fd:	e8 e2 03 00 00       	call   400025e4 <debug_panic>
	assert(WEXITSTATUS(status) == statexpect);
40002202:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002205:	25 ff 00 00 00       	and    $0xff,%eax
4000220a:	3b 45 0c             	cmp    0xc(%ebp),%eax
4000220d:	74 24                	je     40002233 <waitcheckstatus+0x8b>
4000220f:	c7 44 24 0c dc 7c 00 	movl   $0x40007cdc,0xc(%esp)
40002216:	40 
40002217:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
4000221e:	40 
4000221f:	c7 44 24 04 6b 01 00 	movl   $0x16b,0x4(%esp)
40002226:	00 
40002227:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
4000222e:	e8 b1 03 00 00       	call   400025e4 <debug_panic>
}
40002233:	c9                   	leave  
40002234:	c3                   	ret    

40002235 <execcheck>:
#define waitcheck(pid) waitcheckstatus(pid, 0)

void
execcheck()
{
40002235:	55                   	push   %ebp
40002236:	89 e5                	mov    %esp,%ebp
40002238:	83 ec 28             	sub    $0x28,%esp
	waitcheck(spawn("echo", "-c", "called", "by", "execcheck", NULL));
4000223b:	c7 44 24 14 00 00 00 	movl   $0x0,0x14(%esp)
40002242:	00 
40002243:	c7 44 24 10 fe 7c 00 	movl   $0x40007cfe,0x10(%esp)
4000224a:	40 
4000224b:	c7 44 24 0c 08 7d 00 	movl   $0x40007d08,0xc(%esp)
40002252:	40 
40002253:	c7 44 24 08 0b 7d 00 	movl   $0x40007d0b,0x8(%esp)
4000225a:	40 
4000225b:	c7 44 24 04 12 7d 00 	movl   $0x40007d12,0x4(%esp)
40002262:	40 
40002263:	c7 04 24 15 7d 00 40 	movl   $0x40007d15,(%esp)
4000226a:	e8 b5 fe ff ff       	call   40002124 <spawn>
4000226f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002276:	00 
40002277:	89 04 24             	mov    %eax,(%esp)
4000227a:	e8 29 ff ff ff       	call   400021a8 <waitcheckstatus>

	cprintf("execcheck done\n");
4000227f:	c7 04 24 1a 7d 00 40 	movl   $0x40007d1a,(%esp)
40002286:	e8 ed 05 00 00       	call   40002878 <cprintf>
}
4000228b:	c9                   	leave  
4000228c:	c3                   	ret    

4000228d <forkwrite>:

pid_t forkwrite(const char *filename)
{
4000228d:	55                   	push   %ebp
4000228e:	89 e5                	mov    %esp,%ebp
40002290:	83 ec 28             	sub    $0x28,%esp
	pid_t pid = fork();
40002293:	e8 4c 34 00 00       	call   400056e4 <fork>
40002298:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (pid == 0) {		// We're the child.
4000229b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
4000229f:	75 71                	jne    40002312 <forkwrite+0x85>
		FILE *f = fopen(filename, "w"); assert(f != NULL);
400022a1:	c7 44 24 04 2a 7d 00 	movl   $0x40007d2a,0x4(%esp)
400022a8:	40 
400022a9:	8b 45 08             	mov    0x8(%ebp),%eax
400022ac:	89 04 24             	mov    %eax,(%esp)
400022af:	e8 48 29 00 00       	call   40004bfc <fopen>
400022b4:	89 45 f0             	mov    %eax,-0x10(%ebp)
400022b7:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400022bb:	75 24                	jne    400022e1 <forkwrite+0x54>
400022bd:	c7 44 24 0c bc 7b 00 	movl   $0x40007bbc,0xc(%esp)
400022c4:	40 
400022c5:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
400022cc:	40 
400022cd:	c7 44 24 04 7b 01 00 	movl   $0x17b,0x4(%esp)
400022d4:	00 
400022d5:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400022dc:	e8 03 03 00 00       	call   400025e4 <debug_panic>
		fprintf(f, "forkwrite: %s\n", filename);
400022e1:	8b 45 08             	mov    0x8(%ebp),%eax
400022e4:	89 44 24 08          	mov    %eax,0x8(%esp)
400022e8:	c7 44 24 04 2c 7d 00 	movl   $0x40007d2c,0x4(%esp)
400022ef:	40 
400022f0:	8b 45 f0             	mov    -0x10(%ebp),%eax
400022f3:	89 04 24             	mov    %eax,(%esp)
400022f6:	e8 a8 4b 00 00       	call   40006ea3 <fprintf>
		fclose(f);
400022fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
400022fe:	89 04 24             	mov    %eax,(%esp)
40002301:	e8 56 2a 00 00       	call   40004d5c <fclose>
		exit(0);
40002306:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000230d:	e8 de 2d 00 00       	call   400050f0 <exit>
	}
	assert(pid > 0);	// We're the parent.
40002312:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002316:	7f 24                	jg     4000233c <forkwrite+0xaf>
40002318:	c7 44 24 0c c2 7c 00 	movl   $0x40007cc2,0xc(%esp)
4000231f:	40 
40002320:	c7 44 24 08 6a 75 00 	movl   $0x4000756a,0x8(%esp)
40002327:	40 
40002328:	c7 44 24 04 80 01 00 	movl   $0x180,0x4(%esp)
4000232f:	00 
40002330:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
40002337:	e8 a8 02 00 00       	call   400025e4 <debug_panic>
	return pid;
4000233c:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
4000233f:	c9                   	leave  
40002340:	c3                   	ret    

40002341 <reconcilecheck>:

void
reconcilecheck()
{
40002341:	55                   	push   %ebp
40002342:	89 e5                	mov    %esp,%ebp
40002344:	83 ec 38             	sub    $0x38,%esp
	// First fork off a child process that just writes one file,
	// and make sure it appears when we subsequently 'cat' it.
	waitcheck(forkwrite("reconcilefile0"));
40002347:	c7 04 24 3b 7d 00 40 	movl   $0x40007d3b,(%esp)
4000234e:	e8 3a ff ff ff       	call   4000228d <forkwrite>
40002353:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000235a:	00 
4000235b:	89 04 24             	mov    %eax,(%esp)
4000235e:	e8 45 fe ff ff       	call   400021a8 <waitcheckstatus>
	waitcheck(spawn("cat", "reconcilefile0", NULL));
40002363:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
4000236a:	00 
4000236b:	c7 44 24 04 3b 7d 00 	movl   $0x40007d3b,0x4(%esp)
40002372:	40 
40002373:	c7 04 24 4a 7d 00 40 	movl   $0x40007d4a,(%esp)
4000237a:	e8 a5 fd ff ff       	call   40002124 <spawn>
4000237f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002386:	00 
40002387:	89 04 24             	mov    %eax,(%esp)
4000238a:	e8 19 fe ff ff       	call   400021a8 <waitcheckstatus>

	// Now try two concurrent, non-conflicting writes.
	pid_t p1 = forkwrite("reconcilefile1");
4000238f:	c7 04 24 4e 7d 00 40 	movl   $0x40007d4e,(%esp)
40002396:	e8 f2 fe ff ff       	call   4000228d <forkwrite>
4000239b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	pid_t p2 = forkwrite("reconcilefile2");
4000239e:	c7 04 24 5d 7d 00 40 	movl   $0x40007d5d,(%esp)
400023a5:	e8 e3 fe ff ff       	call   4000228d <forkwrite>
400023aa:	89 45 f0             	mov    %eax,-0x10(%ebp)
	waitcheck(p1);
400023ad:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400023b4:	00 
400023b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
400023b8:	89 04 24             	mov    %eax,(%esp)
400023bb:	e8 e8 fd ff ff       	call   400021a8 <waitcheckstatus>
	waitcheck(p2);
400023c0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400023c7:	00 
400023c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
400023cb:	89 04 24             	mov    %eax,(%esp)
400023ce:	e8 d5 fd ff ff       	call   400021a8 <waitcheckstatus>
	waitcheck(spawn("cat", "reconcilefile1", NULL));
400023d3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
400023da:	00 
400023db:	c7 44 24 04 4e 7d 00 	movl   $0x40007d4e,0x4(%esp)
400023e2:	40 
400023e3:	c7 04 24 4a 7d 00 40 	movl   $0x40007d4a,(%esp)
400023ea:	e8 35 fd ff ff       	call   40002124 <spawn>
400023ef:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400023f6:	00 
400023f7:	89 04 24             	mov    %eax,(%esp)
400023fa:	e8 a9 fd ff ff       	call   400021a8 <waitcheckstatus>
	waitcheck(spawn("cat", "reconcilefile2", NULL));
400023ff:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
40002406:	00 
40002407:	c7 44 24 04 5d 7d 00 	movl   $0x40007d5d,0x4(%esp)
4000240e:	40 
4000240f:	c7 04 24 4a 7d 00 40 	movl   $0x40007d4a,(%esp)
40002416:	e8 09 fd ff ff       	call   40002124 <spawn>
4000241b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002422:	00 
40002423:	89 04 24             	mov    %eax,(%esp)
40002426:	e8 7d fd ff ff       	call   400021a8 <waitcheckstatus>

	// Now try two concurrent, conflicting writes.
	p1 = forkwrite("reconcilefileC");
4000242b:	c7 04 24 6c 7d 00 40 	movl   $0x40007d6c,(%esp)
40002432:	e8 56 fe ff ff       	call   4000228d <forkwrite>
40002437:	89 45 f4             	mov    %eax,-0xc(%ebp)
	p2 = forkwrite("reconcilefileC");
4000243a:	c7 04 24 6c 7d 00 40 	movl   $0x40007d6c,(%esp)
40002441:	e8 47 fe ff ff       	call   4000228d <forkwrite>
40002446:	89 45 f0             	mov    %eax,-0x10(%ebp)
	waitcheck(p1);
40002449:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002450:	00 
40002451:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002454:	89 04 24             	mov    %eax,(%esp)
40002457:	e8 4c fd ff ff       	call   400021a8 <waitcheckstatus>
	waitcheck(p2);
4000245c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002463:	00 
40002464:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002467:	89 04 24             	mov    %eax,(%esp)
4000246a:	e8 39 fd ff ff       	call   400021a8 <waitcheckstatus>
	waitcheckstatus(spawn("cat", "reconcilefileC", NULL), 1); // fails!
4000246f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
40002476:	00 
40002477:	c7 44 24 04 6c 7d 00 	movl   $0x40007d6c,0x4(%esp)
4000247e:	40 
4000247f:	c7 04 24 4a 7d 00 40 	movl   $0x40007d4a,(%esp)
40002486:	e8 99 fc ff ff       	call   40002124 <spawn>
4000248b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40002492:	00 
40002493:	89 04 24             	mov    %eax,(%esp)
40002496:	e8 0d fd ff ff       	call   400021a8 <waitcheckstatus>
	waitcheck(spawn("ls", "-l", NULL));
4000249b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
400024a2:	00 
400024a3:	c7 44 24 04 7b 7d 00 	movl   $0x40007d7b,0x4(%esp)
400024aa:	40 
400024ab:	c7 04 24 16 76 00 40 	movl   $0x40007616,(%esp)
400024b2:	e8 6d fc ff ff       	call   40002124 <spawn>
400024b7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400024be:	00 
400024bf:	89 04 24             	mov    %eax,(%esp)
400024c2:	e8 e1 fc ff ff       	call   400021a8 <waitcheckstatus>

	cprintf("reconcilecheck: basic file reconciliation successful\n");
400024c7:	c7 04 24 80 7d 00 40 	movl   $0x40007d80,(%esp)
400024ce:	e8 a5 03 00 00       	call   40002878 <cprintf>

	// Reconcile append-only console output
	printf("reconcilecheck: running echo\n");
400024d3:	c7 04 24 b6 7d 00 40 	movl   $0x40007db6,(%esp)
400024da:	e8 f4 49 00 00       	call   40006ed3 <printf>
	pid_t pid = spawn("echo", "called", "by", "reconcilecheck", NULL);
400024df:	c7 44 24 10 00 00 00 	movl   $0x0,0x10(%esp)
400024e6:	00 
400024e7:	c7 44 24 0c d4 7d 00 	movl   $0x40007dd4,0xc(%esp)
400024ee:	40 
400024ef:	c7 44 24 08 08 7d 00 	movl   $0x40007d08,0x8(%esp)
400024f6:	40 
400024f7:	c7 44 24 04 0b 7d 00 	movl   $0x40007d0b,0x4(%esp)
400024fe:	40 
400024ff:	c7 04 24 15 7d 00 40 	movl   $0x40007d15,(%esp)
40002506:	e8 19 fc ff ff       	call   40002124 <spawn>
4000250b:	89 45 ec             	mov    %eax,-0x14(%ebp)
	printf("reconcilecheck: echo running\n");
4000250e:	c7 04 24 e3 7d 00 40 	movl   $0x40007de3,(%esp)
40002515:	e8 b9 49 00 00       	call   40006ed3 <printf>
	waitcheck(pid);
4000251a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002521:	00 
40002522:	8b 45 ec             	mov    -0x14(%ebp),%eax
40002525:	89 04 24             	mov    %eax,(%esp)
40002528:	e8 7b fc ff ff       	call   400021a8 <waitcheckstatus>
	printf("reconcilecheck: echo finished\n");
4000252d:	c7 04 24 04 7e 00 40 	movl   $0x40007e04,(%esp)
40002534:	e8 9a 49 00 00       	call   40006ed3 <printf>
40002539:	b8 03 00 00 00       	mov    $0x3,%eax
4000253e:	cd 30                	int    $0x30
	sys_ret();	// flush this output to the real console

	cprintf("reconcilecheck done\n");
40002540:	c7 04 24 23 7e 00 40 	movl   $0x40007e23,(%esp)
40002547:	e8 2c 03 00 00       	call   40002878 <cprintf>
}
4000254c:	c9                   	leave  
4000254d:	c3                   	ret    

4000254e <main>:

int
main()
{
4000254e:	55                   	push   %ebp
4000254f:	89 e5                	mov    %esp,%ebp
40002551:	83 e4 f0             	and    $0xfffffff0,%esp
40002554:	83 ec 10             	sub    $0x10,%esp
	cprintf("testfs: in main()\n");
40002557:	c7 04 24 38 7e 00 40 	movl   $0x40007e38,(%esp)
4000255e:	e8 15 03 00 00       	call   40002878 <cprintf>

	initfilecheck();
40002563:	e8 dc db ff ff       	call   40000144 <initfilecheck>
	readwritecheck();
40002568:	e8 45 e0 ff ff       	call   400005b2 <readwritecheck>
	seekcheck();
4000256d:	e8 6a e5 ff ff       	call   40000adc <seekcheck>
	readdircheck();
40002572:	e8 7c f6 ff ff       	call   40001bf3 <readdircheck>

	consoutcheck();
40002577:	e8 01 fa ff ff       	call   40001f7d <consoutcheck>
	consincheck();
4000257c:	e8 66 fb ff ff       	call   400020e7 <consincheck>

	execcheck();
40002581:	e8 af fc ff ff       	call   40002235 <execcheck>

	reconcilecheck();
40002586:	e8 b6 fd ff ff       	call   40002341 <reconcilecheck>

	cprintf("testfs: all tests completed; starting shell...\n");
4000258b:	c7 04 24 4c 7e 00 40 	movl   $0x40007e4c,(%esp)
40002592:	e8 e1 02 00 00       	call   40002878 <cprintf>
	execl("sh", "sh", NULL);
40002597:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
4000259e:	00 
4000259f:	c7 44 24 04 ef 75 00 	movl   $0x400075ef,0x4(%esp)
400025a6:	40 
400025a7:	c7 04 24 ef 75 00 40 	movl   $0x400075ef,(%esp)
400025ae:	e8 3d 40 00 00       	call   400065f0 <execl>
	panic("execl failed: %s", strerror(errno));
400025b3:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400025b8:	8b 00                	mov    (%eax),%eax
400025ba:	89 04 24             	mov    %eax,(%esp)
400025bd:	e8 42 49 00 00       	call   40006f04 <strerror>
400025c2:	89 44 24 0c          	mov    %eax,0xc(%esp)
400025c6:	c7 44 24 08 7c 7e 00 	movl   $0x40007e7c,0x8(%esp)
400025cd:	40 
400025ce:	c7 44 24 04 bc 01 00 	movl   $0x1bc,0x4(%esp)
400025d5:	00 
400025d6:	c7 04 24 7f 75 00 40 	movl   $0x4000757f,(%esp)
400025dd:	e8 02 00 00 00       	call   400025e4 <debug_panic>
400025e2:	66 90                	xchg   %ax,%ax

400025e4 <debug_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: <message>", then causes a breakpoint exception.
 */
void
debug_panic(const char *file, int line, const char *fmt,...)
{
400025e4:	55                   	push   %ebp
400025e5:	89 e5                	mov    %esp,%ebp
400025e7:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	va_start(ap, fmt);
400025ea:	8d 45 10             	lea    0x10(%ebp),%eax
400025ed:	83 c0 04             	add    $0x4,%eax
400025f0:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Print the panic message
	if (argv0)
400025f3:	a1 84 dc 00 40       	mov    0x4000dc84,%eax
400025f8:	85 c0                	test   %eax,%eax
400025fa:	74 15                	je     40002611 <debug_panic+0x2d>
		cprintf("%s: ", argv0);
400025fc:	a1 84 dc 00 40       	mov    0x4000dc84,%eax
40002601:	89 44 24 04          	mov    %eax,0x4(%esp)
40002605:	c7 04 24 90 7e 00 40 	movl   $0x40007e90,(%esp)
4000260c:	e8 67 02 00 00       	call   40002878 <cprintf>
	cprintf("user panic at %s:%d: ", file, line);
40002611:	8b 45 0c             	mov    0xc(%ebp),%eax
40002614:	89 44 24 08          	mov    %eax,0x8(%esp)
40002618:	8b 45 08             	mov    0x8(%ebp),%eax
4000261b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000261f:	c7 04 24 95 7e 00 40 	movl   $0x40007e95,(%esp)
40002626:	e8 4d 02 00 00       	call   40002878 <cprintf>
	vcprintf(fmt, ap);
4000262b:	8b 45 10             	mov    0x10(%ebp),%eax
4000262e:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002631:	89 54 24 04          	mov    %edx,0x4(%esp)
40002635:	89 04 24             	mov    %eax,(%esp)
40002638:	e8 d3 01 00 00       	call   40002810 <vcprintf>
	cprintf("\n");
4000263d:	c7 04 24 ab 7e 00 40 	movl   $0x40007eab,(%esp)
40002644:	e8 2f 02 00 00       	call   40002878 <cprintf>

	abort();
40002649:	e8 e2 2a 00 00       	call   40005130 <abort>

4000264e <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
4000264e:	55                   	push   %ebp
4000264f:	89 e5                	mov    %esp,%ebp
40002651:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
40002654:	8d 45 10             	lea    0x10(%ebp),%eax
40002657:	83 c0 04             	add    $0x4,%eax
4000265a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("user warning at %s:%d: ", file, line);
4000265d:	8b 45 0c             	mov    0xc(%ebp),%eax
40002660:	89 44 24 08          	mov    %eax,0x8(%esp)
40002664:	8b 45 08             	mov    0x8(%ebp),%eax
40002667:	89 44 24 04          	mov    %eax,0x4(%esp)
4000266b:	c7 04 24 ad 7e 00 40 	movl   $0x40007ead,(%esp)
40002672:	e8 01 02 00 00       	call   40002878 <cprintf>
	vcprintf(fmt, ap);
40002677:	8b 45 10             	mov    0x10(%ebp),%eax
4000267a:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000267d:	89 54 24 04          	mov    %edx,0x4(%esp)
40002681:	89 04 24             	mov    %eax,(%esp)
40002684:	e8 87 01 00 00       	call   40002810 <vcprintf>
	cprintf("\n");
40002689:	c7 04 24 ab 7e 00 40 	movl   $0x40007eab,(%esp)
40002690:	e8 e3 01 00 00       	call   40002878 <cprintf>
	va_end(ap);
}
40002695:	c9                   	leave  
40002696:	c3                   	ret    

40002697 <debug_dump>:

// Dump a block of memory as 32-bit words and ASCII bytes
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
40002697:	55                   	push   %ebp
40002698:	89 e5                	mov    %esp,%ebp
4000269a:	56                   	push   %esi
4000269b:	53                   	push   %ebx
4000269c:	81 ec a0 00 00 00    	sub    $0xa0,%esp
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
400026a2:	8b 55 14             	mov    0x14(%ebp),%edx
400026a5:	8b 45 10             	mov    0x10(%ebp),%eax
400026a8:	01 d0                	add    %edx,%eax
400026aa:	89 44 24 10          	mov    %eax,0x10(%esp)
400026ae:	8b 45 10             	mov    0x10(%ebp),%eax
400026b1:	89 44 24 0c          	mov    %eax,0xc(%esp)
400026b5:	8b 45 0c             	mov    0xc(%ebp),%eax
400026b8:	89 44 24 08          	mov    %eax,0x8(%esp)
400026bc:	8b 45 08             	mov    0x8(%ebp),%eax
400026bf:	89 44 24 04          	mov    %eax,0x4(%esp)
400026c3:	c7 04 24 c8 7e 00 40 	movl   $0x40007ec8,(%esp)
400026ca:	e8 a9 01 00 00       	call   40002878 <cprintf>
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
400026cf:	8b 45 14             	mov    0x14(%ebp),%eax
400026d2:	83 c0 0f             	add    $0xf,%eax
400026d5:	83 e0 f0             	and    $0xfffffff0,%eax
400026d8:	89 45 14             	mov    %eax,0x14(%ebp)
400026db:	e9 bb 00 00 00       	jmp    4000279b <debug_dump+0x104>
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
400026e0:	8b 45 10             	mov    0x10(%ebp),%eax
400026e3:	89 45 f0             	mov    %eax,-0x10(%ebp)
		for (i = 0; i < 16; i++)
400026e6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
400026ed:	eb 4d                	jmp    4000273c <debug_dump+0xa5>
			buf[i] = isprint(c[i]) ? c[i] : '.';
400026ef:	8b 55 f4             	mov    -0xc(%ebp),%edx
400026f2:	8b 45 f0             	mov    -0x10(%ebp),%eax
400026f5:	01 d0                	add    %edx,%eax
400026f7:	0f b6 00             	movzbl (%eax),%eax
400026fa:	0f b6 c0             	movzbl %al,%eax
400026fd:	89 45 e8             	mov    %eax,-0x18(%ebp)
static gcc_inline int isalnum(int c)	{ return isalpha(c) || isdigit(c); }
static gcc_inline int iscntrl(int c)	{ return c < ' '; }
static gcc_inline int isblank(int c)	{ return c == ' ' || c == '\t'; }
static gcc_inline int isspace(int c)	{ return c == ' '
						|| (c >= '\t' && c <= '\r'); }
static gcc_inline int isprint(int c)	{ return c >= ' ' && c <= '~'; }
40002700:	83 7d e8 1f          	cmpl   $0x1f,-0x18(%ebp)
40002704:	7e 0d                	jle    40002713 <debug_dump+0x7c>
40002706:	83 7d e8 7e          	cmpl   $0x7e,-0x18(%ebp)
4000270a:	7f 07                	jg     40002713 <debug_dump+0x7c>
4000270c:	b8 01 00 00 00       	mov    $0x1,%eax
40002711:	eb 05                	jmp    40002718 <debug_dump+0x81>
40002713:	b8 00 00 00 00       	mov    $0x0,%eax
40002718:	85 c0                	test   %eax,%eax
4000271a:	74 0d                	je     40002729 <debug_dump+0x92>
4000271c:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000271f:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002722:	01 d0                	add    %edx,%eax
40002724:	0f b6 00             	movzbl (%eax),%eax
40002727:	eb 05                	jmp    4000272e <debug_dump+0x97>
40002729:	b8 2e 00 00 00       	mov    $0x2e,%eax
4000272e:	8d 4d 84             	lea    -0x7c(%ebp),%ecx
40002731:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002734:	01 ca                	add    %ecx,%edx
40002736:	88 02                	mov    %al,(%edx)
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
		for (i = 0; i < 16; i++)
40002738:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
4000273c:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
40002740:	7e ad                	jle    400026ef <debug_dump+0x58>
			buf[i] = isprint(c[i]) ? c[i] : '.';
		buf[16] = 0;
40002742:	c6 45 94 00          	movb   $0x0,-0x6c(%ebp)

		// Hex words
		const uint32_t *v = ptr;
40002746:	8b 45 10             	mov    0x10(%ebp),%eax
40002749:	89 45 ec             	mov    %eax,-0x14(%ebp)

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
			ptr, v[0], v[1], v[2], v[3], buf);
4000274c:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000274f:	83 c0 0c             	add    $0xc,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40002752:	8b 18                	mov    (%eax),%ebx
			ptr, v[0], v[1], v[2], v[3], buf);
40002754:	8b 45 ec             	mov    -0x14(%ebp),%eax
40002757:	83 c0 08             	add    $0x8,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
4000275a:	8b 08                	mov    (%eax),%ecx
			ptr, v[0], v[1], v[2], v[3], buf);
4000275c:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000275f:	83 c0 04             	add    $0x4,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40002762:	8b 10                	mov    (%eax),%edx
40002764:	8b 45 ec             	mov    -0x14(%ebp),%eax
40002767:	8b 00                	mov    (%eax),%eax
			ptr, v[0], v[1], v[2], v[3], buf);
40002769:	8d 75 84             	lea    -0x7c(%ebp),%esi
4000276c:	89 74 24 18          	mov    %esi,0x18(%esp)

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40002770:	89 5c 24 14          	mov    %ebx,0x14(%esp)
40002774:	89 4c 24 10          	mov    %ecx,0x10(%esp)
40002778:	89 54 24 0c          	mov    %edx,0xc(%esp)
4000277c:	89 44 24 08          	mov    %eax,0x8(%esp)
40002780:	8b 45 10             	mov    0x10(%ebp),%eax
40002783:	89 44 24 04          	mov    %eax,0x4(%esp)
40002787:	c7 04 24 f1 7e 00 40 	movl   $0x40007ef1,(%esp)
4000278e:	e8 e5 00 00 00       	call   40002878 <cprintf>
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
40002793:	83 6d 14 10          	subl   $0x10,0x14(%ebp)
40002797:	83 45 10 10          	addl   $0x10,0x10(%ebp)
4000279b:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
4000279f:	0f 8f 3b ff ff ff    	jg     400026e0 <debug_dump+0x49>

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
			ptr, v[0], v[1], v[2], v[3], buf);
	}
}
400027a5:	81 c4 a0 00 00 00    	add    $0xa0,%esp
400027ab:	5b                   	pop    %ebx
400027ac:	5e                   	pop    %esi
400027ad:	5d                   	pop    %ebp
400027ae:	c3                   	ret    
400027af:	90                   	nop

400027b0 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
400027b0:	55                   	push   %ebp
400027b1:	89 e5                	mov    %esp,%ebp
400027b3:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
400027b6:	8b 45 0c             	mov    0xc(%ebp),%eax
400027b9:	8b 00                	mov    (%eax),%eax
400027bb:	8b 55 08             	mov    0x8(%ebp),%edx
400027be:	89 d1                	mov    %edx,%ecx
400027c0:	8b 55 0c             	mov    0xc(%ebp),%edx
400027c3:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
400027c7:	8d 50 01             	lea    0x1(%eax),%edx
400027ca:	8b 45 0c             	mov    0xc(%ebp),%eax
400027cd:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
400027cf:	8b 45 0c             	mov    0xc(%ebp),%eax
400027d2:	8b 00                	mov    (%eax),%eax
400027d4:	3d ff 00 00 00       	cmp    $0xff,%eax
400027d9:	75 24                	jne    400027ff <putch+0x4f>
		b->buf[b->idx] = 0;
400027db:	8b 45 0c             	mov    0xc(%ebp),%eax
400027de:	8b 00                	mov    (%eax),%eax
400027e0:	8b 55 0c             	mov    0xc(%ebp),%edx
400027e3:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
400027e8:	8b 45 0c             	mov    0xc(%ebp),%eax
400027eb:	83 c0 08             	add    $0x8,%eax
400027ee:	89 04 24             	mov    %eax,(%esp)
400027f1:	e8 9a 48 00 00       	call   40007090 <cputs>
		b->idx = 0;
400027f6:	8b 45 0c             	mov    0xc(%ebp),%eax
400027f9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
400027ff:	8b 45 0c             	mov    0xc(%ebp),%eax
40002802:	8b 40 04             	mov    0x4(%eax),%eax
40002805:	8d 50 01             	lea    0x1(%eax),%edx
40002808:	8b 45 0c             	mov    0xc(%ebp),%eax
4000280b:	89 50 04             	mov    %edx,0x4(%eax)
}
4000280e:	c9                   	leave  
4000280f:	c3                   	ret    

40002810 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
40002810:	55                   	push   %ebp
40002811:	89 e5                	mov    %esp,%ebp
40002813:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
40002819:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
40002820:	00 00 00 
	b.cnt = 0;
40002823:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
4000282a:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
4000282d:	8b 45 0c             	mov    0xc(%ebp),%eax
40002830:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002834:	8b 45 08             	mov    0x8(%ebp),%eax
40002837:	89 44 24 08          	mov    %eax,0x8(%esp)
4000283b:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
40002841:	89 44 24 04          	mov    %eax,0x4(%esp)
40002845:	c7 04 24 b0 27 00 40 	movl   $0x400027b0,(%esp)
4000284c:	e8 70 03 00 00       	call   40002bc1 <vprintfmt>

	b.buf[b.idx] = 0;
40002851:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
40002857:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
4000285e:	00 
	cputs(b.buf);
4000285f:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
40002865:	83 c0 08             	add    $0x8,%eax
40002868:	89 04 24             	mov    %eax,(%esp)
4000286b:	e8 20 48 00 00       	call   40007090 <cputs>

	return b.cnt;
40002870:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
40002876:	c9                   	leave  
40002877:	c3                   	ret    

40002878 <cprintf>:

int
cprintf(const char *fmt, ...)
{
40002878:	55                   	push   %ebp
40002879:	89 e5                	mov    %esp,%ebp
4000287b:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
4000287e:	8d 45 0c             	lea    0xc(%ebp),%eax
40002881:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
40002884:	8b 45 08             	mov    0x8(%ebp),%eax
40002887:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000288a:	89 54 24 04          	mov    %edx,0x4(%esp)
4000288e:	89 04 24             	mov    %eax,(%esp)
40002891:	e8 7a ff ff ff       	call   40002810 <vcprintf>
40002896:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
40002899:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
4000289c:	c9                   	leave  
4000289d:	c3                   	ret    
4000289e:	66 90                	xchg   %ax,%ax

400028a0 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
400028a0:	55                   	push   %ebp
400028a1:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
400028a3:	8b 45 08             	mov    0x8(%ebp),%eax
400028a6:	8b 40 18             	mov    0x18(%eax),%eax
400028a9:	83 e0 02             	and    $0x2,%eax
400028ac:	85 c0                	test   %eax,%eax
400028ae:	74 1c                	je     400028cc <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
400028b0:	8b 45 0c             	mov    0xc(%ebp),%eax
400028b3:	8b 00                	mov    (%eax),%eax
400028b5:	8d 50 08             	lea    0x8(%eax),%edx
400028b8:	8b 45 0c             	mov    0xc(%ebp),%eax
400028bb:	89 10                	mov    %edx,(%eax)
400028bd:	8b 45 0c             	mov    0xc(%ebp),%eax
400028c0:	8b 00                	mov    (%eax),%eax
400028c2:	83 e8 08             	sub    $0x8,%eax
400028c5:	8b 50 04             	mov    0x4(%eax),%edx
400028c8:	8b 00                	mov    (%eax),%eax
400028ca:	eb 47                	jmp    40002913 <getuint+0x73>
	else if (st->flags & F_L)
400028cc:	8b 45 08             	mov    0x8(%ebp),%eax
400028cf:	8b 40 18             	mov    0x18(%eax),%eax
400028d2:	83 e0 01             	and    $0x1,%eax
400028d5:	85 c0                	test   %eax,%eax
400028d7:	74 1e                	je     400028f7 <getuint+0x57>
		return va_arg(*ap, unsigned long);
400028d9:	8b 45 0c             	mov    0xc(%ebp),%eax
400028dc:	8b 00                	mov    (%eax),%eax
400028de:	8d 50 04             	lea    0x4(%eax),%edx
400028e1:	8b 45 0c             	mov    0xc(%ebp),%eax
400028e4:	89 10                	mov    %edx,(%eax)
400028e6:	8b 45 0c             	mov    0xc(%ebp),%eax
400028e9:	8b 00                	mov    (%eax),%eax
400028eb:	83 e8 04             	sub    $0x4,%eax
400028ee:	8b 00                	mov    (%eax),%eax
400028f0:	ba 00 00 00 00       	mov    $0x0,%edx
400028f5:	eb 1c                	jmp    40002913 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
400028f7:	8b 45 0c             	mov    0xc(%ebp),%eax
400028fa:	8b 00                	mov    (%eax),%eax
400028fc:	8d 50 04             	lea    0x4(%eax),%edx
400028ff:	8b 45 0c             	mov    0xc(%ebp),%eax
40002902:	89 10                	mov    %edx,(%eax)
40002904:	8b 45 0c             	mov    0xc(%ebp),%eax
40002907:	8b 00                	mov    (%eax),%eax
40002909:	83 e8 04             	sub    $0x4,%eax
4000290c:	8b 00                	mov    (%eax),%eax
4000290e:	ba 00 00 00 00       	mov    $0x0,%edx
}
40002913:	5d                   	pop    %ebp
40002914:	c3                   	ret    

40002915 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
40002915:	55                   	push   %ebp
40002916:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
40002918:	8b 45 08             	mov    0x8(%ebp),%eax
4000291b:	8b 40 18             	mov    0x18(%eax),%eax
4000291e:	83 e0 02             	and    $0x2,%eax
40002921:	85 c0                	test   %eax,%eax
40002923:	74 1c                	je     40002941 <getint+0x2c>
		return va_arg(*ap, long long);
40002925:	8b 45 0c             	mov    0xc(%ebp),%eax
40002928:	8b 00                	mov    (%eax),%eax
4000292a:	8d 50 08             	lea    0x8(%eax),%edx
4000292d:	8b 45 0c             	mov    0xc(%ebp),%eax
40002930:	89 10                	mov    %edx,(%eax)
40002932:	8b 45 0c             	mov    0xc(%ebp),%eax
40002935:	8b 00                	mov    (%eax),%eax
40002937:	83 e8 08             	sub    $0x8,%eax
4000293a:	8b 50 04             	mov    0x4(%eax),%edx
4000293d:	8b 00                	mov    (%eax),%eax
4000293f:	eb 47                	jmp    40002988 <getint+0x73>
	else if (st->flags & F_L)
40002941:	8b 45 08             	mov    0x8(%ebp),%eax
40002944:	8b 40 18             	mov    0x18(%eax),%eax
40002947:	83 e0 01             	and    $0x1,%eax
4000294a:	85 c0                	test   %eax,%eax
4000294c:	74 1e                	je     4000296c <getint+0x57>
		return va_arg(*ap, long);
4000294e:	8b 45 0c             	mov    0xc(%ebp),%eax
40002951:	8b 00                	mov    (%eax),%eax
40002953:	8d 50 04             	lea    0x4(%eax),%edx
40002956:	8b 45 0c             	mov    0xc(%ebp),%eax
40002959:	89 10                	mov    %edx,(%eax)
4000295b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000295e:	8b 00                	mov    (%eax),%eax
40002960:	83 e8 04             	sub    $0x4,%eax
40002963:	8b 00                	mov    (%eax),%eax
40002965:	89 c2                	mov    %eax,%edx
40002967:	c1 fa 1f             	sar    $0x1f,%edx
4000296a:	eb 1c                	jmp    40002988 <getint+0x73>
	else
		return va_arg(*ap, int);
4000296c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000296f:	8b 00                	mov    (%eax),%eax
40002971:	8d 50 04             	lea    0x4(%eax),%edx
40002974:	8b 45 0c             	mov    0xc(%ebp),%eax
40002977:	89 10                	mov    %edx,(%eax)
40002979:	8b 45 0c             	mov    0xc(%ebp),%eax
4000297c:	8b 00                	mov    (%eax),%eax
4000297e:	83 e8 04             	sub    $0x4,%eax
40002981:	8b 00                	mov    (%eax),%eax
40002983:	89 c2                	mov    %eax,%edx
40002985:	c1 fa 1f             	sar    $0x1f,%edx
}
40002988:	5d                   	pop    %ebp
40002989:	c3                   	ret    

4000298a <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
4000298a:	55                   	push   %ebp
4000298b:	89 e5                	mov    %esp,%ebp
4000298d:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
40002990:	eb 1a                	jmp    400029ac <putpad+0x22>
		st->putch(st->padc, st->putdat);
40002992:	8b 45 08             	mov    0x8(%ebp),%eax
40002995:	8b 00                	mov    (%eax),%eax
40002997:	8b 55 08             	mov    0x8(%ebp),%edx
4000299a:	8b 4a 04             	mov    0x4(%edx),%ecx
4000299d:	8b 55 08             	mov    0x8(%ebp),%edx
400029a0:	8b 52 08             	mov    0x8(%edx),%edx
400029a3:	89 4c 24 04          	mov    %ecx,0x4(%esp)
400029a7:	89 14 24             	mov    %edx,(%esp)
400029aa:	ff d0                	call   *%eax

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
400029ac:	8b 45 08             	mov    0x8(%ebp),%eax
400029af:	8b 40 0c             	mov    0xc(%eax),%eax
400029b2:	8d 50 ff             	lea    -0x1(%eax),%edx
400029b5:	8b 45 08             	mov    0x8(%ebp),%eax
400029b8:	89 50 0c             	mov    %edx,0xc(%eax)
400029bb:	8b 45 08             	mov    0x8(%ebp),%eax
400029be:	8b 40 0c             	mov    0xc(%eax),%eax
400029c1:	85 c0                	test   %eax,%eax
400029c3:	79 cd                	jns    40002992 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
400029c5:	c9                   	leave  
400029c6:	c3                   	ret    

400029c7 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
400029c7:	55                   	push   %ebp
400029c8:	89 e5                	mov    %esp,%ebp
400029ca:	53                   	push   %ebx
400029cb:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
400029ce:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400029d2:	79 18                	jns    400029ec <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
400029d4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400029db:	00 
400029dc:	8b 45 0c             	mov    0xc(%ebp),%eax
400029df:	89 04 24             	mov    %eax,(%esp)
400029e2:	e8 f6 06 00 00       	call   400030dd <strchr>
400029e7:	89 45 f4             	mov    %eax,-0xc(%ebp)
400029ea:	eb 2e                	jmp    40002a1a <putstr+0x53>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
400029ec:	8b 45 10             	mov    0x10(%ebp),%eax
400029ef:	89 44 24 08          	mov    %eax,0x8(%esp)
400029f3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400029fa:	00 
400029fb:	8b 45 0c             	mov    0xc(%ebp),%eax
400029fe:	89 04 24             	mov    %eax,(%esp)
40002a01:	e8 d4 08 00 00       	call   400032da <memchr>
40002a06:	89 45 f4             	mov    %eax,-0xc(%ebp)
40002a09:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40002a0d:	75 0b                	jne    40002a1a <putstr+0x53>
		lim = str + maxlen;
40002a0f:	8b 55 10             	mov    0x10(%ebp),%edx
40002a12:	8b 45 0c             	mov    0xc(%ebp),%eax
40002a15:	01 d0                	add    %edx,%eax
40002a17:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
40002a1a:	8b 45 08             	mov    0x8(%ebp),%eax
40002a1d:	8b 40 0c             	mov    0xc(%eax),%eax
40002a20:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40002a23:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002a26:	89 cb                	mov    %ecx,%ebx
40002a28:	29 d3                	sub    %edx,%ebx
40002a2a:	89 da                	mov    %ebx,%edx
40002a2c:	01 c2                	add    %eax,%edx
40002a2e:	8b 45 08             	mov    0x8(%ebp),%eax
40002a31:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
40002a34:	8b 45 08             	mov    0x8(%ebp),%eax
40002a37:	8b 40 18             	mov    0x18(%eax),%eax
40002a3a:	83 e0 10             	and    $0x10,%eax
40002a3d:	85 c0                	test   %eax,%eax
40002a3f:	75 32                	jne    40002a73 <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
40002a41:	8b 45 08             	mov    0x8(%ebp),%eax
40002a44:	89 04 24             	mov    %eax,(%esp)
40002a47:	e8 3e ff ff ff       	call   4000298a <putpad>
	while (str < lim) {
40002a4c:	eb 25                	jmp    40002a73 <putstr+0xac>
		char ch = *str++;
40002a4e:	8b 45 0c             	mov    0xc(%ebp),%eax
40002a51:	0f b6 00             	movzbl (%eax),%eax
40002a54:	88 45 f3             	mov    %al,-0xd(%ebp)
40002a57:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
40002a5b:	8b 45 08             	mov    0x8(%ebp),%eax
40002a5e:	8b 00                	mov    (%eax),%eax
40002a60:	8b 55 08             	mov    0x8(%ebp),%edx
40002a63:	8b 4a 04             	mov    0x4(%edx),%ecx
40002a66:	0f be 55 f3          	movsbl -0xd(%ebp),%edx
40002a6a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
40002a6e:	89 14 24             	mov    %edx,(%esp)
40002a71:	ff d0                	call   *%eax
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
40002a73:	8b 45 0c             	mov    0xc(%ebp),%eax
40002a76:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40002a79:	72 d3                	jb     40002a4e <putstr+0x87>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
40002a7b:	8b 45 08             	mov    0x8(%ebp),%eax
40002a7e:	89 04 24             	mov    %eax,(%esp)
40002a81:	e8 04 ff ff ff       	call   4000298a <putpad>
}
40002a86:	83 c4 24             	add    $0x24,%esp
40002a89:	5b                   	pop    %ebx
40002a8a:	5d                   	pop    %ebp
40002a8b:	c3                   	ret    

40002a8c <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
40002a8c:	55                   	push   %ebp
40002a8d:	89 e5                	mov    %esp,%ebp
40002a8f:	53                   	push   %ebx
40002a90:	83 ec 24             	sub    $0x24,%esp
40002a93:	8b 45 10             	mov    0x10(%ebp),%eax
40002a96:	89 45 f0             	mov    %eax,-0x10(%ebp)
40002a99:	8b 45 14             	mov    0x14(%ebp),%eax
40002a9c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
40002a9f:	8b 45 08             	mov    0x8(%ebp),%eax
40002aa2:	8b 40 1c             	mov    0x1c(%eax),%eax
40002aa5:	89 c2                	mov    %eax,%edx
40002aa7:	c1 fa 1f             	sar    $0x1f,%edx
40002aaa:	3b 55 f4             	cmp    -0xc(%ebp),%edx
40002aad:	77 4e                	ja     40002afd <genint+0x71>
40002aaf:	3b 55 f4             	cmp    -0xc(%ebp),%edx
40002ab2:	72 05                	jb     40002ab9 <genint+0x2d>
40002ab4:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40002ab7:	77 44                	ja     40002afd <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
40002ab9:	8b 45 08             	mov    0x8(%ebp),%eax
40002abc:	8b 40 1c             	mov    0x1c(%eax),%eax
40002abf:	89 c2                	mov    %eax,%edx
40002ac1:	c1 fa 1f             	sar    $0x1f,%edx
40002ac4:	89 44 24 08          	mov    %eax,0x8(%esp)
40002ac8:	89 54 24 0c          	mov    %edx,0xc(%esp)
40002acc:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002acf:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002ad2:	89 04 24             	mov    %eax,(%esp)
40002ad5:	89 54 24 04          	mov    %edx,0x4(%esp)
40002ad9:	e8 62 47 00 00       	call   40007240 <__udivdi3>
40002ade:	89 44 24 08          	mov    %eax,0x8(%esp)
40002ae2:	89 54 24 0c          	mov    %edx,0xc(%esp)
40002ae6:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ae9:	89 44 24 04          	mov    %eax,0x4(%esp)
40002aed:	8b 45 08             	mov    0x8(%ebp),%eax
40002af0:	89 04 24             	mov    %eax,(%esp)
40002af3:	e8 94 ff ff ff       	call   40002a8c <genint>
40002af8:	89 45 0c             	mov    %eax,0xc(%ebp)
40002afb:	eb 1b                	jmp    40002b18 <genint+0x8c>
	else if (st->signc >= 0)
40002afd:	8b 45 08             	mov    0x8(%ebp),%eax
40002b00:	8b 40 14             	mov    0x14(%eax),%eax
40002b03:	85 c0                	test   %eax,%eax
40002b05:	78 11                	js     40002b18 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
40002b07:	8b 45 08             	mov    0x8(%ebp),%eax
40002b0a:	8b 40 14             	mov    0x14(%eax),%eax
40002b0d:	89 c2                	mov    %eax,%edx
40002b0f:	8b 45 0c             	mov    0xc(%ebp),%eax
40002b12:	88 10                	mov    %dl,(%eax)
40002b14:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
40002b18:	8b 45 08             	mov    0x8(%ebp),%eax
40002b1b:	8b 40 1c             	mov    0x1c(%eax),%eax
40002b1e:	89 c1                	mov    %eax,%ecx
40002b20:	89 c3                	mov    %eax,%ebx
40002b22:	c1 fb 1f             	sar    $0x1f,%ebx
40002b25:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002b28:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002b2b:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40002b2f:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
40002b33:	89 04 24             	mov    %eax,(%esp)
40002b36:	89 54 24 04          	mov    %edx,0x4(%esp)
40002b3a:	e8 51 48 00 00       	call   40007390 <__umoddi3>
40002b3f:	05 10 7f 00 40       	add    $0x40007f10,%eax
40002b44:	0f b6 10             	movzbl (%eax),%edx
40002b47:	8b 45 0c             	mov    0xc(%ebp),%eax
40002b4a:	88 10                	mov    %dl,(%eax)
40002b4c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
40002b50:	8b 45 0c             	mov    0xc(%ebp),%eax
}
40002b53:	83 c4 24             	add    $0x24,%esp
40002b56:	5b                   	pop    %ebx
40002b57:	5d                   	pop    %ebp
40002b58:	c3                   	ret    

40002b59 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
40002b59:	55                   	push   %ebp
40002b5a:	89 e5                	mov    %esp,%ebp
40002b5c:	83 ec 58             	sub    $0x58,%esp
40002b5f:	8b 45 0c             	mov    0xc(%ebp),%eax
40002b62:	89 45 c0             	mov    %eax,-0x40(%ebp)
40002b65:	8b 45 10             	mov    0x10(%ebp),%eax
40002b68:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
40002b6b:	8d 45 d6             	lea    -0x2a(%ebp),%eax
40002b6e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
40002b71:	8b 45 08             	mov    0x8(%ebp),%eax
40002b74:	8b 55 14             	mov    0x14(%ebp),%edx
40002b77:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
40002b7a:	8b 45 c0             	mov    -0x40(%ebp),%eax
40002b7d:	8b 55 c4             	mov    -0x3c(%ebp),%edx
40002b80:	89 44 24 08          	mov    %eax,0x8(%esp)
40002b84:	89 54 24 0c          	mov    %edx,0xc(%esp)
40002b88:	8b 45 f4             	mov    -0xc(%ebp),%eax
40002b8b:	89 44 24 04          	mov    %eax,0x4(%esp)
40002b8f:	8b 45 08             	mov    0x8(%ebp),%eax
40002b92:	89 04 24             	mov    %eax,(%esp)
40002b95:	e8 f2 fe ff ff       	call   40002a8c <genint>
40002b9a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
40002b9d:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002ba0:	8d 45 d6             	lea    -0x2a(%ebp),%eax
40002ba3:	89 d1                	mov    %edx,%ecx
40002ba5:	29 c1                	sub    %eax,%ecx
40002ba7:	89 c8                	mov    %ecx,%eax
40002ba9:	89 44 24 08          	mov    %eax,0x8(%esp)
40002bad:	8d 45 d6             	lea    -0x2a(%ebp),%eax
40002bb0:	89 44 24 04          	mov    %eax,0x4(%esp)
40002bb4:	8b 45 08             	mov    0x8(%ebp),%eax
40002bb7:	89 04 24             	mov    %eax,(%esp)
40002bba:	e8 08 fe ff ff       	call   400029c7 <putstr>
}
40002bbf:	c9                   	leave  
40002bc0:	c3                   	ret    

40002bc1 <vprintfmt>:


// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
40002bc1:	55                   	push   %ebp
40002bc2:	89 e5                	mov    %esp,%ebp
40002bc4:	53                   	push   %ebx
40002bc5:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
40002bc8:	8d 55 cc             	lea    -0x34(%ebp),%edx
40002bcb:	b9 00 00 00 00       	mov    $0x0,%ecx
40002bd0:	b8 20 00 00 00       	mov    $0x20,%eax
40002bd5:	89 c3                	mov    %eax,%ebx
40002bd7:	83 e3 fc             	and    $0xfffffffc,%ebx
40002bda:	b8 00 00 00 00       	mov    $0x0,%eax
40002bdf:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
40002be2:	83 c0 04             	add    $0x4,%eax
40002be5:	39 d8                	cmp    %ebx,%eax
40002be7:	72 f6                	jb     40002bdf <vprintfmt+0x1e>
40002be9:	01 c2                	add    %eax,%edx
40002beb:	8b 45 08             	mov    0x8(%ebp),%eax
40002bee:	89 45 cc             	mov    %eax,-0x34(%ebp)
40002bf1:	8b 45 0c             	mov    0xc(%ebp),%eax
40002bf4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40002bf7:	eb 17                	jmp    40002c10 <vprintfmt+0x4f>
			if (ch == '\0')
40002bf9:	85 db                	test   %ebx,%ebx
40002bfb:	0f 84 50 03 00 00    	je     40002f51 <vprintfmt+0x390>
				return;
			putch(ch, putdat);
40002c01:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c04:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c08:	89 1c 24             	mov    %ebx,(%esp)
40002c0b:	8b 45 08             	mov    0x8(%ebp),%eax
40002c0e:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40002c10:	8b 45 10             	mov    0x10(%ebp),%eax
40002c13:	0f b6 00             	movzbl (%eax),%eax
40002c16:	0f b6 d8             	movzbl %al,%ebx
40002c19:	83 fb 25             	cmp    $0x25,%ebx
40002c1c:	0f 95 c0             	setne  %al
40002c1f:	83 45 10 01          	addl   $0x1,0x10(%ebp)
40002c23:	84 c0                	test   %al,%al
40002c25:	75 d2                	jne    40002bf9 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
40002c27:	c7 45 d4 20 00 00 00 	movl   $0x20,-0x2c(%ebp)
		st.width = -1;
40002c2e:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.prec = -1;
40002c35:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.signc = -1;
40002c3c:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		st.flags = 0;
40002c43:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		st.base = 10;
40002c4a:	c7 45 e8 0a 00 00 00 	movl   $0xa,-0x18(%ebp)
40002c51:	eb 04                	jmp    40002c57 <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
40002c53:	90                   	nop
40002c54:	eb 01                	jmp    40002c57 <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
40002c56:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
40002c57:	8b 45 10             	mov    0x10(%ebp),%eax
40002c5a:	0f b6 00             	movzbl (%eax),%eax
40002c5d:	0f b6 d8             	movzbl %al,%ebx
40002c60:	89 d8                	mov    %ebx,%eax
40002c62:	83 45 10 01          	addl   $0x1,0x10(%ebp)
40002c66:	83 e8 20             	sub    $0x20,%eax
40002c69:	83 f8 58             	cmp    $0x58,%eax
40002c6c:	0f 87 ae 02 00 00    	ja     40002f20 <vprintfmt+0x35f>
40002c72:	8b 04 85 28 7f 00 40 	mov    0x40007f28(,%eax,4),%eax
40002c79:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
40002c7b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40002c7e:	83 c8 10             	or     $0x10,%eax
40002c81:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
40002c84:	eb d1                	jmp    40002c57 <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
40002c86:	c7 45 e0 2b 00 00 00 	movl   $0x2b,-0x20(%ebp)
			goto reswitch;
40002c8d:	eb c8                	jmp    40002c57 <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
40002c8f:	8b 45 e0             	mov    -0x20(%ebp),%eax
40002c92:	85 c0                	test   %eax,%eax
40002c94:	79 bd                	jns    40002c53 <vprintfmt+0x92>
				st.signc = ' ';
40002c96:	c7 45 e0 20 00 00 00 	movl   $0x20,-0x20(%ebp)
			goto reswitch;
40002c9d:	eb b4                	jmp    40002c53 <vprintfmt+0x92>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
40002c9f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40002ca2:	83 e0 08             	and    $0x8,%eax
40002ca5:	85 c0                	test   %eax,%eax
40002ca7:	75 07                	jne    40002cb0 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
40002ca9:	c7 45 d4 30 00 00 00 	movl   $0x30,-0x2c(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
40002cb0:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
				st.prec = st.prec * 10 + ch - '0';
40002cb7:	8b 55 dc             	mov    -0x24(%ebp),%edx
40002cba:	89 d0                	mov    %edx,%eax
40002cbc:	c1 e0 02             	shl    $0x2,%eax
40002cbf:	01 d0                	add    %edx,%eax
40002cc1:	01 c0                	add    %eax,%eax
40002cc3:	01 d8                	add    %ebx,%eax
40002cc5:	83 e8 30             	sub    $0x30,%eax
40002cc8:	89 45 dc             	mov    %eax,-0x24(%ebp)
				ch = *fmt;
40002ccb:	8b 45 10             	mov    0x10(%ebp),%eax
40002cce:	0f b6 00             	movzbl (%eax),%eax
40002cd1:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
40002cd4:	83 fb 2f             	cmp    $0x2f,%ebx
40002cd7:	7e 21                	jle    40002cfa <vprintfmt+0x139>
40002cd9:	83 fb 39             	cmp    $0x39,%ebx
40002cdc:	7f 1c                	jg     40002cfa <vprintfmt+0x139>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
40002cde:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
40002ce2:	eb d3                	jmp    40002cb7 <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
40002ce4:	8b 45 14             	mov    0x14(%ebp),%eax
40002ce7:	83 c0 04             	add    $0x4,%eax
40002cea:	89 45 14             	mov    %eax,0x14(%ebp)
40002ced:	8b 45 14             	mov    0x14(%ebp),%eax
40002cf0:	83 e8 04             	sub    $0x4,%eax
40002cf3:	8b 00                	mov    (%eax),%eax
40002cf5:	89 45 dc             	mov    %eax,-0x24(%ebp)
40002cf8:	eb 01                	jmp    40002cfb <vprintfmt+0x13a>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
40002cfa:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
40002cfb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40002cfe:	83 e0 08             	and    $0x8,%eax
40002d01:	85 c0                	test   %eax,%eax
40002d03:	0f 85 4d ff ff ff    	jne    40002c56 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
40002d09:	8b 45 dc             	mov    -0x24(%ebp),%eax
40002d0c:	89 45 d8             	mov    %eax,-0x28(%ebp)
				st.prec = -1;
40002d0f:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
			}
			goto reswitch;
40002d16:	e9 3b ff ff ff       	jmp    40002c56 <vprintfmt+0x95>

		case '.':
			st.flags |= F_DOT;
40002d1b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40002d1e:	83 c8 08             	or     $0x8,%eax
40002d21:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
40002d24:	e9 2e ff ff ff       	jmp    40002c57 <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
40002d29:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40002d2c:	83 c8 04             	or     $0x4,%eax
40002d2f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
40002d32:	e9 20 ff ff ff       	jmp    40002c57 <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
40002d37:	8b 55 e4             	mov    -0x1c(%ebp),%edx
40002d3a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40002d3d:	83 e0 01             	and    $0x1,%eax
40002d40:	85 c0                	test   %eax,%eax
40002d42:	74 07                	je     40002d4b <vprintfmt+0x18a>
40002d44:	b8 02 00 00 00       	mov    $0x2,%eax
40002d49:	eb 05                	jmp    40002d50 <vprintfmt+0x18f>
40002d4b:	b8 01 00 00 00       	mov    $0x1,%eax
40002d50:	09 d0                	or     %edx,%eax
40002d52:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
40002d55:	e9 fd fe ff ff       	jmp    40002c57 <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
40002d5a:	8b 45 14             	mov    0x14(%ebp),%eax
40002d5d:	83 c0 04             	add    $0x4,%eax
40002d60:	89 45 14             	mov    %eax,0x14(%ebp)
40002d63:	8b 45 14             	mov    0x14(%ebp),%eax
40002d66:	83 e8 04             	sub    $0x4,%eax
40002d69:	8b 00                	mov    (%eax),%eax
40002d6b:	8b 55 0c             	mov    0xc(%ebp),%edx
40002d6e:	89 54 24 04          	mov    %edx,0x4(%esp)
40002d72:	89 04 24             	mov    %eax,(%esp)
40002d75:	8b 45 08             	mov    0x8(%ebp),%eax
40002d78:	ff d0                	call   *%eax
			break;
40002d7a:	e9 cc 01 00 00       	jmp    40002f4b <vprintfmt+0x38a>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
40002d7f:	8b 45 14             	mov    0x14(%ebp),%eax
40002d82:	83 c0 04             	add    $0x4,%eax
40002d85:	89 45 14             	mov    %eax,0x14(%ebp)
40002d88:	8b 45 14             	mov    0x14(%ebp),%eax
40002d8b:	83 e8 04             	sub    $0x4,%eax
40002d8e:	8b 00                	mov    (%eax),%eax
40002d90:	89 45 ec             	mov    %eax,-0x14(%ebp)
40002d93:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
40002d97:	75 07                	jne    40002da0 <vprintfmt+0x1df>
				s = "(null)";
40002d99:	c7 45 ec 21 7f 00 40 	movl   $0x40007f21,-0x14(%ebp)
			putstr(&st, s, st.prec);
40002da0:	8b 45 dc             	mov    -0x24(%ebp),%eax
40002da3:	89 44 24 08          	mov    %eax,0x8(%esp)
40002da7:	8b 45 ec             	mov    -0x14(%ebp),%eax
40002daa:	89 44 24 04          	mov    %eax,0x4(%esp)
40002dae:	8d 45 cc             	lea    -0x34(%ebp),%eax
40002db1:	89 04 24             	mov    %eax,(%esp)
40002db4:	e8 0e fc ff ff       	call   400029c7 <putstr>
			break;
40002db9:	e9 8d 01 00 00       	jmp    40002f4b <vprintfmt+0x38a>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
40002dbe:	8d 45 14             	lea    0x14(%ebp),%eax
40002dc1:	89 44 24 04          	mov    %eax,0x4(%esp)
40002dc5:	8d 45 cc             	lea    -0x34(%ebp),%eax
40002dc8:	89 04 24             	mov    %eax,(%esp)
40002dcb:	e8 45 fb ff ff       	call   40002915 <getint>
40002dd0:	89 45 f0             	mov    %eax,-0x10(%ebp)
40002dd3:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((intmax_t) num < 0) {
40002dd6:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002dd9:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002ddc:	85 d2                	test   %edx,%edx
40002dde:	79 1a                	jns    40002dfa <vprintfmt+0x239>
				num = -(intmax_t) num;
40002de0:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002de3:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002de6:	f7 d8                	neg    %eax
40002de8:	83 d2 00             	adc    $0x0,%edx
40002deb:	f7 da                	neg    %edx
40002ded:	89 45 f0             	mov    %eax,-0x10(%ebp)
40002df0:	89 55 f4             	mov    %edx,-0xc(%ebp)
				st.signc = '-';
40002df3:	c7 45 e0 2d 00 00 00 	movl   $0x2d,-0x20(%ebp)
			}
			putint(&st, num, 10);
40002dfa:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
40002e01:	00 
40002e02:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002e05:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002e08:	89 44 24 04          	mov    %eax,0x4(%esp)
40002e0c:	89 54 24 08          	mov    %edx,0x8(%esp)
40002e10:	8d 45 cc             	lea    -0x34(%ebp),%eax
40002e13:	89 04 24             	mov    %eax,(%esp)
40002e16:	e8 3e fd ff ff       	call   40002b59 <putint>
			break;
40002e1b:	e9 2b 01 00 00       	jmp    40002f4b <vprintfmt+0x38a>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
40002e20:	8d 45 14             	lea    0x14(%ebp),%eax
40002e23:	89 44 24 04          	mov    %eax,0x4(%esp)
40002e27:	8d 45 cc             	lea    -0x34(%ebp),%eax
40002e2a:	89 04 24             	mov    %eax,(%esp)
40002e2d:	e8 6e fa ff ff       	call   400028a0 <getuint>
40002e32:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
40002e39:	00 
40002e3a:	89 44 24 04          	mov    %eax,0x4(%esp)
40002e3e:	89 54 24 08          	mov    %edx,0x8(%esp)
40002e42:	8d 45 cc             	lea    -0x34(%ebp),%eax
40002e45:	89 04 24             	mov    %eax,(%esp)
40002e48:	e8 0c fd ff ff       	call   40002b59 <putint>
			break;
40002e4d:	e9 f9 00 00 00       	jmp    40002f4b <vprintfmt+0x38a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
40002e52:	8d 45 14             	lea    0x14(%ebp),%eax
40002e55:	89 44 24 04          	mov    %eax,0x4(%esp)
40002e59:	8d 45 cc             	lea    -0x34(%ebp),%eax
40002e5c:	89 04 24             	mov    %eax,(%esp)
40002e5f:	e8 3c fa ff ff       	call   400028a0 <getuint>
40002e64:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
40002e6b:	00 
40002e6c:	89 44 24 04          	mov    %eax,0x4(%esp)
40002e70:	89 54 24 08          	mov    %edx,0x8(%esp)
40002e74:	8d 45 cc             	lea    -0x34(%ebp),%eax
40002e77:	89 04 24             	mov    %eax,(%esp)
40002e7a:	e8 da fc ff ff       	call   40002b59 <putint>
			break;
40002e7f:	e9 c7 00 00 00       	jmp    40002f4b <vprintfmt+0x38a>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
40002e84:	8d 45 14             	lea    0x14(%ebp),%eax
40002e87:	89 44 24 04          	mov    %eax,0x4(%esp)
40002e8b:	8d 45 cc             	lea    -0x34(%ebp),%eax
40002e8e:	89 04 24             	mov    %eax,(%esp)
40002e91:	e8 0a fa ff ff       	call   400028a0 <getuint>
40002e96:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
40002e9d:	00 
40002e9e:	89 44 24 04          	mov    %eax,0x4(%esp)
40002ea2:	89 54 24 08          	mov    %edx,0x8(%esp)
40002ea6:	8d 45 cc             	lea    -0x34(%ebp),%eax
40002ea9:	89 04 24             	mov    %eax,(%esp)
40002eac:	e8 a8 fc ff ff       	call   40002b59 <putint>
			break;
40002eb1:	e9 95 00 00 00       	jmp    40002f4b <vprintfmt+0x38a>

		// pointer
		case 'p':
			putch('0', putdat);
40002eb6:	8b 45 0c             	mov    0xc(%ebp),%eax
40002eb9:	89 44 24 04          	mov    %eax,0x4(%esp)
40002ebd:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
40002ec4:	8b 45 08             	mov    0x8(%ebp),%eax
40002ec7:	ff d0                	call   *%eax
			putch('x', putdat);
40002ec9:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ecc:	89 44 24 04          	mov    %eax,0x4(%esp)
40002ed0:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
40002ed7:	8b 45 08             	mov    0x8(%ebp),%eax
40002eda:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
40002edc:	8b 45 14             	mov    0x14(%ebp),%eax
40002edf:	83 c0 04             	add    $0x4,%eax
40002ee2:	89 45 14             	mov    %eax,0x14(%ebp)
40002ee5:	8b 45 14             	mov    0x14(%ebp),%eax
40002ee8:	83 e8 04             	sub    $0x4,%eax
40002eeb:	8b 00                	mov    (%eax),%eax
40002eed:	ba 00 00 00 00       	mov    $0x0,%edx
40002ef2:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
40002ef9:	00 
40002efa:	89 44 24 04          	mov    %eax,0x4(%esp)
40002efe:	89 54 24 08          	mov    %edx,0x8(%esp)
40002f02:	8d 45 cc             	lea    -0x34(%ebp),%eax
40002f05:	89 04 24             	mov    %eax,(%esp)
40002f08:	e8 4c fc ff ff       	call   40002b59 <putint>
			break;
40002f0d:	eb 3c                	jmp    40002f4b <vprintfmt+0x38a>


		// escaped '%' character
		case '%':
			putch(ch, putdat);
40002f0f:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f12:	89 44 24 04          	mov    %eax,0x4(%esp)
40002f16:	89 1c 24             	mov    %ebx,(%esp)
40002f19:	8b 45 08             	mov    0x8(%ebp),%eax
40002f1c:	ff d0                	call   *%eax
			break;
40002f1e:	eb 2b                	jmp    40002f4b <vprintfmt+0x38a>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
40002f20:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f23:	89 44 24 04          	mov    %eax,0x4(%esp)
40002f27:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
40002f2e:	8b 45 08             	mov    0x8(%ebp),%eax
40002f31:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
40002f33:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40002f37:	eb 04                	jmp    40002f3d <vprintfmt+0x37c>
40002f39:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40002f3d:	8b 45 10             	mov    0x10(%ebp),%eax
40002f40:	83 e8 01             	sub    $0x1,%eax
40002f43:	0f b6 00             	movzbl (%eax),%eax
40002f46:	3c 25                	cmp    $0x25,%al
40002f48:	75 ef                	jne    40002f39 <vprintfmt+0x378>
				/* do nothing */;
			break;
40002f4a:	90                   	nop
		}
	}
40002f4b:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40002f4c:	e9 bf fc ff ff       	jmp    40002c10 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
40002f51:	83 c4 44             	add    $0x44,%esp
40002f54:	5b                   	pop    %ebx
40002f55:	5d                   	pop    %ebp
40002f56:	c3                   	ret    
40002f57:	90                   	nop

40002f58 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
40002f58:	55                   	push   %ebp
40002f59:	89 e5                	mov    %esp,%ebp
40002f5b:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
40002f5e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
40002f65:	eb 08                	jmp    40002f6f <strlen+0x17>
		n++;
40002f67:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
40002f6b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40002f6f:	8b 45 08             	mov    0x8(%ebp),%eax
40002f72:	0f b6 00             	movzbl (%eax),%eax
40002f75:	84 c0                	test   %al,%al
40002f77:	75 ee                	jne    40002f67 <strlen+0xf>
		n++;
	return n;
40002f79:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
40002f7c:	c9                   	leave  
40002f7d:	c3                   	ret    

40002f7e <strcpy>:

char *
strcpy(char *dst, const char *src)
{
40002f7e:	55                   	push   %ebp
40002f7f:	89 e5                	mov    %esp,%ebp
40002f81:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
40002f84:	8b 45 08             	mov    0x8(%ebp),%eax
40002f87:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
40002f8a:	90                   	nop
40002f8b:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f8e:	0f b6 10             	movzbl (%eax),%edx
40002f91:	8b 45 08             	mov    0x8(%ebp),%eax
40002f94:	88 10                	mov    %dl,(%eax)
40002f96:	8b 45 08             	mov    0x8(%ebp),%eax
40002f99:	0f b6 00             	movzbl (%eax),%eax
40002f9c:	84 c0                	test   %al,%al
40002f9e:	0f 95 c0             	setne  %al
40002fa1:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40002fa5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
40002fa9:	84 c0                	test   %al,%al
40002fab:	75 de                	jne    40002f8b <strcpy+0xd>
		/* do nothing */;
	return ret;
40002fad:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
40002fb0:	c9                   	leave  
40002fb1:	c3                   	ret    

40002fb2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
40002fb2:	55                   	push   %ebp
40002fb3:	89 e5                	mov    %esp,%ebp
40002fb5:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
40002fb8:	8b 45 08             	mov    0x8(%ebp),%eax
40002fbb:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
40002fbe:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
40002fc5:	eb 21                	jmp    40002fe8 <strncpy+0x36>
		*dst++ = *src;
40002fc7:	8b 45 0c             	mov    0xc(%ebp),%eax
40002fca:	0f b6 10             	movzbl (%eax),%edx
40002fcd:	8b 45 08             	mov    0x8(%ebp),%eax
40002fd0:	88 10                	mov    %dl,(%eax)
40002fd2:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
40002fd6:	8b 45 0c             	mov    0xc(%ebp),%eax
40002fd9:	0f b6 00             	movzbl (%eax),%eax
40002fdc:	84 c0                	test   %al,%al
40002fde:	74 04                	je     40002fe4 <strncpy+0x32>
			src++;
40002fe0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
40002fe4:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40002fe8:	8b 45 fc             	mov    -0x4(%ebp),%eax
40002feb:	3b 45 10             	cmp    0x10(%ebp),%eax
40002fee:	72 d7                	jb     40002fc7 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
40002ff0:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
40002ff3:	c9                   	leave  
40002ff4:	c3                   	ret    

40002ff5 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
40002ff5:	55                   	push   %ebp
40002ff6:	89 e5                	mov    %esp,%ebp
40002ff8:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
40002ffb:	8b 45 08             	mov    0x8(%ebp),%eax
40002ffe:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
40003001:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003005:	74 2f                	je     40003036 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
40003007:	eb 13                	jmp    4000301c <strlcpy+0x27>
			*dst++ = *src++;
40003009:	8b 45 0c             	mov    0xc(%ebp),%eax
4000300c:	0f b6 10             	movzbl (%eax),%edx
4000300f:	8b 45 08             	mov    0x8(%ebp),%eax
40003012:	88 10                	mov    %dl,(%eax)
40003014:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003018:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
4000301c:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40003020:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40003024:	74 0a                	je     40003030 <strlcpy+0x3b>
40003026:	8b 45 0c             	mov    0xc(%ebp),%eax
40003029:	0f b6 00             	movzbl (%eax),%eax
4000302c:	84 c0                	test   %al,%al
4000302e:	75 d9                	jne    40003009 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
40003030:	8b 45 08             	mov    0x8(%ebp),%eax
40003033:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
40003036:	8b 55 08             	mov    0x8(%ebp),%edx
40003039:	8b 45 fc             	mov    -0x4(%ebp),%eax
4000303c:	89 d1                	mov    %edx,%ecx
4000303e:	29 c1                	sub    %eax,%ecx
40003040:	89 c8                	mov    %ecx,%eax
}
40003042:	c9                   	leave  
40003043:	c3                   	ret    

40003044 <strcmp>:

int
strcmp(const char *p, const char *q)
{
40003044:	55                   	push   %ebp
40003045:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
40003047:	eb 08                	jmp    40003051 <strcmp+0xd>
		p++, q++;
40003049:	83 45 08 01          	addl   $0x1,0x8(%ebp)
4000304d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
40003051:	8b 45 08             	mov    0x8(%ebp),%eax
40003054:	0f b6 00             	movzbl (%eax),%eax
40003057:	84 c0                	test   %al,%al
40003059:	74 10                	je     4000306b <strcmp+0x27>
4000305b:	8b 45 08             	mov    0x8(%ebp),%eax
4000305e:	0f b6 10             	movzbl (%eax),%edx
40003061:	8b 45 0c             	mov    0xc(%ebp),%eax
40003064:	0f b6 00             	movzbl (%eax),%eax
40003067:	38 c2                	cmp    %al,%dl
40003069:	74 de                	je     40003049 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
4000306b:	8b 45 08             	mov    0x8(%ebp),%eax
4000306e:	0f b6 00             	movzbl (%eax),%eax
40003071:	0f b6 d0             	movzbl %al,%edx
40003074:	8b 45 0c             	mov    0xc(%ebp),%eax
40003077:	0f b6 00             	movzbl (%eax),%eax
4000307a:	0f b6 c0             	movzbl %al,%eax
4000307d:	89 d1                	mov    %edx,%ecx
4000307f:	29 c1                	sub    %eax,%ecx
40003081:	89 c8                	mov    %ecx,%eax
}
40003083:	5d                   	pop    %ebp
40003084:	c3                   	ret    

40003085 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
40003085:	55                   	push   %ebp
40003086:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
40003088:	eb 0c                	jmp    40003096 <strncmp+0x11>
		n--, p++, q++;
4000308a:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
4000308e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003092:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
40003096:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
4000309a:	74 1a                	je     400030b6 <strncmp+0x31>
4000309c:	8b 45 08             	mov    0x8(%ebp),%eax
4000309f:	0f b6 00             	movzbl (%eax),%eax
400030a2:	84 c0                	test   %al,%al
400030a4:	74 10                	je     400030b6 <strncmp+0x31>
400030a6:	8b 45 08             	mov    0x8(%ebp),%eax
400030a9:	0f b6 10             	movzbl (%eax),%edx
400030ac:	8b 45 0c             	mov    0xc(%ebp),%eax
400030af:	0f b6 00             	movzbl (%eax),%eax
400030b2:	38 c2                	cmp    %al,%dl
400030b4:	74 d4                	je     4000308a <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
400030b6:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400030ba:	75 07                	jne    400030c3 <strncmp+0x3e>
		return 0;
400030bc:	b8 00 00 00 00       	mov    $0x0,%eax
400030c1:	eb 18                	jmp    400030db <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
400030c3:	8b 45 08             	mov    0x8(%ebp),%eax
400030c6:	0f b6 00             	movzbl (%eax),%eax
400030c9:	0f b6 d0             	movzbl %al,%edx
400030cc:	8b 45 0c             	mov    0xc(%ebp),%eax
400030cf:	0f b6 00             	movzbl (%eax),%eax
400030d2:	0f b6 c0             	movzbl %al,%eax
400030d5:	89 d1                	mov    %edx,%ecx
400030d7:	29 c1                	sub    %eax,%ecx
400030d9:	89 c8                	mov    %ecx,%eax
}
400030db:	5d                   	pop    %ebp
400030dc:	c3                   	ret    

400030dd <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
400030dd:	55                   	push   %ebp
400030de:	89 e5                	mov    %esp,%ebp
400030e0:	83 ec 04             	sub    $0x4,%esp
400030e3:	8b 45 0c             	mov    0xc(%ebp),%eax
400030e6:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
400030e9:	eb 1a                	jmp    40003105 <strchr+0x28>
		if (*s++ == 0)
400030eb:	8b 45 08             	mov    0x8(%ebp),%eax
400030ee:	0f b6 00             	movzbl (%eax),%eax
400030f1:	84 c0                	test   %al,%al
400030f3:	0f 94 c0             	sete   %al
400030f6:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400030fa:	84 c0                	test   %al,%al
400030fc:	74 07                	je     40003105 <strchr+0x28>
			return NULL;
400030fe:	b8 00 00 00 00       	mov    $0x0,%eax
40003103:	eb 0e                	jmp    40003113 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
40003105:	8b 45 08             	mov    0x8(%ebp),%eax
40003108:	0f b6 00             	movzbl (%eax),%eax
4000310b:	3a 45 fc             	cmp    -0x4(%ebp),%al
4000310e:	75 db                	jne    400030eb <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
40003110:	8b 45 08             	mov    0x8(%ebp),%eax
}
40003113:	c9                   	leave  
40003114:	c3                   	ret    

40003115 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
40003115:	55                   	push   %ebp
40003116:	89 e5                	mov    %esp,%ebp
40003118:	57                   	push   %edi
	char *p;

	if (n == 0)
40003119:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
4000311d:	75 05                	jne    40003124 <memset+0xf>
		return v;
4000311f:	8b 45 08             	mov    0x8(%ebp),%eax
40003122:	eb 5c                	jmp    40003180 <memset+0x6b>
	if ((int)v%4 == 0 && n%4 == 0) {
40003124:	8b 45 08             	mov    0x8(%ebp),%eax
40003127:	83 e0 03             	and    $0x3,%eax
4000312a:	85 c0                	test   %eax,%eax
4000312c:	75 41                	jne    4000316f <memset+0x5a>
4000312e:	8b 45 10             	mov    0x10(%ebp),%eax
40003131:	83 e0 03             	and    $0x3,%eax
40003134:	85 c0                	test   %eax,%eax
40003136:	75 37                	jne    4000316f <memset+0x5a>
		c &= 0xFF;
40003138:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
4000313f:	8b 45 0c             	mov    0xc(%ebp),%eax
40003142:	89 c2                	mov    %eax,%edx
40003144:	c1 e2 18             	shl    $0x18,%edx
40003147:	8b 45 0c             	mov    0xc(%ebp),%eax
4000314a:	c1 e0 10             	shl    $0x10,%eax
4000314d:	09 c2                	or     %eax,%edx
4000314f:	8b 45 0c             	mov    0xc(%ebp),%eax
40003152:	c1 e0 08             	shl    $0x8,%eax
40003155:	09 d0                	or     %edx,%eax
40003157:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
4000315a:	8b 45 10             	mov    0x10(%ebp),%eax
4000315d:	89 c1                	mov    %eax,%ecx
4000315f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
40003162:	8b 55 08             	mov    0x8(%ebp),%edx
40003165:	8b 45 0c             	mov    0xc(%ebp),%eax
40003168:	89 d7                	mov    %edx,%edi
4000316a:	fc                   	cld    
4000316b:	f3 ab                	rep stos %eax,%es:(%edi)
4000316d:	eb 0e                	jmp    4000317d <memset+0x68>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
4000316f:	8b 55 08             	mov    0x8(%ebp),%edx
40003172:	8b 45 0c             	mov    0xc(%ebp),%eax
40003175:	8b 4d 10             	mov    0x10(%ebp),%ecx
40003178:	89 d7                	mov    %edx,%edi
4000317a:	fc                   	cld    
4000317b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
4000317d:	8b 45 08             	mov    0x8(%ebp),%eax
}
40003180:	5f                   	pop    %edi
40003181:	5d                   	pop    %ebp
40003182:	c3                   	ret    

40003183 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
40003183:	55                   	push   %ebp
40003184:	89 e5                	mov    %esp,%ebp
40003186:	57                   	push   %edi
40003187:	56                   	push   %esi
40003188:	53                   	push   %ebx
40003189:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
4000318c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000318f:	89 45 f0             	mov    %eax,-0x10(%ebp)
	d = dst;
40003192:	8b 45 08             	mov    0x8(%ebp),%eax
40003195:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (s < d && s + n > d) {
40003198:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000319b:	3b 45 ec             	cmp    -0x14(%ebp),%eax
4000319e:	73 6d                	jae    4000320d <memmove+0x8a>
400031a0:	8b 45 10             	mov    0x10(%ebp),%eax
400031a3:	8b 55 f0             	mov    -0x10(%ebp),%edx
400031a6:	01 d0                	add    %edx,%eax
400031a8:	3b 45 ec             	cmp    -0x14(%ebp),%eax
400031ab:	76 60                	jbe    4000320d <memmove+0x8a>
		s += n;
400031ad:	8b 45 10             	mov    0x10(%ebp),%eax
400031b0:	01 45 f0             	add    %eax,-0x10(%ebp)
		d += n;
400031b3:	8b 45 10             	mov    0x10(%ebp),%eax
400031b6:	01 45 ec             	add    %eax,-0x14(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
400031b9:	8b 45 f0             	mov    -0x10(%ebp),%eax
400031bc:	83 e0 03             	and    $0x3,%eax
400031bf:	85 c0                	test   %eax,%eax
400031c1:	75 2f                	jne    400031f2 <memmove+0x6f>
400031c3:	8b 45 ec             	mov    -0x14(%ebp),%eax
400031c6:	83 e0 03             	and    $0x3,%eax
400031c9:	85 c0                	test   %eax,%eax
400031cb:	75 25                	jne    400031f2 <memmove+0x6f>
400031cd:	8b 45 10             	mov    0x10(%ebp),%eax
400031d0:	83 e0 03             	and    $0x3,%eax
400031d3:	85 c0                	test   %eax,%eax
400031d5:	75 1b                	jne    400031f2 <memmove+0x6f>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
400031d7:	8b 45 ec             	mov    -0x14(%ebp),%eax
400031da:	83 e8 04             	sub    $0x4,%eax
400031dd:	8b 55 f0             	mov    -0x10(%ebp),%edx
400031e0:	83 ea 04             	sub    $0x4,%edx
400031e3:	8b 4d 10             	mov    0x10(%ebp),%ecx
400031e6:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
400031e9:	89 c7                	mov    %eax,%edi
400031eb:	89 d6                	mov    %edx,%esi
400031ed:	fd                   	std    
400031ee:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
400031f0:	eb 18                	jmp    4000320a <memmove+0x87>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
400031f2:	8b 45 ec             	mov    -0x14(%ebp),%eax
400031f5:	8d 50 ff             	lea    -0x1(%eax),%edx
400031f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
400031fb:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
400031fe:	8b 45 10             	mov    0x10(%ebp),%eax
40003201:	89 d7                	mov    %edx,%edi
40003203:	89 de                	mov    %ebx,%esi
40003205:	89 c1                	mov    %eax,%ecx
40003207:	fd                   	std    
40003208:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
4000320a:	fc                   	cld    
4000320b:	eb 45                	jmp    40003252 <memmove+0xcf>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
4000320d:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003210:	83 e0 03             	and    $0x3,%eax
40003213:	85 c0                	test   %eax,%eax
40003215:	75 2b                	jne    40003242 <memmove+0xbf>
40003217:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000321a:	83 e0 03             	and    $0x3,%eax
4000321d:	85 c0                	test   %eax,%eax
4000321f:	75 21                	jne    40003242 <memmove+0xbf>
40003221:	8b 45 10             	mov    0x10(%ebp),%eax
40003224:	83 e0 03             	and    $0x3,%eax
40003227:	85 c0                	test   %eax,%eax
40003229:	75 17                	jne    40003242 <memmove+0xbf>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
4000322b:	8b 45 10             	mov    0x10(%ebp),%eax
4000322e:	89 c1                	mov    %eax,%ecx
40003230:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
40003233:	8b 45 ec             	mov    -0x14(%ebp),%eax
40003236:	8b 55 f0             	mov    -0x10(%ebp),%edx
40003239:	89 c7                	mov    %eax,%edi
4000323b:	89 d6                	mov    %edx,%esi
4000323d:	fc                   	cld    
4000323e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
40003240:	eb 10                	jmp    40003252 <memmove+0xcf>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
40003242:	8b 45 ec             	mov    -0x14(%ebp),%eax
40003245:	8b 55 f0             	mov    -0x10(%ebp),%edx
40003248:	8b 4d 10             	mov    0x10(%ebp),%ecx
4000324b:	89 c7                	mov    %eax,%edi
4000324d:	89 d6                	mov    %edx,%esi
4000324f:	fc                   	cld    
40003250:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
40003252:	8b 45 08             	mov    0x8(%ebp),%eax
}
40003255:	83 c4 10             	add    $0x10,%esp
40003258:	5b                   	pop    %ebx
40003259:	5e                   	pop    %esi
4000325a:	5f                   	pop    %edi
4000325b:	5d                   	pop    %ebp
4000325c:	c3                   	ret    

4000325d <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
4000325d:	55                   	push   %ebp
4000325e:	89 e5                	mov    %esp,%ebp
40003260:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
40003263:	8b 45 10             	mov    0x10(%ebp),%eax
40003266:	89 44 24 08          	mov    %eax,0x8(%esp)
4000326a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000326d:	89 44 24 04          	mov    %eax,0x4(%esp)
40003271:	8b 45 08             	mov    0x8(%ebp),%eax
40003274:	89 04 24             	mov    %eax,(%esp)
40003277:	e8 07 ff ff ff       	call   40003183 <memmove>
}
4000327c:	c9                   	leave  
4000327d:	c3                   	ret    

4000327e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
4000327e:	55                   	push   %ebp
4000327f:	89 e5                	mov    %esp,%ebp
40003281:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
40003284:	8b 45 08             	mov    0x8(%ebp),%eax
40003287:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
4000328a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000328d:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
40003290:	eb 32                	jmp    400032c4 <memcmp+0x46>
		if (*s1 != *s2)
40003292:	8b 45 fc             	mov    -0x4(%ebp),%eax
40003295:	0f b6 10             	movzbl (%eax),%edx
40003298:	8b 45 f8             	mov    -0x8(%ebp),%eax
4000329b:	0f b6 00             	movzbl (%eax),%eax
4000329e:	38 c2                	cmp    %al,%dl
400032a0:	74 1a                	je     400032bc <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
400032a2:	8b 45 fc             	mov    -0x4(%ebp),%eax
400032a5:	0f b6 00             	movzbl (%eax),%eax
400032a8:	0f b6 d0             	movzbl %al,%edx
400032ab:	8b 45 f8             	mov    -0x8(%ebp),%eax
400032ae:	0f b6 00             	movzbl (%eax),%eax
400032b1:	0f b6 c0             	movzbl %al,%eax
400032b4:	89 d1                	mov    %edx,%ecx
400032b6:	29 c1                	sub    %eax,%ecx
400032b8:	89 c8                	mov    %ecx,%eax
400032ba:	eb 1c                	jmp    400032d8 <memcmp+0x5a>
		s1++, s2++;
400032bc:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
400032c0:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
400032c4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400032c8:	0f 95 c0             	setne  %al
400032cb:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
400032cf:	84 c0                	test   %al,%al
400032d1:	75 bf                	jne    40003292 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
400032d3:	b8 00 00 00 00       	mov    $0x0,%eax
}
400032d8:	c9                   	leave  
400032d9:	c3                   	ret    

400032da <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
400032da:	55                   	push   %ebp
400032db:	89 e5                	mov    %esp,%ebp
400032dd:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
400032e0:	8b 45 10             	mov    0x10(%ebp),%eax
400032e3:	8b 55 08             	mov    0x8(%ebp),%edx
400032e6:	01 d0                	add    %edx,%eax
400032e8:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
400032eb:	eb 16                	jmp    40003303 <memchr+0x29>
		if (*(const unsigned char *) s == (unsigned char) c)
400032ed:	8b 45 08             	mov    0x8(%ebp),%eax
400032f0:	0f b6 10             	movzbl (%eax),%edx
400032f3:	8b 45 0c             	mov    0xc(%ebp),%eax
400032f6:	38 c2                	cmp    %al,%dl
400032f8:	75 05                	jne    400032ff <memchr+0x25>
			return (void *) s;
400032fa:	8b 45 08             	mov    0x8(%ebp),%eax
400032fd:	eb 11                	jmp    40003310 <memchr+0x36>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
400032ff:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003303:	8b 45 08             	mov    0x8(%ebp),%eax
40003306:	3b 45 fc             	cmp    -0x4(%ebp),%eax
40003309:	72 e2                	jb     400032ed <memchr+0x13>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
4000330b:	b8 00 00 00 00       	mov    $0x0,%eax
}
40003310:	c9                   	leave  
40003311:	c3                   	ret    
40003312:	66 90                	xchg   %ax,%ax

40003314 <fileino_alloc>:

// Find and return the index of a currently unused file inode in this process.
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_alloc(void)
{
40003314:	55                   	push   %ebp
40003315:	89 e5                	mov    %esp,%ebp
40003317:	83 ec 28             	sub    $0x28,%esp
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
4000331a:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
40003321:	eb 24                	jmp    40003347 <fileino_alloc+0x33>
		if (files->fi[i].de.d_name[0] == 0)
40003323:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40003329:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000332c:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000332f:	01 d0                	add    %edx,%eax
40003331:	05 10 10 00 00       	add    $0x1010,%eax
40003336:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000333a:	84 c0                	test   %al,%al
4000333c:	75 05                	jne    40003343 <fileino_alloc+0x2f>
			return i;
4000333e:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003341:	eb 39                	jmp    4000337c <fileino_alloc+0x68>
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_alloc(void)
{
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40003343:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40003347:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
4000334e:	7e d3                	jle    40003323 <fileino_alloc+0xf>
		if (files->fi[i].de.d_name[0] == 0)
			return i;

	warn("fileino_alloc: no free inodes\n");
40003350:	c7 44 24 08 90 80 00 	movl   $0x40008090,0x8(%esp)
40003357:	40 
40003358:	c7 44 24 04 29 00 00 	movl   $0x29,0x4(%esp)
4000335f:	00 
40003360:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
40003367:	e8 e2 f2 ff ff       	call   4000264e <debug_warn>
	errno = ENOSPC;
4000336c:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40003371:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
	return -1;
40003377:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
4000337c:	c9                   	leave  
4000337d:	c3                   	ret    

4000337e <fileino_create>:
// Returns the index of the inode found or created.
// A newly-created inode is left in the "deleted" state, with mode == 0.
// If no inodes are available, returns -1 and sets errno accordingly.
int
fileino_create(filestate *fs, int dino, const char *name)
{
4000337e:	55                   	push   %ebp
4000337f:	89 e5                	mov    %esp,%ebp
40003381:	83 ec 28             	sub    $0x28,%esp
	assert(dino != 0);
40003384:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40003388:	75 24                	jne    400033ae <fileino_create+0x30>
4000338a:	c7 44 24 0c ba 80 00 	movl   $0x400080ba,0xc(%esp)
40003391:	40 
40003392:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
40003399:	40 
4000339a:	c7 44 24 04 35 00 00 	movl   $0x35,0x4(%esp)
400033a1:	00 
400033a2:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
400033a9:	e8 36 f2 ff ff       	call   400025e4 <debug_panic>
	assert(name != NULL && name[0] != 0);
400033ae:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400033b2:	74 0a                	je     400033be <fileino_create+0x40>
400033b4:	8b 45 10             	mov    0x10(%ebp),%eax
400033b7:	0f b6 00             	movzbl (%eax),%eax
400033ba:	84 c0                	test   %al,%al
400033bc:	75 24                	jne    400033e2 <fileino_create+0x64>
400033be:	c7 44 24 0c d9 80 00 	movl   $0x400080d9,0xc(%esp)
400033c5:	40 
400033c6:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
400033cd:	40 
400033ce:	c7 44 24 04 36 00 00 	movl   $0x36,0x4(%esp)
400033d5:	00 
400033d6:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
400033dd:	e8 02 f2 ff ff       	call   400025e4 <debug_panic>
	assert(strlen(name) <= NAME_MAX);
400033e2:	8b 45 10             	mov    0x10(%ebp),%eax
400033e5:	89 04 24             	mov    %eax,(%esp)
400033e8:	e8 6b fb ff ff       	call   40002f58 <strlen>
400033ed:	83 f8 3f             	cmp    $0x3f,%eax
400033f0:	7e 24                	jle    40003416 <fileino_create+0x98>
400033f2:	c7 44 24 0c f6 80 00 	movl   $0x400080f6,0xc(%esp)
400033f9:	40 
400033fa:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
40003401:	40 
40003402:	c7 44 24 04 37 00 00 	movl   $0x37,0x4(%esp)
40003409:	00 
4000340a:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
40003411:	e8 ce f1 ff ff       	call   400025e4 <debug_panic>

	// First see if an inode already exists for this directory and name.
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40003416:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
4000341d:	eb 4a                	jmp    40003469 <fileino_create+0xeb>
		if (fs->fi[i].dino == dino
4000341f:	8b 55 08             	mov    0x8(%ebp),%edx
40003422:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003425:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003428:	01 d0                	add    %edx,%eax
4000342a:	05 10 10 00 00       	add    $0x1010,%eax
4000342f:	8b 00                	mov    (%eax),%eax
40003431:	3b 45 0c             	cmp    0xc(%ebp),%eax
40003434:	75 2f                	jne    40003465 <fileino_create+0xe7>
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
40003436:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003439:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000343c:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40003442:	8b 45 08             	mov    0x8(%ebp),%eax
40003445:	01 d0                	add    %edx,%eax
40003447:	8d 50 04             	lea    0x4(%eax),%edx
4000344a:	8b 45 10             	mov    0x10(%ebp),%eax
4000344d:	89 44 24 04          	mov    %eax,0x4(%esp)
40003451:	89 14 24             	mov    %edx,(%esp)
40003454:	e8 eb fb ff ff       	call   40003044 <strcmp>
40003459:	85 c0                	test   %eax,%eax
4000345b:	75 08                	jne    40003465 <fileino_create+0xe7>
			return i;
4000345d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003460:	e9 a5 00 00 00       	jmp    4000350a <fileino_create+0x18c>
	assert(name != NULL && name[0] != 0);
	assert(strlen(name) <= NAME_MAX);

	// First see if an inode already exists for this directory and name.
	int i;
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40003465:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40003469:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
40003470:	7e ad                	jle    4000341f <fileino_create+0xa1>
		if (fs->fi[i].dino == dino
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
			return i;

	// No inode allocated to this name - find a free one to allocate.
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
40003472:	c7 45 f4 04 00 00 00 	movl   $0x4,-0xc(%ebp)
40003479:	eb 5a                	jmp    400034d5 <fileino_create+0x157>
		if (fs->fi[i].de.d_name[0] == 0) {
4000347b:	8b 55 08             	mov    0x8(%ebp),%edx
4000347e:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003481:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003484:	01 d0                	add    %edx,%eax
40003486:	05 10 10 00 00       	add    $0x1010,%eax
4000348b:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000348f:	84 c0                	test   %al,%al
40003491:	75 3e                	jne    400034d1 <fileino_create+0x153>
			fs->fi[i].dino = dino;
40003493:	8b 55 08             	mov    0x8(%ebp),%edx
40003496:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003499:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000349c:	01 d0                	add    %edx,%eax
4000349e:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400034a4:	8b 45 0c             	mov    0xc(%ebp),%eax
400034a7:	89 02                	mov    %eax,(%edx)
			strcpy(fs->fi[i].de.d_name, name);
400034a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
400034ac:	6b c0 5c             	imul   $0x5c,%eax,%eax
400034af:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
400034b5:	8b 45 08             	mov    0x8(%ebp),%eax
400034b8:	01 d0                	add    %edx,%eax
400034ba:	8d 50 04             	lea    0x4(%eax),%edx
400034bd:	8b 45 10             	mov    0x10(%ebp),%eax
400034c0:	89 44 24 04          	mov    %eax,0x4(%esp)
400034c4:	89 14 24             	mov    %edx,(%esp)
400034c7:	e8 b2 fa ff ff       	call   40002f7e <strcpy>
			return i;
400034cc:	8b 45 f4             	mov    -0xc(%ebp),%eax
400034cf:	eb 39                	jmp    4000350a <fileino_create+0x18c>
		if (fs->fi[i].dino == dino
				&& strcmp(fs->fi[i].de.d_name, name) == 0)
			return i;

	// No inode allocated to this name - find a free one to allocate.
	for (i = FILEINO_GENERAL; i < FILE_INODES; i++)
400034d1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
400034d5:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
400034dc:	7e 9d                	jle    4000347b <fileino_create+0xfd>
			fs->fi[i].dino = dino;
			strcpy(fs->fi[i].de.d_name, name);
			return i;
		}

	warn("fileino_create: no free inodes\n");
400034de:	c7 44 24 08 10 81 00 	movl   $0x40008110,0x8(%esp)
400034e5:	40 
400034e6:	c7 44 24 04 48 00 00 	movl   $0x48,0x4(%esp)
400034ed:	00 
400034ee:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
400034f5:	e8 54 f1 ff ff       	call   4000264e <debug_warn>
	errno = ENOSPC;
400034fa:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400034ff:	c7 00 07 00 00 00    	movl   $0x7,(%eax)
	return -1;
40003505:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
4000350a:	c9                   	leave  
4000350b:	c3                   	ret    

4000350c <fileino_read>:
// The number of elements returned is normally equal to the 'count' parameter,
// but may be less (without resulting in an error)
// if the file is not large enough to read that many elements.
ssize_t
fileino_read(int ino, off_t ofs, void *buf, size_t eltsize, size_t count)
{
4000350c:	55                   	push   %ebp
4000350d:	89 e5                	mov    %esp,%ebp
4000350f:	83 ec 28             	sub    $0x28,%esp
	assert(fileino_isreg(ino));
40003512:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003516:	7e 45                	jle    4000355d <fileino_read+0x51>
40003518:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
4000351f:	7f 3c                	jg     4000355d <fileino_read+0x51>
40003521:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40003527:	8b 45 08             	mov    0x8(%ebp),%eax
4000352a:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000352d:	01 d0                	add    %edx,%eax
4000352f:	05 10 10 00 00       	add    $0x1010,%eax
40003534:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40003538:	84 c0                	test   %al,%al
4000353a:	74 21                	je     4000355d <fileino_read+0x51>
4000353c:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40003542:	8b 45 08             	mov    0x8(%ebp),%eax
40003545:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003548:	01 d0                	add    %edx,%eax
4000354a:	05 58 10 00 00       	add    $0x1058,%eax
4000354f:	8b 00                	mov    (%eax),%eax
40003551:	25 00 70 00 00       	and    $0x7000,%eax
40003556:	3d 00 10 00 00       	cmp    $0x1000,%eax
4000355b:	74 24                	je     40003581 <fileino_read+0x75>
4000355d:	c7 44 24 0c 30 81 00 	movl   $0x40008130,0xc(%esp)
40003564:	40 
40003565:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
4000356c:	40 
4000356d:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
40003574:	00 
40003575:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
4000357c:	e8 63 f0 ff ff       	call   400025e4 <debug_panic>
	assert(ofs >= 0);
40003581:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40003585:	79 24                	jns    400035ab <fileino_read+0x9f>
40003587:	c7 44 24 0c 43 81 00 	movl   $0x40008143,0xc(%esp)
4000358e:	40 
4000358f:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
40003596:	40 
40003597:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
4000359e:	00 
4000359f:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
400035a6:	e8 39 f0 ff ff       	call   400025e4 <debug_panic>
	assert(eltsize > 0);
400035ab:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
400035af:	75 24                	jne    400035d5 <fileino_read+0xc9>
400035b1:	c7 44 24 0c 4c 81 00 	movl   $0x4000814c,0xc(%esp)
400035b8:	40 
400035b9:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
400035c0:	40 
400035c1:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
400035c8:	00 
400035c9:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
400035d0:	e8 0f f0 ff ff       	call   400025e4 <debug_panic>

	ssize_t return_number = 0;
400035d5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	fileinode *fi = &files->fi[ino];
400035dc:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400035e1:	8b 55 08             	mov    0x8(%ebp),%edx
400035e4:	6b d2 5c             	imul   $0x5c,%edx,%edx
400035e7:	81 c2 10 10 00 00    	add    $0x1010,%edx
400035ed:	01 d0                	add    %edx,%eax
400035ef:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint32_t tmp_ofs = ofs;
400035f2:	8b 45 0c             	mov    0xc(%ebp),%eax
400035f5:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint8_t* read_pointer = FILEDATA(ino) + ofs;
400035f8:	8b 45 08             	mov    0x8(%ebp),%eax
400035fb:	c1 e0 16             	shl    $0x16,%eax
400035fe:	89 c2                	mov    %eax,%edx
40003600:	8b 45 0c             	mov    0xc(%ebp),%eax
40003603:	01 d0                	add    %edx,%eax
40003605:	05 00 00 00 80       	add    $0x80000000,%eax
4000360a:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(fi->size <= FILE_MAXSIZE);
4000360d:	8b 45 e8             	mov    -0x18(%ebp),%eax
40003610:	8b 40 4c             	mov    0x4c(%eax),%eax
40003613:	3d 00 00 40 00       	cmp    $0x400000,%eax
40003618:	76 7a                	jbe    40003694 <fileino_read+0x188>
4000361a:	c7 44 24 0c 58 81 00 	movl   $0x40008158,0xc(%esp)
40003621:	40 
40003622:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
40003629:	40 
4000362a:	c7 44 24 04 5f 00 00 	movl   $0x5f,0x4(%esp)
40003631:	00 
40003632:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
40003639:	e8 a6 ef ff ff       	call   400025e4 <debug_panic>
	// Lab 4: insert your file reading code here.
	//warn("fileino_read() not implemented");
	while(count > 0){
		if(tmp_ofs >= fi->size){
4000363e:	8b 45 e8             	mov    -0x18(%ebp),%eax
40003641:	8b 40 4c             	mov    0x4c(%eax),%eax
40003644:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40003647:	77 18                	ja     40003661 <fileino_read+0x155>
			if(fi->mode & S_IFPART)
40003649:	8b 45 e8             	mov    -0x18(%ebp),%eax
4000364c:	8b 40 48             	mov    0x48(%eax),%eax
4000364f:	25 00 80 00 00       	and    $0x8000,%eax
40003654:	85 c0                	test   %eax,%eax
40003656:	74 44                	je     4000369c <fileino_read+0x190>
40003658:	b8 03 00 00 00       	mov    $0x3,%eax
4000365d:	cd 30                	int    $0x30
4000365f:	eb 33                	jmp    40003694 <fileino_read+0x188>
				sys_ret();
			else
				break;
		}else{
			memcpy(buf, read_pointer, eltsize);
40003661:	8b 45 14             	mov    0x14(%ebp),%eax
40003664:	89 44 24 08          	mov    %eax,0x8(%esp)
40003668:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000366b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000366f:	8b 45 10             	mov    0x10(%ebp),%eax
40003672:	89 04 24             	mov    %eax,(%esp)
40003675:	e8 e3 fb ff ff       	call   4000325d <memcpy>
			return_number++;
4000367a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
			buf += eltsize;
4000367e:	8b 45 14             	mov    0x14(%ebp),%eax
40003681:	01 45 10             	add    %eax,0x10(%ebp)
			read_pointer += eltsize;
40003684:	8b 45 14             	mov    0x14(%ebp),%eax
40003687:	01 45 ec             	add    %eax,-0x14(%ebp)
			tmp_ofs += eltsize;
4000368a:	8b 45 14             	mov    0x14(%ebp),%eax
4000368d:	01 45 f0             	add    %eax,-0x10(%ebp)
			count--;
40003690:	83 6d 18 01          	subl   $0x1,0x18(%ebp)
	uint32_t tmp_ofs = ofs;
	uint8_t* read_pointer = FILEDATA(ino) + ofs;
	assert(fi->size <= FILE_MAXSIZE);
	// Lab 4: insert your file reading code here.
	//warn("fileino_read() not implemented");
	while(count > 0){
40003694:	83 7d 18 00          	cmpl   $0x0,0x18(%ebp)
40003698:	75 a4                	jne    4000363e <fileino_read+0x132>
4000369a:	eb 01                	jmp    4000369d <fileino_read+0x191>
		if(tmp_ofs >= fi->size){
			if(fi->mode & S_IFPART)
				sys_ret();
			else
				break;
4000369c:	90                   	nop
			read_pointer += eltsize;
			tmp_ofs += eltsize;
			count--;
		}
	}
	return return_number;
4000369d:	8b 45 f4             	mov    -0xc(%ebp),%eax
//	errno = EINVAL;
//	return -1;
}
400036a0:	c9                   	leave  
400036a1:	c3                   	ret    

400036a2 <fileino_write>:
// one particular reason an error might occur is if an application
// tries to grow a file beyond this maximum file size,
// in which case this function generates the EFBIG error.
ssize_t
fileino_write(int ino, off_t ofs, const void *buf, size_t eltsize, size_t count)
{
400036a2:	55                   	push   %ebp
400036a3:	89 e5                	mov    %esp,%ebp
400036a5:	57                   	push   %edi
400036a6:	56                   	push   %esi
400036a7:	53                   	push   %ebx
400036a8:	83 ec 6c             	sub    $0x6c,%esp
	assert(fileino_isreg(ino));
400036ab:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400036af:	7e 45                	jle    400036f6 <fileino_write+0x54>
400036b1:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
400036b8:	7f 3c                	jg     400036f6 <fileino_write+0x54>
400036ba:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
400036c0:	8b 45 08             	mov    0x8(%ebp),%eax
400036c3:	6b c0 5c             	imul   $0x5c,%eax,%eax
400036c6:	01 d0                	add    %edx,%eax
400036c8:	05 10 10 00 00       	add    $0x1010,%eax
400036cd:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400036d1:	84 c0                	test   %al,%al
400036d3:	74 21                	je     400036f6 <fileino_write+0x54>
400036d5:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
400036db:	8b 45 08             	mov    0x8(%ebp),%eax
400036de:	6b c0 5c             	imul   $0x5c,%eax,%eax
400036e1:	01 d0                	add    %edx,%eax
400036e3:	05 58 10 00 00       	add    $0x1058,%eax
400036e8:	8b 00                	mov    (%eax),%eax
400036ea:	25 00 70 00 00       	and    $0x7000,%eax
400036ef:	3d 00 10 00 00       	cmp    $0x1000,%eax
400036f4:	74 24                	je     4000371a <fileino_write+0x78>
400036f6:	c7 44 24 0c 30 81 00 	movl   $0x40008130,0xc(%esp)
400036fd:	40 
400036fe:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
40003705:	40 
40003706:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
4000370d:	00 
4000370e:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
40003715:	e8 ca ee ff ff       	call   400025e4 <debug_panic>
	assert(ofs >= 0);
4000371a:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
4000371e:	79 24                	jns    40003744 <fileino_write+0xa2>
40003720:	c7 44 24 0c 43 81 00 	movl   $0x40008143,0xc(%esp)
40003727:	40 
40003728:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
4000372f:	40 
40003730:	c7 44 24 04 84 00 00 	movl   $0x84,0x4(%esp)
40003737:	00 
40003738:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
4000373f:	e8 a0 ee ff ff       	call   400025e4 <debug_panic>
	assert(eltsize > 0);
40003744:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40003748:	75 24                	jne    4000376e <fileino_write+0xcc>
4000374a:	c7 44 24 0c 4c 81 00 	movl   $0x4000814c,0xc(%esp)
40003751:	40 
40003752:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
40003759:	40 
4000375a:	c7 44 24 04 85 00 00 	movl   $0x85,0x4(%esp)
40003761:	00 
40003762:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
40003769:	e8 76 ee ff ff       	call   400025e4 <debug_panic>

	int i = 0;
4000376e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	ssize_t return_number = 0;
40003775:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	fileinode *fi = &files->fi[ino];
4000377c:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40003781:	8b 55 08             	mov    0x8(%ebp),%edx
40003784:	6b d2 5c             	imul   $0x5c,%edx,%edx
40003787:	81 c2 10 10 00 00    	add    $0x1010,%edx
4000378d:	01 d0                	add    %edx,%eax
4000378f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	assert(fi->size <= FILE_MAXSIZE);
40003792:	8b 45 d8             	mov    -0x28(%ebp),%eax
40003795:	8b 40 4c             	mov    0x4c(%eax),%eax
40003798:	3d 00 00 40 00       	cmp    $0x400000,%eax
4000379d:	76 24                	jbe    400037c3 <fileino_write+0x121>
4000379f:	c7 44 24 0c 58 81 00 	movl   $0x40008158,0xc(%esp)
400037a6:	40 
400037a7:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
400037ae:	40 
400037af:	c7 44 24 04 8a 00 00 	movl   $0x8a,0x4(%esp)
400037b6:	00 
400037b7:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
400037be:	e8 21 ee ff ff       	call   400025e4 <debug_panic>
	uint8_t* write_start = FILEDATA(ino) + ofs;
400037c3:	8b 45 08             	mov    0x8(%ebp),%eax
400037c6:	c1 e0 16             	shl    $0x16,%eax
400037c9:	89 c2                	mov    %eax,%edx
400037cb:	8b 45 0c             	mov    0xc(%ebp),%eax
400037ce:	01 d0                	add    %edx,%eax
400037d0:	05 00 00 00 80       	add    $0x80000000,%eax
400037d5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	uint8_t* write_pointer = write_start;
400037d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
400037db:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uint32_t after_write_size = ofs + eltsize * count;
400037de:	8b 45 14             	mov    0x14(%ebp),%eax
400037e1:	89 c2                	mov    %eax,%edx
400037e3:	0f af 55 18          	imul   0x18(%ebp),%edx
400037e7:	8b 45 0c             	mov    0xc(%ebp),%eax
400037ea:	01 d0                	add    %edx,%eax
400037ec:	89 45 d0             	mov    %eax,-0x30(%ebp)

	if(after_write_size > FILE_MAXSIZE){
400037ef:	81 7d d0 00 00 40 00 	cmpl   $0x400000,-0x30(%ebp)
400037f6:	76 15                	jbe    4000380d <fileino_write+0x16b>
		errno = EFBIG;
400037f8:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400037fd:	c7 00 03 00 00 00    	movl   $0x3,(%eax)
		return -1;
40003803:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40003808:	e9 28 01 00 00       	jmp    40003935 <fileino_write+0x293>
	}
	if(after_write_size > fi->size){
4000380d:	8b 45 d8             	mov    -0x28(%ebp),%eax
40003810:	8b 40 4c             	mov    0x4c(%eax),%eax
40003813:	3b 45 d0             	cmp    -0x30(%ebp),%eax
40003816:	0f 83 0d 01 00 00    	jae    40003929 <fileino_write+0x287>
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
4000381c:	c7 45 cc 00 10 00 00 	movl   $0x1000,-0x34(%ebp)
40003823:	8b 45 cc             	mov    -0x34(%ebp),%eax
40003826:	8b 55 d0             	mov    -0x30(%ebp),%edx
40003829:	01 d0                	add    %edx,%eax
4000382b:	83 e8 01             	sub    $0x1,%eax
4000382e:	89 45 c8             	mov    %eax,-0x38(%ebp)
40003831:	8b 45 c8             	mov    -0x38(%ebp),%eax
40003834:	ba 00 00 00 00       	mov    $0x0,%edx
40003839:	f7 75 cc             	divl   -0x34(%ebp)
4000383c:	89 d0                	mov    %edx,%eax
4000383e:	8b 55 c8             	mov    -0x38(%ebp),%edx
40003841:	89 d1                	mov    %edx,%ecx
40003843:	29 c1                	sub    %eax,%ecx
40003845:	89 c8                	mov    %ecx,%eax
40003847:	89 c1                	mov    %eax,%ecx
40003849:	c7 45 c4 00 10 00 00 	movl   $0x1000,-0x3c(%ebp)
40003850:	8b 45 d8             	mov    -0x28(%ebp),%eax
40003853:	8b 50 4c             	mov    0x4c(%eax),%edx
40003856:	8b 45 c4             	mov    -0x3c(%ebp),%eax
40003859:	01 d0                	add    %edx,%eax
4000385b:	83 e8 01             	sub    $0x1,%eax
4000385e:	89 45 c0             	mov    %eax,-0x40(%ebp)
40003861:	8b 45 c0             	mov    -0x40(%ebp),%eax
40003864:	ba 00 00 00 00       	mov    $0x0,%edx
40003869:	f7 75 c4             	divl   -0x3c(%ebp)
4000386c:	89 d0                	mov    %edx,%eax
4000386e:	8b 55 c0             	mov    -0x40(%ebp),%edx
40003871:	89 d3                	mov    %edx,%ebx
40003873:	29 c3                	sub    %eax,%ebx
40003875:	89 d8                	mov    %ebx,%eax
	if(after_write_size > FILE_MAXSIZE){
		errno = EFBIG;
		return -1;
	}
	if(after_write_size > fi->size){
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
40003877:	29 c1                	sub    %eax,%ecx
40003879:	8b 45 08             	mov    0x8(%ebp),%eax
4000387c:	c1 e0 16             	shl    $0x16,%eax
4000387f:	89 c3                	mov    %eax,%ebx
40003881:	c7 45 bc 00 10 00 00 	movl   $0x1000,-0x44(%ebp)
40003888:	8b 45 d8             	mov    -0x28(%ebp),%eax
4000388b:	8b 50 4c             	mov    0x4c(%eax),%edx
4000388e:	8b 45 bc             	mov    -0x44(%ebp),%eax
40003891:	01 d0                	add    %edx,%eax
40003893:	83 e8 01             	sub    $0x1,%eax
40003896:	89 45 b8             	mov    %eax,-0x48(%ebp)
40003899:	8b 45 b8             	mov    -0x48(%ebp),%eax
4000389c:	ba 00 00 00 00       	mov    $0x0,%edx
400038a1:	f7 75 bc             	divl   -0x44(%ebp)
400038a4:	89 d0                	mov    %edx,%eax
400038a6:	8b 55 b8             	mov    -0x48(%ebp),%edx
400038a9:	89 d6                	mov    %edx,%esi
400038ab:	29 c6                	sub    %eax,%esi
400038ad:	89 f0                	mov    %esi,%eax
400038af:	01 d8                	add    %ebx,%eax
400038b1:	05 00 00 00 80       	add    $0x80000000,%eax
400038b6:	c7 45 b4 00 07 00 00 	movl   $0x700,-0x4c(%ebp)
400038bd:	66 c7 45 b2 00 00    	movw   $0x0,-0x4e(%ebp)
400038c3:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
400038ca:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
400038d1:	89 45 a4             	mov    %eax,-0x5c(%ebp)
400038d4:	89 4d a0             	mov    %ecx,-0x60(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400038d7:	8b 45 b4             	mov    -0x4c(%ebp),%eax
400038da:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400038dd:	8b 5d ac             	mov    -0x54(%ebp),%ebx
400038e0:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
400038e4:	8b 75 a8             	mov    -0x58(%ebp),%esi
400038e7:	8b 7d a4             	mov    -0x5c(%ebp),%edi
400038ea:	8b 4d a0             	mov    -0x60(%ebp),%ecx
400038ed:	cd 30                	int    $0x30
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
		fi->size = after_write_size;
400038ef:	8b 45 d8             	mov    -0x28(%ebp),%eax
400038f2:	8b 55 d0             	mov    -0x30(%ebp),%edx
400038f5:	89 50 4c             	mov    %edx,0x4c(%eax)
	}
	for(i; i < count; i++){
400038f8:	eb 2f                	jmp    40003929 <fileino_write+0x287>
		memcpy(write_pointer, buf, eltsize);
400038fa:	8b 45 14             	mov    0x14(%ebp),%eax
400038fd:	89 44 24 08          	mov    %eax,0x8(%esp)
40003901:	8b 45 10             	mov    0x10(%ebp),%eax
40003904:	89 44 24 04          	mov    %eax,0x4(%esp)
40003908:	8b 45 dc             	mov    -0x24(%ebp),%eax
4000390b:	89 04 24             	mov    %eax,(%esp)
4000390e:	e8 4a f9 ff ff       	call   4000325d <memcpy>
		return_number++;
40003913:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
		buf += eltsize;
40003917:	8b 45 14             	mov    0x14(%ebp),%eax
4000391a:	01 45 10             	add    %eax,0x10(%ebp)
		write_pointer += eltsize;
4000391d:	8b 45 14             	mov    0x14(%ebp),%eax
40003920:	01 45 dc             	add    %eax,-0x24(%ebp)
	if(after_write_size > fi->size){
		sys_get(SYS_PERM | SYS_RW, 0, NULL, NULL, (void*)(FILEDATA(ino) + ROUNDUP(fi->size, PAGESIZE)), 
			ROUNDUP(after_write_size, PAGESIZE) - ROUNDUP(fi->size, PAGESIZE));
		fi->size = after_write_size;
	}
	for(i; i < count; i++){
40003923:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
40003927:	eb 01                	jmp    4000392a <fileino_write+0x288>
40003929:	90                   	nop
4000392a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000392d:	3b 45 18             	cmp    0x18(%ebp),%eax
40003930:	72 c8                	jb     400038fa <fileino_write+0x258>
		memcpy(write_pointer, buf, eltsize);
		return_number++;
		buf += eltsize;
		write_pointer += eltsize;
	}
	return return_number;
40003932:	8b 45 e0             	mov    -0x20(%ebp),%eax

	// Lab 4: insert your file writing code here.
	//warn("fileino_write() not implemented");
	//errno = EINVAL;
	//return -1;
}
40003935:	83 c4 6c             	add    $0x6c,%esp
40003938:	5b                   	pop    %ebx
40003939:	5e                   	pop    %esi
4000393a:	5f                   	pop    %edi
4000393b:	5d                   	pop    %ebp
4000393c:	c3                   	ret    

4000393d <fileino_stat>:
// Return file statistics about a particular inode.
// The specified inode must indicate a file that exists,
// but it can be any type of object: e.g., file, directory, special file, etc.
int
fileino_stat(int ino, struct stat *st)
{
4000393d:	55                   	push   %ebp
4000393e:	89 e5                	mov    %esp,%ebp
40003940:	83 ec 28             	sub    $0x28,%esp
	assert(fileino_exists(ino));
40003943:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003947:	7e 3d                	jle    40003986 <fileino_stat+0x49>
40003949:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40003950:	7f 34                	jg     40003986 <fileino_stat+0x49>
40003952:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40003958:	8b 45 08             	mov    0x8(%ebp),%eax
4000395b:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000395e:	01 d0                	add    %edx,%eax
40003960:	05 10 10 00 00       	add    $0x1010,%eax
40003965:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40003969:	84 c0                	test   %al,%al
4000396b:	74 19                	je     40003986 <fileino_stat+0x49>
4000396d:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40003973:	8b 45 08             	mov    0x8(%ebp),%eax
40003976:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003979:	01 d0                	add    %edx,%eax
4000397b:	05 58 10 00 00       	add    $0x1058,%eax
40003980:	8b 00                	mov    (%eax),%eax
40003982:	85 c0                	test   %eax,%eax
40003984:	75 24                	jne    400039aa <fileino_stat+0x6d>
40003986:	c7 44 24 0c 71 81 00 	movl   $0x40008171,0xc(%esp)
4000398d:	40 
4000398e:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
40003995:	40 
40003996:	c7 44 24 04 ac 00 00 	movl   $0xac,0x4(%esp)
4000399d:	00 
4000399e:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
400039a5:	e8 3a ec ff ff       	call   400025e4 <debug_panic>

	fileinode *fi = &files->fi[ino];
400039aa:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400039af:	8b 55 08             	mov    0x8(%ebp),%edx
400039b2:	6b d2 5c             	imul   $0x5c,%edx,%edx
400039b5:	81 c2 10 10 00 00    	add    $0x1010,%edx
400039bb:	01 d0                	add    %edx,%eax
400039bd:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert(fileino_isdir(fi->dino));	// Should be in a directory!
400039c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
400039c3:	8b 00                	mov    (%eax),%eax
400039c5:	85 c0                	test   %eax,%eax
400039c7:	7e 4c                	jle    40003a15 <fileino_stat+0xd8>
400039c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
400039cc:	8b 00                	mov    (%eax),%eax
400039ce:	3d ff 00 00 00       	cmp    $0xff,%eax
400039d3:	7f 40                	jg     40003a15 <fileino_stat+0xd8>
400039d5:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
400039db:	8b 45 f4             	mov    -0xc(%ebp),%eax
400039de:	8b 00                	mov    (%eax),%eax
400039e0:	6b c0 5c             	imul   $0x5c,%eax,%eax
400039e3:	01 d0                	add    %edx,%eax
400039e5:	05 10 10 00 00       	add    $0x1010,%eax
400039ea:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400039ee:	84 c0                	test   %al,%al
400039f0:	74 23                	je     40003a15 <fileino_stat+0xd8>
400039f2:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
400039f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
400039fb:	8b 00                	mov    (%eax),%eax
400039fd:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003a00:	01 d0                	add    %edx,%eax
40003a02:	05 58 10 00 00       	add    $0x1058,%eax
40003a07:	8b 00                	mov    (%eax),%eax
40003a09:	25 00 70 00 00       	and    $0x7000,%eax
40003a0e:	3d 00 20 00 00       	cmp    $0x2000,%eax
40003a13:	74 24                	je     40003a39 <fileino_stat+0xfc>
40003a15:	c7 44 24 0c 85 81 00 	movl   $0x40008185,0xc(%esp)
40003a1c:	40 
40003a1d:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
40003a24:	40 
40003a25:	c7 44 24 04 af 00 00 	movl   $0xaf,0x4(%esp)
40003a2c:	00 
40003a2d:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
40003a34:	e8 ab eb ff ff       	call   400025e4 <debug_panic>
	st->st_ino = ino;
40003a39:	8b 45 0c             	mov    0xc(%ebp),%eax
40003a3c:	8b 55 08             	mov    0x8(%ebp),%edx
40003a3f:	89 10                	mov    %edx,(%eax)
	st->st_mode = fi->mode;
40003a41:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003a44:	8b 50 48             	mov    0x48(%eax),%edx
40003a47:	8b 45 0c             	mov    0xc(%ebp),%eax
40003a4a:	89 50 04             	mov    %edx,0x4(%eax)
	st->st_size = fi->size;
40003a4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003a50:	8b 40 4c             	mov    0x4c(%eax),%eax
40003a53:	89 c2                	mov    %eax,%edx
40003a55:	8b 45 0c             	mov    0xc(%ebp),%eax
40003a58:	89 50 08             	mov    %edx,0x8(%eax)

	return 0;
40003a5b:	b8 00 00 00 00       	mov    $0x0,%eax
}
40003a60:	c9                   	leave  
40003a61:	c3                   	ret    

40003a62 <fileino_truncate>:
// Grow or shrink a file to exactly a specified size.
// If growing a file, then fills the new space with zeros.
// Returns 0 if successful, or returns -1 and sets errno on error.
int
fileino_truncate(int ino, off_t newsize)
{
40003a62:	55                   	push   %ebp
40003a63:	89 e5                	mov    %esp,%ebp
40003a65:	57                   	push   %edi
40003a66:	56                   	push   %esi
40003a67:	53                   	push   %ebx
40003a68:	81 ec 8c 00 00 00    	sub    $0x8c,%esp
	assert(fileino_isvalid(ino));
40003a6e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003a72:	7e 09                	jle    40003a7d <fileino_truncate+0x1b>
40003a74:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40003a7b:	7e 24                	jle    40003aa1 <fileino_truncate+0x3f>
40003a7d:	c7 44 24 0c 9d 81 00 	movl   $0x4000819d,0xc(%esp)
40003a84:	40 
40003a85:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
40003a8c:	40 
40003a8d:	c7 44 24 04 bd 00 00 	movl   $0xbd,0x4(%esp)
40003a94:	00 
40003a95:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
40003a9c:	e8 43 eb ff ff       	call   400025e4 <debug_panic>
	assert(newsize >= 0 && newsize <= FILE_MAXSIZE);
40003aa1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40003aa5:	78 09                	js     40003ab0 <fileino_truncate+0x4e>
40003aa7:	81 7d 0c 00 00 40 00 	cmpl   $0x400000,0xc(%ebp)
40003aae:	7e 24                	jle    40003ad4 <fileino_truncate+0x72>
40003ab0:	c7 44 24 0c b4 81 00 	movl   $0x400081b4,0xc(%esp)
40003ab7:	40 
40003ab8:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
40003abf:	40 
40003ac0:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
40003ac7:	00 
40003ac8:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
40003acf:	e8 10 eb ff ff       	call   400025e4 <debug_panic>

	size_t oldsize = files->fi[ino].size;
40003ad4:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40003ada:	8b 45 08             	mov    0x8(%ebp),%eax
40003add:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003ae0:	01 d0                	add    %edx,%eax
40003ae2:	05 5c 10 00 00       	add    $0x105c,%eax
40003ae7:	8b 00                	mov    (%eax),%eax
40003ae9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	size_t oldpagelim = ROUNDUP(files->fi[ino].size, PAGESIZE);
40003aec:	c7 45 e0 00 10 00 00 	movl   $0x1000,-0x20(%ebp)
40003af3:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40003af9:	8b 45 08             	mov    0x8(%ebp),%eax
40003afc:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003aff:	01 d0                	add    %edx,%eax
40003b01:	05 5c 10 00 00       	add    $0x105c,%eax
40003b06:	8b 10                	mov    (%eax),%edx
40003b08:	8b 45 e0             	mov    -0x20(%ebp),%eax
40003b0b:	01 d0                	add    %edx,%eax
40003b0d:	83 e8 01             	sub    $0x1,%eax
40003b10:	89 45 dc             	mov    %eax,-0x24(%ebp)
40003b13:	8b 45 dc             	mov    -0x24(%ebp),%eax
40003b16:	ba 00 00 00 00       	mov    $0x0,%edx
40003b1b:	f7 75 e0             	divl   -0x20(%ebp)
40003b1e:	89 d0                	mov    %edx,%eax
40003b20:	8b 55 dc             	mov    -0x24(%ebp),%edx
40003b23:	89 d1                	mov    %edx,%ecx
40003b25:	29 c1                	sub    %eax,%ecx
40003b27:	89 c8                	mov    %ecx,%eax
40003b29:	89 45 d8             	mov    %eax,-0x28(%ebp)
	size_t newpagelim = ROUNDUP(newsize, PAGESIZE);
40003b2c:	c7 45 d4 00 10 00 00 	movl   $0x1000,-0x2c(%ebp)
40003b33:	8b 55 0c             	mov    0xc(%ebp),%edx
40003b36:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40003b39:	01 d0                	add    %edx,%eax
40003b3b:	83 e8 01             	sub    $0x1,%eax
40003b3e:	89 45 d0             	mov    %eax,-0x30(%ebp)
40003b41:	8b 45 d0             	mov    -0x30(%ebp),%eax
40003b44:	ba 00 00 00 00       	mov    $0x0,%edx
40003b49:	f7 75 d4             	divl   -0x2c(%ebp)
40003b4c:	89 d0                	mov    %edx,%eax
40003b4e:	8b 55 d0             	mov    -0x30(%ebp),%edx
40003b51:	89 d1                	mov    %edx,%ecx
40003b53:	29 c1                	sub    %eax,%ecx
40003b55:	89 c8                	mov    %ecx,%eax
40003b57:	89 45 cc             	mov    %eax,-0x34(%ebp)
	if (newsize > oldsize) {
40003b5a:	8b 45 0c             	mov    0xc(%ebp),%eax
40003b5d:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
40003b60:	0f 86 8a 00 00 00    	jbe    40003bf0 <fileino_truncate+0x18e>
		// Grow the file and fill the new space with zeros.
		sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
40003b66:	8b 45 d8             	mov    -0x28(%ebp),%eax
40003b69:	8b 55 cc             	mov    -0x34(%ebp),%edx
40003b6c:	89 d1                	mov    %edx,%ecx
40003b6e:	29 c1                	sub    %eax,%ecx
40003b70:	89 c8                	mov    %ecx,%eax
			FILEDATA(ino) + oldpagelim,
40003b72:	8b 55 08             	mov    0x8(%ebp),%edx
40003b75:	c1 e2 16             	shl    $0x16,%edx
40003b78:	89 d1                	mov    %edx,%ecx
40003b7a:	8b 55 d8             	mov    -0x28(%ebp),%edx
40003b7d:	01 ca                	add    %ecx,%edx
	size_t oldsize = files->fi[ino].size;
	size_t oldpagelim = ROUNDUP(files->fi[ino].size, PAGESIZE);
	size_t newpagelim = ROUNDUP(newsize, PAGESIZE);
	if (newsize > oldsize) {
		// Grow the file and fill the new space with zeros.
		sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
40003b7f:	81 c2 00 00 00 80    	add    $0x80000000,%edx
40003b85:	c7 45 c8 00 07 00 00 	movl   $0x700,-0x38(%ebp)
40003b8c:	66 c7 45 c6 00 00    	movw   $0x0,-0x3a(%ebp)
40003b92:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
40003b99:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
40003ba0:	89 55 b8             	mov    %edx,-0x48(%ebp)
40003ba3:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40003ba6:	8b 45 c8             	mov    -0x38(%ebp),%eax
40003ba9:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40003bac:	8b 5d c0             	mov    -0x40(%ebp),%ebx
40003baf:	0f b7 55 c6          	movzwl -0x3a(%ebp),%edx
40003bb3:	8b 75 bc             	mov    -0x44(%ebp),%esi
40003bb6:	8b 7d b8             	mov    -0x48(%ebp),%edi
40003bb9:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
40003bbc:	cd 30                	int    $0x30
			FILEDATA(ino) + oldpagelim,
			newpagelim - oldpagelim);
		memset(FILEDATA(ino) + oldsize, 0, newsize - oldsize);
40003bbe:	8b 45 0c             	mov    0xc(%ebp),%eax
40003bc1:	2b 45 e4             	sub    -0x1c(%ebp),%eax
40003bc4:	8b 55 08             	mov    0x8(%ebp),%edx
40003bc7:	c1 e2 16             	shl    $0x16,%edx
40003bca:	89 d1                	mov    %edx,%ecx
40003bcc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
40003bcf:	01 ca                	add    %ecx,%edx
40003bd1:	81 c2 00 00 00 80    	add    $0x80000000,%edx
40003bd7:	89 44 24 08          	mov    %eax,0x8(%esp)
40003bdb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40003be2:	00 
40003be3:	89 14 24             	mov    %edx,(%esp)
40003be6:	e8 2a f5 ff ff       	call   40003115 <memset>
40003beb:	e9 a4 00 00 00       	jmp    40003c94 <fileino_truncate+0x232>
	} else if (newsize > 0) {
40003bf0:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40003bf4:	7e 56                	jle    40003c4c <fileino_truncate+0x1ea>
		// Shrink the file, but not all the way to empty.
		// Would prefer to use SYS_ZERO to free the file content,
		// but SYS_ZERO isn't guaranteed to work at page granularity.
		sys_get(SYS_PERM, 0, NULL, NULL,
40003bf6:	b8 00 00 40 00       	mov    $0x400000,%eax
40003bfb:	2b 45 cc             	sub    -0x34(%ebp),%eax
			FILEDATA(ino) + newpagelim, FILE_MAXSIZE - newpagelim);
40003bfe:	8b 55 08             	mov    0x8(%ebp),%edx
40003c01:	c1 e2 16             	shl    $0x16,%edx
40003c04:	89 d1                	mov    %edx,%ecx
40003c06:	8b 55 cc             	mov    -0x34(%ebp),%edx
40003c09:	01 ca                	add    %ecx,%edx
		memset(FILEDATA(ino) + oldsize, 0, newsize - oldsize);
	} else if (newsize > 0) {
		// Shrink the file, but not all the way to empty.
		// Would prefer to use SYS_ZERO to free the file content,
		// but SYS_ZERO isn't guaranteed to work at page granularity.
		sys_get(SYS_PERM, 0, NULL, NULL,
40003c0b:	81 c2 00 00 00 80    	add    $0x80000000,%edx
40003c11:	c7 45 b0 00 01 00 00 	movl   $0x100,-0x50(%ebp)
40003c18:	66 c7 45 ae 00 00    	movw   $0x0,-0x52(%ebp)
40003c1e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
40003c25:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
40003c2c:	89 55 a0             	mov    %edx,-0x60(%ebp)
40003c2f:	89 45 9c             	mov    %eax,-0x64(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40003c32:	8b 45 b0             	mov    -0x50(%ebp),%eax
40003c35:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40003c38:	8b 5d a8             	mov    -0x58(%ebp),%ebx
40003c3b:	0f b7 55 ae          	movzwl -0x52(%ebp),%edx
40003c3f:	8b 75 a4             	mov    -0x5c(%ebp),%esi
40003c42:	8b 7d a0             	mov    -0x60(%ebp),%edi
40003c45:	8b 4d 9c             	mov    -0x64(%ebp),%ecx
40003c48:	cd 30                	int    $0x30
40003c4a:	eb 48                	jmp    40003c94 <fileino_truncate+0x232>
			FILEDATA(ino) + newpagelim, FILE_MAXSIZE - newpagelim);
	} else {
		// Shrink the file to empty.  Use SYS_ZERO to free completely.
		sys_get(SYS_ZERO, 0, NULL, NULL, FILEDATA(ino), FILE_MAXSIZE);
40003c4c:	8b 45 08             	mov    0x8(%ebp),%eax
40003c4f:	c1 e0 16             	shl    $0x16,%eax
40003c52:	05 00 00 00 80       	add    $0x80000000,%eax
40003c57:	c7 45 98 00 00 01 00 	movl   $0x10000,-0x68(%ebp)
40003c5e:	66 c7 45 96 00 00    	movw   $0x0,-0x6a(%ebp)
40003c64:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
40003c6b:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
40003c72:	89 45 88             	mov    %eax,-0x78(%ebp)
40003c75:	c7 45 84 00 00 40 00 	movl   $0x400000,-0x7c(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40003c7c:	8b 45 98             	mov    -0x68(%ebp),%eax
40003c7f:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40003c82:	8b 5d 90             	mov    -0x70(%ebp),%ebx
40003c85:	0f b7 55 96          	movzwl -0x6a(%ebp),%edx
40003c89:	8b 75 8c             	mov    -0x74(%ebp),%esi
40003c8c:	8b 7d 88             	mov    -0x78(%ebp),%edi
40003c8f:	8b 4d 84             	mov    -0x7c(%ebp),%ecx
40003c92:	cd 30                	int    $0x30
	}
	files->fi[ino].size = newsize;
40003c94:	8b 0d 8c 80 00 40    	mov    0x4000808c,%ecx
40003c9a:	8b 45 0c             	mov    0xc(%ebp),%eax
40003c9d:	8b 55 08             	mov    0x8(%ebp),%edx
40003ca0:	6b d2 5c             	imul   $0x5c,%edx,%edx
40003ca3:	01 ca                	add    %ecx,%edx
40003ca5:	81 c2 5c 10 00 00    	add    $0x105c,%edx
40003cab:	89 02                	mov    %eax,(%edx)
	files->fi[ino].ver++;	// truncation is always an exclusive change
40003cad:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40003cb2:	8b 55 08             	mov    0x8(%ebp),%edx
40003cb5:	6b d2 5c             	imul   $0x5c,%edx,%edx
40003cb8:	01 c2                	add    %eax,%edx
40003cba:	81 c2 54 10 00 00    	add    $0x1054,%edx
40003cc0:	8b 12                	mov    (%edx),%edx
40003cc2:	83 c2 01             	add    $0x1,%edx
40003cc5:	8b 4d 08             	mov    0x8(%ebp),%ecx
40003cc8:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
40003ccb:	01 c8                	add    %ecx,%eax
40003ccd:	05 54 10 00 00       	add    $0x1054,%eax
40003cd2:	89 10                	mov    %edx,(%eax)
	return 0;
40003cd4:	b8 00 00 00 00       	mov    $0x0,%eax
}
40003cd9:	81 c4 8c 00 00 00    	add    $0x8c,%esp
40003cdf:	5b                   	pop    %ebx
40003ce0:	5e                   	pop    %esi
40003ce1:	5f                   	pop    %edi
40003ce2:	5d                   	pop    %ebp
40003ce3:	c3                   	ret    

40003ce4 <fileino_flush>:

// Flush any outstanding writes on this file to our parent process.
// (XXX should flushes propagate across multiple levels?)
int
fileino_flush(int ino)
{
40003ce4:	55                   	push   %ebp
40003ce5:	89 e5                	mov    %esp,%ebp
40003ce7:	83 ec 18             	sub    $0x18,%esp
	assert(fileino_isvalid(ino));
40003cea:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003cee:	7e 09                	jle    40003cf9 <fileino_flush+0x15>
40003cf0:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40003cf7:	7e 24                	jle    40003d1d <fileino_flush+0x39>
40003cf9:	c7 44 24 0c 9d 81 00 	movl   $0x4000819d,0xc(%esp)
40003d00:	40 
40003d01:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
40003d08:	40 
40003d09:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
40003d10:	00 
40003d11:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
40003d18:	e8 c7 e8 ff ff       	call   400025e4 <debug_panic>

	if (files->fi[ino].size > files->fi[ino].rlen)
40003d1d:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40003d23:	8b 45 08             	mov    0x8(%ebp),%eax
40003d26:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003d29:	01 d0                	add    %edx,%eax
40003d2b:	05 5c 10 00 00       	add    $0x105c,%eax
40003d30:	8b 10                	mov    (%eax),%edx
40003d32:	8b 0d 8c 80 00 40    	mov    0x4000808c,%ecx
40003d38:	8b 45 08             	mov    0x8(%ebp),%eax
40003d3b:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003d3e:	01 c8                	add    %ecx,%eax
40003d40:	05 68 10 00 00       	add    $0x1068,%eax
40003d45:	8b 00                	mov    (%eax),%eax
40003d47:	39 c2                	cmp    %eax,%edx
40003d49:	76 07                	jbe    40003d52 <fileino_flush+0x6e>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40003d4b:	b8 03 00 00 00       	mov    $0x3,%eax
40003d50:	cd 30                	int    $0x30
		sys_ret();	// synchronize and reconcile with parent
	return 0;
40003d52:	b8 00 00 00 00       	mov    $0x0,%eax
}
40003d57:	c9                   	leave  
40003d58:	c3                   	ret    

40003d59 <filedesc_alloc>:
// Search the file descriptor table for the first free file descriptor,
// and return a pointer to that file descriptor.
// If no file descriptors are available,
// returns NULL and set errno appropriately.
filedesc *filedesc_alloc(void)
{
40003d59:	55                   	push   %ebp
40003d5a:	89 e5                	mov    %esp,%ebp
40003d5c:	83 ec 10             	sub    $0x10,%esp
	int i;
	for (i = 0; i < OPEN_MAX; i++)
40003d5f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
40003d66:	eb 2c                	jmp    40003d94 <filedesc_alloc+0x3b>
		if (files->fd[i].ino == FILEINO_NULL)
40003d68:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40003d6d:	8b 55 fc             	mov    -0x4(%ebp),%edx
40003d70:	83 c2 01             	add    $0x1,%edx
40003d73:	c1 e2 04             	shl    $0x4,%edx
40003d76:	01 d0                	add    %edx,%eax
40003d78:	8b 00                	mov    (%eax),%eax
40003d7a:	85 c0                	test   %eax,%eax
40003d7c:	75 12                	jne    40003d90 <filedesc_alloc+0x37>
			return &files->fd[i];
40003d7e:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40003d83:	8b 55 fc             	mov    -0x4(%ebp),%edx
40003d86:	83 c2 01             	add    $0x1,%edx
40003d89:	c1 e2 04             	shl    $0x4,%edx
40003d8c:	01 d0                	add    %edx,%eax
40003d8e:	eb 1d                	jmp    40003dad <filedesc_alloc+0x54>
// If no file descriptors are available,
// returns NULL and set errno appropriately.
filedesc *filedesc_alloc(void)
{
	int i;
	for (i = 0; i < OPEN_MAX; i++)
40003d90:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
40003d94:	81 7d fc ff 00 00 00 	cmpl   $0xff,-0x4(%ebp)
40003d9b:	7e cb                	jle    40003d68 <filedesc_alloc+0xf>
		if (files->fd[i].ino == FILEINO_NULL)
			return &files->fd[i];
	errno = EMFILE;
40003d9d:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40003da2:	c7 00 04 00 00 00    	movl   $0x4,(%eax)
	return NULL;
40003da8:	b8 00 00 00 00       	mov    $0x0,%eax
}
40003dad:	c9                   	leave  
40003dae:	c3                   	ret    

40003daf <filedesc_open>:
// The 'openflags' determines whether the file is created, truncated, etc.
// Returns the opened file descriptor on success,
// or returns NULL and sets errno on failure.
filedesc *
filedesc_open(filedesc *fd, const char *path, int openflags, mode_t mode)
{
40003daf:	55                   	push   %ebp
40003db0:	89 e5                	mov    %esp,%ebp
40003db2:	83 ec 28             	sub    $0x28,%esp
	if (!fd && !(fd = filedesc_alloc()))
40003db5:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003db9:	75 18                	jne    40003dd3 <filedesc_open+0x24>
40003dbb:	e8 99 ff ff ff       	call   40003d59 <filedesc_alloc>
40003dc0:	89 45 08             	mov    %eax,0x8(%ebp)
40003dc3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40003dc7:	75 0a                	jne    40003dd3 <filedesc_open+0x24>
		return NULL;
40003dc9:	b8 00 00 00 00       	mov    $0x0,%eax
40003dce:	e9 04 02 00 00       	jmp    40003fd7 <filedesc_open+0x228>
	assert(fd->ino == FILEINO_NULL);
40003dd3:	8b 45 08             	mov    0x8(%ebp),%eax
40003dd6:	8b 00                	mov    (%eax),%eax
40003dd8:	85 c0                	test   %eax,%eax
40003dda:	74 24                	je     40003e00 <filedesc_open+0x51>
40003ddc:	c7 44 24 0c dc 81 00 	movl   $0x400081dc,0xc(%esp)
40003de3:	40 
40003de4:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
40003deb:	40 
40003dec:	c7 44 24 04 00 01 00 	movl   $0x100,0x4(%esp)
40003df3:	00 
40003df4:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
40003dfb:	e8 e4 e7 ff ff       	call   400025e4 <debug_panic>

	// Determine the complete file mode if it is to be created.
	mode_t createmode = (openflags & O_CREAT) ? S_IFREG | (mode & 0777) : 0;
40003e00:	8b 45 10             	mov    0x10(%ebp),%eax
40003e03:	83 e0 20             	and    $0x20,%eax
40003e06:	85 c0                	test   %eax,%eax
40003e08:	74 0d                	je     40003e17 <filedesc_open+0x68>
40003e0a:	8b 45 14             	mov    0x14(%ebp),%eax
40003e0d:	25 ff 01 00 00       	and    $0x1ff,%eax
40003e12:	80 cc 10             	or     $0x10,%ah
40003e15:	eb 05                	jmp    40003e1c <filedesc_open+0x6d>
40003e17:	b8 00 00 00 00       	mov    $0x0,%eax
40003e1c:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Walk the directory tree to find the desired directory entry,
	// creating an entry if it doesn't exist and O_CREAT is set.
	int ino = dir_walk(path, createmode);
40003e1f:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003e22:	89 44 24 04          	mov    %eax,0x4(%esp)
40003e26:	8b 45 0c             	mov    0xc(%ebp),%eax
40003e29:	89 04 24             	mov    %eax,(%esp)
40003e2c:	e8 d7 05 00 00       	call   40004408 <dir_walk>
40003e31:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (ino < 0)
40003e34:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40003e38:	79 0a                	jns    40003e44 <filedesc_open+0x95>
		return NULL;
40003e3a:	b8 00 00 00 00       	mov    $0x0,%eax
40003e3f:	e9 93 01 00 00       	jmp    40003fd7 <filedesc_open+0x228>
	assert(fileino_exists(ino));
40003e44:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40003e48:	7e 3d                	jle    40003e87 <filedesc_open+0xd8>
40003e4a:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40003e51:	7f 34                	jg     40003e87 <filedesc_open+0xd8>
40003e53:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40003e59:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003e5c:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003e5f:	01 d0                	add    %edx,%eax
40003e61:	05 10 10 00 00       	add    $0x1010,%eax
40003e66:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40003e6a:	84 c0                	test   %al,%al
40003e6c:	74 19                	je     40003e87 <filedesc_open+0xd8>
40003e6e:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40003e74:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003e77:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003e7a:	01 d0                	add    %edx,%eax
40003e7c:	05 58 10 00 00       	add    $0x1058,%eax
40003e81:	8b 00                	mov    (%eax),%eax
40003e83:	85 c0                	test   %eax,%eax
40003e85:	75 24                	jne    40003eab <filedesc_open+0xfc>
40003e87:	c7 44 24 0c 71 81 00 	movl   $0x40008171,0xc(%esp)
40003e8e:	40 
40003e8f:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
40003e96:	40 
40003e97:	c7 44 24 04 0a 01 00 	movl   $0x10a,0x4(%esp)
40003e9e:	00 
40003e9f:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
40003ea6:	e8 39 e7 ff ff       	call   400025e4 <debug_panic>

	// Refuse to open conflict-marked files;
	// the user needs to resolve the conflict and clear the conflict flag,
	// or just delete the conflicted file.
	if (files->fi[ino].mode & S_IFCONF) {
40003eab:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40003eb1:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003eb4:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003eb7:	01 d0                	add    %edx,%eax
40003eb9:	05 58 10 00 00       	add    $0x1058,%eax
40003ebe:	8b 00                	mov    (%eax),%eax
40003ec0:	25 00 00 01 00       	and    $0x10000,%eax
40003ec5:	85 c0                	test   %eax,%eax
40003ec7:	74 15                	je     40003ede <filedesc_open+0x12f>
		errno = ECONFLICT;
40003ec9:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40003ece:	c7 00 0a 00 00 00    	movl   $0xa,(%eax)
		return NULL;
40003ed4:	b8 00 00 00 00       	mov    $0x0,%eax
40003ed9:	e9 f9 00 00 00       	jmp    40003fd7 <filedesc_open+0x228>
	}

	// Truncate the file if we were asked to
	if (openflags & O_TRUNC) {
40003ede:	8b 45 10             	mov    0x10(%ebp),%eax
40003ee1:	83 e0 40             	and    $0x40,%eax
40003ee4:	85 c0                	test   %eax,%eax
40003ee6:	74 5c                	je     40003f44 <filedesc_open+0x195>
		if (!(openflags & O_WRONLY)) {
40003ee8:	8b 45 10             	mov    0x10(%ebp),%eax
40003eeb:	83 e0 02             	and    $0x2,%eax
40003eee:	85 c0                	test   %eax,%eax
40003ef0:	75 31                	jne    40003f23 <filedesc_open+0x174>
			warn("filedesc_open: can't truncate non-writable file");
40003ef2:	c7 44 24 08 f4 81 00 	movl   $0x400081f4,0x8(%esp)
40003ef9:	40 
40003efa:	c7 44 24 04 17 01 00 	movl   $0x117,0x4(%esp)
40003f01:	00 
40003f02:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
40003f09:	e8 40 e7 ff ff       	call   4000264e <debug_warn>
			errno = EINVAL;
40003f0e:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40003f13:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
			return NULL;
40003f19:	b8 00 00 00 00       	mov    $0x0,%eax
40003f1e:	e9 b4 00 00 00       	jmp    40003fd7 <filedesc_open+0x228>
		}
		if (fileino_truncate(ino, 0) < 0)
40003f23:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40003f2a:	00 
40003f2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003f2e:	89 04 24             	mov    %eax,(%esp)
40003f31:	e8 2c fb ff ff       	call   40003a62 <fileino_truncate>
40003f36:	85 c0                	test   %eax,%eax
40003f38:	79 0a                	jns    40003f44 <filedesc_open+0x195>
			return NULL;
40003f3a:	b8 00 00 00 00       	mov    $0x0,%eax
40003f3f:	e9 93 00 00 00       	jmp    40003fd7 <filedesc_open+0x228>
	}

	// Initialize the file descriptor
	fd->ino = ino;
40003f44:	8b 45 08             	mov    0x8(%ebp),%eax
40003f47:	8b 55 f0             	mov    -0x10(%ebp),%edx
40003f4a:	89 10                	mov    %edx,(%eax)
	fd->flags = openflags;
40003f4c:	8b 45 08             	mov    0x8(%ebp),%eax
40003f4f:	8b 55 10             	mov    0x10(%ebp),%edx
40003f52:	89 50 04             	mov    %edx,0x4(%eax)
	fd->ofs = (openflags & O_APPEND) ? files->fi[ino].size : 0;
40003f55:	8b 45 10             	mov    0x10(%ebp),%eax
40003f58:	83 e0 10             	and    $0x10,%eax
40003f5b:	85 c0                	test   %eax,%eax
40003f5d:	74 17                	je     40003f76 <filedesc_open+0x1c7>
40003f5f:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40003f65:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003f68:	6b c0 5c             	imul   $0x5c,%eax,%eax
40003f6b:	01 d0                	add    %edx,%eax
40003f6d:	05 5c 10 00 00       	add    $0x105c,%eax
40003f72:	8b 00                	mov    (%eax),%eax
40003f74:	eb 05                	jmp    40003f7b <filedesc_open+0x1cc>
40003f76:	b8 00 00 00 00       	mov    $0x0,%eax
40003f7b:	8b 55 08             	mov    0x8(%ebp),%edx
40003f7e:	89 42 08             	mov    %eax,0x8(%edx)
	fd->err = 0;
40003f81:	8b 45 08             	mov    0x8(%ebp),%eax
40003f84:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)

	assert(filedesc_isopen(fd));
40003f8b:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40003f90:	83 c0 10             	add    $0x10,%eax
40003f93:	3b 45 08             	cmp    0x8(%ebp),%eax
40003f96:	77 18                	ja     40003fb0 <filedesc_open+0x201>
40003f98:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40003f9d:	05 10 10 00 00       	add    $0x1010,%eax
40003fa2:	3b 45 08             	cmp    0x8(%ebp),%eax
40003fa5:	76 09                	jbe    40003fb0 <filedesc_open+0x201>
40003fa7:	8b 45 08             	mov    0x8(%ebp),%eax
40003faa:	8b 00                	mov    (%eax),%eax
40003fac:	85 c0                	test   %eax,%eax
40003fae:	75 24                	jne    40003fd4 <filedesc_open+0x225>
40003fb0:	c7 44 24 0c 24 82 00 	movl   $0x40008224,0xc(%esp)
40003fb7:	40 
40003fb8:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
40003fbf:	40 
40003fc0:	c7 44 24 04 25 01 00 	movl   $0x125,0x4(%esp)
40003fc7:	00 
40003fc8:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
40003fcf:	e8 10 e6 ff ff       	call   400025e4 <debug_panic>
	return fd;
40003fd4:	8b 45 08             	mov    0x8(%ebp),%eax
}
40003fd7:	c9                   	leave  
40003fd8:	c3                   	ret    

40003fd9 <filedesc_read>:
// If the file is a special device input file such as the console,
// this function pretends the file has no end and instead
// uses sys_ret() to wait for the file to extend the special file.
ssize_t
filedesc_read(filedesc *fd, void *buf, size_t eltsize, size_t count)
{
40003fd9:	55                   	push   %ebp
40003fda:	89 e5                	mov    %esp,%ebp
40003fdc:	83 ec 38             	sub    $0x38,%esp
	assert(filedesc_isreadable(fd));
40003fdf:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40003fe4:	83 c0 10             	add    $0x10,%eax
40003fe7:	3b 45 08             	cmp    0x8(%ebp),%eax
40003fea:	77 25                	ja     40004011 <filedesc_read+0x38>
40003fec:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40003ff1:	05 10 10 00 00       	add    $0x1010,%eax
40003ff6:	3b 45 08             	cmp    0x8(%ebp),%eax
40003ff9:	76 16                	jbe    40004011 <filedesc_read+0x38>
40003ffb:	8b 45 08             	mov    0x8(%ebp),%eax
40003ffe:	8b 00                	mov    (%eax),%eax
40004000:	85 c0                	test   %eax,%eax
40004002:	74 0d                	je     40004011 <filedesc_read+0x38>
40004004:	8b 45 08             	mov    0x8(%ebp),%eax
40004007:	8b 40 04             	mov    0x4(%eax),%eax
4000400a:	83 e0 01             	and    $0x1,%eax
4000400d:	85 c0                	test   %eax,%eax
4000400f:	75 24                	jne    40004035 <filedesc_read+0x5c>
40004011:	c7 44 24 0c 38 82 00 	movl   $0x40008238,0xc(%esp)
40004018:	40 
40004019:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
40004020:	40 
40004021:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
40004028:	00 
40004029:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
40004030:	e8 af e5 ff ff       	call   400025e4 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40004035:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
4000403b:	8b 45 08             	mov    0x8(%ebp),%eax
4000403e:	8b 00                	mov    (%eax),%eax
40004040:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004043:	05 10 10 00 00       	add    $0x1010,%eax
40004048:	01 d0                	add    %edx,%eax
4000404a:	89 45 f4             	mov    %eax,-0xc(%ebp)

	ssize_t actual = fileino_read(fd->ino, fd->ofs, buf, eltsize, count);
4000404d:	8b 45 08             	mov    0x8(%ebp),%eax
40004050:	8b 50 08             	mov    0x8(%eax),%edx
40004053:	8b 45 08             	mov    0x8(%ebp),%eax
40004056:	8b 00                	mov    (%eax),%eax
40004058:	8b 4d 14             	mov    0x14(%ebp),%ecx
4000405b:	89 4c 24 10          	mov    %ecx,0x10(%esp)
4000405f:	8b 4d 10             	mov    0x10(%ebp),%ecx
40004062:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
40004066:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40004069:	89 4c 24 08          	mov    %ecx,0x8(%esp)
4000406d:	89 54 24 04          	mov    %edx,0x4(%esp)
40004071:	89 04 24             	mov    %eax,(%esp)
40004074:	e8 93 f4 ff ff       	call   4000350c <fileino_read>
40004079:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (actual < 0) {
4000407c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40004080:	79 14                	jns    40004096 <filedesc_read+0xbd>
		fd->err = errno;	// save error indication for ferror()
40004082:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004087:	8b 10                	mov    (%eax),%edx
40004089:	8b 45 08             	mov    0x8(%ebp),%eax
4000408c:	89 50 0c             	mov    %edx,0xc(%eax)
		return -1;
4000408f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40004094:	eb 56                	jmp    400040ec <filedesc_read+0x113>
	}

	// Advance the file position
	fd->ofs += eltsize * actual;
40004096:	8b 45 08             	mov    0x8(%ebp),%eax
40004099:	8b 40 08             	mov    0x8(%eax),%eax
4000409c:	89 c2                	mov    %eax,%edx
4000409e:	8b 45 f0             	mov    -0x10(%ebp),%eax
400040a1:	0f af 45 10          	imul   0x10(%ebp),%eax
400040a5:	01 d0                	add    %edx,%eax
400040a7:	89 c2                	mov    %eax,%edx
400040a9:	8b 45 08             	mov    0x8(%ebp),%eax
400040ac:	89 50 08             	mov    %edx,0x8(%eax)
	assert(actual == 0 || fi->size >= fd->ofs);
400040af:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400040b3:	74 34                	je     400040e9 <filedesc_read+0x110>
400040b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
400040b8:	8b 50 4c             	mov    0x4c(%eax),%edx
400040bb:	8b 45 08             	mov    0x8(%ebp),%eax
400040be:	8b 40 08             	mov    0x8(%eax),%eax
400040c1:	39 c2                	cmp    %eax,%edx
400040c3:	73 24                	jae    400040e9 <filedesc_read+0x110>
400040c5:	c7 44 24 0c 50 82 00 	movl   $0x40008250,0xc(%esp)
400040cc:	40 
400040cd:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
400040d4:	40 
400040d5:	c7 44 24 04 42 01 00 	movl   $0x142,0x4(%esp)
400040dc:	00 
400040dd:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
400040e4:	e8 fb e4 ff ff       	call   400025e4 <debug_panic>

	return actual;
400040e9:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
400040ec:	c9                   	leave  
400040ed:	c3                   	ret    

400040ee <filedesc_write>:
// The size of 'buf' must be at least 'count * eltsize' bytes.
// On success, returns the number of objects written (NOT the number of bytes).
// If an error occurs, returns -1 and sets errno appropriately.
ssize_t
filedesc_write(filedesc *fd, const void *buf, size_t eltsize, size_t count)
{
400040ee:	55                   	push   %ebp
400040ef:	89 e5                	mov    %esp,%ebp
400040f1:	83 ec 38             	sub    $0x38,%esp
	assert(filedesc_iswritable(fd));
400040f4:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400040f9:	83 c0 10             	add    $0x10,%eax
400040fc:	3b 45 08             	cmp    0x8(%ebp),%eax
400040ff:	77 25                	ja     40004126 <filedesc_write+0x38>
40004101:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004106:	05 10 10 00 00       	add    $0x1010,%eax
4000410b:	3b 45 08             	cmp    0x8(%ebp),%eax
4000410e:	76 16                	jbe    40004126 <filedesc_write+0x38>
40004110:	8b 45 08             	mov    0x8(%ebp),%eax
40004113:	8b 00                	mov    (%eax),%eax
40004115:	85 c0                	test   %eax,%eax
40004117:	74 0d                	je     40004126 <filedesc_write+0x38>
40004119:	8b 45 08             	mov    0x8(%ebp),%eax
4000411c:	8b 40 04             	mov    0x4(%eax),%eax
4000411f:	83 e0 02             	and    $0x2,%eax
40004122:	85 c0                	test   %eax,%eax
40004124:	75 24                	jne    4000414a <filedesc_write+0x5c>
40004126:	c7 44 24 0c 73 82 00 	movl   $0x40008273,0xc(%esp)
4000412d:	40 
4000412e:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
40004135:	40 
40004136:	c7 44 24 04 4f 01 00 	movl   $0x14f,0x4(%esp)
4000413d:	00 
4000413e:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
40004145:	e8 9a e4 ff ff       	call   400025e4 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
4000414a:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40004150:	8b 45 08             	mov    0x8(%ebp),%eax
40004153:	8b 00                	mov    (%eax),%eax
40004155:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004158:	05 10 10 00 00       	add    $0x1010,%eax
4000415d:	01 d0                	add    %edx,%eax
4000415f:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// If we're appending to the file, seek to the end first.
	if (fd->flags & O_APPEND)
40004162:	8b 45 08             	mov    0x8(%ebp),%eax
40004165:	8b 40 04             	mov    0x4(%eax),%eax
40004168:	83 e0 10             	and    $0x10,%eax
4000416b:	85 c0                	test   %eax,%eax
4000416d:	74 0e                	je     4000417d <filedesc_write+0x8f>
		fd->ofs = fi->size;
4000416f:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004172:	8b 40 4c             	mov    0x4c(%eax),%eax
40004175:	89 c2                	mov    %eax,%edx
40004177:	8b 45 08             	mov    0x8(%ebp),%eax
4000417a:	89 50 08             	mov    %edx,0x8(%eax)

	// Write the data, growing the file as necessary.
	ssize_t actual = fileino_write(fd->ino, fd->ofs, buf, eltsize, count);
4000417d:	8b 45 08             	mov    0x8(%ebp),%eax
40004180:	8b 50 08             	mov    0x8(%eax),%edx
40004183:	8b 45 08             	mov    0x8(%ebp),%eax
40004186:	8b 00                	mov    (%eax),%eax
40004188:	8b 4d 14             	mov    0x14(%ebp),%ecx
4000418b:	89 4c 24 10          	mov    %ecx,0x10(%esp)
4000418f:	8b 4d 10             	mov    0x10(%ebp),%ecx
40004192:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
40004196:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40004199:	89 4c 24 08          	mov    %ecx,0x8(%esp)
4000419d:	89 54 24 04          	mov    %edx,0x4(%esp)
400041a1:	89 04 24             	mov    %eax,(%esp)
400041a4:	e8 f9 f4 ff ff       	call   400036a2 <fileino_write>
400041a9:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (actual < 0) {
400041ac:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400041b0:	79 17                	jns    400041c9 <filedesc_write+0xdb>
		fd->err = errno;	// save error indication for ferror()
400041b2:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400041b7:	8b 10                	mov    (%eax),%edx
400041b9:	8b 45 08             	mov    0x8(%ebp),%eax
400041bc:	89 50 0c             	mov    %edx,0xc(%eax)
		return -1;
400041bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400041c4:	e9 98 00 00 00       	jmp    40004261 <filedesc_write+0x173>
	}
	assert(actual == count);
400041c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
400041cc:	3b 45 14             	cmp    0x14(%ebp),%eax
400041cf:	74 24                	je     400041f5 <filedesc_write+0x107>
400041d1:	c7 44 24 0c 8b 82 00 	movl   $0x4000828b,0xc(%esp)
400041d8:	40 
400041d9:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
400041e0:	40 
400041e1:	c7 44 24 04 5c 01 00 	movl   $0x15c,0x4(%esp)
400041e8:	00 
400041e9:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
400041f0:	e8 ef e3 ff ff       	call   400025e4 <debug_panic>

	// Non-append-only writes constitute exclusive modifications,
	// so must bump the file's version number.
	if (!(fd->flags & O_APPEND))
400041f5:	8b 45 08             	mov    0x8(%ebp),%eax
400041f8:	8b 40 04             	mov    0x4(%eax),%eax
400041fb:	83 e0 10             	and    $0x10,%eax
400041fe:	85 c0                	test   %eax,%eax
40004200:	75 0f                	jne    40004211 <filedesc_write+0x123>
		fi->ver++;
40004202:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004205:	8b 40 44             	mov    0x44(%eax),%eax
40004208:	8d 50 01             	lea    0x1(%eax),%edx
4000420b:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000420e:	89 50 44             	mov    %edx,0x44(%eax)

	// Advance the file position
	fd->ofs += eltsize * count;
40004211:	8b 45 08             	mov    0x8(%ebp),%eax
40004214:	8b 40 08             	mov    0x8(%eax),%eax
40004217:	89 c2                	mov    %eax,%edx
40004219:	8b 45 10             	mov    0x10(%ebp),%eax
4000421c:	0f af 45 14          	imul   0x14(%ebp),%eax
40004220:	01 d0                	add    %edx,%eax
40004222:	89 c2                	mov    %eax,%edx
40004224:	8b 45 08             	mov    0x8(%ebp),%eax
40004227:	89 50 08             	mov    %edx,0x8(%eax)
	assert(fi->size >= fd->ofs);
4000422a:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000422d:	8b 50 4c             	mov    0x4c(%eax),%edx
40004230:	8b 45 08             	mov    0x8(%ebp),%eax
40004233:	8b 40 08             	mov    0x8(%eax),%eax
40004236:	39 c2                	cmp    %eax,%edx
40004238:	73 24                	jae    4000425e <filedesc_write+0x170>
4000423a:	c7 44 24 0c 9b 82 00 	movl   $0x4000829b,0xc(%esp)
40004241:	40 
40004242:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
40004249:	40 
4000424a:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
40004251:	00 
40004252:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
40004259:	e8 86 e3 ff ff       	call   400025e4 <debug_panic>
	return count;
4000425e:	8b 45 14             	mov    0x14(%ebp),%eax
}
40004261:	c9                   	leave  
40004262:	c3                   	ret    

40004263 <filedesc_seek>:
// which may be relative to the file start, end, or corrent position,
// depending on 'whence' (SEEK_SET, SEEK_CUR, or SEEK_END).
// Returns the resulting absolute file position,
// or returns -1 and sets errno appropriately on error.
off_t filedesc_seek(filedesc *fd, off_t offset, int whence)
{
40004263:	55                   	push   %ebp
40004264:	89 e5                	mov    %esp,%ebp
40004266:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isopen(fd));
40004269:	a1 8c 80 00 40       	mov    0x4000808c,%eax
4000426e:	83 c0 10             	add    $0x10,%eax
40004271:	3b 45 08             	cmp    0x8(%ebp),%eax
40004274:	77 18                	ja     4000428e <filedesc_seek+0x2b>
40004276:	a1 8c 80 00 40       	mov    0x4000808c,%eax
4000427b:	05 10 10 00 00       	add    $0x1010,%eax
40004280:	3b 45 08             	cmp    0x8(%ebp),%eax
40004283:	76 09                	jbe    4000428e <filedesc_seek+0x2b>
40004285:	8b 45 08             	mov    0x8(%ebp),%eax
40004288:	8b 00                	mov    (%eax),%eax
4000428a:	85 c0                	test   %eax,%eax
4000428c:	75 24                	jne    400042b2 <filedesc_seek+0x4f>
4000428e:	c7 44 24 0c 24 82 00 	movl   $0x40008224,0xc(%esp)
40004295:	40 
40004296:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
4000429d:	40 
4000429e:	c7 44 24 04 70 01 00 	movl   $0x170,0x4(%esp)
400042a5:	00 
400042a6:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
400042ad:	e8 32 e3 ff ff       	call   400025e4 <debug_panic>
	assert(whence == SEEK_SET || whence == SEEK_CUR || whence == SEEK_END);
400042b2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400042b6:	74 30                	je     400042e8 <filedesc_seek+0x85>
400042b8:	83 7d 10 01          	cmpl   $0x1,0x10(%ebp)
400042bc:	74 2a                	je     400042e8 <filedesc_seek+0x85>
400042be:	83 7d 10 02          	cmpl   $0x2,0x10(%ebp)
400042c2:	74 24                	je     400042e8 <filedesc_seek+0x85>
400042c4:	c7 44 24 0c b0 82 00 	movl   $0x400082b0,0xc(%esp)
400042cb:	40 
400042cc:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
400042d3:	40 
400042d4:	c7 44 24 04 71 01 00 	movl   $0x171,0x4(%esp)
400042db:	00 
400042dc:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
400042e3:	e8 fc e2 ff ff       	call   400025e4 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
400042e8:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
400042ee:	8b 45 08             	mov    0x8(%ebp),%eax
400042f1:	8b 00                	mov    (%eax),%eax
400042f3:	6b c0 5c             	imul   $0x5c,%eax,%eax
400042f6:	05 10 10 00 00       	add    $0x1010,%eax
400042fb:	01 d0                	add    %edx,%eax
400042fd:	89 45 f4             	mov    %eax,-0xc(%ebp)
	ino_t ino = fd->ino;
40004300:	8b 45 08             	mov    0x8(%ebp),%eax
40004303:	8b 00                	mov    (%eax),%eax
40004305:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint8_t* start_pos = FILEDATA(ino);
40004308:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000430b:	c1 e0 16             	shl    $0x16,%eax
4000430e:	05 00 00 00 80       	add    $0x80000000,%eax
40004313:	89 45 ec             	mov    %eax,-0x14(%ebp)

	// Lab 4: insert your file descriptor seek implementation here.
	//warn("filedesc_seek() not implemented");
	//errno = EINVAL;
	//return -1;
	switch(whence){
40004316:	8b 45 10             	mov    0x10(%ebp),%eax
40004319:	83 f8 01             	cmp    $0x1,%eax
4000431c:	74 14                	je     40004332 <filedesc_seek+0xcf>
4000431e:	83 f8 02             	cmp    $0x2,%eax
40004321:	74 22                	je     40004345 <filedesc_seek+0xe2>
40004323:	85 c0                	test   %eax,%eax
40004325:	75 33                	jne    4000435a <filedesc_seek+0xf7>
	case SEEK_SET:
		fd->ofs = offset;
40004327:	8b 45 08             	mov    0x8(%ebp),%eax
4000432a:	8b 55 0c             	mov    0xc(%ebp),%edx
4000432d:	89 50 08             	mov    %edx,0x8(%eax)
		break;
40004330:	eb 3a                	jmp    4000436c <filedesc_seek+0x109>
	case SEEK_CUR:
		fd->ofs += offset;
40004332:	8b 45 08             	mov    0x8(%ebp),%eax
40004335:	8b 50 08             	mov    0x8(%eax),%edx
40004338:	8b 45 0c             	mov    0xc(%ebp),%eax
4000433b:	01 c2                	add    %eax,%edx
4000433d:	8b 45 08             	mov    0x8(%ebp),%eax
40004340:	89 50 08             	mov    %edx,0x8(%eax)
		break;
40004343:	eb 27                	jmp    4000436c <filedesc_seek+0x109>
	case SEEK_END:
		fd->ofs = (fi->size) + offset;
40004345:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004348:	8b 50 4c             	mov    0x4c(%eax),%edx
4000434b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000434e:	01 d0                	add    %edx,%eax
40004350:	89 c2                	mov    %eax,%edx
40004352:	8b 45 08             	mov    0x8(%ebp),%eax
40004355:	89 50 08             	mov    %edx,0x8(%eax)
		break;
40004358:	eb 12                	jmp    4000436c <filedesc_seek+0x109>
	default:
		errno = EINVAL;
4000435a:	a1 8c 80 00 40       	mov    0x4000808c,%eax
4000435f:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
		return -1;
40004365:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
4000436a:	eb 06                	jmp    40004372 <filedesc_seek+0x10f>
	}
	return fd->ofs;
4000436c:	8b 45 08             	mov    0x8(%ebp),%eax
4000436f:	8b 40 08             	mov    0x8(%eax),%eax
}
40004372:	c9                   	leave  
40004373:	c3                   	ret    

40004374 <filedesc_close>:

void
filedesc_close(filedesc *fd)
{
40004374:	55                   	push   %ebp
40004375:	89 e5                	mov    %esp,%ebp
40004377:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
4000437a:	a1 8c 80 00 40       	mov    0x4000808c,%eax
4000437f:	83 c0 10             	add    $0x10,%eax
40004382:	3b 45 08             	cmp    0x8(%ebp),%eax
40004385:	77 18                	ja     4000439f <filedesc_close+0x2b>
40004387:	a1 8c 80 00 40       	mov    0x4000808c,%eax
4000438c:	05 10 10 00 00       	add    $0x1010,%eax
40004391:	3b 45 08             	cmp    0x8(%ebp),%eax
40004394:	76 09                	jbe    4000439f <filedesc_close+0x2b>
40004396:	8b 45 08             	mov    0x8(%ebp),%eax
40004399:	8b 00                	mov    (%eax),%eax
4000439b:	85 c0                	test   %eax,%eax
4000439d:	75 24                	jne    400043c3 <filedesc_close+0x4f>
4000439f:	c7 44 24 0c 24 82 00 	movl   $0x40008224,0xc(%esp)
400043a6:	40 
400043a7:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
400043ae:	40 
400043af:	c7 44 24 04 8e 01 00 	movl   $0x18e,0x4(%esp)
400043b6:	00 
400043b7:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
400043be:	e8 21 e2 ff ff       	call   400025e4 <debug_panic>
	assert(fileino_isvalid(fd->ino));
400043c3:	8b 45 08             	mov    0x8(%ebp),%eax
400043c6:	8b 00                	mov    (%eax),%eax
400043c8:	85 c0                	test   %eax,%eax
400043ca:	7e 0c                	jle    400043d8 <filedesc_close+0x64>
400043cc:	8b 45 08             	mov    0x8(%ebp),%eax
400043cf:	8b 00                	mov    (%eax),%eax
400043d1:	3d ff 00 00 00       	cmp    $0xff,%eax
400043d6:	7e 24                	jle    400043fc <filedesc_close+0x88>
400043d8:	c7 44 24 0c ef 82 00 	movl   $0x400082ef,0xc(%esp)
400043df:	40 
400043e0:	c7 44 24 08 c4 80 00 	movl   $0x400080c4,0x8(%esp)
400043e7:	40 
400043e8:	c7 44 24 04 8f 01 00 	movl   $0x18f,0x4(%esp)
400043ef:	00 
400043f0:	c7 04 24 af 80 00 40 	movl   $0x400080af,(%esp)
400043f7:	e8 e8 e1 ff ff       	call   400025e4 <debug_panic>

	fd->ino = FILEINO_NULL;		// mark the fd free
400043fc:	8b 45 08             	mov    0x8(%ebp),%eax
400043ff:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
40004405:	c9                   	leave  
40004406:	c3                   	ret    
40004407:	90                   	nop

40004408 <dir_walk>:
#include <inc/dirent.h>


int
dir_walk(const char *path, mode_t createmode)
{
40004408:	55                   	push   %ebp
40004409:	89 e5                	mov    %esp,%ebp
4000440b:	83 ec 28             	sub    $0x28,%esp
	assert(path != 0 && *path != 0);
4000440e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40004412:	74 0a                	je     4000441e <dir_walk+0x16>
40004414:	8b 45 08             	mov    0x8(%ebp),%eax
40004417:	0f b6 00             	movzbl (%eax),%eax
4000441a:	84 c0                	test   %al,%al
4000441c:	75 24                	jne    40004442 <dir_walk+0x3a>
4000441e:	c7 44 24 0c 08 83 00 	movl   $0x40008308,0xc(%esp)
40004425:	40 
40004426:	c7 44 24 08 20 83 00 	movl   $0x40008320,0x8(%esp)
4000442d:	40 
4000442e:	c7 44 24 04 15 00 00 	movl   $0x15,0x4(%esp)
40004435:	00 
40004436:	c7 04 24 35 83 00 40 	movl   $0x40008335,(%esp)
4000443d:	e8 a2 e1 ff ff       	call   400025e4 <debug_panic>

	// Start at the current or root directory as appropriate
	int dino = files->cwd;
40004442:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004447:	8b 40 04             	mov    0x4(%eax),%eax
4000444a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (*path == '/') {
4000444d:	8b 45 08             	mov    0x8(%ebp),%eax
40004450:	0f b6 00             	movzbl (%eax),%eax
40004453:	3c 2f                	cmp    $0x2f,%al
40004455:	75 27                	jne    4000447e <dir_walk+0x76>
		dino = FILEINO_ROOTDIR;
40004457:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
		do { path++; } while (*path == '/');	// skip leading slashes
4000445e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40004462:	8b 45 08             	mov    0x8(%ebp),%eax
40004465:	0f b6 00             	movzbl (%eax),%eax
40004468:	3c 2f                	cmp    $0x2f,%al
4000446a:	74 f2                	je     4000445e <dir_walk+0x56>
		if (*path == 0)
4000446c:	8b 45 08             	mov    0x8(%ebp),%eax
4000446f:	0f b6 00             	movzbl (%eax),%eax
40004472:	84 c0                	test   %al,%al
40004474:	75 08                	jne    4000447e <dir_walk+0x76>
			return dino;	// Just looking up root directory
40004476:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004479:	e9 61 05 00 00       	jmp    400049df <dir_walk+0x5d7>
	}

	// Search for the appropriate entry in this directory
	searchdir:
	assert(fileino_isdir(dino));
4000447e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40004482:	7e 45                	jle    400044c9 <dir_walk+0xc1>
40004484:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
4000448b:	7f 3c                	jg     400044c9 <dir_walk+0xc1>
4000448d:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40004493:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004496:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004499:	01 d0                	add    %edx,%eax
4000449b:	05 10 10 00 00       	add    $0x1010,%eax
400044a0:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400044a4:	84 c0                	test   %al,%al
400044a6:	74 21                	je     400044c9 <dir_walk+0xc1>
400044a8:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
400044ae:	8b 45 f4             	mov    -0xc(%ebp),%eax
400044b1:	6b c0 5c             	imul   $0x5c,%eax,%eax
400044b4:	01 d0                	add    %edx,%eax
400044b6:	05 58 10 00 00       	add    $0x1058,%eax
400044bb:	8b 00                	mov    (%eax),%eax
400044bd:	25 00 70 00 00       	and    $0x7000,%eax
400044c2:	3d 00 20 00 00       	cmp    $0x2000,%eax
400044c7:	74 24                	je     400044ed <dir_walk+0xe5>
400044c9:	c7 44 24 0c 3f 83 00 	movl   $0x4000833f,0xc(%esp)
400044d0:	40 
400044d1:	c7 44 24 08 20 83 00 	movl   $0x40008320,0x8(%esp)
400044d8:	40 
400044d9:	c7 44 24 04 22 00 00 	movl   $0x22,0x4(%esp)
400044e0:	00 
400044e1:	c7 04 24 35 83 00 40 	movl   $0x40008335,(%esp)
400044e8:	e8 f7 e0 ff ff       	call   400025e4 <debug_panic>
	assert(fileino_isdir(files->fi[dino].dino));
400044ed:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
400044f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
400044f6:	6b c0 5c             	imul   $0x5c,%eax,%eax
400044f9:	01 d0                	add    %edx,%eax
400044fb:	05 10 10 00 00       	add    $0x1010,%eax
40004500:	8b 00                	mov    (%eax),%eax
40004502:	85 c0                	test   %eax,%eax
40004504:	7e 7c                	jle    40004582 <dir_walk+0x17a>
40004506:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
4000450c:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000450f:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004512:	01 d0                	add    %edx,%eax
40004514:	05 10 10 00 00       	add    $0x1010,%eax
40004519:	8b 00                	mov    (%eax),%eax
4000451b:	3d ff 00 00 00       	cmp    $0xff,%eax
40004520:	7f 60                	jg     40004582 <dir_walk+0x17a>
40004522:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40004528:	8b 0d 8c 80 00 40    	mov    0x4000808c,%ecx
4000452e:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004531:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004534:	01 c8                	add    %ecx,%eax
40004536:	05 10 10 00 00       	add    $0x1010,%eax
4000453b:	8b 00                	mov    (%eax),%eax
4000453d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004540:	01 d0                	add    %edx,%eax
40004542:	05 10 10 00 00       	add    $0x1010,%eax
40004547:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000454b:	84 c0                	test   %al,%al
4000454d:	74 33                	je     40004582 <dir_walk+0x17a>
4000454f:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40004555:	8b 0d 8c 80 00 40    	mov    0x4000808c,%ecx
4000455b:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000455e:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004561:	01 c8                	add    %ecx,%eax
40004563:	05 10 10 00 00       	add    $0x1010,%eax
40004568:	8b 00                	mov    (%eax),%eax
4000456a:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000456d:	01 d0                	add    %edx,%eax
4000456f:	05 58 10 00 00       	add    $0x1058,%eax
40004574:	8b 00                	mov    (%eax),%eax
40004576:	25 00 70 00 00       	and    $0x7000,%eax
4000457b:	3d 00 20 00 00       	cmp    $0x2000,%eax
40004580:	74 24                	je     400045a6 <dir_walk+0x19e>
40004582:	c7 44 24 0c 54 83 00 	movl   $0x40008354,0xc(%esp)
40004589:	40 
4000458a:	c7 44 24 08 20 83 00 	movl   $0x40008320,0x8(%esp)
40004591:	40 
40004592:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
40004599:	00 
4000459a:	c7 04 24 35 83 00 40 	movl   $0x40008335,(%esp)
400045a1:	e8 3e e0 ff ff       	call   400025e4 <debug_panic>

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
400045a6:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
400045ad:	e9 3d 02 00 00       	jmp    400047ef <dir_walk+0x3e7>
		if (!fileino_alloced(ino) || files->fi[ino].dino != dino)
400045b2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400045b6:	0f 8e 28 02 00 00    	jle    400047e4 <dir_walk+0x3dc>
400045bc:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
400045c3:	0f 8f 1b 02 00 00    	jg     400047e4 <dir_walk+0x3dc>
400045c9:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
400045cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
400045d2:	6b c0 5c             	imul   $0x5c,%eax,%eax
400045d5:	01 d0                	add    %edx,%eax
400045d7:	05 10 10 00 00       	add    $0x1010,%eax
400045dc:	0f b6 40 04          	movzbl 0x4(%eax),%eax
400045e0:	84 c0                	test   %al,%al
400045e2:	0f 84 fc 01 00 00    	je     400047e4 <dir_walk+0x3dc>
400045e8:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
400045ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
400045f1:	6b c0 5c             	imul   $0x5c,%eax,%eax
400045f4:	01 d0                	add    %edx,%eax
400045f6:	05 10 10 00 00       	add    $0x1010,%eax
400045fb:	8b 00                	mov    (%eax),%eax
400045fd:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40004600:	0f 85 de 01 00 00    	jne    400047e4 <dir_walk+0x3dc>
			continue;	// not an entry in directory 'dino'

		// Does this inode's name match our next path component?
		len = strlen(files->fi[ino].de.d_name);
40004606:	a1 8c 80 00 40       	mov    0x4000808c,%eax
4000460b:	8b 55 f0             	mov    -0x10(%ebp),%edx
4000460e:	6b d2 5c             	imul   $0x5c,%edx,%edx
40004611:	81 c2 10 10 00 00    	add    $0x1010,%edx
40004617:	01 d0                	add    %edx,%eax
40004619:	83 c0 04             	add    $0x4,%eax
4000461c:	89 04 24             	mov    %eax,(%esp)
4000461f:	e8 34 e9 ff ff       	call   40002f58 <strlen>
40004624:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (memcmp(path, files->fi[ino].de.d_name, len) != 0)
40004627:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000462a:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40004630:	8b 4d f0             	mov    -0x10(%ebp),%ecx
40004633:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
40004636:	81 c1 10 10 00 00    	add    $0x1010,%ecx
4000463c:	01 ca                	add    %ecx,%edx
4000463e:	83 c2 04             	add    $0x4,%edx
40004641:	89 44 24 08          	mov    %eax,0x8(%esp)
40004645:	89 54 24 04          	mov    %edx,0x4(%esp)
40004649:	8b 45 08             	mov    0x8(%ebp),%eax
4000464c:	89 04 24             	mov    %eax,(%esp)
4000464f:	e8 2a ec ff ff       	call   4000327e <memcmp>
40004654:	85 c0                	test   %eax,%eax
40004656:	0f 85 8b 01 00 00    	jne    400047e7 <dir_walk+0x3df>
			continue;	// no match
		found:
		if (path[len] == 0) {
4000465c:	8b 55 ec             	mov    -0x14(%ebp),%edx
4000465f:	8b 45 08             	mov    0x8(%ebp),%eax
40004662:	01 d0                	add    %edx,%eax
40004664:	0f b6 00             	movzbl (%eax),%eax
40004667:	84 c0                	test   %al,%al
40004669:	0f 85 c7 00 00 00    	jne    40004736 <dir_walk+0x32e>
			// Exact match at end of path - but does it exist?
			if (fileino_exists(ino))
4000466f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40004673:	7e 45                	jle    400046ba <dir_walk+0x2b2>
40004675:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
4000467c:	7f 3c                	jg     400046ba <dir_walk+0x2b2>
4000467e:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40004684:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004687:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000468a:	01 d0                	add    %edx,%eax
4000468c:	05 10 10 00 00       	add    $0x1010,%eax
40004691:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004695:	84 c0                	test   %al,%al
40004697:	74 21                	je     400046ba <dir_walk+0x2b2>
40004699:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
4000469f:	8b 45 f0             	mov    -0x10(%ebp),%eax
400046a2:	6b c0 5c             	imul   $0x5c,%eax,%eax
400046a5:	01 d0                	add    %edx,%eax
400046a7:	05 58 10 00 00       	add    $0x1058,%eax
400046ac:	8b 00                	mov    (%eax),%eax
400046ae:	85 c0                	test   %eax,%eax
400046b0:	74 08                	je     400046ba <dir_walk+0x2b2>
				return ino;	// yes - return it
400046b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
400046b5:	e9 25 03 00 00       	jmp    400049df <dir_walk+0x5d7>

			// no - existed, but was deleted.  re-create?
			if (!createmode) {
400046ba:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
400046be:	75 15                	jne    400046d5 <dir_walk+0x2cd>
				errno = ENOENT;
400046c0:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400046c5:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
				return -1;
400046cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400046d0:	e9 0a 03 00 00       	jmp    400049df <dir_walk+0x5d7>
			}
			files->fi[ino].ver++;	// an exclusive change
400046d5:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400046da:	8b 55 f0             	mov    -0x10(%ebp),%edx
400046dd:	6b d2 5c             	imul   $0x5c,%edx,%edx
400046e0:	01 c2                	add    %eax,%edx
400046e2:	81 c2 54 10 00 00    	add    $0x1054,%edx
400046e8:	8b 12                	mov    (%edx),%edx
400046ea:	83 c2 01             	add    $0x1,%edx
400046ed:	8b 4d f0             	mov    -0x10(%ebp),%ecx
400046f0:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
400046f3:	01 c8                	add    %ecx,%eax
400046f5:	05 54 10 00 00       	add    $0x1054,%eax
400046fa:	89 10                	mov    %edx,(%eax)
			files->fi[ino].mode = createmode;
400046fc:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40004702:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004705:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004708:	01 d0                	add    %edx,%eax
4000470a:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
40004710:	8b 45 0c             	mov    0xc(%ebp),%eax
40004713:	89 02                	mov    %eax,(%edx)
			files->fi[ino].size = 0;
40004715:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
4000471b:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000471e:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004721:	01 d0                	add    %edx,%eax
40004723:	05 5c 10 00 00       	add    $0x105c,%eax
40004728:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			return ino;
4000472e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004731:	e9 a9 02 00 00       	jmp    400049df <dir_walk+0x5d7>
		}
		if (path[len] != '/')
40004736:	8b 55 ec             	mov    -0x14(%ebp),%edx
40004739:	8b 45 08             	mov    0x8(%ebp),%eax
4000473c:	01 d0                	add    %edx,%eax
4000473e:	0f b6 00             	movzbl (%eax),%eax
40004741:	3c 2f                	cmp    $0x2f,%al
40004743:	0f 85 a1 00 00 00    	jne    400047ea <dir_walk+0x3e2>
			continue;	// no match

		// Make sure this dirent refers to a directory
		if (!fileino_isdir(ino)) {
40004749:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
4000474d:	7e 45                	jle    40004794 <dir_walk+0x38c>
4000474f:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40004756:	7f 3c                	jg     40004794 <dir_walk+0x38c>
40004758:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
4000475e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004761:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004764:	01 d0                	add    %edx,%eax
40004766:	05 10 10 00 00       	add    $0x1010,%eax
4000476b:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000476f:	84 c0                	test   %al,%al
40004771:	74 21                	je     40004794 <dir_walk+0x38c>
40004773:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40004779:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000477c:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000477f:	01 d0                	add    %edx,%eax
40004781:	05 58 10 00 00       	add    $0x1058,%eax
40004786:	8b 00                	mov    (%eax),%eax
40004788:	25 00 70 00 00       	and    $0x7000,%eax
4000478d:	3d 00 20 00 00       	cmp    $0x2000,%eax
40004792:	74 15                	je     400047a9 <dir_walk+0x3a1>
			errno = ENOTDIR;
40004794:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004799:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
			return -1;
4000479f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400047a4:	e9 36 02 00 00       	jmp    400049df <dir_walk+0x5d7>
		}

		// Skip slashes to find next component
		do { len++; } while (path[len] == '/');
400047a9:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
400047ad:	8b 55 ec             	mov    -0x14(%ebp),%edx
400047b0:	8b 45 08             	mov    0x8(%ebp),%eax
400047b3:	01 d0                	add    %edx,%eax
400047b5:	0f b6 00             	movzbl (%eax),%eax
400047b8:	3c 2f                	cmp    $0x2f,%al
400047ba:	74 ed                	je     400047a9 <dir_walk+0x3a1>
		if (path[len] == 0)
400047bc:	8b 55 ec             	mov    -0x14(%ebp),%edx
400047bf:	8b 45 08             	mov    0x8(%ebp),%eax
400047c2:	01 d0                	add    %edx,%eax
400047c4:	0f b6 00             	movzbl (%eax),%eax
400047c7:	84 c0                	test   %al,%al
400047c9:	75 08                	jne    400047d3 <dir_walk+0x3cb>
			return ino;	// matched directory at end of path
400047cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
400047ce:	e9 0c 02 00 00       	jmp    400049df <dir_walk+0x5d7>

		// Walk the next directory in the path
		dino = ino;
400047d3:	8b 45 f0             	mov    -0x10(%ebp),%eax
400047d6:	89 45 f4             	mov    %eax,-0xc(%ebp)
		path += len;
400047d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
400047dc:	01 45 08             	add    %eax,0x8(%ebp)
		goto searchdir;
400047df:	e9 9a fc ff ff       	jmp    4000447e <dir_walk+0x76>

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
		if (!fileino_alloced(ino) || files->fi[ino].dino != dino)
			continue;	// not an entry in directory 'dino'
400047e4:	90                   	nop
400047e5:	eb 04                	jmp    400047eb <dir_walk+0x3e3>

		// Does this inode's name match our next path component?
		len = strlen(files->fi[ino].de.d_name);
		if (memcmp(path, files->fi[ino].de.d_name, len) != 0)
			continue;	// no match
400047e7:	90                   	nop
400047e8:	eb 01                	jmp    400047eb <dir_walk+0x3e3>
			files->fi[ino].mode = createmode;
			files->fi[ino].size = 0;
			return ino;
		}
		if (path[len] != '/')
			continue;	// no match
400047ea:	90                   	nop
	assert(fileino_isdir(dino));
	assert(fileino_isdir(files->fi[dino].dino));

	// Look for a regular directory entry with a matching name.
	int ino, len;
	for (ino = 1; ino < FILE_INODES; ino++) {
400047eb:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
400047ef:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
400047f6:	0f 8e b6 fd ff ff    	jle    400045b2 <dir_walk+0x1aa>
		path += len;
		goto searchdir;
	}

	// Looking for one of the special entries '.' or '..'?
	if (path[0] == '.' && (path[1] == 0 || path[1] == '/')) {
400047fc:	8b 45 08             	mov    0x8(%ebp),%eax
400047ff:	0f b6 00             	movzbl (%eax),%eax
40004802:	3c 2e                	cmp    $0x2e,%al
40004804:	75 2c                	jne    40004832 <dir_walk+0x42a>
40004806:	8b 45 08             	mov    0x8(%ebp),%eax
40004809:	83 c0 01             	add    $0x1,%eax
4000480c:	0f b6 00             	movzbl (%eax),%eax
4000480f:	84 c0                	test   %al,%al
40004811:	74 0d                	je     40004820 <dir_walk+0x418>
40004813:	8b 45 08             	mov    0x8(%ebp),%eax
40004816:	83 c0 01             	add    $0x1,%eax
40004819:	0f b6 00             	movzbl (%eax),%eax
4000481c:	3c 2f                	cmp    $0x2f,%al
4000481e:	75 12                	jne    40004832 <dir_walk+0x42a>
		len = 1;
40004820:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
		ino = dino;	// just leads to this same directory
40004827:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000482a:	89 45 f0             	mov    %eax,-0x10(%ebp)
		goto found;
4000482d:	e9 2a fe ff ff       	jmp    4000465c <dir_walk+0x254>
	}
	if (path[0] == '.' && path[1] == '.'
40004832:	8b 45 08             	mov    0x8(%ebp),%eax
40004835:	0f b6 00             	movzbl (%eax),%eax
40004838:	3c 2e                	cmp    $0x2e,%al
4000483a:	75 4b                	jne    40004887 <dir_walk+0x47f>
4000483c:	8b 45 08             	mov    0x8(%ebp),%eax
4000483f:	83 c0 01             	add    $0x1,%eax
40004842:	0f b6 00             	movzbl (%eax),%eax
40004845:	3c 2e                	cmp    $0x2e,%al
40004847:	75 3e                	jne    40004887 <dir_walk+0x47f>
			&& (path[2] == 0 || path[2] == '/')) {
40004849:	8b 45 08             	mov    0x8(%ebp),%eax
4000484c:	83 c0 02             	add    $0x2,%eax
4000484f:	0f b6 00             	movzbl (%eax),%eax
40004852:	84 c0                	test   %al,%al
40004854:	74 0d                	je     40004863 <dir_walk+0x45b>
40004856:	8b 45 08             	mov    0x8(%ebp),%eax
40004859:	83 c0 02             	add    $0x2,%eax
4000485c:	0f b6 00             	movzbl (%eax),%eax
4000485f:	3c 2f                	cmp    $0x2f,%al
40004861:	75 24                	jne    40004887 <dir_walk+0x47f>
		len = 2;
40004863:	c7 45 ec 02 00 00 00 	movl   $0x2,-0x14(%ebp)
		ino = files->fi[dino].dino;	// leads to root directory
4000486a:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40004870:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004873:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004876:	01 d0                	add    %edx,%eax
40004878:	05 10 10 00 00       	add    $0x1010,%eax
4000487d:	8b 00                	mov    (%eax),%eax
4000487f:	89 45 f0             	mov    %eax,-0x10(%ebp)
		goto found;
40004882:	e9 d5 fd ff ff       	jmp    4000465c <dir_walk+0x254>
	}

	// Path component not found - see if we should create it
	if (!createmode || strchr(path, '/') != NULL) {
40004887:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
4000488b:	74 17                	je     400048a4 <dir_walk+0x49c>
4000488d:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
40004894:	00 
40004895:	8b 45 08             	mov    0x8(%ebp),%eax
40004898:	89 04 24             	mov    %eax,(%esp)
4000489b:	e8 3d e8 ff ff       	call   400030dd <strchr>
400048a0:	85 c0                	test   %eax,%eax
400048a2:	74 15                	je     400048b9 <dir_walk+0x4b1>
		errno = ENOENT;
400048a4:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400048a9:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
		return -1;
400048af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400048b4:	e9 26 01 00 00       	jmp    400049df <dir_walk+0x5d7>
	}
	if (strlen(path) > NAME_MAX) {
400048b9:	8b 45 08             	mov    0x8(%ebp),%eax
400048bc:	89 04 24             	mov    %eax,(%esp)
400048bf:	e8 94 e6 ff ff       	call   40002f58 <strlen>
400048c4:	83 f8 3f             	cmp    $0x3f,%eax
400048c7:	7e 15                	jle    400048de <dir_walk+0x4d6>
		errno = ENAMETOOLONG;
400048c9:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400048ce:	c7 00 06 00 00 00    	movl   $0x6,(%eax)
		return -1;
400048d4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400048d9:	e9 01 01 00 00       	jmp    400049df <dir_walk+0x5d7>
	}

	// Allocate a new inode and create this entry with the given mode.
	ino = fileino_alloc();
400048de:	e8 31 ea ff ff       	call   40003314 <fileino_alloc>
400048e3:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (ino < 0)
400048e6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400048ea:	79 0a                	jns    400048f6 <dir_walk+0x4ee>
		return -1;
400048ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400048f1:	e9 e9 00 00 00       	jmp    400049df <dir_walk+0x5d7>
	assert(fileino_isvalid(ino) && !fileino_alloced(ino));
400048f6:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
400048fa:	7e 33                	jle    4000492f <dir_walk+0x527>
400048fc:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40004903:	7f 2a                	jg     4000492f <dir_walk+0x527>
40004905:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40004909:	7e 48                	jle    40004953 <dir_walk+0x54b>
4000490b:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
40004912:	7f 3f                	jg     40004953 <dir_walk+0x54b>
40004914:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
4000491a:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000491d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004920:	01 d0                	add    %edx,%eax
40004922:	05 10 10 00 00       	add    $0x1010,%eax
40004927:	0f b6 40 04          	movzbl 0x4(%eax),%eax
4000492b:	84 c0                	test   %al,%al
4000492d:	74 24                	je     40004953 <dir_walk+0x54b>
4000492f:	c7 44 24 0c 78 83 00 	movl   $0x40008378,0xc(%esp)
40004936:	40 
40004937:	c7 44 24 08 20 83 00 	movl   $0x40008320,0x8(%esp)
4000493e:	40 
4000493f:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
40004946:	00 
40004947:	c7 04 24 35 83 00 40 	movl   $0x40008335,(%esp)
4000494e:	e8 91 dc ff ff       	call   400025e4 <debug_panic>
	strcpy(files->fi[ino].de.d_name, path);
40004953:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004958:	8b 55 f0             	mov    -0x10(%ebp),%edx
4000495b:	6b d2 5c             	imul   $0x5c,%edx,%edx
4000495e:	81 c2 10 10 00 00    	add    $0x1010,%edx
40004964:	01 d0                	add    %edx,%eax
40004966:	8d 50 04             	lea    0x4(%eax),%edx
40004969:	8b 45 08             	mov    0x8(%ebp),%eax
4000496c:	89 44 24 04          	mov    %eax,0x4(%esp)
40004970:	89 14 24             	mov    %edx,(%esp)
40004973:	e8 06 e6 ff ff       	call   40002f7e <strcpy>
	files->fi[ino].dino = dino;
40004978:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
4000497e:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004981:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004984:	01 d0                	add    %edx,%eax
40004986:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
4000498c:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000498f:	89 02                	mov    %eax,(%edx)
	files->fi[ino].ver = 0;
40004991:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40004997:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000499a:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000499d:	01 d0                	add    %edx,%eax
4000499f:	05 54 10 00 00       	add    $0x1054,%eax
400049a4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	files->fi[ino].mode = createmode;
400049aa:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
400049b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
400049b3:	6b c0 5c             	imul   $0x5c,%eax,%eax
400049b6:	01 d0                	add    %edx,%eax
400049b8:	8d 90 58 10 00 00    	lea    0x1058(%eax),%edx
400049be:	8b 45 0c             	mov    0xc(%ebp),%eax
400049c1:	89 02                	mov    %eax,(%edx)
	files->fi[ino].size = 0;
400049c3:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
400049c9:	8b 45 f0             	mov    -0x10(%ebp),%eax
400049cc:	6b c0 5c             	imul   $0x5c,%eax,%eax
400049cf:	01 d0                	add    %edx,%eax
400049d1:	05 5c 10 00 00       	add    $0x105c,%eax
400049d6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return ino;
400049dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
400049df:	c9                   	leave  
400049e0:	c3                   	ret    

400049e1 <opendir>:
// Open a directory for scanning.
// For simplicity, DIR is simply a filedesc like other file descriptors,
// except we interpret fd->ofs as an inode number for scanning,
// instead of as a byte offset as in a regular file.
DIR *opendir(const char *path)
{
400049e1:	55                   	push   %ebp
400049e2:	89 e5                	mov    %esp,%ebp
400049e4:	83 ec 28             	sub    $0x28,%esp
	filedesc *fd = filedesc_open(NULL, path, O_RDONLY, 0);
400049e7:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
400049ee:	00 
400049ef:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
400049f6:	00 
400049f7:	8b 45 08             	mov    0x8(%ebp),%eax
400049fa:	89 44 24 04          	mov    %eax,0x4(%esp)
400049fe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40004a05:	e8 a5 f3 ff ff       	call   40003daf <filedesc_open>
40004a0a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (fd == NULL)
40004a0d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40004a11:	75 0a                	jne    40004a1d <opendir+0x3c>
		return NULL;
40004a13:	b8 00 00 00 00       	mov    $0x0,%eax
40004a18:	e9 bb 00 00 00       	jmp    40004ad8 <opendir+0xf7>

	// Make sure it's a directory
	assert(fileino_exists(fd->ino));
40004a1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004a20:	8b 00                	mov    (%eax),%eax
40004a22:	85 c0                	test   %eax,%eax
40004a24:	7e 44                	jle    40004a6a <opendir+0x89>
40004a26:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004a29:	8b 00                	mov    (%eax),%eax
40004a2b:	3d ff 00 00 00       	cmp    $0xff,%eax
40004a30:	7f 38                	jg     40004a6a <opendir+0x89>
40004a32:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40004a38:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004a3b:	8b 00                	mov    (%eax),%eax
40004a3d:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004a40:	01 d0                	add    %edx,%eax
40004a42:	05 10 10 00 00       	add    $0x1010,%eax
40004a47:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004a4b:	84 c0                	test   %al,%al
40004a4d:	74 1b                	je     40004a6a <opendir+0x89>
40004a4f:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40004a55:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004a58:	8b 00                	mov    (%eax),%eax
40004a5a:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004a5d:	01 d0                	add    %edx,%eax
40004a5f:	05 58 10 00 00       	add    $0x1058,%eax
40004a64:	8b 00                	mov    (%eax),%eax
40004a66:	85 c0                	test   %eax,%eax
40004a68:	75 24                	jne    40004a8e <opendir+0xad>
40004a6a:	c7 44 24 0c a6 83 00 	movl   $0x400083a6,0xc(%esp)
40004a71:	40 
40004a72:	c7 44 24 08 20 83 00 	movl   $0x40008320,0x8(%esp)
40004a79:	40 
40004a7a:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
40004a81:	00 
40004a82:	c7 04 24 35 83 00 40 	movl   $0x40008335,(%esp)
40004a89:	e8 56 db ff ff       	call   400025e4 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40004a8e:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40004a94:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004a97:	8b 00                	mov    (%eax),%eax
40004a99:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004a9c:	05 10 10 00 00       	add    $0x1010,%eax
40004aa1:	01 d0                	add    %edx,%eax
40004aa3:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (!S_ISDIR(fi->mode)) {
40004aa6:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004aa9:	8b 40 48             	mov    0x48(%eax),%eax
40004aac:	25 00 70 00 00       	and    $0x7000,%eax
40004ab1:	3d 00 20 00 00       	cmp    $0x2000,%eax
40004ab6:	74 1d                	je     40004ad5 <opendir+0xf4>
		filedesc_close(fd);
40004ab8:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004abb:	89 04 24             	mov    %eax,(%esp)
40004abe:	e8 b1 f8 ff ff       	call   40004374 <filedesc_close>
		errno = ENOTDIR;
40004ac3:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004ac8:	c7 00 05 00 00 00    	movl   $0x5,(%eax)
		return NULL;
40004ace:	b8 00 00 00 00       	mov    $0x0,%eax
40004ad3:	eb 03                	jmp    40004ad8 <opendir+0xf7>
	}

	return fd;
40004ad5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
40004ad8:	c9                   	leave  
40004ad9:	c3                   	ret    

40004ada <closedir>:

int closedir(DIR *dir)
{
40004ada:	55                   	push   %ebp
40004adb:	89 e5                	mov    %esp,%ebp
40004add:	83 ec 18             	sub    $0x18,%esp
	filedesc_close(dir);
40004ae0:	8b 45 08             	mov    0x8(%ebp),%eax
40004ae3:	89 04 24             	mov    %eax,(%esp)
40004ae6:	e8 89 f8 ff ff       	call   40004374 <filedesc_close>
	return 0;
40004aeb:	b8 00 00 00 00       	mov    $0x0,%eax
}
40004af0:	c9                   	leave  
40004af1:	c3                   	ret    

40004af2 <readdir>:

// Scan an open directory filedesc and return the next entry.
// Returns a pointer to the next matching file inode's 'dirent' struct,
// or NULL if the directory being scanned contains no more entries.
struct dirent *readdir(DIR *dir)
{
40004af2:	55                   	push   %ebp
40004af3:	89 e5                	mov    %esp,%ebp
40004af5:	83 ec 28             	sub    $0x28,%esp
	// Hint: a fileinode's 'dino' field indicates
	// what directory the file is in;
	// this function shouldn't return entries from other directories!
	//warn("readdir() not implemented");
	//return NULL;
	assert(fileino_isdir(dir->ino));
40004af8:	8b 45 08             	mov    0x8(%ebp),%eax
40004afb:	8b 00                	mov    (%eax),%eax
40004afd:	85 c0                	test   %eax,%eax
40004aff:	7e 4c                	jle    40004b4d <readdir+0x5b>
40004b01:	8b 45 08             	mov    0x8(%ebp),%eax
40004b04:	8b 00                	mov    (%eax),%eax
40004b06:	3d ff 00 00 00       	cmp    $0xff,%eax
40004b0b:	7f 40                	jg     40004b4d <readdir+0x5b>
40004b0d:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40004b13:	8b 45 08             	mov    0x8(%ebp),%eax
40004b16:	8b 00                	mov    (%eax),%eax
40004b18:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004b1b:	01 d0                	add    %edx,%eax
40004b1d:	05 10 10 00 00       	add    $0x1010,%eax
40004b22:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40004b26:	84 c0                	test   %al,%al
40004b28:	74 23                	je     40004b4d <readdir+0x5b>
40004b2a:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40004b30:	8b 45 08             	mov    0x8(%ebp),%eax
40004b33:	8b 00                	mov    (%eax),%eax
40004b35:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004b38:	01 d0                	add    %edx,%eax
40004b3a:	05 58 10 00 00       	add    $0x1058,%eax
40004b3f:	8b 00                	mov    (%eax),%eax
40004b41:	25 00 70 00 00       	and    $0x7000,%eax
40004b46:	3d 00 20 00 00       	cmp    $0x2000,%eax
40004b4b:	74 24                	je     40004b71 <readdir+0x7f>
40004b4d:	c7 44 24 0c be 83 00 	movl   $0x400083be,0xc(%esp)
40004b54:	40 
40004b55:	c7 44 24 08 20 83 00 	movl   $0x40008320,0x8(%esp)
40004b5c:	40 
40004b5d:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
40004b64:	00 
40004b65:	c7 04 24 35 83 00 40 	movl   $0x40008335,(%esp)
40004b6c:	e8 73 da ff ff       	call   400025e4 <debug_panic>
	int i = dir->ofs;
40004b71:	8b 45 08             	mov    0x8(%ebp),%eax
40004b74:	8b 40 08             	mov    0x8(%eax),%eax
40004b77:	89 45 f4             	mov    %eax,-0xc(%ebp)
	for(i; i < FILE_INODES; i++){
40004b7a:	eb 3c                	jmp    40004bb8 <readdir+0xc6>
		fileinode* tmp_fi = &files->fi[i];
40004b7c:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004b81:	8b 55 f4             	mov    -0xc(%ebp),%edx
40004b84:	6b d2 5c             	imul   $0x5c,%edx,%edx
40004b87:	81 c2 10 10 00 00    	add    $0x1010,%edx
40004b8d:	01 d0                	add    %edx,%eax
40004b8f:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if(tmp_fi->dino == dir->ino){
40004b92:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004b95:	8b 10                	mov    (%eax),%edx
40004b97:	8b 45 08             	mov    0x8(%ebp),%eax
40004b9a:	8b 00                	mov    (%eax),%eax
40004b9c:	39 c2                	cmp    %eax,%edx
40004b9e:	75 14                	jne    40004bb4 <readdir+0xc2>
			dir->ofs = i+1;
40004ba0:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004ba3:	8d 50 01             	lea    0x1(%eax),%edx
40004ba6:	8b 45 08             	mov    0x8(%ebp),%eax
40004ba9:	89 50 08             	mov    %edx,0x8(%eax)
			return &tmp_fi->de;
40004bac:	8b 45 f0             	mov    -0x10(%ebp),%eax
40004baf:	83 c0 04             	add    $0x4,%eax
40004bb2:	eb 1c                	jmp    40004bd0 <readdir+0xde>
	// this function shouldn't return entries from other directories!
	//warn("readdir() not implemented");
	//return NULL;
	assert(fileino_isdir(dir->ino));
	int i = dir->ofs;
	for(i; i < FILE_INODES; i++){
40004bb4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
40004bb8:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
40004bbf:	7e bb                	jle    40004b7c <readdir+0x8a>
		if(tmp_fi->dino == dir->ino){
			dir->ofs = i+1;
			return &tmp_fi->de;
		}
	}
	dir->ofs = 0;
40004bc1:	8b 45 08             	mov    0x8(%ebp),%eax
40004bc4:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
	return NULL;
40004bcb:	b8 00 00 00 00       	mov    $0x0,%eax
}
40004bd0:	c9                   	leave  
40004bd1:	c3                   	ret    

40004bd2 <rewinddir>:

void rewinddir(DIR *dir)
{
40004bd2:	55                   	push   %ebp
40004bd3:	89 e5                	mov    %esp,%ebp
	dir->ofs = 0;
40004bd5:	8b 45 08             	mov    0x8(%ebp),%eax
40004bd8:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
40004bdf:	5d                   	pop    %ebp
40004be0:	c3                   	ret    

40004be1 <seekdir>:

void seekdir(DIR *dir, long ofs)
{
40004be1:	55                   	push   %ebp
40004be2:	89 e5                	mov    %esp,%ebp
	dir->ofs = ofs;
40004be4:	8b 45 08             	mov    0x8(%ebp),%eax
40004be7:	8b 55 0c             	mov    0xc(%ebp),%edx
40004bea:	89 50 08             	mov    %edx,0x8(%eax)
}
40004bed:	5d                   	pop    %ebp
40004bee:	c3                   	ret    

40004bef <telldir>:

long telldir(DIR *dir)
{
40004bef:	55                   	push   %ebp
40004bf0:	89 e5                	mov    %esp,%ebp
	return dir->ofs;
40004bf2:	8b 45 08             	mov    0x8(%ebp),%eax
40004bf5:	8b 40 08             	mov    0x8(%eax),%eax
}
40004bf8:	5d                   	pop    %ebp
40004bf9:	c3                   	ret    
40004bfa:	66 90                	xchg   %ax,%ax

40004bfc <fopen>:
FILE *const stdout = &FILES->fd[1];
FILE *const stderr = &FILES->fd[2];

FILE *
fopen(const char *path, const char *mode)
{
40004bfc:	55                   	push   %ebp
40004bfd:	89 e5                	mov    %esp,%ebp
40004bff:	83 ec 28             	sub    $0x28,%esp
	// Find an unused file descriptor and use it for the open
	FILE *fd = filedesc_alloc();
40004c02:	e8 52 f1 ff ff       	call   40003d59 <filedesc_alloc>
40004c07:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (fd == NULL)
40004c0a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40004c0e:	75 07                	jne    40004c17 <fopen+0x1b>
		return NULL;
40004c10:	b8 00 00 00 00       	mov    $0x0,%eax
40004c15:	eb 19                	jmp    40004c30 <fopen+0x34>

	return freopen(path, mode, fd);
40004c17:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004c1a:	89 44 24 08          	mov    %eax,0x8(%esp)
40004c1e:	8b 45 0c             	mov    0xc(%ebp),%eax
40004c21:	89 44 24 04          	mov    %eax,0x4(%esp)
40004c25:	8b 45 08             	mov    0x8(%ebp),%eax
40004c28:	89 04 24             	mov    %eax,(%esp)
40004c2b:	e8 02 00 00 00       	call   40004c32 <freopen>
}
40004c30:	c9                   	leave  
40004c31:	c3                   	ret    

40004c32 <freopen>:

FILE *
freopen(const char *path, const char *mode, FILE *fd)
{
40004c32:	55                   	push   %ebp
40004c33:	89 e5                	mov    %esp,%ebp
40004c35:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isvalid(fd));
40004c38:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004c3d:	83 c0 10             	add    $0x10,%eax
40004c40:	3b 45 10             	cmp    0x10(%ebp),%eax
40004c43:	77 0f                	ja     40004c54 <freopen+0x22>
40004c45:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004c4a:	05 10 10 00 00       	add    $0x1010,%eax
40004c4f:	3b 45 10             	cmp    0x10(%ebp),%eax
40004c52:	77 24                	ja     40004c78 <freopen+0x46>
40004c54:	c7 44 24 0c e4 83 00 	movl   $0x400083e4,0xc(%esp)
40004c5b:	40 
40004c5c:	c7 44 24 08 f9 83 00 	movl   $0x400083f9,0x8(%esp)
40004c63:	40 
40004c64:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
40004c6b:	00 
40004c6c:	c7 04 24 0e 84 00 40 	movl   $0x4000840e,(%esp)
40004c73:	e8 6c d9 ff ff       	call   400025e4 <debug_panic>
	if (filedesc_isopen(fd))
40004c78:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004c7d:	83 c0 10             	add    $0x10,%eax
40004c80:	3b 45 10             	cmp    0x10(%ebp),%eax
40004c83:	77 23                	ja     40004ca8 <freopen+0x76>
40004c85:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004c8a:	05 10 10 00 00       	add    $0x1010,%eax
40004c8f:	3b 45 10             	cmp    0x10(%ebp),%eax
40004c92:	76 14                	jbe    40004ca8 <freopen+0x76>
40004c94:	8b 45 10             	mov    0x10(%ebp),%eax
40004c97:	8b 00                	mov    (%eax),%eax
40004c99:	85 c0                	test   %eax,%eax
40004c9b:	74 0b                	je     40004ca8 <freopen+0x76>
		fclose(fd);
40004c9d:	8b 45 10             	mov    0x10(%ebp),%eax
40004ca0:	89 04 24             	mov    %eax,(%esp)
40004ca3:	e8 b4 00 00 00       	call   40004d5c <fclose>

	// Parse the open mode string
	int flags;
	switch (*mode++) {
40004ca8:	8b 45 0c             	mov    0xc(%ebp),%eax
40004cab:	0f b6 00             	movzbl (%eax),%eax
40004cae:	0f be c0             	movsbl %al,%eax
40004cb1:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
40004cb5:	83 f8 72             	cmp    $0x72,%eax
40004cb8:	74 0c                	je     40004cc6 <freopen+0x94>
40004cba:	83 f8 77             	cmp    $0x77,%eax
40004cbd:	74 10                	je     40004ccf <freopen+0x9d>
40004cbf:	83 f8 61             	cmp    $0x61,%eax
40004cc2:	74 14                	je     40004cd8 <freopen+0xa6>
40004cc4:	eb 1b                	jmp    40004ce1 <freopen+0xaf>
	case 'r':	flags = O_RDONLY; break;
40004cc6:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
40004ccd:	eb 3f                	jmp    40004d0e <freopen+0xdc>
	case 'w':	flags = O_WRONLY | O_CREAT | O_TRUNC; break;
40004ccf:	c7 45 f4 62 00 00 00 	movl   $0x62,-0xc(%ebp)
40004cd6:	eb 36                	jmp    40004d0e <freopen+0xdc>
	case 'a':	flags = O_WRONLY | O_CREAT | O_APPEND; break;
40004cd8:	c7 45 f4 32 00 00 00 	movl   $0x32,-0xc(%ebp)
40004cdf:	eb 2d                	jmp    40004d0e <freopen+0xdc>
	default:	panic("freopen: unknown file mode '%c'\n", *--mode);
40004ce1:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
40004ce5:	8b 45 0c             	mov    0xc(%ebp),%eax
40004ce8:	0f b6 00             	movzbl (%eax),%eax
40004ceb:	0f be c0             	movsbl %al,%eax
40004cee:	89 44 24 0c          	mov    %eax,0xc(%esp)
40004cf2:	c7 44 24 08 1c 84 00 	movl   $0x4000841c,0x8(%esp)
40004cf9:	40 
40004cfa:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
40004d01:	00 
40004d02:	c7 04 24 0e 84 00 40 	movl   $0x4000840e,(%esp)
40004d09:	e8 d6 d8 ff ff       	call   400025e4 <debug_panic>
	}
	if (*mode == 'b')	// binary flag - compatibility only
40004d0e:	8b 45 0c             	mov    0xc(%ebp),%eax
40004d11:	0f b6 00             	movzbl (%eax),%eax
40004d14:	3c 62                	cmp    $0x62,%al
40004d16:	75 04                	jne    40004d1c <freopen+0xea>
		mode++;
40004d18:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	if (*mode == '+')
40004d1c:	8b 45 0c             	mov    0xc(%ebp),%eax
40004d1f:	0f b6 00             	movzbl (%eax),%eax
40004d22:	3c 2b                	cmp    $0x2b,%al
40004d24:	75 04                	jne    40004d2a <freopen+0xf8>
		flags |= O_RDWR;
40004d26:	83 4d f4 03          	orl    $0x3,-0xc(%ebp)

	if (filedesc_open(fd, path, flags, 0666) != fd)
40004d2a:	c7 44 24 0c b6 01 00 	movl   $0x1b6,0xc(%esp)
40004d31:	00 
40004d32:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004d35:	89 44 24 08          	mov    %eax,0x8(%esp)
40004d39:	8b 45 08             	mov    0x8(%ebp),%eax
40004d3c:	89 44 24 04          	mov    %eax,0x4(%esp)
40004d40:	8b 45 10             	mov    0x10(%ebp),%eax
40004d43:	89 04 24             	mov    %eax,(%esp)
40004d46:	e8 64 f0 ff ff       	call   40003daf <filedesc_open>
40004d4b:	3b 45 10             	cmp    0x10(%ebp),%eax
40004d4e:	74 07                	je     40004d57 <freopen+0x125>
		return NULL;
40004d50:	b8 00 00 00 00       	mov    $0x0,%eax
40004d55:	eb 03                	jmp    40004d5a <freopen+0x128>
	return fd;
40004d57:	8b 45 10             	mov    0x10(%ebp),%eax
}
40004d5a:	c9                   	leave  
40004d5b:	c3                   	ret    

40004d5c <fclose>:

int
fclose(FILE *fd)
{
40004d5c:	55                   	push   %ebp
40004d5d:	89 e5                	mov    %esp,%ebp
40004d5f:	83 ec 18             	sub    $0x18,%esp
	filedesc_close(fd);
40004d62:	8b 45 08             	mov    0x8(%ebp),%eax
40004d65:	89 04 24             	mov    %eax,(%esp)
40004d68:	e8 07 f6 ff ff       	call   40004374 <filedesc_close>
	return 0;
40004d6d:	b8 00 00 00 00       	mov    $0x0,%eax
}
40004d72:	c9                   	leave  
40004d73:	c3                   	ret    

40004d74 <fgetc>:

int
fgetc(FILE *fd)
{
40004d74:	55                   	push   %ebp
40004d75:	89 e5                	mov    %esp,%ebp
40004d77:	83 ec 28             	sub    $0x28,%esp
	unsigned char ch;
	if (filedesc_read(fd, &ch, 1, 1) < 1)
40004d7a:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
40004d81:	00 
40004d82:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40004d89:	00 
40004d8a:	8d 45 f7             	lea    -0x9(%ebp),%eax
40004d8d:	89 44 24 04          	mov    %eax,0x4(%esp)
40004d91:	8b 45 08             	mov    0x8(%ebp),%eax
40004d94:	89 04 24             	mov    %eax,(%esp)
40004d97:	e8 3d f2 ff ff       	call   40003fd9 <filedesc_read>
40004d9c:	85 c0                	test   %eax,%eax
40004d9e:	7f 07                	jg     40004da7 <fgetc+0x33>
		return EOF;
40004da0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40004da5:	eb 07                	jmp    40004dae <fgetc+0x3a>
	return ch;
40004da7:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
40004dab:	0f b6 c0             	movzbl %al,%eax
}
40004dae:	c9                   	leave  
40004daf:	c3                   	ret    

40004db0 <fputc>:

int
fputc(int c, FILE *fd)
{
40004db0:	55                   	push   %ebp
40004db1:	89 e5                	mov    %esp,%ebp
40004db3:	83 ec 28             	sub    $0x28,%esp
	unsigned char ch = c;
40004db6:	8b 45 08             	mov    0x8(%ebp),%eax
40004db9:	88 45 f7             	mov    %al,-0x9(%ebp)
	if (filedesc_write(fd, &ch, 1, 1) < 1)
40004dbc:	c7 44 24 0c 01 00 00 	movl   $0x1,0xc(%esp)
40004dc3:	00 
40004dc4:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40004dcb:	00 
40004dcc:	8d 45 f7             	lea    -0x9(%ebp),%eax
40004dcf:	89 44 24 04          	mov    %eax,0x4(%esp)
40004dd3:	8b 45 0c             	mov    0xc(%ebp),%eax
40004dd6:	89 04 24             	mov    %eax,(%esp)
40004dd9:	e8 10 f3 ff ff       	call   400040ee <filedesc_write>
40004dde:	85 c0                	test   %eax,%eax
40004de0:	7f 07                	jg     40004de9 <fputc+0x39>
		return EOF;
40004de2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40004de7:	eb 07                	jmp    40004df0 <fputc+0x40>
	return ch;
40004de9:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
40004ded:	0f b6 c0             	movzbl %al,%eax
}
40004df0:	c9                   	leave  
40004df1:	c3                   	ret    

40004df2 <fread>:

size_t
fread(void *buf, size_t eltsize, size_t count, FILE *fd)
{
40004df2:	55                   	push   %ebp
40004df3:	89 e5                	mov    %esp,%ebp
40004df5:	83 ec 28             	sub    $0x28,%esp
	ssize_t actual = filedesc_read(fd, buf, eltsize, count);
40004df8:	8b 45 10             	mov    0x10(%ebp),%eax
40004dfb:	89 44 24 0c          	mov    %eax,0xc(%esp)
40004dff:	8b 45 0c             	mov    0xc(%ebp),%eax
40004e02:	89 44 24 08          	mov    %eax,0x8(%esp)
40004e06:	8b 45 08             	mov    0x8(%ebp),%eax
40004e09:	89 44 24 04          	mov    %eax,0x4(%esp)
40004e0d:	8b 45 14             	mov    0x14(%ebp),%eax
40004e10:	89 04 24             	mov    %eax,(%esp)
40004e13:	e8 c1 f1 ff ff       	call   40003fd9 <filedesc_read>
40004e18:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return actual >= 0 ? actual : 0;	// no error indication
40004e1b:	b8 00 00 00 00       	mov    $0x0,%eax
40004e20:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40004e24:	0f 49 45 f4          	cmovns -0xc(%ebp),%eax
}
40004e28:	c9                   	leave  
40004e29:	c3                   	ret    

40004e2a <fwrite>:

size_t
fwrite(const void *buf, size_t eltsize, size_t count, FILE *fd)
{
40004e2a:	55                   	push   %ebp
40004e2b:	89 e5                	mov    %esp,%ebp
40004e2d:	83 ec 28             	sub    $0x28,%esp
	ssize_t actual = filedesc_write(fd, buf, eltsize, count);
40004e30:	8b 45 10             	mov    0x10(%ebp),%eax
40004e33:	89 44 24 0c          	mov    %eax,0xc(%esp)
40004e37:	8b 45 0c             	mov    0xc(%ebp),%eax
40004e3a:	89 44 24 08          	mov    %eax,0x8(%esp)
40004e3e:	8b 45 08             	mov    0x8(%ebp),%eax
40004e41:	89 44 24 04          	mov    %eax,0x4(%esp)
40004e45:	8b 45 14             	mov    0x14(%ebp),%eax
40004e48:	89 04 24             	mov    %eax,(%esp)
40004e4b:	e8 9e f2 ff ff       	call   400040ee <filedesc_write>
40004e50:	89 45 f4             	mov    %eax,-0xc(%ebp)

		
	return actual >= 0 ? actual : 0;	// no error indication
40004e53:	b8 00 00 00 00       	mov    $0x0,%eax
40004e58:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40004e5c:	0f 49 45 f4          	cmovns -0xc(%ebp),%eax
}
40004e60:	c9                   	leave  
40004e61:	c3                   	ret    

40004e62 <fseek>:

int
fseek(FILE *fd, off_t offset, int whence)
{
40004e62:	55                   	push   %ebp
40004e63:	89 e5                	mov    %esp,%ebp
40004e65:	83 ec 18             	sub    $0x18,%esp
	if (filedesc_seek(fd, offset, whence) < 0)
40004e68:	8b 45 10             	mov    0x10(%ebp),%eax
40004e6b:	89 44 24 08          	mov    %eax,0x8(%esp)
40004e6f:	8b 45 0c             	mov    0xc(%ebp),%eax
40004e72:	89 44 24 04          	mov    %eax,0x4(%esp)
40004e76:	8b 45 08             	mov    0x8(%ebp),%eax
40004e79:	89 04 24             	mov    %eax,(%esp)
40004e7c:	e8 e2 f3 ff ff       	call   40004263 <filedesc_seek>
40004e81:	85 c0                	test   %eax,%eax
40004e83:	79 07                	jns    40004e8c <fseek+0x2a>
		return -1;
40004e85:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40004e8a:	eb 05                	jmp    40004e91 <fseek+0x2f>
	return 0;	// fseek() returns 0 on success, not the new position
40004e8c:	b8 00 00 00 00       	mov    $0x0,%eax
}
40004e91:	c9                   	leave  
40004e92:	c3                   	ret    

40004e93 <ftell>:

long
ftell(FILE *fd)
{
40004e93:	55                   	push   %ebp
40004e94:	89 e5                	mov    %esp,%ebp
40004e96:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
40004e99:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004e9e:	83 c0 10             	add    $0x10,%eax
40004ea1:	3b 45 08             	cmp    0x8(%ebp),%eax
40004ea4:	77 18                	ja     40004ebe <ftell+0x2b>
40004ea6:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004eab:	05 10 10 00 00       	add    $0x1010,%eax
40004eb0:	3b 45 08             	cmp    0x8(%ebp),%eax
40004eb3:	76 09                	jbe    40004ebe <ftell+0x2b>
40004eb5:	8b 45 08             	mov    0x8(%ebp),%eax
40004eb8:	8b 00                	mov    (%eax),%eax
40004eba:	85 c0                	test   %eax,%eax
40004ebc:	75 24                	jne    40004ee2 <ftell+0x4f>
40004ebe:	c7 44 24 0c 3d 84 00 	movl   $0x4000843d,0xc(%esp)
40004ec5:	40 
40004ec6:	c7 44 24 08 f9 83 00 	movl   $0x400083f9,0x8(%esp)
40004ecd:	40 
40004ece:	c7 44 24 04 7a 00 00 	movl   $0x7a,0x4(%esp)
40004ed5:	00 
40004ed6:	c7 04 24 0e 84 00 40 	movl   $0x4000840e,(%esp)
40004edd:	e8 02 d7 ff ff       	call   400025e4 <debug_panic>
	return fd->ofs;
40004ee2:	8b 45 08             	mov    0x8(%ebp),%eax
40004ee5:	8b 40 08             	mov    0x8(%eax),%eax
}
40004ee8:	c9                   	leave  
40004ee9:	c3                   	ret    

40004eea <feof>:

int
feof(FILE *fd)
{
40004eea:	55                   	push   %ebp
40004eeb:	89 e5                	mov    %esp,%ebp
40004eed:	83 ec 28             	sub    $0x28,%esp
	assert(filedesc_isopen(fd));
40004ef0:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004ef5:	83 c0 10             	add    $0x10,%eax
40004ef8:	3b 45 08             	cmp    0x8(%ebp),%eax
40004efb:	77 18                	ja     40004f15 <feof+0x2b>
40004efd:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004f02:	05 10 10 00 00       	add    $0x1010,%eax
40004f07:	3b 45 08             	cmp    0x8(%ebp),%eax
40004f0a:	76 09                	jbe    40004f15 <feof+0x2b>
40004f0c:	8b 45 08             	mov    0x8(%ebp),%eax
40004f0f:	8b 00                	mov    (%eax),%eax
40004f11:	85 c0                	test   %eax,%eax
40004f13:	75 24                	jne    40004f39 <feof+0x4f>
40004f15:	c7 44 24 0c 3d 84 00 	movl   $0x4000843d,0xc(%esp)
40004f1c:	40 
40004f1d:	c7 44 24 08 f9 83 00 	movl   $0x400083f9,0x8(%esp)
40004f24:	40 
40004f25:	c7 44 24 04 81 00 00 	movl   $0x81,0x4(%esp)
40004f2c:	00 
40004f2d:	c7 04 24 0e 84 00 40 	movl   $0x4000840e,(%esp)
40004f34:	e8 ab d6 ff ff       	call   400025e4 <debug_panic>
	fileinode *fi = &files->fi[fd->ino];
40004f39:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40004f3f:	8b 45 08             	mov    0x8(%ebp),%eax
40004f42:	8b 00                	mov    (%eax),%eax
40004f44:	6b c0 5c             	imul   $0x5c,%eax,%eax
40004f47:	05 10 10 00 00       	add    $0x1010,%eax
40004f4c:	01 d0                	add    %edx,%eax
40004f4e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	return fd->ofs >= fi->size && !(fi->mode & S_IFPART);
40004f51:	8b 45 08             	mov    0x8(%ebp),%eax
40004f54:	8b 40 08             	mov    0x8(%eax),%eax
40004f57:	89 c2                	mov    %eax,%edx
40004f59:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004f5c:	8b 40 4c             	mov    0x4c(%eax),%eax
40004f5f:	39 c2                	cmp    %eax,%edx
40004f61:	72 16                	jb     40004f79 <feof+0x8f>
40004f63:	8b 45 f4             	mov    -0xc(%ebp),%eax
40004f66:	8b 40 48             	mov    0x48(%eax),%eax
40004f69:	25 00 80 00 00       	and    $0x8000,%eax
40004f6e:	85 c0                	test   %eax,%eax
40004f70:	75 07                	jne    40004f79 <feof+0x8f>
40004f72:	b8 01 00 00 00       	mov    $0x1,%eax
40004f77:	eb 05                	jmp    40004f7e <feof+0x94>
40004f79:	b8 00 00 00 00       	mov    $0x0,%eax
}
40004f7e:	c9                   	leave  
40004f7f:	c3                   	ret    

40004f80 <ferror>:

int
ferror(FILE *fd)
{
40004f80:	55                   	push   %ebp
40004f81:	89 e5                	mov    %esp,%ebp
40004f83:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
40004f86:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004f8b:	83 c0 10             	add    $0x10,%eax
40004f8e:	3b 45 08             	cmp    0x8(%ebp),%eax
40004f91:	77 18                	ja     40004fab <ferror+0x2b>
40004f93:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004f98:	05 10 10 00 00       	add    $0x1010,%eax
40004f9d:	3b 45 08             	cmp    0x8(%ebp),%eax
40004fa0:	76 09                	jbe    40004fab <ferror+0x2b>
40004fa2:	8b 45 08             	mov    0x8(%ebp),%eax
40004fa5:	8b 00                	mov    (%eax),%eax
40004fa7:	85 c0                	test   %eax,%eax
40004fa9:	75 24                	jne    40004fcf <ferror+0x4f>
40004fab:	c7 44 24 0c 3d 84 00 	movl   $0x4000843d,0xc(%esp)
40004fb2:	40 
40004fb3:	c7 44 24 08 f9 83 00 	movl   $0x400083f9,0x8(%esp)
40004fba:	40 
40004fbb:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
40004fc2:	00 
40004fc3:	c7 04 24 0e 84 00 40 	movl   $0x4000840e,(%esp)
40004fca:	e8 15 d6 ff ff       	call   400025e4 <debug_panic>
	return fd->err;
40004fcf:	8b 45 08             	mov    0x8(%ebp),%eax
40004fd2:	8b 40 0c             	mov    0xc(%eax),%eax
}
40004fd5:	c9                   	leave  
40004fd6:	c3                   	ret    

40004fd7 <clearerr>:

void
clearerr(FILE *fd)
{
40004fd7:	55                   	push   %ebp
40004fd8:	89 e5                	mov    %esp,%ebp
40004fda:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(fd));
40004fdd:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004fe2:	83 c0 10             	add    $0x10,%eax
40004fe5:	3b 45 08             	cmp    0x8(%ebp),%eax
40004fe8:	77 18                	ja     40005002 <clearerr+0x2b>
40004fea:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40004fef:	05 10 10 00 00       	add    $0x1010,%eax
40004ff4:	3b 45 08             	cmp    0x8(%ebp),%eax
40004ff7:	76 09                	jbe    40005002 <clearerr+0x2b>
40004ff9:	8b 45 08             	mov    0x8(%ebp),%eax
40004ffc:	8b 00                	mov    (%eax),%eax
40004ffe:	85 c0                	test   %eax,%eax
40005000:	75 24                	jne    40005026 <clearerr+0x4f>
40005002:	c7 44 24 0c 3d 84 00 	movl   $0x4000843d,0xc(%esp)
40005009:	40 
4000500a:	c7 44 24 08 f9 83 00 	movl   $0x400083f9,0x8(%esp)
40005011:	40 
40005012:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
40005019:	00 
4000501a:	c7 04 24 0e 84 00 40 	movl   $0x4000840e,(%esp)
40005021:	e8 be d5 ff ff       	call   400025e4 <debug_panic>
	fd->err = 0;
40005026:	8b 45 08             	mov    0x8(%ebp),%eax
40005029:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
}
40005030:	c9                   	leave  
40005031:	c3                   	ret    

40005032 <fflush>:


int
fflush(FILE *f)
{
40005032:	55                   	push   %ebp
40005033:	89 e5                	mov    %esp,%ebp
40005035:	83 ec 18             	sub    $0x18,%esp
	if (f == NULL) {	// flush all open streams
40005038:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
4000503c:	75 57                	jne    40005095 <fflush+0x63>
		for (f = &files->fd[0]; f < &files->fd[OPEN_MAX]; f++)
4000503e:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005043:	83 c0 10             	add    $0x10,%eax
40005046:	89 45 08             	mov    %eax,0x8(%ebp)
40005049:	eb 34                	jmp    4000507f <fflush+0x4d>
			if (filedesc_isopen(f))
4000504b:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005050:	83 c0 10             	add    $0x10,%eax
40005053:	3b 45 08             	cmp    0x8(%ebp),%eax
40005056:	77 23                	ja     4000507b <fflush+0x49>
40005058:	a1 8c 80 00 40       	mov    0x4000808c,%eax
4000505d:	05 10 10 00 00       	add    $0x1010,%eax
40005062:	3b 45 08             	cmp    0x8(%ebp),%eax
40005065:	76 14                	jbe    4000507b <fflush+0x49>
40005067:	8b 45 08             	mov    0x8(%ebp),%eax
4000506a:	8b 00                	mov    (%eax),%eax
4000506c:	85 c0                	test   %eax,%eax
4000506e:	74 0b                	je     4000507b <fflush+0x49>
				fflush(f);
40005070:	8b 45 08             	mov    0x8(%ebp),%eax
40005073:	89 04 24             	mov    %eax,(%esp)
40005076:	e8 b7 ff ff ff       	call   40005032 <fflush>

int
fflush(FILE *f)
{
	if (f == NULL) {	// flush all open streams
		for (f = &files->fd[0]; f < &files->fd[OPEN_MAX]; f++)
4000507b:	83 45 08 10          	addl   $0x10,0x8(%ebp)
4000507f:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005084:	05 10 10 00 00       	add    $0x1010,%eax
40005089:	3b 45 08             	cmp    0x8(%ebp),%eax
4000508c:	77 bd                	ja     4000504b <fflush+0x19>
			if (filedesc_isopen(f))
				fflush(f);
		return 0;
4000508e:	b8 00 00 00 00       	mov    $0x0,%eax
40005093:	eb 56                	jmp    400050eb <fflush+0xb9>
	}

	assert(filedesc_isopen(f));
40005095:	a1 8c 80 00 40       	mov    0x4000808c,%eax
4000509a:	83 c0 10             	add    $0x10,%eax
4000509d:	3b 45 08             	cmp    0x8(%ebp),%eax
400050a0:	77 18                	ja     400050ba <fflush+0x88>
400050a2:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400050a7:	05 10 10 00 00       	add    $0x1010,%eax
400050ac:	3b 45 08             	cmp    0x8(%ebp),%eax
400050af:	76 09                	jbe    400050ba <fflush+0x88>
400050b1:	8b 45 08             	mov    0x8(%ebp),%eax
400050b4:	8b 00                	mov    (%eax),%eax
400050b6:	85 c0                	test   %eax,%eax
400050b8:	75 24                	jne    400050de <fflush+0xac>
400050ba:	c7 44 24 0c 51 84 00 	movl   $0x40008451,0xc(%esp)
400050c1:	40 
400050c2:	c7 44 24 08 f9 83 00 	movl   $0x400083f9,0x8(%esp)
400050c9:	40 
400050ca:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
400050d1:	00 
400050d2:	c7 04 24 0e 84 00 40 	movl   $0x4000840e,(%esp)
400050d9:	e8 06 d5 ff ff       	call   400025e4 <debug_panic>
	return fileino_flush(f->ino);
400050de:	8b 45 08             	mov    0x8(%ebp),%eax
400050e1:	8b 00                	mov    (%eax),%eax
400050e3:	89 04 24             	mov    %eax,(%esp)
400050e6:	e8 f9 eb ff ff       	call   40003ce4 <fileino_flush>
}
400050eb:	c9                   	leave  
400050ec:	c3                   	ret    
400050ed:	66 90                	xchg   %ax,%ax
400050ef:	90                   	nop

400050f0 <exit>:
#include <inc/assert.h>
#include <inc/string.h>

void gcc_noreturn
exit(int status)
{
400050f0:	55                   	push   %ebp
400050f1:	89 e5                	mov    %esp,%ebp
400050f3:	83 ec 18             	sub    $0x18,%esp
	// To exit a PIOS user process, by convention,
	// we just set our exit status in our filestate area
	// and return to our parent process.
	files->status = status;
400050f6:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400050fb:	8b 55 08             	mov    0x8(%ebp),%edx
400050fe:	89 50 0c             	mov    %edx,0xc(%eax)
	files->exited = 1;
40005101:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005106:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
4000510d:	b8 03 00 00 00       	mov    $0x3,%eax
40005112:	cd 30                	int    $0x30
	sys_ret();
	panic("exit: sys_ret shouldn't have returned");
40005114:	c7 44 24 08 64 84 00 	movl   $0x40008464,0x8(%esp)
4000511b:	40 
4000511c:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
40005123:	00 
40005124:	c7 04 24 8a 84 00 40 	movl   $0x4000848a,(%esp)
4000512b:	e8 b4 d4 ff ff       	call   400025e4 <debug_panic>

40005130 <abort>:
}

void gcc_noreturn
abort(void)
{
40005130:	55                   	push   %ebp
40005131:	89 e5                	mov    %esp,%ebp
40005133:	83 ec 18             	sub    $0x18,%esp
	exit(EXIT_FAILURE);
40005136:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
4000513d:	e8 ae ff ff ff       	call   400050f0 <exit>
40005142:	66 90                	xchg   %ax,%ax

40005144 <creat>:
#include <inc/assert.h>
#include <inc/stdarg.h>

int
creat(const char *path, mode_t mode)
{
40005144:	55                   	push   %ebp
40005145:	89 e5                	mov    %esp,%ebp
40005147:	83 ec 18             	sub    $0x18,%esp
	return open(path, O_CREAT | O_TRUNC | O_WRONLY, mode);
4000514a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000514d:	89 44 24 08          	mov    %eax,0x8(%esp)
40005151:	c7 44 24 04 62 00 00 	movl   $0x62,0x4(%esp)
40005158:	00 
40005159:	8b 45 08             	mov    0x8(%ebp),%eax
4000515c:	89 04 24             	mov    %eax,(%esp)
4000515f:	e8 02 00 00 00       	call   40005166 <open>
}
40005164:	c9                   	leave  
40005165:	c3                   	ret    

40005166 <open>:

int
open(const char *path, int flags, ...)
{
40005166:	55                   	push   %ebp
40005167:	89 e5                	mov    %esp,%ebp
40005169:	83 ec 28             	sub    $0x28,%esp
	// Get the optional mode argument, which applies only with O_CREAT.
	mode_t mode = 0;
4000516c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	if (flags & O_CREAT) {
40005173:	8b 45 0c             	mov    0xc(%ebp),%eax
40005176:	83 e0 20             	and    $0x20,%eax
40005179:	85 c0                	test   %eax,%eax
4000517b:	74 18                	je     40005195 <open+0x2f>
		va_list ap;
		va_start(ap, flags);
4000517d:	8d 45 0c             	lea    0xc(%ebp),%eax
40005180:	83 c0 04             	add    $0x4,%eax
40005183:	89 45 f0             	mov    %eax,-0x10(%ebp)
		mode = va_arg(ap, mode_t);
40005186:	83 45 f0 04          	addl   $0x4,-0x10(%ebp)
4000518a:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000518d:	83 e8 04             	sub    $0x4,%eax
40005190:	8b 00                	mov    (%eax),%eax
40005192:	89 45 f4             	mov    %eax,-0xc(%ebp)
		va_end(ap);
	}

	filedesc *fd = filedesc_open(NULL, path, flags, mode);
40005195:	8b 45 0c             	mov    0xc(%ebp),%eax
40005198:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000519b:	89 54 24 0c          	mov    %edx,0xc(%esp)
4000519f:	89 44 24 08          	mov    %eax,0x8(%esp)
400051a3:	8b 45 08             	mov    0x8(%ebp),%eax
400051a6:	89 44 24 04          	mov    %eax,0x4(%esp)
400051aa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400051b1:	e8 f9 eb ff ff       	call   40003daf <filedesc_open>
400051b6:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (fd == NULL)
400051b9:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
400051bd:	75 07                	jne    400051c6 <open+0x60>
		return -1;
400051bf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400051c4:	eb 14                	jmp    400051da <open+0x74>

	return fd - files->fd;
400051c6:	8b 55 ec             	mov    -0x14(%ebp),%edx
400051c9:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400051ce:	83 c0 10             	add    $0x10,%eax
400051d1:	89 d1                	mov    %edx,%ecx
400051d3:	29 c1                	sub    %eax,%ecx
400051d5:	89 c8                	mov    %ecx,%eax
400051d7:	c1 f8 04             	sar    $0x4,%eax
}
400051da:	c9                   	leave  
400051db:	c3                   	ret    

400051dc <close>:

int
close(int fn)
{
400051dc:	55                   	push   %ebp
400051dd:	89 e5                	mov    %esp,%ebp
400051df:	83 ec 18             	sub    $0x18,%esp
	filedesc_close(&files->fd[fn]);
400051e2:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400051e7:	8b 55 08             	mov    0x8(%ebp),%edx
400051ea:	83 c2 01             	add    $0x1,%edx
400051ed:	c1 e2 04             	shl    $0x4,%edx
400051f0:	01 d0                	add    %edx,%eax
400051f2:	89 04 24             	mov    %eax,(%esp)
400051f5:	e8 7a f1 ff ff       	call   40004374 <filedesc_close>
	return 0;
400051fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
400051ff:	c9                   	leave  
40005200:	c3                   	ret    

40005201 <read>:

ssize_t
read(int fn, void *buf, size_t nbytes)
{
40005201:	55                   	push   %ebp
40005202:	89 e5                	mov    %esp,%ebp
40005204:	83 ec 18             	sub    $0x18,%esp
	return filedesc_read(&files->fd[fn], buf, 1, nbytes);
40005207:	a1 8c 80 00 40       	mov    0x4000808c,%eax
4000520c:	8b 55 08             	mov    0x8(%ebp),%edx
4000520f:	83 c2 01             	add    $0x1,%edx
40005212:	c1 e2 04             	shl    $0x4,%edx
40005215:	01 c2                	add    %eax,%edx
40005217:	8b 45 10             	mov    0x10(%ebp),%eax
4000521a:	89 44 24 0c          	mov    %eax,0xc(%esp)
4000521e:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40005225:	00 
40005226:	8b 45 0c             	mov    0xc(%ebp),%eax
40005229:	89 44 24 04          	mov    %eax,0x4(%esp)
4000522d:	89 14 24             	mov    %edx,(%esp)
40005230:	e8 a4 ed ff ff       	call   40003fd9 <filedesc_read>
}
40005235:	c9                   	leave  
40005236:	c3                   	ret    

40005237 <write>:

ssize_t
write(int fn, const void *buf, size_t nbytes)
{
40005237:	55                   	push   %ebp
40005238:	89 e5                	mov    %esp,%ebp
4000523a:	83 ec 18             	sub    $0x18,%esp
	return filedesc_write(&files->fd[fn], buf, 1, nbytes);
4000523d:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005242:	8b 55 08             	mov    0x8(%ebp),%edx
40005245:	83 c2 01             	add    $0x1,%edx
40005248:	c1 e2 04             	shl    $0x4,%edx
4000524b:	01 c2                	add    %eax,%edx
4000524d:	8b 45 10             	mov    0x10(%ebp),%eax
40005250:	89 44 24 0c          	mov    %eax,0xc(%esp)
40005254:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
4000525b:	00 
4000525c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000525f:	89 44 24 04          	mov    %eax,0x4(%esp)
40005263:	89 14 24             	mov    %edx,(%esp)
40005266:	e8 83 ee ff ff       	call   400040ee <filedesc_write>
}
4000526b:	c9                   	leave  
4000526c:	c3                   	ret    

4000526d <lseek>:

off_t
lseek(int fn, off_t offset, int whence)
{
4000526d:	55                   	push   %ebp
4000526e:	89 e5                	mov    %esp,%ebp
40005270:	83 ec 18             	sub    $0x18,%esp
	return filedesc_seek(&files->fd[fn], offset, whence);
40005273:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005278:	8b 55 08             	mov    0x8(%ebp),%edx
4000527b:	83 c2 01             	add    $0x1,%edx
4000527e:	c1 e2 04             	shl    $0x4,%edx
40005281:	01 c2                	add    %eax,%edx
40005283:	8b 45 10             	mov    0x10(%ebp),%eax
40005286:	89 44 24 08          	mov    %eax,0x8(%esp)
4000528a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000528d:	89 44 24 04          	mov    %eax,0x4(%esp)
40005291:	89 14 24             	mov    %edx,(%esp)
40005294:	e8 ca ef ff ff       	call   40004263 <filedesc_seek>
}
40005299:	c9                   	leave  
4000529a:	c3                   	ret    

4000529b <dup>:

int
dup(int oldfn)
{
4000529b:	55                   	push   %ebp
4000529c:	89 e5                	mov    %esp,%ebp
4000529e:	83 ec 28             	sub    $0x28,%esp
	filedesc *newfd = filedesc_alloc();
400052a1:	e8 b3 ea ff ff       	call   40003d59 <filedesc_alloc>
400052a6:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (!newfd)
400052a9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
400052ad:	75 07                	jne    400052b6 <dup+0x1b>
		return -1;
400052af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
400052b4:	eb 23                	jmp    400052d9 <dup+0x3e>
	return dup2(oldfn, newfd - files->fd);
400052b6:	8b 55 f4             	mov    -0xc(%ebp),%edx
400052b9:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400052be:	83 c0 10             	add    $0x10,%eax
400052c1:	89 d1                	mov    %edx,%ecx
400052c3:	29 c1                	sub    %eax,%ecx
400052c5:	89 c8                	mov    %ecx,%eax
400052c7:	c1 f8 04             	sar    $0x4,%eax
400052ca:	89 44 24 04          	mov    %eax,0x4(%esp)
400052ce:	8b 45 08             	mov    0x8(%ebp),%eax
400052d1:	89 04 24             	mov    %eax,(%esp)
400052d4:	e8 02 00 00 00       	call   400052db <dup2>
}
400052d9:	c9                   	leave  
400052da:	c3                   	ret    

400052db <dup2>:

int
dup2(int oldfn, int newfn)
{
400052db:	55                   	push   %ebp
400052dc:	89 e5                	mov    %esp,%ebp
400052de:	83 ec 28             	sub    $0x28,%esp
	filedesc *oldfd = &files->fd[oldfn];
400052e1:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400052e6:	8b 55 08             	mov    0x8(%ebp),%edx
400052e9:	83 c2 01             	add    $0x1,%edx
400052ec:	c1 e2 04             	shl    $0x4,%edx
400052ef:	01 d0                	add    %edx,%eax
400052f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
	filedesc *newfd = &files->fd[newfn];
400052f4:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400052f9:	8b 55 0c             	mov    0xc(%ebp),%edx
400052fc:	83 c2 01             	add    $0x1,%edx
400052ff:	c1 e2 04             	shl    $0x4,%edx
40005302:	01 d0                	add    %edx,%eax
40005304:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(filedesc_isopen(oldfd));
40005307:	a1 8c 80 00 40       	mov    0x4000808c,%eax
4000530c:	83 c0 10             	add    $0x10,%eax
4000530f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40005312:	77 18                	ja     4000532c <dup2+0x51>
40005314:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005319:	05 10 10 00 00       	add    $0x1010,%eax
4000531e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40005321:	76 09                	jbe    4000532c <dup2+0x51>
40005323:	8b 45 f4             	mov    -0xc(%ebp),%eax
40005326:	8b 00                	mov    (%eax),%eax
40005328:	85 c0                	test   %eax,%eax
4000532a:	75 24                	jne    40005350 <dup2+0x75>
4000532c:	c7 44 24 0c 98 84 00 	movl   $0x40008498,0xc(%esp)
40005333:	40 
40005334:	c7 44 24 08 af 84 00 	movl   $0x400084af,0x8(%esp)
4000533b:	40 
4000533c:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
40005343:	00 
40005344:	c7 04 24 c4 84 00 40 	movl   $0x400084c4,(%esp)
4000534b:	e8 94 d2 ff ff       	call   400025e4 <debug_panic>
	assert(filedesc_isvalid(newfd));
40005350:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005355:	83 c0 10             	add    $0x10,%eax
40005358:	3b 45 f0             	cmp    -0x10(%ebp),%eax
4000535b:	77 0f                	ja     4000536c <dup2+0x91>
4000535d:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005362:	05 10 10 00 00       	add    $0x1010,%eax
40005367:	3b 45 f0             	cmp    -0x10(%ebp),%eax
4000536a:	77 24                	ja     40005390 <dup2+0xb5>
4000536c:	c7 44 24 0c d1 84 00 	movl   $0x400084d1,0xc(%esp)
40005373:	40 
40005374:	c7 44 24 08 af 84 00 	movl   $0x400084af,0x8(%esp)
4000537b:	40 
4000537c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
40005383:	00 
40005384:	c7 04 24 c4 84 00 40 	movl   $0x400084c4,(%esp)
4000538b:	e8 54 d2 ff ff       	call   400025e4 <debug_panic>

	if (filedesc_isopen(newfd))
40005390:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005395:	83 c0 10             	add    $0x10,%eax
40005398:	3b 45 f0             	cmp    -0x10(%ebp),%eax
4000539b:	77 23                	ja     400053c0 <dup2+0xe5>
4000539d:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400053a2:	05 10 10 00 00       	add    $0x1010,%eax
400053a7:	3b 45 f0             	cmp    -0x10(%ebp),%eax
400053aa:	76 14                	jbe    400053c0 <dup2+0xe5>
400053ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
400053af:	8b 00                	mov    (%eax),%eax
400053b1:	85 c0                	test   %eax,%eax
400053b3:	74 0b                	je     400053c0 <dup2+0xe5>
		close(newfn);
400053b5:	8b 45 0c             	mov    0xc(%ebp),%eax
400053b8:	89 04 24             	mov    %eax,(%esp)
400053bb:	e8 1c fe ff ff       	call   400051dc <close>

	*newfd = *oldfd;
400053c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
400053c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
400053c6:	8b 0a                	mov    (%edx),%ecx
400053c8:	89 08                	mov    %ecx,(%eax)
400053ca:	8b 4a 04             	mov    0x4(%edx),%ecx
400053cd:	89 48 04             	mov    %ecx,0x4(%eax)
400053d0:	8b 4a 08             	mov    0x8(%edx),%ecx
400053d3:	89 48 08             	mov    %ecx,0x8(%eax)
400053d6:	8b 52 0c             	mov    0xc(%edx),%edx
400053d9:	89 50 0c             	mov    %edx,0xc(%eax)

	return newfn;
400053dc:	8b 45 0c             	mov    0xc(%ebp),%eax
}
400053df:	c9                   	leave  
400053e0:	c3                   	ret    

400053e1 <truncate>:

int
truncate(const char *path, off_t newlength)
{
400053e1:	55                   	push   %ebp
400053e2:	89 e5                	mov    %esp,%ebp
400053e4:	83 ec 28             	sub    $0x28,%esp
	int ino = dir_walk(path, 0);
400053e7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400053ee:	00 
400053ef:	8b 45 08             	mov    0x8(%ebp),%eax
400053f2:	89 04 24             	mov    %eax,(%esp)
400053f5:	e8 0e f0 ff ff       	call   40004408 <dir_walk>
400053fa:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (ino < 0)
400053fd:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40005401:	79 07                	jns    4000540a <truncate+0x29>
		return -1;
40005403:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40005408:	eb 12                	jmp    4000541c <truncate+0x3b>
	return fileino_truncate(ino, newlength);
4000540a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000540d:	89 44 24 04          	mov    %eax,0x4(%esp)
40005411:	8b 45 f4             	mov    -0xc(%ebp),%eax
40005414:	89 04 24             	mov    %eax,(%esp)
40005417:	e8 46 e6 ff ff       	call   40003a62 <fileino_truncate>
}
4000541c:	c9                   	leave  
4000541d:	c3                   	ret    

4000541e <ftruncate>:

int
ftruncate(int fn, off_t newlength)
{
4000541e:	55                   	push   %ebp
4000541f:	89 e5                	mov    %esp,%ebp
40005421:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
40005424:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005429:	8b 55 08             	mov    0x8(%ebp),%edx
4000542c:	83 c2 01             	add    $0x1,%edx
4000542f:	c1 e2 04             	shl    $0x4,%edx
40005432:	01 c2                	add    %eax,%edx
40005434:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005439:	83 c0 10             	add    $0x10,%eax
4000543c:	39 c2                	cmp    %eax,%edx
4000543e:	72 34                	jb     40005474 <ftruncate+0x56>
40005440:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005445:	8b 55 08             	mov    0x8(%ebp),%edx
40005448:	83 c2 01             	add    $0x1,%edx
4000544b:	c1 e2 04             	shl    $0x4,%edx
4000544e:	01 c2                	add    %eax,%edx
40005450:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005455:	05 10 10 00 00       	add    $0x1010,%eax
4000545a:	39 c2                	cmp    %eax,%edx
4000545c:	73 16                	jae    40005474 <ftruncate+0x56>
4000545e:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005463:	8b 55 08             	mov    0x8(%ebp),%edx
40005466:	83 c2 01             	add    $0x1,%edx
40005469:	c1 e2 04             	shl    $0x4,%edx
4000546c:	01 d0                	add    %edx,%eax
4000546e:	8b 00                	mov    (%eax),%eax
40005470:	85 c0                	test   %eax,%eax
40005472:	75 24                	jne    40005498 <ftruncate+0x7a>
40005474:	c7 44 24 0c ec 84 00 	movl   $0x400084ec,0xc(%esp)
4000547b:	40 
4000547c:	c7 44 24 08 af 84 00 	movl   $0x400084af,0x8(%esp)
40005483:	40 
40005484:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
4000548b:	00 
4000548c:	c7 04 24 c4 84 00 40 	movl   $0x400084c4,(%esp)
40005493:	e8 4c d1 ff ff       	call   400025e4 <debug_panic>
	return fileino_truncate(files->fd[fn].ino, newlength);
40005498:	a1 8c 80 00 40       	mov    0x4000808c,%eax
4000549d:	8b 55 08             	mov    0x8(%ebp),%edx
400054a0:	83 c2 01             	add    $0x1,%edx
400054a3:	c1 e2 04             	shl    $0x4,%edx
400054a6:	01 d0                	add    %edx,%eax
400054a8:	8b 00                	mov    (%eax),%eax
400054aa:	8b 55 0c             	mov    0xc(%ebp),%edx
400054ad:	89 54 24 04          	mov    %edx,0x4(%esp)
400054b1:	89 04 24             	mov    %eax,(%esp)
400054b4:	e8 a9 e5 ff ff       	call   40003a62 <fileino_truncate>
}
400054b9:	c9                   	leave  
400054ba:	c3                   	ret    

400054bb <isatty>:

int
isatty(int fn)
{
400054bb:	55                   	push   %ebp
400054bc:	89 e5                	mov    %esp,%ebp
400054be:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
400054c1:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400054c6:	8b 55 08             	mov    0x8(%ebp),%edx
400054c9:	83 c2 01             	add    $0x1,%edx
400054cc:	c1 e2 04             	shl    $0x4,%edx
400054cf:	01 c2                	add    %eax,%edx
400054d1:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400054d6:	83 c0 10             	add    $0x10,%eax
400054d9:	39 c2                	cmp    %eax,%edx
400054db:	72 34                	jb     40005511 <isatty+0x56>
400054dd:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400054e2:	8b 55 08             	mov    0x8(%ebp),%edx
400054e5:	83 c2 01             	add    $0x1,%edx
400054e8:	c1 e2 04             	shl    $0x4,%edx
400054eb:	01 c2                	add    %eax,%edx
400054ed:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400054f2:	05 10 10 00 00       	add    $0x1010,%eax
400054f7:	39 c2                	cmp    %eax,%edx
400054f9:	73 16                	jae    40005511 <isatty+0x56>
400054fb:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005500:	8b 55 08             	mov    0x8(%ebp),%edx
40005503:	83 c2 01             	add    $0x1,%edx
40005506:	c1 e2 04             	shl    $0x4,%edx
40005509:	01 d0                	add    %edx,%eax
4000550b:	8b 00                	mov    (%eax),%eax
4000550d:	85 c0                	test   %eax,%eax
4000550f:	75 24                	jne    40005535 <isatty+0x7a>
40005511:	c7 44 24 0c ec 84 00 	movl   $0x400084ec,0xc(%esp)
40005518:	40 
40005519:	c7 44 24 08 af 84 00 	movl   $0x400084af,0x8(%esp)
40005520:	40 
40005521:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
40005528:	00 
40005529:	c7 04 24 c4 84 00 40 	movl   $0x400084c4,(%esp)
40005530:	e8 af d0 ff ff       	call   400025e4 <debug_panic>
	return files->fd[fn].ino == FILEINO_CONSIN
40005535:	a1 8c 80 00 40       	mov    0x4000808c,%eax
4000553a:	8b 55 08             	mov    0x8(%ebp),%edx
4000553d:	83 c2 01             	add    $0x1,%edx
40005540:	c1 e2 04             	shl    $0x4,%edx
40005543:	01 d0                	add    %edx,%eax
40005545:	8b 00                	mov    (%eax),%eax
		|| files->fd[fn].ino == FILEINO_CONSOUT;
40005547:	83 f8 01             	cmp    $0x1,%eax
4000554a:	74 17                	je     40005563 <isatty+0xa8>
4000554c:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005551:	8b 55 08             	mov    0x8(%ebp),%edx
40005554:	83 c2 01             	add    $0x1,%edx
40005557:	c1 e2 04             	shl    $0x4,%edx
4000555a:	01 d0                	add    %edx,%eax
4000555c:	8b 00                	mov    (%eax),%eax
4000555e:	83 f8 02             	cmp    $0x2,%eax
40005561:	75 07                	jne    4000556a <isatty+0xaf>
40005563:	b8 01 00 00 00       	mov    $0x1,%eax
40005568:	eb 05                	jmp    4000556f <isatty+0xb4>
4000556a:	b8 00 00 00 00       	mov    $0x0,%eax
}
4000556f:	c9                   	leave  
40005570:	c3                   	ret    

40005571 <stat>:

int
stat(const char *path, struct stat *statbuf)
{
40005571:	55                   	push   %ebp
40005572:	89 e5                	mov    %esp,%ebp
40005574:	83 ec 28             	sub    $0x28,%esp
	int ino = dir_walk(path, 0);
40005577:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000557e:	00 
4000557f:	8b 45 08             	mov    0x8(%ebp),%eax
40005582:	89 04 24             	mov    %eax,(%esp)
40005585:	e8 7e ee ff ff       	call   40004408 <dir_walk>
4000558a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (ino < 0)
4000558d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40005591:	79 07                	jns    4000559a <stat+0x29>
		return -1;
40005593:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40005598:	eb 12                	jmp    400055ac <stat+0x3b>
	return fileino_stat(ino, statbuf);
4000559a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000559d:	89 44 24 04          	mov    %eax,0x4(%esp)
400055a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
400055a4:	89 04 24             	mov    %eax,(%esp)
400055a7:	e8 91 e3 ff ff       	call   4000393d <fileino_stat>
}
400055ac:	c9                   	leave  
400055ad:	c3                   	ret    

400055ae <fstat>:

int
fstat(int fn, struct stat *statbuf)
{
400055ae:	55                   	push   %ebp
400055af:	89 e5                	mov    %esp,%ebp
400055b1:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
400055b4:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400055b9:	8b 55 08             	mov    0x8(%ebp),%edx
400055bc:	83 c2 01             	add    $0x1,%edx
400055bf:	c1 e2 04             	shl    $0x4,%edx
400055c2:	01 c2                	add    %eax,%edx
400055c4:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400055c9:	83 c0 10             	add    $0x10,%eax
400055cc:	39 c2                	cmp    %eax,%edx
400055ce:	72 34                	jb     40005604 <fstat+0x56>
400055d0:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400055d5:	8b 55 08             	mov    0x8(%ebp),%edx
400055d8:	83 c2 01             	add    $0x1,%edx
400055db:	c1 e2 04             	shl    $0x4,%edx
400055de:	01 c2                	add    %eax,%edx
400055e0:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400055e5:	05 10 10 00 00       	add    $0x1010,%eax
400055ea:	39 c2                	cmp    %eax,%edx
400055ec:	73 16                	jae    40005604 <fstat+0x56>
400055ee:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400055f3:	8b 55 08             	mov    0x8(%ebp),%edx
400055f6:	83 c2 01             	add    $0x1,%edx
400055f9:	c1 e2 04             	shl    $0x4,%edx
400055fc:	01 d0                	add    %edx,%eax
400055fe:	8b 00                	mov    (%eax),%eax
40005600:	85 c0                	test   %eax,%eax
40005602:	75 24                	jne    40005628 <fstat+0x7a>
40005604:	c7 44 24 0c ec 84 00 	movl   $0x400084ec,0xc(%esp)
4000560b:	40 
4000560c:	c7 44 24 08 af 84 00 	movl   $0x400084af,0x8(%esp)
40005613:	40 
40005614:	c7 44 24 04 80 00 00 	movl   $0x80,0x4(%esp)
4000561b:	00 
4000561c:	c7 04 24 c4 84 00 40 	movl   $0x400084c4,(%esp)
40005623:	e8 bc cf ff ff       	call   400025e4 <debug_panic>
	return fileino_stat(files->fd[fn].ino, statbuf);
40005628:	a1 8c 80 00 40       	mov    0x4000808c,%eax
4000562d:	8b 55 08             	mov    0x8(%ebp),%edx
40005630:	83 c2 01             	add    $0x1,%edx
40005633:	c1 e2 04             	shl    $0x4,%edx
40005636:	01 d0                	add    %edx,%eax
40005638:	8b 00                	mov    (%eax),%eax
4000563a:	8b 55 0c             	mov    0xc(%ebp),%edx
4000563d:	89 54 24 04          	mov    %edx,0x4(%esp)
40005641:	89 04 24             	mov    %eax,(%esp)
40005644:	e8 f4 e2 ff ff       	call   4000393d <fileino_stat>
}
40005649:	c9                   	leave  
4000564a:	c3                   	ret    

4000564b <fsync>:

int
fsync(int fn)
{
4000564b:	55                   	push   %ebp
4000564c:	89 e5                	mov    %esp,%ebp
4000564e:	83 ec 18             	sub    $0x18,%esp
	assert(filedesc_isopen(&files->fd[fn]));
40005651:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005656:	8b 55 08             	mov    0x8(%ebp),%edx
40005659:	83 c2 01             	add    $0x1,%edx
4000565c:	c1 e2 04             	shl    $0x4,%edx
4000565f:	01 c2                	add    %eax,%edx
40005661:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005666:	83 c0 10             	add    $0x10,%eax
40005669:	39 c2                	cmp    %eax,%edx
4000566b:	72 34                	jb     400056a1 <fsync+0x56>
4000566d:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005672:	8b 55 08             	mov    0x8(%ebp),%edx
40005675:	83 c2 01             	add    $0x1,%edx
40005678:	c1 e2 04             	shl    $0x4,%edx
4000567b:	01 c2                	add    %eax,%edx
4000567d:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005682:	05 10 10 00 00       	add    $0x1010,%eax
40005687:	39 c2                	cmp    %eax,%edx
40005689:	73 16                	jae    400056a1 <fsync+0x56>
4000568b:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005690:	8b 55 08             	mov    0x8(%ebp),%edx
40005693:	83 c2 01             	add    $0x1,%edx
40005696:	c1 e2 04             	shl    $0x4,%edx
40005699:	01 d0                	add    %edx,%eax
4000569b:	8b 00                	mov    (%eax),%eax
4000569d:	85 c0                	test   %eax,%eax
4000569f:	75 24                	jne    400056c5 <fsync+0x7a>
400056a1:	c7 44 24 0c ec 84 00 	movl   $0x400084ec,0xc(%esp)
400056a8:	40 
400056a9:	c7 44 24 08 af 84 00 	movl   $0x400084af,0x8(%esp)
400056b0:	40 
400056b1:	c7 44 24 04 87 00 00 	movl   $0x87,0x4(%esp)
400056b8:	00 
400056b9:	c7 04 24 c4 84 00 40 	movl   $0x400084c4,(%esp)
400056c0:	e8 1f cf ff ff       	call   400025e4 <debug_panic>
	return fileino_flush(files->fd[fn].ino);
400056c5:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400056ca:	8b 55 08             	mov    0x8(%ebp),%edx
400056cd:	83 c2 01             	add    $0x1,%edx
400056d0:	c1 e2 04             	shl    $0x4,%edx
400056d3:	01 d0                	add    %edx,%eax
400056d5:	8b 00                	mov    (%eax),%eax
400056d7:	89 04 24             	mov    %eax,(%esp)
400056da:	e8 05 e6 ff ff       	call   40003ce4 <fileino_flush>
}
400056df:	c9                   	leave  
400056e0:	c3                   	ret    
400056e1:	66 90                	xchg   %ax,%ax
400056e3:	90                   	nop

400056e4 <fork>:
bool reconcile(pid_t pid, filestate *cfiles);
bool reconcile_inode(pid_t pid, filestate *cfiles, int pino, int cino);
bool reconcile_merge(pid_t pid, filestate *cfiles, int pino, int cino);

pid_t fork(void)
{
400056e4:	55                   	push   %ebp
400056e5:	89 e5                	mov    %esp,%ebp
400056e7:	57                   	push   %edi
400056e8:	56                   	push   %esi
400056e9:	53                   	push   %ebx
400056ea:	81 ec 9c 02 00 00    	sub    $0x29c,%esp
	// even though child slots are process-local in PIOS
	// whereas PIDs are global in Unix.
	// This means that commands like 'ps' and 'kill'
	// have to be shell-builtin commands under PIOS.
	pid_t pid;
	for (pid = 1; pid < 256; pid++)
400056f0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
400056f7:	eb 19                	jmp    40005712 <fork+0x2e>
		if (files->child[pid].state == PROC_FREE)
400056f9:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400056fe:	8b 55 e0             	mov    -0x20(%ebp),%edx
40005701:	81 c2 04 1b 00 00    	add    $0x1b04,%edx
40005707:	8b 04 90             	mov    (%eax,%edx,4),%eax
4000570a:	85 c0                	test   %eax,%eax
4000570c:	74 0f                	je     4000571d <fork+0x39>
	// even though child slots are process-local in PIOS
	// whereas PIDs are global in Unix.
	// This means that commands like 'ps' and 'kill'
	// have to be shell-builtin commands under PIOS.
	pid_t pid;
	for (pid = 1; pid < 256; pid++)
4000570e:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
40005712:	81 7d e0 ff 00 00 00 	cmpl   $0xff,-0x20(%ebp)
40005719:	7e de                	jle    400056f9 <fork+0x15>
4000571b:	eb 01                	jmp    4000571e <fork+0x3a>
		if (files->child[pid].state == PROC_FREE)
			break;
4000571d:	90                   	nop
	if (pid == 256) {
4000571e:	81 7d e0 00 01 00 00 	cmpl   $0x100,-0x20(%ebp)
40005725:	75 31                	jne    40005758 <fork+0x74>
		warn("fork: no child process available");
40005727:	c7 44 24 08 0c 85 00 	movl   $0x4000850c,0x8(%esp)
4000572e:	40 
4000572f:	c7 44 24 04 2c 00 00 	movl   $0x2c,0x4(%esp)
40005736:	00 
40005737:	c7 04 24 2d 85 00 40 	movl   $0x4000852d,(%esp)
4000573e:	e8 0b cf ff ff       	call   4000264e <debug_warn>
		errno = EAGAIN;
40005743:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005748:	c7 00 08 00 00 00    	movl   $0x8,(%eax)
		return -1;
4000574e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40005753:	e9 e1 01 00 00       	jmp    40005939 <fork+0x255>
	}

	// Set up the register state for the child
	struct procstate ps;
	memset(&ps, 0, sizeof(ps));
40005758:	c7 44 24 08 50 02 00 	movl   $0x250,0x8(%esp)
4000575f:	00 
40005760:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40005767:	00 
40005768:	8d 85 68 fd ff ff    	lea    -0x298(%ebp),%eax
4000576e:	89 04 24             	mov    %eax,(%esp)
40005771:	e8 9f d9 ff ff       	call   40003115 <memset>

	// Use some assembly magic to propagate registers to child
	// and generate an appropriate starting eip
	int isparent;
	asm volatile(
40005776:	89 b5 6c fd ff ff    	mov    %esi,-0x294(%ebp)
4000577c:	89 bd 68 fd ff ff    	mov    %edi,-0x298(%ebp)
40005782:	89 ad 70 fd ff ff    	mov    %ebp,-0x290(%ebp)
40005788:	89 a5 ac fd ff ff    	mov    %esp,-0x254(%ebp)
4000578e:	c7 85 a0 fd ff ff 9d 	movl   $0x4000579d,-0x260(%ebp)
40005795:	57 00 40 
40005798:	b8 01 00 00 00       	mov    $0x1,%eax
4000579d:	89 c6                	mov    %eax,%esi
4000579f:	89 75 dc             	mov    %esi,-0x24(%ebp)
		  "=m" (ps.tf.esp),
		  "=m" (ps.tf.eip),
		  "=a" (isparent)
		:
		: "ebx", "ecx", "edx");
	if (!isparent) {
400057a2:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
400057a6:	0f 85 f9 00 00 00    	jne    400058a5 <fork+0x1c1>
		// Clear our child state array, since we have no children yet.
		memset(&files->child, 0, sizeof(files->child));
400057ac:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400057b1:	05 10 6c 00 00       	add    $0x6c10,%eax
400057b6:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
400057bd:	00 
400057be:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400057c5:	00 
400057c6:	89 04 24             	mov    %eax,(%esp)
400057c9:	e8 47 d9 ff ff       	call   40003115 <memset>
		files->child[0].state = PROC_RESERVED;
400057ce:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400057d3:	c7 80 10 6c 00 00 ff 	movl   $0xffffffff,0x6c10(%eax)
400057da:	ff ff ff 
		for (i = 1; i < FILE_INODES; i++)
400057dd:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
400057e4:	e9 a5 00 00 00       	jmp    4000588e <fork+0x1aa>
			if (fileino_alloced(i)) {
400057e9:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
400057ed:	0f 8e 97 00 00 00    	jle    4000588a <fork+0x1a6>
400057f3:	81 7d e4 ff 00 00 00 	cmpl   $0xff,-0x1c(%ebp)
400057fa:	0f 8f 8a 00 00 00    	jg     4000588a <fork+0x1a6>
40005800:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40005806:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40005809:	6b c0 5c             	imul   $0x5c,%eax,%eax
4000580c:	01 d0                	add    %edx,%eax
4000580e:	05 10 10 00 00       	add    $0x1010,%eax
40005813:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40005817:	84 c0                	test   %al,%al
40005819:	74 6f                	je     4000588a <fork+0x1a6>
				files->fi[i].rino = i;	// 1-to-1 mapping
4000581b:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40005821:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40005824:	6b c0 5c             	imul   $0x5c,%eax,%eax
40005827:	01 d0                	add    %edx,%eax
40005829:	8d 90 60 10 00 00    	lea    0x1060(%eax),%edx
4000582f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40005832:	89 02                	mov    %eax,(%edx)
				files->fi[i].rver = files->fi[i].ver;
40005834:	8b 0d 8c 80 00 40    	mov    0x4000808c,%ecx
4000583a:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
40005840:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40005843:	6b c0 5c             	imul   $0x5c,%eax,%eax
40005846:	01 d0                	add    %edx,%eax
40005848:	05 54 10 00 00       	add    $0x1054,%eax
4000584d:	8b 00                	mov    (%eax),%eax
4000584f:	8b 55 e4             	mov    -0x1c(%ebp),%edx
40005852:	6b d2 5c             	imul   $0x5c,%edx,%edx
40005855:	01 ca                	add    %ecx,%edx
40005857:	81 c2 64 10 00 00    	add    $0x1064,%edx
4000585d:	89 02                	mov    %eax,(%edx)
				files->fi[i].rlen = files->fi[i].size;
4000585f:	8b 0d 8c 80 00 40    	mov    0x4000808c,%ecx
40005865:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
4000586b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000586e:	6b c0 5c             	imul   $0x5c,%eax,%eax
40005871:	01 d0                	add    %edx,%eax
40005873:	05 5c 10 00 00       	add    $0x105c,%eax
40005878:	8b 00                	mov    (%eax),%eax
4000587a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
4000587d:	6b d2 5c             	imul   $0x5c,%edx,%edx
40005880:	01 ca                	add    %ecx,%edx
40005882:	81 c2 68 10 00 00    	add    $0x1068,%edx
40005888:	89 02                	mov    %eax,(%edx)
		: "ebx", "ecx", "edx");
	if (!isparent) {
		// Clear our child state array, since we have no children yet.
		memset(&files->child, 0, sizeof(files->child));
		files->child[0].state = PROC_RESERVED;
		for (i = 1; i < FILE_INODES; i++)
4000588a:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
4000588e:	81 7d e4 ff 00 00 00 	cmpl   $0xff,-0x1c(%ebp)
40005895:	0f 8e 4e ff ff ff    	jle    400057e9 <fork+0x105>
				files->fi[i].rino = i;	// 1-to-1 mapping
				files->fi[i].rver = files->fi[i].ver;
				files->fi[i].rlen = files->fi[i].size;
			}

		return 0;	// indicate that we're the child.
4000589b:	b8 00 00 00 00       	mov    $0x0,%eax
400058a0:	e9 94 00 00 00       	jmp    40005939 <fork+0x255>
	}

	// Copy our entire user address space into the child and start it.
	ps.tf.regs.eax = 0;	// isparent == 0 in the child
400058a5:	c7 85 84 fd ff ff 00 	movl   $0x0,-0x27c(%ebp)
400058ac:	00 00 00 
	sys_put(SYS_REGS | SYS_COPY | SYS_START, pid, &ps,
400058af:	8b 45 e0             	mov    -0x20(%ebp),%eax
400058b2:	0f b7 c0             	movzwl %ax,%eax
400058b5:	c7 45 d8 10 10 02 00 	movl   $0x21010,-0x28(%ebp)
400058bc:	66 89 45 d6          	mov    %ax,-0x2a(%ebp)
400058c0:	8d 85 68 fd ff ff    	lea    -0x298(%ebp),%eax
400058c6:	89 45 d0             	mov    %eax,-0x30(%ebp)
400058c9:	c7 45 cc 00 00 00 40 	movl   $0x40000000,-0x34(%ebp)
400058d0:	c7 45 c8 00 00 00 40 	movl   $0x40000000,-0x38(%ebp)
400058d7:	c7 45 c4 00 00 00 b0 	movl   $0xb0000000,-0x3c(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
400058de:	8b 45 d8             	mov    -0x28(%ebp),%eax
400058e1:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400058e4:	8b 5d d0             	mov    -0x30(%ebp),%ebx
400058e7:	0f b7 55 d6          	movzwl -0x2a(%ebp),%edx
400058eb:	8b 75 cc             	mov    -0x34(%ebp),%esi
400058ee:	8b 7d c8             	mov    -0x38(%ebp),%edi
400058f1:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
400058f4:	cd 30                	int    $0x30
		ALLVA, ALLVA, ALLSIZE);

	// Record the inode generation numbers of all inodes at fork time,
	// so that we can reconcile them later when we synchronize with it.
	memset(&files->child[pid], 0, sizeof(files->child[pid]));
400058f6:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400058fb:	8b 55 e0             	mov    -0x20(%ebp),%edx
400058fe:	81 c2 04 1b 00 00    	add    $0x1b04,%edx
40005904:	c1 e2 02             	shl    $0x2,%edx
40005907:	01 d0                	add    %edx,%eax
40005909:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
40005910:	00 
40005911:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40005918:	00 
40005919:	89 04 24             	mov    %eax,(%esp)
4000591c:	e8 f4 d7 ff ff       	call   40003115 <memset>
	files->child[pid].state = PROC_FORKED;
40005921:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005926:	8b 55 e0             	mov    -0x20(%ebp),%edx
40005929:	81 c2 04 1b 00 00    	add    $0x1b04,%edx
4000592f:	c7 04 90 01 00 00 00 	movl   $0x1,(%eax,%edx,4)

	return pid;
40005936:	8b 45 e0             	mov    -0x20(%ebp),%eax
}
40005939:	81 c4 9c 02 00 00    	add    $0x29c,%esp
4000593f:	5b                   	pop    %ebx
40005940:	5e                   	pop    %esi
40005941:	5f                   	pop    %edi
40005942:	5d                   	pop    %ebp
40005943:	c3                   	ret    

40005944 <wait>:

pid_t
wait(int *status)
{
40005944:	55                   	push   %ebp
40005945:	89 e5                	mov    %esp,%ebp
40005947:	83 ec 18             	sub    $0x18,%esp
	return waitpid(-1, status, 0);
4000594a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
40005951:	00 
40005952:	8b 45 08             	mov    0x8(%ebp),%eax
40005955:	89 44 24 04          	mov    %eax,0x4(%esp)
40005959:	c7 04 24 ff ff ff ff 	movl   $0xffffffff,(%esp)
40005960:	e8 02 00 00 00       	call   40005967 <waitpid>
}
40005965:	c9                   	leave  
40005966:	c3                   	ret    

40005967 <waitpid>:

pid_t
waitpid(pid_t pid, int *status, int options)
{
40005967:	55                   	push   %ebp
40005968:	89 e5                	mov    %esp,%ebp
4000596a:	57                   	push   %edi
4000596b:	56                   	push   %esi
4000596c:	53                   	push   %ebx
4000596d:	81 ec cc 02 00 00    	sub    $0x2cc,%esp
	assert(pid >= -1 && pid < 256);
40005973:	83 7d 08 ff          	cmpl   $0xffffffff,0x8(%ebp)
40005977:	7c 09                	jl     40005982 <waitpid+0x1b>
40005979:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
40005980:	7e 24                	jle    400059a6 <waitpid+0x3f>
40005982:	c7 44 24 0c 38 85 00 	movl   $0x40008538,0xc(%esp)
40005989:	40 
4000598a:	c7 44 24 08 4f 85 00 	movl   $0x4000854f,0x8(%esp)
40005991:	40 
40005992:	c7 44 24 04 6c 00 00 	movl   $0x6c,0x4(%esp)
40005999:	00 
4000599a:	c7 04 24 2d 85 00 40 	movl   $0x4000852d,(%esp)
400059a1:	e8 3e cc ff ff       	call   400025e4 <debug_panic>
	// Find a process to wait for.
	// Of course for interactive or load-balancing purposes
	// we would like to have a way to wait for
	// whichever child process happens to finish first -
	// that requires a (nondeterministic) kernel API extension.
	if (pid <= 0)
400059a6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400059aa:	7f 2f                	jg     400059db <waitpid+0x74>
		for (pid = 1; pid < 256; pid++)
400059ac:	c7 45 08 01 00 00 00 	movl   $0x1,0x8(%ebp)
400059b3:	eb 1a                	jmp    400059cf <waitpid+0x68>
			if (files->child[pid].state == PROC_FORKED)
400059b5:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400059ba:	8b 55 08             	mov    0x8(%ebp),%edx
400059bd:	81 c2 04 1b 00 00    	add    $0x1b04,%edx
400059c3:	8b 04 90             	mov    (%eax,%edx,4),%eax
400059c6:	83 f8 01             	cmp    $0x1,%eax
400059c9:	74 0f                	je     400059da <waitpid+0x73>
	// Of course for interactive or load-balancing purposes
	// we would like to have a way to wait for
	// whichever child process happens to finish first -
	// that requires a (nondeterministic) kernel API extension.
	if (pid <= 0)
		for (pid = 1; pid < 256; pid++)
400059cb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400059cf:	81 7d 08 ff 00 00 00 	cmpl   $0xff,0x8(%ebp)
400059d6:	7e dd                	jle    400059b5 <waitpid+0x4e>
400059d8:	eb 01                	jmp    400059db <waitpid+0x74>
			if (files->child[pid].state == PROC_FORKED)
				break;
400059da:	90                   	nop
	if (pid == 256 || files->child[pid].state != PROC_FORKED) {
400059db:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
400059e2:	74 16                	je     400059fa <waitpid+0x93>
400059e4:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400059e9:	8b 55 08             	mov    0x8(%ebp),%edx
400059ec:	81 c2 04 1b 00 00    	add    $0x1b04,%edx
400059f2:	8b 04 90             	mov    (%eax,%edx,4),%eax
400059f5:	83 f8 01             	cmp    $0x1,%eax
400059f8:	74 15                	je     40005a0f <waitpid+0xa8>
		errno = ECHILD;
400059fa:	a1 8c 80 00 40       	mov    0x4000808c,%eax
400059ff:	c7 00 09 00 00 00    	movl   $0x9,(%eax)
		return -1;
40005a05:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40005a0a:	e9 bb 01 00 00       	jmp    40005bca <waitpid+0x263>
	// Repeatedly synchronize with the chosen child until it exits.
	while (1) {
		// Wait for the child to finish whatever it's doing,
		// and extract its CPU and process/file state.
		struct procstate ps;
		sys_get(SYS_COPY | SYS_REGS, pid, &ps,
40005a0f:	8b 45 08             	mov    0x8(%ebp),%eax
40005a12:	0f b7 c0             	movzwl %ax,%eax
40005a15:	c7 45 dc 00 10 02 00 	movl   $0x21000,-0x24(%ebp)
40005a1c:	66 89 45 da          	mov    %ax,-0x26(%ebp)
40005a20:	8d 85 48 fd ff ff    	lea    -0x2b8(%ebp),%eax
40005a26:	89 45 d4             	mov    %eax,-0x2c(%ebp)
40005a29:	c7 45 d0 00 00 00 80 	movl   $0x80000000,-0x30(%ebp)
40005a30:	c7 45 cc 00 00 00 c0 	movl   $0xc0000000,-0x34(%ebp)
40005a37:	c7 45 c8 00 00 40 00 	movl   $0x400000,-0x38(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40005a3e:	8b 45 dc             	mov    -0x24(%ebp),%eax
40005a41:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40005a44:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
40005a47:	0f b7 55 da          	movzwl -0x26(%ebp),%edx
40005a4b:	8b 75 d0             	mov    -0x30(%ebp),%esi
40005a4e:	8b 7d cc             	mov    -0x34(%ebp),%edi
40005a51:	8b 4d c8             	mov    -0x38(%ebp),%ecx
40005a54:	cd 30                	int    $0x30
			(void*)FILESVA, (void*)VM_SCRATCHLO, PTSIZE);
		filestate *cfiles = (filestate*)VM_SCRATCHLO;
40005a56:	c7 45 e4 00 00 00 c0 	movl   $0xc0000000,-0x1c(%ebp)

		// Did the child take a trap?
		if (ps.tf.trapno != T_SYSCALL) {
40005a5d:	8b 85 78 fd ff ff    	mov    -0x288(%ebp),%eax
40005a63:	83 f8 30             	cmp    $0x30,%eax
40005a66:	0f 84 b2 00 00 00    	je     40005b1e <waitpid+0x1b7>
			// Yes - terminate the child WITHOUT reconciling,
			// since the child's results are probably invalid.
			warn("child %d took trap %d, eip %x\n",
40005a6c:	8b 95 80 fd ff ff    	mov    -0x280(%ebp),%edx
40005a72:	8b 85 78 fd ff ff    	mov    -0x288(%ebp),%eax
40005a78:	89 54 24 14          	mov    %edx,0x14(%esp)
40005a7c:	89 44 24 10          	mov    %eax,0x10(%esp)
40005a80:	8b 45 08             	mov    0x8(%ebp),%eax
40005a83:	89 44 24 0c          	mov    %eax,0xc(%esp)
40005a87:	c7 44 24 08 64 85 00 	movl   $0x40008564,0x8(%esp)
40005a8e:	40 
40005a8f:	c7 44 24 04 8a 00 00 	movl   $0x8a,0x4(%esp)
40005a96:	00 
40005a97:	c7 04 24 2d 85 00 40 	movl   $0x4000852d,(%esp)
40005a9e:	e8 ab cb ff ff       	call   4000264e <debug_warn>
				pid, ps.tf.trapno, ps.tf.eip);
			if (status != NULL)
40005aa3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40005aa7:	74 13                	je     40005abc <waitpid+0x155>
				*status = WSIGNALED | ps.tf.trapno;
40005aa9:	8b 85 78 fd ff ff    	mov    -0x288(%ebp),%eax
40005aaf:	80 cc 02             	or     $0x2,%ah
40005ab2:	89 c2                	mov    %eax,%edx
40005ab4:	8b 45 0c             	mov    0xc(%ebp),%eax
40005ab7:	89 10                	mov    %edx,(%eax)
40005ab9:	eb 01                	jmp    40005abc <waitpid+0x155>

		// Has the child exited gracefully?
		if (cfiles->exited) {
			if (status != NULL)
				*status = WEXITED | (cfiles->status & 0xff);
			goto done;
40005abb:	90                   	nop
			if (status != NULL)
				*status = WSIGNALED | ps.tf.trapno;

			done:
			// Clear out the child's address space.
			sys_put(SYS_ZERO, pid, NULL, ALLVA, ALLVA, ALLSIZE);
40005abc:	8b 45 08             	mov    0x8(%ebp),%eax
40005abf:	0f b7 c0             	movzwl %ax,%eax
40005ac2:	c7 45 c4 00 00 01 00 	movl   $0x10000,-0x3c(%ebp)
40005ac9:	66 89 45 c2          	mov    %ax,-0x3e(%ebp)
40005acd:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
40005ad4:	c7 45 b8 00 00 00 40 	movl   $0x40000000,-0x48(%ebp)
40005adb:	c7 45 b4 00 00 00 40 	movl   $0x40000000,-0x4c(%ebp)
40005ae2:	c7 45 b0 00 00 00 b0 	movl   $0xb0000000,-0x50(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40005ae9:	8b 45 c4             	mov    -0x3c(%ebp),%eax
40005aec:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40005aef:	8b 5d bc             	mov    -0x44(%ebp),%ebx
40005af2:	0f b7 55 c2          	movzwl -0x3e(%ebp),%edx
40005af6:	8b 75 b8             	mov    -0x48(%ebp),%esi
40005af9:	8b 7d b4             	mov    -0x4c(%ebp),%edi
40005afc:	8b 4d b0             	mov    -0x50(%ebp),%ecx
40005aff:	cd 30                	int    $0x30
			files->child[pid].state = PROC_FREE;
40005b01:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005b06:	8b 55 08             	mov    0x8(%ebp),%edx
40005b09:	81 c2 04 1b 00 00    	add    $0x1b04,%edx
40005b0f:	c7 04 90 00 00 00 00 	movl   $0x0,(%eax,%edx,4)
			return pid;
40005b16:	8b 45 08             	mov    0x8(%ebp),%eax
40005b19:	e9 ac 00 00 00       	jmp    40005bca <waitpid+0x263>
		}

		// Reconcile our file system state with the child's.
		bool didio = reconcile(pid, cfiles);
40005b1e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40005b21:	89 44 24 04          	mov    %eax,0x4(%esp)
40005b25:	8b 45 08             	mov    0x8(%ebp),%eax
40005b28:	89 04 24             	mov    %eax,(%esp)
40005b2b:	e8 a5 00 00 00       	call   40005bd5 <reconcile>
40005b30:	89 45 e0             	mov    %eax,-0x20(%ebp)

		// Has the child exited gracefully?
		if (cfiles->exited) {
40005b33:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40005b36:	8b 40 08             	mov    0x8(%eax),%eax
40005b39:	85 c0                	test   %eax,%eax
40005b3b:	74 24                	je     40005b61 <waitpid+0x1fa>
			if (status != NULL)
40005b3d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40005b41:	0f 84 74 ff ff ff    	je     40005abb <waitpid+0x154>
				*status = WEXITED | (cfiles->status & 0xff);
40005b47:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40005b4a:	8b 40 0c             	mov    0xc(%eax),%eax
40005b4d:	25 ff 00 00 00       	and    $0xff,%eax
40005b52:	89 c2                	mov    %eax,%edx
40005b54:	80 ce 01             	or     $0x1,%dh
40005b57:	8b 45 0c             	mov    0xc(%ebp),%eax
40005b5a:	89 10                	mov    %edx,(%eax)
			goto done;
40005b5c:	e9 5a ff ff ff       	jmp    40005abb <waitpid+0x154>
		}

		// If the child is waiting for new input
		// and the reconciliation above didn't provide anything new,
		// then wait for something new from OUR parent in turn.
		if (!didio)
40005b61:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
40005b65:	75 07                	jne    40005b6e <waitpid+0x207>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40005b67:	b8 03 00 00 00       	mov    $0x3,%eax
40005b6c:	cd 30                	int    $0x30
			sys_ret();

		// Reconcile again, to forward any new I/O to the child.
		(void)reconcile(pid, cfiles);
40005b6e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40005b71:	89 44 24 04          	mov    %eax,0x4(%esp)
40005b75:	8b 45 08             	mov    0x8(%ebp),%eax
40005b78:	89 04 24             	mov    %eax,(%esp)
40005b7b:	e8 55 00 00 00       	call   40005bd5 <reconcile>

		// Push the child's updated file state back into the child.
		sys_put(SYS_COPY | SYS_START, pid, NULL,
40005b80:	8b 45 08             	mov    0x8(%ebp),%eax
40005b83:	0f b7 c0             	movzwl %ax,%eax
40005b86:	c7 45 ac 10 00 02 00 	movl   $0x20010,-0x54(%ebp)
40005b8d:	66 89 45 aa          	mov    %ax,-0x56(%ebp)
40005b91:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
40005b98:	c7 45 a0 00 00 00 c0 	movl   $0xc0000000,-0x60(%ebp)
40005b9f:	c7 45 9c 00 00 00 80 	movl   $0x80000000,-0x64(%ebp)
40005ba6:	c7 45 98 00 00 40 00 	movl   $0x400000,-0x68(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40005bad:	8b 45 ac             	mov    -0x54(%ebp),%eax
40005bb0:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40005bb3:	8b 5d a4             	mov    -0x5c(%ebp),%ebx
40005bb6:	0f b7 55 aa          	movzwl -0x56(%ebp),%edx
40005bba:	8b 75 a0             	mov    -0x60(%ebp),%esi
40005bbd:	8b 7d 9c             	mov    -0x64(%ebp),%edi
40005bc0:	8b 4d 98             	mov    -0x68(%ebp),%ecx
40005bc3:	cd 30                	int    $0x30
			(void*)VM_SCRATCHLO, (void*)FILESVA, PTSIZE);
	}
40005bc5:	e9 45 fe ff ff       	jmp    40005a0f <waitpid+0xa8>
}
40005bca:	81 c4 cc 02 00 00    	add    $0x2cc,%esp
40005bd0:	5b                   	pop    %ebx
40005bd1:	5e                   	pop    %esi
40005bd2:	5f                   	pop    %edi
40005bd3:	5d                   	pop    %ebp
40005bd4:	c3                   	ret    

40005bd5 <reconcile>:
// Reconcile our file system state, whose metadata is in 'files',
// with the file system state of child 'pid', whose metadata is in 'cfiles'.
// Returns nonzero if any changes were propagated, false otherwise.
bool
reconcile(pid_t pid, filestate *cfiles)
{
40005bd5:	55                   	push   %ebp
40005bd6:	89 e5                	mov    %esp,%ebp
40005bd8:	57                   	push   %edi
40005bd9:	56                   	push   %esi
40005bda:	53                   	push   %ebx
40005bdb:	81 ec 6c 08 00 00    	sub    $0x86c,%esp
	bool didio = 0;
40005be1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	int i;

	// Compute a parent-to-child and child-to-parent inode mapping table.
	int p2c[FILE_INODES], c2p[FILE_INODES];
	memset(p2c, 0, sizeof(p2c)); memset(c2p, 0, sizeof(c2p));
40005be8:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
40005bef:	00 
40005bf0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40005bf7:	00 
40005bf8:	8d 85 cc fb ff ff    	lea    -0x434(%ebp),%eax
40005bfe:	89 04 24             	mov    %eax,(%esp)
40005c01:	e8 0f d5 ff ff       	call   40003115 <memset>
40005c06:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
40005c0d:	00 
40005c0e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40005c15:	00 
40005c16:	8d 85 cc f7 ff ff    	lea    -0x834(%ebp),%eax
40005c1c:	89 04 24             	mov    %eax,(%esp)
40005c1f:	e8 f1 d4 ff ff       	call   40003115 <memset>
	p2c[FILEINO_CONSIN] = c2p[FILEINO_CONSIN] = FILEINO_CONSIN;
40005c24:	c7 85 d0 f7 ff ff 01 	movl   $0x1,-0x830(%ebp)
40005c2b:	00 00 00 
40005c2e:	8b 85 d0 f7 ff ff    	mov    -0x830(%ebp),%eax
40005c34:	89 85 d0 fb ff ff    	mov    %eax,-0x430(%ebp)
	p2c[FILEINO_CONSOUT] = c2p[FILEINO_CONSOUT] = FILEINO_CONSOUT;
40005c3a:	c7 85 d4 f7 ff ff 02 	movl   $0x2,-0x82c(%ebp)
40005c41:	00 00 00 
40005c44:	8b 85 d4 f7 ff ff    	mov    -0x82c(%ebp),%eax
40005c4a:	89 85 d4 fb ff ff    	mov    %eax,-0x42c(%ebp)
	p2c[FILEINO_ROOTDIR] = c2p[FILEINO_ROOTDIR] = FILEINO_ROOTDIR;
40005c50:	c7 85 d8 f7 ff ff 03 	movl   $0x3,-0x828(%ebp)
40005c57:	00 00 00 
40005c5a:	8b 85 d8 f7 ff ff    	mov    -0x828(%ebp),%eax
40005c60:	89 85 d8 fb ff ff    	mov    %eax,-0x428(%ebp)

	// First make sure all the child's allocated inodes
	// have a mapping in the parent, creating mappings as needed.
	// Also keep track of the parent inodes we find mappings for.
	int cino;
	for (cino = 1; cino < FILE_INODES; cino++) {
40005c66:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
40005c6d:	e9 f3 01 00 00       	jmp    40005e65 <reconcile+0x290>
		fileinode *cfi = &cfiles->fi[cino];
40005c72:	8b 45 e0             	mov    -0x20(%ebp),%eax
40005c75:	6b c0 5c             	imul   $0x5c,%eax,%eax
40005c78:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40005c7e:	8b 45 0c             	mov    0xc(%ebp),%eax
40005c81:	01 d0                	add    %edx,%eax
40005c83:	89 45 d8             	mov    %eax,-0x28(%ebp)
		if (cfi->de.d_name[0] == 0)
40005c86:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005c89:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40005c8d:	84 c0                	test   %al,%al
40005c8f:	0f 84 c5 01 00 00    	je     40005e5a <reconcile+0x285>
			continue;	// not allocated in the child
		if (cfi->mode == 0 && cfi->rino == 0)
40005c95:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005c98:	8b 40 48             	mov    0x48(%eax),%eax
40005c9b:	85 c0                	test   %eax,%eax
40005c9d:	75 0e                	jne    40005cad <reconcile+0xd8>
40005c9f:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005ca2:	8b 40 50             	mov    0x50(%eax),%eax
40005ca5:	85 c0                	test   %eax,%eax
40005ca7:	0f 84 b0 01 00 00    	je     40005e5d <reconcile+0x288>
			continue;	// existed only ephemerally in child
		if (cfi->rino == 0) {
40005cad:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005cb0:	8b 40 50             	mov    0x50(%eax),%eax
40005cb3:	85 c0                	test   %eax,%eax
40005cb5:	0f 85 88 00 00 00    	jne    40005d43 <reconcile+0x16e>
			// No corresponding parent inode known: find/create one.
			// The parent directory should already have a mapping.
			if (cfi->dino <= 0 || cfi->dino >= FILE_INODES
40005cbb:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005cbe:	8b 00                	mov    (%eax),%eax
40005cc0:	85 c0                	test   %eax,%eax
40005cc2:	7e 1c                	jle    40005ce0 <reconcile+0x10b>
40005cc4:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005cc7:	8b 00                	mov    (%eax),%eax
40005cc9:	3d ff 00 00 00       	cmp    $0xff,%eax
40005cce:	7f 10                	jg     40005ce0 <reconcile+0x10b>
				|| c2p[cfi->dino] == 0) {
40005cd0:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005cd3:	8b 00                	mov    (%eax),%eax
40005cd5:	8b 84 85 cc f7 ff ff 	mov    -0x834(%ebp,%eax,4),%eax
40005cdc:	85 c0                	test   %eax,%eax
40005cde:	75 28                	jne    40005d08 <reconcile+0x133>
				warn("reconcile: cino %d has invalid parent",
40005ce0:	8b 45 e0             	mov    -0x20(%ebp),%eax
40005ce3:	89 44 24 0c          	mov    %eax,0xc(%esp)
40005ce7:	c7 44 24 08 84 85 00 	movl   $0x40008584,0x8(%esp)
40005cee:	40 
40005cef:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
40005cf6:	00 
40005cf7:	c7 04 24 2d 85 00 40 	movl   $0x4000852d,(%esp)
40005cfe:	e8 4b c9 ff ff       	call   4000264e <debug_warn>
					cino);
				continue;	// don't reconcile it
40005d03:	e9 59 01 00 00       	jmp    40005e61 <reconcile+0x28c>
			}
			cfi->rino = fileino_create(files, c2p[cfi->dino],
							cfi->de.d_name);
40005d08:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005d0b:	8d 48 04             	lea    0x4(%eax),%ecx
				|| c2p[cfi->dino] == 0) {
				warn("reconcile: cino %d has invalid parent",
					cino);
				continue;	// don't reconcile it
			}
			cfi->rino = fileino_create(files, c2p[cfi->dino],
40005d0e:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005d11:	8b 00                	mov    (%eax),%eax
40005d13:	8b 94 85 cc f7 ff ff 	mov    -0x834(%ebp,%eax,4),%edx
40005d1a:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005d1f:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40005d23:	89 54 24 04          	mov    %edx,0x4(%esp)
40005d27:	89 04 24             	mov    %eax,(%esp)
40005d2a:	e8 4f d6 ff ff       	call   4000337e <fileino_create>
40005d2f:	8b 55 d8             	mov    -0x28(%ebp),%edx
40005d32:	89 42 50             	mov    %eax,0x50(%edx)
							cfi->de.d_name);
			if (cfi->rino <= 0)
40005d35:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005d38:	8b 40 50             	mov    0x50(%eax),%eax
40005d3b:	85 c0                	test   %eax,%eax
40005d3d:	0f 8e 1d 01 00 00    	jle    40005e60 <reconcile+0x28b>
		}

		// Check the validity of the child's existing mapping.
		// If something's fishy, just don't reconcile it,
		// since we don't want the child to kill the parent this way.
		int pino = cfi->rino;
40005d43:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005d46:	8b 40 50             	mov    0x50(%eax),%eax
40005d49:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		fileinode *pfi = &files->fi[pino];
40005d4c:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005d51:	8b 55 d4             	mov    -0x2c(%ebp),%edx
40005d54:	6b d2 5c             	imul   $0x5c,%edx,%edx
40005d57:	81 c2 10 10 00 00    	add    $0x1010,%edx
40005d5d:	01 d0                	add    %edx,%eax
40005d5f:	89 45 d0             	mov    %eax,-0x30(%ebp)
		if (pino <= 0 || pino >= FILE_INODES
40005d62:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
40005d66:	7e 5a                	jle    40005dc2 <reconcile+0x1ed>
40005d68:	81 7d d4 ff 00 00 00 	cmpl   $0xff,-0x2c(%ebp)
40005d6f:	7f 51                	jg     40005dc2 <reconcile+0x1ed>
				|| p2c[pfi->dino] != cfi->dino
40005d71:	8b 45 d0             	mov    -0x30(%ebp),%eax
40005d74:	8b 00                	mov    (%eax),%eax
40005d76:	8b 94 85 cc fb ff ff 	mov    -0x434(%ebp,%eax,4),%edx
40005d7d:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005d80:	8b 00                	mov    (%eax),%eax
40005d82:	39 c2                	cmp    %eax,%edx
40005d84:	75 3c                	jne    40005dc2 <reconcile+0x1ed>
				|| strcmp(pfi->de.d_name, cfi->de.d_name) != 0
40005d86:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005d89:	8d 50 04             	lea    0x4(%eax),%edx
40005d8c:	8b 45 d0             	mov    -0x30(%ebp),%eax
40005d8f:	83 c0 04             	add    $0x4,%eax
40005d92:	89 54 24 04          	mov    %edx,0x4(%esp)
40005d96:	89 04 24             	mov    %eax,(%esp)
40005d99:	e8 a6 d2 ff ff       	call   40003044 <strcmp>
40005d9e:	85 c0                	test   %eax,%eax
40005da0:	75 20                	jne    40005dc2 <reconcile+0x1ed>
				|| cfi->rver > pfi->ver
40005da2:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005da5:	8b 50 54             	mov    0x54(%eax),%edx
40005da8:	8b 45 d0             	mov    -0x30(%ebp),%eax
40005dab:	8b 40 44             	mov    0x44(%eax),%eax
40005dae:	39 c2                	cmp    %eax,%edx
40005db0:	7f 10                	jg     40005dc2 <reconcile+0x1ed>
				|| cfi->rver > cfi->ver) {
40005db2:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005db5:	8b 50 54             	mov    0x54(%eax),%edx
40005db8:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005dbb:	8b 40 44             	mov    0x44(%eax),%eax
40005dbe:	39 c2                	cmp    %eax,%edx
40005dc0:	7e 7c                	jle    40005e3e <reconcile+0x269>
			warn("reconcile: mapping %d/%d: "
40005dc2:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005dc5:	8b 70 54             	mov    0x54(%eax),%esi
40005dc8:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005dcb:	8b 58 44             	mov    0x44(%eax),%ebx
40005dce:	8b 45 d0             	mov    -0x30(%ebp),%eax
40005dd1:	8b 48 44             	mov    0x44(%eax),%ecx
40005dd4:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005dd7:	83 c0 04             	add    $0x4,%eax
40005dda:	89 85 c4 f7 ff ff    	mov    %eax,-0x83c(%ebp)
40005de0:	8b 45 d0             	mov    -0x30(%ebp),%eax
40005de3:	8d 78 04             	lea    0x4(%eax),%edi
40005de6:	8b 45 d8             	mov    -0x28(%ebp),%eax
40005de9:	8b 10                	mov    (%eax),%edx
40005deb:	8b 45 d0             	mov    -0x30(%ebp),%eax
40005dee:	8b 00                	mov    (%eax),%eax
40005df0:	89 74 24 2c          	mov    %esi,0x2c(%esp)
40005df4:	89 5c 24 28          	mov    %ebx,0x28(%esp)
40005df8:	89 4c 24 24          	mov    %ecx,0x24(%esp)
40005dfc:	8b 8d c4 f7 ff ff    	mov    -0x83c(%ebp),%ecx
40005e02:	89 4c 24 20          	mov    %ecx,0x20(%esp)
40005e06:	89 7c 24 1c          	mov    %edi,0x1c(%esp)
40005e0a:	89 54 24 18          	mov    %edx,0x18(%esp)
40005e0e:	89 44 24 14          	mov    %eax,0x14(%esp)
40005e12:	8b 45 e0             	mov    -0x20(%ebp),%eax
40005e15:	89 44 24 10          	mov    %eax,0x10(%esp)
40005e19:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40005e1c:	89 44 24 0c          	mov    %eax,0xc(%esp)
40005e20:	c7 44 24 08 ac 85 00 	movl   $0x400085ac,0x8(%esp)
40005e27:	40 
40005e28:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
40005e2f:	00 
40005e30:	c7 04 24 2d 85 00 40 	movl   $0x4000852d,(%esp)
40005e37:	e8 12 c8 ff ff       	call   4000264e <debug_warn>
				"dir %d/%d name %s/%s ver %d/%d(%d)",
				pino, cino, pfi->dino, cfi->dino,
				pfi->de.d_name, cfi->de.d_name,
				pfi->ver, cfi->ver, cfi->rver);
			continue;
40005e3c:	eb 23                	jmp    40005e61 <reconcile+0x28c>
		}

		// Record the mapping.
		p2c[pino] = cino;
40005e3e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40005e41:	8b 55 e0             	mov    -0x20(%ebp),%edx
40005e44:	89 94 85 cc fb ff ff 	mov    %edx,-0x434(%ebp,%eax,4)
		c2p[cino] = pino;
40005e4b:	8b 45 e0             	mov    -0x20(%ebp),%eax
40005e4e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
40005e51:	89 94 85 cc f7 ff ff 	mov    %edx,-0x834(%ebp,%eax,4)
40005e58:	eb 07                	jmp    40005e61 <reconcile+0x28c>
	// Also keep track of the parent inodes we find mappings for.
	int cino;
	for (cino = 1; cino < FILE_INODES; cino++) {
		fileinode *cfi = &cfiles->fi[cino];
		if (cfi->de.d_name[0] == 0)
			continue;	// not allocated in the child
40005e5a:	90                   	nop
40005e5b:	eb 04                	jmp    40005e61 <reconcile+0x28c>
		if (cfi->mode == 0 && cfi->rino == 0)
			continue;	// existed only ephemerally in child
40005e5d:	90                   	nop
40005e5e:	eb 01                	jmp    40005e61 <reconcile+0x28c>
				continue;	// don't reconcile it
			}
			cfi->rino = fileino_create(files, c2p[cfi->dino],
							cfi->de.d_name);
			if (cfi->rino <= 0)
				continue;	// no free inodes!
40005e60:	90                   	nop

	// First make sure all the child's allocated inodes
	// have a mapping in the parent, creating mappings as needed.
	// Also keep track of the parent inodes we find mappings for.
	int cino;
	for (cino = 1; cino < FILE_INODES; cino++) {
40005e61:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
40005e65:	81 7d e0 ff 00 00 00 	cmpl   $0xff,-0x20(%ebp)
40005e6c:	0f 8e 00 fe ff ff    	jle    40005c72 <reconcile+0x9d>
	}

	// Now make sure all the parent's allocated inodes
	// have a mapping in the child, creating mappings as needed.
	int pino;
	for (pino = 1; pino < FILE_INODES; pino++) {
40005e72:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
40005e79:	e9 a4 00 00 00       	jmp    40005f22 <reconcile+0x34d>
		fileinode *pfi = &files->fi[pino];
40005e7e:	a1 8c 80 00 40       	mov    0x4000808c,%eax
40005e83:	8b 55 dc             	mov    -0x24(%ebp),%edx
40005e86:	6b d2 5c             	imul   $0x5c,%edx,%edx
40005e89:	81 c2 10 10 00 00    	add    $0x1010,%edx
40005e8f:	01 d0                	add    %edx,%eax
40005e91:	89 45 cc             	mov    %eax,-0x34(%ebp)
		if (pfi->de.d_name[0] == 0 || pfi->mode == 0)
40005e94:	8b 45 cc             	mov    -0x34(%ebp),%eax
40005e97:	0f b6 40 04          	movzbl 0x4(%eax),%eax
40005e9b:	84 c0                	test   %al,%al
40005e9d:	74 78                	je     40005f17 <reconcile+0x342>
40005e9f:	8b 45 cc             	mov    -0x34(%ebp),%eax
40005ea2:	8b 40 48             	mov    0x48(%eax),%eax
40005ea5:	85 c0                	test   %eax,%eax
40005ea7:	74 6e                	je     40005f17 <reconcile+0x342>
			continue; // not in use or already deleted
		if (p2c[pino] != 0)
40005ea9:	8b 45 dc             	mov    -0x24(%ebp),%eax
40005eac:	8b 84 85 cc fb ff ff 	mov    -0x434(%ebp,%eax,4),%eax
40005eb3:	85 c0                	test   %eax,%eax
40005eb5:	75 63                	jne    40005f1a <reconcile+0x345>
			continue; // already mapped
		cino = fileino_create(cfiles, p2c[pfi->dino], pfi->de.d_name);
40005eb7:	8b 45 cc             	mov    -0x34(%ebp),%eax
40005eba:	8d 50 04             	lea    0x4(%eax),%edx
40005ebd:	8b 45 cc             	mov    -0x34(%ebp),%eax
40005ec0:	8b 00                	mov    (%eax),%eax
40005ec2:	8b 84 85 cc fb ff ff 	mov    -0x434(%ebp,%eax,4),%eax
40005ec9:	89 54 24 08          	mov    %edx,0x8(%esp)
40005ecd:	89 44 24 04          	mov    %eax,0x4(%esp)
40005ed1:	8b 45 0c             	mov    0xc(%ebp),%eax
40005ed4:	89 04 24             	mov    %eax,(%esp)
40005ed7:	e8 a2 d4 ff ff       	call   4000337e <fileino_create>
40005edc:	89 45 e0             	mov    %eax,-0x20(%ebp)
		if (cino <= 0)
40005edf:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
40005ee3:	7e 38                	jle    40005f1d <reconcile+0x348>
			continue;	// no free inodes!
		cfiles->fi[cino].rino = pino;
40005ee5:	8b 55 0c             	mov    0xc(%ebp),%edx
40005ee8:	8b 45 e0             	mov    -0x20(%ebp),%eax
40005eeb:	6b c0 5c             	imul   $0x5c,%eax,%eax
40005eee:	01 d0                	add    %edx,%eax
40005ef0:	8d 90 60 10 00 00    	lea    0x1060(%eax),%edx
40005ef6:	8b 45 dc             	mov    -0x24(%ebp),%eax
40005ef9:	89 02                	mov    %eax,(%edx)
		p2c[pino] = cino;
40005efb:	8b 45 dc             	mov    -0x24(%ebp),%eax
40005efe:	8b 55 e0             	mov    -0x20(%ebp),%edx
40005f01:	89 94 85 cc fb ff ff 	mov    %edx,-0x434(%ebp,%eax,4)
		c2p[cino] = pino;
40005f08:	8b 45 e0             	mov    -0x20(%ebp),%eax
40005f0b:	8b 55 dc             	mov    -0x24(%ebp),%edx
40005f0e:	89 94 85 cc f7 ff ff 	mov    %edx,-0x834(%ebp,%eax,4)
40005f15:	eb 07                	jmp    40005f1e <reconcile+0x349>
	// have a mapping in the child, creating mappings as needed.
	int pino;
	for (pino = 1; pino < FILE_INODES; pino++) {
		fileinode *pfi = &files->fi[pino];
		if (pfi->de.d_name[0] == 0 || pfi->mode == 0)
			continue; // not in use or already deleted
40005f17:	90                   	nop
40005f18:	eb 04                	jmp    40005f1e <reconcile+0x349>
		if (p2c[pino] != 0)
			continue; // already mapped
40005f1a:	90                   	nop
40005f1b:	eb 01                	jmp    40005f1e <reconcile+0x349>
		cino = fileino_create(cfiles, p2c[pfi->dino], pfi->de.d_name);
		if (cino <= 0)
			continue;	// no free inodes!
40005f1d:	90                   	nop
	}

	// Now make sure all the parent's allocated inodes
	// have a mapping in the child, creating mappings as needed.
	int pino;
	for (pino = 1; pino < FILE_INODES; pino++) {
40005f1e:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
40005f22:	81 7d dc ff 00 00 00 	cmpl   $0xff,-0x24(%ebp)
40005f29:	0f 8e 4f ff ff ff    	jle    40005e7e <reconcile+0x2a9>
		p2c[pino] = cino;
		c2p[cino] = pino;
	}

	// Finally, reconcile each corresponding pair of inodes.
	for (pino = 1; pino < FILE_INODES; pino++) {
40005f2f:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
40005f36:	eb 78                	jmp    40005fb0 <reconcile+0x3db>
		if (!p2c[pino])
40005f38:	8b 45 dc             	mov    -0x24(%ebp),%eax
40005f3b:	8b 84 85 cc fb ff ff 	mov    -0x434(%ebp,%eax,4),%eax
40005f42:	85 c0                	test   %eax,%eax
40005f44:	74 65                	je     40005fab <reconcile+0x3d6>
			continue;	// no corresponding inode in child
		cino = p2c[pino];
40005f46:	8b 45 dc             	mov    -0x24(%ebp),%eax
40005f49:	8b 84 85 cc fb ff ff 	mov    -0x434(%ebp,%eax,4),%eax
40005f50:	89 45 e0             	mov    %eax,-0x20(%ebp)
		assert(c2p[cino] == pino);
40005f53:	8b 45 e0             	mov    -0x20(%ebp),%eax
40005f56:	8b 84 85 cc f7 ff ff 	mov    -0x834(%ebp,%eax,4),%eax
40005f5d:	3b 45 dc             	cmp    -0x24(%ebp),%eax
40005f60:	74 24                	je     40005f86 <reconcile+0x3b1>
40005f62:	c7 44 24 0c e9 85 00 	movl   $0x400085e9,0xc(%esp)
40005f69:	40 
40005f6a:	c7 44 24 08 4f 85 00 	movl   $0x4000854f,0x8(%esp)
40005f71:	40 
40005f72:	c7 44 24 04 04 01 00 	movl   $0x104,0x4(%esp)
40005f79:	00 
40005f7a:	c7 04 24 2d 85 00 40 	movl   $0x4000852d,(%esp)
40005f81:	e8 5e c6 ff ff       	call   400025e4 <debug_panic>

		didio |= reconcile_inode(pid, cfiles, pino, cino);
40005f86:	8b 45 e0             	mov    -0x20(%ebp),%eax
40005f89:	89 44 24 0c          	mov    %eax,0xc(%esp)
40005f8d:	8b 45 dc             	mov    -0x24(%ebp),%eax
40005f90:	89 44 24 08          	mov    %eax,0x8(%esp)
40005f94:	8b 45 0c             	mov    0xc(%ebp),%eax
40005f97:	89 44 24 04          	mov    %eax,0x4(%esp)
40005f9b:	8b 45 08             	mov    0x8(%ebp),%eax
40005f9e:	89 04 24             	mov    %eax,(%esp)
40005fa1:	e8 25 00 00 00       	call   40005fcb <reconcile_inode>
40005fa6:	09 45 e4             	or     %eax,-0x1c(%ebp)
40005fa9:	eb 01                	jmp    40005fac <reconcile+0x3d7>
	}

	// Finally, reconcile each corresponding pair of inodes.
	for (pino = 1; pino < FILE_INODES; pino++) {
		if (!p2c[pino])
			continue;	// no corresponding inode in child
40005fab:	90                   	nop
		p2c[pino] = cino;
		c2p[cino] = pino;
	}

	// Finally, reconcile each corresponding pair of inodes.
	for (pino = 1; pino < FILE_INODES; pino++) {
40005fac:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
40005fb0:	81 7d dc ff 00 00 00 	cmpl   $0xff,-0x24(%ebp)
40005fb7:	0f 8e 7b ff ff ff    	jle    40005f38 <reconcile+0x363>
		assert(c2p[cino] == pino);

		didio |= reconcile_inode(pid, cfiles, pino, cino);
	}

	return didio;
40005fbd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
}
40005fc0:	81 c4 6c 08 00 00    	add    $0x86c,%esp
40005fc6:	5b                   	pop    %ebx
40005fc7:	5e                   	pop    %esi
40005fc8:	5f                   	pop    %edi
40005fc9:	5d                   	pop    %ebp
40005fca:	c3                   	ret    

40005fcb <reconcile_inode>:

bool
reconcile_inode(pid_t pid, filestate *cfiles, int pino, int cino)
{
40005fcb:	55                   	push   %ebp
40005fcc:	89 e5                	mov    %esp,%ebp
40005fce:	57                   	push   %edi
40005fcf:	56                   	push   %esi
40005fd0:	53                   	push   %ebx
40005fd1:	83 ec 5c             	sub    $0x5c,%esp
	assert(pino > 0 && pino < FILE_INODES);
40005fd4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40005fd8:	7e 09                	jle    40005fe3 <reconcile_inode+0x18>
40005fda:	81 7d 10 ff 00 00 00 	cmpl   $0xff,0x10(%ebp)
40005fe1:	7e 24                	jle    40006007 <reconcile_inode+0x3c>
40005fe3:	c7 44 24 0c fc 85 00 	movl   $0x400085fc,0xc(%esp)
40005fea:	40 
40005feb:	c7 44 24 08 4f 85 00 	movl   $0x4000854f,0x8(%esp)
40005ff2:	40 
40005ff3:	c7 44 24 04 0f 01 00 	movl   $0x10f,0x4(%esp)
40005ffa:	00 
40005ffb:	c7 04 24 2d 85 00 40 	movl   $0x4000852d,(%esp)
40006002:	e8 dd c5 ff ff       	call   400025e4 <debug_panic>
	assert(cino > 0 && cino < FILE_INODES);
40006007:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
4000600b:	7e 09                	jle    40006016 <reconcile_inode+0x4b>
4000600d:	81 7d 14 ff 00 00 00 	cmpl   $0xff,0x14(%ebp)
40006014:	7e 24                	jle    4000603a <reconcile_inode+0x6f>
40006016:	c7 44 24 0c 1c 86 00 	movl   $0x4000861c,0xc(%esp)
4000601d:	40 
4000601e:	c7 44 24 08 4f 85 00 	movl   $0x4000854f,0x8(%esp)
40006025:	40 
40006026:	c7 44 24 04 10 01 00 	movl   $0x110,0x4(%esp)
4000602d:	00 
4000602e:	c7 04 24 2d 85 00 40 	movl   $0x4000852d,(%esp)
40006035:	e8 aa c5 ff ff       	call   400025e4 <debug_panic>
	fileinode *pfi = &files->fi[pino];
4000603a:	a1 8c 80 00 40       	mov    0x4000808c,%eax
4000603f:	8b 55 10             	mov    0x10(%ebp),%edx
40006042:	6b d2 5c             	imul   $0x5c,%edx,%edx
40006045:	81 c2 10 10 00 00    	add    $0x1010,%edx
4000604b:	01 d0                	add    %edx,%eax
4000604d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	fileinode *cfi = &cfiles->fi[cino];
40006050:	8b 45 14             	mov    0x14(%ebp),%eax
40006053:	6b c0 5c             	imul   $0x5c,%eax,%eax
40006056:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
4000605c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000605f:	01 d0                	add    %edx,%eax
40006061:	89 45 e0             	mov    %eax,-0x20(%ebp)

	// Find the reference version number and length for reconciliation
	int rver = cfi->rver;
40006064:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006067:	8b 40 54             	mov    0x54(%eax),%eax
4000606a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	int rlen = cfi->rlen;
4000606d:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006070:	8b 40 58             	mov    0x58(%eax),%eax
40006073:	89 45 d8             	mov    %eax,-0x28(%ebp)

	// Check some invariants that should hold between
	// the parent's and child's current version numbers and lengths
	// and the reference version number and length stored in the child.
	// XXX should protect the parent better from state corruption by child.
	assert(cfi->ver >= rver);	// version # only increases
40006076:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006079:	8b 40 44             	mov    0x44(%eax),%eax
4000607c:	3b 45 dc             	cmp    -0x24(%ebp),%eax
4000607f:	7d 24                	jge    400060a5 <reconcile_inode+0xda>
40006081:	c7 44 24 0c 3b 86 00 	movl   $0x4000863b,0xc(%esp)
40006088:	40 
40006089:	c7 44 24 08 4f 85 00 	movl   $0x4000854f,0x8(%esp)
40006090:	40 
40006091:	c7 44 24 04 1c 01 00 	movl   $0x11c,0x4(%esp)
40006098:	00 
40006099:	c7 04 24 2d 85 00 40 	movl   $0x4000852d,(%esp)
400060a0:	e8 3f c5 ff ff       	call   400025e4 <debug_panic>
	assert(pfi->ver >= rver);
400060a5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400060a8:	8b 40 44             	mov    0x44(%eax),%eax
400060ab:	3b 45 dc             	cmp    -0x24(%ebp),%eax
400060ae:	7d 24                	jge    400060d4 <reconcile_inode+0x109>
400060b0:	c7 44 24 0c 4c 86 00 	movl   $0x4000864c,0xc(%esp)
400060b7:	40 
400060b8:	c7 44 24 08 4f 85 00 	movl   $0x4000854f,0x8(%esp)
400060bf:	40 
400060c0:	c7 44 24 04 1d 01 00 	movl   $0x11d,0x4(%esp)
400060c7:	00 
400060c8:	c7 04 24 2d 85 00 40 	movl   $0x4000852d,(%esp)
400060cf:	e8 10 c5 ff ff       	call   400025e4 <debug_panic>
	if (cfi->ver == rver)		// within a version, length only grows
400060d4:	8b 45 e0             	mov    -0x20(%ebp),%eax
400060d7:	8b 40 44             	mov    0x44(%eax),%eax
400060da:	3b 45 dc             	cmp    -0x24(%ebp),%eax
400060dd:	75 31                	jne    40006110 <reconcile_inode+0x145>
		assert(cfi->size >= rlen);
400060df:	8b 45 e0             	mov    -0x20(%ebp),%eax
400060e2:	8b 50 4c             	mov    0x4c(%eax),%edx
400060e5:	8b 45 d8             	mov    -0x28(%ebp),%eax
400060e8:	39 c2                	cmp    %eax,%edx
400060ea:	73 24                	jae    40006110 <reconcile_inode+0x145>
400060ec:	c7 44 24 0c 5d 86 00 	movl   $0x4000865d,0xc(%esp)
400060f3:	40 
400060f4:	c7 44 24 08 4f 85 00 	movl   $0x4000854f,0x8(%esp)
400060fb:	40 
400060fc:	c7 44 24 04 1f 01 00 	movl   $0x11f,0x4(%esp)
40006103:	00 
40006104:	c7 04 24 2d 85 00 40 	movl   $0x4000852d,(%esp)
4000610b:	e8 d4 c4 ff ff       	call   400025e4 <debug_panic>
	if (pfi->ver == rver)
40006110:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006113:	8b 40 44             	mov    0x44(%eax),%eax
40006116:	3b 45 dc             	cmp    -0x24(%ebp),%eax
40006119:	75 31                	jne    4000614c <reconcile_inode+0x181>
		assert(pfi->size >= rlen);
4000611b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000611e:	8b 50 4c             	mov    0x4c(%eax),%edx
40006121:	8b 45 d8             	mov    -0x28(%ebp),%eax
40006124:	39 c2                	cmp    %eax,%edx
40006126:	73 24                	jae    4000614c <reconcile_inode+0x181>
40006128:	c7 44 24 0c 6f 86 00 	movl   $0x4000866f,0xc(%esp)
4000612f:	40 
40006130:	c7 44 24 08 4f 85 00 	movl   $0x4000854f,0x8(%esp)
40006137:	40 
40006138:	c7 44 24 04 21 01 00 	movl   $0x121,0x4(%esp)
4000613f:	00 
40006140:	c7 04 24 2d 85 00 40 	movl   $0x4000852d,(%esp)
40006147:	e8 98 c4 ff ff       	call   400025e4 <debug_panic>
	// and the other process has NOT bumped its inode's version number
	// but has performed append-only writes increasing the file's length,
	// that situation still constitutes a conflict
	// because we don't have a clean way to resolve it automatically.
	//warn("reconcile_inode not implemented");
	if(pfi->ver == cfi->rver && cfi->ver == cfi->rver){
4000614c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000614f:	8b 50 44             	mov    0x44(%eax),%edx
40006152:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006155:	8b 40 54             	mov    0x54(%eax),%eax
40006158:	39 c2                	cmp    %eax,%edx
4000615a:	75 35                	jne    40006191 <reconcile_inode+0x1c6>
4000615c:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000615f:	8b 50 44             	mov    0x44(%eax),%edx
40006162:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006165:	8b 40 54             	mov    0x54(%eax),%eax
40006168:	39 c2                	cmp    %eax,%edx
4000616a:	75 25                	jne    40006191 <reconcile_inode+0x1c6>
		return reconcile_merge(pid, cfiles, pino, cino);
4000616c:	8b 45 14             	mov    0x14(%ebp),%eax
4000616f:	89 44 24 0c          	mov    %eax,0xc(%esp)
40006173:	8b 45 10             	mov    0x10(%ebp),%eax
40006176:	89 44 24 08          	mov    %eax,0x8(%esp)
4000617a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000617d:	89 44 24 04          	mov    %eax,0x4(%esp)
40006181:	8b 45 08             	mov    0x8(%ebp),%eax
40006184:	89 04 24             	mov    %eax,(%esp)
40006187:	e8 b0 01 00 00       	call   4000633c <reconcile_merge>
4000618c:	e9 a3 01 00 00       	jmp    40006334 <reconcile_inode+0x369>
	}
	if((pfi->ver > cfi->rver || pfi->size > cfi->rlen) && (cfi->ver > cfi->rver || cfi->size > cfi->rlen)){
40006191:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006194:	8b 50 44             	mov    0x44(%eax),%edx
40006197:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000619a:	8b 40 54             	mov    0x54(%eax),%eax
4000619d:	39 c2                	cmp    %eax,%edx
4000619f:	7f 10                	jg     400061b1 <reconcile_inode+0x1e6>
400061a1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400061a4:	8b 50 4c             	mov    0x4c(%eax),%edx
400061a7:	8b 45 e0             	mov    -0x20(%ebp),%eax
400061aa:	8b 40 58             	mov    0x58(%eax),%eax
400061ad:	39 c2                	cmp    %eax,%edx
400061af:	76 52                	jbe    40006203 <reconcile_inode+0x238>
400061b1:	8b 45 e0             	mov    -0x20(%ebp),%eax
400061b4:	8b 50 44             	mov    0x44(%eax),%edx
400061b7:	8b 45 e0             	mov    -0x20(%ebp),%eax
400061ba:	8b 40 54             	mov    0x54(%eax),%eax
400061bd:	39 c2                	cmp    %eax,%edx
400061bf:	7f 10                	jg     400061d1 <reconcile_inode+0x206>
400061c1:	8b 45 e0             	mov    -0x20(%ebp),%eax
400061c4:	8b 50 4c             	mov    0x4c(%eax),%edx
400061c7:	8b 45 e0             	mov    -0x20(%ebp),%eax
400061ca:	8b 40 58             	mov    0x58(%eax),%eax
400061cd:	39 c2                	cmp    %eax,%edx
400061cf:	76 32                	jbe    40006203 <reconcile_inode+0x238>
		pfi->mode |= S_IFCONF;
400061d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400061d4:	8b 40 48             	mov    0x48(%eax),%eax
400061d7:	89 c2                	mov    %eax,%edx
400061d9:	81 ca 00 00 01 00    	or     $0x10000,%edx
400061df:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400061e2:	89 50 48             	mov    %edx,0x48(%eax)
		cfi->mode |= S_IFCONF;
400061e5:	8b 45 e0             	mov    -0x20(%ebp),%eax
400061e8:	8b 40 48             	mov    0x48(%eax),%eax
400061eb:	89 c2                	mov    %eax,%edx
400061ed:	81 ca 00 00 01 00    	or     $0x10000,%edx
400061f3:	8b 45 e0             	mov    -0x20(%ebp),%eax
400061f6:	89 50 48             	mov    %edx,0x48(%eax)
		return 1;
400061f9:	b8 01 00 00 00       	mov    $0x1,%eax
400061fe:	e9 31 01 00 00       	jmp    40006334 <reconcile_inode+0x369>
	}
	if(pfi->ver > cfi->rver || pfi->size > cfi->rlen){
40006203:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006206:	8b 50 44             	mov    0x44(%eax),%edx
40006209:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000620c:	8b 40 54             	mov    0x54(%eax),%eax
4000620f:	39 c2                	cmp    %eax,%edx
40006211:	7f 10                	jg     40006223 <reconcile_inode+0x258>
40006213:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006216:	8b 50 4c             	mov    0x4c(%eax),%edx
40006219:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000621c:	8b 40 58             	mov    0x58(%eax),%eax
4000621f:	39 c2                	cmp    %eax,%edx
40006221:	76 7b                	jbe    4000629e <reconcile_inode+0x2d3>
		sys_put(SYS_COPY, pid, NULL, FILEDATA(pino),FILEDATA(cino),FILE_MAXSIZE);
40006223:	8b 45 14             	mov    0x14(%ebp),%eax
40006226:	c1 e0 16             	shl    $0x16,%eax
40006229:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
4000622f:	8b 45 10             	mov    0x10(%ebp),%eax
40006232:	c1 e0 16             	shl    $0x16,%eax
40006235:	8d 88 00 00 00 80    	lea    -0x80000000(%eax),%ecx
4000623b:	8b 45 08             	mov    0x8(%ebp),%eax
4000623e:	0f b7 c0             	movzwl %ax,%eax
40006241:	c7 45 d4 00 00 02 00 	movl   $0x20000,-0x2c(%ebp)
40006248:	66 89 45 d2          	mov    %ax,-0x2e(%ebp)
4000624c:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
40006253:	89 4d c8             	mov    %ecx,-0x38(%ebp)
40006256:	89 55 c4             	mov    %edx,-0x3c(%ebp)
40006259:	c7 45 c0 00 00 40 00 	movl   $0x400000,-0x40(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40006260:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40006263:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40006266:	8b 5d cc             	mov    -0x34(%ebp),%ebx
40006269:	0f b7 55 d2          	movzwl -0x2e(%ebp),%edx
4000626d:	8b 75 c8             	mov    -0x38(%ebp),%esi
40006270:	8b 7d c4             	mov    -0x3c(%ebp),%edi
40006273:	8b 4d c0             	mov    -0x40(%ebp),%ecx
40006276:	cd 30                	int    $0x30
		cfi->mode = pfi->mode;
40006278:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000627b:	8b 50 48             	mov    0x48(%eax),%edx
4000627e:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006281:	89 50 48             	mov    %edx,0x48(%eax)
		cfi->ver = pfi->ver;
40006284:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006287:	8b 50 44             	mov    0x44(%eax),%edx
4000628a:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000628d:	89 50 44             	mov    %edx,0x44(%eax)
		cfi->size = pfi->size;
40006290:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006293:	8b 50 4c             	mov    0x4c(%eax),%edx
40006296:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006299:	89 50 4c             	mov    %edx,0x4c(%eax)
4000629c:	eb 79                	jmp    40006317 <reconcile_inode+0x34c>
	}else{
		sys_get(SYS_COPY, pid, NULL, FILEDATA(cino),FILEDATA(pino), FILE_MAXSIZE);
4000629e:	8b 45 10             	mov    0x10(%ebp),%eax
400062a1:	c1 e0 16             	shl    $0x16,%eax
400062a4:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
400062aa:	8b 45 14             	mov    0x14(%ebp),%eax
400062ad:	c1 e0 16             	shl    $0x16,%eax
400062b0:	8d 88 00 00 00 80    	lea    -0x80000000(%eax),%ecx
400062b6:	8b 45 08             	mov    0x8(%ebp),%eax
400062b9:	0f b7 c0             	movzwl %ax,%eax
400062bc:	c7 45 bc 00 00 02 00 	movl   $0x20000,-0x44(%ebp)
400062c3:	66 89 45 ba          	mov    %ax,-0x46(%ebp)
400062c7:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)
400062ce:	89 4d b0             	mov    %ecx,-0x50(%ebp)
400062d1:	89 55 ac             	mov    %edx,-0x54(%ebp)
400062d4:	c7 45 a8 00 00 40 00 	movl   $0x400000,-0x58(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400062db:	8b 45 bc             	mov    -0x44(%ebp),%eax
400062de:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400062e1:	8b 5d b4             	mov    -0x4c(%ebp),%ebx
400062e4:	0f b7 55 ba          	movzwl -0x46(%ebp),%edx
400062e8:	8b 75 b0             	mov    -0x50(%ebp),%esi
400062eb:	8b 7d ac             	mov    -0x54(%ebp),%edi
400062ee:	8b 4d a8             	mov    -0x58(%ebp),%ecx
400062f1:	cd 30                	int    $0x30
		pfi->mode = cfi->mode;
400062f3:	8b 45 e0             	mov    -0x20(%ebp),%eax
400062f6:	8b 50 48             	mov    0x48(%eax),%edx
400062f9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400062fc:	89 50 48             	mov    %edx,0x48(%eax)
		pfi->ver = cfi->ver;
400062ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006302:	8b 50 44             	mov    0x44(%eax),%edx
40006305:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006308:	89 50 44             	mov    %edx,0x44(%eax)
		pfi->size = cfi->size;
4000630b:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000630e:	8b 50 4c             	mov    0x4c(%eax),%edx
40006311:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006314:	89 50 4c             	mov    %edx,0x4c(%eax)
	}
	cfi->rver = pfi->ver;
40006317:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000631a:	8b 50 44             	mov    0x44(%eax),%edx
4000631d:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006320:	89 50 54             	mov    %edx,0x54(%eax)
	cfi->rlen = pfi->size;
40006323:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006326:	8b 50 4c             	mov    0x4c(%eax),%edx
40006329:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000632c:	89 50 58             	mov    %edx,0x58(%eax)
	return 1;
4000632f:	b8 01 00 00 00       	mov    $0x1,%eax
}
40006334:	83 c4 5c             	add    $0x5c,%esp
40006337:	5b                   	pop    %ebx
40006338:	5e                   	pop    %esi
40006339:	5f                   	pop    %edi
4000633a:	5d                   	pop    %ebp
4000633b:	c3                   	ret    

4000633c <reconcile_merge>:

bool
reconcile_merge(pid_t pid, filestate *cfiles, int pino, int cino)
{
4000633c:	55                   	push   %ebp
4000633d:	89 e5                	mov    %esp,%ebp
4000633f:	57                   	push   %edi
40006340:	56                   	push   %esi
40006341:	53                   	push   %ebx
40006342:	83 ec 6c             	sub    $0x6c,%esp
	fileinode *pfi = &files->fi[pino];
40006345:	a1 8c 80 00 40       	mov    0x4000808c,%eax
4000634a:	8b 55 10             	mov    0x10(%ebp),%edx
4000634d:	6b d2 5c             	imul   $0x5c,%edx,%edx
40006350:	81 c2 10 10 00 00    	add    $0x1010,%edx
40006356:	01 d0                	add    %edx,%eax
40006358:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	fileinode *cfi = &cfiles->fi[cino];
4000635b:	8b 45 14             	mov    0x14(%ebp),%eax
4000635e:	6b c0 5c             	imul   $0x5c,%eax,%eax
40006361:	8d 90 10 10 00 00    	lea    0x1010(%eax),%edx
40006367:	8b 45 0c             	mov    0xc(%ebp),%eax
4000636a:	01 d0                	add    %edx,%eax
4000636c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	assert(pino > 0 && pino < FILE_INODES);
4000636f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40006373:	7e 09                	jle    4000637e <reconcile_merge+0x42>
40006375:	81 7d 10 ff 00 00 00 	cmpl   $0xff,0x10(%ebp)
4000637c:	7e 24                	jle    400063a2 <reconcile_merge+0x66>
4000637e:	c7 44 24 0c fc 85 00 	movl   $0x400085fc,0xc(%esp)
40006385:	40 
40006386:	c7 44 24 08 4f 85 00 	movl   $0x4000854f,0x8(%esp)
4000638d:	40 
4000638e:	c7 44 24 04 4e 01 00 	movl   $0x14e,0x4(%esp)
40006395:	00 
40006396:	c7 04 24 2d 85 00 40 	movl   $0x4000852d,(%esp)
4000639d:	e8 42 c2 ff ff       	call   400025e4 <debug_panic>
	assert(cino > 0 && cino < FILE_INODES);
400063a2:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
400063a6:	7e 09                	jle    400063b1 <reconcile_merge+0x75>
400063a8:	81 7d 14 ff 00 00 00 	cmpl   $0xff,0x14(%ebp)
400063af:	7e 24                	jle    400063d5 <reconcile_merge+0x99>
400063b1:	c7 44 24 0c 1c 86 00 	movl   $0x4000861c,0xc(%esp)
400063b8:	40 
400063b9:	c7 44 24 08 4f 85 00 	movl   $0x4000854f,0x8(%esp)
400063c0:	40 
400063c1:	c7 44 24 04 4f 01 00 	movl   $0x14f,0x4(%esp)
400063c8:	00 
400063c9:	c7 04 24 2d 85 00 40 	movl   $0x4000852d,(%esp)
400063d0:	e8 0f c2 ff ff       	call   400025e4 <debug_panic>
	assert(pfi->ver == cfi->ver);
400063d5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400063d8:	8b 50 44             	mov    0x44(%eax),%edx
400063db:	8b 45 e0             	mov    -0x20(%ebp),%eax
400063de:	8b 40 44             	mov    0x44(%eax),%eax
400063e1:	39 c2                	cmp    %eax,%edx
400063e3:	74 24                	je     40006409 <reconcile_merge+0xcd>
400063e5:	c7 44 24 0c 81 86 00 	movl   $0x40008681,0xc(%esp)
400063ec:	40 
400063ed:	c7 44 24 08 4f 85 00 	movl   $0x4000854f,0x8(%esp)
400063f4:	40 
400063f5:	c7 44 24 04 50 01 00 	movl   $0x150,0x4(%esp)
400063fc:	00 
400063fd:	c7 04 24 2d 85 00 40 	movl   $0x4000852d,(%esp)
40006404:	e8 db c1 ff ff       	call   400025e4 <debug_panic>
	assert(pfi->mode == cfi->mode);
40006409:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000640c:	8b 50 48             	mov    0x48(%eax),%edx
4000640f:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006412:	8b 40 48             	mov    0x48(%eax),%eax
40006415:	39 c2                	cmp    %eax,%edx
40006417:	74 24                	je     4000643d <reconcile_merge+0x101>
40006419:	c7 44 24 0c 96 86 00 	movl   $0x40008696,0xc(%esp)
40006420:	40 
40006421:	c7 44 24 08 4f 85 00 	movl   $0x4000854f,0x8(%esp)
40006428:	40 
40006429:	c7 44 24 04 51 01 00 	movl   $0x151,0x4(%esp)
40006430:	00 
40006431:	c7 04 24 2d 85 00 40 	movl   $0x4000852d,(%esp)
40006438:	e8 a7 c1 ff ff       	call   400025e4 <debug_panic>

	if (!S_ISREG(pfi->mode))
4000643d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006440:	8b 40 48             	mov    0x48(%eax),%eax
40006443:	25 00 70 00 00       	and    $0x7000,%eax
40006448:	3d 00 10 00 00       	cmp    $0x1000,%eax
4000644d:	74 0a                	je     40006459 <reconcile_merge+0x11d>
		return 0;	// only regular files have data to merge
4000644f:	b8 00 00 00 00       	mov    $0x0,%eax
40006454:	e9 8f 01 00 00       	jmp    400065e8 <reconcile_merge+0x2ac>
	// copy the parent's appends since last reconciliation into the child,
	// and the child's appends since last reconciliation into the parent.
	// Parent and child should be left with files of the same size,
	// although the writes they contain may be in a different order.
	// warn("reconcile_merge not implemented");
	if((pfi->size == cfi->rlen) && (cfi->size == cfi->rlen))
40006459:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000645c:	8b 50 4c             	mov    0x4c(%eax),%edx
4000645f:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006462:	8b 40 58             	mov    0x58(%eax),%eax
40006465:	39 c2                	cmp    %eax,%edx
40006467:	75 1a                	jne    40006483 <reconcile_merge+0x147>
40006469:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000646c:	8b 50 4c             	mov    0x4c(%eax),%edx
4000646f:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006472:	8b 40 58             	mov    0x58(%eax),%eax
40006475:	39 c2                	cmp    %eax,%edx
40006477:	75 0a                	jne    40006483 <reconcile_merge+0x147>
		return 1;
40006479:	b8 01 00 00 00       	mov    $0x1,%eax
4000647e:	e9 65 01 00 00       	jmp    400065e8 <reconcile_merge+0x2ac>

	void* tmpmem = (void*)(VM_SCRATCHLO + PTSIZE);	//Can't use VM_SCRATCHLO, cause the child process may use it for load elf concurrently..
40006483:	c7 45 dc 00 00 40 c0 	movl   $0xc0400000,-0x24(%ebp)
	size_t cgrow = cfi->size - cfi->rlen;
4000648a:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000648d:	8b 50 4c             	mov    0x4c(%eax),%edx
40006490:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006493:	8b 40 58             	mov    0x58(%eax),%eax
40006496:	89 d1                	mov    %edx,%ecx
40006498:	29 c1                	sub    %eax,%ecx
4000649a:	89 c8                	mov    %ecx,%eax
4000649c:	89 45 d8             	mov    %eax,-0x28(%ebp)
	size_t pgrow = pfi->size - cfi->rlen;
4000649f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400064a2:	8b 50 4c             	mov    0x4c(%eax),%edx
400064a5:	8b 45 e0             	mov    -0x20(%ebp),%eax
400064a8:	8b 40 58             	mov    0x58(%eax),%eax
400064ab:	89 d1                	mov    %edx,%ecx
400064ad:	29 c1                	sub    %eax,%ecx
400064af:	89 c8                	mov    %ecx,%eax
400064b1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	size_t newlen = cfi->rlen + cgrow + pgrow;
400064b4:	8b 45 e0             	mov    -0x20(%ebp),%eax
400064b7:	8b 50 58             	mov    0x58(%eax),%edx
400064ba:	8b 45 d8             	mov    -0x28(%ebp),%eax
400064bd:	01 c2                	add    %eax,%edx
400064bf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
400064c2:	01 d0                	add    %edx,%eax
400064c4:	89 45 d0             	mov    %eax,-0x30(%ebp)

	sys_get(SYS_COPY, pid, NULL, FILEDATA(cino), tmpmem, FILE_MAXSIZE);
400064c7:	8b 45 14             	mov    0x14(%ebp),%eax
400064ca:	c1 e0 16             	shl    $0x16,%eax
400064cd:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
400064d3:	8b 45 08             	mov    0x8(%ebp),%eax
400064d6:	0f b7 c0             	movzwl %ax,%eax
400064d9:	c7 45 cc 00 00 02 00 	movl   $0x20000,-0x34(%ebp)
400064e0:	66 89 45 ca          	mov    %ax,-0x36(%ebp)
400064e4:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)
400064eb:	89 55 c0             	mov    %edx,-0x40(%ebp)
400064ee:	8b 45 dc             	mov    -0x24(%ebp),%eax
400064f1:	89 45 bc             	mov    %eax,-0x44(%ebp)
400064f4:	c7 45 b8 00 00 40 00 	movl   $0x400000,-0x48(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400064fb:	8b 45 cc             	mov    -0x34(%ebp),%eax
400064fe:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40006501:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
40006504:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
40006508:	8b 75 c0             	mov    -0x40(%ebp),%esi
4000650b:	8b 7d bc             	mov    -0x44(%ebp),%edi
4000650e:	8b 4d b8             	mov    -0x48(%ebp),%ecx
40006511:	cd 30                	int    $0x30
	memcpy(FILEDATA(pino) + pfi->size, tmpmem + cfi->rlen, cgrow);
40006513:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006516:	8b 50 58             	mov    0x58(%eax),%edx
40006519:	8b 45 dc             	mov    -0x24(%ebp),%eax
4000651c:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
4000651f:	8b 45 10             	mov    0x10(%ebp),%eax
40006522:	c1 e0 16             	shl    $0x16,%eax
40006525:	89 c2                	mov    %eax,%edx
40006527:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000652a:	8b 40 4c             	mov    0x4c(%eax),%eax
4000652d:	01 d0                	add    %edx,%eax
4000652f:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
40006535:	8b 45 d8             	mov    -0x28(%ebp),%eax
40006538:	89 44 24 08          	mov    %eax,0x8(%esp)
4000653c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
40006540:	89 14 24             	mov    %edx,(%esp)
40006543:	e8 15 cd ff ff       	call   4000325d <memcpy>
	memcpy(tmpmem + cfi->size, FILEDATA(pino) + pfi->rlen, pgrow);
40006548:	8b 45 10             	mov    0x10(%ebp),%eax
4000654b:	c1 e0 16             	shl    $0x16,%eax
4000654e:	89 c2                	mov    %eax,%edx
40006550:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006553:	8b 40 58             	mov    0x58(%eax),%eax
40006556:	01 d0                	add    %edx,%eax
40006558:	8d 88 00 00 00 80    	lea    -0x80000000(%eax),%ecx
4000655e:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006561:	8b 50 4c             	mov    0x4c(%eax),%edx
40006564:	8b 45 dc             	mov    -0x24(%ebp),%eax
40006567:	01 c2                	add    %eax,%edx
40006569:	8b 45 d4             	mov    -0x2c(%ebp),%eax
4000656c:	89 44 24 08          	mov    %eax,0x8(%esp)
40006570:	89 4c 24 04          	mov    %ecx,0x4(%esp)
40006574:	89 14 24             	mov    %edx,(%esp)
40006577:	e8 e1 cc ff ff       	call   4000325d <memcpy>
	pfi->size = newlen;
4000657c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000657f:	8b 55 d0             	mov    -0x30(%ebp),%edx
40006582:	89 50 4c             	mov    %edx,0x4c(%eax)
	cfi->size = newlen;
40006585:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006588:	8b 55 d0             	mov    -0x30(%ebp),%edx
4000658b:	89 50 4c             	mov    %edx,0x4c(%eax)
	cfi->rlen = newlen;
4000658e:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006591:	8b 55 d0             	mov    -0x30(%ebp),%edx
40006594:	89 50 58             	mov    %edx,0x58(%eax)
	sys_put(SYS_COPY, pid, NULL, tmpmem, FILEDATA(cino), FILE_MAXSIZE);
40006597:	8b 45 14             	mov    0x14(%ebp),%eax
4000659a:	c1 e0 16             	shl    $0x16,%eax
4000659d:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
400065a3:	8b 45 08             	mov    0x8(%ebp),%eax
400065a6:	0f b7 c0             	movzwl %ax,%eax
400065a9:	c7 45 b4 00 00 02 00 	movl   $0x20000,-0x4c(%ebp)
400065b0:	66 89 45 b2          	mov    %ax,-0x4e(%ebp)
400065b4:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
400065bb:	8b 45 dc             	mov    -0x24(%ebp),%eax
400065be:	89 45 a8             	mov    %eax,-0x58(%ebp)
400065c1:	89 55 a4             	mov    %edx,-0x5c(%ebp)
400065c4:	c7 45 a0 00 00 40 00 	movl   $0x400000,-0x60(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
400065cb:	8b 45 b4             	mov    -0x4c(%ebp),%eax
400065ce:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400065d1:	8b 5d ac             	mov    -0x54(%ebp),%ebx
400065d4:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
400065d8:	8b 75 a8             	mov    -0x58(%ebp),%esi
400065db:	8b 7d a4             	mov    -0x5c(%ebp),%edi
400065de:	8b 4d a0             	mov    -0x60(%ebp),%ecx
400065e1:	cd 30                	int    $0x30
	return 1;
400065e3:	b8 01 00 00 00       	mov    $0x1,%eax
}
400065e8:	83 c4 6c             	add    $0x6c,%esp
400065eb:	5b                   	pop    %ebx
400065ec:	5e                   	pop    %esi
400065ed:	5f                   	pop    %edi
400065ee:	5d                   	pop    %ebp
400065ef:	c3                   	ret    

400065f0 <execl>:
int exec_readelf(const char *path);
intptr_t exec_copyargs(char *const argv[]);

int
execl(const char *path, const char *arg0, ...)
{
400065f0:	55                   	push   %ebp
400065f1:	89 e5                	mov    %esp,%ebp
400065f3:	83 ec 18             	sub    $0x18,%esp
	return execv(path, (char *const *) &arg0);
400065f6:	8d 45 0c             	lea    0xc(%ebp),%eax
400065f9:	89 44 24 04          	mov    %eax,0x4(%esp)
400065fd:	8b 45 08             	mov    0x8(%ebp),%eax
40006600:	89 04 24             	mov    %eax,(%esp)
40006603:	e8 02 00 00 00       	call   4000660a <execv>
}
40006608:	c9                   	leave  
40006609:	c3                   	ret    

4000660a <execv>:

int
execv(const char *path, char *const argv[])
{
4000660a:	55                   	push   %ebp
4000660b:	89 e5                	mov    %esp,%ebp
4000660d:	57                   	push   %edi
4000660e:	56                   	push   %esi
4000660f:	53                   	push   %ebx
40006610:	83 ec 5c             	sub    $0x5c,%esp
40006613:	c7 45 e0 00 00 01 00 	movl   $0x10000,-0x20(%ebp)
4000661a:	66 c7 45 de 00 00    	movw   $0x0,-0x22(%ebp)
40006620:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
40006627:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
4000662e:	c7 45 d0 00 00 00 40 	movl   $0x40000000,-0x30(%ebp)
40006635:	c7 45 cc 00 00 00 b0 	movl   $0xb0000000,-0x34(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
4000663c:	8b 45 e0             	mov    -0x20(%ebp),%eax
4000663f:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40006642:	8b 5d d8             	mov    -0x28(%ebp),%ebx
40006645:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
40006649:	8b 75 d4             	mov    -0x2c(%ebp),%esi
4000664c:	8b 7d d0             	mov    -0x30(%ebp),%edi
4000664f:	8b 4d cc             	mov    -0x34(%ebp),%ecx
40006652:	cd 30                	int    $0x30
	// which never represents a forked child since 0 is an invalid pid.
	// First clear out the new program's entire address space.
	sys_put(SYS_ZERO, 0, NULL, NULL, (void*)VM_USERLO, VM_USERHI-VM_USERLO);

	// Load the ELF executable into child 0.
	if (exec_readelf(path) < 0)
40006654:	8b 45 08             	mov    0x8(%ebp),%eax
40006657:	89 04 24             	mov    %eax,(%esp)
4000665a:	e8 6d 00 00 00       	call   400066cc <exec_readelf>
4000665f:	85 c0                	test   %eax,%eax
40006661:	79 07                	jns    4000666a <execv+0x60>
		return -1;
40006663:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40006668:	eb 5a                	jmp    400066c4 <execv+0xba>

	// Setup child 0's stack with the argument array.
	intptr_t esp = exec_copyargs(argv);
4000666a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000666d:	89 04 24             	mov    %eax,(%esp)
40006670:	e8 3a 05 00 00       	call   40006baf <exec_copyargs>
40006675:	89 45 e4             	mov    %eax,-0x1c(%ebp)
40006678:	c7 45 c8 00 00 02 00 	movl   $0x20000,-0x38(%ebp)
4000667f:	66 c7 45 c6 00 00    	movw   $0x0,-0x3a(%ebp)
40006685:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
4000668c:	c7 45 bc 00 00 00 80 	movl   $0x80000000,-0x44(%ebp)
40006693:	c7 45 b8 00 00 00 80 	movl   $0x80000000,-0x48(%ebp)
4000669a:	c7 45 b4 00 00 00 40 	movl   $0x40000000,-0x4c(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
400066a1:	8b 45 c8             	mov    -0x38(%ebp),%eax
400066a4:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400066a7:	8b 5d c0             	mov    -0x40(%ebp),%ebx
400066aa:	0f b7 55 c6          	movzwl -0x3a(%ebp),%edx
400066ae:	8b 75 bc             	mov    -0x44(%ebp),%esi
400066b1:	8b 7d b8             	mov    -0x48(%ebp),%edi
400066b4:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
400066b7:	cd 30                	int    $0x30
	sys_put(SYS_COPY, 0, NULL, (void*)VM_FILELO, (void*)VM_FILELO,
		VM_FILEHI-VM_FILELO);

	// Copy child 0's entire memory state onto ours
	// and start the new program.  See lib/entry.S for details.
	exec_start(esp);
400066b9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400066bc:	89 04 24             	mov    %eax,(%esp)
400066bf:	e8 55 9a ff ff       	call   40000119 <exec_start>
}
400066c4:	83 c4 5c             	add    $0x5c,%esp
400066c7:	5b                   	pop    %ebx
400066c8:	5e                   	pop    %esi
400066c9:	5f                   	pop    %edi
400066ca:	5d                   	pop    %ebp
400066cb:	c3                   	ret    

400066cc <exec_readelf>:

int
exec_readelf(const char *path)
{
400066cc:	55                   	push   %ebp
400066cd:	89 e5                	mov    %esp,%ebp
400066cf:	57                   	push   %edi
400066d0:	56                   	push   %esi
400066d1:	53                   	push   %ebx
400066d2:	81 ec fc 00 00 00    	sub    $0xfc,%esp
	// We'll load the ELF image into a scratch area in our address space.
	sys_get(SYS_ZERO, 0, NULL, NULL, (void*)VM_SCRATCHLO, EXEMAX);
400066d8:	c7 45 e0 00 00 00 40 	movl   $0x40000000,-0x20(%ebp)
400066df:	c7 45 dc 00 00 00 10 	movl   $0x10000000,-0x24(%ebp)
400066e6:	8b 45 dc             	mov    -0x24(%ebp),%eax
400066e9:	39 45 e0             	cmp    %eax,-0x20(%ebp)
400066ec:	0f 46 45 e0          	cmovbe -0x20(%ebp),%eax
400066f0:	c7 85 7c ff ff ff 00 	movl   $0x10000,-0x84(%ebp)
400066f7:	00 01 00 
400066fa:	66 c7 85 7a ff ff ff 	movw   $0x0,-0x86(%ebp)
40006701:	00 00 
40006703:	c7 85 74 ff ff ff 00 	movl   $0x0,-0x8c(%ebp)
4000670a:	00 00 00 
4000670d:	c7 85 70 ff ff ff 00 	movl   $0x0,-0x90(%ebp)
40006714:	00 00 00 
40006717:	c7 85 6c ff ff ff 00 	movl   $0xc0000000,-0x94(%ebp)
4000671e:	00 00 c0 
40006721:	89 85 68 ff ff ff    	mov    %eax,-0x98(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40006727:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
4000672d:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40006730:	8b 9d 74 ff ff ff    	mov    -0x8c(%ebp),%ebx
40006736:	0f b7 95 7a ff ff ff 	movzwl -0x86(%ebp),%edx
4000673d:	8b b5 70 ff ff ff    	mov    -0x90(%ebp),%esi
40006743:	8b bd 6c ff ff ff    	mov    -0x94(%ebp),%edi
40006749:	8b 8d 68 ff ff ff    	mov    -0x98(%ebp),%ecx
4000674f:	cd 30                	int    $0x30

	// Open the ELF image to load.
	filedesc *fd = filedesc_open(NULL, path, O_RDONLY, 0);
40006751:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
40006758:	00 
40006759:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
40006760:	00 
40006761:	8b 45 08             	mov    0x8(%ebp),%eax
40006764:	89 44 24 04          	mov    %eax,0x4(%esp)
40006768:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000676f:	e8 3b d6 ff ff       	call   40003daf <filedesc_open>
40006774:	89 45 d8             	mov    %eax,-0x28(%ebp)
	if (fd == NULL)
40006777:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
4000677b:	75 0a                	jne    40006787 <exec_readelf+0xbb>
		return -1;
4000677d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
40006782:	e9 1d 04 00 00       	jmp    40006ba4 <exec_readelf+0x4d8>
	void *imgdata = FILEDATA(fd->ino);
40006787:	8b 45 d8             	mov    -0x28(%ebp),%eax
4000678a:	8b 00                	mov    (%eax),%eax
4000678c:	c1 e0 16             	shl    $0x16,%eax
4000678f:	05 00 00 00 80       	add    $0x80000000,%eax
40006794:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	size_t imgsize = files->fi[fd->ino].size;
40006797:	8b 15 8c 80 00 40    	mov    0x4000808c,%edx
4000679d:	8b 45 d8             	mov    -0x28(%ebp),%eax
400067a0:	8b 00                	mov    (%eax),%eax
400067a2:	6b c0 5c             	imul   $0x5c,%eax,%eax
400067a5:	01 d0                	add    %edx,%eax
400067a7:	05 5c 10 00 00       	add    $0x105c,%eax
400067ac:	8b 00                	mov    (%eax),%eax
400067ae:	89 45 d0             	mov    %eax,-0x30(%ebp)

	// Make sure it looks like an ELF image.
	elfhdr *eh = imgdata;
400067b1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
400067b4:	89 45 cc             	mov    %eax,-0x34(%ebp)
	if (imgsize < sizeof(*eh) || eh->e_magic != ELF_MAGIC) {
400067b7:	83 7d d0 33          	cmpl   $0x33,-0x30(%ebp)
400067bb:	76 0c                	jbe    400067c9 <exec_readelf+0xfd>
400067bd:	8b 45 cc             	mov    -0x34(%ebp),%eax
400067c0:	8b 00                	mov    (%eax),%eax
400067c2:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
400067c7:	74 21                	je     400067ea <exec_readelf+0x11e>
		warn("exec_readelf: ELF header not found");
400067c9:	c7 44 24 08 b0 86 00 	movl   $0x400086b0,0x8(%esp)
400067d0:	40 
400067d1:	c7 44 24 04 4d 00 00 	movl   $0x4d,0x4(%esp)
400067d8:	00 
400067d9:	c7 04 24 d3 86 00 40 	movl   $0x400086d3,(%esp)
400067e0:	e8 69 be ff ff       	call   4000264e <debug_warn>
		goto err;
400067e5:	e9 aa 03 00 00       	jmp    40006b94 <exec_readelf+0x4c8>
	}

	// Load each program segment into the scratch area
	proghdr *ph = imgdata + eh->e_phoff;
400067ea:	8b 45 cc             	mov    -0x34(%ebp),%eax
400067ed:	8b 50 1c             	mov    0x1c(%eax),%edx
400067f0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
400067f3:	01 d0                	add    %edx,%eax
400067f5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	proghdr *eph = ph + eh->e_phnum;
400067f8:	8b 45 cc             	mov    -0x34(%ebp),%eax
400067fb:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
400067ff:	0f b7 c0             	movzwl %ax,%eax
40006802:	89 c2                	mov    %eax,%edx
40006804:	c1 e2 05             	shl    $0x5,%edx
40006807:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000680a:	01 d0                	add    %edx,%eax
4000680c:	89 45 c8             	mov    %eax,-0x38(%ebp)
	if (imgsize < (void*)eph - imgdata) {
4000680f:	8b 55 c8             	mov    -0x38(%ebp),%edx
40006812:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40006815:	89 d1                	mov    %edx,%ecx
40006817:	29 c1                	sub    %eax,%ecx
40006819:	89 c8                	mov    %ecx,%eax
4000681b:	3b 45 d0             	cmp    -0x30(%ebp),%eax
4000681e:	0f 86 ac 02 00 00    	jbe    40006ad0 <exec_readelf+0x404>
		warn("exec_readelf: ELF program header truncated");
40006824:	c7 44 24 08 e0 86 00 	movl   $0x400086e0,0x8(%esp)
4000682b:	40 
4000682c:	c7 44 24 04 55 00 00 	movl   $0x55,0x4(%esp)
40006833:	00 
40006834:	c7 04 24 d3 86 00 40 	movl   $0x400086d3,(%esp)
4000683b:	e8 0e be ff ff       	call   4000264e <debug_warn>
		goto err;
40006840:	e9 4f 03 00 00       	jmp    40006b94 <exec_readelf+0x4c8>
	}
	for (; ph < eph; ph++) {
		if (ph->p_type != ELF_PROG_LOAD)
40006845:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006848:	8b 00                	mov    (%eax),%eax
4000684a:	83 f8 01             	cmp    $0x1,%eax
4000684d:	0f 85 78 02 00 00    	jne    40006acb <exec_readelf+0x3ff>
			continue;

		// The executable should fit in the first 4MB of user space.
		intptr_t valo = ph->p_va;
40006853:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006856:	8b 40 08             	mov    0x8(%eax),%eax
40006859:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		intptr_t vahi = valo + ph->p_memsz;
4000685c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000685f:	8b 50 14             	mov    0x14(%eax),%edx
40006862:	8b 45 c4             	mov    -0x3c(%ebp),%eax
40006865:	01 d0                	add    %edx,%eax
40006867:	89 45 c0             	mov    %eax,-0x40(%ebp)
		if (valo < VM_USERLO || valo > VM_USERLO+EXEMAX ||
4000686a:	81 7d c4 ff ff ff 3f 	cmpl   $0x3fffffff,-0x3c(%ebp)
40006871:	7e 50                	jle    400068c3 <exec_readelf+0x1f7>
40006873:	8b 55 c4             	mov    -0x3c(%ebp),%edx
40006876:	c7 45 bc 00 00 00 40 	movl   $0x40000000,-0x44(%ebp)
4000687d:	c7 45 b8 00 00 00 10 	movl   $0x10000000,-0x48(%ebp)
40006884:	8b 45 b8             	mov    -0x48(%ebp),%eax
40006887:	39 45 bc             	cmp    %eax,-0x44(%ebp)
4000688a:	0f 46 45 bc          	cmovbe -0x44(%ebp),%eax
4000688e:	05 00 00 00 40       	add    $0x40000000,%eax
40006893:	39 c2                	cmp    %eax,%edx
40006895:	77 2c                	ja     400068c3 <exec_readelf+0x1f7>
40006897:	8b 45 c0             	mov    -0x40(%ebp),%eax
4000689a:	3b 45 c4             	cmp    -0x3c(%ebp),%eax
4000689d:	7c 24                	jl     400068c3 <exec_readelf+0x1f7>
				vahi < valo || vahi > VM_USERLO+EXEMAX) {
4000689f:	8b 55 c0             	mov    -0x40(%ebp),%edx
400068a2:	c7 45 b4 00 00 00 40 	movl   $0x40000000,-0x4c(%ebp)
400068a9:	c7 45 b0 00 00 00 10 	movl   $0x10000000,-0x50(%ebp)
400068b0:	8b 45 b0             	mov    -0x50(%ebp),%eax
400068b3:	39 45 b4             	cmp    %eax,-0x4c(%ebp)
400068b6:	0f 46 45 b4          	cmovbe -0x4c(%ebp),%eax
400068ba:	05 00 00 00 40       	add    $0x40000000,%eax
400068bf:	39 c2                	cmp    %eax,%edx
400068c1:	76 4d                	jbe    40006910 <exec_readelf+0x244>
			warn("exec_readelf: executable image too large "
400068c3:	c7 45 8c 00 00 00 40 	movl   $0x40000000,-0x74(%ebp)
400068ca:	c7 45 88 00 00 00 10 	movl   $0x10000000,-0x78(%ebp)
400068d1:	8b 45 88             	mov    -0x78(%ebp),%eax
400068d4:	39 45 8c             	cmp    %eax,-0x74(%ebp)
400068d7:	0f 46 45 8c          	cmovbe -0x74(%ebp),%eax
400068db:	8b 55 c4             	mov    -0x3c(%ebp),%edx
400068de:	8b 4d c0             	mov    -0x40(%ebp),%ecx
400068e1:	89 cb                	mov    %ecx,%ebx
400068e3:	29 d3                	sub    %edx,%ebx
400068e5:	89 da                	mov    %ebx,%edx
400068e7:	89 44 24 10          	mov    %eax,0x10(%esp)
400068eb:	89 54 24 0c          	mov    %edx,0xc(%esp)
400068ef:	c7 44 24 08 0c 87 00 	movl   $0x4000870c,0x8(%esp)
400068f6:	40 
400068f7:	c7 44 24 04 62 00 00 	movl   $0x62,0x4(%esp)
400068fe:	00 
400068ff:	c7 04 24 d3 86 00 40 	movl   $0x400086d3,(%esp)
40006906:	e8 43 bd ff ff       	call   4000264e <debug_warn>
				"(%d bytes > %d max)", vahi-valo, EXEMAX);
			goto err;
4000690b:	e9 84 02 00 00       	jmp    40006b94 <exec_readelf+0x4c8>
		}

		// Map all pages the segment touches in our scratch region.
		// They've already been zeroed by the SYS_ZERO above.
		intptr_t scratchofs = VM_SCRATCHLO - VM_USERLO;
40006910:	c7 45 ac 00 00 00 80 	movl   $0x80000000,-0x54(%ebp)
		intptr_t pagelo = ROUNDDOWN(valo, PAGESIZE);
40006917:	8b 45 c4             	mov    -0x3c(%ebp),%eax
4000691a:	89 45 a8             	mov    %eax,-0x58(%ebp)
4000691d:	8b 45 a8             	mov    -0x58(%ebp),%eax
40006920:	25 00 f0 ff ff       	and    $0xfffff000,%eax
40006925:	89 45 a4             	mov    %eax,-0x5c(%ebp)
		intptr_t pagehi = ROUNDUP(vahi, PAGESIZE);
40006928:	c7 45 a0 00 10 00 00 	movl   $0x1000,-0x60(%ebp)
4000692f:	8b 55 c0             	mov    -0x40(%ebp),%edx
40006932:	8b 45 a0             	mov    -0x60(%ebp),%eax
40006935:	01 d0                	add    %edx,%eax
40006937:	83 e8 01             	sub    $0x1,%eax
4000693a:	89 45 9c             	mov    %eax,-0x64(%ebp)
4000693d:	8b 45 9c             	mov    -0x64(%ebp),%eax
40006940:	ba 00 00 00 00       	mov    $0x0,%edx
40006945:	f7 75 a0             	divl   -0x60(%ebp)
40006948:	89 d0                	mov    %edx,%eax
4000694a:	8b 55 9c             	mov    -0x64(%ebp),%edx
4000694d:	89 d1                	mov    %edx,%ecx
4000694f:	29 c1                	sub    %eax,%ecx
40006951:	89 c8                	mov    %ecx,%eax
40006953:	89 45 98             	mov    %eax,-0x68(%ebp)
		sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL,
			(void*)pagelo + scratchofs, pagehi - pagelo);
40006956:	8b 45 a4             	mov    -0x5c(%ebp),%eax
40006959:	8b 55 98             	mov    -0x68(%ebp),%edx
4000695c:	89 d3                	mov    %edx,%ebx
4000695e:	29 c3                	sub    %eax,%ebx
40006960:	89 d8                	mov    %ebx,%eax
40006962:	8b 4d ac             	mov    -0x54(%ebp),%ecx
40006965:	8b 55 a4             	mov    -0x5c(%ebp),%edx
40006968:	01 ca                	add    %ecx,%edx
4000696a:	c7 85 64 ff ff ff 00 	movl   $0x700,-0x9c(%ebp)
40006971:	07 00 00 
40006974:	66 c7 85 62 ff ff ff 	movw   $0x0,-0x9e(%ebp)
4000697b:	00 00 
4000697d:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
40006984:	00 00 00 
40006987:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
4000698e:	00 00 00 
40006991:	89 95 54 ff ff ff    	mov    %edx,-0xac(%ebp)
40006997:	89 85 50 ff ff ff    	mov    %eax,-0xb0(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
4000699d:	8b 85 64 ff ff ff    	mov    -0x9c(%ebp),%eax
400069a3:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400069a6:	8b 9d 5c ff ff ff    	mov    -0xa4(%ebp),%ebx
400069ac:	0f b7 95 62 ff ff ff 	movzwl -0x9e(%ebp),%edx
400069b3:	8b b5 58 ff ff ff    	mov    -0xa8(%ebp),%esi
400069b9:	8b bd 54 ff ff ff    	mov    -0xac(%ebp),%edi
400069bf:	8b 8d 50 ff ff ff    	mov    -0xb0(%ebp),%ecx
400069c5:	cd 30                	int    $0x30

		// Initialize the file-loaded part of the ELF image.
		// (We could use copy-on-write if SYS_COPY
		// supports copying at arbitrary page boundaries.)
		intptr_t filelo = ph->p_offset;
400069c7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400069ca:	8b 40 04             	mov    0x4(%eax),%eax
400069cd:	89 45 94             	mov    %eax,-0x6c(%ebp)
		intptr_t filehi = filelo + ph->p_filesz;
400069d0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400069d3:	8b 50 10             	mov    0x10(%eax),%edx
400069d6:	8b 45 94             	mov    -0x6c(%ebp),%eax
400069d9:	01 d0                	add    %edx,%eax
400069db:	89 45 90             	mov    %eax,-0x70(%ebp)
		if (filelo < 0 || filelo > imgsize
400069de:	83 7d 94 00          	cmpl   $0x0,-0x6c(%ebp)
400069e2:	78 18                	js     400069fc <exec_readelf+0x330>
400069e4:	8b 45 94             	mov    -0x6c(%ebp),%eax
400069e7:	3b 45 d0             	cmp    -0x30(%ebp),%eax
400069ea:	77 10                	ja     400069fc <exec_readelf+0x330>
				|| filehi < filelo || filehi > imgsize) {
400069ec:	8b 45 90             	mov    -0x70(%ebp),%eax
400069ef:	3b 45 94             	cmp    -0x6c(%ebp),%eax
400069f2:	7c 08                	jl     400069fc <exec_readelf+0x330>
400069f4:	8b 45 90             	mov    -0x70(%ebp),%eax
400069f7:	3b 45 d0             	cmp    -0x30(%ebp),%eax
400069fa:	76 21                	jbe    40006a1d <exec_readelf+0x351>
			warn("exec_readelf: loaded section out of bounds");
400069fc:	c7 44 24 08 4c 87 00 	movl   $0x4000874c,0x8(%esp)
40006a03:	40 
40006a04:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
40006a0b:	00 
40006a0c:	c7 04 24 d3 86 00 40 	movl   $0x400086d3,(%esp)
40006a13:	e8 36 bc ff ff       	call   4000264e <debug_warn>
			goto err;
40006a18:	e9 77 01 00 00       	jmp    40006b94 <exec_readelf+0x4c8>
		}
		memcpy((void*)valo + scratchofs, imgdata + filelo,
			filehi - filelo);
40006a1d:	8b 45 94             	mov    -0x6c(%ebp),%eax
40006a20:	8b 55 90             	mov    -0x70(%ebp),%edx
40006a23:	89 d1                	mov    %edx,%ecx
40006a25:	29 c1                	sub    %eax,%ecx
40006a27:	89 c8                	mov    %ecx,%eax
		if (filelo < 0 || filelo > imgsize
				|| filehi < filelo || filehi > imgsize) {
			warn("exec_readelf: loaded section out of bounds");
			goto err;
		}
		memcpy((void*)valo + scratchofs, imgdata + filelo,
40006a29:	89 c2                	mov    %eax,%edx
40006a2b:	8b 4d 94             	mov    -0x6c(%ebp),%ecx
40006a2e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40006a31:	01 c1                	add    %eax,%ecx
40006a33:	8b 5d ac             	mov    -0x54(%ebp),%ebx
40006a36:	8b 45 c4             	mov    -0x3c(%ebp),%eax
40006a39:	01 d8                	add    %ebx,%eax
40006a3b:	89 54 24 08          	mov    %edx,0x8(%esp)
40006a3f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
40006a43:	89 04 24             	mov    %eax,(%esp)
40006a46:	e8 12 c8 ff ff       	call   4000325d <memcpy>
			filehi - filelo);

		// Finally, remove write permissions on read-only segments.
		if (!(ph->p_flags & ELF_PROG_FLAG_WRITE))
40006a4b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006a4e:	8b 40 18             	mov    0x18(%eax),%eax
40006a51:	83 e0 02             	and    $0x2,%eax
40006a54:	85 c0                	test   %eax,%eax
40006a56:	75 74                	jne    40006acc <exec_readelf+0x400>
			sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL,
				(void*)pagelo + scratchofs, pagehi - pagelo);
40006a58:	8b 45 a4             	mov    -0x5c(%ebp),%eax
40006a5b:	8b 55 98             	mov    -0x68(%ebp),%edx
40006a5e:	89 d3                	mov    %edx,%ebx
40006a60:	29 c3                	sub    %eax,%ebx
40006a62:	89 d8                	mov    %ebx,%eax
40006a64:	8b 4d ac             	mov    -0x54(%ebp),%ecx
40006a67:	8b 55 a4             	mov    -0x5c(%ebp),%edx
40006a6a:	01 ca                	add    %ecx,%edx
40006a6c:	c7 85 4c ff ff ff 00 	movl   $0x300,-0xb4(%ebp)
40006a73:	03 00 00 
40006a76:	66 c7 85 4a ff ff ff 	movw   $0x0,-0xb6(%ebp)
40006a7d:	00 00 
40006a7f:	c7 85 44 ff ff ff 00 	movl   $0x0,-0xbc(%ebp)
40006a86:	00 00 00 
40006a89:	c7 85 40 ff ff ff 00 	movl   $0x0,-0xc0(%ebp)
40006a90:	00 00 00 
40006a93:	89 95 3c ff ff ff    	mov    %edx,-0xc4(%ebp)
40006a99:	89 85 38 ff ff ff    	mov    %eax,-0xc8(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40006a9f:	8b 85 4c ff ff ff    	mov    -0xb4(%ebp),%eax
40006aa5:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40006aa8:	8b 9d 44 ff ff ff    	mov    -0xbc(%ebp),%ebx
40006aae:	0f b7 95 4a ff ff ff 	movzwl -0xb6(%ebp),%edx
40006ab5:	8b b5 40 ff ff ff    	mov    -0xc0(%ebp),%esi
40006abb:	8b bd 3c ff ff ff    	mov    -0xc4(%ebp),%edi
40006ac1:	8b 8d 38 ff ff ff    	mov    -0xc8(%ebp),%ecx
40006ac7:	cd 30                	int    $0x30
40006ac9:	eb 01                	jmp    40006acc <exec_readelf+0x400>
		warn("exec_readelf: ELF program header truncated");
		goto err;
	}
	for (; ph < eph; ph++) {
		if (ph->p_type != ELF_PROG_LOAD)
			continue;
40006acb:	90                   	nop
	proghdr *eph = ph + eh->e_phnum;
	if (imgsize < (void*)eph - imgdata) {
		warn("exec_readelf: ELF program header truncated");
		goto err;
	}
	for (; ph < eph; ph++) {
40006acc:	83 45 e4 20          	addl   $0x20,-0x1c(%ebp)
40006ad0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006ad3:	3b 45 c8             	cmp    -0x38(%ebp),%eax
40006ad6:	0f 82 69 fd ff ff    	jb     40006845 <exec_readelf+0x179>
				(void*)pagelo + scratchofs, pagehi - pagelo);
	}

	// Copy the ELF image into its correct position in child 0.
	sys_put(SYS_COPY, 0, NULL, (void*)VM_SCRATCHLO,
		(void*)VM_USERLO, EXEMAX);
40006adc:	c7 45 84 00 00 00 40 	movl   $0x40000000,-0x7c(%ebp)
40006ae3:	c7 45 80 00 00 00 10 	movl   $0x10000000,-0x80(%ebp)
40006aea:	8b 45 80             	mov    -0x80(%ebp),%eax
40006aed:	39 45 84             	cmp    %eax,-0x7c(%ebp)
40006af0:	0f 46 45 84          	cmovbe -0x7c(%ebp),%eax
40006af4:	c7 85 34 ff ff ff 00 	movl   $0x20000,-0xcc(%ebp)
40006afb:	00 02 00 
40006afe:	66 c7 85 32 ff ff ff 	movw   $0x0,-0xce(%ebp)
40006b05:	00 00 
40006b07:	c7 85 2c ff ff ff 00 	movl   $0x0,-0xd4(%ebp)
40006b0e:	00 00 00 
40006b11:	c7 85 28 ff ff ff 00 	movl   $0xc0000000,-0xd8(%ebp)
40006b18:	00 00 c0 
40006b1b:	c7 85 24 ff ff ff 00 	movl   $0x40000000,-0xdc(%ebp)
40006b22:	00 00 40 
40006b25:	89 85 20 ff ff ff    	mov    %eax,-0xe0(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40006b2b:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
40006b31:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40006b34:	8b 9d 2c ff ff ff    	mov    -0xd4(%ebp),%ebx
40006b3a:	0f b7 95 32 ff ff ff 	movzwl -0xce(%ebp),%edx
40006b41:	8b b5 28 ff ff ff    	mov    -0xd8(%ebp),%esi
40006b47:	8b bd 24 ff ff ff    	mov    -0xdc(%ebp),%edi
40006b4d:	8b 8d 20 ff ff ff    	mov    -0xe0(%ebp),%ecx
40006b53:	cd 30                	int    $0x30

	// The new program should have the same entrypoint as we do!
	if (eh->e_entry != (intptr_t)start) {
40006b55:	8b 45 cc             	mov    -0x34(%ebp),%eax
40006b58:	8b 50 18             	mov    0x18(%eax),%edx
40006b5b:	b8 00 01 00 40       	mov    $0x40000100,%eax
40006b60:	39 c2                	cmp    %eax,%edx
40006b62:	74 1e                	je     40006b82 <exec_readelf+0x4b6>
		warn("exec_readelf: executable has a different start address");
40006b64:	c7 44 24 08 78 87 00 	movl   $0x40008778,0x8(%esp)
40006b6b:	40 
40006b6c:	c7 44 24 04 87 00 00 	movl   $0x87,0x4(%esp)
40006b73:	00 
40006b74:	c7 04 24 d3 86 00 40 	movl   $0x400086d3,(%esp)
40006b7b:	e8 ce ba ff ff       	call   4000264e <debug_warn>
		goto err;
40006b80:	eb 12                	jmp    40006b94 <exec_readelf+0x4c8>
	}

	filedesc_close(fd);	// Done with the ELF file
40006b82:	8b 45 d8             	mov    -0x28(%ebp),%eax
40006b85:	89 04 24             	mov    %eax,(%esp)
40006b88:	e8 e7 d7 ff ff       	call   40004374 <filedesc_close>
	return 0;
40006b8d:	b8 00 00 00 00       	mov    $0x0,%eax
40006b92:	eb 10                	jmp    40006ba4 <exec_readelf+0x4d8>

err:
	filedesc_close(fd);
40006b94:	8b 45 d8             	mov    -0x28(%ebp),%eax
40006b97:	89 04 24             	mov    %eax,(%esp)
40006b9a:	e8 d5 d7 ff ff       	call   40004374 <filedesc_close>
	return -1;
40006b9f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
40006ba4:	81 c4 fc 00 00 00    	add    $0xfc,%esp
40006baa:	5b                   	pop    %ebx
40006bab:	5e                   	pop    %esi
40006bac:	5f                   	pop    %edi
40006bad:	5d                   	pop    %ebp
40006bae:	c3                   	ret    

40006baf <exec_copyargs>:

intptr_t
exec_copyargs(char *const argv[])
{
40006baf:	55                   	push   %ebp
40006bb0:	89 e5                	mov    %esp,%ebp
40006bb2:	57                   	push   %edi
40006bb3:	56                   	push   %esi
40006bb4:	53                   	push   %ebx
40006bb5:	83 ec 7c             	sub    $0x7c,%esp
	int i = 0;
40006bb8:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
40006bbf:	c7 45 bc 00 07 01 00 	movl   $0x10700,-0x44(%ebp)
40006bc6:	66 c7 45 ba 00 00    	movw   $0x0,-0x46(%ebp)
40006bcc:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)
40006bd3:	c7 45 b0 00 00 00 00 	movl   $0x0,-0x50(%ebp)
40006bda:	c7 45 ac 00 00 00 c0 	movl   $0xc0000000,-0x54(%ebp)
40006be1:	c7 45 a8 00 00 40 00 	movl   $0x400000,-0x58(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40006be8:	8b 45 bc             	mov    -0x44(%ebp),%eax
40006beb:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40006bee:	8b 5d b4             	mov    -0x4c(%ebp),%ebx
40006bf1:	0f b7 55 ba          	movzwl -0x46(%ebp),%edx
40006bf5:	8b 75 b0             	mov    -0x50(%ebp),%esi
40006bf8:	8b 7d ac             	mov    -0x54(%ebp),%edi
40006bfb:	8b 4d a8             	mov    -0x58(%ebp),%ecx
40006bfe:	cd 30                	int    $0x30
	// in _our_ address space while we're copying the arguments,
	// but the pointers we're writing into this space will be
	// interpreted by the newly executed process,
	// where the stack will be mapped from VM_STACKHI-PTSIZE to VM_STACKHI.
	//warn("exec_copyargs not implemented yet");
	uint32_t argc= 0;
40006c00:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
	while(argv[argc]){
40006c07:	eb 04                	jmp    40006c0d <exec_copyargs+0x5e>
		argc++;
40006c09:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
	// but the pointers we're writing into this space will be
	// interpreted by the newly executed process,
	// where the stack will be mapped from VM_STACKHI-PTSIZE to VM_STACKHI.
	//warn("exec_copyargs not implemented yet");
	uint32_t argc= 0;
	while(argv[argc]){
40006c0d:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006c10:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
40006c17:	8b 45 08             	mov    0x8(%ebp),%eax
40006c1a:	01 d0                	add    %edx,%eax
40006c1c:	8b 00                	mov    (%eax),%eax
40006c1e:	85 c0                	test   %eax,%eax
40006c20:	75 e7                	jne    40006c09 <exec_copyargs+0x5a>
		argc++;
	}

	uint32_t ofs = VM_STACKHI - VM_SCRATCHLO - PTSIZE;
40006c22:	c7 45 d8 00 00 c0 2f 	movl   $0x2fc00000,-0x28(%ebp)
	intptr_t esp_start = VM_SCRATCHLO + PTSIZE;
40006c29:	c7 45 d4 00 00 40 c0 	movl   $0xc0400000,-0x2c(%ebp)
	intptr_t esp = esp_start;
40006c30:	8b 45 d4             	mov    -0x2c(%ebp),%eax
40006c33:	89 45 dc             	mov    %eax,-0x24(%ebp)
	esp -=4 * (argc+1);
40006c36:	8b 45 dc             	mov    -0x24(%ebp),%eax
40006c39:	8b 55 e0             	mov    -0x20(%ebp),%edx
40006c3c:	83 c2 01             	add    $0x1,%edx
40006c3f:	c1 e2 02             	shl    $0x2,%edx
40006c42:	29 d0                	sub    %edx,%eax
40006c44:	89 45 dc             	mov    %eax,-0x24(%ebp)
	intptr_t init_argv_pos = esp;
40006c47:	8b 45 dc             	mov    -0x24(%ebp),%eax
40006c4a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for(i = argc-1; i >= 0; i--){
40006c4d:	8b 45 e0             	mov    -0x20(%ebp),%eax
40006c50:	83 e8 01             	sub    $0x1,%eax
40006c53:	89 45 e4             	mov    %eax,-0x1c(%ebp)
40006c56:	eb 62                	jmp    40006cba <exec_copyargs+0x10b>
		int len = strlen(argv[i]) + 1;
40006c58:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006c5b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
40006c62:	8b 45 08             	mov    0x8(%ebp),%eax
40006c65:	01 d0                	add    %edx,%eax
40006c67:	8b 00                	mov    (%eax),%eax
40006c69:	89 04 24             	mov    %eax,(%esp)
40006c6c:	e8 e7 c2 ff ff       	call   40002f58 <strlen>
40006c71:	83 c0 01             	add    $0x1,%eax
40006c74:	89 45 cc             	mov    %eax,-0x34(%ebp)
		esp -= len;
40006c77:	8b 45 cc             	mov    -0x34(%ebp),%eax
40006c7a:	29 45 dc             	sub    %eax,-0x24(%ebp)
		strcpy((void*)esp, argv[i]);
40006c7d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006c80:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
40006c87:	8b 45 08             	mov    0x8(%ebp),%eax
40006c8a:	01 d0                	add    %edx,%eax
40006c8c:	8b 10                	mov    (%eax),%edx
40006c8e:	8b 45 dc             	mov    -0x24(%ebp),%eax
40006c91:	89 54 24 04          	mov    %edx,0x4(%esp)
40006c95:	89 04 24             	mov    %eax,(%esp)
40006c98:	e8 e1 c2 ff ff       	call   40002f7e <strcpy>
		((intptr_t*)init_argv_pos)[i]= esp + ofs;
40006c9d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40006ca0:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
40006ca7:	8b 45 d0             	mov    -0x30(%ebp),%eax
40006caa:	01 d0                	add    %edx,%eax
40006cac:	8b 4d dc             	mov    -0x24(%ebp),%ecx
40006caf:	8b 55 d8             	mov    -0x28(%ebp),%edx
40006cb2:	01 ca                	add    %ecx,%edx
40006cb4:	89 10                	mov    %edx,(%eax)
	uint32_t ofs = VM_STACKHI - VM_SCRATCHLO - PTSIZE;
	intptr_t esp_start = VM_SCRATCHLO + PTSIZE;
	intptr_t esp = esp_start;
	esp -=4 * (argc+1);
	intptr_t init_argv_pos = esp;
	for(i = argc-1; i >= 0; i--){
40006cb6:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
40006cba:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
40006cbe:	79 98                	jns    40006c58 <exec_copyargs+0xa9>
		int len = strlen(argv[i]) + 1;
		esp -= len;
		strcpy((void*)esp, argv[i]);
		((intptr_t*)init_argv_pos)[i]= esp + ofs;
	}
	int strsize = ROUNDUP(init_argv_pos - esp, 4);
40006cc0:	c7 45 c8 04 00 00 00 	movl   $0x4,-0x38(%ebp)
40006cc7:	8b 45 dc             	mov    -0x24(%ebp),%eax
40006cca:	8b 55 d0             	mov    -0x30(%ebp),%edx
40006ccd:	89 d1                	mov    %edx,%ecx
40006ccf:	29 c1                	sub    %eax,%ecx
40006cd1:	89 c8                	mov    %ecx,%eax
40006cd3:	89 c2                	mov    %eax,%edx
40006cd5:	8b 45 c8             	mov    -0x38(%ebp),%eax
40006cd8:	01 d0                	add    %edx,%eax
40006cda:	83 e8 01             	sub    $0x1,%eax
40006cdd:	89 45 c4             	mov    %eax,-0x3c(%ebp)
40006ce0:	8b 45 c4             	mov    -0x3c(%ebp),%eax
40006ce3:	ba 00 00 00 00       	mov    $0x0,%edx
40006ce8:	f7 75 c8             	divl   -0x38(%ebp)
40006ceb:	89 d0                	mov    %edx,%eax
40006ced:	8b 55 c4             	mov    -0x3c(%ebp),%edx
40006cf0:	89 d1                	mov    %edx,%ecx
40006cf2:	29 c1                	sub    %eax,%ecx
40006cf4:	89 c8                	mov    %ecx,%eax
40006cf6:	89 45 c0             	mov    %eax,-0x40(%ebp)
	esp = init_argv_pos - strsize;
40006cf9:	8b 45 c0             	mov    -0x40(%ebp),%eax
40006cfc:	8b 55 d0             	mov    -0x30(%ebp),%edx
40006cff:	89 d1                	mov    %edx,%ecx
40006d01:	29 c1                	sub    %eax,%ecx
40006d03:	89 c8                	mov    %ecx,%eax
40006d05:	89 45 dc             	mov    %eax,-0x24(%ebp)
	esp -= 4;
40006d08:	83 6d dc 04          	subl   $0x4,-0x24(%ebp)
	*(intptr_t*)esp = init_argv_pos + ofs;
40006d0c:	8b 45 dc             	mov    -0x24(%ebp),%eax
40006d0f:	8b 4d d0             	mov    -0x30(%ebp),%ecx
40006d12:	8b 55 d8             	mov    -0x28(%ebp),%edx
40006d15:	01 ca                	add    %ecx,%edx
40006d17:	89 10                	mov    %edx,(%eax)
	esp -= 4;
40006d19:	83 6d dc 04          	subl   $0x4,-0x24(%ebp)
	*(intptr_t*)esp = argc;
40006d1d:	8b 45 dc             	mov    -0x24(%ebp),%eax
40006d20:	8b 55 e0             	mov    -0x20(%ebp),%edx
40006d23:	89 10                	mov    %edx,(%eax)
	esp = esp + ofs;
40006d25:	8b 55 dc             	mov    -0x24(%ebp),%edx
40006d28:	8b 45 d8             	mov    -0x28(%ebp),%eax
40006d2b:	01 d0                	add    %edx,%eax
40006d2d:	89 45 dc             	mov    %eax,-0x24(%ebp)
40006d30:	c7 45 a4 00 00 02 00 	movl   $0x20000,-0x5c(%ebp)
40006d37:	66 c7 45 a2 00 00    	movw   $0x0,-0x5e(%ebp)
40006d3d:	c7 45 9c 00 00 00 00 	movl   $0x0,-0x64(%ebp)
40006d44:	c7 45 98 00 00 00 c0 	movl   $0xc0000000,-0x68(%ebp)
40006d4b:	c7 45 94 00 00 c0 ef 	movl   $0xefc00000,-0x6c(%ebp)
40006d52:	c7 45 90 00 00 40 00 	movl   $0x400000,-0x70(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40006d59:	8b 45 a4             	mov    -0x5c(%ebp),%eax
40006d5c:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40006d5f:	8b 5d 9c             	mov    -0x64(%ebp),%ebx
40006d62:	0f b7 55 a2          	movzwl -0x5e(%ebp),%edx
40006d66:	8b 75 98             	mov    -0x68(%ebp),%esi
40006d69:	8b 7d 94             	mov    -0x6c(%ebp),%edi
40006d6c:	8b 4d 90             	mov    -0x70(%ebp),%ecx
40006d6f:	cd 30                	int    $0x30
	// Copy the stack into its correct position in child 0.
	sys_put(SYS_COPY, 0, NULL, (void*)VM_SCRATCHLO,
		(void*)VM_STACKHI-PTSIZE, PTSIZE);
	return esp;
40006d71:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
40006d74:	83 c4 7c             	add    $0x7c,%esp
40006d77:	5b                   	pop    %ebx
40006d78:	5e                   	pop    %esi
40006d79:	5f                   	pop    %edi
40006d7a:	5d                   	pop    %ebp
40006d7b:	c3                   	ret    

40006d7c <writebuf>:
};


static void
writebuf(struct printbuf *b)
{
40006d7c:	55                   	push   %ebp
40006d7d:	89 e5                	mov    %esp,%ebp
40006d7f:	83 ec 28             	sub    $0x28,%esp
	if (!b->err) {
40006d82:	8b 45 08             	mov    0x8(%ebp),%eax
40006d85:	8b 40 0c             	mov    0xc(%eax),%eax
40006d88:	85 c0                	test   %eax,%eax
40006d8a:	75 56                	jne    40006de2 <writebuf+0x66>
		size_t result = fwrite(b->buf, 1, b->idx, b->fh);
40006d8c:	8b 45 08             	mov    0x8(%ebp),%eax
40006d8f:	8b 10                	mov    (%eax),%edx
40006d91:	8b 45 08             	mov    0x8(%ebp),%eax
40006d94:	8b 40 04             	mov    0x4(%eax),%eax
40006d97:	8b 4d 08             	mov    0x8(%ebp),%ecx
40006d9a:	83 c1 10             	add    $0x10,%ecx
40006d9d:	89 54 24 0c          	mov    %edx,0xc(%esp)
40006da1:	89 44 24 08          	mov    %eax,0x8(%esp)
40006da5:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40006dac:	00 
40006dad:	89 0c 24             	mov    %ecx,(%esp)
40006db0:	e8 75 e0 ff ff       	call   40004e2a <fwrite>
40006db5:	89 45 f4             	mov    %eax,-0xc(%ebp)
		b->result += result;
40006db8:	8b 45 08             	mov    0x8(%ebp),%eax
40006dbb:	8b 40 08             	mov    0x8(%eax),%eax
40006dbe:	89 c2                	mov    %eax,%edx
40006dc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
40006dc3:	01 d0                	add    %edx,%eax
40006dc5:	89 c2                	mov    %eax,%edx
40006dc7:	8b 45 08             	mov    0x8(%ebp),%eax
40006dca:	89 50 08             	mov    %edx,0x8(%eax)
		if (result != b->idx) // error, or wrote less than supplied
40006dcd:	8b 45 08             	mov    0x8(%ebp),%eax
40006dd0:	8b 40 04             	mov    0x4(%eax),%eax
40006dd3:	3b 45 f4             	cmp    -0xc(%ebp),%eax
40006dd6:	74 0a                	je     40006de2 <writebuf+0x66>
			b->err = 1;
40006dd8:	8b 45 08             	mov    0x8(%ebp),%eax
40006ddb:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
	}
}
40006de2:	c9                   	leave  
40006de3:	c3                   	ret    

40006de4 <putch>:

static void
putch(int ch, void *thunk)
{
40006de4:	55                   	push   %ebp
40006de5:	89 e5                	mov    %esp,%ebp
40006de7:	83 ec 28             	sub    $0x28,%esp
	struct printbuf *b = (struct printbuf *) thunk;
40006dea:	8b 45 0c             	mov    0xc(%ebp),%eax
40006ded:	89 45 f4             	mov    %eax,-0xc(%ebp)
	b->buf[b->idx++] = ch;
40006df0:	8b 45 f4             	mov    -0xc(%ebp),%eax
40006df3:	8b 40 04             	mov    0x4(%eax),%eax
40006df6:	8b 55 08             	mov    0x8(%ebp),%edx
40006df9:	89 d1                	mov    %edx,%ecx
40006dfb:	8b 55 f4             	mov    -0xc(%ebp),%edx
40006dfe:	88 4c 02 10          	mov    %cl,0x10(%edx,%eax,1)
40006e02:	8d 50 01             	lea    0x1(%eax),%edx
40006e05:	8b 45 f4             	mov    -0xc(%ebp),%eax
40006e08:	89 50 04             	mov    %edx,0x4(%eax)
	if (b->idx == 256) {
40006e0b:	8b 45 f4             	mov    -0xc(%ebp),%eax
40006e0e:	8b 40 04             	mov    0x4(%eax),%eax
40006e11:	3d 00 01 00 00       	cmp    $0x100,%eax
40006e16:	75 15                	jne    40006e2d <putch+0x49>
		writebuf(b);
40006e18:	8b 45 f4             	mov    -0xc(%ebp),%eax
40006e1b:	89 04 24             	mov    %eax,(%esp)
40006e1e:	e8 59 ff ff ff       	call   40006d7c <writebuf>
		b->idx = 0;
40006e23:	8b 45 f4             	mov    -0xc(%ebp),%eax
40006e26:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	}
}
40006e2d:	c9                   	leave  
40006e2e:	c3                   	ret    

40006e2f <vfprintf>:

int
vfprintf(FILE *fh, const char *fmt, va_list ap)
{
40006e2f:	55                   	push   %ebp
40006e30:	89 e5                	mov    %esp,%ebp
40006e32:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.fh = fh;
40006e38:	8b 45 08             	mov    0x8(%ebp),%eax
40006e3b:	89 85 e8 fe ff ff    	mov    %eax,-0x118(%ebp)
	b.idx = 0;
40006e41:	c7 85 ec fe ff ff 00 	movl   $0x0,-0x114(%ebp)
40006e48:	00 00 00 
	b.result = 0;
40006e4b:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
40006e52:	00 00 00 
	b.err = 0;
40006e55:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
40006e5c:	00 00 00 
	vprintfmt(putch, &b, fmt, ap);
40006e5f:	8b 45 10             	mov    0x10(%ebp),%eax
40006e62:	89 44 24 0c          	mov    %eax,0xc(%esp)
40006e66:	8b 45 0c             	mov    0xc(%ebp),%eax
40006e69:	89 44 24 08          	mov    %eax,0x8(%esp)
40006e6d:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
40006e73:	89 44 24 04          	mov    %eax,0x4(%esp)
40006e77:	c7 04 24 e4 6d 00 40 	movl   $0x40006de4,(%esp)
40006e7e:	e8 3e bd ff ff       	call   40002bc1 <vprintfmt>
	if (b.idx > 0)
40006e83:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
40006e89:	85 c0                	test   %eax,%eax
40006e8b:	7e 0e                	jle    40006e9b <vfprintf+0x6c>
		writebuf(&b);
40006e8d:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
40006e93:	89 04 24             	mov    %eax,(%esp)
40006e96:	e8 e1 fe ff ff       	call   40006d7c <writebuf>

	return b.result;
40006e9b:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
}
40006ea1:	c9                   	leave  
40006ea2:	c3                   	ret    

40006ea3 <fprintf>:

int
fprintf(FILE *fh, const char *fmt, ...)
{
40006ea3:	55                   	push   %ebp
40006ea4:	89 e5                	mov    %esp,%ebp
40006ea6:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
40006ea9:	8d 45 0c             	lea    0xc(%ebp),%eax
40006eac:	83 c0 04             	add    $0x4,%eax
40006eaf:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vfprintf(fh, fmt, ap);
40006eb2:	8b 45 0c             	mov    0xc(%ebp),%eax
40006eb5:	8b 55 f4             	mov    -0xc(%ebp),%edx
40006eb8:	89 54 24 08          	mov    %edx,0x8(%esp)
40006ebc:	89 44 24 04          	mov    %eax,0x4(%esp)
40006ec0:	8b 45 08             	mov    0x8(%ebp),%eax
40006ec3:	89 04 24             	mov    %eax,(%esp)
40006ec6:	e8 64 ff ff ff       	call   40006e2f <vfprintf>
40006ecb:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
40006ece:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40006ed1:	c9                   	leave  
40006ed2:	c3                   	ret    

40006ed3 <printf>:

int
printf(const char *fmt, ...)
{
40006ed3:	55                   	push   %ebp
40006ed4:	89 e5                	mov    %esp,%ebp
40006ed6:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
40006ed9:	8d 45 0c             	lea    0xc(%ebp),%eax
40006edc:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vfprintf(stdout, fmt, ap);
40006edf:	8b 55 08             	mov    0x8(%ebp),%edx
40006ee2:	a1 dc 83 00 40       	mov    0x400083dc,%eax
40006ee7:	8b 4d f4             	mov    -0xc(%ebp),%ecx
40006eea:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40006eee:	89 54 24 04          	mov    %edx,0x4(%esp)
40006ef2:	89 04 24             	mov    %eax,(%esp)
40006ef5:	e8 35 ff ff ff       	call   40006e2f <vfprintf>
40006efa:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
40006efd:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40006f00:	c9                   	leave  
40006f01:	c3                   	ret    
40006f02:	66 90                	xchg   %ax,%ax

40006f04 <strerror>:
#include <inc/stdio.h>

char *
strerror(int err)
{
40006f04:	55                   	push   %ebp
40006f05:	89 e5                	mov    %esp,%ebp
40006f07:	83 ec 28             	sub    $0x28,%esp
		"No child processes",
		"Conflict detected",
	};
	static char errbuf[64];

	const int tablen = sizeof(errtab)/sizeof(errtab[0]);
40006f0a:	c7 45 f4 0b 00 00 00 	movl   $0xb,-0xc(%ebp)
	if (err >= 0 && err < sizeof(errtab)/sizeof(errtab[0]))
40006f11:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40006f15:	78 14                	js     40006f2b <strerror+0x27>
40006f17:	8b 45 08             	mov    0x8(%ebp),%eax
40006f1a:	83 f8 0a             	cmp    $0xa,%eax
40006f1d:	77 0c                	ja     40006f2b <strerror+0x27>
		return errtab[err];
40006f1f:	8b 45 08             	mov    0x8(%ebp),%eax
40006f22:	8b 04 85 00 a8 00 40 	mov    0x4000a800(,%eax,4),%eax
40006f29:	eb 20                	jmp    40006f4b <strerror+0x47>

	sprintf(errbuf, "Unknown error code %d", err);
40006f2b:	8b 45 08             	mov    0x8(%ebp),%eax
40006f2e:	89 44 24 08          	mov    %eax,0x8(%esp)
40006f32:	c7 44 24 04 b0 87 00 	movl   $0x400087b0,0x4(%esp)
40006f39:	40 
40006f3a:	c7 04 24 40 d8 00 40 	movl   $0x4000d840,(%esp)
40006f41:	e8 0f 02 00 00       	call   40007155 <sprintf>
	return errbuf;
40006f46:	b8 40 d8 00 40       	mov    $0x4000d840,%eax
}
40006f4b:	c9                   	leave  
40006f4c:	c3                   	ret    
40006f4d:	66 90                	xchg   %ax,%ax
40006f4f:	90                   	nop

40006f50 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
40006f50:	55                   	push   %ebp
40006f51:	89 e5                	mov    %esp,%ebp
40006f53:	83 ec 28             	sub    $0x28,%esp
	int i, c, echoing;

	if (prompt != NULL)
40006f56:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
40006f5a:	74 1c                	je     40006f78 <readline+0x28>
		fprintf(stdout, "%s", prompt);
40006f5c:	a1 dc 83 00 40       	mov    0x400083dc,%eax
40006f61:	8b 55 08             	mov    0x8(%ebp),%edx
40006f64:	89 54 24 08          	mov    %edx,0x8(%esp)
40006f68:	c7 44 24 04 a2 88 00 	movl   $0x400088a2,0x4(%esp)
40006f6f:	40 
40006f70:	89 04 24             	mov    %eax,(%esp)
40006f73:	e8 2b ff ff ff       	call   40006ea3 <fprintf>

	i = 0;
40006f78:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	echoing = isatty(0);
40006f7f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40006f86:	e8 30 e5 ff ff       	call   400054bb <isatty>
40006f8b:	89 45 f0             	mov    %eax,-0x10(%ebp)
40006f8e:	eb 01                	jmp    40006f91 <readline+0x41>
				fflush(stdout);
			}
			buf[i] = 0;
			return buf;
		}
	}
40006f90:	90                   	nop
		fprintf(stdout, "%s", prompt);

	i = 0;
	echoing = isatty(0);
	while (1) {
		c = getchar();
40006f91:	a1 d8 83 00 40       	mov    0x400083d8,%eax
40006f96:	89 04 24             	mov    %eax,(%esp)
40006f99:	e8 d6 dd ff ff       	call   40004d74 <fgetc>
40006f9e:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (c < 0) {
40006fa1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
40006fa5:	79 23                	jns    40006fca <readline+0x7a>
			if (c != EOF)
40006fa7:	83 7d ec ff          	cmpl   $0xffffffff,-0x14(%ebp)
40006fab:	74 13                	je     40006fc0 <readline+0x70>
				cprintf("read error: %e\n", c);
40006fad:	8b 45 ec             	mov    -0x14(%ebp),%eax
40006fb0:	89 44 24 04          	mov    %eax,0x4(%esp)
40006fb4:	c7 04 24 a5 88 00 40 	movl   $0x400088a5,(%esp)
40006fbb:	e8 b8 b8 ff ff       	call   40002878 <cprintf>
			return NULL;
40006fc0:	b8 00 00 00 00       	mov    $0x0,%eax
40006fc5:	e9 c2 00 00 00       	jmp    4000708c <readline+0x13c>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
40006fca:	83 7d ec 08          	cmpl   $0x8,-0x14(%ebp)
40006fce:	74 06                	je     40006fd6 <readline+0x86>
40006fd0:	83 7d ec 7f          	cmpl   $0x7f,-0x14(%ebp)
40006fd4:	75 2a                	jne    40007000 <readline+0xb0>
40006fd6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
40006fda:	7e 24                	jle    40007000 <readline+0xb0>
			if (echoing)
40006fdc:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40006fe0:	74 15                	je     40006ff7 <readline+0xa7>
				putchar('\b');
40006fe2:	a1 dc 83 00 40       	mov    0x400083dc,%eax
40006fe7:	89 44 24 04          	mov    %eax,0x4(%esp)
40006feb:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
40006ff2:	e8 b9 dd ff ff       	call   40004db0 <fputc>
			i--;
40006ff7:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
40006ffb:	e9 87 00 00 00       	jmp    40007087 <readline+0x137>
		} else if (c >= ' ' && i < BUFLEN-1) {
40007000:	83 7d ec 1f          	cmpl   $0x1f,-0x14(%ebp)
40007004:	7e 37                	jle    4000703d <readline+0xed>
40007006:	81 7d f4 fe 03 00 00 	cmpl   $0x3fe,-0xc(%ebp)
4000700d:	7f 2e                	jg     4000703d <readline+0xed>
			if (echoing)
4000700f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40007013:	74 14                	je     40007029 <readline+0xd9>
				putchar(c);
40007015:	a1 dc 83 00 40       	mov    0x400083dc,%eax
4000701a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000701e:	8b 45 ec             	mov    -0x14(%ebp),%eax
40007021:	89 04 24             	mov    %eax,(%esp)
40007024:	e8 87 dd ff ff       	call   40004db0 <fputc>
			buf[i++] = c;
40007029:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000702c:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000702f:	81 c2 80 d8 00 40    	add    $0x4000d880,%edx
40007035:	88 02                	mov    %al,(%edx)
40007037:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
4000703b:	eb 4a                	jmp    40007087 <readline+0x137>
		} else if (c == '\n' || c == '\r') {
4000703d:	83 7d ec 0a          	cmpl   $0xa,-0x14(%ebp)
40007041:	74 0a                	je     4000704d <readline+0xfd>
40007043:	83 7d ec 0d          	cmpl   $0xd,-0x14(%ebp)
40007047:	0f 85 43 ff ff ff    	jne    40006f90 <readline+0x40>
			if (echoing) {
4000704d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40007051:	74 22                	je     40007075 <readline+0x125>
				putchar('\n');
40007053:	a1 dc 83 00 40       	mov    0x400083dc,%eax
40007058:	89 44 24 04          	mov    %eax,0x4(%esp)
4000705c:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
40007063:	e8 48 dd ff ff       	call   40004db0 <fputc>
				fflush(stdout);
40007068:	a1 dc 83 00 40       	mov    0x400083dc,%eax
4000706d:	89 04 24             	mov    %eax,(%esp)
40007070:	e8 bd df ff ff       	call   40005032 <fflush>
			}
			buf[i] = 0;
40007075:	8b 45 f4             	mov    -0xc(%ebp),%eax
40007078:	05 80 d8 00 40       	add    $0x4000d880,%eax
4000707d:	c6 00 00             	movb   $0x0,(%eax)
			return buf;
40007080:	b8 80 d8 00 40       	mov    $0x4000d880,%eax
40007085:	eb 05                	jmp    4000708c <readline+0x13c>
		}
	}
40007087:	e9 04 ff ff ff       	jmp    40006f90 <readline+0x40>
}
4000708c:	c9                   	leave  
4000708d:	c3                   	ret    
4000708e:	66 90                	xchg   %ax,%ax

40007090 <cputs>:

#include <inc/stdio.h>
#include <inc/syscall.h>

void cputs(const char *str)
{
40007090:	55                   	push   %ebp
40007091:	89 e5                	mov    %esp,%ebp
40007093:	53                   	push   %ebx
40007094:	83 ec 10             	sub    $0x10,%esp
40007097:	8b 45 08             	mov    0x8(%ebp),%eax
4000709a:	89 45 f8             	mov    %eax,-0x8(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
4000709d:	b8 00 00 00 00       	mov    $0x0,%eax
400070a2:	8b 55 f8             	mov    -0x8(%ebp),%edx
400070a5:	89 d3                	mov    %edx,%ebx
400070a7:	cd 30                	int    $0x30
	sys_cputs(str);
}
400070a9:	83 c4 10             	add    $0x10,%esp
400070ac:	5b                   	pop    %ebx
400070ad:	5d                   	pop    %ebp
400070ae:	c3                   	ret    
400070af:	90                   	nop

400070b0 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
400070b0:	55                   	push   %ebp
400070b1:	89 e5                	mov    %esp,%ebp
	b->cnt++;
400070b3:	8b 45 0c             	mov    0xc(%ebp),%eax
400070b6:	8b 40 08             	mov    0x8(%eax),%eax
400070b9:	8d 50 01             	lea    0x1(%eax),%edx
400070bc:	8b 45 0c             	mov    0xc(%ebp),%eax
400070bf:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
400070c2:	8b 45 0c             	mov    0xc(%ebp),%eax
400070c5:	8b 10                	mov    (%eax),%edx
400070c7:	8b 45 0c             	mov    0xc(%ebp),%eax
400070ca:	8b 40 04             	mov    0x4(%eax),%eax
400070cd:	39 c2                	cmp    %eax,%edx
400070cf:	73 12                	jae    400070e3 <sprintputch+0x33>
		*b->buf++ = ch;
400070d1:	8b 45 0c             	mov    0xc(%ebp),%eax
400070d4:	8b 00                	mov    (%eax),%eax
400070d6:	8b 55 08             	mov    0x8(%ebp),%edx
400070d9:	88 10                	mov    %dl,(%eax)
400070db:	8d 50 01             	lea    0x1(%eax),%edx
400070de:	8b 45 0c             	mov    0xc(%ebp),%eax
400070e1:	89 10                	mov    %edx,(%eax)
}
400070e3:	5d                   	pop    %ebp
400070e4:	c3                   	ret    

400070e5 <vsprintf>:

int
vsprintf(char *buf, const char *fmt, va_list ap)
{
400070e5:	55                   	push   %ebp
400070e6:	89 e5                	mov    %esp,%ebp
400070e8:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL);
400070eb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
400070ef:	75 24                	jne    40007115 <vsprintf+0x30>
400070f1:	c7 44 24 0c b5 88 00 	movl   $0x400088b5,0xc(%esp)
400070f8:	40 
400070f9:	c7 44 24 08 c1 88 00 	movl   $0x400088c1,0x8(%esp)
40007100:	40 
40007101:	c7 44 24 04 19 00 00 	movl   $0x19,0x4(%esp)
40007108:	00 
40007109:	c7 04 24 d6 88 00 40 	movl   $0x400088d6,(%esp)
40007110:	e8 cf b4 ff ff       	call   400025e4 <debug_panic>
	struct sprintbuf b = {buf, (char*)(intptr_t)~0, 0};
40007115:	8b 45 08             	mov    0x8(%ebp),%eax
40007118:	89 45 ec             	mov    %eax,-0x14(%ebp)
4000711b:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
40007122:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
40007129:	8b 45 10             	mov    0x10(%ebp),%eax
4000712c:	89 44 24 0c          	mov    %eax,0xc(%esp)
40007130:	8b 45 0c             	mov    0xc(%ebp),%eax
40007133:	89 44 24 08          	mov    %eax,0x8(%esp)
40007137:	8d 45 ec             	lea    -0x14(%ebp),%eax
4000713a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000713e:	c7 04 24 b0 70 00 40 	movl   $0x400070b0,(%esp)
40007145:	e8 77 ba ff ff       	call   40002bc1 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
4000714a:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000714d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
40007150:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
40007153:	c9                   	leave  
40007154:	c3                   	ret    

40007155 <sprintf>:

int
sprintf(char *buf, const char *fmt, ...)
{
40007155:	55                   	push   %ebp
40007156:	89 e5                	mov    %esp,%ebp
40007158:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
4000715b:	8d 45 0c             	lea    0xc(%ebp),%eax
4000715e:	83 c0 04             	add    $0x4,%eax
40007161:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsprintf(buf, fmt, ap);
40007164:	8b 45 0c             	mov    0xc(%ebp),%eax
40007167:	8b 55 f4             	mov    -0xc(%ebp),%edx
4000716a:	89 54 24 08          	mov    %edx,0x8(%esp)
4000716e:	89 44 24 04          	mov    %eax,0x4(%esp)
40007172:	8b 45 08             	mov    0x8(%ebp),%eax
40007175:	89 04 24             	mov    %eax,(%esp)
40007178:	e8 68 ff ff ff       	call   400070e5 <vsprintf>
4000717d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
40007180:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40007183:	c9                   	leave  
40007184:	c3                   	ret    

40007185 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
40007185:	55                   	push   %ebp
40007186:	89 e5                	mov    %esp,%ebp
40007188:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL && n > 0);
4000718b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
4000718f:	74 06                	je     40007197 <vsnprintf+0x12>
40007191:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
40007195:	7f 24                	jg     400071bb <vsnprintf+0x36>
40007197:	c7 44 24 0c e4 88 00 	movl   $0x400088e4,0xc(%esp)
4000719e:	40 
4000719f:	c7 44 24 08 c1 88 00 	movl   $0x400088c1,0x8(%esp)
400071a6:	40 
400071a7:	c7 44 24 04 35 00 00 	movl   $0x35,0x4(%esp)
400071ae:	00 
400071af:	c7 04 24 d6 88 00 40 	movl   $0x400088d6,(%esp)
400071b6:	e8 29 b4 ff ff       	call   400025e4 <debug_panic>
	struct sprintbuf b = {buf, buf+n-1, 0};
400071bb:	8b 45 08             	mov    0x8(%ebp),%eax
400071be:	89 45 ec             	mov    %eax,-0x14(%ebp)
400071c1:	8b 45 0c             	mov    0xc(%ebp),%eax
400071c4:	8d 50 ff             	lea    -0x1(%eax),%edx
400071c7:	8b 45 08             	mov    0x8(%ebp),%eax
400071ca:	01 d0                	add    %edx,%eax
400071cc:	89 45 f0             	mov    %eax,-0x10(%ebp)
400071cf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
400071d6:	8b 45 14             	mov    0x14(%ebp),%eax
400071d9:	89 44 24 0c          	mov    %eax,0xc(%esp)
400071dd:	8b 45 10             	mov    0x10(%ebp),%eax
400071e0:	89 44 24 08          	mov    %eax,0x8(%esp)
400071e4:	8d 45 ec             	lea    -0x14(%ebp),%eax
400071e7:	89 44 24 04          	mov    %eax,0x4(%esp)
400071eb:	c7 04 24 b0 70 00 40 	movl   $0x400070b0,(%esp)
400071f2:	e8 ca b9 ff ff       	call   40002bc1 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
400071f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
400071fa:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
400071fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
40007200:	c9                   	leave  
40007201:	c3                   	ret    

40007202 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
40007202:	55                   	push   %ebp
40007203:	89 e5                	mov    %esp,%ebp
40007205:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
40007208:	8d 45 10             	lea    0x10(%ebp),%eax
4000720b:	83 c0 04             	add    $0x4,%eax
4000720e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
40007211:	8b 45 10             	mov    0x10(%ebp),%eax
40007214:	8b 55 f4             	mov    -0xc(%ebp),%edx
40007217:	89 54 24 0c          	mov    %edx,0xc(%esp)
4000721b:	89 44 24 08          	mov    %eax,0x8(%esp)
4000721f:	8b 45 0c             	mov    0xc(%ebp),%eax
40007222:	89 44 24 04          	mov    %eax,0x4(%esp)
40007226:	8b 45 08             	mov    0x8(%ebp),%eax
40007229:	89 04 24             	mov    %eax,(%esp)
4000722c:	e8 54 ff ff ff       	call   40007185 <vsnprintf>
40007231:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
40007234:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
40007237:	c9                   	leave  
40007238:	c3                   	ret    
40007239:	66 90                	xchg   %ax,%ax
4000723b:	66 90                	xchg   %ax,%ax
4000723d:	66 90                	xchg   %ax,%ax
4000723f:	90                   	nop

40007240 <__udivdi3>:
40007240:	83 ec 1c             	sub    $0x1c,%esp
40007243:	8b 44 24 2c          	mov    0x2c(%esp),%eax
40007247:	89 7c 24 14          	mov    %edi,0x14(%esp)
4000724b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
4000724f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
40007253:	8b 7c 24 20          	mov    0x20(%esp),%edi
40007257:	8b 6c 24 24          	mov    0x24(%esp),%ebp
4000725b:	85 c0                	test   %eax,%eax
4000725d:	89 74 24 10          	mov    %esi,0x10(%esp)
40007261:	89 7c 24 08          	mov    %edi,0x8(%esp)
40007265:	89 ea                	mov    %ebp,%edx
40007267:	89 4c 24 04          	mov    %ecx,0x4(%esp)
4000726b:	75 33                	jne    400072a0 <__udivdi3+0x60>
4000726d:	39 e9                	cmp    %ebp,%ecx
4000726f:	77 6f                	ja     400072e0 <__udivdi3+0xa0>
40007271:	85 c9                	test   %ecx,%ecx
40007273:	89 ce                	mov    %ecx,%esi
40007275:	75 0b                	jne    40007282 <__udivdi3+0x42>
40007277:	b8 01 00 00 00       	mov    $0x1,%eax
4000727c:	31 d2                	xor    %edx,%edx
4000727e:	f7 f1                	div    %ecx
40007280:	89 c6                	mov    %eax,%esi
40007282:	31 d2                	xor    %edx,%edx
40007284:	89 e8                	mov    %ebp,%eax
40007286:	f7 f6                	div    %esi
40007288:	89 c5                	mov    %eax,%ebp
4000728a:	89 f8                	mov    %edi,%eax
4000728c:	f7 f6                	div    %esi
4000728e:	89 ea                	mov    %ebp,%edx
40007290:	8b 74 24 10          	mov    0x10(%esp),%esi
40007294:	8b 7c 24 14          	mov    0x14(%esp),%edi
40007298:	8b 6c 24 18          	mov    0x18(%esp),%ebp
4000729c:	83 c4 1c             	add    $0x1c,%esp
4000729f:	c3                   	ret    
400072a0:	39 e8                	cmp    %ebp,%eax
400072a2:	77 24                	ja     400072c8 <__udivdi3+0x88>
400072a4:	0f bd c8             	bsr    %eax,%ecx
400072a7:	83 f1 1f             	xor    $0x1f,%ecx
400072aa:	89 0c 24             	mov    %ecx,(%esp)
400072ad:	75 49                	jne    400072f8 <__udivdi3+0xb8>
400072af:	8b 74 24 08          	mov    0x8(%esp),%esi
400072b3:	39 74 24 04          	cmp    %esi,0x4(%esp)
400072b7:	0f 86 ab 00 00 00    	jbe    40007368 <__udivdi3+0x128>
400072bd:	39 e8                	cmp    %ebp,%eax
400072bf:	0f 82 a3 00 00 00    	jb     40007368 <__udivdi3+0x128>
400072c5:	8d 76 00             	lea    0x0(%esi),%esi
400072c8:	31 d2                	xor    %edx,%edx
400072ca:	31 c0                	xor    %eax,%eax
400072cc:	8b 74 24 10          	mov    0x10(%esp),%esi
400072d0:	8b 7c 24 14          	mov    0x14(%esp),%edi
400072d4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
400072d8:	83 c4 1c             	add    $0x1c,%esp
400072db:	c3                   	ret    
400072dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
400072e0:	89 f8                	mov    %edi,%eax
400072e2:	f7 f1                	div    %ecx
400072e4:	31 d2                	xor    %edx,%edx
400072e6:	8b 74 24 10          	mov    0x10(%esp),%esi
400072ea:	8b 7c 24 14          	mov    0x14(%esp),%edi
400072ee:	8b 6c 24 18          	mov    0x18(%esp),%ebp
400072f2:	83 c4 1c             	add    $0x1c,%esp
400072f5:	c3                   	ret    
400072f6:	66 90                	xchg   %ax,%ax
400072f8:	0f b6 0c 24          	movzbl (%esp),%ecx
400072fc:	89 c6                	mov    %eax,%esi
400072fe:	b8 20 00 00 00       	mov    $0x20,%eax
40007303:	8b 6c 24 04          	mov    0x4(%esp),%ebp
40007307:	2b 04 24             	sub    (%esp),%eax
4000730a:	8b 7c 24 08          	mov    0x8(%esp),%edi
4000730e:	d3 e6                	shl    %cl,%esi
40007310:	89 c1                	mov    %eax,%ecx
40007312:	d3 ed                	shr    %cl,%ebp
40007314:	0f b6 0c 24          	movzbl (%esp),%ecx
40007318:	09 f5                	or     %esi,%ebp
4000731a:	8b 74 24 04          	mov    0x4(%esp),%esi
4000731e:	d3 e6                	shl    %cl,%esi
40007320:	89 c1                	mov    %eax,%ecx
40007322:	89 74 24 04          	mov    %esi,0x4(%esp)
40007326:	89 d6                	mov    %edx,%esi
40007328:	d3 ee                	shr    %cl,%esi
4000732a:	0f b6 0c 24          	movzbl (%esp),%ecx
4000732e:	d3 e2                	shl    %cl,%edx
40007330:	89 c1                	mov    %eax,%ecx
40007332:	d3 ef                	shr    %cl,%edi
40007334:	09 d7                	or     %edx,%edi
40007336:	89 f2                	mov    %esi,%edx
40007338:	89 f8                	mov    %edi,%eax
4000733a:	f7 f5                	div    %ebp
4000733c:	89 d6                	mov    %edx,%esi
4000733e:	89 c7                	mov    %eax,%edi
40007340:	f7 64 24 04          	mull   0x4(%esp)
40007344:	39 d6                	cmp    %edx,%esi
40007346:	72 30                	jb     40007378 <__udivdi3+0x138>
40007348:	8b 6c 24 08          	mov    0x8(%esp),%ebp
4000734c:	0f b6 0c 24          	movzbl (%esp),%ecx
40007350:	d3 e5                	shl    %cl,%ebp
40007352:	39 c5                	cmp    %eax,%ebp
40007354:	73 04                	jae    4000735a <__udivdi3+0x11a>
40007356:	39 d6                	cmp    %edx,%esi
40007358:	74 1e                	je     40007378 <__udivdi3+0x138>
4000735a:	89 f8                	mov    %edi,%eax
4000735c:	31 d2                	xor    %edx,%edx
4000735e:	e9 69 ff ff ff       	jmp    400072cc <__udivdi3+0x8c>
40007363:	90                   	nop
40007364:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40007368:	31 d2                	xor    %edx,%edx
4000736a:	b8 01 00 00 00       	mov    $0x1,%eax
4000736f:	e9 58 ff ff ff       	jmp    400072cc <__udivdi3+0x8c>
40007374:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40007378:	8d 47 ff             	lea    -0x1(%edi),%eax
4000737b:	31 d2                	xor    %edx,%edx
4000737d:	8b 74 24 10          	mov    0x10(%esp),%esi
40007381:	8b 7c 24 14          	mov    0x14(%esp),%edi
40007385:	8b 6c 24 18          	mov    0x18(%esp),%ebp
40007389:	83 c4 1c             	add    $0x1c,%esp
4000738c:	c3                   	ret    
4000738d:	66 90                	xchg   %ax,%ax
4000738f:	90                   	nop

40007390 <__umoddi3>:
40007390:	83 ec 2c             	sub    $0x2c,%esp
40007393:	8b 44 24 3c          	mov    0x3c(%esp),%eax
40007397:	8b 4c 24 30          	mov    0x30(%esp),%ecx
4000739b:	89 74 24 20          	mov    %esi,0x20(%esp)
4000739f:	8b 74 24 38          	mov    0x38(%esp),%esi
400073a3:	89 7c 24 24          	mov    %edi,0x24(%esp)
400073a7:	8b 7c 24 34          	mov    0x34(%esp),%edi
400073ab:	85 c0                	test   %eax,%eax
400073ad:	89 c2                	mov    %eax,%edx
400073af:	89 6c 24 28          	mov    %ebp,0x28(%esp)
400073b3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
400073b7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
400073bb:	89 74 24 10          	mov    %esi,0x10(%esp)
400073bf:	89 4c 24 14          	mov    %ecx,0x14(%esp)
400073c3:	89 7c 24 18          	mov    %edi,0x18(%esp)
400073c7:	75 1f                	jne    400073e8 <__umoddi3+0x58>
400073c9:	39 fe                	cmp    %edi,%esi
400073cb:	76 63                	jbe    40007430 <__umoddi3+0xa0>
400073cd:	89 c8                	mov    %ecx,%eax
400073cf:	89 fa                	mov    %edi,%edx
400073d1:	f7 f6                	div    %esi
400073d3:	89 d0                	mov    %edx,%eax
400073d5:	31 d2                	xor    %edx,%edx
400073d7:	8b 74 24 20          	mov    0x20(%esp),%esi
400073db:	8b 7c 24 24          	mov    0x24(%esp),%edi
400073df:	8b 6c 24 28          	mov    0x28(%esp),%ebp
400073e3:	83 c4 2c             	add    $0x2c,%esp
400073e6:	c3                   	ret    
400073e7:	90                   	nop
400073e8:	39 f8                	cmp    %edi,%eax
400073ea:	77 64                	ja     40007450 <__umoddi3+0xc0>
400073ec:	0f bd e8             	bsr    %eax,%ebp
400073ef:	83 f5 1f             	xor    $0x1f,%ebp
400073f2:	75 74                	jne    40007468 <__umoddi3+0xd8>
400073f4:	8b 7c 24 14          	mov    0x14(%esp),%edi
400073f8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
400073fc:	0f 87 0e 01 00 00    	ja     40007510 <__umoddi3+0x180>
40007402:	8b 7c 24 0c          	mov    0xc(%esp),%edi
40007406:	29 f1                	sub    %esi,%ecx
40007408:	19 c7                	sbb    %eax,%edi
4000740a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
4000740e:	89 7c 24 18          	mov    %edi,0x18(%esp)
40007412:	8b 44 24 14          	mov    0x14(%esp),%eax
40007416:	8b 54 24 18          	mov    0x18(%esp),%edx
4000741a:	8b 74 24 20          	mov    0x20(%esp),%esi
4000741e:	8b 7c 24 24          	mov    0x24(%esp),%edi
40007422:	8b 6c 24 28          	mov    0x28(%esp),%ebp
40007426:	83 c4 2c             	add    $0x2c,%esp
40007429:	c3                   	ret    
4000742a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
40007430:	85 f6                	test   %esi,%esi
40007432:	89 f5                	mov    %esi,%ebp
40007434:	75 0b                	jne    40007441 <__umoddi3+0xb1>
40007436:	b8 01 00 00 00       	mov    $0x1,%eax
4000743b:	31 d2                	xor    %edx,%edx
4000743d:	f7 f6                	div    %esi
4000743f:	89 c5                	mov    %eax,%ebp
40007441:	8b 44 24 0c          	mov    0xc(%esp),%eax
40007445:	31 d2                	xor    %edx,%edx
40007447:	f7 f5                	div    %ebp
40007449:	89 c8                	mov    %ecx,%eax
4000744b:	f7 f5                	div    %ebp
4000744d:	eb 84                	jmp    400073d3 <__umoddi3+0x43>
4000744f:	90                   	nop
40007450:	89 c8                	mov    %ecx,%eax
40007452:	89 fa                	mov    %edi,%edx
40007454:	8b 74 24 20          	mov    0x20(%esp),%esi
40007458:	8b 7c 24 24          	mov    0x24(%esp),%edi
4000745c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
40007460:	83 c4 2c             	add    $0x2c,%esp
40007463:	c3                   	ret    
40007464:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40007468:	8b 44 24 10          	mov    0x10(%esp),%eax
4000746c:	be 20 00 00 00       	mov    $0x20,%esi
40007471:	89 e9                	mov    %ebp,%ecx
40007473:	29 ee                	sub    %ebp,%esi
40007475:	d3 e2                	shl    %cl,%edx
40007477:	89 f1                	mov    %esi,%ecx
40007479:	d3 e8                	shr    %cl,%eax
4000747b:	89 e9                	mov    %ebp,%ecx
4000747d:	09 d0                	or     %edx,%eax
4000747f:	89 fa                	mov    %edi,%edx
40007481:	89 44 24 0c          	mov    %eax,0xc(%esp)
40007485:	8b 44 24 10          	mov    0x10(%esp),%eax
40007489:	d3 e0                	shl    %cl,%eax
4000748b:	89 f1                	mov    %esi,%ecx
4000748d:	89 44 24 10          	mov    %eax,0x10(%esp)
40007491:	8b 44 24 1c          	mov    0x1c(%esp),%eax
40007495:	d3 ea                	shr    %cl,%edx
40007497:	89 e9                	mov    %ebp,%ecx
40007499:	d3 e7                	shl    %cl,%edi
4000749b:	89 f1                	mov    %esi,%ecx
4000749d:	d3 e8                	shr    %cl,%eax
4000749f:	89 e9                	mov    %ebp,%ecx
400074a1:	09 f8                	or     %edi,%eax
400074a3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
400074a7:	f7 74 24 0c          	divl   0xc(%esp)
400074ab:	d3 e7                	shl    %cl,%edi
400074ad:	89 7c 24 18          	mov    %edi,0x18(%esp)
400074b1:	89 d7                	mov    %edx,%edi
400074b3:	f7 64 24 10          	mull   0x10(%esp)
400074b7:	39 d7                	cmp    %edx,%edi
400074b9:	89 c1                	mov    %eax,%ecx
400074bb:	89 54 24 14          	mov    %edx,0x14(%esp)
400074bf:	72 3b                	jb     400074fc <__umoddi3+0x16c>
400074c1:	39 44 24 18          	cmp    %eax,0x18(%esp)
400074c5:	72 31                	jb     400074f8 <__umoddi3+0x168>
400074c7:	8b 44 24 18          	mov    0x18(%esp),%eax
400074cb:	29 c8                	sub    %ecx,%eax
400074cd:	19 d7                	sbb    %edx,%edi
400074cf:	89 e9                	mov    %ebp,%ecx
400074d1:	89 fa                	mov    %edi,%edx
400074d3:	d3 e8                	shr    %cl,%eax
400074d5:	89 f1                	mov    %esi,%ecx
400074d7:	d3 e2                	shl    %cl,%edx
400074d9:	89 e9                	mov    %ebp,%ecx
400074db:	09 d0                	or     %edx,%eax
400074dd:	89 fa                	mov    %edi,%edx
400074df:	d3 ea                	shr    %cl,%edx
400074e1:	8b 74 24 20          	mov    0x20(%esp),%esi
400074e5:	8b 7c 24 24          	mov    0x24(%esp),%edi
400074e9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
400074ed:	83 c4 2c             	add    $0x2c,%esp
400074f0:	c3                   	ret    
400074f1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
400074f8:	39 d7                	cmp    %edx,%edi
400074fa:	75 cb                	jne    400074c7 <__umoddi3+0x137>
400074fc:	8b 54 24 14          	mov    0x14(%esp),%edx
40007500:	89 c1                	mov    %eax,%ecx
40007502:	2b 4c 24 10          	sub    0x10(%esp),%ecx
40007506:	1b 54 24 0c          	sbb    0xc(%esp),%edx
4000750a:	eb bb                	jmp    400074c7 <__umoddi3+0x137>
4000750c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40007510:	3b 44 24 18          	cmp    0x18(%esp),%eax
40007514:	0f 82 e8 fe ff ff    	jb     40007402 <__umoddi3+0x72>
4000751a:	e9 f3 fe ff ff       	jmp    40007412 <__umoddi3+0x82>
