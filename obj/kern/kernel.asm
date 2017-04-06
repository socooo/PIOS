
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

00100000 <_start-0xc>:
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

.globl		start,_start
start: _start:
	movw	$0x1234,0x472			# warm boot BIOS flag
  100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
  100006:	00 00                	add    %al,(%eax)
  100008:	fb                   	sti    
  100009:	4f                   	dec    %edi
  10000a:	52                   	push   %edx
  10000b:	e4 66                	in     $0x66,%al

0010000c <_start>:
  10000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
  100013:	34 12 

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
  100015:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Leave a few words on the stack for the user trap frame
	movl	$(cpu_boot+4096-SIZEOF_STRUCT_TRAPFRAME),%esp
  10001a:	bc b4 ff 10 00       	mov    $0x10ffb4,%esp

	# now to C code
	call	init
  10001f:	e8 76 00 00 00       	call   10009a <init>

00100024 <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
  100024:	eb fe                	jmp    100024 <spin>
  100026:	66 90                	xchg   %ax,%ax

00100028 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100028:	55                   	push   %ebp
  100029:	89 e5                	mov    %esp,%ebp
  10002b:	53                   	push   %ebx
  10002c:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10002f:	89 e3                	mov    %esp,%ebx
  100031:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  100034:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100037:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10003a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10003d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100042:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  100045:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100048:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10004e:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100053:	74 24                	je     100079 <cpu_cur+0x51>
  100055:	c7 44 24 0c 20 a1 10 	movl   $0x10a120,0xc(%esp)
  10005c:	00 
  10005d:	c7 44 24 08 36 a1 10 	movl   $0x10a136,0x8(%esp)
  100064:	00 
  100065:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10006c:	00 
  10006d:	c7 04 24 4b a1 10 00 	movl   $0x10a14b,(%esp)
  100074:	e8 bf 08 00 00       	call   100938 <debug_panic>
	return c;
  100079:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  10007c:	83 c4 24             	add    $0x24,%esp
  10007f:	5b                   	pop    %ebx
  100080:	5d                   	pop    %ebp
  100081:	c3                   	ret    

00100082 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100082:	55                   	push   %ebp
  100083:	89 e5                	mov    %esp,%ebp
  100085:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100088:	e8 9b ff ff ff       	call   100028 <cpu_cur>
  10008d:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  100092:	0f 94 c0             	sete   %al
  100095:	0f b6 c0             	movzbl %al,%eax
}
  100098:	c9                   	leave  
  100099:	c3                   	ret    

0010009a <init>:
// Called first from entry.S on the bootstrap processor,
// and later from boot/bootother.S on all other processors.
// As a rule, "init" functions in PIOS are called once on EACH processor.
void
init(void)
{
  10009a:	55                   	push   %ebp
  10009b:	89 e5                	mov    %esp,%ebp
  10009d:	83 ec 18             	sub    $0x18,%esp
	extern char start[], edata[], end[];
	
	// Before anything else, complete the ELF loading process.
	// Clear all uninitialized global data (BSS) in our program
	// ensuring that all static/global variables start out zero.
	if (cpu_onboot())
  1000a0:	e8 dd ff ff ff       	call   100082 <cpu_onboot>
  1000a5:	85 c0                	test   %eax,%eax
  1000a7:	74 28                	je     1000d1 <init+0x37>
		memset(edata, 0, end - edata);
  1000a9:	ba 08 c0 38 00       	mov    $0x38c008,%edx
  1000ae:	b8 39 21 18 00       	mov    $0x182139,%eax
  1000b3:	89 d1                	mov    %edx,%ecx
  1000b5:	29 c1                	sub    %eax,%ecx
  1000b7:	89 c8                	mov    %ecx,%eax
  1000b9:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000c4:	00 
  1000c5:	c7 04 24 39 21 18 00 	movl   $0x182139,(%esp)
  1000cc:	e8 70 9b 00 00       	call   109c41 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	// hong :
	// the first thing the kernel does is initialize the console device driver so that your kernel can produce visible output. 
	cons_init();
  1000d1:	e8 8f 05 00 00       	call   100665 <cons_init>
	// Lab 1: test cprintf and debug_trace
	cprintf("1234 decimal is %o octal!\n", 1234);
  1000d6:	c7 44 24 04 d2 04 00 	movl   $0x4d2,0x4(%esp)
  1000dd:	00 
  1000de:	c7 04 24 58 a1 10 00 	movl   $0x10a158,(%esp)
  1000e5:	e8 e6 97 00 00       	call   1098d0 <cprintf>
	debug_check();
  1000ea:	e8 66 0a 00 00       	call   100b55 <debug_check>
	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  1000ef:	e8 23 15 00 00       	call   101617 <cpu_init>
	trap_init();
  1000f4:	e8 8f 1a 00 00       	call   101b88 <trap_init>
	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
  1000f9:	e8 14 0d 00 00       	call   100e12 <mem_init>
	
	// Lab 2: check spinlock implementation
	if (cpu_onboot())
  1000fe:	e8 7f ff ff ff       	call   100082 <cpu_onboot>
  100103:	85 c0                	test   %eax,%eax
  100105:	74 05                	je     10010c <init+0x72>
		spinlock_check();
  100107:	e8 21 2a 00 00       	call   102b2d <spinlock_check>

	// Initialize the paged virtual memory system.
	pmap_init();
  10010c:	e8 a5 47 00 00       	call   1048b6 <pmap_init>
	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
  100111:	e8 a3 26 00 00       	call   1027b9 <mp_init>
	pic_init();		// setup the legacy PIC (mainly to disable it)
  100116:	e8 8d 88 00 00       	call   1089a8 <pic_init>
	ioapic_init();		// prepare to handle external device interrupts
  10011b:	e8 d1 8e 00 00       	call   108ff1 <ioapic_init>
	lapic_init();		// setup this CPU's local APIC
  100120:	e8 7a 8b 00 00       	call   108c9f <lapic_init>
	//cpu_bootothers();	// Get other processors started
	//cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
	//	cpu_onboot() ? "BP" : "AP");

	// Initialize the I/O system.
	file_init();		// Create root directory and console I/O files
  100125:	e8 8c 7c 00 00       	call   107db6 <file_init>
	// Lab 4: uncomment this when you can handle IRQ_SERIAL and IRQ_KBD.
	cons_intenable();	// Let the console start producing interrupts
  10012a:	e8 9a 05 00 00       	call   1006c9 <cons_intenable>
	// Initialize the process management code.
	proc_init();
  10012f:	e8 73 2f 00 00       	call   1030a7 <proc_init>
	if(cpu_onboot()){
  100134:	e8 49 ff ff ff       	call   100082 <cpu_onboot>
  100139:	85 c0                	test   %eax,%eax
  10013b:	0f 84 91 00 00 00    	je     1001d2 <init+0x138>
		proc_root= proc_alloc(NULL, 0);
  100141:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100148:	00 
  100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  100150:	e8 96 2f 00 00       	call   1030eb <proc_alloc>
  100155:	a3 90 96 38 00       	mov    %eax,0x389690
		file_initroot(proc_root);
  10015a:	a1 90 96 38 00       	mov    0x389690,%eax
  10015f:	89 04 24             	mov    %eax,(%esp)
  100162:	e8 7f 7c 00 00       	call   107de6 <file_initroot>
		load_elf(ROOTEXE_START,proc_root);
  100167:	a1 90 96 38 00       	mov    0x389690,%eax
  10016c:	89 44 24 04          	mov    %eax,0x4(%esp)
  100170:	c7 04 24 99 aa 15 00 	movl   $0x15aa99,(%esp)
  100177:	e8 eb 00 00 00       	call   100267 <load_elf>
		proc_root->sv.tf.fs = CPU_GDT_UDATA | 3;
  10017c:	a1 90 96 38 00       	mov    0x389690,%eax
  100181:	66 c7 80 d4 04 00 00 	movw   $0x23,0x4d4(%eax)
  100188:	23 00 
		proc_root->sv.tf.gs = CPU_GDT_UDATA | 3;
  10018a:	a1 90 96 38 00       	mov    0x389690,%eax
  10018f:	66 c7 80 d0 04 00 00 	movw   $0x23,0x4d0(%eax)
  100196:	23 00 
		proc_root->sv.tf.eip = (uint32_t)(0x40000100);
  100198:	a1 90 96 38 00       	mov    0x389690,%eax
  10019d:	c7 80 e8 04 00 00 00 	movl   $0x40000100,0x4e8(%eax)
  1001a4:	01 00 40 
		proc_root->sv.tf.esp = (uint32_t)(VM_USERHI -1);
  1001a7:	a1 90 96 38 00       	mov    0x389690,%eax
  1001ac:	c7 80 f4 04 00 00 ff 	movl   $0xefffffff,0x4f4(%eax)
  1001b3:	ff ff ef 
		proc_root->sv.tf.eflags = FL_IF;
  1001b6:	a1 90 96 38 00       	mov    0x389690,%eax
  1001bb:	c7 80 f0 04 00 00 00 	movl   $0x200,0x4f0(%eax)
  1001c2:	02 00 00 
		proc_ready(proc_root);
  1001c5:	a1 90 96 38 00       	mov    0x389690,%eax
  1001ca:	89 04 24             	mov    %eax,(%esp)
  1001cd:	e8 fd 30 00 00       	call   1032cf <proc_ready>
		//lcr3(mem_phys(proc_root->pdir));
	}
	proc_sched();
  1001d2:	e8 8b 32 00 00       	call   103462 <proc_sched>

001001d7 <user>:
// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  1001d7:	55                   	push   %ebp
  1001d8:	89 e5                	mov    %esp,%ebp
  1001da:	53                   	push   %ebx
  1001db:	83 ec 24             	sub    $0x24,%esp
	// hong: system haven't complete 
	 cprintf("in user()\n");
  1001de:	c7 04 24 73 a1 10 00 	movl   $0x10a173,(%esp)
  1001e5:	e8 e6 96 00 00       	call   1098d0 <cprintf>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1001ea:	89 e3                	mov    %esp,%ebx
  1001ec:	89 5d f4             	mov    %ebx,-0xc(%ebp)
        return esp;
  1001ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
	assert(read_esp() > (uint32_t) &user_stack[0]);
  1001f2:	89 c2                	mov    %eax,%edx
  1001f4:	b8 00 30 18 00       	mov    $0x183000,%eax
  1001f9:	39 c2                	cmp    %eax,%edx
  1001fb:	77 24                	ja     100221 <user+0x4a>
  1001fd:	c7 44 24 0c 80 a1 10 	movl   $0x10a180,0xc(%esp)
  100204:	00 
  100205:	c7 44 24 08 36 a1 10 	movl   $0x10a136,0x8(%esp)
  10020c:	00 
  10020d:	c7 44 24 04 8a 00 00 	movl   $0x8a,0x4(%esp)
  100214:	00 
  100215:	c7 04 24 a7 a1 10 00 	movl   $0x10a1a7,(%esp)
  10021c:	e8 17 07 00 00       	call   100938 <debug_panic>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100221:	89 e3                	mov    %esp,%ebx
  100223:	89 5d f0             	mov    %ebx,-0x10(%ebp)
        return esp;
  100226:	8b 45 f0             	mov    -0x10(%ebp),%eax
	// hong:
	// sizeof(user_stack) == 4096
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  100229:	89 c2                	mov    %eax,%edx
  10022b:	b8 00 40 18 00       	mov    $0x184000,%eax
  100230:	39 c2                	cmp    %eax,%edx
  100232:	72 24                	jb     100258 <user+0x81>
  100234:	c7 44 24 0c b4 a1 10 	movl   $0x10a1b4,0xc(%esp)
  10023b:	00 
  10023c:	c7 44 24 08 36 a1 10 	movl   $0x10a136,0x8(%esp)
  100243:	00 
  100244:	c7 44 24 04 8d 00 00 	movl   $0x8d,0x4(%esp)
  10024b:	00 
  10024c:	c7 04 24 a7 a1 10 00 	movl   $0x10a1a7,(%esp)
  100253:	e8 e0 06 00 00       	call   100938 <debug_panic>
	// Check the system call and process scheduling code.
	proc_check();
  100258:	e8 a9 33 00 00       	call   103606 <proc_check>

	done();
  10025d:	e8 00 00 00 00       	call   100262 <done>

00100262 <done>:
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
  100262:	55                   	push   %ebp
  100263:	89 e5                	mov    %esp,%ebp
	while (1)
		;	// just spin
  100265:	eb fe                	jmp    100265 <done+0x3>

00100267 <load_elf>:
}

void load_elf(char* elf, proc* p){
  100267:	55                   	push   %ebp
  100268:	89 e5                	mov    %esp,%ebp
  10026a:	53                   	push   %ebx
  10026b:	83 ec 44             	sub    $0x44,%esp
	uint32_t va, p_va_start, p_va_end;
	proghdr* phd;
	int i, j;
	pte_t* pte;
	elfhdr* elf_load = (elfhdr*)elf;
  10026e:	8b 45 08             	mov    0x8(%ebp),%eax
  100271:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	phd = (proghdr*)(elf + elf_load->e_phoff);
  100274:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100277:	8b 50 1c             	mov    0x1c(%eax),%edx
  10027a:	8b 45 08             	mov    0x8(%ebp),%eax
  10027d:	01 d0                	add    %edx,%eax
  10027f:	89 45 f0             	mov    %eax,-0x10(%ebp)
	
	for(i = 0; i < elf_load->e_phnum; i++){
  100282:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100289:	e9 9f 00 00 00       	jmp    10032d <load_elf+0xc6>
		if(phd->p_type != 1){
  10028e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100291:	8b 00                	mov    (%eax),%eax
  100293:	83 f8 01             	cmp    $0x1,%eax
  100296:	74 09                	je     1002a1 <load_elf+0x3a>
			phd++;
  100298:	83 45 f0 20          	addl   $0x20,-0x10(%ebp)
			continue;
  10029c:	e9 88 00 00 00       	jmp    100329 <load_elf+0xc2>
		}
		p_va_start = phd->p_va & (~0xfff);
  1002a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1002a4:	8b 40 08             	mov    0x8(%eax),%eax
  1002a7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1002ac:	89 45 e0             	mov    %eax,-0x20(%ebp)
		p_va_end = (p_va_start + phd->p_memsz - 1) & ~0xfff;
  1002af:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1002b2:	8b 50 14             	mov    0x14(%eax),%edx
  1002b5:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1002b8:	01 d0                	add    %edx,%eax
  1002ba:	83 e8 01             	sub    $0x1,%eax
  1002bd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1002c2:	89 45 dc             	mov    %eax,-0x24(%ebp)
		for(va = p_va_start; va <= p_va_end; va+=PAGESIZE){
  1002c5:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1002c8:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1002cb:	eb 50                	jmp    10031d <load_elf+0xb6>
			if(pmap_insert(p->pdir, mem_alloc(), va, PTE_P | PTE_W | PTE_U) == NULL){
  1002cd:	e8 f9 0c 00 00       	call   100fcb <mem_alloc>
  1002d2:	8b 55 0c             	mov    0xc(%ebp),%edx
  1002d5:	8b 92 00 07 00 00    	mov    0x700(%edx),%edx
  1002db:	c7 44 24 0c 07 00 00 	movl   $0x7,0xc(%esp)
  1002e2:	00 
  1002e3:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  1002e6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  1002ea:	89 44 24 04          	mov    %eax,0x4(%esp)
  1002ee:	89 14 24             	mov    %edx,(%esp)
  1002f1:	e8 1a 4c 00 00       	call   104f10 <pmap_insert>
  1002f6:	85 c0                	test   %eax,%eax
  1002f8:	75 1c                	jne    100316 <load_elf+0xaf>
				panic("no mem in load_elf.\n");
  1002fa:	c7 44 24 08 ec a1 10 	movl   $0x10a1ec,0x8(%esp)
  100301:	00 
  100302:	c7 44 24 04 b0 00 00 	movl   $0xb0,0x4(%esp)
  100309:	00 
  10030a:	c7 04 24 a7 a1 10 00 	movl   $0x10a1a7,(%esp)
  100311:	e8 22 06 00 00       	call   100938 <debug_panic>
			phd++;
			continue;
		}
		p_va_start = phd->p_va & (~0xfff);
		p_va_end = (p_va_start + phd->p_memsz - 1) & ~0xfff;
		for(va = p_va_start; va <= p_va_end; va+=PAGESIZE){
  100316:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
  10031d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100320:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  100323:	76 a8                	jbe    1002cd <load_elf+0x66>
			if(pmap_insert(p->pdir, mem_alloc(), va, PTE_P | PTE_W | PTE_U) == NULL){
				panic("no mem in load_elf.\n");
			};
		}
		phd++;
  100325:	83 45 f0 20          	addl   $0x20,-0x10(%ebp)
	int i, j;
	pte_t* pte;
	elfhdr* elf_load = (elfhdr*)elf;
	phd = (proghdr*)(elf + elf_load->e_phoff);
	
	for(i = 0; i < elf_load->e_phnum; i++){
  100329:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  10032d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100330:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  100334:	0f b7 c0             	movzwl %ax,%eax
  100337:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  10033a:	0f 8f 4e ff ff ff    	jg     10028e <load_elf+0x27>
			};
		}
		phd++;
	}
	
	phd = (proghdr*)(elf + elf_load->e_phoff);
  100340:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100343:	8b 50 1c             	mov    0x1c(%eax),%edx
  100346:	8b 45 08             	mov    0x8(%ebp),%eax
  100349:	01 d0                	add    %edx,%eax
  10034b:	89 45 f0             	mov    %eax,-0x10(%ebp)
	for(i = 0; i < elf_load->e_phnum; i++){
  10034e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100355:	e9 8c 00 00 00       	jmp    1003e6 <load_elf+0x17f>
		if(phd->p_type != 1){
  10035a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10035d:	8b 00                	mov    (%eax),%eax
  10035f:	83 f8 01             	cmp    $0x1,%eax
  100362:	74 06                	je     10036a <load_elf+0x103>
			phd++;
  100364:	83 45 f0 20          	addl   $0x20,-0x10(%ebp)
			continue;
  100368:	eb 78                	jmp    1003e2 <load_elf+0x17b>
		}

		char* load_va_start = (char*)phd->p_va;
  10036a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10036d:	8b 40 08             	mov    0x8(%eax),%eax
  100370:	89 45 d8             	mov    %eax,-0x28(%ebp)
		//char* load_start = (char*)phd + phd->p_offset;
		char* load_start = elf + phd->p_offset;
  100373:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100376:	8b 50 04             	mov    0x4(%eax),%edx
  100379:	8b 45 08             	mov    0x8(%ebp),%eax
  10037c:	01 d0                	add    %edx,%eax
  10037e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		for(j = 0; j < phd->p_filesz; j++){
  100381:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  100388:	eb 19                	jmp    1003a3 <load_elf+0x13c>
			*(load_va_start + j) = *(load_start + j);
  10038a:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10038d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  100390:	01 c2                	add    %eax,%edx
  100392:	8b 4d e8             	mov    -0x18(%ebp),%ecx
  100395:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  100398:	01 c8                	add    %ecx,%eax
  10039a:	0f b6 00             	movzbl (%eax),%eax
  10039d:	88 02                	mov    %al,(%edx)
		}

		char* load_va_start = (char*)phd->p_va;
		//char* load_start = (char*)phd + phd->p_offset;
		char* load_start = elf + phd->p_offset;
		for(j = 0; j < phd->p_filesz; j++){
  10039f:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
  1003a3:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1003a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1003a9:	8b 40 10             	mov    0x10(%eax),%eax
  1003ac:	39 c2                	cmp    %eax,%edx
  1003ae:	72 da                	jb     10038a <load_elf+0x123>
			*(load_va_start + j) = *(load_start + j);
		}
		// memmove((char*)p_va_start, (char*)((uint32_t)phd + phd->p_offset), (size_t)phd->p_filesz);
		if(phd->p_memsz > phd->p_filesz){
  1003b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1003b3:	8b 50 14             	mov    0x14(%eax),%edx
  1003b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1003b9:	8b 40 10             	mov    0x10(%eax),%eax
  1003bc:	39 c2                	cmp    %eax,%edx
  1003be:	76 1e                	jbe    1003de <load_elf+0x177>
			//memset((char*)((uint32_t)phd + phd->p_offset + phd->p_filesz), 0, (size_t)(phd->p_memsz - phd->p_filesz));
			for(j; j < phd->p_memsz; j++)
  1003c0:	eb 0f                	jmp    1003d1 <load_elf+0x16a>
				*(load_va_start + j) = 0;
  1003c2:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1003c5:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1003c8:	01 d0                	add    %edx,%eax
  1003ca:	c6 00 00             	movb   $0x0,(%eax)
			*(load_va_start + j) = *(load_start + j);
		}
		// memmove((char*)p_va_start, (char*)((uint32_t)phd + phd->p_offset), (size_t)phd->p_filesz);
		if(phd->p_memsz > phd->p_filesz){
			//memset((char*)((uint32_t)phd + phd->p_offset + phd->p_filesz), 0, (size_t)(phd->p_memsz - phd->p_filesz));
			for(j; j < phd->p_memsz; j++)
  1003cd:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
  1003d1:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1003d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1003d7:	8b 40 14             	mov    0x14(%eax),%eax
  1003da:	39 c2                	cmp    %eax,%edx
  1003dc:	72 e4                	jb     1003c2 <load_elf+0x15b>
				*(load_va_start + j) = 0;
		}
		phd++;
  1003de:	83 45 f0 20          	addl   $0x20,-0x10(%ebp)
		}
		phd++;
	}
	
	phd = (proghdr*)(elf + elf_load->e_phoff);
	for(i = 0; i < elf_load->e_phnum; i++){
  1003e2:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  1003e6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1003e9:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  1003ed:	0f b7 c0             	movzwl %ax,%eax
  1003f0:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  1003f3:	0f 8f 61 ff ff ff    	jg     10035a <load_elf+0xf3>
				*(load_va_start + j) = 0;
		}
		phd++;
	}
	
	phd = (proghdr*)(elf + elf_load->e_phoff);
  1003f9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1003fc:	8b 50 1c             	mov    0x1c(%eax),%edx
  1003ff:	8b 45 08             	mov    0x8(%ebp),%eax
  100402:	01 d0                	add    %edx,%eax
  100404:	89 45 f0             	mov    %eax,-0x10(%ebp)
	for(i = 0; i < elf_load->e_phnum; i++){
  100407:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  10040e:	e9 97 00 00 00       	jmp    1004aa <load_elf+0x243>
		if(phd->p_type != 1){
  100413:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100416:	8b 00                	mov    (%eax),%eax
  100418:	83 f8 01             	cmp    $0x1,%eax
  10041b:	74 09                	je     100426 <load_elf+0x1bf>
			phd++;
  10041d:	83 45 f0 20          	addl   $0x20,-0x10(%ebp)
			continue;
  100421:	e9 80 00 00 00       	jmp    1004a6 <load_elf+0x23f>
		}
		if(phd->p_flags & ELF_PROG_FLAG_WRITE){
  100426:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100429:	8b 40 18             	mov    0x18(%eax),%eax
  10042c:	83 e0 02             	and    $0x2,%eax
  10042f:	85 c0                	test   %eax,%eax
  100431:	74 06                	je     100439 <load_elf+0x1d2>
			phd++;
  100433:	83 45 f0 20          	addl   $0x20,-0x10(%ebp)
			continue;
  100437:	eb 6d                	jmp    1004a6 <load_elf+0x23f>
		}
		p_va_start = phd->p_va & (~0xfff);
  100439:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10043c:	8b 40 08             	mov    0x8(%eax),%eax
  10043f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100444:	89 45 e0             	mov    %eax,-0x20(%ebp)
		p_va_end = (p_va_start + phd->p_memsz - 1) & ~0xfff;
  100447:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10044a:	8b 50 14             	mov    0x14(%eax),%edx
  10044d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100450:	01 d0                	add    %edx,%eax
  100452:	83 e8 01             	sub    $0x1,%eax
  100455:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10045a:	89 45 dc             	mov    %eax,-0x24(%ebp)
		for(va = p_va_start; va <= p_va_end; va+=PAGESIZE){
  10045d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100460:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100463:	eb 39                	jmp    10049e <load_elf+0x237>
			pte = pmap_walk(p->pdir,va,1);
  100465:	8b 45 0c             	mov    0xc(%ebp),%eax
  100468:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  10046e:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  100475:	00 
  100476:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100479:	89 54 24 04          	mov    %edx,0x4(%esp)
  10047d:	89 04 24             	mov    %eax,(%esp)
  100480:	e8 4a 48 00 00       	call   104ccf <pmap_walk>
  100485:	89 45 d0             	mov    %eax,-0x30(%ebp)
			*pte = *pte & (~PTE_W);
  100488:	8b 45 d0             	mov    -0x30(%ebp),%eax
  10048b:	8b 00                	mov    (%eax),%eax
  10048d:	89 c2                	mov    %eax,%edx
  10048f:	83 e2 fd             	and    $0xfffffffd,%edx
  100492:	8b 45 d0             	mov    -0x30(%ebp),%eax
  100495:	89 10                	mov    %edx,(%eax)
			phd++;
			continue;
		}
		p_va_start = phd->p_va & (~0xfff);
		p_va_end = (p_va_start + phd->p_memsz - 1) & ~0xfff;
		for(va = p_va_start; va <= p_va_end; va+=PAGESIZE){
  100497:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
  10049e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1004a1:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  1004a4:	76 bf                	jbe    100465 <load_elf+0x1fe>
		}
		phd++;
	}
	
	phd = (proghdr*)(elf + elf_load->e_phoff);
	for(i = 0; i < elf_load->e_phnum; i++){
  1004a6:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  1004aa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1004ad:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  1004b1:	0f b7 c0             	movzwl %ax,%eax
  1004b4:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  1004b7:	0f 8f 56 ff ff ff    	jg     100413 <load_elf+0x1ac>
			pte = pmap_walk(p->pdir,va,1);
			*pte = *pte & (~PTE_W);
		}
	}
	
	if(pmap_insert(p->pdir, mem_alloc(), rootexe_stack_addr,SYS_RW| PTE_U | PTE_P | PTE_W) == NULL)
  1004bd:	8b 1d 00 e0 10 00    	mov    0x10e000,%ebx
  1004c3:	e8 03 0b 00 00       	call   100fcb <mem_alloc>
  1004c8:	8b 55 0c             	mov    0xc(%ebp),%edx
  1004cb:	8b 92 00 07 00 00    	mov    0x700(%edx),%edx
  1004d1:	c7 44 24 0c 07 06 00 	movl   $0x607,0xc(%esp)
  1004d8:	00 
  1004d9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  1004dd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004e1:	89 14 24             	mov    %edx,(%esp)
  1004e4:	e8 27 4a 00 00       	call   104f10 <pmap_insert>
  1004e9:	85 c0                	test   %eax,%eax
  1004eb:	75 1c                	jne    100509 <load_elf+0x2a2>
		panic("Has no mem in load_elf assign stack.\n");
  1004ed:	c7 44 24 08 04 a2 10 	movl   $0x10a204,0x8(%esp)
  1004f4:	00 
  1004f5:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
  1004fc:	00 
  1004fd:	c7 04 24 a7 a1 10 00 	movl   $0x10a1a7,(%esp)
  100504:	e8 2f 04 00 00       	call   100938 <debug_panic>
}
  100509:	83 c4 44             	add    $0x44,%esp
  10050c:	5b                   	pop    %ebx
  10050d:	5d                   	pop    %ebp
  10050e:	c3                   	ret    
  10050f:	90                   	nop

00100510 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100510:	55                   	push   %ebp
  100511:	89 e5                	mov    %esp,%ebp
  100513:	53                   	push   %ebx
  100514:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100517:	89 e3                	mov    %esp,%ebx
  100519:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  10051c:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10051f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100522:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100525:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10052a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  10052d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100530:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  100536:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10053b:	74 24                	je     100561 <cpu_cur+0x51>
  10053d:	c7 44 24 0c 2a a2 10 	movl   $0x10a22a,0xc(%esp)
  100544:	00 
  100545:	c7 44 24 08 40 a2 10 	movl   $0x10a240,0x8(%esp)
  10054c:	00 
  10054d:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100554:	00 
  100555:	c7 04 24 55 a2 10 00 	movl   $0x10a255,(%esp)
  10055c:	e8 d7 03 00 00       	call   100938 <debug_panic>
	return c;
  100561:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  100564:	83 c4 24             	add    $0x24,%esp
  100567:	5b                   	pop    %ebx
  100568:	5d                   	pop    %ebp
  100569:	c3                   	ret    

0010056a <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10056a:	55                   	push   %ebp
  10056b:	89 e5                	mov    %esp,%ebp
  10056d:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100570:	e8 9b ff ff ff       	call   100510 <cpu_cur>
  100575:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  10057a:	0f 94 c0             	sete   %al
  10057d:	0f b6 c0             	movzbl %al,%eax
}
  100580:	c9                   	leave  
  100581:	c3                   	ret    

00100582 <cons_intr>:
static int fi_read_pos = (uint32_t)FILEDATA(FILEINO_CONSIN);
// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
  100582:	55                   	push   %ebp
  100583:	89 e5                	mov    %esp,%ebp
  100585:	83 ec 28             	sub    $0x28,%esp
	int c;
	spinlock_acquire(&cons_lock);
  100588:	c7 04 24 00 8f 18 00 	movl   $0x188f00,(%esp)
  10058f:	e8 5d 24 00 00       	call   1029f1 <spinlock_acquire>
	while ((c = (*proc)()) != -1) {
  100594:	eb 35                	jmp    1005cb <cons_intr+0x49>
		if (c == 0)
  100596:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10059a:	74 2e                	je     1005ca <cons_intr+0x48>
			continue;
		s_consin.buf[s_consin.wpos++] = c;
  10059c:	a1 04 42 18 00       	mov    0x184204,%eax
  1005a1:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1005a4:	88 90 00 40 18 00    	mov    %dl,0x184000(%eax)
  1005aa:	83 c0 01             	add    $0x1,%eax
  1005ad:	a3 04 42 18 00       	mov    %eax,0x184204
		if (s_consin.wpos == CONSBUFSIZE)
  1005b2:	a1 04 42 18 00       	mov    0x184204,%eax
  1005b7:	3d 00 02 00 00       	cmp    $0x200,%eax
  1005bc:	75 0d                	jne    1005cb <cons_intr+0x49>
			s_consin.wpos = 0;
  1005be:	c7 05 04 42 18 00 00 	movl   $0x0,0x184204
  1005c5:	00 00 00 
  1005c8:	eb 01                	jmp    1005cb <cons_intr+0x49>
{
	int c;
	spinlock_acquire(&cons_lock);
	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
  1005ca:	90                   	nop
void
cons_intr(int (*proc)(void))
{
	int c;
	spinlock_acquire(&cons_lock);
	while ((c = (*proc)()) != -1) {
  1005cb:	8b 45 08             	mov    0x8(%ebp),%eax
  1005ce:	ff d0                	call   *%eax
  1005d0:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1005d3:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
  1005d7:	75 bd                	jne    100596 <cons_intr+0x14>
			continue;
		s_consin.buf[s_consin.wpos++] = c;
		if (s_consin.wpos == CONSBUFSIZE)
			s_consin.wpos = 0;
	}
	spinlock_release(&cons_lock);
  1005d9:	c7 04 24 00 8f 18 00 	movl   $0x188f00,(%esp)
  1005e0:	e8 81 24 00 00       	call   102a66 <spinlock_release>

	// Wake the root process
	file_wakeroot();
  1005e5:	e8 58 7c 00 00       	call   108242 <file_wakeroot>
}
  1005ea:	c9                   	leave  
  1005eb:	c3                   	ret    

001005ec <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  1005ec:	55                   	push   %ebp
  1005ed:	89 e5                	mov    %esp,%ebp
  1005ef:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  1005f2:	e8 13 82 00 00       	call   10880a <serial_intr>
	kbd_intr();
  1005f7:	e8 16 81 00 00       	call   108712 <kbd_intr>

	// grab the next character from the input buffer.
	if (s_consin.rpos != s_consin.wpos) {
  1005fc:	8b 15 00 42 18 00    	mov    0x184200,%edx
  100602:	a1 04 42 18 00       	mov    0x184204,%eax
  100607:	39 c2                	cmp    %eax,%edx
  100609:	74 35                	je     100640 <cons_getc+0x54>
		c = s_consin.buf[s_consin.rpos++];
  10060b:	a1 00 42 18 00       	mov    0x184200,%eax
  100610:	0f b6 90 00 40 18 00 	movzbl 0x184000(%eax),%edx
  100617:	0f b6 d2             	movzbl %dl,%edx
  10061a:	89 55 f4             	mov    %edx,-0xc(%ebp)
  10061d:	83 c0 01             	add    $0x1,%eax
  100620:	a3 00 42 18 00       	mov    %eax,0x184200
		if (s_consin.rpos == CONSBUFSIZE)
  100625:	a1 00 42 18 00       	mov    0x184200,%eax
  10062a:	3d 00 02 00 00       	cmp    $0x200,%eax
  10062f:	75 0a                	jne    10063b <cons_getc+0x4f>
			s_consin.rpos = 0;
  100631:	c7 05 00 42 18 00 00 	movl   $0x0,0x184200
  100638:	00 00 00 
		return c;
  10063b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10063e:	eb 05                	jmp    100645 <cons_getc+0x59>
	}
	return 0;
  100640:	b8 00 00 00 00       	mov    $0x0,%eax
}
  100645:	c9                   	leave  
  100646:	c3                   	ret    

00100647 <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  100647:	55                   	push   %ebp
  100648:	89 e5                	mov    %esp,%ebp
  10064a:	83 ec 18             	sub    $0x18,%esp
	serial_putc(c);
  10064d:	8b 45 08             	mov    0x8(%ebp),%eax
  100650:	89 04 24             	mov    %eax,(%esp)
  100653:	e8 cf 81 00 00       	call   108827 <serial_putc>
	video_putc(c);
  100658:	8b 45 08             	mov    0x8(%ebp),%eax
  10065b:	89 04 24             	mov    %eax,(%esp)
  10065e:	e8 02 7d 00 00       	call   108365 <video_putc>
}
  100663:	c9                   	leave  
  100664:	c3                   	ret    

00100665 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  100665:	55                   	push   %ebp
  100666:	89 e5                	mov    %esp,%ebp
  100668:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  10066b:	e8 fa fe ff ff       	call   10056a <cpu_onboot>
  100670:	85 c0                	test   %eax,%eax
  100672:	74 52                	je     1006c6 <cons_init+0x61>
		return;

	spinlock_init(&cons_lock);
  100674:	c7 44 24 08 72 00 00 	movl   $0x72,0x8(%esp)
  10067b:	00 
  10067c:	c7 44 24 04 62 a2 10 	movl   $0x10a262,0x4(%esp)
  100683:	00 
  100684:	c7 04 24 00 8f 18 00 	movl   $0x188f00,(%esp)
  10068b:	e8 37 23 00 00       	call   1029c7 <spinlock_init_>
	video_init();
  100690:	e8 f3 7b 00 00       	call   108288 <video_init>
	kbd_init();
  100695:	e8 8c 80 00 00       	call   108726 <kbd_init>
	serial_init();
  10069a:	e8 f8 81 00 00       	call   108897 <serial_init>

	if (!serial_exists)
  10069f:	a1 00 c0 38 00       	mov    0x38c000,%eax
  1006a4:	85 c0                	test   %eax,%eax
  1006a6:	75 1f                	jne    1006c7 <cons_init+0x62>
		warn("Serial port does not exist!\n");
  1006a8:	c7 44 24 08 6e a2 10 	movl   $0x10a26e,0x8(%esp)
  1006af:	00 
  1006b0:	c7 44 24 04 78 00 00 	movl   $0x78,0x4(%esp)
  1006b7:	00 
  1006b8:	c7 04 24 62 a2 10 00 	movl   $0x10a262,(%esp)
  1006bf:	e8 3a 03 00 00       	call   1009fe <debug_warn>
  1006c4:	eb 01                	jmp    1006c7 <cons_init+0x62>
// initialize the console devices
void
cons_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  1006c6:	90                   	nop
	kbd_init();
	serial_init();

	if (!serial_exists)
		warn("Serial port does not exist!\n");
}
  1006c7:	c9                   	leave  
  1006c8:	c3                   	ret    

001006c9 <cons_intenable>:

// Enable console interrupts.
void
cons_intenable(void)
{
  1006c9:	55                   	push   %ebp
  1006ca:	89 e5                	mov    %esp,%ebp
  1006cc:	83 ec 08             	sub    $0x8,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  1006cf:	e8 96 fe ff ff       	call   10056a <cpu_onboot>
  1006d4:	85 c0                	test   %eax,%eax
  1006d6:	74 0c                	je     1006e4 <cons_intenable+0x1b>
		return;

	kbd_intenable();
  1006d8:	e8 4e 80 00 00       	call   10872b <kbd_intenable>
	serial_intenable();
  1006dd:	e8 9a 82 00 00       	call   10897c <serial_intenable>
  1006e2:	eb 01                	jmp    1006e5 <cons_intenable+0x1c>
// Enable console interrupts.
void
cons_intenable(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  1006e4:	90                   	nop

	kbd_intenable();
	serial_intenable();
}
  1006e5:	c9                   	leave  
  1006e6:	c3                   	ret    

001006e7 <cputs>:

// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
  1006e7:	55                   	push   %ebp
  1006e8:	89 e5                	mov    %esp,%ebp
  1006ea:	53                   	push   %ebx
  1006eb:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1006ee:	66 8c cb             	mov    %cs,%bx
  1006f1:	66 89 5d f2          	mov    %bx,-0xe(%ebp)
        return cs;
  1006f5:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	if (read_cs() & 3)
  1006f9:	0f b7 c0             	movzwl %ax,%eax
  1006fc:	83 e0 03             	and    $0x3,%eax
  1006ff:	85 c0                	test   %eax,%eax
  100701:	74 14                	je     100717 <cputs+0x30>
  100703:	8b 45 08             	mov    0x8(%ebp),%eax
  100706:	89 45 ec             	mov    %eax,-0x14(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
  100709:	b8 00 00 00 00       	mov    $0x0,%eax
  10070e:	8b 55 ec             	mov    -0x14(%ebp),%edx
  100711:	89 d3                	mov    %edx,%ebx
  100713:	cd 30                	int    $0x30
		return sys_cputs(str);	// use syscall from user mode
  100715:	eb 57                	jmp    10076e <cputs+0x87>

	// Hold the console spinlock while printing the entire string,
	// so that the output of different cputs calls won't get mixed.
	// Implement ad hoc recursive locking for debugging convenience.
	bool already = spinlock_holding(&cons_lock);
  100717:	c7 04 24 00 8f 18 00 	movl   $0x188f00,(%esp)
  10071e:	e8 9d 23 00 00       	call   102ac0 <spinlock_holding>
  100723:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (!already)
  100726:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10072a:	75 25                	jne    100751 <cputs+0x6a>
		spinlock_acquire(&cons_lock);
  10072c:	c7 04 24 00 8f 18 00 	movl   $0x188f00,(%esp)
  100733:	e8 b9 22 00 00       	call   1029f1 <spinlock_acquire>

	char ch;
	while (*str)
  100738:	eb 17                	jmp    100751 <cputs+0x6a>
		cons_putc(*str++);
  10073a:	8b 45 08             	mov    0x8(%ebp),%eax
  10073d:	0f b6 00             	movzbl (%eax),%eax
  100740:	0f be c0             	movsbl %al,%eax
  100743:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  100747:	89 04 24             	mov    %eax,(%esp)
  10074a:	e8 f8 fe ff ff       	call   100647 <cons_putc>
  10074f:	eb 01                	jmp    100752 <cputs+0x6b>
	bool already = spinlock_holding(&cons_lock);
	if (!already)
		spinlock_acquire(&cons_lock);

	char ch;
	while (*str)
  100751:	90                   	nop
  100752:	8b 45 08             	mov    0x8(%ebp),%eax
  100755:	0f b6 00             	movzbl (%eax),%eax
  100758:	84 c0                	test   %al,%al
  10075a:	75 de                	jne    10073a <cputs+0x53>
		cons_putc(*str++);

	if (!already)
  10075c:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100760:	75 0c                	jne    10076e <cputs+0x87>
		spinlock_release(&cons_lock);
  100762:	c7 04 24 00 8f 18 00 	movl   $0x188f00,(%esp)
  100769:	e8 f8 22 00 00       	call   102a66 <spinlock_release>
}
  10076e:	83 c4 24             	add    $0x24,%esp
  100771:	5b                   	pop    %ebx
  100772:	5d                   	pop    %ebp
  100773:	c3                   	ret    

00100774 <cons_io>:

// Synchronize the root process's console special files
// with the actual console I/O device.
bool
cons_io(void)
{
  100774:	55                   	push   %ebp
  100775:	89 e5                	mov    %esp,%ebp
  100777:	83 ec 38             	sub    $0x38,%esp
	// Lab 4: your console I/O code here.
	//warn("cons_io() not implemented");
	fileinode* stdout = &files->fi[FILEINO_CONSOUT];
  10077a:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  10077f:	05 c8 10 00 00       	add    $0x10c8,%eax
  100784:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	fileinode* stdin = &files->fi[FILEINO_CONSIN];
  100787:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  10078c:	05 6c 10 00 00       	add    $0x106c,%eax
  100791:	89 45 e0             	mov    %eax,-0x20(%ebp)
	int status = 0;
  100794:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	int ind = 0;
  10079b:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	spinlock_acquire(&cons_lock);
  1007a2:	c7 04 24 00 8f 18 00 	movl   $0x188f00,(%esp)
  1007a9:	e8 43 22 00 00       	call   1029f1 <spinlock_acquire>
	if(s_consout.wpos < stdout->size){
  1007ae:	8b 15 24 44 18 00    	mov    0x184424,%edx
  1007b4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1007b7:	8b 40 4c             	mov    0x4c(%eax),%eax
  1007ba:	39 c2                	cmp    %eax,%edx
  1007bc:	0f 83 f5 00 00 00    	jae    1008b7 <cons_io+0x143>
		while(s_consout.wpos < stdout->size){
  1007c2:	e9 81 00 00 00       	jmp    100848 <cons_io+0xd4>
			if(ind >= CONSBUFSIZE){
  1007c7:	81 7d f0 ff 01 00 00 	cmpl   $0x1ff,-0x10(%ebp)
  1007ce:	7e 4f                	jle    10081f <cons_io+0xab>
				int n = 0;
  1007d0:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
				//cputs((char*)s_consout.buf);
				for(n; n < CONSBUFSIZE; n++){
  1007d7:	eb 1a                	jmp    1007f3 <cons_io+0x7f>
					cons_putc(s_consout.buf[n]);
  1007d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1007dc:	05 20 42 18 00       	add    $0x184220,%eax
  1007e1:	0f b6 00             	movzbl (%eax),%eax
  1007e4:	0f b6 c0             	movzbl %al,%eax
  1007e7:	89 04 24             	mov    %eax,(%esp)
  1007ea:	e8 58 fe ff ff       	call   100647 <cons_putc>
	if(s_consout.wpos < stdout->size){
		while(s_consout.wpos < stdout->size){
			if(ind >= CONSBUFSIZE){
				int n = 0;
				//cputs((char*)s_consout.buf);
				for(n; n < CONSBUFSIZE; n++){
  1007ef:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  1007f3:	81 7d ec ff 01 00 00 	cmpl   $0x1ff,-0x14(%ebp)
  1007fa:	7e dd                	jle    1007d9 <cons_io+0x65>
					cons_putc(s_consout.buf[n]);
				}
				memset(s_consout.buf,0,CONSBUFSIZE);
  1007fc:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
  100803:	00 
  100804:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10080b:	00 
  10080c:	c7 04 24 20 42 18 00 	movl   $0x184220,(%esp)
  100813:	e8 29 94 00 00       	call   109c41 <memset>
				ind = 0;
  100818:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
			}
			s_consout.buf[ind++] = *(uint8_t*)((uint32_t)FILEDATA(FILEINO_CONSOUT) + s_consout.wpos);
  10081f:	a1 24 44 18 00       	mov    0x184424,%eax
  100824:	2d 00 00 80 7f       	sub    $0x7f800000,%eax
  100829:	0f b6 00             	movzbl (%eax),%eax
  10082c:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10082f:	81 c2 20 42 18 00    	add    $0x184220,%edx
  100835:	88 02                	mov    %al,(%edx)
  100837:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
			s_consout.wpos++;
  10083b:	a1 24 44 18 00       	mov    0x184424,%eax
  100840:	83 c0 01             	add    $0x1,%eax
  100843:	a3 24 44 18 00       	mov    %eax,0x184424
	fileinode* stdin = &files->fi[FILEINO_CONSIN];
	int status = 0;
	int ind = 0;
	spinlock_acquire(&cons_lock);
	if(s_consout.wpos < stdout->size){
		while(s_consout.wpos < stdout->size){
  100848:	8b 15 24 44 18 00    	mov    0x184424,%edx
  10084e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100851:	8b 40 4c             	mov    0x4c(%eax),%eax
  100854:	39 c2                	cmp    %eax,%edx
  100856:	0f 82 6b ff ff ff    	jb     1007c7 <cons_io+0x53>
				ind = 0;
			}
			s_consout.buf[ind++] = *(uint8_t*)((uint32_t)FILEDATA(FILEINO_CONSOUT) + s_consout.wpos);
			s_consout.wpos++;
		}
		if(ind > 0){
  10085c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  100860:	7e 4e                	jle    1008b0 <cons_io+0x13c>
			int n = 0;
  100862:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
			//cputs((char*)s_consout.buf);
			for(n; n < ind; n++){
  100869:	eb 1a                	jmp    100885 <cons_io+0x111>
					cons_putc(s_consout.buf[n]);
  10086b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10086e:	05 20 42 18 00       	add    $0x184220,%eax
  100873:	0f b6 00             	movzbl (%eax),%eax
  100876:	0f b6 c0             	movzbl %al,%eax
  100879:	89 04 24             	mov    %eax,(%esp)
  10087c:	e8 c6 fd ff ff       	call   100647 <cons_putc>
			s_consout.wpos++;
		}
		if(ind > 0){
			int n = 0;
			//cputs((char*)s_consout.buf);
			for(n; n < ind; n++){
  100881:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
  100885:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100888:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10088b:	7c de                	jl     10086b <cons_io+0xf7>
					cons_putc(s_consout.buf[n]);
				}
			memset(s_consout.buf,0,CONSBUFSIZE);
  10088d:	c7 44 24 08 00 02 00 	movl   $0x200,0x8(%esp)
  100894:	00 
  100895:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10089c:	00 
  10089d:	c7 04 24 20 42 18 00 	movl   $0x184220,(%esp)
  1008a4:	e8 98 93 00 00       	call   109c41 <memset>
			ind = 0;
  1008a9:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
		}
		status = 1;
  1008b0:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
	}
	if(s_consin.rpos != s_consin.wpos){
  1008b7:	8b 15 00 42 18 00    	mov    0x184200,%edx
  1008bd:	a1 04 42 18 00       	mov    0x184204,%eax
  1008c2:	39 c2                	cmp    %eax,%edx
  1008c4:	74 60                	je     100926 <cons_io+0x1b2>
		while(s_consin.rpos != s_consin.wpos){
  1008c6:	eb 48                	jmp    100910 <cons_io+0x19c>
			memcpy((void*)fi_read_pos, &s_consin.buf[s_consin.rpos++], 1);
  1008c8:	a1 00 42 18 00       	mov    0x184200,%eax
  1008cd:	8d 90 00 40 18 00    	lea    0x184000(%eax),%edx
  1008d3:	83 c0 01             	add    $0x1,%eax
  1008d6:	a3 00 42 18 00       	mov    %eax,0x184200
  1008db:	a1 04 e0 10 00       	mov    0x10e004,%eax
  1008e0:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  1008e7:	00 
  1008e8:	89 54 24 04          	mov    %edx,0x4(%esp)
  1008ec:	89 04 24             	mov    %eax,(%esp)
  1008ef:	e8 95 94 00 00       	call   109d89 <memcpy>
			fi_read_pos++;
  1008f4:	a1 04 e0 10 00       	mov    0x10e004,%eax
  1008f9:	83 c0 01             	add    $0x1,%eax
  1008fc:	a3 04 e0 10 00       	mov    %eax,0x10e004
			stdin->size++;
  100901:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100904:	8b 40 4c             	mov    0x4c(%eax),%eax
  100907:	8d 50 01             	lea    0x1(%eax),%edx
  10090a:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10090d:	89 50 4c             	mov    %edx,0x4c(%eax)
			ind = 0;
		}
		status = 1;
	}
	if(s_consin.rpos != s_consin.wpos){
		while(s_consin.rpos != s_consin.wpos){
  100910:	8b 15 00 42 18 00    	mov    0x184200,%edx
  100916:	a1 04 42 18 00       	mov    0x184204,%eax
  10091b:	39 c2                	cmp    %eax,%edx
  10091d:	75 a9                	jne    1008c8 <cons_io+0x154>
			memcpy((void*)fi_read_pos, &s_consin.buf[s_consin.rpos++], 1);
			fi_read_pos++;
			stdin->size++;
		}
		status = 1;
  10091f:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
	}
	spinlock_release(&cons_lock);
  100926:	c7 04 24 00 8f 18 00 	movl   $0x188f00,(%esp)
  10092d:	e8 34 21 00 00       	call   102a66 <spinlock_release>
	return status;	// 0 indicates no I/O done
  100932:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  100935:	c9                   	leave  
  100936:	c3                   	ret    
  100937:	90                   	nop

00100938 <debug_panic>:

// Panic is called on unresolvable fatal errors.
// It prints "panic: mesg", and then enters the kernel monitor.
void
debug_panic(const char *file, int line, const char *fmt,...)
{
  100938:	55                   	push   %ebp
  100939:	89 e5                	mov    %esp,%ebp
  10093b:	53                   	push   %ebx
  10093c:	83 ec 54             	sub    $0x54,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10093f:	66 8c cb             	mov    %cs,%bx
  100942:	66 89 5d ee          	mov    %bx,-0x12(%ebp)
        return cs;
  100946:	0f b7 45 ee          	movzwl -0x12(%ebp),%eax
	va_list ap;
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
  10094a:	0f b7 c0             	movzwl %ax,%eax
  10094d:	83 e0 03             	and    $0x3,%eax
  100950:	85 c0                	test   %eax,%eax
  100952:	75 15                	jne    100969 <debug_panic+0x31>
		if (panicstr)
  100954:	a1 28 44 18 00       	mov    0x184428,%eax
  100959:	85 c0                	test   %eax,%eax
  10095b:	0f 85 97 00 00 00    	jne    1009f8 <debug_panic+0xc0>
			goto dead;
		panicstr = fmt;
  100961:	8b 45 10             	mov    0x10(%ebp),%eax
  100964:	a3 28 44 18 00       	mov    %eax,0x184428
	}

	// First print the requested message
	va_start(ap, fmt);
  100969:	8d 45 10             	lea    0x10(%ebp),%eax
  10096c:	83 c0 04             	add    $0x4,%eax
  10096f:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
  100972:	8b 45 0c             	mov    0xc(%ebp),%eax
  100975:	89 44 24 08          	mov    %eax,0x8(%esp)
  100979:	8b 45 08             	mov    0x8(%ebp),%eax
  10097c:	89 44 24 04          	mov    %eax,0x4(%esp)
  100980:	c7 04 24 8b a2 10 00 	movl   $0x10a28b,(%esp)
  100987:	e8 44 8f 00 00       	call   1098d0 <cprintf>
	vcprintf(fmt, ap);
  10098c:	8b 45 10             	mov    0x10(%ebp),%eax
  10098f:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100992:	89 54 24 04          	mov    %edx,0x4(%esp)
  100996:	89 04 24             	mov    %eax,(%esp)
  100999:	e8 ca 8e 00 00       	call   109868 <vcprintf>
	cprintf("\n");
  10099e:	c7 04 24 a3 a2 10 00 	movl   $0x10a2a3,(%esp)
  1009a5:	e8 26 8f 00 00       	call   1098d0 <cprintf>

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  1009aa:	89 eb                	mov    %ebp,%ebx
  1009ac:	89 5d e8             	mov    %ebx,-0x18(%ebp)
        return ebp;
  1009af:	8b 45 e8             	mov    -0x18(%ebp),%eax
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
  1009b2:	8d 55 c0             	lea    -0x40(%ebp),%edx
  1009b5:	89 54 24 04          	mov    %edx,0x4(%esp)
  1009b9:	89 04 24             	mov    %eax,(%esp)
  1009bc:	e8 86 00 00 00       	call   100a47 <debug_trace>
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  1009c1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1009c8:	eb 1b                	jmp    1009e5 <debug_panic+0xad>
		cprintf("  from %08x\n", eips[i]);
  1009ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1009cd:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  1009d1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1009d5:	c7 04 24 a5 a2 10 00 	movl   $0x10a2a5,(%esp)
  1009dc:	e8 ef 8e 00 00       	call   1098d0 <cprintf>
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  1009e1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1009e5:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  1009e9:	7f 0e                	jg     1009f9 <debug_panic+0xc1>
  1009eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1009ee:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  1009f2:	85 c0                	test   %eax,%eax
  1009f4:	75 d4                	jne    1009ca <debug_panic+0x92>
  1009f6:	eb 01                	jmp    1009f9 <debug_panic+0xc1>
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
		if (panicstr)
			goto dead;
  1009f8:	90                   	nop
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
		cprintf("  from %08x\n", eips[i]);

dead:
	done();		// enter infinite loop (see kern/init.c)
  1009f9:	e8 64 f8 ff ff       	call   100262 <done>

001009fe <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
  1009fe:	55                   	push   %ebp
  1009ff:	89 e5                	mov    %esp,%ebp
  100a01:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  100a04:	8d 45 10             	lea    0x10(%ebp),%eax
  100a07:	83 c0 04             	add    $0x4,%eax
  100a0a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
  100a0d:	8b 45 0c             	mov    0xc(%ebp),%eax
  100a10:	89 44 24 08          	mov    %eax,0x8(%esp)
  100a14:	8b 45 08             	mov    0x8(%ebp),%eax
  100a17:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a1b:	c7 04 24 b2 a2 10 00 	movl   $0x10a2b2,(%esp)
  100a22:	e8 a9 8e 00 00       	call   1098d0 <cprintf>
	vcprintf(fmt, ap);
  100a27:	8b 45 10             	mov    0x10(%ebp),%eax
  100a2a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100a2d:	89 54 24 04          	mov    %edx,0x4(%esp)
  100a31:	89 04 24             	mov    %eax,(%esp)
  100a34:	e8 2f 8e 00 00       	call   109868 <vcprintf>
	cprintf("\n");
  100a39:	c7 04 24 a3 a2 10 00 	movl   $0x10a2a3,(%esp)
  100a40:	e8 8b 8e 00 00       	call   1098d0 <cprintf>
	va_end(ap);
}
  100a45:	c9                   	leave  
  100a46:	c3                   	ret    

00100a47 <debug_trace>:

// Record the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  100a47:	55                   	push   %ebp
  100a48:	89 e5                	mov    %esp,%ebp
  100a4a:	83 ec 10             	sub    $0x10,%esp
	int i ,j;
	uint32_t *cur_epb = (uint32_t *)ebp;
  100a4d:	8b 45 08             	mov    0x8(%ebp),%eax
  100a50:	89 45 f4             	mov    %eax,-0xc(%ebp)
	//cprintf("Stack backtrace:\n");
	for(i = 0; i < DEBUG_TRACEFRAMES && cur_epb > 0; i++) {
  100a53:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  100a5a:	eb 36                	jmp    100a92 <debug_trace+0x4b>
		//cprintf("  ebp %08x eip %08x args",cur_epb[0],cur_epb[1]);
		eips[i] = cur_epb[1];
  100a5c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100a5f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  100a66:	8b 45 0c             	mov    0xc(%ebp),%eax
  100a69:	01 c2                	add    %eax,%edx
  100a6b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a6e:	8b 40 04             	mov    0x4(%eax),%eax
  100a71:	89 02                	mov    %eax,(%edx)
		for(j = 0; j < 5; j++) {
  100a73:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  100a7a:	eb 04                	jmp    100a80 <debug_trace+0x39>
  100a7c:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  100a80:	83 7d f8 04          	cmpl   $0x4,-0x8(%ebp)
  100a84:	7e f6                	jle    100a7c <debug_trace+0x35>
			//cprintf(" %08x",cur_epb[2 + j]);
		}
		//cprintf("\n");
		cur_epb = (uint32_t *)(*cur_epb);
  100a86:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100a89:	8b 00                	mov    (%eax),%eax
  100a8b:	89 45 f4             	mov    %eax,-0xc(%ebp)
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
	int i ,j;
	uint32_t *cur_epb = (uint32_t *)ebp;
	//cprintf("Stack backtrace:\n");
	for(i = 0; i < DEBUG_TRACEFRAMES && cur_epb > 0; i++) {
  100a8e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  100a92:	83 7d fc 09          	cmpl   $0x9,-0x4(%ebp)
  100a96:	7f 21                	jg     100ab9 <debug_trace+0x72>
  100a98:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100a9c:	75 be                	jne    100a5c <debug_trace+0x15>
			//cprintf(" %08x",cur_epb[2 + j]);
		}
		//cprintf("\n");
		cur_epb = (uint32_t *)(*cur_epb);
	}
	for(; i < DEBUG_TRACEFRAMES ; i++) {
  100a9e:	eb 19                	jmp    100ab9 <debug_trace+0x72>
		eips[i] = 0;
  100aa0:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100aa3:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  100aaa:	8b 45 0c             	mov    0xc(%ebp),%eax
  100aad:	01 d0                	add    %edx,%eax
  100aaf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			//cprintf(" %08x",cur_epb[2 + j]);
		}
		//cprintf("\n");
		cur_epb = (uint32_t *)(*cur_epb);
	}
	for(; i < DEBUG_TRACEFRAMES ; i++) {
  100ab5:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  100ab9:	83 7d fc 09          	cmpl   $0x9,-0x4(%ebp)
  100abd:	7e e1                	jle    100aa0 <debug_trace+0x59>
		eips[i] = 0;
	}
}
  100abf:	c9                   	leave  
  100ac0:	c3                   	ret    

00100ac1 <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  100ac1:	55                   	push   %ebp
  100ac2:	89 e5                	mov    %esp,%ebp
  100ac4:	53                   	push   %ebx
  100ac5:	83 ec 18             	sub    $0x18,%esp

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  100ac8:	89 eb                	mov    %ebp,%ebx
  100aca:	89 5d f8             	mov    %ebx,-0x8(%ebp)
        return ebp;
  100acd:	8b 45 f8             	mov    -0x8(%ebp),%eax
  100ad0:	8b 55 0c             	mov    0xc(%ebp),%edx
  100ad3:	89 54 24 04          	mov    %edx,0x4(%esp)
  100ad7:	89 04 24             	mov    %eax,(%esp)
  100ada:	e8 68 ff ff ff       	call   100a47 <debug_trace>
  100adf:	83 c4 18             	add    $0x18,%esp
  100ae2:	5b                   	pop    %ebx
  100ae3:	5d                   	pop    %ebp
  100ae4:	c3                   	ret    

00100ae5 <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  100ae5:	55                   	push   %ebp
  100ae6:	89 e5                	mov    %esp,%ebp
  100ae8:	83 ec 08             	sub    $0x8,%esp
  100aeb:	8b 45 08             	mov    0x8(%ebp),%eax
  100aee:	83 e0 02             	and    $0x2,%eax
  100af1:	85 c0                	test   %eax,%eax
  100af3:	74 14                	je     100b09 <f2+0x24>
  100af5:	8b 45 0c             	mov    0xc(%ebp),%eax
  100af8:	89 44 24 04          	mov    %eax,0x4(%esp)
  100afc:	8b 45 08             	mov    0x8(%ebp),%eax
  100aff:	89 04 24             	mov    %eax,(%esp)
  100b02:	e8 ba ff ff ff       	call   100ac1 <f3>
  100b07:	eb 12                	jmp    100b1b <f2+0x36>
  100b09:	8b 45 0c             	mov    0xc(%ebp),%eax
  100b0c:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b10:	8b 45 08             	mov    0x8(%ebp),%eax
  100b13:	89 04 24             	mov    %eax,(%esp)
  100b16:	e8 a6 ff ff ff       	call   100ac1 <f3>
  100b1b:	c9                   	leave  
  100b1c:	c3                   	ret    

00100b1d <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  100b1d:	55                   	push   %ebp
  100b1e:	89 e5                	mov    %esp,%ebp
  100b20:	83 ec 08             	sub    $0x8,%esp
  100b23:	8b 45 08             	mov    0x8(%ebp),%eax
  100b26:	83 e0 01             	and    $0x1,%eax
  100b29:	85 c0                	test   %eax,%eax
  100b2b:	74 14                	je     100b41 <f1+0x24>
  100b2d:	8b 45 0c             	mov    0xc(%ebp),%eax
  100b30:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b34:	8b 45 08             	mov    0x8(%ebp),%eax
  100b37:	89 04 24             	mov    %eax,(%esp)
  100b3a:	e8 a6 ff ff ff       	call   100ae5 <f2>
  100b3f:	eb 12                	jmp    100b53 <f1+0x36>
  100b41:	8b 45 0c             	mov    0xc(%ebp),%eax
  100b44:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b48:	8b 45 08             	mov    0x8(%ebp),%eax
  100b4b:	89 04 24             	mov    %eax,(%esp)
  100b4e:	e8 92 ff ff ff       	call   100ae5 <f2>
  100b53:	c9                   	leave  
  100b54:	c3                   	ret    

00100b55 <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  100b55:	55                   	push   %ebp
  100b56:	89 e5                	mov    %esp,%ebp
  100b58:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  100b5e:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  100b65:	eb 28                	jmp    100b8f <debug_check+0x3a>
		f1(i, eips[i]);
  100b67:	8d 8d 50 ff ff ff    	lea    -0xb0(%ebp),%ecx
  100b6d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100b70:	89 d0                	mov    %edx,%eax
  100b72:	c1 e0 02             	shl    $0x2,%eax
  100b75:	01 d0                	add    %edx,%eax
  100b77:	c1 e0 03             	shl    $0x3,%eax
  100b7a:	01 c8                	add    %ecx,%eax
  100b7c:	89 44 24 04          	mov    %eax,0x4(%esp)
  100b80:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100b83:	89 04 24             	mov    %eax,(%esp)
  100b86:	e8 92 ff ff ff       	call   100b1d <f1>
{
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  100b8b:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  100b8f:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
  100b93:	7e d2                	jle    100b67 <debug_check+0x12>
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  100b95:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  100b9c:	e9 bc 00 00 00       	jmp    100c5d <debug_check+0x108>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  100ba1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  100ba8:	e9 a2 00 00 00       	jmp    100c4f <debug_check+0xfa>
			assert((eips[r][i] != 0) == (i < 5));
  100bad:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100bb0:	89 d0                	mov    %edx,%eax
  100bb2:	c1 e0 02             	shl    $0x2,%eax
  100bb5:	01 d0                	add    %edx,%eax
  100bb7:	01 c0                	add    %eax,%eax
  100bb9:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100bbc:	01 d0                	add    %edx,%eax
  100bbe:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  100bc5:	85 c0                	test   %eax,%eax
  100bc7:	0f 95 c2             	setne  %dl
  100bca:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
  100bce:	0f 9e c0             	setle  %al
  100bd1:	31 d0                	xor    %edx,%eax
  100bd3:	84 c0                	test   %al,%al
  100bd5:	74 24                	je     100bfb <debug_check+0xa6>
  100bd7:	c7 44 24 0c cc a2 10 	movl   $0x10a2cc,0xc(%esp)
  100bde:	00 
  100bdf:	c7 44 24 08 e9 a2 10 	movl   $0x10a2e9,0x8(%esp)
  100be6:	00 
  100be7:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
  100bee:	00 
  100bef:	c7 04 24 fe a2 10 00 	movl   $0x10a2fe,(%esp)
  100bf6:	e8 3d fd ff ff       	call   100938 <debug_panic>
			if (i >= 2)
  100bfb:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
  100bff:	7e 4a                	jle    100c4b <debug_check+0xf6>
				assert(eips[r][i] == eips[0][i]);
  100c01:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100c04:	89 d0                	mov    %edx,%eax
  100c06:	c1 e0 02             	shl    $0x2,%eax
  100c09:	01 d0                	add    %edx,%eax
  100c0b:	01 c0                	add    %eax,%eax
  100c0d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100c10:	01 d0                	add    %edx,%eax
  100c12:	8b 94 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%edx
  100c19:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100c1c:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  100c23:	39 c2                	cmp    %eax,%edx
  100c25:	74 24                	je     100c4b <debug_check+0xf6>
  100c27:	c7 44 24 0c 0b a3 10 	movl   $0x10a30b,0xc(%esp)
  100c2e:	00 
  100c2f:	c7 44 24 08 e9 a2 10 	movl   $0x10a2e9,0x8(%esp)
  100c36:	00 
  100c37:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
  100c3e:	00 
  100c3f:	c7 04 24 fe a2 10 00 	movl   $0x10a2fe,(%esp)
  100c46:	e8 ed fc ff ff       	call   100938 <debug_panic>
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  100c4b:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  100c4f:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  100c53:	0f 8e 54 ff ff ff    	jle    100bad <debug_check+0x58>
	// produce several related backtraces...
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  100c59:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  100c5d:	83 7d f4 03          	cmpl   $0x3,-0xc(%ebp)
  100c61:	0f 8e 3a ff ff ff    	jle    100ba1 <debug_check+0x4c>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
			assert((eips[r][i] != 0) == (i < 5));
			if (i >= 2)
				assert(eips[r][i] == eips[0][i]);
		}
	assert(eips[0][0] == eips[1][0]);
  100c67:	8b 95 50 ff ff ff    	mov    -0xb0(%ebp),%edx
  100c6d:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  100c73:	39 c2                	cmp    %eax,%edx
  100c75:	74 24                	je     100c9b <debug_check+0x146>
  100c77:	c7 44 24 0c 24 a3 10 	movl   $0x10a324,0xc(%esp)
  100c7e:	00 
  100c7f:	c7 44 24 08 e9 a2 10 	movl   $0x10a2e9,0x8(%esp)
  100c86:	00 
  100c87:	c7 44 24 04 73 00 00 	movl   $0x73,0x4(%esp)
  100c8e:	00 
  100c8f:	c7 04 24 fe a2 10 00 	movl   $0x10a2fe,(%esp)
  100c96:	e8 9d fc ff ff       	call   100938 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  100c9b:	8b 55 a0             	mov    -0x60(%ebp),%edx
  100c9e:	8b 45 c8             	mov    -0x38(%ebp),%eax
  100ca1:	39 c2                	cmp    %eax,%edx
  100ca3:	74 24                	je     100cc9 <debug_check+0x174>
  100ca5:	c7 44 24 0c 3d a3 10 	movl   $0x10a33d,0xc(%esp)
  100cac:	00 
  100cad:	c7 44 24 08 e9 a2 10 	movl   $0x10a2e9,0x8(%esp)
  100cb4:	00 
  100cb5:	c7 44 24 04 74 00 00 	movl   $0x74,0x4(%esp)
  100cbc:	00 
  100cbd:	c7 04 24 fe a2 10 00 	movl   $0x10a2fe,(%esp)
  100cc4:	e8 6f fc ff ff       	call   100938 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  100cc9:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  100ccf:	8b 45 a0             	mov    -0x60(%ebp),%eax
  100cd2:	39 c2                	cmp    %eax,%edx
  100cd4:	75 24                	jne    100cfa <debug_check+0x1a5>
  100cd6:	c7 44 24 0c 56 a3 10 	movl   $0x10a356,0xc(%esp)
  100cdd:	00 
  100cde:	c7 44 24 08 e9 a2 10 	movl   $0x10a2e9,0x8(%esp)
  100ce5:	00 
  100ce6:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  100ced:	00 
  100cee:	c7 04 24 fe a2 10 00 	movl   $0x10a2fe,(%esp)
  100cf5:	e8 3e fc ff ff       	call   100938 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  100cfa:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100d00:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  100d03:	39 c2                	cmp    %eax,%edx
  100d05:	74 24                	je     100d2b <debug_check+0x1d6>
  100d07:	c7 44 24 0c 6f a3 10 	movl   $0x10a36f,0xc(%esp)
  100d0e:	00 
  100d0f:	c7 44 24 08 e9 a2 10 	movl   $0x10a2e9,0x8(%esp)
  100d16:	00 
  100d17:	c7 44 24 04 76 00 00 	movl   $0x76,0x4(%esp)
  100d1e:	00 
  100d1f:	c7 04 24 fe a2 10 00 	movl   $0x10a2fe,(%esp)
  100d26:	e8 0d fc ff ff       	call   100938 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  100d2b:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  100d31:	8b 45 cc             	mov    -0x34(%ebp),%eax
  100d34:	39 c2                	cmp    %eax,%edx
  100d36:	74 24                	je     100d5c <debug_check+0x207>
  100d38:	c7 44 24 0c 88 a3 10 	movl   $0x10a388,0xc(%esp)
  100d3f:	00 
  100d40:	c7 44 24 08 e9 a2 10 	movl   $0x10a2e9,0x8(%esp)
  100d47:	00 
  100d48:	c7 44 24 04 77 00 00 	movl   $0x77,0x4(%esp)
  100d4f:	00 
  100d50:	c7 04 24 fe a2 10 00 	movl   $0x10a2fe,(%esp)
  100d57:	e8 dc fb ff ff       	call   100938 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  100d5c:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100d62:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  100d68:	39 c2                	cmp    %eax,%edx
  100d6a:	75 24                	jne    100d90 <debug_check+0x23b>
  100d6c:	c7 44 24 0c a1 a3 10 	movl   $0x10a3a1,0xc(%esp)
  100d73:	00 
  100d74:	c7 44 24 08 e9 a2 10 	movl   $0x10a2e9,0x8(%esp)
  100d7b:	00 
  100d7c:	c7 44 24 04 78 00 00 	movl   $0x78,0x4(%esp)
  100d83:	00 
  100d84:	c7 04 24 fe a2 10 00 	movl   $0x10a2fe,(%esp)
  100d8b:	e8 a8 fb ff ff       	call   100938 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  100d90:	c7 04 24 ba a3 10 00 	movl   $0x10a3ba,(%esp)
  100d97:	e8 34 8b 00 00       	call   1098d0 <cprintf>
}
  100d9c:	c9                   	leave  
  100d9d:	c3                   	ret    
  100d9e:	66 90                	xchg   %ax,%ax

00100da0 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100da0:	55                   	push   %ebp
  100da1:	89 e5                	mov    %esp,%ebp
  100da3:	53                   	push   %ebx
  100da4:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100da7:	89 e3                	mov    %esp,%ebx
  100da9:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  100dac:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100daf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100db2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100db5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100dba:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  100dbd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100dc0:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  100dc6:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100dcb:	74 24                	je     100df1 <cpu_cur+0x51>
  100dcd:	c7 44 24 0c d4 a3 10 	movl   $0x10a3d4,0xc(%esp)
  100dd4:	00 
  100dd5:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  100ddc:	00 
  100ddd:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100de4:	00 
  100de5:	c7 04 24 ff a3 10 00 	movl   $0x10a3ff,(%esp)
  100dec:	e8 47 fb ff ff       	call   100938 <debug_panic>
	return c;
  100df1:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  100df4:	83 c4 24             	add    $0x24,%esp
  100df7:	5b                   	pop    %ebx
  100df8:	5d                   	pop    %ebp
  100df9:	c3                   	ret    

00100dfa <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100dfa:	55                   	push   %ebp
  100dfb:	89 e5                	mov    %esp,%ebp
  100dfd:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100e00:	e8 9b ff ff ff       	call   100da0 <cpu_cur>
  100e05:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  100e0a:	0f 94 c0             	sete   %al
  100e0d:	0f b6 c0             	movzbl %al,%eax
}
  100e10:	c9                   	leave  
  100e11:	c3                   	ret    

00100e12 <mem_init>:

void mem_check(void);

void
mem_init(void)
{
  100e12:	55                   	push   %ebp
  100e13:	89 e5                	mov    %esp,%ebp
  100e15:	83 ec 38             	sub    $0x38,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  100e18:	e8 dd ff ff ff       	call   100dfa <cpu_onboot>
  100e1d:	85 c0                	test   %eax,%eax
  100e1f:	0f 84 a3 01 00 00    	je     100fc8 <mem_init+0x1b6>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  100e25:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  100e2c:	e8 8d 7d 00 00       	call   108bbe <nvram_read16>
  100e31:	c1 e0 0a             	shl    $0xa,%eax
  100e34:	89 45 ec             	mov    %eax,-0x14(%ebp)
  100e37:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100e3a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100e3f:	89 45 e8             	mov    %eax,-0x18(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  100e42:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  100e49:	e8 70 7d 00 00       	call   108bbe <nvram_read16>
  100e4e:	c1 e0 0a             	shl    $0xa,%eax
  100e51:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100e54:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100e57:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100e5c:	89 45 e0             	mov    %eax,-0x20(%ebp)

	warn("Assuming we have 1GB of memory!");
  100e5f:	c7 44 24 08 0c a4 10 	movl   $0x10a40c,0x8(%esp)
  100e66:	00 
  100e67:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
  100e6e:	00 
  100e6f:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  100e76:	e8 83 fb ff ff       	call   1009fe <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  100e7b:	c7 45 e0 00 00 f0 3f 	movl   $0x3ff00000,-0x20(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  100e82:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100e85:	05 00 00 10 00       	add    $0x100000,%eax
  100e8a:	a3 48 8f 38 00       	mov    %eax,0x388f48

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  100e8f:	a1 48 8f 38 00       	mov    0x388f48,%eax
  100e94:	c1 e8 0c             	shr    $0xc,%eax
  100e97:	a3 44 8f 38 00       	mov    %eax,0x388f44

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  100e9c:	a1 48 8f 38 00       	mov    0x388f48,%eax
  100ea1:	c1 e8 0a             	shr    $0xa,%eax
  100ea4:	89 44 24 04          	mov    %eax,0x4(%esp)
  100ea8:	c7 04 24 38 a4 10 00 	movl   $0x10a438,(%esp)
  100eaf:	e8 1c 8a 00 00       	call   1098d0 <cprintf>
	cprintf("base = %dK, extended = %dK\n",
		(int)(basemem/1024), (int)(extmem/1024));
  100eb4:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100eb7:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100eba:	89 c2                	mov    %eax,%edx
		(int)(basemem/1024), (int)(extmem/1024));
  100ebc:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ebf:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100ec2:	89 54 24 08          	mov    %edx,0x8(%esp)
  100ec6:	89 44 24 04          	mov    %eax,0x4(%esp)
  100eca:	c7 04 24 59 a4 10 00 	movl   $0x10a459,(%esp)
  100ed1:	e8 fa 89 00 00       	call   1098d0 <cprintf>
		(int)(basemem/1024), (int)(extmem/1024));
	spinlock_init(mem_spinlock);
  100ed6:	a1 4c 8f 38 00       	mov    0x388f4c,%eax
  100edb:	c7 44 24 08 3c 00 00 	movl   $0x3c,0x8(%esp)
  100ee2:	00 
  100ee3:	c7 44 24 04 2c a4 10 	movl   $0x10a42c,0x4(%esp)
  100eea:	00 
  100eeb:	89 04 24             	mov    %eax,(%esp)
  100eee:	e8 d4 1a 00 00       	call   1029c7 <spinlock_init_>
	//     Some of it is in use, some is free.
	//     Which pages hold the kernel and the pageinfo array?
	//     Hint: the linker places the kernel (see start and end above),
	//     but YOU decide where to place the pageinfo array.
	// Change the code to reflect this.
	pageinfo **freetail = &mem_freelist;
  100ef3:	c7 45 f4 40 8f 38 00 	movl   $0x388f40,-0xc(%ebp)
	int i;
	mem_pageinfo = tmp_pageinfo;
  100efa:	c7 05 50 8f 38 00 40 	movl   $0x188f40,0x388f50
  100f01:	8f 18 00 
	memset(tmp_pageinfo, 0, (sizeof(pageinfo)*1024*1024*1024)/PAGESIZE);
  100f04:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  100f0b:	00 
  100f0c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100f13:	00 
  100f14:	c7 04 24 40 8f 18 00 	movl   $0x188f40,(%esp)
  100f1b:	e8 21 8d 00 00       	call   109c41 <memset>
	for (i = 0; i < mem_npage; i++) {
  100f20:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  100f27:	eb 7f                	jmp    100fa8 <mem_init+0x196>
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  100f29:	a1 50 8f 38 00       	mov    0x388f50,%eax
  100f2e:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100f31:	c1 e2 03             	shl    $0x3,%edx
  100f34:	01 d0                	add    %edx,%eax
  100f36:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
		if(i == 0 || i == 1)
  100f3d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  100f41:	74 5a                	je     100f9d <mem_init+0x18b>
  100f43:	83 7d f0 01          	cmpl   $0x1,-0x10(%ebp)
  100f47:	74 54                	je     100f9d <mem_init+0x18b>
			continue;
		if(i >= MEM_IO/PAGESIZE && i < MEM_EXT/PAGESIZE)
  100f49:	81 7d f0 9f 00 00 00 	cmpl   $0x9f,-0x10(%ebp)
  100f50:	7e 09                	jle    100f5b <mem_init+0x149>
  100f52:	81 7d f0 ff 00 00 00 	cmpl   $0xff,-0x10(%ebp)
  100f59:	7e 45                	jle    100fa0 <mem_init+0x18e>
			continue;
		// Add the page to the end of the free list.s
		if(i >= ((uint32_t)start)/PAGESIZE && i <= ((uint32_t)end)/PAGESIZE)
  100f5b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f5e:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  100f63:	c1 ea 0c             	shr    $0xc,%edx
  100f66:	39 d0                	cmp    %edx,%eax
  100f68:	72 0f                	jb     100f79 <mem_init+0x167>
  100f6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100f6d:	ba 08 c0 38 00       	mov    $0x38c008,%edx
  100f72:	c1 ea 0c             	shr    $0xc,%edx
  100f75:	39 d0                	cmp    %edx,%eax
  100f77:	76 2a                	jbe    100fa3 <mem_init+0x191>
			continue;
		*freetail = &mem_pageinfo[i];
  100f79:	a1 50 8f 38 00       	mov    0x388f50,%eax
  100f7e:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100f81:	c1 e2 03             	shl    $0x3,%edx
  100f84:	01 c2                	add    %eax,%edx
  100f86:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100f89:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100f8b:	a1 50 8f 38 00       	mov    0x388f50,%eax
  100f90:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100f93:	c1 e2 03             	shl    $0x3,%edx
  100f96:	01 d0                	add    %edx,%eax
  100f98:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100f9b:	eb 07                	jmp    100fa4 <mem_init+0x192>
	memset(tmp_pageinfo, 0, (sizeof(pageinfo)*1024*1024*1024)/PAGESIZE);
	for (i = 0; i < mem_npage; i++) {
		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
		if(i == 0 || i == 1)
			continue;
  100f9d:	90                   	nop
  100f9e:	eb 04                	jmp    100fa4 <mem_init+0x192>
		if(i >= MEM_IO/PAGESIZE && i < MEM_EXT/PAGESIZE)
			continue;
  100fa0:	90                   	nop
  100fa1:	eb 01                	jmp    100fa4 <mem_init+0x192>
		// Add the page to the end of the free list.s
		if(i >= ((uint32_t)start)/PAGESIZE && i <= ((uint32_t)end)/PAGESIZE)
			continue;
  100fa3:	90                   	nop
	// Change the code to reflect this.
	pageinfo **freetail = &mem_freelist;
	int i;
	mem_pageinfo = tmp_pageinfo;
	memset(tmp_pageinfo, 0, (sizeof(pageinfo)*1024*1024*1024)/PAGESIZE);
	for (i = 0; i < mem_npage; i++) {
  100fa4:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  100fa8:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100fab:	a1 44 8f 38 00       	mov    0x388f44,%eax
  100fb0:	39 c2                	cmp    %eax,%edx
  100fb2:	0f 82 71 ff ff ff    	jb     100f29 <mem_init+0x117>
		if(i >= ((uint32_t)start)/PAGESIZE && i <= ((uint32_t)end)/PAGESIZE)
			continue;
		*freetail = &mem_pageinfo[i];
		freetail = &mem_pageinfo[i].free_next;
	}
	*freetail = NULL;	// null-terminate the freelist
  100fb8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100fbb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
  100fc1:	e8 e1 00 00 00       	call   1010a7 <mem_check>
  100fc6:	eb 01                	jmp    100fc9 <mem_init+0x1b7>

void
mem_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  100fc8:	90                   	nop
	// ...and remove this when you're ready.
	//panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
}
  100fc9:	c9                   	leave  
  100fca:	c3                   	ret    

00100fcb <mem_alloc>:
//
// Hint: pi->refs should not be incremented 
// Hint: be sure to use proper mutual exclusion for multiprocessor operation.
pageinfo *
mem_alloc(void)
{
  100fcb:	55                   	push   %ebp
  100fcc:	89 e5                	mov    %esp,%ebp
  100fce:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in.
	//panic("mem_alloc not implemented.");
	pageinfo *return_page;
	if(!mem_freelist)
  100fd1:	a1 40 8f 38 00       	mov    0x388f40,%eax
  100fd6:	85 c0                	test   %eax,%eax
  100fd8:	75 07                	jne    100fe1 <mem_alloc+0x16>
		return NULL;
  100fda:	b8 00 00 00 00       	mov    $0x0,%eax
  100fdf:	eb 3a                	jmp    10101b <mem_alloc+0x50>
	spinlock_acquire(mem_spinlock);
  100fe1:	a1 4c 8f 38 00       	mov    0x388f4c,%eax
  100fe6:	89 04 24             	mov    %eax,(%esp)
  100fe9:	e8 03 1a 00 00       	call   1029f1 <spinlock_acquire>
	return_page = mem_freelist;
  100fee:	a1 40 8f 38 00       	mov    0x388f40,%eax
  100ff3:	89 45 f4             	mov    %eax,-0xc(%ebp)
	mem_freelist = mem_freelist->free_next;
  100ff6:	a1 40 8f 38 00       	mov    0x388f40,%eax
  100ffb:	8b 00                	mov    (%eax),%eax
  100ffd:	a3 40 8f 38 00       	mov    %eax,0x388f40
	spinlock_release(mem_spinlock);
  101002:	a1 4c 8f 38 00       	mov    0x388f4c,%eax
  101007:	89 04 24             	mov    %eax,(%esp)
  10100a:	e8 57 1a 00 00       	call   102a66 <spinlock_release>
	return_page->free_next = NULL;
  10100f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101012:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	return return_page;
  101018:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  10101b:	c9                   	leave  
  10101c:	c3                   	ret    

0010101d <mem_free>:
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  10101d:	55                   	push   %ebp
  10101e:	89 e5                	mov    %esp,%ebp
  101020:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in.
	//panic("mem_free not implemented.");
	assert(pi->refcount == 0);
  101023:	8b 45 08             	mov    0x8(%ebp),%eax
  101026:	8b 40 04             	mov    0x4(%eax),%eax
  101029:	85 c0                	test   %eax,%eax
  10102b:	74 24                	je     101051 <mem_free+0x34>
  10102d:	c7 44 24 0c 75 a4 10 	movl   $0x10a475,0xc(%esp)
  101034:	00 
  101035:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  10103c:	00 
  10103d:	c7 44 24 04 91 00 00 	movl   $0x91,0x4(%esp)
  101044:	00 
  101045:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  10104c:	e8 e7 f8 ff ff       	call   100938 <debug_panic>
	if(((int)pi <= 0x123608) && ((int)pi >= 0x1224e0))
  101051:	8b 45 08             	mov    0x8(%ebp),%eax
  101054:	3d 08 36 12 00       	cmp    $0x123608,%eax
  101059:	7f 1d                	jg     101078 <mem_free+0x5b>
  10105b:	8b 45 08             	mov    0x8(%ebp),%eax
  10105e:	3d df 24 12 00       	cmp    $0x1224df,%eax
  101063:	7e 13                	jle    101078 <mem_free+0x5b>
		cprintf("=========== in mem_free 0x%x free.============\n", pi);
  101065:	8b 45 08             	mov    0x8(%ebp),%eax
  101068:	89 44 24 04          	mov    %eax,0x4(%esp)
  10106c:	c7 04 24 88 a4 10 00 	movl   $0x10a488,(%esp)
  101073:	e8 58 88 00 00       	call   1098d0 <cprintf>
	spinlock_acquire(mem_spinlock);
  101078:	a1 4c 8f 38 00       	mov    0x388f4c,%eax
  10107d:	89 04 24             	mov    %eax,(%esp)
  101080:	e8 6c 19 00 00       	call   1029f1 <spinlock_acquire>
	pi->free_next = mem_freelist;
  101085:	8b 15 40 8f 38 00    	mov    0x388f40,%edx
  10108b:	8b 45 08             	mov    0x8(%ebp),%eax
  10108e:	89 10                	mov    %edx,(%eax)
	mem_freelist = pi;
  101090:	8b 45 08             	mov    0x8(%ebp),%eax
  101093:	a3 40 8f 38 00       	mov    %eax,0x388f40
	spinlock_release(mem_spinlock);
  101098:	a1 4c 8f 38 00       	mov    0x388f4c,%eax
  10109d:	89 04 24             	mov    %eax,(%esp)
  1010a0:	e8 c1 19 00 00       	call   102a66 <spinlock_release>
}
  1010a5:	c9                   	leave  
  1010a6:	c3                   	ret    

001010a7 <mem_check>:
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  1010a7:	55                   	push   %ebp
  1010a8:	89 e5                	mov    %esp,%ebp
  1010aa:	83 ec 38             	sub    $0x38,%esp
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  1010ad:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  1010b4:	a1 40 8f 38 00       	mov    0x388f40,%eax
  1010b9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1010bc:	eb 38                	jmp    1010f6 <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  1010be:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1010c1:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1010c6:	89 d1                	mov    %edx,%ecx
  1010c8:	29 c1                	sub    %eax,%ecx
  1010ca:	89 c8                	mov    %ecx,%eax
  1010cc:	c1 f8 03             	sar    $0x3,%eax
  1010cf:	c1 e0 0c             	shl    $0xc,%eax
  1010d2:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  1010d9:	00 
  1010da:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  1010e1:	00 
  1010e2:	89 04 24             	mov    %eax,(%esp)
  1010e5:	e8 57 8b 00 00       	call   109c41 <memset>
		freepages++;
  1010ea:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  1010ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1010f1:	8b 00                	mov    (%eax),%eax
  1010f3:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1010f6:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1010fa:	75 c2                	jne    1010be <mem_check+0x17>
		memset(mem_pi2ptr(pp), 0x97, 128);
		freepages++;
	}
	cprintf("mem_check: %d free pages\n", freepages);
  1010fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1010ff:	89 44 24 04          	mov    %eax,0x4(%esp)
  101103:	c7 04 24 b8 a4 10 00 	movl   $0x10a4b8,(%esp)
  10110a:	e8 c1 87 00 00       	call   1098d0 <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  10110f:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101112:	a1 44 8f 38 00       	mov    0x388f44,%eax
  101117:	39 c2                	cmp    %eax,%edx
  101119:	72 24                	jb     10113f <mem_check+0x98>
  10111b:	c7 44 24 0c d2 a4 10 	movl   $0x10a4d2,0xc(%esp)
  101122:	00 
  101123:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  10112a:	00 
  10112b:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
  101132:	00 
  101133:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  10113a:	e8 f9 f7 ff ff       	call   100938 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  10113f:	81 7d f0 80 3e 00 00 	cmpl   $0x3e80,-0x10(%ebp)
  101146:	7f 24                	jg     10116c <mem_check+0xc5>
  101148:	c7 44 24 0c e8 a4 10 	movl   $0x10a4e8,0xc(%esp)
  10114f:	00 
  101150:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  101157:	00 
  101158:	c7 44 24 04 af 00 00 	movl   $0xaf,0x4(%esp)
  10115f:	00 
  101160:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  101167:	e8 cc f7 ff ff       	call   100938 <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  10116c:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  101173:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101176:	89 45 e8             	mov    %eax,-0x18(%ebp)
  101179:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10117c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  10117f:	e8 47 fe ff ff       	call   100fcb <mem_alloc>
  101184:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  101187:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  10118b:	75 24                	jne    1011b1 <mem_check+0x10a>
  10118d:	c7 44 24 0c fa a4 10 	movl   $0x10a4fa,0xc(%esp)
  101194:	00 
  101195:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  10119c:	00 
  10119d:	c7 44 24 04 b3 00 00 	movl   $0xb3,0x4(%esp)
  1011a4:	00 
  1011a5:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  1011ac:	e8 87 f7 ff ff       	call   100938 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  1011b1:	e8 15 fe ff ff       	call   100fcb <mem_alloc>
  1011b6:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1011b9:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  1011bd:	75 24                	jne    1011e3 <mem_check+0x13c>
  1011bf:	c7 44 24 0c 03 a5 10 	movl   $0x10a503,0xc(%esp)
  1011c6:	00 
  1011c7:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  1011ce:	00 
  1011cf:	c7 44 24 04 b4 00 00 	movl   $0xb4,0x4(%esp)
  1011d6:	00 
  1011d7:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  1011de:	e8 55 f7 ff ff       	call   100938 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  1011e3:	e8 e3 fd ff ff       	call   100fcb <mem_alloc>
  1011e8:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1011eb:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1011ef:	75 24                	jne    101215 <mem_check+0x16e>
  1011f1:	c7 44 24 0c 0c a5 10 	movl   $0x10a50c,0xc(%esp)
  1011f8:	00 
  1011f9:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  101200:	00 
  101201:	c7 44 24 04 b5 00 00 	movl   $0xb5,0x4(%esp)
  101208:	00 
  101209:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  101210:	e8 23 f7 ff ff       	call   100938 <debug_panic>

	assert(pp0);
  101215:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  101219:	75 24                	jne    10123f <mem_check+0x198>
  10121b:	c7 44 24 0c 15 a5 10 	movl   $0x10a515,0xc(%esp)
  101222:	00 
  101223:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  10122a:	00 
  10122b:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
  101232:	00 
  101233:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  10123a:	e8 f9 f6 ff ff       	call   100938 <debug_panic>
	assert(pp1 && pp1 != pp0);
  10123f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  101243:	74 08                	je     10124d <mem_check+0x1a6>
  101245:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101248:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  10124b:	75 24                	jne    101271 <mem_check+0x1ca>
  10124d:	c7 44 24 0c 19 a5 10 	movl   $0x10a519,0xc(%esp)
  101254:	00 
  101255:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  10125c:	00 
  10125d:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
  101264:	00 
  101265:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  10126c:	e8 c7 f6 ff ff       	call   100938 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  101271:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  101275:	74 10                	je     101287 <mem_check+0x1e0>
  101277:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10127a:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  10127d:	74 08                	je     101287 <mem_check+0x1e0>
  10127f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101282:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  101285:	75 24                	jne    1012ab <mem_check+0x204>
  101287:	c7 44 24 0c 2c a5 10 	movl   $0x10a52c,0xc(%esp)
  10128e:	00 
  10128f:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  101296:	00 
  101297:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
  10129e:	00 
  10129f:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  1012a6:	e8 8d f6 ff ff       	call   100938 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  1012ab:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1012ae:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1012b3:	89 d1                	mov    %edx,%ecx
  1012b5:	29 c1                	sub    %eax,%ecx
  1012b7:	89 c8                	mov    %ecx,%eax
  1012b9:	c1 f8 03             	sar    $0x3,%eax
  1012bc:	c1 e0 0c             	shl    $0xc,%eax
  1012bf:	8b 15 44 8f 38 00    	mov    0x388f44,%edx
  1012c5:	c1 e2 0c             	shl    $0xc,%edx
  1012c8:	39 d0                	cmp    %edx,%eax
  1012ca:	72 24                	jb     1012f0 <mem_check+0x249>
  1012cc:	c7 44 24 0c 4c a5 10 	movl   $0x10a54c,0xc(%esp)
  1012d3:	00 
  1012d4:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  1012db:	00 
  1012dc:	c7 44 24 04 ba 00 00 	movl   $0xba,0x4(%esp)
  1012e3:	00 
  1012e4:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  1012eb:	e8 48 f6 ff ff       	call   100938 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  1012f0:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1012f3:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1012f8:	89 d1                	mov    %edx,%ecx
  1012fa:	29 c1                	sub    %eax,%ecx
  1012fc:	89 c8                	mov    %ecx,%eax
  1012fe:	c1 f8 03             	sar    $0x3,%eax
  101301:	c1 e0 0c             	shl    $0xc,%eax
  101304:	8b 15 44 8f 38 00    	mov    0x388f44,%edx
  10130a:	c1 e2 0c             	shl    $0xc,%edx
  10130d:	39 d0                	cmp    %edx,%eax
  10130f:	72 24                	jb     101335 <mem_check+0x28e>
  101311:	c7 44 24 0c 74 a5 10 	movl   $0x10a574,0xc(%esp)
  101318:	00 
  101319:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  101320:	00 
  101321:	c7 44 24 04 bb 00 00 	movl   $0xbb,0x4(%esp)
  101328:	00 
  101329:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  101330:	e8 03 f6 ff ff       	call   100938 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  101335:	8b 55 ec             	mov    -0x14(%ebp),%edx
  101338:	a1 50 8f 38 00       	mov    0x388f50,%eax
  10133d:	89 d1                	mov    %edx,%ecx
  10133f:	29 c1                	sub    %eax,%ecx
  101341:	89 c8                	mov    %ecx,%eax
  101343:	c1 f8 03             	sar    $0x3,%eax
  101346:	c1 e0 0c             	shl    $0xc,%eax
  101349:	8b 15 44 8f 38 00    	mov    0x388f44,%edx
  10134f:	c1 e2 0c             	shl    $0xc,%edx
  101352:	39 d0                	cmp    %edx,%eax
  101354:	72 24                	jb     10137a <mem_check+0x2d3>
  101356:	c7 44 24 0c 9c a5 10 	movl   $0x10a59c,0xc(%esp)
  10135d:	00 
  10135e:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  101365:	00 
  101366:	c7 44 24 04 bc 00 00 	movl   $0xbc,0x4(%esp)
  10136d:	00 
  10136e:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  101375:	e8 be f5 ff ff       	call   100938 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  10137a:	a1 40 8f 38 00       	mov    0x388f40,%eax
  10137f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	mem_freelist = 0;
  101382:	c7 05 40 8f 38 00 00 	movl   $0x0,0x388f40
  101389:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  10138c:	e8 3a fc ff ff       	call   100fcb <mem_alloc>
  101391:	85 c0                	test   %eax,%eax
  101393:	74 24                	je     1013b9 <mem_check+0x312>
  101395:	c7 44 24 0c c2 a5 10 	movl   $0x10a5c2,0xc(%esp)
  10139c:	00 
  10139d:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  1013a4:	00 
  1013a5:	c7 44 24 04 c3 00 00 	movl   $0xc3,0x4(%esp)
  1013ac:	00 
  1013ad:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  1013b4:	e8 7f f5 ff ff       	call   100938 <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  1013b9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1013bc:	89 04 24             	mov    %eax,(%esp)
  1013bf:	e8 59 fc ff ff       	call   10101d <mem_free>
        mem_free(pp1);
  1013c4:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1013c7:	89 04 24             	mov    %eax,(%esp)
  1013ca:	e8 4e fc ff ff       	call   10101d <mem_free>
        mem_free(pp2);
  1013cf:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1013d2:	89 04 24             	mov    %eax,(%esp)
  1013d5:	e8 43 fc ff ff       	call   10101d <mem_free>
	pp0 = pp1 = pp2 = 0;
  1013da:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  1013e1:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1013e4:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1013e7:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1013ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  1013ed:	e8 d9 fb ff ff       	call   100fcb <mem_alloc>
  1013f2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  1013f5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  1013f9:	75 24                	jne    10141f <mem_check+0x378>
  1013fb:	c7 44 24 0c fa a4 10 	movl   $0x10a4fa,0xc(%esp)
  101402:	00 
  101403:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  10140a:	00 
  10140b:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
  101412:	00 
  101413:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  10141a:	e8 19 f5 ff ff       	call   100938 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  10141f:	e8 a7 fb ff ff       	call   100fcb <mem_alloc>
  101424:	89 45 e8             	mov    %eax,-0x18(%ebp)
  101427:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  10142b:	75 24                	jne    101451 <mem_check+0x3aa>
  10142d:	c7 44 24 0c 03 a5 10 	movl   $0x10a503,0xc(%esp)
  101434:	00 
  101435:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  10143c:	00 
  10143d:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
  101444:	00 
  101445:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  10144c:	e8 e7 f4 ff ff       	call   100938 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  101451:	e8 75 fb ff ff       	call   100fcb <mem_alloc>
  101456:	89 45 ec             	mov    %eax,-0x14(%ebp)
  101459:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  10145d:	75 24                	jne    101483 <mem_check+0x3dc>
  10145f:	c7 44 24 0c 0c a5 10 	movl   $0x10a50c,0xc(%esp)
  101466:	00 
  101467:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  10146e:	00 
  10146f:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
  101476:	00 
  101477:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  10147e:	e8 b5 f4 ff ff       	call   100938 <debug_panic>
	assert(pp0);
  101483:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  101487:	75 24                	jne    1014ad <mem_check+0x406>
  101489:	c7 44 24 0c 15 a5 10 	movl   $0x10a515,0xc(%esp)
  101490:	00 
  101491:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  101498:	00 
  101499:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  1014a0:	00 
  1014a1:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  1014a8:	e8 8b f4 ff ff       	call   100938 <debug_panic>
	assert(pp1 && pp1 != pp0);
  1014ad:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  1014b1:	74 08                	je     1014bb <mem_check+0x414>
  1014b3:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1014b6:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  1014b9:	75 24                	jne    1014df <mem_check+0x438>
  1014bb:	c7 44 24 0c 19 a5 10 	movl   $0x10a519,0xc(%esp)
  1014c2:	00 
  1014c3:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  1014ca:	00 
  1014cb:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  1014d2:	00 
  1014d3:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  1014da:	e8 59 f4 ff ff       	call   100938 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  1014df:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1014e3:	74 10                	je     1014f5 <mem_check+0x44e>
  1014e5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1014e8:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  1014eb:	74 08                	je     1014f5 <mem_check+0x44e>
  1014ed:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1014f0:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  1014f3:	75 24                	jne    101519 <mem_check+0x472>
  1014f5:	c7 44 24 0c 2c a5 10 	movl   $0x10a52c,0xc(%esp)
  1014fc:	00 
  1014fd:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  101504:	00 
  101505:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  10150c:	00 
  10150d:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  101514:	e8 1f f4 ff ff       	call   100938 <debug_panic>
	assert(mem_alloc() == 0);
  101519:	e8 ad fa ff ff       	call   100fcb <mem_alloc>
  10151e:	85 c0                	test   %eax,%eax
  101520:	74 24                	je     101546 <mem_check+0x49f>
  101522:	c7 44 24 0c c2 a5 10 	movl   $0x10a5c2,0xc(%esp)
  101529:	00 
  10152a:	c7 44 24 08 ea a3 10 	movl   $0x10a3ea,0x8(%esp)
  101531:	00 
  101532:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
  101539:	00 
  10153a:	c7 04 24 2c a4 10 00 	movl   $0x10a42c,(%esp)
  101541:	e8 f2 f3 ff ff       	call   100938 <debug_panic>

	// give free list back
	mem_freelist = fl;
  101546:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101549:	a3 40 8f 38 00       	mov    %eax,0x388f40

	// free the pages we took
	mem_free(pp0);
  10154e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  101551:	89 04 24             	mov    %eax,(%esp)
  101554:	e8 c4 fa ff ff       	call   10101d <mem_free>
	mem_free(pp1);
  101559:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10155c:	89 04 24             	mov    %eax,(%esp)
  10155f:	e8 b9 fa ff ff       	call   10101d <mem_free>
	mem_free(pp2);
  101564:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101567:	89 04 24             	mov    %eax,(%esp)
  10156a:	e8 ae fa ff ff       	call   10101d <mem_free>

	cprintf("mem_check() succeeded!\n");
  10156f:	c7 04 24 d3 a5 10 00 	movl   $0x10a5d3,(%esp)
  101576:	e8 55 83 00 00       	call   1098d0 <cprintf>
}
  10157b:	c9                   	leave  
  10157c:	c3                   	ret    
  10157d:	66 90                	xchg   %ax,%ax
  10157f:	90                   	nop

00101580 <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  101580:	55                   	push   %ebp
  101581:	89 e5                	mov    %esp,%ebp
  101583:	53                   	push   %ebx
  101584:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
	       "+m" (*addr), "=a" (result) :
  101587:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  10158a:	8b 45 0c             	mov    0xc(%ebp),%eax
	       "+m" (*addr), "=a" (result) :
  10158d:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  101590:	89 c3                	mov    %eax,%ebx
  101592:	89 d8                	mov    %ebx,%eax
  101594:	f0 87 02             	lock xchg %eax,(%edx)
  101597:	89 c3                	mov    %eax,%ebx
  101599:	89 5d f8             	mov    %ebx,-0x8(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  10159c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  10159f:	83 c4 10             	add    $0x10,%esp
  1015a2:	5b                   	pop    %ebx
  1015a3:	5d                   	pop    %ebp
  1015a4:	c3                   	ret    

001015a5 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1015a5:	55                   	push   %ebp
  1015a6:	89 e5                	mov    %esp,%ebp
  1015a8:	53                   	push   %ebx
  1015a9:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1015ac:	89 e3                	mov    %esp,%ebx
  1015ae:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  1015b1:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1015b4:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1015b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1015ba:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1015bf:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  1015c2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1015c5:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1015cb:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1015d0:	74 24                	je     1015f6 <cpu_cur+0x51>
  1015d2:	c7 44 24 0c eb a5 10 	movl   $0x10a5eb,0xc(%esp)
  1015d9:	00 
  1015da:	c7 44 24 08 01 a6 10 	movl   $0x10a601,0x8(%esp)
  1015e1:	00 
  1015e2:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1015e9:	00 
  1015ea:	c7 04 24 16 a6 10 00 	movl   $0x10a616,(%esp)
  1015f1:	e8 42 f3 ff ff       	call   100938 <debug_panic>
	return c;
  1015f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1015f9:	83 c4 24             	add    $0x24,%esp
  1015fc:	5b                   	pop    %ebx
  1015fd:	5d                   	pop    %ebp
  1015fe:	c3                   	ret    

001015ff <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1015ff:	55                   	push   %ebp
  101600:	89 e5                	mov    %esp,%ebp
  101602:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  101605:	e8 9b ff ff ff       	call   1015a5 <cpu_cur>
  10160a:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  10160f:	0f 94 c0             	sete   %al
  101612:	0f b6 c0             	movzbl %al,%eax
}
  101615:	c9                   	leave  
  101616:	c3                   	ret    

00101617 <cpu_init>:
	magic: CPU_MAGIC
};


void cpu_init()
{
  101617:	55                   	push   %ebp
  101618:	89 e5                	mov    %esp,%ebp
  10161a:	53                   	push   %ebx
  10161b:	83 ec 14             	sub    $0x14,%esp
	cpu *c = cpu_cur();
  10161e:	e8 82 ff ff ff       	call   1015a5 <cpu_cur>
  101623:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// Load the GDT
	struct pseudodesc gdt_pd = {
  101626:	66 c7 45 ec 37 00    	movw   $0x37,-0x14(%ebp)
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  10162c:	8b 45 f4             	mov    -0xc(%ebp),%eax

void cpu_init()
{
	cpu *c = cpu_cur();
	// Load the GDT
	struct pseudodesc gdt_pd = {
  10162f:	89 45 ee             	mov    %eax,-0x12(%ebp)
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  101632:	0f 01 55 ec          	lgdtl  -0x14(%ebp)
	// Reload all segment registers.
	asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
  101636:	b8 23 00 00 00       	mov    $0x23,%eax
  10163b:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
  10163d:	b8 23 00 00 00       	mov    $0x23,%eax
  101642:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  101644:	b8 10 00 00 00       	mov    $0x10,%eax
  101649:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  10164b:	b8 10 00 00 00       	mov    $0x10,%eax
  101650:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  101652:	b8 10 00 00 00       	mov    $0x10,%eax
  101657:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE)); // reload CS
  101659:	ea 60 16 10 00 08 00 	ljmp   $0x8,$0x101660
	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  101660:	b8 00 00 00 00       	mov    $0x0,%eax
  101665:	0f 00 d0             	lldt   %ax
	
	c->tss.ts_ss0 = CPU_GDT_KDATA;
  101668:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10166b:	66 c7 40 40 10 00    	movw   $0x10,0x40(%eax)
	c->tss.ts_esp0 = (uintptr_t)(c->kstackhi);
  101671:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101674:	05 00 10 00 00       	add    $0x1000,%eax
  101679:	89 c2                	mov    %eax,%edx
  10167b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10167e:	89 50 3c             	mov    %edx,0x3c(%eax)
	c->gdt[CPU_GDT_TSS >> 3] = SEGDESC16(0, STS_T32A, (uintptr_t)(&c->tss), sizeof(c->tss)-1, 0);
  101681:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101684:	83 c0 38             	add    $0x38,%eax
  101687:	89 c3                	mov    %eax,%ebx
  101689:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10168c:	83 c0 38             	add    $0x38,%eax
  10168f:	c1 e8 10             	shr    $0x10,%eax
  101692:	89 c1                	mov    %eax,%ecx
  101694:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101697:	83 c0 38             	add    $0x38,%eax
  10169a:	c1 e8 18             	shr    $0x18,%eax
  10169d:	89 c2                	mov    %eax,%edx
  10169f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1016a2:	66 c7 40 30 67 00    	movw   $0x67,0x30(%eax)
  1016a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1016ab:	66 89 58 32          	mov    %bx,0x32(%eax)
  1016af:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1016b2:	88 48 34             	mov    %cl,0x34(%eax)
  1016b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1016b8:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  1016bc:	83 e1 f0             	and    $0xfffffff0,%ecx
  1016bf:	83 c9 09             	or     $0x9,%ecx
  1016c2:	88 48 35             	mov    %cl,0x35(%eax)
  1016c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1016c8:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  1016cc:	83 e1 ef             	and    $0xffffffef,%ecx
  1016cf:	88 48 35             	mov    %cl,0x35(%eax)
  1016d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1016d5:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  1016d9:	83 e1 9f             	and    $0xffffff9f,%ecx
  1016dc:	88 48 35             	mov    %cl,0x35(%eax)
  1016df:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1016e2:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  1016e6:	83 c9 80             	or     $0xffffff80,%ecx
  1016e9:	88 48 35             	mov    %cl,0x35(%eax)
  1016ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1016ef:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  1016f3:	83 e1 f0             	and    $0xfffffff0,%ecx
  1016f6:	88 48 36             	mov    %cl,0x36(%eax)
  1016f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1016fc:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101700:	83 e1 ef             	and    $0xffffffef,%ecx
  101703:	88 48 36             	mov    %cl,0x36(%eax)
  101706:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101709:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10170d:	83 e1 df             	and    $0xffffffdf,%ecx
  101710:	88 48 36             	mov    %cl,0x36(%eax)
  101713:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101716:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10171a:	83 c9 40             	or     $0x40,%ecx
  10171d:	88 48 36             	mov    %cl,0x36(%eax)
  101720:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101723:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101727:	83 e1 7f             	and    $0x7f,%ecx
  10172a:	88 48 36             	mov    %cl,0x36(%eax)
  10172d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101730:	88 50 37             	mov    %dl,0x37(%eax)
  101733:	66 c7 45 f2 30 00    	movw   $0x30,-0xe(%ebp)
}

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  101739:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
  10173d:	0f 00 d8             	ltr    %ax
	ltr(CPU_GDT_TSS);
}
  101740:	83 c4 14             	add    $0x14,%esp
  101743:	5b                   	pop    %ebx
  101744:	5d                   	pop    %ebp
  101745:	c3                   	ret    

00101746 <cpu_alloc>:

// Allocate an additional cpu struct representing a non-bootstrap processor.
cpu *
cpu_alloc(void)
{
  101746:	55                   	push   %ebp
  101747:	89 e5                	mov    %esp,%ebp
  101749:	83 ec 28             	sub    $0x28,%esp
	// Pointer to the cpu.next pointer of the last CPU on the list,
	// for chaining on new CPUs in cpu_alloc().  Note: static.
	static cpu **cpu_tail = &cpu_boot.next;

	pageinfo *pi = mem_alloc();
  10174c:	e8 7a f8 ff ff       	call   100fcb <mem_alloc>
  101751:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert(pi != 0);	// shouldn't be out of memory just yet!
  101754:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  101758:	75 24                	jne    10177e <cpu_alloc+0x38>
  10175a:	c7 44 24 0c 23 a6 10 	movl   $0x10a623,0xc(%esp)
  101761:	00 
  101762:	c7 44 24 08 01 a6 10 	movl   $0x10a601,0x8(%esp)
  101769:	00 
  10176a:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  101771:	00 
  101772:	c7 04 24 2b a6 10 00 	movl   $0x10a62b,(%esp)
  101779:	e8 ba f1 ff ff       	call   100938 <debug_panic>

	cpu *c = (cpu*) mem_pi2ptr(pi);
  10177e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101781:	a1 50 8f 38 00       	mov    0x388f50,%eax
  101786:	89 d1                	mov    %edx,%ecx
  101788:	29 c1                	sub    %eax,%ecx
  10178a:	89 c8                	mov    %ecx,%eax
  10178c:	c1 f8 03             	sar    $0x3,%eax
  10178f:	c1 e0 0c             	shl    $0xc,%eax
  101792:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// Clear the whole page for good measure: cpu struct and kernel stack
	memset(c, 0, PAGESIZE);
  101795:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10179c:	00 
  10179d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1017a4:	00 
  1017a5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1017a8:	89 04 24             	mov    %eax,(%esp)
  1017ab:	e8 91 84 00 00       	call   109c41 <memset>
	// when it starts up and calls cpu_init().

	// Initialize the new cpu's GDT by copying from the cpu_boot.
	// The TSS descriptor will be filled in later by cpu_init().
	assert(sizeof(c->gdt) == sizeof(segdesc) * CPU_GDT_NDESC);
	memmove(c->gdt, cpu_boot.gdt, sizeof(c->gdt));
  1017b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1017b3:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  1017ba:	00 
  1017bb:	c7 44 24 04 00 f0 10 	movl   $0x10f000,0x4(%esp)
  1017c2:	00 
  1017c3:	89 04 24             	mov    %eax,(%esp)
  1017c6:	e8 e4 84 00 00       	call   109caf <memmove>

	// Magic verification tag for stack overflow/cpu corruption checking
	c->magic = CPU_MAGIC;
  1017cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1017ce:	c7 80 b8 00 00 00 32 	movl   $0x98765432,0xb8(%eax)
  1017d5:	54 76 98 

	// Chain the new CPU onto the tail of the list.
	*cpu_tail = c;
  1017d8:	a1 00 00 11 00       	mov    0x110000,%eax
  1017dd:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1017e0:	89 10                	mov    %edx,(%eax)
	cpu_tail = &c->next;
  1017e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1017e5:	05 a8 00 00 00       	add    $0xa8,%eax
  1017ea:	a3 00 00 11 00       	mov    %eax,0x110000

	return c;
  1017ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1017f2:	c9                   	leave  
  1017f3:	c3                   	ret    

001017f4 <cpu_bootothers>:

void
cpu_bootothers(void)
{
  1017f4:	55                   	push   %ebp
  1017f5:	89 e5                	mov    %esp,%ebp
  1017f7:	83 ec 28             	sub    $0x28,%esp
	extern uint8_t _binary_obj_boot_bootother_start[],
			_binary_obj_boot_bootother_size[];

	if (!cpu_onboot()) {
  1017fa:	e8 00 fe ff ff       	call   1015ff <cpu_onboot>
  1017ff:	85 c0                	test   %eax,%eax
  101801:	75 1f                	jne    101822 <cpu_bootothers+0x2e>
		// Just inform the boot cpu we've booted.
		xchg(&cpu_cur()->booted, 1);
  101803:	e8 9d fd ff ff       	call   1015a5 <cpu_cur>
  101808:	05 b0 00 00 00       	add    $0xb0,%eax
  10180d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  101814:	00 
  101815:	89 04 24             	mov    %eax,(%esp)
  101818:	e8 63 fd ff ff       	call   101580 <xchg>
		return;
  10181d:	e9 92 00 00 00       	jmp    1018b4 <cpu_bootothers+0xc0>
	}

	// Write bootstrap code to unused memory at 0x1000.
	uint8_t *code = (uint8_t*)0x1000;
  101822:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
	memmove(code, _binary_obj_boot_bootother_start,
  101829:	b8 6a 00 00 00       	mov    $0x6a,%eax
  10182e:	89 44 24 08          	mov    %eax,0x8(%esp)
  101832:	c7 44 24 04 cf 20 18 	movl   $0x1820cf,0x4(%esp)
  101839:	00 
  10183a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10183d:	89 04 24             	mov    %eax,(%esp)
  101840:	e8 6a 84 00 00       	call   109caf <memmove>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  101845:	c7 45 f4 00 f0 10 00 	movl   $0x10f000,-0xc(%ebp)
  10184c:	eb 60                	jmp    1018ae <cpu_bootothers+0xba>
		if(c == cpu_cur())  // We''ve started already.
  10184e:	e8 52 fd ff ff       	call   1015a5 <cpu_cur>
  101853:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  101856:	74 49                	je     1018a1 <cpu_bootothers+0xad>
			continue;

		// Fill in %esp, %eip and start code on cpu.
		*(void**)(code-4) = c->kstackhi;
  101858:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10185b:	83 e8 04             	sub    $0x4,%eax
  10185e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101861:	81 c2 00 10 00 00    	add    $0x1000,%edx
  101867:	89 10                	mov    %edx,(%eax)
		*(void**)(code-8) = init;
  101869:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10186c:	83 e8 08             	sub    $0x8,%eax
  10186f:	c7 00 9a 00 10 00    	movl   $0x10009a,(%eax)
		lapic_startcpu(c->id, (uint32_t)code);
  101875:	8b 55 f0             	mov    -0x10(%ebp),%edx
  101878:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10187b:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  101882:	0f b6 c0             	movzbl %al,%eax
  101885:	89 54 24 04          	mov    %edx,0x4(%esp)
  101889:	89 04 24             	mov    %eax,(%esp)
  10188c:	e8 36 76 00 00       	call   108ec7 <lapic_startcpu>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
  101891:	90                   	nop
  101892:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101895:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
  10189b:	85 c0                	test   %eax,%eax
  10189d:	74 f3                	je     101892 <cpu_bootothers+0x9e>
  10189f:	eb 01                	jmp    1018a2 <cpu_bootothers+0xae>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
		if(c == cpu_cur())  // We''ve started already.
			continue;
  1018a1:	90                   	nop
	uint8_t *code = (uint8_t*)0x1000;
	memmove(code, _binary_obj_boot_bootother_start,
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  1018a2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1018a5:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  1018ab:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1018ae:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1018b2:	75 9a                	jne    10184e <cpu_bootothers+0x5a>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
			;
	}
}
  1018b4:	c9                   	leave  
  1018b5:	c3                   	ret    
  1018b6:	66 90                	xchg   %ax,%ax

001018b8 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1018b8:	55                   	push   %ebp
  1018b9:	89 e5                	mov    %esp,%ebp
  1018bb:	53                   	push   %ebx
  1018bc:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1018bf:	89 e3                	mov    %esp,%ebx
  1018c1:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  1018c4:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1018c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1018ca:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1018cd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1018d2:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  1018d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1018d8:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1018de:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1018e3:	74 24                	je     101909 <cpu_cur+0x51>
  1018e5:	c7 44 24 0c 40 a6 10 	movl   $0x10a640,0xc(%esp)
  1018ec:	00 
  1018ed:	c7 44 24 08 56 a6 10 	movl   $0x10a656,0x8(%esp)
  1018f4:	00 
  1018f5:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1018fc:	00 
  1018fd:	c7 04 24 6b a6 10 00 	movl   $0x10a66b,(%esp)
  101904:	e8 2f f0 ff ff       	call   100938 <debug_panic>
	return c;
  101909:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  10190c:	83 c4 24             	add    $0x24,%esp
  10190f:	5b                   	pop    %ebx
  101910:	5d                   	pop    %ebp
  101911:	c3                   	ret    

00101912 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  101912:	55                   	push   %ebp
  101913:	89 e5                	mov    %esp,%ebp
  101915:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  101918:	e8 9b ff ff ff       	call   1018b8 <cpu_cur>
  10191d:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  101922:	0f 94 c0             	sete   %al
  101925:	0f b6 c0             	movzbl %al,%eax
}
  101928:	c9                   	leave  
  101929:	c3                   	ret    

0010192a <trap_init_idt>:
};


static void
trap_init_idt(void)
{
  10192a:	55                   	push   %ebp
  10192b:	89 e5                	mov    %esp,%ebp
  10192d:	83 ec 10             	sub    $0x10,%esp
	int i;
	extern segdesc gdt[];
	for(i=0; i<=50; i++){
  101930:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  101937:	e9 c3 00 00 00       	jmp    1019ff <trap_init_idt+0xd5>
		SETGATE(idt[i], 0, CPU_GDT_KCODE, vectors[i], 0);
  10193c:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10193f:	8b 04 85 10 00 11 00 	mov    0x110010(,%eax,4),%eax
  101946:	89 c2                	mov    %eax,%edx
  101948:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10194b:	66 89 14 c5 40 44 18 	mov    %dx,0x184440(,%eax,8)
  101952:	00 
  101953:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101956:	66 c7 04 c5 42 44 18 	movw   $0x8,0x184442(,%eax,8)
  10195d:	00 08 00 
  101960:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101963:	0f b6 14 c5 44 44 18 	movzbl 0x184444(,%eax,8),%edx
  10196a:	00 
  10196b:	83 e2 e0             	and    $0xffffffe0,%edx
  10196e:	88 14 c5 44 44 18 00 	mov    %dl,0x184444(,%eax,8)
  101975:	8b 45 fc             	mov    -0x4(%ebp),%eax
  101978:	0f b6 14 c5 44 44 18 	movzbl 0x184444(,%eax,8),%edx
  10197f:	00 
  101980:	83 e2 1f             	and    $0x1f,%edx
  101983:	88 14 c5 44 44 18 00 	mov    %dl,0x184444(,%eax,8)
  10198a:	8b 45 fc             	mov    -0x4(%ebp),%eax
  10198d:	0f b6 14 c5 45 44 18 	movzbl 0x184445(,%eax,8),%edx
  101994:	00 
  101995:	83 e2 f0             	and    $0xfffffff0,%edx
  101998:	83 ca 0e             	or     $0xe,%edx
  10199b:	88 14 c5 45 44 18 00 	mov    %dl,0x184445(,%eax,8)
  1019a2:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1019a5:	0f b6 14 c5 45 44 18 	movzbl 0x184445(,%eax,8),%edx
  1019ac:	00 
  1019ad:	83 e2 ef             	and    $0xffffffef,%edx
  1019b0:	88 14 c5 45 44 18 00 	mov    %dl,0x184445(,%eax,8)
  1019b7:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1019ba:	0f b6 14 c5 45 44 18 	movzbl 0x184445(,%eax,8),%edx
  1019c1:	00 
  1019c2:	83 e2 9f             	and    $0xffffff9f,%edx
  1019c5:	88 14 c5 45 44 18 00 	mov    %dl,0x184445(,%eax,8)
  1019cc:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1019cf:	0f b6 14 c5 45 44 18 	movzbl 0x184445(,%eax,8),%edx
  1019d6:	00 
  1019d7:	83 ca 80             	or     $0xffffff80,%edx
  1019da:	88 14 c5 45 44 18 00 	mov    %dl,0x184445(,%eax,8)
  1019e1:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1019e4:	8b 04 85 10 00 11 00 	mov    0x110010(,%eax,4),%eax
  1019eb:	c1 e8 10             	shr    $0x10,%eax
  1019ee:	89 c2                	mov    %eax,%edx
  1019f0:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1019f3:	66 89 14 c5 46 44 18 	mov    %dx,0x184446(,%eax,8)
  1019fa:	00 
static void
trap_init_idt(void)
{
	int i;
	extern segdesc gdt[];
	for(i=0; i<=50; i++){
  1019fb:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  1019ff:	83 7d fc 32          	cmpl   $0x32,-0x4(%ebp)
  101a03:	0f 8e 33 ff ff ff    	jle    10193c <trap_init_idt+0x12>
		SETGATE(idt[i], 0, CPU_GDT_KCODE, vectors[i], 0);
	}
	SETGATE(idt[T_BRKPT], 0,CPU_GDT_KCODE, vectors[T_BRKPT], 3);
  101a09:	a1 1c 00 11 00       	mov    0x11001c,%eax
  101a0e:	66 a3 58 44 18 00    	mov    %ax,0x184458
  101a14:	66 c7 05 5a 44 18 00 	movw   $0x8,0x18445a
  101a1b:	08 00 
  101a1d:	0f b6 05 5c 44 18 00 	movzbl 0x18445c,%eax
  101a24:	83 e0 e0             	and    $0xffffffe0,%eax
  101a27:	a2 5c 44 18 00       	mov    %al,0x18445c
  101a2c:	0f b6 05 5c 44 18 00 	movzbl 0x18445c,%eax
  101a33:	83 e0 1f             	and    $0x1f,%eax
  101a36:	a2 5c 44 18 00       	mov    %al,0x18445c
  101a3b:	0f b6 05 5d 44 18 00 	movzbl 0x18445d,%eax
  101a42:	83 e0 f0             	and    $0xfffffff0,%eax
  101a45:	83 c8 0e             	or     $0xe,%eax
  101a48:	a2 5d 44 18 00       	mov    %al,0x18445d
  101a4d:	0f b6 05 5d 44 18 00 	movzbl 0x18445d,%eax
  101a54:	83 e0 ef             	and    $0xffffffef,%eax
  101a57:	a2 5d 44 18 00       	mov    %al,0x18445d
  101a5c:	0f b6 05 5d 44 18 00 	movzbl 0x18445d,%eax
  101a63:	83 c8 60             	or     $0x60,%eax
  101a66:	a2 5d 44 18 00       	mov    %al,0x18445d
  101a6b:	0f b6 05 5d 44 18 00 	movzbl 0x18445d,%eax
  101a72:	83 c8 80             	or     $0xffffff80,%eax
  101a75:	a2 5d 44 18 00       	mov    %al,0x18445d
  101a7a:	a1 1c 00 11 00       	mov    0x11001c,%eax
  101a7f:	c1 e8 10             	shr    $0x10,%eax
  101a82:	66 a3 5e 44 18 00    	mov    %ax,0x18445e
	SETGATE(idt[T_OFLOW], 0,CPU_GDT_KCODE, vectors[T_OFLOW], 3);
  101a88:	a1 20 00 11 00       	mov    0x110020,%eax
  101a8d:	66 a3 60 44 18 00    	mov    %ax,0x184460
  101a93:	66 c7 05 62 44 18 00 	movw   $0x8,0x184462
  101a9a:	08 00 
  101a9c:	0f b6 05 64 44 18 00 	movzbl 0x184464,%eax
  101aa3:	83 e0 e0             	and    $0xffffffe0,%eax
  101aa6:	a2 64 44 18 00       	mov    %al,0x184464
  101aab:	0f b6 05 64 44 18 00 	movzbl 0x184464,%eax
  101ab2:	83 e0 1f             	and    $0x1f,%eax
  101ab5:	a2 64 44 18 00       	mov    %al,0x184464
  101aba:	0f b6 05 65 44 18 00 	movzbl 0x184465,%eax
  101ac1:	83 e0 f0             	and    $0xfffffff0,%eax
  101ac4:	83 c8 0e             	or     $0xe,%eax
  101ac7:	a2 65 44 18 00       	mov    %al,0x184465
  101acc:	0f b6 05 65 44 18 00 	movzbl 0x184465,%eax
  101ad3:	83 e0 ef             	and    $0xffffffef,%eax
  101ad6:	a2 65 44 18 00       	mov    %al,0x184465
  101adb:	0f b6 05 65 44 18 00 	movzbl 0x184465,%eax
  101ae2:	83 c8 60             	or     $0x60,%eax
  101ae5:	a2 65 44 18 00       	mov    %al,0x184465
  101aea:	0f b6 05 65 44 18 00 	movzbl 0x184465,%eax
  101af1:	83 c8 80             	or     $0xffffff80,%eax
  101af4:	a2 65 44 18 00       	mov    %al,0x184465
  101af9:	a1 20 00 11 00       	mov    0x110020,%eax
  101afe:	c1 e8 10             	shr    $0x10,%eax
  101b01:	66 a3 66 44 18 00    	mov    %ax,0x184466
	SETGATE(idt[T_SYSCALL], 0,CPU_GDT_KCODE, vectors[T_SYSCALL], 3);
  101b07:	a1 d0 00 11 00       	mov    0x1100d0,%eax
  101b0c:	66 a3 c0 45 18 00    	mov    %ax,0x1845c0
  101b12:	66 c7 05 c2 45 18 00 	movw   $0x8,0x1845c2
  101b19:	08 00 
  101b1b:	0f b6 05 c4 45 18 00 	movzbl 0x1845c4,%eax
  101b22:	83 e0 e0             	and    $0xffffffe0,%eax
  101b25:	a2 c4 45 18 00       	mov    %al,0x1845c4
  101b2a:	0f b6 05 c4 45 18 00 	movzbl 0x1845c4,%eax
  101b31:	83 e0 1f             	and    $0x1f,%eax
  101b34:	a2 c4 45 18 00       	mov    %al,0x1845c4
  101b39:	0f b6 05 c5 45 18 00 	movzbl 0x1845c5,%eax
  101b40:	83 e0 f0             	and    $0xfffffff0,%eax
  101b43:	83 c8 0e             	or     $0xe,%eax
  101b46:	a2 c5 45 18 00       	mov    %al,0x1845c5
  101b4b:	0f b6 05 c5 45 18 00 	movzbl 0x1845c5,%eax
  101b52:	83 e0 ef             	and    $0xffffffef,%eax
  101b55:	a2 c5 45 18 00       	mov    %al,0x1845c5
  101b5a:	0f b6 05 c5 45 18 00 	movzbl 0x1845c5,%eax
  101b61:	83 c8 60             	or     $0x60,%eax
  101b64:	a2 c5 45 18 00       	mov    %al,0x1845c5
  101b69:	0f b6 05 c5 45 18 00 	movzbl 0x1845c5,%eax
  101b70:	83 c8 80             	or     $0xffffff80,%eax
  101b73:	a2 c5 45 18 00       	mov    %al,0x1845c5
  101b78:	a1 d0 00 11 00       	mov    0x1100d0,%eax
  101b7d:	c1 e8 10             	shr    $0x10,%eax
  101b80:	66 a3 c6 45 18 00    	mov    %ax,0x1845c6
}
  101b86:	c9                   	leave  
  101b87:	c3                   	ret    

00101b88 <trap_init>:

void
trap_init(void)
{
  101b88:	55                   	push   %ebp
  101b89:	89 e5                	mov    %esp,%ebp
  101b8b:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  101b8e:	e8 7f fd ff ff       	call   101912 <cpu_onboot>
  101b93:	85 c0                	test   %eax,%eax
  101b95:	74 05                	je     101b9c <trap_init+0x14>
		trap_init_idt();
  101b97:	e8 8e fd ff ff       	call   10192a <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  101b9c:	0f 01 1d 04 00 11 00 	lidtl  0x110004

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  101ba3:	e8 6a fd ff ff       	call   101912 <cpu_onboot>
  101ba8:	85 c0                	test   %eax,%eax
  101baa:	74 05                	je     101bb1 <trap_init+0x29>
		trap_check_kernel();
  101bac:	e8 6d 04 00 00       	call   10201e <trap_check_kernel>
}
  101bb1:	c9                   	leave  
  101bb2:	c3                   	ret    

00101bb3 <trap_name>:

const char *trap_name(int trapno)
{
  101bb3:	55                   	push   %ebp
  101bb4:	89 e5                	mov    %esp,%ebp
		"x87 FPU Floating-Point Error",
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};
	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  101bb6:	8b 45 08             	mov    0x8(%ebp),%eax
  101bb9:	83 f8 13             	cmp    $0x13,%eax
  101bbc:	77 0c                	ja     101bca <trap_name+0x17>
		return excnames[trapno];
  101bbe:	8b 45 08             	mov    0x8(%ebp),%eax
  101bc1:	8b 04 85 40 ab 10 00 	mov    0x10ab40(,%eax,4),%eax
  101bc8:	eb 25                	jmp    101bef <trap_name+0x3c>
	if (trapno == T_SYSCALL)
  101bca:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  101bce:	75 07                	jne    101bd7 <trap_name+0x24>
		return "System call";
  101bd0:	b8 78 a6 10 00       	mov    $0x10a678,%eax
  101bd5:	eb 18                	jmp    101bef <trap_name+0x3c>
	if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16)
  101bd7:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  101bdb:	7e 0d                	jle    101bea <trap_name+0x37>
  101bdd:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  101be1:	7f 07                	jg     101bea <trap_name+0x37>
		return "Hardware Interrupt";
  101be3:	b8 84 a6 10 00       	mov    $0x10a684,%eax
  101be8:	eb 05                	jmp    101bef <trap_name+0x3c>
	return "(unknown trap)";
  101bea:	b8 97 a6 10 00       	mov    $0x10a697,%eax
}
  101bef:	5d                   	pop    %ebp
  101bf0:	c3                   	ret    

00101bf1 <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  101bf1:	55                   	push   %ebp
  101bf2:	89 e5                	mov    %esp,%ebp
  101bf4:	83 ec 18             	sub    $0x18,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  101bf7:	8b 45 08             	mov    0x8(%ebp),%eax
  101bfa:	8b 00                	mov    (%eax),%eax
  101bfc:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c00:	c7 04 24 a6 a6 10 00 	movl   $0x10a6a6,(%esp)
  101c07:	e8 c4 7c 00 00       	call   1098d0 <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  101c0c:	8b 45 08             	mov    0x8(%ebp),%eax
  101c0f:	8b 40 04             	mov    0x4(%eax),%eax
  101c12:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c16:	c7 04 24 b5 a6 10 00 	movl   $0x10a6b5,(%esp)
  101c1d:	e8 ae 7c 00 00       	call   1098d0 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  101c22:	8b 45 08             	mov    0x8(%ebp),%eax
  101c25:	8b 40 08             	mov    0x8(%eax),%eax
  101c28:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c2c:	c7 04 24 c4 a6 10 00 	movl   $0x10a6c4,(%esp)
  101c33:	e8 98 7c 00 00       	call   1098d0 <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  101c38:	8b 45 08             	mov    0x8(%ebp),%eax
  101c3b:	8b 40 10             	mov    0x10(%eax),%eax
  101c3e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c42:	c7 04 24 d3 a6 10 00 	movl   $0x10a6d3,(%esp)
  101c49:	e8 82 7c 00 00       	call   1098d0 <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  101c4e:	8b 45 08             	mov    0x8(%ebp),%eax
  101c51:	8b 40 14             	mov    0x14(%eax),%eax
  101c54:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c58:	c7 04 24 e2 a6 10 00 	movl   $0x10a6e2,(%esp)
  101c5f:	e8 6c 7c 00 00       	call   1098d0 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  101c64:	8b 45 08             	mov    0x8(%ebp),%eax
  101c67:	8b 40 18             	mov    0x18(%eax),%eax
  101c6a:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c6e:	c7 04 24 f1 a6 10 00 	movl   $0x10a6f1,(%esp)
  101c75:	e8 56 7c 00 00       	call   1098d0 <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  101c7a:	8b 45 08             	mov    0x8(%ebp),%eax
  101c7d:	8b 40 1c             	mov    0x1c(%eax),%eax
  101c80:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c84:	c7 04 24 00 a7 10 00 	movl   $0x10a700,(%esp)
  101c8b:	e8 40 7c 00 00       	call   1098d0 <cprintf>
}
  101c90:	c9                   	leave  
  101c91:	c3                   	ret    

00101c92 <trap_print>:

void
trap_print(trapframe *tf)
{
  101c92:	55                   	push   %ebp
  101c93:	89 e5                	mov    %esp,%ebp
  101c95:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  101c98:	8b 45 08             	mov    0x8(%ebp),%eax
  101c9b:	89 44 24 04          	mov    %eax,0x4(%esp)
  101c9f:	c7 04 24 0f a7 10 00 	movl   $0x10a70f,(%esp)
  101ca6:	e8 25 7c 00 00       	call   1098d0 <cprintf>
	trap_print_regs(&tf->regs);
  101cab:	8b 45 08             	mov    0x8(%ebp),%eax
  101cae:	89 04 24             	mov    %eax,(%esp)
  101cb1:	e8 3b ff ff ff       	call   101bf1 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  101cb6:	8b 45 08             	mov    0x8(%ebp),%eax
  101cb9:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  101cbd:	0f b7 c0             	movzwl %ax,%eax
  101cc0:	89 44 24 04          	mov    %eax,0x4(%esp)
  101cc4:	c7 04 24 21 a7 10 00 	movl   $0x10a721,(%esp)
  101ccb:	e8 00 7c 00 00       	call   1098d0 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  101cd0:	8b 45 08             	mov    0x8(%ebp),%eax
  101cd3:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  101cd7:	0f b7 c0             	movzwl %ax,%eax
  101cda:	89 44 24 04          	mov    %eax,0x4(%esp)
  101cde:	c7 04 24 34 a7 10 00 	movl   $0x10a734,(%esp)
  101ce5:	e8 e6 7b 00 00       	call   1098d0 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  101cea:	8b 45 08             	mov    0x8(%ebp),%eax
  101ced:	8b 40 30             	mov    0x30(%eax),%eax
  101cf0:	89 04 24             	mov    %eax,(%esp)
  101cf3:	e8 bb fe ff ff       	call   101bb3 <trap_name>
  101cf8:	8b 55 08             	mov    0x8(%ebp),%edx
  101cfb:	8b 52 30             	mov    0x30(%edx),%edx
  101cfe:	89 44 24 08          	mov    %eax,0x8(%esp)
  101d02:	89 54 24 04          	mov    %edx,0x4(%esp)
  101d06:	c7 04 24 47 a7 10 00 	movl   $0x10a747,(%esp)
  101d0d:	e8 be 7b 00 00       	call   1098d0 <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  101d12:	8b 45 08             	mov    0x8(%ebp),%eax
  101d15:	8b 40 34             	mov    0x34(%eax),%eax
  101d18:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d1c:	c7 04 24 59 a7 10 00 	movl   $0x10a759,(%esp)
  101d23:	e8 a8 7b 00 00       	call   1098d0 <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  101d28:	8b 45 08             	mov    0x8(%ebp),%eax
  101d2b:	8b 40 38             	mov    0x38(%eax),%eax
  101d2e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d32:	c7 04 24 68 a7 10 00 	movl   $0x10a768,(%esp)
  101d39:	e8 92 7b 00 00       	call   1098d0 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  101d3e:	8b 45 08             	mov    0x8(%ebp),%eax
  101d41:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101d45:	0f b7 c0             	movzwl %ax,%eax
  101d48:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d4c:	c7 04 24 77 a7 10 00 	movl   $0x10a777,(%esp)
  101d53:	e8 78 7b 00 00       	call   1098d0 <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  101d58:	8b 45 08             	mov    0x8(%ebp),%eax
  101d5b:	8b 40 40             	mov    0x40(%eax),%eax
  101d5e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d62:	c7 04 24 8a a7 10 00 	movl   $0x10a78a,(%esp)
  101d69:	e8 62 7b 00 00       	call   1098d0 <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  101d6e:	8b 45 08             	mov    0x8(%ebp),%eax
  101d71:	8b 40 44             	mov    0x44(%eax),%eax
  101d74:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d78:	c7 04 24 99 a7 10 00 	movl   $0x10a799,(%esp)
  101d7f:	e8 4c 7b 00 00       	call   1098d0 <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  101d84:	8b 45 08             	mov    0x8(%ebp),%eax
  101d87:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  101d8b:	0f b7 c0             	movzwl %ax,%eax
  101d8e:	89 44 24 04          	mov    %eax,0x4(%esp)
  101d92:	c7 04 24 a8 a7 10 00 	movl   $0x10a7a8,(%esp)
  101d99:	e8 32 7b 00 00       	call   1098d0 <cprintf>
}
  101d9e:	c9                   	leave  
  101d9f:	c3                   	ret    

00101da0 <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  101da0:	55                   	push   %ebp
  101da1:	89 e5                	mov    %esp,%ebp
  101da3:	53                   	push   %ebx
  101da4:	83 ec 24             	sub    $0x24,%esp
		// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  101da7:	fc                   	cld    

	// If this is a page fault, first handle lazy copying automatically.
	// If that works, this call just calls trap_return() itself -
	// otherwise, it returns normally to blame the fault on the user.
	if (tf->trapno == T_PGFLT)
  101da8:	8b 45 08             	mov    0x8(%ebp),%eax
  101dab:	8b 40 30             	mov    0x30(%eax),%eax
  101dae:	83 f8 0e             	cmp    $0xe,%eax
  101db1:	75 0b                	jne    101dbe <trap+0x1e>
		pmap_pagefault(tf);
  101db3:	8b 45 08             	mov    0x8(%ebp),%eax
  101db6:	89 04 24             	mov    %eax,(%esp)
  101db9:	e8 e5 3d 00 00       	call   105ba3 <pmap_pagefault>

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  101dbe:	e8 f5 fa ff ff       	call   1018b8 <cpu_cur>
  101dc3:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (c->recover)
  101dc6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101dc9:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  101dcf:	85 c0                	test   %eax,%eax
  101dd1:	74 1e                	je     101df1 <trap+0x51>
		c->recover(tf, c->recoverdata);
  101dd3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101dd6:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  101ddc:	8b 55 f4             	mov    -0xc(%ebp),%edx
  101ddf:	8b 92 a4 00 00 00    	mov    0xa4(%edx),%edx
  101de5:	89 54 24 04          	mov    %edx,0x4(%esp)
  101de9:	8b 55 08             	mov    0x8(%ebp),%edx
  101dec:	89 14 24             	mov    %edx,(%esp)
  101def:	ff d0                	call   *%eax

	proc *p = proc_cur();
  101df1:	e8 c2 fa ff ff       	call   1018b8 <cpu_cur>
  101df6:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  101dfc:	89 45 f0             	mov    %eax,-0x10(%ebp)
	switch (tf->trapno) {
  101dff:	8b 45 08             	mov    0x8(%ebp),%eax
  101e02:	8b 40 30             	mov    0x30(%eax),%eax
  101e05:	83 e8 03             	sub    $0x3,%eax
  101e08:	83 f8 2f             	cmp    $0x2f,%eax
  101e0b:	0f 87 3c 01 00 00    	ja     101f4d <trap+0x1ad>
  101e11:	8b 04 85 30 a8 10 00 	mov    0x10a830(,%eax,4),%eax
  101e18:	ff e0                	jmp    *%eax
	case T_SYSCALL:
		assert(tf->cs & 3);	// syscalls only come from user space
  101e1a:	8b 45 08             	mov    0x8(%ebp),%eax
  101e1d:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101e21:	0f b7 c0             	movzwl %ax,%eax
  101e24:	83 e0 03             	and    $0x3,%eax
  101e27:	85 c0                	test   %eax,%eax
  101e29:	75 24                	jne    101e4f <trap+0xaf>
  101e2b:	c7 44 24 0c bb a7 10 	movl   $0x10a7bb,0xc(%esp)
  101e32:	00 
  101e33:	c7 44 24 08 56 a6 10 	movl   $0x10a656,0x8(%esp)
  101e3a:	00 
  101e3b:	c7 44 24 04 99 00 00 	movl   $0x99,0x4(%esp)
  101e42:	00 
  101e43:	c7 04 24 c6 a7 10 00 	movl   $0x10a7c6,(%esp)
  101e4a:	e8 e9 ea ff ff       	call   100938 <debug_panic>
		syscall(tf);
  101e4f:	8b 45 08             	mov    0x8(%ebp),%eax
  101e52:	89 04 24             	mov    %eax,(%esp)
  101e55:	e8 2c 29 00 00       	call   104786 <syscall>
		break;
  101e5a:	e9 ee 00 00 00       	jmp    101f4d <trap+0x1ad>
	case T_BRKPT:
		break;// other traps entered via explicit INT instructions
	case T_OFLOW:
		assert(tf->cs & 3);	// only allowed from user space
  101e5f:	8b 45 08             	mov    0x8(%ebp),%eax
  101e62:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101e66:	0f b7 c0             	movzwl %ax,%eax
  101e69:	83 e0 03             	and    $0x3,%eax
  101e6c:	85 c0                	test   %eax,%eax
  101e6e:	75 24                	jne    101e94 <trap+0xf4>
  101e70:	c7 44 24 0c bb a7 10 	movl   $0x10a7bb,0xc(%esp)
  101e77:	00 
  101e78:	c7 44 24 08 56 a6 10 	movl   $0x10a656,0x8(%esp)
  101e7f:	00 
  101e80:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
  101e87:	00 
  101e88:	c7 04 24 c6 a7 10 00 	movl   $0x10a7c6,(%esp)
  101e8f:	e8 a4 ea ff ff       	call   100938 <debug_panic>
		proc_ret(tf, 1);	// reflect trap to parent process
  101e94:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  101e9b:	00 
  101e9c:	8b 45 08             	mov    0x8(%ebp),%eax
  101e9f:	89 04 24             	mov    %eax,(%esp)
  101ea2:	e8 da 16 00 00       	call   103581 <proc_ret>
		break;
	case T_LTIMER: ;
		lapic_eoi();
  101ea7:	e8 8c 6f 00 00       	call   108e38 <lapic_eoi>
		if (tf->cs & 3)	// If in user mode, context switch
  101eac:	8b 45 08             	mov    0x8(%ebp),%eax
  101eaf:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101eb3:	0f b7 c0             	movzwl %ax,%eax
  101eb6:	83 e0 03             	and    $0x3,%eax
  101eb9:	85 c0                	test   %eax,%eax
  101ebb:	74 0b                	je     101ec8 <trap+0x128>
			proc_yield(tf);
  101ebd:	8b 45 08             	mov    0x8(%ebp),%eax
  101ec0:	89 04 24             	mov    %eax,(%esp)
  101ec3:	e8 79 16 00 00       	call   103541 <proc_yield>
		trap_return(tf);	// Otherwise, stay in idle loop
  101ec8:	8b 45 08             	mov    0x8(%ebp),%eax
  101ecb:	89 04 24             	mov    %eax,(%esp)
  101ece:	e8 2d e2 00 00       	call   110100 <trap_return>
	case T_LERROR:
		lapic_errintr();
  101ed3:	e8 85 6f 00 00       	call   108e5d <lapic_errintr>
		trap_return(tf);
  101ed8:	8b 45 08             	mov    0x8(%ebp),%eax
  101edb:	89 04 24             	mov    %eax,(%esp)
  101ede:	e8 1d e2 00 00       	call   110100 <trap_return>
	case T_IRQ0 + IRQ_KBD:
		//cprintf("CPU%d: KBD\n", c->id);
		kbd_intr();
  101ee3:	e8 2a 68 00 00       	call   108712 <kbd_intr>
		lapic_eoi();
  101ee8:	e8 4b 6f 00 00       	call   108e38 <lapic_eoi>
		trap_return(tf);
  101eed:	8b 45 08             	mov    0x8(%ebp),%eax
  101ef0:	89 04 24             	mov    %eax,(%esp)
  101ef3:	e8 08 e2 00 00       	call   110100 <trap_return>
	case T_IRQ0 + IRQ_SERIAL:
		serial_intr();
  101ef8:	e8 0d 69 00 00       	call   10880a <serial_intr>
		lapic_eoi();
  101efd:	e8 36 6f 00 00       	call   108e38 <lapic_eoi>
		trap_return(tf);
  101f02:	8b 45 08             	mov    0x8(%ebp),%eax
  101f05:	89 04 24             	mov    %eax,(%esp)
  101f08:	e8 f3 e1 00 00       	call   110100 <trap_return>
	case T_IRQ0 + IRQ_SPURIOUS:
		cprintf("cpu%d: spurious interrupt at %x:%x\n",
			c->id, tf->cs, tf->eip);
  101f0d:	8b 45 08             	mov    0x8(%ebp),%eax
	case T_IRQ0 + IRQ_SERIAL:
		serial_intr();
		lapic_eoi();
		trap_return(tf);
	case T_IRQ0 + IRQ_SPURIOUS:
		cprintf("cpu%d: spurious interrupt at %x:%x\n",
  101f10:	8b 48 38             	mov    0x38(%eax),%ecx
			c->id, tf->cs, tf->eip);
  101f13:	8b 45 08             	mov    0x8(%ebp),%eax
  101f16:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
	case T_IRQ0 + IRQ_SERIAL:
		serial_intr();
		lapic_eoi();
		trap_return(tf);
	case T_IRQ0 + IRQ_SPURIOUS:
		cprintf("cpu%d: spurious interrupt at %x:%x\n",
  101f1a:	0f b7 d0             	movzwl %ax,%edx
			c->id, tf->cs, tf->eip);
  101f1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101f20:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
	case T_IRQ0 + IRQ_SERIAL:
		serial_intr();
		lapic_eoi();
		trap_return(tf);
	case T_IRQ0 + IRQ_SPURIOUS:
		cprintf("cpu%d: spurious interrupt at %x:%x\n",
  101f27:	0f b6 c0             	movzbl %al,%eax
  101f2a:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  101f2e:	89 54 24 08          	mov    %edx,0x8(%esp)
  101f32:	89 44 24 04          	mov    %eax,0x4(%esp)
  101f36:	c7 04 24 d4 a7 10 00 	movl   $0x10a7d4,(%esp)
  101f3d:	e8 8e 79 00 00       	call   1098d0 <cprintf>
			c->id, tf->cs, tf->eip);
		trap_return(tf); // Note: no EOI (see Local APIC manual)
  101f42:	8b 45 08             	mov    0x8(%ebp),%eax
  101f45:	89 04 24             	mov    %eax,(%esp)
  101f48:	e8 b3 e1 00 00       	call   110100 <trap_return>
		break;
	}
	if (tf->cs & 3) {		// Unhandled trap from user mode
  101f4d:	8b 45 08             	mov    0x8(%ebp),%eax
  101f50:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  101f54:	0f b7 c0             	movzwl %ax,%eax
  101f57:	83 e0 03             	and    $0x3,%eax
  101f5a:	85 c0                	test   %eax,%eax
  101f5c:	74 4b                	je     101fa9 <trap+0x209>
		cprintf("trap in proc %x, reflecting to proc %x\n",
			proc_cur(), proc_cur()->parent);
  101f5e:	e8 55 f9 ff ff       	call   1018b8 <cpu_cur>
  101f63:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
			c->id, tf->cs, tf->eip);
		trap_return(tf); // Note: no EOI (see Local APIC manual)
		break;
	}
	if (tf->cs & 3) {		// Unhandled trap from user mode
		cprintf("trap in proc %x, reflecting to proc %x\n",
  101f69:	8b 58 38             	mov    0x38(%eax),%ebx
			proc_cur(), proc_cur()->parent);
  101f6c:	e8 47 f9 ff ff       	call   1018b8 <cpu_cur>
			c->id, tf->cs, tf->eip);
		trap_return(tf); // Note: no EOI (see Local APIC manual)
		break;
	}
	if (tf->cs & 3) {		// Unhandled trap from user mode
		cprintf("trap in proc %x, reflecting to proc %x\n",
  101f71:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  101f77:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  101f7b:	89 44 24 04          	mov    %eax,0x4(%esp)
  101f7f:	c7 04 24 f8 a7 10 00 	movl   $0x10a7f8,(%esp)
  101f86:	e8 45 79 00 00       	call   1098d0 <cprintf>
			proc_cur(), proc_cur()->parent);
		trap_print(tf);
  101f8b:	8b 45 08             	mov    0x8(%ebp),%eax
  101f8e:	89 04 24             	mov    %eax,(%esp)
  101f91:	e8 fc fc ff ff       	call   101c92 <trap_print>
		proc_ret(tf, -1);	// Reflect trap to parent process
  101f96:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  101f9d:	ff 
  101f9e:	8b 45 08             	mov    0x8(%ebp),%eax
  101fa1:	89 04 24             	mov    %eax,(%esp)
  101fa4:	e8 d8 15 00 00       	call   103581 <proc_ret>
	}

	// If we panic while holding the console lock,
	// release it so we don't get into a recursive panic that way.
	if (spinlock_holding(&cons_lock))
  101fa9:	c7 04 24 00 8f 18 00 	movl   $0x188f00,(%esp)
  101fb0:	e8 0b 0b 00 00       	call   102ac0 <spinlock_holding>
  101fb5:	85 c0                	test   %eax,%eax
  101fb7:	74 0c                	je     101fc5 <trap+0x225>
		spinlock_release(&cons_lock);
  101fb9:	c7 04 24 00 8f 18 00 	movl   $0x188f00,(%esp)
  101fc0:	e8 a1 0a 00 00       	call   102a66 <spinlock_release>
	trap_print(tf);
  101fc5:	8b 45 08             	mov    0x8(%ebp),%eax
  101fc8:	89 04 24             	mov    %eax,(%esp)
  101fcb:	e8 c2 fc ff ff       	call   101c92 <trap_print>
	panic("unhandled trap");
  101fd0:	c7 44 24 08 20 a8 10 	movl   $0x10a820,0x8(%esp)
  101fd7:	00 
  101fd8:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
  101fdf:	00 
  101fe0:	c7 04 24 c6 a7 10 00 	movl   $0x10a7c6,(%esp)
  101fe7:	e8 4c e9 ff ff       	call   100938 <debug_panic>

00101fec <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  101fec:	55                   	push   %ebp
  101fed:	89 e5                	mov    %esp,%ebp
  101fef:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  101ff2:	8b 45 0c             	mov    0xc(%ebp),%eax
  101ff5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  101ff8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101ffb:	8b 00                	mov    (%eax),%eax
  101ffd:	89 c2                	mov    %eax,%edx
  101fff:	8b 45 08             	mov    0x8(%ebp),%eax
  102002:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  102005:	8b 45 08             	mov    0x8(%ebp),%eax
  102008:	8b 40 30             	mov    0x30(%eax),%eax
  10200b:	89 c2                	mov    %eax,%edx
  10200d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102010:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  102013:	8b 45 08             	mov    0x8(%ebp),%eax
  102016:	89 04 24             	mov    %eax,(%esp)
  102019:	e8 e2 e0 00 00       	call   110100 <trap_return>

0010201e <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  10201e:	55                   	push   %ebp
  10201f:	89 e5                	mov    %esp,%ebp
  102021:	53                   	push   %ebx
  102022:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  102025:	66 8c cb             	mov    %cs,%bx
  102028:	66 89 5d f2          	mov    %bx,-0xe(%ebp)
        return cs;
  10202c:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  102030:	0f b7 c0             	movzwl %ax,%eax
  102033:	83 e0 03             	and    $0x3,%eax
  102036:	85 c0                	test   %eax,%eax
  102038:	74 24                	je     10205e <trap_check_kernel+0x40>
  10203a:	c7 44 24 0c f0 a8 10 	movl   $0x10a8f0,0xc(%esp)
  102041:	00 
  102042:	c7 44 24 08 56 a6 10 	movl   $0x10a656,0x8(%esp)
  102049:	00 
  10204a:	c7 44 24 04 d9 00 00 	movl   $0xd9,0x4(%esp)
  102051:	00 
  102052:	c7 04 24 c6 a7 10 00 	movl   $0x10a7c6,(%esp)
  102059:	e8 da e8 ff ff       	call   100938 <debug_panic>

	cpu *c = cpu_cur();
  10205e:	e8 55 f8 ff ff       	call   1018b8 <cpu_cur>
  102063:	89 45 f4             	mov    %eax,-0xc(%ebp)
	c->recover = trap_check_recover;
  102066:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102069:	c7 80 a0 00 00 00 ec 	movl   $0x101fec,0xa0(%eax)
  102070:	1f 10 00 
	trap_check(&c->recoverdata);
  102073:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102076:	05 a4 00 00 00       	add    $0xa4,%eax
  10207b:	89 04 24             	mov    %eax,(%esp)
  10207e:	e8 a3 00 00 00       	call   102126 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  102083:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102086:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  10208d:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  102090:	c7 04 24 08 a9 10 00 	movl   $0x10a908,(%esp)
  102097:	e8 34 78 00 00       	call   1098d0 <cprintf>
}
  10209c:	83 c4 24             	add    $0x24,%esp
  10209f:	5b                   	pop    %ebx
  1020a0:	5d                   	pop    %ebp
  1020a1:	c3                   	ret    

001020a2 <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  1020a2:	55                   	push   %ebp
  1020a3:	89 e5                	mov    %esp,%ebp
  1020a5:	53                   	push   %ebx
  1020a6:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1020a9:	66 8c cb             	mov    %cs,%bx
  1020ac:	66 89 5d f2          	mov    %bx,-0xe(%ebp)
        return cs;
  1020b0:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  1020b4:	0f b7 c0             	movzwl %ax,%eax
  1020b7:	83 e0 03             	and    $0x3,%eax
  1020ba:	83 f8 03             	cmp    $0x3,%eax
  1020bd:	74 24                	je     1020e3 <trap_check_user+0x41>
  1020bf:	c7 44 24 0c 28 a9 10 	movl   $0x10a928,0xc(%esp)
  1020c6:	00 
  1020c7:	c7 44 24 08 56 a6 10 	movl   $0x10a656,0x8(%esp)
  1020ce:	00 
  1020cf:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
  1020d6:	00 
  1020d7:	c7 04 24 c6 a7 10 00 	movl   $0x10a7c6,(%esp)
  1020de:	e8 55 e8 ff ff       	call   100938 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  1020e3:	c7 45 f4 00 f0 10 00 	movl   $0x10f000,-0xc(%ebp)
	c->recover = trap_check_recover;
  1020ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1020ed:	c7 80 a0 00 00 00 ec 	movl   $0x101fec,0xa0(%eax)
  1020f4:	1f 10 00 
	trap_check(&c->recoverdata);
  1020f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1020fa:	05 a4 00 00 00       	add    $0xa4,%eax
  1020ff:	89 04 24             	mov    %eax,(%esp)
  102102:	e8 1f 00 00 00       	call   102126 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  102107:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10210a:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  102111:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  102114:	c7 04 24 3d a9 10 00 	movl   $0x10a93d,(%esp)
  10211b:	e8 b0 77 00 00       	call   1098d0 <cprintf>
}
  102120:	83 c4 24             	add    $0x24,%esp
  102123:	5b                   	pop    %ebx
  102124:	5d                   	pop    %ebp
  102125:	c3                   	ret    

00102126 <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  102126:	55                   	push   %ebp
  102127:	89 e5                	mov    %esp,%ebp
  102129:	57                   	push   %edi
  10212a:	56                   	push   %esi
  10212b:	53                   	push   %ebx
  10212c:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  10212f:	c7 45 e0 ce fa ed fe 	movl   $0xfeedface,-0x20(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  102136:	8b 45 08             	mov    0x8(%ebp),%eax
  102139:	8d 55 d8             	lea    -0x28(%ebp),%edx
  10213c:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  10213e:	c7 45 d8 4c 21 10 00 	movl   $0x10214c,-0x28(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  102145:	b8 00 00 00 00       	mov    $0x0,%eax
  10214a:	f7 f0                	div    %eax

0010214c <after_div0>:
	assert(args.trapno == T_DIVIDE);
  10214c:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10214f:	85 c0                	test   %eax,%eax
  102151:	74 24                	je     102177 <after_div0+0x2b>
  102153:	c7 44 24 0c 5b a9 10 	movl   $0x10a95b,0xc(%esp)
  10215a:	00 
  10215b:	c7 44 24 08 56 a6 10 	movl   $0x10a656,0x8(%esp)
  102162:	00 
  102163:	c7 44 24 04 0a 01 00 	movl   $0x10a,0x4(%esp)
  10216a:	00 
  10216b:	c7 04 24 c6 a7 10 00 	movl   $0x10a7c6,(%esp)
  102172:	e8 c1 e7 ff ff       	call   100938 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  102177:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10217a:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  10217f:	74 24                	je     1021a5 <after_div0+0x59>
  102181:	c7 44 24 0c 73 a9 10 	movl   $0x10a973,0xc(%esp)
  102188:	00 
  102189:	c7 44 24 08 56 a6 10 	movl   $0x10a656,0x8(%esp)
  102190:	00 
  102191:	c7 44 24 04 0f 01 00 	movl   $0x10f,0x4(%esp)
  102198:	00 
  102199:	c7 04 24 c6 a7 10 00 	movl   $0x10a7c6,(%esp)
  1021a0:	e8 93 e7 ff ff       	call   100938 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  1021a5:	c7 45 d8 ad 21 10 00 	movl   $0x1021ad,-0x28(%ebp)
	asm volatile("int3; after_breakpoint:");
  1021ac:	cc                   	int3   

001021ad <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  1021ad:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1021b0:	83 f8 03             	cmp    $0x3,%eax
  1021b3:	74 24                	je     1021d9 <after_breakpoint+0x2c>
  1021b5:	c7 44 24 0c 88 a9 10 	movl   $0x10a988,0xc(%esp)
  1021bc:	00 
  1021bd:	c7 44 24 08 56 a6 10 	movl   $0x10a656,0x8(%esp)
  1021c4:	00 
  1021c5:	c7 44 24 04 14 01 00 	movl   $0x114,0x4(%esp)
  1021cc:	00 
  1021cd:	c7 04 24 c6 a7 10 00 	movl   $0x10a7c6,(%esp)
  1021d4:	e8 5f e7 ff ff       	call   100938 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  1021d9:	c7 45 d8 e8 21 10 00 	movl   $0x1021e8,-0x28(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  1021e0:	b8 00 00 00 70       	mov    $0x70000000,%eax
  1021e5:	01 c0                	add    %eax,%eax
  1021e7:	ce                   	into   

001021e8 <after_overflow>:
	assert(args.trapno == T_OFLOW);
  1021e8:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1021eb:	83 f8 04             	cmp    $0x4,%eax
  1021ee:	74 24                	je     102214 <after_overflow+0x2c>
  1021f0:	c7 44 24 0c 9f a9 10 	movl   $0x10a99f,0xc(%esp)
  1021f7:	00 
  1021f8:	c7 44 24 08 56 a6 10 	movl   $0x10a656,0x8(%esp)
  1021ff:	00 
  102200:	c7 44 24 04 19 01 00 	movl   $0x119,0x4(%esp)
  102207:	00 
  102208:	c7 04 24 c6 a7 10 00 	movl   $0x10a7c6,(%esp)
  10220f:	e8 24 e7 ff ff       	call   100938 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  102214:	c7 45 d8 31 22 10 00 	movl   $0x102231,-0x28(%ebp)
	int bounds[2] = { 1, 3 };
  10221b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  102222:	c7 45 d4 03 00 00 00 	movl   $0x3,-0x2c(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  102229:	b8 00 00 00 00       	mov    $0x0,%eax
  10222e:	62 45 d0             	bound  %eax,-0x30(%ebp)

00102231 <after_bound>:
	assert(args.trapno == T_BOUND);
  102231:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102234:	83 f8 05             	cmp    $0x5,%eax
  102237:	74 24                	je     10225d <after_bound+0x2c>
  102239:	c7 44 24 0c b6 a9 10 	movl   $0x10a9b6,0xc(%esp)
  102240:	00 
  102241:	c7 44 24 08 56 a6 10 	movl   $0x10a656,0x8(%esp)
  102248:	00 
  102249:	c7 44 24 04 1f 01 00 	movl   $0x11f,0x4(%esp)
  102250:	00 
  102251:	c7 04 24 c6 a7 10 00 	movl   $0x10a7c6,(%esp)
  102258:	e8 db e6 ff ff       	call   100938 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  10225d:	c7 45 d8 66 22 10 00 	movl   $0x102266,-0x28(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  102264:	0f 0b                	ud2    

00102266 <after_illegal>:
	assert(args.trapno == T_ILLOP);
  102266:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102269:	83 f8 06             	cmp    $0x6,%eax
  10226c:	74 24                	je     102292 <after_illegal+0x2c>
  10226e:	c7 44 24 0c cd a9 10 	movl   $0x10a9cd,0xc(%esp)
  102275:	00 
  102276:	c7 44 24 08 56 a6 10 	movl   $0x10a656,0x8(%esp)
  10227d:	00 
  10227e:	c7 44 24 04 24 01 00 	movl   $0x124,0x4(%esp)
  102285:	00 
  102286:	c7 04 24 c6 a7 10 00 	movl   $0x10a7c6,(%esp)
  10228d:	e8 a6 e6 ff ff       	call   100938 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  102292:	c7 45 d8 a0 22 10 00 	movl   $0x1022a0,-0x28(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  102299:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  10229e:	8e e0                	mov    %eax,%fs

001022a0 <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  1022a0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1022a3:	83 f8 0d             	cmp    $0xd,%eax
  1022a6:	74 24                	je     1022cc <after_gpfault+0x2c>
  1022a8:	c7 44 24 0c e4 a9 10 	movl   $0x10a9e4,0xc(%esp)
  1022af:	00 
  1022b0:	c7 44 24 08 56 a6 10 	movl   $0x10a656,0x8(%esp)
  1022b7:	00 
  1022b8:	c7 44 24 04 29 01 00 	movl   $0x129,0x4(%esp)
  1022bf:	00 
  1022c0:	c7 04 24 c6 a7 10 00 	movl   $0x10a7c6,(%esp)
  1022c7:	e8 6c e6 ff ff       	call   100938 <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1022cc:	66 8c cb             	mov    %cs,%bx
  1022cf:	66 89 5d e6          	mov    %bx,-0x1a(%ebp)
        return cs;
  1022d3:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  1022d7:	0f b7 c0             	movzwl %ax,%eax
  1022da:	83 e0 03             	and    $0x3,%eax
  1022dd:	85 c0                	test   %eax,%eax
  1022df:	74 3a                	je     10231b <after_priv+0x2c>
		args.reip = after_priv;
  1022e1:	c7 45 d8 ef 22 10 00 	movl   $0x1022ef,-0x28(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  1022e8:	0f 01 1d 04 00 11 00 	lidtl  0x110004

001022ef <after_priv>:
		assert(args.trapno == T_GPFLT);
  1022ef:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1022f2:	83 f8 0d             	cmp    $0xd,%eax
  1022f5:	74 24                	je     10231b <after_priv+0x2c>
  1022f7:	c7 44 24 0c e4 a9 10 	movl   $0x10a9e4,0xc(%esp)
  1022fe:	00 
  1022ff:	c7 44 24 08 56 a6 10 	movl   $0x10a656,0x8(%esp)
  102306:	00 
  102307:	c7 44 24 04 2f 01 00 	movl   $0x12f,0x4(%esp)
  10230e:	00 
  10230f:	c7 04 24 c6 a7 10 00 	movl   $0x10a7c6,(%esp)
  102316:	e8 1d e6 ff ff       	call   100938 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  10231b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10231e:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  102323:	74 24                	je     102349 <after_priv+0x5a>
  102325:	c7 44 24 0c 73 a9 10 	movl   $0x10a973,0xc(%esp)
  10232c:	00 
  10232d:	c7 44 24 08 56 a6 10 	movl   $0x10a656,0x8(%esp)
  102334:	00 
  102335:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
  10233c:	00 
  10233d:	c7 04 24 c6 a7 10 00 	movl   $0x10a7c6,(%esp)
  102344:	e8 ef e5 ff ff       	call   100938 <debug_panic>

	*argsp = NULL;	// recovery mechanism not needed anymore
  102349:	8b 45 08             	mov    0x8(%ebp),%eax
  10234c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  102352:	83 c4 3c             	add    $0x3c,%esp
  102355:	5b                   	pop    %ebx
  102356:	5e                   	pop    %esi
  102357:	5f                   	pop    %edi
  102358:	5d                   	pop    %ebp
  102359:	c3                   	ret    
  10235a:	66 90                	xchg   %ax,%ax

0010235c <vector0>:
.text

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(vector0, 0)
  10235c:	6a 00                	push   $0x0
  10235e:	6a 00                	push   $0x0
  102360:	e9 77 dd 00 00       	jmp    1100dc <_alltraps>
  102365:	90                   	nop

00102366 <vector1>:
TRAPHANDLER_NOEC(vector1, 1)
  102366:	6a 00                	push   $0x0
  102368:	6a 01                	push   $0x1
  10236a:	e9 6d dd 00 00       	jmp    1100dc <_alltraps>
  10236f:	90                   	nop

00102370 <vector2>:
TRAPHANDLER_NOEC(vector2,2 )
  102370:	6a 00                	push   $0x0
  102372:	6a 02                	push   $0x2
  102374:	e9 63 dd 00 00       	jmp    1100dc <_alltraps>
  102379:	90                   	nop

0010237a <vector3>:
TRAPHANDLER_NOEC(vector3,3 )
  10237a:	6a 00                	push   $0x0
  10237c:	6a 03                	push   $0x3
  10237e:	e9 59 dd 00 00       	jmp    1100dc <_alltraps>
  102383:	90                   	nop

00102384 <vector4>:
TRAPHANDLER_NOEC(vector4,4 )
  102384:	6a 00                	push   $0x0
  102386:	6a 04                	push   $0x4
  102388:	e9 4f dd 00 00       	jmp    1100dc <_alltraps>
  10238d:	90                   	nop

0010238e <vector5>:
TRAPHANDLER_NOEC(vector5,5 )
  10238e:	6a 00                	push   $0x0
  102390:	6a 05                	push   $0x5
  102392:	e9 45 dd 00 00       	jmp    1100dc <_alltraps>
  102397:	90                   	nop

00102398 <vector6>:
TRAPHANDLER_NOEC(vector6,6 )
  102398:	6a 00                	push   $0x0
  10239a:	6a 06                	push   $0x6
  10239c:	e9 3b dd 00 00       	jmp    1100dc <_alltraps>
  1023a1:	90                   	nop

001023a2 <vector7>:
TRAPHANDLER_NOEC(vector7,7 )
  1023a2:	6a 00                	push   $0x0
  1023a4:	6a 07                	push   $0x7
  1023a6:	e9 31 dd 00 00       	jmp    1100dc <_alltraps>
  1023ab:	90                   	nop

001023ac <vector8>:
TRAPHANDLER(vector8,8 )
  1023ac:	6a 08                	push   $0x8
  1023ae:	e9 29 dd 00 00       	jmp    1100dc <_alltraps>
  1023b3:	90                   	nop

001023b4 <vector9>:
TRAPHANDLER_NOEC(vector9,9 )
  1023b4:	6a 00                	push   $0x0
  1023b6:	6a 09                	push   $0x9
  1023b8:	e9 1f dd 00 00       	jmp    1100dc <_alltraps>
  1023bd:	90                   	nop

001023be <vector10>:
TRAPHANDLER(vector10,10 )
  1023be:	6a 0a                	push   $0xa
  1023c0:	e9 17 dd 00 00       	jmp    1100dc <_alltraps>
  1023c5:	90                   	nop

001023c6 <vector11>:
TRAPHANDLER(vector11,11 )
  1023c6:	6a 0b                	push   $0xb
  1023c8:	e9 0f dd 00 00       	jmp    1100dc <_alltraps>
  1023cd:	90                   	nop

001023ce <vector12>:
TRAPHANDLER(vector12,12 )
  1023ce:	6a 0c                	push   $0xc
  1023d0:	e9 07 dd 00 00       	jmp    1100dc <_alltraps>
  1023d5:	90                   	nop

001023d6 <vector13>:
TRAPHANDLER(vector13,13 )
  1023d6:	6a 0d                	push   $0xd
  1023d8:	e9 ff dc 00 00       	jmp    1100dc <_alltraps>
  1023dd:	90                   	nop

001023de <vector14>:
TRAPHANDLER(vector14,14 )
  1023de:	6a 0e                	push   $0xe
  1023e0:	e9 f7 dc 00 00       	jmp    1100dc <_alltraps>
  1023e5:	90                   	nop

001023e6 <vector15>:
TRAPHANDLER_NOEC(vector15,15 )
  1023e6:	6a 00                	push   $0x0
  1023e8:	6a 0f                	push   $0xf
  1023ea:	e9 ed dc 00 00       	jmp    1100dc <_alltraps>
  1023ef:	90                   	nop

001023f0 <vector16>:
TRAPHANDLER_NOEC(vector16,16 )
  1023f0:	6a 00                	push   $0x0
  1023f2:	6a 10                	push   $0x10
  1023f4:	e9 e3 dc 00 00       	jmp    1100dc <_alltraps>
  1023f9:	90                   	nop

001023fa <vector17>:
TRAPHANDLER(vector17,17 )
  1023fa:	6a 11                	push   $0x11
  1023fc:	e9 db dc 00 00       	jmp    1100dc <_alltraps>
  102401:	90                   	nop

00102402 <vector18>:
TRAPHANDLER_NOEC(vector18,18 )
  102402:	6a 00                	push   $0x0
  102404:	6a 12                	push   $0x12
  102406:	e9 d1 dc 00 00       	jmp    1100dc <_alltraps>
  10240b:	90                   	nop

0010240c <vector19>:
TRAPHANDLER_NOEC(vector19,19 )
  10240c:	6a 00                	push   $0x0
  10240e:	6a 13                	push   $0x13
  102410:	e9 c7 dc 00 00       	jmp    1100dc <_alltraps>
  102415:	90                   	nop

00102416 <vector20>:
TRAPHANDLER_NOEC(vector20, 20)
  102416:	6a 00                	push   $0x0
  102418:	6a 14                	push   $0x14
  10241a:	e9 bd dc 00 00       	jmp    1100dc <_alltraps>
  10241f:	90                   	nop

00102420 <vector21>:
TRAPHANDLER_NOEC(vector21, 21)
  102420:	6a 00                	push   $0x0
  102422:	6a 15                	push   $0x15
  102424:	e9 b3 dc 00 00       	jmp    1100dc <_alltraps>
  102429:	90                   	nop

0010242a <vector22>:
TRAPHANDLER_NOEC(vector22,22 )
  10242a:	6a 00                	push   $0x0
  10242c:	6a 16                	push   $0x16
  10242e:	e9 a9 dc 00 00       	jmp    1100dc <_alltraps>
  102433:	90                   	nop

00102434 <vector23>:
TRAPHANDLER_NOEC(vector23,23 )
  102434:	6a 00                	push   $0x0
  102436:	6a 17                	push   $0x17
  102438:	e9 9f dc 00 00       	jmp    1100dc <_alltraps>
  10243d:	90                   	nop

0010243e <vector24>:
TRAPHANDLER_NOEC(vector24,24 )
  10243e:	6a 00                	push   $0x0
  102440:	6a 18                	push   $0x18
  102442:	e9 95 dc 00 00       	jmp    1100dc <_alltraps>
  102447:	90                   	nop

00102448 <vector25>:
TRAPHANDLER_NOEC(vector25,25 )
  102448:	6a 00                	push   $0x0
  10244a:	6a 19                	push   $0x19
  10244c:	e9 8b dc 00 00       	jmp    1100dc <_alltraps>
  102451:	90                   	nop

00102452 <vector26>:
TRAPHANDLER_NOEC(vector26,26 )
  102452:	6a 00                	push   $0x0
  102454:	6a 1a                	push   $0x1a
  102456:	e9 81 dc 00 00       	jmp    1100dc <_alltraps>
  10245b:	90                   	nop

0010245c <vector27>:
TRAPHANDLER_NOEC(vector27,27 )
  10245c:	6a 00                	push   $0x0
  10245e:	6a 1b                	push   $0x1b
  102460:	e9 77 dc 00 00       	jmp    1100dc <_alltraps>
  102465:	90                   	nop

00102466 <vector28>:
TRAPHANDLER_NOEC(vector28,28 )
  102466:	6a 00                	push   $0x0
  102468:	6a 1c                	push   $0x1c
  10246a:	e9 6d dc 00 00       	jmp    1100dc <_alltraps>
  10246f:	90                   	nop

00102470 <vector29>:
TRAPHANDLER_NOEC(vector29,29 )
  102470:	6a 00                	push   $0x0
  102472:	6a 1d                	push   $0x1d
  102474:	e9 63 dc 00 00       	jmp    1100dc <_alltraps>
  102479:	90                   	nop

0010247a <vector30>:
TRAPHANDLER_NOEC(vector30,30 )
  10247a:	6a 00                	push   $0x0
  10247c:	6a 1e                	push   $0x1e
  10247e:	e9 59 dc 00 00       	jmp    1100dc <_alltraps>
  102483:	90                   	nop

00102484 <vector31>:
TRAPHANDLER_NOEC(vector31, 31)
  102484:	6a 00                	push   $0x0
  102486:	6a 1f                	push   $0x1f
  102488:	e9 4f dc 00 00       	jmp    1100dc <_alltraps>
  10248d:	90                   	nop

0010248e <vector32>:
TRAPHANDLER_NOEC(vector32,32 )
  10248e:	6a 00                	push   $0x0
  102490:	6a 20                	push   $0x20
  102492:	e9 45 dc 00 00       	jmp    1100dc <_alltraps>
  102497:	90                   	nop

00102498 <vector33>:
TRAPHANDLER_NOEC(vector33,33 )
  102498:	6a 00                	push   $0x0
  10249a:	6a 21                	push   $0x21
  10249c:	e9 3b dc 00 00       	jmp    1100dc <_alltraps>
  1024a1:	90                   	nop

001024a2 <vector34>:
TRAPHANDLER_NOEC(vector34,34 )
  1024a2:	6a 00                	push   $0x0
  1024a4:	6a 22                	push   $0x22
  1024a6:	e9 31 dc 00 00       	jmp    1100dc <_alltraps>
  1024ab:	90                   	nop

001024ac <vector35>:
TRAPHANDLER_NOEC(vector35,35 )
  1024ac:	6a 00                	push   $0x0
  1024ae:	6a 23                	push   $0x23
  1024b0:	e9 27 dc 00 00       	jmp    1100dc <_alltraps>
  1024b5:	90                   	nop

001024b6 <vector36>:
TRAPHANDLER_NOEC(vector36,36 )
  1024b6:	6a 00                	push   $0x0
  1024b8:	6a 24                	push   $0x24
  1024ba:	e9 1d dc 00 00       	jmp    1100dc <_alltraps>
  1024bf:	90                   	nop

001024c0 <vector37>:
TRAPHANDLER_NOEC(vector37,37 )
  1024c0:	6a 00                	push   $0x0
  1024c2:	6a 25                	push   $0x25
  1024c4:	e9 13 dc 00 00       	jmp    1100dc <_alltraps>
  1024c9:	90                   	nop

001024ca <vector38>:
TRAPHANDLER_NOEC(vector38,38 )
  1024ca:	6a 00                	push   $0x0
  1024cc:	6a 26                	push   $0x26
  1024ce:	e9 09 dc 00 00       	jmp    1100dc <_alltraps>
  1024d3:	90                   	nop

001024d4 <vector39>:
TRAPHANDLER_NOEC(vector39,39 )
  1024d4:	6a 00                	push   $0x0
  1024d6:	6a 27                	push   $0x27
  1024d8:	e9 ff db 00 00       	jmp    1100dc <_alltraps>
  1024dd:	90                   	nop

001024de <vector40>:
TRAPHANDLER_NOEC(vector40,40 )
  1024de:	6a 00                	push   $0x0
  1024e0:	6a 28                	push   $0x28
  1024e2:	e9 f5 db 00 00       	jmp    1100dc <_alltraps>
  1024e7:	90                   	nop

001024e8 <vector41>:
TRAPHANDLER_NOEC(vector41, 41)
  1024e8:	6a 00                	push   $0x0
  1024ea:	6a 29                	push   $0x29
  1024ec:	e9 eb db 00 00       	jmp    1100dc <_alltraps>
  1024f1:	90                   	nop

001024f2 <vector42>:
TRAPHANDLER_NOEC(vector42,42 )
  1024f2:	6a 00                	push   $0x0
  1024f4:	6a 2a                	push   $0x2a
  1024f6:	e9 e1 db 00 00       	jmp    1100dc <_alltraps>
  1024fb:	90                   	nop

001024fc <vector43>:
TRAPHANDLER_NOEC(vector43,43 )
  1024fc:	6a 00                	push   $0x0
  1024fe:	6a 2b                	push   $0x2b
  102500:	e9 d7 db 00 00       	jmp    1100dc <_alltraps>
  102505:	90                   	nop

00102506 <vector44>:
TRAPHANDLER_NOEC(vector44,44 )
  102506:	6a 00                	push   $0x0
  102508:	6a 2c                	push   $0x2c
  10250a:	e9 cd db 00 00       	jmp    1100dc <_alltraps>
  10250f:	90                   	nop

00102510 <vector45>:
TRAPHANDLER_NOEC(vector45,45 )
  102510:	6a 00                	push   $0x0
  102512:	6a 2d                	push   $0x2d
  102514:	e9 c3 db 00 00       	jmp    1100dc <_alltraps>
  102519:	90                   	nop

0010251a <vector46>:
TRAPHANDLER_NOEC(vector46,46 )
  10251a:	6a 00                	push   $0x0
  10251c:	6a 2e                	push   $0x2e
  10251e:	e9 b9 db 00 00       	jmp    1100dc <_alltraps>
  102523:	90                   	nop

00102524 <vector47>:
TRAPHANDLER_NOEC(vector47,47 )
  102524:	6a 00                	push   $0x0
  102526:	6a 2f                	push   $0x2f
  102528:	e9 af db 00 00       	jmp    1100dc <_alltraps>
  10252d:	90                   	nop

0010252e <vector48>:
TRAPHANDLER_NOEC(vector48,48 )
  10252e:	6a 00                	push   $0x0
  102530:	6a 30                	push   $0x30
  102532:	e9 a5 db 00 00       	jmp    1100dc <_alltraps>
  102537:	90                   	nop

00102538 <vector49>:
TRAPHANDLER_NOEC(vector49,49 )
  102538:	6a 00                	push   $0x0
  10253a:	6a 31                	push   $0x31
  10253c:	e9 9b db 00 00       	jmp    1100dc <_alltraps>
  102541:	90                   	nop

00102542 <vector50>:
TRAPHANDLER_NOEC(vector50,50 )
  102542:	6a 00                	push   $0x0
  102544:	6a 32                	push   $0x32
  102546:	e9 91 db 00 00       	jmp    1100dc <_alltraps>
  10254b:	90                   	nop

0010254c <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10254c:	55                   	push   %ebp
  10254d:	89 e5                	mov    %esp,%ebp
  10254f:	53                   	push   %ebx
  102550:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  102553:	89 e3                	mov    %esp,%ebx
  102555:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  102558:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10255b:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10255e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102561:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102566:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  102569:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10256c:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  102572:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  102577:	74 24                	je     10259d <cpu_cur+0x51>
  102579:	c7 44 24 0c 90 ab 10 	movl   $0x10ab90,0xc(%esp)
  102580:	00 
  102581:	c7 44 24 08 a6 ab 10 	movl   $0x10aba6,0x8(%esp)
  102588:	00 
  102589:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  102590:	00 
  102591:	c7 04 24 bb ab 10 00 	movl   $0x10abbb,(%esp)
  102598:	e8 9b e3 ff ff       	call   100938 <debug_panic>
	return c;
  10259d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1025a0:	83 c4 24             	add    $0x24,%esp
  1025a3:	5b                   	pop    %ebx
  1025a4:	5d                   	pop    %ebp
  1025a5:	c3                   	ret    

001025a6 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1025a6:	55                   	push   %ebp
  1025a7:	89 e5                	mov    %esp,%ebp
  1025a9:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1025ac:	e8 9b ff ff ff       	call   10254c <cpu_cur>
  1025b1:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  1025b6:	0f 94 c0             	sete   %al
  1025b9:	0f b6 c0             	movzbl %al,%eax
}
  1025bc:	c9                   	leave  
  1025bd:	c3                   	ret    

001025be <sum>:
volatile struct ioapic *ioapic;


static uint8_t
sum(uint8_t * addr, int len)
{
  1025be:	55                   	push   %ebp
  1025bf:	89 e5                	mov    %esp,%ebp
  1025c1:	83 ec 10             	sub    $0x10,%esp
	int i, sum;

	sum = 0;
  1025c4:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	for (i = 0; i < len; i++)
  1025cb:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  1025d2:	eb 15                	jmp    1025e9 <sum+0x2b>
		sum += addr[i];
  1025d4:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1025d7:	8b 45 08             	mov    0x8(%ebp),%eax
  1025da:	01 d0                	add    %edx,%eax
  1025dc:	0f b6 00             	movzbl (%eax),%eax
  1025df:	0f b6 c0             	movzbl %al,%eax
  1025e2:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uint8_t * addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
  1025e5:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  1025e9:	8b 45 fc             	mov    -0x4(%ebp),%eax
  1025ec:	3b 45 0c             	cmp    0xc(%ebp),%eax
  1025ef:	7c e3                	jl     1025d4 <sum+0x16>
		sum += addr[i];
	return sum;
  1025f1:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  1025f4:	c9                   	leave  
  1025f5:	c3                   	ret    

001025f6 <mpsearch1>:

//Look for an MP structure in the len bytes at addr.
static struct mp *
mpsearch1(uint8_t * addr, int len)
{
  1025f6:	55                   	push   %ebp
  1025f7:	89 e5                	mov    %esp,%ebp
  1025f9:	83 ec 28             	sub    $0x28,%esp
	uint8_t *e, *p;

	e = addr + len;
  1025fc:	8b 55 0c             	mov    0xc(%ebp),%edx
  1025ff:	8b 45 08             	mov    0x8(%ebp),%eax
  102602:	01 d0                	add    %edx,%eax
  102604:	89 45 f0             	mov    %eax,-0x10(%ebp)
	for (p = addr; p < e; p += sizeof(struct mp))
  102607:	8b 45 08             	mov    0x8(%ebp),%eax
  10260a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10260d:	eb 3f                	jmp    10264e <mpsearch1+0x58>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
  10260f:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  102616:	00 
  102617:	c7 44 24 04 c8 ab 10 	movl   $0x10abc8,0x4(%esp)
  10261e:	00 
  10261f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102622:	89 04 24             	mov    %eax,(%esp)
  102625:	e8 80 77 00 00       	call   109daa <memcmp>
  10262a:	85 c0                	test   %eax,%eax
  10262c:	75 1c                	jne    10264a <mpsearch1+0x54>
  10262e:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
  102635:	00 
  102636:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102639:	89 04 24             	mov    %eax,(%esp)
  10263c:	e8 7d ff ff ff       	call   1025be <sum>
  102641:	84 c0                	test   %al,%al
  102643:	75 05                	jne    10264a <mpsearch1+0x54>
			return (struct mp *) p;
  102645:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102648:	eb 11                	jmp    10265b <mpsearch1+0x65>
mpsearch1(uint8_t * addr, int len)
{
	uint8_t *e, *p;

	e = addr + len;
	for (p = addr; p < e; p += sizeof(struct mp))
  10264a:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
  10264e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102651:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  102654:	72 b9                	jb     10260f <mpsearch1+0x19>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
			return (struct mp *) p;
	return 0;
  102656:	b8 00 00 00 00       	mov    $0x0,%eax
}
  10265b:	c9                   	leave  
  10265c:	c3                   	ret    

0010265d <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp *
mpsearch(void)
{
  10265d:	55                   	push   %ebp
  10265e:	89 e5                	mov    %esp,%ebp
  102660:	83 ec 28             	sub    $0x28,%esp
	uint8_t          *bda;
	uint32_t            p;
	struct mp      *mp;

	bda = (uint8_t *) 0x400;
  102663:	c7 45 f4 00 04 00 00 	movl   $0x400,-0xc(%ebp)
	if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) {
  10266a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10266d:	83 c0 0f             	add    $0xf,%eax
  102670:	0f b6 00             	movzbl (%eax),%eax
  102673:	0f b6 c0             	movzbl %al,%eax
  102676:	89 c2                	mov    %eax,%edx
  102678:	c1 e2 08             	shl    $0x8,%edx
  10267b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10267e:	83 c0 0e             	add    $0xe,%eax
  102681:	0f b6 00             	movzbl (%eax),%eax
  102684:	0f b6 c0             	movzbl %al,%eax
  102687:	09 d0                	or     %edx,%eax
  102689:	c1 e0 04             	shl    $0x4,%eax
  10268c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10268f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  102693:	74 21                	je     1026b6 <mpsearch+0x59>
		if ((mp = mpsearch1((uint8_t *) p, 1024)))
  102695:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102698:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  10269f:	00 
  1026a0:	89 04 24             	mov    %eax,(%esp)
  1026a3:	e8 4e ff ff ff       	call   1025f6 <mpsearch1>
  1026a8:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1026ab:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1026af:	74 50                	je     102701 <mpsearch+0xa4>
			return mp;
  1026b1:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1026b4:	eb 5f                	jmp    102715 <mpsearch+0xb8>
	} else {
		p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
  1026b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1026b9:	83 c0 14             	add    $0x14,%eax
  1026bc:	0f b6 00             	movzbl (%eax),%eax
  1026bf:	0f b6 c0             	movzbl %al,%eax
  1026c2:	89 c2                	mov    %eax,%edx
  1026c4:	c1 e2 08             	shl    $0x8,%edx
  1026c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1026ca:	83 c0 13             	add    $0x13,%eax
  1026cd:	0f b6 00             	movzbl (%eax),%eax
  1026d0:	0f b6 c0             	movzbl %al,%eax
  1026d3:	09 d0                	or     %edx,%eax
  1026d5:	c1 e0 0a             	shl    $0xa,%eax
  1026d8:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if ((mp = mpsearch1((uint8_t *) p - 1024, 1024)))
  1026db:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1026de:	2d 00 04 00 00       	sub    $0x400,%eax
  1026e3:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  1026ea:	00 
  1026eb:	89 04 24             	mov    %eax,(%esp)
  1026ee:	e8 03 ff ff ff       	call   1025f6 <mpsearch1>
  1026f3:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1026f6:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1026fa:	74 05                	je     102701 <mpsearch+0xa4>
			return mp;
  1026fc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1026ff:	eb 14                	jmp    102715 <mpsearch+0xb8>
	}
	return mpsearch1((uint8_t *) 0xF0000, 0x10000);
  102701:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  102708:	00 
  102709:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
  102710:	e8 e1 fe ff ff       	call   1025f6 <mpsearch1>
}
  102715:	c9                   	leave  
  102716:	c3                   	ret    

00102717 <mpconfig>:
// don 't accept the default configurations (physaddr == 0).
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf *
mpconfig(struct mp **pmp) {
  102717:	55                   	push   %ebp
  102718:	89 e5                	mov    %esp,%ebp
  10271a:	83 ec 28             	sub    $0x28,%esp
	struct mpconf  *conf;
	struct mp      *mp;

	if ((mp = mpsearch()) == 0 || mp->physaddr == 0)
  10271d:	e8 3b ff ff ff       	call   10265d <mpsearch>
  102722:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102725:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102729:	74 0a                	je     102735 <mpconfig+0x1e>
  10272b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10272e:	8b 40 04             	mov    0x4(%eax),%eax
  102731:	85 c0                	test   %eax,%eax
  102733:	75 07                	jne    10273c <mpconfig+0x25>
		return 0;
  102735:	b8 00 00 00 00       	mov    $0x0,%eax
  10273a:	eb 7b                	jmp    1027b7 <mpconfig+0xa0>
	conf = (struct mpconf *) mp->physaddr;
  10273c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10273f:	8b 40 04             	mov    0x4(%eax),%eax
  102742:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (memcmp(conf, "PCMP", 4) != 0)
  102745:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  10274c:	00 
  10274d:	c7 44 24 04 cd ab 10 	movl   $0x10abcd,0x4(%esp)
  102754:	00 
  102755:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102758:	89 04 24             	mov    %eax,(%esp)
  10275b:	e8 4a 76 00 00       	call   109daa <memcmp>
  102760:	85 c0                	test   %eax,%eax
  102762:	74 07                	je     10276b <mpconfig+0x54>
		return 0;
  102764:	b8 00 00 00 00       	mov    $0x0,%eax
  102769:	eb 4c                	jmp    1027b7 <mpconfig+0xa0>
	if (conf->version != 1 && conf->version != 4)
  10276b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10276e:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  102772:	3c 01                	cmp    $0x1,%al
  102774:	74 12                	je     102788 <mpconfig+0x71>
  102776:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102779:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  10277d:	3c 04                	cmp    $0x4,%al
  10277f:	74 07                	je     102788 <mpconfig+0x71>
		return 0;
  102781:	b8 00 00 00 00       	mov    $0x0,%eax
  102786:	eb 2f                	jmp    1027b7 <mpconfig+0xa0>
	if (sum((uint8_t *) conf, conf->length) != 0)
  102788:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10278b:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  10278f:	0f b7 c0             	movzwl %ax,%eax
  102792:	89 44 24 04          	mov    %eax,0x4(%esp)
  102796:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102799:	89 04 24             	mov    %eax,(%esp)
  10279c:	e8 1d fe ff ff       	call   1025be <sum>
  1027a1:	84 c0                	test   %al,%al
  1027a3:	74 07                	je     1027ac <mpconfig+0x95>
		return 0;
  1027a5:	b8 00 00 00 00       	mov    $0x0,%eax
  1027aa:	eb 0b                	jmp    1027b7 <mpconfig+0xa0>
       *pmp = mp;
  1027ac:	8b 45 08             	mov    0x8(%ebp),%eax
  1027af:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1027b2:	89 10                	mov    %edx,(%eax)
	return conf;
  1027b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1027b7:	c9                   	leave  
  1027b8:	c3                   	ret    

001027b9 <mp_init>:

void
mp_init(void)
{
  1027b9:	55                   	push   %ebp
  1027ba:	89 e5                	mov    %esp,%ebp
  1027bc:	53                   	push   %ebx
  1027bd:	83 ec 64             	sub    $0x64,%esp
	struct mp      *mp;
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
  1027c0:	e8 e1 fd ff ff       	call   1025a6 <cpu_onboot>
  1027c5:	85 c0                	test   %eax,%eax
  1027c7:	0f 84 75 01 00 00    	je     102942 <mp_init+0x189>
		return;

	if ((conf = mpconfig(&mp)) == 0)
  1027cd:	8d 45 c4             	lea    -0x3c(%ebp),%eax
  1027d0:	89 04 24             	mov    %eax,(%esp)
  1027d3:	e8 3f ff ff ff       	call   102717 <mpconfig>
  1027d8:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1027db:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1027df:	0f 84 5d 01 00 00    	je     102942 <mp_init+0x189>
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
  1027e5:	c7 05 5c 8f 38 00 01 	movl   $0x1,0x388f5c
  1027ec:	00 00 00 
	lapic = (uint32_t *) conf->lapicaddr;
  1027ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1027f2:	8b 40 24             	mov    0x24(%eax),%eax
  1027f5:	a3 04 c0 38 00       	mov    %eax,0x38c004
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  1027fa:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1027fd:	83 c0 2c             	add    $0x2c,%eax
  102800:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102803:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102806:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  10280a:	0f b7 d0             	movzwl %ax,%edx
  10280d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102810:	01 d0                	add    %edx,%eax
  102812:	89 45 ec             	mov    %eax,-0x14(%ebp)
  102815:	e9 cc 00 00 00       	jmp    1028e6 <mp_init+0x12d>
			p < e;) {
		switch (*p) {
  10281a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10281d:	0f b6 00             	movzbl (%eax),%eax
  102820:	0f b6 c0             	movzbl %al,%eax
  102823:	83 f8 04             	cmp    $0x4,%eax
  102826:	0f 87 90 00 00 00    	ja     1028bc <mp_init+0x103>
  10282c:	8b 04 85 00 ac 10 00 	mov    0x10ac00(,%eax,4),%eax
  102833:	ff e0                	jmp    *%eax
		case MPPROC:
			proc = (struct mpproc *) p;
  102835:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102838:	89 45 e8             	mov    %eax,-0x18(%ebp)
			p += sizeof(struct mpproc);
  10283b:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
			if (!(proc->flags & MPENAB))
  10283f:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102842:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  102846:	0f b6 c0             	movzbl %al,%eax
  102849:	83 e0 01             	and    $0x1,%eax
  10284c:	85 c0                	test   %eax,%eax
  10284e:	0f 84 91 00 00 00    	je     1028e5 <mp_init+0x12c>
				continue;	// processor disabled

			// Get a cpu struct and kernel stack for this CPU.
			cpu *c = (proc->flags & MPBOOT)
  102854:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102857:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  10285b:	0f b6 c0             	movzbl %al,%eax
  10285e:	83 e0 02             	and    $0x2,%eax
					? &cpu_boot : cpu_alloc();
  102861:	85 c0                	test   %eax,%eax
  102863:	75 07                	jne    10286c <mp_init+0xb3>
  102865:	e8 dc ee ff ff       	call   101746 <cpu_alloc>
  10286a:	eb 05                	jmp    102871 <mp_init+0xb8>
  10286c:	b8 00 f0 10 00       	mov    $0x10f000,%eax
			p += sizeof(struct mpproc);
			if (!(proc->flags & MPENAB))
				continue;	// processor disabled

			// Get a cpu struct and kernel stack for this CPU.
			cpu *c = (proc->flags & MPBOOT)
  102871:	89 45 e4             	mov    %eax,-0x1c(%ebp)
					? &cpu_boot : cpu_alloc();
			c->id = proc->apicid;
  102874:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102877:	0f b6 50 01          	movzbl 0x1(%eax),%edx
  10287b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10287e:	88 90 ac 00 00 00    	mov    %dl,0xac(%eax)
			ncpu++;
  102884:	a1 60 8f 38 00       	mov    0x388f60,%eax
  102889:	83 c0 01             	add    $0x1,%eax
  10288c:	a3 60 8f 38 00       	mov    %eax,0x388f60
			continue;
  102891:	eb 53                	jmp    1028e6 <mp_init+0x12d>
		case MPIOAPIC:
			mpio = (struct mpioapic *) p;
  102893:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102896:	89 45 e0             	mov    %eax,-0x20(%ebp)
			p += sizeof(struct mpioapic);
  102899:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
			ioapicid = mpio->apicno;
  10289d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1028a0:	0f b6 40 01          	movzbl 0x1(%eax),%eax
  1028a4:	a2 54 8f 38 00       	mov    %al,0x388f54
			ioapic = (struct ioapic *) mpio->addr;
  1028a9:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1028ac:	8b 40 04             	mov    0x4(%eax),%eax
  1028af:	a3 58 8f 38 00       	mov    %eax,0x388f58
			continue;
  1028b4:	eb 30                	jmp    1028e6 <mp_init+0x12d>
		case MPBUS:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
  1028b6:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
			continue;
  1028ba:	eb 2a                	jmp    1028e6 <mp_init+0x12d>
		default:
			panic("mpinit: unknown config type %x\n", *p);
  1028bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1028bf:	0f b6 00             	movzbl (%eax),%eax
  1028c2:	0f b6 c0             	movzbl %al,%eax
  1028c5:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1028c9:	c7 44 24 08 d4 ab 10 	movl   $0x10abd4,0x8(%esp)
  1028d0:	00 
  1028d1:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
  1028d8:	00 
  1028d9:	c7 04 24 f4 ab 10 00 	movl   $0x10abf4,(%esp)
  1028e0:	e8 53 e0 ff ff       	call   100938 <debug_panic>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *) p;
			p += sizeof(struct mpproc);
			if (!(proc->flags & MPENAB))
				continue;	// processor disabled
  1028e5:	90                   	nop
	if ((conf = mpconfig(&mp)) == 0)
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
	lapic = (uint32_t *) conf->lapicaddr;
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  1028e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1028e9:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  1028ec:	0f 82 28 ff ff ff    	jb     10281a <mp_init+0x61>
			continue;
		default:
			panic("mpinit: unknown config type %x\n", *p);
		}
	}
	if (mp->imcrp) {
  1028f2:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  1028f5:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
  1028f9:	84 c0                	test   %al,%al
  1028fb:	74 45                	je     102942 <mp_init+0x189>
  1028fd:	c7 45 dc 22 00 00 00 	movl   $0x22,-0x24(%ebp)
  102904:	c6 45 db 70          	movb   $0x70,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  102908:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  10290c:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10290f:	ee                   	out    %al,(%dx)
  102910:	c7 45 d4 23 00 00 00 	movl   $0x23,-0x2c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  102917:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10291a:	89 55 b4             	mov    %edx,-0x4c(%ebp)
  10291d:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  102920:	ec                   	in     (%dx),%al
  102921:	89 c3                	mov    %eax,%ebx
  102923:	88 5d d3             	mov    %bl,-0x2d(%ebp)
	return data;
  102926:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
  10292a:	83 c8 01             	or     $0x1,%eax
  10292d:	0f b6 c0             	movzbl %al,%eax
  102930:	c7 45 cc 23 00 00 00 	movl   $0x23,-0x34(%ebp)
  102937:	88 45 cb             	mov    %al,-0x35(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10293a:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  10293e:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102941:	ee                   	out    %al,(%dx)
	}
}
  102942:	83 c4 64             	add    $0x64,%esp
  102945:	5b                   	pop    %ebx
  102946:	5d                   	pop    %ebp
  102947:	c3                   	ret    

00102948 <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  102948:	55                   	push   %ebp
  102949:	89 e5                	mov    %esp,%ebp
  10294b:	53                   	push   %ebx
  10294c:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
	       "+m" (*addr), "=a" (result) :
  10294f:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  102952:	8b 45 0c             	mov    0xc(%ebp),%eax
	       "+m" (*addr), "=a" (result) :
  102955:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  102958:	89 c3                	mov    %eax,%ebx
  10295a:	89 d8                	mov    %ebx,%eax
  10295c:	f0 87 02             	lock xchg %eax,(%edx)
  10295f:	89 c3                	mov    %eax,%ebx
  102961:	89 5d f8             	mov    %ebx,-0x8(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  102964:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  102967:	83 c4 10             	add    $0x10,%esp
  10296a:	5b                   	pop    %ebx
  10296b:	5d                   	pop    %ebp
  10296c:	c3                   	ret    

0010296d <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  10296d:	55                   	push   %ebp
  10296e:	89 e5                	mov    %esp,%ebp
  102970:	53                   	push   %ebx
  102971:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  102974:	89 e3                	mov    %esp,%ebx
  102976:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  102979:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10297c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10297f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102982:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102987:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  10298a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10298d:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  102993:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  102998:	74 24                	je     1029be <cpu_cur+0x51>
  10299a:	c7 44 24 0c 14 ac 10 	movl   $0x10ac14,0xc(%esp)
  1029a1:	00 
  1029a2:	c7 44 24 08 2a ac 10 	movl   $0x10ac2a,0x8(%esp)
  1029a9:	00 
  1029aa:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1029b1:	00 
  1029b2:	c7 04 24 3f ac 10 00 	movl   $0x10ac3f,(%esp)
  1029b9:	e8 7a df ff ff       	call   100938 <debug_panic>
	return c;
  1029be:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1029c1:	83 c4 24             	add    $0x24,%esp
  1029c4:	5b                   	pop    %ebx
  1029c5:	5d                   	pop    %ebp
  1029c6:	c3                   	ret    

001029c7 <spinlock_init_>:
#include <kern/cons.h>


void
spinlock_init_(struct spinlock *lk, const char *file, int line)
{
  1029c7:	55                   	push   %ebp
  1029c8:	89 e5                	mov    %esp,%ebp
	lk->file = file;
  1029ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1029cd:	8b 55 0c             	mov    0xc(%ebp),%edx
  1029d0:	89 50 04             	mov    %edx,0x4(%eax)
	lk->line = line;
  1029d3:	8b 45 08             	mov    0x8(%ebp),%eax
  1029d6:	8b 55 10             	mov    0x10(%ebp),%edx
  1029d9:	89 50 08             	mov    %edx,0x8(%eax)
	lk->cpu = NULL;
  1029dc:	8b 45 08             	mov    0x8(%ebp),%eax
  1029df:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
	lk->locked = 0;
  1029e6:	8b 45 08             	mov    0x8(%ebp),%eax
  1029e9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  1029ef:	5d                   	pop    %ebp
  1029f0:	c3                   	ret    

001029f1 <spinlock_acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spinlock_acquire(struct spinlock *lk)
{
  1029f1:	55                   	push   %ebp
  1029f2:	89 e5                	mov    %esp,%ebp
  1029f4:	53                   	push   %ebx
  1029f5:	83 ec 24             	sub    $0x24,%esp
	if(spinlock_holding(lk))
  1029f8:	8b 45 08             	mov    0x8(%ebp),%eax
  1029fb:	89 04 24             	mov    %eax,(%esp)
  1029fe:	e8 bd 00 00 00       	call   102ac0 <spinlock_holding>
  102a03:	85 c0                	test   %eax,%eax
  102a05:	74 1c                	je     102a23 <spinlock_acquire+0x32>
		panic("Has already held this spinlock!\n");
  102a07:	c7 44 24 08 4c ac 10 	movl   $0x10ac4c,0x8(%esp)
  102a0e:	00 
  102a0f:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
  102a16:	00 
  102a17:	c7 04 24 6d ac 10 00 	movl   $0x10ac6d,(%esp)
  102a1e:	e8 15 df ff ff       	call   100938 <debug_panic>
	while(xchg(&lk->locked, 1) != 0);
  102a23:	90                   	nop
  102a24:	8b 45 08             	mov    0x8(%ebp),%eax
  102a27:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102a2e:	00 
  102a2f:	89 04 24             	mov    %eax,(%esp)
  102a32:	e8 11 ff ff ff       	call   102948 <xchg>
  102a37:	85 c0                	test   %eax,%eax
  102a39:	75 e9                	jne    102a24 <spinlock_acquire+0x33>
	lk->cpu = cpu_cur();
  102a3b:	e8 2d ff ff ff       	call   10296d <cpu_cur>
  102a40:	8b 55 08             	mov    0x8(%ebp),%edx
  102a43:	89 42 0c             	mov    %eax,0xc(%edx)
	debug_trace(read_ebp(), lk->eips);
  102a46:	8b 45 08             	mov    0x8(%ebp),%eax
  102a49:	8d 50 10             	lea    0x10(%eax),%edx

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  102a4c:	89 eb                	mov    %ebp,%ebx
  102a4e:	89 5d f4             	mov    %ebx,-0xc(%ebp)
        return ebp;
  102a51:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102a54:	89 54 24 04          	mov    %edx,0x4(%esp)
  102a58:	89 04 24             	mov    %eax,(%esp)
  102a5b:	e8 e7 df ff ff       	call   100a47 <debug_trace>
}
  102a60:	83 c4 24             	add    $0x24,%esp
  102a63:	5b                   	pop    %ebx
  102a64:	5d                   	pop    %ebp
  102a65:	c3                   	ret    

00102a66 <spinlock_release>:

// Release the lock.
void
spinlock_release(struct spinlock *lk)
{
  102a66:	55                   	push   %ebp
  102a67:	89 e5                	mov    %esp,%ebp
  102a69:	83 ec 18             	sub    $0x18,%esp
	if(!spinlock_holding(lk))
  102a6c:	8b 45 08             	mov    0x8(%ebp),%eax
  102a6f:	89 04 24             	mov    %eax,(%esp)
  102a72:	e8 49 00 00 00       	call   102ac0 <spinlock_holding>
  102a77:	85 c0                	test   %eax,%eax
  102a79:	75 1c                	jne    102a97 <spinlock_release+0x31>
		panic("Doesn't hold the spinlock!\n");
  102a7b:	c7 44 24 08 7d ac 10 	movl   $0x10ac7d,0x8(%esp)
  102a82:	00 
  102a83:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
  102a8a:	00 
  102a8b:	c7 04 24 6d ac 10 00 	movl   $0x10ac6d,(%esp)
  102a92:	e8 a1 de ff ff       	call   100938 <debug_panic>
	lk->eips[0] = 0;
  102a97:	8b 45 08             	mov    0x8(%ebp),%eax
  102a9a:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
	lk->cpu = NULL;
  102aa1:	8b 45 08             	mov    0x8(%ebp),%eax
  102aa4:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
	xchg(&lk->locked, 0);
  102aab:	8b 45 08             	mov    0x8(%ebp),%eax
  102aae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102ab5:	00 
  102ab6:	89 04 24             	mov    %eax,(%esp)
  102ab9:	e8 8a fe ff ff       	call   102948 <xchg>
}
  102abe:	c9                   	leave  
  102abf:	c3                   	ret    

00102ac0 <spinlock_holding>:

// Check whether this cpu is holding the lock.
int
spinlock_holding(spinlock *lock)
{
  102ac0:	55                   	push   %ebp
  102ac1:	89 e5                	mov    %esp,%ebp
  102ac3:	53                   	push   %ebx
  102ac4:	83 ec 04             	sub    $0x4,%esp
	return lock->locked && lock->cpu == cpu_cur();
  102ac7:	8b 45 08             	mov    0x8(%ebp),%eax
  102aca:	8b 00                	mov    (%eax),%eax
  102acc:	85 c0                	test   %eax,%eax
  102ace:	74 16                	je     102ae6 <spinlock_holding+0x26>
  102ad0:	8b 45 08             	mov    0x8(%ebp),%eax
  102ad3:	8b 58 0c             	mov    0xc(%eax),%ebx
  102ad6:	e8 92 fe ff ff       	call   10296d <cpu_cur>
  102adb:	39 c3                	cmp    %eax,%ebx
  102add:	75 07                	jne    102ae6 <spinlock_holding+0x26>
  102adf:	b8 01 00 00 00       	mov    $0x1,%eax
  102ae4:	eb 05                	jmp    102aeb <spinlock_holding+0x2b>
  102ae6:	b8 00 00 00 00       	mov    $0x0,%eax
}
  102aeb:	83 c4 04             	add    $0x4,%esp
  102aee:	5b                   	pop    %ebx
  102aef:	5d                   	pop    %ebp
  102af0:	c3                   	ret    

00102af1 <spinlock_godeep>:
// Function that simply recurses to a specified depth.
// The useless return value and volatile parameter are
// so GCC doesn't collapse it via tail-call elimination.
int gcc_noinline
spinlock_godeep(volatile int depth, spinlock* lk)
{
  102af1:	55                   	push   %ebp
  102af2:	89 e5                	mov    %esp,%ebp
  102af4:	83 ec 18             	sub    $0x18,%esp
	if (depth==0) { spinlock_acquire(lk); return 1; }
  102af7:	8b 45 08             	mov    0x8(%ebp),%eax
  102afa:	85 c0                	test   %eax,%eax
  102afc:	75 12                	jne    102b10 <spinlock_godeep+0x1f>
  102afe:	8b 45 0c             	mov    0xc(%ebp),%eax
  102b01:	89 04 24             	mov    %eax,(%esp)
  102b04:	e8 e8 fe ff ff       	call   1029f1 <spinlock_acquire>
  102b09:	b8 01 00 00 00       	mov    $0x1,%eax
  102b0e:	eb 1b                	jmp    102b2b <spinlock_godeep+0x3a>
	else return spinlock_godeep(depth-1, lk) * depth;
  102b10:	8b 45 08             	mov    0x8(%ebp),%eax
  102b13:	8d 50 ff             	lea    -0x1(%eax),%edx
  102b16:	8b 45 0c             	mov    0xc(%ebp),%eax
  102b19:	89 44 24 04          	mov    %eax,0x4(%esp)
  102b1d:	89 14 24             	mov    %edx,(%esp)
  102b20:	e8 cc ff ff ff       	call   102af1 <spinlock_godeep>
  102b25:	8b 55 08             	mov    0x8(%ebp),%edx
  102b28:	0f af c2             	imul   %edx,%eax
}
  102b2b:	c9                   	leave  
  102b2c:	c3                   	ret    

00102b2d <spinlock_check>:

void spinlock_check()
{
  102b2d:	55                   	push   %ebp
  102b2e:	89 e5                	mov    %esp,%ebp
  102b30:	56                   	push   %esi
  102b31:	53                   	push   %ebx
  102b32:	83 ec 40             	sub    $0x40,%esp
  102b35:	89 e0                	mov    %esp,%eax
  102b37:	89 c3                	mov    %eax,%ebx
	const int NUMLOCKS=10;
  102b39:	c7 45 e8 0a 00 00 00 	movl   $0xa,-0x18(%ebp)
	const int NUMRUNS=5;
  102b40:	c7 45 e4 05 00 00 00 	movl   $0x5,-0x1c(%ebp)
	int i,j,run;
	const char* file = "spinlock_check";
  102b47:	c7 45 e0 99 ac 10 00 	movl   $0x10ac99,-0x20(%ebp)
	spinlock locks[NUMLOCKS];
  102b4e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102b51:	83 e8 01             	sub    $0x1,%eax
  102b54:	89 45 dc             	mov    %eax,-0x24(%ebp)
  102b57:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102b5a:	ba 00 00 00 00       	mov    $0x0,%edx
  102b5f:	69 f2 c0 01 00 00    	imul   $0x1c0,%edx,%esi
  102b65:	6b c8 00             	imul   $0x0,%eax,%ecx
  102b68:	01 ce                	add    %ecx,%esi
  102b6a:	b9 c0 01 00 00       	mov    $0x1c0,%ecx
  102b6f:	f7 e1                	mul    %ecx
  102b71:	8d 0c 16             	lea    (%esi,%edx,1),%ecx
  102b74:	89 ca                	mov    %ecx,%edx
  102b76:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102b79:	c1 e0 03             	shl    $0x3,%eax
  102b7c:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102b7f:	ba 00 00 00 00       	mov    $0x0,%edx
  102b84:	69 f2 c0 01 00 00    	imul   $0x1c0,%edx,%esi
  102b8a:	6b c8 00             	imul   $0x0,%eax,%ecx
  102b8d:	01 ce                	add    %ecx,%esi
  102b8f:	b9 c0 01 00 00       	mov    $0x1c0,%ecx
  102b94:	f7 e1                	mul    %ecx
  102b96:	8d 0c 16             	lea    (%esi,%edx,1),%ecx
  102b99:	89 ca                	mov    %ecx,%edx
  102b9b:	8b 45 e8             	mov    -0x18(%ebp),%eax
  102b9e:	c1 e0 03             	shl    $0x3,%eax
  102ba1:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102ba8:	89 d1                	mov    %edx,%ecx
  102baa:	29 c1                	sub    %eax,%ecx
  102bac:	89 c8                	mov    %ecx,%eax
  102bae:	8d 50 03             	lea    0x3(%eax),%edx
  102bb1:	b8 10 00 00 00       	mov    $0x10,%eax
  102bb6:	83 e8 01             	sub    $0x1,%eax
  102bb9:	01 d0                	add    %edx,%eax
  102bbb:	c7 45 d4 10 00 00 00 	movl   $0x10,-0x2c(%ebp)
  102bc2:	ba 00 00 00 00       	mov    $0x0,%edx
  102bc7:	f7 75 d4             	divl   -0x2c(%ebp)
  102bca:	6b c0 10             	imul   $0x10,%eax,%eax
  102bcd:	29 c4                	sub    %eax,%esp
  102bcf:	8d 44 24 10          	lea    0x10(%esp),%eax
  102bd3:	83 c0 03             	add    $0x3,%eax
  102bd6:	c1 e8 02             	shr    $0x2,%eax
  102bd9:	c1 e0 02             	shl    $0x2,%eax
  102bdc:	89 45 d8             	mov    %eax,-0x28(%ebp)

	// Initialize the locks
	for(i=0;i<NUMLOCKS;i++) spinlock_init_(&locks[i], file, 0);
  102bdf:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102be6:	eb 2f                	jmp    102c17 <spinlock_check+0xea>
  102be8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102beb:	c1 e0 03             	shl    $0x3,%eax
  102bee:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102bf5:	29 c2                	sub    %eax,%edx
  102bf7:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102bfa:	01 c2                	add    %eax,%edx
  102bfc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  102c03:	00 
  102c04:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102c07:	89 44 24 04          	mov    %eax,0x4(%esp)
  102c0b:	89 14 24             	mov    %edx,(%esp)
  102c0e:	e8 b4 fd ff ff       	call   1029c7 <spinlock_init_>
  102c13:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102c17:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102c1a:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102c1d:	7c c9                	jl     102be8 <spinlock_check+0xbb>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
  102c1f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102c26:	eb 46                	jmp    102c6e <spinlock_check+0x141>
  102c28:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  102c2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102c2e:	c1 e0 03             	shl    $0x3,%eax
  102c31:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102c38:	29 c2                	sub    %eax,%edx
  102c3a:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  102c3d:	83 c0 0c             	add    $0xc,%eax
  102c40:	8b 00                	mov    (%eax),%eax
  102c42:	85 c0                	test   %eax,%eax
  102c44:	74 24                	je     102c6a <spinlock_check+0x13d>
  102c46:	c7 44 24 0c a8 ac 10 	movl   $0x10aca8,0xc(%esp)
  102c4d:	00 
  102c4e:	c7 44 24 08 2a ac 10 	movl   $0x10ac2a,0x8(%esp)
  102c55:	00 
  102c56:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
  102c5d:	00 
  102c5e:	c7 04 24 6d ac 10 00 	movl   $0x10ac6d,(%esp)
  102c65:	e8 ce dc ff ff       	call   100938 <debug_panic>
  102c6a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102c6e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102c71:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102c74:	7c b2                	jl     102c28 <spinlock_check+0xfb>
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);
  102c76:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102c7d:	eb 47                	jmp    102cc6 <spinlock_check+0x199>
  102c7f:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  102c82:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102c85:	c1 e0 03             	shl    $0x3,%eax
  102c88:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102c8f:	29 c2                	sub    %eax,%edx
  102c91:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  102c94:	83 c0 04             	add    $0x4,%eax
  102c97:	8b 00                	mov    (%eax),%eax
  102c99:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  102c9c:	74 24                	je     102cc2 <spinlock_check+0x195>
  102c9e:	c7 44 24 0c bb ac 10 	movl   $0x10acbb,0xc(%esp)
  102ca5:	00 
  102ca6:	c7 44 24 08 2a ac 10 	movl   $0x10ac2a,0x8(%esp)
  102cad:	00 
  102cae:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  102cb5:	00 
  102cb6:	c7 04 24 6d ac 10 00 	movl   $0x10ac6d,(%esp)
  102cbd:	e8 76 dc ff ff       	call   100938 <debug_panic>
  102cc2:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102cc6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102cc9:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102ccc:	7c b1                	jl     102c7f <spinlock_check+0x152>

	for (run=0;run<NUMRUNS;run++) 
  102cce:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  102cd5:	e9 fc 02 00 00       	jmp    102fd6 <spinlock_check+0x4a9>
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  102cda:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102ce1:	eb 27                	jmp    102d0a <spinlock_check+0x1dd>
			spinlock_godeep(i, &locks[i]);
  102ce3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ce6:	c1 e0 03             	shl    $0x3,%eax
  102ce9:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102cf0:	29 c2                	sub    %eax,%edx
  102cf2:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102cf5:	01 d0                	add    %edx,%eax
  102cf7:	89 44 24 04          	mov    %eax,0x4(%esp)
  102cfb:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102cfe:	89 04 24             	mov    %eax,(%esp)
  102d01:	e8 eb fd ff ff       	call   102af1 <spinlock_godeep>
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  102d06:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102d0a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102d0d:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102d10:	7c d1                	jl     102ce3 <spinlock_check+0x1b6>
			spinlock_godeep(i, &locks[i]);

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  102d12:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102d19:	eb 4b                	jmp    102d66 <spinlock_check+0x239>
			assert(locks[i].cpu == cpu_cur());
  102d1b:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  102d1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102d21:	c1 e0 03             	shl    $0x3,%eax
  102d24:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102d2b:	29 c2                	sub    %eax,%edx
  102d2d:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  102d30:	83 c0 0c             	add    $0xc,%eax
  102d33:	8b 30                	mov    (%eax),%esi
  102d35:	e8 33 fc ff ff       	call   10296d <cpu_cur>
  102d3a:	39 c6                	cmp    %eax,%esi
  102d3c:	74 24                	je     102d62 <spinlock_check+0x235>
  102d3e:	c7 44 24 0c cf ac 10 	movl   $0x10accf,0xc(%esp)
  102d45:	00 
  102d46:	c7 44 24 08 2a ac 10 	movl   $0x10ac2a,0x8(%esp)
  102d4d:	00 
  102d4e:	c7 44 24 04 5d 00 00 	movl   $0x5d,0x4(%esp)
  102d55:	00 
  102d56:	c7 04 24 6d ac 10 00 	movl   $0x10ac6d,(%esp)
  102d5d:	e8 d6 db ff ff       	call   100938 <debug_panic>
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
			spinlock_godeep(i, &locks[i]);

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  102d62:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102d66:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102d69:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102d6c:	7c ad                	jl     102d1b <spinlock_check+0x1ee>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  102d6e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102d75:	eb 48                	jmp    102dbf <spinlock_check+0x292>
			assert(spinlock_holding(&locks[i]) != 0);
  102d77:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102d7a:	c1 e0 03             	shl    $0x3,%eax
  102d7d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102d84:	29 c2                	sub    %eax,%edx
  102d86:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102d89:	01 d0                	add    %edx,%eax
  102d8b:	89 04 24             	mov    %eax,(%esp)
  102d8e:	e8 2d fd ff ff       	call   102ac0 <spinlock_holding>
  102d93:	85 c0                	test   %eax,%eax
  102d95:	75 24                	jne    102dbb <spinlock_check+0x28e>
  102d97:	c7 44 24 0c ec ac 10 	movl   $0x10acec,0xc(%esp)
  102d9e:	00 
  102d9f:	c7 44 24 08 2a ac 10 	movl   $0x10ac2a,0x8(%esp)
  102da6:	00 
  102da7:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  102dae:	00 
  102daf:	c7 04 24 6d ac 10 00 	movl   $0x10ac6d,(%esp)
  102db6:	e8 7d db ff ff       	call   100938 <debug_panic>

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  102dbb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102dbf:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102dc2:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102dc5:	7c b0                	jl     102d77 <spinlock_check+0x24a>
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  102dc7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102dce:	e9 bb 00 00 00       	jmp    102e8e <spinlock_check+0x361>
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  102dd3:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  102dda:	e9 99 00 00 00       	jmp    102e78 <spinlock_check+0x34b>
			{
				assert(locks[i].eips[j] >=
  102ddf:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  102de2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102de5:	01 c0                	add    %eax,%eax
  102de7:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102dee:	29 c2                	sub    %eax,%edx
  102df0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102df3:	01 d0                	add    %edx,%eax
  102df5:	83 c0 04             	add    $0x4,%eax
  102df8:	8b 14 81             	mov    (%ecx,%eax,4),%edx
  102dfb:	b8 f1 2a 10 00       	mov    $0x102af1,%eax
  102e00:	39 c2                	cmp    %eax,%edx
  102e02:	73 24                	jae    102e28 <spinlock_check+0x2fb>
  102e04:	c7 44 24 0c 10 ad 10 	movl   $0x10ad10,0xc(%esp)
  102e0b:	00 
  102e0c:	c7 44 24 08 2a ac 10 	movl   $0x10ac2a,0x8(%esp)
  102e13:	00 
  102e14:	c7 44 24 04 67 00 00 	movl   $0x67,0x4(%esp)
  102e1b:	00 
  102e1c:	c7 04 24 6d ac 10 00 	movl   $0x10ac6d,(%esp)
  102e23:	e8 10 db ff ff       	call   100938 <debug_panic>
					(uint32_t)spinlock_godeep);
				assert(locks[i].eips[j] <
  102e28:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  102e2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102e2e:	01 c0                	add    %eax,%eax
  102e30:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102e37:	29 c2                	sub    %eax,%edx
  102e39:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102e3c:	01 d0                	add    %edx,%eax
  102e3e:	83 c0 04             	add    $0x4,%eax
  102e41:	8b 04 81             	mov    (%ecx,%eax,4),%eax
  102e44:	ba f1 2a 10 00       	mov    $0x102af1,%edx
  102e49:	83 c2 64             	add    $0x64,%edx
  102e4c:	39 d0                	cmp    %edx,%eax
  102e4e:	72 24                	jb     102e74 <spinlock_check+0x347>
  102e50:	c7 44 24 0c 40 ad 10 	movl   $0x10ad40,0xc(%esp)
  102e57:	00 
  102e58:	c7 44 24 08 2a ac 10 	movl   $0x10ac2a,0x8(%esp)
  102e5f:	00 
  102e60:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  102e67:	00 
  102e68:	c7 04 24 6d ac 10 00 	movl   $0x10ac6d,(%esp)
  102e6f:	e8 c4 da ff ff       	call   100938 <debug_panic>
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  102e74:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  102e78:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102e7b:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  102e7e:	7f 0a                	jg     102e8a <spinlock_check+0x35d>
  102e80:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  102e84:	0f 8e 55 ff ff ff    	jle    102ddf <spinlock_check+0x2b2>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  102e8a:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102e8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102e91:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102e94:	0f 8c 39 ff ff ff    	jl     102dd3 <spinlock_check+0x2a6>
					(uint32_t)spinlock_godeep+100);
			}
		}

		// Release all locks
		for(i=0;i<NUMLOCKS;i++) spinlock_release(&locks[i]);
  102e9a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102ea1:	eb 20                	jmp    102ec3 <spinlock_check+0x396>
  102ea3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ea6:	c1 e0 03             	shl    $0x3,%eax
  102ea9:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102eb0:	29 c2                	sub    %eax,%edx
  102eb2:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102eb5:	01 d0                	add    %edx,%eax
  102eb7:	89 04 24             	mov    %eax,(%esp)
  102eba:	e8 a7 fb ff ff       	call   102a66 <spinlock_release>
  102ebf:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102ec3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102ec6:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102ec9:	7c d8                	jl     102ea3 <spinlock_check+0x376>
		// Make sure that the CPU has been cleared
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
  102ecb:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102ed2:	eb 46                	jmp    102f1a <spinlock_check+0x3ed>
  102ed4:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  102ed7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102eda:	c1 e0 03             	shl    $0x3,%eax
  102edd:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102ee4:	29 c2                	sub    %eax,%edx
  102ee6:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  102ee9:	83 c0 0c             	add    $0xc,%eax
  102eec:	8b 00                	mov    (%eax),%eax
  102eee:	85 c0                	test   %eax,%eax
  102ef0:	74 24                	je     102f16 <spinlock_check+0x3e9>
  102ef2:	c7 44 24 0c 71 ad 10 	movl   $0x10ad71,0xc(%esp)
  102ef9:	00 
  102efa:	c7 44 24 08 2a ac 10 	movl   $0x10ac2a,0x8(%esp)
  102f01:	00 
  102f02:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
  102f09:	00 
  102f0a:	c7 04 24 6d ac 10 00 	movl   $0x10ac6d,(%esp)
  102f11:	e8 22 da ff ff       	call   100938 <debug_panic>
  102f16:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102f1a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f1d:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102f20:	7c b2                	jl     102ed4 <spinlock_check+0x3a7>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
  102f22:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102f29:	eb 46                	jmp    102f71 <spinlock_check+0x444>
  102f2b:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  102f2e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f31:	c1 e0 03             	shl    $0x3,%eax
  102f34:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102f3b:	29 c2                	sub    %eax,%edx
  102f3d:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  102f40:	83 c0 10             	add    $0x10,%eax
  102f43:	8b 00                	mov    (%eax),%eax
  102f45:	85 c0                	test   %eax,%eax
  102f47:	74 24                	je     102f6d <spinlock_check+0x440>
  102f49:	c7 44 24 0c 86 ad 10 	movl   $0x10ad86,0xc(%esp)
  102f50:	00 
  102f51:	c7 44 24 08 2a ac 10 	movl   $0x10ac2a,0x8(%esp)
  102f58:	00 
  102f59:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
  102f60:	00 
  102f61:	c7 04 24 6d ac 10 00 	movl   $0x10ac6d,(%esp)
  102f68:	e8 cb d9 ff ff       	call   100938 <debug_panic>
  102f6d:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102f71:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f74:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102f77:	7c b2                	jl     102f2b <spinlock_check+0x3fe>
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
  102f79:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  102f80:	eb 48                	jmp    102fca <spinlock_check+0x49d>
  102f82:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102f85:	c1 e0 03             	shl    $0x3,%eax
  102f88:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102f8f:	29 c2                	sub    %eax,%edx
  102f91:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102f94:	01 d0                	add    %edx,%eax
  102f96:	89 04 24             	mov    %eax,(%esp)
  102f99:	e8 22 fb ff ff       	call   102ac0 <spinlock_holding>
  102f9e:	85 c0                	test   %eax,%eax
  102fa0:	74 24                	je     102fc6 <spinlock_check+0x499>
  102fa2:	c7 44 24 0c 9c ad 10 	movl   $0x10ad9c,0xc(%esp)
  102fa9:	00 
  102faa:	c7 44 24 08 2a ac 10 	movl   $0x10ac2a,0x8(%esp)
  102fb1:	00 
  102fb2:	c7 44 24 04 73 00 00 	movl   $0x73,0x4(%esp)
  102fb9:	00 
  102fba:	c7 04 24 6d ac 10 00 	movl   $0x10ac6d,(%esp)
  102fc1:	e8 72 d9 ff ff       	call   100938 <debug_panic>
  102fc6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  102fca:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102fcd:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  102fd0:	7c b0                	jl     102f82 <spinlock_check+0x455>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
  102fd2:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  102fd6:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102fd9:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  102fdc:	0f 8c f8 fc ff ff    	jl     102cda <spinlock_check+0x1ad>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
	}
	cprintf("spinlock_check() succeeded!\n");
  102fe2:	c7 04 24 bd ad 10 00 	movl   $0x10adbd,(%esp)
  102fe9:	e8 e2 68 00 00       	call   1098d0 <cprintf>
  102fee:	89 dc                	mov    %ebx,%esp
}
  102ff0:	8d 65 f8             	lea    -0x8(%ebp),%esp
  102ff3:	5b                   	pop    %ebx
  102ff4:	5e                   	pop    %esi
  102ff5:	5d                   	pop    %ebp
  102ff6:	c3                   	ret    
  102ff7:	90                   	nop

00102ff8 <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  102ff8:	55                   	push   %ebp
  102ff9:	89 e5                	mov    %esp,%ebp
  102ffb:	53                   	push   %ebx
  102ffc:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
	       "+m" (*addr), "=a" (result) :
  102fff:	8b 55 08             	mov    0x8(%ebp),%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  103002:	8b 45 0c             	mov    0xc(%ebp),%eax
	       "+m" (*addr), "=a" (result) :
  103005:	8b 4d 08             	mov    0x8(%ebp),%ecx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  103008:	89 c3                	mov    %eax,%ebx
  10300a:	89 d8                	mov    %ebx,%eax
  10300c:	f0 87 02             	lock xchg %eax,(%edx)
  10300f:	89 c3                	mov    %eax,%ebx
  103011:	89 5d f8             	mov    %ebx,-0x8(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  103014:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  103017:	83 c4 10             	add    $0x10,%esp
  10301a:	5b                   	pop    %ebx
  10301b:	5d                   	pop    %ebp
  10301c:	c3                   	ret    

0010301d <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  10301d:	55                   	push   %ebp
  10301e:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  103020:	8b 45 08             	mov    0x8(%ebp),%eax
  103023:	8b 55 0c             	mov    0xc(%ebp),%edx
  103026:	8b 4d 08             	mov    0x8(%ebp),%ecx
  103029:	f0 01 10             	lock add %edx,(%eax)
}
  10302c:	5d                   	pop    %ebp
  10302d:	c3                   	ret    

0010302e <pause>:
	return result;
}

static inline void
pause(void)
{
  10302e:	55                   	push   %ebp
  10302f:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  103031:	f3 90                	pause  
}
  103033:	5d                   	pop    %ebp
  103034:	c3                   	ret    

00103035 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  103035:	55                   	push   %ebp
  103036:	89 e5                	mov    %esp,%ebp
  103038:	53                   	push   %ebx
  103039:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10303c:	89 e3                	mov    %esp,%ebx
  10303e:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  103041:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  103044:	89 45 f4             	mov    %eax,-0xc(%ebp)
  103047:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10304a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10304f:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  103052:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103055:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10305b:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  103060:	74 24                	je     103086 <cpu_cur+0x51>
  103062:	c7 44 24 0c dc ad 10 	movl   $0x10addc,0xc(%esp)
  103069:	00 
  10306a:	c7 44 24 08 f2 ad 10 	movl   $0x10adf2,0x8(%esp)
  103071:	00 
  103072:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103079:	00 
  10307a:	c7 04 24 07 ae 10 00 	movl   $0x10ae07,(%esp)
  103081:	e8 b2 d8 ff ff       	call   100938 <debug_panic>
	return c;
  103086:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  103089:	83 c4 24             	add    $0x24,%esp
  10308c:	5b                   	pop    %ebx
  10308d:	5d                   	pop    %ebp
  10308e:	c3                   	ret    

0010308f <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10308f:	55                   	push   %ebp
  103090:	89 e5                	mov    %esp,%ebp
  103092:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  103095:	e8 9b ff ff ff       	call   103035 <cpu_cur>
  10309a:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  10309f:	0f 94 c0             	sete   %al
  1030a2:	0f b6 c0             	movzbl %al,%eax
}
  1030a5:	c9                   	leave  
  1030a6:	c3                   	ret    

001030a7 <proc_init>:

proc_ready_queue prq;

void
proc_init(void)
{
  1030a7:	55                   	push   %ebp
  1030a8:	89 e5                	mov    %esp,%ebp
  1030aa:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())
  1030ad:	e8 dd ff ff ff       	call   10308f <cpu_onboot>
  1030b2:	85 c0                	test   %eax,%eax
  1030b4:	74 32                	je     1030e8 <proc_init+0x41>
		return;
	// your module initialization code here
	spinlock_init(&prq.lock);
  1030b6:	c7 44 24 08 2a 00 00 	movl   $0x2a,0x8(%esp)
  1030bd:	00 
  1030be:	c7 44 24 04 14 ae 10 	movl   $0x10ae14,0x4(%esp)
  1030c5:	00 
  1030c6:	c7 04 24 a0 96 38 00 	movl   $0x3896a0,(%esp)
  1030cd:	e8 f5 f8 ff ff       	call   1029c7 <spinlock_init_>
	prq.head = prq.tail = NULL;
  1030d2:	c7 05 dc 96 38 00 00 	movl   $0x0,0x3896dc
  1030d9:	00 00 00 
  1030dc:	a1 dc 96 38 00       	mov    0x3896dc,%eax
  1030e1:	a3 d8 96 38 00       	mov    %eax,0x3896d8
  1030e6:	eb 01                	jmp    1030e9 <proc_init+0x42>

void
proc_init(void)
{
	if (!cpu_onboot())
		return;
  1030e8:	90                   	nop
	// your module initialization code here
	spinlock_init(&prq.lock);
	prq.head = prq.tail = NULL;
}
  1030e9:	c9                   	leave  
  1030ea:	c3                   	ret    

001030eb <proc_alloc>:

// Allocate and initialize a new proc as child 'cn' of parent 'p'.
// Returns NULL if no physical memory available.
proc *
proc_alloc(proc *p, uint32_t cn)
{
  1030eb:	55                   	push   %ebp
  1030ec:	89 e5                	mov    %esp,%ebp
  1030ee:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  1030f1:	e8 d5 de ff ff       	call   100fcb <mem_alloc>
  1030f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (!pi)
  1030f9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1030fd:	75 0a                	jne    103109 <proc_alloc+0x1e>
		return NULL;
  1030ff:	b8 00 00 00 00       	mov    $0x0,%eax
  103104:	e9 c4 01 00 00       	jmp    1032cd <proc_alloc+0x1e2>
  103109:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10310c:	89 45 ec             	mov    %eax,-0x14(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  10310f:	a1 50 8f 38 00       	mov    0x388f50,%eax
  103114:	83 c0 08             	add    $0x8,%eax
  103117:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  10311a:	76 15                	jbe    103131 <proc_alloc+0x46>
  10311c:	a1 50 8f 38 00       	mov    0x388f50,%eax
  103121:	8b 15 44 8f 38 00    	mov    0x388f44,%edx
  103127:	c1 e2 03             	shl    $0x3,%edx
  10312a:	01 d0                	add    %edx,%eax
  10312c:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  10312f:	72 24                	jb     103155 <proc_alloc+0x6a>
  103131:	c7 44 24 0c 20 ae 10 	movl   $0x10ae20,0xc(%esp)
  103138:	00 
  103139:	c7 44 24 08 f2 ad 10 	movl   $0x10adf2,0x8(%esp)
  103140:	00 
  103141:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  103148:	00 
  103149:	c7 04 24 57 ae 10 00 	movl   $0x10ae57,(%esp)
  103150:	e8 e3 d7 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  103155:	a1 50 8f 38 00       	mov    0x388f50,%eax
  10315a:	ba 00 b0 38 00       	mov    $0x38b000,%edx
  10315f:	c1 ea 0c             	shr    $0xc,%edx
  103162:	c1 e2 03             	shl    $0x3,%edx
  103165:	01 d0                	add    %edx,%eax
  103167:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  10316a:	75 24                	jne    103190 <proc_alloc+0xa5>
  10316c:	c7 44 24 0c 64 ae 10 	movl   $0x10ae64,0xc(%esp)
  103173:	00 
  103174:	c7 44 24 08 f2 ad 10 	movl   $0x10adf2,0x8(%esp)
  10317b:	00 
  10317c:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  103183:	00 
  103184:	c7 04 24 57 ae 10 00 	movl   $0x10ae57,(%esp)
  10318b:	e8 a8 d7 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  103190:	a1 50 8f 38 00       	mov    0x388f50,%eax
  103195:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  10319a:	c1 ea 0c             	shr    $0xc,%edx
  10319d:	c1 e2 03             	shl    $0x3,%edx
  1031a0:	01 d0                	add    %edx,%eax
  1031a2:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  1031a5:	72 3b                	jb     1031e2 <proc_alloc+0xf7>
  1031a7:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1031ac:	ba 07 c0 38 00       	mov    $0x38c007,%edx
  1031b1:	c1 ea 0c             	shr    $0xc,%edx
  1031b4:	c1 e2 03             	shl    $0x3,%edx
  1031b7:	01 d0                	add    %edx,%eax
  1031b9:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  1031bc:	77 24                	ja     1031e2 <proc_alloc+0xf7>
  1031be:	c7 44 24 0c 80 ae 10 	movl   $0x10ae80,0xc(%esp)
  1031c5:	00 
  1031c6:	c7 44 24 08 f2 ad 10 	movl   $0x10adf2,0x8(%esp)
  1031cd:	00 
  1031ce:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  1031d5:	00 
  1031d6:	c7 04 24 57 ae 10 00 	movl   $0x10ae57,(%esp)
  1031dd:	e8 56 d7 ff ff       	call   100938 <debug_panic>

	lockadd(&pi->refcount, 1);
  1031e2:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1031e5:	83 c0 04             	add    $0x4,%eax
  1031e8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1031ef:	00 
  1031f0:	89 04 24             	mov    %eax,(%esp)
  1031f3:	e8 25 fe ff ff       	call   10301d <lockadd>
	mem_incref(pi);

	proc *cp = (proc*)mem_pi2ptr(pi);
  1031f8:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1031fb:	a1 50 8f 38 00       	mov    0x388f50,%eax
  103200:	89 d1                	mov    %edx,%ecx
  103202:	29 c1                	sub    %eax,%ecx
  103204:	89 c8                	mov    %ecx,%eax
  103206:	c1 f8 03             	sar    $0x3,%eax
  103209:	c1 e0 0c             	shl    $0xc,%eax
  10320c:	89 45 f0             	mov    %eax,-0x10(%ebp)
	memset(cp, 0, sizeof(proc));
  10320f:	c7 44 24 08 10 07 00 	movl   $0x710,0x8(%esp)
  103216:	00 
  103217:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10321e:	00 
  10321f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103222:	89 04 24             	mov    %eax,(%esp)
  103225:	e8 17 6a 00 00       	call   109c41 <memset>
	spinlock_init(&cp->lock);
  10322a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10322d:	c7 44 24 08 3a 00 00 	movl   $0x3a,0x8(%esp)
  103234:	00 
  103235:	c7 44 24 04 14 ae 10 	movl   $0x10ae14,0x4(%esp)
  10323c:	00 
  10323d:	89 04 24             	mov    %eax,(%esp)
  103240:	e8 82 f7 ff ff       	call   1029c7 <spinlock_init_>
	cp->parent = p;
  103245:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103248:	8b 55 08             	mov    0x8(%ebp),%edx
  10324b:	89 50 38             	mov    %edx,0x38(%eax)
	cp->state = PROC_STOP;
  10324e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103251:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  103258:	00 00 00 

	// Integer register state
	cp->sv.tf.ds = CPU_GDT_UDATA | 3;
  10325b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10325e:	66 c7 80 dc 04 00 00 	movw   $0x23,0x4dc(%eax)
  103265:	23 00 
	cp->sv.tf.es = CPU_GDT_UDATA | 3;
  103267:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10326a:	66 c7 80 d8 04 00 00 	movw   $0x23,0x4d8(%eax)
  103271:	23 00 
	cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  103273:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103276:	66 c7 80 ec 04 00 00 	movw   $0x1b,0x4ec(%eax)
  10327d:	1b 00 
	cp->sv.tf.ss = CPU_GDT_UDATA | 3;
  10327f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103282:	66 c7 80 f8 04 00 00 	movw   $0x23,0x4f8(%eax)
  103289:	23 00 
	cp->sv.tf.eflags = FL_IF;
  10328b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10328e:	c7 80 f0 04 00 00 00 	movl   $0x200,0x4f0(%eax)
  103295:	02 00 00 
	cp->pdir = pmap_newpdir();
  103298:	e8 0a 17 00 00       	call   1049a7 <pmap_newpdir>
  10329d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1032a0:	89 82 00 07 00 00    	mov    %eax,0x700(%edx)
	cp->rpdir = pmap_newpdir();
  1032a6:	e8 fc 16 00 00       	call   1049a7 <pmap_newpdir>
  1032ab:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1032ae:	89 82 04 07 00 00    	mov    %eax,0x704(%edx)
	if (p)
  1032b4:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  1032b8:	74 10                	je     1032ca <proc_alloc+0x1df>
		p->child[cn] = cp;
  1032ba:	8b 45 08             	mov    0x8(%ebp),%eax
  1032bd:	8b 55 0c             	mov    0xc(%ebp),%edx
  1032c0:	8d 4a 0c             	lea    0xc(%edx),%ecx
  1032c3:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1032c6:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
	return cp;
  1032ca:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1032cd:	c9                   	leave  
  1032ce:	c3                   	ret    

001032cf <proc_ready>:

// Put process p in the ready state and add it to the ready queue.
void
proc_ready(proc *p)
{
  1032cf:	55                   	push   %ebp
  1032d0:	89 e5                	mov    %esp,%ebp
  1032d2:	83 ec 18             	sub    $0x18,%esp
	assert(p->state != PROC_READY);
  1032d5:	8b 45 08             	mov    0x8(%ebp),%eax
  1032d8:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  1032de:	83 f8 01             	cmp    $0x1,%eax
  1032e1:	75 24                	jne    103307 <proc_ready+0x38>
  1032e3:	c7 44 24 0c b1 ae 10 	movl   $0x10aeb1,0xc(%esp)
  1032ea:	00 
  1032eb:	c7 44 24 08 f2 ad 10 	movl   $0x10adf2,0x8(%esp)
  1032f2:	00 
  1032f3:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
  1032fa:	00 
  1032fb:	c7 04 24 14 ae 10 00 	movl   $0x10ae14,(%esp)
  103302:	e8 31 d6 ff ff       	call   100938 <debug_panic>
	spinlock_acquire(&p->lock);
  103307:	8b 45 08             	mov    0x8(%ebp),%eax
  10330a:	89 04 24             	mov    %eax,(%esp)
  10330d:	e8 df f6 ff ff       	call   1029f1 <spinlock_acquire>
	p->state = PROC_READY;
  103312:	8b 45 08             	mov    0x8(%ebp),%eax
  103315:	c7 80 3c 04 00 00 01 	movl   $0x1,0x43c(%eax)
  10331c:	00 00 00 
	p->readynext = NULL;
  10331f:	8b 45 08             	mov    0x8(%ebp),%eax
  103322:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  103329:	00 00 00 
	spinlock_release(&p->lock);
  10332c:	8b 45 08             	mov    0x8(%ebp),%eax
  10332f:	89 04 24             	mov    %eax,(%esp)
  103332:	e8 2f f7 ff ff       	call   102a66 <spinlock_release>

	spinlock_acquire(&prq.lock);
  103337:	c7 04 24 a0 96 38 00 	movl   $0x3896a0,(%esp)
  10333e:	e8 ae f6 ff ff       	call   1029f1 <spinlock_acquire>
	if(prq.head == NULL || prq.tail == NULL){
  103343:	a1 d8 96 38 00       	mov    0x3896d8,%eax
  103348:	85 c0                	test   %eax,%eax
  10334a:	74 09                	je     103355 <proc_ready+0x86>
  10334c:	a1 dc 96 38 00       	mov    0x3896dc,%eax
  103351:	85 c0                	test   %eax,%eax
  103353:	75 14                	jne    103369 <proc_ready+0x9a>
		prq.head = prq.tail = p;
  103355:	8b 45 08             	mov    0x8(%ebp),%eax
  103358:	a3 dc 96 38 00       	mov    %eax,0x3896dc
  10335d:	a1 dc 96 38 00       	mov    0x3896dc,%eax
  103362:	a3 d8 96 38 00       	mov    %eax,0x3896d8
  103367:	eb 16                	jmp    10337f <proc_ready+0xb0>
	}
	else{
		prq.tail->readynext = p;
  103369:	a1 dc 96 38 00       	mov    0x3896dc,%eax
  10336e:	8b 55 08             	mov    0x8(%ebp),%edx
  103371:	89 90 40 04 00 00    	mov    %edx,0x440(%eax)
		prq.tail = p;
  103377:	8b 45 08             	mov    0x8(%ebp),%eax
  10337a:	a3 dc 96 38 00       	mov    %eax,0x3896dc
	}
	spinlock_release(&prq.lock);
  10337f:	c7 04 24 a0 96 38 00 	movl   $0x3896a0,(%esp)
  103386:	e8 db f6 ff ff       	call   102a66 <spinlock_release>
}
  10338b:	c9                   	leave  
  10338c:	c3                   	ret    

0010338d <proc_save>:
//	-1	if we entered the kernel via a trap before executing an insn
//	0	if we entered via a syscall and must abort/rollback the syscall
//	1	if we entered via a syscall and are completing the syscall
void
proc_save(proc *p, trapframe *tf, int entry)
{
  10338d:	55                   	push   %ebp
  10338e:	89 e5                	mov    %esp,%ebp
  103390:	83 ec 18             	sub    $0x18,%esp
	spinlock_acquire(&p->lock);
  103393:	8b 45 08             	mov    0x8(%ebp),%eax
  103396:	89 04 24             	mov    %eax,(%esp)
  103399:	e8 53 f6 ff ff       	call   1029f1 <spinlock_acquire>
	switch(entry){
  10339e:	8b 45 10             	mov    0x10(%ebp),%eax
  1033a1:	85 c0                	test   %eax,%eax
  1033a3:	74 2c                	je     1033d1 <proc_save+0x44>
  1033a5:	83 f8 01             	cmp    $0x1,%eax
  1033a8:	74 36                	je     1033e0 <proc_save+0x53>
  1033aa:	83 f8 ff             	cmp    $0xffffffff,%eax
  1033ad:	75 52                	jne    103401 <proc_save+0x74>
		case -1:
			memmove(&p->sv.tf, tf, sizeof(trapframe));
  1033af:	8b 45 08             	mov    0x8(%ebp),%eax
  1033b2:	8d 90 b0 04 00 00    	lea    0x4b0(%eax),%edx
  1033b8:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  1033bf:	00 
  1033c0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1033c3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1033c7:	89 14 24             	mov    %edx,(%esp)
  1033ca:	e8 e0 68 00 00       	call   109caf <memmove>
			break;
  1033cf:	eb 30                	jmp    103401 <proc_save+0x74>
		case 0:
			tf->eip = (uintptr_t)((int*)tf->eip - 2);
  1033d1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1033d4:	8b 40 38             	mov    0x38(%eax),%eax
  1033d7:	8d 50 f8             	lea    -0x8(%eax),%edx
  1033da:	8b 45 0c             	mov    0xc(%ebp),%eax
  1033dd:	89 50 38             	mov    %edx,0x38(%eax)
		case 1:
			memmove(&p->sv.tf, tf, sizeof(trapframe));
  1033e0:	8b 45 08             	mov    0x8(%ebp),%eax
  1033e3:	8d 90 b0 04 00 00    	lea    0x4b0(%eax),%edx
  1033e9:	c7 44 24 08 4c 00 00 	movl   $0x4c,0x8(%esp)
  1033f0:	00 
  1033f1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1033f4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1033f8:	89 14 24             	mov    %edx,(%esp)
  1033fb:	e8 af 68 00 00       	call   109caf <memmove>
			break;
  103400:	90                   	nop
	}
	spinlock_release(&p->lock);
  103401:	8b 45 08             	mov    0x8(%ebp),%eax
  103404:	89 04 24             	mov    %eax,(%esp)
  103407:	e8 5a f6 ff ff       	call   102a66 <spinlock_release>
}
  10340c:	c9                   	leave  
  10340d:	c3                   	ret    

0010340e <proc_wait>:
// Go to sleep waiting for a given child process to finish running.
// Parent process 'p' must be running and locked on entry.
// The supplied trapframe represents p's register state on syscall entry.
void gcc_noreturn
proc_wait(proc *p, proc *cp, trapframe *tf)
{
  10340e:	55                   	push   %ebp
  10340f:	89 e5                	mov    %esp,%ebp
  103411:	83 ec 18             	sub    $0x18,%esp
	spinlock_acquire(&p->lock);
  103414:	8b 45 08             	mov    0x8(%ebp),%eax
  103417:	89 04 24             	mov    %eax,(%esp)
  10341a:	e8 d2 f5 ff ff       	call   1029f1 <spinlock_acquire>
	p->state = PROC_WAIT;
  10341f:	8b 45 08             	mov    0x8(%ebp),%eax
  103422:	c7 80 3c 04 00 00 03 	movl   $0x3,0x43c(%eax)
  103429:	00 00 00 
	p->waitchild = cp;
  10342c:	8b 45 08             	mov    0x8(%ebp),%eax
  10342f:	8b 55 0c             	mov    0xc(%ebp),%edx
  103432:	89 90 48 04 00 00    	mov    %edx,0x448(%eax)
	spinlock_release(&p->lock);
  103438:	8b 45 08             	mov    0x8(%ebp),%eax
  10343b:	89 04 24             	mov    %eax,(%esp)
  10343e:	e8 23 f6 ff ff       	call   102a66 <spinlock_release>

	proc_save(p, tf, 0);
  103443:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  10344a:	00 
  10344b:	8b 45 10             	mov    0x10(%ebp),%eax
  10344e:	89 44 24 04          	mov    %eax,0x4(%esp)
  103452:	8b 45 08             	mov    0x8(%ebp),%eax
  103455:	89 04 24             	mov    %eax,(%esp)
  103458:	e8 30 ff ff ff       	call   10338d <proc_save>

	proc_sched();
  10345d:	e8 00 00 00 00       	call   103462 <proc_sched>

00103462 <proc_sched>:
}

void gcc_noreturn
proc_sched(void)
{	
  103462:	55                   	push   %ebp
  103463:	89 e5                	mov    %esp,%ebp
  103465:	83 ec 28             	sub    $0x28,%esp
	while(!prq.head){
  103468:	eb 07                	jmp    103471 <proc_sched+0xf>

// Enable external device interrupts.
static gcc_inline void
sti(void)
{
	asm volatile("sti");
  10346a:	fb                   	sti    
		sti();
		pause();
  10346b:	e8 be fb ff ff       	call   10302e <pause>

// Disable external device interrupts.
static gcc_inline void
cli(void)
{
	asm volatile("cli");
  103470:	fa                   	cli    
}

void gcc_noreturn
proc_sched(void)
{	
	while(!prq.head){
  103471:	a1 d8 96 38 00       	mov    0x3896d8,%eax
  103476:	85 c0                	test   %eax,%eax
  103478:	74 f0                	je     10346a <proc_sched+0x8>
		sti();
		pause();
		cli();
	}
	spinlock_acquire(&prq.lock);
  10347a:	c7 04 24 a0 96 38 00 	movl   $0x3896a0,(%esp)
  103481:	e8 6b f5 ff ff       	call   1029f1 <spinlock_acquire>
	proc *cur = prq.head;
  103486:	a1 d8 96 38 00       	mov    0x3896d8,%eax
  10348b:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if(prq.head->readynext == NULL){
  10348e:	a1 d8 96 38 00       	mov    0x3896d8,%eax
  103493:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  103499:	85 c0                	test   %eax,%eax
  10349b:	75 16                	jne    1034b3 <proc_sched+0x51>
		prq.head = prq.tail = NULL;
  10349d:	c7 05 dc 96 38 00 00 	movl   $0x0,0x3896dc
  1034a4:	00 00 00 
  1034a7:	a1 dc 96 38 00       	mov    0x3896dc,%eax
  1034ac:	a3 d8 96 38 00       	mov    %eax,0x3896d8
  1034b1:	eb 10                	jmp    1034c3 <proc_sched+0x61>
	}
	else{
		prq.head = prq.head->readynext;
  1034b3:	a1 d8 96 38 00       	mov    0x3896d8,%eax
  1034b8:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  1034be:	a3 d8 96 38 00       	mov    %eax,0x3896d8
	}
	spinlock_release(&prq.lock);
  1034c3:	c7 04 24 a0 96 38 00 	movl   $0x3896a0,(%esp)
  1034ca:	e8 97 f5 ff ff       	call   102a66 <spinlock_release>
	proc_run(cur);
  1034cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1034d2:	89 04 24             	mov    %eax,(%esp)
  1034d5:	e8 00 00 00 00       	call   1034da <proc_run>

001034da <proc_run>:
}

// Switch to and run a specified process, which must already be locked.
void gcc_noreturn
proc_run(proc *p)
{
  1034da:	55                   	push   %ebp
  1034db:	89 e5                	mov    %esp,%ebp
  1034dd:	83 ec 28             	sub    $0x28,%esp
	spinlock_acquire(&p->lock);
  1034e0:	8b 45 08             	mov    0x8(%ebp),%eax
  1034e3:	89 04 24             	mov    %eax,(%esp)
  1034e6:	e8 06 f5 ff ff       	call   1029f1 <spinlock_acquire>
	p->state = PROC_RUN;
  1034eb:	8b 45 08             	mov    0x8(%ebp),%eax
  1034ee:	c7 80 3c 04 00 00 02 	movl   $0x2,0x43c(%eax)
  1034f5:	00 00 00 
	p->runcpu = cpu_cur();
  1034f8:	e8 38 fb ff ff       	call   103035 <cpu_cur>
  1034fd:	8b 55 08             	mov    0x8(%ebp),%edx
  103500:	89 82 44 04 00 00    	mov    %eax,0x444(%edx)
	lcr3(mem_phys(p->pdir));
  103506:	8b 45 08             	mov    0x8(%ebp),%eax
  103509:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  10350f:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  103512:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103515:	0f 22 d8             	mov    %eax,%cr3
	spinlock_release(&p->lock);
  103518:	8b 45 08             	mov    0x8(%ebp),%eax
  10351b:	89 04 24             	mov    %eax,(%esp)
  10351e:	e8 43 f5 ff ff       	call   102a66 <spinlock_release>
	cpu_cur()->proc = p;
  103523:	e8 0d fb ff ff       	call   103035 <cpu_cur>
  103528:	8b 55 08             	mov    0x8(%ebp),%edx
  10352b:	89 90 b4 00 00 00    	mov    %edx,0xb4(%eax)
	trap_return(&p->sv.tf);
  103531:	8b 45 08             	mov    0x8(%ebp),%eax
  103534:	05 b0 04 00 00       	add    $0x4b0,%eax
  103539:	89 04 24             	mov    %eax,(%esp)
  10353c:	e8 bf cb 00 00       	call   110100 <trap_return>

00103541 <proc_yield>:

// Yield the current CPU to another ready process.
// Called while handling a timer interrupt.
void gcc_noreturn
proc_yield(trapframe *tf)
{
  103541:	55                   	push   %ebp
  103542:	89 e5                	mov    %esp,%ebp
  103544:	83 ec 18             	sub    $0x18,%esp
	proc_save(proc_cur(), tf, 1);
  103547:	e8 e9 fa ff ff       	call   103035 <cpu_cur>
  10354c:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103552:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  103559:	00 
  10355a:	8b 55 08             	mov    0x8(%ebp),%edx
  10355d:	89 54 24 04          	mov    %edx,0x4(%esp)
  103561:	89 04 24             	mov    %eax,(%esp)
  103564:	e8 24 fe ff ff       	call   10338d <proc_save>
	proc_ready(proc_cur());
  103569:	e8 c7 fa ff ff       	call   103035 <cpu_cur>
  10356e:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103574:	89 04 24             	mov    %eax,(%esp)
  103577:	e8 53 fd ff ff       	call   1032cf <proc_ready>
	proc_sched();
  10357c:	e8 e1 fe ff ff       	call   103462 <proc_sched>

00103581 <proc_ret>:
// Used both when a process calls the SYS_RET system call explicitly,
// and when a process causes an unhandled trap in user mode.
// The 'entry' parameter is as in proc_save().
void gcc_noreturn
proc_ret(trapframe *tf, int entry)
{
  103581:	55                   	push   %ebp
  103582:	89 e5                	mov    %esp,%ebp
  103584:	83 ec 28             	sub    $0x28,%esp
	proc* cur = proc_cur();
  103587:	e8 a9 fa ff ff       	call   103035 <cpu_cur>
  10358c:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103592:	89 45 f4             	mov    %eax,-0xc(%ebp)
	spinlock_acquire(&cur->lock);
  103595:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103598:	89 04 24             	mov    %eax,(%esp)
  10359b:	e8 51 f4 ff ff       	call   1029f1 <spinlock_acquire>
	cur->state = PROC_STOP;
  1035a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1035a3:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  1035aa:	00 00 00 
	spinlock_release(&cur->lock);
  1035ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1035b0:	89 04 24             	mov    %eax,(%esp)
  1035b3:	e8 ae f4 ff ff       	call   102a66 <spinlock_release>

	proc_save(cur, tf, entry);
  1035b8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1035bb:	89 44 24 08          	mov    %eax,0x8(%esp)
  1035bf:	8b 45 08             	mov    0x8(%ebp),%eax
  1035c2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1035c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1035c9:	89 04 24             	mov    %eax,(%esp)
  1035cc:	e8 bc fd ff ff       	call   10338d <proc_save>

	if(cur->parent->waitchild == cur && cur->parent->state == PROC_WAIT){
  1035d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1035d4:	8b 40 38             	mov    0x38(%eax),%eax
  1035d7:	8b 80 48 04 00 00    	mov    0x448(%eax),%eax
  1035dd:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  1035e0:	75 1f                	jne    103601 <proc_ret+0x80>
  1035e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1035e5:	8b 40 38             	mov    0x38(%eax),%eax
  1035e8:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  1035ee:	83 f8 03             	cmp    $0x3,%eax
  1035f1:	75 0e                	jne    103601 <proc_ret+0x80>
		proc_ready(cur->parent);
  1035f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1035f6:	8b 40 38             	mov    0x38(%eax),%eax
  1035f9:	89 04 24             	mov    %eax,(%esp)
  1035fc:	e8 ce fc ff ff       	call   1032cf <proc_ready>
	}

	proc_sched();
  103601:	e8 5c fe ff ff       	call   103462 <proc_sched>

00103606 <proc_check>:
static volatile uint32_t pingpong = 0;
static void *recovargs;

void
proc_check(void)
{
  103606:	55                   	push   %ebp
  103607:	89 e5                	mov    %esp,%ebp
  103609:	57                   	push   %edi
  10360a:	56                   	push   %esi
  10360b:	53                   	push   %ebx
  10360c:	81 ec dc 00 00 00    	sub    $0xdc,%esp
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  103612:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  103619:	e9 a6 00 00 00       	jmp    1036c4 <proc_check+0xbe>
		// Setup register state for child
		uint32_t *esp = (uint32_t*) &child_stack[i][PAGESIZE];
  10361e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103621:	83 c0 01             	add    $0x1,%eax
  103624:	c1 e0 0c             	shl    $0xc,%eax
  103627:	05 90 4e 18 00       	add    $0x184e90,%eax
  10362c:	89 45 e0             	mov    %eax,-0x20(%ebp)
		*--esp = i;	// push argument to child() function
  10362f:	83 6d e0 04          	subl   $0x4,-0x20(%ebp)
  103633:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103636:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103639:	89 10                	mov    %edx,(%eax)
		*--esp = 0;	// fake return address
  10363b:	83 6d e0 04          	subl   $0x4,-0x20(%ebp)
  10363f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103642:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		child_state.tf.eip = (uint32_t) child;
  103648:	b8 7c 3a 10 00       	mov    $0x103a7c,%eax
  10364d:	a3 78 4c 18 00       	mov    %eax,0x184c78
		child_state.tf.esp = (uint32_t) esp;
  103652:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103655:	a3 84 4c 18 00       	mov    %eax,0x184c84

		// Use PUT syscall to create each child,
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);
  10365a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10365d:	89 44 24 04          	mov    %eax,0x4(%esp)
  103661:	c7 04 24 c8 ae 10 00 	movl   $0x10aec8,(%esp)
  103668:	e8 63 62 00 00       	call   1098d0 <cprintf>
		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
  10366d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103670:	0f b7 d0             	movzwl %ax,%edx
  103673:	83 7d e4 01          	cmpl   $0x1,-0x1c(%ebp)
  103677:	7f 07                	jg     103680 <proc_check+0x7a>
  103679:	b8 10 10 00 00       	mov    $0x1010,%eax
  10367e:	eb 05                	jmp    103685 <proc_check+0x7f>
  103680:	b8 00 10 00 00       	mov    $0x1000,%eax
  103685:	89 45 d8             	mov    %eax,-0x28(%ebp)
  103688:	66 89 55 d6          	mov    %dx,-0x2a(%ebp)
  10368c:	c7 45 d0 40 4c 18 00 	movl   $0x184c40,-0x30(%ebp)
  103693:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
  10369a:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
  1036a1:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  1036a8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1036ab:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  1036ae:	8b 5d d0             	mov    -0x30(%ebp),%ebx
  1036b1:	0f b7 55 d6          	movzwl -0x2a(%ebp),%edx
  1036b5:	8b 75 cc             	mov    -0x34(%ebp),%esi
  1036b8:	8b 7d c8             	mov    -0x38(%ebp),%edi
  1036bb:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
  1036be:	cd 30                	int    $0x30
proc_check(void)
{
	// Spawn 2 child processes, executing on statically allocated stacks.

	int i;
	for (i = 0; i < 4; i++) {
  1036c0:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
  1036c4:	83 7d e4 03          	cmpl   $0x3,-0x1c(%ebp)
  1036c8:	0f 8e 50 ff ff ff    	jle    10361e <proc_check+0x18>
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  1036ce:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  1036d5:	eb 5c                	jmp    103733 <proc_check+0x12d>
		cprintf("waiting for child %d\n", i);
  1036d7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1036da:	89 44 24 04          	mov    %eax,0x4(%esp)
  1036de:	c7 04 24 db ae 10 00 	movl   $0x10aedb,(%esp)
  1036e5:	e8 e6 61 00 00       	call   1098d0 <cprintf>
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  1036ea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1036ed:	0f b7 c0             	movzwl %ax,%eax
  1036f0:	c7 45 c0 00 10 00 00 	movl   $0x1000,-0x40(%ebp)
  1036f7:	66 89 45 be          	mov    %ax,-0x42(%ebp)
  1036fb:	c7 45 b8 40 4c 18 00 	movl   $0x184c40,-0x48(%ebp)
  103702:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)
  103709:	c7 45 b0 00 00 00 00 	movl   $0x0,-0x50(%ebp)
  103710:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103717:	8b 45 c0             	mov    -0x40(%ebp),%eax
  10371a:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  10371d:	8b 5d b8             	mov    -0x48(%ebp),%ebx
  103720:	0f b7 55 be          	movzwl -0x42(%ebp),%edx
  103724:	8b 75 b4             	mov    -0x4c(%ebp),%esi
  103727:	8b 7d b0             	mov    -0x50(%ebp),%edi
  10372a:	8b 4d ac             	mov    -0x54(%ebp),%ecx
  10372d:	cd 30                	int    $0x30
	}

	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  10372f:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
  103733:	83 7d e4 01          	cmpl   $0x1,-0x1c(%ebp)
  103737:	7e 9e                	jle    1036d7 <proc_check+0xd1>
		cprintf("waiting for child %d\n", i);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
	}
	cprintf("proc_check() 2-child test succeeded\n");
  103739:	c7 04 24 f4 ae 10 00 	movl   $0x10aef4,(%esp)
  103740:	e8 8b 61 00 00       	call   1098d0 <cprintf>

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
  103745:	c7 04 24 1c af 10 00 	movl   $0x10af1c,(%esp)
  10374c:	e8 7f 61 00 00       	call   1098d0 <cprintf>
	for (i = 0; i < 4; i++) {
  103751:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  103758:	eb 5c                	jmp    1037b6 <proc_check+0x1b0>
		cprintf("spawning child %d\n", i);
  10375a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10375d:	89 44 24 04          	mov    %eax,0x4(%esp)
  103761:	c7 04 24 c8 ae 10 00 	movl   $0x10aec8,(%esp)
  103768:	e8 63 61 00 00       	call   1098d0 <cprintf>
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
  10376d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103770:	0f b7 c0             	movzwl %ax,%eax
  103773:	c7 45 a8 10 00 00 00 	movl   $0x10,-0x58(%ebp)
  10377a:	66 89 45 a6          	mov    %ax,-0x5a(%ebp)
  10377e:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
  103785:	c7 45 9c 00 00 00 00 	movl   $0x0,-0x64(%ebp)
  10378c:	c7 45 98 00 00 00 00 	movl   $0x0,-0x68(%ebp)
  103793:	c7 45 94 00 00 00 00 	movl   $0x0,-0x6c(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  10379a:	8b 45 a8             	mov    -0x58(%ebp),%eax
  10379d:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  1037a0:	8b 5d a0             	mov    -0x60(%ebp),%ebx
  1037a3:	0f b7 55 a6          	movzwl -0x5a(%ebp),%edx
  1037a7:	8b 75 9c             	mov    -0x64(%ebp),%esi
  1037aa:	8b 7d 98             	mov    -0x68(%ebp),%edi
  1037ad:	8b 4d 94             	mov    -0x6c(%ebp),%ecx
  1037b0:	cd 30                	int    $0x30

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
	for (i = 0; i < 4; i++) {
  1037b2:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
  1037b6:	83 7d e4 03          	cmpl   $0x3,-0x1c(%ebp)
  1037ba:	7e 9e                	jle    10375a <proc_check+0x154>
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  1037bc:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  1037c3:	eb 4f                	jmp    103814 <proc_check+0x20e>
		sys_get(0, i, NULL, NULL, NULL, 0);
  1037c5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1037c8:	0f b7 c0             	movzwl %ax,%eax
  1037cb:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
  1037d2:	66 89 45 8e          	mov    %ax,-0x72(%ebp)
  1037d6:	c7 45 88 00 00 00 00 	movl   $0x0,-0x78(%ebp)
  1037dd:	c7 45 84 00 00 00 00 	movl   $0x0,-0x7c(%ebp)
  1037e4:	c7 45 80 00 00 00 00 	movl   $0x0,-0x80(%ebp)
  1037eb:	c7 85 7c ff ff ff 00 	movl   $0x0,-0x84(%ebp)
  1037f2:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  1037f5:	8b 45 90             	mov    -0x70(%ebp),%eax
  1037f8:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  1037fb:	8b 5d 88             	mov    -0x78(%ebp),%ebx
  1037fe:	0f b7 55 8e          	movzwl -0x72(%ebp),%edx
  103802:	8b 75 84             	mov    -0x7c(%ebp),%esi
  103805:	8b 7d 80             	mov    -0x80(%ebp),%edi
  103808:	8b 8d 7c ff ff ff    	mov    -0x84(%ebp),%ecx
  10380e:	cd 30                	int    $0x30
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  103810:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
  103814:	83 7d e4 03          	cmpl   $0x3,-0x1c(%ebp)
  103818:	7e ab                	jle    1037c5 <proc_check+0x1bf>
		sys_get(0, i, NULL, NULL, NULL, 0);
	cprintf("proc_check() 4-child test succeeded\n");
  10381a:	c7 04 24 40 af 10 00 	movl   $0x10af40,(%esp)
  103821:	e8 aa 60 00 00       	call   1098d0 <cprintf>

	// Now do a trap handling test using all 4 children -
	// but they'll _think_ they're all child 0!
	// (We'll lose the register state of the other children.)
	i = 0;
  103826:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  10382d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103830:	0f b7 c0             	movzwl %ax,%eax
  103833:	c7 85 78 ff ff ff 00 	movl   $0x1000,-0x88(%ebp)
  10383a:	10 00 00 
  10383d:	66 89 85 76 ff ff ff 	mov    %ax,-0x8a(%ebp)
  103844:	c7 85 70 ff ff ff 40 	movl   $0x184c40,-0x90(%ebp)
  10384b:	4c 18 00 
  10384e:	c7 85 6c ff ff ff 00 	movl   $0x0,-0x94(%ebp)
  103855:	00 00 00 
  103858:	c7 85 68 ff ff ff 00 	movl   $0x0,-0x98(%ebp)
  10385f:	00 00 00 
  103862:	c7 85 64 ff ff ff 00 	movl   $0x0,-0x9c(%ebp)
  103869:	00 00 00 
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  10386c:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  103872:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103875:	8b 9d 70 ff ff ff    	mov    -0x90(%ebp),%ebx
  10387b:	0f b7 95 76 ff ff ff 	movzwl -0x8a(%ebp),%edx
  103882:	8b b5 6c ff ff ff    	mov    -0x94(%ebp),%esi
  103888:	8b bd 68 ff ff ff    	mov    -0x98(%ebp),%edi
  10388e:	8b 8d 64 ff ff ff    	mov    -0x9c(%ebp),%ecx
  103894:	cd 30                	int    $0x30
		// get child 0's state
	assert(recovargs == NULL);
  103896:	a1 94 8e 18 00       	mov    0x188e94,%eax
  10389b:	85 c0                	test   %eax,%eax
  10389d:	74 24                	je     1038c3 <proc_check+0x2bd>
  10389f:	c7 44 24 0c 65 af 10 	movl   $0x10af65,0xc(%esp)
  1038a6:	00 
  1038a7:	c7 44 24 08 f2 ad 10 	movl   $0x10adf2,0x8(%esp)
  1038ae:	00 
  1038af:	c7 44 24 04 04 01 00 	movl   $0x104,0x4(%esp)
  1038b6:	00 
  1038b7:	c7 04 24 14 ae 10 00 	movl   $0x10ae14,(%esp)
  1038be:	e8 75 d0 ff ff       	call   100938 <debug_panic>
	do {
		sys_put(SYS_REGS | SYS_START, i, &child_state, NULL, NULL, 0);
  1038c3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1038c6:	0f b7 c0             	movzwl %ax,%eax
  1038c9:	c7 85 60 ff ff ff 10 	movl   $0x1010,-0xa0(%ebp)
  1038d0:	10 00 00 
  1038d3:	66 89 85 5e ff ff ff 	mov    %ax,-0xa2(%ebp)
  1038da:	c7 85 58 ff ff ff 40 	movl   $0x184c40,-0xa8(%ebp)
  1038e1:	4c 18 00 
  1038e4:	c7 85 54 ff ff ff 00 	movl   $0x0,-0xac(%ebp)
  1038eb:	00 00 00 
  1038ee:	c7 85 50 ff ff ff 00 	movl   $0x0,-0xb0(%ebp)
  1038f5:	00 00 00 
  1038f8:	c7 85 4c ff ff ff 00 	movl   $0x0,-0xb4(%ebp)
  1038ff:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  103902:	8b 85 60 ff ff ff    	mov    -0xa0(%ebp),%eax
  103908:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  10390b:	8b 9d 58 ff ff ff    	mov    -0xa8(%ebp),%ebx
  103911:	0f b7 95 5e ff ff ff 	movzwl -0xa2(%ebp),%edx
  103918:	8b b5 54 ff ff ff    	mov    -0xac(%ebp),%esi
  10391e:	8b bd 50 ff ff ff    	mov    -0xb0(%ebp),%edi
  103924:	8b 8d 4c ff ff ff    	mov    -0xb4(%ebp),%ecx
  10392a:	cd 30                	int    $0x30
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  10392c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10392f:	0f b7 c0             	movzwl %ax,%eax
  103932:	c7 85 48 ff ff ff 00 	movl   $0x1000,-0xb8(%ebp)
  103939:	10 00 00 
  10393c:	66 89 85 46 ff ff ff 	mov    %ax,-0xba(%ebp)
  103943:	c7 85 40 ff ff ff 40 	movl   $0x184c40,-0xc0(%ebp)
  10394a:	4c 18 00 
  10394d:	c7 85 3c ff ff ff 00 	movl   $0x0,-0xc4(%ebp)
  103954:	00 00 00 
  103957:	c7 85 38 ff ff ff 00 	movl   $0x0,-0xc8(%ebp)
  10395e:	00 00 00 
  103961:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103968:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  10396b:	8b 85 48 ff ff ff    	mov    -0xb8(%ebp),%eax
  103971:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103974:	8b 9d 40 ff ff ff    	mov    -0xc0(%ebp),%ebx
  10397a:	0f b7 95 46 ff ff ff 	movzwl -0xba(%ebp),%edx
  103981:	8b b5 3c ff ff ff    	mov    -0xc4(%ebp),%esi
  103987:	8b bd 38 ff ff ff    	mov    -0xc8(%ebp),%edi
  10398d:	8b 8d 34 ff ff ff    	mov    -0xcc(%ebp),%ecx
  103993:	cd 30                	int    $0x30
		if (recovargs) {	// trap recovery needed
  103995:	a1 94 8e 18 00       	mov    0x188e94,%eax
  10399a:	85 c0                	test   %eax,%eax
  10399c:	74 36                	je     1039d4 <proc_check+0x3ce>
			trap_check_args *args = recovargs;
  10399e:	a1 94 8e 18 00       	mov    0x188e94,%eax
  1039a3:	89 45 dc             	mov    %eax,-0x24(%ebp)
			cprintf("recover from trap %d\n",
  1039a6:	a1 70 4c 18 00       	mov    0x184c70,%eax
  1039ab:	89 44 24 04          	mov    %eax,0x4(%esp)
  1039af:	c7 04 24 77 af 10 00 	movl   $0x10af77,(%esp)
  1039b6:	e8 15 5f 00 00       	call   1098d0 <cprintf>
				child_state.tf.trapno);
			child_state.tf.eip = (uint32_t) args->reip;
  1039bb:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1039be:	8b 00                	mov    (%eax),%eax
  1039c0:	a3 78 4c 18 00       	mov    %eax,0x184c78
			args->trapno = child_state.tf.trapno;
  1039c5:	a1 70 4c 18 00       	mov    0x184c70,%eax
  1039ca:	89 c2                	mov    %eax,%edx
  1039cc:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1039cf:	89 50 04             	mov    %edx,0x4(%eax)
  1039d2:	eb 2e                	jmp    103a02 <proc_check+0x3fc>
		} else
			assert(child_state.tf.trapno == T_SYSCALL);
  1039d4:	a1 70 4c 18 00       	mov    0x184c70,%eax
  1039d9:	83 f8 30             	cmp    $0x30,%eax
  1039dc:	74 24                	je     103a02 <proc_check+0x3fc>
  1039de:	c7 44 24 0c 90 af 10 	movl   $0x10af90,0xc(%esp)
  1039e5:	00 
  1039e6:	c7 44 24 08 f2 ad 10 	movl   $0x10adf2,0x8(%esp)
  1039ed:	00 
  1039ee:	c7 44 24 04 0f 01 00 	movl   $0x10f,0x4(%esp)
  1039f5:	00 
  1039f6:	c7 04 24 14 ae 10 00 	movl   $0x10ae14,(%esp)
  1039fd:	e8 36 cf ff ff       	call   100938 <debug_panic>
		i = (i+1) % 4;	// rotate to next child proc
  103a02:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103a05:	8d 50 01             	lea    0x1(%eax),%edx
  103a08:	89 d0                	mov    %edx,%eax
  103a0a:	c1 f8 1f             	sar    $0x1f,%eax
  103a0d:	c1 e8 1e             	shr    $0x1e,%eax
  103a10:	01 c2                	add    %eax,%edx
  103a12:	83 e2 03             	and    $0x3,%edx
  103a15:	89 d1                	mov    %edx,%ecx
  103a17:	29 c1                	sub    %eax,%ecx
  103a19:	89 c8                	mov    %ecx,%eax
  103a1b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	} while (child_state.tf.trapno != T_SYSCALL);
  103a1e:	a1 70 4c 18 00       	mov    0x184c70,%eax
  103a23:	83 f8 30             	cmp    $0x30,%eax
  103a26:	0f 85 97 fe ff ff    	jne    1038c3 <proc_check+0x2bd>
	assert(recovargs == NULL);
  103a2c:	a1 94 8e 18 00       	mov    0x188e94,%eax
  103a31:	85 c0                	test   %eax,%eax
  103a33:	74 24                	je     103a59 <proc_check+0x453>
  103a35:	c7 44 24 0c 65 af 10 	movl   $0x10af65,0xc(%esp)
  103a3c:	00 
  103a3d:	c7 44 24 08 f2 ad 10 	movl   $0x10adf2,0x8(%esp)
  103a44:	00 
  103a45:	c7 44 24 04 12 01 00 	movl   $0x112,0x4(%esp)
  103a4c:	00 
  103a4d:	c7 04 24 14 ae 10 00 	movl   $0x10ae14,(%esp)
  103a54:	e8 df ce ff ff       	call   100938 <debug_panic>

	cprintf("proc_check() trap reflection test succeeded\n");
  103a59:	c7 04 24 b4 af 10 00 	movl   $0x10afb4,(%esp)
  103a60:	e8 6b 5e 00 00       	call   1098d0 <cprintf>

	cprintf("proc_check() succeeded!\n");
  103a65:	c7 04 24 e1 af 10 00 	movl   $0x10afe1,(%esp)
  103a6c:	e8 5f 5e 00 00       	call   1098d0 <cprintf>
}
  103a71:	81 c4 dc 00 00 00    	add    $0xdc,%esp
  103a77:	5b                   	pop    %ebx
  103a78:	5e                   	pop    %esi
  103a79:	5f                   	pop    %edi
  103a7a:	5d                   	pop    %ebp
  103a7b:	c3                   	ret    

00103a7c <child>:

static void child(int n)
{
  103a7c:	55                   	push   %ebp
  103a7d:	89 e5                	mov    %esp,%ebp
  103a7f:	83 ec 28             	sub    $0x28,%esp
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
  103a82:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
  103a86:	7f 64                	jg     103aec <child+0x70>
		int i;
		for (i = 0; i < 10; i++) {
  103a88:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  103a8f:	eb 4e                	jmp    103adf <child+0x63>
			cprintf("in child %d count %d\n", n, i);
  103a91:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a94:	89 44 24 08          	mov    %eax,0x8(%esp)
  103a98:	8b 45 08             	mov    0x8(%ebp),%eax
  103a9b:	89 44 24 04          	mov    %eax,0x4(%esp)
  103a9f:	c7 04 24 fa af 10 00 	movl   $0x10affa,(%esp)
  103aa6:	e8 25 5e 00 00       	call   1098d0 <cprintf>
			while (pingpong != n)
  103aab:	eb 05                	jmp    103ab2 <child+0x36>
				pause();
  103aad:	e8 7c f5 ff ff       	call   10302e <pause>
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
			cprintf("in child %d count %d\n", n, i);
			while (pingpong != n)
  103ab2:	8b 55 08             	mov    0x8(%ebp),%edx
  103ab5:	a1 90 8e 18 00       	mov    0x188e90,%eax
  103aba:	39 c2                	cmp    %eax,%edx
  103abc:	75 ef                	jne    103aad <child+0x31>
				pause();
			xchg(&pingpong, !pingpong);
  103abe:	a1 90 8e 18 00       	mov    0x188e90,%eax
  103ac3:	85 c0                	test   %eax,%eax
  103ac5:	0f 94 c0             	sete   %al
  103ac8:	0f b6 c0             	movzbl %al,%eax
  103acb:	89 44 24 04          	mov    %eax,0x4(%esp)
  103acf:	c7 04 24 90 8e 18 00 	movl   $0x188e90,(%esp)
  103ad6:	e8 1d f5 ff ff       	call   102ff8 <xchg>
static void child(int n)
{
	// Only first 2 children participate in first pingpong test
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
  103adb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  103adf:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  103ae3:	7e ac                	jle    103a91 <child+0x15>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  103ae5:	b8 03 00 00 00       	mov    $0x3,%eax
  103aea:	cd 30                	int    $0x30
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  103aec:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  103af3:	eb 4c                	jmp    103b41 <child+0xc5>
		cprintf("in child %d count %d\n", n, i);
  103af5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103af8:	89 44 24 08          	mov    %eax,0x8(%esp)
  103afc:	8b 45 08             	mov    0x8(%ebp),%eax
  103aff:	89 44 24 04          	mov    %eax,0x4(%esp)
  103b03:	c7 04 24 fa af 10 00 	movl   $0x10affa,(%esp)
  103b0a:	e8 c1 5d 00 00       	call   1098d0 <cprintf>
		while (pingpong != n)
  103b0f:	eb 05                	jmp    103b16 <child+0x9a>
			pause();
  103b11:	e8 18 f5 ff ff       	call   10302e <pause>

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
		cprintf("in child %d count %d\n", n, i);
		while (pingpong != n)
  103b16:	8b 55 08             	mov    0x8(%ebp),%edx
  103b19:	a1 90 8e 18 00       	mov    0x188e90,%eax
  103b1e:	39 c2                	cmp    %eax,%edx
  103b20:	75 ef                	jne    103b11 <child+0x95>
			pause();
		xchg(&pingpong, (pingpong + 1) % 4);
  103b22:	a1 90 8e 18 00       	mov    0x188e90,%eax
  103b27:	83 c0 01             	add    $0x1,%eax
  103b2a:	83 e0 03             	and    $0x3,%eax
  103b2d:	89 44 24 04          	mov    %eax,0x4(%esp)
  103b31:	c7 04 24 90 8e 18 00 	movl   $0x188e90,(%esp)
  103b38:	e8 bb f4 ff ff       	call   102ff8 <xchg>
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  103b3d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  103b41:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  103b45:	7e ae                	jle    103af5 <child+0x79>
  103b47:	b8 03 00 00 00       	mov    $0x3,%eax
  103b4c:	cd 30                	int    $0x30
		xchg(&pingpong, (pingpong + 1) % 4);
	}
	sys_ret();

	// Only "child 0" (or the proc that thinks it's child 0), trap check...
	if (n == 0) {
  103b4e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  103b52:	75 6d                	jne    103bc1 <child+0x145>
		assert(recovargs == NULL);
  103b54:	a1 94 8e 18 00       	mov    0x188e94,%eax
  103b59:	85 c0                	test   %eax,%eax
  103b5b:	74 24                	je     103b81 <child+0x105>
  103b5d:	c7 44 24 0c 65 af 10 	movl   $0x10af65,0xc(%esp)
  103b64:	00 
  103b65:	c7 44 24 08 f2 ad 10 	movl   $0x10adf2,0x8(%esp)
  103b6c:	00 
  103b6d:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
  103b74:	00 
  103b75:	c7 04 24 14 ae 10 00 	movl   $0x10ae14,(%esp)
  103b7c:	e8 b7 cd ff ff       	call   100938 <debug_panic>
		trap_check(&recovargs);
  103b81:	c7 04 24 94 8e 18 00 	movl   $0x188e94,(%esp)
  103b88:	e8 99 e5 ff ff       	call   102126 <trap_check>
		assert(recovargs == NULL);
  103b8d:	a1 94 8e 18 00       	mov    0x188e94,%eax
  103b92:	85 c0                	test   %eax,%eax
  103b94:	74 24                	je     103bba <child+0x13e>
  103b96:	c7 44 24 0c 65 af 10 	movl   $0x10af65,0xc(%esp)
  103b9d:	00 
  103b9e:	c7 44 24 08 f2 ad 10 	movl   $0x10adf2,0x8(%esp)
  103ba5:	00 
  103ba6:	c7 44 24 04 35 01 00 	movl   $0x135,0x4(%esp)
  103bad:	00 
  103bae:	c7 04 24 14 ae 10 00 	movl   $0x10ae14,(%esp)
  103bb5:	e8 7e cd ff ff       	call   100938 <debug_panic>
  103bba:	b8 03 00 00 00       	mov    $0x3,%eax
  103bbf:	cd 30                	int    $0x30
		sys_ret();
	}

	panic("child(): shouldn't have gotten here");
  103bc1:	c7 44 24 08 10 b0 10 	movl   $0x10b010,0x8(%esp)
  103bc8:	00 
  103bc9:	c7 44 24 04 39 01 00 	movl   $0x139,0x4(%esp)
  103bd0:	00 
  103bd1:	c7 04 24 14 ae 10 00 	movl   $0x10ae14,(%esp)
  103bd8:	e8 5b cd ff ff       	call   100938 <debug_panic>

00103bdd <grandchild>:
}

static void grandchild(int n)
{
  103bdd:	55                   	push   %ebp
  103bde:	89 e5                	mov    %esp,%ebp
  103be0:	83 ec 18             	sub    $0x18,%esp
	panic("grandchild(): shouldn't have gotten here");
  103be3:	c7 44 24 08 34 b0 10 	movl   $0x10b034,0x8(%esp)
  103bea:	00 
  103beb:	c7 44 24 04 3e 01 00 	movl   $0x13e,0x4(%esp)
  103bf2:	00 
  103bf3:	c7 04 24 14 ae 10 00 	movl   $0x10ae14,(%esp)
  103bfa:	e8 39 cd ff ff       	call   100938 <debug_panic>
  103bff:	90                   	nop

00103c00 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  103c00:	55                   	push   %ebp
  103c01:	89 e5                	mov    %esp,%ebp
  103c03:	53                   	push   %ebx
  103c04:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  103c07:	89 e3                	mov    %esp,%ebx
  103c09:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  103c0c:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  103c0f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  103c12:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c15:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103c1a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  103c1d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103c20:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103c26:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  103c2b:	74 24                	je     103c51 <cpu_cur+0x51>
  103c2d:	c7 44 24 0c 5d b0 10 	movl   $0x10b05d,0xc(%esp)
  103c34:	00 
  103c35:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  103c3c:	00 
  103c3d:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103c44:	00 
  103c45:	c7 04 24 88 b0 10 00 	movl   $0x10b088,(%esp)
  103c4c:	e8 e7 cc ff ff       	call   100938 <debug_panic>
	return c;
  103c51:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  103c54:	83 c4 24             	add    $0x24,%esp
  103c57:	5b                   	pop    %ebx
  103c58:	5d                   	pop    %ebp
  103c59:	c3                   	ret    

00103c5a <systrap>:
// During a system call, generate a specific processor trap -
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
  103c5a:	55                   	push   %ebp
  103c5b:	89 e5                	mov    %esp,%ebp
  103c5d:	83 ec 18             	sub    $0x18,%esp
	utf->trapno = trapno;
  103c60:	8b 55 0c             	mov    0xc(%ebp),%edx
  103c63:	8b 45 08             	mov    0x8(%ebp),%eax
  103c66:	89 50 30             	mov    %edx,0x30(%eax)
	utf->err = err;
  103c69:	8b 55 10             	mov    0x10(%ebp),%edx
  103c6c:	8b 45 08             	mov    0x8(%ebp),%eax
  103c6f:	89 50 34             	mov    %edx,0x34(%eax)
	proc_ret(utf, 0);
  103c72:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103c79:	00 
  103c7a:	8b 45 08             	mov    0x8(%ebp),%eax
  103c7d:	89 04 24             	mov    %eax,(%esp)
  103c80:	e8 fc f8 ff ff       	call   103581 <proc_ret>

00103c85 <sysrecover>:
// - Be sure the parent gets the correct trapno, err, and eip values.
// - Be sure to release any spinlocks you were holding during the copyin/out.
//
static void gcc_noreturn
sysrecover(trapframe *ktf, void *recoverdata)
{	
  103c85:	55                   	push   %ebp
  103c86:	89 e5                	mov    %esp,%ebp
  103c88:	83 ec 28             	sub    $0x28,%esp
	cpu* c = cpu_cur();
  103c8b:	e8 70 ff ff ff       	call   103c00 <cpu_cur>
  103c90:	89 45 f4             	mov    %eax,-0xc(%ebp)
	c->recover = NULL;
  103c93:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103c96:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  103c9d:	00 00 00 
	trapframe* utf = (trapframe*) recoverdata;
  103ca0:	8b 45 0c             	mov    0xc(%ebp),%eax
  103ca3:	89 45 f0             	mov    %eax,-0x10(%ebp)
	systrap(utf, ktf->trapno, ktf->err);
  103ca6:	8b 45 08             	mov    0x8(%ebp),%eax
  103ca9:	8b 40 34             	mov    0x34(%eax),%eax
  103cac:	89 c2                	mov    %eax,%edx
  103cae:	8b 45 08             	mov    0x8(%ebp),%eax
  103cb1:	8b 40 30             	mov    0x30(%eax),%eax
  103cb4:	89 54 24 08          	mov    %edx,0x8(%esp)
  103cb8:	89 44 24 04          	mov    %eax,0x4(%esp)
  103cbc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103cbf:	89 04 24             	mov    %eax,(%esp)
  103cc2:	e8 93 ff ff ff       	call   103c5a <systrap>

00103cc7 <checkva>:
//
// Note: Be careful that your arithmetic works correctly
// even if size is very large, e.g., if uva+size wraps around!
//
static void checkva(trapframe *utf, uint32_t uva, size_t size)
{
  103cc7:	55                   	push   %ebp
  103cc8:	89 e5                	mov    %esp,%ebp
  103cca:	83 ec 18             	sub    $0x18,%esp
	if(uva < VM_USERLO || uva >= VM_USERHI || uva + size > VM_USERHI){
  103ccd:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  103cd4:	76 18                	jbe    103cee <checkva+0x27>
  103cd6:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  103cdd:	77 0f                	ja     103cee <checkva+0x27>
  103cdf:	8b 45 10             	mov    0x10(%ebp),%eax
  103ce2:	8b 55 0c             	mov    0xc(%ebp),%edx
  103ce5:	01 d0                	add    %edx,%eax
  103ce7:	3d 00 00 00 f0       	cmp    $0xf0000000,%eax
  103cec:	76 1b                	jbe    103d09 <checkva+0x42>
		systrap(utf, T_PGFLT, 0);
  103cee:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  103cf5:	00 
  103cf6:	c7 44 24 04 0e 00 00 	movl   $0xe,0x4(%esp)
  103cfd:	00 
  103cfe:	8b 45 08             	mov    0x8(%ebp),%eax
  103d01:	89 04 24             	mov    %eax,(%esp)
  103d04:	e8 51 ff ff ff       	call   103c5a <systrap>
	}
}
  103d09:	c9                   	leave  
  103d0a:	c3                   	ret    

00103d0b <usercopy>:
// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout,
			void *kva, uint32_t uva, size_t size)
{
  103d0b:	55                   	push   %ebp
  103d0c:	89 e5                	mov    %esp,%ebp
  103d0e:	83 ec 28             	sub    $0x28,%esp
	checkva(utf, uva, size);
  103d11:	8b 45 18             	mov    0x18(%ebp),%eax
  103d14:	89 44 24 08          	mov    %eax,0x8(%esp)
  103d18:	8b 45 14             	mov    0x14(%ebp),%eax
  103d1b:	89 44 24 04          	mov    %eax,0x4(%esp)
  103d1f:	8b 45 08             	mov    0x8(%ebp),%eax
  103d22:	89 04 24             	mov    %eax,(%esp)
  103d25:	e8 9d ff ff ff       	call   103cc7 <checkva>
	cpu* c = cpu_cur();
  103d2a:	e8 d1 fe ff ff       	call   103c00 <cpu_cur>
  103d2f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert(c->recover == NULL);
  103d32:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103d35:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  103d3b:	85 c0                	test   %eax,%eax
  103d3d:	74 24                	je     103d63 <usercopy+0x58>
  103d3f:	c7 44 24 0c 95 b0 10 	movl   $0x10b095,0xc(%esp)
  103d46:	00 
  103d47:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  103d4e:	00 
  103d4f:	c7 44 24 04 55 00 00 	movl   $0x55,0x4(%esp)
  103d56:	00 
  103d57:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  103d5e:	e8 d5 cb ff ff       	call   100938 <debug_panic>
	c->recover = sysrecover;
  103d63:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103d66:	c7 80 a0 00 00 00 85 	movl   $0x103c85,0xa0(%eax)
  103d6d:	3c 10 00 
	// Now do the copy, but recover from page faults.
	if(copyout)
  103d70:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  103d74:	74 1b                	je     103d91 <usercopy+0x86>
		memmove((void*)uva, kva, size);
  103d76:	8b 45 14             	mov    0x14(%ebp),%eax
  103d79:	8b 55 18             	mov    0x18(%ebp),%edx
  103d7c:	89 54 24 08          	mov    %edx,0x8(%esp)
  103d80:	8b 55 10             	mov    0x10(%ebp),%edx
  103d83:	89 54 24 04          	mov    %edx,0x4(%esp)
  103d87:	89 04 24             	mov    %eax,(%esp)
  103d8a:	e8 20 5f 00 00       	call   109caf <memmove>
  103d8f:	eb 19                	jmp    103daa <usercopy+0x9f>
	else
		memmove(kva, (void*)uva, size);
  103d91:	8b 45 14             	mov    0x14(%ebp),%eax
  103d94:	8b 55 18             	mov    0x18(%ebp),%edx
  103d97:	89 54 24 08          	mov    %edx,0x8(%esp)
  103d9b:	89 44 24 04          	mov    %eax,0x4(%esp)
  103d9f:	8b 45 10             	mov    0x10(%ebp),%eax
  103da2:	89 04 24             	mov    %eax,(%esp)
  103da5:	e8 05 5f 00 00       	call   109caf <memmove>

	c->recover = NULL;
  103daa:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103dad:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  103db4:	00 00 00 
}
  103db7:	c9                   	leave  
  103db8:	c3                   	ret    

00103db9 <do_cputs>:

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
  103db9:	55                   	push   %ebp
  103dba:	89 e5                	mov    %esp,%ebp
  103dbc:	81 ec 38 01 00 00    	sub    $0x138,%esp
	// Print the string supplied by the user: pointer in EBX
	char string[CPUTS_MAX + 1];
	usercopy(tf, 0, string, tf->regs.ebx, CPUTS_MAX);
  103dc2:	8b 45 08             	mov    0x8(%ebp),%eax
  103dc5:	8b 40 10             	mov    0x10(%eax),%eax
  103dc8:	c7 44 24 10 00 01 00 	movl   $0x100,0x10(%esp)
  103dcf:	00 
  103dd0:	89 44 24 0c          	mov    %eax,0xc(%esp)
  103dd4:	8d 85 f7 fe ff ff    	lea    -0x109(%ebp),%eax
  103dda:	89 44 24 08          	mov    %eax,0x8(%esp)
  103dde:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103de5:	00 
  103de6:	8b 45 08             	mov    0x8(%ebp),%eax
  103de9:	89 04 24             	mov    %eax,(%esp)
  103dec:	e8 1a ff ff ff       	call   103d0b <usercopy>
	cprintf("%s", string);
  103df1:	8d 85 f7 fe ff ff    	lea    -0x109(%ebp),%eax
  103df7:	89 44 24 04          	mov    %eax,0x4(%esp)
  103dfb:	c7 04 24 b7 b0 10 00 	movl   $0x10b0b7,(%esp)
  103e02:	e8 c9 5a 00 00       	call   1098d0 <cprintf>

	trap_return(tf);	// syscall completed
  103e07:	8b 45 08             	mov    0x8(%ebp),%eax
  103e0a:	89 04 24             	mov    %eax,(%esp)
  103e0d:	e8 ee c2 00 00       	call   110100 <trap_return>

00103e12 <do_get>:
}

static void
do_get(trapframe *tf, uint32_t cmd){
  103e12:	55                   	push   %ebp
  103e13:	89 e5                	mov    %esp,%ebp
  103e15:	53                   	push   %ebx
  103e16:	83 ec 44             	sub    $0x44,%esp
	uint32_t flag = tf->regs.eax;
  103e19:	8b 45 08             	mov    0x8(%ebp),%eax
  103e1c:	8b 40 1c             	mov    0x1c(%eax),%eax
  103e1f:	89 45 f0             	mov    %eax,-0x10(%ebp)
	size_t size = tf->regs.ecx;
  103e22:	8b 45 08             	mov    0x8(%ebp),%eax
  103e25:	8b 40 18             	mov    0x18(%eax),%eax
  103e28:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32_t source_add = tf->regs.esi;
  103e2b:	8b 45 08             	mov    0x8(%ebp),%eax
  103e2e:	8b 40 04             	mov    0x4(%eax),%eax
  103e31:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint32_t dest_add = tf->regs.edi;
  103e34:	8b 45 08             	mov    0x8(%ebp),%eax
  103e37:	8b 00                	mov    (%eax),%eax
  103e39:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	proc* parent = proc_cur();
  103e3c:	e8 bf fd ff ff       	call   103c00 <cpu_cur>
  103e41:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  103e47:	89 45 e0             	mov    %eax,-0x20(%ebp)
	proc* child = parent->child[tf->regs.edx];
  103e4a:	8b 45 08             	mov    0x8(%ebp),%eax
  103e4d:	8b 50 14             	mov    0x14(%eax),%edx
  103e50:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103e53:	83 c2 0c             	add    $0xc,%edx
  103e56:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
  103e5a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	procstate *get_state = (procstate*)tf->regs.ebx;
  103e5d:	8b 45 08             	mov    0x8(%ebp),%eax
  103e60:	8b 40 10             	mov    0x10(%eax),%eax
  103e63:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if(!child)
  103e66:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  103e6a:	75 07                	jne    103e73 <do_get+0x61>
		child = &proc_null;
  103e6c:	c7 45 f4 80 8f 38 00 	movl   $0x388f80,-0xc(%ebp)
	/*assert(size%PTSIZE == 0);
	assert(((uint32_t)source_add)%PTSIZE == 0);
	assert(((uint32_t)dest_add)%PTSIZE == 0);
	*/
	if(child->state != PROC_STOP){
  103e73:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103e76:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  103e7c:	85 c0                	test   %eax,%eax
  103e7e:	74 19                	je     103e99 <do_get+0x87>
		proc_wait(parent, child, tf);
  103e80:	8b 45 08             	mov    0x8(%ebp),%eax
  103e83:	89 44 24 08          	mov    %eax,0x8(%esp)
  103e87:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103e8a:	89 44 24 04          	mov    %eax,0x4(%esp)
  103e8e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103e91:	89 04 24             	mov    %eax,(%esp)
  103e94:	e8 75 f5 ff ff       	call   10340e <proc_wait>
	}
	if(flag& SYS_REGS){
  103e99:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103e9c:	25 00 10 00 00       	and    $0x1000,%eax
  103ea1:	85 c0                	test   %eax,%eax
  103ea3:	74 2f                	je     103ed4 <do_get+0xc2>
		usercopy(tf, 1, &child->sv.tf, (uint32_t)(&get_state->tf), sizeof(trapframe));
  103ea5:	8b 45 dc             	mov    -0x24(%ebp),%eax
  103ea8:	8b 55 f4             	mov    -0xc(%ebp),%edx
  103eab:	81 c2 b0 04 00 00    	add    $0x4b0,%edx
  103eb1:	c7 44 24 10 4c 00 00 	movl   $0x4c,0x10(%esp)
  103eb8:	00 
  103eb9:	89 44 24 0c          	mov    %eax,0xc(%esp)
  103ebd:	89 54 24 08          	mov    %edx,0x8(%esp)
  103ec1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  103ec8:	00 
  103ec9:	8b 45 08             	mov    0x8(%ebp),%eax
  103ecc:	89 04 24             	mov    %eax,(%esp)
  103ecf:	e8 37 fe ff ff       	call   103d0b <usercopy>
	}
	switch(flag & SYS_MEMOP){
  103ed4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103ed7:	25 00 00 03 00       	and    $0x30000,%eax
  103edc:	3d 00 00 01 00       	cmp    $0x10000,%eax
  103ee1:	74 10                	je     103ef3 <do_get+0xe1>
  103ee3:	3d 00 00 02 00       	cmp    $0x20000,%eax
  103ee8:	0f 84 a2 00 00 00    	je     103f90 <do_get+0x17e>
  103eee:	e9 94 01 00 00       	jmp    104087 <do_get+0x275>
	case SYS_ZERO:
		assert(size%PTSIZE == 0);
  103ef3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103ef6:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  103efb:	85 c0                	test   %eax,%eax
  103efd:	74 24                	je     103f23 <do_get+0x111>
  103eff:	c7 44 24 0c ba b0 10 	movl   $0x10b0ba,0xc(%esp)
  103f06:	00 
  103f07:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  103f0e:	00 
  103f0f:	c7 44 24 04 82 00 00 	movl   $0x82,0x4(%esp)
  103f16:	00 
  103f17:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  103f1e:	e8 15 ca ff ff       	call   100938 <debug_panic>
		assert((dest_add)%PTSIZE == 0);
  103f23:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103f26:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  103f2b:	85 c0                	test   %eax,%eax
  103f2d:	74 24                	je     103f53 <do_get+0x141>
  103f2f:	c7 44 24 0c cb b0 10 	movl   $0x10b0cb,0xc(%esp)
  103f36:	00 
  103f37:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  103f3e:	00 
  103f3f:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
  103f46:	00 
  103f47:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  103f4e:	e8 e5 c9 ff ff       	call   100938 <debug_panic>
		checkva(tf, dest_add, size);
  103f53:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103f56:	89 44 24 08          	mov    %eax,0x8(%esp)
  103f5a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103f5d:	89 44 24 04          	mov    %eax,0x4(%esp)
  103f61:	8b 45 08             	mov    0x8(%ebp),%eax
  103f64:	89 04 24             	mov    %eax,(%esp)
  103f67:	e8 5b fd ff ff       	call   103cc7 <checkva>
		pmap_remove(parent->pdir, dest_add, size);
  103f6c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  103f6f:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  103f75:	8b 55 ec             	mov    -0x14(%ebp),%edx
  103f78:	89 54 24 08          	mov    %edx,0x8(%esp)
  103f7c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  103f7f:	89 54 24 04          	mov    %edx,0x4(%esp)
  103f83:	89 04 24             	mov    %eax,(%esp)
  103f86:	e8 c3 11 00 00       	call   10514e <pmap_remove>
		break;
  103f8b:	e9 f8 00 00 00       	jmp    104088 <do_get+0x276>
	case SYS_COPY:
		assert(size%PTSIZE == 0);
  103f90:	8b 45 ec             	mov    -0x14(%ebp),%eax
  103f93:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  103f98:	85 c0                	test   %eax,%eax
  103f9a:	74 24                	je     103fc0 <do_get+0x1ae>
  103f9c:	c7 44 24 0c ba b0 10 	movl   $0x10b0ba,0xc(%esp)
  103fa3:	00 
  103fa4:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  103fab:	00 
  103fac:	c7 44 24 04 88 00 00 	movl   $0x88,0x4(%esp)
  103fb3:	00 
  103fb4:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  103fbb:	e8 78 c9 ff ff       	call   100938 <debug_panic>
		assert((source_add)%PTSIZE == 0);
  103fc0:	8b 45 e8             	mov    -0x18(%ebp),%eax
  103fc3:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  103fc8:	85 c0                	test   %eax,%eax
  103fca:	74 24                	je     103ff0 <do_get+0x1de>
  103fcc:	c7 44 24 0c e2 b0 10 	movl   $0x10b0e2,0xc(%esp)
  103fd3:	00 
  103fd4:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  103fdb:	00 
  103fdc:	c7 44 24 04 89 00 00 	movl   $0x89,0x4(%esp)
  103fe3:	00 
  103fe4:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  103feb:	e8 48 c9 ff ff       	call   100938 <debug_panic>
		assert((dest_add)%PTSIZE == 0);
  103ff0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103ff3:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  103ff8:	85 c0                	test   %eax,%eax
  103ffa:	74 24                	je     104020 <do_get+0x20e>
  103ffc:	c7 44 24 0c cb b0 10 	movl   $0x10b0cb,0xc(%esp)
  104003:	00 
  104004:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  10400b:	00 
  10400c:	c7 44 24 04 8a 00 00 	movl   $0x8a,0x4(%esp)
  104013:	00 
  104014:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  10401b:	e8 18 c9 ff ff       	call   100938 <debug_panic>
		checkva(tf, source_add, size);
  104020:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104023:	89 44 24 08          	mov    %eax,0x8(%esp)
  104027:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10402a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10402e:	8b 45 08             	mov    0x8(%ebp),%eax
  104031:	89 04 24             	mov    %eax,(%esp)
  104034:	e8 8e fc ff ff       	call   103cc7 <checkva>
		checkva(tf, dest_add, size);
  104039:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10403c:	89 44 24 08          	mov    %eax,0x8(%esp)
  104040:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104043:	89 44 24 04          	mov    %eax,0x4(%esp)
  104047:	8b 45 08             	mov    0x8(%ebp),%eax
  10404a:	89 04 24             	mov    %eax,(%esp)
  10404d:	e8 75 fc ff ff       	call   103cc7 <checkva>
		pmap_copy(child->pdir, source_add, parent->pdir, dest_add, size);
  104052:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104055:	8b 90 00 07 00 00    	mov    0x700(%eax),%edx
  10405b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10405e:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  104064:	8b 4d ec             	mov    -0x14(%ebp),%ecx
  104067:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  10406b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  10406e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  104072:	89 54 24 08          	mov    %edx,0x8(%esp)
  104076:	8b 55 e8             	mov    -0x18(%ebp),%edx
  104079:	89 54 24 04          	mov    %edx,0x4(%esp)
  10407d:	89 04 24             	mov    %eax,(%esp)
  104080:	e8 b4 17 00 00       	call   105839 <pmap_copy>
		break;
  104085:	eb 01                	jmp    104088 <do_get+0x276>
	default:
		break;
  104087:	90                   	nop
	}
	
	if((flag & SYS_MEMOP) == SYS_MERGE){
  104088:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10408b:	25 00 00 03 00       	and    $0x30000,%eax
  104090:	3d 00 00 03 00       	cmp    $0x30000,%eax
  104095:	0f 85 02 01 00 00    	jne    10419d <do_get+0x38b>
		assert(size%PTSIZE == 0);
  10409b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10409e:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1040a3:	85 c0                	test   %eax,%eax
  1040a5:	74 24                	je     1040cb <do_get+0x2b9>
  1040a7:	c7 44 24 0c ba b0 10 	movl   $0x10b0ba,0xc(%esp)
  1040ae:	00 
  1040af:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  1040b6:	00 
  1040b7:	c7 44 24 04 94 00 00 	movl   $0x94,0x4(%esp)
  1040be:	00 
  1040bf:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  1040c6:	e8 6d c8 ff ff       	call   100938 <debug_panic>
		assert((source_add)%PTSIZE == 0);
  1040cb:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1040ce:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1040d3:	85 c0                	test   %eax,%eax
  1040d5:	74 24                	je     1040fb <do_get+0x2e9>
  1040d7:	c7 44 24 0c e2 b0 10 	movl   $0x10b0e2,0xc(%esp)
  1040de:	00 
  1040df:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  1040e6:	00 
  1040e7:	c7 44 24 04 95 00 00 	movl   $0x95,0x4(%esp)
  1040ee:	00 
  1040ef:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  1040f6:	e8 3d c8 ff ff       	call   100938 <debug_panic>
		assert((dest_add)%PTSIZE == 0);
  1040fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1040fe:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104103:	85 c0                	test   %eax,%eax
  104105:	74 24                	je     10412b <do_get+0x319>
  104107:	c7 44 24 0c cb b0 10 	movl   $0x10b0cb,0xc(%esp)
  10410e:	00 
  10410f:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  104116:	00 
  104117:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
  10411e:	00 
  10411f:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  104126:	e8 0d c8 ff ff       	call   100938 <debug_panic>
		checkva(tf, source_add, size);
  10412b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10412e:	89 44 24 08          	mov    %eax,0x8(%esp)
  104132:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104135:	89 44 24 04          	mov    %eax,0x4(%esp)
  104139:	8b 45 08             	mov    0x8(%ebp),%eax
  10413c:	89 04 24             	mov    %eax,(%esp)
  10413f:	e8 83 fb ff ff       	call   103cc7 <checkva>
		checkva(tf, dest_add, size);		
  104144:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104147:	89 44 24 08          	mov    %eax,0x8(%esp)
  10414b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10414e:	89 44 24 04          	mov    %eax,0x4(%esp)
  104152:	8b 45 08             	mov    0x8(%ebp),%eax
  104155:	89 04 24             	mov    %eax,(%esp)
  104158:	e8 6a fb ff ff       	call   103cc7 <checkva>
		pmap_merge(child->rpdir, child->pdir, source_add, parent->pdir, dest_add, size);
  10415d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104160:	8b 88 00 07 00 00    	mov    0x700(%eax),%ecx
  104166:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104169:	8b 90 00 07 00 00    	mov    0x700(%eax),%edx
  10416f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104172:	8b 80 04 07 00 00    	mov    0x704(%eax),%eax
  104178:	8b 5d ec             	mov    -0x14(%ebp),%ebx
  10417b:	89 5c 24 14          	mov    %ebx,0x14(%esp)
  10417f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
  104182:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  104186:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  10418a:	8b 4d e8             	mov    -0x18(%ebp),%ecx
  10418d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  104191:	89 54 24 04          	mov    %edx,0x4(%esp)
  104195:	89 04 24             	mov    %eax,(%esp)
  104198:	e8 4e 1d 00 00       	call   105eeb <pmap_merge>
	}

	switch(flag & 0x700){
  10419d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1041a0:	25 00 07 00 00       	and    $0x700,%eax
  1041a5:	3d 00 03 00 00       	cmp    $0x300,%eax
  1041aa:	74 37                	je     1041e3 <do_get+0x3d1>
  1041ac:	3d 00 07 00 00       	cmp    $0x700,%eax
  1041b1:	74 59                	je     10420c <do_get+0x3fa>
  1041b3:	3d 00 01 00 00       	cmp    $0x100,%eax
  1041b8:	75 7b                	jne    104235 <do_get+0x423>
	case SYS_PERM:
		pmap_setperm(parent->pdir, dest_add, size, 0);
  1041ba:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1041bd:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  1041c3:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1041ca:	00 
  1041cb:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1041ce:	89 54 24 08          	mov    %edx,0x8(%esp)
  1041d2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1041d5:	89 54 24 04          	mov    %edx,0x4(%esp)
  1041d9:	89 04 24             	mov    %eax,(%esp)
  1041dc:	e8 71 21 00 00       	call   106352 <pmap_setperm>
		break;
  1041e1:	eb 53                	jmp    104236 <do_get+0x424>
	case SYS_PERM | SYS_READ:
		pmap_setperm(parent->pdir, dest_add, size,  SYS_READ);
  1041e3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1041e6:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  1041ec:	c7 44 24 0c 00 02 00 	movl   $0x200,0xc(%esp)
  1041f3:	00 
  1041f4:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1041f7:	89 54 24 08          	mov    %edx,0x8(%esp)
  1041fb:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1041fe:	89 54 24 04          	mov    %edx,0x4(%esp)
  104202:	89 04 24             	mov    %eax,(%esp)
  104205:	e8 48 21 00 00       	call   106352 <pmap_setperm>
		break;
  10420a:	eb 2a                	jmp    104236 <do_get+0x424>
	case SYS_PERM | SYS_READ | SYS_WRITE:
		pmap_setperm(parent->pdir, dest_add, size,  SYS_RW);
  10420c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10420f:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  104215:	c7 44 24 0c 00 06 00 	movl   $0x600,0xc(%esp)
  10421c:	00 
  10421d:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104220:	89 54 24 08          	mov    %edx,0x8(%esp)
  104224:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  104227:	89 54 24 04          	mov    %edx,0x4(%esp)
  10422b:	89 04 24             	mov    %eax,(%esp)
  10422e:	e8 1f 21 00 00       	call   106352 <pmap_setperm>
		break;
  104233:	eb 01                	jmp    104236 <do_get+0x424>
	default:
		break;
  104235:	90                   	nop
	}
	trap_return(tf);
  104236:	8b 45 08             	mov    0x8(%ebp),%eax
  104239:	89 04 24             	mov    %eax,(%esp)
  10423c:	e8 bf be 00 00       	call   110100 <trap_return>

00104241 <do_put>:
}

static void
do_put(trapframe *tf, uint32_t cmd){	
  104241:	55                   	push   %ebp
  104242:	89 e5                	mov    %esp,%ebp
  104244:	83 ec 48             	sub    $0x48,%esp
	uint32_t flag = tf->regs.eax;
  104247:	8b 45 08             	mov    0x8(%ebp),%eax
  10424a:	8b 40 1c             	mov    0x1c(%eax),%eax
  10424d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	size_t size = tf->regs.ecx;
  104250:	8b 45 08             	mov    0x8(%ebp),%eax
  104253:	8b 40 18             	mov    0x18(%eax),%eax
  104256:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32_t source_add = tf->regs.esi;
  104259:	8b 45 08             	mov    0x8(%ebp),%eax
  10425c:	8b 40 04             	mov    0x4(%eax),%eax
  10425f:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint32_t dest_add = tf->regs.edi;
  104262:	8b 45 08             	mov    0x8(%ebp),%eax
  104265:	8b 00                	mov    (%eax),%eax
  104267:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	proc* parent = proc_cur();
  10426a:	e8 91 f9 ff ff       	call   103c00 <cpu_cur>
  10426f:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  104275:	89 45 e0             	mov    %eax,-0x20(%ebp)
	proc* child = parent->child[tf->regs.edx];
  104278:	8b 45 08             	mov    0x8(%ebp),%eax
  10427b:	8b 50 14             	mov    0x14(%eax),%edx
  10427e:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104281:	83 c2 0c             	add    $0xc,%edx
  104284:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
  104288:	89 45 f4             	mov    %eax,-0xc(%ebp)
	procstate *put_state = (procstate*)tf->regs.ebx;
  10428b:	8b 45 08             	mov    0x8(%ebp),%eax
  10428e:	8b 40 10             	mov    0x10(%eax),%eax
  104291:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if(!child){
  104294:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  104298:	75 18                	jne    1042b2 <do_put+0x71>
		child = proc_alloc(parent, tf->regs.edx);
  10429a:	8b 45 08             	mov    0x8(%ebp),%eax
  10429d:	8b 40 14             	mov    0x14(%eax),%eax
  1042a0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1042a4:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1042a7:	89 04 24             	mov    %eax,(%esp)
  1042aa:	e8 3c ee ff ff       	call   1030eb <proc_alloc>
  1042af:	89 45 f4             	mov    %eax,-0xc(%ebp)
	}
	if(child->state != PROC_STOP){
  1042b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1042b5:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  1042bb:	85 c0                	test   %eax,%eax
  1042bd:	74 19                	je     1042d8 <do_put+0x97>
		proc_wait(parent, child, tf);
  1042bf:	8b 45 08             	mov    0x8(%ebp),%eax
  1042c2:	89 44 24 08          	mov    %eax,0x8(%esp)
  1042c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1042c9:	89 44 24 04          	mov    %eax,0x4(%esp)
  1042cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1042d0:	89 04 24             	mov    %eax,(%esp)
  1042d3:	e8 36 f1 ff ff       	call   10340e <proc_wait>
	}
	if(tf->regs.eax & SYS_REGS){
  1042d8:	8b 45 08             	mov    0x8(%ebp),%eax
  1042db:	8b 40 1c             	mov    0x1c(%eax),%eax
  1042de:	25 00 10 00 00       	and    $0x1000,%eax
  1042e3:	85 c0                	test   %eax,%eax
  1042e5:	0f 84 ae 00 00 00    	je     104399 <do_put+0x158>
		usercopy(tf, false, &child->sv.tf, (uint32_t)(&put_state->tf), sizeof(trapframe));
  1042eb:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1042ee:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1042f1:	81 c2 b0 04 00 00    	add    $0x4b0,%edx
  1042f7:	c7 44 24 10 4c 00 00 	movl   $0x4c,0x10(%esp)
  1042fe:	00 
  1042ff:	89 44 24 0c          	mov    %eax,0xc(%esp)
  104303:	89 54 24 08          	mov    %edx,0x8(%esp)
  104307:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10430e:	00 
  10430f:	8b 45 08             	mov    0x8(%ebp),%eax
  104312:	89 04 24             	mov    %eax,(%esp)
  104315:	e8 f1 f9 ff ff       	call   103d0b <usercopy>
		child->sv.tf.cs = CPU_GDT_UCODE | 3;
  10431a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10431d:	66 c7 80 ec 04 00 00 	movw   $0x1b,0x4ec(%eax)
  104324:	1b 00 
		child->sv.tf.ds = CPU_GDT_UDATA | 3;
  104326:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104329:	66 c7 80 dc 04 00 00 	movw   $0x23,0x4dc(%eax)
  104330:	23 00 
		child->sv.tf.es = CPU_GDT_UDATA | 3;
  104332:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104335:	66 c7 80 d8 04 00 00 	movw   $0x23,0x4d8(%eax)
  10433c:	23 00 
		child->sv.tf.ss = CPU_GDT_UDATA | 3;
  10433e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104341:	66 c7 80 f8 04 00 00 	movw   $0x23,0x4f8(%eax)
  104348:	23 00 
		child->sv.tf.eflags &= FL_USER;
  10434a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10434d:	8b 80 f0 04 00 00    	mov    0x4f0(%eax),%eax
  104353:	89 c2                	mov    %eax,%edx
  104355:	81 e2 d5 0c 00 00    	and    $0xcd5,%edx
  10435b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10435e:	89 90 f0 04 00 00    	mov    %edx,0x4f0(%eax)
		child->sv.tf.eflags |= FL_IF;
  104364:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104367:	8b 80 f0 04 00 00    	mov    0x4f0(%eax),%eax
  10436d:	89 c2                	mov    %eax,%edx
  10436f:	80 ce 02             	or     $0x2,%dh
  104372:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104375:	89 90 f0 04 00 00    	mov    %edx,0x4f0(%eax)
		child->sv.tf.eip = put_state->tf.eip;
  10437b:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10437e:	8b 50 38             	mov    0x38(%eax),%edx
  104381:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104384:	89 90 e8 04 00 00    	mov    %edx,0x4e8(%eax)
		child->sv.tf.esp = put_state->tf.esp;
  10438a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10438d:	8b 50 44             	mov    0x44(%eax),%edx
  104390:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104393:	89 90 f4 04 00 00    	mov    %edx,0x4f4(%eax)
	}
	switch(flag & SYS_MEMOP){
  104399:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10439c:	25 00 00 03 00       	and    $0x30000,%eax
  1043a1:	3d 00 00 01 00       	cmp    $0x10000,%eax
  1043a6:	74 10                	je     1043b8 <do_put+0x177>
  1043a8:	3d 00 00 02 00       	cmp    $0x20000,%eax
  1043ad:	0f 84 a2 00 00 00    	je     104455 <do_put+0x214>
  1043b3:	e9 b2 01 00 00       	jmp    10456a <do_put+0x329>
	case SYS_ZERO:
		assert(size%PTSIZE == 0);
  1043b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1043bb:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1043c0:	85 c0                	test   %eax,%eax
  1043c2:	74 24                	je     1043e8 <do_put+0x1a7>
  1043c4:	c7 44 24 0c ba b0 10 	movl   $0x10b0ba,0xc(%esp)
  1043cb:	00 
  1043cc:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  1043d3:	00 
  1043d4:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
  1043db:	00 
  1043dc:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  1043e3:	e8 50 c5 ff ff       	call   100938 <debug_panic>
		assert((dest_add)%PTSIZE == 0);
  1043e8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1043eb:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1043f0:	85 c0                	test   %eax,%eax
  1043f2:	74 24                	je     104418 <do_put+0x1d7>
  1043f4:	c7 44 24 0c cb b0 10 	movl   $0x10b0cb,0xc(%esp)
  1043fb:	00 
  1043fc:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  104403:	00 
  104404:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
  10440b:	00 
  10440c:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  104413:	e8 20 c5 ff ff       	call   100938 <debug_panic>
		checkva(tf, dest_add, size);
  104418:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10441b:	89 44 24 08          	mov    %eax,0x8(%esp)
  10441f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104422:	89 44 24 04          	mov    %eax,0x4(%esp)
  104426:	8b 45 08             	mov    0x8(%ebp),%eax
  104429:	89 04 24             	mov    %eax,(%esp)
  10442c:	e8 96 f8 ff ff       	call   103cc7 <checkva>
		pmap_remove(child->pdir, dest_add, size);
  104431:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104434:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  10443a:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10443d:	89 54 24 08          	mov    %edx,0x8(%esp)
  104441:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  104444:	89 54 24 04          	mov    %edx,0x4(%esp)
  104448:	89 04 24             	mov    %eax,(%esp)
  10444b:	e8 fe 0c 00 00       	call   10514e <pmap_remove>
		break;
  104450:	e9 18 01 00 00       	jmp    10456d <do_put+0x32c>
	case SYS_COPY:
		assert(size%PTSIZE == 0);
  104455:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104458:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  10445d:	85 c0                	test   %eax,%eax
  10445f:	74 24                	je     104485 <do_put+0x244>
  104461:	c7 44 24 0c ba b0 10 	movl   $0x10b0ba,0xc(%esp)
  104468:	00 
  104469:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  104470:	00 
  104471:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  104478:	00 
  104479:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  104480:	e8 b3 c4 ff ff       	call   100938 <debug_panic>
		assert((source_add)%PTSIZE == 0);
  104485:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104488:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  10448d:	85 c0                	test   %eax,%eax
  10448f:	74 24                	je     1044b5 <do_put+0x274>
  104491:	c7 44 24 0c e2 b0 10 	movl   $0x10b0e2,0xc(%esp)
  104498:	00 
  104499:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  1044a0:	00 
  1044a1:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  1044a8:	00 
  1044a9:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  1044b0:	e8 83 c4 ff ff       	call   100938 <debug_panic>
		assert((dest_add)%PTSIZE == 0);
  1044b5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1044b8:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1044bd:	85 c0                	test   %eax,%eax
  1044bf:	74 24                	je     1044e5 <do_put+0x2a4>
  1044c1:	c7 44 24 0c cb b0 10 	movl   $0x10b0cb,0xc(%esp)
  1044c8:	00 
  1044c9:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  1044d0:	00 
  1044d1:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
  1044d8:	00 
  1044d9:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  1044e0:	e8 53 c4 ff ff       	call   100938 <debug_panic>
		checkva(tf, source_add, size);
  1044e5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1044e8:	89 44 24 08          	mov    %eax,0x8(%esp)
  1044ec:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1044ef:	89 44 24 04          	mov    %eax,0x4(%esp)
  1044f3:	8b 45 08             	mov    0x8(%ebp),%eax
  1044f6:	89 04 24             	mov    %eax,(%esp)
  1044f9:	e8 c9 f7 ff ff       	call   103cc7 <checkva>
		checkva(tf, dest_add, size);
  1044fe:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104501:	89 44 24 08          	mov    %eax,0x8(%esp)
  104505:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104508:	89 44 24 04          	mov    %eax,0x4(%esp)
  10450c:	8b 45 08             	mov    0x8(%ebp),%eax
  10450f:	89 04 24             	mov    %eax,(%esp)
  104512:	e8 b0 f7 ff ff       	call   103cc7 <checkva>
		if(!pmap_copy(parent->pdir, source_add, child->pdir, dest_add, size))
  104517:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10451a:	8b 90 00 07 00 00    	mov    0x700(%eax),%edx
  104520:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104523:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  104529:	8b 4d ec             	mov    -0x14(%ebp),%ecx
  10452c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  104530:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  104533:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  104537:	89 54 24 08          	mov    %edx,0x8(%esp)
  10453b:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10453e:	89 54 24 04          	mov    %edx,0x4(%esp)
  104542:	89 04 24             	mov    %eax,(%esp)
  104545:	e8 ef 12 00 00       	call   105839 <pmap_copy>
  10454a:	85 c0                	test   %eax,%eax
  10454c:	75 1e                	jne    10456c <do_put+0x32b>
			panic("pmap_copy does not finished.\n");
  10454e:	c7 44 24 08 fb b0 10 	movl   $0x10b0fb,0x8(%esp)
  104555:	00 
  104556:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
  10455d:	00 
  10455e:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  104565:	e8 ce c3 ff ff       	call   100938 <debug_panic>
		break;
	default:
		break;
  10456a:	eb 01                	jmp    10456d <do_put+0x32c>
		assert((dest_add)%PTSIZE == 0);
		checkva(tf, source_add, size);
		checkva(tf, dest_add, size);
		if(!pmap_copy(parent->pdir, source_add, child->pdir, dest_add, size))
			panic("pmap_copy does not finished.\n");
		break;
  10456c:	90                   	nop
	default:
		break;
	}
	if(flag & SYS_SNAP){
  10456d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104570:	25 00 00 04 00       	and    $0x40000,%eax
  104575:	85 c0                	test   %eax,%eax
  104577:	0f 84 15 01 00 00    	je     104692 <do_put+0x451>
		assert(size%PTSIZE == 0);
  10457d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104580:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104585:	85 c0                	test   %eax,%eax
  104587:	74 24                	je     1045ad <do_put+0x36c>
  104589:	c7 44 24 0c ba b0 10 	movl   $0x10b0ba,0xc(%esp)
  104590:	00 
  104591:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  104598:	00 
  104599:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
  1045a0:	00 
  1045a1:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  1045a8:	e8 8b c3 ff ff       	call   100938 <debug_panic>
		assert((source_add)%PTSIZE == 0);
  1045ad:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1045b0:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1045b5:	85 c0                	test   %eax,%eax
  1045b7:	74 24                	je     1045dd <do_put+0x39c>
  1045b9:	c7 44 24 0c e2 b0 10 	movl   $0x10b0e2,0xc(%esp)
  1045c0:	00 
  1045c1:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  1045c8:	00 
  1045c9:	c7 44 24 04 db 00 00 	movl   $0xdb,0x4(%esp)
  1045d0:	00 
  1045d1:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  1045d8:	e8 5b c3 ff ff       	call   100938 <debug_panic>
		assert((dest_add)%PTSIZE == 0);
  1045dd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1045e0:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1045e5:	85 c0                	test   %eax,%eax
  1045e7:	74 24                	je     10460d <do_put+0x3cc>
  1045e9:	c7 44 24 0c cb b0 10 	movl   $0x10b0cb,0xc(%esp)
  1045f0:	00 
  1045f1:	c7 44 24 08 73 b0 10 	movl   $0x10b073,0x8(%esp)
  1045f8:	00 
  1045f9:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
  104600:	00 
  104601:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  104608:	e8 2b c3 ff ff       	call   100938 <debug_panic>
		checkva(tf, source_add, size);
  10460d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104610:	89 44 24 08          	mov    %eax,0x8(%esp)
  104614:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104617:	89 44 24 04          	mov    %eax,0x4(%esp)
  10461b:	8b 45 08             	mov    0x8(%ebp),%eax
  10461e:	89 04 24             	mov    %eax,(%esp)
  104621:	e8 a1 f6 ff ff       	call   103cc7 <checkva>
		checkva(tf, dest_add, size);
  104626:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104629:	89 44 24 08          	mov    %eax,0x8(%esp)
  10462d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104630:	89 44 24 04          	mov    %eax,0x4(%esp)
  104634:	8b 45 08             	mov    0x8(%ebp),%eax
  104637:	89 04 24             	mov    %eax,(%esp)
  10463a:	e8 88 f6 ff ff       	call   103cc7 <checkva>
		if(!pmap_copy(child->pdir, source_add, child->rpdir, dest_add, size))
  10463f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104642:	8b 90 04 07 00 00    	mov    0x704(%eax),%edx
  104648:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10464b:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  104651:	8b 4d ec             	mov    -0x14(%ebp),%ecx
  104654:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  104658:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
  10465b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  10465f:	89 54 24 08          	mov    %edx,0x8(%esp)
  104663:	8b 55 e8             	mov    -0x18(%ebp),%edx
  104666:	89 54 24 04          	mov    %edx,0x4(%esp)
  10466a:	89 04 24             	mov    %eax,(%esp)
  10466d:	e8 c7 11 00 00       	call   105839 <pmap_copy>
  104672:	85 c0                	test   %eax,%eax
  104674:	75 1c                	jne    104692 <do_put+0x451>
			panic("pmap_copy does not finished.\n");
  104676:	c7 44 24 08 fb b0 10 	movl   $0x10b0fb,0x8(%esp)
  10467d:	00 
  10467e:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
  104685:	00 
  104686:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  10468d:	e8 a6 c2 ff ff       	call   100938 <debug_panic>
	}
	switch(flag & 0x700){
  104692:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104695:	25 00 07 00 00       	and    $0x700,%eax
  10469a:	3d 00 03 00 00       	cmp    $0x300,%eax
  10469f:	74 37                	je     1046d8 <do_put+0x497>
  1046a1:	3d 00 07 00 00       	cmp    $0x700,%eax
  1046a6:	74 59                	je     104701 <do_put+0x4c0>
  1046a8:	3d 00 01 00 00       	cmp    $0x100,%eax
  1046ad:	75 7b                	jne    10472a <do_put+0x4e9>
	case SYS_PERM:
		pmap_setperm(child->pdir, dest_add, size, 0);
  1046af:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1046b2:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  1046b8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1046bf:	00 
  1046c0:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1046c3:	89 54 24 08          	mov    %edx,0x8(%esp)
  1046c7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1046ca:	89 54 24 04          	mov    %edx,0x4(%esp)
  1046ce:	89 04 24             	mov    %eax,(%esp)
  1046d1:	e8 7c 1c 00 00       	call   106352 <pmap_setperm>
		break;
  1046d6:	eb 53                	jmp    10472b <do_put+0x4ea>
	case SYS_PERM | SYS_READ:
		pmap_setperm(child->pdir, dest_add, size,SYS_READ);
  1046d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1046db:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  1046e1:	c7 44 24 0c 00 02 00 	movl   $0x200,0xc(%esp)
  1046e8:	00 
  1046e9:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1046ec:	89 54 24 08          	mov    %edx,0x8(%esp)
  1046f0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1046f3:	89 54 24 04          	mov    %edx,0x4(%esp)
  1046f7:	89 04 24             	mov    %eax,(%esp)
  1046fa:	e8 53 1c 00 00       	call   106352 <pmap_setperm>
		break;
  1046ff:	eb 2a                	jmp    10472b <do_put+0x4ea>
	case SYS_PERM | SYS_READ | SYS_WRITE:
		pmap_setperm(child->pdir, dest_add, size, SYS_RW);
  104701:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104704:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  10470a:	c7 44 24 0c 00 06 00 	movl   $0x600,0xc(%esp)
  104711:	00 
  104712:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104715:	89 54 24 08          	mov    %edx,0x8(%esp)
  104719:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  10471c:	89 54 24 04          	mov    %edx,0x4(%esp)
  104720:	89 04 24             	mov    %eax,(%esp)
  104723:	e8 2a 1c 00 00       	call   106352 <pmap_setperm>
		break;
  104728:	eb 01                	jmp    10472b <do_put+0x4ea>
	default:
		break;
  10472a:	90                   	nop
	}
	if(tf->regs.eax & SYS_START){
  10472b:	8b 45 08             	mov    0x8(%ebp),%eax
  10472e:	8b 40 1c             	mov    0x1c(%eax),%eax
  104731:	83 e0 10             	and    $0x10,%eax
  104734:	85 c0                	test   %eax,%eax
  104736:	74 0b                	je     104743 <do_put+0x502>
		proc_ready(child);
  104738:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10473b:	89 04 24             	mov    %eax,(%esp)
  10473e:	e8 8c eb ff ff       	call   1032cf <proc_ready>
	}
	trap_return(tf);
  104743:	8b 45 08             	mov    0x8(%ebp),%eax
  104746:	89 04 24             	mov    %eax,(%esp)
  104749:	e8 b2 b9 00 00       	call   110100 <trap_return>

0010474e <do_ret>:
}

static void
do_ret(trapframe *tf){
  10474e:	55                   	push   %ebp
  10474f:	89 e5                	mov    %esp,%ebp
  104751:	83 ec 18             	sub    $0x18,%esp
	if(proc_cur() == proc_root)
  104754:	e8 a7 f4 ff ff       	call   103c00 <cpu_cur>
  104759:	8b 90 b4 00 00 00    	mov    0xb4(%eax),%edx
  10475f:	a1 90 96 38 00       	mov    0x389690,%eax
  104764:	39 c2                	cmp    %eax,%edx
  104766:	75 0b                	jne    104773 <do_ret+0x25>
		file_io(tf);
  104768:	8b 45 08             	mov    0x8(%ebp),%eax
  10476b:	89 04 24             	mov    %eax,(%esp)
  10476e:	e8 f3 39 00 00       	call   108166 <file_io>
	proc_ret(tf, 1);
  104773:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10477a:	00 
  10477b:	8b 45 08             	mov    0x8(%ebp),%eax
  10477e:	89 04 24             	mov    %eax,(%esp)
  104781:	e8 fb ed ff ff       	call   103581 <proc_ret>

00104786 <syscall>:
// Common function to handle all system calls -
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.
void
syscall(trapframe *tf)
{
  104786:	55                   	push   %ebp
  104787:	89 e5                	mov    %esp,%ebp
  104789:	83 ec 28             	sub    $0x28,%esp
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
  10478c:	8b 45 08             	mov    0x8(%ebp),%eax
  10478f:	8b 40 1c             	mov    0x1c(%eax),%eax
  104792:	89 45 f4             	mov    %eax,-0xc(%ebp)
	switch (cmd & SYS_TYPE) {
  104795:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104798:	83 e0 0f             	and    $0xf,%eax
  10479b:	83 f8 01             	cmp    $0x1,%eax
  10479e:	74 23                	je     1047c3 <syscall+0x3d>
  1047a0:	83 f8 01             	cmp    $0x1,%eax
  1047a3:	72 0c                	jb     1047b1 <syscall+0x2b>
  1047a5:	83 f8 02             	cmp    $0x2,%eax
  1047a8:	74 2b                	je     1047d5 <syscall+0x4f>
  1047aa:	83 f8 03             	cmp    $0x3,%eax
  1047ad:	74 38                	je     1047e7 <syscall+0x61>
  1047af:	eb 41                	jmp    1047f2 <syscall+0x6c>
	case SYS_CPUTS:
		do_cputs(tf, cmd);
  1047b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1047b4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1047b8:	8b 45 08             	mov    0x8(%ebp),%eax
  1047bb:	89 04 24             	mov    %eax,(%esp)
  1047be:	e8 f6 f5 ff ff       	call   103db9 <do_cputs>
	// Your implementations of SYS_PUT, SYS_GET, SYS_RET here...
	case SYS_PUT:
		do_put(tf, cmd);
  1047c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1047c6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1047ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1047cd:	89 04 24             	mov    %eax,(%esp)
  1047d0:	e8 6c fa ff ff       	call   104241 <do_put>
	case SYS_GET:
		do_get(tf, cmd);
  1047d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1047d8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1047dc:	8b 45 08             	mov    0x8(%ebp),%eax
  1047df:	89 04 24             	mov    %eax,(%esp)
  1047e2:	e8 2b f6 ff ff       	call   103e12 <do_get>
	case SYS_RET:
		do_ret(tf);
  1047e7:	8b 45 08             	mov    0x8(%ebp),%eax
  1047ea:	89 04 24             	mov    %eax,(%esp)
  1047ed:	e8 5c ff ff ff       	call   10474e <do_ret>
	default:
		panic("Undefine system call.\n");		// handle as a regular trap
  1047f2:	c7 44 24 08 19 b1 10 	movl   $0x10b119,0x8(%esp)
  1047f9:	00 
  1047fa:	c7 44 24 04 0e 01 00 	movl   $0x10e,0x4(%esp)
  104801:	00 
  104802:	c7 04 24 a8 b0 10 00 	movl   $0x10b0a8,(%esp)
  104809:	e8 2a c1 ff ff       	call   100938 <debug_panic>
  10480e:	66 90                	xchg   %ax,%ax

00104810 <lockadd>:
}

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  104810:	55                   	push   %ebp
  104811:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  104813:	8b 45 08             	mov    0x8(%ebp),%eax
  104816:	8b 55 0c             	mov    0xc(%ebp),%edx
  104819:	8b 4d 08             	mov    0x8(%ebp),%ecx
  10481c:	f0 01 10             	lock add %edx,(%eax)
}
  10481f:	5d                   	pop    %ebp
  104820:	c3                   	ret    

00104821 <lockaddz>:

// Atomically add incr to *addr and return true if the result is zero.
static inline uint8_t
lockaddz(volatile int32_t *addr, int32_t incr)
{
  104821:	55                   	push   %ebp
  104822:	89 e5                	mov    %esp,%ebp
  104824:	53                   	push   %ebx
  104825:	83 ec 10             	sub    $0x10,%esp
	uint8_t zero;
	asm volatile("lock; addl %2,%0; setzb %1"
		: "+m" (*addr), "=rm" (zero)
  104828:	8b 45 08             	mov    0x8(%ebp),%eax
// Atomically add incr to *addr and return true if the result is zero.
static inline uint8_t
lockaddz(volatile int32_t *addr, int32_t incr)
{
	uint8_t zero;
	asm volatile("lock; addl %2,%0; setzb %1"
  10482b:	8b 55 0c             	mov    0xc(%ebp),%edx
		: "+m" (*addr), "=rm" (zero)
  10482e:	8b 4d 08             	mov    0x8(%ebp),%ecx
// Atomically add incr to *addr and return true if the result is zero.
static inline uint8_t
lockaddz(volatile int32_t *addr, int32_t incr)
{
	uint8_t zero;
	asm volatile("lock; addl %2,%0; setzb %1"
  104831:	f0 01 10             	lock add %edx,(%eax)
  104834:	0f 94 c3             	sete   %bl
  104837:	88 5d fb             	mov    %bl,-0x5(%ebp)
		: "+m" (*addr), "=rm" (zero)
		: "r" (incr)
		: "cc");
	return zero;
  10483a:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
}
  10483e:	83 c4 10             	add    $0x10,%esp
  104841:	5b                   	pop    %ebx
  104842:	5d                   	pop    %ebp
  104843:	c3                   	ret    

00104844 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  104844:	55                   	push   %ebp
  104845:	89 e5                	mov    %esp,%ebp
  104847:	53                   	push   %ebx
  104848:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10484b:	89 e3                	mov    %esp,%ebx
  10484d:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  104850:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  104853:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104856:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104859:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10485e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  104861:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104864:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10486a:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10486f:	74 24                	je     104895 <cpu_cur+0x51>
  104871:	c7 44 24 0c 30 b1 10 	movl   $0x10b130,0xc(%esp)
  104878:	00 
  104879:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  104880:	00 
  104881:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  104888:	00 
  104889:	c7 04 24 5b b1 10 00 	movl   $0x10b15b,(%esp)
  104890:	e8 a3 c0 ff ff       	call   100938 <debug_panic>
	return c;
  104895:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  104898:	83 c4 24             	add    $0x24,%esp
  10489b:	5b                   	pop    %ebx
  10489c:	5d                   	pop    %ebp
  10489d:	c3                   	ret    

0010489e <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10489e:	55                   	push   %ebp
  10489f:	89 e5                	mov    %esp,%ebp
  1048a1:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1048a4:	e8 9b ff ff ff       	call   104844 <cpu_cur>
  1048a9:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  1048ae:	0f 94 c0             	sete   %al
  1048b1:	0f b6 c0             	movzbl %al,%eax
}
  1048b4:	c9                   	leave  
  1048b5:	c3                   	ret    

001048b6 <pmap_init>:
// (addresses outside of the range between VM_USERLO and VM_USERHI).
// The user part of the address space remains all PTE_ZERO until later.
//
void
pmap_init(void)
{
  1048b6:	55                   	push   %ebp
  1048b7:	89 e5                	mov    %esp,%ebp
  1048b9:	53                   	push   %ebx
  1048ba:	83 ec 34             	sub    $0x34,%esp
	if (cpu_onboot()) {
  1048bd:	e8 dc ff ff ff       	call   10489e <cpu_onboot>
  1048c2:	85 c0                	test   %eax,%eax
  1048c4:	74 7d                	je     104943 <pmap_init+0x8d>
		// but only accessible in kernel mode (not in user mode).
		// The easiest way to do this is to use 4MB page mappings.
		// Since these page mappings never change on context switches,
		// we can also mark them global (PTE_G) so the processor
		// doesn't flush these mappings when we reload the PDBR.
		int i = 0;
  1048c6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
		int userlo_d = VM_USERLO >> PDXSHIFT;
  1048cd:	c7 45 f0 00 01 00 00 	movl   $0x100,-0x10(%ebp)
		int userhi_d = VM_USERHI >> PDXSHIFT;
  1048d4:	c7 45 ec c0 03 00 00 	movl   $0x3c0,-0x14(%ebp)
		for(i; i<userlo_d; i++){
  1048db:	eb 1b                	jmp    1048f8 <pmap_init+0x42>
			pmap_bootpdir[i] = i << PDXSHIFT | PTE_P | PTE_PS | PTE_G | PTE_W;
  1048dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1048e0:	c1 e0 16             	shl    $0x16,%eax
  1048e3:	0d 83 01 00 00       	or     $0x183,%eax
  1048e8:	89 c2                	mov    %eax,%edx
  1048ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1048ed:	89 14 85 00 a0 38 00 	mov    %edx,0x38a000(,%eax,4)
		// we can also mark them global (PTE_G) so the processor
		// doesn't flush these mappings when we reload the PDBR.
		int i = 0;
		int userlo_d = VM_USERLO >> PDXSHIFT;
		int userhi_d = VM_USERHI >> PDXSHIFT;
		for(i; i<userlo_d; i++){
  1048f4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1048f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1048fb:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1048fe:	7c dd                	jl     1048dd <pmap_init+0x27>
			pmap_bootpdir[i] = i << PDXSHIFT | PTE_P | PTE_PS | PTE_G | PTE_W;
		}
		for(i; i<userhi_d; i++){
  104900:	eb 13                	jmp    104915 <pmap_init+0x5f>
			pmap_bootpdir[i] = PTE_ZERO;
  104902:	ba 00 b0 38 00       	mov    $0x38b000,%edx
  104907:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10490a:	89 14 85 00 a0 38 00 	mov    %edx,0x38a000(,%eax,4)
		int userlo_d = VM_USERLO >> PDXSHIFT;
		int userhi_d = VM_USERHI >> PDXSHIFT;
		for(i; i<userlo_d; i++){
			pmap_bootpdir[i] = i << PDXSHIFT | PTE_P | PTE_PS | PTE_G | PTE_W;
		}
		for(i; i<userhi_d; i++){
  104911:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  104915:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104918:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  10491b:	7c e5                	jl     104902 <pmap_init+0x4c>
			pmap_bootpdir[i] = PTE_ZERO;
		}
		for(i; i < NPDENTRIES; i++){
  10491d:	eb 1b                	jmp    10493a <pmap_init+0x84>
			pmap_bootpdir[i] = i << PDXSHIFT| PTE_P | PTE_PS | PTE_G | PTE_W;
  10491f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104922:	c1 e0 16             	shl    $0x16,%eax
  104925:	0d 83 01 00 00       	or     $0x183,%eax
  10492a:	89 c2                	mov    %eax,%edx
  10492c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10492f:	89 14 85 00 a0 38 00 	mov    %edx,0x38a000(,%eax,4)
			pmap_bootpdir[i] = i << PDXSHIFT | PTE_P | PTE_PS | PTE_G | PTE_W;
		}
		for(i; i<userhi_d; i++){
			pmap_bootpdir[i] = PTE_ZERO;
		}
		for(i; i < NPDENTRIES; i++){
  104936:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10493a:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
  104941:	7e dc                	jle    10491f <pmap_init+0x69>

static gcc_inline uint32_t
rcr4(void)
{
	uint32_t cr4;
	__asm __volatile("movl %%cr4,%0" : "=r" (cr4));
  104943:	0f 20 e3             	mov    %cr4,%ebx
  104946:	89 5d e0             	mov    %ebx,-0x20(%ebp)
	return cr4;
  104949:	8b 45 e0             	mov    -0x20(%ebp),%eax
	// where LA == PA according to the page mapping structures.
	// In PIOS this is always the case for the kernel's address space,
	// so we don't have to play any special tricks as in other kernels.

	// Enable 4MB pages and global pages.
	uint32_t cr4 = rcr4();
  10494c:	89 45 e8             	mov    %eax,-0x18(%ebp)
	cr4 |= CR4_PSE | CR4_PGE;
  10494f:	81 4d e8 90 00 00 00 	orl    $0x90,-0x18(%ebp)
  104956:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104959:	89 45 dc             	mov    %eax,-0x24(%ebp)
}

static gcc_inline void
lcr4(uint32_t val)
{
	__asm __volatile("movl %0,%%cr4" : : "r" (val));
  10495c:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10495f:	0f 22 e0             	mov    %eax,%cr4
	lcr4(cr4);

	// Install the bootstrap page directory into the PDBR.
	lcr3(mem_phys(pmap_bootpdir));
  104962:	b8 00 a0 38 00       	mov    $0x38a000,%eax
  104967:	89 45 d8             	mov    %eax,-0x28(%ebp)
}

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  10496a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10496d:	0f 22 d8             	mov    %eax,%cr3

static gcc_inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
  104970:	0f 20 c3             	mov    %cr0,%ebx
  104973:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	return val;
  104976:	8b 45 d4             	mov    -0x2c(%ebp),%eax

	// Turn on paging.
	uint32_t cr0 = rcr0();
  104979:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_MP|CR0_TS;
  10497c:	81 4d e4 2b 00 05 80 	orl    $0x8005002b,-0x1c(%ebp)
	cr0 &= ~(CR0_EM);
  104983:	83 65 e4 fb          	andl   $0xfffffffb,-0x1c(%ebp)
  104987:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10498a:	89 45 d0             	mov    %eax,-0x30(%ebp)
}

static gcc_inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
  10498d:	8b 45 d0             	mov    -0x30(%ebp),%eax
  104990:	0f 22 c0             	mov    %eax,%cr0
	lcr0(cr0);

	// If we survived the lcr0, we're running with paging enabled.
	// Now check the page table management functions below.
	if (cpu_onboot())
  104993:	e8 06 ff ff ff       	call   10489e <cpu_onboot>
  104998:	85 c0                	test   %eax,%eax
  10499a:	74 05                	je     1049a1 <pmap_init+0xeb>
		pmap_check();
  10499c:	e8 46 1c 00 00       	call   1065e7 <pmap_check>
}
  1049a1:	83 c4 34             	add    $0x34,%esp
  1049a4:	5b                   	pop    %ebx
  1049a5:	5d                   	pop    %ebp
  1049a6:	c3                   	ret    

001049a7 <pmap_newpdir>:
// Allocate a new page directory, initialized from the bootstrap pdir.
// Returns the new pdir with a reference count of 1.
//
pte_t *
pmap_newpdir(void)
{
  1049a7:	55                   	push   %ebp
  1049a8:	89 e5                	mov    %esp,%ebp
  1049aa:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  1049ad:	e8 19 c6 ff ff       	call   100fcb <mem_alloc>
  1049b2:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (pi == NULL)
  1049b5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1049b9:	75 0a                	jne    1049c5 <pmap_newpdir+0x1e>
		return NULL;
  1049bb:	b8 00 00 00 00       	mov    $0x0,%eax
  1049c0:	e9 24 01 00 00       	jmp    104ae9 <pmap_newpdir+0x142>
  1049c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1049c8:	89 45 ec             	mov    %eax,-0x14(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1049cb:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1049d0:	83 c0 08             	add    $0x8,%eax
  1049d3:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  1049d6:	76 15                	jbe    1049ed <pmap_newpdir+0x46>
  1049d8:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1049dd:	8b 15 44 8f 38 00    	mov    0x388f44,%edx
  1049e3:	c1 e2 03             	shl    $0x3,%edx
  1049e6:	01 d0                	add    %edx,%eax
  1049e8:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  1049eb:	72 24                	jb     104a11 <pmap_newpdir+0x6a>
  1049ed:	c7 44 24 0c 68 b1 10 	movl   $0x10b168,0xc(%esp)
  1049f4:	00 
  1049f5:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1049fc:	00 
  1049fd:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  104a04:	00 
  104a05:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  104a0c:	e8 27 bf ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  104a11:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104a16:	ba 00 b0 38 00       	mov    $0x38b000,%edx
  104a1b:	c1 ea 0c             	shr    $0xc,%edx
  104a1e:	c1 e2 03             	shl    $0x3,%edx
  104a21:	01 d0                	add    %edx,%eax
  104a23:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  104a26:	75 24                	jne    104a4c <pmap_newpdir+0xa5>
  104a28:	c7 44 24 0c ac b1 10 	movl   $0x10b1ac,0xc(%esp)
  104a2f:	00 
  104a30:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  104a37:	00 
  104a38:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  104a3f:	00 
  104a40:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  104a47:	e8 ec be ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  104a4c:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104a51:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  104a56:	c1 ea 0c             	shr    $0xc,%edx
  104a59:	c1 e2 03             	shl    $0x3,%edx
  104a5c:	01 d0                	add    %edx,%eax
  104a5e:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  104a61:	72 3b                	jb     104a9e <pmap_newpdir+0xf7>
  104a63:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104a68:	ba 07 c0 38 00       	mov    $0x38c007,%edx
  104a6d:	c1 ea 0c             	shr    $0xc,%edx
  104a70:	c1 e2 03             	shl    $0x3,%edx
  104a73:	01 d0                	add    %edx,%eax
  104a75:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  104a78:	77 24                	ja     104a9e <pmap_newpdir+0xf7>
  104a7a:	c7 44 24 0c c8 b1 10 	movl   $0x10b1c8,0xc(%esp)
  104a81:	00 
  104a82:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  104a89:	00 
  104a8a:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  104a91:	00 
  104a92:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  104a99:	e8 9a be ff ff       	call   100938 <debug_panic>

	lockadd(&pi->refcount, 1);
  104a9e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104aa1:	83 c0 04             	add    $0x4,%eax
  104aa4:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104aab:	00 
  104aac:	89 04 24             	mov    %eax,(%esp)
  104aaf:	e8 5c fd ff ff       	call   104810 <lockadd>
	mem_incref(pi);
	pte_t *pdir = mem_pi2ptr(pi);
  104ab4:	8b 55 f4             	mov    -0xc(%ebp),%edx
  104ab7:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104abc:	89 d1                	mov    %edx,%ecx
  104abe:	29 c1                	sub    %eax,%ecx
  104ac0:	89 c8                	mov    %ecx,%eax
  104ac2:	c1 f8 03             	sar    $0x3,%eax
  104ac5:	c1 e0 0c             	shl    $0xc,%eax
  104ac8:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// Initialize it from the bootstrap page directory
	assert(sizeof(pmap_bootpdir) == PAGESIZE);
	memmove(pdir, pmap_bootpdir, PAGESIZE);
  104acb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  104ad2:	00 
  104ad3:	c7 44 24 04 00 a0 38 	movl   $0x38a000,0x4(%esp)
  104ada:	00 
  104adb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104ade:	89 04 24             	mov    %eax,(%esp)
  104ae1:	e8 c9 51 00 00       	call   109caf <memmove>

	return pdir;
  104ae6:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  104ae9:	c9                   	leave  
  104aea:	c3                   	ret    

00104aeb <pmap_freepdir>:

// Free a page directory, and all page tables and mappings it may contain.
void
pmap_freepdir(pageinfo *pdirpi)
{
  104aeb:	55                   	push   %ebp
  104aec:	89 e5                	mov    %esp,%ebp
  104aee:	83 ec 18             	sub    $0x18,%esp
	pmap_remove(mem_pi2ptr(pdirpi), VM_USERLO, VM_USERHI-VM_USERLO);
  104af1:	8b 55 08             	mov    0x8(%ebp),%edx
  104af4:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104af9:	89 d1                	mov    %edx,%ecx
  104afb:	29 c1                	sub    %eax,%ecx
  104afd:	89 c8                	mov    %ecx,%eax
  104aff:	c1 f8 03             	sar    $0x3,%eax
  104b02:	c1 e0 0c             	shl    $0xc,%eax
  104b05:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  104b0c:	b0 
  104b0d:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  104b14:	40 
  104b15:	89 04 24             	mov    %eax,(%esp)
  104b18:	e8 31 06 00 00       	call   10514e <pmap_remove>
	mem_free(pdirpi);
  104b1d:	8b 45 08             	mov    0x8(%ebp),%eax
  104b20:	89 04 24             	mov    %eax,(%esp)
  104b23:	e8 f5 c4 ff ff       	call   10101d <mem_free>
}
  104b28:	c9                   	leave  
  104b29:	c3                   	ret    

00104b2a <pmap_freeptab>:

// Free a page table and all page mappings it may contain.
void
pmap_freeptab(pageinfo *ptabpi)
{
  104b2a:	55                   	push   %ebp
  104b2b:	89 e5                	mov    %esp,%ebp
  104b2d:	83 ec 38             	sub    $0x38,%esp
	pte_t *pte = mem_pi2ptr(ptabpi), *ptelim = pte + NPTENTRIES;
  104b30:	8b 55 08             	mov    0x8(%ebp),%edx
  104b33:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104b38:	89 d1                	mov    %edx,%ecx
  104b3a:	29 c1                	sub    %eax,%ecx
  104b3c:	89 c8                	mov    %ecx,%eax
  104b3e:	c1 f8 03             	sar    $0x3,%eax
  104b41:	c1 e0 0c             	shl    $0xc,%eax
  104b44:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104b47:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104b4a:	05 00 10 00 00       	add    $0x1000,%eax
  104b4f:	89 45 f0             	mov    %eax,-0x10(%ebp)
	for (; pte < ptelim; pte++) {
  104b52:	e9 5f 01 00 00       	jmp    104cb6 <pmap_freeptab+0x18c>
		uint32_t pgaddr = PGADDR(*pte);
  104b57:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104b5a:	8b 00                	mov    (%eax),%eax
  104b5c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104b61:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (pgaddr != PTE_ZERO)
  104b64:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  104b69:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  104b6c:	0f 84 40 01 00 00    	je     104cb2 <pmap_freeptab+0x188>
			mem_decref(mem_phys2pi(pgaddr), mem_free);
  104b72:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104b77:	8b 55 ec             	mov    -0x14(%ebp),%edx
  104b7a:	c1 ea 0c             	shr    $0xc,%edx
  104b7d:	c1 e2 03             	shl    $0x3,%edx
  104b80:	01 d0                	add    %edx,%eax
  104b82:	89 45 e8             	mov    %eax,-0x18(%ebp)
  104b85:	c7 45 e4 1d 10 10 00 	movl   $0x10101d,-0x1c(%ebp)
// Atomically decrement the reference count on a page,
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  104b8c:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104b91:	83 c0 08             	add    $0x8,%eax
  104b94:	39 45 e8             	cmp    %eax,-0x18(%ebp)
  104b97:	76 15                	jbe    104bae <pmap_freeptab+0x84>
  104b99:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104b9e:	8b 15 44 8f 38 00    	mov    0x388f44,%edx
  104ba4:	c1 e2 03             	shl    $0x3,%edx
  104ba7:	01 d0                	add    %edx,%eax
  104ba9:	39 45 e8             	cmp    %eax,-0x18(%ebp)
  104bac:	72 24                	jb     104bd2 <pmap_freeptab+0xa8>
  104bae:	c7 44 24 0c 68 b1 10 	movl   $0x10b168,0xc(%esp)
  104bb5:	00 
  104bb6:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  104bbd:	00 
  104bbe:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  104bc5:	00 
  104bc6:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  104bcd:	e8 66 bd ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  104bd2:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104bd7:	ba 00 b0 38 00       	mov    $0x38b000,%edx
  104bdc:	c1 ea 0c             	shr    $0xc,%edx
  104bdf:	c1 e2 03             	shl    $0x3,%edx
  104be2:	01 d0                	add    %edx,%eax
  104be4:	39 45 e8             	cmp    %eax,-0x18(%ebp)
  104be7:	75 24                	jne    104c0d <pmap_freeptab+0xe3>
  104be9:	c7 44 24 0c ac b1 10 	movl   $0x10b1ac,0xc(%esp)
  104bf0:	00 
  104bf1:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  104bf8:	00 
  104bf9:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  104c00:	00 
  104c01:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  104c08:	e8 2b bd ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  104c0d:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104c12:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  104c17:	c1 ea 0c             	shr    $0xc,%edx
  104c1a:	c1 e2 03             	shl    $0x3,%edx
  104c1d:	01 d0                	add    %edx,%eax
  104c1f:	39 45 e8             	cmp    %eax,-0x18(%ebp)
  104c22:	72 3b                	jb     104c5f <pmap_freeptab+0x135>
  104c24:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104c29:	ba 07 c0 38 00       	mov    $0x38c007,%edx
  104c2e:	c1 ea 0c             	shr    $0xc,%edx
  104c31:	c1 e2 03             	shl    $0x3,%edx
  104c34:	01 d0                	add    %edx,%eax
  104c36:	39 45 e8             	cmp    %eax,-0x18(%ebp)
  104c39:	77 24                	ja     104c5f <pmap_freeptab+0x135>
  104c3b:	c7 44 24 0c c8 b1 10 	movl   $0x10b1c8,0xc(%esp)
  104c42:	00 
  104c43:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  104c4a:	00 
  104c4b:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  104c52:	00 
  104c53:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  104c5a:	e8 d9 bc ff ff       	call   100938 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  104c5f:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104c62:	83 c0 04             	add    $0x4,%eax
  104c65:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  104c6c:	ff 
  104c6d:	89 04 24             	mov    %eax,(%esp)
  104c70:	e8 ac fb ff ff       	call   104821 <lockaddz>
  104c75:	84 c0                	test   %al,%al
  104c77:	74 0b                	je     104c84 <pmap_freeptab+0x15a>
			freefun(pi);
  104c79:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104c7c:	89 04 24             	mov    %eax,(%esp)
  104c7f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104c82:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  104c84:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104c87:	8b 40 04             	mov    0x4(%eax),%eax
  104c8a:	85 c0                	test   %eax,%eax
  104c8c:	79 24                	jns    104cb2 <pmap_freeptab+0x188>
  104c8e:	c7 44 24 0c f9 b1 10 	movl   $0x10b1f9,0xc(%esp)
  104c95:	00 
  104c96:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  104c9d:	00 
  104c9e:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  104ca5:	00 
  104ca6:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  104cad:	e8 86 bc ff ff       	call   100938 <debug_panic>
// Free a page table and all page mappings it may contain.
void
pmap_freeptab(pageinfo *ptabpi)
{
	pte_t *pte = mem_pi2ptr(ptabpi), *ptelim = pte + NPTENTRIES;
	for (; pte < ptelim; pte++) {
  104cb2:	83 45 f4 04          	addl   $0x4,-0xc(%ebp)
  104cb6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104cb9:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  104cbc:	0f 82 95 fe ff ff    	jb     104b57 <pmap_freeptab+0x2d>
		uint32_t pgaddr = PGADDR(*pte);
		if (pgaddr != PTE_ZERO)
			mem_decref(mem_phys2pi(pgaddr), mem_free);
	}
	mem_free(ptabpi);
  104cc2:	8b 45 08             	mov    0x8(%ebp),%eax
  104cc5:	89 04 24             	mov    %eax,(%esp)
  104cc8:	e8 50 c3 ff ff       	call   10101d <mem_free>
}
  104ccd:	c9                   	leave  
  104cce:	c3                   	ret    

00104ccf <pmap_walk>:
// Hint 2: the x86 MMU checks permission bits in both the page directory
// and the page table, so it's safe to leave some page permissions
// more permissive than strictly necessary.
pte_t *
pmap_walk(pde_t *pdir, uint32_t va, bool writing)
{
  104ccf:	55                   	push   %ebp
  104cd0:	89 e5                	mov    %esp,%ebp
  104cd2:	53                   	push   %ebx
  104cd3:	83 ec 44             	sub    $0x44,%esp
	assert(va >= VM_USERLO && va < VM_USERHI);
  104cd6:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  104cdd:	76 09                	jbe    104ce8 <pmap_walk+0x19>
  104cdf:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  104ce6:	76 24                	jbe    104d0c <pmap_walk+0x3d>
  104ce8:	c7 44 24 0c 0c b2 10 	movl   $0x10b20c,0xc(%esp)
  104cef:	00 
  104cf0:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  104cf7:	00 
  104cf8:	c7 44 24 04 ad 00 00 	movl   $0xad,0x4(%esp)
  104cff:	00 
  104d00:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  104d07:	e8 2c bc ff ff       	call   100938 <debug_panic>
	uint32_t pde_i = PDX(va);
  104d0c:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d0f:	c1 e8 16             	shr    $0x16,%eax
  104d12:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint32_t pte_i = PTX(va);
  104d15:	8b 45 0c             	mov    0xc(%ebp),%eax
  104d18:	c1 e8 0c             	shr    $0xc,%eax
  104d1b:	25 ff 03 00 00       	and    $0x3ff,%eax
  104d20:	89 45 ec             	mov    %eax,-0x14(%ebp)
	// Fill in this function
	if(pdir[pde_i] == PTE_ZERO){
  104d23:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104d26:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  104d2d:	8b 45 08             	mov    0x8(%ebp),%eax
  104d30:	01 d0                	add    %edx,%eax
  104d32:	8b 10                	mov    (%eax),%edx
  104d34:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  104d39:	39 c2                	cmp    %eax,%edx
  104d3b:	0f 85 9b 01 00 00    	jne    104edc <pmap_walk+0x20d>
		if(!writing)
  104d41:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  104d45:	75 0a                	jne    104d51 <pmap_walk+0x82>
			return NULL;
  104d47:	b8 00 00 00 00       	mov    $0x0,%eax
  104d4c:	e9 b9 01 00 00       	jmp    104f0a <pmap_walk+0x23b>
		pageinfo* page = mem_alloc();
  104d51:	e8 75 c2 ff ff       	call   100fcb <mem_alloc>
  104d56:	89 45 e8             	mov    %eax,-0x18(%ebp)
		if(!page)
  104d59:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  104d5d:	75 0a                	jne    104d69 <pmap_walk+0x9a>
			return NULL;
  104d5f:	b8 00 00 00 00       	mov    $0x0,%eax
  104d64:	e9 a1 01 00 00       	jmp    104f0a <pmap_walk+0x23b>
  104d69:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104d6c:	89 45 d4             	mov    %eax,-0x2c(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  104d6f:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104d74:	83 c0 08             	add    $0x8,%eax
  104d77:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
  104d7a:	76 15                	jbe    104d91 <pmap_walk+0xc2>
  104d7c:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104d81:	8b 15 44 8f 38 00    	mov    0x388f44,%edx
  104d87:	c1 e2 03             	shl    $0x3,%edx
  104d8a:	01 d0                	add    %edx,%eax
  104d8c:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
  104d8f:	72 24                	jb     104db5 <pmap_walk+0xe6>
  104d91:	c7 44 24 0c 68 b1 10 	movl   $0x10b168,0xc(%esp)
  104d98:	00 
  104d99:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  104da0:	00 
  104da1:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  104da8:	00 
  104da9:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  104db0:	e8 83 bb ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  104db5:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104dba:	ba 00 b0 38 00       	mov    $0x38b000,%edx
  104dbf:	c1 ea 0c             	shr    $0xc,%edx
  104dc2:	c1 e2 03             	shl    $0x3,%edx
  104dc5:	01 d0                	add    %edx,%eax
  104dc7:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
  104dca:	75 24                	jne    104df0 <pmap_walk+0x121>
  104dcc:	c7 44 24 0c ac b1 10 	movl   $0x10b1ac,0xc(%esp)
  104dd3:	00 
  104dd4:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  104ddb:	00 
  104ddc:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  104de3:	00 
  104de4:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  104deb:	e8 48 bb ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  104df0:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104df5:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  104dfa:	c1 ea 0c             	shr    $0xc,%edx
  104dfd:	c1 e2 03             	shl    $0x3,%edx
  104e00:	01 d0                	add    %edx,%eax
  104e02:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
  104e05:	72 3b                	jb     104e42 <pmap_walk+0x173>
  104e07:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104e0c:	ba 07 c0 38 00       	mov    $0x38c007,%edx
  104e11:	c1 ea 0c             	shr    $0xc,%edx
  104e14:	c1 e2 03             	shl    $0x3,%edx
  104e17:	01 d0                	add    %edx,%eax
  104e19:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
  104e1c:	77 24                	ja     104e42 <pmap_walk+0x173>
  104e1e:	c7 44 24 0c c8 b1 10 	movl   $0x10b1c8,0xc(%esp)
  104e25:	00 
  104e26:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  104e2d:	00 
  104e2e:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  104e35:	00 
  104e36:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  104e3d:	e8 f6 ba ff ff       	call   100938 <debug_panic>

	lockadd(&pi->refcount, 1);
  104e42:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  104e45:	83 c0 04             	add    $0x4,%eax
  104e48:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  104e4f:	00 
  104e50:	89 04 24             	mov    %eax,(%esp)
  104e53:	e8 b8 f9 ff ff       	call   104810 <lockadd>
		mem_incref(page);
		pdir[pde_i] = mem_pi2phys(page) | PTE_P | PTE_U | PTE_W | PTE_A;
  104e58:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104e5b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  104e62:	8b 45 08             	mov    0x8(%ebp),%eax
  104e65:	01 c2                	add    %eax,%edx
  104e67:	8b 4d e8             	mov    -0x18(%ebp),%ecx
  104e6a:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104e6f:	89 cb                	mov    %ecx,%ebx
  104e71:	29 c3                	sub    %eax,%ebx
  104e73:	89 d8                	mov    %ebx,%eax
  104e75:	c1 f8 03             	sar    $0x3,%eax
  104e78:	c1 e0 0c             	shl    $0xc,%eax
  104e7b:	83 c8 27             	or     $0x27,%eax
  104e7e:	89 02                	mov    %eax,(%edx)
		int i;
		pte_t* ptable = (pte_t*)PGADDR(pdir[pde_i]);
  104e80:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104e83:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  104e8a:	8b 45 08             	mov    0x8(%ebp),%eax
  104e8d:	01 d0                	add    %edx,%eax
  104e8f:	8b 00                	mov    (%eax),%eax
  104e91:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104e96:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		for(i = 0; i<NPTENTRIES; i++){
  104e99:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  104ea0:	eb 1a                	jmp    104ebc <pmap_walk+0x1ed>
			ptable[i] = PTE_ZERO;
  104ea2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104ea5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  104eac:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104eaf:	01 c2                	add    %eax,%edx
  104eb1:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  104eb6:	89 02                	mov    %eax,(%edx)
			return NULL;
		mem_incref(page);
		pdir[pde_i] = mem_pi2phys(page) | PTE_P | PTE_U | PTE_W | PTE_A;
		int i;
		pte_t* ptable = (pte_t*)PGADDR(pdir[pde_i]);
		for(i = 0; i<NPTENTRIES; i++){
  104eb8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  104ebc:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
  104ec3:	7e dd                	jle    104ea2 <pmap_walk+0x1d3>
			ptable[i] = PTE_ZERO;
		}
		pte_t* pte_ret = (pte_t*) (&(ptable[pte_i]));
  104ec5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104ec8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  104ecf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  104ed2:	01 d0                	add    %edx,%eax
  104ed4:	89 45 e0             	mov    %eax,-0x20(%ebp)
		return pte_ret;
  104ed7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  104eda:	eb 2e                	jmp    104f0a <pmap_walk+0x23b>
	}
	pte_t* pt_has_ret = (pte_t*) (PGADDR(pdir[pde_i]));
  104edc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104edf:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  104ee6:	8b 45 08             	mov    0x8(%ebp),%eax
  104ee9:	01 d0                	add    %edx,%eax
  104eeb:	8b 00                	mov    (%eax),%eax
  104eed:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104ef2:	89 45 dc             	mov    %eax,-0x24(%ebp)
	pte_t* pte_ret = (pte_t*) (&(pt_has_ret[pte_i]));
  104ef5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104ef8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  104eff:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104f02:	01 d0                	add    %edx,%eax
  104f04:	89 45 d8             	mov    %eax,-0x28(%ebp)
	return pte_ret;
  104f07:	8b 45 d8             	mov    -0x28(%ebp),%eax
}
  104f0a:	83 c4 44             	add    $0x44,%esp
  104f0d:	5b                   	pop    %ebx
  104f0e:	5d                   	pop    %ebp
  104f0f:	c3                   	ret    

00104f10 <pmap_insert>:
//
// Hint: The reference solution uses pmap_walk, pmap_remove, and mem_pi2phys.
//
pte_t *
pmap_insert(pde_t *pdir, pageinfo *pi, uint32_t va, int perm)
{
  104f10:	55                   	push   %ebp
  104f11:	89 e5                	mov    %esp,%ebp
  104f13:	83 ec 38             	sub    $0x38,%esp
	// Fill in this function
	uint32_t pte_i = PTX(va);
  104f16:	8b 45 10             	mov    0x10(%ebp),%eax
  104f19:	c1 e8 0c             	shr    $0xc,%eax
  104f1c:	25 ff 03 00 00       	and    $0x3ff,%eax
  104f21:	89 45 f4             	mov    %eax,-0xc(%ebp)
	uint32_t pde_i = PDX(va);
  104f24:	8b 45 10             	mov    0x10(%ebp),%eax
  104f27:	c1 e8 16             	shr    $0x16,%eax
  104f2a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	pte_t* pt_base = (pte_t *)PGADDR(pdir[pde_i]);
  104f2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104f30:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  104f37:	8b 45 08             	mov    0x8(%ebp),%eax
  104f3a:	01 d0                	add    %edx,%eax
  104f3c:	8b 00                	mov    (%eax),%eax
  104f3e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104f43:	89 45 ec             	mov    %eax,-0x14(%ebp)
	uint32_t pte = mem_pi2phys(pi) | perm | PTE_P;
  104f46:	8b 55 0c             	mov    0xc(%ebp),%edx
  104f49:	a1 50 8f 38 00       	mov    0x388f50,%eax
  104f4e:	89 d1                	mov    %edx,%ecx
  104f50:	29 c1                	sub    %eax,%ecx
  104f52:	89 c8                	mov    %ecx,%eax
  104f54:	c1 f8 03             	sar    $0x3,%eax
  104f57:	c1 e0 0c             	shl    $0xc,%eax
  104f5a:	0b 45 14             	or     0x14(%ebp),%eax
  104f5d:	83 c8 01             	or     $0x1,%eax
  104f60:	89 45 e8             	mov    %eax,-0x18(%ebp)
	if((pt_base[pte_i] & 0xfffff000) == (pte & 0xfffff000)){
  104f63:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104f66:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  104f6d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104f70:	01 d0                	add    %edx,%eax
  104f72:	8b 00                	mov    (%eax),%eax
  104f74:	33 45 e8             	xor    -0x18(%ebp),%eax
  104f77:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104f7c:	85 c0                	test   %eax,%eax
  104f7e:	75 42                	jne    104fc2 <pmap_insert+0xb2>
		pt_base[pte_i] = (pte_t)pte;
  104f80:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104f83:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  104f8a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104f8d:	01 c2                	add    %eax,%edx
  104f8f:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104f92:	89 02                	mov    %eax,(%edx)
		pmap_inval(pdir, va, PAGESIZE);
  104f94:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  104f9b:	00 
  104f9c:	8b 45 10             	mov    0x10(%ebp),%eax
  104f9f:	89 44 24 04          	mov    %eax,0x4(%esp)
  104fa3:	8b 45 08             	mov    0x8(%ebp),%eax
  104fa6:	89 04 24             	mov    %eax,(%esp)
  104fa9:	e8 32 08 00 00       	call   1057e0 <pmap_inval>
		return (pte_t*)(&(pt_base[pte_i]));
  104fae:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104fb1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  104fb8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104fbb:	01 d0                	add    %edx,%eax
  104fbd:	e9 8a 01 00 00       	jmp    10514c <pmap_insert+0x23c>
	}
	if((PGADDR(pdir[pde_i]) != PTE_ZERO) && (PGADDR(pt_base[pte_i]) != PTE_ZERO)){
  104fc2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104fc5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  104fcc:	8b 45 08             	mov    0x8(%ebp),%eax
  104fcf:	01 d0                	add    %edx,%eax
  104fd1:	8b 00                	mov    (%eax),%eax
  104fd3:	89 c2                	mov    %eax,%edx
  104fd5:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  104fdb:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  104fe0:	39 c2                	cmp    %eax,%edx
  104fe2:	74 41                	je     105025 <pmap_insert+0x115>
  104fe4:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104fe7:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  104fee:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104ff1:	01 d0                	add    %edx,%eax
  104ff3:	8b 00                	mov    (%eax),%eax
  104ff5:	89 c2                	mov    %eax,%edx
  104ff7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  104ffd:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  105002:	39 c2                	cmp    %eax,%edx
  105004:	74 1f                	je     105025 <pmap_insert+0x115>
		pmap_remove(pdir, PGADDR(va), PAGESIZE);
  105006:	8b 45 10             	mov    0x10(%ebp),%eax
  105009:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10500e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105015:	00 
  105016:	89 44 24 04          	mov    %eax,0x4(%esp)
  10501a:	8b 45 08             	mov    0x8(%ebp),%eax
  10501d:	89 04 24             	mov    %eax,(%esp)
  105020:	e8 29 01 00 00       	call   10514e <pmap_remove>
	}
	pte_t* pte_add = pmap_walk(pdir, va, 1);
  105025:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  10502c:	00 
  10502d:	8b 45 10             	mov    0x10(%ebp),%eax
  105030:	89 44 24 04          	mov    %eax,0x4(%esp)
  105034:	8b 45 08             	mov    0x8(%ebp),%eax
  105037:	89 04 24             	mov    %eax,(%esp)
  10503a:	e8 90 fc ff ff       	call   104ccf <pmap_walk>
  10503f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	if(!pte_add)
  105042:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  105046:	75 0a                	jne    105052 <pmap_insert+0x142>
		return NULL;
  105048:	b8 00 00 00 00       	mov    $0x0,%eax
  10504d:	e9 fa 00 00 00       	jmp    10514c <pmap_insert+0x23c>
	pte_add[0] = pte;
  105052:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105055:	8b 55 e8             	mov    -0x18(%ebp),%edx
  105058:	89 10                	mov    %edx,(%eax)
  10505a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10505d:	89 45 e0             	mov    %eax,-0x20(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  105060:	a1 50 8f 38 00       	mov    0x388f50,%eax
  105065:	83 c0 08             	add    $0x8,%eax
  105068:	39 45 e0             	cmp    %eax,-0x20(%ebp)
  10506b:	76 15                	jbe    105082 <pmap_insert+0x172>
  10506d:	a1 50 8f 38 00       	mov    0x388f50,%eax
  105072:	8b 15 44 8f 38 00    	mov    0x388f44,%edx
  105078:	c1 e2 03             	shl    $0x3,%edx
  10507b:	01 d0                	add    %edx,%eax
  10507d:	39 45 e0             	cmp    %eax,-0x20(%ebp)
  105080:	72 24                	jb     1050a6 <pmap_insert+0x196>
  105082:	c7 44 24 0c 68 b1 10 	movl   $0x10b168,0xc(%esp)
  105089:	00 
  10508a:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105091:	00 
  105092:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  105099:	00 
  10509a:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  1050a1:	e8 92 b8 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1050a6:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1050ab:	ba 00 b0 38 00       	mov    $0x38b000,%edx
  1050b0:	c1 ea 0c             	shr    $0xc,%edx
  1050b3:	c1 e2 03             	shl    $0x3,%edx
  1050b6:	01 d0                	add    %edx,%eax
  1050b8:	39 45 e0             	cmp    %eax,-0x20(%ebp)
  1050bb:	75 24                	jne    1050e1 <pmap_insert+0x1d1>
  1050bd:	c7 44 24 0c ac b1 10 	movl   $0x10b1ac,0xc(%esp)
  1050c4:	00 
  1050c5:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1050cc:	00 
  1050cd:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  1050d4:	00 
  1050d5:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  1050dc:	e8 57 b8 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1050e1:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1050e6:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  1050eb:	c1 ea 0c             	shr    $0xc,%edx
  1050ee:	c1 e2 03             	shl    $0x3,%edx
  1050f1:	01 d0                	add    %edx,%eax
  1050f3:	39 45 e0             	cmp    %eax,-0x20(%ebp)
  1050f6:	72 3b                	jb     105133 <pmap_insert+0x223>
  1050f8:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1050fd:	ba 07 c0 38 00       	mov    $0x38c007,%edx
  105102:	c1 ea 0c             	shr    $0xc,%edx
  105105:	c1 e2 03             	shl    $0x3,%edx
  105108:	01 d0                	add    %edx,%eax
  10510a:	39 45 e0             	cmp    %eax,-0x20(%ebp)
  10510d:	77 24                	ja     105133 <pmap_insert+0x223>
  10510f:	c7 44 24 0c c8 b1 10 	movl   $0x10b1c8,0xc(%esp)
  105116:	00 
  105117:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10511e:	00 
  10511f:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  105126:	00 
  105127:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  10512e:	e8 05 b8 ff ff       	call   100938 <debug_panic>

	lockadd(&pi->refcount, 1);
  105133:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105136:	83 c0 04             	add    $0x4,%eax
  105139:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105140:	00 
  105141:	89 04 24             	mov    %eax,(%esp)
  105144:	e8 c7 f6 ff ff       	call   104810 <lockadd>
	//cprintf("in pmap insert, pte: %x.\n", *pmap_walk(pdir, va, false));
	mem_incref(pi);
	return (pte_t*)(pte_add);
  105149:	8b 45 e4             	mov    -0x1c(%ebp),%eax
}
  10514c:	c9                   	leave  
  10514d:	c3                   	ret    

0010514e <pmap_remove>:
// Hint: The TA solution is implemented using pmap_lookup,
// 	pmap_inval, and mem_decref.
//
void
pmap_remove(pde_t *pdir, uint32_t va, size_t size)
{
  10514e:	55                   	push   %ebp
  10514f:	89 e5                	mov    %esp,%ebp
  105151:	83 ec 58             	sub    $0x58,%esp
	assert(PGOFF(size) == 0);	// must be page-aligned
  105154:	8b 45 10             	mov    0x10(%ebp),%eax
  105157:	25 ff 0f 00 00       	and    $0xfff,%eax
  10515c:	85 c0                	test   %eax,%eax
  10515e:	74 24                	je     105184 <pmap_remove+0x36>
  105160:	c7 44 24 0c 3a b2 10 	movl   $0x10b23a,0xc(%esp)
  105167:	00 
  105168:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10516f:	00 
  105170:	c7 44 24 04 0b 01 00 	movl   $0x10b,0x4(%esp)
  105177:	00 
  105178:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10517f:	e8 b4 b7 ff ff       	call   100938 <debug_panic>
	assert(va >= VM_USERLO && va < VM_USERHI);
  105184:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  10518b:	76 09                	jbe    105196 <pmap_remove+0x48>
  10518d:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  105194:	76 24                	jbe    1051ba <pmap_remove+0x6c>
  105196:	c7 44 24 0c 0c b2 10 	movl   $0x10b20c,0xc(%esp)
  10519d:	00 
  10519e:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1051a5:	00 
  1051a6:	c7 44 24 04 0c 01 00 	movl   $0x10c,0x4(%esp)
  1051ad:	00 
  1051ae:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1051b5:	e8 7e b7 ff ff       	call   100938 <debug_panic>
	assert(size <= VM_USERHI - va);
  1051ba:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1051bf:	2b 45 0c             	sub    0xc(%ebp),%eax
  1051c2:	3b 45 10             	cmp    0x10(%ebp),%eax
  1051c5:	73 24                	jae    1051eb <pmap_remove+0x9d>
  1051c7:	c7 44 24 0c 4b b2 10 	movl   $0x10b24b,0xc(%esp)
  1051ce:	00 
  1051cf:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1051d6:	00 
  1051d7:	c7 44 24 04 0d 01 00 	movl   $0x10d,0x4(%esp)
  1051de:	00 
  1051df:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1051e6:	e8 4d b7 ff ff       	call   100938 <debug_panic>

	uint32_t pde_i = PDX(va);
  1051eb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1051ee:	c1 e8 16             	shr    $0x16,%eax
  1051f1:	89 45 f0             	mov    %eax,-0x10(%ebp)
	uint32_t pte_i = PTX(va);
  1051f4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1051f7:	c1 e8 0c             	shr    $0xc,%eax
  1051fa:	25 ff 03 00 00       	and    $0x3ff,%eax
  1051ff:	89 45 ec             	mov    %eax,-0x14(%ebp)
	int page_account = size/PAGESIZE;
  105202:	8b 45 10             	mov    0x10(%ebp),%eax
  105205:	c1 e8 0c             	shr    $0xc,%eax
  105208:	89 45 e8             	mov    %eax,-0x18(%ebp)
	int remove_pde_no = (page_account+pte_i) / NPTENTRIES;
  10520b:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10520e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105211:	01 d0                	add    %edx,%eax
  105213:	c1 e8 0a             	shr    $0xa,%eax
  105216:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int i = 0;
  105219:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	for(i; i < page_account; i++){
  105220:	e9 46 02 00 00       	jmp    10546b <pmap_remove+0x31d>
		pte_t* pt_base = (pte_t*)PGADDR(pdir[pde_i + i/NPDENTRIES]);
  105225:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105228:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
  10522e:	85 c0                	test   %eax,%eax
  105230:	0f 48 c2             	cmovs  %edx,%eax
  105233:	c1 f8 0a             	sar    $0xa,%eax
  105236:	89 c2                	mov    %eax,%edx
  105238:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10523b:	01 d0                	add    %edx,%eax
  10523d:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  105244:	8b 45 08             	mov    0x8(%ebp),%eax
  105247:	01 d0                	add    %edx,%eax
  105249:	8b 00                	mov    (%eax),%eax
  10524b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105250:	89 45 e0             	mov    %eax,-0x20(%ebp)
		if((PGADDR(pdir[pde_i + i/NPDENTRIES]) != PTE_ZERO) && (PGADDR(pt_base[(pte_i + i) % NPTENTRIES]) != PTE_ZERO)){
  105253:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105256:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
  10525c:	85 c0                	test   %eax,%eax
  10525e:	0f 48 c2             	cmovs  %edx,%eax
  105261:	c1 f8 0a             	sar    $0xa,%eax
  105264:	89 c2                	mov    %eax,%edx
  105266:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105269:	01 d0                	add    %edx,%eax
  10526b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  105272:	8b 45 08             	mov    0x8(%ebp),%eax
  105275:	01 d0                	add    %edx,%eax
  105277:	8b 00                	mov    (%eax),%eax
  105279:	89 c2                	mov    %eax,%edx
  10527b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  105281:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  105286:	39 c2                	cmp    %eax,%edx
  105288:	0f 84 d9 01 00 00    	je     105467 <pmap_remove+0x319>
  10528e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105291:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105294:	01 d0                	add    %edx,%eax
  105296:	25 ff 03 00 00       	and    $0x3ff,%eax
  10529b:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  1052a2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1052a5:	01 d0                	add    %edx,%eax
  1052a7:	8b 00                	mov    (%eax),%eax
  1052a9:	89 c2                	mov    %eax,%edx
  1052ab:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  1052b1:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  1052b6:	39 c2                	cmp    %eax,%edx
  1052b8:	0f 84 a9 01 00 00    	je     105467 <pmap_remove+0x319>
			pageinfo* pi = (pageinfo*)mem_phys2pi(PGADDR(pt_base[(pte_i + i)%NPTENTRIES]));
  1052be:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1052c3:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  1052c6:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1052c9:	01 ca                	add    %ecx,%edx
  1052cb:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
  1052d1:	8d 0c 95 00 00 00 00 	lea    0x0(,%edx,4),%ecx
  1052d8:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1052db:	01 ca                	add    %ecx,%edx
  1052dd:	8b 12                	mov    (%edx),%edx
  1052df:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  1052e5:	c1 ea 0c             	shr    $0xc,%edx
  1052e8:	c1 e2 03             	shl    $0x3,%edx
  1052eb:	01 d0                	add    %edx,%eax
  1052ed:	89 45 dc             	mov    %eax,-0x24(%ebp)
			// Fill in this function
			if(pi){
  1052f0:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  1052f4:	0f 84 6d 01 00 00    	je     105467 <pmap_remove+0x319>
  1052fa:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1052fd:	89 45 d8             	mov    %eax,-0x28(%ebp)
  105300:	c7 45 d4 1d 10 10 00 	movl   $0x10101d,-0x2c(%ebp)
// Atomically decrement the reference count on a page,
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  105307:	a1 50 8f 38 00       	mov    0x388f50,%eax
  10530c:	83 c0 08             	add    $0x8,%eax
  10530f:	39 45 d8             	cmp    %eax,-0x28(%ebp)
  105312:	76 15                	jbe    105329 <pmap_remove+0x1db>
  105314:	a1 50 8f 38 00       	mov    0x388f50,%eax
  105319:	8b 15 44 8f 38 00    	mov    0x388f44,%edx
  10531f:	c1 e2 03             	shl    $0x3,%edx
  105322:	01 d0                	add    %edx,%eax
  105324:	39 45 d8             	cmp    %eax,-0x28(%ebp)
  105327:	72 24                	jb     10534d <pmap_remove+0x1ff>
  105329:	c7 44 24 0c 68 b1 10 	movl   $0x10b168,0xc(%esp)
  105330:	00 
  105331:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105338:	00 
  105339:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  105340:	00 
  105341:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  105348:	e8 eb b5 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  10534d:	a1 50 8f 38 00       	mov    0x388f50,%eax
  105352:	ba 00 b0 38 00       	mov    $0x38b000,%edx
  105357:	c1 ea 0c             	shr    $0xc,%edx
  10535a:	c1 e2 03             	shl    $0x3,%edx
  10535d:	01 d0                	add    %edx,%eax
  10535f:	39 45 d8             	cmp    %eax,-0x28(%ebp)
  105362:	75 24                	jne    105388 <pmap_remove+0x23a>
  105364:	c7 44 24 0c ac b1 10 	movl   $0x10b1ac,0xc(%esp)
  10536b:	00 
  10536c:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105373:	00 
  105374:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  10537b:	00 
  10537c:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  105383:	e8 b0 b5 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  105388:	a1 50 8f 38 00       	mov    0x388f50,%eax
  10538d:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  105392:	c1 ea 0c             	shr    $0xc,%edx
  105395:	c1 e2 03             	shl    $0x3,%edx
  105398:	01 d0                	add    %edx,%eax
  10539a:	39 45 d8             	cmp    %eax,-0x28(%ebp)
  10539d:	72 3b                	jb     1053da <pmap_remove+0x28c>
  10539f:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1053a4:	ba 07 c0 38 00       	mov    $0x38c007,%edx
  1053a9:	c1 ea 0c             	shr    $0xc,%edx
  1053ac:	c1 e2 03             	shl    $0x3,%edx
  1053af:	01 d0                	add    %edx,%eax
  1053b1:	39 45 d8             	cmp    %eax,-0x28(%ebp)
  1053b4:	77 24                	ja     1053da <pmap_remove+0x28c>
  1053b6:	c7 44 24 0c c8 b1 10 	movl   $0x10b1c8,0xc(%esp)
  1053bd:	00 
  1053be:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1053c5:	00 
  1053c6:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  1053cd:	00 
  1053ce:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  1053d5:	e8 5e b5 ff ff       	call   100938 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  1053da:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1053dd:	83 c0 04             	add    $0x4,%eax
  1053e0:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  1053e7:	ff 
  1053e8:	89 04 24             	mov    %eax,(%esp)
  1053eb:	e8 31 f4 ff ff       	call   104821 <lockaddz>
  1053f0:	84 c0                	test   %al,%al
  1053f2:	74 0b                	je     1053ff <pmap_remove+0x2b1>
			freefun(pi);
  1053f4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1053f7:	89 04 24             	mov    %eax,(%esp)
  1053fa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1053fd:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  1053ff:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105402:	8b 40 04             	mov    0x4(%eax),%eax
  105405:	85 c0                	test   %eax,%eax
  105407:	79 24                	jns    10542d <pmap_remove+0x2df>
  105409:	c7 44 24 0c f9 b1 10 	movl   $0x10b1f9,0xc(%esp)
  105410:	00 
  105411:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105418:	00 
  105419:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  105420:	00 
  105421:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  105428:	e8 0b b5 ff ff       	call   100938 <debug_panic>
				mem_decref(pi, mem_free);
				pt_base[(pte_i+i)%NPTENTRIES] = PTE_ZERO;
  10542d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105430:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105433:	01 d0                	add    %edx,%eax
  105435:	25 ff 03 00 00       	and    $0x3ff,%eax
  10543a:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  105441:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105444:	01 c2                	add    %eax,%edx
  105446:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  10544b:	89 02                	mov    %eax,(%edx)
				pmap_inval(pdir, va, PAGESIZE);
  10544d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105454:	00 
  105455:	8b 45 0c             	mov    0xc(%ebp),%eax
  105458:	89 44 24 04          	mov    %eax,0x4(%esp)
  10545c:	8b 45 08             	mov    0x8(%ebp),%eax
  10545f:	89 04 24             	mov    %eax,(%esp)
  105462:	e8 79 03 00 00       	call   1057e0 <pmap_inval>
	uint32_t pde_i = PDX(va);
	uint32_t pte_i = PTX(va);
	int page_account = size/PAGESIZE;
	int remove_pde_no = (page_account+pte_i) / NPTENTRIES;
	int i = 0;
	for(i; i < page_account; i++){
  105467:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  10546b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10546e:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  105471:	0f 8c ae fd ff ff    	jl     105225 <pmap_remove+0xd7>
				pt_base[(pte_i+i)%NPTENTRIES] = PTE_ZERO;
				pmap_inval(pdir, va, PAGESIZE);
			}
		}
	}
	if(remove_pde_no > 0){
  105477:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  10547b:	0f 8e 5d 03 00 00    	jle    1057de <pmap_remove+0x690>
		for(i = 1; i <= remove_pde_no; i++){
  105481:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  105488:	e9 45 03 00 00       	jmp    1057d2 <pmap_remove+0x684>
				if(!hasEntry){
					mem_decref((pageinfo *)mem_phys2pi(PGADDR(pdir[pde_i + i])), mem_free);
					pdir[pde_i+i] = PTE_ZERO;
				}
			}*/
			if(i == 1){
  10548d:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
  105491:	0f 85 97 01 00 00    	jne    10562e <pmap_remove+0x4e0>
				if(pte_i == 0){
  105497:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  10549b:	0f 85 2d 03 00 00    	jne    1057ce <pmap_remove+0x680>
					if(pdir[pde_i] != PTE_ZERO){
  1054a1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1054a4:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  1054ab:	8b 45 08             	mov    0x8(%ebp),%eax
  1054ae:	01 d0                	add    %edx,%eax
  1054b0:	8b 10                	mov    (%eax),%edx
  1054b2:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  1054b7:	39 c2                	cmp    %eax,%edx
  1054b9:	0f 84 0f 03 00 00    	je     1057ce <pmap_remove+0x680>
						mem_decref((pageinfo *)mem_phys2pi(PGADDR(pdir[pde_i])), mem_free);
  1054bf:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1054c4:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1054c7:	8d 0c 95 00 00 00 00 	lea    0x0(,%edx,4),%ecx
  1054ce:	8b 55 08             	mov    0x8(%ebp),%edx
  1054d1:	01 ca                	add    %ecx,%edx
  1054d3:	8b 12                	mov    (%edx),%edx
  1054d5:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  1054db:	c1 ea 0c             	shr    $0xc,%edx
  1054de:	c1 e2 03             	shl    $0x3,%edx
  1054e1:	01 d0                	add    %edx,%eax
  1054e3:	89 45 d0             	mov    %eax,-0x30(%ebp)
  1054e6:	c7 45 cc 1d 10 10 00 	movl   $0x10101d,-0x34(%ebp)
// Atomically decrement the reference count on a page,
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1054ed:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1054f2:	83 c0 08             	add    $0x8,%eax
  1054f5:	39 45 d0             	cmp    %eax,-0x30(%ebp)
  1054f8:	76 15                	jbe    10550f <pmap_remove+0x3c1>
  1054fa:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1054ff:	8b 15 44 8f 38 00    	mov    0x388f44,%edx
  105505:	c1 e2 03             	shl    $0x3,%edx
  105508:	01 d0                	add    %edx,%eax
  10550a:	39 45 d0             	cmp    %eax,-0x30(%ebp)
  10550d:	72 24                	jb     105533 <pmap_remove+0x3e5>
  10550f:	c7 44 24 0c 68 b1 10 	movl   $0x10b168,0xc(%esp)
  105516:	00 
  105517:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10551e:	00 
  10551f:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  105526:	00 
  105527:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  10552e:	e8 05 b4 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  105533:	a1 50 8f 38 00       	mov    0x388f50,%eax
  105538:	ba 00 b0 38 00       	mov    $0x38b000,%edx
  10553d:	c1 ea 0c             	shr    $0xc,%edx
  105540:	c1 e2 03             	shl    $0x3,%edx
  105543:	01 d0                	add    %edx,%eax
  105545:	39 45 d0             	cmp    %eax,-0x30(%ebp)
  105548:	75 24                	jne    10556e <pmap_remove+0x420>
  10554a:	c7 44 24 0c ac b1 10 	movl   $0x10b1ac,0xc(%esp)
  105551:	00 
  105552:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105559:	00 
  10555a:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  105561:	00 
  105562:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  105569:	e8 ca b3 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  10556e:	a1 50 8f 38 00       	mov    0x388f50,%eax
  105573:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  105578:	c1 ea 0c             	shr    $0xc,%edx
  10557b:	c1 e2 03             	shl    $0x3,%edx
  10557e:	01 d0                	add    %edx,%eax
  105580:	39 45 d0             	cmp    %eax,-0x30(%ebp)
  105583:	72 3b                	jb     1055c0 <pmap_remove+0x472>
  105585:	a1 50 8f 38 00       	mov    0x388f50,%eax
  10558a:	ba 07 c0 38 00       	mov    $0x38c007,%edx
  10558f:	c1 ea 0c             	shr    $0xc,%edx
  105592:	c1 e2 03             	shl    $0x3,%edx
  105595:	01 d0                	add    %edx,%eax
  105597:	39 45 d0             	cmp    %eax,-0x30(%ebp)
  10559a:	77 24                	ja     1055c0 <pmap_remove+0x472>
  10559c:	c7 44 24 0c c8 b1 10 	movl   $0x10b1c8,0xc(%esp)
  1055a3:	00 
  1055a4:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1055ab:	00 
  1055ac:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  1055b3:	00 
  1055b4:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  1055bb:	e8 78 b3 ff ff       	call   100938 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  1055c0:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1055c3:	83 c0 04             	add    $0x4,%eax
  1055c6:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  1055cd:	ff 
  1055ce:	89 04 24             	mov    %eax,(%esp)
  1055d1:	e8 4b f2 ff ff       	call   104821 <lockaddz>
  1055d6:	84 c0                	test   %al,%al
  1055d8:	74 0b                	je     1055e5 <pmap_remove+0x497>
			freefun(pi);
  1055da:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1055dd:	89 04 24             	mov    %eax,(%esp)
  1055e0:	8b 45 cc             	mov    -0x34(%ebp),%eax
  1055e3:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  1055e5:	8b 45 d0             	mov    -0x30(%ebp),%eax
  1055e8:	8b 40 04             	mov    0x4(%eax),%eax
  1055eb:	85 c0                	test   %eax,%eax
  1055ed:	79 24                	jns    105613 <pmap_remove+0x4c5>
  1055ef:	c7 44 24 0c f9 b1 10 	movl   $0x10b1f9,0xc(%esp)
  1055f6:	00 
  1055f7:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1055fe:	00 
  1055ff:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  105606:	00 
  105607:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  10560e:	e8 25 b3 ff ff       	call   100938 <debug_panic>
						pdir[pde_i] = PTE_ZERO;
  105613:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105616:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  10561d:	8b 45 08             	mov    0x8(%ebp),%eax
  105620:	01 c2                	add    %eax,%edx
  105622:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  105627:	89 02                	mov    %eax,(%edx)
  105629:	e9 a0 01 00 00       	jmp    1057ce <pmap_remove+0x680>
					}
				}
			}else{
				if(pdir[pde_i + i -1] != PTE_ZERO){
  10562e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  105631:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105634:	01 d0                	add    %edx,%eax
  105636:	83 e8 01             	sub    $0x1,%eax
  105639:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  105640:	8b 45 08             	mov    0x8(%ebp),%eax
  105643:	01 d0                	add    %edx,%eax
  105645:	8b 10                	mov    (%eax),%edx
  105647:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  10564c:	39 c2                	cmp    %eax,%edx
  10564e:	0f 84 7a 01 00 00    	je     1057ce <pmap_remove+0x680>
					mem_decref((pageinfo *)mem_phys2pi(PGADDR(pdir[pde_i + i -1])), mem_free);
  105654:	a1 50 8f 38 00       	mov    0x388f50,%eax
  105659:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  10565c:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10565f:	01 ca                	add    %ecx,%edx
  105661:	83 ea 01             	sub    $0x1,%edx
  105664:	8d 0c 95 00 00 00 00 	lea    0x0(,%edx,4),%ecx
  10566b:	8b 55 08             	mov    0x8(%ebp),%edx
  10566e:	01 ca                	add    %ecx,%edx
  105670:	8b 12                	mov    (%edx),%edx
  105672:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  105678:	c1 ea 0c             	shr    $0xc,%edx
  10567b:	c1 e2 03             	shl    $0x3,%edx
  10567e:	01 d0                	add    %edx,%eax
  105680:	89 45 c8             	mov    %eax,-0x38(%ebp)
  105683:	c7 45 c4 1d 10 10 00 	movl   $0x10101d,-0x3c(%ebp)
// Atomically decrement the reference count on a page,
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  10568a:	a1 50 8f 38 00       	mov    0x388f50,%eax
  10568f:	83 c0 08             	add    $0x8,%eax
  105692:	39 45 c8             	cmp    %eax,-0x38(%ebp)
  105695:	76 15                	jbe    1056ac <pmap_remove+0x55e>
  105697:	a1 50 8f 38 00       	mov    0x388f50,%eax
  10569c:	8b 15 44 8f 38 00    	mov    0x388f44,%edx
  1056a2:	c1 e2 03             	shl    $0x3,%edx
  1056a5:	01 d0                	add    %edx,%eax
  1056a7:	39 45 c8             	cmp    %eax,-0x38(%ebp)
  1056aa:	72 24                	jb     1056d0 <pmap_remove+0x582>
  1056ac:	c7 44 24 0c 68 b1 10 	movl   $0x10b168,0xc(%esp)
  1056b3:	00 
  1056b4:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1056bb:	00 
  1056bc:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  1056c3:	00 
  1056c4:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  1056cb:	e8 68 b2 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1056d0:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1056d5:	ba 00 b0 38 00       	mov    $0x38b000,%edx
  1056da:	c1 ea 0c             	shr    $0xc,%edx
  1056dd:	c1 e2 03             	shl    $0x3,%edx
  1056e0:	01 d0                	add    %edx,%eax
  1056e2:	39 45 c8             	cmp    %eax,-0x38(%ebp)
  1056e5:	75 24                	jne    10570b <pmap_remove+0x5bd>
  1056e7:	c7 44 24 0c ac b1 10 	movl   $0x10b1ac,0xc(%esp)
  1056ee:	00 
  1056ef:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1056f6:	00 
  1056f7:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  1056fe:	00 
  1056ff:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  105706:	e8 2d b2 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  10570b:	a1 50 8f 38 00       	mov    0x388f50,%eax
  105710:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  105715:	c1 ea 0c             	shr    $0xc,%edx
  105718:	c1 e2 03             	shl    $0x3,%edx
  10571b:	01 d0                	add    %edx,%eax
  10571d:	39 45 c8             	cmp    %eax,-0x38(%ebp)
  105720:	72 3b                	jb     10575d <pmap_remove+0x60f>
  105722:	a1 50 8f 38 00       	mov    0x388f50,%eax
  105727:	ba 07 c0 38 00       	mov    $0x38c007,%edx
  10572c:	c1 ea 0c             	shr    $0xc,%edx
  10572f:	c1 e2 03             	shl    $0x3,%edx
  105732:	01 d0                	add    %edx,%eax
  105734:	39 45 c8             	cmp    %eax,-0x38(%ebp)
  105737:	77 24                	ja     10575d <pmap_remove+0x60f>
  105739:	c7 44 24 0c c8 b1 10 	movl   $0x10b1c8,0xc(%esp)
  105740:	00 
  105741:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105748:	00 
  105749:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  105750:	00 
  105751:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  105758:	e8 db b1 ff ff       	call   100938 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  10575d:	8b 45 c8             	mov    -0x38(%ebp),%eax
  105760:	83 c0 04             	add    $0x4,%eax
  105763:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  10576a:	ff 
  10576b:	89 04 24             	mov    %eax,(%esp)
  10576e:	e8 ae f0 ff ff       	call   104821 <lockaddz>
  105773:	84 c0                	test   %al,%al
  105775:	74 0b                	je     105782 <pmap_remove+0x634>
			freefun(pi);
  105777:	8b 45 c8             	mov    -0x38(%ebp),%eax
  10577a:	89 04 24             	mov    %eax,(%esp)
  10577d:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  105780:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  105782:	8b 45 c8             	mov    -0x38(%ebp),%eax
  105785:	8b 40 04             	mov    0x4(%eax),%eax
  105788:	85 c0                	test   %eax,%eax
  10578a:	79 24                	jns    1057b0 <pmap_remove+0x662>
  10578c:	c7 44 24 0c f9 b1 10 	movl   $0x10b1f9,0xc(%esp)
  105793:	00 
  105794:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10579b:	00 
  10579c:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  1057a3:	00 
  1057a4:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  1057ab:	e8 88 b1 ff ff       	call   100938 <debug_panic>
					pdir[pde_i + i -1] = PTE_ZERO;
  1057b0:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1057b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1057b6:	01 d0                	add    %edx,%eax
  1057b8:	83 e8 01             	sub    $0x1,%eax
  1057bb:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  1057c2:	8b 45 08             	mov    0x8(%ebp),%eax
  1057c5:	01 c2                	add    %eax,%edx
  1057c7:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  1057cc:	89 02                	mov    %eax,(%edx)
				pmap_inval(pdir, va, PAGESIZE);
			}
		}
	}
	if(remove_pde_no > 0){
		for(i = 1; i <= remove_pde_no; i++){
  1057ce:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1057d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1057d5:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  1057d8:	0f 8e af fc ff ff    	jle    10548d <pmap_remove+0x33f>
					pdir[pde_i + i -1] = PTE_ZERO;
				}
			}
		}
	}
}
  1057de:	c9                   	leave  
  1057df:	c3                   	ret    

001057e0 <pmap_inval>:
// but only if the page tables being edited are the ones
// currently in use by the processor.
//
void
pmap_inval(pde_t *pdir, uint32_t va, size_t size)
{
  1057e0:	55                   	push   %ebp
  1057e1:	89 e5                	mov    %esp,%ebp
  1057e3:	83 ec 28             	sub    $0x28,%esp
	// Flush the entry only if we're modifying the current address space.
	proc *p = proc_cur();
  1057e6:	e8 59 f0 ff ff       	call   104844 <cpu_cur>
  1057eb:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1057f1:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (p == NULL || p->pdir == pdir) {
  1057f4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1057f8:	74 0e                	je     105808 <pmap_inval+0x28>
  1057fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1057fd:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  105803:	3b 45 08             	cmp    0x8(%ebp),%eax
  105806:	75 2f                	jne    105837 <pmap_inval+0x57>
		if (size == PAGESIZE)
  105808:	81 7d 10 00 10 00 00 	cmpl   $0x1000,0x10(%ebp)
  10580f:	75 0e                	jne    10581f <pmap_inval+0x3f>
			invlpg(mem_ptr(va));	// invalidate one page
  105811:	8b 45 0c             	mov    0xc(%ebp),%eax
  105814:	89 45 f0             	mov    %eax,-0x10(%ebp)
}

static gcc_inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
  105817:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10581a:	0f 01 38             	invlpg (%eax)
  10581d:	eb 18                	jmp    105837 <pmap_inval+0x57>
		else{
			lcr3(mem_phys(pdir));	// invalidate everything
  10581f:	8b 45 08             	mov    0x8(%ebp),%eax
  105822:	89 45 ec             	mov    %eax,-0x14(%ebp)
}

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  105825:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105828:	0f 22 d8             	mov    %eax,%cr3
			cprintf("in pmap_inval, flush done.\n");
  10582b:	c7 04 24 62 b2 10 00 	movl   $0x10b262,(%esp)
  105832:	e8 99 40 00 00       	call   1098d0 <cprintf>
		}
	}
}
  105837:	c9                   	leave  
  105838:	c3                   	ret    

00105839 <pmap_copy>:
// Returns true if successfull, false if not enough memory for copy.
//
int
pmap_copy(pde_t *spdir, uint32_t sva, pde_t *dpdir, uint32_t dva,
		size_t size)
{
  105839:	55                   	push   %ebp
  10583a:	89 e5                	mov    %esp,%ebp
  10583c:	83 ec 38             	sub    $0x38,%esp
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
  10583f:	8b 45 0c             	mov    0xc(%ebp),%eax
  105842:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  105847:	85 c0                	test   %eax,%eax
  105849:	74 24                	je     10586f <pmap_copy+0x36>
  10584b:	c7 44 24 0c 7e b2 10 	movl   $0x10b27e,0xc(%esp)
  105852:	00 
  105853:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10585a:	00 
  10585b:	c7 44 24 04 60 01 00 	movl   $0x160,0x4(%esp)
  105862:	00 
  105863:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10586a:	e8 c9 b0 ff ff       	call   100938 <debug_panic>
	assert(PTOFF(dva) == 0);
  10586f:	8b 45 14             	mov    0x14(%ebp),%eax
  105872:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  105877:	85 c0                	test   %eax,%eax
  105879:	74 24                	je     10589f <pmap_copy+0x66>
  10587b:	c7 44 24 0c 8e b2 10 	movl   $0x10b28e,0xc(%esp)
  105882:	00 
  105883:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10588a:	00 
  10588b:	c7 44 24 04 61 01 00 	movl   $0x161,0x4(%esp)
  105892:	00 
  105893:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10589a:	e8 99 b0 ff ff       	call   100938 <debug_panic>
	assert(PTOFF(size) == 0);
  10589f:	8b 45 18             	mov    0x18(%ebp),%eax
  1058a2:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  1058a7:	85 c0                	test   %eax,%eax
  1058a9:	74 24                	je     1058cf <pmap_copy+0x96>
  1058ab:	c7 44 24 0c 9e b2 10 	movl   $0x10b29e,0xc(%esp)
  1058b2:	00 
  1058b3:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1058ba:	00 
  1058bb:	c7 44 24 04 62 01 00 	movl   $0x162,0x4(%esp)
  1058c2:	00 
  1058c3:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1058ca:	e8 69 b0 ff ff       	call   100938 <debug_panic>
	assert(sva >= VM_USERLO && sva < VM_USERHI);
  1058cf:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  1058d6:	76 09                	jbe    1058e1 <pmap_copy+0xa8>
  1058d8:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  1058df:	76 24                	jbe    105905 <pmap_copy+0xcc>
  1058e1:	c7 44 24 0c b0 b2 10 	movl   $0x10b2b0,0xc(%esp)
  1058e8:	00 
  1058e9:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1058f0:	00 
  1058f1:	c7 44 24 04 63 01 00 	movl   $0x163,0x4(%esp)
  1058f8:	00 
  1058f9:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  105900:	e8 33 b0 ff ff       	call   100938 <debug_panic>
	assert(dva >= VM_USERLO && dva < VM_USERHI);
  105905:	81 7d 14 ff ff ff 3f 	cmpl   $0x3fffffff,0x14(%ebp)
  10590c:	76 09                	jbe    105917 <pmap_copy+0xde>
  10590e:	81 7d 14 ff ff ff ef 	cmpl   $0xefffffff,0x14(%ebp)
  105915:	76 24                	jbe    10593b <pmap_copy+0x102>
  105917:	c7 44 24 0c d4 b2 10 	movl   $0x10b2d4,0xc(%esp)
  10591e:	00 
  10591f:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105926:	00 
  105927:	c7 44 24 04 64 01 00 	movl   $0x164,0x4(%esp)
  10592e:	00 
  10592f:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  105936:	e8 fd af ff ff       	call   100938 <debug_panic>
	assert(size <= VM_USERHI - sva);
  10593b:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  105940:	2b 45 0c             	sub    0xc(%ebp),%eax
  105943:	3b 45 18             	cmp    0x18(%ebp),%eax
  105946:	73 24                	jae    10596c <pmap_copy+0x133>
  105948:	c7 44 24 0c f8 b2 10 	movl   $0x10b2f8,0xc(%esp)
  10594f:	00 
  105950:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105957:	00 
  105958:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
  10595f:	00 
  105960:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  105967:	e8 cc af ff ff       	call   100938 <debug_panic>
	assert(size <= VM_USERHI - dva);
  10596c:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  105971:	2b 45 14             	sub    0x14(%ebp),%eax
  105974:	3b 45 18             	cmp    0x18(%ebp),%eax
  105977:	73 24                	jae    10599d <pmap_copy+0x164>
  105979:	c7 44 24 0c 10 b3 10 	movl   $0x10b310,0xc(%esp)
  105980:	00 
  105981:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105988:	00 
  105989:	c7 44 24 04 66 01 00 	movl   $0x166,0x4(%esp)
  105990:	00 
  105991:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  105998:	e8 9b af ff ff       	call   100938 <debug_panic>

	pte_t* spage;
	pte_t* dpage;
	int page_number = size/PAGESIZE;
  10599d:	8b 45 18             	mov    0x18(%ebp),%eax
  1059a0:	c1 e8 0c             	shr    $0xc,%eax
  1059a3:	89 45 f0             	mov    %eax,-0x10(%ebp)
	int i = 0;
  1059a6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	for(i; i < page_number; i++){
  1059ad:	e9 de 01 00 00       	jmp    105b90 <pmap_copy+0x357>
		if((spage = pmap_walk(spdir, sva, false))){
  1059b2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1059b9:	00 
  1059ba:	8b 45 0c             	mov    0xc(%ebp),%eax
  1059bd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1059c1:	8b 45 08             	mov    0x8(%ebp),%eax
  1059c4:	89 04 24             	mov    %eax,(%esp)
  1059c7:	e8 03 f3 ff ff       	call   104ccf <pmap_walk>
  1059cc:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1059cf:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1059d3:	0f 84 a5 01 00 00    	je     105b7e <pmap_copy+0x345>
			if(!(dpage = pmap_walk(dpdir, dva, true)))
  1059d9:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  1059e0:	00 
  1059e1:	8b 45 14             	mov    0x14(%ebp),%eax
  1059e4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1059e8:	8b 45 10             	mov    0x10(%ebp),%eax
  1059eb:	89 04 24             	mov    %eax,(%esp)
  1059ee:	e8 dc f2 ff ff       	call   104ccf <pmap_walk>
  1059f3:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1059f6:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  1059fa:	75 0a                	jne    105a06 <pmap_copy+0x1cd>
				return false;
  1059fc:	b8 00 00 00 00       	mov    $0x0,%eax
  105a01:	e9 9b 01 00 00       	jmp    105ba1 <pmap_copy+0x368>
			if((*spage) & PTE_W)
  105a06:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105a09:	8b 00                	mov    (%eax),%eax
  105a0b:	83 e0 02             	and    $0x2,%eax
  105a0e:	85 c0                	test   %eax,%eax
  105a10:	74 0f                	je     105a21 <pmap_copy+0x1e8>
				*spage |= SYS_WRITE;
  105a12:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105a15:	8b 00                	mov    (%eax),%eax
  105a17:	89 c2                	mov    %eax,%edx
  105a19:	80 ce 04             	or     $0x4,%dh
  105a1c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105a1f:	89 10                	mov    %edx,(%eax)
			if((*spage) & PTE_P)
  105a21:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105a24:	8b 00                	mov    (%eax),%eax
  105a26:	83 e0 01             	and    $0x1,%eax
  105a29:	85 c0                	test   %eax,%eax
  105a2b:	74 0f                	je     105a3c <pmap_copy+0x203>
				*spage |= SYS_READ;
  105a2d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105a30:	8b 00                	mov    (%eax),%eax
  105a32:	89 c2                	mov    %eax,%edx
  105a34:	80 ce 02             	or     $0x2,%dh
  105a37:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105a3a:	89 10                	mov    %edx,(%eax)
			*spage &= (~PTE_W);
  105a3c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105a3f:	8b 00                	mov    (%eax),%eax
  105a41:	89 c2                	mov    %eax,%edx
  105a43:	83 e2 fd             	and    $0xfffffffd,%edx
  105a46:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105a49:	89 10                	mov    %edx,(%eax)
			*dpage = *spage;
  105a4b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105a4e:	8b 10                	mov    (%eax),%edx
  105a50:	8b 45 e8             	mov    -0x18(%ebp),%eax
  105a53:	89 10                	mov    %edx,(%eax)
			uint32_t phy_add = PGADDR(*spage);
  105a55:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105a58:	8b 00                	mov    (%eax),%eax
  105a5a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105a5f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			pageinfo* pi = mem_phys2pi(phy_add);
  105a62:	a1 50 8f 38 00       	mov    0x388f50,%eax
  105a67:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  105a6a:	c1 ea 0c             	shr    $0xc,%edx
  105a6d:	c1 e2 03             	shl    $0x3,%edx
  105a70:	01 d0                	add    %edx,%eax
  105a72:	89 45 e0             	mov    %eax,-0x20(%ebp)
			if((PGADDR(*spage)) != PTE_ZERO)
  105a75:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105a78:	8b 00                	mov    (%eax),%eax
  105a7a:	89 c2                	mov    %eax,%edx
  105a7c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  105a82:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  105a87:	39 c2                	cmp    %eax,%edx
  105a89:	0f 84 ef 00 00 00    	je     105b7e <pmap_copy+0x345>
  105a8f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105a92:	89 45 dc             	mov    %eax,-0x24(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  105a95:	a1 50 8f 38 00       	mov    0x388f50,%eax
  105a9a:	83 c0 08             	add    $0x8,%eax
  105a9d:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  105aa0:	76 15                	jbe    105ab7 <pmap_copy+0x27e>
  105aa2:	a1 50 8f 38 00       	mov    0x388f50,%eax
  105aa7:	8b 15 44 8f 38 00    	mov    0x388f44,%edx
  105aad:	c1 e2 03             	shl    $0x3,%edx
  105ab0:	01 d0                	add    %edx,%eax
  105ab2:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  105ab5:	72 24                	jb     105adb <pmap_copy+0x2a2>
  105ab7:	c7 44 24 0c 68 b1 10 	movl   $0x10b168,0xc(%esp)
  105abe:	00 
  105abf:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105ac6:	00 
  105ac7:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  105ace:	00 
  105acf:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  105ad6:	e8 5d ae ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  105adb:	a1 50 8f 38 00       	mov    0x388f50,%eax
  105ae0:	ba 00 b0 38 00       	mov    $0x38b000,%edx
  105ae5:	c1 ea 0c             	shr    $0xc,%edx
  105ae8:	c1 e2 03             	shl    $0x3,%edx
  105aeb:	01 d0                	add    %edx,%eax
  105aed:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  105af0:	75 24                	jne    105b16 <pmap_copy+0x2dd>
  105af2:	c7 44 24 0c ac b1 10 	movl   $0x10b1ac,0xc(%esp)
  105af9:	00 
  105afa:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105b01:	00 
  105b02:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  105b09:	00 
  105b0a:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  105b11:	e8 22 ae ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  105b16:	a1 50 8f 38 00       	mov    0x388f50,%eax
  105b1b:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  105b20:	c1 ea 0c             	shr    $0xc,%edx
  105b23:	c1 e2 03             	shl    $0x3,%edx
  105b26:	01 d0                	add    %edx,%eax
  105b28:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  105b2b:	72 3b                	jb     105b68 <pmap_copy+0x32f>
  105b2d:	a1 50 8f 38 00       	mov    0x388f50,%eax
  105b32:	ba 07 c0 38 00       	mov    $0x38c007,%edx
  105b37:	c1 ea 0c             	shr    $0xc,%edx
  105b3a:	c1 e2 03             	shl    $0x3,%edx
  105b3d:	01 d0                	add    %edx,%eax
  105b3f:	39 45 dc             	cmp    %eax,-0x24(%ebp)
  105b42:	77 24                	ja     105b68 <pmap_copy+0x32f>
  105b44:	c7 44 24 0c c8 b1 10 	movl   $0x10b1c8,0xc(%esp)
  105b4b:	00 
  105b4c:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105b53:	00 
  105b54:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  105b5b:	00 
  105b5c:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  105b63:	e8 d0 ad ff ff       	call   100938 <debug_panic>

	lockadd(&pi->refcount, 1);
  105b68:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105b6b:	83 c0 04             	add    $0x4,%eax
  105b6e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105b75:	00 
  105b76:	89 04 24             	mov    %eax,(%esp)
  105b79:	e8 92 ec ff ff       	call   104810 <lockadd>
				mem_incref(pi);
		}
		sva += PAGESIZE;
  105b7e:	81 45 0c 00 10 00 00 	addl   $0x1000,0xc(%ebp)
		dva += PAGESIZE;
  105b85:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)

	pte_t* spage;
	pte_t* dpage;
	int page_number = size/PAGESIZE;
	int i = 0;
	for(i; i < page_number; i++){
  105b8c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  105b90:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105b93:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  105b96:	0f 8c 16 fe ff ff    	jl     1059b2 <pmap_copy+0x179>
		}
		sva += PAGESIZE;
		dva += PAGESIZE;
	}
	//cprintf("in pmapcopy, content in spdir 0xefffff9c: %x, dpdir: %x.\n", (int)*pmap_walk(spdir, 0xefffff9c,false),(int)*pmap_walk(dpdir,0xefffff9c,false));
	return true;
  105b9c:	b8 01 00 00 00       	mov    $0x1,%eax
}
  105ba1:	c9                   	leave  
  105ba2:	c3                   	ret    

00105ba3 <pmap_pagefault>:
// If the fault wasn't due to the kernel's copy on write optimization,
// however, this function just returns so the trap gets blamed on the user.
//
void
pmap_pagefault(trapframe *tf)
{
  105ba3:	55                   	push   %ebp
  105ba4:	89 e5                	mov    %esp,%ebp
  105ba6:	53                   	push   %ebx
  105ba7:	83 ec 44             	sub    $0x44,%esp

static gcc_inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
  105baa:	0f 20 d3             	mov    %cr2,%ebx
  105bad:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	return val;
  105bb0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
	// Read processor's CR2 register to find the faulting linear address.
	uint32_t fva = rcr2();
  105bb3:	89 45 f0             	mov    %eax,-0x10(%ebp)
	proc* p = proc_cur();
  105bb6:	e8 89 ec ff ff       	call   104844 <cpu_cur>
  105bbb:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  105bc1:	89 45 ec             	mov    %eax,-0x14(%ebp)
	pageinfo* origin_pi;	
	//cprintf("in page fault, start. fva: %x err: %x.\n", fva, tf->err);
	//cprintf("pmap_pagefault fva %x, proc: %x.\n", fva, p->id);
	// Fill in the rest of this code.
	if((fva < VM_USERLO)  | (fva >= VM_USERHI)){
  105bc4:	81 7d f0 ff ff ff 3f 	cmpl   $0x3fffffff,-0x10(%ebp)
  105bcb:	0f 96 c2             	setbe  %dl
  105bce:	81 7d f0 ff ff ff ef 	cmpl   $0xefffffff,-0x10(%ebp)
  105bd5:	0f 97 c0             	seta   %al
  105bd8:	09 d0                	or     %edx,%eax
  105bda:	84 c0                	test   %al,%al
  105bdc:	74 2e                	je     105c0c <pmap_pagefault+0x69>
		cprintf("in page fault, start. fva: %x err: %x.\n", fva, tf->err);
  105bde:	8b 45 08             	mov    0x8(%ebp),%eax
  105be1:	8b 40 34             	mov    0x34(%eax),%eax
  105be4:	89 44 24 08          	mov    %eax,0x8(%esp)
  105be8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105beb:	89 44 24 04          	mov    %eax,0x4(%esp)
  105bef:	c7 04 24 28 b3 10 00 	movl   $0x10b328,(%esp)
  105bf6:	e8 d5 3c 00 00       	call   1098d0 <cprintf>
		cprintf("in page fault, out bound.\n");
  105bfb:	c7 04 24 50 b3 10 00 	movl   $0x10b350,(%esp)
  105c02:	e8 c9 3c 00 00       	call   1098d0 <cprintf>
		return;
  105c07:	e9 d4 01 00 00       	jmp    105de0 <pmap_pagefault+0x23d>
	}
	pte_t* fault_pte_point =  pmap_walk(p->pdir, fva, false);
  105c0c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105c0f:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  105c15:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105c1c:	00 
  105c1d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  105c20:	89 54 24 04          	mov    %edx,0x4(%esp)
  105c24:	89 04 24             	mov    %eax,(%esp)
  105c27:	e8 a3 f0 ff ff       	call   104ccf <pmap_walk>
  105c2c:	89 45 e8             	mov    %eax,-0x18(%ebp)
	uint32_t fault_pte_content = *fault_pte_point;
  105c2f:	8b 45 e8             	mov    -0x18(%ebp),%eax
  105c32:	8b 00                	mov    (%eax),%eax
  105c34:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	//cprintf("in pagefault: fault pte content: %x, pde content: %x.\n", fault_pte_content, p->pdir[PDX(fva)]);
	if(!fault_pte_point){
  105c37:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  105c3b:	75 2e                	jne    105c6b <pmap_pagefault+0xc8>
		cprintf("in page fault, start. fva: %x err: %x.\n", fva, tf->err);
  105c3d:	8b 45 08             	mov    0x8(%ebp),%eax
  105c40:	8b 40 34             	mov    0x34(%eax),%eax
  105c43:	89 44 24 08          	mov    %eax,0x8(%esp)
  105c47:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105c4a:	89 44 24 04          	mov    %eax,0x4(%esp)
  105c4e:	c7 04 24 28 b3 10 00 	movl   $0x10b328,(%esp)
  105c55:	e8 76 3c 00 00       	call   1098d0 <cprintf>
		cprintf("in page fault, no pte.\n");
  105c5a:	c7 04 24 6b b3 10 00 	movl   $0x10b36b,(%esp)
  105c61:	e8 6a 3c 00 00       	call   1098d0 <cprintf>
		return;
  105c66:	e9 75 01 00 00       	jmp    105de0 <pmap_pagefault+0x23d>
	}
	uint32_t page_flag = fault_pte_content & SYS_WRITE;
  105c6b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105c6e:	25 00 04 00 00       	and    $0x400,%eax
  105c73:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if(!page_flag){
  105c76:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  105c7a:	75 11                	jne    105c8d <pmap_pagefault+0xea>
		cprintf("in page fault, no right.\n");
  105c7c:	c7 04 24 83 b3 10 00 	movl   $0x10b383,(%esp)
  105c83:	e8 48 3c 00 00       	call   1098d0 <cprintf>
		return;
  105c88:	e9 53 01 00 00       	jmp    105de0 <pmap_pagefault+0x23d>
	}
	if(PGADDR(fault_pte_content) == PTE_ZERO){
  105c8d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105c90:	89 c2                	mov    %eax,%edx
  105c92:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  105c98:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  105c9d:	39 c2                	cmp    %eax,%edx
  105c9f:	75 09                	jne    105caa <pmap_pagefault+0x107>
		origin_pi = NULL;
  105ca1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  105ca8:	eb 19                	jmp    105cc3 <pmap_pagefault+0x120>
	}else{
		origin_pi = mem_phys2pi(PGADDR(fault_pte_content));
  105caa:	a1 50 8f 38 00       	mov    0x388f50,%eax
  105caf:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  105cb2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  105cb8:	c1 ea 0c             	shr    $0xc,%edx
  105cbb:	c1 e2 03             	shl    $0x3,%edx
  105cbe:	01 d0                	add    %edx,%eax
  105cc0:	89 45 f4             	mov    %eax,-0xc(%ebp)
				pmap_inval(p->pdir, PGADDR(fva), PAGESIZE);
				trap_return(tf);
			}
		}
	}*/
	if(page_flag & SYS_WRITE){		
  105cc3:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105cc6:	25 00 04 00 00       	and    $0x400,%eax
  105ccb:	85 c0                	test   %eax,%eax
  105ccd:	0f 84 0c 01 00 00    	je     105ddf <pmap_pagefault+0x23c>
		if(origin_pi->refcount > 1 || (!origin_pi)){
  105cd3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105cd6:	8b 40 04             	mov    0x4(%eax),%eax
  105cd9:	83 f8 01             	cmp    $0x1,%eax
  105cdc:	7f 06                	jg     105ce4 <pmap_pagefault+0x141>
  105cde:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  105ce2:	75 61                	jne    105d45 <pmap_pagefault+0x1a2>
			pageinfo* new_page = mem_alloc();
  105ce4:	e8 e2 b2 ff ff       	call   100fcb <mem_alloc>
  105ce9:	89 45 dc             	mov    %eax,-0x24(%ebp)
			memmove((void*)mem_pi2phys(new_page),(void*)PGADDR(fault_pte_content), PAGESIZE);
  105cec:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105cef:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105cf4:	89 c2                	mov    %eax,%edx
  105cf6:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  105cf9:	a1 50 8f 38 00       	mov    0x388f50,%eax
  105cfe:	89 cb                	mov    %ecx,%ebx
  105d00:	29 c3                	sub    %eax,%ebx
  105d02:	89 d8                	mov    %ebx,%eax
  105d04:	c1 f8 03             	sar    $0x3,%eax
  105d07:	c1 e0 0c             	shl    $0xc,%eax
  105d0a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105d11:	00 
  105d12:	89 54 24 04          	mov    %edx,0x4(%esp)
  105d16:	89 04 24             	mov    %eax,(%esp)
  105d19:	e8 91 3f 00 00       	call   109caf <memmove>
			pmap_insert(p->pdir, new_page, fva, SYS_RW | PTE_W | PTE_P | PTE_U);
  105d1e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105d21:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  105d27:	c7 44 24 0c 07 06 00 	movl   $0x607,0xc(%esp)
  105d2e:	00 
  105d2f:	8b 55 f0             	mov    -0x10(%ebp),%edx
  105d32:	89 54 24 08          	mov    %edx,0x8(%esp)
  105d36:	8b 55 dc             	mov    -0x24(%ebp),%edx
  105d39:	89 54 24 04          	mov    %edx,0x4(%esp)
  105d3d:	89 04 24             	mov    %eax,(%esp)
  105d40:	e8 cb f1 ff ff       	call   104f10 <pmap_insert>
			//cprintf("in page fault, new page: %x.", mem_pi2phys(new_page));
			//cprintf("after insert, fault pte content: %x, pde content: %x, what in add: %x.\n\n", 
			//	*pmap_walk(p->pdir,fva,false), p->pdir[PDX(fva)], *((int*)(*pmap_walk(p->pdir,fva,false))));
		}
		if(origin_pi->refcount == 1){
  105d45:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105d48:	8b 40 04             	mov    0x4(%eax),%eax
  105d4b:	83 f8 01             	cmp    $0x1,%eax
  105d4e:	75 5c                	jne    105dac <pmap_pagefault+0x209>
			pte_t* pte = pmap_walk(p->pdir, fva, false);
  105d50:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105d53:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  105d59:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105d60:	00 
  105d61:	8b 55 f0             	mov    -0x10(%ebp),%edx
  105d64:	89 54 24 04          	mov    %edx,0x4(%esp)
  105d68:	89 04 24             	mov    %eax,(%esp)
  105d6b:	e8 5f ef ff ff       	call   104ccf <pmap_walk>
  105d70:	89 45 d8             	mov    %eax,-0x28(%ebp)
			assert(pte != NULL);
  105d73:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  105d77:	75 24                	jne    105d9d <pmap_pagefault+0x1fa>
  105d79:	c7 44 24 0c 9d b3 10 	movl   $0x10b39d,0xc(%esp)
  105d80:	00 
  105d81:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105d88:	00 
  105d89:	c7 44 24 04 c6 01 00 	movl   $0x1c6,0x4(%esp)
  105d90:	00 
  105d91:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  105d98:	e8 9b ab ff ff       	call   100938 <debug_panic>
			*pte |= PTE_W;
  105d9d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105da0:	8b 00                	mov    (%eax),%eax
  105da2:	89 c2                	mov    %eax,%edx
  105da4:	83 ca 02             	or     $0x2,%edx
  105da7:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105daa:	89 10                	mov    %edx,(%eax)
		}
		//pte_t* after_fault_pte_point =  pmap_walk(p->pdir, fva, false);
		//uint32_t after_fault_pte_content = *fault_pte_point;
		//cprintf("after write, fault pte content: %x, pde content: %x.\n\n\n", after_fault_pte_content, p->pdir[PDX(fva)]);
		pmap_inval(p->pdir, PGADDR(fva), PAGESIZE);
  105dac:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105daf:	89 c2                	mov    %eax,%edx
  105db1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  105db7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  105dba:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  105dc0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105dc7:	00 
  105dc8:	89 54 24 04          	mov    %edx,0x4(%esp)
  105dcc:	89 04 24             	mov    %eax,(%esp)
  105dcf:	e8 0c fa ff ff       	call   1057e0 <pmap_inval>
		trap_return(tf);
  105dd4:	8b 45 08             	mov    0x8(%ebp),%eax
  105dd7:	89 04 24             	mov    %eax,(%esp)
  105dda:	e8 21 a3 00 00       	call   110100 <trap_return>
	}
	return;
  105ddf:	90                   	nop
}
  105de0:	83 c4 44             	add    $0x44,%esp
  105de3:	5b                   	pop    %ebx
  105de4:	5d                   	pop    %ebp
  105de5:	c3                   	ret    

00105de6 <pmap_mergepage>:
// print a warning to the console and remove the page from the destination.
// If the destination page is read-shared, be sure to copy it before modifying!
//
void
pmap_mergepage(pte_t *rpte, pte_t *spte, pte_t *dpte, uint32_t dva)
{
  105de6:	55                   	push   %ebp
  105de7:	89 e5                	mov    %esp,%ebp
  105de9:	83 ec 38             	sub    $0x38,%esp
	uint32_t i = 0;
  105dec:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	if(!rpte || *rpte == PTE_ZERO){
  105df3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  105df7:	74 67                	je     105e60 <pmap_mergepage+0x7a>
  105df9:	8b 45 08             	mov    0x8(%ebp),%eax
  105dfc:	8b 10                	mov    (%eax),%edx
  105dfe:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  105e03:	39 c2                	cmp    %eax,%edx
  105e05:	0f 85 d5 00 00 00    	jne    105ee0 <pmap_mergepage+0xfa>
		while( i < PAGESIZE ){
  105e0b:	eb 53                	jmp    105e60 <pmap_mergepage+0x7a>
			uint32_t cmp_sadd = PGADDR(*spte);
  105e0d:	8b 45 0c             	mov    0xc(%ebp),%eax
  105e10:	8b 00                	mov    (%eax),%eax
  105e12:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105e17:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			uint32_t cmp_dadd = PGADDR(*dpte);
  105e1a:	8b 45 10             	mov    0x10(%ebp),%eax
  105e1d:	8b 00                	mov    (%eax),%eax
  105e1f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105e24:	89 45 e0             	mov    %eax,-0x20(%ebp)
			cmp_dadd += i * 8;
  105e27:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105e2a:	c1 e0 03             	shl    $0x3,%eax
  105e2d:	01 45 e0             	add    %eax,-0x20(%ebp)
			cmp_sadd += i*8;
  105e30:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105e33:	c1 e0 03             	shl    $0x3,%eax
  105e36:	01 45 e4             	add    %eax,-0x1c(%ebp)
			if(*(uint32_t*)cmp_sadd)
  105e39:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  105e3c:	8b 00                	mov    (%eax),%eax
  105e3e:	85 c0                	test   %eax,%eax
  105e40:	74 1a                	je     105e5c <pmap_mergepage+0x76>
				memmove((void*)cmp_dadd, (void*)cmp_sadd, 4);
  105e42:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  105e45:	8b 45 e0             	mov    -0x20(%ebp),%eax
  105e48:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  105e4f:	00 
  105e50:	89 54 24 04          	mov    %edx,0x4(%esp)
  105e54:	89 04 24             	mov    %eax,(%esp)
  105e57:	e8 53 3e 00 00       	call   109caf <memmove>
			i += 4;
  105e5c:	83 45 f4 04          	addl   $0x4,-0xc(%ebp)
void
pmap_mergepage(pte_t *rpte, pte_t *spte, pte_t *dpte, uint32_t dva)
{
	uint32_t i = 0;
	if(!rpte || *rpte == PTE_ZERO){
		while( i < PAGESIZE ){
  105e60:	81 7d f4 ff 0f 00 00 	cmpl   $0xfff,-0xc(%ebp)
  105e67:	76 a4                	jbe    105e0d <pmap_mergepage+0x27>
//
void
pmap_mergepage(pte_t *rpte, pte_t *spte, pte_t *dpte, uint32_t dva)
{
	uint32_t i = 0;
	if(!rpte || *rpte == PTE_ZERO){
  105e69:	eb 7e                	jmp    105ee9 <pmap_mergepage+0x103>
				memmove((void*)cmp_dadd, (void*)cmp_sadd, 4);
			i += 4;
		}
	}else{
		while(i < PAGESIZE){
			uint32_t cmp_radd = PGADDR(*rpte);
  105e6b:	8b 45 08             	mov    0x8(%ebp),%eax
  105e6e:	8b 00                	mov    (%eax),%eax
  105e70:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105e75:	89 45 f0             	mov    %eax,-0x10(%ebp)
			uint32_t cmp_sadd = PGADDR(*spte);
  105e78:	8b 45 0c             	mov    0xc(%ebp),%eax
  105e7b:	8b 00                	mov    (%eax),%eax
  105e7d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105e82:	89 45 ec             	mov    %eax,-0x14(%ebp)
			uint32_t cmp_dadd = PGADDR(*dpte);
  105e85:	8b 45 10             	mov    0x10(%ebp),%eax
  105e88:	8b 00                	mov    (%eax),%eax
  105e8a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105e8f:	89 45 e8             	mov    %eax,-0x18(%ebp)
			cmp_radd += i;
  105e92:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105e95:	01 45 f0             	add    %eax,-0x10(%ebp)
			cmp_dadd += i;
  105e98:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105e9b:	01 45 e8             	add    %eax,-0x18(%ebp)
			cmp_sadd += i;
  105e9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105ea1:	01 45 ec             	add    %eax,-0x14(%ebp)
			if(memcmp((void*)cmp_radd,(void*)cmp_sadd, 4))
  105ea4:	8b 55 ec             	mov    -0x14(%ebp),%edx
  105ea7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  105eaa:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  105eb1:	00 
  105eb2:	89 54 24 04          	mov    %edx,0x4(%esp)
  105eb6:	89 04 24             	mov    %eax,(%esp)
  105eb9:	e8 ec 3e 00 00       	call   109daa <memcmp>
  105ebe:	85 c0                	test   %eax,%eax
  105ec0:	74 1a                	je     105edc <pmap_mergepage+0xf6>
				memmove((void*)cmp_dadd, (void*)cmp_sadd, 4);
  105ec2:	8b 55 ec             	mov    -0x14(%ebp),%edx
  105ec5:	8b 45 e8             	mov    -0x18(%ebp),%eax
  105ec8:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  105ecf:	00 
  105ed0:	89 54 24 04          	mov    %edx,0x4(%esp)
  105ed4:	89 04 24             	mov    %eax,(%esp)
  105ed7:	e8 d3 3d 00 00       	call   109caf <memmove>
			i += 4;
  105edc:	83 45 f4 04          	addl   $0x4,-0xc(%ebp)
			if(*(uint32_t*)cmp_sadd)
				memmove((void*)cmp_dadd, (void*)cmp_sadd, 4);
			i += 4;
		}
	}else{
		while(i < PAGESIZE){
  105ee0:	81 7d f4 ff 0f 00 00 	cmpl   $0xfff,-0xc(%ebp)
  105ee7:	76 82                	jbe    105e6b <pmap_mergepage+0x85>
				memmove((void*)cmp_dadd, (void*)cmp_sadd, 4);
			i += 4;
		}
	}
	//panic("pmap_mergepage() not implemented");
}
  105ee9:	c9                   	leave  
  105eea:	c3                   	ret    

00105eeb <pmap_merge>:
// and a source address space spdir into a destination address space dpdir.
//
int
pmap_merge(pde_t *rpdir, pde_t *spdir, uint32_t sva,
		pde_t *dpdir, uint32_t dva, size_t size)
{
  105eeb:	55                   	push   %ebp
  105eec:	89 e5                	mov    %esp,%ebp
  105eee:	53                   	push   %ebx
  105eef:	83 ec 44             	sub    $0x44,%esp
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
  105ef2:	8b 45 10             	mov    0x10(%ebp),%eax
  105ef5:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  105efa:	85 c0                	test   %eax,%eax
  105efc:	74 24                	je     105f22 <pmap_merge+0x37>
  105efe:	c7 44 24 0c 7e b2 10 	movl   $0x10b27e,0xc(%esp)
  105f05:	00 
  105f06:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105f0d:	00 
  105f0e:	c7 44 24 04 fe 01 00 	movl   $0x1fe,0x4(%esp)
  105f15:	00 
  105f16:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  105f1d:	e8 16 aa ff ff       	call   100938 <debug_panic>
	assert(PTOFF(dva) == 0);
  105f22:	8b 45 18             	mov    0x18(%ebp),%eax
  105f25:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  105f2a:	85 c0                	test   %eax,%eax
  105f2c:	74 24                	je     105f52 <pmap_merge+0x67>
  105f2e:	c7 44 24 0c 8e b2 10 	movl   $0x10b28e,0xc(%esp)
  105f35:	00 
  105f36:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105f3d:	00 
  105f3e:	c7 44 24 04 ff 01 00 	movl   $0x1ff,0x4(%esp)
  105f45:	00 
  105f46:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  105f4d:	e8 e6 a9 ff ff       	call   100938 <debug_panic>
	assert(PTOFF(size) == 0);
  105f52:	8b 45 1c             	mov    0x1c(%ebp),%eax
  105f55:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  105f5a:	85 c0                	test   %eax,%eax
  105f5c:	74 24                	je     105f82 <pmap_merge+0x97>
  105f5e:	c7 44 24 0c 9e b2 10 	movl   $0x10b29e,0xc(%esp)
  105f65:	00 
  105f66:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105f6d:	00 
  105f6e:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
  105f75:	00 
  105f76:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  105f7d:	e8 b6 a9 ff ff       	call   100938 <debug_panic>
	assert(sva >= VM_USERLO && sva < VM_USERHI);
  105f82:	81 7d 10 ff ff ff 3f 	cmpl   $0x3fffffff,0x10(%ebp)
  105f89:	76 09                	jbe    105f94 <pmap_merge+0xa9>
  105f8b:	81 7d 10 ff ff ff ef 	cmpl   $0xefffffff,0x10(%ebp)
  105f92:	76 24                	jbe    105fb8 <pmap_merge+0xcd>
  105f94:	c7 44 24 0c b0 b2 10 	movl   $0x10b2b0,0xc(%esp)
  105f9b:	00 
  105f9c:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105fa3:	00 
  105fa4:	c7 44 24 04 01 02 00 	movl   $0x201,0x4(%esp)
  105fab:	00 
  105fac:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  105fb3:	e8 80 a9 ff ff       	call   100938 <debug_panic>
	assert(dva >= VM_USERLO && dva < VM_USERHI);
  105fb8:	81 7d 18 ff ff ff 3f 	cmpl   $0x3fffffff,0x18(%ebp)
  105fbf:	76 09                	jbe    105fca <pmap_merge+0xdf>
  105fc1:	81 7d 18 ff ff ff ef 	cmpl   $0xefffffff,0x18(%ebp)
  105fc8:	76 24                	jbe    105fee <pmap_merge+0x103>
  105fca:	c7 44 24 0c d4 b2 10 	movl   $0x10b2d4,0xc(%esp)
  105fd1:	00 
  105fd2:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  105fd9:	00 
  105fda:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
  105fe1:	00 
  105fe2:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  105fe9:	e8 4a a9 ff ff       	call   100938 <debug_panic>
	assert(size <= VM_USERHI - sva);
  105fee:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  105ff3:	2b 45 10             	sub    0x10(%ebp),%eax
  105ff6:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  105ff9:	73 24                	jae    10601f <pmap_merge+0x134>
  105ffb:	c7 44 24 0c f8 b2 10 	movl   $0x10b2f8,0xc(%esp)
  106002:	00 
  106003:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10600a:	00 
  10600b:	c7 44 24 04 03 02 00 	movl   $0x203,0x4(%esp)
  106012:	00 
  106013:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10601a:	e8 19 a9 ff ff       	call   100938 <debug_panic>
	assert(size <= VM_USERHI - dva);
  10601f:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  106024:	2b 45 18             	sub    0x18(%ebp),%eax
  106027:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  10602a:	73 24                	jae    106050 <pmap_merge+0x165>
  10602c:	c7 44 24 0c 10 b3 10 	movl   $0x10b310,0xc(%esp)
  106033:	00 
  106034:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10603b:	00 
  10603c:	c7 44 24 04 04 02 00 	movl   $0x204,0x4(%esp)
  106043:	00 
  106044:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10604b:	e8 e8 a8 ff ff       	call   100938 <debug_panic>

	uint32_t tmp_va = sva;
  106050:	8b 45 10             	mov    0x10(%ebp),%eax
  106053:	89 45 f4             	mov    %eax,-0xc(%ebp)
	while(tmp_va < sva + size){
  106056:	e9 db 02 00 00       	jmp    106336 <pmap_merge+0x44b>
		uint32_t rpde = rpdir[PDX(tmp_va)];
  10605b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10605e:	c1 e8 16             	shr    $0x16,%eax
  106061:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  106068:	8b 45 08             	mov    0x8(%ebp),%eax
  10606b:	01 d0                	add    %edx,%eax
  10606d:	8b 00                	mov    (%eax),%eax
  10606f:	89 45 ec             	mov    %eax,-0x14(%ebp)
		uint32_t spde = spdir[PDX(tmp_va)];
  106072:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106075:	c1 e8 16             	shr    $0x16,%eax
  106078:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  10607f:	8b 45 0c             	mov    0xc(%ebp),%eax
  106082:	01 d0                	add    %edx,%eax
  106084:	8b 00                	mov    (%eax),%eax
  106086:	89 45 e8             	mov    %eax,-0x18(%ebp)
		if(PGADDR(spde) == PTE_ZERO){
  106089:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10608c:	89 c2                	mov    %eax,%edx
  10608e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  106094:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  106099:	39 c2                	cmp    %eax,%edx
  10609b:	75 0c                	jne    1060a9 <pmap_merge+0x1be>
			tmp_va += PTSIZE;
  10609d:	81 45 f4 00 00 40 00 	addl   $0x400000,-0xc(%ebp)
			continue;
  1060a4:	e9 8d 02 00 00       	jmp    106336 <pmap_merge+0x44b>
		}
		pte_t* rpte = pmap_walk(rpdir, tmp_va, false);
  1060a9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1060b0:	00 
  1060b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1060b4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1060b8:	8b 45 08             	mov    0x8(%ebp),%eax
  1060bb:	89 04 24             	mov    %eax,(%esp)
  1060be:	e8 0c ec ff ff       	call   104ccf <pmap_walk>
  1060c3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		//cprintf("rpte add: %x     ", rpte);
		pte_t* spte = pmap_walk(spdir, tmp_va, false);
  1060c6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  1060cd:	00 
  1060ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1060d1:	89 44 24 04          	mov    %eax,0x4(%esp)
  1060d5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1060d8:	89 04 24             	mov    %eax,(%esp)
  1060db:	e8 ef eb ff ff       	call   104ccf <pmap_walk>
  1060e0:	89 45 e0             	mov    %eax,-0x20(%ebp)
		//cprintf("spte add: %x     ", spte);
		if(*rpte == *spte){
  1060e3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1060e6:	8b 10                	mov    (%eax),%edx
  1060e8:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1060eb:	8b 00                	mov    (%eax),%eax
  1060ed:	39 c2                	cmp    %eax,%edx
  1060ef:	75 0c                	jne    1060fd <pmap_merge+0x212>
			tmp_va += PAGESIZE;
  1060f1:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
			continue;
  1060f8:	e9 39 02 00 00       	jmp    106336 <pmap_merge+0x44b>
		}
		if(PGADDR(*spte) == PTE_ZERO){
  1060fd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  106100:	8b 00                	mov    (%eax),%eax
  106102:	89 c2                	mov    %eax,%edx
  106104:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  10610a:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  10610f:	39 c2                	cmp    %eax,%edx
  106111:	75 0c                	jne    10611f <pmap_merge+0x234>
			tmp_va += PAGESIZE;
  106113:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
			continue;
  10611a:	e9 17 02 00 00       	jmp    106336 <pmap_merge+0x44b>
		}
		pte_t* dpte = pmap_walk(dpdir, tmp_va, true);
  10611f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  106126:	00 
  106127:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10612a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10612e:	8b 45 14             	mov    0x14(%ebp),%eax
  106131:	89 04 24             	mov    %eax,(%esp)
  106134:	e8 96 eb ff ff       	call   104ccf <pmap_walk>
  106139:	89 45 dc             	mov    %eax,-0x24(%ebp)
		if(!dpte)
  10613c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  106140:	75 1c                	jne    10615e <pmap_merge+0x273>
			panic("in pmap_merge, has no pte.\n");
  106142:	c7 44 24 08 a9 b3 10 	movl   $0x10b3a9,0x8(%esp)
  106149:	00 
  10614a:	c7 44 24 04 1c 02 00 	movl   $0x21c,0x4(%esp)
  106151:	00 
  106152:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106159:	e8 da a7 ff ff       	call   100938 <debug_panic>
		if(PGADDR(*dpte) == PGADDR(*rpte)){
  10615e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  106161:	8b 10                	mov    (%eax),%edx
  106163:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  106166:	8b 00                	mov    (%eax),%eax
  106168:	31 d0                	xor    %edx,%eax
  10616a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10616f:	85 c0                	test   %eax,%eax
  106171:	0f 85 98 01 00 00    	jne    10630f <pmap_merge+0x424>
			uint32_t perm = 0;
  106177:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
			pageinfo* dpage = mem_alloc();
  10617e:	e8 48 ae ff ff       	call   100fcb <mem_alloc>
  106183:	89 45 d8             	mov    %eax,-0x28(%ebp)
			if(!dpage)
  106186:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  10618a:	75 1c                	jne    1061a8 <pmap_merge+0x2bd>
				panic("in pmap_merge, has no page.\n");
  10618c:	c7 44 24 08 c5 b3 10 	movl   $0x10b3c5,0x8(%esp)
  106193:	00 
  106194:	c7 44 24 04 21 02 00 	movl   $0x221,0x4(%esp)
  10619b:	00 
  10619c:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1061a3:	e8 90 a7 ff ff       	call   100938 <debug_panic>
  1061a8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1061ab:	89 45 d4             	mov    %eax,-0x2c(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1061ae:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1061b3:	83 c0 08             	add    $0x8,%eax
  1061b6:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
  1061b9:	76 15                	jbe    1061d0 <pmap_merge+0x2e5>
  1061bb:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1061c0:	8b 15 44 8f 38 00    	mov    0x388f44,%edx
  1061c6:	c1 e2 03             	shl    $0x3,%edx
  1061c9:	01 d0                	add    %edx,%eax
  1061cb:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
  1061ce:	72 24                	jb     1061f4 <pmap_merge+0x309>
  1061d0:	c7 44 24 0c 68 b1 10 	movl   $0x10b168,0xc(%esp)
  1061d7:	00 
  1061d8:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1061df:	00 
  1061e0:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  1061e7:	00 
  1061e8:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  1061ef:	e8 44 a7 ff ff       	call   100938 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1061f4:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1061f9:	ba 00 b0 38 00       	mov    $0x38b000,%edx
  1061fe:	c1 ea 0c             	shr    $0xc,%edx
  106201:	c1 e2 03             	shl    $0x3,%edx
  106204:	01 d0                	add    %edx,%eax
  106206:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
  106209:	75 24                	jne    10622f <pmap_merge+0x344>
  10620b:	c7 44 24 0c ac b1 10 	movl   $0x10b1ac,0xc(%esp)
  106212:	00 
  106213:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10621a:	00 
  10621b:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  106222:	00 
  106223:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  10622a:	e8 09 a7 ff ff       	call   100938 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  10622f:	a1 50 8f 38 00       	mov    0x388f50,%eax
  106234:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  106239:	c1 ea 0c             	shr    $0xc,%edx
  10623c:	c1 e2 03             	shl    $0x3,%edx
  10623f:	01 d0                	add    %edx,%eax
  106241:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
  106244:	72 3b                	jb     106281 <pmap_merge+0x396>
  106246:	a1 50 8f 38 00       	mov    0x388f50,%eax
  10624b:	ba 07 c0 38 00       	mov    $0x38c007,%edx
  106250:	c1 ea 0c             	shr    $0xc,%edx
  106253:	c1 e2 03             	shl    $0x3,%edx
  106256:	01 d0                	add    %edx,%eax
  106258:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
  10625b:	77 24                	ja     106281 <pmap_merge+0x396>
  10625d:	c7 44 24 0c c8 b1 10 	movl   $0x10b1c8,0xc(%esp)
  106264:	00 
  106265:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10626c:	00 
  10626d:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  106274:	00 
  106275:	c7 04 24 9f b1 10 00 	movl   $0x10b19f,(%esp)
  10627c:	e8 b7 a6 ff ff       	call   100938 <debug_panic>

	lockadd(&pi->refcount, 1);
  106281:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  106284:	83 c0 04             	add    $0x4,%eax
  106287:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10628e:	00 
  10628f:	89 04 24             	mov    %eax,(%esp)
  106292:	e8 79 e5 ff ff       	call   104810 <lockadd>
			mem_incref(dpage);
			mem_pi2phys(dpage);
			memmove((void*)mem_pi2phys(dpage), (void*)PGADDR(*dpte), PAGESIZE);
  106297:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10629a:	8b 00                	mov    (%eax),%eax
  10629c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1062a1:	89 c2                	mov    %eax,%edx
  1062a3:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  1062a6:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1062ab:	89 cb                	mov    %ecx,%ebx
  1062ad:	29 c3                	sub    %eax,%ebx
  1062af:	89 d8                	mov    %ebx,%eax
  1062b1:	c1 f8 03             	sar    $0x3,%eax
  1062b4:	c1 e0 0c             	shl    $0xc,%eax
  1062b7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1062be:	00 
  1062bf:	89 54 24 04          	mov    %edx,0x4(%esp)
  1062c3:	89 04 24             	mov    %eax,(%esp)
  1062c6:	e8 e4 39 00 00       	call   109caf <memmove>
			if((*dpte & SYS_READ))
  1062cb:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1062ce:	8b 00                	mov    (%eax),%eax
  1062d0:	25 00 02 00 00       	and    $0x200,%eax
  1062d5:	85 c0                	test   %eax,%eax
  1062d7:	74 04                	je     1062dd <pmap_merge+0x3f2>
				perm = perm | PTE_P | PTE_U;
  1062d9:	83 4d f0 05          	orl    $0x5,-0x10(%ebp)
			if((*dpte & SYS_WRITE))
  1062dd:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1062e0:	8b 00                	mov    (%eax),%eax
  1062e2:	25 00 04 00 00       	and    $0x400,%eax
  1062e7:	85 c0                	test   %eax,%eax
  1062e9:	74 04                	je     1062ef <pmap_merge+0x404>
				perm = perm | PTE_W;
  1062eb:	83 4d f0 02          	orl    $0x2,-0x10(%ebp)
			pmap_insert(dpdir, dpage, tmp_va, perm);
  1062ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1062f2:	89 44 24 0c          	mov    %eax,0xc(%esp)
  1062f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1062f9:	89 44 24 08          	mov    %eax,0x8(%esp)
  1062fd:	8b 45 d8             	mov    -0x28(%ebp),%eax
  106300:	89 44 24 04          	mov    %eax,0x4(%esp)
  106304:	8b 45 14             	mov    0x14(%ebp),%eax
  106307:	89 04 24             	mov    %eax,(%esp)
  10630a:	e8 01 ec ff ff       	call   104f10 <pmap_insert>
		}
		pmap_mergepage(rpte, spte, dpte, dva);
  10630f:	8b 45 18             	mov    0x18(%ebp),%eax
  106312:	89 44 24 0c          	mov    %eax,0xc(%esp)
  106316:	8b 45 dc             	mov    -0x24(%ebp),%eax
  106319:	89 44 24 08          	mov    %eax,0x8(%esp)
  10631d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  106320:	89 44 24 04          	mov    %eax,0x4(%esp)
  106324:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  106327:	89 04 24             	mov    %eax,(%esp)
  10632a:	e8 b7 fa ff ff       	call   105de6 <pmap_mergepage>
		tmp_va += PAGESIZE;
  10632f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
	assert(dva >= VM_USERLO && dva < VM_USERHI);
	assert(size <= VM_USERHI - sva);
	assert(size <= VM_USERHI - dva);

	uint32_t tmp_va = sva;
	while(tmp_va < sva + size){
  106336:	8b 45 1c             	mov    0x1c(%ebp),%eax
  106339:	8b 55 10             	mov    0x10(%ebp),%edx
  10633c:	01 d0                	add    %edx,%eax
  10633e:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  106341:	0f 87 14 fd ff ff    	ja     10605b <pmap_merge+0x170>
			pmap_insert(dpdir, dpage, tmp_va, perm);
		}
		pmap_mergepage(rpte, spte, dpte, dva);
		tmp_va += PAGESIZE;
	}
	return 1;
  106347:	b8 01 00 00 00       	mov    $0x1,%eax
	//panic("pmap_merge() not implemented");
}
  10634c:	83 c4 44             	add    $0x44,%esp
  10634f:	5b                   	pop    %ebx
  106350:	5d                   	pop    %ebp
  106351:	c3                   	ret    

00106352 <pmap_setperm>:
// If the user gives SYS_WRITE permission to a PTE_ZERO mapping,
// the page fault handler copies the zero page when the first write occurs.
//
int
pmap_setperm(pde_t *pdir, uint32_t va, uint32_t size, int perm)
{
  106352:	55                   	push   %ebp
  106353:	89 e5                	mov    %esp,%ebp
  106355:	83 ec 28             	sub    $0x28,%esp
	assert(PGOFF(va) == 0);
  106358:	8b 45 0c             	mov    0xc(%ebp),%eax
  10635b:	25 ff 0f 00 00       	and    $0xfff,%eax
  106360:	85 c0                	test   %eax,%eax
  106362:	74 24                	je     106388 <pmap_setperm+0x36>
  106364:	c7 44 24 0c e2 b3 10 	movl   $0x10b3e2,0xc(%esp)
  10636b:	00 
  10636c:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106373:	00 
  106374:	c7 44 24 04 3d 02 00 	movl   $0x23d,0x4(%esp)
  10637b:	00 
  10637c:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106383:	e8 b0 a5 ff ff       	call   100938 <debug_panic>
	assert(PGOFF(size) == 0);
  106388:	8b 45 10             	mov    0x10(%ebp),%eax
  10638b:	25 ff 0f 00 00       	and    $0xfff,%eax
  106390:	85 c0                	test   %eax,%eax
  106392:	74 24                	je     1063b8 <pmap_setperm+0x66>
  106394:	c7 44 24 0c 3a b2 10 	movl   $0x10b23a,0xc(%esp)
  10639b:	00 
  10639c:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1063a3:	00 
  1063a4:	c7 44 24 04 3e 02 00 	movl   $0x23e,0x4(%esp)
  1063ab:	00 
  1063ac:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1063b3:	e8 80 a5 ff ff       	call   100938 <debug_panic>
	assert(va >= VM_USERLO && va < VM_USERHI);
  1063b8:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  1063bf:	76 09                	jbe    1063ca <pmap_setperm+0x78>
  1063c1:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  1063c8:	76 24                	jbe    1063ee <pmap_setperm+0x9c>
  1063ca:	c7 44 24 0c 0c b2 10 	movl   $0x10b20c,0xc(%esp)
  1063d1:	00 
  1063d2:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1063d9:	00 
  1063da:	c7 44 24 04 3f 02 00 	movl   $0x23f,0x4(%esp)
  1063e1:	00 
  1063e2:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1063e9:	e8 4a a5 ff ff       	call   100938 <debug_panic>
	assert(size <= VM_USERHI - va);
  1063ee:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  1063f3:	2b 45 0c             	sub    0xc(%ebp),%eax
  1063f6:	3b 45 10             	cmp    0x10(%ebp),%eax
  1063f9:	73 24                	jae    10641f <pmap_setperm+0xcd>
  1063fb:	c7 44 24 0c 4b b2 10 	movl   $0x10b24b,0xc(%esp)
  106402:	00 
  106403:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10640a:	00 
  10640b:	c7 44 24 04 40 02 00 	movl   $0x240,0x4(%esp)
  106412:	00 
  106413:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10641a:	e8 19 a5 ff ff       	call   100938 <debug_panic>
	assert((perm & ~(SYS_RW)) == 0);
  10641f:	8b 45 14             	mov    0x14(%ebp),%eax
  106422:	80 e4 f9             	and    $0xf9,%ah
  106425:	85 c0                	test   %eax,%eax
  106427:	74 24                	je     10644d <pmap_setperm+0xfb>
  106429:	c7 44 24 0c f1 b3 10 	movl   $0x10b3f1,0xc(%esp)
  106430:	00 
  106431:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106438:	00 
  106439:	c7 44 24 04 41 02 00 	movl   $0x241,0x4(%esp)
  106440:	00 
  106441:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106448:	e8 eb a4 ff ff       	call   100938 <debug_panic>

	uint32_t page_accout = size/PAGESIZE;
  10644d:	8b 45 10             	mov    0x10(%ebp),%eax
  106450:	c1 e8 0c             	shr    $0xc,%eax
  106453:	89 45 ec             	mov    %eax,-0x14(%ebp)
	int i = 0;
  106456:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	pte_t* tmp_pte;
	uint32_t tmp_va = va;
  10645d:	8b 45 0c             	mov    0xc(%ebp),%eax
  106460:	89 45 f0             	mov    %eax,-0x10(%ebp)
	for(i; i < page_accout; i++){
  106463:	e9 ed 00 00 00       	jmp    106555 <pmap_setperm+0x203>
		if(!(tmp_pte = pmap_walk(pdir, tmp_va, true)))
  106468:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  10646f:	00 
  106470:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106473:	89 44 24 04          	mov    %eax,0x4(%esp)
  106477:	8b 45 08             	mov    0x8(%ebp),%eax
  10647a:	89 04 24             	mov    %eax,(%esp)
  10647d:	e8 4d e8 ff ff       	call   104ccf <pmap_walk>
  106482:	89 45 e8             	mov    %eax,-0x18(%ebp)
  106485:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  106489:	75 0a                	jne    106495 <pmap_setperm+0x143>
			return 0;
  10648b:	b8 00 00 00 00       	mov    $0x0,%eax
  106490:	e9 d1 00 00 00       	jmp    106566 <pmap_setperm+0x214>
		switch(perm & SYS_RW){
  106495:	8b 45 14             	mov    0x14(%ebp),%eax
  106498:	25 00 06 00 00       	and    $0x600,%eax
  10649d:	3d 00 02 00 00       	cmp    $0x200,%eax
  1064a2:	74 3e                	je     1064e2 <pmap_setperm+0x190>
  1064a4:	3d 00 06 00 00       	cmp    $0x600,%eax
  1064a9:	74 5d                	je     106508 <pmap_setperm+0x1b6>
  1064ab:	85 c0                	test   %eax,%eax
  1064ad:	75 7f                	jne    10652e <pmap_setperm+0x1dc>
		case 0:
			if(!((*tmp_pte) & SYS_RW))
  1064af:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1064b2:	8b 00                	mov    (%eax),%eax
  1064b4:	25 00 06 00 00       	and    $0x600,%eax
  1064b9:	85 c0                	test   %eax,%eax
  1064bb:	75 11                	jne    1064ce <pmap_setperm+0x17c>
				*tmp_pte = *tmp_pte | PTE_U | PTE_P;
  1064bd:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1064c0:	8b 00                	mov    (%eax),%eax
  1064c2:	89 c2                	mov    %eax,%edx
  1064c4:	83 ca 05             	or     $0x5,%edx
  1064c7:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1064ca:	89 10                	mov    %edx,(%eax)
			else{
				*tmp_pte &= ~(SYS_RW | PTE_P | PTE_W);
			}
			break;
  1064cc:	eb 7c                	jmp    10654a <pmap_setperm+0x1f8>
		switch(perm & SYS_RW){
		case 0:
			if(!((*tmp_pte) & SYS_RW))
				*tmp_pte = *tmp_pte | PTE_U | PTE_P;
			else{
				*tmp_pte &= ~(SYS_RW | PTE_P | PTE_W);
  1064ce:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1064d1:	8b 00                	mov    (%eax),%eax
  1064d3:	89 c2                	mov    %eax,%edx
  1064d5:	81 e2 fc f9 ff ff    	and    $0xfffff9fc,%edx
  1064db:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1064de:	89 10                	mov    %edx,(%eax)
			}
			break;
  1064e0:	eb 68                	jmp    10654a <pmap_setperm+0x1f8>
		case SYS_READ:
			*tmp_pte &= ~(SYS_RW | PTE_P | PTE_W);
  1064e2:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1064e5:	8b 00                	mov    (%eax),%eax
  1064e7:	89 c2                	mov    %eax,%edx
  1064e9:	81 e2 fc f9 ff ff    	and    $0xfffff9fc,%edx
  1064ef:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1064f2:	89 10                	mov    %edx,(%eax)
			*tmp_pte |= (SYS_READ | PTE_U | PTE_P);
  1064f4:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1064f7:	8b 00                	mov    (%eax),%eax
  1064f9:	89 c2                	mov    %eax,%edx
  1064fb:	81 ca 05 02 00 00    	or     $0x205,%edx
  106501:	8b 45 e8             	mov    -0x18(%ebp),%eax
  106504:	89 10                	mov    %edx,(%eax)
			break;
  106506:	eb 42                	jmp    10654a <pmap_setperm+0x1f8>
		case SYS_RW:
			*tmp_pte &= ~(SYS_RW | PTE_P | PTE_W);
  106508:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10650b:	8b 00                	mov    (%eax),%eax
  10650d:	89 c2                	mov    %eax,%edx
  10650f:	81 e2 fc f9 ff ff    	and    $0xfffff9fc,%edx
  106515:	8b 45 e8             	mov    -0x18(%ebp),%eax
  106518:	89 10                	mov    %edx,(%eax)
			*tmp_pte |= (SYS_RW| PTE_U | PTE_P);
  10651a:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10651d:	8b 00                	mov    (%eax),%eax
  10651f:	89 c2                	mov    %eax,%edx
  106521:	81 ca 05 06 00 00    	or     $0x605,%edx
  106527:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10652a:	89 10                	mov    %edx,(%eax)
			break;
  10652c:	eb 1c                	jmp    10654a <pmap_setperm+0x1f8>
		default:
			panic("In pmap_setperm,unrecognized perm.\n");
  10652e:	c7 44 24 08 0c b4 10 	movl   $0x10b40c,0x8(%esp)
  106535:	00 
  106536:	c7 44 24 04 5b 02 00 	movl   $0x25b,0x4(%esp)
  10653d:	00 
  10653e:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106545:	e8 ee a3 ff ff       	call   100938 <debug_panic>
		}
		tmp_va += PAGESIZE;
  10654a:	81 45 f0 00 10 00 00 	addl   $0x1000,-0x10(%ebp)

	uint32_t page_accout = size/PAGESIZE;
	int i = 0;
	pte_t* tmp_pte;
	uint32_t tmp_va = va;
	for(i; i < page_accout; i++){
  106551:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  106555:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106558:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  10655b:	0f 82 07 ff ff ff    	jb     106468 <pmap_setperm+0x116>
	}
	/*
	if(va == 0x40401000)
			cprintf("in pmap_setperm, after flush, pde: %x, pte: %x, pdir: %x.\n", pdir[PDX(va)], *pmap_walk(pdir, va, false),*(uint32_t*)pdir);
	*/
	return 1;
  106561:	b8 01 00 00 00       	mov    $0x1,%eax
}
  106566:	c9                   	leave  
  106567:	c3                   	ret    

00106568 <va2pa>:
// this functionality for us!  We define our own version to help check
// the pmap_check() function; it shouldn't be used elsewhere.
//
static uint32_t
va2pa(pde_t *pdir, uintptr_t va)
{
  106568:	55                   	push   %ebp
  106569:	89 e5                	mov    %esp,%ebp
  10656b:	83 ec 10             	sub    $0x10,%esp
	pde_t* ptmp = pdir;
  10656e:	8b 45 08             	mov    0x8(%ebp),%eax
  106571:	89 45 fc             	mov    %eax,-0x4(%ebp)
	pdir = &pdir[PDX(va)];
  106574:	8b 45 0c             	mov    0xc(%ebp),%eax
  106577:	c1 e8 16             	shr    $0x16,%eax
  10657a:	c1 e0 02             	shl    $0x2,%eax
  10657d:	01 45 08             	add    %eax,0x8(%ebp)
	if (!(*pdir & PTE_P))
  106580:	8b 45 08             	mov    0x8(%ebp),%eax
  106583:	8b 00                	mov    (%eax),%eax
  106585:	83 e0 01             	and    $0x1,%eax
  106588:	85 c0                	test   %eax,%eax
  10658a:	75 07                	jne    106593 <va2pa+0x2b>
		return ~0;
  10658c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  106591:	eb 52                	jmp    1065e5 <va2pa+0x7d>
	pte_t *ptab = mem_ptr(PGADDR(*pdir));
  106593:	8b 45 08             	mov    0x8(%ebp),%eax
  106596:	8b 00                	mov    (%eax),%eax
  106598:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10659d:	89 45 f8             	mov    %eax,-0x8(%ebp)
	if (!(ptab[PTX(va)] & PTE_P))
  1065a0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1065a3:	c1 e8 0c             	shr    $0xc,%eax
  1065a6:	25 ff 03 00 00       	and    $0x3ff,%eax
  1065ab:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  1065b2:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1065b5:	01 d0                	add    %edx,%eax
  1065b7:	8b 00                	mov    (%eax),%eax
  1065b9:	83 e0 01             	and    $0x1,%eax
  1065bc:	85 c0                	test   %eax,%eax
  1065be:	75 07                	jne    1065c7 <va2pa+0x5f>
		return ~0;
  1065c0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1065c5:	eb 1e                	jmp    1065e5 <va2pa+0x7d>
	return PGADDR(ptab[PTX(va)]);
  1065c7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1065ca:	c1 e8 0c             	shr    $0xc,%eax
  1065cd:	25 ff 03 00 00       	and    $0x3ff,%eax
  1065d2:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  1065d9:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1065dc:	01 d0                	add    %edx,%eax
  1065de:	8b 00                	mov    (%eax),%eax
  1065e0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
}
  1065e5:	c9                   	leave  
  1065e6:	c3                   	ret    

001065e7 <pmap_check>:

// check pmap_insert, pmap_remove, &c
void
pmap_check(void)
{
  1065e7:	55                   	push   %ebp
  1065e8:	89 e5                	mov    %esp,%ebp
  1065ea:	53                   	push   %ebx
  1065eb:	83 ec 44             	sub    $0x44,%esp
	pageinfo *fl;
	pte_t *ptep, *ptep1;
	int i;

	// should be able to allocate three pages
	pi0 = pi1 = pi2 = 0;
  1065ee:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  1065f5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1065f8:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1065fb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1065fe:	89 45 e8             	mov    %eax,-0x18(%ebp)
	pi0 = mem_alloc();
  106601:	e8 c5 a9 ff ff       	call   100fcb <mem_alloc>
  106606:	89 45 e8             	mov    %eax,-0x18(%ebp)
	pi1 = mem_alloc();
  106609:	e8 bd a9 ff ff       	call   100fcb <mem_alloc>
  10660e:	89 45 ec             	mov    %eax,-0x14(%ebp)
	pi2 = mem_alloc();
  106611:	e8 b5 a9 ff ff       	call   100fcb <mem_alloc>
  106616:	89 45 f0             	mov    %eax,-0x10(%ebp)
	pi3 = mem_alloc();
  106619:	e8 ad a9 ff ff       	call   100fcb <mem_alloc>
  10661e:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	assert(pi0);
  106621:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  106625:	75 24                	jne    10664b <pmap_check+0x64>
  106627:	c7 44 24 0c 30 b4 10 	movl   $0x10b430,0xc(%esp)
  10662e:	00 
  10662f:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106636:	00 
  106637:	c7 44 24 04 8b 02 00 	movl   $0x28b,0x4(%esp)
  10663e:	00 
  10663f:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106646:	e8 ed a2 ff ff       	call   100938 <debug_panic>
	assert(pi1 && pi1 != pi0);
  10664b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  10664f:	74 08                	je     106659 <pmap_check+0x72>
  106651:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106654:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  106657:	75 24                	jne    10667d <pmap_check+0x96>
  106659:	c7 44 24 0c 34 b4 10 	movl   $0x10b434,0xc(%esp)
  106660:	00 
  106661:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106668:	00 
  106669:	c7 44 24 04 8c 02 00 	movl   $0x28c,0x4(%esp)
  106670:	00 
  106671:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106678:	e8 bb a2 ff ff       	call   100938 <debug_panic>
	assert(pi2 && pi2 != pi1 && pi2 != pi0);
  10667d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  106681:	74 10                	je     106693 <pmap_check+0xac>
  106683:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106686:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  106689:	74 08                	je     106693 <pmap_check+0xac>
  10668b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10668e:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  106691:	75 24                	jne    1066b7 <pmap_check+0xd0>
  106693:	c7 44 24 0c 48 b4 10 	movl   $0x10b448,0xc(%esp)
  10669a:	00 
  10669b:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1066a2:	00 
  1066a3:	c7 44 24 04 8d 02 00 	movl   $0x28d,0x4(%esp)
  1066aa:	00 
  1066ab:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1066b2:	e8 81 a2 ff ff       	call   100938 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  1066b7:	a1 40 8f 38 00       	mov    0x388f40,%eax
  1066bc:	89 45 e0             	mov    %eax,-0x20(%ebp)
	mem_freelist = NULL;
  1066bf:	c7 05 40 8f 38 00 00 	movl   $0x0,0x388f40
  1066c6:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == NULL);
  1066c9:	e8 fd a8 ff ff       	call   100fcb <mem_alloc>
  1066ce:	85 c0                	test   %eax,%eax
  1066d0:	74 24                	je     1066f6 <pmap_check+0x10f>
  1066d2:	c7 44 24 0c 68 b4 10 	movl   $0x10b468,0xc(%esp)
  1066d9:	00 
  1066da:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1066e1:	00 
  1066e2:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
  1066e9:	00 
  1066ea:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1066f1:	e8 42 a2 ff ff       	call   100938 <debug_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) == NULL);
  1066f6:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1066fd:	00 
  1066fe:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  106705:	40 
  106706:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106709:	89 44 24 04          	mov    %eax,0x4(%esp)
  10670d:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  106714:	e8 f7 e7 ff ff       	call   104f10 <pmap_insert>
  106719:	85 c0                	test   %eax,%eax
  10671b:	74 24                	je     106741 <pmap_check+0x15a>
  10671d:	c7 44 24 0c 7c b4 10 	movl   $0x10b47c,0xc(%esp)
  106724:	00 
  106725:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10672c:	00 
  10672d:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
  106734:	00 
  106735:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10673c:	e8 f7 a1 ff ff       	call   100938 <debug_panic>

	// free pi0 and try again: pi0 should be used for page table
	mem_free(pi0);
  106741:	8b 45 e8             	mov    -0x18(%ebp),%eax
  106744:	89 04 24             	mov    %eax,(%esp)
  106747:	e8 d1 a8 ff ff       	call   10101d <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) != NULL);
  10674c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  106753:	00 
  106754:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  10675b:	40 
  10675c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10675f:	89 44 24 04          	mov    %eax,0x4(%esp)
  106763:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  10676a:	e8 a1 e7 ff ff       	call   104f10 <pmap_insert>
  10676f:	85 c0                	test   %eax,%eax
  106771:	75 24                	jne    106797 <pmap_check+0x1b0>
  106773:	c7 44 24 0c b4 b4 10 	movl   $0x10b4b4,0xc(%esp)
  10677a:	00 
  10677b:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106782:	00 
  106783:	c7 44 24 04 9b 02 00 	movl   $0x29b,0x4(%esp)
  10678a:	00 
  10678b:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106792:	e8 a1 a1 ff ff       	call   100938 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi0));
  106797:	a1 00 a4 38 00       	mov    0x38a400,%eax
  10679c:	89 c1                	mov    %eax,%ecx
  10679e:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  1067a4:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1067a7:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1067ac:	89 d3                	mov    %edx,%ebx
  1067ae:	29 c3                	sub    %eax,%ebx
  1067b0:	89 d8                	mov    %ebx,%eax
  1067b2:	c1 f8 03             	sar    $0x3,%eax
  1067b5:	c1 e0 0c             	shl    $0xc,%eax
  1067b8:	39 c1                	cmp    %eax,%ecx
  1067ba:	74 24                	je     1067e0 <pmap_check+0x1f9>
  1067bc:	c7 44 24 0c ec b4 10 	movl   $0x10b4ec,0xc(%esp)
  1067c3:	00 
  1067c4:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1067cb:	00 
  1067cc:	c7 44 24 04 9c 02 00 	movl   $0x29c,0x4(%esp)
  1067d3:	00 
  1067d4:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1067db:	e8 58 a1 ff ff       	call   100938 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO) == mem_pi2phys(pi1));
  1067e0:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  1067e7:	40 
  1067e8:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  1067ef:	e8 74 fd ff ff       	call   106568 <va2pa>
  1067f4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
  1067f7:	8b 15 50 8f 38 00    	mov    0x388f50,%edx
  1067fd:	89 cb                	mov    %ecx,%ebx
  1067ff:	29 d3                	sub    %edx,%ebx
  106801:	89 da                	mov    %ebx,%edx
  106803:	c1 fa 03             	sar    $0x3,%edx
  106806:	c1 e2 0c             	shl    $0xc,%edx
  106809:	39 d0                	cmp    %edx,%eax
  10680b:	74 24                	je     106831 <pmap_check+0x24a>
  10680d:	c7 44 24 0c 28 b5 10 	movl   $0x10b528,0xc(%esp)
  106814:	00 
  106815:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10681c:	00 
  10681d:	c7 44 24 04 9d 02 00 	movl   $0x29d,0x4(%esp)
  106824:	00 
  106825:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10682c:	e8 07 a1 ff ff       	call   100938 <debug_panic>
	assert(pi1->refcount == 1);
  106831:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106834:	8b 40 04             	mov    0x4(%eax),%eax
  106837:	83 f8 01             	cmp    $0x1,%eax
  10683a:	74 24                	je     106860 <pmap_check+0x279>
  10683c:	c7 44 24 0c 5c b5 10 	movl   $0x10b55c,0xc(%esp)
  106843:	00 
  106844:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10684b:	00 
  10684c:	c7 44 24 04 9e 02 00 	movl   $0x29e,0x4(%esp)
  106853:	00 
  106854:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10685b:	e8 d8 a0 ff ff       	call   100938 <debug_panic>
	assert(pi0->refcount == 1);
  106860:	8b 45 e8             	mov    -0x18(%ebp),%eax
  106863:	8b 40 04             	mov    0x4(%eax),%eax
  106866:	83 f8 01             	cmp    $0x1,%eax
  106869:	74 24                	je     10688f <pmap_check+0x2a8>
  10686b:	c7 44 24 0c 6f b5 10 	movl   $0x10b56f,0xc(%esp)
  106872:	00 
  106873:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10687a:	00 
  10687b:	c7 44 24 04 9f 02 00 	movl   $0x29f,0x4(%esp)
  106882:	00 
  106883:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10688a:	e8 a9 a0 ff ff       	call   100938 <debug_panic>

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because pi0 is already allocated for page table
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
  10688f:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  106896:	00 
  106897:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  10689e:	40 
  10689f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1068a2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1068a6:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  1068ad:	e8 5e e6 ff ff       	call   104f10 <pmap_insert>
  1068b2:	85 c0                	test   %eax,%eax
  1068b4:	75 24                	jne    1068da <pmap_check+0x2f3>
  1068b6:	c7 44 24 0c 84 b5 10 	movl   $0x10b584,0xc(%esp)
  1068bd:	00 
  1068be:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1068c5:	00 
  1068c6:	c7 44 24 04 a3 02 00 	movl   $0x2a3,0x4(%esp)
  1068cd:	00 
  1068ce:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1068d5:	e8 5e a0 ff ff       	call   100938 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  1068da:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1068e1:	40 
  1068e2:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  1068e9:	e8 7a fc ff ff       	call   106568 <va2pa>
  1068ee:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  1068f1:	8b 15 50 8f 38 00    	mov    0x388f50,%edx
  1068f7:	89 cb                	mov    %ecx,%ebx
  1068f9:	29 d3                	sub    %edx,%ebx
  1068fb:	89 da                	mov    %ebx,%edx
  1068fd:	c1 fa 03             	sar    $0x3,%edx
  106900:	c1 e2 0c             	shl    $0xc,%edx
  106903:	39 d0                	cmp    %edx,%eax
  106905:	74 24                	je     10692b <pmap_check+0x344>
  106907:	c7 44 24 0c bc b5 10 	movl   $0x10b5bc,0xc(%esp)
  10690e:	00 
  10690f:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106916:	00 
  106917:	c7 44 24 04 a4 02 00 	movl   $0x2a4,0x4(%esp)
  10691e:	00 
  10691f:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106926:	e8 0d a0 ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 1);
  10692b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10692e:	8b 40 04             	mov    0x4(%eax),%eax
  106931:	83 f8 01             	cmp    $0x1,%eax
  106934:	74 24                	je     10695a <pmap_check+0x373>
  106936:	c7 44 24 0c f9 b5 10 	movl   $0x10b5f9,0xc(%esp)
  10693d:	00 
  10693e:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106945:	00 
  106946:	c7 44 24 04 a5 02 00 	movl   $0x2a5,0x4(%esp)
  10694d:	00 
  10694e:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106955:	e8 de 9f ff ff       	call   100938 <debug_panic>
	// should be no free memory
	assert(mem_alloc() == NULL);
  10695a:	e8 6c a6 ff ff       	call   100fcb <mem_alloc>
  10695f:	85 c0                	test   %eax,%eax
  106961:	74 24                	je     106987 <pmap_check+0x3a0>
  106963:	c7 44 24 0c 68 b4 10 	movl   $0x10b468,0xc(%esp)
  10696a:	00 
  10696b:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106972:	00 
  106973:	c7 44 24 04 a7 02 00 	movl   $0x2a7,0x4(%esp)
  10697a:	00 
  10697b:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106982:	e8 b1 9f ff ff       	call   100938 <debug_panic>

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because it's already there
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
  106987:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10698e:	00 
  10698f:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  106996:	40 
  106997:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10699a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10699e:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  1069a5:	e8 66 e5 ff ff       	call   104f10 <pmap_insert>
  1069aa:	85 c0                	test   %eax,%eax
  1069ac:	75 24                	jne    1069d2 <pmap_check+0x3eb>
  1069ae:	c7 44 24 0c 84 b5 10 	movl   $0x10b584,0xc(%esp)
  1069b5:	00 
  1069b6:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1069bd:	00 
  1069be:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
  1069c5:	00 
  1069c6:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1069cd:	e8 66 9f ff ff       	call   100938 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  1069d2:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1069d9:	40 
  1069da:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  1069e1:	e8 82 fb ff ff       	call   106568 <va2pa>
  1069e6:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  1069e9:	8b 15 50 8f 38 00    	mov    0x388f50,%edx
  1069ef:	89 cb                	mov    %ecx,%ebx
  1069f1:	29 d3                	sub    %edx,%ebx
  1069f3:	89 da                	mov    %ebx,%edx
  1069f5:	c1 fa 03             	sar    $0x3,%edx
  1069f8:	c1 e2 0c             	shl    $0xc,%edx
  1069fb:	39 d0                	cmp    %edx,%eax
  1069fd:	74 24                	je     106a23 <pmap_check+0x43c>
  1069ff:	c7 44 24 0c bc b5 10 	movl   $0x10b5bc,0xc(%esp)
  106a06:	00 
  106a07:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106a0e:	00 
  106a0f:	c7 44 24 04 ac 02 00 	movl   $0x2ac,0x4(%esp)
  106a16:	00 
  106a17:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106a1e:	e8 15 9f ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 1);
  106a23:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106a26:	8b 40 04             	mov    0x4(%eax),%eax
  106a29:	83 f8 01             	cmp    $0x1,%eax
  106a2c:	74 24                	je     106a52 <pmap_check+0x46b>
  106a2e:	c7 44 24 0c f9 b5 10 	movl   $0x10b5f9,0xc(%esp)
  106a35:	00 
  106a36:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106a3d:	00 
  106a3e:	c7 44 24 04 ad 02 00 	movl   $0x2ad,0x4(%esp)
  106a45:	00 
  106a46:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106a4d:	e8 e6 9e ff ff       	call   100938 <debug_panic>

	// pi2 should NOT be on the free list
	// could hapien in ref counts are handled slopiily in pmap_insert
	assert(mem_alloc() == NULL);
  106a52:	e8 74 a5 ff ff       	call   100fcb <mem_alloc>
  106a57:	85 c0                	test   %eax,%eax
  106a59:	74 24                	je     106a7f <pmap_check+0x498>
  106a5b:	c7 44 24 0c 68 b4 10 	movl   $0x10b468,0xc(%esp)
  106a62:	00 
  106a63:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106a6a:	00 
  106a6b:	c7 44 24 04 b1 02 00 	movl   $0x2b1,0x4(%esp)
  106a72:	00 
  106a73:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106a7a:	e8 b9 9e ff ff       	call   100938 <debug_panic>

	// check that pmap_walk returns a pointer to the pte
	ptep = mem_ptr(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PAGESIZE)]));
  106a7f:	a1 00 a4 38 00       	mov    0x38a400,%eax
  106a84:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106a89:	89 45 dc             	mov    %eax,-0x24(%ebp)
	assert(pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0)
  106a8c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  106a93:	00 
  106a94:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  106a9b:	40 
  106a9c:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  106aa3:	e8 27 e2 ff ff       	call   104ccf <pmap_walk>
  106aa8:	8b 55 dc             	mov    -0x24(%ebp),%edx
  106aab:	83 c2 04             	add    $0x4,%edx
  106aae:	39 d0                	cmp    %edx,%eax
  106ab0:	74 24                	je     106ad6 <pmap_check+0x4ef>
  106ab2:	c7 44 24 0c 0c b6 10 	movl   $0x10b60c,0xc(%esp)
  106ab9:	00 
  106aba:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106ac1:	00 
  106ac2:	c7 44 24 04 b6 02 00 	movl   $0x2b6,0x4(%esp)
  106ac9:	00 
  106aca:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106ad1:	e8 62 9e ff ff       	call   100938 <debug_panic>
		== ptep+PTX(VM_USERLO+PAGESIZE));

	// should be able to change permissions too.
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, PTE_U));
  106ad6:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  106add:	00 
  106ade:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  106ae5:	40 
  106ae6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106ae9:	89 44 24 04          	mov    %eax,0x4(%esp)
  106aed:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  106af4:	e8 17 e4 ff ff       	call   104f10 <pmap_insert>
  106af9:	85 c0                	test   %eax,%eax
  106afb:	75 24                	jne    106b21 <pmap_check+0x53a>
  106afd:	c7 44 24 0c 5c b6 10 	movl   $0x10b65c,0xc(%esp)
  106b04:	00 
  106b05:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106b0c:	00 
  106b0d:	c7 44 24 04 b9 02 00 	movl   $0x2b9,0x4(%esp)
  106b14:	00 
  106b15:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106b1c:	e8 17 9e ff ff       	call   100938 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  106b21:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  106b28:	40 
  106b29:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  106b30:	e8 33 fa ff ff       	call   106568 <va2pa>
  106b35:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  106b38:	8b 15 50 8f 38 00    	mov    0x388f50,%edx
  106b3e:	89 cb                	mov    %ecx,%ebx
  106b40:	29 d3                	sub    %edx,%ebx
  106b42:	89 da                	mov    %ebx,%edx
  106b44:	c1 fa 03             	sar    $0x3,%edx
  106b47:	c1 e2 0c             	shl    $0xc,%edx
  106b4a:	39 d0                	cmp    %edx,%eax
  106b4c:	74 24                	je     106b72 <pmap_check+0x58b>
  106b4e:	c7 44 24 0c bc b5 10 	movl   $0x10b5bc,0xc(%esp)
  106b55:	00 
  106b56:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106b5d:	00 
  106b5e:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
  106b65:	00 
  106b66:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106b6d:	e8 c6 9d ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 1);
  106b72:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106b75:	8b 40 04             	mov    0x4(%eax),%eax
  106b78:	83 f8 01             	cmp    $0x1,%eax
  106b7b:	74 24                	je     106ba1 <pmap_check+0x5ba>
  106b7d:	c7 44 24 0c f9 b5 10 	movl   $0x10b5f9,0xc(%esp)
  106b84:	00 
  106b85:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106b8c:	00 
  106b8d:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
  106b94:	00 
  106b95:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106b9c:	e8 97 9d ff ff       	call   100938 <debug_panic>
	assert(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U);
  106ba1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  106ba8:	00 
  106ba9:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  106bb0:	40 
  106bb1:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  106bb8:	e8 12 e1 ff ff       	call   104ccf <pmap_walk>
  106bbd:	8b 00                	mov    (%eax),%eax
  106bbf:	83 e0 04             	and    $0x4,%eax
  106bc2:	85 c0                	test   %eax,%eax
  106bc4:	75 24                	jne    106bea <pmap_check+0x603>
  106bc6:	c7 44 24 0c 98 b6 10 	movl   $0x10b698,0xc(%esp)
  106bcd:	00 
  106bce:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106bd5:	00 
  106bd6:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
  106bdd:	00 
  106bde:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106be5:	e8 4e 9d ff ff       	call   100938 <debug_panic>
	assert(pmap_bootpdir[PDX(VM_USERLO)] & PTE_U);
  106bea:	a1 00 a4 38 00       	mov    0x38a400,%eax
  106bef:	83 e0 04             	and    $0x4,%eax
  106bf2:	85 c0                	test   %eax,%eax
  106bf4:	75 24                	jne    106c1a <pmap_check+0x633>
  106bf6:	c7 44 24 0c d4 b6 10 	movl   $0x10b6d4,0xc(%esp)
  106bfd:	00 
  106bfe:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106c05:	00 
  106c06:	c7 44 24 04 bd 02 00 	movl   $0x2bd,0x4(%esp)
  106c0d:	00 
  106c0e:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106c15:	e8 1e 9d ff ff       	call   100938 <debug_panic>
	
	// should not be able to map at VM_USERLO+PTSIZE
	// because we need a free page for a page table
	assert(pmap_insert(pmap_bootpdir, pi0, VM_USERLO+PTSIZE, 0) == NULL);
  106c1a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  106c21:	00 
  106c22:	c7 44 24 08 00 00 40 	movl   $0x40400000,0x8(%esp)
  106c29:	40 
  106c2a:	8b 45 e8             	mov    -0x18(%ebp),%eax
  106c2d:	89 44 24 04          	mov    %eax,0x4(%esp)
  106c31:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  106c38:	e8 d3 e2 ff ff       	call   104f10 <pmap_insert>
  106c3d:	85 c0                	test   %eax,%eax
  106c3f:	74 24                	je     106c65 <pmap_check+0x67e>
  106c41:	c7 44 24 0c fc b6 10 	movl   $0x10b6fc,0xc(%esp)
  106c48:	00 
  106c49:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106c50:	00 
  106c51:	c7 44 24 04 c1 02 00 	movl   $0x2c1,0x4(%esp)
  106c58:	00 
  106c59:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106c60:	e8 d3 9c ff ff       	call   100938 <debug_panic>

	// insert pi1 at VM_USERLO+PAGESIZE (replacing pi2)
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO+PAGESIZE, 0));
  106c65:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  106c6c:	00 
  106c6d:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  106c74:	40 
  106c75:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106c78:	89 44 24 04          	mov    %eax,0x4(%esp)
  106c7c:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  106c83:	e8 88 e2 ff ff       	call   104f10 <pmap_insert>
  106c88:	85 c0                	test   %eax,%eax
  106c8a:	75 24                	jne    106cb0 <pmap_check+0x6c9>
  106c8c:	c7 44 24 0c 3c b7 10 	movl   $0x10b73c,0xc(%esp)
  106c93:	00 
  106c94:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106c9b:	00 
  106c9c:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
  106ca3:	00 
  106ca4:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106cab:	e8 88 9c ff ff       	call   100938 <debug_panic>
	assert(!(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U));
  106cb0:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  106cb7:	00 
  106cb8:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  106cbf:	40 
  106cc0:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  106cc7:	e8 03 e0 ff ff       	call   104ccf <pmap_walk>
  106ccc:	8b 00                	mov    (%eax),%eax
  106cce:	83 e0 04             	and    $0x4,%eax
  106cd1:	85 c0                	test   %eax,%eax
  106cd3:	74 24                	je     106cf9 <pmap_check+0x712>
  106cd5:	c7 44 24 0c 74 b7 10 	movl   $0x10b774,0xc(%esp)
  106cdc:	00 
  106cdd:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106ce4:	00 
  106ce5:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
  106cec:	00 
  106ced:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106cf4:	e8 3f 9c ff ff       	call   100938 <debug_panic>

	// should have pi1 at both +0 and +PAGESIZE, pi2 nowhere, ...
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == mem_pi2phys(pi1));
  106cf9:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  106d00:	40 
  106d01:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  106d08:	e8 5b f8 ff ff       	call   106568 <va2pa>
  106d0d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
  106d10:	8b 15 50 8f 38 00    	mov    0x388f50,%edx
  106d16:	89 cb                	mov    %ecx,%ebx
  106d18:	29 d3                	sub    %edx,%ebx
  106d1a:	89 da                	mov    %ebx,%edx
  106d1c:	c1 fa 03             	sar    $0x3,%edx
  106d1f:	c1 e2 0c             	shl    $0xc,%edx
  106d22:	39 d0                	cmp    %edx,%eax
  106d24:	74 24                	je     106d4a <pmap_check+0x763>
  106d26:	c7 44 24 0c b0 b7 10 	movl   $0x10b7b0,0xc(%esp)
  106d2d:	00 
  106d2e:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106d35:	00 
  106d36:	c7 44 24 04 c8 02 00 	movl   $0x2c8,0x4(%esp)
  106d3d:	00 
  106d3e:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106d45:	e8 ee 9b ff ff       	call   100938 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
  106d4a:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  106d51:	40 
  106d52:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  106d59:	e8 0a f8 ff ff       	call   106568 <va2pa>
  106d5e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
  106d61:	8b 15 50 8f 38 00    	mov    0x388f50,%edx
  106d67:	89 cb                	mov    %ecx,%ebx
  106d69:	29 d3                	sub    %edx,%ebx
  106d6b:	89 da                	mov    %ebx,%edx
  106d6d:	c1 fa 03             	sar    $0x3,%edx
  106d70:	c1 e2 0c             	shl    $0xc,%edx
  106d73:	39 d0                	cmp    %edx,%eax
  106d75:	74 24                	je     106d9b <pmap_check+0x7b4>
  106d77:	c7 44 24 0c e8 b7 10 	movl   $0x10b7e8,0xc(%esp)
  106d7e:	00 
  106d7f:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106d86:	00 
  106d87:	c7 44 24 04 c9 02 00 	movl   $0x2c9,0x4(%esp)
  106d8e:	00 
  106d8f:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106d96:	e8 9d 9b ff ff       	call   100938 <debug_panic>
	// ... and ref counts should reflect this
	assert(pi1->refcount == 2);
  106d9b:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106d9e:	8b 40 04             	mov    0x4(%eax),%eax
  106da1:	83 f8 02             	cmp    $0x2,%eax
  106da4:	74 24                	je     106dca <pmap_check+0x7e3>
  106da6:	c7 44 24 0c 25 b8 10 	movl   $0x10b825,0xc(%esp)
  106dad:	00 
  106dae:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106db5:	00 
  106db6:	c7 44 24 04 cb 02 00 	movl   $0x2cb,0x4(%esp)
  106dbd:	00 
  106dbe:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106dc5:	e8 6e 9b ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 0);
  106dca:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106dcd:	8b 40 04             	mov    0x4(%eax),%eax
  106dd0:	85 c0                	test   %eax,%eax
  106dd2:	74 24                	je     106df8 <pmap_check+0x811>
  106dd4:	c7 44 24 0c 38 b8 10 	movl   $0x10b838,0xc(%esp)
  106ddb:	00 
  106ddc:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106de3:	00 
  106de4:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
  106deb:	00 
  106dec:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106df3:	e8 40 9b ff ff       	call   100938 <debug_panic>

	// pi2 should be returned by mem_alloc
	assert(mem_alloc() == pi2);
  106df8:	e8 ce a1 ff ff       	call   100fcb <mem_alloc>
  106dfd:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  106e00:	74 24                	je     106e26 <pmap_check+0x83f>
  106e02:	c7 44 24 0c 4b b8 10 	movl   $0x10b84b,0xc(%esp)
  106e09:	00 
  106e0a:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106e11:	00 
  106e12:	c7 44 24 04 cf 02 00 	movl   $0x2cf,0x4(%esp)
  106e19:	00 
  106e1a:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106e21:	e8 12 9b ff ff       	call   100938 <debug_panic>

	// unmapping pi1 at VM_USERLO+0 should keep pi1 at +PAGESIZE
	pmap_remove(pmap_bootpdir, VM_USERLO+0, PAGESIZE);
  106e26:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  106e2d:	00 
  106e2e:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  106e35:	40 
  106e36:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  106e3d:	e8 0c e3 ff ff       	call   10514e <pmap_remove>
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
  106e42:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  106e49:	40 
  106e4a:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  106e51:	e8 12 f7 ff ff       	call   106568 <va2pa>
  106e56:	83 f8 ff             	cmp    $0xffffffff,%eax
  106e59:	74 24                	je     106e7f <pmap_check+0x898>
  106e5b:	c7 44 24 0c 60 b8 10 	movl   $0x10b860,0xc(%esp)
  106e62:	00 
  106e63:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106e6a:	00 
  106e6b:	c7 44 24 04 d3 02 00 	movl   $0x2d3,0x4(%esp)
  106e72:	00 
  106e73:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106e7a:	e8 b9 9a ff ff       	call   100938 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
  106e7f:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  106e86:	40 
  106e87:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  106e8e:	e8 d5 f6 ff ff       	call   106568 <va2pa>
  106e93:	8b 4d ec             	mov    -0x14(%ebp),%ecx
  106e96:	8b 15 50 8f 38 00    	mov    0x388f50,%edx
  106e9c:	89 cb                	mov    %ecx,%ebx
  106e9e:	29 d3                	sub    %edx,%ebx
  106ea0:	89 da                	mov    %ebx,%edx
  106ea2:	c1 fa 03             	sar    $0x3,%edx
  106ea5:	c1 e2 0c             	shl    $0xc,%edx
  106ea8:	39 d0                	cmp    %edx,%eax
  106eaa:	74 24                	je     106ed0 <pmap_check+0x8e9>
  106eac:	c7 44 24 0c e8 b7 10 	movl   $0x10b7e8,0xc(%esp)
  106eb3:	00 
  106eb4:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106ebb:	00 
  106ebc:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
  106ec3:	00 
  106ec4:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106ecb:	e8 68 9a ff ff       	call   100938 <debug_panic>
	assert(pi1->refcount == 1);
  106ed0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106ed3:	8b 40 04             	mov    0x4(%eax),%eax
  106ed6:	83 f8 01             	cmp    $0x1,%eax
  106ed9:	74 24                	je     106eff <pmap_check+0x918>
  106edb:	c7 44 24 0c 5c b5 10 	movl   $0x10b55c,0xc(%esp)
  106ee2:	00 
  106ee3:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106eea:	00 
  106eeb:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
  106ef2:	00 
  106ef3:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106efa:	e8 39 9a ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 0);
  106eff:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106f02:	8b 40 04             	mov    0x4(%eax),%eax
  106f05:	85 c0                	test   %eax,%eax
  106f07:	74 24                	je     106f2d <pmap_check+0x946>
  106f09:	c7 44 24 0c 38 b8 10 	movl   $0x10b838,0xc(%esp)
  106f10:	00 
  106f11:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106f18:	00 
  106f19:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
  106f20:	00 
  106f21:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106f28:	e8 0b 9a ff ff       	call   100938 <debug_panic>
	assert(mem_alloc() == NULL);	// still should have no pages free
  106f2d:	e8 99 a0 ff ff       	call   100fcb <mem_alloc>
  106f32:	85 c0                	test   %eax,%eax
  106f34:	74 24                	je     106f5a <pmap_check+0x973>
  106f36:	c7 44 24 0c 68 b4 10 	movl   $0x10b468,0xc(%esp)
  106f3d:	00 
  106f3e:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106f45:	00 
  106f46:	c7 44 24 04 d7 02 00 	movl   $0x2d7,0x4(%esp)
  106f4d:	00 
  106f4e:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106f55:	e8 de 99 ff ff       	call   100938 <debug_panic>

	// unmapping pi1 at VM_USERLO+PAGESIZE should free it
	pmap_remove(pmap_bootpdir, VM_USERLO+PAGESIZE, PAGESIZE);
  106f5a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  106f61:	00 
  106f62:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  106f69:	40 
  106f6a:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  106f71:	e8 d8 e1 ff ff       	call   10514e <pmap_remove>
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
  106f76:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  106f7d:	40 
  106f7e:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  106f85:	e8 de f5 ff ff       	call   106568 <va2pa>
  106f8a:	83 f8 ff             	cmp    $0xffffffff,%eax
  106f8d:	74 24                	je     106fb3 <pmap_check+0x9cc>
  106f8f:	c7 44 24 0c 60 b8 10 	movl   $0x10b860,0xc(%esp)
  106f96:	00 
  106f97:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106f9e:	00 
  106f9f:	c7 44 24 04 db 02 00 	movl   $0x2db,0x4(%esp)
  106fa6:	00 
  106fa7:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106fae:	e8 85 99 ff ff       	call   100938 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == ~0);
  106fb3:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  106fba:	40 
  106fbb:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  106fc2:	e8 a1 f5 ff ff       	call   106568 <va2pa>
  106fc7:	83 f8 ff             	cmp    $0xffffffff,%eax
  106fca:	74 24                	je     106ff0 <pmap_check+0xa09>
  106fcc:	c7 44 24 0c 88 b8 10 	movl   $0x10b888,0xc(%esp)
  106fd3:	00 
  106fd4:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  106fdb:	00 
  106fdc:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
  106fe3:	00 
  106fe4:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  106feb:	e8 48 99 ff ff       	call   100938 <debug_panic>
	assert(pi1->refcount == 0);
  106ff0:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106ff3:	8b 40 04             	mov    0x4(%eax),%eax
  106ff6:	85 c0                	test   %eax,%eax
  106ff8:	74 24                	je     10701e <pmap_check+0xa37>
  106ffa:	c7 44 24 0c b7 b8 10 	movl   $0x10b8b7,0xc(%esp)
  107001:	00 
  107002:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107009:	00 
  10700a:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
  107011:	00 
  107012:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107019:	e8 1a 99 ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 0);
  10701e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107021:	8b 40 04             	mov    0x4(%eax),%eax
  107024:	85 c0                	test   %eax,%eax
  107026:	74 24                	je     10704c <pmap_check+0xa65>
  107028:	c7 44 24 0c 38 b8 10 	movl   $0x10b838,0xc(%esp)
  10702f:	00 
  107030:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107037:	00 
  107038:	c7 44 24 04 de 02 00 	movl   $0x2de,0x4(%esp)
  10703f:	00 
  107040:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107047:	e8 ec 98 ff ff       	call   100938 <debug_panic>

	// so it should be returned by page_alloc
	assert(mem_alloc() == pi1);
  10704c:	e8 7a 9f ff ff       	call   100fcb <mem_alloc>
  107051:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  107054:	74 24                	je     10707a <pmap_check+0xa93>
  107056:	c7 44 24 0c ca b8 10 	movl   $0x10b8ca,0xc(%esp)
  10705d:	00 
  10705e:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107065:	00 
  107066:	c7 44 24 04 e1 02 00 	movl   $0x2e1,0x4(%esp)
  10706d:	00 
  10706e:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107075:	e8 be 98 ff ff       	call   100938 <debug_panic>

	// should once again have no free memory
	assert(mem_alloc() == NULL);
  10707a:	e8 4c 9f ff ff       	call   100fcb <mem_alloc>
  10707f:	85 c0                	test   %eax,%eax
  107081:	74 24                	je     1070a7 <pmap_check+0xac0>
  107083:	c7 44 24 0c 68 b4 10 	movl   $0x10b468,0xc(%esp)
  10708a:	00 
  10708b:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107092:	00 
  107093:	c7 44 24 04 e4 02 00 	movl   $0x2e4,0x4(%esp)
  10709a:	00 
  10709b:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1070a2:	e8 91 98 ff ff       	call   100938 <debug_panic>

	// should be able to pmap_insert to change a page
	// and see the new data immediately.
	memset(mem_pi2ptr(pi1), 1, PAGESIZE);
  1070a7:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1070aa:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1070af:	89 d1                	mov    %edx,%ecx
  1070b1:	29 c1                	sub    %eax,%ecx
  1070b3:	89 c8                	mov    %ecx,%eax
  1070b5:	c1 f8 03             	sar    $0x3,%eax
  1070b8:	c1 e0 0c             	shl    $0xc,%eax
  1070bb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1070c2:	00 
  1070c3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1070ca:	00 
  1070cb:	89 04 24             	mov    %eax,(%esp)
  1070ce:	e8 6e 2b 00 00       	call   109c41 <memset>
	memset(mem_pi2ptr(pi2), 2, PAGESIZE);
  1070d3:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1070d6:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1070db:	89 d3                	mov    %edx,%ebx
  1070dd:	29 c3                	sub    %eax,%ebx
  1070df:	89 d8                	mov    %ebx,%eax
  1070e1:	c1 f8 03             	sar    $0x3,%eax
  1070e4:	c1 e0 0c             	shl    $0xc,%eax
  1070e7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1070ee:	00 
  1070ef:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  1070f6:	00 
  1070f7:	89 04 24             	mov    %eax,(%esp)
  1070fa:	e8 42 2b 00 00       	call   109c41 <memset>
	pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0);
  1070ff:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  107106:	00 
  107107:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  10710e:	40 
  10710f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107112:	89 44 24 04          	mov    %eax,0x4(%esp)
  107116:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  10711d:	e8 ee dd ff ff       	call   104f10 <pmap_insert>
	assert(pi1->refcount == 1);
  107122:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107125:	8b 40 04             	mov    0x4(%eax),%eax
  107128:	83 f8 01             	cmp    $0x1,%eax
  10712b:	74 24                	je     107151 <pmap_check+0xb6a>
  10712d:	c7 44 24 0c 5c b5 10 	movl   $0x10b55c,0xc(%esp)
  107134:	00 
  107135:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10713c:	00 
  10713d:	c7 44 24 04 eb 02 00 	movl   $0x2eb,0x4(%esp)
  107144:	00 
  107145:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10714c:	e8 e7 97 ff ff       	call   100938 <debug_panic>
	assert(*(int*)VM_USERLO == 0x01010101);
  107151:	b8 00 00 00 40       	mov    $0x40000000,%eax
  107156:	8b 00                	mov    (%eax),%eax
  107158:	3d 01 01 01 01       	cmp    $0x1010101,%eax
  10715d:	74 24                	je     107183 <pmap_check+0xb9c>
  10715f:	c7 44 24 0c e0 b8 10 	movl   $0x10b8e0,0xc(%esp)
  107166:	00 
  107167:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10716e:	00 
  10716f:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
  107176:	00 
  107177:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10717e:	e8 b5 97 ff ff       	call   100938 <debug_panic>
	pmap_insert(pmap_bootpdir, pi2, VM_USERLO, 0);
  107183:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10718a:	00 
  10718b:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  107192:	40 
  107193:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107196:	89 44 24 04          	mov    %eax,0x4(%esp)
  10719a:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  1071a1:	e8 6a dd ff ff       	call   104f10 <pmap_insert>
	assert(*(int*)VM_USERLO == 0x02020202);
  1071a6:	b8 00 00 00 40       	mov    $0x40000000,%eax
  1071ab:	8b 00                	mov    (%eax),%eax
  1071ad:	3d 02 02 02 02       	cmp    $0x2020202,%eax
  1071b2:	74 24                	je     1071d8 <pmap_check+0xbf1>
  1071b4:	c7 44 24 0c 00 b9 10 	movl   $0x10b900,0xc(%esp)
  1071bb:	00 
  1071bc:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1071c3:	00 
  1071c4:	c7 44 24 04 ee 02 00 	movl   $0x2ee,0x4(%esp)
  1071cb:	00 
  1071cc:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1071d3:	e8 60 97 ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 1);
  1071d8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1071db:	8b 40 04             	mov    0x4(%eax),%eax
  1071de:	83 f8 01             	cmp    $0x1,%eax
  1071e1:	74 24                	je     107207 <pmap_check+0xc20>
  1071e3:	c7 44 24 0c f9 b5 10 	movl   $0x10b5f9,0xc(%esp)
  1071ea:	00 
  1071eb:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1071f2:	00 
  1071f3:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
  1071fa:	00 
  1071fb:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107202:	e8 31 97 ff ff       	call   100938 <debug_panic>
	assert(pi1->refcount == 0);
  107207:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10720a:	8b 40 04             	mov    0x4(%eax),%eax
  10720d:	85 c0                	test   %eax,%eax
  10720f:	74 24                	je     107235 <pmap_check+0xc4e>
  107211:	c7 44 24 0c b7 b8 10 	movl   $0x10b8b7,0xc(%esp)
  107218:	00 
  107219:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107220:	00 
  107221:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
  107228:	00 
  107229:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107230:	e8 03 97 ff ff       	call   100938 <debug_panic>
	assert(mem_alloc() == pi1);
  107235:	e8 91 9d ff ff       	call   100fcb <mem_alloc>
  10723a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  10723d:	74 24                	je     107263 <pmap_check+0xc7c>
  10723f:	c7 44 24 0c ca b8 10 	movl   $0x10b8ca,0xc(%esp)
  107246:	00 
  107247:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10724e:	00 
  10724f:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
  107256:	00 
  107257:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10725e:	e8 d5 96 ff ff       	call   100938 <debug_panic>
	pmap_remove(pmap_bootpdir, VM_USERLO, PAGESIZE);
  107263:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10726a:	00 
  10726b:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  107272:	40 
  107273:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  10727a:	e8 cf de ff ff       	call   10514e <pmap_remove>
	assert(pi2->refcount == 0);
  10727f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107282:	8b 40 04             	mov    0x4(%eax),%eax
  107285:	85 c0                	test   %eax,%eax
  107287:	74 24                	je     1072ad <pmap_check+0xcc6>
  107289:	c7 44 24 0c 38 b8 10 	movl   $0x10b838,0xc(%esp)
  107290:	00 
  107291:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107298:	00 
  107299:	c7 44 24 04 f3 02 00 	movl   $0x2f3,0x4(%esp)
  1072a0:	00 
  1072a1:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1072a8:	e8 8b 96 ff ff       	call   100938 <debug_panic>
	assert(mem_alloc() == pi2);
  1072ad:	e8 19 9d ff ff       	call   100fcb <mem_alloc>
  1072b2:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1072b5:	74 24                	je     1072db <pmap_check+0xcf4>
  1072b7:	c7 44 24 0c 4b b8 10 	movl   $0x10b84b,0xc(%esp)
  1072be:	00 
  1072bf:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1072c6:	00 
  1072c7:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
  1072ce:	00 
  1072cf:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1072d6:	e8 5d 96 ff ff       	call   100938 <debug_panic>

	// now use a pmap_remove on a large region to take pi0 back
	pmap_remove(pmap_bootpdir, VM_USERLO, VM_USERHI-VM_USERLO);
  1072db:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  1072e2:	b0 
  1072e3:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  1072ea:	40 
  1072eb:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  1072f2:	e8 57 de ff ff       	call   10514e <pmap_remove>
	assert(pmap_bootpdir[PDX(VM_USERLO)] == PTE_ZERO);
  1072f7:	8b 15 00 a4 38 00    	mov    0x38a400,%edx
  1072fd:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  107302:	39 c2                	cmp    %eax,%edx
  107304:	74 24                	je     10732a <pmap_check+0xd43>
  107306:	c7 44 24 0c 20 b9 10 	movl   $0x10b920,0xc(%esp)
  10730d:	00 
  10730e:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107315:	00 
  107316:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
  10731d:	00 
  10731e:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107325:	e8 0e 96 ff ff       	call   100938 <debug_panic>
	assert(pi0->refcount == 0);
  10732a:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10732d:	8b 40 04             	mov    0x4(%eax),%eax
  107330:	85 c0                	test   %eax,%eax
  107332:	74 24                	je     107358 <pmap_check+0xd71>
  107334:	c7 44 24 0c 4a b9 10 	movl   $0x10b94a,0xc(%esp)
  10733b:	00 
  10733c:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107343:	00 
  107344:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
  10734b:	00 
  10734c:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107353:	e8 e0 95 ff ff       	call   100938 <debug_panic>
	assert(mem_alloc() == pi0);
  107358:	e8 6e 9c ff ff       	call   100fcb <mem_alloc>
  10735d:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  107360:	74 24                	je     107386 <pmap_check+0xd9f>
  107362:	c7 44 24 0c 5d b9 10 	movl   $0x10b95d,0xc(%esp)
  107369:	00 
  10736a:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107371:	00 
  107372:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
  107379:	00 
  10737a:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107381:	e8 b2 95 ff ff       	call   100938 <debug_panic>
	assert(mem_freelist == NULL);
  107386:	a1 40 8f 38 00       	mov    0x388f40,%eax
  10738b:	85 c0                	test   %eax,%eax
  10738d:	74 24                	je     1073b3 <pmap_check+0xdcc>
  10738f:	c7 44 24 0c 70 b9 10 	movl   $0x10b970,0xc(%esp)
  107396:	00 
  107397:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10739e:	00 
  10739f:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
  1073a6:	00 
  1073a7:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1073ae:	e8 85 95 ff ff       	call   100938 <debug_panic>

	// test pmap_remove with large, non-ptable-aligned regions
	mem_free(pi1);
  1073b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1073b6:	89 04 24             	mov    %eax,(%esp)
  1073b9:	e8 5f 9c ff ff       	call   10101d <mem_free>
	uintptr_t va = VM_USERLO;
  1073be:	c7 45 d8 00 00 00 40 	movl   $0x40000000,-0x28(%ebp)
	assert(pmap_insert(pmap_bootpdir, pi0, va, 0));
  1073c5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1073cc:	00 
  1073cd:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1073d0:	89 44 24 08          	mov    %eax,0x8(%esp)
  1073d4:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1073d7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1073db:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  1073e2:	e8 29 db ff ff       	call   104f10 <pmap_insert>
  1073e7:	85 c0                	test   %eax,%eax
  1073e9:	75 24                	jne    10740f <pmap_check+0xe28>
  1073eb:	c7 44 24 0c 88 b9 10 	movl   $0x10b988,0xc(%esp)
  1073f2:	00 
  1073f3:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1073fa:	00 
  1073fb:	c7 44 24 04 00 03 00 	movl   $0x300,0x4(%esp)
  107402:	00 
  107403:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10740a:	e8 29 95 ff ff       	call   100938 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PAGESIZE, 0));
  10740f:	8b 45 d8             	mov    -0x28(%ebp),%eax
  107412:	05 00 10 00 00       	add    $0x1000,%eax
  107417:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10741e:	00 
  10741f:	89 44 24 08          	mov    %eax,0x8(%esp)
  107423:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107426:	89 44 24 04          	mov    %eax,0x4(%esp)
  10742a:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  107431:	e8 da da ff ff       	call   104f10 <pmap_insert>
  107436:	85 c0                	test   %eax,%eax
  107438:	75 24                	jne    10745e <pmap_check+0xe77>
  10743a:	c7 44 24 0c b0 b9 10 	movl   $0x10b9b0,0xc(%esp)
  107441:	00 
  107442:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107449:	00 
  10744a:	c7 44 24 04 01 03 00 	movl   $0x301,0x4(%esp)
  107451:	00 
  107452:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107459:	e8 da 94 ff ff       	call   100938 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE-PAGESIZE, 0));
  10745e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  107461:	05 00 f0 3f 00       	add    $0x3ff000,%eax
  107466:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10746d:	00 
  10746e:	89 44 24 08          	mov    %eax,0x8(%esp)
  107472:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107475:	89 44 24 04          	mov    %eax,0x4(%esp)
  107479:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  107480:	e8 8b da ff ff       	call   104f10 <pmap_insert>
  107485:	85 c0                	test   %eax,%eax
  107487:	75 24                	jne    1074ad <pmap_check+0xec6>
  107489:	c7 44 24 0c e0 b9 10 	movl   $0x10b9e0,0xc(%esp)
  107490:	00 
  107491:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107498:	00 
  107499:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
  1074a0:	00 
  1074a1:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1074a8:	e8 8b 94 ff ff       	call   100938 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi1));
  1074ad:	a1 00 a4 38 00       	mov    0x38a400,%eax
  1074b2:	89 c1                	mov    %eax,%ecx
  1074b4:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  1074ba:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1074bd:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1074c2:	89 d3                	mov    %edx,%ebx
  1074c4:	29 c3                	sub    %eax,%ebx
  1074c6:	89 d8                	mov    %ebx,%eax
  1074c8:	c1 f8 03             	sar    $0x3,%eax
  1074cb:	c1 e0 0c             	shl    $0xc,%eax
  1074ce:	39 c1                	cmp    %eax,%ecx
  1074d0:	74 24                	je     1074f6 <pmap_check+0xf0f>
  1074d2:	c7 44 24 0c 18 ba 10 	movl   $0x10ba18,0xc(%esp)
  1074d9:	00 
  1074da:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1074e1:	00 
  1074e2:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
  1074e9:	00 
  1074ea:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1074f1:	e8 42 94 ff ff       	call   100938 <debug_panic>
	assert(mem_freelist == NULL);
  1074f6:	a1 40 8f 38 00       	mov    0x388f40,%eax
  1074fb:	85 c0                	test   %eax,%eax
  1074fd:	74 24                	je     107523 <pmap_check+0xf3c>
  1074ff:	c7 44 24 0c 70 b9 10 	movl   $0x10b970,0xc(%esp)
  107506:	00 
  107507:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10750e:	00 
  10750f:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
  107516:	00 
  107517:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10751e:	e8 15 94 ff ff       	call   100938 <debug_panic>
	mem_free(pi2);
  107523:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107526:	89 04 24             	mov    %eax,(%esp)
  107529:	e8 ef 9a ff ff       	call   10101d <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE, 0));
  10752e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  107531:	05 00 00 40 00       	add    $0x400000,%eax
  107536:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10753d:	00 
  10753e:	89 44 24 08          	mov    %eax,0x8(%esp)
  107542:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107545:	89 44 24 04          	mov    %eax,0x4(%esp)
  107549:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  107550:	e8 bb d9 ff ff       	call   104f10 <pmap_insert>
  107555:	85 c0                	test   %eax,%eax
  107557:	75 24                	jne    10757d <pmap_check+0xf96>
  107559:	c7 44 24 0c 54 ba 10 	movl   $0x10ba54,0xc(%esp)
  107560:	00 
  107561:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107568:	00 
  107569:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
  107570:	00 
  107571:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107578:	e8 bb 93 ff ff       	call   100938 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE+PAGESIZE, 0));
  10757d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  107580:	05 00 10 40 00       	add    $0x401000,%eax
  107585:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10758c:	00 
  10758d:	89 44 24 08          	mov    %eax,0x8(%esp)
  107591:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107594:	89 44 24 04          	mov    %eax,0x4(%esp)
  107598:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  10759f:	e8 6c d9 ff ff       	call   104f10 <pmap_insert>
  1075a4:	85 c0                	test   %eax,%eax
  1075a6:	75 24                	jne    1075cc <pmap_check+0xfe5>
  1075a8:	c7 44 24 0c 84 ba 10 	movl   $0x10ba84,0xc(%esp)
  1075af:	00 
  1075b0:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1075b7:	00 
  1075b8:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
  1075bf:	00 
  1075c0:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1075c7:	e8 6c 93 ff ff       	call   100938 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2-PAGESIZE, 0));
  1075cc:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1075cf:	05 00 f0 7f 00       	add    $0x7ff000,%eax
  1075d4:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1075db:	00 
  1075dc:	89 44 24 08          	mov    %eax,0x8(%esp)
  1075e0:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1075e3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1075e7:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  1075ee:	e8 1d d9 ff ff       	call   104f10 <pmap_insert>
  1075f3:	85 c0                	test   %eax,%eax
  1075f5:	75 24                	jne    10761b <pmap_check+0x1034>
  1075f7:	c7 44 24 0c bc ba 10 	movl   $0x10babc,0xc(%esp)
  1075fe:	00 
  1075ff:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107606:	00 
  107607:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
  10760e:	00 
  10760f:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107616:	e8 1d 93 ff ff       	call   100938 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE)])
  10761b:	a1 04 a4 38 00       	mov    0x38a404,%eax
  107620:	89 c1                	mov    %eax,%ecx
  107622:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  107628:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10762b:	a1 50 8f 38 00       	mov    0x388f50,%eax
  107630:	89 d3                	mov    %edx,%ebx
  107632:	29 c3                	sub    %eax,%ebx
  107634:	89 d8                	mov    %ebx,%eax
  107636:	c1 f8 03             	sar    $0x3,%eax
  107639:	c1 e0 0c             	shl    $0xc,%eax
  10763c:	39 c1                	cmp    %eax,%ecx
  10763e:	74 24                	je     107664 <pmap_check+0x107d>
  107640:	c7 44 24 0c f8 ba 10 	movl   $0x10baf8,0xc(%esp)
  107647:	00 
  107648:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10764f:	00 
  107650:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
  107657:	00 
  107658:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10765f:	e8 d4 92 ff ff       	call   100938 <debug_panic>
		== mem_pi2phys(pi2));
	assert(mem_freelist == NULL);
  107664:	a1 40 8f 38 00       	mov    0x388f40,%eax
  107669:	85 c0                	test   %eax,%eax
  10766b:	74 24                	je     107691 <pmap_check+0x10aa>
  10766d:	c7 44 24 0c 70 b9 10 	movl   $0x10b970,0xc(%esp)
  107674:	00 
  107675:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10767c:	00 
  10767d:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
  107684:	00 
  107685:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10768c:	e8 a7 92 ff ff       	call   100938 <debug_panic>
	mem_free(pi3);
  107691:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  107694:	89 04 24             	mov    %eax,(%esp)
  107697:	e8 81 99 ff ff       	call   10101d <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2, 0));
  10769c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10769f:	05 00 00 80 00       	add    $0x800000,%eax
  1076a4:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1076ab:	00 
  1076ac:	89 44 24 08          	mov    %eax,0x8(%esp)
  1076b0:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1076b3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1076b7:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  1076be:	e8 4d d8 ff ff       	call   104f10 <pmap_insert>
  1076c3:	85 c0                	test   %eax,%eax
  1076c5:	75 24                	jne    1076eb <pmap_check+0x1104>
  1076c7:	c7 44 24 0c 3c bb 10 	movl   $0x10bb3c,0xc(%esp)
  1076ce:	00 
  1076cf:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1076d6:	00 
  1076d7:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
  1076de:	00 
  1076df:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1076e6:	e8 4d 92 ff ff       	call   100938 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2+PAGESIZE, 0));
  1076eb:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1076ee:	05 00 10 80 00       	add    $0x801000,%eax
  1076f3:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1076fa:	00 
  1076fb:	89 44 24 08          	mov    %eax,0x8(%esp)
  1076ff:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107702:	89 44 24 04          	mov    %eax,0x4(%esp)
  107706:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  10770d:	e8 fe d7 ff ff       	call   104f10 <pmap_insert>
  107712:	85 c0                	test   %eax,%eax
  107714:	75 24                	jne    10773a <pmap_check+0x1153>
  107716:	c7 44 24 0c 6c bb 10 	movl   $0x10bb6c,0xc(%esp)
  10771d:	00 
  10771e:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107725:	00 
  107726:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
  10772d:	00 
  10772e:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107735:	e8 fe 91 ff ff       	call   100938 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE*2, 0));
  10773a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10773d:	05 00 e0 bf 00       	add    $0xbfe000,%eax
  107742:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  107749:	00 
  10774a:	89 44 24 08          	mov    %eax,0x8(%esp)
  10774e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107751:	89 44 24 04          	mov    %eax,0x4(%esp)
  107755:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  10775c:	e8 af d7 ff ff       	call   104f10 <pmap_insert>
  107761:	85 c0                	test   %eax,%eax
  107763:	75 24                	jne    107789 <pmap_check+0x11a2>
  107765:	c7 44 24 0c a8 bb 10 	movl   $0x10bba8,0xc(%esp)
  10776c:	00 
  10776d:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107774:	00 
  107775:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
  10777c:	00 
  10777d:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107784:	e8 af 91 ff ff       	call   100938 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE, 0));
  107789:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10778c:	05 00 f0 bf 00       	add    $0xbff000,%eax
  107791:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  107798:	00 
  107799:	89 44 24 08          	mov    %eax,0x8(%esp)
  10779d:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1077a0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1077a4:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  1077ab:	e8 60 d7 ff ff       	call   104f10 <pmap_insert>
  1077b0:	85 c0                	test   %eax,%eax
  1077b2:	75 24                	jne    1077d8 <pmap_check+0x11f1>
  1077b4:	c7 44 24 0c e4 bb 10 	movl   $0x10bbe4,0xc(%esp)
  1077bb:	00 
  1077bc:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1077c3:	00 
  1077c4:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
  1077cb:	00 
  1077cc:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1077d3:	e8 60 91 ff ff       	call   100938 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE*2)])
  1077d8:	a1 08 a4 38 00       	mov    0x38a408,%eax
  1077dd:	89 c1                	mov    %eax,%ecx
  1077df:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  1077e5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1077e8:	a1 50 8f 38 00       	mov    0x388f50,%eax
  1077ed:	89 d3                	mov    %edx,%ebx
  1077ef:	29 c3                	sub    %eax,%ebx
  1077f1:	89 d8                	mov    %ebx,%eax
  1077f3:	c1 f8 03             	sar    $0x3,%eax
  1077f6:	c1 e0 0c             	shl    $0xc,%eax
  1077f9:	39 c1                	cmp    %eax,%ecx
  1077fb:	74 24                	je     107821 <pmap_check+0x123a>
  1077fd:	c7 44 24 0c 20 bc 10 	movl   $0x10bc20,0xc(%esp)
  107804:	00 
  107805:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  10780c:	00 
  10780d:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
  107814:	00 
  107815:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  10781c:	e8 17 91 ff ff       	call   100938 <debug_panic>
		== mem_pi2phys(pi3));
	assert(mem_freelist == NULL);
  107821:	a1 40 8f 38 00       	mov    0x388f40,%eax
  107826:	85 c0                	test   %eax,%eax
  107828:	74 24                	je     10784e <pmap_check+0x1267>
  10782a:	c7 44 24 0c 70 b9 10 	movl   $0x10b970,0xc(%esp)
  107831:	00 
  107832:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107839:	00 
  10783a:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
  107841:	00 
  107842:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107849:	e8 ea 90 ff ff       	call   100938 <debug_panic>
	assert(pi0->refcount == 10);
  10784e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107851:	8b 40 04             	mov    0x4(%eax),%eax
  107854:	83 f8 0a             	cmp    $0xa,%eax
  107857:	74 24                	je     10787d <pmap_check+0x1296>
  107859:	c7 44 24 0c 63 bc 10 	movl   $0x10bc63,0xc(%esp)
  107860:	00 
  107861:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107868:	00 
  107869:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
  107870:	00 
  107871:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107878:	e8 bb 90 ff ff       	call   100938 <debug_panic>
	assert(pi1->refcount == 1);
  10787d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107880:	8b 40 04             	mov    0x4(%eax),%eax
  107883:	83 f8 01             	cmp    $0x1,%eax
  107886:	74 24                	je     1078ac <pmap_check+0x12c5>
  107888:	c7 44 24 0c 5c b5 10 	movl   $0x10b55c,0xc(%esp)
  10788f:	00 
  107890:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107897:	00 
  107898:	c7 44 24 04 15 03 00 	movl   $0x315,0x4(%esp)
  10789f:	00 
  1078a0:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1078a7:	e8 8c 90 ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 1);
  1078ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1078af:	8b 40 04             	mov    0x4(%eax),%eax
  1078b2:	83 f8 01             	cmp    $0x1,%eax
  1078b5:	74 24                	je     1078db <pmap_check+0x12f4>
  1078b7:	c7 44 24 0c f9 b5 10 	movl   $0x10b5f9,0xc(%esp)
  1078be:	00 
  1078bf:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1078c6:	00 
  1078c7:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
  1078ce:	00 
  1078cf:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1078d6:	e8 5d 90 ff ff       	call   100938 <debug_panic>
	assert(pi3->refcount == 1);
  1078db:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1078de:	8b 40 04             	mov    0x4(%eax),%eax
  1078e1:	83 f8 01             	cmp    $0x1,%eax
  1078e4:	74 24                	je     10790a <pmap_check+0x1323>
  1078e6:	c7 44 24 0c 77 bc 10 	movl   $0x10bc77,0xc(%esp)
  1078ed:	00 
  1078ee:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1078f5:	00 
  1078f6:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
  1078fd:	00 
  1078fe:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107905:	e8 2e 90 ff ff       	call   100938 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3-PAGESIZE*2);
  10790a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10790d:	05 00 10 00 00       	add    $0x1000,%eax
  107912:	c7 44 24 08 00 e0 bf 	movl   $0xbfe000,0x8(%esp)
  107919:	00 
  10791a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10791e:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  107925:	e8 24 d8 ff ff       	call   10514e <pmap_remove>
	assert(pi0->refcount == 2);
  10792a:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10792d:	8b 40 04             	mov    0x4(%eax),%eax
  107930:	83 f8 02             	cmp    $0x2,%eax
  107933:	74 24                	je     107959 <pmap_check+0x1372>
  107935:	c7 44 24 0c 8a bc 10 	movl   $0x10bc8a,0xc(%esp)
  10793c:	00 
  10793d:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107944:	00 
  107945:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
  10794c:	00 
  10794d:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107954:	e8 df 8f ff ff       	call   100938 <debug_panic>
	assert(pi2->refcount == 0); assert(mem_alloc() == pi2);
  107959:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10795c:	8b 40 04             	mov    0x4(%eax),%eax
  10795f:	85 c0                	test   %eax,%eax
  107961:	74 24                	je     107987 <pmap_check+0x13a0>
  107963:	c7 44 24 0c 38 b8 10 	movl   $0x10b838,0xc(%esp)
  10796a:	00 
  10796b:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107972:	00 
  107973:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
  10797a:	00 
  10797b:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107982:	e8 b1 8f ff ff       	call   100938 <debug_panic>
  107987:	e8 3f 96 ff ff       	call   100fcb <mem_alloc>
  10798c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10798f:	74 24                	je     1079b5 <pmap_check+0x13ce>
  107991:	c7 44 24 0c 4b b8 10 	movl   $0x10b84b,0xc(%esp)
  107998:	00 
  107999:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1079a0:	00 
  1079a1:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
  1079a8:	00 
  1079a9:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1079b0:	e8 83 8f ff ff       	call   100938 <debug_panic>
	assert(mem_freelist == NULL);
  1079b5:	a1 40 8f 38 00       	mov    0x388f40,%eax
  1079ba:	85 c0                	test   %eax,%eax
  1079bc:	74 24                	je     1079e2 <pmap_check+0x13fb>
  1079be:	c7 44 24 0c 70 b9 10 	movl   $0x10b970,0xc(%esp)
  1079c5:	00 
  1079c6:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  1079cd:	00 
  1079ce:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
  1079d5:	00 
  1079d6:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  1079dd:	e8 56 8f ff ff       	call   100938 <debug_panic>
	pmap_remove(pmap_bootpdir, va, PTSIZE*3-PAGESIZE);
  1079e2:	c7 44 24 08 00 f0 bf 	movl   $0xbff000,0x8(%esp)
  1079e9:	00 
  1079ea:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1079ed:	89 44 24 04          	mov    %eax,0x4(%esp)
  1079f1:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  1079f8:	e8 51 d7 ff ff       	call   10514e <pmap_remove>
	assert(pi0->refcount == 1);
  1079fd:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107a00:	8b 40 04             	mov    0x4(%eax),%eax
  107a03:	83 f8 01             	cmp    $0x1,%eax
  107a06:	74 24                	je     107a2c <pmap_check+0x1445>
  107a08:	c7 44 24 0c 6f b5 10 	movl   $0x10b56f,0xc(%esp)
  107a0f:	00 
  107a10:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107a17:	00 
  107a18:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
  107a1f:	00 
  107a20:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107a27:	e8 0c 8f ff ff       	call   100938 <debug_panic>
	assert(pi1->refcount == 0); assert(mem_alloc() == pi1);
  107a2c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107a2f:	8b 40 04             	mov    0x4(%eax),%eax
  107a32:	85 c0                	test   %eax,%eax
  107a34:	74 24                	je     107a5a <pmap_check+0x1473>
  107a36:	c7 44 24 0c b7 b8 10 	movl   $0x10b8b7,0xc(%esp)
  107a3d:	00 
  107a3e:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107a45:	00 
  107a46:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
  107a4d:	00 
  107a4e:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107a55:	e8 de 8e ff ff       	call   100938 <debug_panic>
  107a5a:	e8 6c 95 ff ff       	call   100fcb <mem_alloc>
  107a5f:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  107a62:	74 24                	je     107a88 <pmap_check+0x14a1>
  107a64:	c7 44 24 0c ca b8 10 	movl   $0x10b8ca,0xc(%esp)
  107a6b:	00 
  107a6c:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107a73:	00 
  107a74:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
  107a7b:	00 
  107a7c:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107a83:	e8 b0 8e ff ff       	call   100938 <debug_panic>
	assert(mem_freelist == NULL);
  107a88:	a1 40 8f 38 00       	mov    0x388f40,%eax
  107a8d:	85 c0                	test   %eax,%eax
  107a8f:	74 24                	je     107ab5 <pmap_check+0x14ce>
  107a91:	c7 44 24 0c 70 b9 10 	movl   $0x10b970,0xc(%esp)
  107a98:	00 
  107a99:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107aa0:	00 
  107aa1:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
  107aa8:	00 
  107aa9:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107ab0:	e8 83 8e ff ff       	call   100938 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PTSIZE*3-PAGESIZE, PAGESIZE);
  107ab5:	8b 45 d8             	mov    -0x28(%ebp),%eax
  107ab8:	05 00 f0 bf 00       	add    $0xbff000,%eax
  107abd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  107ac4:	00 
  107ac5:	89 44 24 04          	mov    %eax,0x4(%esp)
  107ac9:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  107ad0:	e8 79 d6 ff ff       	call   10514e <pmap_remove>
	assert(pi0->refcount == 0);	// pi3 might or might not also be freed
  107ad5:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107ad8:	8b 40 04             	mov    0x4(%eax),%eax
  107adb:	85 c0                	test   %eax,%eax
  107add:	74 24                	je     107b03 <pmap_check+0x151c>
  107adf:	c7 44 24 0c 4a b9 10 	movl   $0x10b94a,0xc(%esp)
  107ae6:	00 
  107ae7:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107aee:	00 
  107aef:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
  107af6:	00 
  107af7:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107afe:	e8 35 8e ff ff       	call   100938 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3);
  107b03:	8b 45 d8             	mov    -0x28(%ebp),%eax
  107b06:	05 00 10 00 00       	add    $0x1000,%eax
  107b0b:	c7 44 24 08 00 00 c0 	movl   $0xc00000,0x8(%esp)
  107b12:	00 
  107b13:	89 44 24 04          	mov    %eax,0x4(%esp)
  107b17:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  107b1e:	e8 2b d6 ff ff       	call   10514e <pmap_remove>
	assert(pi3->refcount == 0);
  107b23:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  107b26:	8b 40 04             	mov    0x4(%eax),%eax
  107b29:	85 c0                	test   %eax,%eax
  107b2b:	74 24                	je     107b51 <pmap_check+0x156a>
  107b2d:	c7 44 24 0c 9d bc 10 	movl   $0x10bc9d,0xc(%esp)
  107b34:	00 
  107b35:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107b3c:	00 
  107b3d:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
  107b44:	00 
  107b45:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107b4c:	e8 e7 8d ff ff       	call   100938 <debug_panic>
	mem_alloc(); mem_alloc();	// collect pi0 and pi3
  107b51:	e8 75 94 ff ff       	call   100fcb <mem_alloc>
  107b56:	e8 70 94 ff ff       	call   100fcb <mem_alloc>
	assert(mem_freelist == NULL);
  107b5b:	a1 40 8f 38 00       	mov    0x388f40,%eax
  107b60:	85 c0                	test   %eax,%eax
  107b62:	74 24                	je     107b88 <pmap_check+0x15a1>
  107b64:	c7 44 24 0c 70 b9 10 	movl   $0x10b970,0xc(%esp)
  107b6b:	00 
  107b6c:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107b73:	00 
  107b74:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
  107b7b:	00 
  107b7c:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107b83:	e8 b0 8d ff ff       	call   100938 <debug_panic>

	// check pointer arithmetic in pmap_walk
	mem_free(pi0);
  107b88:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107b8b:	89 04 24             	mov    %eax,(%esp)
  107b8e:	e8 8a 94 ff ff       	call   10101d <mem_free>
	va = VM_USERLO + PAGESIZE*NPTENTRIES + PAGESIZE;
  107b93:	c7 45 d8 00 10 40 40 	movl   $0x40401000,-0x28(%ebp)
	ptep = pmap_walk(pmap_bootpdir, va, 1);
  107b9a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  107ba1:	00 
  107ba2:	8b 45 d8             	mov    -0x28(%ebp),%eax
  107ba5:	89 44 24 04          	mov    %eax,0x4(%esp)
  107ba9:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  107bb0:	e8 1a d1 ff ff       	call   104ccf <pmap_walk>
  107bb5:	89 45 dc             	mov    %eax,-0x24(%ebp)
	ptep1 = mem_ptr(PGADDR(pmap_bootpdir[PDX(va)]));
  107bb8:	8b 45 d8             	mov    -0x28(%ebp),%eax
  107bbb:	c1 e8 16             	shr    $0x16,%eax
  107bbe:	8b 04 85 00 a0 38 00 	mov    0x38a000(,%eax,4),%eax
  107bc5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107bca:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	assert(ptep == ptep1 + PTX(va));
  107bcd:	8b 45 d8             	mov    -0x28(%ebp),%eax
  107bd0:	c1 e8 0c             	shr    $0xc,%eax
  107bd3:	25 ff 03 00 00       	and    $0x3ff,%eax
  107bd8:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  107bdf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  107be2:	01 d0                	add    %edx,%eax
  107be4:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  107be7:	74 24                	je     107c0d <pmap_check+0x1626>
  107be9:	c7 44 24 0c b0 bc 10 	movl   $0x10bcb0,0xc(%esp)
  107bf0:	00 
  107bf1:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107bf8:	00 
  107bf9:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
  107c00:	00 
  107c01:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107c08:	e8 2b 8d ff ff       	call   100938 <debug_panic>
	pmap_bootpdir[PDX(va)] = PTE_ZERO;
  107c0d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  107c10:	89 c2                	mov    %eax,%edx
  107c12:	c1 ea 16             	shr    $0x16,%edx
  107c15:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  107c1a:	89 04 95 00 a0 38 00 	mov    %eax,0x38a000(,%edx,4)
	pi0->refcount = 0;
  107c21:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107c24:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

	// check that new page tables get cleared
	memset(mem_pi2ptr(pi0), 0xFF, PAGESIZE);
  107c2b:	8b 55 e8             	mov    -0x18(%ebp),%edx
  107c2e:	a1 50 8f 38 00       	mov    0x388f50,%eax
  107c33:	89 d1                	mov    %edx,%ecx
  107c35:	29 c1                	sub    %eax,%ecx
  107c37:	89 c8                	mov    %ecx,%eax
  107c39:	c1 f8 03             	sar    $0x3,%eax
  107c3c:	c1 e0 0c             	shl    $0xc,%eax
  107c3f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  107c46:	00 
  107c47:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  107c4e:	00 
  107c4f:	89 04 24             	mov    %eax,(%esp)
  107c52:	e8 ea 1f 00 00       	call   109c41 <memset>
	mem_free(pi0);
  107c57:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107c5a:	89 04 24             	mov    %eax,(%esp)
  107c5d:	e8 bb 93 ff ff       	call   10101d <mem_free>
	pmap_walk(pmap_bootpdir, VM_USERHI-PAGESIZE, 1);
  107c62:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  107c69:	00 
  107c6a:	c7 44 24 04 00 f0 ff 	movl   $0xeffff000,0x4(%esp)
  107c71:	ef 
  107c72:	c7 04 24 00 a0 38 00 	movl   $0x38a000,(%esp)
  107c79:	e8 51 d0 ff ff       	call   104ccf <pmap_walk>
	ptep = mem_pi2ptr(pi0);
  107c7e:	8b 55 e8             	mov    -0x18(%ebp),%edx
  107c81:	a1 50 8f 38 00       	mov    0x388f50,%eax
  107c86:	89 d3                	mov    %edx,%ebx
  107c88:	29 c3                	sub    %eax,%ebx
  107c8a:	89 d8                	mov    %ebx,%eax
  107c8c:	c1 f8 03             	sar    $0x3,%eax
  107c8f:	c1 e0 0c             	shl    $0xc,%eax
  107c92:	89 45 dc             	mov    %eax,-0x24(%ebp)
	for(i=0; i<NPTENTRIES; i++)
  107c95:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  107c9c:	eb 42                	jmp    107ce0 <pmap_check+0x16f9>
		assert(ptep[i] == PTE_ZERO);
  107c9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  107ca1:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
  107ca8:	8b 45 dc             	mov    -0x24(%ebp),%eax
  107cab:	01 d0                	add    %edx,%eax
  107cad:	8b 10                	mov    (%eax),%edx
  107caf:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  107cb4:	39 c2                	cmp    %eax,%edx
  107cb6:	74 24                	je     107cdc <pmap_check+0x16f5>
  107cb8:	c7 44 24 0c c8 bc 10 	movl   $0x10bcc8,0xc(%esp)
  107cbf:	00 
  107cc0:	c7 44 24 08 46 b1 10 	movl   $0x10b146,0x8(%esp)
  107cc7:	00 
  107cc8:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
  107ccf:	00 
  107cd0:	c7 04 24 2e b2 10 00 	movl   $0x10b22e,(%esp)
  107cd7:	e8 5c 8c ff ff       	call   100938 <debug_panic>
	// check that new page tables get cleared
	memset(mem_pi2ptr(pi0), 0xFF, PAGESIZE);
	mem_free(pi0);
	pmap_walk(pmap_bootpdir, VM_USERHI-PAGESIZE, 1);
	ptep = mem_pi2ptr(pi0);
	for(i=0; i<NPTENTRIES; i++)
  107cdc:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  107ce0:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
  107ce7:	7e b5                	jle    107c9e <pmap_check+0x16b7>
		assert(ptep[i] == PTE_ZERO);
	pmap_bootpdir[PDX(VM_USERHI-PAGESIZE)] = PTE_ZERO;
  107ce9:	b8 00 b0 38 00       	mov    $0x38b000,%eax
  107cee:	a3 fc ae 38 00       	mov    %eax,0x38aefc
	pi0->refcount = 0;
  107cf3:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107cf6:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

	// give free list back
	mem_freelist = fl;
  107cfd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  107d00:	a3 40 8f 38 00       	mov    %eax,0x388f40

	// free the pages we filched
	mem_free(pi0);
  107d05:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107d08:	89 04 24             	mov    %eax,(%esp)
  107d0b:	e8 0d 93 ff ff       	call   10101d <mem_free>
	mem_free(pi1);
  107d10:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107d13:	89 04 24             	mov    %eax,(%esp)
  107d16:	e8 02 93 ff ff       	call   10101d <mem_free>
	mem_free(pi2);
  107d1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107d1e:	89 04 24             	mov    %eax,(%esp)
  107d21:	e8 f7 92 ff ff       	call   10101d <mem_free>
	mem_free(pi3);
  107d26:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  107d29:	89 04 24             	mov    %eax,(%esp)
  107d2c:	e8 ec 92 ff ff       	call   10101d <mem_free>

	cprintf("pmap_check() succeeded!\n");
  107d31:	c7 04 24 dc bc 10 00 	movl   $0x10bcdc,(%esp)
  107d38:	e8 93 1b 00 00       	call   1098d0 <cprintf>
}
  107d3d:	83 c4 44             	add    $0x44,%esp
  107d40:	5b                   	pop    %ebx
  107d41:	5d                   	pop    %ebp
  107d42:	c3                   	ret    
  107d43:	90                   	nop

00107d44 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  107d44:	55                   	push   %ebp
  107d45:	89 e5                	mov    %esp,%ebp
  107d47:	53                   	push   %ebx
  107d48:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  107d4b:	89 e3                	mov    %esp,%ebx
  107d4d:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  107d50:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  107d53:	89 45 f4             	mov    %eax,-0xc(%ebp)
  107d56:	8b 45 f4             	mov    -0xc(%ebp),%eax
  107d59:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  107d5e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  107d61:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107d64:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  107d6a:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  107d6f:	74 24                	je     107d95 <cpu_cur+0x51>
  107d71:	c7 44 24 0c f8 bc 10 	movl   $0x10bcf8,0xc(%esp)
  107d78:	00 
  107d79:	c7 44 24 08 0e bd 10 	movl   $0x10bd0e,0x8(%esp)
  107d80:	00 
  107d81:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  107d88:	00 
  107d89:	c7 04 24 23 bd 10 00 	movl   $0x10bd23,(%esp)
  107d90:	e8 a3 8b ff ff       	call   100938 <debug_panic>
	return c;
  107d95:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  107d98:	83 c4 24             	add    $0x24,%esp
  107d9b:	5b                   	pop    %ebx
  107d9c:	5d                   	pop    %ebp
  107d9d:	c3                   	ret    

00107d9e <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  107d9e:	55                   	push   %ebp
  107d9f:	89 e5                	mov    %esp,%ebp
  107da1:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  107da4:	e8 9b ff ff ff       	call   107d44 <cpu_cur>
  107da9:	3d 00 f0 10 00       	cmp    $0x10f000,%eax
  107dae:	0f 94 c0             	sete   %al
  107db1:	0f b6 c0             	movzbl %al,%eax
}
  107db4:	c9                   	leave  
  107db5:	c3                   	ret    

00107db6 <file_init>:



void
file_init(void)
{
  107db6:	55                   	push   %ebp
  107db7:	89 e5                	mov    %esp,%ebp
  107db9:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())
  107dbc:	e8 dd ff ff ff       	call   107d9e <cpu_onboot>
  107dc1:	85 c0                	test   %eax,%eax
  107dc3:	74 1e                	je     107de3 <file_init+0x2d>
		return;

	spinlock_init(&file_lock);
  107dc5:	c7 44 24 08 3b 00 00 	movl   $0x3b,0x8(%esp)
  107dcc:	00 
  107dcd:	c7 44 24 04 54 bd 10 	movl   $0x10bd54,0x4(%esp)
  107dd4:	00 
  107dd5:	c7 04 24 a0 8e 18 00 	movl   $0x188ea0,(%esp)
  107ddc:	e8 e6 ab ff ff       	call   1029c7 <spinlock_init_>
  107de1:	eb 01                	jmp    107de4 <file_init+0x2e>

void
file_init(void)
{
	if (!cpu_onboot())
		return;
  107de3:	90                   	nop

	spinlock_init(&file_lock);
}
  107de4:	c9                   	leave  
  107de5:	c3                   	ret    

00107de6 <file_initroot>:

void
file_initroot(proc *root)
{
  107de6:	55                   	push   %ebp
  107de7:	89 e5                	mov    %esp,%ebp
  107de9:	56                   	push   %esi
  107dea:	53                   	push   %ebx
  107deb:	83 ec 30             	sub    $0x30,%esp
	// Only one root process may perform external I/O directly -
	// all other processes do I/O indirectly via the process hierarchy.
	assert(root == proc_root);
  107dee:	a1 90 96 38 00       	mov    0x389690,%eax
  107df3:	39 45 08             	cmp    %eax,0x8(%ebp)
  107df6:	74 24                	je     107e1c <file_initroot+0x36>
  107df8:	c7 44 24 0c 60 bd 10 	movl   $0x10bd60,0xc(%esp)
  107dff:	00 
  107e00:	c7 44 24 08 0e bd 10 	movl   $0x10bd0e,0x8(%esp)
  107e07:	00 
  107e08:	c7 44 24 04 43 00 00 	movl   $0x43,0x4(%esp)
  107e0f:	00 
  107e10:	c7 04 24 54 bd 10 00 	movl   $0x10bd54,(%esp)
  107e17:	e8 1c 8b ff ff       	call   100938 <debug_panic>
	int i = 0;
  107e1c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	// Make sure the root process's page directory is loaded,
	// so that we can write into the root process's file area directly.
	cpu_cur()->proc = root;
  107e23:	e8 1c ff ff ff       	call   107d44 <cpu_cur>
  107e28:	8b 55 08             	mov    0x8(%ebp),%edx
  107e2b:	89 90 b4 00 00 00    	mov    %edx,0xb4(%eax)
	lcr3(mem_phys(root->pdir));
  107e31:	8b 45 08             	mov    0x8(%ebp),%eax
  107e34:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  107e3a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  107e3d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  107e40:	0f 22 d8             	mov    %eax,%cr3

	// Enable read/write access on the file metadata area
	pmap_setperm(root->pdir, FILESVA, ROUNDUP(sizeof(filestate), PAGESIZE),
  107e43:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
  107e4a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107e4d:	05 0f 70 00 00       	add    $0x700f,%eax
  107e52:	89 45 ec             	mov    %eax,-0x14(%ebp)
  107e55:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107e58:	ba 00 00 00 00       	mov    $0x0,%edx
  107e5d:	f7 75 f0             	divl   -0x10(%ebp)
  107e60:	89 d0                	mov    %edx,%eax
  107e62:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107e65:	89 d1                	mov    %edx,%ecx
  107e67:	29 c1                	sub    %eax,%ecx
  107e69:	89 c8                	mov    %ecx,%eax
  107e6b:	89 c2                	mov    %eax,%edx
  107e6d:	8b 45 08             	mov    0x8(%ebp),%eax
  107e70:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  107e76:	c7 44 24 0c 00 06 00 	movl   $0x600,0xc(%esp)
  107e7d:	00 
  107e7e:	89 54 24 08          	mov    %edx,0x8(%esp)
  107e82:	c7 44 24 04 00 00 00 	movl   $0x80000000,0x4(%esp)
  107e89:	80 
  107e8a:	89 04 24             	mov    %eax,(%esp)
  107e8d:	e8 c0 e4 ff ff       	call   106352 <pmap_setperm>
				SYS_READ | SYS_WRITE);
	memset(files, 0, sizeof(*files));
  107e92:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  107e97:	c7 44 24 08 10 70 00 	movl   $0x7010,0x8(%esp)
  107e9e:	00 
  107e9f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  107ea6:	00 
  107ea7:	89 04 24             	mov    %eax,(%esp)
  107eaa:	e8 92 1d 00 00       	call   109c41 <memset>

	// Set up the standard I/O descriptors for console I/O
	files->fd[0].ino = FILEINO_CONSIN;
  107eaf:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  107eb4:	c7 40 10 01 00 00 00 	movl   $0x1,0x10(%eax)
	files->fd[0].flags = O_RDONLY;
  107ebb:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  107ec0:	c7 40 14 01 00 00 00 	movl   $0x1,0x14(%eax)
	files->fd[1].ino = FILEINO_CONSOUT;
  107ec7:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  107ecc:	c7 40 20 02 00 00 00 	movl   $0x2,0x20(%eax)
	files->fd[1].flags = O_WRONLY | O_APPEND;
  107ed3:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  107ed8:	c7 40 24 12 00 00 00 	movl   $0x12,0x24(%eax)
	files->fd[2].ino = FILEINO_CONSOUT;
  107edf:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  107ee4:	c7 40 30 02 00 00 00 	movl   $0x2,0x30(%eax)
	files->fd[2].flags = O_WRONLY | O_APPEND;
  107eeb:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  107ef0:	c7 40 34 12 00 00 00 	movl   $0x12,0x34(%eax)

	// Setup the inodes for the console I/O files and root directory
	strcpy(files->fi[FILEINO_CONSIN].de.d_name, "consin");
  107ef7:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  107efc:	05 70 10 00 00       	add    $0x1070,%eax
  107f01:	c7 44 24 04 72 bd 10 	movl   $0x10bd72,0x4(%esp)
  107f08:	00 
  107f09:	89 04 24             	mov    %eax,(%esp)
  107f0c:	e8 99 1b 00 00       	call   109aaa <strcpy>
	strcpy(files->fi[FILEINO_CONSOUT].de.d_name, "consout");
  107f11:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  107f16:	05 cc 10 00 00       	add    $0x10cc,%eax
  107f1b:	c7 44 24 04 79 bd 10 	movl   $0x10bd79,0x4(%esp)
  107f22:	00 
  107f23:	89 04 24             	mov    %eax,(%esp)
  107f26:	e8 7f 1b 00 00       	call   109aaa <strcpy>
	strcpy(files->fi[FILEINO_ROOTDIR].de.d_name, "/");
  107f2b:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  107f30:	05 28 11 00 00       	add    $0x1128,%eax
  107f35:	c7 44 24 04 81 bd 10 	movl   $0x10bd81,0x4(%esp)
  107f3c:	00 
  107f3d:	89 04 24             	mov    %eax,(%esp)
  107f40:	e8 65 1b 00 00       	call   109aaa <strcpy>
	files->fi[FILEINO_CONSIN].dino = FILEINO_ROOTDIR;
  107f45:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  107f4a:	c7 80 6c 10 00 00 03 	movl   $0x3,0x106c(%eax)
  107f51:	00 00 00 
	files->fi[FILEINO_CONSOUT].dino = FILEINO_ROOTDIR;
  107f54:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  107f59:	c7 80 c8 10 00 00 03 	movl   $0x3,0x10c8(%eax)
  107f60:	00 00 00 
	files->fi[FILEINO_ROOTDIR].dino = FILEINO_ROOTDIR;
  107f63:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  107f68:	c7 80 24 11 00 00 03 	movl   $0x3,0x1124(%eax)
  107f6f:	00 00 00 
	files->fi[FILEINO_CONSIN].mode = S_IFREG | S_IFPART;
  107f72:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  107f77:	c7 80 b4 10 00 00 00 	movl   $0x9000,0x10b4(%eax)
  107f7e:	90 00 00 
	files->fi[FILEINO_CONSOUT].mode = S_IFREG;
  107f81:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  107f86:	c7 80 10 11 00 00 00 	movl   $0x1000,0x1110(%eax)
  107f8d:	10 00 00 
	files->fi[FILEINO_ROOTDIR].mode = S_IFDIR;
  107f90:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  107f95:	c7 80 6c 11 00 00 00 	movl   $0x2000,0x116c(%eax)
  107f9c:	20 00 00 

	// Set the whole console input area to be read/write,
	// so we won't have to worry about perms in cons_io().
	pmap_setperm(root->pdir, (uintptr_t)FILEDATA(FILEINO_CONSIN),
  107f9f:	8b 45 08             	mov    0x8(%ebp),%eax
  107fa2:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  107fa8:	c7 44 24 0c 00 06 00 	movl   $0x600,0xc(%esp)
  107faf:	00 
  107fb0:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
  107fb7:	00 
  107fb8:	c7 44 24 04 00 00 40 	movl   $0x80400000,0x4(%esp)
  107fbf:	80 
  107fc0:	89 04 24             	mov    %eax,(%esp)
  107fc3:	e8 8a e3 ff ff       	call   106352 <pmap_setperm>
				PTSIZE, SYS_READ | SYS_WRITE);
	pmap_setperm(root->pdir, (uintptr_t)FILEDATA(FILEINO_CONSOUT),
  107fc8:	8b 45 08             	mov    0x8(%ebp),%eax
  107fcb:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  107fd1:	c7 44 24 0c 00 06 00 	movl   $0x600,0xc(%esp)
  107fd8:	00 
  107fd9:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
  107fe0:	00 
  107fe1:	c7 44 24 04 00 00 80 	movl   $0x80800000,0x4(%esp)
  107fe8:	80 
  107fe9:	89 04 24             	mov    %eax,(%esp)
  107fec:	e8 61 e3 ff ff       	call   106352 <pmap_setperm>
	// For each initial file numbered 0 <= i < ninitfiles,
	// initfiles[i][0] is a pointer to the filename string for that file,
	// initfiles[i][1] is a pointer to the start of the file's content, and
	// initfiles[i][2] is a pointer to the end of the file's content
	// (i.e., a pointer to the first byte after the file's last byte).
	int ninitfiles = sizeof(initfiles)/sizeof(initfiles[0]);
  107ff1:	c7 45 e8 07 00 00 00 	movl   $0x7,-0x18(%ebp)
	// Lab 4: your file system initialization code here.
	//warn("file_initroot: file system initialization not done\n");
	for(i; i < ninitfiles; i++){
  107ff8:	e9 3b 01 00 00       	jmp    108138 <file_initroot+0x352>
		strcpy(files->fi[i+4].de.d_name, initfiles[i][0]);
  107ffd:	8b 55 f4             	mov    -0xc(%ebp),%edx
  108000:	89 d0                	mov    %edx,%eax
  108002:	01 c0                	add    %eax,%eax
  108004:	01 d0                	add    %edx,%eax
  108006:	c1 e0 02             	shl    $0x2,%eax
  108009:	05 20 01 11 00       	add    $0x110120,%eax
  10800e:	8b 00                	mov    (%eax),%eax
  108010:	8b 15 50 bd 10 00    	mov    0x10bd50,%edx
  108016:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  108019:	83 c1 04             	add    $0x4,%ecx
  10801c:	6b c9 5c             	imul   $0x5c,%ecx,%ecx
  10801f:	81 c1 10 10 00 00    	add    $0x1010,%ecx
  108025:	01 ca                	add    %ecx,%edx
  108027:	83 c2 04             	add    $0x4,%edx
  10802a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10802e:	89 14 24             	mov    %edx,(%esp)
  108031:	e8 74 1a 00 00       	call   109aaa <strcpy>
		files->fi[i+4].dino = FILEINO_ROOTDIR;
  108036:	8b 15 50 bd 10 00    	mov    0x10bd50,%edx
  10803c:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10803f:	83 c0 04             	add    $0x4,%eax
  108042:	6b c0 5c             	imul   $0x5c,%eax,%eax
  108045:	01 d0                	add    %edx,%eax
  108047:	05 10 10 00 00       	add    $0x1010,%eax
  10804c:	c7 00 03 00 00 00    	movl   $0x3,(%eax)
		files->fi[i+4].mode =  S_IFREG;
  108052:	8b 15 50 bd 10 00    	mov    0x10bd50,%edx
  108058:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10805b:	83 c0 04             	add    $0x4,%eax
  10805e:	6b c0 5c             	imul   $0x5c,%eax,%eax
  108061:	01 d0                	add    %edx,%eax
  108063:	05 58 10 00 00       	add    $0x1058,%eax
  108068:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
		files->fi[i+4].size = initfiles[i][2] - initfiles[i][1];
  10806e:	8b 0d 50 bd 10 00    	mov    0x10bd50,%ecx
  108074:	8b 45 f4             	mov    -0xc(%ebp),%eax
  108077:	8d 70 04             	lea    0x4(%eax),%esi
  10807a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10807d:	89 d0                	mov    %edx,%eax
  10807f:	01 c0                	add    %eax,%eax
  108081:	01 d0                	add    %edx,%eax
  108083:	c1 e0 02             	shl    $0x2,%eax
  108086:	05 28 01 11 00       	add    $0x110128,%eax
  10808b:	8b 00                	mov    (%eax),%eax
  10808d:	89 c3                	mov    %eax,%ebx
  10808f:	8b 55 f4             	mov    -0xc(%ebp),%edx
  108092:	89 d0                	mov    %edx,%eax
  108094:	01 c0                	add    %eax,%eax
  108096:	01 d0                	add    %edx,%eax
  108098:	c1 e0 02             	shl    $0x2,%eax
  10809b:	05 24 01 11 00       	add    $0x110124,%eax
  1080a0:	8b 00                	mov    (%eax),%eax
  1080a2:	89 da                	mov    %ebx,%edx
  1080a4:	29 c2                	sub    %eax,%edx
  1080a6:	89 d0                	mov    %edx,%eax
  1080a8:	6b d6 5c             	imul   $0x5c,%esi,%edx
  1080ab:	01 ca                	add    %ecx,%edx
  1080ad:	81 c2 5c 10 00 00    	add    $0x105c,%edx
  1080b3:	89 02                	mov    %eax,(%edx)
		pmap_setperm(root->pdir, (uintptr_t)FILEDATA(i+4),
  1080b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1080b8:	83 c0 04             	add    $0x4,%eax
  1080bb:	c1 e0 16             	shl    $0x16,%eax
  1080be:	05 00 00 00 80       	add    $0x80000000,%eax
  1080c3:	89 c2                	mov    %eax,%edx
  1080c5:	8b 45 08             	mov    0x8(%ebp),%eax
  1080c8:	8b 80 00 07 00 00    	mov    0x700(%eax),%eax
  1080ce:	c7 44 24 0c 00 06 00 	movl   $0x600,0xc(%esp)
  1080d5:	00 
  1080d6:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
  1080dd:	00 
  1080de:	89 54 24 04          	mov    %edx,0x4(%esp)
  1080e2:	89 04 24             	mov    %eax,(%esp)
  1080e5:	e8 68 e2 ff ff       	call   106352 <pmap_setperm>
				PTSIZE, SYS_READ | SYS_WRITE);
		memcpy((void*)FILEDATA(i + 4), initfiles[i][1], files->fi[i+4].size);
  1080ea:	8b 15 50 bd 10 00    	mov    0x10bd50,%edx
  1080f0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1080f3:	83 c0 04             	add    $0x4,%eax
  1080f6:	6b c0 5c             	imul   $0x5c,%eax,%eax
  1080f9:	01 d0                	add    %edx,%eax
  1080fb:	05 5c 10 00 00       	add    $0x105c,%eax
  108100:	8b 08                	mov    (%eax),%ecx
  108102:	8b 55 f4             	mov    -0xc(%ebp),%edx
  108105:	89 d0                	mov    %edx,%eax
  108107:	01 c0                	add    %eax,%eax
  108109:	01 d0                	add    %edx,%eax
  10810b:	c1 e0 02             	shl    $0x2,%eax
  10810e:	05 24 01 11 00       	add    $0x110124,%eax
  108113:	8b 00                	mov    (%eax),%eax
  108115:	8b 55 f4             	mov    -0xc(%ebp),%edx
  108118:	83 c2 04             	add    $0x4,%edx
  10811b:	c1 e2 16             	shl    $0x16,%edx
  10811e:	81 c2 00 00 00 80    	add    $0x80000000,%edx
  108124:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  108128:	89 44 24 04          	mov    %eax,0x4(%esp)
  10812c:	89 14 24             	mov    %edx,(%esp)
  10812f:	e8 55 1c 00 00       	call   109d89 <memcpy>
	// initfiles[i][2] is a pointer to the end of the file's content
	// (i.e., a pointer to the first byte after the file's last byte).
	int ninitfiles = sizeof(initfiles)/sizeof(initfiles[0]);
	// Lab 4: your file system initialization code here.
	//warn("file_initroot: file system initialization not done\n");
	for(i; i < ninitfiles; i++){
  108134:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  108138:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10813b:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  10813e:	0f 8c b9 fe ff ff    	jl     107ffd <file_initroot+0x217>
		pmap_setperm(root->pdir, (uintptr_t)FILEDATA(i+4),
				PTSIZE, SYS_READ | SYS_WRITE);
		memcpy((void*)FILEDATA(i + 4), initfiles[i][1], files->fi[i+4].size);
	}
	// Set root process's current working directory
	files->cwd = FILEINO_ROOTDIR;
  108144:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  108149:	c7 40 04 03 00 00 00 	movl   $0x3,0x4(%eax)

	// Child process state - reserve PID 0 as a "scratch" child process.
	files->child[0].state = PROC_RESERVED;
  108150:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  108155:	c7 80 10 6c 00 00 ff 	movl   $0xffffffff,0x6c10(%eax)
  10815c:	ff ff ff 
}
  10815f:	83 c4 30             	add    $0x30,%esp
  108162:	5b                   	pop    %ebx
  108163:	5e                   	pop    %esi
  108164:	5d                   	pop    %ebp
  108165:	c3                   	ret    

00108166 <file_io>:
// this function performs any new output the root process requested,
// or if it didn't request output, puts the root process to sleep
// waiting for input to arrive from some I/O device.
void
file_io(trapframe *tf)
{
  108166:	55                   	push   %ebp
  108167:	89 e5                	mov    %esp,%ebp
  108169:	83 ec 28             	sub    $0x28,%esp
	proc *cp = proc_cur();
  10816c:	e8 d3 fb ff ff       	call   107d44 <cpu_cur>
  108171:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  108177:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert(cp == proc_root);	// only root process should do this!
  10817a:	a1 90 96 38 00       	mov    0x389690,%eax
  10817f:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  108182:	74 24                	je     1081a8 <file_io+0x42>
  108184:	c7 44 24 0c 83 bd 10 	movl   $0x10bd83,0xc(%esp)
  10818b:	00 
  10818c:	c7 44 24 08 0e bd 10 	movl   $0x10bd0e,0x8(%esp)
  108193:	00 
  108194:	c7 44 24 04 8c 00 00 	movl   $0x8c,0x4(%esp)
  10819b:	00 
  10819c:	c7 04 24 54 bd 10 00 	movl   $0x10bd54,(%esp)
  1081a3:	e8 90 87 ff ff       	call   100938 <debug_panic>
	// the whole system goes down anyway if the root process goes haywire.
	// This is very different from handling system calls
	// on behalf of arbitrary processes that might be buggy or evil.

	// Perform I/O with whatever devices we have access to.
	bool iodone = 0;
  1081a8:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
	iodone |= cons_io();
  1081af:	e8 c0 85 ff ff       	call   100774 <cons_io>
  1081b4:	09 45 f0             	or     %eax,-0x10(%ebp)
	//cprintf("in file io, iodone: %d.\n", iodone);
	// Has the root process exited?
	if (files->exited) {
  1081b7:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  1081bc:	8b 40 08             	mov    0x8(%eax),%eax
  1081bf:	85 c0                	test   %eax,%eax
  1081c1:	74 1d                	je     1081e0 <file_io+0x7a>
		cprintf("root process exited with status %d\n", files->status);
  1081c3:	a1 50 bd 10 00       	mov    0x10bd50,%eax
  1081c8:	8b 40 0c             	mov    0xc(%eax),%eax
  1081cb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1081cf:	c7 04 24 94 bd 10 00 	movl   $0x10bd94,(%esp)
  1081d6:	e8 f5 16 00 00       	call   1098d0 <cprintf>
		done();
  1081db:	e8 82 80 ff ff       	call   100262 <done>
	}

	// We successfully did some I/O, let the root process run again.
	if (iodone)
  1081e0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1081e4:	74 0b                	je     1081f1 <file_io+0x8b>
		trap_return(tf);
  1081e6:	8b 45 08             	mov    0x8(%ebp),%eax
  1081e9:	89 04 24             	mov    %eax,(%esp)
  1081ec:	e8 0f 7f 00 00       	call   110100 <trap_return>

	// No I/O ready - put the root process to sleep waiting for I/O.
	spinlock_acquire(&file_lock);
  1081f1:	c7 04 24 a0 8e 18 00 	movl   $0x188ea0,(%esp)
  1081f8:	e8 f4 a7 ff ff       	call   1029f1 <spinlock_acquire>
	cp->state = PROC_STOP;		// we're becoming stopped
  1081fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  108200:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  108207:	00 00 00 
	cp->runcpu = NULL;		// no longer running
  10820a:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10820d:	c7 80 44 04 00 00 00 	movl   $0x0,0x444(%eax)
  108214:	00 00 00 
	proc_save(cp, tf, 1);		// save process's state
  108217:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  10821e:	00 
  10821f:	8b 45 08             	mov    0x8(%ebp),%eax
  108222:	89 44 24 04          	mov    %eax,0x4(%esp)
  108226:	8b 45 f4             	mov    -0xc(%ebp),%eax
  108229:	89 04 24             	mov    %eax,(%esp)
  10822c:	e8 5c b1 ff ff       	call   10338d <proc_save>
	spinlock_release(&file_lock);
  108231:	c7 04 24 a0 8e 18 00 	movl   $0x188ea0,(%esp)
  108238:	e8 29 a8 ff ff       	call   102a66 <spinlock_release>

	proc_sched();			// go do something else
  10823d:	e8 20 b2 ff ff       	call   103462 <proc_sched>

00108242 <file_wakeroot>:

// Check to see if any input is available for the root process
// and if the root process is waiting for it, and if so, wake the process.
void
file_wakeroot(void)
{
  108242:	55                   	push   %ebp
  108243:	89 e5                	mov    %esp,%ebp
  108245:	83 ec 18             	sub    $0x18,%esp
	spinlock_acquire(&file_lock);
  108248:	c7 04 24 a0 8e 18 00 	movl   $0x188ea0,(%esp)
  10824f:	e8 9d a7 ff ff       	call   1029f1 <spinlock_acquire>
	if (proc_root && proc_root->state == PROC_STOP)
  108254:	a1 90 96 38 00       	mov    0x389690,%eax
  108259:	85 c0                	test   %eax,%eax
  10825b:	74 1c                	je     108279 <file_wakeroot+0x37>
  10825d:	a1 90 96 38 00       	mov    0x389690,%eax
  108262:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  108268:	85 c0                	test   %eax,%eax
  10826a:	75 0d                	jne    108279 <file_wakeroot+0x37>
		proc_ready(proc_root);
  10826c:	a1 90 96 38 00       	mov    0x389690,%eax
  108271:	89 04 24             	mov    %eax,(%esp)
  108274:	e8 56 b0 ff ff       	call   1032cf <proc_ready>
	spinlock_release(&file_lock);
  108279:	c7 04 24 a0 8e 18 00 	movl   $0x188ea0,(%esp)
  108280:	e8 e1 a7 ff ff       	call   102a66 <spinlock_release>
}
  108285:	c9                   	leave  
  108286:	c3                   	ret    
  108287:	90                   	nop

00108288 <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  108288:	55                   	push   %ebp
  108289:	89 e5                	mov    %esp,%ebp
  10828b:	53                   	push   %ebx
  10828c:	83 ec 34             	sub    $0x34,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  10828f:	c7 45 f8 00 80 0b 00 	movl   $0xb8000,-0x8(%ebp)
	was = *cp;
  108296:	8b 45 f8             	mov    -0x8(%ebp),%eax
  108299:	0f b7 00             	movzwl (%eax),%eax
  10829c:	66 89 45 f6          	mov    %ax,-0xa(%ebp)
	*cp = (uint16_t) 0xA55A;
  1082a0:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1082a3:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  1082a8:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1082ab:	0f b7 00             	movzwl (%eax),%eax
  1082ae:	66 3d 5a a5          	cmp    $0xa55a,%ax
  1082b2:	74 13                	je     1082c7 <video_init+0x3f>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  1082b4:	c7 45 f8 00 00 0b 00 	movl   $0xb0000,-0x8(%ebp)
		addr_6845 = MONO_BASE;
  1082bb:	c7 05 dc 8e 18 00 b4 	movl   $0x3b4,0x188edc
  1082c2:	03 00 00 
  1082c5:	eb 14                	jmp    1082db <video_init+0x53>
	} else {
		*cp = was;
  1082c7:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1082ca:	0f b7 55 f6          	movzwl -0xa(%ebp),%edx
  1082ce:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  1082d1:	c7 05 dc 8e 18 00 d4 	movl   $0x3d4,0x188edc
  1082d8:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  1082db:	a1 dc 8e 18 00       	mov    0x188edc,%eax
  1082e0:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1082e3:	c6 45 eb 0e          	movb   $0xe,-0x15(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1082e7:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  1082eb:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1082ee:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  1082ef:	a1 dc 8e 18 00       	mov    0x188edc,%eax
  1082f4:	83 c0 01             	add    $0x1,%eax
  1082f7:	89 45 e4             	mov    %eax,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1082fa:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1082fd:	89 55 c8             	mov    %edx,-0x38(%ebp)
  108300:	8b 55 c8             	mov    -0x38(%ebp),%edx
  108303:	ec                   	in     (%dx),%al
  108304:	89 c3                	mov    %eax,%ebx
  108306:	88 5d e3             	mov    %bl,-0x1d(%ebp)
	return data;
  108309:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  10830d:	0f b6 c0             	movzbl %al,%eax
  108310:	c1 e0 08             	shl    $0x8,%eax
  108313:	89 45 f0             	mov    %eax,-0x10(%ebp)
	outb(addr_6845, 15);
  108316:	a1 dc 8e 18 00       	mov    0x188edc,%eax
  10831b:	89 45 dc             	mov    %eax,-0x24(%ebp)
  10831e:	c6 45 db 0f          	movb   $0xf,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  108322:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  108326:	8b 55 dc             	mov    -0x24(%ebp),%edx
  108329:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  10832a:	a1 dc 8e 18 00       	mov    0x188edc,%eax
  10832f:	83 c0 01             	add    $0x1,%eax
  108332:	89 45 d4             	mov    %eax,-0x2c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  108335:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  108338:	89 55 c8             	mov    %edx,-0x38(%ebp)
  10833b:	8b 55 c8             	mov    -0x38(%ebp),%edx
  10833e:	ec                   	in     (%dx),%al
  10833f:	89 c3                	mov    %eax,%ebx
  108341:	88 5d d3             	mov    %bl,-0x2d(%ebp)
	return data;
  108344:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  108348:	0f b6 c0             	movzbl %al,%eax
  10834b:	09 45 f0             	or     %eax,-0x10(%ebp)

	crt_buf = (uint16_t*) cp;
  10834e:	8b 45 f8             	mov    -0x8(%ebp),%eax
  108351:	a3 e0 8e 18 00       	mov    %eax,0x188ee0
	crt_pos = pos;
  108356:	8b 45 f0             	mov    -0x10(%ebp),%eax
  108359:	66 a3 e4 8e 18 00    	mov    %ax,0x188ee4
}
  10835f:	83 c4 34             	add    $0x34,%esp
  108362:	5b                   	pop    %ebx
  108363:	5d                   	pop    %ebp
  108364:	c3                   	ret    

00108365 <video_putc>:



void
video_putc(int c)
{
  108365:	55                   	push   %ebp
  108366:	89 e5                	mov    %esp,%ebp
  108368:	53                   	push   %ebx
  108369:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  10836c:	8b 45 08             	mov    0x8(%ebp),%eax
  10836f:	b0 00                	mov    $0x0,%al
  108371:	85 c0                	test   %eax,%eax
  108373:	75 07                	jne    10837c <video_putc+0x17>
		c |= 0x0700;
  108375:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  10837c:	8b 45 08             	mov    0x8(%ebp),%eax
  10837f:	25 ff 00 00 00       	and    $0xff,%eax
  108384:	83 f8 09             	cmp    $0x9,%eax
  108387:	0f 84 ab 00 00 00    	je     108438 <video_putc+0xd3>
  10838d:	83 f8 09             	cmp    $0x9,%eax
  108390:	7f 0a                	jg     10839c <video_putc+0x37>
  108392:	83 f8 08             	cmp    $0x8,%eax
  108395:	74 14                	je     1083ab <video_putc+0x46>
  108397:	e9 da 00 00 00       	jmp    108476 <video_putc+0x111>
  10839c:	83 f8 0a             	cmp    $0xa,%eax
  10839f:	74 4d                	je     1083ee <video_putc+0x89>
  1083a1:	83 f8 0d             	cmp    $0xd,%eax
  1083a4:	74 58                	je     1083fe <video_putc+0x99>
  1083a6:	e9 cb 00 00 00       	jmp    108476 <video_putc+0x111>
	case '\b':
		if (crt_pos > 0) {
  1083ab:	0f b7 05 e4 8e 18 00 	movzwl 0x188ee4,%eax
  1083b2:	66 85 c0             	test   %ax,%ax
  1083b5:	0f 84 e0 00 00 00    	je     10849b <video_putc+0x136>
			crt_pos--;
  1083bb:	0f b7 05 e4 8e 18 00 	movzwl 0x188ee4,%eax
  1083c2:	83 e8 01             	sub    $0x1,%eax
  1083c5:	66 a3 e4 8e 18 00    	mov    %ax,0x188ee4
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  1083cb:	a1 e0 8e 18 00       	mov    0x188ee0,%eax
  1083d0:	0f b7 15 e4 8e 18 00 	movzwl 0x188ee4,%edx
  1083d7:	0f b7 d2             	movzwl %dx,%edx
  1083da:	01 d2                	add    %edx,%edx
  1083dc:	01 c2                	add    %eax,%edx
  1083de:	8b 45 08             	mov    0x8(%ebp),%eax
  1083e1:	b0 00                	mov    $0x0,%al
  1083e3:	83 c8 20             	or     $0x20,%eax
  1083e6:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  1083e9:	e9 ad 00 00 00       	jmp    10849b <video_putc+0x136>
	case '\n':
		crt_pos += CRT_COLS;
  1083ee:	0f b7 05 e4 8e 18 00 	movzwl 0x188ee4,%eax
  1083f5:	83 c0 50             	add    $0x50,%eax
  1083f8:	66 a3 e4 8e 18 00    	mov    %ax,0x188ee4
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  1083fe:	0f b7 1d e4 8e 18 00 	movzwl 0x188ee4,%ebx
  108405:	0f b7 0d e4 8e 18 00 	movzwl 0x188ee4,%ecx
  10840c:	0f b7 c1             	movzwl %cx,%eax
  10840f:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  108415:	c1 e8 10             	shr    $0x10,%eax
  108418:	89 c2                	mov    %eax,%edx
  10841a:	66 c1 ea 06          	shr    $0x6,%dx
  10841e:	89 d0                	mov    %edx,%eax
  108420:	c1 e0 02             	shl    $0x2,%eax
  108423:	01 d0                	add    %edx,%eax
  108425:	c1 e0 04             	shl    $0x4,%eax
  108428:	89 ca                	mov    %ecx,%edx
  10842a:	29 c2                	sub    %eax,%edx
  10842c:	89 d8                	mov    %ebx,%eax
  10842e:	29 d0                	sub    %edx,%eax
  108430:	66 a3 e4 8e 18 00    	mov    %ax,0x188ee4
		break;
  108436:	eb 64                	jmp    10849c <video_putc+0x137>
	case '\t':
		video_putc(' ');
  108438:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10843f:	e8 21 ff ff ff       	call   108365 <video_putc>
		video_putc(' ');
  108444:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10844b:	e8 15 ff ff ff       	call   108365 <video_putc>
		video_putc(' ');
  108450:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  108457:	e8 09 ff ff ff       	call   108365 <video_putc>
		video_putc(' ');
  10845c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  108463:	e8 fd fe ff ff       	call   108365 <video_putc>
		video_putc(' ');
  108468:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10846f:	e8 f1 fe ff ff       	call   108365 <video_putc>
		break;
  108474:	eb 26                	jmp    10849c <video_putc+0x137>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  108476:	8b 15 e0 8e 18 00    	mov    0x188ee0,%edx
  10847c:	0f b7 05 e4 8e 18 00 	movzwl 0x188ee4,%eax
  108483:	0f b7 c8             	movzwl %ax,%ecx
  108486:	01 c9                	add    %ecx,%ecx
  108488:	01 d1                	add    %edx,%ecx
  10848a:	8b 55 08             	mov    0x8(%ebp),%edx
  10848d:	66 89 11             	mov    %dx,(%ecx)
  108490:	83 c0 01             	add    $0x1,%eax
  108493:	66 a3 e4 8e 18 00    	mov    %ax,0x188ee4
		break;
  108499:	eb 01                	jmp    10849c <video_putc+0x137>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  10849b:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  10849c:	0f b7 05 e4 8e 18 00 	movzwl 0x188ee4,%eax
  1084a3:	66 3d cf 07          	cmp    $0x7cf,%ax
  1084a7:	76 5b                	jbe    108504 <video_putc+0x19f>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  1084a9:	a1 e0 8e 18 00       	mov    0x188ee0,%eax
  1084ae:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  1084b4:	a1 e0 8e 18 00       	mov    0x188ee0,%eax
  1084b9:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  1084c0:	00 
  1084c1:	89 54 24 04          	mov    %edx,0x4(%esp)
  1084c5:	89 04 24             	mov    %eax,(%esp)
  1084c8:	e8 e2 17 00 00       	call   109caf <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  1084cd:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
  1084d4:	eb 15                	jmp    1084eb <video_putc+0x186>
			crt_buf[i] = 0x0700 | ' ';
  1084d6:	a1 e0 8e 18 00       	mov    0x188ee0,%eax
  1084db:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1084de:	01 d2                	add    %edx,%edx
  1084e0:	01 d0                	add    %edx,%eax
  1084e2:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  1084e7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1084eb:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
  1084f2:	7e e2                	jle    1084d6 <video_putc+0x171>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  1084f4:	0f b7 05 e4 8e 18 00 	movzwl 0x188ee4,%eax
  1084fb:	83 e8 50             	sub    $0x50,%eax
  1084fe:	66 a3 e4 8e 18 00    	mov    %ax,0x188ee4
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  108504:	a1 dc 8e 18 00       	mov    0x188edc,%eax
  108509:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10850c:	c6 45 ef 0e          	movb   $0xe,-0x11(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  108510:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
  108514:	8b 55 f0             	mov    -0x10(%ebp),%edx
  108517:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  108518:	0f b7 05 e4 8e 18 00 	movzwl 0x188ee4,%eax
  10851f:	66 c1 e8 08          	shr    $0x8,%ax
  108523:	0f b6 c0             	movzbl %al,%eax
  108526:	8b 15 dc 8e 18 00    	mov    0x188edc,%edx
  10852c:	83 c2 01             	add    $0x1,%edx
  10852f:	89 55 e8             	mov    %edx,-0x18(%ebp)
  108532:	88 45 e7             	mov    %al,-0x19(%ebp)
  108535:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  108539:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10853c:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  10853d:	a1 dc 8e 18 00       	mov    0x188edc,%eax
  108542:	89 45 e0             	mov    %eax,-0x20(%ebp)
  108545:	c6 45 df 0f          	movb   $0xf,-0x21(%ebp)
  108549:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
  10854d:	8b 55 e0             	mov    -0x20(%ebp),%edx
  108550:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  108551:	0f b7 05 e4 8e 18 00 	movzwl 0x188ee4,%eax
  108558:	0f b6 c0             	movzbl %al,%eax
  10855b:	8b 15 dc 8e 18 00    	mov    0x188edc,%edx
  108561:	83 c2 01             	add    $0x1,%edx
  108564:	89 55 d8             	mov    %edx,-0x28(%ebp)
  108567:	88 45 d7             	mov    %al,-0x29(%ebp)
  10856a:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
  10856e:	8b 55 d8             	mov    -0x28(%ebp),%edx
  108571:	ee                   	out    %al,(%dx)
}
  108572:	83 c4 44             	add    $0x44,%esp
  108575:	5b                   	pop    %ebx
  108576:	5d                   	pop    %ebp
  108577:	c3                   	ret    

00108578 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  108578:	55                   	push   %ebp
  108579:	89 e5                	mov    %esp,%ebp
  10857b:	53                   	push   %ebx
  10857c:	83 ec 44             	sub    $0x44,%esp
  10857f:	c7 45 ec 64 00 00 00 	movl   $0x64,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  108586:	8b 55 ec             	mov    -0x14(%ebp),%edx
  108589:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  10858c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10858f:	ec                   	in     (%dx),%al
  108590:	89 c3                	mov    %eax,%ebx
  108592:	88 5d eb             	mov    %bl,-0x15(%ebp)
	return data;
  108595:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  108599:	0f b6 c0             	movzbl %al,%eax
  10859c:	83 e0 01             	and    $0x1,%eax
  10859f:	85 c0                	test   %eax,%eax
  1085a1:	75 0a                	jne    1085ad <kbd_proc_data+0x35>
		return -1;
  1085a3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1085a8:	e9 5f 01 00 00       	jmp    10870c <kbd_proc_data+0x194>
  1085ad:	c7 45 e4 60 00 00 00 	movl   $0x60,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1085b4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1085b7:	89 55 d4             	mov    %edx,-0x2c(%ebp)
  1085ba:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1085bd:	ec                   	in     (%dx),%al
  1085be:	89 c3                	mov    %eax,%ebx
  1085c0:	88 5d e3             	mov    %bl,-0x1d(%ebp)
	return data;
  1085c3:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax

	data = inb(KBDATAP);
  1085c7:	88 45 f3             	mov    %al,-0xd(%ebp)

	if (data == 0xE0) {
  1085ca:	80 7d f3 e0          	cmpb   $0xe0,-0xd(%ebp)
  1085ce:	75 17                	jne    1085e7 <kbd_proc_data+0x6f>
		// E0 escape character
		shift |= E0ESC;
  1085d0:	a1 e8 8e 18 00       	mov    0x188ee8,%eax
  1085d5:	83 c8 40             	or     $0x40,%eax
  1085d8:	a3 e8 8e 18 00       	mov    %eax,0x188ee8
		return 0;
  1085dd:	b8 00 00 00 00       	mov    $0x0,%eax
  1085e2:	e9 25 01 00 00       	jmp    10870c <kbd_proc_data+0x194>
	} else if (data & 0x80) {
  1085e7:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1085eb:	84 c0                	test   %al,%al
  1085ed:	79 47                	jns    108636 <kbd_proc_data+0xbe>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  1085ef:	a1 e8 8e 18 00       	mov    0x188ee8,%eax
  1085f4:	83 e0 40             	and    $0x40,%eax
  1085f7:	85 c0                	test   %eax,%eax
  1085f9:	75 09                	jne    108604 <kbd_proc_data+0x8c>
  1085fb:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1085ff:	83 e0 7f             	and    $0x7f,%eax
  108602:	eb 04                	jmp    108608 <kbd_proc_data+0x90>
  108604:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  108608:	88 45 f3             	mov    %al,-0xd(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  10860b:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10860f:	0f b6 80 80 01 11 00 	movzbl 0x110180(%eax),%eax
  108616:	83 c8 40             	or     $0x40,%eax
  108619:	0f b6 c0             	movzbl %al,%eax
  10861c:	f7 d0                	not    %eax
  10861e:	89 c2                	mov    %eax,%edx
  108620:	a1 e8 8e 18 00       	mov    0x188ee8,%eax
  108625:	21 d0                	and    %edx,%eax
  108627:	a3 e8 8e 18 00       	mov    %eax,0x188ee8
		return 0;
  10862c:	b8 00 00 00 00       	mov    $0x0,%eax
  108631:	e9 d6 00 00 00       	jmp    10870c <kbd_proc_data+0x194>
	} else if (shift & E0ESC) {
  108636:	a1 e8 8e 18 00       	mov    0x188ee8,%eax
  10863b:	83 e0 40             	and    $0x40,%eax
  10863e:	85 c0                	test   %eax,%eax
  108640:	74 11                	je     108653 <kbd_proc_data+0xdb>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  108642:	80 4d f3 80          	orb    $0x80,-0xd(%ebp)
		shift &= ~E0ESC;
  108646:	a1 e8 8e 18 00       	mov    0x188ee8,%eax
  10864b:	83 e0 bf             	and    $0xffffffbf,%eax
  10864e:	a3 e8 8e 18 00       	mov    %eax,0x188ee8
	}

	shift |= shiftcode[data];
  108653:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  108657:	0f b6 80 80 01 11 00 	movzbl 0x110180(%eax),%eax
  10865e:	0f b6 d0             	movzbl %al,%edx
  108661:	a1 e8 8e 18 00       	mov    0x188ee8,%eax
  108666:	09 d0                	or     %edx,%eax
  108668:	a3 e8 8e 18 00       	mov    %eax,0x188ee8
	shift ^= togglecode[data];
  10866d:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  108671:	0f b6 80 80 02 11 00 	movzbl 0x110280(%eax),%eax
  108678:	0f b6 d0             	movzbl %al,%edx
  10867b:	a1 e8 8e 18 00       	mov    0x188ee8,%eax
  108680:	31 d0                	xor    %edx,%eax
  108682:	a3 e8 8e 18 00       	mov    %eax,0x188ee8

	c = charcode[shift & (CTL | SHIFT)][data];
  108687:	a1 e8 8e 18 00       	mov    0x188ee8,%eax
  10868c:	83 e0 03             	and    $0x3,%eax
  10868f:	8b 14 85 80 06 11 00 	mov    0x110680(,%eax,4),%edx
  108696:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10869a:	01 d0                	add    %edx,%eax
  10869c:	0f b6 00             	movzbl (%eax),%eax
  10869f:	0f b6 c0             	movzbl %al,%eax
  1086a2:	89 45 f4             	mov    %eax,-0xc(%ebp)
	if (shift & CAPSLOCK) {
  1086a5:	a1 e8 8e 18 00       	mov    0x188ee8,%eax
  1086aa:	83 e0 08             	and    $0x8,%eax
  1086ad:	85 c0                	test   %eax,%eax
  1086af:	74 22                	je     1086d3 <kbd_proc_data+0x15b>
		if ('a' <= c && c <= 'z')
  1086b1:	83 7d f4 60          	cmpl   $0x60,-0xc(%ebp)
  1086b5:	7e 0c                	jle    1086c3 <kbd_proc_data+0x14b>
  1086b7:	83 7d f4 7a          	cmpl   $0x7a,-0xc(%ebp)
  1086bb:	7f 06                	jg     1086c3 <kbd_proc_data+0x14b>
			c += 'A' - 'a';
  1086bd:	83 6d f4 20          	subl   $0x20,-0xc(%ebp)
  1086c1:	eb 10                	jmp    1086d3 <kbd_proc_data+0x15b>
		else if ('A' <= c && c <= 'Z')
  1086c3:	83 7d f4 40          	cmpl   $0x40,-0xc(%ebp)
  1086c7:	7e 0a                	jle    1086d3 <kbd_proc_data+0x15b>
  1086c9:	83 7d f4 5a          	cmpl   $0x5a,-0xc(%ebp)
  1086cd:	7f 04                	jg     1086d3 <kbd_proc_data+0x15b>
			c += 'a' - 'A';
  1086cf:	83 45 f4 20          	addl   $0x20,-0xc(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  1086d3:	a1 e8 8e 18 00       	mov    0x188ee8,%eax
  1086d8:	f7 d0                	not    %eax
  1086da:	83 e0 06             	and    $0x6,%eax
  1086dd:	85 c0                	test   %eax,%eax
  1086df:	75 28                	jne    108709 <kbd_proc_data+0x191>
  1086e1:	81 7d f4 e9 00 00 00 	cmpl   $0xe9,-0xc(%ebp)
  1086e8:	75 1f                	jne    108709 <kbd_proc_data+0x191>
		cprintf("Rebooting!\n");
  1086ea:	c7 04 24 b8 bd 10 00 	movl   $0x10bdb8,(%esp)
  1086f1:	e8 da 11 00 00       	call   1098d0 <cprintf>
  1086f6:	c7 45 dc 92 00 00 00 	movl   $0x92,-0x24(%ebp)
  1086fd:	c6 45 db 03          	movb   $0x3,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  108701:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  108705:	8b 55 dc             	mov    -0x24(%ebp),%edx
  108708:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  108709:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  10870c:	83 c4 44             	add    $0x44,%esp
  10870f:	5b                   	pop    %ebx
  108710:	5d                   	pop    %ebp
  108711:	c3                   	ret    

00108712 <kbd_intr>:

void
kbd_intr(void)
{
  108712:	55                   	push   %ebp
  108713:	89 e5                	mov    %esp,%ebp
  108715:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  108718:	c7 04 24 78 85 10 00 	movl   $0x108578,(%esp)
  10871f:	e8 5e 7e ff ff       	call   100582 <cons_intr>
}
  108724:	c9                   	leave  
  108725:	c3                   	ret    

00108726 <kbd_init>:

void
kbd_init(void)
{
  108726:	55                   	push   %ebp
  108727:	89 e5                	mov    %esp,%ebp
}
  108729:	5d                   	pop    %ebp
  10872a:	c3                   	ret    

0010872b <kbd_intenable>:

void
kbd_intenable(void)
{
  10872b:	55                   	push   %ebp
  10872c:	89 e5                	mov    %esp,%ebp
  10872e:	83 ec 18             	sub    $0x18,%esp
	// Enable interrupt delivery via the PIC/APIC
	pic_enable(IRQ_KBD);
  108731:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  108738:	e8 08 04 00 00       	call   108b45 <pic_enable>
	ioapic_enable(IRQ_KBD);
  10873d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  108744:	e8 bb 09 00 00       	call   109104 <ioapic_enable>

	// Drain the kbd buffer so that the hardware generates interrupts.
	kbd_intr();
  108749:	e8 c4 ff ff ff       	call   108712 <kbd_intr>
}
  10874e:	c9                   	leave  
  10874f:	c3                   	ret    

00108750 <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  108750:	55                   	push   %ebp
  108751:	89 e5                	mov    %esp,%ebp
  108753:	53                   	push   %ebx
  108754:	83 ec 24             	sub    $0x24,%esp
  108757:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10875e:	8b 55 f8             	mov    -0x8(%ebp),%edx
  108761:	89 55 d8             	mov    %edx,-0x28(%ebp)
  108764:	8b 55 d8             	mov    -0x28(%ebp),%edx
  108767:	ec                   	in     (%dx),%al
  108768:	89 c3                	mov    %eax,%ebx
  10876a:	88 5d f7             	mov    %bl,-0x9(%ebp)
  10876d:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)
  108774:	8b 55 f0             	mov    -0x10(%ebp),%edx
  108777:	89 55 d8             	mov    %edx,-0x28(%ebp)
  10877a:	8b 55 d8             	mov    -0x28(%ebp),%edx
  10877d:	ec                   	in     (%dx),%al
  10877e:	89 c3                	mov    %eax,%ebx
  108780:	88 5d ef             	mov    %bl,-0x11(%ebp)
  108783:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)
  10878a:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10878d:	89 55 d8             	mov    %edx,-0x28(%ebp)
  108790:	8b 55 d8             	mov    -0x28(%ebp),%edx
  108793:	ec                   	in     (%dx),%al
  108794:	89 c3                	mov    %eax,%ebx
  108796:	88 5d e7             	mov    %bl,-0x19(%ebp)
  108799:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)
  1087a0:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1087a3:	89 55 d8             	mov    %edx,-0x28(%ebp)
  1087a6:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1087a9:	ec                   	in     (%dx),%al
  1087aa:	89 c3                	mov    %eax,%ebx
  1087ac:	88 5d df             	mov    %bl,-0x21(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  1087af:	83 c4 24             	add    $0x24,%esp
  1087b2:	5b                   	pop    %ebx
  1087b3:	5d                   	pop    %ebp
  1087b4:	c3                   	ret    

001087b5 <serial_proc_data>:

static int
serial_proc_data(void)
{
  1087b5:	55                   	push   %ebp
  1087b6:	89 e5                	mov    %esp,%ebp
  1087b8:	53                   	push   %ebx
  1087b9:	83 ec 14             	sub    $0x14,%esp
  1087bc:	c7 45 f8 fd 03 00 00 	movl   $0x3fd,-0x8(%ebp)
  1087c3:	8b 55 f8             	mov    -0x8(%ebp),%edx
  1087c6:	89 55 e8             	mov    %edx,-0x18(%ebp)
  1087c9:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1087cc:	ec                   	in     (%dx),%al
  1087cd:	89 c3                	mov    %eax,%ebx
  1087cf:	88 5d f7             	mov    %bl,-0x9(%ebp)
	return data;
  1087d2:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  1087d6:	0f b6 c0             	movzbl %al,%eax
  1087d9:	83 e0 01             	and    $0x1,%eax
  1087dc:	85 c0                	test   %eax,%eax
  1087de:	75 07                	jne    1087e7 <serial_proc_data+0x32>
		return -1;
  1087e0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1087e5:	eb 1d                	jmp    108804 <serial_proc_data+0x4f>
  1087e7:	c7 45 f0 f8 03 00 00 	movl   $0x3f8,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1087ee:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1087f1:	89 55 e8             	mov    %edx,-0x18(%ebp)
  1087f4:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1087f7:	ec                   	in     (%dx),%al
  1087f8:	89 c3                	mov    %eax,%ebx
  1087fa:	88 5d ef             	mov    %bl,-0x11(%ebp)
	return data;
  1087fd:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	return inb(COM1+COM_RX);
  108801:	0f b6 c0             	movzbl %al,%eax
}
  108804:	83 c4 14             	add    $0x14,%esp
  108807:	5b                   	pop    %ebx
  108808:	5d                   	pop    %ebp
  108809:	c3                   	ret    

0010880a <serial_intr>:

void
serial_intr(void)
{
  10880a:	55                   	push   %ebp
  10880b:	89 e5                	mov    %esp,%ebp
  10880d:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  108810:	a1 00 c0 38 00       	mov    0x38c000,%eax
  108815:	85 c0                	test   %eax,%eax
  108817:	74 0c                	je     108825 <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  108819:	c7 04 24 b5 87 10 00 	movl   $0x1087b5,(%esp)
  108820:	e8 5d 7d ff ff       	call   100582 <cons_intr>
}
  108825:	c9                   	leave  
  108826:	c3                   	ret    

00108827 <serial_putc>:

void
serial_putc(int c)
{
  108827:	55                   	push   %ebp
  108828:	89 e5                	mov    %esp,%ebp
  10882a:	53                   	push   %ebx
  10882b:	83 ec 24             	sub    $0x24,%esp
	if (!serial_exists)
  10882e:	a1 00 c0 38 00       	mov    0x38c000,%eax
  108833:	85 c0                	test   %eax,%eax
  108835:	74 59                	je     108890 <serial_putc+0x69>
		return;

	int i;
	for (i = 0;
  108837:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  10883e:	eb 09                	jmp    108849 <serial_putc+0x22>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  108840:	e8 0b ff ff ff       	call   108750 <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  108845:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  108849:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  108850:	8b 55 f4             	mov    -0xc(%ebp),%edx
  108853:	89 55 d8             	mov    %edx,-0x28(%ebp)
  108856:	8b 55 d8             	mov    -0x28(%ebp),%edx
  108859:	ec                   	in     (%dx),%al
  10885a:	89 c3                	mov    %eax,%ebx
  10885c:	88 5d f3             	mov    %bl,-0xd(%ebp)
	return data;
  10885f:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  108863:	0f b6 c0             	movzbl %al,%eax
  108866:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  108869:	85 c0                	test   %eax,%eax
  10886b:	75 09                	jne    108876 <serial_putc+0x4f>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  10886d:	81 7d f8 ff 31 00 00 	cmpl   $0x31ff,-0x8(%ebp)
  108874:	7e ca                	jle    108840 <serial_putc+0x19>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  108876:	8b 45 08             	mov    0x8(%ebp),%eax
  108879:	0f b6 c0             	movzbl %al,%eax
  10887c:	c7 45 ec f8 03 00 00 	movl   $0x3f8,-0x14(%ebp)
  108883:	88 45 eb             	mov    %al,-0x15(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  108886:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  10888a:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10888d:	ee                   	out    %al,(%dx)
  10888e:	eb 01                	jmp    108891 <serial_putc+0x6a>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  108890:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  108891:	83 c4 24             	add    $0x24,%esp
  108894:	5b                   	pop    %ebx
  108895:	5d                   	pop    %ebp
  108896:	c3                   	ret    

00108897 <serial_init>:

void
serial_init(void)
{
  108897:	55                   	push   %ebp
  108898:	89 e5                	mov    %esp,%ebp
  10889a:	53                   	push   %ebx
  10889b:	83 ec 54             	sub    $0x54,%esp
  10889e:	c7 45 f8 fa 03 00 00 	movl   $0x3fa,-0x8(%ebp)
  1088a5:	c6 45 f7 00          	movb   $0x0,-0x9(%ebp)
  1088a9:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
  1088ad:	8b 55 f8             	mov    -0x8(%ebp),%edx
  1088b0:	ee                   	out    %al,(%dx)
  1088b1:	c7 45 f0 fb 03 00 00 	movl   $0x3fb,-0x10(%ebp)
  1088b8:	c6 45 ef 80          	movb   $0x80,-0x11(%ebp)
  1088bc:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
  1088c0:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1088c3:	ee                   	out    %al,(%dx)
  1088c4:	c7 45 e8 f8 03 00 00 	movl   $0x3f8,-0x18(%ebp)
  1088cb:	c6 45 e7 0c          	movb   $0xc,-0x19(%ebp)
  1088cf:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  1088d3:	8b 55 e8             	mov    -0x18(%ebp),%edx
  1088d6:	ee                   	out    %al,(%dx)
  1088d7:	c7 45 e0 f9 03 00 00 	movl   $0x3f9,-0x20(%ebp)
  1088de:	c6 45 df 00          	movb   $0x0,-0x21(%ebp)
  1088e2:	0f b6 45 df          	movzbl -0x21(%ebp),%eax
  1088e6:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1088e9:	ee                   	out    %al,(%dx)
  1088ea:	c7 45 d8 fb 03 00 00 	movl   $0x3fb,-0x28(%ebp)
  1088f1:	c6 45 d7 03          	movb   $0x3,-0x29(%ebp)
  1088f5:	0f b6 45 d7          	movzbl -0x29(%ebp),%eax
  1088f9:	8b 55 d8             	mov    -0x28(%ebp),%edx
  1088fc:	ee                   	out    %al,(%dx)
  1088fd:	c7 45 d0 fc 03 00 00 	movl   $0x3fc,-0x30(%ebp)
  108904:	c6 45 cf 00          	movb   $0x0,-0x31(%ebp)
  108908:	0f b6 45 cf          	movzbl -0x31(%ebp),%eax
  10890c:	8b 55 d0             	mov    -0x30(%ebp),%edx
  10890f:	ee                   	out    %al,(%dx)
  108910:	c7 45 c8 f9 03 00 00 	movl   $0x3f9,-0x38(%ebp)
  108917:	c6 45 c7 01          	movb   $0x1,-0x39(%ebp)
  10891b:	0f b6 45 c7          	movzbl -0x39(%ebp),%eax
  10891f:	8b 55 c8             	mov    -0x38(%ebp),%edx
  108922:	ee                   	out    %al,(%dx)
  108923:	c7 45 c0 fd 03 00 00 	movl   $0x3fd,-0x40(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  10892a:	8b 55 c0             	mov    -0x40(%ebp),%edx
  10892d:	89 55 a8             	mov    %edx,-0x58(%ebp)
  108930:	8b 55 a8             	mov    -0x58(%ebp),%edx
  108933:	ec                   	in     (%dx),%al
  108934:	89 c3                	mov    %eax,%ebx
  108936:	88 5d bf             	mov    %bl,-0x41(%ebp)
	return data;
  108939:	0f b6 45 bf          	movzbl -0x41(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  10893d:	3c ff                	cmp    $0xff,%al
  10893f:	0f 95 c0             	setne  %al
  108942:	0f b6 c0             	movzbl %al,%eax
  108945:	a3 00 c0 38 00       	mov    %eax,0x38c000
  10894a:	c7 45 b8 fa 03 00 00 	movl   $0x3fa,-0x48(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  108951:	8b 55 b8             	mov    -0x48(%ebp),%edx
  108954:	89 55 a8             	mov    %edx,-0x58(%ebp)
  108957:	8b 55 a8             	mov    -0x58(%ebp),%edx
  10895a:	ec                   	in     (%dx),%al
  10895b:	89 c3                	mov    %eax,%ebx
  10895d:	88 5d b7             	mov    %bl,-0x49(%ebp)
  108960:	c7 45 b0 f8 03 00 00 	movl   $0x3f8,-0x50(%ebp)
  108967:	8b 55 b0             	mov    -0x50(%ebp),%edx
  10896a:	89 55 a8             	mov    %edx,-0x58(%ebp)
  10896d:	8b 55 a8             	mov    -0x58(%ebp),%edx
  108970:	ec                   	in     (%dx),%al
  108971:	89 c3                	mov    %eax,%ebx
  108973:	88 5d af             	mov    %bl,-0x51(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  108976:	83 c4 54             	add    $0x54,%esp
  108979:	5b                   	pop    %ebx
  10897a:	5d                   	pop    %ebp
  10897b:	c3                   	ret    

0010897c <serial_intenable>:

void
serial_intenable(void)
{
  10897c:	55                   	push   %ebp
  10897d:	89 e5                	mov    %esp,%ebp
  10897f:	83 ec 18             	sub    $0x18,%esp
	// Enable serial interrupts
	if (serial_exists) {
  108982:	a1 00 c0 38 00       	mov    0x38c000,%eax
  108987:	85 c0                	test   %eax,%eax
  108989:	74 18                	je     1089a3 <serial_intenable+0x27>
		pic_enable(IRQ_SERIAL);
  10898b:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  108992:	e8 ae 01 00 00       	call   108b45 <pic_enable>
		ioapic_enable(IRQ_SERIAL);
  108997:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
  10899e:	e8 61 07 00 00       	call   109104 <ioapic_enable>
	}
}
  1089a3:	c9                   	leave  
  1089a4:	c3                   	ret    
  1089a5:	66 90                	xchg   %ax,%ax
  1089a7:	90                   	nop

001089a8 <pic_init>:
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
  1089a8:	55                   	push   %ebp
  1089a9:	89 e5                	mov    %esp,%ebp
  1089ab:	81 ec 88 00 00 00    	sub    $0x88,%esp
	if (didinit)		// only do once on bootstrap CPU
  1089b1:	a1 ec 8e 18 00       	mov    0x188eec,%eax
  1089b6:	85 c0                	test   %eax,%eax
  1089b8:	0f 85 35 01 00 00    	jne    108af3 <pic_init+0x14b>
		return;
	didinit = 1;
  1089be:	c7 05 ec 8e 18 00 01 	movl   $0x1,0x188eec
  1089c5:	00 00 00 
  1089c8:	c7 45 f4 21 00 00 00 	movl   $0x21,-0xc(%ebp)
  1089cf:	c6 45 f3 ff          	movb   $0xff,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  1089d3:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1089d7:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1089da:	ee                   	out    %al,(%dx)
  1089db:	c7 45 ec a1 00 00 00 	movl   $0xa1,-0x14(%ebp)
  1089e2:	c6 45 eb ff          	movb   $0xff,-0x15(%ebp)
  1089e6:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  1089ea:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1089ed:	ee                   	out    %al,(%dx)
  1089ee:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
  1089f5:	c6 45 e3 11          	movb   $0x11,-0x1d(%ebp)
  1089f9:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1089fd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  108a00:	ee                   	out    %al,(%dx)
  108a01:	c7 45 dc 21 00 00 00 	movl   $0x21,-0x24(%ebp)
  108a08:	c6 45 db 20          	movb   $0x20,-0x25(%ebp)
  108a0c:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  108a10:	8b 55 dc             	mov    -0x24(%ebp),%edx
  108a13:	ee                   	out    %al,(%dx)
  108a14:	c7 45 d4 21 00 00 00 	movl   $0x21,-0x2c(%ebp)
  108a1b:	c6 45 d3 04          	movb   $0x4,-0x2d(%ebp)
  108a1f:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  108a23:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  108a26:	ee                   	out    %al,(%dx)
  108a27:	c7 45 cc 21 00 00 00 	movl   $0x21,-0x34(%ebp)
  108a2e:	c6 45 cb 03          	movb   $0x3,-0x35(%ebp)
  108a32:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  108a36:	8b 55 cc             	mov    -0x34(%ebp),%edx
  108a39:	ee                   	out    %al,(%dx)
  108a3a:	c7 45 c4 a0 00 00 00 	movl   $0xa0,-0x3c(%ebp)
  108a41:	c6 45 c3 11          	movb   $0x11,-0x3d(%ebp)
  108a45:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  108a49:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  108a4c:	ee                   	out    %al,(%dx)
  108a4d:	c7 45 bc a1 00 00 00 	movl   $0xa1,-0x44(%ebp)
  108a54:	c6 45 bb 28          	movb   $0x28,-0x45(%ebp)
  108a58:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  108a5c:	8b 55 bc             	mov    -0x44(%ebp),%edx
  108a5f:	ee                   	out    %al,(%dx)
  108a60:	c7 45 b4 a1 00 00 00 	movl   $0xa1,-0x4c(%ebp)
  108a67:	c6 45 b3 02          	movb   $0x2,-0x4d(%ebp)
  108a6b:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  108a6f:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  108a72:	ee                   	out    %al,(%dx)
  108a73:	c7 45 ac a1 00 00 00 	movl   $0xa1,-0x54(%ebp)
  108a7a:	c6 45 ab 01          	movb   $0x1,-0x55(%ebp)
  108a7e:	0f b6 45 ab          	movzbl -0x55(%ebp),%eax
  108a82:	8b 55 ac             	mov    -0x54(%ebp),%edx
  108a85:	ee                   	out    %al,(%dx)
  108a86:	c7 45 a4 20 00 00 00 	movl   $0x20,-0x5c(%ebp)
  108a8d:	c6 45 a3 68          	movb   $0x68,-0x5d(%ebp)
  108a91:	0f b6 45 a3          	movzbl -0x5d(%ebp),%eax
  108a95:	8b 55 a4             	mov    -0x5c(%ebp),%edx
  108a98:	ee                   	out    %al,(%dx)
  108a99:	c7 45 9c 20 00 00 00 	movl   $0x20,-0x64(%ebp)
  108aa0:	c6 45 9b 0a          	movb   $0xa,-0x65(%ebp)
  108aa4:	0f b6 45 9b          	movzbl -0x65(%ebp),%eax
  108aa8:	8b 55 9c             	mov    -0x64(%ebp),%edx
  108aab:	ee                   	out    %al,(%dx)
  108aac:	c7 45 94 a0 00 00 00 	movl   $0xa0,-0x6c(%ebp)
  108ab3:	c6 45 93 68          	movb   $0x68,-0x6d(%ebp)
  108ab7:	0f b6 45 93          	movzbl -0x6d(%ebp),%eax
  108abb:	8b 55 94             	mov    -0x6c(%ebp),%edx
  108abe:	ee                   	out    %al,(%dx)
  108abf:	c7 45 8c a0 00 00 00 	movl   $0xa0,-0x74(%ebp)
  108ac6:	c6 45 8b 0a          	movb   $0xa,-0x75(%ebp)
  108aca:	0f b6 45 8b          	movzbl -0x75(%ebp),%eax
  108ace:	8b 55 8c             	mov    -0x74(%ebp),%edx
  108ad1:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
  108ad2:	0f b7 05 90 06 11 00 	movzwl 0x110690,%eax
  108ad9:	66 83 f8 ff          	cmp    $0xffff,%ax
  108add:	74 15                	je     108af4 <pic_init+0x14c>
		pic_setmask(irqmask);
  108adf:	0f b7 05 90 06 11 00 	movzwl 0x110690,%eax
  108ae6:	0f b7 c0             	movzwl %ax,%eax
  108ae9:	89 04 24             	mov    %eax,(%esp)
  108aec:	e8 05 00 00 00       	call   108af6 <pic_setmask>
  108af1:	eb 01                	jmp    108af4 <pic_init+0x14c>
/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	if (didinit)		// only do once on bootstrap CPU
		return;
  108af3:	90                   	nop
	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
		pic_setmask(irqmask);
}
  108af4:	c9                   	leave  
  108af5:	c3                   	ret    

00108af6 <pic_setmask>:

void
pic_setmask(uint16_t mask)
{
  108af6:	55                   	push   %ebp
  108af7:	89 e5                	mov    %esp,%ebp
  108af9:	83 ec 14             	sub    $0x14,%esp
  108afc:	8b 45 08             	mov    0x8(%ebp),%eax
  108aff:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
	irqmask = mask;
  108b03:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  108b07:	66 a3 90 06 11 00    	mov    %ax,0x110690
	outb(IO_PIC1+1, (char)mask);
  108b0d:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  108b11:	0f b6 c0             	movzbl %al,%eax
  108b14:	c7 45 fc 21 00 00 00 	movl   $0x21,-0x4(%ebp)
  108b1b:	88 45 fb             	mov    %al,-0x5(%ebp)
  108b1e:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  108b22:	8b 55 fc             	mov    -0x4(%ebp),%edx
  108b25:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
  108b26:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  108b2a:	66 c1 e8 08          	shr    $0x8,%ax
  108b2e:	0f b6 c0             	movzbl %al,%eax
  108b31:	c7 45 f4 a1 00 00 00 	movl   $0xa1,-0xc(%ebp)
  108b38:	88 45 f3             	mov    %al,-0xd(%ebp)
  108b3b:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  108b3f:	8b 55 f4             	mov    -0xc(%ebp),%edx
  108b42:	ee                   	out    %al,(%dx)
}
  108b43:	c9                   	leave  
  108b44:	c3                   	ret    

00108b45 <pic_enable>:

void
pic_enable(int irq)
{
  108b45:	55                   	push   %ebp
  108b46:	89 e5                	mov    %esp,%ebp
  108b48:	53                   	push   %ebx
  108b49:	83 ec 04             	sub    $0x4,%esp
	pic_setmask(irqmask & ~(1 << irq));
  108b4c:	8b 45 08             	mov    0x8(%ebp),%eax
  108b4f:	ba 01 00 00 00       	mov    $0x1,%edx
  108b54:	89 d3                	mov    %edx,%ebx
  108b56:	89 c1                	mov    %eax,%ecx
  108b58:	d3 e3                	shl    %cl,%ebx
  108b5a:	89 d8                	mov    %ebx,%eax
  108b5c:	89 c2                	mov    %eax,%edx
  108b5e:	f7 d2                	not    %edx
  108b60:	0f b7 05 90 06 11 00 	movzwl 0x110690,%eax
  108b67:	21 d0                	and    %edx,%eax
  108b69:	0f b7 c0             	movzwl %ax,%eax
  108b6c:	89 04 24             	mov    %eax,(%esp)
  108b6f:	e8 82 ff ff ff       	call   108af6 <pic_setmask>
}
  108b74:	83 c4 04             	add    $0x4,%esp
  108b77:	5b                   	pop    %ebx
  108b78:	5d                   	pop    %ebp
  108b79:	c3                   	ret    
  108b7a:	66 90                	xchg   %ax,%ax

00108b7c <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  108b7c:	55                   	push   %ebp
  108b7d:	89 e5                	mov    %esp,%ebp
  108b7f:	53                   	push   %ebx
  108b80:	83 ec 14             	sub    $0x14,%esp
	outb(IO_RTC, reg);
  108b83:	8b 45 08             	mov    0x8(%ebp),%eax
  108b86:	0f b6 c0             	movzbl %al,%eax
  108b89:	c7 45 f8 70 00 00 00 	movl   $0x70,-0x8(%ebp)
  108b90:	88 45 f7             	mov    %al,-0x9(%ebp)
  108b93:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
  108b97:	8b 55 f8             	mov    -0x8(%ebp),%edx
  108b9a:	ee                   	out    %al,(%dx)
  108b9b:	c7 45 f0 71 00 00 00 	movl   $0x71,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  108ba2:	8b 55 f0             	mov    -0x10(%ebp),%edx
  108ba5:	89 55 e8             	mov    %edx,-0x18(%ebp)
  108ba8:	8b 55 e8             	mov    -0x18(%ebp),%edx
  108bab:	ec                   	in     (%dx),%al
  108bac:	89 c3                	mov    %eax,%ebx
  108bae:	88 5d ef             	mov    %bl,-0x11(%ebp)
	return data;
  108bb1:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	return inb(IO_RTC+1);
  108bb5:	0f b6 c0             	movzbl %al,%eax
}
  108bb8:	83 c4 14             	add    $0x14,%esp
  108bbb:	5b                   	pop    %ebx
  108bbc:	5d                   	pop    %ebp
  108bbd:	c3                   	ret    

00108bbe <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  108bbe:	55                   	push   %ebp
  108bbf:	89 e5                	mov    %esp,%ebp
  108bc1:	53                   	push   %ebx
  108bc2:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  108bc5:	8b 45 08             	mov    0x8(%ebp),%eax
  108bc8:	89 04 24             	mov    %eax,(%esp)
  108bcb:	e8 ac ff ff ff       	call   108b7c <nvram_read>
  108bd0:	89 c3                	mov    %eax,%ebx
  108bd2:	8b 45 08             	mov    0x8(%ebp),%eax
  108bd5:	83 c0 01             	add    $0x1,%eax
  108bd8:	89 04 24             	mov    %eax,(%esp)
  108bdb:	e8 9c ff ff ff       	call   108b7c <nvram_read>
  108be0:	c1 e0 08             	shl    $0x8,%eax
  108be3:	09 d8                	or     %ebx,%eax
}
  108be5:	83 c4 04             	add    $0x4,%esp
  108be8:	5b                   	pop    %ebx
  108be9:	5d                   	pop    %ebp
  108bea:	c3                   	ret    

00108beb <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  108beb:	55                   	push   %ebp
  108bec:	89 e5                	mov    %esp,%ebp
  108bee:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  108bf1:	8b 45 08             	mov    0x8(%ebp),%eax
  108bf4:	0f b6 c0             	movzbl %al,%eax
  108bf7:	c7 45 fc 70 00 00 00 	movl   $0x70,-0x4(%ebp)
  108bfe:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  108c01:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  108c05:	8b 55 fc             	mov    -0x4(%ebp),%edx
  108c08:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  108c09:	8b 45 0c             	mov    0xc(%ebp),%eax
  108c0c:	0f b6 c0             	movzbl %al,%eax
  108c0f:	c7 45 f4 71 00 00 00 	movl   $0x71,-0xc(%ebp)
  108c16:	88 45 f3             	mov    %al,-0xd(%ebp)
  108c19:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  108c1d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  108c20:	ee                   	out    %al,(%dx)
}
  108c21:	c9                   	leave  
  108c22:	c3                   	ret    
  108c23:	90                   	nop

00108c24 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  108c24:	55                   	push   %ebp
  108c25:	89 e5                	mov    %esp,%ebp
  108c27:	53                   	push   %ebx
  108c28:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  108c2b:	89 e3                	mov    %esp,%ebx
  108c2d:	89 5d ec             	mov    %ebx,-0x14(%ebp)
        return esp;
  108c30:	8b 45 ec             	mov    -0x14(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  108c33:	89 45 f4             	mov    %eax,-0xc(%ebp)
  108c36:	8b 45 f4             	mov    -0xc(%ebp),%eax
  108c39:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  108c3e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(c->magic == CPU_MAGIC);
  108c41:	8b 45 f0             	mov    -0x10(%ebp),%eax
  108c44:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  108c4a:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  108c4f:	74 24                	je     108c75 <cpu_cur+0x51>
  108c51:	c7 44 24 0c c4 bd 10 	movl   $0x10bdc4,0xc(%esp)
  108c58:	00 
  108c59:	c7 44 24 08 da bd 10 	movl   $0x10bdda,0x8(%esp)
  108c60:	00 
  108c61:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  108c68:	00 
  108c69:	c7 04 24 ef bd 10 00 	movl   $0x10bdef,(%esp)
  108c70:	e8 c3 7c ff ff       	call   100938 <debug_panic>
	return c;
  108c75:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  108c78:	83 c4 24             	add    $0x24,%esp
  108c7b:	5b                   	pop    %ebx
  108c7c:	5d                   	pop    %ebp
  108c7d:	c3                   	ret    

00108c7e <lapicw>:
volatile uint32_t *lapic;  // Initialized in mp.c


static void
lapicw(int index, int value)
{
  108c7e:	55                   	push   %ebp
  108c7f:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
  108c81:	a1 04 c0 38 00       	mov    0x38c004,%eax
  108c86:	8b 55 08             	mov    0x8(%ebp),%edx
  108c89:	c1 e2 02             	shl    $0x2,%edx
  108c8c:	01 c2                	add    %eax,%edx
  108c8e:	8b 45 0c             	mov    0xc(%ebp),%eax
  108c91:	89 02                	mov    %eax,(%edx)
	lapic[ID];  // wait for write to finish, by reading
  108c93:	a1 04 c0 38 00       	mov    0x38c004,%eax
  108c98:	83 c0 20             	add    $0x20,%eax
  108c9b:	8b 00                	mov    (%eax),%eax
}
  108c9d:	5d                   	pop    %ebp
  108c9e:	c3                   	ret    

00108c9f <lapic_init>:

void
lapic_init()
{
  108c9f:	55                   	push   %ebp
  108ca0:	89 e5                	mov    %esp,%ebp
  108ca2:	83 ec 08             	sub    $0x8,%esp
	if (!lapic) 
  108ca5:	a1 04 c0 38 00       	mov    0x38c004,%eax
  108caa:	85 c0                	test   %eax,%eax
  108cac:	0f 84 83 01 00 00    	je     108e35 <lapic_init+0x196>
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
  108cb2:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  108cb9:	00 
  108cba:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
  108cc1:	e8 b8 ff ff ff       	call   108c7e <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	lapicw(TDCR, X1);
  108cc6:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
  108ccd:	00 
  108cce:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
  108cd5:	e8 a4 ff ff ff       	call   108c7e <lapicw>
	lapicw(TIMER, PERIODIC | T_LTIMER);
  108cda:	c7 44 24 04 31 00 02 	movl   $0x20031,0x4(%esp)
  108ce1:	00 
  108ce2:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  108ce9:	e8 90 ff ff ff       	call   108c7e <lapicw>

	// If we cared more about precise timekeeping,
	// we would calibrate TICR with another time source such as the PIT.
	lapicw(TICR, 10000000);
  108cee:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
  108cf5:	00 
  108cf6:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
  108cfd:	e8 7c ff ff ff       	call   108c7e <lapicw>

	// Disable logical interrupt lines.
	lapicw(LINT0, MASKED);
  108d02:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  108d09:	00 
  108d0a:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
  108d11:	e8 68 ff ff ff       	call   108c7e <lapicw>
	lapicw(LINT1, MASKED);
  108d16:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  108d1d:	00 
  108d1e:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
  108d25:	e8 54 ff ff ff       	call   108c7e <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
  108d2a:	a1 04 c0 38 00       	mov    0x38c004,%eax
  108d2f:	83 c0 30             	add    $0x30,%eax
  108d32:	8b 00                	mov    (%eax),%eax
  108d34:	c1 e8 10             	shr    $0x10,%eax
  108d37:	25 ff 00 00 00       	and    $0xff,%eax
  108d3c:	83 f8 03             	cmp    $0x3,%eax
  108d3f:	76 14                	jbe    108d55 <lapic_init+0xb6>
		lapicw(PCINT, MASKED);
  108d41:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  108d48:	00 
  108d49:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
  108d50:	e8 29 ff ff ff       	call   108c7e <lapicw>

	// Map other interrupts to appropriate vectors.
	lapicw(ERROR, T_LERROR);
  108d55:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  108d5c:	00 
  108d5d:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
  108d64:	e8 15 ff ff ff       	call   108c7e <lapicw>

	// Set up to lowest-priority, "anycast" interrupts
	lapicw(LDR, 0xff << 24);	// Accept all interrupts
  108d69:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  108d70:	ff 
  108d71:	c7 04 24 34 00 00 00 	movl   $0x34,(%esp)
  108d78:	e8 01 ff ff ff       	call   108c7e <lapicw>
	lapicw(DFR, 0xf << 28);		// Flat model
  108d7d:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
  108d84:	f0 
  108d85:	c7 04 24 38 00 00 00 	movl   $0x38,(%esp)
  108d8c:	e8 ed fe ff ff       	call   108c7e <lapicw>
	lapicw(TPR, 0x00);		// Task priority 0, no intrs masked
  108d91:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  108d98:	00 
  108d99:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  108da0:	e8 d9 fe ff ff       	call   108c7e <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
  108da5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  108dac:	00 
  108dad:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  108db4:	e8 c5 fe ff ff       	call   108c7e <lapicw>
	lapicw(ESR, 0);
  108db9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  108dc0:	00 
  108dc1:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  108dc8:	e8 b1 fe ff ff       	call   108c7e <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
  108dcd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  108dd4:	00 
  108dd5:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  108ddc:	e8 9d fe ff ff       	call   108c7e <lapicw>

	// Send an Init Level De-Assert to synchronise arbitration ID's.
	lapicw(ICRHI, 0);
  108de1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  108de8:	00 
  108de9:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  108df0:	e8 89 fe ff ff       	call   108c7e <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
  108df5:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
  108dfc:	00 
  108dfd:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  108e04:	e8 75 fe ff ff       	call   108c7e <lapicw>
	while(lapic[ICRLO] & DELIVS)
  108e09:	90                   	nop
  108e0a:	a1 04 c0 38 00       	mov    0x38c004,%eax
  108e0f:	05 00 03 00 00       	add    $0x300,%eax
  108e14:	8b 00                	mov    (%eax),%eax
  108e16:	25 00 10 00 00       	and    $0x1000,%eax
  108e1b:	85 c0                	test   %eax,%eax
  108e1d:	75 eb                	jne    108e0a <lapic_init+0x16b>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
  108e1f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  108e26:	00 
  108e27:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  108e2e:	e8 4b fe ff ff       	call   108c7e <lapicw>
  108e33:	eb 01                	jmp    108e36 <lapic_init+0x197>

void
lapic_init()
{
	if (!lapic) 
		return;
  108e35:	90                   	nop
	while(lapic[ICRLO] & DELIVS)
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
}
  108e36:	c9                   	leave  
  108e37:	c3                   	ret    

00108e38 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
  108e38:	55                   	push   %ebp
  108e39:	89 e5                	mov    %esp,%ebp
  108e3b:	83 ec 08             	sub    $0x8,%esp
	if (lapic)
  108e3e:	a1 04 c0 38 00       	mov    0x38c004,%eax
  108e43:	85 c0                	test   %eax,%eax
  108e45:	74 14                	je     108e5b <lapic_eoi+0x23>
		lapicw(EOI, 0);
  108e47:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  108e4e:	00 
  108e4f:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  108e56:	e8 23 fe ff ff       	call   108c7e <lapicw>
}
  108e5b:	c9                   	leave  
  108e5c:	c3                   	ret    

00108e5d <lapic_errintr>:

void lapic_errintr(void)
{
  108e5d:	55                   	push   %ebp
  108e5e:	89 e5                	mov    %esp,%ebp
  108e60:	53                   	push   %ebx
  108e61:	83 ec 24             	sub    $0x24,%esp
	lapic_eoi();	// Acknowledge interrupt
  108e64:	e8 cf ff ff ff       	call   108e38 <lapic_eoi>
	lapicw(ESR, 0);	// Trigger update of ESR by writing anything
  108e69:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  108e70:	00 
  108e71:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  108e78:	e8 01 fe ff ff       	call   108c7e <lapicw>
	warn("CPU%d LAPIC error: ESR %x", cpu_cur()->id, lapic[ESR]);
  108e7d:	a1 04 c0 38 00       	mov    0x38c004,%eax
  108e82:	05 80 02 00 00       	add    $0x280,%eax
  108e87:	8b 18                	mov    (%eax),%ebx
  108e89:	e8 96 fd ff ff       	call   108c24 <cpu_cur>
  108e8e:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  108e95:	0f b6 c0             	movzbl %al,%eax
  108e98:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  108e9c:	89 44 24 0c          	mov    %eax,0xc(%esp)
  108ea0:	c7 44 24 08 fc bd 10 	movl   $0x10bdfc,0x8(%esp)
  108ea7:	00 
  108ea8:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  108eaf:	00 
  108eb0:	c7 04 24 16 be 10 00 	movl   $0x10be16,(%esp)
  108eb7:	e8 42 7b ff ff       	call   1009fe <debug_warn>
}
  108ebc:	83 c4 24             	add    $0x24,%esp
  108ebf:	5b                   	pop    %ebx
  108ec0:	5d                   	pop    %ebp
  108ec1:	c3                   	ret    

00108ec2 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  108ec2:	55                   	push   %ebp
  108ec3:	89 e5                	mov    %esp,%ebp
}
  108ec5:	5d                   	pop    %ebp
  108ec6:	c3                   	ret    

00108ec7 <lapic_startcpu>:

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startcpu(uint8_t apicid, uint32_t addr)
{
  108ec7:	55                   	push   %ebp
  108ec8:	89 e5                	mov    %esp,%ebp
  108eca:	83 ec 2c             	sub    $0x2c,%esp
  108ecd:	8b 45 08             	mov    0x8(%ebp),%eax
  108ed0:	88 45 dc             	mov    %al,-0x24(%ebp)
  108ed3:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  108eda:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  108ede:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  108ee2:	8b 55 f4             	mov    -0xc(%ebp),%edx
  108ee5:	ee                   	out    %al,(%dx)
  108ee6:	c7 45 ec 71 00 00 00 	movl   $0x71,-0x14(%ebp)
  108eed:	c6 45 eb 0a          	movb   $0xa,-0x15(%ebp)
  108ef1:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  108ef5:	8b 55 ec             	mov    -0x14(%ebp),%edx
  108ef8:	ee                   	out    %al,(%dx)
	// "The BSP must initialize CMOS shutdown code to 0AH
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t*)(0x40<<4 | 0x67);  // Warm reset vector
  108ef9:	c7 45 f8 67 04 00 00 	movl   $0x467,-0x8(%ebp)
	wrv[0] = 0;
  108f00:	8b 45 f8             	mov    -0x8(%ebp),%eax
  108f03:	66 c7 00 00 00       	movw   $0x0,(%eax)
	wrv[1] = addr >> 4;
  108f08:	8b 45 f8             	mov    -0x8(%ebp),%eax
  108f0b:	8d 50 02             	lea    0x2(%eax),%edx
  108f0e:	8b 45 0c             	mov    0xc(%ebp),%eax
  108f11:	c1 e8 04             	shr    $0x4,%eax
  108f14:	66 89 02             	mov    %ax,(%edx)

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid<<24);
  108f17:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  108f1b:	c1 e0 18             	shl    $0x18,%eax
  108f1e:	89 44 24 04          	mov    %eax,0x4(%esp)
  108f22:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  108f29:	e8 50 fd ff ff       	call   108c7e <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
  108f2e:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
  108f35:	00 
  108f36:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  108f3d:	e8 3c fd ff ff       	call   108c7e <lapicw>
	microdelay(200);
  108f42:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  108f49:	e8 74 ff ff ff       	call   108ec2 <microdelay>
	lapicw(ICRLO, INIT | LEVEL);
  108f4e:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
  108f55:	00 
  108f56:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  108f5d:	e8 1c fd ff ff       	call   108c7e <lapicw>
	microdelay(100);    // should be 10ms, but too slow in Bochs!
  108f62:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
  108f69:	e8 54 ff ff ff       	call   108ec2 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  108f6e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  108f75:	eb 40                	jmp    108fb7 <lapic_startcpu+0xf0>
		lapicw(ICRHI, apicid<<24);
  108f77:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  108f7b:	c1 e0 18             	shl    $0x18,%eax
  108f7e:	89 44 24 04          	mov    %eax,0x4(%esp)
  108f82:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  108f89:	e8 f0 fc ff ff       	call   108c7e <lapicw>
		lapicw(ICRLO, STARTUP | (addr>>12));
  108f8e:	8b 45 0c             	mov    0xc(%ebp),%eax
  108f91:	c1 e8 0c             	shr    $0xc,%eax
  108f94:	80 cc 06             	or     $0x6,%ah
  108f97:	89 44 24 04          	mov    %eax,0x4(%esp)
  108f9b:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  108fa2:	e8 d7 fc ff ff       	call   108c7e <lapicw>
		microdelay(200);
  108fa7:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  108fae:	e8 0f ff ff ff       	call   108ec2 <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  108fb3:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  108fb7:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
  108fbb:	7e ba                	jle    108f77 <lapic_startcpu+0xb0>
		lapicw(ICRHI, apicid<<24);
		lapicw(ICRLO, STARTUP | (addr>>12));
		microdelay(200);
	}
}
  108fbd:	c9                   	leave  
  108fbe:	c3                   	ret    
  108fbf:	90                   	nop

00108fc0 <ioapic_read>:
	uint32_t data;
};

static uint32_t
ioapic_read(int reg)
{
  108fc0:	55                   	push   %ebp
  108fc1:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  108fc3:	a1 58 8f 38 00       	mov    0x388f58,%eax
  108fc8:	8b 55 08             	mov    0x8(%ebp),%edx
  108fcb:	89 10                	mov    %edx,(%eax)
	return ioapic->data;
  108fcd:	a1 58 8f 38 00       	mov    0x388f58,%eax
  108fd2:	8b 40 10             	mov    0x10(%eax),%eax
}
  108fd5:	5d                   	pop    %ebp
  108fd6:	c3                   	ret    

00108fd7 <ioapic_write>:

static void
ioapic_write(int reg, uint32_t data)
{
  108fd7:	55                   	push   %ebp
  108fd8:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  108fda:	a1 58 8f 38 00       	mov    0x388f58,%eax
  108fdf:	8b 55 08             	mov    0x8(%ebp),%edx
  108fe2:	89 10                	mov    %edx,(%eax)
	ioapic->data = data;
  108fe4:	a1 58 8f 38 00       	mov    0x388f58,%eax
  108fe9:	8b 55 0c             	mov    0xc(%ebp),%edx
  108fec:	89 50 10             	mov    %edx,0x10(%eax)
}
  108fef:	5d                   	pop    %ebp
  108ff0:	c3                   	ret    

00108ff1 <ioapic_init>:

void
ioapic_init(void)
{
  108ff1:	55                   	push   %ebp
  108ff2:	89 e5                	mov    %esp,%ebp
  108ff4:	83 ec 38             	sub    $0x38,%esp
	int i, id, maxintr;

	if(!ismp)
  108ff7:	a1 5c 8f 38 00       	mov    0x388f5c,%eax
  108ffc:	85 c0                	test   %eax,%eax
  108ffe:	0f 84 fd 00 00 00    	je     109101 <ioapic_init+0x110>
		return;

	if (ioapic == NULL)
  109004:	a1 58 8f 38 00       	mov    0x388f58,%eax
  109009:	85 c0                	test   %eax,%eax
  10900b:	75 0a                	jne    109017 <ioapic_init+0x26>
		ioapic = mem_ptr(IOAPIC);	// assume default address
  10900d:	c7 05 58 8f 38 00 00 	movl   $0xfec00000,0x388f58
  109014:	00 c0 fe 

	maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
  109017:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  10901e:	e8 9d ff ff ff       	call   108fc0 <ioapic_read>
  109023:	c1 e8 10             	shr    $0x10,%eax
  109026:	25 ff 00 00 00       	and    $0xff,%eax
  10902b:	89 45 ec             	mov    %eax,-0x14(%ebp)
	id = ioapic_read(REG_ID) >> 24;
  10902e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  109035:	e8 86 ff ff ff       	call   108fc0 <ioapic_read>
  10903a:	c1 e8 18             	shr    $0x18,%eax
  10903d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (id == 0) {
  109040:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  109044:	75 2a                	jne    109070 <ioapic_init+0x7f>
		// I/O APIC ID not initialized yet - have to do it ourselves.
		ioapic_write(REG_ID, ioapicid << 24);
  109046:	0f b6 05 54 8f 38 00 	movzbl 0x388f54,%eax
  10904d:	0f b6 c0             	movzbl %al,%eax
  109050:	c1 e0 18             	shl    $0x18,%eax
  109053:	89 44 24 04          	mov    %eax,0x4(%esp)
  109057:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10905e:	e8 74 ff ff ff       	call   108fd7 <ioapic_write>
		id = ioapicid;
  109063:	0f b6 05 54 8f 38 00 	movzbl 0x388f54,%eax
  10906a:	0f b6 c0             	movzbl %al,%eax
  10906d:	89 45 f0             	mov    %eax,-0x10(%ebp)
	}
	if (id != ioapicid)
  109070:	0f b6 05 54 8f 38 00 	movzbl 0x388f54,%eax
  109077:	0f b6 c0             	movzbl %al,%eax
  10907a:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  10907d:	74 31                	je     1090b0 <ioapic_init+0xbf>
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);
  10907f:	0f b6 05 54 8f 38 00 	movzbl 0x388f54,%eax
  109086:	0f b6 c0             	movzbl %al,%eax
  109089:	89 44 24 10          	mov    %eax,0x10(%esp)
  10908d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  109090:	89 44 24 0c          	mov    %eax,0xc(%esp)
  109094:	c7 44 24 08 24 be 10 	movl   $0x10be24,0x8(%esp)
  10909b:	00 
  10909c:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  1090a3:	00 
  1090a4:	c7 04 24 45 be 10 00 	movl   $0x10be45,(%esp)
  1090ab:	e8 4e 79 ff ff       	call   1009fe <debug_warn>

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  1090b0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1090b7:	eb 3e                	jmp    1090f7 <ioapic_init+0x106>
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  1090b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1090bc:	83 c0 20             	add    $0x20,%eax
  1090bf:	0d 00 00 01 00       	or     $0x10000,%eax
  1090c4:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1090c7:	83 c2 08             	add    $0x8,%edx
  1090ca:	01 d2                	add    %edx,%edx
  1090cc:	89 44 24 04          	mov    %eax,0x4(%esp)
  1090d0:	89 14 24             	mov    %edx,(%esp)
  1090d3:	e8 ff fe ff ff       	call   108fd7 <ioapic_write>
		ioapic_write(REG_TABLE+2*i+1, 0);
  1090d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1090db:	83 c0 08             	add    $0x8,%eax
  1090de:	01 c0                	add    %eax,%eax
  1090e0:	83 c0 01             	add    $0x1,%eax
  1090e3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1090ea:	00 
  1090eb:	89 04 24             	mov    %eax,(%esp)
  1090ee:	e8 e4 fe ff ff       	call   108fd7 <ioapic_write>
	if (id != ioapicid)
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  1090f3:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1090f7:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1090fa:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  1090fd:	7e ba                	jle    1090b9 <ioapic_init+0xc8>
  1090ff:	eb 01                	jmp    109102 <ioapic_init+0x111>
ioapic_init(void)
{
	int i, id, maxintr;

	if(!ismp)
		return;
  109101:	90                   	nop
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
		ioapic_write(REG_TABLE+2*i+1, 0);
	}
}
  109102:	c9                   	leave  
  109103:	c3                   	ret    

00109104 <ioapic_enable>:

void
ioapic_enable(int irq)
{
  109104:	55                   	push   %ebp
  109105:	89 e5                	mov    %esp,%ebp
  109107:	83 ec 08             	sub    $0x8,%esp
	if (!ismp)
  10910a:	a1 5c 8f 38 00       	mov    0x388f5c,%eax
  10910f:	85 c0                	test   %eax,%eax
  109111:	74 3a                	je     10914d <ioapic_enable+0x49>
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
  109113:	8b 45 08             	mov    0x8(%ebp),%eax
  109116:	83 c0 20             	add    $0x20,%eax
  109119:	80 cc 09             	or     $0x9,%ah
	if (!ismp)
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
  10911c:	8b 55 08             	mov    0x8(%ebp),%edx
  10911f:	83 c2 08             	add    $0x8,%edx
  109122:	01 d2                	add    %edx,%edx
  109124:	89 44 24 04          	mov    %eax,0x4(%esp)
  109128:	89 14 24             	mov    %edx,(%esp)
  10912b:	e8 a7 fe ff ff       	call   108fd7 <ioapic_write>
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
  109130:	8b 45 08             	mov    0x8(%ebp),%eax
  109133:	83 c0 08             	add    $0x8,%eax
  109136:	01 c0                	add    %eax,%eax
  109138:	83 c0 01             	add    $0x1,%eax
  10913b:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  109142:	ff 
  109143:	89 04 24             	mov    %eax,(%esp)
  109146:	e8 8c fe ff ff       	call   108fd7 <ioapic_write>
  10914b:	eb 01                	jmp    10914e <ioapic_enable+0x4a>

void
ioapic_enable(int irq)
{
	if (!ismp)
		return;
  10914d:	90                   	nop
	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
}
  10914e:	c9                   	leave  
  10914f:	c3                   	ret    

00109150 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  109150:	55                   	push   %ebp
  109151:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  109153:	8b 45 08             	mov    0x8(%ebp),%eax
  109156:	8b 40 18             	mov    0x18(%eax),%eax
  109159:	83 e0 02             	and    $0x2,%eax
  10915c:	85 c0                	test   %eax,%eax
  10915e:	74 1c                	je     10917c <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  109160:	8b 45 0c             	mov    0xc(%ebp),%eax
  109163:	8b 00                	mov    (%eax),%eax
  109165:	8d 50 08             	lea    0x8(%eax),%edx
  109168:	8b 45 0c             	mov    0xc(%ebp),%eax
  10916b:	89 10                	mov    %edx,(%eax)
  10916d:	8b 45 0c             	mov    0xc(%ebp),%eax
  109170:	8b 00                	mov    (%eax),%eax
  109172:	83 e8 08             	sub    $0x8,%eax
  109175:	8b 50 04             	mov    0x4(%eax),%edx
  109178:	8b 00                	mov    (%eax),%eax
  10917a:	eb 47                	jmp    1091c3 <getuint+0x73>
	else if (st->flags & F_L)
  10917c:	8b 45 08             	mov    0x8(%ebp),%eax
  10917f:	8b 40 18             	mov    0x18(%eax),%eax
  109182:	83 e0 01             	and    $0x1,%eax
  109185:	85 c0                	test   %eax,%eax
  109187:	74 1e                	je     1091a7 <getuint+0x57>
		return va_arg(*ap, unsigned long);
  109189:	8b 45 0c             	mov    0xc(%ebp),%eax
  10918c:	8b 00                	mov    (%eax),%eax
  10918e:	8d 50 04             	lea    0x4(%eax),%edx
  109191:	8b 45 0c             	mov    0xc(%ebp),%eax
  109194:	89 10                	mov    %edx,(%eax)
  109196:	8b 45 0c             	mov    0xc(%ebp),%eax
  109199:	8b 00                	mov    (%eax),%eax
  10919b:	83 e8 04             	sub    $0x4,%eax
  10919e:	8b 00                	mov    (%eax),%eax
  1091a0:	ba 00 00 00 00       	mov    $0x0,%edx
  1091a5:	eb 1c                	jmp    1091c3 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  1091a7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1091aa:	8b 00                	mov    (%eax),%eax
  1091ac:	8d 50 04             	lea    0x4(%eax),%edx
  1091af:	8b 45 0c             	mov    0xc(%ebp),%eax
  1091b2:	89 10                	mov    %edx,(%eax)
  1091b4:	8b 45 0c             	mov    0xc(%ebp),%eax
  1091b7:	8b 00                	mov    (%eax),%eax
  1091b9:	83 e8 04             	sub    $0x4,%eax
  1091bc:	8b 00                	mov    (%eax),%eax
  1091be:	ba 00 00 00 00       	mov    $0x0,%edx
}
  1091c3:	5d                   	pop    %ebp
  1091c4:	c3                   	ret    

001091c5 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  1091c5:	55                   	push   %ebp
  1091c6:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  1091c8:	8b 45 08             	mov    0x8(%ebp),%eax
  1091cb:	8b 40 18             	mov    0x18(%eax),%eax
  1091ce:	83 e0 02             	and    $0x2,%eax
  1091d1:	85 c0                	test   %eax,%eax
  1091d3:	74 1c                	je     1091f1 <getint+0x2c>
		return va_arg(*ap, long long);
  1091d5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1091d8:	8b 00                	mov    (%eax),%eax
  1091da:	8d 50 08             	lea    0x8(%eax),%edx
  1091dd:	8b 45 0c             	mov    0xc(%ebp),%eax
  1091e0:	89 10                	mov    %edx,(%eax)
  1091e2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1091e5:	8b 00                	mov    (%eax),%eax
  1091e7:	83 e8 08             	sub    $0x8,%eax
  1091ea:	8b 50 04             	mov    0x4(%eax),%edx
  1091ed:	8b 00                	mov    (%eax),%eax
  1091ef:	eb 47                	jmp    109238 <getint+0x73>
	else if (st->flags & F_L)
  1091f1:	8b 45 08             	mov    0x8(%ebp),%eax
  1091f4:	8b 40 18             	mov    0x18(%eax),%eax
  1091f7:	83 e0 01             	and    $0x1,%eax
  1091fa:	85 c0                	test   %eax,%eax
  1091fc:	74 1e                	je     10921c <getint+0x57>
		return va_arg(*ap, long);
  1091fe:	8b 45 0c             	mov    0xc(%ebp),%eax
  109201:	8b 00                	mov    (%eax),%eax
  109203:	8d 50 04             	lea    0x4(%eax),%edx
  109206:	8b 45 0c             	mov    0xc(%ebp),%eax
  109209:	89 10                	mov    %edx,(%eax)
  10920b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10920e:	8b 00                	mov    (%eax),%eax
  109210:	83 e8 04             	sub    $0x4,%eax
  109213:	8b 00                	mov    (%eax),%eax
  109215:	89 c2                	mov    %eax,%edx
  109217:	c1 fa 1f             	sar    $0x1f,%edx
  10921a:	eb 1c                	jmp    109238 <getint+0x73>
	else
		return va_arg(*ap, int);
  10921c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10921f:	8b 00                	mov    (%eax),%eax
  109221:	8d 50 04             	lea    0x4(%eax),%edx
  109224:	8b 45 0c             	mov    0xc(%ebp),%eax
  109227:	89 10                	mov    %edx,(%eax)
  109229:	8b 45 0c             	mov    0xc(%ebp),%eax
  10922c:	8b 00                	mov    (%eax),%eax
  10922e:	83 e8 04             	sub    $0x4,%eax
  109231:	8b 00                	mov    (%eax),%eax
  109233:	89 c2                	mov    %eax,%edx
  109235:	c1 fa 1f             	sar    $0x1f,%edx
}
  109238:	5d                   	pop    %ebp
  109239:	c3                   	ret    

0010923a <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  10923a:	55                   	push   %ebp
  10923b:	89 e5                	mov    %esp,%ebp
  10923d:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  109240:	eb 1a                	jmp    10925c <putpad+0x22>
		st->putch(st->padc, st->putdat);
  109242:	8b 45 08             	mov    0x8(%ebp),%eax
  109245:	8b 00                	mov    (%eax),%eax
  109247:	8b 55 08             	mov    0x8(%ebp),%edx
  10924a:	8b 4a 04             	mov    0x4(%edx),%ecx
  10924d:	8b 55 08             	mov    0x8(%ebp),%edx
  109250:	8b 52 08             	mov    0x8(%edx),%edx
  109253:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  109257:	89 14 24             	mov    %edx,(%esp)
  10925a:	ff d0                	call   *%eax

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  10925c:	8b 45 08             	mov    0x8(%ebp),%eax
  10925f:	8b 40 0c             	mov    0xc(%eax),%eax
  109262:	8d 50 ff             	lea    -0x1(%eax),%edx
  109265:	8b 45 08             	mov    0x8(%ebp),%eax
  109268:	89 50 0c             	mov    %edx,0xc(%eax)
  10926b:	8b 45 08             	mov    0x8(%ebp),%eax
  10926e:	8b 40 0c             	mov    0xc(%eax),%eax
  109271:	85 c0                	test   %eax,%eax
  109273:	79 cd                	jns    109242 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  109275:	c9                   	leave  
  109276:	c3                   	ret    

00109277 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  109277:	55                   	push   %ebp
  109278:	89 e5                	mov    %esp,%ebp
  10927a:	53                   	push   %ebx
  10927b:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  10927e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  109282:	79 18                	jns    10929c <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  109284:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10928b:	00 
  10928c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10928f:	89 04 24             	mov    %eax,(%esp)
  109292:	e8 72 09 00 00       	call   109c09 <strchr>
  109297:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10929a:	eb 2e                	jmp    1092ca <putstr+0x53>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  10929c:	8b 45 10             	mov    0x10(%ebp),%eax
  10929f:	89 44 24 08          	mov    %eax,0x8(%esp)
  1092a3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1092aa:	00 
  1092ab:	8b 45 0c             	mov    0xc(%ebp),%eax
  1092ae:	89 04 24             	mov    %eax,(%esp)
  1092b1:	e8 50 0b 00 00       	call   109e06 <memchr>
  1092b6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1092b9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1092bd:	75 0b                	jne    1092ca <putstr+0x53>
		lim = str + maxlen;
  1092bf:	8b 55 10             	mov    0x10(%ebp),%edx
  1092c2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1092c5:	01 d0                	add    %edx,%eax
  1092c7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  1092ca:	8b 45 08             	mov    0x8(%ebp),%eax
  1092cd:	8b 40 0c             	mov    0xc(%eax),%eax
  1092d0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  1092d3:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1092d6:	89 cb                	mov    %ecx,%ebx
  1092d8:	29 d3                	sub    %edx,%ebx
  1092da:	89 da                	mov    %ebx,%edx
  1092dc:	01 c2                	add    %eax,%edx
  1092de:	8b 45 08             	mov    0x8(%ebp),%eax
  1092e1:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  1092e4:	8b 45 08             	mov    0x8(%ebp),%eax
  1092e7:	8b 40 18             	mov    0x18(%eax),%eax
  1092ea:	83 e0 10             	and    $0x10,%eax
  1092ed:	85 c0                	test   %eax,%eax
  1092ef:	75 32                	jne    109323 <putstr+0xac>
		putpad(st);		// (also leaves st->width == 0)
  1092f1:	8b 45 08             	mov    0x8(%ebp),%eax
  1092f4:	89 04 24             	mov    %eax,(%esp)
  1092f7:	e8 3e ff ff ff       	call   10923a <putpad>
	while (str < lim) {
  1092fc:	eb 25                	jmp    109323 <putstr+0xac>
		char ch = *str++;
  1092fe:	8b 45 0c             	mov    0xc(%ebp),%eax
  109301:	0f b6 00             	movzbl (%eax),%eax
  109304:	88 45 f3             	mov    %al,-0xd(%ebp)
  109307:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  10930b:	8b 45 08             	mov    0x8(%ebp),%eax
  10930e:	8b 00                	mov    (%eax),%eax
  109310:	8b 55 08             	mov    0x8(%ebp),%edx
  109313:	8b 4a 04             	mov    0x4(%edx),%ecx
  109316:	0f be 55 f3          	movsbl -0xd(%ebp),%edx
  10931a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  10931e:	89 14 24             	mov    %edx,(%esp)
  109321:	ff d0                	call   *%eax
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  109323:	8b 45 0c             	mov    0xc(%ebp),%eax
  109326:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  109329:	72 d3                	jb     1092fe <putstr+0x87>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  10932b:	8b 45 08             	mov    0x8(%ebp),%eax
  10932e:	89 04 24             	mov    %eax,(%esp)
  109331:	e8 04 ff ff ff       	call   10923a <putpad>
}
  109336:	83 c4 24             	add    $0x24,%esp
  109339:	5b                   	pop    %ebx
  10933a:	5d                   	pop    %ebp
  10933b:	c3                   	ret    

0010933c <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  10933c:	55                   	push   %ebp
  10933d:	89 e5                	mov    %esp,%ebp
  10933f:	53                   	push   %ebx
  109340:	83 ec 24             	sub    $0x24,%esp
  109343:	8b 45 10             	mov    0x10(%ebp),%eax
  109346:	89 45 f0             	mov    %eax,-0x10(%ebp)
  109349:	8b 45 14             	mov    0x14(%ebp),%eax
  10934c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  10934f:	8b 45 08             	mov    0x8(%ebp),%eax
  109352:	8b 40 1c             	mov    0x1c(%eax),%eax
  109355:	89 c2                	mov    %eax,%edx
  109357:	c1 fa 1f             	sar    $0x1f,%edx
  10935a:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  10935d:	77 4e                	ja     1093ad <genint+0x71>
  10935f:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  109362:	72 05                	jb     109369 <genint+0x2d>
  109364:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  109367:	77 44                	ja     1093ad <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  109369:	8b 45 08             	mov    0x8(%ebp),%eax
  10936c:	8b 40 1c             	mov    0x1c(%eax),%eax
  10936f:	89 c2                	mov    %eax,%edx
  109371:	c1 fa 1f             	sar    $0x1f,%edx
  109374:	89 44 24 08          	mov    %eax,0x8(%esp)
  109378:	89 54 24 0c          	mov    %edx,0xc(%esp)
  10937c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10937f:	8b 55 f4             	mov    -0xc(%ebp),%edx
  109382:	89 04 24             	mov    %eax,(%esp)
  109385:	89 54 24 04          	mov    %edx,0x4(%esp)
  109389:	e8 b2 0a 00 00       	call   109e40 <__udivdi3>
  10938e:	89 44 24 08          	mov    %eax,0x8(%esp)
  109392:	89 54 24 0c          	mov    %edx,0xc(%esp)
  109396:	8b 45 0c             	mov    0xc(%ebp),%eax
  109399:	89 44 24 04          	mov    %eax,0x4(%esp)
  10939d:	8b 45 08             	mov    0x8(%ebp),%eax
  1093a0:	89 04 24             	mov    %eax,(%esp)
  1093a3:	e8 94 ff ff ff       	call   10933c <genint>
  1093a8:	89 45 0c             	mov    %eax,0xc(%ebp)
  1093ab:	eb 1b                	jmp    1093c8 <genint+0x8c>
	else if (st->signc >= 0)
  1093ad:	8b 45 08             	mov    0x8(%ebp),%eax
  1093b0:	8b 40 14             	mov    0x14(%eax),%eax
  1093b3:	85 c0                	test   %eax,%eax
  1093b5:	78 11                	js     1093c8 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  1093b7:	8b 45 08             	mov    0x8(%ebp),%eax
  1093ba:	8b 40 14             	mov    0x14(%eax),%eax
  1093bd:	89 c2                	mov    %eax,%edx
  1093bf:	8b 45 0c             	mov    0xc(%ebp),%eax
  1093c2:	88 10                	mov    %dl,(%eax)
  1093c4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  1093c8:	8b 45 08             	mov    0x8(%ebp),%eax
  1093cb:	8b 40 1c             	mov    0x1c(%eax),%eax
  1093ce:	89 c1                	mov    %eax,%ecx
  1093d0:	89 c3                	mov    %eax,%ebx
  1093d2:	c1 fb 1f             	sar    $0x1f,%ebx
  1093d5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1093d8:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1093db:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  1093df:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  1093e3:	89 04 24             	mov    %eax,(%esp)
  1093e6:	89 54 24 04          	mov    %edx,0x4(%esp)
  1093ea:	e8 a1 0b 00 00       	call   109f90 <__umoddi3>
  1093ef:	05 54 be 10 00       	add    $0x10be54,%eax
  1093f4:	0f b6 10             	movzbl (%eax),%edx
  1093f7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1093fa:	88 10                	mov    %dl,(%eax)
  1093fc:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  109400:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  109403:	83 c4 24             	add    $0x24,%esp
  109406:	5b                   	pop    %ebx
  109407:	5d                   	pop    %ebp
  109408:	c3                   	ret    

00109409 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  109409:	55                   	push   %ebp
  10940a:	89 e5                	mov    %esp,%ebp
  10940c:	83 ec 58             	sub    $0x58,%esp
  10940f:	8b 45 0c             	mov    0xc(%ebp),%eax
  109412:	89 45 c0             	mov    %eax,-0x40(%ebp)
  109415:	8b 45 10             	mov    0x10(%ebp),%eax
  109418:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  10941b:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  10941e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  109421:	8b 45 08             	mov    0x8(%ebp),%eax
  109424:	8b 55 14             	mov    0x14(%ebp),%edx
  109427:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  10942a:	8b 45 c0             	mov    -0x40(%ebp),%eax
  10942d:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  109430:	89 44 24 08          	mov    %eax,0x8(%esp)
  109434:	89 54 24 0c          	mov    %edx,0xc(%esp)
  109438:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10943b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10943f:	8b 45 08             	mov    0x8(%ebp),%eax
  109442:	89 04 24             	mov    %eax,(%esp)
  109445:	e8 f2 fe ff ff       	call   10933c <genint>
  10944a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  10944d:	8b 55 f4             	mov    -0xc(%ebp),%edx
  109450:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  109453:	89 d1                	mov    %edx,%ecx
  109455:	29 c1                	sub    %eax,%ecx
  109457:	89 c8                	mov    %ecx,%eax
  109459:	89 44 24 08          	mov    %eax,0x8(%esp)
  10945d:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  109460:	89 44 24 04          	mov    %eax,0x4(%esp)
  109464:	8b 45 08             	mov    0x8(%ebp),%eax
  109467:	89 04 24             	mov    %eax,(%esp)
  10946a:	e8 08 fe ff ff       	call   109277 <putstr>
}
  10946f:	c9                   	leave  
  109470:	c3                   	ret    

00109471 <vprintfmt>:


// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  109471:	55                   	push   %ebp
  109472:	89 e5                	mov    %esp,%ebp
  109474:	53                   	push   %ebx
  109475:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  109478:	8d 55 cc             	lea    -0x34(%ebp),%edx
  10947b:	b9 00 00 00 00       	mov    $0x0,%ecx
  109480:	b8 20 00 00 00       	mov    $0x20,%eax
  109485:	89 c3                	mov    %eax,%ebx
  109487:	83 e3 fc             	and    $0xfffffffc,%ebx
  10948a:	b8 00 00 00 00       	mov    $0x0,%eax
  10948f:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  109492:	83 c0 04             	add    $0x4,%eax
  109495:	39 d8                	cmp    %ebx,%eax
  109497:	72 f6                	jb     10948f <vprintfmt+0x1e>
  109499:	01 c2                	add    %eax,%edx
  10949b:	8b 45 08             	mov    0x8(%ebp),%eax
  10949e:	89 45 cc             	mov    %eax,-0x34(%ebp)
  1094a1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1094a4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1094a7:	eb 17                	jmp    1094c0 <vprintfmt+0x4f>
			if (ch == '\0')
  1094a9:	85 db                	test   %ebx,%ebx
  1094ab:	0f 84 50 03 00 00    	je     109801 <vprintfmt+0x390>
				return;
			putch(ch, putdat);
  1094b1:	8b 45 0c             	mov    0xc(%ebp),%eax
  1094b4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1094b8:	89 1c 24             	mov    %ebx,(%esp)
  1094bb:	8b 45 08             	mov    0x8(%ebp),%eax
  1094be:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1094c0:	8b 45 10             	mov    0x10(%ebp),%eax
  1094c3:	0f b6 00             	movzbl (%eax),%eax
  1094c6:	0f b6 d8             	movzbl %al,%ebx
  1094c9:	83 fb 25             	cmp    $0x25,%ebx
  1094cc:	0f 95 c0             	setne  %al
  1094cf:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  1094d3:	84 c0                	test   %al,%al
  1094d5:	75 d2                	jne    1094a9 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  1094d7:	c7 45 d4 20 00 00 00 	movl   $0x20,-0x2c(%ebp)
		st.width = -1;
  1094de:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.prec = -1;
  1094e5:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.signc = -1;
  1094ec:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		st.flags = 0;
  1094f3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		st.base = 10;
  1094fa:	c7 45 e8 0a 00 00 00 	movl   $0xa,-0x18(%ebp)
  109501:	eb 04                	jmp    109507 <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  109503:	90                   	nop
  109504:	eb 01                	jmp    109507 <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  109506:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  109507:	8b 45 10             	mov    0x10(%ebp),%eax
  10950a:	0f b6 00             	movzbl (%eax),%eax
  10950d:	0f b6 d8             	movzbl %al,%ebx
  109510:	89 d8                	mov    %ebx,%eax
  109512:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  109516:	83 e8 20             	sub    $0x20,%eax
  109519:	83 f8 58             	cmp    $0x58,%eax
  10951c:	0f 87 ae 02 00 00    	ja     1097d0 <vprintfmt+0x35f>
  109522:	8b 04 85 6c be 10 00 	mov    0x10be6c(,%eax,4),%eax
  109529:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  10952b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10952e:	83 c8 10             	or     $0x10,%eax
  109531:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  109534:	eb d1                	jmp    109507 <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  109536:	c7 45 e0 2b 00 00 00 	movl   $0x2b,-0x20(%ebp)
			goto reswitch;
  10953d:	eb c8                	jmp    109507 <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  10953f:	8b 45 e0             	mov    -0x20(%ebp),%eax
  109542:	85 c0                	test   %eax,%eax
  109544:	79 bd                	jns    109503 <vprintfmt+0x92>
				st.signc = ' ';
  109546:	c7 45 e0 20 00 00 00 	movl   $0x20,-0x20(%ebp)
			goto reswitch;
  10954d:	eb b4                	jmp    109503 <vprintfmt+0x92>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  10954f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  109552:	83 e0 08             	and    $0x8,%eax
  109555:	85 c0                	test   %eax,%eax
  109557:	75 07                	jne    109560 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  109559:	c7 45 d4 30 00 00 00 	movl   $0x30,-0x2c(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  109560:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  109567:	8b 55 dc             	mov    -0x24(%ebp),%edx
  10956a:	89 d0                	mov    %edx,%eax
  10956c:	c1 e0 02             	shl    $0x2,%eax
  10956f:	01 d0                	add    %edx,%eax
  109571:	01 c0                	add    %eax,%eax
  109573:	01 d8                	add    %ebx,%eax
  109575:	83 e8 30             	sub    $0x30,%eax
  109578:	89 45 dc             	mov    %eax,-0x24(%ebp)
				ch = *fmt;
  10957b:	8b 45 10             	mov    0x10(%ebp),%eax
  10957e:	0f b6 00             	movzbl (%eax),%eax
  109581:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  109584:	83 fb 2f             	cmp    $0x2f,%ebx
  109587:	7e 21                	jle    1095aa <vprintfmt+0x139>
  109589:	83 fb 39             	cmp    $0x39,%ebx
  10958c:	7f 1c                	jg     1095aa <vprintfmt+0x139>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  10958e:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  109592:	eb d3                	jmp    109567 <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  109594:	8b 45 14             	mov    0x14(%ebp),%eax
  109597:	83 c0 04             	add    $0x4,%eax
  10959a:	89 45 14             	mov    %eax,0x14(%ebp)
  10959d:	8b 45 14             	mov    0x14(%ebp),%eax
  1095a0:	83 e8 04             	sub    $0x4,%eax
  1095a3:	8b 00                	mov    (%eax),%eax
  1095a5:	89 45 dc             	mov    %eax,-0x24(%ebp)
  1095a8:	eb 01                	jmp    1095ab <vprintfmt+0x13a>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  1095aa:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  1095ab:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1095ae:	83 e0 08             	and    $0x8,%eax
  1095b1:	85 c0                	test   %eax,%eax
  1095b3:	0f 85 4d ff ff ff    	jne    109506 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  1095b9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1095bc:	89 45 d8             	mov    %eax,-0x28(%ebp)
				st.prec = -1;
  1095bf:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
			}
			goto reswitch;
  1095c6:	e9 3b ff ff ff       	jmp    109506 <vprintfmt+0x95>

		case '.':
			st.flags |= F_DOT;
  1095cb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1095ce:	83 c8 08             	or     $0x8,%eax
  1095d1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  1095d4:	e9 2e ff ff ff       	jmp    109507 <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  1095d9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1095dc:	83 c8 04             	or     $0x4,%eax
  1095df:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  1095e2:	e9 20 ff ff ff       	jmp    109507 <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  1095e7:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1095ea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1095ed:	83 e0 01             	and    $0x1,%eax
  1095f0:	85 c0                	test   %eax,%eax
  1095f2:	74 07                	je     1095fb <vprintfmt+0x18a>
  1095f4:	b8 02 00 00 00       	mov    $0x2,%eax
  1095f9:	eb 05                	jmp    109600 <vprintfmt+0x18f>
  1095fb:	b8 01 00 00 00       	mov    $0x1,%eax
  109600:	09 d0                	or     %edx,%eax
  109602:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto reswitch;
  109605:	e9 fd fe ff ff       	jmp    109507 <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  10960a:	8b 45 14             	mov    0x14(%ebp),%eax
  10960d:	83 c0 04             	add    $0x4,%eax
  109610:	89 45 14             	mov    %eax,0x14(%ebp)
  109613:	8b 45 14             	mov    0x14(%ebp),%eax
  109616:	83 e8 04             	sub    $0x4,%eax
  109619:	8b 00                	mov    (%eax),%eax
  10961b:	8b 55 0c             	mov    0xc(%ebp),%edx
  10961e:	89 54 24 04          	mov    %edx,0x4(%esp)
  109622:	89 04 24             	mov    %eax,(%esp)
  109625:	8b 45 08             	mov    0x8(%ebp),%eax
  109628:	ff d0                	call   *%eax
			break;
  10962a:	e9 cc 01 00 00       	jmp    1097fb <vprintfmt+0x38a>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  10962f:	8b 45 14             	mov    0x14(%ebp),%eax
  109632:	83 c0 04             	add    $0x4,%eax
  109635:	89 45 14             	mov    %eax,0x14(%ebp)
  109638:	8b 45 14             	mov    0x14(%ebp),%eax
  10963b:	83 e8 04             	sub    $0x4,%eax
  10963e:	8b 00                	mov    (%eax),%eax
  109640:	89 45 ec             	mov    %eax,-0x14(%ebp)
  109643:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  109647:	75 07                	jne    109650 <vprintfmt+0x1df>
				s = "(null)";
  109649:	c7 45 ec 65 be 10 00 	movl   $0x10be65,-0x14(%ebp)
			putstr(&st, s, st.prec);
  109650:	8b 45 dc             	mov    -0x24(%ebp),%eax
  109653:	89 44 24 08          	mov    %eax,0x8(%esp)
  109657:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10965a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10965e:	8d 45 cc             	lea    -0x34(%ebp),%eax
  109661:	89 04 24             	mov    %eax,(%esp)
  109664:	e8 0e fc ff ff       	call   109277 <putstr>
			break;
  109669:	e9 8d 01 00 00       	jmp    1097fb <vprintfmt+0x38a>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  10966e:	8d 45 14             	lea    0x14(%ebp),%eax
  109671:	89 44 24 04          	mov    %eax,0x4(%esp)
  109675:	8d 45 cc             	lea    -0x34(%ebp),%eax
  109678:	89 04 24             	mov    %eax,(%esp)
  10967b:	e8 45 fb ff ff       	call   1091c5 <getint>
  109680:	89 45 f0             	mov    %eax,-0x10(%ebp)
  109683:	89 55 f4             	mov    %edx,-0xc(%ebp)
			if ((intmax_t) num < 0) {
  109686:	8b 45 f0             	mov    -0x10(%ebp),%eax
  109689:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10968c:	85 d2                	test   %edx,%edx
  10968e:	79 1a                	jns    1096aa <vprintfmt+0x239>
				num = -(intmax_t) num;
  109690:	8b 45 f0             	mov    -0x10(%ebp),%eax
  109693:	8b 55 f4             	mov    -0xc(%ebp),%edx
  109696:	f7 d8                	neg    %eax
  109698:	83 d2 00             	adc    $0x0,%edx
  10969b:	f7 da                	neg    %edx
  10969d:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1096a0:	89 55 f4             	mov    %edx,-0xc(%ebp)
				st.signc = '-';
  1096a3:	c7 45 e0 2d 00 00 00 	movl   $0x2d,-0x20(%ebp)
			}
			putint(&st, num, 10);
  1096aa:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  1096b1:	00 
  1096b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1096b5:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1096b8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1096bc:	89 54 24 08          	mov    %edx,0x8(%esp)
  1096c0:	8d 45 cc             	lea    -0x34(%ebp),%eax
  1096c3:	89 04 24             	mov    %eax,(%esp)
  1096c6:	e8 3e fd ff ff       	call   109409 <putint>
			break;
  1096cb:	e9 2b 01 00 00       	jmp    1097fb <vprintfmt+0x38a>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  1096d0:	8d 45 14             	lea    0x14(%ebp),%eax
  1096d3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1096d7:	8d 45 cc             	lea    -0x34(%ebp),%eax
  1096da:	89 04 24             	mov    %eax,(%esp)
  1096dd:	e8 6e fa ff ff       	call   109150 <getuint>
  1096e2:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  1096e9:	00 
  1096ea:	89 44 24 04          	mov    %eax,0x4(%esp)
  1096ee:	89 54 24 08          	mov    %edx,0x8(%esp)
  1096f2:	8d 45 cc             	lea    -0x34(%ebp),%eax
  1096f5:	89 04 24             	mov    %eax,(%esp)
  1096f8:	e8 0c fd ff ff       	call   109409 <putint>
			break;
  1096fd:	e9 f9 00 00 00       	jmp    1097fb <vprintfmt+0x38a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putint(&st, getuint(&st, &ap), 8);
  109702:	8d 45 14             	lea    0x14(%ebp),%eax
  109705:	89 44 24 04          	mov    %eax,0x4(%esp)
  109709:	8d 45 cc             	lea    -0x34(%ebp),%eax
  10970c:	89 04 24             	mov    %eax,(%esp)
  10970f:	e8 3c fa ff ff       	call   109150 <getuint>
  109714:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  10971b:	00 
  10971c:	89 44 24 04          	mov    %eax,0x4(%esp)
  109720:	89 54 24 08          	mov    %edx,0x8(%esp)
  109724:	8d 45 cc             	lea    -0x34(%ebp),%eax
  109727:	89 04 24             	mov    %eax,(%esp)
  10972a:	e8 da fc ff ff       	call   109409 <putint>
			break;
  10972f:	e9 c7 00 00 00       	jmp    1097fb <vprintfmt+0x38a>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  109734:	8d 45 14             	lea    0x14(%ebp),%eax
  109737:	89 44 24 04          	mov    %eax,0x4(%esp)
  10973b:	8d 45 cc             	lea    -0x34(%ebp),%eax
  10973e:	89 04 24             	mov    %eax,(%esp)
  109741:	e8 0a fa ff ff       	call   109150 <getuint>
  109746:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  10974d:	00 
  10974e:	89 44 24 04          	mov    %eax,0x4(%esp)
  109752:	89 54 24 08          	mov    %edx,0x8(%esp)
  109756:	8d 45 cc             	lea    -0x34(%ebp),%eax
  109759:	89 04 24             	mov    %eax,(%esp)
  10975c:	e8 a8 fc ff ff       	call   109409 <putint>
			break;
  109761:	e9 95 00 00 00       	jmp    1097fb <vprintfmt+0x38a>

		// pointer
		case 'p':
			putch('0', putdat);
  109766:	8b 45 0c             	mov    0xc(%ebp),%eax
  109769:	89 44 24 04          	mov    %eax,0x4(%esp)
  10976d:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  109774:	8b 45 08             	mov    0x8(%ebp),%eax
  109777:	ff d0                	call   *%eax
			putch('x', putdat);
  109779:	8b 45 0c             	mov    0xc(%ebp),%eax
  10977c:	89 44 24 04          	mov    %eax,0x4(%esp)
  109780:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  109787:	8b 45 08             	mov    0x8(%ebp),%eax
  10978a:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  10978c:	8b 45 14             	mov    0x14(%ebp),%eax
  10978f:	83 c0 04             	add    $0x4,%eax
  109792:	89 45 14             	mov    %eax,0x14(%ebp)
  109795:	8b 45 14             	mov    0x14(%ebp),%eax
  109798:	83 e8 04             	sub    $0x4,%eax
  10979b:	8b 00                	mov    (%eax),%eax
  10979d:	ba 00 00 00 00       	mov    $0x0,%edx
  1097a2:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  1097a9:	00 
  1097aa:	89 44 24 04          	mov    %eax,0x4(%esp)
  1097ae:	89 54 24 08          	mov    %edx,0x8(%esp)
  1097b2:	8d 45 cc             	lea    -0x34(%ebp),%eax
  1097b5:	89 04 24             	mov    %eax,(%esp)
  1097b8:	e8 4c fc ff ff       	call   109409 <putint>
			break;
  1097bd:	eb 3c                	jmp    1097fb <vprintfmt+0x38a>


		// escaped '%' character
		case '%':
			putch(ch, putdat);
  1097bf:	8b 45 0c             	mov    0xc(%ebp),%eax
  1097c2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1097c6:	89 1c 24             	mov    %ebx,(%esp)
  1097c9:	8b 45 08             	mov    0x8(%ebp),%eax
  1097cc:	ff d0                	call   *%eax
			break;
  1097ce:	eb 2b                	jmp    1097fb <vprintfmt+0x38a>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  1097d0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1097d3:	89 44 24 04          	mov    %eax,0x4(%esp)
  1097d7:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  1097de:	8b 45 08             	mov    0x8(%ebp),%eax
  1097e1:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  1097e3:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1097e7:	eb 04                	jmp    1097ed <vprintfmt+0x37c>
  1097e9:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  1097ed:	8b 45 10             	mov    0x10(%ebp),%eax
  1097f0:	83 e8 01             	sub    $0x1,%eax
  1097f3:	0f b6 00             	movzbl (%eax),%eax
  1097f6:	3c 25                	cmp    $0x25,%al
  1097f8:	75 ef                	jne    1097e9 <vprintfmt+0x378>
				/* do nothing */;
			break;
  1097fa:	90                   	nop
		}
	}
  1097fb:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  1097fc:	e9 bf fc ff ff       	jmp    1094c0 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  109801:	83 c4 44             	add    $0x44,%esp
  109804:	5b                   	pop    %ebx
  109805:	5d                   	pop    %ebp
  109806:	c3                   	ret    
  109807:	90                   	nop

00109808 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  109808:	55                   	push   %ebp
  109809:	89 e5                	mov    %esp,%ebp
  10980b:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  10980e:	8b 45 0c             	mov    0xc(%ebp),%eax
  109811:	8b 00                	mov    (%eax),%eax
  109813:	8b 55 08             	mov    0x8(%ebp),%edx
  109816:	89 d1                	mov    %edx,%ecx
  109818:	8b 55 0c             	mov    0xc(%ebp),%edx
  10981b:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  10981f:	8d 50 01             	lea    0x1(%eax),%edx
  109822:	8b 45 0c             	mov    0xc(%ebp),%eax
  109825:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  109827:	8b 45 0c             	mov    0xc(%ebp),%eax
  10982a:	8b 00                	mov    (%eax),%eax
  10982c:	3d ff 00 00 00       	cmp    $0xff,%eax
  109831:	75 24                	jne    109857 <putch+0x4f>
		b->buf[b->idx] = 0;
  109833:	8b 45 0c             	mov    0xc(%ebp),%eax
  109836:	8b 00                	mov    (%eax),%eax
  109838:	8b 55 0c             	mov    0xc(%ebp),%edx
  10983b:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  109840:	8b 45 0c             	mov    0xc(%ebp),%eax
  109843:	83 c0 08             	add    $0x8,%eax
  109846:	89 04 24             	mov    %eax,(%esp)
  109849:	e8 99 6e ff ff       	call   1006e7 <cputs>
		b->idx = 0;
  10984e:	8b 45 0c             	mov    0xc(%ebp),%eax
  109851:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  109857:	8b 45 0c             	mov    0xc(%ebp),%eax
  10985a:	8b 40 04             	mov    0x4(%eax),%eax
  10985d:	8d 50 01             	lea    0x1(%eax),%edx
  109860:	8b 45 0c             	mov    0xc(%ebp),%eax
  109863:	89 50 04             	mov    %edx,0x4(%eax)
}
  109866:	c9                   	leave  
  109867:	c3                   	ret    

00109868 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  109868:	55                   	push   %ebp
  109869:	89 e5                	mov    %esp,%ebp
  10986b:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  109871:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  109878:	00 00 00 
	b.cnt = 0;
  10987b:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  109882:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  109885:	8b 45 0c             	mov    0xc(%ebp),%eax
  109888:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10988c:	8b 45 08             	mov    0x8(%ebp),%eax
  10988f:	89 44 24 08          	mov    %eax,0x8(%esp)
  109893:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  109899:	89 44 24 04          	mov    %eax,0x4(%esp)
  10989d:	c7 04 24 08 98 10 00 	movl   $0x109808,(%esp)
  1098a4:	e8 c8 fb ff ff       	call   109471 <vprintfmt>

	b.buf[b.idx] = 0;
  1098a9:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  1098af:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  1098b6:	00 
	cputs(b.buf);
  1098b7:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  1098bd:	83 c0 08             	add    $0x8,%eax
  1098c0:	89 04 24             	mov    %eax,(%esp)
  1098c3:	e8 1f 6e ff ff       	call   1006e7 <cputs>

	return b.cnt;
  1098c8:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  1098ce:	c9                   	leave  
  1098cf:	c3                   	ret    

001098d0 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  1098d0:	55                   	push   %ebp
  1098d1:	89 e5                	mov    %esp,%ebp
  1098d3:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  1098d6:	8d 45 0c             	lea    0xc(%ebp),%eax
  1098d9:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cnt = vcprintf(fmt, ap);
  1098dc:	8b 45 08             	mov    0x8(%ebp),%eax
  1098df:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1098e2:	89 54 24 04          	mov    %edx,0x4(%esp)
  1098e6:	89 04 24             	mov    %eax,(%esp)
  1098e9:	e8 7a ff ff ff       	call   109868 <vcprintf>
  1098ee:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return cnt;
  1098f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1098f4:	c9                   	leave  
  1098f5:	c3                   	ret    
  1098f6:	66 90                	xchg   %ax,%ax

001098f8 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  1098f8:	55                   	push   %ebp
  1098f9:	89 e5                	mov    %esp,%ebp
	b->cnt++;
  1098fb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1098fe:	8b 40 08             	mov    0x8(%eax),%eax
  109901:	8d 50 01             	lea    0x1(%eax),%edx
  109904:	8b 45 0c             	mov    0xc(%ebp),%eax
  109907:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
  10990a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10990d:	8b 10                	mov    (%eax),%edx
  10990f:	8b 45 0c             	mov    0xc(%ebp),%eax
  109912:	8b 40 04             	mov    0x4(%eax),%eax
  109915:	39 c2                	cmp    %eax,%edx
  109917:	73 12                	jae    10992b <sprintputch+0x33>
		*b->buf++ = ch;
  109919:	8b 45 0c             	mov    0xc(%ebp),%eax
  10991c:	8b 00                	mov    (%eax),%eax
  10991e:	8b 55 08             	mov    0x8(%ebp),%edx
  109921:	88 10                	mov    %dl,(%eax)
  109923:	8d 50 01             	lea    0x1(%eax),%edx
  109926:	8b 45 0c             	mov    0xc(%ebp),%eax
  109929:	89 10                	mov    %edx,(%eax)
}
  10992b:	5d                   	pop    %ebp
  10992c:	c3                   	ret    

0010992d <vsprintf>:

int
vsprintf(char *buf, const char *fmt, va_list ap)
{
  10992d:	55                   	push   %ebp
  10992e:	89 e5                	mov    %esp,%ebp
  109930:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL);
  109933:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  109937:	75 24                	jne    10995d <vsprintf+0x30>
  109939:	c7 44 24 0c d0 bf 10 	movl   $0x10bfd0,0xc(%esp)
  109940:	00 
  109941:	c7 44 24 08 dc bf 10 	movl   $0x10bfdc,0x8(%esp)
  109948:	00 
  109949:	c7 44 24 04 19 00 00 	movl   $0x19,0x4(%esp)
  109950:	00 
  109951:	c7 04 24 f1 bf 10 00 	movl   $0x10bff1,(%esp)
  109958:	e8 db 6f ff ff       	call   100938 <debug_panic>
	struct sprintbuf b = {buf, (char*)(intptr_t)~0, 0};
  10995d:	8b 45 08             	mov    0x8(%ebp),%eax
  109960:	89 45 ec             	mov    %eax,-0x14(%ebp)
  109963:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
  10996a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  109971:	8b 45 10             	mov    0x10(%ebp),%eax
  109974:	89 44 24 0c          	mov    %eax,0xc(%esp)
  109978:	8b 45 0c             	mov    0xc(%ebp),%eax
  10997b:	89 44 24 08          	mov    %eax,0x8(%esp)
  10997f:	8d 45 ec             	lea    -0x14(%ebp),%eax
  109982:	89 44 24 04          	mov    %eax,0x4(%esp)
  109986:	c7 04 24 f8 98 10 00 	movl   $0x1098f8,(%esp)
  10998d:	e8 df fa ff ff       	call   109471 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  109992:	8b 45 ec             	mov    -0x14(%ebp),%eax
  109995:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  109998:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  10999b:	c9                   	leave  
  10999c:	c3                   	ret    

0010999d <sprintf>:

int
sprintf(char *buf, const char *fmt, ...)
{
  10999d:	55                   	push   %ebp
  10999e:	89 e5                	mov    %esp,%ebp
  1099a0:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  1099a3:	8d 45 0c             	lea    0xc(%ebp),%eax
  1099a6:	83 c0 04             	add    $0x4,%eax
  1099a9:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsprintf(buf, fmt, ap);
  1099ac:	8b 45 0c             	mov    0xc(%ebp),%eax
  1099af:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1099b2:	89 54 24 08          	mov    %edx,0x8(%esp)
  1099b6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1099ba:	8b 45 08             	mov    0x8(%ebp),%eax
  1099bd:	89 04 24             	mov    %eax,(%esp)
  1099c0:	e8 68 ff ff ff       	call   10992d <vsprintf>
  1099c5:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
  1099c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1099cb:	c9                   	leave  
  1099cc:	c3                   	ret    

001099cd <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  1099cd:	55                   	push   %ebp
  1099ce:	89 e5                	mov    %esp,%ebp
  1099d0:	83 ec 28             	sub    $0x28,%esp
	assert(buf != NULL && n > 0);
  1099d3:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  1099d7:	74 06                	je     1099df <vsnprintf+0x12>
  1099d9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  1099dd:	7f 24                	jg     109a03 <vsnprintf+0x36>
  1099df:	c7 44 24 0c ff bf 10 	movl   $0x10bfff,0xc(%esp)
  1099e6:	00 
  1099e7:	c7 44 24 08 dc bf 10 	movl   $0x10bfdc,0x8(%esp)
  1099ee:	00 
  1099ef:	c7 44 24 04 35 00 00 	movl   $0x35,0x4(%esp)
  1099f6:	00 
  1099f7:	c7 04 24 f1 bf 10 00 	movl   $0x10bff1,(%esp)
  1099fe:	e8 35 6f ff ff       	call   100938 <debug_panic>
	struct sprintbuf b = {buf, buf+n-1, 0};
  109a03:	8b 45 08             	mov    0x8(%ebp),%eax
  109a06:	89 45 ec             	mov    %eax,-0x14(%ebp)
  109a09:	8b 45 0c             	mov    0xc(%ebp),%eax
  109a0c:	8d 50 ff             	lea    -0x1(%eax),%edx
  109a0f:	8b 45 08             	mov    0x8(%ebp),%eax
  109a12:	01 d0                	add    %edx,%eax
  109a14:	89 45 f0             	mov    %eax,-0x10(%ebp)
  109a17:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  109a1e:	8b 45 14             	mov    0x14(%ebp),%eax
  109a21:	89 44 24 0c          	mov    %eax,0xc(%esp)
  109a25:	8b 45 10             	mov    0x10(%ebp),%eax
  109a28:	89 44 24 08          	mov    %eax,0x8(%esp)
  109a2c:	8d 45 ec             	lea    -0x14(%ebp),%eax
  109a2f:	89 44 24 04          	mov    %eax,0x4(%esp)
  109a33:	c7 04 24 f8 98 10 00 	movl   $0x1098f8,(%esp)
  109a3a:	e8 32 fa ff ff       	call   109471 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  109a3f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  109a42:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  109a45:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  109a48:	c9                   	leave  
  109a49:	c3                   	ret    

00109a4a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  109a4a:	55                   	push   %ebp
  109a4b:	89 e5                	mov    %esp,%ebp
  109a4d:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  109a50:	8d 45 10             	lea    0x10(%ebp),%eax
  109a53:	83 c0 04             	add    $0x4,%eax
  109a56:	89 45 f4             	mov    %eax,-0xc(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
  109a59:	8b 45 10             	mov    0x10(%ebp),%eax
  109a5c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  109a5f:	89 54 24 0c          	mov    %edx,0xc(%esp)
  109a63:	89 44 24 08          	mov    %eax,0x8(%esp)
  109a67:	8b 45 0c             	mov    0xc(%ebp),%eax
  109a6a:	89 44 24 04          	mov    %eax,0x4(%esp)
  109a6e:	8b 45 08             	mov    0x8(%ebp),%eax
  109a71:	89 04 24             	mov    %eax,(%esp)
  109a74:	e8 54 ff ff ff       	call   1099cd <vsnprintf>
  109a79:	89 45 f0             	mov    %eax,-0x10(%ebp)
	va_end(ap);

	return rc;
  109a7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  109a7f:	c9                   	leave  
  109a80:	c3                   	ret    
  109a81:	66 90                	xchg   %ax,%ax
  109a83:	90                   	nop

00109a84 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  109a84:	55                   	push   %ebp
  109a85:	89 e5                	mov    %esp,%ebp
  109a87:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  109a8a:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  109a91:	eb 08                	jmp    109a9b <strlen+0x17>
		n++;
  109a93:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  109a97:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  109a9b:	8b 45 08             	mov    0x8(%ebp),%eax
  109a9e:	0f b6 00             	movzbl (%eax),%eax
  109aa1:	84 c0                	test   %al,%al
  109aa3:	75 ee                	jne    109a93 <strlen+0xf>
		n++;
	return n;
  109aa5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  109aa8:	c9                   	leave  
  109aa9:	c3                   	ret    

00109aaa <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  109aaa:	55                   	push   %ebp
  109aab:	89 e5                	mov    %esp,%ebp
  109aad:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  109ab0:	8b 45 08             	mov    0x8(%ebp),%eax
  109ab3:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  109ab6:	90                   	nop
  109ab7:	8b 45 0c             	mov    0xc(%ebp),%eax
  109aba:	0f b6 10             	movzbl (%eax),%edx
  109abd:	8b 45 08             	mov    0x8(%ebp),%eax
  109ac0:	88 10                	mov    %dl,(%eax)
  109ac2:	8b 45 08             	mov    0x8(%ebp),%eax
  109ac5:	0f b6 00             	movzbl (%eax),%eax
  109ac8:	84 c0                	test   %al,%al
  109aca:	0f 95 c0             	setne  %al
  109acd:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  109ad1:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  109ad5:	84 c0                	test   %al,%al
  109ad7:	75 de                	jne    109ab7 <strcpy+0xd>
		/* do nothing */;
	return ret;
  109ad9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  109adc:	c9                   	leave  
  109add:	c3                   	ret    

00109ade <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  109ade:	55                   	push   %ebp
  109adf:	89 e5                	mov    %esp,%ebp
  109ae1:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  109ae4:	8b 45 08             	mov    0x8(%ebp),%eax
  109ae7:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
  109aea:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  109af1:	eb 21                	jmp    109b14 <strncpy+0x36>
		*dst++ = *src;
  109af3:	8b 45 0c             	mov    0xc(%ebp),%eax
  109af6:	0f b6 10             	movzbl (%eax),%edx
  109af9:	8b 45 08             	mov    0x8(%ebp),%eax
  109afc:	88 10                	mov    %dl,(%eax)
  109afe:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  109b02:	8b 45 0c             	mov    0xc(%ebp),%eax
  109b05:	0f b6 00             	movzbl (%eax),%eax
  109b08:	84 c0                	test   %al,%al
  109b0a:	74 04                	je     109b10 <strncpy+0x32>
			src++;
  109b0c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  109b10:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  109b14:	8b 45 fc             	mov    -0x4(%ebp),%eax
  109b17:	3b 45 10             	cmp    0x10(%ebp),%eax
  109b1a:	72 d7                	jb     109af3 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  109b1c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
  109b1f:	c9                   	leave  
  109b20:	c3                   	ret    

00109b21 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  109b21:	55                   	push   %ebp
  109b22:	89 e5                	mov    %esp,%ebp
  109b24:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  109b27:	8b 45 08             	mov    0x8(%ebp),%eax
  109b2a:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  109b2d:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  109b31:	74 2f                	je     109b62 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  109b33:	eb 13                	jmp    109b48 <strlcpy+0x27>
			*dst++ = *src++;
  109b35:	8b 45 0c             	mov    0xc(%ebp),%eax
  109b38:	0f b6 10             	movzbl (%eax),%edx
  109b3b:	8b 45 08             	mov    0x8(%ebp),%eax
  109b3e:	88 10                	mov    %dl,(%eax)
  109b40:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  109b44:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  109b48:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  109b4c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  109b50:	74 0a                	je     109b5c <strlcpy+0x3b>
  109b52:	8b 45 0c             	mov    0xc(%ebp),%eax
  109b55:	0f b6 00             	movzbl (%eax),%eax
  109b58:	84 c0                	test   %al,%al
  109b5a:	75 d9                	jne    109b35 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  109b5c:	8b 45 08             	mov    0x8(%ebp),%eax
  109b5f:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  109b62:	8b 55 08             	mov    0x8(%ebp),%edx
  109b65:	8b 45 fc             	mov    -0x4(%ebp),%eax
  109b68:	89 d1                	mov    %edx,%ecx
  109b6a:	29 c1                	sub    %eax,%ecx
  109b6c:	89 c8                	mov    %ecx,%eax
}
  109b6e:	c9                   	leave  
  109b6f:	c3                   	ret    

00109b70 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  109b70:	55                   	push   %ebp
  109b71:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  109b73:	eb 08                	jmp    109b7d <strcmp+0xd>
		p++, q++;
  109b75:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  109b79:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  109b7d:	8b 45 08             	mov    0x8(%ebp),%eax
  109b80:	0f b6 00             	movzbl (%eax),%eax
  109b83:	84 c0                	test   %al,%al
  109b85:	74 10                	je     109b97 <strcmp+0x27>
  109b87:	8b 45 08             	mov    0x8(%ebp),%eax
  109b8a:	0f b6 10             	movzbl (%eax),%edx
  109b8d:	8b 45 0c             	mov    0xc(%ebp),%eax
  109b90:	0f b6 00             	movzbl (%eax),%eax
  109b93:	38 c2                	cmp    %al,%dl
  109b95:	74 de                	je     109b75 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  109b97:	8b 45 08             	mov    0x8(%ebp),%eax
  109b9a:	0f b6 00             	movzbl (%eax),%eax
  109b9d:	0f b6 d0             	movzbl %al,%edx
  109ba0:	8b 45 0c             	mov    0xc(%ebp),%eax
  109ba3:	0f b6 00             	movzbl (%eax),%eax
  109ba6:	0f b6 c0             	movzbl %al,%eax
  109ba9:	89 d1                	mov    %edx,%ecx
  109bab:	29 c1                	sub    %eax,%ecx
  109bad:	89 c8                	mov    %ecx,%eax
}
  109baf:	5d                   	pop    %ebp
  109bb0:	c3                   	ret    

00109bb1 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  109bb1:	55                   	push   %ebp
  109bb2:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  109bb4:	eb 0c                	jmp    109bc2 <strncmp+0x11>
		n--, p++, q++;
  109bb6:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  109bba:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  109bbe:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  109bc2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  109bc6:	74 1a                	je     109be2 <strncmp+0x31>
  109bc8:	8b 45 08             	mov    0x8(%ebp),%eax
  109bcb:	0f b6 00             	movzbl (%eax),%eax
  109bce:	84 c0                	test   %al,%al
  109bd0:	74 10                	je     109be2 <strncmp+0x31>
  109bd2:	8b 45 08             	mov    0x8(%ebp),%eax
  109bd5:	0f b6 10             	movzbl (%eax),%edx
  109bd8:	8b 45 0c             	mov    0xc(%ebp),%eax
  109bdb:	0f b6 00             	movzbl (%eax),%eax
  109bde:	38 c2                	cmp    %al,%dl
  109be0:	74 d4                	je     109bb6 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  109be2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  109be6:	75 07                	jne    109bef <strncmp+0x3e>
		return 0;
  109be8:	b8 00 00 00 00       	mov    $0x0,%eax
  109bed:	eb 18                	jmp    109c07 <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  109bef:	8b 45 08             	mov    0x8(%ebp),%eax
  109bf2:	0f b6 00             	movzbl (%eax),%eax
  109bf5:	0f b6 d0             	movzbl %al,%edx
  109bf8:	8b 45 0c             	mov    0xc(%ebp),%eax
  109bfb:	0f b6 00             	movzbl (%eax),%eax
  109bfe:	0f b6 c0             	movzbl %al,%eax
  109c01:	89 d1                	mov    %edx,%ecx
  109c03:	29 c1                	sub    %eax,%ecx
  109c05:	89 c8                	mov    %ecx,%eax
}
  109c07:	5d                   	pop    %ebp
  109c08:	c3                   	ret    

00109c09 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  109c09:	55                   	push   %ebp
  109c0a:	89 e5                	mov    %esp,%ebp
  109c0c:	83 ec 04             	sub    $0x4,%esp
  109c0f:	8b 45 0c             	mov    0xc(%ebp),%eax
  109c12:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  109c15:	eb 1a                	jmp    109c31 <strchr+0x28>
		if (*s++ == 0)
  109c17:	8b 45 08             	mov    0x8(%ebp),%eax
  109c1a:	0f b6 00             	movzbl (%eax),%eax
  109c1d:	84 c0                	test   %al,%al
  109c1f:	0f 94 c0             	sete   %al
  109c22:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  109c26:	84 c0                	test   %al,%al
  109c28:	74 07                	je     109c31 <strchr+0x28>
			return NULL;
  109c2a:	b8 00 00 00 00       	mov    $0x0,%eax
  109c2f:	eb 0e                	jmp    109c3f <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  109c31:	8b 45 08             	mov    0x8(%ebp),%eax
  109c34:	0f b6 00             	movzbl (%eax),%eax
  109c37:	3a 45 fc             	cmp    -0x4(%ebp),%al
  109c3a:	75 db                	jne    109c17 <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  109c3c:	8b 45 08             	mov    0x8(%ebp),%eax
}
  109c3f:	c9                   	leave  
  109c40:	c3                   	ret    

00109c41 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  109c41:	55                   	push   %ebp
  109c42:	89 e5                	mov    %esp,%ebp
  109c44:	57                   	push   %edi
	char *p;

	if (n == 0)
  109c45:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  109c49:	75 05                	jne    109c50 <memset+0xf>
		return v;
  109c4b:	8b 45 08             	mov    0x8(%ebp),%eax
  109c4e:	eb 5c                	jmp    109cac <memset+0x6b>
	if ((int)v%4 == 0 && n%4 == 0) {
  109c50:	8b 45 08             	mov    0x8(%ebp),%eax
  109c53:	83 e0 03             	and    $0x3,%eax
  109c56:	85 c0                	test   %eax,%eax
  109c58:	75 41                	jne    109c9b <memset+0x5a>
  109c5a:	8b 45 10             	mov    0x10(%ebp),%eax
  109c5d:	83 e0 03             	and    $0x3,%eax
  109c60:	85 c0                	test   %eax,%eax
  109c62:	75 37                	jne    109c9b <memset+0x5a>
		c &= 0xFF;
  109c64:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  109c6b:	8b 45 0c             	mov    0xc(%ebp),%eax
  109c6e:	89 c2                	mov    %eax,%edx
  109c70:	c1 e2 18             	shl    $0x18,%edx
  109c73:	8b 45 0c             	mov    0xc(%ebp),%eax
  109c76:	c1 e0 10             	shl    $0x10,%eax
  109c79:	09 c2                	or     %eax,%edx
  109c7b:	8b 45 0c             	mov    0xc(%ebp),%eax
  109c7e:	c1 e0 08             	shl    $0x8,%eax
  109c81:	09 d0                	or     %edx,%eax
  109c83:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  109c86:	8b 45 10             	mov    0x10(%ebp),%eax
  109c89:	89 c1                	mov    %eax,%ecx
  109c8b:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  109c8e:	8b 55 08             	mov    0x8(%ebp),%edx
  109c91:	8b 45 0c             	mov    0xc(%ebp),%eax
  109c94:	89 d7                	mov    %edx,%edi
  109c96:	fc                   	cld    
  109c97:	f3 ab                	rep stos %eax,%es:(%edi)
  109c99:	eb 0e                	jmp    109ca9 <memset+0x68>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  109c9b:	8b 55 08             	mov    0x8(%ebp),%edx
  109c9e:	8b 45 0c             	mov    0xc(%ebp),%eax
  109ca1:	8b 4d 10             	mov    0x10(%ebp),%ecx
  109ca4:	89 d7                	mov    %edx,%edi
  109ca6:	fc                   	cld    
  109ca7:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  109ca9:	8b 45 08             	mov    0x8(%ebp),%eax
}
  109cac:	5f                   	pop    %edi
  109cad:	5d                   	pop    %ebp
  109cae:	c3                   	ret    

00109caf <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  109caf:	55                   	push   %ebp
  109cb0:	89 e5                	mov    %esp,%ebp
  109cb2:	57                   	push   %edi
  109cb3:	56                   	push   %esi
  109cb4:	53                   	push   %ebx
  109cb5:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  109cb8:	8b 45 0c             	mov    0xc(%ebp),%eax
  109cbb:	89 45 f0             	mov    %eax,-0x10(%ebp)
	d = dst;
  109cbe:	8b 45 08             	mov    0x8(%ebp),%eax
  109cc1:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (s < d && s + n > d) {
  109cc4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  109cc7:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  109cca:	73 6d                	jae    109d39 <memmove+0x8a>
  109ccc:	8b 45 10             	mov    0x10(%ebp),%eax
  109ccf:	8b 55 f0             	mov    -0x10(%ebp),%edx
  109cd2:	01 d0                	add    %edx,%eax
  109cd4:	3b 45 ec             	cmp    -0x14(%ebp),%eax
  109cd7:	76 60                	jbe    109d39 <memmove+0x8a>
		s += n;
  109cd9:	8b 45 10             	mov    0x10(%ebp),%eax
  109cdc:	01 45 f0             	add    %eax,-0x10(%ebp)
		d += n;
  109cdf:	8b 45 10             	mov    0x10(%ebp),%eax
  109ce2:	01 45 ec             	add    %eax,-0x14(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  109ce5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  109ce8:	83 e0 03             	and    $0x3,%eax
  109ceb:	85 c0                	test   %eax,%eax
  109ced:	75 2f                	jne    109d1e <memmove+0x6f>
  109cef:	8b 45 ec             	mov    -0x14(%ebp),%eax
  109cf2:	83 e0 03             	and    $0x3,%eax
  109cf5:	85 c0                	test   %eax,%eax
  109cf7:	75 25                	jne    109d1e <memmove+0x6f>
  109cf9:	8b 45 10             	mov    0x10(%ebp),%eax
  109cfc:	83 e0 03             	and    $0x3,%eax
  109cff:	85 c0                	test   %eax,%eax
  109d01:	75 1b                	jne    109d1e <memmove+0x6f>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  109d03:	8b 45 ec             	mov    -0x14(%ebp),%eax
  109d06:	83 e8 04             	sub    $0x4,%eax
  109d09:	8b 55 f0             	mov    -0x10(%ebp),%edx
  109d0c:	83 ea 04             	sub    $0x4,%edx
  109d0f:	8b 4d 10             	mov    0x10(%ebp),%ecx
  109d12:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  109d15:	89 c7                	mov    %eax,%edi
  109d17:	89 d6                	mov    %edx,%esi
  109d19:	fd                   	std    
  109d1a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  109d1c:	eb 18                	jmp    109d36 <memmove+0x87>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  109d1e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  109d21:	8d 50 ff             	lea    -0x1(%eax),%edx
  109d24:	8b 45 f0             	mov    -0x10(%ebp),%eax
  109d27:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  109d2a:	8b 45 10             	mov    0x10(%ebp),%eax
  109d2d:	89 d7                	mov    %edx,%edi
  109d2f:	89 de                	mov    %ebx,%esi
  109d31:	89 c1                	mov    %eax,%ecx
  109d33:	fd                   	std    
  109d34:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  109d36:	fc                   	cld    
  109d37:	eb 45                	jmp    109d7e <memmove+0xcf>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  109d39:	8b 45 f0             	mov    -0x10(%ebp),%eax
  109d3c:	83 e0 03             	and    $0x3,%eax
  109d3f:	85 c0                	test   %eax,%eax
  109d41:	75 2b                	jne    109d6e <memmove+0xbf>
  109d43:	8b 45 ec             	mov    -0x14(%ebp),%eax
  109d46:	83 e0 03             	and    $0x3,%eax
  109d49:	85 c0                	test   %eax,%eax
  109d4b:	75 21                	jne    109d6e <memmove+0xbf>
  109d4d:	8b 45 10             	mov    0x10(%ebp),%eax
  109d50:	83 e0 03             	and    $0x3,%eax
  109d53:	85 c0                	test   %eax,%eax
  109d55:	75 17                	jne    109d6e <memmove+0xbf>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  109d57:	8b 45 10             	mov    0x10(%ebp),%eax
  109d5a:	89 c1                	mov    %eax,%ecx
  109d5c:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  109d5f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  109d62:	8b 55 f0             	mov    -0x10(%ebp),%edx
  109d65:	89 c7                	mov    %eax,%edi
  109d67:	89 d6                	mov    %edx,%esi
  109d69:	fc                   	cld    
  109d6a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  109d6c:	eb 10                	jmp    109d7e <memmove+0xcf>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  109d6e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  109d71:	8b 55 f0             	mov    -0x10(%ebp),%edx
  109d74:	8b 4d 10             	mov    0x10(%ebp),%ecx
  109d77:	89 c7                	mov    %eax,%edi
  109d79:	89 d6                	mov    %edx,%esi
  109d7b:	fc                   	cld    
  109d7c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  109d7e:	8b 45 08             	mov    0x8(%ebp),%eax
}
  109d81:	83 c4 10             	add    $0x10,%esp
  109d84:	5b                   	pop    %ebx
  109d85:	5e                   	pop    %esi
  109d86:	5f                   	pop    %edi
  109d87:	5d                   	pop    %ebp
  109d88:	c3                   	ret    

00109d89 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  109d89:	55                   	push   %ebp
  109d8a:	89 e5                	mov    %esp,%ebp
  109d8c:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  109d8f:	8b 45 10             	mov    0x10(%ebp),%eax
  109d92:	89 44 24 08          	mov    %eax,0x8(%esp)
  109d96:	8b 45 0c             	mov    0xc(%ebp),%eax
  109d99:	89 44 24 04          	mov    %eax,0x4(%esp)
  109d9d:	8b 45 08             	mov    0x8(%ebp),%eax
  109da0:	89 04 24             	mov    %eax,(%esp)
  109da3:	e8 07 ff ff ff       	call   109caf <memmove>
}
  109da8:	c9                   	leave  
  109da9:	c3                   	ret    

00109daa <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  109daa:	55                   	push   %ebp
  109dab:	89 e5                	mov    %esp,%ebp
  109dad:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  109db0:	8b 45 08             	mov    0x8(%ebp),%eax
  109db3:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  109db6:	8b 45 0c             	mov    0xc(%ebp),%eax
  109db9:	89 45 f8             	mov    %eax,-0x8(%ebp)

	while (n-- > 0) {
  109dbc:	eb 32                	jmp    109df0 <memcmp+0x46>
		if (*s1 != *s2)
  109dbe:	8b 45 fc             	mov    -0x4(%ebp),%eax
  109dc1:	0f b6 10             	movzbl (%eax),%edx
  109dc4:	8b 45 f8             	mov    -0x8(%ebp),%eax
  109dc7:	0f b6 00             	movzbl (%eax),%eax
  109dca:	38 c2                	cmp    %al,%dl
  109dcc:	74 1a                	je     109de8 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  109dce:	8b 45 fc             	mov    -0x4(%ebp),%eax
  109dd1:	0f b6 00             	movzbl (%eax),%eax
  109dd4:	0f b6 d0             	movzbl %al,%edx
  109dd7:	8b 45 f8             	mov    -0x8(%ebp),%eax
  109dda:	0f b6 00             	movzbl (%eax),%eax
  109ddd:	0f b6 c0             	movzbl %al,%eax
  109de0:	89 d1                	mov    %edx,%ecx
  109de2:	29 c1                	sub    %eax,%ecx
  109de4:	89 c8                	mov    %ecx,%eax
  109de6:	eb 1c                	jmp    109e04 <memcmp+0x5a>
		s1++, s2++;
  109de8:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
  109dec:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  109df0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  109df4:	0f 95 c0             	setne  %al
  109df7:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  109dfb:	84 c0                	test   %al,%al
  109dfd:	75 bf                	jne    109dbe <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  109dff:	b8 00 00 00 00       	mov    $0x0,%eax
}
  109e04:	c9                   	leave  
  109e05:	c3                   	ret    

00109e06 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  109e06:	55                   	push   %ebp
  109e07:	89 e5                	mov    %esp,%ebp
  109e09:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  109e0c:	8b 45 10             	mov    0x10(%ebp),%eax
  109e0f:	8b 55 08             	mov    0x8(%ebp),%edx
  109e12:	01 d0                	add    %edx,%eax
  109e14:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  109e17:	eb 16                	jmp    109e2f <memchr+0x29>
		if (*(const unsigned char *) s == (unsigned char) c)
  109e19:	8b 45 08             	mov    0x8(%ebp),%eax
  109e1c:	0f b6 10             	movzbl (%eax),%edx
  109e1f:	8b 45 0c             	mov    0xc(%ebp),%eax
  109e22:	38 c2                	cmp    %al,%dl
  109e24:	75 05                	jne    109e2b <memchr+0x25>
			return (void *) s;
  109e26:	8b 45 08             	mov    0x8(%ebp),%eax
  109e29:	eb 11                	jmp    109e3c <memchr+0x36>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  109e2b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  109e2f:	8b 45 08             	mov    0x8(%ebp),%eax
  109e32:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  109e35:	72 e2                	jb     109e19 <memchr+0x13>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  109e37:	b8 00 00 00 00       	mov    $0x0,%eax
}
  109e3c:	c9                   	leave  
  109e3d:	c3                   	ret    
  109e3e:	66 90                	xchg   %ax,%ax

00109e40 <__udivdi3>:
  109e40:	83 ec 1c             	sub    $0x1c,%esp
  109e43:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  109e47:	89 7c 24 14          	mov    %edi,0x14(%esp)
  109e4b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
  109e4f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
  109e53:	8b 7c 24 20          	mov    0x20(%esp),%edi
  109e57:	8b 6c 24 24          	mov    0x24(%esp),%ebp
  109e5b:	85 c0                	test   %eax,%eax
  109e5d:	89 74 24 10          	mov    %esi,0x10(%esp)
  109e61:	89 7c 24 08          	mov    %edi,0x8(%esp)
  109e65:	89 ea                	mov    %ebp,%edx
  109e67:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  109e6b:	75 33                	jne    109ea0 <__udivdi3+0x60>
  109e6d:	39 e9                	cmp    %ebp,%ecx
  109e6f:	77 6f                	ja     109ee0 <__udivdi3+0xa0>
  109e71:	85 c9                	test   %ecx,%ecx
  109e73:	89 ce                	mov    %ecx,%esi
  109e75:	75 0b                	jne    109e82 <__udivdi3+0x42>
  109e77:	b8 01 00 00 00       	mov    $0x1,%eax
  109e7c:	31 d2                	xor    %edx,%edx
  109e7e:	f7 f1                	div    %ecx
  109e80:	89 c6                	mov    %eax,%esi
  109e82:	31 d2                	xor    %edx,%edx
  109e84:	89 e8                	mov    %ebp,%eax
  109e86:	f7 f6                	div    %esi
  109e88:	89 c5                	mov    %eax,%ebp
  109e8a:	89 f8                	mov    %edi,%eax
  109e8c:	f7 f6                	div    %esi
  109e8e:	89 ea                	mov    %ebp,%edx
  109e90:	8b 74 24 10          	mov    0x10(%esp),%esi
  109e94:	8b 7c 24 14          	mov    0x14(%esp),%edi
  109e98:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  109e9c:	83 c4 1c             	add    $0x1c,%esp
  109e9f:	c3                   	ret    
  109ea0:	39 e8                	cmp    %ebp,%eax
  109ea2:	77 24                	ja     109ec8 <__udivdi3+0x88>
  109ea4:	0f bd c8             	bsr    %eax,%ecx
  109ea7:	83 f1 1f             	xor    $0x1f,%ecx
  109eaa:	89 0c 24             	mov    %ecx,(%esp)
  109ead:	75 49                	jne    109ef8 <__udivdi3+0xb8>
  109eaf:	8b 74 24 08          	mov    0x8(%esp),%esi
  109eb3:	39 74 24 04          	cmp    %esi,0x4(%esp)
  109eb7:	0f 86 ab 00 00 00    	jbe    109f68 <__udivdi3+0x128>
  109ebd:	39 e8                	cmp    %ebp,%eax
  109ebf:	0f 82 a3 00 00 00    	jb     109f68 <__udivdi3+0x128>
  109ec5:	8d 76 00             	lea    0x0(%esi),%esi
  109ec8:	31 d2                	xor    %edx,%edx
  109eca:	31 c0                	xor    %eax,%eax
  109ecc:	8b 74 24 10          	mov    0x10(%esp),%esi
  109ed0:	8b 7c 24 14          	mov    0x14(%esp),%edi
  109ed4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  109ed8:	83 c4 1c             	add    $0x1c,%esp
  109edb:	c3                   	ret    
  109edc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  109ee0:	89 f8                	mov    %edi,%eax
  109ee2:	f7 f1                	div    %ecx
  109ee4:	31 d2                	xor    %edx,%edx
  109ee6:	8b 74 24 10          	mov    0x10(%esp),%esi
  109eea:	8b 7c 24 14          	mov    0x14(%esp),%edi
  109eee:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  109ef2:	83 c4 1c             	add    $0x1c,%esp
  109ef5:	c3                   	ret    
  109ef6:	66 90                	xchg   %ax,%ax
  109ef8:	0f b6 0c 24          	movzbl (%esp),%ecx
  109efc:	89 c6                	mov    %eax,%esi
  109efe:	b8 20 00 00 00       	mov    $0x20,%eax
  109f03:	8b 6c 24 04          	mov    0x4(%esp),%ebp
  109f07:	2b 04 24             	sub    (%esp),%eax
  109f0a:	8b 7c 24 08          	mov    0x8(%esp),%edi
  109f0e:	d3 e6                	shl    %cl,%esi
  109f10:	89 c1                	mov    %eax,%ecx
  109f12:	d3 ed                	shr    %cl,%ebp
  109f14:	0f b6 0c 24          	movzbl (%esp),%ecx
  109f18:	09 f5                	or     %esi,%ebp
  109f1a:	8b 74 24 04          	mov    0x4(%esp),%esi
  109f1e:	d3 e6                	shl    %cl,%esi
  109f20:	89 c1                	mov    %eax,%ecx
  109f22:	89 74 24 04          	mov    %esi,0x4(%esp)
  109f26:	89 d6                	mov    %edx,%esi
  109f28:	d3 ee                	shr    %cl,%esi
  109f2a:	0f b6 0c 24          	movzbl (%esp),%ecx
  109f2e:	d3 e2                	shl    %cl,%edx
  109f30:	89 c1                	mov    %eax,%ecx
  109f32:	d3 ef                	shr    %cl,%edi
  109f34:	09 d7                	or     %edx,%edi
  109f36:	89 f2                	mov    %esi,%edx
  109f38:	89 f8                	mov    %edi,%eax
  109f3a:	f7 f5                	div    %ebp
  109f3c:	89 d6                	mov    %edx,%esi
  109f3e:	89 c7                	mov    %eax,%edi
  109f40:	f7 64 24 04          	mull   0x4(%esp)
  109f44:	39 d6                	cmp    %edx,%esi
  109f46:	72 30                	jb     109f78 <__udivdi3+0x138>
  109f48:	8b 6c 24 08          	mov    0x8(%esp),%ebp
  109f4c:	0f b6 0c 24          	movzbl (%esp),%ecx
  109f50:	d3 e5                	shl    %cl,%ebp
  109f52:	39 c5                	cmp    %eax,%ebp
  109f54:	73 04                	jae    109f5a <__udivdi3+0x11a>
  109f56:	39 d6                	cmp    %edx,%esi
  109f58:	74 1e                	je     109f78 <__udivdi3+0x138>
  109f5a:	89 f8                	mov    %edi,%eax
  109f5c:	31 d2                	xor    %edx,%edx
  109f5e:	e9 69 ff ff ff       	jmp    109ecc <__udivdi3+0x8c>
  109f63:	90                   	nop
  109f64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  109f68:	31 d2                	xor    %edx,%edx
  109f6a:	b8 01 00 00 00       	mov    $0x1,%eax
  109f6f:	e9 58 ff ff ff       	jmp    109ecc <__udivdi3+0x8c>
  109f74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  109f78:	8d 47 ff             	lea    -0x1(%edi),%eax
  109f7b:	31 d2                	xor    %edx,%edx
  109f7d:	8b 74 24 10          	mov    0x10(%esp),%esi
  109f81:	8b 7c 24 14          	mov    0x14(%esp),%edi
  109f85:	8b 6c 24 18          	mov    0x18(%esp),%ebp
  109f89:	83 c4 1c             	add    $0x1c,%esp
  109f8c:	c3                   	ret    
  109f8d:	66 90                	xchg   %ax,%ax
  109f8f:	90                   	nop

00109f90 <__umoddi3>:
  109f90:	83 ec 2c             	sub    $0x2c,%esp
  109f93:	8b 44 24 3c          	mov    0x3c(%esp),%eax
  109f97:	8b 4c 24 30          	mov    0x30(%esp),%ecx
  109f9b:	89 74 24 20          	mov    %esi,0x20(%esp)
  109f9f:	8b 74 24 38          	mov    0x38(%esp),%esi
  109fa3:	89 7c 24 24          	mov    %edi,0x24(%esp)
  109fa7:	8b 7c 24 34          	mov    0x34(%esp),%edi
  109fab:	85 c0                	test   %eax,%eax
  109fad:	89 c2                	mov    %eax,%edx
  109faf:	89 6c 24 28          	mov    %ebp,0x28(%esp)
  109fb3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
  109fb7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  109fbb:	89 74 24 10          	mov    %esi,0x10(%esp)
  109fbf:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  109fc3:	89 7c 24 18          	mov    %edi,0x18(%esp)
  109fc7:	75 1f                	jne    109fe8 <__umoddi3+0x58>
  109fc9:	39 fe                	cmp    %edi,%esi
  109fcb:	76 63                	jbe    10a030 <__umoddi3+0xa0>
  109fcd:	89 c8                	mov    %ecx,%eax
  109fcf:	89 fa                	mov    %edi,%edx
  109fd1:	f7 f6                	div    %esi
  109fd3:	89 d0                	mov    %edx,%eax
  109fd5:	31 d2                	xor    %edx,%edx
  109fd7:	8b 74 24 20          	mov    0x20(%esp),%esi
  109fdb:	8b 7c 24 24          	mov    0x24(%esp),%edi
  109fdf:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  109fe3:	83 c4 2c             	add    $0x2c,%esp
  109fe6:	c3                   	ret    
  109fe7:	90                   	nop
  109fe8:	39 f8                	cmp    %edi,%eax
  109fea:	77 64                	ja     10a050 <__umoddi3+0xc0>
  109fec:	0f bd e8             	bsr    %eax,%ebp
  109fef:	83 f5 1f             	xor    $0x1f,%ebp
  109ff2:	75 74                	jne    10a068 <__umoddi3+0xd8>
  109ff4:	8b 7c 24 14          	mov    0x14(%esp),%edi
  109ff8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
  109ffc:	0f 87 0e 01 00 00    	ja     10a110 <__umoddi3+0x180>
  10a002:	8b 7c 24 0c          	mov    0xc(%esp),%edi
  10a006:	29 f1                	sub    %esi,%ecx
  10a008:	19 c7                	sbb    %eax,%edi
  10a00a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
  10a00e:	89 7c 24 18          	mov    %edi,0x18(%esp)
  10a012:	8b 44 24 14          	mov    0x14(%esp),%eax
  10a016:	8b 54 24 18          	mov    0x18(%esp),%edx
  10a01a:	8b 74 24 20          	mov    0x20(%esp),%esi
  10a01e:	8b 7c 24 24          	mov    0x24(%esp),%edi
  10a022:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  10a026:	83 c4 2c             	add    $0x2c,%esp
  10a029:	c3                   	ret    
  10a02a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  10a030:	85 f6                	test   %esi,%esi
  10a032:	89 f5                	mov    %esi,%ebp
  10a034:	75 0b                	jne    10a041 <__umoddi3+0xb1>
  10a036:	b8 01 00 00 00       	mov    $0x1,%eax
  10a03b:	31 d2                	xor    %edx,%edx
  10a03d:	f7 f6                	div    %esi
  10a03f:	89 c5                	mov    %eax,%ebp
  10a041:	8b 44 24 0c          	mov    0xc(%esp),%eax
  10a045:	31 d2                	xor    %edx,%edx
  10a047:	f7 f5                	div    %ebp
  10a049:	89 c8                	mov    %ecx,%eax
  10a04b:	f7 f5                	div    %ebp
  10a04d:	eb 84                	jmp    109fd3 <__umoddi3+0x43>
  10a04f:	90                   	nop
  10a050:	89 c8                	mov    %ecx,%eax
  10a052:	89 fa                	mov    %edi,%edx
  10a054:	8b 74 24 20          	mov    0x20(%esp),%esi
  10a058:	8b 7c 24 24          	mov    0x24(%esp),%edi
  10a05c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  10a060:	83 c4 2c             	add    $0x2c,%esp
  10a063:	c3                   	ret    
  10a064:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  10a068:	8b 44 24 10          	mov    0x10(%esp),%eax
  10a06c:	be 20 00 00 00       	mov    $0x20,%esi
  10a071:	89 e9                	mov    %ebp,%ecx
  10a073:	29 ee                	sub    %ebp,%esi
  10a075:	d3 e2                	shl    %cl,%edx
  10a077:	89 f1                	mov    %esi,%ecx
  10a079:	d3 e8                	shr    %cl,%eax
  10a07b:	89 e9                	mov    %ebp,%ecx
  10a07d:	09 d0                	or     %edx,%eax
  10a07f:	89 fa                	mov    %edi,%edx
  10a081:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10a085:	8b 44 24 10          	mov    0x10(%esp),%eax
  10a089:	d3 e0                	shl    %cl,%eax
  10a08b:	89 f1                	mov    %esi,%ecx
  10a08d:	89 44 24 10          	mov    %eax,0x10(%esp)
  10a091:	8b 44 24 1c          	mov    0x1c(%esp),%eax
  10a095:	d3 ea                	shr    %cl,%edx
  10a097:	89 e9                	mov    %ebp,%ecx
  10a099:	d3 e7                	shl    %cl,%edi
  10a09b:	89 f1                	mov    %esi,%ecx
  10a09d:	d3 e8                	shr    %cl,%eax
  10a09f:	89 e9                	mov    %ebp,%ecx
  10a0a1:	09 f8                	or     %edi,%eax
  10a0a3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  10a0a7:	f7 74 24 0c          	divl   0xc(%esp)
  10a0ab:	d3 e7                	shl    %cl,%edi
  10a0ad:	89 7c 24 18          	mov    %edi,0x18(%esp)
  10a0b1:	89 d7                	mov    %edx,%edi
  10a0b3:	f7 64 24 10          	mull   0x10(%esp)
  10a0b7:	39 d7                	cmp    %edx,%edi
  10a0b9:	89 c1                	mov    %eax,%ecx
  10a0bb:	89 54 24 14          	mov    %edx,0x14(%esp)
  10a0bf:	72 3b                	jb     10a0fc <__umoddi3+0x16c>
  10a0c1:	39 44 24 18          	cmp    %eax,0x18(%esp)
  10a0c5:	72 31                	jb     10a0f8 <__umoddi3+0x168>
  10a0c7:	8b 44 24 18          	mov    0x18(%esp),%eax
  10a0cb:	29 c8                	sub    %ecx,%eax
  10a0cd:	19 d7                	sbb    %edx,%edi
  10a0cf:	89 e9                	mov    %ebp,%ecx
  10a0d1:	89 fa                	mov    %edi,%edx
  10a0d3:	d3 e8                	shr    %cl,%eax
  10a0d5:	89 f1                	mov    %esi,%ecx
  10a0d7:	d3 e2                	shl    %cl,%edx
  10a0d9:	89 e9                	mov    %ebp,%ecx
  10a0db:	09 d0                	or     %edx,%eax
  10a0dd:	89 fa                	mov    %edi,%edx
  10a0df:	d3 ea                	shr    %cl,%edx
  10a0e1:	8b 74 24 20          	mov    0x20(%esp),%esi
  10a0e5:	8b 7c 24 24          	mov    0x24(%esp),%edi
  10a0e9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
  10a0ed:	83 c4 2c             	add    $0x2c,%esp
  10a0f0:	c3                   	ret    
  10a0f1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  10a0f8:	39 d7                	cmp    %edx,%edi
  10a0fa:	75 cb                	jne    10a0c7 <__umoddi3+0x137>
  10a0fc:	8b 54 24 14          	mov    0x14(%esp),%edx
  10a100:	89 c1                	mov    %eax,%ecx
  10a102:	2b 4c 24 10          	sub    0x10(%esp),%ecx
  10a106:	1b 54 24 0c          	sbb    0xc(%esp),%edx
  10a10a:	eb bb                	jmp    10a0c7 <__umoddi3+0x137>
  10a10c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  10a110:	3b 44 24 18          	cmp    0x18(%esp),%eax
  10a114:	0f 82 e8 fe ff ff    	jb     10a002 <__umoddi3+0x72>
  10a11a:	e9 f3 fe ff ff       	jmp    10a012 <__umoddi3+0x82>
