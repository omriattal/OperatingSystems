
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
    80000068:	3ac78793          	addi	a5,a5,940 # 80006410 <timervec>
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
    80000122:	3d4080e7          	jalr	980(ra) # 800024f2 <either_copyin>
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
    800001b2:	00002097          	auipc	ra,0x2
    800001b6:	810080e7          	jalr	-2032(ra) # 800019c2 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	f2c080e7          	jalr	-212(ra) # 800020ee <sleep>
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
    80000202:	29e080e7          	jalr	670(ra) # 8000249c <either_copyout>
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
    800002e2:	26a080e7          	jalr	618(ra) # 80002548 <procdump>
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
    80000436:	e48080e7          	jalr	-440(ra) # 8000227a <wakeup>
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
    80000464:	00022797          	auipc	a5,0x22
    80000468:	8cc78793          	addi	a5,a5,-1844 # 80021d30 <devsw>
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
    80000882:	9fc080e7          	jalr	-1540(ra) # 8000227a <wakeup>
    
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
    8000090e:	7e4080e7          	jalr	2020(ra) # 800020ee <sleep>
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
    80000b60:	e4a080e7          	jalr	-438(ra) # 800019a6 <mycpu>
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
    80000b92:	e18080e7          	jalr	-488(ra) # 800019a6 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	e0c080e7          	jalr	-500(ra) # 800019a6 <mycpu>
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
    80000bb6:	df4080e7          	jalr	-524(ra) # 800019a6 <mycpu>
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
    80000bf6:	db4080e7          	jalr	-588(ra) # 800019a6 <mycpu>
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
    80000c22:	d88080e7          	jalr	-632(ra) # 800019a6 <mycpu>
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
    80000e78:	b22080e7          	jalr	-1246(ra) # 80001996 <cpuid>
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
    80000e94:	b06080e7          	jalr	-1274(ra) # 80001996 <cpuid>
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
    80000eb6:	e36080e7          	jalr	-458(ra) # 80002ce8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	596080e7          	jalr	1430(ra) # 80006450 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	0e8080e7          	jalr	232(ra) # 80001faa <scheduler>
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
    80000f26:	9c4080e7          	jalr	-1596(ra) # 800018e6 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	d96080e7          	jalr	-618(ra) # 80002cc0 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	db6080e7          	jalr	-586(ra) # 80002ce8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	500080e7          	jalr	1280(ra) # 8000643a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	50e080e7          	jalr	1294(ra) # 80006450 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	6d8080e7          	jalr	1752(ra) # 80003622 <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	d6a080e7          	jalr	-662(ra) # 80003cbc <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	d18080e7          	jalr	-744(ra) # 80004c72 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	610080e7          	jalr	1552(ra) # 80006572 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	d52080e7          	jalr	-686(ra) # 80001cbc <userinit>
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
    80001210:	644080e7          	jalr	1604(ra) # 80001850 <proc_mapstacks>
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

000000008000180c <get_turn>:
struct spinlock TURNLOCK;
uint TURN = -1;
int decay_factors[] = {-253,1,3,5,7,25};

int get_turn()
{
    8000180c:	1101                	addi	sp,sp,-32
    8000180e:	ec06                	sd	ra,24(sp)
    80001810:	e822                	sd	s0,16(sp)
    80001812:	e426                	sd	s1,8(sp)
    80001814:	e04a                	sd	s2,0(sp)
    80001816:	1000                	addi	s0,sp,32
	acquire(&TURNLOCK);
    80001818:	00010917          	auipc	s2,0x10
    8000181c:	a8890913          	addi	s2,s2,-1400 # 800112a0 <TURNLOCK>
    80001820:	854a                	mv	a0,s2
    80001822:	fffff097          	auipc	ra,0xfffff
    80001826:	3a0080e7          	jalr	928(ra) # 80000bc2 <acquire>
	TURN++;
    8000182a:	00007497          	auipc	s1,0x7
    8000182e:	1ee48493          	addi	s1,s1,494 # 80008a18 <TURN>
    80001832:	409c                	lw	a5,0(s1)
    80001834:	2785                	addiw	a5,a5,1
    80001836:	c09c                	sw	a5,0(s1)
	release(&TURNLOCK);
    80001838:	854a                	mv	a0,s2
    8000183a:	fffff097          	auipc	ra,0xfffff
    8000183e:	43c080e7          	jalr	1084(ra) # 80000c76 <release>
	return TURN;
} // ADDED
    80001842:	4088                	lw	a0,0(s1)
    80001844:	60e2                	ld	ra,24(sp)
    80001846:	6442                	ld	s0,16(sp)
    80001848:	64a2                	ld	s1,8(sp)
    8000184a:	6902                	ld	s2,0(sp)
    8000184c:	6105                	addi	sp,sp,32
    8000184e:	8082                	ret

0000000080001850 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	e05a                	sd	s6,0(sp)
    80001862:	0080                	addi	s0,sp,64
    80001864:	89aa                	mv	s3,a0
	struct proc *p;

	for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00010497          	auipc	s1,0x10
    8000186a:	e8248493          	addi	s1,s1,-382 # 800116e8 <proc>
	{
		char *pa = kalloc();
		if (pa == 0)
			panic("kalloc");
		uint64 va = KSTACK((int)(p - proc));
    8000186e:	8b26                	mv	s6,s1
    80001870:	00006a97          	auipc	s5,0x6
    80001874:	790a8a93          	addi	s5,s5,1936 # 80008000 <etext>
    80001878:	04000937          	lui	s2,0x4000
    8000187c:	197d                	addi	s2,s2,-1
    8000187e:	0932                	slli	s2,s2,0xc
	for (p = proc; p < &proc[NPROC]; p++)
    80001880:	00016a17          	auipc	s4,0x16
    80001884:	268a0a13          	addi	s4,s4,616 # 80017ae8 <tickslock>
		char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	24a080e7          	jalr	586(ra) # 80000ad2 <kalloc>
    80001890:	862a                	mv	a2,a0
		if (pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
		uint64 va = KSTACK((int)(p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	8591                	srai	a1,a1,0x4
    8000189a:	000ab783          	ld	a5,0(s5)
    8000189e:	02f585b3          	mul	a1,a1,a5
    800018a2:	2585                	addiw	a1,a1,1
    800018a4:	00d5959b          	slliw	a1,a1,0xd
		kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a8:	4719                	li	a4,6
    800018aa:	6685                	lui	a3,0x1
    800018ac:	40b905b3          	sub	a1,s2,a1
    800018b0:	854e                	mv	a0,s3
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	86a080e7          	jalr	-1942(ra) # 8000111c <kvmmap>
	for (p = proc; p < &proc[NPROC]; p++)
    800018ba:	19048493          	addi	s1,s1,400
    800018be:	fd4495e3          	bne	s1,s4,80001888 <proc_mapstacks+0x38>
	}
}
    800018c2:	70e2                	ld	ra,56(sp)
    800018c4:	7442                	ld	s0,48(sp)
    800018c6:	74a2                	ld	s1,40(sp)
    800018c8:	7902                	ld	s2,32(sp)
    800018ca:	69e2                	ld	s3,24(sp)
    800018cc:	6a42                	ld	s4,16(sp)
    800018ce:	6aa2                	ld	s5,8(sp)
    800018d0:	6b02                	ld	s6,0(sp)
    800018d2:	6121                	addi	sp,sp,64
    800018d4:	8082                	ret
			panic("kalloc");
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	8ea50513          	addi	a0,a0,-1814 # 800081c0 <digits+0x180>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	c4c080e7          	jalr	-948(ra) # 8000052a <panic>

00000000800018e6 <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
	struct proc *p;

	initlock(&pid_lock, "nextpid");
    800018fa:	00007597          	auipc	a1,0x7
    800018fe:	8ce58593          	addi	a1,a1,-1842 # 800081c8 <digits+0x188>
    80001902:	00010517          	auipc	a0,0x10
    80001906:	9b650513          	addi	a0,a0,-1610 # 800112b8 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	228080e7          	jalr	552(ra) # 80000b32 <initlock>
	initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8be58593          	addi	a1,a1,-1858 # 800081d0 <digits+0x190>
    8000191a:	00010517          	auipc	a0,0x10
    8000191e:	9b650513          	addi	a0,a0,-1610 # 800112d0 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	210080e7          	jalr	528(ra) # 80000b32 <initlock>
	for (p = proc; p < &proc[NPROC]; p++)
    8000192a:	00010497          	auipc	s1,0x10
    8000192e:	dbe48493          	addi	s1,s1,-578 # 800116e8 <proc>
	{
		initlock(&p->lock, "proc");
    80001932:	00007b17          	auipc	s6,0x7
    80001936:	8aeb0b13          	addi	s6,s6,-1874 # 800081e0 <digits+0x1a0>
		p->kstack = KSTACK((int)(p - proc));
    8000193a:	8aa6                	mv	s5,s1
    8000193c:	00006a17          	auipc	s4,0x6
    80001940:	6c4a0a13          	addi	s4,s4,1732 # 80008000 <etext>
    80001944:	04000937          	lui	s2,0x4000
    80001948:	197d                	addi	s2,s2,-1
    8000194a:	0932                	slli	s2,s2,0xc
	for (p = proc; p < &proc[NPROC]; p++)
    8000194c:	00016997          	auipc	s3,0x16
    80001950:	19c98993          	addi	s3,s3,412 # 80017ae8 <tickslock>
		initlock(&p->lock, "proc");
    80001954:	85da                	mv	a1,s6
    80001956:	8526                	mv	a0,s1
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	1da080e7          	jalr	474(ra) # 80000b32 <initlock>
		p->kstack = KSTACK((int)(p - proc));
    80001960:	415487b3          	sub	a5,s1,s5
    80001964:	8791                	srai	a5,a5,0x4
    80001966:	000a3703          	ld	a4,0(s4)
    8000196a:	02e787b3          	mul	a5,a5,a4
    8000196e:	2785                	addiw	a5,a5,1
    80001970:	00d7979b          	slliw	a5,a5,0xd
    80001974:	40f907b3          	sub	a5,s2,a5
    80001978:	f4bc                	sd	a5,104(s1)
	for (p = proc; p < &proc[NPROC]; p++)
    8000197a:	19048493          	addi	s1,s1,400
    8000197e:	fd349be3          	bne	s1,s3,80001954 <procinit+0x6e>
	}
}
    80001982:	70e2                	ld	ra,56(sp)
    80001984:	7442                	ld	s0,48(sp)
    80001986:	74a2                	ld	s1,40(sp)
    80001988:	7902                	ld	s2,32(sp)
    8000198a:	69e2                	ld	s3,24(sp)
    8000198c:	6a42                	ld	s4,16(sp)
    8000198e:	6aa2                	ld	s5,8(sp)
    80001990:	6b02                	ld	s6,0(sp)
    80001992:	6121                	addi	sp,sp,64
    80001994:	8082                	ret

0000000080001996 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001996:	1141                	addi	sp,sp,-16
    80001998:	e422                	sd	s0,8(sp)
    8000199a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000199c:	8512                	mv	a0,tp
	int id = r_tp();
	return id;
}
    8000199e:	2501                	sext.w	a0,a0
    800019a0:	6422                	ld	s0,8(sp)
    800019a2:	0141                	addi	sp,sp,16
    800019a4:	8082                	ret

00000000800019a6 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    800019a6:	1141                	addi	sp,sp,-16
    800019a8:	e422                	sd	s0,8(sp)
    800019aa:	0800                	addi	s0,sp,16
    800019ac:	8792                	mv	a5,tp
	int id = cpuid();
	struct cpu *c = &cpus[id];
    800019ae:	2781                	sext.w	a5,a5
    800019b0:	079e                	slli	a5,a5,0x7
	return c;
}
    800019b2:	00010517          	auipc	a0,0x10
    800019b6:	93650513          	addi	a0,a0,-1738 # 800112e8 <cpus>
    800019ba:	953e                	add	a0,a0,a5
    800019bc:	6422                	ld	s0,8(sp)
    800019be:	0141                	addi	sp,sp,16
    800019c0:	8082                	ret

00000000800019c2 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019c2:	1101                	addi	sp,sp,-32
    800019c4:	ec06                	sd	ra,24(sp)
    800019c6:	e822                	sd	s0,16(sp)
    800019c8:	e426                	sd	s1,8(sp)
    800019ca:	1000                	addi	s0,sp,32
	push_off();
    800019cc:	fffff097          	auipc	ra,0xfffff
    800019d0:	1aa080e7          	jalr	426(ra) # 80000b76 <push_off>
    800019d4:	8792                	mv	a5,tp
	struct cpu *c = mycpu();
	struct proc *p = c->proc;
    800019d6:	2781                	sext.w	a5,a5
    800019d8:	079e                	slli	a5,a5,0x7
    800019da:	00010717          	auipc	a4,0x10
    800019de:	8c670713          	addi	a4,a4,-1850 # 800112a0 <TURNLOCK>
    800019e2:	97ba                	add	a5,a5,a4
    800019e4:	67a4                	ld	s1,72(a5)
	pop_off();
    800019e6:	fffff097          	auipc	ra,0xfffff
    800019ea:	230080e7          	jalr	560(ra) # 80000c16 <pop_off>
	return p;
}
    800019ee:	8526                	mv	a0,s1
    800019f0:	60e2                	ld	ra,24(sp)
    800019f2:	6442                	ld	s0,16(sp)
    800019f4:	64a2                	ld	s1,8(sp)
    800019f6:	6105                	addi	sp,sp,32
    800019f8:	8082                	ret

00000000800019fa <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019fa:	1141                	addi	sp,sp,-16
    800019fc:	e406                	sd	ra,8(sp)
    800019fe:	e022                	sd	s0,0(sp)
    80001a00:	0800                	addi	s0,sp,16
	static int first = 1;

	// Still holding p->lock from scheduler.
	release(&myproc()->lock);
    80001a02:	00000097          	auipc	ra,0x0
    80001a06:	fc0080e7          	jalr	-64(ra) # 800019c2 <myproc>
    80001a0a:	fffff097          	auipc	ra,0xfffff
    80001a0e:	26c080e7          	jalr	620(ra) # 80000c76 <release>

	if (first)
    80001a12:	00007797          	auipc	a5,0x7
    80001a16:	ffe7a783          	lw	a5,-2(a5) # 80008a10 <first.1>
    80001a1a:	eb89                	bnez	a5,80001a2c <forkret+0x32>
		// be run from main().
		first = 0;
		fsinit(ROOTDEV);
	}

	usertrapret();
    80001a1c:	00001097          	auipc	ra,0x1
    80001a20:	2e4080e7          	jalr	740(ra) # 80002d00 <usertrapret>
}
    80001a24:	60a2                	ld	ra,8(sp)
    80001a26:	6402                	ld	s0,0(sp)
    80001a28:	0141                	addi	sp,sp,16
    80001a2a:	8082                	ret
		first = 0;
    80001a2c:	00007797          	auipc	a5,0x7
    80001a30:	fe07a223          	sw	zero,-28(a5) # 80008a10 <first.1>
		fsinit(ROOTDEV);
    80001a34:	4505                	li	a0,1
    80001a36:	00002097          	auipc	ra,0x2
    80001a3a:	206080e7          	jalr	518(ra) # 80003c3c <fsinit>
    80001a3e:	bff9                	j	80001a1c <forkret+0x22>

0000000080001a40 <allocpid>:
{
    80001a40:	1101                	addi	sp,sp,-32
    80001a42:	ec06                	sd	ra,24(sp)
    80001a44:	e822                	sd	s0,16(sp)
    80001a46:	e426                	sd	s1,8(sp)
    80001a48:	e04a                	sd	s2,0(sp)
    80001a4a:	1000                	addi	s0,sp,32
	acquire(&pid_lock);
    80001a4c:	00010917          	auipc	s2,0x10
    80001a50:	86c90913          	addi	s2,s2,-1940 # 800112b8 <pid_lock>
    80001a54:	854a                	mv	a0,s2
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	16c080e7          	jalr	364(ra) # 80000bc2 <acquire>
	pid = nextpid;
    80001a5e:	00007797          	auipc	a5,0x7
    80001a62:	fb678793          	addi	a5,a5,-74 # 80008a14 <nextpid>
    80001a66:	4384                	lw	s1,0(a5)
	nextpid = nextpid + 1;
    80001a68:	0014871b          	addiw	a4,s1,1
    80001a6c:	c398                	sw	a4,0(a5)
	release(&pid_lock);
    80001a6e:	854a                	mv	a0,s2
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	206080e7          	jalr	518(ra) # 80000c76 <release>
}
    80001a78:	8526                	mv	a0,s1
    80001a7a:	60e2                	ld	ra,24(sp)
    80001a7c:	6442                	ld	s0,16(sp)
    80001a7e:	64a2                	ld	s1,8(sp)
    80001a80:	6902                	ld	s2,0(sp)
    80001a82:	6105                	addi	sp,sp,32
    80001a84:	8082                	ret

0000000080001a86 <proc_pagetable>:
{
    80001a86:	1101                	addi	sp,sp,-32
    80001a88:	ec06                	sd	ra,24(sp)
    80001a8a:	e822                	sd	s0,16(sp)
    80001a8c:	e426                	sd	s1,8(sp)
    80001a8e:	e04a                	sd	s2,0(sp)
    80001a90:	1000                	addi	s0,sp,32
    80001a92:	892a                	mv	s2,a0
	pagetable = uvmcreate();
    80001a94:	00000097          	auipc	ra,0x0
    80001a98:	872080e7          	jalr	-1934(ra) # 80001306 <uvmcreate>
    80001a9c:	84aa                	mv	s1,a0
	if (pagetable == 0)
    80001a9e:	c121                	beqz	a0,80001ade <proc_pagetable+0x58>
	if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa0:	4729                	li	a4,10
    80001aa2:	00005697          	auipc	a3,0x5
    80001aa6:	55e68693          	addi	a3,a3,1374 # 80007000 <_trampoline>
    80001aaa:	6605                	lui	a2,0x1
    80001aac:	040005b7          	lui	a1,0x4000
    80001ab0:	15fd                	addi	a1,a1,-1
    80001ab2:	05b2                	slli	a1,a1,0xc
    80001ab4:	fffff097          	auipc	ra,0xfffff
    80001ab8:	5da080e7          	jalr	1498(ra) # 8000108e <mappages>
    80001abc:	02054863          	bltz	a0,80001aec <proc_pagetable+0x66>
	if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac0:	4719                	li	a4,6
    80001ac2:	08093683          	ld	a3,128(s2)
    80001ac6:	6605                	lui	a2,0x1
    80001ac8:	020005b7          	lui	a1,0x2000
    80001acc:	15fd                	addi	a1,a1,-1
    80001ace:	05b6                	slli	a1,a1,0xd
    80001ad0:	8526                	mv	a0,s1
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	5bc080e7          	jalr	1468(ra) # 8000108e <mappages>
    80001ada:	02054163          	bltz	a0,80001afc <proc_pagetable+0x76>
}
    80001ade:	8526                	mv	a0,s1
    80001ae0:	60e2                	ld	ra,24(sp)
    80001ae2:	6442                	ld	s0,16(sp)
    80001ae4:	64a2                	ld	s1,8(sp)
    80001ae6:	6902                	ld	s2,0(sp)
    80001ae8:	6105                	addi	sp,sp,32
    80001aea:	8082                	ret
		uvmfree(pagetable, 0);
    80001aec:	4581                	li	a1,0
    80001aee:	8526                	mv	a0,s1
    80001af0:	00000097          	auipc	ra,0x0
    80001af4:	a12080e7          	jalr	-1518(ra) # 80001502 <uvmfree>
		return 0;
    80001af8:	4481                	li	s1,0
    80001afa:	b7d5                	j	80001ade <proc_pagetable+0x58>
		uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001afc:	4681                	li	a3,0
    80001afe:	4605                	li	a2,1
    80001b00:	040005b7          	lui	a1,0x4000
    80001b04:	15fd                	addi	a1,a1,-1
    80001b06:	05b2                	slli	a1,a1,0xc
    80001b08:	8526                	mv	a0,s1
    80001b0a:	fffff097          	auipc	ra,0xfffff
    80001b0e:	738080e7          	jalr	1848(ra) # 80001242 <uvmunmap>
		uvmfree(pagetable, 0);
    80001b12:	4581                	li	a1,0
    80001b14:	8526                	mv	a0,s1
    80001b16:	00000097          	auipc	ra,0x0
    80001b1a:	9ec080e7          	jalr	-1556(ra) # 80001502 <uvmfree>
		return 0;
    80001b1e:	4481                	li	s1,0
    80001b20:	bf7d                	j	80001ade <proc_pagetable+0x58>

0000000080001b22 <proc_freepagetable>:
{
    80001b22:	1101                	addi	sp,sp,-32
    80001b24:	ec06                	sd	ra,24(sp)
    80001b26:	e822                	sd	s0,16(sp)
    80001b28:	e426                	sd	s1,8(sp)
    80001b2a:	e04a                	sd	s2,0(sp)
    80001b2c:	1000                	addi	s0,sp,32
    80001b2e:	84aa                	mv	s1,a0
    80001b30:	892e                	mv	s2,a1
	uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b32:	4681                	li	a3,0
    80001b34:	4605                	li	a2,1
    80001b36:	040005b7          	lui	a1,0x4000
    80001b3a:	15fd                	addi	a1,a1,-1
    80001b3c:	05b2                	slli	a1,a1,0xc
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	704080e7          	jalr	1796(ra) # 80001242 <uvmunmap>
	uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b46:	4681                	li	a3,0
    80001b48:	4605                	li	a2,1
    80001b4a:	020005b7          	lui	a1,0x2000
    80001b4e:	15fd                	addi	a1,a1,-1
    80001b50:	05b6                	slli	a1,a1,0xd
    80001b52:	8526                	mv	a0,s1
    80001b54:	fffff097          	auipc	ra,0xfffff
    80001b58:	6ee080e7          	jalr	1774(ra) # 80001242 <uvmunmap>
	uvmfree(pagetable, sz);
    80001b5c:	85ca                	mv	a1,s2
    80001b5e:	8526                	mv	a0,s1
    80001b60:	00000097          	auipc	ra,0x0
    80001b64:	9a2080e7          	jalr	-1630(ra) # 80001502 <uvmfree>
}
    80001b68:	60e2                	ld	ra,24(sp)
    80001b6a:	6442                	ld	s0,16(sp)
    80001b6c:	64a2                	ld	s1,8(sp)
    80001b6e:	6902                	ld	s2,0(sp)
    80001b70:	6105                	addi	sp,sp,32
    80001b72:	8082                	ret

0000000080001b74 <freeproc>:
{
    80001b74:	1101                	addi	sp,sp,-32
    80001b76:	ec06                	sd	ra,24(sp)
    80001b78:	e822                	sd	s0,16(sp)
    80001b7a:	e426                	sd	s1,8(sp)
    80001b7c:	1000                	addi	s0,sp,32
    80001b7e:	84aa                	mv	s1,a0
	if (p->trapframe)
    80001b80:	6148                	ld	a0,128(a0)
    80001b82:	c509                	beqz	a0,80001b8c <freeproc+0x18>
		kfree((void *)p->trapframe);
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	e52080e7          	jalr	-430(ra) # 800009d6 <kfree>
	p->trapframe = 0;
    80001b8c:	0804b023          	sd	zero,128(s1)
	if (p->pagetable)
    80001b90:	7ca8                	ld	a0,120(s1)
    80001b92:	c511                	beqz	a0,80001b9e <freeproc+0x2a>
		proc_freepagetable(p->pagetable, p->sz);
    80001b94:	78ac                	ld	a1,112(s1)
    80001b96:	00000097          	auipc	ra,0x0
    80001b9a:	f8c080e7          	jalr	-116(ra) # 80001b22 <proc_freepagetable>
	p->pagetable = 0;
    80001b9e:	0604bc23          	sd	zero,120(s1)
	p->sz = 0;
    80001ba2:	0604b823          	sd	zero,112(s1)
	p->pid = 0;
    80001ba6:	0204a823          	sw	zero,48(s1)
	p->parent = 0;
    80001baa:	0604b023          	sd	zero,96(s1)
	p->name[0] = 0;
    80001bae:	18048023          	sb	zero,384(s1)
	p->chan = 0;
    80001bb2:	0204b023          	sd	zero,32(s1)
	p->killed = 0;
    80001bb6:	0204a423          	sw	zero,40(s1)
	p->xstate = 0;
    80001bba:	0204a623          	sw	zero,44(s1)
	p->state = UNUSED;
    80001bbe:	0004ac23          	sw	zero,24(s1)
}
    80001bc2:	60e2                	ld	ra,24(sp)
    80001bc4:	6442                	ld	s0,16(sp)
    80001bc6:	64a2                	ld	s1,8(sp)
    80001bc8:	6105                	addi	sp,sp,32
    80001bca:	8082                	ret

0000000080001bcc <allocproc>:
{
    80001bcc:	1101                	addi	sp,sp,-32
    80001bce:	ec06                	sd	ra,24(sp)
    80001bd0:	e822                	sd	s0,16(sp)
    80001bd2:	e426                	sd	s1,8(sp)
    80001bd4:	e04a                	sd	s2,0(sp)
    80001bd6:	1000                	addi	s0,sp,32
	for (p = proc; p < &proc[NPROC]; p++)
    80001bd8:	00010497          	auipc	s1,0x10
    80001bdc:	b1048493          	addi	s1,s1,-1264 # 800116e8 <proc>
    80001be0:	00016917          	auipc	s2,0x16
    80001be4:	f0890913          	addi	s2,s2,-248 # 80017ae8 <tickslock>
		acquire(&p->lock);
    80001be8:	8526                	mv	a0,s1
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	fd8080e7          	jalr	-40(ra) # 80000bc2 <acquire>
		if (p->state == UNUSED)
    80001bf2:	4c9c                	lw	a5,24(s1)
    80001bf4:	cf81                	beqz	a5,80001c0c <allocproc+0x40>
			release(&p->lock);
    80001bf6:	8526                	mv	a0,s1
    80001bf8:	fffff097          	auipc	ra,0xfffff
    80001bfc:	07e080e7          	jalr	126(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80001c00:	19048493          	addi	s1,s1,400
    80001c04:	ff2492e3          	bne	s1,s2,80001be8 <allocproc+0x1c>
	return 0;
    80001c08:	4481                	li	s1,0
    80001c0a:	a895                	j	80001c7e <allocproc+0xb2>
	p->pid = allocpid();
    80001c0c:	00000097          	auipc	ra,0x0
    80001c10:	e34080e7          	jalr	-460(ra) # 80001a40 <allocpid>
    80001c14:	d888                	sw	a0,48(s1)
	p->state = USED;
    80001c16:	4785                	li	a5,1
    80001c18:	cc9c                	sw	a5,24(s1)
	p->performance.ctime = ticks;
    80001c1a:	00007797          	auipc	a5,0x7
    80001c1e:	4167a783          	lw	a5,1046(a5) # 80009030 <ticks>
    80001c22:	dc9c                	sw	a5,56(s1)
	p->performance.ttime = -1;
    80001c24:	57fd                	li	a5,-1
    80001c26:	dcdc                	sw	a5,60(s1)
	p->turn = get_turn();
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	be4080e7          	jalr	-1052(ra) # 8000180c <get_turn>
    80001c30:	c8a8                	sw	a0,80(s1)
	p->performance.average_bursttime = QUANTUM * 100;
    80001c32:	1f400793          	li	a5,500
    80001c36:	c4fc                	sw	a5,76(s1)
	p->priority = P_NORMAL;
    80001c38:	478d                	li	a5,3
    80001c3a:	ccbc                	sw	a5,88(s1)
	if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c3c:	fffff097          	auipc	ra,0xfffff
    80001c40:	e96080e7          	jalr	-362(ra) # 80000ad2 <kalloc>
    80001c44:	892a                	mv	s2,a0
    80001c46:	e0c8                	sd	a0,128(s1)
    80001c48:	c131                	beqz	a0,80001c8c <allocproc+0xc0>
	p->pagetable = proc_pagetable(p);
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	00000097          	auipc	ra,0x0
    80001c50:	e3a080e7          	jalr	-454(ra) # 80001a86 <proc_pagetable>
    80001c54:	892a                	mv	s2,a0
    80001c56:	fca8                	sd	a0,120(s1)
	if (p->pagetable == 0)
    80001c58:	c531                	beqz	a0,80001ca4 <allocproc+0xd8>
	memset(&p->context, 0, sizeof(p->context));
    80001c5a:	07000613          	li	a2,112
    80001c5e:	4581                	li	a1,0
    80001c60:	08848513          	addi	a0,s1,136
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	05a080e7          	jalr	90(ra) # 80000cbe <memset>
	p->context.ra = (uint64)forkret;
    80001c6c:	00000797          	auipc	a5,0x0
    80001c70:	d8e78793          	addi	a5,a5,-626 # 800019fa <forkret>
    80001c74:	e4dc                	sd	a5,136(s1)
	p->context.sp = p->kstack + PGSIZE;
    80001c76:	74bc                	ld	a5,104(s1)
    80001c78:	6705                	lui	a4,0x1
    80001c7a:	97ba                	add	a5,a5,a4
    80001c7c:	e8dc                	sd	a5,144(s1)
}
    80001c7e:	8526                	mv	a0,s1
    80001c80:	60e2                	ld	ra,24(sp)
    80001c82:	6442                	ld	s0,16(sp)
    80001c84:	64a2                	ld	s1,8(sp)
    80001c86:	6902                	ld	s2,0(sp)
    80001c88:	6105                	addi	sp,sp,32
    80001c8a:	8082                	ret
		freeproc(p);
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	ee6080e7          	jalr	-282(ra) # 80001b74 <freeproc>
		release(&p->lock);
    80001c96:	8526                	mv	a0,s1
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	fde080e7          	jalr	-34(ra) # 80000c76 <release>
		return 0;
    80001ca0:	84ca                	mv	s1,s2
    80001ca2:	bff1                	j	80001c7e <allocproc+0xb2>
		freeproc(p);
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	ece080e7          	jalr	-306(ra) # 80001b74 <freeproc>
		release(&p->lock);
    80001cae:	8526                	mv	a0,s1
    80001cb0:	fffff097          	auipc	ra,0xfffff
    80001cb4:	fc6080e7          	jalr	-58(ra) # 80000c76 <release>
		return 0;
    80001cb8:	84ca                	mv	s1,s2
    80001cba:	b7d1                	j	80001c7e <allocproc+0xb2>

0000000080001cbc <userinit>:
{
    80001cbc:	1101                	addi	sp,sp,-32
    80001cbe:	ec06                	sd	ra,24(sp)
    80001cc0:	e822                	sd	s0,16(sp)
    80001cc2:	e426                	sd	s1,8(sp)
    80001cc4:	1000                	addi	s0,sp,32
	p = allocproc();
    80001cc6:	00000097          	auipc	ra,0x0
    80001cca:	f06080e7          	jalr	-250(ra) # 80001bcc <allocproc>
    80001cce:	84aa                	mv	s1,a0
	initproc = p;
    80001cd0:	00007797          	auipc	a5,0x7
    80001cd4:	34a7bc23          	sd	a0,856(a5) # 80009028 <initproc>
	uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cd8:	03400613          	li	a2,52
    80001cdc:	00007597          	auipc	a1,0x7
    80001ce0:	d4458593          	addi	a1,a1,-700 # 80008a20 <initcode>
    80001ce4:	7d28                	ld	a0,120(a0)
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	64e080e7          	jalr	1614(ra) # 80001334 <uvminit>
	p->sz = PGSIZE;
    80001cee:	6785                	lui	a5,0x1
    80001cf0:	f8bc                	sd	a5,112(s1)
	p->trapframe->epc = 0;	   // user program counter
    80001cf2:	60d8                	ld	a4,128(s1)
    80001cf4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
	p->trapframe->sp = PGSIZE; // user stack pointer
    80001cf8:	60d8                	ld	a4,128(s1)
    80001cfa:	fb1c                	sd	a5,48(a4)
	safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cfc:	4641                	li	a2,16
    80001cfe:	00006597          	auipc	a1,0x6
    80001d02:	4ea58593          	addi	a1,a1,1258 # 800081e8 <digits+0x1a8>
    80001d06:	18048513          	addi	a0,s1,384
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	106080e7          	jalr	262(ra) # 80000e10 <safestrcpy>
	p->cwd = namei("/");
    80001d12:	00006517          	auipc	a0,0x6
    80001d16:	4e650513          	addi	a0,a0,1254 # 800081f8 <digits+0x1b8>
    80001d1a:	00003097          	auipc	ra,0x3
    80001d1e:	950080e7          	jalr	-1712(ra) # 8000466a <namei>
    80001d22:	16a4bc23          	sd	a0,376(s1)
	p->state = RUNNABLE;
    80001d26:	478d                	li	a5,3
    80001d28:	cc9c                	sw	a5,24(s1)
	release(&p->lock);
    80001d2a:	8526                	mv	a0,s1
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	f4a080e7          	jalr	-182(ra) # 80000c76 <release>
}
    80001d34:	60e2                	ld	ra,24(sp)
    80001d36:	6442                	ld	s0,16(sp)
    80001d38:	64a2                	ld	s1,8(sp)
    80001d3a:	6105                	addi	sp,sp,32
    80001d3c:	8082                	ret

0000000080001d3e <growproc>:
{
    80001d3e:	1101                	addi	sp,sp,-32
    80001d40:	ec06                	sd	ra,24(sp)
    80001d42:	e822                	sd	s0,16(sp)
    80001d44:	e426                	sd	s1,8(sp)
    80001d46:	e04a                	sd	s2,0(sp)
    80001d48:	1000                	addi	s0,sp,32
    80001d4a:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    80001d4c:	00000097          	auipc	ra,0x0
    80001d50:	c76080e7          	jalr	-906(ra) # 800019c2 <myproc>
    80001d54:	892a                	mv	s2,a0
	sz = p->sz;
    80001d56:	792c                	ld	a1,112(a0)
    80001d58:	0005861b          	sext.w	a2,a1
	if (n > 0)
    80001d5c:	00904f63          	bgtz	s1,80001d7a <growproc+0x3c>
	else if (n < 0)
    80001d60:	0204cc63          	bltz	s1,80001d98 <growproc+0x5a>
	p->sz = sz;
    80001d64:	1602                	slli	a2,a2,0x20
    80001d66:	9201                	srli	a2,a2,0x20
    80001d68:	06c93823          	sd	a2,112(s2)
	return 0;
    80001d6c:	4501                	li	a0,0
}
    80001d6e:	60e2                	ld	ra,24(sp)
    80001d70:	6442                	ld	s0,16(sp)
    80001d72:	64a2                	ld	s1,8(sp)
    80001d74:	6902                	ld	s2,0(sp)
    80001d76:	6105                	addi	sp,sp,32
    80001d78:	8082                	ret
		if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001d7a:	9e25                	addw	a2,a2,s1
    80001d7c:	1602                	slli	a2,a2,0x20
    80001d7e:	9201                	srli	a2,a2,0x20
    80001d80:	1582                	slli	a1,a1,0x20
    80001d82:	9181                	srli	a1,a1,0x20
    80001d84:	7d28                	ld	a0,120(a0)
    80001d86:	fffff097          	auipc	ra,0xfffff
    80001d8a:	668080e7          	jalr	1640(ra) # 800013ee <uvmalloc>
    80001d8e:	0005061b          	sext.w	a2,a0
    80001d92:	fa69                	bnez	a2,80001d64 <growproc+0x26>
			return -1;
    80001d94:	557d                	li	a0,-1
    80001d96:	bfe1                	j	80001d6e <growproc+0x30>
		sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d98:	9e25                	addw	a2,a2,s1
    80001d9a:	1602                	slli	a2,a2,0x20
    80001d9c:	9201                	srli	a2,a2,0x20
    80001d9e:	1582                	slli	a1,a1,0x20
    80001da0:	9181                	srli	a1,a1,0x20
    80001da2:	7d28                	ld	a0,120(a0)
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	602080e7          	jalr	1538(ra) # 800013a6 <uvmdealloc>
    80001dac:	0005061b          	sext.w	a2,a0
    80001db0:	bf55                	j	80001d64 <growproc+0x26>

0000000080001db2 <fork>:
{
    80001db2:	7139                	addi	sp,sp,-64
    80001db4:	fc06                	sd	ra,56(sp)
    80001db6:	f822                	sd	s0,48(sp)
    80001db8:	f426                	sd	s1,40(sp)
    80001dba:	f04a                	sd	s2,32(sp)
    80001dbc:	ec4e                	sd	s3,24(sp)
    80001dbe:	e852                	sd	s4,16(sp)
    80001dc0:	e456                	sd	s5,8(sp)
    80001dc2:	0080                	addi	s0,sp,64
	struct proc *p = myproc();
    80001dc4:	00000097          	auipc	ra,0x0
    80001dc8:	bfe080e7          	jalr	-1026(ra) # 800019c2 <myproc>
    80001dcc:	8aaa                	mv	s5,a0
	if ((np = allocproc()) == 0)
    80001dce:	00000097          	auipc	ra,0x0
    80001dd2:	dfe080e7          	jalr	-514(ra) # 80001bcc <allocproc>
    80001dd6:	12050463          	beqz	a0,80001efe <fork+0x14c>
    80001dda:	89aa                	mv	s3,a0
	if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001ddc:	070ab603          	ld	a2,112(s5)
    80001de0:	7d2c                	ld	a1,120(a0)
    80001de2:	078ab503          	ld	a0,120(s5)
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	754080e7          	jalr	1876(ra) # 8000153a <uvmcopy>
    80001dee:	04054863          	bltz	a0,80001e3e <fork+0x8c>
	np->sz = p->sz;
    80001df2:	070ab783          	ld	a5,112(s5)
    80001df6:	06f9b823          	sd	a5,112(s3)
	*(np->trapframe) = *(p->trapframe);
    80001dfa:	080ab683          	ld	a3,128(s5)
    80001dfe:	87b6                	mv	a5,a3
    80001e00:	0809b703          	ld	a4,128(s3)
    80001e04:	12068693          	addi	a3,a3,288
    80001e08:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e0c:	6788                	ld	a0,8(a5)
    80001e0e:	6b8c                	ld	a1,16(a5)
    80001e10:	6f90                	ld	a2,24(a5)
    80001e12:	01073023          	sd	a6,0(a4)
    80001e16:	e708                	sd	a0,8(a4)
    80001e18:	eb0c                	sd	a1,16(a4)
    80001e1a:	ef10                	sd	a2,24(a4)
    80001e1c:	02078793          	addi	a5,a5,32
    80001e20:	02070713          	addi	a4,a4,32
    80001e24:	fed792e3          	bne	a5,a3,80001e08 <fork+0x56>
	np->trapframe->a0 = 0;
    80001e28:	0809b783          	ld	a5,128(s3)
    80001e2c:	0607b823          	sd	zero,112(a5)
	for (i = 0; i < NOFILE; i++)
    80001e30:	0f8a8493          	addi	s1,s5,248
    80001e34:	0f898913          	addi	s2,s3,248
    80001e38:	178a8a13          	addi	s4,s5,376
    80001e3c:	a00d                	j	80001e5e <fork+0xac>
		freeproc(np);
    80001e3e:	854e                	mv	a0,s3
    80001e40:	00000097          	auipc	ra,0x0
    80001e44:	d34080e7          	jalr	-716(ra) # 80001b74 <freeproc>
		release(&np->lock);
    80001e48:	854e                	mv	a0,s3
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	e2c080e7          	jalr	-468(ra) # 80000c76 <release>
		return -1;
    80001e52:	597d                	li	s2,-1
    80001e54:	a859                	j	80001eea <fork+0x138>
	for (i = 0; i < NOFILE; i++)
    80001e56:	04a1                	addi	s1,s1,8
    80001e58:	0921                	addi	s2,s2,8
    80001e5a:	01448b63          	beq	s1,s4,80001e70 <fork+0xbe>
		if (p->ofile[i])
    80001e5e:	6088                	ld	a0,0(s1)
    80001e60:	d97d                	beqz	a0,80001e56 <fork+0xa4>
			np->ofile[i] = filedup(p->ofile[i]);
    80001e62:	00003097          	auipc	ra,0x3
    80001e66:	ea2080e7          	jalr	-350(ra) # 80004d04 <filedup>
    80001e6a:	00a93023          	sd	a0,0(s2)
    80001e6e:	b7e5                	j	80001e56 <fork+0xa4>
	np->cwd = idup(p->cwd);
    80001e70:	178ab503          	ld	a0,376(s5)
    80001e74:	00002097          	auipc	ra,0x2
    80001e78:	002080e7          	jalr	2(ra) # 80003e76 <idup>
    80001e7c:	16a9bc23          	sd	a0,376(s3)
	safestrcpy(np->name, p->name, sizeof(p->name));
    80001e80:	4641                	li	a2,16
    80001e82:	180a8593          	addi	a1,s5,384
    80001e86:	18098513          	addi	a0,s3,384
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	f86080e7          	jalr	-122(ra) # 80000e10 <safestrcpy>
	pid = np->pid;
    80001e92:	0309a903          	lw	s2,48(s3)
	release(&np->lock);
    80001e96:	854e                	mv	a0,s3
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	dde080e7          	jalr	-546(ra) # 80000c76 <release>
	acquire(&wait_lock);
    80001ea0:	0000f497          	auipc	s1,0xf
    80001ea4:	43048493          	addi	s1,s1,1072 # 800112d0 <wait_lock>
    80001ea8:	8526                	mv	a0,s1
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	d18080e7          	jalr	-744(ra) # 80000bc2 <acquire>
	np->parent = p;
    80001eb2:	0759b023          	sd	s5,96(s3)
	np->trace_mask = p->trace_mask; // ADDED: copying trace mask in fork
    80001eb6:	034aa783          	lw	a5,52(s5)
    80001eba:	02f9aa23          	sw	a5,52(s3)
	np->priority = p->priority; // ADDED: copying priority in fork
    80001ebe:	058aa783          	lw	a5,88(s5)
    80001ec2:	04f9ac23          	sw	a5,88(s3)
	release(&wait_lock);
    80001ec6:	8526                	mv	a0,s1
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	dae080e7          	jalr	-594(ra) # 80000c76 <release>
	acquire(&np->lock);
    80001ed0:	854e                	mv	a0,s3
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	cf0080e7          	jalr	-784(ra) # 80000bc2 <acquire>
	np->state = RUNNABLE;
    80001eda:	478d                	li	a5,3
    80001edc:	00f9ac23          	sw	a5,24(s3)
	release(&np->lock);
    80001ee0:	854e                	mv	a0,s3
    80001ee2:	fffff097          	auipc	ra,0xfffff
    80001ee6:	d94080e7          	jalr	-620(ra) # 80000c76 <release>
}
    80001eea:	854a                	mv	a0,s2
    80001eec:	70e2                	ld	ra,56(sp)
    80001eee:	7442                	ld	s0,48(sp)
    80001ef0:	74a2                	ld	s1,40(sp)
    80001ef2:	7902                	ld	s2,32(sp)
    80001ef4:	69e2                	ld	s3,24(sp)
    80001ef6:	6a42                	ld	s4,16(sp)
    80001ef8:	6aa2                	ld	s5,8(sp)
    80001efa:	6121                	addi	sp,sp,64
    80001efc:	8082                	ret
		return -1;
    80001efe:	597d                	li	s2,-1
    80001f00:	b7ed                	j	80001eea <fork+0x138>

0000000080001f02 <sched_default>:
{
    80001f02:	7139                	addi	sp,sp,-64
    80001f04:	fc06                	sd	ra,56(sp)
    80001f06:	f822                	sd	s0,48(sp)
    80001f08:	f426                	sd	s1,40(sp)
    80001f0a:	f04a                	sd	s2,32(sp)
    80001f0c:	ec4e                	sd	s3,24(sp)
    80001f0e:	e852                	sd	s4,16(sp)
    80001f10:	e456                	sd	s5,8(sp)
    80001f12:	e05a                	sd	s6,0(sp)
    80001f14:	0080                	addi	s0,sp,64
    80001f16:	8792                	mv	a5,tp
	int id = r_tp();
    80001f18:	2781                	sext.w	a5,a5
	c->proc = 0;
    80001f1a:	00779a93          	slli	s5,a5,0x7
    80001f1e:	0000f717          	auipc	a4,0xf
    80001f22:	38270713          	addi	a4,a4,898 # 800112a0 <TURNLOCK>
    80001f26:	9756                	add	a4,a4,s5
    80001f28:	04073423          	sd	zero,72(a4)
			swtch(&c->context,&p->context);
    80001f2c:	0000f717          	auipc	a4,0xf
    80001f30:	3c470713          	addi	a4,a4,964 # 800112f0 <cpus+0x8>
    80001f34:	9aba                	add	s5,s5,a4
	for (p = proc; p < &proc[NPROC]; p++)
    80001f36:	0000f497          	auipc	s1,0xf
    80001f3a:	7b248493          	addi	s1,s1,1970 # 800116e8 <proc>
		if (p->state == RUNNABLE)
    80001f3e:	498d                	li	s3,3
			p->state = RUNNING;
    80001f40:	4b11                	li	s6,4
			c->proc = p;
    80001f42:	079e                	slli	a5,a5,0x7
    80001f44:	0000fa17          	auipc	s4,0xf
    80001f48:	35ca0a13          	addi	s4,s4,860 # 800112a0 <TURNLOCK>
    80001f4c:	9a3e                	add	s4,s4,a5
	for (p = proc; p < &proc[NPROC]; p++)
    80001f4e:	00016917          	auipc	s2,0x16
    80001f52:	b9a90913          	addi	s2,s2,-1126 # 80017ae8 <tickslock>
    80001f56:	a811                	j	80001f6a <sched_default+0x68>
		release(&p->lock);
    80001f58:	8526                	mv	a0,s1
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	d1c080e7          	jalr	-740(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80001f62:	19048493          	addi	s1,s1,400
    80001f66:	03248863          	beq	s1,s2,80001f96 <sched_default+0x94>
		acquire(&p->lock);
    80001f6a:	8526                	mv	a0,s1
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	c56080e7          	jalr	-938(ra) # 80000bc2 <acquire>
		if (p->state == RUNNABLE)
    80001f74:	4c9c                	lw	a5,24(s1)
    80001f76:	ff3791e3          	bne	a5,s3,80001f58 <sched_default+0x56>
			p->state = RUNNING;
    80001f7a:	0164ac23          	sw	s6,24(s1)
			c->proc = p;
    80001f7e:	049a3423          	sd	s1,72(s4)
			swtch(&c->context,&p->context);
    80001f82:	08848593          	addi	a1,s1,136
    80001f86:	8556                	mv	a0,s5
    80001f88:	00001097          	auipc	ra,0x1
    80001f8c:	cce080e7          	jalr	-818(ra) # 80002c56 <swtch>
			c->proc = 0;
    80001f90:	040a3423          	sd	zero,72(s4)
    80001f94:	b7d1                	j	80001f58 <sched_default+0x56>
}
    80001f96:	70e2                	ld	ra,56(sp)
    80001f98:	7442                	ld	s0,48(sp)
    80001f9a:	74a2                	ld	s1,40(sp)
    80001f9c:	7902                	ld	s2,32(sp)
    80001f9e:	69e2                	ld	s3,24(sp)
    80001fa0:	6a42                	ld	s4,16(sp)
    80001fa2:	6aa2                	ld	s5,8(sp)
    80001fa4:	6b02                	ld	s6,0(sp)
    80001fa6:	6121                	addi	sp,sp,64
    80001fa8:	8082                	ret

0000000080001faa <scheduler>:
{
    80001faa:	1101                	addi	sp,sp,-32
    80001fac:	ec06                	sd	ra,24(sp)
    80001fae:	e822                	sd	s0,16(sp)
    80001fb0:	e426                	sd	s1,8(sp)
    80001fb2:	1000                	addi	s0,sp,32
		printf("abcd\n");
    80001fb4:	00006497          	auipc	s1,0x6
    80001fb8:	24c48493          	addi	s1,s1,588 # 80008200 <digits+0x1c0>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fbc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fc0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fc4:	10079073          	csrw	sstatus,a5
    80001fc8:	8526                	mv	a0,s1
    80001fca:	ffffe097          	auipc	ra,0xffffe
    80001fce:	5aa080e7          	jalr	1450(ra) # 80000574 <printf>
		sched_default();
    80001fd2:	00000097          	auipc	ra,0x0
    80001fd6:	f30080e7          	jalr	-208(ra) # 80001f02 <sched_default>
	for (;;)
    80001fda:	b7cd                	j	80001fbc <scheduler+0x12>

0000000080001fdc <sched>:
{
    80001fdc:	7179                	addi	sp,sp,-48
    80001fde:	f406                	sd	ra,40(sp)
    80001fe0:	f022                	sd	s0,32(sp)
    80001fe2:	ec26                	sd	s1,24(sp)
    80001fe4:	e84a                	sd	s2,16(sp)
    80001fe6:	e44e                	sd	s3,8(sp)
    80001fe8:	1800                	addi	s0,sp,48
	struct proc *p = myproc();
    80001fea:	00000097          	auipc	ra,0x0
    80001fee:	9d8080e7          	jalr	-1576(ra) # 800019c2 <myproc>
    80001ff2:	84aa                	mv	s1,a0
	if (!holding(&p->lock))
    80001ff4:	fffff097          	auipc	ra,0xfffff
    80001ff8:	b54080e7          	jalr	-1196(ra) # 80000b48 <holding>
    80001ffc:	c93d                	beqz	a0,80002072 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ffe:	8792                	mv	a5,tp
	if (mycpu()->noff != 1)
    80002000:	2781                	sext.w	a5,a5
    80002002:	079e                	slli	a5,a5,0x7
    80002004:	0000f717          	auipc	a4,0xf
    80002008:	29c70713          	addi	a4,a4,668 # 800112a0 <TURNLOCK>
    8000200c:	97ba                	add	a5,a5,a4
    8000200e:	0c07a703          	lw	a4,192(a5)
    80002012:	4785                	li	a5,1
    80002014:	06f71763          	bne	a4,a5,80002082 <sched+0xa6>
	if (p->state == RUNNING)
    80002018:	4c98                	lw	a4,24(s1)
    8000201a:	4791                	li	a5,4
    8000201c:	06f70b63          	beq	a4,a5,80002092 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002020:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002024:	8b89                	andi	a5,a5,2
	if (intr_get())
    80002026:	efb5                	bnez	a5,800020a2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002028:	8792                	mv	a5,tp
	intena = mycpu()->intena;
    8000202a:	0000f917          	auipc	s2,0xf
    8000202e:	27690913          	addi	s2,s2,630 # 800112a0 <TURNLOCK>
    80002032:	2781                	sext.w	a5,a5
    80002034:	079e                	slli	a5,a5,0x7
    80002036:	97ca                	add	a5,a5,s2
    80002038:	0c47a983          	lw	s3,196(a5)
    8000203c:	8792                	mv	a5,tp
	swtch(&p->context, &mycpu()->context);
    8000203e:	2781                	sext.w	a5,a5
    80002040:	079e                	slli	a5,a5,0x7
    80002042:	0000f597          	auipc	a1,0xf
    80002046:	2ae58593          	addi	a1,a1,686 # 800112f0 <cpus+0x8>
    8000204a:	95be                	add	a1,a1,a5
    8000204c:	08848513          	addi	a0,s1,136
    80002050:	00001097          	auipc	ra,0x1
    80002054:	c06080e7          	jalr	-1018(ra) # 80002c56 <swtch>
    80002058:	8792                	mv	a5,tp
	mycpu()->intena = intena;
    8000205a:	2781                	sext.w	a5,a5
    8000205c:	079e                	slli	a5,a5,0x7
    8000205e:	97ca                	add	a5,a5,s2
    80002060:	0d37a223          	sw	s3,196(a5)
}
    80002064:	70a2                	ld	ra,40(sp)
    80002066:	7402                	ld	s0,32(sp)
    80002068:	64e2                	ld	s1,24(sp)
    8000206a:	6942                	ld	s2,16(sp)
    8000206c:	69a2                	ld	s3,8(sp)
    8000206e:	6145                	addi	sp,sp,48
    80002070:	8082                	ret
		panic("sched p->lock");
    80002072:	00006517          	auipc	a0,0x6
    80002076:	19650513          	addi	a0,a0,406 # 80008208 <digits+0x1c8>
    8000207a:	ffffe097          	auipc	ra,0xffffe
    8000207e:	4b0080e7          	jalr	1200(ra) # 8000052a <panic>
		panic("sched locks");
    80002082:	00006517          	auipc	a0,0x6
    80002086:	19650513          	addi	a0,a0,406 # 80008218 <digits+0x1d8>
    8000208a:	ffffe097          	auipc	ra,0xffffe
    8000208e:	4a0080e7          	jalr	1184(ra) # 8000052a <panic>
		panic("sched running");
    80002092:	00006517          	auipc	a0,0x6
    80002096:	19650513          	addi	a0,a0,406 # 80008228 <digits+0x1e8>
    8000209a:	ffffe097          	auipc	ra,0xffffe
    8000209e:	490080e7          	jalr	1168(ra) # 8000052a <panic>
		panic("sched interruptible");
    800020a2:	00006517          	auipc	a0,0x6
    800020a6:	19650513          	addi	a0,a0,406 # 80008238 <digits+0x1f8>
    800020aa:	ffffe097          	auipc	ra,0xffffe
    800020ae:	480080e7          	jalr	1152(ra) # 8000052a <panic>

00000000800020b2 <yield>:
{
    800020b2:	1101                	addi	sp,sp,-32
    800020b4:	ec06                	sd	ra,24(sp)
    800020b6:	e822                	sd	s0,16(sp)
    800020b8:	e426                	sd	s1,8(sp)
    800020ba:	1000                	addi	s0,sp,32
	struct proc *p = myproc();
    800020bc:	00000097          	auipc	ra,0x0
    800020c0:	906080e7          	jalr	-1786(ra) # 800019c2 <myproc>
    800020c4:	84aa                	mv	s1,a0
	acquire(&p->lock);
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	afc080e7          	jalr	-1284(ra) # 80000bc2 <acquire>
	p->state = RUNNABLE;
    800020ce:	478d                	li	a5,3
    800020d0:	cc9c                	sw	a5,24(s1)
	sched();
    800020d2:	00000097          	auipc	ra,0x0
    800020d6:	f0a080e7          	jalr	-246(ra) # 80001fdc <sched>
	release(&p->lock);
    800020da:	8526                	mv	a0,s1
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	b9a080e7          	jalr	-1126(ra) # 80000c76 <release>
}
    800020e4:	60e2                	ld	ra,24(sp)
    800020e6:	6442                	ld	s0,16(sp)
    800020e8:	64a2                	ld	s1,8(sp)
    800020ea:	6105                	addi	sp,sp,32
    800020ec:	8082                	ret

00000000800020ee <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800020ee:	7179                	addi	sp,sp,-48
    800020f0:	f406                	sd	ra,40(sp)
    800020f2:	f022                	sd	s0,32(sp)
    800020f4:	ec26                	sd	s1,24(sp)
    800020f6:	e84a                	sd	s2,16(sp)
    800020f8:	e44e                	sd	s3,8(sp)
    800020fa:	1800                	addi	s0,sp,48
    800020fc:	89aa                	mv	s3,a0
    800020fe:	892e                	mv	s2,a1
	struct proc *p = myproc();
    80002100:	00000097          	auipc	ra,0x0
    80002104:	8c2080e7          	jalr	-1854(ra) # 800019c2 <myproc>
    80002108:	84aa                	mv	s1,a0
	// Once we hold p->lock, we can be
	// guaranteed that we won't miss any wakeup
	// (wakeup locks p->lock),
	// so it's okay to release lk.

	acquire(&p->lock); //DOC: sleeplock1
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	ab8080e7          	jalr	-1352(ra) # 80000bc2 <acquire>
	release(lk);
    80002112:	854a                	mv	a0,s2
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	b62080e7          	jalr	-1182(ra) # 80000c76 <release>

	// Go to sleep.
	p->chan = chan;
    8000211c:	0334b023          	sd	s3,32(s1)
	p->state = SLEEPING;
    80002120:	4789                	li	a5,2
    80002122:	cc9c                	sw	a5,24(s1)

	sched();
    80002124:	00000097          	auipc	ra,0x0
    80002128:	eb8080e7          	jalr	-328(ra) # 80001fdc <sched>

	// Tidy up.
	p->chan = 0;
    8000212c:	0204b023          	sd	zero,32(s1)

	// Reacquire original lock.
	release(&p->lock);
    80002130:	8526                	mv	a0,s1
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	b44080e7          	jalr	-1212(ra) # 80000c76 <release>
	acquire(lk);
    8000213a:	854a                	mv	a0,s2
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	a86080e7          	jalr	-1402(ra) # 80000bc2 <acquire>
}
    80002144:	70a2                	ld	ra,40(sp)
    80002146:	7402                	ld	s0,32(sp)
    80002148:	64e2                	ld	s1,24(sp)
    8000214a:	6942                	ld	s2,16(sp)
    8000214c:	69a2                	ld	s3,8(sp)
    8000214e:	6145                	addi	sp,sp,48
    80002150:	8082                	ret

0000000080002152 <wait>:
{
    80002152:	715d                	addi	sp,sp,-80
    80002154:	e486                	sd	ra,72(sp)
    80002156:	e0a2                	sd	s0,64(sp)
    80002158:	fc26                	sd	s1,56(sp)
    8000215a:	f84a                	sd	s2,48(sp)
    8000215c:	f44e                	sd	s3,40(sp)
    8000215e:	f052                	sd	s4,32(sp)
    80002160:	ec56                	sd	s5,24(sp)
    80002162:	e85a                	sd	s6,16(sp)
    80002164:	e45e                	sd	s7,8(sp)
    80002166:	e062                	sd	s8,0(sp)
    80002168:	0880                	addi	s0,sp,80
    8000216a:	8b2a                	mv	s6,a0
	struct proc *p = myproc();
    8000216c:	00000097          	auipc	ra,0x0
    80002170:	856080e7          	jalr	-1962(ra) # 800019c2 <myproc>
    80002174:	892a                	mv	s2,a0
	acquire(&wait_lock);
    80002176:	0000f517          	auipc	a0,0xf
    8000217a:	15a50513          	addi	a0,a0,346 # 800112d0 <wait_lock>
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	a44080e7          	jalr	-1468(ra) # 80000bc2 <acquire>
		havekids = 0;
    80002186:	4b81                	li	s7,0
				if (np->state == ZOMBIE)
    80002188:	4a15                	li	s4,5
				havekids = 1;
    8000218a:	4a85                	li	s5,1
		for (np = proc; np < &proc[NPROC]; np++)
    8000218c:	00016997          	auipc	s3,0x16
    80002190:	95c98993          	addi	s3,s3,-1700 # 80017ae8 <tickslock>
		sleep(p, &wait_lock); //DOC: wait-sleep
    80002194:	0000fc17          	auipc	s8,0xf
    80002198:	13cc0c13          	addi	s8,s8,316 # 800112d0 <wait_lock>
		havekids = 0;
    8000219c:	875e                	mv	a4,s7
		for (np = proc; np < &proc[NPROC]; np++)
    8000219e:	0000f497          	auipc	s1,0xf
    800021a2:	54a48493          	addi	s1,s1,1354 # 800116e8 <proc>
    800021a6:	a0bd                	j	80002214 <wait+0xc2>
					pid = np->pid;
    800021a8:	0304a983          	lw	s3,48(s1)
					if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021ac:	000b0e63          	beqz	s6,800021c8 <wait+0x76>
    800021b0:	4691                	li	a3,4
    800021b2:	02c48613          	addi	a2,s1,44
    800021b6:	85da                	mv	a1,s6
    800021b8:	07893503          	ld	a0,120(s2)
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	482080e7          	jalr	1154(ra) # 8000163e <copyout>
    800021c4:	02054563          	bltz	a0,800021ee <wait+0x9c>
					freeproc(np);
    800021c8:	8526                	mv	a0,s1
    800021ca:	00000097          	auipc	ra,0x0
    800021ce:	9aa080e7          	jalr	-1622(ra) # 80001b74 <freeproc>
					release(&np->lock);
    800021d2:	8526                	mv	a0,s1
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	aa2080e7          	jalr	-1374(ra) # 80000c76 <release>
					release(&wait_lock);
    800021dc:	0000f517          	auipc	a0,0xf
    800021e0:	0f450513          	addi	a0,a0,244 # 800112d0 <wait_lock>
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	a92080e7          	jalr	-1390(ra) # 80000c76 <release>
					return pid;
    800021ec:	a09d                	j	80002252 <wait+0x100>
						release(&np->lock);
    800021ee:	8526                	mv	a0,s1
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	a86080e7          	jalr	-1402(ra) # 80000c76 <release>
						release(&wait_lock);
    800021f8:	0000f517          	auipc	a0,0xf
    800021fc:	0d850513          	addi	a0,a0,216 # 800112d0 <wait_lock>
    80002200:	fffff097          	auipc	ra,0xfffff
    80002204:	a76080e7          	jalr	-1418(ra) # 80000c76 <release>
						return -1;
    80002208:	59fd                	li	s3,-1
    8000220a:	a0a1                	j	80002252 <wait+0x100>
		for (np = proc; np < &proc[NPROC]; np++)
    8000220c:	19048493          	addi	s1,s1,400
    80002210:	03348463          	beq	s1,s3,80002238 <wait+0xe6>
			if (np->parent == p)
    80002214:	70bc                	ld	a5,96(s1)
    80002216:	ff279be3          	bne	a5,s2,8000220c <wait+0xba>
				acquire(&np->lock);
    8000221a:	8526                	mv	a0,s1
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	9a6080e7          	jalr	-1626(ra) # 80000bc2 <acquire>
				if (np->state == ZOMBIE)
    80002224:	4c9c                	lw	a5,24(s1)
    80002226:	f94781e3          	beq	a5,s4,800021a8 <wait+0x56>
				release(&np->lock);
    8000222a:	8526                	mv	a0,s1
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	a4a080e7          	jalr	-1462(ra) # 80000c76 <release>
				havekids = 1;
    80002234:	8756                	mv	a4,s5
    80002236:	bfd9                	j	8000220c <wait+0xba>
		if (!havekids || p->killed)
    80002238:	c701                	beqz	a4,80002240 <wait+0xee>
    8000223a:	02892783          	lw	a5,40(s2)
    8000223e:	c79d                	beqz	a5,8000226c <wait+0x11a>
			release(&wait_lock);
    80002240:	0000f517          	auipc	a0,0xf
    80002244:	09050513          	addi	a0,a0,144 # 800112d0 <wait_lock>
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	a2e080e7          	jalr	-1490(ra) # 80000c76 <release>
			return -1;
    80002250:	59fd                	li	s3,-1
}
    80002252:	854e                	mv	a0,s3
    80002254:	60a6                	ld	ra,72(sp)
    80002256:	6406                	ld	s0,64(sp)
    80002258:	74e2                	ld	s1,56(sp)
    8000225a:	7942                	ld	s2,48(sp)
    8000225c:	79a2                	ld	s3,40(sp)
    8000225e:	7a02                	ld	s4,32(sp)
    80002260:	6ae2                	ld	s5,24(sp)
    80002262:	6b42                	ld	s6,16(sp)
    80002264:	6ba2                	ld	s7,8(sp)
    80002266:	6c02                	ld	s8,0(sp)
    80002268:	6161                	addi	sp,sp,80
    8000226a:	8082                	ret
		sleep(p, &wait_lock); //DOC: wait-sleep
    8000226c:	85e2                	mv	a1,s8
    8000226e:	854a                	mv	a0,s2
    80002270:	00000097          	auipc	ra,0x0
    80002274:	e7e080e7          	jalr	-386(ra) # 800020ee <sleep>
		havekids = 0;
    80002278:	b715                	j	8000219c <wait+0x4a>

000000008000227a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000227a:	7139                	addi	sp,sp,-64
    8000227c:	fc06                	sd	ra,56(sp)
    8000227e:	f822                	sd	s0,48(sp)
    80002280:	f426                	sd	s1,40(sp)
    80002282:	f04a                	sd	s2,32(sp)
    80002284:	ec4e                	sd	s3,24(sp)
    80002286:	e852                	sd	s4,16(sp)
    80002288:	e456                	sd	s5,8(sp)
    8000228a:	0080                	addi	s0,sp,64
    8000228c:	8a2a                	mv	s4,a0
	struct proc *p;

	for (p = proc; p < &proc[NPROC]; p++)
    8000228e:	0000f497          	auipc	s1,0xf
    80002292:	45a48493          	addi	s1,s1,1114 # 800116e8 <proc>
	{
		if (p != myproc())
		{
			acquire(&p->lock);
			if (p->state == SLEEPING && p->chan == chan)
    80002296:	4989                	li	s3,2
			{
				p->state = RUNNABLE;
    80002298:	4a8d                	li	s5,3
	for (p = proc; p < &proc[NPROC]; p++)
    8000229a:	00016917          	auipc	s2,0x16
    8000229e:	84e90913          	addi	s2,s2,-1970 # 80017ae8 <tickslock>
    800022a2:	a811                	j	800022b6 <wakeup+0x3c>
				p->turn = get_turn(); // ADDED: determin the turn of the process when it wakes up
			}
			release(&p->lock);
    800022a4:	8526                	mv	a0,s1
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	9d0080e7          	jalr	-1584(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    800022ae:	19048493          	addi	s1,s1,400
    800022b2:	03248b63          	beq	s1,s2,800022e8 <wakeup+0x6e>
		if (p != myproc())
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	70c080e7          	jalr	1804(ra) # 800019c2 <myproc>
    800022be:	fea488e3          	beq	s1,a0,800022ae <wakeup+0x34>
			acquire(&p->lock);
    800022c2:	8526                	mv	a0,s1
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	8fe080e7          	jalr	-1794(ra) # 80000bc2 <acquire>
			if (p->state == SLEEPING && p->chan == chan)
    800022cc:	4c9c                	lw	a5,24(s1)
    800022ce:	fd379be3          	bne	a5,s3,800022a4 <wakeup+0x2a>
    800022d2:	709c                	ld	a5,32(s1)
    800022d4:	fd4798e3          	bne	a5,s4,800022a4 <wakeup+0x2a>
				p->state = RUNNABLE;
    800022d8:	0154ac23          	sw	s5,24(s1)
				p->turn = get_turn(); // ADDED: determin the turn of the process when it wakes up
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	530080e7          	jalr	1328(ra) # 8000180c <get_turn>
    800022e4:	c8a8                	sw	a0,80(s1)
    800022e6:	bf7d                	j	800022a4 <wakeup+0x2a>
		}
	}
}
    800022e8:	70e2                	ld	ra,56(sp)
    800022ea:	7442                	ld	s0,48(sp)
    800022ec:	74a2                	ld	s1,40(sp)
    800022ee:	7902                	ld	s2,32(sp)
    800022f0:	69e2                	ld	s3,24(sp)
    800022f2:	6a42                	ld	s4,16(sp)
    800022f4:	6aa2                	ld	s5,8(sp)
    800022f6:	6121                	addi	sp,sp,64
    800022f8:	8082                	ret

00000000800022fa <reparent>:
{
    800022fa:	7179                	addi	sp,sp,-48
    800022fc:	f406                	sd	ra,40(sp)
    800022fe:	f022                	sd	s0,32(sp)
    80002300:	ec26                	sd	s1,24(sp)
    80002302:	e84a                	sd	s2,16(sp)
    80002304:	e44e                	sd	s3,8(sp)
    80002306:	e052                	sd	s4,0(sp)
    80002308:	1800                	addi	s0,sp,48
    8000230a:	892a                	mv	s2,a0
	for (pp = proc; pp < &proc[NPROC]; pp++)
    8000230c:	0000f497          	auipc	s1,0xf
    80002310:	3dc48493          	addi	s1,s1,988 # 800116e8 <proc>
			pp->parent = initproc;
    80002314:	00007a17          	auipc	s4,0x7
    80002318:	d14a0a13          	addi	s4,s4,-748 # 80009028 <initproc>
	for (pp = proc; pp < &proc[NPROC]; pp++)
    8000231c:	00015997          	auipc	s3,0x15
    80002320:	7cc98993          	addi	s3,s3,1996 # 80017ae8 <tickslock>
    80002324:	a029                	j	8000232e <reparent+0x34>
    80002326:	19048493          	addi	s1,s1,400
    8000232a:	01348d63          	beq	s1,s3,80002344 <reparent+0x4a>
		if (pp->parent == p)
    8000232e:	70bc                	ld	a5,96(s1)
    80002330:	ff279be3          	bne	a5,s2,80002326 <reparent+0x2c>
			pp->parent = initproc;
    80002334:	000a3503          	ld	a0,0(s4)
    80002338:	f0a8                	sd	a0,96(s1)
			wakeup(initproc);
    8000233a:	00000097          	auipc	ra,0x0
    8000233e:	f40080e7          	jalr	-192(ra) # 8000227a <wakeup>
    80002342:	b7d5                	j	80002326 <reparent+0x2c>
}
    80002344:	70a2                	ld	ra,40(sp)
    80002346:	7402                	ld	s0,32(sp)
    80002348:	64e2                	ld	s1,24(sp)
    8000234a:	6942                	ld	s2,16(sp)
    8000234c:	69a2                	ld	s3,8(sp)
    8000234e:	6a02                	ld	s4,0(sp)
    80002350:	6145                	addi	sp,sp,48
    80002352:	8082                	ret

0000000080002354 <exit>:
{
    80002354:	7179                	addi	sp,sp,-48
    80002356:	f406                	sd	ra,40(sp)
    80002358:	f022                	sd	s0,32(sp)
    8000235a:	ec26                	sd	s1,24(sp)
    8000235c:	e84a                	sd	s2,16(sp)
    8000235e:	e44e                	sd	s3,8(sp)
    80002360:	e052                	sd	s4,0(sp)
    80002362:	1800                	addi	s0,sp,48
    80002364:	8a2a                	mv	s4,a0
	struct proc *p = myproc();
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	65c080e7          	jalr	1628(ra) # 800019c2 <myproc>
    8000236e:	89aa                	mv	s3,a0
	if (p == initproc)
    80002370:	00007797          	auipc	a5,0x7
    80002374:	cb87b783          	ld	a5,-840(a5) # 80009028 <initproc>
    80002378:	0f850493          	addi	s1,a0,248
    8000237c:	17850913          	addi	s2,a0,376
    80002380:	02a79363          	bne	a5,a0,800023a6 <exit+0x52>
		panic("init exiting");
    80002384:	00006517          	auipc	a0,0x6
    80002388:	ecc50513          	addi	a0,a0,-308 # 80008250 <digits+0x210>
    8000238c:	ffffe097          	auipc	ra,0xffffe
    80002390:	19e080e7          	jalr	414(ra) # 8000052a <panic>
			fileclose(f);
    80002394:	00003097          	auipc	ra,0x3
    80002398:	9c2080e7          	jalr	-1598(ra) # 80004d56 <fileclose>
			p->ofile[fd] = 0;
    8000239c:	0004b023          	sd	zero,0(s1)
	for (int fd = 0; fd < NOFILE; fd++)
    800023a0:	04a1                	addi	s1,s1,8
    800023a2:	01248563          	beq	s1,s2,800023ac <exit+0x58>
		if (p->ofile[fd])
    800023a6:	6088                	ld	a0,0(s1)
    800023a8:	f575                	bnez	a0,80002394 <exit+0x40>
    800023aa:	bfdd                	j	800023a0 <exit+0x4c>
	begin_op();
    800023ac:	00002097          	auipc	ra,0x2
    800023b0:	4de080e7          	jalr	1246(ra) # 8000488a <begin_op>
	iput(p->cwd);
    800023b4:	1789b503          	ld	a0,376(s3)
    800023b8:	00002097          	auipc	ra,0x2
    800023bc:	cb6080e7          	jalr	-842(ra) # 8000406e <iput>
	end_op();
    800023c0:	00002097          	auipc	ra,0x2
    800023c4:	54a080e7          	jalr	1354(ra) # 8000490a <end_op>
	p->cwd = 0;
    800023c8:	1609bc23          	sd	zero,376(s3)
	acquire(&wait_lock);
    800023cc:	0000f497          	auipc	s1,0xf
    800023d0:	f0448493          	addi	s1,s1,-252 # 800112d0 <wait_lock>
    800023d4:	8526                	mv	a0,s1
    800023d6:	ffffe097          	auipc	ra,0xffffe
    800023da:	7ec080e7          	jalr	2028(ra) # 80000bc2 <acquire>
	reparent(p);
    800023de:	854e                	mv	a0,s3
    800023e0:	00000097          	auipc	ra,0x0
    800023e4:	f1a080e7          	jalr	-230(ra) # 800022fa <reparent>
	wakeup(p->parent);
    800023e8:	0609b503          	ld	a0,96(s3)
    800023ec:	00000097          	auipc	ra,0x0
    800023f0:	e8e080e7          	jalr	-370(ra) # 8000227a <wakeup>
	acquire(&p->lock);
    800023f4:	854e                	mv	a0,s3
    800023f6:	ffffe097          	auipc	ra,0xffffe
    800023fa:	7cc080e7          	jalr	1996(ra) # 80000bc2 <acquire>
	p->xstate = status;
    800023fe:	0349a623          	sw	s4,44(s3)
	p->state = ZOMBIE;
    80002402:	4795                	li	a5,5
    80002404:	00f9ac23          	sw	a5,24(s3)
	release(&wait_lock);
    80002408:	8526                	mv	a0,s1
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	86c080e7          	jalr	-1940(ra) # 80000c76 <release>
	sched();
    80002412:	00000097          	auipc	ra,0x0
    80002416:	bca080e7          	jalr	-1078(ra) # 80001fdc <sched>
	panic("zombie exit");
    8000241a:	00006517          	auipc	a0,0x6
    8000241e:	e4650513          	addi	a0,a0,-442 # 80008260 <digits+0x220>
    80002422:	ffffe097          	auipc	ra,0xffffe
    80002426:	108080e7          	jalr	264(ra) # 8000052a <panic>

000000008000242a <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000242a:	7179                	addi	sp,sp,-48
    8000242c:	f406                	sd	ra,40(sp)
    8000242e:	f022                	sd	s0,32(sp)
    80002430:	ec26                	sd	s1,24(sp)
    80002432:	e84a                	sd	s2,16(sp)
    80002434:	e44e                	sd	s3,8(sp)
    80002436:	1800                	addi	s0,sp,48
    80002438:	892a                	mv	s2,a0
	struct proc *p;

	for (p = proc; p < &proc[NPROC]; p++)
    8000243a:	0000f497          	auipc	s1,0xf
    8000243e:	2ae48493          	addi	s1,s1,686 # 800116e8 <proc>
    80002442:	00015997          	auipc	s3,0x15
    80002446:	6a698993          	addi	s3,s3,1702 # 80017ae8 <tickslock>
	{
		acquire(&p->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	ffffe097          	auipc	ra,0xffffe
    80002450:	776080e7          	jalr	1910(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    80002454:	589c                	lw	a5,48(s1)
    80002456:	01278d63          	beq	a5,s2,80002470 <kill+0x46>
				p->state = RUNNABLE;
			}
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    8000245a:	8526                	mv	a0,s1
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	81a080e7          	jalr	-2022(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80002464:	19048493          	addi	s1,s1,400
    80002468:	ff3491e3          	bne	s1,s3,8000244a <kill+0x20>
	}
	return -1;
    8000246c:	557d                	li	a0,-1
    8000246e:	a829                	j	80002488 <kill+0x5e>
			p->killed = 1;
    80002470:	4785                	li	a5,1
    80002472:	d49c                	sw	a5,40(s1)
			if (p->state == SLEEPING)
    80002474:	4c98                	lw	a4,24(s1)
    80002476:	4789                	li	a5,2
    80002478:	00f70f63          	beq	a4,a5,80002496 <kill+0x6c>
			release(&p->lock);
    8000247c:	8526                	mv	a0,s1
    8000247e:	ffffe097          	auipc	ra,0xffffe
    80002482:	7f8080e7          	jalr	2040(ra) # 80000c76 <release>
			return 0;
    80002486:	4501                	li	a0,0
}
    80002488:	70a2                	ld	ra,40(sp)
    8000248a:	7402                	ld	s0,32(sp)
    8000248c:	64e2                	ld	s1,24(sp)
    8000248e:	6942                	ld	s2,16(sp)
    80002490:	69a2                	ld	s3,8(sp)
    80002492:	6145                	addi	sp,sp,48
    80002494:	8082                	ret
				p->state = RUNNABLE;
    80002496:	478d                	li	a5,3
    80002498:	cc9c                	sw	a5,24(s1)
    8000249a:	b7cd                	j	8000247c <kill+0x52>

000000008000249c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000249c:	7179                	addi	sp,sp,-48
    8000249e:	f406                	sd	ra,40(sp)
    800024a0:	f022                	sd	s0,32(sp)
    800024a2:	ec26                	sd	s1,24(sp)
    800024a4:	e84a                	sd	s2,16(sp)
    800024a6:	e44e                	sd	s3,8(sp)
    800024a8:	e052                	sd	s4,0(sp)
    800024aa:	1800                	addi	s0,sp,48
    800024ac:	84aa                	mv	s1,a0
    800024ae:	892e                	mv	s2,a1
    800024b0:	89b2                	mv	s3,a2
    800024b2:	8a36                	mv	s4,a3
	struct proc *p = myproc();
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	50e080e7          	jalr	1294(ra) # 800019c2 <myproc>
	if (user_dst)
    800024bc:	c08d                	beqz	s1,800024de <either_copyout+0x42>
	{
		return copyout(p->pagetable, dst, src, len);
    800024be:	86d2                	mv	a3,s4
    800024c0:	864e                	mv	a2,s3
    800024c2:	85ca                	mv	a1,s2
    800024c4:	7d28                	ld	a0,120(a0)
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	178080e7          	jalr	376(ra) # 8000163e <copyout>
	else
	{
		memmove((char *)dst, src, len);
		return 0;
	}
}
    800024ce:	70a2                	ld	ra,40(sp)
    800024d0:	7402                	ld	s0,32(sp)
    800024d2:	64e2                	ld	s1,24(sp)
    800024d4:	6942                	ld	s2,16(sp)
    800024d6:	69a2                	ld	s3,8(sp)
    800024d8:	6a02                	ld	s4,0(sp)
    800024da:	6145                	addi	sp,sp,48
    800024dc:	8082                	ret
		memmove((char *)dst, src, len);
    800024de:	000a061b          	sext.w	a2,s4
    800024e2:	85ce                	mv	a1,s3
    800024e4:	854a                	mv	a0,s2
    800024e6:	fffff097          	auipc	ra,0xfffff
    800024ea:	834080e7          	jalr	-1996(ra) # 80000d1a <memmove>
		return 0;
    800024ee:	8526                	mv	a0,s1
    800024f0:	bff9                	j	800024ce <either_copyout+0x32>

00000000800024f2 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024f2:	7179                	addi	sp,sp,-48
    800024f4:	f406                	sd	ra,40(sp)
    800024f6:	f022                	sd	s0,32(sp)
    800024f8:	ec26                	sd	s1,24(sp)
    800024fa:	e84a                	sd	s2,16(sp)
    800024fc:	e44e                	sd	s3,8(sp)
    800024fe:	e052                	sd	s4,0(sp)
    80002500:	1800                	addi	s0,sp,48
    80002502:	892a                	mv	s2,a0
    80002504:	84ae                	mv	s1,a1
    80002506:	89b2                	mv	s3,a2
    80002508:	8a36                	mv	s4,a3
	struct proc *p = myproc();
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	4b8080e7          	jalr	1208(ra) # 800019c2 <myproc>
	if (user_src)
    80002512:	c08d                	beqz	s1,80002534 <either_copyin+0x42>
	{
		return copyin(p->pagetable, dst, src, len);
    80002514:	86d2                	mv	a3,s4
    80002516:	864e                	mv	a2,s3
    80002518:	85ca                	mv	a1,s2
    8000251a:	7d28                	ld	a0,120(a0)
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	1ae080e7          	jalr	430(ra) # 800016ca <copyin>
	else
	{
		memmove(dst, (char *)src, len);
		return 0;
	}
}
    80002524:	70a2                	ld	ra,40(sp)
    80002526:	7402                	ld	s0,32(sp)
    80002528:	64e2                	ld	s1,24(sp)
    8000252a:	6942                	ld	s2,16(sp)
    8000252c:	69a2                	ld	s3,8(sp)
    8000252e:	6a02                	ld	s4,0(sp)
    80002530:	6145                	addi	sp,sp,48
    80002532:	8082                	ret
		memmove(dst, (char *)src, len);
    80002534:	000a061b          	sext.w	a2,s4
    80002538:	85ce                	mv	a1,s3
    8000253a:	854a                	mv	a0,s2
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	7de080e7          	jalr	2014(ra) # 80000d1a <memmove>
		return 0;
    80002544:	8526                	mv	a0,s1
    80002546:	bff9                	j	80002524 <either_copyin+0x32>

0000000080002548 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002548:	715d                	addi	sp,sp,-80
    8000254a:	e486                	sd	ra,72(sp)
    8000254c:	e0a2                	sd	s0,64(sp)
    8000254e:	fc26                	sd	s1,56(sp)
    80002550:	f84a                	sd	s2,48(sp)
    80002552:	f44e                	sd	s3,40(sp)
    80002554:	f052                	sd	s4,32(sp)
    80002556:	ec56                	sd	s5,24(sp)
    80002558:	e85a                	sd	s6,16(sp)
    8000255a:	e45e                	sd	s7,8(sp)
    8000255c:	0880                	addi	s0,sp,80
		[RUNNING] "run   ",
		[ZOMBIE] "zombie"};
	struct proc *p;
	char *state;

	printf("\n");
    8000255e:	00006517          	auipc	a0,0x6
    80002562:	b6a50513          	addi	a0,a0,-1174 # 800080c8 <digits+0x88>
    80002566:	ffffe097          	auipc	ra,0xffffe
    8000256a:	00e080e7          	jalr	14(ra) # 80000574 <printf>
	for (p = proc; p < &proc[NPROC]; p++)
    8000256e:	0000f497          	auipc	s1,0xf
    80002572:	2fa48493          	addi	s1,s1,762 # 80011868 <proc+0x180>
    80002576:	00015917          	auipc	s2,0x15
    8000257a:	6f290913          	addi	s2,s2,1778 # 80017c68 <bcache+0x168>
	{
		if (p->state == UNUSED)
			continue;
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000257e:	4b15                	li	s6,5
			state = states[p->state];
		else
			state = "???";
    80002580:	00006997          	auipc	s3,0x6
    80002584:	cf098993          	addi	s3,s3,-784 # 80008270 <digits+0x230>
		printf("%d %s %s", p->pid, state, p->name);
    80002588:	00006a97          	auipc	s5,0x6
    8000258c:	cf0a8a93          	addi	s5,s5,-784 # 80008278 <digits+0x238>
		printf("\n");
    80002590:	00006a17          	auipc	s4,0x6
    80002594:	b38a0a13          	addi	s4,s4,-1224 # 800080c8 <digits+0x88>
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002598:	00006b97          	auipc	s7,0x6
    8000259c:	d18b8b93          	addi	s7,s7,-744 # 800082b0 <states.0>
    800025a0:	a00d                	j	800025c2 <procdump+0x7a>
		printf("%d %s %s", p->pid, state, p->name);
    800025a2:	eb06a583          	lw	a1,-336(a3)
    800025a6:	8556                	mv	a0,s5
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	fcc080e7          	jalr	-52(ra) # 80000574 <printf>
		printf("\n");
    800025b0:	8552                	mv	a0,s4
    800025b2:	ffffe097          	auipc	ra,0xffffe
    800025b6:	fc2080e7          	jalr	-62(ra) # 80000574 <printf>
	for (p = proc; p < &proc[NPROC]; p++)
    800025ba:	19048493          	addi	s1,s1,400
    800025be:	03248263          	beq	s1,s2,800025e2 <procdump+0x9a>
		if (p->state == UNUSED)
    800025c2:	86a6                	mv	a3,s1
    800025c4:	e984a783          	lw	a5,-360(s1)
    800025c8:	dbed                	beqz	a5,800025ba <procdump+0x72>
			state = "???";
    800025ca:	864e                	mv	a2,s3
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025cc:	fcfb6be3          	bltu	s6,a5,800025a2 <procdump+0x5a>
    800025d0:	02079713          	slli	a4,a5,0x20
    800025d4:	01d75793          	srli	a5,a4,0x1d
    800025d8:	97de                	add	a5,a5,s7
    800025da:	6390                	ld	a2,0(a5)
    800025dc:	f279                	bnez	a2,800025a2 <procdump+0x5a>
			state = "???";
    800025de:	864e                	mv	a2,s3
    800025e0:	b7c9                	j	800025a2 <procdump+0x5a>
	}
}
    800025e2:	60a6                	ld	ra,72(sp)
    800025e4:	6406                	ld	s0,64(sp)
    800025e6:	74e2                	ld	s1,56(sp)
    800025e8:	7942                	ld	s2,48(sp)
    800025ea:	79a2                	ld	s3,40(sp)
    800025ec:	7a02                	ld	s4,32(sp)
    800025ee:	6ae2                	ld	s5,24(sp)
    800025f0:	6b42                	ld	s6,16(sp)
    800025f2:	6ba2                	ld	s7,8(sp)
    800025f4:	6161                	addi	sp,sp,80
    800025f6:	8082                	ret

00000000800025f8 <trace>:
// ADDED: trace
int trace(int mask, int pid)
{
    800025f8:	7179                	addi	sp,sp,-48
    800025fa:	f406                	sd	ra,40(sp)
    800025fc:	f022                	sd	s0,32(sp)
    800025fe:	ec26                	sd	s1,24(sp)
    80002600:	e84a                	sd	s2,16(sp)
    80002602:	e44e                	sd	s3,8(sp)
    80002604:	e052                	sd	s4,0(sp)
    80002606:	1800                	addi	s0,sp,48
    80002608:	8a2a                	mv	s4,a0
    8000260a:	892e                	mv	s2,a1
	struct proc *p;
	for (p = proc; p < &proc[NPROC]; p++)
    8000260c:	0000f497          	auipc	s1,0xf
    80002610:	0dc48493          	addi	s1,s1,220 # 800116e8 <proc>
    80002614:	00015997          	auipc	s3,0x15
    80002618:	4d498993          	addi	s3,s3,1236 # 80017ae8 <tickslock>
	{
		acquire(&p->lock);
    8000261c:	8526                	mv	a0,s1
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	5a4080e7          	jalr	1444(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    80002626:	589c                	lw	a5,48(s1)
    80002628:	01278d63          	beq	a5,s2,80002642 <trace+0x4a>
		{
			p->trace_mask = mask;
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    8000262c:	8526                	mv	a0,s1
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	648080e7          	jalr	1608(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80002636:	19048493          	addi	s1,s1,400
    8000263a:	ff3491e3          	bne	s1,s3,8000261c <trace+0x24>
	}

	return -1;
    8000263e:	557d                	li	a0,-1
    80002640:	a809                	j	80002652 <trace+0x5a>
			p->trace_mask = mask;
    80002642:	0344aa23          	sw	s4,52(s1)
			release(&p->lock);
    80002646:	8526                	mv	a0,s1
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	62e080e7          	jalr	1582(ra) # 80000c76 <release>
			return 0;
    80002650:	4501                	li	a0,0
}
    80002652:	70a2                	ld	ra,40(sp)
    80002654:	7402                	ld	s0,32(sp)
    80002656:	64e2                	ld	s1,24(sp)
    80002658:	6942                	ld	s2,16(sp)
    8000265a:	69a2                	ld	s3,8(sp)
    8000265c:	6a02                	ld	s4,0(sp)
    8000265e:	6145                	addi	sp,sp,48
    80002660:	8082                	ret

0000000080002662 <getmsk>:
// ADDED: getmsk
int getmsk(int pid)
{
    80002662:	7179                	addi	sp,sp,-48
    80002664:	f406                	sd	ra,40(sp)
    80002666:	f022                	sd	s0,32(sp)
    80002668:	ec26                	sd	s1,24(sp)
    8000266a:	e84a                	sd	s2,16(sp)
    8000266c:	e44e                	sd	s3,8(sp)
    8000266e:	1800                	addi	s0,sp,48
    80002670:	892a                	mv	s2,a0
	struct proc *p;
	int mask;

	for (p = proc; p < &proc[NPROC]; p++)
    80002672:	0000f497          	auipc	s1,0xf
    80002676:	07648493          	addi	s1,s1,118 # 800116e8 <proc>
    8000267a:	00015997          	auipc	s3,0x15
    8000267e:	46e98993          	addi	s3,s3,1134 # 80017ae8 <tickslock>
	{
		acquire(&p->lock);
    80002682:	8526                	mv	a0,s1
    80002684:	ffffe097          	auipc	ra,0xffffe
    80002688:	53e080e7          	jalr	1342(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    8000268c:	589c                	lw	a5,48(s1)
    8000268e:	01278d63          	beq	a5,s2,800026a8 <getmsk+0x46>
		{
			mask = p->trace_mask;
			release(&p->lock);
			return mask;
		}
		release(&p->lock);
    80002692:	8526                	mv	a0,s1
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	5e2080e7          	jalr	1506(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    8000269c:	19048493          	addi	s1,s1,400
    800026a0:	ff3491e3          	bne	s1,s3,80002682 <getmsk+0x20>
	}

	return -1;
    800026a4:	597d                	li	s2,-1
    800026a6:	a801                	j	800026b6 <getmsk+0x54>
			mask = p->trace_mask;
    800026a8:	0344a903          	lw	s2,52(s1)
			release(&p->lock);
    800026ac:	8526                	mv	a0,s1
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	5c8080e7          	jalr	1480(ra) # 80000c76 <release>
}
    800026b6:	854a                	mv	a0,s2
    800026b8:	70a2                	ld	ra,40(sp)
    800026ba:	7402                	ld	s0,32(sp)
    800026bc:	64e2                	ld	s1,24(sp)
    800026be:	6942                	ld	s2,16(sp)
    800026c0:	69a2                	ld	s3,8(sp)
    800026c2:	6145                	addi	sp,sp,48
    800026c4:	8082                	ret

00000000800026c6 <update_avg_burst_zero_burst>:
		// Wait for a child to exit.
		sleep(p, &wait_lock); //DOC: wait-sleep
	}
}

void update_avg_burst_zero_burst(struct proc *p){
    800026c6:	1141                	addi	sp,sp,-16
    800026c8:	e422                	sd	s0,8(sp)
    800026ca:	0800                	addi	s0,sp,16
	uint B = p->burst;
	uint A = p->performance.average_bursttime;
	A = ALPHA * B + (100 - ALPHA) * A / 100;
    800026cc:	03200793          	li	a5,50
    800026d0:	4578                	lw	a4,76(a0)
    800026d2:	02e7873b          	mulw	a4,a5,a4
    800026d6:	06400693          	li	a3,100
    800026da:	02d7573b          	divuw	a4,a4,a3
    800026de:	4974                	lw	a3,84(a0)
    800026e0:	02d787bb          	mulw	a5,a5,a3
    800026e4:	9fb9                	addw	a5,a5,a4
	p->performance.average_bursttime = A;
    800026e6:	c57c                	sw	a5,76(a0)
	p->burst = 0;
    800026e8:	04052a23          	sw	zero,84(a0)
}
    800026ec:	6422                	ld	s0,8(sp)
    800026ee:	0141                	addi	sp,sp,16
    800026f0:	8082                	ret

00000000800026f2 <swtch_and_update_bursttime>:
void swtch_and_update_bursttime(struct cpu *c, struct proc *p) {
    800026f2:	1101                	addi	sp,sp,-32
    800026f4:	ec06                	sd	ra,24(sp)
    800026f6:	e822                	sd	s0,16(sp)
    800026f8:	e426                	sd	s1,8(sp)
    800026fa:	1000                	addi	s0,sp,32
    800026fc:	84ae                	mv	s1,a1
	swtch(&c->context,&p->context);
    800026fe:	08858593          	addi	a1,a1,136
    80002702:	0521                	addi	a0,a0,8
    80002704:	00000097          	auipc	ra,0x0
    80002708:	552080e7          	jalr	1362(ra) # 80002c56 <swtch>
			update_avg_burst_zero_burst(p);
    8000270c:	8526                	mv	a0,s1
    8000270e:	00000097          	auipc	ra,0x0
    80002712:	fb8080e7          	jalr	-72(ra) # 800026c6 <update_avg_burst_zero_burst>
}
    80002716:	60e2                	ld	ra,24(sp)
    80002718:	6442                	ld	s0,16(sp)
    8000271a:	64a2                	ld	s1,8(sp)
    8000271c:	6105                	addi	sp,sp,32
    8000271e:	8082                	ret

0000000080002720 <sched_fcfs>:
{
    80002720:	715d                	addi	sp,sp,-80
    80002722:	e486                	sd	ra,72(sp)
    80002724:	e0a2                	sd	s0,64(sp)
    80002726:	fc26                	sd	s1,56(sp)
    80002728:	f84a                	sd	s2,48(sp)
    8000272a:	f44e                	sd	s3,40(sp)
    8000272c:	f052                	sd	s4,32(sp)
    8000272e:	ec56                	sd	s5,24(sp)
    80002730:	e85a                	sd	s6,16(sp)
    80002732:	e45e                	sd	s7,8(sp)
    80002734:	0880                	addi	s0,sp,80
    80002736:	8b92                	mv	s7,tp
	int id = r_tp();
    80002738:	2b81                	sext.w	s7,s7
	c->proc = 0;
    8000273a:	007b9713          	slli	a4,s7,0x7
    8000273e:	0000f797          	auipc	a5,0xf
    80002742:	b6278793          	addi	a5,a5,-1182 # 800112a0 <TURNLOCK>
    80002746:	97ba                	add	a5,a5,a4
    80002748:	0407b423          	sd	zero,72(a5)
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    8000274c:	4901                	li	s2,0
	int proc_to_run_index = 0;
    8000274e:	4b01                	li	s6,0
	uint first_turn = 4294967295;
    80002750:	5afd                	li	s5,-1
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80002752:	0000f497          	auipc	s1,0xf
    80002756:	f9648493          	addi	s1,s1,-106 # 800116e8 <proc>
		if (p->state == RUNNABLE && p->turn < first_turn)
    8000275a:	4a0d                	li	s4,3
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    8000275c:	00015997          	auipc	s3,0x15
    80002760:	38c98993          	addi	s3,s3,908 # 80017ae8 <tickslock>
    80002764:	a819                	j	8000277a <sched_fcfs+0x5a>
		release(&p->lock);
    80002766:	8526                	mv	a0,s1
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	50e080e7          	jalr	1294(ra) # 80000c76 <release>
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80002770:	19048493          	addi	s1,s1,400
    80002774:	2905                	addiw	s2,s2,1
    80002776:	03348063          	beq	s1,s3,80002796 <sched_fcfs+0x76>
		acquire(&p->lock);
    8000277a:	8526                	mv	a0,s1
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	446080e7          	jalr	1094(ra) # 80000bc2 <acquire>
		if (p->state == RUNNABLE && p->turn < first_turn)
    80002784:	4c9c                	lw	a5,24(s1)
    80002786:	ff4790e3          	bne	a5,s4,80002766 <sched_fcfs+0x46>
    8000278a:	48bc                	lw	a5,80(s1)
    8000278c:	fd57fde3          	bgeu	a5,s5,80002766 <sched_fcfs+0x46>
    80002790:	8b4a                	mv	s6,s2
			first_turn = p->turn;
    80002792:	8abe                	mv	s5,a5
    80002794:	bfc9                	j	80002766 <sched_fcfs+0x46>
	first = &proc[proc_to_run_index];
    80002796:	19000493          	li	s1,400
    8000279a:	029b04b3          	mul	s1,s6,s1
    8000279e:	0000f797          	auipc	a5,0xf
    800027a2:	f4a78793          	addi	a5,a5,-182 # 800116e8 <proc>
    800027a6:	94be                	add	s1,s1,a5
	acquire(&first->lock);
    800027a8:	8526                	mv	a0,s1
    800027aa:	ffffe097          	auipc	ra,0xffffe
    800027ae:	418080e7          	jalr	1048(ra) # 80000bc2 <acquire>
	if (first->state == RUNNABLE)
    800027b2:	4c98                	lw	a4,24(s1)
    800027b4:	478d                	li	a5,3
    800027b6:	02f70263          	beq	a4,a5,800027da <sched_fcfs+0xba>
	release(&first->lock);
    800027ba:	8526                	mv	a0,s1
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	4ba080e7          	jalr	1210(ra) # 80000c76 <release>
}
    800027c4:	60a6                	ld	ra,72(sp)
    800027c6:	6406                	ld	s0,64(sp)
    800027c8:	74e2                	ld	s1,56(sp)
    800027ca:	7942                	ld	s2,48(sp)
    800027cc:	79a2                	ld	s3,40(sp)
    800027ce:	7a02                	ld	s4,32(sp)
    800027d0:	6ae2                	ld	s5,24(sp)
    800027d2:	6b42                	ld	s6,16(sp)
    800027d4:	6ba2                	ld	s7,8(sp)
    800027d6:	6161                	addi	sp,sp,80
    800027d8:	8082                	ret
		first->state = RUNNING;
    800027da:	4791                	li	a5,4
    800027dc:	cc9c                	sw	a5,24(s1)
		c->proc = first;
    800027de:	0b9e                	slli	s7,s7,0x7
    800027e0:	0000f917          	auipc	s2,0xf
    800027e4:	ac090913          	addi	s2,s2,-1344 # 800112a0 <TURNLOCK>
    800027e8:	995e                	add	s2,s2,s7
    800027ea:	04993423          	sd	s1,72(s2)
		swtch_and_update_bursttime(c,first);
    800027ee:	85a6                	mv	a1,s1
    800027f0:	0000f517          	auipc	a0,0xf
    800027f4:	af850513          	addi	a0,a0,-1288 # 800112e8 <cpus>
    800027f8:	955e                	add	a0,a0,s7
    800027fa:	00000097          	auipc	ra,0x0
    800027fe:	ef8080e7          	jalr	-264(ra) # 800026f2 <swtch_and_update_bursttime>
		c->proc = 0;
    80002802:	04093423          	sd	zero,72(s2)
    80002806:	bf55                	j	800027ba <sched_fcfs+0x9a>

0000000080002808 <sched_srt>:
{
    80002808:	715d                	addi	sp,sp,-80
    8000280a:	e486                	sd	ra,72(sp)
    8000280c:	e0a2                	sd	s0,64(sp)
    8000280e:	fc26                	sd	s1,56(sp)
    80002810:	f84a                	sd	s2,48(sp)
    80002812:	f44e                	sd	s3,40(sp)
    80002814:	f052                	sd	s4,32(sp)
    80002816:	ec56                	sd	s5,24(sp)
    80002818:	e85a                	sd	s6,16(sp)
    8000281a:	e45e                	sd	s7,8(sp)
    8000281c:	0880                	addi	s0,sp,80
    8000281e:	8b92                	mv	s7,tp
	int id = r_tp();
    80002820:	2b81                	sext.w	s7,s7
	c->proc = 0;
    80002822:	007b9713          	slli	a4,s7,0x7
    80002826:	0000f797          	auipc	a5,0xf
    8000282a:	a7a78793          	addi	a5,a5,-1414 # 800112a0 <TURNLOCK>
    8000282e:	97ba                	add	a5,a5,a4
    80002830:	0407b423          	sd	zero,72(a5)
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80002834:	4901                	li	s2,0
	int proc_to_run_index = 0;
    80002836:	4b01                	li	s6,0
	uint least_average_bursttime = 4294967295;
    80002838:	5afd                	li	s5,-1
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    8000283a:	0000f497          	auipc	s1,0xf
    8000283e:	eae48493          	addi	s1,s1,-338 # 800116e8 <proc>
		if (p->state == RUNNABLE && p->performance.average_bursttime < least_average_bursttime)
    80002842:	4a0d                	li	s4,3
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80002844:	00015997          	auipc	s3,0x15
    80002848:	2a498993          	addi	s3,s3,676 # 80017ae8 <tickslock>
    8000284c:	a819                	j	80002862 <sched_srt+0x5a>
		release(&p->lock);
    8000284e:	8526                	mv	a0,s1
    80002850:	ffffe097          	auipc	ra,0xffffe
    80002854:	426080e7          	jalr	1062(ra) # 80000c76 <release>
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80002858:	19048493          	addi	s1,s1,400
    8000285c:	2905                	addiw	s2,s2,1
    8000285e:	03348063          	beq	s1,s3,8000287e <sched_srt+0x76>
		acquire(&p->lock);
    80002862:	8526                	mv	a0,s1
    80002864:	ffffe097          	auipc	ra,0xffffe
    80002868:	35e080e7          	jalr	862(ra) # 80000bc2 <acquire>
		if (p->state == RUNNABLE && p->performance.average_bursttime < least_average_bursttime)
    8000286c:	4c9c                	lw	a5,24(s1)
    8000286e:	ff4790e3          	bne	a5,s4,8000284e <sched_srt+0x46>
    80002872:	44fc                	lw	a5,76(s1)
    80002874:	fd57fde3          	bgeu	a5,s5,8000284e <sched_srt+0x46>
    80002878:	8b4a                	mv	s6,s2
			least_average_bursttime = p->performance.average_bursttime;
    8000287a:	8abe                	mv	s5,a5
    8000287c:	bfc9                	j	8000284e <sched_srt+0x46>
	first = &proc[proc_to_run_index];
    8000287e:	19000493          	li	s1,400
    80002882:	029b04b3          	mul	s1,s6,s1
    80002886:	0000f797          	auipc	a5,0xf
    8000288a:	e6278793          	addi	a5,a5,-414 # 800116e8 <proc>
    8000288e:	94be                	add	s1,s1,a5
	acquire(&first->lock);
    80002890:	8526                	mv	a0,s1
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	330080e7          	jalr	816(ra) # 80000bc2 <acquire>
	if (first->state == RUNNABLE)
    8000289a:	4c98                	lw	a4,24(s1)
    8000289c:	478d                	li	a5,3
    8000289e:	02f70263          	beq	a4,a5,800028c2 <sched_srt+0xba>
	release(&first->lock);
    800028a2:	8526                	mv	a0,s1
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	3d2080e7          	jalr	978(ra) # 80000c76 <release>
}
    800028ac:	60a6                	ld	ra,72(sp)
    800028ae:	6406                	ld	s0,64(sp)
    800028b0:	74e2                	ld	s1,56(sp)
    800028b2:	7942                	ld	s2,48(sp)
    800028b4:	79a2                	ld	s3,40(sp)
    800028b6:	7a02                	ld	s4,32(sp)
    800028b8:	6ae2                	ld	s5,24(sp)
    800028ba:	6b42                	ld	s6,16(sp)
    800028bc:	6ba2                	ld	s7,8(sp)
    800028be:	6161                	addi	sp,sp,80
    800028c0:	8082                	ret
		first->state = RUNNING;
    800028c2:	4791                	li	a5,4
    800028c4:	cc9c                	sw	a5,24(s1)
		c->proc = first;
    800028c6:	0b9e                	slli	s7,s7,0x7
    800028c8:	0000f917          	auipc	s2,0xf
    800028cc:	9d890913          	addi	s2,s2,-1576 # 800112a0 <TURNLOCK>
    800028d0:	995e                	add	s2,s2,s7
    800028d2:	04993423          	sd	s1,72(s2)
		swtch_and_update_bursttime(c,first);
    800028d6:	85a6                	mv	a1,s1
    800028d8:	0000f517          	auipc	a0,0xf
    800028dc:	a1050513          	addi	a0,a0,-1520 # 800112e8 <cpus>
    800028e0:	955e                	add	a0,a0,s7
    800028e2:	00000097          	auipc	ra,0x0
    800028e6:	e10080e7          	jalr	-496(ra) # 800026f2 <swtch_and_update_bursttime>
		c->proc = 0;
    800028ea:	04093423          	sd	zero,72(s2)
    800028ee:	bf55                	j	800028a2 <sched_srt+0x9a>

00000000800028f0 <sched_cfsd>:
void sched_cfsd() {
    800028f0:	711d                	addi	sp,sp,-96
    800028f2:	ec86                	sd	ra,88(sp)
    800028f4:	e8a2                	sd	s0,80(sp)
    800028f6:	e4a6                	sd	s1,72(sp)
    800028f8:	e0ca                	sd	s2,64(sp)
    800028fa:	fc4e                	sd	s3,56(sp)
    800028fc:	f852                	sd	s4,48(sp)
    800028fe:	f456                	sd	s5,40(sp)
    80002900:	f05a                	sd	s6,32(sp)
    80002902:	ec5e                	sd	s7,24(sp)
    80002904:	e862                	sd	s8,16(sp)
    80002906:	e466                	sd	s9,8(sp)
    80002908:	1080                	addi	s0,sp,96
    8000290a:	8c92                	mv	s9,tp
	int id = r_tp();
    8000290c:	2c81                	sext.w	s9,s9
	c->proc = 0;
    8000290e:	007c9713          	slli	a4,s9,0x7
    80002912:	0000f797          	auipc	a5,0xf
    80002916:	98e78793          	addi	a5,a5,-1650 # 800112a0 <TURNLOCK>
    8000291a:	97ba                	add	a5,a5,a4
    8000291c:	0407b423          	sd	zero,72(a5)
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80002920:	4901                	li	s2,0
	int proc_to_run_index = 0;
    80002922:	4c01                	li	s8,0
	uint least_runtime_ratio = 4294967295;
    80002924:	5b7d                	li	s6,-1
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80002926:	0000f497          	auipc	s1,0xf
    8000292a:	dc248493          	addi	s1,s1,-574 # 800116e8 <proc>
			run_time_ratio = (p->performance.rutime * decay_factors[p->priority]) / (p->performance.rutime + p->performance.stime);
    8000292e:	00006a97          	auipc	s5,0x6
    80002932:	0f2a8a93          	addi	s5,s5,242 # 80008a20 <initcode>
			run_time_ratio = 0;
    80002936:	4b81                	li	s7,0
		if (p->state == RUNNABLE && run_time_ratio < least_runtime_ratio)
    80002938:	4a0d                	li	s4,3
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    8000293a:	00015997          	auipc	s3,0x15
    8000293e:	1ae98993          	addi	s3,s3,430 # 80017ae8 <tickslock>
    80002942:	a805                	j	80002972 <sched_cfsd+0x82>
			run_time_ratio = (p->performance.rutime * decay_factors[p->priority]) / (p->performance.rutime + p->performance.stime);
    80002944:	4cbc                	lw	a5,88(s1)
    80002946:	078a                	slli	a5,a5,0x2
    80002948:	97d6                	add	a5,a5,s5
    8000294a:	5f9c                	lw	a5,56(a5)
    8000294c:	02e787bb          	mulw	a5,a5,a4
    80002950:	40b4                	lw	a3,64(s1)
    80002952:	9f35                	addw	a4,a4,a3
    80002954:	02e7c7bb          	divw	a5,a5,a4
		if (p->state == RUNNABLE && run_time_ratio < least_runtime_ratio)
    80002958:	4c98                	lw	a4,24(s1)
    8000295a:	03470763          	beq	a4,s4,80002988 <sched_cfsd+0x98>
		release(&p->lock);
    8000295e:	8526                	mv	a0,s1
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	316080e7          	jalr	790(ra) # 80000c76 <release>
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80002968:	19048493          	addi	s1,s1,400
    8000296c:	2905                	addiw	s2,s2,1
    8000296e:	03348263          	beq	s1,s3,80002992 <sched_cfsd+0xa2>
		acquire(&p->lock);
    80002972:	8526                	mv	a0,s1
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	24e080e7          	jalr	590(ra) # 80000bc2 <acquire>
		if (p->performance.rutime == 0 && p->performance.stime == 0) {
    8000297c:	44b8                	lw	a4,72(s1)
    8000297e:	f379                	bnez	a4,80002944 <sched_cfsd+0x54>
    80002980:	40b4                	lw	a3,64(s1)
			run_time_ratio = 0;
    80002982:	87de                	mv	a5,s7
		if (p->performance.rutime == 0 && p->performance.stime == 0) {
    80002984:	daf1                	beqz	a3,80002958 <sched_cfsd+0x68>
    80002986:	bf7d                	j	80002944 <sched_cfsd+0x54>
		if (p->state == RUNNABLE && run_time_ratio < least_runtime_ratio)
    80002988:	fd67fbe3          	bgeu	a5,s6,8000295e <sched_cfsd+0x6e>
    8000298c:	8c4a                	mv	s8,s2
			least_runtime_ratio = run_time_ratio;   
    8000298e:	8b3e                	mv	s6,a5
    80002990:	b7f9                	j	8000295e <sched_cfsd+0x6e>
	first = &proc[proc_to_run_index];
    80002992:	19000493          	li	s1,400
    80002996:	029c04b3          	mul	s1,s8,s1
    8000299a:	0000f797          	auipc	a5,0xf
    8000299e:	d4e78793          	addi	a5,a5,-690 # 800116e8 <proc>
    800029a2:	94be                	add	s1,s1,a5
	acquire(&first->lock);
    800029a4:	8526                	mv	a0,s1
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	21c080e7          	jalr	540(ra) # 80000bc2 <acquire>
	if (first->state == RUNNABLE)
    800029ae:	4c98                	lw	a4,24(s1)
    800029b0:	478d                	li	a5,3
    800029b2:	02f70463          	beq	a4,a5,800029da <sched_cfsd+0xea>
	release(&first->lock);
    800029b6:	8526                	mv	a0,s1
    800029b8:	ffffe097          	auipc	ra,0xffffe
    800029bc:	2be080e7          	jalr	702(ra) # 80000c76 <release>
}
    800029c0:	60e6                	ld	ra,88(sp)
    800029c2:	6446                	ld	s0,80(sp)
    800029c4:	64a6                	ld	s1,72(sp)
    800029c6:	6906                	ld	s2,64(sp)
    800029c8:	79e2                	ld	s3,56(sp)
    800029ca:	7a42                	ld	s4,48(sp)
    800029cc:	7aa2                	ld	s5,40(sp)
    800029ce:	7b02                	ld	s6,32(sp)
    800029d0:	6be2                	ld	s7,24(sp)
    800029d2:	6c42                	ld	s8,16(sp)
    800029d4:	6ca2                	ld	s9,8(sp)
    800029d6:	6125                	addi	sp,sp,96
    800029d8:	8082                	ret
		first->state = RUNNING;
    800029da:	4791                	li	a5,4
    800029dc:	cc9c                	sw	a5,24(s1)
		c->proc = first;
    800029de:	0c9e                	slli	s9,s9,0x7
    800029e0:	0000f917          	auipc	s2,0xf
    800029e4:	8c090913          	addi	s2,s2,-1856 # 800112a0 <TURNLOCK>
    800029e8:	9966                	add	s2,s2,s9
    800029ea:	04993423          	sd	s1,72(s2)
		swtch_and_update_bursttime(c,first);
    800029ee:	85a6                	mv	a1,s1
    800029f0:	0000f517          	auipc	a0,0xf
    800029f4:	8f850513          	addi	a0,a0,-1800 # 800112e8 <cpus>
    800029f8:	9566                	add	a0,a0,s9
    800029fa:	00000097          	auipc	ra,0x0
    800029fe:	cf8080e7          	jalr	-776(ra) # 800026f2 <swtch_and_update_bursttime>
		c->proc = 0;
    80002a02:	04093423          	sd	zero,72(s2)
    80002a06:	bf45                	j	800029b6 <sched_cfsd+0xc6>

0000000080002a08 <update_perf>:

// ADDED: update_perf
void update_perf(uint ticks, struct proc *p)
{
    80002a08:	1141                	addi	sp,sp,-16
    80002a0a:	e422                	sd	s0,8(sp)
    80002a0c:	0800                	addi	s0,sp,16
	switch (p->state)
    80002a0e:	4d9c                	lw	a5,24(a1)
    80002a10:	4711                	li	a4,4
    80002a12:	02e78763          	beq	a5,a4,80002a40 <update_perf+0x38>
    80002a16:	00f76c63          	bltu	a4,a5,80002a2e <update_perf+0x26>
    80002a1a:	4709                	li	a4,2
    80002a1c:	02e78b63          	beq	a5,a4,80002a52 <update_perf+0x4a>
    80002a20:	470d                	li	a4,3
    80002a22:	02e79563          	bne	a5,a4,80002a4c <update_perf+0x44>
		break;
	case SLEEPING:
		p->performance.stime++;
		break;
	case RUNNABLE:
		p->performance.retime++;
    80002a26:	41fc                	lw	a5,68(a1)
    80002a28:	2785                	addiw	a5,a5,1
    80002a2a:	c1fc                	sw	a5,68(a1)
		break;
    80002a2c:	a005                	j	80002a4c <update_perf+0x44>
	switch (p->state)
    80002a2e:	4715                	li	a4,5
    80002a30:	00e79e63          	bne	a5,a4,80002a4c <update_perf+0x44>
	case ZOMBIE:
		if (p->performance.ttime == -1)
    80002a34:	5dd8                	lw	a4,60(a1)
    80002a36:	57fd                	li	a5,-1
    80002a38:	00f71a63          	bne	a4,a5,80002a4c <update_perf+0x44>
			p->performance.ttime = ticks;
    80002a3c:	ddc8                	sw	a0,60(a1)
		break;
	default:
		break;
	}
}
    80002a3e:	a039                	j	80002a4c <update_perf+0x44>
		p->burst++;
    80002a40:	49fc                	lw	a5,84(a1)
    80002a42:	2785                	addiw	a5,a5,1
    80002a44:	c9fc                	sw	a5,84(a1)
		p->performance.rutime++;
    80002a46:	45bc                	lw	a5,72(a1)
    80002a48:	2785                	addiw	a5,a5,1
    80002a4a:	c5bc                	sw	a5,72(a1)
}
    80002a4c:	6422                	ld	s0,8(sp)
    80002a4e:	0141                	addi	sp,sp,16
    80002a50:	8082                	ret
		p->performance.stime++;
    80002a52:	41bc                	lw	a5,64(a1)
    80002a54:	2785                	addiw	a5,a5,1
    80002a56:	c1bc                	sw	a5,64(a1)
		break;
    80002a58:	bfd5                	j	80002a4c <update_perf+0x44>

0000000080002a5a <wait_stat>:
{
    80002a5a:	711d                	addi	sp,sp,-96
    80002a5c:	ec86                	sd	ra,88(sp)
    80002a5e:	e8a2                	sd	s0,80(sp)
    80002a60:	e4a6                	sd	s1,72(sp)
    80002a62:	e0ca                	sd	s2,64(sp)
    80002a64:	fc4e                	sd	s3,56(sp)
    80002a66:	f852                	sd	s4,48(sp)
    80002a68:	f456                	sd	s5,40(sp)
    80002a6a:	f05a                	sd	s6,32(sp)
    80002a6c:	ec5e                	sd	s7,24(sp)
    80002a6e:	e862                	sd	s8,16(sp)
    80002a70:	e466                	sd	s9,8(sp)
    80002a72:	1080                	addi	s0,sp,96
    80002a74:	8b2a                	mv	s6,a0
    80002a76:	8bae                	mv	s7,a1
	struct proc *p = myproc();
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	f4a080e7          	jalr	-182(ra) # 800019c2 <myproc>
    80002a80:	892a                	mv	s2,a0
	acquire(&wait_lock);
    80002a82:	0000f517          	auipc	a0,0xf
    80002a86:	84e50513          	addi	a0,a0,-1970 # 800112d0 <wait_lock>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	138080e7          	jalr	312(ra) # 80000bc2 <acquire>
		havekids = 0;
    80002a92:	4c01                	li	s8,0
				if (np->state == ZOMBIE)
    80002a94:	4a15                	li	s4,5
				havekids = 1;
    80002a96:	4a85                	li	s5,1
		for (np = proc; np < &proc[NPROC]; np++)
    80002a98:	00015997          	auipc	s3,0x15
    80002a9c:	05098993          	addi	s3,s3,80 # 80017ae8 <tickslock>
		sleep(p, &wait_lock); //DOC: wait-sleep
    80002aa0:	0000fc97          	auipc	s9,0xf
    80002aa4:	830c8c93          	addi	s9,s9,-2000 # 800112d0 <wait_lock>
		havekids = 0;
    80002aa8:	8762                	mv	a4,s8
		for (np = proc; np < &proc[NPROC]; np++)
    80002aaa:	0000f497          	auipc	s1,0xf
    80002aae:	c3e48493          	addi	s1,s1,-962 # 800116e8 <proc>
    80002ab2:	a85d                	j	80002b68 <wait_stat+0x10e>
					pid = np->pid;
    80002ab4:	0304a983          	lw	s3,48(s1)
					update_perf(ticks, np);
    80002ab8:	85a6                	mv	a1,s1
    80002aba:	00006517          	auipc	a0,0x6
    80002abe:	57652503          	lw	a0,1398(a0) # 80009030 <ticks>
    80002ac2:	00000097          	auipc	ra,0x0
    80002ac6:	f46080e7          	jalr	-186(ra) # 80002a08 <update_perf>
					if (status != 0 && copyout(p->pagetable, status, (char *)&np->xstate,
    80002aca:	000b0e63          	beqz	s6,80002ae6 <wait_stat+0x8c>
    80002ace:	4691                	li	a3,4
    80002ad0:	02c48613          	addi	a2,s1,44
    80002ad4:	85da                	mv	a1,s6
    80002ad6:	07893503          	ld	a0,120(s2)
    80002ada:	fffff097          	auipc	ra,0xfffff
    80002ade:	b64080e7          	jalr	-1180(ra) # 8000163e <copyout>
    80002ae2:	04054163          	bltz	a0,80002b24 <wait_stat+0xca>
					if (copyout(p->pagetable, performance, (char *)&(np->performance), sizeof(struct perf)) < 0)
    80002ae6:	46e1                	li	a3,24
    80002ae8:	03848613          	addi	a2,s1,56
    80002aec:	85de                	mv	a1,s7
    80002aee:	07893503          	ld	a0,120(s2)
    80002af2:	fffff097          	auipc	ra,0xfffff
    80002af6:	b4c080e7          	jalr	-1204(ra) # 8000163e <copyout>
    80002afa:	04054463          	bltz	a0,80002b42 <wait_stat+0xe8>
					freeproc(np);
    80002afe:	8526                	mv	a0,s1
    80002b00:	fffff097          	auipc	ra,0xfffff
    80002b04:	074080e7          	jalr	116(ra) # 80001b74 <freeproc>
					release(&np->lock);
    80002b08:	8526                	mv	a0,s1
    80002b0a:	ffffe097          	auipc	ra,0xffffe
    80002b0e:	16c080e7          	jalr	364(ra) # 80000c76 <release>
					release(&wait_lock);
    80002b12:	0000e517          	auipc	a0,0xe
    80002b16:	7be50513          	addi	a0,a0,1982 # 800112d0 <wait_lock>
    80002b1a:	ffffe097          	auipc	ra,0xffffe
    80002b1e:	15c080e7          	jalr	348(ra) # 80000c76 <release>
					return pid;
    80002b22:	a051                	j	80002ba6 <wait_stat+0x14c>
						release(&np->lock);
    80002b24:	8526                	mv	a0,s1
    80002b26:	ffffe097          	auipc	ra,0xffffe
    80002b2a:	150080e7          	jalr	336(ra) # 80000c76 <release>
						release(&wait_lock);
    80002b2e:	0000e517          	auipc	a0,0xe
    80002b32:	7a250513          	addi	a0,a0,1954 # 800112d0 <wait_lock>
    80002b36:	ffffe097          	auipc	ra,0xffffe
    80002b3a:	140080e7          	jalr	320(ra) # 80000c76 <release>
						return -1;
    80002b3e:	59fd                	li	s3,-1
    80002b40:	a09d                	j	80002ba6 <wait_stat+0x14c>
						release(&np->lock);
    80002b42:	8526                	mv	a0,s1
    80002b44:	ffffe097          	auipc	ra,0xffffe
    80002b48:	132080e7          	jalr	306(ra) # 80000c76 <release>
						release(&wait_lock);
    80002b4c:	0000e517          	auipc	a0,0xe
    80002b50:	78450513          	addi	a0,a0,1924 # 800112d0 <wait_lock>
    80002b54:	ffffe097          	auipc	ra,0xffffe
    80002b58:	122080e7          	jalr	290(ra) # 80000c76 <release>
						return -1;
    80002b5c:	59fd                	li	s3,-1
    80002b5e:	a0a1                	j	80002ba6 <wait_stat+0x14c>
		for (np = proc; np < &proc[NPROC]; np++)
    80002b60:	19048493          	addi	s1,s1,400
    80002b64:	03348463          	beq	s1,s3,80002b8c <wait_stat+0x132>
			if (np->parent == p)
    80002b68:	70bc                	ld	a5,96(s1)
    80002b6a:	ff279be3          	bne	a5,s2,80002b60 <wait_stat+0x106>
				acquire(&np->lock);
    80002b6e:	8526                	mv	a0,s1
    80002b70:	ffffe097          	auipc	ra,0xffffe
    80002b74:	052080e7          	jalr	82(ra) # 80000bc2 <acquire>
				if (np->state == ZOMBIE)
    80002b78:	4c9c                	lw	a5,24(s1)
    80002b7a:	f3478de3          	beq	a5,s4,80002ab4 <wait_stat+0x5a>
				release(&np->lock);
    80002b7e:	8526                	mv	a0,s1
    80002b80:	ffffe097          	auipc	ra,0xffffe
    80002b84:	0f6080e7          	jalr	246(ra) # 80000c76 <release>
				havekids = 1;
    80002b88:	8756                	mv	a4,s5
    80002b8a:	bfd9                	j	80002b60 <wait_stat+0x106>
		if (!havekids || p->killed)
    80002b8c:	c701                	beqz	a4,80002b94 <wait_stat+0x13a>
    80002b8e:	02892783          	lw	a5,40(s2)
    80002b92:	cb85                	beqz	a5,80002bc2 <wait_stat+0x168>
			release(&wait_lock);
    80002b94:	0000e517          	auipc	a0,0xe
    80002b98:	73c50513          	addi	a0,a0,1852 # 800112d0 <wait_lock>
    80002b9c:	ffffe097          	auipc	ra,0xffffe
    80002ba0:	0da080e7          	jalr	218(ra) # 80000c76 <release>
			return -1;
    80002ba4:	59fd                	li	s3,-1
}
    80002ba6:	854e                	mv	a0,s3
    80002ba8:	60e6                	ld	ra,88(sp)
    80002baa:	6446                	ld	s0,80(sp)
    80002bac:	64a6                	ld	s1,72(sp)
    80002bae:	6906                	ld	s2,64(sp)
    80002bb0:	79e2                	ld	s3,56(sp)
    80002bb2:	7a42                	ld	s4,48(sp)
    80002bb4:	7aa2                	ld	s5,40(sp)
    80002bb6:	7b02                	ld	s6,32(sp)
    80002bb8:	6be2                	ld	s7,24(sp)
    80002bba:	6c42                	ld	s8,16(sp)
    80002bbc:	6ca2                	ld	s9,8(sp)
    80002bbe:	6125                	addi	sp,sp,96
    80002bc0:	8082                	ret
		sleep(p, &wait_lock); //DOC: wait-sleep
    80002bc2:	85e6                	mv	a1,s9
    80002bc4:	854a                	mv	a0,s2
    80002bc6:	fffff097          	auipc	ra,0xfffff
    80002bca:	528080e7          	jalr	1320(ra) # 800020ee <sleep>
		havekids = 0;
    80002bce:	bde9                	j	80002aa8 <wait_stat+0x4e>

0000000080002bd0 <update_perfs>:

// ADDED: update_perfs
void update_perfs(uint ticks)
{
    80002bd0:	7179                	addi	sp,sp,-48
    80002bd2:	f406                	sd	ra,40(sp)
    80002bd4:	f022                	sd	s0,32(sp)
    80002bd6:	ec26                	sd	s1,24(sp)
    80002bd8:	e84a                	sd	s2,16(sp)
    80002bda:	e44e                	sd	s3,8(sp)
    80002bdc:	1800                	addi	s0,sp,48
    80002bde:	892a                	mv	s2,a0
	struct proc *p;
	for (p = proc; p < &proc[NPROC]; p++)
    80002be0:	0000f497          	auipc	s1,0xf
    80002be4:	b0848493          	addi	s1,s1,-1272 # 800116e8 <proc>
    80002be8:	00015997          	auipc	s3,0x15
    80002bec:	f0098993          	addi	s3,s3,-256 # 80017ae8 <tickslock>
	{
		acquire(&p->lock);
    80002bf0:	8526                	mv	a0,s1
    80002bf2:	ffffe097          	auipc	ra,0xffffe
    80002bf6:	fd0080e7          	jalr	-48(ra) # 80000bc2 <acquire>
		update_perf(ticks, p);
    80002bfa:	85a6                	mv	a1,s1
    80002bfc:	854a                	mv	a0,s2
    80002bfe:	00000097          	auipc	ra,0x0
    80002c02:	e0a080e7          	jalr	-502(ra) # 80002a08 <update_perf>
		release(&p->lock);
    80002c06:	8526                	mv	a0,s1
    80002c08:	ffffe097          	auipc	ra,0xffffe
    80002c0c:	06e080e7          	jalr	110(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80002c10:	19048493          	addi	s1,s1,400
    80002c14:	fd349ee3          	bne	s1,s3,80002bf0 <update_perfs+0x20>
	}
}
    80002c18:	70a2                	ld	ra,40(sp)
    80002c1a:	7402                	ld	s0,32(sp)
    80002c1c:	64e2                	ld	s1,24(sp)
    80002c1e:	6942                	ld	s2,16(sp)
    80002c20:	69a2                	ld	s3,8(sp)
    80002c22:	6145                	addi	sp,sp,48
    80002c24:	8082                	ret

0000000080002c26 <set_priority>:

// ADDED: set_priority
int set_priority(int priority) {
    80002c26:	1101                	addi	sp,sp,-32
    80002c28:	ec06                	sd	ra,24(sp)
    80002c2a:	e822                	sd	s0,16(sp)
    80002c2c:	e426                	sd	s1,8(sp)
    80002c2e:	1000                	addi	s0,sp,32
    80002c30:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    80002c32:	fffff097          	auipc	ra,0xfffff
    80002c36:	d90080e7          	jalr	-624(ra) # 800019c2 <myproc>
	if (priority >= 1 && priority <= 5) {
    80002c3a:	fff4871b          	addiw	a4,s1,-1
    80002c3e:	4791                	li	a5,4
    80002c40:	00e7e963          	bltu	a5,a4,80002c52 <set_priority+0x2c>
		p->priority = priority;
    80002c44:	cd24                	sw	s1,88(a0)
		return 0;
    80002c46:	4501                	li	a0,0
	}
	return -1;
    80002c48:	60e2                	ld	ra,24(sp)
    80002c4a:	6442                	ld	s0,16(sp)
    80002c4c:	64a2                	ld	s1,8(sp)
    80002c4e:	6105                	addi	sp,sp,32
    80002c50:	8082                	ret
	return -1;
    80002c52:	557d                	li	a0,-1
    80002c54:	bfd5                	j	80002c48 <set_priority+0x22>

0000000080002c56 <swtch>:
    80002c56:	00153023          	sd	ra,0(a0)
    80002c5a:	00253423          	sd	sp,8(a0)
    80002c5e:	e900                	sd	s0,16(a0)
    80002c60:	ed04                	sd	s1,24(a0)
    80002c62:	03253023          	sd	s2,32(a0)
    80002c66:	03353423          	sd	s3,40(a0)
    80002c6a:	03453823          	sd	s4,48(a0)
    80002c6e:	03553c23          	sd	s5,56(a0)
    80002c72:	05653023          	sd	s6,64(a0)
    80002c76:	05753423          	sd	s7,72(a0)
    80002c7a:	05853823          	sd	s8,80(a0)
    80002c7e:	05953c23          	sd	s9,88(a0)
    80002c82:	07a53023          	sd	s10,96(a0)
    80002c86:	07b53423          	sd	s11,104(a0)
    80002c8a:	0005b083          	ld	ra,0(a1)
    80002c8e:	0085b103          	ld	sp,8(a1)
    80002c92:	6980                	ld	s0,16(a1)
    80002c94:	6d84                	ld	s1,24(a1)
    80002c96:	0205b903          	ld	s2,32(a1)
    80002c9a:	0285b983          	ld	s3,40(a1)
    80002c9e:	0305ba03          	ld	s4,48(a1)
    80002ca2:	0385ba83          	ld	s5,56(a1)
    80002ca6:	0405bb03          	ld	s6,64(a1)
    80002caa:	0485bb83          	ld	s7,72(a1)
    80002cae:	0505bc03          	ld	s8,80(a1)
    80002cb2:	0585bc83          	ld	s9,88(a1)
    80002cb6:	0605bd03          	ld	s10,96(a1)
    80002cba:	0685bd83          	ld	s11,104(a1)
    80002cbe:	8082                	ret

0000000080002cc0 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002cc0:	1141                	addi	sp,sp,-16
    80002cc2:	e406                	sd	ra,8(sp)
    80002cc4:	e022                	sd	s0,0(sp)
    80002cc6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002cc8:	00005597          	auipc	a1,0x5
    80002ccc:	61858593          	addi	a1,a1,1560 # 800082e0 <states.0+0x30>
    80002cd0:	00015517          	auipc	a0,0x15
    80002cd4:	e1850513          	addi	a0,a0,-488 # 80017ae8 <tickslock>
    80002cd8:	ffffe097          	auipc	ra,0xffffe
    80002cdc:	e5a080e7          	jalr	-422(ra) # 80000b32 <initlock>
}
    80002ce0:	60a2                	ld	ra,8(sp)
    80002ce2:	6402                	ld	s0,0(sp)
    80002ce4:	0141                	addi	sp,sp,16
    80002ce6:	8082                	ret

0000000080002ce8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002ce8:	1141                	addi	sp,sp,-16
    80002cea:	e422                	sd	s0,8(sp)
    80002cec:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cee:	00003797          	auipc	a5,0x3
    80002cf2:	69278793          	addi	a5,a5,1682 # 80006380 <kernelvec>
    80002cf6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002cfa:	6422                	ld	s0,8(sp)
    80002cfc:	0141                	addi	sp,sp,16
    80002cfe:	8082                	ret

0000000080002d00 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002d00:	1141                	addi	sp,sp,-16
    80002d02:	e406                	sd	ra,8(sp)
    80002d04:	e022                	sd	s0,0(sp)
    80002d06:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d08:	fffff097          	auipc	ra,0xfffff
    80002d0c:	cba080e7          	jalr	-838(ra) # 800019c2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d10:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d14:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d16:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002d1a:	00004617          	auipc	a2,0x4
    80002d1e:	2e660613          	addi	a2,a2,742 # 80007000 <_trampoline>
    80002d22:	00004697          	auipc	a3,0x4
    80002d26:	2de68693          	addi	a3,a3,734 # 80007000 <_trampoline>
    80002d2a:	8e91                	sub	a3,a3,a2
    80002d2c:	040007b7          	lui	a5,0x4000
    80002d30:	17fd                	addi	a5,a5,-1
    80002d32:	07b2                	slli	a5,a5,0xc
    80002d34:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d36:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d3a:	6158                	ld	a4,128(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d3c:	180026f3          	csrr	a3,satp
    80002d40:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d42:	6158                	ld	a4,128(a0)
    80002d44:	7534                	ld	a3,104(a0)
    80002d46:	6585                	lui	a1,0x1
    80002d48:	96ae                	add	a3,a3,a1
    80002d4a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d4c:	6158                	ld	a4,128(a0)
    80002d4e:	00000697          	auipc	a3,0x0
    80002d52:	14868693          	addi	a3,a3,328 # 80002e96 <usertrap>
    80002d56:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002d58:	6158                	ld	a4,128(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d5a:	8692                	mv	a3,tp
    80002d5c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d5e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d62:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d66:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d6a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d6e:	6158                	ld	a4,128(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d70:	6f18                	ld	a4,24(a4)
    80002d72:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d76:	7d2c                	ld	a1,120(a0)
    80002d78:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002d7a:	00004717          	auipc	a4,0x4
    80002d7e:	31670713          	addi	a4,a4,790 # 80007090 <userret>
    80002d82:	8f11                	sub	a4,a4,a2
    80002d84:	97ba                	add	a5,a5,a4
  ((void (*)(uint64, uint64))fn)(TRAPFRAME, satp);
    80002d86:	577d                	li	a4,-1
    80002d88:	177e                	slli	a4,a4,0x3f
    80002d8a:	8dd9                	or	a1,a1,a4
    80002d8c:	02000537          	lui	a0,0x2000
    80002d90:	157d                	addi	a0,a0,-1
    80002d92:	0536                	slli	a0,a0,0xd
    80002d94:	9782                	jalr	a5
}
    80002d96:	60a2                	ld	ra,8(sp)
    80002d98:	6402                	ld	s0,0(sp)
    80002d9a:	0141                	addi	sp,sp,16
    80002d9c:	8082                	ret

0000000080002d9e <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002d9e:	1101                	addi	sp,sp,-32
    80002da0:	ec06                	sd	ra,24(sp)
    80002da2:	e822                	sd	s0,16(sp)
    80002da4:	e426                	sd	s1,8(sp)
    80002da6:	e04a                	sd	s2,0(sp)
    80002da8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002daa:	00015917          	auipc	s2,0x15
    80002dae:	d3e90913          	addi	s2,s2,-706 # 80017ae8 <tickslock>
    80002db2:	854a                	mv	a0,s2
    80002db4:	ffffe097          	auipc	ra,0xffffe
    80002db8:	e0e080e7          	jalr	-498(ra) # 80000bc2 <acquire>
  ticks++;
    80002dbc:	00006497          	auipc	s1,0x6
    80002dc0:	27448493          	addi	s1,s1,628 # 80009030 <ticks>
    80002dc4:	4088                	lw	a0,0(s1)
    80002dc6:	2505                	addiw	a0,a0,1
    80002dc8:	c088                	sw	a0,0(s1)
  update_perfs(ticks);
    80002dca:	2501                	sext.w	a0,a0
    80002dcc:	00000097          	auipc	ra,0x0
    80002dd0:	e04080e7          	jalr	-508(ra) # 80002bd0 <update_perfs>
  wakeup(&ticks);
    80002dd4:	8526                	mv	a0,s1
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	4a4080e7          	jalr	1188(ra) # 8000227a <wakeup>
  release(&tickslock);
    80002dde:	854a                	mv	a0,s2
    80002de0:	ffffe097          	auipc	ra,0xffffe
    80002de4:	e96080e7          	jalr	-362(ra) # 80000c76 <release>
}
    80002de8:	60e2                	ld	ra,24(sp)
    80002dea:	6442                	ld	s0,16(sp)
    80002dec:	64a2                	ld	s1,8(sp)
    80002dee:	6902                	ld	s2,0(sp)
    80002df0:	6105                	addi	sp,sp,32
    80002df2:	8082                	ret

0000000080002df4 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002df4:	1101                	addi	sp,sp,-32
    80002df6:	ec06                	sd	ra,24(sp)
    80002df8:	e822                	sd	s0,16(sp)
    80002dfa:	e426                	sd	s1,8(sp)
    80002dfc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dfe:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002e02:	00074d63          	bltz	a4,80002e1c <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002e06:	57fd                	li	a5,-1
    80002e08:	17fe                	slli	a5,a5,0x3f
    80002e0a:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002e0c:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002e0e:	06f70363          	beq	a4,a5,80002e74 <devintr+0x80>
  }
}
    80002e12:	60e2                	ld	ra,24(sp)
    80002e14:	6442                	ld	s0,16(sp)
    80002e16:	64a2                	ld	s1,8(sp)
    80002e18:	6105                	addi	sp,sp,32
    80002e1a:	8082                	ret
      (scause & 0xff) == 9)
    80002e1c:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002e20:	46a5                	li	a3,9
    80002e22:	fed792e3          	bne	a5,a3,80002e06 <devintr+0x12>
    int irq = plic_claim();
    80002e26:	00003097          	auipc	ra,0x3
    80002e2a:	662080e7          	jalr	1634(ra) # 80006488 <plic_claim>
    80002e2e:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002e30:	47a9                	li	a5,10
    80002e32:	02f50763          	beq	a0,a5,80002e60 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002e36:	4785                	li	a5,1
    80002e38:	02f50963          	beq	a0,a5,80002e6a <devintr+0x76>
    return 1;
    80002e3c:	4505                	li	a0,1
    else if (irq)
    80002e3e:	d8f1                	beqz	s1,80002e12 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e40:	85a6                	mv	a1,s1
    80002e42:	00005517          	auipc	a0,0x5
    80002e46:	4a650513          	addi	a0,a0,1190 # 800082e8 <states.0+0x38>
    80002e4a:	ffffd097          	auipc	ra,0xffffd
    80002e4e:	72a080e7          	jalr	1834(ra) # 80000574 <printf>
      plic_complete(irq);
    80002e52:	8526                	mv	a0,s1
    80002e54:	00003097          	auipc	ra,0x3
    80002e58:	658080e7          	jalr	1624(ra) # 800064ac <plic_complete>
    return 1;
    80002e5c:	4505                	li	a0,1
    80002e5e:	bf55                	j	80002e12 <devintr+0x1e>
      uartintr();
    80002e60:	ffffe097          	auipc	ra,0xffffe
    80002e64:	b26080e7          	jalr	-1242(ra) # 80000986 <uartintr>
    80002e68:	b7ed                	j	80002e52 <devintr+0x5e>
      virtio_disk_intr();
    80002e6a:	00004097          	auipc	ra,0x4
    80002e6e:	ad4080e7          	jalr	-1324(ra) # 8000693e <virtio_disk_intr>
    80002e72:	b7c5                	j	80002e52 <devintr+0x5e>
    if (cpuid() == 0)
    80002e74:	fffff097          	auipc	ra,0xfffff
    80002e78:	b22080e7          	jalr	-1246(ra) # 80001996 <cpuid>
    80002e7c:	c901                	beqz	a0,80002e8c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e7e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e82:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e84:	14479073          	csrw	sip,a5
    return 2;
    80002e88:	4509                	li	a0,2
    80002e8a:	b761                	j	80002e12 <devintr+0x1e>
      clockintr();
    80002e8c:	00000097          	auipc	ra,0x0
    80002e90:	f12080e7          	jalr	-238(ra) # 80002d9e <clockintr>
    80002e94:	b7ed                	j	80002e7e <devintr+0x8a>

0000000080002e96 <usertrap>:
{
    80002e96:	1101                	addi	sp,sp,-32
    80002e98:	ec06                	sd	ra,24(sp)
    80002e9a:	e822                	sd	s0,16(sp)
    80002e9c:	e426                	sd	s1,8(sp)
    80002e9e:	e04a                	sd	s2,0(sp)
    80002ea0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ea2:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002ea6:	1007f793          	andi	a5,a5,256
    80002eaa:	e3ad                	bnez	a5,80002f0c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002eac:	00003797          	auipc	a5,0x3
    80002eb0:	4d478793          	addi	a5,a5,1236 # 80006380 <kernelvec>
    80002eb4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	b0a080e7          	jalr	-1270(ra) # 800019c2 <myproc>
    80002ec0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ec2:	615c                	ld	a5,128(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ec4:	14102773          	csrr	a4,sepc
    80002ec8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eca:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002ece:	47a1                	li	a5,8
    80002ed0:	04f71c63          	bne	a4,a5,80002f28 <usertrap+0x92>
    if (p->killed)
    80002ed4:	551c                	lw	a5,40(a0)
    80002ed6:	e3b9                	bnez	a5,80002f1c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002ed8:	60d8                	ld	a4,128(s1)
    80002eda:	6f1c                	ld	a5,24(a4)
    80002edc:	0791                	addi	a5,a5,4
    80002ede:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ee0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ee4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ee8:	10079073          	csrw	sstatus,a5
    syscall();
    80002eec:	00000097          	auipc	ra,0x0
    80002ef0:	3cc080e7          	jalr	972(ra) # 800032b8 <syscall>
  if (p->killed)
    80002ef4:	549c                	lw	a5,40(s1)
    80002ef6:	e3c5                	bnez	a5,80002f96 <usertrap+0x100>
  usertrapret();
    80002ef8:	00000097          	auipc	ra,0x0
    80002efc:	e08080e7          	jalr	-504(ra) # 80002d00 <usertrapret>
}
    80002f00:	60e2                	ld	ra,24(sp)
    80002f02:	6442                	ld	s0,16(sp)
    80002f04:	64a2                	ld	s1,8(sp)
    80002f06:	6902                	ld	s2,0(sp)
    80002f08:	6105                	addi	sp,sp,32
    80002f0a:	8082                	ret
    panic("usertrap: not from user mode");
    80002f0c:	00005517          	auipc	a0,0x5
    80002f10:	3fc50513          	addi	a0,a0,1020 # 80008308 <states.0+0x58>
    80002f14:	ffffd097          	auipc	ra,0xffffd
    80002f18:	616080e7          	jalr	1558(ra) # 8000052a <panic>
      exit(-1);
    80002f1c:	557d                	li	a0,-1
    80002f1e:	fffff097          	auipc	ra,0xfffff
    80002f22:	436080e7          	jalr	1078(ra) # 80002354 <exit>
    80002f26:	bf4d                	j	80002ed8 <usertrap+0x42>
  else if ((which_dev = devintr()) != 0)
    80002f28:	00000097          	auipc	ra,0x0
    80002f2c:	ecc080e7          	jalr	-308(ra) # 80002df4 <devintr>
    80002f30:	892a                	mv	s2,a0
    80002f32:	c501                	beqz	a0,80002f3a <usertrap+0xa4>
  if (p->killed)
    80002f34:	549c                	lw	a5,40(s1)
    80002f36:	c3a1                	beqz	a5,80002f76 <usertrap+0xe0>
    80002f38:	a815                	j	80002f6c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f3a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f3e:	5890                	lw	a2,48(s1)
    80002f40:	00005517          	auipc	a0,0x5
    80002f44:	3e850513          	addi	a0,a0,1000 # 80008328 <states.0+0x78>
    80002f48:	ffffd097          	auipc	ra,0xffffd
    80002f4c:	62c080e7          	jalr	1580(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f50:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f54:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f58:	00005517          	auipc	a0,0x5
    80002f5c:	40050513          	addi	a0,a0,1024 # 80008358 <states.0+0xa8>
    80002f60:	ffffd097          	auipc	ra,0xffffd
    80002f64:	614080e7          	jalr	1556(ra) # 80000574 <printf>
    p->killed = 1;
    80002f68:	4785                	li	a5,1
    80002f6a:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002f6c:	557d                	li	a0,-1
    80002f6e:	fffff097          	auipc	ra,0xfffff
    80002f72:	3e6080e7          	jalr	998(ra) # 80002354 <exit>
  if (which_dev == 2 && ticks % QUANTUM == 0)
    80002f76:	4789                	li	a5,2
    80002f78:	f8f910e3          	bne	s2,a5,80002ef8 <usertrap+0x62>
    80002f7c:	00006797          	auipc	a5,0x6
    80002f80:	0b47a783          	lw	a5,180(a5) # 80009030 <ticks>
    80002f84:	4715                	li	a4,5
    80002f86:	02e7f7bb          	remuw	a5,a5,a4
    80002f8a:	f7bd                	bnez	a5,80002ef8 <usertrap+0x62>
    yield();
    80002f8c:	fffff097          	auipc	ra,0xfffff
    80002f90:	126080e7          	jalr	294(ra) # 800020b2 <yield>
    80002f94:	b795                	j	80002ef8 <usertrap+0x62>
  int which_dev = 0;
    80002f96:	4901                	li	s2,0
    80002f98:	bfd1                	j	80002f6c <usertrap+0xd6>

0000000080002f9a <kerneltrap>:
{
    80002f9a:	7179                	addi	sp,sp,-48
    80002f9c:	f406                	sd	ra,40(sp)
    80002f9e:	f022                	sd	s0,32(sp)
    80002fa0:	ec26                	sd	s1,24(sp)
    80002fa2:	e84a                	sd	s2,16(sp)
    80002fa4:	e44e                	sd	s3,8(sp)
    80002fa6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fa8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fac:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fb0:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002fb4:	1004f793          	andi	a5,s1,256
    80002fb8:	cb85                	beqz	a5,80002fe8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fba:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fbe:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002fc0:	ef85                	bnez	a5,80002ff8 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002fc2:	00000097          	auipc	ra,0x0
    80002fc6:	e32080e7          	jalr	-462(ra) # 80002df4 <devintr>
    80002fca:	cd1d                	beqz	a0,80003008 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && ticks % QUANTUM == 0)
    80002fcc:	4789                	li	a5,2
    80002fce:	06f50a63          	beq	a0,a5,80003042 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002fd2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fd6:	10049073          	csrw	sstatus,s1
}
    80002fda:	70a2                	ld	ra,40(sp)
    80002fdc:	7402                	ld	s0,32(sp)
    80002fde:	64e2                	ld	s1,24(sp)
    80002fe0:	6942                	ld	s2,16(sp)
    80002fe2:	69a2                	ld	s3,8(sp)
    80002fe4:	6145                	addi	sp,sp,48
    80002fe6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002fe8:	00005517          	auipc	a0,0x5
    80002fec:	39050513          	addi	a0,a0,912 # 80008378 <states.0+0xc8>
    80002ff0:	ffffd097          	auipc	ra,0xffffd
    80002ff4:	53a080e7          	jalr	1338(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002ff8:	00005517          	auipc	a0,0x5
    80002ffc:	3a850513          	addi	a0,a0,936 # 800083a0 <states.0+0xf0>
    80003000:	ffffd097          	auipc	ra,0xffffd
    80003004:	52a080e7          	jalr	1322(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80003008:	85ce                	mv	a1,s3
    8000300a:	00005517          	auipc	a0,0x5
    8000300e:	3b650513          	addi	a0,a0,950 # 800083c0 <states.0+0x110>
    80003012:	ffffd097          	auipc	ra,0xffffd
    80003016:	562080e7          	jalr	1378(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000301a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000301e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003022:	00005517          	auipc	a0,0x5
    80003026:	3ae50513          	addi	a0,a0,942 # 800083d0 <states.0+0x120>
    8000302a:	ffffd097          	auipc	ra,0xffffd
    8000302e:	54a080e7          	jalr	1354(ra) # 80000574 <printf>
    panic("kerneltrap");
    80003032:	00005517          	auipc	a0,0x5
    80003036:	3b650513          	addi	a0,a0,950 # 800083e8 <states.0+0x138>
    8000303a:	ffffd097          	auipc	ra,0xffffd
    8000303e:	4f0080e7          	jalr	1264(ra) # 8000052a <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && ticks % QUANTUM == 0)
    80003042:	fffff097          	auipc	ra,0xfffff
    80003046:	980080e7          	jalr	-1664(ra) # 800019c2 <myproc>
    8000304a:	d541                	beqz	a0,80002fd2 <kerneltrap+0x38>
    8000304c:	fffff097          	auipc	ra,0xfffff
    80003050:	976080e7          	jalr	-1674(ra) # 800019c2 <myproc>
    80003054:	4d18                	lw	a4,24(a0)
    80003056:	4791                	li	a5,4
    80003058:	f6f71de3          	bne	a4,a5,80002fd2 <kerneltrap+0x38>
    8000305c:	00006797          	auipc	a5,0x6
    80003060:	fd47a783          	lw	a5,-44(a5) # 80009030 <ticks>
    80003064:	4715                	li	a4,5
    80003066:	02e7f7bb          	remuw	a5,a5,a4
    8000306a:	f7a5                	bnez	a5,80002fd2 <kerneltrap+0x38>
    yield();
    8000306c:	fffff097          	auipc	ra,0xfffff
    80003070:	046080e7          	jalr	70(ra) # 800020b2 <yield>
    80003074:	bfb9                	j	80002fd2 <kerneltrap+0x38>

0000000080003076 <argraw>:
	return strlen(buf);
}

static uint64
argraw(int n)
{
    80003076:	1101                	addi	sp,sp,-32
    80003078:	ec06                	sd	ra,24(sp)
    8000307a:	e822                	sd	s0,16(sp)
    8000307c:	e426                	sd	s1,8(sp)
    8000307e:	1000                	addi	s0,sp,32
    80003080:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    80003082:	fffff097          	auipc	ra,0xfffff
    80003086:	940080e7          	jalr	-1728(ra) # 800019c2 <myproc>
	switch (n)
    8000308a:	4795                	li	a5,5
    8000308c:	0497e163          	bltu	a5,s1,800030ce <argraw+0x58>
    80003090:	048a                	slli	s1,s1,0x2
    80003092:	00005717          	auipc	a4,0x5
    80003096:	4b670713          	addi	a4,a4,1206 # 80008548 <states.0+0x298>
    8000309a:	94ba                	add	s1,s1,a4
    8000309c:	409c                	lw	a5,0(s1)
    8000309e:	97ba                	add	a5,a5,a4
    800030a0:	8782                	jr	a5
	{
	case 0:
		return p->trapframe->a0;
    800030a2:	615c                	ld	a5,128(a0)
    800030a4:	7ba8                	ld	a0,112(a5)
	case 5:
		return p->trapframe->a5;
	}
	panic("argraw");
	return -1;
}
    800030a6:	60e2                	ld	ra,24(sp)
    800030a8:	6442                	ld	s0,16(sp)
    800030aa:	64a2                	ld	s1,8(sp)
    800030ac:	6105                	addi	sp,sp,32
    800030ae:	8082                	ret
		return p->trapframe->a1;
    800030b0:	615c                	ld	a5,128(a0)
    800030b2:	7fa8                	ld	a0,120(a5)
    800030b4:	bfcd                	j	800030a6 <argraw+0x30>
		return p->trapframe->a2;
    800030b6:	615c                	ld	a5,128(a0)
    800030b8:	63c8                	ld	a0,128(a5)
    800030ba:	b7f5                	j	800030a6 <argraw+0x30>
		return p->trapframe->a3;
    800030bc:	615c                	ld	a5,128(a0)
    800030be:	67c8                	ld	a0,136(a5)
    800030c0:	b7dd                	j	800030a6 <argraw+0x30>
		return p->trapframe->a4;
    800030c2:	615c                	ld	a5,128(a0)
    800030c4:	6bc8                	ld	a0,144(a5)
    800030c6:	b7c5                	j	800030a6 <argraw+0x30>
		return p->trapframe->a5;
    800030c8:	615c                	ld	a5,128(a0)
    800030ca:	6fc8                	ld	a0,152(a5)
    800030cc:	bfe9                	j	800030a6 <argraw+0x30>
	panic("argraw");
    800030ce:	00005517          	auipc	a0,0x5
    800030d2:	32a50513          	addi	a0,a0,810 # 800083f8 <states.0+0x148>
    800030d6:	ffffd097          	auipc	ra,0xffffd
    800030da:	454080e7          	jalr	1108(ra) # 8000052a <panic>

00000000800030de <fetchaddr>:
{
    800030de:	1101                	addi	sp,sp,-32
    800030e0:	ec06                	sd	ra,24(sp)
    800030e2:	e822                	sd	s0,16(sp)
    800030e4:	e426                	sd	s1,8(sp)
    800030e6:	e04a                	sd	s2,0(sp)
    800030e8:	1000                	addi	s0,sp,32
    800030ea:	84aa                	mv	s1,a0
    800030ec:	892e                	mv	s2,a1
	struct proc *p = myproc();
    800030ee:	fffff097          	auipc	ra,0xfffff
    800030f2:	8d4080e7          	jalr	-1836(ra) # 800019c2 <myproc>
	if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    800030f6:	793c                	ld	a5,112(a0)
    800030f8:	02f4f863          	bgeu	s1,a5,80003128 <fetchaddr+0x4a>
    800030fc:	00848713          	addi	a4,s1,8
    80003100:	02e7e663          	bltu	a5,a4,8000312c <fetchaddr+0x4e>
	if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003104:	46a1                	li	a3,8
    80003106:	8626                	mv	a2,s1
    80003108:	85ca                	mv	a1,s2
    8000310a:	7d28                	ld	a0,120(a0)
    8000310c:	ffffe097          	auipc	ra,0xffffe
    80003110:	5be080e7          	jalr	1470(ra) # 800016ca <copyin>
    80003114:	00a03533          	snez	a0,a0
    80003118:	40a00533          	neg	a0,a0
}
    8000311c:	60e2                	ld	ra,24(sp)
    8000311e:	6442                	ld	s0,16(sp)
    80003120:	64a2                	ld	s1,8(sp)
    80003122:	6902                	ld	s2,0(sp)
    80003124:	6105                	addi	sp,sp,32
    80003126:	8082                	ret
		return -1;
    80003128:	557d                	li	a0,-1
    8000312a:	bfcd                	j	8000311c <fetchaddr+0x3e>
    8000312c:	557d                	li	a0,-1
    8000312e:	b7fd                	j	8000311c <fetchaddr+0x3e>

0000000080003130 <fetchstr>:
{
    80003130:	7179                	addi	sp,sp,-48
    80003132:	f406                	sd	ra,40(sp)
    80003134:	f022                	sd	s0,32(sp)
    80003136:	ec26                	sd	s1,24(sp)
    80003138:	e84a                	sd	s2,16(sp)
    8000313a:	e44e                	sd	s3,8(sp)
    8000313c:	1800                	addi	s0,sp,48
    8000313e:	892a                	mv	s2,a0
    80003140:	84ae                	mv	s1,a1
    80003142:	89b2                	mv	s3,a2
	struct proc *p = myproc();
    80003144:	fffff097          	auipc	ra,0xfffff
    80003148:	87e080e7          	jalr	-1922(ra) # 800019c2 <myproc>
	int err = copyinstr(p->pagetable, buf, addr, max);
    8000314c:	86ce                	mv	a3,s3
    8000314e:	864a                	mv	a2,s2
    80003150:	85a6                	mv	a1,s1
    80003152:	7d28                	ld	a0,120(a0)
    80003154:	ffffe097          	auipc	ra,0xffffe
    80003158:	604080e7          	jalr	1540(ra) # 80001758 <copyinstr>
	if (err < 0)
    8000315c:	00054763          	bltz	a0,8000316a <fetchstr+0x3a>
	return strlen(buf);
    80003160:	8526                	mv	a0,s1
    80003162:	ffffe097          	auipc	ra,0xffffe
    80003166:	ce0080e7          	jalr	-800(ra) # 80000e42 <strlen>
}
    8000316a:	70a2                	ld	ra,40(sp)
    8000316c:	7402                	ld	s0,32(sp)
    8000316e:	64e2                	ld	s1,24(sp)
    80003170:	6942                	ld	s2,16(sp)
    80003172:	69a2                	ld	s3,8(sp)
    80003174:	6145                	addi	sp,sp,48
    80003176:	8082                	ret

0000000080003178 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80003178:	1101                	addi	sp,sp,-32
    8000317a:	ec06                	sd	ra,24(sp)
    8000317c:	e822                	sd	s0,16(sp)
    8000317e:	e426                	sd	s1,8(sp)
    80003180:	1000                	addi	s0,sp,32
    80003182:	84ae                	mv	s1,a1
	*ip = argraw(n);
    80003184:	00000097          	auipc	ra,0x0
    80003188:	ef2080e7          	jalr	-270(ra) # 80003076 <argraw>
    8000318c:	c088                	sw	a0,0(s1)
	return 0;
}
    8000318e:	4501                	li	a0,0
    80003190:	60e2                	ld	ra,24(sp)
    80003192:	6442                	ld	s0,16(sp)
    80003194:	64a2                	ld	s1,8(sp)
    80003196:	6105                	addi	sp,sp,32
    80003198:	8082                	ret

000000008000319a <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    8000319a:	1101                	addi	sp,sp,-32
    8000319c:	ec06                	sd	ra,24(sp)
    8000319e:	e822                	sd	s0,16(sp)
    800031a0:	e426                	sd	s1,8(sp)
    800031a2:	1000                	addi	s0,sp,32
    800031a4:	84ae                	mv	s1,a1
	*ip = argraw(n);
    800031a6:	00000097          	auipc	ra,0x0
    800031aa:	ed0080e7          	jalr	-304(ra) # 80003076 <argraw>
    800031ae:	e088                	sd	a0,0(s1)
	return 0;
}
    800031b0:	4501                	li	a0,0
    800031b2:	60e2                	ld	ra,24(sp)
    800031b4:	6442                	ld	s0,16(sp)
    800031b6:	64a2                	ld	s1,8(sp)
    800031b8:	6105                	addi	sp,sp,32
    800031ba:	8082                	ret

00000000800031bc <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    800031bc:	1101                	addi	sp,sp,-32
    800031be:	ec06                	sd	ra,24(sp)
    800031c0:	e822                	sd	s0,16(sp)
    800031c2:	e426                	sd	s1,8(sp)
    800031c4:	e04a                	sd	s2,0(sp)
    800031c6:	1000                	addi	s0,sp,32
    800031c8:	84ae                	mv	s1,a1
    800031ca:	8932                	mv	s2,a2
	*ip = argraw(n);
    800031cc:	00000097          	auipc	ra,0x0
    800031d0:	eaa080e7          	jalr	-342(ra) # 80003076 <argraw>
	uint64 addr;
	if (argaddr(n, &addr) < 0)
		return -1;
	return fetchstr(addr, buf, max);
    800031d4:	864a                	mv	a2,s2
    800031d6:	85a6                	mv	a1,s1
    800031d8:	00000097          	auipc	ra,0x0
    800031dc:	f58080e7          	jalr	-168(ra) # 80003130 <fetchstr>
}
    800031e0:	60e2                	ld	ra,24(sp)
    800031e2:	6442                	ld	s0,16(sp)
    800031e4:	64a2                	ld	s1,8(sp)
    800031e6:	6902                	ld	s2,0(sp)
    800031e8:	6105                	addi	sp,sp,32
    800031ea:	8082                	ret

00000000800031ec <print_trace>:
	}
}

// ADDED
void print_trace(int arg)
{
    800031ec:	7179                	addi	sp,sp,-48
    800031ee:	f406                	sd	ra,40(sp)
    800031f0:	f022                	sd	s0,32(sp)
    800031f2:	ec26                	sd	s1,24(sp)
    800031f4:	e84a                	sd	s2,16(sp)
    800031f6:	e44e                	sd	s3,8(sp)
    800031f8:	1800                	addi	s0,sp,48
    800031fa:	89aa                	mv	s3,a0
	int num;
	struct proc *p = myproc();
    800031fc:	ffffe097          	auipc	ra,0xffffe
    80003200:	7c6080e7          	jalr	1990(ra) # 800019c2 <myproc>
	num = p->trapframe->a7;
    80003204:	615c                	ld	a5,128(a0)
    80003206:	0a87a903          	lw	s2,168(a5)

	int res = (1 << num) & p->trace_mask;
    8000320a:	4785                	li	a5,1
    8000320c:	012797bb          	sllw	a5,a5,s2
    80003210:	5958                	lw	a4,52(a0)
    80003212:	8ff9                	and	a5,a5,a4
	if (res != 0)
    80003214:	2781                	sext.w	a5,a5
    80003216:	eb81                	bnez	a5,80003226 <print_trace+0x3a>
		else
		{
			printf("syscall %s  -> %d\n", syscallnames[num], p->trapframe->a0);
		}
	}
} // ADDED
    80003218:	70a2                	ld	ra,40(sp)
    8000321a:	7402                	ld	s0,32(sp)
    8000321c:	64e2                	ld	s1,24(sp)
    8000321e:	6942                	ld	s2,16(sp)
    80003220:	69a2                	ld	s3,8(sp)
    80003222:	6145                	addi	sp,sp,48
    80003224:	8082                	ret
    80003226:	84aa                	mv	s1,a0
		printf("%d: ", p->pid);
    80003228:	590c                	lw	a1,48(a0)
    8000322a:	00005517          	auipc	a0,0x5
    8000322e:	1d650513          	addi	a0,a0,470 # 80008400 <states.0+0x150>
    80003232:	ffffd097          	auipc	ra,0xffffd
    80003236:	342080e7          	jalr	834(ra) # 80000574 <printf>
		if (num == SYS_fork)
    8000323a:	4785                	li	a5,1
    8000323c:	02f90c63          	beq	s2,a5,80003274 <print_trace+0x88>
		else if (num == SYS_kill || num == SYS_sbrk)
    80003240:	4799                	li	a5,6
    80003242:	00f90563          	beq	s2,a5,8000324c <print_trace+0x60>
    80003246:	47b1                	li	a5,12
    80003248:	04f91563          	bne	s2,a5,80003292 <print_trace+0xa6>
			printf("syscall %s %d -> %d\n", syscallnames[num], arg, p->trapframe->a0);
    8000324c:	60d8                	ld	a4,128(s1)
    8000324e:	090e                	slli	s2,s2,0x3
    80003250:	00005797          	auipc	a5,0x5
    80003254:	31078793          	addi	a5,a5,784 # 80008560 <syscallnames>
    80003258:	993e                	add	s2,s2,a5
    8000325a:	7b34                	ld	a3,112(a4)
    8000325c:	864e                	mv	a2,s3
    8000325e:	00093583          	ld	a1,0(s2)
    80003262:	00005517          	auipc	a0,0x5
    80003266:	1c650513          	addi	a0,a0,454 # 80008428 <states.0+0x178>
    8000326a:	ffffd097          	auipc	ra,0xffffd
    8000326e:	30a080e7          	jalr	778(ra) # 80000574 <printf>
    80003272:	b75d                	j	80003218 <print_trace+0x2c>
			printf("syscall %s NULL -> %d\n", syscallnames[num], p->trapframe->a0);
    80003274:	60dc                	ld	a5,128(s1)
    80003276:	7bb0                	ld	a2,112(a5)
    80003278:	00005597          	auipc	a1,0x5
    8000327c:	19058593          	addi	a1,a1,400 # 80008408 <states.0+0x158>
    80003280:	00005517          	auipc	a0,0x5
    80003284:	19050513          	addi	a0,a0,400 # 80008410 <states.0+0x160>
    80003288:	ffffd097          	auipc	ra,0xffffd
    8000328c:	2ec080e7          	jalr	748(ra) # 80000574 <printf>
    80003290:	b761                	j	80003218 <print_trace+0x2c>
			printf("syscall %s  -> %d\n", syscallnames[num], p->trapframe->a0);
    80003292:	60d8                	ld	a4,128(s1)
    80003294:	090e                	slli	s2,s2,0x3
    80003296:	00005797          	auipc	a5,0x5
    8000329a:	2ca78793          	addi	a5,a5,714 # 80008560 <syscallnames>
    8000329e:	993e                	add	s2,s2,a5
    800032a0:	7b30                	ld	a2,112(a4)
    800032a2:	00093583          	ld	a1,0(s2)
    800032a6:	00005517          	auipc	a0,0x5
    800032aa:	19a50513          	addi	a0,a0,410 # 80008440 <states.0+0x190>
    800032ae:	ffffd097          	auipc	ra,0xffffd
    800032b2:	2c6080e7          	jalr	710(ra) # 80000574 <printf>
} // ADDED
    800032b6:	b78d                	j	80003218 <print_trace+0x2c>

00000000800032b8 <syscall>:
{
    800032b8:	7179                	addi	sp,sp,-48
    800032ba:	f406                	sd	ra,40(sp)
    800032bc:	f022                	sd	s0,32(sp)
    800032be:	ec26                	sd	s1,24(sp)
    800032c0:	e84a                	sd	s2,16(sp)
    800032c2:	1800                	addi	s0,sp,48
	struct proc *p = myproc();
    800032c4:	ffffe097          	auipc	ra,0xffffe
    800032c8:	6fe080e7          	jalr	1790(ra) # 800019c2 <myproc>
    800032cc:	84aa                	mv	s1,a0
	num = p->trapframe->a7;
    800032ce:	615c                	ld	a5,128(a0)
    800032d0:	77dc                	ld	a5,168(a5)
    800032d2:	0007869b          	sext.w	a3,a5
	if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    800032d6:	37fd                	addiw	a5,a5,-1
    800032d8:	4761                	li	a4,24
    800032da:	02f76e63          	bltu	a4,a5,80003316 <syscall+0x5e>
    800032de:	00369713          	slli	a4,a3,0x3
    800032e2:	00005797          	auipc	a5,0x5
    800032e6:	27e78793          	addi	a5,a5,638 # 80008560 <syscallnames>
    800032ea:	97ba                	add	a5,a5,a4
    800032ec:	0d07b903          	ld	s2,208(a5)
    800032f0:	02090363          	beqz	s2,80003316 <syscall+0x5e>
		argint(0, &arg); // ADDED
    800032f4:	fdc40593          	addi	a1,s0,-36
    800032f8:	4501                	li	a0,0
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	e7e080e7          	jalr	-386(ra) # 80003178 <argint>
		p->trapframe->a0 = syscalls[num]();
    80003302:	60c4                	ld	s1,128(s1)
    80003304:	9902                	jalr	s2
    80003306:	f8a8                	sd	a0,112(s1)
		print_trace(arg); // ADDED
    80003308:	fdc42503          	lw	a0,-36(s0)
    8000330c:	00000097          	auipc	ra,0x0
    80003310:	ee0080e7          	jalr	-288(ra) # 800031ec <print_trace>
    80003314:	a839                	j	80003332 <syscall+0x7a>
		printf("%d %s: unknown sys call %d\n",
    80003316:	18048613          	addi	a2,s1,384
    8000331a:	588c                	lw	a1,48(s1)
    8000331c:	00005517          	auipc	a0,0x5
    80003320:	13c50513          	addi	a0,a0,316 # 80008458 <states.0+0x1a8>
    80003324:	ffffd097          	auipc	ra,0xffffd
    80003328:	250080e7          	jalr	592(ra) # 80000574 <printf>
		p->trapframe->a0 = -1;
    8000332c:	60dc                	ld	a5,128(s1)
    8000332e:	577d                	li	a4,-1
    80003330:	fbb8                	sd	a4,112(a5)
}
    80003332:	70a2                	ld	ra,40(sp)
    80003334:	7402                	ld	s0,32(sp)
    80003336:	64e2                	ld	s1,24(sp)
    80003338:	6942                	ld	s2,16(sp)
    8000333a:	6145                	addi	sp,sp,48
    8000333c:	8082                	ret

000000008000333e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000333e:	1101                	addi	sp,sp,-32
    80003340:	ec06                	sd	ra,24(sp)
    80003342:	e822                	sd	s0,16(sp)
    80003344:	1000                	addi	s0,sp,32
  int n;
  if (argint(0, &n) < 0)
    80003346:	fec40593          	addi	a1,s0,-20
    8000334a:	4501                	li	a0,0
    8000334c:	00000097          	auipc	ra,0x0
    80003350:	e2c080e7          	jalr	-468(ra) # 80003178 <argint>
    return -1;
    80003354:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80003356:	00054963          	bltz	a0,80003368 <sys_exit+0x2a>
  exit(n);
    8000335a:	fec42503          	lw	a0,-20(s0)
    8000335e:	fffff097          	auipc	ra,0xfffff
    80003362:	ff6080e7          	jalr	-10(ra) # 80002354 <exit>
  return 0; // not reached
    80003366:	4781                	li	a5,0
}
    80003368:	853e                	mv	a0,a5
    8000336a:	60e2                	ld	ra,24(sp)
    8000336c:	6442                	ld	s0,16(sp)
    8000336e:	6105                	addi	sp,sp,32
    80003370:	8082                	ret

0000000080003372 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003372:	1141                	addi	sp,sp,-16
    80003374:	e406                	sd	ra,8(sp)
    80003376:	e022                	sd	s0,0(sp)
    80003378:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000337a:	ffffe097          	auipc	ra,0xffffe
    8000337e:	648080e7          	jalr	1608(ra) # 800019c2 <myproc>
}
    80003382:	5908                	lw	a0,48(a0)
    80003384:	60a2                	ld	ra,8(sp)
    80003386:	6402                	ld	s0,0(sp)
    80003388:	0141                	addi	sp,sp,16
    8000338a:	8082                	ret

000000008000338c <sys_fork>:

uint64
sys_fork(void)
{
    8000338c:	1141                	addi	sp,sp,-16
    8000338e:	e406                	sd	ra,8(sp)
    80003390:	e022                	sd	s0,0(sp)
    80003392:	0800                	addi	s0,sp,16
  return fork();
    80003394:	fffff097          	auipc	ra,0xfffff
    80003398:	a1e080e7          	jalr	-1506(ra) # 80001db2 <fork>
}
    8000339c:	60a2                	ld	ra,8(sp)
    8000339e:	6402                	ld	s0,0(sp)
    800033a0:	0141                	addi	sp,sp,16
    800033a2:	8082                	ret

00000000800033a4 <sys_wait>:

uint64
sys_wait(void)
{
    800033a4:	1101                	addi	sp,sp,-32
    800033a6:	ec06                	sd	ra,24(sp)
    800033a8:	e822                	sd	s0,16(sp)
    800033aa:	1000                	addi	s0,sp,32
  uint64 p;
  if (argaddr(0, &p) < 0)
    800033ac:	fe840593          	addi	a1,s0,-24
    800033b0:	4501                	li	a0,0
    800033b2:	00000097          	auipc	ra,0x0
    800033b6:	de8080e7          	jalr	-536(ra) # 8000319a <argaddr>
    800033ba:	87aa                	mv	a5,a0
    return -1;
    800033bc:	557d                	li	a0,-1
  if (argaddr(0, &p) < 0)
    800033be:	0007c863          	bltz	a5,800033ce <sys_wait+0x2a>
  return wait(p);
    800033c2:	fe843503          	ld	a0,-24(s0)
    800033c6:	fffff097          	auipc	ra,0xfffff
    800033ca:	d8c080e7          	jalr	-628(ra) # 80002152 <wait>
}
    800033ce:	60e2                	ld	ra,24(sp)
    800033d0:	6442                	ld	s0,16(sp)
    800033d2:	6105                	addi	sp,sp,32
    800033d4:	8082                	ret

00000000800033d6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800033d6:	7179                	addi	sp,sp,-48
    800033d8:	f406                	sd	ra,40(sp)
    800033da:	f022                	sd	s0,32(sp)
    800033dc:	ec26                	sd	s1,24(sp)
    800033de:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if (argint(0, &n) < 0)
    800033e0:	fdc40593          	addi	a1,s0,-36
    800033e4:	4501                	li	a0,0
    800033e6:	00000097          	auipc	ra,0x0
    800033ea:	d92080e7          	jalr	-622(ra) # 80003178 <argint>
    return -1;
    800033ee:	54fd                	li	s1,-1
  if (argint(0, &n) < 0)
    800033f0:	00054f63          	bltz	a0,8000340e <sys_sbrk+0x38>
  addr = myproc()->sz;
    800033f4:	ffffe097          	auipc	ra,0xffffe
    800033f8:	5ce080e7          	jalr	1486(ra) # 800019c2 <myproc>
    800033fc:	5924                	lw	s1,112(a0)
  if (growproc(n) < 0)
    800033fe:	fdc42503          	lw	a0,-36(s0)
    80003402:	fffff097          	auipc	ra,0xfffff
    80003406:	93c080e7          	jalr	-1732(ra) # 80001d3e <growproc>
    8000340a:	00054863          	bltz	a0,8000341a <sys_sbrk+0x44>
    return -1;
  return addr;
}
    8000340e:	8526                	mv	a0,s1
    80003410:	70a2                	ld	ra,40(sp)
    80003412:	7402                	ld	s0,32(sp)
    80003414:	64e2                	ld	s1,24(sp)
    80003416:	6145                	addi	sp,sp,48
    80003418:	8082                	ret
    return -1;
    8000341a:	54fd                	li	s1,-1
    8000341c:	bfcd                	j	8000340e <sys_sbrk+0x38>

000000008000341e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000341e:	7139                	addi	sp,sp,-64
    80003420:	fc06                	sd	ra,56(sp)
    80003422:	f822                	sd	s0,48(sp)
    80003424:	f426                	sd	s1,40(sp)
    80003426:	f04a                	sd	s2,32(sp)
    80003428:	ec4e                	sd	s3,24(sp)
    8000342a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if (argint(0, &n) < 0)
    8000342c:	fcc40593          	addi	a1,s0,-52
    80003430:	4501                	li	a0,0
    80003432:	00000097          	auipc	ra,0x0
    80003436:	d46080e7          	jalr	-698(ra) # 80003178 <argint>
    return -1;
    8000343a:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    8000343c:	06054563          	bltz	a0,800034a6 <sys_sleep+0x88>
  acquire(&tickslock);
    80003440:	00014517          	auipc	a0,0x14
    80003444:	6a850513          	addi	a0,a0,1704 # 80017ae8 <tickslock>
    80003448:	ffffd097          	auipc	ra,0xffffd
    8000344c:	77a080e7          	jalr	1914(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80003450:	00006917          	auipc	s2,0x6
    80003454:	be092903          	lw	s2,-1056(s2) # 80009030 <ticks>
  while (ticks - ticks0 < n)
    80003458:	fcc42783          	lw	a5,-52(s0)
    8000345c:	cf85                	beqz	a5,80003494 <sys_sleep+0x76>
    if (myproc()->killed)
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000345e:	00014997          	auipc	s3,0x14
    80003462:	68a98993          	addi	s3,s3,1674 # 80017ae8 <tickslock>
    80003466:	00006497          	auipc	s1,0x6
    8000346a:	bca48493          	addi	s1,s1,-1078 # 80009030 <ticks>
    if (myproc()->killed)
    8000346e:	ffffe097          	auipc	ra,0xffffe
    80003472:	554080e7          	jalr	1364(ra) # 800019c2 <myproc>
    80003476:	551c                	lw	a5,40(a0)
    80003478:	ef9d                	bnez	a5,800034b6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000347a:	85ce                	mv	a1,s3
    8000347c:	8526                	mv	a0,s1
    8000347e:	fffff097          	auipc	ra,0xfffff
    80003482:	c70080e7          	jalr	-912(ra) # 800020ee <sleep>
  while (ticks - ticks0 < n)
    80003486:	409c                	lw	a5,0(s1)
    80003488:	412787bb          	subw	a5,a5,s2
    8000348c:	fcc42703          	lw	a4,-52(s0)
    80003490:	fce7efe3          	bltu	a5,a4,8000346e <sys_sleep+0x50>
  }
  release(&tickslock);
    80003494:	00014517          	auipc	a0,0x14
    80003498:	65450513          	addi	a0,a0,1620 # 80017ae8 <tickslock>
    8000349c:	ffffd097          	auipc	ra,0xffffd
    800034a0:	7da080e7          	jalr	2010(ra) # 80000c76 <release>
  return 0;
    800034a4:	4781                	li	a5,0
}
    800034a6:	853e                	mv	a0,a5
    800034a8:	70e2                	ld	ra,56(sp)
    800034aa:	7442                	ld	s0,48(sp)
    800034ac:	74a2                	ld	s1,40(sp)
    800034ae:	7902                	ld	s2,32(sp)
    800034b0:	69e2                	ld	s3,24(sp)
    800034b2:	6121                	addi	sp,sp,64
    800034b4:	8082                	ret
      release(&tickslock);
    800034b6:	00014517          	auipc	a0,0x14
    800034ba:	63250513          	addi	a0,a0,1586 # 80017ae8 <tickslock>
    800034be:	ffffd097          	auipc	ra,0xffffd
    800034c2:	7b8080e7          	jalr	1976(ra) # 80000c76 <release>
      return -1;
    800034c6:	57fd                	li	a5,-1
    800034c8:	bff9                	j	800034a6 <sys_sleep+0x88>

00000000800034ca <sys_kill>:

uint64
sys_kill(void)
{
    800034ca:	1101                	addi	sp,sp,-32
    800034cc:	ec06                	sd	ra,24(sp)
    800034ce:	e822                	sd	s0,16(sp)
    800034d0:	1000                	addi	s0,sp,32
  int pid;

  if (argint(0, &pid) < 0)
    800034d2:	fec40593          	addi	a1,s0,-20
    800034d6:	4501                	li	a0,0
    800034d8:	00000097          	auipc	ra,0x0
    800034dc:	ca0080e7          	jalr	-864(ra) # 80003178 <argint>
    800034e0:	87aa                	mv	a5,a0
    return -1;
    800034e2:	557d                	li	a0,-1
  if (argint(0, &pid) < 0)
    800034e4:	0007c863          	bltz	a5,800034f4 <sys_kill+0x2a>
  return kill(pid);
    800034e8:	fec42503          	lw	a0,-20(s0)
    800034ec:	fffff097          	auipc	ra,0xfffff
    800034f0:	f3e080e7          	jalr	-194(ra) # 8000242a <kill>
}
    800034f4:	60e2                	ld	ra,24(sp)
    800034f6:	6442                	ld	s0,16(sp)
    800034f8:	6105                	addi	sp,sp,32
    800034fa:	8082                	ret

00000000800034fc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800034fc:	1101                	addi	sp,sp,-32
    800034fe:	ec06                	sd	ra,24(sp)
    80003500:	e822                	sd	s0,16(sp)
    80003502:	e426                	sd	s1,8(sp)
    80003504:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003506:	00014517          	auipc	a0,0x14
    8000350a:	5e250513          	addi	a0,a0,1506 # 80017ae8 <tickslock>
    8000350e:	ffffd097          	auipc	ra,0xffffd
    80003512:	6b4080e7          	jalr	1716(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80003516:	00006497          	auipc	s1,0x6
    8000351a:	b1a4a483          	lw	s1,-1254(s1) # 80009030 <ticks>
  release(&tickslock);
    8000351e:	00014517          	auipc	a0,0x14
    80003522:	5ca50513          	addi	a0,a0,1482 # 80017ae8 <tickslock>
    80003526:	ffffd097          	auipc	ra,0xffffd
    8000352a:	750080e7          	jalr	1872(ra) # 80000c76 <release>
  return xticks;
}
    8000352e:	02049513          	slli	a0,s1,0x20
    80003532:	9101                	srli	a0,a0,0x20
    80003534:	60e2                	ld	ra,24(sp)
    80003536:	6442                	ld	s0,16(sp)
    80003538:	64a2                	ld	s1,8(sp)
    8000353a:	6105                	addi	sp,sp,32
    8000353c:	8082                	ret

000000008000353e <sys_trace>:

//ADDED: sys_
uint64
sys_trace(void)
{
    8000353e:	1101                	addi	sp,sp,-32
    80003540:	ec06                	sd	ra,24(sp)
    80003542:	e822                	sd	s0,16(sp)
    80003544:	1000                	addi	s0,sp,32
  int mask, pid;
  if (argint(0, &mask) < 0 || argint(1, &pid) < 0)
    80003546:	fec40593          	addi	a1,s0,-20
    8000354a:	4501                	li	a0,0
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	c2c080e7          	jalr	-980(ra) # 80003178 <argint>
    80003554:	00055763          	bgez	a0,80003562 <sys_trace+0x24>
  {
  }
  return -1;
  return trace(mask, pid);
}
    80003558:	557d                	li	a0,-1
    8000355a:	60e2                	ld	ra,24(sp)
    8000355c:	6442                	ld	s0,16(sp)
    8000355e:	6105                	addi	sp,sp,32
    80003560:	8082                	ret
  if (argint(0, &mask) < 0 || argint(1, &pid) < 0)
    80003562:	fe840593          	addi	a1,s0,-24
    80003566:	4505                	li	a0,1
    80003568:	00000097          	auipc	ra,0x0
    8000356c:	c10080e7          	jalr	-1008(ra) # 80003178 <argint>
    80003570:	b7e5                	j	80003558 <sys_trace+0x1a>

0000000080003572 <sys_getmsk>:

uint64
sys_getmsk(void)
{
    80003572:	1101                	addi	sp,sp,-32
    80003574:	ec06                	sd	ra,24(sp)
    80003576:	e822                	sd	s0,16(sp)
    80003578:	1000                	addi	s0,sp,32
  int pid;
  if (argint(0, &pid) < 0)
    8000357a:	fec40593          	addi	a1,s0,-20
    8000357e:	4501                	li	a0,0
    80003580:	00000097          	auipc	ra,0x0
    80003584:	bf8080e7          	jalr	-1032(ra) # 80003178 <argint>
    80003588:	87aa                	mv	a5,a0
    return -1;
    8000358a:	557d                	li	a0,-1
  if (argint(0, &pid) < 0)
    8000358c:	0007c863          	bltz	a5,8000359c <sys_getmsk+0x2a>
  return getmsk(pid);
    80003590:	fec42503          	lw	a0,-20(s0)
    80003594:	fffff097          	auipc	ra,0xfffff
    80003598:	0ce080e7          	jalr	206(ra) # 80002662 <getmsk>
}
    8000359c:	60e2                	ld	ra,24(sp)
    8000359e:	6442                	ld	s0,16(sp)
    800035a0:	6105                	addi	sp,sp,32
    800035a2:	8082                	ret

00000000800035a4 <sys_wait_stat>:

uint64
sys_wait_stat(void)
{
    800035a4:	1101                	addi	sp,sp,-32
    800035a6:	ec06                	sd	ra,24(sp)
    800035a8:	e822                	sd	s0,16(sp)
    800035aa:	1000                	addi	s0,sp,32
  uint64 status;
  uint64 performance;
  if (argaddr(0, &status) < 0 || argaddr(1, &performance) < 0)
    800035ac:	fe840593          	addi	a1,s0,-24
    800035b0:	4501                	li	a0,0
    800035b2:	00000097          	auipc	ra,0x0
    800035b6:	be8080e7          	jalr	-1048(ra) # 8000319a <argaddr>
    return -1;
    800035ba:	57fd                	li	a5,-1
  if (argaddr(0, &status) < 0 || argaddr(1, &performance) < 0)
    800035bc:	02054563          	bltz	a0,800035e6 <sys_wait_stat+0x42>
    800035c0:	fe040593          	addi	a1,s0,-32
    800035c4:	4505                	li	a0,1
    800035c6:	00000097          	auipc	ra,0x0
    800035ca:	bd4080e7          	jalr	-1068(ra) # 8000319a <argaddr>
    return -1;
    800035ce:	57fd                	li	a5,-1
  if (argaddr(0, &status) < 0 || argaddr(1, &performance) < 0)
    800035d0:	00054b63          	bltz	a0,800035e6 <sys_wait_stat+0x42>
  return wait_stat(status, performance);
    800035d4:	fe043583          	ld	a1,-32(s0)
    800035d8:	fe843503          	ld	a0,-24(s0)
    800035dc:	fffff097          	auipc	ra,0xfffff
    800035e0:	47e080e7          	jalr	1150(ra) # 80002a5a <wait_stat>
    800035e4:	87aa                	mv	a5,a0
}
    800035e6:	853e                	mv	a0,a5
    800035e8:	60e2                	ld	ra,24(sp)
    800035ea:	6442                	ld	s0,16(sp)
    800035ec:	6105                	addi	sp,sp,32
    800035ee:	8082                	ret

00000000800035f0 <sys_set_priority>:

uint64
sys_set_priority(void)
{
    800035f0:	1101                	addi	sp,sp,-32
    800035f2:	ec06                	sd	ra,24(sp)
    800035f4:	e822                	sd	s0,16(sp)
    800035f6:	1000                	addi	s0,sp,32
  int priority;
  if (argint(0, &priority) < 0)
    800035f8:	fec40593          	addi	a1,s0,-20
    800035fc:	4501                	li	a0,0
    800035fe:	00000097          	auipc	ra,0x0
    80003602:	b7a080e7          	jalr	-1158(ra) # 80003178 <argint>
    80003606:	87aa                	mv	a5,a0
    return -1;
    80003608:	557d                	li	a0,-1
  if (argint(0, &priority) < 0)
    8000360a:	0007c863          	bltz	a5,8000361a <sys_set_priority+0x2a>
  return set_priority(priority);
    8000360e:	fec42503          	lw	a0,-20(s0)
    80003612:	fffff097          	auipc	ra,0xfffff
    80003616:	614080e7          	jalr	1556(ra) # 80002c26 <set_priority>
}
    8000361a:	60e2                	ld	ra,24(sp)
    8000361c:	6442                	ld	s0,16(sp)
    8000361e:	6105                	addi	sp,sp,32
    80003620:	8082                	ret

0000000080003622 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003622:	7179                	addi	sp,sp,-48
    80003624:	f406                	sd	ra,40(sp)
    80003626:	f022                	sd	s0,32(sp)
    80003628:	ec26                	sd	s1,24(sp)
    8000362a:	e84a                	sd	s2,16(sp)
    8000362c:	e44e                	sd	s3,8(sp)
    8000362e:	e052                	sd	s4,0(sp)
    80003630:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003632:	00005597          	auipc	a1,0x5
    80003636:	0ce58593          	addi	a1,a1,206 # 80008700 <syscalls+0xd0>
    8000363a:	00014517          	auipc	a0,0x14
    8000363e:	4c650513          	addi	a0,a0,1222 # 80017b00 <bcache>
    80003642:	ffffd097          	auipc	ra,0xffffd
    80003646:	4f0080e7          	jalr	1264(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000364a:	0001c797          	auipc	a5,0x1c
    8000364e:	4b678793          	addi	a5,a5,1206 # 8001fb00 <bcache+0x8000>
    80003652:	0001c717          	auipc	a4,0x1c
    80003656:	71670713          	addi	a4,a4,1814 # 8001fd68 <bcache+0x8268>
    8000365a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000365e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003662:	00014497          	auipc	s1,0x14
    80003666:	4b648493          	addi	s1,s1,1206 # 80017b18 <bcache+0x18>
    b->next = bcache.head.next;
    8000366a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000366c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000366e:	00005a17          	auipc	s4,0x5
    80003672:	09aa0a13          	addi	s4,s4,154 # 80008708 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003676:	2b893783          	ld	a5,696(s2)
    8000367a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000367c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003680:	85d2                	mv	a1,s4
    80003682:	01048513          	addi	a0,s1,16
    80003686:	00001097          	auipc	ra,0x1
    8000368a:	4c2080e7          	jalr	1218(ra) # 80004b48 <initsleeplock>
    bcache.head.next->prev = b;
    8000368e:	2b893783          	ld	a5,696(s2)
    80003692:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003694:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003698:	45848493          	addi	s1,s1,1112
    8000369c:	fd349de3          	bne	s1,s3,80003676 <binit+0x54>
  }
}
    800036a0:	70a2                	ld	ra,40(sp)
    800036a2:	7402                	ld	s0,32(sp)
    800036a4:	64e2                	ld	s1,24(sp)
    800036a6:	6942                	ld	s2,16(sp)
    800036a8:	69a2                	ld	s3,8(sp)
    800036aa:	6a02                	ld	s4,0(sp)
    800036ac:	6145                	addi	sp,sp,48
    800036ae:	8082                	ret

00000000800036b0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800036b0:	7179                	addi	sp,sp,-48
    800036b2:	f406                	sd	ra,40(sp)
    800036b4:	f022                	sd	s0,32(sp)
    800036b6:	ec26                	sd	s1,24(sp)
    800036b8:	e84a                	sd	s2,16(sp)
    800036ba:	e44e                	sd	s3,8(sp)
    800036bc:	1800                	addi	s0,sp,48
    800036be:	892a                	mv	s2,a0
    800036c0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800036c2:	00014517          	auipc	a0,0x14
    800036c6:	43e50513          	addi	a0,a0,1086 # 80017b00 <bcache>
    800036ca:	ffffd097          	auipc	ra,0xffffd
    800036ce:	4f8080e7          	jalr	1272(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800036d2:	0001c497          	auipc	s1,0x1c
    800036d6:	6e64b483          	ld	s1,1766(s1) # 8001fdb8 <bcache+0x82b8>
    800036da:	0001c797          	auipc	a5,0x1c
    800036de:	68e78793          	addi	a5,a5,1678 # 8001fd68 <bcache+0x8268>
    800036e2:	02f48f63          	beq	s1,a5,80003720 <bread+0x70>
    800036e6:	873e                	mv	a4,a5
    800036e8:	a021                	j	800036f0 <bread+0x40>
    800036ea:	68a4                	ld	s1,80(s1)
    800036ec:	02e48a63          	beq	s1,a4,80003720 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800036f0:	449c                	lw	a5,8(s1)
    800036f2:	ff279ce3          	bne	a5,s2,800036ea <bread+0x3a>
    800036f6:	44dc                	lw	a5,12(s1)
    800036f8:	ff3799e3          	bne	a5,s3,800036ea <bread+0x3a>
      b->refcnt++;
    800036fc:	40bc                	lw	a5,64(s1)
    800036fe:	2785                	addiw	a5,a5,1
    80003700:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003702:	00014517          	auipc	a0,0x14
    80003706:	3fe50513          	addi	a0,a0,1022 # 80017b00 <bcache>
    8000370a:	ffffd097          	auipc	ra,0xffffd
    8000370e:	56c080e7          	jalr	1388(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003712:	01048513          	addi	a0,s1,16
    80003716:	00001097          	auipc	ra,0x1
    8000371a:	46c080e7          	jalr	1132(ra) # 80004b82 <acquiresleep>
      return b;
    8000371e:	a8b9                	j	8000377c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003720:	0001c497          	auipc	s1,0x1c
    80003724:	6904b483          	ld	s1,1680(s1) # 8001fdb0 <bcache+0x82b0>
    80003728:	0001c797          	auipc	a5,0x1c
    8000372c:	64078793          	addi	a5,a5,1600 # 8001fd68 <bcache+0x8268>
    80003730:	00f48863          	beq	s1,a5,80003740 <bread+0x90>
    80003734:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003736:	40bc                	lw	a5,64(s1)
    80003738:	cf81                	beqz	a5,80003750 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000373a:	64a4                	ld	s1,72(s1)
    8000373c:	fee49de3          	bne	s1,a4,80003736 <bread+0x86>
  panic("bget: no buffers");
    80003740:	00005517          	auipc	a0,0x5
    80003744:	fd050513          	addi	a0,a0,-48 # 80008710 <syscalls+0xe0>
    80003748:	ffffd097          	auipc	ra,0xffffd
    8000374c:	de2080e7          	jalr	-542(ra) # 8000052a <panic>
      b->dev = dev;
    80003750:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003754:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003758:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000375c:	4785                	li	a5,1
    8000375e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003760:	00014517          	auipc	a0,0x14
    80003764:	3a050513          	addi	a0,a0,928 # 80017b00 <bcache>
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	50e080e7          	jalr	1294(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003770:	01048513          	addi	a0,s1,16
    80003774:	00001097          	auipc	ra,0x1
    80003778:	40e080e7          	jalr	1038(ra) # 80004b82 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000377c:	409c                	lw	a5,0(s1)
    8000377e:	cb89                	beqz	a5,80003790 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003780:	8526                	mv	a0,s1
    80003782:	70a2                	ld	ra,40(sp)
    80003784:	7402                	ld	s0,32(sp)
    80003786:	64e2                	ld	s1,24(sp)
    80003788:	6942                	ld	s2,16(sp)
    8000378a:	69a2                	ld	s3,8(sp)
    8000378c:	6145                	addi	sp,sp,48
    8000378e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003790:	4581                	li	a1,0
    80003792:	8526                	mv	a0,s1
    80003794:	00003097          	auipc	ra,0x3
    80003798:	f22080e7          	jalr	-222(ra) # 800066b6 <virtio_disk_rw>
    b->valid = 1;
    8000379c:	4785                	li	a5,1
    8000379e:	c09c                	sw	a5,0(s1)
  return b;
    800037a0:	b7c5                	j	80003780 <bread+0xd0>

00000000800037a2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800037a2:	1101                	addi	sp,sp,-32
    800037a4:	ec06                	sd	ra,24(sp)
    800037a6:	e822                	sd	s0,16(sp)
    800037a8:	e426                	sd	s1,8(sp)
    800037aa:	1000                	addi	s0,sp,32
    800037ac:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037ae:	0541                	addi	a0,a0,16
    800037b0:	00001097          	auipc	ra,0x1
    800037b4:	46c080e7          	jalr	1132(ra) # 80004c1c <holdingsleep>
    800037b8:	cd01                	beqz	a0,800037d0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800037ba:	4585                	li	a1,1
    800037bc:	8526                	mv	a0,s1
    800037be:	00003097          	auipc	ra,0x3
    800037c2:	ef8080e7          	jalr	-264(ra) # 800066b6 <virtio_disk_rw>
}
    800037c6:	60e2                	ld	ra,24(sp)
    800037c8:	6442                	ld	s0,16(sp)
    800037ca:	64a2                	ld	s1,8(sp)
    800037cc:	6105                	addi	sp,sp,32
    800037ce:	8082                	ret
    panic("bwrite");
    800037d0:	00005517          	auipc	a0,0x5
    800037d4:	f5850513          	addi	a0,a0,-168 # 80008728 <syscalls+0xf8>
    800037d8:	ffffd097          	auipc	ra,0xffffd
    800037dc:	d52080e7          	jalr	-686(ra) # 8000052a <panic>

00000000800037e0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800037e0:	1101                	addi	sp,sp,-32
    800037e2:	ec06                	sd	ra,24(sp)
    800037e4:	e822                	sd	s0,16(sp)
    800037e6:	e426                	sd	s1,8(sp)
    800037e8:	e04a                	sd	s2,0(sp)
    800037ea:	1000                	addi	s0,sp,32
    800037ec:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037ee:	01050913          	addi	s2,a0,16
    800037f2:	854a                	mv	a0,s2
    800037f4:	00001097          	auipc	ra,0x1
    800037f8:	428080e7          	jalr	1064(ra) # 80004c1c <holdingsleep>
    800037fc:	c92d                	beqz	a0,8000386e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800037fe:	854a                	mv	a0,s2
    80003800:	00001097          	auipc	ra,0x1
    80003804:	3d8080e7          	jalr	984(ra) # 80004bd8 <releasesleep>

  acquire(&bcache.lock);
    80003808:	00014517          	auipc	a0,0x14
    8000380c:	2f850513          	addi	a0,a0,760 # 80017b00 <bcache>
    80003810:	ffffd097          	auipc	ra,0xffffd
    80003814:	3b2080e7          	jalr	946(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003818:	40bc                	lw	a5,64(s1)
    8000381a:	37fd                	addiw	a5,a5,-1
    8000381c:	0007871b          	sext.w	a4,a5
    80003820:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003822:	eb05                	bnez	a4,80003852 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003824:	68bc                	ld	a5,80(s1)
    80003826:	64b8                	ld	a4,72(s1)
    80003828:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000382a:	64bc                	ld	a5,72(s1)
    8000382c:	68b8                	ld	a4,80(s1)
    8000382e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003830:	0001c797          	auipc	a5,0x1c
    80003834:	2d078793          	addi	a5,a5,720 # 8001fb00 <bcache+0x8000>
    80003838:	2b87b703          	ld	a4,696(a5)
    8000383c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000383e:	0001c717          	auipc	a4,0x1c
    80003842:	52a70713          	addi	a4,a4,1322 # 8001fd68 <bcache+0x8268>
    80003846:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003848:	2b87b703          	ld	a4,696(a5)
    8000384c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000384e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003852:	00014517          	auipc	a0,0x14
    80003856:	2ae50513          	addi	a0,a0,686 # 80017b00 <bcache>
    8000385a:	ffffd097          	auipc	ra,0xffffd
    8000385e:	41c080e7          	jalr	1052(ra) # 80000c76 <release>
}
    80003862:	60e2                	ld	ra,24(sp)
    80003864:	6442                	ld	s0,16(sp)
    80003866:	64a2                	ld	s1,8(sp)
    80003868:	6902                	ld	s2,0(sp)
    8000386a:	6105                	addi	sp,sp,32
    8000386c:	8082                	ret
    panic("brelse");
    8000386e:	00005517          	auipc	a0,0x5
    80003872:	ec250513          	addi	a0,a0,-318 # 80008730 <syscalls+0x100>
    80003876:	ffffd097          	auipc	ra,0xffffd
    8000387a:	cb4080e7          	jalr	-844(ra) # 8000052a <panic>

000000008000387e <bpin>:

void
bpin(struct buf *b) {
    8000387e:	1101                	addi	sp,sp,-32
    80003880:	ec06                	sd	ra,24(sp)
    80003882:	e822                	sd	s0,16(sp)
    80003884:	e426                	sd	s1,8(sp)
    80003886:	1000                	addi	s0,sp,32
    80003888:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000388a:	00014517          	auipc	a0,0x14
    8000388e:	27650513          	addi	a0,a0,630 # 80017b00 <bcache>
    80003892:	ffffd097          	auipc	ra,0xffffd
    80003896:	330080e7          	jalr	816(ra) # 80000bc2 <acquire>
  b->refcnt++;
    8000389a:	40bc                	lw	a5,64(s1)
    8000389c:	2785                	addiw	a5,a5,1
    8000389e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038a0:	00014517          	auipc	a0,0x14
    800038a4:	26050513          	addi	a0,a0,608 # 80017b00 <bcache>
    800038a8:	ffffd097          	auipc	ra,0xffffd
    800038ac:	3ce080e7          	jalr	974(ra) # 80000c76 <release>
}
    800038b0:	60e2                	ld	ra,24(sp)
    800038b2:	6442                	ld	s0,16(sp)
    800038b4:	64a2                	ld	s1,8(sp)
    800038b6:	6105                	addi	sp,sp,32
    800038b8:	8082                	ret

00000000800038ba <bunpin>:

void
bunpin(struct buf *b) {
    800038ba:	1101                	addi	sp,sp,-32
    800038bc:	ec06                	sd	ra,24(sp)
    800038be:	e822                	sd	s0,16(sp)
    800038c0:	e426                	sd	s1,8(sp)
    800038c2:	1000                	addi	s0,sp,32
    800038c4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038c6:	00014517          	auipc	a0,0x14
    800038ca:	23a50513          	addi	a0,a0,570 # 80017b00 <bcache>
    800038ce:	ffffd097          	auipc	ra,0xffffd
    800038d2:	2f4080e7          	jalr	756(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800038d6:	40bc                	lw	a5,64(s1)
    800038d8:	37fd                	addiw	a5,a5,-1
    800038da:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038dc:	00014517          	auipc	a0,0x14
    800038e0:	22450513          	addi	a0,a0,548 # 80017b00 <bcache>
    800038e4:	ffffd097          	auipc	ra,0xffffd
    800038e8:	392080e7          	jalr	914(ra) # 80000c76 <release>
}
    800038ec:	60e2                	ld	ra,24(sp)
    800038ee:	6442                	ld	s0,16(sp)
    800038f0:	64a2                	ld	s1,8(sp)
    800038f2:	6105                	addi	sp,sp,32
    800038f4:	8082                	ret

00000000800038f6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800038f6:	1101                	addi	sp,sp,-32
    800038f8:	ec06                	sd	ra,24(sp)
    800038fa:	e822                	sd	s0,16(sp)
    800038fc:	e426                	sd	s1,8(sp)
    800038fe:	e04a                	sd	s2,0(sp)
    80003900:	1000                	addi	s0,sp,32
    80003902:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003904:	00d5d59b          	srliw	a1,a1,0xd
    80003908:	0001d797          	auipc	a5,0x1d
    8000390c:	8d47a783          	lw	a5,-1836(a5) # 800201dc <sb+0x1c>
    80003910:	9dbd                	addw	a1,a1,a5
    80003912:	00000097          	auipc	ra,0x0
    80003916:	d9e080e7          	jalr	-610(ra) # 800036b0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000391a:	0074f713          	andi	a4,s1,7
    8000391e:	4785                	li	a5,1
    80003920:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003924:	14ce                	slli	s1,s1,0x33
    80003926:	90d9                	srli	s1,s1,0x36
    80003928:	00950733          	add	a4,a0,s1
    8000392c:	05874703          	lbu	a4,88(a4)
    80003930:	00e7f6b3          	and	a3,a5,a4
    80003934:	c69d                	beqz	a3,80003962 <bfree+0x6c>
    80003936:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003938:	94aa                	add	s1,s1,a0
    8000393a:	fff7c793          	not	a5,a5
    8000393e:	8ff9                	and	a5,a5,a4
    80003940:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003944:	00001097          	auipc	ra,0x1
    80003948:	11e080e7          	jalr	286(ra) # 80004a62 <log_write>
  brelse(bp);
    8000394c:	854a                	mv	a0,s2
    8000394e:	00000097          	auipc	ra,0x0
    80003952:	e92080e7          	jalr	-366(ra) # 800037e0 <brelse>
}
    80003956:	60e2                	ld	ra,24(sp)
    80003958:	6442                	ld	s0,16(sp)
    8000395a:	64a2                	ld	s1,8(sp)
    8000395c:	6902                	ld	s2,0(sp)
    8000395e:	6105                	addi	sp,sp,32
    80003960:	8082                	ret
    panic("freeing free block");
    80003962:	00005517          	auipc	a0,0x5
    80003966:	dd650513          	addi	a0,a0,-554 # 80008738 <syscalls+0x108>
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	bc0080e7          	jalr	-1088(ra) # 8000052a <panic>

0000000080003972 <balloc>:
{
    80003972:	711d                	addi	sp,sp,-96
    80003974:	ec86                	sd	ra,88(sp)
    80003976:	e8a2                	sd	s0,80(sp)
    80003978:	e4a6                	sd	s1,72(sp)
    8000397a:	e0ca                	sd	s2,64(sp)
    8000397c:	fc4e                	sd	s3,56(sp)
    8000397e:	f852                	sd	s4,48(sp)
    80003980:	f456                	sd	s5,40(sp)
    80003982:	f05a                	sd	s6,32(sp)
    80003984:	ec5e                	sd	s7,24(sp)
    80003986:	e862                	sd	s8,16(sp)
    80003988:	e466                	sd	s9,8(sp)
    8000398a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000398c:	0001d797          	auipc	a5,0x1d
    80003990:	8387a783          	lw	a5,-1992(a5) # 800201c4 <sb+0x4>
    80003994:	cbd1                	beqz	a5,80003a28 <balloc+0xb6>
    80003996:	8baa                	mv	s7,a0
    80003998:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000399a:	0001db17          	auipc	s6,0x1d
    8000399e:	826b0b13          	addi	s6,s6,-2010 # 800201c0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039a2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800039a4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039a6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800039a8:	6c89                	lui	s9,0x2
    800039aa:	a831                	j	800039c6 <balloc+0x54>
    brelse(bp);
    800039ac:	854a                	mv	a0,s2
    800039ae:	00000097          	auipc	ra,0x0
    800039b2:	e32080e7          	jalr	-462(ra) # 800037e0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800039b6:	015c87bb          	addw	a5,s9,s5
    800039ba:	00078a9b          	sext.w	s5,a5
    800039be:	004b2703          	lw	a4,4(s6)
    800039c2:	06eaf363          	bgeu	s5,a4,80003a28 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800039c6:	41fad79b          	sraiw	a5,s5,0x1f
    800039ca:	0137d79b          	srliw	a5,a5,0x13
    800039ce:	015787bb          	addw	a5,a5,s5
    800039d2:	40d7d79b          	sraiw	a5,a5,0xd
    800039d6:	01cb2583          	lw	a1,28(s6)
    800039da:	9dbd                	addw	a1,a1,a5
    800039dc:	855e                	mv	a0,s7
    800039de:	00000097          	auipc	ra,0x0
    800039e2:	cd2080e7          	jalr	-814(ra) # 800036b0 <bread>
    800039e6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039e8:	004b2503          	lw	a0,4(s6)
    800039ec:	000a849b          	sext.w	s1,s5
    800039f0:	8662                	mv	a2,s8
    800039f2:	faa4fde3          	bgeu	s1,a0,800039ac <balloc+0x3a>
      m = 1 << (bi % 8);
    800039f6:	41f6579b          	sraiw	a5,a2,0x1f
    800039fa:	01d7d69b          	srliw	a3,a5,0x1d
    800039fe:	00c6873b          	addw	a4,a3,a2
    80003a02:	00777793          	andi	a5,a4,7
    80003a06:	9f95                	subw	a5,a5,a3
    80003a08:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a0c:	4037571b          	sraiw	a4,a4,0x3
    80003a10:	00e906b3          	add	a3,s2,a4
    80003a14:	0586c683          	lbu	a3,88(a3)
    80003a18:	00d7f5b3          	and	a1,a5,a3
    80003a1c:	cd91                	beqz	a1,80003a38 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a1e:	2605                	addiw	a2,a2,1
    80003a20:	2485                	addiw	s1,s1,1
    80003a22:	fd4618e3          	bne	a2,s4,800039f2 <balloc+0x80>
    80003a26:	b759                	j	800039ac <balloc+0x3a>
  panic("balloc: out of blocks");
    80003a28:	00005517          	auipc	a0,0x5
    80003a2c:	d2850513          	addi	a0,a0,-728 # 80008750 <syscalls+0x120>
    80003a30:	ffffd097          	auipc	ra,0xffffd
    80003a34:	afa080e7          	jalr	-1286(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003a38:	974a                	add	a4,a4,s2
    80003a3a:	8fd5                	or	a5,a5,a3
    80003a3c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003a40:	854a                	mv	a0,s2
    80003a42:	00001097          	auipc	ra,0x1
    80003a46:	020080e7          	jalr	32(ra) # 80004a62 <log_write>
        brelse(bp);
    80003a4a:	854a                	mv	a0,s2
    80003a4c:	00000097          	auipc	ra,0x0
    80003a50:	d94080e7          	jalr	-620(ra) # 800037e0 <brelse>
  bp = bread(dev, bno);
    80003a54:	85a6                	mv	a1,s1
    80003a56:	855e                	mv	a0,s7
    80003a58:	00000097          	auipc	ra,0x0
    80003a5c:	c58080e7          	jalr	-936(ra) # 800036b0 <bread>
    80003a60:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003a62:	40000613          	li	a2,1024
    80003a66:	4581                	li	a1,0
    80003a68:	05850513          	addi	a0,a0,88
    80003a6c:	ffffd097          	auipc	ra,0xffffd
    80003a70:	252080e7          	jalr	594(ra) # 80000cbe <memset>
  log_write(bp);
    80003a74:	854a                	mv	a0,s2
    80003a76:	00001097          	auipc	ra,0x1
    80003a7a:	fec080e7          	jalr	-20(ra) # 80004a62 <log_write>
  brelse(bp);
    80003a7e:	854a                	mv	a0,s2
    80003a80:	00000097          	auipc	ra,0x0
    80003a84:	d60080e7          	jalr	-672(ra) # 800037e0 <brelse>
}
    80003a88:	8526                	mv	a0,s1
    80003a8a:	60e6                	ld	ra,88(sp)
    80003a8c:	6446                	ld	s0,80(sp)
    80003a8e:	64a6                	ld	s1,72(sp)
    80003a90:	6906                	ld	s2,64(sp)
    80003a92:	79e2                	ld	s3,56(sp)
    80003a94:	7a42                	ld	s4,48(sp)
    80003a96:	7aa2                	ld	s5,40(sp)
    80003a98:	7b02                	ld	s6,32(sp)
    80003a9a:	6be2                	ld	s7,24(sp)
    80003a9c:	6c42                	ld	s8,16(sp)
    80003a9e:	6ca2                	ld	s9,8(sp)
    80003aa0:	6125                	addi	sp,sp,96
    80003aa2:	8082                	ret

0000000080003aa4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003aa4:	7179                	addi	sp,sp,-48
    80003aa6:	f406                	sd	ra,40(sp)
    80003aa8:	f022                	sd	s0,32(sp)
    80003aaa:	ec26                	sd	s1,24(sp)
    80003aac:	e84a                	sd	s2,16(sp)
    80003aae:	e44e                	sd	s3,8(sp)
    80003ab0:	e052                	sd	s4,0(sp)
    80003ab2:	1800                	addi	s0,sp,48
    80003ab4:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ab6:	47ad                	li	a5,11
    80003ab8:	04b7fe63          	bgeu	a5,a1,80003b14 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003abc:	ff45849b          	addiw	s1,a1,-12
    80003ac0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003ac4:	0ff00793          	li	a5,255
    80003ac8:	0ae7e463          	bltu	a5,a4,80003b70 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003acc:	08052583          	lw	a1,128(a0)
    80003ad0:	c5b5                	beqz	a1,80003b3c <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003ad2:	00092503          	lw	a0,0(s2)
    80003ad6:	00000097          	auipc	ra,0x0
    80003ada:	bda080e7          	jalr	-1062(ra) # 800036b0 <bread>
    80003ade:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003ae0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003ae4:	02049713          	slli	a4,s1,0x20
    80003ae8:	01e75593          	srli	a1,a4,0x1e
    80003aec:	00b784b3          	add	s1,a5,a1
    80003af0:	0004a983          	lw	s3,0(s1)
    80003af4:	04098e63          	beqz	s3,80003b50 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003af8:	8552                	mv	a0,s4
    80003afa:	00000097          	auipc	ra,0x0
    80003afe:	ce6080e7          	jalr	-794(ra) # 800037e0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b02:	854e                	mv	a0,s3
    80003b04:	70a2                	ld	ra,40(sp)
    80003b06:	7402                	ld	s0,32(sp)
    80003b08:	64e2                	ld	s1,24(sp)
    80003b0a:	6942                	ld	s2,16(sp)
    80003b0c:	69a2                	ld	s3,8(sp)
    80003b0e:	6a02                	ld	s4,0(sp)
    80003b10:	6145                	addi	sp,sp,48
    80003b12:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003b14:	02059793          	slli	a5,a1,0x20
    80003b18:	01e7d593          	srli	a1,a5,0x1e
    80003b1c:	00b504b3          	add	s1,a0,a1
    80003b20:	0504a983          	lw	s3,80(s1)
    80003b24:	fc099fe3          	bnez	s3,80003b02 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003b28:	4108                	lw	a0,0(a0)
    80003b2a:	00000097          	auipc	ra,0x0
    80003b2e:	e48080e7          	jalr	-440(ra) # 80003972 <balloc>
    80003b32:	0005099b          	sext.w	s3,a0
    80003b36:	0534a823          	sw	s3,80(s1)
    80003b3a:	b7e1                	j	80003b02 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003b3c:	4108                	lw	a0,0(a0)
    80003b3e:	00000097          	auipc	ra,0x0
    80003b42:	e34080e7          	jalr	-460(ra) # 80003972 <balloc>
    80003b46:	0005059b          	sext.w	a1,a0
    80003b4a:	08b92023          	sw	a1,128(s2)
    80003b4e:	b751                	j	80003ad2 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003b50:	00092503          	lw	a0,0(s2)
    80003b54:	00000097          	auipc	ra,0x0
    80003b58:	e1e080e7          	jalr	-482(ra) # 80003972 <balloc>
    80003b5c:	0005099b          	sext.w	s3,a0
    80003b60:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003b64:	8552                	mv	a0,s4
    80003b66:	00001097          	auipc	ra,0x1
    80003b6a:	efc080e7          	jalr	-260(ra) # 80004a62 <log_write>
    80003b6e:	b769                	j	80003af8 <bmap+0x54>
  panic("bmap: out of range");
    80003b70:	00005517          	auipc	a0,0x5
    80003b74:	bf850513          	addi	a0,a0,-1032 # 80008768 <syscalls+0x138>
    80003b78:	ffffd097          	auipc	ra,0xffffd
    80003b7c:	9b2080e7          	jalr	-1614(ra) # 8000052a <panic>

0000000080003b80 <iget>:
{
    80003b80:	7179                	addi	sp,sp,-48
    80003b82:	f406                	sd	ra,40(sp)
    80003b84:	f022                	sd	s0,32(sp)
    80003b86:	ec26                	sd	s1,24(sp)
    80003b88:	e84a                	sd	s2,16(sp)
    80003b8a:	e44e                	sd	s3,8(sp)
    80003b8c:	e052                	sd	s4,0(sp)
    80003b8e:	1800                	addi	s0,sp,48
    80003b90:	89aa                	mv	s3,a0
    80003b92:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003b94:	0001c517          	auipc	a0,0x1c
    80003b98:	64c50513          	addi	a0,a0,1612 # 800201e0 <itable>
    80003b9c:	ffffd097          	auipc	ra,0xffffd
    80003ba0:	026080e7          	jalr	38(ra) # 80000bc2 <acquire>
  empty = 0;
    80003ba4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ba6:	0001c497          	auipc	s1,0x1c
    80003baa:	65248493          	addi	s1,s1,1618 # 800201f8 <itable+0x18>
    80003bae:	0001e697          	auipc	a3,0x1e
    80003bb2:	0da68693          	addi	a3,a3,218 # 80021c88 <log>
    80003bb6:	a039                	j	80003bc4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bb8:	02090b63          	beqz	s2,80003bee <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bbc:	08848493          	addi	s1,s1,136
    80003bc0:	02d48a63          	beq	s1,a3,80003bf4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003bc4:	449c                	lw	a5,8(s1)
    80003bc6:	fef059e3          	blez	a5,80003bb8 <iget+0x38>
    80003bca:	4098                	lw	a4,0(s1)
    80003bcc:	ff3716e3          	bne	a4,s3,80003bb8 <iget+0x38>
    80003bd0:	40d8                	lw	a4,4(s1)
    80003bd2:	ff4713e3          	bne	a4,s4,80003bb8 <iget+0x38>
      ip->ref++;
    80003bd6:	2785                	addiw	a5,a5,1
    80003bd8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003bda:	0001c517          	auipc	a0,0x1c
    80003bde:	60650513          	addi	a0,a0,1542 # 800201e0 <itable>
    80003be2:	ffffd097          	auipc	ra,0xffffd
    80003be6:	094080e7          	jalr	148(ra) # 80000c76 <release>
      return ip;
    80003bea:	8926                	mv	s2,s1
    80003bec:	a03d                	j	80003c1a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bee:	f7f9                	bnez	a5,80003bbc <iget+0x3c>
    80003bf0:	8926                	mv	s2,s1
    80003bf2:	b7e9                	j	80003bbc <iget+0x3c>
  if(empty == 0)
    80003bf4:	02090c63          	beqz	s2,80003c2c <iget+0xac>
  ip->dev = dev;
    80003bf8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003bfc:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c00:	4785                	li	a5,1
    80003c02:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c06:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c0a:	0001c517          	auipc	a0,0x1c
    80003c0e:	5d650513          	addi	a0,a0,1494 # 800201e0 <itable>
    80003c12:	ffffd097          	auipc	ra,0xffffd
    80003c16:	064080e7          	jalr	100(ra) # 80000c76 <release>
}
    80003c1a:	854a                	mv	a0,s2
    80003c1c:	70a2                	ld	ra,40(sp)
    80003c1e:	7402                	ld	s0,32(sp)
    80003c20:	64e2                	ld	s1,24(sp)
    80003c22:	6942                	ld	s2,16(sp)
    80003c24:	69a2                	ld	s3,8(sp)
    80003c26:	6a02                	ld	s4,0(sp)
    80003c28:	6145                	addi	sp,sp,48
    80003c2a:	8082                	ret
    panic("iget: no inodes");
    80003c2c:	00005517          	auipc	a0,0x5
    80003c30:	b5450513          	addi	a0,a0,-1196 # 80008780 <syscalls+0x150>
    80003c34:	ffffd097          	auipc	ra,0xffffd
    80003c38:	8f6080e7          	jalr	-1802(ra) # 8000052a <panic>

0000000080003c3c <fsinit>:
fsinit(int dev) {
    80003c3c:	7179                	addi	sp,sp,-48
    80003c3e:	f406                	sd	ra,40(sp)
    80003c40:	f022                	sd	s0,32(sp)
    80003c42:	ec26                	sd	s1,24(sp)
    80003c44:	e84a                	sd	s2,16(sp)
    80003c46:	e44e                	sd	s3,8(sp)
    80003c48:	1800                	addi	s0,sp,48
    80003c4a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c4c:	4585                	li	a1,1
    80003c4e:	00000097          	auipc	ra,0x0
    80003c52:	a62080e7          	jalr	-1438(ra) # 800036b0 <bread>
    80003c56:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c58:	0001c997          	auipc	s3,0x1c
    80003c5c:	56898993          	addi	s3,s3,1384 # 800201c0 <sb>
    80003c60:	02000613          	li	a2,32
    80003c64:	05850593          	addi	a1,a0,88
    80003c68:	854e                	mv	a0,s3
    80003c6a:	ffffd097          	auipc	ra,0xffffd
    80003c6e:	0b0080e7          	jalr	176(ra) # 80000d1a <memmove>
  brelse(bp);
    80003c72:	8526                	mv	a0,s1
    80003c74:	00000097          	auipc	ra,0x0
    80003c78:	b6c080e7          	jalr	-1172(ra) # 800037e0 <brelse>
  if(sb.magic != FSMAGIC)
    80003c7c:	0009a703          	lw	a4,0(s3)
    80003c80:	102037b7          	lui	a5,0x10203
    80003c84:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c88:	02f71263          	bne	a4,a5,80003cac <fsinit+0x70>
  initlog(dev, &sb);
    80003c8c:	0001c597          	auipc	a1,0x1c
    80003c90:	53458593          	addi	a1,a1,1332 # 800201c0 <sb>
    80003c94:	854a                	mv	a0,s2
    80003c96:	00001097          	auipc	ra,0x1
    80003c9a:	b4e080e7          	jalr	-1202(ra) # 800047e4 <initlog>
}
    80003c9e:	70a2                	ld	ra,40(sp)
    80003ca0:	7402                	ld	s0,32(sp)
    80003ca2:	64e2                	ld	s1,24(sp)
    80003ca4:	6942                	ld	s2,16(sp)
    80003ca6:	69a2                	ld	s3,8(sp)
    80003ca8:	6145                	addi	sp,sp,48
    80003caa:	8082                	ret
    panic("invalid file system");
    80003cac:	00005517          	auipc	a0,0x5
    80003cb0:	ae450513          	addi	a0,a0,-1308 # 80008790 <syscalls+0x160>
    80003cb4:	ffffd097          	auipc	ra,0xffffd
    80003cb8:	876080e7          	jalr	-1930(ra) # 8000052a <panic>

0000000080003cbc <iinit>:
{
    80003cbc:	7179                	addi	sp,sp,-48
    80003cbe:	f406                	sd	ra,40(sp)
    80003cc0:	f022                	sd	s0,32(sp)
    80003cc2:	ec26                	sd	s1,24(sp)
    80003cc4:	e84a                	sd	s2,16(sp)
    80003cc6:	e44e                	sd	s3,8(sp)
    80003cc8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003cca:	00005597          	auipc	a1,0x5
    80003cce:	ade58593          	addi	a1,a1,-1314 # 800087a8 <syscalls+0x178>
    80003cd2:	0001c517          	auipc	a0,0x1c
    80003cd6:	50e50513          	addi	a0,a0,1294 # 800201e0 <itable>
    80003cda:	ffffd097          	auipc	ra,0xffffd
    80003cde:	e58080e7          	jalr	-424(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003ce2:	0001c497          	auipc	s1,0x1c
    80003ce6:	52648493          	addi	s1,s1,1318 # 80020208 <itable+0x28>
    80003cea:	0001e997          	auipc	s3,0x1e
    80003cee:	fae98993          	addi	s3,s3,-82 # 80021c98 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003cf2:	00005917          	auipc	s2,0x5
    80003cf6:	abe90913          	addi	s2,s2,-1346 # 800087b0 <syscalls+0x180>
    80003cfa:	85ca                	mv	a1,s2
    80003cfc:	8526                	mv	a0,s1
    80003cfe:	00001097          	auipc	ra,0x1
    80003d02:	e4a080e7          	jalr	-438(ra) # 80004b48 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d06:	08848493          	addi	s1,s1,136
    80003d0a:	ff3498e3          	bne	s1,s3,80003cfa <iinit+0x3e>
}
    80003d0e:	70a2                	ld	ra,40(sp)
    80003d10:	7402                	ld	s0,32(sp)
    80003d12:	64e2                	ld	s1,24(sp)
    80003d14:	6942                	ld	s2,16(sp)
    80003d16:	69a2                	ld	s3,8(sp)
    80003d18:	6145                	addi	sp,sp,48
    80003d1a:	8082                	ret

0000000080003d1c <ialloc>:
{
    80003d1c:	715d                	addi	sp,sp,-80
    80003d1e:	e486                	sd	ra,72(sp)
    80003d20:	e0a2                	sd	s0,64(sp)
    80003d22:	fc26                	sd	s1,56(sp)
    80003d24:	f84a                	sd	s2,48(sp)
    80003d26:	f44e                	sd	s3,40(sp)
    80003d28:	f052                	sd	s4,32(sp)
    80003d2a:	ec56                	sd	s5,24(sp)
    80003d2c:	e85a                	sd	s6,16(sp)
    80003d2e:	e45e                	sd	s7,8(sp)
    80003d30:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d32:	0001c717          	auipc	a4,0x1c
    80003d36:	49a72703          	lw	a4,1178(a4) # 800201cc <sb+0xc>
    80003d3a:	4785                	li	a5,1
    80003d3c:	04e7fa63          	bgeu	a5,a4,80003d90 <ialloc+0x74>
    80003d40:	8aaa                	mv	s5,a0
    80003d42:	8bae                	mv	s7,a1
    80003d44:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d46:	0001ca17          	auipc	s4,0x1c
    80003d4a:	47aa0a13          	addi	s4,s4,1146 # 800201c0 <sb>
    80003d4e:	00048b1b          	sext.w	s6,s1
    80003d52:	0044d793          	srli	a5,s1,0x4
    80003d56:	018a2583          	lw	a1,24(s4)
    80003d5a:	9dbd                	addw	a1,a1,a5
    80003d5c:	8556                	mv	a0,s5
    80003d5e:	00000097          	auipc	ra,0x0
    80003d62:	952080e7          	jalr	-1710(ra) # 800036b0 <bread>
    80003d66:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d68:	05850993          	addi	s3,a0,88
    80003d6c:	00f4f793          	andi	a5,s1,15
    80003d70:	079a                	slli	a5,a5,0x6
    80003d72:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d74:	00099783          	lh	a5,0(s3)
    80003d78:	c785                	beqz	a5,80003da0 <ialloc+0x84>
    brelse(bp);
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	a66080e7          	jalr	-1434(ra) # 800037e0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d82:	0485                	addi	s1,s1,1
    80003d84:	00ca2703          	lw	a4,12(s4)
    80003d88:	0004879b          	sext.w	a5,s1
    80003d8c:	fce7e1e3          	bltu	a5,a4,80003d4e <ialloc+0x32>
  panic("ialloc: no inodes");
    80003d90:	00005517          	auipc	a0,0x5
    80003d94:	a2850513          	addi	a0,a0,-1496 # 800087b8 <syscalls+0x188>
    80003d98:	ffffc097          	auipc	ra,0xffffc
    80003d9c:	792080e7          	jalr	1938(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003da0:	04000613          	li	a2,64
    80003da4:	4581                	li	a1,0
    80003da6:	854e                	mv	a0,s3
    80003da8:	ffffd097          	auipc	ra,0xffffd
    80003dac:	f16080e7          	jalr	-234(ra) # 80000cbe <memset>
      dip->type = type;
    80003db0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003db4:	854a                	mv	a0,s2
    80003db6:	00001097          	auipc	ra,0x1
    80003dba:	cac080e7          	jalr	-852(ra) # 80004a62 <log_write>
      brelse(bp);
    80003dbe:	854a                	mv	a0,s2
    80003dc0:	00000097          	auipc	ra,0x0
    80003dc4:	a20080e7          	jalr	-1504(ra) # 800037e0 <brelse>
      return iget(dev, inum);
    80003dc8:	85da                	mv	a1,s6
    80003dca:	8556                	mv	a0,s5
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	db4080e7          	jalr	-588(ra) # 80003b80 <iget>
}
    80003dd4:	60a6                	ld	ra,72(sp)
    80003dd6:	6406                	ld	s0,64(sp)
    80003dd8:	74e2                	ld	s1,56(sp)
    80003dda:	7942                	ld	s2,48(sp)
    80003ddc:	79a2                	ld	s3,40(sp)
    80003dde:	7a02                	ld	s4,32(sp)
    80003de0:	6ae2                	ld	s5,24(sp)
    80003de2:	6b42                	ld	s6,16(sp)
    80003de4:	6ba2                	ld	s7,8(sp)
    80003de6:	6161                	addi	sp,sp,80
    80003de8:	8082                	ret

0000000080003dea <iupdate>:
{
    80003dea:	1101                	addi	sp,sp,-32
    80003dec:	ec06                	sd	ra,24(sp)
    80003dee:	e822                	sd	s0,16(sp)
    80003df0:	e426                	sd	s1,8(sp)
    80003df2:	e04a                	sd	s2,0(sp)
    80003df4:	1000                	addi	s0,sp,32
    80003df6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003df8:	415c                	lw	a5,4(a0)
    80003dfa:	0047d79b          	srliw	a5,a5,0x4
    80003dfe:	0001c597          	auipc	a1,0x1c
    80003e02:	3da5a583          	lw	a1,986(a1) # 800201d8 <sb+0x18>
    80003e06:	9dbd                	addw	a1,a1,a5
    80003e08:	4108                	lw	a0,0(a0)
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	8a6080e7          	jalr	-1882(ra) # 800036b0 <bread>
    80003e12:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e14:	05850793          	addi	a5,a0,88
    80003e18:	40c8                	lw	a0,4(s1)
    80003e1a:	893d                	andi	a0,a0,15
    80003e1c:	051a                	slli	a0,a0,0x6
    80003e1e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003e20:	04449703          	lh	a4,68(s1)
    80003e24:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003e28:	04649703          	lh	a4,70(s1)
    80003e2c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003e30:	04849703          	lh	a4,72(s1)
    80003e34:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003e38:	04a49703          	lh	a4,74(s1)
    80003e3c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003e40:	44f8                	lw	a4,76(s1)
    80003e42:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e44:	03400613          	li	a2,52
    80003e48:	05048593          	addi	a1,s1,80
    80003e4c:	0531                	addi	a0,a0,12
    80003e4e:	ffffd097          	auipc	ra,0xffffd
    80003e52:	ecc080e7          	jalr	-308(ra) # 80000d1a <memmove>
  log_write(bp);
    80003e56:	854a                	mv	a0,s2
    80003e58:	00001097          	auipc	ra,0x1
    80003e5c:	c0a080e7          	jalr	-1014(ra) # 80004a62 <log_write>
  brelse(bp);
    80003e60:	854a                	mv	a0,s2
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	97e080e7          	jalr	-1666(ra) # 800037e0 <brelse>
}
    80003e6a:	60e2                	ld	ra,24(sp)
    80003e6c:	6442                	ld	s0,16(sp)
    80003e6e:	64a2                	ld	s1,8(sp)
    80003e70:	6902                	ld	s2,0(sp)
    80003e72:	6105                	addi	sp,sp,32
    80003e74:	8082                	ret

0000000080003e76 <idup>:
{
    80003e76:	1101                	addi	sp,sp,-32
    80003e78:	ec06                	sd	ra,24(sp)
    80003e7a:	e822                	sd	s0,16(sp)
    80003e7c:	e426                	sd	s1,8(sp)
    80003e7e:	1000                	addi	s0,sp,32
    80003e80:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e82:	0001c517          	auipc	a0,0x1c
    80003e86:	35e50513          	addi	a0,a0,862 # 800201e0 <itable>
    80003e8a:	ffffd097          	auipc	ra,0xffffd
    80003e8e:	d38080e7          	jalr	-712(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003e92:	449c                	lw	a5,8(s1)
    80003e94:	2785                	addiw	a5,a5,1
    80003e96:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e98:	0001c517          	auipc	a0,0x1c
    80003e9c:	34850513          	addi	a0,a0,840 # 800201e0 <itable>
    80003ea0:	ffffd097          	auipc	ra,0xffffd
    80003ea4:	dd6080e7          	jalr	-554(ra) # 80000c76 <release>
}
    80003ea8:	8526                	mv	a0,s1
    80003eaa:	60e2                	ld	ra,24(sp)
    80003eac:	6442                	ld	s0,16(sp)
    80003eae:	64a2                	ld	s1,8(sp)
    80003eb0:	6105                	addi	sp,sp,32
    80003eb2:	8082                	ret

0000000080003eb4 <ilock>:
{
    80003eb4:	1101                	addi	sp,sp,-32
    80003eb6:	ec06                	sd	ra,24(sp)
    80003eb8:	e822                	sd	s0,16(sp)
    80003eba:	e426                	sd	s1,8(sp)
    80003ebc:	e04a                	sd	s2,0(sp)
    80003ebe:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ec0:	c115                	beqz	a0,80003ee4 <ilock+0x30>
    80003ec2:	84aa                	mv	s1,a0
    80003ec4:	451c                	lw	a5,8(a0)
    80003ec6:	00f05f63          	blez	a5,80003ee4 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003eca:	0541                	addi	a0,a0,16
    80003ecc:	00001097          	auipc	ra,0x1
    80003ed0:	cb6080e7          	jalr	-842(ra) # 80004b82 <acquiresleep>
  if(ip->valid == 0){
    80003ed4:	40bc                	lw	a5,64(s1)
    80003ed6:	cf99                	beqz	a5,80003ef4 <ilock+0x40>
}
    80003ed8:	60e2                	ld	ra,24(sp)
    80003eda:	6442                	ld	s0,16(sp)
    80003edc:	64a2                	ld	s1,8(sp)
    80003ede:	6902                	ld	s2,0(sp)
    80003ee0:	6105                	addi	sp,sp,32
    80003ee2:	8082                	ret
    panic("ilock");
    80003ee4:	00005517          	auipc	a0,0x5
    80003ee8:	8ec50513          	addi	a0,a0,-1812 # 800087d0 <syscalls+0x1a0>
    80003eec:	ffffc097          	auipc	ra,0xffffc
    80003ef0:	63e080e7          	jalr	1598(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ef4:	40dc                	lw	a5,4(s1)
    80003ef6:	0047d79b          	srliw	a5,a5,0x4
    80003efa:	0001c597          	auipc	a1,0x1c
    80003efe:	2de5a583          	lw	a1,734(a1) # 800201d8 <sb+0x18>
    80003f02:	9dbd                	addw	a1,a1,a5
    80003f04:	4088                	lw	a0,0(s1)
    80003f06:	fffff097          	auipc	ra,0xfffff
    80003f0a:	7aa080e7          	jalr	1962(ra) # 800036b0 <bread>
    80003f0e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f10:	05850593          	addi	a1,a0,88
    80003f14:	40dc                	lw	a5,4(s1)
    80003f16:	8bbd                	andi	a5,a5,15
    80003f18:	079a                	slli	a5,a5,0x6
    80003f1a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f1c:	00059783          	lh	a5,0(a1)
    80003f20:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f24:	00259783          	lh	a5,2(a1)
    80003f28:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f2c:	00459783          	lh	a5,4(a1)
    80003f30:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f34:	00659783          	lh	a5,6(a1)
    80003f38:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f3c:	459c                	lw	a5,8(a1)
    80003f3e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f40:	03400613          	li	a2,52
    80003f44:	05b1                	addi	a1,a1,12
    80003f46:	05048513          	addi	a0,s1,80
    80003f4a:	ffffd097          	auipc	ra,0xffffd
    80003f4e:	dd0080e7          	jalr	-560(ra) # 80000d1a <memmove>
    brelse(bp);
    80003f52:	854a                	mv	a0,s2
    80003f54:	00000097          	auipc	ra,0x0
    80003f58:	88c080e7          	jalr	-1908(ra) # 800037e0 <brelse>
    ip->valid = 1;
    80003f5c:	4785                	li	a5,1
    80003f5e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f60:	04449783          	lh	a5,68(s1)
    80003f64:	fbb5                	bnez	a5,80003ed8 <ilock+0x24>
      panic("ilock: no type");
    80003f66:	00005517          	auipc	a0,0x5
    80003f6a:	87250513          	addi	a0,a0,-1934 # 800087d8 <syscalls+0x1a8>
    80003f6e:	ffffc097          	auipc	ra,0xffffc
    80003f72:	5bc080e7          	jalr	1468(ra) # 8000052a <panic>

0000000080003f76 <iunlock>:
{
    80003f76:	1101                	addi	sp,sp,-32
    80003f78:	ec06                	sd	ra,24(sp)
    80003f7a:	e822                	sd	s0,16(sp)
    80003f7c:	e426                	sd	s1,8(sp)
    80003f7e:	e04a                	sd	s2,0(sp)
    80003f80:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f82:	c905                	beqz	a0,80003fb2 <iunlock+0x3c>
    80003f84:	84aa                	mv	s1,a0
    80003f86:	01050913          	addi	s2,a0,16
    80003f8a:	854a                	mv	a0,s2
    80003f8c:	00001097          	auipc	ra,0x1
    80003f90:	c90080e7          	jalr	-880(ra) # 80004c1c <holdingsleep>
    80003f94:	cd19                	beqz	a0,80003fb2 <iunlock+0x3c>
    80003f96:	449c                	lw	a5,8(s1)
    80003f98:	00f05d63          	blez	a5,80003fb2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f9c:	854a                	mv	a0,s2
    80003f9e:	00001097          	auipc	ra,0x1
    80003fa2:	c3a080e7          	jalr	-966(ra) # 80004bd8 <releasesleep>
}
    80003fa6:	60e2                	ld	ra,24(sp)
    80003fa8:	6442                	ld	s0,16(sp)
    80003faa:	64a2                	ld	s1,8(sp)
    80003fac:	6902                	ld	s2,0(sp)
    80003fae:	6105                	addi	sp,sp,32
    80003fb0:	8082                	ret
    panic("iunlock");
    80003fb2:	00005517          	auipc	a0,0x5
    80003fb6:	83650513          	addi	a0,a0,-1994 # 800087e8 <syscalls+0x1b8>
    80003fba:	ffffc097          	auipc	ra,0xffffc
    80003fbe:	570080e7          	jalr	1392(ra) # 8000052a <panic>

0000000080003fc2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003fc2:	7179                	addi	sp,sp,-48
    80003fc4:	f406                	sd	ra,40(sp)
    80003fc6:	f022                	sd	s0,32(sp)
    80003fc8:	ec26                	sd	s1,24(sp)
    80003fca:	e84a                	sd	s2,16(sp)
    80003fcc:	e44e                	sd	s3,8(sp)
    80003fce:	e052                	sd	s4,0(sp)
    80003fd0:	1800                	addi	s0,sp,48
    80003fd2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003fd4:	05050493          	addi	s1,a0,80
    80003fd8:	08050913          	addi	s2,a0,128
    80003fdc:	a021                	j	80003fe4 <itrunc+0x22>
    80003fde:	0491                	addi	s1,s1,4
    80003fe0:	01248d63          	beq	s1,s2,80003ffa <itrunc+0x38>
    if(ip->addrs[i]){
    80003fe4:	408c                	lw	a1,0(s1)
    80003fe6:	dde5                	beqz	a1,80003fde <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003fe8:	0009a503          	lw	a0,0(s3)
    80003fec:	00000097          	auipc	ra,0x0
    80003ff0:	90a080e7          	jalr	-1782(ra) # 800038f6 <bfree>
      ip->addrs[i] = 0;
    80003ff4:	0004a023          	sw	zero,0(s1)
    80003ff8:	b7dd                	j	80003fde <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ffa:	0809a583          	lw	a1,128(s3)
    80003ffe:	e185                	bnez	a1,8000401e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004000:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004004:	854e                	mv	a0,s3
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	de4080e7          	jalr	-540(ra) # 80003dea <iupdate>
}
    8000400e:	70a2                	ld	ra,40(sp)
    80004010:	7402                	ld	s0,32(sp)
    80004012:	64e2                	ld	s1,24(sp)
    80004014:	6942                	ld	s2,16(sp)
    80004016:	69a2                	ld	s3,8(sp)
    80004018:	6a02                	ld	s4,0(sp)
    8000401a:	6145                	addi	sp,sp,48
    8000401c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000401e:	0009a503          	lw	a0,0(s3)
    80004022:	fffff097          	auipc	ra,0xfffff
    80004026:	68e080e7          	jalr	1678(ra) # 800036b0 <bread>
    8000402a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000402c:	05850493          	addi	s1,a0,88
    80004030:	45850913          	addi	s2,a0,1112
    80004034:	a021                	j	8000403c <itrunc+0x7a>
    80004036:	0491                	addi	s1,s1,4
    80004038:	01248b63          	beq	s1,s2,8000404e <itrunc+0x8c>
      if(a[j])
    8000403c:	408c                	lw	a1,0(s1)
    8000403e:	dde5                	beqz	a1,80004036 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004040:	0009a503          	lw	a0,0(s3)
    80004044:	00000097          	auipc	ra,0x0
    80004048:	8b2080e7          	jalr	-1870(ra) # 800038f6 <bfree>
    8000404c:	b7ed                	j	80004036 <itrunc+0x74>
    brelse(bp);
    8000404e:	8552                	mv	a0,s4
    80004050:	fffff097          	auipc	ra,0xfffff
    80004054:	790080e7          	jalr	1936(ra) # 800037e0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004058:	0809a583          	lw	a1,128(s3)
    8000405c:	0009a503          	lw	a0,0(s3)
    80004060:	00000097          	auipc	ra,0x0
    80004064:	896080e7          	jalr	-1898(ra) # 800038f6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004068:	0809a023          	sw	zero,128(s3)
    8000406c:	bf51                	j	80004000 <itrunc+0x3e>

000000008000406e <iput>:
{
    8000406e:	1101                	addi	sp,sp,-32
    80004070:	ec06                	sd	ra,24(sp)
    80004072:	e822                	sd	s0,16(sp)
    80004074:	e426                	sd	s1,8(sp)
    80004076:	e04a                	sd	s2,0(sp)
    80004078:	1000                	addi	s0,sp,32
    8000407a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000407c:	0001c517          	auipc	a0,0x1c
    80004080:	16450513          	addi	a0,a0,356 # 800201e0 <itable>
    80004084:	ffffd097          	auipc	ra,0xffffd
    80004088:	b3e080e7          	jalr	-1218(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000408c:	4498                	lw	a4,8(s1)
    8000408e:	4785                	li	a5,1
    80004090:	02f70363          	beq	a4,a5,800040b6 <iput+0x48>
  ip->ref--;
    80004094:	449c                	lw	a5,8(s1)
    80004096:	37fd                	addiw	a5,a5,-1
    80004098:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000409a:	0001c517          	auipc	a0,0x1c
    8000409e:	14650513          	addi	a0,a0,326 # 800201e0 <itable>
    800040a2:	ffffd097          	auipc	ra,0xffffd
    800040a6:	bd4080e7          	jalr	-1068(ra) # 80000c76 <release>
}
    800040aa:	60e2                	ld	ra,24(sp)
    800040ac:	6442                	ld	s0,16(sp)
    800040ae:	64a2                	ld	s1,8(sp)
    800040b0:	6902                	ld	s2,0(sp)
    800040b2:	6105                	addi	sp,sp,32
    800040b4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040b6:	40bc                	lw	a5,64(s1)
    800040b8:	dff1                	beqz	a5,80004094 <iput+0x26>
    800040ba:	04a49783          	lh	a5,74(s1)
    800040be:	fbf9                	bnez	a5,80004094 <iput+0x26>
    acquiresleep(&ip->lock);
    800040c0:	01048913          	addi	s2,s1,16
    800040c4:	854a                	mv	a0,s2
    800040c6:	00001097          	auipc	ra,0x1
    800040ca:	abc080e7          	jalr	-1348(ra) # 80004b82 <acquiresleep>
    release(&itable.lock);
    800040ce:	0001c517          	auipc	a0,0x1c
    800040d2:	11250513          	addi	a0,a0,274 # 800201e0 <itable>
    800040d6:	ffffd097          	auipc	ra,0xffffd
    800040da:	ba0080e7          	jalr	-1120(ra) # 80000c76 <release>
    itrunc(ip);
    800040de:	8526                	mv	a0,s1
    800040e0:	00000097          	auipc	ra,0x0
    800040e4:	ee2080e7          	jalr	-286(ra) # 80003fc2 <itrunc>
    ip->type = 0;
    800040e8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800040ec:	8526                	mv	a0,s1
    800040ee:	00000097          	auipc	ra,0x0
    800040f2:	cfc080e7          	jalr	-772(ra) # 80003dea <iupdate>
    ip->valid = 0;
    800040f6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800040fa:	854a                	mv	a0,s2
    800040fc:	00001097          	auipc	ra,0x1
    80004100:	adc080e7          	jalr	-1316(ra) # 80004bd8 <releasesleep>
    acquire(&itable.lock);
    80004104:	0001c517          	auipc	a0,0x1c
    80004108:	0dc50513          	addi	a0,a0,220 # 800201e0 <itable>
    8000410c:	ffffd097          	auipc	ra,0xffffd
    80004110:	ab6080e7          	jalr	-1354(ra) # 80000bc2 <acquire>
    80004114:	b741                	j	80004094 <iput+0x26>

0000000080004116 <iunlockput>:
{
    80004116:	1101                	addi	sp,sp,-32
    80004118:	ec06                	sd	ra,24(sp)
    8000411a:	e822                	sd	s0,16(sp)
    8000411c:	e426                	sd	s1,8(sp)
    8000411e:	1000                	addi	s0,sp,32
    80004120:	84aa                	mv	s1,a0
  iunlock(ip);
    80004122:	00000097          	auipc	ra,0x0
    80004126:	e54080e7          	jalr	-428(ra) # 80003f76 <iunlock>
  iput(ip);
    8000412a:	8526                	mv	a0,s1
    8000412c:	00000097          	auipc	ra,0x0
    80004130:	f42080e7          	jalr	-190(ra) # 8000406e <iput>
}
    80004134:	60e2                	ld	ra,24(sp)
    80004136:	6442                	ld	s0,16(sp)
    80004138:	64a2                	ld	s1,8(sp)
    8000413a:	6105                	addi	sp,sp,32
    8000413c:	8082                	ret

000000008000413e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000413e:	1141                	addi	sp,sp,-16
    80004140:	e422                	sd	s0,8(sp)
    80004142:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004144:	411c                	lw	a5,0(a0)
    80004146:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004148:	415c                	lw	a5,4(a0)
    8000414a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000414c:	04451783          	lh	a5,68(a0)
    80004150:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004154:	04a51783          	lh	a5,74(a0)
    80004158:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000415c:	04c56783          	lwu	a5,76(a0)
    80004160:	e99c                	sd	a5,16(a1)
}
    80004162:	6422                	ld	s0,8(sp)
    80004164:	0141                	addi	sp,sp,16
    80004166:	8082                	ret

0000000080004168 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004168:	457c                	lw	a5,76(a0)
    8000416a:	0ed7e963          	bltu	a5,a3,8000425c <readi+0xf4>
{
    8000416e:	7159                	addi	sp,sp,-112
    80004170:	f486                	sd	ra,104(sp)
    80004172:	f0a2                	sd	s0,96(sp)
    80004174:	eca6                	sd	s1,88(sp)
    80004176:	e8ca                	sd	s2,80(sp)
    80004178:	e4ce                	sd	s3,72(sp)
    8000417a:	e0d2                	sd	s4,64(sp)
    8000417c:	fc56                	sd	s5,56(sp)
    8000417e:	f85a                	sd	s6,48(sp)
    80004180:	f45e                	sd	s7,40(sp)
    80004182:	f062                	sd	s8,32(sp)
    80004184:	ec66                	sd	s9,24(sp)
    80004186:	e86a                	sd	s10,16(sp)
    80004188:	e46e                	sd	s11,8(sp)
    8000418a:	1880                	addi	s0,sp,112
    8000418c:	8baa                	mv	s7,a0
    8000418e:	8c2e                	mv	s8,a1
    80004190:	8ab2                	mv	s5,a2
    80004192:	84b6                	mv	s1,a3
    80004194:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004196:	9f35                	addw	a4,a4,a3
    return 0;
    80004198:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000419a:	0ad76063          	bltu	a4,a3,8000423a <readi+0xd2>
  if(off + n > ip->size)
    8000419e:	00e7f463          	bgeu	a5,a4,800041a6 <readi+0x3e>
    n = ip->size - off;
    800041a2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041a6:	0a0b0963          	beqz	s6,80004258 <readi+0xf0>
    800041aa:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041ac:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800041b0:	5cfd                	li	s9,-1
    800041b2:	a82d                	j	800041ec <readi+0x84>
    800041b4:	020a1d93          	slli	s11,s4,0x20
    800041b8:	020ddd93          	srli	s11,s11,0x20
    800041bc:	05890793          	addi	a5,s2,88
    800041c0:	86ee                	mv	a3,s11
    800041c2:	963e                	add	a2,a2,a5
    800041c4:	85d6                	mv	a1,s5
    800041c6:	8562                	mv	a0,s8
    800041c8:	ffffe097          	auipc	ra,0xffffe
    800041cc:	2d4080e7          	jalr	724(ra) # 8000249c <either_copyout>
    800041d0:	05950d63          	beq	a0,s9,8000422a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800041d4:	854a                	mv	a0,s2
    800041d6:	fffff097          	auipc	ra,0xfffff
    800041da:	60a080e7          	jalr	1546(ra) # 800037e0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041de:	013a09bb          	addw	s3,s4,s3
    800041e2:	009a04bb          	addw	s1,s4,s1
    800041e6:	9aee                	add	s5,s5,s11
    800041e8:	0569f763          	bgeu	s3,s6,80004236 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800041ec:	000ba903          	lw	s2,0(s7)
    800041f0:	00a4d59b          	srliw	a1,s1,0xa
    800041f4:	855e                	mv	a0,s7
    800041f6:	00000097          	auipc	ra,0x0
    800041fa:	8ae080e7          	jalr	-1874(ra) # 80003aa4 <bmap>
    800041fe:	0005059b          	sext.w	a1,a0
    80004202:	854a                	mv	a0,s2
    80004204:	fffff097          	auipc	ra,0xfffff
    80004208:	4ac080e7          	jalr	1196(ra) # 800036b0 <bread>
    8000420c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000420e:	3ff4f613          	andi	a2,s1,1023
    80004212:	40cd07bb          	subw	a5,s10,a2
    80004216:	413b073b          	subw	a4,s6,s3
    8000421a:	8a3e                	mv	s4,a5
    8000421c:	2781                	sext.w	a5,a5
    8000421e:	0007069b          	sext.w	a3,a4
    80004222:	f8f6f9e3          	bgeu	a3,a5,800041b4 <readi+0x4c>
    80004226:	8a3a                	mv	s4,a4
    80004228:	b771                	j	800041b4 <readi+0x4c>
      brelse(bp);
    8000422a:	854a                	mv	a0,s2
    8000422c:	fffff097          	auipc	ra,0xfffff
    80004230:	5b4080e7          	jalr	1460(ra) # 800037e0 <brelse>
      tot = -1;
    80004234:	59fd                	li	s3,-1
  }
  return tot;
    80004236:	0009851b          	sext.w	a0,s3
}
    8000423a:	70a6                	ld	ra,104(sp)
    8000423c:	7406                	ld	s0,96(sp)
    8000423e:	64e6                	ld	s1,88(sp)
    80004240:	6946                	ld	s2,80(sp)
    80004242:	69a6                	ld	s3,72(sp)
    80004244:	6a06                	ld	s4,64(sp)
    80004246:	7ae2                	ld	s5,56(sp)
    80004248:	7b42                	ld	s6,48(sp)
    8000424a:	7ba2                	ld	s7,40(sp)
    8000424c:	7c02                	ld	s8,32(sp)
    8000424e:	6ce2                	ld	s9,24(sp)
    80004250:	6d42                	ld	s10,16(sp)
    80004252:	6da2                	ld	s11,8(sp)
    80004254:	6165                	addi	sp,sp,112
    80004256:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004258:	89da                	mv	s3,s6
    8000425a:	bff1                	j	80004236 <readi+0xce>
    return 0;
    8000425c:	4501                	li	a0,0
}
    8000425e:	8082                	ret

0000000080004260 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004260:	457c                	lw	a5,76(a0)
    80004262:	10d7e863          	bltu	a5,a3,80004372 <writei+0x112>
{
    80004266:	7159                	addi	sp,sp,-112
    80004268:	f486                	sd	ra,104(sp)
    8000426a:	f0a2                	sd	s0,96(sp)
    8000426c:	eca6                	sd	s1,88(sp)
    8000426e:	e8ca                	sd	s2,80(sp)
    80004270:	e4ce                	sd	s3,72(sp)
    80004272:	e0d2                	sd	s4,64(sp)
    80004274:	fc56                	sd	s5,56(sp)
    80004276:	f85a                	sd	s6,48(sp)
    80004278:	f45e                	sd	s7,40(sp)
    8000427a:	f062                	sd	s8,32(sp)
    8000427c:	ec66                	sd	s9,24(sp)
    8000427e:	e86a                	sd	s10,16(sp)
    80004280:	e46e                	sd	s11,8(sp)
    80004282:	1880                	addi	s0,sp,112
    80004284:	8b2a                	mv	s6,a0
    80004286:	8c2e                	mv	s8,a1
    80004288:	8ab2                	mv	s5,a2
    8000428a:	8936                	mv	s2,a3
    8000428c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000428e:	00e687bb          	addw	a5,a3,a4
    80004292:	0ed7e263          	bltu	a5,a3,80004376 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004296:	00043737          	lui	a4,0x43
    8000429a:	0ef76063          	bltu	a4,a5,8000437a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000429e:	0c0b8863          	beqz	s7,8000436e <writei+0x10e>
    800042a2:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800042a4:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800042a8:	5cfd                	li	s9,-1
    800042aa:	a091                	j	800042ee <writei+0x8e>
    800042ac:	02099d93          	slli	s11,s3,0x20
    800042b0:	020ddd93          	srli	s11,s11,0x20
    800042b4:	05848793          	addi	a5,s1,88
    800042b8:	86ee                	mv	a3,s11
    800042ba:	8656                	mv	a2,s5
    800042bc:	85e2                	mv	a1,s8
    800042be:	953e                	add	a0,a0,a5
    800042c0:	ffffe097          	auipc	ra,0xffffe
    800042c4:	232080e7          	jalr	562(ra) # 800024f2 <either_copyin>
    800042c8:	07950263          	beq	a0,s9,8000432c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800042cc:	8526                	mv	a0,s1
    800042ce:	00000097          	auipc	ra,0x0
    800042d2:	794080e7          	jalr	1940(ra) # 80004a62 <log_write>
    brelse(bp);
    800042d6:	8526                	mv	a0,s1
    800042d8:	fffff097          	auipc	ra,0xfffff
    800042dc:	508080e7          	jalr	1288(ra) # 800037e0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042e0:	01498a3b          	addw	s4,s3,s4
    800042e4:	0129893b          	addw	s2,s3,s2
    800042e8:	9aee                	add	s5,s5,s11
    800042ea:	057a7663          	bgeu	s4,s7,80004336 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800042ee:	000b2483          	lw	s1,0(s6)
    800042f2:	00a9559b          	srliw	a1,s2,0xa
    800042f6:	855a                	mv	a0,s6
    800042f8:	fffff097          	auipc	ra,0xfffff
    800042fc:	7ac080e7          	jalr	1964(ra) # 80003aa4 <bmap>
    80004300:	0005059b          	sext.w	a1,a0
    80004304:	8526                	mv	a0,s1
    80004306:	fffff097          	auipc	ra,0xfffff
    8000430a:	3aa080e7          	jalr	938(ra) # 800036b0 <bread>
    8000430e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004310:	3ff97513          	andi	a0,s2,1023
    80004314:	40ad07bb          	subw	a5,s10,a0
    80004318:	414b873b          	subw	a4,s7,s4
    8000431c:	89be                	mv	s3,a5
    8000431e:	2781                	sext.w	a5,a5
    80004320:	0007069b          	sext.w	a3,a4
    80004324:	f8f6f4e3          	bgeu	a3,a5,800042ac <writei+0x4c>
    80004328:	89ba                	mv	s3,a4
    8000432a:	b749                	j	800042ac <writei+0x4c>
      brelse(bp);
    8000432c:	8526                	mv	a0,s1
    8000432e:	fffff097          	auipc	ra,0xfffff
    80004332:	4b2080e7          	jalr	1202(ra) # 800037e0 <brelse>
  }

  if(off > ip->size)
    80004336:	04cb2783          	lw	a5,76(s6)
    8000433a:	0127f463          	bgeu	a5,s2,80004342 <writei+0xe2>
    ip->size = off;
    8000433e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004342:	855a                	mv	a0,s6
    80004344:	00000097          	auipc	ra,0x0
    80004348:	aa6080e7          	jalr	-1370(ra) # 80003dea <iupdate>

  return tot;
    8000434c:	000a051b          	sext.w	a0,s4
}
    80004350:	70a6                	ld	ra,104(sp)
    80004352:	7406                	ld	s0,96(sp)
    80004354:	64e6                	ld	s1,88(sp)
    80004356:	6946                	ld	s2,80(sp)
    80004358:	69a6                	ld	s3,72(sp)
    8000435a:	6a06                	ld	s4,64(sp)
    8000435c:	7ae2                	ld	s5,56(sp)
    8000435e:	7b42                	ld	s6,48(sp)
    80004360:	7ba2                	ld	s7,40(sp)
    80004362:	7c02                	ld	s8,32(sp)
    80004364:	6ce2                	ld	s9,24(sp)
    80004366:	6d42                	ld	s10,16(sp)
    80004368:	6da2                	ld	s11,8(sp)
    8000436a:	6165                	addi	sp,sp,112
    8000436c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000436e:	8a5e                	mv	s4,s7
    80004370:	bfc9                	j	80004342 <writei+0xe2>
    return -1;
    80004372:	557d                	li	a0,-1
}
    80004374:	8082                	ret
    return -1;
    80004376:	557d                	li	a0,-1
    80004378:	bfe1                	j	80004350 <writei+0xf0>
    return -1;
    8000437a:	557d                	li	a0,-1
    8000437c:	bfd1                	j	80004350 <writei+0xf0>

000000008000437e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000437e:	1141                	addi	sp,sp,-16
    80004380:	e406                	sd	ra,8(sp)
    80004382:	e022                	sd	s0,0(sp)
    80004384:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004386:	4639                	li	a2,14
    80004388:	ffffd097          	auipc	ra,0xffffd
    8000438c:	a0e080e7          	jalr	-1522(ra) # 80000d96 <strncmp>
}
    80004390:	60a2                	ld	ra,8(sp)
    80004392:	6402                	ld	s0,0(sp)
    80004394:	0141                	addi	sp,sp,16
    80004396:	8082                	ret

0000000080004398 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004398:	7139                	addi	sp,sp,-64
    8000439a:	fc06                	sd	ra,56(sp)
    8000439c:	f822                	sd	s0,48(sp)
    8000439e:	f426                	sd	s1,40(sp)
    800043a0:	f04a                	sd	s2,32(sp)
    800043a2:	ec4e                	sd	s3,24(sp)
    800043a4:	e852                	sd	s4,16(sp)
    800043a6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800043a8:	04451703          	lh	a4,68(a0)
    800043ac:	4785                	li	a5,1
    800043ae:	00f71a63          	bne	a4,a5,800043c2 <dirlookup+0x2a>
    800043b2:	892a                	mv	s2,a0
    800043b4:	89ae                	mv	s3,a1
    800043b6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800043b8:	457c                	lw	a5,76(a0)
    800043ba:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800043bc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043be:	e79d                	bnez	a5,800043ec <dirlookup+0x54>
    800043c0:	a8a5                	j	80004438 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800043c2:	00004517          	auipc	a0,0x4
    800043c6:	42e50513          	addi	a0,a0,1070 # 800087f0 <syscalls+0x1c0>
    800043ca:	ffffc097          	auipc	ra,0xffffc
    800043ce:	160080e7          	jalr	352(ra) # 8000052a <panic>
      panic("dirlookup read");
    800043d2:	00004517          	auipc	a0,0x4
    800043d6:	43650513          	addi	a0,a0,1078 # 80008808 <syscalls+0x1d8>
    800043da:	ffffc097          	auipc	ra,0xffffc
    800043de:	150080e7          	jalr	336(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043e2:	24c1                	addiw	s1,s1,16
    800043e4:	04c92783          	lw	a5,76(s2)
    800043e8:	04f4f763          	bgeu	s1,a5,80004436 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043ec:	4741                	li	a4,16
    800043ee:	86a6                	mv	a3,s1
    800043f0:	fc040613          	addi	a2,s0,-64
    800043f4:	4581                	li	a1,0
    800043f6:	854a                	mv	a0,s2
    800043f8:	00000097          	auipc	ra,0x0
    800043fc:	d70080e7          	jalr	-656(ra) # 80004168 <readi>
    80004400:	47c1                	li	a5,16
    80004402:	fcf518e3          	bne	a0,a5,800043d2 <dirlookup+0x3a>
    if(de.inum == 0)
    80004406:	fc045783          	lhu	a5,-64(s0)
    8000440a:	dfe1                	beqz	a5,800043e2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000440c:	fc240593          	addi	a1,s0,-62
    80004410:	854e                	mv	a0,s3
    80004412:	00000097          	auipc	ra,0x0
    80004416:	f6c080e7          	jalr	-148(ra) # 8000437e <namecmp>
    8000441a:	f561                	bnez	a0,800043e2 <dirlookup+0x4a>
      if(poff)
    8000441c:	000a0463          	beqz	s4,80004424 <dirlookup+0x8c>
        *poff = off;
    80004420:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004424:	fc045583          	lhu	a1,-64(s0)
    80004428:	00092503          	lw	a0,0(s2)
    8000442c:	fffff097          	auipc	ra,0xfffff
    80004430:	754080e7          	jalr	1876(ra) # 80003b80 <iget>
    80004434:	a011                	j	80004438 <dirlookup+0xa0>
  return 0;
    80004436:	4501                	li	a0,0
}
    80004438:	70e2                	ld	ra,56(sp)
    8000443a:	7442                	ld	s0,48(sp)
    8000443c:	74a2                	ld	s1,40(sp)
    8000443e:	7902                	ld	s2,32(sp)
    80004440:	69e2                	ld	s3,24(sp)
    80004442:	6a42                	ld	s4,16(sp)
    80004444:	6121                	addi	sp,sp,64
    80004446:	8082                	ret

0000000080004448 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004448:	711d                	addi	sp,sp,-96
    8000444a:	ec86                	sd	ra,88(sp)
    8000444c:	e8a2                	sd	s0,80(sp)
    8000444e:	e4a6                	sd	s1,72(sp)
    80004450:	e0ca                	sd	s2,64(sp)
    80004452:	fc4e                	sd	s3,56(sp)
    80004454:	f852                	sd	s4,48(sp)
    80004456:	f456                	sd	s5,40(sp)
    80004458:	f05a                	sd	s6,32(sp)
    8000445a:	ec5e                	sd	s7,24(sp)
    8000445c:	e862                	sd	s8,16(sp)
    8000445e:	e466                	sd	s9,8(sp)
    80004460:	1080                	addi	s0,sp,96
    80004462:	84aa                	mv	s1,a0
    80004464:	8aae                	mv	s5,a1
    80004466:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004468:	00054703          	lbu	a4,0(a0)
    8000446c:	02f00793          	li	a5,47
    80004470:	02f70363          	beq	a4,a5,80004496 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004474:	ffffd097          	auipc	ra,0xffffd
    80004478:	54e080e7          	jalr	1358(ra) # 800019c2 <myproc>
    8000447c:	17853503          	ld	a0,376(a0)
    80004480:	00000097          	auipc	ra,0x0
    80004484:	9f6080e7          	jalr	-1546(ra) # 80003e76 <idup>
    80004488:	89aa                	mv	s3,a0
  while(*path == '/')
    8000448a:	02f00913          	li	s2,47
  len = path - s;
    8000448e:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004490:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004492:	4b85                	li	s7,1
    80004494:	a865                	j	8000454c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004496:	4585                	li	a1,1
    80004498:	4505                	li	a0,1
    8000449a:	fffff097          	auipc	ra,0xfffff
    8000449e:	6e6080e7          	jalr	1766(ra) # 80003b80 <iget>
    800044a2:	89aa                	mv	s3,a0
    800044a4:	b7dd                	j	8000448a <namex+0x42>
      iunlockput(ip);
    800044a6:	854e                	mv	a0,s3
    800044a8:	00000097          	auipc	ra,0x0
    800044ac:	c6e080e7          	jalr	-914(ra) # 80004116 <iunlockput>
      return 0;
    800044b0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800044b2:	854e                	mv	a0,s3
    800044b4:	60e6                	ld	ra,88(sp)
    800044b6:	6446                	ld	s0,80(sp)
    800044b8:	64a6                	ld	s1,72(sp)
    800044ba:	6906                	ld	s2,64(sp)
    800044bc:	79e2                	ld	s3,56(sp)
    800044be:	7a42                	ld	s4,48(sp)
    800044c0:	7aa2                	ld	s5,40(sp)
    800044c2:	7b02                	ld	s6,32(sp)
    800044c4:	6be2                	ld	s7,24(sp)
    800044c6:	6c42                	ld	s8,16(sp)
    800044c8:	6ca2                	ld	s9,8(sp)
    800044ca:	6125                	addi	sp,sp,96
    800044cc:	8082                	ret
      iunlock(ip);
    800044ce:	854e                	mv	a0,s3
    800044d0:	00000097          	auipc	ra,0x0
    800044d4:	aa6080e7          	jalr	-1370(ra) # 80003f76 <iunlock>
      return ip;
    800044d8:	bfe9                	j	800044b2 <namex+0x6a>
      iunlockput(ip);
    800044da:	854e                	mv	a0,s3
    800044dc:	00000097          	auipc	ra,0x0
    800044e0:	c3a080e7          	jalr	-966(ra) # 80004116 <iunlockput>
      return 0;
    800044e4:	89e6                	mv	s3,s9
    800044e6:	b7f1                	j	800044b2 <namex+0x6a>
  len = path - s;
    800044e8:	40b48633          	sub	a2,s1,a1
    800044ec:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800044f0:	099c5463          	bge	s8,s9,80004578 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800044f4:	4639                	li	a2,14
    800044f6:	8552                	mv	a0,s4
    800044f8:	ffffd097          	auipc	ra,0xffffd
    800044fc:	822080e7          	jalr	-2014(ra) # 80000d1a <memmove>
  while(*path == '/')
    80004500:	0004c783          	lbu	a5,0(s1)
    80004504:	01279763          	bne	a5,s2,80004512 <namex+0xca>
    path++;
    80004508:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000450a:	0004c783          	lbu	a5,0(s1)
    8000450e:	ff278de3          	beq	a5,s2,80004508 <namex+0xc0>
    ilock(ip);
    80004512:	854e                	mv	a0,s3
    80004514:	00000097          	auipc	ra,0x0
    80004518:	9a0080e7          	jalr	-1632(ra) # 80003eb4 <ilock>
    if(ip->type != T_DIR){
    8000451c:	04499783          	lh	a5,68(s3)
    80004520:	f97793e3          	bne	a5,s7,800044a6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004524:	000a8563          	beqz	s5,8000452e <namex+0xe6>
    80004528:	0004c783          	lbu	a5,0(s1)
    8000452c:	d3cd                	beqz	a5,800044ce <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000452e:	865a                	mv	a2,s6
    80004530:	85d2                	mv	a1,s4
    80004532:	854e                	mv	a0,s3
    80004534:	00000097          	auipc	ra,0x0
    80004538:	e64080e7          	jalr	-412(ra) # 80004398 <dirlookup>
    8000453c:	8caa                	mv	s9,a0
    8000453e:	dd51                	beqz	a0,800044da <namex+0x92>
    iunlockput(ip);
    80004540:	854e                	mv	a0,s3
    80004542:	00000097          	auipc	ra,0x0
    80004546:	bd4080e7          	jalr	-1068(ra) # 80004116 <iunlockput>
    ip = next;
    8000454a:	89e6                	mv	s3,s9
  while(*path == '/')
    8000454c:	0004c783          	lbu	a5,0(s1)
    80004550:	05279763          	bne	a5,s2,8000459e <namex+0x156>
    path++;
    80004554:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004556:	0004c783          	lbu	a5,0(s1)
    8000455a:	ff278de3          	beq	a5,s2,80004554 <namex+0x10c>
  if(*path == 0)
    8000455e:	c79d                	beqz	a5,8000458c <namex+0x144>
    path++;
    80004560:	85a6                	mv	a1,s1
  len = path - s;
    80004562:	8cda                	mv	s9,s6
    80004564:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004566:	01278963          	beq	a5,s2,80004578 <namex+0x130>
    8000456a:	dfbd                	beqz	a5,800044e8 <namex+0xa0>
    path++;
    8000456c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000456e:	0004c783          	lbu	a5,0(s1)
    80004572:	ff279ce3          	bne	a5,s2,8000456a <namex+0x122>
    80004576:	bf8d                	j	800044e8 <namex+0xa0>
    memmove(name, s, len);
    80004578:	2601                	sext.w	a2,a2
    8000457a:	8552                	mv	a0,s4
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	79e080e7          	jalr	1950(ra) # 80000d1a <memmove>
    name[len] = 0;
    80004584:	9cd2                	add	s9,s9,s4
    80004586:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000458a:	bf9d                	j	80004500 <namex+0xb8>
  if(nameiparent){
    8000458c:	f20a83e3          	beqz	s5,800044b2 <namex+0x6a>
    iput(ip);
    80004590:	854e                	mv	a0,s3
    80004592:	00000097          	auipc	ra,0x0
    80004596:	adc080e7          	jalr	-1316(ra) # 8000406e <iput>
    return 0;
    8000459a:	4981                	li	s3,0
    8000459c:	bf19                	j	800044b2 <namex+0x6a>
  if(*path == 0)
    8000459e:	d7fd                	beqz	a5,8000458c <namex+0x144>
  while(*path != '/' && *path != 0)
    800045a0:	0004c783          	lbu	a5,0(s1)
    800045a4:	85a6                	mv	a1,s1
    800045a6:	b7d1                	j	8000456a <namex+0x122>

00000000800045a8 <dirlink>:
{
    800045a8:	7139                	addi	sp,sp,-64
    800045aa:	fc06                	sd	ra,56(sp)
    800045ac:	f822                	sd	s0,48(sp)
    800045ae:	f426                	sd	s1,40(sp)
    800045b0:	f04a                	sd	s2,32(sp)
    800045b2:	ec4e                	sd	s3,24(sp)
    800045b4:	e852                	sd	s4,16(sp)
    800045b6:	0080                	addi	s0,sp,64
    800045b8:	892a                	mv	s2,a0
    800045ba:	8a2e                	mv	s4,a1
    800045bc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800045be:	4601                	li	a2,0
    800045c0:	00000097          	auipc	ra,0x0
    800045c4:	dd8080e7          	jalr	-552(ra) # 80004398 <dirlookup>
    800045c8:	e93d                	bnez	a0,8000463e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045ca:	04c92483          	lw	s1,76(s2)
    800045ce:	c49d                	beqz	s1,800045fc <dirlink+0x54>
    800045d0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045d2:	4741                	li	a4,16
    800045d4:	86a6                	mv	a3,s1
    800045d6:	fc040613          	addi	a2,s0,-64
    800045da:	4581                	li	a1,0
    800045dc:	854a                	mv	a0,s2
    800045de:	00000097          	auipc	ra,0x0
    800045e2:	b8a080e7          	jalr	-1142(ra) # 80004168 <readi>
    800045e6:	47c1                	li	a5,16
    800045e8:	06f51163          	bne	a0,a5,8000464a <dirlink+0xa2>
    if(de.inum == 0)
    800045ec:	fc045783          	lhu	a5,-64(s0)
    800045f0:	c791                	beqz	a5,800045fc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045f2:	24c1                	addiw	s1,s1,16
    800045f4:	04c92783          	lw	a5,76(s2)
    800045f8:	fcf4ede3          	bltu	s1,a5,800045d2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800045fc:	4639                	li	a2,14
    800045fe:	85d2                	mv	a1,s4
    80004600:	fc240513          	addi	a0,s0,-62
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	7ce080e7          	jalr	1998(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    8000460c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004610:	4741                	li	a4,16
    80004612:	86a6                	mv	a3,s1
    80004614:	fc040613          	addi	a2,s0,-64
    80004618:	4581                	li	a1,0
    8000461a:	854a                	mv	a0,s2
    8000461c:	00000097          	auipc	ra,0x0
    80004620:	c44080e7          	jalr	-956(ra) # 80004260 <writei>
    80004624:	872a                	mv	a4,a0
    80004626:	47c1                	li	a5,16
  return 0;
    80004628:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000462a:	02f71863          	bne	a4,a5,8000465a <dirlink+0xb2>
}
    8000462e:	70e2                	ld	ra,56(sp)
    80004630:	7442                	ld	s0,48(sp)
    80004632:	74a2                	ld	s1,40(sp)
    80004634:	7902                	ld	s2,32(sp)
    80004636:	69e2                	ld	s3,24(sp)
    80004638:	6a42                	ld	s4,16(sp)
    8000463a:	6121                	addi	sp,sp,64
    8000463c:	8082                	ret
    iput(ip);
    8000463e:	00000097          	auipc	ra,0x0
    80004642:	a30080e7          	jalr	-1488(ra) # 8000406e <iput>
    return -1;
    80004646:	557d                	li	a0,-1
    80004648:	b7dd                	j	8000462e <dirlink+0x86>
      panic("dirlink read");
    8000464a:	00004517          	auipc	a0,0x4
    8000464e:	1ce50513          	addi	a0,a0,462 # 80008818 <syscalls+0x1e8>
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	ed8080e7          	jalr	-296(ra) # 8000052a <panic>
    panic("dirlink");
    8000465a:	00004517          	auipc	a0,0x4
    8000465e:	2c650513          	addi	a0,a0,710 # 80008920 <syscalls+0x2f0>
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	ec8080e7          	jalr	-312(ra) # 8000052a <panic>

000000008000466a <namei>:

struct inode*
namei(char *path)
{
    8000466a:	1101                	addi	sp,sp,-32
    8000466c:	ec06                	sd	ra,24(sp)
    8000466e:	e822                	sd	s0,16(sp)
    80004670:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004672:	fe040613          	addi	a2,s0,-32
    80004676:	4581                	li	a1,0
    80004678:	00000097          	auipc	ra,0x0
    8000467c:	dd0080e7          	jalr	-560(ra) # 80004448 <namex>
}
    80004680:	60e2                	ld	ra,24(sp)
    80004682:	6442                	ld	s0,16(sp)
    80004684:	6105                	addi	sp,sp,32
    80004686:	8082                	ret

0000000080004688 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004688:	1141                	addi	sp,sp,-16
    8000468a:	e406                	sd	ra,8(sp)
    8000468c:	e022                	sd	s0,0(sp)
    8000468e:	0800                	addi	s0,sp,16
    80004690:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004692:	4585                	li	a1,1
    80004694:	00000097          	auipc	ra,0x0
    80004698:	db4080e7          	jalr	-588(ra) # 80004448 <namex>
}
    8000469c:	60a2                	ld	ra,8(sp)
    8000469e:	6402                	ld	s0,0(sp)
    800046a0:	0141                	addi	sp,sp,16
    800046a2:	8082                	ret

00000000800046a4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800046a4:	1101                	addi	sp,sp,-32
    800046a6:	ec06                	sd	ra,24(sp)
    800046a8:	e822                	sd	s0,16(sp)
    800046aa:	e426                	sd	s1,8(sp)
    800046ac:	e04a                	sd	s2,0(sp)
    800046ae:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800046b0:	0001d917          	auipc	s2,0x1d
    800046b4:	5d890913          	addi	s2,s2,1496 # 80021c88 <log>
    800046b8:	01892583          	lw	a1,24(s2)
    800046bc:	02892503          	lw	a0,40(s2)
    800046c0:	fffff097          	auipc	ra,0xfffff
    800046c4:	ff0080e7          	jalr	-16(ra) # 800036b0 <bread>
    800046c8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800046ca:	02c92683          	lw	a3,44(s2)
    800046ce:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800046d0:	02d05863          	blez	a3,80004700 <write_head+0x5c>
    800046d4:	0001d797          	auipc	a5,0x1d
    800046d8:	5e478793          	addi	a5,a5,1508 # 80021cb8 <log+0x30>
    800046dc:	05c50713          	addi	a4,a0,92
    800046e0:	36fd                	addiw	a3,a3,-1
    800046e2:	02069613          	slli	a2,a3,0x20
    800046e6:	01e65693          	srli	a3,a2,0x1e
    800046ea:	0001d617          	auipc	a2,0x1d
    800046ee:	5d260613          	addi	a2,a2,1490 # 80021cbc <log+0x34>
    800046f2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800046f4:	4390                	lw	a2,0(a5)
    800046f6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800046f8:	0791                	addi	a5,a5,4
    800046fa:	0711                	addi	a4,a4,4
    800046fc:	fed79ce3          	bne	a5,a3,800046f4 <write_head+0x50>
  }
  bwrite(buf);
    80004700:	8526                	mv	a0,s1
    80004702:	fffff097          	auipc	ra,0xfffff
    80004706:	0a0080e7          	jalr	160(ra) # 800037a2 <bwrite>
  brelse(buf);
    8000470a:	8526                	mv	a0,s1
    8000470c:	fffff097          	auipc	ra,0xfffff
    80004710:	0d4080e7          	jalr	212(ra) # 800037e0 <brelse>
}
    80004714:	60e2                	ld	ra,24(sp)
    80004716:	6442                	ld	s0,16(sp)
    80004718:	64a2                	ld	s1,8(sp)
    8000471a:	6902                	ld	s2,0(sp)
    8000471c:	6105                	addi	sp,sp,32
    8000471e:	8082                	ret

0000000080004720 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004720:	0001d797          	auipc	a5,0x1d
    80004724:	5947a783          	lw	a5,1428(a5) # 80021cb4 <log+0x2c>
    80004728:	0af05d63          	blez	a5,800047e2 <install_trans+0xc2>
{
    8000472c:	7139                	addi	sp,sp,-64
    8000472e:	fc06                	sd	ra,56(sp)
    80004730:	f822                	sd	s0,48(sp)
    80004732:	f426                	sd	s1,40(sp)
    80004734:	f04a                	sd	s2,32(sp)
    80004736:	ec4e                	sd	s3,24(sp)
    80004738:	e852                	sd	s4,16(sp)
    8000473a:	e456                	sd	s5,8(sp)
    8000473c:	e05a                	sd	s6,0(sp)
    8000473e:	0080                	addi	s0,sp,64
    80004740:	8b2a                	mv	s6,a0
    80004742:	0001da97          	auipc	s5,0x1d
    80004746:	576a8a93          	addi	s5,s5,1398 # 80021cb8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000474a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000474c:	0001d997          	auipc	s3,0x1d
    80004750:	53c98993          	addi	s3,s3,1340 # 80021c88 <log>
    80004754:	a00d                	j	80004776 <install_trans+0x56>
    brelse(lbuf);
    80004756:	854a                	mv	a0,s2
    80004758:	fffff097          	auipc	ra,0xfffff
    8000475c:	088080e7          	jalr	136(ra) # 800037e0 <brelse>
    brelse(dbuf);
    80004760:	8526                	mv	a0,s1
    80004762:	fffff097          	auipc	ra,0xfffff
    80004766:	07e080e7          	jalr	126(ra) # 800037e0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000476a:	2a05                	addiw	s4,s4,1
    8000476c:	0a91                	addi	s5,s5,4
    8000476e:	02c9a783          	lw	a5,44(s3)
    80004772:	04fa5e63          	bge	s4,a5,800047ce <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004776:	0189a583          	lw	a1,24(s3)
    8000477a:	014585bb          	addw	a1,a1,s4
    8000477e:	2585                	addiw	a1,a1,1
    80004780:	0289a503          	lw	a0,40(s3)
    80004784:	fffff097          	auipc	ra,0xfffff
    80004788:	f2c080e7          	jalr	-212(ra) # 800036b0 <bread>
    8000478c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000478e:	000aa583          	lw	a1,0(s5)
    80004792:	0289a503          	lw	a0,40(s3)
    80004796:	fffff097          	auipc	ra,0xfffff
    8000479a:	f1a080e7          	jalr	-230(ra) # 800036b0 <bread>
    8000479e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800047a0:	40000613          	li	a2,1024
    800047a4:	05890593          	addi	a1,s2,88
    800047a8:	05850513          	addi	a0,a0,88
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	56e080e7          	jalr	1390(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    800047b4:	8526                	mv	a0,s1
    800047b6:	fffff097          	auipc	ra,0xfffff
    800047ba:	fec080e7          	jalr	-20(ra) # 800037a2 <bwrite>
    if(recovering == 0)
    800047be:	f80b1ce3          	bnez	s6,80004756 <install_trans+0x36>
      bunpin(dbuf);
    800047c2:	8526                	mv	a0,s1
    800047c4:	fffff097          	auipc	ra,0xfffff
    800047c8:	0f6080e7          	jalr	246(ra) # 800038ba <bunpin>
    800047cc:	b769                	j	80004756 <install_trans+0x36>
}
    800047ce:	70e2                	ld	ra,56(sp)
    800047d0:	7442                	ld	s0,48(sp)
    800047d2:	74a2                	ld	s1,40(sp)
    800047d4:	7902                	ld	s2,32(sp)
    800047d6:	69e2                	ld	s3,24(sp)
    800047d8:	6a42                	ld	s4,16(sp)
    800047da:	6aa2                	ld	s5,8(sp)
    800047dc:	6b02                	ld	s6,0(sp)
    800047de:	6121                	addi	sp,sp,64
    800047e0:	8082                	ret
    800047e2:	8082                	ret

00000000800047e4 <initlog>:
{
    800047e4:	7179                	addi	sp,sp,-48
    800047e6:	f406                	sd	ra,40(sp)
    800047e8:	f022                	sd	s0,32(sp)
    800047ea:	ec26                	sd	s1,24(sp)
    800047ec:	e84a                	sd	s2,16(sp)
    800047ee:	e44e                	sd	s3,8(sp)
    800047f0:	1800                	addi	s0,sp,48
    800047f2:	892a                	mv	s2,a0
    800047f4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800047f6:	0001d497          	auipc	s1,0x1d
    800047fa:	49248493          	addi	s1,s1,1170 # 80021c88 <log>
    800047fe:	00004597          	auipc	a1,0x4
    80004802:	02a58593          	addi	a1,a1,42 # 80008828 <syscalls+0x1f8>
    80004806:	8526                	mv	a0,s1
    80004808:	ffffc097          	auipc	ra,0xffffc
    8000480c:	32a080e7          	jalr	810(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004810:	0149a583          	lw	a1,20(s3)
    80004814:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004816:	0109a783          	lw	a5,16(s3)
    8000481a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000481c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004820:	854a                	mv	a0,s2
    80004822:	fffff097          	auipc	ra,0xfffff
    80004826:	e8e080e7          	jalr	-370(ra) # 800036b0 <bread>
  log.lh.n = lh->n;
    8000482a:	4d34                	lw	a3,88(a0)
    8000482c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000482e:	02d05663          	blez	a3,8000485a <initlog+0x76>
    80004832:	05c50793          	addi	a5,a0,92
    80004836:	0001d717          	auipc	a4,0x1d
    8000483a:	48270713          	addi	a4,a4,1154 # 80021cb8 <log+0x30>
    8000483e:	36fd                	addiw	a3,a3,-1
    80004840:	02069613          	slli	a2,a3,0x20
    80004844:	01e65693          	srli	a3,a2,0x1e
    80004848:	06050613          	addi	a2,a0,96
    8000484c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000484e:	4390                	lw	a2,0(a5)
    80004850:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004852:	0791                	addi	a5,a5,4
    80004854:	0711                	addi	a4,a4,4
    80004856:	fed79ce3          	bne	a5,a3,8000484e <initlog+0x6a>
  brelse(buf);
    8000485a:	fffff097          	auipc	ra,0xfffff
    8000485e:	f86080e7          	jalr	-122(ra) # 800037e0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004862:	4505                	li	a0,1
    80004864:	00000097          	auipc	ra,0x0
    80004868:	ebc080e7          	jalr	-324(ra) # 80004720 <install_trans>
  log.lh.n = 0;
    8000486c:	0001d797          	auipc	a5,0x1d
    80004870:	4407a423          	sw	zero,1096(a5) # 80021cb4 <log+0x2c>
  write_head(); // clear the log
    80004874:	00000097          	auipc	ra,0x0
    80004878:	e30080e7          	jalr	-464(ra) # 800046a4 <write_head>
}
    8000487c:	70a2                	ld	ra,40(sp)
    8000487e:	7402                	ld	s0,32(sp)
    80004880:	64e2                	ld	s1,24(sp)
    80004882:	6942                	ld	s2,16(sp)
    80004884:	69a2                	ld	s3,8(sp)
    80004886:	6145                	addi	sp,sp,48
    80004888:	8082                	ret

000000008000488a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000488a:	1101                	addi	sp,sp,-32
    8000488c:	ec06                	sd	ra,24(sp)
    8000488e:	e822                	sd	s0,16(sp)
    80004890:	e426                	sd	s1,8(sp)
    80004892:	e04a                	sd	s2,0(sp)
    80004894:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004896:	0001d517          	auipc	a0,0x1d
    8000489a:	3f250513          	addi	a0,a0,1010 # 80021c88 <log>
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	324080e7          	jalr	804(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800048a6:	0001d497          	auipc	s1,0x1d
    800048aa:	3e248493          	addi	s1,s1,994 # 80021c88 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048ae:	4979                	li	s2,30
    800048b0:	a039                	j	800048be <begin_op+0x34>
      sleep(&log, &log.lock);
    800048b2:	85a6                	mv	a1,s1
    800048b4:	8526                	mv	a0,s1
    800048b6:	ffffe097          	auipc	ra,0xffffe
    800048ba:	838080e7          	jalr	-1992(ra) # 800020ee <sleep>
    if(log.committing){
    800048be:	50dc                	lw	a5,36(s1)
    800048c0:	fbed                	bnez	a5,800048b2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048c2:	509c                	lw	a5,32(s1)
    800048c4:	0017871b          	addiw	a4,a5,1
    800048c8:	0007069b          	sext.w	a3,a4
    800048cc:	0027179b          	slliw	a5,a4,0x2
    800048d0:	9fb9                	addw	a5,a5,a4
    800048d2:	0017979b          	slliw	a5,a5,0x1
    800048d6:	54d8                	lw	a4,44(s1)
    800048d8:	9fb9                	addw	a5,a5,a4
    800048da:	00f95963          	bge	s2,a5,800048ec <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800048de:	85a6                	mv	a1,s1
    800048e0:	8526                	mv	a0,s1
    800048e2:	ffffe097          	auipc	ra,0xffffe
    800048e6:	80c080e7          	jalr	-2036(ra) # 800020ee <sleep>
    800048ea:	bfd1                	j	800048be <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800048ec:	0001d517          	auipc	a0,0x1d
    800048f0:	39c50513          	addi	a0,a0,924 # 80021c88 <log>
    800048f4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	380080e7          	jalr	896(ra) # 80000c76 <release>
      break;
    }
  }
}
    800048fe:	60e2                	ld	ra,24(sp)
    80004900:	6442                	ld	s0,16(sp)
    80004902:	64a2                	ld	s1,8(sp)
    80004904:	6902                	ld	s2,0(sp)
    80004906:	6105                	addi	sp,sp,32
    80004908:	8082                	ret

000000008000490a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000490a:	7139                	addi	sp,sp,-64
    8000490c:	fc06                	sd	ra,56(sp)
    8000490e:	f822                	sd	s0,48(sp)
    80004910:	f426                	sd	s1,40(sp)
    80004912:	f04a                	sd	s2,32(sp)
    80004914:	ec4e                	sd	s3,24(sp)
    80004916:	e852                	sd	s4,16(sp)
    80004918:	e456                	sd	s5,8(sp)
    8000491a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000491c:	0001d497          	auipc	s1,0x1d
    80004920:	36c48493          	addi	s1,s1,876 # 80021c88 <log>
    80004924:	8526                	mv	a0,s1
    80004926:	ffffc097          	auipc	ra,0xffffc
    8000492a:	29c080e7          	jalr	668(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    8000492e:	509c                	lw	a5,32(s1)
    80004930:	37fd                	addiw	a5,a5,-1
    80004932:	0007891b          	sext.w	s2,a5
    80004936:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004938:	50dc                	lw	a5,36(s1)
    8000493a:	e7b9                	bnez	a5,80004988 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000493c:	04091e63          	bnez	s2,80004998 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004940:	0001d497          	auipc	s1,0x1d
    80004944:	34848493          	addi	s1,s1,840 # 80021c88 <log>
    80004948:	4785                	li	a5,1
    8000494a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000494c:	8526                	mv	a0,s1
    8000494e:	ffffc097          	auipc	ra,0xffffc
    80004952:	328080e7          	jalr	808(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004956:	54dc                	lw	a5,44(s1)
    80004958:	06f04763          	bgtz	a5,800049c6 <end_op+0xbc>
    acquire(&log.lock);
    8000495c:	0001d497          	auipc	s1,0x1d
    80004960:	32c48493          	addi	s1,s1,812 # 80021c88 <log>
    80004964:	8526                	mv	a0,s1
    80004966:	ffffc097          	auipc	ra,0xffffc
    8000496a:	25c080e7          	jalr	604(ra) # 80000bc2 <acquire>
    log.committing = 0;
    8000496e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004972:	8526                	mv	a0,s1
    80004974:	ffffe097          	auipc	ra,0xffffe
    80004978:	906080e7          	jalr	-1786(ra) # 8000227a <wakeup>
    release(&log.lock);
    8000497c:	8526                	mv	a0,s1
    8000497e:	ffffc097          	auipc	ra,0xffffc
    80004982:	2f8080e7          	jalr	760(ra) # 80000c76 <release>
}
    80004986:	a03d                	j	800049b4 <end_op+0xaa>
    panic("log.committing");
    80004988:	00004517          	auipc	a0,0x4
    8000498c:	ea850513          	addi	a0,a0,-344 # 80008830 <syscalls+0x200>
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	b9a080e7          	jalr	-1126(ra) # 8000052a <panic>
    wakeup(&log);
    80004998:	0001d497          	auipc	s1,0x1d
    8000499c:	2f048493          	addi	s1,s1,752 # 80021c88 <log>
    800049a0:	8526                	mv	a0,s1
    800049a2:	ffffe097          	auipc	ra,0xffffe
    800049a6:	8d8080e7          	jalr	-1832(ra) # 8000227a <wakeup>
  release(&log.lock);
    800049aa:	8526                	mv	a0,s1
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	2ca080e7          	jalr	714(ra) # 80000c76 <release>
}
    800049b4:	70e2                	ld	ra,56(sp)
    800049b6:	7442                	ld	s0,48(sp)
    800049b8:	74a2                	ld	s1,40(sp)
    800049ba:	7902                	ld	s2,32(sp)
    800049bc:	69e2                	ld	s3,24(sp)
    800049be:	6a42                	ld	s4,16(sp)
    800049c0:	6aa2                	ld	s5,8(sp)
    800049c2:	6121                	addi	sp,sp,64
    800049c4:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800049c6:	0001da97          	auipc	s5,0x1d
    800049ca:	2f2a8a93          	addi	s5,s5,754 # 80021cb8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800049ce:	0001da17          	auipc	s4,0x1d
    800049d2:	2baa0a13          	addi	s4,s4,698 # 80021c88 <log>
    800049d6:	018a2583          	lw	a1,24(s4)
    800049da:	012585bb          	addw	a1,a1,s2
    800049de:	2585                	addiw	a1,a1,1
    800049e0:	028a2503          	lw	a0,40(s4)
    800049e4:	fffff097          	auipc	ra,0xfffff
    800049e8:	ccc080e7          	jalr	-820(ra) # 800036b0 <bread>
    800049ec:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800049ee:	000aa583          	lw	a1,0(s5)
    800049f2:	028a2503          	lw	a0,40(s4)
    800049f6:	fffff097          	auipc	ra,0xfffff
    800049fa:	cba080e7          	jalr	-838(ra) # 800036b0 <bread>
    800049fe:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004a00:	40000613          	li	a2,1024
    80004a04:	05850593          	addi	a1,a0,88
    80004a08:	05848513          	addi	a0,s1,88
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	30e080e7          	jalr	782(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004a14:	8526                	mv	a0,s1
    80004a16:	fffff097          	auipc	ra,0xfffff
    80004a1a:	d8c080e7          	jalr	-628(ra) # 800037a2 <bwrite>
    brelse(from);
    80004a1e:	854e                	mv	a0,s3
    80004a20:	fffff097          	auipc	ra,0xfffff
    80004a24:	dc0080e7          	jalr	-576(ra) # 800037e0 <brelse>
    brelse(to);
    80004a28:	8526                	mv	a0,s1
    80004a2a:	fffff097          	auipc	ra,0xfffff
    80004a2e:	db6080e7          	jalr	-586(ra) # 800037e0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a32:	2905                	addiw	s2,s2,1
    80004a34:	0a91                	addi	s5,s5,4
    80004a36:	02ca2783          	lw	a5,44(s4)
    80004a3a:	f8f94ee3          	blt	s2,a5,800049d6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a3e:	00000097          	auipc	ra,0x0
    80004a42:	c66080e7          	jalr	-922(ra) # 800046a4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004a46:	4501                	li	a0,0
    80004a48:	00000097          	auipc	ra,0x0
    80004a4c:	cd8080e7          	jalr	-808(ra) # 80004720 <install_trans>
    log.lh.n = 0;
    80004a50:	0001d797          	auipc	a5,0x1d
    80004a54:	2607a223          	sw	zero,612(a5) # 80021cb4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004a58:	00000097          	auipc	ra,0x0
    80004a5c:	c4c080e7          	jalr	-948(ra) # 800046a4 <write_head>
    80004a60:	bdf5                	j	8000495c <end_op+0x52>

0000000080004a62 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004a62:	1101                	addi	sp,sp,-32
    80004a64:	ec06                	sd	ra,24(sp)
    80004a66:	e822                	sd	s0,16(sp)
    80004a68:	e426                	sd	s1,8(sp)
    80004a6a:	e04a                	sd	s2,0(sp)
    80004a6c:	1000                	addi	s0,sp,32
    80004a6e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004a70:	0001d917          	auipc	s2,0x1d
    80004a74:	21890913          	addi	s2,s2,536 # 80021c88 <log>
    80004a78:	854a                	mv	a0,s2
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	148080e7          	jalr	328(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004a82:	02c92603          	lw	a2,44(s2)
    80004a86:	47f5                	li	a5,29
    80004a88:	06c7c563          	blt	a5,a2,80004af2 <log_write+0x90>
    80004a8c:	0001d797          	auipc	a5,0x1d
    80004a90:	2187a783          	lw	a5,536(a5) # 80021ca4 <log+0x1c>
    80004a94:	37fd                	addiw	a5,a5,-1
    80004a96:	04f65e63          	bge	a2,a5,80004af2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004a9a:	0001d797          	auipc	a5,0x1d
    80004a9e:	20e7a783          	lw	a5,526(a5) # 80021ca8 <log+0x20>
    80004aa2:	06f05063          	blez	a5,80004b02 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004aa6:	4781                	li	a5,0
    80004aa8:	06c05563          	blez	a2,80004b12 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004aac:	44cc                	lw	a1,12(s1)
    80004aae:	0001d717          	auipc	a4,0x1d
    80004ab2:	20a70713          	addi	a4,a4,522 # 80021cb8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004ab6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004ab8:	4314                	lw	a3,0(a4)
    80004aba:	04b68c63          	beq	a3,a1,80004b12 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004abe:	2785                	addiw	a5,a5,1
    80004ac0:	0711                	addi	a4,a4,4
    80004ac2:	fef61be3          	bne	a2,a5,80004ab8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004ac6:	0621                	addi	a2,a2,8
    80004ac8:	060a                	slli	a2,a2,0x2
    80004aca:	0001d797          	auipc	a5,0x1d
    80004ace:	1be78793          	addi	a5,a5,446 # 80021c88 <log>
    80004ad2:	963e                	add	a2,a2,a5
    80004ad4:	44dc                	lw	a5,12(s1)
    80004ad6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004ad8:	8526                	mv	a0,s1
    80004ada:	fffff097          	auipc	ra,0xfffff
    80004ade:	da4080e7          	jalr	-604(ra) # 8000387e <bpin>
    log.lh.n++;
    80004ae2:	0001d717          	auipc	a4,0x1d
    80004ae6:	1a670713          	addi	a4,a4,422 # 80021c88 <log>
    80004aea:	575c                	lw	a5,44(a4)
    80004aec:	2785                	addiw	a5,a5,1
    80004aee:	d75c                	sw	a5,44(a4)
    80004af0:	a835                	j	80004b2c <log_write+0xca>
    panic("too big a transaction");
    80004af2:	00004517          	auipc	a0,0x4
    80004af6:	d4e50513          	addi	a0,a0,-690 # 80008840 <syscalls+0x210>
    80004afa:	ffffc097          	auipc	ra,0xffffc
    80004afe:	a30080e7          	jalr	-1488(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004b02:	00004517          	auipc	a0,0x4
    80004b06:	d5650513          	addi	a0,a0,-682 # 80008858 <syscalls+0x228>
    80004b0a:	ffffc097          	auipc	ra,0xffffc
    80004b0e:	a20080e7          	jalr	-1504(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004b12:	00878713          	addi	a4,a5,8
    80004b16:	00271693          	slli	a3,a4,0x2
    80004b1a:	0001d717          	auipc	a4,0x1d
    80004b1e:	16e70713          	addi	a4,a4,366 # 80021c88 <log>
    80004b22:	9736                	add	a4,a4,a3
    80004b24:	44d4                	lw	a3,12(s1)
    80004b26:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004b28:	faf608e3          	beq	a2,a5,80004ad8 <log_write+0x76>
  }
  release(&log.lock);
    80004b2c:	0001d517          	auipc	a0,0x1d
    80004b30:	15c50513          	addi	a0,a0,348 # 80021c88 <log>
    80004b34:	ffffc097          	auipc	ra,0xffffc
    80004b38:	142080e7          	jalr	322(ra) # 80000c76 <release>
}
    80004b3c:	60e2                	ld	ra,24(sp)
    80004b3e:	6442                	ld	s0,16(sp)
    80004b40:	64a2                	ld	s1,8(sp)
    80004b42:	6902                	ld	s2,0(sp)
    80004b44:	6105                	addi	sp,sp,32
    80004b46:	8082                	ret

0000000080004b48 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004b48:	1101                	addi	sp,sp,-32
    80004b4a:	ec06                	sd	ra,24(sp)
    80004b4c:	e822                	sd	s0,16(sp)
    80004b4e:	e426                	sd	s1,8(sp)
    80004b50:	e04a                	sd	s2,0(sp)
    80004b52:	1000                	addi	s0,sp,32
    80004b54:	84aa                	mv	s1,a0
    80004b56:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004b58:	00004597          	auipc	a1,0x4
    80004b5c:	d2058593          	addi	a1,a1,-736 # 80008878 <syscalls+0x248>
    80004b60:	0521                	addi	a0,a0,8
    80004b62:	ffffc097          	auipc	ra,0xffffc
    80004b66:	fd0080e7          	jalr	-48(ra) # 80000b32 <initlock>
  lk->name = name;
    80004b6a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004b6e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b72:	0204a423          	sw	zero,40(s1)
}
    80004b76:	60e2                	ld	ra,24(sp)
    80004b78:	6442                	ld	s0,16(sp)
    80004b7a:	64a2                	ld	s1,8(sp)
    80004b7c:	6902                	ld	s2,0(sp)
    80004b7e:	6105                	addi	sp,sp,32
    80004b80:	8082                	ret

0000000080004b82 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004b82:	1101                	addi	sp,sp,-32
    80004b84:	ec06                	sd	ra,24(sp)
    80004b86:	e822                	sd	s0,16(sp)
    80004b88:	e426                	sd	s1,8(sp)
    80004b8a:	e04a                	sd	s2,0(sp)
    80004b8c:	1000                	addi	s0,sp,32
    80004b8e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b90:	00850913          	addi	s2,a0,8
    80004b94:	854a                	mv	a0,s2
    80004b96:	ffffc097          	auipc	ra,0xffffc
    80004b9a:	02c080e7          	jalr	44(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004b9e:	409c                	lw	a5,0(s1)
    80004ba0:	cb89                	beqz	a5,80004bb2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004ba2:	85ca                	mv	a1,s2
    80004ba4:	8526                	mv	a0,s1
    80004ba6:	ffffd097          	auipc	ra,0xffffd
    80004baa:	548080e7          	jalr	1352(ra) # 800020ee <sleep>
  while (lk->locked) {
    80004bae:	409c                	lw	a5,0(s1)
    80004bb0:	fbed                	bnez	a5,80004ba2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004bb2:	4785                	li	a5,1
    80004bb4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004bb6:	ffffd097          	auipc	ra,0xffffd
    80004bba:	e0c080e7          	jalr	-500(ra) # 800019c2 <myproc>
    80004bbe:	591c                	lw	a5,48(a0)
    80004bc0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004bc2:	854a                	mv	a0,s2
    80004bc4:	ffffc097          	auipc	ra,0xffffc
    80004bc8:	0b2080e7          	jalr	178(ra) # 80000c76 <release>
}
    80004bcc:	60e2                	ld	ra,24(sp)
    80004bce:	6442                	ld	s0,16(sp)
    80004bd0:	64a2                	ld	s1,8(sp)
    80004bd2:	6902                	ld	s2,0(sp)
    80004bd4:	6105                	addi	sp,sp,32
    80004bd6:	8082                	ret

0000000080004bd8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004bd8:	1101                	addi	sp,sp,-32
    80004bda:	ec06                	sd	ra,24(sp)
    80004bdc:	e822                	sd	s0,16(sp)
    80004bde:	e426                	sd	s1,8(sp)
    80004be0:	e04a                	sd	s2,0(sp)
    80004be2:	1000                	addi	s0,sp,32
    80004be4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004be6:	00850913          	addi	s2,a0,8
    80004bea:	854a                	mv	a0,s2
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	fd6080e7          	jalr	-42(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004bf4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004bf8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004bfc:	8526                	mv	a0,s1
    80004bfe:	ffffd097          	auipc	ra,0xffffd
    80004c02:	67c080e7          	jalr	1660(ra) # 8000227a <wakeup>
  release(&lk->lk);
    80004c06:	854a                	mv	a0,s2
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	06e080e7          	jalr	110(ra) # 80000c76 <release>
}
    80004c10:	60e2                	ld	ra,24(sp)
    80004c12:	6442                	ld	s0,16(sp)
    80004c14:	64a2                	ld	s1,8(sp)
    80004c16:	6902                	ld	s2,0(sp)
    80004c18:	6105                	addi	sp,sp,32
    80004c1a:	8082                	ret

0000000080004c1c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004c1c:	7179                	addi	sp,sp,-48
    80004c1e:	f406                	sd	ra,40(sp)
    80004c20:	f022                	sd	s0,32(sp)
    80004c22:	ec26                	sd	s1,24(sp)
    80004c24:	e84a                	sd	s2,16(sp)
    80004c26:	e44e                	sd	s3,8(sp)
    80004c28:	1800                	addi	s0,sp,48
    80004c2a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004c2c:	00850913          	addi	s2,a0,8
    80004c30:	854a                	mv	a0,s2
    80004c32:	ffffc097          	auipc	ra,0xffffc
    80004c36:	f90080e7          	jalr	-112(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c3a:	409c                	lw	a5,0(s1)
    80004c3c:	ef99                	bnez	a5,80004c5a <holdingsleep+0x3e>
    80004c3e:	4481                	li	s1,0
  release(&lk->lk);
    80004c40:	854a                	mv	a0,s2
    80004c42:	ffffc097          	auipc	ra,0xffffc
    80004c46:	034080e7          	jalr	52(ra) # 80000c76 <release>
  return r;
}
    80004c4a:	8526                	mv	a0,s1
    80004c4c:	70a2                	ld	ra,40(sp)
    80004c4e:	7402                	ld	s0,32(sp)
    80004c50:	64e2                	ld	s1,24(sp)
    80004c52:	6942                	ld	s2,16(sp)
    80004c54:	69a2                	ld	s3,8(sp)
    80004c56:	6145                	addi	sp,sp,48
    80004c58:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c5a:	0284a983          	lw	s3,40(s1)
    80004c5e:	ffffd097          	auipc	ra,0xffffd
    80004c62:	d64080e7          	jalr	-668(ra) # 800019c2 <myproc>
    80004c66:	5904                	lw	s1,48(a0)
    80004c68:	413484b3          	sub	s1,s1,s3
    80004c6c:	0014b493          	seqz	s1,s1
    80004c70:	bfc1                	j	80004c40 <holdingsleep+0x24>

0000000080004c72 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004c72:	1141                	addi	sp,sp,-16
    80004c74:	e406                	sd	ra,8(sp)
    80004c76:	e022                	sd	s0,0(sp)
    80004c78:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004c7a:	00004597          	auipc	a1,0x4
    80004c7e:	c0e58593          	addi	a1,a1,-1010 # 80008888 <syscalls+0x258>
    80004c82:	0001d517          	auipc	a0,0x1d
    80004c86:	14e50513          	addi	a0,a0,334 # 80021dd0 <ftable>
    80004c8a:	ffffc097          	auipc	ra,0xffffc
    80004c8e:	ea8080e7          	jalr	-344(ra) # 80000b32 <initlock>
}
    80004c92:	60a2                	ld	ra,8(sp)
    80004c94:	6402                	ld	s0,0(sp)
    80004c96:	0141                	addi	sp,sp,16
    80004c98:	8082                	ret

0000000080004c9a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004c9a:	1101                	addi	sp,sp,-32
    80004c9c:	ec06                	sd	ra,24(sp)
    80004c9e:	e822                	sd	s0,16(sp)
    80004ca0:	e426                	sd	s1,8(sp)
    80004ca2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004ca4:	0001d517          	auipc	a0,0x1d
    80004ca8:	12c50513          	addi	a0,a0,300 # 80021dd0 <ftable>
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	f16080e7          	jalr	-234(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cb4:	0001d497          	auipc	s1,0x1d
    80004cb8:	13448493          	addi	s1,s1,308 # 80021de8 <ftable+0x18>
    80004cbc:	0001e717          	auipc	a4,0x1e
    80004cc0:	0cc70713          	addi	a4,a4,204 # 80022d88 <ftable+0xfb8>
    if(f->ref == 0){
    80004cc4:	40dc                	lw	a5,4(s1)
    80004cc6:	cf99                	beqz	a5,80004ce4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cc8:	02848493          	addi	s1,s1,40
    80004ccc:	fee49ce3          	bne	s1,a4,80004cc4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004cd0:	0001d517          	auipc	a0,0x1d
    80004cd4:	10050513          	addi	a0,a0,256 # 80021dd0 <ftable>
    80004cd8:	ffffc097          	auipc	ra,0xffffc
    80004cdc:	f9e080e7          	jalr	-98(ra) # 80000c76 <release>
  return 0;
    80004ce0:	4481                	li	s1,0
    80004ce2:	a819                	j	80004cf8 <filealloc+0x5e>
      f->ref = 1;
    80004ce4:	4785                	li	a5,1
    80004ce6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004ce8:	0001d517          	auipc	a0,0x1d
    80004cec:	0e850513          	addi	a0,a0,232 # 80021dd0 <ftable>
    80004cf0:	ffffc097          	auipc	ra,0xffffc
    80004cf4:	f86080e7          	jalr	-122(ra) # 80000c76 <release>
}
    80004cf8:	8526                	mv	a0,s1
    80004cfa:	60e2                	ld	ra,24(sp)
    80004cfc:	6442                	ld	s0,16(sp)
    80004cfe:	64a2                	ld	s1,8(sp)
    80004d00:	6105                	addi	sp,sp,32
    80004d02:	8082                	ret

0000000080004d04 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004d04:	1101                	addi	sp,sp,-32
    80004d06:	ec06                	sd	ra,24(sp)
    80004d08:	e822                	sd	s0,16(sp)
    80004d0a:	e426                	sd	s1,8(sp)
    80004d0c:	1000                	addi	s0,sp,32
    80004d0e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004d10:	0001d517          	auipc	a0,0x1d
    80004d14:	0c050513          	addi	a0,a0,192 # 80021dd0 <ftable>
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	eaa080e7          	jalr	-342(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004d20:	40dc                	lw	a5,4(s1)
    80004d22:	02f05263          	blez	a5,80004d46 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004d26:	2785                	addiw	a5,a5,1
    80004d28:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004d2a:	0001d517          	auipc	a0,0x1d
    80004d2e:	0a650513          	addi	a0,a0,166 # 80021dd0 <ftable>
    80004d32:	ffffc097          	auipc	ra,0xffffc
    80004d36:	f44080e7          	jalr	-188(ra) # 80000c76 <release>
  return f;
}
    80004d3a:	8526                	mv	a0,s1
    80004d3c:	60e2                	ld	ra,24(sp)
    80004d3e:	6442                	ld	s0,16(sp)
    80004d40:	64a2                	ld	s1,8(sp)
    80004d42:	6105                	addi	sp,sp,32
    80004d44:	8082                	ret
    panic("filedup");
    80004d46:	00004517          	auipc	a0,0x4
    80004d4a:	b4a50513          	addi	a0,a0,-1206 # 80008890 <syscalls+0x260>
    80004d4e:	ffffb097          	auipc	ra,0xffffb
    80004d52:	7dc080e7          	jalr	2012(ra) # 8000052a <panic>

0000000080004d56 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004d56:	7139                	addi	sp,sp,-64
    80004d58:	fc06                	sd	ra,56(sp)
    80004d5a:	f822                	sd	s0,48(sp)
    80004d5c:	f426                	sd	s1,40(sp)
    80004d5e:	f04a                	sd	s2,32(sp)
    80004d60:	ec4e                	sd	s3,24(sp)
    80004d62:	e852                	sd	s4,16(sp)
    80004d64:	e456                	sd	s5,8(sp)
    80004d66:	0080                	addi	s0,sp,64
    80004d68:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d6a:	0001d517          	auipc	a0,0x1d
    80004d6e:	06650513          	addi	a0,a0,102 # 80021dd0 <ftable>
    80004d72:	ffffc097          	auipc	ra,0xffffc
    80004d76:	e50080e7          	jalr	-432(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004d7a:	40dc                	lw	a5,4(s1)
    80004d7c:	06f05163          	blez	a5,80004dde <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004d80:	37fd                	addiw	a5,a5,-1
    80004d82:	0007871b          	sext.w	a4,a5
    80004d86:	c0dc                	sw	a5,4(s1)
    80004d88:	06e04363          	bgtz	a4,80004dee <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004d8c:	0004a903          	lw	s2,0(s1)
    80004d90:	0094ca83          	lbu	s5,9(s1)
    80004d94:	0104ba03          	ld	s4,16(s1)
    80004d98:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004d9c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004da0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004da4:	0001d517          	auipc	a0,0x1d
    80004da8:	02c50513          	addi	a0,a0,44 # 80021dd0 <ftable>
    80004dac:	ffffc097          	auipc	ra,0xffffc
    80004db0:	eca080e7          	jalr	-310(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004db4:	4785                	li	a5,1
    80004db6:	04f90d63          	beq	s2,a5,80004e10 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004dba:	3979                	addiw	s2,s2,-2
    80004dbc:	4785                	li	a5,1
    80004dbe:	0527e063          	bltu	a5,s2,80004dfe <fileclose+0xa8>
    begin_op();
    80004dc2:	00000097          	auipc	ra,0x0
    80004dc6:	ac8080e7          	jalr	-1336(ra) # 8000488a <begin_op>
    iput(ff.ip);
    80004dca:	854e                	mv	a0,s3
    80004dcc:	fffff097          	auipc	ra,0xfffff
    80004dd0:	2a2080e7          	jalr	674(ra) # 8000406e <iput>
    end_op();
    80004dd4:	00000097          	auipc	ra,0x0
    80004dd8:	b36080e7          	jalr	-1226(ra) # 8000490a <end_op>
    80004ddc:	a00d                	j	80004dfe <fileclose+0xa8>
    panic("fileclose");
    80004dde:	00004517          	auipc	a0,0x4
    80004de2:	aba50513          	addi	a0,a0,-1350 # 80008898 <syscalls+0x268>
    80004de6:	ffffb097          	auipc	ra,0xffffb
    80004dea:	744080e7          	jalr	1860(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004dee:	0001d517          	auipc	a0,0x1d
    80004df2:	fe250513          	addi	a0,a0,-30 # 80021dd0 <ftable>
    80004df6:	ffffc097          	auipc	ra,0xffffc
    80004dfa:	e80080e7          	jalr	-384(ra) # 80000c76 <release>
  }
}
    80004dfe:	70e2                	ld	ra,56(sp)
    80004e00:	7442                	ld	s0,48(sp)
    80004e02:	74a2                	ld	s1,40(sp)
    80004e04:	7902                	ld	s2,32(sp)
    80004e06:	69e2                	ld	s3,24(sp)
    80004e08:	6a42                	ld	s4,16(sp)
    80004e0a:	6aa2                	ld	s5,8(sp)
    80004e0c:	6121                	addi	sp,sp,64
    80004e0e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004e10:	85d6                	mv	a1,s5
    80004e12:	8552                	mv	a0,s4
    80004e14:	00000097          	auipc	ra,0x0
    80004e18:	34c080e7          	jalr	844(ra) # 80005160 <pipeclose>
    80004e1c:	b7cd                	j	80004dfe <fileclose+0xa8>

0000000080004e1e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004e1e:	715d                	addi	sp,sp,-80
    80004e20:	e486                	sd	ra,72(sp)
    80004e22:	e0a2                	sd	s0,64(sp)
    80004e24:	fc26                	sd	s1,56(sp)
    80004e26:	f84a                	sd	s2,48(sp)
    80004e28:	f44e                	sd	s3,40(sp)
    80004e2a:	0880                	addi	s0,sp,80
    80004e2c:	84aa                	mv	s1,a0
    80004e2e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004e30:	ffffd097          	auipc	ra,0xffffd
    80004e34:	b92080e7          	jalr	-1134(ra) # 800019c2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e38:	409c                	lw	a5,0(s1)
    80004e3a:	37f9                	addiw	a5,a5,-2
    80004e3c:	4705                	li	a4,1
    80004e3e:	04f76763          	bltu	a4,a5,80004e8c <filestat+0x6e>
    80004e42:	892a                	mv	s2,a0
    ilock(f->ip);
    80004e44:	6c88                	ld	a0,24(s1)
    80004e46:	fffff097          	auipc	ra,0xfffff
    80004e4a:	06e080e7          	jalr	110(ra) # 80003eb4 <ilock>
    stati(f->ip, &st);
    80004e4e:	fb840593          	addi	a1,s0,-72
    80004e52:	6c88                	ld	a0,24(s1)
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	2ea080e7          	jalr	746(ra) # 8000413e <stati>
    iunlock(f->ip);
    80004e5c:	6c88                	ld	a0,24(s1)
    80004e5e:	fffff097          	auipc	ra,0xfffff
    80004e62:	118080e7          	jalr	280(ra) # 80003f76 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004e66:	46e1                	li	a3,24
    80004e68:	fb840613          	addi	a2,s0,-72
    80004e6c:	85ce                	mv	a1,s3
    80004e6e:	07893503          	ld	a0,120(s2)
    80004e72:	ffffc097          	auipc	ra,0xffffc
    80004e76:	7cc080e7          	jalr	1996(ra) # 8000163e <copyout>
    80004e7a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004e7e:	60a6                	ld	ra,72(sp)
    80004e80:	6406                	ld	s0,64(sp)
    80004e82:	74e2                	ld	s1,56(sp)
    80004e84:	7942                	ld	s2,48(sp)
    80004e86:	79a2                	ld	s3,40(sp)
    80004e88:	6161                	addi	sp,sp,80
    80004e8a:	8082                	ret
  return -1;
    80004e8c:	557d                	li	a0,-1
    80004e8e:	bfc5                	j	80004e7e <filestat+0x60>

0000000080004e90 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004e90:	7179                	addi	sp,sp,-48
    80004e92:	f406                	sd	ra,40(sp)
    80004e94:	f022                	sd	s0,32(sp)
    80004e96:	ec26                	sd	s1,24(sp)
    80004e98:	e84a                	sd	s2,16(sp)
    80004e9a:	e44e                	sd	s3,8(sp)
    80004e9c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004e9e:	00854783          	lbu	a5,8(a0)
    80004ea2:	c3d5                	beqz	a5,80004f46 <fileread+0xb6>
    80004ea4:	84aa                	mv	s1,a0
    80004ea6:	89ae                	mv	s3,a1
    80004ea8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004eaa:	411c                	lw	a5,0(a0)
    80004eac:	4705                	li	a4,1
    80004eae:	04e78963          	beq	a5,a4,80004f00 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004eb2:	470d                	li	a4,3
    80004eb4:	04e78d63          	beq	a5,a4,80004f0e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004eb8:	4709                	li	a4,2
    80004eba:	06e79e63          	bne	a5,a4,80004f36 <fileread+0xa6>
    ilock(f->ip);
    80004ebe:	6d08                	ld	a0,24(a0)
    80004ec0:	fffff097          	auipc	ra,0xfffff
    80004ec4:	ff4080e7          	jalr	-12(ra) # 80003eb4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ec8:	874a                	mv	a4,s2
    80004eca:	5094                	lw	a3,32(s1)
    80004ecc:	864e                	mv	a2,s3
    80004ece:	4585                	li	a1,1
    80004ed0:	6c88                	ld	a0,24(s1)
    80004ed2:	fffff097          	auipc	ra,0xfffff
    80004ed6:	296080e7          	jalr	662(ra) # 80004168 <readi>
    80004eda:	892a                	mv	s2,a0
    80004edc:	00a05563          	blez	a0,80004ee6 <fileread+0x56>
      f->off += r;
    80004ee0:	509c                	lw	a5,32(s1)
    80004ee2:	9fa9                	addw	a5,a5,a0
    80004ee4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ee6:	6c88                	ld	a0,24(s1)
    80004ee8:	fffff097          	auipc	ra,0xfffff
    80004eec:	08e080e7          	jalr	142(ra) # 80003f76 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ef0:	854a                	mv	a0,s2
    80004ef2:	70a2                	ld	ra,40(sp)
    80004ef4:	7402                	ld	s0,32(sp)
    80004ef6:	64e2                	ld	s1,24(sp)
    80004ef8:	6942                	ld	s2,16(sp)
    80004efa:	69a2                	ld	s3,8(sp)
    80004efc:	6145                	addi	sp,sp,48
    80004efe:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f00:	6908                	ld	a0,16(a0)
    80004f02:	00000097          	auipc	ra,0x0
    80004f06:	3c0080e7          	jalr	960(ra) # 800052c2 <piperead>
    80004f0a:	892a                	mv	s2,a0
    80004f0c:	b7d5                	j	80004ef0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f0e:	02451783          	lh	a5,36(a0)
    80004f12:	03079693          	slli	a3,a5,0x30
    80004f16:	92c1                	srli	a3,a3,0x30
    80004f18:	4725                	li	a4,9
    80004f1a:	02d76863          	bltu	a4,a3,80004f4a <fileread+0xba>
    80004f1e:	0792                	slli	a5,a5,0x4
    80004f20:	0001d717          	auipc	a4,0x1d
    80004f24:	e1070713          	addi	a4,a4,-496 # 80021d30 <devsw>
    80004f28:	97ba                	add	a5,a5,a4
    80004f2a:	639c                	ld	a5,0(a5)
    80004f2c:	c38d                	beqz	a5,80004f4e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004f2e:	4505                	li	a0,1
    80004f30:	9782                	jalr	a5
    80004f32:	892a                	mv	s2,a0
    80004f34:	bf75                	j	80004ef0 <fileread+0x60>
    panic("fileread");
    80004f36:	00004517          	auipc	a0,0x4
    80004f3a:	97250513          	addi	a0,a0,-1678 # 800088a8 <syscalls+0x278>
    80004f3e:	ffffb097          	auipc	ra,0xffffb
    80004f42:	5ec080e7          	jalr	1516(ra) # 8000052a <panic>
    return -1;
    80004f46:	597d                	li	s2,-1
    80004f48:	b765                	j	80004ef0 <fileread+0x60>
      return -1;
    80004f4a:	597d                	li	s2,-1
    80004f4c:	b755                	j	80004ef0 <fileread+0x60>
    80004f4e:	597d                	li	s2,-1
    80004f50:	b745                	j	80004ef0 <fileread+0x60>

0000000080004f52 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004f52:	715d                	addi	sp,sp,-80
    80004f54:	e486                	sd	ra,72(sp)
    80004f56:	e0a2                	sd	s0,64(sp)
    80004f58:	fc26                	sd	s1,56(sp)
    80004f5a:	f84a                	sd	s2,48(sp)
    80004f5c:	f44e                	sd	s3,40(sp)
    80004f5e:	f052                	sd	s4,32(sp)
    80004f60:	ec56                	sd	s5,24(sp)
    80004f62:	e85a                	sd	s6,16(sp)
    80004f64:	e45e                	sd	s7,8(sp)
    80004f66:	e062                	sd	s8,0(sp)
    80004f68:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004f6a:	00954783          	lbu	a5,9(a0)
    80004f6e:	10078663          	beqz	a5,8000507a <filewrite+0x128>
    80004f72:	892a                	mv	s2,a0
    80004f74:	8aae                	mv	s5,a1
    80004f76:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f78:	411c                	lw	a5,0(a0)
    80004f7a:	4705                	li	a4,1
    80004f7c:	02e78263          	beq	a5,a4,80004fa0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f80:	470d                	li	a4,3
    80004f82:	02e78663          	beq	a5,a4,80004fae <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f86:	4709                	li	a4,2
    80004f88:	0ee79163          	bne	a5,a4,8000506a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f8c:	0ac05d63          	blez	a2,80005046 <filewrite+0xf4>
    int i = 0;
    80004f90:	4981                	li	s3,0
    80004f92:	6b05                	lui	s6,0x1
    80004f94:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004f98:	6b85                	lui	s7,0x1
    80004f9a:	c00b8b9b          	addiw	s7,s7,-1024
    80004f9e:	a861                	j	80005036 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004fa0:	6908                	ld	a0,16(a0)
    80004fa2:	00000097          	auipc	ra,0x0
    80004fa6:	22e080e7          	jalr	558(ra) # 800051d0 <pipewrite>
    80004faa:	8a2a                	mv	s4,a0
    80004fac:	a045                	j	8000504c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004fae:	02451783          	lh	a5,36(a0)
    80004fb2:	03079693          	slli	a3,a5,0x30
    80004fb6:	92c1                	srli	a3,a3,0x30
    80004fb8:	4725                	li	a4,9
    80004fba:	0cd76263          	bltu	a4,a3,8000507e <filewrite+0x12c>
    80004fbe:	0792                	slli	a5,a5,0x4
    80004fc0:	0001d717          	auipc	a4,0x1d
    80004fc4:	d7070713          	addi	a4,a4,-656 # 80021d30 <devsw>
    80004fc8:	97ba                	add	a5,a5,a4
    80004fca:	679c                	ld	a5,8(a5)
    80004fcc:	cbdd                	beqz	a5,80005082 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004fce:	4505                	li	a0,1
    80004fd0:	9782                	jalr	a5
    80004fd2:	8a2a                	mv	s4,a0
    80004fd4:	a8a5                	j	8000504c <filewrite+0xfa>
    80004fd6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004fda:	00000097          	auipc	ra,0x0
    80004fde:	8b0080e7          	jalr	-1872(ra) # 8000488a <begin_op>
      ilock(f->ip);
    80004fe2:	01893503          	ld	a0,24(s2)
    80004fe6:	fffff097          	auipc	ra,0xfffff
    80004fea:	ece080e7          	jalr	-306(ra) # 80003eb4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004fee:	8762                	mv	a4,s8
    80004ff0:	02092683          	lw	a3,32(s2)
    80004ff4:	01598633          	add	a2,s3,s5
    80004ff8:	4585                	li	a1,1
    80004ffa:	01893503          	ld	a0,24(s2)
    80004ffe:	fffff097          	auipc	ra,0xfffff
    80005002:	262080e7          	jalr	610(ra) # 80004260 <writei>
    80005006:	84aa                	mv	s1,a0
    80005008:	00a05763          	blez	a0,80005016 <filewrite+0xc4>
        f->off += r;
    8000500c:	02092783          	lw	a5,32(s2)
    80005010:	9fa9                	addw	a5,a5,a0
    80005012:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005016:	01893503          	ld	a0,24(s2)
    8000501a:	fffff097          	auipc	ra,0xfffff
    8000501e:	f5c080e7          	jalr	-164(ra) # 80003f76 <iunlock>
      end_op();
    80005022:	00000097          	auipc	ra,0x0
    80005026:	8e8080e7          	jalr	-1816(ra) # 8000490a <end_op>

      if(r != n1){
    8000502a:	009c1f63          	bne	s8,s1,80005048 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000502e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005032:	0149db63          	bge	s3,s4,80005048 <filewrite+0xf6>
      int n1 = n - i;
    80005036:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000503a:	84be                	mv	s1,a5
    8000503c:	2781                	sext.w	a5,a5
    8000503e:	f8fb5ce3          	bge	s6,a5,80004fd6 <filewrite+0x84>
    80005042:	84de                	mv	s1,s7
    80005044:	bf49                	j	80004fd6 <filewrite+0x84>
    int i = 0;
    80005046:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005048:	013a1f63          	bne	s4,s3,80005066 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000504c:	8552                	mv	a0,s4
    8000504e:	60a6                	ld	ra,72(sp)
    80005050:	6406                	ld	s0,64(sp)
    80005052:	74e2                	ld	s1,56(sp)
    80005054:	7942                	ld	s2,48(sp)
    80005056:	79a2                	ld	s3,40(sp)
    80005058:	7a02                	ld	s4,32(sp)
    8000505a:	6ae2                	ld	s5,24(sp)
    8000505c:	6b42                	ld	s6,16(sp)
    8000505e:	6ba2                	ld	s7,8(sp)
    80005060:	6c02                	ld	s8,0(sp)
    80005062:	6161                	addi	sp,sp,80
    80005064:	8082                	ret
    ret = (i == n ? n : -1);
    80005066:	5a7d                	li	s4,-1
    80005068:	b7d5                	j	8000504c <filewrite+0xfa>
    panic("filewrite");
    8000506a:	00004517          	auipc	a0,0x4
    8000506e:	84e50513          	addi	a0,a0,-1970 # 800088b8 <syscalls+0x288>
    80005072:	ffffb097          	auipc	ra,0xffffb
    80005076:	4b8080e7          	jalr	1208(ra) # 8000052a <panic>
    return -1;
    8000507a:	5a7d                	li	s4,-1
    8000507c:	bfc1                	j	8000504c <filewrite+0xfa>
      return -1;
    8000507e:	5a7d                	li	s4,-1
    80005080:	b7f1                	j	8000504c <filewrite+0xfa>
    80005082:	5a7d                	li	s4,-1
    80005084:	b7e1                	j	8000504c <filewrite+0xfa>

0000000080005086 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005086:	7179                	addi	sp,sp,-48
    80005088:	f406                	sd	ra,40(sp)
    8000508a:	f022                	sd	s0,32(sp)
    8000508c:	ec26                	sd	s1,24(sp)
    8000508e:	e84a                	sd	s2,16(sp)
    80005090:	e44e                	sd	s3,8(sp)
    80005092:	e052                	sd	s4,0(sp)
    80005094:	1800                	addi	s0,sp,48
    80005096:	84aa                	mv	s1,a0
    80005098:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000509a:	0005b023          	sd	zero,0(a1)
    8000509e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800050a2:	00000097          	auipc	ra,0x0
    800050a6:	bf8080e7          	jalr	-1032(ra) # 80004c9a <filealloc>
    800050aa:	e088                	sd	a0,0(s1)
    800050ac:	c551                	beqz	a0,80005138 <pipealloc+0xb2>
    800050ae:	00000097          	auipc	ra,0x0
    800050b2:	bec080e7          	jalr	-1044(ra) # 80004c9a <filealloc>
    800050b6:	00aa3023          	sd	a0,0(s4)
    800050ba:	c92d                	beqz	a0,8000512c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800050bc:	ffffc097          	auipc	ra,0xffffc
    800050c0:	a16080e7          	jalr	-1514(ra) # 80000ad2 <kalloc>
    800050c4:	892a                	mv	s2,a0
    800050c6:	c125                	beqz	a0,80005126 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800050c8:	4985                	li	s3,1
    800050ca:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800050ce:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800050d2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800050d6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800050da:	00003597          	auipc	a1,0x3
    800050de:	3b658593          	addi	a1,a1,950 # 80008490 <states.0+0x1e0>
    800050e2:	ffffc097          	auipc	ra,0xffffc
    800050e6:	a50080e7          	jalr	-1456(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800050ea:	609c                	ld	a5,0(s1)
    800050ec:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800050f0:	609c                	ld	a5,0(s1)
    800050f2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800050f6:	609c                	ld	a5,0(s1)
    800050f8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800050fc:	609c                	ld	a5,0(s1)
    800050fe:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005102:	000a3783          	ld	a5,0(s4)
    80005106:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000510a:	000a3783          	ld	a5,0(s4)
    8000510e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005112:	000a3783          	ld	a5,0(s4)
    80005116:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000511a:	000a3783          	ld	a5,0(s4)
    8000511e:	0127b823          	sd	s2,16(a5)
  return 0;
    80005122:	4501                	li	a0,0
    80005124:	a025                	j	8000514c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005126:	6088                	ld	a0,0(s1)
    80005128:	e501                	bnez	a0,80005130 <pipealloc+0xaa>
    8000512a:	a039                	j	80005138 <pipealloc+0xb2>
    8000512c:	6088                	ld	a0,0(s1)
    8000512e:	c51d                	beqz	a0,8000515c <pipealloc+0xd6>
    fileclose(*f0);
    80005130:	00000097          	auipc	ra,0x0
    80005134:	c26080e7          	jalr	-986(ra) # 80004d56 <fileclose>
  if(*f1)
    80005138:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000513c:	557d                	li	a0,-1
  if(*f1)
    8000513e:	c799                	beqz	a5,8000514c <pipealloc+0xc6>
    fileclose(*f1);
    80005140:	853e                	mv	a0,a5
    80005142:	00000097          	auipc	ra,0x0
    80005146:	c14080e7          	jalr	-1004(ra) # 80004d56 <fileclose>
  return -1;
    8000514a:	557d                	li	a0,-1
}
    8000514c:	70a2                	ld	ra,40(sp)
    8000514e:	7402                	ld	s0,32(sp)
    80005150:	64e2                	ld	s1,24(sp)
    80005152:	6942                	ld	s2,16(sp)
    80005154:	69a2                	ld	s3,8(sp)
    80005156:	6a02                	ld	s4,0(sp)
    80005158:	6145                	addi	sp,sp,48
    8000515a:	8082                	ret
  return -1;
    8000515c:	557d                	li	a0,-1
    8000515e:	b7fd                	j	8000514c <pipealloc+0xc6>

0000000080005160 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005160:	1101                	addi	sp,sp,-32
    80005162:	ec06                	sd	ra,24(sp)
    80005164:	e822                	sd	s0,16(sp)
    80005166:	e426                	sd	s1,8(sp)
    80005168:	e04a                	sd	s2,0(sp)
    8000516a:	1000                	addi	s0,sp,32
    8000516c:	84aa                	mv	s1,a0
    8000516e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005170:	ffffc097          	auipc	ra,0xffffc
    80005174:	a52080e7          	jalr	-1454(ra) # 80000bc2 <acquire>
  if(writable){
    80005178:	02090d63          	beqz	s2,800051b2 <pipeclose+0x52>
    pi->writeopen = 0;
    8000517c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005180:	21848513          	addi	a0,s1,536
    80005184:	ffffd097          	auipc	ra,0xffffd
    80005188:	0f6080e7          	jalr	246(ra) # 8000227a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000518c:	2204b783          	ld	a5,544(s1)
    80005190:	eb95                	bnez	a5,800051c4 <pipeclose+0x64>
    release(&pi->lock);
    80005192:	8526                	mv	a0,s1
    80005194:	ffffc097          	auipc	ra,0xffffc
    80005198:	ae2080e7          	jalr	-1310(ra) # 80000c76 <release>
    kfree((char*)pi);
    8000519c:	8526                	mv	a0,s1
    8000519e:	ffffc097          	auipc	ra,0xffffc
    800051a2:	838080e7          	jalr	-1992(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800051a6:	60e2                	ld	ra,24(sp)
    800051a8:	6442                	ld	s0,16(sp)
    800051aa:	64a2                	ld	s1,8(sp)
    800051ac:	6902                	ld	s2,0(sp)
    800051ae:	6105                	addi	sp,sp,32
    800051b0:	8082                	ret
    pi->readopen = 0;
    800051b2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800051b6:	21c48513          	addi	a0,s1,540
    800051ba:	ffffd097          	auipc	ra,0xffffd
    800051be:	0c0080e7          	jalr	192(ra) # 8000227a <wakeup>
    800051c2:	b7e9                	j	8000518c <pipeclose+0x2c>
    release(&pi->lock);
    800051c4:	8526                	mv	a0,s1
    800051c6:	ffffc097          	auipc	ra,0xffffc
    800051ca:	ab0080e7          	jalr	-1360(ra) # 80000c76 <release>
}
    800051ce:	bfe1                	j	800051a6 <pipeclose+0x46>

00000000800051d0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800051d0:	711d                	addi	sp,sp,-96
    800051d2:	ec86                	sd	ra,88(sp)
    800051d4:	e8a2                	sd	s0,80(sp)
    800051d6:	e4a6                	sd	s1,72(sp)
    800051d8:	e0ca                	sd	s2,64(sp)
    800051da:	fc4e                	sd	s3,56(sp)
    800051dc:	f852                	sd	s4,48(sp)
    800051de:	f456                	sd	s5,40(sp)
    800051e0:	f05a                	sd	s6,32(sp)
    800051e2:	ec5e                	sd	s7,24(sp)
    800051e4:	e862                	sd	s8,16(sp)
    800051e6:	1080                	addi	s0,sp,96
    800051e8:	84aa                	mv	s1,a0
    800051ea:	8aae                	mv	s5,a1
    800051ec:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800051ee:	ffffc097          	auipc	ra,0xffffc
    800051f2:	7d4080e7          	jalr	2004(ra) # 800019c2 <myproc>
    800051f6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800051f8:	8526                	mv	a0,s1
    800051fa:	ffffc097          	auipc	ra,0xffffc
    800051fe:	9c8080e7          	jalr	-1592(ra) # 80000bc2 <acquire>
  while(i < n){
    80005202:	0b405363          	blez	s4,800052a8 <pipewrite+0xd8>
  int i = 0;
    80005206:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005208:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000520a:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000520e:	21c48b93          	addi	s7,s1,540
    80005212:	a089                	j	80005254 <pipewrite+0x84>
      release(&pi->lock);
    80005214:	8526                	mv	a0,s1
    80005216:	ffffc097          	auipc	ra,0xffffc
    8000521a:	a60080e7          	jalr	-1440(ra) # 80000c76 <release>
      return -1;
    8000521e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005220:	854a                	mv	a0,s2
    80005222:	60e6                	ld	ra,88(sp)
    80005224:	6446                	ld	s0,80(sp)
    80005226:	64a6                	ld	s1,72(sp)
    80005228:	6906                	ld	s2,64(sp)
    8000522a:	79e2                	ld	s3,56(sp)
    8000522c:	7a42                	ld	s4,48(sp)
    8000522e:	7aa2                	ld	s5,40(sp)
    80005230:	7b02                	ld	s6,32(sp)
    80005232:	6be2                	ld	s7,24(sp)
    80005234:	6c42                	ld	s8,16(sp)
    80005236:	6125                	addi	sp,sp,96
    80005238:	8082                	ret
      wakeup(&pi->nread);
    8000523a:	8562                	mv	a0,s8
    8000523c:	ffffd097          	auipc	ra,0xffffd
    80005240:	03e080e7          	jalr	62(ra) # 8000227a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005244:	85a6                	mv	a1,s1
    80005246:	855e                	mv	a0,s7
    80005248:	ffffd097          	auipc	ra,0xffffd
    8000524c:	ea6080e7          	jalr	-346(ra) # 800020ee <sleep>
  while(i < n){
    80005250:	05495d63          	bge	s2,s4,800052aa <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005254:	2204a783          	lw	a5,544(s1)
    80005258:	dfd5                	beqz	a5,80005214 <pipewrite+0x44>
    8000525a:	0289a783          	lw	a5,40(s3)
    8000525e:	fbdd                	bnez	a5,80005214 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005260:	2184a783          	lw	a5,536(s1)
    80005264:	21c4a703          	lw	a4,540(s1)
    80005268:	2007879b          	addiw	a5,a5,512
    8000526c:	fcf707e3          	beq	a4,a5,8000523a <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005270:	4685                	li	a3,1
    80005272:	01590633          	add	a2,s2,s5
    80005276:	faf40593          	addi	a1,s0,-81
    8000527a:	0789b503          	ld	a0,120(s3)
    8000527e:	ffffc097          	auipc	ra,0xffffc
    80005282:	44c080e7          	jalr	1100(ra) # 800016ca <copyin>
    80005286:	03650263          	beq	a0,s6,800052aa <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000528a:	21c4a783          	lw	a5,540(s1)
    8000528e:	0017871b          	addiw	a4,a5,1
    80005292:	20e4ae23          	sw	a4,540(s1)
    80005296:	1ff7f793          	andi	a5,a5,511
    8000529a:	97a6                	add	a5,a5,s1
    8000529c:	faf44703          	lbu	a4,-81(s0)
    800052a0:	00e78c23          	sb	a4,24(a5)
      i++;
    800052a4:	2905                	addiw	s2,s2,1
    800052a6:	b76d                	j	80005250 <pipewrite+0x80>
  int i = 0;
    800052a8:	4901                	li	s2,0
  wakeup(&pi->nread);
    800052aa:	21848513          	addi	a0,s1,536
    800052ae:	ffffd097          	auipc	ra,0xffffd
    800052b2:	fcc080e7          	jalr	-52(ra) # 8000227a <wakeup>
  release(&pi->lock);
    800052b6:	8526                	mv	a0,s1
    800052b8:	ffffc097          	auipc	ra,0xffffc
    800052bc:	9be080e7          	jalr	-1602(ra) # 80000c76 <release>
  return i;
    800052c0:	b785                	j	80005220 <pipewrite+0x50>

00000000800052c2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800052c2:	715d                	addi	sp,sp,-80
    800052c4:	e486                	sd	ra,72(sp)
    800052c6:	e0a2                	sd	s0,64(sp)
    800052c8:	fc26                	sd	s1,56(sp)
    800052ca:	f84a                	sd	s2,48(sp)
    800052cc:	f44e                	sd	s3,40(sp)
    800052ce:	f052                	sd	s4,32(sp)
    800052d0:	ec56                	sd	s5,24(sp)
    800052d2:	e85a                	sd	s6,16(sp)
    800052d4:	0880                	addi	s0,sp,80
    800052d6:	84aa                	mv	s1,a0
    800052d8:	892e                	mv	s2,a1
    800052da:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800052dc:	ffffc097          	auipc	ra,0xffffc
    800052e0:	6e6080e7          	jalr	1766(ra) # 800019c2 <myproc>
    800052e4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800052e6:	8526                	mv	a0,s1
    800052e8:	ffffc097          	auipc	ra,0xffffc
    800052ec:	8da080e7          	jalr	-1830(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052f0:	2184a703          	lw	a4,536(s1)
    800052f4:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800052f8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052fc:	02f71463          	bne	a4,a5,80005324 <piperead+0x62>
    80005300:	2244a783          	lw	a5,548(s1)
    80005304:	c385                	beqz	a5,80005324 <piperead+0x62>
    if(pr->killed){
    80005306:	028a2783          	lw	a5,40(s4)
    8000530a:	ebc1                	bnez	a5,8000539a <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000530c:	85a6                	mv	a1,s1
    8000530e:	854e                	mv	a0,s3
    80005310:	ffffd097          	auipc	ra,0xffffd
    80005314:	dde080e7          	jalr	-546(ra) # 800020ee <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005318:	2184a703          	lw	a4,536(s1)
    8000531c:	21c4a783          	lw	a5,540(s1)
    80005320:	fef700e3          	beq	a4,a5,80005300 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005324:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005326:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005328:	05505363          	blez	s5,8000536e <piperead+0xac>
    if(pi->nread == pi->nwrite)
    8000532c:	2184a783          	lw	a5,536(s1)
    80005330:	21c4a703          	lw	a4,540(s1)
    80005334:	02f70d63          	beq	a4,a5,8000536e <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005338:	0017871b          	addiw	a4,a5,1
    8000533c:	20e4ac23          	sw	a4,536(s1)
    80005340:	1ff7f793          	andi	a5,a5,511
    80005344:	97a6                	add	a5,a5,s1
    80005346:	0187c783          	lbu	a5,24(a5)
    8000534a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000534e:	4685                	li	a3,1
    80005350:	fbf40613          	addi	a2,s0,-65
    80005354:	85ca                	mv	a1,s2
    80005356:	078a3503          	ld	a0,120(s4)
    8000535a:	ffffc097          	auipc	ra,0xffffc
    8000535e:	2e4080e7          	jalr	740(ra) # 8000163e <copyout>
    80005362:	01650663          	beq	a0,s6,8000536e <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005366:	2985                	addiw	s3,s3,1
    80005368:	0905                	addi	s2,s2,1
    8000536a:	fd3a91e3          	bne	s5,s3,8000532c <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000536e:	21c48513          	addi	a0,s1,540
    80005372:	ffffd097          	auipc	ra,0xffffd
    80005376:	f08080e7          	jalr	-248(ra) # 8000227a <wakeup>
  release(&pi->lock);
    8000537a:	8526                	mv	a0,s1
    8000537c:	ffffc097          	auipc	ra,0xffffc
    80005380:	8fa080e7          	jalr	-1798(ra) # 80000c76 <release>
  return i;
}
    80005384:	854e                	mv	a0,s3
    80005386:	60a6                	ld	ra,72(sp)
    80005388:	6406                	ld	s0,64(sp)
    8000538a:	74e2                	ld	s1,56(sp)
    8000538c:	7942                	ld	s2,48(sp)
    8000538e:	79a2                	ld	s3,40(sp)
    80005390:	7a02                	ld	s4,32(sp)
    80005392:	6ae2                	ld	s5,24(sp)
    80005394:	6b42                	ld	s6,16(sp)
    80005396:	6161                	addi	sp,sp,80
    80005398:	8082                	ret
      release(&pi->lock);
    8000539a:	8526                	mv	a0,s1
    8000539c:	ffffc097          	auipc	ra,0xffffc
    800053a0:	8da080e7          	jalr	-1830(ra) # 80000c76 <release>
      return -1;
    800053a4:	59fd                	li	s3,-1
    800053a6:	bff9                	j	80005384 <piperead+0xc2>

00000000800053a8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800053a8:	de010113          	addi	sp,sp,-544
    800053ac:	20113c23          	sd	ra,536(sp)
    800053b0:	20813823          	sd	s0,528(sp)
    800053b4:	20913423          	sd	s1,520(sp)
    800053b8:	21213023          	sd	s2,512(sp)
    800053bc:	ffce                	sd	s3,504(sp)
    800053be:	fbd2                	sd	s4,496(sp)
    800053c0:	f7d6                	sd	s5,488(sp)
    800053c2:	f3da                	sd	s6,480(sp)
    800053c4:	efde                	sd	s7,472(sp)
    800053c6:	ebe2                	sd	s8,464(sp)
    800053c8:	e7e6                	sd	s9,456(sp)
    800053ca:	e3ea                	sd	s10,448(sp)
    800053cc:	ff6e                	sd	s11,440(sp)
    800053ce:	1400                	addi	s0,sp,544
    800053d0:	892a                	mv	s2,a0
    800053d2:	dea43423          	sd	a0,-536(s0)
    800053d6:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800053da:	ffffc097          	auipc	ra,0xffffc
    800053de:	5e8080e7          	jalr	1512(ra) # 800019c2 <myproc>
    800053e2:	84aa                	mv	s1,a0

  begin_op();
    800053e4:	fffff097          	auipc	ra,0xfffff
    800053e8:	4a6080e7          	jalr	1190(ra) # 8000488a <begin_op>

  if((ip = namei(path)) == 0){
    800053ec:	854a                	mv	a0,s2
    800053ee:	fffff097          	auipc	ra,0xfffff
    800053f2:	27c080e7          	jalr	636(ra) # 8000466a <namei>
    800053f6:	c93d                	beqz	a0,8000546c <exec+0xc4>
    800053f8:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	aba080e7          	jalr	-1350(ra) # 80003eb4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005402:	04000713          	li	a4,64
    80005406:	4681                	li	a3,0
    80005408:	e4840613          	addi	a2,s0,-440
    8000540c:	4581                	li	a1,0
    8000540e:	8556                	mv	a0,s5
    80005410:	fffff097          	auipc	ra,0xfffff
    80005414:	d58080e7          	jalr	-680(ra) # 80004168 <readi>
    80005418:	04000793          	li	a5,64
    8000541c:	00f51a63          	bne	a0,a5,80005430 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005420:	e4842703          	lw	a4,-440(s0)
    80005424:	464c47b7          	lui	a5,0x464c4
    80005428:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000542c:	04f70663          	beq	a4,a5,80005478 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005430:	8556                	mv	a0,s5
    80005432:	fffff097          	auipc	ra,0xfffff
    80005436:	ce4080e7          	jalr	-796(ra) # 80004116 <iunlockput>
    end_op();
    8000543a:	fffff097          	auipc	ra,0xfffff
    8000543e:	4d0080e7          	jalr	1232(ra) # 8000490a <end_op>
  }
  return -1;
    80005442:	557d                	li	a0,-1
}
    80005444:	21813083          	ld	ra,536(sp)
    80005448:	21013403          	ld	s0,528(sp)
    8000544c:	20813483          	ld	s1,520(sp)
    80005450:	20013903          	ld	s2,512(sp)
    80005454:	79fe                	ld	s3,504(sp)
    80005456:	7a5e                	ld	s4,496(sp)
    80005458:	7abe                	ld	s5,488(sp)
    8000545a:	7b1e                	ld	s6,480(sp)
    8000545c:	6bfe                	ld	s7,472(sp)
    8000545e:	6c5e                	ld	s8,464(sp)
    80005460:	6cbe                	ld	s9,456(sp)
    80005462:	6d1e                	ld	s10,448(sp)
    80005464:	7dfa                	ld	s11,440(sp)
    80005466:	22010113          	addi	sp,sp,544
    8000546a:	8082                	ret
    end_op();
    8000546c:	fffff097          	auipc	ra,0xfffff
    80005470:	49e080e7          	jalr	1182(ra) # 8000490a <end_op>
    return -1;
    80005474:	557d                	li	a0,-1
    80005476:	b7f9                	j	80005444 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005478:	8526                	mv	a0,s1
    8000547a:	ffffc097          	auipc	ra,0xffffc
    8000547e:	60c080e7          	jalr	1548(ra) # 80001a86 <proc_pagetable>
    80005482:	8b2a                	mv	s6,a0
    80005484:	d555                	beqz	a0,80005430 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005486:	e6842783          	lw	a5,-408(s0)
    8000548a:	e8045703          	lhu	a4,-384(s0)
    8000548e:	c735                	beqz	a4,800054fa <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005490:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005492:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005496:	6a05                	lui	s4,0x1
    80005498:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000549c:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    800054a0:	6d85                	lui	s11,0x1
    800054a2:	7d7d                	lui	s10,0xfffff
    800054a4:	ac1d                	j	800056da <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800054a6:	00003517          	auipc	a0,0x3
    800054aa:	42250513          	addi	a0,a0,1058 # 800088c8 <syscalls+0x298>
    800054ae:	ffffb097          	auipc	ra,0xffffb
    800054b2:	07c080e7          	jalr	124(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800054b6:	874a                	mv	a4,s2
    800054b8:	009c86bb          	addw	a3,s9,s1
    800054bc:	4581                	li	a1,0
    800054be:	8556                	mv	a0,s5
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	ca8080e7          	jalr	-856(ra) # 80004168 <readi>
    800054c8:	2501                	sext.w	a0,a0
    800054ca:	1aa91863          	bne	s2,a0,8000567a <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    800054ce:	009d84bb          	addw	s1,s11,s1
    800054d2:	013d09bb          	addw	s3,s10,s3
    800054d6:	1f74f263          	bgeu	s1,s7,800056ba <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    800054da:	02049593          	slli	a1,s1,0x20
    800054de:	9181                	srli	a1,a1,0x20
    800054e0:	95e2                	add	a1,a1,s8
    800054e2:	855a                	mv	a0,s6
    800054e4:	ffffc097          	auipc	ra,0xffffc
    800054e8:	b68080e7          	jalr	-1176(ra) # 8000104c <walkaddr>
    800054ec:	862a                	mv	a2,a0
    if(pa == 0)
    800054ee:	dd45                	beqz	a0,800054a6 <exec+0xfe>
      n = PGSIZE;
    800054f0:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800054f2:	fd49f2e3          	bgeu	s3,s4,800054b6 <exec+0x10e>
      n = sz - i;
    800054f6:	894e                	mv	s2,s3
    800054f8:	bf7d                	j	800054b6 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800054fa:	4481                	li	s1,0
  iunlockput(ip);
    800054fc:	8556                	mv	a0,s5
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	c18080e7          	jalr	-1000(ra) # 80004116 <iunlockput>
  end_op();
    80005506:	fffff097          	auipc	ra,0xfffff
    8000550a:	404080e7          	jalr	1028(ra) # 8000490a <end_op>
  p = myproc();
    8000550e:	ffffc097          	auipc	ra,0xffffc
    80005512:	4b4080e7          	jalr	1204(ra) # 800019c2 <myproc>
    80005516:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005518:	07053d03          	ld	s10,112(a0)
  sz = PGROUNDUP(sz);
    8000551c:	6785                	lui	a5,0x1
    8000551e:	17fd                	addi	a5,a5,-1
    80005520:	94be                	add	s1,s1,a5
    80005522:	77fd                	lui	a5,0xfffff
    80005524:	8fe5                	and	a5,a5,s1
    80005526:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000552a:	6609                	lui	a2,0x2
    8000552c:	963e                	add	a2,a2,a5
    8000552e:	85be                	mv	a1,a5
    80005530:	855a                	mv	a0,s6
    80005532:	ffffc097          	auipc	ra,0xffffc
    80005536:	ebc080e7          	jalr	-324(ra) # 800013ee <uvmalloc>
    8000553a:	8c2a                	mv	s8,a0
  ip = 0;
    8000553c:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000553e:	12050e63          	beqz	a0,8000567a <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005542:	75f9                	lui	a1,0xffffe
    80005544:	95aa                	add	a1,a1,a0
    80005546:	855a                	mv	a0,s6
    80005548:	ffffc097          	auipc	ra,0xffffc
    8000554c:	0c4080e7          	jalr	196(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80005550:	7afd                	lui	s5,0xfffff
    80005552:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005554:	df043783          	ld	a5,-528(s0)
    80005558:	6388                	ld	a0,0(a5)
    8000555a:	c925                	beqz	a0,800055ca <exec+0x222>
    8000555c:	e8840993          	addi	s3,s0,-376
    80005560:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005564:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005566:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005568:	ffffc097          	auipc	ra,0xffffc
    8000556c:	8da080e7          	jalr	-1830(ra) # 80000e42 <strlen>
    80005570:	0015079b          	addiw	a5,a0,1
    80005574:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005578:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000557c:	13596363          	bltu	s2,s5,800056a2 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005580:	df043d83          	ld	s11,-528(s0)
    80005584:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005588:	8552                	mv	a0,s4
    8000558a:	ffffc097          	auipc	ra,0xffffc
    8000558e:	8b8080e7          	jalr	-1864(ra) # 80000e42 <strlen>
    80005592:	0015069b          	addiw	a3,a0,1
    80005596:	8652                	mv	a2,s4
    80005598:	85ca                	mv	a1,s2
    8000559a:	855a                	mv	a0,s6
    8000559c:	ffffc097          	auipc	ra,0xffffc
    800055a0:	0a2080e7          	jalr	162(ra) # 8000163e <copyout>
    800055a4:	10054363          	bltz	a0,800056aa <exec+0x302>
    ustack[argc] = sp;
    800055a8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800055ac:	0485                	addi	s1,s1,1
    800055ae:	008d8793          	addi	a5,s11,8
    800055b2:	def43823          	sd	a5,-528(s0)
    800055b6:	008db503          	ld	a0,8(s11)
    800055ba:	c911                	beqz	a0,800055ce <exec+0x226>
    if(argc >= MAXARG)
    800055bc:	09a1                	addi	s3,s3,8
    800055be:	fb3c95e3          	bne	s9,s3,80005568 <exec+0x1c0>
  sz = sz1;
    800055c2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055c6:	4a81                	li	s5,0
    800055c8:	a84d                	j	8000567a <exec+0x2d2>
  sp = sz;
    800055ca:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800055cc:	4481                	li	s1,0
  ustack[argc] = 0;
    800055ce:	00349793          	slli	a5,s1,0x3
    800055d2:	f9040713          	addi	a4,s0,-112
    800055d6:	97ba                	add	a5,a5,a4
    800055d8:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    800055dc:	00148693          	addi	a3,s1,1
    800055e0:	068e                	slli	a3,a3,0x3
    800055e2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800055e6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800055ea:	01597663          	bgeu	s2,s5,800055f6 <exec+0x24e>
  sz = sz1;
    800055ee:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055f2:	4a81                	li	s5,0
    800055f4:	a059                	j	8000567a <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800055f6:	e8840613          	addi	a2,s0,-376
    800055fa:	85ca                	mv	a1,s2
    800055fc:	855a                	mv	a0,s6
    800055fe:	ffffc097          	auipc	ra,0xffffc
    80005602:	040080e7          	jalr	64(ra) # 8000163e <copyout>
    80005606:	0a054663          	bltz	a0,800056b2 <exec+0x30a>
  p->trapframe->a1 = sp;
    8000560a:	080bb783          	ld	a5,128(s7) # 1080 <_entry-0x7fffef80>
    8000560e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005612:	de843783          	ld	a5,-536(s0)
    80005616:	0007c703          	lbu	a4,0(a5)
    8000561a:	cf11                	beqz	a4,80005636 <exec+0x28e>
    8000561c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000561e:	02f00693          	li	a3,47
    80005622:	a039                	j	80005630 <exec+0x288>
      last = s+1;
    80005624:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005628:	0785                	addi	a5,a5,1
    8000562a:	fff7c703          	lbu	a4,-1(a5)
    8000562e:	c701                	beqz	a4,80005636 <exec+0x28e>
    if(*s == '/')
    80005630:	fed71ce3          	bne	a4,a3,80005628 <exec+0x280>
    80005634:	bfc5                	j	80005624 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005636:	4641                	li	a2,16
    80005638:	de843583          	ld	a1,-536(s0)
    8000563c:	180b8513          	addi	a0,s7,384
    80005640:	ffffb097          	auipc	ra,0xffffb
    80005644:	7d0080e7          	jalr	2000(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005648:	078bb503          	ld	a0,120(s7)
  p->pagetable = pagetable;
    8000564c:	076bbc23          	sd	s6,120(s7)
  p->sz = sz;
    80005650:	078bb823          	sd	s8,112(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005654:	080bb783          	ld	a5,128(s7)
    80005658:	e6043703          	ld	a4,-416(s0)
    8000565c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000565e:	080bb783          	ld	a5,128(s7)
    80005662:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005666:	85ea                	mv	a1,s10
    80005668:	ffffc097          	auipc	ra,0xffffc
    8000566c:	4ba080e7          	jalr	1210(ra) # 80001b22 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005670:	0004851b          	sext.w	a0,s1
    80005674:	bbc1                	j	80005444 <exec+0x9c>
    80005676:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000567a:	df843583          	ld	a1,-520(s0)
    8000567e:	855a                	mv	a0,s6
    80005680:	ffffc097          	auipc	ra,0xffffc
    80005684:	4a2080e7          	jalr	1186(ra) # 80001b22 <proc_freepagetable>
  if(ip){
    80005688:	da0a94e3          	bnez	s5,80005430 <exec+0x88>
  return -1;
    8000568c:	557d                	li	a0,-1
    8000568e:	bb5d                	j	80005444 <exec+0x9c>
    80005690:	de943c23          	sd	s1,-520(s0)
    80005694:	b7dd                	j	8000567a <exec+0x2d2>
    80005696:	de943c23          	sd	s1,-520(s0)
    8000569a:	b7c5                	j	8000567a <exec+0x2d2>
    8000569c:	de943c23          	sd	s1,-520(s0)
    800056a0:	bfe9                	j	8000567a <exec+0x2d2>
  sz = sz1;
    800056a2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056a6:	4a81                	li	s5,0
    800056a8:	bfc9                	j	8000567a <exec+0x2d2>
  sz = sz1;
    800056aa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056ae:	4a81                	li	s5,0
    800056b0:	b7e9                	j	8000567a <exec+0x2d2>
  sz = sz1;
    800056b2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056b6:	4a81                	li	s5,0
    800056b8:	b7c9                	j	8000567a <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800056ba:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056be:	e0843783          	ld	a5,-504(s0)
    800056c2:	0017869b          	addiw	a3,a5,1
    800056c6:	e0d43423          	sd	a3,-504(s0)
    800056ca:	e0043783          	ld	a5,-512(s0)
    800056ce:	0387879b          	addiw	a5,a5,56
    800056d2:	e8045703          	lhu	a4,-384(s0)
    800056d6:	e2e6d3e3          	bge	a3,a4,800054fc <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800056da:	2781                	sext.w	a5,a5
    800056dc:	e0f43023          	sd	a5,-512(s0)
    800056e0:	03800713          	li	a4,56
    800056e4:	86be                	mv	a3,a5
    800056e6:	e1040613          	addi	a2,s0,-496
    800056ea:	4581                	li	a1,0
    800056ec:	8556                	mv	a0,s5
    800056ee:	fffff097          	auipc	ra,0xfffff
    800056f2:	a7a080e7          	jalr	-1414(ra) # 80004168 <readi>
    800056f6:	03800793          	li	a5,56
    800056fa:	f6f51ee3          	bne	a0,a5,80005676 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800056fe:	e1042783          	lw	a5,-496(s0)
    80005702:	4705                	li	a4,1
    80005704:	fae79de3          	bne	a5,a4,800056be <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005708:	e3843603          	ld	a2,-456(s0)
    8000570c:	e3043783          	ld	a5,-464(s0)
    80005710:	f8f660e3          	bltu	a2,a5,80005690 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005714:	e2043783          	ld	a5,-480(s0)
    80005718:	963e                	add	a2,a2,a5
    8000571a:	f6f66ee3          	bltu	a2,a5,80005696 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000571e:	85a6                	mv	a1,s1
    80005720:	855a                	mv	a0,s6
    80005722:	ffffc097          	auipc	ra,0xffffc
    80005726:	ccc080e7          	jalr	-820(ra) # 800013ee <uvmalloc>
    8000572a:	dea43c23          	sd	a0,-520(s0)
    8000572e:	d53d                	beqz	a0,8000569c <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005730:	e2043c03          	ld	s8,-480(s0)
    80005734:	de043783          	ld	a5,-544(s0)
    80005738:	00fc77b3          	and	a5,s8,a5
    8000573c:	ff9d                	bnez	a5,8000567a <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000573e:	e1842c83          	lw	s9,-488(s0)
    80005742:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005746:	f60b8ae3          	beqz	s7,800056ba <exec+0x312>
    8000574a:	89de                	mv	s3,s7
    8000574c:	4481                	li	s1,0
    8000574e:	b371                	j	800054da <exec+0x132>

0000000080005750 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005750:	7179                	addi	sp,sp,-48
    80005752:	f406                	sd	ra,40(sp)
    80005754:	f022                	sd	s0,32(sp)
    80005756:	ec26                	sd	s1,24(sp)
    80005758:	e84a                	sd	s2,16(sp)
    8000575a:	1800                	addi	s0,sp,48
    8000575c:	892e                	mv	s2,a1
    8000575e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005760:	fdc40593          	addi	a1,s0,-36
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	a14080e7          	jalr	-1516(ra) # 80003178 <argint>
    8000576c:	04054063          	bltz	a0,800057ac <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005770:	fdc42703          	lw	a4,-36(s0)
    80005774:	47bd                	li	a5,15
    80005776:	02e7ed63          	bltu	a5,a4,800057b0 <argfd+0x60>
    8000577a:	ffffc097          	auipc	ra,0xffffc
    8000577e:	248080e7          	jalr	584(ra) # 800019c2 <myproc>
    80005782:	fdc42703          	lw	a4,-36(s0)
    80005786:	01e70793          	addi	a5,a4,30
    8000578a:	078e                	slli	a5,a5,0x3
    8000578c:	953e                	add	a0,a0,a5
    8000578e:	651c                	ld	a5,8(a0)
    80005790:	c395                	beqz	a5,800057b4 <argfd+0x64>
    return -1;
  if(pfd)
    80005792:	00090463          	beqz	s2,8000579a <argfd+0x4a>
    *pfd = fd;
    80005796:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000579a:	4501                	li	a0,0
  if(pf)
    8000579c:	c091                	beqz	s1,800057a0 <argfd+0x50>
    *pf = f;
    8000579e:	e09c                	sd	a5,0(s1)
}
    800057a0:	70a2                	ld	ra,40(sp)
    800057a2:	7402                	ld	s0,32(sp)
    800057a4:	64e2                	ld	s1,24(sp)
    800057a6:	6942                	ld	s2,16(sp)
    800057a8:	6145                	addi	sp,sp,48
    800057aa:	8082                	ret
    return -1;
    800057ac:	557d                	li	a0,-1
    800057ae:	bfcd                	j	800057a0 <argfd+0x50>
    return -1;
    800057b0:	557d                	li	a0,-1
    800057b2:	b7fd                	j	800057a0 <argfd+0x50>
    800057b4:	557d                	li	a0,-1
    800057b6:	b7ed                	j	800057a0 <argfd+0x50>

00000000800057b8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800057b8:	1101                	addi	sp,sp,-32
    800057ba:	ec06                	sd	ra,24(sp)
    800057bc:	e822                	sd	s0,16(sp)
    800057be:	e426                	sd	s1,8(sp)
    800057c0:	1000                	addi	s0,sp,32
    800057c2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800057c4:	ffffc097          	auipc	ra,0xffffc
    800057c8:	1fe080e7          	jalr	510(ra) # 800019c2 <myproc>
    800057cc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800057ce:	0f850793          	addi	a5,a0,248
    800057d2:	4501                	li	a0,0
    800057d4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800057d6:	6398                	ld	a4,0(a5)
    800057d8:	cb19                	beqz	a4,800057ee <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800057da:	2505                	addiw	a0,a0,1
    800057dc:	07a1                	addi	a5,a5,8
    800057de:	fed51ce3          	bne	a0,a3,800057d6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800057e2:	557d                	li	a0,-1
}
    800057e4:	60e2                	ld	ra,24(sp)
    800057e6:	6442                	ld	s0,16(sp)
    800057e8:	64a2                	ld	s1,8(sp)
    800057ea:	6105                	addi	sp,sp,32
    800057ec:	8082                	ret
      p->ofile[fd] = f;
    800057ee:	01e50793          	addi	a5,a0,30
    800057f2:	078e                	slli	a5,a5,0x3
    800057f4:	963e                	add	a2,a2,a5
    800057f6:	e604                	sd	s1,8(a2)
      return fd;
    800057f8:	b7f5                	j	800057e4 <fdalloc+0x2c>

00000000800057fa <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800057fa:	715d                	addi	sp,sp,-80
    800057fc:	e486                	sd	ra,72(sp)
    800057fe:	e0a2                	sd	s0,64(sp)
    80005800:	fc26                	sd	s1,56(sp)
    80005802:	f84a                	sd	s2,48(sp)
    80005804:	f44e                	sd	s3,40(sp)
    80005806:	f052                	sd	s4,32(sp)
    80005808:	ec56                	sd	s5,24(sp)
    8000580a:	0880                	addi	s0,sp,80
    8000580c:	89ae                	mv	s3,a1
    8000580e:	8ab2                	mv	s5,a2
    80005810:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005812:	fb040593          	addi	a1,s0,-80
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	e72080e7          	jalr	-398(ra) # 80004688 <nameiparent>
    8000581e:	892a                	mv	s2,a0
    80005820:	12050e63          	beqz	a0,8000595c <create+0x162>
    return 0;

  ilock(dp);
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	690080e7          	jalr	1680(ra) # 80003eb4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000582c:	4601                	li	a2,0
    8000582e:	fb040593          	addi	a1,s0,-80
    80005832:	854a                	mv	a0,s2
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	b64080e7          	jalr	-1180(ra) # 80004398 <dirlookup>
    8000583c:	84aa                	mv	s1,a0
    8000583e:	c921                	beqz	a0,8000588e <create+0x94>
    iunlockput(dp);
    80005840:	854a                	mv	a0,s2
    80005842:	fffff097          	auipc	ra,0xfffff
    80005846:	8d4080e7          	jalr	-1836(ra) # 80004116 <iunlockput>
    ilock(ip);
    8000584a:	8526                	mv	a0,s1
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	668080e7          	jalr	1640(ra) # 80003eb4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005854:	2981                	sext.w	s3,s3
    80005856:	4789                	li	a5,2
    80005858:	02f99463          	bne	s3,a5,80005880 <create+0x86>
    8000585c:	0444d783          	lhu	a5,68(s1)
    80005860:	37f9                	addiw	a5,a5,-2
    80005862:	17c2                	slli	a5,a5,0x30
    80005864:	93c1                	srli	a5,a5,0x30
    80005866:	4705                	li	a4,1
    80005868:	00f76c63          	bltu	a4,a5,80005880 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000586c:	8526                	mv	a0,s1
    8000586e:	60a6                	ld	ra,72(sp)
    80005870:	6406                	ld	s0,64(sp)
    80005872:	74e2                	ld	s1,56(sp)
    80005874:	7942                	ld	s2,48(sp)
    80005876:	79a2                	ld	s3,40(sp)
    80005878:	7a02                	ld	s4,32(sp)
    8000587a:	6ae2                	ld	s5,24(sp)
    8000587c:	6161                	addi	sp,sp,80
    8000587e:	8082                	ret
    iunlockput(ip);
    80005880:	8526                	mv	a0,s1
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	894080e7          	jalr	-1900(ra) # 80004116 <iunlockput>
    return 0;
    8000588a:	4481                	li	s1,0
    8000588c:	b7c5                	j	8000586c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000588e:	85ce                	mv	a1,s3
    80005890:	00092503          	lw	a0,0(s2)
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	488080e7          	jalr	1160(ra) # 80003d1c <ialloc>
    8000589c:	84aa                	mv	s1,a0
    8000589e:	c521                	beqz	a0,800058e6 <create+0xec>
  ilock(ip);
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	614080e7          	jalr	1556(ra) # 80003eb4 <ilock>
  ip->major = major;
    800058a8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800058ac:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800058b0:	4a05                	li	s4,1
    800058b2:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800058b6:	8526                	mv	a0,s1
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	532080e7          	jalr	1330(ra) # 80003dea <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800058c0:	2981                	sext.w	s3,s3
    800058c2:	03498a63          	beq	s3,s4,800058f6 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800058c6:	40d0                	lw	a2,4(s1)
    800058c8:	fb040593          	addi	a1,s0,-80
    800058cc:	854a                	mv	a0,s2
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	cda080e7          	jalr	-806(ra) # 800045a8 <dirlink>
    800058d6:	06054b63          	bltz	a0,8000594c <create+0x152>
  iunlockput(dp);
    800058da:	854a                	mv	a0,s2
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	83a080e7          	jalr	-1990(ra) # 80004116 <iunlockput>
  return ip;
    800058e4:	b761                	j	8000586c <create+0x72>
    panic("create: ialloc");
    800058e6:	00003517          	auipc	a0,0x3
    800058ea:	00250513          	addi	a0,a0,2 # 800088e8 <syscalls+0x2b8>
    800058ee:	ffffb097          	auipc	ra,0xffffb
    800058f2:	c3c080e7          	jalr	-964(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    800058f6:	04a95783          	lhu	a5,74(s2)
    800058fa:	2785                	addiw	a5,a5,1
    800058fc:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005900:	854a                	mv	a0,s2
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	4e8080e7          	jalr	1256(ra) # 80003dea <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000590a:	40d0                	lw	a2,4(s1)
    8000590c:	00003597          	auipc	a1,0x3
    80005910:	fec58593          	addi	a1,a1,-20 # 800088f8 <syscalls+0x2c8>
    80005914:	8526                	mv	a0,s1
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	c92080e7          	jalr	-878(ra) # 800045a8 <dirlink>
    8000591e:	00054f63          	bltz	a0,8000593c <create+0x142>
    80005922:	00492603          	lw	a2,4(s2)
    80005926:	00003597          	auipc	a1,0x3
    8000592a:	fda58593          	addi	a1,a1,-38 # 80008900 <syscalls+0x2d0>
    8000592e:	8526                	mv	a0,s1
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	c78080e7          	jalr	-904(ra) # 800045a8 <dirlink>
    80005938:	f80557e3          	bgez	a0,800058c6 <create+0xcc>
      panic("create dots");
    8000593c:	00003517          	auipc	a0,0x3
    80005940:	fcc50513          	addi	a0,a0,-52 # 80008908 <syscalls+0x2d8>
    80005944:	ffffb097          	auipc	ra,0xffffb
    80005948:	be6080e7          	jalr	-1050(ra) # 8000052a <panic>
    panic("create: dirlink");
    8000594c:	00003517          	auipc	a0,0x3
    80005950:	fcc50513          	addi	a0,a0,-52 # 80008918 <syscalls+0x2e8>
    80005954:	ffffb097          	auipc	ra,0xffffb
    80005958:	bd6080e7          	jalr	-1066(ra) # 8000052a <panic>
    return 0;
    8000595c:	84aa                	mv	s1,a0
    8000595e:	b739                	j	8000586c <create+0x72>

0000000080005960 <sys_dup>:
{
    80005960:	7179                	addi	sp,sp,-48
    80005962:	f406                	sd	ra,40(sp)
    80005964:	f022                	sd	s0,32(sp)
    80005966:	ec26                	sd	s1,24(sp)
    80005968:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000596a:	fd840613          	addi	a2,s0,-40
    8000596e:	4581                	li	a1,0
    80005970:	4501                	li	a0,0
    80005972:	00000097          	auipc	ra,0x0
    80005976:	dde080e7          	jalr	-546(ra) # 80005750 <argfd>
    return -1;
    8000597a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000597c:	02054363          	bltz	a0,800059a2 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005980:	fd843503          	ld	a0,-40(s0)
    80005984:	00000097          	auipc	ra,0x0
    80005988:	e34080e7          	jalr	-460(ra) # 800057b8 <fdalloc>
    8000598c:	84aa                	mv	s1,a0
    return -1;
    8000598e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005990:	00054963          	bltz	a0,800059a2 <sys_dup+0x42>
  filedup(f);
    80005994:	fd843503          	ld	a0,-40(s0)
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	36c080e7          	jalr	876(ra) # 80004d04 <filedup>
  return fd;
    800059a0:	87a6                	mv	a5,s1
}
    800059a2:	853e                	mv	a0,a5
    800059a4:	70a2                	ld	ra,40(sp)
    800059a6:	7402                	ld	s0,32(sp)
    800059a8:	64e2                	ld	s1,24(sp)
    800059aa:	6145                	addi	sp,sp,48
    800059ac:	8082                	ret

00000000800059ae <sys_read>:
{
    800059ae:	7179                	addi	sp,sp,-48
    800059b0:	f406                	sd	ra,40(sp)
    800059b2:	f022                	sd	s0,32(sp)
    800059b4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059b6:	fe840613          	addi	a2,s0,-24
    800059ba:	4581                	li	a1,0
    800059bc:	4501                	li	a0,0
    800059be:	00000097          	auipc	ra,0x0
    800059c2:	d92080e7          	jalr	-622(ra) # 80005750 <argfd>
    return -1;
    800059c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059c8:	04054163          	bltz	a0,80005a0a <sys_read+0x5c>
    800059cc:	fe440593          	addi	a1,s0,-28
    800059d0:	4509                	li	a0,2
    800059d2:	ffffd097          	auipc	ra,0xffffd
    800059d6:	7a6080e7          	jalr	1958(ra) # 80003178 <argint>
    return -1;
    800059da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059dc:	02054763          	bltz	a0,80005a0a <sys_read+0x5c>
    800059e0:	fd840593          	addi	a1,s0,-40
    800059e4:	4505                	li	a0,1
    800059e6:	ffffd097          	auipc	ra,0xffffd
    800059ea:	7b4080e7          	jalr	1972(ra) # 8000319a <argaddr>
    return -1;
    800059ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059f0:	00054d63          	bltz	a0,80005a0a <sys_read+0x5c>
  return fileread(f, p, n);
    800059f4:	fe442603          	lw	a2,-28(s0)
    800059f8:	fd843583          	ld	a1,-40(s0)
    800059fc:	fe843503          	ld	a0,-24(s0)
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	490080e7          	jalr	1168(ra) # 80004e90 <fileread>
    80005a08:	87aa                	mv	a5,a0
}
    80005a0a:	853e                	mv	a0,a5
    80005a0c:	70a2                	ld	ra,40(sp)
    80005a0e:	7402                	ld	s0,32(sp)
    80005a10:	6145                	addi	sp,sp,48
    80005a12:	8082                	ret

0000000080005a14 <sys_write>:
{
    80005a14:	7179                	addi	sp,sp,-48
    80005a16:	f406                	sd	ra,40(sp)
    80005a18:	f022                	sd	s0,32(sp)
    80005a1a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a1c:	fe840613          	addi	a2,s0,-24
    80005a20:	4581                	li	a1,0
    80005a22:	4501                	li	a0,0
    80005a24:	00000097          	auipc	ra,0x0
    80005a28:	d2c080e7          	jalr	-724(ra) # 80005750 <argfd>
    return -1;
    80005a2c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a2e:	04054163          	bltz	a0,80005a70 <sys_write+0x5c>
    80005a32:	fe440593          	addi	a1,s0,-28
    80005a36:	4509                	li	a0,2
    80005a38:	ffffd097          	auipc	ra,0xffffd
    80005a3c:	740080e7          	jalr	1856(ra) # 80003178 <argint>
    return -1;
    80005a40:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a42:	02054763          	bltz	a0,80005a70 <sys_write+0x5c>
    80005a46:	fd840593          	addi	a1,s0,-40
    80005a4a:	4505                	li	a0,1
    80005a4c:	ffffd097          	auipc	ra,0xffffd
    80005a50:	74e080e7          	jalr	1870(ra) # 8000319a <argaddr>
    return -1;
    80005a54:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a56:	00054d63          	bltz	a0,80005a70 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005a5a:	fe442603          	lw	a2,-28(s0)
    80005a5e:	fd843583          	ld	a1,-40(s0)
    80005a62:	fe843503          	ld	a0,-24(s0)
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	4ec080e7          	jalr	1260(ra) # 80004f52 <filewrite>
    80005a6e:	87aa                	mv	a5,a0
}
    80005a70:	853e                	mv	a0,a5
    80005a72:	70a2                	ld	ra,40(sp)
    80005a74:	7402                	ld	s0,32(sp)
    80005a76:	6145                	addi	sp,sp,48
    80005a78:	8082                	ret

0000000080005a7a <sys_close>:
{
    80005a7a:	1101                	addi	sp,sp,-32
    80005a7c:	ec06                	sd	ra,24(sp)
    80005a7e:	e822                	sd	s0,16(sp)
    80005a80:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005a82:	fe040613          	addi	a2,s0,-32
    80005a86:	fec40593          	addi	a1,s0,-20
    80005a8a:	4501                	li	a0,0
    80005a8c:	00000097          	auipc	ra,0x0
    80005a90:	cc4080e7          	jalr	-828(ra) # 80005750 <argfd>
    return -1;
    80005a94:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a96:	02054463          	bltz	a0,80005abe <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005a9a:	ffffc097          	auipc	ra,0xffffc
    80005a9e:	f28080e7          	jalr	-216(ra) # 800019c2 <myproc>
    80005aa2:	fec42783          	lw	a5,-20(s0)
    80005aa6:	07f9                	addi	a5,a5,30
    80005aa8:	078e                	slli	a5,a5,0x3
    80005aaa:	97aa                	add	a5,a5,a0
    80005aac:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005ab0:	fe043503          	ld	a0,-32(s0)
    80005ab4:	fffff097          	auipc	ra,0xfffff
    80005ab8:	2a2080e7          	jalr	674(ra) # 80004d56 <fileclose>
  return 0;
    80005abc:	4781                	li	a5,0
}
    80005abe:	853e                	mv	a0,a5
    80005ac0:	60e2                	ld	ra,24(sp)
    80005ac2:	6442                	ld	s0,16(sp)
    80005ac4:	6105                	addi	sp,sp,32
    80005ac6:	8082                	ret

0000000080005ac8 <sys_fstat>:
{
    80005ac8:	1101                	addi	sp,sp,-32
    80005aca:	ec06                	sd	ra,24(sp)
    80005acc:	e822                	sd	s0,16(sp)
    80005ace:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ad0:	fe840613          	addi	a2,s0,-24
    80005ad4:	4581                	li	a1,0
    80005ad6:	4501                	li	a0,0
    80005ad8:	00000097          	auipc	ra,0x0
    80005adc:	c78080e7          	jalr	-904(ra) # 80005750 <argfd>
    return -1;
    80005ae0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ae2:	02054563          	bltz	a0,80005b0c <sys_fstat+0x44>
    80005ae6:	fe040593          	addi	a1,s0,-32
    80005aea:	4505                	li	a0,1
    80005aec:	ffffd097          	auipc	ra,0xffffd
    80005af0:	6ae080e7          	jalr	1710(ra) # 8000319a <argaddr>
    return -1;
    80005af4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005af6:	00054b63          	bltz	a0,80005b0c <sys_fstat+0x44>
  return filestat(f, st);
    80005afa:	fe043583          	ld	a1,-32(s0)
    80005afe:	fe843503          	ld	a0,-24(s0)
    80005b02:	fffff097          	auipc	ra,0xfffff
    80005b06:	31c080e7          	jalr	796(ra) # 80004e1e <filestat>
    80005b0a:	87aa                	mv	a5,a0
}
    80005b0c:	853e                	mv	a0,a5
    80005b0e:	60e2                	ld	ra,24(sp)
    80005b10:	6442                	ld	s0,16(sp)
    80005b12:	6105                	addi	sp,sp,32
    80005b14:	8082                	ret

0000000080005b16 <sys_link>:
{
    80005b16:	7169                	addi	sp,sp,-304
    80005b18:	f606                	sd	ra,296(sp)
    80005b1a:	f222                	sd	s0,288(sp)
    80005b1c:	ee26                	sd	s1,280(sp)
    80005b1e:	ea4a                	sd	s2,272(sp)
    80005b20:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b22:	08000613          	li	a2,128
    80005b26:	ed040593          	addi	a1,s0,-304
    80005b2a:	4501                	li	a0,0
    80005b2c:	ffffd097          	auipc	ra,0xffffd
    80005b30:	690080e7          	jalr	1680(ra) # 800031bc <argstr>
    return -1;
    80005b34:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b36:	10054e63          	bltz	a0,80005c52 <sys_link+0x13c>
    80005b3a:	08000613          	li	a2,128
    80005b3e:	f5040593          	addi	a1,s0,-176
    80005b42:	4505                	li	a0,1
    80005b44:	ffffd097          	auipc	ra,0xffffd
    80005b48:	678080e7          	jalr	1656(ra) # 800031bc <argstr>
    return -1;
    80005b4c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b4e:	10054263          	bltz	a0,80005c52 <sys_link+0x13c>
  begin_op();
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	d38080e7          	jalr	-712(ra) # 8000488a <begin_op>
  if((ip = namei(old)) == 0){
    80005b5a:	ed040513          	addi	a0,s0,-304
    80005b5e:	fffff097          	auipc	ra,0xfffff
    80005b62:	b0c080e7          	jalr	-1268(ra) # 8000466a <namei>
    80005b66:	84aa                	mv	s1,a0
    80005b68:	c551                	beqz	a0,80005bf4 <sys_link+0xde>
  ilock(ip);
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	34a080e7          	jalr	842(ra) # 80003eb4 <ilock>
  if(ip->type == T_DIR){
    80005b72:	04449703          	lh	a4,68(s1)
    80005b76:	4785                	li	a5,1
    80005b78:	08f70463          	beq	a4,a5,80005c00 <sys_link+0xea>
  ip->nlink++;
    80005b7c:	04a4d783          	lhu	a5,74(s1)
    80005b80:	2785                	addiw	a5,a5,1
    80005b82:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b86:	8526                	mv	a0,s1
    80005b88:	ffffe097          	auipc	ra,0xffffe
    80005b8c:	262080e7          	jalr	610(ra) # 80003dea <iupdate>
  iunlock(ip);
    80005b90:	8526                	mv	a0,s1
    80005b92:	ffffe097          	auipc	ra,0xffffe
    80005b96:	3e4080e7          	jalr	996(ra) # 80003f76 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b9a:	fd040593          	addi	a1,s0,-48
    80005b9e:	f5040513          	addi	a0,s0,-176
    80005ba2:	fffff097          	auipc	ra,0xfffff
    80005ba6:	ae6080e7          	jalr	-1306(ra) # 80004688 <nameiparent>
    80005baa:	892a                	mv	s2,a0
    80005bac:	c935                	beqz	a0,80005c20 <sys_link+0x10a>
  ilock(dp);
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	306080e7          	jalr	774(ra) # 80003eb4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005bb6:	00092703          	lw	a4,0(s2)
    80005bba:	409c                	lw	a5,0(s1)
    80005bbc:	04f71d63          	bne	a4,a5,80005c16 <sys_link+0x100>
    80005bc0:	40d0                	lw	a2,4(s1)
    80005bc2:	fd040593          	addi	a1,s0,-48
    80005bc6:	854a                	mv	a0,s2
    80005bc8:	fffff097          	auipc	ra,0xfffff
    80005bcc:	9e0080e7          	jalr	-1568(ra) # 800045a8 <dirlink>
    80005bd0:	04054363          	bltz	a0,80005c16 <sys_link+0x100>
  iunlockput(dp);
    80005bd4:	854a                	mv	a0,s2
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	540080e7          	jalr	1344(ra) # 80004116 <iunlockput>
  iput(ip);
    80005bde:	8526                	mv	a0,s1
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	48e080e7          	jalr	1166(ra) # 8000406e <iput>
  end_op();
    80005be8:	fffff097          	auipc	ra,0xfffff
    80005bec:	d22080e7          	jalr	-734(ra) # 8000490a <end_op>
  return 0;
    80005bf0:	4781                	li	a5,0
    80005bf2:	a085                	j	80005c52 <sys_link+0x13c>
    end_op();
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	d16080e7          	jalr	-746(ra) # 8000490a <end_op>
    return -1;
    80005bfc:	57fd                	li	a5,-1
    80005bfe:	a891                	j	80005c52 <sys_link+0x13c>
    iunlockput(ip);
    80005c00:	8526                	mv	a0,s1
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	514080e7          	jalr	1300(ra) # 80004116 <iunlockput>
    end_op();
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	d00080e7          	jalr	-768(ra) # 8000490a <end_op>
    return -1;
    80005c12:	57fd                	li	a5,-1
    80005c14:	a83d                	j	80005c52 <sys_link+0x13c>
    iunlockput(dp);
    80005c16:	854a                	mv	a0,s2
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	4fe080e7          	jalr	1278(ra) # 80004116 <iunlockput>
  ilock(ip);
    80005c20:	8526                	mv	a0,s1
    80005c22:	ffffe097          	auipc	ra,0xffffe
    80005c26:	292080e7          	jalr	658(ra) # 80003eb4 <ilock>
  ip->nlink--;
    80005c2a:	04a4d783          	lhu	a5,74(s1)
    80005c2e:	37fd                	addiw	a5,a5,-1
    80005c30:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c34:	8526                	mv	a0,s1
    80005c36:	ffffe097          	auipc	ra,0xffffe
    80005c3a:	1b4080e7          	jalr	436(ra) # 80003dea <iupdate>
  iunlockput(ip);
    80005c3e:	8526                	mv	a0,s1
    80005c40:	ffffe097          	auipc	ra,0xffffe
    80005c44:	4d6080e7          	jalr	1238(ra) # 80004116 <iunlockput>
  end_op();
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	cc2080e7          	jalr	-830(ra) # 8000490a <end_op>
  return -1;
    80005c50:	57fd                	li	a5,-1
}
    80005c52:	853e                	mv	a0,a5
    80005c54:	70b2                	ld	ra,296(sp)
    80005c56:	7412                	ld	s0,288(sp)
    80005c58:	64f2                	ld	s1,280(sp)
    80005c5a:	6952                	ld	s2,272(sp)
    80005c5c:	6155                	addi	sp,sp,304
    80005c5e:	8082                	ret

0000000080005c60 <sys_unlink>:
{
    80005c60:	7151                	addi	sp,sp,-240
    80005c62:	f586                	sd	ra,232(sp)
    80005c64:	f1a2                	sd	s0,224(sp)
    80005c66:	eda6                	sd	s1,216(sp)
    80005c68:	e9ca                	sd	s2,208(sp)
    80005c6a:	e5ce                	sd	s3,200(sp)
    80005c6c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005c6e:	08000613          	li	a2,128
    80005c72:	f3040593          	addi	a1,s0,-208
    80005c76:	4501                	li	a0,0
    80005c78:	ffffd097          	auipc	ra,0xffffd
    80005c7c:	544080e7          	jalr	1348(ra) # 800031bc <argstr>
    80005c80:	18054163          	bltz	a0,80005e02 <sys_unlink+0x1a2>
  begin_op();
    80005c84:	fffff097          	auipc	ra,0xfffff
    80005c88:	c06080e7          	jalr	-1018(ra) # 8000488a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005c8c:	fb040593          	addi	a1,s0,-80
    80005c90:	f3040513          	addi	a0,s0,-208
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	9f4080e7          	jalr	-1548(ra) # 80004688 <nameiparent>
    80005c9c:	84aa                	mv	s1,a0
    80005c9e:	c979                	beqz	a0,80005d74 <sys_unlink+0x114>
  ilock(dp);
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	214080e7          	jalr	532(ra) # 80003eb4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005ca8:	00003597          	auipc	a1,0x3
    80005cac:	c5058593          	addi	a1,a1,-944 # 800088f8 <syscalls+0x2c8>
    80005cb0:	fb040513          	addi	a0,s0,-80
    80005cb4:	ffffe097          	auipc	ra,0xffffe
    80005cb8:	6ca080e7          	jalr	1738(ra) # 8000437e <namecmp>
    80005cbc:	14050a63          	beqz	a0,80005e10 <sys_unlink+0x1b0>
    80005cc0:	00003597          	auipc	a1,0x3
    80005cc4:	c4058593          	addi	a1,a1,-960 # 80008900 <syscalls+0x2d0>
    80005cc8:	fb040513          	addi	a0,s0,-80
    80005ccc:	ffffe097          	auipc	ra,0xffffe
    80005cd0:	6b2080e7          	jalr	1714(ra) # 8000437e <namecmp>
    80005cd4:	12050e63          	beqz	a0,80005e10 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005cd8:	f2c40613          	addi	a2,s0,-212
    80005cdc:	fb040593          	addi	a1,s0,-80
    80005ce0:	8526                	mv	a0,s1
    80005ce2:	ffffe097          	auipc	ra,0xffffe
    80005ce6:	6b6080e7          	jalr	1718(ra) # 80004398 <dirlookup>
    80005cea:	892a                	mv	s2,a0
    80005cec:	12050263          	beqz	a0,80005e10 <sys_unlink+0x1b0>
  ilock(ip);
    80005cf0:	ffffe097          	auipc	ra,0xffffe
    80005cf4:	1c4080e7          	jalr	452(ra) # 80003eb4 <ilock>
  if(ip->nlink < 1)
    80005cf8:	04a91783          	lh	a5,74(s2)
    80005cfc:	08f05263          	blez	a5,80005d80 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005d00:	04491703          	lh	a4,68(s2)
    80005d04:	4785                	li	a5,1
    80005d06:	08f70563          	beq	a4,a5,80005d90 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005d0a:	4641                	li	a2,16
    80005d0c:	4581                	li	a1,0
    80005d0e:	fc040513          	addi	a0,s0,-64
    80005d12:	ffffb097          	auipc	ra,0xffffb
    80005d16:	fac080e7          	jalr	-84(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d1a:	4741                	li	a4,16
    80005d1c:	f2c42683          	lw	a3,-212(s0)
    80005d20:	fc040613          	addi	a2,s0,-64
    80005d24:	4581                	li	a1,0
    80005d26:	8526                	mv	a0,s1
    80005d28:	ffffe097          	auipc	ra,0xffffe
    80005d2c:	538080e7          	jalr	1336(ra) # 80004260 <writei>
    80005d30:	47c1                	li	a5,16
    80005d32:	0af51563          	bne	a0,a5,80005ddc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005d36:	04491703          	lh	a4,68(s2)
    80005d3a:	4785                	li	a5,1
    80005d3c:	0af70863          	beq	a4,a5,80005dec <sys_unlink+0x18c>
  iunlockput(dp);
    80005d40:	8526                	mv	a0,s1
    80005d42:	ffffe097          	auipc	ra,0xffffe
    80005d46:	3d4080e7          	jalr	980(ra) # 80004116 <iunlockput>
  ip->nlink--;
    80005d4a:	04a95783          	lhu	a5,74(s2)
    80005d4e:	37fd                	addiw	a5,a5,-1
    80005d50:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005d54:	854a                	mv	a0,s2
    80005d56:	ffffe097          	auipc	ra,0xffffe
    80005d5a:	094080e7          	jalr	148(ra) # 80003dea <iupdate>
  iunlockput(ip);
    80005d5e:	854a                	mv	a0,s2
    80005d60:	ffffe097          	auipc	ra,0xffffe
    80005d64:	3b6080e7          	jalr	950(ra) # 80004116 <iunlockput>
  end_op();
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	ba2080e7          	jalr	-1118(ra) # 8000490a <end_op>
  return 0;
    80005d70:	4501                	li	a0,0
    80005d72:	a84d                	j	80005e24 <sys_unlink+0x1c4>
    end_op();
    80005d74:	fffff097          	auipc	ra,0xfffff
    80005d78:	b96080e7          	jalr	-1130(ra) # 8000490a <end_op>
    return -1;
    80005d7c:	557d                	li	a0,-1
    80005d7e:	a05d                	j	80005e24 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005d80:	00003517          	auipc	a0,0x3
    80005d84:	ba850513          	addi	a0,a0,-1112 # 80008928 <syscalls+0x2f8>
    80005d88:	ffffa097          	auipc	ra,0xffffa
    80005d8c:	7a2080e7          	jalr	1954(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d90:	04c92703          	lw	a4,76(s2)
    80005d94:	02000793          	li	a5,32
    80005d98:	f6e7f9e3          	bgeu	a5,a4,80005d0a <sys_unlink+0xaa>
    80005d9c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005da0:	4741                	li	a4,16
    80005da2:	86ce                	mv	a3,s3
    80005da4:	f1840613          	addi	a2,s0,-232
    80005da8:	4581                	li	a1,0
    80005daa:	854a                	mv	a0,s2
    80005dac:	ffffe097          	auipc	ra,0xffffe
    80005db0:	3bc080e7          	jalr	956(ra) # 80004168 <readi>
    80005db4:	47c1                	li	a5,16
    80005db6:	00f51b63          	bne	a0,a5,80005dcc <sys_unlink+0x16c>
    if(de.inum != 0)
    80005dba:	f1845783          	lhu	a5,-232(s0)
    80005dbe:	e7a1                	bnez	a5,80005e06 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005dc0:	29c1                	addiw	s3,s3,16
    80005dc2:	04c92783          	lw	a5,76(s2)
    80005dc6:	fcf9ede3          	bltu	s3,a5,80005da0 <sys_unlink+0x140>
    80005dca:	b781                	j	80005d0a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005dcc:	00003517          	auipc	a0,0x3
    80005dd0:	b7450513          	addi	a0,a0,-1164 # 80008940 <syscalls+0x310>
    80005dd4:	ffffa097          	auipc	ra,0xffffa
    80005dd8:	756080e7          	jalr	1878(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005ddc:	00003517          	auipc	a0,0x3
    80005de0:	b7c50513          	addi	a0,a0,-1156 # 80008958 <syscalls+0x328>
    80005de4:	ffffa097          	auipc	ra,0xffffa
    80005de8:	746080e7          	jalr	1862(ra) # 8000052a <panic>
    dp->nlink--;
    80005dec:	04a4d783          	lhu	a5,74(s1)
    80005df0:	37fd                	addiw	a5,a5,-1
    80005df2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005df6:	8526                	mv	a0,s1
    80005df8:	ffffe097          	auipc	ra,0xffffe
    80005dfc:	ff2080e7          	jalr	-14(ra) # 80003dea <iupdate>
    80005e00:	b781                	j	80005d40 <sys_unlink+0xe0>
    return -1;
    80005e02:	557d                	li	a0,-1
    80005e04:	a005                	j	80005e24 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005e06:	854a                	mv	a0,s2
    80005e08:	ffffe097          	auipc	ra,0xffffe
    80005e0c:	30e080e7          	jalr	782(ra) # 80004116 <iunlockput>
  iunlockput(dp);
    80005e10:	8526                	mv	a0,s1
    80005e12:	ffffe097          	auipc	ra,0xffffe
    80005e16:	304080e7          	jalr	772(ra) # 80004116 <iunlockput>
  end_op();
    80005e1a:	fffff097          	auipc	ra,0xfffff
    80005e1e:	af0080e7          	jalr	-1296(ra) # 8000490a <end_op>
  return -1;
    80005e22:	557d                	li	a0,-1
}
    80005e24:	70ae                	ld	ra,232(sp)
    80005e26:	740e                	ld	s0,224(sp)
    80005e28:	64ee                	ld	s1,216(sp)
    80005e2a:	694e                	ld	s2,208(sp)
    80005e2c:	69ae                	ld	s3,200(sp)
    80005e2e:	616d                	addi	sp,sp,240
    80005e30:	8082                	ret

0000000080005e32 <sys_open>:

uint64
sys_open(void)
{
    80005e32:	7131                	addi	sp,sp,-192
    80005e34:	fd06                	sd	ra,184(sp)
    80005e36:	f922                	sd	s0,176(sp)
    80005e38:	f526                	sd	s1,168(sp)
    80005e3a:	f14a                	sd	s2,160(sp)
    80005e3c:	ed4e                	sd	s3,152(sp)
    80005e3e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005e40:	08000613          	li	a2,128
    80005e44:	f5040593          	addi	a1,s0,-176
    80005e48:	4501                	li	a0,0
    80005e4a:	ffffd097          	auipc	ra,0xffffd
    80005e4e:	372080e7          	jalr	882(ra) # 800031bc <argstr>
    return -1;
    80005e52:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005e54:	0c054163          	bltz	a0,80005f16 <sys_open+0xe4>
    80005e58:	f4c40593          	addi	a1,s0,-180
    80005e5c:	4505                	li	a0,1
    80005e5e:	ffffd097          	auipc	ra,0xffffd
    80005e62:	31a080e7          	jalr	794(ra) # 80003178 <argint>
    80005e66:	0a054863          	bltz	a0,80005f16 <sys_open+0xe4>

  begin_op();
    80005e6a:	fffff097          	auipc	ra,0xfffff
    80005e6e:	a20080e7          	jalr	-1504(ra) # 8000488a <begin_op>

  if(omode & O_CREATE){
    80005e72:	f4c42783          	lw	a5,-180(s0)
    80005e76:	2007f793          	andi	a5,a5,512
    80005e7a:	cbdd                	beqz	a5,80005f30 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005e7c:	4681                	li	a3,0
    80005e7e:	4601                	li	a2,0
    80005e80:	4589                	li	a1,2
    80005e82:	f5040513          	addi	a0,s0,-176
    80005e86:	00000097          	auipc	ra,0x0
    80005e8a:	974080e7          	jalr	-1676(ra) # 800057fa <create>
    80005e8e:	892a                	mv	s2,a0
    if(ip == 0){
    80005e90:	c959                	beqz	a0,80005f26 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e92:	04491703          	lh	a4,68(s2)
    80005e96:	478d                	li	a5,3
    80005e98:	00f71763          	bne	a4,a5,80005ea6 <sys_open+0x74>
    80005e9c:	04695703          	lhu	a4,70(s2)
    80005ea0:	47a5                	li	a5,9
    80005ea2:	0ce7ec63          	bltu	a5,a4,80005f7a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ea6:	fffff097          	auipc	ra,0xfffff
    80005eaa:	df4080e7          	jalr	-524(ra) # 80004c9a <filealloc>
    80005eae:	89aa                	mv	s3,a0
    80005eb0:	10050263          	beqz	a0,80005fb4 <sys_open+0x182>
    80005eb4:	00000097          	auipc	ra,0x0
    80005eb8:	904080e7          	jalr	-1788(ra) # 800057b8 <fdalloc>
    80005ebc:	84aa                	mv	s1,a0
    80005ebe:	0e054663          	bltz	a0,80005faa <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005ec2:	04491703          	lh	a4,68(s2)
    80005ec6:	478d                	li	a5,3
    80005ec8:	0cf70463          	beq	a4,a5,80005f90 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ecc:	4789                	li	a5,2
    80005ece:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ed2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ed6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005eda:	f4c42783          	lw	a5,-180(s0)
    80005ede:	0017c713          	xori	a4,a5,1
    80005ee2:	8b05                	andi	a4,a4,1
    80005ee4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ee8:	0037f713          	andi	a4,a5,3
    80005eec:	00e03733          	snez	a4,a4
    80005ef0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ef4:	4007f793          	andi	a5,a5,1024
    80005ef8:	c791                	beqz	a5,80005f04 <sys_open+0xd2>
    80005efa:	04491703          	lh	a4,68(s2)
    80005efe:	4789                	li	a5,2
    80005f00:	08f70f63          	beq	a4,a5,80005f9e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005f04:	854a                	mv	a0,s2
    80005f06:	ffffe097          	auipc	ra,0xffffe
    80005f0a:	070080e7          	jalr	112(ra) # 80003f76 <iunlock>
  end_op();
    80005f0e:	fffff097          	auipc	ra,0xfffff
    80005f12:	9fc080e7          	jalr	-1540(ra) # 8000490a <end_op>

  return fd;
}
    80005f16:	8526                	mv	a0,s1
    80005f18:	70ea                	ld	ra,184(sp)
    80005f1a:	744a                	ld	s0,176(sp)
    80005f1c:	74aa                	ld	s1,168(sp)
    80005f1e:	790a                	ld	s2,160(sp)
    80005f20:	69ea                	ld	s3,152(sp)
    80005f22:	6129                	addi	sp,sp,192
    80005f24:	8082                	ret
      end_op();
    80005f26:	fffff097          	auipc	ra,0xfffff
    80005f2a:	9e4080e7          	jalr	-1564(ra) # 8000490a <end_op>
      return -1;
    80005f2e:	b7e5                	j	80005f16 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005f30:	f5040513          	addi	a0,s0,-176
    80005f34:	ffffe097          	auipc	ra,0xffffe
    80005f38:	736080e7          	jalr	1846(ra) # 8000466a <namei>
    80005f3c:	892a                	mv	s2,a0
    80005f3e:	c905                	beqz	a0,80005f6e <sys_open+0x13c>
    ilock(ip);
    80005f40:	ffffe097          	auipc	ra,0xffffe
    80005f44:	f74080e7          	jalr	-140(ra) # 80003eb4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005f48:	04491703          	lh	a4,68(s2)
    80005f4c:	4785                	li	a5,1
    80005f4e:	f4f712e3          	bne	a4,a5,80005e92 <sys_open+0x60>
    80005f52:	f4c42783          	lw	a5,-180(s0)
    80005f56:	dba1                	beqz	a5,80005ea6 <sys_open+0x74>
      iunlockput(ip);
    80005f58:	854a                	mv	a0,s2
    80005f5a:	ffffe097          	auipc	ra,0xffffe
    80005f5e:	1bc080e7          	jalr	444(ra) # 80004116 <iunlockput>
      end_op();
    80005f62:	fffff097          	auipc	ra,0xfffff
    80005f66:	9a8080e7          	jalr	-1624(ra) # 8000490a <end_op>
      return -1;
    80005f6a:	54fd                	li	s1,-1
    80005f6c:	b76d                	j	80005f16 <sys_open+0xe4>
      end_op();
    80005f6e:	fffff097          	auipc	ra,0xfffff
    80005f72:	99c080e7          	jalr	-1636(ra) # 8000490a <end_op>
      return -1;
    80005f76:	54fd                	li	s1,-1
    80005f78:	bf79                	j	80005f16 <sys_open+0xe4>
    iunlockput(ip);
    80005f7a:	854a                	mv	a0,s2
    80005f7c:	ffffe097          	auipc	ra,0xffffe
    80005f80:	19a080e7          	jalr	410(ra) # 80004116 <iunlockput>
    end_op();
    80005f84:	fffff097          	auipc	ra,0xfffff
    80005f88:	986080e7          	jalr	-1658(ra) # 8000490a <end_op>
    return -1;
    80005f8c:	54fd                	li	s1,-1
    80005f8e:	b761                	j	80005f16 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005f90:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005f94:	04691783          	lh	a5,70(s2)
    80005f98:	02f99223          	sh	a5,36(s3)
    80005f9c:	bf2d                	j	80005ed6 <sys_open+0xa4>
    itrunc(ip);
    80005f9e:	854a                	mv	a0,s2
    80005fa0:	ffffe097          	auipc	ra,0xffffe
    80005fa4:	022080e7          	jalr	34(ra) # 80003fc2 <itrunc>
    80005fa8:	bfb1                	j	80005f04 <sys_open+0xd2>
      fileclose(f);
    80005faa:	854e                	mv	a0,s3
    80005fac:	fffff097          	auipc	ra,0xfffff
    80005fb0:	daa080e7          	jalr	-598(ra) # 80004d56 <fileclose>
    iunlockput(ip);
    80005fb4:	854a                	mv	a0,s2
    80005fb6:	ffffe097          	auipc	ra,0xffffe
    80005fba:	160080e7          	jalr	352(ra) # 80004116 <iunlockput>
    end_op();
    80005fbe:	fffff097          	auipc	ra,0xfffff
    80005fc2:	94c080e7          	jalr	-1716(ra) # 8000490a <end_op>
    return -1;
    80005fc6:	54fd                	li	s1,-1
    80005fc8:	b7b9                	j	80005f16 <sys_open+0xe4>

0000000080005fca <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005fca:	7175                	addi	sp,sp,-144
    80005fcc:	e506                	sd	ra,136(sp)
    80005fce:	e122                	sd	s0,128(sp)
    80005fd0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005fd2:	fffff097          	auipc	ra,0xfffff
    80005fd6:	8b8080e7          	jalr	-1864(ra) # 8000488a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005fda:	08000613          	li	a2,128
    80005fde:	f7040593          	addi	a1,s0,-144
    80005fe2:	4501                	li	a0,0
    80005fe4:	ffffd097          	auipc	ra,0xffffd
    80005fe8:	1d8080e7          	jalr	472(ra) # 800031bc <argstr>
    80005fec:	02054963          	bltz	a0,8000601e <sys_mkdir+0x54>
    80005ff0:	4681                	li	a3,0
    80005ff2:	4601                	li	a2,0
    80005ff4:	4585                	li	a1,1
    80005ff6:	f7040513          	addi	a0,s0,-144
    80005ffa:	00000097          	auipc	ra,0x0
    80005ffe:	800080e7          	jalr	-2048(ra) # 800057fa <create>
    80006002:	cd11                	beqz	a0,8000601e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006004:	ffffe097          	auipc	ra,0xffffe
    80006008:	112080e7          	jalr	274(ra) # 80004116 <iunlockput>
  end_op();
    8000600c:	fffff097          	auipc	ra,0xfffff
    80006010:	8fe080e7          	jalr	-1794(ra) # 8000490a <end_op>
  return 0;
    80006014:	4501                	li	a0,0
}
    80006016:	60aa                	ld	ra,136(sp)
    80006018:	640a                	ld	s0,128(sp)
    8000601a:	6149                	addi	sp,sp,144
    8000601c:	8082                	ret
    end_op();
    8000601e:	fffff097          	auipc	ra,0xfffff
    80006022:	8ec080e7          	jalr	-1812(ra) # 8000490a <end_op>
    return -1;
    80006026:	557d                	li	a0,-1
    80006028:	b7fd                	j	80006016 <sys_mkdir+0x4c>

000000008000602a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000602a:	7135                	addi	sp,sp,-160
    8000602c:	ed06                	sd	ra,152(sp)
    8000602e:	e922                	sd	s0,144(sp)
    80006030:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006032:	fffff097          	auipc	ra,0xfffff
    80006036:	858080e7          	jalr	-1960(ra) # 8000488a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000603a:	08000613          	li	a2,128
    8000603e:	f7040593          	addi	a1,s0,-144
    80006042:	4501                	li	a0,0
    80006044:	ffffd097          	auipc	ra,0xffffd
    80006048:	178080e7          	jalr	376(ra) # 800031bc <argstr>
    8000604c:	04054a63          	bltz	a0,800060a0 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006050:	f6c40593          	addi	a1,s0,-148
    80006054:	4505                	li	a0,1
    80006056:	ffffd097          	auipc	ra,0xffffd
    8000605a:	122080e7          	jalr	290(ra) # 80003178 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000605e:	04054163          	bltz	a0,800060a0 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006062:	f6840593          	addi	a1,s0,-152
    80006066:	4509                	li	a0,2
    80006068:	ffffd097          	auipc	ra,0xffffd
    8000606c:	110080e7          	jalr	272(ra) # 80003178 <argint>
     argint(1, &major) < 0 ||
    80006070:	02054863          	bltz	a0,800060a0 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006074:	f6841683          	lh	a3,-152(s0)
    80006078:	f6c41603          	lh	a2,-148(s0)
    8000607c:	458d                	li	a1,3
    8000607e:	f7040513          	addi	a0,s0,-144
    80006082:	fffff097          	auipc	ra,0xfffff
    80006086:	778080e7          	jalr	1912(ra) # 800057fa <create>
     argint(2, &minor) < 0 ||
    8000608a:	c919                	beqz	a0,800060a0 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000608c:	ffffe097          	auipc	ra,0xffffe
    80006090:	08a080e7          	jalr	138(ra) # 80004116 <iunlockput>
  end_op();
    80006094:	fffff097          	auipc	ra,0xfffff
    80006098:	876080e7          	jalr	-1930(ra) # 8000490a <end_op>
  return 0;
    8000609c:	4501                	li	a0,0
    8000609e:	a031                	j	800060aa <sys_mknod+0x80>
    end_op();
    800060a0:	fffff097          	auipc	ra,0xfffff
    800060a4:	86a080e7          	jalr	-1942(ra) # 8000490a <end_op>
    return -1;
    800060a8:	557d                	li	a0,-1
}
    800060aa:	60ea                	ld	ra,152(sp)
    800060ac:	644a                	ld	s0,144(sp)
    800060ae:	610d                	addi	sp,sp,160
    800060b0:	8082                	ret

00000000800060b2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800060b2:	7135                	addi	sp,sp,-160
    800060b4:	ed06                	sd	ra,152(sp)
    800060b6:	e922                	sd	s0,144(sp)
    800060b8:	e526                	sd	s1,136(sp)
    800060ba:	e14a                	sd	s2,128(sp)
    800060bc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800060be:	ffffc097          	auipc	ra,0xffffc
    800060c2:	904080e7          	jalr	-1788(ra) # 800019c2 <myproc>
    800060c6:	892a                	mv	s2,a0
  
  begin_op();
    800060c8:	ffffe097          	auipc	ra,0xffffe
    800060cc:	7c2080e7          	jalr	1986(ra) # 8000488a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800060d0:	08000613          	li	a2,128
    800060d4:	f6040593          	addi	a1,s0,-160
    800060d8:	4501                	li	a0,0
    800060da:	ffffd097          	auipc	ra,0xffffd
    800060de:	0e2080e7          	jalr	226(ra) # 800031bc <argstr>
    800060e2:	04054b63          	bltz	a0,80006138 <sys_chdir+0x86>
    800060e6:	f6040513          	addi	a0,s0,-160
    800060ea:	ffffe097          	auipc	ra,0xffffe
    800060ee:	580080e7          	jalr	1408(ra) # 8000466a <namei>
    800060f2:	84aa                	mv	s1,a0
    800060f4:	c131                	beqz	a0,80006138 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800060f6:	ffffe097          	auipc	ra,0xffffe
    800060fa:	dbe080e7          	jalr	-578(ra) # 80003eb4 <ilock>
  if(ip->type != T_DIR){
    800060fe:	04449703          	lh	a4,68(s1)
    80006102:	4785                	li	a5,1
    80006104:	04f71063          	bne	a4,a5,80006144 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006108:	8526                	mv	a0,s1
    8000610a:	ffffe097          	auipc	ra,0xffffe
    8000610e:	e6c080e7          	jalr	-404(ra) # 80003f76 <iunlock>
  iput(p->cwd);
    80006112:	17893503          	ld	a0,376(s2)
    80006116:	ffffe097          	auipc	ra,0xffffe
    8000611a:	f58080e7          	jalr	-168(ra) # 8000406e <iput>
  end_op();
    8000611e:	ffffe097          	auipc	ra,0xffffe
    80006122:	7ec080e7          	jalr	2028(ra) # 8000490a <end_op>
  p->cwd = ip;
    80006126:	16993c23          	sd	s1,376(s2)
  return 0;
    8000612a:	4501                	li	a0,0
}
    8000612c:	60ea                	ld	ra,152(sp)
    8000612e:	644a                	ld	s0,144(sp)
    80006130:	64aa                	ld	s1,136(sp)
    80006132:	690a                	ld	s2,128(sp)
    80006134:	610d                	addi	sp,sp,160
    80006136:	8082                	ret
    end_op();
    80006138:	ffffe097          	auipc	ra,0xffffe
    8000613c:	7d2080e7          	jalr	2002(ra) # 8000490a <end_op>
    return -1;
    80006140:	557d                	li	a0,-1
    80006142:	b7ed                	j	8000612c <sys_chdir+0x7a>
    iunlockput(ip);
    80006144:	8526                	mv	a0,s1
    80006146:	ffffe097          	auipc	ra,0xffffe
    8000614a:	fd0080e7          	jalr	-48(ra) # 80004116 <iunlockput>
    end_op();
    8000614e:	ffffe097          	auipc	ra,0xffffe
    80006152:	7bc080e7          	jalr	1980(ra) # 8000490a <end_op>
    return -1;
    80006156:	557d                	li	a0,-1
    80006158:	bfd1                	j	8000612c <sys_chdir+0x7a>

000000008000615a <sys_exec>:

uint64
sys_exec(void)
{
    8000615a:	7145                	addi	sp,sp,-464
    8000615c:	e786                	sd	ra,456(sp)
    8000615e:	e3a2                	sd	s0,448(sp)
    80006160:	ff26                	sd	s1,440(sp)
    80006162:	fb4a                	sd	s2,432(sp)
    80006164:	f74e                	sd	s3,424(sp)
    80006166:	f352                	sd	s4,416(sp)
    80006168:	ef56                	sd	s5,408(sp)
    8000616a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000616c:	08000613          	li	a2,128
    80006170:	f4040593          	addi	a1,s0,-192
    80006174:	4501                	li	a0,0
    80006176:	ffffd097          	auipc	ra,0xffffd
    8000617a:	046080e7          	jalr	70(ra) # 800031bc <argstr>
    return -1;
    8000617e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006180:	0c054a63          	bltz	a0,80006254 <sys_exec+0xfa>
    80006184:	e3840593          	addi	a1,s0,-456
    80006188:	4505                	li	a0,1
    8000618a:	ffffd097          	auipc	ra,0xffffd
    8000618e:	010080e7          	jalr	16(ra) # 8000319a <argaddr>
    80006192:	0c054163          	bltz	a0,80006254 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006196:	10000613          	li	a2,256
    8000619a:	4581                	li	a1,0
    8000619c:	e4040513          	addi	a0,s0,-448
    800061a0:	ffffb097          	auipc	ra,0xffffb
    800061a4:	b1e080e7          	jalr	-1250(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800061a8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800061ac:	89a6                	mv	s3,s1
    800061ae:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800061b0:	02000a13          	li	s4,32
    800061b4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800061b8:	00391793          	slli	a5,s2,0x3
    800061bc:	e3040593          	addi	a1,s0,-464
    800061c0:	e3843503          	ld	a0,-456(s0)
    800061c4:	953e                	add	a0,a0,a5
    800061c6:	ffffd097          	auipc	ra,0xffffd
    800061ca:	f18080e7          	jalr	-232(ra) # 800030de <fetchaddr>
    800061ce:	02054a63          	bltz	a0,80006202 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800061d2:	e3043783          	ld	a5,-464(s0)
    800061d6:	c3b9                	beqz	a5,8000621c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800061d8:	ffffb097          	auipc	ra,0xffffb
    800061dc:	8fa080e7          	jalr	-1798(ra) # 80000ad2 <kalloc>
    800061e0:	85aa                	mv	a1,a0
    800061e2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800061e6:	cd11                	beqz	a0,80006202 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800061e8:	6605                	lui	a2,0x1
    800061ea:	e3043503          	ld	a0,-464(s0)
    800061ee:	ffffd097          	auipc	ra,0xffffd
    800061f2:	f42080e7          	jalr	-190(ra) # 80003130 <fetchstr>
    800061f6:	00054663          	bltz	a0,80006202 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800061fa:	0905                	addi	s2,s2,1
    800061fc:	09a1                	addi	s3,s3,8
    800061fe:	fb491be3          	bne	s2,s4,800061b4 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006202:	10048913          	addi	s2,s1,256
    80006206:	6088                	ld	a0,0(s1)
    80006208:	c529                	beqz	a0,80006252 <sys_exec+0xf8>
    kfree(argv[i]);
    8000620a:	ffffa097          	auipc	ra,0xffffa
    8000620e:	7cc080e7          	jalr	1996(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006212:	04a1                	addi	s1,s1,8
    80006214:	ff2499e3          	bne	s1,s2,80006206 <sys_exec+0xac>
  return -1;
    80006218:	597d                	li	s2,-1
    8000621a:	a82d                	j	80006254 <sys_exec+0xfa>
      argv[i] = 0;
    8000621c:	0a8e                	slli	s5,s5,0x3
    8000621e:	fc040793          	addi	a5,s0,-64
    80006222:	9abe                	add	s5,s5,a5
    80006224:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80006228:	e4040593          	addi	a1,s0,-448
    8000622c:	f4040513          	addi	a0,s0,-192
    80006230:	fffff097          	auipc	ra,0xfffff
    80006234:	178080e7          	jalr	376(ra) # 800053a8 <exec>
    80006238:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000623a:	10048993          	addi	s3,s1,256
    8000623e:	6088                	ld	a0,0(s1)
    80006240:	c911                	beqz	a0,80006254 <sys_exec+0xfa>
    kfree(argv[i]);
    80006242:	ffffa097          	auipc	ra,0xffffa
    80006246:	794080e7          	jalr	1940(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000624a:	04a1                	addi	s1,s1,8
    8000624c:	ff3499e3          	bne	s1,s3,8000623e <sys_exec+0xe4>
    80006250:	a011                	j	80006254 <sys_exec+0xfa>
  return -1;
    80006252:	597d                	li	s2,-1
}
    80006254:	854a                	mv	a0,s2
    80006256:	60be                	ld	ra,456(sp)
    80006258:	641e                	ld	s0,448(sp)
    8000625a:	74fa                	ld	s1,440(sp)
    8000625c:	795a                	ld	s2,432(sp)
    8000625e:	79ba                	ld	s3,424(sp)
    80006260:	7a1a                	ld	s4,416(sp)
    80006262:	6afa                	ld	s5,408(sp)
    80006264:	6179                	addi	sp,sp,464
    80006266:	8082                	ret

0000000080006268 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006268:	7139                	addi	sp,sp,-64
    8000626a:	fc06                	sd	ra,56(sp)
    8000626c:	f822                	sd	s0,48(sp)
    8000626e:	f426                	sd	s1,40(sp)
    80006270:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006272:	ffffb097          	auipc	ra,0xffffb
    80006276:	750080e7          	jalr	1872(ra) # 800019c2 <myproc>
    8000627a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000627c:	fd840593          	addi	a1,s0,-40
    80006280:	4501                	li	a0,0
    80006282:	ffffd097          	auipc	ra,0xffffd
    80006286:	f18080e7          	jalr	-232(ra) # 8000319a <argaddr>
    return -1;
    8000628a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000628c:	0e054063          	bltz	a0,8000636c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006290:	fc840593          	addi	a1,s0,-56
    80006294:	fd040513          	addi	a0,s0,-48
    80006298:	fffff097          	auipc	ra,0xfffff
    8000629c:	dee080e7          	jalr	-530(ra) # 80005086 <pipealloc>
    return -1;
    800062a0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800062a2:	0c054563          	bltz	a0,8000636c <sys_pipe+0x104>
  fd0 = -1;
    800062a6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800062aa:	fd043503          	ld	a0,-48(s0)
    800062ae:	fffff097          	auipc	ra,0xfffff
    800062b2:	50a080e7          	jalr	1290(ra) # 800057b8 <fdalloc>
    800062b6:	fca42223          	sw	a0,-60(s0)
    800062ba:	08054c63          	bltz	a0,80006352 <sys_pipe+0xea>
    800062be:	fc843503          	ld	a0,-56(s0)
    800062c2:	fffff097          	auipc	ra,0xfffff
    800062c6:	4f6080e7          	jalr	1270(ra) # 800057b8 <fdalloc>
    800062ca:	fca42023          	sw	a0,-64(s0)
    800062ce:	06054863          	bltz	a0,8000633e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800062d2:	4691                	li	a3,4
    800062d4:	fc440613          	addi	a2,s0,-60
    800062d8:	fd843583          	ld	a1,-40(s0)
    800062dc:	7ca8                	ld	a0,120(s1)
    800062de:	ffffb097          	auipc	ra,0xffffb
    800062e2:	360080e7          	jalr	864(ra) # 8000163e <copyout>
    800062e6:	02054063          	bltz	a0,80006306 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800062ea:	4691                	li	a3,4
    800062ec:	fc040613          	addi	a2,s0,-64
    800062f0:	fd843583          	ld	a1,-40(s0)
    800062f4:	0591                	addi	a1,a1,4
    800062f6:	7ca8                	ld	a0,120(s1)
    800062f8:	ffffb097          	auipc	ra,0xffffb
    800062fc:	346080e7          	jalr	838(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006300:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006302:	06055563          	bgez	a0,8000636c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006306:	fc442783          	lw	a5,-60(s0)
    8000630a:	07f9                	addi	a5,a5,30
    8000630c:	078e                	slli	a5,a5,0x3
    8000630e:	97a6                	add	a5,a5,s1
    80006310:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006314:	fc042503          	lw	a0,-64(s0)
    80006318:	0579                	addi	a0,a0,30
    8000631a:	050e                	slli	a0,a0,0x3
    8000631c:	9526                	add	a0,a0,s1
    8000631e:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006322:	fd043503          	ld	a0,-48(s0)
    80006326:	fffff097          	auipc	ra,0xfffff
    8000632a:	a30080e7          	jalr	-1488(ra) # 80004d56 <fileclose>
    fileclose(wf);
    8000632e:	fc843503          	ld	a0,-56(s0)
    80006332:	fffff097          	auipc	ra,0xfffff
    80006336:	a24080e7          	jalr	-1500(ra) # 80004d56 <fileclose>
    return -1;
    8000633a:	57fd                	li	a5,-1
    8000633c:	a805                	j	8000636c <sys_pipe+0x104>
    if(fd0 >= 0)
    8000633e:	fc442783          	lw	a5,-60(s0)
    80006342:	0007c863          	bltz	a5,80006352 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006346:	01e78513          	addi	a0,a5,30
    8000634a:	050e                	slli	a0,a0,0x3
    8000634c:	9526                	add	a0,a0,s1
    8000634e:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006352:	fd043503          	ld	a0,-48(s0)
    80006356:	fffff097          	auipc	ra,0xfffff
    8000635a:	a00080e7          	jalr	-1536(ra) # 80004d56 <fileclose>
    fileclose(wf);
    8000635e:	fc843503          	ld	a0,-56(s0)
    80006362:	fffff097          	auipc	ra,0xfffff
    80006366:	9f4080e7          	jalr	-1548(ra) # 80004d56 <fileclose>
    return -1;
    8000636a:	57fd                	li	a5,-1
}
    8000636c:	853e                	mv	a0,a5
    8000636e:	70e2                	ld	ra,56(sp)
    80006370:	7442                	ld	s0,48(sp)
    80006372:	74a2                	ld	s1,40(sp)
    80006374:	6121                	addi	sp,sp,64
    80006376:	8082                	ret
	...

0000000080006380 <kernelvec>:
    80006380:	7111                	addi	sp,sp,-256
    80006382:	e006                	sd	ra,0(sp)
    80006384:	e40a                	sd	sp,8(sp)
    80006386:	e80e                	sd	gp,16(sp)
    80006388:	ec12                	sd	tp,24(sp)
    8000638a:	f016                	sd	t0,32(sp)
    8000638c:	f41a                	sd	t1,40(sp)
    8000638e:	f81e                	sd	t2,48(sp)
    80006390:	fc22                	sd	s0,56(sp)
    80006392:	e0a6                	sd	s1,64(sp)
    80006394:	e4aa                	sd	a0,72(sp)
    80006396:	e8ae                	sd	a1,80(sp)
    80006398:	ecb2                	sd	a2,88(sp)
    8000639a:	f0b6                	sd	a3,96(sp)
    8000639c:	f4ba                	sd	a4,104(sp)
    8000639e:	f8be                	sd	a5,112(sp)
    800063a0:	fcc2                	sd	a6,120(sp)
    800063a2:	e146                	sd	a7,128(sp)
    800063a4:	e54a                	sd	s2,136(sp)
    800063a6:	e94e                	sd	s3,144(sp)
    800063a8:	ed52                	sd	s4,152(sp)
    800063aa:	f156                	sd	s5,160(sp)
    800063ac:	f55a                	sd	s6,168(sp)
    800063ae:	f95e                	sd	s7,176(sp)
    800063b0:	fd62                	sd	s8,184(sp)
    800063b2:	e1e6                	sd	s9,192(sp)
    800063b4:	e5ea                	sd	s10,200(sp)
    800063b6:	e9ee                	sd	s11,208(sp)
    800063b8:	edf2                	sd	t3,216(sp)
    800063ba:	f1f6                	sd	t4,224(sp)
    800063bc:	f5fa                	sd	t5,232(sp)
    800063be:	f9fe                	sd	t6,240(sp)
    800063c0:	bdbfc0ef          	jal	ra,80002f9a <kerneltrap>
    800063c4:	6082                	ld	ra,0(sp)
    800063c6:	6122                	ld	sp,8(sp)
    800063c8:	61c2                	ld	gp,16(sp)
    800063ca:	7282                	ld	t0,32(sp)
    800063cc:	7322                	ld	t1,40(sp)
    800063ce:	73c2                	ld	t2,48(sp)
    800063d0:	7462                	ld	s0,56(sp)
    800063d2:	6486                	ld	s1,64(sp)
    800063d4:	6526                	ld	a0,72(sp)
    800063d6:	65c6                	ld	a1,80(sp)
    800063d8:	6666                	ld	a2,88(sp)
    800063da:	7686                	ld	a3,96(sp)
    800063dc:	7726                	ld	a4,104(sp)
    800063de:	77c6                	ld	a5,112(sp)
    800063e0:	7866                	ld	a6,120(sp)
    800063e2:	688a                	ld	a7,128(sp)
    800063e4:	692a                	ld	s2,136(sp)
    800063e6:	69ca                	ld	s3,144(sp)
    800063e8:	6a6a                	ld	s4,152(sp)
    800063ea:	7a8a                	ld	s5,160(sp)
    800063ec:	7b2a                	ld	s6,168(sp)
    800063ee:	7bca                	ld	s7,176(sp)
    800063f0:	7c6a                	ld	s8,184(sp)
    800063f2:	6c8e                	ld	s9,192(sp)
    800063f4:	6d2e                	ld	s10,200(sp)
    800063f6:	6dce                	ld	s11,208(sp)
    800063f8:	6e6e                	ld	t3,216(sp)
    800063fa:	7e8e                	ld	t4,224(sp)
    800063fc:	7f2e                	ld	t5,232(sp)
    800063fe:	7fce                	ld	t6,240(sp)
    80006400:	6111                	addi	sp,sp,256
    80006402:	10200073          	sret
    80006406:	00000013          	nop
    8000640a:	00000013          	nop
    8000640e:	0001                	nop

0000000080006410 <timervec>:
    80006410:	34051573          	csrrw	a0,mscratch,a0
    80006414:	e10c                	sd	a1,0(a0)
    80006416:	e510                	sd	a2,8(a0)
    80006418:	e914                	sd	a3,16(a0)
    8000641a:	6d0c                	ld	a1,24(a0)
    8000641c:	7110                	ld	a2,32(a0)
    8000641e:	6194                	ld	a3,0(a1)
    80006420:	96b2                	add	a3,a3,a2
    80006422:	e194                	sd	a3,0(a1)
    80006424:	4589                	li	a1,2
    80006426:	14459073          	csrw	sip,a1
    8000642a:	6914                	ld	a3,16(a0)
    8000642c:	6510                	ld	a2,8(a0)
    8000642e:	610c                	ld	a1,0(a0)
    80006430:	34051573          	csrrw	a0,mscratch,a0
    80006434:	30200073          	mret
	...

000000008000643a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000643a:	1141                	addi	sp,sp,-16
    8000643c:	e422                	sd	s0,8(sp)
    8000643e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006440:	0c0007b7          	lui	a5,0xc000
    80006444:	4705                	li	a4,1
    80006446:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006448:	c3d8                	sw	a4,4(a5)
}
    8000644a:	6422                	ld	s0,8(sp)
    8000644c:	0141                	addi	sp,sp,16
    8000644e:	8082                	ret

0000000080006450 <plicinithart>:

void
plicinithart(void)
{
    80006450:	1141                	addi	sp,sp,-16
    80006452:	e406                	sd	ra,8(sp)
    80006454:	e022                	sd	s0,0(sp)
    80006456:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006458:	ffffb097          	auipc	ra,0xffffb
    8000645c:	53e080e7          	jalr	1342(ra) # 80001996 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006460:	0085171b          	slliw	a4,a0,0x8
    80006464:	0c0027b7          	lui	a5,0xc002
    80006468:	97ba                	add	a5,a5,a4
    8000646a:	40200713          	li	a4,1026
    8000646e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006472:	00d5151b          	slliw	a0,a0,0xd
    80006476:	0c2017b7          	lui	a5,0xc201
    8000647a:	953e                	add	a0,a0,a5
    8000647c:	00052023          	sw	zero,0(a0)
}
    80006480:	60a2                	ld	ra,8(sp)
    80006482:	6402                	ld	s0,0(sp)
    80006484:	0141                	addi	sp,sp,16
    80006486:	8082                	ret

0000000080006488 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006488:	1141                	addi	sp,sp,-16
    8000648a:	e406                	sd	ra,8(sp)
    8000648c:	e022                	sd	s0,0(sp)
    8000648e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006490:	ffffb097          	auipc	ra,0xffffb
    80006494:	506080e7          	jalr	1286(ra) # 80001996 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006498:	00d5179b          	slliw	a5,a0,0xd
    8000649c:	0c201537          	lui	a0,0xc201
    800064a0:	953e                	add	a0,a0,a5
  return irq;
}
    800064a2:	4148                	lw	a0,4(a0)
    800064a4:	60a2                	ld	ra,8(sp)
    800064a6:	6402                	ld	s0,0(sp)
    800064a8:	0141                	addi	sp,sp,16
    800064aa:	8082                	ret

00000000800064ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800064ac:	1101                	addi	sp,sp,-32
    800064ae:	ec06                	sd	ra,24(sp)
    800064b0:	e822                	sd	s0,16(sp)
    800064b2:	e426                	sd	s1,8(sp)
    800064b4:	1000                	addi	s0,sp,32
    800064b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800064b8:	ffffb097          	auipc	ra,0xffffb
    800064bc:	4de080e7          	jalr	1246(ra) # 80001996 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800064c0:	00d5151b          	slliw	a0,a0,0xd
    800064c4:	0c2017b7          	lui	a5,0xc201
    800064c8:	97aa                	add	a5,a5,a0
    800064ca:	c3c4                	sw	s1,4(a5)
}
    800064cc:	60e2                	ld	ra,24(sp)
    800064ce:	6442                	ld	s0,16(sp)
    800064d0:	64a2                	ld	s1,8(sp)
    800064d2:	6105                	addi	sp,sp,32
    800064d4:	8082                	ret

00000000800064d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800064d6:	1141                	addi	sp,sp,-16
    800064d8:	e406                	sd	ra,8(sp)
    800064da:	e022                	sd	s0,0(sp)
    800064dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800064de:	479d                	li	a5,7
    800064e0:	06a7c963          	blt	a5,a0,80006552 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800064e4:	0001d797          	auipc	a5,0x1d
    800064e8:	b1c78793          	addi	a5,a5,-1252 # 80023000 <disk>
    800064ec:	00a78733          	add	a4,a5,a0
    800064f0:	6789                	lui	a5,0x2
    800064f2:	97ba                	add	a5,a5,a4
    800064f4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800064f8:	e7ad                	bnez	a5,80006562 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800064fa:	00451793          	slli	a5,a0,0x4
    800064fe:	0001f717          	auipc	a4,0x1f
    80006502:	b0270713          	addi	a4,a4,-1278 # 80025000 <disk+0x2000>
    80006506:	6314                	ld	a3,0(a4)
    80006508:	96be                	add	a3,a3,a5
    8000650a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000650e:	6314                	ld	a3,0(a4)
    80006510:	96be                	add	a3,a3,a5
    80006512:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006516:	6314                	ld	a3,0(a4)
    80006518:	96be                	add	a3,a3,a5
    8000651a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000651e:	6318                	ld	a4,0(a4)
    80006520:	97ba                	add	a5,a5,a4
    80006522:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006526:	0001d797          	auipc	a5,0x1d
    8000652a:	ada78793          	addi	a5,a5,-1318 # 80023000 <disk>
    8000652e:	97aa                	add	a5,a5,a0
    80006530:	6509                	lui	a0,0x2
    80006532:	953e                	add	a0,a0,a5
    80006534:	4785                	li	a5,1
    80006536:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000653a:	0001f517          	auipc	a0,0x1f
    8000653e:	ade50513          	addi	a0,a0,-1314 # 80025018 <disk+0x2018>
    80006542:	ffffc097          	auipc	ra,0xffffc
    80006546:	d38080e7          	jalr	-712(ra) # 8000227a <wakeup>
}
    8000654a:	60a2                	ld	ra,8(sp)
    8000654c:	6402                	ld	s0,0(sp)
    8000654e:	0141                	addi	sp,sp,16
    80006550:	8082                	ret
    panic("free_desc 1");
    80006552:	00002517          	auipc	a0,0x2
    80006556:	41650513          	addi	a0,a0,1046 # 80008968 <syscalls+0x338>
    8000655a:	ffffa097          	auipc	ra,0xffffa
    8000655e:	fd0080e7          	jalr	-48(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006562:	00002517          	auipc	a0,0x2
    80006566:	41650513          	addi	a0,a0,1046 # 80008978 <syscalls+0x348>
    8000656a:	ffffa097          	auipc	ra,0xffffa
    8000656e:	fc0080e7          	jalr	-64(ra) # 8000052a <panic>

0000000080006572 <virtio_disk_init>:
{
    80006572:	1101                	addi	sp,sp,-32
    80006574:	ec06                	sd	ra,24(sp)
    80006576:	e822                	sd	s0,16(sp)
    80006578:	e426                	sd	s1,8(sp)
    8000657a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000657c:	00002597          	auipc	a1,0x2
    80006580:	40c58593          	addi	a1,a1,1036 # 80008988 <syscalls+0x358>
    80006584:	0001f517          	auipc	a0,0x1f
    80006588:	ba450513          	addi	a0,a0,-1116 # 80025128 <disk+0x2128>
    8000658c:	ffffa097          	auipc	ra,0xffffa
    80006590:	5a6080e7          	jalr	1446(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006594:	100017b7          	lui	a5,0x10001
    80006598:	4398                	lw	a4,0(a5)
    8000659a:	2701                	sext.w	a4,a4
    8000659c:	747277b7          	lui	a5,0x74727
    800065a0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800065a4:	0ef71163          	bne	a4,a5,80006686 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800065a8:	100017b7          	lui	a5,0x10001
    800065ac:	43dc                	lw	a5,4(a5)
    800065ae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065b0:	4705                	li	a4,1
    800065b2:	0ce79a63          	bne	a5,a4,80006686 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065b6:	100017b7          	lui	a5,0x10001
    800065ba:	479c                	lw	a5,8(a5)
    800065bc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800065be:	4709                	li	a4,2
    800065c0:	0ce79363          	bne	a5,a4,80006686 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800065c4:	100017b7          	lui	a5,0x10001
    800065c8:	47d8                	lw	a4,12(a5)
    800065ca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065cc:	554d47b7          	lui	a5,0x554d4
    800065d0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800065d4:	0af71963          	bne	a4,a5,80006686 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800065d8:	100017b7          	lui	a5,0x10001
    800065dc:	4705                	li	a4,1
    800065de:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065e0:	470d                	li	a4,3
    800065e2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800065e4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800065e6:	c7ffe737          	lui	a4,0xc7ffe
    800065ea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800065ee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800065f0:	2701                	sext.w	a4,a4
    800065f2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065f4:	472d                	li	a4,11
    800065f6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065f8:	473d                	li	a4,15
    800065fa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800065fc:	6705                	lui	a4,0x1
    800065fe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006600:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006604:	5bdc                	lw	a5,52(a5)
    80006606:	2781                	sext.w	a5,a5
  if(max == 0)
    80006608:	c7d9                	beqz	a5,80006696 <virtio_disk_init+0x124>
  if(max < NUM)
    8000660a:	471d                	li	a4,7
    8000660c:	08f77d63          	bgeu	a4,a5,800066a6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006610:	100014b7          	lui	s1,0x10001
    80006614:	47a1                	li	a5,8
    80006616:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006618:	6609                	lui	a2,0x2
    8000661a:	4581                	li	a1,0
    8000661c:	0001d517          	auipc	a0,0x1d
    80006620:	9e450513          	addi	a0,a0,-1564 # 80023000 <disk>
    80006624:	ffffa097          	auipc	ra,0xffffa
    80006628:	69a080e7          	jalr	1690(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000662c:	0001d717          	auipc	a4,0x1d
    80006630:	9d470713          	addi	a4,a4,-1580 # 80023000 <disk>
    80006634:	00c75793          	srli	a5,a4,0xc
    80006638:	2781                	sext.w	a5,a5
    8000663a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000663c:	0001f797          	auipc	a5,0x1f
    80006640:	9c478793          	addi	a5,a5,-1596 # 80025000 <disk+0x2000>
    80006644:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006646:	0001d717          	auipc	a4,0x1d
    8000664a:	a3a70713          	addi	a4,a4,-1478 # 80023080 <disk+0x80>
    8000664e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006650:	0001e717          	auipc	a4,0x1e
    80006654:	9b070713          	addi	a4,a4,-1616 # 80024000 <disk+0x1000>
    80006658:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000665a:	4705                	li	a4,1
    8000665c:	00e78c23          	sb	a4,24(a5)
    80006660:	00e78ca3          	sb	a4,25(a5)
    80006664:	00e78d23          	sb	a4,26(a5)
    80006668:	00e78da3          	sb	a4,27(a5)
    8000666c:	00e78e23          	sb	a4,28(a5)
    80006670:	00e78ea3          	sb	a4,29(a5)
    80006674:	00e78f23          	sb	a4,30(a5)
    80006678:	00e78fa3          	sb	a4,31(a5)
}
    8000667c:	60e2                	ld	ra,24(sp)
    8000667e:	6442                	ld	s0,16(sp)
    80006680:	64a2                	ld	s1,8(sp)
    80006682:	6105                	addi	sp,sp,32
    80006684:	8082                	ret
    panic("could not find virtio disk");
    80006686:	00002517          	auipc	a0,0x2
    8000668a:	31250513          	addi	a0,a0,786 # 80008998 <syscalls+0x368>
    8000668e:	ffffa097          	auipc	ra,0xffffa
    80006692:	e9c080e7          	jalr	-356(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006696:	00002517          	auipc	a0,0x2
    8000669a:	32250513          	addi	a0,a0,802 # 800089b8 <syscalls+0x388>
    8000669e:	ffffa097          	auipc	ra,0xffffa
    800066a2:	e8c080e7          	jalr	-372(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    800066a6:	00002517          	auipc	a0,0x2
    800066aa:	33250513          	addi	a0,a0,818 # 800089d8 <syscalls+0x3a8>
    800066ae:	ffffa097          	auipc	ra,0xffffa
    800066b2:	e7c080e7          	jalr	-388(ra) # 8000052a <panic>

00000000800066b6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800066b6:	7119                	addi	sp,sp,-128
    800066b8:	fc86                	sd	ra,120(sp)
    800066ba:	f8a2                	sd	s0,112(sp)
    800066bc:	f4a6                	sd	s1,104(sp)
    800066be:	f0ca                	sd	s2,96(sp)
    800066c0:	ecce                	sd	s3,88(sp)
    800066c2:	e8d2                	sd	s4,80(sp)
    800066c4:	e4d6                	sd	s5,72(sp)
    800066c6:	e0da                	sd	s6,64(sp)
    800066c8:	fc5e                	sd	s7,56(sp)
    800066ca:	f862                	sd	s8,48(sp)
    800066cc:	f466                	sd	s9,40(sp)
    800066ce:	f06a                	sd	s10,32(sp)
    800066d0:	ec6e                	sd	s11,24(sp)
    800066d2:	0100                	addi	s0,sp,128
    800066d4:	8aaa                	mv	s5,a0
    800066d6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800066d8:	00c52c83          	lw	s9,12(a0)
    800066dc:	001c9c9b          	slliw	s9,s9,0x1
    800066e0:	1c82                	slli	s9,s9,0x20
    800066e2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800066e6:	0001f517          	auipc	a0,0x1f
    800066ea:	a4250513          	addi	a0,a0,-1470 # 80025128 <disk+0x2128>
    800066ee:	ffffa097          	auipc	ra,0xffffa
    800066f2:	4d4080e7          	jalr	1236(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    800066f6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800066f8:	44a1                	li	s1,8
      disk.free[i] = 0;
    800066fa:	0001dc17          	auipc	s8,0x1d
    800066fe:	906c0c13          	addi	s8,s8,-1786 # 80023000 <disk>
    80006702:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006704:	4b0d                	li	s6,3
    80006706:	a0ad                	j	80006770 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006708:	00fc0733          	add	a4,s8,a5
    8000670c:	975e                	add	a4,a4,s7
    8000670e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006712:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006714:	0207c563          	bltz	a5,8000673e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006718:	2905                	addiw	s2,s2,1
    8000671a:	0611                	addi	a2,a2,4
    8000671c:	19690d63          	beq	s2,s6,800068b6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006720:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006722:	0001f717          	auipc	a4,0x1f
    80006726:	8f670713          	addi	a4,a4,-1802 # 80025018 <disk+0x2018>
    8000672a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000672c:	00074683          	lbu	a3,0(a4)
    80006730:	fee1                	bnez	a3,80006708 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006732:	2785                	addiw	a5,a5,1
    80006734:	0705                	addi	a4,a4,1
    80006736:	fe979be3          	bne	a5,s1,8000672c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000673a:	57fd                	li	a5,-1
    8000673c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000673e:	01205d63          	blez	s2,80006758 <virtio_disk_rw+0xa2>
    80006742:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006744:	000a2503          	lw	a0,0(s4)
    80006748:	00000097          	auipc	ra,0x0
    8000674c:	d8e080e7          	jalr	-626(ra) # 800064d6 <free_desc>
      for(int j = 0; j < i; j++)
    80006750:	2d85                	addiw	s11,s11,1
    80006752:	0a11                	addi	s4,s4,4
    80006754:	ffb918e3          	bne	s2,s11,80006744 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006758:	0001f597          	auipc	a1,0x1f
    8000675c:	9d058593          	addi	a1,a1,-1584 # 80025128 <disk+0x2128>
    80006760:	0001f517          	auipc	a0,0x1f
    80006764:	8b850513          	addi	a0,a0,-1864 # 80025018 <disk+0x2018>
    80006768:	ffffc097          	auipc	ra,0xffffc
    8000676c:	986080e7          	jalr	-1658(ra) # 800020ee <sleep>
  for(int i = 0; i < 3; i++){
    80006770:	f8040a13          	addi	s4,s0,-128
{
    80006774:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006776:	894e                	mv	s2,s3
    80006778:	b765                	j	80006720 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000677a:	0001f697          	auipc	a3,0x1f
    8000677e:	8866b683          	ld	a3,-1914(a3) # 80025000 <disk+0x2000>
    80006782:	96ba                	add	a3,a3,a4
    80006784:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006788:	0001d817          	auipc	a6,0x1d
    8000678c:	87880813          	addi	a6,a6,-1928 # 80023000 <disk>
    80006790:	0001f697          	auipc	a3,0x1f
    80006794:	87068693          	addi	a3,a3,-1936 # 80025000 <disk+0x2000>
    80006798:	6290                	ld	a2,0(a3)
    8000679a:	963a                	add	a2,a2,a4
    8000679c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800067a0:	0015e593          	ori	a1,a1,1
    800067a4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800067a8:	f8842603          	lw	a2,-120(s0)
    800067ac:	628c                	ld	a1,0(a3)
    800067ae:	972e                	add	a4,a4,a1
    800067b0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800067b4:	20050593          	addi	a1,a0,512
    800067b8:	0592                	slli	a1,a1,0x4
    800067ba:	95c2                	add	a1,a1,a6
    800067bc:	577d                	li	a4,-1
    800067be:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800067c2:	00461713          	slli	a4,a2,0x4
    800067c6:	6290                	ld	a2,0(a3)
    800067c8:	963a                	add	a2,a2,a4
    800067ca:	03078793          	addi	a5,a5,48
    800067ce:	97c2                	add	a5,a5,a6
    800067d0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800067d2:	629c                	ld	a5,0(a3)
    800067d4:	97ba                	add	a5,a5,a4
    800067d6:	4605                	li	a2,1
    800067d8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800067da:	629c                	ld	a5,0(a3)
    800067dc:	97ba                	add	a5,a5,a4
    800067de:	4809                	li	a6,2
    800067e0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800067e4:	629c                	ld	a5,0(a3)
    800067e6:	973e                	add	a4,a4,a5
    800067e8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067ec:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800067f0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067f4:	6698                	ld	a4,8(a3)
    800067f6:	00275783          	lhu	a5,2(a4)
    800067fa:	8b9d                	andi	a5,a5,7
    800067fc:	0786                	slli	a5,a5,0x1
    800067fe:	97ba                	add	a5,a5,a4
    80006800:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006804:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006808:	6698                	ld	a4,8(a3)
    8000680a:	00275783          	lhu	a5,2(a4)
    8000680e:	2785                	addiw	a5,a5,1
    80006810:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006814:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006818:	100017b7          	lui	a5,0x10001
    8000681c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006820:	004aa783          	lw	a5,4(s5)
    80006824:	02c79163          	bne	a5,a2,80006846 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006828:	0001f917          	auipc	s2,0x1f
    8000682c:	90090913          	addi	s2,s2,-1792 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006830:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006832:	85ca                	mv	a1,s2
    80006834:	8556                	mv	a0,s5
    80006836:	ffffc097          	auipc	ra,0xffffc
    8000683a:	8b8080e7          	jalr	-1864(ra) # 800020ee <sleep>
  while(b->disk == 1) {
    8000683e:	004aa783          	lw	a5,4(s5)
    80006842:	fe9788e3          	beq	a5,s1,80006832 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006846:	f8042903          	lw	s2,-128(s0)
    8000684a:	20090793          	addi	a5,s2,512
    8000684e:	00479713          	slli	a4,a5,0x4
    80006852:	0001c797          	auipc	a5,0x1c
    80006856:	7ae78793          	addi	a5,a5,1966 # 80023000 <disk>
    8000685a:	97ba                	add	a5,a5,a4
    8000685c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006860:	0001e997          	auipc	s3,0x1e
    80006864:	7a098993          	addi	s3,s3,1952 # 80025000 <disk+0x2000>
    80006868:	00491713          	slli	a4,s2,0x4
    8000686c:	0009b783          	ld	a5,0(s3)
    80006870:	97ba                	add	a5,a5,a4
    80006872:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006876:	854a                	mv	a0,s2
    80006878:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000687c:	00000097          	auipc	ra,0x0
    80006880:	c5a080e7          	jalr	-934(ra) # 800064d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006884:	8885                	andi	s1,s1,1
    80006886:	f0ed                	bnez	s1,80006868 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006888:	0001f517          	auipc	a0,0x1f
    8000688c:	8a050513          	addi	a0,a0,-1888 # 80025128 <disk+0x2128>
    80006890:	ffffa097          	auipc	ra,0xffffa
    80006894:	3e6080e7          	jalr	998(ra) # 80000c76 <release>
}
    80006898:	70e6                	ld	ra,120(sp)
    8000689a:	7446                	ld	s0,112(sp)
    8000689c:	74a6                	ld	s1,104(sp)
    8000689e:	7906                	ld	s2,96(sp)
    800068a0:	69e6                	ld	s3,88(sp)
    800068a2:	6a46                	ld	s4,80(sp)
    800068a4:	6aa6                	ld	s5,72(sp)
    800068a6:	6b06                	ld	s6,64(sp)
    800068a8:	7be2                	ld	s7,56(sp)
    800068aa:	7c42                	ld	s8,48(sp)
    800068ac:	7ca2                	ld	s9,40(sp)
    800068ae:	7d02                	ld	s10,32(sp)
    800068b0:	6de2                	ld	s11,24(sp)
    800068b2:	6109                	addi	sp,sp,128
    800068b4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800068b6:	f8042503          	lw	a0,-128(s0)
    800068ba:	20050793          	addi	a5,a0,512
    800068be:	0792                	slli	a5,a5,0x4
  if(write)
    800068c0:	0001c817          	auipc	a6,0x1c
    800068c4:	74080813          	addi	a6,a6,1856 # 80023000 <disk>
    800068c8:	00f80733          	add	a4,a6,a5
    800068cc:	01a036b3          	snez	a3,s10
    800068d0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800068d4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800068d8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800068dc:	7679                	lui	a2,0xffffe
    800068de:	963e                	add	a2,a2,a5
    800068e0:	0001e697          	auipc	a3,0x1e
    800068e4:	72068693          	addi	a3,a3,1824 # 80025000 <disk+0x2000>
    800068e8:	6298                	ld	a4,0(a3)
    800068ea:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800068ec:	0a878593          	addi	a1,a5,168
    800068f0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800068f2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800068f4:	6298                	ld	a4,0(a3)
    800068f6:	9732                	add	a4,a4,a2
    800068f8:	45c1                	li	a1,16
    800068fa:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800068fc:	6298                	ld	a4,0(a3)
    800068fe:	9732                	add	a4,a4,a2
    80006900:	4585                	li	a1,1
    80006902:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006906:	f8442703          	lw	a4,-124(s0)
    8000690a:	628c                	ld	a1,0(a3)
    8000690c:	962e                	add	a2,a2,a1
    8000690e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006912:	0712                	slli	a4,a4,0x4
    80006914:	6290                	ld	a2,0(a3)
    80006916:	963a                	add	a2,a2,a4
    80006918:	058a8593          	addi	a1,s5,88
    8000691c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000691e:	6294                	ld	a3,0(a3)
    80006920:	96ba                	add	a3,a3,a4
    80006922:	40000613          	li	a2,1024
    80006926:	c690                	sw	a2,8(a3)
  if(write)
    80006928:	e40d19e3          	bnez	s10,8000677a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000692c:	0001e697          	auipc	a3,0x1e
    80006930:	6d46b683          	ld	a3,1748(a3) # 80025000 <disk+0x2000>
    80006934:	96ba                	add	a3,a3,a4
    80006936:	4609                	li	a2,2
    80006938:	00c69623          	sh	a2,12(a3)
    8000693c:	b5b1                	j	80006788 <virtio_disk_rw+0xd2>

000000008000693e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000693e:	1101                	addi	sp,sp,-32
    80006940:	ec06                	sd	ra,24(sp)
    80006942:	e822                	sd	s0,16(sp)
    80006944:	e426                	sd	s1,8(sp)
    80006946:	e04a                	sd	s2,0(sp)
    80006948:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000694a:	0001e517          	auipc	a0,0x1e
    8000694e:	7de50513          	addi	a0,a0,2014 # 80025128 <disk+0x2128>
    80006952:	ffffa097          	auipc	ra,0xffffa
    80006956:	270080e7          	jalr	624(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000695a:	10001737          	lui	a4,0x10001
    8000695e:	533c                	lw	a5,96(a4)
    80006960:	8b8d                	andi	a5,a5,3
    80006962:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006964:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006968:	0001e797          	auipc	a5,0x1e
    8000696c:	69878793          	addi	a5,a5,1688 # 80025000 <disk+0x2000>
    80006970:	6b94                	ld	a3,16(a5)
    80006972:	0207d703          	lhu	a4,32(a5)
    80006976:	0026d783          	lhu	a5,2(a3)
    8000697a:	06f70163          	beq	a4,a5,800069dc <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000697e:	0001c917          	auipc	s2,0x1c
    80006982:	68290913          	addi	s2,s2,1666 # 80023000 <disk>
    80006986:	0001e497          	auipc	s1,0x1e
    8000698a:	67a48493          	addi	s1,s1,1658 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000698e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006992:	6898                	ld	a4,16(s1)
    80006994:	0204d783          	lhu	a5,32(s1)
    80006998:	8b9d                	andi	a5,a5,7
    8000699a:	078e                	slli	a5,a5,0x3
    8000699c:	97ba                	add	a5,a5,a4
    8000699e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800069a0:	20078713          	addi	a4,a5,512
    800069a4:	0712                	slli	a4,a4,0x4
    800069a6:	974a                	add	a4,a4,s2
    800069a8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800069ac:	e731                	bnez	a4,800069f8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800069ae:	20078793          	addi	a5,a5,512
    800069b2:	0792                	slli	a5,a5,0x4
    800069b4:	97ca                	add	a5,a5,s2
    800069b6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800069b8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800069bc:	ffffc097          	auipc	ra,0xffffc
    800069c0:	8be080e7          	jalr	-1858(ra) # 8000227a <wakeup>

    disk.used_idx += 1;
    800069c4:	0204d783          	lhu	a5,32(s1)
    800069c8:	2785                	addiw	a5,a5,1
    800069ca:	17c2                	slli	a5,a5,0x30
    800069cc:	93c1                	srli	a5,a5,0x30
    800069ce:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800069d2:	6898                	ld	a4,16(s1)
    800069d4:	00275703          	lhu	a4,2(a4)
    800069d8:	faf71be3          	bne	a4,a5,8000698e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800069dc:	0001e517          	auipc	a0,0x1e
    800069e0:	74c50513          	addi	a0,a0,1868 # 80025128 <disk+0x2128>
    800069e4:	ffffa097          	auipc	ra,0xffffa
    800069e8:	292080e7          	jalr	658(ra) # 80000c76 <release>
}
    800069ec:	60e2                	ld	ra,24(sp)
    800069ee:	6442                	ld	s0,16(sp)
    800069f0:	64a2                	ld	s1,8(sp)
    800069f2:	6902                	ld	s2,0(sp)
    800069f4:	6105                	addi	sp,sp,32
    800069f6:	8082                	ret
      panic("virtio_disk_intr status");
    800069f8:	00002517          	auipc	a0,0x2
    800069fc:	00050513          	mv	a0,a0
    80006a00:	ffffa097          	auipc	ra,0xffffa
    80006a04:	b2a080e7          	jalr	-1238(ra) # 8000052a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0) # 80008a20 <initcode>
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
