
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
    80000068:	f2c78793          	addi	a5,a5,-212 # 80005f90 <timervec>
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
    80000eb6:	a1a080e7          	jalr	-1510(ra) # 800028cc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	116080e7          	jalr	278(ra) # 80005fd0 <plicinithart>
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
    80000f2e:	97a080e7          	jalr	-1670(ra) # 800028a4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	99a080e7          	jalr	-1638(ra) # 800028cc <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	080080e7          	jalr	128(ra) # 80005fba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	08e080e7          	jalr	142(ra) # 80005fd0 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	25c080e7          	jalr	604(ra) # 800031a6 <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	8ee080e7          	jalr	-1810(ra) # 80003840 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	89c080e7          	jalr	-1892(ra) # 800047f6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	190080e7          	jalr	400(ra) # 800060f2 <virtio_disk_init>
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
    800019dc:	f0c080e7          	jalr	-244(ra) # 800028e4 <usertrapret>
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
    800019f6:	dce080e7          	jalr	-562(ra) # 800037c0 <fsinit>
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
    80001cc6:	52c080e7          	jalr	1324(ra) # 800041ee <namei>
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
    80001e0e:	a7e080e7          	jalr	-1410(ra) # 80004888 <filedup>
    80001e12:	00a93023          	sd	a0,0(s2)
    80001e16:	b7e5                	j	80001dfe <fork+0xa4>
	np->cwd = idup(p->cwd);
    80001e18:	168ab503          	ld	a0,360(s5)
    80001e1c:	00002097          	auipc	ra,0x2
    80001e20:	bde080e7          	jalr	-1058(ra) # 800039fa <idup>
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
    80001f34:	00001097          	auipc	ra,0x1
    80001f38:	906080e7          	jalr	-1786(ra) # 8000283a <swtch>
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
    80001fb6:	00001097          	auipc	ra,0x1
    80001fba:	884080e7          	jalr	-1916(ra) # 8000283a <swtch>
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
    800022f4:	5ea080e7          	jalr	1514(ra) # 800048da <fileclose>
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
    8000230c:	106080e7          	jalr	262(ra) # 8000440e <begin_op>
	iput(p->cwd);
    80002310:	1689b503          	ld	a0,360(s3)
    80002314:	00002097          	auipc	ra,0x2
    80002318:	8de080e7          	jalr	-1826(ra) # 80003bf2 <iput>
	end_op();
    8000231c:	00002097          	auipc	ra,0x2
    80002320:	172080e7          	jalr	370(ra) # 8000448e <end_op>
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

0000000080002622 <update_perf>:
	}
}
 
// ADDED
void update_perf(uint ticks, struct proc *p)
{
    80002622:	1141                	addi	sp,sp,-16
    80002624:	e422                	sd	s0,8(sp)
    80002626:	0800                	addi	s0,sp,16
	switch (p->state)
    80002628:	4d9c                	lw	a5,24(a1)
    8000262a:	4711                	li	a4,4
    8000262c:	02e78763          	beq	a5,a4,8000265a <update_perf+0x38>
    80002630:	00f76c63          	bltu	a4,a5,80002648 <update_perf+0x26>
    80002634:	4709                	li	a4,2
    80002636:	02e78863          	beq	a5,a4,80002666 <update_perf+0x44>
    8000263a:	470d                	li	a4,3
    8000263c:	02e79263          	bne	a5,a4,80002660 <update_perf+0x3e>
		break;
	case SLEEPING:
		p->performance.stime++;
		break;
	case RUNNABLE:
		p->performance.retime++;
    80002640:	41fc                	lw	a5,68(a1)
    80002642:	2785                	addiw	a5,a5,1
    80002644:	c1fc                	sw	a5,68(a1)
		break;	 
    80002646:	a829                	j	80002660 <update_perf+0x3e>
	switch (p->state)
    80002648:	4715                	li	a4,5
    8000264a:	00e79b63          	bne	a5,a4,80002660 <update_perf+0x3e>
	case ZOMBIE:
		if (p->performance.ttime == -1)
    8000264e:	5dd8                	lw	a4,60(a1)
    80002650:	57fd                	li	a5,-1
    80002652:	00f71763          	bne	a4,a5,80002660 <update_perf+0x3e>
			p->performance.ttime = ticks;
    80002656:	ddc8                	sw	a0,60(a1)
		break;
	default:
		break;
	}
}
    80002658:	a021                	j	80002660 <update_perf+0x3e>
		p->performance.rutime++;
    8000265a:	45bc                	lw	a5,72(a1)
    8000265c:	2785                	addiw	a5,a5,1
    8000265e:	c5bc                	sw	a5,72(a1)
}
    80002660:	6422                	ld	s0,8(sp)
    80002662:	0141                	addi	sp,sp,16
    80002664:	8082                	ret
		p->performance.stime++;
    80002666:	41bc                	lw	a5,64(a1)
    80002668:	2785                	addiw	a5,a5,1
    8000266a:	c1bc                	sw	a5,64(a1)
		break;
    8000266c:	bfd5                	j	80002660 <update_perf+0x3e>

000000008000266e <wait_stat>:
{
    8000266e:	711d                	addi	sp,sp,-96
    80002670:	ec86                	sd	ra,88(sp)
    80002672:	e8a2                	sd	s0,80(sp)
    80002674:	e4a6                	sd	s1,72(sp)
    80002676:	e0ca                	sd	s2,64(sp)
    80002678:	fc4e                	sd	s3,56(sp)
    8000267a:	f852                	sd	s4,48(sp)
    8000267c:	f456                	sd	s5,40(sp)
    8000267e:	f05a                	sd	s6,32(sp)
    80002680:	ec5e                	sd	s7,24(sp)
    80002682:	e862                	sd	s8,16(sp)
    80002684:	e466                	sd	s9,8(sp)
    80002686:	1080                	addi	s0,sp,96
    80002688:	8b2a                	mv	s6,a0
    8000268a:	8bae                	mv	s7,a1
	struct proc *p = myproc();
    8000268c:	fffff097          	auipc	ra,0xfffff
    80002690:	2f2080e7          	jalr	754(ra) # 8000197e <myproc>
    80002694:	892a                	mv	s2,a0
	acquire(&wait_lock);
    80002696:	0000f517          	auipc	a0,0xf
    8000269a:	c2250513          	addi	a0,a0,-990 # 800112b8 <wait_lock>
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	524080e7          	jalr	1316(ra) # 80000bc2 <acquire>
		havekids = 0;
    800026a6:	4c01                	li	s8,0
				if (np->state == ZOMBIE)
    800026a8:	4a15                	li	s4,5
				havekids = 1;
    800026aa:	4a85                	li	s5,1
		for (np = proc; np < &proc[NPROC]; np++)
    800026ac:	00015997          	auipc	s3,0x15
    800026b0:	02498993          	addi	s3,s3,36 # 800176d0 <tickslock>
		sleep(p, &wait_lock); //DOC: wait-sleep
    800026b4:	0000fc97          	auipc	s9,0xf
    800026b8:	c04c8c93          	addi	s9,s9,-1020 # 800112b8 <wait_lock>
		havekids = 0;
    800026bc:	8762                	mv	a4,s8
		for (np = proc; np < &proc[NPROC]; np++)
    800026be:	0000f497          	auipc	s1,0xf
    800026c2:	01248493          	addi	s1,s1,18 # 800116d0 <proc>
    800026c6:	a85d                	j	8000277c <wait_stat+0x10e>
					pid = np->pid;
    800026c8:	0304a983          	lw	s3,48(s1)
					update_perf(ticks, np);
    800026cc:	85a6                	mv	a1,s1
    800026ce:	00007517          	auipc	a0,0x7
    800026d2:	96252503          	lw	a0,-1694(a0) # 80009030 <ticks>
    800026d6:	00000097          	auipc	ra,0x0
    800026da:	f4c080e7          	jalr	-180(ra) # 80002622 <update_perf>
					if (status != 0 && copyout(p->pagetable, status, (char *)&np->xstate,
    800026de:	000b0e63          	beqz	s6,800026fa <wait_stat+0x8c>
    800026e2:	4691                	li	a3,4
    800026e4:	02c48613          	addi	a2,s1,44
    800026e8:	85da                	mv	a1,s6
    800026ea:	06893503          	ld	a0,104(s2)
    800026ee:	fffff097          	auipc	ra,0xfffff
    800026f2:	f50080e7          	jalr	-176(ra) # 8000163e <copyout>
    800026f6:	04054163          	bltz	a0,80002738 <wait_stat+0xca>
					if(copyout(p->pagetable, performance, (char *)&(np->performance), sizeof(struct perf)) < 0){
    800026fa:	46e1                	li	a3,24
    800026fc:	03848613          	addi	a2,s1,56
    80002700:	85de                	mv	a1,s7
    80002702:	06893503          	ld	a0,104(s2)
    80002706:	fffff097          	auipc	ra,0xfffff
    8000270a:	f38080e7          	jalr	-200(ra) # 8000163e <copyout>
    8000270e:	04054463          	bltz	a0,80002756 <wait_stat+0xe8>
					freeproc(np);
    80002712:	8526                	mv	a0,s1
    80002714:	fffff097          	auipc	ra,0xfffff
    80002718:	41c080e7          	jalr	1052(ra) # 80001b30 <freeproc>
					release(&np->lock);
    8000271c:	8526                	mv	a0,s1
    8000271e:	ffffe097          	auipc	ra,0xffffe
    80002722:	558080e7          	jalr	1368(ra) # 80000c76 <release>
					release(&wait_lock);
    80002726:	0000f517          	auipc	a0,0xf
    8000272a:	b9250513          	addi	a0,a0,-1134 # 800112b8 <wait_lock>
    8000272e:	ffffe097          	auipc	ra,0xffffe
    80002732:	548080e7          	jalr	1352(ra) # 80000c76 <release>
					return pid;
    80002736:	a051                	j	800027ba <wait_stat+0x14c>
						release(&np->lock);
    80002738:	8526                	mv	a0,s1
    8000273a:	ffffe097          	auipc	ra,0xffffe
    8000273e:	53c080e7          	jalr	1340(ra) # 80000c76 <release>
						release(&wait_lock);
    80002742:	0000f517          	auipc	a0,0xf
    80002746:	b7650513          	addi	a0,a0,-1162 # 800112b8 <wait_lock>
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	52c080e7          	jalr	1324(ra) # 80000c76 <release>
						return -1;
    80002752:	59fd                	li	s3,-1
    80002754:	a09d                	j	800027ba <wait_stat+0x14c>
						release(&np->lock);
    80002756:	8526                	mv	a0,s1
    80002758:	ffffe097          	auipc	ra,0xffffe
    8000275c:	51e080e7          	jalr	1310(ra) # 80000c76 <release>
						release(&wait_lock);
    80002760:	0000f517          	auipc	a0,0xf
    80002764:	b5850513          	addi	a0,a0,-1192 # 800112b8 <wait_lock>
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	50e080e7          	jalr	1294(ra) # 80000c76 <release>
						return -1;
    80002770:	59fd                	li	s3,-1
    80002772:	a0a1                	j	800027ba <wait_stat+0x14c>
		for (np = proc; np < &proc[NPROC]; np++)
    80002774:	18048493          	addi	s1,s1,384
    80002778:	03348463          	beq	s1,s3,800027a0 <wait_stat+0x132>
			if (np->parent == p)
    8000277c:	68bc                	ld	a5,80(s1)
    8000277e:	ff279be3          	bne	a5,s2,80002774 <wait_stat+0x106>
				acquire(&np->lock);
    80002782:	8526                	mv	a0,s1
    80002784:	ffffe097          	auipc	ra,0xffffe
    80002788:	43e080e7          	jalr	1086(ra) # 80000bc2 <acquire>
				if (np->state == ZOMBIE)
    8000278c:	4c9c                	lw	a5,24(s1)
    8000278e:	f3478de3          	beq	a5,s4,800026c8 <wait_stat+0x5a>
				release(&np->lock);
    80002792:	8526                	mv	a0,s1
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	4e2080e7          	jalr	1250(ra) # 80000c76 <release>
				havekids = 1;
    8000279c:	8756                	mv	a4,s5
    8000279e:	bfd9                	j	80002774 <wait_stat+0x106>
		if (!havekids || p->killed)
    800027a0:	c701                	beqz	a4,800027a8 <wait_stat+0x13a>
    800027a2:	02892783          	lw	a5,40(s2)
    800027a6:	cb85                	beqz	a5,800027d6 <wait_stat+0x168>
			release(&wait_lock);
    800027a8:	0000f517          	auipc	a0,0xf
    800027ac:	b1050513          	addi	a0,a0,-1264 # 800112b8 <wait_lock>
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	4c6080e7          	jalr	1222(ra) # 80000c76 <release>
			return -1;
    800027b8:	59fd                	li	s3,-1
}
    800027ba:	854e                	mv	a0,s3
    800027bc:	60e6                	ld	ra,88(sp)
    800027be:	6446                	ld	s0,80(sp)
    800027c0:	64a6                	ld	s1,72(sp)
    800027c2:	6906                	ld	s2,64(sp)
    800027c4:	79e2                	ld	s3,56(sp)
    800027c6:	7a42                	ld	s4,48(sp)
    800027c8:	7aa2                	ld	s5,40(sp)
    800027ca:	7b02                	ld	s6,32(sp)
    800027cc:	6be2                	ld	s7,24(sp)
    800027ce:	6c42                	ld	s8,16(sp)
    800027d0:	6ca2                	ld	s9,8(sp)
    800027d2:	6125                	addi	sp,sp,96
    800027d4:	8082                	ret
		sleep(p, &wait_lock); //DOC: wait-sleep
    800027d6:	85e6                	mv	a1,s9
    800027d8:	854a                	mv	a0,s2
    800027da:	00000097          	auipc	ra,0x0
    800027de:	87a080e7          	jalr	-1926(ra) # 80002054 <sleep>
		havekids = 0;
    800027e2:	bde9                	j	800026bc <wait_stat+0x4e>

00000000800027e4 <update_perfs>:

// ADDED
void update_perfs(uint ticks)
{
    800027e4:	7179                	addi	sp,sp,-48
    800027e6:	f406                	sd	ra,40(sp)
    800027e8:	f022                	sd	s0,32(sp)
    800027ea:	ec26                	sd	s1,24(sp)
    800027ec:	e84a                	sd	s2,16(sp)
    800027ee:	e44e                	sd	s3,8(sp)
    800027f0:	1800                	addi	s0,sp,48
    800027f2:	892a                	mv	s2,a0
	struct proc *p;
	for (p = proc; p < &proc[NPROC]; p++)
    800027f4:	0000f497          	auipc	s1,0xf
    800027f8:	edc48493          	addi	s1,s1,-292 # 800116d0 <proc>
    800027fc:	00015997          	auipc	s3,0x15
    80002800:	ed498993          	addi	s3,s3,-300 # 800176d0 <tickslock>
	{
		acquire(&p->lock);
    80002804:	8526                	mv	a0,s1
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	3bc080e7          	jalr	956(ra) # 80000bc2 <acquire>
		update_perf(ticks, p);
    8000280e:	85a6                	mv	a1,s1
    80002810:	854a                	mv	a0,s2
    80002812:	00000097          	auipc	ra,0x0
    80002816:	e10080e7          	jalr	-496(ra) # 80002622 <update_perf>
		release(&p->lock);
    8000281a:	8526                	mv	a0,s1
    8000281c:	ffffe097          	auipc	ra,0xffffe
    80002820:	45a080e7          	jalr	1114(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80002824:	18048493          	addi	s1,s1,384
    80002828:	fd349ee3          	bne	s1,s3,80002804 <update_perfs+0x20>
	}
    8000282c:	70a2                	ld	ra,40(sp)
    8000282e:	7402                	ld	s0,32(sp)
    80002830:	64e2                	ld	s1,24(sp)
    80002832:	6942                	ld	s2,16(sp)
    80002834:	69a2                	ld	s3,8(sp)
    80002836:	6145                	addi	sp,sp,48
    80002838:	8082                	ret

000000008000283a <swtch>:
    8000283a:	00153023          	sd	ra,0(a0)
    8000283e:	00253423          	sd	sp,8(a0)
    80002842:	e900                	sd	s0,16(a0)
    80002844:	ed04                	sd	s1,24(a0)
    80002846:	03253023          	sd	s2,32(a0)
    8000284a:	03353423          	sd	s3,40(a0)
    8000284e:	03453823          	sd	s4,48(a0)
    80002852:	03553c23          	sd	s5,56(a0)
    80002856:	05653023          	sd	s6,64(a0)
    8000285a:	05753423          	sd	s7,72(a0)
    8000285e:	05853823          	sd	s8,80(a0)
    80002862:	05953c23          	sd	s9,88(a0)
    80002866:	07a53023          	sd	s10,96(a0)
    8000286a:	07b53423          	sd	s11,104(a0)
    8000286e:	0005b083          	ld	ra,0(a1)
    80002872:	0085b103          	ld	sp,8(a1)
    80002876:	6980                	ld	s0,16(a1)
    80002878:	6d84                	ld	s1,24(a1)
    8000287a:	0205b903          	ld	s2,32(a1)
    8000287e:	0285b983          	ld	s3,40(a1)
    80002882:	0305ba03          	ld	s4,48(a1)
    80002886:	0385ba83          	ld	s5,56(a1)
    8000288a:	0405bb03          	ld	s6,64(a1)
    8000288e:	0485bb83          	ld	s7,72(a1)
    80002892:	0505bc03          	ld	s8,80(a1)
    80002896:	0585bc83          	ld	s9,88(a1)
    8000289a:	0605bd03          	ld	s10,96(a1)
    8000289e:	0685bd83          	ld	s11,104(a1)
    800028a2:	8082                	ret

00000000800028a4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800028a4:	1141                	addi	sp,sp,-16
    800028a6:	e406                	sd	ra,8(sp)
    800028a8:	e022                	sd	s0,0(sp)
    800028aa:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800028ac:	00006597          	auipc	a1,0x6
    800028b0:	a2c58593          	addi	a1,a1,-1492 # 800082d8 <states.0+0x30>
    800028b4:	00015517          	auipc	a0,0x15
    800028b8:	e1c50513          	addi	a0,a0,-484 # 800176d0 <tickslock>
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	276080e7          	jalr	630(ra) # 80000b32 <initlock>
}
    800028c4:	60a2                	ld	ra,8(sp)
    800028c6:	6402                	ld	s0,0(sp)
    800028c8:	0141                	addi	sp,sp,16
    800028ca:	8082                	ret

00000000800028cc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800028cc:	1141                	addi	sp,sp,-16
    800028ce:	e422                	sd	s0,8(sp)
    800028d0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028d2:	00003797          	auipc	a5,0x3
    800028d6:	62e78793          	addi	a5,a5,1582 # 80005f00 <kernelvec>
    800028da:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028de:	6422                	ld	s0,8(sp)
    800028e0:	0141                	addi	sp,sp,16
    800028e2:	8082                	ret

00000000800028e4 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028e4:	1141                	addi	sp,sp,-16
    800028e6:	e406                	sd	ra,8(sp)
    800028e8:	e022                	sd	s0,0(sp)
    800028ea:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028ec:	fffff097          	auipc	ra,0xfffff
    800028f0:	092080e7          	jalr	146(ra) # 8000197e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028f8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028fa:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028fe:	00004617          	auipc	a2,0x4
    80002902:	70260613          	addi	a2,a2,1794 # 80007000 <_trampoline>
    80002906:	00004697          	auipc	a3,0x4
    8000290a:	6fa68693          	addi	a3,a3,1786 # 80007000 <_trampoline>
    8000290e:	8e91                	sub	a3,a3,a2
    80002910:	040007b7          	lui	a5,0x4000
    80002914:	17fd                	addi	a5,a5,-1
    80002916:	07b2                	slli	a5,a5,0xc
    80002918:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000291a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000291e:	7938                	ld	a4,112(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002920:	180026f3          	csrr	a3,satp
    80002924:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002926:	7938                	ld	a4,112(a0)
    80002928:	6d34                	ld	a3,88(a0)
    8000292a:	6585                	lui	a1,0x1
    8000292c:	96ae                	add	a3,a3,a1
    8000292e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002930:	7938                	ld	a4,112(a0)
    80002932:	00000697          	auipc	a3,0x0
    80002936:	14868693          	addi	a3,a3,328 # 80002a7a <usertrap>
    8000293a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000293c:	7938                	ld	a4,112(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000293e:	8692                	mv	a3,tp
    80002940:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002942:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002946:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000294a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000294e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002952:	7938                	ld	a4,112(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002954:	6f18                	ld	a4,24(a4)
    80002956:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000295a:	752c                	ld	a1,104(a0)
    8000295c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000295e:	00004717          	auipc	a4,0x4
    80002962:	73270713          	addi	a4,a4,1842 # 80007090 <userret>
    80002966:	8f11                	sub	a4,a4,a2
    80002968:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000296a:	577d                	li	a4,-1
    8000296c:	177e                	slli	a4,a4,0x3f
    8000296e:	8dd9                	or	a1,a1,a4
    80002970:	02000537          	lui	a0,0x2000
    80002974:	157d                	addi	a0,a0,-1
    80002976:	0536                	slli	a0,a0,0xd
    80002978:	9782                	jalr	a5
}
    8000297a:	60a2                	ld	ra,8(sp)
    8000297c:	6402                	ld	s0,0(sp)
    8000297e:	0141                	addi	sp,sp,16
    80002980:	8082                	ret

0000000080002982 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002982:	1101                	addi	sp,sp,-32
    80002984:	ec06                	sd	ra,24(sp)
    80002986:	e822                	sd	s0,16(sp)
    80002988:	e426                	sd	s1,8(sp)
    8000298a:	e04a                	sd	s2,0(sp)
    8000298c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000298e:	00015917          	auipc	s2,0x15
    80002992:	d4290913          	addi	s2,s2,-702 # 800176d0 <tickslock>
    80002996:	854a                	mv	a0,s2
    80002998:	ffffe097          	auipc	ra,0xffffe
    8000299c:	22a080e7          	jalr	554(ra) # 80000bc2 <acquire>
  ticks++;
    800029a0:	00006497          	auipc	s1,0x6
    800029a4:	69048493          	addi	s1,s1,1680 # 80009030 <ticks>
    800029a8:	4088                	lw	a0,0(s1)
    800029aa:	2505                	addiw	a0,a0,1
    800029ac:	c088                	sw	a0,0(s1)
  update_perfs(ticks);
    800029ae:	2501                	sext.w	a0,a0
    800029b0:	00000097          	auipc	ra,0x0
    800029b4:	e34080e7          	jalr	-460(ra) # 800027e4 <update_perfs>
  wakeup(&ticks);
    800029b8:	8526                	mv	a0,s1
    800029ba:	00000097          	auipc	ra,0x0
    800029be:	826080e7          	jalr	-2010(ra) # 800021e0 <wakeup>
  release(&tickslock);
    800029c2:	854a                	mv	a0,s2
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	2b2080e7          	jalr	690(ra) # 80000c76 <release>
}
    800029cc:	60e2                	ld	ra,24(sp)
    800029ce:	6442                	ld	s0,16(sp)
    800029d0:	64a2                	ld	s1,8(sp)
    800029d2:	6902                	ld	s2,0(sp)
    800029d4:	6105                	addi	sp,sp,32
    800029d6:	8082                	ret

00000000800029d8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800029d8:	1101                	addi	sp,sp,-32
    800029da:	ec06                	sd	ra,24(sp)
    800029dc:	e822                	sd	s0,16(sp)
    800029de:	e426                	sd	s1,8(sp)
    800029e0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029e2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800029e6:	00074d63          	bltz	a4,80002a00 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029ea:	57fd                	li	a5,-1
    800029ec:	17fe                	slli	a5,a5,0x3f
    800029ee:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029f0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029f2:	06f70363          	beq	a4,a5,80002a58 <devintr+0x80>
  }
}
    800029f6:	60e2                	ld	ra,24(sp)
    800029f8:	6442                	ld	s0,16(sp)
    800029fa:	64a2                	ld	s1,8(sp)
    800029fc:	6105                	addi	sp,sp,32
    800029fe:	8082                	ret
     (scause & 0xff) == 9){
    80002a00:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a04:	46a5                	li	a3,9
    80002a06:	fed792e3          	bne	a5,a3,800029ea <devintr+0x12>
    int irq = plic_claim();
    80002a0a:	00003097          	auipc	ra,0x3
    80002a0e:	5fe080e7          	jalr	1534(ra) # 80006008 <plic_claim>
    80002a12:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a14:	47a9                	li	a5,10
    80002a16:	02f50763          	beq	a0,a5,80002a44 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a1a:	4785                	li	a5,1
    80002a1c:	02f50963          	beq	a0,a5,80002a4e <devintr+0x76>
    return 1;
    80002a20:	4505                	li	a0,1
    } else if(irq){
    80002a22:	d8f1                	beqz	s1,800029f6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a24:	85a6                	mv	a1,s1
    80002a26:	00006517          	auipc	a0,0x6
    80002a2a:	8ba50513          	addi	a0,a0,-1862 # 800082e0 <states.0+0x38>
    80002a2e:	ffffe097          	auipc	ra,0xffffe
    80002a32:	b46080e7          	jalr	-1210(ra) # 80000574 <printf>
      plic_complete(irq);
    80002a36:	8526                	mv	a0,s1
    80002a38:	00003097          	auipc	ra,0x3
    80002a3c:	5f4080e7          	jalr	1524(ra) # 8000602c <plic_complete>
    return 1;
    80002a40:	4505                	li	a0,1
    80002a42:	bf55                	j	800029f6 <devintr+0x1e>
      uartintr();
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	f42080e7          	jalr	-190(ra) # 80000986 <uartintr>
    80002a4c:	b7ed                	j	80002a36 <devintr+0x5e>
      virtio_disk_intr();
    80002a4e:	00004097          	auipc	ra,0x4
    80002a52:	a70080e7          	jalr	-1424(ra) # 800064be <virtio_disk_intr>
    80002a56:	b7c5                	j	80002a36 <devintr+0x5e>
    if(cpuid() == 0){
    80002a58:	fffff097          	auipc	ra,0xfffff
    80002a5c:	efa080e7          	jalr	-262(ra) # 80001952 <cpuid>
    80002a60:	c901                	beqz	a0,80002a70 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a62:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a66:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a68:	14479073          	csrw	sip,a5
    return 2;
    80002a6c:	4509                	li	a0,2
    80002a6e:	b761                	j	800029f6 <devintr+0x1e>
      clockintr();
    80002a70:	00000097          	auipc	ra,0x0
    80002a74:	f12080e7          	jalr	-238(ra) # 80002982 <clockintr>
    80002a78:	b7ed                	j	80002a62 <devintr+0x8a>

0000000080002a7a <usertrap>:
{
    80002a7a:	1101                	addi	sp,sp,-32
    80002a7c:	ec06                	sd	ra,24(sp)
    80002a7e:	e822                	sd	s0,16(sp)
    80002a80:	e426                	sd	s1,8(sp)
    80002a82:	e04a                	sd	s2,0(sp)
    80002a84:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a86:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a8a:	1007f793          	andi	a5,a5,256
    80002a8e:	e3ad                	bnez	a5,80002af0 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a90:	00003797          	auipc	a5,0x3
    80002a94:	47078793          	addi	a5,a5,1136 # 80005f00 <kernelvec>
    80002a98:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a9c:	fffff097          	auipc	ra,0xfffff
    80002aa0:	ee2080e7          	jalr	-286(ra) # 8000197e <myproc>
    80002aa4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002aa6:	793c                	ld	a5,112(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aa8:	14102773          	csrr	a4,sepc
    80002aac:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aae:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ab2:	47a1                	li	a5,8
    80002ab4:	04f71c63          	bne	a4,a5,80002b0c <usertrap+0x92>
    if(p->killed)
    80002ab8:	551c                	lw	a5,40(a0)
    80002aba:	e3b9                	bnez	a5,80002b00 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002abc:	78b8                	ld	a4,112(s1)
    80002abe:	6f1c                	ld	a5,24(a4)
    80002ac0:	0791                	addi	a5,a5,4
    80002ac2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ac8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002acc:	10079073          	csrw	sstatus,a5
    syscall();
    80002ad0:	00000097          	auipc	ra,0x0
    80002ad4:	3ac080e7          	jalr	940(ra) # 80002e7c <syscall>
  if(p->killed)
    80002ad8:	549c                	lw	a5,40(s1)
    80002ada:	ebc1                	bnez	a5,80002b6a <usertrap+0xf0>
  usertrapret();
    80002adc:	00000097          	auipc	ra,0x0
    80002ae0:	e08080e7          	jalr	-504(ra) # 800028e4 <usertrapret>
}
    80002ae4:	60e2                	ld	ra,24(sp)
    80002ae6:	6442                	ld	s0,16(sp)
    80002ae8:	64a2                	ld	s1,8(sp)
    80002aea:	6902                	ld	s2,0(sp)
    80002aec:	6105                	addi	sp,sp,32
    80002aee:	8082                	ret
    panic("usertrap: not from user mode");
    80002af0:	00006517          	auipc	a0,0x6
    80002af4:	81050513          	addi	a0,a0,-2032 # 80008300 <states.0+0x58>
    80002af8:	ffffe097          	auipc	ra,0xffffe
    80002afc:	a32080e7          	jalr	-1486(ra) # 8000052a <panic>
      exit(-1);
    80002b00:	557d                	li	a0,-1
    80002b02:	fffff097          	auipc	ra,0xfffff
    80002b06:	7ae080e7          	jalr	1966(ra) # 800022b0 <exit>
    80002b0a:	bf4d                	j	80002abc <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b0c:	00000097          	auipc	ra,0x0
    80002b10:	ecc080e7          	jalr	-308(ra) # 800029d8 <devintr>
    80002b14:	892a                	mv	s2,a0
    80002b16:	c501                	beqz	a0,80002b1e <usertrap+0xa4>
  if(p->killed)
    80002b18:	549c                	lw	a5,40(s1)
    80002b1a:	c3a1                	beqz	a5,80002b5a <usertrap+0xe0>
    80002b1c:	a815                	j	80002b50 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b1e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b22:	5890                	lw	a2,48(s1)
    80002b24:	00005517          	auipc	a0,0x5
    80002b28:	7fc50513          	addi	a0,a0,2044 # 80008320 <states.0+0x78>
    80002b2c:	ffffe097          	auipc	ra,0xffffe
    80002b30:	a48080e7          	jalr	-1464(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b34:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b38:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b3c:	00006517          	auipc	a0,0x6
    80002b40:	81450513          	addi	a0,a0,-2028 # 80008350 <states.0+0xa8>
    80002b44:	ffffe097          	auipc	ra,0xffffe
    80002b48:	a30080e7          	jalr	-1488(ra) # 80000574 <printf>
    p->killed = 1;
    80002b4c:	4785                	li	a5,1
    80002b4e:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002b50:	557d                	li	a0,-1
    80002b52:	fffff097          	auipc	ra,0xfffff
    80002b56:	75e080e7          	jalr	1886(ra) # 800022b0 <exit>
  if(which_dev == 2)
    80002b5a:	4789                	li	a5,2
    80002b5c:	f8f910e3          	bne	s2,a5,80002adc <usertrap+0x62>
    yield();
    80002b60:	fffff097          	auipc	ra,0xfffff
    80002b64:	4b8080e7          	jalr	1208(ra) # 80002018 <yield>
    80002b68:	bf95                	j	80002adc <usertrap+0x62>
  int which_dev = 0;
    80002b6a:	4901                	li	s2,0
    80002b6c:	b7d5                	j	80002b50 <usertrap+0xd6>

0000000080002b6e <kerneltrap>:
{
    80002b6e:	7179                	addi	sp,sp,-48
    80002b70:	f406                	sd	ra,40(sp)
    80002b72:	f022                	sd	s0,32(sp)
    80002b74:	ec26                	sd	s1,24(sp)
    80002b76:	e84a                	sd	s2,16(sp)
    80002b78:	e44e                	sd	s3,8(sp)
    80002b7a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b7c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b80:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b84:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b88:	1004f793          	andi	a5,s1,256
    80002b8c:	cb85                	beqz	a5,80002bbc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b8e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b92:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b94:	ef85                	bnez	a5,80002bcc <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b96:	00000097          	auipc	ra,0x0
    80002b9a:	e42080e7          	jalr	-446(ra) # 800029d8 <devintr>
    80002b9e:	cd1d                	beqz	a0,80002bdc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ba0:	4789                	li	a5,2
    80002ba2:	06f50a63          	beq	a0,a5,80002c16 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ba6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002baa:	10049073          	csrw	sstatus,s1
}
    80002bae:	70a2                	ld	ra,40(sp)
    80002bb0:	7402                	ld	s0,32(sp)
    80002bb2:	64e2                	ld	s1,24(sp)
    80002bb4:	6942                	ld	s2,16(sp)
    80002bb6:	69a2                	ld	s3,8(sp)
    80002bb8:	6145                	addi	sp,sp,48
    80002bba:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002bbc:	00005517          	auipc	a0,0x5
    80002bc0:	7b450513          	addi	a0,a0,1972 # 80008370 <states.0+0xc8>
    80002bc4:	ffffe097          	auipc	ra,0xffffe
    80002bc8:	966080e7          	jalr	-1690(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002bcc:	00005517          	auipc	a0,0x5
    80002bd0:	7cc50513          	addi	a0,a0,1996 # 80008398 <states.0+0xf0>
    80002bd4:	ffffe097          	auipc	ra,0xffffe
    80002bd8:	956080e7          	jalr	-1706(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002bdc:	85ce                	mv	a1,s3
    80002bde:	00005517          	auipc	a0,0x5
    80002be2:	7da50513          	addi	a0,a0,2010 # 800083b8 <states.0+0x110>
    80002be6:	ffffe097          	auipc	ra,0xffffe
    80002bea:	98e080e7          	jalr	-1650(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bee:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bf2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bf6:	00005517          	auipc	a0,0x5
    80002bfa:	7d250513          	addi	a0,a0,2002 # 800083c8 <states.0+0x120>
    80002bfe:	ffffe097          	auipc	ra,0xffffe
    80002c02:	976080e7          	jalr	-1674(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002c06:	00005517          	auipc	a0,0x5
    80002c0a:	7da50513          	addi	a0,a0,2010 # 800083e0 <states.0+0x138>
    80002c0e:	ffffe097          	auipc	ra,0xffffe
    80002c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c16:	fffff097          	auipc	ra,0xfffff
    80002c1a:	d68080e7          	jalr	-664(ra) # 8000197e <myproc>
    80002c1e:	d541                	beqz	a0,80002ba6 <kerneltrap+0x38>
    80002c20:	fffff097          	auipc	ra,0xfffff
    80002c24:	d5e080e7          	jalr	-674(ra) # 8000197e <myproc>
    80002c28:	4d18                	lw	a4,24(a0)
    80002c2a:	4791                	li	a5,4
    80002c2c:	f6f71de3          	bne	a4,a5,80002ba6 <kerneltrap+0x38>
    yield();
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	3e8080e7          	jalr	1000(ra) # 80002018 <yield>
    80002c38:	b7bd                	j	80002ba6 <kerneltrap+0x38>

0000000080002c3a <argraw>:
	return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c3a:	1101                	addi	sp,sp,-32
    80002c3c:	ec06                	sd	ra,24(sp)
    80002c3e:	e822                	sd	s0,16(sp)
    80002c40:	e426                	sd	s1,8(sp)
    80002c42:	1000                	addi	s0,sp,32
    80002c44:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    80002c46:	fffff097          	auipc	ra,0xfffff
    80002c4a:	d38080e7          	jalr	-712(ra) # 8000197e <myproc>
	switch (n)
    80002c4e:	4795                	li	a5,5
    80002c50:	0497e163          	bltu	a5,s1,80002c92 <argraw+0x58>
    80002c54:	048a                	slli	s1,s1,0x2
    80002c56:	00006717          	auipc	a4,0x6
    80002c5a:	8da70713          	addi	a4,a4,-1830 # 80008530 <states.0+0x288>
    80002c5e:	94ba                	add	s1,s1,a4
    80002c60:	409c                	lw	a5,0(s1)
    80002c62:	97ba                	add	a5,a5,a4
    80002c64:	8782                	jr	a5
	{
	case 0:
		return p->trapframe->a0;
    80002c66:	793c                	ld	a5,112(a0)
    80002c68:	7ba8                	ld	a0,112(a5)
	case 5:
		return p->trapframe->a5;
	}
	panic("argraw");
	return -1;
}
    80002c6a:	60e2                	ld	ra,24(sp)
    80002c6c:	6442                	ld	s0,16(sp)
    80002c6e:	64a2                	ld	s1,8(sp)
    80002c70:	6105                	addi	sp,sp,32
    80002c72:	8082                	ret
		return p->trapframe->a1;
    80002c74:	793c                	ld	a5,112(a0)
    80002c76:	7fa8                	ld	a0,120(a5)
    80002c78:	bfcd                	j	80002c6a <argraw+0x30>
		return p->trapframe->a2;
    80002c7a:	793c                	ld	a5,112(a0)
    80002c7c:	63c8                	ld	a0,128(a5)
    80002c7e:	b7f5                	j	80002c6a <argraw+0x30>
		return p->trapframe->a3;
    80002c80:	793c                	ld	a5,112(a0)
    80002c82:	67c8                	ld	a0,136(a5)
    80002c84:	b7dd                	j	80002c6a <argraw+0x30>
		return p->trapframe->a4;
    80002c86:	793c                	ld	a5,112(a0)
    80002c88:	6bc8                	ld	a0,144(a5)
    80002c8a:	b7c5                	j	80002c6a <argraw+0x30>
		return p->trapframe->a5;
    80002c8c:	793c                	ld	a5,112(a0)
    80002c8e:	6fc8                	ld	a0,152(a5)
    80002c90:	bfe9                	j	80002c6a <argraw+0x30>
	panic("argraw");
    80002c92:	00005517          	auipc	a0,0x5
    80002c96:	75e50513          	addi	a0,a0,1886 # 800083f0 <states.0+0x148>
    80002c9a:	ffffe097          	auipc	ra,0xffffe
    80002c9e:	890080e7          	jalr	-1904(ra) # 8000052a <panic>

0000000080002ca2 <fetchaddr>:
{
    80002ca2:	1101                	addi	sp,sp,-32
    80002ca4:	ec06                	sd	ra,24(sp)
    80002ca6:	e822                	sd	s0,16(sp)
    80002ca8:	e426                	sd	s1,8(sp)
    80002caa:	e04a                	sd	s2,0(sp)
    80002cac:	1000                	addi	s0,sp,32
    80002cae:	84aa                	mv	s1,a0
    80002cb0:	892e                	mv	s2,a1
	struct proc *p = myproc();
    80002cb2:	fffff097          	auipc	ra,0xfffff
    80002cb6:	ccc080e7          	jalr	-820(ra) # 8000197e <myproc>
	if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002cba:	713c                	ld	a5,96(a0)
    80002cbc:	02f4f863          	bgeu	s1,a5,80002cec <fetchaddr+0x4a>
    80002cc0:	00848713          	addi	a4,s1,8
    80002cc4:	02e7e663          	bltu	a5,a4,80002cf0 <fetchaddr+0x4e>
	if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cc8:	46a1                	li	a3,8
    80002cca:	8626                	mv	a2,s1
    80002ccc:	85ca                	mv	a1,s2
    80002cce:	7528                	ld	a0,104(a0)
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	9fa080e7          	jalr	-1542(ra) # 800016ca <copyin>
    80002cd8:	00a03533          	snez	a0,a0
    80002cdc:	40a00533          	neg	a0,a0
}
    80002ce0:	60e2                	ld	ra,24(sp)
    80002ce2:	6442                	ld	s0,16(sp)
    80002ce4:	64a2                	ld	s1,8(sp)
    80002ce6:	6902                	ld	s2,0(sp)
    80002ce8:	6105                	addi	sp,sp,32
    80002cea:	8082                	ret
		return -1;
    80002cec:	557d                	li	a0,-1
    80002cee:	bfcd                	j	80002ce0 <fetchaddr+0x3e>
    80002cf0:	557d                	li	a0,-1
    80002cf2:	b7fd                	j	80002ce0 <fetchaddr+0x3e>

0000000080002cf4 <fetchstr>:
{
    80002cf4:	7179                	addi	sp,sp,-48
    80002cf6:	f406                	sd	ra,40(sp)
    80002cf8:	f022                	sd	s0,32(sp)
    80002cfa:	ec26                	sd	s1,24(sp)
    80002cfc:	e84a                	sd	s2,16(sp)
    80002cfe:	e44e                	sd	s3,8(sp)
    80002d00:	1800                	addi	s0,sp,48
    80002d02:	892a                	mv	s2,a0
    80002d04:	84ae                	mv	s1,a1
    80002d06:	89b2                	mv	s3,a2
	struct proc *p = myproc();
    80002d08:	fffff097          	auipc	ra,0xfffff
    80002d0c:	c76080e7          	jalr	-906(ra) # 8000197e <myproc>
	int err = copyinstr(p->pagetable, buf, addr, max);
    80002d10:	86ce                	mv	a3,s3
    80002d12:	864a                	mv	a2,s2
    80002d14:	85a6                	mv	a1,s1
    80002d16:	7528                	ld	a0,104(a0)
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	a40080e7          	jalr	-1472(ra) # 80001758 <copyinstr>
	if (err < 0)
    80002d20:	00054763          	bltz	a0,80002d2e <fetchstr+0x3a>
	return strlen(buf);
    80002d24:	8526                	mv	a0,s1
    80002d26:	ffffe097          	auipc	ra,0xffffe
    80002d2a:	11c080e7          	jalr	284(ra) # 80000e42 <strlen>
}
    80002d2e:	70a2                	ld	ra,40(sp)
    80002d30:	7402                	ld	s0,32(sp)
    80002d32:	64e2                	ld	s1,24(sp)
    80002d34:	6942                	ld	s2,16(sp)
    80002d36:	69a2                	ld	s3,8(sp)
    80002d38:	6145                	addi	sp,sp,48
    80002d3a:	8082                	ret

0000000080002d3c <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002d3c:	1101                	addi	sp,sp,-32
    80002d3e:	ec06                	sd	ra,24(sp)
    80002d40:	e822                	sd	s0,16(sp)
    80002d42:	e426                	sd	s1,8(sp)
    80002d44:	1000                	addi	s0,sp,32
    80002d46:	84ae                	mv	s1,a1
	*ip = argraw(n);
    80002d48:	00000097          	auipc	ra,0x0
    80002d4c:	ef2080e7          	jalr	-270(ra) # 80002c3a <argraw>
    80002d50:	c088                	sw	a0,0(s1)
	return 0;
}
    80002d52:	4501                	li	a0,0
    80002d54:	60e2                	ld	ra,24(sp)
    80002d56:	6442                	ld	s0,16(sp)
    80002d58:	64a2                	ld	s1,8(sp)
    80002d5a:	6105                	addi	sp,sp,32
    80002d5c:	8082                	ret

0000000080002d5e <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002d5e:	1101                	addi	sp,sp,-32
    80002d60:	ec06                	sd	ra,24(sp)
    80002d62:	e822                	sd	s0,16(sp)
    80002d64:	e426                	sd	s1,8(sp)
    80002d66:	1000                	addi	s0,sp,32
    80002d68:	84ae                	mv	s1,a1
	*ip = argraw(n);
    80002d6a:	00000097          	auipc	ra,0x0
    80002d6e:	ed0080e7          	jalr	-304(ra) # 80002c3a <argraw>
    80002d72:	e088                	sd	a0,0(s1)
	return 0;
}
    80002d74:	4501                	li	a0,0
    80002d76:	60e2                	ld	ra,24(sp)
    80002d78:	6442                	ld	s0,16(sp)
    80002d7a:	64a2                	ld	s1,8(sp)
    80002d7c:	6105                	addi	sp,sp,32
    80002d7e:	8082                	ret

0000000080002d80 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002d80:	1101                	addi	sp,sp,-32
    80002d82:	ec06                	sd	ra,24(sp)
    80002d84:	e822                	sd	s0,16(sp)
    80002d86:	e426                	sd	s1,8(sp)
    80002d88:	e04a                	sd	s2,0(sp)
    80002d8a:	1000                	addi	s0,sp,32
    80002d8c:	84ae                	mv	s1,a1
    80002d8e:	8932                	mv	s2,a2
	*ip = argraw(n);
    80002d90:	00000097          	auipc	ra,0x0
    80002d94:	eaa080e7          	jalr	-342(ra) # 80002c3a <argraw>
	uint64 addr;
	if (argaddr(n, &addr) < 0)
		return -1;
	return fetchstr(addr, buf, max);
    80002d98:	864a                	mv	a2,s2
    80002d9a:	85a6                	mv	a1,s1
    80002d9c:	00000097          	auipc	ra,0x0
    80002da0:	f58080e7          	jalr	-168(ra) # 80002cf4 <fetchstr>
}
    80002da4:	60e2                	ld	ra,24(sp)
    80002da6:	6442                	ld	s0,16(sp)
    80002da8:	64a2                	ld	s1,8(sp)
    80002daa:	6902                	ld	s2,0(sp)
    80002dac:	6105                	addi	sp,sp,32
    80002dae:	8082                	ret

0000000080002db0 <print_trace>:
	}
}

// ADDED
void print_trace(int arg)
{
    80002db0:	7179                	addi	sp,sp,-48
    80002db2:	f406                	sd	ra,40(sp)
    80002db4:	f022                	sd	s0,32(sp)
    80002db6:	ec26                	sd	s1,24(sp)
    80002db8:	e84a                	sd	s2,16(sp)
    80002dba:	e44e                	sd	s3,8(sp)
    80002dbc:	1800                	addi	s0,sp,48
    80002dbe:	89aa                	mv	s3,a0
	int num;
	struct proc *p = myproc();
    80002dc0:	fffff097          	auipc	ra,0xfffff
    80002dc4:	bbe080e7          	jalr	-1090(ra) # 8000197e <myproc>
	num = p->trapframe->a7;
    80002dc8:	793c                	ld	a5,112(a0)
    80002dca:	0a87a903          	lw	s2,168(a5)

	int res = (1 << num) & p->trace_mask;
    80002dce:	4785                	li	a5,1
    80002dd0:	012797bb          	sllw	a5,a5,s2
    80002dd4:	5958                	lw	a4,52(a0)
    80002dd6:	8ff9                	and	a5,a5,a4
	if (res != 0)
    80002dd8:	2781                	sext.w	a5,a5
    80002dda:	eb81                	bnez	a5,80002dea <print_trace+0x3a>
		else
		{
			printf("syscall %s  -> %d\n", syscallnames[num], p->trapframe->a0);
		}
	}
} // ADDED
    80002ddc:	70a2                	ld	ra,40(sp)
    80002dde:	7402                	ld	s0,32(sp)
    80002de0:	64e2                	ld	s1,24(sp)
    80002de2:	6942                	ld	s2,16(sp)
    80002de4:	69a2                	ld	s3,8(sp)
    80002de6:	6145                	addi	sp,sp,48
    80002de8:	8082                	ret
    80002dea:	84aa                	mv	s1,a0
		printf("%d: ", p->pid);
    80002dec:	590c                	lw	a1,48(a0)
    80002dee:	00005517          	auipc	a0,0x5
    80002df2:	60a50513          	addi	a0,a0,1546 # 800083f8 <states.0+0x150>
    80002df6:	ffffd097          	auipc	ra,0xffffd
    80002dfa:	77e080e7          	jalr	1918(ra) # 80000574 <printf>
		if (num == SYS_fork)
    80002dfe:	4785                	li	a5,1
    80002e00:	02f90c63          	beq	s2,a5,80002e38 <print_trace+0x88>
		else if (num == SYS_kill || num == SYS_sbrk)
    80002e04:	4799                	li	a5,6
    80002e06:	00f90563          	beq	s2,a5,80002e10 <print_trace+0x60>
    80002e0a:	47b1                	li	a5,12
    80002e0c:	04f91563          	bne	s2,a5,80002e56 <print_trace+0xa6>
			printf("syscall %s %d -> %d\n", syscallnames[num], arg, p->trapframe->a0);
    80002e10:	78b8                	ld	a4,112(s1)
    80002e12:	090e                	slli	s2,s2,0x3
    80002e14:	00005797          	auipc	a5,0x5
    80002e18:	73478793          	addi	a5,a5,1844 # 80008548 <syscallnames>
    80002e1c:	993e                	add	s2,s2,a5
    80002e1e:	7b34                	ld	a3,112(a4)
    80002e20:	864e                	mv	a2,s3
    80002e22:	00093583          	ld	a1,0(s2)
    80002e26:	00005517          	auipc	a0,0x5
    80002e2a:	5fa50513          	addi	a0,a0,1530 # 80008420 <states.0+0x178>
    80002e2e:	ffffd097          	auipc	ra,0xffffd
    80002e32:	746080e7          	jalr	1862(ra) # 80000574 <printf>
    80002e36:	b75d                	j	80002ddc <print_trace+0x2c>
			printf("syscall %s NULL -> %d\n", syscallnames[num], p->trapframe->a0);
    80002e38:	78bc                	ld	a5,112(s1)
    80002e3a:	7bb0                	ld	a2,112(a5)
    80002e3c:	00005597          	auipc	a1,0x5
    80002e40:	5c458593          	addi	a1,a1,1476 # 80008400 <states.0+0x158>
    80002e44:	00005517          	auipc	a0,0x5
    80002e48:	5c450513          	addi	a0,a0,1476 # 80008408 <states.0+0x160>
    80002e4c:	ffffd097          	auipc	ra,0xffffd
    80002e50:	728080e7          	jalr	1832(ra) # 80000574 <printf>
    80002e54:	b761                	j	80002ddc <print_trace+0x2c>
			printf("syscall %s  -> %d\n", syscallnames[num], p->trapframe->a0);
    80002e56:	78b8                	ld	a4,112(s1)
    80002e58:	090e                	slli	s2,s2,0x3
    80002e5a:	00005797          	auipc	a5,0x5
    80002e5e:	6ee78793          	addi	a5,a5,1774 # 80008548 <syscallnames>
    80002e62:	993e                	add	s2,s2,a5
    80002e64:	7b30                	ld	a2,112(a4)
    80002e66:	00093583          	ld	a1,0(s2)
    80002e6a:	00005517          	auipc	a0,0x5
    80002e6e:	5ce50513          	addi	a0,a0,1486 # 80008438 <states.0+0x190>
    80002e72:	ffffd097          	auipc	ra,0xffffd
    80002e76:	702080e7          	jalr	1794(ra) # 80000574 <printf>
} // ADDED
    80002e7a:	b78d                	j	80002ddc <print_trace+0x2c>

0000000080002e7c <syscall>:
{
    80002e7c:	7179                	addi	sp,sp,-48
    80002e7e:	f406                	sd	ra,40(sp)
    80002e80:	f022                	sd	s0,32(sp)
    80002e82:	ec26                	sd	s1,24(sp)
    80002e84:	e84a                	sd	s2,16(sp)
    80002e86:	1800                	addi	s0,sp,48
	struct proc *p = myproc();
    80002e88:	fffff097          	auipc	ra,0xfffff
    80002e8c:	af6080e7          	jalr	-1290(ra) # 8000197e <myproc>
    80002e90:	84aa                	mv	s1,a0
	num = p->trapframe->a7;
    80002e92:	793c                	ld	a5,112(a0)
    80002e94:	77dc                	ld	a5,168(a5)
    80002e96:	0007869b          	sext.w	a3,a5
	if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002e9a:	37fd                	addiw	a5,a5,-1
    80002e9c:	475d                	li	a4,23
    80002e9e:	02f76e63          	bltu	a4,a5,80002eda <syscall+0x5e>
    80002ea2:	00369713          	slli	a4,a3,0x3
    80002ea6:	00005797          	auipc	a5,0x5
    80002eaa:	6a278793          	addi	a5,a5,1698 # 80008548 <syscallnames>
    80002eae:	97ba                	add	a5,a5,a4
    80002eb0:	0c87b903          	ld	s2,200(a5)
    80002eb4:	02090363          	beqz	s2,80002eda <syscall+0x5e>
		argint(0, &arg); // ADDED
    80002eb8:	fdc40593          	addi	a1,s0,-36
    80002ebc:	4501                	li	a0,0
    80002ebe:	00000097          	auipc	ra,0x0
    80002ec2:	e7e080e7          	jalr	-386(ra) # 80002d3c <argint>
		p->trapframe->a0 = syscalls[num]();
    80002ec6:	78a4                	ld	s1,112(s1)
    80002ec8:	9902                	jalr	s2
    80002eca:	f8a8                	sd	a0,112(s1)
		print_trace(arg); // ADDED
    80002ecc:	fdc42503          	lw	a0,-36(s0)
    80002ed0:	00000097          	auipc	ra,0x0
    80002ed4:	ee0080e7          	jalr	-288(ra) # 80002db0 <print_trace>
    80002ed8:	a839                	j	80002ef6 <syscall+0x7a>
		printf("%d %s: unknown sys call %d\n",
    80002eda:	17048613          	addi	a2,s1,368
    80002ede:	588c                	lw	a1,48(s1)
    80002ee0:	00005517          	auipc	a0,0x5
    80002ee4:	57050513          	addi	a0,a0,1392 # 80008450 <states.0+0x1a8>
    80002ee8:	ffffd097          	auipc	ra,0xffffd
    80002eec:	68c080e7          	jalr	1676(ra) # 80000574 <printf>
		p->trapframe->a0 = -1;
    80002ef0:	78bc                	ld	a5,112(s1)
    80002ef2:	577d                	li	a4,-1
    80002ef4:	fbb8                	sd	a4,112(a5)
}
    80002ef6:	70a2                	ld	ra,40(sp)
    80002ef8:	7402                	ld	s0,32(sp)
    80002efa:	64e2                	ld	s1,24(sp)
    80002efc:	6942                	ld	s2,16(sp)
    80002efe:	6145                	addi	sp,sp,48
    80002f00:	8082                	ret

0000000080002f02 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f02:	1101                	addi	sp,sp,-32
    80002f04:	ec06                	sd	ra,24(sp)
    80002f06:	e822                	sd	s0,16(sp)
    80002f08:	1000                	addi	s0,sp,32
  int n;
  if (argint(0, &n) < 0)
    80002f0a:	fec40593          	addi	a1,s0,-20
    80002f0e:	4501                	li	a0,0
    80002f10:	00000097          	auipc	ra,0x0
    80002f14:	e2c080e7          	jalr	-468(ra) # 80002d3c <argint>
    return -1;
    80002f18:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80002f1a:	00054963          	bltz	a0,80002f2c <sys_exit+0x2a>
  exit(n);
    80002f1e:	fec42503          	lw	a0,-20(s0)
    80002f22:	fffff097          	auipc	ra,0xfffff
    80002f26:	38e080e7          	jalr	910(ra) # 800022b0 <exit>
  return 0; // not reached
    80002f2a:	4781                	li	a5,0
}
    80002f2c:	853e                	mv	a0,a5
    80002f2e:	60e2                	ld	ra,24(sp)
    80002f30:	6442                	ld	s0,16(sp)
    80002f32:	6105                	addi	sp,sp,32
    80002f34:	8082                	ret

0000000080002f36 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f36:	1141                	addi	sp,sp,-16
    80002f38:	e406                	sd	ra,8(sp)
    80002f3a:	e022                	sd	s0,0(sp)
    80002f3c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f3e:	fffff097          	auipc	ra,0xfffff
    80002f42:	a40080e7          	jalr	-1472(ra) # 8000197e <myproc>
}
    80002f46:	5908                	lw	a0,48(a0)
    80002f48:	60a2                	ld	ra,8(sp)
    80002f4a:	6402                	ld	s0,0(sp)
    80002f4c:	0141                	addi	sp,sp,16
    80002f4e:	8082                	ret

0000000080002f50 <sys_fork>:

uint64
sys_fork(void)
{
    80002f50:	1141                	addi	sp,sp,-16
    80002f52:	e406                	sd	ra,8(sp)
    80002f54:	e022                	sd	s0,0(sp)
    80002f56:	0800                	addi	s0,sp,16
  return fork();
    80002f58:	fffff097          	auipc	ra,0xfffff
    80002f5c:	e02080e7          	jalr	-510(ra) # 80001d5a <fork>
}
    80002f60:	60a2                	ld	ra,8(sp)
    80002f62:	6402                	ld	s0,0(sp)
    80002f64:	0141                	addi	sp,sp,16
    80002f66:	8082                	ret

0000000080002f68 <sys_wait>:

uint64
sys_wait(void)
{
    80002f68:	1101                	addi	sp,sp,-32
    80002f6a:	ec06                	sd	ra,24(sp)
    80002f6c:	e822                	sd	s0,16(sp)
    80002f6e:	1000                	addi	s0,sp,32
  uint64 p;
  if (argaddr(0, &p) < 0)
    80002f70:	fe840593          	addi	a1,s0,-24
    80002f74:	4501                	li	a0,0
    80002f76:	00000097          	auipc	ra,0x0
    80002f7a:	de8080e7          	jalr	-536(ra) # 80002d5e <argaddr>
    80002f7e:	87aa                	mv	a5,a0
    return -1;
    80002f80:	557d                	li	a0,-1
  if (argaddr(0, &p) < 0)
    80002f82:	0007c863          	bltz	a5,80002f92 <sys_wait+0x2a>
  return wait(p);
    80002f86:	fe843503          	ld	a0,-24(s0)
    80002f8a:	fffff097          	auipc	ra,0xfffff
    80002f8e:	12e080e7          	jalr	302(ra) # 800020b8 <wait>
}
    80002f92:	60e2                	ld	ra,24(sp)
    80002f94:	6442                	ld	s0,16(sp)
    80002f96:	6105                	addi	sp,sp,32
    80002f98:	8082                	ret

0000000080002f9a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f9a:	7179                	addi	sp,sp,-48
    80002f9c:	f406                	sd	ra,40(sp)
    80002f9e:	f022                	sd	s0,32(sp)
    80002fa0:	ec26                	sd	s1,24(sp)
    80002fa2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if (argint(0, &n) < 0)
    80002fa4:	fdc40593          	addi	a1,s0,-36
    80002fa8:	4501                	li	a0,0
    80002faa:	00000097          	auipc	ra,0x0
    80002fae:	d92080e7          	jalr	-622(ra) # 80002d3c <argint>
    return -1;
    80002fb2:	54fd                	li	s1,-1
  if (argint(0, &n) < 0)
    80002fb4:	00054f63          	bltz	a0,80002fd2 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002fb8:	fffff097          	auipc	ra,0xfffff
    80002fbc:	9c6080e7          	jalr	-1594(ra) # 8000197e <myproc>
    80002fc0:	5124                	lw	s1,96(a0)
  if (growproc(n) < 0)
    80002fc2:	fdc42503          	lw	a0,-36(s0)
    80002fc6:	fffff097          	auipc	ra,0xfffff
    80002fca:	d20080e7          	jalr	-736(ra) # 80001ce6 <growproc>
    80002fce:	00054863          	bltz	a0,80002fde <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002fd2:	8526                	mv	a0,s1
    80002fd4:	70a2                	ld	ra,40(sp)
    80002fd6:	7402                	ld	s0,32(sp)
    80002fd8:	64e2                	ld	s1,24(sp)
    80002fda:	6145                	addi	sp,sp,48
    80002fdc:	8082                	ret
    return -1;
    80002fde:	54fd                	li	s1,-1
    80002fe0:	bfcd                	j	80002fd2 <sys_sbrk+0x38>

0000000080002fe2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fe2:	7139                	addi	sp,sp,-64
    80002fe4:	fc06                	sd	ra,56(sp)
    80002fe6:	f822                	sd	s0,48(sp)
    80002fe8:	f426                	sd	s1,40(sp)
    80002fea:	f04a                	sd	s2,32(sp)
    80002fec:	ec4e                	sd	s3,24(sp)
    80002fee:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if (argint(0, &n) < 0)
    80002ff0:	fcc40593          	addi	a1,s0,-52
    80002ff4:	4501                	li	a0,0
    80002ff6:	00000097          	auipc	ra,0x0
    80002ffa:	d46080e7          	jalr	-698(ra) # 80002d3c <argint>
    return -1;
    80002ffe:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80003000:	06054563          	bltz	a0,8000306a <sys_sleep+0x88>
  acquire(&tickslock);
    80003004:	00014517          	auipc	a0,0x14
    80003008:	6cc50513          	addi	a0,a0,1740 # 800176d0 <tickslock>
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	bb6080e7          	jalr	-1098(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80003014:	00006917          	auipc	s2,0x6
    80003018:	01c92903          	lw	s2,28(s2) # 80009030 <ticks>
  while (ticks - ticks0 < n)
    8000301c:	fcc42783          	lw	a5,-52(s0)
    80003020:	cf85                	beqz	a5,80003058 <sys_sleep+0x76>
    if (myproc()->killed)
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003022:	00014997          	auipc	s3,0x14
    80003026:	6ae98993          	addi	s3,s3,1710 # 800176d0 <tickslock>
    8000302a:	00006497          	auipc	s1,0x6
    8000302e:	00648493          	addi	s1,s1,6 # 80009030 <ticks>
    if (myproc()->killed)
    80003032:	fffff097          	auipc	ra,0xfffff
    80003036:	94c080e7          	jalr	-1716(ra) # 8000197e <myproc>
    8000303a:	551c                	lw	a5,40(a0)
    8000303c:	ef9d                	bnez	a5,8000307a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000303e:	85ce                	mv	a1,s3
    80003040:	8526                	mv	a0,s1
    80003042:	fffff097          	auipc	ra,0xfffff
    80003046:	012080e7          	jalr	18(ra) # 80002054 <sleep>
  while (ticks - ticks0 < n)
    8000304a:	409c                	lw	a5,0(s1)
    8000304c:	412787bb          	subw	a5,a5,s2
    80003050:	fcc42703          	lw	a4,-52(s0)
    80003054:	fce7efe3          	bltu	a5,a4,80003032 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003058:	00014517          	auipc	a0,0x14
    8000305c:	67850513          	addi	a0,a0,1656 # 800176d0 <tickslock>
    80003060:	ffffe097          	auipc	ra,0xffffe
    80003064:	c16080e7          	jalr	-1002(ra) # 80000c76 <release>
  return 0;
    80003068:	4781                	li	a5,0
}
    8000306a:	853e                	mv	a0,a5
    8000306c:	70e2                	ld	ra,56(sp)
    8000306e:	7442                	ld	s0,48(sp)
    80003070:	74a2                	ld	s1,40(sp)
    80003072:	7902                	ld	s2,32(sp)
    80003074:	69e2                	ld	s3,24(sp)
    80003076:	6121                	addi	sp,sp,64
    80003078:	8082                	ret
      release(&tickslock);
    8000307a:	00014517          	auipc	a0,0x14
    8000307e:	65650513          	addi	a0,a0,1622 # 800176d0 <tickslock>
    80003082:	ffffe097          	auipc	ra,0xffffe
    80003086:	bf4080e7          	jalr	-1036(ra) # 80000c76 <release>
      return -1;
    8000308a:	57fd                	li	a5,-1
    8000308c:	bff9                	j	8000306a <sys_sleep+0x88>

000000008000308e <sys_kill>:

uint64
sys_kill(void)
{
    8000308e:	1101                	addi	sp,sp,-32
    80003090:	ec06                	sd	ra,24(sp)
    80003092:	e822                	sd	s0,16(sp)
    80003094:	1000                	addi	s0,sp,32
  int pid;

  if (argint(0, &pid) < 0)
    80003096:	fec40593          	addi	a1,s0,-20
    8000309a:	4501                	li	a0,0
    8000309c:	00000097          	auipc	ra,0x0
    800030a0:	ca0080e7          	jalr	-864(ra) # 80002d3c <argint>
    800030a4:	87aa                	mv	a5,a0
    return -1;
    800030a6:	557d                	li	a0,-1
  if (argint(0, &pid) < 0)
    800030a8:	0007c863          	bltz	a5,800030b8 <sys_kill+0x2a>
  return kill(pid);
    800030ac:	fec42503          	lw	a0,-20(s0)
    800030b0:	fffff097          	auipc	ra,0xfffff
    800030b4:	2d6080e7          	jalr	726(ra) # 80002386 <kill>
}
    800030b8:	60e2                	ld	ra,24(sp)
    800030ba:	6442                	ld	s0,16(sp)
    800030bc:	6105                	addi	sp,sp,32
    800030be:	8082                	ret

00000000800030c0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030c0:	1101                	addi	sp,sp,-32
    800030c2:	ec06                	sd	ra,24(sp)
    800030c4:	e822                	sd	s0,16(sp)
    800030c6:	e426                	sd	s1,8(sp)
    800030c8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030ca:	00014517          	auipc	a0,0x14
    800030ce:	60650513          	addi	a0,a0,1542 # 800176d0 <tickslock>
    800030d2:	ffffe097          	auipc	ra,0xffffe
    800030d6:	af0080e7          	jalr	-1296(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800030da:	00006497          	auipc	s1,0x6
    800030de:	f564a483          	lw	s1,-170(s1) # 80009030 <ticks>
  release(&tickslock);
    800030e2:	00014517          	auipc	a0,0x14
    800030e6:	5ee50513          	addi	a0,a0,1518 # 800176d0 <tickslock>
    800030ea:	ffffe097          	auipc	ra,0xffffe
    800030ee:	b8c080e7          	jalr	-1140(ra) # 80000c76 <release>
  return xticks;
}
    800030f2:	02049513          	slli	a0,s1,0x20
    800030f6:	9101                	srli	a0,a0,0x20
    800030f8:	60e2                	ld	ra,24(sp)
    800030fa:	6442                	ld	s0,16(sp)
    800030fc:	64a2                	ld	s1,8(sp)
    800030fe:	6105                	addi	sp,sp,32
    80003100:	8082                	ret

0000000080003102 <sys_trace>:

//ADDED
uint64
sys_trace(void)
{
    80003102:	1101                	addi	sp,sp,-32
    80003104:	ec06                	sd	ra,24(sp)
    80003106:	e822                	sd	s0,16(sp)
    80003108:	1000                	addi	s0,sp,32
  int mask, pid;
  argint(0, &mask);
    8000310a:	fec40593          	addi	a1,s0,-20
    8000310e:	4501                	li	a0,0
    80003110:	00000097          	auipc	ra,0x0
    80003114:	c2c080e7          	jalr	-980(ra) # 80002d3c <argint>
  argint(1, &pid);
    80003118:	fe840593          	addi	a1,s0,-24
    8000311c:	4505                	li	a0,1
    8000311e:	00000097          	auipc	ra,0x0
    80003122:	c1e080e7          	jalr	-994(ra) # 80002d3c <argint>
  trace(mask, pid);
    80003126:	fe842583          	lw	a1,-24(s0)
    8000312a:	fec42503          	lw	a0,-20(s0)
    8000312e:	fffff097          	auipc	ra,0xfffff
    80003132:	426080e7          	jalr	1062(ra) # 80002554 <trace>
  return 0;
}
    80003136:	4501                	li	a0,0
    80003138:	60e2                	ld	ra,24(sp)
    8000313a:	6442                	ld	s0,16(sp)
    8000313c:	6105                	addi	sp,sp,32
    8000313e:	8082                	ret

0000000080003140 <sys_getmsk>:

uint64
sys_getmsk(void)
{
    80003140:	1101                	addi	sp,sp,-32
    80003142:	ec06                	sd	ra,24(sp)
    80003144:	e822                	sd	s0,16(sp)
    80003146:	1000                	addi	s0,sp,32
  int pid;
  argint(0, &pid);
    80003148:	fec40593          	addi	a1,s0,-20
    8000314c:	4501                	li	a0,0
    8000314e:	00000097          	auipc	ra,0x0
    80003152:	bee080e7          	jalr	-1042(ra) # 80002d3c <argint>
  return getmsk(pid);
    80003156:	fec42503          	lw	a0,-20(s0)
    8000315a:	fffff097          	auipc	ra,0xfffff
    8000315e:	464080e7          	jalr	1124(ra) # 800025be <getmsk>
}
    80003162:	60e2                	ld	ra,24(sp)
    80003164:	6442                	ld	s0,16(sp)
    80003166:	6105                	addi	sp,sp,32
    80003168:	8082                	ret

000000008000316a <sys_wait_stat>:

uint64
sys_wait_stat(void)
{
    8000316a:	1101                	addi	sp,sp,-32
    8000316c:	ec06                	sd	ra,24(sp)
    8000316e:	e822                	sd	s0,16(sp)
    80003170:	1000                	addi	s0,sp,32
  uint64 status;
  uint64 performance;
  argaddr(0,  &status);
    80003172:	fe840593          	addi	a1,s0,-24
    80003176:	4501                	li	a0,0
    80003178:	00000097          	auipc	ra,0x0
    8000317c:	be6080e7          	jalr	-1050(ra) # 80002d5e <argaddr>
  argaddr(1,  &performance);
    80003180:	fe040593          	addi	a1,s0,-32
    80003184:	4505                	li	a0,1
    80003186:	00000097          	auipc	ra,0x0
    8000318a:	bd8080e7          	jalr	-1064(ra) # 80002d5e <argaddr>
  return wait_stat(status, performance);
    8000318e:	fe043583          	ld	a1,-32(s0)
    80003192:	fe843503          	ld	a0,-24(s0)
    80003196:	fffff097          	auipc	ra,0xfffff
    8000319a:	4d8080e7          	jalr	1240(ra) # 8000266e <wait_stat>
}
    8000319e:	60e2                	ld	ra,24(sp)
    800031a0:	6442                	ld	s0,16(sp)
    800031a2:	6105                	addi	sp,sp,32
    800031a4:	8082                	ret

00000000800031a6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800031a6:	7179                	addi	sp,sp,-48
    800031a8:	f406                	sd	ra,40(sp)
    800031aa:	f022                	sd	s0,32(sp)
    800031ac:	ec26                	sd	s1,24(sp)
    800031ae:	e84a                	sd	s2,16(sp)
    800031b0:	e44e                	sd	s3,8(sp)
    800031b2:	e052                	sd	s4,0(sp)
    800031b4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800031b6:	00005597          	auipc	a1,0x5
    800031ba:	52258593          	addi	a1,a1,1314 # 800086d8 <syscalls+0xc8>
    800031be:	00014517          	auipc	a0,0x14
    800031c2:	52a50513          	addi	a0,a0,1322 # 800176e8 <bcache>
    800031c6:	ffffe097          	auipc	ra,0xffffe
    800031ca:	96c080e7          	jalr	-1684(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031ce:	0001c797          	auipc	a5,0x1c
    800031d2:	51a78793          	addi	a5,a5,1306 # 8001f6e8 <bcache+0x8000>
    800031d6:	0001c717          	auipc	a4,0x1c
    800031da:	77a70713          	addi	a4,a4,1914 # 8001f950 <bcache+0x8268>
    800031de:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031e2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031e6:	00014497          	auipc	s1,0x14
    800031ea:	51a48493          	addi	s1,s1,1306 # 80017700 <bcache+0x18>
    b->next = bcache.head.next;
    800031ee:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800031f0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800031f2:	00005a17          	auipc	s4,0x5
    800031f6:	4eea0a13          	addi	s4,s4,1262 # 800086e0 <syscalls+0xd0>
    b->next = bcache.head.next;
    800031fa:	2b893783          	ld	a5,696(s2)
    800031fe:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003200:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003204:	85d2                	mv	a1,s4
    80003206:	01048513          	addi	a0,s1,16
    8000320a:	00001097          	auipc	ra,0x1
    8000320e:	4c2080e7          	jalr	1218(ra) # 800046cc <initsleeplock>
    bcache.head.next->prev = b;
    80003212:	2b893783          	ld	a5,696(s2)
    80003216:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003218:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000321c:	45848493          	addi	s1,s1,1112
    80003220:	fd349de3          	bne	s1,s3,800031fa <binit+0x54>
  }
}
    80003224:	70a2                	ld	ra,40(sp)
    80003226:	7402                	ld	s0,32(sp)
    80003228:	64e2                	ld	s1,24(sp)
    8000322a:	6942                	ld	s2,16(sp)
    8000322c:	69a2                	ld	s3,8(sp)
    8000322e:	6a02                	ld	s4,0(sp)
    80003230:	6145                	addi	sp,sp,48
    80003232:	8082                	ret

0000000080003234 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003234:	7179                	addi	sp,sp,-48
    80003236:	f406                	sd	ra,40(sp)
    80003238:	f022                	sd	s0,32(sp)
    8000323a:	ec26                	sd	s1,24(sp)
    8000323c:	e84a                	sd	s2,16(sp)
    8000323e:	e44e                	sd	s3,8(sp)
    80003240:	1800                	addi	s0,sp,48
    80003242:	892a                	mv	s2,a0
    80003244:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003246:	00014517          	auipc	a0,0x14
    8000324a:	4a250513          	addi	a0,a0,1186 # 800176e8 <bcache>
    8000324e:	ffffe097          	auipc	ra,0xffffe
    80003252:	974080e7          	jalr	-1676(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003256:	0001c497          	auipc	s1,0x1c
    8000325a:	74a4b483          	ld	s1,1866(s1) # 8001f9a0 <bcache+0x82b8>
    8000325e:	0001c797          	auipc	a5,0x1c
    80003262:	6f278793          	addi	a5,a5,1778 # 8001f950 <bcache+0x8268>
    80003266:	02f48f63          	beq	s1,a5,800032a4 <bread+0x70>
    8000326a:	873e                	mv	a4,a5
    8000326c:	a021                	j	80003274 <bread+0x40>
    8000326e:	68a4                	ld	s1,80(s1)
    80003270:	02e48a63          	beq	s1,a4,800032a4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003274:	449c                	lw	a5,8(s1)
    80003276:	ff279ce3          	bne	a5,s2,8000326e <bread+0x3a>
    8000327a:	44dc                	lw	a5,12(s1)
    8000327c:	ff3799e3          	bne	a5,s3,8000326e <bread+0x3a>
      b->refcnt++;
    80003280:	40bc                	lw	a5,64(s1)
    80003282:	2785                	addiw	a5,a5,1
    80003284:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003286:	00014517          	auipc	a0,0x14
    8000328a:	46250513          	addi	a0,a0,1122 # 800176e8 <bcache>
    8000328e:	ffffe097          	auipc	ra,0xffffe
    80003292:	9e8080e7          	jalr	-1560(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003296:	01048513          	addi	a0,s1,16
    8000329a:	00001097          	auipc	ra,0x1
    8000329e:	46c080e7          	jalr	1132(ra) # 80004706 <acquiresleep>
      return b;
    800032a2:	a8b9                	j	80003300 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032a4:	0001c497          	auipc	s1,0x1c
    800032a8:	6f44b483          	ld	s1,1780(s1) # 8001f998 <bcache+0x82b0>
    800032ac:	0001c797          	auipc	a5,0x1c
    800032b0:	6a478793          	addi	a5,a5,1700 # 8001f950 <bcache+0x8268>
    800032b4:	00f48863          	beq	s1,a5,800032c4 <bread+0x90>
    800032b8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032ba:	40bc                	lw	a5,64(s1)
    800032bc:	cf81                	beqz	a5,800032d4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032be:	64a4                	ld	s1,72(s1)
    800032c0:	fee49de3          	bne	s1,a4,800032ba <bread+0x86>
  panic("bget: no buffers");
    800032c4:	00005517          	auipc	a0,0x5
    800032c8:	42450513          	addi	a0,a0,1060 # 800086e8 <syscalls+0xd8>
    800032cc:	ffffd097          	auipc	ra,0xffffd
    800032d0:	25e080e7          	jalr	606(ra) # 8000052a <panic>
      b->dev = dev;
    800032d4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800032d8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800032dc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032e0:	4785                	li	a5,1
    800032e2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032e4:	00014517          	auipc	a0,0x14
    800032e8:	40450513          	addi	a0,a0,1028 # 800176e8 <bcache>
    800032ec:	ffffe097          	auipc	ra,0xffffe
    800032f0:	98a080e7          	jalr	-1654(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800032f4:	01048513          	addi	a0,s1,16
    800032f8:	00001097          	auipc	ra,0x1
    800032fc:	40e080e7          	jalr	1038(ra) # 80004706 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003300:	409c                	lw	a5,0(s1)
    80003302:	cb89                	beqz	a5,80003314 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003304:	8526                	mv	a0,s1
    80003306:	70a2                	ld	ra,40(sp)
    80003308:	7402                	ld	s0,32(sp)
    8000330a:	64e2                	ld	s1,24(sp)
    8000330c:	6942                	ld	s2,16(sp)
    8000330e:	69a2                	ld	s3,8(sp)
    80003310:	6145                	addi	sp,sp,48
    80003312:	8082                	ret
    virtio_disk_rw(b, 0);
    80003314:	4581                	li	a1,0
    80003316:	8526                	mv	a0,s1
    80003318:	00003097          	auipc	ra,0x3
    8000331c:	f1e080e7          	jalr	-226(ra) # 80006236 <virtio_disk_rw>
    b->valid = 1;
    80003320:	4785                	li	a5,1
    80003322:	c09c                	sw	a5,0(s1)
  return b;
    80003324:	b7c5                	j	80003304 <bread+0xd0>

0000000080003326 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003326:	1101                	addi	sp,sp,-32
    80003328:	ec06                	sd	ra,24(sp)
    8000332a:	e822                	sd	s0,16(sp)
    8000332c:	e426                	sd	s1,8(sp)
    8000332e:	1000                	addi	s0,sp,32
    80003330:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003332:	0541                	addi	a0,a0,16
    80003334:	00001097          	auipc	ra,0x1
    80003338:	46c080e7          	jalr	1132(ra) # 800047a0 <holdingsleep>
    8000333c:	cd01                	beqz	a0,80003354 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000333e:	4585                	li	a1,1
    80003340:	8526                	mv	a0,s1
    80003342:	00003097          	auipc	ra,0x3
    80003346:	ef4080e7          	jalr	-268(ra) # 80006236 <virtio_disk_rw>
}
    8000334a:	60e2                	ld	ra,24(sp)
    8000334c:	6442                	ld	s0,16(sp)
    8000334e:	64a2                	ld	s1,8(sp)
    80003350:	6105                	addi	sp,sp,32
    80003352:	8082                	ret
    panic("bwrite");
    80003354:	00005517          	auipc	a0,0x5
    80003358:	3ac50513          	addi	a0,a0,940 # 80008700 <syscalls+0xf0>
    8000335c:	ffffd097          	auipc	ra,0xffffd
    80003360:	1ce080e7          	jalr	462(ra) # 8000052a <panic>

0000000080003364 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003364:	1101                	addi	sp,sp,-32
    80003366:	ec06                	sd	ra,24(sp)
    80003368:	e822                	sd	s0,16(sp)
    8000336a:	e426                	sd	s1,8(sp)
    8000336c:	e04a                	sd	s2,0(sp)
    8000336e:	1000                	addi	s0,sp,32
    80003370:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003372:	01050913          	addi	s2,a0,16
    80003376:	854a                	mv	a0,s2
    80003378:	00001097          	auipc	ra,0x1
    8000337c:	428080e7          	jalr	1064(ra) # 800047a0 <holdingsleep>
    80003380:	c92d                	beqz	a0,800033f2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003382:	854a                	mv	a0,s2
    80003384:	00001097          	auipc	ra,0x1
    80003388:	3d8080e7          	jalr	984(ra) # 8000475c <releasesleep>

  acquire(&bcache.lock);
    8000338c:	00014517          	auipc	a0,0x14
    80003390:	35c50513          	addi	a0,a0,860 # 800176e8 <bcache>
    80003394:	ffffe097          	auipc	ra,0xffffe
    80003398:	82e080e7          	jalr	-2002(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000339c:	40bc                	lw	a5,64(s1)
    8000339e:	37fd                	addiw	a5,a5,-1
    800033a0:	0007871b          	sext.w	a4,a5
    800033a4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800033a6:	eb05                	bnez	a4,800033d6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800033a8:	68bc                	ld	a5,80(s1)
    800033aa:	64b8                	ld	a4,72(s1)
    800033ac:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800033ae:	64bc                	ld	a5,72(s1)
    800033b0:	68b8                	ld	a4,80(s1)
    800033b2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800033b4:	0001c797          	auipc	a5,0x1c
    800033b8:	33478793          	addi	a5,a5,820 # 8001f6e8 <bcache+0x8000>
    800033bc:	2b87b703          	ld	a4,696(a5)
    800033c0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033c2:	0001c717          	auipc	a4,0x1c
    800033c6:	58e70713          	addi	a4,a4,1422 # 8001f950 <bcache+0x8268>
    800033ca:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033cc:	2b87b703          	ld	a4,696(a5)
    800033d0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033d2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800033d6:	00014517          	auipc	a0,0x14
    800033da:	31250513          	addi	a0,a0,786 # 800176e8 <bcache>
    800033de:	ffffe097          	auipc	ra,0xffffe
    800033e2:	898080e7          	jalr	-1896(ra) # 80000c76 <release>
}
    800033e6:	60e2                	ld	ra,24(sp)
    800033e8:	6442                	ld	s0,16(sp)
    800033ea:	64a2                	ld	s1,8(sp)
    800033ec:	6902                	ld	s2,0(sp)
    800033ee:	6105                	addi	sp,sp,32
    800033f0:	8082                	ret
    panic("brelse");
    800033f2:	00005517          	auipc	a0,0x5
    800033f6:	31650513          	addi	a0,a0,790 # 80008708 <syscalls+0xf8>
    800033fa:	ffffd097          	auipc	ra,0xffffd
    800033fe:	130080e7          	jalr	304(ra) # 8000052a <panic>

0000000080003402 <bpin>:

void
bpin(struct buf *b) {
    80003402:	1101                	addi	sp,sp,-32
    80003404:	ec06                	sd	ra,24(sp)
    80003406:	e822                	sd	s0,16(sp)
    80003408:	e426                	sd	s1,8(sp)
    8000340a:	1000                	addi	s0,sp,32
    8000340c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000340e:	00014517          	auipc	a0,0x14
    80003412:	2da50513          	addi	a0,a0,730 # 800176e8 <bcache>
    80003416:	ffffd097          	auipc	ra,0xffffd
    8000341a:	7ac080e7          	jalr	1964(ra) # 80000bc2 <acquire>
  b->refcnt++;
    8000341e:	40bc                	lw	a5,64(s1)
    80003420:	2785                	addiw	a5,a5,1
    80003422:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003424:	00014517          	auipc	a0,0x14
    80003428:	2c450513          	addi	a0,a0,708 # 800176e8 <bcache>
    8000342c:	ffffe097          	auipc	ra,0xffffe
    80003430:	84a080e7          	jalr	-1974(ra) # 80000c76 <release>
}
    80003434:	60e2                	ld	ra,24(sp)
    80003436:	6442                	ld	s0,16(sp)
    80003438:	64a2                	ld	s1,8(sp)
    8000343a:	6105                	addi	sp,sp,32
    8000343c:	8082                	ret

000000008000343e <bunpin>:

void
bunpin(struct buf *b) {
    8000343e:	1101                	addi	sp,sp,-32
    80003440:	ec06                	sd	ra,24(sp)
    80003442:	e822                	sd	s0,16(sp)
    80003444:	e426                	sd	s1,8(sp)
    80003446:	1000                	addi	s0,sp,32
    80003448:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000344a:	00014517          	auipc	a0,0x14
    8000344e:	29e50513          	addi	a0,a0,670 # 800176e8 <bcache>
    80003452:	ffffd097          	auipc	ra,0xffffd
    80003456:	770080e7          	jalr	1904(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000345a:	40bc                	lw	a5,64(s1)
    8000345c:	37fd                	addiw	a5,a5,-1
    8000345e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003460:	00014517          	auipc	a0,0x14
    80003464:	28850513          	addi	a0,a0,648 # 800176e8 <bcache>
    80003468:	ffffe097          	auipc	ra,0xffffe
    8000346c:	80e080e7          	jalr	-2034(ra) # 80000c76 <release>
}
    80003470:	60e2                	ld	ra,24(sp)
    80003472:	6442                	ld	s0,16(sp)
    80003474:	64a2                	ld	s1,8(sp)
    80003476:	6105                	addi	sp,sp,32
    80003478:	8082                	ret

000000008000347a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000347a:	1101                	addi	sp,sp,-32
    8000347c:	ec06                	sd	ra,24(sp)
    8000347e:	e822                	sd	s0,16(sp)
    80003480:	e426                	sd	s1,8(sp)
    80003482:	e04a                	sd	s2,0(sp)
    80003484:	1000                	addi	s0,sp,32
    80003486:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003488:	00d5d59b          	srliw	a1,a1,0xd
    8000348c:	0001d797          	auipc	a5,0x1d
    80003490:	9387a783          	lw	a5,-1736(a5) # 8001fdc4 <sb+0x1c>
    80003494:	9dbd                	addw	a1,a1,a5
    80003496:	00000097          	auipc	ra,0x0
    8000349a:	d9e080e7          	jalr	-610(ra) # 80003234 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000349e:	0074f713          	andi	a4,s1,7
    800034a2:	4785                	li	a5,1
    800034a4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800034a8:	14ce                	slli	s1,s1,0x33
    800034aa:	90d9                	srli	s1,s1,0x36
    800034ac:	00950733          	add	a4,a0,s1
    800034b0:	05874703          	lbu	a4,88(a4)
    800034b4:	00e7f6b3          	and	a3,a5,a4
    800034b8:	c69d                	beqz	a3,800034e6 <bfree+0x6c>
    800034ba:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034bc:	94aa                	add	s1,s1,a0
    800034be:	fff7c793          	not	a5,a5
    800034c2:	8ff9                	and	a5,a5,a4
    800034c4:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800034c8:	00001097          	auipc	ra,0x1
    800034cc:	11e080e7          	jalr	286(ra) # 800045e6 <log_write>
  brelse(bp);
    800034d0:	854a                	mv	a0,s2
    800034d2:	00000097          	auipc	ra,0x0
    800034d6:	e92080e7          	jalr	-366(ra) # 80003364 <brelse>
}
    800034da:	60e2                	ld	ra,24(sp)
    800034dc:	6442                	ld	s0,16(sp)
    800034de:	64a2                	ld	s1,8(sp)
    800034e0:	6902                	ld	s2,0(sp)
    800034e2:	6105                	addi	sp,sp,32
    800034e4:	8082                	ret
    panic("freeing free block");
    800034e6:	00005517          	auipc	a0,0x5
    800034ea:	22a50513          	addi	a0,a0,554 # 80008710 <syscalls+0x100>
    800034ee:	ffffd097          	auipc	ra,0xffffd
    800034f2:	03c080e7          	jalr	60(ra) # 8000052a <panic>

00000000800034f6 <balloc>:
{
    800034f6:	711d                	addi	sp,sp,-96
    800034f8:	ec86                	sd	ra,88(sp)
    800034fa:	e8a2                	sd	s0,80(sp)
    800034fc:	e4a6                	sd	s1,72(sp)
    800034fe:	e0ca                	sd	s2,64(sp)
    80003500:	fc4e                	sd	s3,56(sp)
    80003502:	f852                	sd	s4,48(sp)
    80003504:	f456                	sd	s5,40(sp)
    80003506:	f05a                	sd	s6,32(sp)
    80003508:	ec5e                	sd	s7,24(sp)
    8000350a:	e862                	sd	s8,16(sp)
    8000350c:	e466                	sd	s9,8(sp)
    8000350e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003510:	0001d797          	auipc	a5,0x1d
    80003514:	89c7a783          	lw	a5,-1892(a5) # 8001fdac <sb+0x4>
    80003518:	cbd1                	beqz	a5,800035ac <balloc+0xb6>
    8000351a:	8baa                	mv	s7,a0
    8000351c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000351e:	0001db17          	auipc	s6,0x1d
    80003522:	88ab0b13          	addi	s6,s6,-1910 # 8001fda8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003526:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003528:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000352a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000352c:	6c89                	lui	s9,0x2
    8000352e:	a831                	j	8000354a <balloc+0x54>
    brelse(bp);
    80003530:	854a                	mv	a0,s2
    80003532:	00000097          	auipc	ra,0x0
    80003536:	e32080e7          	jalr	-462(ra) # 80003364 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000353a:	015c87bb          	addw	a5,s9,s5
    8000353e:	00078a9b          	sext.w	s5,a5
    80003542:	004b2703          	lw	a4,4(s6)
    80003546:	06eaf363          	bgeu	s5,a4,800035ac <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000354a:	41fad79b          	sraiw	a5,s5,0x1f
    8000354e:	0137d79b          	srliw	a5,a5,0x13
    80003552:	015787bb          	addw	a5,a5,s5
    80003556:	40d7d79b          	sraiw	a5,a5,0xd
    8000355a:	01cb2583          	lw	a1,28(s6)
    8000355e:	9dbd                	addw	a1,a1,a5
    80003560:	855e                	mv	a0,s7
    80003562:	00000097          	auipc	ra,0x0
    80003566:	cd2080e7          	jalr	-814(ra) # 80003234 <bread>
    8000356a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000356c:	004b2503          	lw	a0,4(s6)
    80003570:	000a849b          	sext.w	s1,s5
    80003574:	8662                	mv	a2,s8
    80003576:	faa4fde3          	bgeu	s1,a0,80003530 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000357a:	41f6579b          	sraiw	a5,a2,0x1f
    8000357e:	01d7d69b          	srliw	a3,a5,0x1d
    80003582:	00c6873b          	addw	a4,a3,a2
    80003586:	00777793          	andi	a5,a4,7
    8000358a:	9f95                	subw	a5,a5,a3
    8000358c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003590:	4037571b          	sraiw	a4,a4,0x3
    80003594:	00e906b3          	add	a3,s2,a4
    80003598:	0586c683          	lbu	a3,88(a3)
    8000359c:	00d7f5b3          	and	a1,a5,a3
    800035a0:	cd91                	beqz	a1,800035bc <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035a2:	2605                	addiw	a2,a2,1
    800035a4:	2485                	addiw	s1,s1,1
    800035a6:	fd4618e3          	bne	a2,s4,80003576 <balloc+0x80>
    800035aa:	b759                	j	80003530 <balloc+0x3a>
  panic("balloc: out of blocks");
    800035ac:	00005517          	auipc	a0,0x5
    800035b0:	17c50513          	addi	a0,a0,380 # 80008728 <syscalls+0x118>
    800035b4:	ffffd097          	auipc	ra,0xffffd
    800035b8:	f76080e7          	jalr	-138(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800035bc:	974a                	add	a4,a4,s2
    800035be:	8fd5                	or	a5,a5,a3
    800035c0:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800035c4:	854a                	mv	a0,s2
    800035c6:	00001097          	auipc	ra,0x1
    800035ca:	020080e7          	jalr	32(ra) # 800045e6 <log_write>
        brelse(bp);
    800035ce:	854a                	mv	a0,s2
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	d94080e7          	jalr	-620(ra) # 80003364 <brelse>
  bp = bread(dev, bno);
    800035d8:	85a6                	mv	a1,s1
    800035da:	855e                	mv	a0,s7
    800035dc:	00000097          	auipc	ra,0x0
    800035e0:	c58080e7          	jalr	-936(ra) # 80003234 <bread>
    800035e4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800035e6:	40000613          	li	a2,1024
    800035ea:	4581                	li	a1,0
    800035ec:	05850513          	addi	a0,a0,88
    800035f0:	ffffd097          	auipc	ra,0xffffd
    800035f4:	6ce080e7          	jalr	1742(ra) # 80000cbe <memset>
  log_write(bp);
    800035f8:	854a                	mv	a0,s2
    800035fa:	00001097          	auipc	ra,0x1
    800035fe:	fec080e7          	jalr	-20(ra) # 800045e6 <log_write>
  brelse(bp);
    80003602:	854a                	mv	a0,s2
    80003604:	00000097          	auipc	ra,0x0
    80003608:	d60080e7          	jalr	-672(ra) # 80003364 <brelse>
}
    8000360c:	8526                	mv	a0,s1
    8000360e:	60e6                	ld	ra,88(sp)
    80003610:	6446                	ld	s0,80(sp)
    80003612:	64a6                	ld	s1,72(sp)
    80003614:	6906                	ld	s2,64(sp)
    80003616:	79e2                	ld	s3,56(sp)
    80003618:	7a42                	ld	s4,48(sp)
    8000361a:	7aa2                	ld	s5,40(sp)
    8000361c:	7b02                	ld	s6,32(sp)
    8000361e:	6be2                	ld	s7,24(sp)
    80003620:	6c42                	ld	s8,16(sp)
    80003622:	6ca2                	ld	s9,8(sp)
    80003624:	6125                	addi	sp,sp,96
    80003626:	8082                	ret

0000000080003628 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003628:	7179                	addi	sp,sp,-48
    8000362a:	f406                	sd	ra,40(sp)
    8000362c:	f022                	sd	s0,32(sp)
    8000362e:	ec26                	sd	s1,24(sp)
    80003630:	e84a                	sd	s2,16(sp)
    80003632:	e44e                	sd	s3,8(sp)
    80003634:	e052                	sd	s4,0(sp)
    80003636:	1800                	addi	s0,sp,48
    80003638:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000363a:	47ad                	li	a5,11
    8000363c:	04b7fe63          	bgeu	a5,a1,80003698 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003640:	ff45849b          	addiw	s1,a1,-12
    80003644:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003648:	0ff00793          	li	a5,255
    8000364c:	0ae7e463          	bltu	a5,a4,800036f4 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003650:	08052583          	lw	a1,128(a0)
    80003654:	c5b5                	beqz	a1,800036c0 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003656:	00092503          	lw	a0,0(s2)
    8000365a:	00000097          	auipc	ra,0x0
    8000365e:	bda080e7          	jalr	-1062(ra) # 80003234 <bread>
    80003662:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003664:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003668:	02049713          	slli	a4,s1,0x20
    8000366c:	01e75593          	srli	a1,a4,0x1e
    80003670:	00b784b3          	add	s1,a5,a1
    80003674:	0004a983          	lw	s3,0(s1)
    80003678:	04098e63          	beqz	s3,800036d4 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000367c:	8552                	mv	a0,s4
    8000367e:	00000097          	auipc	ra,0x0
    80003682:	ce6080e7          	jalr	-794(ra) # 80003364 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003686:	854e                	mv	a0,s3
    80003688:	70a2                	ld	ra,40(sp)
    8000368a:	7402                	ld	s0,32(sp)
    8000368c:	64e2                	ld	s1,24(sp)
    8000368e:	6942                	ld	s2,16(sp)
    80003690:	69a2                	ld	s3,8(sp)
    80003692:	6a02                	ld	s4,0(sp)
    80003694:	6145                	addi	sp,sp,48
    80003696:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003698:	02059793          	slli	a5,a1,0x20
    8000369c:	01e7d593          	srli	a1,a5,0x1e
    800036a0:	00b504b3          	add	s1,a0,a1
    800036a4:	0504a983          	lw	s3,80(s1)
    800036a8:	fc099fe3          	bnez	s3,80003686 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800036ac:	4108                	lw	a0,0(a0)
    800036ae:	00000097          	auipc	ra,0x0
    800036b2:	e48080e7          	jalr	-440(ra) # 800034f6 <balloc>
    800036b6:	0005099b          	sext.w	s3,a0
    800036ba:	0534a823          	sw	s3,80(s1)
    800036be:	b7e1                	j	80003686 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800036c0:	4108                	lw	a0,0(a0)
    800036c2:	00000097          	auipc	ra,0x0
    800036c6:	e34080e7          	jalr	-460(ra) # 800034f6 <balloc>
    800036ca:	0005059b          	sext.w	a1,a0
    800036ce:	08b92023          	sw	a1,128(s2)
    800036d2:	b751                	j	80003656 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800036d4:	00092503          	lw	a0,0(s2)
    800036d8:	00000097          	auipc	ra,0x0
    800036dc:	e1e080e7          	jalr	-482(ra) # 800034f6 <balloc>
    800036e0:	0005099b          	sext.w	s3,a0
    800036e4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800036e8:	8552                	mv	a0,s4
    800036ea:	00001097          	auipc	ra,0x1
    800036ee:	efc080e7          	jalr	-260(ra) # 800045e6 <log_write>
    800036f2:	b769                	j	8000367c <bmap+0x54>
  panic("bmap: out of range");
    800036f4:	00005517          	auipc	a0,0x5
    800036f8:	04c50513          	addi	a0,a0,76 # 80008740 <syscalls+0x130>
    800036fc:	ffffd097          	auipc	ra,0xffffd
    80003700:	e2e080e7          	jalr	-466(ra) # 8000052a <panic>

0000000080003704 <iget>:
{
    80003704:	7179                	addi	sp,sp,-48
    80003706:	f406                	sd	ra,40(sp)
    80003708:	f022                	sd	s0,32(sp)
    8000370a:	ec26                	sd	s1,24(sp)
    8000370c:	e84a                	sd	s2,16(sp)
    8000370e:	e44e                	sd	s3,8(sp)
    80003710:	e052                	sd	s4,0(sp)
    80003712:	1800                	addi	s0,sp,48
    80003714:	89aa                	mv	s3,a0
    80003716:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003718:	0001c517          	auipc	a0,0x1c
    8000371c:	6b050513          	addi	a0,a0,1712 # 8001fdc8 <itable>
    80003720:	ffffd097          	auipc	ra,0xffffd
    80003724:	4a2080e7          	jalr	1186(ra) # 80000bc2 <acquire>
  empty = 0;
    80003728:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000372a:	0001c497          	auipc	s1,0x1c
    8000372e:	6b648493          	addi	s1,s1,1718 # 8001fde0 <itable+0x18>
    80003732:	0001e697          	auipc	a3,0x1e
    80003736:	13e68693          	addi	a3,a3,318 # 80021870 <log>
    8000373a:	a039                	j	80003748 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000373c:	02090b63          	beqz	s2,80003772 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003740:	08848493          	addi	s1,s1,136
    80003744:	02d48a63          	beq	s1,a3,80003778 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003748:	449c                	lw	a5,8(s1)
    8000374a:	fef059e3          	blez	a5,8000373c <iget+0x38>
    8000374e:	4098                	lw	a4,0(s1)
    80003750:	ff3716e3          	bne	a4,s3,8000373c <iget+0x38>
    80003754:	40d8                	lw	a4,4(s1)
    80003756:	ff4713e3          	bne	a4,s4,8000373c <iget+0x38>
      ip->ref++;
    8000375a:	2785                	addiw	a5,a5,1
    8000375c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000375e:	0001c517          	auipc	a0,0x1c
    80003762:	66a50513          	addi	a0,a0,1642 # 8001fdc8 <itable>
    80003766:	ffffd097          	auipc	ra,0xffffd
    8000376a:	510080e7          	jalr	1296(ra) # 80000c76 <release>
      return ip;
    8000376e:	8926                	mv	s2,s1
    80003770:	a03d                	j	8000379e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003772:	f7f9                	bnez	a5,80003740 <iget+0x3c>
    80003774:	8926                	mv	s2,s1
    80003776:	b7e9                	j	80003740 <iget+0x3c>
  if(empty == 0)
    80003778:	02090c63          	beqz	s2,800037b0 <iget+0xac>
  ip->dev = dev;
    8000377c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003780:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003784:	4785                	li	a5,1
    80003786:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000378a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000378e:	0001c517          	auipc	a0,0x1c
    80003792:	63a50513          	addi	a0,a0,1594 # 8001fdc8 <itable>
    80003796:	ffffd097          	auipc	ra,0xffffd
    8000379a:	4e0080e7          	jalr	1248(ra) # 80000c76 <release>
}
    8000379e:	854a                	mv	a0,s2
    800037a0:	70a2                	ld	ra,40(sp)
    800037a2:	7402                	ld	s0,32(sp)
    800037a4:	64e2                	ld	s1,24(sp)
    800037a6:	6942                	ld	s2,16(sp)
    800037a8:	69a2                	ld	s3,8(sp)
    800037aa:	6a02                	ld	s4,0(sp)
    800037ac:	6145                	addi	sp,sp,48
    800037ae:	8082                	ret
    panic("iget: no inodes");
    800037b0:	00005517          	auipc	a0,0x5
    800037b4:	fa850513          	addi	a0,a0,-88 # 80008758 <syscalls+0x148>
    800037b8:	ffffd097          	auipc	ra,0xffffd
    800037bc:	d72080e7          	jalr	-654(ra) # 8000052a <panic>

00000000800037c0 <fsinit>:
fsinit(int dev) {
    800037c0:	7179                	addi	sp,sp,-48
    800037c2:	f406                	sd	ra,40(sp)
    800037c4:	f022                	sd	s0,32(sp)
    800037c6:	ec26                	sd	s1,24(sp)
    800037c8:	e84a                	sd	s2,16(sp)
    800037ca:	e44e                	sd	s3,8(sp)
    800037cc:	1800                	addi	s0,sp,48
    800037ce:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800037d0:	4585                	li	a1,1
    800037d2:	00000097          	auipc	ra,0x0
    800037d6:	a62080e7          	jalr	-1438(ra) # 80003234 <bread>
    800037da:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037dc:	0001c997          	auipc	s3,0x1c
    800037e0:	5cc98993          	addi	s3,s3,1484 # 8001fda8 <sb>
    800037e4:	02000613          	li	a2,32
    800037e8:	05850593          	addi	a1,a0,88
    800037ec:	854e                	mv	a0,s3
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	52c080e7          	jalr	1324(ra) # 80000d1a <memmove>
  brelse(bp);
    800037f6:	8526                	mv	a0,s1
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	b6c080e7          	jalr	-1172(ra) # 80003364 <brelse>
  if(sb.magic != FSMAGIC)
    80003800:	0009a703          	lw	a4,0(s3)
    80003804:	102037b7          	lui	a5,0x10203
    80003808:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000380c:	02f71263          	bne	a4,a5,80003830 <fsinit+0x70>
  initlog(dev, &sb);
    80003810:	0001c597          	auipc	a1,0x1c
    80003814:	59858593          	addi	a1,a1,1432 # 8001fda8 <sb>
    80003818:	854a                	mv	a0,s2
    8000381a:	00001097          	auipc	ra,0x1
    8000381e:	b4e080e7          	jalr	-1202(ra) # 80004368 <initlog>
}
    80003822:	70a2                	ld	ra,40(sp)
    80003824:	7402                	ld	s0,32(sp)
    80003826:	64e2                	ld	s1,24(sp)
    80003828:	6942                	ld	s2,16(sp)
    8000382a:	69a2                	ld	s3,8(sp)
    8000382c:	6145                	addi	sp,sp,48
    8000382e:	8082                	ret
    panic("invalid file system");
    80003830:	00005517          	auipc	a0,0x5
    80003834:	f3850513          	addi	a0,a0,-200 # 80008768 <syscalls+0x158>
    80003838:	ffffd097          	auipc	ra,0xffffd
    8000383c:	cf2080e7          	jalr	-782(ra) # 8000052a <panic>

0000000080003840 <iinit>:
{
    80003840:	7179                	addi	sp,sp,-48
    80003842:	f406                	sd	ra,40(sp)
    80003844:	f022                	sd	s0,32(sp)
    80003846:	ec26                	sd	s1,24(sp)
    80003848:	e84a                	sd	s2,16(sp)
    8000384a:	e44e                	sd	s3,8(sp)
    8000384c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000384e:	00005597          	auipc	a1,0x5
    80003852:	f3258593          	addi	a1,a1,-206 # 80008780 <syscalls+0x170>
    80003856:	0001c517          	auipc	a0,0x1c
    8000385a:	57250513          	addi	a0,a0,1394 # 8001fdc8 <itable>
    8000385e:	ffffd097          	auipc	ra,0xffffd
    80003862:	2d4080e7          	jalr	724(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003866:	0001c497          	auipc	s1,0x1c
    8000386a:	58a48493          	addi	s1,s1,1418 # 8001fdf0 <itable+0x28>
    8000386e:	0001e997          	auipc	s3,0x1e
    80003872:	01298993          	addi	s3,s3,18 # 80021880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003876:	00005917          	auipc	s2,0x5
    8000387a:	f1290913          	addi	s2,s2,-238 # 80008788 <syscalls+0x178>
    8000387e:	85ca                	mv	a1,s2
    80003880:	8526                	mv	a0,s1
    80003882:	00001097          	auipc	ra,0x1
    80003886:	e4a080e7          	jalr	-438(ra) # 800046cc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000388a:	08848493          	addi	s1,s1,136
    8000388e:	ff3498e3          	bne	s1,s3,8000387e <iinit+0x3e>
}
    80003892:	70a2                	ld	ra,40(sp)
    80003894:	7402                	ld	s0,32(sp)
    80003896:	64e2                	ld	s1,24(sp)
    80003898:	6942                	ld	s2,16(sp)
    8000389a:	69a2                	ld	s3,8(sp)
    8000389c:	6145                	addi	sp,sp,48
    8000389e:	8082                	ret

00000000800038a0 <ialloc>:
{
    800038a0:	715d                	addi	sp,sp,-80
    800038a2:	e486                	sd	ra,72(sp)
    800038a4:	e0a2                	sd	s0,64(sp)
    800038a6:	fc26                	sd	s1,56(sp)
    800038a8:	f84a                	sd	s2,48(sp)
    800038aa:	f44e                	sd	s3,40(sp)
    800038ac:	f052                	sd	s4,32(sp)
    800038ae:	ec56                	sd	s5,24(sp)
    800038b0:	e85a                	sd	s6,16(sp)
    800038b2:	e45e                	sd	s7,8(sp)
    800038b4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800038b6:	0001c717          	auipc	a4,0x1c
    800038ba:	4fe72703          	lw	a4,1278(a4) # 8001fdb4 <sb+0xc>
    800038be:	4785                	li	a5,1
    800038c0:	04e7fa63          	bgeu	a5,a4,80003914 <ialloc+0x74>
    800038c4:	8aaa                	mv	s5,a0
    800038c6:	8bae                	mv	s7,a1
    800038c8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800038ca:	0001ca17          	auipc	s4,0x1c
    800038ce:	4dea0a13          	addi	s4,s4,1246 # 8001fda8 <sb>
    800038d2:	00048b1b          	sext.w	s6,s1
    800038d6:	0044d793          	srli	a5,s1,0x4
    800038da:	018a2583          	lw	a1,24(s4)
    800038de:	9dbd                	addw	a1,a1,a5
    800038e0:	8556                	mv	a0,s5
    800038e2:	00000097          	auipc	ra,0x0
    800038e6:	952080e7          	jalr	-1710(ra) # 80003234 <bread>
    800038ea:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800038ec:	05850993          	addi	s3,a0,88
    800038f0:	00f4f793          	andi	a5,s1,15
    800038f4:	079a                	slli	a5,a5,0x6
    800038f6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800038f8:	00099783          	lh	a5,0(s3)
    800038fc:	c785                	beqz	a5,80003924 <ialloc+0x84>
    brelse(bp);
    800038fe:	00000097          	auipc	ra,0x0
    80003902:	a66080e7          	jalr	-1434(ra) # 80003364 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003906:	0485                	addi	s1,s1,1
    80003908:	00ca2703          	lw	a4,12(s4)
    8000390c:	0004879b          	sext.w	a5,s1
    80003910:	fce7e1e3          	bltu	a5,a4,800038d2 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003914:	00005517          	auipc	a0,0x5
    80003918:	e7c50513          	addi	a0,a0,-388 # 80008790 <syscalls+0x180>
    8000391c:	ffffd097          	auipc	ra,0xffffd
    80003920:	c0e080e7          	jalr	-1010(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003924:	04000613          	li	a2,64
    80003928:	4581                	li	a1,0
    8000392a:	854e                	mv	a0,s3
    8000392c:	ffffd097          	auipc	ra,0xffffd
    80003930:	392080e7          	jalr	914(ra) # 80000cbe <memset>
      dip->type = type;
    80003934:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003938:	854a                	mv	a0,s2
    8000393a:	00001097          	auipc	ra,0x1
    8000393e:	cac080e7          	jalr	-852(ra) # 800045e6 <log_write>
      brelse(bp);
    80003942:	854a                	mv	a0,s2
    80003944:	00000097          	auipc	ra,0x0
    80003948:	a20080e7          	jalr	-1504(ra) # 80003364 <brelse>
      return iget(dev, inum);
    8000394c:	85da                	mv	a1,s6
    8000394e:	8556                	mv	a0,s5
    80003950:	00000097          	auipc	ra,0x0
    80003954:	db4080e7          	jalr	-588(ra) # 80003704 <iget>
}
    80003958:	60a6                	ld	ra,72(sp)
    8000395a:	6406                	ld	s0,64(sp)
    8000395c:	74e2                	ld	s1,56(sp)
    8000395e:	7942                	ld	s2,48(sp)
    80003960:	79a2                	ld	s3,40(sp)
    80003962:	7a02                	ld	s4,32(sp)
    80003964:	6ae2                	ld	s5,24(sp)
    80003966:	6b42                	ld	s6,16(sp)
    80003968:	6ba2                	ld	s7,8(sp)
    8000396a:	6161                	addi	sp,sp,80
    8000396c:	8082                	ret

000000008000396e <iupdate>:
{
    8000396e:	1101                	addi	sp,sp,-32
    80003970:	ec06                	sd	ra,24(sp)
    80003972:	e822                	sd	s0,16(sp)
    80003974:	e426                	sd	s1,8(sp)
    80003976:	e04a                	sd	s2,0(sp)
    80003978:	1000                	addi	s0,sp,32
    8000397a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000397c:	415c                	lw	a5,4(a0)
    8000397e:	0047d79b          	srliw	a5,a5,0x4
    80003982:	0001c597          	auipc	a1,0x1c
    80003986:	43e5a583          	lw	a1,1086(a1) # 8001fdc0 <sb+0x18>
    8000398a:	9dbd                	addw	a1,a1,a5
    8000398c:	4108                	lw	a0,0(a0)
    8000398e:	00000097          	auipc	ra,0x0
    80003992:	8a6080e7          	jalr	-1882(ra) # 80003234 <bread>
    80003996:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003998:	05850793          	addi	a5,a0,88
    8000399c:	40c8                	lw	a0,4(s1)
    8000399e:	893d                	andi	a0,a0,15
    800039a0:	051a                	slli	a0,a0,0x6
    800039a2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800039a4:	04449703          	lh	a4,68(s1)
    800039a8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800039ac:	04649703          	lh	a4,70(s1)
    800039b0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800039b4:	04849703          	lh	a4,72(s1)
    800039b8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800039bc:	04a49703          	lh	a4,74(s1)
    800039c0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800039c4:	44f8                	lw	a4,76(s1)
    800039c6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800039c8:	03400613          	li	a2,52
    800039cc:	05048593          	addi	a1,s1,80
    800039d0:	0531                	addi	a0,a0,12
    800039d2:	ffffd097          	auipc	ra,0xffffd
    800039d6:	348080e7          	jalr	840(ra) # 80000d1a <memmove>
  log_write(bp);
    800039da:	854a                	mv	a0,s2
    800039dc:	00001097          	auipc	ra,0x1
    800039e0:	c0a080e7          	jalr	-1014(ra) # 800045e6 <log_write>
  brelse(bp);
    800039e4:	854a                	mv	a0,s2
    800039e6:	00000097          	auipc	ra,0x0
    800039ea:	97e080e7          	jalr	-1666(ra) # 80003364 <brelse>
}
    800039ee:	60e2                	ld	ra,24(sp)
    800039f0:	6442                	ld	s0,16(sp)
    800039f2:	64a2                	ld	s1,8(sp)
    800039f4:	6902                	ld	s2,0(sp)
    800039f6:	6105                	addi	sp,sp,32
    800039f8:	8082                	ret

00000000800039fa <idup>:
{
    800039fa:	1101                	addi	sp,sp,-32
    800039fc:	ec06                	sd	ra,24(sp)
    800039fe:	e822                	sd	s0,16(sp)
    80003a00:	e426                	sd	s1,8(sp)
    80003a02:	1000                	addi	s0,sp,32
    80003a04:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a06:	0001c517          	auipc	a0,0x1c
    80003a0a:	3c250513          	addi	a0,a0,962 # 8001fdc8 <itable>
    80003a0e:	ffffd097          	auipc	ra,0xffffd
    80003a12:	1b4080e7          	jalr	436(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003a16:	449c                	lw	a5,8(s1)
    80003a18:	2785                	addiw	a5,a5,1
    80003a1a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a1c:	0001c517          	auipc	a0,0x1c
    80003a20:	3ac50513          	addi	a0,a0,940 # 8001fdc8 <itable>
    80003a24:	ffffd097          	auipc	ra,0xffffd
    80003a28:	252080e7          	jalr	594(ra) # 80000c76 <release>
}
    80003a2c:	8526                	mv	a0,s1
    80003a2e:	60e2                	ld	ra,24(sp)
    80003a30:	6442                	ld	s0,16(sp)
    80003a32:	64a2                	ld	s1,8(sp)
    80003a34:	6105                	addi	sp,sp,32
    80003a36:	8082                	ret

0000000080003a38 <ilock>:
{
    80003a38:	1101                	addi	sp,sp,-32
    80003a3a:	ec06                	sd	ra,24(sp)
    80003a3c:	e822                	sd	s0,16(sp)
    80003a3e:	e426                	sd	s1,8(sp)
    80003a40:	e04a                	sd	s2,0(sp)
    80003a42:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a44:	c115                	beqz	a0,80003a68 <ilock+0x30>
    80003a46:	84aa                	mv	s1,a0
    80003a48:	451c                	lw	a5,8(a0)
    80003a4a:	00f05f63          	blez	a5,80003a68 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a4e:	0541                	addi	a0,a0,16
    80003a50:	00001097          	auipc	ra,0x1
    80003a54:	cb6080e7          	jalr	-842(ra) # 80004706 <acquiresleep>
  if(ip->valid == 0){
    80003a58:	40bc                	lw	a5,64(s1)
    80003a5a:	cf99                	beqz	a5,80003a78 <ilock+0x40>
}
    80003a5c:	60e2                	ld	ra,24(sp)
    80003a5e:	6442                	ld	s0,16(sp)
    80003a60:	64a2                	ld	s1,8(sp)
    80003a62:	6902                	ld	s2,0(sp)
    80003a64:	6105                	addi	sp,sp,32
    80003a66:	8082                	ret
    panic("ilock");
    80003a68:	00005517          	auipc	a0,0x5
    80003a6c:	d4050513          	addi	a0,a0,-704 # 800087a8 <syscalls+0x198>
    80003a70:	ffffd097          	auipc	ra,0xffffd
    80003a74:	aba080e7          	jalr	-1350(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a78:	40dc                	lw	a5,4(s1)
    80003a7a:	0047d79b          	srliw	a5,a5,0x4
    80003a7e:	0001c597          	auipc	a1,0x1c
    80003a82:	3425a583          	lw	a1,834(a1) # 8001fdc0 <sb+0x18>
    80003a86:	9dbd                	addw	a1,a1,a5
    80003a88:	4088                	lw	a0,0(s1)
    80003a8a:	fffff097          	auipc	ra,0xfffff
    80003a8e:	7aa080e7          	jalr	1962(ra) # 80003234 <bread>
    80003a92:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a94:	05850593          	addi	a1,a0,88
    80003a98:	40dc                	lw	a5,4(s1)
    80003a9a:	8bbd                	andi	a5,a5,15
    80003a9c:	079a                	slli	a5,a5,0x6
    80003a9e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003aa0:	00059783          	lh	a5,0(a1)
    80003aa4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003aa8:	00259783          	lh	a5,2(a1)
    80003aac:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003ab0:	00459783          	lh	a5,4(a1)
    80003ab4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ab8:	00659783          	lh	a5,6(a1)
    80003abc:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ac0:	459c                	lw	a5,8(a1)
    80003ac2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ac4:	03400613          	li	a2,52
    80003ac8:	05b1                	addi	a1,a1,12
    80003aca:	05048513          	addi	a0,s1,80
    80003ace:	ffffd097          	auipc	ra,0xffffd
    80003ad2:	24c080e7          	jalr	588(ra) # 80000d1a <memmove>
    brelse(bp);
    80003ad6:	854a                	mv	a0,s2
    80003ad8:	00000097          	auipc	ra,0x0
    80003adc:	88c080e7          	jalr	-1908(ra) # 80003364 <brelse>
    ip->valid = 1;
    80003ae0:	4785                	li	a5,1
    80003ae2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ae4:	04449783          	lh	a5,68(s1)
    80003ae8:	fbb5                	bnez	a5,80003a5c <ilock+0x24>
      panic("ilock: no type");
    80003aea:	00005517          	auipc	a0,0x5
    80003aee:	cc650513          	addi	a0,a0,-826 # 800087b0 <syscalls+0x1a0>
    80003af2:	ffffd097          	auipc	ra,0xffffd
    80003af6:	a38080e7          	jalr	-1480(ra) # 8000052a <panic>

0000000080003afa <iunlock>:
{
    80003afa:	1101                	addi	sp,sp,-32
    80003afc:	ec06                	sd	ra,24(sp)
    80003afe:	e822                	sd	s0,16(sp)
    80003b00:	e426                	sd	s1,8(sp)
    80003b02:	e04a                	sd	s2,0(sp)
    80003b04:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b06:	c905                	beqz	a0,80003b36 <iunlock+0x3c>
    80003b08:	84aa                	mv	s1,a0
    80003b0a:	01050913          	addi	s2,a0,16
    80003b0e:	854a                	mv	a0,s2
    80003b10:	00001097          	auipc	ra,0x1
    80003b14:	c90080e7          	jalr	-880(ra) # 800047a0 <holdingsleep>
    80003b18:	cd19                	beqz	a0,80003b36 <iunlock+0x3c>
    80003b1a:	449c                	lw	a5,8(s1)
    80003b1c:	00f05d63          	blez	a5,80003b36 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b20:	854a                	mv	a0,s2
    80003b22:	00001097          	auipc	ra,0x1
    80003b26:	c3a080e7          	jalr	-966(ra) # 8000475c <releasesleep>
}
    80003b2a:	60e2                	ld	ra,24(sp)
    80003b2c:	6442                	ld	s0,16(sp)
    80003b2e:	64a2                	ld	s1,8(sp)
    80003b30:	6902                	ld	s2,0(sp)
    80003b32:	6105                	addi	sp,sp,32
    80003b34:	8082                	ret
    panic("iunlock");
    80003b36:	00005517          	auipc	a0,0x5
    80003b3a:	c8a50513          	addi	a0,a0,-886 # 800087c0 <syscalls+0x1b0>
    80003b3e:	ffffd097          	auipc	ra,0xffffd
    80003b42:	9ec080e7          	jalr	-1556(ra) # 8000052a <panic>

0000000080003b46 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b46:	7179                	addi	sp,sp,-48
    80003b48:	f406                	sd	ra,40(sp)
    80003b4a:	f022                	sd	s0,32(sp)
    80003b4c:	ec26                	sd	s1,24(sp)
    80003b4e:	e84a                	sd	s2,16(sp)
    80003b50:	e44e                	sd	s3,8(sp)
    80003b52:	e052                	sd	s4,0(sp)
    80003b54:	1800                	addi	s0,sp,48
    80003b56:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b58:	05050493          	addi	s1,a0,80
    80003b5c:	08050913          	addi	s2,a0,128
    80003b60:	a021                	j	80003b68 <itrunc+0x22>
    80003b62:	0491                	addi	s1,s1,4
    80003b64:	01248d63          	beq	s1,s2,80003b7e <itrunc+0x38>
    if(ip->addrs[i]){
    80003b68:	408c                	lw	a1,0(s1)
    80003b6a:	dde5                	beqz	a1,80003b62 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b6c:	0009a503          	lw	a0,0(s3)
    80003b70:	00000097          	auipc	ra,0x0
    80003b74:	90a080e7          	jalr	-1782(ra) # 8000347a <bfree>
      ip->addrs[i] = 0;
    80003b78:	0004a023          	sw	zero,0(s1)
    80003b7c:	b7dd                	j	80003b62 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b7e:	0809a583          	lw	a1,128(s3)
    80003b82:	e185                	bnez	a1,80003ba2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b84:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b88:	854e                	mv	a0,s3
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	de4080e7          	jalr	-540(ra) # 8000396e <iupdate>
}
    80003b92:	70a2                	ld	ra,40(sp)
    80003b94:	7402                	ld	s0,32(sp)
    80003b96:	64e2                	ld	s1,24(sp)
    80003b98:	6942                	ld	s2,16(sp)
    80003b9a:	69a2                	ld	s3,8(sp)
    80003b9c:	6a02                	ld	s4,0(sp)
    80003b9e:	6145                	addi	sp,sp,48
    80003ba0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ba2:	0009a503          	lw	a0,0(s3)
    80003ba6:	fffff097          	auipc	ra,0xfffff
    80003baa:	68e080e7          	jalr	1678(ra) # 80003234 <bread>
    80003bae:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003bb0:	05850493          	addi	s1,a0,88
    80003bb4:	45850913          	addi	s2,a0,1112
    80003bb8:	a021                	j	80003bc0 <itrunc+0x7a>
    80003bba:	0491                	addi	s1,s1,4
    80003bbc:	01248b63          	beq	s1,s2,80003bd2 <itrunc+0x8c>
      if(a[j])
    80003bc0:	408c                	lw	a1,0(s1)
    80003bc2:	dde5                	beqz	a1,80003bba <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003bc4:	0009a503          	lw	a0,0(s3)
    80003bc8:	00000097          	auipc	ra,0x0
    80003bcc:	8b2080e7          	jalr	-1870(ra) # 8000347a <bfree>
    80003bd0:	b7ed                	j	80003bba <itrunc+0x74>
    brelse(bp);
    80003bd2:	8552                	mv	a0,s4
    80003bd4:	fffff097          	auipc	ra,0xfffff
    80003bd8:	790080e7          	jalr	1936(ra) # 80003364 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003bdc:	0809a583          	lw	a1,128(s3)
    80003be0:	0009a503          	lw	a0,0(s3)
    80003be4:	00000097          	auipc	ra,0x0
    80003be8:	896080e7          	jalr	-1898(ra) # 8000347a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003bec:	0809a023          	sw	zero,128(s3)
    80003bf0:	bf51                	j	80003b84 <itrunc+0x3e>

0000000080003bf2 <iput>:
{
    80003bf2:	1101                	addi	sp,sp,-32
    80003bf4:	ec06                	sd	ra,24(sp)
    80003bf6:	e822                	sd	s0,16(sp)
    80003bf8:	e426                	sd	s1,8(sp)
    80003bfa:	e04a                	sd	s2,0(sp)
    80003bfc:	1000                	addi	s0,sp,32
    80003bfe:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c00:	0001c517          	auipc	a0,0x1c
    80003c04:	1c850513          	addi	a0,a0,456 # 8001fdc8 <itable>
    80003c08:	ffffd097          	auipc	ra,0xffffd
    80003c0c:	fba080e7          	jalr	-70(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c10:	4498                	lw	a4,8(s1)
    80003c12:	4785                	li	a5,1
    80003c14:	02f70363          	beq	a4,a5,80003c3a <iput+0x48>
  ip->ref--;
    80003c18:	449c                	lw	a5,8(s1)
    80003c1a:	37fd                	addiw	a5,a5,-1
    80003c1c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c1e:	0001c517          	auipc	a0,0x1c
    80003c22:	1aa50513          	addi	a0,a0,426 # 8001fdc8 <itable>
    80003c26:	ffffd097          	auipc	ra,0xffffd
    80003c2a:	050080e7          	jalr	80(ra) # 80000c76 <release>
}
    80003c2e:	60e2                	ld	ra,24(sp)
    80003c30:	6442                	ld	s0,16(sp)
    80003c32:	64a2                	ld	s1,8(sp)
    80003c34:	6902                	ld	s2,0(sp)
    80003c36:	6105                	addi	sp,sp,32
    80003c38:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c3a:	40bc                	lw	a5,64(s1)
    80003c3c:	dff1                	beqz	a5,80003c18 <iput+0x26>
    80003c3e:	04a49783          	lh	a5,74(s1)
    80003c42:	fbf9                	bnez	a5,80003c18 <iput+0x26>
    acquiresleep(&ip->lock);
    80003c44:	01048913          	addi	s2,s1,16
    80003c48:	854a                	mv	a0,s2
    80003c4a:	00001097          	auipc	ra,0x1
    80003c4e:	abc080e7          	jalr	-1348(ra) # 80004706 <acquiresleep>
    release(&itable.lock);
    80003c52:	0001c517          	auipc	a0,0x1c
    80003c56:	17650513          	addi	a0,a0,374 # 8001fdc8 <itable>
    80003c5a:	ffffd097          	auipc	ra,0xffffd
    80003c5e:	01c080e7          	jalr	28(ra) # 80000c76 <release>
    itrunc(ip);
    80003c62:	8526                	mv	a0,s1
    80003c64:	00000097          	auipc	ra,0x0
    80003c68:	ee2080e7          	jalr	-286(ra) # 80003b46 <itrunc>
    ip->type = 0;
    80003c6c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c70:	8526                	mv	a0,s1
    80003c72:	00000097          	auipc	ra,0x0
    80003c76:	cfc080e7          	jalr	-772(ra) # 8000396e <iupdate>
    ip->valid = 0;
    80003c7a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c7e:	854a                	mv	a0,s2
    80003c80:	00001097          	auipc	ra,0x1
    80003c84:	adc080e7          	jalr	-1316(ra) # 8000475c <releasesleep>
    acquire(&itable.lock);
    80003c88:	0001c517          	auipc	a0,0x1c
    80003c8c:	14050513          	addi	a0,a0,320 # 8001fdc8 <itable>
    80003c90:	ffffd097          	auipc	ra,0xffffd
    80003c94:	f32080e7          	jalr	-206(ra) # 80000bc2 <acquire>
    80003c98:	b741                	j	80003c18 <iput+0x26>

0000000080003c9a <iunlockput>:
{
    80003c9a:	1101                	addi	sp,sp,-32
    80003c9c:	ec06                	sd	ra,24(sp)
    80003c9e:	e822                	sd	s0,16(sp)
    80003ca0:	e426                	sd	s1,8(sp)
    80003ca2:	1000                	addi	s0,sp,32
    80003ca4:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ca6:	00000097          	auipc	ra,0x0
    80003caa:	e54080e7          	jalr	-428(ra) # 80003afa <iunlock>
  iput(ip);
    80003cae:	8526                	mv	a0,s1
    80003cb0:	00000097          	auipc	ra,0x0
    80003cb4:	f42080e7          	jalr	-190(ra) # 80003bf2 <iput>
}
    80003cb8:	60e2                	ld	ra,24(sp)
    80003cba:	6442                	ld	s0,16(sp)
    80003cbc:	64a2                	ld	s1,8(sp)
    80003cbe:	6105                	addi	sp,sp,32
    80003cc0:	8082                	ret

0000000080003cc2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003cc2:	1141                	addi	sp,sp,-16
    80003cc4:	e422                	sd	s0,8(sp)
    80003cc6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003cc8:	411c                	lw	a5,0(a0)
    80003cca:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ccc:	415c                	lw	a5,4(a0)
    80003cce:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003cd0:	04451783          	lh	a5,68(a0)
    80003cd4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003cd8:	04a51783          	lh	a5,74(a0)
    80003cdc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ce0:	04c56783          	lwu	a5,76(a0)
    80003ce4:	e99c                	sd	a5,16(a1)
}
    80003ce6:	6422                	ld	s0,8(sp)
    80003ce8:	0141                	addi	sp,sp,16
    80003cea:	8082                	ret

0000000080003cec <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cec:	457c                	lw	a5,76(a0)
    80003cee:	0ed7e963          	bltu	a5,a3,80003de0 <readi+0xf4>
{
    80003cf2:	7159                	addi	sp,sp,-112
    80003cf4:	f486                	sd	ra,104(sp)
    80003cf6:	f0a2                	sd	s0,96(sp)
    80003cf8:	eca6                	sd	s1,88(sp)
    80003cfa:	e8ca                	sd	s2,80(sp)
    80003cfc:	e4ce                	sd	s3,72(sp)
    80003cfe:	e0d2                	sd	s4,64(sp)
    80003d00:	fc56                	sd	s5,56(sp)
    80003d02:	f85a                	sd	s6,48(sp)
    80003d04:	f45e                	sd	s7,40(sp)
    80003d06:	f062                	sd	s8,32(sp)
    80003d08:	ec66                	sd	s9,24(sp)
    80003d0a:	e86a                	sd	s10,16(sp)
    80003d0c:	e46e                	sd	s11,8(sp)
    80003d0e:	1880                	addi	s0,sp,112
    80003d10:	8baa                	mv	s7,a0
    80003d12:	8c2e                	mv	s8,a1
    80003d14:	8ab2                	mv	s5,a2
    80003d16:	84b6                	mv	s1,a3
    80003d18:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d1a:	9f35                	addw	a4,a4,a3
    return 0;
    80003d1c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d1e:	0ad76063          	bltu	a4,a3,80003dbe <readi+0xd2>
  if(off + n > ip->size)
    80003d22:	00e7f463          	bgeu	a5,a4,80003d2a <readi+0x3e>
    n = ip->size - off;
    80003d26:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d2a:	0a0b0963          	beqz	s6,80003ddc <readi+0xf0>
    80003d2e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d30:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d34:	5cfd                	li	s9,-1
    80003d36:	a82d                	j	80003d70 <readi+0x84>
    80003d38:	020a1d93          	slli	s11,s4,0x20
    80003d3c:	020ddd93          	srli	s11,s11,0x20
    80003d40:	05890793          	addi	a5,s2,88
    80003d44:	86ee                	mv	a3,s11
    80003d46:	963e                	add	a2,a2,a5
    80003d48:	85d6                	mv	a1,s5
    80003d4a:	8562                	mv	a0,s8
    80003d4c:	ffffe097          	auipc	ra,0xffffe
    80003d50:	6ac080e7          	jalr	1708(ra) # 800023f8 <either_copyout>
    80003d54:	05950d63          	beq	a0,s9,80003dae <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d58:	854a                	mv	a0,s2
    80003d5a:	fffff097          	auipc	ra,0xfffff
    80003d5e:	60a080e7          	jalr	1546(ra) # 80003364 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d62:	013a09bb          	addw	s3,s4,s3
    80003d66:	009a04bb          	addw	s1,s4,s1
    80003d6a:	9aee                	add	s5,s5,s11
    80003d6c:	0569f763          	bgeu	s3,s6,80003dba <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d70:	000ba903          	lw	s2,0(s7)
    80003d74:	00a4d59b          	srliw	a1,s1,0xa
    80003d78:	855e                	mv	a0,s7
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	8ae080e7          	jalr	-1874(ra) # 80003628 <bmap>
    80003d82:	0005059b          	sext.w	a1,a0
    80003d86:	854a                	mv	a0,s2
    80003d88:	fffff097          	auipc	ra,0xfffff
    80003d8c:	4ac080e7          	jalr	1196(ra) # 80003234 <bread>
    80003d90:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d92:	3ff4f613          	andi	a2,s1,1023
    80003d96:	40cd07bb          	subw	a5,s10,a2
    80003d9a:	413b073b          	subw	a4,s6,s3
    80003d9e:	8a3e                	mv	s4,a5
    80003da0:	2781                	sext.w	a5,a5
    80003da2:	0007069b          	sext.w	a3,a4
    80003da6:	f8f6f9e3          	bgeu	a3,a5,80003d38 <readi+0x4c>
    80003daa:	8a3a                	mv	s4,a4
    80003dac:	b771                	j	80003d38 <readi+0x4c>
      brelse(bp);
    80003dae:	854a                	mv	a0,s2
    80003db0:	fffff097          	auipc	ra,0xfffff
    80003db4:	5b4080e7          	jalr	1460(ra) # 80003364 <brelse>
      tot = -1;
    80003db8:	59fd                	li	s3,-1
  }
  return tot;
    80003dba:	0009851b          	sext.w	a0,s3
}
    80003dbe:	70a6                	ld	ra,104(sp)
    80003dc0:	7406                	ld	s0,96(sp)
    80003dc2:	64e6                	ld	s1,88(sp)
    80003dc4:	6946                	ld	s2,80(sp)
    80003dc6:	69a6                	ld	s3,72(sp)
    80003dc8:	6a06                	ld	s4,64(sp)
    80003dca:	7ae2                	ld	s5,56(sp)
    80003dcc:	7b42                	ld	s6,48(sp)
    80003dce:	7ba2                	ld	s7,40(sp)
    80003dd0:	7c02                	ld	s8,32(sp)
    80003dd2:	6ce2                	ld	s9,24(sp)
    80003dd4:	6d42                	ld	s10,16(sp)
    80003dd6:	6da2                	ld	s11,8(sp)
    80003dd8:	6165                	addi	sp,sp,112
    80003dda:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ddc:	89da                	mv	s3,s6
    80003dde:	bff1                	j	80003dba <readi+0xce>
    return 0;
    80003de0:	4501                	li	a0,0
}
    80003de2:	8082                	ret

0000000080003de4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003de4:	457c                	lw	a5,76(a0)
    80003de6:	10d7e863          	bltu	a5,a3,80003ef6 <writei+0x112>
{
    80003dea:	7159                	addi	sp,sp,-112
    80003dec:	f486                	sd	ra,104(sp)
    80003dee:	f0a2                	sd	s0,96(sp)
    80003df0:	eca6                	sd	s1,88(sp)
    80003df2:	e8ca                	sd	s2,80(sp)
    80003df4:	e4ce                	sd	s3,72(sp)
    80003df6:	e0d2                	sd	s4,64(sp)
    80003df8:	fc56                	sd	s5,56(sp)
    80003dfa:	f85a                	sd	s6,48(sp)
    80003dfc:	f45e                	sd	s7,40(sp)
    80003dfe:	f062                	sd	s8,32(sp)
    80003e00:	ec66                	sd	s9,24(sp)
    80003e02:	e86a                	sd	s10,16(sp)
    80003e04:	e46e                	sd	s11,8(sp)
    80003e06:	1880                	addi	s0,sp,112
    80003e08:	8b2a                	mv	s6,a0
    80003e0a:	8c2e                	mv	s8,a1
    80003e0c:	8ab2                	mv	s5,a2
    80003e0e:	8936                	mv	s2,a3
    80003e10:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003e12:	00e687bb          	addw	a5,a3,a4
    80003e16:	0ed7e263          	bltu	a5,a3,80003efa <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e1a:	00043737          	lui	a4,0x43
    80003e1e:	0ef76063          	bltu	a4,a5,80003efe <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e22:	0c0b8863          	beqz	s7,80003ef2 <writei+0x10e>
    80003e26:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e28:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e2c:	5cfd                	li	s9,-1
    80003e2e:	a091                	j	80003e72 <writei+0x8e>
    80003e30:	02099d93          	slli	s11,s3,0x20
    80003e34:	020ddd93          	srli	s11,s11,0x20
    80003e38:	05848793          	addi	a5,s1,88
    80003e3c:	86ee                	mv	a3,s11
    80003e3e:	8656                	mv	a2,s5
    80003e40:	85e2                	mv	a1,s8
    80003e42:	953e                	add	a0,a0,a5
    80003e44:	ffffe097          	auipc	ra,0xffffe
    80003e48:	60a080e7          	jalr	1546(ra) # 8000244e <either_copyin>
    80003e4c:	07950263          	beq	a0,s9,80003eb0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e50:	8526                	mv	a0,s1
    80003e52:	00000097          	auipc	ra,0x0
    80003e56:	794080e7          	jalr	1940(ra) # 800045e6 <log_write>
    brelse(bp);
    80003e5a:	8526                	mv	a0,s1
    80003e5c:	fffff097          	auipc	ra,0xfffff
    80003e60:	508080e7          	jalr	1288(ra) # 80003364 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e64:	01498a3b          	addw	s4,s3,s4
    80003e68:	0129893b          	addw	s2,s3,s2
    80003e6c:	9aee                	add	s5,s5,s11
    80003e6e:	057a7663          	bgeu	s4,s7,80003eba <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e72:	000b2483          	lw	s1,0(s6)
    80003e76:	00a9559b          	srliw	a1,s2,0xa
    80003e7a:	855a                	mv	a0,s6
    80003e7c:	fffff097          	auipc	ra,0xfffff
    80003e80:	7ac080e7          	jalr	1964(ra) # 80003628 <bmap>
    80003e84:	0005059b          	sext.w	a1,a0
    80003e88:	8526                	mv	a0,s1
    80003e8a:	fffff097          	auipc	ra,0xfffff
    80003e8e:	3aa080e7          	jalr	938(ra) # 80003234 <bread>
    80003e92:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e94:	3ff97513          	andi	a0,s2,1023
    80003e98:	40ad07bb          	subw	a5,s10,a0
    80003e9c:	414b873b          	subw	a4,s7,s4
    80003ea0:	89be                	mv	s3,a5
    80003ea2:	2781                	sext.w	a5,a5
    80003ea4:	0007069b          	sext.w	a3,a4
    80003ea8:	f8f6f4e3          	bgeu	a3,a5,80003e30 <writei+0x4c>
    80003eac:	89ba                	mv	s3,a4
    80003eae:	b749                	j	80003e30 <writei+0x4c>
      brelse(bp);
    80003eb0:	8526                	mv	a0,s1
    80003eb2:	fffff097          	auipc	ra,0xfffff
    80003eb6:	4b2080e7          	jalr	1202(ra) # 80003364 <brelse>
  }

  if(off > ip->size)
    80003eba:	04cb2783          	lw	a5,76(s6)
    80003ebe:	0127f463          	bgeu	a5,s2,80003ec6 <writei+0xe2>
    ip->size = off;
    80003ec2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ec6:	855a                	mv	a0,s6
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	aa6080e7          	jalr	-1370(ra) # 8000396e <iupdate>

  return tot;
    80003ed0:	000a051b          	sext.w	a0,s4
}
    80003ed4:	70a6                	ld	ra,104(sp)
    80003ed6:	7406                	ld	s0,96(sp)
    80003ed8:	64e6                	ld	s1,88(sp)
    80003eda:	6946                	ld	s2,80(sp)
    80003edc:	69a6                	ld	s3,72(sp)
    80003ede:	6a06                	ld	s4,64(sp)
    80003ee0:	7ae2                	ld	s5,56(sp)
    80003ee2:	7b42                	ld	s6,48(sp)
    80003ee4:	7ba2                	ld	s7,40(sp)
    80003ee6:	7c02                	ld	s8,32(sp)
    80003ee8:	6ce2                	ld	s9,24(sp)
    80003eea:	6d42                	ld	s10,16(sp)
    80003eec:	6da2                	ld	s11,8(sp)
    80003eee:	6165                	addi	sp,sp,112
    80003ef0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ef2:	8a5e                	mv	s4,s7
    80003ef4:	bfc9                	j	80003ec6 <writei+0xe2>
    return -1;
    80003ef6:	557d                	li	a0,-1
}
    80003ef8:	8082                	ret
    return -1;
    80003efa:	557d                	li	a0,-1
    80003efc:	bfe1                	j	80003ed4 <writei+0xf0>
    return -1;
    80003efe:	557d                	li	a0,-1
    80003f00:	bfd1                	j	80003ed4 <writei+0xf0>

0000000080003f02 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f02:	1141                	addi	sp,sp,-16
    80003f04:	e406                	sd	ra,8(sp)
    80003f06:	e022                	sd	s0,0(sp)
    80003f08:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f0a:	4639                	li	a2,14
    80003f0c:	ffffd097          	auipc	ra,0xffffd
    80003f10:	e8a080e7          	jalr	-374(ra) # 80000d96 <strncmp>
}
    80003f14:	60a2                	ld	ra,8(sp)
    80003f16:	6402                	ld	s0,0(sp)
    80003f18:	0141                	addi	sp,sp,16
    80003f1a:	8082                	ret

0000000080003f1c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f1c:	7139                	addi	sp,sp,-64
    80003f1e:	fc06                	sd	ra,56(sp)
    80003f20:	f822                	sd	s0,48(sp)
    80003f22:	f426                	sd	s1,40(sp)
    80003f24:	f04a                	sd	s2,32(sp)
    80003f26:	ec4e                	sd	s3,24(sp)
    80003f28:	e852                	sd	s4,16(sp)
    80003f2a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f2c:	04451703          	lh	a4,68(a0)
    80003f30:	4785                	li	a5,1
    80003f32:	00f71a63          	bne	a4,a5,80003f46 <dirlookup+0x2a>
    80003f36:	892a                	mv	s2,a0
    80003f38:	89ae                	mv	s3,a1
    80003f3a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f3c:	457c                	lw	a5,76(a0)
    80003f3e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f40:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f42:	e79d                	bnez	a5,80003f70 <dirlookup+0x54>
    80003f44:	a8a5                	j	80003fbc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f46:	00005517          	auipc	a0,0x5
    80003f4a:	88250513          	addi	a0,a0,-1918 # 800087c8 <syscalls+0x1b8>
    80003f4e:	ffffc097          	auipc	ra,0xffffc
    80003f52:	5dc080e7          	jalr	1500(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003f56:	00005517          	auipc	a0,0x5
    80003f5a:	88a50513          	addi	a0,a0,-1910 # 800087e0 <syscalls+0x1d0>
    80003f5e:	ffffc097          	auipc	ra,0xffffc
    80003f62:	5cc080e7          	jalr	1484(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f66:	24c1                	addiw	s1,s1,16
    80003f68:	04c92783          	lw	a5,76(s2)
    80003f6c:	04f4f763          	bgeu	s1,a5,80003fba <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f70:	4741                	li	a4,16
    80003f72:	86a6                	mv	a3,s1
    80003f74:	fc040613          	addi	a2,s0,-64
    80003f78:	4581                	li	a1,0
    80003f7a:	854a                	mv	a0,s2
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	d70080e7          	jalr	-656(ra) # 80003cec <readi>
    80003f84:	47c1                	li	a5,16
    80003f86:	fcf518e3          	bne	a0,a5,80003f56 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f8a:	fc045783          	lhu	a5,-64(s0)
    80003f8e:	dfe1                	beqz	a5,80003f66 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f90:	fc240593          	addi	a1,s0,-62
    80003f94:	854e                	mv	a0,s3
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	f6c080e7          	jalr	-148(ra) # 80003f02 <namecmp>
    80003f9e:	f561                	bnez	a0,80003f66 <dirlookup+0x4a>
      if(poff)
    80003fa0:	000a0463          	beqz	s4,80003fa8 <dirlookup+0x8c>
        *poff = off;
    80003fa4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003fa8:	fc045583          	lhu	a1,-64(s0)
    80003fac:	00092503          	lw	a0,0(s2)
    80003fb0:	fffff097          	auipc	ra,0xfffff
    80003fb4:	754080e7          	jalr	1876(ra) # 80003704 <iget>
    80003fb8:	a011                	j	80003fbc <dirlookup+0xa0>
  return 0;
    80003fba:	4501                	li	a0,0
}
    80003fbc:	70e2                	ld	ra,56(sp)
    80003fbe:	7442                	ld	s0,48(sp)
    80003fc0:	74a2                	ld	s1,40(sp)
    80003fc2:	7902                	ld	s2,32(sp)
    80003fc4:	69e2                	ld	s3,24(sp)
    80003fc6:	6a42                	ld	s4,16(sp)
    80003fc8:	6121                	addi	sp,sp,64
    80003fca:	8082                	ret

0000000080003fcc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003fcc:	711d                	addi	sp,sp,-96
    80003fce:	ec86                	sd	ra,88(sp)
    80003fd0:	e8a2                	sd	s0,80(sp)
    80003fd2:	e4a6                	sd	s1,72(sp)
    80003fd4:	e0ca                	sd	s2,64(sp)
    80003fd6:	fc4e                	sd	s3,56(sp)
    80003fd8:	f852                	sd	s4,48(sp)
    80003fda:	f456                	sd	s5,40(sp)
    80003fdc:	f05a                	sd	s6,32(sp)
    80003fde:	ec5e                	sd	s7,24(sp)
    80003fe0:	e862                	sd	s8,16(sp)
    80003fe2:	e466                	sd	s9,8(sp)
    80003fe4:	1080                	addi	s0,sp,96
    80003fe6:	84aa                	mv	s1,a0
    80003fe8:	8aae                	mv	s5,a1
    80003fea:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003fec:	00054703          	lbu	a4,0(a0)
    80003ff0:	02f00793          	li	a5,47
    80003ff4:	02f70363          	beq	a4,a5,8000401a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ff8:	ffffe097          	auipc	ra,0xffffe
    80003ffc:	986080e7          	jalr	-1658(ra) # 8000197e <myproc>
    80004000:	16853503          	ld	a0,360(a0)
    80004004:	00000097          	auipc	ra,0x0
    80004008:	9f6080e7          	jalr	-1546(ra) # 800039fa <idup>
    8000400c:	89aa                	mv	s3,a0
  while(*path == '/')
    8000400e:	02f00913          	li	s2,47
  len = path - s;
    80004012:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004014:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004016:	4b85                	li	s7,1
    80004018:	a865                	j	800040d0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000401a:	4585                	li	a1,1
    8000401c:	4505                	li	a0,1
    8000401e:	fffff097          	auipc	ra,0xfffff
    80004022:	6e6080e7          	jalr	1766(ra) # 80003704 <iget>
    80004026:	89aa                	mv	s3,a0
    80004028:	b7dd                	j	8000400e <namex+0x42>
      iunlockput(ip);
    8000402a:	854e                	mv	a0,s3
    8000402c:	00000097          	auipc	ra,0x0
    80004030:	c6e080e7          	jalr	-914(ra) # 80003c9a <iunlockput>
      return 0;
    80004034:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004036:	854e                	mv	a0,s3
    80004038:	60e6                	ld	ra,88(sp)
    8000403a:	6446                	ld	s0,80(sp)
    8000403c:	64a6                	ld	s1,72(sp)
    8000403e:	6906                	ld	s2,64(sp)
    80004040:	79e2                	ld	s3,56(sp)
    80004042:	7a42                	ld	s4,48(sp)
    80004044:	7aa2                	ld	s5,40(sp)
    80004046:	7b02                	ld	s6,32(sp)
    80004048:	6be2                	ld	s7,24(sp)
    8000404a:	6c42                	ld	s8,16(sp)
    8000404c:	6ca2                	ld	s9,8(sp)
    8000404e:	6125                	addi	sp,sp,96
    80004050:	8082                	ret
      iunlock(ip);
    80004052:	854e                	mv	a0,s3
    80004054:	00000097          	auipc	ra,0x0
    80004058:	aa6080e7          	jalr	-1370(ra) # 80003afa <iunlock>
      return ip;
    8000405c:	bfe9                	j	80004036 <namex+0x6a>
      iunlockput(ip);
    8000405e:	854e                	mv	a0,s3
    80004060:	00000097          	auipc	ra,0x0
    80004064:	c3a080e7          	jalr	-966(ra) # 80003c9a <iunlockput>
      return 0;
    80004068:	89e6                	mv	s3,s9
    8000406a:	b7f1                	j	80004036 <namex+0x6a>
  len = path - s;
    8000406c:	40b48633          	sub	a2,s1,a1
    80004070:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004074:	099c5463          	bge	s8,s9,800040fc <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004078:	4639                	li	a2,14
    8000407a:	8552                	mv	a0,s4
    8000407c:	ffffd097          	auipc	ra,0xffffd
    80004080:	c9e080e7          	jalr	-866(ra) # 80000d1a <memmove>
  while(*path == '/')
    80004084:	0004c783          	lbu	a5,0(s1)
    80004088:	01279763          	bne	a5,s2,80004096 <namex+0xca>
    path++;
    8000408c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000408e:	0004c783          	lbu	a5,0(s1)
    80004092:	ff278de3          	beq	a5,s2,8000408c <namex+0xc0>
    ilock(ip);
    80004096:	854e                	mv	a0,s3
    80004098:	00000097          	auipc	ra,0x0
    8000409c:	9a0080e7          	jalr	-1632(ra) # 80003a38 <ilock>
    if(ip->type != T_DIR){
    800040a0:	04499783          	lh	a5,68(s3)
    800040a4:	f97793e3          	bne	a5,s7,8000402a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800040a8:	000a8563          	beqz	s5,800040b2 <namex+0xe6>
    800040ac:	0004c783          	lbu	a5,0(s1)
    800040b0:	d3cd                	beqz	a5,80004052 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040b2:	865a                	mv	a2,s6
    800040b4:	85d2                	mv	a1,s4
    800040b6:	854e                	mv	a0,s3
    800040b8:	00000097          	auipc	ra,0x0
    800040bc:	e64080e7          	jalr	-412(ra) # 80003f1c <dirlookup>
    800040c0:	8caa                	mv	s9,a0
    800040c2:	dd51                	beqz	a0,8000405e <namex+0x92>
    iunlockput(ip);
    800040c4:	854e                	mv	a0,s3
    800040c6:	00000097          	auipc	ra,0x0
    800040ca:	bd4080e7          	jalr	-1068(ra) # 80003c9a <iunlockput>
    ip = next;
    800040ce:	89e6                	mv	s3,s9
  while(*path == '/')
    800040d0:	0004c783          	lbu	a5,0(s1)
    800040d4:	05279763          	bne	a5,s2,80004122 <namex+0x156>
    path++;
    800040d8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040da:	0004c783          	lbu	a5,0(s1)
    800040de:	ff278de3          	beq	a5,s2,800040d8 <namex+0x10c>
  if(*path == 0)
    800040e2:	c79d                	beqz	a5,80004110 <namex+0x144>
    path++;
    800040e4:	85a6                	mv	a1,s1
  len = path - s;
    800040e6:	8cda                	mv	s9,s6
    800040e8:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800040ea:	01278963          	beq	a5,s2,800040fc <namex+0x130>
    800040ee:	dfbd                	beqz	a5,8000406c <namex+0xa0>
    path++;
    800040f0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800040f2:	0004c783          	lbu	a5,0(s1)
    800040f6:	ff279ce3          	bne	a5,s2,800040ee <namex+0x122>
    800040fa:	bf8d                	j	8000406c <namex+0xa0>
    memmove(name, s, len);
    800040fc:	2601                	sext.w	a2,a2
    800040fe:	8552                	mv	a0,s4
    80004100:	ffffd097          	auipc	ra,0xffffd
    80004104:	c1a080e7          	jalr	-998(ra) # 80000d1a <memmove>
    name[len] = 0;
    80004108:	9cd2                	add	s9,s9,s4
    8000410a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000410e:	bf9d                	j	80004084 <namex+0xb8>
  if(nameiparent){
    80004110:	f20a83e3          	beqz	s5,80004036 <namex+0x6a>
    iput(ip);
    80004114:	854e                	mv	a0,s3
    80004116:	00000097          	auipc	ra,0x0
    8000411a:	adc080e7          	jalr	-1316(ra) # 80003bf2 <iput>
    return 0;
    8000411e:	4981                	li	s3,0
    80004120:	bf19                	j	80004036 <namex+0x6a>
  if(*path == 0)
    80004122:	d7fd                	beqz	a5,80004110 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004124:	0004c783          	lbu	a5,0(s1)
    80004128:	85a6                	mv	a1,s1
    8000412a:	b7d1                	j	800040ee <namex+0x122>

000000008000412c <dirlink>:
{
    8000412c:	7139                	addi	sp,sp,-64
    8000412e:	fc06                	sd	ra,56(sp)
    80004130:	f822                	sd	s0,48(sp)
    80004132:	f426                	sd	s1,40(sp)
    80004134:	f04a                	sd	s2,32(sp)
    80004136:	ec4e                	sd	s3,24(sp)
    80004138:	e852                	sd	s4,16(sp)
    8000413a:	0080                	addi	s0,sp,64
    8000413c:	892a                	mv	s2,a0
    8000413e:	8a2e                	mv	s4,a1
    80004140:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004142:	4601                	li	a2,0
    80004144:	00000097          	auipc	ra,0x0
    80004148:	dd8080e7          	jalr	-552(ra) # 80003f1c <dirlookup>
    8000414c:	e93d                	bnez	a0,800041c2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000414e:	04c92483          	lw	s1,76(s2)
    80004152:	c49d                	beqz	s1,80004180 <dirlink+0x54>
    80004154:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004156:	4741                	li	a4,16
    80004158:	86a6                	mv	a3,s1
    8000415a:	fc040613          	addi	a2,s0,-64
    8000415e:	4581                	li	a1,0
    80004160:	854a                	mv	a0,s2
    80004162:	00000097          	auipc	ra,0x0
    80004166:	b8a080e7          	jalr	-1142(ra) # 80003cec <readi>
    8000416a:	47c1                	li	a5,16
    8000416c:	06f51163          	bne	a0,a5,800041ce <dirlink+0xa2>
    if(de.inum == 0)
    80004170:	fc045783          	lhu	a5,-64(s0)
    80004174:	c791                	beqz	a5,80004180 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004176:	24c1                	addiw	s1,s1,16
    80004178:	04c92783          	lw	a5,76(s2)
    8000417c:	fcf4ede3          	bltu	s1,a5,80004156 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004180:	4639                	li	a2,14
    80004182:	85d2                	mv	a1,s4
    80004184:	fc240513          	addi	a0,s0,-62
    80004188:	ffffd097          	auipc	ra,0xffffd
    8000418c:	c4a080e7          	jalr	-950(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004190:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004194:	4741                	li	a4,16
    80004196:	86a6                	mv	a3,s1
    80004198:	fc040613          	addi	a2,s0,-64
    8000419c:	4581                	li	a1,0
    8000419e:	854a                	mv	a0,s2
    800041a0:	00000097          	auipc	ra,0x0
    800041a4:	c44080e7          	jalr	-956(ra) # 80003de4 <writei>
    800041a8:	872a                	mv	a4,a0
    800041aa:	47c1                	li	a5,16
  return 0;
    800041ac:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041ae:	02f71863          	bne	a4,a5,800041de <dirlink+0xb2>
}
    800041b2:	70e2                	ld	ra,56(sp)
    800041b4:	7442                	ld	s0,48(sp)
    800041b6:	74a2                	ld	s1,40(sp)
    800041b8:	7902                	ld	s2,32(sp)
    800041ba:	69e2                	ld	s3,24(sp)
    800041bc:	6a42                	ld	s4,16(sp)
    800041be:	6121                	addi	sp,sp,64
    800041c0:	8082                	ret
    iput(ip);
    800041c2:	00000097          	auipc	ra,0x0
    800041c6:	a30080e7          	jalr	-1488(ra) # 80003bf2 <iput>
    return -1;
    800041ca:	557d                	li	a0,-1
    800041cc:	b7dd                	j	800041b2 <dirlink+0x86>
      panic("dirlink read");
    800041ce:	00004517          	auipc	a0,0x4
    800041d2:	62250513          	addi	a0,a0,1570 # 800087f0 <syscalls+0x1e0>
    800041d6:	ffffc097          	auipc	ra,0xffffc
    800041da:	354080e7          	jalr	852(ra) # 8000052a <panic>
    panic("dirlink");
    800041de:	00004517          	auipc	a0,0x4
    800041e2:	71a50513          	addi	a0,a0,1818 # 800088f8 <syscalls+0x2e8>
    800041e6:	ffffc097          	auipc	ra,0xffffc
    800041ea:	344080e7          	jalr	836(ra) # 8000052a <panic>

00000000800041ee <namei>:

struct inode*
namei(char *path)
{
    800041ee:	1101                	addi	sp,sp,-32
    800041f0:	ec06                	sd	ra,24(sp)
    800041f2:	e822                	sd	s0,16(sp)
    800041f4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800041f6:	fe040613          	addi	a2,s0,-32
    800041fa:	4581                	li	a1,0
    800041fc:	00000097          	auipc	ra,0x0
    80004200:	dd0080e7          	jalr	-560(ra) # 80003fcc <namex>
}
    80004204:	60e2                	ld	ra,24(sp)
    80004206:	6442                	ld	s0,16(sp)
    80004208:	6105                	addi	sp,sp,32
    8000420a:	8082                	ret

000000008000420c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000420c:	1141                	addi	sp,sp,-16
    8000420e:	e406                	sd	ra,8(sp)
    80004210:	e022                	sd	s0,0(sp)
    80004212:	0800                	addi	s0,sp,16
    80004214:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004216:	4585                	li	a1,1
    80004218:	00000097          	auipc	ra,0x0
    8000421c:	db4080e7          	jalr	-588(ra) # 80003fcc <namex>
}
    80004220:	60a2                	ld	ra,8(sp)
    80004222:	6402                	ld	s0,0(sp)
    80004224:	0141                	addi	sp,sp,16
    80004226:	8082                	ret

0000000080004228 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004228:	1101                	addi	sp,sp,-32
    8000422a:	ec06                	sd	ra,24(sp)
    8000422c:	e822                	sd	s0,16(sp)
    8000422e:	e426                	sd	s1,8(sp)
    80004230:	e04a                	sd	s2,0(sp)
    80004232:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004234:	0001d917          	auipc	s2,0x1d
    80004238:	63c90913          	addi	s2,s2,1596 # 80021870 <log>
    8000423c:	01892583          	lw	a1,24(s2)
    80004240:	02892503          	lw	a0,40(s2)
    80004244:	fffff097          	auipc	ra,0xfffff
    80004248:	ff0080e7          	jalr	-16(ra) # 80003234 <bread>
    8000424c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000424e:	02c92683          	lw	a3,44(s2)
    80004252:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004254:	02d05863          	blez	a3,80004284 <write_head+0x5c>
    80004258:	0001d797          	auipc	a5,0x1d
    8000425c:	64878793          	addi	a5,a5,1608 # 800218a0 <log+0x30>
    80004260:	05c50713          	addi	a4,a0,92
    80004264:	36fd                	addiw	a3,a3,-1
    80004266:	02069613          	slli	a2,a3,0x20
    8000426a:	01e65693          	srli	a3,a2,0x1e
    8000426e:	0001d617          	auipc	a2,0x1d
    80004272:	63660613          	addi	a2,a2,1590 # 800218a4 <log+0x34>
    80004276:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004278:	4390                	lw	a2,0(a5)
    8000427a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000427c:	0791                	addi	a5,a5,4
    8000427e:	0711                	addi	a4,a4,4
    80004280:	fed79ce3          	bne	a5,a3,80004278 <write_head+0x50>
  }
  bwrite(buf);
    80004284:	8526                	mv	a0,s1
    80004286:	fffff097          	auipc	ra,0xfffff
    8000428a:	0a0080e7          	jalr	160(ra) # 80003326 <bwrite>
  brelse(buf);
    8000428e:	8526                	mv	a0,s1
    80004290:	fffff097          	auipc	ra,0xfffff
    80004294:	0d4080e7          	jalr	212(ra) # 80003364 <brelse>
}
    80004298:	60e2                	ld	ra,24(sp)
    8000429a:	6442                	ld	s0,16(sp)
    8000429c:	64a2                	ld	s1,8(sp)
    8000429e:	6902                	ld	s2,0(sp)
    800042a0:	6105                	addi	sp,sp,32
    800042a2:	8082                	ret

00000000800042a4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800042a4:	0001d797          	auipc	a5,0x1d
    800042a8:	5f87a783          	lw	a5,1528(a5) # 8002189c <log+0x2c>
    800042ac:	0af05d63          	blez	a5,80004366 <install_trans+0xc2>
{
    800042b0:	7139                	addi	sp,sp,-64
    800042b2:	fc06                	sd	ra,56(sp)
    800042b4:	f822                	sd	s0,48(sp)
    800042b6:	f426                	sd	s1,40(sp)
    800042b8:	f04a                	sd	s2,32(sp)
    800042ba:	ec4e                	sd	s3,24(sp)
    800042bc:	e852                	sd	s4,16(sp)
    800042be:	e456                	sd	s5,8(sp)
    800042c0:	e05a                	sd	s6,0(sp)
    800042c2:	0080                	addi	s0,sp,64
    800042c4:	8b2a                	mv	s6,a0
    800042c6:	0001da97          	auipc	s5,0x1d
    800042ca:	5daa8a93          	addi	s5,s5,1498 # 800218a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ce:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042d0:	0001d997          	auipc	s3,0x1d
    800042d4:	5a098993          	addi	s3,s3,1440 # 80021870 <log>
    800042d8:	a00d                	j	800042fa <install_trans+0x56>
    brelse(lbuf);
    800042da:	854a                	mv	a0,s2
    800042dc:	fffff097          	auipc	ra,0xfffff
    800042e0:	088080e7          	jalr	136(ra) # 80003364 <brelse>
    brelse(dbuf);
    800042e4:	8526                	mv	a0,s1
    800042e6:	fffff097          	auipc	ra,0xfffff
    800042ea:	07e080e7          	jalr	126(ra) # 80003364 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ee:	2a05                	addiw	s4,s4,1
    800042f0:	0a91                	addi	s5,s5,4
    800042f2:	02c9a783          	lw	a5,44(s3)
    800042f6:	04fa5e63          	bge	s4,a5,80004352 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042fa:	0189a583          	lw	a1,24(s3)
    800042fe:	014585bb          	addw	a1,a1,s4
    80004302:	2585                	addiw	a1,a1,1
    80004304:	0289a503          	lw	a0,40(s3)
    80004308:	fffff097          	auipc	ra,0xfffff
    8000430c:	f2c080e7          	jalr	-212(ra) # 80003234 <bread>
    80004310:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004312:	000aa583          	lw	a1,0(s5)
    80004316:	0289a503          	lw	a0,40(s3)
    8000431a:	fffff097          	auipc	ra,0xfffff
    8000431e:	f1a080e7          	jalr	-230(ra) # 80003234 <bread>
    80004322:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004324:	40000613          	li	a2,1024
    80004328:	05890593          	addi	a1,s2,88
    8000432c:	05850513          	addi	a0,a0,88
    80004330:	ffffd097          	auipc	ra,0xffffd
    80004334:	9ea080e7          	jalr	-1558(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004338:	8526                	mv	a0,s1
    8000433a:	fffff097          	auipc	ra,0xfffff
    8000433e:	fec080e7          	jalr	-20(ra) # 80003326 <bwrite>
    if(recovering == 0)
    80004342:	f80b1ce3          	bnez	s6,800042da <install_trans+0x36>
      bunpin(dbuf);
    80004346:	8526                	mv	a0,s1
    80004348:	fffff097          	auipc	ra,0xfffff
    8000434c:	0f6080e7          	jalr	246(ra) # 8000343e <bunpin>
    80004350:	b769                	j	800042da <install_trans+0x36>
}
    80004352:	70e2                	ld	ra,56(sp)
    80004354:	7442                	ld	s0,48(sp)
    80004356:	74a2                	ld	s1,40(sp)
    80004358:	7902                	ld	s2,32(sp)
    8000435a:	69e2                	ld	s3,24(sp)
    8000435c:	6a42                	ld	s4,16(sp)
    8000435e:	6aa2                	ld	s5,8(sp)
    80004360:	6b02                	ld	s6,0(sp)
    80004362:	6121                	addi	sp,sp,64
    80004364:	8082                	ret
    80004366:	8082                	ret

0000000080004368 <initlog>:
{
    80004368:	7179                	addi	sp,sp,-48
    8000436a:	f406                	sd	ra,40(sp)
    8000436c:	f022                	sd	s0,32(sp)
    8000436e:	ec26                	sd	s1,24(sp)
    80004370:	e84a                	sd	s2,16(sp)
    80004372:	e44e                	sd	s3,8(sp)
    80004374:	1800                	addi	s0,sp,48
    80004376:	892a                	mv	s2,a0
    80004378:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000437a:	0001d497          	auipc	s1,0x1d
    8000437e:	4f648493          	addi	s1,s1,1270 # 80021870 <log>
    80004382:	00004597          	auipc	a1,0x4
    80004386:	47e58593          	addi	a1,a1,1150 # 80008800 <syscalls+0x1f0>
    8000438a:	8526                	mv	a0,s1
    8000438c:	ffffc097          	auipc	ra,0xffffc
    80004390:	7a6080e7          	jalr	1958(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004394:	0149a583          	lw	a1,20(s3)
    80004398:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000439a:	0109a783          	lw	a5,16(s3)
    8000439e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800043a0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800043a4:	854a                	mv	a0,s2
    800043a6:	fffff097          	auipc	ra,0xfffff
    800043aa:	e8e080e7          	jalr	-370(ra) # 80003234 <bread>
  log.lh.n = lh->n;
    800043ae:	4d34                	lw	a3,88(a0)
    800043b0:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800043b2:	02d05663          	blez	a3,800043de <initlog+0x76>
    800043b6:	05c50793          	addi	a5,a0,92
    800043ba:	0001d717          	auipc	a4,0x1d
    800043be:	4e670713          	addi	a4,a4,1254 # 800218a0 <log+0x30>
    800043c2:	36fd                	addiw	a3,a3,-1
    800043c4:	02069613          	slli	a2,a3,0x20
    800043c8:	01e65693          	srli	a3,a2,0x1e
    800043cc:	06050613          	addi	a2,a0,96
    800043d0:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800043d2:	4390                	lw	a2,0(a5)
    800043d4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043d6:	0791                	addi	a5,a5,4
    800043d8:	0711                	addi	a4,a4,4
    800043da:	fed79ce3          	bne	a5,a3,800043d2 <initlog+0x6a>
  brelse(buf);
    800043de:	fffff097          	auipc	ra,0xfffff
    800043e2:	f86080e7          	jalr	-122(ra) # 80003364 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043e6:	4505                	li	a0,1
    800043e8:	00000097          	auipc	ra,0x0
    800043ec:	ebc080e7          	jalr	-324(ra) # 800042a4 <install_trans>
  log.lh.n = 0;
    800043f0:	0001d797          	auipc	a5,0x1d
    800043f4:	4a07a623          	sw	zero,1196(a5) # 8002189c <log+0x2c>
  write_head(); // clear the log
    800043f8:	00000097          	auipc	ra,0x0
    800043fc:	e30080e7          	jalr	-464(ra) # 80004228 <write_head>
}
    80004400:	70a2                	ld	ra,40(sp)
    80004402:	7402                	ld	s0,32(sp)
    80004404:	64e2                	ld	s1,24(sp)
    80004406:	6942                	ld	s2,16(sp)
    80004408:	69a2                	ld	s3,8(sp)
    8000440a:	6145                	addi	sp,sp,48
    8000440c:	8082                	ret

000000008000440e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000440e:	1101                	addi	sp,sp,-32
    80004410:	ec06                	sd	ra,24(sp)
    80004412:	e822                	sd	s0,16(sp)
    80004414:	e426                	sd	s1,8(sp)
    80004416:	e04a                	sd	s2,0(sp)
    80004418:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000441a:	0001d517          	auipc	a0,0x1d
    8000441e:	45650513          	addi	a0,a0,1110 # 80021870 <log>
    80004422:	ffffc097          	auipc	ra,0xffffc
    80004426:	7a0080e7          	jalr	1952(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    8000442a:	0001d497          	auipc	s1,0x1d
    8000442e:	44648493          	addi	s1,s1,1094 # 80021870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004432:	4979                	li	s2,30
    80004434:	a039                	j	80004442 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004436:	85a6                	mv	a1,s1
    80004438:	8526                	mv	a0,s1
    8000443a:	ffffe097          	auipc	ra,0xffffe
    8000443e:	c1a080e7          	jalr	-998(ra) # 80002054 <sleep>
    if(log.committing){
    80004442:	50dc                	lw	a5,36(s1)
    80004444:	fbed                	bnez	a5,80004436 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004446:	509c                	lw	a5,32(s1)
    80004448:	0017871b          	addiw	a4,a5,1
    8000444c:	0007069b          	sext.w	a3,a4
    80004450:	0027179b          	slliw	a5,a4,0x2
    80004454:	9fb9                	addw	a5,a5,a4
    80004456:	0017979b          	slliw	a5,a5,0x1
    8000445a:	54d8                	lw	a4,44(s1)
    8000445c:	9fb9                	addw	a5,a5,a4
    8000445e:	00f95963          	bge	s2,a5,80004470 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004462:	85a6                	mv	a1,s1
    80004464:	8526                	mv	a0,s1
    80004466:	ffffe097          	auipc	ra,0xffffe
    8000446a:	bee080e7          	jalr	-1042(ra) # 80002054 <sleep>
    8000446e:	bfd1                	j	80004442 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004470:	0001d517          	auipc	a0,0x1d
    80004474:	40050513          	addi	a0,a0,1024 # 80021870 <log>
    80004478:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000447a:	ffffc097          	auipc	ra,0xffffc
    8000447e:	7fc080e7          	jalr	2044(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004482:	60e2                	ld	ra,24(sp)
    80004484:	6442                	ld	s0,16(sp)
    80004486:	64a2                	ld	s1,8(sp)
    80004488:	6902                	ld	s2,0(sp)
    8000448a:	6105                	addi	sp,sp,32
    8000448c:	8082                	ret

000000008000448e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000448e:	7139                	addi	sp,sp,-64
    80004490:	fc06                	sd	ra,56(sp)
    80004492:	f822                	sd	s0,48(sp)
    80004494:	f426                	sd	s1,40(sp)
    80004496:	f04a                	sd	s2,32(sp)
    80004498:	ec4e                	sd	s3,24(sp)
    8000449a:	e852                	sd	s4,16(sp)
    8000449c:	e456                	sd	s5,8(sp)
    8000449e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800044a0:	0001d497          	auipc	s1,0x1d
    800044a4:	3d048493          	addi	s1,s1,976 # 80021870 <log>
    800044a8:	8526                	mv	a0,s1
    800044aa:	ffffc097          	auipc	ra,0xffffc
    800044ae:	718080e7          	jalr	1816(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    800044b2:	509c                	lw	a5,32(s1)
    800044b4:	37fd                	addiw	a5,a5,-1
    800044b6:	0007891b          	sext.w	s2,a5
    800044ba:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800044bc:	50dc                	lw	a5,36(s1)
    800044be:	e7b9                	bnez	a5,8000450c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800044c0:	04091e63          	bnez	s2,8000451c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800044c4:	0001d497          	auipc	s1,0x1d
    800044c8:	3ac48493          	addi	s1,s1,940 # 80021870 <log>
    800044cc:	4785                	li	a5,1
    800044ce:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800044d0:	8526                	mv	a0,s1
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	7a4080e7          	jalr	1956(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044da:	54dc                	lw	a5,44(s1)
    800044dc:	06f04763          	bgtz	a5,8000454a <end_op+0xbc>
    acquire(&log.lock);
    800044e0:	0001d497          	auipc	s1,0x1d
    800044e4:	39048493          	addi	s1,s1,912 # 80021870 <log>
    800044e8:	8526                	mv	a0,s1
    800044ea:	ffffc097          	auipc	ra,0xffffc
    800044ee:	6d8080e7          	jalr	1752(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800044f2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044f6:	8526                	mv	a0,s1
    800044f8:	ffffe097          	auipc	ra,0xffffe
    800044fc:	ce8080e7          	jalr	-792(ra) # 800021e0 <wakeup>
    release(&log.lock);
    80004500:	8526                	mv	a0,s1
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	774080e7          	jalr	1908(ra) # 80000c76 <release>
}
    8000450a:	a03d                	j	80004538 <end_op+0xaa>
    panic("log.committing");
    8000450c:	00004517          	auipc	a0,0x4
    80004510:	2fc50513          	addi	a0,a0,764 # 80008808 <syscalls+0x1f8>
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	016080e7          	jalr	22(ra) # 8000052a <panic>
    wakeup(&log);
    8000451c:	0001d497          	auipc	s1,0x1d
    80004520:	35448493          	addi	s1,s1,852 # 80021870 <log>
    80004524:	8526                	mv	a0,s1
    80004526:	ffffe097          	auipc	ra,0xffffe
    8000452a:	cba080e7          	jalr	-838(ra) # 800021e0 <wakeup>
  release(&log.lock);
    8000452e:	8526                	mv	a0,s1
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	746080e7          	jalr	1862(ra) # 80000c76 <release>
}
    80004538:	70e2                	ld	ra,56(sp)
    8000453a:	7442                	ld	s0,48(sp)
    8000453c:	74a2                	ld	s1,40(sp)
    8000453e:	7902                	ld	s2,32(sp)
    80004540:	69e2                	ld	s3,24(sp)
    80004542:	6a42                	ld	s4,16(sp)
    80004544:	6aa2                	ld	s5,8(sp)
    80004546:	6121                	addi	sp,sp,64
    80004548:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000454a:	0001da97          	auipc	s5,0x1d
    8000454e:	356a8a93          	addi	s5,s5,854 # 800218a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004552:	0001da17          	auipc	s4,0x1d
    80004556:	31ea0a13          	addi	s4,s4,798 # 80021870 <log>
    8000455a:	018a2583          	lw	a1,24(s4)
    8000455e:	012585bb          	addw	a1,a1,s2
    80004562:	2585                	addiw	a1,a1,1
    80004564:	028a2503          	lw	a0,40(s4)
    80004568:	fffff097          	auipc	ra,0xfffff
    8000456c:	ccc080e7          	jalr	-820(ra) # 80003234 <bread>
    80004570:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004572:	000aa583          	lw	a1,0(s5)
    80004576:	028a2503          	lw	a0,40(s4)
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	cba080e7          	jalr	-838(ra) # 80003234 <bread>
    80004582:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004584:	40000613          	li	a2,1024
    80004588:	05850593          	addi	a1,a0,88
    8000458c:	05848513          	addi	a0,s1,88
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	78a080e7          	jalr	1930(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004598:	8526                	mv	a0,s1
    8000459a:	fffff097          	auipc	ra,0xfffff
    8000459e:	d8c080e7          	jalr	-628(ra) # 80003326 <bwrite>
    brelse(from);
    800045a2:	854e                	mv	a0,s3
    800045a4:	fffff097          	auipc	ra,0xfffff
    800045a8:	dc0080e7          	jalr	-576(ra) # 80003364 <brelse>
    brelse(to);
    800045ac:	8526                	mv	a0,s1
    800045ae:	fffff097          	auipc	ra,0xfffff
    800045b2:	db6080e7          	jalr	-586(ra) # 80003364 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045b6:	2905                	addiw	s2,s2,1
    800045b8:	0a91                	addi	s5,s5,4
    800045ba:	02ca2783          	lw	a5,44(s4)
    800045be:	f8f94ee3          	blt	s2,a5,8000455a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800045c2:	00000097          	auipc	ra,0x0
    800045c6:	c66080e7          	jalr	-922(ra) # 80004228 <write_head>
    install_trans(0); // Now install writes to home locations
    800045ca:	4501                	li	a0,0
    800045cc:	00000097          	auipc	ra,0x0
    800045d0:	cd8080e7          	jalr	-808(ra) # 800042a4 <install_trans>
    log.lh.n = 0;
    800045d4:	0001d797          	auipc	a5,0x1d
    800045d8:	2c07a423          	sw	zero,712(a5) # 8002189c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045dc:	00000097          	auipc	ra,0x0
    800045e0:	c4c080e7          	jalr	-948(ra) # 80004228 <write_head>
    800045e4:	bdf5                	j	800044e0 <end_op+0x52>

00000000800045e6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045e6:	1101                	addi	sp,sp,-32
    800045e8:	ec06                	sd	ra,24(sp)
    800045ea:	e822                	sd	s0,16(sp)
    800045ec:	e426                	sd	s1,8(sp)
    800045ee:	e04a                	sd	s2,0(sp)
    800045f0:	1000                	addi	s0,sp,32
    800045f2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045f4:	0001d917          	auipc	s2,0x1d
    800045f8:	27c90913          	addi	s2,s2,636 # 80021870 <log>
    800045fc:	854a                	mv	a0,s2
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	5c4080e7          	jalr	1476(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004606:	02c92603          	lw	a2,44(s2)
    8000460a:	47f5                	li	a5,29
    8000460c:	06c7c563          	blt	a5,a2,80004676 <log_write+0x90>
    80004610:	0001d797          	auipc	a5,0x1d
    80004614:	27c7a783          	lw	a5,636(a5) # 8002188c <log+0x1c>
    80004618:	37fd                	addiw	a5,a5,-1
    8000461a:	04f65e63          	bge	a2,a5,80004676 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000461e:	0001d797          	auipc	a5,0x1d
    80004622:	2727a783          	lw	a5,626(a5) # 80021890 <log+0x20>
    80004626:	06f05063          	blez	a5,80004686 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000462a:	4781                	li	a5,0
    8000462c:	06c05563          	blez	a2,80004696 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004630:	44cc                	lw	a1,12(s1)
    80004632:	0001d717          	auipc	a4,0x1d
    80004636:	26e70713          	addi	a4,a4,622 # 800218a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000463a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000463c:	4314                	lw	a3,0(a4)
    8000463e:	04b68c63          	beq	a3,a1,80004696 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004642:	2785                	addiw	a5,a5,1
    80004644:	0711                	addi	a4,a4,4
    80004646:	fef61be3          	bne	a2,a5,8000463c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000464a:	0621                	addi	a2,a2,8
    8000464c:	060a                	slli	a2,a2,0x2
    8000464e:	0001d797          	auipc	a5,0x1d
    80004652:	22278793          	addi	a5,a5,546 # 80021870 <log>
    80004656:	963e                	add	a2,a2,a5
    80004658:	44dc                	lw	a5,12(s1)
    8000465a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000465c:	8526                	mv	a0,s1
    8000465e:	fffff097          	auipc	ra,0xfffff
    80004662:	da4080e7          	jalr	-604(ra) # 80003402 <bpin>
    log.lh.n++;
    80004666:	0001d717          	auipc	a4,0x1d
    8000466a:	20a70713          	addi	a4,a4,522 # 80021870 <log>
    8000466e:	575c                	lw	a5,44(a4)
    80004670:	2785                	addiw	a5,a5,1
    80004672:	d75c                	sw	a5,44(a4)
    80004674:	a835                	j	800046b0 <log_write+0xca>
    panic("too big a transaction");
    80004676:	00004517          	auipc	a0,0x4
    8000467a:	1a250513          	addi	a0,a0,418 # 80008818 <syscalls+0x208>
    8000467e:	ffffc097          	auipc	ra,0xffffc
    80004682:	eac080e7          	jalr	-340(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004686:	00004517          	auipc	a0,0x4
    8000468a:	1aa50513          	addi	a0,a0,426 # 80008830 <syscalls+0x220>
    8000468e:	ffffc097          	auipc	ra,0xffffc
    80004692:	e9c080e7          	jalr	-356(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004696:	00878713          	addi	a4,a5,8
    8000469a:	00271693          	slli	a3,a4,0x2
    8000469e:	0001d717          	auipc	a4,0x1d
    800046a2:	1d270713          	addi	a4,a4,466 # 80021870 <log>
    800046a6:	9736                	add	a4,a4,a3
    800046a8:	44d4                	lw	a3,12(s1)
    800046aa:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800046ac:	faf608e3          	beq	a2,a5,8000465c <log_write+0x76>
  }
  release(&log.lock);
    800046b0:	0001d517          	auipc	a0,0x1d
    800046b4:	1c050513          	addi	a0,a0,448 # 80021870 <log>
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	5be080e7          	jalr	1470(ra) # 80000c76 <release>
}
    800046c0:	60e2                	ld	ra,24(sp)
    800046c2:	6442                	ld	s0,16(sp)
    800046c4:	64a2                	ld	s1,8(sp)
    800046c6:	6902                	ld	s2,0(sp)
    800046c8:	6105                	addi	sp,sp,32
    800046ca:	8082                	ret

00000000800046cc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046cc:	1101                	addi	sp,sp,-32
    800046ce:	ec06                	sd	ra,24(sp)
    800046d0:	e822                	sd	s0,16(sp)
    800046d2:	e426                	sd	s1,8(sp)
    800046d4:	e04a                	sd	s2,0(sp)
    800046d6:	1000                	addi	s0,sp,32
    800046d8:	84aa                	mv	s1,a0
    800046da:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046dc:	00004597          	auipc	a1,0x4
    800046e0:	17458593          	addi	a1,a1,372 # 80008850 <syscalls+0x240>
    800046e4:	0521                	addi	a0,a0,8
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	44c080e7          	jalr	1100(ra) # 80000b32 <initlock>
  lk->name = name;
    800046ee:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046f2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046f6:	0204a423          	sw	zero,40(s1)
}
    800046fa:	60e2                	ld	ra,24(sp)
    800046fc:	6442                	ld	s0,16(sp)
    800046fe:	64a2                	ld	s1,8(sp)
    80004700:	6902                	ld	s2,0(sp)
    80004702:	6105                	addi	sp,sp,32
    80004704:	8082                	ret

0000000080004706 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004706:	1101                	addi	sp,sp,-32
    80004708:	ec06                	sd	ra,24(sp)
    8000470a:	e822                	sd	s0,16(sp)
    8000470c:	e426                	sd	s1,8(sp)
    8000470e:	e04a                	sd	s2,0(sp)
    80004710:	1000                	addi	s0,sp,32
    80004712:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004714:	00850913          	addi	s2,a0,8
    80004718:	854a                	mv	a0,s2
    8000471a:	ffffc097          	auipc	ra,0xffffc
    8000471e:	4a8080e7          	jalr	1192(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004722:	409c                	lw	a5,0(s1)
    80004724:	cb89                	beqz	a5,80004736 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004726:	85ca                	mv	a1,s2
    80004728:	8526                	mv	a0,s1
    8000472a:	ffffe097          	auipc	ra,0xffffe
    8000472e:	92a080e7          	jalr	-1750(ra) # 80002054 <sleep>
  while (lk->locked) {
    80004732:	409c                	lw	a5,0(s1)
    80004734:	fbed                	bnez	a5,80004726 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004736:	4785                	li	a5,1
    80004738:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000473a:	ffffd097          	auipc	ra,0xffffd
    8000473e:	244080e7          	jalr	580(ra) # 8000197e <myproc>
    80004742:	591c                	lw	a5,48(a0)
    80004744:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004746:	854a                	mv	a0,s2
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	52e080e7          	jalr	1326(ra) # 80000c76 <release>
}
    80004750:	60e2                	ld	ra,24(sp)
    80004752:	6442                	ld	s0,16(sp)
    80004754:	64a2                	ld	s1,8(sp)
    80004756:	6902                	ld	s2,0(sp)
    80004758:	6105                	addi	sp,sp,32
    8000475a:	8082                	ret

000000008000475c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000475c:	1101                	addi	sp,sp,-32
    8000475e:	ec06                	sd	ra,24(sp)
    80004760:	e822                	sd	s0,16(sp)
    80004762:	e426                	sd	s1,8(sp)
    80004764:	e04a                	sd	s2,0(sp)
    80004766:	1000                	addi	s0,sp,32
    80004768:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000476a:	00850913          	addi	s2,a0,8
    8000476e:	854a                	mv	a0,s2
    80004770:	ffffc097          	auipc	ra,0xffffc
    80004774:	452080e7          	jalr	1106(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004778:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000477c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004780:	8526                	mv	a0,s1
    80004782:	ffffe097          	auipc	ra,0xffffe
    80004786:	a5e080e7          	jalr	-1442(ra) # 800021e0 <wakeup>
  release(&lk->lk);
    8000478a:	854a                	mv	a0,s2
    8000478c:	ffffc097          	auipc	ra,0xffffc
    80004790:	4ea080e7          	jalr	1258(ra) # 80000c76 <release>
}
    80004794:	60e2                	ld	ra,24(sp)
    80004796:	6442                	ld	s0,16(sp)
    80004798:	64a2                	ld	s1,8(sp)
    8000479a:	6902                	ld	s2,0(sp)
    8000479c:	6105                	addi	sp,sp,32
    8000479e:	8082                	ret

00000000800047a0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800047a0:	7179                	addi	sp,sp,-48
    800047a2:	f406                	sd	ra,40(sp)
    800047a4:	f022                	sd	s0,32(sp)
    800047a6:	ec26                	sd	s1,24(sp)
    800047a8:	e84a                	sd	s2,16(sp)
    800047aa:	e44e                	sd	s3,8(sp)
    800047ac:	1800                	addi	s0,sp,48
    800047ae:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800047b0:	00850913          	addi	s2,a0,8
    800047b4:	854a                	mv	a0,s2
    800047b6:	ffffc097          	auipc	ra,0xffffc
    800047ba:	40c080e7          	jalr	1036(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800047be:	409c                	lw	a5,0(s1)
    800047c0:	ef99                	bnez	a5,800047de <holdingsleep+0x3e>
    800047c2:	4481                	li	s1,0
  release(&lk->lk);
    800047c4:	854a                	mv	a0,s2
    800047c6:	ffffc097          	auipc	ra,0xffffc
    800047ca:	4b0080e7          	jalr	1200(ra) # 80000c76 <release>
  return r;
}
    800047ce:	8526                	mv	a0,s1
    800047d0:	70a2                	ld	ra,40(sp)
    800047d2:	7402                	ld	s0,32(sp)
    800047d4:	64e2                	ld	s1,24(sp)
    800047d6:	6942                	ld	s2,16(sp)
    800047d8:	69a2                	ld	s3,8(sp)
    800047da:	6145                	addi	sp,sp,48
    800047dc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047de:	0284a983          	lw	s3,40(s1)
    800047e2:	ffffd097          	auipc	ra,0xffffd
    800047e6:	19c080e7          	jalr	412(ra) # 8000197e <myproc>
    800047ea:	5904                	lw	s1,48(a0)
    800047ec:	413484b3          	sub	s1,s1,s3
    800047f0:	0014b493          	seqz	s1,s1
    800047f4:	bfc1                	j	800047c4 <holdingsleep+0x24>

00000000800047f6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047f6:	1141                	addi	sp,sp,-16
    800047f8:	e406                	sd	ra,8(sp)
    800047fa:	e022                	sd	s0,0(sp)
    800047fc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047fe:	00004597          	auipc	a1,0x4
    80004802:	06258593          	addi	a1,a1,98 # 80008860 <syscalls+0x250>
    80004806:	0001d517          	auipc	a0,0x1d
    8000480a:	1b250513          	addi	a0,a0,434 # 800219b8 <ftable>
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	324080e7          	jalr	804(ra) # 80000b32 <initlock>
}
    80004816:	60a2                	ld	ra,8(sp)
    80004818:	6402                	ld	s0,0(sp)
    8000481a:	0141                	addi	sp,sp,16
    8000481c:	8082                	ret

000000008000481e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000481e:	1101                	addi	sp,sp,-32
    80004820:	ec06                	sd	ra,24(sp)
    80004822:	e822                	sd	s0,16(sp)
    80004824:	e426                	sd	s1,8(sp)
    80004826:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004828:	0001d517          	auipc	a0,0x1d
    8000482c:	19050513          	addi	a0,a0,400 # 800219b8 <ftable>
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	392080e7          	jalr	914(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004838:	0001d497          	auipc	s1,0x1d
    8000483c:	19848493          	addi	s1,s1,408 # 800219d0 <ftable+0x18>
    80004840:	0001e717          	auipc	a4,0x1e
    80004844:	13070713          	addi	a4,a4,304 # 80022970 <ftable+0xfb8>
    if(f->ref == 0){
    80004848:	40dc                	lw	a5,4(s1)
    8000484a:	cf99                	beqz	a5,80004868 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000484c:	02848493          	addi	s1,s1,40
    80004850:	fee49ce3          	bne	s1,a4,80004848 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004854:	0001d517          	auipc	a0,0x1d
    80004858:	16450513          	addi	a0,a0,356 # 800219b8 <ftable>
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	41a080e7          	jalr	1050(ra) # 80000c76 <release>
  return 0;
    80004864:	4481                	li	s1,0
    80004866:	a819                	j	8000487c <filealloc+0x5e>
      f->ref = 1;
    80004868:	4785                	li	a5,1
    8000486a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000486c:	0001d517          	auipc	a0,0x1d
    80004870:	14c50513          	addi	a0,a0,332 # 800219b8 <ftable>
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	402080e7          	jalr	1026(ra) # 80000c76 <release>
}
    8000487c:	8526                	mv	a0,s1
    8000487e:	60e2                	ld	ra,24(sp)
    80004880:	6442                	ld	s0,16(sp)
    80004882:	64a2                	ld	s1,8(sp)
    80004884:	6105                	addi	sp,sp,32
    80004886:	8082                	ret

0000000080004888 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004888:	1101                	addi	sp,sp,-32
    8000488a:	ec06                	sd	ra,24(sp)
    8000488c:	e822                	sd	s0,16(sp)
    8000488e:	e426                	sd	s1,8(sp)
    80004890:	1000                	addi	s0,sp,32
    80004892:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004894:	0001d517          	auipc	a0,0x1d
    80004898:	12450513          	addi	a0,a0,292 # 800219b8 <ftable>
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	326080e7          	jalr	806(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800048a4:	40dc                	lw	a5,4(s1)
    800048a6:	02f05263          	blez	a5,800048ca <filedup+0x42>
    panic("filedup");
  f->ref++;
    800048aa:	2785                	addiw	a5,a5,1
    800048ac:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800048ae:	0001d517          	auipc	a0,0x1d
    800048b2:	10a50513          	addi	a0,a0,266 # 800219b8 <ftable>
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	3c0080e7          	jalr	960(ra) # 80000c76 <release>
  return f;
}
    800048be:	8526                	mv	a0,s1
    800048c0:	60e2                	ld	ra,24(sp)
    800048c2:	6442                	ld	s0,16(sp)
    800048c4:	64a2                	ld	s1,8(sp)
    800048c6:	6105                	addi	sp,sp,32
    800048c8:	8082                	ret
    panic("filedup");
    800048ca:	00004517          	auipc	a0,0x4
    800048ce:	f9e50513          	addi	a0,a0,-98 # 80008868 <syscalls+0x258>
    800048d2:	ffffc097          	auipc	ra,0xffffc
    800048d6:	c58080e7          	jalr	-936(ra) # 8000052a <panic>

00000000800048da <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048da:	7139                	addi	sp,sp,-64
    800048dc:	fc06                	sd	ra,56(sp)
    800048de:	f822                	sd	s0,48(sp)
    800048e0:	f426                	sd	s1,40(sp)
    800048e2:	f04a                	sd	s2,32(sp)
    800048e4:	ec4e                	sd	s3,24(sp)
    800048e6:	e852                	sd	s4,16(sp)
    800048e8:	e456                	sd	s5,8(sp)
    800048ea:	0080                	addi	s0,sp,64
    800048ec:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048ee:	0001d517          	auipc	a0,0x1d
    800048f2:	0ca50513          	addi	a0,a0,202 # 800219b8 <ftable>
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	2cc080e7          	jalr	716(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800048fe:	40dc                	lw	a5,4(s1)
    80004900:	06f05163          	blez	a5,80004962 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004904:	37fd                	addiw	a5,a5,-1
    80004906:	0007871b          	sext.w	a4,a5
    8000490a:	c0dc                	sw	a5,4(s1)
    8000490c:	06e04363          	bgtz	a4,80004972 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004910:	0004a903          	lw	s2,0(s1)
    80004914:	0094ca83          	lbu	s5,9(s1)
    80004918:	0104ba03          	ld	s4,16(s1)
    8000491c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004920:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004924:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004928:	0001d517          	auipc	a0,0x1d
    8000492c:	09050513          	addi	a0,a0,144 # 800219b8 <ftable>
    80004930:	ffffc097          	auipc	ra,0xffffc
    80004934:	346080e7          	jalr	838(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004938:	4785                	li	a5,1
    8000493a:	04f90d63          	beq	s2,a5,80004994 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000493e:	3979                	addiw	s2,s2,-2
    80004940:	4785                	li	a5,1
    80004942:	0527e063          	bltu	a5,s2,80004982 <fileclose+0xa8>
    begin_op();
    80004946:	00000097          	auipc	ra,0x0
    8000494a:	ac8080e7          	jalr	-1336(ra) # 8000440e <begin_op>
    iput(ff.ip);
    8000494e:	854e                	mv	a0,s3
    80004950:	fffff097          	auipc	ra,0xfffff
    80004954:	2a2080e7          	jalr	674(ra) # 80003bf2 <iput>
    end_op();
    80004958:	00000097          	auipc	ra,0x0
    8000495c:	b36080e7          	jalr	-1226(ra) # 8000448e <end_op>
    80004960:	a00d                	j	80004982 <fileclose+0xa8>
    panic("fileclose");
    80004962:	00004517          	auipc	a0,0x4
    80004966:	f0e50513          	addi	a0,a0,-242 # 80008870 <syscalls+0x260>
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	bc0080e7          	jalr	-1088(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004972:	0001d517          	auipc	a0,0x1d
    80004976:	04650513          	addi	a0,a0,70 # 800219b8 <ftable>
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	2fc080e7          	jalr	764(ra) # 80000c76 <release>
  }
}
    80004982:	70e2                	ld	ra,56(sp)
    80004984:	7442                	ld	s0,48(sp)
    80004986:	74a2                	ld	s1,40(sp)
    80004988:	7902                	ld	s2,32(sp)
    8000498a:	69e2                	ld	s3,24(sp)
    8000498c:	6a42                	ld	s4,16(sp)
    8000498e:	6aa2                	ld	s5,8(sp)
    80004990:	6121                	addi	sp,sp,64
    80004992:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004994:	85d6                	mv	a1,s5
    80004996:	8552                	mv	a0,s4
    80004998:	00000097          	auipc	ra,0x0
    8000499c:	34c080e7          	jalr	844(ra) # 80004ce4 <pipeclose>
    800049a0:	b7cd                	j	80004982 <fileclose+0xa8>

00000000800049a2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800049a2:	715d                	addi	sp,sp,-80
    800049a4:	e486                	sd	ra,72(sp)
    800049a6:	e0a2                	sd	s0,64(sp)
    800049a8:	fc26                	sd	s1,56(sp)
    800049aa:	f84a                	sd	s2,48(sp)
    800049ac:	f44e                	sd	s3,40(sp)
    800049ae:	0880                	addi	s0,sp,80
    800049b0:	84aa                	mv	s1,a0
    800049b2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800049b4:	ffffd097          	auipc	ra,0xffffd
    800049b8:	fca080e7          	jalr	-54(ra) # 8000197e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800049bc:	409c                	lw	a5,0(s1)
    800049be:	37f9                	addiw	a5,a5,-2
    800049c0:	4705                	li	a4,1
    800049c2:	04f76763          	bltu	a4,a5,80004a10 <filestat+0x6e>
    800049c6:	892a                	mv	s2,a0
    ilock(f->ip);
    800049c8:	6c88                	ld	a0,24(s1)
    800049ca:	fffff097          	auipc	ra,0xfffff
    800049ce:	06e080e7          	jalr	110(ra) # 80003a38 <ilock>
    stati(f->ip, &st);
    800049d2:	fb840593          	addi	a1,s0,-72
    800049d6:	6c88                	ld	a0,24(s1)
    800049d8:	fffff097          	auipc	ra,0xfffff
    800049dc:	2ea080e7          	jalr	746(ra) # 80003cc2 <stati>
    iunlock(f->ip);
    800049e0:	6c88                	ld	a0,24(s1)
    800049e2:	fffff097          	auipc	ra,0xfffff
    800049e6:	118080e7          	jalr	280(ra) # 80003afa <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049ea:	46e1                	li	a3,24
    800049ec:	fb840613          	addi	a2,s0,-72
    800049f0:	85ce                	mv	a1,s3
    800049f2:	06893503          	ld	a0,104(s2)
    800049f6:	ffffd097          	auipc	ra,0xffffd
    800049fa:	c48080e7          	jalr	-952(ra) # 8000163e <copyout>
    800049fe:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a02:	60a6                	ld	ra,72(sp)
    80004a04:	6406                	ld	s0,64(sp)
    80004a06:	74e2                	ld	s1,56(sp)
    80004a08:	7942                	ld	s2,48(sp)
    80004a0a:	79a2                	ld	s3,40(sp)
    80004a0c:	6161                	addi	sp,sp,80
    80004a0e:	8082                	ret
  return -1;
    80004a10:	557d                	li	a0,-1
    80004a12:	bfc5                	j	80004a02 <filestat+0x60>

0000000080004a14 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a14:	7179                	addi	sp,sp,-48
    80004a16:	f406                	sd	ra,40(sp)
    80004a18:	f022                	sd	s0,32(sp)
    80004a1a:	ec26                	sd	s1,24(sp)
    80004a1c:	e84a                	sd	s2,16(sp)
    80004a1e:	e44e                	sd	s3,8(sp)
    80004a20:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a22:	00854783          	lbu	a5,8(a0)
    80004a26:	c3d5                	beqz	a5,80004aca <fileread+0xb6>
    80004a28:	84aa                	mv	s1,a0
    80004a2a:	89ae                	mv	s3,a1
    80004a2c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a2e:	411c                	lw	a5,0(a0)
    80004a30:	4705                	li	a4,1
    80004a32:	04e78963          	beq	a5,a4,80004a84 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a36:	470d                	li	a4,3
    80004a38:	04e78d63          	beq	a5,a4,80004a92 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a3c:	4709                	li	a4,2
    80004a3e:	06e79e63          	bne	a5,a4,80004aba <fileread+0xa6>
    ilock(f->ip);
    80004a42:	6d08                	ld	a0,24(a0)
    80004a44:	fffff097          	auipc	ra,0xfffff
    80004a48:	ff4080e7          	jalr	-12(ra) # 80003a38 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a4c:	874a                	mv	a4,s2
    80004a4e:	5094                	lw	a3,32(s1)
    80004a50:	864e                	mv	a2,s3
    80004a52:	4585                	li	a1,1
    80004a54:	6c88                	ld	a0,24(s1)
    80004a56:	fffff097          	auipc	ra,0xfffff
    80004a5a:	296080e7          	jalr	662(ra) # 80003cec <readi>
    80004a5e:	892a                	mv	s2,a0
    80004a60:	00a05563          	blez	a0,80004a6a <fileread+0x56>
      f->off += r;
    80004a64:	509c                	lw	a5,32(s1)
    80004a66:	9fa9                	addw	a5,a5,a0
    80004a68:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a6a:	6c88                	ld	a0,24(s1)
    80004a6c:	fffff097          	auipc	ra,0xfffff
    80004a70:	08e080e7          	jalr	142(ra) # 80003afa <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a74:	854a                	mv	a0,s2
    80004a76:	70a2                	ld	ra,40(sp)
    80004a78:	7402                	ld	s0,32(sp)
    80004a7a:	64e2                	ld	s1,24(sp)
    80004a7c:	6942                	ld	s2,16(sp)
    80004a7e:	69a2                	ld	s3,8(sp)
    80004a80:	6145                	addi	sp,sp,48
    80004a82:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a84:	6908                	ld	a0,16(a0)
    80004a86:	00000097          	auipc	ra,0x0
    80004a8a:	3c0080e7          	jalr	960(ra) # 80004e46 <piperead>
    80004a8e:	892a                	mv	s2,a0
    80004a90:	b7d5                	j	80004a74 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a92:	02451783          	lh	a5,36(a0)
    80004a96:	03079693          	slli	a3,a5,0x30
    80004a9a:	92c1                	srli	a3,a3,0x30
    80004a9c:	4725                	li	a4,9
    80004a9e:	02d76863          	bltu	a4,a3,80004ace <fileread+0xba>
    80004aa2:	0792                	slli	a5,a5,0x4
    80004aa4:	0001d717          	auipc	a4,0x1d
    80004aa8:	e7470713          	addi	a4,a4,-396 # 80021918 <devsw>
    80004aac:	97ba                	add	a5,a5,a4
    80004aae:	639c                	ld	a5,0(a5)
    80004ab0:	c38d                	beqz	a5,80004ad2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ab2:	4505                	li	a0,1
    80004ab4:	9782                	jalr	a5
    80004ab6:	892a                	mv	s2,a0
    80004ab8:	bf75                	j	80004a74 <fileread+0x60>
    panic("fileread");
    80004aba:	00004517          	auipc	a0,0x4
    80004abe:	dc650513          	addi	a0,a0,-570 # 80008880 <syscalls+0x270>
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	a68080e7          	jalr	-1432(ra) # 8000052a <panic>
    return -1;
    80004aca:	597d                	li	s2,-1
    80004acc:	b765                	j	80004a74 <fileread+0x60>
      return -1;
    80004ace:	597d                	li	s2,-1
    80004ad0:	b755                	j	80004a74 <fileread+0x60>
    80004ad2:	597d                	li	s2,-1
    80004ad4:	b745                	j	80004a74 <fileread+0x60>

0000000080004ad6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ad6:	715d                	addi	sp,sp,-80
    80004ad8:	e486                	sd	ra,72(sp)
    80004ada:	e0a2                	sd	s0,64(sp)
    80004adc:	fc26                	sd	s1,56(sp)
    80004ade:	f84a                	sd	s2,48(sp)
    80004ae0:	f44e                	sd	s3,40(sp)
    80004ae2:	f052                	sd	s4,32(sp)
    80004ae4:	ec56                	sd	s5,24(sp)
    80004ae6:	e85a                	sd	s6,16(sp)
    80004ae8:	e45e                	sd	s7,8(sp)
    80004aea:	e062                	sd	s8,0(sp)
    80004aec:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004aee:	00954783          	lbu	a5,9(a0)
    80004af2:	10078663          	beqz	a5,80004bfe <filewrite+0x128>
    80004af6:	892a                	mv	s2,a0
    80004af8:	8aae                	mv	s5,a1
    80004afa:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004afc:	411c                	lw	a5,0(a0)
    80004afe:	4705                	li	a4,1
    80004b00:	02e78263          	beq	a5,a4,80004b24 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b04:	470d                	li	a4,3
    80004b06:	02e78663          	beq	a5,a4,80004b32 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b0a:	4709                	li	a4,2
    80004b0c:	0ee79163          	bne	a5,a4,80004bee <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b10:	0ac05d63          	blez	a2,80004bca <filewrite+0xf4>
    int i = 0;
    80004b14:	4981                	li	s3,0
    80004b16:	6b05                	lui	s6,0x1
    80004b18:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004b1c:	6b85                	lui	s7,0x1
    80004b1e:	c00b8b9b          	addiw	s7,s7,-1024
    80004b22:	a861                	j	80004bba <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004b24:	6908                	ld	a0,16(a0)
    80004b26:	00000097          	auipc	ra,0x0
    80004b2a:	22e080e7          	jalr	558(ra) # 80004d54 <pipewrite>
    80004b2e:	8a2a                	mv	s4,a0
    80004b30:	a045                	j	80004bd0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b32:	02451783          	lh	a5,36(a0)
    80004b36:	03079693          	slli	a3,a5,0x30
    80004b3a:	92c1                	srli	a3,a3,0x30
    80004b3c:	4725                	li	a4,9
    80004b3e:	0cd76263          	bltu	a4,a3,80004c02 <filewrite+0x12c>
    80004b42:	0792                	slli	a5,a5,0x4
    80004b44:	0001d717          	auipc	a4,0x1d
    80004b48:	dd470713          	addi	a4,a4,-556 # 80021918 <devsw>
    80004b4c:	97ba                	add	a5,a5,a4
    80004b4e:	679c                	ld	a5,8(a5)
    80004b50:	cbdd                	beqz	a5,80004c06 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004b52:	4505                	li	a0,1
    80004b54:	9782                	jalr	a5
    80004b56:	8a2a                	mv	s4,a0
    80004b58:	a8a5                	j	80004bd0 <filewrite+0xfa>
    80004b5a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b5e:	00000097          	auipc	ra,0x0
    80004b62:	8b0080e7          	jalr	-1872(ra) # 8000440e <begin_op>
      ilock(f->ip);
    80004b66:	01893503          	ld	a0,24(s2)
    80004b6a:	fffff097          	auipc	ra,0xfffff
    80004b6e:	ece080e7          	jalr	-306(ra) # 80003a38 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b72:	8762                	mv	a4,s8
    80004b74:	02092683          	lw	a3,32(s2)
    80004b78:	01598633          	add	a2,s3,s5
    80004b7c:	4585                	li	a1,1
    80004b7e:	01893503          	ld	a0,24(s2)
    80004b82:	fffff097          	auipc	ra,0xfffff
    80004b86:	262080e7          	jalr	610(ra) # 80003de4 <writei>
    80004b8a:	84aa                	mv	s1,a0
    80004b8c:	00a05763          	blez	a0,80004b9a <filewrite+0xc4>
        f->off += r;
    80004b90:	02092783          	lw	a5,32(s2)
    80004b94:	9fa9                	addw	a5,a5,a0
    80004b96:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b9a:	01893503          	ld	a0,24(s2)
    80004b9e:	fffff097          	auipc	ra,0xfffff
    80004ba2:	f5c080e7          	jalr	-164(ra) # 80003afa <iunlock>
      end_op();
    80004ba6:	00000097          	auipc	ra,0x0
    80004baa:	8e8080e7          	jalr	-1816(ra) # 8000448e <end_op>

      if(r != n1){
    80004bae:	009c1f63          	bne	s8,s1,80004bcc <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004bb2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004bb6:	0149db63          	bge	s3,s4,80004bcc <filewrite+0xf6>
      int n1 = n - i;
    80004bba:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004bbe:	84be                	mv	s1,a5
    80004bc0:	2781                	sext.w	a5,a5
    80004bc2:	f8fb5ce3          	bge	s6,a5,80004b5a <filewrite+0x84>
    80004bc6:	84de                	mv	s1,s7
    80004bc8:	bf49                	j	80004b5a <filewrite+0x84>
    int i = 0;
    80004bca:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004bcc:	013a1f63          	bne	s4,s3,80004bea <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004bd0:	8552                	mv	a0,s4
    80004bd2:	60a6                	ld	ra,72(sp)
    80004bd4:	6406                	ld	s0,64(sp)
    80004bd6:	74e2                	ld	s1,56(sp)
    80004bd8:	7942                	ld	s2,48(sp)
    80004bda:	79a2                	ld	s3,40(sp)
    80004bdc:	7a02                	ld	s4,32(sp)
    80004bde:	6ae2                	ld	s5,24(sp)
    80004be0:	6b42                	ld	s6,16(sp)
    80004be2:	6ba2                	ld	s7,8(sp)
    80004be4:	6c02                	ld	s8,0(sp)
    80004be6:	6161                	addi	sp,sp,80
    80004be8:	8082                	ret
    ret = (i == n ? n : -1);
    80004bea:	5a7d                	li	s4,-1
    80004bec:	b7d5                	j	80004bd0 <filewrite+0xfa>
    panic("filewrite");
    80004bee:	00004517          	auipc	a0,0x4
    80004bf2:	ca250513          	addi	a0,a0,-862 # 80008890 <syscalls+0x280>
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	934080e7          	jalr	-1740(ra) # 8000052a <panic>
    return -1;
    80004bfe:	5a7d                	li	s4,-1
    80004c00:	bfc1                	j	80004bd0 <filewrite+0xfa>
      return -1;
    80004c02:	5a7d                	li	s4,-1
    80004c04:	b7f1                	j	80004bd0 <filewrite+0xfa>
    80004c06:	5a7d                	li	s4,-1
    80004c08:	b7e1                	j	80004bd0 <filewrite+0xfa>

0000000080004c0a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c0a:	7179                	addi	sp,sp,-48
    80004c0c:	f406                	sd	ra,40(sp)
    80004c0e:	f022                	sd	s0,32(sp)
    80004c10:	ec26                	sd	s1,24(sp)
    80004c12:	e84a                	sd	s2,16(sp)
    80004c14:	e44e                	sd	s3,8(sp)
    80004c16:	e052                	sd	s4,0(sp)
    80004c18:	1800                	addi	s0,sp,48
    80004c1a:	84aa                	mv	s1,a0
    80004c1c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c1e:	0005b023          	sd	zero,0(a1)
    80004c22:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c26:	00000097          	auipc	ra,0x0
    80004c2a:	bf8080e7          	jalr	-1032(ra) # 8000481e <filealloc>
    80004c2e:	e088                	sd	a0,0(s1)
    80004c30:	c551                	beqz	a0,80004cbc <pipealloc+0xb2>
    80004c32:	00000097          	auipc	ra,0x0
    80004c36:	bec080e7          	jalr	-1044(ra) # 8000481e <filealloc>
    80004c3a:	00aa3023          	sd	a0,0(s4)
    80004c3e:	c92d                	beqz	a0,80004cb0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	e92080e7          	jalr	-366(ra) # 80000ad2 <kalloc>
    80004c48:	892a                	mv	s2,a0
    80004c4a:	c125                	beqz	a0,80004caa <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c4c:	4985                	li	s3,1
    80004c4e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c52:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c56:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c5a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c5e:	00004597          	auipc	a1,0x4
    80004c62:	82a58593          	addi	a1,a1,-2006 # 80008488 <states.0+0x1e0>
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	ecc080e7          	jalr	-308(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004c6e:	609c                	ld	a5,0(s1)
    80004c70:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c74:	609c                	ld	a5,0(s1)
    80004c76:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c7a:	609c                	ld	a5,0(s1)
    80004c7c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c80:	609c                	ld	a5,0(s1)
    80004c82:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c86:	000a3783          	ld	a5,0(s4)
    80004c8a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c8e:	000a3783          	ld	a5,0(s4)
    80004c92:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c96:	000a3783          	ld	a5,0(s4)
    80004c9a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c9e:	000a3783          	ld	a5,0(s4)
    80004ca2:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ca6:	4501                	li	a0,0
    80004ca8:	a025                	j	80004cd0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004caa:	6088                	ld	a0,0(s1)
    80004cac:	e501                	bnez	a0,80004cb4 <pipealloc+0xaa>
    80004cae:	a039                	j	80004cbc <pipealloc+0xb2>
    80004cb0:	6088                	ld	a0,0(s1)
    80004cb2:	c51d                	beqz	a0,80004ce0 <pipealloc+0xd6>
    fileclose(*f0);
    80004cb4:	00000097          	auipc	ra,0x0
    80004cb8:	c26080e7          	jalr	-986(ra) # 800048da <fileclose>
  if(*f1)
    80004cbc:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004cc0:	557d                	li	a0,-1
  if(*f1)
    80004cc2:	c799                	beqz	a5,80004cd0 <pipealloc+0xc6>
    fileclose(*f1);
    80004cc4:	853e                	mv	a0,a5
    80004cc6:	00000097          	auipc	ra,0x0
    80004cca:	c14080e7          	jalr	-1004(ra) # 800048da <fileclose>
  return -1;
    80004cce:	557d                	li	a0,-1
}
    80004cd0:	70a2                	ld	ra,40(sp)
    80004cd2:	7402                	ld	s0,32(sp)
    80004cd4:	64e2                	ld	s1,24(sp)
    80004cd6:	6942                	ld	s2,16(sp)
    80004cd8:	69a2                	ld	s3,8(sp)
    80004cda:	6a02                	ld	s4,0(sp)
    80004cdc:	6145                	addi	sp,sp,48
    80004cde:	8082                	ret
  return -1;
    80004ce0:	557d                	li	a0,-1
    80004ce2:	b7fd                	j	80004cd0 <pipealloc+0xc6>

0000000080004ce4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ce4:	1101                	addi	sp,sp,-32
    80004ce6:	ec06                	sd	ra,24(sp)
    80004ce8:	e822                	sd	s0,16(sp)
    80004cea:	e426                	sd	s1,8(sp)
    80004cec:	e04a                	sd	s2,0(sp)
    80004cee:	1000                	addi	s0,sp,32
    80004cf0:	84aa                	mv	s1,a0
    80004cf2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004cf4:	ffffc097          	auipc	ra,0xffffc
    80004cf8:	ece080e7          	jalr	-306(ra) # 80000bc2 <acquire>
  if(writable){
    80004cfc:	02090d63          	beqz	s2,80004d36 <pipeclose+0x52>
    pi->writeopen = 0;
    80004d00:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d04:	21848513          	addi	a0,s1,536
    80004d08:	ffffd097          	auipc	ra,0xffffd
    80004d0c:	4d8080e7          	jalr	1240(ra) # 800021e0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d10:	2204b783          	ld	a5,544(s1)
    80004d14:	eb95                	bnez	a5,80004d48 <pipeclose+0x64>
    release(&pi->lock);
    80004d16:	8526                	mv	a0,s1
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	f5e080e7          	jalr	-162(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004d20:	8526                	mv	a0,s1
    80004d22:	ffffc097          	auipc	ra,0xffffc
    80004d26:	cb4080e7          	jalr	-844(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004d2a:	60e2                	ld	ra,24(sp)
    80004d2c:	6442                	ld	s0,16(sp)
    80004d2e:	64a2                	ld	s1,8(sp)
    80004d30:	6902                	ld	s2,0(sp)
    80004d32:	6105                	addi	sp,sp,32
    80004d34:	8082                	ret
    pi->readopen = 0;
    80004d36:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d3a:	21c48513          	addi	a0,s1,540
    80004d3e:	ffffd097          	auipc	ra,0xffffd
    80004d42:	4a2080e7          	jalr	1186(ra) # 800021e0 <wakeup>
    80004d46:	b7e9                	j	80004d10 <pipeclose+0x2c>
    release(&pi->lock);
    80004d48:	8526                	mv	a0,s1
    80004d4a:	ffffc097          	auipc	ra,0xffffc
    80004d4e:	f2c080e7          	jalr	-212(ra) # 80000c76 <release>
}
    80004d52:	bfe1                	j	80004d2a <pipeclose+0x46>

0000000080004d54 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d54:	711d                	addi	sp,sp,-96
    80004d56:	ec86                	sd	ra,88(sp)
    80004d58:	e8a2                	sd	s0,80(sp)
    80004d5a:	e4a6                	sd	s1,72(sp)
    80004d5c:	e0ca                	sd	s2,64(sp)
    80004d5e:	fc4e                	sd	s3,56(sp)
    80004d60:	f852                	sd	s4,48(sp)
    80004d62:	f456                	sd	s5,40(sp)
    80004d64:	f05a                	sd	s6,32(sp)
    80004d66:	ec5e                	sd	s7,24(sp)
    80004d68:	e862                	sd	s8,16(sp)
    80004d6a:	1080                	addi	s0,sp,96
    80004d6c:	84aa                	mv	s1,a0
    80004d6e:	8aae                	mv	s5,a1
    80004d70:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d72:	ffffd097          	auipc	ra,0xffffd
    80004d76:	c0c080e7          	jalr	-1012(ra) # 8000197e <myproc>
    80004d7a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d7c:	8526                	mv	a0,s1
    80004d7e:	ffffc097          	auipc	ra,0xffffc
    80004d82:	e44080e7          	jalr	-444(ra) # 80000bc2 <acquire>
  while(i < n){
    80004d86:	0b405363          	blez	s4,80004e2c <pipewrite+0xd8>
  int i = 0;
    80004d8a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d8c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d8e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d92:	21c48b93          	addi	s7,s1,540
    80004d96:	a089                	j	80004dd8 <pipewrite+0x84>
      release(&pi->lock);
    80004d98:	8526                	mv	a0,s1
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	edc080e7          	jalr	-292(ra) # 80000c76 <release>
      return -1;
    80004da2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004da4:	854a                	mv	a0,s2
    80004da6:	60e6                	ld	ra,88(sp)
    80004da8:	6446                	ld	s0,80(sp)
    80004daa:	64a6                	ld	s1,72(sp)
    80004dac:	6906                	ld	s2,64(sp)
    80004dae:	79e2                	ld	s3,56(sp)
    80004db0:	7a42                	ld	s4,48(sp)
    80004db2:	7aa2                	ld	s5,40(sp)
    80004db4:	7b02                	ld	s6,32(sp)
    80004db6:	6be2                	ld	s7,24(sp)
    80004db8:	6c42                	ld	s8,16(sp)
    80004dba:	6125                	addi	sp,sp,96
    80004dbc:	8082                	ret
      wakeup(&pi->nread);
    80004dbe:	8562                	mv	a0,s8
    80004dc0:	ffffd097          	auipc	ra,0xffffd
    80004dc4:	420080e7          	jalr	1056(ra) # 800021e0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004dc8:	85a6                	mv	a1,s1
    80004dca:	855e                	mv	a0,s7
    80004dcc:	ffffd097          	auipc	ra,0xffffd
    80004dd0:	288080e7          	jalr	648(ra) # 80002054 <sleep>
  while(i < n){
    80004dd4:	05495d63          	bge	s2,s4,80004e2e <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004dd8:	2204a783          	lw	a5,544(s1)
    80004ddc:	dfd5                	beqz	a5,80004d98 <pipewrite+0x44>
    80004dde:	0289a783          	lw	a5,40(s3)
    80004de2:	fbdd                	bnez	a5,80004d98 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004de4:	2184a783          	lw	a5,536(s1)
    80004de8:	21c4a703          	lw	a4,540(s1)
    80004dec:	2007879b          	addiw	a5,a5,512
    80004df0:	fcf707e3          	beq	a4,a5,80004dbe <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004df4:	4685                	li	a3,1
    80004df6:	01590633          	add	a2,s2,s5
    80004dfa:	faf40593          	addi	a1,s0,-81
    80004dfe:	0689b503          	ld	a0,104(s3)
    80004e02:	ffffd097          	auipc	ra,0xffffd
    80004e06:	8c8080e7          	jalr	-1848(ra) # 800016ca <copyin>
    80004e0a:	03650263          	beq	a0,s6,80004e2e <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e0e:	21c4a783          	lw	a5,540(s1)
    80004e12:	0017871b          	addiw	a4,a5,1
    80004e16:	20e4ae23          	sw	a4,540(s1)
    80004e1a:	1ff7f793          	andi	a5,a5,511
    80004e1e:	97a6                	add	a5,a5,s1
    80004e20:	faf44703          	lbu	a4,-81(s0)
    80004e24:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e28:	2905                	addiw	s2,s2,1
    80004e2a:	b76d                	j	80004dd4 <pipewrite+0x80>
  int i = 0;
    80004e2c:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004e2e:	21848513          	addi	a0,s1,536
    80004e32:	ffffd097          	auipc	ra,0xffffd
    80004e36:	3ae080e7          	jalr	942(ra) # 800021e0 <wakeup>
  release(&pi->lock);
    80004e3a:	8526                	mv	a0,s1
    80004e3c:	ffffc097          	auipc	ra,0xffffc
    80004e40:	e3a080e7          	jalr	-454(ra) # 80000c76 <release>
  return i;
    80004e44:	b785                	j	80004da4 <pipewrite+0x50>

0000000080004e46 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e46:	715d                	addi	sp,sp,-80
    80004e48:	e486                	sd	ra,72(sp)
    80004e4a:	e0a2                	sd	s0,64(sp)
    80004e4c:	fc26                	sd	s1,56(sp)
    80004e4e:	f84a                	sd	s2,48(sp)
    80004e50:	f44e                	sd	s3,40(sp)
    80004e52:	f052                	sd	s4,32(sp)
    80004e54:	ec56                	sd	s5,24(sp)
    80004e56:	e85a                	sd	s6,16(sp)
    80004e58:	0880                	addi	s0,sp,80
    80004e5a:	84aa                	mv	s1,a0
    80004e5c:	892e                	mv	s2,a1
    80004e5e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e60:	ffffd097          	auipc	ra,0xffffd
    80004e64:	b1e080e7          	jalr	-1250(ra) # 8000197e <myproc>
    80004e68:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e6a:	8526                	mv	a0,s1
    80004e6c:	ffffc097          	auipc	ra,0xffffc
    80004e70:	d56080e7          	jalr	-682(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e74:	2184a703          	lw	a4,536(s1)
    80004e78:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e7c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e80:	02f71463          	bne	a4,a5,80004ea8 <piperead+0x62>
    80004e84:	2244a783          	lw	a5,548(s1)
    80004e88:	c385                	beqz	a5,80004ea8 <piperead+0x62>
    if(pr->killed){
    80004e8a:	028a2783          	lw	a5,40(s4)
    80004e8e:	ebc1                	bnez	a5,80004f1e <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e90:	85a6                	mv	a1,s1
    80004e92:	854e                	mv	a0,s3
    80004e94:	ffffd097          	auipc	ra,0xffffd
    80004e98:	1c0080e7          	jalr	448(ra) # 80002054 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e9c:	2184a703          	lw	a4,536(s1)
    80004ea0:	21c4a783          	lw	a5,540(s1)
    80004ea4:	fef700e3          	beq	a4,a5,80004e84 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ea8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004eaa:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eac:	05505363          	blez	s5,80004ef2 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004eb0:	2184a783          	lw	a5,536(s1)
    80004eb4:	21c4a703          	lw	a4,540(s1)
    80004eb8:	02f70d63          	beq	a4,a5,80004ef2 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ebc:	0017871b          	addiw	a4,a5,1
    80004ec0:	20e4ac23          	sw	a4,536(s1)
    80004ec4:	1ff7f793          	andi	a5,a5,511
    80004ec8:	97a6                	add	a5,a5,s1
    80004eca:	0187c783          	lbu	a5,24(a5)
    80004ece:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ed2:	4685                	li	a3,1
    80004ed4:	fbf40613          	addi	a2,s0,-65
    80004ed8:	85ca                	mv	a1,s2
    80004eda:	068a3503          	ld	a0,104(s4)
    80004ede:	ffffc097          	auipc	ra,0xffffc
    80004ee2:	760080e7          	jalr	1888(ra) # 8000163e <copyout>
    80004ee6:	01650663          	beq	a0,s6,80004ef2 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eea:	2985                	addiw	s3,s3,1
    80004eec:	0905                	addi	s2,s2,1
    80004eee:	fd3a91e3          	bne	s5,s3,80004eb0 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ef2:	21c48513          	addi	a0,s1,540
    80004ef6:	ffffd097          	auipc	ra,0xffffd
    80004efa:	2ea080e7          	jalr	746(ra) # 800021e0 <wakeup>
  release(&pi->lock);
    80004efe:	8526                	mv	a0,s1
    80004f00:	ffffc097          	auipc	ra,0xffffc
    80004f04:	d76080e7          	jalr	-650(ra) # 80000c76 <release>
  return i;
}
    80004f08:	854e                	mv	a0,s3
    80004f0a:	60a6                	ld	ra,72(sp)
    80004f0c:	6406                	ld	s0,64(sp)
    80004f0e:	74e2                	ld	s1,56(sp)
    80004f10:	7942                	ld	s2,48(sp)
    80004f12:	79a2                	ld	s3,40(sp)
    80004f14:	7a02                	ld	s4,32(sp)
    80004f16:	6ae2                	ld	s5,24(sp)
    80004f18:	6b42                	ld	s6,16(sp)
    80004f1a:	6161                	addi	sp,sp,80
    80004f1c:	8082                	ret
      release(&pi->lock);
    80004f1e:	8526                	mv	a0,s1
    80004f20:	ffffc097          	auipc	ra,0xffffc
    80004f24:	d56080e7          	jalr	-682(ra) # 80000c76 <release>
      return -1;
    80004f28:	59fd                	li	s3,-1
    80004f2a:	bff9                	j	80004f08 <piperead+0xc2>

0000000080004f2c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004f2c:	de010113          	addi	sp,sp,-544
    80004f30:	20113c23          	sd	ra,536(sp)
    80004f34:	20813823          	sd	s0,528(sp)
    80004f38:	20913423          	sd	s1,520(sp)
    80004f3c:	21213023          	sd	s2,512(sp)
    80004f40:	ffce                	sd	s3,504(sp)
    80004f42:	fbd2                	sd	s4,496(sp)
    80004f44:	f7d6                	sd	s5,488(sp)
    80004f46:	f3da                	sd	s6,480(sp)
    80004f48:	efde                	sd	s7,472(sp)
    80004f4a:	ebe2                	sd	s8,464(sp)
    80004f4c:	e7e6                	sd	s9,456(sp)
    80004f4e:	e3ea                	sd	s10,448(sp)
    80004f50:	ff6e                	sd	s11,440(sp)
    80004f52:	1400                	addi	s0,sp,544
    80004f54:	892a                	mv	s2,a0
    80004f56:	dea43423          	sd	a0,-536(s0)
    80004f5a:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f5e:	ffffd097          	auipc	ra,0xffffd
    80004f62:	a20080e7          	jalr	-1504(ra) # 8000197e <myproc>
    80004f66:	84aa                	mv	s1,a0

  begin_op();
    80004f68:	fffff097          	auipc	ra,0xfffff
    80004f6c:	4a6080e7          	jalr	1190(ra) # 8000440e <begin_op>

  if((ip = namei(path)) == 0){
    80004f70:	854a                	mv	a0,s2
    80004f72:	fffff097          	auipc	ra,0xfffff
    80004f76:	27c080e7          	jalr	636(ra) # 800041ee <namei>
    80004f7a:	c93d                	beqz	a0,80004ff0 <exec+0xc4>
    80004f7c:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f7e:	fffff097          	auipc	ra,0xfffff
    80004f82:	aba080e7          	jalr	-1350(ra) # 80003a38 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f86:	04000713          	li	a4,64
    80004f8a:	4681                	li	a3,0
    80004f8c:	e4840613          	addi	a2,s0,-440
    80004f90:	4581                	li	a1,0
    80004f92:	8556                	mv	a0,s5
    80004f94:	fffff097          	auipc	ra,0xfffff
    80004f98:	d58080e7          	jalr	-680(ra) # 80003cec <readi>
    80004f9c:	04000793          	li	a5,64
    80004fa0:	00f51a63          	bne	a0,a5,80004fb4 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004fa4:	e4842703          	lw	a4,-440(s0)
    80004fa8:	464c47b7          	lui	a5,0x464c4
    80004fac:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004fb0:	04f70663          	beq	a4,a5,80004ffc <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004fb4:	8556                	mv	a0,s5
    80004fb6:	fffff097          	auipc	ra,0xfffff
    80004fba:	ce4080e7          	jalr	-796(ra) # 80003c9a <iunlockput>
    end_op();
    80004fbe:	fffff097          	auipc	ra,0xfffff
    80004fc2:	4d0080e7          	jalr	1232(ra) # 8000448e <end_op>
  }
  return -1;
    80004fc6:	557d                	li	a0,-1
}
    80004fc8:	21813083          	ld	ra,536(sp)
    80004fcc:	21013403          	ld	s0,528(sp)
    80004fd0:	20813483          	ld	s1,520(sp)
    80004fd4:	20013903          	ld	s2,512(sp)
    80004fd8:	79fe                	ld	s3,504(sp)
    80004fda:	7a5e                	ld	s4,496(sp)
    80004fdc:	7abe                	ld	s5,488(sp)
    80004fde:	7b1e                	ld	s6,480(sp)
    80004fe0:	6bfe                	ld	s7,472(sp)
    80004fe2:	6c5e                	ld	s8,464(sp)
    80004fe4:	6cbe                	ld	s9,456(sp)
    80004fe6:	6d1e                	ld	s10,448(sp)
    80004fe8:	7dfa                	ld	s11,440(sp)
    80004fea:	22010113          	addi	sp,sp,544
    80004fee:	8082                	ret
    end_op();
    80004ff0:	fffff097          	auipc	ra,0xfffff
    80004ff4:	49e080e7          	jalr	1182(ra) # 8000448e <end_op>
    return -1;
    80004ff8:	557d                	li	a0,-1
    80004ffa:	b7f9                	j	80004fc8 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ffc:	8526                	mv	a0,s1
    80004ffe:	ffffd097          	auipc	ra,0xffffd
    80005002:	a44080e7          	jalr	-1468(ra) # 80001a42 <proc_pagetable>
    80005006:	8b2a                	mv	s6,a0
    80005008:	d555                	beqz	a0,80004fb4 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000500a:	e6842783          	lw	a5,-408(s0)
    8000500e:	e8045703          	lhu	a4,-384(s0)
    80005012:	c735                	beqz	a4,8000507e <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005014:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005016:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000501a:	6a05                	lui	s4,0x1
    8000501c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005020:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005024:	6d85                	lui	s11,0x1
    80005026:	7d7d                	lui	s10,0xfffff
    80005028:	ac1d                	j	8000525e <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000502a:	00004517          	auipc	a0,0x4
    8000502e:	87650513          	addi	a0,a0,-1930 # 800088a0 <syscalls+0x290>
    80005032:	ffffb097          	auipc	ra,0xffffb
    80005036:	4f8080e7          	jalr	1272(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000503a:	874a                	mv	a4,s2
    8000503c:	009c86bb          	addw	a3,s9,s1
    80005040:	4581                	li	a1,0
    80005042:	8556                	mv	a0,s5
    80005044:	fffff097          	auipc	ra,0xfffff
    80005048:	ca8080e7          	jalr	-856(ra) # 80003cec <readi>
    8000504c:	2501                	sext.w	a0,a0
    8000504e:	1aa91863          	bne	s2,a0,800051fe <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80005052:	009d84bb          	addw	s1,s11,s1
    80005056:	013d09bb          	addw	s3,s10,s3
    8000505a:	1f74f263          	bgeu	s1,s7,8000523e <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    8000505e:	02049593          	slli	a1,s1,0x20
    80005062:	9181                	srli	a1,a1,0x20
    80005064:	95e2                	add	a1,a1,s8
    80005066:	855a                	mv	a0,s6
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	fe4080e7          	jalr	-28(ra) # 8000104c <walkaddr>
    80005070:	862a                	mv	a2,a0
    if(pa == 0)
    80005072:	dd45                	beqz	a0,8000502a <exec+0xfe>
      n = PGSIZE;
    80005074:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005076:	fd49f2e3          	bgeu	s3,s4,8000503a <exec+0x10e>
      n = sz - i;
    8000507a:	894e                	mv	s2,s3
    8000507c:	bf7d                	j	8000503a <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000507e:	4481                	li	s1,0
  iunlockput(ip);
    80005080:	8556                	mv	a0,s5
    80005082:	fffff097          	auipc	ra,0xfffff
    80005086:	c18080e7          	jalr	-1000(ra) # 80003c9a <iunlockput>
  end_op();
    8000508a:	fffff097          	auipc	ra,0xfffff
    8000508e:	404080e7          	jalr	1028(ra) # 8000448e <end_op>
  p = myproc();
    80005092:	ffffd097          	auipc	ra,0xffffd
    80005096:	8ec080e7          	jalr	-1812(ra) # 8000197e <myproc>
    8000509a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000509c:	06053d03          	ld	s10,96(a0)
  sz = PGROUNDUP(sz);
    800050a0:	6785                	lui	a5,0x1
    800050a2:	17fd                	addi	a5,a5,-1
    800050a4:	94be                	add	s1,s1,a5
    800050a6:	77fd                	lui	a5,0xfffff
    800050a8:	8fe5                	and	a5,a5,s1
    800050aa:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800050ae:	6609                	lui	a2,0x2
    800050b0:	963e                	add	a2,a2,a5
    800050b2:	85be                	mv	a1,a5
    800050b4:	855a                	mv	a0,s6
    800050b6:	ffffc097          	auipc	ra,0xffffc
    800050ba:	338080e7          	jalr	824(ra) # 800013ee <uvmalloc>
    800050be:	8c2a                	mv	s8,a0
  ip = 0;
    800050c0:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800050c2:	12050e63          	beqz	a0,800051fe <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    800050c6:	75f9                	lui	a1,0xffffe
    800050c8:	95aa                	add	a1,a1,a0
    800050ca:	855a                	mv	a0,s6
    800050cc:	ffffc097          	auipc	ra,0xffffc
    800050d0:	540080e7          	jalr	1344(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    800050d4:	7afd                	lui	s5,0xfffff
    800050d6:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800050d8:	df043783          	ld	a5,-528(s0)
    800050dc:	6388                	ld	a0,0(a5)
    800050de:	c925                	beqz	a0,8000514e <exec+0x222>
    800050e0:	e8840993          	addi	s3,s0,-376
    800050e4:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    800050e8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050ea:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800050ec:	ffffc097          	auipc	ra,0xffffc
    800050f0:	d56080e7          	jalr	-682(ra) # 80000e42 <strlen>
    800050f4:	0015079b          	addiw	a5,a0,1
    800050f8:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050fc:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005100:	13596363          	bltu	s2,s5,80005226 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005104:	df043d83          	ld	s11,-528(s0)
    80005108:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000510c:	8552                	mv	a0,s4
    8000510e:	ffffc097          	auipc	ra,0xffffc
    80005112:	d34080e7          	jalr	-716(ra) # 80000e42 <strlen>
    80005116:	0015069b          	addiw	a3,a0,1
    8000511a:	8652                	mv	a2,s4
    8000511c:	85ca                	mv	a1,s2
    8000511e:	855a                	mv	a0,s6
    80005120:	ffffc097          	auipc	ra,0xffffc
    80005124:	51e080e7          	jalr	1310(ra) # 8000163e <copyout>
    80005128:	10054363          	bltz	a0,8000522e <exec+0x302>
    ustack[argc] = sp;
    8000512c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005130:	0485                	addi	s1,s1,1
    80005132:	008d8793          	addi	a5,s11,8
    80005136:	def43823          	sd	a5,-528(s0)
    8000513a:	008db503          	ld	a0,8(s11)
    8000513e:	c911                	beqz	a0,80005152 <exec+0x226>
    if(argc >= MAXARG)
    80005140:	09a1                	addi	s3,s3,8
    80005142:	fb3c95e3          	bne	s9,s3,800050ec <exec+0x1c0>
  sz = sz1;
    80005146:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000514a:	4a81                	li	s5,0
    8000514c:	a84d                	j	800051fe <exec+0x2d2>
  sp = sz;
    8000514e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005150:	4481                	li	s1,0
  ustack[argc] = 0;
    80005152:	00349793          	slli	a5,s1,0x3
    80005156:	f9040713          	addi	a4,s0,-112
    8000515a:	97ba                	add	a5,a5,a4
    8000515c:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80005160:	00148693          	addi	a3,s1,1
    80005164:	068e                	slli	a3,a3,0x3
    80005166:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000516a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000516e:	01597663          	bgeu	s2,s5,8000517a <exec+0x24e>
  sz = sz1;
    80005172:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005176:	4a81                	li	s5,0
    80005178:	a059                	j	800051fe <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000517a:	e8840613          	addi	a2,s0,-376
    8000517e:	85ca                	mv	a1,s2
    80005180:	855a                	mv	a0,s6
    80005182:	ffffc097          	auipc	ra,0xffffc
    80005186:	4bc080e7          	jalr	1212(ra) # 8000163e <copyout>
    8000518a:	0a054663          	bltz	a0,80005236 <exec+0x30a>
  p->trapframe->a1 = sp;
    8000518e:	070bb783          	ld	a5,112(s7) # 1070 <_entry-0x7fffef90>
    80005192:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005196:	de843783          	ld	a5,-536(s0)
    8000519a:	0007c703          	lbu	a4,0(a5)
    8000519e:	cf11                	beqz	a4,800051ba <exec+0x28e>
    800051a0:	0785                	addi	a5,a5,1
    if(*s == '/')
    800051a2:	02f00693          	li	a3,47
    800051a6:	a039                	j	800051b4 <exec+0x288>
      last = s+1;
    800051a8:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800051ac:	0785                	addi	a5,a5,1
    800051ae:	fff7c703          	lbu	a4,-1(a5)
    800051b2:	c701                	beqz	a4,800051ba <exec+0x28e>
    if(*s == '/')
    800051b4:	fed71ce3          	bne	a4,a3,800051ac <exec+0x280>
    800051b8:	bfc5                	j	800051a8 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    800051ba:	4641                	li	a2,16
    800051bc:	de843583          	ld	a1,-536(s0)
    800051c0:	170b8513          	addi	a0,s7,368
    800051c4:	ffffc097          	auipc	ra,0xffffc
    800051c8:	c4c080e7          	jalr	-948(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    800051cc:	068bb503          	ld	a0,104(s7)
  p->pagetable = pagetable;
    800051d0:	076bb423          	sd	s6,104(s7)
  p->sz = sz;
    800051d4:	078bb023          	sd	s8,96(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051d8:	070bb783          	ld	a5,112(s7)
    800051dc:	e6043703          	ld	a4,-416(s0)
    800051e0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051e2:	070bb783          	ld	a5,112(s7)
    800051e6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051ea:	85ea                	mv	a1,s10
    800051ec:	ffffd097          	auipc	ra,0xffffd
    800051f0:	8f2080e7          	jalr	-1806(ra) # 80001ade <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051f4:	0004851b          	sext.w	a0,s1
    800051f8:	bbc1                	j	80004fc8 <exec+0x9c>
    800051fa:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800051fe:	df843583          	ld	a1,-520(s0)
    80005202:	855a                	mv	a0,s6
    80005204:	ffffd097          	auipc	ra,0xffffd
    80005208:	8da080e7          	jalr	-1830(ra) # 80001ade <proc_freepagetable>
  if(ip){
    8000520c:	da0a94e3          	bnez	s5,80004fb4 <exec+0x88>
  return -1;
    80005210:	557d                	li	a0,-1
    80005212:	bb5d                	j	80004fc8 <exec+0x9c>
    80005214:	de943c23          	sd	s1,-520(s0)
    80005218:	b7dd                	j	800051fe <exec+0x2d2>
    8000521a:	de943c23          	sd	s1,-520(s0)
    8000521e:	b7c5                	j	800051fe <exec+0x2d2>
    80005220:	de943c23          	sd	s1,-520(s0)
    80005224:	bfe9                	j	800051fe <exec+0x2d2>
  sz = sz1;
    80005226:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000522a:	4a81                	li	s5,0
    8000522c:	bfc9                	j	800051fe <exec+0x2d2>
  sz = sz1;
    8000522e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005232:	4a81                	li	s5,0
    80005234:	b7e9                	j	800051fe <exec+0x2d2>
  sz = sz1;
    80005236:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000523a:	4a81                	li	s5,0
    8000523c:	b7c9                	j	800051fe <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000523e:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005242:	e0843783          	ld	a5,-504(s0)
    80005246:	0017869b          	addiw	a3,a5,1
    8000524a:	e0d43423          	sd	a3,-504(s0)
    8000524e:	e0043783          	ld	a5,-512(s0)
    80005252:	0387879b          	addiw	a5,a5,56
    80005256:	e8045703          	lhu	a4,-384(s0)
    8000525a:	e2e6d3e3          	bge	a3,a4,80005080 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000525e:	2781                	sext.w	a5,a5
    80005260:	e0f43023          	sd	a5,-512(s0)
    80005264:	03800713          	li	a4,56
    80005268:	86be                	mv	a3,a5
    8000526a:	e1040613          	addi	a2,s0,-496
    8000526e:	4581                	li	a1,0
    80005270:	8556                	mv	a0,s5
    80005272:	fffff097          	auipc	ra,0xfffff
    80005276:	a7a080e7          	jalr	-1414(ra) # 80003cec <readi>
    8000527a:	03800793          	li	a5,56
    8000527e:	f6f51ee3          	bne	a0,a5,800051fa <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005282:	e1042783          	lw	a5,-496(s0)
    80005286:	4705                	li	a4,1
    80005288:	fae79de3          	bne	a5,a4,80005242 <exec+0x316>
    if(ph.memsz < ph.filesz)
    8000528c:	e3843603          	ld	a2,-456(s0)
    80005290:	e3043783          	ld	a5,-464(s0)
    80005294:	f8f660e3          	bltu	a2,a5,80005214 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005298:	e2043783          	ld	a5,-480(s0)
    8000529c:	963e                	add	a2,a2,a5
    8000529e:	f6f66ee3          	bltu	a2,a5,8000521a <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800052a2:	85a6                	mv	a1,s1
    800052a4:	855a                	mv	a0,s6
    800052a6:	ffffc097          	auipc	ra,0xffffc
    800052aa:	148080e7          	jalr	328(ra) # 800013ee <uvmalloc>
    800052ae:	dea43c23          	sd	a0,-520(s0)
    800052b2:	d53d                	beqz	a0,80005220 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    800052b4:	e2043c03          	ld	s8,-480(s0)
    800052b8:	de043783          	ld	a5,-544(s0)
    800052bc:	00fc77b3          	and	a5,s8,a5
    800052c0:	ff9d                	bnez	a5,800051fe <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800052c2:	e1842c83          	lw	s9,-488(s0)
    800052c6:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800052ca:	f60b8ae3          	beqz	s7,8000523e <exec+0x312>
    800052ce:	89de                	mv	s3,s7
    800052d0:	4481                	li	s1,0
    800052d2:	b371                	j	8000505e <exec+0x132>

00000000800052d4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052d4:	7179                	addi	sp,sp,-48
    800052d6:	f406                	sd	ra,40(sp)
    800052d8:	f022                	sd	s0,32(sp)
    800052da:	ec26                	sd	s1,24(sp)
    800052dc:	e84a                	sd	s2,16(sp)
    800052de:	1800                	addi	s0,sp,48
    800052e0:	892e                	mv	s2,a1
    800052e2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800052e4:	fdc40593          	addi	a1,s0,-36
    800052e8:	ffffe097          	auipc	ra,0xffffe
    800052ec:	a54080e7          	jalr	-1452(ra) # 80002d3c <argint>
    800052f0:	04054063          	bltz	a0,80005330 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052f4:	fdc42703          	lw	a4,-36(s0)
    800052f8:	47bd                	li	a5,15
    800052fa:	02e7ed63          	bltu	a5,a4,80005334 <argfd+0x60>
    800052fe:	ffffc097          	auipc	ra,0xffffc
    80005302:	680080e7          	jalr	1664(ra) # 8000197e <myproc>
    80005306:	fdc42703          	lw	a4,-36(s0)
    8000530a:	01c70793          	addi	a5,a4,28
    8000530e:	078e                	slli	a5,a5,0x3
    80005310:	953e                	add	a0,a0,a5
    80005312:	651c                	ld	a5,8(a0)
    80005314:	c395                	beqz	a5,80005338 <argfd+0x64>
    return -1;
  if(pfd)
    80005316:	00090463          	beqz	s2,8000531e <argfd+0x4a>
    *pfd = fd;
    8000531a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000531e:	4501                	li	a0,0
  if(pf)
    80005320:	c091                	beqz	s1,80005324 <argfd+0x50>
    *pf = f;
    80005322:	e09c                	sd	a5,0(s1)
}
    80005324:	70a2                	ld	ra,40(sp)
    80005326:	7402                	ld	s0,32(sp)
    80005328:	64e2                	ld	s1,24(sp)
    8000532a:	6942                	ld	s2,16(sp)
    8000532c:	6145                	addi	sp,sp,48
    8000532e:	8082                	ret
    return -1;
    80005330:	557d                	li	a0,-1
    80005332:	bfcd                	j	80005324 <argfd+0x50>
    return -1;
    80005334:	557d                	li	a0,-1
    80005336:	b7fd                	j	80005324 <argfd+0x50>
    80005338:	557d                	li	a0,-1
    8000533a:	b7ed                	j	80005324 <argfd+0x50>

000000008000533c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000533c:	1101                	addi	sp,sp,-32
    8000533e:	ec06                	sd	ra,24(sp)
    80005340:	e822                	sd	s0,16(sp)
    80005342:	e426                	sd	s1,8(sp)
    80005344:	1000                	addi	s0,sp,32
    80005346:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005348:	ffffc097          	auipc	ra,0xffffc
    8000534c:	636080e7          	jalr	1590(ra) # 8000197e <myproc>
    80005350:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005352:	0e850793          	addi	a5,a0,232
    80005356:	4501                	li	a0,0
    80005358:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000535a:	6398                	ld	a4,0(a5)
    8000535c:	cb19                	beqz	a4,80005372 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000535e:	2505                	addiw	a0,a0,1
    80005360:	07a1                	addi	a5,a5,8
    80005362:	fed51ce3          	bne	a0,a3,8000535a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005366:	557d                	li	a0,-1
}
    80005368:	60e2                	ld	ra,24(sp)
    8000536a:	6442                	ld	s0,16(sp)
    8000536c:	64a2                	ld	s1,8(sp)
    8000536e:	6105                	addi	sp,sp,32
    80005370:	8082                	ret
      p->ofile[fd] = f;
    80005372:	01c50793          	addi	a5,a0,28
    80005376:	078e                	slli	a5,a5,0x3
    80005378:	963e                	add	a2,a2,a5
    8000537a:	e604                	sd	s1,8(a2)
      return fd;
    8000537c:	b7f5                	j	80005368 <fdalloc+0x2c>

000000008000537e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000537e:	715d                	addi	sp,sp,-80
    80005380:	e486                	sd	ra,72(sp)
    80005382:	e0a2                	sd	s0,64(sp)
    80005384:	fc26                	sd	s1,56(sp)
    80005386:	f84a                	sd	s2,48(sp)
    80005388:	f44e                	sd	s3,40(sp)
    8000538a:	f052                	sd	s4,32(sp)
    8000538c:	ec56                	sd	s5,24(sp)
    8000538e:	0880                	addi	s0,sp,80
    80005390:	89ae                	mv	s3,a1
    80005392:	8ab2                	mv	s5,a2
    80005394:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005396:	fb040593          	addi	a1,s0,-80
    8000539a:	fffff097          	auipc	ra,0xfffff
    8000539e:	e72080e7          	jalr	-398(ra) # 8000420c <nameiparent>
    800053a2:	892a                	mv	s2,a0
    800053a4:	12050e63          	beqz	a0,800054e0 <create+0x162>
    return 0;

  ilock(dp);
    800053a8:	ffffe097          	auipc	ra,0xffffe
    800053ac:	690080e7          	jalr	1680(ra) # 80003a38 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053b0:	4601                	li	a2,0
    800053b2:	fb040593          	addi	a1,s0,-80
    800053b6:	854a                	mv	a0,s2
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	b64080e7          	jalr	-1180(ra) # 80003f1c <dirlookup>
    800053c0:	84aa                	mv	s1,a0
    800053c2:	c921                	beqz	a0,80005412 <create+0x94>
    iunlockput(dp);
    800053c4:	854a                	mv	a0,s2
    800053c6:	fffff097          	auipc	ra,0xfffff
    800053ca:	8d4080e7          	jalr	-1836(ra) # 80003c9a <iunlockput>
    ilock(ip);
    800053ce:	8526                	mv	a0,s1
    800053d0:	ffffe097          	auipc	ra,0xffffe
    800053d4:	668080e7          	jalr	1640(ra) # 80003a38 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053d8:	2981                	sext.w	s3,s3
    800053da:	4789                	li	a5,2
    800053dc:	02f99463          	bne	s3,a5,80005404 <create+0x86>
    800053e0:	0444d783          	lhu	a5,68(s1)
    800053e4:	37f9                	addiw	a5,a5,-2
    800053e6:	17c2                	slli	a5,a5,0x30
    800053e8:	93c1                	srli	a5,a5,0x30
    800053ea:	4705                	li	a4,1
    800053ec:	00f76c63          	bltu	a4,a5,80005404 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800053f0:	8526                	mv	a0,s1
    800053f2:	60a6                	ld	ra,72(sp)
    800053f4:	6406                	ld	s0,64(sp)
    800053f6:	74e2                	ld	s1,56(sp)
    800053f8:	7942                	ld	s2,48(sp)
    800053fa:	79a2                	ld	s3,40(sp)
    800053fc:	7a02                	ld	s4,32(sp)
    800053fe:	6ae2                	ld	s5,24(sp)
    80005400:	6161                	addi	sp,sp,80
    80005402:	8082                	ret
    iunlockput(ip);
    80005404:	8526                	mv	a0,s1
    80005406:	fffff097          	auipc	ra,0xfffff
    8000540a:	894080e7          	jalr	-1900(ra) # 80003c9a <iunlockput>
    return 0;
    8000540e:	4481                	li	s1,0
    80005410:	b7c5                	j	800053f0 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005412:	85ce                	mv	a1,s3
    80005414:	00092503          	lw	a0,0(s2)
    80005418:	ffffe097          	auipc	ra,0xffffe
    8000541c:	488080e7          	jalr	1160(ra) # 800038a0 <ialloc>
    80005420:	84aa                	mv	s1,a0
    80005422:	c521                	beqz	a0,8000546a <create+0xec>
  ilock(ip);
    80005424:	ffffe097          	auipc	ra,0xffffe
    80005428:	614080e7          	jalr	1556(ra) # 80003a38 <ilock>
  ip->major = major;
    8000542c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005430:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005434:	4a05                	li	s4,1
    80005436:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000543a:	8526                	mv	a0,s1
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	532080e7          	jalr	1330(ra) # 8000396e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005444:	2981                	sext.w	s3,s3
    80005446:	03498a63          	beq	s3,s4,8000547a <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000544a:	40d0                	lw	a2,4(s1)
    8000544c:	fb040593          	addi	a1,s0,-80
    80005450:	854a                	mv	a0,s2
    80005452:	fffff097          	auipc	ra,0xfffff
    80005456:	cda080e7          	jalr	-806(ra) # 8000412c <dirlink>
    8000545a:	06054b63          	bltz	a0,800054d0 <create+0x152>
  iunlockput(dp);
    8000545e:	854a                	mv	a0,s2
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	83a080e7          	jalr	-1990(ra) # 80003c9a <iunlockput>
  return ip;
    80005468:	b761                	j	800053f0 <create+0x72>
    panic("create: ialloc");
    8000546a:	00003517          	auipc	a0,0x3
    8000546e:	45650513          	addi	a0,a0,1110 # 800088c0 <syscalls+0x2b0>
    80005472:	ffffb097          	auipc	ra,0xffffb
    80005476:	0b8080e7          	jalr	184(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000547a:	04a95783          	lhu	a5,74(s2)
    8000547e:	2785                	addiw	a5,a5,1
    80005480:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005484:	854a                	mv	a0,s2
    80005486:	ffffe097          	auipc	ra,0xffffe
    8000548a:	4e8080e7          	jalr	1256(ra) # 8000396e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000548e:	40d0                	lw	a2,4(s1)
    80005490:	00003597          	auipc	a1,0x3
    80005494:	44058593          	addi	a1,a1,1088 # 800088d0 <syscalls+0x2c0>
    80005498:	8526                	mv	a0,s1
    8000549a:	fffff097          	auipc	ra,0xfffff
    8000549e:	c92080e7          	jalr	-878(ra) # 8000412c <dirlink>
    800054a2:	00054f63          	bltz	a0,800054c0 <create+0x142>
    800054a6:	00492603          	lw	a2,4(s2)
    800054aa:	00003597          	auipc	a1,0x3
    800054ae:	42e58593          	addi	a1,a1,1070 # 800088d8 <syscalls+0x2c8>
    800054b2:	8526                	mv	a0,s1
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	c78080e7          	jalr	-904(ra) # 8000412c <dirlink>
    800054bc:	f80557e3          	bgez	a0,8000544a <create+0xcc>
      panic("create dots");
    800054c0:	00003517          	auipc	a0,0x3
    800054c4:	42050513          	addi	a0,a0,1056 # 800088e0 <syscalls+0x2d0>
    800054c8:	ffffb097          	auipc	ra,0xffffb
    800054cc:	062080e7          	jalr	98(ra) # 8000052a <panic>
    panic("create: dirlink");
    800054d0:	00003517          	auipc	a0,0x3
    800054d4:	42050513          	addi	a0,a0,1056 # 800088f0 <syscalls+0x2e0>
    800054d8:	ffffb097          	auipc	ra,0xffffb
    800054dc:	052080e7          	jalr	82(ra) # 8000052a <panic>
    return 0;
    800054e0:	84aa                	mv	s1,a0
    800054e2:	b739                	j	800053f0 <create+0x72>

00000000800054e4 <sys_dup>:
{
    800054e4:	7179                	addi	sp,sp,-48
    800054e6:	f406                	sd	ra,40(sp)
    800054e8:	f022                	sd	s0,32(sp)
    800054ea:	ec26                	sd	s1,24(sp)
    800054ec:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054ee:	fd840613          	addi	a2,s0,-40
    800054f2:	4581                	li	a1,0
    800054f4:	4501                	li	a0,0
    800054f6:	00000097          	auipc	ra,0x0
    800054fa:	dde080e7          	jalr	-546(ra) # 800052d4 <argfd>
    return -1;
    800054fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005500:	02054363          	bltz	a0,80005526 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005504:	fd843503          	ld	a0,-40(s0)
    80005508:	00000097          	auipc	ra,0x0
    8000550c:	e34080e7          	jalr	-460(ra) # 8000533c <fdalloc>
    80005510:	84aa                	mv	s1,a0
    return -1;
    80005512:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005514:	00054963          	bltz	a0,80005526 <sys_dup+0x42>
  filedup(f);
    80005518:	fd843503          	ld	a0,-40(s0)
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	36c080e7          	jalr	876(ra) # 80004888 <filedup>
  return fd;
    80005524:	87a6                	mv	a5,s1
}
    80005526:	853e                	mv	a0,a5
    80005528:	70a2                	ld	ra,40(sp)
    8000552a:	7402                	ld	s0,32(sp)
    8000552c:	64e2                	ld	s1,24(sp)
    8000552e:	6145                	addi	sp,sp,48
    80005530:	8082                	ret

0000000080005532 <sys_read>:
{
    80005532:	7179                	addi	sp,sp,-48
    80005534:	f406                	sd	ra,40(sp)
    80005536:	f022                	sd	s0,32(sp)
    80005538:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000553a:	fe840613          	addi	a2,s0,-24
    8000553e:	4581                	li	a1,0
    80005540:	4501                	li	a0,0
    80005542:	00000097          	auipc	ra,0x0
    80005546:	d92080e7          	jalr	-622(ra) # 800052d4 <argfd>
    return -1;
    8000554a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000554c:	04054163          	bltz	a0,8000558e <sys_read+0x5c>
    80005550:	fe440593          	addi	a1,s0,-28
    80005554:	4509                	li	a0,2
    80005556:	ffffd097          	auipc	ra,0xffffd
    8000555a:	7e6080e7          	jalr	2022(ra) # 80002d3c <argint>
    return -1;
    8000555e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005560:	02054763          	bltz	a0,8000558e <sys_read+0x5c>
    80005564:	fd840593          	addi	a1,s0,-40
    80005568:	4505                	li	a0,1
    8000556a:	ffffd097          	auipc	ra,0xffffd
    8000556e:	7f4080e7          	jalr	2036(ra) # 80002d5e <argaddr>
    return -1;
    80005572:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005574:	00054d63          	bltz	a0,8000558e <sys_read+0x5c>
  return fileread(f, p, n);
    80005578:	fe442603          	lw	a2,-28(s0)
    8000557c:	fd843583          	ld	a1,-40(s0)
    80005580:	fe843503          	ld	a0,-24(s0)
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	490080e7          	jalr	1168(ra) # 80004a14 <fileread>
    8000558c:	87aa                	mv	a5,a0
}
    8000558e:	853e                	mv	a0,a5
    80005590:	70a2                	ld	ra,40(sp)
    80005592:	7402                	ld	s0,32(sp)
    80005594:	6145                	addi	sp,sp,48
    80005596:	8082                	ret

0000000080005598 <sys_write>:
{
    80005598:	7179                	addi	sp,sp,-48
    8000559a:	f406                	sd	ra,40(sp)
    8000559c:	f022                	sd	s0,32(sp)
    8000559e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055a0:	fe840613          	addi	a2,s0,-24
    800055a4:	4581                	li	a1,0
    800055a6:	4501                	li	a0,0
    800055a8:	00000097          	auipc	ra,0x0
    800055ac:	d2c080e7          	jalr	-724(ra) # 800052d4 <argfd>
    return -1;
    800055b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055b2:	04054163          	bltz	a0,800055f4 <sys_write+0x5c>
    800055b6:	fe440593          	addi	a1,s0,-28
    800055ba:	4509                	li	a0,2
    800055bc:	ffffd097          	auipc	ra,0xffffd
    800055c0:	780080e7          	jalr	1920(ra) # 80002d3c <argint>
    return -1;
    800055c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055c6:	02054763          	bltz	a0,800055f4 <sys_write+0x5c>
    800055ca:	fd840593          	addi	a1,s0,-40
    800055ce:	4505                	li	a0,1
    800055d0:	ffffd097          	auipc	ra,0xffffd
    800055d4:	78e080e7          	jalr	1934(ra) # 80002d5e <argaddr>
    return -1;
    800055d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055da:	00054d63          	bltz	a0,800055f4 <sys_write+0x5c>
  return filewrite(f, p, n);
    800055de:	fe442603          	lw	a2,-28(s0)
    800055e2:	fd843583          	ld	a1,-40(s0)
    800055e6:	fe843503          	ld	a0,-24(s0)
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	4ec080e7          	jalr	1260(ra) # 80004ad6 <filewrite>
    800055f2:	87aa                	mv	a5,a0
}
    800055f4:	853e                	mv	a0,a5
    800055f6:	70a2                	ld	ra,40(sp)
    800055f8:	7402                	ld	s0,32(sp)
    800055fa:	6145                	addi	sp,sp,48
    800055fc:	8082                	ret

00000000800055fe <sys_close>:
{
    800055fe:	1101                	addi	sp,sp,-32
    80005600:	ec06                	sd	ra,24(sp)
    80005602:	e822                	sd	s0,16(sp)
    80005604:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005606:	fe040613          	addi	a2,s0,-32
    8000560a:	fec40593          	addi	a1,s0,-20
    8000560e:	4501                	li	a0,0
    80005610:	00000097          	auipc	ra,0x0
    80005614:	cc4080e7          	jalr	-828(ra) # 800052d4 <argfd>
    return -1;
    80005618:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000561a:	02054463          	bltz	a0,80005642 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000561e:	ffffc097          	auipc	ra,0xffffc
    80005622:	360080e7          	jalr	864(ra) # 8000197e <myproc>
    80005626:	fec42783          	lw	a5,-20(s0)
    8000562a:	07f1                	addi	a5,a5,28
    8000562c:	078e                	slli	a5,a5,0x3
    8000562e:	97aa                	add	a5,a5,a0
    80005630:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005634:	fe043503          	ld	a0,-32(s0)
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	2a2080e7          	jalr	674(ra) # 800048da <fileclose>
  return 0;
    80005640:	4781                	li	a5,0
}
    80005642:	853e                	mv	a0,a5
    80005644:	60e2                	ld	ra,24(sp)
    80005646:	6442                	ld	s0,16(sp)
    80005648:	6105                	addi	sp,sp,32
    8000564a:	8082                	ret

000000008000564c <sys_fstat>:
{
    8000564c:	1101                	addi	sp,sp,-32
    8000564e:	ec06                	sd	ra,24(sp)
    80005650:	e822                	sd	s0,16(sp)
    80005652:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005654:	fe840613          	addi	a2,s0,-24
    80005658:	4581                	li	a1,0
    8000565a:	4501                	li	a0,0
    8000565c:	00000097          	auipc	ra,0x0
    80005660:	c78080e7          	jalr	-904(ra) # 800052d4 <argfd>
    return -1;
    80005664:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005666:	02054563          	bltz	a0,80005690 <sys_fstat+0x44>
    8000566a:	fe040593          	addi	a1,s0,-32
    8000566e:	4505                	li	a0,1
    80005670:	ffffd097          	auipc	ra,0xffffd
    80005674:	6ee080e7          	jalr	1774(ra) # 80002d5e <argaddr>
    return -1;
    80005678:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000567a:	00054b63          	bltz	a0,80005690 <sys_fstat+0x44>
  return filestat(f, st);
    8000567e:	fe043583          	ld	a1,-32(s0)
    80005682:	fe843503          	ld	a0,-24(s0)
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	31c080e7          	jalr	796(ra) # 800049a2 <filestat>
    8000568e:	87aa                	mv	a5,a0
}
    80005690:	853e                	mv	a0,a5
    80005692:	60e2                	ld	ra,24(sp)
    80005694:	6442                	ld	s0,16(sp)
    80005696:	6105                	addi	sp,sp,32
    80005698:	8082                	ret

000000008000569a <sys_link>:
{
    8000569a:	7169                	addi	sp,sp,-304
    8000569c:	f606                	sd	ra,296(sp)
    8000569e:	f222                	sd	s0,288(sp)
    800056a0:	ee26                	sd	s1,280(sp)
    800056a2:	ea4a                	sd	s2,272(sp)
    800056a4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056a6:	08000613          	li	a2,128
    800056aa:	ed040593          	addi	a1,s0,-304
    800056ae:	4501                	li	a0,0
    800056b0:	ffffd097          	auipc	ra,0xffffd
    800056b4:	6d0080e7          	jalr	1744(ra) # 80002d80 <argstr>
    return -1;
    800056b8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056ba:	10054e63          	bltz	a0,800057d6 <sys_link+0x13c>
    800056be:	08000613          	li	a2,128
    800056c2:	f5040593          	addi	a1,s0,-176
    800056c6:	4505                	li	a0,1
    800056c8:	ffffd097          	auipc	ra,0xffffd
    800056cc:	6b8080e7          	jalr	1720(ra) # 80002d80 <argstr>
    return -1;
    800056d0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056d2:	10054263          	bltz	a0,800057d6 <sys_link+0x13c>
  begin_op();
    800056d6:	fffff097          	auipc	ra,0xfffff
    800056da:	d38080e7          	jalr	-712(ra) # 8000440e <begin_op>
  if((ip = namei(old)) == 0){
    800056de:	ed040513          	addi	a0,s0,-304
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	b0c080e7          	jalr	-1268(ra) # 800041ee <namei>
    800056ea:	84aa                	mv	s1,a0
    800056ec:	c551                	beqz	a0,80005778 <sys_link+0xde>
  ilock(ip);
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	34a080e7          	jalr	842(ra) # 80003a38 <ilock>
  if(ip->type == T_DIR){
    800056f6:	04449703          	lh	a4,68(s1)
    800056fa:	4785                	li	a5,1
    800056fc:	08f70463          	beq	a4,a5,80005784 <sys_link+0xea>
  ip->nlink++;
    80005700:	04a4d783          	lhu	a5,74(s1)
    80005704:	2785                	addiw	a5,a5,1
    80005706:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000570a:	8526                	mv	a0,s1
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	262080e7          	jalr	610(ra) # 8000396e <iupdate>
  iunlock(ip);
    80005714:	8526                	mv	a0,s1
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	3e4080e7          	jalr	996(ra) # 80003afa <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000571e:	fd040593          	addi	a1,s0,-48
    80005722:	f5040513          	addi	a0,s0,-176
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	ae6080e7          	jalr	-1306(ra) # 8000420c <nameiparent>
    8000572e:	892a                	mv	s2,a0
    80005730:	c935                	beqz	a0,800057a4 <sys_link+0x10a>
  ilock(dp);
    80005732:	ffffe097          	auipc	ra,0xffffe
    80005736:	306080e7          	jalr	774(ra) # 80003a38 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000573a:	00092703          	lw	a4,0(s2)
    8000573e:	409c                	lw	a5,0(s1)
    80005740:	04f71d63          	bne	a4,a5,8000579a <sys_link+0x100>
    80005744:	40d0                	lw	a2,4(s1)
    80005746:	fd040593          	addi	a1,s0,-48
    8000574a:	854a                	mv	a0,s2
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	9e0080e7          	jalr	-1568(ra) # 8000412c <dirlink>
    80005754:	04054363          	bltz	a0,8000579a <sys_link+0x100>
  iunlockput(dp);
    80005758:	854a                	mv	a0,s2
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	540080e7          	jalr	1344(ra) # 80003c9a <iunlockput>
  iput(ip);
    80005762:	8526                	mv	a0,s1
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	48e080e7          	jalr	1166(ra) # 80003bf2 <iput>
  end_op();
    8000576c:	fffff097          	auipc	ra,0xfffff
    80005770:	d22080e7          	jalr	-734(ra) # 8000448e <end_op>
  return 0;
    80005774:	4781                	li	a5,0
    80005776:	a085                	j	800057d6 <sys_link+0x13c>
    end_op();
    80005778:	fffff097          	auipc	ra,0xfffff
    8000577c:	d16080e7          	jalr	-746(ra) # 8000448e <end_op>
    return -1;
    80005780:	57fd                	li	a5,-1
    80005782:	a891                	j	800057d6 <sys_link+0x13c>
    iunlockput(ip);
    80005784:	8526                	mv	a0,s1
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	514080e7          	jalr	1300(ra) # 80003c9a <iunlockput>
    end_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	d00080e7          	jalr	-768(ra) # 8000448e <end_op>
    return -1;
    80005796:	57fd                	li	a5,-1
    80005798:	a83d                	j	800057d6 <sys_link+0x13c>
    iunlockput(dp);
    8000579a:	854a                	mv	a0,s2
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	4fe080e7          	jalr	1278(ra) # 80003c9a <iunlockput>
  ilock(ip);
    800057a4:	8526                	mv	a0,s1
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	292080e7          	jalr	658(ra) # 80003a38 <ilock>
  ip->nlink--;
    800057ae:	04a4d783          	lhu	a5,74(s1)
    800057b2:	37fd                	addiw	a5,a5,-1
    800057b4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057b8:	8526                	mv	a0,s1
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	1b4080e7          	jalr	436(ra) # 8000396e <iupdate>
  iunlockput(ip);
    800057c2:	8526                	mv	a0,s1
    800057c4:	ffffe097          	auipc	ra,0xffffe
    800057c8:	4d6080e7          	jalr	1238(ra) # 80003c9a <iunlockput>
  end_op();
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	cc2080e7          	jalr	-830(ra) # 8000448e <end_op>
  return -1;
    800057d4:	57fd                	li	a5,-1
}
    800057d6:	853e                	mv	a0,a5
    800057d8:	70b2                	ld	ra,296(sp)
    800057da:	7412                	ld	s0,288(sp)
    800057dc:	64f2                	ld	s1,280(sp)
    800057de:	6952                	ld	s2,272(sp)
    800057e0:	6155                	addi	sp,sp,304
    800057e2:	8082                	ret

00000000800057e4 <sys_unlink>:
{
    800057e4:	7151                	addi	sp,sp,-240
    800057e6:	f586                	sd	ra,232(sp)
    800057e8:	f1a2                	sd	s0,224(sp)
    800057ea:	eda6                	sd	s1,216(sp)
    800057ec:	e9ca                	sd	s2,208(sp)
    800057ee:	e5ce                	sd	s3,200(sp)
    800057f0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057f2:	08000613          	li	a2,128
    800057f6:	f3040593          	addi	a1,s0,-208
    800057fa:	4501                	li	a0,0
    800057fc:	ffffd097          	auipc	ra,0xffffd
    80005800:	584080e7          	jalr	1412(ra) # 80002d80 <argstr>
    80005804:	18054163          	bltz	a0,80005986 <sys_unlink+0x1a2>
  begin_op();
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	c06080e7          	jalr	-1018(ra) # 8000440e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005810:	fb040593          	addi	a1,s0,-80
    80005814:	f3040513          	addi	a0,s0,-208
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	9f4080e7          	jalr	-1548(ra) # 8000420c <nameiparent>
    80005820:	84aa                	mv	s1,a0
    80005822:	c979                	beqz	a0,800058f8 <sys_unlink+0x114>
  ilock(dp);
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	214080e7          	jalr	532(ra) # 80003a38 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000582c:	00003597          	auipc	a1,0x3
    80005830:	0a458593          	addi	a1,a1,164 # 800088d0 <syscalls+0x2c0>
    80005834:	fb040513          	addi	a0,s0,-80
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	6ca080e7          	jalr	1738(ra) # 80003f02 <namecmp>
    80005840:	14050a63          	beqz	a0,80005994 <sys_unlink+0x1b0>
    80005844:	00003597          	auipc	a1,0x3
    80005848:	09458593          	addi	a1,a1,148 # 800088d8 <syscalls+0x2c8>
    8000584c:	fb040513          	addi	a0,s0,-80
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	6b2080e7          	jalr	1714(ra) # 80003f02 <namecmp>
    80005858:	12050e63          	beqz	a0,80005994 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000585c:	f2c40613          	addi	a2,s0,-212
    80005860:	fb040593          	addi	a1,s0,-80
    80005864:	8526                	mv	a0,s1
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	6b6080e7          	jalr	1718(ra) # 80003f1c <dirlookup>
    8000586e:	892a                	mv	s2,a0
    80005870:	12050263          	beqz	a0,80005994 <sys_unlink+0x1b0>
  ilock(ip);
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	1c4080e7          	jalr	452(ra) # 80003a38 <ilock>
  if(ip->nlink < 1)
    8000587c:	04a91783          	lh	a5,74(s2)
    80005880:	08f05263          	blez	a5,80005904 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005884:	04491703          	lh	a4,68(s2)
    80005888:	4785                	li	a5,1
    8000588a:	08f70563          	beq	a4,a5,80005914 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000588e:	4641                	li	a2,16
    80005890:	4581                	li	a1,0
    80005892:	fc040513          	addi	a0,s0,-64
    80005896:	ffffb097          	auipc	ra,0xffffb
    8000589a:	428080e7          	jalr	1064(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000589e:	4741                	li	a4,16
    800058a0:	f2c42683          	lw	a3,-212(s0)
    800058a4:	fc040613          	addi	a2,s0,-64
    800058a8:	4581                	li	a1,0
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	538080e7          	jalr	1336(ra) # 80003de4 <writei>
    800058b4:	47c1                	li	a5,16
    800058b6:	0af51563          	bne	a0,a5,80005960 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058ba:	04491703          	lh	a4,68(s2)
    800058be:	4785                	li	a5,1
    800058c0:	0af70863          	beq	a4,a5,80005970 <sys_unlink+0x18c>
  iunlockput(dp);
    800058c4:	8526                	mv	a0,s1
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	3d4080e7          	jalr	980(ra) # 80003c9a <iunlockput>
  ip->nlink--;
    800058ce:	04a95783          	lhu	a5,74(s2)
    800058d2:	37fd                	addiw	a5,a5,-1
    800058d4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058d8:	854a                	mv	a0,s2
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	094080e7          	jalr	148(ra) # 8000396e <iupdate>
  iunlockput(ip);
    800058e2:	854a                	mv	a0,s2
    800058e4:	ffffe097          	auipc	ra,0xffffe
    800058e8:	3b6080e7          	jalr	950(ra) # 80003c9a <iunlockput>
  end_op();
    800058ec:	fffff097          	auipc	ra,0xfffff
    800058f0:	ba2080e7          	jalr	-1118(ra) # 8000448e <end_op>
  return 0;
    800058f4:	4501                	li	a0,0
    800058f6:	a84d                	j	800059a8 <sys_unlink+0x1c4>
    end_op();
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	b96080e7          	jalr	-1130(ra) # 8000448e <end_op>
    return -1;
    80005900:	557d                	li	a0,-1
    80005902:	a05d                	j	800059a8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005904:	00003517          	auipc	a0,0x3
    80005908:	ffc50513          	addi	a0,a0,-4 # 80008900 <syscalls+0x2f0>
    8000590c:	ffffb097          	auipc	ra,0xffffb
    80005910:	c1e080e7          	jalr	-994(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005914:	04c92703          	lw	a4,76(s2)
    80005918:	02000793          	li	a5,32
    8000591c:	f6e7f9e3          	bgeu	a5,a4,8000588e <sys_unlink+0xaa>
    80005920:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005924:	4741                	li	a4,16
    80005926:	86ce                	mv	a3,s3
    80005928:	f1840613          	addi	a2,s0,-232
    8000592c:	4581                	li	a1,0
    8000592e:	854a                	mv	a0,s2
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	3bc080e7          	jalr	956(ra) # 80003cec <readi>
    80005938:	47c1                	li	a5,16
    8000593a:	00f51b63          	bne	a0,a5,80005950 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000593e:	f1845783          	lhu	a5,-232(s0)
    80005942:	e7a1                	bnez	a5,8000598a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005944:	29c1                	addiw	s3,s3,16
    80005946:	04c92783          	lw	a5,76(s2)
    8000594a:	fcf9ede3          	bltu	s3,a5,80005924 <sys_unlink+0x140>
    8000594e:	b781                	j	8000588e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005950:	00003517          	auipc	a0,0x3
    80005954:	fc850513          	addi	a0,a0,-56 # 80008918 <syscalls+0x308>
    80005958:	ffffb097          	auipc	ra,0xffffb
    8000595c:	bd2080e7          	jalr	-1070(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005960:	00003517          	auipc	a0,0x3
    80005964:	fd050513          	addi	a0,a0,-48 # 80008930 <syscalls+0x320>
    80005968:	ffffb097          	auipc	ra,0xffffb
    8000596c:	bc2080e7          	jalr	-1086(ra) # 8000052a <panic>
    dp->nlink--;
    80005970:	04a4d783          	lhu	a5,74(s1)
    80005974:	37fd                	addiw	a5,a5,-1
    80005976:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000597a:	8526                	mv	a0,s1
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	ff2080e7          	jalr	-14(ra) # 8000396e <iupdate>
    80005984:	b781                	j	800058c4 <sys_unlink+0xe0>
    return -1;
    80005986:	557d                	li	a0,-1
    80005988:	a005                	j	800059a8 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000598a:	854a                	mv	a0,s2
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	30e080e7          	jalr	782(ra) # 80003c9a <iunlockput>
  iunlockput(dp);
    80005994:	8526                	mv	a0,s1
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	304080e7          	jalr	772(ra) # 80003c9a <iunlockput>
  end_op();
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	af0080e7          	jalr	-1296(ra) # 8000448e <end_op>
  return -1;
    800059a6:	557d                	li	a0,-1
}
    800059a8:	70ae                	ld	ra,232(sp)
    800059aa:	740e                	ld	s0,224(sp)
    800059ac:	64ee                	ld	s1,216(sp)
    800059ae:	694e                	ld	s2,208(sp)
    800059b0:	69ae                	ld	s3,200(sp)
    800059b2:	616d                	addi	sp,sp,240
    800059b4:	8082                	ret

00000000800059b6 <sys_open>:

uint64
sys_open(void)
{
    800059b6:	7131                	addi	sp,sp,-192
    800059b8:	fd06                	sd	ra,184(sp)
    800059ba:	f922                	sd	s0,176(sp)
    800059bc:	f526                	sd	s1,168(sp)
    800059be:	f14a                	sd	s2,160(sp)
    800059c0:	ed4e                	sd	s3,152(sp)
    800059c2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059c4:	08000613          	li	a2,128
    800059c8:	f5040593          	addi	a1,s0,-176
    800059cc:	4501                	li	a0,0
    800059ce:	ffffd097          	auipc	ra,0xffffd
    800059d2:	3b2080e7          	jalr	946(ra) # 80002d80 <argstr>
    return -1;
    800059d6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059d8:	0c054163          	bltz	a0,80005a9a <sys_open+0xe4>
    800059dc:	f4c40593          	addi	a1,s0,-180
    800059e0:	4505                	li	a0,1
    800059e2:	ffffd097          	auipc	ra,0xffffd
    800059e6:	35a080e7          	jalr	858(ra) # 80002d3c <argint>
    800059ea:	0a054863          	bltz	a0,80005a9a <sys_open+0xe4>

  begin_op();
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	a20080e7          	jalr	-1504(ra) # 8000440e <begin_op>

  if(omode & O_CREATE){
    800059f6:	f4c42783          	lw	a5,-180(s0)
    800059fa:	2007f793          	andi	a5,a5,512
    800059fe:	cbdd                	beqz	a5,80005ab4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a00:	4681                	li	a3,0
    80005a02:	4601                	li	a2,0
    80005a04:	4589                	li	a1,2
    80005a06:	f5040513          	addi	a0,s0,-176
    80005a0a:	00000097          	auipc	ra,0x0
    80005a0e:	974080e7          	jalr	-1676(ra) # 8000537e <create>
    80005a12:	892a                	mv	s2,a0
    if(ip == 0){
    80005a14:	c959                	beqz	a0,80005aaa <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a16:	04491703          	lh	a4,68(s2)
    80005a1a:	478d                	li	a5,3
    80005a1c:	00f71763          	bne	a4,a5,80005a2a <sys_open+0x74>
    80005a20:	04695703          	lhu	a4,70(s2)
    80005a24:	47a5                	li	a5,9
    80005a26:	0ce7ec63          	bltu	a5,a4,80005afe <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	df4080e7          	jalr	-524(ra) # 8000481e <filealloc>
    80005a32:	89aa                	mv	s3,a0
    80005a34:	10050263          	beqz	a0,80005b38 <sys_open+0x182>
    80005a38:	00000097          	auipc	ra,0x0
    80005a3c:	904080e7          	jalr	-1788(ra) # 8000533c <fdalloc>
    80005a40:	84aa                	mv	s1,a0
    80005a42:	0e054663          	bltz	a0,80005b2e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a46:	04491703          	lh	a4,68(s2)
    80005a4a:	478d                	li	a5,3
    80005a4c:	0cf70463          	beq	a4,a5,80005b14 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a50:	4789                	li	a5,2
    80005a52:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a56:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a5a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a5e:	f4c42783          	lw	a5,-180(s0)
    80005a62:	0017c713          	xori	a4,a5,1
    80005a66:	8b05                	andi	a4,a4,1
    80005a68:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a6c:	0037f713          	andi	a4,a5,3
    80005a70:	00e03733          	snez	a4,a4
    80005a74:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a78:	4007f793          	andi	a5,a5,1024
    80005a7c:	c791                	beqz	a5,80005a88 <sys_open+0xd2>
    80005a7e:	04491703          	lh	a4,68(s2)
    80005a82:	4789                	li	a5,2
    80005a84:	08f70f63          	beq	a4,a5,80005b22 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a88:	854a                	mv	a0,s2
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	070080e7          	jalr	112(ra) # 80003afa <iunlock>
  end_op();
    80005a92:	fffff097          	auipc	ra,0xfffff
    80005a96:	9fc080e7          	jalr	-1540(ra) # 8000448e <end_op>

  return fd;
}
    80005a9a:	8526                	mv	a0,s1
    80005a9c:	70ea                	ld	ra,184(sp)
    80005a9e:	744a                	ld	s0,176(sp)
    80005aa0:	74aa                	ld	s1,168(sp)
    80005aa2:	790a                	ld	s2,160(sp)
    80005aa4:	69ea                	ld	s3,152(sp)
    80005aa6:	6129                	addi	sp,sp,192
    80005aa8:	8082                	ret
      end_op();
    80005aaa:	fffff097          	auipc	ra,0xfffff
    80005aae:	9e4080e7          	jalr	-1564(ra) # 8000448e <end_op>
      return -1;
    80005ab2:	b7e5                	j	80005a9a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005ab4:	f5040513          	addi	a0,s0,-176
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	736080e7          	jalr	1846(ra) # 800041ee <namei>
    80005ac0:	892a                	mv	s2,a0
    80005ac2:	c905                	beqz	a0,80005af2 <sys_open+0x13c>
    ilock(ip);
    80005ac4:	ffffe097          	auipc	ra,0xffffe
    80005ac8:	f74080e7          	jalr	-140(ra) # 80003a38 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005acc:	04491703          	lh	a4,68(s2)
    80005ad0:	4785                	li	a5,1
    80005ad2:	f4f712e3          	bne	a4,a5,80005a16 <sys_open+0x60>
    80005ad6:	f4c42783          	lw	a5,-180(s0)
    80005ada:	dba1                	beqz	a5,80005a2a <sys_open+0x74>
      iunlockput(ip);
    80005adc:	854a                	mv	a0,s2
    80005ade:	ffffe097          	auipc	ra,0xffffe
    80005ae2:	1bc080e7          	jalr	444(ra) # 80003c9a <iunlockput>
      end_op();
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	9a8080e7          	jalr	-1624(ra) # 8000448e <end_op>
      return -1;
    80005aee:	54fd                	li	s1,-1
    80005af0:	b76d                	j	80005a9a <sys_open+0xe4>
      end_op();
    80005af2:	fffff097          	auipc	ra,0xfffff
    80005af6:	99c080e7          	jalr	-1636(ra) # 8000448e <end_op>
      return -1;
    80005afa:	54fd                	li	s1,-1
    80005afc:	bf79                	j	80005a9a <sys_open+0xe4>
    iunlockput(ip);
    80005afe:	854a                	mv	a0,s2
    80005b00:	ffffe097          	auipc	ra,0xffffe
    80005b04:	19a080e7          	jalr	410(ra) # 80003c9a <iunlockput>
    end_op();
    80005b08:	fffff097          	auipc	ra,0xfffff
    80005b0c:	986080e7          	jalr	-1658(ra) # 8000448e <end_op>
    return -1;
    80005b10:	54fd                	li	s1,-1
    80005b12:	b761                	j	80005a9a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b14:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b18:	04691783          	lh	a5,70(s2)
    80005b1c:	02f99223          	sh	a5,36(s3)
    80005b20:	bf2d                	j	80005a5a <sys_open+0xa4>
    itrunc(ip);
    80005b22:	854a                	mv	a0,s2
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	022080e7          	jalr	34(ra) # 80003b46 <itrunc>
    80005b2c:	bfb1                	j	80005a88 <sys_open+0xd2>
      fileclose(f);
    80005b2e:	854e                	mv	a0,s3
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	daa080e7          	jalr	-598(ra) # 800048da <fileclose>
    iunlockput(ip);
    80005b38:	854a                	mv	a0,s2
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	160080e7          	jalr	352(ra) # 80003c9a <iunlockput>
    end_op();
    80005b42:	fffff097          	auipc	ra,0xfffff
    80005b46:	94c080e7          	jalr	-1716(ra) # 8000448e <end_op>
    return -1;
    80005b4a:	54fd                	li	s1,-1
    80005b4c:	b7b9                	j	80005a9a <sys_open+0xe4>

0000000080005b4e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b4e:	7175                	addi	sp,sp,-144
    80005b50:	e506                	sd	ra,136(sp)
    80005b52:	e122                	sd	s0,128(sp)
    80005b54:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b56:	fffff097          	auipc	ra,0xfffff
    80005b5a:	8b8080e7          	jalr	-1864(ra) # 8000440e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b5e:	08000613          	li	a2,128
    80005b62:	f7040593          	addi	a1,s0,-144
    80005b66:	4501                	li	a0,0
    80005b68:	ffffd097          	auipc	ra,0xffffd
    80005b6c:	218080e7          	jalr	536(ra) # 80002d80 <argstr>
    80005b70:	02054963          	bltz	a0,80005ba2 <sys_mkdir+0x54>
    80005b74:	4681                	li	a3,0
    80005b76:	4601                	li	a2,0
    80005b78:	4585                	li	a1,1
    80005b7a:	f7040513          	addi	a0,s0,-144
    80005b7e:	00000097          	auipc	ra,0x0
    80005b82:	800080e7          	jalr	-2048(ra) # 8000537e <create>
    80005b86:	cd11                	beqz	a0,80005ba2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b88:	ffffe097          	auipc	ra,0xffffe
    80005b8c:	112080e7          	jalr	274(ra) # 80003c9a <iunlockput>
  end_op();
    80005b90:	fffff097          	auipc	ra,0xfffff
    80005b94:	8fe080e7          	jalr	-1794(ra) # 8000448e <end_op>
  return 0;
    80005b98:	4501                	li	a0,0
}
    80005b9a:	60aa                	ld	ra,136(sp)
    80005b9c:	640a                	ld	s0,128(sp)
    80005b9e:	6149                	addi	sp,sp,144
    80005ba0:	8082                	ret
    end_op();
    80005ba2:	fffff097          	auipc	ra,0xfffff
    80005ba6:	8ec080e7          	jalr	-1812(ra) # 8000448e <end_op>
    return -1;
    80005baa:	557d                	li	a0,-1
    80005bac:	b7fd                	j	80005b9a <sys_mkdir+0x4c>

0000000080005bae <sys_mknod>:

uint64
sys_mknod(void)
{
    80005bae:	7135                	addi	sp,sp,-160
    80005bb0:	ed06                	sd	ra,152(sp)
    80005bb2:	e922                	sd	s0,144(sp)
    80005bb4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005bb6:	fffff097          	auipc	ra,0xfffff
    80005bba:	858080e7          	jalr	-1960(ra) # 8000440e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bbe:	08000613          	li	a2,128
    80005bc2:	f7040593          	addi	a1,s0,-144
    80005bc6:	4501                	li	a0,0
    80005bc8:	ffffd097          	auipc	ra,0xffffd
    80005bcc:	1b8080e7          	jalr	440(ra) # 80002d80 <argstr>
    80005bd0:	04054a63          	bltz	a0,80005c24 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005bd4:	f6c40593          	addi	a1,s0,-148
    80005bd8:	4505                	li	a0,1
    80005bda:	ffffd097          	auipc	ra,0xffffd
    80005bde:	162080e7          	jalr	354(ra) # 80002d3c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005be2:	04054163          	bltz	a0,80005c24 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005be6:	f6840593          	addi	a1,s0,-152
    80005bea:	4509                	li	a0,2
    80005bec:	ffffd097          	auipc	ra,0xffffd
    80005bf0:	150080e7          	jalr	336(ra) # 80002d3c <argint>
     argint(1, &major) < 0 ||
    80005bf4:	02054863          	bltz	a0,80005c24 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bf8:	f6841683          	lh	a3,-152(s0)
    80005bfc:	f6c41603          	lh	a2,-148(s0)
    80005c00:	458d                	li	a1,3
    80005c02:	f7040513          	addi	a0,s0,-144
    80005c06:	fffff097          	auipc	ra,0xfffff
    80005c0a:	778080e7          	jalr	1912(ra) # 8000537e <create>
     argint(2, &minor) < 0 ||
    80005c0e:	c919                	beqz	a0,80005c24 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	08a080e7          	jalr	138(ra) # 80003c9a <iunlockput>
  end_op();
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	876080e7          	jalr	-1930(ra) # 8000448e <end_op>
  return 0;
    80005c20:	4501                	li	a0,0
    80005c22:	a031                	j	80005c2e <sys_mknod+0x80>
    end_op();
    80005c24:	fffff097          	auipc	ra,0xfffff
    80005c28:	86a080e7          	jalr	-1942(ra) # 8000448e <end_op>
    return -1;
    80005c2c:	557d                	li	a0,-1
}
    80005c2e:	60ea                	ld	ra,152(sp)
    80005c30:	644a                	ld	s0,144(sp)
    80005c32:	610d                	addi	sp,sp,160
    80005c34:	8082                	ret

0000000080005c36 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c36:	7135                	addi	sp,sp,-160
    80005c38:	ed06                	sd	ra,152(sp)
    80005c3a:	e922                	sd	s0,144(sp)
    80005c3c:	e526                	sd	s1,136(sp)
    80005c3e:	e14a                	sd	s2,128(sp)
    80005c40:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c42:	ffffc097          	auipc	ra,0xffffc
    80005c46:	d3c080e7          	jalr	-708(ra) # 8000197e <myproc>
    80005c4a:	892a                	mv	s2,a0
  
  begin_op();
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	7c2080e7          	jalr	1986(ra) # 8000440e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c54:	08000613          	li	a2,128
    80005c58:	f6040593          	addi	a1,s0,-160
    80005c5c:	4501                	li	a0,0
    80005c5e:	ffffd097          	auipc	ra,0xffffd
    80005c62:	122080e7          	jalr	290(ra) # 80002d80 <argstr>
    80005c66:	04054b63          	bltz	a0,80005cbc <sys_chdir+0x86>
    80005c6a:	f6040513          	addi	a0,s0,-160
    80005c6e:	ffffe097          	auipc	ra,0xffffe
    80005c72:	580080e7          	jalr	1408(ra) # 800041ee <namei>
    80005c76:	84aa                	mv	s1,a0
    80005c78:	c131                	beqz	a0,80005cbc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c7a:	ffffe097          	auipc	ra,0xffffe
    80005c7e:	dbe080e7          	jalr	-578(ra) # 80003a38 <ilock>
  if(ip->type != T_DIR){
    80005c82:	04449703          	lh	a4,68(s1)
    80005c86:	4785                	li	a5,1
    80005c88:	04f71063          	bne	a4,a5,80005cc8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c8c:	8526                	mv	a0,s1
    80005c8e:	ffffe097          	auipc	ra,0xffffe
    80005c92:	e6c080e7          	jalr	-404(ra) # 80003afa <iunlock>
  iput(p->cwd);
    80005c96:	16893503          	ld	a0,360(s2)
    80005c9a:	ffffe097          	auipc	ra,0xffffe
    80005c9e:	f58080e7          	jalr	-168(ra) # 80003bf2 <iput>
  end_op();
    80005ca2:	ffffe097          	auipc	ra,0xffffe
    80005ca6:	7ec080e7          	jalr	2028(ra) # 8000448e <end_op>
  p->cwd = ip;
    80005caa:	16993423          	sd	s1,360(s2)
  return 0;
    80005cae:	4501                	li	a0,0
}
    80005cb0:	60ea                	ld	ra,152(sp)
    80005cb2:	644a                	ld	s0,144(sp)
    80005cb4:	64aa                	ld	s1,136(sp)
    80005cb6:	690a                	ld	s2,128(sp)
    80005cb8:	610d                	addi	sp,sp,160
    80005cba:	8082                	ret
    end_op();
    80005cbc:	ffffe097          	auipc	ra,0xffffe
    80005cc0:	7d2080e7          	jalr	2002(ra) # 8000448e <end_op>
    return -1;
    80005cc4:	557d                	li	a0,-1
    80005cc6:	b7ed                	j	80005cb0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005cc8:	8526                	mv	a0,s1
    80005cca:	ffffe097          	auipc	ra,0xffffe
    80005cce:	fd0080e7          	jalr	-48(ra) # 80003c9a <iunlockput>
    end_op();
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	7bc080e7          	jalr	1980(ra) # 8000448e <end_op>
    return -1;
    80005cda:	557d                	li	a0,-1
    80005cdc:	bfd1                	j	80005cb0 <sys_chdir+0x7a>

0000000080005cde <sys_exec>:

uint64
sys_exec(void)
{
    80005cde:	7145                	addi	sp,sp,-464
    80005ce0:	e786                	sd	ra,456(sp)
    80005ce2:	e3a2                	sd	s0,448(sp)
    80005ce4:	ff26                	sd	s1,440(sp)
    80005ce6:	fb4a                	sd	s2,432(sp)
    80005ce8:	f74e                	sd	s3,424(sp)
    80005cea:	f352                	sd	s4,416(sp)
    80005cec:	ef56                	sd	s5,408(sp)
    80005cee:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cf0:	08000613          	li	a2,128
    80005cf4:	f4040593          	addi	a1,s0,-192
    80005cf8:	4501                	li	a0,0
    80005cfa:	ffffd097          	auipc	ra,0xffffd
    80005cfe:	086080e7          	jalr	134(ra) # 80002d80 <argstr>
    return -1;
    80005d02:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d04:	0c054a63          	bltz	a0,80005dd8 <sys_exec+0xfa>
    80005d08:	e3840593          	addi	a1,s0,-456
    80005d0c:	4505                	li	a0,1
    80005d0e:	ffffd097          	auipc	ra,0xffffd
    80005d12:	050080e7          	jalr	80(ra) # 80002d5e <argaddr>
    80005d16:	0c054163          	bltz	a0,80005dd8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005d1a:	10000613          	li	a2,256
    80005d1e:	4581                	li	a1,0
    80005d20:	e4040513          	addi	a0,s0,-448
    80005d24:	ffffb097          	auipc	ra,0xffffb
    80005d28:	f9a080e7          	jalr	-102(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d2c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d30:	89a6                	mv	s3,s1
    80005d32:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d34:	02000a13          	li	s4,32
    80005d38:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d3c:	00391793          	slli	a5,s2,0x3
    80005d40:	e3040593          	addi	a1,s0,-464
    80005d44:	e3843503          	ld	a0,-456(s0)
    80005d48:	953e                	add	a0,a0,a5
    80005d4a:	ffffd097          	auipc	ra,0xffffd
    80005d4e:	f58080e7          	jalr	-168(ra) # 80002ca2 <fetchaddr>
    80005d52:	02054a63          	bltz	a0,80005d86 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005d56:	e3043783          	ld	a5,-464(s0)
    80005d5a:	c3b9                	beqz	a5,80005da0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d5c:	ffffb097          	auipc	ra,0xffffb
    80005d60:	d76080e7          	jalr	-650(ra) # 80000ad2 <kalloc>
    80005d64:	85aa                	mv	a1,a0
    80005d66:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d6a:	cd11                	beqz	a0,80005d86 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d6c:	6605                	lui	a2,0x1
    80005d6e:	e3043503          	ld	a0,-464(s0)
    80005d72:	ffffd097          	auipc	ra,0xffffd
    80005d76:	f82080e7          	jalr	-126(ra) # 80002cf4 <fetchstr>
    80005d7a:	00054663          	bltz	a0,80005d86 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d7e:	0905                	addi	s2,s2,1
    80005d80:	09a1                	addi	s3,s3,8
    80005d82:	fb491be3          	bne	s2,s4,80005d38 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d86:	10048913          	addi	s2,s1,256
    80005d8a:	6088                	ld	a0,0(s1)
    80005d8c:	c529                	beqz	a0,80005dd6 <sys_exec+0xf8>
    kfree(argv[i]);
    80005d8e:	ffffb097          	auipc	ra,0xffffb
    80005d92:	c48080e7          	jalr	-952(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d96:	04a1                	addi	s1,s1,8
    80005d98:	ff2499e3          	bne	s1,s2,80005d8a <sys_exec+0xac>
  return -1;
    80005d9c:	597d                	li	s2,-1
    80005d9e:	a82d                	j	80005dd8 <sys_exec+0xfa>
      argv[i] = 0;
    80005da0:	0a8e                	slli	s5,s5,0x3
    80005da2:	fc040793          	addi	a5,s0,-64
    80005da6:	9abe                	add	s5,s5,a5
    80005da8:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005dac:	e4040593          	addi	a1,s0,-448
    80005db0:	f4040513          	addi	a0,s0,-192
    80005db4:	fffff097          	auipc	ra,0xfffff
    80005db8:	178080e7          	jalr	376(ra) # 80004f2c <exec>
    80005dbc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dbe:	10048993          	addi	s3,s1,256
    80005dc2:	6088                	ld	a0,0(s1)
    80005dc4:	c911                	beqz	a0,80005dd8 <sys_exec+0xfa>
    kfree(argv[i]);
    80005dc6:	ffffb097          	auipc	ra,0xffffb
    80005dca:	c10080e7          	jalr	-1008(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dce:	04a1                	addi	s1,s1,8
    80005dd0:	ff3499e3          	bne	s1,s3,80005dc2 <sys_exec+0xe4>
    80005dd4:	a011                	j	80005dd8 <sys_exec+0xfa>
  return -1;
    80005dd6:	597d                	li	s2,-1
}
    80005dd8:	854a                	mv	a0,s2
    80005dda:	60be                	ld	ra,456(sp)
    80005ddc:	641e                	ld	s0,448(sp)
    80005dde:	74fa                	ld	s1,440(sp)
    80005de0:	795a                	ld	s2,432(sp)
    80005de2:	79ba                	ld	s3,424(sp)
    80005de4:	7a1a                	ld	s4,416(sp)
    80005de6:	6afa                	ld	s5,408(sp)
    80005de8:	6179                	addi	sp,sp,464
    80005dea:	8082                	ret

0000000080005dec <sys_pipe>:

uint64
sys_pipe(void)
{
    80005dec:	7139                	addi	sp,sp,-64
    80005dee:	fc06                	sd	ra,56(sp)
    80005df0:	f822                	sd	s0,48(sp)
    80005df2:	f426                	sd	s1,40(sp)
    80005df4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005df6:	ffffc097          	auipc	ra,0xffffc
    80005dfa:	b88080e7          	jalr	-1144(ra) # 8000197e <myproc>
    80005dfe:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005e00:	fd840593          	addi	a1,s0,-40
    80005e04:	4501                	li	a0,0
    80005e06:	ffffd097          	auipc	ra,0xffffd
    80005e0a:	f58080e7          	jalr	-168(ra) # 80002d5e <argaddr>
    return -1;
    80005e0e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005e10:	0e054063          	bltz	a0,80005ef0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005e14:	fc840593          	addi	a1,s0,-56
    80005e18:	fd040513          	addi	a0,s0,-48
    80005e1c:	fffff097          	auipc	ra,0xfffff
    80005e20:	dee080e7          	jalr	-530(ra) # 80004c0a <pipealloc>
    return -1;
    80005e24:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e26:	0c054563          	bltz	a0,80005ef0 <sys_pipe+0x104>
  fd0 = -1;
    80005e2a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e2e:	fd043503          	ld	a0,-48(s0)
    80005e32:	fffff097          	auipc	ra,0xfffff
    80005e36:	50a080e7          	jalr	1290(ra) # 8000533c <fdalloc>
    80005e3a:	fca42223          	sw	a0,-60(s0)
    80005e3e:	08054c63          	bltz	a0,80005ed6 <sys_pipe+0xea>
    80005e42:	fc843503          	ld	a0,-56(s0)
    80005e46:	fffff097          	auipc	ra,0xfffff
    80005e4a:	4f6080e7          	jalr	1270(ra) # 8000533c <fdalloc>
    80005e4e:	fca42023          	sw	a0,-64(s0)
    80005e52:	06054863          	bltz	a0,80005ec2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e56:	4691                	li	a3,4
    80005e58:	fc440613          	addi	a2,s0,-60
    80005e5c:	fd843583          	ld	a1,-40(s0)
    80005e60:	74a8                	ld	a0,104(s1)
    80005e62:	ffffb097          	auipc	ra,0xffffb
    80005e66:	7dc080e7          	jalr	2012(ra) # 8000163e <copyout>
    80005e6a:	02054063          	bltz	a0,80005e8a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e6e:	4691                	li	a3,4
    80005e70:	fc040613          	addi	a2,s0,-64
    80005e74:	fd843583          	ld	a1,-40(s0)
    80005e78:	0591                	addi	a1,a1,4
    80005e7a:	74a8                	ld	a0,104(s1)
    80005e7c:	ffffb097          	auipc	ra,0xffffb
    80005e80:	7c2080e7          	jalr	1986(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e84:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e86:	06055563          	bgez	a0,80005ef0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e8a:	fc442783          	lw	a5,-60(s0)
    80005e8e:	07f1                	addi	a5,a5,28
    80005e90:	078e                	slli	a5,a5,0x3
    80005e92:	97a6                	add	a5,a5,s1
    80005e94:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005e98:	fc042503          	lw	a0,-64(s0)
    80005e9c:	0571                	addi	a0,a0,28
    80005e9e:	050e                	slli	a0,a0,0x3
    80005ea0:	9526                	add	a0,a0,s1
    80005ea2:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005ea6:	fd043503          	ld	a0,-48(s0)
    80005eaa:	fffff097          	auipc	ra,0xfffff
    80005eae:	a30080e7          	jalr	-1488(ra) # 800048da <fileclose>
    fileclose(wf);
    80005eb2:	fc843503          	ld	a0,-56(s0)
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	a24080e7          	jalr	-1500(ra) # 800048da <fileclose>
    return -1;
    80005ebe:	57fd                	li	a5,-1
    80005ec0:	a805                	j	80005ef0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005ec2:	fc442783          	lw	a5,-60(s0)
    80005ec6:	0007c863          	bltz	a5,80005ed6 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005eca:	01c78513          	addi	a0,a5,28
    80005ece:	050e                	slli	a0,a0,0x3
    80005ed0:	9526                	add	a0,a0,s1
    80005ed2:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005ed6:	fd043503          	ld	a0,-48(s0)
    80005eda:	fffff097          	auipc	ra,0xfffff
    80005ede:	a00080e7          	jalr	-1536(ra) # 800048da <fileclose>
    fileclose(wf);
    80005ee2:	fc843503          	ld	a0,-56(s0)
    80005ee6:	fffff097          	auipc	ra,0xfffff
    80005eea:	9f4080e7          	jalr	-1548(ra) # 800048da <fileclose>
    return -1;
    80005eee:	57fd                	li	a5,-1
}
    80005ef0:	853e                	mv	a0,a5
    80005ef2:	70e2                	ld	ra,56(sp)
    80005ef4:	7442                	ld	s0,48(sp)
    80005ef6:	74a2                	ld	s1,40(sp)
    80005ef8:	6121                	addi	sp,sp,64
    80005efa:	8082                	ret
    80005efc:	0000                	unimp
	...

0000000080005f00 <kernelvec>:
    80005f00:	7111                	addi	sp,sp,-256
    80005f02:	e006                	sd	ra,0(sp)
    80005f04:	e40a                	sd	sp,8(sp)
    80005f06:	e80e                	sd	gp,16(sp)
    80005f08:	ec12                	sd	tp,24(sp)
    80005f0a:	f016                	sd	t0,32(sp)
    80005f0c:	f41a                	sd	t1,40(sp)
    80005f0e:	f81e                	sd	t2,48(sp)
    80005f10:	fc22                	sd	s0,56(sp)
    80005f12:	e0a6                	sd	s1,64(sp)
    80005f14:	e4aa                	sd	a0,72(sp)
    80005f16:	e8ae                	sd	a1,80(sp)
    80005f18:	ecb2                	sd	a2,88(sp)
    80005f1a:	f0b6                	sd	a3,96(sp)
    80005f1c:	f4ba                	sd	a4,104(sp)
    80005f1e:	f8be                	sd	a5,112(sp)
    80005f20:	fcc2                	sd	a6,120(sp)
    80005f22:	e146                	sd	a7,128(sp)
    80005f24:	e54a                	sd	s2,136(sp)
    80005f26:	e94e                	sd	s3,144(sp)
    80005f28:	ed52                	sd	s4,152(sp)
    80005f2a:	f156                	sd	s5,160(sp)
    80005f2c:	f55a                	sd	s6,168(sp)
    80005f2e:	f95e                	sd	s7,176(sp)
    80005f30:	fd62                	sd	s8,184(sp)
    80005f32:	e1e6                	sd	s9,192(sp)
    80005f34:	e5ea                	sd	s10,200(sp)
    80005f36:	e9ee                	sd	s11,208(sp)
    80005f38:	edf2                	sd	t3,216(sp)
    80005f3a:	f1f6                	sd	t4,224(sp)
    80005f3c:	f5fa                	sd	t5,232(sp)
    80005f3e:	f9fe                	sd	t6,240(sp)
    80005f40:	c2ffc0ef          	jal	ra,80002b6e <kerneltrap>
    80005f44:	6082                	ld	ra,0(sp)
    80005f46:	6122                	ld	sp,8(sp)
    80005f48:	61c2                	ld	gp,16(sp)
    80005f4a:	7282                	ld	t0,32(sp)
    80005f4c:	7322                	ld	t1,40(sp)
    80005f4e:	73c2                	ld	t2,48(sp)
    80005f50:	7462                	ld	s0,56(sp)
    80005f52:	6486                	ld	s1,64(sp)
    80005f54:	6526                	ld	a0,72(sp)
    80005f56:	65c6                	ld	a1,80(sp)
    80005f58:	6666                	ld	a2,88(sp)
    80005f5a:	7686                	ld	a3,96(sp)
    80005f5c:	7726                	ld	a4,104(sp)
    80005f5e:	77c6                	ld	a5,112(sp)
    80005f60:	7866                	ld	a6,120(sp)
    80005f62:	688a                	ld	a7,128(sp)
    80005f64:	692a                	ld	s2,136(sp)
    80005f66:	69ca                	ld	s3,144(sp)
    80005f68:	6a6a                	ld	s4,152(sp)
    80005f6a:	7a8a                	ld	s5,160(sp)
    80005f6c:	7b2a                	ld	s6,168(sp)
    80005f6e:	7bca                	ld	s7,176(sp)
    80005f70:	7c6a                	ld	s8,184(sp)
    80005f72:	6c8e                	ld	s9,192(sp)
    80005f74:	6d2e                	ld	s10,200(sp)
    80005f76:	6dce                	ld	s11,208(sp)
    80005f78:	6e6e                	ld	t3,216(sp)
    80005f7a:	7e8e                	ld	t4,224(sp)
    80005f7c:	7f2e                	ld	t5,232(sp)
    80005f7e:	7fce                	ld	t6,240(sp)
    80005f80:	6111                	addi	sp,sp,256
    80005f82:	10200073          	sret
    80005f86:	00000013          	nop
    80005f8a:	00000013          	nop
    80005f8e:	0001                	nop

0000000080005f90 <timervec>:
    80005f90:	34051573          	csrrw	a0,mscratch,a0
    80005f94:	e10c                	sd	a1,0(a0)
    80005f96:	e510                	sd	a2,8(a0)
    80005f98:	e914                	sd	a3,16(a0)
    80005f9a:	6d0c                	ld	a1,24(a0)
    80005f9c:	7110                	ld	a2,32(a0)
    80005f9e:	6194                	ld	a3,0(a1)
    80005fa0:	96b2                	add	a3,a3,a2
    80005fa2:	e194                	sd	a3,0(a1)
    80005fa4:	4589                	li	a1,2
    80005fa6:	14459073          	csrw	sip,a1
    80005faa:	6914                	ld	a3,16(a0)
    80005fac:	6510                	ld	a2,8(a0)
    80005fae:	610c                	ld	a1,0(a0)
    80005fb0:	34051573          	csrrw	a0,mscratch,a0
    80005fb4:	30200073          	mret
	...

0000000080005fba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005fba:	1141                	addi	sp,sp,-16
    80005fbc:	e422                	sd	s0,8(sp)
    80005fbe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fc0:	0c0007b7          	lui	a5,0xc000
    80005fc4:	4705                	li	a4,1
    80005fc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fc8:	c3d8                	sw	a4,4(a5)
}
    80005fca:	6422                	ld	s0,8(sp)
    80005fcc:	0141                	addi	sp,sp,16
    80005fce:	8082                	ret

0000000080005fd0 <plicinithart>:

void
plicinithart(void)
{
    80005fd0:	1141                	addi	sp,sp,-16
    80005fd2:	e406                	sd	ra,8(sp)
    80005fd4:	e022                	sd	s0,0(sp)
    80005fd6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fd8:	ffffc097          	auipc	ra,0xffffc
    80005fdc:	97a080e7          	jalr	-1670(ra) # 80001952 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fe0:	0085171b          	slliw	a4,a0,0x8
    80005fe4:	0c0027b7          	lui	a5,0xc002
    80005fe8:	97ba                	add	a5,a5,a4
    80005fea:	40200713          	li	a4,1026
    80005fee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ff2:	00d5151b          	slliw	a0,a0,0xd
    80005ff6:	0c2017b7          	lui	a5,0xc201
    80005ffa:	953e                	add	a0,a0,a5
    80005ffc:	00052023          	sw	zero,0(a0)
}
    80006000:	60a2                	ld	ra,8(sp)
    80006002:	6402                	ld	s0,0(sp)
    80006004:	0141                	addi	sp,sp,16
    80006006:	8082                	ret

0000000080006008 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006008:	1141                	addi	sp,sp,-16
    8000600a:	e406                	sd	ra,8(sp)
    8000600c:	e022                	sd	s0,0(sp)
    8000600e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006010:	ffffc097          	auipc	ra,0xffffc
    80006014:	942080e7          	jalr	-1726(ra) # 80001952 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006018:	00d5179b          	slliw	a5,a0,0xd
    8000601c:	0c201537          	lui	a0,0xc201
    80006020:	953e                	add	a0,a0,a5
  return irq;
}
    80006022:	4148                	lw	a0,4(a0)
    80006024:	60a2                	ld	ra,8(sp)
    80006026:	6402                	ld	s0,0(sp)
    80006028:	0141                	addi	sp,sp,16
    8000602a:	8082                	ret

000000008000602c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000602c:	1101                	addi	sp,sp,-32
    8000602e:	ec06                	sd	ra,24(sp)
    80006030:	e822                	sd	s0,16(sp)
    80006032:	e426                	sd	s1,8(sp)
    80006034:	1000                	addi	s0,sp,32
    80006036:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006038:	ffffc097          	auipc	ra,0xffffc
    8000603c:	91a080e7          	jalr	-1766(ra) # 80001952 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006040:	00d5151b          	slliw	a0,a0,0xd
    80006044:	0c2017b7          	lui	a5,0xc201
    80006048:	97aa                	add	a5,a5,a0
    8000604a:	c3c4                	sw	s1,4(a5)
}
    8000604c:	60e2                	ld	ra,24(sp)
    8000604e:	6442                	ld	s0,16(sp)
    80006050:	64a2                	ld	s1,8(sp)
    80006052:	6105                	addi	sp,sp,32
    80006054:	8082                	ret

0000000080006056 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006056:	1141                	addi	sp,sp,-16
    80006058:	e406                	sd	ra,8(sp)
    8000605a:	e022                	sd	s0,0(sp)
    8000605c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000605e:	479d                	li	a5,7
    80006060:	06a7c963          	blt	a5,a0,800060d2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006064:	0001d797          	auipc	a5,0x1d
    80006068:	f9c78793          	addi	a5,a5,-100 # 80023000 <disk>
    8000606c:	00a78733          	add	a4,a5,a0
    80006070:	6789                	lui	a5,0x2
    80006072:	97ba                	add	a5,a5,a4
    80006074:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006078:	e7ad                	bnez	a5,800060e2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000607a:	00451793          	slli	a5,a0,0x4
    8000607e:	0001f717          	auipc	a4,0x1f
    80006082:	f8270713          	addi	a4,a4,-126 # 80025000 <disk+0x2000>
    80006086:	6314                	ld	a3,0(a4)
    80006088:	96be                	add	a3,a3,a5
    8000608a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000608e:	6314                	ld	a3,0(a4)
    80006090:	96be                	add	a3,a3,a5
    80006092:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006096:	6314                	ld	a3,0(a4)
    80006098:	96be                	add	a3,a3,a5
    8000609a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000609e:	6318                	ld	a4,0(a4)
    800060a0:	97ba                	add	a5,a5,a4
    800060a2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800060a6:	0001d797          	auipc	a5,0x1d
    800060aa:	f5a78793          	addi	a5,a5,-166 # 80023000 <disk>
    800060ae:	97aa                	add	a5,a5,a0
    800060b0:	6509                	lui	a0,0x2
    800060b2:	953e                	add	a0,a0,a5
    800060b4:	4785                	li	a5,1
    800060b6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800060ba:	0001f517          	auipc	a0,0x1f
    800060be:	f5e50513          	addi	a0,a0,-162 # 80025018 <disk+0x2018>
    800060c2:	ffffc097          	auipc	ra,0xffffc
    800060c6:	11e080e7          	jalr	286(ra) # 800021e0 <wakeup>
}
    800060ca:	60a2                	ld	ra,8(sp)
    800060cc:	6402                	ld	s0,0(sp)
    800060ce:	0141                	addi	sp,sp,16
    800060d0:	8082                	ret
    panic("free_desc 1");
    800060d2:	00003517          	auipc	a0,0x3
    800060d6:	86e50513          	addi	a0,a0,-1938 # 80008940 <syscalls+0x330>
    800060da:	ffffa097          	auipc	ra,0xffffa
    800060de:	450080e7          	jalr	1104(ra) # 8000052a <panic>
    panic("free_desc 2");
    800060e2:	00003517          	auipc	a0,0x3
    800060e6:	86e50513          	addi	a0,a0,-1938 # 80008950 <syscalls+0x340>
    800060ea:	ffffa097          	auipc	ra,0xffffa
    800060ee:	440080e7          	jalr	1088(ra) # 8000052a <panic>

00000000800060f2 <virtio_disk_init>:
{
    800060f2:	1101                	addi	sp,sp,-32
    800060f4:	ec06                	sd	ra,24(sp)
    800060f6:	e822                	sd	s0,16(sp)
    800060f8:	e426                	sd	s1,8(sp)
    800060fa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060fc:	00003597          	auipc	a1,0x3
    80006100:	86458593          	addi	a1,a1,-1948 # 80008960 <syscalls+0x350>
    80006104:	0001f517          	auipc	a0,0x1f
    80006108:	02450513          	addi	a0,a0,36 # 80025128 <disk+0x2128>
    8000610c:	ffffb097          	auipc	ra,0xffffb
    80006110:	a26080e7          	jalr	-1498(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006114:	100017b7          	lui	a5,0x10001
    80006118:	4398                	lw	a4,0(a5)
    8000611a:	2701                	sext.w	a4,a4
    8000611c:	747277b7          	lui	a5,0x74727
    80006120:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006124:	0ef71163          	bne	a4,a5,80006206 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006128:	100017b7          	lui	a5,0x10001
    8000612c:	43dc                	lw	a5,4(a5)
    8000612e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006130:	4705                	li	a4,1
    80006132:	0ce79a63          	bne	a5,a4,80006206 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006136:	100017b7          	lui	a5,0x10001
    8000613a:	479c                	lw	a5,8(a5)
    8000613c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000613e:	4709                	li	a4,2
    80006140:	0ce79363          	bne	a5,a4,80006206 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006144:	100017b7          	lui	a5,0x10001
    80006148:	47d8                	lw	a4,12(a5)
    8000614a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000614c:	554d47b7          	lui	a5,0x554d4
    80006150:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006154:	0af71963          	bne	a4,a5,80006206 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006158:	100017b7          	lui	a5,0x10001
    8000615c:	4705                	li	a4,1
    8000615e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006160:	470d                	li	a4,3
    80006162:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006164:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006166:	c7ffe737          	lui	a4,0xc7ffe
    8000616a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000616e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006170:	2701                	sext.w	a4,a4
    80006172:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006174:	472d                	li	a4,11
    80006176:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006178:	473d                	li	a4,15
    8000617a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000617c:	6705                	lui	a4,0x1
    8000617e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006180:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006184:	5bdc                	lw	a5,52(a5)
    80006186:	2781                	sext.w	a5,a5
  if(max == 0)
    80006188:	c7d9                	beqz	a5,80006216 <virtio_disk_init+0x124>
  if(max < NUM)
    8000618a:	471d                	li	a4,7
    8000618c:	08f77d63          	bgeu	a4,a5,80006226 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006190:	100014b7          	lui	s1,0x10001
    80006194:	47a1                	li	a5,8
    80006196:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006198:	6609                	lui	a2,0x2
    8000619a:	4581                	li	a1,0
    8000619c:	0001d517          	auipc	a0,0x1d
    800061a0:	e6450513          	addi	a0,a0,-412 # 80023000 <disk>
    800061a4:	ffffb097          	auipc	ra,0xffffb
    800061a8:	b1a080e7          	jalr	-1254(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800061ac:	0001d717          	auipc	a4,0x1d
    800061b0:	e5470713          	addi	a4,a4,-428 # 80023000 <disk>
    800061b4:	00c75793          	srli	a5,a4,0xc
    800061b8:	2781                	sext.w	a5,a5
    800061ba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800061bc:	0001f797          	auipc	a5,0x1f
    800061c0:	e4478793          	addi	a5,a5,-444 # 80025000 <disk+0x2000>
    800061c4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800061c6:	0001d717          	auipc	a4,0x1d
    800061ca:	eba70713          	addi	a4,a4,-326 # 80023080 <disk+0x80>
    800061ce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800061d0:	0001e717          	auipc	a4,0x1e
    800061d4:	e3070713          	addi	a4,a4,-464 # 80024000 <disk+0x1000>
    800061d8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800061da:	4705                	li	a4,1
    800061dc:	00e78c23          	sb	a4,24(a5)
    800061e0:	00e78ca3          	sb	a4,25(a5)
    800061e4:	00e78d23          	sb	a4,26(a5)
    800061e8:	00e78da3          	sb	a4,27(a5)
    800061ec:	00e78e23          	sb	a4,28(a5)
    800061f0:	00e78ea3          	sb	a4,29(a5)
    800061f4:	00e78f23          	sb	a4,30(a5)
    800061f8:	00e78fa3          	sb	a4,31(a5)
}
    800061fc:	60e2                	ld	ra,24(sp)
    800061fe:	6442                	ld	s0,16(sp)
    80006200:	64a2                	ld	s1,8(sp)
    80006202:	6105                	addi	sp,sp,32
    80006204:	8082                	ret
    panic("could not find virtio disk");
    80006206:	00002517          	auipc	a0,0x2
    8000620a:	76a50513          	addi	a0,a0,1898 # 80008970 <syscalls+0x360>
    8000620e:	ffffa097          	auipc	ra,0xffffa
    80006212:	31c080e7          	jalr	796(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006216:	00002517          	auipc	a0,0x2
    8000621a:	77a50513          	addi	a0,a0,1914 # 80008990 <syscalls+0x380>
    8000621e:	ffffa097          	auipc	ra,0xffffa
    80006222:	30c080e7          	jalr	780(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006226:	00002517          	auipc	a0,0x2
    8000622a:	78a50513          	addi	a0,a0,1930 # 800089b0 <syscalls+0x3a0>
    8000622e:	ffffa097          	auipc	ra,0xffffa
    80006232:	2fc080e7          	jalr	764(ra) # 8000052a <panic>

0000000080006236 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006236:	7119                	addi	sp,sp,-128
    80006238:	fc86                	sd	ra,120(sp)
    8000623a:	f8a2                	sd	s0,112(sp)
    8000623c:	f4a6                	sd	s1,104(sp)
    8000623e:	f0ca                	sd	s2,96(sp)
    80006240:	ecce                	sd	s3,88(sp)
    80006242:	e8d2                	sd	s4,80(sp)
    80006244:	e4d6                	sd	s5,72(sp)
    80006246:	e0da                	sd	s6,64(sp)
    80006248:	fc5e                	sd	s7,56(sp)
    8000624a:	f862                	sd	s8,48(sp)
    8000624c:	f466                	sd	s9,40(sp)
    8000624e:	f06a                	sd	s10,32(sp)
    80006250:	ec6e                	sd	s11,24(sp)
    80006252:	0100                	addi	s0,sp,128
    80006254:	8aaa                	mv	s5,a0
    80006256:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006258:	00c52c83          	lw	s9,12(a0)
    8000625c:	001c9c9b          	slliw	s9,s9,0x1
    80006260:	1c82                	slli	s9,s9,0x20
    80006262:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006266:	0001f517          	auipc	a0,0x1f
    8000626a:	ec250513          	addi	a0,a0,-318 # 80025128 <disk+0x2128>
    8000626e:	ffffb097          	auipc	ra,0xffffb
    80006272:	954080e7          	jalr	-1708(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006276:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006278:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000627a:	0001dc17          	auipc	s8,0x1d
    8000627e:	d86c0c13          	addi	s8,s8,-634 # 80023000 <disk>
    80006282:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006284:	4b0d                	li	s6,3
    80006286:	a0ad                	j	800062f0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006288:	00fc0733          	add	a4,s8,a5
    8000628c:	975e                	add	a4,a4,s7
    8000628e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006292:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006294:	0207c563          	bltz	a5,800062be <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006298:	2905                	addiw	s2,s2,1
    8000629a:	0611                	addi	a2,a2,4
    8000629c:	19690d63          	beq	s2,s6,80006436 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    800062a0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800062a2:	0001f717          	auipc	a4,0x1f
    800062a6:	d7670713          	addi	a4,a4,-650 # 80025018 <disk+0x2018>
    800062aa:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800062ac:	00074683          	lbu	a3,0(a4)
    800062b0:	fee1                	bnez	a3,80006288 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800062b2:	2785                	addiw	a5,a5,1
    800062b4:	0705                	addi	a4,a4,1
    800062b6:	fe979be3          	bne	a5,s1,800062ac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800062ba:	57fd                	li	a5,-1
    800062bc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800062be:	01205d63          	blez	s2,800062d8 <virtio_disk_rw+0xa2>
    800062c2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800062c4:	000a2503          	lw	a0,0(s4)
    800062c8:	00000097          	auipc	ra,0x0
    800062cc:	d8e080e7          	jalr	-626(ra) # 80006056 <free_desc>
      for(int j = 0; j < i; j++)
    800062d0:	2d85                	addiw	s11,s11,1
    800062d2:	0a11                	addi	s4,s4,4
    800062d4:	ffb918e3          	bne	s2,s11,800062c4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062d8:	0001f597          	auipc	a1,0x1f
    800062dc:	e5058593          	addi	a1,a1,-432 # 80025128 <disk+0x2128>
    800062e0:	0001f517          	auipc	a0,0x1f
    800062e4:	d3850513          	addi	a0,a0,-712 # 80025018 <disk+0x2018>
    800062e8:	ffffc097          	auipc	ra,0xffffc
    800062ec:	d6c080e7          	jalr	-660(ra) # 80002054 <sleep>
  for(int i = 0; i < 3; i++){
    800062f0:	f8040a13          	addi	s4,s0,-128
{
    800062f4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800062f6:	894e                	mv	s2,s3
    800062f8:	b765                	j	800062a0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062fa:	0001f697          	auipc	a3,0x1f
    800062fe:	d066b683          	ld	a3,-762(a3) # 80025000 <disk+0x2000>
    80006302:	96ba                	add	a3,a3,a4
    80006304:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006308:	0001d817          	auipc	a6,0x1d
    8000630c:	cf880813          	addi	a6,a6,-776 # 80023000 <disk>
    80006310:	0001f697          	auipc	a3,0x1f
    80006314:	cf068693          	addi	a3,a3,-784 # 80025000 <disk+0x2000>
    80006318:	6290                	ld	a2,0(a3)
    8000631a:	963a                	add	a2,a2,a4
    8000631c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006320:	0015e593          	ori	a1,a1,1
    80006324:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006328:	f8842603          	lw	a2,-120(s0)
    8000632c:	628c                	ld	a1,0(a3)
    8000632e:	972e                	add	a4,a4,a1
    80006330:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006334:	20050593          	addi	a1,a0,512
    80006338:	0592                	slli	a1,a1,0x4
    8000633a:	95c2                	add	a1,a1,a6
    8000633c:	577d                	li	a4,-1
    8000633e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006342:	00461713          	slli	a4,a2,0x4
    80006346:	6290                	ld	a2,0(a3)
    80006348:	963a                	add	a2,a2,a4
    8000634a:	03078793          	addi	a5,a5,48
    8000634e:	97c2                	add	a5,a5,a6
    80006350:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006352:	629c                	ld	a5,0(a3)
    80006354:	97ba                	add	a5,a5,a4
    80006356:	4605                	li	a2,1
    80006358:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000635a:	629c                	ld	a5,0(a3)
    8000635c:	97ba                	add	a5,a5,a4
    8000635e:	4809                	li	a6,2
    80006360:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006364:	629c                	ld	a5,0(a3)
    80006366:	973e                	add	a4,a4,a5
    80006368:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000636c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006370:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006374:	6698                	ld	a4,8(a3)
    80006376:	00275783          	lhu	a5,2(a4)
    8000637a:	8b9d                	andi	a5,a5,7
    8000637c:	0786                	slli	a5,a5,0x1
    8000637e:	97ba                	add	a5,a5,a4
    80006380:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006384:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006388:	6698                	ld	a4,8(a3)
    8000638a:	00275783          	lhu	a5,2(a4)
    8000638e:	2785                	addiw	a5,a5,1
    80006390:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006394:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006398:	100017b7          	lui	a5,0x10001
    8000639c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063a0:	004aa783          	lw	a5,4(s5)
    800063a4:	02c79163          	bne	a5,a2,800063c6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800063a8:	0001f917          	auipc	s2,0x1f
    800063ac:	d8090913          	addi	s2,s2,-640 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800063b0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800063b2:	85ca                	mv	a1,s2
    800063b4:	8556                	mv	a0,s5
    800063b6:	ffffc097          	auipc	ra,0xffffc
    800063ba:	c9e080e7          	jalr	-866(ra) # 80002054 <sleep>
  while(b->disk == 1) {
    800063be:	004aa783          	lw	a5,4(s5)
    800063c2:	fe9788e3          	beq	a5,s1,800063b2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800063c6:	f8042903          	lw	s2,-128(s0)
    800063ca:	20090793          	addi	a5,s2,512
    800063ce:	00479713          	slli	a4,a5,0x4
    800063d2:	0001d797          	auipc	a5,0x1d
    800063d6:	c2e78793          	addi	a5,a5,-978 # 80023000 <disk>
    800063da:	97ba                	add	a5,a5,a4
    800063dc:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800063e0:	0001f997          	auipc	s3,0x1f
    800063e4:	c2098993          	addi	s3,s3,-992 # 80025000 <disk+0x2000>
    800063e8:	00491713          	slli	a4,s2,0x4
    800063ec:	0009b783          	ld	a5,0(s3)
    800063f0:	97ba                	add	a5,a5,a4
    800063f2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063f6:	854a                	mv	a0,s2
    800063f8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063fc:	00000097          	auipc	ra,0x0
    80006400:	c5a080e7          	jalr	-934(ra) # 80006056 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006404:	8885                	andi	s1,s1,1
    80006406:	f0ed                	bnez	s1,800063e8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006408:	0001f517          	auipc	a0,0x1f
    8000640c:	d2050513          	addi	a0,a0,-736 # 80025128 <disk+0x2128>
    80006410:	ffffb097          	auipc	ra,0xffffb
    80006414:	866080e7          	jalr	-1946(ra) # 80000c76 <release>
}
    80006418:	70e6                	ld	ra,120(sp)
    8000641a:	7446                	ld	s0,112(sp)
    8000641c:	74a6                	ld	s1,104(sp)
    8000641e:	7906                	ld	s2,96(sp)
    80006420:	69e6                	ld	s3,88(sp)
    80006422:	6a46                	ld	s4,80(sp)
    80006424:	6aa6                	ld	s5,72(sp)
    80006426:	6b06                	ld	s6,64(sp)
    80006428:	7be2                	ld	s7,56(sp)
    8000642a:	7c42                	ld	s8,48(sp)
    8000642c:	7ca2                	ld	s9,40(sp)
    8000642e:	7d02                	ld	s10,32(sp)
    80006430:	6de2                	ld	s11,24(sp)
    80006432:	6109                	addi	sp,sp,128
    80006434:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006436:	f8042503          	lw	a0,-128(s0)
    8000643a:	20050793          	addi	a5,a0,512
    8000643e:	0792                	slli	a5,a5,0x4
  if(write)
    80006440:	0001d817          	auipc	a6,0x1d
    80006444:	bc080813          	addi	a6,a6,-1088 # 80023000 <disk>
    80006448:	00f80733          	add	a4,a6,a5
    8000644c:	01a036b3          	snez	a3,s10
    80006450:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006454:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006458:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000645c:	7679                	lui	a2,0xffffe
    8000645e:	963e                	add	a2,a2,a5
    80006460:	0001f697          	auipc	a3,0x1f
    80006464:	ba068693          	addi	a3,a3,-1120 # 80025000 <disk+0x2000>
    80006468:	6298                	ld	a4,0(a3)
    8000646a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000646c:	0a878593          	addi	a1,a5,168
    80006470:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006472:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006474:	6298                	ld	a4,0(a3)
    80006476:	9732                	add	a4,a4,a2
    80006478:	45c1                	li	a1,16
    8000647a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000647c:	6298                	ld	a4,0(a3)
    8000647e:	9732                	add	a4,a4,a2
    80006480:	4585                	li	a1,1
    80006482:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006486:	f8442703          	lw	a4,-124(s0)
    8000648a:	628c                	ld	a1,0(a3)
    8000648c:	962e                	add	a2,a2,a1
    8000648e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006492:	0712                	slli	a4,a4,0x4
    80006494:	6290                	ld	a2,0(a3)
    80006496:	963a                	add	a2,a2,a4
    80006498:	058a8593          	addi	a1,s5,88
    8000649c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000649e:	6294                	ld	a3,0(a3)
    800064a0:	96ba                	add	a3,a3,a4
    800064a2:	40000613          	li	a2,1024
    800064a6:	c690                	sw	a2,8(a3)
  if(write)
    800064a8:	e40d19e3          	bnez	s10,800062fa <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800064ac:	0001f697          	auipc	a3,0x1f
    800064b0:	b546b683          	ld	a3,-1196(a3) # 80025000 <disk+0x2000>
    800064b4:	96ba                	add	a3,a3,a4
    800064b6:	4609                	li	a2,2
    800064b8:	00c69623          	sh	a2,12(a3)
    800064bc:	b5b1                	j	80006308 <virtio_disk_rw+0xd2>

00000000800064be <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800064be:	1101                	addi	sp,sp,-32
    800064c0:	ec06                	sd	ra,24(sp)
    800064c2:	e822                	sd	s0,16(sp)
    800064c4:	e426                	sd	s1,8(sp)
    800064c6:	e04a                	sd	s2,0(sp)
    800064c8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064ca:	0001f517          	auipc	a0,0x1f
    800064ce:	c5e50513          	addi	a0,a0,-930 # 80025128 <disk+0x2128>
    800064d2:	ffffa097          	auipc	ra,0xffffa
    800064d6:	6f0080e7          	jalr	1776(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064da:	10001737          	lui	a4,0x10001
    800064de:	533c                	lw	a5,96(a4)
    800064e0:	8b8d                	andi	a5,a5,3
    800064e2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064e4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064e8:	0001f797          	auipc	a5,0x1f
    800064ec:	b1878793          	addi	a5,a5,-1256 # 80025000 <disk+0x2000>
    800064f0:	6b94                	ld	a3,16(a5)
    800064f2:	0207d703          	lhu	a4,32(a5)
    800064f6:	0026d783          	lhu	a5,2(a3)
    800064fa:	06f70163          	beq	a4,a5,8000655c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064fe:	0001d917          	auipc	s2,0x1d
    80006502:	b0290913          	addi	s2,s2,-1278 # 80023000 <disk>
    80006506:	0001f497          	auipc	s1,0x1f
    8000650a:	afa48493          	addi	s1,s1,-1286 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000650e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006512:	6898                	ld	a4,16(s1)
    80006514:	0204d783          	lhu	a5,32(s1)
    80006518:	8b9d                	andi	a5,a5,7
    8000651a:	078e                	slli	a5,a5,0x3
    8000651c:	97ba                	add	a5,a5,a4
    8000651e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006520:	20078713          	addi	a4,a5,512
    80006524:	0712                	slli	a4,a4,0x4
    80006526:	974a                	add	a4,a4,s2
    80006528:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000652c:	e731                	bnez	a4,80006578 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000652e:	20078793          	addi	a5,a5,512
    80006532:	0792                	slli	a5,a5,0x4
    80006534:	97ca                	add	a5,a5,s2
    80006536:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006538:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000653c:	ffffc097          	auipc	ra,0xffffc
    80006540:	ca4080e7          	jalr	-860(ra) # 800021e0 <wakeup>

    disk.used_idx += 1;
    80006544:	0204d783          	lhu	a5,32(s1)
    80006548:	2785                	addiw	a5,a5,1
    8000654a:	17c2                	slli	a5,a5,0x30
    8000654c:	93c1                	srli	a5,a5,0x30
    8000654e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006552:	6898                	ld	a4,16(s1)
    80006554:	00275703          	lhu	a4,2(a4)
    80006558:	faf71be3          	bne	a4,a5,8000650e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000655c:	0001f517          	auipc	a0,0x1f
    80006560:	bcc50513          	addi	a0,a0,-1076 # 80025128 <disk+0x2128>
    80006564:	ffffa097          	auipc	ra,0xffffa
    80006568:	712080e7          	jalr	1810(ra) # 80000c76 <release>
}
    8000656c:	60e2                	ld	ra,24(sp)
    8000656e:	6442                	ld	s0,16(sp)
    80006570:	64a2                	ld	s1,8(sp)
    80006572:	6902                	ld	s2,0(sp)
    80006574:	6105                	addi	sp,sp,32
    80006576:	8082                	ret
      panic("virtio_disk_intr status");
    80006578:	00002517          	auipc	a0,0x2
    8000657c:	45850513          	addi	a0,a0,1112 # 800089d0 <syscalls+0x3c0>
    80006580:	ffffa097          	auipc	ra,0xffffa
    80006584:	faa080e7          	jalr	-86(ra) # 8000052a <panic>
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
