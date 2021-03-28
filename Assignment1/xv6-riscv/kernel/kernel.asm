
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	02c78793          	addi	a5,a5,44 # 80006090 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dbe78793          	addi	a5,a5,-578 # 80000e6c <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	47a080e7          	jalr	1146(ra) # 80002598 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	77a080e7          	jalr	1914(ra) # 800008a8 <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7159                	addi	sp,sp,-112
    80000158:	f486                	sd	ra,104(sp)
    8000015a:	f0a2                	sd	s0,96(sp)
    8000015c:	eca6                	sd	s1,88(sp)
    8000015e:	e8ca                	sd	s2,80(sp)
    80000160:	e4ce                	sd	s3,72(sp)
    80000162:	e0d2                	sd	s4,64(sp)
    80000164:	fc56                	sd	s5,56(sp)
    80000166:	f85a                	sd	s6,48(sp)
    80000168:	f45e                	sd	s7,40(sp)
    8000016a:	f062                	sd	s8,32(sp)
    8000016c:	ec66                	sd	s9,24(sp)
    8000016e:	e86a                	sd	s10,16(sp)
    80000170:	1880                	addi	s0,sp,112
    80000172:	8aaa                	mv	s5,a0
    80000174:	8a2e                	mv	s4,a1
    80000176:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000178:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000017c:	00011517          	auipc	a0,0x11
    80000180:	00450513          	addi	a0,a0,4 # 80011180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00011497          	auipc	s1,0x11
    80000190:	ff448493          	addi	s1,s1,-12 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00011917          	auipc	s2,0x11
    80000198:	08490913          	addi	s2,s2,132 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000019c:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000019e:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a0:	4ca9                	li	s9,10
  while(n > 0){
    800001a2:	07305863          	blez	s3,80000212 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71463          	bne	a4,a5,800001d6 <consoleread+0x80>
      if(myproc()->killed){
    800001b2:	00001097          	auipc	ra,0x1
    800001b6:	7cc080e7          	jalr	1996(ra) # 8000197e <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	fdc080e7          	jalr	-36(ra) # 8000219e <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef700e3          	beq	a4,a5,800001b2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001d6:	0017871b          	addiw	a4,a5,1
    800001da:	08e4ac23          	sw	a4,152(s1)
    800001de:	07f7f713          	andi	a4,a5,127
    800001e2:	9726                	add	a4,a4,s1
    800001e4:	01874703          	lbu	a4,24(a4)
    800001e8:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001ec:	077d0563          	beq	s10,s7,80000256 <consoleread+0x100>
    cbuf = c;
    800001f0:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f4:	4685                	li	a3,1
    800001f6:	f9f40613          	addi	a2,s0,-97
    800001fa:	85d2                	mv	a1,s4
    800001fc:	8556                	mv	a0,s5
    800001fe:	00002097          	auipc	ra,0x2
    80000202:	344080e7          	jalr	836(ra) # 80002542 <either_copyout>
    80000206:	01850663          	beq	a0,s8,80000212 <consoleread+0xbc>
    dst++;
    8000020a:	0a05                	addi	s4,s4,1
    --n;
    8000020c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000020e:	f99d1ae3          	bne	s10,s9,800001a2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000212:	00011517          	auipc	a0,0x11
    80000216:	f6e50513          	addi	a0,a0,-146 # 80011180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f5850513          	addi	a0,a0,-168 # 80011180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a46080e7          	jalr	-1466(ra) # 80000c76 <release>
        return -1;
    80000238:	557d                	li	a0,-1
}
    8000023a:	70a6                	ld	ra,104(sp)
    8000023c:	7406                	ld	s0,96(sp)
    8000023e:	64e6                	ld	s1,88(sp)
    80000240:	6946                	ld	s2,80(sp)
    80000242:	69a6                	ld	s3,72(sp)
    80000244:	6a06                	ld	s4,64(sp)
    80000246:	7ae2                	ld	s5,56(sp)
    80000248:	7b42                	ld	s6,48(sp)
    8000024a:	7ba2                	ld	s7,40(sp)
    8000024c:	7c02                	ld	s8,32(sp)
    8000024e:	6ce2                	ld	s9,24(sp)
    80000250:	6d42                	ld	s10,16(sp)
    80000252:	6165                	addi	sp,sp,112
    80000254:	8082                	ret
      if(n < target){
    80000256:	0009871b          	sext.w	a4,s3
    8000025a:	fb677ce3          	bgeu	a4,s6,80000212 <consoleread+0xbc>
        cons.r--;
    8000025e:	00011717          	auipc	a4,0x11
    80000262:	faf72d23          	sw	a5,-70(a4) # 80011218 <cons+0x98>
    80000266:	b775                	j	80000212 <consoleread+0xbc>

0000000080000268 <consputc>:
{
    80000268:	1141                	addi	sp,sp,-16
    8000026a:	e406                	sd	ra,8(sp)
    8000026c:	e022                	sd	s0,0(sp)
    8000026e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000270:	10000793          	li	a5,256
    80000274:	00f50a63          	beq	a0,a5,80000288 <consputc+0x20>
    uartputc_sync(c);
    80000278:	00000097          	auipc	ra,0x0
    8000027c:	55e080e7          	jalr	1374(ra) # 800007d6 <uartputc_sync>
}
    80000280:	60a2                	ld	ra,8(sp)
    80000282:	6402                	ld	s0,0(sp)
    80000284:	0141                	addi	sp,sp,16
    80000286:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000288:	4521                	li	a0,8
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	54c080e7          	jalr	1356(ra) # 800007d6 <uartputc_sync>
    80000292:	02000513          	li	a0,32
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	540080e7          	jalr	1344(ra) # 800007d6 <uartputc_sync>
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	536080e7          	jalr	1334(ra) # 800007d6 <uartputc_sync>
    800002a8:	bfe1                	j	80000280 <consputc+0x18>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	e04a                	sd	s2,0(sp)
    800002b4:	1000                	addi	s0,sp,32
    800002b6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b8:	00011517          	auipc	a0,0x11
    800002bc:	ec850513          	addi	a0,a0,-312 # 80011180 <cons>
    800002c0:	00001097          	auipc	ra,0x1
    800002c4:	902080e7          	jalr	-1790(ra) # 80000bc2 <acquire>

  switch(c){
    800002c8:	47d5                	li	a5,21
    800002ca:	0af48663          	beq	s1,a5,80000376 <consoleintr+0xcc>
    800002ce:	0297ca63          	blt	a5,s1,80000302 <consoleintr+0x58>
    800002d2:	47a1                	li	a5,8
    800002d4:	0ef48763          	beq	s1,a5,800003c2 <consoleintr+0x118>
    800002d8:	47c1                	li	a5,16
    800002da:	10f49a63          	bne	s1,a5,800003ee <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002de:	00002097          	auipc	ra,0x2
    800002e2:	310080e7          	jalr	784(ra) # 800025ee <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80011180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
}
    800002f6:	60e2                	ld	ra,24(sp)
    800002f8:	6442                	ld	s0,16(sp)
    800002fa:	64a2                	ld	s1,8(sp)
    800002fc:	6902                	ld	s2,0(sp)
    800002fe:	6105                	addi	sp,sp,32
    80000300:	8082                	ret
  switch(c){
    80000302:	07f00793          	li	a5,127
    80000306:	0af48e63          	beq	s1,a5,800003c2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000030a:	00011717          	auipc	a4,0x11
    8000030e:	e7670713          	addi	a4,a4,-394 # 80011180 <cons>
    80000312:	0a072783          	lw	a5,160(a4)
    80000316:	09872703          	lw	a4,152(a4)
    8000031a:	9f99                	subw	a5,a5,a4
    8000031c:	07f00713          	li	a4,127
    80000320:	fcf763e3          	bltu	a4,a5,800002e6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000324:	47b5                	li	a5,13
    80000326:	0cf48763          	beq	s1,a5,800003f4 <consoleintr+0x14a>
      consputc(c);
    8000032a:	8526                	mv	a0,s1
    8000032c:	00000097          	auipc	ra,0x0
    80000330:	f3c080e7          	jalr	-196(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000334:	00011797          	auipc	a5,0x11
    80000338:	e4c78793          	addi	a5,a5,-436 # 80011180 <cons>
    8000033c:	0a07a703          	lw	a4,160(a5)
    80000340:	0017069b          	addiw	a3,a4,1
    80000344:	0006861b          	sext.w	a2,a3
    80000348:	0ad7a023          	sw	a3,160(a5)
    8000034c:	07f77713          	andi	a4,a4,127
    80000350:	97ba                	add	a5,a5,a4
    80000352:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000356:	47a9                	li	a5,10
    80000358:	0cf48563          	beq	s1,a5,80000422 <consoleintr+0x178>
    8000035c:	4791                	li	a5,4
    8000035e:	0cf48263          	beq	s1,a5,80000422 <consoleintr+0x178>
    80000362:	00011797          	auipc	a5,0x11
    80000366:	eb67a783          	lw	a5,-330(a5) # 80011218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00011717          	auipc	a4,0x11
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80011180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00011497          	auipc	s1,0x11
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000038e:	4929                	li	s2,10
    80000390:	f4f70be3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	37fd                	addiw	a5,a5,-1
    80000396:	07f7f713          	andi	a4,a5,127
    8000039a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000039c:	01874703          	lbu	a4,24(a4)
    800003a0:	f52703e3          	beq	a4,s2,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003a4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003a8:	10000513          	li	a0,256
    800003ac:	00000097          	auipc	ra,0x0
    800003b0:	ebc080e7          	jalr	-324(ra) # 80000268 <consputc>
    while(cons.e != cons.w &&
    800003b4:	0a04a783          	lw	a5,160(s1)
    800003b8:	09c4a703          	lw	a4,156(s1)
    800003bc:	fcf71ce3          	bne	a4,a5,80000394 <consoleintr+0xea>
    800003c0:	b71d                	j	800002e6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c2:	00011717          	auipc	a4,0x11
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80011180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e0:	10000513          	li	a0,256
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	e84080e7          	jalr	-380(ra) # 80000268 <consputc>
    800003ec:	bded                	j	800002e6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003ee:	ee048ce3          	beqz	s1,800002e6 <consoleintr+0x3c>
    800003f2:	bf21                	j	8000030a <consoleintr+0x60>
      consputc(c);
    800003f4:	4529                	li	a0,10
    800003f6:	00000097          	auipc	ra,0x0
    800003fa:	e72080e7          	jalr	-398(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003fe:	00011797          	auipc	a5,0x11
    80000402:	d8278793          	addi	a5,a5,-638 # 80011180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00011797          	auipc	a5,0x11
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00011517          	auipc	a0,0x11
    8000042e:	dee50513          	addi	a0,a0,-530 # 80011218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	ef8080e7          	jalr	-264(ra) # 8000232a <wakeup>
    8000043a:	b575                	j	800002e6 <consoleintr+0x3c>

000000008000043c <consoleinit>:

void
consoleinit(void)
{
    8000043c:	1141                	addi	sp,sp,-16
    8000043e:	e406                	sd	ra,8(sp)
    80000440:	e022                	sd	s0,0(sp)
    80000442:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000444:	00008597          	auipc	a1,0x8
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80008010 <etext+0x10>
    8000044c:	00011517          	auipc	a0,0x11
    80000450:	d3450513          	addi	a0,a0,-716 # 80011180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00021797          	auipc	a5,0x21
    80000468:	4b478793          	addi	a5,a5,1204 # 80021918 <devsw>
    8000046c:	00000717          	auipc	a4,0x0
    80000470:	cea70713          	addi	a4,a4,-790 # 80000156 <consoleread>
    80000474:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000476:	00000717          	auipc	a4,0x0
    8000047a:	c7e70713          	addi	a4,a4,-898 # 800000f4 <consolewrite>
    8000047e:	ef98                	sd	a4,24(a5)
}
    80000480:	60a2                	ld	ra,8(sp)
    80000482:	6402                	ld	s0,0(sp)
    80000484:	0141                	addi	sp,sp,16
    80000486:	8082                	ret

0000000080000488 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000488:	7179                	addi	sp,sp,-48
    8000048a:	f406                	sd	ra,40(sp)
    8000048c:	f022                	sd	s0,32(sp)
    8000048e:	ec26                	sd	s1,24(sp)
    80000490:	e84a                	sd	s2,16(sp)
    80000492:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000494:	c219                	beqz	a2,8000049a <printint+0x12>
    80000496:	08054663          	bltz	a0,80000522 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    8000049a:	2501                	sext.w	a0,a0
    8000049c:	4881                	li	a7,0
    8000049e:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004a4:	2581                	sext.w	a1,a1
    800004a6:	00008617          	auipc	a2,0x8
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80008040 <digits>
    800004ae:	883a                	mv	a6,a4
    800004b0:	2705                	addiw	a4,a4,1
    800004b2:	02b577bb          	remuw	a5,a0,a1
    800004b6:	1782                	slli	a5,a5,0x20
    800004b8:	9381                	srli	a5,a5,0x20
    800004ba:	97b2                	add	a5,a5,a2
    800004bc:	0007c783          	lbu	a5,0(a5)
    800004c0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004c4:	0005079b          	sext.w	a5,a0
    800004c8:	02b5553b          	divuw	a0,a0,a1
    800004cc:	0685                	addi	a3,a3,1
    800004ce:	feb7f0e3          	bgeu	a5,a1,800004ae <printint+0x26>

  if(sign)
    800004d2:	00088b63          	beqz	a7,800004e8 <printint+0x60>
    buf[i++] = '-';
    800004d6:	fe040793          	addi	a5,s0,-32
    800004da:	973e                	add	a4,a4,a5
    800004dc:	02d00793          	li	a5,45
    800004e0:	fef70823          	sb	a5,-16(a4)
    800004e4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004e8:	02e05763          	blez	a4,80000516 <printint+0x8e>
    800004ec:	fd040793          	addi	a5,s0,-48
    800004f0:	00e784b3          	add	s1,a5,a4
    800004f4:	fff78913          	addi	s2,a5,-1
    800004f8:	993a                	add	s2,s2,a4
    800004fa:	377d                	addiw	a4,a4,-1
    800004fc:	1702                	slli	a4,a4,0x20
    800004fe:	9301                	srli	a4,a4,0x20
    80000500:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000504:	fff4c503          	lbu	a0,-1(s1)
    80000508:	00000097          	auipc	ra,0x0
    8000050c:	d60080e7          	jalr	-672(ra) # 80000268 <consputc>
  while(--i >= 0)
    80000510:	14fd                	addi	s1,s1,-1
    80000512:	ff2499e3          	bne	s1,s2,80000504 <printint+0x7c>
}
    80000516:	70a2                	ld	ra,40(sp)
    80000518:	7402                	ld	s0,32(sp)
    8000051a:	64e2                	ld	s1,24(sp)
    8000051c:	6942                	ld	s2,16(sp)
    8000051e:	6145                	addi	sp,sp,48
    80000520:	8082                	ret
    x = -xx;
    80000522:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000526:	4885                	li	a7,1
    x = -xx;
    80000528:	bf9d                	j	8000049e <printint+0x16>

000000008000052a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000052a:	1101                	addi	sp,sp,-32
    8000052c:	ec06                	sd	ra,24(sp)
    8000052e:	e822                	sd	s0,16(sp)
    80000530:	e426                	sd	s1,8(sp)
    80000532:	1000                	addi	s0,sp,32
    80000534:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000536:	00011797          	auipc	a5,0x11
    8000053a:	d007a523          	sw	zero,-758(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000053e:	00008517          	auipc	a0,0x8
    80000542:	ada50513          	addi	a0,a0,-1318 # 80008018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	b7050513          	addi	a0,a0,-1168 # 800080c8 <digits+0x88>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	00009717          	auipc	a4,0x9
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 80009000 <panicked>
  for(;;)
    80000572:	a001                	j	80000572 <panic+0x48>

0000000080000574 <printf>:
{
    80000574:	7131                	addi	sp,sp,-192
    80000576:	fc86                	sd	ra,120(sp)
    80000578:	f8a2                	sd	s0,112(sp)
    8000057a:	f4a6                	sd	s1,104(sp)
    8000057c:	f0ca                	sd	s2,96(sp)
    8000057e:	ecce                	sd	s3,88(sp)
    80000580:	e8d2                	sd	s4,80(sp)
    80000582:	e4d6                	sd	s5,72(sp)
    80000584:	e0da                	sd	s6,64(sp)
    80000586:	fc5e                	sd	s7,56(sp)
    80000588:	f862                	sd	s8,48(sp)
    8000058a:	f466                	sd	s9,40(sp)
    8000058c:	f06a                	sd	s10,32(sp)
    8000058e:	ec6e                	sd	s11,24(sp)
    80000590:	0100                	addi	s0,sp,128
    80000592:	8a2a                	mv	s4,a0
    80000594:	e40c                	sd	a1,8(s0)
    80000596:	e810                	sd	a2,16(s0)
    80000598:	ec14                	sd	a3,24(s0)
    8000059a:	f018                	sd	a4,32(s0)
    8000059c:	f41c                	sd	a5,40(s0)
    8000059e:	03043823          	sd	a6,48(s0)
    800005a2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005a6:	00011d97          	auipc	s11,0x11
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80011240 <pr+0x18>
  if(locking)
    800005ae:	020d9b63          	bnez	s11,800005e4 <printf+0x70>
  if (fmt == 0)
    800005b2:	040a0263          	beqz	s4,800005f6 <printf+0x82>
  va_start(ap, fmt);
    800005b6:	00840793          	addi	a5,s0,8
    800005ba:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005be:	000a4503          	lbu	a0,0(s4)
    800005c2:	14050f63          	beqz	a0,80000720 <printf+0x1ac>
    800005c6:	4981                	li	s3,0
    if(c != '%'){
    800005c8:	02500a93          	li	s5,37
    switch(c){
    800005cc:	07000b93          	li	s7,112
  consputc('x');
    800005d0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d2:	00008b17          	auipc	s6,0x8
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80008040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00011517          	auipc	a0,0x11
    800005e8:	c4450513          	addi	a0,a0,-956 # 80011228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	5d6080e7          	jalr	1494(ra) # 80000bc2 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00008517          	auipc	a0,0x8
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80008028 <etext+0x28>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	f2c080e7          	jalr	-212(ra) # 8000052a <panic>
      consputc(c);
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	c62080e7          	jalr	-926(ra) # 80000268 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000060e:	2985                	addiw	s3,s3,1
    80000610:	013a07b3          	add	a5,s4,s3
    80000614:	0007c503          	lbu	a0,0(a5)
    80000618:	10050463          	beqz	a0,80000720 <printf+0x1ac>
    if(c != '%'){
    8000061c:	ff5515e3          	bne	a0,s5,80000606 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c783          	lbu	a5,0(a5)
    8000062a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000062e:	cbed                	beqz	a5,80000720 <printf+0x1ac>
    switch(c){
    80000630:	05778a63          	beq	a5,s7,80000684 <printf+0x110>
    80000634:	02fbf663          	bgeu	s7,a5,80000660 <printf+0xec>
    80000638:	09978863          	beq	a5,s9,800006c8 <printf+0x154>
    8000063c:	07800713          	li	a4,120
    80000640:	0ce79563          	bne	a5,a4,8000070a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4605                	li	a2,1
    80000652:	85ea                	mv	a1,s10
    80000654:	4388                	lw	a0,0(a5)
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	e32080e7          	jalr	-462(ra) # 80000488 <printint>
      break;
    8000065e:	bf45                	j	8000060e <printf+0x9a>
    switch(c){
    80000660:	09578f63          	beq	a5,s5,800006fe <printf+0x18a>
    80000664:	0b879363          	bne	a5,s8,8000070a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	45a9                	li	a1,10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e0e080e7          	jalr	-498(ra) # 80000488 <printint>
      break;
    80000682:	b771                	j	8000060e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000684:	f8843783          	ld	a5,-120(s0)
    80000688:	00878713          	addi	a4,a5,8
    8000068c:	f8e43423          	sd	a4,-120(s0)
    80000690:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000694:	03000513          	li	a0,48
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	bd0080e7          	jalr	-1072(ra) # 80000268 <consputc>
  consputc('x');
    800006a0:	07800513          	li	a0,120
    800006a4:	00000097          	auipc	ra,0x0
    800006a8:	bc4080e7          	jalr	-1084(ra) # 80000268 <consputc>
    800006ac:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ae:	03c95793          	srli	a5,s2,0x3c
    800006b2:	97da                	add	a5,a5,s6
    800006b4:	0007c503          	lbu	a0,0(a5)
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bb0080e7          	jalr	-1104(ra) # 80000268 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c0:	0912                	slli	s2,s2,0x4
    800006c2:	34fd                	addiw	s1,s1,-1
    800006c4:	f4ed                	bnez	s1,800006ae <printf+0x13a>
    800006c6:	b7a1                	j	8000060e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006c8:	f8843783          	ld	a5,-120(s0)
    800006cc:	00878713          	addi	a4,a5,8
    800006d0:	f8e43423          	sd	a4,-120(s0)
    800006d4:	6384                	ld	s1,0(a5)
    800006d6:	cc89                	beqz	s1,800006f0 <printf+0x17c>
      for(; *s; s++)
    800006d8:	0004c503          	lbu	a0,0(s1)
    800006dc:	d90d                	beqz	a0,8000060e <printf+0x9a>
        consputc(*s);
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	b8a080e7          	jalr	-1142(ra) # 80000268 <consputc>
      for(; *s; s++)
    800006e6:	0485                	addi	s1,s1,1
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	f96d                	bnez	a0,800006de <printf+0x16a>
    800006ee:	b705                	j	8000060e <printf+0x9a>
        s = "(null)";
    800006f0:	00008497          	auipc	s1,0x8
    800006f4:	93048493          	addi	s1,s1,-1744 # 80008020 <etext+0x20>
      for(; *s; s++)
    800006f8:	02800513          	li	a0,40
    800006fc:	b7cd                	j	800006de <printf+0x16a>
      consputc('%');
    800006fe:	8556                	mv	a0,s5
    80000700:	00000097          	auipc	ra,0x0
    80000704:	b68080e7          	jalr	-1176(ra) # 80000268 <consputc>
      break;
    80000708:	b719                	j	8000060e <printf+0x9a>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b5c080e7          	jalr	-1188(ra) # 80000268 <consputc>
      consputc(c);
    80000714:	8526                	mv	a0,s1
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b52080e7          	jalr	-1198(ra) # 80000268 <consputc>
      break;
    8000071e:	bdc5                	j	8000060e <printf+0x9a>
  if(locking)
    80000720:	020d9163          	bnez	s11,80000742 <printf+0x1ce>
}
    80000724:	70e6                	ld	ra,120(sp)
    80000726:	7446                	ld	s0,112(sp)
    80000728:	74a6                	ld	s1,104(sp)
    8000072a:	7906                	ld	s2,96(sp)
    8000072c:	69e6                	ld	s3,88(sp)
    8000072e:	6a46                	ld	s4,80(sp)
    80000730:	6aa6                	ld	s5,72(sp)
    80000732:	6b06                	ld	s6,64(sp)
    80000734:	7be2                	ld	s7,56(sp)
    80000736:	7c42                	ld	s8,48(sp)
    80000738:	7ca2                	ld	s9,40(sp)
    8000073a:	7d02                	ld	s10,32(sp)
    8000073c:	6de2                	ld	s11,24(sp)
    8000073e:	6129                	addi	sp,sp,192
    80000740:	8082                	ret
    release(&pr.lock);
    80000742:	00011517          	auipc	a0,0x11
    80000746:	ae650513          	addi	a0,a0,-1306 # 80011228 <pr>
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	52c080e7          	jalr	1324(ra) # 80000c76 <release>
}
    80000752:	bfc9                	j	80000724 <printf+0x1b0>

0000000080000754 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000754:	1101                	addi	sp,sp,-32
    80000756:	ec06                	sd	ra,24(sp)
    80000758:	e822                	sd	s0,16(sp)
    8000075a:	e426                	sd	s1,8(sp)
    8000075c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000075e:	00011497          	auipc	s1,0x11
    80000762:	aca48493          	addi	s1,s1,-1334 # 80011228 <pr>
    80000766:	00008597          	auipc	a1,0x8
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80008038 <etext+0x38>
    8000076e:	8526                	mv	a0,s1
    80000770:	00000097          	auipc	ra,0x0
    80000774:	3c2080e7          	jalr	962(ra) # 80000b32 <initlock>
  pr.locking = 1;
    80000778:	4785                	li	a5,1
    8000077a:	cc9c                	sw	a5,24(s1)
}
    8000077c:	60e2                	ld	ra,24(sp)
    8000077e:	6442                	ld	s0,16(sp)
    80000780:	64a2                	ld	s1,8(sp)
    80000782:	6105                	addi	sp,sp,32
    80000784:	8082                	ret

0000000080000786 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000786:	1141                	addi	sp,sp,-16
    80000788:	e406                	sd	ra,8(sp)
    8000078a:	e022                	sd	s0,0(sp)
    8000078c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000078e:	100007b7          	lui	a5,0x10000
    80000792:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000796:	f8000713          	li	a4,-128
    8000079a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000079e:	470d                	li	a4,3
    800007a0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007a4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007a8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ac:	469d                	li	a3,7
    800007ae:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007b2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007b6:	00008597          	auipc	a1,0x8
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80008058 <digits+0x18>
    800007be:	00011517          	auipc	a0,0x11
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80011248 <uart_tx_lock>
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	36c080e7          	jalr	876(ra) # 80000b32 <initlock>
}
    800007ce:	60a2                	ld	ra,8(sp)
    800007d0:	6402                	ld	s0,0(sp)
    800007d2:	0141                	addi	sp,sp,16
    800007d4:	8082                	ret

00000000800007d6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007d6:	1101                	addi	sp,sp,-32
    800007d8:	ec06                	sd	ra,24(sp)
    800007da:	e822                	sd	s0,16(sp)
    800007dc:	e426                	sd	s1,8(sp)
    800007de:	1000                	addi	s0,sp,32
    800007e0:	84aa                	mv	s1,a0
  push_off();
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	394080e7          	jalr	916(ra) # 80000b76 <push_off>

  if(panicked){
    800007ea:	00009797          	auipc	a5,0x9
    800007ee:	8167a783          	lw	a5,-2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007f2:	10000737          	lui	a4,0x10000
  if(panicked){
    800007f6:	c391                	beqz	a5,800007fa <uartputc_sync+0x24>
    for(;;)
    800007f8:	a001                	j	800007f8 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fa:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007fe:	0207f793          	andi	a5,a5,32
    80000802:	dfe5                	beqz	a5,800007fa <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000804:	0ff4f513          	andi	a0,s1,255
    80000808:	100007b7          	lui	a5,0x10000
    8000080c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000810:	00000097          	auipc	ra,0x0
    80000814:	406080e7          	jalr	1030(ra) # 80000c16 <pop_off>
}
    80000818:	60e2                	ld	ra,24(sp)
    8000081a:	6442                	ld	s0,16(sp)
    8000081c:	64a2                	ld	s1,8(sp)
    8000081e:	6105                	addi	sp,sp,32
    80000820:	8082                	ret

0000000080000822 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000822:	00008797          	auipc	a5,0x8
    80000826:	7e67b783          	ld	a5,2022(a5) # 80009008 <uart_tx_r>
    8000082a:	00008717          	auipc	a4,0x8
    8000082e:	7e673703          	ld	a4,2022(a4) # 80009010 <uart_tx_w>
    80000832:	06f70a63          	beq	a4,a5,800008a6 <uartstart+0x84>
{
    80000836:	7139                	addi	sp,sp,-64
    80000838:	fc06                	sd	ra,56(sp)
    8000083a:	f822                	sd	s0,48(sp)
    8000083c:	f426                	sd	s1,40(sp)
    8000083e:	f04a                	sd	s2,32(sp)
    80000840:	ec4e                	sd	s3,24(sp)
    80000842:	e852                	sd	s4,16(sp)
    80000844:	e456                	sd	s5,8(sp)
    80000846:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000848:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000084c:	00011a17          	auipc	s4,0x11
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00008497          	auipc	s1,0x8
    80000858:	7b448493          	addi	s1,s1,1972 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00008997          	auipc	s3,0x8
    80000860:	7b498993          	addi	s3,s3,1972 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000864:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000868:	02077713          	andi	a4,a4,32
    8000086c:	c705                	beqz	a4,80000894 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086e:	01f7f713          	andi	a4,a5,31
    80000872:	9752                	add	a4,a4,s4
    80000874:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000878:	0785                	addi	a5,a5,1
    8000087a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000087c:	8526                	mv	a0,s1
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	aac080e7          	jalr	-1364(ra) # 8000232a <wakeup>
    
    WriteReg(THR, c);
    80000886:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000088a:	609c                	ld	a5,0(s1)
    8000088c:	0009b703          	ld	a4,0(s3)
    80000890:	fcf71ae3          	bne	a4,a5,80000864 <uartstart+0x42>
  }
}
    80000894:	70e2                	ld	ra,56(sp)
    80000896:	7442                	ld	s0,48(sp)
    80000898:	74a2                	ld	s1,40(sp)
    8000089a:	7902                	ld	s2,32(sp)
    8000089c:	69e2                	ld	s3,24(sp)
    8000089e:	6a42                	ld	s4,16(sp)
    800008a0:	6aa2                	ld	s5,8(sp)
    800008a2:	6121                	addi	sp,sp,64
    800008a4:	8082                	ret
    800008a6:	8082                	ret

00000000800008a8 <uartputc>:
{
    800008a8:	7179                	addi	sp,sp,-48
    800008aa:	f406                	sd	ra,40(sp)
    800008ac:	f022                	sd	s0,32(sp)
    800008ae:	ec26                	sd	s1,24(sp)
    800008b0:	e84a                	sd	s2,16(sp)
    800008b2:	e44e                	sd	s3,8(sp)
    800008b4:	e052                	sd	s4,0(sp)
    800008b6:	1800                	addi	s0,sp,48
    800008b8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ba:	00011517          	auipc	a0,0x11
    800008be:	98e50513          	addi	a0,a0,-1650 # 80011248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	300080e7          	jalr	768(ra) # 80000bc2 <acquire>
  if(panicked){
    800008ca:	00008797          	auipc	a5,0x8
    800008ce:	7367a783          	lw	a5,1846(a5) # 80009000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00008717          	auipc	a4,0x8
    800008da:	73a73703          	ld	a4,1850(a4) # 80009010 <uart_tx_w>
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	72a7b783          	ld	a5,1834(a5) # 80009008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00011997          	auipc	s3,0x11
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80011248 <uart_tx_lock>
    800008f6:	00008497          	auipc	s1,0x8
    800008fa:	71248493          	addi	s1,s1,1810 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00008917          	auipc	s2,0x8
    80000902:	71290913          	addi	s2,s2,1810 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00002097          	auipc	ra,0x2
    8000090e:	894080e7          	jalr	-1900(ra) # 8000219e <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00011497          	auipc	s1,0x11
    80000924:	92848493          	addi	s1,s1,-1752 # 80011248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00008797          	auipc	a5,0x8
    80000938:	6ce7be23          	sd	a4,1756(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	ee6080e7          	jalr	-282(ra) # 80000822 <uartstart>
      release(&uart_tx_lock);
    80000944:	8526                	mv	a0,s1
    80000946:	00000097          	auipc	ra,0x0
    8000094a:	330080e7          	jalr	816(ra) # 80000c76 <release>
}
    8000094e:	70a2                	ld	ra,40(sp)
    80000950:	7402                	ld	s0,32(sp)
    80000952:	64e2                	ld	s1,24(sp)
    80000954:	6942                	ld	s2,16(sp)
    80000956:	69a2                	ld	s3,8(sp)
    80000958:	6a02                	ld	s4,0(sp)
    8000095a:	6145                	addi	sp,sp,48
    8000095c:	8082                	ret

000000008000095e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000095e:	1141                	addi	sp,sp,-16
    80000960:	e422                	sd	s0,8(sp)
    80000962:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000964:	100007b7          	lui	a5,0x10000
    80000968:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000096c:	8b85                	andi	a5,a5,1
    8000096e:	cb91                	beqz	a5,80000982 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000970:	100007b7          	lui	a5,0x10000
    80000974:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000978:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000097c:	6422                	ld	s0,8(sp)
    8000097e:	0141                	addi	sp,sp,16
    80000980:	8082                	ret
    return -1;
    80000982:	557d                	li	a0,-1
    80000984:	bfe5                	j	8000097c <uartgetc+0x1e>

0000000080000986 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000986:	1101                	addi	sp,sp,-32
    80000988:	ec06                	sd	ra,24(sp)
    8000098a:	e822                	sd	s0,16(sp)
    8000098c:	e426                	sd	s1,8(sp)
    8000098e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000990:	54fd                	li	s1,-1
    80000992:	a029                	j	8000099c <uartintr+0x16>
      break;
    consoleintr(c);
    80000994:	00000097          	auipc	ra,0x0
    80000998:	916080e7          	jalr	-1770(ra) # 800002aa <consoleintr>
    int c = uartgetc();
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	fc2080e7          	jalr	-62(ra) # 8000095e <uartgetc>
    if(c == -1)
    800009a4:	fe9518e3          	bne	a0,s1,80000994 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009a8:	00011497          	auipc	s1,0x11
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80011248 <uart_tx_lock>
    800009b0:	8526                	mv	a0,s1
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	210080e7          	jalr	528(ra) # 80000bc2 <acquire>
  uartstart();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	e68080e7          	jalr	-408(ra) # 80000822 <uartstart>
  release(&uart_tx_lock);
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	2b2080e7          	jalr	690(ra) # 80000c76 <release>
}
    800009cc:	60e2                	ld	ra,24(sp)
    800009ce:	6442                	ld	s0,16(sp)
    800009d0:	64a2                	ld	s1,8(sp)
    800009d2:	6105                	addi	sp,sp,32
    800009d4:	8082                	ret

00000000800009d6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009d6:	1101                	addi	sp,sp,-32
    800009d8:	ec06                	sd	ra,24(sp)
    800009da:	e822                	sd	s0,16(sp)
    800009dc:	e426                	sd	s1,8(sp)
    800009de:	e04a                	sd	s2,0(sp)
    800009e0:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009e2:	03451793          	slli	a5,a0,0x34
    800009e6:	ebb9                	bnez	a5,80000a3c <kfree+0x66>
    800009e8:	84aa                	mv	s1,a0
    800009ea:	00025797          	auipc	a5,0x25
    800009ee:	61678793          	addi	a5,a5,1558 # 80026000 <end>
    800009f2:	04f56563          	bltu	a0,a5,80000a3c <kfree+0x66>
    800009f6:	47c5                	li	a5,17
    800009f8:	07ee                	slli	a5,a5,0x1b
    800009fa:	04f57163          	bgeu	a0,a5,80000a3c <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009fe:	6605                	lui	a2,0x1
    80000a00:	4585                	li	a1,1
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	2bc080e7          	jalr	700(ra) # 80000cbe <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a0a:	00011917          	auipc	s2,0x11
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80011280 <kmem>
    80000a12:	854a                	mv	a0,s2
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	1ae080e7          	jalr	430(ra) # 80000bc2 <acquire>
  r->next = kmem.freelist;
    80000a1c:	01893783          	ld	a5,24(s2)
    80000a20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a22:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	24e080e7          	jalr	590(ra) # 80000c76 <release>
}
    80000a30:	60e2                	ld	ra,24(sp)
    80000a32:	6442                	ld	s0,16(sp)
    80000a34:	64a2                	ld	s1,8(sp)
    80000a36:	6902                	ld	s2,0(sp)
    80000a38:	6105                	addi	sp,sp,32
    80000a3a:	8082                	ret
    panic("kfree");
    80000a3c:	00007517          	auipc	a0,0x7
    80000a40:	62450513          	addi	a0,a0,1572 # 80008060 <digits+0x20>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>

0000000080000a4c <freerange>:
{
    80000a4c:	7179                	addi	sp,sp,-48
    80000a4e:	f406                	sd	ra,40(sp)
    80000a50:	f022                	sd	s0,32(sp)
    80000a52:	ec26                	sd	s1,24(sp)
    80000a54:	e84a                	sd	s2,16(sp)
    80000a56:	e44e                	sd	s3,8(sp)
    80000a58:	e052                	sd	s4,0(sp)
    80000a5a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a5c:	6785                	lui	a5,0x1
    80000a5e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a62:	94aa                	add	s1,s1,a0
    80000a64:	757d                	lui	a0,0xfffff
    80000a66:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a68:	94be                	add	s1,s1,a5
    80000a6a:	0095ee63          	bltu	a1,s1,80000a86 <freerange+0x3a>
    80000a6e:	892e                	mv	s2,a1
    kfree(p);
    80000a70:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a72:	6985                	lui	s3,0x1
    kfree(p);
    80000a74:	01448533          	add	a0,s1,s4
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	f5e080e7          	jalr	-162(ra) # 800009d6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	94ce                	add	s1,s1,s3
    80000a82:	fe9979e3          	bgeu	s2,s1,80000a74 <freerange+0x28>
}
    80000a86:	70a2                	ld	ra,40(sp)
    80000a88:	7402                	ld	s0,32(sp)
    80000a8a:	64e2                	ld	s1,24(sp)
    80000a8c:	6942                	ld	s2,16(sp)
    80000a8e:	69a2                	ld	s3,8(sp)
    80000a90:	6a02                	ld	s4,0(sp)
    80000a92:	6145                	addi	sp,sp,48
    80000a94:	8082                	ret

0000000080000a96 <kinit>:
{
    80000a96:	1141                	addi	sp,sp,-16
    80000a98:	e406                	sd	ra,8(sp)
    80000a9a:	e022                	sd	s0,0(sp)
    80000a9c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000a9e:	00007597          	auipc	a1,0x7
    80000aa2:	5ca58593          	addi	a1,a1,1482 # 80008068 <digits+0x28>
    80000aa6:	00010517          	auipc	a0,0x10
    80000aaa:	7da50513          	addi	a0,a0,2010 # 80011280 <kmem>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	084080e7          	jalr	132(ra) # 80000b32 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ab6:	45c5                	li	a1,17
    80000ab8:	05ee                	slli	a1,a1,0x1b
    80000aba:	00025517          	auipc	a0,0x25
    80000abe:	54650513          	addi	a0,a0,1350 # 80026000 <end>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	f8a080e7          	jalr	-118(ra) # 80000a4c <freerange>
}
    80000aca:	60a2                	ld	ra,8(sp)
    80000acc:	6402                	ld	s0,0(sp)
    80000ace:	0141                	addi	sp,sp,16
    80000ad0:	8082                	ret

0000000080000ad2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ad2:	1101                	addi	sp,sp,-32
    80000ad4:	ec06                	sd	ra,24(sp)
    80000ad6:	e822                	sd	s0,16(sp)
    80000ad8:	e426                	sd	s1,8(sp)
    80000ada:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000adc:	00010497          	auipc	s1,0x10
    80000ae0:	7a448493          	addi	s1,s1,1956 # 80011280 <kmem>
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  r = kmem.freelist;
    80000aee:	6c84                	ld	s1,24(s1)
  if(r)
    80000af0:	c885                	beqz	s1,80000b20 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af2:	609c                	ld	a5,0(s1)
    80000af4:	00010517          	auipc	a0,0x10
    80000af8:	78c50513          	addi	a0,a0,1932 # 80011280 <kmem>
    80000afc:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	178080e7          	jalr	376(ra) # 80000c76 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4595                	li	a1,5
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	1b2080e7          	jalr	434(ra) # 80000cbe <memset>
  return (void*)r;
}
    80000b14:	8526                	mv	a0,s1
    80000b16:	60e2                	ld	ra,24(sp)
    80000b18:	6442                	ld	s0,16(sp)
    80000b1a:	64a2                	ld	s1,8(sp)
    80000b1c:	6105                	addi	sp,sp,32
    80000b1e:	8082                	ret
  release(&kmem.lock);
    80000b20:	00010517          	auipc	a0,0x10
    80000b24:	76050513          	addi	a0,a0,1888 # 80011280 <kmem>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	14e080e7          	jalr	334(ra) # 80000c76 <release>
  if(r)
    80000b30:	b7d5                	j	80000b14 <kalloc+0x42>

0000000080000b32 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b32:	1141                	addi	sp,sp,-16
    80000b34:	e422                	sd	s0,8(sp)
    80000b36:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b38:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b3a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b3e:	00053823          	sd	zero,16(a0)
}
    80000b42:	6422                	ld	s0,8(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b48:	411c                	lw	a5,0(a0)
    80000b4a:	e399                	bnez	a5,80000b50 <holding+0x8>
    80000b4c:	4501                	li	a0,0
  return r;
}
    80000b4e:	8082                	ret
{
    80000b50:	1101                	addi	sp,sp,-32
    80000b52:	ec06                	sd	ra,24(sp)
    80000b54:	e822                	sd	s0,16(sp)
    80000b56:	e426                	sd	s1,8(sp)
    80000b58:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b5a:	6904                	ld	s1,16(a0)
    80000b5c:	00001097          	auipc	ra,0x1
    80000b60:	e06080e7          	jalr	-506(ra) # 80001962 <mycpu>
    80000b64:	40a48533          	sub	a0,s1,a0
    80000b68:	00153513          	seqz	a0,a0
}
    80000b6c:	60e2                	ld	ra,24(sp)
    80000b6e:	6442                	ld	s0,16(sp)
    80000b70:	64a2                	ld	s1,8(sp)
    80000b72:	6105                	addi	sp,sp,32
    80000b74:	8082                	ret

0000000080000b76 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b76:	1101                	addi	sp,sp,-32
    80000b78:	ec06                	sd	ra,24(sp)
    80000b7a:	e822                	sd	s0,16(sp)
    80000b7c:	e426                	sd	s1,8(sp)
    80000b7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b80:	100024f3          	csrr	s1,sstatus
    80000b84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b88:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b8a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b8e:	00001097          	auipc	ra,0x1
    80000b92:	dd4080e7          	jalr	-556(ra) # 80001962 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	dc8080e7          	jalr	-568(ra) # 80001962 <mycpu>
    80000ba2:	5d3c                	lw	a5,120(a0)
    80000ba4:	2785                	addiw	a5,a5,1
    80000ba6:	dd3c                	sw	a5,120(a0)
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret
    mycpu()->intena = old;
    80000bb2:	00001097          	auipc	ra,0x1
    80000bb6:	db0080e7          	jalr	-592(ra) # 80001962 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bba:	8085                	srli	s1,s1,0x1
    80000bbc:	8885                	andi	s1,s1,1
    80000bbe:	dd64                	sw	s1,124(a0)
    80000bc0:	bfe9                	j	80000b9a <push_off+0x24>

0000000080000bc2 <acquire>:
{
    80000bc2:	1101                	addi	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	1000                	addi	s0,sp,32
    80000bcc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	fa8080e7          	jalr	-88(ra) # 80000b76 <push_off>
  if(holding(lk))
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	f70080e7          	jalr	-144(ra) # 80000b48 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be0:	4705                	li	a4,1
  if(holding(lk))
    80000be2:	e115                	bnez	a0,80000c06 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	87ba                	mv	a5,a4
    80000be6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bea:	2781                	sext.w	a5,a5
    80000bec:	ffe5                	bnez	a5,80000be4 <acquire+0x22>
  __sync_synchronize();
    80000bee:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	d70080e7          	jalr	-656(ra) # 80001962 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00007517          	auipc	a0,0x7
    80000c0a:	46a50513          	addi	a0,a0,1130 # 80008070 <digits+0x30>
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>

0000000080000c16 <pop_off>:

void
pop_off(void)
{
    80000c16:	1141                	addi	sp,sp,-16
    80000c18:	e406                	sd	ra,8(sp)
    80000c1a:	e022                	sd	s0,0(sp)
    80000c1c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1e:	00001097          	auipc	ra,0x1
    80000c22:	d44080e7          	jalr	-700(ra) # 80001962 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c26:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c2a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c2c:	e78d                	bnez	a5,80000c56 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	02f05b63          	blez	a5,80000c66 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c34:	37fd                	addiw	a5,a5,-1
    80000c36:	0007871b          	sext.w	a4,a5
    80000c3a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c3c:	eb09                	bnez	a4,80000c4e <pop_off+0x38>
    80000c3e:	5d7c                	lw	a5,124(a0)
    80000c40:	c799                	beqz	a5,80000c4e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c4a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c4e:	60a2                	ld	ra,8(sp)
    80000c50:	6402                	ld	s0,0(sp)
    80000c52:	0141                	addi	sp,sp,16
    80000c54:	8082                	ret
    panic("pop_off - interruptible");
    80000c56:	00007517          	auipc	a0,0x7
    80000c5a:	42250513          	addi	a0,a0,1058 # 80008078 <digits+0x38>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("pop_off");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80008090 <digits+0x50>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>

0000000080000c76 <release>:
{
    80000c76:	1101                	addi	sp,sp,-32
    80000c78:	ec06                	sd	ra,24(sp)
    80000c7a:	e822                	sd	s0,16(sp)
    80000c7c:	e426                	sd	s1,8(sp)
    80000c7e:	1000                	addi	s0,sp,32
    80000c80:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	ec6080e7          	jalr	-314(ra) # 80000b48 <holding>
    80000c8a:	c115                	beqz	a0,80000cae <release+0x38>
  lk->cpu = 0;
    80000c8c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c90:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c94:	0f50000f          	fence	iorw,ow
    80000c98:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	f7a080e7          	jalr	-134(ra) # 80000c16 <pop_off>
}
    80000ca4:	60e2                	ld	ra,24(sp)
    80000ca6:	6442                	ld	s0,16(sp)
    80000ca8:	64a2                	ld	s1,8(sp)
    80000caa:	6105                	addi	sp,sp,32
    80000cac:	8082                	ret
    panic("release");
    80000cae:	00007517          	auipc	a0,0x7
    80000cb2:	3ea50513          	addi	a0,a0,1002 # 80008098 <digits+0x58>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	874080e7          	jalr	-1932(ra) # 8000052a <panic>

0000000080000cbe <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cbe:	1141                	addi	sp,sp,-16
    80000cc0:	e422                	sd	s0,8(sp)
    80000cc2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cc4:	ca19                	beqz	a2,80000cda <memset+0x1c>
    80000cc6:	87aa                	mv	a5,a0
    80000cc8:	1602                	slli	a2,a2,0x20
    80000cca:	9201                	srli	a2,a2,0x20
    80000ccc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cd0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cd4:	0785                	addi	a5,a5,1
    80000cd6:	fee79de3          	bne	a5,a4,80000cd0 <memset+0x12>
  }
  return dst;
}
    80000cda:	6422                	ld	s0,8(sp)
    80000cdc:	0141                	addi	sp,sp,16
    80000cde:	8082                	ret

0000000080000ce0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ce6:	ca05                	beqz	a2,80000d16 <memcmp+0x36>
    80000ce8:	fff6069b          	addiw	a3,a2,-1
    80000cec:	1682                	slli	a3,a3,0x20
    80000cee:	9281                	srli	a3,a3,0x20
    80000cf0:	0685                	addi	a3,a3,1
    80000cf2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cf4:	00054783          	lbu	a5,0(a0)
    80000cf8:	0005c703          	lbu	a4,0(a1)
    80000cfc:	00e79863          	bne	a5,a4,80000d0c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d00:	0505                	addi	a0,a0,1
    80000d02:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d04:	fed518e3          	bne	a0,a3,80000cf4 <memcmp+0x14>
  }

  return 0;
    80000d08:	4501                	li	a0,0
    80000d0a:	a019                	j	80000d10 <memcmp+0x30>
      return *s1 - *s2;
    80000d0c:	40e7853b          	subw	a0,a5,a4
}
    80000d10:	6422                	ld	s0,8(sp)
    80000d12:	0141                	addi	sp,sp,16
    80000d14:	8082                	ret
  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	bfe5                	j	80000d10 <memcmp+0x30>

0000000080000d1a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d20:	02a5e563          	bltu	a1,a0,80000d4a <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	ce11                	beqz	a2,80000d44 <memmove+0x2a>
    80000d2a:	1682                	slli	a3,a3,0x20
    80000d2c:	9281                	srli	a3,a3,0x20
    80000d2e:	0685                	addi	a3,a3,1
    80000d30:	96ae                	add	a3,a3,a1
    80000d32:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d34:	0585                	addi	a1,a1,1
    80000d36:	0785                	addi	a5,a5,1
    80000d38:	fff5c703          	lbu	a4,-1(a1)
    80000d3c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d40:	fed59ae3          	bne	a1,a3,80000d34 <memmove+0x1a>

  return dst;
}
    80000d44:	6422                	ld	s0,8(sp)
    80000d46:	0141                	addi	sp,sp,16
    80000d48:	8082                	ret
  if(s < d && s + n > d){
    80000d4a:	02061713          	slli	a4,a2,0x20
    80000d4e:	9301                	srli	a4,a4,0x20
    80000d50:	00e587b3          	add	a5,a1,a4
    80000d54:	fcf578e3          	bgeu	a0,a5,80000d24 <memmove+0xa>
    d += n;
    80000d58:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d5a:	fff6069b          	addiw	a3,a2,-1
    80000d5e:	d27d                	beqz	a2,80000d44 <memmove+0x2a>
    80000d60:	02069613          	slli	a2,a3,0x20
    80000d64:	9201                	srli	a2,a2,0x20
    80000d66:	fff64613          	not	a2,a2
    80000d6a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d6c:	17fd                	addi	a5,a5,-1
    80000d6e:	177d                	addi	a4,a4,-1
    80000d70:	0007c683          	lbu	a3,0(a5)
    80000d74:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d78:	fef61ae3          	bne	a2,a5,80000d6c <memmove+0x52>
    80000d7c:	b7e1                	j	80000d44 <memmove+0x2a>

0000000080000d7e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	f94080e7          	jalr	-108(ra) # 80000d1a <memmove>
}
    80000d8e:	60a2                	ld	ra,8(sp)
    80000d90:	6402                	ld	s0,0(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret

0000000080000d96 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d9c:	ce11                	beqz	a2,80000db8 <strncmp+0x22>
    80000d9e:	00054783          	lbu	a5,0(a0)
    80000da2:	cf89                	beqz	a5,80000dbc <strncmp+0x26>
    80000da4:	0005c703          	lbu	a4,0(a1)
    80000da8:	00f71a63          	bne	a4,a5,80000dbc <strncmp+0x26>
    n--, p++, q++;
    80000dac:	367d                	addiw	a2,a2,-1
    80000dae:	0505                	addi	a0,a0,1
    80000db0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db2:	f675                	bnez	a2,80000d9e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000db4:	4501                	li	a0,0
    80000db6:	a809                	j	80000dc8 <strncmp+0x32>
    80000db8:	4501                	li	a0,0
    80000dba:	a039                	j	80000dc8 <strncmp+0x32>
  if(n == 0)
    80000dbc:	ca09                	beqz	a2,80000dce <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dbe:	00054503          	lbu	a0,0(a0)
    80000dc2:	0005c783          	lbu	a5,0(a1)
    80000dc6:	9d1d                	subw	a0,a0,a5
}
    80000dc8:	6422                	ld	s0,8(sp)
    80000dca:	0141                	addi	sp,sp,16
    80000dcc:	8082                	ret
    return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	bfe5                	j	80000dc8 <strncmp+0x32>

0000000080000dd2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dd8:	872a                	mv	a4,a0
    80000dda:	8832                	mv	a6,a2
    80000ddc:	367d                	addiw	a2,a2,-1
    80000dde:	01005963          	blez	a6,80000df0 <strncpy+0x1e>
    80000de2:	0705                	addi	a4,a4,1
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	fef70fa3          	sb	a5,-1(a4)
    80000dec:	0585                	addi	a1,a1,1
    80000dee:	f7f5                	bnez	a5,80000dda <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df0:	86ba                	mv	a3,a4
    80000df2:	00c05c63          	blez	a2,80000e0a <strncpy+0x38>
    *s++ = 0;
    80000df6:	0685                	addi	a3,a3,1
    80000df8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000dfc:	fff6c793          	not	a5,a3
    80000e00:	9fb9                	addw	a5,a5,a4
    80000e02:	010787bb          	addw	a5,a5,a6
    80000e06:	fef048e3          	bgtz	a5,80000df6 <strncpy+0x24>
  return os;
}
    80000e0a:	6422                	ld	s0,8(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret

0000000080000e10 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e16:	02c05363          	blez	a2,80000e3c <safestrcpy+0x2c>
    80000e1a:	fff6069b          	addiw	a3,a2,-1
    80000e1e:	1682                	slli	a3,a3,0x20
    80000e20:	9281                	srli	a3,a3,0x20
    80000e22:	96ae                	add	a3,a3,a1
    80000e24:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e26:	00d58963          	beq	a1,a3,80000e38 <safestrcpy+0x28>
    80000e2a:	0585                	addi	a1,a1,1
    80000e2c:	0785                	addi	a5,a5,1
    80000e2e:	fff5c703          	lbu	a4,-1(a1)
    80000e32:	fee78fa3          	sb	a4,-1(a5)
    80000e36:	fb65                	bnez	a4,80000e26 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e38:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e3c:	6422                	ld	s0,8(sp)
    80000e3e:	0141                	addi	sp,sp,16
    80000e40:	8082                	ret

0000000080000e42 <strlen>:

int
strlen(const char *s)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e422                	sd	s0,8(sp)
    80000e46:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e48:	00054783          	lbu	a5,0(a0)
    80000e4c:	cf91                	beqz	a5,80000e68 <strlen+0x26>
    80000e4e:	0505                	addi	a0,a0,1
    80000e50:	87aa                	mv	a5,a0
    80000e52:	4685                	li	a3,1
    80000e54:	9e89                	subw	a3,a3,a0
    80000e56:	00f6853b          	addw	a0,a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	fb7d                	bnez	a4,80000e56 <strlen+0x14>
    ;
  return n;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e68:	4501                	li	a0,0
    80000e6a:	bfe5                	j	80000e62 <strlen+0x20>

0000000080000e6c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e6c:	1141                	addi	sp,sp,-16
    80000e6e:	e406                	sd	ra,8(sp)
    80000e70:	e022                	sd	s0,0(sp)
    80000e72:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e74:	00001097          	auipc	ra,0x1
    80000e78:	ade080e7          	jalr	-1314(ra) # 80001952 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e7c:	00008717          	auipc	a4,0x8
    80000e80:	19c70713          	addi	a4,a4,412 # 80009018 <started>
  if(cpuid() == 0){
    80000e84:	c139                	beqz	a0,80000eca <main+0x5e>
    while(started == 0)
    80000e86:	431c                	lw	a5,0(a4)
    80000e88:	2781                	sext.w	a5,a5
    80000e8a:	dff5                	beqz	a5,80000e86 <main+0x1a>
      ;
    __sync_synchronize();
    80000e8c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e90:	00001097          	auipc	ra,0x1
    80000e94:	ac2080e7          	jalr	-1342(ra) # 80001952 <cpuid>
    80000e98:	85aa                	mv	a1,a0
    80000e9a:	00007517          	auipc	a0,0x7
    80000e9e:	21e50513          	addi	a0,a0,542 # 800080b8 <digits+0x78>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	6d2080e7          	jalr	1746(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	0d8080e7          	jalr	216(ra) # 80000f82 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb2:	00002097          	auipc	ra,0x2
    80000eb6:	b64080e7          	jalr	-1180(ra) # 80002a16 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	216080e7          	jalr	534(ra) # 800060d0 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	1ac080e7          	jalr	428(ra) # 8000206e <scheduler>
    consoleinit();
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	572080e7          	jalr	1394(ra) # 8000043c <consoleinit>
    printfinit();
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	882080e7          	jalr	-1918(ra) # 80000754 <printfinit>
    printf("\n");
    80000eda:	00007517          	auipc	a0,0x7
    80000ede:	1ee50513          	addi	a0,a0,494 # 800080c8 <digits+0x88>
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	692080e7          	jalr	1682(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000eea:	00007517          	auipc	a0,0x7
    80000eee:	1b650513          	addi	a0,a0,438 # 800080a0 <digits+0x60>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("\n");
    80000efa:	00007517          	auipc	a0,0x7
    80000efe:	1ce50513          	addi	a0,a0,462 # 800080c8 <digits+0x88>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	b8c080e7          	jalr	-1140(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	310080e7          	jalr	784(ra) # 80001222 <kvminit>
    kvminithart();   // turn on paging
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	068080e7          	jalr	104(ra) # 80000f82 <kvminithart>
    procinit();      // process table
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	980080e7          	jalr	-1664(ra) # 800018a2 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	ac4080e7          	jalr	-1340(ra) # 800029ee <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	ae4080e7          	jalr	-1308(ra) # 80002a16 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	180080e7          	jalr	384(ra) # 800060ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	18e080e7          	jalr	398(ra) # 800060d0 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	35e080e7          	jalr	862(ra) # 800032a8 <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	9f0080e7          	jalr	-1552(ra) # 80003942 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	99e080e7          	jalr	-1634(ra) # 800048f8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	290080e7          	jalr	656(ra) # 800061f2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	cfa080e7          	jalr	-774(ra) # 80001c64 <userinit>
    __sync_synchronize();
    80000f72:	0ff0000f          	fence
    started = 1;
    80000f76:	4785                	li	a5,1
    80000f78:	00008717          	auipc	a4,0x8
    80000f7c:	0af72023          	sw	a5,160(a4) # 80009018 <started>
    80000f80:	b789                	j	80000ec2 <main+0x56>

0000000080000f82 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f82:	1141                	addi	sp,sp,-16
    80000f84:	e422                	sd	s0,8(sp)
    80000f86:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f88:	00008797          	auipc	a5,0x8
    80000f8c:	0987b783          	ld	a5,152(a5) # 80009020 <kernel_pagetable>
    80000f90:	83b1                	srli	a5,a5,0xc
    80000f92:	577d                	li	a4,-1
    80000f94:	177e                	slli	a4,a4,0x3f
    80000f96:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f98:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f9c:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa0:	6422                	ld	s0,8(sp)
    80000fa2:	0141                	addi	sp,sp,16
    80000fa4:	8082                	ret

0000000080000fa6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fa6:	7139                	addi	sp,sp,-64
    80000fa8:	fc06                	sd	ra,56(sp)
    80000faa:	f822                	sd	s0,48(sp)
    80000fac:	f426                	sd	s1,40(sp)
    80000fae:	f04a                	sd	s2,32(sp)
    80000fb0:	ec4e                	sd	s3,24(sp)
    80000fb2:	e852                	sd	s4,16(sp)
    80000fb4:	e456                	sd	s5,8(sp)
    80000fb6:	e05a                	sd	s6,0(sp)
    80000fb8:	0080                	addi	s0,sp,64
    80000fba:	84aa                	mv	s1,a0
    80000fbc:	89ae                	mv	s3,a1
    80000fbe:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc0:	57fd                	li	a5,-1
    80000fc2:	83e9                	srli	a5,a5,0x1a
    80000fc4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fc6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fc8:	04b7f263          	bgeu	a5,a1,8000100c <walk+0x66>
    panic("walk");
    80000fcc:	00007517          	auipc	a0,0x7
    80000fd0:	10450513          	addi	a0,a0,260 # 800080d0 <digits+0x90>
    80000fd4:	fffff097          	auipc	ra,0xfffff
    80000fd8:	556080e7          	jalr	1366(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fdc:	060a8663          	beqz	s5,80001048 <walk+0xa2>
    80000fe0:	00000097          	auipc	ra,0x0
    80000fe4:	af2080e7          	jalr	-1294(ra) # 80000ad2 <kalloc>
    80000fe8:	84aa                	mv	s1,a0
    80000fea:	c529                	beqz	a0,80001034 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000fec:	6605                	lui	a2,0x1
    80000fee:	4581                	li	a1,0
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	cce080e7          	jalr	-818(ra) # 80000cbe <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ff8:	00c4d793          	srli	a5,s1,0xc
    80000ffc:	07aa                	slli	a5,a5,0xa
    80000ffe:	0017e793          	ori	a5,a5,1
    80001002:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001006:	3a5d                	addiw	s4,s4,-9
    80001008:	036a0063          	beq	s4,s6,80001028 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000100c:	0149d933          	srl	s2,s3,s4
    80001010:	1ff97913          	andi	s2,s2,511
    80001014:	090e                	slli	s2,s2,0x3
    80001016:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001018:	00093483          	ld	s1,0(s2)
    8000101c:	0014f793          	andi	a5,s1,1
    80001020:	dfd5                	beqz	a5,80000fdc <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001022:	80a9                	srli	s1,s1,0xa
    80001024:	04b2                	slli	s1,s1,0xc
    80001026:	b7c5                	j	80001006 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001028:	00c9d513          	srli	a0,s3,0xc
    8000102c:	1ff57513          	andi	a0,a0,511
    80001030:	050e                	slli	a0,a0,0x3
    80001032:	9526                	add	a0,a0,s1
}
    80001034:	70e2                	ld	ra,56(sp)
    80001036:	7442                	ld	s0,48(sp)
    80001038:	74a2                	ld	s1,40(sp)
    8000103a:	7902                	ld	s2,32(sp)
    8000103c:	69e2                	ld	s3,24(sp)
    8000103e:	6a42                	ld	s4,16(sp)
    80001040:	6aa2                	ld	s5,8(sp)
    80001042:	6b02                	ld	s6,0(sp)
    80001044:	6121                	addi	sp,sp,64
    80001046:	8082                	ret
        return 0;
    80001048:	4501                	li	a0,0
    8000104a:	b7ed                	j	80001034 <walk+0x8e>

000000008000104c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000104c:	57fd                	li	a5,-1
    8000104e:	83e9                	srli	a5,a5,0x1a
    80001050:	00b7f463          	bgeu	a5,a1,80001058 <walkaddr+0xc>
    return 0;
    80001054:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001056:	8082                	ret
{
    80001058:	1141                	addi	sp,sp,-16
    8000105a:	e406                	sd	ra,8(sp)
    8000105c:	e022                	sd	s0,0(sp)
    8000105e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001060:	4601                	li	a2,0
    80001062:	00000097          	auipc	ra,0x0
    80001066:	f44080e7          	jalr	-188(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000106a:	c105                	beqz	a0,8000108a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000106c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000106e:	0117f693          	andi	a3,a5,17
    80001072:	4745                	li	a4,17
    return 0;
    80001074:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001076:	00e68663          	beq	a3,a4,80001082 <walkaddr+0x36>
}
    8000107a:	60a2                	ld	ra,8(sp)
    8000107c:	6402                	ld	s0,0(sp)
    8000107e:	0141                	addi	sp,sp,16
    80001080:	8082                	ret
  pa = PTE2PA(*pte);
    80001082:	00a7d513          	srli	a0,a5,0xa
    80001086:	0532                	slli	a0,a0,0xc
  return pa;
    80001088:	bfcd                	j	8000107a <walkaddr+0x2e>
    return 0;
    8000108a:	4501                	li	a0,0
    8000108c:	b7fd                	j	8000107a <walkaddr+0x2e>

000000008000108e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000108e:	715d                	addi	sp,sp,-80
    80001090:	e486                	sd	ra,72(sp)
    80001092:	e0a2                	sd	s0,64(sp)
    80001094:	fc26                	sd	s1,56(sp)
    80001096:	f84a                	sd	s2,48(sp)
    80001098:	f44e                	sd	s3,40(sp)
    8000109a:	f052                	sd	s4,32(sp)
    8000109c:	ec56                	sd	s5,24(sp)
    8000109e:	e85a                	sd	s6,16(sp)
    800010a0:	e45e                	sd	s7,8(sp)
    800010a2:	0880                	addi	s0,sp,80
    800010a4:	8aaa                	mv	s5,a0
    800010a6:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010a8:	777d                	lui	a4,0xfffff
    800010aa:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ae:	167d                	addi	a2,a2,-1
    800010b0:	00b609b3          	add	s3,a2,a1
    800010b4:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010b8:	893e                	mv	s2,a5
    800010ba:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010be:	6b85                	lui	s7,0x1
    800010c0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010c4:	4605                	li	a2,1
    800010c6:	85ca                	mv	a1,s2
    800010c8:	8556                	mv	a0,s5
    800010ca:	00000097          	auipc	ra,0x0
    800010ce:	edc080e7          	jalr	-292(ra) # 80000fa6 <walk>
    800010d2:	c51d                	beqz	a0,80001100 <mappages+0x72>
    if(*pte & PTE_V)
    800010d4:	611c                	ld	a5,0(a0)
    800010d6:	8b85                	andi	a5,a5,1
    800010d8:	ef81                	bnez	a5,800010f0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010da:	80b1                	srli	s1,s1,0xc
    800010dc:	04aa                	slli	s1,s1,0xa
    800010de:	0164e4b3          	or	s1,s1,s6
    800010e2:	0014e493          	ori	s1,s1,1
    800010e6:	e104                	sd	s1,0(a0)
    if(a == last)
    800010e8:	03390863          	beq	s2,s3,80001118 <mappages+0x8a>
    a += PGSIZE;
    800010ec:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010ee:	bfc9                	j	800010c0 <mappages+0x32>
      panic("remap");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	432080e7          	jalr	1074(ra) # 8000052a <panic>
      return -1;
    80001100:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001102:	60a6                	ld	ra,72(sp)
    80001104:	6406                	ld	s0,64(sp)
    80001106:	74e2                	ld	s1,56(sp)
    80001108:	7942                	ld	s2,48(sp)
    8000110a:	79a2                	ld	s3,40(sp)
    8000110c:	7a02                	ld	s4,32(sp)
    8000110e:	6ae2                	ld	s5,24(sp)
    80001110:	6b42                	ld	s6,16(sp)
    80001112:	6ba2                	ld	s7,8(sp)
    80001114:	6161                	addi	sp,sp,80
    80001116:	8082                	ret
  return 0;
    80001118:	4501                	li	a0,0
    8000111a:	b7e5                	j	80001102 <mappages+0x74>

000000008000111c <kvmmap>:
{
    8000111c:	1141                	addi	sp,sp,-16
    8000111e:	e406                	sd	ra,8(sp)
    80001120:	e022                	sd	s0,0(sp)
    80001122:	0800                	addi	s0,sp,16
    80001124:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001126:	86b2                	mv	a3,a2
    80001128:	863e                	mv	a2,a5
    8000112a:	00000097          	auipc	ra,0x0
    8000112e:	f64080e7          	jalr	-156(ra) # 8000108e <mappages>
    80001132:	e509                	bnez	a0,8000113c <kvmmap+0x20>
}
    80001134:	60a2                	ld	ra,8(sp)
    80001136:	6402                	ld	s0,0(sp)
    80001138:	0141                	addi	sp,sp,16
    8000113a:	8082                	ret
    panic("kvmmap");
    8000113c:	00007517          	auipc	a0,0x7
    80001140:	fa450513          	addi	a0,a0,-92 # 800080e0 <digits+0xa0>
    80001144:	fffff097          	auipc	ra,0xfffff
    80001148:	3e6080e7          	jalr	998(ra) # 8000052a <panic>

000000008000114c <kvmmake>:
{
    8000114c:	1101                	addi	sp,sp,-32
    8000114e:	ec06                	sd	ra,24(sp)
    80001150:	e822                	sd	s0,16(sp)
    80001152:	e426                	sd	s1,8(sp)
    80001154:	e04a                	sd	s2,0(sp)
    80001156:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001158:	00000097          	auipc	ra,0x0
    8000115c:	97a080e7          	jalr	-1670(ra) # 80000ad2 <kalloc>
    80001160:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001162:	6605                	lui	a2,0x1
    80001164:	4581                	li	a1,0
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	b58080e7          	jalr	-1192(ra) # 80000cbe <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000116e:	4719                	li	a4,6
    80001170:	6685                	lui	a3,0x1
    80001172:	10000637          	lui	a2,0x10000
    80001176:	100005b7          	lui	a1,0x10000
    8000117a:	8526                	mv	a0,s1
    8000117c:	00000097          	auipc	ra,0x0
    80001180:	fa0080e7          	jalr	-96(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001184:	4719                	li	a4,6
    80001186:	6685                	lui	a3,0x1
    80001188:	10001637          	lui	a2,0x10001
    8000118c:	100015b7          	lui	a1,0x10001
    80001190:	8526                	mv	a0,s1
    80001192:	00000097          	auipc	ra,0x0
    80001196:	f8a080e7          	jalr	-118(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000119a:	4719                	li	a4,6
    8000119c:	004006b7          	lui	a3,0x400
    800011a0:	0c000637          	lui	a2,0xc000
    800011a4:	0c0005b7          	lui	a1,0xc000
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f72080e7          	jalr	-142(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011b2:	00007917          	auipc	s2,0x7
    800011b6:	e4e90913          	addi	s2,s2,-434 # 80008000 <etext>
    800011ba:	4729                	li	a4,10
    800011bc:	80007697          	auipc	a3,0x80007
    800011c0:	e4468693          	addi	a3,a3,-444 # 8000 <_entry-0x7fff8000>
    800011c4:	4605                	li	a2,1
    800011c6:	067e                	slli	a2,a2,0x1f
    800011c8:	85b2                	mv	a1,a2
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f50080e7          	jalr	-176(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011d4:	4719                	li	a4,6
    800011d6:	46c5                	li	a3,17
    800011d8:	06ee                	slli	a3,a3,0x1b
    800011da:	412686b3          	sub	a3,a3,s2
    800011de:	864a                	mv	a2,s2
    800011e0:	85ca                	mv	a1,s2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f38080e7          	jalr	-200(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011ec:	4729                	li	a4,10
    800011ee:	6685                	lui	a3,0x1
    800011f0:	00006617          	auipc	a2,0x6
    800011f4:	e1060613          	addi	a2,a2,-496 # 80007000 <_trampoline>
    800011f8:	040005b7          	lui	a1,0x4000
    800011fc:	15fd                	addi	a1,a1,-1
    800011fe:	05b2                	slli	a1,a1,0xc
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	f1a080e7          	jalr	-230(ra) # 8000111c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000120a:	8526                	mv	a0,s1
    8000120c:	00000097          	auipc	ra,0x0
    80001210:	600080e7          	jalr	1536(ra) # 8000180c <proc_mapstacks>
}
    80001214:	8526                	mv	a0,s1
    80001216:	60e2                	ld	ra,24(sp)
    80001218:	6442                	ld	s0,16(sp)
    8000121a:	64a2                	ld	s1,8(sp)
    8000121c:	6902                	ld	s2,0(sp)
    8000121e:	6105                	addi	sp,sp,32
    80001220:	8082                	ret

0000000080001222 <kvminit>:
{
    80001222:	1141                	addi	sp,sp,-16
    80001224:	e406                	sd	ra,8(sp)
    80001226:	e022                	sd	s0,0(sp)
    80001228:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	f22080e7          	jalr	-222(ra) # 8000114c <kvmmake>
    80001232:	00008797          	auipc	a5,0x8
    80001236:	dea7b723          	sd	a0,-530(a5) # 80009020 <kernel_pagetable>
}
    8000123a:	60a2                	ld	ra,8(sp)
    8000123c:	6402                	ld	s0,0(sp)
    8000123e:	0141                	addi	sp,sp,16
    80001240:	8082                	ret

0000000080001242 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001242:	715d                	addi	sp,sp,-80
    80001244:	e486                	sd	ra,72(sp)
    80001246:	e0a2                	sd	s0,64(sp)
    80001248:	fc26                	sd	s1,56(sp)
    8000124a:	f84a                	sd	s2,48(sp)
    8000124c:	f44e                	sd	s3,40(sp)
    8000124e:	f052                	sd	s4,32(sp)
    80001250:	ec56                	sd	s5,24(sp)
    80001252:	e85a                	sd	s6,16(sp)
    80001254:	e45e                	sd	s7,8(sp)
    80001256:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001258:	03459793          	slli	a5,a1,0x34
    8000125c:	e795                	bnez	a5,80001288 <uvmunmap+0x46>
    8000125e:	8a2a                	mv	s4,a0
    80001260:	892e                	mv	s2,a1
    80001262:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001264:	0632                	slli	a2,a2,0xc
    80001266:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000126a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000126c:	6b05                	lui	s6,0x1
    8000126e:	0735e263          	bltu	a1,s3,800012d2 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001272:	60a6                	ld	ra,72(sp)
    80001274:	6406                	ld	s0,64(sp)
    80001276:	74e2                	ld	s1,56(sp)
    80001278:	7942                	ld	s2,48(sp)
    8000127a:	79a2                	ld	s3,40(sp)
    8000127c:	7a02                	ld	s4,32(sp)
    8000127e:	6ae2                	ld	s5,24(sp)
    80001280:	6b42                	ld	s6,16(sp)
    80001282:	6ba2                	ld	s7,8(sp)
    80001284:	6161                	addi	sp,sp,80
    80001286:	8082                	ret
    panic("uvmunmap: not aligned");
    80001288:	00007517          	auipc	a0,0x7
    8000128c:	e6050513          	addi	a0,a0,-416 # 800080e8 <digits+0xa8>
    80001290:	fffff097          	auipc	ra,0xfffff
    80001294:	29a080e7          	jalr	666(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    80001298:	00007517          	auipc	a0,0x7
    8000129c:	e6850513          	addi	a0,a0,-408 # 80008100 <digits+0xc0>
    800012a0:	fffff097          	auipc	ra,0xfffff
    800012a4:	28a080e7          	jalr	650(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012a8:	00007517          	auipc	a0,0x7
    800012ac:	e6850513          	addi	a0,a0,-408 # 80008110 <digits+0xd0>
    800012b0:	fffff097          	auipc	ra,0xfffff
    800012b4:	27a080e7          	jalr	634(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012b8:	00007517          	auipc	a0,0x7
    800012bc:	e7050513          	addi	a0,a0,-400 # 80008128 <digits+0xe8>
    800012c0:	fffff097          	auipc	ra,0xfffff
    800012c4:	26a080e7          	jalr	618(ra) # 8000052a <panic>
    *pte = 0;
    800012c8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012cc:	995a                	add	s2,s2,s6
    800012ce:	fb3972e3          	bgeu	s2,s3,80001272 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012d2:	4601                	li	a2,0
    800012d4:	85ca                	mv	a1,s2
    800012d6:	8552                	mv	a0,s4
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	cce080e7          	jalr	-818(ra) # 80000fa6 <walk>
    800012e0:	84aa                	mv	s1,a0
    800012e2:	d95d                	beqz	a0,80001298 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012e4:	6108                	ld	a0,0(a0)
    800012e6:	00157793          	andi	a5,a0,1
    800012ea:	dfdd                	beqz	a5,800012a8 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ec:	3ff57793          	andi	a5,a0,1023
    800012f0:	fd7784e3          	beq	a5,s7,800012b8 <uvmunmap+0x76>
    if(do_free){
    800012f4:	fc0a8ae3          	beqz	s5,800012c8 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800012f8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fa:	0532                	slli	a0,a0,0xc
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	6da080e7          	jalr	1754(ra) # 800009d6 <kfree>
    80001304:	b7d1                	j	800012c8 <uvmunmap+0x86>

0000000080001306 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001306:	1101                	addi	sp,sp,-32
    80001308:	ec06                	sd	ra,24(sp)
    8000130a:	e822                	sd	s0,16(sp)
    8000130c:	e426                	sd	s1,8(sp)
    8000130e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001310:	fffff097          	auipc	ra,0xfffff
    80001314:	7c2080e7          	jalr	1986(ra) # 80000ad2 <kalloc>
    80001318:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000131a:	c519                	beqz	a0,80001328 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000131c:	6605                	lui	a2,0x1
    8000131e:	4581                	li	a1,0
    80001320:	00000097          	auipc	ra,0x0
    80001324:	99e080e7          	jalr	-1634(ra) # 80000cbe <memset>
  return pagetable;
}
    80001328:	8526                	mv	a0,s1
    8000132a:	60e2                	ld	ra,24(sp)
    8000132c:	6442                	ld	s0,16(sp)
    8000132e:	64a2                	ld	s1,8(sp)
    80001330:	6105                	addi	sp,sp,32
    80001332:	8082                	ret

0000000080001334 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001334:	7179                	addi	sp,sp,-48
    80001336:	f406                	sd	ra,40(sp)
    80001338:	f022                	sd	s0,32(sp)
    8000133a:	ec26                	sd	s1,24(sp)
    8000133c:	e84a                	sd	s2,16(sp)
    8000133e:	e44e                	sd	s3,8(sp)
    80001340:	e052                	sd	s4,0(sp)
    80001342:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001344:	6785                	lui	a5,0x1
    80001346:	04f67863          	bgeu	a2,a5,80001396 <uvminit+0x62>
    8000134a:	8a2a                	mv	s4,a0
    8000134c:	89ae                	mv	s3,a1
    8000134e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001350:	fffff097          	auipc	ra,0xfffff
    80001354:	782080e7          	jalr	1922(ra) # 80000ad2 <kalloc>
    80001358:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	960080e7          	jalr	-1696(ra) # 80000cbe <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001366:	4779                	li	a4,30
    80001368:	86ca                	mv	a3,s2
    8000136a:	6605                	lui	a2,0x1
    8000136c:	4581                	li	a1,0
    8000136e:	8552                	mv	a0,s4
    80001370:	00000097          	auipc	ra,0x0
    80001374:	d1e080e7          	jalr	-738(ra) # 8000108e <mappages>
  memmove(mem, src, sz);
    80001378:	8626                	mv	a2,s1
    8000137a:	85ce                	mv	a1,s3
    8000137c:	854a                	mv	a0,s2
    8000137e:	00000097          	auipc	ra,0x0
    80001382:	99c080e7          	jalr	-1636(ra) # 80000d1a <memmove>
}
    80001386:	70a2                	ld	ra,40(sp)
    80001388:	7402                	ld	s0,32(sp)
    8000138a:	64e2                	ld	s1,24(sp)
    8000138c:	6942                	ld	s2,16(sp)
    8000138e:	69a2                	ld	s3,8(sp)
    80001390:	6a02                	ld	s4,0(sp)
    80001392:	6145                	addi	sp,sp,48
    80001394:	8082                	ret
    panic("inituvm: more than a page");
    80001396:	00007517          	auipc	a0,0x7
    8000139a:	daa50513          	addi	a0,a0,-598 # 80008140 <digits+0x100>
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	18c080e7          	jalr	396(ra) # 8000052a <panic>

00000000800013a6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013a6:	1101                	addi	sp,sp,-32
    800013a8:	ec06                	sd	ra,24(sp)
    800013aa:	e822                	sd	s0,16(sp)
    800013ac:	e426                	sd	s1,8(sp)
    800013ae:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013b0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013b2:	00b67d63          	bgeu	a2,a1,800013cc <uvmdealloc+0x26>
    800013b6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013b8:	6785                	lui	a5,0x1
    800013ba:	17fd                	addi	a5,a5,-1
    800013bc:	00f60733          	add	a4,a2,a5
    800013c0:	767d                	lui	a2,0xfffff
    800013c2:	8f71                	and	a4,a4,a2
    800013c4:	97ae                	add	a5,a5,a1
    800013c6:	8ff1                	and	a5,a5,a2
    800013c8:	00f76863          	bltu	a4,a5,800013d8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013cc:	8526                	mv	a0,s1
    800013ce:	60e2                	ld	ra,24(sp)
    800013d0:	6442                	ld	s0,16(sp)
    800013d2:	64a2                	ld	s1,8(sp)
    800013d4:	6105                	addi	sp,sp,32
    800013d6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013d8:	8f99                	sub	a5,a5,a4
    800013da:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013dc:	4685                	li	a3,1
    800013de:	0007861b          	sext.w	a2,a5
    800013e2:	85ba                	mv	a1,a4
    800013e4:	00000097          	auipc	ra,0x0
    800013e8:	e5e080e7          	jalr	-418(ra) # 80001242 <uvmunmap>
    800013ec:	b7c5                	j	800013cc <uvmdealloc+0x26>

00000000800013ee <uvmalloc>:
  if(newsz < oldsz)
    800013ee:	0ab66163          	bltu	a2,a1,80001490 <uvmalloc+0xa2>
{
    800013f2:	7139                	addi	sp,sp,-64
    800013f4:	fc06                	sd	ra,56(sp)
    800013f6:	f822                	sd	s0,48(sp)
    800013f8:	f426                	sd	s1,40(sp)
    800013fa:	f04a                	sd	s2,32(sp)
    800013fc:	ec4e                	sd	s3,24(sp)
    800013fe:	e852                	sd	s4,16(sp)
    80001400:	e456                	sd	s5,8(sp)
    80001402:	0080                	addi	s0,sp,64
    80001404:	8aaa                	mv	s5,a0
    80001406:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001408:	6985                	lui	s3,0x1
    8000140a:	19fd                	addi	s3,s3,-1
    8000140c:	95ce                	add	a1,a1,s3
    8000140e:	79fd                	lui	s3,0xfffff
    80001410:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001414:	08c9f063          	bgeu	s3,a2,80001494 <uvmalloc+0xa6>
    80001418:	894e                	mv	s2,s3
    mem = kalloc();
    8000141a:	fffff097          	auipc	ra,0xfffff
    8000141e:	6b8080e7          	jalr	1720(ra) # 80000ad2 <kalloc>
    80001422:	84aa                	mv	s1,a0
    if(mem == 0){
    80001424:	c51d                	beqz	a0,80001452 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001426:	6605                	lui	a2,0x1
    80001428:	4581                	li	a1,0
    8000142a:	00000097          	auipc	ra,0x0
    8000142e:	894080e7          	jalr	-1900(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001432:	4779                	li	a4,30
    80001434:	86a6                	mv	a3,s1
    80001436:	6605                	lui	a2,0x1
    80001438:	85ca                	mv	a1,s2
    8000143a:	8556                	mv	a0,s5
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	c52080e7          	jalr	-942(ra) # 8000108e <mappages>
    80001444:	e905                	bnez	a0,80001474 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001446:	6785                	lui	a5,0x1
    80001448:	993e                	add	s2,s2,a5
    8000144a:	fd4968e3          	bltu	s2,s4,8000141a <uvmalloc+0x2c>
  return newsz;
    8000144e:	8552                	mv	a0,s4
    80001450:	a809                	j	80001462 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001452:	864e                	mv	a2,s3
    80001454:	85ca                	mv	a1,s2
    80001456:	8556                	mv	a0,s5
    80001458:	00000097          	auipc	ra,0x0
    8000145c:	f4e080e7          	jalr	-178(ra) # 800013a6 <uvmdealloc>
      return 0;
    80001460:	4501                	li	a0,0
}
    80001462:	70e2                	ld	ra,56(sp)
    80001464:	7442                	ld	s0,48(sp)
    80001466:	74a2                	ld	s1,40(sp)
    80001468:	7902                	ld	s2,32(sp)
    8000146a:	69e2                	ld	s3,24(sp)
    8000146c:	6a42                	ld	s4,16(sp)
    8000146e:	6aa2                	ld	s5,8(sp)
    80001470:	6121                	addi	sp,sp,64
    80001472:	8082                	ret
      kfree(mem);
    80001474:	8526                	mv	a0,s1
    80001476:	fffff097          	auipc	ra,0xfffff
    8000147a:	560080e7          	jalr	1376(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000147e:	864e                	mv	a2,s3
    80001480:	85ca                	mv	a1,s2
    80001482:	8556                	mv	a0,s5
    80001484:	00000097          	auipc	ra,0x0
    80001488:	f22080e7          	jalr	-222(ra) # 800013a6 <uvmdealloc>
      return 0;
    8000148c:	4501                	li	a0,0
    8000148e:	bfd1                	j	80001462 <uvmalloc+0x74>
    return oldsz;
    80001490:	852e                	mv	a0,a1
}
    80001492:	8082                	ret
  return newsz;
    80001494:	8532                	mv	a0,a2
    80001496:	b7f1                	j	80001462 <uvmalloc+0x74>

0000000080001498 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001498:	7179                	addi	sp,sp,-48
    8000149a:	f406                	sd	ra,40(sp)
    8000149c:	f022                	sd	s0,32(sp)
    8000149e:	ec26                	sd	s1,24(sp)
    800014a0:	e84a                	sd	s2,16(sp)
    800014a2:	e44e                	sd	s3,8(sp)
    800014a4:	e052                	sd	s4,0(sp)
    800014a6:	1800                	addi	s0,sp,48
    800014a8:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014aa:	84aa                	mv	s1,a0
    800014ac:	6905                	lui	s2,0x1
    800014ae:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014b0:	4985                	li	s3,1
    800014b2:	a821                	j	800014ca <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014b4:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014b6:	0532                	slli	a0,a0,0xc
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	fe0080e7          	jalr	-32(ra) # 80001498 <freewalk>
      pagetable[i] = 0;
    800014c0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014c4:	04a1                	addi	s1,s1,8
    800014c6:	03248163          	beq	s1,s2,800014e8 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014ca:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014cc:	00f57793          	andi	a5,a0,15
    800014d0:	ff3782e3          	beq	a5,s3,800014b4 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014d4:	8905                	andi	a0,a0,1
    800014d6:	d57d                	beqz	a0,800014c4 <freewalk+0x2c>
      panic("freewalk: leaf");
    800014d8:	00007517          	auipc	a0,0x7
    800014dc:	c8850513          	addi	a0,a0,-888 # 80008160 <digits+0x120>
    800014e0:	fffff097          	auipc	ra,0xfffff
    800014e4:	04a080e7          	jalr	74(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    800014e8:	8552                	mv	a0,s4
    800014ea:	fffff097          	auipc	ra,0xfffff
    800014ee:	4ec080e7          	jalr	1260(ra) # 800009d6 <kfree>
}
    800014f2:	70a2                	ld	ra,40(sp)
    800014f4:	7402                	ld	s0,32(sp)
    800014f6:	64e2                	ld	s1,24(sp)
    800014f8:	6942                	ld	s2,16(sp)
    800014fa:	69a2                	ld	s3,8(sp)
    800014fc:	6a02                	ld	s4,0(sp)
    800014fe:	6145                	addi	sp,sp,48
    80001500:	8082                	ret

0000000080001502 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001502:	1101                	addi	sp,sp,-32
    80001504:	ec06                	sd	ra,24(sp)
    80001506:	e822                	sd	s0,16(sp)
    80001508:	e426                	sd	s1,8(sp)
    8000150a:	1000                	addi	s0,sp,32
    8000150c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000150e:	e999                	bnez	a1,80001524 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001510:	8526                	mv	a0,s1
    80001512:	00000097          	auipc	ra,0x0
    80001516:	f86080e7          	jalr	-122(ra) # 80001498 <freewalk>
}
    8000151a:	60e2                	ld	ra,24(sp)
    8000151c:	6442                	ld	s0,16(sp)
    8000151e:	64a2                	ld	s1,8(sp)
    80001520:	6105                	addi	sp,sp,32
    80001522:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001524:	6605                	lui	a2,0x1
    80001526:	167d                	addi	a2,a2,-1
    80001528:	962e                	add	a2,a2,a1
    8000152a:	4685                	li	a3,1
    8000152c:	8231                	srli	a2,a2,0xc
    8000152e:	4581                	li	a1,0
    80001530:	00000097          	auipc	ra,0x0
    80001534:	d12080e7          	jalr	-750(ra) # 80001242 <uvmunmap>
    80001538:	bfe1                	j	80001510 <uvmfree+0xe>

000000008000153a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000153a:	c679                	beqz	a2,80001608 <uvmcopy+0xce>
{
    8000153c:	715d                	addi	sp,sp,-80
    8000153e:	e486                	sd	ra,72(sp)
    80001540:	e0a2                	sd	s0,64(sp)
    80001542:	fc26                	sd	s1,56(sp)
    80001544:	f84a                	sd	s2,48(sp)
    80001546:	f44e                	sd	s3,40(sp)
    80001548:	f052                	sd	s4,32(sp)
    8000154a:	ec56                	sd	s5,24(sp)
    8000154c:	e85a                	sd	s6,16(sp)
    8000154e:	e45e                	sd	s7,8(sp)
    80001550:	0880                	addi	s0,sp,80
    80001552:	8b2a                	mv	s6,a0
    80001554:	8aae                	mv	s5,a1
    80001556:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001558:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000155a:	4601                	li	a2,0
    8000155c:	85ce                	mv	a1,s3
    8000155e:	855a                	mv	a0,s6
    80001560:	00000097          	auipc	ra,0x0
    80001564:	a46080e7          	jalr	-1466(ra) # 80000fa6 <walk>
    80001568:	c531                	beqz	a0,800015b4 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000156a:	6118                	ld	a4,0(a0)
    8000156c:	00177793          	andi	a5,a4,1
    80001570:	cbb1                	beqz	a5,800015c4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001572:	00a75593          	srli	a1,a4,0xa
    80001576:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000157a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000157e:	fffff097          	auipc	ra,0xfffff
    80001582:	554080e7          	jalr	1364(ra) # 80000ad2 <kalloc>
    80001586:	892a                	mv	s2,a0
    80001588:	c939                	beqz	a0,800015de <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000158a:	6605                	lui	a2,0x1
    8000158c:	85de                	mv	a1,s7
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	78c080e7          	jalr	1932(ra) # 80000d1a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001596:	8726                	mv	a4,s1
    80001598:	86ca                	mv	a3,s2
    8000159a:	6605                	lui	a2,0x1
    8000159c:	85ce                	mv	a1,s3
    8000159e:	8556                	mv	a0,s5
    800015a0:	00000097          	auipc	ra,0x0
    800015a4:	aee080e7          	jalr	-1298(ra) # 8000108e <mappages>
    800015a8:	e515                	bnez	a0,800015d4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015aa:	6785                	lui	a5,0x1
    800015ac:	99be                	add	s3,s3,a5
    800015ae:	fb49e6e3          	bltu	s3,s4,8000155a <uvmcopy+0x20>
    800015b2:	a081                	j	800015f2 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015b4:	00007517          	auipc	a0,0x7
    800015b8:	bbc50513          	addi	a0,a0,-1092 # 80008170 <digits+0x130>
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	f6e080e7          	jalr	-146(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    800015c4:	00007517          	auipc	a0,0x7
    800015c8:	bcc50513          	addi	a0,a0,-1076 # 80008190 <digits+0x150>
    800015cc:	fffff097          	auipc	ra,0xfffff
    800015d0:	f5e080e7          	jalr	-162(ra) # 8000052a <panic>
      kfree(mem);
    800015d4:	854a                	mv	a0,s2
    800015d6:	fffff097          	auipc	ra,0xfffff
    800015da:	400080e7          	jalr	1024(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015de:	4685                	li	a3,1
    800015e0:	00c9d613          	srli	a2,s3,0xc
    800015e4:	4581                	li	a1,0
    800015e6:	8556                	mv	a0,s5
    800015e8:	00000097          	auipc	ra,0x0
    800015ec:	c5a080e7          	jalr	-934(ra) # 80001242 <uvmunmap>
  return -1;
    800015f0:	557d                	li	a0,-1
}
    800015f2:	60a6                	ld	ra,72(sp)
    800015f4:	6406                	ld	s0,64(sp)
    800015f6:	74e2                	ld	s1,56(sp)
    800015f8:	7942                	ld	s2,48(sp)
    800015fa:	79a2                	ld	s3,40(sp)
    800015fc:	7a02                	ld	s4,32(sp)
    800015fe:	6ae2                	ld	s5,24(sp)
    80001600:	6b42                	ld	s6,16(sp)
    80001602:	6ba2                	ld	s7,8(sp)
    80001604:	6161                	addi	sp,sp,80
    80001606:	8082                	ret
  return 0;
    80001608:	4501                	li	a0,0
}
    8000160a:	8082                	ret

000000008000160c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000160c:	1141                	addi	sp,sp,-16
    8000160e:	e406                	sd	ra,8(sp)
    80001610:	e022                	sd	s0,0(sp)
    80001612:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001614:	4601                	li	a2,0
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	990080e7          	jalr	-1648(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000161e:	c901                	beqz	a0,8000162e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001620:	611c                	ld	a5,0(a0)
    80001622:	9bbd                	andi	a5,a5,-17
    80001624:	e11c                	sd	a5,0(a0)
}
    80001626:	60a2                	ld	ra,8(sp)
    80001628:	6402                	ld	s0,0(sp)
    8000162a:	0141                	addi	sp,sp,16
    8000162c:	8082                	ret
    panic("uvmclear");
    8000162e:	00007517          	auipc	a0,0x7
    80001632:	b8250513          	addi	a0,a0,-1150 # 800081b0 <digits+0x170>
    80001636:	fffff097          	auipc	ra,0xfffff
    8000163a:	ef4080e7          	jalr	-268(ra) # 8000052a <panic>

000000008000163e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000163e:	c6bd                	beqz	a3,800016ac <copyout+0x6e>
{
    80001640:	715d                	addi	sp,sp,-80
    80001642:	e486                	sd	ra,72(sp)
    80001644:	e0a2                	sd	s0,64(sp)
    80001646:	fc26                	sd	s1,56(sp)
    80001648:	f84a                	sd	s2,48(sp)
    8000164a:	f44e                	sd	s3,40(sp)
    8000164c:	f052                	sd	s4,32(sp)
    8000164e:	ec56                	sd	s5,24(sp)
    80001650:	e85a                	sd	s6,16(sp)
    80001652:	e45e                	sd	s7,8(sp)
    80001654:	e062                	sd	s8,0(sp)
    80001656:	0880                	addi	s0,sp,80
    80001658:	8b2a                	mv	s6,a0
    8000165a:	8c2e                	mv	s8,a1
    8000165c:	8a32                	mv	s4,a2
    8000165e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001660:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001662:	6a85                	lui	s5,0x1
    80001664:	a015                	j	80001688 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001666:	9562                	add	a0,a0,s8
    80001668:	0004861b          	sext.w	a2,s1
    8000166c:	85d2                	mv	a1,s4
    8000166e:	41250533          	sub	a0,a0,s2
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	6a8080e7          	jalr	1704(ra) # 80000d1a <memmove>

    len -= n;
    8000167a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000167e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001680:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001684:	02098263          	beqz	s3,800016a8 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001688:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000168c:	85ca                	mv	a1,s2
    8000168e:	855a                	mv	a0,s6
    80001690:	00000097          	auipc	ra,0x0
    80001694:	9bc080e7          	jalr	-1604(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001698:	cd01                	beqz	a0,800016b0 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000169a:	418904b3          	sub	s1,s2,s8
    8000169e:	94d6                	add	s1,s1,s5
    if(n > len)
    800016a0:	fc99f3e3          	bgeu	s3,s1,80001666 <copyout+0x28>
    800016a4:	84ce                	mv	s1,s3
    800016a6:	b7c1                	j	80001666 <copyout+0x28>
  }
  return 0;
    800016a8:	4501                	li	a0,0
    800016aa:	a021                	j	800016b2 <copyout+0x74>
    800016ac:	4501                	li	a0,0
}
    800016ae:	8082                	ret
      return -1;
    800016b0:	557d                	li	a0,-1
}
    800016b2:	60a6                	ld	ra,72(sp)
    800016b4:	6406                	ld	s0,64(sp)
    800016b6:	74e2                	ld	s1,56(sp)
    800016b8:	7942                	ld	s2,48(sp)
    800016ba:	79a2                	ld	s3,40(sp)
    800016bc:	7a02                	ld	s4,32(sp)
    800016be:	6ae2                	ld	s5,24(sp)
    800016c0:	6b42                	ld	s6,16(sp)
    800016c2:	6ba2                	ld	s7,8(sp)
    800016c4:	6c02                	ld	s8,0(sp)
    800016c6:	6161                	addi	sp,sp,80
    800016c8:	8082                	ret

00000000800016ca <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016ca:	caa5                	beqz	a3,8000173a <copyin+0x70>
{
    800016cc:	715d                	addi	sp,sp,-80
    800016ce:	e486                	sd	ra,72(sp)
    800016d0:	e0a2                	sd	s0,64(sp)
    800016d2:	fc26                	sd	s1,56(sp)
    800016d4:	f84a                	sd	s2,48(sp)
    800016d6:	f44e                	sd	s3,40(sp)
    800016d8:	f052                	sd	s4,32(sp)
    800016da:	ec56                	sd	s5,24(sp)
    800016dc:	e85a                	sd	s6,16(sp)
    800016de:	e45e                	sd	s7,8(sp)
    800016e0:	e062                	sd	s8,0(sp)
    800016e2:	0880                	addi	s0,sp,80
    800016e4:	8b2a                	mv	s6,a0
    800016e6:	8a2e                	mv	s4,a1
    800016e8:	8c32                	mv	s8,a2
    800016ea:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800016ec:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016ee:	6a85                	lui	s5,0x1
    800016f0:	a01d                	j	80001716 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016f2:	018505b3          	add	a1,a0,s8
    800016f6:	0004861b          	sext.w	a2,s1
    800016fa:	412585b3          	sub	a1,a1,s2
    800016fe:	8552                	mv	a0,s4
    80001700:	fffff097          	auipc	ra,0xfffff
    80001704:	61a080e7          	jalr	1562(ra) # 80000d1a <memmove>

    len -= n;
    80001708:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000170c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000170e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001712:	02098263          	beqz	s3,80001736 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001716:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000171a:	85ca                	mv	a1,s2
    8000171c:	855a                	mv	a0,s6
    8000171e:	00000097          	auipc	ra,0x0
    80001722:	92e080e7          	jalr	-1746(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001726:	cd01                	beqz	a0,8000173e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001728:	418904b3          	sub	s1,s2,s8
    8000172c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000172e:	fc99f2e3          	bgeu	s3,s1,800016f2 <copyin+0x28>
    80001732:	84ce                	mv	s1,s3
    80001734:	bf7d                	j	800016f2 <copyin+0x28>
  }
  return 0;
    80001736:	4501                	li	a0,0
    80001738:	a021                	j	80001740 <copyin+0x76>
    8000173a:	4501                	li	a0,0
}
    8000173c:	8082                	ret
      return -1;
    8000173e:	557d                	li	a0,-1
}
    80001740:	60a6                	ld	ra,72(sp)
    80001742:	6406                	ld	s0,64(sp)
    80001744:	74e2                	ld	s1,56(sp)
    80001746:	7942                	ld	s2,48(sp)
    80001748:	79a2                	ld	s3,40(sp)
    8000174a:	7a02                	ld	s4,32(sp)
    8000174c:	6ae2                	ld	s5,24(sp)
    8000174e:	6b42                	ld	s6,16(sp)
    80001750:	6ba2                	ld	s7,8(sp)
    80001752:	6c02                	ld	s8,0(sp)
    80001754:	6161                	addi	sp,sp,80
    80001756:	8082                	ret

0000000080001758 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001758:	c6c5                	beqz	a3,80001800 <copyinstr+0xa8>
{
    8000175a:	715d                	addi	sp,sp,-80
    8000175c:	e486                	sd	ra,72(sp)
    8000175e:	e0a2                	sd	s0,64(sp)
    80001760:	fc26                	sd	s1,56(sp)
    80001762:	f84a                	sd	s2,48(sp)
    80001764:	f44e                	sd	s3,40(sp)
    80001766:	f052                	sd	s4,32(sp)
    80001768:	ec56                	sd	s5,24(sp)
    8000176a:	e85a                	sd	s6,16(sp)
    8000176c:	e45e                	sd	s7,8(sp)
    8000176e:	0880                	addi	s0,sp,80
    80001770:	8a2a                	mv	s4,a0
    80001772:	8b2e                	mv	s6,a1
    80001774:	8bb2                	mv	s7,a2
    80001776:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001778:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000177a:	6985                	lui	s3,0x1
    8000177c:	a035                	j	800017a8 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000177e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001782:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001784:	0017b793          	seqz	a5,a5
    80001788:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000178c:	60a6                	ld	ra,72(sp)
    8000178e:	6406                	ld	s0,64(sp)
    80001790:	74e2                	ld	s1,56(sp)
    80001792:	7942                	ld	s2,48(sp)
    80001794:	79a2                	ld	s3,40(sp)
    80001796:	7a02                	ld	s4,32(sp)
    80001798:	6ae2                	ld	s5,24(sp)
    8000179a:	6b42                	ld	s6,16(sp)
    8000179c:	6ba2                	ld	s7,8(sp)
    8000179e:	6161                	addi	sp,sp,80
    800017a0:	8082                	ret
    srcva = va0 + PGSIZE;
    800017a2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017a6:	c8a9                	beqz	s1,800017f8 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017a8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017ac:	85ca                	mv	a1,s2
    800017ae:	8552                	mv	a0,s4
    800017b0:	00000097          	auipc	ra,0x0
    800017b4:	89c080e7          	jalr	-1892(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    800017b8:	c131                	beqz	a0,800017fc <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ba:	41790833          	sub	a6,s2,s7
    800017be:	984e                	add	a6,a6,s3
    if(n > max)
    800017c0:	0104f363          	bgeu	s1,a6,800017c6 <copyinstr+0x6e>
    800017c4:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017c6:	955e                	add	a0,a0,s7
    800017c8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017cc:	fc080be3          	beqz	a6,800017a2 <copyinstr+0x4a>
    800017d0:	985a                	add	a6,a6,s6
    800017d2:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017d4:	41650633          	sub	a2,a0,s6
    800017d8:	14fd                	addi	s1,s1,-1
    800017da:	9b26                	add	s6,s6,s1
    800017dc:	00f60733          	add	a4,a2,a5
    800017e0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017e4:	df49                	beqz	a4,8000177e <copyinstr+0x26>
        *dst = *p;
    800017e6:	00e78023          	sb	a4,0(a5)
      --max;
    800017ea:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017ee:	0785                	addi	a5,a5,1
    while(n > 0){
    800017f0:	ff0796e3          	bne	a5,a6,800017dc <copyinstr+0x84>
      dst++;
    800017f4:	8b42                	mv	s6,a6
    800017f6:	b775                	j	800017a2 <copyinstr+0x4a>
    800017f8:	4781                	li	a5,0
    800017fa:	b769                	j	80001784 <copyinstr+0x2c>
      return -1;
    800017fc:	557d                	li	a0,-1
    800017fe:	b779                	j	8000178c <copyinstr+0x34>
  int got_null = 0;
    80001800:	4781                	li	a5,0
  if(got_null){
    80001802:	0017b793          	seqz	a5,a5
    80001806:	40f00533          	neg	a0,a5
}
    8000180a:	8082                	ret

000000008000180c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    8000180c:	7139                	addi	sp,sp,-64
    8000180e:	fc06                	sd	ra,56(sp)
    80001810:	f822                	sd	s0,48(sp)
    80001812:	f426                	sd	s1,40(sp)
    80001814:	f04a                	sd	s2,32(sp)
    80001816:	ec4e                	sd	s3,24(sp)
    80001818:	e852                	sd	s4,16(sp)
    8000181a:	e456                	sd	s5,8(sp)
    8000181c:	e05a                	sd	s6,0(sp)
    8000181e:	0080                	addi	s0,sp,64
    80001820:	89aa                	mv	s3,a0
	struct proc *p;

	for (p = proc; p < &proc[NPROC]; p++)
    80001822:	00010497          	auipc	s1,0x10
    80001826:	eae48493          	addi	s1,s1,-338 # 800116d0 <proc>
	{
		char *pa = kalloc();
		if (pa == 0)
			panic("kalloc");
		uint64 va = KSTACK((int)(p - proc));
    8000182a:	8b26                	mv	s6,s1
    8000182c:	00006a97          	auipc	s5,0x6
    80001830:	7d4a8a93          	addi	s5,s5,2004 # 80008000 <etext>
    80001834:	04000937          	lui	s2,0x4000
    80001838:	197d                	addi	s2,s2,-1
    8000183a:	0932                	slli	s2,s2,0xc
	for (p = proc; p < &proc[NPROC]; p++)
    8000183c:	00016a17          	auipc	s4,0x16
    80001840:	e94a0a13          	addi	s4,s4,-364 # 800176d0 <tickslock>
		char *pa = kalloc();
    80001844:	fffff097          	auipc	ra,0xfffff
    80001848:	28e080e7          	jalr	654(ra) # 80000ad2 <kalloc>
    8000184c:	862a                	mv	a2,a0
		if (pa == 0)
    8000184e:	c131                	beqz	a0,80001892 <proc_mapstacks+0x86>
		uint64 va = KSTACK((int)(p - proc));
    80001850:	416485b3          	sub	a1,s1,s6
    80001854:	859d                	srai	a1,a1,0x7
    80001856:	000ab783          	ld	a5,0(s5)
    8000185a:	02f585b3          	mul	a1,a1,a5
    8000185e:	2585                	addiw	a1,a1,1
    80001860:	00d5959b          	slliw	a1,a1,0xd
		kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001864:	4719                	li	a4,6
    80001866:	6685                	lui	a3,0x1
    80001868:	40b905b3          	sub	a1,s2,a1
    8000186c:	854e                	mv	a0,s3
    8000186e:	00000097          	auipc	ra,0x0
    80001872:	8ae080e7          	jalr	-1874(ra) # 8000111c <kvmmap>
	for (p = proc; p < &proc[NPROC]; p++)
    80001876:	18048493          	addi	s1,s1,384
    8000187a:	fd4495e3          	bne	s1,s4,80001844 <proc_mapstacks+0x38>
	}
}
    8000187e:	70e2                	ld	ra,56(sp)
    80001880:	7442                	ld	s0,48(sp)
    80001882:	74a2                	ld	s1,40(sp)
    80001884:	7902                	ld	s2,32(sp)
    80001886:	69e2                	ld	s3,24(sp)
    80001888:	6a42                	ld	s4,16(sp)
    8000188a:	6aa2                	ld	s5,8(sp)
    8000188c:	6b02                	ld	s6,0(sp)
    8000188e:	6121                	addi	sp,sp,64
    80001890:	8082                	ret
			panic("kalloc");
    80001892:	00007517          	auipc	a0,0x7
    80001896:	92e50513          	addi	a0,a0,-1746 # 800081c0 <digits+0x180>
    8000189a:	fffff097          	auipc	ra,0xfffff
    8000189e:	c90080e7          	jalr	-880(ra) # 8000052a <panic>

00000000800018a2 <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    800018a2:	7139                	addi	sp,sp,-64
    800018a4:	fc06                	sd	ra,56(sp)
    800018a6:	f822                	sd	s0,48(sp)
    800018a8:	f426                	sd	s1,40(sp)
    800018aa:	f04a                	sd	s2,32(sp)
    800018ac:	ec4e                	sd	s3,24(sp)
    800018ae:	e852                	sd	s4,16(sp)
    800018b0:	e456                	sd	s5,8(sp)
    800018b2:	e05a                	sd	s6,0(sp)
    800018b4:	0080                	addi	s0,sp,64
	struct proc *p;

	initlock(&pid_lock, "nextpid");
    800018b6:	00007597          	auipc	a1,0x7
    800018ba:	91258593          	addi	a1,a1,-1774 # 800081c8 <digits+0x188>
    800018be:	00010517          	auipc	a0,0x10
    800018c2:	9e250513          	addi	a0,a0,-1566 # 800112a0 <pid_lock>
    800018c6:	fffff097          	auipc	ra,0xfffff
    800018ca:	26c080e7          	jalr	620(ra) # 80000b32 <initlock>
	initlock(&wait_lock, "wait_lock");
    800018ce:	00007597          	auipc	a1,0x7
    800018d2:	90258593          	addi	a1,a1,-1790 # 800081d0 <digits+0x190>
    800018d6:	00010517          	auipc	a0,0x10
    800018da:	9e250513          	addi	a0,a0,-1566 # 800112b8 <wait_lock>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	254080e7          	jalr	596(ra) # 80000b32 <initlock>
	for (p = proc; p < &proc[NPROC]; p++)
    800018e6:	00010497          	auipc	s1,0x10
    800018ea:	dea48493          	addi	s1,s1,-534 # 800116d0 <proc>
	{
		initlock(&p->lock, "proc");
    800018ee:	00007b17          	auipc	s6,0x7
    800018f2:	8f2b0b13          	addi	s6,s6,-1806 # 800081e0 <digits+0x1a0>
		p->kstack = KSTACK((int)(p - proc));
    800018f6:	8aa6                	mv	s5,s1
    800018f8:	00006a17          	auipc	s4,0x6
    800018fc:	708a0a13          	addi	s4,s4,1800 # 80008000 <etext>
    80001900:	04000937          	lui	s2,0x4000
    80001904:	197d                	addi	s2,s2,-1
    80001906:	0932                	slli	s2,s2,0xc
	for (p = proc; p < &proc[NPROC]; p++)
    80001908:	00016997          	auipc	s3,0x16
    8000190c:	dc898993          	addi	s3,s3,-568 # 800176d0 <tickslock>
		initlock(&p->lock, "proc");
    80001910:	85da                	mv	a1,s6
    80001912:	8526                	mv	a0,s1
    80001914:	fffff097          	auipc	ra,0xfffff
    80001918:	21e080e7          	jalr	542(ra) # 80000b32 <initlock>
		p->kstack = KSTACK((int)(p - proc));
    8000191c:	415487b3          	sub	a5,s1,s5
    80001920:	879d                	srai	a5,a5,0x7
    80001922:	000a3703          	ld	a4,0(s4)
    80001926:	02e787b3          	mul	a5,a5,a4
    8000192a:	2785                	addiw	a5,a5,1
    8000192c:	00d7979b          	slliw	a5,a5,0xd
    80001930:	40f907b3          	sub	a5,s2,a5
    80001934:	ecbc                	sd	a5,88(s1)
	for (p = proc; p < &proc[NPROC]; p++)
    80001936:	18048493          	addi	s1,s1,384
    8000193a:	fd349be3          	bne	s1,s3,80001910 <procinit+0x6e>
	}
}
    8000193e:	70e2                	ld	ra,56(sp)
    80001940:	7442                	ld	s0,48(sp)
    80001942:	74a2                	ld	s1,40(sp)
    80001944:	7902                	ld	s2,32(sp)
    80001946:	69e2                	ld	s3,24(sp)
    80001948:	6a42                	ld	s4,16(sp)
    8000194a:	6aa2                	ld	s5,8(sp)
    8000194c:	6b02                	ld	s6,0(sp)
    8000194e:	6121                	addi	sp,sp,64
    80001950:	8082                	ret

0000000080001952 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001952:	1141                	addi	sp,sp,-16
    80001954:	e422                	sd	s0,8(sp)
    80001956:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001958:	8512                	mv	a0,tp
	int id = r_tp();
	return id;
}
    8000195a:	2501                	sext.w	a0,a0
    8000195c:	6422                	ld	s0,8(sp)
    8000195e:	0141                	addi	sp,sp,16
    80001960:	8082                	ret

0000000080001962 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001962:	1141                	addi	sp,sp,-16
    80001964:	e422                	sd	s0,8(sp)
    80001966:	0800                	addi	s0,sp,16
    80001968:	8792                	mv	a5,tp
	int id = cpuid();
	struct cpu *c = &cpus[id];
    8000196a:	2781                	sext.w	a5,a5
    8000196c:	079e                	slli	a5,a5,0x7
	return c;
}
    8000196e:	00010517          	auipc	a0,0x10
    80001972:	96250513          	addi	a0,a0,-1694 # 800112d0 <cpus>
    80001976:	953e                	add	a0,a0,a5
    80001978:	6422                	ld	s0,8(sp)
    8000197a:	0141                	addi	sp,sp,16
    8000197c:	8082                	ret

000000008000197e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    8000197e:	1101                	addi	sp,sp,-32
    80001980:	ec06                	sd	ra,24(sp)
    80001982:	e822                	sd	s0,16(sp)
    80001984:	e426                	sd	s1,8(sp)
    80001986:	1000                	addi	s0,sp,32
	push_off();
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	1ee080e7          	jalr	494(ra) # 80000b76 <push_off>
    80001990:	8792                	mv	a5,tp
	struct cpu *c = mycpu();
	struct proc *p = c->proc;
    80001992:	2781                	sext.w	a5,a5
    80001994:	079e                	slli	a5,a5,0x7
    80001996:	00010717          	auipc	a4,0x10
    8000199a:	90a70713          	addi	a4,a4,-1782 # 800112a0 <pid_lock>
    8000199e:	97ba                	add	a5,a5,a4
    800019a0:	7b84                	ld	s1,48(a5)
	pop_off();
    800019a2:	fffff097          	auipc	ra,0xfffff
    800019a6:	274080e7          	jalr	628(ra) # 80000c16 <pop_off>
	return p;
}
    800019aa:	8526                	mv	a0,s1
    800019ac:	60e2                	ld	ra,24(sp)
    800019ae:	6442                	ld	s0,16(sp)
    800019b0:	64a2                	ld	s1,8(sp)
    800019b2:	6105                	addi	sp,sp,32
    800019b4:	8082                	ret

00000000800019b6 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019b6:	1141                	addi	sp,sp,-16
    800019b8:	e406                	sd	ra,8(sp)
    800019ba:	e022                	sd	s0,0(sp)
    800019bc:	0800                	addi	s0,sp,16
	static int first = 1;

	// Still holding p->lock from scheduler.
	release(&myproc()->lock);
    800019be:	00000097          	auipc	ra,0x0
    800019c2:	fc0080e7          	jalr	-64(ra) # 8000197e <myproc>
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	2b0080e7          	jalr	688(ra) # 80000c76 <release>

	if (first)
    800019ce:	00007797          	auipc	a5,0x7
    800019d2:	0227a783          	lw	a5,34(a5) # 800089f0 <first.1>
    800019d6:	eb89                	bnez	a5,800019e8 <forkret+0x32>
		// be run from main().
		first = 0;
		fsinit(ROOTDEV);
	}

	usertrapret();
    800019d8:	00001097          	auipc	ra,0x1
    800019dc:	056080e7          	jalr	86(ra) # 80002a2e <usertrapret>
}
    800019e0:	60a2                	ld	ra,8(sp)
    800019e2:	6402                	ld	s0,0(sp)
    800019e4:	0141                	addi	sp,sp,16
    800019e6:	8082                	ret
		first = 0;
    800019e8:	00007797          	auipc	a5,0x7
    800019ec:	0007a423          	sw	zero,8(a5) # 800089f0 <first.1>
		fsinit(ROOTDEV);
    800019f0:	4505                	li	a0,1
    800019f2:	00002097          	auipc	ra,0x2
    800019f6:	ed0080e7          	jalr	-304(ra) # 800038c2 <fsinit>
    800019fa:	bff9                	j	800019d8 <forkret+0x22>

00000000800019fc <allocpid>:
{
    800019fc:	1101                	addi	sp,sp,-32
    800019fe:	ec06                	sd	ra,24(sp)
    80001a00:	e822                	sd	s0,16(sp)
    80001a02:	e426                	sd	s1,8(sp)
    80001a04:	e04a                	sd	s2,0(sp)
    80001a06:	1000                	addi	s0,sp,32
	acquire(&pid_lock);
    80001a08:	00010917          	auipc	s2,0x10
    80001a0c:	89890913          	addi	s2,s2,-1896 # 800112a0 <pid_lock>
    80001a10:	854a                	mv	a0,s2
    80001a12:	fffff097          	auipc	ra,0xfffff
    80001a16:	1b0080e7          	jalr	432(ra) # 80000bc2 <acquire>
	pid = nextpid;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	fda78793          	addi	a5,a5,-38 # 800089f4 <nextpid>
    80001a22:	4384                	lw	s1,0(a5)
	nextpid = nextpid + 1;
    80001a24:	0014871b          	addiw	a4,s1,1
    80001a28:	c398                	sw	a4,0(a5)
	release(&pid_lock);
    80001a2a:	854a                	mv	a0,s2
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	24a080e7          	jalr	586(ra) # 80000c76 <release>
}
    80001a34:	8526                	mv	a0,s1
    80001a36:	60e2                	ld	ra,24(sp)
    80001a38:	6442                	ld	s0,16(sp)
    80001a3a:	64a2                	ld	s1,8(sp)
    80001a3c:	6902                	ld	s2,0(sp)
    80001a3e:	6105                	addi	sp,sp,32
    80001a40:	8082                	ret

0000000080001a42 <proc_pagetable>:
{
    80001a42:	1101                	addi	sp,sp,-32
    80001a44:	ec06                	sd	ra,24(sp)
    80001a46:	e822                	sd	s0,16(sp)
    80001a48:	e426                	sd	s1,8(sp)
    80001a4a:	e04a                	sd	s2,0(sp)
    80001a4c:	1000                	addi	s0,sp,32
    80001a4e:	892a                	mv	s2,a0
	pagetable = uvmcreate();
    80001a50:	00000097          	auipc	ra,0x0
    80001a54:	8b6080e7          	jalr	-1866(ra) # 80001306 <uvmcreate>
    80001a58:	84aa                	mv	s1,a0
	if (pagetable == 0)
    80001a5a:	c121                	beqz	a0,80001a9a <proc_pagetable+0x58>
	if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a5c:	4729                	li	a4,10
    80001a5e:	00005697          	auipc	a3,0x5
    80001a62:	5a268693          	addi	a3,a3,1442 # 80007000 <_trampoline>
    80001a66:	6605                	lui	a2,0x1
    80001a68:	040005b7          	lui	a1,0x4000
    80001a6c:	15fd                	addi	a1,a1,-1
    80001a6e:	05b2                	slli	a1,a1,0xc
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	61e080e7          	jalr	1566(ra) # 8000108e <mappages>
    80001a78:	02054863          	bltz	a0,80001aa8 <proc_pagetable+0x66>
	if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a7c:	4719                	li	a4,6
    80001a7e:	07093683          	ld	a3,112(s2)
    80001a82:	6605                	lui	a2,0x1
    80001a84:	020005b7          	lui	a1,0x2000
    80001a88:	15fd                	addi	a1,a1,-1
    80001a8a:	05b6                	slli	a1,a1,0xd
    80001a8c:	8526                	mv	a0,s1
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	600080e7          	jalr	1536(ra) # 8000108e <mappages>
    80001a96:	02054163          	bltz	a0,80001ab8 <proc_pagetable+0x76>
}
    80001a9a:	8526                	mv	a0,s1
    80001a9c:	60e2                	ld	ra,24(sp)
    80001a9e:	6442                	ld	s0,16(sp)
    80001aa0:	64a2                	ld	s1,8(sp)
    80001aa2:	6902                	ld	s2,0(sp)
    80001aa4:	6105                	addi	sp,sp,32
    80001aa6:	8082                	ret
		uvmfree(pagetable, 0);
    80001aa8:	4581                	li	a1,0
    80001aaa:	8526                	mv	a0,s1
    80001aac:	00000097          	auipc	ra,0x0
    80001ab0:	a56080e7          	jalr	-1450(ra) # 80001502 <uvmfree>
		return 0;
    80001ab4:	4481                	li	s1,0
    80001ab6:	b7d5                	j	80001a9a <proc_pagetable+0x58>
		uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ab8:	4681                	li	a3,0
    80001aba:	4605                	li	a2,1
    80001abc:	040005b7          	lui	a1,0x4000
    80001ac0:	15fd                	addi	a1,a1,-1
    80001ac2:	05b2                	slli	a1,a1,0xc
    80001ac4:	8526                	mv	a0,s1
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	77c080e7          	jalr	1916(ra) # 80001242 <uvmunmap>
		uvmfree(pagetable, 0);
    80001ace:	4581                	li	a1,0
    80001ad0:	8526                	mv	a0,s1
    80001ad2:	00000097          	auipc	ra,0x0
    80001ad6:	a30080e7          	jalr	-1488(ra) # 80001502 <uvmfree>
		return 0;
    80001ada:	4481                	li	s1,0
    80001adc:	bf7d                	j	80001a9a <proc_pagetable+0x58>

0000000080001ade <proc_freepagetable>:
{
    80001ade:	1101                	addi	sp,sp,-32
    80001ae0:	ec06                	sd	ra,24(sp)
    80001ae2:	e822                	sd	s0,16(sp)
    80001ae4:	e426                	sd	s1,8(sp)
    80001ae6:	e04a                	sd	s2,0(sp)
    80001ae8:	1000                	addi	s0,sp,32
    80001aea:	84aa                	mv	s1,a0
    80001aec:	892e                	mv	s2,a1
	uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aee:	4681                	li	a3,0
    80001af0:	4605                	li	a2,1
    80001af2:	040005b7          	lui	a1,0x4000
    80001af6:	15fd                	addi	a1,a1,-1
    80001af8:	05b2                	slli	a1,a1,0xc
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	748080e7          	jalr	1864(ra) # 80001242 <uvmunmap>
	uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b02:	4681                	li	a3,0
    80001b04:	4605                	li	a2,1
    80001b06:	020005b7          	lui	a1,0x2000
    80001b0a:	15fd                	addi	a1,a1,-1
    80001b0c:	05b6                	slli	a1,a1,0xd
    80001b0e:	8526                	mv	a0,s1
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	732080e7          	jalr	1842(ra) # 80001242 <uvmunmap>
	uvmfree(pagetable, sz);
    80001b18:	85ca                	mv	a1,s2
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	9e6080e7          	jalr	-1562(ra) # 80001502 <uvmfree>
}
    80001b24:	60e2                	ld	ra,24(sp)
    80001b26:	6442                	ld	s0,16(sp)
    80001b28:	64a2                	ld	s1,8(sp)
    80001b2a:	6902                	ld	s2,0(sp)
    80001b2c:	6105                	addi	sp,sp,32
    80001b2e:	8082                	ret

0000000080001b30 <freeproc>:
{
    80001b30:	1101                	addi	sp,sp,-32
    80001b32:	ec06                	sd	ra,24(sp)
    80001b34:	e822                	sd	s0,16(sp)
    80001b36:	e426                	sd	s1,8(sp)
    80001b38:	1000                	addi	s0,sp,32
    80001b3a:	84aa                	mv	s1,a0
	if (p->trapframe)
    80001b3c:	7928                	ld	a0,112(a0)
    80001b3e:	c509                	beqz	a0,80001b48 <freeproc+0x18>
		kfree((void *)p->trapframe);
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	e96080e7          	jalr	-362(ra) # 800009d6 <kfree>
	p->trapframe = 0;
    80001b48:	0604b823          	sd	zero,112(s1)
	if (p->pagetable)
    80001b4c:	74a8                	ld	a0,104(s1)
    80001b4e:	c511                	beqz	a0,80001b5a <freeproc+0x2a>
		proc_freepagetable(p->pagetable, p->sz);
    80001b50:	70ac                	ld	a1,96(s1)
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	f8c080e7          	jalr	-116(ra) # 80001ade <proc_freepagetable>
	p->pagetable = 0;
    80001b5a:	0604b423          	sd	zero,104(s1)
	p->sz = 0;
    80001b5e:	0604b023          	sd	zero,96(s1)
	p->pid = 0;
    80001b62:	0204a823          	sw	zero,48(s1)
	p->parent = 0;
    80001b66:	0404b823          	sd	zero,80(s1)
	p->name[0] = 0;
    80001b6a:	16048823          	sb	zero,368(s1)
	p->chan = 0;
    80001b6e:	0204b023          	sd	zero,32(s1)
	p->killed = 0;
    80001b72:	0204a423          	sw	zero,40(s1)
	p->xstate = 0;
    80001b76:	0204a623          	sw	zero,44(s1)
	p->state = UNUSED;
    80001b7a:	0004ac23          	sw	zero,24(s1)
}
    80001b7e:	60e2                	ld	ra,24(sp)
    80001b80:	6442                	ld	s0,16(sp)
    80001b82:	64a2                	ld	s1,8(sp)
    80001b84:	6105                	addi	sp,sp,32
    80001b86:	8082                	ret

0000000080001b88 <allocproc>:
{
    80001b88:	1101                	addi	sp,sp,-32
    80001b8a:	ec06                	sd	ra,24(sp)
    80001b8c:	e822                	sd	s0,16(sp)
    80001b8e:	e426                	sd	s1,8(sp)
    80001b90:	e04a                	sd	s2,0(sp)
    80001b92:	1000                	addi	s0,sp,32
	for (p = proc; p < &proc[NPROC]; p++)
    80001b94:	00010497          	auipc	s1,0x10
    80001b98:	b3c48493          	addi	s1,s1,-1220 # 800116d0 <proc>
    80001b9c:	00016917          	auipc	s2,0x16
    80001ba0:	b3490913          	addi	s2,s2,-1228 # 800176d0 <tickslock>
		acquire(&p->lock);
    80001ba4:	8526                	mv	a0,s1
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	01c080e7          	jalr	28(ra) # 80000bc2 <acquire>
		if (p->state == UNUSED)
    80001bae:	4c9c                	lw	a5,24(s1)
    80001bb0:	cf81                	beqz	a5,80001bc8 <allocproc+0x40>
			release(&p->lock);
    80001bb2:	8526                	mv	a0,s1
    80001bb4:	fffff097          	auipc	ra,0xfffff
    80001bb8:	0c2080e7          	jalr	194(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80001bbc:	18048493          	addi	s1,s1,384
    80001bc0:	ff2492e3          	bne	s1,s2,80001ba4 <allocproc+0x1c>
	return 0;
    80001bc4:	4481                	li	s1,0
    80001bc6:	a085                	j	80001c26 <allocproc+0x9e>
	p->pid = allocpid();
    80001bc8:	00000097          	auipc	ra,0x0
    80001bcc:	e34080e7          	jalr	-460(ra) # 800019fc <allocpid>
    80001bd0:	d888                	sw	a0,48(s1)
	p->state = USED;
    80001bd2:	4785                	li	a5,1
    80001bd4:	cc9c                	sw	a5,24(s1)
	p->performance.ctime = ticks;
    80001bd6:	00007797          	auipc	a5,0x7
    80001bda:	45a7a783          	lw	a5,1114(a5) # 80009030 <ticks>
    80001bde:	dc9c                	sw	a5,56(s1)
	p->performance.ttime = -1;
    80001be0:	57fd                	li	a5,-1
    80001be2:	dcdc                	sw	a5,60(s1)
	if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	eee080e7          	jalr	-274(ra) # 80000ad2 <kalloc>
    80001bec:	892a                	mv	s2,a0
    80001bee:	f8a8                	sd	a0,112(s1)
    80001bf0:	c131                	beqz	a0,80001c34 <allocproc+0xac>
	p->pagetable = proc_pagetable(p);
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	00000097          	auipc	ra,0x0
    80001bf8:	e4e080e7          	jalr	-434(ra) # 80001a42 <proc_pagetable>
    80001bfc:	892a                	mv	s2,a0
    80001bfe:	f4a8                	sd	a0,104(s1)
	if (p->pagetable == 0)
    80001c00:	c531                	beqz	a0,80001c4c <allocproc+0xc4>
	memset(&p->context, 0, sizeof(p->context));
    80001c02:	07000613          	li	a2,112
    80001c06:	4581                	li	a1,0
    80001c08:	07848513          	addi	a0,s1,120
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	0b2080e7          	jalr	178(ra) # 80000cbe <memset>
	p->context.ra = (uint64)forkret;
    80001c14:	00000797          	auipc	a5,0x0
    80001c18:	da278793          	addi	a5,a5,-606 # 800019b6 <forkret>
    80001c1c:	fcbc                	sd	a5,120(s1)
	p->context.sp = p->kstack + PGSIZE;
    80001c1e:	6cbc                	ld	a5,88(s1)
    80001c20:	6705                	lui	a4,0x1
    80001c22:	97ba                	add	a5,a5,a4
    80001c24:	e0dc                	sd	a5,128(s1)
}
    80001c26:	8526                	mv	a0,s1
    80001c28:	60e2                	ld	ra,24(sp)
    80001c2a:	6442                	ld	s0,16(sp)
    80001c2c:	64a2                	ld	s1,8(sp)
    80001c2e:	6902                	ld	s2,0(sp)
    80001c30:	6105                	addi	sp,sp,32
    80001c32:	8082                	ret
		freeproc(p);
    80001c34:	8526                	mv	a0,s1
    80001c36:	00000097          	auipc	ra,0x0
    80001c3a:	efa080e7          	jalr	-262(ra) # 80001b30 <freeproc>
		release(&p->lock);
    80001c3e:	8526                	mv	a0,s1
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	036080e7          	jalr	54(ra) # 80000c76 <release>
		return 0;
    80001c48:	84ca                	mv	s1,s2
    80001c4a:	bff1                	j	80001c26 <allocproc+0x9e>
		freeproc(p);
    80001c4c:	8526                	mv	a0,s1
    80001c4e:	00000097          	auipc	ra,0x0
    80001c52:	ee2080e7          	jalr	-286(ra) # 80001b30 <freeproc>
		release(&p->lock);
    80001c56:	8526                	mv	a0,s1
    80001c58:	fffff097          	auipc	ra,0xfffff
    80001c5c:	01e080e7          	jalr	30(ra) # 80000c76 <release>
		return 0;
    80001c60:	84ca                	mv	s1,s2
    80001c62:	b7d1                	j	80001c26 <allocproc+0x9e>

0000000080001c64 <userinit>:
{
    80001c64:	1101                	addi	sp,sp,-32
    80001c66:	ec06                	sd	ra,24(sp)
    80001c68:	e822                	sd	s0,16(sp)
    80001c6a:	e426                	sd	s1,8(sp)
    80001c6c:	1000                	addi	s0,sp,32
	p = allocproc();
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	f1a080e7          	jalr	-230(ra) # 80001b88 <allocproc>
    80001c76:	84aa                	mv	s1,a0
	initproc = p;
    80001c78:	00007797          	auipc	a5,0x7
    80001c7c:	3aa7b823          	sd	a0,944(a5) # 80009028 <initproc>
	uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c80:	03400613          	li	a2,52
    80001c84:	00007597          	auipc	a1,0x7
    80001c88:	d7c58593          	addi	a1,a1,-644 # 80008a00 <initcode>
    80001c8c:	7528                	ld	a0,104(a0)
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	6a6080e7          	jalr	1702(ra) # 80001334 <uvminit>
	p->sz = PGSIZE;
    80001c96:	6785                	lui	a5,0x1
    80001c98:	f0bc                	sd	a5,96(s1)
	p->trapframe->epc = 0;	   // user program counter
    80001c9a:	78b8                	ld	a4,112(s1)
    80001c9c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
	p->trapframe->sp = PGSIZE; // user stack pointer
    80001ca0:	78b8                	ld	a4,112(s1)
    80001ca2:	fb1c                	sd	a5,48(a4)
	safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ca4:	4641                	li	a2,16
    80001ca6:	00006597          	auipc	a1,0x6
    80001caa:	54258593          	addi	a1,a1,1346 # 800081e8 <digits+0x1a8>
    80001cae:	17048513          	addi	a0,s1,368
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	15e080e7          	jalr	350(ra) # 80000e10 <safestrcpy>
	p->cwd = namei("/");
    80001cba:	00006517          	auipc	a0,0x6
    80001cbe:	53e50513          	addi	a0,a0,1342 # 800081f8 <digits+0x1b8>
    80001cc2:	00002097          	auipc	ra,0x2
    80001cc6:	62e080e7          	jalr	1582(ra) # 800042f0 <namei>
    80001cca:	16a4b423          	sd	a0,360(s1)
	p->state = RUNNABLE;
    80001cce:	478d                	li	a5,3
    80001cd0:	cc9c                	sw	a5,24(s1)
	release(&p->lock);
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	fa2080e7          	jalr	-94(ra) # 80000c76 <release>
}
    80001cdc:	60e2                	ld	ra,24(sp)
    80001cde:	6442                	ld	s0,16(sp)
    80001ce0:	64a2                	ld	s1,8(sp)
    80001ce2:	6105                	addi	sp,sp,32
    80001ce4:	8082                	ret

0000000080001ce6 <growproc>:
{
    80001ce6:	1101                	addi	sp,sp,-32
    80001ce8:	ec06                	sd	ra,24(sp)
    80001cea:	e822                	sd	s0,16(sp)
    80001cec:	e426                	sd	s1,8(sp)
    80001cee:	e04a                	sd	s2,0(sp)
    80001cf0:	1000                	addi	s0,sp,32
    80001cf2:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    80001cf4:	00000097          	auipc	ra,0x0
    80001cf8:	c8a080e7          	jalr	-886(ra) # 8000197e <myproc>
    80001cfc:	892a                	mv	s2,a0
	sz = p->sz;
    80001cfe:	712c                	ld	a1,96(a0)
    80001d00:	0005861b          	sext.w	a2,a1
	if (n > 0)
    80001d04:	00904f63          	bgtz	s1,80001d22 <growproc+0x3c>
	else if (n < 0)
    80001d08:	0204cc63          	bltz	s1,80001d40 <growproc+0x5a>
	p->sz = sz;
    80001d0c:	1602                	slli	a2,a2,0x20
    80001d0e:	9201                	srli	a2,a2,0x20
    80001d10:	06c93023          	sd	a2,96(s2)
	return 0;
    80001d14:	4501                	li	a0,0
}
    80001d16:	60e2                	ld	ra,24(sp)
    80001d18:	6442                	ld	s0,16(sp)
    80001d1a:	64a2                	ld	s1,8(sp)
    80001d1c:	6902                	ld	s2,0(sp)
    80001d1e:	6105                	addi	sp,sp,32
    80001d20:	8082                	ret
		if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001d22:	9e25                	addw	a2,a2,s1
    80001d24:	1602                	slli	a2,a2,0x20
    80001d26:	9201                	srli	a2,a2,0x20
    80001d28:	1582                	slli	a1,a1,0x20
    80001d2a:	9181                	srli	a1,a1,0x20
    80001d2c:	7528                	ld	a0,104(a0)
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	6c0080e7          	jalr	1728(ra) # 800013ee <uvmalloc>
    80001d36:	0005061b          	sext.w	a2,a0
    80001d3a:	fa69                	bnez	a2,80001d0c <growproc+0x26>
			return -1;
    80001d3c:	557d                	li	a0,-1
    80001d3e:	bfe1                	j	80001d16 <growproc+0x30>
		sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d40:	9e25                	addw	a2,a2,s1
    80001d42:	1602                	slli	a2,a2,0x20
    80001d44:	9201                	srli	a2,a2,0x20
    80001d46:	1582                	slli	a1,a1,0x20
    80001d48:	9181                	srli	a1,a1,0x20
    80001d4a:	7528                	ld	a0,104(a0)
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	65a080e7          	jalr	1626(ra) # 800013a6 <uvmdealloc>
    80001d54:	0005061b          	sext.w	a2,a0
    80001d58:	bf55                	j	80001d0c <growproc+0x26>

0000000080001d5a <fork>:
{
    80001d5a:	7139                	addi	sp,sp,-64
    80001d5c:	fc06                	sd	ra,56(sp)
    80001d5e:	f822                	sd	s0,48(sp)
    80001d60:	f426                	sd	s1,40(sp)
    80001d62:	f04a                	sd	s2,32(sp)
    80001d64:	ec4e                	sd	s3,24(sp)
    80001d66:	e852                	sd	s4,16(sp)
    80001d68:	e456                	sd	s5,8(sp)
    80001d6a:	0080                	addi	s0,sp,64
	struct proc *p = myproc();
    80001d6c:	00000097          	auipc	ra,0x0
    80001d70:	c12080e7          	jalr	-1006(ra) # 8000197e <myproc>
    80001d74:	8aaa                	mv	s5,a0
	if ((np = allocproc()) == 0)
    80001d76:	00000097          	auipc	ra,0x0
    80001d7a:	e12080e7          	jalr	-494(ra) # 80001b88 <allocproc>
    80001d7e:	12050063          	beqz	a0,80001e9e <fork+0x144>
    80001d82:	89aa                	mv	s3,a0
	if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001d84:	060ab603          	ld	a2,96(s5)
    80001d88:	752c                	ld	a1,104(a0)
    80001d8a:	068ab503          	ld	a0,104(s5)
    80001d8e:	fffff097          	auipc	ra,0xfffff
    80001d92:	7ac080e7          	jalr	1964(ra) # 8000153a <uvmcopy>
    80001d96:	04054863          	bltz	a0,80001de6 <fork+0x8c>
	np->sz = p->sz;
    80001d9a:	060ab783          	ld	a5,96(s5)
    80001d9e:	06f9b023          	sd	a5,96(s3)
	*(np->trapframe) = *(p->trapframe);
    80001da2:	070ab683          	ld	a3,112(s5)
    80001da6:	87b6                	mv	a5,a3
    80001da8:	0709b703          	ld	a4,112(s3)
    80001dac:	12068693          	addi	a3,a3,288
    80001db0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001db4:	6788                	ld	a0,8(a5)
    80001db6:	6b8c                	ld	a1,16(a5)
    80001db8:	6f90                	ld	a2,24(a5)
    80001dba:	01073023          	sd	a6,0(a4)
    80001dbe:	e708                	sd	a0,8(a4)
    80001dc0:	eb0c                	sd	a1,16(a4)
    80001dc2:	ef10                	sd	a2,24(a4)
    80001dc4:	02078793          	addi	a5,a5,32
    80001dc8:	02070713          	addi	a4,a4,32
    80001dcc:	fed792e3          	bne	a5,a3,80001db0 <fork+0x56>
	np->trapframe->a0 = 0;
    80001dd0:	0709b783          	ld	a5,112(s3)
    80001dd4:	0607b823          	sd	zero,112(a5)
	for (i = 0; i < NOFILE; i++)
    80001dd8:	0e8a8493          	addi	s1,s5,232
    80001ddc:	0e898913          	addi	s2,s3,232
    80001de0:	168a8a13          	addi	s4,s5,360
    80001de4:	a00d                	j	80001e06 <fork+0xac>
		freeproc(np);
    80001de6:	854e                	mv	a0,s3
    80001de8:	00000097          	auipc	ra,0x0
    80001dec:	d48080e7          	jalr	-696(ra) # 80001b30 <freeproc>
		release(&np->lock);
    80001df0:	854e                	mv	a0,s3
    80001df2:	fffff097          	auipc	ra,0xfffff
    80001df6:	e84080e7          	jalr	-380(ra) # 80000c76 <release>
		return -1;
    80001dfa:	597d                	li	s2,-1
    80001dfc:	a079                	j	80001e8a <fork+0x130>
	for (i = 0; i < NOFILE; i++)
    80001dfe:	04a1                	addi	s1,s1,8
    80001e00:	0921                	addi	s2,s2,8
    80001e02:	01448b63          	beq	s1,s4,80001e18 <fork+0xbe>
		if (p->ofile[i])
    80001e06:	6088                	ld	a0,0(s1)
    80001e08:	d97d                	beqz	a0,80001dfe <fork+0xa4>
			np->ofile[i] = filedup(p->ofile[i]);
    80001e0a:	00003097          	auipc	ra,0x3
    80001e0e:	b80080e7          	jalr	-1152(ra) # 8000498a <filedup>
    80001e12:	00a93023          	sd	a0,0(s2)
    80001e16:	b7e5                	j	80001dfe <fork+0xa4>
	np->cwd = idup(p->cwd);
    80001e18:	168ab503          	ld	a0,360(s5)
    80001e1c:	00002097          	auipc	ra,0x2
    80001e20:	ce0080e7          	jalr	-800(ra) # 80003afc <idup>
    80001e24:	16a9b423          	sd	a0,360(s3)
	safestrcpy(np->name, p->name, sizeof(p->name));
    80001e28:	4641                	li	a2,16
    80001e2a:	170a8593          	addi	a1,s5,368
    80001e2e:	17098513          	addi	a0,s3,368
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	fde080e7          	jalr	-34(ra) # 80000e10 <safestrcpy>
	pid = np->pid;
    80001e3a:	0309a903          	lw	s2,48(s3)
	release(&np->lock);
    80001e3e:	854e                	mv	a0,s3
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	e36080e7          	jalr	-458(ra) # 80000c76 <release>
	acquire(&wait_lock);
    80001e48:	0000f497          	auipc	s1,0xf
    80001e4c:	47048493          	addi	s1,s1,1136 # 800112b8 <wait_lock>
    80001e50:	8526                	mv	a0,s1
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	d70080e7          	jalr	-656(ra) # 80000bc2 <acquire>
	np->parent = p;
    80001e5a:	0559b823          	sd	s5,80(s3)
	np->trace_mask = p->trace_mask; // ADDED
    80001e5e:	034aa783          	lw	a5,52(s5)
    80001e62:	02f9aa23          	sw	a5,52(s3)
	release(&wait_lock);
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e0e080e7          	jalr	-498(ra) # 80000c76 <release>
	acquire(&np->lock);
    80001e70:	854e                	mv	a0,s3
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d50080e7          	jalr	-688(ra) # 80000bc2 <acquire>
	np->state = RUNNABLE;
    80001e7a:	478d                	li	a5,3
    80001e7c:	00f9ac23          	sw	a5,24(s3)
	release(&np->lock);
    80001e80:	854e                	mv	a0,s3
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	df4080e7          	jalr	-524(ra) # 80000c76 <release>
}
    80001e8a:	854a                	mv	a0,s2
    80001e8c:	70e2                	ld	ra,56(sp)
    80001e8e:	7442                	ld	s0,48(sp)
    80001e90:	74a2                	ld	s1,40(sp)
    80001e92:	7902                	ld	s2,32(sp)
    80001e94:	69e2                	ld	s3,24(sp)
    80001e96:	6a42                	ld	s4,16(sp)
    80001e98:	6aa2                	ld	s5,8(sp)
    80001e9a:	6121                	addi	sp,sp,64
    80001e9c:	8082                	ret
		return -1;
    80001e9e:	597d                	li	s2,-1
    80001ea0:	b7ed                	j	80001e8a <fork+0x130>

0000000080001ea2 <sched_default>:
{
    80001ea2:	7139                	addi	sp,sp,-64
    80001ea4:	fc06                	sd	ra,56(sp)
    80001ea6:	f822                	sd	s0,48(sp)
    80001ea8:	f426                	sd	s1,40(sp)
    80001eaa:	f04a                	sd	s2,32(sp)
    80001eac:	ec4e                	sd	s3,24(sp)
    80001eae:	e852                	sd	s4,16(sp)
    80001eb0:	e456                	sd	s5,8(sp)
    80001eb2:	e05a                	sd	s6,0(sp)
    80001eb4:	0080                	addi	s0,sp,64
    80001eb6:	8792                	mv	a5,tp
	int id = r_tp();
    80001eb8:	2781                	sext.w	a5,a5
	c->proc = 0;
    80001eba:	00779a93          	slli	s5,a5,0x7
    80001ebe:	0000f717          	auipc	a4,0xf
    80001ec2:	3e270713          	addi	a4,a4,994 # 800112a0 <pid_lock>
    80001ec6:	9756                	add	a4,a4,s5
    80001ec8:	02073823          	sd	zero,48(a4)
			swtch(&c->context, &p->context);
    80001ecc:	0000f717          	auipc	a4,0xf
    80001ed0:	40c70713          	addi	a4,a4,1036 # 800112d8 <cpus+0x8>
    80001ed4:	9aba                	add	s5,s5,a4
	for (p = proc; p < &proc[NPROC]; p++)
    80001ed6:	0000f497          	auipc	s1,0xf
    80001eda:	7fa48493          	addi	s1,s1,2042 # 800116d0 <proc>
		if (p->state == RUNNABLE)
    80001ede:	498d                	li	s3,3
			p->state = RUNNING;
    80001ee0:	4b11                	li	s6,4
			c->proc = p;
    80001ee2:	079e                	slli	a5,a5,0x7
    80001ee4:	0000fa17          	auipc	s4,0xf
    80001ee8:	3bca0a13          	addi	s4,s4,956 # 800112a0 <pid_lock>
    80001eec:	9a3e                	add	s4,s4,a5
	for (p = proc; p < &proc[NPROC]; p++)
    80001eee:	00015917          	auipc	s2,0x15
    80001ef2:	7e290913          	addi	s2,s2,2018 # 800176d0 <tickslock>
    80001ef6:	a811                	j	80001f0a <sched_default+0x68>
		release(&p->lock);
    80001ef8:	8526                	mv	a0,s1
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	d7c080e7          	jalr	-644(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80001f02:	18048493          	addi	s1,s1,384
    80001f06:	03248863          	beq	s1,s2,80001f36 <sched_default+0x94>
		acquire(&p->lock);
    80001f0a:	8526                	mv	a0,s1
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	cb6080e7          	jalr	-842(ra) # 80000bc2 <acquire>
		if (p->state == RUNNABLE)
    80001f14:	4c9c                	lw	a5,24(s1)
    80001f16:	ff3791e3          	bne	a5,s3,80001ef8 <sched_default+0x56>
			p->state = RUNNING;
    80001f1a:	0164ac23          	sw	s6,24(s1)
			c->proc = p;
    80001f1e:	029a3823          	sd	s1,48(s4)
			swtch(&c->context, &p->context);
    80001f22:	07848593          	addi	a1,s1,120
    80001f26:	8556                	mv	a0,s5
    80001f28:	00001097          	auipc	ra,0x1
    80001f2c:	a5c080e7          	jalr	-1444(ra) # 80002984 <swtch>
			c->proc = 0;
    80001f30:	020a3823          	sd	zero,48(s4)
    80001f34:	b7d1                	j	80001ef8 <sched_default+0x56>
}
    80001f36:	70e2                	ld	ra,56(sp)
    80001f38:	7442                	ld	s0,48(sp)
    80001f3a:	74a2                	ld	s1,40(sp)
    80001f3c:	7902                	ld	s2,32(sp)
    80001f3e:	69e2                	ld	s3,24(sp)
    80001f40:	6a42                	ld	s4,16(sp)
    80001f42:	6aa2                	ld	s5,8(sp)
    80001f44:	6b02                	ld	s6,0(sp)
    80001f46:	6121                	addi	sp,sp,64
    80001f48:	8082                	ret

0000000080001f4a <sched_fcfs>:
{
    80001f4a:	715d                	addi	sp,sp,-80
    80001f4c:	e486                	sd	ra,72(sp)
    80001f4e:	e0a2                	sd	s0,64(sp)
    80001f50:	fc26                	sd	s1,56(sp)
    80001f52:	f84a                	sd	s2,48(sp)
    80001f54:	f44e                	sd	s3,40(sp)
    80001f56:	f052                	sd	s4,32(sp)
    80001f58:	ec56                	sd	s5,24(sp)
    80001f5a:	e85a                	sd	s6,16(sp)
    80001f5c:	e45e                	sd	s7,8(sp)
    80001f5e:	0880                	addi	s0,sp,80
    80001f60:	8b92                	mv	s7,tp
	int id = r_tp();
    80001f62:	2b81                	sext.w	s7,s7
	c->proc = 0;
    80001f64:	007b9713          	slli	a4,s7,0x7
    80001f68:	0000f797          	auipc	a5,0xf
    80001f6c:	33878793          	addi	a5,a5,824 # 800112a0 <pid_lock>
    80001f70:	97ba                	add	a5,a5,a4
    80001f72:	0207b823          	sd	zero,48(a5)
	dummy.performance.ctime = 2147483647;
    80001f76:	80000ab7          	lui	s5,0x80000
    80001f7a:	fffaca93          	not	s5,s5
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80001f7e:	4901                	li	s2,0
	int proc_to_run_index = 0;
    80001f80:	4b01                	li	s6,0
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80001f82:	0000f497          	auipc	s1,0xf
    80001f86:	74e48493          	addi	s1,s1,1870 # 800116d0 <proc>
		if (p->state == RUNNABLE && p->performance.ctime < first->performance.ctime)
    80001f8a:	4a0d                	li	s4,3
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80001f8c:	00015997          	auipc	s3,0x15
    80001f90:	74498993          	addi	s3,s3,1860 # 800176d0 <tickslock>
    80001f94:	a819                	j	80001faa <sched_fcfs+0x60>
		release(&p->lock);
    80001f96:	8526                	mv	a0,s1
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	cde080e7          	jalr	-802(ra) # 80000c76 <release>
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80001fa0:	18048493          	addi	s1,s1,384
    80001fa4:	2905                	addiw	s2,s2,1
    80001fa6:	03348063          	beq	s1,s3,80001fc6 <sched_fcfs+0x7c>
		acquire(&p->lock);
    80001faa:	8526                	mv	a0,s1
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	c16080e7          	jalr	-1002(ra) # 80000bc2 <acquire>
		if (p->state == RUNNABLE && p->performance.ctime < first->performance.ctime)
    80001fb4:	4c9c                	lw	a5,24(s1)
    80001fb6:	ff4790e3          	bne	a5,s4,80001f96 <sched_fcfs+0x4c>
    80001fba:	5c9c                	lw	a5,56(s1)
    80001fbc:	fd57dde3          	bge	a5,s5,80001f96 <sched_fcfs+0x4c>
			first->performance.ctime = p->performance.ctime;
    80001fc0:	8abe                	mv	s5,a5
		if (p->state == RUNNABLE && p->performance.ctime < first->performance.ctime)
    80001fc2:	8b4a                	mv	s6,s2
    80001fc4:	bfc9                	j	80001f96 <sched_fcfs+0x4c>
	first = &proc[proc_to_run_index];
    80001fc6:	001b1493          	slli	s1,s6,0x1
    80001fca:	94da                	add	s1,s1,s6
    80001fcc:	049e                	slli	s1,s1,0x7
    80001fce:	0000f917          	auipc	s2,0xf
    80001fd2:	70290913          	addi	s2,s2,1794 # 800116d0 <proc>
    80001fd6:	9926                	add	s2,s2,s1
	acquire(&first->lock);
    80001fd8:	854a                	mv	a0,s2
    80001fda:	fffff097          	auipc	ra,0xfffff
    80001fde:	be8080e7          	jalr	-1048(ra) # 80000bc2 <acquire>
	if (first->state == RUNNABLE)
    80001fe2:	01892703          	lw	a4,24(s2)
    80001fe6:	478d                	li	a5,3
    80001fe8:	02f70263          	beq	a4,a5,8000200c <sched_fcfs+0xc2>
	release(&first->lock);
    80001fec:	854a                	mv	a0,s2
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	c88080e7          	jalr	-888(ra) # 80000c76 <release>
}
    80001ff6:	60a6                	ld	ra,72(sp)
    80001ff8:	6406                	ld	s0,64(sp)
    80001ffa:	74e2                	ld	s1,56(sp)
    80001ffc:	7942                	ld	s2,48(sp)
    80001ffe:	79a2                	ld	s3,40(sp)
    80002000:	7a02                	ld	s4,32(sp)
    80002002:	6ae2                	ld	s5,24(sp)
    80002004:	6b42                	ld	s6,16(sp)
    80002006:	6ba2                	ld	s7,8(sp)
    80002008:	6161                	addi	sp,sp,80
    8000200a:	8082                	ret
		first->state = RUNNING;
    8000200c:	0000f597          	auipc	a1,0xf
    80002010:	6c458593          	addi	a1,a1,1732 # 800116d0 <proc>
    80002014:	4791                	li	a5,4
    80002016:	00f92c23          	sw	a5,24(s2)
		c->proc = first;
    8000201a:	007b9713          	slli	a4,s7,0x7
    8000201e:	0000f797          	auipc	a5,0xf
    80002022:	28278793          	addi	a5,a5,642 # 800112a0 <pid_lock>
    80002026:	97ba                	add	a5,a5,a4
    80002028:	0327b823          	sd	s2,48(a5)
		swtch(&c->context, &first->context);
    8000202c:	07848493          	addi	s1,s1,120
    80002030:	95a6                	add	a1,a1,s1
    80002032:	0000f517          	auipc	a0,0xf
    80002036:	2a650513          	addi	a0,a0,678 # 800112d8 <cpus+0x8>
    8000203a:	953a                	add	a0,a0,a4
    8000203c:	00001097          	auipc	ra,0x1
    80002040:	948080e7          	jalr	-1720(ra) # 80002984 <swtch>
		if (first->state == RUNNABLE)
    80002044:	01892703          	lw	a4,24(s2)
    80002048:	478d                	li	a5,3
    8000204a:	00f70b63          	beq	a4,a5,80002060 <sched_fcfs+0x116>
		c->proc = 0;
    8000204e:	0b9e                	slli	s7,s7,0x7
    80002050:	0000f797          	auipc	a5,0xf
    80002054:	25078793          	addi	a5,a5,592 # 800112a0 <pid_lock>
    80002058:	9bbe                	add	s7,s7,a5
    8000205a:	020bb823          	sd	zero,48(s7) # fffffffffffff030 <end+0xffffffff7ffd9030>
    8000205e:	b779                	j	80001fec <sched_fcfs+0xa2>
			first->performance.ctime = ticks;
    80002060:	00007717          	auipc	a4,0x7
    80002064:	fd072703          	lw	a4,-48(a4) # 80009030 <ticks>
    80002068:	02e92c23          	sw	a4,56(s2)
    8000206c:	b7cd                	j	8000204e <sched_fcfs+0x104>

000000008000206e <scheduler>:
{
    8000206e:	1141                	addi	sp,sp,-16
    80002070:	e406                	sd	ra,8(sp)
    80002072:	e022                	sd	s0,0(sp)
    80002074:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002076:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000207a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000207e:	10079073          	csrw	sstatus,a5
		sched_fcfs();
    80002082:	00000097          	auipc	ra,0x0
    80002086:	ec8080e7          	jalr	-312(ra) # 80001f4a <sched_fcfs>
	for (;;)
    8000208a:	b7f5                	j	80002076 <scheduler+0x8>

000000008000208c <sched>:
{
    8000208c:	7179                	addi	sp,sp,-48
    8000208e:	f406                	sd	ra,40(sp)
    80002090:	f022                	sd	s0,32(sp)
    80002092:	ec26                	sd	s1,24(sp)
    80002094:	e84a                	sd	s2,16(sp)
    80002096:	e44e                	sd	s3,8(sp)
    80002098:	1800                	addi	s0,sp,48
	struct proc *p = myproc();
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	8e4080e7          	jalr	-1820(ra) # 8000197e <myproc>
    800020a2:	84aa                	mv	s1,a0
	if (!holding(&p->lock))
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	aa4080e7          	jalr	-1372(ra) # 80000b48 <holding>
    800020ac:	c93d                	beqz	a0,80002122 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ae:	8792                	mv	a5,tp
	if (mycpu()->noff != 1)
    800020b0:	2781                	sext.w	a5,a5
    800020b2:	079e                	slli	a5,a5,0x7
    800020b4:	0000f717          	auipc	a4,0xf
    800020b8:	1ec70713          	addi	a4,a4,492 # 800112a0 <pid_lock>
    800020bc:	97ba                	add	a5,a5,a4
    800020be:	0a87a703          	lw	a4,168(a5)
    800020c2:	4785                	li	a5,1
    800020c4:	06f71763          	bne	a4,a5,80002132 <sched+0xa6>
	if (p->state == RUNNING)
    800020c8:	4c98                	lw	a4,24(s1)
    800020ca:	4791                	li	a5,4
    800020cc:	06f70b63          	beq	a4,a5,80002142 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020d0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020d4:	8b89                	andi	a5,a5,2
	if (intr_get())
    800020d6:	efb5                	bnez	a5,80002152 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020d8:	8792                	mv	a5,tp
	intena = mycpu()->intena;
    800020da:	0000f917          	auipc	s2,0xf
    800020de:	1c690913          	addi	s2,s2,454 # 800112a0 <pid_lock>
    800020e2:	2781                	sext.w	a5,a5
    800020e4:	079e                	slli	a5,a5,0x7
    800020e6:	97ca                	add	a5,a5,s2
    800020e8:	0ac7a983          	lw	s3,172(a5)
    800020ec:	8792                	mv	a5,tp
	swtch(&p->context, &mycpu()->context);
    800020ee:	2781                	sext.w	a5,a5
    800020f0:	079e                	slli	a5,a5,0x7
    800020f2:	0000f597          	auipc	a1,0xf
    800020f6:	1e658593          	addi	a1,a1,486 # 800112d8 <cpus+0x8>
    800020fa:	95be                	add	a1,a1,a5
    800020fc:	07848513          	addi	a0,s1,120
    80002100:	00001097          	auipc	ra,0x1
    80002104:	884080e7          	jalr	-1916(ra) # 80002984 <swtch>
    80002108:	8792                	mv	a5,tp
	mycpu()->intena = intena;
    8000210a:	2781                	sext.w	a5,a5
    8000210c:	079e                	slli	a5,a5,0x7
    8000210e:	97ca                	add	a5,a5,s2
    80002110:	0b37a623          	sw	s3,172(a5)
}
    80002114:	70a2                	ld	ra,40(sp)
    80002116:	7402                	ld	s0,32(sp)
    80002118:	64e2                	ld	s1,24(sp)
    8000211a:	6942                	ld	s2,16(sp)
    8000211c:	69a2                	ld	s3,8(sp)
    8000211e:	6145                	addi	sp,sp,48
    80002120:	8082                	ret
		panic("sched p->lock");
    80002122:	00006517          	auipc	a0,0x6
    80002126:	0de50513          	addi	a0,a0,222 # 80008200 <digits+0x1c0>
    8000212a:	ffffe097          	auipc	ra,0xffffe
    8000212e:	400080e7          	jalr	1024(ra) # 8000052a <panic>
		panic("sched locks");
    80002132:	00006517          	auipc	a0,0x6
    80002136:	0de50513          	addi	a0,a0,222 # 80008210 <digits+0x1d0>
    8000213a:	ffffe097          	auipc	ra,0xffffe
    8000213e:	3f0080e7          	jalr	1008(ra) # 8000052a <panic>
		panic("sched running");
    80002142:	00006517          	auipc	a0,0x6
    80002146:	0de50513          	addi	a0,a0,222 # 80008220 <digits+0x1e0>
    8000214a:	ffffe097          	auipc	ra,0xffffe
    8000214e:	3e0080e7          	jalr	992(ra) # 8000052a <panic>
		panic("sched interruptible");
    80002152:	00006517          	auipc	a0,0x6
    80002156:	0de50513          	addi	a0,a0,222 # 80008230 <digits+0x1f0>
    8000215a:	ffffe097          	auipc	ra,0xffffe
    8000215e:	3d0080e7          	jalr	976(ra) # 8000052a <panic>

0000000080002162 <yield>:
{
    80002162:	1101                	addi	sp,sp,-32
    80002164:	ec06                	sd	ra,24(sp)
    80002166:	e822                	sd	s0,16(sp)
    80002168:	e426                	sd	s1,8(sp)
    8000216a:	1000                	addi	s0,sp,32
	struct proc *p = myproc();
    8000216c:	00000097          	auipc	ra,0x0
    80002170:	812080e7          	jalr	-2030(ra) # 8000197e <myproc>
    80002174:	84aa                	mv	s1,a0
	acquire(&p->lock);
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	a4c080e7          	jalr	-1460(ra) # 80000bc2 <acquire>
	p->state = RUNNABLE;
    8000217e:	478d                	li	a5,3
    80002180:	cc9c                	sw	a5,24(s1)
	sched();
    80002182:	00000097          	auipc	ra,0x0
    80002186:	f0a080e7          	jalr	-246(ra) # 8000208c <sched>
	release(&p->lock);
    8000218a:	8526                	mv	a0,s1
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	aea080e7          	jalr	-1302(ra) # 80000c76 <release>
}
    80002194:	60e2                	ld	ra,24(sp)
    80002196:	6442                	ld	s0,16(sp)
    80002198:	64a2                	ld	s1,8(sp)
    8000219a:	6105                	addi	sp,sp,32
    8000219c:	8082                	ret

000000008000219e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000219e:	7179                	addi	sp,sp,-48
    800021a0:	f406                	sd	ra,40(sp)
    800021a2:	f022                	sd	s0,32(sp)
    800021a4:	ec26                	sd	s1,24(sp)
    800021a6:	e84a                	sd	s2,16(sp)
    800021a8:	e44e                	sd	s3,8(sp)
    800021aa:	1800                	addi	s0,sp,48
    800021ac:	89aa                	mv	s3,a0
    800021ae:	892e                	mv	s2,a1
	struct proc *p = myproc();
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	7ce080e7          	jalr	1998(ra) # 8000197e <myproc>
    800021b8:	84aa                	mv	s1,a0
	// Once we hold p->lock, we can be
	// guaranteed that we won't miss any wakeup
	// (wakeup locks p->lock),
	// so it's okay to release lk.

	acquire(&p->lock); //DOC: sleeplock1
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	a08080e7          	jalr	-1528(ra) # 80000bc2 <acquire>
	release(lk);
    800021c2:	854a                	mv	a0,s2
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	ab2080e7          	jalr	-1358(ra) # 80000c76 <release>

	// Go to sleep.
	p->chan = chan;
    800021cc:	0334b023          	sd	s3,32(s1)
	p->state = SLEEPING;
    800021d0:	4789                	li	a5,2
    800021d2:	cc9c                	sw	a5,24(s1)

	sched();
    800021d4:	00000097          	auipc	ra,0x0
    800021d8:	eb8080e7          	jalr	-328(ra) # 8000208c <sched>

	// Tidy up.
	p->chan = 0;
    800021dc:	0204b023          	sd	zero,32(s1)

	// Reacquire original lock.
	release(&p->lock);
    800021e0:	8526                	mv	a0,s1
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	a94080e7          	jalr	-1388(ra) # 80000c76 <release>
	acquire(lk);
    800021ea:	854a                	mv	a0,s2
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	9d6080e7          	jalr	-1578(ra) # 80000bc2 <acquire>
}
    800021f4:	70a2                	ld	ra,40(sp)
    800021f6:	7402                	ld	s0,32(sp)
    800021f8:	64e2                	ld	s1,24(sp)
    800021fa:	6942                	ld	s2,16(sp)
    800021fc:	69a2                	ld	s3,8(sp)
    800021fe:	6145                	addi	sp,sp,48
    80002200:	8082                	ret

0000000080002202 <wait>:
{
    80002202:	715d                	addi	sp,sp,-80
    80002204:	e486                	sd	ra,72(sp)
    80002206:	e0a2                	sd	s0,64(sp)
    80002208:	fc26                	sd	s1,56(sp)
    8000220a:	f84a                	sd	s2,48(sp)
    8000220c:	f44e                	sd	s3,40(sp)
    8000220e:	f052                	sd	s4,32(sp)
    80002210:	ec56                	sd	s5,24(sp)
    80002212:	e85a                	sd	s6,16(sp)
    80002214:	e45e                	sd	s7,8(sp)
    80002216:	e062                	sd	s8,0(sp)
    80002218:	0880                	addi	s0,sp,80
    8000221a:	8b2a                	mv	s6,a0
	struct proc *p = myproc();
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	762080e7          	jalr	1890(ra) # 8000197e <myproc>
    80002224:	892a                	mv	s2,a0
	acquire(&wait_lock);
    80002226:	0000f517          	auipc	a0,0xf
    8000222a:	09250513          	addi	a0,a0,146 # 800112b8 <wait_lock>
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	994080e7          	jalr	-1644(ra) # 80000bc2 <acquire>
		havekids = 0;
    80002236:	4b81                	li	s7,0
				if (np->state == ZOMBIE)
    80002238:	4a15                	li	s4,5
				havekids = 1;
    8000223a:	4a85                	li	s5,1
		for (np = proc; np < &proc[NPROC]; np++)
    8000223c:	00015997          	auipc	s3,0x15
    80002240:	49498993          	addi	s3,s3,1172 # 800176d0 <tickslock>
		sleep(p, &wait_lock); //DOC: wait-sleep
    80002244:	0000fc17          	auipc	s8,0xf
    80002248:	074c0c13          	addi	s8,s8,116 # 800112b8 <wait_lock>
		havekids = 0;
    8000224c:	875e                	mv	a4,s7
		for (np = proc; np < &proc[NPROC]; np++)
    8000224e:	0000f497          	auipc	s1,0xf
    80002252:	48248493          	addi	s1,s1,1154 # 800116d0 <proc>
    80002256:	a0bd                	j	800022c4 <wait+0xc2>
					pid = np->pid;
    80002258:	0304a983          	lw	s3,48(s1)
					if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000225c:	000b0e63          	beqz	s6,80002278 <wait+0x76>
    80002260:	4691                	li	a3,4
    80002262:	02c48613          	addi	a2,s1,44
    80002266:	85da                	mv	a1,s6
    80002268:	06893503          	ld	a0,104(s2)
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	3d2080e7          	jalr	978(ra) # 8000163e <copyout>
    80002274:	02054563          	bltz	a0,8000229e <wait+0x9c>
					freeproc(np);
    80002278:	8526                	mv	a0,s1
    8000227a:	00000097          	auipc	ra,0x0
    8000227e:	8b6080e7          	jalr	-1866(ra) # 80001b30 <freeproc>
					release(&np->lock);
    80002282:	8526                	mv	a0,s1
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	9f2080e7          	jalr	-1550(ra) # 80000c76 <release>
					release(&wait_lock);
    8000228c:	0000f517          	auipc	a0,0xf
    80002290:	02c50513          	addi	a0,a0,44 # 800112b8 <wait_lock>
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	9e2080e7          	jalr	-1566(ra) # 80000c76 <release>
					return pid;
    8000229c:	a09d                	j	80002302 <wait+0x100>
						release(&np->lock);
    8000229e:	8526                	mv	a0,s1
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	9d6080e7          	jalr	-1578(ra) # 80000c76 <release>
						release(&wait_lock);
    800022a8:	0000f517          	auipc	a0,0xf
    800022ac:	01050513          	addi	a0,a0,16 # 800112b8 <wait_lock>
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	9c6080e7          	jalr	-1594(ra) # 80000c76 <release>
						return -1;
    800022b8:	59fd                	li	s3,-1
    800022ba:	a0a1                	j	80002302 <wait+0x100>
		for (np = proc; np < &proc[NPROC]; np++)
    800022bc:	18048493          	addi	s1,s1,384
    800022c0:	03348463          	beq	s1,s3,800022e8 <wait+0xe6>
			if (np->parent == p)
    800022c4:	68bc                	ld	a5,80(s1)
    800022c6:	ff279be3          	bne	a5,s2,800022bc <wait+0xba>
				acquire(&np->lock);
    800022ca:	8526                	mv	a0,s1
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	8f6080e7          	jalr	-1802(ra) # 80000bc2 <acquire>
				if (np->state == ZOMBIE)
    800022d4:	4c9c                	lw	a5,24(s1)
    800022d6:	f94781e3          	beq	a5,s4,80002258 <wait+0x56>
				release(&np->lock);
    800022da:	8526                	mv	a0,s1
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	99a080e7          	jalr	-1638(ra) # 80000c76 <release>
				havekids = 1;
    800022e4:	8756                	mv	a4,s5
    800022e6:	bfd9                	j	800022bc <wait+0xba>
		if (!havekids || p->killed)
    800022e8:	c701                	beqz	a4,800022f0 <wait+0xee>
    800022ea:	02892783          	lw	a5,40(s2)
    800022ee:	c79d                	beqz	a5,8000231c <wait+0x11a>
			release(&wait_lock);
    800022f0:	0000f517          	auipc	a0,0xf
    800022f4:	fc850513          	addi	a0,a0,-56 # 800112b8 <wait_lock>
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	97e080e7          	jalr	-1666(ra) # 80000c76 <release>
			return -1;
    80002300:	59fd                	li	s3,-1
}
    80002302:	854e                	mv	a0,s3
    80002304:	60a6                	ld	ra,72(sp)
    80002306:	6406                	ld	s0,64(sp)
    80002308:	74e2                	ld	s1,56(sp)
    8000230a:	7942                	ld	s2,48(sp)
    8000230c:	79a2                	ld	s3,40(sp)
    8000230e:	7a02                	ld	s4,32(sp)
    80002310:	6ae2                	ld	s5,24(sp)
    80002312:	6b42                	ld	s6,16(sp)
    80002314:	6ba2                	ld	s7,8(sp)
    80002316:	6c02                	ld	s8,0(sp)
    80002318:	6161                	addi	sp,sp,80
    8000231a:	8082                	ret
		sleep(p, &wait_lock); //DOC: wait-sleep
    8000231c:	85e2                	mv	a1,s8
    8000231e:	854a                	mv	a0,s2
    80002320:	00000097          	auipc	ra,0x0
    80002324:	e7e080e7          	jalr	-386(ra) # 8000219e <sleep>
		havekids = 0;
    80002328:	b715                	j	8000224c <wait+0x4a>

000000008000232a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000232a:	7139                	addi	sp,sp,-64
    8000232c:	fc06                	sd	ra,56(sp)
    8000232e:	f822                	sd	s0,48(sp)
    80002330:	f426                	sd	s1,40(sp)
    80002332:	f04a                	sd	s2,32(sp)
    80002334:	ec4e                	sd	s3,24(sp)
    80002336:	e852                	sd	s4,16(sp)
    80002338:	e456                	sd	s5,8(sp)
    8000233a:	0080                	addi	s0,sp,64
    8000233c:	8a2a                	mv	s4,a0
	struct proc *p;

	for (p = proc; p < &proc[NPROC]; p++)
    8000233e:	0000f497          	auipc	s1,0xf
    80002342:	39248493          	addi	s1,s1,914 # 800116d0 <proc>
	{
		if (p != myproc())
		{
			acquire(&p->lock);
			if (p->state == SLEEPING && p->chan == chan)
    80002346:	4989                	li	s3,2
			{
				p->state = RUNNABLE;
    80002348:	4a8d                	li	s5,3
	for (p = proc; p < &proc[NPROC]; p++)
    8000234a:	00015917          	auipc	s2,0x15
    8000234e:	38690913          	addi	s2,s2,902 # 800176d0 <tickslock>
    80002352:	a811                	j	80002366 <wakeup+0x3c>
			}
			release(&p->lock);
    80002354:	8526                	mv	a0,s1
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	920080e7          	jalr	-1760(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    8000235e:	18048493          	addi	s1,s1,384
    80002362:	03248663          	beq	s1,s2,8000238e <wakeup+0x64>
		if (p != myproc())
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	618080e7          	jalr	1560(ra) # 8000197e <myproc>
    8000236e:	fea488e3          	beq	s1,a0,8000235e <wakeup+0x34>
			acquire(&p->lock);
    80002372:	8526                	mv	a0,s1
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	84e080e7          	jalr	-1970(ra) # 80000bc2 <acquire>
			if (p->state == SLEEPING && p->chan == chan)
    8000237c:	4c9c                	lw	a5,24(s1)
    8000237e:	fd379be3          	bne	a5,s3,80002354 <wakeup+0x2a>
    80002382:	709c                	ld	a5,32(s1)
    80002384:	fd4798e3          	bne	a5,s4,80002354 <wakeup+0x2a>
				p->state = RUNNABLE;
    80002388:	0154ac23          	sw	s5,24(s1)
    8000238c:	b7e1                	j	80002354 <wakeup+0x2a>
		}
	}
}
    8000238e:	70e2                	ld	ra,56(sp)
    80002390:	7442                	ld	s0,48(sp)
    80002392:	74a2                	ld	s1,40(sp)
    80002394:	7902                	ld	s2,32(sp)
    80002396:	69e2                	ld	s3,24(sp)
    80002398:	6a42                	ld	s4,16(sp)
    8000239a:	6aa2                	ld	s5,8(sp)
    8000239c:	6121                	addi	sp,sp,64
    8000239e:	8082                	ret

00000000800023a0 <reparent>:
{
    800023a0:	7179                	addi	sp,sp,-48
    800023a2:	f406                	sd	ra,40(sp)
    800023a4:	f022                	sd	s0,32(sp)
    800023a6:	ec26                	sd	s1,24(sp)
    800023a8:	e84a                	sd	s2,16(sp)
    800023aa:	e44e                	sd	s3,8(sp)
    800023ac:	e052                	sd	s4,0(sp)
    800023ae:	1800                	addi	s0,sp,48
    800023b0:	892a                	mv	s2,a0
	for (pp = proc; pp < &proc[NPROC]; pp++)
    800023b2:	0000f497          	auipc	s1,0xf
    800023b6:	31e48493          	addi	s1,s1,798 # 800116d0 <proc>
			pp->parent = initproc;
    800023ba:	00007a17          	auipc	s4,0x7
    800023be:	c6ea0a13          	addi	s4,s4,-914 # 80009028 <initproc>
	for (pp = proc; pp < &proc[NPROC]; pp++)
    800023c2:	00015997          	auipc	s3,0x15
    800023c6:	30e98993          	addi	s3,s3,782 # 800176d0 <tickslock>
    800023ca:	a029                	j	800023d4 <reparent+0x34>
    800023cc:	18048493          	addi	s1,s1,384
    800023d0:	01348d63          	beq	s1,s3,800023ea <reparent+0x4a>
		if (pp->parent == p)
    800023d4:	68bc                	ld	a5,80(s1)
    800023d6:	ff279be3          	bne	a5,s2,800023cc <reparent+0x2c>
			pp->parent = initproc;
    800023da:	000a3503          	ld	a0,0(s4)
    800023de:	e8a8                	sd	a0,80(s1)
			wakeup(initproc);
    800023e0:	00000097          	auipc	ra,0x0
    800023e4:	f4a080e7          	jalr	-182(ra) # 8000232a <wakeup>
    800023e8:	b7d5                	j	800023cc <reparent+0x2c>
}
    800023ea:	70a2                	ld	ra,40(sp)
    800023ec:	7402                	ld	s0,32(sp)
    800023ee:	64e2                	ld	s1,24(sp)
    800023f0:	6942                	ld	s2,16(sp)
    800023f2:	69a2                	ld	s3,8(sp)
    800023f4:	6a02                	ld	s4,0(sp)
    800023f6:	6145                	addi	sp,sp,48
    800023f8:	8082                	ret

00000000800023fa <exit>:
{
    800023fa:	7179                	addi	sp,sp,-48
    800023fc:	f406                	sd	ra,40(sp)
    800023fe:	f022                	sd	s0,32(sp)
    80002400:	ec26                	sd	s1,24(sp)
    80002402:	e84a                	sd	s2,16(sp)
    80002404:	e44e                	sd	s3,8(sp)
    80002406:	e052                	sd	s4,0(sp)
    80002408:	1800                	addi	s0,sp,48
    8000240a:	8a2a                	mv	s4,a0
	struct proc *p = myproc();
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	572080e7          	jalr	1394(ra) # 8000197e <myproc>
    80002414:	89aa                	mv	s3,a0
	if (p == initproc)
    80002416:	00007797          	auipc	a5,0x7
    8000241a:	c127b783          	ld	a5,-1006(a5) # 80009028 <initproc>
    8000241e:	0e850493          	addi	s1,a0,232
    80002422:	16850913          	addi	s2,a0,360
    80002426:	02a79363          	bne	a5,a0,8000244c <exit+0x52>
		panic("init exiting");
    8000242a:	00006517          	auipc	a0,0x6
    8000242e:	e1e50513          	addi	a0,a0,-482 # 80008248 <digits+0x208>
    80002432:	ffffe097          	auipc	ra,0xffffe
    80002436:	0f8080e7          	jalr	248(ra) # 8000052a <panic>
			fileclose(f);
    8000243a:	00002097          	auipc	ra,0x2
    8000243e:	5a2080e7          	jalr	1442(ra) # 800049dc <fileclose>
			p->ofile[fd] = 0;
    80002442:	0004b023          	sd	zero,0(s1)
	for (int fd = 0; fd < NOFILE; fd++)
    80002446:	04a1                	addi	s1,s1,8
    80002448:	01248563          	beq	s1,s2,80002452 <exit+0x58>
		if (p->ofile[fd])
    8000244c:	6088                	ld	a0,0(s1)
    8000244e:	f575                	bnez	a0,8000243a <exit+0x40>
    80002450:	bfdd                	j	80002446 <exit+0x4c>
	begin_op();
    80002452:	00002097          	auipc	ra,0x2
    80002456:	0be080e7          	jalr	190(ra) # 80004510 <begin_op>
	iput(p->cwd);
    8000245a:	1689b503          	ld	a0,360(s3)
    8000245e:	00002097          	auipc	ra,0x2
    80002462:	896080e7          	jalr	-1898(ra) # 80003cf4 <iput>
	end_op();
    80002466:	00002097          	auipc	ra,0x2
    8000246a:	12a080e7          	jalr	298(ra) # 80004590 <end_op>
	p->cwd = 0;
    8000246e:	1609b423          	sd	zero,360(s3)
	acquire(&wait_lock);
    80002472:	0000f497          	auipc	s1,0xf
    80002476:	e4648493          	addi	s1,s1,-442 # 800112b8 <wait_lock>
    8000247a:	8526                	mv	a0,s1
    8000247c:	ffffe097          	auipc	ra,0xffffe
    80002480:	746080e7          	jalr	1862(ra) # 80000bc2 <acquire>
	reparent(p);
    80002484:	854e                	mv	a0,s3
    80002486:	00000097          	auipc	ra,0x0
    8000248a:	f1a080e7          	jalr	-230(ra) # 800023a0 <reparent>
	wakeup(p->parent);
    8000248e:	0509b503          	ld	a0,80(s3)
    80002492:	00000097          	auipc	ra,0x0
    80002496:	e98080e7          	jalr	-360(ra) # 8000232a <wakeup>
	acquire(&p->lock);
    8000249a:	854e                	mv	a0,s3
    8000249c:	ffffe097          	auipc	ra,0xffffe
    800024a0:	726080e7          	jalr	1830(ra) # 80000bc2 <acquire>
	p->xstate = status;
    800024a4:	0349a623          	sw	s4,44(s3)
	p->state = ZOMBIE;
    800024a8:	4795                	li	a5,5
    800024aa:	00f9ac23          	sw	a5,24(s3)
	release(&wait_lock);
    800024ae:	8526                	mv	a0,s1
    800024b0:	ffffe097          	auipc	ra,0xffffe
    800024b4:	7c6080e7          	jalr	1990(ra) # 80000c76 <release>
	sched();
    800024b8:	00000097          	auipc	ra,0x0
    800024bc:	bd4080e7          	jalr	-1068(ra) # 8000208c <sched>
	panic("zombie exit");
    800024c0:	00006517          	auipc	a0,0x6
    800024c4:	d9850513          	addi	a0,a0,-616 # 80008258 <digits+0x218>
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	062080e7          	jalr	98(ra) # 8000052a <panic>

00000000800024d0 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800024d0:	7179                	addi	sp,sp,-48
    800024d2:	f406                	sd	ra,40(sp)
    800024d4:	f022                	sd	s0,32(sp)
    800024d6:	ec26                	sd	s1,24(sp)
    800024d8:	e84a                	sd	s2,16(sp)
    800024da:	e44e                	sd	s3,8(sp)
    800024dc:	1800                	addi	s0,sp,48
    800024de:	892a                	mv	s2,a0
	struct proc *p;

	for (p = proc; p < &proc[NPROC]; p++)
    800024e0:	0000f497          	auipc	s1,0xf
    800024e4:	1f048493          	addi	s1,s1,496 # 800116d0 <proc>
    800024e8:	00015997          	auipc	s3,0x15
    800024ec:	1e898993          	addi	s3,s3,488 # 800176d0 <tickslock>
	{
		acquire(&p->lock);
    800024f0:	8526                	mv	a0,s1
    800024f2:	ffffe097          	auipc	ra,0xffffe
    800024f6:	6d0080e7          	jalr	1744(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    800024fa:	589c                	lw	a5,48(s1)
    800024fc:	01278d63          	beq	a5,s2,80002516 <kill+0x46>
				p->state = RUNNABLE;
			}
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    80002500:	8526                	mv	a0,s1
    80002502:	ffffe097          	auipc	ra,0xffffe
    80002506:	774080e7          	jalr	1908(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    8000250a:	18048493          	addi	s1,s1,384
    8000250e:	ff3491e3          	bne	s1,s3,800024f0 <kill+0x20>
	}
	return -1;
    80002512:	557d                	li	a0,-1
    80002514:	a829                	j	8000252e <kill+0x5e>
			p->killed = 1;
    80002516:	4785                	li	a5,1
    80002518:	d49c                	sw	a5,40(s1)
			if (p->state == SLEEPING)
    8000251a:	4c98                	lw	a4,24(s1)
    8000251c:	4789                	li	a5,2
    8000251e:	00f70f63          	beq	a4,a5,8000253c <kill+0x6c>
			release(&p->lock);
    80002522:	8526                	mv	a0,s1
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	752080e7          	jalr	1874(ra) # 80000c76 <release>
			return 0;
    8000252c:	4501                	li	a0,0
}
    8000252e:	70a2                	ld	ra,40(sp)
    80002530:	7402                	ld	s0,32(sp)
    80002532:	64e2                	ld	s1,24(sp)
    80002534:	6942                	ld	s2,16(sp)
    80002536:	69a2                	ld	s3,8(sp)
    80002538:	6145                	addi	sp,sp,48
    8000253a:	8082                	ret
				p->state = RUNNABLE;
    8000253c:	478d                	li	a5,3
    8000253e:	cc9c                	sw	a5,24(s1)
    80002540:	b7cd                	j	80002522 <kill+0x52>

0000000080002542 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002542:	7179                	addi	sp,sp,-48
    80002544:	f406                	sd	ra,40(sp)
    80002546:	f022                	sd	s0,32(sp)
    80002548:	ec26                	sd	s1,24(sp)
    8000254a:	e84a                	sd	s2,16(sp)
    8000254c:	e44e                	sd	s3,8(sp)
    8000254e:	e052                	sd	s4,0(sp)
    80002550:	1800                	addi	s0,sp,48
    80002552:	84aa                	mv	s1,a0
    80002554:	892e                	mv	s2,a1
    80002556:	89b2                	mv	s3,a2
    80002558:	8a36                	mv	s4,a3
	struct proc *p = myproc();
    8000255a:	fffff097          	auipc	ra,0xfffff
    8000255e:	424080e7          	jalr	1060(ra) # 8000197e <myproc>
	if (user_dst)
    80002562:	c08d                	beqz	s1,80002584 <either_copyout+0x42>
	{
		return copyout(p->pagetable, dst, src, len);
    80002564:	86d2                	mv	a3,s4
    80002566:	864e                	mv	a2,s3
    80002568:	85ca                	mv	a1,s2
    8000256a:	7528                	ld	a0,104(a0)
    8000256c:	fffff097          	auipc	ra,0xfffff
    80002570:	0d2080e7          	jalr	210(ra) # 8000163e <copyout>
	else
	{
		memmove((char *)dst, src, len);
		return 0;
	}
}
    80002574:	70a2                	ld	ra,40(sp)
    80002576:	7402                	ld	s0,32(sp)
    80002578:	64e2                	ld	s1,24(sp)
    8000257a:	6942                	ld	s2,16(sp)
    8000257c:	69a2                	ld	s3,8(sp)
    8000257e:	6a02                	ld	s4,0(sp)
    80002580:	6145                	addi	sp,sp,48
    80002582:	8082                	ret
		memmove((char *)dst, src, len);
    80002584:	000a061b          	sext.w	a2,s4
    80002588:	85ce                	mv	a1,s3
    8000258a:	854a                	mv	a0,s2
    8000258c:	ffffe097          	auipc	ra,0xffffe
    80002590:	78e080e7          	jalr	1934(ra) # 80000d1a <memmove>
		return 0;
    80002594:	8526                	mv	a0,s1
    80002596:	bff9                	j	80002574 <either_copyout+0x32>

0000000080002598 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002598:	7179                	addi	sp,sp,-48
    8000259a:	f406                	sd	ra,40(sp)
    8000259c:	f022                	sd	s0,32(sp)
    8000259e:	ec26                	sd	s1,24(sp)
    800025a0:	e84a                	sd	s2,16(sp)
    800025a2:	e44e                	sd	s3,8(sp)
    800025a4:	e052                	sd	s4,0(sp)
    800025a6:	1800                	addi	s0,sp,48
    800025a8:	892a                	mv	s2,a0
    800025aa:	84ae                	mv	s1,a1
    800025ac:	89b2                	mv	s3,a2
    800025ae:	8a36                	mv	s4,a3
	struct proc *p = myproc();
    800025b0:	fffff097          	auipc	ra,0xfffff
    800025b4:	3ce080e7          	jalr	974(ra) # 8000197e <myproc>
	if (user_src)
    800025b8:	c08d                	beqz	s1,800025da <either_copyin+0x42>
	{
		return copyin(p->pagetable, dst, src, len);
    800025ba:	86d2                	mv	a3,s4
    800025bc:	864e                	mv	a2,s3
    800025be:	85ca                	mv	a1,s2
    800025c0:	7528                	ld	a0,104(a0)
    800025c2:	fffff097          	auipc	ra,0xfffff
    800025c6:	108080e7          	jalr	264(ra) # 800016ca <copyin>
	else
	{
		memmove(dst, (char *)src, len);
		return 0;
	}
}
    800025ca:	70a2                	ld	ra,40(sp)
    800025cc:	7402                	ld	s0,32(sp)
    800025ce:	64e2                	ld	s1,24(sp)
    800025d0:	6942                	ld	s2,16(sp)
    800025d2:	69a2                	ld	s3,8(sp)
    800025d4:	6a02                	ld	s4,0(sp)
    800025d6:	6145                	addi	sp,sp,48
    800025d8:	8082                	ret
		memmove(dst, (char *)src, len);
    800025da:	000a061b          	sext.w	a2,s4
    800025de:	85ce                	mv	a1,s3
    800025e0:	854a                	mv	a0,s2
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	738080e7          	jalr	1848(ra) # 80000d1a <memmove>
		return 0;
    800025ea:	8526                	mv	a0,s1
    800025ec:	bff9                	j	800025ca <either_copyin+0x32>

00000000800025ee <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800025ee:	715d                	addi	sp,sp,-80
    800025f0:	e486                	sd	ra,72(sp)
    800025f2:	e0a2                	sd	s0,64(sp)
    800025f4:	fc26                	sd	s1,56(sp)
    800025f6:	f84a                	sd	s2,48(sp)
    800025f8:	f44e                	sd	s3,40(sp)
    800025fa:	f052                	sd	s4,32(sp)
    800025fc:	ec56                	sd	s5,24(sp)
    800025fe:	e85a                	sd	s6,16(sp)
    80002600:	e45e                	sd	s7,8(sp)
    80002602:	0880                	addi	s0,sp,80
		[RUNNING] "run   ",
		[ZOMBIE] "zombie"};
	struct proc *p;
	char *state;

	printf("\n");
    80002604:	00006517          	auipc	a0,0x6
    80002608:	ac450513          	addi	a0,a0,-1340 # 800080c8 <digits+0x88>
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	f68080e7          	jalr	-152(ra) # 80000574 <printf>
	for (p = proc; p < &proc[NPROC]; p++)
    80002614:	0000f497          	auipc	s1,0xf
    80002618:	22c48493          	addi	s1,s1,556 # 80011840 <proc+0x170>
    8000261c:	00015917          	auipc	s2,0x15
    80002620:	22490913          	addi	s2,s2,548 # 80017840 <bcache+0x158>
	{
		if (p->state == UNUSED)
			continue;
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002624:	4b15                	li	s6,5
			state = states[p->state];
		else
			state = "???";
    80002626:	00006997          	auipc	s3,0x6
    8000262a:	c4298993          	addi	s3,s3,-958 # 80008268 <digits+0x228>
		printf("%d %s %s", p->pid, state, p->name);
    8000262e:	00006a97          	auipc	s5,0x6
    80002632:	c42a8a93          	addi	s5,s5,-958 # 80008270 <digits+0x230>
		printf("\n");
    80002636:	00006a17          	auipc	s4,0x6
    8000263a:	a92a0a13          	addi	s4,s4,-1390 # 800080c8 <digits+0x88>
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000263e:	00006b97          	auipc	s7,0x6
    80002642:	c6ab8b93          	addi	s7,s7,-918 # 800082a8 <states.0>
    80002646:	a00d                	j	80002668 <procdump+0x7a>
		printf("%d %s %s", p->pid, state, p->name);
    80002648:	ec06a583          	lw	a1,-320(a3)
    8000264c:	8556                	mv	a0,s5
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	f26080e7          	jalr	-218(ra) # 80000574 <printf>
		printf("\n");
    80002656:	8552                	mv	a0,s4
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	f1c080e7          	jalr	-228(ra) # 80000574 <printf>
	for (p = proc; p < &proc[NPROC]; p++)
    80002660:	18048493          	addi	s1,s1,384
    80002664:	03248263          	beq	s1,s2,80002688 <procdump+0x9a>
		if (p->state == UNUSED)
    80002668:	86a6                	mv	a3,s1
    8000266a:	ea84a783          	lw	a5,-344(s1)
    8000266e:	dbed                	beqz	a5,80002660 <procdump+0x72>
			state = "???";
    80002670:	864e                	mv	a2,s3
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002672:	fcfb6be3          	bltu	s6,a5,80002648 <procdump+0x5a>
    80002676:	02079713          	slli	a4,a5,0x20
    8000267a:	01d75793          	srli	a5,a4,0x1d
    8000267e:	97de                	add	a5,a5,s7
    80002680:	6390                	ld	a2,0(a5)
    80002682:	f279                	bnez	a2,80002648 <procdump+0x5a>
			state = "???";
    80002684:	864e                	mv	a2,s3
    80002686:	b7c9                	j	80002648 <procdump+0x5a>
	}
}
    80002688:	60a6                	ld	ra,72(sp)
    8000268a:	6406                	ld	s0,64(sp)
    8000268c:	74e2                	ld	s1,56(sp)
    8000268e:	7942                	ld	s2,48(sp)
    80002690:	79a2                	ld	s3,40(sp)
    80002692:	7a02                	ld	s4,32(sp)
    80002694:	6ae2                	ld	s5,24(sp)
    80002696:	6b42                	ld	s6,16(sp)
    80002698:	6ba2                	ld	s7,8(sp)
    8000269a:	6161                	addi	sp,sp,80
    8000269c:	8082                	ret

000000008000269e <trace>:
//ADDED
int trace(int mask, int pid)
{
    8000269e:	7179                	addi	sp,sp,-48
    800026a0:	f406                	sd	ra,40(sp)
    800026a2:	f022                	sd	s0,32(sp)
    800026a4:	ec26                	sd	s1,24(sp)
    800026a6:	e84a                	sd	s2,16(sp)
    800026a8:	e44e                	sd	s3,8(sp)
    800026aa:	e052                	sd	s4,0(sp)
    800026ac:	1800                	addi	s0,sp,48
    800026ae:	8a2a                	mv	s4,a0
    800026b0:	892e                	mv	s2,a1
	struct proc *p;
	for (p = proc; p < &proc[NPROC]; p++)
    800026b2:	0000f497          	auipc	s1,0xf
    800026b6:	01e48493          	addi	s1,s1,30 # 800116d0 <proc>
    800026ba:	00015997          	auipc	s3,0x15
    800026be:	01698993          	addi	s3,s3,22 # 800176d0 <tickslock>
	{
		acquire(&p->lock);
    800026c2:	8526                	mv	a0,s1
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	4fe080e7          	jalr	1278(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    800026cc:	589c                	lw	a5,48(s1)
    800026ce:	01278d63          	beq	a5,s2,800026e8 <trace+0x4a>
		{
			p->trace_mask = mask;
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    800026d2:	8526                	mv	a0,s1
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	5a2080e7          	jalr	1442(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    800026dc:	18048493          	addi	s1,s1,384
    800026e0:	ff3491e3          	bne	s1,s3,800026c2 <trace+0x24>
	}

	return -1;
    800026e4:	557d                	li	a0,-1
    800026e6:	a809                	j	800026f8 <trace+0x5a>
			p->trace_mask = mask;
    800026e8:	0344aa23          	sw	s4,52(s1)
			release(&p->lock);
    800026ec:	8526                	mv	a0,s1
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	588080e7          	jalr	1416(ra) # 80000c76 <release>
			return 0;
    800026f6:	4501                	li	a0,0
}
    800026f8:	70a2                	ld	ra,40(sp)
    800026fa:	7402                	ld	s0,32(sp)
    800026fc:	64e2                	ld	s1,24(sp)
    800026fe:	6942                	ld	s2,16(sp)
    80002700:	69a2                	ld	s3,8(sp)
    80002702:	6a02                	ld	s4,0(sp)
    80002704:	6145                	addi	sp,sp,48
    80002706:	8082                	ret

0000000080002708 <getmsk>:

int getmsk(int pid)
{
    80002708:	7179                	addi	sp,sp,-48
    8000270a:	f406                	sd	ra,40(sp)
    8000270c:	f022                	sd	s0,32(sp)
    8000270e:	ec26                	sd	s1,24(sp)
    80002710:	e84a                	sd	s2,16(sp)
    80002712:	e44e                	sd	s3,8(sp)
    80002714:	1800                	addi	s0,sp,48
    80002716:	892a                	mv	s2,a0
	struct proc *p;
	int mask;

	for (p = proc; p < &proc[NPROC]; p++)
    80002718:	0000f497          	auipc	s1,0xf
    8000271c:	fb848493          	addi	s1,s1,-72 # 800116d0 <proc>
    80002720:	00015997          	auipc	s3,0x15
    80002724:	fb098993          	addi	s3,s3,-80 # 800176d0 <tickslock>
	{
		acquire(&p->lock);
    80002728:	8526                	mv	a0,s1
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	498080e7          	jalr	1176(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    80002732:	589c                	lw	a5,48(s1)
    80002734:	01278d63          	beq	a5,s2,8000274e <getmsk+0x46>
		{
			mask = p->trace_mask;
			release(&p->lock);
			return mask;
		}
		release(&p->lock);
    80002738:	8526                	mv	a0,s1
    8000273a:	ffffe097          	auipc	ra,0xffffe
    8000273e:	53c080e7          	jalr	1340(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80002742:	18048493          	addi	s1,s1,384
    80002746:	ff3491e3          	bne	s1,s3,80002728 <getmsk+0x20>
	}

	return -1;
    8000274a:	597d                	li	s2,-1
    8000274c:	a801                	j	8000275c <getmsk+0x54>
			mask = p->trace_mask;
    8000274e:	0344a903          	lw	s2,52(s1)
			release(&p->lock);
    80002752:	8526                	mv	a0,s1
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	522080e7          	jalr	1314(ra) # 80000c76 <release>
}
    8000275c:	854a                	mv	a0,s2
    8000275e:	70a2                	ld	ra,40(sp)
    80002760:	7402                	ld	s0,32(sp)
    80002762:	64e2                	ld	s1,24(sp)
    80002764:	6942                	ld	s2,16(sp)
    80002766:	69a2                	ld	s3,8(sp)
    80002768:	6145                	addi	sp,sp,48
    8000276a:	8082                	ret

000000008000276c <update_perf>:
	}
}

// ADDED
void update_perf(uint ticks, struct proc *p)
{
    8000276c:	1141                	addi	sp,sp,-16
    8000276e:	e422                	sd	s0,8(sp)
    80002770:	0800                	addi	s0,sp,16
	switch (p->state)
    80002772:	4d9c                	lw	a5,24(a1)
    80002774:	4711                	li	a4,4
    80002776:	02e78763          	beq	a5,a4,800027a4 <update_perf+0x38>
    8000277a:	00f76c63          	bltu	a4,a5,80002792 <update_perf+0x26>
    8000277e:	4709                	li	a4,2
    80002780:	02e78863          	beq	a5,a4,800027b0 <update_perf+0x44>
    80002784:	470d                	li	a4,3
    80002786:	02e79263          	bne	a5,a4,800027aa <update_perf+0x3e>
		break;
	case SLEEPING:
		p->performance.stime++;
		break;
	case RUNNABLE:
		p->performance.retime++;
    8000278a:	41fc                	lw	a5,68(a1)
    8000278c:	2785                	addiw	a5,a5,1
    8000278e:	c1fc                	sw	a5,68(a1)
		break;
    80002790:	a829                	j	800027aa <update_perf+0x3e>
	switch (p->state)
    80002792:	4715                	li	a4,5
    80002794:	00e79b63          	bne	a5,a4,800027aa <update_perf+0x3e>
	case ZOMBIE:
		if (p->performance.ttime == -1)
    80002798:	5dd8                	lw	a4,60(a1)
    8000279a:	57fd                	li	a5,-1
    8000279c:	00f71763          	bne	a4,a5,800027aa <update_perf+0x3e>
			p->performance.ttime = ticks;
    800027a0:	ddc8                	sw	a0,60(a1)
		break;
	default:
		break;
	}
}
    800027a2:	a021                	j	800027aa <update_perf+0x3e>
		p->performance.rutime++;
    800027a4:	45bc                	lw	a5,72(a1)
    800027a6:	2785                	addiw	a5,a5,1
    800027a8:	c5bc                	sw	a5,72(a1)
}
    800027aa:	6422                	ld	s0,8(sp)
    800027ac:	0141                	addi	sp,sp,16
    800027ae:	8082                	ret
		p->performance.stime++;
    800027b0:	41bc                	lw	a5,64(a1)
    800027b2:	2785                	addiw	a5,a5,1
    800027b4:	c1bc                	sw	a5,64(a1)
		break;
    800027b6:	bfd5                	j	800027aa <update_perf+0x3e>

00000000800027b8 <wait_stat>:
{
    800027b8:	711d                	addi	sp,sp,-96
    800027ba:	ec86                	sd	ra,88(sp)
    800027bc:	e8a2                	sd	s0,80(sp)
    800027be:	e4a6                	sd	s1,72(sp)
    800027c0:	e0ca                	sd	s2,64(sp)
    800027c2:	fc4e                	sd	s3,56(sp)
    800027c4:	f852                	sd	s4,48(sp)
    800027c6:	f456                	sd	s5,40(sp)
    800027c8:	f05a                	sd	s6,32(sp)
    800027ca:	ec5e                	sd	s7,24(sp)
    800027cc:	e862                	sd	s8,16(sp)
    800027ce:	e466                	sd	s9,8(sp)
    800027d0:	1080                	addi	s0,sp,96
    800027d2:	8b2a                	mv	s6,a0
    800027d4:	8bae                	mv	s7,a1
	struct proc *p = myproc();
    800027d6:	fffff097          	auipc	ra,0xfffff
    800027da:	1a8080e7          	jalr	424(ra) # 8000197e <myproc>
    800027de:	892a                	mv	s2,a0
	acquire(&wait_lock);
    800027e0:	0000f517          	auipc	a0,0xf
    800027e4:	ad850513          	addi	a0,a0,-1320 # 800112b8 <wait_lock>
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	3da080e7          	jalr	986(ra) # 80000bc2 <acquire>
		havekids = 0;
    800027f0:	4c01                	li	s8,0
				if (np->state == ZOMBIE)
    800027f2:	4a15                	li	s4,5
				havekids = 1;
    800027f4:	4a85                	li	s5,1
		for (np = proc; np < &proc[NPROC]; np++)
    800027f6:	00015997          	auipc	s3,0x15
    800027fa:	eda98993          	addi	s3,s3,-294 # 800176d0 <tickslock>
		sleep(p, &wait_lock); //DOC: wait-sleep
    800027fe:	0000fc97          	auipc	s9,0xf
    80002802:	abac8c93          	addi	s9,s9,-1350 # 800112b8 <wait_lock>
		havekids = 0;
    80002806:	8762                	mv	a4,s8
		for (np = proc; np < &proc[NPROC]; np++)
    80002808:	0000f497          	auipc	s1,0xf
    8000280c:	ec848493          	addi	s1,s1,-312 # 800116d0 <proc>
    80002810:	a85d                	j	800028c6 <wait_stat+0x10e>
					pid = np->pid;
    80002812:	0304a983          	lw	s3,48(s1)
					update_perf(ticks, np);
    80002816:	85a6                	mv	a1,s1
    80002818:	00007517          	auipc	a0,0x7
    8000281c:	81852503          	lw	a0,-2024(a0) # 80009030 <ticks>
    80002820:	00000097          	auipc	ra,0x0
    80002824:	f4c080e7          	jalr	-180(ra) # 8000276c <update_perf>
					if (status != 0 && copyout(p->pagetable, status, (char *)&np->xstate,
    80002828:	000b0e63          	beqz	s6,80002844 <wait_stat+0x8c>
    8000282c:	4691                	li	a3,4
    8000282e:	02c48613          	addi	a2,s1,44
    80002832:	85da                	mv	a1,s6
    80002834:	06893503          	ld	a0,104(s2)
    80002838:	fffff097          	auipc	ra,0xfffff
    8000283c:	e06080e7          	jalr	-506(ra) # 8000163e <copyout>
    80002840:	04054163          	bltz	a0,80002882 <wait_stat+0xca>
					if (copyout(p->pagetable, performance, (char *)&(np->performance), sizeof(struct perf)) < 0)
    80002844:	46e1                	li	a3,24
    80002846:	03848613          	addi	a2,s1,56
    8000284a:	85de                	mv	a1,s7
    8000284c:	06893503          	ld	a0,104(s2)
    80002850:	fffff097          	auipc	ra,0xfffff
    80002854:	dee080e7          	jalr	-530(ra) # 8000163e <copyout>
    80002858:	04054463          	bltz	a0,800028a0 <wait_stat+0xe8>
					freeproc(np);
    8000285c:	8526                	mv	a0,s1
    8000285e:	fffff097          	auipc	ra,0xfffff
    80002862:	2d2080e7          	jalr	722(ra) # 80001b30 <freeproc>
					release(&np->lock);
    80002866:	8526                	mv	a0,s1
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	40e080e7          	jalr	1038(ra) # 80000c76 <release>
					release(&wait_lock);
    80002870:	0000f517          	auipc	a0,0xf
    80002874:	a4850513          	addi	a0,a0,-1464 # 800112b8 <wait_lock>
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	3fe080e7          	jalr	1022(ra) # 80000c76 <release>
					return pid;
    80002880:	a051                	j	80002904 <wait_stat+0x14c>
						release(&np->lock);
    80002882:	8526                	mv	a0,s1
    80002884:	ffffe097          	auipc	ra,0xffffe
    80002888:	3f2080e7          	jalr	1010(ra) # 80000c76 <release>
						release(&wait_lock);
    8000288c:	0000f517          	auipc	a0,0xf
    80002890:	a2c50513          	addi	a0,a0,-1492 # 800112b8 <wait_lock>
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	3e2080e7          	jalr	994(ra) # 80000c76 <release>
						return -1;
    8000289c:	59fd                	li	s3,-1
    8000289e:	a09d                	j	80002904 <wait_stat+0x14c>
						release(&np->lock);
    800028a0:	8526                	mv	a0,s1
    800028a2:	ffffe097          	auipc	ra,0xffffe
    800028a6:	3d4080e7          	jalr	980(ra) # 80000c76 <release>
						release(&wait_lock);
    800028aa:	0000f517          	auipc	a0,0xf
    800028ae:	a0e50513          	addi	a0,a0,-1522 # 800112b8 <wait_lock>
    800028b2:	ffffe097          	auipc	ra,0xffffe
    800028b6:	3c4080e7          	jalr	964(ra) # 80000c76 <release>
						return -1;
    800028ba:	59fd                	li	s3,-1
    800028bc:	a0a1                	j	80002904 <wait_stat+0x14c>
		for (np = proc; np < &proc[NPROC]; np++)
    800028be:	18048493          	addi	s1,s1,384
    800028c2:	03348463          	beq	s1,s3,800028ea <wait_stat+0x132>
			if (np->parent == p)
    800028c6:	68bc                	ld	a5,80(s1)
    800028c8:	ff279be3          	bne	a5,s2,800028be <wait_stat+0x106>
				acquire(&np->lock);
    800028cc:	8526                	mv	a0,s1
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	2f4080e7          	jalr	756(ra) # 80000bc2 <acquire>
				if (np->state == ZOMBIE)
    800028d6:	4c9c                	lw	a5,24(s1)
    800028d8:	f3478de3          	beq	a5,s4,80002812 <wait_stat+0x5a>
				release(&np->lock);
    800028dc:	8526                	mv	a0,s1
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	398080e7          	jalr	920(ra) # 80000c76 <release>
				havekids = 1;
    800028e6:	8756                	mv	a4,s5
    800028e8:	bfd9                	j	800028be <wait_stat+0x106>
		if (!havekids || p->killed)
    800028ea:	c701                	beqz	a4,800028f2 <wait_stat+0x13a>
    800028ec:	02892783          	lw	a5,40(s2)
    800028f0:	cb85                	beqz	a5,80002920 <wait_stat+0x168>
			release(&wait_lock);
    800028f2:	0000f517          	auipc	a0,0xf
    800028f6:	9c650513          	addi	a0,a0,-1594 # 800112b8 <wait_lock>
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	37c080e7          	jalr	892(ra) # 80000c76 <release>
			return -1;
    80002902:	59fd                	li	s3,-1
}
    80002904:	854e                	mv	a0,s3
    80002906:	60e6                	ld	ra,88(sp)
    80002908:	6446                	ld	s0,80(sp)
    8000290a:	64a6                	ld	s1,72(sp)
    8000290c:	6906                	ld	s2,64(sp)
    8000290e:	79e2                	ld	s3,56(sp)
    80002910:	7a42                	ld	s4,48(sp)
    80002912:	7aa2                	ld	s5,40(sp)
    80002914:	7b02                	ld	s6,32(sp)
    80002916:	6be2                	ld	s7,24(sp)
    80002918:	6c42                	ld	s8,16(sp)
    8000291a:	6ca2                	ld	s9,8(sp)
    8000291c:	6125                	addi	sp,sp,96
    8000291e:	8082                	ret
		sleep(p, &wait_lock); //DOC: wait-sleep
    80002920:	85e6                	mv	a1,s9
    80002922:	854a                	mv	a0,s2
    80002924:	00000097          	auipc	ra,0x0
    80002928:	87a080e7          	jalr	-1926(ra) # 8000219e <sleep>
		havekids = 0;
    8000292c:	bde9                	j	80002806 <wait_stat+0x4e>

000000008000292e <update_perfs>:

// ADDED
void update_perfs(uint ticks)
{
    8000292e:	7179                	addi	sp,sp,-48
    80002930:	f406                	sd	ra,40(sp)
    80002932:	f022                	sd	s0,32(sp)
    80002934:	ec26                	sd	s1,24(sp)
    80002936:	e84a                	sd	s2,16(sp)
    80002938:	e44e                	sd	s3,8(sp)
    8000293a:	1800                	addi	s0,sp,48
    8000293c:	892a                	mv	s2,a0
	struct proc *p;
	for (p = proc; p < &proc[NPROC]; p++)
    8000293e:	0000f497          	auipc	s1,0xf
    80002942:	d9248493          	addi	s1,s1,-622 # 800116d0 <proc>
    80002946:	00015997          	auipc	s3,0x15
    8000294a:	d8a98993          	addi	s3,s3,-630 # 800176d0 <tickslock>
	{
		acquire(&p->lock);
    8000294e:	8526                	mv	a0,s1
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	272080e7          	jalr	626(ra) # 80000bc2 <acquire>
		update_perf(ticks, p);
    80002958:	85a6                	mv	a1,s1
    8000295a:	854a                	mv	a0,s2
    8000295c:	00000097          	auipc	ra,0x0
    80002960:	e10080e7          	jalr	-496(ra) # 8000276c <update_perf>
		release(&p->lock);
    80002964:	8526                	mv	a0,s1
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	310080e7          	jalr	784(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    8000296e:	18048493          	addi	s1,s1,384
    80002972:	fd349ee3          	bne	s1,s3,8000294e <update_perfs+0x20>
	}
    80002976:	70a2                	ld	ra,40(sp)
    80002978:	7402                	ld	s0,32(sp)
    8000297a:	64e2                	ld	s1,24(sp)
    8000297c:	6942                	ld	s2,16(sp)
    8000297e:	69a2                	ld	s3,8(sp)
    80002980:	6145                	addi	sp,sp,48
    80002982:	8082                	ret

0000000080002984 <swtch>:
    80002984:	00153023          	sd	ra,0(a0)
    80002988:	00253423          	sd	sp,8(a0)
    8000298c:	e900                	sd	s0,16(a0)
    8000298e:	ed04                	sd	s1,24(a0)
    80002990:	03253023          	sd	s2,32(a0)
    80002994:	03353423          	sd	s3,40(a0)
    80002998:	03453823          	sd	s4,48(a0)
    8000299c:	03553c23          	sd	s5,56(a0)
    800029a0:	05653023          	sd	s6,64(a0)
    800029a4:	05753423          	sd	s7,72(a0)
    800029a8:	05853823          	sd	s8,80(a0)
    800029ac:	05953c23          	sd	s9,88(a0)
    800029b0:	07a53023          	sd	s10,96(a0)
    800029b4:	07b53423          	sd	s11,104(a0)
    800029b8:	0005b083          	ld	ra,0(a1)
    800029bc:	0085b103          	ld	sp,8(a1)
    800029c0:	6980                	ld	s0,16(a1)
    800029c2:	6d84                	ld	s1,24(a1)
    800029c4:	0205b903          	ld	s2,32(a1)
    800029c8:	0285b983          	ld	s3,40(a1)
    800029cc:	0305ba03          	ld	s4,48(a1)
    800029d0:	0385ba83          	ld	s5,56(a1)
    800029d4:	0405bb03          	ld	s6,64(a1)
    800029d8:	0485bb83          	ld	s7,72(a1)
    800029dc:	0505bc03          	ld	s8,80(a1)
    800029e0:	0585bc83          	ld	s9,88(a1)
    800029e4:	0605bd03          	ld	s10,96(a1)
    800029e8:	0685bd83          	ld	s11,104(a1)
    800029ec:	8082                	ret

00000000800029ee <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029ee:	1141                	addi	sp,sp,-16
    800029f0:	e406                	sd	ra,8(sp)
    800029f2:	e022                	sd	s0,0(sp)
    800029f4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029f6:	00006597          	auipc	a1,0x6
    800029fa:	8e258593          	addi	a1,a1,-1822 # 800082d8 <states.0+0x30>
    800029fe:	00015517          	auipc	a0,0x15
    80002a02:	cd250513          	addi	a0,a0,-814 # 800176d0 <tickslock>
    80002a06:	ffffe097          	auipc	ra,0xffffe
    80002a0a:	12c080e7          	jalr	300(ra) # 80000b32 <initlock>
}
    80002a0e:	60a2                	ld	ra,8(sp)
    80002a10:	6402                	ld	s0,0(sp)
    80002a12:	0141                	addi	sp,sp,16
    80002a14:	8082                	ret

0000000080002a16 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a16:	1141                	addi	sp,sp,-16
    80002a18:	e422                	sd	s0,8(sp)
    80002a1a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a1c:	00003797          	auipc	a5,0x3
    80002a20:	5e478793          	addi	a5,a5,1508 # 80006000 <kernelvec>
    80002a24:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a28:	6422                	ld	s0,8(sp)
    80002a2a:	0141                	addi	sp,sp,16
    80002a2c:	8082                	ret

0000000080002a2e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a2e:	1141                	addi	sp,sp,-16
    80002a30:	e406                	sd	ra,8(sp)
    80002a32:	e022                	sd	s0,0(sp)
    80002a34:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a36:	fffff097          	auipc	ra,0xfffff
    80002a3a:	f48080e7          	jalr	-184(ra) # 8000197e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a3e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a42:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a44:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a48:	00004617          	auipc	a2,0x4
    80002a4c:	5b860613          	addi	a2,a2,1464 # 80007000 <_trampoline>
    80002a50:	00004697          	auipc	a3,0x4
    80002a54:	5b068693          	addi	a3,a3,1456 # 80007000 <_trampoline>
    80002a58:	8e91                	sub	a3,a3,a2
    80002a5a:	040007b7          	lui	a5,0x4000
    80002a5e:	17fd                	addi	a5,a5,-1
    80002a60:	07b2                	slli	a5,a5,0xc
    80002a62:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a64:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a68:	7938                	ld	a4,112(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a6a:	180026f3          	csrr	a3,satp
    80002a6e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a70:	7938                	ld	a4,112(a0)
    80002a72:	6d34                	ld	a3,88(a0)
    80002a74:	6585                	lui	a1,0x1
    80002a76:	96ae                	add	a3,a3,a1
    80002a78:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a7a:	7938                	ld	a4,112(a0)
    80002a7c:	00000697          	auipc	a3,0x0
    80002a80:	14868693          	addi	a3,a3,328 # 80002bc4 <usertrap>
    80002a84:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a86:	7938                	ld	a4,112(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a88:	8692                	mv	a3,tp
    80002a8a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a8c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a90:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a94:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a98:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a9c:	7938                	ld	a4,112(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a9e:	6f18                	ld	a4,24(a4)
    80002aa0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002aa4:	752c                	ld	a1,104(a0)
    80002aa6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002aa8:	00004717          	auipc	a4,0x4
    80002aac:	5e870713          	addi	a4,a4,1512 # 80007090 <userret>
    80002ab0:	8f11                	sub	a4,a4,a2
    80002ab2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002ab4:	577d                	li	a4,-1
    80002ab6:	177e                	slli	a4,a4,0x3f
    80002ab8:	8dd9                	or	a1,a1,a4
    80002aba:	02000537          	lui	a0,0x2000
    80002abe:	157d                	addi	a0,a0,-1
    80002ac0:	0536                	slli	a0,a0,0xd
    80002ac2:	9782                	jalr	a5
}
    80002ac4:	60a2                	ld	ra,8(sp)
    80002ac6:	6402                	ld	s0,0(sp)
    80002ac8:	0141                	addi	sp,sp,16
    80002aca:	8082                	ret

0000000080002acc <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002acc:	1101                	addi	sp,sp,-32
    80002ace:	ec06                	sd	ra,24(sp)
    80002ad0:	e822                	sd	s0,16(sp)
    80002ad2:	e426                	sd	s1,8(sp)
    80002ad4:	e04a                	sd	s2,0(sp)
    80002ad6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ad8:	00015917          	auipc	s2,0x15
    80002adc:	bf890913          	addi	s2,s2,-1032 # 800176d0 <tickslock>
    80002ae0:	854a                	mv	a0,s2
    80002ae2:	ffffe097          	auipc	ra,0xffffe
    80002ae6:	0e0080e7          	jalr	224(ra) # 80000bc2 <acquire>
  ticks++;
    80002aea:	00006497          	auipc	s1,0x6
    80002aee:	54648493          	addi	s1,s1,1350 # 80009030 <ticks>
    80002af2:	4088                	lw	a0,0(s1)
    80002af4:	2505                	addiw	a0,a0,1
    80002af6:	c088                	sw	a0,0(s1)
  update_perfs(ticks);
    80002af8:	2501                	sext.w	a0,a0
    80002afa:	00000097          	auipc	ra,0x0
    80002afe:	e34080e7          	jalr	-460(ra) # 8000292e <update_perfs>
  wakeup(&ticks);
    80002b02:	8526                	mv	a0,s1
    80002b04:	00000097          	auipc	ra,0x0
    80002b08:	826080e7          	jalr	-2010(ra) # 8000232a <wakeup>
  release(&tickslock);
    80002b0c:	854a                	mv	a0,s2
    80002b0e:	ffffe097          	auipc	ra,0xffffe
    80002b12:	168080e7          	jalr	360(ra) # 80000c76 <release>
}
    80002b16:	60e2                	ld	ra,24(sp)
    80002b18:	6442                	ld	s0,16(sp)
    80002b1a:	64a2                	ld	s1,8(sp)
    80002b1c:	6902                	ld	s2,0(sp)
    80002b1e:	6105                	addi	sp,sp,32
    80002b20:	8082                	ret

0000000080002b22 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b22:	1101                	addi	sp,sp,-32
    80002b24:	ec06                	sd	ra,24(sp)
    80002b26:	e822                	sd	s0,16(sp)
    80002b28:	e426                	sd	s1,8(sp)
    80002b2a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b2c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b30:	00074d63          	bltz	a4,80002b4a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b34:	57fd                	li	a5,-1
    80002b36:	17fe                	slli	a5,a5,0x3f
    80002b38:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b3a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b3c:	06f70363          	beq	a4,a5,80002ba2 <devintr+0x80>
  }
}
    80002b40:	60e2                	ld	ra,24(sp)
    80002b42:	6442                	ld	s0,16(sp)
    80002b44:	64a2                	ld	s1,8(sp)
    80002b46:	6105                	addi	sp,sp,32
    80002b48:	8082                	ret
     (scause & 0xff) == 9){
    80002b4a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b4e:	46a5                	li	a3,9
    80002b50:	fed792e3          	bne	a5,a3,80002b34 <devintr+0x12>
    int irq = plic_claim();
    80002b54:	00003097          	auipc	ra,0x3
    80002b58:	5b4080e7          	jalr	1460(ra) # 80006108 <plic_claim>
    80002b5c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b5e:	47a9                	li	a5,10
    80002b60:	02f50763          	beq	a0,a5,80002b8e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b64:	4785                	li	a5,1
    80002b66:	02f50963          	beq	a0,a5,80002b98 <devintr+0x76>
    return 1;
    80002b6a:	4505                	li	a0,1
    } else if(irq){
    80002b6c:	d8f1                	beqz	s1,80002b40 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b6e:	85a6                	mv	a1,s1
    80002b70:	00005517          	auipc	a0,0x5
    80002b74:	77050513          	addi	a0,a0,1904 # 800082e0 <states.0+0x38>
    80002b78:	ffffe097          	auipc	ra,0xffffe
    80002b7c:	9fc080e7          	jalr	-1540(ra) # 80000574 <printf>
      plic_complete(irq);
    80002b80:	8526                	mv	a0,s1
    80002b82:	00003097          	auipc	ra,0x3
    80002b86:	5aa080e7          	jalr	1450(ra) # 8000612c <plic_complete>
    return 1;
    80002b8a:	4505                	li	a0,1
    80002b8c:	bf55                	j	80002b40 <devintr+0x1e>
      uartintr();
    80002b8e:	ffffe097          	auipc	ra,0xffffe
    80002b92:	df8080e7          	jalr	-520(ra) # 80000986 <uartintr>
    80002b96:	b7ed                	j	80002b80 <devintr+0x5e>
      virtio_disk_intr();
    80002b98:	00004097          	auipc	ra,0x4
    80002b9c:	a26080e7          	jalr	-1498(ra) # 800065be <virtio_disk_intr>
    80002ba0:	b7c5                	j	80002b80 <devintr+0x5e>
    if(cpuid() == 0){
    80002ba2:	fffff097          	auipc	ra,0xfffff
    80002ba6:	db0080e7          	jalr	-592(ra) # 80001952 <cpuid>
    80002baa:	c901                	beqz	a0,80002bba <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002bac:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002bb2:	14479073          	csrw	sip,a5
    return 2;
    80002bb6:	4509                	li	a0,2
    80002bb8:	b761                	j	80002b40 <devintr+0x1e>
      clockintr();
    80002bba:	00000097          	auipc	ra,0x0
    80002bbe:	f12080e7          	jalr	-238(ra) # 80002acc <clockintr>
    80002bc2:	b7ed                	j	80002bac <devintr+0x8a>

0000000080002bc4 <usertrap>:
{
    80002bc4:	1101                	addi	sp,sp,-32
    80002bc6:	ec06                	sd	ra,24(sp)
    80002bc8:	e822                	sd	s0,16(sp)
    80002bca:	e426                	sd	s1,8(sp)
    80002bcc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bce:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002bd2:	1007f793          	andi	a5,a5,256
    80002bd6:	e3a5                	bnez	a5,80002c36 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bd8:	00003797          	auipc	a5,0x3
    80002bdc:	42878793          	addi	a5,a5,1064 # 80006000 <kernelvec>
    80002be0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	d9a080e7          	jalr	-614(ra) # 8000197e <myproc>
    80002bec:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bee:	793c                	ld	a5,112(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bf0:	14102773          	csrr	a4,sepc
    80002bf4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bf6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002bfa:	47a1                	li	a5,8
    80002bfc:	04f71b63          	bne	a4,a5,80002c52 <usertrap+0x8e>
    if(p->killed)
    80002c00:	551c                	lw	a5,40(a0)
    80002c02:	e3b1                	bnez	a5,80002c46 <usertrap+0x82>
    p->trapframe->epc += 4;
    80002c04:	78b8                	ld	a4,112(s1)
    80002c06:	6f1c                	ld	a5,24(a4)
    80002c08:	0791                	addi	a5,a5,4
    80002c0a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c0c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c10:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c14:	10079073          	csrw	sstatus,a5
    syscall();
    80002c18:	00000097          	auipc	ra,0x0
    80002c1c:	366080e7          	jalr	870(ra) # 80002f7e <syscall>
  if(p->killed)
    80002c20:	549c                	lw	a5,40(s1)
    80002c22:	e7b5                	bnez	a5,80002c8e <usertrap+0xca>
  usertrapret();
    80002c24:	00000097          	auipc	ra,0x0
    80002c28:	e0a080e7          	jalr	-502(ra) # 80002a2e <usertrapret>
}
    80002c2c:	60e2                	ld	ra,24(sp)
    80002c2e:	6442                	ld	s0,16(sp)
    80002c30:	64a2                	ld	s1,8(sp)
    80002c32:	6105                	addi	sp,sp,32
    80002c34:	8082                	ret
    panic("usertrap: not from user mode");
    80002c36:	00005517          	auipc	a0,0x5
    80002c3a:	6ca50513          	addi	a0,a0,1738 # 80008300 <states.0+0x58>
    80002c3e:	ffffe097          	auipc	ra,0xffffe
    80002c42:	8ec080e7          	jalr	-1812(ra) # 8000052a <panic>
      exit(-1);
    80002c46:	557d                	li	a0,-1
    80002c48:	fffff097          	auipc	ra,0xfffff
    80002c4c:	7b2080e7          	jalr	1970(ra) # 800023fa <exit>
    80002c50:	bf55                	j	80002c04 <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80002c52:	00000097          	auipc	ra,0x0
    80002c56:	ed0080e7          	jalr	-304(ra) # 80002b22 <devintr>
    80002c5a:	f179                	bnez	a0,80002c20 <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c5c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c60:	5890                	lw	a2,48(s1)
    80002c62:	00005517          	auipc	a0,0x5
    80002c66:	6be50513          	addi	a0,a0,1726 # 80008320 <states.0+0x78>
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	90a080e7          	jalr	-1782(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c72:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c76:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c7a:	00005517          	auipc	a0,0x5
    80002c7e:	6d650513          	addi	a0,a0,1750 # 80008350 <states.0+0xa8>
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	8f2080e7          	jalr	-1806(ra) # 80000574 <printf>
    p->killed = 1;
    80002c8a:	4785                	li	a5,1
    80002c8c:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002c8e:	557d                	li	a0,-1
    80002c90:	fffff097          	auipc	ra,0xfffff
    80002c94:	76a080e7          	jalr	1898(ra) # 800023fa <exit>
    80002c98:	b771                	j	80002c24 <usertrap+0x60>

0000000080002c9a <kerneltrap>:
{
    80002c9a:	7179                	addi	sp,sp,-48
    80002c9c:	f406                	sd	ra,40(sp)
    80002c9e:	f022                	sd	s0,32(sp)
    80002ca0:	ec26                	sd	s1,24(sp)
    80002ca2:	e84a                	sd	s2,16(sp)
    80002ca4:	e44e                	sd	s3,8(sp)
    80002ca6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ca8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cac:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cb0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002cb4:	1004f793          	andi	a5,s1,256
    80002cb8:	c78d                	beqz	a5,80002ce2 <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cba:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002cbe:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002cc0:	eb8d                	bnez	a5,80002cf2 <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    80002cc2:	00000097          	auipc	ra,0x0
    80002cc6:	e60080e7          	jalr	-416(ra) # 80002b22 <devintr>
    80002cca:	cd05                	beqz	a0,80002d02 <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ccc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cd0:	10049073          	csrw	sstatus,s1
}
    80002cd4:	70a2                	ld	ra,40(sp)
    80002cd6:	7402                	ld	s0,32(sp)
    80002cd8:	64e2                	ld	s1,24(sp)
    80002cda:	6942                	ld	s2,16(sp)
    80002cdc:	69a2                	ld	s3,8(sp)
    80002cde:	6145                	addi	sp,sp,48
    80002ce0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ce2:	00005517          	auipc	a0,0x5
    80002ce6:	68e50513          	addi	a0,a0,1678 # 80008370 <states.0+0xc8>
    80002cea:	ffffe097          	auipc	ra,0xffffe
    80002cee:	840080e7          	jalr	-1984(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002cf2:	00005517          	auipc	a0,0x5
    80002cf6:	6a650513          	addi	a0,a0,1702 # 80008398 <states.0+0xf0>
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	830080e7          	jalr	-2000(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002d02:	85ce                	mv	a1,s3
    80002d04:	00005517          	auipc	a0,0x5
    80002d08:	6b450513          	addi	a0,a0,1716 # 800083b8 <states.0+0x110>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	868080e7          	jalr	-1944(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d14:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d18:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d1c:	00005517          	auipc	a0,0x5
    80002d20:	6ac50513          	addi	a0,a0,1708 # 800083c8 <states.0+0x120>
    80002d24:	ffffe097          	auipc	ra,0xffffe
    80002d28:	850080e7          	jalr	-1968(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002d2c:	00005517          	auipc	a0,0x5
    80002d30:	6b450513          	addi	a0,a0,1716 # 800083e0 <states.0+0x138>
    80002d34:	ffffd097          	auipc	ra,0xffffd
    80002d38:	7f6080e7          	jalr	2038(ra) # 8000052a <panic>

0000000080002d3c <argraw>:
	return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d3c:	1101                	addi	sp,sp,-32
    80002d3e:	ec06                	sd	ra,24(sp)
    80002d40:	e822                	sd	s0,16(sp)
    80002d42:	e426                	sd	s1,8(sp)
    80002d44:	1000                	addi	s0,sp,32
    80002d46:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    80002d48:	fffff097          	auipc	ra,0xfffff
    80002d4c:	c36080e7          	jalr	-970(ra) # 8000197e <myproc>
	switch (n)
    80002d50:	4795                	li	a5,5
    80002d52:	0497e163          	bltu	a5,s1,80002d94 <argraw+0x58>
    80002d56:	048a                	slli	s1,s1,0x2
    80002d58:	00005717          	auipc	a4,0x5
    80002d5c:	7d870713          	addi	a4,a4,2008 # 80008530 <states.0+0x288>
    80002d60:	94ba                	add	s1,s1,a4
    80002d62:	409c                	lw	a5,0(s1)
    80002d64:	97ba                	add	a5,a5,a4
    80002d66:	8782                	jr	a5
	{
	case 0:
		return p->trapframe->a0;
    80002d68:	793c                	ld	a5,112(a0)
    80002d6a:	7ba8                	ld	a0,112(a5)
	case 5:
		return p->trapframe->a5;
	}
	panic("argraw");
	return -1;
}
    80002d6c:	60e2                	ld	ra,24(sp)
    80002d6e:	6442                	ld	s0,16(sp)
    80002d70:	64a2                	ld	s1,8(sp)
    80002d72:	6105                	addi	sp,sp,32
    80002d74:	8082                	ret
		return p->trapframe->a1;
    80002d76:	793c                	ld	a5,112(a0)
    80002d78:	7fa8                	ld	a0,120(a5)
    80002d7a:	bfcd                	j	80002d6c <argraw+0x30>
		return p->trapframe->a2;
    80002d7c:	793c                	ld	a5,112(a0)
    80002d7e:	63c8                	ld	a0,128(a5)
    80002d80:	b7f5                	j	80002d6c <argraw+0x30>
		return p->trapframe->a3;
    80002d82:	793c                	ld	a5,112(a0)
    80002d84:	67c8                	ld	a0,136(a5)
    80002d86:	b7dd                	j	80002d6c <argraw+0x30>
		return p->trapframe->a4;
    80002d88:	793c                	ld	a5,112(a0)
    80002d8a:	6bc8                	ld	a0,144(a5)
    80002d8c:	b7c5                	j	80002d6c <argraw+0x30>
		return p->trapframe->a5;
    80002d8e:	793c                	ld	a5,112(a0)
    80002d90:	6fc8                	ld	a0,152(a5)
    80002d92:	bfe9                	j	80002d6c <argraw+0x30>
	panic("argraw");
    80002d94:	00005517          	auipc	a0,0x5
    80002d98:	65c50513          	addi	a0,a0,1628 # 800083f0 <states.0+0x148>
    80002d9c:	ffffd097          	auipc	ra,0xffffd
    80002da0:	78e080e7          	jalr	1934(ra) # 8000052a <panic>

0000000080002da4 <fetchaddr>:
{
    80002da4:	1101                	addi	sp,sp,-32
    80002da6:	ec06                	sd	ra,24(sp)
    80002da8:	e822                	sd	s0,16(sp)
    80002daa:	e426                	sd	s1,8(sp)
    80002dac:	e04a                	sd	s2,0(sp)
    80002dae:	1000                	addi	s0,sp,32
    80002db0:	84aa                	mv	s1,a0
    80002db2:	892e                	mv	s2,a1
	struct proc *p = myproc();
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	bca080e7          	jalr	-1078(ra) # 8000197e <myproc>
	if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002dbc:	713c                	ld	a5,96(a0)
    80002dbe:	02f4f863          	bgeu	s1,a5,80002dee <fetchaddr+0x4a>
    80002dc2:	00848713          	addi	a4,s1,8
    80002dc6:	02e7e663          	bltu	a5,a4,80002df2 <fetchaddr+0x4e>
	if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002dca:	46a1                	li	a3,8
    80002dcc:	8626                	mv	a2,s1
    80002dce:	85ca                	mv	a1,s2
    80002dd0:	7528                	ld	a0,104(a0)
    80002dd2:	fffff097          	auipc	ra,0xfffff
    80002dd6:	8f8080e7          	jalr	-1800(ra) # 800016ca <copyin>
    80002dda:	00a03533          	snez	a0,a0
    80002dde:	40a00533          	neg	a0,a0
}
    80002de2:	60e2                	ld	ra,24(sp)
    80002de4:	6442                	ld	s0,16(sp)
    80002de6:	64a2                	ld	s1,8(sp)
    80002de8:	6902                	ld	s2,0(sp)
    80002dea:	6105                	addi	sp,sp,32
    80002dec:	8082                	ret
		return -1;
    80002dee:	557d                	li	a0,-1
    80002df0:	bfcd                	j	80002de2 <fetchaddr+0x3e>
    80002df2:	557d                	li	a0,-1
    80002df4:	b7fd                	j	80002de2 <fetchaddr+0x3e>

0000000080002df6 <fetchstr>:
{
    80002df6:	7179                	addi	sp,sp,-48
    80002df8:	f406                	sd	ra,40(sp)
    80002dfa:	f022                	sd	s0,32(sp)
    80002dfc:	ec26                	sd	s1,24(sp)
    80002dfe:	e84a                	sd	s2,16(sp)
    80002e00:	e44e                	sd	s3,8(sp)
    80002e02:	1800                	addi	s0,sp,48
    80002e04:	892a                	mv	s2,a0
    80002e06:	84ae                	mv	s1,a1
    80002e08:	89b2                	mv	s3,a2
	struct proc *p = myproc();
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	b74080e7          	jalr	-1164(ra) # 8000197e <myproc>
	int err = copyinstr(p->pagetable, buf, addr, max);
    80002e12:	86ce                	mv	a3,s3
    80002e14:	864a                	mv	a2,s2
    80002e16:	85a6                	mv	a1,s1
    80002e18:	7528                	ld	a0,104(a0)
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	93e080e7          	jalr	-1730(ra) # 80001758 <copyinstr>
	if (err < 0)
    80002e22:	00054763          	bltz	a0,80002e30 <fetchstr+0x3a>
	return strlen(buf);
    80002e26:	8526                	mv	a0,s1
    80002e28:	ffffe097          	auipc	ra,0xffffe
    80002e2c:	01a080e7          	jalr	26(ra) # 80000e42 <strlen>
}
    80002e30:	70a2                	ld	ra,40(sp)
    80002e32:	7402                	ld	s0,32(sp)
    80002e34:	64e2                	ld	s1,24(sp)
    80002e36:	6942                	ld	s2,16(sp)
    80002e38:	69a2                	ld	s3,8(sp)
    80002e3a:	6145                	addi	sp,sp,48
    80002e3c:	8082                	ret

0000000080002e3e <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002e3e:	1101                	addi	sp,sp,-32
    80002e40:	ec06                	sd	ra,24(sp)
    80002e42:	e822                	sd	s0,16(sp)
    80002e44:	e426                	sd	s1,8(sp)
    80002e46:	1000                	addi	s0,sp,32
    80002e48:	84ae                	mv	s1,a1
	*ip = argraw(n);
    80002e4a:	00000097          	auipc	ra,0x0
    80002e4e:	ef2080e7          	jalr	-270(ra) # 80002d3c <argraw>
    80002e52:	c088                	sw	a0,0(s1)
	return 0;
}
    80002e54:	4501                	li	a0,0
    80002e56:	60e2                	ld	ra,24(sp)
    80002e58:	6442                	ld	s0,16(sp)
    80002e5a:	64a2                	ld	s1,8(sp)
    80002e5c:	6105                	addi	sp,sp,32
    80002e5e:	8082                	ret

0000000080002e60 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002e60:	1101                	addi	sp,sp,-32
    80002e62:	ec06                	sd	ra,24(sp)
    80002e64:	e822                	sd	s0,16(sp)
    80002e66:	e426                	sd	s1,8(sp)
    80002e68:	1000                	addi	s0,sp,32
    80002e6a:	84ae                	mv	s1,a1
	*ip = argraw(n);
    80002e6c:	00000097          	auipc	ra,0x0
    80002e70:	ed0080e7          	jalr	-304(ra) # 80002d3c <argraw>
    80002e74:	e088                	sd	a0,0(s1)
	return 0;
}
    80002e76:	4501                	li	a0,0
    80002e78:	60e2                	ld	ra,24(sp)
    80002e7a:	6442                	ld	s0,16(sp)
    80002e7c:	64a2                	ld	s1,8(sp)
    80002e7e:	6105                	addi	sp,sp,32
    80002e80:	8082                	ret

0000000080002e82 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002e82:	1101                	addi	sp,sp,-32
    80002e84:	ec06                	sd	ra,24(sp)
    80002e86:	e822                	sd	s0,16(sp)
    80002e88:	e426                	sd	s1,8(sp)
    80002e8a:	e04a                	sd	s2,0(sp)
    80002e8c:	1000                	addi	s0,sp,32
    80002e8e:	84ae                	mv	s1,a1
    80002e90:	8932                	mv	s2,a2
	*ip = argraw(n);
    80002e92:	00000097          	auipc	ra,0x0
    80002e96:	eaa080e7          	jalr	-342(ra) # 80002d3c <argraw>
	uint64 addr;
	if (argaddr(n, &addr) < 0)
		return -1;
	return fetchstr(addr, buf, max);
    80002e9a:	864a                	mv	a2,s2
    80002e9c:	85a6                	mv	a1,s1
    80002e9e:	00000097          	auipc	ra,0x0
    80002ea2:	f58080e7          	jalr	-168(ra) # 80002df6 <fetchstr>
}
    80002ea6:	60e2                	ld	ra,24(sp)
    80002ea8:	6442                	ld	s0,16(sp)
    80002eaa:	64a2                	ld	s1,8(sp)
    80002eac:	6902                	ld	s2,0(sp)
    80002eae:	6105                	addi	sp,sp,32
    80002eb0:	8082                	ret

0000000080002eb2 <print_trace>:
	}
}

// ADDED
void print_trace(int arg)
{
    80002eb2:	7179                	addi	sp,sp,-48
    80002eb4:	f406                	sd	ra,40(sp)
    80002eb6:	f022                	sd	s0,32(sp)
    80002eb8:	ec26                	sd	s1,24(sp)
    80002eba:	e84a                	sd	s2,16(sp)
    80002ebc:	e44e                	sd	s3,8(sp)
    80002ebe:	1800                	addi	s0,sp,48
    80002ec0:	89aa                	mv	s3,a0
	int num;
	struct proc *p = myproc();
    80002ec2:	fffff097          	auipc	ra,0xfffff
    80002ec6:	abc080e7          	jalr	-1348(ra) # 8000197e <myproc>
	num = p->trapframe->a7;
    80002eca:	793c                	ld	a5,112(a0)
    80002ecc:	0a87a903          	lw	s2,168(a5)

	int res = (1 << num) & p->trace_mask;
    80002ed0:	4785                	li	a5,1
    80002ed2:	012797bb          	sllw	a5,a5,s2
    80002ed6:	5958                	lw	a4,52(a0)
    80002ed8:	8ff9                	and	a5,a5,a4
	if (res != 0)
    80002eda:	2781                	sext.w	a5,a5
    80002edc:	eb81                	bnez	a5,80002eec <print_trace+0x3a>
		else
		{
			printf("syscall %s  -> %d\n", syscallnames[num], p->trapframe->a0);
		}
	}
} // ADDED
    80002ede:	70a2                	ld	ra,40(sp)
    80002ee0:	7402                	ld	s0,32(sp)
    80002ee2:	64e2                	ld	s1,24(sp)
    80002ee4:	6942                	ld	s2,16(sp)
    80002ee6:	69a2                	ld	s3,8(sp)
    80002ee8:	6145                	addi	sp,sp,48
    80002eea:	8082                	ret
    80002eec:	84aa                	mv	s1,a0
		printf("%d: ", p->pid);
    80002eee:	590c                	lw	a1,48(a0)
    80002ef0:	00005517          	auipc	a0,0x5
    80002ef4:	50850513          	addi	a0,a0,1288 # 800083f8 <states.0+0x150>
    80002ef8:	ffffd097          	auipc	ra,0xffffd
    80002efc:	67c080e7          	jalr	1660(ra) # 80000574 <printf>
		if (num == SYS_fork)
    80002f00:	4785                	li	a5,1
    80002f02:	02f90c63          	beq	s2,a5,80002f3a <print_trace+0x88>
		else if (num == SYS_kill || num == SYS_sbrk)
    80002f06:	4799                	li	a5,6
    80002f08:	00f90563          	beq	s2,a5,80002f12 <print_trace+0x60>
    80002f0c:	47b1                	li	a5,12
    80002f0e:	04f91563          	bne	s2,a5,80002f58 <print_trace+0xa6>
			printf("syscall %s %d -> %d\n", syscallnames[num], arg, p->trapframe->a0);
    80002f12:	78b8                	ld	a4,112(s1)
    80002f14:	090e                	slli	s2,s2,0x3
    80002f16:	00005797          	auipc	a5,0x5
    80002f1a:	63278793          	addi	a5,a5,1586 # 80008548 <syscallnames>
    80002f1e:	993e                	add	s2,s2,a5
    80002f20:	7b34                	ld	a3,112(a4)
    80002f22:	864e                	mv	a2,s3
    80002f24:	00093583          	ld	a1,0(s2)
    80002f28:	00005517          	auipc	a0,0x5
    80002f2c:	4f850513          	addi	a0,a0,1272 # 80008420 <states.0+0x178>
    80002f30:	ffffd097          	auipc	ra,0xffffd
    80002f34:	644080e7          	jalr	1604(ra) # 80000574 <printf>
    80002f38:	b75d                	j	80002ede <print_trace+0x2c>
			printf("syscall %s NULL -> %d\n", syscallnames[num], p->trapframe->a0);
    80002f3a:	78bc                	ld	a5,112(s1)
    80002f3c:	7bb0                	ld	a2,112(a5)
    80002f3e:	00005597          	auipc	a1,0x5
    80002f42:	4c258593          	addi	a1,a1,1218 # 80008400 <states.0+0x158>
    80002f46:	00005517          	auipc	a0,0x5
    80002f4a:	4c250513          	addi	a0,a0,1218 # 80008408 <states.0+0x160>
    80002f4e:	ffffd097          	auipc	ra,0xffffd
    80002f52:	626080e7          	jalr	1574(ra) # 80000574 <printf>
    80002f56:	b761                	j	80002ede <print_trace+0x2c>
			printf("syscall %s  -> %d\n", syscallnames[num], p->trapframe->a0);
    80002f58:	78b8                	ld	a4,112(s1)
    80002f5a:	090e                	slli	s2,s2,0x3
    80002f5c:	00005797          	auipc	a5,0x5
    80002f60:	5ec78793          	addi	a5,a5,1516 # 80008548 <syscallnames>
    80002f64:	993e                	add	s2,s2,a5
    80002f66:	7b30                	ld	a2,112(a4)
    80002f68:	00093583          	ld	a1,0(s2)
    80002f6c:	00005517          	auipc	a0,0x5
    80002f70:	4cc50513          	addi	a0,a0,1228 # 80008438 <states.0+0x190>
    80002f74:	ffffd097          	auipc	ra,0xffffd
    80002f78:	600080e7          	jalr	1536(ra) # 80000574 <printf>
} // ADDED
    80002f7c:	b78d                	j	80002ede <print_trace+0x2c>

0000000080002f7e <syscall>:
{
    80002f7e:	7179                	addi	sp,sp,-48
    80002f80:	f406                	sd	ra,40(sp)
    80002f82:	f022                	sd	s0,32(sp)
    80002f84:	ec26                	sd	s1,24(sp)
    80002f86:	e84a                	sd	s2,16(sp)
    80002f88:	1800                	addi	s0,sp,48
	struct proc *p = myproc();
    80002f8a:	fffff097          	auipc	ra,0xfffff
    80002f8e:	9f4080e7          	jalr	-1548(ra) # 8000197e <myproc>
    80002f92:	84aa                	mv	s1,a0
	num = p->trapframe->a7;
    80002f94:	793c                	ld	a5,112(a0)
    80002f96:	77dc                	ld	a5,168(a5)
    80002f98:	0007869b          	sext.w	a3,a5
	if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002f9c:	37fd                	addiw	a5,a5,-1
    80002f9e:	475d                	li	a4,23
    80002fa0:	02f76e63          	bltu	a4,a5,80002fdc <syscall+0x5e>
    80002fa4:	00369713          	slli	a4,a3,0x3
    80002fa8:	00005797          	auipc	a5,0x5
    80002fac:	5a078793          	addi	a5,a5,1440 # 80008548 <syscallnames>
    80002fb0:	97ba                	add	a5,a5,a4
    80002fb2:	0c87b903          	ld	s2,200(a5)
    80002fb6:	02090363          	beqz	s2,80002fdc <syscall+0x5e>
		argint(0, &arg); // ADDED
    80002fba:	fdc40593          	addi	a1,s0,-36
    80002fbe:	4501                	li	a0,0
    80002fc0:	00000097          	auipc	ra,0x0
    80002fc4:	e7e080e7          	jalr	-386(ra) # 80002e3e <argint>
		p->trapframe->a0 = syscalls[num]();
    80002fc8:	78a4                	ld	s1,112(s1)
    80002fca:	9902                	jalr	s2
    80002fcc:	f8a8                	sd	a0,112(s1)
		print_trace(arg); // ADDED
    80002fce:	fdc42503          	lw	a0,-36(s0)
    80002fd2:	00000097          	auipc	ra,0x0
    80002fd6:	ee0080e7          	jalr	-288(ra) # 80002eb2 <print_trace>
    80002fda:	a839                	j	80002ff8 <syscall+0x7a>
		printf("%d %s: unknown sys call %d\n",
    80002fdc:	17048613          	addi	a2,s1,368
    80002fe0:	588c                	lw	a1,48(s1)
    80002fe2:	00005517          	auipc	a0,0x5
    80002fe6:	46e50513          	addi	a0,a0,1134 # 80008450 <states.0+0x1a8>
    80002fea:	ffffd097          	auipc	ra,0xffffd
    80002fee:	58a080e7          	jalr	1418(ra) # 80000574 <printf>
		p->trapframe->a0 = -1;
    80002ff2:	78bc                	ld	a5,112(s1)
    80002ff4:	577d                	li	a4,-1
    80002ff6:	fbb8                	sd	a4,112(a5)
}
    80002ff8:	70a2                	ld	ra,40(sp)
    80002ffa:	7402                	ld	s0,32(sp)
    80002ffc:	64e2                	ld	s1,24(sp)
    80002ffe:	6942                	ld	s2,16(sp)
    80003000:	6145                	addi	sp,sp,48
    80003002:	8082                	ret

0000000080003004 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003004:	1101                	addi	sp,sp,-32
    80003006:	ec06                	sd	ra,24(sp)
    80003008:	e822                	sd	s0,16(sp)
    8000300a:	1000                	addi	s0,sp,32
  int n;
  if (argint(0, &n) < 0)
    8000300c:	fec40593          	addi	a1,s0,-20
    80003010:	4501                	li	a0,0
    80003012:	00000097          	auipc	ra,0x0
    80003016:	e2c080e7          	jalr	-468(ra) # 80002e3e <argint>
    return -1;
    8000301a:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    8000301c:	00054963          	bltz	a0,8000302e <sys_exit+0x2a>
  exit(n);
    80003020:	fec42503          	lw	a0,-20(s0)
    80003024:	fffff097          	auipc	ra,0xfffff
    80003028:	3d6080e7          	jalr	982(ra) # 800023fa <exit>
  return 0; // not reached
    8000302c:	4781                	li	a5,0
}
    8000302e:	853e                	mv	a0,a5
    80003030:	60e2                	ld	ra,24(sp)
    80003032:	6442                	ld	s0,16(sp)
    80003034:	6105                	addi	sp,sp,32
    80003036:	8082                	ret

0000000080003038 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003038:	1141                	addi	sp,sp,-16
    8000303a:	e406                	sd	ra,8(sp)
    8000303c:	e022                	sd	s0,0(sp)
    8000303e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003040:	fffff097          	auipc	ra,0xfffff
    80003044:	93e080e7          	jalr	-1730(ra) # 8000197e <myproc>
}
    80003048:	5908                	lw	a0,48(a0)
    8000304a:	60a2                	ld	ra,8(sp)
    8000304c:	6402                	ld	s0,0(sp)
    8000304e:	0141                	addi	sp,sp,16
    80003050:	8082                	ret

0000000080003052 <sys_fork>:

uint64
sys_fork(void)
{
    80003052:	1141                	addi	sp,sp,-16
    80003054:	e406                	sd	ra,8(sp)
    80003056:	e022                	sd	s0,0(sp)
    80003058:	0800                	addi	s0,sp,16
  return fork();
    8000305a:	fffff097          	auipc	ra,0xfffff
    8000305e:	d00080e7          	jalr	-768(ra) # 80001d5a <fork>
}
    80003062:	60a2                	ld	ra,8(sp)
    80003064:	6402                	ld	s0,0(sp)
    80003066:	0141                	addi	sp,sp,16
    80003068:	8082                	ret

000000008000306a <sys_wait>:

uint64
sys_wait(void)
{
    8000306a:	1101                	addi	sp,sp,-32
    8000306c:	ec06                	sd	ra,24(sp)
    8000306e:	e822                	sd	s0,16(sp)
    80003070:	1000                	addi	s0,sp,32
  uint64 p;
  if (argaddr(0, &p) < 0)
    80003072:	fe840593          	addi	a1,s0,-24
    80003076:	4501                	li	a0,0
    80003078:	00000097          	auipc	ra,0x0
    8000307c:	de8080e7          	jalr	-536(ra) # 80002e60 <argaddr>
    80003080:	87aa                	mv	a5,a0
    return -1;
    80003082:	557d                	li	a0,-1
  if (argaddr(0, &p) < 0)
    80003084:	0007c863          	bltz	a5,80003094 <sys_wait+0x2a>
  return wait(p);
    80003088:	fe843503          	ld	a0,-24(s0)
    8000308c:	fffff097          	auipc	ra,0xfffff
    80003090:	176080e7          	jalr	374(ra) # 80002202 <wait>
}
    80003094:	60e2                	ld	ra,24(sp)
    80003096:	6442                	ld	s0,16(sp)
    80003098:	6105                	addi	sp,sp,32
    8000309a:	8082                	ret

000000008000309c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000309c:	7179                	addi	sp,sp,-48
    8000309e:	f406                	sd	ra,40(sp)
    800030a0:	f022                	sd	s0,32(sp)
    800030a2:	ec26                	sd	s1,24(sp)
    800030a4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if (argint(0, &n) < 0)
    800030a6:	fdc40593          	addi	a1,s0,-36
    800030aa:	4501                	li	a0,0
    800030ac:	00000097          	auipc	ra,0x0
    800030b0:	d92080e7          	jalr	-622(ra) # 80002e3e <argint>
    return -1;
    800030b4:	54fd                	li	s1,-1
  if (argint(0, &n) < 0)
    800030b6:	00054f63          	bltz	a0,800030d4 <sys_sbrk+0x38>
  addr = myproc()->sz;
    800030ba:	fffff097          	auipc	ra,0xfffff
    800030be:	8c4080e7          	jalr	-1852(ra) # 8000197e <myproc>
    800030c2:	5124                	lw	s1,96(a0)
  if (growproc(n) < 0)
    800030c4:	fdc42503          	lw	a0,-36(s0)
    800030c8:	fffff097          	auipc	ra,0xfffff
    800030cc:	c1e080e7          	jalr	-994(ra) # 80001ce6 <growproc>
    800030d0:	00054863          	bltz	a0,800030e0 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    800030d4:	8526                	mv	a0,s1
    800030d6:	70a2                	ld	ra,40(sp)
    800030d8:	7402                	ld	s0,32(sp)
    800030da:	64e2                	ld	s1,24(sp)
    800030dc:	6145                	addi	sp,sp,48
    800030de:	8082                	ret
    return -1;
    800030e0:	54fd                	li	s1,-1
    800030e2:	bfcd                	j	800030d4 <sys_sbrk+0x38>

00000000800030e4 <sys_sleep>:

uint64
sys_sleep(void)
{
    800030e4:	7139                	addi	sp,sp,-64
    800030e6:	fc06                	sd	ra,56(sp)
    800030e8:	f822                	sd	s0,48(sp)
    800030ea:	f426                	sd	s1,40(sp)
    800030ec:	f04a                	sd	s2,32(sp)
    800030ee:	ec4e                	sd	s3,24(sp)
    800030f0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if (argint(0, &n) < 0)
    800030f2:	fcc40593          	addi	a1,s0,-52
    800030f6:	4501                	li	a0,0
    800030f8:	00000097          	auipc	ra,0x0
    800030fc:	d46080e7          	jalr	-698(ra) # 80002e3e <argint>
    return -1;
    80003100:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80003102:	06054563          	bltz	a0,8000316c <sys_sleep+0x88>
  acquire(&tickslock);
    80003106:	00014517          	auipc	a0,0x14
    8000310a:	5ca50513          	addi	a0,a0,1482 # 800176d0 <tickslock>
    8000310e:	ffffe097          	auipc	ra,0xffffe
    80003112:	ab4080e7          	jalr	-1356(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80003116:	00006917          	auipc	s2,0x6
    8000311a:	f1a92903          	lw	s2,-230(s2) # 80009030 <ticks>
  while (ticks - ticks0 < n)
    8000311e:	fcc42783          	lw	a5,-52(s0)
    80003122:	cf85                	beqz	a5,8000315a <sys_sleep+0x76>
    if (myproc()->killed)
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003124:	00014997          	auipc	s3,0x14
    80003128:	5ac98993          	addi	s3,s3,1452 # 800176d0 <tickslock>
    8000312c:	00006497          	auipc	s1,0x6
    80003130:	f0448493          	addi	s1,s1,-252 # 80009030 <ticks>
    if (myproc()->killed)
    80003134:	fffff097          	auipc	ra,0xfffff
    80003138:	84a080e7          	jalr	-1974(ra) # 8000197e <myproc>
    8000313c:	551c                	lw	a5,40(a0)
    8000313e:	ef9d                	bnez	a5,8000317c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003140:	85ce                	mv	a1,s3
    80003142:	8526                	mv	a0,s1
    80003144:	fffff097          	auipc	ra,0xfffff
    80003148:	05a080e7          	jalr	90(ra) # 8000219e <sleep>
  while (ticks - ticks0 < n)
    8000314c:	409c                	lw	a5,0(s1)
    8000314e:	412787bb          	subw	a5,a5,s2
    80003152:	fcc42703          	lw	a4,-52(s0)
    80003156:	fce7efe3          	bltu	a5,a4,80003134 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000315a:	00014517          	auipc	a0,0x14
    8000315e:	57650513          	addi	a0,a0,1398 # 800176d0 <tickslock>
    80003162:	ffffe097          	auipc	ra,0xffffe
    80003166:	b14080e7          	jalr	-1260(ra) # 80000c76 <release>
  return 0;
    8000316a:	4781                	li	a5,0
}
    8000316c:	853e                	mv	a0,a5
    8000316e:	70e2                	ld	ra,56(sp)
    80003170:	7442                	ld	s0,48(sp)
    80003172:	74a2                	ld	s1,40(sp)
    80003174:	7902                	ld	s2,32(sp)
    80003176:	69e2                	ld	s3,24(sp)
    80003178:	6121                	addi	sp,sp,64
    8000317a:	8082                	ret
      release(&tickslock);
    8000317c:	00014517          	auipc	a0,0x14
    80003180:	55450513          	addi	a0,a0,1364 # 800176d0 <tickslock>
    80003184:	ffffe097          	auipc	ra,0xffffe
    80003188:	af2080e7          	jalr	-1294(ra) # 80000c76 <release>
      return -1;
    8000318c:	57fd                	li	a5,-1
    8000318e:	bff9                	j	8000316c <sys_sleep+0x88>

0000000080003190 <sys_kill>:

uint64
sys_kill(void)
{
    80003190:	1101                	addi	sp,sp,-32
    80003192:	ec06                	sd	ra,24(sp)
    80003194:	e822                	sd	s0,16(sp)
    80003196:	1000                	addi	s0,sp,32
  int pid;

  if (argint(0, &pid) < 0)
    80003198:	fec40593          	addi	a1,s0,-20
    8000319c:	4501                	li	a0,0
    8000319e:	00000097          	auipc	ra,0x0
    800031a2:	ca0080e7          	jalr	-864(ra) # 80002e3e <argint>
    800031a6:	87aa                	mv	a5,a0
    return -1;
    800031a8:	557d                	li	a0,-1
  if (argint(0, &pid) < 0)
    800031aa:	0007c863          	bltz	a5,800031ba <sys_kill+0x2a>
  return kill(pid);
    800031ae:	fec42503          	lw	a0,-20(s0)
    800031b2:	fffff097          	auipc	ra,0xfffff
    800031b6:	31e080e7          	jalr	798(ra) # 800024d0 <kill>
}
    800031ba:	60e2                	ld	ra,24(sp)
    800031bc:	6442                	ld	s0,16(sp)
    800031be:	6105                	addi	sp,sp,32
    800031c0:	8082                	ret

00000000800031c2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031c2:	1101                	addi	sp,sp,-32
    800031c4:	ec06                	sd	ra,24(sp)
    800031c6:	e822                	sd	s0,16(sp)
    800031c8:	e426                	sd	s1,8(sp)
    800031ca:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031cc:	00014517          	auipc	a0,0x14
    800031d0:	50450513          	addi	a0,a0,1284 # 800176d0 <tickslock>
    800031d4:	ffffe097          	auipc	ra,0xffffe
    800031d8:	9ee080e7          	jalr	-1554(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800031dc:	00006497          	auipc	s1,0x6
    800031e0:	e544a483          	lw	s1,-428(s1) # 80009030 <ticks>
  release(&tickslock);
    800031e4:	00014517          	auipc	a0,0x14
    800031e8:	4ec50513          	addi	a0,a0,1260 # 800176d0 <tickslock>
    800031ec:	ffffe097          	auipc	ra,0xffffe
    800031f0:	a8a080e7          	jalr	-1398(ra) # 80000c76 <release>
  return xticks;
}
    800031f4:	02049513          	slli	a0,s1,0x20
    800031f8:	9101                	srli	a0,a0,0x20
    800031fa:	60e2                	ld	ra,24(sp)
    800031fc:	6442                	ld	s0,16(sp)
    800031fe:	64a2                	ld	s1,8(sp)
    80003200:	6105                	addi	sp,sp,32
    80003202:	8082                	ret

0000000080003204 <sys_trace>:

//ADDED
uint64
sys_trace(void)
{
    80003204:	1101                	addi	sp,sp,-32
    80003206:	ec06                	sd	ra,24(sp)
    80003208:	e822                	sd	s0,16(sp)
    8000320a:	1000                	addi	s0,sp,32
  int mask, pid;
  argint(0, &mask);
    8000320c:	fec40593          	addi	a1,s0,-20
    80003210:	4501                	li	a0,0
    80003212:	00000097          	auipc	ra,0x0
    80003216:	c2c080e7          	jalr	-980(ra) # 80002e3e <argint>
  argint(1, &pid);
    8000321a:	fe840593          	addi	a1,s0,-24
    8000321e:	4505                	li	a0,1
    80003220:	00000097          	auipc	ra,0x0
    80003224:	c1e080e7          	jalr	-994(ra) # 80002e3e <argint>
  trace(mask, pid);
    80003228:	fe842583          	lw	a1,-24(s0)
    8000322c:	fec42503          	lw	a0,-20(s0)
    80003230:	fffff097          	auipc	ra,0xfffff
    80003234:	46e080e7          	jalr	1134(ra) # 8000269e <trace>
  return 0;
}
    80003238:	4501                	li	a0,0
    8000323a:	60e2                	ld	ra,24(sp)
    8000323c:	6442                	ld	s0,16(sp)
    8000323e:	6105                	addi	sp,sp,32
    80003240:	8082                	ret

0000000080003242 <sys_getmsk>:

uint64
sys_getmsk(void)
{
    80003242:	1101                	addi	sp,sp,-32
    80003244:	ec06                	sd	ra,24(sp)
    80003246:	e822                	sd	s0,16(sp)
    80003248:	1000                	addi	s0,sp,32
  int pid;
  argint(0, &pid);
    8000324a:	fec40593          	addi	a1,s0,-20
    8000324e:	4501                	li	a0,0
    80003250:	00000097          	auipc	ra,0x0
    80003254:	bee080e7          	jalr	-1042(ra) # 80002e3e <argint>
  return getmsk(pid);
    80003258:	fec42503          	lw	a0,-20(s0)
    8000325c:	fffff097          	auipc	ra,0xfffff
    80003260:	4ac080e7          	jalr	1196(ra) # 80002708 <getmsk>
}
    80003264:	60e2                	ld	ra,24(sp)
    80003266:	6442                	ld	s0,16(sp)
    80003268:	6105                	addi	sp,sp,32
    8000326a:	8082                	ret

000000008000326c <sys_wait_stat>:

uint64
sys_wait_stat(void)
{
    8000326c:	1101                	addi	sp,sp,-32
    8000326e:	ec06                	sd	ra,24(sp)
    80003270:	e822                	sd	s0,16(sp)
    80003272:	1000                	addi	s0,sp,32
  uint64 status;
  uint64 performance;
  argaddr(0,  &status);
    80003274:	fe840593          	addi	a1,s0,-24
    80003278:	4501                	li	a0,0
    8000327a:	00000097          	auipc	ra,0x0
    8000327e:	be6080e7          	jalr	-1050(ra) # 80002e60 <argaddr>
  argaddr(1,  &performance);
    80003282:	fe040593          	addi	a1,s0,-32
    80003286:	4505                	li	a0,1
    80003288:	00000097          	auipc	ra,0x0
    8000328c:	bd8080e7          	jalr	-1064(ra) # 80002e60 <argaddr>
  return wait_stat(status, performance);
    80003290:	fe043583          	ld	a1,-32(s0)
    80003294:	fe843503          	ld	a0,-24(s0)
    80003298:	fffff097          	auipc	ra,0xfffff
    8000329c:	520080e7          	jalr	1312(ra) # 800027b8 <wait_stat>
}
    800032a0:	60e2                	ld	ra,24(sp)
    800032a2:	6442                	ld	s0,16(sp)
    800032a4:	6105                	addi	sp,sp,32
    800032a6:	8082                	ret

00000000800032a8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800032a8:	7179                	addi	sp,sp,-48
    800032aa:	f406                	sd	ra,40(sp)
    800032ac:	f022                	sd	s0,32(sp)
    800032ae:	ec26                	sd	s1,24(sp)
    800032b0:	e84a                	sd	s2,16(sp)
    800032b2:	e44e                	sd	s3,8(sp)
    800032b4:	e052                	sd	s4,0(sp)
    800032b6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800032b8:	00005597          	auipc	a1,0x5
    800032bc:	42058593          	addi	a1,a1,1056 # 800086d8 <syscalls+0xc8>
    800032c0:	00014517          	auipc	a0,0x14
    800032c4:	42850513          	addi	a0,a0,1064 # 800176e8 <bcache>
    800032c8:	ffffe097          	auipc	ra,0xffffe
    800032cc:	86a080e7          	jalr	-1942(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800032d0:	0001c797          	auipc	a5,0x1c
    800032d4:	41878793          	addi	a5,a5,1048 # 8001f6e8 <bcache+0x8000>
    800032d8:	0001c717          	auipc	a4,0x1c
    800032dc:	67870713          	addi	a4,a4,1656 # 8001f950 <bcache+0x8268>
    800032e0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800032e4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032e8:	00014497          	auipc	s1,0x14
    800032ec:	41848493          	addi	s1,s1,1048 # 80017700 <bcache+0x18>
    b->next = bcache.head.next;
    800032f0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800032f2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800032f4:	00005a17          	auipc	s4,0x5
    800032f8:	3eca0a13          	addi	s4,s4,1004 # 800086e0 <syscalls+0xd0>
    b->next = bcache.head.next;
    800032fc:	2b893783          	ld	a5,696(s2)
    80003300:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003302:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003306:	85d2                	mv	a1,s4
    80003308:	01048513          	addi	a0,s1,16
    8000330c:	00001097          	auipc	ra,0x1
    80003310:	4c2080e7          	jalr	1218(ra) # 800047ce <initsleeplock>
    bcache.head.next->prev = b;
    80003314:	2b893783          	ld	a5,696(s2)
    80003318:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000331a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000331e:	45848493          	addi	s1,s1,1112
    80003322:	fd349de3          	bne	s1,s3,800032fc <binit+0x54>
  }
}
    80003326:	70a2                	ld	ra,40(sp)
    80003328:	7402                	ld	s0,32(sp)
    8000332a:	64e2                	ld	s1,24(sp)
    8000332c:	6942                	ld	s2,16(sp)
    8000332e:	69a2                	ld	s3,8(sp)
    80003330:	6a02                	ld	s4,0(sp)
    80003332:	6145                	addi	sp,sp,48
    80003334:	8082                	ret

0000000080003336 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003336:	7179                	addi	sp,sp,-48
    80003338:	f406                	sd	ra,40(sp)
    8000333a:	f022                	sd	s0,32(sp)
    8000333c:	ec26                	sd	s1,24(sp)
    8000333e:	e84a                	sd	s2,16(sp)
    80003340:	e44e                	sd	s3,8(sp)
    80003342:	1800                	addi	s0,sp,48
    80003344:	892a                	mv	s2,a0
    80003346:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003348:	00014517          	auipc	a0,0x14
    8000334c:	3a050513          	addi	a0,a0,928 # 800176e8 <bcache>
    80003350:	ffffe097          	auipc	ra,0xffffe
    80003354:	872080e7          	jalr	-1934(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003358:	0001c497          	auipc	s1,0x1c
    8000335c:	6484b483          	ld	s1,1608(s1) # 8001f9a0 <bcache+0x82b8>
    80003360:	0001c797          	auipc	a5,0x1c
    80003364:	5f078793          	addi	a5,a5,1520 # 8001f950 <bcache+0x8268>
    80003368:	02f48f63          	beq	s1,a5,800033a6 <bread+0x70>
    8000336c:	873e                	mv	a4,a5
    8000336e:	a021                	j	80003376 <bread+0x40>
    80003370:	68a4                	ld	s1,80(s1)
    80003372:	02e48a63          	beq	s1,a4,800033a6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003376:	449c                	lw	a5,8(s1)
    80003378:	ff279ce3          	bne	a5,s2,80003370 <bread+0x3a>
    8000337c:	44dc                	lw	a5,12(s1)
    8000337e:	ff3799e3          	bne	a5,s3,80003370 <bread+0x3a>
      b->refcnt++;
    80003382:	40bc                	lw	a5,64(s1)
    80003384:	2785                	addiw	a5,a5,1
    80003386:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003388:	00014517          	auipc	a0,0x14
    8000338c:	36050513          	addi	a0,a0,864 # 800176e8 <bcache>
    80003390:	ffffe097          	auipc	ra,0xffffe
    80003394:	8e6080e7          	jalr	-1818(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003398:	01048513          	addi	a0,s1,16
    8000339c:	00001097          	auipc	ra,0x1
    800033a0:	46c080e7          	jalr	1132(ra) # 80004808 <acquiresleep>
      return b;
    800033a4:	a8b9                	j	80003402 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033a6:	0001c497          	auipc	s1,0x1c
    800033aa:	5f24b483          	ld	s1,1522(s1) # 8001f998 <bcache+0x82b0>
    800033ae:	0001c797          	auipc	a5,0x1c
    800033b2:	5a278793          	addi	a5,a5,1442 # 8001f950 <bcache+0x8268>
    800033b6:	00f48863          	beq	s1,a5,800033c6 <bread+0x90>
    800033ba:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800033bc:	40bc                	lw	a5,64(s1)
    800033be:	cf81                	beqz	a5,800033d6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033c0:	64a4                	ld	s1,72(s1)
    800033c2:	fee49de3          	bne	s1,a4,800033bc <bread+0x86>
  panic("bget: no buffers");
    800033c6:	00005517          	auipc	a0,0x5
    800033ca:	32250513          	addi	a0,a0,802 # 800086e8 <syscalls+0xd8>
    800033ce:	ffffd097          	auipc	ra,0xffffd
    800033d2:	15c080e7          	jalr	348(ra) # 8000052a <panic>
      b->dev = dev;
    800033d6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800033da:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800033de:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800033e2:	4785                	li	a5,1
    800033e4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033e6:	00014517          	auipc	a0,0x14
    800033ea:	30250513          	addi	a0,a0,770 # 800176e8 <bcache>
    800033ee:	ffffe097          	auipc	ra,0xffffe
    800033f2:	888080e7          	jalr	-1912(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800033f6:	01048513          	addi	a0,s1,16
    800033fa:	00001097          	auipc	ra,0x1
    800033fe:	40e080e7          	jalr	1038(ra) # 80004808 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003402:	409c                	lw	a5,0(s1)
    80003404:	cb89                	beqz	a5,80003416 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003406:	8526                	mv	a0,s1
    80003408:	70a2                	ld	ra,40(sp)
    8000340a:	7402                	ld	s0,32(sp)
    8000340c:	64e2                	ld	s1,24(sp)
    8000340e:	6942                	ld	s2,16(sp)
    80003410:	69a2                	ld	s3,8(sp)
    80003412:	6145                	addi	sp,sp,48
    80003414:	8082                	ret
    virtio_disk_rw(b, 0);
    80003416:	4581                	li	a1,0
    80003418:	8526                	mv	a0,s1
    8000341a:	00003097          	auipc	ra,0x3
    8000341e:	f1c080e7          	jalr	-228(ra) # 80006336 <virtio_disk_rw>
    b->valid = 1;
    80003422:	4785                	li	a5,1
    80003424:	c09c                	sw	a5,0(s1)
  return b;
    80003426:	b7c5                	j	80003406 <bread+0xd0>

0000000080003428 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003428:	1101                	addi	sp,sp,-32
    8000342a:	ec06                	sd	ra,24(sp)
    8000342c:	e822                	sd	s0,16(sp)
    8000342e:	e426                	sd	s1,8(sp)
    80003430:	1000                	addi	s0,sp,32
    80003432:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003434:	0541                	addi	a0,a0,16
    80003436:	00001097          	auipc	ra,0x1
    8000343a:	46c080e7          	jalr	1132(ra) # 800048a2 <holdingsleep>
    8000343e:	cd01                	beqz	a0,80003456 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003440:	4585                	li	a1,1
    80003442:	8526                	mv	a0,s1
    80003444:	00003097          	auipc	ra,0x3
    80003448:	ef2080e7          	jalr	-270(ra) # 80006336 <virtio_disk_rw>
}
    8000344c:	60e2                	ld	ra,24(sp)
    8000344e:	6442                	ld	s0,16(sp)
    80003450:	64a2                	ld	s1,8(sp)
    80003452:	6105                	addi	sp,sp,32
    80003454:	8082                	ret
    panic("bwrite");
    80003456:	00005517          	auipc	a0,0x5
    8000345a:	2aa50513          	addi	a0,a0,682 # 80008700 <syscalls+0xf0>
    8000345e:	ffffd097          	auipc	ra,0xffffd
    80003462:	0cc080e7          	jalr	204(ra) # 8000052a <panic>

0000000080003466 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003466:	1101                	addi	sp,sp,-32
    80003468:	ec06                	sd	ra,24(sp)
    8000346a:	e822                	sd	s0,16(sp)
    8000346c:	e426                	sd	s1,8(sp)
    8000346e:	e04a                	sd	s2,0(sp)
    80003470:	1000                	addi	s0,sp,32
    80003472:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003474:	01050913          	addi	s2,a0,16
    80003478:	854a                	mv	a0,s2
    8000347a:	00001097          	auipc	ra,0x1
    8000347e:	428080e7          	jalr	1064(ra) # 800048a2 <holdingsleep>
    80003482:	c92d                	beqz	a0,800034f4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003484:	854a                	mv	a0,s2
    80003486:	00001097          	auipc	ra,0x1
    8000348a:	3d8080e7          	jalr	984(ra) # 8000485e <releasesleep>

  acquire(&bcache.lock);
    8000348e:	00014517          	auipc	a0,0x14
    80003492:	25a50513          	addi	a0,a0,602 # 800176e8 <bcache>
    80003496:	ffffd097          	auipc	ra,0xffffd
    8000349a:	72c080e7          	jalr	1836(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000349e:	40bc                	lw	a5,64(s1)
    800034a0:	37fd                	addiw	a5,a5,-1
    800034a2:	0007871b          	sext.w	a4,a5
    800034a6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800034a8:	eb05                	bnez	a4,800034d8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034aa:	68bc                	ld	a5,80(s1)
    800034ac:	64b8                	ld	a4,72(s1)
    800034ae:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800034b0:	64bc                	ld	a5,72(s1)
    800034b2:	68b8                	ld	a4,80(s1)
    800034b4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800034b6:	0001c797          	auipc	a5,0x1c
    800034ba:	23278793          	addi	a5,a5,562 # 8001f6e8 <bcache+0x8000>
    800034be:	2b87b703          	ld	a4,696(a5)
    800034c2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800034c4:	0001c717          	auipc	a4,0x1c
    800034c8:	48c70713          	addi	a4,a4,1164 # 8001f950 <bcache+0x8268>
    800034cc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800034ce:	2b87b703          	ld	a4,696(a5)
    800034d2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800034d4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800034d8:	00014517          	auipc	a0,0x14
    800034dc:	21050513          	addi	a0,a0,528 # 800176e8 <bcache>
    800034e0:	ffffd097          	auipc	ra,0xffffd
    800034e4:	796080e7          	jalr	1942(ra) # 80000c76 <release>
}
    800034e8:	60e2                	ld	ra,24(sp)
    800034ea:	6442                	ld	s0,16(sp)
    800034ec:	64a2                	ld	s1,8(sp)
    800034ee:	6902                	ld	s2,0(sp)
    800034f0:	6105                	addi	sp,sp,32
    800034f2:	8082                	ret
    panic("brelse");
    800034f4:	00005517          	auipc	a0,0x5
    800034f8:	21450513          	addi	a0,a0,532 # 80008708 <syscalls+0xf8>
    800034fc:	ffffd097          	auipc	ra,0xffffd
    80003500:	02e080e7          	jalr	46(ra) # 8000052a <panic>

0000000080003504 <bpin>:

void
bpin(struct buf *b) {
    80003504:	1101                	addi	sp,sp,-32
    80003506:	ec06                	sd	ra,24(sp)
    80003508:	e822                	sd	s0,16(sp)
    8000350a:	e426                	sd	s1,8(sp)
    8000350c:	1000                	addi	s0,sp,32
    8000350e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003510:	00014517          	auipc	a0,0x14
    80003514:	1d850513          	addi	a0,a0,472 # 800176e8 <bcache>
    80003518:	ffffd097          	auipc	ra,0xffffd
    8000351c:	6aa080e7          	jalr	1706(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003520:	40bc                	lw	a5,64(s1)
    80003522:	2785                	addiw	a5,a5,1
    80003524:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003526:	00014517          	auipc	a0,0x14
    8000352a:	1c250513          	addi	a0,a0,450 # 800176e8 <bcache>
    8000352e:	ffffd097          	auipc	ra,0xffffd
    80003532:	748080e7          	jalr	1864(ra) # 80000c76 <release>
}
    80003536:	60e2                	ld	ra,24(sp)
    80003538:	6442                	ld	s0,16(sp)
    8000353a:	64a2                	ld	s1,8(sp)
    8000353c:	6105                	addi	sp,sp,32
    8000353e:	8082                	ret

0000000080003540 <bunpin>:

void
bunpin(struct buf *b) {
    80003540:	1101                	addi	sp,sp,-32
    80003542:	ec06                	sd	ra,24(sp)
    80003544:	e822                	sd	s0,16(sp)
    80003546:	e426                	sd	s1,8(sp)
    80003548:	1000                	addi	s0,sp,32
    8000354a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000354c:	00014517          	auipc	a0,0x14
    80003550:	19c50513          	addi	a0,a0,412 # 800176e8 <bcache>
    80003554:	ffffd097          	auipc	ra,0xffffd
    80003558:	66e080e7          	jalr	1646(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000355c:	40bc                	lw	a5,64(s1)
    8000355e:	37fd                	addiw	a5,a5,-1
    80003560:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003562:	00014517          	auipc	a0,0x14
    80003566:	18650513          	addi	a0,a0,390 # 800176e8 <bcache>
    8000356a:	ffffd097          	auipc	ra,0xffffd
    8000356e:	70c080e7          	jalr	1804(ra) # 80000c76 <release>
}
    80003572:	60e2                	ld	ra,24(sp)
    80003574:	6442                	ld	s0,16(sp)
    80003576:	64a2                	ld	s1,8(sp)
    80003578:	6105                	addi	sp,sp,32
    8000357a:	8082                	ret

000000008000357c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000357c:	1101                	addi	sp,sp,-32
    8000357e:	ec06                	sd	ra,24(sp)
    80003580:	e822                	sd	s0,16(sp)
    80003582:	e426                	sd	s1,8(sp)
    80003584:	e04a                	sd	s2,0(sp)
    80003586:	1000                	addi	s0,sp,32
    80003588:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000358a:	00d5d59b          	srliw	a1,a1,0xd
    8000358e:	0001d797          	auipc	a5,0x1d
    80003592:	8367a783          	lw	a5,-1994(a5) # 8001fdc4 <sb+0x1c>
    80003596:	9dbd                	addw	a1,a1,a5
    80003598:	00000097          	auipc	ra,0x0
    8000359c:	d9e080e7          	jalr	-610(ra) # 80003336 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035a0:	0074f713          	andi	a4,s1,7
    800035a4:	4785                	li	a5,1
    800035a6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035aa:	14ce                	slli	s1,s1,0x33
    800035ac:	90d9                	srli	s1,s1,0x36
    800035ae:	00950733          	add	a4,a0,s1
    800035b2:	05874703          	lbu	a4,88(a4)
    800035b6:	00e7f6b3          	and	a3,a5,a4
    800035ba:	c69d                	beqz	a3,800035e8 <bfree+0x6c>
    800035bc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800035be:	94aa                	add	s1,s1,a0
    800035c0:	fff7c793          	not	a5,a5
    800035c4:	8ff9                	and	a5,a5,a4
    800035c6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800035ca:	00001097          	auipc	ra,0x1
    800035ce:	11e080e7          	jalr	286(ra) # 800046e8 <log_write>
  brelse(bp);
    800035d2:	854a                	mv	a0,s2
    800035d4:	00000097          	auipc	ra,0x0
    800035d8:	e92080e7          	jalr	-366(ra) # 80003466 <brelse>
}
    800035dc:	60e2                	ld	ra,24(sp)
    800035de:	6442                	ld	s0,16(sp)
    800035e0:	64a2                	ld	s1,8(sp)
    800035e2:	6902                	ld	s2,0(sp)
    800035e4:	6105                	addi	sp,sp,32
    800035e6:	8082                	ret
    panic("freeing free block");
    800035e8:	00005517          	auipc	a0,0x5
    800035ec:	12850513          	addi	a0,a0,296 # 80008710 <syscalls+0x100>
    800035f0:	ffffd097          	auipc	ra,0xffffd
    800035f4:	f3a080e7          	jalr	-198(ra) # 8000052a <panic>

00000000800035f8 <balloc>:
{
    800035f8:	711d                	addi	sp,sp,-96
    800035fa:	ec86                	sd	ra,88(sp)
    800035fc:	e8a2                	sd	s0,80(sp)
    800035fe:	e4a6                	sd	s1,72(sp)
    80003600:	e0ca                	sd	s2,64(sp)
    80003602:	fc4e                	sd	s3,56(sp)
    80003604:	f852                	sd	s4,48(sp)
    80003606:	f456                	sd	s5,40(sp)
    80003608:	f05a                	sd	s6,32(sp)
    8000360a:	ec5e                	sd	s7,24(sp)
    8000360c:	e862                	sd	s8,16(sp)
    8000360e:	e466                	sd	s9,8(sp)
    80003610:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003612:	0001c797          	auipc	a5,0x1c
    80003616:	79a7a783          	lw	a5,1946(a5) # 8001fdac <sb+0x4>
    8000361a:	cbd1                	beqz	a5,800036ae <balloc+0xb6>
    8000361c:	8baa                	mv	s7,a0
    8000361e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003620:	0001cb17          	auipc	s6,0x1c
    80003624:	788b0b13          	addi	s6,s6,1928 # 8001fda8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003628:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000362a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000362c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000362e:	6c89                	lui	s9,0x2
    80003630:	a831                	j	8000364c <balloc+0x54>
    brelse(bp);
    80003632:	854a                	mv	a0,s2
    80003634:	00000097          	auipc	ra,0x0
    80003638:	e32080e7          	jalr	-462(ra) # 80003466 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000363c:	015c87bb          	addw	a5,s9,s5
    80003640:	00078a9b          	sext.w	s5,a5
    80003644:	004b2703          	lw	a4,4(s6)
    80003648:	06eaf363          	bgeu	s5,a4,800036ae <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000364c:	41fad79b          	sraiw	a5,s5,0x1f
    80003650:	0137d79b          	srliw	a5,a5,0x13
    80003654:	015787bb          	addw	a5,a5,s5
    80003658:	40d7d79b          	sraiw	a5,a5,0xd
    8000365c:	01cb2583          	lw	a1,28(s6)
    80003660:	9dbd                	addw	a1,a1,a5
    80003662:	855e                	mv	a0,s7
    80003664:	00000097          	auipc	ra,0x0
    80003668:	cd2080e7          	jalr	-814(ra) # 80003336 <bread>
    8000366c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000366e:	004b2503          	lw	a0,4(s6)
    80003672:	000a849b          	sext.w	s1,s5
    80003676:	8662                	mv	a2,s8
    80003678:	faa4fde3          	bgeu	s1,a0,80003632 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000367c:	41f6579b          	sraiw	a5,a2,0x1f
    80003680:	01d7d69b          	srliw	a3,a5,0x1d
    80003684:	00c6873b          	addw	a4,a3,a2
    80003688:	00777793          	andi	a5,a4,7
    8000368c:	9f95                	subw	a5,a5,a3
    8000368e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003692:	4037571b          	sraiw	a4,a4,0x3
    80003696:	00e906b3          	add	a3,s2,a4
    8000369a:	0586c683          	lbu	a3,88(a3)
    8000369e:	00d7f5b3          	and	a1,a5,a3
    800036a2:	cd91                	beqz	a1,800036be <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036a4:	2605                	addiw	a2,a2,1
    800036a6:	2485                	addiw	s1,s1,1
    800036a8:	fd4618e3          	bne	a2,s4,80003678 <balloc+0x80>
    800036ac:	b759                	j	80003632 <balloc+0x3a>
  panic("balloc: out of blocks");
    800036ae:	00005517          	auipc	a0,0x5
    800036b2:	07a50513          	addi	a0,a0,122 # 80008728 <syscalls+0x118>
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	e74080e7          	jalr	-396(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800036be:	974a                	add	a4,a4,s2
    800036c0:	8fd5                	or	a5,a5,a3
    800036c2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800036c6:	854a                	mv	a0,s2
    800036c8:	00001097          	auipc	ra,0x1
    800036cc:	020080e7          	jalr	32(ra) # 800046e8 <log_write>
        brelse(bp);
    800036d0:	854a                	mv	a0,s2
    800036d2:	00000097          	auipc	ra,0x0
    800036d6:	d94080e7          	jalr	-620(ra) # 80003466 <brelse>
  bp = bread(dev, bno);
    800036da:	85a6                	mv	a1,s1
    800036dc:	855e                	mv	a0,s7
    800036de:	00000097          	auipc	ra,0x0
    800036e2:	c58080e7          	jalr	-936(ra) # 80003336 <bread>
    800036e6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036e8:	40000613          	li	a2,1024
    800036ec:	4581                	li	a1,0
    800036ee:	05850513          	addi	a0,a0,88
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	5cc080e7          	jalr	1484(ra) # 80000cbe <memset>
  log_write(bp);
    800036fa:	854a                	mv	a0,s2
    800036fc:	00001097          	auipc	ra,0x1
    80003700:	fec080e7          	jalr	-20(ra) # 800046e8 <log_write>
  brelse(bp);
    80003704:	854a                	mv	a0,s2
    80003706:	00000097          	auipc	ra,0x0
    8000370a:	d60080e7          	jalr	-672(ra) # 80003466 <brelse>
}
    8000370e:	8526                	mv	a0,s1
    80003710:	60e6                	ld	ra,88(sp)
    80003712:	6446                	ld	s0,80(sp)
    80003714:	64a6                	ld	s1,72(sp)
    80003716:	6906                	ld	s2,64(sp)
    80003718:	79e2                	ld	s3,56(sp)
    8000371a:	7a42                	ld	s4,48(sp)
    8000371c:	7aa2                	ld	s5,40(sp)
    8000371e:	7b02                	ld	s6,32(sp)
    80003720:	6be2                	ld	s7,24(sp)
    80003722:	6c42                	ld	s8,16(sp)
    80003724:	6ca2                	ld	s9,8(sp)
    80003726:	6125                	addi	sp,sp,96
    80003728:	8082                	ret

000000008000372a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000372a:	7179                	addi	sp,sp,-48
    8000372c:	f406                	sd	ra,40(sp)
    8000372e:	f022                	sd	s0,32(sp)
    80003730:	ec26                	sd	s1,24(sp)
    80003732:	e84a                	sd	s2,16(sp)
    80003734:	e44e                	sd	s3,8(sp)
    80003736:	e052                	sd	s4,0(sp)
    80003738:	1800                	addi	s0,sp,48
    8000373a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000373c:	47ad                	li	a5,11
    8000373e:	04b7fe63          	bgeu	a5,a1,8000379a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003742:	ff45849b          	addiw	s1,a1,-12
    80003746:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000374a:	0ff00793          	li	a5,255
    8000374e:	0ae7e463          	bltu	a5,a4,800037f6 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003752:	08052583          	lw	a1,128(a0)
    80003756:	c5b5                	beqz	a1,800037c2 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003758:	00092503          	lw	a0,0(s2)
    8000375c:	00000097          	auipc	ra,0x0
    80003760:	bda080e7          	jalr	-1062(ra) # 80003336 <bread>
    80003764:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003766:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000376a:	02049713          	slli	a4,s1,0x20
    8000376e:	01e75593          	srli	a1,a4,0x1e
    80003772:	00b784b3          	add	s1,a5,a1
    80003776:	0004a983          	lw	s3,0(s1)
    8000377a:	04098e63          	beqz	s3,800037d6 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000377e:	8552                	mv	a0,s4
    80003780:	00000097          	auipc	ra,0x0
    80003784:	ce6080e7          	jalr	-794(ra) # 80003466 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003788:	854e                	mv	a0,s3
    8000378a:	70a2                	ld	ra,40(sp)
    8000378c:	7402                	ld	s0,32(sp)
    8000378e:	64e2                	ld	s1,24(sp)
    80003790:	6942                	ld	s2,16(sp)
    80003792:	69a2                	ld	s3,8(sp)
    80003794:	6a02                	ld	s4,0(sp)
    80003796:	6145                	addi	sp,sp,48
    80003798:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000379a:	02059793          	slli	a5,a1,0x20
    8000379e:	01e7d593          	srli	a1,a5,0x1e
    800037a2:	00b504b3          	add	s1,a0,a1
    800037a6:	0504a983          	lw	s3,80(s1)
    800037aa:	fc099fe3          	bnez	s3,80003788 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800037ae:	4108                	lw	a0,0(a0)
    800037b0:	00000097          	auipc	ra,0x0
    800037b4:	e48080e7          	jalr	-440(ra) # 800035f8 <balloc>
    800037b8:	0005099b          	sext.w	s3,a0
    800037bc:	0534a823          	sw	s3,80(s1)
    800037c0:	b7e1                	j	80003788 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800037c2:	4108                	lw	a0,0(a0)
    800037c4:	00000097          	auipc	ra,0x0
    800037c8:	e34080e7          	jalr	-460(ra) # 800035f8 <balloc>
    800037cc:	0005059b          	sext.w	a1,a0
    800037d0:	08b92023          	sw	a1,128(s2)
    800037d4:	b751                	j	80003758 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800037d6:	00092503          	lw	a0,0(s2)
    800037da:	00000097          	auipc	ra,0x0
    800037de:	e1e080e7          	jalr	-482(ra) # 800035f8 <balloc>
    800037e2:	0005099b          	sext.w	s3,a0
    800037e6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800037ea:	8552                	mv	a0,s4
    800037ec:	00001097          	auipc	ra,0x1
    800037f0:	efc080e7          	jalr	-260(ra) # 800046e8 <log_write>
    800037f4:	b769                	j	8000377e <bmap+0x54>
  panic("bmap: out of range");
    800037f6:	00005517          	auipc	a0,0x5
    800037fa:	f4a50513          	addi	a0,a0,-182 # 80008740 <syscalls+0x130>
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	d2c080e7          	jalr	-724(ra) # 8000052a <panic>

0000000080003806 <iget>:
{
    80003806:	7179                	addi	sp,sp,-48
    80003808:	f406                	sd	ra,40(sp)
    8000380a:	f022                	sd	s0,32(sp)
    8000380c:	ec26                	sd	s1,24(sp)
    8000380e:	e84a                	sd	s2,16(sp)
    80003810:	e44e                	sd	s3,8(sp)
    80003812:	e052                	sd	s4,0(sp)
    80003814:	1800                	addi	s0,sp,48
    80003816:	89aa                	mv	s3,a0
    80003818:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000381a:	0001c517          	auipc	a0,0x1c
    8000381e:	5ae50513          	addi	a0,a0,1454 # 8001fdc8 <itable>
    80003822:	ffffd097          	auipc	ra,0xffffd
    80003826:	3a0080e7          	jalr	928(ra) # 80000bc2 <acquire>
  empty = 0;
    8000382a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000382c:	0001c497          	auipc	s1,0x1c
    80003830:	5b448493          	addi	s1,s1,1460 # 8001fde0 <itable+0x18>
    80003834:	0001e697          	auipc	a3,0x1e
    80003838:	03c68693          	addi	a3,a3,60 # 80021870 <log>
    8000383c:	a039                	j	8000384a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000383e:	02090b63          	beqz	s2,80003874 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003842:	08848493          	addi	s1,s1,136
    80003846:	02d48a63          	beq	s1,a3,8000387a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000384a:	449c                	lw	a5,8(s1)
    8000384c:	fef059e3          	blez	a5,8000383e <iget+0x38>
    80003850:	4098                	lw	a4,0(s1)
    80003852:	ff3716e3          	bne	a4,s3,8000383e <iget+0x38>
    80003856:	40d8                	lw	a4,4(s1)
    80003858:	ff4713e3          	bne	a4,s4,8000383e <iget+0x38>
      ip->ref++;
    8000385c:	2785                	addiw	a5,a5,1
    8000385e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003860:	0001c517          	auipc	a0,0x1c
    80003864:	56850513          	addi	a0,a0,1384 # 8001fdc8 <itable>
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	40e080e7          	jalr	1038(ra) # 80000c76 <release>
      return ip;
    80003870:	8926                	mv	s2,s1
    80003872:	a03d                	j	800038a0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003874:	f7f9                	bnez	a5,80003842 <iget+0x3c>
    80003876:	8926                	mv	s2,s1
    80003878:	b7e9                	j	80003842 <iget+0x3c>
  if(empty == 0)
    8000387a:	02090c63          	beqz	s2,800038b2 <iget+0xac>
  ip->dev = dev;
    8000387e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003882:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003886:	4785                	li	a5,1
    80003888:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000388c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003890:	0001c517          	auipc	a0,0x1c
    80003894:	53850513          	addi	a0,a0,1336 # 8001fdc8 <itable>
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	3de080e7          	jalr	990(ra) # 80000c76 <release>
}
    800038a0:	854a                	mv	a0,s2
    800038a2:	70a2                	ld	ra,40(sp)
    800038a4:	7402                	ld	s0,32(sp)
    800038a6:	64e2                	ld	s1,24(sp)
    800038a8:	6942                	ld	s2,16(sp)
    800038aa:	69a2                	ld	s3,8(sp)
    800038ac:	6a02                	ld	s4,0(sp)
    800038ae:	6145                	addi	sp,sp,48
    800038b0:	8082                	ret
    panic("iget: no inodes");
    800038b2:	00005517          	auipc	a0,0x5
    800038b6:	ea650513          	addi	a0,a0,-346 # 80008758 <syscalls+0x148>
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	c70080e7          	jalr	-912(ra) # 8000052a <panic>

00000000800038c2 <fsinit>:
fsinit(int dev) {
    800038c2:	7179                	addi	sp,sp,-48
    800038c4:	f406                	sd	ra,40(sp)
    800038c6:	f022                	sd	s0,32(sp)
    800038c8:	ec26                	sd	s1,24(sp)
    800038ca:	e84a                	sd	s2,16(sp)
    800038cc:	e44e                	sd	s3,8(sp)
    800038ce:	1800                	addi	s0,sp,48
    800038d0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800038d2:	4585                	li	a1,1
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	a62080e7          	jalr	-1438(ra) # 80003336 <bread>
    800038dc:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800038de:	0001c997          	auipc	s3,0x1c
    800038e2:	4ca98993          	addi	s3,s3,1226 # 8001fda8 <sb>
    800038e6:	02000613          	li	a2,32
    800038ea:	05850593          	addi	a1,a0,88
    800038ee:	854e                	mv	a0,s3
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	42a080e7          	jalr	1066(ra) # 80000d1a <memmove>
  brelse(bp);
    800038f8:	8526                	mv	a0,s1
    800038fa:	00000097          	auipc	ra,0x0
    800038fe:	b6c080e7          	jalr	-1172(ra) # 80003466 <brelse>
  if(sb.magic != FSMAGIC)
    80003902:	0009a703          	lw	a4,0(s3)
    80003906:	102037b7          	lui	a5,0x10203
    8000390a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000390e:	02f71263          	bne	a4,a5,80003932 <fsinit+0x70>
  initlog(dev, &sb);
    80003912:	0001c597          	auipc	a1,0x1c
    80003916:	49658593          	addi	a1,a1,1174 # 8001fda8 <sb>
    8000391a:	854a                	mv	a0,s2
    8000391c:	00001097          	auipc	ra,0x1
    80003920:	b4e080e7          	jalr	-1202(ra) # 8000446a <initlog>
}
    80003924:	70a2                	ld	ra,40(sp)
    80003926:	7402                	ld	s0,32(sp)
    80003928:	64e2                	ld	s1,24(sp)
    8000392a:	6942                	ld	s2,16(sp)
    8000392c:	69a2                	ld	s3,8(sp)
    8000392e:	6145                	addi	sp,sp,48
    80003930:	8082                	ret
    panic("invalid file system");
    80003932:	00005517          	auipc	a0,0x5
    80003936:	e3650513          	addi	a0,a0,-458 # 80008768 <syscalls+0x158>
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	bf0080e7          	jalr	-1040(ra) # 8000052a <panic>

0000000080003942 <iinit>:
{
    80003942:	7179                	addi	sp,sp,-48
    80003944:	f406                	sd	ra,40(sp)
    80003946:	f022                	sd	s0,32(sp)
    80003948:	ec26                	sd	s1,24(sp)
    8000394a:	e84a                	sd	s2,16(sp)
    8000394c:	e44e                	sd	s3,8(sp)
    8000394e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003950:	00005597          	auipc	a1,0x5
    80003954:	e3058593          	addi	a1,a1,-464 # 80008780 <syscalls+0x170>
    80003958:	0001c517          	auipc	a0,0x1c
    8000395c:	47050513          	addi	a0,a0,1136 # 8001fdc8 <itable>
    80003960:	ffffd097          	auipc	ra,0xffffd
    80003964:	1d2080e7          	jalr	466(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003968:	0001c497          	auipc	s1,0x1c
    8000396c:	48848493          	addi	s1,s1,1160 # 8001fdf0 <itable+0x28>
    80003970:	0001e997          	auipc	s3,0x1e
    80003974:	f1098993          	addi	s3,s3,-240 # 80021880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003978:	00005917          	auipc	s2,0x5
    8000397c:	e1090913          	addi	s2,s2,-496 # 80008788 <syscalls+0x178>
    80003980:	85ca                	mv	a1,s2
    80003982:	8526                	mv	a0,s1
    80003984:	00001097          	auipc	ra,0x1
    80003988:	e4a080e7          	jalr	-438(ra) # 800047ce <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000398c:	08848493          	addi	s1,s1,136
    80003990:	ff3498e3          	bne	s1,s3,80003980 <iinit+0x3e>
}
    80003994:	70a2                	ld	ra,40(sp)
    80003996:	7402                	ld	s0,32(sp)
    80003998:	64e2                	ld	s1,24(sp)
    8000399a:	6942                	ld	s2,16(sp)
    8000399c:	69a2                	ld	s3,8(sp)
    8000399e:	6145                	addi	sp,sp,48
    800039a0:	8082                	ret

00000000800039a2 <ialloc>:
{
    800039a2:	715d                	addi	sp,sp,-80
    800039a4:	e486                	sd	ra,72(sp)
    800039a6:	e0a2                	sd	s0,64(sp)
    800039a8:	fc26                	sd	s1,56(sp)
    800039aa:	f84a                	sd	s2,48(sp)
    800039ac:	f44e                	sd	s3,40(sp)
    800039ae:	f052                	sd	s4,32(sp)
    800039b0:	ec56                	sd	s5,24(sp)
    800039b2:	e85a                	sd	s6,16(sp)
    800039b4:	e45e                	sd	s7,8(sp)
    800039b6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800039b8:	0001c717          	auipc	a4,0x1c
    800039bc:	3fc72703          	lw	a4,1020(a4) # 8001fdb4 <sb+0xc>
    800039c0:	4785                	li	a5,1
    800039c2:	04e7fa63          	bgeu	a5,a4,80003a16 <ialloc+0x74>
    800039c6:	8aaa                	mv	s5,a0
    800039c8:	8bae                	mv	s7,a1
    800039ca:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800039cc:	0001ca17          	auipc	s4,0x1c
    800039d0:	3dca0a13          	addi	s4,s4,988 # 8001fda8 <sb>
    800039d4:	00048b1b          	sext.w	s6,s1
    800039d8:	0044d793          	srli	a5,s1,0x4
    800039dc:	018a2583          	lw	a1,24(s4)
    800039e0:	9dbd                	addw	a1,a1,a5
    800039e2:	8556                	mv	a0,s5
    800039e4:	00000097          	auipc	ra,0x0
    800039e8:	952080e7          	jalr	-1710(ra) # 80003336 <bread>
    800039ec:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039ee:	05850993          	addi	s3,a0,88
    800039f2:	00f4f793          	andi	a5,s1,15
    800039f6:	079a                	slli	a5,a5,0x6
    800039f8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039fa:	00099783          	lh	a5,0(s3)
    800039fe:	c785                	beqz	a5,80003a26 <ialloc+0x84>
    brelse(bp);
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	a66080e7          	jalr	-1434(ra) # 80003466 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a08:	0485                	addi	s1,s1,1
    80003a0a:	00ca2703          	lw	a4,12(s4)
    80003a0e:	0004879b          	sext.w	a5,s1
    80003a12:	fce7e1e3          	bltu	a5,a4,800039d4 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a16:	00005517          	auipc	a0,0x5
    80003a1a:	d7a50513          	addi	a0,a0,-646 # 80008790 <syscalls+0x180>
    80003a1e:	ffffd097          	auipc	ra,0xffffd
    80003a22:	b0c080e7          	jalr	-1268(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003a26:	04000613          	li	a2,64
    80003a2a:	4581                	li	a1,0
    80003a2c:	854e                	mv	a0,s3
    80003a2e:	ffffd097          	auipc	ra,0xffffd
    80003a32:	290080e7          	jalr	656(ra) # 80000cbe <memset>
      dip->type = type;
    80003a36:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a3a:	854a                	mv	a0,s2
    80003a3c:	00001097          	auipc	ra,0x1
    80003a40:	cac080e7          	jalr	-852(ra) # 800046e8 <log_write>
      brelse(bp);
    80003a44:	854a                	mv	a0,s2
    80003a46:	00000097          	auipc	ra,0x0
    80003a4a:	a20080e7          	jalr	-1504(ra) # 80003466 <brelse>
      return iget(dev, inum);
    80003a4e:	85da                	mv	a1,s6
    80003a50:	8556                	mv	a0,s5
    80003a52:	00000097          	auipc	ra,0x0
    80003a56:	db4080e7          	jalr	-588(ra) # 80003806 <iget>
}
    80003a5a:	60a6                	ld	ra,72(sp)
    80003a5c:	6406                	ld	s0,64(sp)
    80003a5e:	74e2                	ld	s1,56(sp)
    80003a60:	7942                	ld	s2,48(sp)
    80003a62:	79a2                	ld	s3,40(sp)
    80003a64:	7a02                	ld	s4,32(sp)
    80003a66:	6ae2                	ld	s5,24(sp)
    80003a68:	6b42                	ld	s6,16(sp)
    80003a6a:	6ba2                	ld	s7,8(sp)
    80003a6c:	6161                	addi	sp,sp,80
    80003a6e:	8082                	ret

0000000080003a70 <iupdate>:
{
    80003a70:	1101                	addi	sp,sp,-32
    80003a72:	ec06                	sd	ra,24(sp)
    80003a74:	e822                	sd	s0,16(sp)
    80003a76:	e426                	sd	s1,8(sp)
    80003a78:	e04a                	sd	s2,0(sp)
    80003a7a:	1000                	addi	s0,sp,32
    80003a7c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a7e:	415c                	lw	a5,4(a0)
    80003a80:	0047d79b          	srliw	a5,a5,0x4
    80003a84:	0001c597          	auipc	a1,0x1c
    80003a88:	33c5a583          	lw	a1,828(a1) # 8001fdc0 <sb+0x18>
    80003a8c:	9dbd                	addw	a1,a1,a5
    80003a8e:	4108                	lw	a0,0(a0)
    80003a90:	00000097          	auipc	ra,0x0
    80003a94:	8a6080e7          	jalr	-1882(ra) # 80003336 <bread>
    80003a98:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a9a:	05850793          	addi	a5,a0,88
    80003a9e:	40c8                	lw	a0,4(s1)
    80003aa0:	893d                	andi	a0,a0,15
    80003aa2:	051a                	slli	a0,a0,0x6
    80003aa4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003aa6:	04449703          	lh	a4,68(s1)
    80003aaa:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003aae:	04649703          	lh	a4,70(s1)
    80003ab2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003ab6:	04849703          	lh	a4,72(s1)
    80003aba:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003abe:	04a49703          	lh	a4,74(s1)
    80003ac2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003ac6:	44f8                	lw	a4,76(s1)
    80003ac8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003aca:	03400613          	li	a2,52
    80003ace:	05048593          	addi	a1,s1,80
    80003ad2:	0531                	addi	a0,a0,12
    80003ad4:	ffffd097          	auipc	ra,0xffffd
    80003ad8:	246080e7          	jalr	582(ra) # 80000d1a <memmove>
  log_write(bp);
    80003adc:	854a                	mv	a0,s2
    80003ade:	00001097          	auipc	ra,0x1
    80003ae2:	c0a080e7          	jalr	-1014(ra) # 800046e8 <log_write>
  brelse(bp);
    80003ae6:	854a                	mv	a0,s2
    80003ae8:	00000097          	auipc	ra,0x0
    80003aec:	97e080e7          	jalr	-1666(ra) # 80003466 <brelse>
}
    80003af0:	60e2                	ld	ra,24(sp)
    80003af2:	6442                	ld	s0,16(sp)
    80003af4:	64a2                	ld	s1,8(sp)
    80003af6:	6902                	ld	s2,0(sp)
    80003af8:	6105                	addi	sp,sp,32
    80003afa:	8082                	ret

0000000080003afc <idup>:
{
    80003afc:	1101                	addi	sp,sp,-32
    80003afe:	ec06                	sd	ra,24(sp)
    80003b00:	e822                	sd	s0,16(sp)
    80003b02:	e426                	sd	s1,8(sp)
    80003b04:	1000                	addi	s0,sp,32
    80003b06:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b08:	0001c517          	auipc	a0,0x1c
    80003b0c:	2c050513          	addi	a0,a0,704 # 8001fdc8 <itable>
    80003b10:	ffffd097          	auipc	ra,0xffffd
    80003b14:	0b2080e7          	jalr	178(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003b18:	449c                	lw	a5,8(s1)
    80003b1a:	2785                	addiw	a5,a5,1
    80003b1c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b1e:	0001c517          	auipc	a0,0x1c
    80003b22:	2aa50513          	addi	a0,a0,682 # 8001fdc8 <itable>
    80003b26:	ffffd097          	auipc	ra,0xffffd
    80003b2a:	150080e7          	jalr	336(ra) # 80000c76 <release>
}
    80003b2e:	8526                	mv	a0,s1
    80003b30:	60e2                	ld	ra,24(sp)
    80003b32:	6442                	ld	s0,16(sp)
    80003b34:	64a2                	ld	s1,8(sp)
    80003b36:	6105                	addi	sp,sp,32
    80003b38:	8082                	ret

0000000080003b3a <ilock>:
{
    80003b3a:	1101                	addi	sp,sp,-32
    80003b3c:	ec06                	sd	ra,24(sp)
    80003b3e:	e822                	sd	s0,16(sp)
    80003b40:	e426                	sd	s1,8(sp)
    80003b42:	e04a                	sd	s2,0(sp)
    80003b44:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b46:	c115                	beqz	a0,80003b6a <ilock+0x30>
    80003b48:	84aa                	mv	s1,a0
    80003b4a:	451c                	lw	a5,8(a0)
    80003b4c:	00f05f63          	blez	a5,80003b6a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b50:	0541                	addi	a0,a0,16
    80003b52:	00001097          	auipc	ra,0x1
    80003b56:	cb6080e7          	jalr	-842(ra) # 80004808 <acquiresleep>
  if(ip->valid == 0){
    80003b5a:	40bc                	lw	a5,64(s1)
    80003b5c:	cf99                	beqz	a5,80003b7a <ilock+0x40>
}
    80003b5e:	60e2                	ld	ra,24(sp)
    80003b60:	6442                	ld	s0,16(sp)
    80003b62:	64a2                	ld	s1,8(sp)
    80003b64:	6902                	ld	s2,0(sp)
    80003b66:	6105                	addi	sp,sp,32
    80003b68:	8082                	ret
    panic("ilock");
    80003b6a:	00005517          	auipc	a0,0x5
    80003b6e:	c3e50513          	addi	a0,a0,-962 # 800087a8 <syscalls+0x198>
    80003b72:	ffffd097          	auipc	ra,0xffffd
    80003b76:	9b8080e7          	jalr	-1608(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b7a:	40dc                	lw	a5,4(s1)
    80003b7c:	0047d79b          	srliw	a5,a5,0x4
    80003b80:	0001c597          	auipc	a1,0x1c
    80003b84:	2405a583          	lw	a1,576(a1) # 8001fdc0 <sb+0x18>
    80003b88:	9dbd                	addw	a1,a1,a5
    80003b8a:	4088                	lw	a0,0(s1)
    80003b8c:	fffff097          	auipc	ra,0xfffff
    80003b90:	7aa080e7          	jalr	1962(ra) # 80003336 <bread>
    80003b94:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b96:	05850593          	addi	a1,a0,88
    80003b9a:	40dc                	lw	a5,4(s1)
    80003b9c:	8bbd                	andi	a5,a5,15
    80003b9e:	079a                	slli	a5,a5,0x6
    80003ba0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ba2:	00059783          	lh	a5,0(a1)
    80003ba6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003baa:	00259783          	lh	a5,2(a1)
    80003bae:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003bb2:	00459783          	lh	a5,4(a1)
    80003bb6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003bba:	00659783          	lh	a5,6(a1)
    80003bbe:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003bc2:	459c                	lw	a5,8(a1)
    80003bc4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003bc6:	03400613          	li	a2,52
    80003bca:	05b1                	addi	a1,a1,12
    80003bcc:	05048513          	addi	a0,s1,80
    80003bd0:	ffffd097          	auipc	ra,0xffffd
    80003bd4:	14a080e7          	jalr	330(ra) # 80000d1a <memmove>
    brelse(bp);
    80003bd8:	854a                	mv	a0,s2
    80003bda:	00000097          	auipc	ra,0x0
    80003bde:	88c080e7          	jalr	-1908(ra) # 80003466 <brelse>
    ip->valid = 1;
    80003be2:	4785                	li	a5,1
    80003be4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003be6:	04449783          	lh	a5,68(s1)
    80003bea:	fbb5                	bnez	a5,80003b5e <ilock+0x24>
      panic("ilock: no type");
    80003bec:	00005517          	auipc	a0,0x5
    80003bf0:	bc450513          	addi	a0,a0,-1084 # 800087b0 <syscalls+0x1a0>
    80003bf4:	ffffd097          	auipc	ra,0xffffd
    80003bf8:	936080e7          	jalr	-1738(ra) # 8000052a <panic>

0000000080003bfc <iunlock>:
{
    80003bfc:	1101                	addi	sp,sp,-32
    80003bfe:	ec06                	sd	ra,24(sp)
    80003c00:	e822                	sd	s0,16(sp)
    80003c02:	e426                	sd	s1,8(sp)
    80003c04:	e04a                	sd	s2,0(sp)
    80003c06:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c08:	c905                	beqz	a0,80003c38 <iunlock+0x3c>
    80003c0a:	84aa                	mv	s1,a0
    80003c0c:	01050913          	addi	s2,a0,16
    80003c10:	854a                	mv	a0,s2
    80003c12:	00001097          	auipc	ra,0x1
    80003c16:	c90080e7          	jalr	-880(ra) # 800048a2 <holdingsleep>
    80003c1a:	cd19                	beqz	a0,80003c38 <iunlock+0x3c>
    80003c1c:	449c                	lw	a5,8(s1)
    80003c1e:	00f05d63          	blez	a5,80003c38 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c22:	854a                	mv	a0,s2
    80003c24:	00001097          	auipc	ra,0x1
    80003c28:	c3a080e7          	jalr	-966(ra) # 8000485e <releasesleep>
}
    80003c2c:	60e2                	ld	ra,24(sp)
    80003c2e:	6442                	ld	s0,16(sp)
    80003c30:	64a2                	ld	s1,8(sp)
    80003c32:	6902                	ld	s2,0(sp)
    80003c34:	6105                	addi	sp,sp,32
    80003c36:	8082                	ret
    panic("iunlock");
    80003c38:	00005517          	auipc	a0,0x5
    80003c3c:	b8850513          	addi	a0,a0,-1144 # 800087c0 <syscalls+0x1b0>
    80003c40:	ffffd097          	auipc	ra,0xffffd
    80003c44:	8ea080e7          	jalr	-1814(ra) # 8000052a <panic>

0000000080003c48 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c48:	7179                	addi	sp,sp,-48
    80003c4a:	f406                	sd	ra,40(sp)
    80003c4c:	f022                	sd	s0,32(sp)
    80003c4e:	ec26                	sd	s1,24(sp)
    80003c50:	e84a                	sd	s2,16(sp)
    80003c52:	e44e                	sd	s3,8(sp)
    80003c54:	e052                	sd	s4,0(sp)
    80003c56:	1800                	addi	s0,sp,48
    80003c58:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c5a:	05050493          	addi	s1,a0,80
    80003c5e:	08050913          	addi	s2,a0,128
    80003c62:	a021                	j	80003c6a <itrunc+0x22>
    80003c64:	0491                	addi	s1,s1,4
    80003c66:	01248d63          	beq	s1,s2,80003c80 <itrunc+0x38>
    if(ip->addrs[i]){
    80003c6a:	408c                	lw	a1,0(s1)
    80003c6c:	dde5                	beqz	a1,80003c64 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c6e:	0009a503          	lw	a0,0(s3)
    80003c72:	00000097          	auipc	ra,0x0
    80003c76:	90a080e7          	jalr	-1782(ra) # 8000357c <bfree>
      ip->addrs[i] = 0;
    80003c7a:	0004a023          	sw	zero,0(s1)
    80003c7e:	b7dd                	j	80003c64 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c80:	0809a583          	lw	a1,128(s3)
    80003c84:	e185                	bnez	a1,80003ca4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c86:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c8a:	854e                	mv	a0,s3
    80003c8c:	00000097          	auipc	ra,0x0
    80003c90:	de4080e7          	jalr	-540(ra) # 80003a70 <iupdate>
}
    80003c94:	70a2                	ld	ra,40(sp)
    80003c96:	7402                	ld	s0,32(sp)
    80003c98:	64e2                	ld	s1,24(sp)
    80003c9a:	6942                	ld	s2,16(sp)
    80003c9c:	69a2                	ld	s3,8(sp)
    80003c9e:	6a02                	ld	s4,0(sp)
    80003ca0:	6145                	addi	sp,sp,48
    80003ca2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ca4:	0009a503          	lw	a0,0(s3)
    80003ca8:	fffff097          	auipc	ra,0xfffff
    80003cac:	68e080e7          	jalr	1678(ra) # 80003336 <bread>
    80003cb0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003cb2:	05850493          	addi	s1,a0,88
    80003cb6:	45850913          	addi	s2,a0,1112
    80003cba:	a021                	j	80003cc2 <itrunc+0x7a>
    80003cbc:	0491                	addi	s1,s1,4
    80003cbe:	01248b63          	beq	s1,s2,80003cd4 <itrunc+0x8c>
      if(a[j])
    80003cc2:	408c                	lw	a1,0(s1)
    80003cc4:	dde5                	beqz	a1,80003cbc <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003cc6:	0009a503          	lw	a0,0(s3)
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	8b2080e7          	jalr	-1870(ra) # 8000357c <bfree>
    80003cd2:	b7ed                	j	80003cbc <itrunc+0x74>
    brelse(bp);
    80003cd4:	8552                	mv	a0,s4
    80003cd6:	fffff097          	auipc	ra,0xfffff
    80003cda:	790080e7          	jalr	1936(ra) # 80003466 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003cde:	0809a583          	lw	a1,128(s3)
    80003ce2:	0009a503          	lw	a0,0(s3)
    80003ce6:	00000097          	auipc	ra,0x0
    80003cea:	896080e7          	jalr	-1898(ra) # 8000357c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003cee:	0809a023          	sw	zero,128(s3)
    80003cf2:	bf51                	j	80003c86 <itrunc+0x3e>

0000000080003cf4 <iput>:
{
    80003cf4:	1101                	addi	sp,sp,-32
    80003cf6:	ec06                	sd	ra,24(sp)
    80003cf8:	e822                	sd	s0,16(sp)
    80003cfa:	e426                	sd	s1,8(sp)
    80003cfc:	e04a                	sd	s2,0(sp)
    80003cfe:	1000                	addi	s0,sp,32
    80003d00:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d02:	0001c517          	auipc	a0,0x1c
    80003d06:	0c650513          	addi	a0,a0,198 # 8001fdc8 <itable>
    80003d0a:	ffffd097          	auipc	ra,0xffffd
    80003d0e:	eb8080e7          	jalr	-328(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d12:	4498                	lw	a4,8(s1)
    80003d14:	4785                	li	a5,1
    80003d16:	02f70363          	beq	a4,a5,80003d3c <iput+0x48>
  ip->ref--;
    80003d1a:	449c                	lw	a5,8(s1)
    80003d1c:	37fd                	addiw	a5,a5,-1
    80003d1e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d20:	0001c517          	auipc	a0,0x1c
    80003d24:	0a850513          	addi	a0,a0,168 # 8001fdc8 <itable>
    80003d28:	ffffd097          	auipc	ra,0xffffd
    80003d2c:	f4e080e7          	jalr	-178(ra) # 80000c76 <release>
}
    80003d30:	60e2                	ld	ra,24(sp)
    80003d32:	6442                	ld	s0,16(sp)
    80003d34:	64a2                	ld	s1,8(sp)
    80003d36:	6902                	ld	s2,0(sp)
    80003d38:	6105                	addi	sp,sp,32
    80003d3a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d3c:	40bc                	lw	a5,64(s1)
    80003d3e:	dff1                	beqz	a5,80003d1a <iput+0x26>
    80003d40:	04a49783          	lh	a5,74(s1)
    80003d44:	fbf9                	bnez	a5,80003d1a <iput+0x26>
    acquiresleep(&ip->lock);
    80003d46:	01048913          	addi	s2,s1,16
    80003d4a:	854a                	mv	a0,s2
    80003d4c:	00001097          	auipc	ra,0x1
    80003d50:	abc080e7          	jalr	-1348(ra) # 80004808 <acquiresleep>
    release(&itable.lock);
    80003d54:	0001c517          	auipc	a0,0x1c
    80003d58:	07450513          	addi	a0,a0,116 # 8001fdc8 <itable>
    80003d5c:	ffffd097          	auipc	ra,0xffffd
    80003d60:	f1a080e7          	jalr	-230(ra) # 80000c76 <release>
    itrunc(ip);
    80003d64:	8526                	mv	a0,s1
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	ee2080e7          	jalr	-286(ra) # 80003c48 <itrunc>
    ip->type = 0;
    80003d6e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d72:	8526                	mv	a0,s1
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	cfc080e7          	jalr	-772(ra) # 80003a70 <iupdate>
    ip->valid = 0;
    80003d7c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d80:	854a                	mv	a0,s2
    80003d82:	00001097          	auipc	ra,0x1
    80003d86:	adc080e7          	jalr	-1316(ra) # 8000485e <releasesleep>
    acquire(&itable.lock);
    80003d8a:	0001c517          	auipc	a0,0x1c
    80003d8e:	03e50513          	addi	a0,a0,62 # 8001fdc8 <itable>
    80003d92:	ffffd097          	auipc	ra,0xffffd
    80003d96:	e30080e7          	jalr	-464(ra) # 80000bc2 <acquire>
    80003d9a:	b741                	j	80003d1a <iput+0x26>

0000000080003d9c <iunlockput>:
{
    80003d9c:	1101                	addi	sp,sp,-32
    80003d9e:	ec06                	sd	ra,24(sp)
    80003da0:	e822                	sd	s0,16(sp)
    80003da2:	e426                	sd	s1,8(sp)
    80003da4:	1000                	addi	s0,sp,32
    80003da6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	e54080e7          	jalr	-428(ra) # 80003bfc <iunlock>
  iput(ip);
    80003db0:	8526                	mv	a0,s1
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	f42080e7          	jalr	-190(ra) # 80003cf4 <iput>
}
    80003dba:	60e2                	ld	ra,24(sp)
    80003dbc:	6442                	ld	s0,16(sp)
    80003dbe:	64a2                	ld	s1,8(sp)
    80003dc0:	6105                	addi	sp,sp,32
    80003dc2:	8082                	ret

0000000080003dc4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003dc4:	1141                	addi	sp,sp,-16
    80003dc6:	e422                	sd	s0,8(sp)
    80003dc8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003dca:	411c                	lw	a5,0(a0)
    80003dcc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003dce:	415c                	lw	a5,4(a0)
    80003dd0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003dd2:	04451783          	lh	a5,68(a0)
    80003dd6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003dda:	04a51783          	lh	a5,74(a0)
    80003dde:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003de2:	04c56783          	lwu	a5,76(a0)
    80003de6:	e99c                	sd	a5,16(a1)
}
    80003de8:	6422                	ld	s0,8(sp)
    80003dea:	0141                	addi	sp,sp,16
    80003dec:	8082                	ret

0000000080003dee <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dee:	457c                	lw	a5,76(a0)
    80003df0:	0ed7e963          	bltu	a5,a3,80003ee2 <readi+0xf4>
{
    80003df4:	7159                	addi	sp,sp,-112
    80003df6:	f486                	sd	ra,104(sp)
    80003df8:	f0a2                	sd	s0,96(sp)
    80003dfa:	eca6                	sd	s1,88(sp)
    80003dfc:	e8ca                	sd	s2,80(sp)
    80003dfe:	e4ce                	sd	s3,72(sp)
    80003e00:	e0d2                	sd	s4,64(sp)
    80003e02:	fc56                	sd	s5,56(sp)
    80003e04:	f85a                	sd	s6,48(sp)
    80003e06:	f45e                	sd	s7,40(sp)
    80003e08:	f062                	sd	s8,32(sp)
    80003e0a:	ec66                	sd	s9,24(sp)
    80003e0c:	e86a                	sd	s10,16(sp)
    80003e0e:	e46e                	sd	s11,8(sp)
    80003e10:	1880                	addi	s0,sp,112
    80003e12:	8baa                	mv	s7,a0
    80003e14:	8c2e                	mv	s8,a1
    80003e16:	8ab2                	mv	s5,a2
    80003e18:	84b6                	mv	s1,a3
    80003e1a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e1c:	9f35                	addw	a4,a4,a3
    return 0;
    80003e1e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e20:	0ad76063          	bltu	a4,a3,80003ec0 <readi+0xd2>
  if(off + n > ip->size)
    80003e24:	00e7f463          	bgeu	a5,a4,80003e2c <readi+0x3e>
    n = ip->size - off;
    80003e28:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e2c:	0a0b0963          	beqz	s6,80003ede <readi+0xf0>
    80003e30:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e32:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e36:	5cfd                	li	s9,-1
    80003e38:	a82d                	j	80003e72 <readi+0x84>
    80003e3a:	020a1d93          	slli	s11,s4,0x20
    80003e3e:	020ddd93          	srli	s11,s11,0x20
    80003e42:	05890793          	addi	a5,s2,88
    80003e46:	86ee                	mv	a3,s11
    80003e48:	963e                	add	a2,a2,a5
    80003e4a:	85d6                	mv	a1,s5
    80003e4c:	8562                	mv	a0,s8
    80003e4e:	ffffe097          	auipc	ra,0xffffe
    80003e52:	6f4080e7          	jalr	1780(ra) # 80002542 <either_copyout>
    80003e56:	05950d63          	beq	a0,s9,80003eb0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e5a:	854a                	mv	a0,s2
    80003e5c:	fffff097          	auipc	ra,0xfffff
    80003e60:	60a080e7          	jalr	1546(ra) # 80003466 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e64:	013a09bb          	addw	s3,s4,s3
    80003e68:	009a04bb          	addw	s1,s4,s1
    80003e6c:	9aee                	add	s5,s5,s11
    80003e6e:	0569f763          	bgeu	s3,s6,80003ebc <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e72:	000ba903          	lw	s2,0(s7)
    80003e76:	00a4d59b          	srliw	a1,s1,0xa
    80003e7a:	855e                	mv	a0,s7
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	8ae080e7          	jalr	-1874(ra) # 8000372a <bmap>
    80003e84:	0005059b          	sext.w	a1,a0
    80003e88:	854a                	mv	a0,s2
    80003e8a:	fffff097          	auipc	ra,0xfffff
    80003e8e:	4ac080e7          	jalr	1196(ra) # 80003336 <bread>
    80003e92:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e94:	3ff4f613          	andi	a2,s1,1023
    80003e98:	40cd07bb          	subw	a5,s10,a2
    80003e9c:	413b073b          	subw	a4,s6,s3
    80003ea0:	8a3e                	mv	s4,a5
    80003ea2:	2781                	sext.w	a5,a5
    80003ea4:	0007069b          	sext.w	a3,a4
    80003ea8:	f8f6f9e3          	bgeu	a3,a5,80003e3a <readi+0x4c>
    80003eac:	8a3a                	mv	s4,a4
    80003eae:	b771                	j	80003e3a <readi+0x4c>
      brelse(bp);
    80003eb0:	854a                	mv	a0,s2
    80003eb2:	fffff097          	auipc	ra,0xfffff
    80003eb6:	5b4080e7          	jalr	1460(ra) # 80003466 <brelse>
      tot = -1;
    80003eba:	59fd                	li	s3,-1
  }
  return tot;
    80003ebc:	0009851b          	sext.w	a0,s3
}
    80003ec0:	70a6                	ld	ra,104(sp)
    80003ec2:	7406                	ld	s0,96(sp)
    80003ec4:	64e6                	ld	s1,88(sp)
    80003ec6:	6946                	ld	s2,80(sp)
    80003ec8:	69a6                	ld	s3,72(sp)
    80003eca:	6a06                	ld	s4,64(sp)
    80003ecc:	7ae2                	ld	s5,56(sp)
    80003ece:	7b42                	ld	s6,48(sp)
    80003ed0:	7ba2                	ld	s7,40(sp)
    80003ed2:	7c02                	ld	s8,32(sp)
    80003ed4:	6ce2                	ld	s9,24(sp)
    80003ed6:	6d42                	ld	s10,16(sp)
    80003ed8:	6da2                	ld	s11,8(sp)
    80003eda:	6165                	addi	sp,sp,112
    80003edc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ede:	89da                	mv	s3,s6
    80003ee0:	bff1                	j	80003ebc <readi+0xce>
    return 0;
    80003ee2:	4501                	li	a0,0
}
    80003ee4:	8082                	ret

0000000080003ee6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ee6:	457c                	lw	a5,76(a0)
    80003ee8:	10d7e863          	bltu	a5,a3,80003ff8 <writei+0x112>
{
    80003eec:	7159                	addi	sp,sp,-112
    80003eee:	f486                	sd	ra,104(sp)
    80003ef0:	f0a2                	sd	s0,96(sp)
    80003ef2:	eca6                	sd	s1,88(sp)
    80003ef4:	e8ca                	sd	s2,80(sp)
    80003ef6:	e4ce                	sd	s3,72(sp)
    80003ef8:	e0d2                	sd	s4,64(sp)
    80003efa:	fc56                	sd	s5,56(sp)
    80003efc:	f85a                	sd	s6,48(sp)
    80003efe:	f45e                	sd	s7,40(sp)
    80003f00:	f062                	sd	s8,32(sp)
    80003f02:	ec66                	sd	s9,24(sp)
    80003f04:	e86a                	sd	s10,16(sp)
    80003f06:	e46e                	sd	s11,8(sp)
    80003f08:	1880                	addi	s0,sp,112
    80003f0a:	8b2a                	mv	s6,a0
    80003f0c:	8c2e                	mv	s8,a1
    80003f0e:	8ab2                	mv	s5,a2
    80003f10:	8936                	mv	s2,a3
    80003f12:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003f14:	00e687bb          	addw	a5,a3,a4
    80003f18:	0ed7e263          	bltu	a5,a3,80003ffc <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f1c:	00043737          	lui	a4,0x43
    80003f20:	0ef76063          	bltu	a4,a5,80004000 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f24:	0c0b8863          	beqz	s7,80003ff4 <writei+0x10e>
    80003f28:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f2a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f2e:	5cfd                	li	s9,-1
    80003f30:	a091                	j	80003f74 <writei+0x8e>
    80003f32:	02099d93          	slli	s11,s3,0x20
    80003f36:	020ddd93          	srli	s11,s11,0x20
    80003f3a:	05848793          	addi	a5,s1,88
    80003f3e:	86ee                	mv	a3,s11
    80003f40:	8656                	mv	a2,s5
    80003f42:	85e2                	mv	a1,s8
    80003f44:	953e                	add	a0,a0,a5
    80003f46:	ffffe097          	auipc	ra,0xffffe
    80003f4a:	652080e7          	jalr	1618(ra) # 80002598 <either_copyin>
    80003f4e:	07950263          	beq	a0,s9,80003fb2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f52:	8526                	mv	a0,s1
    80003f54:	00000097          	auipc	ra,0x0
    80003f58:	794080e7          	jalr	1940(ra) # 800046e8 <log_write>
    brelse(bp);
    80003f5c:	8526                	mv	a0,s1
    80003f5e:	fffff097          	auipc	ra,0xfffff
    80003f62:	508080e7          	jalr	1288(ra) # 80003466 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f66:	01498a3b          	addw	s4,s3,s4
    80003f6a:	0129893b          	addw	s2,s3,s2
    80003f6e:	9aee                	add	s5,s5,s11
    80003f70:	057a7663          	bgeu	s4,s7,80003fbc <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f74:	000b2483          	lw	s1,0(s6)
    80003f78:	00a9559b          	srliw	a1,s2,0xa
    80003f7c:	855a                	mv	a0,s6
    80003f7e:	fffff097          	auipc	ra,0xfffff
    80003f82:	7ac080e7          	jalr	1964(ra) # 8000372a <bmap>
    80003f86:	0005059b          	sext.w	a1,a0
    80003f8a:	8526                	mv	a0,s1
    80003f8c:	fffff097          	auipc	ra,0xfffff
    80003f90:	3aa080e7          	jalr	938(ra) # 80003336 <bread>
    80003f94:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f96:	3ff97513          	andi	a0,s2,1023
    80003f9a:	40ad07bb          	subw	a5,s10,a0
    80003f9e:	414b873b          	subw	a4,s7,s4
    80003fa2:	89be                	mv	s3,a5
    80003fa4:	2781                	sext.w	a5,a5
    80003fa6:	0007069b          	sext.w	a3,a4
    80003faa:	f8f6f4e3          	bgeu	a3,a5,80003f32 <writei+0x4c>
    80003fae:	89ba                	mv	s3,a4
    80003fb0:	b749                	j	80003f32 <writei+0x4c>
      brelse(bp);
    80003fb2:	8526                	mv	a0,s1
    80003fb4:	fffff097          	auipc	ra,0xfffff
    80003fb8:	4b2080e7          	jalr	1202(ra) # 80003466 <brelse>
  }

  if(off > ip->size)
    80003fbc:	04cb2783          	lw	a5,76(s6)
    80003fc0:	0127f463          	bgeu	a5,s2,80003fc8 <writei+0xe2>
    ip->size = off;
    80003fc4:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003fc8:	855a                	mv	a0,s6
    80003fca:	00000097          	auipc	ra,0x0
    80003fce:	aa6080e7          	jalr	-1370(ra) # 80003a70 <iupdate>

  return tot;
    80003fd2:	000a051b          	sext.w	a0,s4
}
    80003fd6:	70a6                	ld	ra,104(sp)
    80003fd8:	7406                	ld	s0,96(sp)
    80003fda:	64e6                	ld	s1,88(sp)
    80003fdc:	6946                	ld	s2,80(sp)
    80003fde:	69a6                	ld	s3,72(sp)
    80003fe0:	6a06                	ld	s4,64(sp)
    80003fe2:	7ae2                	ld	s5,56(sp)
    80003fe4:	7b42                	ld	s6,48(sp)
    80003fe6:	7ba2                	ld	s7,40(sp)
    80003fe8:	7c02                	ld	s8,32(sp)
    80003fea:	6ce2                	ld	s9,24(sp)
    80003fec:	6d42                	ld	s10,16(sp)
    80003fee:	6da2                	ld	s11,8(sp)
    80003ff0:	6165                	addi	sp,sp,112
    80003ff2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ff4:	8a5e                	mv	s4,s7
    80003ff6:	bfc9                	j	80003fc8 <writei+0xe2>
    return -1;
    80003ff8:	557d                	li	a0,-1
}
    80003ffa:	8082                	ret
    return -1;
    80003ffc:	557d                	li	a0,-1
    80003ffe:	bfe1                	j	80003fd6 <writei+0xf0>
    return -1;
    80004000:	557d                	li	a0,-1
    80004002:	bfd1                	j	80003fd6 <writei+0xf0>

0000000080004004 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004004:	1141                	addi	sp,sp,-16
    80004006:	e406                	sd	ra,8(sp)
    80004008:	e022                	sd	s0,0(sp)
    8000400a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000400c:	4639                	li	a2,14
    8000400e:	ffffd097          	auipc	ra,0xffffd
    80004012:	d88080e7          	jalr	-632(ra) # 80000d96 <strncmp>
}
    80004016:	60a2                	ld	ra,8(sp)
    80004018:	6402                	ld	s0,0(sp)
    8000401a:	0141                	addi	sp,sp,16
    8000401c:	8082                	ret

000000008000401e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000401e:	7139                	addi	sp,sp,-64
    80004020:	fc06                	sd	ra,56(sp)
    80004022:	f822                	sd	s0,48(sp)
    80004024:	f426                	sd	s1,40(sp)
    80004026:	f04a                	sd	s2,32(sp)
    80004028:	ec4e                	sd	s3,24(sp)
    8000402a:	e852                	sd	s4,16(sp)
    8000402c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000402e:	04451703          	lh	a4,68(a0)
    80004032:	4785                	li	a5,1
    80004034:	00f71a63          	bne	a4,a5,80004048 <dirlookup+0x2a>
    80004038:	892a                	mv	s2,a0
    8000403a:	89ae                	mv	s3,a1
    8000403c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000403e:	457c                	lw	a5,76(a0)
    80004040:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004042:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004044:	e79d                	bnez	a5,80004072 <dirlookup+0x54>
    80004046:	a8a5                	j	800040be <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004048:	00004517          	auipc	a0,0x4
    8000404c:	78050513          	addi	a0,a0,1920 # 800087c8 <syscalls+0x1b8>
    80004050:	ffffc097          	auipc	ra,0xffffc
    80004054:	4da080e7          	jalr	1242(ra) # 8000052a <panic>
      panic("dirlookup read");
    80004058:	00004517          	auipc	a0,0x4
    8000405c:	78850513          	addi	a0,a0,1928 # 800087e0 <syscalls+0x1d0>
    80004060:	ffffc097          	auipc	ra,0xffffc
    80004064:	4ca080e7          	jalr	1226(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004068:	24c1                	addiw	s1,s1,16
    8000406a:	04c92783          	lw	a5,76(s2)
    8000406e:	04f4f763          	bgeu	s1,a5,800040bc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004072:	4741                	li	a4,16
    80004074:	86a6                	mv	a3,s1
    80004076:	fc040613          	addi	a2,s0,-64
    8000407a:	4581                	li	a1,0
    8000407c:	854a                	mv	a0,s2
    8000407e:	00000097          	auipc	ra,0x0
    80004082:	d70080e7          	jalr	-656(ra) # 80003dee <readi>
    80004086:	47c1                	li	a5,16
    80004088:	fcf518e3          	bne	a0,a5,80004058 <dirlookup+0x3a>
    if(de.inum == 0)
    8000408c:	fc045783          	lhu	a5,-64(s0)
    80004090:	dfe1                	beqz	a5,80004068 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004092:	fc240593          	addi	a1,s0,-62
    80004096:	854e                	mv	a0,s3
    80004098:	00000097          	auipc	ra,0x0
    8000409c:	f6c080e7          	jalr	-148(ra) # 80004004 <namecmp>
    800040a0:	f561                	bnez	a0,80004068 <dirlookup+0x4a>
      if(poff)
    800040a2:	000a0463          	beqz	s4,800040aa <dirlookup+0x8c>
        *poff = off;
    800040a6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040aa:	fc045583          	lhu	a1,-64(s0)
    800040ae:	00092503          	lw	a0,0(s2)
    800040b2:	fffff097          	auipc	ra,0xfffff
    800040b6:	754080e7          	jalr	1876(ra) # 80003806 <iget>
    800040ba:	a011                	j	800040be <dirlookup+0xa0>
  return 0;
    800040bc:	4501                	li	a0,0
}
    800040be:	70e2                	ld	ra,56(sp)
    800040c0:	7442                	ld	s0,48(sp)
    800040c2:	74a2                	ld	s1,40(sp)
    800040c4:	7902                	ld	s2,32(sp)
    800040c6:	69e2                	ld	s3,24(sp)
    800040c8:	6a42                	ld	s4,16(sp)
    800040ca:	6121                	addi	sp,sp,64
    800040cc:	8082                	ret

00000000800040ce <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800040ce:	711d                	addi	sp,sp,-96
    800040d0:	ec86                	sd	ra,88(sp)
    800040d2:	e8a2                	sd	s0,80(sp)
    800040d4:	e4a6                	sd	s1,72(sp)
    800040d6:	e0ca                	sd	s2,64(sp)
    800040d8:	fc4e                	sd	s3,56(sp)
    800040da:	f852                	sd	s4,48(sp)
    800040dc:	f456                	sd	s5,40(sp)
    800040de:	f05a                	sd	s6,32(sp)
    800040e0:	ec5e                	sd	s7,24(sp)
    800040e2:	e862                	sd	s8,16(sp)
    800040e4:	e466                	sd	s9,8(sp)
    800040e6:	1080                	addi	s0,sp,96
    800040e8:	84aa                	mv	s1,a0
    800040ea:	8aae                	mv	s5,a1
    800040ec:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040ee:	00054703          	lbu	a4,0(a0)
    800040f2:	02f00793          	li	a5,47
    800040f6:	02f70363          	beq	a4,a5,8000411c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040fa:	ffffe097          	auipc	ra,0xffffe
    800040fe:	884080e7          	jalr	-1916(ra) # 8000197e <myproc>
    80004102:	16853503          	ld	a0,360(a0)
    80004106:	00000097          	auipc	ra,0x0
    8000410a:	9f6080e7          	jalr	-1546(ra) # 80003afc <idup>
    8000410e:	89aa                	mv	s3,a0
  while(*path == '/')
    80004110:	02f00913          	li	s2,47
  len = path - s;
    80004114:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004116:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004118:	4b85                	li	s7,1
    8000411a:	a865                	j	800041d2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000411c:	4585                	li	a1,1
    8000411e:	4505                	li	a0,1
    80004120:	fffff097          	auipc	ra,0xfffff
    80004124:	6e6080e7          	jalr	1766(ra) # 80003806 <iget>
    80004128:	89aa                	mv	s3,a0
    8000412a:	b7dd                	j	80004110 <namex+0x42>
      iunlockput(ip);
    8000412c:	854e                	mv	a0,s3
    8000412e:	00000097          	auipc	ra,0x0
    80004132:	c6e080e7          	jalr	-914(ra) # 80003d9c <iunlockput>
      return 0;
    80004136:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004138:	854e                	mv	a0,s3
    8000413a:	60e6                	ld	ra,88(sp)
    8000413c:	6446                	ld	s0,80(sp)
    8000413e:	64a6                	ld	s1,72(sp)
    80004140:	6906                	ld	s2,64(sp)
    80004142:	79e2                	ld	s3,56(sp)
    80004144:	7a42                	ld	s4,48(sp)
    80004146:	7aa2                	ld	s5,40(sp)
    80004148:	7b02                	ld	s6,32(sp)
    8000414a:	6be2                	ld	s7,24(sp)
    8000414c:	6c42                	ld	s8,16(sp)
    8000414e:	6ca2                	ld	s9,8(sp)
    80004150:	6125                	addi	sp,sp,96
    80004152:	8082                	ret
      iunlock(ip);
    80004154:	854e                	mv	a0,s3
    80004156:	00000097          	auipc	ra,0x0
    8000415a:	aa6080e7          	jalr	-1370(ra) # 80003bfc <iunlock>
      return ip;
    8000415e:	bfe9                	j	80004138 <namex+0x6a>
      iunlockput(ip);
    80004160:	854e                	mv	a0,s3
    80004162:	00000097          	auipc	ra,0x0
    80004166:	c3a080e7          	jalr	-966(ra) # 80003d9c <iunlockput>
      return 0;
    8000416a:	89e6                	mv	s3,s9
    8000416c:	b7f1                	j	80004138 <namex+0x6a>
  len = path - s;
    8000416e:	40b48633          	sub	a2,s1,a1
    80004172:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004176:	099c5463          	bge	s8,s9,800041fe <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000417a:	4639                	li	a2,14
    8000417c:	8552                	mv	a0,s4
    8000417e:	ffffd097          	auipc	ra,0xffffd
    80004182:	b9c080e7          	jalr	-1124(ra) # 80000d1a <memmove>
  while(*path == '/')
    80004186:	0004c783          	lbu	a5,0(s1)
    8000418a:	01279763          	bne	a5,s2,80004198 <namex+0xca>
    path++;
    8000418e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004190:	0004c783          	lbu	a5,0(s1)
    80004194:	ff278de3          	beq	a5,s2,8000418e <namex+0xc0>
    ilock(ip);
    80004198:	854e                	mv	a0,s3
    8000419a:	00000097          	auipc	ra,0x0
    8000419e:	9a0080e7          	jalr	-1632(ra) # 80003b3a <ilock>
    if(ip->type != T_DIR){
    800041a2:	04499783          	lh	a5,68(s3)
    800041a6:	f97793e3          	bne	a5,s7,8000412c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800041aa:	000a8563          	beqz	s5,800041b4 <namex+0xe6>
    800041ae:	0004c783          	lbu	a5,0(s1)
    800041b2:	d3cd                	beqz	a5,80004154 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800041b4:	865a                	mv	a2,s6
    800041b6:	85d2                	mv	a1,s4
    800041b8:	854e                	mv	a0,s3
    800041ba:	00000097          	auipc	ra,0x0
    800041be:	e64080e7          	jalr	-412(ra) # 8000401e <dirlookup>
    800041c2:	8caa                	mv	s9,a0
    800041c4:	dd51                	beqz	a0,80004160 <namex+0x92>
    iunlockput(ip);
    800041c6:	854e                	mv	a0,s3
    800041c8:	00000097          	auipc	ra,0x0
    800041cc:	bd4080e7          	jalr	-1068(ra) # 80003d9c <iunlockput>
    ip = next;
    800041d0:	89e6                	mv	s3,s9
  while(*path == '/')
    800041d2:	0004c783          	lbu	a5,0(s1)
    800041d6:	05279763          	bne	a5,s2,80004224 <namex+0x156>
    path++;
    800041da:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041dc:	0004c783          	lbu	a5,0(s1)
    800041e0:	ff278de3          	beq	a5,s2,800041da <namex+0x10c>
  if(*path == 0)
    800041e4:	c79d                	beqz	a5,80004212 <namex+0x144>
    path++;
    800041e6:	85a6                	mv	a1,s1
  len = path - s;
    800041e8:	8cda                	mv	s9,s6
    800041ea:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800041ec:	01278963          	beq	a5,s2,800041fe <namex+0x130>
    800041f0:	dfbd                	beqz	a5,8000416e <namex+0xa0>
    path++;
    800041f2:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800041f4:	0004c783          	lbu	a5,0(s1)
    800041f8:	ff279ce3          	bne	a5,s2,800041f0 <namex+0x122>
    800041fc:	bf8d                	j	8000416e <namex+0xa0>
    memmove(name, s, len);
    800041fe:	2601                	sext.w	a2,a2
    80004200:	8552                	mv	a0,s4
    80004202:	ffffd097          	auipc	ra,0xffffd
    80004206:	b18080e7          	jalr	-1256(ra) # 80000d1a <memmove>
    name[len] = 0;
    8000420a:	9cd2                	add	s9,s9,s4
    8000420c:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004210:	bf9d                	j	80004186 <namex+0xb8>
  if(nameiparent){
    80004212:	f20a83e3          	beqz	s5,80004138 <namex+0x6a>
    iput(ip);
    80004216:	854e                	mv	a0,s3
    80004218:	00000097          	auipc	ra,0x0
    8000421c:	adc080e7          	jalr	-1316(ra) # 80003cf4 <iput>
    return 0;
    80004220:	4981                	li	s3,0
    80004222:	bf19                	j	80004138 <namex+0x6a>
  if(*path == 0)
    80004224:	d7fd                	beqz	a5,80004212 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004226:	0004c783          	lbu	a5,0(s1)
    8000422a:	85a6                	mv	a1,s1
    8000422c:	b7d1                	j	800041f0 <namex+0x122>

000000008000422e <dirlink>:
{
    8000422e:	7139                	addi	sp,sp,-64
    80004230:	fc06                	sd	ra,56(sp)
    80004232:	f822                	sd	s0,48(sp)
    80004234:	f426                	sd	s1,40(sp)
    80004236:	f04a                	sd	s2,32(sp)
    80004238:	ec4e                	sd	s3,24(sp)
    8000423a:	e852                	sd	s4,16(sp)
    8000423c:	0080                	addi	s0,sp,64
    8000423e:	892a                	mv	s2,a0
    80004240:	8a2e                	mv	s4,a1
    80004242:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004244:	4601                	li	a2,0
    80004246:	00000097          	auipc	ra,0x0
    8000424a:	dd8080e7          	jalr	-552(ra) # 8000401e <dirlookup>
    8000424e:	e93d                	bnez	a0,800042c4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004250:	04c92483          	lw	s1,76(s2)
    80004254:	c49d                	beqz	s1,80004282 <dirlink+0x54>
    80004256:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004258:	4741                	li	a4,16
    8000425a:	86a6                	mv	a3,s1
    8000425c:	fc040613          	addi	a2,s0,-64
    80004260:	4581                	li	a1,0
    80004262:	854a                	mv	a0,s2
    80004264:	00000097          	auipc	ra,0x0
    80004268:	b8a080e7          	jalr	-1142(ra) # 80003dee <readi>
    8000426c:	47c1                	li	a5,16
    8000426e:	06f51163          	bne	a0,a5,800042d0 <dirlink+0xa2>
    if(de.inum == 0)
    80004272:	fc045783          	lhu	a5,-64(s0)
    80004276:	c791                	beqz	a5,80004282 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004278:	24c1                	addiw	s1,s1,16
    8000427a:	04c92783          	lw	a5,76(s2)
    8000427e:	fcf4ede3          	bltu	s1,a5,80004258 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004282:	4639                	li	a2,14
    80004284:	85d2                	mv	a1,s4
    80004286:	fc240513          	addi	a0,s0,-62
    8000428a:	ffffd097          	auipc	ra,0xffffd
    8000428e:	b48080e7          	jalr	-1208(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004292:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004296:	4741                	li	a4,16
    80004298:	86a6                	mv	a3,s1
    8000429a:	fc040613          	addi	a2,s0,-64
    8000429e:	4581                	li	a1,0
    800042a0:	854a                	mv	a0,s2
    800042a2:	00000097          	auipc	ra,0x0
    800042a6:	c44080e7          	jalr	-956(ra) # 80003ee6 <writei>
    800042aa:	872a                	mv	a4,a0
    800042ac:	47c1                	li	a5,16
  return 0;
    800042ae:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042b0:	02f71863          	bne	a4,a5,800042e0 <dirlink+0xb2>
}
    800042b4:	70e2                	ld	ra,56(sp)
    800042b6:	7442                	ld	s0,48(sp)
    800042b8:	74a2                	ld	s1,40(sp)
    800042ba:	7902                	ld	s2,32(sp)
    800042bc:	69e2                	ld	s3,24(sp)
    800042be:	6a42                	ld	s4,16(sp)
    800042c0:	6121                	addi	sp,sp,64
    800042c2:	8082                	ret
    iput(ip);
    800042c4:	00000097          	auipc	ra,0x0
    800042c8:	a30080e7          	jalr	-1488(ra) # 80003cf4 <iput>
    return -1;
    800042cc:	557d                	li	a0,-1
    800042ce:	b7dd                	j	800042b4 <dirlink+0x86>
      panic("dirlink read");
    800042d0:	00004517          	auipc	a0,0x4
    800042d4:	52050513          	addi	a0,a0,1312 # 800087f0 <syscalls+0x1e0>
    800042d8:	ffffc097          	auipc	ra,0xffffc
    800042dc:	252080e7          	jalr	594(ra) # 8000052a <panic>
    panic("dirlink");
    800042e0:	00004517          	auipc	a0,0x4
    800042e4:	61850513          	addi	a0,a0,1560 # 800088f8 <syscalls+0x2e8>
    800042e8:	ffffc097          	auipc	ra,0xffffc
    800042ec:	242080e7          	jalr	578(ra) # 8000052a <panic>

00000000800042f0 <namei>:

struct inode*
namei(char *path)
{
    800042f0:	1101                	addi	sp,sp,-32
    800042f2:	ec06                	sd	ra,24(sp)
    800042f4:	e822                	sd	s0,16(sp)
    800042f6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042f8:	fe040613          	addi	a2,s0,-32
    800042fc:	4581                	li	a1,0
    800042fe:	00000097          	auipc	ra,0x0
    80004302:	dd0080e7          	jalr	-560(ra) # 800040ce <namex>
}
    80004306:	60e2                	ld	ra,24(sp)
    80004308:	6442                	ld	s0,16(sp)
    8000430a:	6105                	addi	sp,sp,32
    8000430c:	8082                	ret

000000008000430e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000430e:	1141                	addi	sp,sp,-16
    80004310:	e406                	sd	ra,8(sp)
    80004312:	e022                	sd	s0,0(sp)
    80004314:	0800                	addi	s0,sp,16
    80004316:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004318:	4585                	li	a1,1
    8000431a:	00000097          	auipc	ra,0x0
    8000431e:	db4080e7          	jalr	-588(ra) # 800040ce <namex>
}
    80004322:	60a2                	ld	ra,8(sp)
    80004324:	6402                	ld	s0,0(sp)
    80004326:	0141                	addi	sp,sp,16
    80004328:	8082                	ret

000000008000432a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000432a:	1101                	addi	sp,sp,-32
    8000432c:	ec06                	sd	ra,24(sp)
    8000432e:	e822                	sd	s0,16(sp)
    80004330:	e426                	sd	s1,8(sp)
    80004332:	e04a                	sd	s2,0(sp)
    80004334:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004336:	0001d917          	auipc	s2,0x1d
    8000433a:	53a90913          	addi	s2,s2,1338 # 80021870 <log>
    8000433e:	01892583          	lw	a1,24(s2)
    80004342:	02892503          	lw	a0,40(s2)
    80004346:	fffff097          	auipc	ra,0xfffff
    8000434a:	ff0080e7          	jalr	-16(ra) # 80003336 <bread>
    8000434e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004350:	02c92683          	lw	a3,44(s2)
    80004354:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004356:	02d05863          	blez	a3,80004386 <write_head+0x5c>
    8000435a:	0001d797          	auipc	a5,0x1d
    8000435e:	54678793          	addi	a5,a5,1350 # 800218a0 <log+0x30>
    80004362:	05c50713          	addi	a4,a0,92
    80004366:	36fd                	addiw	a3,a3,-1
    80004368:	02069613          	slli	a2,a3,0x20
    8000436c:	01e65693          	srli	a3,a2,0x1e
    80004370:	0001d617          	auipc	a2,0x1d
    80004374:	53460613          	addi	a2,a2,1332 # 800218a4 <log+0x34>
    80004378:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000437a:	4390                	lw	a2,0(a5)
    8000437c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000437e:	0791                	addi	a5,a5,4
    80004380:	0711                	addi	a4,a4,4
    80004382:	fed79ce3          	bne	a5,a3,8000437a <write_head+0x50>
  }
  bwrite(buf);
    80004386:	8526                	mv	a0,s1
    80004388:	fffff097          	auipc	ra,0xfffff
    8000438c:	0a0080e7          	jalr	160(ra) # 80003428 <bwrite>
  brelse(buf);
    80004390:	8526                	mv	a0,s1
    80004392:	fffff097          	auipc	ra,0xfffff
    80004396:	0d4080e7          	jalr	212(ra) # 80003466 <brelse>
}
    8000439a:	60e2                	ld	ra,24(sp)
    8000439c:	6442                	ld	s0,16(sp)
    8000439e:	64a2                	ld	s1,8(sp)
    800043a0:	6902                	ld	s2,0(sp)
    800043a2:	6105                	addi	sp,sp,32
    800043a4:	8082                	ret

00000000800043a6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a6:	0001d797          	auipc	a5,0x1d
    800043aa:	4f67a783          	lw	a5,1270(a5) # 8002189c <log+0x2c>
    800043ae:	0af05d63          	blez	a5,80004468 <install_trans+0xc2>
{
    800043b2:	7139                	addi	sp,sp,-64
    800043b4:	fc06                	sd	ra,56(sp)
    800043b6:	f822                	sd	s0,48(sp)
    800043b8:	f426                	sd	s1,40(sp)
    800043ba:	f04a                	sd	s2,32(sp)
    800043bc:	ec4e                	sd	s3,24(sp)
    800043be:	e852                	sd	s4,16(sp)
    800043c0:	e456                	sd	s5,8(sp)
    800043c2:	e05a                	sd	s6,0(sp)
    800043c4:	0080                	addi	s0,sp,64
    800043c6:	8b2a                	mv	s6,a0
    800043c8:	0001da97          	auipc	s5,0x1d
    800043cc:	4d8a8a93          	addi	s5,s5,1240 # 800218a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043d0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043d2:	0001d997          	auipc	s3,0x1d
    800043d6:	49e98993          	addi	s3,s3,1182 # 80021870 <log>
    800043da:	a00d                	j	800043fc <install_trans+0x56>
    brelse(lbuf);
    800043dc:	854a                	mv	a0,s2
    800043de:	fffff097          	auipc	ra,0xfffff
    800043e2:	088080e7          	jalr	136(ra) # 80003466 <brelse>
    brelse(dbuf);
    800043e6:	8526                	mv	a0,s1
    800043e8:	fffff097          	auipc	ra,0xfffff
    800043ec:	07e080e7          	jalr	126(ra) # 80003466 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043f0:	2a05                	addiw	s4,s4,1
    800043f2:	0a91                	addi	s5,s5,4
    800043f4:	02c9a783          	lw	a5,44(s3)
    800043f8:	04fa5e63          	bge	s4,a5,80004454 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043fc:	0189a583          	lw	a1,24(s3)
    80004400:	014585bb          	addw	a1,a1,s4
    80004404:	2585                	addiw	a1,a1,1
    80004406:	0289a503          	lw	a0,40(s3)
    8000440a:	fffff097          	auipc	ra,0xfffff
    8000440e:	f2c080e7          	jalr	-212(ra) # 80003336 <bread>
    80004412:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004414:	000aa583          	lw	a1,0(s5)
    80004418:	0289a503          	lw	a0,40(s3)
    8000441c:	fffff097          	auipc	ra,0xfffff
    80004420:	f1a080e7          	jalr	-230(ra) # 80003336 <bread>
    80004424:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004426:	40000613          	li	a2,1024
    8000442a:	05890593          	addi	a1,s2,88
    8000442e:	05850513          	addi	a0,a0,88
    80004432:	ffffd097          	auipc	ra,0xffffd
    80004436:	8e8080e7          	jalr	-1816(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    8000443a:	8526                	mv	a0,s1
    8000443c:	fffff097          	auipc	ra,0xfffff
    80004440:	fec080e7          	jalr	-20(ra) # 80003428 <bwrite>
    if(recovering == 0)
    80004444:	f80b1ce3          	bnez	s6,800043dc <install_trans+0x36>
      bunpin(dbuf);
    80004448:	8526                	mv	a0,s1
    8000444a:	fffff097          	auipc	ra,0xfffff
    8000444e:	0f6080e7          	jalr	246(ra) # 80003540 <bunpin>
    80004452:	b769                	j	800043dc <install_trans+0x36>
}
    80004454:	70e2                	ld	ra,56(sp)
    80004456:	7442                	ld	s0,48(sp)
    80004458:	74a2                	ld	s1,40(sp)
    8000445a:	7902                	ld	s2,32(sp)
    8000445c:	69e2                	ld	s3,24(sp)
    8000445e:	6a42                	ld	s4,16(sp)
    80004460:	6aa2                	ld	s5,8(sp)
    80004462:	6b02                	ld	s6,0(sp)
    80004464:	6121                	addi	sp,sp,64
    80004466:	8082                	ret
    80004468:	8082                	ret

000000008000446a <initlog>:
{
    8000446a:	7179                	addi	sp,sp,-48
    8000446c:	f406                	sd	ra,40(sp)
    8000446e:	f022                	sd	s0,32(sp)
    80004470:	ec26                	sd	s1,24(sp)
    80004472:	e84a                	sd	s2,16(sp)
    80004474:	e44e                	sd	s3,8(sp)
    80004476:	1800                	addi	s0,sp,48
    80004478:	892a                	mv	s2,a0
    8000447a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000447c:	0001d497          	auipc	s1,0x1d
    80004480:	3f448493          	addi	s1,s1,1012 # 80021870 <log>
    80004484:	00004597          	auipc	a1,0x4
    80004488:	37c58593          	addi	a1,a1,892 # 80008800 <syscalls+0x1f0>
    8000448c:	8526                	mv	a0,s1
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	6a4080e7          	jalr	1700(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004496:	0149a583          	lw	a1,20(s3)
    8000449a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000449c:	0109a783          	lw	a5,16(s3)
    800044a0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044a2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044a6:	854a                	mv	a0,s2
    800044a8:	fffff097          	auipc	ra,0xfffff
    800044ac:	e8e080e7          	jalr	-370(ra) # 80003336 <bread>
  log.lh.n = lh->n;
    800044b0:	4d34                	lw	a3,88(a0)
    800044b2:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800044b4:	02d05663          	blez	a3,800044e0 <initlog+0x76>
    800044b8:	05c50793          	addi	a5,a0,92
    800044bc:	0001d717          	auipc	a4,0x1d
    800044c0:	3e470713          	addi	a4,a4,996 # 800218a0 <log+0x30>
    800044c4:	36fd                	addiw	a3,a3,-1
    800044c6:	02069613          	slli	a2,a3,0x20
    800044ca:	01e65693          	srli	a3,a2,0x1e
    800044ce:	06050613          	addi	a2,a0,96
    800044d2:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800044d4:	4390                	lw	a2,0(a5)
    800044d6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044d8:	0791                	addi	a5,a5,4
    800044da:	0711                	addi	a4,a4,4
    800044dc:	fed79ce3          	bne	a5,a3,800044d4 <initlog+0x6a>
  brelse(buf);
    800044e0:	fffff097          	auipc	ra,0xfffff
    800044e4:	f86080e7          	jalr	-122(ra) # 80003466 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044e8:	4505                	li	a0,1
    800044ea:	00000097          	auipc	ra,0x0
    800044ee:	ebc080e7          	jalr	-324(ra) # 800043a6 <install_trans>
  log.lh.n = 0;
    800044f2:	0001d797          	auipc	a5,0x1d
    800044f6:	3a07a523          	sw	zero,938(a5) # 8002189c <log+0x2c>
  write_head(); // clear the log
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	e30080e7          	jalr	-464(ra) # 8000432a <write_head>
}
    80004502:	70a2                	ld	ra,40(sp)
    80004504:	7402                	ld	s0,32(sp)
    80004506:	64e2                	ld	s1,24(sp)
    80004508:	6942                	ld	s2,16(sp)
    8000450a:	69a2                	ld	s3,8(sp)
    8000450c:	6145                	addi	sp,sp,48
    8000450e:	8082                	ret

0000000080004510 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004510:	1101                	addi	sp,sp,-32
    80004512:	ec06                	sd	ra,24(sp)
    80004514:	e822                	sd	s0,16(sp)
    80004516:	e426                	sd	s1,8(sp)
    80004518:	e04a                	sd	s2,0(sp)
    8000451a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000451c:	0001d517          	auipc	a0,0x1d
    80004520:	35450513          	addi	a0,a0,852 # 80021870 <log>
    80004524:	ffffc097          	auipc	ra,0xffffc
    80004528:	69e080e7          	jalr	1694(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    8000452c:	0001d497          	auipc	s1,0x1d
    80004530:	34448493          	addi	s1,s1,836 # 80021870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004534:	4979                	li	s2,30
    80004536:	a039                	j	80004544 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004538:	85a6                	mv	a1,s1
    8000453a:	8526                	mv	a0,s1
    8000453c:	ffffe097          	auipc	ra,0xffffe
    80004540:	c62080e7          	jalr	-926(ra) # 8000219e <sleep>
    if(log.committing){
    80004544:	50dc                	lw	a5,36(s1)
    80004546:	fbed                	bnez	a5,80004538 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004548:	509c                	lw	a5,32(s1)
    8000454a:	0017871b          	addiw	a4,a5,1
    8000454e:	0007069b          	sext.w	a3,a4
    80004552:	0027179b          	slliw	a5,a4,0x2
    80004556:	9fb9                	addw	a5,a5,a4
    80004558:	0017979b          	slliw	a5,a5,0x1
    8000455c:	54d8                	lw	a4,44(s1)
    8000455e:	9fb9                	addw	a5,a5,a4
    80004560:	00f95963          	bge	s2,a5,80004572 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004564:	85a6                	mv	a1,s1
    80004566:	8526                	mv	a0,s1
    80004568:	ffffe097          	auipc	ra,0xffffe
    8000456c:	c36080e7          	jalr	-970(ra) # 8000219e <sleep>
    80004570:	bfd1                	j	80004544 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004572:	0001d517          	auipc	a0,0x1d
    80004576:	2fe50513          	addi	a0,a0,766 # 80021870 <log>
    8000457a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	6fa080e7          	jalr	1786(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004584:	60e2                	ld	ra,24(sp)
    80004586:	6442                	ld	s0,16(sp)
    80004588:	64a2                	ld	s1,8(sp)
    8000458a:	6902                	ld	s2,0(sp)
    8000458c:	6105                	addi	sp,sp,32
    8000458e:	8082                	ret

0000000080004590 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004590:	7139                	addi	sp,sp,-64
    80004592:	fc06                	sd	ra,56(sp)
    80004594:	f822                	sd	s0,48(sp)
    80004596:	f426                	sd	s1,40(sp)
    80004598:	f04a                	sd	s2,32(sp)
    8000459a:	ec4e                	sd	s3,24(sp)
    8000459c:	e852                	sd	s4,16(sp)
    8000459e:	e456                	sd	s5,8(sp)
    800045a0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045a2:	0001d497          	auipc	s1,0x1d
    800045a6:	2ce48493          	addi	s1,s1,718 # 80021870 <log>
    800045aa:	8526                	mv	a0,s1
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	616080e7          	jalr	1558(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    800045b4:	509c                	lw	a5,32(s1)
    800045b6:	37fd                	addiw	a5,a5,-1
    800045b8:	0007891b          	sext.w	s2,a5
    800045bc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800045be:	50dc                	lw	a5,36(s1)
    800045c0:	e7b9                	bnez	a5,8000460e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800045c2:	04091e63          	bnez	s2,8000461e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800045c6:	0001d497          	auipc	s1,0x1d
    800045ca:	2aa48493          	addi	s1,s1,682 # 80021870 <log>
    800045ce:	4785                	li	a5,1
    800045d0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045d2:	8526                	mv	a0,s1
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	6a2080e7          	jalr	1698(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800045dc:	54dc                	lw	a5,44(s1)
    800045de:	06f04763          	bgtz	a5,8000464c <end_op+0xbc>
    acquire(&log.lock);
    800045e2:	0001d497          	auipc	s1,0x1d
    800045e6:	28e48493          	addi	s1,s1,654 # 80021870 <log>
    800045ea:	8526                	mv	a0,s1
    800045ec:	ffffc097          	auipc	ra,0xffffc
    800045f0:	5d6080e7          	jalr	1494(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800045f4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045f8:	8526                	mv	a0,s1
    800045fa:	ffffe097          	auipc	ra,0xffffe
    800045fe:	d30080e7          	jalr	-720(ra) # 8000232a <wakeup>
    release(&log.lock);
    80004602:	8526                	mv	a0,s1
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	672080e7          	jalr	1650(ra) # 80000c76 <release>
}
    8000460c:	a03d                	j	8000463a <end_op+0xaa>
    panic("log.committing");
    8000460e:	00004517          	auipc	a0,0x4
    80004612:	1fa50513          	addi	a0,a0,506 # 80008808 <syscalls+0x1f8>
    80004616:	ffffc097          	auipc	ra,0xffffc
    8000461a:	f14080e7          	jalr	-236(ra) # 8000052a <panic>
    wakeup(&log);
    8000461e:	0001d497          	auipc	s1,0x1d
    80004622:	25248493          	addi	s1,s1,594 # 80021870 <log>
    80004626:	8526                	mv	a0,s1
    80004628:	ffffe097          	auipc	ra,0xffffe
    8000462c:	d02080e7          	jalr	-766(ra) # 8000232a <wakeup>
  release(&log.lock);
    80004630:	8526                	mv	a0,s1
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	644080e7          	jalr	1604(ra) # 80000c76 <release>
}
    8000463a:	70e2                	ld	ra,56(sp)
    8000463c:	7442                	ld	s0,48(sp)
    8000463e:	74a2                	ld	s1,40(sp)
    80004640:	7902                	ld	s2,32(sp)
    80004642:	69e2                	ld	s3,24(sp)
    80004644:	6a42                	ld	s4,16(sp)
    80004646:	6aa2                	ld	s5,8(sp)
    80004648:	6121                	addi	sp,sp,64
    8000464a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000464c:	0001da97          	auipc	s5,0x1d
    80004650:	254a8a93          	addi	s5,s5,596 # 800218a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004654:	0001da17          	auipc	s4,0x1d
    80004658:	21ca0a13          	addi	s4,s4,540 # 80021870 <log>
    8000465c:	018a2583          	lw	a1,24(s4)
    80004660:	012585bb          	addw	a1,a1,s2
    80004664:	2585                	addiw	a1,a1,1
    80004666:	028a2503          	lw	a0,40(s4)
    8000466a:	fffff097          	auipc	ra,0xfffff
    8000466e:	ccc080e7          	jalr	-820(ra) # 80003336 <bread>
    80004672:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004674:	000aa583          	lw	a1,0(s5)
    80004678:	028a2503          	lw	a0,40(s4)
    8000467c:	fffff097          	auipc	ra,0xfffff
    80004680:	cba080e7          	jalr	-838(ra) # 80003336 <bread>
    80004684:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004686:	40000613          	li	a2,1024
    8000468a:	05850593          	addi	a1,a0,88
    8000468e:	05848513          	addi	a0,s1,88
    80004692:	ffffc097          	auipc	ra,0xffffc
    80004696:	688080e7          	jalr	1672(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    8000469a:	8526                	mv	a0,s1
    8000469c:	fffff097          	auipc	ra,0xfffff
    800046a0:	d8c080e7          	jalr	-628(ra) # 80003428 <bwrite>
    brelse(from);
    800046a4:	854e                	mv	a0,s3
    800046a6:	fffff097          	auipc	ra,0xfffff
    800046aa:	dc0080e7          	jalr	-576(ra) # 80003466 <brelse>
    brelse(to);
    800046ae:	8526                	mv	a0,s1
    800046b0:	fffff097          	auipc	ra,0xfffff
    800046b4:	db6080e7          	jalr	-586(ra) # 80003466 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046b8:	2905                	addiw	s2,s2,1
    800046ba:	0a91                	addi	s5,s5,4
    800046bc:	02ca2783          	lw	a5,44(s4)
    800046c0:	f8f94ee3          	blt	s2,a5,8000465c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800046c4:	00000097          	auipc	ra,0x0
    800046c8:	c66080e7          	jalr	-922(ra) # 8000432a <write_head>
    install_trans(0); // Now install writes to home locations
    800046cc:	4501                	li	a0,0
    800046ce:	00000097          	auipc	ra,0x0
    800046d2:	cd8080e7          	jalr	-808(ra) # 800043a6 <install_trans>
    log.lh.n = 0;
    800046d6:	0001d797          	auipc	a5,0x1d
    800046da:	1c07a323          	sw	zero,454(a5) # 8002189c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800046de:	00000097          	auipc	ra,0x0
    800046e2:	c4c080e7          	jalr	-948(ra) # 8000432a <write_head>
    800046e6:	bdf5                	j	800045e2 <end_op+0x52>

00000000800046e8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046e8:	1101                	addi	sp,sp,-32
    800046ea:	ec06                	sd	ra,24(sp)
    800046ec:	e822                	sd	s0,16(sp)
    800046ee:	e426                	sd	s1,8(sp)
    800046f0:	e04a                	sd	s2,0(sp)
    800046f2:	1000                	addi	s0,sp,32
    800046f4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046f6:	0001d917          	auipc	s2,0x1d
    800046fa:	17a90913          	addi	s2,s2,378 # 80021870 <log>
    800046fe:	854a                	mv	a0,s2
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	4c2080e7          	jalr	1218(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004708:	02c92603          	lw	a2,44(s2)
    8000470c:	47f5                	li	a5,29
    8000470e:	06c7c563          	blt	a5,a2,80004778 <log_write+0x90>
    80004712:	0001d797          	auipc	a5,0x1d
    80004716:	17a7a783          	lw	a5,378(a5) # 8002188c <log+0x1c>
    8000471a:	37fd                	addiw	a5,a5,-1
    8000471c:	04f65e63          	bge	a2,a5,80004778 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004720:	0001d797          	auipc	a5,0x1d
    80004724:	1707a783          	lw	a5,368(a5) # 80021890 <log+0x20>
    80004728:	06f05063          	blez	a5,80004788 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000472c:	4781                	li	a5,0
    8000472e:	06c05563          	blez	a2,80004798 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004732:	44cc                	lw	a1,12(s1)
    80004734:	0001d717          	auipc	a4,0x1d
    80004738:	16c70713          	addi	a4,a4,364 # 800218a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000473c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000473e:	4314                	lw	a3,0(a4)
    80004740:	04b68c63          	beq	a3,a1,80004798 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004744:	2785                	addiw	a5,a5,1
    80004746:	0711                	addi	a4,a4,4
    80004748:	fef61be3          	bne	a2,a5,8000473e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000474c:	0621                	addi	a2,a2,8
    8000474e:	060a                	slli	a2,a2,0x2
    80004750:	0001d797          	auipc	a5,0x1d
    80004754:	12078793          	addi	a5,a5,288 # 80021870 <log>
    80004758:	963e                	add	a2,a2,a5
    8000475a:	44dc                	lw	a5,12(s1)
    8000475c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000475e:	8526                	mv	a0,s1
    80004760:	fffff097          	auipc	ra,0xfffff
    80004764:	da4080e7          	jalr	-604(ra) # 80003504 <bpin>
    log.lh.n++;
    80004768:	0001d717          	auipc	a4,0x1d
    8000476c:	10870713          	addi	a4,a4,264 # 80021870 <log>
    80004770:	575c                	lw	a5,44(a4)
    80004772:	2785                	addiw	a5,a5,1
    80004774:	d75c                	sw	a5,44(a4)
    80004776:	a835                	j	800047b2 <log_write+0xca>
    panic("too big a transaction");
    80004778:	00004517          	auipc	a0,0x4
    8000477c:	0a050513          	addi	a0,a0,160 # 80008818 <syscalls+0x208>
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	daa080e7          	jalr	-598(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004788:	00004517          	auipc	a0,0x4
    8000478c:	0a850513          	addi	a0,a0,168 # 80008830 <syscalls+0x220>
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	d9a080e7          	jalr	-614(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004798:	00878713          	addi	a4,a5,8
    8000479c:	00271693          	slli	a3,a4,0x2
    800047a0:	0001d717          	auipc	a4,0x1d
    800047a4:	0d070713          	addi	a4,a4,208 # 80021870 <log>
    800047a8:	9736                	add	a4,a4,a3
    800047aa:	44d4                	lw	a3,12(s1)
    800047ac:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047ae:	faf608e3          	beq	a2,a5,8000475e <log_write+0x76>
  }
  release(&log.lock);
    800047b2:	0001d517          	auipc	a0,0x1d
    800047b6:	0be50513          	addi	a0,a0,190 # 80021870 <log>
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	4bc080e7          	jalr	1212(ra) # 80000c76 <release>
}
    800047c2:	60e2                	ld	ra,24(sp)
    800047c4:	6442                	ld	s0,16(sp)
    800047c6:	64a2                	ld	s1,8(sp)
    800047c8:	6902                	ld	s2,0(sp)
    800047ca:	6105                	addi	sp,sp,32
    800047cc:	8082                	ret

00000000800047ce <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800047ce:	1101                	addi	sp,sp,-32
    800047d0:	ec06                	sd	ra,24(sp)
    800047d2:	e822                	sd	s0,16(sp)
    800047d4:	e426                	sd	s1,8(sp)
    800047d6:	e04a                	sd	s2,0(sp)
    800047d8:	1000                	addi	s0,sp,32
    800047da:	84aa                	mv	s1,a0
    800047dc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800047de:	00004597          	auipc	a1,0x4
    800047e2:	07258593          	addi	a1,a1,114 # 80008850 <syscalls+0x240>
    800047e6:	0521                	addi	a0,a0,8
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	34a080e7          	jalr	842(ra) # 80000b32 <initlock>
  lk->name = name;
    800047f0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047f4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047f8:	0204a423          	sw	zero,40(s1)
}
    800047fc:	60e2                	ld	ra,24(sp)
    800047fe:	6442                	ld	s0,16(sp)
    80004800:	64a2                	ld	s1,8(sp)
    80004802:	6902                	ld	s2,0(sp)
    80004804:	6105                	addi	sp,sp,32
    80004806:	8082                	ret

0000000080004808 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004808:	1101                	addi	sp,sp,-32
    8000480a:	ec06                	sd	ra,24(sp)
    8000480c:	e822                	sd	s0,16(sp)
    8000480e:	e426                	sd	s1,8(sp)
    80004810:	e04a                	sd	s2,0(sp)
    80004812:	1000                	addi	s0,sp,32
    80004814:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004816:	00850913          	addi	s2,a0,8
    8000481a:	854a                	mv	a0,s2
    8000481c:	ffffc097          	auipc	ra,0xffffc
    80004820:	3a6080e7          	jalr	934(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004824:	409c                	lw	a5,0(s1)
    80004826:	cb89                	beqz	a5,80004838 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004828:	85ca                	mv	a1,s2
    8000482a:	8526                	mv	a0,s1
    8000482c:	ffffe097          	auipc	ra,0xffffe
    80004830:	972080e7          	jalr	-1678(ra) # 8000219e <sleep>
  while (lk->locked) {
    80004834:	409c                	lw	a5,0(s1)
    80004836:	fbed                	bnez	a5,80004828 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004838:	4785                	li	a5,1
    8000483a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000483c:	ffffd097          	auipc	ra,0xffffd
    80004840:	142080e7          	jalr	322(ra) # 8000197e <myproc>
    80004844:	591c                	lw	a5,48(a0)
    80004846:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004848:	854a                	mv	a0,s2
    8000484a:	ffffc097          	auipc	ra,0xffffc
    8000484e:	42c080e7          	jalr	1068(ra) # 80000c76 <release>
}
    80004852:	60e2                	ld	ra,24(sp)
    80004854:	6442                	ld	s0,16(sp)
    80004856:	64a2                	ld	s1,8(sp)
    80004858:	6902                	ld	s2,0(sp)
    8000485a:	6105                	addi	sp,sp,32
    8000485c:	8082                	ret

000000008000485e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000485e:	1101                	addi	sp,sp,-32
    80004860:	ec06                	sd	ra,24(sp)
    80004862:	e822                	sd	s0,16(sp)
    80004864:	e426                	sd	s1,8(sp)
    80004866:	e04a                	sd	s2,0(sp)
    80004868:	1000                	addi	s0,sp,32
    8000486a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000486c:	00850913          	addi	s2,a0,8
    80004870:	854a                	mv	a0,s2
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	350080e7          	jalr	848(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    8000487a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000487e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004882:	8526                	mv	a0,s1
    80004884:	ffffe097          	auipc	ra,0xffffe
    80004888:	aa6080e7          	jalr	-1370(ra) # 8000232a <wakeup>
  release(&lk->lk);
    8000488c:	854a                	mv	a0,s2
    8000488e:	ffffc097          	auipc	ra,0xffffc
    80004892:	3e8080e7          	jalr	1000(ra) # 80000c76 <release>
}
    80004896:	60e2                	ld	ra,24(sp)
    80004898:	6442                	ld	s0,16(sp)
    8000489a:	64a2                	ld	s1,8(sp)
    8000489c:	6902                	ld	s2,0(sp)
    8000489e:	6105                	addi	sp,sp,32
    800048a0:	8082                	ret

00000000800048a2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048a2:	7179                	addi	sp,sp,-48
    800048a4:	f406                	sd	ra,40(sp)
    800048a6:	f022                	sd	s0,32(sp)
    800048a8:	ec26                	sd	s1,24(sp)
    800048aa:	e84a                	sd	s2,16(sp)
    800048ac:	e44e                	sd	s3,8(sp)
    800048ae:	1800                	addi	s0,sp,48
    800048b0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048b2:	00850913          	addi	s2,a0,8
    800048b6:	854a                	mv	a0,s2
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	30a080e7          	jalr	778(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800048c0:	409c                	lw	a5,0(s1)
    800048c2:	ef99                	bnez	a5,800048e0 <holdingsleep+0x3e>
    800048c4:	4481                	li	s1,0
  release(&lk->lk);
    800048c6:	854a                	mv	a0,s2
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	3ae080e7          	jalr	942(ra) # 80000c76 <release>
  return r;
}
    800048d0:	8526                	mv	a0,s1
    800048d2:	70a2                	ld	ra,40(sp)
    800048d4:	7402                	ld	s0,32(sp)
    800048d6:	64e2                	ld	s1,24(sp)
    800048d8:	6942                	ld	s2,16(sp)
    800048da:	69a2                	ld	s3,8(sp)
    800048dc:	6145                	addi	sp,sp,48
    800048de:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800048e0:	0284a983          	lw	s3,40(s1)
    800048e4:	ffffd097          	auipc	ra,0xffffd
    800048e8:	09a080e7          	jalr	154(ra) # 8000197e <myproc>
    800048ec:	5904                	lw	s1,48(a0)
    800048ee:	413484b3          	sub	s1,s1,s3
    800048f2:	0014b493          	seqz	s1,s1
    800048f6:	bfc1                	j	800048c6 <holdingsleep+0x24>

00000000800048f8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048f8:	1141                	addi	sp,sp,-16
    800048fa:	e406                	sd	ra,8(sp)
    800048fc:	e022                	sd	s0,0(sp)
    800048fe:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004900:	00004597          	auipc	a1,0x4
    80004904:	f6058593          	addi	a1,a1,-160 # 80008860 <syscalls+0x250>
    80004908:	0001d517          	auipc	a0,0x1d
    8000490c:	0b050513          	addi	a0,a0,176 # 800219b8 <ftable>
    80004910:	ffffc097          	auipc	ra,0xffffc
    80004914:	222080e7          	jalr	546(ra) # 80000b32 <initlock>
}
    80004918:	60a2                	ld	ra,8(sp)
    8000491a:	6402                	ld	s0,0(sp)
    8000491c:	0141                	addi	sp,sp,16
    8000491e:	8082                	ret

0000000080004920 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004920:	1101                	addi	sp,sp,-32
    80004922:	ec06                	sd	ra,24(sp)
    80004924:	e822                	sd	s0,16(sp)
    80004926:	e426                	sd	s1,8(sp)
    80004928:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000492a:	0001d517          	auipc	a0,0x1d
    8000492e:	08e50513          	addi	a0,a0,142 # 800219b8 <ftable>
    80004932:	ffffc097          	auipc	ra,0xffffc
    80004936:	290080e7          	jalr	656(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000493a:	0001d497          	auipc	s1,0x1d
    8000493e:	09648493          	addi	s1,s1,150 # 800219d0 <ftable+0x18>
    80004942:	0001e717          	auipc	a4,0x1e
    80004946:	02e70713          	addi	a4,a4,46 # 80022970 <ftable+0xfb8>
    if(f->ref == 0){
    8000494a:	40dc                	lw	a5,4(s1)
    8000494c:	cf99                	beqz	a5,8000496a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000494e:	02848493          	addi	s1,s1,40
    80004952:	fee49ce3          	bne	s1,a4,8000494a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004956:	0001d517          	auipc	a0,0x1d
    8000495a:	06250513          	addi	a0,a0,98 # 800219b8 <ftable>
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	318080e7          	jalr	792(ra) # 80000c76 <release>
  return 0;
    80004966:	4481                	li	s1,0
    80004968:	a819                	j	8000497e <filealloc+0x5e>
      f->ref = 1;
    8000496a:	4785                	li	a5,1
    8000496c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000496e:	0001d517          	auipc	a0,0x1d
    80004972:	04a50513          	addi	a0,a0,74 # 800219b8 <ftable>
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	300080e7          	jalr	768(ra) # 80000c76 <release>
}
    8000497e:	8526                	mv	a0,s1
    80004980:	60e2                	ld	ra,24(sp)
    80004982:	6442                	ld	s0,16(sp)
    80004984:	64a2                	ld	s1,8(sp)
    80004986:	6105                	addi	sp,sp,32
    80004988:	8082                	ret

000000008000498a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000498a:	1101                	addi	sp,sp,-32
    8000498c:	ec06                	sd	ra,24(sp)
    8000498e:	e822                	sd	s0,16(sp)
    80004990:	e426                	sd	s1,8(sp)
    80004992:	1000                	addi	s0,sp,32
    80004994:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004996:	0001d517          	auipc	a0,0x1d
    8000499a:	02250513          	addi	a0,a0,34 # 800219b8 <ftable>
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	224080e7          	jalr	548(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800049a6:	40dc                	lw	a5,4(s1)
    800049a8:	02f05263          	blez	a5,800049cc <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049ac:	2785                	addiw	a5,a5,1
    800049ae:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049b0:	0001d517          	auipc	a0,0x1d
    800049b4:	00850513          	addi	a0,a0,8 # 800219b8 <ftable>
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	2be080e7          	jalr	702(ra) # 80000c76 <release>
  return f;
}
    800049c0:	8526                	mv	a0,s1
    800049c2:	60e2                	ld	ra,24(sp)
    800049c4:	6442                	ld	s0,16(sp)
    800049c6:	64a2                	ld	s1,8(sp)
    800049c8:	6105                	addi	sp,sp,32
    800049ca:	8082                	ret
    panic("filedup");
    800049cc:	00004517          	auipc	a0,0x4
    800049d0:	e9c50513          	addi	a0,a0,-356 # 80008868 <syscalls+0x258>
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	b56080e7          	jalr	-1194(ra) # 8000052a <panic>

00000000800049dc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800049dc:	7139                	addi	sp,sp,-64
    800049de:	fc06                	sd	ra,56(sp)
    800049e0:	f822                	sd	s0,48(sp)
    800049e2:	f426                	sd	s1,40(sp)
    800049e4:	f04a                	sd	s2,32(sp)
    800049e6:	ec4e                	sd	s3,24(sp)
    800049e8:	e852                	sd	s4,16(sp)
    800049ea:	e456                	sd	s5,8(sp)
    800049ec:	0080                	addi	s0,sp,64
    800049ee:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049f0:	0001d517          	auipc	a0,0x1d
    800049f4:	fc850513          	addi	a0,a0,-56 # 800219b8 <ftable>
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	1ca080e7          	jalr	458(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004a00:	40dc                	lw	a5,4(s1)
    80004a02:	06f05163          	blez	a5,80004a64 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a06:	37fd                	addiw	a5,a5,-1
    80004a08:	0007871b          	sext.w	a4,a5
    80004a0c:	c0dc                	sw	a5,4(s1)
    80004a0e:	06e04363          	bgtz	a4,80004a74 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a12:	0004a903          	lw	s2,0(s1)
    80004a16:	0094ca83          	lbu	s5,9(s1)
    80004a1a:	0104ba03          	ld	s4,16(s1)
    80004a1e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a22:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a26:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a2a:	0001d517          	auipc	a0,0x1d
    80004a2e:	f8e50513          	addi	a0,a0,-114 # 800219b8 <ftable>
    80004a32:	ffffc097          	auipc	ra,0xffffc
    80004a36:	244080e7          	jalr	580(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004a3a:	4785                	li	a5,1
    80004a3c:	04f90d63          	beq	s2,a5,80004a96 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a40:	3979                	addiw	s2,s2,-2
    80004a42:	4785                	li	a5,1
    80004a44:	0527e063          	bltu	a5,s2,80004a84 <fileclose+0xa8>
    begin_op();
    80004a48:	00000097          	auipc	ra,0x0
    80004a4c:	ac8080e7          	jalr	-1336(ra) # 80004510 <begin_op>
    iput(ff.ip);
    80004a50:	854e                	mv	a0,s3
    80004a52:	fffff097          	auipc	ra,0xfffff
    80004a56:	2a2080e7          	jalr	674(ra) # 80003cf4 <iput>
    end_op();
    80004a5a:	00000097          	auipc	ra,0x0
    80004a5e:	b36080e7          	jalr	-1226(ra) # 80004590 <end_op>
    80004a62:	a00d                	j	80004a84 <fileclose+0xa8>
    panic("fileclose");
    80004a64:	00004517          	auipc	a0,0x4
    80004a68:	e0c50513          	addi	a0,a0,-500 # 80008870 <syscalls+0x260>
    80004a6c:	ffffc097          	auipc	ra,0xffffc
    80004a70:	abe080e7          	jalr	-1346(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004a74:	0001d517          	auipc	a0,0x1d
    80004a78:	f4450513          	addi	a0,a0,-188 # 800219b8 <ftable>
    80004a7c:	ffffc097          	auipc	ra,0xffffc
    80004a80:	1fa080e7          	jalr	506(ra) # 80000c76 <release>
  }
}
    80004a84:	70e2                	ld	ra,56(sp)
    80004a86:	7442                	ld	s0,48(sp)
    80004a88:	74a2                	ld	s1,40(sp)
    80004a8a:	7902                	ld	s2,32(sp)
    80004a8c:	69e2                	ld	s3,24(sp)
    80004a8e:	6a42                	ld	s4,16(sp)
    80004a90:	6aa2                	ld	s5,8(sp)
    80004a92:	6121                	addi	sp,sp,64
    80004a94:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a96:	85d6                	mv	a1,s5
    80004a98:	8552                	mv	a0,s4
    80004a9a:	00000097          	auipc	ra,0x0
    80004a9e:	34c080e7          	jalr	844(ra) # 80004de6 <pipeclose>
    80004aa2:	b7cd                	j	80004a84 <fileclose+0xa8>

0000000080004aa4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004aa4:	715d                	addi	sp,sp,-80
    80004aa6:	e486                	sd	ra,72(sp)
    80004aa8:	e0a2                	sd	s0,64(sp)
    80004aaa:	fc26                	sd	s1,56(sp)
    80004aac:	f84a                	sd	s2,48(sp)
    80004aae:	f44e                	sd	s3,40(sp)
    80004ab0:	0880                	addi	s0,sp,80
    80004ab2:	84aa                	mv	s1,a0
    80004ab4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ab6:	ffffd097          	auipc	ra,0xffffd
    80004aba:	ec8080e7          	jalr	-312(ra) # 8000197e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004abe:	409c                	lw	a5,0(s1)
    80004ac0:	37f9                	addiw	a5,a5,-2
    80004ac2:	4705                	li	a4,1
    80004ac4:	04f76763          	bltu	a4,a5,80004b12 <filestat+0x6e>
    80004ac8:	892a                	mv	s2,a0
    ilock(f->ip);
    80004aca:	6c88                	ld	a0,24(s1)
    80004acc:	fffff097          	auipc	ra,0xfffff
    80004ad0:	06e080e7          	jalr	110(ra) # 80003b3a <ilock>
    stati(f->ip, &st);
    80004ad4:	fb840593          	addi	a1,s0,-72
    80004ad8:	6c88                	ld	a0,24(s1)
    80004ada:	fffff097          	auipc	ra,0xfffff
    80004ade:	2ea080e7          	jalr	746(ra) # 80003dc4 <stati>
    iunlock(f->ip);
    80004ae2:	6c88                	ld	a0,24(s1)
    80004ae4:	fffff097          	auipc	ra,0xfffff
    80004ae8:	118080e7          	jalr	280(ra) # 80003bfc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004aec:	46e1                	li	a3,24
    80004aee:	fb840613          	addi	a2,s0,-72
    80004af2:	85ce                	mv	a1,s3
    80004af4:	06893503          	ld	a0,104(s2)
    80004af8:	ffffd097          	auipc	ra,0xffffd
    80004afc:	b46080e7          	jalr	-1210(ra) # 8000163e <copyout>
    80004b00:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b04:	60a6                	ld	ra,72(sp)
    80004b06:	6406                	ld	s0,64(sp)
    80004b08:	74e2                	ld	s1,56(sp)
    80004b0a:	7942                	ld	s2,48(sp)
    80004b0c:	79a2                	ld	s3,40(sp)
    80004b0e:	6161                	addi	sp,sp,80
    80004b10:	8082                	ret
  return -1;
    80004b12:	557d                	li	a0,-1
    80004b14:	bfc5                	j	80004b04 <filestat+0x60>

0000000080004b16 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b16:	7179                	addi	sp,sp,-48
    80004b18:	f406                	sd	ra,40(sp)
    80004b1a:	f022                	sd	s0,32(sp)
    80004b1c:	ec26                	sd	s1,24(sp)
    80004b1e:	e84a                	sd	s2,16(sp)
    80004b20:	e44e                	sd	s3,8(sp)
    80004b22:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b24:	00854783          	lbu	a5,8(a0)
    80004b28:	c3d5                	beqz	a5,80004bcc <fileread+0xb6>
    80004b2a:	84aa                	mv	s1,a0
    80004b2c:	89ae                	mv	s3,a1
    80004b2e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b30:	411c                	lw	a5,0(a0)
    80004b32:	4705                	li	a4,1
    80004b34:	04e78963          	beq	a5,a4,80004b86 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b38:	470d                	li	a4,3
    80004b3a:	04e78d63          	beq	a5,a4,80004b94 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b3e:	4709                	li	a4,2
    80004b40:	06e79e63          	bne	a5,a4,80004bbc <fileread+0xa6>
    ilock(f->ip);
    80004b44:	6d08                	ld	a0,24(a0)
    80004b46:	fffff097          	auipc	ra,0xfffff
    80004b4a:	ff4080e7          	jalr	-12(ra) # 80003b3a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b4e:	874a                	mv	a4,s2
    80004b50:	5094                	lw	a3,32(s1)
    80004b52:	864e                	mv	a2,s3
    80004b54:	4585                	li	a1,1
    80004b56:	6c88                	ld	a0,24(s1)
    80004b58:	fffff097          	auipc	ra,0xfffff
    80004b5c:	296080e7          	jalr	662(ra) # 80003dee <readi>
    80004b60:	892a                	mv	s2,a0
    80004b62:	00a05563          	blez	a0,80004b6c <fileread+0x56>
      f->off += r;
    80004b66:	509c                	lw	a5,32(s1)
    80004b68:	9fa9                	addw	a5,a5,a0
    80004b6a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b6c:	6c88                	ld	a0,24(s1)
    80004b6e:	fffff097          	auipc	ra,0xfffff
    80004b72:	08e080e7          	jalr	142(ra) # 80003bfc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b76:	854a                	mv	a0,s2
    80004b78:	70a2                	ld	ra,40(sp)
    80004b7a:	7402                	ld	s0,32(sp)
    80004b7c:	64e2                	ld	s1,24(sp)
    80004b7e:	6942                	ld	s2,16(sp)
    80004b80:	69a2                	ld	s3,8(sp)
    80004b82:	6145                	addi	sp,sp,48
    80004b84:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b86:	6908                	ld	a0,16(a0)
    80004b88:	00000097          	auipc	ra,0x0
    80004b8c:	3c0080e7          	jalr	960(ra) # 80004f48 <piperead>
    80004b90:	892a                	mv	s2,a0
    80004b92:	b7d5                	j	80004b76 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b94:	02451783          	lh	a5,36(a0)
    80004b98:	03079693          	slli	a3,a5,0x30
    80004b9c:	92c1                	srli	a3,a3,0x30
    80004b9e:	4725                	li	a4,9
    80004ba0:	02d76863          	bltu	a4,a3,80004bd0 <fileread+0xba>
    80004ba4:	0792                	slli	a5,a5,0x4
    80004ba6:	0001d717          	auipc	a4,0x1d
    80004baa:	d7270713          	addi	a4,a4,-654 # 80021918 <devsw>
    80004bae:	97ba                	add	a5,a5,a4
    80004bb0:	639c                	ld	a5,0(a5)
    80004bb2:	c38d                	beqz	a5,80004bd4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004bb4:	4505                	li	a0,1
    80004bb6:	9782                	jalr	a5
    80004bb8:	892a                	mv	s2,a0
    80004bba:	bf75                	j	80004b76 <fileread+0x60>
    panic("fileread");
    80004bbc:	00004517          	auipc	a0,0x4
    80004bc0:	cc450513          	addi	a0,a0,-828 # 80008880 <syscalls+0x270>
    80004bc4:	ffffc097          	auipc	ra,0xffffc
    80004bc8:	966080e7          	jalr	-1690(ra) # 8000052a <panic>
    return -1;
    80004bcc:	597d                	li	s2,-1
    80004bce:	b765                	j	80004b76 <fileread+0x60>
      return -1;
    80004bd0:	597d                	li	s2,-1
    80004bd2:	b755                	j	80004b76 <fileread+0x60>
    80004bd4:	597d                	li	s2,-1
    80004bd6:	b745                	j	80004b76 <fileread+0x60>

0000000080004bd8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004bd8:	715d                	addi	sp,sp,-80
    80004bda:	e486                	sd	ra,72(sp)
    80004bdc:	e0a2                	sd	s0,64(sp)
    80004bde:	fc26                	sd	s1,56(sp)
    80004be0:	f84a                	sd	s2,48(sp)
    80004be2:	f44e                	sd	s3,40(sp)
    80004be4:	f052                	sd	s4,32(sp)
    80004be6:	ec56                	sd	s5,24(sp)
    80004be8:	e85a                	sd	s6,16(sp)
    80004bea:	e45e                	sd	s7,8(sp)
    80004bec:	e062                	sd	s8,0(sp)
    80004bee:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004bf0:	00954783          	lbu	a5,9(a0)
    80004bf4:	10078663          	beqz	a5,80004d00 <filewrite+0x128>
    80004bf8:	892a                	mv	s2,a0
    80004bfa:	8aae                	mv	s5,a1
    80004bfc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bfe:	411c                	lw	a5,0(a0)
    80004c00:	4705                	li	a4,1
    80004c02:	02e78263          	beq	a5,a4,80004c26 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c06:	470d                	li	a4,3
    80004c08:	02e78663          	beq	a5,a4,80004c34 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c0c:	4709                	li	a4,2
    80004c0e:	0ee79163          	bne	a5,a4,80004cf0 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c12:	0ac05d63          	blez	a2,80004ccc <filewrite+0xf4>
    int i = 0;
    80004c16:	4981                	li	s3,0
    80004c18:	6b05                	lui	s6,0x1
    80004c1a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c1e:	6b85                	lui	s7,0x1
    80004c20:	c00b8b9b          	addiw	s7,s7,-1024
    80004c24:	a861                	j	80004cbc <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c26:	6908                	ld	a0,16(a0)
    80004c28:	00000097          	auipc	ra,0x0
    80004c2c:	22e080e7          	jalr	558(ra) # 80004e56 <pipewrite>
    80004c30:	8a2a                	mv	s4,a0
    80004c32:	a045                	j	80004cd2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c34:	02451783          	lh	a5,36(a0)
    80004c38:	03079693          	slli	a3,a5,0x30
    80004c3c:	92c1                	srli	a3,a3,0x30
    80004c3e:	4725                	li	a4,9
    80004c40:	0cd76263          	bltu	a4,a3,80004d04 <filewrite+0x12c>
    80004c44:	0792                	slli	a5,a5,0x4
    80004c46:	0001d717          	auipc	a4,0x1d
    80004c4a:	cd270713          	addi	a4,a4,-814 # 80021918 <devsw>
    80004c4e:	97ba                	add	a5,a5,a4
    80004c50:	679c                	ld	a5,8(a5)
    80004c52:	cbdd                	beqz	a5,80004d08 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c54:	4505                	li	a0,1
    80004c56:	9782                	jalr	a5
    80004c58:	8a2a                	mv	s4,a0
    80004c5a:	a8a5                	j	80004cd2 <filewrite+0xfa>
    80004c5c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c60:	00000097          	auipc	ra,0x0
    80004c64:	8b0080e7          	jalr	-1872(ra) # 80004510 <begin_op>
      ilock(f->ip);
    80004c68:	01893503          	ld	a0,24(s2)
    80004c6c:	fffff097          	auipc	ra,0xfffff
    80004c70:	ece080e7          	jalr	-306(ra) # 80003b3a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c74:	8762                	mv	a4,s8
    80004c76:	02092683          	lw	a3,32(s2)
    80004c7a:	01598633          	add	a2,s3,s5
    80004c7e:	4585                	li	a1,1
    80004c80:	01893503          	ld	a0,24(s2)
    80004c84:	fffff097          	auipc	ra,0xfffff
    80004c88:	262080e7          	jalr	610(ra) # 80003ee6 <writei>
    80004c8c:	84aa                	mv	s1,a0
    80004c8e:	00a05763          	blez	a0,80004c9c <filewrite+0xc4>
        f->off += r;
    80004c92:	02092783          	lw	a5,32(s2)
    80004c96:	9fa9                	addw	a5,a5,a0
    80004c98:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c9c:	01893503          	ld	a0,24(s2)
    80004ca0:	fffff097          	auipc	ra,0xfffff
    80004ca4:	f5c080e7          	jalr	-164(ra) # 80003bfc <iunlock>
      end_op();
    80004ca8:	00000097          	auipc	ra,0x0
    80004cac:	8e8080e7          	jalr	-1816(ra) # 80004590 <end_op>

      if(r != n1){
    80004cb0:	009c1f63          	bne	s8,s1,80004cce <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004cb4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004cb8:	0149db63          	bge	s3,s4,80004cce <filewrite+0xf6>
      int n1 = n - i;
    80004cbc:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004cc0:	84be                	mv	s1,a5
    80004cc2:	2781                	sext.w	a5,a5
    80004cc4:	f8fb5ce3          	bge	s6,a5,80004c5c <filewrite+0x84>
    80004cc8:	84de                	mv	s1,s7
    80004cca:	bf49                	j	80004c5c <filewrite+0x84>
    int i = 0;
    80004ccc:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004cce:	013a1f63          	bne	s4,s3,80004cec <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004cd2:	8552                	mv	a0,s4
    80004cd4:	60a6                	ld	ra,72(sp)
    80004cd6:	6406                	ld	s0,64(sp)
    80004cd8:	74e2                	ld	s1,56(sp)
    80004cda:	7942                	ld	s2,48(sp)
    80004cdc:	79a2                	ld	s3,40(sp)
    80004cde:	7a02                	ld	s4,32(sp)
    80004ce0:	6ae2                	ld	s5,24(sp)
    80004ce2:	6b42                	ld	s6,16(sp)
    80004ce4:	6ba2                	ld	s7,8(sp)
    80004ce6:	6c02                	ld	s8,0(sp)
    80004ce8:	6161                	addi	sp,sp,80
    80004cea:	8082                	ret
    ret = (i == n ? n : -1);
    80004cec:	5a7d                	li	s4,-1
    80004cee:	b7d5                	j	80004cd2 <filewrite+0xfa>
    panic("filewrite");
    80004cf0:	00004517          	auipc	a0,0x4
    80004cf4:	ba050513          	addi	a0,a0,-1120 # 80008890 <syscalls+0x280>
    80004cf8:	ffffc097          	auipc	ra,0xffffc
    80004cfc:	832080e7          	jalr	-1998(ra) # 8000052a <panic>
    return -1;
    80004d00:	5a7d                	li	s4,-1
    80004d02:	bfc1                	j	80004cd2 <filewrite+0xfa>
      return -1;
    80004d04:	5a7d                	li	s4,-1
    80004d06:	b7f1                	j	80004cd2 <filewrite+0xfa>
    80004d08:	5a7d                	li	s4,-1
    80004d0a:	b7e1                	j	80004cd2 <filewrite+0xfa>

0000000080004d0c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d0c:	7179                	addi	sp,sp,-48
    80004d0e:	f406                	sd	ra,40(sp)
    80004d10:	f022                	sd	s0,32(sp)
    80004d12:	ec26                	sd	s1,24(sp)
    80004d14:	e84a                	sd	s2,16(sp)
    80004d16:	e44e                	sd	s3,8(sp)
    80004d18:	e052                	sd	s4,0(sp)
    80004d1a:	1800                	addi	s0,sp,48
    80004d1c:	84aa                	mv	s1,a0
    80004d1e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d20:	0005b023          	sd	zero,0(a1)
    80004d24:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d28:	00000097          	auipc	ra,0x0
    80004d2c:	bf8080e7          	jalr	-1032(ra) # 80004920 <filealloc>
    80004d30:	e088                	sd	a0,0(s1)
    80004d32:	c551                	beqz	a0,80004dbe <pipealloc+0xb2>
    80004d34:	00000097          	auipc	ra,0x0
    80004d38:	bec080e7          	jalr	-1044(ra) # 80004920 <filealloc>
    80004d3c:	00aa3023          	sd	a0,0(s4)
    80004d40:	c92d                	beqz	a0,80004db2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d42:	ffffc097          	auipc	ra,0xffffc
    80004d46:	d90080e7          	jalr	-624(ra) # 80000ad2 <kalloc>
    80004d4a:	892a                	mv	s2,a0
    80004d4c:	c125                	beqz	a0,80004dac <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d4e:	4985                	li	s3,1
    80004d50:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d54:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d58:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d5c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d60:	00003597          	auipc	a1,0x3
    80004d64:	72858593          	addi	a1,a1,1832 # 80008488 <states.0+0x1e0>
    80004d68:	ffffc097          	auipc	ra,0xffffc
    80004d6c:	dca080e7          	jalr	-566(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004d70:	609c                	ld	a5,0(s1)
    80004d72:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d76:	609c                	ld	a5,0(s1)
    80004d78:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d7c:	609c                	ld	a5,0(s1)
    80004d7e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d82:	609c                	ld	a5,0(s1)
    80004d84:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d88:	000a3783          	ld	a5,0(s4)
    80004d8c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d90:	000a3783          	ld	a5,0(s4)
    80004d94:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d98:	000a3783          	ld	a5,0(s4)
    80004d9c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004da0:	000a3783          	ld	a5,0(s4)
    80004da4:	0127b823          	sd	s2,16(a5)
  return 0;
    80004da8:	4501                	li	a0,0
    80004daa:	a025                	j	80004dd2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004dac:	6088                	ld	a0,0(s1)
    80004dae:	e501                	bnez	a0,80004db6 <pipealloc+0xaa>
    80004db0:	a039                	j	80004dbe <pipealloc+0xb2>
    80004db2:	6088                	ld	a0,0(s1)
    80004db4:	c51d                	beqz	a0,80004de2 <pipealloc+0xd6>
    fileclose(*f0);
    80004db6:	00000097          	auipc	ra,0x0
    80004dba:	c26080e7          	jalr	-986(ra) # 800049dc <fileclose>
  if(*f1)
    80004dbe:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004dc2:	557d                	li	a0,-1
  if(*f1)
    80004dc4:	c799                	beqz	a5,80004dd2 <pipealloc+0xc6>
    fileclose(*f1);
    80004dc6:	853e                	mv	a0,a5
    80004dc8:	00000097          	auipc	ra,0x0
    80004dcc:	c14080e7          	jalr	-1004(ra) # 800049dc <fileclose>
  return -1;
    80004dd0:	557d                	li	a0,-1
}
    80004dd2:	70a2                	ld	ra,40(sp)
    80004dd4:	7402                	ld	s0,32(sp)
    80004dd6:	64e2                	ld	s1,24(sp)
    80004dd8:	6942                	ld	s2,16(sp)
    80004dda:	69a2                	ld	s3,8(sp)
    80004ddc:	6a02                	ld	s4,0(sp)
    80004dde:	6145                	addi	sp,sp,48
    80004de0:	8082                	ret
  return -1;
    80004de2:	557d                	li	a0,-1
    80004de4:	b7fd                	j	80004dd2 <pipealloc+0xc6>

0000000080004de6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004de6:	1101                	addi	sp,sp,-32
    80004de8:	ec06                	sd	ra,24(sp)
    80004dea:	e822                	sd	s0,16(sp)
    80004dec:	e426                	sd	s1,8(sp)
    80004dee:	e04a                	sd	s2,0(sp)
    80004df0:	1000                	addi	s0,sp,32
    80004df2:	84aa                	mv	s1,a0
    80004df4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004df6:	ffffc097          	auipc	ra,0xffffc
    80004dfa:	dcc080e7          	jalr	-564(ra) # 80000bc2 <acquire>
  if(writable){
    80004dfe:	02090d63          	beqz	s2,80004e38 <pipeclose+0x52>
    pi->writeopen = 0;
    80004e02:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e06:	21848513          	addi	a0,s1,536
    80004e0a:	ffffd097          	auipc	ra,0xffffd
    80004e0e:	520080e7          	jalr	1312(ra) # 8000232a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e12:	2204b783          	ld	a5,544(s1)
    80004e16:	eb95                	bnez	a5,80004e4a <pipeclose+0x64>
    release(&pi->lock);
    80004e18:	8526                	mv	a0,s1
    80004e1a:	ffffc097          	auipc	ra,0xffffc
    80004e1e:	e5c080e7          	jalr	-420(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004e22:	8526                	mv	a0,s1
    80004e24:	ffffc097          	auipc	ra,0xffffc
    80004e28:	bb2080e7          	jalr	-1102(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004e2c:	60e2                	ld	ra,24(sp)
    80004e2e:	6442                	ld	s0,16(sp)
    80004e30:	64a2                	ld	s1,8(sp)
    80004e32:	6902                	ld	s2,0(sp)
    80004e34:	6105                	addi	sp,sp,32
    80004e36:	8082                	ret
    pi->readopen = 0;
    80004e38:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e3c:	21c48513          	addi	a0,s1,540
    80004e40:	ffffd097          	auipc	ra,0xffffd
    80004e44:	4ea080e7          	jalr	1258(ra) # 8000232a <wakeup>
    80004e48:	b7e9                	j	80004e12 <pipeclose+0x2c>
    release(&pi->lock);
    80004e4a:	8526                	mv	a0,s1
    80004e4c:	ffffc097          	auipc	ra,0xffffc
    80004e50:	e2a080e7          	jalr	-470(ra) # 80000c76 <release>
}
    80004e54:	bfe1                	j	80004e2c <pipeclose+0x46>

0000000080004e56 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e56:	711d                	addi	sp,sp,-96
    80004e58:	ec86                	sd	ra,88(sp)
    80004e5a:	e8a2                	sd	s0,80(sp)
    80004e5c:	e4a6                	sd	s1,72(sp)
    80004e5e:	e0ca                	sd	s2,64(sp)
    80004e60:	fc4e                	sd	s3,56(sp)
    80004e62:	f852                	sd	s4,48(sp)
    80004e64:	f456                	sd	s5,40(sp)
    80004e66:	f05a                	sd	s6,32(sp)
    80004e68:	ec5e                	sd	s7,24(sp)
    80004e6a:	e862                	sd	s8,16(sp)
    80004e6c:	1080                	addi	s0,sp,96
    80004e6e:	84aa                	mv	s1,a0
    80004e70:	8aae                	mv	s5,a1
    80004e72:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e74:	ffffd097          	auipc	ra,0xffffd
    80004e78:	b0a080e7          	jalr	-1270(ra) # 8000197e <myproc>
    80004e7c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e7e:	8526                	mv	a0,s1
    80004e80:	ffffc097          	auipc	ra,0xffffc
    80004e84:	d42080e7          	jalr	-702(ra) # 80000bc2 <acquire>
  while(i < n){
    80004e88:	0b405363          	blez	s4,80004f2e <pipewrite+0xd8>
  int i = 0;
    80004e8c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e8e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e90:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e94:	21c48b93          	addi	s7,s1,540
    80004e98:	a089                	j	80004eda <pipewrite+0x84>
      release(&pi->lock);
    80004e9a:	8526                	mv	a0,s1
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	dda080e7          	jalr	-550(ra) # 80000c76 <release>
      return -1;
    80004ea4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ea6:	854a                	mv	a0,s2
    80004ea8:	60e6                	ld	ra,88(sp)
    80004eaa:	6446                	ld	s0,80(sp)
    80004eac:	64a6                	ld	s1,72(sp)
    80004eae:	6906                	ld	s2,64(sp)
    80004eb0:	79e2                	ld	s3,56(sp)
    80004eb2:	7a42                	ld	s4,48(sp)
    80004eb4:	7aa2                	ld	s5,40(sp)
    80004eb6:	7b02                	ld	s6,32(sp)
    80004eb8:	6be2                	ld	s7,24(sp)
    80004eba:	6c42                	ld	s8,16(sp)
    80004ebc:	6125                	addi	sp,sp,96
    80004ebe:	8082                	ret
      wakeup(&pi->nread);
    80004ec0:	8562                	mv	a0,s8
    80004ec2:	ffffd097          	auipc	ra,0xffffd
    80004ec6:	468080e7          	jalr	1128(ra) # 8000232a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004eca:	85a6                	mv	a1,s1
    80004ecc:	855e                	mv	a0,s7
    80004ece:	ffffd097          	auipc	ra,0xffffd
    80004ed2:	2d0080e7          	jalr	720(ra) # 8000219e <sleep>
  while(i < n){
    80004ed6:	05495d63          	bge	s2,s4,80004f30 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004eda:	2204a783          	lw	a5,544(s1)
    80004ede:	dfd5                	beqz	a5,80004e9a <pipewrite+0x44>
    80004ee0:	0289a783          	lw	a5,40(s3)
    80004ee4:	fbdd                	bnez	a5,80004e9a <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ee6:	2184a783          	lw	a5,536(s1)
    80004eea:	21c4a703          	lw	a4,540(s1)
    80004eee:	2007879b          	addiw	a5,a5,512
    80004ef2:	fcf707e3          	beq	a4,a5,80004ec0 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ef6:	4685                	li	a3,1
    80004ef8:	01590633          	add	a2,s2,s5
    80004efc:	faf40593          	addi	a1,s0,-81
    80004f00:	0689b503          	ld	a0,104(s3)
    80004f04:	ffffc097          	auipc	ra,0xffffc
    80004f08:	7c6080e7          	jalr	1990(ra) # 800016ca <copyin>
    80004f0c:	03650263          	beq	a0,s6,80004f30 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f10:	21c4a783          	lw	a5,540(s1)
    80004f14:	0017871b          	addiw	a4,a5,1
    80004f18:	20e4ae23          	sw	a4,540(s1)
    80004f1c:	1ff7f793          	andi	a5,a5,511
    80004f20:	97a6                	add	a5,a5,s1
    80004f22:	faf44703          	lbu	a4,-81(s0)
    80004f26:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f2a:	2905                	addiw	s2,s2,1
    80004f2c:	b76d                	j	80004ed6 <pipewrite+0x80>
  int i = 0;
    80004f2e:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f30:	21848513          	addi	a0,s1,536
    80004f34:	ffffd097          	auipc	ra,0xffffd
    80004f38:	3f6080e7          	jalr	1014(ra) # 8000232a <wakeup>
  release(&pi->lock);
    80004f3c:	8526                	mv	a0,s1
    80004f3e:	ffffc097          	auipc	ra,0xffffc
    80004f42:	d38080e7          	jalr	-712(ra) # 80000c76 <release>
  return i;
    80004f46:	b785                	j	80004ea6 <pipewrite+0x50>

0000000080004f48 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f48:	715d                	addi	sp,sp,-80
    80004f4a:	e486                	sd	ra,72(sp)
    80004f4c:	e0a2                	sd	s0,64(sp)
    80004f4e:	fc26                	sd	s1,56(sp)
    80004f50:	f84a                	sd	s2,48(sp)
    80004f52:	f44e                	sd	s3,40(sp)
    80004f54:	f052                	sd	s4,32(sp)
    80004f56:	ec56                	sd	s5,24(sp)
    80004f58:	e85a                	sd	s6,16(sp)
    80004f5a:	0880                	addi	s0,sp,80
    80004f5c:	84aa                	mv	s1,a0
    80004f5e:	892e                	mv	s2,a1
    80004f60:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f62:	ffffd097          	auipc	ra,0xffffd
    80004f66:	a1c080e7          	jalr	-1508(ra) # 8000197e <myproc>
    80004f6a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f6c:	8526                	mv	a0,s1
    80004f6e:	ffffc097          	auipc	ra,0xffffc
    80004f72:	c54080e7          	jalr	-940(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f76:	2184a703          	lw	a4,536(s1)
    80004f7a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f7e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f82:	02f71463          	bne	a4,a5,80004faa <piperead+0x62>
    80004f86:	2244a783          	lw	a5,548(s1)
    80004f8a:	c385                	beqz	a5,80004faa <piperead+0x62>
    if(pr->killed){
    80004f8c:	028a2783          	lw	a5,40(s4)
    80004f90:	ebc1                	bnez	a5,80005020 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f92:	85a6                	mv	a1,s1
    80004f94:	854e                	mv	a0,s3
    80004f96:	ffffd097          	auipc	ra,0xffffd
    80004f9a:	208080e7          	jalr	520(ra) # 8000219e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f9e:	2184a703          	lw	a4,536(s1)
    80004fa2:	21c4a783          	lw	a5,540(s1)
    80004fa6:	fef700e3          	beq	a4,a5,80004f86 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004faa:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fac:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fae:	05505363          	blez	s5,80004ff4 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004fb2:	2184a783          	lw	a5,536(s1)
    80004fb6:	21c4a703          	lw	a4,540(s1)
    80004fba:	02f70d63          	beq	a4,a5,80004ff4 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004fbe:	0017871b          	addiw	a4,a5,1
    80004fc2:	20e4ac23          	sw	a4,536(s1)
    80004fc6:	1ff7f793          	andi	a5,a5,511
    80004fca:	97a6                	add	a5,a5,s1
    80004fcc:	0187c783          	lbu	a5,24(a5)
    80004fd0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fd4:	4685                	li	a3,1
    80004fd6:	fbf40613          	addi	a2,s0,-65
    80004fda:	85ca                	mv	a1,s2
    80004fdc:	068a3503          	ld	a0,104(s4)
    80004fe0:	ffffc097          	auipc	ra,0xffffc
    80004fe4:	65e080e7          	jalr	1630(ra) # 8000163e <copyout>
    80004fe8:	01650663          	beq	a0,s6,80004ff4 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fec:	2985                	addiw	s3,s3,1
    80004fee:	0905                	addi	s2,s2,1
    80004ff0:	fd3a91e3          	bne	s5,s3,80004fb2 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ff4:	21c48513          	addi	a0,s1,540
    80004ff8:	ffffd097          	auipc	ra,0xffffd
    80004ffc:	332080e7          	jalr	818(ra) # 8000232a <wakeup>
  release(&pi->lock);
    80005000:	8526                	mv	a0,s1
    80005002:	ffffc097          	auipc	ra,0xffffc
    80005006:	c74080e7          	jalr	-908(ra) # 80000c76 <release>
  return i;
}
    8000500a:	854e                	mv	a0,s3
    8000500c:	60a6                	ld	ra,72(sp)
    8000500e:	6406                	ld	s0,64(sp)
    80005010:	74e2                	ld	s1,56(sp)
    80005012:	7942                	ld	s2,48(sp)
    80005014:	79a2                	ld	s3,40(sp)
    80005016:	7a02                	ld	s4,32(sp)
    80005018:	6ae2                	ld	s5,24(sp)
    8000501a:	6b42                	ld	s6,16(sp)
    8000501c:	6161                	addi	sp,sp,80
    8000501e:	8082                	ret
      release(&pi->lock);
    80005020:	8526                	mv	a0,s1
    80005022:	ffffc097          	auipc	ra,0xffffc
    80005026:	c54080e7          	jalr	-940(ra) # 80000c76 <release>
      return -1;
    8000502a:	59fd                	li	s3,-1
    8000502c:	bff9                	j	8000500a <piperead+0xc2>

000000008000502e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000502e:	de010113          	addi	sp,sp,-544
    80005032:	20113c23          	sd	ra,536(sp)
    80005036:	20813823          	sd	s0,528(sp)
    8000503a:	20913423          	sd	s1,520(sp)
    8000503e:	21213023          	sd	s2,512(sp)
    80005042:	ffce                	sd	s3,504(sp)
    80005044:	fbd2                	sd	s4,496(sp)
    80005046:	f7d6                	sd	s5,488(sp)
    80005048:	f3da                	sd	s6,480(sp)
    8000504a:	efde                	sd	s7,472(sp)
    8000504c:	ebe2                	sd	s8,464(sp)
    8000504e:	e7e6                	sd	s9,456(sp)
    80005050:	e3ea                	sd	s10,448(sp)
    80005052:	ff6e                	sd	s11,440(sp)
    80005054:	1400                	addi	s0,sp,544
    80005056:	892a                	mv	s2,a0
    80005058:	dea43423          	sd	a0,-536(s0)
    8000505c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005060:	ffffd097          	auipc	ra,0xffffd
    80005064:	91e080e7          	jalr	-1762(ra) # 8000197e <myproc>
    80005068:	84aa                	mv	s1,a0

  begin_op();
    8000506a:	fffff097          	auipc	ra,0xfffff
    8000506e:	4a6080e7          	jalr	1190(ra) # 80004510 <begin_op>

  if((ip = namei(path)) == 0){
    80005072:	854a                	mv	a0,s2
    80005074:	fffff097          	auipc	ra,0xfffff
    80005078:	27c080e7          	jalr	636(ra) # 800042f0 <namei>
    8000507c:	c93d                	beqz	a0,800050f2 <exec+0xc4>
    8000507e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005080:	fffff097          	auipc	ra,0xfffff
    80005084:	aba080e7          	jalr	-1350(ra) # 80003b3a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005088:	04000713          	li	a4,64
    8000508c:	4681                	li	a3,0
    8000508e:	e4840613          	addi	a2,s0,-440
    80005092:	4581                	li	a1,0
    80005094:	8556                	mv	a0,s5
    80005096:	fffff097          	auipc	ra,0xfffff
    8000509a:	d58080e7          	jalr	-680(ra) # 80003dee <readi>
    8000509e:	04000793          	li	a5,64
    800050a2:	00f51a63          	bne	a0,a5,800050b6 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800050a6:	e4842703          	lw	a4,-440(s0)
    800050aa:	464c47b7          	lui	a5,0x464c4
    800050ae:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050b2:	04f70663          	beq	a4,a5,800050fe <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050b6:	8556                	mv	a0,s5
    800050b8:	fffff097          	auipc	ra,0xfffff
    800050bc:	ce4080e7          	jalr	-796(ra) # 80003d9c <iunlockput>
    end_op();
    800050c0:	fffff097          	auipc	ra,0xfffff
    800050c4:	4d0080e7          	jalr	1232(ra) # 80004590 <end_op>
  }
  return -1;
    800050c8:	557d                	li	a0,-1
}
    800050ca:	21813083          	ld	ra,536(sp)
    800050ce:	21013403          	ld	s0,528(sp)
    800050d2:	20813483          	ld	s1,520(sp)
    800050d6:	20013903          	ld	s2,512(sp)
    800050da:	79fe                	ld	s3,504(sp)
    800050dc:	7a5e                	ld	s4,496(sp)
    800050de:	7abe                	ld	s5,488(sp)
    800050e0:	7b1e                	ld	s6,480(sp)
    800050e2:	6bfe                	ld	s7,472(sp)
    800050e4:	6c5e                	ld	s8,464(sp)
    800050e6:	6cbe                	ld	s9,456(sp)
    800050e8:	6d1e                	ld	s10,448(sp)
    800050ea:	7dfa                	ld	s11,440(sp)
    800050ec:	22010113          	addi	sp,sp,544
    800050f0:	8082                	ret
    end_op();
    800050f2:	fffff097          	auipc	ra,0xfffff
    800050f6:	49e080e7          	jalr	1182(ra) # 80004590 <end_op>
    return -1;
    800050fa:	557d                	li	a0,-1
    800050fc:	b7f9                	j	800050ca <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800050fe:	8526                	mv	a0,s1
    80005100:	ffffd097          	auipc	ra,0xffffd
    80005104:	942080e7          	jalr	-1726(ra) # 80001a42 <proc_pagetable>
    80005108:	8b2a                	mv	s6,a0
    8000510a:	d555                	beqz	a0,800050b6 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000510c:	e6842783          	lw	a5,-408(s0)
    80005110:	e8045703          	lhu	a4,-384(s0)
    80005114:	c735                	beqz	a4,80005180 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005116:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005118:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000511c:	6a05                	lui	s4,0x1
    8000511e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005122:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005126:	6d85                	lui	s11,0x1
    80005128:	7d7d                	lui	s10,0xfffff
    8000512a:	ac1d                	j	80005360 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000512c:	00003517          	auipc	a0,0x3
    80005130:	77450513          	addi	a0,a0,1908 # 800088a0 <syscalls+0x290>
    80005134:	ffffb097          	auipc	ra,0xffffb
    80005138:	3f6080e7          	jalr	1014(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000513c:	874a                	mv	a4,s2
    8000513e:	009c86bb          	addw	a3,s9,s1
    80005142:	4581                	li	a1,0
    80005144:	8556                	mv	a0,s5
    80005146:	fffff097          	auipc	ra,0xfffff
    8000514a:	ca8080e7          	jalr	-856(ra) # 80003dee <readi>
    8000514e:	2501                	sext.w	a0,a0
    80005150:	1aa91863          	bne	s2,a0,80005300 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80005154:	009d84bb          	addw	s1,s11,s1
    80005158:	013d09bb          	addw	s3,s10,s3
    8000515c:	1f74f263          	bgeu	s1,s7,80005340 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005160:	02049593          	slli	a1,s1,0x20
    80005164:	9181                	srli	a1,a1,0x20
    80005166:	95e2                	add	a1,a1,s8
    80005168:	855a                	mv	a0,s6
    8000516a:	ffffc097          	auipc	ra,0xffffc
    8000516e:	ee2080e7          	jalr	-286(ra) # 8000104c <walkaddr>
    80005172:	862a                	mv	a2,a0
    if(pa == 0)
    80005174:	dd45                	beqz	a0,8000512c <exec+0xfe>
      n = PGSIZE;
    80005176:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005178:	fd49f2e3          	bgeu	s3,s4,8000513c <exec+0x10e>
      n = sz - i;
    8000517c:	894e                	mv	s2,s3
    8000517e:	bf7d                	j	8000513c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005180:	4481                	li	s1,0
  iunlockput(ip);
    80005182:	8556                	mv	a0,s5
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	c18080e7          	jalr	-1000(ra) # 80003d9c <iunlockput>
  end_op();
    8000518c:	fffff097          	auipc	ra,0xfffff
    80005190:	404080e7          	jalr	1028(ra) # 80004590 <end_op>
  p = myproc();
    80005194:	ffffc097          	auipc	ra,0xffffc
    80005198:	7ea080e7          	jalr	2026(ra) # 8000197e <myproc>
    8000519c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000519e:	06053d03          	ld	s10,96(a0)
  sz = PGROUNDUP(sz);
    800051a2:	6785                	lui	a5,0x1
    800051a4:	17fd                	addi	a5,a5,-1
    800051a6:	94be                	add	s1,s1,a5
    800051a8:	77fd                	lui	a5,0xfffff
    800051aa:	8fe5                	and	a5,a5,s1
    800051ac:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051b0:	6609                	lui	a2,0x2
    800051b2:	963e                	add	a2,a2,a5
    800051b4:	85be                	mv	a1,a5
    800051b6:	855a                	mv	a0,s6
    800051b8:	ffffc097          	auipc	ra,0xffffc
    800051bc:	236080e7          	jalr	566(ra) # 800013ee <uvmalloc>
    800051c0:	8c2a                	mv	s8,a0
  ip = 0;
    800051c2:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051c4:	12050e63          	beqz	a0,80005300 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    800051c8:	75f9                	lui	a1,0xffffe
    800051ca:	95aa                	add	a1,a1,a0
    800051cc:	855a                	mv	a0,s6
    800051ce:	ffffc097          	auipc	ra,0xffffc
    800051d2:	43e080e7          	jalr	1086(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    800051d6:	7afd                	lui	s5,0xfffff
    800051d8:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800051da:	df043783          	ld	a5,-528(s0)
    800051de:	6388                	ld	a0,0(a5)
    800051e0:	c925                	beqz	a0,80005250 <exec+0x222>
    800051e2:	e8840993          	addi	s3,s0,-376
    800051e6:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    800051ea:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051ec:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800051ee:	ffffc097          	auipc	ra,0xffffc
    800051f2:	c54080e7          	jalr	-940(ra) # 80000e42 <strlen>
    800051f6:	0015079b          	addiw	a5,a0,1
    800051fa:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051fe:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005202:	13596363          	bltu	s2,s5,80005328 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005206:	df043d83          	ld	s11,-528(s0)
    8000520a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000520e:	8552                	mv	a0,s4
    80005210:	ffffc097          	auipc	ra,0xffffc
    80005214:	c32080e7          	jalr	-974(ra) # 80000e42 <strlen>
    80005218:	0015069b          	addiw	a3,a0,1
    8000521c:	8652                	mv	a2,s4
    8000521e:	85ca                	mv	a1,s2
    80005220:	855a                	mv	a0,s6
    80005222:	ffffc097          	auipc	ra,0xffffc
    80005226:	41c080e7          	jalr	1052(ra) # 8000163e <copyout>
    8000522a:	10054363          	bltz	a0,80005330 <exec+0x302>
    ustack[argc] = sp;
    8000522e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005232:	0485                	addi	s1,s1,1
    80005234:	008d8793          	addi	a5,s11,8
    80005238:	def43823          	sd	a5,-528(s0)
    8000523c:	008db503          	ld	a0,8(s11)
    80005240:	c911                	beqz	a0,80005254 <exec+0x226>
    if(argc >= MAXARG)
    80005242:	09a1                	addi	s3,s3,8
    80005244:	fb3c95e3          	bne	s9,s3,800051ee <exec+0x1c0>
  sz = sz1;
    80005248:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000524c:	4a81                	li	s5,0
    8000524e:	a84d                	j	80005300 <exec+0x2d2>
  sp = sz;
    80005250:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005252:	4481                	li	s1,0
  ustack[argc] = 0;
    80005254:	00349793          	slli	a5,s1,0x3
    80005258:	f9040713          	addi	a4,s0,-112
    8000525c:	97ba                	add	a5,a5,a4
    8000525e:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80005262:	00148693          	addi	a3,s1,1
    80005266:	068e                	slli	a3,a3,0x3
    80005268:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000526c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005270:	01597663          	bgeu	s2,s5,8000527c <exec+0x24e>
  sz = sz1;
    80005274:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005278:	4a81                	li	s5,0
    8000527a:	a059                	j	80005300 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000527c:	e8840613          	addi	a2,s0,-376
    80005280:	85ca                	mv	a1,s2
    80005282:	855a                	mv	a0,s6
    80005284:	ffffc097          	auipc	ra,0xffffc
    80005288:	3ba080e7          	jalr	954(ra) # 8000163e <copyout>
    8000528c:	0a054663          	bltz	a0,80005338 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005290:	070bb783          	ld	a5,112(s7) # 1070 <_entry-0x7fffef90>
    80005294:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005298:	de843783          	ld	a5,-536(s0)
    8000529c:	0007c703          	lbu	a4,0(a5)
    800052a0:	cf11                	beqz	a4,800052bc <exec+0x28e>
    800052a2:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052a4:	02f00693          	li	a3,47
    800052a8:	a039                	j	800052b6 <exec+0x288>
      last = s+1;
    800052aa:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800052ae:	0785                	addi	a5,a5,1
    800052b0:	fff7c703          	lbu	a4,-1(a5)
    800052b4:	c701                	beqz	a4,800052bc <exec+0x28e>
    if(*s == '/')
    800052b6:	fed71ce3          	bne	a4,a3,800052ae <exec+0x280>
    800052ba:	bfc5                	j	800052aa <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    800052bc:	4641                	li	a2,16
    800052be:	de843583          	ld	a1,-536(s0)
    800052c2:	170b8513          	addi	a0,s7,368
    800052c6:	ffffc097          	auipc	ra,0xffffc
    800052ca:	b4a080e7          	jalr	-1206(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    800052ce:	068bb503          	ld	a0,104(s7)
  p->pagetable = pagetable;
    800052d2:	076bb423          	sd	s6,104(s7)
  p->sz = sz;
    800052d6:	078bb023          	sd	s8,96(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052da:	070bb783          	ld	a5,112(s7)
    800052de:	e6043703          	ld	a4,-416(s0)
    800052e2:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052e4:	070bb783          	ld	a5,112(s7)
    800052e8:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052ec:	85ea                	mv	a1,s10
    800052ee:	ffffc097          	auipc	ra,0xffffc
    800052f2:	7f0080e7          	jalr	2032(ra) # 80001ade <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052f6:	0004851b          	sext.w	a0,s1
    800052fa:	bbc1                	j	800050ca <exec+0x9c>
    800052fc:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005300:	df843583          	ld	a1,-520(s0)
    80005304:	855a                	mv	a0,s6
    80005306:	ffffc097          	auipc	ra,0xffffc
    8000530a:	7d8080e7          	jalr	2008(ra) # 80001ade <proc_freepagetable>
  if(ip){
    8000530e:	da0a94e3          	bnez	s5,800050b6 <exec+0x88>
  return -1;
    80005312:	557d                	li	a0,-1
    80005314:	bb5d                	j	800050ca <exec+0x9c>
    80005316:	de943c23          	sd	s1,-520(s0)
    8000531a:	b7dd                	j	80005300 <exec+0x2d2>
    8000531c:	de943c23          	sd	s1,-520(s0)
    80005320:	b7c5                	j	80005300 <exec+0x2d2>
    80005322:	de943c23          	sd	s1,-520(s0)
    80005326:	bfe9                	j	80005300 <exec+0x2d2>
  sz = sz1;
    80005328:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000532c:	4a81                	li	s5,0
    8000532e:	bfc9                	j	80005300 <exec+0x2d2>
  sz = sz1;
    80005330:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005334:	4a81                	li	s5,0
    80005336:	b7e9                	j	80005300 <exec+0x2d2>
  sz = sz1;
    80005338:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000533c:	4a81                	li	s5,0
    8000533e:	b7c9                	j	80005300 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005340:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005344:	e0843783          	ld	a5,-504(s0)
    80005348:	0017869b          	addiw	a3,a5,1
    8000534c:	e0d43423          	sd	a3,-504(s0)
    80005350:	e0043783          	ld	a5,-512(s0)
    80005354:	0387879b          	addiw	a5,a5,56
    80005358:	e8045703          	lhu	a4,-384(s0)
    8000535c:	e2e6d3e3          	bge	a3,a4,80005182 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005360:	2781                	sext.w	a5,a5
    80005362:	e0f43023          	sd	a5,-512(s0)
    80005366:	03800713          	li	a4,56
    8000536a:	86be                	mv	a3,a5
    8000536c:	e1040613          	addi	a2,s0,-496
    80005370:	4581                	li	a1,0
    80005372:	8556                	mv	a0,s5
    80005374:	fffff097          	auipc	ra,0xfffff
    80005378:	a7a080e7          	jalr	-1414(ra) # 80003dee <readi>
    8000537c:	03800793          	li	a5,56
    80005380:	f6f51ee3          	bne	a0,a5,800052fc <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005384:	e1042783          	lw	a5,-496(s0)
    80005388:	4705                	li	a4,1
    8000538a:	fae79de3          	bne	a5,a4,80005344 <exec+0x316>
    if(ph.memsz < ph.filesz)
    8000538e:	e3843603          	ld	a2,-456(s0)
    80005392:	e3043783          	ld	a5,-464(s0)
    80005396:	f8f660e3          	bltu	a2,a5,80005316 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000539a:	e2043783          	ld	a5,-480(s0)
    8000539e:	963e                	add	a2,a2,a5
    800053a0:	f6f66ee3          	bltu	a2,a5,8000531c <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053a4:	85a6                	mv	a1,s1
    800053a6:	855a                	mv	a0,s6
    800053a8:	ffffc097          	auipc	ra,0xffffc
    800053ac:	046080e7          	jalr	70(ra) # 800013ee <uvmalloc>
    800053b0:	dea43c23          	sd	a0,-520(s0)
    800053b4:	d53d                	beqz	a0,80005322 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    800053b6:	e2043c03          	ld	s8,-480(s0)
    800053ba:	de043783          	ld	a5,-544(s0)
    800053be:	00fc77b3          	and	a5,s8,a5
    800053c2:	ff9d                	bnez	a5,80005300 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053c4:	e1842c83          	lw	s9,-488(s0)
    800053c8:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053cc:	f60b8ae3          	beqz	s7,80005340 <exec+0x312>
    800053d0:	89de                	mv	s3,s7
    800053d2:	4481                	li	s1,0
    800053d4:	b371                	j	80005160 <exec+0x132>

00000000800053d6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053d6:	7179                	addi	sp,sp,-48
    800053d8:	f406                	sd	ra,40(sp)
    800053da:	f022                	sd	s0,32(sp)
    800053dc:	ec26                	sd	s1,24(sp)
    800053de:	e84a                	sd	s2,16(sp)
    800053e0:	1800                	addi	s0,sp,48
    800053e2:	892e                	mv	s2,a1
    800053e4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800053e6:	fdc40593          	addi	a1,s0,-36
    800053ea:	ffffe097          	auipc	ra,0xffffe
    800053ee:	a54080e7          	jalr	-1452(ra) # 80002e3e <argint>
    800053f2:	04054063          	bltz	a0,80005432 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053f6:	fdc42703          	lw	a4,-36(s0)
    800053fa:	47bd                	li	a5,15
    800053fc:	02e7ed63          	bltu	a5,a4,80005436 <argfd+0x60>
    80005400:	ffffc097          	auipc	ra,0xffffc
    80005404:	57e080e7          	jalr	1406(ra) # 8000197e <myproc>
    80005408:	fdc42703          	lw	a4,-36(s0)
    8000540c:	01c70793          	addi	a5,a4,28
    80005410:	078e                	slli	a5,a5,0x3
    80005412:	953e                	add	a0,a0,a5
    80005414:	651c                	ld	a5,8(a0)
    80005416:	c395                	beqz	a5,8000543a <argfd+0x64>
    return -1;
  if(pfd)
    80005418:	00090463          	beqz	s2,80005420 <argfd+0x4a>
    *pfd = fd;
    8000541c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005420:	4501                	li	a0,0
  if(pf)
    80005422:	c091                	beqz	s1,80005426 <argfd+0x50>
    *pf = f;
    80005424:	e09c                	sd	a5,0(s1)
}
    80005426:	70a2                	ld	ra,40(sp)
    80005428:	7402                	ld	s0,32(sp)
    8000542a:	64e2                	ld	s1,24(sp)
    8000542c:	6942                	ld	s2,16(sp)
    8000542e:	6145                	addi	sp,sp,48
    80005430:	8082                	ret
    return -1;
    80005432:	557d                	li	a0,-1
    80005434:	bfcd                	j	80005426 <argfd+0x50>
    return -1;
    80005436:	557d                	li	a0,-1
    80005438:	b7fd                	j	80005426 <argfd+0x50>
    8000543a:	557d                	li	a0,-1
    8000543c:	b7ed                	j	80005426 <argfd+0x50>

000000008000543e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000543e:	1101                	addi	sp,sp,-32
    80005440:	ec06                	sd	ra,24(sp)
    80005442:	e822                	sd	s0,16(sp)
    80005444:	e426                	sd	s1,8(sp)
    80005446:	1000                	addi	s0,sp,32
    80005448:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000544a:	ffffc097          	auipc	ra,0xffffc
    8000544e:	534080e7          	jalr	1332(ra) # 8000197e <myproc>
    80005452:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005454:	0e850793          	addi	a5,a0,232
    80005458:	4501                	li	a0,0
    8000545a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000545c:	6398                	ld	a4,0(a5)
    8000545e:	cb19                	beqz	a4,80005474 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005460:	2505                	addiw	a0,a0,1
    80005462:	07a1                	addi	a5,a5,8
    80005464:	fed51ce3          	bne	a0,a3,8000545c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005468:	557d                	li	a0,-1
}
    8000546a:	60e2                	ld	ra,24(sp)
    8000546c:	6442                	ld	s0,16(sp)
    8000546e:	64a2                	ld	s1,8(sp)
    80005470:	6105                	addi	sp,sp,32
    80005472:	8082                	ret
      p->ofile[fd] = f;
    80005474:	01c50793          	addi	a5,a0,28
    80005478:	078e                	slli	a5,a5,0x3
    8000547a:	963e                	add	a2,a2,a5
    8000547c:	e604                	sd	s1,8(a2)
      return fd;
    8000547e:	b7f5                	j	8000546a <fdalloc+0x2c>

0000000080005480 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005480:	715d                	addi	sp,sp,-80
    80005482:	e486                	sd	ra,72(sp)
    80005484:	e0a2                	sd	s0,64(sp)
    80005486:	fc26                	sd	s1,56(sp)
    80005488:	f84a                	sd	s2,48(sp)
    8000548a:	f44e                	sd	s3,40(sp)
    8000548c:	f052                	sd	s4,32(sp)
    8000548e:	ec56                	sd	s5,24(sp)
    80005490:	0880                	addi	s0,sp,80
    80005492:	89ae                	mv	s3,a1
    80005494:	8ab2                	mv	s5,a2
    80005496:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005498:	fb040593          	addi	a1,s0,-80
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	e72080e7          	jalr	-398(ra) # 8000430e <nameiparent>
    800054a4:	892a                	mv	s2,a0
    800054a6:	12050e63          	beqz	a0,800055e2 <create+0x162>
    return 0;

  ilock(dp);
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	690080e7          	jalr	1680(ra) # 80003b3a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054b2:	4601                	li	a2,0
    800054b4:	fb040593          	addi	a1,s0,-80
    800054b8:	854a                	mv	a0,s2
    800054ba:	fffff097          	auipc	ra,0xfffff
    800054be:	b64080e7          	jalr	-1180(ra) # 8000401e <dirlookup>
    800054c2:	84aa                	mv	s1,a0
    800054c4:	c921                	beqz	a0,80005514 <create+0x94>
    iunlockput(dp);
    800054c6:	854a                	mv	a0,s2
    800054c8:	fffff097          	auipc	ra,0xfffff
    800054cc:	8d4080e7          	jalr	-1836(ra) # 80003d9c <iunlockput>
    ilock(ip);
    800054d0:	8526                	mv	a0,s1
    800054d2:	ffffe097          	auipc	ra,0xffffe
    800054d6:	668080e7          	jalr	1640(ra) # 80003b3a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054da:	2981                	sext.w	s3,s3
    800054dc:	4789                	li	a5,2
    800054de:	02f99463          	bne	s3,a5,80005506 <create+0x86>
    800054e2:	0444d783          	lhu	a5,68(s1)
    800054e6:	37f9                	addiw	a5,a5,-2
    800054e8:	17c2                	slli	a5,a5,0x30
    800054ea:	93c1                	srli	a5,a5,0x30
    800054ec:	4705                	li	a4,1
    800054ee:	00f76c63          	bltu	a4,a5,80005506 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800054f2:	8526                	mv	a0,s1
    800054f4:	60a6                	ld	ra,72(sp)
    800054f6:	6406                	ld	s0,64(sp)
    800054f8:	74e2                	ld	s1,56(sp)
    800054fa:	7942                	ld	s2,48(sp)
    800054fc:	79a2                	ld	s3,40(sp)
    800054fe:	7a02                	ld	s4,32(sp)
    80005500:	6ae2                	ld	s5,24(sp)
    80005502:	6161                	addi	sp,sp,80
    80005504:	8082                	ret
    iunlockput(ip);
    80005506:	8526                	mv	a0,s1
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	894080e7          	jalr	-1900(ra) # 80003d9c <iunlockput>
    return 0;
    80005510:	4481                	li	s1,0
    80005512:	b7c5                	j	800054f2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005514:	85ce                	mv	a1,s3
    80005516:	00092503          	lw	a0,0(s2)
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	488080e7          	jalr	1160(ra) # 800039a2 <ialloc>
    80005522:	84aa                	mv	s1,a0
    80005524:	c521                	beqz	a0,8000556c <create+0xec>
  ilock(ip);
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	614080e7          	jalr	1556(ra) # 80003b3a <ilock>
  ip->major = major;
    8000552e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005532:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005536:	4a05                	li	s4,1
    80005538:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000553c:	8526                	mv	a0,s1
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	532080e7          	jalr	1330(ra) # 80003a70 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005546:	2981                	sext.w	s3,s3
    80005548:	03498a63          	beq	s3,s4,8000557c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000554c:	40d0                	lw	a2,4(s1)
    8000554e:	fb040593          	addi	a1,s0,-80
    80005552:	854a                	mv	a0,s2
    80005554:	fffff097          	auipc	ra,0xfffff
    80005558:	cda080e7          	jalr	-806(ra) # 8000422e <dirlink>
    8000555c:	06054b63          	bltz	a0,800055d2 <create+0x152>
  iunlockput(dp);
    80005560:	854a                	mv	a0,s2
    80005562:	fffff097          	auipc	ra,0xfffff
    80005566:	83a080e7          	jalr	-1990(ra) # 80003d9c <iunlockput>
  return ip;
    8000556a:	b761                	j	800054f2 <create+0x72>
    panic("create: ialloc");
    8000556c:	00003517          	auipc	a0,0x3
    80005570:	35450513          	addi	a0,a0,852 # 800088c0 <syscalls+0x2b0>
    80005574:	ffffb097          	auipc	ra,0xffffb
    80005578:	fb6080e7          	jalr	-74(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000557c:	04a95783          	lhu	a5,74(s2)
    80005580:	2785                	addiw	a5,a5,1
    80005582:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005586:	854a                	mv	a0,s2
    80005588:	ffffe097          	auipc	ra,0xffffe
    8000558c:	4e8080e7          	jalr	1256(ra) # 80003a70 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005590:	40d0                	lw	a2,4(s1)
    80005592:	00003597          	auipc	a1,0x3
    80005596:	33e58593          	addi	a1,a1,830 # 800088d0 <syscalls+0x2c0>
    8000559a:	8526                	mv	a0,s1
    8000559c:	fffff097          	auipc	ra,0xfffff
    800055a0:	c92080e7          	jalr	-878(ra) # 8000422e <dirlink>
    800055a4:	00054f63          	bltz	a0,800055c2 <create+0x142>
    800055a8:	00492603          	lw	a2,4(s2)
    800055ac:	00003597          	auipc	a1,0x3
    800055b0:	32c58593          	addi	a1,a1,812 # 800088d8 <syscalls+0x2c8>
    800055b4:	8526                	mv	a0,s1
    800055b6:	fffff097          	auipc	ra,0xfffff
    800055ba:	c78080e7          	jalr	-904(ra) # 8000422e <dirlink>
    800055be:	f80557e3          	bgez	a0,8000554c <create+0xcc>
      panic("create dots");
    800055c2:	00003517          	auipc	a0,0x3
    800055c6:	31e50513          	addi	a0,a0,798 # 800088e0 <syscalls+0x2d0>
    800055ca:	ffffb097          	auipc	ra,0xffffb
    800055ce:	f60080e7          	jalr	-160(ra) # 8000052a <panic>
    panic("create: dirlink");
    800055d2:	00003517          	auipc	a0,0x3
    800055d6:	31e50513          	addi	a0,a0,798 # 800088f0 <syscalls+0x2e0>
    800055da:	ffffb097          	auipc	ra,0xffffb
    800055de:	f50080e7          	jalr	-176(ra) # 8000052a <panic>
    return 0;
    800055e2:	84aa                	mv	s1,a0
    800055e4:	b739                	j	800054f2 <create+0x72>

00000000800055e6 <sys_dup>:
{
    800055e6:	7179                	addi	sp,sp,-48
    800055e8:	f406                	sd	ra,40(sp)
    800055ea:	f022                	sd	s0,32(sp)
    800055ec:	ec26                	sd	s1,24(sp)
    800055ee:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800055f0:	fd840613          	addi	a2,s0,-40
    800055f4:	4581                	li	a1,0
    800055f6:	4501                	li	a0,0
    800055f8:	00000097          	auipc	ra,0x0
    800055fc:	dde080e7          	jalr	-546(ra) # 800053d6 <argfd>
    return -1;
    80005600:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005602:	02054363          	bltz	a0,80005628 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005606:	fd843503          	ld	a0,-40(s0)
    8000560a:	00000097          	auipc	ra,0x0
    8000560e:	e34080e7          	jalr	-460(ra) # 8000543e <fdalloc>
    80005612:	84aa                	mv	s1,a0
    return -1;
    80005614:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005616:	00054963          	bltz	a0,80005628 <sys_dup+0x42>
  filedup(f);
    8000561a:	fd843503          	ld	a0,-40(s0)
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	36c080e7          	jalr	876(ra) # 8000498a <filedup>
  return fd;
    80005626:	87a6                	mv	a5,s1
}
    80005628:	853e                	mv	a0,a5
    8000562a:	70a2                	ld	ra,40(sp)
    8000562c:	7402                	ld	s0,32(sp)
    8000562e:	64e2                	ld	s1,24(sp)
    80005630:	6145                	addi	sp,sp,48
    80005632:	8082                	ret

0000000080005634 <sys_read>:
{
    80005634:	7179                	addi	sp,sp,-48
    80005636:	f406                	sd	ra,40(sp)
    80005638:	f022                	sd	s0,32(sp)
    8000563a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000563c:	fe840613          	addi	a2,s0,-24
    80005640:	4581                	li	a1,0
    80005642:	4501                	li	a0,0
    80005644:	00000097          	auipc	ra,0x0
    80005648:	d92080e7          	jalr	-622(ra) # 800053d6 <argfd>
    return -1;
    8000564c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000564e:	04054163          	bltz	a0,80005690 <sys_read+0x5c>
    80005652:	fe440593          	addi	a1,s0,-28
    80005656:	4509                	li	a0,2
    80005658:	ffffd097          	auipc	ra,0xffffd
    8000565c:	7e6080e7          	jalr	2022(ra) # 80002e3e <argint>
    return -1;
    80005660:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005662:	02054763          	bltz	a0,80005690 <sys_read+0x5c>
    80005666:	fd840593          	addi	a1,s0,-40
    8000566a:	4505                	li	a0,1
    8000566c:	ffffd097          	auipc	ra,0xffffd
    80005670:	7f4080e7          	jalr	2036(ra) # 80002e60 <argaddr>
    return -1;
    80005674:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005676:	00054d63          	bltz	a0,80005690 <sys_read+0x5c>
  return fileread(f, p, n);
    8000567a:	fe442603          	lw	a2,-28(s0)
    8000567e:	fd843583          	ld	a1,-40(s0)
    80005682:	fe843503          	ld	a0,-24(s0)
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	490080e7          	jalr	1168(ra) # 80004b16 <fileread>
    8000568e:	87aa                	mv	a5,a0
}
    80005690:	853e                	mv	a0,a5
    80005692:	70a2                	ld	ra,40(sp)
    80005694:	7402                	ld	s0,32(sp)
    80005696:	6145                	addi	sp,sp,48
    80005698:	8082                	ret

000000008000569a <sys_write>:
{
    8000569a:	7179                	addi	sp,sp,-48
    8000569c:	f406                	sd	ra,40(sp)
    8000569e:	f022                	sd	s0,32(sp)
    800056a0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056a2:	fe840613          	addi	a2,s0,-24
    800056a6:	4581                	li	a1,0
    800056a8:	4501                	li	a0,0
    800056aa:	00000097          	auipc	ra,0x0
    800056ae:	d2c080e7          	jalr	-724(ra) # 800053d6 <argfd>
    return -1;
    800056b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056b4:	04054163          	bltz	a0,800056f6 <sys_write+0x5c>
    800056b8:	fe440593          	addi	a1,s0,-28
    800056bc:	4509                	li	a0,2
    800056be:	ffffd097          	auipc	ra,0xffffd
    800056c2:	780080e7          	jalr	1920(ra) # 80002e3e <argint>
    return -1;
    800056c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056c8:	02054763          	bltz	a0,800056f6 <sys_write+0x5c>
    800056cc:	fd840593          	addi	a1,s0,-40
    800056d0:	4505                	li	a0,1
    800056d2:	ffffd097          	auipc	ra,0xffffd
    800056d6:	78e080e7          	jalr	1934(ra) # 80002e60 <argaddr>
    return -1;
    800056da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056dc:	00054d63          	bltz	a0,800056f6 <sys_write+0x5c>
  return filewrite(f, p, n);
    800056e0:	fe442603          	lw	a2,-28(s0)
    800056e4:	fd843583          	ld	a1,-40(s0)
    800056e8:	fe843503          	ld	a0,-24(s0)
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	4ec080e7          	jalr	1260(ra) # 80004bd8 <filewrite>
    800056f4:	87aa                	mv	a5,a0
}
    800056f6:	853e                	mv	a0,a5
    800056f8:	70a2                	ld	ra,40(sp)
    800056fa:	7402                	ld	s0,32(sp)
    800056fc:	6145                	addi	sp,sp,48
    800056fe:	8082                	ret

0000000080005700 <sys_close>:
{
    80005700:	1101                	addi	sp,sp,-32
    80005702:	ec06                	sd	ra,24(sp)
    80005704:	e822                	sd	s0,16(sp)
    80005706:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005708:	fe040613          	addi	a2,s0,-32
    8000570c:	fec40593          	addi	a1,s0,-20
    80005710:	4501                	li	a0,0
    80005712:	00000097          	auipc	ra,0x0
    80005716:	cc4080e7          	jalr	-828(ra) # 800053d6 <argfd>
    return -1;
    8000571a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000571c:	02054463          	bltz	a0,80005744 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005720:	ffffc097          	auipc	ra,0xffffc
    80005724:	25e080e7          	jalr	606(ra) # 8000197e <myproc>
    80005728:	fec42783          	lw	a5,-20(s0)
    8000572c:	07f1                	addi	a5,a5,28
    8000572e:	078e                	slli	a5,a5,0x3
    80005730:	97aa                	add	a5,a5,a0
    80005732:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005736:	fe043503          	ld	a0,-32(s0)
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	2a2080e7          	jalr	674(ra) # 800049dc <fileclose>
  return 0;
    80005742:	4781                	li	a5,0
}
    80005744:	853e                	mv	a0,a5
    80005746:	60e2                	ld	ra,24(sp)
    80005748:	6442                	ld	s0,16(sp)
    8000574a:	6105                	addi	sp,sp,32
    8000574c:	8082                	ret

000000008000574e <sys_fstat>:
{
    8000574e:	1101                	addi	sp,sp,-32
    80005750:	ec06                	sd	ra,24(sp)
    80005752:	e822                	sd	s0,16(sp)
    80005754:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005756:	fe840613          	addi	a2,s0,-24
    8000575a:	4581                	li	a1,0
    8000575c:	4501                	li	a0,0
    8000575e:	00000097          	auipc	ra,0x0
    80005762:	c78080e7          	jalr	-904(ra) # 800053d6 <argfd>
    return -1;
    80005766:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005768:	02054563          	bltz	a0,80005792 <sys_fstat+0x44>
    8000576c:	fe040593          	addi	a1,s0,-32
    80005770:	4505                	li	a0,1
    80005772:	ffffd097          	auipc	ra,0xffffd
    80005776:	6ee080e7          	jalr	1774(ra) # 80002e60 <argaddr>
    return -1;
    8000577a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000577c:	00054b63          	bltz	a0,80005792 <sys_fstat+0x44>
  return filestat(f, st);
    80005780:	fe043583          	ld	a1,-32(s0)
    80005784:	fe843503          	ld	a0,-24(s0)
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	31c080e7          	jalr	796(ra) # 80004aa4 <filestat>
    80005790:	87aa                	mv	a5,a0
}
    80005792:	853e                	mv	a0,a5
    80005794:	60e2                	ld	ra,24(sp)
    80005796:	6442                	ld	s0,16(sp)
    80005798:	6105                	addi	sp,sp,32
    8000579a:	8082                	ret

000000008000579c <sys_link>:
{
    8000579c:	7169                	addi	sp,sp,-304
    8000579e:	f606                	sd	ra,296(sp)
    800057a0:	f222                	sd	s0,288(sp)
    800057a2:	ee26                	sd	s1,280(sp)
    800057a4:	ea4a                	sd	s2,272(sp)
    800057a6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057a8:	08000613          	li	a2,128
    800057ac:	ed040593          	addi	a1,s0,-304
    800057b0:	4501                	li	a0,0
    800057b2:	ffffd097          	auipc	ra,0xffffd
    800057b6:	6d0080e7          	jalr	1744(ra) # 80002e82 <argstr>
    return -1;
    800057ba:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057bc:	10054e63          	bltz	a0,800058d8 <sys_link+0x13c>
    800057c0:	08000613          	li	a2,128
    800057c4:	f5040593          	addi	a1,s0,-176
    800057c8:	4505                	li	a0,1
    800057ca:	ffffd097          	auipc	ra,0xffffd
    800057ce:	6b8080e7          	jalr	1720(ra) # 80002e82 <argstr>
    return -1;
    800057d2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057d4:	10054263          	bltz	a0,800058d8 <sys_link+0x13c>
  begin_op();
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	d38080e7          	jalr	-712(ra) # 80004510 <begin_op>
  if((ip = namei(old)) == 0){
    800057e0:	ed040513          	addi	a0,s0,-304
    800057e4:	fffff097          	auipc	ra,0xfffff
    800057e8:	b0c080e7          	jalr	-1268(ra) # 800042f0 <namei>
    800057ec:	84aa                	mv	s1,a0
    800057ee:	c551                	beqz	a0,8000587a <sys_link+0xde>
  ilock(ip);
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	34a080e7          	jalr	842(ra) # 80003b3a <ilock>
  if(ip->type == T_DIR){
    800057f8:	04449703          	lh	a4,68(s1)
    800057fc:	4785                	li	a5,1
    800057fe:	08f70463          	beq	a4,a5,80005886 <sys_link+0xea>
  ip->nlink++;
    80005802:	04a4d783          	lhu	a5,74(s1)
    80005806:	2785                	addiw	a5,a5,1
    80005808:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000580c:	8526                	mv	a0,s1
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	262080e7          	jalr	610(ra) # 80003a70 <iupdate>
  iunlock(ip);
    80005816:	8526                	mv	a0,s1
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	3e4080e7          	jalr	996(ra) # 80003bfc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005820:	fd040593          	addi	a1,s0,-48
    80005824:	f5040513          	addi	a0,s0,-176
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	ae6080e7          	jalr	-1306(ra) # 8000430e <nameiparent>
    80005830:	892a                	mv	s2,a0
    80005832:	c935                	beqz	a0,800058a6 <sys_link+0x10a>
  ilock(dp);
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	306080e7          	jalr	774(ra) # 80003b3a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000583c:	00092703          	lw	a4,0(s2)
    80005840:	409c                	lw	a5,0(s1)
    80005842:	04f71d63          	bne	a4,a5,8000589c <sys_link+0x100>
    80005846:	40d0                	lw	a2,4(s1)
    80005848:	fd040593          	addi	a1,s0,-48
    8000584c:	854a                	mv	a0,s2
    8000584e:	fffff097          	auipc	ra,0xfffff
    80005852:	9e0080e7          	jalr	-1568(ra) # 8000422e <dirlink>
    80005856:	04054363          	bltz	a0,8000589c <sys_link+0x100>
  iunlockput(dp);
    8000585a:	854a                	mv	a0,s2
    8000585c:	ffffe097          	auipc	ra,0xffffe
    80005860:	540080e7          	jalr	1344(ra) # 80003d9c <iunlockput>
  iput(ip);
    80005864:	8526                	mv	a0,s1
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	48e080e7          	jalr	1166(ra) # 80003cf4 <iput>
  end_op();
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	d22080e7          	jalr	-734(ra) # 80004590 <end_op>
  return 0;
    80005876:	4781                	li	a5,0
    80005878:	a085                	j	800058d8 <sys_link+0x13c>
    end_op();
    8000587a:	fffff097          	auipc	ra,0xfffff
    8000587e:	d16080e7          	jalr	-746(ra) # 80004590 <end_op>
    return -1;
    80005882:	57fd                	li	a5,-1
    80005884:	a891                	j	800058d8 <sys_link+0x13c>
    iunlockput(ip);
    80005886:	8526                	mv	a0,s1
    80005888:	ffffe097          	auipc	ra,0xffffe
    8000588c:	514080e7          	jalr	1300(ra) # 80003d9c <iunlockput>
    end_op();
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	d00080e7          	jalr	-768(ra) # 80004590 <end_op>
    return -1;
    80005898:	57fd                	li	a5,-1
    8000589a:	a83d                	j	800058d8 <sys_link+0x13c>
    iunlockput(dp);
    8000589c:	854a                	mv	a0,s2
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	4fe080e7          	jalr	1278(ra) # 80003d9c <iunlockput>
  ilock(ip);
    800058a6:	8526                	mv	a0,s1
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	292080e7          	jalr	658(ra) # 80003b3a <ilock>
  ip->nlink--;
    800058b0:	04a4d783          	lhu	a5,74(s1)
    800058b4:	37fd                	addiw	a5,a5,-1
    800058b6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058ba:	8526                	mv	a0,s1
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	1b4080e7          	jalr	436(ra) # 80003a70 <iupdate>
  iunlockput(ip);
    800058c4:	8526                	mv	a0,s1
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	4d6080e7          	jalr	1238(ra) # 80003d9c <iunlockput>
  end_op();
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	cc2080e7          	jalr	-830(ra) # 80004590 <end_op>
  return -1;
    800058d6:	57fd                	li	a5,-1
}
    800058d8:	853e                	mv	a0,a5
    800058da:	70b2                	ld	ra,296(sp)
    800058dc:	7412                	ld	s0,288(sp)
    800058de:	64f2                	ld	s1,280(sp)
    800058e0:	6952                	ld	s2,272(sp)
    800058e2:	6155                	addi	sp,sp,304
    800058e4:	8082                	ret

00000000800058e6 <sys_unlink>:
{
    800058e6:	7151                	addi	sp,sp,-240
    800058e8:	f586                	sd	ra,232(sp)
    800058ea:	f1a2                	sd	s0,224(sp)
    800058ec:	eda6                	sd	s1,216(sp)
    800058ee:	e9ca                	sd	s2,208(sp)
    800058f0:	e5ce                	sd	s3,200(sp)
    800058f2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058f4:	08000613          	li	a2,128
    800058f8:	f3040593          	addi	a1,s0,-208
    800058fc:	4501                	li	a0,0
    800058fe:	ffffd097          	auipc	ra,0xffffd
    80005902:	584080e7          	jalr	1412(ra) # 80002e82 <argstr>
    80005906:	18054163          	bltz	a0,80005a88 <sys_unlink+0x1a2>
  begin_op();
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	c06080e7          	jalr	-1018(ra) # 80004510 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005912:	fb040593          	addi	a1,s0,-80
    80005916:	f3040513          	addi	a0,s0,-208
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	9f4080e7          	jalr	-1548(ra) # 8000430e <nameiparent>
    80005922:	84aa                	mv	s1,a0
    80005924:	c979                	beqz	a0,800059fa <sys_unlink+0x114>
  ilock(dp);
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	214080e7          	jalr	532(ra) # 80003b3a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000592e:	00003597          	auipc	a1,0x3
    80005932:	fa258593          	addi	a1,a1,-94 # 800088d0 <syscalls+0x2c0>
    80005936:	fb040513          	addi	a0,s0,-80
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	6ca080e7          	jalr	1738(ra) # 80004004 <namecmp>
    80005942:	14050a63          	beqz	a0,80005a96 <sys_unlink+0x1b0>
    80005946:	00003597          	auipc	a1,0x3
    8000594a:	f9258593          	addi	a1,a1,-110 # 800088d8 <syscalls+0x2c8>
    8000594e:	fb040513          	addi	a0,s0,-80
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	6b2080e7          	jalr	1714(ra) # 80004004 <namecmp>
    8000595a:	12050e63          	beqz	a0,80005a96 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000595e:	f2c40613          	addi	a2,s0,-212
    80005962:	fb040593          	addi	a1,s0,-80
    80005966:	8526                	mv	a0,s1
    80005968:	ffffe097          	auipc	ra,0xffffe
    8000596c:	6b6080e7          	jalr	1718(ra) # 8000401e <dirlookup>
    80005970:	892a                	mv	s2,a0
    80005972:	12050263          	beqz	a0,80005a96 <sys_unlink+0x1b0>
  ilock(ip);
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	1c4080e7          	jalr	452(ra) # 80003b3a <ilock>
  if(ip->nlink < 1)
    8000597e:	04a91783          	lh	a5,74(s2)
    80005982:	08f05263          	blez	a5,80005a06 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005986:	04491703          	lh	a4,68(s2)
    8000598a:	4785                	li	a5,1
    8000598c:	08f70563          	beq	a4,a5,80005a16 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005990:	4641                	li	a2,16
    80005992:	4581                	li	a1,0
    80005994:	fc040513          	addi	a0,s0,-64
    80005998:	ffffb097          	auipc	ra,0xffffb
    8000599c:	326080e7          	jalr	806(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059a0:	4741                	li	a4,16
    800059a2:	f2c42683          	lw	a3,-212(s0)
    800059a6:	fc040613          	addi	a2,s0,-64
    800059aa:	4581                	li	a1,0
    800059ac:	8526                	mv	a0,s1
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	538080e7          	jalr	1336(ra) # 80003ee6 <writei>
    800059b6:	47c1                	li	a5,16
    800059b8:	0af51563          	bne	a0,a5,80005a62 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059bc:	04491703          	lh	a4,68(s2)
    800059c0:	4785                	li	a5,1
    800059c2:	0af70863          	beq	a4,a5,80005a72 <sys_unlink+0x18c>
  iunlockput(dp);
    800059c6:	8526                	mv	a0,s1
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	3d4080e7          	jalr	980(ra) # 80003d9c <iunlockput>
  ip->nlink--;
    800059d0:	04a95783          	lhu	a5,74(s2)
    800059d4:	37fd                	addiw	a5,a5,-1
    800059d6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059da:	854a                	mv	a0,s2
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	094080e7          	jalr	148(ra) # 80003a70 <iupdate>
  iunlockput(ip);
    800059e4:	854a                	mv	a0,s2
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	3b6080e7          	jalr	950(ra) # 80003d9c <iunlockput>
  end_op();
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	ba2080e7          	jalr	-1118(ra) # 80004590 <end_op>
  return 0;
    800059f6:	4501                	li	a0,0
    800059f8:	a84d                	j	80005aaa <sys_unlink+0x1c4>
    end_op();
    800059fa:	fffff097          	auipc	ra,0xfffff
    800059fe:	b96080e7          	jalr	-1130(ra) # 80004590 <end_op>
    return -1;
    80005a02:	557d                	li	a0,-1
    80005a04:	a05d                	j	80005aaa <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a06:	00003517          	auipc	a0,0x3
    80005a0a:	efa50513          	addi	a0,a0,-262 # 80008900 <syscalls+0x2f0>
    80005a0e:	ffffb097          	auipc	ra,0xffffb
    80005a12:	b1c080e7          	jalr	-1252(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a16:	04c92703          	lw	a4,76(s2)
    80005a1a:	02000793          	li	a5,32
    80005a1e:	f6e7f9e3          	bgeu	a5,a4,80005990 <sys_unlink+0xaa>
    80005a22:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a26:	4741                	li	a4,16
    80005a28:	86ce                	mv	a3,s3
    80005a2a:	f1840613          	addi	a2,s0,-232
    80005a2e:	4581                	li	a1,0
    80005a30:	854a                	mv	a0,s2
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	3bc080e7          	jalr	956(ra) # 80003dee <readi>
    80005a3a:	47c1                	li	a5,16
    80005a3c:	00f51b63          	bne	a0,a5,80005a52 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a40:	f1845783          	lhu	a5,-232(s0)
    80005a44:	e7a1                	bnez	a5,80005a8c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a46:	29c1                	addiw	s3,s3,16
    80005a48:	04c92783          	lw	a5,76(s2)
    80005a4c:	fcf9ede3          	bltu	s3,a5,80005a26 <sys_unlink+0x140>
    80005a50:	b781                	j	80005990 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a52:	00003517          	auipc	a0,0x3
    80005a56:	ec650513          	addi	a0,a0,-314 # 80008918 <syscalls+0x308>
    80005a5a:	ffffb097          	auipc	ra,0xffffb
    80005a5e:	ad0080e7          	jalr	-1328(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005a62:	00003517          	auipc	a0,0x3
    80005a66:	ece50513          	addi	a0,a0,-306 # 80008930 <syscalls+0x320>
    80005a6a:	ffffb097          	auipc	ra,0xffffb
    80005a6e:	ac0080e7          	jalr	-1344(ra) # 8000052a <panic>
    dp->nlink--;
    80005a72:	04a4d783          	lhu	a5,74(s1)
    80005a76:	37fd                	addiw	a5,a5,-1
    80005a78:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a7c:	8526                	mv	a0,s1
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	ff2080e7          	jalr	-14(ra) # 80003a70 <iupdate>
    80005a86:	b781                	j	800059c6 <sys_unlink+0xe0>
    return -1;
    80005a88:	557d                	li	a0,-1
    80005a8a:	a005                	j	80005aaa <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a8c:	854a                	mv	a0,s2
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	30e080e7          	jalr	782(ra) # 80003d9c <iunlockput>
  iunlockput(dp);
    80005a96:	8526                	mv	a0,s1
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	304080e7          	jalr	772(ra) # 80003d9c <iunlockput>
  end_op();
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	af0080e7          	jalr	-1296(ra) # 80004590 <end_op>
  return -1;
    80005aa8:	557d                	li	a0,-1
}
    80005aaa:	70ae                	ld	ra,232(sp)
    80005aac:	740e                	ld	s0,224(sp)
    80005aae:	64ee                	ld	s1,216(sp)
    80005ab0:	694e                	ld	s2,208(sp)
    80005ab2:	69ae                	ld	s3,200(sp)
    80005ab4:	616d                	addi	sp,sp,240
    80005ab6:	8082                	ret

0000000080005ab8 <sys_open>:

uint64
sys_open(void)
{
    80005ab8:	7131                	addi	sp,sp,-192
    80005aba:	fd06                	sd	ra,184(sp)
    80005abc:	f922                	sd	s0,176(sp)
    80005abe:	f526                	sd	s1,168(sp)
    80005ac0:	f14a                	sd	s2,160(sp)
    80005ac2:	ed4e                	sd	s3,152(sp)
    80005ac4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ac6:	08000613          	li	a2,128
    80005aca:	f5040593          	addi	a1,s0,-176
    80005ace:	4501                	li	a0,0
    80005ad0:	ffffd097          	auipc	ra,0xffffd
    80005ad4:	3b2080e7          	jalr	946(ra) # 80002e82 <argstr>
    return -1;
    80005ad8:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ada:	0c054163          	bltz	a0,80005b9c <sys_open+0xe4>
    80005ade:	f4c40593          	addi	a1,s0,-180
    80005ae2:	4505                	li	a0,1
    80005ae4:	ffffd097          	auipc	ra,0xffffd
    80005ae8:	35a080e7          	jalr	858(ra) # 80002e3e <argint>
    80005aec:	0a054863          	bltz	a0,80005b9c <sys_open+0xe4>

  begin_op();
    80005af0:	fffff097          	auipc	ra,0xfffff
    80005af4:	a20080e7          	jalr	-1504(ra) # 80004510 <begin_op>

  if(omode & O_CREATE){
    80005af8:	f4c42783          	lw	a5,-180(s0)
    80005afc:	2007f793          	andi	a5,a5,512
    80005b00:	cbdd                	beqz	a5,80005bb6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b02:	4681                	li	a3,0
    80005b04:	4601                	li	a2,0
    80005b06:	4589                	li	a1,2
    80005b08:	f5040513          	addi	a0,s0,-176
    80005b0c:	00000097          	auipc	ra,0x0
    80005b10:	974080e7          	jalr	-1676(ra) # 80005480 <create>
    80005b14:	892a                	mv	s2,a0
    if(ip == 0){
    80005b16:	c959                	beqz	a0,80005bac <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b18:	04491703          	lh	a4,68(s2)
    80005b1c:	478d                	li	a5,3
    80005b1e:	00f71763          	bne	a4,a5,80005b2c <sys_open+0x74>
    80005b22:	04695703          	lhu	a4,70(s2)
    80005b26:	47a5                	li	a5,9
    80005b28:	0ce7ec63          	bltu	a5,a4,80005c00 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	df4080e7          	jalr	-524(ra) # 80004920 <filealloc>
    80005b34:	89aa                	mv	s3,a0
    80005b36:	10050263          	beqz	a0,80005c3a <sys_open+0x182>
    80005b3a:	00000097          	auipc	ra,0x0
    80005b3e:	904080e7          	jalr	-1788(ra) # 8000543e <fdalloc>
    80005b42:	84aa                	mv	s1,a0
    80005b44:	0e054663          	bltz	a0,80005c30 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b48:	04491703          	lh	a4,68(s2)
    80005b4c:	478d                	li	a5,3
    80005b4e:	0cf70463          	beq	a4,a5,80005c16 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b52:	4789                	li	a5,2
    80005b54:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b58:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b5c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b60:	f4c42783          	lw	a5,-180(s0)
    80005b64:	0017c713          	xori	a4,a5,1
    80005b68:	8b05                	andi	a4,a4,1
    80005b6a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b6e:	0037f713          	andi	a4,a5,3
    80005b72:	00e03733          	snez	a4,a4
    80005b76:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b7a:	4007f793          	andi	a5,a5,1024
    80005b7e:	c791                	beqz	a5,80005b8a <sys_open+0xd2>
    80005b80:	04491703          	lh	a4,68(s2)
    80005b84:	4789                	li	a5,2
    80005b86:	08f70f63          	beq	a4,a5,80005c24 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b8a:	854a                	mv	a0,s2
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	070080e7          	jalr	112(ra) # 80003bfc <iunlock>
  end_op();
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	9fc080e7          	jalr	-1540(ra) # 80004590 <end_op>

  return fd;
}
    80005b9c:	8526                	mv	a0,s1
    80005b9e:	70ea                	ld	ra,184(sp)
    80005ba0:	744a                	ld	s0,176(sp)
    80005ba2:	74aa                	ld	s1,168(sp)
    80005ba4:	790a                	ld	s2,160(sp)
    80005ba6:	69ea                	ld	s3,152(sp)
    80005ba8:	6129                	addi	sp,sp,192
    80005baa:	8082                	ret
      end_op();
    80005bac:	fffff097          	auipc	ra,0xfffff
    80005bb0:	9e4080e7          	jalr	-1564(ra) # 80004590 <end_op>
      return -1;
    80005bb4:	b7e5                	j	80005b9c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bb6:	f5040513          	addi	a0,s0,-176
    80005bba:	ffffe097          	auipc	ra,0xffffe
    80005bbe:	736080e7          	jalr	1846(ra) # 800042f0 <namei>
    80005bc2:	892a                	mv	s2,a0
    80005bc4:	c905                	beqz	a0,80005bf4 <sys_open+0x13c>
    ilock(ip);
    80005bc6:	ffffe097          	auipc	ra,0xffffe
    80005bca:	f74080e7          	jalr	-140(ra) # 80003b3a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bce:	04491703          	lh	a4,68(s2)
    80005bd2:	4785                	li	a5,1
    80005bd4:	f4f712e3          	bne	a4,a5,80005b18 <sys_open+0x60>
    80005bd8:	f4c42783          	lw	a5,-180(s0)
    80005bdc:	dba1                	beqz	a5,80005b2c <sys_open+0x74>
      iunlockput(ip);
    80005bde:	854a                	mv	a0,s2
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	1bc080e7          	jalr	444(ra) # 80003d9c <iunlockput>
      end_op();
    80005be8:	fffff097          	auipc	ra,0xfffff
    80005bec:	9a8080e7          	jalr	-1624(ra) # 80004590 <end_op>
      return -1;
    80005bf0:	54fd                	li	s1,-1
    80005bf2:	b76d                	j	80005b9c <sys_open+0xe4>
      end_op();
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	99c080e7          	jalr	-1636(ra) # 80004590 <end_op>
      return -1;
    80005bfc:	54fd                	li	s1,-1
    80005bfe:	bf79                	j	80005b9c <sys_open+0xe4>
    iunlockput(ip);
    80005c00:	854a                	mv	a0,s2
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	19a080e7          	jalr	410(ra) # 80003d9c <iunlockput>
    end_op();
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	986080e7          	jalr	-1658(ra) # 80004590 <end_op>
    return -1;
    80005c12:	54fd                	li	s1,-1
    80005c14:	b761                	j	80005b9c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c16:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c1a:	04691783          	lh	a5,70(s2)
    80005c1e:	02f99223          	sh	a5,36(s3)
    80005c22:	bf2d                	j	80005b5c <sys_open+0xa4>
    itrunc(ip);
    80005c24:	854a                	mv	a0,s2
    80005c26:	ffffe097          	auipc	ra,0xffffe
    80005c2a:	022080e7          	jalr	34(ra) # 80003c48 <itrunc>
    80005c2e:	bfb1                	j	80005b8a <sys_open+0xd2>
      fileclose(f);
    80005c30:	854e                	mv	a0,s3
    80005c32:	fffff097          	auipc	ra,0xfffff
    80005c36:	daa080e7          	jalr	-598(ra) # 800049dc <fileclose>
    iunlockput(ip);
    80005c3a:	854a                	mv	a0,s2
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	160080e7          	jalr	352(ra) # 80003d9c <iunlockput>
    end_op();
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	94c080e7          	jalr	-1716(ra) # 80004590 <end_op>
    return -1;
    80005c4c:	54fd                	li	s1,-1
    80005c4e:	b7b9                	j	80005b9c <sys_open+0xe4>

0000000080005c50 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c50:	7175                	addi	sp,sp,-144
    80005c52:	e506                	sd	ra,136(sp)
    80005c54:	e122                	sd	s0,128(sp)
    80005c56:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c58:	fffff097          	auipc	ra,0xfffff
    80005c5c:	8b8080e7          	jalr	-1864(ra) # 80004510 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c60:	08000613          	li	a2,128
    80005c64:	f7040593          	addi	a1,s0,-144
    80005c68:	4501                	li	a0,0
    80005c6a:	ffffd097          	auipc	ra,0xffffd
    80005c6e:	218080e7          	jalr	536(ra) # 80002e82 <argstr>
    80005c72:	02054963          	bltz	a0,80005ca4 <sys_mkdir+0x54>
    80005c76:	4681                	li	a3,0
    80005c78:	4601                	li	a2,0
    80005c7a:	4585                	li	a1,1
    80005c7c:	f7040513          	addi	a0,s0,-144
    80005c80:	00000097          	auipc	ra,0x0
    80005c84:	800080e7          	jalr	-2048(ra) # 80005480 <create>
    80005c88:	cd11                	beqz	a0,80005ca4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c8a:	ffffe097          	auipc	ra,0xffffe
    80005c8e:	112080e7          	jalr	274(ra) # 80003d9c <iunlockput>
  end_op();
    80005c92:	fffff097          	auipc	ra,0xfffff
    80005c96:	8fe080e7          	jalr	-1794(ra) # 80004590 <end_op>
  return 0;
    80005c9a:	4501                	li	a0,0
}
    80005c9c:	60aa                	ld	ra,136(sp)
    80005c9e:	640a                	ld	s0,128(sp)
    80005ca0:	6149                	addi	sp,sp,144
    80005ca2:	8082                	ret
    end_op();
    80005ca4:	fffff097          	auipc	ra,0xfffff
    80005ca8:	8ec080e7          	jalr	-1812(ra) # 80004590 <end_op>
    return -1;
    80005cac:	557d                	li	a0,-1
    80005cae:	b7fd                	j	80005c9c <sys_mkdir+0x4c>

0000000080005cb0 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005cb0:	7135                	addi	sp,sp,-160
    80005cb2:	ed06                	sd	ra,152(sp)
    80005cb4:	e922                	sd	s0,144(sp)
    80005cb6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005cb8:	fffff097          	auipc	ra,0xfffff
    80005cbc:	858080e7          	jalr	-1960(ra) # 80004510 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cc0:	08000613          	li	a2,128
    80005cc4:	f7040593          	addi	a1,s0,-144
    80005cc8:	4501                	li	a0,0
    80005cca:	ffffd097          	auipc	ra,0xffffd
    80005cce:	1b8080e7          	jalr	440(ra) # 80002e82 <argstr>
    80005cd2:	04054a63          	bltz	a0,80005d26 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005cd6:	f6c40593          	addi	a1,s0,-148
    80005cda:	4505                	li	a0,1
    80005cdc:	ffffd097          	auipc	ra,0xffffd
    80005ce0:	162080e7          	jalr	354(ra) # 80002e3e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ce4:	04054163          	bltz	a0,80005d26 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ce8:	f6840593          	addi	a1,s0,-152
    80005cec:	4509                	li	a0,2
    80005cee:	ffffd097          	auipc	ra,0xffffd
    80005cf2:	150080e7          	jalr	336(ra) # 80002e3e <argint>
     argint(1, &major) < 0 ||
    80005cf6:	02054863          	bltz	a0,80005d26 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005cfa:	f6841683          	lh	a3,-152(s0)
    80005cfe:	f6c41603          	lh	a2,-148(s0)
    80005d02:	458d                	li	a1,3
    80005d04:	f7040513          	addi	a0,s0,-144
    80005d08:	fffff097          	auipc	ra,0xfffff
    80005d0c:	778080e7          	jalr	1912(ra) # 80005480 <create>
     argint(2, &minor) < 0 ||
    80005d10:	c919                	beqz	a0,80005d26 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d12:	ffffe097          	auipc	ra,0xffffe
    80005d16:	08a080e7          	jalr	138(ra) # 80003d9c <iunlockput>
  end_op();
    80005d1a:	fffff097          	auipc	ra,0xfffff
    80005d1e:	876080e7          	jalr	-1930(ra) # 80004590 <end_op>
  return 0;
    80005d22:	4501                	li	a0,0
    80005d24:	a031                	j	80005d30 <sys_mknod+0x80>
    end_op();
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	86a080e7          	jalr	-1942(ra) # 80004590 <end_op>
    return -1;
    80005d2e:	557d                	li	a0,-1
}
    80005d30:	60ea                	ld	ra,152(sp)
    80005d32:	644a                	ld	s0,144(sp)
    80005d34:	610d                	addi	sp,sp,160
    80005d36:	8082                	ret

0000000080005d38 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d38:	7135                	addi	sp,sp,-160
    80005d3a:	ed06                	sd	ra,152(sp)
    80005d3c:	e922                	sd	s0,144(sp)
    80005d3e:	e526                	sd	s1,136(sp)
    80005d40:	e14a                	sd	s2,128(sp)
    80005d42:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d44:	ffffc097          	auipc	ra,0xffffc
    80005d48:	c3a080e7          	jalr	-966(ra) # 8000197e <myproc>
    80005d4c:	892a                	mv	s2,a0
  
  begin_op();
    80005d4e:	ffffe097          	auipc	ra,0xffffe
    80005d52:	7c2080e7          	jalr	1986(ra) # 80004510 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d56:	08000613          	li	a2,128
    80005d5a:	f6040593          	addi	a1,s0,-160
    80005d5e:	4501                	li	a0,0
    80005d60:	ffffd097          	auipc	ra,0xffffd
    80005d64:	122080e7          	jalr	290(ra) # 80002e82 <argstr>
    80005d68:	04054b63          	bltz	a0,80005dbe <sys_chdir+0x86>
    80005d6c:	f6040513          	addi	a0,s0,-160
    80005d70:	ffffe097          	auipc	ra,0xffffe
    80005d74:	580080e7          	jalr	1408(ra) # 800042f0 <namei>
    80005d78:	84aa                	mv	s1,a0
    80005d7a:	c131                	beqz	a0,80005dbe <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d7c:	ffffe097          	auipc	ra,0xffffe
    80005d80:	dbe080e7          	jalr	-578(ra) # 80003b3a <ilock>
  if(ip->type != T_DIR){
    80005d84:	04449703          	lh	a4,68(s1)
    80005d88:	4785                	li	a5,1
    80005d8a:	04f71063          	bne	a4,a5,80005dca <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d8e:	8526                	mv	a0,s1
    80005d90:	ffffe097          	auipc	ra,0xffffe
    80005d94:	e6c080e7          	jalr	-404(ra) # 80003bfc <iunlock>
  iput(p->cwd);
    80005d98:	16893503          	ld	a0,360(s2)
    80005d9c:	ffffe097          	auipc	ra,0xffffe
    80005da0:	f58080e7          	jalr	-168(ra) # 80003cf4 <iput>
  end_op();
    80005da4:	ffffe097          	auipc	ra,0xffffe
    80005da8:	7ec080e7          	jalr	2028(ra) # 80004590 <end_op>
  p->cwd = ip;
    80005dac:	16993423          	sd	s1,360(s2)
  return 0;
    80005db0:	4501                	li	a0,0
}
    80005db2:	60ea                	ld	ra,152(sp)
    80005db4:	644a                	ld	s0,144(sp)
    80005db6:	64aa                	ld	s1,136(sp)
    80005db8:	690a                	ld	s2,128(sp)
    80005dba:	610d                	addi	sp,sp,160
    80005dbc:	8082                	ret
    end_op();
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	7d2080e7          	jalr	2002(ra) # 80004590 <end_op>
    return -1;
    80005dc6:	557d                	li	a0,-1
    80005dc8:	b7ed                	j	80005db2 <sys_chdir+0x7a>
    iunlockput(ip);
    80005dca:	8526                	mv	a0,s1
    80005dcc:	ffffe097          	auipc	ra,0xffffe
    80005dd0:	fd0080e7          	jalr	-48(ra) # 80003d9c <iunlockput>
    end_op();
    80005dd4:	ffffe097          	auipc	ra,0xffffe
    80005dd8:	7bc080e7          	jalr	1980(ra) # 80004590 <end_op>
    return -1;
    80005ddc:	557d                	li	a0,-1
    80005dde:	bfd1                	j	80005db2 <sys_chdir+0x7a>

0000000080005de0 <sys_exec>:

uint64
sys_exec(void)
{
    80005de0:	7145                	addi	sp,sp,-464
    80005de2:	e786                	sd	ra,456(sp)
    80005de4:	e3a2                	sd	s0,448(sp)
    80005de6:	ff26                	sd	s1,440(sp)
    80005de8:	fb4a                	sd	s2,432(sp)
    80005dea:	f74e                	sd	s3,424(sp)
    80005dec:	f352                	sd	s4,416(sp)
    80005dee:	ef56                	sd	s5,408(sp)
    80005df0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005df2:	08000613          	li	a2,128
    80005df6:	f4040593          	addi	a1,s0,-192
    80005dfa:	4501                	li	a0,0
    80005dfc:	ffffd097          	auipc	ra,0xffffd
    80005e00:	086080e7          	jalr	134(ra) # 80002e82 <argstr>
    return -1;
    80005e04:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e06:	0c054a63          	bltz	a0,80005eda <sys_exec+0xfa>
    80005e0a:	e3840593          	addi	a1,s0,-456
    80005e0e:	4505                	li	a0,1
    80005e10:	ffffd097          	auipc	ra,0xffffd
    80005e14:	050080e7          	jalr	80(ra) # 80002e60 <argaddr>
    80005e18:	0c054163          	bltz	a0,80005eda <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e1c:	10000613          	li	a2,256
    80005e20:	4581                	li	a1,0
    80005e22:	e4040513          	addi	a0,s0,-448
    80005e26:	ffffb097          	auipc	ra,0xffffb
    80005e2a:	e98080e7          	jalr	-360(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e2e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e32:	89a6                	mv	s3,s1
    80005e34:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e36:	02000a13          	li	s4,32
    80005e3a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e3e:	00391793          	slli	a5,s2,0x3
    80005e42:	e3040593          	addi	a1,s0,-464
    80005e46:	e3843503          	ld	a0,-456(s0)
    80005e4a:	953e                	add	a0,a0,a5
    80005e4c:	ffffd097          	auipc	ra,0xffffd
    80005e50:	f58080e7          	jalr	-168(ra) # 80002da4 <fetchaddr>
    80005e54:	02054a63          	bltz	a0,80005e88 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e58:	e3043783          	ld	a5,-464(s0)
    80005e5c:	c3b9                	beqz	a5,80005ea2 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e5e:	ffffb097          	auipc	ra,0xffffb
    80005e62:	c74080e7          	jalr	-908(ra) # 80000ad2 <kalloc>
    80005e66:	85aa                	mv	a1,a0
    80005e68:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e6c:	cd11                	beqz	a0,80005e88 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e6e:	6605                	lui	a2,0x1
    80005e70:	e3043503          	ld	a0,-464(s0)
    80005e74:	ffffd097          	auipc	ra,0xffffd
    80005e78:	f82080e7          	jalr	-126(ra) # 80002df6 <fetchstr>
    80005e7c:	00054663          	bltz	a0,80005e88 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e80:	0905                	addi	s2,s2,1
    80005e82:	09a1                	addi	s3,s3,8
    80005e84:	fb491be3          	bne	s2,s4,80005e3a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e88:	10048913          	addi	s2,s1,256
    80005e8c:	6088                	ld	a0,0(s1)
    80005e8e:	c529                	beqz	a0,80005ed8 <sys_exec+0xf8>
    kfree(argv[i]);
    80005e90:	ffffb097          	auipc	ra,0xffffb
    80005e94:	b46080e7          	jalr	-1210(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e98:	04a1                	addi	s1,s1,8
    80005e9a:	ff2499e3          	bne	s1,s2,80005e8c <sys_exec+0xac>
  return -1;
    80005e9e:	597d                	li	s2,-1
    80005ea0:	a82d                	j	80005eda <sys_exec+0xfa>
      argv[i] = 0;
    80005ea2:	0a8e                	slli	s5,s5,0x3
    80005ea4:	fc040793          	addi	a5,s0,-64
    80005ea8:	9abe                	add	s5,s5,a5
    80005eaa:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005eae:	e4040593          	addi	a1,s0,-448
    80005eb2:	f4040513          	addi	a0,s0,-192
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	178080e7          	jalr	376(ra) # 8000502e <exec>
    80005ebe:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ec0:	10048993          	addi	s3,s1,256
    80005ec4:	6088                	ld	a0,0(s1)
    80005ec6:	c911                	beqz	a0,80005eda <sys_exec+0xfa>
    kfree(argv[i]);
    80005ec8:	ffffb097          	auipc	ra,0xffffb
    80005ecc:	b0e080e7          	jalr	-1266(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ed0:	04a1                	addi	s1,s1,8
    80005ed2:	ff3499e3          	bne	s1,s3,80005ec4 <sys_exec+0xe4>
    80005ed6:	a011                	j	80005eda <sys_exec+0xfa>
  return -1;
    80005ed8:	597d                	li	s2,-1
}
    80005eda:	854a                	mv	a0,s2
    80005edc:	60be                	ld	ra,456(sp)
    80005ede:	641e                	ld	s0,448(sp)
    80005ee0:	74fa                	ld	s1,440(sp)
    80005ee2:	795a                	ld	s2,432(sp)
    80005ee4:	79ba                	ld	s3,424(sp)
    80005ee6:	7a1a                	ld	s4,416(sp)
    80005ee8:	6afa                	ld	s5,408(sp)
    80005eea:	6179                	addi	sp,sp,464
    80005eec:	8082                	ret

0000000080005eee <sys_pipe>:

uint64
sys_pipe(void)
{
    80005eee:	7139                	addi	sp,sp,-64
    80005ef0:	fc06                	sd	ra,56(sp)
    80005ef2:	f822                	sd	s0,48(sp)
    80005ef4:	f426                	sd	s1,40(sp)
    80005ef6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	a86080e7          	jalr	-1402(ra) # 8000197e <myproc>
    80005f00:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f02:	fd840593          	addi	a1,s0,-40
    80005f06:	4501                	li	a0,0
    80005f08:	ffffd097          	auipc	ra,0xffffd
    80005f0c:	f58080e7          	jalr	-168(ra) # 80002e60 <argaddr>
    return -1;
    80005f10:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f12:	0e054063          	bltz	a0,80005ff2 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f16:	fc840593          	addi	a1,s0,-56
    80005f1a:	fd040513          	addi	a0,s0,-48
    80005f1e:	fffff097          	auipc	ra,0xfffff
    80005f22:	dee080e7          	jalr	-530(ra) # 80004d0c <pipealloc>
    return -1;
    80005f26:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f28:	0c054563          	bltz	a0,80005ff2 <sys_pipe+0x104>
  fd0 = -1;
    80005f2c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f30:	fd043503          	ld	a0,-48(s0)
    80005f34:	fffff097          	auipc	ra,0xfffff
    80005f38:	50a080e7          	jalr	1290(ra) # 8000543e <fdalloc>
    80005f3c:	fca42223          	sw	a0,-60(s0)
    80005f40:	08054c63          	bltz	a0,80005fd8 <sys_pipe+0xea>
    80005f44:	fc843503          	ld	a0,-56(s0)
    80005f48:	fffff097          	auipc	ra,0xfffff
    80005f4c:	4f6080e7          	jalr	1270(ra) # 8000543e <fdalloc>
    80005f50:	fca42023          	sw	a0,-64(s0)
    80005f54:	06054863          	bltz	a0,80005fc4 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f58:	4691                	li	a3,4
    80005f5a:	fc440613          	addi	a2,s0,-60
    80005f5e:	fd843583          	ld	a1,-40(s0)
    80005f62:	74a8                	ld	a0,104(s1)
    80005f64:	ffffb097          	auipc	ra,0xffffb
    80005f68:	6da080e7          	jalr	1754(ra) # 8000163e <copyout>
    80005f6c:	02054063          	bltz	a0,80005f8c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f70:	4691                	li	a3,4
    80005f72:	fc040613          	addi	a2,s0,-64
    80005f76:	fd843583          	ld	a1,-40(s0)
    80005f7a:	0591                	addi	a1,a1,4
    80005f7c:	74a8                	ld	a0,104(s1)
    80005f7e:	ffffb097          	auipc	ra,0xffffb
    80005f82:	6c0080e7          	jalr	1728(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f86:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f88:	06055563          	bgez	a0,80005ff2 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005f8c:	fc442783          	lw	a5,-60(s0)
    80005f90:	07f1                	addi	a5,a5,28
    80005f92:	078e                	slli	a5,a5,0x3
    80005f94:	97a6                	add	a5,a5,s1
    80005f96:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005f9a:	fc042503          	lw	a0,-64(s0)
    80005f9e:	0571                	addi	a0,a0,28
    80005fa0:	050e                	slli	a0,a0,0x3
    80005fa2:	9526                	add	a0,a0,s1
    80005fa4:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005fa8:	fd043503          	ld	a0,-48(s0)
    80005fac:	fffff097          	auipc	ra,0xfffff
    80005fb0:	a30080e7          	jalr	-1488(ra) # 800049dc <fileclose>
    fileclose(wf);
    80005fb4:	fc843503          	ld	a0,-56(s0)
    80005fb8:	fffff097          	auipc	ra,0xfffff
    80005fbc:	a24080e7          	jalr	-1500(ra) # 800049dc <fileclose>
    return -1;
    80005fc0:	57fd                	li	a5,-1
    80005fc2:	a805                	j	80005ff2 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005fc4:	fc442783          	lw	a5,-60(s0)
    80005fc8:	0007c863          	bltz	a5,80005fd8 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005fcc:	01c78513          	addi	a0,a5,28
    80005fd0:	050e                	slli	a0,a0,0x3
    80005fd2:	9526                	add	a0,a0,s1
    80005fd4:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005fd8:	fd043503          	ld	a0,-48(s0)
    80005fdc:	fffff097          	auipc	ra,0xfffff
    80005fe0:	a00080e7          	jalr	-1536(ra) # 800049dc <fileclose>
    fileclose(wf);
    80005fe4:	fc843503          	ld	a0,-56(s0)
    80005fe8:	fffff097          	auipc	ra,0xfffff
    80005fec:	9f4080e7          	jalr	-1548(ra) # 800049dc <fileclose>
    return -1;
    80005ff0:	57fd                	li	a5,-1
}
    80005ff2:	853e                	mv	a0,a5
    80005ff4:	70e2                	ld	ra,56(sp)
    80005ff6:	7442                	ld	s0,48(sp)
    80005ff8:	74a2                	ld	s1,40(sp)
    80005ffa:	6121                	addi	sp,sp,64
    80005ffc:	8082                	ret
	...

0000000080006000 <kernelvec>:
    80006000:	7111                	addi	sp,sp,-256
    80006002:	e006                	sd	ra,0(sp)
    80006004:	e40a                	sd	sp,8(sp)
    80006006:	e80e                	sd	gp,16(sp)
    80006008:	ec12                	sd	tp,24(sp)
    8000600a:	f016                	sd	t0,32(sp)
    8000600c:	f41a                	sd	t1,40(sp)
    8000600e:	f81e                	sd	t2,48(sp)
    80006010:	fc22                	sd	s0,56(sp)
    80006012:	e0a6                	sd	s1,64(sp)
    80006014:	e4aa                	sd	a0,72(sp)
    80006016:	e8ae                	sd	a1,80(sp)
    80006018:	ecb2                	sd	a2,88(sp)
    8000601a:	f0b6                	sd	a3,96(sp)
    8000601c:	f4ba                	sd	a4,104(sp)
    8000601e:	f8be                	sd	a5,112(sp)
    80006020:	fcc2                	sd	a6,120(sp)
    80006022:	e146                	sd	a7,128(sp)
    80006024:	e54a                	sd	s2,136(sp)
    80006026:	e94e                	sd	s3,144(sp)
    80006028:	ed52                	sd	s4,152(sp)
    8000602a:	f156                	sd	s5,160(sp)
    8000602c:	f55a                	sd	s6,168(sp)
    8000602e:	f95e                	sd	s7,176(sp)
    80006030:	fd62                	sd	s8,184(sp)
    80006032:	e1e6                	sd	s9,192(sp)
    80006034:	e5ea                	sd	s10,200(sp)
    80006036:	e9ee                	sd	s11,208(sp)
    80006038:	edf2                	sd	t3,216(sp)
    8000603a:	f1f6                	sd	t4,224(sp)
    8000603c:	f5fa                	sd	t5,232(sp)
    8000603e:	f9fe                	sd	t6,240(sp)
    80006040:	c5bfc0ef          	jal	ra,80002c9a <kerneltrap>
    80006044:	6082                	ld	ra,0(sp)
    80006046:	6122                	ld	sp,8(sp)
    80006048:	61c2                	ld	gp,16(sp)
    8000604a:	7282                	ld	t0,32(sp)
    8000604c:	7322                	ld	t1,40(sp)
    8000604e:	73c2                	ld	t2,48(sp)
    80006050:	7462                	ld	s0,56(sp)
    80006052:	6486                	ld	s1,64(sp)
    80006054:	6526                	ld	a0,72(sp)
    80006056:	65c6                	ld	a1,80(sp)
    80006058:	6666                	ld	a2,88(sp)
    8000605a:	7686                	ld	a3,96(sp)
    8000605c:	7726                	ld	a4,104(sp)
    8000605e:	77c6                	ld	a5,112(sp)
    80006060:	7866                	ld	a6,120(sp)
    80006062:	688a                	ld	a7,128(sp)
    80006064:	692a                	ld	s2,136(sp)
    80006066:	69ca                	ld	s3,144(sp)
    80006068:	6a6a                	ld	s4,152(sp)
    8000606a:	7a8a                	ld	s5,160(sp)
    8000606c:	7b2a                	ld	s6,168(sp)
    8000606e:	7bca                	ld	s7,176(sp)
    80006070:	7c6a                	ld	s8,184(sp)
    80006072:	6c8e                	ld	s9,192(sp)
    80006074:	6d2e                	ld	s10,200(sp)
    80006076:	6dce                	ld	s11,208(sp)
    80006078:	6e6e                	ld	t3,216(sp)
    8000607a:	7e8e                	ld	t4,224(sp)
    8000607c:	7f2e                	ld	t5,232(sp)
    8000607e:	7fce                	ld	t6,240(sp)
    80006080:	6111                	addi	sp,sp,256
    80006082:	10200073          	sret
    80006086:	00000013          	nop
    8000608a:	00000013          	nop
    8000608e:	0001                	nop

0000000080006090 <timervec>:
    80006090:	34051573          	csrrw	a0,mscratch,a0
    80006094:	e10c                	sd	a1,0(a0)
    80006096:	e510                	sd	a2,8(a0)
    80006098:	e914                	sd	a3,16(a0)
    8000609a:	6d0c                	ld	a1,24(a0)
    8000609c:	7110                	ld	a2,32(a0)
    8000609e:	6194                	ld	a3,0(a1)
    800060a0:	96b2                	add	a3,a3,a2
    800060a2:	e194                	sd	a3,0(a1)
    800060a4:	4589                	li	a1,2
    800060a6:	14459073          	csrw	sip,a1
    800060aa:	6914                	ld	a3,16(a0)
    800060ac:	6510                	ld	a2,8(a0)
    800060ae:	610c                	ld	a1,0(a0)
    800060b0:	34051573          	csrrw	a0,mscratch,a0
    800060b4:	30200073          	mret
	...

00000000800060ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060ba:	1141                	addi	sp,sp,-16
    800060bc:	e422                	sd	s0,8(sp)
    800060be:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060c0:	0c0007b7          	lui	a5,0xc000
    800060c4:	4705                	li	a4,1
    800060c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060c8:	c3d8                	sw	a4,4(a5)
}
    800060ca:	6422                	ld	s0,8(sp)
    800060cc:	0141                	addi	sp,sp,16
    800060ce:	8082                	ret

00000000800060d0 <plicinithart>:

void
plicinithart(void)
{
    800060d0:	1141                	addi	sp,sp,-16
    800060d2:	e406                	sd	ra,8(sp)
    800060d4:	e022                	sd	s0,0(sp)
    800060d6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060d8:	ffffc097          	auipc	ra,0xffffc
    800060dc:	87a080e7          	jalr	-1926(ra) # 80001952 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060e0:	0085171b          	slliw	a4,a0,0x8
    800060e4:	0c0027b7          	lui	a5,0xc002
    800060e8:	97ba                	add	a5,a5,a4
    800060ea:	40200713          	li	a4,1026
    800060ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060f2:	00d5151b          	slliw	a0,a0,0xd
    800060f6:	0c2017b7          	lui	a5,0xc201
    800060fa:	953e                	add	a0,a0,a5
    800060fc:	00052023          	sw	zero,0(a0)
}
    80006100:	60a2                	ld	ra,8(sp)
    80006102:	6402                	ld	s0,0(sp)
    80006104:	0141                	addi	sp,sp,16
    80006106:	8082                	ret

0000000080006108 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006108:	1141                	addi	sp,sp,-16
    8000610a:	e406                	sd	ra,8(sp)
    8000610c:	e022                	sd	s0,0(sp)
    8000610e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006110:	ffffc097          	auipc	ra,0xffffc
    80006114:	842080e7          	jalr	-1982(ra) # 80001952 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006118:	00d5179b          	slliw	a5,a0,0xd
    8000611c:	0c201537          	lui	a0,0xc201
    80006120:	953e                	add	a0,a0,a5
  return irq;
}
    80006122:	4148                	lw	a0,4(a0)
    80006124:	60a2                	ld	ra,8(sp)
    80006126:	6402                	ld	s0,0(sp)
    80006128:	0141                	addi	sp,sp,16
    8000612a:	8082                	ret

000000008000612c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000612c:	1101                	addi	sp,sp,-32
    8000612e:	ec06                	sd	ra,24(sp)
    80006130:	e822                	sd	s0,16(sp)
    80006132:	e426                	sd	s1,8(sp)
    80006134:	1000                	addi	s0,sp,32
    80006136:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006138:	ffffc097          	auipc	ra,0xffffc
    8000613c:	81a080e7          	jalr	-2022(ra) # 80001952 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006140:	00d5151b          	slliw	a0,a0,0xd
    80006144:	0c2017b7          	lui	a5,0xc201
    80006148:	97aa                	add	a5,a5,a0
    8000614a:	c3c4                	sw	s1,4(a5)
}
    8000614c:	60e2                	ld	ra,24(sp)
    8000614e:	6442                	ld	s0,16(sp)
    80006150:	64a2                	ld	s1,8(sp)
    80006152:	6105                	addi	sp,sp,32
    80006154:	8082                	ret

0000000080006156 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006156:	1141                	addi	sp,sp,-16
    80006158:	e406                	sd	ra,8(sp)
    8000615a:	e022                	sd	s0,0(sp)
    8000615c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000615e:	479d                	li	a5,7
    80006160:	06a7c963          	blt	a5,a0,800061d2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006164:	0001d797          	auipc	a5,0x1d
    80006168:	e9c78793          	addi	a5,a5,-356 # 80023000 <disk>
    8000616c:	00a78733          	add	a4,a5,a0
    80006170:	6789                	lui	a5,0x2
    80006172:	97ba                	add	a5,a5,a4
    80006174:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006178:	e7ad                	bnez	a5,800061e2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000617a:	00451793          	slli	a5,a0,0x4
    8000617e:	0001f717          	auipc	a4,0x1f
    80006182:	e8270713          	addi	a4,a4,-382 # 80025000 <disk+0x2000>
    80006186:	6314                	ld	a3,0(a4)
    80006188:	96be                	add	a3,a3,a5
    8000618a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000618e:	6314                	ld	a3,0(a4)
    80006190:	96be                	add	a3,a3,a5
    80006192:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006196:	6314                	ld	a3,0(a4)
    80006198:	96be                	add	a3,a3,a5
    8000619a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000619e:	6318                	ld	a4,0(a4)
    800061a0:	97ba                	add	a5,a5,a4
    800061a2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800061a6:	0001d797          	auipc	a5,0x1d
    800061aa:	e5a78793          	addi	a5,a5,-422 # 80023000 <disk>
    800061ae:	97aa                	add	a5,a5,a0
    800061b0:	6509                	lui	a0,0x2
    800061b2:	953e                	add	a0,a0,a5
    800061b4:	4785                	li	a5,1
    800061b6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800061ba:	0001f517          	auipc	a0,0x1f
    800061be:	e5e50513          	addi	a0,a0,-418 # 80025018 <disk+0x2018>
    800061c2:	ffffc097          	auipc	ra,0xffffc
    800061c6:	168080e7          	jalr	360(ra) # 8000232a <wakeup>
}
    800061ca:	60a2                	ld	ra,8(sp)
    800061cc:	6402                	ld	s0,0(sp)
    800061ce:	0141                	addi	sp,sp,16
    800061d0:	8082                	ret
    panic("free_desc 1");
    800061d2:	00002517          	auipc	a0,0x2
    800061d6:	76e50513          	addi	a0,a0,1902 # 80008940 <syscalls+0x330>
    800061da:	ffffa097          	auipc	ra,0xffffa
    800061de:	350080e7          	jalr	848(ra) # 8000052a <panic>
    panic("free_desc 2");
    800061e2:	00002517          	auipc	a0,0x2
    800061e6:	76e50513          	addi	a0,a0,1902 # 80008950 <syscalls+0x340>
    800061ea:	ffffa097          	auipc	ra,0xffffa
    800061ee:	340080e7          	jalr	832(ra) # 8000052a <panic>

00000000800061f2 <virtio_disk_init>:
{
    800061f2:	1101                	addi	sp,sp,-32
    800061f4:	ec06                	sd	ra,24(sp)
    800061f6:	e822                	sd	s0,16(sp)
    800061f8:	e426                	sd	s1,8(sp)
    800061fa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061fc:	00002597          	auipc	a1,0x2
    80006200:	76458593          	addi	a1,a1,1892 # 80008960 <syscalls+0x350>
    80006204:	0001f517          	auipc	a0,0x1f
    80006208:	f2450513          	addi	a0,a0,-220 # 80025128 <disk+0x2128>
    8000620c:	ffffb097          	auipc	ra,0xffffb
    80006210:	926080e7          	jalr	-1754(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006214:	100017b7          	lui	a5,0x10001
    80006218:	4398                	lw	a4,0(a5)
    8000621a:	2701                	sext.w	a4,a4
    8000621c:	747277b7          	lui	a5,0x74727
    80006220:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006224:	0ef71163          	bne	a4,a5,80006306 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006228:	100017b7          	lui	a5,0x10001
    8000622c:	43dc                	lw	a5,4(a5)
    8000622e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006230:	4705                	li	a4,1
    80006232:	0ce79a63          	bne	a5,a4,80006306 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006236:	100017b7          	lui	a5,0x10001
    8000623a:	479c                	lw	a5,8(a5)
    8000623c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000623e:	4709                	li	a4,2
    80006240:	0ce79363          	bne	a5,a4,80006306 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006244:	100017b7          	lui	a5,0x10001
    80006248:	47d8                	lw	a4,12(a5)
    8000624a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000624c:	554d47b7          	lui	a5,0x554d4
    80006250:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006254:	0af71963          	bne	a4,a5,80006306 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006258:	100017b7          	lui	a5,0x10001
    8000625c:	4705                	li	a4,1
    8000625e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006260:	470d                	li	a4,3
    80006262:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006264:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006266:	c7ffe737          	lui	a4,0xc7ffe
    8000626a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000626e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006270:	2701                	sext.w	a4,a4
    80006272:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006274:	472d                	li	a4,11
    80006276:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006278:	473d                	li	a4,15
    8000627a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000627c:	6705                	lui	a4,0x1
    8000627e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006280:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006284:	5bdc                	lw	a5,52(a5)
    80006286:	2781                	sext.w	a5,a5
  if(max == 0)
    80006288:	c7d9                	beqz	a5,80006316 <virtio_disk_init+0x124>
  if(max < NUM)
    8000628a:	471d                	li	a4,7
    8000628c:	08f77d63          	bgeu	a4,a5,80006326 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006290:	100014b7          	lui	s1,0x10001
    80006294:	47a1                	li	a5,8
    80006296:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006298:	6609                	lui	a2,0x2
    8000629a:	4581                	li	a1,0
    8000629c:	0001d517          	auipc	a0,0x1d
    800062a0:	d6450513          	addi	a0,a0,-668 # 80023000 <disk>
    800062a4:	ffffb097          	auipc	ra,0xffffb
    800062a8:	a1a080e7          	jalr	-1510(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800062ac:	0001d717          	auipc	a4,0x1d
    800062b0:	d5470713          	addi	a4,a4,-684 # 80023000 <disk>
    800062b4:	00c75793          	srli	a5,a4,0xc
    800062b8:	2781                	sext.w	a5,a5
    800062ba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800062bc:	0001f797          	auipc	a5,0x1f
    800062c0:	d4478793          	addi	a5,a5,-700 # 80025000 <disk+0x2000>
    800062c4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800062c6:	0001d717          	auipc	a4,0x1d
    800062ca:	dba70713          	addi	a4,a4,-582 # 80023080 <disk+0x80>
    800062ce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800062d0:	0001e717          	auipc	a4,0x1e
    800062d4:	d3070713          	addi	a4,a4,-720 # 80024000 <disk+0x1000>
    800062d8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800062da:	4705                	li	a4,1
    800062dc:	00e78c23          	sb	a4,24(a5)
    800062e0:	00e78ca3          	sb	a4,25(a5)
    800062e4:	00e78d23          	sb	a4,26(a5)
    800062e8:	00e78da3          	sb	a4,27(a5)
    800062ec:	00e78e23          	sb	a4,28(a5)
    800062f0:	00e78ea3          	sb	a4,29(a5)
    800062f4:	00e78f23          	sb	a4,30(a5)
    800062f8:	00e78fa3          	sb	a4,31(a5)
}
    800062fc:	60e2                	ld	ra,24(sp)
    800062fe:	6442                	ld	s0,16(sp)
    80006300:	64a2                	ld	s1,8(sp)
    80006302:	6105                	addi	sp,sp,32
    80006304:	8082                	ret
    panic("could not find virtio disk");
    80006306:	00002517          	auipc	a0,0x2
    8000630a:	66a50513          	addi	a0,a0,1642 # 80008970 <syscalls+0x360>
    8000630e:	ffffa097          	auipc	ra,0xffffa
    80006312:	21c080e7          	jalr	540(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006316:	00002517          	auipc	a0,0x2
    8000631a:	67a50513          	addi	a0,a0,1658 # 80008990 <syscalls+0x380>
    8000631e:	ffffa097          	auipc	ra,0xffffa
    80006322:	20c080e7          	jalr	524(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006326:	00002517          	auipc	a0,0x2
    8000632a:	68a50513          	addi	a0,a0,1674 # 800089b0 <syscalls+0x3a0>
    8000632e:	ffffa097          	auipc	ra,0xffffa
    80006332:	1fc080e7          	jalr	508(ra) # 8000052a <panic>

0000000080006336 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006336:	7119                	addi	sp,sp,-128
    80006338:	fc86                	sd	ra,120(sp)
    8000633a:	f8a2                	sd	s0,112(sp)
    8000633c:	f4a6                	sd	s1,104(sp)
    8000633e:	f0ca                	sd	s2,96(sp)
    80006340:	ecce                	sd	s3,88(sp)
    80006342:	e8d2                	sd	s4,80(sp)
    80006344:	e4d6                	sd	s5,72(sp)
    80006346:	e0da                	sd	s6,64(sp)
    80006348:	fc5e                	sd	s7,56(sp)
    8000634a:	f862                	sd	s8,48(sp)
    8000634c:	f466                	sd	s9,40(sp)
    8000634e:	f06a                	sd	s10,32(sp)
    80006350:	ec6e                	sd	s11,24(sp)
    80006352:	0100                	addi	s0,sp,128
    80006354:	8aaa                	mv	s5,a0
    80006356:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006358:	00c52c83          	lw	s9,12(a0)
    8000635c:	001c9c9b          	slliw	s9,s9,0x1
    80006360:	1c82                	slli	s9,s9,0x20
    80006362:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006366:	0001f517          	auipc	a0,0x1f
    8000636a:	dc250513          	addi	a0,a0,-574 # 80025128 <disk+0x2128>
    8000636e:	ffffb097          	auipc	ra,0xffffb
    80006372:	854080e7          	jalr	-1964(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006376:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006378:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000637a:	0001dc17          	auipc	s8,0x1d
    8000637e:	c86c0c13          	addi	s8,s8,-890 # 80023000 <disk>
    80006382:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006384:	4b0d                	li	s6,3
    80006386:	a0ad                	j	800063f0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006388:	00fc0733          	add	a4,s8,a5
    8000638c:	975e                	add	a4,a4,s7
    8000638e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006392:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006394:	0207c563          	bltz	a5,800063be <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006398:	2905                	addiw	s2,s2,1
    8000639a:	0611                	addi	a2,a2,4
    8000639c:	19690d63          	beq	s2,s6,80006536 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    800063a0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800063a2:	0001f717          	auipc	a4,0x1f
    800063a6:	c7670713          	addi	a4,a4,-906 # 80025018 <disk+0x2018>
    800063aa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800063ac:	00074683          	lbu	a3,0(a4)
    800063b0:	fee1                	bnez	a3,80006388 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800063b2:	2785                	addiw	a5,a5,1
    800063b4:	0705                	addi	a4,a4,1
    800063b6:	fe979be3          	bne	a5,s1,800063ac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800063ba:	57fd                	li	a5,-1
    800063bc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800063be:	01205d63          	blez	s2,800063d8 <virtio_disk_rw+0xa2>
    800063c2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800063c4:	000a2503          	lw	a0,0(s4)
    800063c8:	00000097          	auipc	ra,0x0
    800063cc:	d8e080e7          	jalr	-626(ra) # 80006156 <free_desc>
      for(int j = 0; j < i; j++)
    800063d0:	2d85                	addiw	s11,s11,1
    800063d2:	0a11                	addi	s4,s4,4
    800063d4:	ffb918e3          	bne	s2,s11,800063c4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063d8:	0001f597          	auipc	a1,0x1f
    800063dc:	d5058593          	addi	a1,a1,-688 # 80025128 <disk+0x2128>
    800063e0:	0001f517          	auipc	a0,0x1f
    800063e4:	c3850513          	addi	a0,a0,-968 # 80025018 <disk+0x2018>
    800063e8:	ffffc097          	auipc	ra,0xffffc
    800063ec:	db6080e7          	jalr	-586(ra) # 8000219e <sleep>
  for(int i = 0; i < 3; i++){
    800063f0:	f8040a13          	addi	s4,s0,-128
{
    800063f4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800063f6:	894e                	mv	s2,s3
    800063f8:	b765                	j	800063a0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800063fa:	0001f697          	auipc	a3,0x1f
    800063fe:	c066b683          	ld	a3,-1018(a3) # 80025000 <disk+0x2000>
    80006402:	96ba                	add	a3,a3,a4
    80006404:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006408:	0001d817          	auipc	a6,0x1d
    8000640c:	bf880813          	addi	a6,a6,-1032 # 80023000 <disk>
    80006410:	0001f697          	auipc	a3,0x1f
    80006414:	bf068693          	addi	a3,a3,-1040 # 80025000 <disk+0x2000>
    80006418:	6290                	ld	a2,0(a3)
    8000641a:	963a                	add	a2,a2,a4
    8000641c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006420:	0015e593          	ori	a1,a1,1
    80006424:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006428:	f8842603          	lw	a2,-120(s0)
    8000642c:	628c                	ld	a1,0(a3)
    8000642e:	972e                	add	a4,a4,a1
    80006430:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006434:	20050593          	addi	a1,a0,512
    80006438:	0592                	slli	a1,a1,0x4
    8000643a:	95c2                	add	a1,a1,a6
    8000643c:	577d                	li	a4,-1
    8000643e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006442:	00461713          	slli	a4,a2,0x4
    80006446:	6290                	ld	a2,0(a3)
    80006448:	963a                	add	a2,a2,a4
    8000644a:	03078793          	addi	a5,a5,48
    8000644e:	97c2                	add	a5,a5,a6
    80006450:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006452:	629c                	ld	a5,0(a3)
    80006454:	97ba                	add	a5,a5,a4
    80006456:	4605                	li	a2,1
    80006458:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000645a:	629c                	ld	a5,0(a3)
    8000645c:	97ba                	add	a5,a5,a4
    8000645e:	4809                	li	a6,2
    80006460:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006464:	629c                	ld	a5,0(a3)
    80006466:	973e                	add	a4,a4,a5
    80006468:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000646c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006470:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006474:	6698                	ld	a4,8(a3)
    80006476:	00275783          	lhu	a5,2(a4)
    8000647a:	8b9d                	andi	a5,a5,7
    8000647c:	0786                	slli	a5,a5,0x1
    8000647e:	97ba                	add	a5,a5,a4
    80006480:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006484:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006488:	6698                	ld	a4,8(a3)
    8000648a:	00275783          	lhu	a5,2(a4)
    8000648e:	2785                	addiw	a5,a5,1
    80006490:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006494:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006498:	100017b7          	lui	a5,0x10001
    8000649c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800064a0:	004aa783          	lw	a5,4(s5)
    800064a4:	02c79163          	bne	a5,a2,800064c6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800064a8:	0001f917          	auipc	s2,0x1f
    800064ac:	c8090913          	addi	s2,s2,-896 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800064b0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800064b2:	85ca                	mv	a1,s2
    800064b4:	8556                	mv	a0,s5
    800064b6:	ffffc097          	auipc	ra,0xffffc
    800064ba:	ce8080e7          	jalr	-792(ra) # 8000219e <sleep>
  while(b->disk == 1) {
    800064be:	004aa783          	lw	a5,4(s5)
    800064c2:	fe9788e3          	beq	a5,s1,800064b2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800064c6:	f8042903          	lw	s2,-128(s0)
    800064ca:	20090793          	addi	a5,s2,512
    800064ce:	00479713          	slli	a4,a5,0x4
    800064d2:	0001d797          	auipc	a5,0x1d
    800064d6:	b2e78793          	addi	a5,a5,-1234 # 80023000 <disk>
    800064da:	97ba                	add	a5,a5,a4
    800064dc:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800064e0:	0001f997          	auipc	s3,0x1f
    800064e4:	b2098993          	addi	s3,s3,-1248 # 80025000 <disk+0x2000>
    800064e8:	00491713          	slli	a4,s2,0x4
    800064ec:	0009b783          	ld	a5,0(s3)
    800064f0:	97ba                	add	a5,a5,a4
    800064f2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800064f6:	854a                	mv	a0,s2
    800064f8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800064fc:	00000097          	auipc	ra,0x0
    80006500:	c5a080e7          	jalr	-934(ra) # 80006156 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006504:	8885                	andi	s1,s1,1
    80006506:	f0ed                	bnez	s1,800064e8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006508:	0001f517          	auipc	a0,0x1f
    8000650c:	c2050513          	addi	a0,a0,-992 # 80025128 <disk+0x2128>
    80006510:	ffffa097          	auipc	ra,0xffffa
    80006514:	766080e7          	jalr	1894(ra) # 80000c76 <release>
}
    80006518:	70e6                	ld	ra,120(sp)
    8000651a:	7446                	ld	s0,112(sp)
    8000651c:	74a6                	ld	s1,104(sp)
    8000651e:	7906                	ld	s2,96(sp)
    80006520:	69e6                	ld	s3,88(sp)
    80006522:	6a46                	ld	s4,80(sp)
    80006524:	6aa6                	ld	s5,72(sp)
    80006526:	6b06                	ld	s6,64(sp)
    80006528:	7be2                	ld	s7,56(sp)
    8000652a:	7c42                	ld	s8,48(sp)
    8000652c:	7ca2                	ld	s9,40(sp)
    8000652e:	7d02                	ld	s10,32(sp)
    80006530:	6de2                	ld	s11,24(sp)
    80006532:	6109                	addi	sp,sp,128
    80006534:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006536:	f8042503          	lw	a0,-128(s0)
    8000653a:	20050793          	addi	a5,a0,512
    8000653e:	0792                	slli	a5,a5,0x4
  if(write)
    80006540:	0001d817          	auipc	a6,0x1d
    80006544:	ac080813          	addi	a6,a6,-1344 # 80023000 <disk>
    80006548:	00f80733          	add	a4,a6,a5
    8000654c:	01a036b3          	snez	a3,s10
    80006550:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006554:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006558:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000655c:	7679                	lui	a2,0xffffe
    8000655e:	963e                	add	a2,a2,a5
    80006560:	0001f697          	auipc	a3,0x1f
    80006564:	aa068693          	addi	a3,a3,-1376 # 80025000 <disk+0x2000>
    80006568:	6298                	ld	a4,0(a3)
    8000656a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000656c:	0a878593          	addi	a1,a5,168
    80006570:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006572:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006574:	6298                	ld	a4,0(a3)
    80006576:	9732                	add	a4,a4,a2
    80006578:	45c1                	li	a1,16
    8000657a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000657c:	6298                	ld	a4,0(a3)
    8000657e:	9732                	add	a4,a4,a2
    80006580:	4585                	li	a1,1
    80006582:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006586:	f8442703          	lw	a4,-124(s0)
    8000658a:	628c                	ld	a1,0(a3)
    8000658c:	962e                	add	a2,a2,a1
    8000658e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006592:	0712                	slli	a4,a4,0x4
    80006594:	6290                	ld	a2,0(a3)
    80006596:	963a                	add	a2,a2,a4
    80006598:	058a8593          	addi	a1,s5,88
    8000659c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000659e:	6294                	ld	a3,0(a3)
    800065a0:	96ba                	add	a3,a3,a4
    800065a2:	40000613          	li	a2,1024
    800065a6:	c690                	sw	a2,8(a3)
  if(write)
    800065a8:	e40d19e3          	bnez	s10,800063fa <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800065ac:	0001f697          	auipc	a3,0x1f
    800065b0:	a546b683          	ld	a3,-1452(a3) # 80025000 <disk+0x2000>
    800065b4:	96ba                	add	a3,a3,a4
    800065b6:	4609                	li	a2,2
    800065b8:	00c69623          	sh	a2,12(a3)
    800065bc:	b5b1                	j	80006408 <virtio_disk_rw+0xd2>

00000000800065be <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800065be:	1101                	addi	sp,sp,-32
    800065c0:	ec06                	sd	ra,24(sp)
    800065c2:	e822                	sd	s0,16(sp)
    800065c4:	e426                	sd	s1,8(sp)
    800065c6:	e04a                	sd	s2,0(sp)
    800065c8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065ca:	0001f517          	auipc	a0,0x1f
    800065ce:	b5e50513          	addi	a0,a0,-1186 # 80025128 <disk+0x2128>
    800065d2:	ffffa097          	auipc	ra,0xffffa
    800065d6:	5f0080e7          	jalr	1520(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065da:	10001737          	lui	a4,0x10001
    800065de:	533c                	lw	a5,96(a4)
    800065e0:	8b8d                	andi	a5,a5,3
    800065e2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800065e4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800065e8:	0001f797          	auipc	a5,0x1f
    800065ec:	a1878793          	addi	a5,a5,-1512 # 80025000 <disk+0x2000>
    800065f0:	6b94                	ld	a3,16(a5)
    800065f2:	0207d703          	lhu	a4,32(a5)
    800065f6:	0026d783          	lhu	a5,2(a3)
    800065fa:	06f70163          	beq	a4,a5,8000665c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065fe:	0001d917          	auipc	s2,0x1d
    80006602:	a0290913          	addi	s2,s2,-1534 # 80023000 <disk>
    80006606:	0001f497          	auipc	s1,0x1f
    8000660a:	9fa48493          	addi	s1,s1,-1542 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000660e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006612:	6898                	ld	a4,16(s1)
    80006614:	0204d783          	lhu	a5,32(s1)
    80006618:	8b9d                	andi	a5,a5,7
    8000661a:	078e                	slli	a5,a5,0x3
    8000661c:	97ba                	add	a5,a5,a4
    8000661e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006620:	20078713          	addi	a4,a5,512
    80006624:	0712                	slli	a4,a4,0x4
    80006626:	974a                	add	a4,a4,s2
    80006628:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000662c:	e731                	bnez	a4,80006678 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000662e:	20078793          	addi	a5,a5,512
    80006632:	0792                	slli	a5,a5,0x4
    80006634:	97ca                	add	a5,a5,s2
    80006636:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006638:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000663c:	ffffc097          	auipc	ra,0xffffc
    80006640:	cee080e7          	jalr	-786(ra) # 8000232a <wakeup>

    disk.used_idx += 1;
    80006644:	0204d783          	lhu	a5,32(s1)
    80006648:	2785                	addiw	a5,a5,1
    8000664a:	17c2                	slli	a5,a5,0x30
    8000664c:	93c1                	srli	a5,a5,0x30
    8000664e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006652:	6898                	ld	a4,16(s1)
    80006654:	00275703          	lhu	a4,2(a4)
    80006658:	faf71be3          	bne	a4,a5,8000660e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000665c:	0001f517          	auipc	a0,0x1f
    80006660:	acc50513          	addi	a0,a0,-1332 # 80025128 <disk+0x2128>
    80006664:	ffffa097          	auipc	ra,0xffffa
    80006668:	612080e7          	jalr	1554(ra) # 80000c76 <release>
}
    8000666c:	60e2                	ld	ra,24(sp)
    8000666e:	6442                	ld	s0,16(sp)
    80006670:	64a2                	ld	s1,8(sp)
    80006672:	6902                	ld	s2,0(sp)
    80006674:	6105                	addi	sp,sp,32
    80006676:	8082                	ret
      panic("virtio_disk_intr status");
    80006678:	00002517          	auipc	a0,0x2
    8000667c:	35850513          	addi	a0,a0,856 # 800089d0 <syscalls+0x3c0>
    80006680:	ffffa097          	auipc	ra,0xffffa
    80006684:	eaa080e7          	jalr	-342(ra) # 8000052a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
