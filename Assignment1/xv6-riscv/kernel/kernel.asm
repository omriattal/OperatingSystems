
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
    80000068:	dbc78793          	addi	a5,a5,-580 # 80005e20 <timervec>
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
    80000122:	330080e7          	jalr	816(ra) # 8000244e <either_copyin>
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
    800001c6:	e92080e7          	jalr	-366(ra) # 80002054 <sleep>
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
    80000202:	1fa080e7          	jalr	506(ra) # 800023f8 <either_copyout>
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
    800002e2:	1c6080e7          	jalr	454(ra) # 800024a4 <procdump>
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
    80000436:	dae080e7          	jalr	-594(ra) # 800021e0 <wakeup>
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
    80000882:	962080e7          	jalr	-1694(ra) # 800021e0 <wakeup>
    
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
    8000090a:	00001097          	auipc	ra,0x1
    8000090e:	74a080e7          	jalr	1866(ra) # 80002054 <sleep>
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
    80000eb6:	8c2080e7          	jalr	-1854(ra) # 80002774 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	fa6080e7          	jalr	-90(ra) # 80005e60 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	fe0080e7          	jalr	-32(ra) # 80001ea2 <scheduler>
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
    80000f2e:	822080e7          	jalr	-2014(ra) # 8000274c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	842080e7          	jalr	-1982(ra) # 80002774 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	f10080e7          	jalr	-240(ra) # 80005e4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	f1e080e7          	jalr	-226(ra) # 80005e60 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	0e4080e7          	jalr	228(ra) # 8000302e <binit>
    iinit();         // inode cache
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	776080e7          	jalr	1910(ra) # 800036c8 <iinit>
    fileinit();      // file table
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	724080e7          	jalr	1828(ra) # 8000467e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	020080e7          	jalr	32(ra) # 80005f82 <virtio_disk_init>
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
    800019dc:	db4080e7          	jalr	-588(ra) # 8000278c <usertrapret>
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
    800019f6:	c56080e7          	jalr	-938(ra) # 80003648 <fsinit>
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
    80001cc6:	3b4080e7          	jalr	948(ra) # 80004076 <namei>
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
    80001e0e:	906080e7          	jalr	-1786(ra) # 80004710 <filedup>
    80001e12:	00a93023          	sd	a0,0(s2)
    80001e16:	b7e5                	j	80001dfe <fork+0xa4>
	np->cwd = idup(p->cwd);
    80001e18:	168ab503          	ld	a0,360(s5)
    80001e1c:	00002097          	auipc	ra,0x2
    80001e20:	a66080e7          	jalr	-1434(ra) # 80003882 <idup>
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

0000000080001ea2 <scheduler>:
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
			if (p->state == RUNNABLE)
    80001ed6:	498d                	li	s3,3
				p->state = RUNNING;
    80001ed8:	4b11                	li	s6,4
				c->proc = p;
    80001eda:	079e                	slli	a5,a5,0x7
    80001edc:	0000fa17          	auipc	s4,0xf
    80001ee0:	3c4a0a13          	addi	s4,s4,964 # 800112a0 <pid_lock>
    80001ee4:	9a3e                	add	s4,s4,a5
		for (p = proc; p < &proc[NPROC]; p++)
    80001ee6:	00015917          	auipc	s2,0x15
    80001eea:	7ea90913          	addi	s2,s2,2026 # 800176d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef6:	10079073          	csrw	sstatus,a5
    80001efa:	0000f497          	auipc	s1,0xf
    80001efe:	7d648493          	addi	s1,s1,2006 # 800116d0 <proc>
    80001f02:	a811                	j	80001f16 <scheduler+0x74>
			release(&p->lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d70080e7          	jalr	-656(ra) # 80000c76 <release>
		for (p = proc; p < &proc[NPROC]; p++)
    80001f0e:	18048493          	addi	s1,s1,384
    80001f12:	fd248ee3          	beq	s1,s2,80001eee <scheduler+0x4c>
			acquire(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	caa080e7          	jalr	-854(ra) # 80000bc2 <acquire>
			if (p->state == RUNNABLE)
    80001f20:	4c9c                	lw	a5,24(s1)
    80001f22:	ff3791e3          	bne	a5,s3,80001f04 <scheduler+0x62>
				p->state = RUNNING;
    80001f26:	0164ac23          	sw	s6,24(s1)
				c->proc = p;
    80001f2a:	029a3823          	sd	s1,48(s4)
				swtch(&c->context, &p->context);
    80001f2e:	07848593          	addi	a1,s1,120
    80001f32:	8556                	mv	a0,s5
    80001f34:	00000097          	auipc	ra,0x0
    80001f38:	7ae080e7          	jalr	1966(ra) # 800026e2 <swtch>
				c->proc = 0;
    80001f3c:	020a3823          	sd	zero,48(s4)
    80001f40:	b7d1                	j	80001f04 <scheduler+0x62>

0000000080001f42 <sched>:
{
    80001f42:	7179                	addi	sp,sp,-48
    80001f44:	f406                	sd	ra,40(sp)
    80001f46:	f022                	sd	s0,32(sp)
    80001f48:	ec26                	sd	s1,24(sp)
    80001f4a:	e84a                	sd	s2,16(sp)
    80001f4c:	e44e                	sd	s3,8(sp)
    80001f4e:	1800                	addi	s0,sp,48
	struct proc *p = myproc();
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	a2e080e7          	jalr	-1490(ra) # 8000197e <myproc>
    80001f58:	84aa                	mv	s1,a0
	if (!holding(&p->lock))
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	bee080e7          	jalr	-1042(ra) # 80000b48 <holding>
    80001f62:	c93d                	beqz	a0,80001fd8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f64:	8792                	mv	a5,tp
	if (mycpu()->noff != 1)
    80001f66:	2781                	sext.w	a5,a5
    80001f68:	079e                	slli	a5,a5,0x7
    80001f6a:	0000f717          	auipc	a4,0xf
    80001f6e:	33670713          	addi	a4,a4,822 # 800112a0 <pid_lock>
    80001f72:	97ba                	add	a5,a5,a4
    80001f74:	0a87a703          	lw	a4,168(a5)
    80001f78:	4785                	li	a5,1
    80001f7a:	06f71763          	bne	a4,a5,80001fe8 <sched+0xa6>
	if (p->state == RUNNING)
    80001f7e:	4c98                	lw	a4,24(s1)
    80001f80:	4791                	li	a5,4
    80001f82:	06f70b63          	beq	a4,a5,80001ff8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8a:	8b89                	andi	a5,a5,2
	if (intr_get())
    80001f8c:	efb5                	bnez	a5,80002008 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8e:	8792                	mv	a5,tp
	intena = mycpu()->intena;
    80001f90:	0000f917          	auipc	s2,0xf
    80001f94:	31090913          	addi	s2,s2,784 # 800112a0 <pid_lock>
    80001f98:	2781                	sext.w	a5,a5
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	97ca                	add	a5,a5,s2
    80001f9e:	0ac7a983          	lw	s3,172(a5)
    80001fa2:	8792                	mv	a5,tp
	swtch(&p->context, &mycpu()->context);
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	0000f597          	auipc	a1,0xf
    80001fac:	33058593          	addi	a1,a1,816 # 800112d8 <cpus+0x8>
    80001fb0:	95be                	add	a1,a1,a5
    80001fb2:	07848513          	addi	a0,s1,120
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	72c080e7          	jalr	1836(ra) # 800026e2 <swtch>
    80001fbe:	8792                	mv	a5,tp
	mycpu()->intena = intena;
    80001fc0:	2781                	sext.w	a5,a5
    80001fc2:	079e                	slli	a5,a5,0x7
    80001fc4:	97ca                	add	a5,a5,s2
    80001fc6:	0b37a623          	sw	s3,172(a5)
}
    80001fca:	70a2                	ld	ra,40(sp)
    80001fcc:	7402                	ld	s0,32(sp)
    80001fce:	64e2                	ld	s1,24(sp)
    80001fd0:	6942                	ld	s2,16(sp)
    80001fd2:	69a2                	ld	s3,8(sp)
    80001fd4:	6145                	addi	sp,sp,48
    80001fd6:	8082                	ret
		panic("sched p->lock");
    80001fd8:	00006517          	auipc	a0,0x6
    80001fdc:	22850513          	addi	a0,a0,552 # 80008200 <digits+0x1c0>
    80001fe0:	ffffe097          	auipc	ra,0xffffe
    80001fe4:	54a080e7          	jalr	1354(ra) # 8000052a <panic>
		panic("sched locks");
    80001fe8:	00006517          	auipc	a0,0x6
    80001fec:	22850513          	addi	a0,a0,552 # 80008210 <digits+0x1d0>
    80001ff0:	ffffe097          	auipc	ra,0xffffe
    80001ff4:	53a080e7          	jalr	1338(ra) # 8000052a <panic>
		panic("sched running");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	22850513          	addi	a0,a0,552 # 80008220 <digits+0x1e0>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	52a080e7          	jalr	1322(ra) # 8000052a <panic>
		panic("sched interruptible");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	22850513          	addi	a0,a0,552 # 80008230 <digits+0x1f0>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	51a080e7          	jalr	1306(ra) # 8000052a <panic>

0000000080002018 <yield>:
{
    80002018:	1101                	addi	sp,sp,-32
    8000201a:	ec06                	sd	ra,24(sp)
    8000201c:	e822                	sd	s0,16(sp)
    8000201e:	e426                	sd	s1,8(sp)
    80002020:	1000                	addi	s0,sp,32
	struct proc *p = myproc();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	95c080e7          	jalr	-1700(ra) # 8000197e <myproc>
    8000202a:	84aa                	mv	s1,a0
	acquire(&p->lock);
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	b96080e7          	jalr	-1130(ra) # 80000bc2 <acquire>
	p->state = RUNNABLE;
    80002034:	478d                	li	a5,3
    80002036:	cc9c                	sw	a5,24(s1)
	sched();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	f0a080e7          	jalr	-246(ra) # 80001f42 <sched>
	release(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c34080e7          	jalr	-972(ra) # 80000c76 <release>
}
    8000204a:	60e2                	ld	ra,24(sp)
    8000204c:	6442                	ld	s0,16(sp)
    8000204e:	64a2                	ld	s1,8(sp)
    80002050:	6105                	addi	sp,sp,32
    80002052:	8082                	ret

0000000080002054 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002054:	7179                	addi	sp,sp,-48
    80002056:	f406                	sd	ra,40(sp)
    80002058:	f022                	sd	s0,32(sp)
    8000205a:	ec26                	sd	s1,24(sp)
    8000205c:	e84a                	sd	s2,16(sp)
    8000205e:	e44e                	sd	s3,8(sp)
    80002060:	1800                	addi	s0,sp,48
    80002062:	89aa                	mv	s3,a0
    80002064:	892e                	mv	s2,a1
	struct proc *p = myproc();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	918080e7          	jalr	-1768(ra) # 8000197e <myproc>
    8000206e:	84aa                	mv	s1,a0
	// Once we hold p->lock, we can be
	// guaranteed that we won't miss any wakeup
	// (wakeup locks p->lock),
	// so it's okay to release lk.

	acquire(&p->lock); //DOC: sleeplock1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	b52080e7          	jalr	-1198(ra) # 80000bc2 <acquire>
	release(lk);
    80002078:	854a                	mv	a0,s2
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	bfc080e7          	jalr	-1028(ra) # 80000c76 <release>

	// Go to sleep.
	p->chan = chan;
    80002082:	0334b023          	sd	s3,32(s1)
	p->state = SLEEPING;
    80002086:	4789                	li	a5,2
    80002088:	cc9c                	sw	a5,24(s1)

	sched();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	eb8080e7          	jalr	-328(ra) # 80001f42 <sched>

	// Tidy up.
	p->chan = 0;
    80002092:	0204b023          	sd	zero,32(s1)

	// Reacquire original lock.
	release(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	bde080e7          	jalr	-1058(ra) # 80000c76 <release>
	acquire(lk);
    800020a0:	854a                	mv	a0,s2
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b20080e7          	jalr	-1248(ra) # 80000bc2 <acquire>
}
    800020aa:	70a2                	ld	ra,40(sp)
    800020ac:	7402                	ld	s0,32(sp)
    800020ae:	64e2                	ld	s1,24(sp)
    800020b0:	6942                	ld	s2,16(sp)
    800020b2:	69a2                	ld	s3,8(sp)
    800020b4:	6145                	addi	sp,sp,48
    800020b6:	8082                	ret

00000000800020b8 <wait>:
{
    800020b8:	715d                	addi	sp,sp,-80
    800020ba:	e486                	sd	ra,72(sp)
    800020bc:	e0a2                	sd	s0,64(sp)
    800020be:	fc26                	sd	s1,56(sp)
    800020c0:	f84a                	sd	s2,48(sp)
    800020c2:	f44e                	sd	s3,40(sp)
    800020c4:	f052                	sd	s4,32(sp)
    800020c6:	ec56                	sd	s5,24(sp)
    800020c8:	e85a                	sd	s6,16(sp)
    800020ca:	e45e                	sd	s7,8(sp)
    800020cc:	e062                	sd	s8,0(sp)
    800020ce:	0880                	addi	s0,sp,80
    800020d0:	8b2a                	mv	s6,a0
	struct proc *p = myproc();
    800020d2:	00000097          	auipc	ra,0x0
    800020d6:	8ac080e7          	jalr	-1876(ra) # 8000197e <myproc>
    800020da:	892a                	mv	s2,a0
	acquire(&wait_lock);
    800020dc:	0000f517          	auipc	a0,0xf
    800020e0:	1dc50513          	addi	a0,a0,476 # 800112b8 <wait_lock>
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	ade080e7          	jalr	-1314(ra) # 80000bc2 <acquire>
		havekids = 0;
    800020ec:	4b81                	li	s7,0
				if (np->state == ZOMBIE)
    800020ee:	4a15                	li	s4,5
				havekids = 1;
    800020f0:	4a85                	li	s5,1
		for (np = proc; np < &proc[NPROC]; np++)
    800020f2:	00015997          	auipc	s3,0x15
    800020f6:	5de98993          	addi	s3,s3,1502 # 800176d0 <tickslock>
		sleep(p, &wait_lock); //DOC: wait-sleep
    800020fa:	0000fc17          	auipc	s8,0xf
    800020fe:	1bec0c13          	addi	s8,s8,446 # 800112b8 <wait_lock>
		havekids = 0;
    80002102:	875e                	mv	a4,s7
		for (np = proc; np < &proc[NPROC]; np++)
    80002104:	0000f497          	auipc	s1,0xf
    80002108:	5cc48493          	addi	s1,s1,1484 # 800116d0 <proc>
    8000210c:	a0bd                	j	8000217a <wait+0xc2>
					pid = np->pid;
    8000210e:	0304a983          	lw	s3,48(s1)
					if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002112:	000b0e63          	beqz	s6,8000212e <wait+0x76>
    80002116:	4691                	li	a3,4
    80002118:	02c48613          	addi	a2,s1,44
    8000211c:	85da                	mv	a1,s6
    8000211e:	06893503          	ld	a0,104(s2)
    80002122:	fffff097          	auipc	ra,0xfffff
    80002126:	51c080e7          	jalr	1308(ra) # 8000163e <copyout>
    8000212a:	02054563          	bltz	a0,80002154 <wait+0x9c>
					freeproc(np);
    8000212e:	8526                	mv	a0,s1
    80002130:	00000097          	auipc	ra,0x0
    80002134:	a00080e7          	jalr	-1536(ra) # 80001b30 <freeproc>
					release(&np->lock);
    80002138:	8526                	mv	a0,s1
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	b3c080e7          	jalr	-1220(ra) # 80000c76 <release>
					release(&wait_lock);
    80002142:	0000f517          	auipc	a0,0xf
    80002146:	17650513          	addi	a0,a0,374 # 800112b8 <wait_lock>
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	b2c080e7          	jalr	-1236(ra) # 80000c76 <release>
					return pid;
    80002152:	a09d                	j	800021b8 <wait+0x100>
						release(&np->lock);
    80002154:	8526                	mv	a0,s1
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	b20080e7          	jalr	-1248(ra) # 80000c76 <release>
						release(&wait_lock);
    8000215e:	0000f517          	auipc	a0,0xf
    80002162:	15a50513          	addi	a0,a0,346 # 800112b8 <wait_lock>
    80002166:	fffff097          	auipc	ra,0xfffff
    8000216a:	b10080e7          	jalr	-1264(ra) # 80000c76 <release>
						return -1;
    8000216e:	59fd                	li	s3,-1
    80002170:	a0a1                	j	800021b8 <wait+0x100>
		for (np = proc; np < &proc[NPROC]; np++)
    80002172:	18048493          	addi	s1,s1,384
    80002176:	03348463          	beq	s1,s3,8000219e <wait+0xe6>
			if (np->parent == p)
    8000217a:	68bc                	ld	a5,80(s1)
    8000217c:	ff279be3          	bne	a5,s2,80002172 <wait+0xba>
				acquire(&np->lock);
    80002180:	8526                	mv	a0,s1
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	a40080e7          	jalr	-1472(ra) # 80000bc2 <acquire>
				if (np->state == ZOMBIE)
    8000218a:	4c9c                	lw	a5,24(s1)
    8000218c:	f94781e3          	beq	a5,s4,8000210e <wait+0x56>
				release(&np->lock);
    80002190:	8526                	mv	a0,s1
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	ae4080e7          	jalr	-1308(ra) # 80000c76 <release>
				havekids = 1;
    8000219a:	8756                	mv	a4,s5
    8000219c:	bfd9                	j	80002172 <wait+0xba>
		if (!havekids || p->killed)
    8000219e:	c701                	beqz	a4,800021a6 <wait+0xee>
    800021a0:	02892783          	lw	a5,40(s2)
    800021a4:	c79d                	beqz	a5,800021d2 <wait+0x11a>
			release(&wait_lock);
    800021a6:	0000f517          	auipc	a0,0xf
    800021aa:	11250513          	addi	a0,a0,274 # 800112b8 <wait_lock>
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	ac8080e7          	jalr	-1336(ra) # 80000c76 <release>
			return -1;
    800021b6:	59fd                	li	s3,-1
}
    800021b8:	854e                	mv	a0,s3
    800021ba:	60a6                	ld	ra,72(sp)
    800021bc:	6406                	ld	s0,64(sp)
    800021be:	74e2                	ld	s1,56(sp)
    800021c0:	7942                	ld	s2,48(sp)
    800021c2:	79a2                	ld	s3,40(sp)
    800021c4:	7a02                	ld	s4,32(sp)
    800021c6:	6ae2                	ld	s5,24(sp)
    800021c8:	6b42                	ld	s6,16(sp)
    800021ca:	6ba2                	ld	s7,8(sp)
    800021cc:	6c02                	ld	s8,0(sp)
    800021ce:	6161                	addi	sp,sp,80
    800021d0:	8082                	ret
		sleep(p, &wait_lock); //DOC: wait-sleep
    800021d2:	85e2                	mv	a1,s8
    800021d4:	854a                	mv	a0,s2
    800021d6:	00000097          	auipc	ra,0x0
    800021da:	e7e080e7          	jalr	-386(ra) # 80002054 <sleep>
		havekids = 0;
    800021de:	b715                	j	80002102 <wait+0x4a>

00000000800021e0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800021e0:	7139                	addi	sp,sp,-64
    800021e2:	fc06                	sd	ra,56(sp)
    800021e4:	f822                	sd	s0,48(sp)
    800021e6:	f426                	sd	s1,40(sp)
    800021e8:	f04a                	sd	s2,32(sp)
    800021ea:	ec4e                	sd	s3,24(sp)
    800021ec:	e852                	sd	s4,16(sp)
    800021ee:	e456                	sd	s5,8(sp)
    800021f0:	0080                	addi	s0,sp,64
    800021f2:	8a2a                	mv	s4,a0
	struct proc *p;

	for (p = proc; p < &proc[NPROC]; p++)
    800021f4:	0000f497          	auipc	s1,0xf
    800021f8:	4dc48493          	addi	s1,s1,1244 # 800116d0 <proc>
	{
		if (p != myproc())
		{
			acquire(&p->lock);
			if (p->state == SLEEPING && p->chan == chan)
    800021fc:	4989                	li	s3,2
			{
				p->state = RUNNABLE;
    800021fe:	4a8d                	li	s5,3
	for (p = proc; p < &proc[NPROC]; p++)
    80002200:	00015917          	auipc	s2,0x15
    80002204:	4d090913          	addi	s2,s2,1232 # 800176d0 <tickslock>
    80002208:	a811                	j	8000221c <wakeup+0x3c>
			}
			release(&p->lock);
    8000220a:	8526                	mv	a0,s1
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	a6a080e7          	jalr	-1430(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80002214:	18048493          	addi	s1,s1,384
    80002218:	03248663          	beq	s1,s2,80002244 <wakeup+0x64>
		if (p != myproc())
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	762080e7          	jalr	1890(ra) # 8000197e <myproc>
    80002224:	fea488e3          	beq	s1,a0,80002214 <wakeup+0x34>
			acquire(&p->lock);
    80002228:	8526                	mv	a0,s1
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	998080e7          	jalr	-1640(ra) # 80000bc2 <acquire>
			if (p->state == SLEEPING && p->chan == chan)
    80002232:	4c9c                	lw	a5,24(s1)
    80002234:	fd379be3          	bne	a5,s3,8000220a <wakeup+0x2a>
    80002238:	709c                	ld	a5,32(s1)
    8000223a:	fd4798e3          	bne	a5,s4,8000220a <wakeup+0x2a>
				p->state = RUNNABLE;
    8000223e:	0154ac23          	sw	s5,24(s1)
    80002242:	b7e1                	j	8000220a <wakeup+0x2a>
		}
	}
}
    80002244:	70e2                	ld	ra,56(sp)
    80002246:	7442                	ld	s0,48(sp)
    80002248:	74a2                	ld	s1,40(sp)
    8000224a:	7902                	ld	s2,32(sp)
    8000224c:	69e2                	ld	s3,24(sp)
    8000224e:	6a42                	ld	s4,16(sp)
    80002250:	6aa2                	ld	s5,8(sp)
    80002252:	6121                	addi	sp,sp,64
    80002254:	8082                	ret

0000000080002256 <reparent>:
{
    80002256:	7179                	addi	sp,sp,-48
    80002258:	f406                	sd	ra,40(sp)
    8000225a:	f022                	sd	s0,32(sp)
    8000225c:	ec26                	sd	s1,24(sp)
    8000225e:	e84a                	sd	s2,16(sp)
    80002260:	e44e                	sd	s3,8(sp)
    80002262:	e052                	sd	s4,0(sp)
    80002264:	1800                	addi	s0,sp,48
    80002266:	892a                	mv	s2,a0
	for (pp = proc; pp < &proc[NPROC]; pp++)
    80002268:	0000f497          	auipc	s1,0xf
    8000226c:	46848493          	addi	s1,s1,1128 # 800116d0 <proc>
			pp->parent = initproc;
    80002270:	00007a17          	auipc	s4,0x7
    80002274:	db8a0a13          	addi	s4,s4,-584 # 80009028 <initproc>
	for (pp = proc; pp < &proc[NPROC]; pp++)
    80002278:	00015997          	auipc	s3,0x15
    8000227c:	45898993          	addi	s3,s3,1112 # 800176d0 <tickslock>
    80002280:	a029                	j	8000228a <reparent+0x34>
    80002282:	18048493          	addi	s1,s1,384
    80002286:	01348d63          	beq	s1,s3,800022a0 <reparent+0x4a>
		if (pp->parent == p)
    8000228a:	68bc                	ld	a5,80(s1)
    8000228c:	ff279be3          	bne	a5,s2,80002282 <reparent+0x2c>
			pp->parent = initproc;
    80002290:	000a3503          	ld	a0,0(s4)
    80002294:	e8a8                	sd	a0,80(s1)
			wakeup(initproc);
    80002296:	00000097          	auipc	ra,0x0
    8000229a:	f4a080e7          	jalr	-182(ra) # 800021e0 <wakeup>
    8000229e:	b7d5                	j	80002282 <reparent+0x2c>
}
    800022a0:	70a2                	ld	ra,40(sp)
    800022a2:	7402                	ld	s0,32(sp)
    800022a4:	64e2                	ld	s1,24(sp)
    800022a6:	6942                	ld	s2,16(sp)
    800022a8:	69a2                	ld	s3,8(sp)
    800022aa:	6a02                	ld	s4,0(sp)
    800022ac:	6145                	addi	sp,sp,48
    800022ae:	8082                	ret

00000000800022b0 <exit>:
{
    800022b0:	7179                	addi	sp,sp,-48
    800022b2:	f406                	sd	ra,40(sp)
    800022b4:	f022                	sd	s0,32(sp)
    800022b6:	ec26                	sd	s1,24(sp)
    800022b8:	e84a                	sd	s2,16(sp)
    800022ba:	e44e                	sd	s3,8(sp)
    800022bc:	e052                	sd	s4,0(sp)
    800022be:	1800                	addi	s0,sp,48
    800022c0:	8a2a                	mv	s4,a0
	struct proc *p = myproc();
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	6bc080e7          	jalr	1724(ra) # 8000197e <myproc>
    800022ca:	89aa                	mv	s3,a0
	if (p == initproc)
    800022cc:	00007797          	auipc	a5,0x7
    800022d0:	d5c7b783          	ld	a5,-676(a5) # 80009028 <initproc>
    800022d4:	0e850493          	addi	s1,a0,232
    800022d8:	16850913          	addi	s2,a0,360
    800022dc:	02a79363          	bne	a5,a0,80002302 <exit+0x52>
		panic("init exiting");
    800022e0:	00006517          	auipc	a0,0x6
    800022e4:	f6850513          	addi	a0,a0,-152 # 80008248 <digits+0x208>
    800022e8:	ffffe097          	auipc	ra,0xffffe
    800022ec:	242080e7          	jalr	578(ra) # 8000052a <panic>
			fileclose(f);
    800022f0:	00002097          	auipc	ra,0x2
    800022f4:	472080e7          	jalr	1138(ra) # 80004762 <fileclose>
			p->ofile[fd] = 0;
    800022f8:	0004b023          	sd	zero,0(s1)
	for (int fd = 0; fd < NOFILE; fd++)
    800022fc:	04a1                	addi	s1,s1,8
    800022fe:	01248563          	beq	s1,s2,80002308 <exit+0x58>
		if (p->ofile[fd])
    80002302:	6088                	ld	a0,0(s1)
    80002304:	f575                	bnez	a0,800022f0 <exit+0x40>
    80002306:	bfdd                	j	800022fc <exit+0x4c>
	begin_op();
    80002308:	00002097          	auipc	ra,0x2
    8000230c:	f8e080e7          	jalr	-114(ra) # 80004296 <begin_op>
	iput(p->cwd);
    80002310:	1689b503          	ld	a0,360(s3)
    80002314:	00001097          	auipc	ra,0x1
    80002318:	766080e7          	jalr	1894(ra) # 80003a7a <iput>
	end_op();
    8000231c:	00002097          	auipc	ra,0x2
    80002320:	ffa080e7          	jalr	-6(ra) # 80004316 <end_op>
	p->cwd = 0;
    80002324:	1609b423          	sd	zero,360(s3)
	acquire(&wait_lock);
    80002328:	0000f497          	auipc	s1,0xf
    8000232c:	f9048493          	addi	s1,s1,-112 # 800112b8 <wait_lock>
    80002330:	8526                	mv	a0,s1
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	890080e7          	jalr	-1904(ra) # 80000bc2 <acquire>
	reparent(p);
    8000233a:	854e                	mv	a0,s3
    8000233c:	00000097          	auipc	ra,0x0
    80002340:	f1a080e7          	jalr	-230(ra) # 80002256 <reparent>
	wakeup(p->parent);
    80002344:	0509b503          	ld	a0,80(s3)
    80002348:	00000097          	auipc	ra,0x0
    8000234c:	e98080e7          	jalr	-360(ra) # 800021e0 <wakeup>
	acquire(&p->lock);
    80002350:	854e                	mv	a0,s3
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	870080e7          	jalr	-1936(ra) # 80000bc2 <acquire>
	p->xstate = status;
    8000235a:	0349a623          	sw	s4,44(s3)
	p->state = ZOMBIE;
    8000235e:	4795                	li	a5,5
    80002360:	00f9ac23          	sw	a5,24(s3)
	release(&wait_lock);
    80002364:	8526                	mv	a0,s1
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	910080e7          	jalr	-1776(ra) # 80000c76 <release>
	sched();
    8000236e:	00000097          	auipc	ra,0x0
    80002372:	bd4080e7          	jalr	-1068(ra) # 80001f42 <sched>
	panic("zombie exit");
    80002376:	00006517          	auipc	a0,0x6
    8000237a:	ee250513          	addi	a0,a0,-286 # 80008258 <digits+0x218>
    8000237e:	ffffe097          	auipc	ra,0xffffe
    80002382:	1ac080e7          	jalr	428(ra) # 8000052a <panic>

0000000080002386 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002386:	7179                	addi	sp,sp,-48
    80002388:	f406                	sd	ra,40(sp)
    8000238a:	f022                	sd	s0,32(sp)
    8000238c:	ec26                	sd	s1,24(sp)
    8000238e:	e84a                	sd	s2,16(sp)
    80002390:	e44e                	sd	s3,8(sp)
    80002392:	1800                	addi	s0,sp,48
    80002394:	892a                	mv	s2,a0
	struct proc *p;

	for (p = proc; p < &proc[NPROC]; p++)
    80002396:	0000f497          	auipc	s1,0xf
    8000239a:	33a48493          	addi	s1,s1,826 # 800116d0 <proc>
    8000239e:	00015997          	auipc	s3,0x15
    800023a2:	33298993          	addi	s3,s3,818 # 800176d0 <tickslock>
	{
		acquire(&p->lock);
    800023a6:	8526                	mv	a0,s1
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	81a080e7          	jalr	-2022(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    800023b0:	589c                	lw	a5,48(s1)
    800023b2:	01278d63          	beq	a5,s2,800023cc <kill+0x46>
				p->state = RUNNABLE;
			}
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    800023b6:	8526                	mv	a0,s1
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	8be080e7          	jalr	-1858(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    800023c0:	18048493          	addi	s1,s1,384
    800023c4:	ff3491e3          	bne	s1,s3,800023a6 <kill+0x20>
	}
	return -1;
    800023c8:	557d                	li	a0,-1
    800023ca:	a829                	j	800023e4 <kill+0x5e>
			p->killed = 1;
    800023cc:	4785                	li	a5,1
    800023ce:	d49c                	sw	a5,40(s1)
			if (p->state == SLEEPING)
    800023d0:	4c98                	lw	a4,24(s1)
    800023d2:	4789                	li	a5,2
    800023d4:	00f70f63          	beq	a4,a5,800023f2 <kill+0x6c>
			release(&p->lock);
    800023d8:	8526                	mv	a0,s1
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	89c080e7          	jalr	-1892(ra) # 80000c76 <release>
			return 0;
    800023e2:	4501                	li	a0,0
}
    800023e4:	70a2                	ld	ra,40(sp)
    800023e6:	7402                	ld	s0,32(sp)
    800023e8:	64e2                	ld	s1,24(sp)
    800023ea:	6942                	ld	s2,16(sp)
    800023ec:	69a2                	ld	s3,8(sp)
    800023ee:	6145                	addi	sp,sp,48
    800023f0:	8082                	ret
				p->state = RUNNABLE;
    800023f2:	478d                	li	a5,3
    800023f4:	cc9c                	sw	a5,24(s1)
    800023f6:	b7cd                	j	800023d8 <kill+0x52>

00000000800023f8 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800023f8:	7179                	addi	sp,sp,-48
    800023fa:	f406                	sd	ra,40(sp)
    800023fc:	f022                	sd	s0,32(sp)
    800023fe:	ec26                	sd	s1,24(sp)
    80002400:	e84a                	sd	s2,16(sp)
    80002402:	e44e                	sd	s3,8(sp)
    80002404:	e052                	sd	s4,0(sp)
    80002406:	1800                	addi	s0,sp,48
    80002408:	84aa                	mv	s1,a0
    8000240a:	892e                	mv	s2,a1
    8000240c:	89b2                	mv	s3,a2
    8000240e:	8a36                	mv	s4,a3
	struct proc *p = myproc();
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	56e080e7          	jalr	1390(ra) # 8000197e <myproc>
	if (user_dst)
    80002418:	c08d                	beqz	s1,8000243a <either_copyout+0x42>
	{
		return copyout(p->pagetable, dst, src, len);
    8000241a:	86d2                	mv	a3,s4
    8000241c:	864e                	mv	a2,s3
    8000241e:	85ca                	mv	a1,s2
    80002420:	7528                	ld	a0,104(a0)
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	21c080e7          	jalr	540(ra) # 8000163e <copyout>
	else
	{
		memmove((char *)dst, src, len);
		return 0;
	}
}
    8000242a:	70a2                	ld	ra,40(sp)
    8000242c:	7402                	ld	s0,32(sp)
    8000242e:	64e2                	ld	s1,24(sp)
    80002430:	6942                	ld	s2,16(sp)
    80002432:	69a2                	ld	s3,8(sp)
    80002434:	6a02                	ld	s4,0(sp)
    80002436:	6145                	addi	sp,sp,48
    80002438:	8082                	ret
		memmove((char *)dst, src, len);
    8000243a:	000a061b          	sext.w	a2,s4
    8000243e:	85ce                	mv	a1,s3
    80002440:	854a                	mv	a0,s2
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	8d8080e7          	jalr	-1832(ra) # 80000d1a <memmove>
		return 0;
    8000244a:	8526                	mv	a0,s1
    8000244c:	bff9                	j	8000242a <either_copyout+0x32>

000000008000244e <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000244e:	7179                	addi	sp,sp,-48
    80002450:	f406                	sd	ra,40(sp)
    80002452:	f022                	sd	s0,32(sp)
    80002454:	ec26                	sd	s1,24(sp)
    80002456:	e84a                	sd	s2,16(sp)
    80002458:	e44e                	sd	s3,8(sp)
    8000245a:	e052                	sd	s4,0(sp)
    8000245c:	1800                	addi	s0,sp,48
    8000245e:	892a                	mv	s2,a0
    80002460:	84ae                	mv	s1,a1
    80002462:	89b2                	mv	s3,a2
    80002464:	8a36                	mv	s4,a3
	struct proc *p = myproc();
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	518080e7          	jalr	1304(ra) # 8000197e <myproc>
	if (user_src)
    8000246e:	c08d                	beqz	s1,80002490 <either_copyin+0x42>
	{
		return copyin(p->pagetable, dst, src, len);
    80002470:	86d2                	mv	a3,s4
    80002472:	864e                	mv	a2,s3
    80002474:	85ca                	mv	a1,s2
    80002476:	7528                	ld	a0,104(a0)
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	252080e7          	jalr	594(ra) # 800016ca <copyin>
	else
	{
		memmove(dst, (char *)src, len);
		return 0;
	}
}
    80002480:	70a2                	ld	ra,40(sp)
    80002482:	7402                	ld	s0,32(sp)
    80002484:	64e2                	ld	s1,24(sp)
    80002486:	6942                	ld	s2,16(sp)
    80002488:	69a2                	ld	s3,8(sp)
    8000248a:	6a02                	ld	s4,0(sp)
    8000248c:	6145                	addi	sp,sp,48
    8000248e:	8082                	ret
		memmove(dst, (char *)src, len);
    80002490:	000a061b          	sext.w	a2,s4
    80002494:	85ce                	mv	a1,s3
    80002496:	854a                	mv	a0,s2
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	882080e7          	jalr	-1918(ra) # 80000d1a <memmove>
		return 0;
    800024a0:	8526                	mv	a0,s1
    800024a2:	bff9                	j	80002480 <either_copyin+0x32>

00000000800024a4 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800024a4:	715d                	addi	sp,sp,-80
    800024a6:	e486                	sd	ra,72(sp)
    800024a8:	e0a2                	sd	s0,64(sp)
    800024aa:	fc26                	sd	s1,56(sp)
    800024ac:	f84a                	sd	s2,48(sp)
    800024ae:	f44e                	sd	s3,40(sp)
    800024b0:	f052                	sd	s4,32(sp)
    800024b2:	ec56                	sd	s5,24(sp)
    800024b4:	e85a                	sd	s6,16(sp)
    800024b6:	e45e                	sd	s7,8(sp)
    800024b8:	0880                	addi	s0,sp,80
		[RUNNING] "run   ",
		[ZOMBIE] "zombie"};
	struct proc *p;
	char *state;

	printf("\n");
    800024ba:	00006517          	auipc	a0,0x6
    800024be:	c0e50513          	addi	a0,a0,-1010 # 800080c8 <digits+0x88>
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	0b2080e7          	jalr	178(ra) # 80000574 <printf>
	for (p = proc; p < &proc[NPROC]; p++)
    800024ca:	0000f497          	auipc	s1,0xf
    800024ce:	37648493          	addi	s1,s1,886 # 80011840 <proc+0x170>
    800024d2:	00015917          	auipc	s2,0x15
    800024d6:	36e90913          	addi	s2,s2,878 # 80017840 <bcache+0x158>
	{
		if (p->state == UNUSED)
			continue;
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024da:	4b15                	li	s6,5
			state = states[p->state];
		else
			state = "???";
    800024dc:	00006997          	auipc	s3,0x6
    800024e0:	d8c98993          	addi	s3,s3,-628 # 80008268 <digits+0x228>
		printf("%d %s %s", p->pid, state, p->name);
    800024e4:	00006a97          	auipc	s5,0x6
    800024e8:	d8ca8a93          	addi	s5,s5,-628 # 80008270 <digits+0x230>
		printf("\n");
    800024ec:	00006a17          	auipc	s4,0x6
    800024f0:	bdca0a13          	addi	s4,s4,-1060 # 800080c8 <digits+0x88>
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024f4:	00006b97          	auipc	s7,0x6
    800024f8:	db4b8b93          	addi	s7,s7,-588 # 800082a8 <states.0>
    800024fc:	a00d                	j	8000251e <procdump+0x7a>
		printf("%d %s %s", p->pid, state, p->name);
    800024fe:	ec06a583          	lw	a1,-320(a3)
    80002502:	8556                	mv	a0,s5
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	070080e7          	jalr	112(ra) # 80000574 <printf>
		printf("\n");
    8000250c:	8552                	mv	a0,s4
    8000250e:	ffffe097          	auipc	ra,0xffffe
    80002512:	066080e7          	jalr	102(ra) # 80000574 <printf>
	for (p = proc; p < &proc[NPROC]; p++)
    80002516:	18048493          	addi	s1,s1,384
    8000251a:	03248263          	beq	s1,s2,8000253e <procdump+0x9a>
		if (p->state == UNUSED)
    8000251e:	86a6                	mv	a3,s1
    80002520:	ea84a783          	lw	a5,-344(s1)
    80002524:	dbed                	beqz	a5,80002516 <procdump+0x72>
			state = "???";
    80002526:	864e                	mv	a2,s3
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002528:	fcfb6be3          	bltu	s6,a5,800024fe <procdump+0x5a>
    8000252c:	02079713          	slli	a4,a5,0x20
    80002530:	01d75793          	srli	a5,a4,0x1d
    80002534:	97de                	add	a5,a5,s7
    80002536:	6390                	ld	a2,0(a5)
    80002538:	f279                	bnez	a2,800024fe <procdump+0x5a>
			state = "???";
    8000253a:	864e                	mv	a2,s3
    8000253c:	b7c9                	j	800024fe <procdump+0x5a>
	}
}
    8000253e:	60a6                	ld	ra,72(sp)
    80002540:	6406                	ld	s0,64(sp)
    80002542:	74e2                	ld	s1,56(sp)
    80002544:	7942                	ld	s2,48(sp)
    80002546:	79a2                	ld	s3,40(sp)
    80002548:	7a02                	ld	s4,32(sp)
    8000254a:	6ae2                	ld	s5,24(sp)
    8000254c:	6b42                	ld	s6,16(sp)
    8000254e:	6ba2                	ld	s7,8(sp)
    80002550:	6161                	addi	sp,sp,80
    80002552:	8082                	ret

0000000080002554 <trace>:
//ADDED
int trace(int mask, int pid)
{
    80002554:	7179                	addi	sp,sp,-48
    80002556:	f406                	sd	ra,40(sp)
    80002558:	f022                	sd	s0,32(sp)
    8000255a:	ec26                	sd	s1,24(sp)
    8000255c:	e84a                	sd	s2,16(sp)
    8000255e:	e44e                	sd	s3,8(sp)
    80002560:	e052                	sd	s4,0(sp)
    80002562:	1800                	addi	s0,sp,48
    80002564:	8a2a                	mv	s4,a0
    80002566:	892e                	mv	s2,a1
	struct proc *p;
	for (p = proc; p < &proc[NPROC]; p++)
    80002568:	0000f497          	auipc	s1,0xf
    8000256c:	16848493          	addi	s1,s1,360 # 800116d0 <proc>
    80002570:	00015997          	auipc	s3,0x15
    80002574:	16098993          	addi	s3,s3,352 # 800176d0 <tickslock>
	{
		acquire(&p->lock);
    80002578:	8526                	mv	a0,s1
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	648080e7          	jalr	1608(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    80002582:	589c                	lw	a5,48(s1)
    80002584:	01278d63          	beq	a5,s2,8000259e <trace+0x4a>
		{
			p->trace_mask = mask;
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    80002588:	8526                	mv	a0,s1
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	6ec080e7          	jalr	1772(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80002592:	18048493          	addi	s1,s1,384
    80002596:	ff3491e3          	bne	s1,s3,80002578 <trace+0x24>
	}

	return -1;
    8000259a:	557d                	li	a0,-1
    8000259c:	a809                	j	800025ae <trace+0x5a>
			p->trace_mask = mask;
    8000259e:	0344aa23          	sw	s4,52(s1)
			release(&p->lock);
    800025a2:	8526                	mv	a0,s1
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	6d2080e7          	jalr	1746(ra) # 80000c76 <release>
			return 0;
    800025ac:	4501                	li	a0,0
}
    800025ae:	70a2                	ld	ra,40(sp)
    800025b0:	7402                	ld	s0,32(sp)
    800025b2:	64e2                	ld	s1,24(sp)
    800025b4:	6942                	ld	s2,16(sp)
    800025b6:	69a2                	ld	s3,8(sp)
    800025b8:	6a02                	ld	s4,0(sp)
    800025ba:	6145                	addi	sp,sp,48
    800025bc:	8082                	ret

00000000800025be <getmsk>:

int getmsk(int pid)
{
    800025be:	7179                	addi	sp,sp,-48
    800025c0:	f406                	sd	ra,40(sp)
    800025c2:	f022                	sd	s0,32(sp)
    800025c4:	ec26                	sd	s1,24(sp)
    800025c6:	e84a                	sd	s2,16(sp)
    800025c8:	e44e                	sd	s3,8(sp)
    800025ca:	1800                	addi	s0,sp,48
    800025cc:	892a                	mv	s2,a0
	struct proc *p;
	int mask;

	for (p = proc; p < &proc[NPROC]; p++)
    800025ce:	0000f497          	auipc	s1,0xf
    800025d2:	10248493          	addi	s1,s1,258 # 800116d0 <proc>
    800025d6:	00015997          	auipc	s3,0x15
    800025da:	0fa98993          	addi	s3,s3,250 # 800176d0 <tickslock>
	{
		acquire(&p->lock);
    800025de:	8526                	mv	a0,s1
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	5e2080e7          	jalr	1506(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    800025e8:	589c                	lw	a5,48(s1)
    800025ea:	01278d63          	beq	a5,s2,80002604 <getmsk+0x46>
		{
			mask = p->trace_mask;
			release(&p->lock);
			return mask;
		}
		release(&p->lock);
    800025ee:	8526                	mv	a0,s1
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	686080e7          	jalr	1670(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    800025f8:	18048493          	addi	s1,s1,384
    800025fc:	ff3491e3          	bne	s1,s3,800025de <getmsk+0x20>
	}

	return -1;
    80002600:	597d                	li	s2,-1
    80002602:	a801                	j	80002612 <getmsk+0x54>
			mask = p->trace_mask;
    80002604:	0344a903          	lw	s2,52(s1)
			release(&p->lock);
    80002608:	8526                	mv	a0,s1
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	66c080e7          	jalr	1644(ra) # 80000c76 <release>
}
    80002612:	854a                	mv	a0,s2
    80002614:	70a2                	ld	ra,40(sp)
    80002616:	7402                	ld	s0,32(sp)
    80002618:	64e2                	ld	s1,24(sp)
    8000261a:	6942                	ld	s2,16(sp)
    8000261c:	69a2                	ld	s3,8(sp)
    8000261e:	6145                	addi	sp,sp,48
    80002620:	8082                	ret

0000000080002622 <wait_stat>:

int wait_stat(uint64 status, uint64 performance)
{
    80002622:	1141                	addi	sp,sp,-16
    80002624:	e422                	sd	s0,8(sp)
    80002626:	0800                	addi	s0,sp,16
	return 7;
}
    80002628:	451d                	li	a0,7
    8000262a:	6422                	ld	s0,8(sp)
    8000262c:	0141                	addi	sp,sp,16
    8000262e:	8082                	ret

0000000080002630 <update_pref>:

// ADDED
void update_pref(uint tick, struct proc *p)
{
    80002630:	1141                	addi	sp,sp,-16
    80002632:	e422                	sd	s0,8(sp)
    80002634:	0800                	addi	s0,sp,16
	switch (p->state)
    80002636:	4d9c                	lw	a5,24(a1)
    80002638:	4711                	li	a4,4
    8000263a:	02e78763          	beq	a5,a4,80002668 <update_pref+0x38>
    8000263e:	00f76c63          	bltu	a4,a5,80002656 <update_pref+0x26>
    80002642:	4709                	li	a4,2
    80002644:	02e78863          	beq	a5,a4,80002674 <update_pref+0x44>
    80002648:	470d                	li	a4,3
    8000264a:	02e79263          	bne	a5,a4,8000266e <update_pref+0x3e>
		break;
	case SLEEPING:
		p->performance.stime++;
		break;
	case RUNNABLE:
		p->performance.retime++;
    8000264e:	41fc                	lw	a5,68(a1)
    80002650:	2785                	addiw	a5,a5,1
    80002652:	c1fc                	sw	a5,68(a1)
		break;
    80002654:	a829                	j	8000266e <update_pref+0x3e>
	switch (p->state)
    80002656:	4715                	li	a4,5
    80002658:	00e79b63          	bne	a5,a4,8000266e <update_pref+0x3e>
	case ZOMBIE:
		if (p->performance.ttime == -1)
    8000265c:	5dd8                	lw	a4,60(a1)
    8000265e:	57fd                	li	a5,-1
    80002660:	00f71763          	bne	a4,a5,8000266e <update_pref+0x3e>
			p->performance.ttime = tick;
    80002664:	ddc8                	sw	a0,60(a1)
		break;
	default:
		break;
	}
}
    80002666:	a021                	j	8000266e <update_pref+0x3e>
		p->performance.rutime++;
    80002668:	45bc                	lw	a5,72(a1)
    8000266a:	2785                	addiw	a5,a5,1
    8000266c:	c5bc                	sw	a5,72(a1)
}
    8000266e:	6422                	ld	s0,8(sp)
    80002670:	0141                	addi	sp,sp,16
    80002672:	8082                	ret
		p->performance.stime++;
    80002674:	41bc                	lw	a5,64(a1)
    80002676:	2785                	addiw	a5,a5,1
    80002678:	c1bc                	sw	a5,64(a1)
		break;
    8000267a:	bfd5                	j	8000266e <update_pref+0x3e>

000000008000267c <update_prefs>:

// ADDED
void update_prefs(uint tick)
{
    8000267c:	7179                	addi	sp,sp,-48
    8000267e:	f406                	sd	ra,40(sp)
    80002680:	f022                	sd	s0,32(sp)
    80002682:	ec26                	sd	s1,24(sp)
    80002684:	e84a                	sd	s2,16(sp)
    80002686:	e44e                	sd	s3,8(sp)
    80002688:	e052                	sd	s4,0(sp)
    8000268a:	1800                	addi	s0,sp,48
    8000268c:	8a2a                	mv	s4,a0
	struct proc *p;

	for (p = proc; p < &proc[NPROC]; p++)
    8000268e:	0000f497          	auipc	s1,0xf
    80002692:	04248493          	addi	s1,s1,66 # 800116d0 <proc>
	{
		acquire(&p->lock);
		if (p->state == SLEEPING)
    80002696:	4989                	li	s3,2
	for (p = proc; p < &proc[NPROC]; p++)
    80002698:	00015917          	auipc	s2,0x15
    8000269c:	03890913          	addi	s2,s2,56 # 800176d0 <tickslock>
    800026a0:	a811                	j	800026b4 <update_prefs+0x38>
		{
			update_pref(tick, p);
		}
		release(&p->lock);
    800026a2:	8526                	mv	a0,s1
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	5d2080e7          	jalr	1490(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    800026ac:	18048493          	addi	s1,s1,384
    800026b0:	03248163          	beq	s1,s2,800026d2 <update_prefs+0x56>
		acquire(&p->lock);
    800026b4:	8526                	mv	a0,s1
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	50c080e7          	jalr	1292(ra) # 80000bc2 <acquire>
		if (p->state == SLEEPING)
    800026be:	4c9c                	lw	a5,24(s1)
    800026c0:	ff3791e3          	bne	a5,s3,800026a2 <update_prefs+0x26>
			update_pref(tick, p);
    800026c4:	85a6                	mv	a1,s1
    800026c6:	8552                	mv	a0,s4
    800026c8:	00000097          	auipc	ra,0x0
    800026cc:	f68080e7          	jalr	-152(ra) # 80002630 <update_pref>
    800026d0:	bfc9                	j	800026a2 <update_prefs+0x26>
	}
    800026d2:	70a2                	ld	ra,40(sp)
    800026d4:	7402                	ld	s0,32(sp)
    800026d6:	64e2                	ld	s1,24(sp)
    800026d8:	6942                	ld	s2,16(sp)
    800026da:	69a2                	ld	s3,8(sp)
    800026dc:	6a02                	ld	s4,0(sp)
    800026de:	6145                	addi	sp,sp,48
    800026e0:	8082                	ret

00000000800026e2 <swtch>:
    800026e2:	00153023          	sd	ra,0(a0)
    800026e6:	00253423          	sd	sp,8(a0)
    800026ea:	e900                	sd	s0,16(a0)
    800026ec:	ed04                	sd	s1,24(a0)
    800026ee:	03253023          	sd	s2,32(a0)
    800026f2:	03353423          	sd	s3,40(a0)
    800026f6:	03453823          	sd	s4,48(a0)
    800026fa:	03553c23          	sd	s5,56(a0)
    800026fe:	05653023          	sd	s6,64(a0)
    80002702:	05753423          	sd	s7,72(a0)
    80002706:	05853823          	sd	s8,80(a0)
    8000270a:	05953c23          	sd	s9,88(a0)
    8000270e:	07a53023          	sd	s10,96(a0)
    80002712:	07b53423          	sd	s11,104(a0)
    80002716:	0005b083          	ld	ra,0(a1)
    8000271a:	0085b103          	ld	sp,8(a1)
    8000271e:	6980                	ld	s0,16(a1)
    80002720:	6d84                	ld	s1,24(a1)
    80002722:	0205b903          	ld	s2,32(a1)
    80002726:	0285b983          	ld	s3,40(a1)
    8000272a:	0305ba03          	ld	s4,48(a1)
    8000272e:	0385ba83          	ld	s5,56(a1)
    80002732:	0405bb03          	ld	s6,64(a1)
    80002736:	0485bb83          	ld	s7,72(a1)
    8000273a:	0505bc03          	ld	s8,80(a1)
    8000273e:	0585bc83          	ld	s9,88(a1)
    80002742:	0605bd03          	ld	s10,96(a1)
    80002746:	0685bd83          	ld	s11,104(a1)
    8000274a:	8082                	ret

000000008000274c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000274c:	1141                	addi	sp,sp,-16
    8000274e:	e406                	sd	ra,8(sp)
    80002750:	e022                	sd	s0,0(sp)
    80002752:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002754:	00006597          	auipc	a1,0x6
    80002758:	b8458593          	addi	a1,a1,-1148 # 800082d8 <states.0+0x30>
    8000275c:	00015517          	auipc	a0,0x15
    80002760:	f7450513          	addi	a0,a0,-140 # 800176d0 <tickslock>
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	3ce080e7          	jalr	974(ra) # 80000b32 <initlock>
}
    8000276c:	60a2                	ld	ra,8(sp)
    8000276e:	6402                	ld	s0,0(sp)
    80002770:	0141                	addi	sp,sp,16
    80002772:	8082                	ret

0000000080002774 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002774:	1141                	addi	sp,sp,-16
    80002776:	e422                	sd	s0,8(sp)
    80002778:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000277a:	00003797          	auipc	a5,0x3
    8000277e:	61678793          	addi	a5,a5,1558 # 80005d90 <kernelvec>
    80002782:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002786:	6422                	ld	s0,8(sp)
    80002788:	0141                	addi	sp,sp,16
    8000278a:	8082                	ret

000000008000278c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000278c:	1141                	addi	sp,sp,-16
    8000278e:	e406                	sd	ra,8(sp)
    80002790:	e022                	sd	s0,0(sp)
    80002792:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002794:	fffff097          	auipc	ra,0xfffff
    80002798:	1ea080e7          	jalr	490(ra) # 8000197e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000279c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027a0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027a2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800027a6:	00005617          	auipc	a2,0x5
    800027aa:	85a60613          	addi	a2,a2,-1958 # 80007000 <_trampoline>
    800027ae:	00005697          	auipc	a3,0x5
    800027b2:	85268693          	addi	a3,a3,-1966 # 80007000 <_trampoline>
    800027b6:	8e91                	sub	a3,a3,a2
    800027b8:	040007b7          	lui	a5,0x4000
    800027bc:	17fd                	addi	a5,a5,-1
    800027be:	07b2                	slli	a5,a5,0xc
    800027c0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027c2:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027c6:	7938                	ld	a4,112(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027c8:	180026f3          	csrr	a3,satp
    800027cc:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027ce:	7938                	ld	a4,112(a0)
    800027d0:	6d34                	ld	a3,88(a0)
    800027d2:	6585                	lui	a1,0x1
    800027d4:	96ae                	add	a3,a3,a1
    800027d6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027d8:	7938                	ld	a4,112(a0)
    800027da:	00000697          	auipc	a3,0x0
    800027de:	14868693          	addi	a3,a3,328 # 80002922 <usertrap>
    800027e2:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027e4:	7938                	ld	a4,112(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027e6:	8692                	mv	a3,tp
    800027e8:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ea:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027ee:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027f2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027f6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027fa:	7938                	ld	a4,112(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027fc:	6f18                	ld	a4,24(a4)
    800027fe:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002802:	752c                	ld	a1,104(a0)
    80002804:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002806:	00005717          	auipc	a4,0x5
    8000280a:	88a70713          	addi	a4,a4,-1910 # 80007090 <userret>
    8000280e:	8f11                	sub	a4,a4,a2
    80002810:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002812:	577d                	li	a4,-1
    80002814:	177e                	slli	a4,a4,0x3f
    80002816:	8dd9                	or	a1,a1,a4
    80002818:	02000537          	lui	a0,0x2000
    8000281c:	157d                	addi	a0,a0,-1
    8000281e:	0536                	slli	a0,a0,0xd
    80002820:	9782                	jalr	a5
}
    80002822:	60a2                	ld	ra,8(sp)
    80002824:	6402                	ld	s0,0(sp)
    80002826:	0141                	addi	sp,sp,16
    80002828:	8082                	ret

000000008000282a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000282a:	1101                	addi	sp,sp,-32
    8000282c:	ec06                	sd	ra,24(sp)
    8000282e:	e822                	sd	s0,16(sp)
    80002830:	e426                	sd	s1,8(sp)
    80002832:	e04a                	sd	s2,0(sp)
    80002834:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002836:	00015917          	auipc	s2,0x15
    8000283a:	e9a90913          	addi	s2,s2,-358 # 800176d0 <tickslock>
    8000283e:	854a                	mv	a0,s2
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	382080e7          	jalr	898(ra) # 80000bc2 <acquire>
  ticks++;
    80002848:	00006497          	auipc	s1,0x6
    8000284c:	7e848493          	addi	s1,s1,2024 # 80009030 <ticks>
    80002850:	409c                	lw	a5,0(s1)
    80002852:	2785                	addiw	a5,a5,1
    80002854:	c09c                	sw	a5,0(s1)
  wakeup(&ticks);
    80002856:	8526                	mv	a0,s1
    80002858:	00000097          	auipc	ra,0x0
    8000285c:	988080e7          	jalr	-1656(ra) # 800021e0 <wakeup>
  update_prefs(ticks);
    80002860:	4088                	lw	a0,0(s1)
    80002862:	00000097          	auipc	ra,0x0
    80002866:	e1a080e7          	jalr	-486(ra) # 8000267c <update_prefs>
  release(&tickslock);
    8000286a:	854a                	mv	a0,s2
    8000286c:	ffffe097          	auipc	ra,0xffffe
    80002870:	40a080e7          	jalr	1034(ra) # 80000c76 <release>
}
    80002874:	60e2                	ld	ra,24(sp)
    80002876:	6442                	ld	s0,16(sp)
    80002878:	64a2                	ld	s1,8(sp)
    8000287a:	6902                	ld	s2,0(sp)
    8000287c:	6105                	addi	sp,sp,32
    8000287e:	8082                	ret

0000000080002880 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002880:	1101                	addi	sp,sp,-32
    80002882:	ec06                	sd	ra,24(sp)
    80002884:	e822                	sd	s0,16(sp)
    80002886:	e426                	sd	s1,8(sp)
    80002888:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000288a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000288e:	00074d63          	bltz	a4,800028a8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002892:	57fd                	li	a5,-1
    80002894:	17fe                	slli	a5,a5,0x3f
    80002896:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002898:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000289a:	06f70363          	beq	a4,a5,80002900 <devintr+0x80>
  }
}
    8000289e:	60e2                	ld	ra,24(sp)
    800028a0:	6442                	ld	s0,16(sp)
    800028a2:	64a2                	ld	s1,8(sp)
    800028a4:	6105                	addi	sp,sp,32
    800028a6:	8082                	ret
     (scause & 0xff) == 9){
    800028a8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800028ac:	46a5                	li	a3,9
    800028ae:	fed792e3          	bne	a5,a3,80002892 <devintr+0x12>
    int irq = plic_claim();
    800028b2:	00003097          	auipc	ra,0x3
    800028b6:	5e6080e7          	jalr	1510(ra) # 80005e98 <plic_claim>
    800028ba:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028bc:	47a9                	li	a5,10
    800028be:	02f50763          	beq	a0,a5,800028ec <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028c2:	4785                	li	a5,1
    800028c4:	02f50963          	beq	a0,a5,800028f6 <devintr+0x76>
    return 1;
    800028c8:	4505                	li	a0,1
    } else if(irq){
    800028ca:	d8f1                	beqz	s1,8000289e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028cc:	85a6                	mv	a1,s1
    800028ce:	00006517          	auipc	a0,0x6
    800028d2:	a1250513          	addi	a0,a0,-1518 # 800082e0 <states.0+0x38>
    800028d6:	ffffe097          	auipc	ra,0xffffe
    800028da:	c9e080e7          	jalr	-866(ra) # 80000574 <printf>
      plic_complete(irq);
    800028de:	8526                	mv	a0,s1
    800028e0:	00003097          	auipc	ra,0x3
    800028e4:	5dc080e7          	jalr	1500(ra) # 80005ebc <plic_complete>
    return 1;
    800028e8:	4505                	li	a0,1
    800028ea:	bf55                	j	8000289e <devintr+0x1e>
      uartintr();
    800028ec:	ffffe097          	auipc	ra,0xffffe
    800028f0:	09a080e7          	jalr	154(ra) # 80000986 <uartintr>
    800028f4:	b7ed                	j	800028de <devintr+0x5e>
      virtio_disk_intr();
    800028f6:	00004097          	auipc	ra,0x4
    800028fa:	a58080e7          	jalr	-1448(ra) # 8000634e <virtio_disk_intr>
    800028fe:	b7c5                	j	800028de <devintr+0x5e>
    if(cpuid() == 0){
    80002900:	fffff097          	auipc	ra,0xfffff
    80002904:	052080e7          	jalr	82(ra) # 80001952 <cpuid>
    80002908:	c901                	beqz	a0,80002918 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000290a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000290e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002910:	14479073          	csrw	sip,a5
    return 2;
    80002914:	4509                	li	a0,2
    80002916:	b761                	j	8000289e <devintr+0x1e>
      clockintr();
    80002918:	00000097          	auipc	ra,0x0
    8000291c:	f12080e7          	jalr	-238(ra) # 8000282a <clockintr>
    80002920:	b7ed                	j	8000290a <devintr+0x8a>

0000000080002922 <usertrap>:
{
    80002922:	1101                	addi	sp,sp,-32
    80002924:	ec06                	sd	ra,24(sp)
    80002926:	e822                	sd	s0,16(sp)
    80002928:	e426                	sd	s1,8(sp)
    8000292a:	e04a                	sd	s2,0(sp)
    8000292c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000292e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002932:	1007f793          	andi	a5,a5,256
    80002936:	e3ad                	bnez	a5,80002998 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002938:	00003797          	auipc	a5,0x3
    8000293c:	45878793          	addi	a5,a5,1112 # 80005d90 <kernelvec>
    80002940:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002944:	fffff097          	auipc	ra,0xfffff
    80002948:	03a080e7          	jalr	58(ra) # 8000197e <myproc>
    8000294c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000294e:	793c                	ld	a5,112(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002950:	14102773          	csrr	a4,sepc
    80002954:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002956:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000295a:	47a1                	li	a5,8
    8000295c:	04f71c63          	bne	a4,a5,800029b4 <usertrap+0x92>
    if(p->killed)
    80002960:	551c                	lw	a5,40(a0)
    80002962:	e3b9                	bnez	a5,800029a8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002964:	78b8                	ld	a4,112(s1)
    80002966:	6f1c                	ld	a5,24(a4)
    80002968:	0791                	addi	a5,a5,4
    8000296a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000296c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002970:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002974:	10079073          	csrw	sstatus,a5
    syscall();
    80002978:	00000097          	auipc	ra,0x0
    8000297c:	3ac080e7          	jalr	940(ra) # 80002d24 <syscall>
  if(p->killed)
    80002980:	549c                	lw	a5,40(s1)
    80002982:	ebc1                	bnez	a5,80002a12 <usertrap+0xf0>
  usertrapret();
    80002984:	00000097          	auipc	ra,0x0
    80002988:	e08080e7          	jalr	-504(ra) # 8000278c <usertrapret>
}
    8000298c:	60e2                	ld	ra,24(sp)
    8000298e:	6442                	ld	s0,16(sp)
    80002990:	64a2                	ld	s1,8(sp)
    80002992:	6902                	ld	s2,0(sp)
    80002994:	6105                	addi	sp,sp,32
    80002996:	8082                	ret
    panic("usertrap: not from user mode");
    80002998:	00006517          	auipc	a0,0x6
    8000299c:	96850513          	addi	a0,a0,-1688 # 80008300 <states.0+0x58>
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	b8a080e7          	jalr	-1142(ra) # 8000052a <panic>
      exit(-1);
    800029a8:	557d                	li	a0,-1
    800029aa:	00000097          	auipc	ra,0x0
    800029ae:	906080e7          	jalr	-1786(ra) # 800022b0 <exit>
    800029b2:	bf4d                	j	80002964 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800029b4:	00000097          	auipc	ra,0x0
    800029b8:	ecc080e7          	jalr	-308(ra) # 80002880 <devintr>
    800029bc:	892a                	mv	s2,a0
    800029be:	c501                	beqz	a0,800029c6 <usertrap+0xa4>
  if(p->killed)
    800029c0:	549c                	lw	a5,40(s1)
    800029c2:	c3a1                	beqz	a5,80002a02 <usertrap+0xe0>
    800029c4:	a815                	j	800029f8 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029c6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029ca:	5890                	lw	a2,48(s1)
    800029cc:	00006517          	auipc	a0,0x6
    800029d0:	95450513          	addi	a0,a0,-1708 # 80008320 <states.0+0x78>
    800029d4:	ffffe097          	auipc	ra,0xffffe
    800029d8:	ba0080e7          	jalr	-1120(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029dc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029e0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029e4:	00006517          	auipc	a0,0x6
    800029e8:	96c50513          	addi	a0,a0,-1684 # 80008350 <states.0+0xa8>
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	b88080e7          	jalr	-1144(ra) # 80000574 <printf>
    p->killed = 1;
    800029f4:	4785                	li	a5,1
    800029f6:	d49c                	sw	a5,40(s1)
    exit(-1);
    800029f8:	557d                	li	a0,-1
    800029fa:	00000097          	auipc	ra,0x0
    800029fe:	8b6080e7          	jalr	-1866(ra) # 800022b0 <exit>
  if(which_dev == 2)
    80002a02:	4789                	li	a5,2
    80002a04:	f8f910e3          	bne	s2,a5,80002984 <usertrap+0x62>
    yield();
    80002a08:	fffff097          	auipc	ra,0xfffff
    80002a0c:	610080e7          	jalr	1552(ra) # 80002018 <yield>
    80002a10:	bf95                	j	80002984 <usertrap+0x62>
  int which_dev = 0;
    80002a12:	4901                	li	s2,0
    80002a14:	b7d5                	j	800029f8 <usertrap+0xd6>

0000000080002a16 <kerneltrap>:
{
    80002a16:	7179                	addi	sp,sp,-48
    80002a18:	f406                	sd	ra,40(sp)
    80002a1a:	f022                	sd	s0,32(sp)
    80002a1c:	ec26                	sd	s1,24(sp)
    80002a1e:	e84a                	sd	s2,16(sp)
    80002a20:	e44e                	sd	s3,8(sp)
    80002a22:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a24:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a28:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a2c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a30:	1004f793          	andi	a5,s1,256
    80002a34:	cb85                	beqz	a5,80002a64 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a3a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a3c:	ef85                	bnez	a5,80002a74 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a3e:	00000097          	auipc	ra,0x0
    80002a42:	e42080e7          	jalr	-446(ra) # 80002880 <devintr>
    80002a46:	cd1d                	beqz	a0,80002a84 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a48:	4789                	li	a5,2
    80002a4a:	06f50a63          	beq	a0,a5,80002abe <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a4e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a52:	10049073          	csrw	sstatus,s1
}
    80002a56:	70a2                	ld	ra,40(sp)
    80002a58:	7402                	ld	s0,32(sp)
    80002a5a:	64e2                	ld	s1,24(sp)
    80002a5c:	6942                	ld	s2,16(sp)
    80002a5e:	69a2                	ld	s3,8(sp)
    80002a60:	6145                	addi	sp,sp,48
    80002a62:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a64:	00006517          	auipc	a0,0x6
    80002a68:	90c50513          	addi	a0,a0,-1780 # 80008370 <states.0+0xc8>
    80002a6c:	ffffe097          	auipc	ra,0xffffe
    80002a70:	abe080e7          	jalr	-1346(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002a74:	00006517          	auipc	a0,0x6
    80002a78:	92450513          	addi	a0,a0,-1756 # 80008398 <states.0+0xf0>
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	aae080e7          	jalr	-1362(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002a84:	85ce                	mv	a1,s3
    80002a86:	00006517          	auipc	a0,0x6
    80002a8a:	93250513          	addi	a0,a0,-1742 # 800083b8 <states.0+0x110>
    80002a8e:	ffffe097          	auipc	ra,0xffffe
    80002a92:	ae6080e7          	jalr	-1306(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a96:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a9a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a9e:	00006517          	auipc	a0,0x6
    80002aa2:	92a50513          	addi	a0,a0,-1750 # 800083c8 <states.0+0x120>
    80002aa6:	ffffe097          	auipc	ra,0xffffe
    80002aaa:	ace080e7          	jalr	-1330(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002aae:	00006517          	auipc	a0,0x6
    80002ab2:	93250513          	addi	a0,a0,-1742 # 800083e0 <states.0+0x138>
    80002ab6:	ffffe097          	auipc	ra,0xffffe
    80002aba:	a74080e7          	jalr	-1420(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002abe:	fffff097          	auipc	ra,0xfffff
    80002ac2:	ec0080e7          	jalr	-320(ra) # 8000197e <myproc>
    80002ac6:	d541                	beqz	a0,80002a4e <kerneltrap+0x38>
    80002ac8:	fffff097          	auipc	ra,0xfffff
    80002acc:	eb6080e7          	jalr	-330(ra) # 8000197e <myproc>
    80002ad0:	4d18                	lw	a4,24(a0)
    80002ad2:	4791                	li	a5,4
    80002ad4:	f6f71de3          	bne	a4,a5,80002a4e <kerneltrap+0x38>
    yield();
    80002ad8:	fffff097          	auipc	ra,0xfffff
    80002adc:	540080e7          	jalr	1344(ra) # 80002018 <yield>
    80002ae0:	b7bd                	j	80002a4e <kerneltrap+0x38>

0000000080002ae2 <argraw>:
	return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ae2:	1101                	addi	sp,sp,-32
    80002ae4:	ec06                	sd	ra,24(sp)
    80002ae6:	e822                	sd	s0,16(sp)
    80002ae8:	e426                	sd	s1,8(sp)
    80002aea:	1000                	addi	s0,sp,32
    80002aec:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    80002aee:	fffff097          	auipc	ra,0xfffff
    80002af2:	e90080e7          	jalr	-368(ra) # 8000197e <myproc>
	switch (n)
    80002af6:	4795                	li	a5,5
    80002af8:	0497e163          	bltu	a5,s1,80002b3a <argraw+0x58>
    80002afc:	048a                	slli	s1,s1,0x2
    80002afe:	00006717          	auipc	a4,0x6
    80002b02:	a3270713          	addi	a4,a4,-1486 # 80008530 <states.0+0x288>
    80002b06:	94ba                	add	s1,s1,a4
    80002b08:	409c                	lw	a5,0(s1)
    80002b0a:	97ba                	add	a5,a5,a4
    80002b0c:	8782                	jr	a5
	{
	case 0:
		return p->trapframe->a0;
    80002b0e:	793c                	ld	a5,112(a0)
    80002b10:	7ba8                	ld	a0,112(a5)
	case 5:
		return p->trapframe->a5;
	}
	panic("argraw");
	return -1;
}
    80002b12:	60e2                	ld	ra,24(sp)
    80002b14:	6442                	ld	s0,16(sp)
    80002b16:	64a2                	ld	s1,8(sp)
    80002b18:	6105                	addi	sp,sp,32
    80002b1a:	8082                	ret
		return p->trapframe->a1;
    80002b1c:	793c                	ld	a5,112(a0)
    80002b1e:	7fa8                	ld	a0,120(a5)
    80002b20:	bfcd                	j	80002b12 <argraw+0x30>
		return p->trapframe->a2;
    80002b22:	793c                	ld	a5,112(a0)
    80002b24:	63c8                	ld	a0,128(a5)
    80002b26:	b7f5                	j	80002b12 <argraw+0x30>
		return p->trapframe->a3;
    80002b28:	793c                	ld	a5,112(a0)
    80002b2a:	67c8                	ld	a0,136(a5)
    80002b2c:	b7dd                	j	80002b12 <argraw+0x30>
		return p->trapframe->a4;
    80002b2e:	793c                	ld	a5,112(a0)
    80002b30:	6bc8                	ld	a0,144(a5)
    80002b32:	b7c5                	j	80002b12 <argraw+0x30>
		return p->trapframe->a5;
    80002b34:	793c                	ld	a5,112(a0)
    80002b36:	6fc8                	ld	a0,152(a5)
    80002b38:	bfe9                	j	80002b12 <argraw+0x30>
	panic("argraw");
    80002b3a:	00006517          	auipc	a0,0x6
    80002b3e:	8b650513          	addi	a0,a0,-1866 # 800083f0 <states.0+0x148>
    80002b42:	ffffe097          	auipc	ra,0xffffe
    80002b46:	9e8080e7          	jalr	-1560(ra) # 8000052a <panic>

0000000080002b4a <fetchaddr>:
{
    80002b4a:	1101                	addi	sp,sp,-32
    80002b4c:	ec06                	sd	ra,24(sp)
    80002b4e:	e822                	sd	s0,16(sp)
    80002b50:	e426                	sd	s1,8(sp)
    80002b52:	e04a                	sd	s2,0(sp)
    80002b54:	1000                	addi	s0,sp,32
    80002b56:	84aa                	mv	s1,a0
    80002b58:	892e                	mv	s2,a1
	struct proc *p = myproc();
    80002b5a:	fffff097          	auipc	ra,0xfffff
    80002b5e:	e24080e7          	jalr	-476(ra) # 8000197e <myproc>
	if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002b62:	713c                	ld	a5,96(a0)
    80002b64:	02f4f863          	bgeu	s1,a5,80002b94 <fetchaddr+0x4a>
    80002b68:	00848713          	addi	a4,s1,8
    80002b6c:	02e7e663          	bltu	a5,a4,80002b98 <fetchaddr+0x4e>
	if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b70:	46a1                	li	a3,8
    80002b72:	8626                	mv	a2,s1
    80002b74:	85ca                	mv	a1,s2
    80002b76:	7528                	ld	a0,104(a0)
    80002b78:	fffff097          	auipc	ra,0xfffff
    80002b7c:	b52080e7          	jalr	-1198(ra) # 800016ca <copyin>
    80002b80:	00a03533          	snez	a0,a0
    80002b84:	40a00533          	neg	a0,a0
}
    80002b88:	60e2                	ld	ra,24(sp)
    80002b8a:	6442                	ld	s0,16(sp)
    80002b8c:	64a2                	ld	s1,8(sp)
    80002b8e:	6902                	ld	s2,0(sp)
    80002b90:	6105                	addi	sp,sp,32
    80002b92:	8082                	ret
		return -1;
    80002b94:	557d                	li	a0,-1
    80002b96:	bfcd                	j	80002b88 <fetchaddr+0x3e>
    80002b98:	557d                	li	a0,-1
    80002b9a:	b7fd                	j	80002b88 <fetchaddr+0x3e>

0000000080002b9c <fetchstr>:
{
    80002b9c:	7179                	addi	sp,sp,-48
    80002b9e:	f406                	sd	ra,40(sp)
    80002ba0:	f022                	sd	s0,32(sp)
    80002ba2:	ec26                	sd	s1,24(sp)
    80002ba4:	e84a                	sd	s2,16(sp)
    80002ba6:	e44e                	sd	s3,8(sp)
    80002ba8:	1800                	addi	s0,sp,48
    80002baa:	892a                	mv	s2,a0
    80002bac:	84ae                	mv	s1,a1
    80002bae:	89b2                	mv	s3,a2
	struct proc *p = myproc();
    80002bb0:	fffff097          	auipc	ra,0xfffff
    80002bb4:	dce080e7          	jalr	-562(ra) # 8000197e <myproc>
	int err = copyinstr(p->pagetable, buf, addr, max);
    80002bb8:	86ce                	mv	a3,s3
    80002bba:	864a                	mv	a2,s2
    80002bbc:	85a6                	mv	a1,s1
    80002bbe:	7528                	ld	a0,104(a0)
    80002bc0:	fffff097          	auipc	ra,0xfffff
    80002bc4:	b98080e7          	jalr	-1128(ra) # 80001758 <copyinstr>
	if (err < 0)
    80002bc8:	00054763          	bltz	a0,80002bd6 <fetchstr+0x3a>
	return strlen(buf);
    80002bcc:	8526                	mv	a0,s1
    80002bce:	ffffe097          	auipc	ra,0xffffe
    80002bd2:	274080e7          	jalr	628(ra) # 80000e42 <strlen>
}
    80002bd6:	70a2                	ld	ra,40(sp)
    80002bd8:	7402                	ld	s0,32(sp)
    80002bda:	64e2                	ld	s1,24(sp)
    80002bdc:	6942                	ld	s2,16(sp)
    80002bde:	69a2                	ld	s3,8(sp)
    80002be0:	6145                	addi	sp,sp,48
    80002be2:	8082                	ret

0000000080002be4 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002be4:	1101                	addi	sp,sp,-32
    80002be6:	ec06                	sd	ra,24(sp)
    80002be8:	e822                	sd	s0,16(sp)
    80002bea:	e426                	sd	s1,8(sp)
    80002bec:	1000                	addi	s0,sp,32
    80002bee:	84ae                	mv	s1,a1
	*ip = argraw(n);
    80002bf0:	00000097          	auipc	ra,0x0
    80002bf4:	ef2080e7          	jalr	-270(ra) # 80002ae2 <argraw>
    80002bf8:	c088                	sw	a0,0(s1)
	return 0;
}
    80002bfa:	4501                	li	a0,0
    80002bfc:	60e2                	ld	ra,24(sp)
    80002bfe:	6442                	ld	s0,16(sp)
    80002c00:	64a2                	ld	s1,8(sp)
    80002c02:	6105                	addi	sp,sp,32
    80002c04:	8082                	ret

0000000080002c06 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002c06:	1101                	addi	sp,sp,-32
    80002c08:	ec06                	sd	ra,24(sp)
    80002c0a:	e822                	sd	s0,16(sp)
    80002c0c:	e426                	sd	s1,8(sp)
    80002c0e:	1000                	addi	s0,sp,32
    80002c10:	84ae                	mv	s1,a1
	*ip = argraw(n);
    80002c12:	00000097          	auipc	ra,0x0
    80002c16:	ed0080e7          	jalr	-304(ra) # 80002ae2 <argraw>
    80002c1a:	e088                	sd	a0,0(s1)
	return 0;
}
    80002c1c:	4501                	li	a0,0
    80002c1e:	60e2                	ld	ra,24(sp)
    80002c20:	6442                	ld	s0,16(sp)
    80002c22:	64a2                	ld	s1,8(sp)
    80002c24:	6105                	addi	sp,sp,32
    80002c26:	8082                	ret

0000000080002c28 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002c28:	1101                	addi	sp,sp,-32
    80002c2a:	ec06                	sd	ra,24(sp)
    80002c2c:	e822                	sd	s0,16(sp)
    80002c2e:	e426                	sd	s1,8(sp)
    80002c30:	e04a                	sd	s2,0(sp)
    80002c32:	1000                	addi	s0,sp,32
    80002c34:	84ae                	mv	s1,a1
    80002c36:	8932                	mv	s2,a2
	*ip = argraw(n);
    80002c38:	00000097          	auipc	ra,0x0
    80002c3c:	eaa080e7          	jalr	-342(ra) # 80002ae2 <argraw>
	uint64 addr;
	if (argaddr(n, &addr) < 0)
		return -1;
	return fetchstr(addr, buf, max);
    80002c40:	864a                	mv	a2,s2
    80002c42:	85a6                	mv	a1,s1
    80002c44:	00000097          	auipc	ra,0x0
    80002c48:	f58080e7          	jalr	-168(ra) # 80002b9c <fetchstr>
}
    80002c4c:	60e2                	ld	ra,24(sp)
    80002c4e:	6442                	ld	s0,16(sp)
    80002c50:	64a2                	ld	s1,8(sp)
    80002c52:	6902                	ld	s2,0(sp)
    80002c54:	6105                	addi	sp,sp,32
    80002c56:	8082                	ret

0000000080002c58 <print_trace>:
	}
}

// ADDED
void print_trace(int arg)
{
    80002c58:	7179                	addi	sp,sp,-48
    80002c5a:	f406                	sd	ra,40(sp)
    80002c5c:	f022                	sd	s0,32(sp)
    80002c5e:	ec26                	sd	s1,24(sp)
    80002c60:	e84a                	sd	s2,16(sp)
    80002c62:	e44e                	sd	s3,8(sp)
    80002c64:	1800                	addi	s0,sp,48
    80002c66:	89aa                	mv	s3,a0
	int num;
	struct proc *p = myproc();
    80002c68:	fffff097          	auipc	ra,0xfffff
    80002c6c:	d16080e7          	jalr	-746(ra) # 8000197e <myproc>
	num = p->trapframe->a7;
    80002c70:	793c                	ld	a5,112(a0)
    80002c72:	0a87a903          	lw	s2,168(a5)

	int res = (1 << num) & p->trace_mask;
    80002c76:	4785                	li	a5,1
    80002c78:	012797bb          	sllw	a5,a5,s2
    80002c7c:	5958                	lw	a4,52(a0)
    80002c7e:	8ff9                	and	a5,a5,a4
	if (res != 0)
    80002c80:	2781                	sext.w	a5,a5
    80002c82:	eb81                	bnez	a5,80002c92 <print_trace+0x3a>
		else
		{
			printf("syscall %s  -> %d\n", syscallnames[num], p->trapframe->a0);
		}
	}
} // ADDED
    80002c84:	70a2                	ld	ra,40(sp)
    80002c86:	7402                	ld	s0,32(sp)
    80002c88:	64e2                	ld	s1,24(sp)
    80002c8a:	6942                	ld	s2,16(sp)
    80002c8c:	69a2                	ld	s3,8(sp)
    80002c8e:	6145                	addi	sp,sp,48
    80002c90:	8082                	ret
    80002c92:	84aa                	mv	s1,a0
		printf("%d: ", p->pid);
    80002c94:	590c                	lw	a1,48(a0)
    80002c96:	00005517          	auipc	a0,0x5
    80002c9a:	76250513          	addi	a0,a0,1890 # 800083f8 <states.0+0x150>
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	8d6080e7          	jalr	-1834(ra) # 80000574 <printf>
		if (num == SYS_fork)
    80002ca6:	4785                	li	a5,1
    80002ca8:	02f90c63          	beq	s2,a5,80002ce0 <print_trace+0x88>
		else if (num == SYS_kill || num == SYS_sbrk)
    80002cac:	4799                	li	a5,6
    80002cae:	00f90563          	beq	s2,a5,80002cb8 <print_trace+0x60>
    80002cb2:	47b1                	li	a5,12
    80002cb4:	04f91563          	bne	s2,a5,80002cfe <print_trace+0xa6>
			printf("syscall %s %d -> %d\n", syscallnames[num], arg, p->trapframe->a0);
    80002cb8:	78b8                	ld	a4,112(s1)
    80002cba:	090e                	slli	s2,s2,0x3
    80002cbc:	00006797          	auipc	a5,0x6
    80002cc0:	88c78793          	addi	a5,a5,-1908 # 80008548 <syscallnames>
    80002cc4:	993e                	add	s2,s2,a5
    80002cc6:	7b34                	ld	a3,112(a4)
    80002cc8:	864e                	mv	a2,s3
    80002cca:	00093583          	ld	a1,0(s2)
    80002cce:	00005517          	auipc	a0,0x5
    80002cd2:	75250513          	addi	a0,a0,1874 # 80008420 <states.0+0x178>
    80002cd6:	ffffe097          	auipc	ra,0xffffe
    80002cda:	89e080e7          	jalr	-1890(ra) # 80000574 <printf>
    80002cde:	b75d                	j	80002c84 <print_trace+0x2c>
			printf("syscall %s NULL -> %d\n", syscallnames[num], p->trapframe->a0);
    80002ce0:	78bc                	ld	a5,112(s1)
    80002ce2:	7bb0                	ld	a2,112(a5)
    80002ce4:	00005597          	auipc	a1,0x5
    80002ce8:	71c58593          	addi	a1,a1,1820 # 80008400 <states.0+0x158>
    80002cec:	00005517          	auipc	a0,0x5
    80002cf0:	71c50513          	addi	a0,a0,1820 # 80008408 <states.0+0x160>
    80002cf4:	ffffe097          	auipc	ra,0xffffe
    80002cf8:	880080e7          	jalr	-1920(ra) # 80000574 <printf>
    80002cfc:	b761                	j	80002c84 <print_trace+0x2c>
			printf("syscall %s  -> %d\n", syscallnames[num], p->trapframe->a0);
    80002cfe:	78b8                	ld	a4,112(s1)
    80002d00:	090e                	slli	s2,s2,0x3
    80002d02:	00006797          	auipc	a5,0x6
    80002d06:	84678793          	addi	a5,a5,-1978 # 80008548 <syscallnames>
    80002d0a:	993e                	add	s2,s2,a5
    80002d0c:	7b30                	ld	a2,112(a4)
    80002d0e:	00093583          	ld	a1,0(s2)
    80002d12:	00005517          	auipc	a0,0x5
    80002d16:	72650513          	addi	a0,a0,1830 # 80008438 <states.0+0x190>
    80002d1a:	ffffe097          	auipc	ra,0xffffe
    80002d1e:	85a080e7          	jalr	-1958(ra) # 80000574 <printf>
} // ADDED
    80002d22:	b78d                	j	80002c84 <print_trace+0x2c>

0000000080002d24 <syscall>:
{
    80002d24:	7179                	addi	sp,sp,-48
    80002d26:	f406                	sd	ra,40(sp)
    80002d28:	f022                	sd	s0,32(sp)
    80002d2a:	ec26                	sd	s1,24(sp)
    80002d2c:	e84a                	sd	s2,16(sp)
    80002d2e:	1800                	addi	s0,sp,48
	struct proc *p = myproc();
    80002d30:	fffff097          	auipc	ra,0xfffff
    80002d34:	c4e080e7          	jalr	-946(ra) # 8000197e <myproc>
    80002d38:	84aa                	mv	s1,a0
	num = p->trapframe->a7;
    80002d3a:	793c                	ld	a5,112(a0)
    80002d3c:	77dc                	ld	a5,168(a5)
    80002d3e:	0007869b          	sext.w	a3,a5
	if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002d42:	37fd                	addiw	a5,a5,-1
    80002d44:	475d                	li	a4,23
    80002d46:	02f76e63          	bltu	a4,a5,80002d82 <syscall+0x5e>
    80002d4a:	00369713          	slli	a4,a3,0x3
    80002d4e:	00005797          	auipc	a5,0x5
    80002d52:	7fa78793          	addi	a5,a5,2042 # 80008548 <syscallnames>
    80002d56:	97ba                	add	a5,a5,a4
    80002d58:	0c87b903          	ld	s2,200(a5)
    80002d5c:	02090363          	beqz	s2,80002d82 <syscall+0x5e>
		argint(0, &arg); // ADDED
    80002d60:	fdc40593          	addi	a1,s0,-36
    80002d64:	4501                	li	a0,0
    80002d66:	00000097          	auipc	ra,0x0
    80002d6a:	e7e080e7          	jalr	-386(ra) # 80002be4 <argint>
		p->trapframe->a0 = syscalls[num]();
    80002d6e:	78a4                	ld	s1,112(s1)
    80002d70:	9902                	jalr	s2
    80002d72:	f8a8                	sd	a0,112(s1)
		print_trace(arg); // ADDED
    80002d74:	fdc42503          	lw	a0,-36(s0)
    80002d78:	00000097          	auipc	ra,0x0
    80002d7c:	ee0080e7          	jalr	-288(ra) # 80002c58 <print_trace>
    80002d80:	a839                	j	80002d9e <syscall+0x7a>
		printf("%d %s: unknown sys call %d\n",
    80002d82:	17048613          	addi	a2,s1,368
    80002d86:	588c                	lw	a1,48(s1)
    80002d88:	00005517          	auipc	a0,0x5
    80002d8c:	6c850513          	addi	a0,a0,1736 # 80008450 <states.0+0x1a8>
    80002d90:	ffffd097          	auipc	ra,0xffffd
    80002d94:	7e4080e7          	jalr	2020(ra) # 80000574 <printf>
		p->trapframe->a0 = -1;
    80002d98:	78bc                	ld	a5,112(s1)
    80002d9a:	577d                	li	a4,-1
    80002d9c:	fbb8                	sd	a4,112(a5)
}
    80002d9e:	70a2                	ld	ra,40(sp)
    80002da0:	7402                	ld	s0,32(sp)
    80002da2:	64e2                	ld	s1,24(sp)
    80002da4:	6942                	ld	s2,16(sp)
    80002da6:	6145                	addi	sp,sp,48
    80002da8:	8082                	ret

0000000080002daa <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002daa:	1101                	addi	sp,sp,-32
    80002dac:	ec06                	sd	ra,24(sp)
    80002dae:	e822                	sd	s0,16(sp)
    80002db0:	1000                	addi	s0,sp,32
  int n;
  if (argint(0, &n) < 0)
    80002db2:	fec40593          	addi	a1,s0,-20
    80002db6:	4501                	li	a0,0
    80002db8:	00000097          	auipc	ra,0x0
    80002dbc:	e2c080e7          	jalr	-468(ra) # 80002be4 <argint>
    return -1;
    80002dc0:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80002dc2:	00054963          	bltz	a0,80002dd4 <sys_exit+0x2a>
  exit(n);
    80002dc6:	fec42503          	lw	a0,-20(s0)
    80002dca:	fffff097          	auipc	ra,0xfffff
    80002dce:	4e6080e7          	jalr	1254(ra) # 800022b0 <exit>
  return 0; // not reached
    80002dd2:	4781                	li	a5,0
}
    80002dd4:	853e                	mv	a0,a5
    80002dd6:	60e2                	ld	ra,24(sp)
    80002dd8:	6442                	ld	s0,16(sp)
    80002dda:	6105                	addi	sp,sp,32
    80002ddc:	8082                	ret

0000000080002dde <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dde:	1141                	addi	sp,sp,-16
    80002de0:	e406                	sd	ra,8(sp)
    80002de2:	e022                	sd	s0,0(sp)
    80002de4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002de6:	fffff097          	auipc	ra,0xfffff
    80002dea:	b98080e7          	jalr	-1128(ra) # 8000197e <myproc>
}
    80002dee:	5908                	lw	a0,48(a0)
    80002df0:	60a2                	ld	ra,8(sp)
    80002df2:	6402                	ld	s0,0(sp)
    80002df4:	0141                	addi	sp,sp,16
    80002df6:	8082                	ret

0000000080002df8 <sys_fork>:

uint64
sys_fork(void)
{
    80002df8:	1141                	addi	sp,sp,-16
    80002dfa:	e406                	sd	ra,8(sp)
    80002dfc:	e022                	sd	s0,0(sp)
    80002dfe:	0800                	addi	s0,sp,16
  return fork();
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	f5a080e7          	jalr	-166(ra) # 80001d5a <fork>
}
    80002e08:	60a2                	ld	ra,8(sp)
    80002e0a:	6402                	ld	s0,0(sp)
    80002e0c:	0141                	addi	sp,sp,16
    80002e0e:	8082                	ret

0000000080002e10 <sys_wait>:

uint64
sys_wait(void)
{
    80002e10:	1101                	addi	sp,sp,-32
    80002e12:	ec06                	sd	ra,24(sp)
    80002e14:	e822                	sd	s0,16(sp)
    80002e16:	1000                	addi	s0,sp,32
  uint64 p;
  if (argaddr(0, &p) < 0)
    80002e18:	fe840593          	addi	a1,s0,-24
    80002e1c:	4501                	li	a0,0
    80002e1e:	00000097          	auipc	ra,0x0
    80002e22:	de8080e7          	jalr	-536(ra) # 80002c06 <argaddr>
    80002e26:	87aa                	mv	a5,a0
    return -1;
    80002e28:	557d                	li	a0,-1
  if (argaddr(0, &p) < 0)
    80002e2a:	0007c863          	bltz	a5,80002e3a <sys_wait+0x2a>
  return wait(p);
    80002e2e:	fe843503          	ld	a0,-24(s0)
    80002e32:	fffff097          	auipc	ra,0xfffff
    80002e36:	286080e7          	jalr	646(ra) # 800020b8 <wait>
}
    80002e3a:	60e2                	ld	ra,24(sp)
    80002e3c:	6442                	ld	s0,16(sp)
    80002e3e:	6105                	addi	sp,sp,32
    80002e40:	8082                	ret

0000000080002e42 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e42:	7179                	addi	sp,sp,-48
    80002e44:	f406                	sd	ra,40(sp)
    80002e46:	f022                	sd	s0,32(sp)
    80002e48:	ec26                	sd	s1,24(sp)
    80002e4a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if (argint(0, &n) < 0)
    80002e4c:	fdc40593          	addi	a1,s0,-36
    80002e50:	4501                	li	a0,0
    80002e52:	00000097          	auipc	ra,0x0
    80002e56:	d92080e7          	jalr	-622(ra) # 80002be4 <argint>
    return -1;
    80002e5a:	54fd                	li	s1,-1
  if (argint(0, &n) < 0)
    80002e5c:	00054f63          	bltz	a0,80002e7a <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002e60:	fffff097          	auipc	ra,0xfffff
    80002e64:	b1e080e7          	jalr	-1250(ra) # 8000197e <myproc>
    80002e68:	5124                	lw	s1,96(a0)
  if (growproc(n) < 0)
    80002e6a:	fdc42503          	lw	a0,-36(s0)
    80002e6e:	fffff097          	auipc	ra,0xfffff
    80002e72:	e78080e7          	jalr	-392(ra) # 80001ce6 <growproc>
    80002e76:	00054863          	bltz	a0,80002e86 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002e7a:	8526                	mv	a0,s1
    80002e7c:	70a2                	ld	ra,40(sp)
    80002e7e:	7402                	ld	s0,32(sp)
    80002e80:	64e2                	ld	s1,24(sp)
    80002e82:	6145                	addi	sp,sp,48
    80002e84:	8082                	ret
    return -1;
    80002e86:	54fd                	li	s1,-1
    80002e88:	bfcd                	j	80002e7a <sys_sbrk+0x38>

0000000080002e8a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e8a:	7139                	addi	sp,sp,-64
    80002e8c:	fc06                	sd	ra,56(sp)
    80002e8e:	f822                	sd	s0,48(sp)
    80002e90:	f426                	sd	s1,40(sp)
    80002e92:	f04a                	sd	s2,32(sp)
    80002e94:	ec4e                	sd	s3,24(sp)
    80002e96:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if (argint(0, &n) < 0)
    80002e98:	fcc40593          	addi	a1,s0,-52
    80002e9c:	4501                	li	a0,0
    80002e9e:	00000097          	auipc	ra,0x0
    80002ea2:	d46080e7          	jalr	-698(ra) # 80002be4 <argint>
    return -1;
    80002ea6:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80002ea8:	06054563          	bltz	a0,80002f12 <sys_sleep+0x88>
  acquire(&tickslock);
    80002eac:	00015517          	auipc	a0,0x15
    80002eb0:	82450513          	addi	a0,a0,-2012 # 800176d0 <tickslock>
    80002eb4:	ffffe097          	auipc	ra,0xffffe
    80002eb8:	d0e080e7          	jalr	-754(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002ebc:	00006917          	auipc	s2,0x6
    80002ec0:	17492903          	lw	s2,372(s2) # 80009030 <ticks>
  while (ticks - ticks0 < n)
    80002ec4:	fcc42783          	lw	a5,-52(s0)
    80002ec8:	cf85                	beqz	a5,80002f00 <sys_sleep+0x76>
    if (myproc()->killed)
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002eca:	00015997          	auipc	s3,0x15
    80002ece:	80698993          	addi	s3,s3,-2042 # 800176d0 <tickslock>
    80002ed2:	00006497          	auipc	s1,0x6
    80002ed6:	15e48493          	addi	s1,s1,350 # 80009030 <ticks>
    if (myproc()->killed)
    80002eda:	fffff097          	auipc	ra,0xfffff
    80002ede:	aa4080e7          	jalr	-1372(ra) # 8000197e <myproc>
    80002ee2:	551c                	lw	a5,40(a0)
    80002ee4:	ef9d                	bnez	a5,80002f22 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002ee6:	85ce                	mv	a1,s3
    80002ee8:	8526                	mv	a0,s1
    80002eea:	fffff097          	auipc	ra,0xfffff
    80002eee:	16a080e7          	jalr	362(ra) # 80002054 <sleep>
  while (ticks - ticks0 < n)
    80002ef2:	409c                	lw	a5,0(s1)
    80002ef4:	412787bb          	subw	a5,a5,s2
    80002ef8:	fcc42703          	lw	a4,-52(s0)
    80002efc:	fce7efe3          	bltu	a5,a4,80002eda <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f00:	00014517          	auipc	a0,0x14
    80002f04:	7d050513          	addi	a0,a0,2000 # 800176d0 <tickslock>
    80002f08:	ffffe097          	auipc	ra,0xffffe
    80002f0c:	d6e080e7          	jalr	-658(ra) # 80000c76 <release>
  return 0;
    80002f10:	4781                	li	a5,0
}
    80002f12:	853e                	mv	a0,a5
    80002f14:	70e2                	ld	ra,56(sp)
    80002f16:	7442                	ld	s0,48(sp)
    80002f18:	74a2                	ld	s1,40(sp)
    80002f1a:	7902                	ld	s2,32(sp)
    80002f1c:	69e2                	ld	s3,24(sp)
    80002f1e:	6121                	addi	sp,sp,64
    80002f20:	8082                	ret
      release(&tickslock);
    80002f22:	00014517          	auipc	a0,0x14
    80002f26:	7ae50513          	addi	a0,a0,1966 # 800176d0 <tickslock>
    80002f2a:	ffffe097          	auipc	ra,0xffffe
    80002f2e:	d4c080e7          	jalr	-692(ra) # 80000c76 <release>
      return -1;
    80002f32:	57fd                	li	a5,-1
    80002f34:	bff9                	j	80002f12 <sys_sleep+0x88>

0000000080002f36 <sys_kill>:

uint64
sys_kill(void)
{
    80002f36:	1101                	addi	sp,sp,-32
    80002f38:	ec06                	sd	ra,24(sp)
    80002f3a:	e822                	sd	s0,16(sp)
    80002f3c:	1000                	addi	s0,sp,32
  int pid;

  if (argint(0, &pid) < 0)
    80002f3e:	fec40593          	addi	a1,s0,-20
    80002f42:	4501                	li	a0,0
    80002f44:	00000097          	auipc	ra,0x0
    80002f48:	ca0080e7          	jalr	-864(ra) # 80002be4 <argint>
    80002f4c:	87aa                	mv	a5,a0
    return -1;
    80002f4e:	557d                	li	a0,-1
  if (argint(0, &pid) < 0)
    80002f50:	0007c863          	bltz	a5,80002f60 <sys_kill+0x2a>
  return kill(pid);
    80002f54:	fec42503          	lw	a0,-20(s0)
    80002f58:	fffff097          	auipc	ra,0xfffff
    80002f5c:	42e080e7          	jalr	1070(ra) # 80002386 <kill>
}
    80002f60:	60e2                	ld	ra,24(sp)
    80002f62:	6442                	ld	s0,16(sp)
    80002f64:	6105                	addi	sp,sp,32
    80002f66:	8082                	ret

0000000080002f68 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f68:	1101                	addi	sp,sp,-32
    80002f6a:	ec06                	sd	ra,24(sp)
    80002f6c:	e822                	sd	s0,16(sp)
    80002f6e:	e426                	sd	s1,8(sp)
    80002f70:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f72:	00014517          	auipc	a0,0x14
    80002f76:	75e50513          	addi	a0,a0,1886 # 800176d0 <tickslock>
    80002f7a:	ffffe097          	auipc	ra,0xffffe
    80002f7e:	c48080e7          	jalr	-952(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002f82:	00006497          	auipc	s1,0x6
    80002f86:	0ae4a483          	lw	s1,174(s1) # 80009030 <ticks>
  release(&tickslock);
    80002f8a:	00014517          	auipc	a0,0x14
    80002f8e:	74650513          	addi	a0,a0,1862 # 800176d0 <tickslock>
    80002f92:	ffffe097          	auipc	ra,0xffffe
    80002f96:	ce4080e7          	jalr	-796(ra) # 80000c76 <release>
  return xticks;
}
    80002f9a:	02049513          	slli	a0,s1,0x20
    80002f9e:	9101                	srli	a0,a0,0x20
    80002fa0:	60e2                	ld	ra,24(sp)
    80002fa2:	6442                	ld	s0,16(sp)
    80002fa4:	64a2                	ld	s1,8(sp)
    80002fa6:	6105                	addi	sp,sp,32
    80002fa8:	8082                	ret

0000000080002faa <sys_trace>:

//ADDED
uint64
sys_trace(void)
{
    80002faa:	1101                	addi	sp,sp,-32
    80002fac:	ec06                	sd	ra,24(sp)
    80002fae:	e822                	sd	s0,16(sp)
    80002fb0:	1000                	addi	s0,sp,32
  int mask, pid;
  argint(0, &mask);
    80002fb2:	fec40593          	addi	a1,s0,-20
    80002fb6:	4501                	li	a0,0
    80002fb8:	00000097          	auipc	ra,0x0
    80002fbc:	c2c080e7          	jalr	-980(ra) # 80002be4 <argint>
  argint(1, &pid);
    80002fc0:	fe840593          	addi	a1,s0,-24
    80002fc4:	4505                	li	a0,1
    80002fc6:	00000097          	auipc	ra,0x0
    80002fca:	c1e080e7          	jalr	-994(ra) # 80002be4 <argint>
  trace(mask, pid);
    80002fce:	fe842583          	lw	a1,-24(s0)
    80002fd2:	fec42503          	lw	a0,-20(s0)
    80002fd6:	fffff097          	auipc	ra,0xfffff
    80002fda:	57e080e7          	jalr	1406(ra) # 80002554 <trace>
  return 0;
}
    80002fde:	4501                	li	a0,0
    80002fe0:	60e2                	ld	ra,24(sp)
    80002fe2:	6442                	ld	s0,16(sp)
    80002fe4:	6105                	addi	sp,sp,32
    80002fe6:	8082                	ret

0000000080002fe8 <sys_getmsk>:

uint64
sys_getmsk(void)
{
    80002fe8:	1101                	addi	sp,sp,-32
    80002fea:	ec06                	sd	ra,24(sp)
    80002fec:	e822                	sd	s0,16(sp)
    80002fee:	1000                	addi	s0,sp,32
  int pid;
  argint(0, &pid);
    80002ff0:	fec40593          	addi	a1,s0,-20
    80002ff4:	4501                	li	a0,0
    80002ff6:	00000097          	auipc	ra,0x0
    80002ffa:	bee080e7          	jalr	-1042(ra) # 80002be4 <argint>
  return getmsk(pid);
    80002ffe:	fec42503          	lw	a0,-20(s0)
    80003002:	fffff097          	auipc	ra,0xfffff
    80003006:	5bc080e7          	jalr	1468(ra) # 800025be <getmsk>
}
    8000300a:	60e2                	ld	ra,24(sp)
    8000300c:	6442                	ld	s0,16(sp)
    8000300e:	6105                	addi	sp,sp,32
    80003010:	8082                	ret

0000000080003012 <sys_wait_stat>:

uint64
sys_wait_stat(void)
{
    80003012:	1141                	addi	sp,sp,-16
    80003014:	e406                	sd	ra,8(sp)
    80003016:	e022                	sd	s0,0(sp)
    80003018:	0800                	addi	s0,sp,16
  uint64 a = 0, b = 7;
  return wait_stat(a, b);
    8000301a:	459d                	li	a1,7
    8000301c:	4501                	li	a0,0
    8000301e:	fffff097          	auipc	ra,0xfffff
    80003022:	604080e7          	jalr	1540(ra) # 80002622 <wait_stat>
}
    80003026:	60a2                	ld	ra,8(sp)
    80003028:	6402                	ld	s0,0(sp)
    8000302a:	0141                	addi	sp,sp,16
    8000302c:	8082                	ret

000000008000302e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000302e:	7179                	addi	sp,sp,-48
    80003030:	f406                	sd	ra,40(sp)
    80003032:	f022                	sd	s0,32(sp)
    80003034:	ec26                	sd	s1,24(sp)
    80003036:	e84a                	sd	s2,16(sp)
    80003038:	e44e                	sd	s3,8(sp)
    8000303a:	e052                	sd	s4,0(sp)
    8000303c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000303e:	00005597          	auipc	a1,0x5
    80003042:	69a58593          	addi	a1,a1,1690 # 800086d8 <syscalls+0xc8>
    80003046:	00014517          	auipc	a0,0x14
    8000304a:	6a250513          	addi	a0,a0,1698 # 800176e8 <bcache>
    8000304e:	ffffe097          	auipc	ra,0xffffe
    80003052:	ae4080e7          	jalr	-1308(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003056:	0001c797          	auipc	a5,0x1c
    8000305a:	69278793          	addi	a5,a5,1682 # 8001f6e8 <bcache+0x8000>
    8000305e:	0001d717          	auipc	a4,0x1d
    80003062:	8f270713          	addi	a4,a4,-1806 # 8001f950 <bcache+0x8268>
    80003066:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000306a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000306e:	00014497          	auipc	s1,0x14
    80003072:	69248493          	addi	s1,s1,1682 # 80017700 <bcache+0x18>
    b->next = bcache.head.next;
    80003076:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003078:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000307a:	00005a17          	auipc	s4,0x5
    8000307e:	666a0a13          	addi	s4,s4,1638 # 800086e0 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003082:	2b893783          	ld	a5,696(s2)
    80003086:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003088:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000308c:	85d2                	mv	a1,s4
    8000308e:	01048513          	addi	a0,s1,16
    80003092:	00001097          	auipc	ra,0x1
    80003096:	4c2080e7          	jalr	1218(ra) # 80004554 <initsleeplock>
    bcache.head.next->prev = b;
    8000309a:	2b893783          	ld	a5,696(s2)
    8000309e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030a0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030a4:	45848493          	addi	s1,s1,1112
    800030a8:	fd349de3          	bne	s1,s3,80003082 <binit+0x54>
  }
}
    800030ac:	70a2                	ld	ra,40(sp)
    800030ae:	7402                	ld	s0,32(sp)
    800030b0:	64e2                	ld	s1,24(sp)
    800030b2:	6942                	ld	s2,16(sp)
    800030b4:	69a2                	ld	s3,8(sp)
    800030b6:	6a02                	ld	s4,0(sp)
    800030b8:	6145                	addi	sp,sp,48
    800030ba:	8082                	ret

00000000800030bc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030bc:	7179                	addi	sp,sp,-48
    800030be:	f406                	sd	ra,40(sp)
    800030c0:	f022                	sd	s0,32(sp)
    800030c2:	ec26                	sd	s1,24(sp)
    800030c4:	e84a                	sd	s2,16(sp)
    800030c6:	e44e                	sd	s3,8(sp)
    800030c8:	1800                	addi	s0,sp,48
    800030ca:	892a                	mv	s2,a0
    800030cc:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800030ce:	00014517          	auipc	a0,0x14
    800030d2:	61a50513          	addi	a0,a0,1562 # 800176e8 <bcache>
    800030d6:	ffffe097          	auipc	ra,0xffffe
    800030da:	aec080e7          	jalr	-1300(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030de:	0001d497          	auipc	s1,0x1d
    800030e2:	8c24b483          	ld	s1,-1854(s1) # 8001f9a0 <bcache+0x82b8>
    800030e6:	0001d797          	auipc	a5,0x1d
    800030ea:	86a78793          	addi	a5,a5,-1942 # 8001f950 <bcache+0x8268>
    800030ee:	02f48f63          	beq	s1,a5,8000312c <bread+0x70>
    800030f2:	873e                	mv	a4,a5
    800030f4:	a021                	j	800030fc <bread+0x40>
    800030f6:	68a4                	ld	s1,80(s1)
    800030f8:	02e48a63          	beq	s1,a4,8000312c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030fc:	449c                	lw	a5,8(s1)
    800030fe:	ff279ce3          	bne	a5,s2,800030f6 <bread+0x3a>
    80003102:	44dc                	lw	a5,12(s1)
    80003104:	ff3799e3          	bne	a5,s3,800030f6 <bread+0x3a>
      b->refcnt++;
    80003108:	40bc                	lw	a5,64(s1)
    8000310a:	2785                	addiw	a5,a5,1
    8000310c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000310e:	00014517          	auipc	a0,0x14
    80003112:	5da50513          	addi	a0,a0,1498 # 800176e8 <bcache>
    80003116:	ffffe097          	auipc	ra,0xffffe
    8000311a:	b60080e7          	jalr	-1184(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000311e:	01048513          	addi	a0,s1,16
    80003122:	00001097          	auipc	ra,0x1
    80003126:	46c080e7          	jalr	1132(ra) # 8000458e <acquiresleep>
      return b;
    8000312a:	a8b9                	j	80003188 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000312c:	0001d497          	auipc	s1,0x1d
    80003130:	86c4b483          	ld	s1,-1940(s1) # 8001f998 <bcache+0x82b0>
    80003134:	0001d797          	auipc	a5,0x1d
    80003138:	81c78793          	addi	a5,a5,-2020 # 8001f950 <bcache+0x8268>
    8000313c:	00f48863          	beq	s1,a5,8000314c <bread+0x90>
    80003140:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003142:	40bc                	lw	a5,64(s1)
    80003144:	cf81                	beqz	a5,8000315c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003146:	64a4                	ld	s1,72(s1)
    80003148:	fee49de3          	bne	s1,a4,80003142 <bread+0x86>
  panic("bget: no buffers");
    8000314c:	00005517          	auipc	a0,0x5
    80003150:	59c50513          	addi	a0,a0,1436 # 800086e8 <syscalls+0xd8>
    80003154:	ffffd097          	auipc	ra,0xffffd
    80003158:	3d6080e7          	jalr	982(ra) # 8000052a <panic>
      b->dev = dev;
    8000315c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003160:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003164:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003168:	4785                	li	a5,1
    8000316a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000316c:	00014517          	auipc	a0,0x14
    80003170:	57c50513          	addi	a0,a0,1404 # 800176e8 <bcache>
    80003174:	ffffe097          	auipc	ra,0xffffe
    80003178:	b02080e7          	jalr	-1278(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000317c:	01048513          	addi	a0,s1,16
    80003180:	00001097          	auipc	ra,0x1
    80003184:	40e080e7          	jalr	1038(ra) # 8000458e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003188:	409c                	lw	a5,0(s1)
    8000318a:	cb89                	beqz	a5,8000319c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000318c:	8526                	mv	a0,s1
    8000318e:	70a2                	ld	ra,40(sp)
    80003190:	7402                	ld	s0,32(sp)
    80003192:	64e2                	ld	s1,24(sp)
    80003194:	6942                	ld	s2,16(sp)
    80003196:	69a2                	ld	s3,8(sp)
    80003198:	6145                	addi	sp,sp,48
    8000319a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000319c:	4581                	li	a1,0
    8000319e:	8526                	mv	a0,s1
    800031a0:	00003097          	auipc	ra,0x3
    800031a4:	f26080e7          	jalr	-218(ra) # 800060c6 <virtio_disk_rw>
    b->valid = 1;
    800031a8:	4785                	li	a5,1
    800031aa:	c09c                	sw	a5,0(s1)
  return b;
    800031ac:	b7c5                	j	8000318c <bread+0xd0>

00000000800031ae <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031ae:	1101                	addi	sp,sp,-32
    800031b0:	ec06                	sd	ra,24(sp)
    800031b2:	e822                	sd	s0,16(sp)
    800031b4:	e426                	sd	s1,8(sp)
    800031b6:	1000                	addi	s0,sp,32
    800031b8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031ba:	0541                	addi	a0,a0,16
    800031bc:	00001097          	auipc	ra,0x1
    800031c0:	46c080e7          	jalr	1132(ra) # 80004628 <holdingsleep>
    800031c4:	cd01                	beqz	a0,800031dc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031c6:	4585                	li	a1,1
    800031c8:	8526                	mv	a0,s1
    800031ca:	00003097          	auipc	ra,0x3
    800031ce:	efc080e7          	jalr	-260(ra) # 800060c6 <virtio_disk_rw>
}
    800031d2:	60e2                	ld	ra,24(sp)
    800031d4:	6442                	ld	s0,16(sp)
    800031d6:	64a2                	ld	s1,8(sp)
    800031d8:	6105                	addi	sp,sp,32
    800031da:	8082                	ret
    panic("bwrite");
    800031dc:	00005517          	auipc	a0,0x5
    800031e0:	52450513          	addi	a0,a0,1316 # 80008700 <syscalls+0xf0>
    800031e4:	ffffd097          	auipc	ra,0xffffd
    800031e8:	346080e7          	jalr	838(ra) # 8000052a <panic>

00000000800031ec <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031ec:	1101                	addi	sp,sp,-32
    800031ee:	ec06                	sd	ra,24(sp)
    800031f0:	e822                	sd	s0,16(sp)
    800031f2:	e426                	sd	s1,8(sp)
    800031f4:	e04a                	sd	s2,0(sp)
    800031f6:	1000                	addi	s0,sp,32
    800031f8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031fa:	01050913          	addi	s2,a0,16
    800031fe:	854a                	mv	a0,s2
    80003200:	00001097          	auipc	ra,0x1
    80003204:	428080e7          	jalr	1064(ra) # 80004628 <holdingsleep>
    80003208:	c92d                	beqz	a0,8000327a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000320a:	854a                	mv	a0,s2
    8000320c:	00001097          	auipc	ra,0x1
    80003210:	3d8080e7          	jalr	984(ra) # 800045e4 <releasesleep>

  acquire(&bcache.lock);
    80003214:	00014517          	auipc	a0,0x14
    80003218:	4d450513          	addi	a0,a0,1236 # 800176e8 <bcache>
    8000321c:	ffffe097          	auipc	ra,0xffffe
    80003220:	9a6080e7          	jalr	-1626(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003224:	40bc                	lw	a5,64(s1)
    80003226:	37fd                	addiw	a5,a5,-1
    80003228:	0007871b          	sext.w	a4,a5
    8000322c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000322e:	eb05                	bnez	a4,8000325e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003230:	68bc                	ld	a5,80(s1)
    80003232:	64b8                	ld	a4,72(s1)
    80003234:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003236:	64bc                	ld	a5,72(s1)
    80003238:	68b8                	ld	a4,80(s1)
    8000323a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000323c:	0001c797          	auipc	a5,0x1c
    80003240:	4ac78793          	addi	a5,a5,1196 # 8001f6e8 <bcache+0x8000>
    80003244:	2b87b703          	ld	a4,696(a5)
    80003248:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000324a:	0001c717          	auipc	a4,0x1c
    8000324e:	70670713          	addi	a4,a4,1798 # 8001f950 <bcache+0x8268>
    80003252:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003254:	2b87b703          	ld	a4,696(a5)
    80003258:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000325a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000325e:	00014517          	auipc	a0,0x14
    80003262:	48a50513          	addi	a0,a0,1162 # 800176e8 <bcache>
    80003266:	ffffe097          	auipc	ra,0xffffe
    8000326a:	a10080e7          	jalr	-1520(ra) # 80000c76 <release>
}
    8000326e:	60e2                	ld	ra,24(sp)
    80003270:	6442                	ld	s0,16(sp)
    80003272:	64a2                	ld	s1,8(sp)
    80003274:	6902                	ld	s2,0(sp)
    80003276:	6105                	addi	sp,sp,32
    80003278:	8082                	ret
    panic("brelse");
    8000327a:	00005517          	auipc	a0,0x5
    8000327e:	48e50513          	addi	a0,a0,1166 # 80008708 <syscalls+0xf8>
    80003282:	ffffd097          	auipc	ra,0xffffd
    80003286:	2a8080e7          	jalr	680(ra) # 8000052a <panic>

000000008000328a <bpin>:

void
bpin(struct buf *b) {
    8000328a:	1101                	addi	sp,sp,-32
    8000328c:	ec06                	sd	ra,24(sp)
    8000328e:	e822                	sd	s0,16(sp)
    80003290:	e426                	sd	s1,8(sp)
    80003292:	1000                	addi	s0,sp,32
    80003294:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003296:	00014517          	auipc	a0,0x14
    8000329a:	45250513          	addi	a0,a0,1106 # 800176e8 <bcache>
    8000329e:	ffffe097          	auipc	ra,0xffffe
    800032a2:	924080e7          	jalr	-1756(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800032a6:	40bc                	lw	a5,64(s1)
    800032a8:	2785                	addiw	a5,a5,1
    800032aa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032ac:	00014517          	auipc	a0,0x14
    800032b0:	43c50513          	addi	a0,a0,1084 # 800176e8 <bcache>
    800032b4:	ffffe097          	auipc	ra,0xffffe
    800032b8:	9c2080e7          	jalr	-1598(ra) # 80000c76 <release>
}
    800032bc:	60e2                	ld	ra,24(sp)
    800032be:	6442                	ld	s0,16(sp)
    800032c0:	64a2                	ld	s1,8(sp)
    800032c2:	6105                	addi	sp,sp,32
    800032c4:	8082                	ret

00000000800032c6 <bunpin>:

void
bunpin(struct buf *b) {
    800032c6:	1101                	addi	sp,sp,-32
    800032c8:	ec06                	sd	ra,24(sp)
    800032ca:	e822                	sd	s0,16(sp)
    800032cc:	e426                	sd	s1,8(sp)
    800032ce:	1000                	addi	s0,sp,32
    800032d0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032d2:	00014517          	auipc	a0,0x14
    800032d6:	41650513          	addi	a0,a0,1046 # 800176e8 <bcache>
    800032da:	ffffe097          	auipc	ra,0xffffe
    800032de:	8e8080e7          	jalr	-1816(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800032e2:	40bc                	lw	a5,64(s1)
    800032e4:	37fd                	addiw	a5,a5,-1
    800032e6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032e8:	00014517          	auipc	a0,0x14
    800032ec:	40050513          	addi	a0,a0,1024 # 800176e8 <bcache>
    800032f0:	ffffe097          	auipc	ra,0xffffe
    800032f4:	986080e7          	jalr	-1658(ra) # 80000c76 <release>
}
    800032f8:	60e2                	ld	ra,24(sp)
    800032fa:	6442                	ld	s0,16(sp)
    800032fc:	64a2                	ld	s1,8(sp)
    800032fe:	6105                	addi	sp,sp,32
    80003300:	8082                	ret

0000000080003302 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003302:	1101                	addi	sp,sp,-32
    80003304:	ec06                	sd	ra,24(sp)
    80003306:	e822                	sd	s0,16(sp)
    80003308:	e426                	sd	s1,8(sp)
    8000330a:	e04a                	sd	s2,0(sp)
    8000330c:	1000                	addi	s0,sp,32
    8000330e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003310:	00d5d59b          	srliw	a1,a1,0xd
    80003314:	0001d797          	auipc	a5,0x1d
    80003318:	ab07a783          	lw	a5,-1360(a5) # 8001fdc4 <sb+0x1c>
    8000331c:	9dbd                	addw	a1,a1,a5
    8000331e:	00000097          	auipc	ra,0x0
    80003322:	d9e080e7          	jalr	-610(ra) # 800030bc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003326:	0074f713          	andi	a4,s1,7
    8000332a:	4785                	li	a5,1
    8000332c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003330:	14ce                	slli	s1,s1,0x33
    80003332:	90d9                	srli	s1,s1,0x36
    80003334:	00950733          	add	a4,a0,s1
    80003338:	05874703          	lbu	a4,88(a4)
    8000333c:	00e7f6b3          	and	a3,a5,a4
    80003340:	c69d                	beqz	a3,8000336e <bfree+0x6c>
    80003342:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003344:	94aa                	add	s1,s1,a0
    80003346:	fff7c793          	not	a5,a5
    8000334a:	8ff9                	and	a5,a5,a4
    8000334c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003350:	00001097          	auipc	ra,0x1
    80003354:	11e080e7          	jalr	286(ra) # 8000446e <log_write>
  brelse(bp);
    80003358:	854a                	mv	a0,s2
    8000335a:	00000097          	auipc	ra,0x0
    8000335e:	e92080e7          	jalr	-366(ra) # 800031ec <brelse>
}
    80003362:	60e2                	ld	ra,24(sp)
    80003364:	6442                	ld	s0,16(sp)
    80003366:	64a2                	ld	s1,8(sp)
    80003368:	6902                	ld	s2,0(sp)
    8000336a:	6105                	addi	sp,sp,32
    8000336c:	8082                	ret
    panic("freeing free block");
    8000336e:	00005517          	auipc	a0,0x5
    80003372:	3a250513          	addi	a0,a0,930 # 80008710 <syscalls+0x100>
    80003376:	ffffd097          	auipc	ra,0xffffd
    8000337a:	1b4080e7          	jalr	436(ra) # 8000052a <panic>

000000008000337e <balloc>:
{
    8000337e:	711d                	addi	sp,sp,-96
    80003380:	ec86                	sd	ra,88(sp)
    80003382:	e8a2                	sd	s0,80(sp)
    80003384:	e4a6                	sd	s1,72(sp)
    80003386:	e0ca                	sd	s2,64(sp)
    80003388:	fc4e                	sd	s3,56(sp)
    8000338a:	f852                	sd	s4,48(sp)
    8000338c:	f456                	sd	s5,40(sp)
    8000338e:	f05a                	sd	s6,32(sp)
    80003390:	ec5e                	sd	s7,24(sp)
    80003392:	e862                	sd	s8,16(sp)
    80003394:	e466                	sd	s9,8(sp)
    80003396:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003398:	0001d797          	auipc	a5,0x1d
    8000339c:	a147a783          	lw	a5,-1516(a5) # 8001fdac <sb+0x4>
    800033a0:	cbd1                	beqz	a5,80003434 <balloc+0xb6>
    800033a2:	8baa                	mv	s7,a0
    800033a4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033a6:	0001db17          	auipc	s6,0x1d
    800033aa:	a02b0b13          	addi	s6,s6,-1534 # 8001fda8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ae:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033b0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033b2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033b4:	6c89                	lui	s9,0x2
    800033b6:	a831                	j	800033d2 <balloc+0x54>
    brelse(bp);
    800033b8:	854a                	mv	a0,s2
    800033ba:	00000097          	auipc	ra,0x0
    800033be:	e32080e7          	jalr	-462(ra) # 800031ec <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033c2:	015c87bb          	addw	a5,s9,s5
    800033c6:	00078a9b          	sext.w	s5,a5
    800033ca:	004b2703          	lw	a4,4(s6)
    800033ce:	06eaf363          	bgeu	s5,a4,80003434 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033d2:	41fad79b          	sraiw	a5,s5,0x1f
    800033d6:	0137d79b          	srliw	a5,a5,0x13
    800033da:	015787bb          	addw	a5,a5,s5
    800033de:	40d7d79b          	sraiw	a5,a5,0xd
    800033e2:	01cb2583          	lw	a1,28(s6)
    800033e6:	9dbd                	addw	a1,a1,a5
    800033e8:	855e                	mv	a0,s7
    800033ea:	00000097          	auipc	ra,0x0
    800033ee:	cd2080e7          	jalr	-814(ra) # 800030bc <bread>
    800033f2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033f4:	004b2503          	lw	a0,4(s6)
    800033f8:	000a849b          	sext.w	s1,s5
    800033fc:	8662                	mv	a2,s8
    800033fe:	faa4fde3          	bgeu	s1,a0,800033b8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003402:	41f6579b          	sraiw	a5,a2,0x1f
    80003406:	01d7d69b          	srliw	a3,a5,0x1d
    8000340a:	00c6873b          	addw	a4,a3,a2
    8000340e:	00777793          	andi	a5,a4,7
    80003412:	9f95                	subw	a5,a5,a3
    80003414:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003418:	4037571b          	sraiw	a4,a4,0x3
    8000341c:	00e906b3          	add	a3,s2,a4
    80003420:	0586c683          	lbu	a3,88(a3)
    80003424:	00d7f5b3          	and	a1,a5,a3
    80003428:	cd91                	beqz	a1,80003444 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000342a:	2605                	addiw	a2,a2,1
    8000342c:	2485                	addiw	s1,s1,1
    8000342e:	fd4618e3          	bne	a2,s4,800033fe <balloc+0x80>
    80003432:	b759                	j	800033b8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003434:	00005517          	auipc	a0,0x5
    80003438:	2f450513          	addi	a0,a0,756 # 80008728 <syscalls+0x118>
    8000343c:	ffffd097          	auipc	ra,0xffffd
    80003440:	0ee080e7          	jalr	238(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003444:	974a                	add	a4,a4,s2
    80003446:	8fd5                	or	a5,a5,a3
    80003448:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000344c:	854a                	mv	a0,s2
    8000344e:	00001097          	auipc	ra,0x1
    80003452:	020080e7          	jalr	32(ra) # 8000446e <log_write>
        brelse(bp);
    80003456:	854a                	mv	a0,s2
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	d94080e7          	jalr	-620(ra) # 800031ec <brelse>
  bp = bread(dev, bno);
    80003460:	85a6                	mv	a1,s1
    80003462:	855e                	mv	a0,s7
    80003464:	00000097          	auipc	ra,0x0
    80003468:	c58080e7          	jalr	-936(ra) # 800030bc <bread>
    8000346c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000346e:	40000613          	li	a2,1024
    80003472:	4581                	li	a1,0
    80003474:	05850513          	addi	a0,a0,88
    80003478:	ffffe097          	auipc	ra,0xffffe
    8000347c:	846080e7          	jalr	-1978(ra) # 80000cbe <memset>
  log_write(bp);
    80003480:	854a                	mv	a0,s2
    80003482:	00001097          	auipc	ra,0x1
    80003486:	fec080e7          	jalr	-20(ra) # 8000446e <log_write>
  brelse(bp);
    8000348a:	854a                	mv	a0,s2
    8000348c:	00000097          	auipc	ra,0x0
    80003490:	d60080e7          	jalr	-672(ra) # 800031ec <brelse>
}
    80003494:	8526                	mv	a0,s1
    80003496:	60e6                	ld	ra,88(sp)
    80003498:	6446                	ld	s0,80(sp)
    8000349a:	64a6                	ld	s1,72(sp)
    8000349c:	6906                	ld	s2,64(sp)
    8000349e:	79e2                	ld	s3,56(sp)
    800034a0:	7a42                	ld	s4,48(sp)
    800034a2:	7aa2                	ld	s5,40(sp)
    800034a4:	7b02                	ld	s6,32(sp)
    800034a6:	6be2                	ld	s7,24(sp)
    800034a8:	6c42                	ld	s8,16(sp)
    800034aa:	6ca2                	ld	s9,8(sp)
    800034ac:	6125                	addi	sp,sp,96
    800034ae:	8082                	ret

00000000800034b0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034b0:	7179                	addi	sp,sp,-48
    800034b2:	f406                	sd	ra,40(sp)
    800034b4:	f022                	sd	s0,32(sp)
    800034b6:	ec26                	sd	s1,24(sp)
    800034b8:	e84a                	sd	s2,16(sp)
    800034ba:	e44e                	sd	s3,8(sp)
    800034bc:	e052                	sd	s4,0(sp)
    800034be:	1800                	addi	s0,sp,48
    800034c0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034c2:	47ad                	li	a5,11
    800034c4:	04b7fe63          	bgeu	a5,a1,80003520 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034c8:	ff45849b          	addiw	s1,a1,-12
    800034cc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034d0:	0ff00793          	li	a5,255
    800034d4:	0ae7e463          	bltu	a5,a4,8000357c <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034d8:	08052583          	lw	a1,128(a0)
    800034dc:	c5b5                	beqz	a1,80003548 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800034de:	00092503          	lw	a0,0(s2)
    800034e2:	00000097          	auipc	ra,0x0
    800034e6:	bda080e7          	jalr	-1062(ra) # 800030bc <bread>
    800034ea:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034ec:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034f0:	02049713          	slli	a4,s1,0x20
    800034f4:	01e75593          	srli	a1,a4,0x1e
    800034f8:	00b784b3          	add	s1,a5,a1
    800034fc:	0004a983          	lw	s3,0(s1)
    80003500:	04098e63          	beqz	s3,8000355c <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003504:	8552                	mv	a0,s4
    80003506:	00000097          	auipc	ra,0x0
    8000350a:	ce6080e7          	jalr	-794(ra) # 800031ec <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000350e:	854e                	mv	a0,s3
    80003510:	70a2                	ld	ra,40(sp)
    80003512:	7402                	ld	s0,32(sp)
    80003514:	64e2                	ld	s1,24(sp)
    80003516:	6942                	ld	s2,16(sp)
    80003518:	69a2                	ld	s3,8(sp)
    8000351a:	6a02                	ld	s4,0(sp)
    8000351c:	6145                	addi	sp,sp,48
    8000351e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003520:	02059793          	slli	a5,a1,0x20
    80003524:	01e7d593          	srli	a1,a5,0x1e
    80003528:	00b504b3          	add	s1,a0,a1
    8000352c:	0504a983          	lw	s3,80(s1)
    80003530:	fc099fe3          	bnez	s3,8000350e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003534:	4108                	lw	a0,0(a0)
    80003536:	00000097          	auipc	ra,0x0
    8000353a:	e48080e7          	jalr	-440(ra) # 8000337e <balloc>
    8000353e:	0005099b          	sext.w	s3,a0
    80003542:	0534a823          	sw	s3,80(s1)
    80003546:	b7e1                	j	8000350e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003548:	4108                	lw	a0,0(a0)
    8000354a:	00000097          	auipc	ra,0x0
    8000354e:	e34080e7          	jalr	-460(ra) # 8000337e <balloc>
    80003552:	0005059b          	sext.w	a1,a0
    80003556:	08b92023          	sw	a1,128(s2)
    8000355a:	b751                	j	800034de <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000355c:	00092503          	lw	a0,0(s2)
    80003560:	00000097          	auipc	ra,0x0
    80003564:	e1e080e7          	jalr	-482(ra) # 8000337e <balloc>
    80003568:	0005099b          	sext.w	s3,a0
    8000356c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003570:	8552                	mv	a0,s4
    80003572:	00001097          	auipc	ra,0x1
    80003576:	efc080e7          	jalr	-260(ra) # 8000446e <log_write>
    8000357a:	b769                	j	80003504 <bmap+0x54>
  panic("bmap: out of range");
    8000357c:	00005517          	auipc	a0,0x5
    80003580:	1c450513          	addi	a0,a0,452 # 80008740 <syscalls+0x130>
    80003584:	ffffd097          	auipc	ra,0xffffd
    80003588:	fa6080e7          	jalr	-90(ra) # 8000052a <panic>

000000008000358c <iget>:
{
    8000358c:	7179                	addi	sp,sp,-48
    8000358e:	f406                	sd	ra,40(sp)
    80003590:	f022                	sd	s0,32(sp)
    80003592:	ec26                	sd	s1,24(sp)
    80003594:	e84a                	sd	s2,16(sp)
    80003596:	e44e                	sd	s3,8(sp)
    80003598:	e052                	sd	s4,0(sp)
    8000359a:	1800                	addi	s0,sp,48
    8000359c:	89aa                	mv	s3,a0
    8000359e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035a0:	0001d517          	auipc	a0,0x1d
    800035a4:	82850513          	addi	a0,a0,-2008 # 8001fdc8 <itable>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	61a080e7          	jalr	1562(ra) # 80000bc2 <acquire>
  empty = 0;
    800035b0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035b2:	0001d497          	auipc	s1,0x1d
    800035b6:	82e48493          	addi	s1,s1,-2002 # 8001fde0 <itable+0x18>
    800035ba:	0001e697          	auipc	a3,0x1e
    800035be:	2b668693          	addi	a3,a3,694 # 80021870 <log>
    800035c2:	a039                	j	800035d0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035c4:	02090b63          	beqz	s2,800035fa <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035c8:	08848493          	addi	s1,s1,136
    800035cc:	02d48a63          	beq	s1,a3,80003600 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035d0:	449c                	lw	a5,8(s1)
    800035d2:	fef059e3          	blez	a5,800035c4 <iget+0x38>
    800035d6:	4098                	lw	a4,0(s1)
    800035d8:	ff3716e3          	bne	a4,s3,800035c4 <iget+0x38>
    800035dc:	40d8                	lw	a4,4(s1)
    800035de:	ff4713e3          	bne	a4,s4,800035c4 <iget+0x38>
      ip->ref++;
    800035e2:	2785                	addiw	a5,a5,1
    800035e4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035e6:	0001c517          	auipc	a0,0x1c
    800035ea:	7e250513          	addi	a0,a0,2018 # 8001fdc8 <itable>
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	688080e7          	jalr	1672(ra) # 80000c76 <release>
      return ip;
    800035f6:	8926                	mv	s2,s1
    800035f8:	a03d                	j	80003626 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035fa:	f7f9                	bnez	a5,800035c8 <iget+0x3c>
    800035fc:	8926                	mv	s2,s1
    800035fe:	b7e9                	j	800035c8 <iget+0x3c>
  if(empty == 0)
    80003600:	02090c63          	beqz	s2,80003638 <iget+0xac>
  ip->dev = dev;
    80003604:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003608:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000360c:	4785                	li	a5,1
    8000360e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003612:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003616:	0001c517          	auipc	a0,0x1c
    8000361a:	7b250513          	addi	a0,a0,1970 # 8001fdc8 <itable>
    8000361e:	ffffd097          	auipc	ra,0xffffd
    80003622:	658080e7          	jalr	1624(ra) # 80000c76 <release>
}
    80003626:	854a                	mv	a0,s2
    80003628:	70a2                	ld	ra,40(sp)
    8000362a:	7402                	ld	s0,32(sp)
    8000362c:	64e2                	ld	s1,24(sp)
    8000362e:	6942                	ld	s2,16(sp)
    80003630:	69a2                	ld	s3,8(sp)
    80003632:	6a02                	ld	s4,0(sp)
    80003634:	6145                	addi	sp,sp,48
    80003636:	8082                	ret
    panic("iget: no inodes");
    80003638:	00005517          	auipc	a0,0x5
    8000363c:	12050513          	addi	a0,a0,288 # 80008758 <syscalls+0x148>
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	eea080e7          	jalr	-278(ra) # 8000052a <panic>

0000000080003648 <fsinit>:
fsinit(int dev) {
    80003648:	7179                	addi	sp,sp,-48
    8000364a:	f406                	sd	ra,40(sp)
    8000364c:	f022                	sd	s0,32(sp)
    8000364e:	ec26                	sd	s1,24(sp)
    80003650:	e84a                	sd	s2,16(sp)
    80003652:	e44e                	sd	s3,8(sp)
    80003654:	1800                	addi	s0,sp,48
    80003656:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003658:	4585                	li	a1,1
    8000365a:	00000097          	auipc	ra,0x0
    8000365e:	a62080e7          	jalr	-1438(ra) # 800030bc <bread>
    80003662:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003664:	0001c997          	auipc	s3,0x1c
    80003668:	74498993          	addi	s3,s3,1860 # 8001fda8 <sb>
    8000366c:	02000613          	li	a2,32
    80003670:	05850593          	addi	a1,a0,88
    80003674:	854e                	mv	a0,s3
    80003676:	ffffd097          	auipc	ra,0xffffd
    8000367a:	6a4080e7          	jalr	1700(ra) # 80000d1a <memmove>
  brelse(bp);
    8000367e:	8526                	mv	a0,s1
    80003680:	00000097          	auipc	ra,0x0
    80003684:	b6c080e7          	jalr	-1172(ra) # 800031ec <brelse>
  if(sb.magic != FSMAGIC)
    80003688:	0009a703          	lw	a4,0(s3)
    8000368c:	102037b7          	lui	a5,0x10203
    80003690:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003694:	02f71263          	bne	a4,a5,800036b8 <fsinit+0x70>
  initlog(dev, &sb);
    80003698:	0001c597          	auipc	a1,0x1c
    8000369c:	71058593          	addi	a1,a1,1808 # 8001fda8 <sb>
    800036a0:	854a                	mv	a0,s2
    800036a2:	00001097          	auipc	ra,0x1
    800036a6:	b4e080e7          	jalr	-1202(ra) # 800041f0 <initlog>
}
    800036aa:	70a2                	ld	ra,40(sp)
    800036ac:	7402                	ld	s0,32(sp)
    800036ae:	64e2                	ld	s1,24(sp)
    800036b0:	6942                	ld	s2,16(sp)
    800036b2:	69a2                	ld	s3,8(sp)
    800036b4:	6145                	addi	sp,sp,48
    800036b6:	8082                	ret
    panic("invalid file system");
    800036b8:	00005517          	auipc	a0,0x5
    800036bc:	0b050513          	addi	a0,a0,176 # 80008768 <syscalls+0x158>
    800036c0:	ffffd097          	auipc	ra,0xffffd
    800036c4:	e6a080e7          	jalr	-406(ra) # 8000052a <panic>

00000000800036c8 <iinit>:
{
    800036c8:	7179                	addi	sp,sp,-48
    800036ca:	f406                	sd	ra,40(sp)
    800036cc:	f022                	sd	s0,32(sp)
    800036ce:	ec26                	sd	s1,24(sp)
    800036d0:	e84a                	sd	s2,16(sp)
    800036d2:	e44e                	sd	s3,8(sp)
    800036d4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036d6:	00005597          	auipc	a1,0x5
    800036da:	0aa58593          	addi	a1,a1,170 # 80008780 <syscalls+0x170>
    800036de:	0001c517          	auipc	a0,0x1c
    800036e2:	6ea50513          	addi	a0,a0,1770 # 8001fdc8 <itable>
    800036e6:	ffffd097          	auipc	ra,0xffffd
    800036ea:	44c080e7          	jalr	1100(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036ee:	0001c497          	auipc	s1,0x1c
    800036f2:	70248493          	addi	s1,s1,1794 # 8001fdf0 <itable+0x28>
    800036f6:	0001e997          	auipc	s3,0x1e
    800036fa:	18a98993          	addi	s3,s3,394 # 80021880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036fe:	00005917          	auipc	s2,0x5
    80003702:	08a90913          	addi	s2,s2,138 # 80008788 <syscalls+0x178>
    80003706:	85ca                	mv	a1,s2
    80003708:	8526                	mv	a0,s1
    8000370a:	00001097          	auipc	ra,0x1
    8000370e:	e4a080e7          	jalr	-438(ra) # 80004554 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003712:	08848493          	addi	s1,s1,136
    80003716:	ff3498e3          	bne	s1,s3,80003706 <iinit+0x3e>
}
    8000371a:	70a2                	ld	ra,40(sp)
    8000371c:	7402                	ld	s0,32(sp)
    8000371e:	64e2                	ld	s1,24(sp)
    80003720:	6942                	ld	s2,16(sp)
    80003722:	69a2                	ld	s3,8(sp)
    80003724:	6145                	addi	sp,sp,48
    80003726:	8082                	ret

0000000080003728 <ialloc>:
{
    80003728:	715d                	addi	sp,sp,-80
    8000372a:	e486                	sd	ra,72(sp)
    8000372c:	e0a2                	sd	s0,64(sp)
    8000372e:	fc26                	sd	s1,56(sp)
    80003730:	f84a                	sd	s2,48(sp)
    80003732:	f44e                	sd	s3,40(sp)
    80003734:	f052                	sd	s4,32(sp)
    80003736:	ec56                	sd	s5,24(sp)
    80003738:	e85a                	sd	s6,16(sp)
    8000373a:	e45e                	sd	s7,8(sp)
    8000373c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000373e:	0001c717          	auipc	a4,0x1c
    80003742:	67672703          	lw	a4,1654(a4) # 8001fdb4 <sb+0xc>
    80003746:	4785                	li	a5,1
    80003748:	04e7fa63          	bgeu	a5,a4,8000379c <ialloc+0x74>
    8000374c:	8aaa                	mv	s5,a0
    8000374e:	8bae                	mv	s7,a1
    80003750:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003752:	0001ca17          	auipc	s4,0x1c
    80003756:	656a0a13          	addi	s4,s4,1622 # 8001fda8 <sb>
    8000375a:	00048b1b          	sext.w	s6,s1
    8000375e:	0044d793          	srli	a5,s1,0x4
    80003762:	018a2583          	lw	a1,24(s4)
    80003766:	9dbd                	addw	a1,a1,a5
    80003768:	8556                	mv	a0,s5
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	952080e7          	jalr	-1710(ra) # 800030bc <bread>
    80003772:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003774:	05850993          	addi	s3,a0,88
    80003778:	00f4f793          	andi	a5,s1,15
    8000377c:	079a                	slli	a5,a5,0x6
    8000377e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003780:	00099783          	lh	a5,0(s3)
    80003784:	c785                	beqz	a5,800037ac <ialloc+0x84>
    brelse(bp);
    80003786:	00000097          	auipc	ra,0x0
    8000378a:	a66080e7          	jalr	-1434(ra) # 800031ec <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000378e:	0485                	addi	s1,s1,1
    80003790:	00ca2703          	lw	a4,12(s4)
    80003794:	0004879b          	sext.w	a5,s1
    80003798:	fce7e1e3          	bltu	a5,a4,8000375a <ialloc+0x32>
  panic("ialloc: no inodes");
    8000379c:	00005517          	auipc	a0,0x5
    800037a0:	ff450513          	addi	a0,a0,-12 # 80008790 <syscalls+0x180>
    800037a4:	ffffd097          	auipc	ra,0xffffd
    800037a8:	d86080e7          	jalr	-634(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800037ac:	04000613          	li	a2,64
    800037b0:	4581                	li	a1,0
    800037b2:	854e                	mv	a0,s3
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	50a080e7          	jalr	1290(ra) # 80000cbe <memset>
      dip->type = type;
    800037bc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037c0:	854a                	mv	a0,s2
    800037c2:	00001097          	auipc	ra,0x1
    800037c6:	cac080e7          	jalr	-852(ra) # 8000446e <log_write>
      brelse(bp);
    800037ca:	854a                	mv	a0,s2
    800037cc:	00000097          	auipc	ra,0x0
    800037d0:	a20080e7          	jalr	-1504(ra) # 800031ec <brelse>
      return iget(dev, inum);
    800037d4:	85da                	mv	a1,s6
    800037d6:	8556                	mv	a0,s5
    800037d8:	00000097          	auipc	ra,0x0
    800037dc:	db4080e7          	jalr	-588(ra) # 8000358c <iget>
}
    800037e0:	60a6                	ld	ra,72(sp)
    800037e2:	6406                	ld	s0,64(sp)
    800037e4:	74e2                	ld	s1,56(sp)
    800037e6:	7942                	ld	s2,48(sp)
    800037e8:	79a2                	ld	s3,40(sp)
    800037ea:	7a02                	ld	s4,32(sp)
    800037ec:	6ae2                	ld	s5,24(sp)
    800037ee:	6b42                	ld	s6,16(sp)
    800037f0:	6ba2                	ld	s7,8(sp)
    800037f2:	6161                	addi	sp,sp,80
    800037f4:	8082                	ret

00000000800037f6 <iupdate>:
{
    800037f6:	1101                	addi	sp,sp,-32
    800037f8:	ec06                	sd	ra,24(sp)
    800037fa:	e822                	sd	s0,16(sp)
    800037fc:	e426                	sd	s1,8(sp)
    800037fe:	e04a                	sd	s2,0(sp)
    80003800:	1000                	addi	s0,sp,32
    80003802:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003804:	415c                	lw	a5,4(a0)
    80003806:	0047d79b          	srliw	a5,a5,0x4
    8000380a:	0001c597          	auipc	a1,0x1c
    8000380e:	5b65a583          	lw	a1,1462(a1) # 8001fdc0 <sb+0x18>
    80003812:	9dbd                	addw	a1,a1,a5
    80003814:	4108                	lw	a0,0(a0)
    80003816:	00000097          	auipc	ra,0x0
    8000381a:	8a6080e7          	jalr	-1882(ra) # 800030bc <bread>
    8000381e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003820:	05850793          	addi	a5,a0,88
    80003824:	40c8                	lw	a0,4(s1)
    80003826:	893d                	andi	a0,a0,15
    80003828:	051a                	slli	a0,a0,0x6
    8000382a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000382c:	04449703          	lh	a4,68(s1)
    80003830:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003834:	04649703          	lh	a4,70(s1)
    80003838:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000383c:	04849703          	lh	a4,72(s1)
    80003840:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003844:	04a49703          	lh	a4,74(s1)
    80003848:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000384c:	44f8                	lw	a4,76(s1)
    8000384e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003850:	03400613          	li	a2,52
    80003854:	05048593          	addi	a1,s1,80
    80003858:	0531                	addi	a0,a0,12
    8000385a:	ffffd097          	auipc	ra,0xffffd
    8000385e:	4c0080e7          	jalr	1216(ra) # 80000d1a <memmove>
  log_write(bp);
    80003862:	854a                	mv	a0,s2
    80003864:	00001097          	auipc	ra,0x1
    80003868:	c0a080e7          	jalr	-1014(ra) # 8000446e <log_write>
  brelse(bp);
    8000386c:	854a                	mv	a0,s2
    8000386e:	00000097          	auipc	ra,0x0
    80003872:	97e080e7          	jalr	-1666(ra) # 800031ec <brelse>
}
    80003876:	60e2                	ld	ra,24(sp)
    80003878:	6442                	ld	s0,16(sp)
    8000387a:	64a2                	ld	s1,8(sp)
    8000387c:	6902                	ld	s2,0(sp)
    8000387e:	6105                	addi	sp,sp,32
    80003880:	8082                	ret

0000000080003882 <idup>:
{
    80003882:	1101                	addi	sp,sp,-32
    80003884:	ec06                	sd	ra,24(sp)
    80003886:	e822                	sd	s0,16(sp)
    80003888:	e426                	sd	s1,8(sp)
    8000388a:	1000                	addi	s0,sp,32
    8000388c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000388e:	0001c517          	auipc	a0,0x1c
    80003892:	53a50513          	addi	a0,a0,1338 # 8001fdc8 <itable>
    80003896:	ffffd097          	auipc	ra,0xffffd
    8000389a:	32c080e7          	jalr	812(ra) # 80000bc2 <acquire>
  ip->ref++;
    8000389e:	449c                	lw	a5,8(s1)
    800038a0:	2785                	addiw	a5,a5,1
    800038a2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038a4:	0001c517          	auipc	a0,0x1c
    800038a8:	52450513          	addi	a0,a0,1316 # 8001fdc8 <itable>
    800038ac:	ffffd097          	auipc	ra,0xffffd
    800038b0:	3ca080e7          	jalr	970(ra) # 80000c76 <release>
}
    800038b4:	8526                	mv	a0,s1
    800038b6:	60e2                	ld	ra,24(sp)
    800038b8:	6442                	ld	s0,16(sp)
    800038ba:	64a2                	ld	s1,8(sp)
    800038bc:	6105                	addi	sp,sp,32
    800038be:	8082                	ret

00000000800038c0 <ilock>:
{
    800038c0:	1101                	addi	sp,sp,-32
    800038c2:	ec06                	sd	ra,24(sp)
    800038c4:	e822                	sd	s0,16(sp)
    800038c6:	e426                	sd	s1,8(sp)
    800038c8:	e04a                	sd	s2,0(sp)
    800038ca:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038cc:	c115                	beqz	a0,800038f0 <ilock+0x30>
    800038ce:	84aa                	mv	s1,a0
    800038d0:	451c                	lw	a5,8(a0)
    800038d2:	00f05f63          	blez	a5,800038f0 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038d6:	0541                	addi	a0,a0,16
    800038d8:	00001097          	auipc	ra,0x1
    800038dc:	cb6080e7          	jalr	-842(ra) # 8000458e <acquiresleep>
  if(ip->valid == 0){
    800038e0:	40bc                	lw	a5,64(s1)
    800038e2:	cf99                	beqz	a5,80003900 <ilock+0x40>
}
    800038e4:	60e2                	ld	ra,24(sp)
    800038e6:	6442                	ld	s0,16(sp)
    800038e8:	64a2                	ld	s1,8(sp)
    800038ea:	6902                	ld	s2,0(sp)
    800038ec:	6105                	addi	sp,sp,32
    800038ee:	8082                	ret
    panic("ilock");
    800038f0:	00005517          	auipc	a0,0x5
    800038f4:	eb850513          	addi	a0,a0,-328 # 800087a8 <syscalls+0x198>
    800038f8:	ffffd097          	auipc	ra,0xffffd
    800038fc:	c32080e7          	jalr	-974(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003900:	40dc                	lw	a5,4(s1)
    80003902:	0047d79b          	srliw	a5,a5,0x4
    80003906:	0001c597          	auipc	a1,0x1c
    8000390a:	4ba5a583          	lw	a1,1210(a1) # 8001fdc0 <sb+0x18>
    8000390e:	9dbd                	addw	a1,a1,a5
    80003910:	4088                	lw	a0,0(s1)
    80003912:	fffff097          	auipc	ra,0xfffff
    80003916:	7aa080e7          	jalr	1962(ra) # 800030bc <bread>
    8000391a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000391c:	05850593          	addi	a1,a0,88
    80003920:	40dc                	lw	a5,4(s1)
    80003922:	8bbd                	andi	a5,a5,15
    80003924:	079a                	slli	a5,a5,0x6
    80003926:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003928:	00059783          	lh	a5,0(a1)
    8000392c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003930:	00259783          	lh	a5,2(a1)
    80003934:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003938:	00459783          	lh	a5,4(a1)
    8000393c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003940:	00659783          	lh	a5,6(a1)
    80003944:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003948:	459c                	lw	a5,8(a1)
    8000394a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000394c:	03400613          	li	a2,52
    80003950:	05b1                	addi	a1,a1,12
    80003952:	05048513          	addi	a0,s1,80
    80003956:	ffffd097          	auipc	ra,0xffffd
    8000395a:	3c4080e7          	jalr	964(ra) # 80000d1a <memmove>
    brelse(bp);
    8000395e:	854a                	mv	a0,s2
    80003960:	00000097          	auipc	ra,0x0
    80003964:	88c080e7          	jalr	-1908(ra) # 800031ec <brelse>
    ip->valid = 1;
    80003968:	4785                	li	a5,1
    8000396a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000396c:	04449783          	lh	a5,68(s1)
    80003970:	fbb5                	bnez	a5,800038e4 <ilock+0x24>
      panic("ilock: no type");
    80003972:	00005517          	auipc	a0,0x5
    80003976:	e3e50513          	addi	a0,a0,-450 # 800087b0 <syscalls+0x1a0>
    8000397a:	ffffd097          	auipc	ra,0xffffd
    8000397e:	bb0080e7          	jalr	-1104(ra) # 8000052a <panic>

0000000080003982 <iunlock>:
{
    80003982:	1101                	addi	sp,sp,-32
    80003984:	ec06                	sd	ra,24(sp)
    80003986:	e822                	sd	s0,16(sp)
    80003988:	e426                	sd	s1,8(sp)
    8000398a:	e04a                	sd	s2,0(sp)
    8000398c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000398e:	c905                	beqz	a0,800039be <iunlock+0x3c>
    80003990:	84aa                	mv	s1,a0
    80003992:	01050913          	addi	s2,a0,16
    80003996:	854a                	mv	a0,s2
    80003998:	00001097          	auipc	ra,0x1
    8000399c:	c90080e7          	jalr	-880(ra) # 80004628 <holdingsleep>
    800039a0:	cd19                	beqz	a0,800039be <iunlock+0x3c>
    800039a2:	449c                	lw	a5,8(s1)
    800039a4:	00f05d63          	blez	a5,800039be <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039a8:	854a                	mv	a0,s2
    800039aa:	00001097          	auipc	ra,0x1
    800039ae:	c3a080e7          	jalr	-966(ra) # 800045e4 <releasesleep>
}
    800039b2:	60e2                	ld	ra,24(sp)
    800039b4:	6442                	ld	s0,16(sp)
    800039b6:	64a2                	ld	s1,8(sp)
    800039b8:	6902                	ld	s2,0(sp)
    800039ba:	6105                	addi	sp,sp,32
    800039bc:	8082                	ret
    panic("iunlock");
    800039be:	00005517          	auipc	a0,0x5
    800039c2:	e0250513          	addi	a0,a0,-510 # 800087c0 <syscalls+0x1b0>
    800039c6:	ffffd097          	auipc	ra,0xffffd
    800039ca:	b64080e7          	jalr	-1180(ra) # 8000052a <panic>

00000000800039ce <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039ce:	7179                	addi	sp,sp,-48
    800039d0:	f406                	sd	ra,40(sp)
    800039d2:	f022                	sd	s0,32(sp)
    800039d4:	ec26                	sd	s1,24(sp)
    800039d6:	e84a                	sd	s2,16(sp)
    800039d8:	e44e                	sd	s3,8(sp)
    800039da:	e052                	sd	s4,0(sp)
    800039dc:	1800                	addi	s0,sp,48
    800039de:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039e0:	05050493          	addi	s1,a0,80
    800039e4:	08050913          	addi	s2,a0,128
    800039e8:	a021                	j	800039f0 <itrunc+0x22>
    800039ea:	0491                	addi	s1,s1,4
    800039ec:	01248d63          	beq	s1,s2,80003a06 <itrunc+0x38>
    if(ip->addrs[i]){
    800039f0:	408c                	lw	a1,0(s1)
    800039f2:	dde5                	beqz	a1,800039ea <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039f4:	0009a503          	lw	a0,0(s3)
    800039f8:	00000097          	auipc	ra,0x0
    800039fc:	90a080e7          	jalr	-1782(ra) # 80003302 <bfree>
      ip->addrs[i] = 0;
    80003a00:	0004a023          	sw	zero,0(s1)
    80003a04:	b7dd                	j	800039ea <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a06:	0809a583          	lw	a1,128(s3)
    80003a0a:	e185                	bnez	a1,80003a2a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a0c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a10:	854e                	mv	a0,s3
    80003a12:	00000097          	auipc	ra,0x0
    80003a16:	de4080e7          	jalr	-540(ra) # 800037f6 <iupdate>
}
    80003a1a:	70a2                	ld	ra,40(sp)
    80003a1c:	7402                	ld	s0,32(sp)
    80003a1e:	64e2                	ld	s1,24(sp)
    80003a20:	6942                	ld	s2,16(sp)
    80003a22:	69a2                	ld	s3,8(sp)
    80003a24:	6a02                	ld	s4,0(sp)
    80003a26:	6145                	addi	sp,sp,48
    80003a28:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a2a:	0009a503          	lw	a0,0(s3)
    80003a2e:	fffff097          	auipc	ra,0xfffff
    80003a32:	68e080e7          	jalr	1678(ra) # 800030bc <bread>
    80003a36:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a38:	05850493          	addi	s1,a0,88
    80003a3c:	45850913          	addi	s2,a0,1112
    80003a40:	a021                	j	80003a48 <itrunc+0x7a>
    80003a42:	0491                	addi	s1,s1,4
    80003a44:	01248b63          	beq	s1,s2,80003a5a <itrunc+0x8c>
      if(a[j])
    80003a48:	408c                	lw	a1,0(s1)
    80003a4a:	dde5                	beqz	a1,80003a42 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a4c:	0009a503          	lw	a0,0(s3)
    80003a50:	00000097          	auipc	ra,0x0
    80003a54:	8b2080e7          	jalr	-1870(ra) # 80003302 <bfree>
    80003a58:	b7ed                	j	80003a42 <itrunc+0x74>
    brelse(bp);
    80003a5a:	8552                	mv	a0,s4
    80003a5c:	fffff097          	auipc	ra,0xfffff
    80003a60:	790080e7          	jalr	1936(ra) # 800031ec <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a64:	0809a583          	lw	a1,128(s3)
    80003a68:	0009a503          	lw	a0,0(s3)
    80003a6c:	00000097          	auipc	ra,0x0
    80003a70:	896080e7          	jalr	-1898(ra) # 80003302 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a74:	0809a023          	sw	zero,128(s3)
    80003a78:	bf51                	j	80003a0c <itrunc+0x3e>

0000000080003a7a <iput>:
{
    80003a7a:	1101                	addi	sp,sp,-32
    80003a7c:	ec06                	sd	ra,24(sp)
    80003a7e:	e822                	sd	s0,16(sp)
    80003a80:	e426                	sd	s1,8(sp)
    80003a82:	e04a                	sd	s2,0(sp)
    80003a84:	1000                	addi	s0,sp,32
    80003a86:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a88:	0001c517          	auipc	a0,0x1c
    80003a8c:	34050513          	addi	a0,a0,832 # 8001fdc8 <itable>
    80003a90:	ffffd097          	auipc	ra,0xffffd
    80003a94:	132080e7          	jalr	306(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a98:	4498                	lw	a4,8(s1)
    80003a9a:	4785                	li	a5,1
    80003a9c:	02f70363          	beq	a4,a5,80003ac2 <iput+0x48>
  ip->ref--;
    80003aa0:	449c                	lw	a5,8(s1)
    80003aa2:	37fd                	addiw	a5,a5,-1
    80003aa4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003aa6:	0001c517          	auipc	a0,0x1c
    80003aaa:	32250513          	addi	a0,a0,802 # 8001fdc8 <itable>
    80003aae:	ffffd097          	auipc	ra,0xffffd
    80003ab2:	1c8080e7          	jalr	456(ra) # 80000c76 <release>
}
    80003ab6:	60e2                	ld	ra,24(sp)
    80003ab8:	6442                	ld	s0,16(sp)
    80003aba:	64a2                	ld	s1,8(sp)
    80003abc:	6902                	ld	s2,0(sp)
    80003abe:	6105                	addi	sp,sp,32
    80003ac0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ac2:	40bc                	lw	a5,64(s1)
    80003ac4:	dff1                	beqz	a5,80003aa0 <iput+0x26>
    80003ac6:	04a49783          	lh	a5,74(s1)
    80003aca:	fbf9                	bnez	a5,80003aa0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003acc:	01048913          	addi	s2,s1,16
    80003ad0:	854a                	mv	a0,s2
    80003ad2:	00001097          	auipc	ra,0x1
    80003ad6:	abc080e7          	jalr	-1348(ra) # 8000458e <acquiresleep>
    release(&itable.lock);
    80003ada:	0001c517          	auipc	a0,0x1c
    80003ade:	2ee50513          	addi	a0,a0,750 # 8001fdc8 <itable>
    80003ae2:	ffffd097          	auipc	ra,0xffffd
    80003ae6:	194080e7          	jalr	404(ra) # 80000c76 <release>
    itrunc(ip);
    80003aea:	8526                	mv	a0,s1
    80003aec:	00000097          	auipc	ra,0x0
    80003af0:	ee2080e7          	jalr	-286(ra) # 800039ce <itrunc>
    ip->type = 0;
    80003af4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003af8:	8526                	mv	a0,s1
    80003afa:	00000097          	auipc	ra,0x0
    80003afe:	cfc080e7          	jalr	-772(ra) # 800037f6 <iupdate>
    ip->valid = 0;
    80003b02:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b06:	854a                	mv	a0,s2
    80003b08:	00001097          	auipc	ra,0x1
    80003b0c:	adc080e7          	jalr	-1316(ra) # 800045e4 <releasesleep>
    acquire(&itable.lock);
    80003b10:	0001c517          	auipc	a0,0x1c
    80003b14:	2b850513          	addi	a0,a0,696 # 8001fdc8 <itable>
    80003b18:	ffffd097          	auipc	ra,0xffffd
    80003b1c:	0aa080e7          	jalr	170(ra) # 80000bc2 <acquire>
    80003b20:	b741                	j	80003aa0 <iput+0x26>

0000000080003b22 <iunlockput>:
{
    80003b22:	1101                	addi	sp,sp,-32
    80003b24:	ec06                	sd	ra,24(sp)
    80003b26:	e822                	sd	s0,16(sp)
    80003b28:	e426                	sd	s1,8(sp)
    80003b2a:	1000                	addi	s0,sp,32
    80003b2c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b2e:	00000097          	auipc	ra,0x0
    80003b32:	e54080e7          	jalr	-428(ra) # 80003982 <iunlock>
  iput(ip);
    80003b36:	8526                	mv	a0,s1
    80003b38:	00000097          	auipc	ra,0x0
    80003b3c:	f42080e7          	jalr	-190(ra) # 80003a7a <iput>
}
    80003b40:	60e2                	ld	ra,24(sp)
    80003b42:	6442                	ld	s0,16(sp)
    80003b44:	64a2                	ld	s1,8(sp)
    80003b46:	6105                	addi	sp,sp,32
    80003b48:	8082                	ret

0000000080003b4a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b4a:	1141                	addi	sp,sp,-16
    80003b4c:	e422                	sd	s0,8(sp)
    80003b4e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b50:	411c                	lw	a5,0(a0)
    80003b52:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b54:	415c                	lw	a5,4(a0)
    80003b56:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b58:	04451783          	lh	a5,68(a0)
    80003b5c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b60:	04a51783          	lh	a5,74(a0)
    80003b64:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b68:	04c56783          	lwu	a5,76(a0)
    80003b6c:	e99c                	sd	a5,16(a1)
}
    80003b6e:	6422                	ld	s0,8(sp)
    80003b70:	0141                	addi	sp,sp,16
    80003b72:	8082                	ret

0000000080003b74 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b74:	457c                	lw	a5,76(a0)
    80003b76:	0ed7e963          	bltu	a5,a3,80003c68 <readi+0xf4>
{
    80003b7a:	7159                	addi	sp,sp,-112
    80003b7c:	f486                	sd	ra,104(sp)
    80003b7e:	f0a2                	sd	s0,96(sp)
    80003b80:	eca6                	sd	s1,88(sp)
    80003b82:	e8ca                	sd	s2,80(sp)
    80003b84:	e4ce                	sd	s3,72(sp)
    80003b86:	e0d2                	sd	s4,64(sp)
    80003b88:	fc56                	sd	s5,56(sp)
    80003b8a:	f85a                	sd	s6,48(sp)
    80003b8c:	f45e                	sd	s7,40(sp)
    80003b8e:	f062                	sd	s8,32(sp)
    80003b90:	ec66                	sd	s9,24(sp)
    80003b92:	e86a                	sd	s10,16(sp)
    80003b94:	e46e                	sd	s11,8(sp)
    80003b96:	1880                	addi	s0,sp,112
    80003b98:	8baa                	mv	s7,a0
    80003b9a:	8c2e                	mv	s8,a1
    80003b9c:	8ab2                	mv	s5,a2
    80003b9e:	84b6                	mv	s1,a3
    80003ba0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ba2:	9f35                	addw	a4,a4,a3
    return 0;
    80003ba4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ba6:	0ad76063          	bltu	a4,a3,80003c46 <readi+0xd2>
  if(off + n > ip->size)
    80003baa:	00e7f463          	bgeu	a5,a4,80003bb2 <readi+0x3e>
    n = ip->size - off;
    80003bae:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bb2:	0a0b0963          	beqz	s6,80003c64 <readi+0xf0>
    80003bb6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bb8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bbc:	5cfd                	li	s9,-1
    80003bbe:	a82d                	j	80003bf8 <readi+0x84>
    80003bc0:	020a1d93          	slli	s11,s4,0x20
    80003bc4:	020ddd93          	srli	s11,s11,0x20
    80003bc8:	05890793          	addi	a5,s2,88
    80003bcc:	86ee                	mv	a3,s11
    80003bce:	963e                	add	a2,a2,a5
    80003bd0:	85d6                	mv	a1,s5
    80003bd2:	8562                	mv	a0,s8
    80003bd4:	fffff097          	auipc	ra,0xfffff
    80003bd8:	824080e7          	jalr	-2012(ra) # 800023f8 <either_copyout>
    80003bdc:	05950d63          	beq	a0,s9,80003c36 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003be0:	854a                	mv	a0,s2
    80003be2:	fffff097          	auipc	ra,0xfffff
    80003be6:	60a080e7          	jalr	1546(ra) # 800031ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bea:	013a09bb          	addw	s3,s4,s3
    80003bee:	009a04bb          	addw	s1,s4,s1
    80003bf2:	9aee                	add	s5,s5,s11
    80003bf4:	0569f763          	bgeu	s3,s6,80003c42 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bf8:	000ba903          	lw	s2,0(s7)
    80003bfc:	00a4d59b          	srliw	a1,s1,0xa
    80003c00:	855e                	mv	a0,s7
    80003c02:	00000097          	auipc	ra,0x0
    80003c06:	8ae080e7          	jalr	-1874(ra) # 800034b0 <bmap>
    80003c0a:	0005059b          	sext.w	a1,a0
    80003c0e:	854a                	mv	a0,s2
    80003c10:	fffff097          	auipc	ra,0xfffff
    80003c14:	4ac080e7          	jalr	1196(ra) # 800030bc <bread>
    80003c18:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c1a:	3ff4f613          	andi	a2,s1,1023
    80003c1e:	40cd07bb          	subw	a5,s10,a2
    80003c22:	413b073b          	subw	a4,s6,s3
    80003c26:	8a3e                	mv	s4,a5
    80003c28:	2781                	sext.w	a5,a5
    80003c2a:	0007069b          	sext.w	a3,a4
    80003c2e:	f8f6f9e3          	bgeu	a3,a5,80003bc0 <readi+0x4c>
    80003c32:	8a3a                	mv	s4,a4
    80003c34:	b771                	j	80003bc0 <readi+0x4c>
      brelse(bp);
    80003c36:	854a                	mv	a0,s2
    80003c38:	fffff097          	auipc	ra,0xfffff
    80003c3c:	5b4080e7          	jalr	1460(ra) # 800031ec <brelse>
      tot = -1;
    80003c40:	59fd                	li	s3,-1
  }
  return tot;
    80003c42:	0009851b          	sext.w	a0,s3
}
    80003c46:	70a6                	ld	ra,104(sp)
    80003c48:	7406                	ld	s0,96(sp)
    80003c4a:	64e6                	ld	s1,88(sp)
    80003c4c:	6946                	ld	s2,80(sp)
    80003c4e:	69a6                	ld	s3,72(sp)
    80003c50:	6a06                	ld	s4,64(sp)
    80003c52:	7ae2                	ld	s5,56(sp)
    80003c54:	7b42                	ld	s6,48(sp)
    80003c56:	7ba2                	ld	s7,40(sp)
    80003c58:	7c02                	ld	s8,32(sp)
    80003c5a:	6ce2                	ld	s9,24(sp)
    80003c5c:	6d42                	ld	s10,16(sp)
    80003c5e:	6da2                	ld	s11,8(sp)
    80003c60:	6165                	addi	sp,sp,112
    80003c62:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c64:	89da                	mv	s3,s6
    80003c66:	bff1                	j	80003c42 <readi+0xce>
    return 0;
    80003c68:	4501                	li	a0,0
}
    80003c6a:	8082                	ret

0000000080003c6c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c6c:	457c                	lw	a5,76(a0)
    80003c6e:	10d7e863          	bltu	a5,a3,80003d7e <writei+0x112>
{
    80003c72:	7159                	addi	sp,sp,-112
    80003c74:	f486                	sd	ra,104(sp)
    80003c76:	f0a2                	sd	s0,96(sp)
    80003c78:	eca6                	sd	s1,88(sp)
    80003c7a:	e8ca                	sd	s2,80(sp)
    80003c7c:	e4ce                	sd	s3,72(sp)
    80003c7e:	e0d2                	sd	s4,64(sp)
    80003c80:	fc56                	sd	s5,56(sp)
    80003c82:	f85a                	sd	s6,48(sp)
    80003c84:	f45e                	sd	s7,40(sp)
    80003c86:	f062                	sd	s8,32(sp)
    80003c88:	ec66                	sd	s9,24(sp)
    80003c8a:	e86a                	sd	s10,16(sp)
    80003c8c:	e46e                	sd	s11,8(sp)
    80003c8e:	1880                	addi	s0,sp,112
    80003c90:	8b2a                	mv	s6,a0
    80003c92:	8c2e                	mv	s8,a1
    80003c94:	8ab2                	mv	s5,a2
    80003c96:	8936                	mv	s2,a3
    80003c98:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c9a:	00e687bb          	addw	a5,a3,a4
    80003c9e:	0ed7e263          	bltu	a5,a3,80003d82 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ca2:	00043737          	lui	a4,0x43
    80003ca6:	0ef76063          	bltu	a4,a5,80003d86 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003caa:	0c0b8863          	beqz	s7,80003d7a <writei+0x10e>
    80003cae:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cb0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cb4:	5cfd                	li	s9,-1
    80003cb6:	a091                	j	80003cfa <writei+0x8e>
    80003cb8:	02099d93          	slli	s11,s3,0x20
    80003cbc:	020ddd93          	srli	s11,s11,0x20
    80003cc0:	05848793          	addi	a5,s1,88
    80003cc4:	86ee                	mv	a3,s11
    80003cc6:	8656                	mv	a2,s5
    80003cc8:	85e2                	mv	a1,s8
    80003cca:	953e                	add	a0,a0,a5
    80003ccc:	ffffe097          	auipc	ra,0xffffe
    80003cd0:	782080e7          	jalr	1922(ra) # 8000244e <either_copyin>
    80003cd4:	07950263          	beq	a0,s9,80003d38 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cd8:	8526                	mv	a0,s1
    80003cda:	00000097          	auipc	ra,0x0
    80003cde:	794080e7          	jalr	1940(ra) # 8000446e <log_write>
    brelse(bp);
    80003ce2:	8526                	mv	a0,s1
    80003ce4:	fffff097          	auipc	ra,0xfffff
    80003ce8:	508080e7          	jalr	1288(ra) # 800031ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cec:	01498a3b          	addw	s4,s3,s4
    80003cf0:	0129893b          	addw	s2,s3,s2
    80003cf4:	9aee                	add	s5,s5,s11
    80003cf6:	057a7663          	bgeu	s4,s7,80003d42 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cfa:	000b2483          	lw	s1,0(s6)
    80003cfe:	00a9559b          	srliw	a1,s2,0xa
    80003d02:	855a                	mv	a0,s6
    80003d04:	fffff097          	auipc	ra,0xfffff
    80003d08:	7ac080e7          	jalr	1964(ra) # 800034b0 <bmap>
    80003d0c:	0005059b          	sext.w	a1,a0
    80003d10:	8526                	mv	a0,s1
    80003d12:	fffff097          	auipc	ra,0xfffff
    80003d16:	3aa080e7          	jalr	938(ra) # 800030bc <bread>
    80003d1a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d1c:	3ff97513          	andi	a0,s2,1023
    80003d20:	40ad07bb          	subw	a5,s10,a0
    80003d24:	414b873b          	subw	a4,s7,s4
    80003d28:	89be                	mv	s3,a5
    80003d2a:	2781                	sext.w	a5,a5
    80003d2c:	0007069b          	sext.w	a3,a4
    80003d30:	f8f6f4e3          	bgeu	a3,a5,80003cb8 <writei+0x4c>
    80003d34:	89ba                	mv	s3,a4
    80003d36:	b749                	j	80003cb8 <writei+0x4c>
      brelse(bp);
    80003d38:	8526                	mv	a0,s1
    80003d3a:	fffff097          	auipc	ra,0xfffff
    80003d3e:	4b2080e7          	jalr	1202(ra) # 800031ec <brelse>
  }

  if(off > ip->size)
    80003d42:	04cb2783          	lw	a5,76(s6)
    80003d46:	0127f463          	bgeu	a5,s2,80003d4e <writei+0xe2>
    ip->size = off;
    80003d4a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d4e:	855a                	mv	a0,s6
    80003d50:	00000097          	auipc	ra,0x0
    80003d54:	aa6080e7          	jalr	-1370(ra) # 800037f6 <iupdate>

  return tot;
    80003d58:	000a051b          	sext.w	a0,s4
}
    80003d5c:	70a6                	ld	ra,104(sp)
    80003d5e:	7406                	ld	s0,96(sp)
    80003d60:	64e6                	ld	s1,88(sp)
    80003d62:	6946                	ld	s2,80(sp)
    80003d64:	69a6                	ld	s3,72(sp)
    80003d66:	6a06                	ld	s4,64(sp)
    80003d68:	7ae2                	ld	s5,56(sp)
    80003d6a:	7b42                	ld	s6,48(sp)
    80003d6c:	7ba2                	ld	s7,40(sp)
    80003d6e:	7c02                	ld	s8,32(sp)
    80003d70:	6ce2                	ld	s9,24(sp)
    80003d72:	6d42                	ld	s10,16(sp)
    80003d74:	6da2                	ld	s11,8(sp)
    80003d76:	6165                	addi	sp,sp,112
    80003d78:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d7a:	8a5e                	mv	s4,s7
    80003d7c:	bfc9                	j	80003d4e <writei+0xe2>
    return -1;
    80003d7e:	557d                	li	a0,-1
}
    80003d80:	8082                	ret
    return -1;
    80003d82:	557d                	li	a0,-1
    80003d84:	bfe1                	j	80003d5c <writei+0xf0>
    return -1;
    80003d86:	557d                	li	a0,-1
    80003d88:	bfd1                	j	80003d5c <writei+0xf0>

0000000080003d8a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d8a:	1141                	addi	sp,sp,-16
    80003d8c:	e406                	sd	ra,8(sp)
    80003d8e:	e022                	sd	s0,0(sp)
    80003d90:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d92:	4639                	li	a2,14
    80003d94:	ffffd097          	auipc	ra,0xffffd
    80003d98:	002080e7          	jalr	2(ra) # 80000d96 <strncmp>
}
    80003d9c:	60a2                	ld	ra,8(sp)
    80003d9e:	6402                	ld	s0,0(sp)
    80003da0:	0141                	addi	sp,sp,16
    80003da2:	8082                	ret

0000000080003da4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003da4:	7139                	addi	sp,sp,-64
    80003da6:	fc06                	sd	ra,56(sp)
    80003da8:	f822                	sd	s0,48(sp)
    80003daa:	f426                	sd	s1,40(sp)
    80003dac:	f04a                	sd	s2,32(sp)
    80003dae:	ec4e                	sd	s3,24(sp)
    80003db0:	e852                	sd	s4,16(sp)
    80003db2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003db4:	04451703          	lh	a4,68(a0)
    80003db8:	4785                	li	a5,1
    80003dba:	00f71a63          	bne	a4,a5,80003dce <dirlookup+0x2a>
    80003dbe:	892a                	mv	s2,a0
    80003dc0:	89ae                	mv	s3,a1
    80003dc2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dc4:	457c                	lw	a5,76(a0)
    80003dc6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dc8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dca:	e79d                	bnez	a5,80003df8 <dirlookup+0x54>
    80003dcc:	a8a5                	j	80003e44 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dce:	00005517          	auipc	a0,0x5
    80003dd2:	9fa50513          	addi	a0,a0,-1542 # 800087c8 <syscalls+0x1b8>
    80003dd6:	ffffc097          	auipc	ra,0xffffc
    80003dda:	754080e7          	jalr	1876(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003dde:	00005517          	auipc	a0,0x5
    80003de2:	a0250513          	addi	a0,a0,-1534 # 800087e0 <syscalls+0x1d0>
    80003de6:	ffffc097          	auipc	ra,0xffffc
    80003dea:	744080e7          	jalr	1860(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dee:	24c1                	addiw	s1,s1,16
    80003df0:	04c92783          	lw	a5,76(s2)
    80003df4:	04f4f763          	bgeu	s1,a5,80003e42 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003df8:	4741                	li	a4,16
    80003dfa:	86a6                	mv	a3,s1
    80003dfc:	fc040613          	addi	a2,s0,-64
    80003e00:	4581                	li	a1,0
    80003e02:	854a                	mv	a0,s2
    80003e04:	00000097          	auipc	ra,0x0
    80003e08:	d70080e7          	jalr	-656(ra) # 80003b74 <readi>
    80003e0c:	47c1                	li	a5,16
    80003e0e:	fcf518e3          	bne	a0,a5,80003dde <dirlookup+0x3a>
    if(de.inum == 0)
    80003e12:	fc045783          	lhu	a5,-64(s0)
    80003e16:	dfe1                	beqz	a5,80003dee <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e18:	fc240593          	addi	a1,s0,-62
    80003e1c:	854e                	mv	a0,s3
    80003e1e:	00000097          	auipc	ra,0x0
    80003e22:	f6c080e7          	jalr	-148(ra) # 80003d8a <namecmp>
    80003e26:	f561                	bnez	a0,80003dee <dirlookup+0x4a>
      if(poff)
    80003e28:	000a0463          	beqz	s4,80003e30 <dirlookup+0x8c>
        *poff = off;
    80003e2c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e30:	fc045583          	lhu	a1,-64(s0)
    80003e34:	00092503          	lw	a0,0(s2)
    80003e38:	fffff097          	auipc	ra,0xfffff
    80003e3c:	754080e7          	jalr	1876(ra) # 8000358c <iget>
    80003e40:	a011                	j	80003e44 <dirlookup+0xa0>
  return 0;
    80003e42:	4501                	li	a0,0
}
    80003e44:	70e2                	ld	ra,56(sp)
    80003e46:	7442                	ld	s0,48(sp)
    80003e48:	74a2                	ld	s1,40(sp)
    80003e4a:	7902                	ld	s2,32(sp)
    80003e4c:	69e2                	ld	s3,24(sp)
    80003e4e:	6a42                	ld	s4,16(sp)
    80003e50:	6121                	addi	sp,sp,64
    80003e52:	8082                	ret

0000000080003e54 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e54:	711d                	addi	sp,sp,-96
    80003e56:	ec86                	sd	ra,88(sp)
    80003e58:	e8a2                	sd	s0,80(sp)
    80003e5a:	e4a6                	sd	s1,72(sp)
    80003e5c:	e0ca                	sd	s2,64(sp)
    80003e5e:	fc4e                	sd	s3,56(sp)
    80003e60:	f852                	sd	s4,48(sp)
    80003e62:	f456                	sd	s5,40(sp)
    80003e64:	f05a                	sd	s6,32(sp)
    80003e66:	ec5e                	sd	s7,24(sp)
    80003e68:	e862                	sd	s8,16(sp)
    80003e6a:	e466                	sd	s9,8(sp)
    80003e6c:	1080                	addi	s0,sp,96
    80003e6e:	84aa                	mv	s1,a0
    80003e70:	8aae                	mv	s5,a1
    80003e72:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e74:	00054703          	lbu	a4,0(a0)
    80003e78:	02f00793          	li	a5,47
    80003e7c:	02f70363          	beq	a4,a5,80003ea2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e80:	ffffe097          	auipc	ra,0xffffe
    80003e84:	afe080e7          	jalr	-1282(ra) # 8000197e <myproc>
    80003e88:	16853503          	ld	a0,360(a0)
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	9f6080e7          	jalr	-1546(ra) # 80003882 <idup>
    80003e94:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e96:	02f00913          	li	s2,47
  len = path - s;
    80003e9a:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003e9c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e9e:	4b85                	li	s7,1
    80003ea0:	a865                	j	80003f58 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ea2:	4585                	li	a1,1
    80003ea4:	4505                	li	a0,1
    80003ea6:	fffff097          	auipc	ra,0xfffff
    80003eaa:	6e6080e7          	jalr	1766(ra) # 8000358c <iget>
    80003eae:	89aa                	mv	s3,a0
    80003eb0:	b7dd                	j	80003e96 <namex+0x42>
      iunlockput(ip);
    80003eb2:	854e                	mv	a0,s3
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	c6e080e7          	jalr	-914(ra) # 80003b22 <iunlockput>
      return 0;
    80003ebc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ebe:	854e                	mv	a0,s3
    80003ec0:	60e6                	ld	ra,88(sp)
    80003ec2:	6446                	ld	s0,80(sp)
    80003ec4:	64a6                	ld	s1,72(sp)
    80003ec6:	6906                	ld	s2,64(sp)
    80003ec8:	79e2                	ld	s3,56(sp)
    80003eca:	7a42                	ld	s4,48(sp)
    80003ecc:	7aa2                	ld	s5,40(sp)
    80003ece:	7b02                	ld	s6,32(sp)
    80003ed0:	6be2                	ld	s7,24(sp)
    80003ed2:	6c42                	ld	s8,16(sp)
    80003ed4:	6ca2                	ld	s9,8(sp)
    80003ed6:	6125                	addi	sp,sp,96
    80003ed8:	8082                	ret
      iunlock(ip);
    80003eda:	854e                	mv	a0,s3
    80003edc:	00000097          	auipc	ra,0x0
    80003ee0:	aa6080e7          	jalr	-1370(ra) # 80003982 <iunlock>
      return ip;
    80003ee4:	bfe9                	j	80003ebe <namex+0x6a>
      iunlockput(ip);
    80003ee6:	854e                	mv	a0,s3
    80003ee8:	00000097          	auipc	ra,0x0
    80003eec:	c3a080e7          	jalr	-966(ra) # 80003b22 <iunlockput>
      return 0;
    80003ef0:	89e6                	mv	s3,s9
    80003ef2:	b7f1                	j	80003ebe <namex+0x6a>
  len = path - s;
    80003ef4:	40b48633          	sub	a2,s1,a1
    80003ef8:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003efc:	099c5463          	bge	s8,s9,80003f84 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f00:	4639                	li	a2,14
    80003f02:	8552                	mv	a0,s4
    80003f04:	ffffd097          	auipc	ra,0xffffd
    80003f08:	e16080e7          	jalr	-490(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003f0c:	0004c783          	lbu	a5,0(s1)
    80003f10:	01279763          	bne	a5,s2,80003f1e <namex+0xca>
    path++;
    80003f14:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f16:	0004c783          	lbu	a5,0(s1)
    80003f1a:	ff278de3          	beq	a5,s2,80003f14 <namex+0xc0>
    ilock(ip);
    80003f1e:	854e                	mv	a0,s3
    80003f20:	00000097          	auipc	ra,0x0
    80003f24:	9a0080e7          	jalr	-1632(ra) # 800038c0 <ilock>
    if(ip->type != T_DIR){
    80003f28:	04499783          	lh	a5,68(s3)
    80003f2c:	f97793e3          	bne	a5,s7,80003eb2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f30:	000a8563          	beqz	s5,80003f3a <namex+0xe6>
    80003f34:	0004c783          	lbu	a5,0(s1)
    80003f38:	d3cd                	beqz	a5,80003eda <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f3a:	865a                	mv	a2,s6
    80003f3c:	85d2                	mv	a1,s4
    80003f3e:	854e                	mv	a0,s3
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	e64080e7          	jalr	-412(ra) # 80003da4 <dirlookup>
    80003f48:	8caa                	mv	s9,a0
    80003f4a:	dd51                	beqz	a0,80003ee6 <namex+0x92>
    iunlockput(ip);
    80003f4c:	854e                	mv	a0,s3
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	bd4080e7          	jalr	-1068(ra) # 80003b22 <iunlockput>
    ip = next;
    80003f56:	89e6                	mv	s3,s9
  while(*path == '/')
    80003f58:	0004c783          	lbu	a5,0(s1)
    80003f5c:	05279763          	bne	a5,s2,80003faa <namex+0x156>
    path++;
    80003f60:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f62:	0004c783          	lbu	a5,0(s1)
    80003f66:	ff278de3          	beq	a5,s2,80003f60 <namex+0x10c>
  if(*path == 0)
    80003f6a:	c79d                	beqz	a5,80003f98 <namex+0x144>
    path++;
    80003f6c:	85a6                	mv	a1,s1
  len = path - s;
    80003f6e:	8cda                	mv	s9,s6
    80003f70:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003f72:	01278963          	beq	a5,s2,80003f84 <namex+0x130>
    80003f76:	dfbd                	beqz	a5,80003ef4 <namex+0xa0>
    path++;
    80003f78:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f7a:	0004c783          	lbu	a5,0(s1)
    80003f7e:	ff279ce3          	bne	a5,s2,80003f76 <namex+0x122>
    80003f82:	bf8d                	j	80003ef4 <namex+0xa0>
    memmove(name, s, len);
    80003f84:	2601                	sext.w	a2,a2
    80003f86:	8552                	mv	a0,s4
    80003f88:	ffffd097          	auipc	ra,0xffffd
    80003f8c:	d92080e7          	jalr	-622(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003f90:	9cd2                	add	s9,s9,s4
    80003f92:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003f96:	bf9d                	j	80003f0c <namex+0xb8>
  if(nameiparent){
    80003f98:	f20a83e3          	beqz	s5,80003ebe <namex+0x6a>
    iput(ip);
    80003f9c:	854e                	mv	a0,s3
    80003f9e:	00000097          	auipc	ra,0x0
    80003fa2:	adc080e7          	jalr	-1316(ra) # 80003a7a <iput>
    return 0;
    80003fa6:	4981                	li	s3,0
    80003fa8:	bf19                	j	80003ebe <namex+0x6a>
  if(*path == 0)
    80003faa:	d7fd                	beqz	a5,80003f98 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fac:	0004c783          	lbu	a5,0(s1)
    80003fb0:	85a6                	mv	a1,s1
    80003fb2:	b7d1                	j	80003f76 <namex+0x122>

0000000080003fb4 <dirlink>:
{
    80003fb4:	7139                	addi	sp,sp,-64
    80003fb6:	fc06                	sd	ra,56(sp)
    80003fb8:	f822                	sd	s0,48(sp)
    80003fba:	f426                	sd	s1,40(sp)
    80003fbc:	f04a                	sd	s2,32(sp)
    80003fbe:	ec4e                	sd	s3,24(sp)
    80003fc0:	e852                	sd	s4,16(sp)
    80003fc2:	0080                	addi	s0,sp,64
    80003fc4:	892a                	mv	s2,a0
    80003fc6:	8a2e                	mv	s4,a1
    80003fc8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fca:	4601                	li	a2,0
    80003fcc:	00000097          	auipc	ra,0x0
    80003fd0:	dd8080e7          	jalr	-552(ra) # 80003da4 <dirlookup>
    80003fd4:	e93d                	bnez	a0,8000404a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fd6:	04c92483          	lw	s1,76(s2)
    80003fda:	c49d                	beqz	s1,80004008 <dirlink+0x54>
    80003fdc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fde:	4741                	li	a4,16
    80003fe0:	86a6                	mv	a3,s1
    80003fe2:	fc040613          	addi	a2,s0,-64
    80003fe6:	4581                	li	a1,0
    80003fe8:	854a                	mv	a0,s2
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	b8a080e7          	jalr	-1142(ra) # 80003b74 <readi>
    80003ff2:	47c1                	li	a5,16
    80003ff4:	06f51163          	bne	a0,a5,80004056 <dirlink+0xa2>
    if(de.inum == 0)
    80003ff8:	fc045783          	lhu	a5,-64(s0)
    80003ffc:	c791                	beqz	a5,80004008 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ffe:	24c1                	addiw	s1,s1,16
    80004000:	04c92783          	lw	a5,76(s2)
    80004004:	fcf4ede3          	bltu	s1,a5,80003fde <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004008:	4639                	li	a2,14
    8000400a:	85d2                	mv	a1,s4
    8000400c:	fc240513          	addi	a0,s0,-62
    80004010:	ffffd097          	auipc	ra,0xffffd
    80004014:	dc2080e7          	jalr	-574(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004018:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000401c:	4741                	li	a4,16
    8000401e:	86a6                	mv	a3,s1
    80004020:	fc040613          	addi	a2,s0,-64
    80004024:	4581                	li	a1,0
    80004026:	854a                	mv	a0,s2
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	c44080e7          	jalr	-956(ra) # 80003c6c <writei>
    80004030:	872a                	mv	a4,a0
    80004032:	47c1                	li	a5,16
  return 0;
    80004034:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004036:	02f71863          	bne	a4,a5,80004066 <dirlink+0xb2>
}
    8000403a:	70e2                	ld	ra,56(sp)
    8000403c:	7442                	ld	s0,48(sp)
    8000403e:	74a2                	ld	s1,40(sp)
    80004040:	7902                	ld	s2,32(sp)
    80004042:	69e2                	ld	s3,24(sp)
    80004044:	6a42                	ld	s4,16(sp)
    80004046:	6121                	addi	sp,sp,64
    80004048:	8082                	ret
    iput(ip);
    8000404a:	00000097          	auipc	ra,0x0
    8000404e:	a30080e7          	jalr	-1488(ra) # 80003a7a <iput>
    return -1;
    80004052:	557d                	li	a0,-1
    80004054:	b7dd                	j	8000403a <dirlink+0x86>
      panic("dirlink read");
    80004056:	00004517          	auipc	a0,0x4
    8000405a:	79a50513          	addi	a0,a0,1946 # 800087f0 <syscalls+0x1e0>
    8000405e:	ffffc097          	auipc	ra,0xffffc
    80004062:	4cc080e7          	jalr	1228(ra) # 8000052a <panic>
    panic("dirlink");
    80004066:	00005517          	auipc	a0,0x5
    8000406a:	89250513          	addi	a0,a0,-1902 # 800088f8 <syscalls+0x2e8>
    8000406e:	ffffc097          	auipc	ra,0xffffc
    80004072:	4bc080e7          	jalr	1212(ra) # 8000052a <panic>

0000000080004076 <namei>:

struct inode*
namei(char *path)
{
    80004076:	1101                	addi	sp,sp,-32
    80004078:	ec06                	sd	ra,24(sp)
    8000407a:	e822                	sd	s0,16(sp)
    8000407c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000407e:	fe040613          	addi	a2,s0,-32
    80004082:	4581                	li	a1,0
    80004084:	00000097          	auipc	ra,0x0
    80004088:	dd0080e7          	jalr	-560(ra) # 80003e54 <namex>
}
    8000408c:	60e2                	ld	ra,24(sp)
    8000408e:	6442                	ld	s0,16(sp)
    80004090:	6105                	addi	sp,sp,32
    80004092:	8082                	ret

0000000080004094 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004094:	1141                	addi	sp,sp,-16
    80004096:	e406                	sd	ra,8(sp)
    80004098:	e022                	sd	s0,0(sp)
    8000409a:	0800                	addi	s0,sp,16
    8000409c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000409e:	4585                	li	a1,1
    800040a0:	00000097          	auipc	ra,0x0
    800040a4:	db4080e7          	jalr	-588(ra) # 80003e54 <namex>
}
    800040a8:	60a2                	ld	ra,8(sp)
    800040aa:	6402                	ld	s0,0(sp)
    800040ac:	0141                	addi	sp,sp,16
    800040ae:	8082                	ret

00000000800040b0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040b0:	1101                	addi	sp,sp,-32
    800040b2:	ec06                	sd	ra,24(sp)
    800040b4:	e822                	sd	s0,16(sp)
    800040b6:	e426                	sd	s1,8(sp)
    800040b8:	e04a                	sd	s2,0(sp)
    800040ba:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040bc:	0001d917          	auipc	s2,0x1d
    800040c0:	7b490913          	addi	s2,s2,1972 # 80021870 <log>
    800040c4:	01892583          	lw	a1,24(s2)
    800040c8:	02892503          	lw	a0,40(s2)
    800040cc:	fffff097          	auipc	ra,0xfffff
    800040d0:	ff0080e7          	jalr	-16(ra) # 800030bc <bread>
    800040d4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040d6:	02c92683          	lw	a3,44(s2)
    800040da:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040dc:	02d05863          	blez	a3,8000410c <write_head+0x5c>
    800040e0:	0001d797          	auipc	a5,0x1d
    800040e4:	7c078793          	addi	a5,a5,1984 # 800218a0 <log+0x30>
    800040e8:	05c50713          	addi	a4,a0,92
    800040ec:	36fd                	addiw	a3,a3,-1
    800040ee:	02069613          	slli	a2,a3,0x20
    800040f2:	01e65693          	srli	a3,a2,0x1e
    800040f6:	0001d617          	auipc	a2,0x1d
    800040fa:	7ae60613          	addi	a2,a2,1966 # 800218a4 <log+0x34>
    800040fe:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004100:	4390                	lw	a2,0(a5)
    80004102:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004104:	0791                	addi	a5,a5,4
    80004106:	0711                	addi	a4,a4,4
    80004108:	fed79ce3          	bne	a5,a3,80004100 <write_head+0x50>
  }
  bwrite(buf);
    8000410c:	8526                	mv	a0,s1
    8000410e:	fffff097          	auipc	ra,0xfffff
    80004112:	0a0080e7          	jalr	160(ra) # 800031ae <bwrite>
  brelse(buf);
    80004116:	8526                	mv	a0,s1
    80004118:	fffff097          	auipc	ra,0xfffff
    8000411c:	0d4080e7          	jalr	212(ra) # 800031ec <brelse>
}
    80004120:	60e2                	ld	ra,24(sp)
    80004122:	6442                	ld	s0,16(sp)
    80004124:	64a2                	ld	s1,8(sp)
    80004126:	6902                	ld	s2,0(sp)
    80004128:	6105                	addi	sp,sp,32
    8000412a:	8082                	ret

000000008000412c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000412c:	0001d797          	auipc	a5,0x1d
    80004130:	7707a783          	lw	a5,1904(a5) # 8002189c <log+0x2c>
    80004134:	0af05d63          	blez	a5,800041ee <install_trans+0xc2>
{
    80004138:	7139                	addi	sp,sp,-64
    8000413a:	fc06                	sd	ra,56(sp)
    8000413c:	f822                	sd	s0,48(sp)
    8000413e:	f426                	sd	s1,40(sp)
    80004140:	f04a                	sd	s2,32(sp)
    80004142:	ec4e                	sd	s3,24(sp)
    80004144:	e852                	sd	s4,16(sp)
    80004146:	e456                	sd	s5,8(sp)
    80004148:	e05a                	sd	s6,0(sp)
    8000414a:	0080                	addi	s0,sp,64
    8000414c:	8b2a                	mv	s6,a0
    8000414e:	0001da97          	auipc	s5,0x1d
    80004152:	752a8a93          	addi	s5,s5,1874 # 800218a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004156:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004158:	0001d997          	auipc	s3,0x1d
    8000415c:	71898993          	addi	s3,s3,1816 # 80021870 <log>
    80004160:	a00d                	j	80004182 <install_trans+0x56>
    brelse(lbuf);
    80004162:	854a                	mv	a0,s2
    80004164:	fffff097          	auipc	ra,0xfffff
    80004168:	088080e7          	jalr	136(ra) # 800031ec <brelse>
    brelse(dbuf);
    8000416c:	8526                	mv	a0,s1
    8000416e:	fffff097          	auipc	ra,0xfffff
    80004172:	07e080e7          	jalr	126(ra) # 800031ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004176:	2a05                	addiw	s4,s4,1
    80004178:	0a91                	addi	s5,s5,4
    8000417a:	02c9a783          	lw	a5,44(s3)
    8000417e:	04fa5e63          	bge	s4,a5,800041da <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004182:	0189a583          	lw	a1,24(s3)
    80004186:	014585bb          	addw	a1,a1,s4
    8000418a:	2585                	addiw	a1,a1,1
    8000418c:	0289a503          	lw	a0,40(s3)
    80004190:	fffff097          	auipc	ra,0xfffff
    80004194:	f2c080e7          	jalr	-212(ra) # 800030bc <bread>
    80004198:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000419a:	000aa583          	lw	a1,0(s5)
    8000419e:	0289a503          	lw	a0,40(s3)
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	f1a080e7          	jalr	-230(ra) # 800030bc <bread>
    800041aa:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041ac:	40000613          	li	a2,1024
    800041b0:	05890593          	addi	a1,s2,88
    800041b4:	05850513          	addi	a0,a0,88
    800041b8:	ffffd097          	auipc	ra,0xffffd
    800041bc:	b62080e7          	jalr	-1182(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    800041c0:	8526                	mv	a0,s1
    800041c2:	fffff097          	auipc	ra,0xfffff
    800041c6:	fec080e7          	jalr	-20(ra) # 800031ae <bwrite>
    if(recovering == 0)
    800041ca:	f80b1ce3          	bnez	s6,80004162 <install_trans+0x36>
      bunpin(dbuf);
    800041ce:	8526                	mv	a0,s1
    800041d0:	fffff097          	auipc	ra,0xfffff
    800041d4:	0f6080e7          	jalr	246(ra) # 800032c6 <bunpin>
    800041d8:	b769                	j	80004162 <install_trans+0x36>
}
    800041da:	70e2                	ld	ra,56(sp)
    800041dc:	7442                	ld	s0,48(sp)
    800041de:	74a2                	ld	s1,40(sp)
    800041e0:	7902                	ld	s2,32(sp)
    800041e2:	69e2                	ld	s3,24(sp)
    800041e4:	6a42                	ld	s4,16(sp)
    800041e6:	6aa2                	ld	s5,8(sp)
    800041e8:	6b02                	ld	s6,0(sp)
    800041ea:	6121                	addi	sp,sp,64
    800041ec:	8082                	ret
    800041ee:	8082                	ret

00000000800041f0 <initlog>:
{
    800041f0:	7179                	addi	sp,sp,-48
    800041f2:	f406                	sd	ra,40(sp)
    800041f4:	f022                	sd	s0,32(sp)
    800041f6:	ec26                	sd	s1,24(sp)
    800041f8:	e84a                	sd	s2,16(sp)
    800041fa:	e44e                	sd	s3,8(sp)
    800041fc:	1800                	addi	s0,sp,48
    800041fe:	892a                	mv	s2,a0
    80004200:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004202:	0001d497          	auipc	s1,0x1d
    80004206:	66e48493          	addi	s1,s1,1646 # 80021870 <log>
    8000420a:	00004597          	auipc	a1,0x4
    8000420e:	5f658593          	addi	a1,a1,1526 # 80008800 <syscalls+0x1f0>
    80004212:	8526                	mv	a0,s1
    80004214:	ffffd097          	auipc	ra,0xffffd
    80004218:	91e080e7          	jalr	-1762(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    8000421c:	0149a583          	lw	a1,20(s3)
    80004220:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004222:	0109a783          	lw	a5,16(s3)
    80004226:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004228:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000422c:	854a                	mv	a0,s2
    8000422e:	fffff097          	auipc	ra,0xfffff
    80004232:	e8e080e7          	jalr	-370(ra) # 800030bc <bread>
  log.lh.n = lh->n;
    80004236:	4d34                	lw	a3,88(a0)
    80004238:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000423a:	02d05663          	blez	a3,80004266 <initlog+0x76>
    8000423e:	05c50793          	addi	a5,a0,92
    80004242:	0001d717          	auipc	a4,0x1d
    80004246:	65e70713          	addi	a4,a4,1630 # 800218a0 <log+0x30>
    8000424a:	36fd                	addiw	a3,a3,-1
    8000424c:	02069613          	slli	a2,a3,0x20
    80004250:	01e65693          	srli	a3,a2,0x1e
    80004254:	06050613          	addi	a2,a0,96
    80004258:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000425a:	4390                	lw	a2,0(a5)
    8000425c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000425e:	0791                	addi	a5,a5,4
    80004260:	0711                	addi	a4,a4,4
    80004262:	fed79ce3          	bne	a5,a3,8000425a <initlog+0x6a>
  brelse(buf);
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	f86080e7          	jalr	-122(ra) # 800031ec <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000426e:	4505                	li	a0,1
    80004270:	00000097          	auipc	ra,0x0
    80004274:	ebc080e7          	jalr	-324(ra) # 8000412c <install_trans>
  log.lh.n = 0;
    80004278:	0001d797          	auipc	a5,0x1d
    8000427c:	6207a223          	sw	zero,1572(a5) # 8002189c <log+0x2c>
  write_head(); // clear the log
    80004280:	00000097          	auipc	ra,0x0
    80004284:	e30080e7          	jalr	-464(ra) # 800040b0 <write_head>
}
    80004288:	70a2                	ld	ra,40(sp)
    8000428a:	7402                	ld	s0,32(sp)
    8000428c:	64e2                	ld	s1,24(sp)
    8000428e:	6942                	ld	s2,16(sp)
    80004290:	69a2                	ld	s3,8(sp)
    80004292:	6145                	addi	sp,sp,48
    80004294:	8082                	ret

0000000080004296 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004296:	1101                	addi	sp,sp,-32
    80004298:	ec06                	sd	ra,24(sp)
    8000429a:	e822                	sd	s0,16(sp)
    8000429c:	e426                	sd	s1,8(sp)
    8000429e:	e04a                	sd	s2,0(sp)
    800042a0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042a2:	0001d517          	auipc	a0,0x1d
    800042a6:	5ce50513          	addi	a0,a0,1486 # 80021870 <log>
    800042aa:	ffffd097          	auipc	ra,0xffffd
    800042ae:	918080e7          	jalr	-1768(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800042b2:	0001d497          	auipc	s1,0x1d
    800042b6:	5be48493          	addi	s1,s1,1470 # 80021870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042ba:	4979                	li	s2,30
    800042bc:	a039                	j	800042ca <begin_op+0x34>
      sleep(&log, &log.lock);
    800042be:	85a6                	mv	a1,s1
    800042c0:	8526                	mv	a0,s1
    800042c2:	ffffe097          	auipc	ra,0xffffe
    800042c6:	d92080e7          	jalr	-622(ra) # 80002054 <sleep>
    if(log.committing){
    800042ca:	50dc                	lw	a5,36(s1)
    800042cc:	fbed                	bnez	a5,800042be <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042ce:	509c                	lw	a5,32(s1)
    800042d0:	0017871b          	addiw	a4,a5,1
    800042d4:	0007069b          	sext.w	a3,a4
    800042d8:	0027179b          	slliw	a5,a4,0x2
    800042dc:	9fb9                	addw	a5,a5,a4
    800042de:	0017979b          	slliw	a5,a5,0x1
    800042e2:	54d8                	lw	a4,44(s1)
    800042e4:	9fb9                	addw	a5,a5,a4
    800042e6:	00f95963          	bge	s2,a5,800042f8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042ea:	85a6                	mv	a1,s1
    800042ec:	8526                	mv	a0,s1
    800042ee:	ffffe097          	auipc	ra,0xffffe
    800042f2:	d66080e7          	jalr	-666(ra) # 80002054 <sleep>
    800042f6:	bfd1                	j	800042ca <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042f8:	0001d517          	auipc	a0,0x1d
    800042fc:	57850513          	addi	a0,a0,1400 # 80021870 <log>
    80004300:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004302:	ffffd097          	auipc	ra,0xffffd
    80004306:	974080e7          	jalr	-1676(ra) # 80000c76 <release>
      break;
    }
  }
}
    8000430a:	60e2                	ld	ra,24(sp)
    8000430c:	6442                	ld	s0,16(sp)
    8000430e:	64a2                	ld	s1,8(sp)
    80004310:	6902                	ld	s2,0(sp)
    80004312:	6105                	addi	sp,sp,32
    80004314:	8082                	ret

0000000080004316 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004316:	7139                	addi	sp,sp,-64
    80004318:	fc06                	sd	ra,56(sp)
    8000431a:	f822                	sd	s0,48(sp)
    8000431c:	f426                	sd	s1,40(sp)
    8000431e:	f04a                	sd	s2,32(sp)
    80004320:	ec4e                	sd	s3,24(sp)
    80004322:	e852                	sd	s4,16(sp)
    80004324:	e456                	sd	s5,8(sp)
    80004326:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004328:	0001d497          	auipc	s1,0x1d
    8000432c:	54848493          	addi	s1,s1,1352 # 80021870 <log>
    80004330:	8526                	mv	a0,s1
    80004332:	ffffd097          	auipc	ra,0xffffd
    80004336:	890080e7          	jalr	-1904(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    8000433a:	509c                	lw	a5,32(s1)
    8000433c:	37fd                	addiw	a5,a5,-1
    8000433e:	0007891b          	sext.w	s2,a5
    80004342:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004344:	50dc                	lw	a5,36(s1)
    80004346:	e7b9                	bnez	a5,80004394 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004348:	04091e63          	bnez	s2,800043a4 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000434c:	0001d497          	auipc	s1,0x1d
    80004350:	52448493          	addi	s1,s1,1316 # 80021870 <log>
    80004354:	4785                	li	a5,1
    80004356:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004358:	8526                	mv	a0,s1
    8000435a:	ffffd097          	auipc	ra,0xffffd
    8000435e:	91c080e7          	jalr	-1764(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004362:	54dc                	lw	a5,44(s1)
    80004364:	06f04763          	bgtz	a5,800043d2 <end_op+0xbc>
    acquire(&log.lock);
    80004368:	0001d497          	auipc	s1,0x1d
    8000436c:	50848493          	addi	s1,s1,1288 # 80021870 <log>
    80004370:	8526                	mv	a0,s1
    80004372:	ffffd097          	auipc	ra,0xffffd
    80004376:	850080e7          	jalr	-1968(ra) # 80000bc2 <acquire>
    log.committing = 0;
    8000437a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000437e:	8526                	mv	a0,s1
    80004380:	ffffe097          	auipc	ra,0xffffe
    80004384:	e60080e7          	jalr	-416(ra) # 800021e0 <wakeup>
    release(&log.lock);
    80004388:	8526                	mv	a0,s1
    8000438a:	ffffd097          	auipc	ra,0xffffd
    8000438e:	8ec080e7          	jalr	-1812(ra) # 80000c76 <release>
}
    80004392:	a03d                	j	800043c0 <end_op+0xaa>
    panic("log.committing");
    80004394:	00004517          	auipc	a0,0x4
    80004398:	47450513          	addi	a0,a0,1140 # 80008808 <syscalls+0x1f8>
    8000439c:	ffffc097          	auipc	ra,0xffffc
    800043a0:	18e080e7          	jalr	398(ra) # 8000052a <panic>
    wakeup(&log);
    800043a4:	0001d497          	auipc	s1,0x1d
    800043a8:	4cc48493          	addi	s1,s1,1228 # 80021870 <log>
    800043ac:	8526                	mv	a0,s1
    800043ae:	ffffe097          	auipc	ra,0xffffe
    800043b2:	e32080e7          	jalr	-462(ra) # 800021e0 <wakeup>
  release(&log.lock);
    800043b6:	8526                	mv	a0,s1
    800043b8:	ffffd097          	auipc	ra,0xffffd
    800043bc:	8be080e7          	jalr	-1858(ra) # 80000c76 <release>
}
    800043c0:	70e2                	ld	ra,56(sp)
    800043c2:	7442                	ld	s0,48(sp)
    800043c4:	74a2                	ld	s1,40(sp)
    800043c6:	7902                	ld	s2,32(sp)
    800043c8:	69e2                	ld	s3,24(sp)
    800043ca:	6a42                	ld	s4,16(sp)
    800043cc:	6aa2                	ld	s5,8(sp)
    800043ce:	6121                	addi	sp,sp,64
    800043d0:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800043d2:	0001da97          	auipc	s5,0x1d
    800043d6:	4cea8a93          	addi	s5,s5,1230 # 800218a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043da:	0001da17          	auipc	s4,0x1d
    800043de:	496a0a13          	addi	s4,s4,1174 # 80021870 <log>
    800043e2:	018a2583          	lw	a1,24(s4)
    800043e6:	012585bb          	addw	a1,a1,s2
    800043ea:	2585                	addiw	a1,a1,1
    800043ec:	028a2503          	lw	a0,40(s4)
    800043f0:	fffff097          	auipc	ra,0xfffff
    800043f4:	ccc080e7          	jalr	-820(ra) # 800030bc <bread>
    800043f8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043fa:	000aa583          	lw	a1,0(s5)
    800043fe:	028a2503          	lw	a0,40(s4)
    80004402:	fffff097          	auipc	ra,0xfffff
    80004406:	cba080e7          	jalr	-838(ra) # 800030bc <bread>
    8000440a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000440c:	40000613          	li	a2,1024
    80004410:	05850593          	addi	a1,a0,88
    80004414:	05848513          	addi	a0,s1,88
    80004418:	ffffd097          	auipc	ra,0xffffd
    8000441c:	902080e7          	jalr	-1790(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004420:	8526                	mv	a0,s1
    80004422:	fffff097          	auipc	ra,0xfffff
    80004426:	d8c080e7          	jalr	-628(ra) # 800031ae <bwrite>
    brelse(from);
    8000442a:	854e                	mv	a0,s3
    8000442c:	fffff097          	auipc	ra,0xfffff
    80004430:	dc0080e7          	jalr	-576(ra) # 800031ec <brelse>
    brelse(to);
    80004434:	8526                	mv	a0,s1
    80004436:	fffff097          	auipc	ra,0xfffff
    8000443a:	db6080e7          	jalr	-586(ra) # 800031ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000443e:	2905                	addiw	s2,s2,1
    80004440:	0a91                	addi	s5,s5,4
    80004442:	02ca2783          	lw	a5,44(s4)
    80004446:	f8f94ee3          	blt	s2,a5,800043e2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000444a:	00000097          	auipc	ra,0x0
    8000444e:	c66080e7          	jalr	-922(ra) # 800040b0 <write_head>
    install_trans(0); // Now install writes to home locations
    80004452:	4501                	li	a0,0
    80004454:	00000097          	auipc	ra,0x0
    80004458:	cd8080e7          	jalr	-808(ra) # 8000412c <install_trans>
    log.lh.n = 0;
    8000445c:	0001d797          	auipc	a5,0x1d
    80004460:	4407a023          	sw	zero,1088(a5) # 8002189c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004464:	00000097          	auipc	ra,0x0
    80004468:	c4c080e7          	jalr	-948(ra) # 800040b0 <write_head>
    8000446c:	bdf5                	j	80004368 <end_op+0x52>

000000008000446e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000446e:	1101                	addi	sp,sp,-32
    80004470:	ec06                	sd	ra,24(sp)
    80004472:	e822                	sd	s0,16(sp)
    80004474:	e426                	sd	s1,8(sp)
    80004476:	e04a                	sd	s2,0(sp)
    80004478:	1000                	addi	s0,sp,32
    8000447a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000447c:	0001d917          	auipc	s2,0x1d
    80004480:	3f490913          	addi	s2,s2,1012 # 80021870 <log>
    80004484:	854a                	mv	a0,s2
    80004486:	ffffc097          	auipc	ra,0xffffc
    8000448a:	73c080e7          	jalr	1852(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000448e:	02c92603          	lw	a2,44(s2)
    80004492:	47f5                	li	a5,29
    80004494:	06c7c563          	blt	a5,a2,800044fe <log_write+0x90>
    80004498:	0001d797          	auipc	a5,0x1d
    8000449c:	3f47a783          	lw	a5,1012(a5) # 8002188c <log+0x1c>
    800044a0:	37fd                	addiw	a5,a5,-1
    800044a2:	04f65e63          	bge	a2,a5,800044fe <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044a6:	0001d797          	auipc	a5,0x1d
    800044aa:	3ea7a783          	lw	a5,1002(a5) # 80021890 <log+0x20>
    800044ae:	06f05063          	blez	a5,8000450e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044b2:	4781                	li	a5,0
    800044b4:	06c05563          	blez	a2,8000451e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044b8:	44cc                	lw	a1,12(s1)
    800044ba:	0001d717          	auipc	a4,0x1d
    800044be:	3e670713          	addi	a4,a4,998 # 800218a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044c2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044c4:	4314                	lw	a3,0(a4)
    800044c6:	04b68c63          	beq	a3,a1,8000451e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044ca:	2785                	addiw	a5,a5,1
    800044cc:	0711                	addi	a4,a4,4
    800044ce:	fef61be3          	bne	a2,a5,800044c4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044d2:	0621                	addi	a2,a2,8
    800044d4:	060a                	slli	a2,a2,0x2
    800044d6:	0001d797          	auipc	a5,0x1d
    800044da:	39a78793          	addi	a5,a5,922 # 80021870 <log>
    800044de:	963e                	add	a2,a2,a5
    800044e0:	44dc                	lw	a5,12(s1)
    800044e2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044e4:	8526                	mv	a0,s1
    800044e6:	fffff097          	auipc	ra,0xfffff
    800044ea:	da4080e7          	jalr	-604(ra) # 8000328a <bpin>
    log.lh.n++;
    800044ee:	0001d717          	auipc	a4,0x1d
    800044f2:	38270713          	addi	a4,a4,898 # 80021870 <log>
    800044f6:	575c                	lw	a5,44(a4)
    800044f8:	2785                	addiw	a5,a5,1
    800044fa:	d75c                	sw	a5,44(a4)
    800044fc:	a835                	j	80004538 <log_write+0xca>
    panic("too big a transaction");
    800044fe:	00004517          	auipc	a0,0x4
    80004502:	31a50513          	addi	a0,a0,794 # 80008818 <syscalls+0x208>
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	024080e7          	jalr	36(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    8000450e:	00004517          	auipc	a0,0x4
    80004512:	32250513          	addi	a0,a0,802 # 80008830 <syscalls+0x220>
    80004516:	ffffc097          	auipc	ra,0xffffc
    8000451a:	014080e7          	jalr	20(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    8000451e:	00878713          	addi	a4,a5,8
    80004522:	00271693          	slli	a3,a4,0x2
    80004526:	0001d717          	auipc	a4,0x1d
    8000452a:	34a70713          	addi	a4,a4,842 # 80021870 <log>
    8000452e:	9736                	add	a4,a4,a3
    80004530:	44d4                	lw	a3,12(s1)
    80004532:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004534:	faf608e3          	beq	a2,a5,800044e4 <log_write+0x76>
  }
  release(&log.lock);
    80004538:	0001d517          	auipc	a0,0x1d
    8000453c:	33850513          	addi	a0,a0,824 # 80021870 <log>
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	736080e7          	jalr	1846(ra) # 80000c76 <release>
}
    80004548:	60e2                	ld	ra,24(sp)
    8000454a:	6442                	ld	s0,16(sp)
    8000454c:	64a2                	ld	s1,8(sp)
    8000454e:	6902                	ld	s2,0(sp)
    80004550:	6105                	addi	sp,sp,32
    80004552:	8082                	ret

0000000080004554 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004554:	1101                	addi	sp,sp,-32
    80004556:	ec06                	sd	ra,24(sp)
    80004558:	e822                	sd	s0,16(sp)
    8000455a:	e426                	sd	s1,8(sp)
    8000455c:	e04a                	sd	s2,0(sp)
    8000455e:	1000                	addi	s0,sp,32
    80004560:	84aa                	mv	s1,a0
    80004562:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004564:	00004597          	auipc	a1,0x4
    80004568:	2ec58593          	addi	a1,a1,748 # 80008850 <syscalls+0x240>
    8000456c:	0521                	addi	a0,a0,8
    8000456e:	ffffc097          	auipc	ra,0xffffc
    80004572:	5c4080e7          	jalr	1476(ra) # 80000b32 <initlock>
  lk->name = name;
    80004576:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000457a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000457e:	0204a423          	sw	zero,40(s1)
}
    80004582:	60e2                	ld	ra,24(sp)
    80004584:	6442                	ld	s0,16(sp)
    80004586:	64a2                	ld	s1,8(sp)
    80004588:	6902                	ld	s2,0(sp)
    8000458a:	6105                	addi	sp,sp,32
    8000458c:	8082                	ret

000000008000458e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000458e:	1101                	addi	sp,sp,-32
    80004590:	ec06                	sd	ra,24(sp)
    80004592:	e822                	sd	s0,16(sp)
    80004594:	e426                	sd	s1,8(sp)
    80004596:	e04a                	sd	s2,0(sp)
    80004598:	1000                	addi	s0,sp,32
    8000459a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000459c:	00850913          	addi	s2,a0,8
    800045a0:	854a                	mv	a0,s2
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	620080e7          	jalr	1568(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800045aa:	409c                	lw	a5,0(s1)
    800045ac:	cb89                	beqz	a5,800045be <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045ae:	85ca                	mv	a1,s2
    800045b0:	8526                	mv	a0,s1
    800045b2:	ffffe097          	auipc	ra,0xffffe
    800045b6:	aa2080e7          	jalr	-1374(ra) # 80002054 <sleep>
  while (lk->locked) {
    800045ba:	409c                	lw	a5,0(s1)
    800045bc:	fbed                	bnez	a5,800045ae <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045be:	4785                	li	a5,1
    800045c0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045c2:	ffffd097          	auipc	ra,0xffffd
    800045c6:	3bc080e7          	jalr	956(ra) # 8000197e <myproc>
    800045ca:	591c                	lw	a5,48(a0)
    800045cc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045ce:	854a                	mv	a0,s2
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	6a6080e7          	jalr	1702(ra) # 80000c76 <release>
}
    800045d8:	60e2                	ld	ra,24(sp)
    800045da:	6442                	ld	s0,16(sp)
    800045dc:	64a2                	ld	s1,8(sp)
    800045de:	6902                	ld	s2,0(sp)
    800045e0:	6105                	addi	sp,sp,32
    800045e2:	8082                	ret

00000000800045e4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045e4:	1101                	addi	sp,sp,-32
    800045e6:	ec06                	sd	ra,24(sp)
    800045e8:	e822                	sd	s0,16(sp)
    800045ea:	e426                	sd	s1,8(sp)
    800045ec:	e04a                	sd	s2,0(sp)
    800045ee:	1000                	addi	s0,sp,32
    800045f0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045f2:	00850913          	addi	s2,a0,8
    800045f6:	854a                	mv	a0,s2
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	5ca080e7          	jalr	1482(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004600:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004604:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004608:	8526                	mv	a0,s1
    8000460a:	ffffe097          	auipc	ra,0xffffe
    8000460e:	bd6080e7          	jalr	-1066(ra) # 800021e0 <wakeup>
  release(&lk->lk);
    80004612:	854a                	mv	a0,s2
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	662080e7          	jalr	1634(ra) # 80000c76 <release>
}
    8000461c:	60e2                	ld	ra,24(sp)
    8000461e:	6442                	ld	s0,16(sp)
    80004620:	64a2                	ld	s1,8(sp)
    80004622:	6902                	ld	s2,0(sp)
    80004624:	6105                	addi	sp,sp,32
    80004626:	8082                	ret

0000000080004628 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004628:	7179                	addi	sp,sp,-48
    8000462a:	f406                	sd	ra,40(sp)
    8000462c:	f022                	sd	s0,32(sp)
    8000462e:	ec26                	sd	s1,24(sp)
    80004630:	e84a                	sd	s2,16(sp)
    80004632:	e44e                	sd	s3,8(sp)
    80004634:	1800                	addi	s0,sp,48
    80004636:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004638:	00850913          	addi	s2,a0,8
    8000463c:	854a                	mv	a0,s2
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	584080e7          	jalr	1412(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004646:	409c                	lw	a5,0(s1)
    80004648:	ef99                	bnez	a5,80004666 <holdingsleep+0x3e>
    8000464a:	4481                	li	s1,0
  release(&lk->lk);
    8000464c:	854a                	mv	a0,s2
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	628080e7          	jalr	1576(ra) # 80000c76 <release>
  return r;
}
    80004656:	8526                	mv	a0,s1
    80004658:	70a2                	ld	ra,40(sp)
    8000465a:	7402                	ld	s0,32(sp)
    8000465c:	64e2                	ld	s1,24(sp)
    8000465e:	6942                	ld	s2,16(sp)
    80004660:	69a2                	ld	s3,8(sp)
    80004662:	6145                	addi	sp,sp,48
    80004664:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004666:	0284a983          	lw	s3,40(s1)
    8000466a:	ffffd097          	auipc	ra,0xffffd
    8000466e:	314080e7          	jalr	788(ra) # 8000197e <myproc>
    80004672:	5904                	lw	s1,48(a0)
    80004674:	413484b3          	sub	s1,s1,s3
    80004678:	0014b493          	seqz	s1,s1
    8000467c:	bfc1                	j	8000464c <holdingsleep+0x24>

000000008000467e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000467e:	1141                	addi	sp,sp,-16
    80004680:	e406                	sd	ra,8(sp)
    80004682:	e022                	sd	s0,0(sp)
    80004684:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004686:	00004597          	auipc	a1,0x4
    8000468a:	1da58593          	addi	a1,a1,474 # 80008860 <syscalls+0x250>
    8000468e:	0001d517          	auipc	a0,0x1d
    80004692:	32a50513          	addi	a0,a0,810 # 800219b8 <ftable>
    80004696:	ffffc097          	auipc	ra,0xffffc
    8000469a:	49c080e7          	jalr	1180(ra) # 80000b32 <initlock>
}
    8000469e:	60a2                	ld	ra,8(sp)
    800046a0:	6402                	ld	s0,0(sp)
    800046a2:	0141                	addi	sp,sp,16
    800046a4:	8082                	ret

00000000800046a6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046a6:	1101                	addi	sp,sp,-32
    800046a8:	ec06                	sd	ra,24(sp)
    800046aa:	e822                	sd	s0,16(sp)
    800046ac:	e426                	sd	s1,8(sp)
    800046ae:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046b0:	0001d517          	auipc	a0,0x1d
    800046b4:	30850513          	addi	a0,a0,776 # 800219b8 <ftable>
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	50a080e7          	jalr	1290(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046c0:	0001d497          	auipc	s1,0x1d
    800046c4:	31048493          	addi	s1,s1,784 # 800219d0 <ftable+0x18>
    800046c8:	0001e717          	auipc	a4,0x1e
    800046cc:	2a870713          	addi	a4,a4,680 # 80022970 <ftable+0xfb8>
    if(f->ref == 0){
    800046d0:	40dc                	lw	a5,4(s1)
    800046d2:	cf99                	beqz	a5,800046f0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046d4:	02848493          	addi	s1,s1,40
    800046d8:	fee49ce3          	bne	s1,a4,800046d0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046dc:	0001d517          	auipc	a0,0x1d
    800046e0:	2dc50513          	addi	a0,a0,732 # 800219b8 <ftable>
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	592080e7          	jalr	1426(ra) # 80000c76 <release>
  return 0;
    800046ec:	4481                	li	s1,0
    800046ee:	a819                	j	80004704 <filealloc+0x5e>
      f->ref = 1;
    800046f0:	4785                	li	a5,1
    800046f2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046f4:	0001d517          	auipc	a0,0x1d
    800046f8:	2c450513          	addi	a0,a0,708 # 800219b8 <ftable>
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	57a080e7          	jalr	1402(ra) # 80000c76 <release>
}
    80004704:	8526                	mv	a0,s1
    80004706:	60e2                	ld	ra,24(sp)
    80004708:	6442                	ld	s0,16(sp)
    8000470a:	64a2                	ld	s1,8(sp)
    8000470c:	6105                	addi	sp,sp,32
    8000470e:	8082                	ret

0000000080004710 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004710:	1101                	addi	sp,sp,-32
    80004712:	ec06                	sd	ra,24(sp)
    80004714:	e822                	sd	s0,16(sp)
    80004716:	e426                	sd	s1,8(sp)
    80004718:	1000                	addi	s0,sp,32
    8000471a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000471c:	0001d517          	auipc	a0,0x1d
    80004720:	29c50513          	addi	a0,a0,668 # 800219b8 <ftable>
    80004724:	ffffc097          	auipc	ra,0xffffc
    80004728:	49e080e7          	jalr	1182(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    8000472c:	40dc                	lw	a5,4(s1)
    8000472e:	02f05263          	blez	a5,80004752 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004732:	2785                	addiw	a5,a5,1
    80004734:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004736:	0001d517          	auipc	a0,0x1d
    8000473a:	28250513          	addi	a0,a0,642 # 800219b8 <ftable>
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	538080e7          	jalr	1336(ra) # 80000c76 <release>
  return f;
}
    80004746:	8526                	mv	a0,s1
    80004748:	60e2                	ld	ra,24(sp)
    8000474a:	6442                	ld	s0,16(sp)
    8000474c:	64a2                	ld	s1,8(sp)
    8000474e:	6105                	addi	sp,sp,32
    80004750:	8082                	ret
    panic("filedup");
    80004752:	00004517          	auipc	a0,0x4
    80004756:	11650513          	addi	a0,a0,278 # 80008868 <syscalls+0x258>
    8000475a:	ffffc097          	auipc	ra,0xffffc
    8000475e:	dd0080e7          	jalr	-560(ra) # 8000052a <panic>

0000000080004762 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004762:	7139                	addi	sp,sp,-64
    80004764:	fc06                	sd	ra,56(sp)
    80004766:	f822                	sd	s0,48(sp)
    80004768:	f426                	sd	s1,40(sp)
    8000476a:	f04a                	sd	s2,32(sp)
    8000476c:	ec4e                	sd	s3,24(sp)
    8000476e:	e852                	sd	s4,16(sp)
    80004770:	e456                	sd	s5,8(sp)
    80004772:	0080                	addi	s0,sp,64
    80004774:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004776:	0001d517          	auipc	a0,0x1d
    8000477a:	24250513          	addi	a0,a0,578 # 800219b8 <ftable>
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	444080e7          	jalr	1092(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004786:	40dc                	lw	a5,4(s1)
    80004788:	06f05163          	blez	a5,800047ea <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000478c:	37fd                	addiw	a5,a5,-1
    8000478e:	0007871b          	sext.w	a4,a5
    80004792:	c0dc                	sw	a5,4(s1)
    80004794:	06e04363          	bgtz	a4,800047fa <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004798:	0004a903          	lw	s2,0(s1)
    8000479c:	0094ca83          	lbu	s5,9(s1)
    800047a0:	0104ba03          	ld	s4,16(s1)
    800047a4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047a8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047ac:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047b0:	0001d517          	auipc	a0,0x1d
    800047b4:	20850513          	addi	a0,a0,520 # 800219b8 <ftable>
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	4be080e7          	jalr	1214(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    800047c0:	4785                	li	a5,1
    800047c2:	04f90d63          	beq	s2,a5,8000481c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047c6:	3979                	addiw	s2,s2,-2
    800047c8:	4785                	li	a5,1
    800047ca:	0527e063          	bltu	a5,s2,8000480a <fileclose+0xa8>
    begin_op();
    800047ce:	00000097          	auipc	ra,0x0
    800047d2:	ac8080e7          	jalr	-1336(ra) # 80004296 <begin_op>
    iput(ff.ip);
    800047d6:	854e                	mv	a0,s3
    800047d8:	fffff097          	auipc	ra,0xfffff
    800047dc:	2a2080e7          	jalr	674(ra) # 80003a7a <iput>
    end_op();
    800047e0:	00000097          	auipc	ra,0x0
    800047e4:	b36080e7          	jalr	-1226(ra) # 80004316 <end_op>
    800047e8:	a00d                	j	8000480a <fileclose+0xa8>
    panic("fileclose");
    800047ea:	00004517          	auipc	a0,0x4
    800047ee:	08650513          	addi	a0,a0,134 # 80008870 <syscalls+0x260>
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	d38080e7          	jalr	-712(ra) # 8000052a <panic>
    release(&ftable.lock);
    800047fa:	0001d517          	auipc	a0,0x1d
    800047fe:	1be50513          	addi	a0,a0,446 # 800219b8 <ftable>
    80004802:	ffffc097          	auipc	ra,0xffffc
    80004806:	474080e7          	jalr	1140(ra) # 80000c76 <release>
  }
}
    8000480a:	70e2                	ld	ra,56(sp)
    8000480c:	7442                	ld	s0,48(sp)
    8000480e:	74a2                	ld	s1,40(sp)
    80004810:	7902                	ld	s2,32(sp)
    80004812:	69e2                	ld	s3,24(sp)
    80004814:	6a42                	ld	s4,16(sp)
    80004816:	6aa2                	ld	s5,8(sp)
    80004818:	6121                	addi	sp,sp,64
    8000481a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000481c:	85d6                	mv	a1,s5
    8000481e:	8552                	mv	a0,s4
    80004820:	00000097          	auipc	ra,0x0
    80004824:	34c080e7          	jalr	844(ra) # 80004b6c <pipeclose>
    80004828:	b7cd                	j	8000480a <fileclose+0xa8>

000000008000482a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000482a:	715d                	addi	sp,sp,-80
    8000482c:	e486                	sd	ra,72(sp)
    8000482e:	e0a2                	sd	s0,64(sp)
    80004830:	fc26                	sd	s1,56(sp)
    80004832:	f84a                	sd	s2,48(sp)
    80004834:	f44e                	sd	s3,40(sp)
    80004836:	0880                	addi	s0,sp,80
    80004838:	84aa                	mv	s1,a0
    8000483a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000483c:	ffffd097          	auipc	ra,0xffffd
    80004840:	142080e7          	jalr	322(ra) # 8000197e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004844:	409c                	lw	a5,0(s1)
    80004846:	37f9                	addiw	a5,a5,-2
    80004848:	4705                	li	a4,1
    8000484a:	04f76763          	bltu	a4,a5,80004898 <filestat+0x6e>
    8000484e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004850:	6c88                	ld	a0,24(s1)
    80004852:	fffff097          	auipc	ra,0xfffff
    80004856:	06e080e7          	jalr	110(ra) # 800038c0 <ilock>
    stati(f->ip, &st);
    8000485a:	fb840593          	addi	a1,s0,-72
    8000485e:	6c88                	ld	a0,24(s1)
    80004860:	fffff097          	auipc	ra,0xfffff
    80004864:	2ea080e7          	jalr	746(ra) # 80003b4a <stati>
    iunlock(f->ip);
    80004868:	6c88                	ld	a0,24(s1)
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	118080e7          	jalr	280(ra) # 80003982 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004872:	46e1                	li	a3,24
    80004874:	fb840613          	addi	a2,s0,-72
    80004878:	85ce                	mv	a1,s3
    8000487a:	06893503          	ld	a0,104(s2)
    8000487e:	ffffd097          	auipc	ra,0xffffd
    80004882:	dc0080e7          	jalr	-576(ra) # 8000163e <copyout>
    80004886:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000488a:	60a6                	ld	ra,72(sp)
    8000488c:	6406                	ld	s0,64(sp)
    8000488e:	74e2                	ld	s1,56(sp)
    80004890:	7942                	ld	s2,48(sp)
    80004892:	79a2                	ld	s3,40(sp)
    80004894:	6161                	addi	sp,sp,80
    80004896:	8082                	ret
  return -1;
    80004898:	557d                	li	a0,-1
    8000489a:	bfc5                	j	8000488a <filestat+0x60>

000000008000489c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000489c:	7179                	addi	sp,sp,-48
    8000489e:	f406                	sd	ra,40(sp)
    800048a0:	f022                	sd	s0,32(sp)
    800048a2:	ec26                	sd	s1,24(sp)
    800048a4:	e84a                	sd	s2,16(sp)
    800048a6:	e44e                	sd	s3,8(sp)
    800048a8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048aa:	00854783          	lbu	a5,8(a0)
    800048ae:	c3d5                	beqz	a5,80004952 <fileread+0xb6>
    800048b0:	84aa                	mv	s1,a0
    800048b2:	89ae                	mv	s3,a1
    800048b4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048b6:	411c                	lw	a5,0(a0)
    800048b8:	4705                	li	a4,1
    800048ba:	04e78963          	beq	a5,a4,8000490c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048be:	470d                	li	a4,3
    800048c0:	04e78d63          	beq	a5,a4,8000491a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048c4:	4709                	li	a4,2
    800048c6:	06e79e63          	bne	a5,a4,80004942 <fileread+0xa6>
    ilock(f->ip);
    800048ca:	6d08                	ld	a0,24(a0)
    800048cc:	fffff097          	auipc	ra,0xfffff
    800048d0:	ff4080e7          	jalr	-12(ra) # 800038c0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048d4:	874a                	mv	a4,s2
    800048d6:	5094                	lw	a3,32(s1)
    800048d8:	864e                	mv	a2,s3
    800048da:	4585                	li	a1,1
    800048dc:	6c88                	ld	a0,24(s1)
    800048de:	fffff097          	auipc	ra,0xfffff
    800048e2:	296080e7          	jalr	662(ra) # 80003b74 <readi>
    800048e6:	892a                	mv	s2,a0
    800048e8:	00a05563          	blez	a0,800048f2 <fileread+0x56>
      f->off += r;
    800048ec:	509c                	lw	a5,32(s1)
    800048ee:	9fa9                	addw	a5,a5,a0
    800048f0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048f2:	6c88                	ld	a0,24(s1)
    800048f4:	fffff097          	auipc	ra,0xfffff
    800048f8:	08e080e7          	jalr	142(ra) # 80003982 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048fc:	854a                	mv	a0,s2
    800048fe:	70a2                	ld	ra,40(sp)
    80004900:	7402                	ld	s0,32(sp)
    80004902:	64e2                	ld	s1,24(sp)
    80004904:	6942                	ld	s2,16(sp)
    80004906:	69a2                	ld	s3,8(sp)
    80004908:	6145                	addi	sp,sp,48
    8000490a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000490c:	6908                	ld	a0,16(a0)
    8000490e:	00000097          	auipc	ra,0x0
    80004912:	3c0080e7          	jalr	960(ra) # 80004cce <piperead>
    80004916:	892a                	mv	s2,a0
    80004918:	b7d5                	j	800048fc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000491a:	02451783          	lh	a5,36(a0)
    8000491e:	03079693          	slli	a3,a5,0x30
    80004922:	92c1                	srli	a3,a3,0x30
    80004924:	4725                	li	a4,9
    80004926:	02d76863          	bltu	a4,a3,80004956 <fileread+0xba>
    8000492a:	0792                	slli	a5,a5,0x4
    8000492c:	0001d717          	auipc	a4,0x1d
    80004930:	fec70713          	addi	a4,a4,-20 # 80021918 <devsw>
    80004934:	97ba                	add	a5,a5,a4
    80004936:	639c                	ld	a5,0(a5)
    80004938:	c38d                	beqz	a5,8000495a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000493a:	4505                	li	a0,1
    8000493c:	9782                	jalr	a5
    8000493e:	892a                	mv	s2,a0
    80004940:	bf75                	j	800048fc <fileread+0x60>
    panic("fileread");
    80004942:	00004517          	auipc	a0,0x4
    80004946:	f3e50513          	addi	a0,a0,-194 # 80008880 <syscalls+0x270>
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	be0080e7          	jalr	-1056(ra) # 8000052a <panic>
    return -1;
    80004952:	597d                	li	s2,-1
    80004954:	b765                	j	800048fc <fileread+0x60>
      return -1;
    80004956:	597d                	li	s2,-1
    80004958:	b755                	j	800048fc <fileread+0x60>
    8000495a:	597d                	li	s2,-1
    8000495c:	b745                	j	800048fc <fileread+0x60>

000000008000495e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000495e:	715d                	addi	sp,sp,-80
    80004960:	e486                	sd	ra,72(sp)
    80004962:	e0a2                	sd	s0,64(sp)
    80004964:	fc26                	sd	s1,56(sp)
    80004966:	f84a                	sd	s2,48(sp)
    80004968:	f44e                	sd	s3,40(sp)
    8000496a:	f052                	sd	s4,32(sp)
    8000496c:	ec56                	sd	s5,24(sp)
    8000496e:	e85a                	sd	s6,16(sp)
    80004970:	e45e                	sd	s7,8(sp)
    80004972:	e062                	sd	s8,0(sp)
    80004974:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004976:	00954783          	lbu	a5,9(a0)
    8000497a:	10078663          	beqz	a5,80004a86 <filewrite+0x128>
    8000497e:	892a                	mv	s2,a0
    80004980:	8aae                	mv	s5,a1
    80004982:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004984:	411c                	lw	a5,0(a0)
    80004986:	4705                	li	a4,1
    80004988:	02e78263          	beq	a5,a4,800049ac <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000498c:	470d                	li	a4,3
    8000498e:	02e78663          	beq	a5,a4,800049ba <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004992:	4709                	li	a4,2
    80004994:	0ee79163          	bne	a5,a4,80004a76 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004998:	0ac05d63          	blez	a2,80004a52 <filewrite+0xf4>
    int i = 0;
    8000499c:	4981                	li	s3,0
    8000499e:	6b05                	lui	s6,0x1
    800049a0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049a4:	6b85                	lui	s7,0x1
    800049a6:	c00b8b9b          	addiw	s7,s7,-1024
    800049aa:	a861                	j	80004a42 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049ac:	6908                	ld	a0,16(a0)
    800049ae:	00000097          	auipc	ra,0x0
    800049b2:	22e080e7          	jalr	558(ra) # 80004bdc <pipewrite>
    800049b6:	8a2a                	mv	s4,a0
    800049b8:	a045                	j	80004a58 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049ba:	02451783          	lh	a5,36(a0)
    800049be:	03079693          	slli	a3,a5,0x30
    800049c2:	92c1                	srli	a3,a3,0x30
    800049c4:	4725                	li	a4,9
    800049c6:	0cd76263          	bltu	a4,a3,80004a8a <filewrite+0x12c>
    800049ca:	0792                	slli	a5,a5,0x4
    800049cc:	0001d717          	auipc	a4,0x1d
    800049d0:	f4c70713          	addi	a4,a4,-180 # 80021918 <devsw>
    800049d4:	97ba                	add	a5,a5,a4
    800049d6:	679c                	ld	a5,8(a5)
    800049d8:	cbdd                	beqz	a5,80004a8e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049da:	4505                	li	a0,1
    800049dc:	9782                	jalr	a5
    800049de:	8a2a                	mv	s4,a0
    800049e0:	a8a5                	j	80004a58 <filewrite+0xfa>
    800049e2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049e6:	00000097          	auipc	ra,0x0
    800049ea:	8b0080e7          	jalr	-1872(ra) # 80004296 <begin_op>
      ilock(f->ip);
    800049ee:	01893503          	ld	a0,24(s2)
    800049f2:	fffff097          	auipc	ra,0xfffff
    800049f6:	ece080e7          	jalr	-306(ra) # 800038c0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049fa:	8762                	mv	a4,s8
    800049fc:	02092683          	lw	a3,32(s2)
    80004a00:	01598633          	add	a2,s3,s5
    80004a04:	4585                	li	a1,1
    80004a06:	01893503          	ld	a0,24(s2)
    80004a0a:	fffff097          	auipc	ra,0xfffff
    80004a0e:	262080e7          	jalr	610(ra) # 80003c6c <writei>
    80004a12:	84aa                	mv	s1,a0
    80004a14:	00a05763          	blez	a0,80004a22 <filewrite+0xc4>
        f->off += r;
    80004a18:	02092783          	lw	a5,32(s2)
    80004a1c:	9fa9                	addw	a5,a5,a0
    80004a1e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a22:	01893503          	ld	a0,24(s2)
    80004a26:	fffff097          	auipc	ra,0xfffff
    80004a2a:	f5c080e7          	jalr	-164(ra) # 80003982 <iunlock>
      end_op();
    80004a2e:	00000097          	auipc	ra,0x0
    80004a32:	8e8080e7          	jalr	-1816(ra) # 80004316 <end_op>

      if(r != n1){
    80004a36:	009c1f63          	bne	s8,s1,80004a54 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a3a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a3e:	0149db63          	bge	s3,s4,80004a54 <filewrite+0xf6>
      int n1 = n - i;
    80004a42:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a46:	84be                	mv	s1,a5
    80004a48:	2781                	sext.w	a5,a5
    80004a4a:	f8fb5ce3          	bge	s6,a5,800049e2 <filewrite+0x84>
    80004a4e:	84de                	mv	s1,s7
    80004a50:	bf49                	j	800049e2 <filewrite+0x84>
    int i = 0;
    80004a52:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a54:	013a1f63          	bne	s4,s3,80004a72 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a58:	8552                	mv	a0,s4
    80004a5a:	60a6                	ld	ra,72(sp)
    80004a5c:	6406                	ld	s0,64(sp)
    80004a5e:	74e2                	ld	s1,56(sp)
    80004a60:	7942                	ld	s2,48(sp)
    80004a62:	79a2                	ld	s3,40(sp)
    80004a64:	7a02                	ld	s4,32(sp)
    80004a66:	6ae2                	ld	s5,24(sp)
    80004a68:	6b42                	ld	s6,16(sp)
    80004a6a:	6ba2                	ld	s7,8(sp)
    80004a6c:	6c02                	ld	s8,0(sp)
    80004a6e:	6161                	addi	sp,sp,80
    80004a70:	8082                	ret
    ret = (i == n ? n : -1);
    80004a72:	5a7d                	li	s4,-1
    80004a74:	b7d5                	j	80004a58 <filewrite+0xfa>
    panic("filewrite");
    80004a76:	00004517          	auipc	a0,0x4
    80004a7a:	e1a50513          	addi	a0,a0,-486 # 80008890 <syscalls+0x280>
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	aac080e7          	jalr	-1364(ra) # 8000052a <panic>
    return -1;
    80004a86:	5a7d                	li	s4,-1
    80004a88:	bfc1                	j	80004a58 <filewrite+0xfa>
      return -1;
    80004a8a:	5a7d                	li	s4,-1
    80004a8c:	b7f1                	j	80004a58 <filewrite+0xfa>
    80004a8e:	5a7d                	li	s4,-1
    80004a90:	b7e1                	j	80004a58 <filewrite+0xfa>

0000000080004a92 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a92:	7179                	addi	sp,sp,-48
    80004a94:	f406                	sd	ra,40(sp)
    80004a96:	f022                	sd	s0,32(sp)
    80004a98:	ec26                	sd	s1,24(sp)
    80004a9a:	e84a                	sd	s2,16(sp)
    80004a9c:	e44e                	sd	s3,8(sp)
    80004a9e:	e052                	sd	s4,0(sp)
    80004aa0:	1800                	addi	s0,sp,48
    80004aa2:	84aa                	mv	s1,a0
    80004aa4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004aa6:	0005b023          	sd	zero,0(a1)
    80004aaa:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004aae:	00000097          	auipc	ra,0x0
    80004ab2:	bf8080e7          	jalr	-1032(ra) # 800046a6 <filealloc>
    80004ab6:	e088                	sd	a0,0(s1)
    80004ab8:	c551                	beqz	a0,80004b44 <pipealloc+0xb2>
    80004aba:	00000097          	auipc	ra,0x0
    80004abe:	bec080e7          	jalr	-1044(ra) # 800046a6 <filealloc>
    80004ac2:	00aa3023          	sd	a0,0(s4)
    80004ac6:	c92d                	beqz	a0,80004b38 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	00a080e7          	jalr	10(ra) # 80000ad2 <kalloc>
    80004ad0:	892a                	mv	s2,a0
    80004ad2:	c125                	beqz	a0,80004b32 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ad4:	4985                	li	s3,1
    80004ad6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ada:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ade:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ae2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ae6:	00004597          	auipc	a1,0x4
    80004aea:	9a258593          	addi	a1,a1,-1630 # 80008488 <states.0+0x1e0>
    80004aee:	ffffc097          	auipc	ra,0xffffc
    80004af2:	044080e7          	jalr	68(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004af6:	609c                	ld	a5,0(s1)
    80004af8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004afc:	609c                	ld	a5,0(s1)
    80004afe:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b02:	609c                	ld	a5,0(s1)
    80004b04:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b08:	609c                	ld	a5,0(s1)
    80004b0a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b0e:	000a3783          	ld	a5,0(s4)
    80004b12:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b16:	000a3783          	ld	a5,0(s4)
    80004b1a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b1e:	000a3783          	ld	a5,0(s4)
    80004b22:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b26:	000a3783          	ld	a5,0(s4)
    80004b2a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b2e:	4501                	li	a0,0
    80004b30:	a025                	j	80004b58 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b32:	6088                	ld	a0,0(s1)
    80004b34:	e501                	bnez	a0,80004b3c <pipealloc+0xaa>
    80004b36:	a039                	j	80004b44 <pipealloc+0xb2>
    80004b38:	6088                	ld	a0,0(s1)
    80004b3a:	c51d                	beqz	a0,80004b68 <pipealloc+0xd6>
    fileclose(*f0);
    80004b3c:	00000097          	auipc	ra,0x0
    80004b40:	c26080e7          	jalr	-986(ra) # 80004762 <fileclose>
  if(*f1)
    80004b44:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b48:	557d                	li	a0,-1
  if(*f1)
    80004b4a:	c799                	beqz	a5,80004b58 <pipealloc+0xc6>
    fileclose(*f1);
    80004b4c:	853e                	mv	a0,a5
    80004b4e:	00000097          	auipc	ra,0x0
    80004b52:	c14080e7          	jalr	-1004(ra) # 80004762 <fileclose>
  return -1;
    80004b56:	557d                	li	a0,-1
}
    80004b58:	70a2                	ld	ra,40(sp)
    80004b5a:	7402                	ld	s0,32(sp)
    80004b5c:	64e2                	ld	s1,24(sp)
    80004b5e:	6942                	ld	s2,16(sp)
    80004b60:	69a2                	ld	s3,8(sp)
    80004b62:	6a02                	ld	s4,0(sp)
    80004b64:	6145                	addi	sp,sp,48
    80004b66:	8082                	ret
  return -1;
    80004b68:	557d                	li	a0,-1
    80004b6a:	b7fd                	j	80004b58 <pipealloc+0xc6>

0000000080004b6c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b6c:	1101                	addi	sp,sp,-32
    80004b6e:	ec06                	sd	ra,24(sp)
    80004b70:	e822                	sd	s0,16(sp)
    80004b72:	e426                	sd	s1,8(sp)
    80004b74:	e04a                	sd	s2,0(sp)
    80004b76:	1000                	addi	s0,sp,32
    80004b78:	84aa                	mv	s1,a0
    80004b7a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b7c:	ffffc097          	auipc	ra,0xffffc
    80004b80:	046080e7          	jalr	70(ra) # 80000bc2 <acquire>
  if(writable){
    80004b84:	02090d63          	beqz	s2,80004bbe <pipeclose+0x52>
    pi->writeopen = 0;
    80004b88:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b8c:	21848513          	addi	a0,s1,536
    80004b90:	ffffd097          	auipc	ra,0xffffd
    80004b94:	650080e7          	jalr	1616(ra) # 800021e0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b98:	2204b783          	ld	a5,544(s1)
    80004b9c:	eb95                	bnez	a5,80004bd0 <pipeclose+0x64>
    release(&pi->lock);
    80004b9e:	8526                	mv	a0,s1
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	0d6080e7          	jalr	214(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004ba8:	8526                	mv	a0,s1
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	e2c080e7          	jalr	-468(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004bb2:	60e2                	ld	ra,24(sp)
    80004bb4:	6442                	ld	s0,16(sp)
    80004bb6:	64a2                	ld	s1,8(sp)
    80004bb8:	6902                	ld	s2,0(sp)
    80004bba:	6105                	addi	sp,sp,32
    80004bbc:	8082                	ret
    pi->readopen = 0;
    80004bbe:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bc2:	21c48513          	addi	a0,s1,540
    80004bc6:	ffffd097          	auipc	ra,0xffffd
    80004bca:	61a080e7          	jalr	1562(ra) # 800021e0 <wakeup>
    80004bce:	b7e9                	j	80004b98 <pipeclose+0x2c>
    release(&pi->lock);
    80004bd0:	8526                	mv	a0,s1
    80004bd2:	ffffc097          	auipc	ra,0xffffc
    80004bd6:	0a4080e7          	jalr	164(ra) # 80000c76 <release>
}
    80004bda:	bfe1                	j	80004bb2 <pipeclose+0x46>

0000000080004bdc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bdc:	711d                	addi	sp,sp,-96
    80004bde:	ec86                	sd	ra,88(sp)
    80004be0:	e8a2                	sd	s0,80(sp)
    80004be2:	e4a6                	sd	s1,72(sp)
    80004be4:	e0ca                	sd	s2,64(sp)
    80004be6:	fc4e                	sd	s3,56(sp)
    80004be8:	f852                	sd	s4,48(sp)
    80004bea:	f456                	sd	s5,40(sp)
    80004bec:	f05a                	sd	s6,32(sp)
    80004bee:	ec5e                	sd	s7,24(sp)
    80004bf0:	e862                	sd	s8,16(sp)
    80004bf2:	1080                	addi	s0,sp,96
    80004bf4:	84aa                	mv	s1,a0
    80004bf6:	8aae                	mv	s5,a1
    80004bf8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bfa:	ffffd097          	auipc	ra,0xffffd
    80004bfe:	d84080e7          	jalr	-636(ra) # 8000197e <myproc>
    80004c02:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c04:	8526                	mv	a0,s1
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	fbc080e7          	jalr	-68(ra) # 80000bc2 <acquire>
  while(i < n){
    80004c0e:	0b405363          	blez	s4,80004cb4 <pipewrite+0xd8>
  int i = 0;
    80004c12:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c14:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c16:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c1a:	21c48b93          	addi	s7,s1,540
    80004c1e:	a089                	j	80004c60 <pipewrite+0x84>
      release(&pi->lock);
    80004c20:	8526                	mv	a0,s1
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	054080e7          	jalr	84(ra) # 80000c76 <release>
      return -1;
    80004c2a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c2c:	854a                	mv	a0,s2
    80004c2e:	60e6                	ld	ra,88(sp)
    80004c30:	6446                	ld	s0,80(sp)
    80004c32:	64a6                	ld	s1,72(sp)
    80004c34:	6906                	ld	s2,64(sp)
    80004c36:	79e2                	ld	s3,56(sp)
    80004c38:	7a42                	ld	s4,48(sp)
    80004c3a:	7aa2                	ld	s5,40(sp)
    80004c3c:	7b02                	ld	s6,32(sp)
    80004c3e:	6be2                	ld	s7,24(sp)
    80004c40:	6c42                	ld	s8,16(sp)
    80004c42:	6125                	addi	sp,sp,96
    80004c44:	8082                	ret
      wakeup(&pi->nread);
    80004c46:	8562                	mv	a0,s8
    80004c48:	ffffd097          	auipc	ra,0xffffd
    80004c4c:	598080e7          	jalr	1432(ra) # 800021e0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c50:	85a6                	mv	a1,s1
    80004c52:	855e                	mv	a0,s7
    80004c54:	ffffd097          	auipc	ra,0xffffd
    80004c58:	400080e7          	jalr	1024(ra) # 80002054 <sleep>
  while(i < n){
    80004c5c:	05495d63          	bge	s2,s4,80004cb6 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004c60:	2204a783          	lw	a5,544(s1)
    80004c64:	dfd5                	beqz	a5,80004c20 <pipewrite+0x44>
    80004c66:	0289a783          	lw	a5,40(s3)
    80004c6a:	fbdd                	bnez	a5,80004c20 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c6c:	2184a783          	lw	a5,536(s1)
    80004c70:	21c4a703          	lw	a4,540(s1)
    80004c74:	2007879b          	addiw	a5,a5,512
    80004c78:	fcf707e3          	beq	a4,a5,80004c46 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c7c:	4685                	li	a3,1
    80004c7e:	01590633          	add	a2,s2,s5
    80004c82:	faf40593          	addi	a1,s0,-81
    80004c86:	0689b503          	ld	a0,104(s3)
    80004c8a:	ffffd097          	auipc	ra,0xffffd
    80004c8e:	a40080e7          	jalr	-1472(ra) # 800016ca <copyin>
    80004c92:	03650263          	beq	a0,s6,80004cb6 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c96:	21c4a783          	lw	a5,540(s1)
    80004c9a:	0017871b          	addiw	a4,a5,1
    80004c9e:	20e4ae23          	sw	a4,540(s1)
    80004ca2:	1ff7f793          	andi	a5,a5,511
    80004ca6:	97a6                	add	a5,a5,s1
    80004ca8:	faf44703          	lbu	a4,-81(s0)
    80004cac:	00e78c23          	sb	a4,24(a5)
      i++;
    80004cb0:	2905                	addiw	s2,s2,1
    80004cb2:	b76d                	j	80004c5c <pipewrite+0x80>
  int i = 0;
    80004cb4:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004cb6:	21848513          	addi	a0,s1,536
    80004cba:	ffffd097          	auipc	ra,0xffffd
    80004cbe:	526080e7          	jalr	1318(ra) # 800021e0 <wakeup>
  release(&pi->lock);
    80004cc2:	8526                	mv	a0,s1
    80004cc4:	ffffc097          	auipc	ra,0xffffc
    80004cc8:	fb2080e7          	jalr	-78(ra) # 80000c76 <release>
  return i;
    80004ccc:	b785                	j	80004c2c <pipewrite+0x50>

0000000080004cce <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cce:	715d                	addi	sp,sp,-80
    80004cd0:	e486                	sd	ra,72(sp)
    80004cd2:	e0a2                	sd	s0,64(sp)
    80004cd4:	fc26                	sd	s1,56(sp)
    80004cd6:	f84a                	sd	s2,48(sp)
    80004cd8:	f44e                	sd	s3,40(sp)
    80004cda:	f052                	sd	s4,32(sp)
    80004cdc:	ec56                	sd	s5,24(sp)
    80004cde:	e85a                	sd	s6,16(sp)
    80004ce0:	0880                	addi	s0,sp,80
    80004ce2:	84aa                	mv	s1,a0
    80004ce4:	892e                	mv	s2,a1
    80004ce6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ce8:	ffffd097          	auipc	ra,0xffffd
    80004cec:	c96080e7          	jalr	-874(ra) # 8000197e <myproc>
    80004cf0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cf2:	8526                	mv	a0,s1
    80004cf4:	ffffc097          	auipc	ra,0xffffc
    80004cf8:	ece080e7          	jalr	-306(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cfc:	2184a703          	lw	a4,536(s1)
    80004d00:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d04:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d08:	02f71463          	bne	a4,a5,80004d30 <piperead+0x62>
    80004d0c:	2244a783          	lw	a5,548(s1)
    80004d10:	c385                	beqz	a5,80004d30 <piperead+0x62>
    if(pr->killed){
    80004d12:	028a2783          	lw	a5,40(s4)
    80004d16:	ebc1                	bnez	a5,80004da6 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d18:	85a6                	mv	a1,s1
    80004d1a:	854e                	mv	a0,s3
    80004d1c:	ffffd097          	auipc	ra,0xffffd
    80004d20:	338080e7          	jalr	824(ra) # 80002054 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d24:	2184a703          	lw	a4,536(s1)
    80004d28:	21c4a783          	lw	a5,540(s1)
    80004d2c:	fef700e3          	beq	a4,a5,80004d0c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d30:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d32:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d34:	05505363          	blez	s5,80004d7a <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004d38:	2184a783          	lw	a5,536(s1)
    80004d3c:	21c4a703          	lw	a4,540(s1)
    80004d40:	02f70d63          	beq	a4,a5,80004d7a <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d44:	0017871b          	addiw	a4,a5,1
    80004d48:	20e4ac23          	sw	a4,536(s1)
    80004d4c:	1ff7f793          	andi	a5,a5,511
    80004d50:	97a6                	add	a5,a5,s1
    80004d52:	0187c783          	lbu	a5,24(a5)
    80004d56:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d5a:	4685                	li	a3,1
    80004d5c:	fbf40613          	addi	a2,s0,-65
    80004d60:	85ca                	mv	a1,s2
    80004d62:	068a3503          	ld	a0,104(s4)
    80004d66:	ffffd097          	auipc	ra,0xffffd
    80004d6a:	8d8080e7          	jalr	-1832(ra) # 8000163e <copyout>
    80004d6e:	01650663          	beq	a0,s6,80004d7a <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d72:	2985                	addiw	s3,s3,1
    80004d74:	0905                	addi	s2,s2,1
    80004d76:	fd3a91e3          	bne	s5,s3,80004d38 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d7a:	21c48513          	addi	a0,s1,540
    80004d7e:	ffffd097          	auipc	ra,0xffffd
    80004d82:	462080e7          	jalr	1122(ra) # 800021e0 <wakeup>
  release(&pi->lock);
    80004d86:	8526                	mv	a0,s1
    80004d88:	ffffc097          	auipc	ra,0xffffc
    80004d8c:	eee080e7          	jalr	-274(ra) # 80000c76 <release>
  return i;
}
    80004d90:	854e                	mv	a0,s3
    80004d92:	60a6                	ld	ra,72(sp)
    80004d94:	6406                	ld	s0,64(sp)
    80004d96:	74e2                	ld	s1,56(sp)
    80004d98:	7942                	ld	s2,48(sp)
    80004d9a:	79a2                	ld	s3,40(sp)
    80004d9c:	7a02                	ld	s4,32(sp)
    80004d9e:	6ae2                	ld	s5,24(sp)
    80004da0:	6b42                	ld	s6,16(sp)
    80004da2:	6161                	addi	sp,sp,80
    80004da4:	8082                	ret
      release(&pi->lock);
    80004da6:	8526                	mv	a0,s1
    80004da8:	ffffc097          	auipc	ra,0xffffc
    80004dac:	ece080e7          	jalr	-306(ra) # 80000c76 <release>
      return -1;
    80004db0:	59fd                	li	s3,-1
    80004db2:	bff9                	j	80004d90 <piperead+0xc2>

0000000080004db4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004db4:	de010113          	addi	sp,sp,-544
    80004db8:	20113c23          	sd	ra,536(sp)
    80004dbc:	20813823          	sd	s0,528(sp)
    80004dc0:	20913423          	sd	s1,520(sp)
    80004dc4:	21213023          	sd	s2,512(sp)
    80004dc8:	ffce                	sd	s3,504(sp)
    80004dca:	fbd2                	sd	s4,496(sp)
    80004dcc:	f7d6                	sd	s5,488(sp)
    80004dce:	f3da                	sd	s6,480(sp)
    80004dd0:	efde                	sd	s7,472(sp)
    80004dd2:	ebe2                	sd	s8,464(sp)
    80004dd4:	e7e6                	sd	s9,456(sp)
    80004dd6:	e3ea                	sd	s10,448(sp)
    80004dd8:	ff6e                	sd	s11,440(sp)
    80004dda:	1400                	addi	s0,sp,544
    80004ddc:	892a                	mv	s2,a0
    80004dde:	dea43423          	sd	a0,-536(s0)
    80004de2:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004de6:	ffffd097          	auipc	ra,0xffffd
    80004dea:	b98080e7          	jalr	-1128(ra) # 8000197e <myproc>
    80004dee:	84aa                	mv	s1,a0

  begin_op();
    80004df0:	fffff097          	auipc	ra,0xfffff
    80004df4:	4a6080e7          	jalr	1190(ra) # 80004296 <begin_op>

  if((ip = namei(path)) == 0){
    80004df8:	854a                	mv	a0,s2
    80004dfa:	fffff097          	auipc	ra,0xfffff
    80004dfe:	27c080e7          	jalr	636(ra) # 80004076 <namei>
    80004e02:	c93d                	beqz	a0,80004e78 <exec+0xc4>
    80004e04:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e06:	fffff097          	auipc	ra,0xfffff
    80004e0a:	aba080e7          	jalr	-1350(ra) # 800038c0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e0e:	04000713          	li	a4,64
    80004e12:	4681                	li	a3,0
    80004e14:	e4840613          	addi	a2,s0,-440
    80004e18:	4581                	li	a1,0
    80004e1a:	8556                	mv	a0,s5
    80004e1c:	fffff097          	auipc	ra,0xfffff
    80004e20:	d58080e7          	jalr	-680(ra) # 80003b74 <readi>
    80004e24:	04000793          	li	a5,64
    80004e28:	00f51a63          	bne	a0,a5,80004e3c <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e2c:	e4842703          	lw	a4,-440(s0)
    80004e30:	464c47b7          	lui	a5,0x464c4
    80004e34:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e38:	04f70663          	beq	a4,a5,80004e84 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e3c:	8556                	mv	a0,s5
    80004e3e:	fffff097          	auipc	ra,0xfffff
    80004e42:	ce4080e7          	jalr	-796(ra) # 80003b22 <iunlockput>
    end_op();
    80004e46:	fffff097          	auipc	ra,0xfffff
    80004e4a:	4d0080e7          	jalr	1232(ra) # 80004316 <end_op>
  }
  return -1;
    80004e4e:	557d                	li	a0,-1
}
    80004e50:	21813083          	ld	ra,536(sp)
    80004e54:	21013403          	ld	s0,528(sp)
    80004e58:	20813483          	ld	s1,520(sp)
    80004e5c:	20013903          	ld	s2,512(sp)
    80004e60:	79fe                	ld	s3,504(sp)
    80004e62:	7a5e                	ld	s4,496(sp)
    80004e64:	7abe                	ld	s5,488(sp)
    80004e66:	7b1e                	ld	s6,480(sp)
    80004e68:	6bfe                	ld	s7,472(sp)
    80004e6a:	6c5e                	ld	s8,464(sp)
    80004e6c:	6cbe                	ld	s9,456(sp)
    80004e6e:	6d1e                	ld	s10,448(sp)
    80004e70:	7dfa                	ld	s11,440(sp)
    80004e72:	22010113          	addi	sp,sp,544
    80004e76:	8082                	ret
    end_op();
    80004e78:	fffff097          	auipc	ra,0xfffff
    80004e7c:	49e080e7          	jalr	1182(ra) # 80004316 <end_op>
    return -1;
    80004e80:	557d                	li	a0,-1
    80004e82:	b7f9                	j	80004e50 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e84:	8526                	mv	a0,s1
    80004e86:	ffffd097          	auipc	ra,0xffffd
    80004e8a:	bbc080e7          	jalr	-1092(ra) # 80001a42 <proc_pagetable>
    80004e8e:	8b2a                	mv	s6,a0
    80004e90:	d555                	beqz	a0,80004e3c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e92:	e6842783          	lw	a5,-408(s0)
    80004e96:	e8045703          	lhu	a4,-384(s0)
    80004e9a:	c735                	beqz	a4,80004f06 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e9c:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e9e:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004ea2:	6a05                	lui	s4,0x1
    80004ea4:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004ea8:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004eac:	6d85                	lui	s11,0x1
    80004eae:	7d7d                	lui	s10,0xfffff
    80004eb0:	ac1d                	j	800050e6 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004eb2:	00004517          	auipc	a0,0x4
    80004eb6:	9ee50513          	addi	a0,a0,-1554 # 800088a0 <syscalls+0x290>
    80004eba:	ffffb097          	auipc	ra,0xffffb
    80004ebe:	670080e7          	jalr	1648(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ec2:	874a                	mv	a4,s2
    80004ec4:	009c86bb          	addw	a3,s9,s1
    80004ec8:	4581                	li	a1,0
    80004eca:	8556                	mv	a0,s5
    80004ecc:	fffff097          	auipc	ra,0xfffff
    80004ed0:	ca8080e7          	jalr	-856(ra) # 80003b74 <readi>
    80004ed4:	2501                	sext.w	a0,a0
    80004ed6:	1aa91863          	bne	s2,a0,80005086 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004eda:	009d84bb          	addw	s1,s11,s1
    80004ede:	013d09bb          	addw	s3,s10,s3
    80004ee2:	1f74f263          	bgeu	s1,s7,800050c6 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004ee6:	02049593          	slli	a1,s1,0x20
    80004eea:	9181                	srli	a1,a1,0x20
    80004eec:	95e2                	add	a1,a1,s8
    80004eee:	855a                	mv	a0,s6
    80004ef0:	ffffc097          	auipc	ra,0xffffc
    80004ef4:	15c080e7          	jalr	348(ra) # 8000104c <walkaddr>
    80004ef8:	862a                	mv	a2,a0
    if(pa == 0)
    80004efa:	dd45                	beqz	a0,80004eb2 <exec+0xfe>
      n = PGSIZE;
    80004efc:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004efe:	fd49f2e3          	bgeu	s3,s4,80004ec2 <exec+0x10e>
      n = sz - i;
    80004f02:	894e                	mv	s2,s3
    80004f04:	bf7d                	j	80004ec2 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f06:	4481                	li	s1,0
  iunlockput(ip);
    80004f08:	8556                	mv	a0,s5
    80004f0a:	fffff097          	auipc	ra,0xfffff
    80004f0e:	c18080e7          	jalr	-1000(ra) # 80003b22 <iunlockput>
  end_op();
    80004f12:	fffff097          	auipc	ra,0xfffff
    80004f16:	404080e7          	jalr	1028(ra) # 80004316 <end_op>
  p = myproc();
    80004f1a:	ffffd097          	auipc	ra,0xffffd
    80004f1e:	a64080e7          	jalr	-1436(ra) # 8000197e <myproc>
    80004f22:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f24:	06053d03          	ld	s10,96(a0)
  sz = PGROUNDUP(sz);
    80004f28:	6785                	lui	a5,0x1
    80004f2a:	17fd                	addi	a5,a5,-1
    80004f2c:	94be                	add	s1,s1,a5
    80004f2e:	77fd                	lui	a5,0xfffff
    80004f30:	8fe5                	and	a5,a5,s1
    80004f32:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f36:	6609                	lui	a2,0x2
    80004f38:	963e                	add	a2,a2,a5
    80004f3a:	85be                	mv	a1,a5
    80004f3c:	855a                	mv	a0,s6
    80004f3e:	ffffc097          	auipc	ra,0xffffc
    80004f42:	4b0080e7          	jalr	1200(ra) # 800013ee <uvmalloc>
    80004f46:	8c2a                	mv	s8,a0
  ip = 0;
    80004f48:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f4a:	12050e63          	beqz	a0,80005086 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f4e:	75f9                	lui	a1,0xffffe
    80004f50:	95aa                	add	a1,a1,a0
    80004f52:	855a                	mv	a0,s6
    80004f54:	ffffc097          	auipc	ra,0xffffc
    80004f58:	6b8080e7          	jalr	1720(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80004f5c:	7afd                	lui	s5,0xfffff
    80004f5e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f60:	df043783          	ld	a5,-528(s0)
    80004f64:	6388                	ld	a0,0(a5)
    80004f66:	c925                	beqz	a0,80004fd6 <exec+0x222>
    80004f68:	e8840993          	addi	s3,s0,-376
    80004f6c:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004f70:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f72:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f74:	ffffc097          	auipc	ra,0xffffc
    80004f78:	ece080e7          	jalr	-306(ra) # 80000e42 <strlen>
    80004f7c:	0015079b          	addiw	a5,a0,1
    80004f80:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f84:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f88:	13596363          	bltu	s2,s5,800050ae <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f8c:	df043d83          	ld	s11,-528(s0)
    80004f90:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f94:	8552                	mv	a0,s4
    80004f96:	ffffc097          	auipc	ra,0xffffc
    80004f9a:	eac080e7          	jalr	-340(ra) # 80000e42 <strlen>
    80004f9e:	0015069b          	addiw	a3,a0,1
    80004fa2:	8652                	mv	a2,s4
    80004fa4:	85ca                	mv	a1,s2
    80004fa6:	855a                	mv	a0,s6
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	696080e7          	jalr	1686(ra) # 8000163e <copyout>
    80004fb0:	10054363          	bltz	a0,800050b6 <exec+0x302>
    ustack[argc] = sp;
    80004fb4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fb8:	0485                	addi	s1,s1,1
    80004fba:	008d8793          	addi	a5,s11,8
    80004fbe:	def43823          	sd	a5,-528(s0)
    80004fc2:	008db503          	ld	a0,8(s11)
    80004fc6:	c911                	beqz	a0,80004fda <exec+0x226>
    if(argc >= MAXARG)
    80004fc8:	09a1                	addi	s3,s3,8
    80004fca:	fb3c95e3          	bne	s9,s3,80004f74 <exec+0x1c0>
  sz = sz1;
    80004fce:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fd2:	4a81                	li	s5,0
    80004fd4:	a84d                	j	80005086 <exec+0x2d2>
  sp = sz;
    80004fd6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fd8:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fda:	00349793          	slli	a5,s1,0x3
    80004fde:	f9040713          	addi	a4,s0,-112
    80004fe2:	97ba                	add	a5,a5,a4
    80004fe4:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004fe8:	00148693          	addi	a3,s1,1
    80004fec:	068e                	slli	a3,a3,0x3
    80004fee:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ff2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ff6:	01597663          	bgeu	s2,s5,80005002 <exec+0x24e>
  sz = sz1;
    80004ffa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ffe:	4a81                	li	s5,0
    80005000:	a059                	j	80005086 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005002:	e8840613          	addi	a2,s0,-376
    80005006:	85ca                	mv	a1,s2
    80005008:	855a                	mv	a0,s6
    8000500a:	ffffc097          	auipc	ra,0xffffc
    8000500e:	634080e7          	jalr	1588(ra) # 8000163e <copyout>
    80005012:	0a054663          	bltz	a0,800050be <exec+0x30a>
  p->trapframe->a1 = sp;
    80005016:	070bb783          	ld	a5,112(s7) # 1070 <_entry-0x7fffef90>
    8000501a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000501e:	de843783          	ld	a5,-536(s0)
    80005022:	0007c703          	lbu	a4,0(a5)
    80005026:	cf11                	beqz	a4,80005042 <exec+0x28e>
    80005028:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000502a:	02f00693          	li	a3,47
    8000502e:	a039                	j	8000503c <exec+0x288>
      last = s+1;
    80005030:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005034:	0785                	addi	a5,a5,1
    80005036:	fff7c703          	lbu	a4,-1(a5)
    8000503a:	c701                	beqz	a4,80005042 <exec+0x28e>
    if(*s == '/')
    8000503c:	fed71ce3          	bne	a4,a3,80005034 <exec+0x280>
    80005040:	bfc5                	j	80005030 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005042:	4641                	li	a2,16
    80005044:	de843583          	ld	a1,-536(s0)
    80005048:	170b8513          	addi	a0,s7,368
    8000504c:	ffffc097          	auipc	ra,0xffffc
    80005050:	dc4080e7          	jalr	-572(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005054:	068bb503          	ld	a0,104(s7)
  p->pagetable = pagetable;
    80005058:	076bb423          	sd	s6,104(s7)
  p->sz = sz;
    8000505c:	078bb023          	sd	s8,96(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005060:	070bb783          	ld	a5,112(s7)
    80005064:	e6043703          	ld	a4,-416(s0)
    80005068:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000506a:	070bb783          	ld	a5,112(s7)
    8000506e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005072:	85ea                	mv	a1,s10
    80005074:	ffffd097          	auipc	ra,0xffffd
    80005078:	a6a080e7          	jalr	-1430(ra) # 80001ade <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000507c:	0004851b          	sext.w	a0,s1
    80005080:	bbc1                	j	80004e50 <exec+0x9c>
    80005082:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005086:	df843583          	ld	a1,-520(s0)
    8000508a:	855a                	mv	a0,s6
    8000508c:	ffffd097          	auipc	ra,0xffffd
    80005090:	a52080e7          	jalr	-1454(ra) # 80001ade <proc_freepagetable>
  if(ip){
    80005094:	da0a94e3          	bnez	s5,80004e3c <exec+0x88>
  return -1;
    80005098:	557d                	li	a0,-1
    8000509a:	bb5d                	j	80004e50 <exec+0x9c>
    8000509c:	de943c23          	sd	s1,-520(s0)
    800050a0:	b7dd                	j	80005086 <exec+0x2d2>
    800050a2:	de943c23          	sd	s1,-520(s0)
    800050a6:	b7c5                	j	80005086 <exec+0x2d2>
    800050a8:	de943c23          	sd	s1,-520(s0)
    800050ac:	bfe9                	j	80005086 <exec+0x2d2>
  sz = sz1;
    800050ae:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050b2:	4a81                	li	s5,0
    800050b4:	bfc9                	j	80005086 <exec+0x2d2>
  sz = sz1;
    800050b6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050ba:	4a81                	li	s5,0
    800050bc:	b7e9                	j	80005086 <exec+0x2d2>
  sz = sz1;
    800050be:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050c2:	4a81                	li	s5,0
    800050c4:	b7c9                	j	80005086 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050c6:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050ca:	e0843783          	ld	a5,-504(s0)
    800050ce:	0017869b          	addiw	a3,a5,1
    800050d2:	e0d43423          	sd	a3,-504(s0)
    800050d6:	e0043783          	ld	a5,-512(s0)
    800050da:	0387879b          	addiw	a5,a5,56
    800050de:	e8045703          	lhu	a4,-384(s0)
    800050e2:	e2e6d3e3          	bge	a3,a4,80004f08 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050e6:	2781                	sext.w	a5,a5
    800050e8:	e0f43023          	sd	a5,-512(s0)
    800050ec:	03800713          	li	a4,56
    800050f0:	86be                	mv	a3,a5
    800050f2:	e1040613          	addi	a2,s0,-496
    800050f6:	4581                	li	a1,0
    800050f8:	8556                	mv	a0,s5
    800050fa:	fffff097          	auipc	ra,0xfffff
    800050fe:	a7a080e7          	jalr	-1414(ra) # 80003b74 <readi>
    80005102:	03800793          	li	a5,56
    80005106:	f6f51ee3          	bne	a0,a5,80005082 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000510a:	e1042783          	lw	a5,-496(s0)
    8000510e:	4705                	li	a4,1
    80005110:	fae79de3          	bne	a5,a4,800050ca <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005114:	e3843603          	ld	a2,-456(s0)
    80005118:	e3043783          	ld	a5,-464(s0)
    8000511c:	f8f660e3          	bltu	a2,a5,8000509c <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005120:	e2043783          	ld	a5,-480(s0)
    80005124:	963e                	add	a2,a2,a5
    80005126:	f6f66ee3          	bltu	a2,a5,800050a2 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000512a:	85a6                	mv	a1,s1
    8000512c:	855a                	mv	a0,s6
    8000512e:	ffffc097          	auipc	ra,0xffffc
    80005132:	2c0080e7          	jalr	704(ra) # 800013ee <uvmalloc>
    80005136:	dea43c23          	sd	a0,-520(s0)
    8000513a:	d53d                	beqz	a0,800050a8 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    8000513c:	e2043c03          	ld	s8,-480(s0)
    80005140:	de043783          	ld	a5,-544(s0)
    80005144:	00fc77b3          	and	a5,s8,a5
    80005148:	ff9d                	bnez	a5,80005086 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000514a:	e1842c83          	lw	s9,-488(s0)
    8000514e:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005152:	f60b8ae3          	beqz	s7,800050c6 <exec+0x312>
    80005156:	89de                	mv	s3,s7
    80005158:	4481                	li	s1,0
    8000515a:	b371                	j	80004ee6 <exec+0x132>

000000008000515c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000515c:	7179                	addi	sp,sp,-48
    8000515e:	f406                	sd	ra,40(sp)
    80005160:	f022                	sd	s0,32(sp)
    80005162:	ec26                	sd	s1,24(sp)
    80005164:	e84a                	sd	s2,16(sp)
    80005166:	1800                	addi	s0,sp,48
    80005168:	892e                	mv	s2,a1
    8000516a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000516c:	fdc40593          	addi	a1,s0,-36
    80005170:	ffffe097          	auipc	ra,0xffffe
    80005174:	a74080e7          	jalr	-1420(ra) # 80002be4 <argint>
    80005178:	04054063          	bltz	a0,800051b8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000517c:	fdc42703          	lw	a4,-36(s0)
    80005180:	47bd                	li	a5,15
    80005182:	02e7ed63          	bltu	a5,a4,800051bc <argfd+0x60>
    80005186:	ffffc097          	auipc	ra,0xffffc
    8000518a:	7f8080e7          	jalr	2040(ra) # 8000197e <myproc>
    8000518e:	fdc42703          	lw	a4,-36(s0)
    80005192:	01c70793          	addi	a5,a4,28
    80005196:	078e                	slli	a5,a5,0x3
    80005198:	953e                	add	a0,a0,a5
    8000519a:	651c                	ld	a5,8(a0)
    8000519c:	c395                	beqz	a5,800051c0 <argfd+0x64>
    return -1;
  if(pfd)
    8000519e:	00090463          	beqz	s2,800051a6 <argfd+0x4a>
    *pfd = fd;
    800051a2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051a6:	4501                	li	a0,0
  if(pf)
    800051a8:	c091                	beqz	s1,800051ac <argfd+0x50>
    *pf = f;
    800051aa:	e09c                	sd	a5,0(s1)
}
    800051ac:	70a2                	ld	ra,40(sp)
    800051ae:	7402                	ld	s0,32(sp)
    800051b0:	64e2                	ld	s1,24(sp)
    800051b2:	6942                	ld	s2,16(sp)
    800051b4:	6145                	addi	sp,sp,48
    800051b6:	8082                	ret
    return -1;
    800051b8:	557d                	li	a0,-1
    800051ba:	bfcd                	j	800051ac <argfd+0x50>
    return -1;
    800051bc:	557d                	li	a0,-1
    800051be:	b7fd                	j	800051ac <argfd+0x50>
    800051c0:	557d                	li	a0,-1
    800051c2:	b7ed                	j	800051ac <argfd+0x50>

00000000800051c4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051c4:	1101                	addi	sp,sp,-32
    800051c6:	ec06                	sd	ra,24(sp)
    800051c8:	e822                	sd	s0,16(sp)
    800051ca:	e426                	sd	s1,8(sp)
    800051cc:	1000                	addi	s0,sp,32
    800051ce:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	7ae080e7          	jalr	1966(ra) # 8000197e <myproc>
    800051d8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051da:	0e850793          	addi	a5,a0,232
    800051de:	4501                	li	a0,0
    800051e0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051e2:	6398                	ld	a4,0(a5)
    800051e4:	cb19                	beqz	a4,800051fa <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051e6:	2505                	addiw	a0,a0,1
    800051e8:	07a1                	addi	a5,a5,8
    800051ea:	fed51ce3          	bne	a0,a3,800051e2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051ee:	557d                	li	a0,-1
}
    800051f0:	60e2                	ld	ra,24(sp)
    800051f2:	6442                	ld	s0,16(sp)
    800051f4:	64a2                	ld	s1,8(sp)
    800051f6:	6105                	addi	sp,sp,32
    800051f8:	8082                	ret
      p->ofile[fd] = f;
    800051fa:	01c50793          	addi	a5,a0,28
    800051fe:	078e                	slli	a5,a5,0x3
    80005200:	963e                	add	a2,a2,a5
    80005202:	e604                	sd	s1,8(a2)
      return fd;
    80005204:	b7f5                	j	800051f0 <fdalloc+0x2c>

0000000080005206 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005206:	715d                	addi	sp,sp,-80
    80005208:	e486                	sd	ra,72(sp)
    8000520a:	e0a2                	sd	s0,64(sp)
    8000520c:	fc26                	sd	s1,56(sp)
    8000520e:	f84a                	sd	s2,48(sp)
    80005210:	f44e                	sd	s3,40(sp)
    80005212:	f052                	sd	s4,32(sp)
    80005214:	ec56                	sd	s5,24(sp)
    80005216:	0880                	addi	s0,sp,80
    80005218:	89ae                	mv	s3,a1
    8000521a:	8ab2                	mv	s5,a2
    8000521c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000521e:	fb040593          	addi	a1,s0,-80
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	e72080e7          	jalr	-398(ra) # 80004094 <nameiparent>
    8000522a:	892a                	mv	s2,a0
    8000522c:	12050e63          	beqz	a0,80005368 <create+0x162>
    return 0;

  ilock(dp);
    80005230:	ffffe097          	auipc	ra,0xffffe
    80005234:	690080e7          	jalr	1680(ra) # 800038c0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005238:	4601                	li	a2,0
    8000523a:	fb040593          	addi	a1,s0,-80
    8000523e:	854a                	mv	a0,s2
    80005240:	fffff097          	auipc	ra,0xfffff
    80005244:	b64080e7          	jalr	-1180(ra) # 80003da4 <dirlookup>
    80005248:	84aa                	mv	s1,a0
    8000524a:	c921                	beqz	a0,8000529a <create+0x94>
    iunlockput(dp);
    8000524c:	854a                	mv	a0,s2
    8000524e:	fffff097          	auipc	ra,0xfffff
    80005252:	8d4080e7          	jalr	-1836(ra) # 80003b22 <iunlockput>
    ilock(ip);
    80005256:	8526                	mv	a0,s1
    80005258:	ffffe097          	auipc	ra,0xffffe
    8000525c:	668080e7          	jalr	1640(ra) # 800038c0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005260:	2981                	sext.w	s3,s3
    80005262:	4789                	li	a5,2
    80005264:	02f99463          	bne	s3,a5,8000528c <create+0x86>
    80005268:	0444d783          	lhu	a5,68(s1)
    8000526c:	37f9                	addiw	a5,a5,-2
    8000526e:	17c2                	slli	a5,a5,0x30
    80005270:	93c1                	srli	a5,a5,0x30
    80005272:	4705                	li	a4,1
    80005274:	00f76c63          	bltu	a4,a5,8000528c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005278:	8526                	mv	a0,s1
    8000527a:	60a6                	ld	ra,72(sp)
    8000527c:	6406                	ld	s0,64(sp)
    8000527e:	74e2                	ld	s1,56(sp)
    80005280:	7942                	ld	s2,48(sp)
    80005282:	79a2                	ld	s3,40(sp)
    80005284:	7a02                	ld	s4,32(sp)
    80005286:	6ae2                	ld	s5,24(sp)
    80005288:	6161                	addi	sp,sp,80
    8000528a:	8082                	ret
    iunlockput(ip);
    8000528c:	8526                	mv	a0,s1
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	894080e7          	jalr	-1900(ra) # 80003b22 <iunlockput>
    return 0;
    80005296:	4481                	li	s1,0
    80005298:	b7c5                	j	80005278 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000529a:	85ce                	mv	a1,s3
    8000529c:	00092503          	lw	a0,0(s2)
    800052a0:	ffffe097          	auipc	ra,0xffffe
    800052a4:	488080e7          	jalr	1160(ra) # 80003728 <ialloc>
    800052a8:	84aa                	mv	s1,a0
    800052aa:	c521                	beqz	a0,800052f2 <create+0xec>
  ilock(ip);
    800052ac:	ffffe097          	auipc	ra,0xffffe
    800052b0:	614080e7          	jalr	1556(ra) # 800038c0 <ilock>
  ip->major = major;
    800052b4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052b8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052bc:	4a05                	li	s4,1
    800052be:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800052c2:	8526                	mv	a0,s1
    800052c4:	ffffe097          	auipc	ra,0xffffe
    800052c8:	532080e7          	jalr	1330(ra) # 800037f6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052cc:	2981                	sext.w	s3,s3
    800052ce:	03498a63          	beq	s3,s4,80005302 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800052d2:	40d0                	lw	a2,4(s1)
    800052d4:	fb040593          	addi	a1,s0,-80
    800052d8:	854a                	mv	a0,s2
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	cda080e7          	jalr	-806(ra) # 80003fb4 <dirlink>
    800052e2:	06054b63          	bltz	a0,80005358 <create+0x152>
  iunlockput(dp);
    800052e6:	854a                	mv	a0,s2
    800052e8:	fffff097          	auipc	ra,0xfffff
    800052ec:	83a080e7          	jalr	-1990(ra) # 80003b22 <iunlockput>
  return ip;
    800052f0:	b761                	j	80005278 <create+0x72>
    panic("create: ialloc");
    800052f2:	00003517          	auipc	a0,0x3
    800052f6:	5ce50513          	addi	a0,a0,1486 # 800088c0 <syscalls+0x2b0>
    800052fa:	ffffb097          	auipc	ra,0xffffb
    800052fe:	230080e7          	jalr	560(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005302:	04a95783          	lhu	a5,74(s2)
    80005306:	2785                	addiw	a5,a5,1
    80005308:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000530c:	854a                	mv	a0,s2
    8000530e:	ffffe097          	auipc	ra,0xffffe
    80005312:	4e8080e7          	jalr	1256(ra) # 800037f6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005316:	40d0                	lw	a2,4(s1)
    80005318:	00003597          	auipc	a1,0x3
    8000531c:	5b858593          	addi	a1,a1,1464 # 800088d0 <syscalls+0x2c0>
    80005320:	8526                	mv	a0,s1
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	c92080e7          	jalr	-878(ra) # 80003fb4 <dirlink>
    8000532a:	00054f63          	bltz	a0,80005348 <create+0x142>
    8000532e:	00492603          	lw	a2,4(s2)
    80005332:	00003597          	auipc	a1,0x3
    80005336:	5a658593          	addi	a1,a1,1446 # 800088d8 <syscalls+0x2c8>
    8000533a:	8526                	mv	a0,s1
    8000533c:	fffff097          	auipc	ra,0xfffff
    80005340:	c78080e7          	jalr	-904(ra) # 80003fb4 <dirlink>
    80005344:	f80557e3          	bgez	a0,800052d2 <create+0xcc>
      panic("create dots");
    80005348:	00003517          	auipc	a0,0x3
    8000534c:	59850513          	addi	a0,a0,1432 # 800088e0 <syscalls+0x2d0>
    80005350:	ffffb097          	auipc	ra,0xffffb
    80005354:	1da080e7          	jalr	474(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005358:	00003517          	auipc	a0,0x3
    8000535c:	59850513          	addi	a0,a0,1432 # 800088f0 <syscalls+0x2e0>
    80005360:	ffffb097          	auipc	ra,0xffffb
    80005364:	1ca080e7          	jalr	458(ra) # 8000052a <panic>
    return 0;
    80005368:	84aa                	mv	s1,a0
    8000536a:	b739                	j	80005278 <create+0x72>

000000008000536c <sys_dup>:
{
    8000536c:	7179                	addi	sp,sp,-48
    8000536e:	f406                	sd	ra,40(sp)
    80005370:	f022                	sd	s0,32(sp)
    80005372:	ec26                	sd	s1,24(sp)
    80005374:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005376:	fd840613          	addi	a2,s0,-40
    8000537a:	4581                	li	a1,0
    8000537c:	4501                	li	a0,0
    8000537e:	00000097          	auipc	ra,0x0
    80005382:	dde080e7          	jalr	-546(ra) # 8000515c <argfd>
    return -1;
    80005386:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005388:	02054363          	bltz	a0,800053ae <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000538c:	fd843503          	ld	a0,-40(s0)
    80005390:	00000097          	auipc	ra,0x0
    80005394:	e34080e7          	jalr	-460(ra) # 800051c4 <fdalloc>
    80005398:	84aa                	mv	s1,a0
    return -1;
    8000539a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000539c:	00054963          	bltz	a0,800053ae <sys_dup+0x42>
  filedup(f);
    800053a0:	fd843503          	ld	a0,-40(s0)
    800053a4:	fffff097          	auipc	ra,0xfffff
    800053a8:	36c080e7          	jalr	876(ra) # 80004710 <filedup>
  return fd;
    800053ac:	87a6                	mv	a5,s1
}
    800053ae:	853e                	mv	a0,a5
    800053b0:	70a2                	ld	ra,40(sp)
    800053b2:	7402                	ld	s0,32(sp)
    800053b4:	64e2                	ld	s1,24(sp)
    800053b6:	6145                	addi	sp,sp,48
    800053b8:	8082                	ret

00000000800053ba <sys_read>:
{
    800053ba:	7179                	addi	sp,sp,-48
    800053bc:	f406                	sd	ra,40(sp)
    800053be:	f022                	sd	s0,32(sp)
    800053c0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053c2:	fe840613          	addi	a2,s0,-24
    800053c6:	4581                	li	a1,0
    800053c8:	4501                	li	a0,0
    800053ca:	00000097          	auipc	ra,0x0
    800053ce:	d92080e7          	jalr	-622(ra) # 8000515c <argfd>
    return -1;
    800053d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d4:	04054163          	bltz	a0,80005416 <sys_read+0x5c>
    800053d8:	fe440593          	addi	a1,s0,-28
    800053dc:	4509                	li	a0,2
    800053de:	ffffe097          	auipc	ra,0xffffe
    800053e2:	806080e7          	jalr	-2042(ra) # 80002be4 <argint>
    return -1;
    800053e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e8:	02054763          	bltz	a0,80005416 <sys_read+0x5c>
    800053ec:	fd840593          	addi	a1,s0,-40
    800053f0:	4505                	li	a0,1
    800053f2:	ffffe097          	auipc	ra,0xffffe
    800053f6:	814080e7          	jalr	-2028(ra) # 80002c06 <argaddr>
    return -1;
    800053fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053fc:	00054d63          	bltz	a0,80005416 <sys_read+0x5c>
  return fileread(f, p, n);
    80005400:	fe442603          	lw	a2,-28(s0)
    80005404:	fd843583          	ld	a1,-40(s0)
    80005408:	fe843503          	ld	a0,-24(s0)
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	490080e7          	jalr	1168(ra) # 8000489c <fileread>
    80005414:	87aa                	mv	a5,a0
}
    80005416:	853e                	mv	a0,a5
    80005418:	70a2                	ld	ra,40(sp)
    8000541a:	7402                	ld	s0,32(sp)
    8000541c:	6145                	addi	sp,sp,48
    8000541e:	8082                	ret

0000000080005420 <sys_write>:
{
    80005420:	7179                	addi	sp,sp,-48
    80005422:	f406                	sd	ra,40(sp)
    80005424:	f022                	sd	s0,32(sp)
    80005426:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005428:	fe840613          	addi	a2,s0,-24
    8000542c:	4581                	li	a1,0
    8000542e:	4501                	li	a0,0
    80005430:	00000097          	auipc	ra,0x0
    80005434:	d2c080e7          	jalr	-724(ra) # 8000515c <argfd>
    return -1;
    80005438:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000543a:	04054163          	bltz	a0,8000547c <sys_write+0x5c>
    8000543e:	fe440593          	addi	a1,s0,-28
    80005442:	4509                	li	a0,2
    80005444:	ffffd097          	auipc	ra,0xffffd
    80005448:	7a0080e7          	jalr	1952(ra) # 80002be4 <argint>
    return -1;
    8000544c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000544e:	02054763          	bltz	a0,8000547c <sys_write+0x5c>
    80005452:	fd840593          	addi	a1,s0,-40
    80005456:	4505                	li	a0,1
    80005458:	ffffd097          	auipc	ra,0xffffd
    8000545c:	7ae080e7          	jalr	1966(ra) # 80002c06 <argaddr>
    return -1;
    80005460:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005462:	00054d63          	bltz	a0,8000547c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005466:	fe442603          	lw	a2,-28(s0)
    8000546a:	fd843583          	ld	a1,-40(s0)
    8000546e:	fe843503          	ld	a0,-24(s0)
    80005472:	fffff097          	auipc	ra,0xfffff
    80005476:	4ec080e7          	jalr	1260(ra) # 8000495e <filewrite>
    8000547a:	87aa                	mv	a5,a0
}
    8000547c:	853e                	mv	a0,a5
    8000547e:	70a2                	ld	ra,40(sp)
    80005480:	7402                	ld	s0,32(sp)
    80005482:	6145                	addi	sp,sp,48
    80005484:	8082                	ret

0000000080005486 <sys_close>:
{
    80005486:	1101                	addi	sp,sp,-32
    80005488:	ec06                	sd	ra,24(sp)
    8000548a:	e822                	sd	s0,16(sp)
    8000548c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000548e:	fe040613          	addi	a2,s0,-32
    80005492:	fec40593          	addi	a1,s0,-20
    80005496:	4501                	li	a0,0
    80005498:	00000097          	auipc	ra,0x0
    8000549c:	cc4080e7          	jalr	-828(ra) # 8000515c <argfd>
    return -1;
    800054a0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054a2:	02054463          	bltz	a0,800054ca <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054a6:	ffffc097          	auipc	ra,0xffffc
    800054aa:	4d8080e7          	jalr	1240(ra) # 8000197e <myproc>
    800054ae:	fec42783          	lw	a5,-20(s0)
    800054b2:	07f1                	addi	a5,a5,28
    800054b4:	078e                	slli	a5,a5,0x3
    800054b6:	97aa                	add	a5,a5,a0
    800054b8:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800054bc:	fe043503          	ld	a0,-32(s0)
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	2a2080e7          	jalr	674(ra) # 80004762 <fileclose>
  return 0;
    800054c8:	4781                	li	a5,0
}
    800054ca:	853e                	mv	a0,a5
    800054cc:	60e2                	ld	ra,24(sp)
    800054ce:	6442                	ld	s0,16(sp)
    800054d0:	6105                	addi	sp,sp,32
    800054d2:	8082                	ret

00000000800054d4 <sys_fstat>:
{
    800054d4:	1101                	addi	sp,sp,-32
    800054d6:	ec06                	sd	ra,24(sp)
    800054d8:	e822                	sd	s0,16(sp)
    800054da:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054dc:	fe840613          	addi	a2,s0,-24
    800054e0:	4581                	li	a1,0
    800054e2:	4501                	li	a0,0
    800054e4:	00000097          	auipc	ra,0x0
    800054e8:	c78080e7          	jalr	-904(ra) # 8000515c <argfd>
    return -1;
    800054ec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054ee:	02054563          	bltz	a0,80005518 <sys_fstat+0x44>
    800054f2:	fe040593          	addi	a1,s0,-32
    800054f6:	4505                	li	a0,1
    800054f8:	ffffd097          	auipc	ra,0xffffd
    800054fc:	70e080e7          	jalr	1806(ra) # 80002c06 <argaddr>
    return -1;
    80005500:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005502:	00054b63          	bltz	a0,80005518 <sys_fstat+0x44>
  return filestat(f, st);
    80005506:	fe043583          	ld	a1,-32(s0)
    8000550a:	fe843503          	ld	a0,-24(s0)
    8000550e:	fffff097          	auipc	ra,0xfffff
    80005512:	31c080e7          	jalr	796(ra) # 8000482a <filestat>
    80005516:	87aa                	mv	a5,a0
}
    80005518:	853e                	mv	a0,a5
    8000551a:	60e2                	ld	ra,24(sp)
    8000551c:	6442                	ld	s0,16(sp)
    8000551e:	6105                	addi	sp,sp,32
    80005520:	8082                	ret

0000000080005522 <sys_link>:
{
    80005522:	7169                	addi	sp,sp,-304
    80005524:	f606                	sd	ra,296(sp)
    80005526:	f222                	sd	s0,288(sp)
    80005528:	ee26                	sd	s1,280(sp)
    8000552a:	ea4a                	sd	s2,272(sp)
    8000552c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000552e:	08000613          	li	a2,128
    80005532:	ed040593          	addi	a1,s0,-304
    80005536:	4501                	li	a0,0
    80005538:	ffffd097          	auipc	ra,0xffffd
    8000553c:	6f0080e7          	jalr	1776(ra) # 80002c28 <argstr>
    return -1;
    80005540:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005542:	10054e63          	bltz	a0,8000565e <sys_link+0x13c>
    80005546:	08000613          	li	a2,128
    8000554a:	f5040593          	addi	a1,s0,-176
    8000554e:	4505                	li	a0,1
    80005550:	ffffd097          	auipc	ra,0xffffd
    80005554:	6d8080e7          	jalr	1752(ra) # 80002c28 <argstr>
    return -1;
    80005558:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000555a:	10054263          	bltz	a0,8000565e <sys_link+0x13c>
  begin_op();
    8000555e:	fffff097          	auipc	ra,0xfffff
    80005562:	d38080e7          	jalr	-712(ra) # 80004296 <begin_op>
  if((ip = namei(old)) == 0){
    80005566:	ed040513          	addi	a0,s0,-304
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	b0c080e7          	jalr	-1268(ra) # 80004076 <namei>
    80005572:	84aa                	mv	s1,a0
    80005574:	c551                	beqz	a0,80005600 <sys_link+0xde>
  ilock(ip);
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	34a080e7          	jalr	842(ra) # 800038c0 <ilock>
  if(ip->type == T_DIR){
    8000557e:	04449703          	lh	a4,68(s1)
    80005582:	4785                	li	a5,1
    80005584:	08f70463          	beq	a4,a5,8000560c <sys_link+0xea>
  ip->nlink++;
    80005588:	04a4d783          	lhu	a5,74(s1)
    8000558c:	2785                	addiw	a5,a5,1
    8000558e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005592:	8526                	mv	a0,s1
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	262080e7          	jalr	610(ra) # 800037f6 <iupdate>
  iunlock(ip);
    8000559c:	8526                	mv	a0,s1
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	3e4080e7          	jalr	996(ra) # 80003982 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055a6:	fd040593          	addi	a1,s0,-48
    800055aa:	f5040513          	addi	a0,s0,-176
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	ae6080e7          	jalr	-1306(ra) # 80004094 <nameiparent>
    800055b6:	892a                	mv	s2,a0
    800055b8:	c935                	beqz	a0,8000562c <sys_link+0x10a>
  ilock(dp);
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	306080e7          	jalr	774(ra) # 800038c0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055c2:	00092703          	lw	a4,0(s2)
    800055c6:	409c                	lw	a5,0(s1)
    800055c8:	04f71d63          	bne	a4,a5,80005622 <sys_link+0x100>
    800055cc:	40d0                	lw	a2,4(s1)
    800055ce:	fd040593          	addi	a1,s0,-48
    800055d2:	854a                	mv	a0,s2
    800055d4:	fffff097          	auipc	ra,0xfffff
    800055d8:	9e0080e7          	jalr	-1568(ra) # 80003fb4 <dirlink>
    800055dc:	04054363          	bltz	a0,80005622 <sys_link+0x100>
  iunlockput(dp);
    800055e0:	854a                	mv	a0,s2
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	540080e7          	jalr	1344(ra) # 80003b22 <iunlockput>
  iput(ip);
    800055ea:	8526                	mv	a0,s1
    800055ec:	ffffe097          	auipc	ra,0xffffe
    800055f0:	48e080e7          	jalr	1166(ra) # 80003a7a <iput>
  end_op();
    800055f4:	fffff097          	auipc	ra,0xfffff
    800055f8:	d22080e7          	jalr	-734(ra) # 80004316 <end_op>
  return 0;
    800055fc:	4781                	li	a5,0
    800055fe:	a085                	j	8000565e <sys_link+0x13c>
    end_op();
    80005600:	fffff097          	auipc	ra,0xfffff
    80005604:	d16080e7          	jalr	-746(ra) # 80004316 <end_op>
    return -1;
    80005608:	57fd                	li	a5,-1
    8000560a:	a891                	j	8000565e <sys_link+0x13c>
    iunlockput(ip);
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	514080e7          	jalr	1300(ra) # 80003b22 <iunlockput>
    end_op();
    80005616:	fffff097          	auipc	ra,0xfffff
    8000561a:	d00080e7          	jalr	-768(ra) # 80004316 <end_op>
    return -1;
    8000561e:	57fd                	li	a5,-1
    80005620:	a83d                	j	8000565e <sys_link+0x13c>
    iunlockput(dp);
    80005622:	854a                	mv	a0,s2
    80005624:	ffffe097          	auipc	ra,0xffffe
    80005628:	4fe080e7          	jalr	1278(ra) # 80003b22 <iunlockput>
  ilock(ip);
    8000562c:	8526                	mv	a0,s1
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	292080e7          	jalr	658(ra) # 800038c0 <ilock>
  ip->nlink--;
    80005636:	04a4d783          	lhu	a5,74(s1)
    8000563a:	37fd                	addiw	a5,a5,-1
    8000563c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005640:	8526                	mv	a0,s1
    80005642:	ffffe097          	auipc	ra,0xffffe
    80005646:	1b4080e7          	jalr	436(ra) # 800037f6 <iupdate>
  iunlockput(ip);
    8000564a:	8526                	mv	a0,s1
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	4d6080e7          	jalr	1238(ra) # 80003b22 <iunlockput>
  end_op();
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	cc2080e7          	jalr	-830(ra) # 80004316 <end_op>
  return -1;
    8000565c:	57fd                	li	a5,-1
}
    8000565e:	853e                	mv	a0,a5
    80005660:	70b2                	ld	ra,296(sp)
    80005662:	7412                	ld	s0,288(sp)
    80005664:	64f2                	ld	s1,280(sp)
    80005666:	6952                	ld	s2,272(sp)
    80005668:	6155                	addi	sp,sp,304
    8000566a:	8082                	ret

000000008000566c <sys_unlink>:
{
    8000566c:	7151                	addi	sp,sp,-240
    8000566e:	f586                	sd	ra,232(sp)
    80005670:	f1a2                	sd	s0,224(sp)
    80005672:	eda6                	sd	s1,216(sp)
    80005674:	e9ca                	sd	s2,208(sp)
    80005676:	e5ce                	sd	s3,200(sp)
    80005678:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000567a:	08000613          	li	a2,128
    8000567e:	f3040593          	addi	a1,s0,-208
    80005682:	4501                	li	a0,0
    80005684:	ffffd097          	auipc	ra,0xffffd
    80005688:	5a4080e7          	jalr	1444(ra) # 80002c28 <argstr>
    8000568c:	18054163          	bltz	a0,8000580e <sys_unlink+0x1a2>
  begin_op();
    80005690:	fffff097          	auipc	ra,0xfffff
    80005694:	c06080e7          	jalr	-1018(ra) # 80004296 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005698:	fb040593          	addi	a1,s0,-80
    8000569c:	f3040513          	addi	a0,s0,-208
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	9f4080e7          	jalr	-1548(ra) # 80004094 <nameiparent>
    800056a8:	84aa                	mv	s1,a0
    800056aa:	c979                	beqz	a0,80005780 <sys_unlink+0x114>
  ilock(dp);
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	214080e7          	jalr	532(ra) # 800038c0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056b4:	00003597          	auipc	a1,0x3
    800056b8:	21c58593          	addi	a1,a1,540 # 800088d0 <syscalls+0x2c0>
    800056bc:	fb040513          	addi	a0,s0,-80
    800056c0:	ffffe097          	auipc	ra,0xffffe
    800056c4:	6ca080e7          	jalr	1738(ra) # 80003d8a <namecmp>
    800056c8:	14050a63          	beqz	a0,8000581c <sys_unlink+0x1b0>
    800056cc:	00003597          	auipc	a1,0x3
    800056d0:	20c58593          	addi	a1,a1,524 # 800088d8 <syscalls+0x2c8>
    800056d4:	fb040513          	addi	a0,s0,-80
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	6b2080e7          	jalr	1714(ra) # 80003d8a <namecmp>
    800056e0:	12050e63          	beqz	a0,8000581c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056e4:	f2c40613          	addi	a2,s0,-212
    800056e8:	fb040593          	addi	a1,s0,-80
    800056ec:	8526                	mv	a0,s1
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	6b6080e7          	jalr	1718(ra) # 80003da4 <dirlookup>
    800056f6:	892a                	mv	s2,a0
    800056f8:	12050263          	beqz	a0,8000581c <sys_unlink+0x1b0>
  ilock(ip);
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	1c4080e7          	jalr	452(ra) # 800038c0 <ilock>
  if(ip->nlink < 1)
    80005704:	04a91783          	lh	a5,74(s2)
    80005708:	08f05263          	blez	a5,8000578c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000570c:	04491703          	lh	a4,68(s2)
    80005710:	4785                	li	a5,1
    80005712:	08f70563          	beq	a4,a5,8000579c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005716:	4641                	li	a2,16
    80005718:	4581                	li	a1,0
    8000571a:	fc040513          	addi	a0,s0,-64
    8000571e:	ffffb097          	auipc	ra,0xffffb
    80005722:	5a0080e7          	jalr	1440(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005726:	4741                	li	a4,16
    80005728:	f2c42683          	lw	a3,-212(s0)
    8000572c:	fc040613          	addi	a2,s0,-64
    80005730:	4581                	li	a1,0
    80005732:	8526                	mv	a0,s1
    80005734:	ffffe097          	auipc	ra,0xffffe
    80005738:	538080e7          	jalr	1336(ra) # 80003c6c <writei>
    8000573c:	47c1                	li	a5,16
    8000573e:	0af51563          	bne	a0,a5,800057e8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005742:	04491703          	lh	a4,68(s2)
    80005746:	4785                	li	a5,1
    80005748:	0af70863          	beq	a4,a5,800057f8 <sys_unlink+0x18c>
  iunlockput(dp);
    8000574c:	8526                	mv	a0,s1
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	3d4080e7          	jalr	980(ra) # 80003b22 <iunlockput>
  ip->nlink--;
    80005756:	04a95783          	lhu	a5,74(s2)
    8000575a:	37fd                	addiw	a5,a5,-1
    8000575c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005760:	854a                	mv	a0,s2
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	094080e7          	jalr	148(ra) # 800037f6 <iupdate>
  iunlockput(ip);
    8000576a:	854a                	mv	a0,s2
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	3b6080e7          	jalr	950(ra) # 80003b22 <iunlockput>
  end_op();
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	ba2080e7          	jalr	-1118(ra) # 80004316 <end_op>
  return 0;
    8000577c:	4501                	li	a0,0
    8000577e:	a84d                	j	80005830 <sys_unlink+0x1c4>
    end_op();
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	b96080e7          	jalr	-1130(ra) # 80004316 <end_op>
    return -1;
    80005788:	557d                	li	a0,-1
    8000578a:	a05d                	j	80005830 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000578c:	00003517          	auipc	a0,0x3
    80005790:	17450513          	addi	a0,a0,372 # 80008900 <syscalls+0x2f0>
    80005794:	ffffb097          	auipc	ra,0xffffb
    80005798:	d96080e7          	jalr	-618(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000579c:	04c92703          	lw	a4,76(s2)
    800057a0:	02000793          	li	a5,32
    800057a4:	f6e7f9e3          	bgeu	a5,a4,80005716 <sys_unlink+0xaa>
    800057a8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057ac:	4741                	li	a4,16
    800057ae:	86ce                	mv	a3,s3
    800057b0:	f1840613          	addi	a2,s0,-232
    800057b4:	4581                	li	a1,0
    800057b6:	854a                	mv	a0,s2
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	3bc080e7          	jalr	956(ra) # 80003b74 <readi>
    800057c0:	47c1                	li	a5,16
    800057c2:	00f51b63          	bne	a0,a5,800057d8 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057c6:	f1845783          	lhu	a5,-232(s0)
    800057ca:	e7a1                	bnez	a5,80005812 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057cc:	29c1                	addiw	s3,s3,16
    800057ce:	04c92783          	lw	a5,76(s2)
    800057d2:	fcf9ede3          	bltu	s3,a5,800057ac <sys_unlink+0x140>
    800057d6:	b781                	j	80005716 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057d8:	00003517          	auipc	a0,0x3
    800057dc:	14050513          	addi	a0,a0,320 # 80008918 <syscalls+0x308>
    800057e0:	ffffb097          	auipc	ra,0xffffb
    800057e4:	d4a080e7          	jalr	-694(ra) # 8000052a <panic>
    panic("unlink: writei");
    800057e8:	00003517          	auipc	a0,0x3
    800057ec:	14850513          	addi	a0,a0,328 # 80008930 <syscalls+0x320>
    800057f0:	ffffb097          	auipc	ra,0xffffb
    800057f4:	d3a080e7          	jalr	-710(ra) # 8000052a <panic>
    dp->nlink--;
    800057f8:	04a4d783          	lhu	a5,74(s1)
    800057fc:	37fd                	addiw	a5,a5,-1
    800057fe:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005802:	8526                	mv	a0,s1
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	ff2080e7          	jalr	-14(ra) # 800037f6 <iupdate>
    8000580c:	b781                	j	8000574c <sys_unlink+0xe0>
    return -1;
    8000580e:	557d                	li	a0,-1
    80005810:	a005                	j	80005830 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005812:	854a                	mv	a0,s2
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	30e080e7          	jalr	782(ra) # 80003b22 <iunlockput>
  iunlockput(dp);
    8000581c:	8526                	mv	a0,s1
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	304080e7          	jalr	772(ra) # 80003b22 <iunlockput>
  end_op();
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	af0080e7          	jalr	-1296(ra) # 80004316 <end_op>
  return -1;
    8000582e:	557d                	li	a0,-1
}
    80005830:	70ae                	ld	ra,232(sp)
    80005832:	740e                	ld	s0,224(sp)
    80005834:	64ee                	ld	s1,216(sp)
    80005836:	694e                	ld	s2,208(sp)
    80005838:	69ae                	ld	s3,200(sp)
    8000583a:	616d                	addi	sp,sp,240
    8000583c:	8082                	ret

000000008000583e <sys_open>:

uint64
sys_open(void)
{
    8000583e:	7131                	addi	sp,sp,-192
    80005840:	fd06                	sd	ra,184(sp)
    80005842:	f922                	sd	s0,176(sp)
    80005844:	f526                	sd	s1,168(sp)
    80005846:	f14a                	sd	s2,160(sp)
    80005848:	ed4e                	sd	s3,152(sp)
    8000584a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000584c:	08000613          	li	a2,128
    80005850:	f5040593          	addi	a1,s0,-176
    80005854:	4501                	li	a0,0
    80005856:	ffffd097          	auipc	ra,0xffffd
    8000585a:	3d2080e7          	jalr	978(ra) # 80002c28 <argstr>
    return -1;
    8000585e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005860:	0c054163          	bltz	a0,80005922 <sys_open+0xe4>
    80005864:	f4c40593          	addi	a1,s0,-180
    80005868:	4505                	li	a0,1
    8000586a:	ffffd097          	auipc	ra,0xffffd
    8000586e:	37a080e7          	jalr	890(ra) # 80002be4 <argint>
    80005872:	0a054863          	bltz	a0,80005922 <sys_open+0xe4>

  begin_op();
    80005876:	fffff097          	auipc	ra,0xfffff
    8000587a:	a20080e7          	jalr	-1504(ra) # 80004296 <begin_op>

  if(omode & O_CREATE){
    8000587e:	f4c42783          	lw	a5,-180(s0)
    80005882:	2007f793          	andi	a5,a5,512
    80005886:	cbdd                	beqz	a5,8000593c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005888:	4681                	li	a3,0
    8000588a:	4601                	li	a2,0
    8000588c:	4589                	li	a1,2
    8000588e:	f5040513          	addi	a0,s0,-176
    80005892:	00000097          	auipc	ra,0x0
    80005896:	974080e7          	jalr	-1676(ra) # 80005206 <create>
    8000589a:	892a                	mv	s2,a0
    if(ip == 0){
    8000589c:	c959                	beqz	a0,80005932 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000589e:	04491703          	lh	a4,68(s2)
    800058a2:	478d                	li	a5,3
    800058a4:	00f71763          	bne	a4,a5,800058b2 <sys_open+0x74>
    800058a8:	04695703          	lhu	a4,70(s2)
    800058ac:	47a5                	li	a5,9
    800058ae:	0ce7ec63          	bltu	a5,a4,80005986 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	df4080e7          	jalr	-524(ra) # 800046a6 <filealloc>
    800058ba:	89aa                	mv	s3,a0
    800058bc:	10050263          	beqz	a0,800059c0 <sys_open+0x182>
    800058c0:	00000097          	auipc	ra,0x0
    800058c4:	904080e7          	jalr	-1788(ra) # 800051c4 <fdalloc>
    800058c8:	84aa                	mv	s1,a0
    800058ca:	0e054663          	bltz	a0,800059b6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058ce:	04491703          	lh	a4,68(s2)
    800058d2:	478d                	li	a5,3
    800058d4:	0cf70463          	beq	a4,a5,8000599c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058d8:	4789                	li	a5,2
    800058da:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058de:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058e2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058e6:	f4c42783          	lw	a5,-180(s0)
    800058ea:	0017c713          	xori	a4,a5,1
    800058ee:	8b05                	andi	a4,a4,1
    800058f0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058f4:	0037f713          	andi	a4,a5,3
    800058f8:	00e03733          	snez	a4,a4
    800058fc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005900:	4007f793          	andi	a5,a5,1024
    80005904:	c791                	beqz	a5,80005910 <sys_open+0xd2>
    80005906:	04491703          	lh	a4,68(s2)
    8000590a:	4789                	li	a5,2
    8000590c:	08f70f63          	beq	a4,a5,800059aa <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005910:	854a                	mv	a0,s2
    80005912:	ffffe097          	auipc	ra,0xffffe
    80005916:	070080e7          	jalr	112(ra) # 80003982 <iunlock>
  end_op();
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	9fc080e7          	jalr	-1540(ra) # 80004316 <end_op>

  return fd;
}
    80005922:	8526                	mv	a0,s1
    80005924:	70ea                	ld	ra,184(sp)
    80005926:	744a                	ld	s0,176(sp)
    80005928:	74aa                	ld	s1,168(sp)
    8000592a:	790a                	ld	s2,160(sp)
    8000592c:	69ea                	ld	s3,152(sp)
    8000592e:	6129                	addi	sp,sp,192
    80005930:	8082                	ret
      end_op();
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	9e4080e7          	jalr	-1564(ra) # 80004316 <end_op>
      return -1;
    8000593a:	b7e5                	j	80005922 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000593c:	f5040513          	addi	a0,s0,-176
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	736080e7          	jalr	1846(ra) # 80004076 <namei>
    80005948:	892a                	mv	s2,a0
    8000594a:	c905                	beqz	a0,8000597a <sys_open+0x13c>
    ilock(ip);
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	f74080e7          	jalr	-140(ra) # 800038c0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005954:	04491703          	lh	a4,68(s2)
    80005958:	4785                	li	a5,1
    8000595a:	f4f712e3          	bne	a4,a5,8000589e <sys_open+0x60>
    8000595e:	f4c42783          	lw	a5,-180(s0)
    80005962:	dba1                	beqz	a5,800058b2 <sys_open+0x74>
      iunlockput(ip);
    80005964:	854a                	mv	a0,s2
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	1bc080e7          	jalr	444(ra) # 80003b22 <iunlockput>
      end_op();
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	9a8080e7          	jalr	-1624(ra) # 80004316 <end_op>
      return -1;
    80005976:	54fd                	li	s1,-1
    80005978:	b76d                	j	80005922 <sys_open+0xe4>
      end_op();
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	99c080e7          	jalr	-1636(ra) # 80004316 <end_op>
      return -1;
    80005982:	54fd                	li	s1,-1
    80005984:	bf79                	j	80005922 <sys_open+0xe4>
    iunlockput(ip);
    80005986:	854a                	mv	a0,s2
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	19a080e7          	jalr	410(ra) # 80003b22 <iunlockput>
    end_op();
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	986080e7          	jalr	-1658(ra) # 80004316 <end_op>
    return -1;
    80005998:	54fd                	li	s1,-1
    8000599a:	b761                	j	80005922 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000599c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059a0:	04691783          	lh	a5,70(s2)
    800059a4:	02f99223          	sh	a5,36(s3)
    800059a8:	bf2d                	j	800058e2 <sys_open+0xa4>
    itrunc(ip);
    800059aa:	854a                	mv	a0,s2
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	022080e7          	jalr	34(ra) # 800039ce <itrunc>
    800059b4:	bfb1                	j	80005910 <sys_open+0xd2>
      fileclose(f);
    800059b6:	854e                	mv	a0,s3
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	daa080e7          	jalr	-598(ra) # 80004762 <fileclose>
    iunlockput(ip);
    800059c0:	854a                	mv	a0,s2
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	160080e7          	jalr	352(ra) # 80003b22 <iunlockput>
    end_op();
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	94c080e7          	jalr	-1716(ra) # 80004316 <end_op>
    return -1;
    800059d2:	54fd                	li	s1,-1
    800059d4:	b7b9                	j	80005922 <sys_open+0xe4>

00000000800059d6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059d6:	7175                	addi	sp,sp,-144
    800059d8:	e506                	sd	ra,136(sp)
    800059da:	e122                	sd	s0,128(sp)
    800059dc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059de:	fffff097          	auipc	ra,0xfffff
    800059e2:	8b8080e7          	jalr	-1864(ra) # 80004296 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059e6:	08000613          	li	a2,128
    800059ea:	f7040593          	addi	a1,s0,-144
    800059ee:	4501                	li	a0,0
    800059f0:	ffffd097          	auipc	ra,0xffffd
    800059f4:	238080e7          	jalr	568(ra) # 80002c28 <argstr>
    800059f8:	02054963          	bltz	a0,80005a2a <sys_mkdir+0x54>
    800059fc:	4681                	li	a3,0
    800059fe:	4601                	li	a2,0
    80005a00:	4585                	li	a1,1
    80005a02:	f7040513          	addi	a0,s0,-144
    80005a06:	00000097          	auipc	ra,0x0
    80005a0a:	800080e7          	jalr	-2048(ra) # 80005206 <create>
    80005a0e:	cd11                	beqz	a0,80005a2a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	112080e7          	jalr	274(ra) # 80003b22 <iunlockput>
  end_op();
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	8fe080e7          	jalr	-1794(ra) # 80004316 <end_op>
  return 0;
    80005a20:	4501                	li	a0,0
}
    80005a22:	60aa                	ld	ra,136(sp)
    80005a24:	640a                	ld	s0,128(sp)
    80005a26:	6149                	addi	sp,sp,144
    80005a28:	8082                	ret
    end_op();
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	8ec080e7          	jalr	-1812(ra) # 80004316 <end_op>
    return -1;
    80005a32:	557d                	li	a0,-1
    80005a34:	b7fd                	j	80005a22 <sys_mkdir+0x4c>

0000000080005a36 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a36:	7135                	addi	sp,sp,-160
    80005a38:	ed06                	sd	ra,152(sp)
    80005a3a:	e922                	sd	s0,144(sp)
    80005a3c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a3e:	fffff097          	auipc	ra,0xfffff
    80005a42:	858080e7          	jalr	-1960(ra) # 80004296 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a46:	08000613          	li	a2,128
    80005a4a:	f7040593          	addi	a1,s0,-144
    80005a4e:	4501                	li	a0,0
    80005a50:	ffffd097          	auipc	ra,0xffffd
    80005a54:	1d8080e7          	jalr	472(ra) # 80002c28 <argstr>
    80005a58:	04054a63          	bltz	a0,80005aac <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a5c:	f6c40593          	addi	a1,s0,-148
    80005a60:	4505                	li	a0,1
    80005a62:	ffffd097          	auipc	ra,0xffffd
    80005a66:	182080e7          	jalr	386(ra) # 80002be4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a6a:	04054163          	bltz	a0,80005aac <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a6e:	f6840593          	addi	a1,s0,-152
    80005a72:	4509                	li	a0,2
    80005a74:	ffffd097          	auipc	ra,0xffffd
    80005a78:	170080e7          	jalr	368(ra) # 80002be4 <argint>
     argint(1, &major) < 0 ||
    80005a7c:	02054863          	bltz	a0,80005aac <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a80:	f6841683          	lh	a3,-152(s0)
    80005a84:	f6c41603          	lh	a2,-148(s0)
    80005a88:	458d                	li	a1,3
    80005a8a:	f7040513          	addi	a0,s0,-144
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	778080e7          	jalr	1912(ra) # 80005206 <create>
     argint(2, &minor) < 0 ||
    80005a96:	c919                	beqz	a0,80005aac <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	08a080e7          	jalr	138(ra) # 80003b22 <iunlockput>
  end_op();
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	876080e7          	jalr	-1930(ra) # 80004316 <end_op>
  return 0;
    80005aa8:	4501                	li	a0,0
    80005aaa:	a031                	j	80005ab6 <sys_mknod+0x80>
    end_op();
    80005aac:	fffff097          	auipc	ra,0xfffff
    80005ab0:	86a080e7          	jalr	-1942(ra) # 80004316 <end_op>
    return -1;
    80005ab4:	557d                	li	a0,-1
}
    80005ab6:	60ea                	ld	ra,152(sp)
    80005ab8:	644a                	ld	s0,144(sp)
    80005aba:	610d                	addi	sp,sp,160
    80005abc:	8082                	ret

0000000080005abe <sys_chdir>:

uint64
sys_chdir(void)
{
    80005abe:	7135                	addi	sp,sp,-160
    80005ac0:	ed06                	sd	ra,152(sp)
    80005ac2:	e922                	sd	s0,144(sp)
    80005ac4:	e526                	sd	s1,136(sp)
    80005ac6:	e14a                	sd	s2,128(sp)
    80005ac8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005aca:	ffffc097          	auipc	ra,0xffffc
    80005ace:	eb4080e7          	jalr	-332(ra) # 8000197e <myproc>
    80005ad2:	892a                	mv	s2,a0
  
  begin_op();
    80005ad4:	ffffe097          	auipc	ra,0xffffe
    80005ad8:	7c2080e7          	jalr	1986(ra) # 80004296 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005adc:	08000613          	li	a2,128
    80005ae0:	f6040593          	addi	a1,s0,-160
    80005ae4:	4501                	li	a0,0
    80005ae6:	ffffd097          	auipc	ra,0xffffd
    80005aea:	142080e7          	jalr	322(ra) # 80002c28 <argstr>
    80005aee:	04054b63          	bltz	a0,80005b44 <sys_chdir+0x86>
    80005af2:	f6040513          	addi	a0,s0,-160
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	580080e7          	jalr	1408(ra) # 80004076 <namei>
    80005afe:	84aa                	mv	s1,a0
    80005b00:	c131                	beqz	a0,80005b44 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	dbe080e7          	jalr	-578(ra) # 800038c0 <ilock>
  if(ip->type != T_DIR){
    80005b0a:	04449703          	lh	a4,68(s1)
    80005b0e:	4785                	li	a5,1
    80005b10:	04f71063          	bne	a4,a5,80005b50 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b14:	8526                	mv	a0,s1
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	e6c080e7          	jalr	-404(ra) # 80003982 <iunlock>
  iput(p->cwd);
    80005b1e:	16893503          	ld	a0,360(s2)
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	f58080e7          	jalr	-168(ra) # 80003a7a <iput>
  end_op();
    80005b2a:	ffffe097          	auipc	ra,0xffffe
    80005b2e:	7ec080e7          	jalr	2028(ra) # 80004316 <end_op>
  p->cwd = ip;
    80005b32:	16993423          	sd	s1,360(s2)
  return 0;
    80005b36:	4501                	li	a0,0
}
    80005b38:	60ea                	ld	ra,152(sp)
    80005b3a:	644a                	ld	s0,144(sp)
    80005b3c:	64aa                	ld	s1,136(sp)
    80005b3e:	690a                	ld	s2,128(sp)
    80005b40:	610d                	addi	sp,sp,160
    80005b42:	8082                	ret
    end_op();
    80005b44:	ffffe097          	auipc	ra,0xffffe
    80005b48:	7d2080e7          	jalr	2002(ra) # 80004316 <end_op>
    return -1;
    80005b4c:	557d                	li	a0,-1
    80005b4e:	b7ed                	j	80005b38 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b50:	8526                	mv	a0,s1
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	fd0080e7          	jalr	-48(ra) # 80003b22 <iunlockput>
    end_op();
    80005b5a:	ffffe097          	auipc	ra,0xffffe
    80005b5e:	7bc080e7          	jalr	1980(ra) # 80004316 <end_op>
    return -1;
    80005b62:	557d                	li	a0,-1
    80005b64:	bfd1                	j	80005b38 <sys_chdir+0x7a>

0000000080005b66 <sys_exec>:

uint64
sys_exec(void)
{
    80005b66:	7145                	addi	sp,sp,-464
    80005b68:	e786                	sd	ra,456(sp)
    80005b6a:	e3a2                	sd	s0,448(sp)
    80005b6c:	ff26                	sd	s1,440(sp)
    80005b6e:	fb4a                	sd	s2,432(sp)
    80005b70:	f74e                	sd	s3,424(sp)
    80005b72:	f352                	sd	s4,416(sp)
    80005b74:	ef56                	sd	s5,408(sp)
    80005b76:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b78:	08000613          	li	a2,128
    80005b7c:	f4040593          	addi	a1,s0,-192
    80005b80:	4501                	li	a0,0
    80005b82:	ffffd097          	auipc	ra,0xffffd
    80005b86:	0a6080e7          	jalr	166(ra) # 80002c28 <argstr>
    return -1;
    80005b8a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b8c:	0c054a63          	bltz	a0,80005c60 <sys_exec+0xfa>
    80005b90:	e3840593          	addi	a1,s0,-456
    80005b94:	4505                	li	a0,1
    80005b96:	ffffd097          	auipc	ra,0xffffd
    80005b9a:	070080e7          	jalr	112(ra) # 80002c06 <argaddr>
    80005b9e:	0c054163          	bltz	a0,80005c60 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ba2:	10000613          	li	a2,256
    80005ba6:	4581                	li	a1,0
    80005ba8:	e4040513          	addi	a0,s0,-448
    80005bac:	ffffb097          	auipc	ra,0xffffb
    80005bb0:	112080e7          	jalr	274(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bb4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bb8:	89a6                	mv	s3,s1
    80005bba:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bbc:	02000a13          	li	s4,32
    80005bc0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bc4:	00391793          	slli	a5,s2,0x3
    80005bc8:	e3040593          	addi	a1,s0,-464
    80005bcc:	e3843503          	ld	a0,-456(s0)
    80005bd0:	953e                	add	a0,a0,a5
    80005bd2:	ffffd097          	auipc	ra,0xffffd
    80005bd6:	f78080e7          	jalr	-136(ra) # 80002b4a <fetchaddr>
    80005bda:	02054a63          	bltz	a0,80005c0e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005bde:	e3043783          	ld	a5,-464(s0)
    80005be2:	c3b9                	beqz	a5,80005c28 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005be4:	ffffb097          	auipc	ra,0xffffb
    80005be8:	eee080e7          	jalr	-274(ra) # 80000ad2 <kalloc>
    80005bec:	85aa                	mv	a1,a0
    80005bee:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bf2:	cd11                	beqz	a0,80005c0e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bf4:	6605                	lui	a2,0x1
    80005bf6:	e3043503          	ld	a0,-464(s0)
    80005bfa:	ffffd097          	auipc	ra,0xffffd
    80005bfe:	fa2080e7          	jalr	-94(ra) # 80002b9c <fetchstr>
    80005c02:	00054663          	bltz	a0,80005c0e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c06:	0905                	addi	s2,s2,1
    80005c08:	09a1                	addi	s3,s3,8
    80005c0a:	fb491be3          	bne	s2,s4,80005bc0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c0e:	10048913          	addi	s2,s1,256
    80005c12:	6088                	ld	a0,0(s1)
    80005c14:	c529                	beqz	a0,80005c5e <sys_exec+0xf8>
    kfree(argv[i]);
    80005c16:	ffffb097          	auipc	ra,0xffffb
    80005c1a:	dc0080e7          	jalr	-576(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c1e:	04a1                	addi	s1,s1,8
    80005c20:	ff2499e3          	bne	s1,s2,80005c12 <sys_exec+0xac>
  return -1;
    80005c24:	597d                	li	s2,-1
    80005c26:	a82d                	j	80005c60 <sys_exec+0xfa>
      argv[i] = 0;
    80005c28:	0a8e                	slli	s5,s5,0x3
    80005c2a:	fc040793          	addi	a5,s0,-64
    80005c2e:	9abe                	add	s5,s5,a5
    80005c30:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005c34:	e4040593          	addi	a1,s0,-448
    80005c38:	f4040513          	addi	a0,s0,-192
    80005c3c:	fffff097          	auipc	ra,0xfffff
    80005c40:	178080e7          	jalr	376(ra) # 80004db4 <exec>
    80005c44:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c46:	10048993          	addi	s3,s1,256
    80005c4a:	6088                	ld	a0,0(s1)
    80005c4c:	c911                	beqz	a0,80005c60 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c4e:	ffffb097          	auipc	ra,0xffffb
    80005c52:	d88080e7          	jalr	-632(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c56:	04a1                	addi	s1,s1,8
    80005c58:	ff3499e3          	bne	s1,s3,80005c4a <sys_exec+0xe4>
    80005c5c:	a011                	j	80005c60 <sys_exec+0xfa>
  return -1;
    80005c5e:	597d                	li	s2,-1
}
    80005c60:	854a                	mv	a0,s2
    80005c62:	60be                	ld	ra,456(sp)
    80005c64:	641e                	ld	s0,448(sp)
    80005c66:	74fa                	ld	s1,440(sp)
    80005c68:	795a                	ld	s2,432(sp)
    80005c6a:	79ba                	ld	s3,424(sp)
    80005c6c:	7a1a                	ld	s4,416(sp)
    80005c6e:	6afa                	ld	s5,408(sp)
    80005c70:	6179                	addi	sp,sp,464
    80005c72:	8082                	ret

0000000080005c74 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c74:	7139                	addi	sp,sp,-64
    80005c76:	fc06                	sd	ra,56(sp)
    80005c78:	f822                	sd	s0,48(sp)
    80005c7a:	f426                	sd	s1,40(sp)
    80005c7c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c7e:	ffffc097          	auipc	ra,0xffffc
    80005c82:	d00080e7          	jalr	-768(ra) # 8000197e <myproc>
    80005c86:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c88:	fd840593          	addi	a1,s0,-40
    80005c8c:	4501                	li	a0,0
    80005c8e:	ffffd097          	auipc	ra,0xffffd
    80005c92:	f78080e7          	jalr	-136(ra) # 80002c06 <argaddr>
    return -1;
    80005c96:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c98:	0e054063          	bltz	a0,80005d78 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c9c:	fc840593          	addi	a1,s0,-56
    80005ca0:	fd040513          	addi	a0,s0,-48
    80005ca4:	fffff097          	auipc	ra,0xfffff
    80005ca8:	dee080e7          	jalr	-530(ra) # 80004a92 <pipealloc>
    return -1;
    80005cac:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cae:	0c054563          	bltz	a0,80005d78 <sys_pipe+0x104>
  fd0 = -1;
    80005cb2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cb6:	fd043503          	ld	a0,-48(s0)
    80005cba:	fffff097          	auipc	ra,0xfffff
    80005cbe:	50a080e7          	jalr	1290(ra) # 800051c4 <fdalloc>
    80005cc2:	fca42223          	sw	a0,-60(s0)
    80005cc6:	08054c63          	bltz	a0,80005d5e <sys_pipe+0xea>
    80005cca:	fc843503          	ld	a0,-56(s0)
    80005cce:	fffff097          	auipc	ra,0xfffff
    80005cd2:	4f6080e7          	jalr	1270(ra) # 800051c4 <fdalloc>
    80005cd6:	fca42023          	sw	a0,-64(s0)
    80005cda:	06054863          	bltz	a0,80005d4a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cde:	4691                	li	a3,4
    80005ce0:	fc440613          	addi	a2,s0,-60
    80005ce4:	fd843583          	ld	a1,-40(s0)
    80005ce8:	74a8                	ld	a0,104(s1)
    80005cea:	ffffc097          	auipc	ra,0xffffc
    80005cee:	954080e7          	jalr	-1708(ra) # 8000163e <copyout>
    80005cf2:	02054063          	bltz	a0,80005d12 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cf6:	4691                	li	a3,4
    80005cf8:	fc040613          	addi	a2,s0,-64
    80005cfc:	fd843583          	ld	a1,-40(s0)
    80005d00:	0591                	addi	a1,a1,4
    80005d02:	74a8                	ld	a0,104(s1)
    80005d04:	ffffc097          	auipc	ra,0xffffc
    80005d08:	93a080e7          	jalr	-1734(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d0c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d0e:	06055563          	bgez	a0,80005d78 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d12:	fc442783          	lw	a5,-60(s0)
    80005d16:	07f1                	addi	a5,a5,28
    80005d18:	078e                	slli	a5,a5,0x3
    80005d1a:	97a6                	add	a5,a5,s1
    80005d1c:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005d20:	fc042503          	lw	a0,-64(s0)
    80005d24:	0571                	addi	a0,a0,28
    80005d26:	050e                	slli	a0,a0,0x3
    80005d28:	9526                	add	a0,a0,s1
    80005d2a:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005d2e:	fd043503          	ld	a0,-48(s0)
    80005d32:	fffff097          	auipc	ra,0xfffff
    80005d36:	a30080e7          	jalr	-1488(ra) # 80004762 <fileclose>
    fileclose(wf);
    80005d3a:	fc843503          	ld	a0,-56(s0)
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	a24080e7          	jalr	-1500(ra) # 80004762 <fileclose>
    return -1;
    80005d46:	57fd                	li	a5,-1
    80005d48:	a805                	j	80005d78 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d4a:	fc442783          	lw	a5,-60(s0)
    80005d4e:	0007c863          	bltz	a5,80005d5e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d52:	01c78513          	addi	a0,a5,28
    80005d56:	050e                	slli	a0,a0,0x3
    80005d58:	9526                	add	a0,a0,s1
    80005d5a:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005d5e:	fd043503          	ld	a0,-48(s0)
    80005d62:	fffff097          	auipc	ra,0xfffff
    80005d66:	a00080e7          	jalr	-1536(ra) # 80004762 <fileclose>
    fileclose(wf);
    80005d6a:	fc843503          	ld	a0,-56(s0)
    80005d6e:	fffff097          	auipc	ra,0xfffff
    80005d72:	9f4080e7          	jalr	-1548(ra) # 80004762 <fileclose>
    return -1;
    80005d76:	57fd                	li	a5,-1
}
    80005d78:	853e                	mv	a0,a5
    80005d7a:	70e2                	ld	ra,56(sp)
    80005d7c:	7442                	ld	s0,48(sp)
    80005d7e:	74a2                	ld	s1,40(sp)
    80005d80:	6121                	addi	sp,sp,64
    80005d82:	8082                	ret
	...

0000000080005d90 <kernelvec>:
    80005d90:	7111                	addi	sp,sp,-256
    80005d92:	e006                	sd	ra,0(sp)
    80005d94:	e40a                	sd	sp,8(sp)
    80005d96:	e80e                	sd	gp,16(sp)
    80005d98:	ec12                	sd	tp,24(sp)
    80005d9a:	f016                	sd	t0,32(sp)
    80005d9c:	f41a                	sd	t1,40(sp)
    80005d9e:	f81e                	sd	t2,48(sp)
    80005da0:	fc22                	sd	s0,56(sp)
    80005da2:	e0a6                	sd	s1,64(sp)
    80005da4:	e4aa                	sd	a0,72(sp)
    80005da6:	e8ae                	sd	a1,80(sp)
    80005da8:	ecb2                	sd	a2,88(sp)
    80005daa:	f0b6                	sd	a3,96(sp)
    80005dac:	f4ba                	sd	a4,104(sp)
    80005dae:	f8be                	sd	a5,112(sp)
    80005db0:	fcc2                	sd	a6,120(sp)
    80005db2:	e146                	sd	a7,128(sp)
    80005db4:	e54a                	sd	s2,136(sp)
    80005db6:	e94e                	sd	s3,144(sp)
    80005db8:	ed52                	sd	s4,152(sp)
    80005dba:	f156                	sd	s5,160(sp)
    80005dbc:	f55a                	sd	s6,168(sp)
    80005dbe:	f95e                	sd	s7,176(sp)
    80005dc0:	fd62                	sd	s8,184(sp)
    80005dc2:	e1e6                	sd	s9,192(sp)
    80005dc4:	e5ea                	sd	s10,200(sp)
    80005dc6:	e9ee                	sd	s11,208(sp)
    80005dc8:	edf2                	sd	t3,216(sp)
    80005dca:	f1f6                	sd	t4,224(sp)
    80005dcc:	f5fa                	sd	t5,232(sp)
    80005dce:	f9fe                	sd	t6,240(sp)
    80005dd0:	c47fc0ef          	jal	ra,80002a16 <kerneltrap>
    80005dd4:	6082                	ld	ra,0(sp)
    80005dd6:	6122                	ld	sp,8(sp)
    80005dd8:	61c2                	ld	gp,16(sp)
    80005dda:	7282                	ld	t0,32(sp)
    80005ddc:	7322                	ld	t1,40(sp)
    80005dde:	73c2                	ld	t2,48(sp)
    80005de0:	7462                	ld	s0,56(sp)
    80005de2:	6486                	ld	s1,64(sp)
    80005de4:	6526                	ld	a0,72(sp)
    80005de6:	65c6                	ld	a1,80(sp)
    80005de8:	6666                	ld	a2,88(sp)
    80005dea:	7686                	ld	a3,96(sp)
    80005dec:	7726                	ld	a4,104(sp)
    80005dee:	77c6                	ld	a5,112(sp)
    80005df0:	7866                	ld	a6,120(sp)
    80005df2:	688a                	ld	a7,128(sp)
    80005df4:	692a                	ld	s2,136(sp)
    80005df6:	69ca                	ld	s3,144(sp)
    80005df8:	6a6a                	ld	s4,152(sp)
    80005dfa:	7a8a                	ld	s5,160(sp)
    80005dfc:	7b2a                	ld	s6,168(sp)
    80005dfe:	7bca                	ld	s7,176(sp)
    80005e00:	7c6a                	ld	s8,184(sp)
    80005e02:	6c8e                	ld	s9,192(sp)
    80005e04:	6d2e                	ld	s10,200(sp)
    80005e06:	6dce                	ld	s11,208(sp)
    80005e08:	6e6e                	ld	t3,216(sp)
    80005e0a:	7e8e                	ld	t4,224(sp)
    80005e0c:	7f2e                	ld	t5,232(sp)
    80005e0e:	7fce                	ld	t6,240(sp)
    80005e10:	6111                	addi	sp,sp,256
    80005e12:	10200073          	sret
    80005e16:	00000013          	nop
    80005e1a:	00000013          	nop
    80005e1e:	0001                	nop

0000000080005e20 <timervec>:
    80005e20:	34051573          	csrrw	a0,mscratch,a0
    80005e24:	e10c                	sd	a1,0(a0)
    80005e26:	e510                	sd	a2,8(a0)
    80005e28:	e914                	sd	a3,16(a0)
    80005e2a:	6d0c                	ld	a1,24(a0)
    80005e2c:	7110                	ld	a2,32(a0)
    80005e2e:	6194                	ld	a3,0(a1)
    80005e30:	96b2                	add	a3,a3,a2
    80005e32:	e194                	sd	a3,0(a1)
    80005e34:	4589                	li	a1,2
    80005e36:	14459073          	csrw	sip,a1
    80005e3a:	6914                	ld	a3,16(a0)
    80005e3c:	6510                	ld	a2,8(a0)
    80005e3e:	610c                	ld	a1,0(a0)
    80005e40:	34051573          	csrrw	a0,mscratch,a0
    80005e44:	30200073          	mret
	...

0000000080005e4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e4a:	1141                	addi	sp,sp,-16
    80005e4c:	e422                	sd	s0,8(sp)
    80005e4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e50:	0c0007b7          	lui	a5,0xc000
    80005e54:	4705                	li	a4,1
    80005e56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e58:	c3d8                	sw	a4,4(a5)
}
    80005e5a:	6422                	ld	s0,8(sp)
    80005e5c:	0141                	addi	sp,sp,16
    80005e5e:	8082                	ret

0000000080005e60 <plicinithart>:

void
plicinithart(void)
{
    80005e60:	1141                	addi	sp,sp,-16
    80005e62:	e406                	sd	ra,8(sp)
    80005e64:	e022                	sd	s0,0(sp)
    80005e66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	aea080e7          	jalr	-1302(ra) # 80001952 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e70:	0085171b          	slliw	a4,a0,0x8
    80005e74:	0c0027b7          	lui	a5,0xc002
    80005e78:	97ba                	add	a5,a5,a4
    80005e7a:	40200713          	li	a4,1026
    80005e7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e82:	00d5151b          	slliw	a0,a0,0xd
    80005e86:	0c2017b7          	lui	a5,0xc201
    80005e8a:	953e                	add	a0,a0,a5
    80005e8c:	00052023          	sw	zero,0(a0)
}
    80005e90:	60a2                	ld	ra,8(sp)
    80005e92:	6402                	ld	s0,0(sp)
    80005e94:	0141                	addi	sp,sp,16
    80005e96:	8082                	ret

0000000080005e98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e98:	1141                	addi	sp,sp,-16
    80005e9a:	e406                	sd	ra,8(sp)
    80005e9c:	e022                	sd	s0,0(sp)
    80005e9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ea0:	ffffc097          	auipc	ra,0xffffc
    80005ea4:	ab2080e7          	jalr	-1358(ra) # 80001952 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ea8:	00d5179b          	slliw	a5,a0,0xd
    80005eac:	0c201537          	lui	a0,0xc201
    80005eb0:	953e                	add	a0,a0,a5
  return irq;
}
    80005eb2:	4148                	lw	a0,4(a0)
    80005eb4:	60a2                	ld	ra,8(sp)
    80005eb6:	6402                	ld	s0,0(sp)
    80005eb8:	0141                	addi	sp,sp,16
    80005eba:	8082                	ret

0000000080005ebc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ebc:	1101                	addi	sp,sp,-32
    80005ebe:	ec06                	sd	ra,24(sp)
    80005ec0:	e822                	sd	s0,16(sp)
    80005ec2:	e426                	sd	s1,8(sp)
    80005ec4:	1000                	addi	s0,sp,32
    80005ec6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	a8a080e7          	jalr	-1398(ra) # 80001952 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ed0:	00d5151b          	slliw	a0,a0,0xd
    80005ed4:	0c2017b7          	lui	a5,0xc201
    80005ed8:	97aa                	add	a5,a5,a0
    80005eda:	c3c4                	sw	s1,4(a5)
}
    80005edc:	60e2                	ld	ra,24(sp)
    80005ede:	6442                	ld	s0,16(sp)
    80005ee0:	64a2                	ld	s1,8(sp)
    80005ee2:	6105                	addi	sp,sp,32
    80005ee4:	8082                	ret

0000000080005ee6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ee6:	1141                	addi	sp,sp,-16
    80005ee8:	e406                	sd	ra,8(sp)
    80005eea:	e022                	sd	s0,0(sp)
    80005eec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005eee:	479d                	li	a5,7
    80005ef0:	06a7c963          	blt	a5,a0,80005f62 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005ef4:	0001d797          	auipc	a5,0x1d
    80005ef8:	10c78793          	addi	a5,a5,268 # 80023000 <disk>
    80005efc:	00a78733          	add	a4,a5,a0
    80005f00:	6789                	lui	a5,0x2
    80005f02:	97ba                	add	a5,a5,a4
    80005f04:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f08:	e7ad                	bnez	a5,80005f72 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f0a:	00451793          	slli	a5,a0,0x4
    80005f0e:	0001f717          	auipc	a4,0x1f
    80005f12:	0f270713          	addi	a4,a4,242 # 80025000 <disk+0x2000>
    80005f16:	6314                	ld	a3,0(a4)
    80005f18:	96be                	add	a3,a3,a5
    80005f1a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f1e:	6314                	ld	a3,0(a4)
    80005f20:	96be                	add	a3,a3,a5
    80005f22:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005f26:	6314                	ld	a3,0(a4)
    80005f28:	96be                	add	a3,a3,a5
    80005f2a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005f2e:	6318                	ld	a4,0(a4)
    80005f30:	97ba                	add	a5,a5,a4
    80005f32:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005f36:	0001d797          	auipc	a5,0x1d
    80005f3a:	0ca78793          	addi	a5,a5,202 # 80023000 <disk>
    80005f3e:	97aa                	add	a5,a5,a0
    80005f40:	6509                	lui	a0,0x2
    80005f42:	953e                	add	a0,a0,a5
    80005f44:	4785                	li	a5,1
    80005f46:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f4a:	0001f517          	auipc	a0,0x1f
    80005f4e:	0ce50513          	addi	a0,a0,206 # 80025018 <disk+0x2018>
    80005f52:	ffffc097          	auipc	ra,0xffffc
    80005f56:	28e080e7          	jalr	654(ra) # 800021e0 <wakeup>
}
    80005f5a:	60a2                	ld	ra,8(sp)
    80005f5c:	6402                	ld	s0,0(sp)
    80005f5e:	0141                	addi	sp,sp,16
    80005f60:	8082                	ret
    panic("free_desc 1");
    80005f62:	00003517          	auipc	a0,0x3
    80005f66:	9de50513          	addi	a0,a0,-1570 # 80008940 <syscalls+0x330>
    80005f6a:	ffffa097          	auipc	ra,0xffffa
    80005f6e:	5c0080e7          	jalr	1472(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005f72:	00003517          	auipc	a0,0x3
    80005f76:	9de50513          	addi	a0,a0,-1570 # 80008950 <syscalls+0x340>
    80005f7a:	ffffa097          	auipc	ra,0xffffa
    80005f7e:	5b0080e7          	jalr	1456(ra) # 8000052a <panic>

0000000080005f82 <virtio_disk_init>:
{
    80005f82:	1101                	addi	sp,sp,-32
    80005f84:	ec06                	sd	ra,24(sp)
    80005f86:	e822                	sd	s0,16(sp)
    80005f88:	e426                	sd	s1,8(sp)
    80005f8a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f8c:	00003597          	auipc	a1,0x3
    80005f90:	9d458593          	addi	a1,a1,-1580 # 80008960 <syscalls+0x350>
    80005f94:	0001f517          	auipc	a0,0x1f
    80005f98:	19450513          	addi	a0,a0,404 # 80025128 <disk+0x2128>
    80005f9c:	ffffb097          	auipc	ra,0xffffb
    80005fa0:	b96080e7          	jalr	-1130(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fa4:	100017b7          	lui	a5,0x10001
    80005fa8:	4398                	lw	a4,0(a5)
    80005faa:	2701                	sext.w	a4,a4
    80005fac:	747277b7          	lui	a5,0x74727
    80005fb0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fb4:	0ef71163          	bne	a4,a5,80006096 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fb8:	100017b7          	lui	a5,0x10001
    80005fbc:	43dc                	lw	a5,4(a5)
    80005fbe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fc0:	4705                	li	a4,1
    80005fc2:	0ce79a63          	bne	a5,a4,80006096 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fc6:	100017b7          	lui	a5,0x10001
    80005fca:	479c                	lw	a5,8(a5)
    80005fcc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fce:	4709                	li	a4,2
    80005fd0:	0ce79363          	bne	a5,a4,80006096 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fd4:	100017b7          	lui	a5,0x10001
    80005fd8:	47d8                	lw	a4,12(a5)
    80005fda:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fdc:	554d47b7          	lui	a5,0x554d4
    80005fe0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fe4:	0af71963          	bne	a4,a5,80006096 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fe8:	100017b7          	lui	a5,0x10001
    80005fec:	4705                	li	a4,1
    80005fee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff0:	470d                	li	a4,3
    80005ff2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ff4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ff6:	c7ffe737          	lui	a4,0xc7ffe
    80005ffa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ffe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006000:	2701                	sext.w	a4,a4
    80006002:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006004:	472d                	li	a4,11
    80006006:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006008:	473d                	li	a4,15
    8000600a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000600c:	6705                	lui	a4,0x1
    8000600e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006010:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006014:	5bdc                	lw	a5,52(a5)
    80006016:	2781                	sext.w	a5,a5
  if(max == 0)
    80006018:	c7d9                	beqz	a5,800060a6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000601a:	471d                	li	a4,7
    8000601c:	08f77d63          	bgeu	a4,a5,800060b6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006020:	100014b7          	lui	s1,0x10001
    80006024:	47a1                	li	a5,8
    80006026:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006028:	6609                	lui	a2,0x2
    8000602a:	4581                	li	a1,0
    8000602c:	0001d517          	auipc	a0,0x1d
    80006030:	fd450513          	addi	a0,a0,-44 # 80023000 <disk>
    80006034:	ffffb097          	auipc	ra,0xffffb
    80006038:	c8a080e7          	jalr	-886(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000603c:	0001d717          	auipc	a4,0x1d
    80006040:	fc470713          	addi	a4,a4,-60 # 80023000 <disk>
    80006044:	00c75793          	srli	a5,a4,0xc
    80006048:	2781                	sext.w	a5,a5
    8000604a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000604c:	0001f797          	auipc	a5,0x1f
    80006050:	fb478793          	addi	a5,a5,-76 # 80025000 <disk+0x2000>
    80006054:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006056:	0001d717          	auipc	a4,0x1d
    8000605a:	02a70713          	addi	a4,a4,42 # 80023080 <disk+0x80>
    8000605e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006060:	0001e717          	auipc	a4,0x1e
    80006064:	fa070713          	addi	a4,a4,-96 # 80024000 <disk+0x1000>
    80006068:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000606a:	4705                	li	a4,1
    8000606c:	00e78c23          	sb	a4,24(a5)
    80006070:	00e78ca3          	sb	a4,25(a5)
    80006074:	00e78d23          	sb	a4,26(a5)
    80006078:	00e78da3          	sb	a4,27(a5)
    8000607c:	00e78e23          	sb	a4,28(a5)
    80006080:	00e78ea3          	sb	a4,29(a5)
    80006084:	00e78f23          	sb	a4,30(a5)
    80006088:	00e78fa3          	sb	a4,31(a5)
}
    8000608c:	60e2                	ld	ra,24(sp)
    8000608e:	6442                	ld	s0,16(sp)
    80006090:	64a2                	ld	s1,8(sp)
    80006092:	6105                	addi	sp,sp,32
    80006094:	8082                	ret
    panic("could not find virtio disk");
    80006096:	00003517          	auipc	a0,0x3
    8000609a:	8da50513          	addi	a0,a0,-1830 # 80008970 <syscalls+0x360>
    8000609e:	ffffa097          	auipc	ra,0xffffa
    800060a2:	48c080e7          	jalr	1164(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    800060a6:	00003517          	auipc	a0,0x3
    800060aa:	8ea50513          	addi	a0,a0,-1814 # 80008990 <syscalls+0x380>
    800060ae:	ffffa097          	auipc	ra,0xffffa
    800060b2:	47c080e7          	jalr	1148(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    800060b6:	00003517          	auipc	a0,0x3
    800060ba:	8fa50513          	addi	a0,a0,-1798 # 800089b0 <syscalls+0x3a0>
    800060be:	ffffa097          	auipc	ra,0xffffa
    800060c2:	46c080e7          	jalr	1132(ra) # 8000052a <panic>

00000000800060c6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060c6:	7119                	addi	sp,sp,-128
    800060c8:	fc86                	sd	ra,120(sp)
    800060ca:	f8a2                	sd	s0,112(sp)
    800060cc:	f4a6                	sd	s1,104(sp)
    800060ce:	f0ca                	sd	s2,96(sp)
    800060d0:	ecce                	sd	s3,88(sp)
    800060d2:	e8d2                	sd	s4,80(sp)
    800060d4:	e4d6                	sd	s5,72(sp)
    800060d6:	e0da                	sd	s6,64(sp)
    800060d8:	fc5e                	sd	s7,56(sp)
    800060da:	f862                	sd	s8,48(sp)
    800060dc:	f466                	sd	s9,40(sp)
    800060de:	f06a                	sd	s10,32(sp)
    800060e0:	ec6e                	sd	s11,24(sp)
    800060e2:	0100                	addi	s0,sp,128
    800060e4:	8aaa                	mv	s5,a0
    800060e6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060e8:	00c52c83          	lw	s9,12(a0)
    800060ec:	001c9c9b          	slliw	s9,s9,0x1
    800060f0:	1c82                	slli	s9,s9,0x20
    800060f2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060f6:	0001f517          	auipc	a0,0x1f
    800060fa:	03250513          	addi	a0,a0,50 # 80025128 <disk+0x2128>
    800060fe:	ffffb097          	auipc	ra,0xffffb
    80006102:	ac4080e7          	jalr	-1340(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006106:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006108:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000610a:	0001dc17          	auipc	s8,0x1d
    8000610e:	ef6c0c13          	addi	s8,s8,-266 # 80023000 <disk>
    80006112:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006114:	4b0d                	li	s6,3
    80006116:	a0ad                	j	80006180 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006118:	00fc0733          	add	a4,s8,a5
    8000611c:	975e                	add	a4,a4,s7
    8000611e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006122:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006124:	0207c563          	bltz	a5,8000614e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006128:	2905                	addiw	s2,s2,1
    8000612a:	0611                	addi	a2,a2,4
    8000612c:	19690d63          	beq	s2,s6,800062c6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006130:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006132:	0001f717          	auipc	a4,0x1f
    80006136:	ee670713          	addi	a4,a4,-282 # 80025018 <disk+0x2018>
    8000613a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000613c:	00074683          	lbu	a3,0(a4)
    80006140:	fee1                	bnez	a3,80006118 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006142:	2785                	addiw	a5,a5,1
    80006144:	0705                	addi	a4,a4,1
    80006146:	fe979be3          	bne	a5,s1,8000613c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000614a:	57fd                	li	a5,-1
    8000614c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000614e:	01205d63          	blez	s2,80006168 <virtio_disk_rw+0xa2>
    80006152:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006154:	000a2503          	lw	a0,0(s4)
    80006158:	00000097          	auipc	ra,0x0
    8000615c:	d8e080e7          	jalr	-626(ra) # 80005ee6 <free_desc>
      for(int j = 0; j < i; j++)
    80006160:	2d85                	addiw	s11,s11,1
    80006162:	0a11                	addi	s4,s4,4
    80006164:	ffb918e3          	bne	s2,s11,80006154 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006168:	0001f597          	auipc	a1,0x1f
    8000616c:	fc058593          	addi	a1,a1,-64 # 80025128 <disk+0x2128>
    80006170:	0001f517          	auipc	a0,0x1f
    80006174:	ea850513          	addi	a0,a0,-344 # 80025018 <disk+0x2018>
    80006178:	ffffc097          	auipc	ra,0xffffc
    8000617c:	edc080e7          	jalr	-292(ra) # 80002054 <sleep>
  for(int i = 0; i < 3; i++){
    80006180:	f8040a13          	addi	s4,s0,-128
{
    80006184:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006186:	894e                	mv	s2,s3
    80006188:	b765                	j	80006130 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000618a:	0001f697          	auipc	a3,0x1f
    8000618e:	e766b683          	ld	a3,-394(a3) # 80025000 <disk+0x2000>
    80006192:	96ba                	add	a3,a3,a4
    80006194:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006198:	0001d817          	auipc	a6,0x1d
    8000619c:	e6880813          	addi	a6,a6,-408 # 80023000 <disk>
    800061a0:	0001f697          	auipc	a3,0x1f
    800061a4:	e6068693          	addi	a3,a3,-416 # 80025000 <disk+0x2000>
    800061a8:	6290                	ld	a2,0(a3)
    800061aa:	963a                	add	a2,a2,a4
    800061ac:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800061b0:	0015e593          	ori	a1,a1,1
    800061b4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800061b8:	f8842603          	lw	a2,-120(s0)
    800061bc:	628c                	ld	a1,0(a3)
    800061be:	972e                	add	a4,a4,a1
    800061c0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061c4:	20050593          	addi	a1,a0,512
    800061c8:	0592                	slli	a1,a1,0x4
    800061ca:	95c2                	add	a1,a1,a6
    800061cc:	577d                	li	a4,-1
    800061ce:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061d2:	00461713          	slli	a4,a2,0x4
    800061d6:	6290                	ld	a2,0(a3)
    800061d8:	963a                	add	a2,a2,a4
    800061da:	03078793          	addi	a5,a5,48
    800061de:	97c2                	add	a5,a5,a6
    800061e0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800061e2:	629c                	ld	a5,0(a3)
    800061e4:	97ba                	add	a5,a5,a4
    800061e6:	4605                	li	a2,1
    800061e8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061ea:	629c                	ld	a5,0(a3)
    800061ec:	97ba                	add	a5,a5,a4
    800061ee:	4809                	li	a6,2
    800061f0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800061f4:	629c                	ld	a5,0(a3)
    800061f6:	973e                	add	a4,a4,a5
    800061f8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061fc:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006200:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006204:	6698                	ld	a4,8(a3)
    80006206:	00275783          	lhu	a5,2(a4)
    8000620a:	8b9d                	andi	a5,a5,7
    8000620c:	0786                	slli	a5,a5,0x1
    8000620e:	97ba                	add	a5,a5,a4
    80006210:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006214:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006218:	6698                	ld	a4,8(a3)
    8000621a:	00275783          	lhu	a5,2(a4)
    8000621e:	2785                	addiw	a5,a5,1
    80006220:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006224:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006228:	100017b7          	lui	a5,0x10001
    8000622c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006230:	004aa783          	lw	a5,4(s5)
    80006234:	02c79163          	bne	a5,a2,80006256 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006238:	0001f917          	auipc	s2,0x1f
    8000623c:	ef090913          	addi	s2,s2,-272 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006240:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006242:	85ca                	mv	a1,s2
    80006244:	8556                	mv	a0,s5
    80006246:	ffffc097          	auipc	ra,0xffffc
    8000624a:	e0e080e7          	jalr	-498(ra) # 80002054 <sleep>
  while(b->disk == 1) {
    8000624e:	004aa783          	lw	a5,4(s5)
    80006252:	fe9788e3          	beq	a5,s1,80006242 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006256:	f8042903          	lw	s2,-128(s0)
    8000625a:	20090793          	addi	a5,s2,512
    8000625e:	00479713          	slli	a4,a5,0x4
    80006262:	0001d797          	auipc	a5,0x1d
    80006266:	d9e78793          	addi	a5,a5,-610 # 80023000 <disk>
    8000626a:	97ba                	add	a5,a5,a4
    8000626c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006270:	0001f997          	auipc	s3,0x1f
    80006274:	d9098993          	addi	s3,s3,-624 # 80025000 <disk+0x2000>
    80006278:	00491713          	slli	a4,s2,0x4
    8000627c:	0009b783          	ld	a5,0(s3)
    80006280:	97ba                	add	a5,a5,a4
    80006282:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006286:	854a                	mv	a0,s2
    80006288:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000628c:	00000097          	auipc	ra,0x0
    80006290:	c5a080e7          	jalr	-934(ra) # 80005ee6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006294:	8885                	andi	s1,s1,1
    80006296:	f0ed                	bnez	s1,80006278 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006298:	0001f517          	auipc	a0,0x1f
    8000629c:	e9050513          	addi	a0,a0,-368 # 80025128 <disk+0x2128>
    800062a0:	ffffb097          	auipc	ra,0xffffb
    800062a4:	9d6080e7          	jalr	-1578(ra) # 80000c76 <release>
}
    800062a8:	70e6                	ld	ra,120(sp)
    800062aa:	7446                	ld	s0,112(sp)
    800062ac:	74a6                	ld	s1,104(sp)
    800062ae:	7906                	ld	s2,96(sp)
    800062b0:	69e6                	ld	s3,88(sp)
    800062b2:	6a46                	ld	s4,80(sp)
    800062b4:	6aa6                	ld	s5,72(sp)
    800062b6:	6b06                	ld	s6,64(sp)
    800062b8:	7be2                	ld	s7,56(sp)
    800062ba:	7c42                	ld	s8,48(sp)
    800062bc:	7ca2                	ld	s9,40(sp)
    800062be:	7d02                	ld	s10,32(sp)
    800062c0:	6de2                	ld	s11,24(sp)
    800062c2:	6109                	addi	sp,sp,128
    800062c4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062c6:	f8042503          	lw	a0,-128(s0)
    800062ca:	20050793          	addi	a5,a0,512
    800062ce:	0792                	slli	a5,a5,0x4
  if(write)
    800062d0:	0001d817          	auipc	a6,0x1d
    800062d4:	d3080813          	addi	a6,a6,-720 # 80023000 <disk>
    800062d8:	00f80733          	add	a4,a6,a5
    800062dc:	01a036b3          	snez	a3,s10
    800062e0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800062e4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800062e8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800062ec:	7679                	lui	a2,0xffffe
    800062ee:	963e                	add	a2,a2,a5
    800062f0:	0001f697          	auipc	a3,0x1f
    800062f4:	d1068693          	addi	a3,a3,-752 # 80025000 <disk+0x2000>
    800062f8:	6298                	ld	a4,0(a3)
    800062fa:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062fc:	0a878593          	addi	a1,a5,168
    80006300:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006302:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006304:	6298                	ld	a4,0(a3)
    80006306:	9732                	add	a4,a4,a2
    80006308:	45c1                	li	a1,16
    8000630a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000630c:	6298                	ld	a4,0(a3)
    8000630e:	9732                	add	a4,a4,a2
    80006310:	4585                	li	a1,1
    80006312:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006316:	f8442703          	lw	a4,-124(s0)
    8000631a:	628c                	ld	a1,0(a3)
    8000631c:	962e                	add	a2,a2,a1
    8000631e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006322:	0712                	slli	a4,a4,0x4
    80006324:	6290                	ld	a2,0(a3)
    80006326:	963a                	add	a2,a2,a4
    80006328:	058a8593          	addi	a1,s5,88
    8000632c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000632e:	6294                	ld	a3,0(a3)
    80006330:	96ba                	add	a3,a3,a4
    80006332:	40000613          	li	a2,1024
    80006336:	c690                	sw	a2,8(a3)
  if(write)
    80006338:	e40d19e3          	bnez	s10,8000618a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000633c:	0001f697          	auipc	a3,0x1f
    80006340:	cc46b683          	ld	a3,-828(a3) # 80025000 <disk+0x2000>
    80006344:	96ba                	add	a3,a3,a4
    80006346:	4609                	li	a2,2
    80006348:	00c69623          	sh	a2,12(a3)
    8000634c:	b5b1                	j	80006198 <virtio_disk_rw+0xd2>

000000008000634e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000634e:	1101                	addi	sp,sp,-32
    80006350:	ec06                	sd	ra,24(sp)
    80006352:	e822                	sd	s0,16(sp)
    80006354:	e426                	sd	s1,8(sp)
    80006356:	e04a                	sd	s2,0(sp)
    80006358:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000635a:	0001f517          	auipc	a0,0x1f
    8000635e:	dce50513          	addi	a0,a0,-562 # 80025128 <disk+0x2128>
    80006362:	ffffb097          	auipc	ra,0xffffb
    80006366:	860080e7          	jalr	-1952(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000636a:	10001737          	lui	a4,0x10001
    8000636e:	533c                	lw	a5,96(a4)
    80006370:	8b8d                	andi	a5,a5,3
    80006372:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006374:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006378:	0001f797          	auipc	a5,0x1f
    8000637c:	c8878793          	addi	a5,a5,-888 # 80025000 <disk+0x2000>
    80006380:	6b94                	ld	a3,16(a5)
    80006382:	0207d703          	lhu	a4,32(a5)
    80006386:	0026d783          	lhu	a5,2(a3)
    8000638a:	06f70163          	beq	a4,a5,800063ec <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000638e:	0001d917          	auipc	s2,0x1d
    80006392:	c7290913          	addi	s2,s2,-910 # 80023000 <disk>
    80006396:	0001f497          	auipc	s1,0x1f
    8000639a:	c6a48493          	addi	s1,s1,-918 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000639e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063a2:	6898                	ld	a4,16(s1)
    800063a4:	0204d783          	lhu	a5,32(s1)
    800063a8:	8b9d                	andi	a5,a5,7
    800063aa:	078e                	slli	a5,a5,0x3
    800063ac:	97ba                	add	a5,a5,a4
    800063ae:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063b0:	20078713          	addi	a4,a5,512
    800063b4:	0712                	slli	a4,a4,0x4
    800063b6:	974a                	add	a4,a4,s2
    800063b8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800063bc:	e731                	bnez	a4,80006408 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063be:	20078793          	addi	a5,a5,512
    800063c2:	0792                	slli	a5,a5,0x4
    800063c4:	97ca                	add	a5,a5,s2
    800063c6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800063c8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063cc:	ffffc097          	auipc	ra,0xffffc
    800063d0:	e14080e7          	jalr	-492(ra) # 800021e0 <wakeup>

    disk.used_idx += 1;
    800063d4:	0204d783          	lhu	a5,32(s1)
    800063d8:	2785                	addiw	a5,a5,1
    800063da:	17c2                	slli	a5,a5,0x30
    800063dc:	93c1                	srli	a5,a5,0x30
    800063de:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063e2:	6898                	ld	a4,16(s1)
    800063e4:	00275703          	lhu	a4,2(a4)
    800063e8:	faf71be3          	bne	a4,a5,8000639e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800063ec:	0001f517          	auipc	a0,0x1f
    800063f0:	d3c50513          	addi	a0,a0,-708 # 80025128 <disk+0x2128>
    800063f4:	ffffb097          	auipc	ra,0xffffb
    800063f8:	882080e7          	jalr	-1918(ra) # 80000c76 <release>
}
    800063fc:	60e2                	ld	ra,24(sp)
    800063fe:	6442                	ld	s0,16(sp)
    80006400:	64a2                	ld	s1,8(sp)
    80006402:	6902                	ld	s2,0(sp)
    80006404:	6105                	addi	sp,sp,32
    80006406:	8082                	ret
      panic("virtio_disk_intr status");
    80006408:	00002517          	auipc	a0,0x2
    8000640c:	5c850513          	addi	a0,a0,1480 # 800089d0 <syscalls+0x3c0>
    80006410:	ffffa097          	auipc	ra,0xffffa
    80006414:	11a080e7          	jalr	282(ra) # 8000052a <panic>
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
