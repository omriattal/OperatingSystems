
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
    80000068:	08c78793          	addi	a5,a5,140 # 800060f0 <timervec>
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
    80000122:	4d4080e7          	jalr	1236(ra) # 800025f2 <either_copyin>
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
    800001c6:	02c080e7          	jalr	44(ra) # 800021ee <sleep>
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
    80000202:	39e080e7          	jalr	926(ra) # 8000259c <either_copyout>
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
    800002e2:	36a080e7          	jalr	874(ra) # 80002648 <procdump>
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
    80000436:	f48080e7          	jalr	-184(ra) # 8000237a <wakeup>
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
    80000468:	6cc78793          	addi	a5,a5,1740 # 80021b30 <devsw>
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
    80000882:	afc080e7          	jalr	-1284(ra) # 8000237a <wakeup>
    
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
    8000090e:	8e4080e7          	jalr	-1820(ra) # 800021ee <sleep>
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
    80000eb6:	bbe080e7          	jalr	-1090(ra) # 80002a70 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	276080e7          	jalr	630(ra) # 80006130 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	1fc080e7          	jalr	508(ra) # 800020be <scheduler>
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
    80000f2e:	b1e080e7          	jalr	-1250(ra) # 80002a48 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	b3e080e7          	jalr	-1218(ra) # 80002a70 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	1e0080e7          	jalr	480(ra) # 8000611a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	1ee080e7          	jalr	494(ra) # 80006130 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	3b6080e7          	jalr	950(ra) # 80003300 <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	a48080e7          	jalr	-1464(ra) # 8000399a <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	9f6080e7          	jalr	-1546(ra) # 80004950 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	2f0080e7          	jalr	752(ra) # 80006252 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	d5e080e7          	jalr	-674(ra) # 80001cc8 <userinit>
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

// ADDED: global turn variable and function for the FCFS scheduler
struct spinlock TURNLOCK;
uint TURN = -1;

int get_turn(){
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
    8000182e:	21e48493          	addi	s1,s1,542 # 80008a48 <TURN>
    80001832:	409c                	lw	a5,0(s1)
    80001834:	2785                	addiw	a5,a5,1
    80001836:	c09c                	sw	a5,0(s1)
	release(&TURNLOCK);
    80001838:	854a                	mv	a0,s2
    8000183a:	fffff097          	auipc	ra,0xfffff
    8000183e:	43c080e7          	jalr	1084(ra) # 80000c76 <release>
	return TURN;
}// ADDED
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
    80001884:	068a0a13          	addi	s4,s4,104 # 800178e8 <tickslock>
		char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	24a080e7          	jalr	586(ra) # 80000ad2 <kalloc>
    80001890:	862a                	mv	a2,a0
		if (pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
		uint64 va = KSTACK((int)(p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	858d                	srai	a1,a1,0x3
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
    800018ba:	18848493          	addi	s1,s1,392
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
    80001950:	f9c98993          	addi	s3,s3,-100 # 800178e8 <tickslock>
		initlock(&p->lock, "proc");
    80001954:	85da                	mv	a1,s6
    80001956:	8526                	mv	a0,s1
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	1da080e7          	jalr	474(ra) # 80000b32 <initlock>
		p->kstack = KSTACK((int)(p - proc));
    80001960:	415487b3          	sub	a5,s1,s5
    80001964:	878d                	srai	a5,a5,0x3
    80001966:	000a3703          	ld	a4,0(s4)
    8000196a:	02e787b3          	mul	a5,a5,a4
    8000196e:	2785                	addiw	a5,a5,1
    80001970:	00d7979b          	slliw	a5,a5,0xd
    80001974:	40f907b3          	sub	a5,s2,a5
    80001978:	f0bc                	sd	a5,96(s1)
	for (p = proc; p < &proc[NPROC]; p++)
    8000197a:	18848493          	addi	s1,s1,392
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
    80001a16:	02e7a783          	lw	a5,46(a5) # 80008a40 <first.1>
    80001a1a:	eb89                	bnez	a5,80001a2c <forkret+0x32>
		// be run from main().
		first = 0;
		fsinit(ROOTDEV);
	}

	usertrapret();
    80001a1c:	00001097          	auipc	ra,0x1
    80001a20:	06c080e7          	jalr	108(ra) # 80002a88 <usertrapret>
}
    80001a24:	60a2                	ld	ra,8(sp)
    80001a26:	6402                	ld	s0,0(sp)
    80001a28:	0141                	addi	sp,sp,16
    80001a2a:	8082                	ret
		first = 0;
    80001a2c:	00007797          	auipc	a5,0x7
    80001a30:	0007aa23          	sw	zero,20(a5) # 80008a40 <first.1>
		fsinit(ROOTDEV);
    80001a34:	4505                	li	a0,1
    80001a36:	00002097          	auipc	ra,0x2
    80001a3a:	ee4080e7          	jalr	-284(ra) # 8000391a <fsinit>
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
    80001a62:	fe678793          	addi	a5,a5,-26 # 80008a44 <nextpid>
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
    80001ac2:	07893683          	ld	a3,120(s2)
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
    80001b80:	7d28                	ld	a0,120(a0)
    80001b82:	c509                	beqz	a0,80001b8c <freeproc+0x18>
		kfree((void *)p->trapframe);
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	e52080e7          	jalr	-430(ra) # 800009d6 <kfree>
	p->trapframe = 0;
    80001b8c:	0604bc23          	sd	zero,120(s1)
	if (p->pagetable)
    80001b90:	78a8                	ld	a0,112(s1)
    80001b92:	c511                	beqz	a0,80001b9e <freeproc+0x2a>
		proc_freepagetable(p->pagetable, p->sz);
    80001b94:	74ac                	ld	a1,104(s1)
    80001b96:	00000097          	auipc	ra,0x0
    80001b9a:	f8c080e7          	jalr	-116(ra) # 80001b22 <proc_freepagetable>
	p->pagetable = 0;
    80001b9e:	0604b823          	sd	zero,112(s1)
	p->sz = 0;
    80001ba2:	0604b423          	sd	zero,104(s1)
	p->pid = 0;
    80001ba6:	0204a823          	sw	zero,48(s1)
	p->parent = 0;
    80001baa:	0404bc23          	sd	zero,88(s1)
	p->name[0] = 0;
    80001bae:	16048c23          	sb	zero,376(s1)
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
    80001be4:	d0890913          	addi	s2,s2,-760 # 800178e8 <tickslock>
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
    80001c00:	18848493          	addi	s1,s1,392
    80001c04:	ff2492e3          	bne	s1,s2,80001be8 <allocproc+0x1c>
	return 0;
    80001c08:	4481                	li	s1,0
    80001c0a:	a041                	j	80001c8a <allocproc+0xbe>
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
    80001c30:	0005061b          	sext.w	a2,a0
    80001c34:	c8b0                	sw	a2,80(s1)
	printf("Created process with pid %d and turn %d\n", p->pid, p->turn);
    80001c36:	588c                	lw	a1,48(s1)
    80001c38:	00006517          	auipc	a0,0x6
    80001c3c:	5b050513          	addi	a0,a0,1456 # 800081e8 <digits+0x1a8>
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	934080e7          	jalr	-1740(ra) # 80000574 <printf>
	if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	e8a080e7          	jalr	-374(ra) # 80000ad2 <kalloc>
    80001c50:	892a                	mv	s2,a0
    80001c52:	fca8                	sd	a0,120(s1)
    80001c54:	c131                	beqz	a0,80001c98 <allocproc+0xcc>
	p->pagetable = proc_pagetable(p);
    80001c56:	8526                	mv	a0,s1
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	e2e080e7          	jalr	-466(ra) # 80001a86 <proc_pagetable>
    80001c60:	892a                	mv	s2,a0
    80001c62:	f8a8                	sd	a0,112(s1)
	if (p->pagetable == 0)
    80001c64:	c531                	beqz	a0,80001cb0 <allocproc+0xe4>
	memset(&p->context, 0, sizeof(p->context));
    80001c66:	07000613          	li	a2,112
    80001c6a:	4581                	li	a1,0
    80001c6c:	08048513          	addi	a0,s1,128
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	04e080e7          	jalr	78(ra) # 80000cbe <memset>
	p->context.ra = (uint64)forkret;
    80001c78:	00000797          	auipc	a5,0x0
    80001c7c:	d8278793          	addi	a5,a5,-638 # 800019fa <forkret>
    80001c80:	e0dc                	sd	a5,128(s1)
	p->context.sp = p->kstack + PGSIZE;
    80001c82:	70bc                	ld	a5,96(s1)
    80001c84:	6705                	lui	a4,0x1
    80001c86:	97ba                	add	a5,a5,a4
    80001c88:	e4dc                	sd	a5,136(s1)
}
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	60e2                	ld	ra,24(sp)
    80001c8e:	6442                	ld	s0,16(sp)
    80001c90:	64a2                	ld	s1,8(sp)
    80001c92:	6902                	ld	s2,0(sp)
    80001c94:	6105                	addi	sp,sp,32
    80001c96:	8082                	ret
		freeproc(p);
    80001c98:	8526                	mv	a0,s1
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	eda080e7          	jalr	-294(ra) # 80001b74 <freeproc>
		release(&p->lock);
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	fd2080e7          	jalr	-46(ra) # 80000c76 <release>
		return 0;
    80001cac:	84ca                	mv	s1,s2
    80001cae:	bff1                	j	80001c8a <allocproc+0xbe>
		freeproc(p);
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	ec2080e7          	jalr	-318(ra) # 80001b74 <freeproc>
		release(&p->lock);
    80001cba:	8526                	mv	a0,s1
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	fba080e7          	jalr	-70(ra) # 80000c76 <release>
		return 0;
    80001cc4:	84ca                	mv	s1,s2
    80001cc6:	b7d1                	j	80001c8a <allocproc+0xbe>

0000000080001cc8 <userinit>:
{
    80001cc8:	1101                	addi	sp,sp,-32
    80001cca:	ec06                	sd	ra,24(sp)
    80001ccc:	e822                	sd	s0,16(sp)
    80001cce:	e426                	sd	s1,8(sp)
    80001cd0:	1000                	addi	s0,sp,32
	p = allocproc();
    80001cd2:	00000097          	auipc	ra,0x0
    80001cd6:	efa080e7          	jalr	-262(ra) # 80001bcc <allocproc>
    80001cda:	84aa                	mv	s1,a0
	initproc = p;
    80001cdc:	00007797          	auipc	a5,0x7
    80001ce0:	34a7b623          	sd	a0,844(a5) # 80009028 <initproc>
	uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ce4:	03400613          	li	a2,52
    80001ce8:	00007597          	auipc	a1,0x7
    80001cec:	d6858593          	addi	a1,a1,-664 # 80008a50 <initcode>
    80001cf0:	7928                	ld	a0,112(a0)
    80001cf2:	fffff097          	auipc	ra,0xfffff
    80001cf6:	642080e7          	jalr	1602(ra) # 80001334 <uvminit>
	p->sz = PGSIZE;
    80001cfa:	6785                	lui	a5,0x1
    80001cfc:	f4bc                	sd	a5,104(s1)
	p->trapframe->epc = 0;	   // user program counter
    80001cfe:	7cb8                	ld	a4,120(s1)
    80001d00:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
	p->trapframe->sp = PGSIZE; // user stack pointer
    80001d04:	7cb8                	ld	a4,120(s1)
    80001d06:	fb1c                	sd	a5,48(a4)
	safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d08:	4641                	li	a2,16
    80001d0a:	00006597          	auipc	a1,0x6
    80001d0e:	50e58593          	addi	a1,a1,1294 # 80008218 <digits+0x1d8>
    80001d12:	17848513          	addi	a0,s1,376
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	0fa080e7          	jalr	250(ra) # 80000e10 <safestrcpy>
	p->cwd = namei("/");
    80001d1e:	00006517          	auipc	a0,0x6
    80001d22:	50a50513          	addi	a0,a0,1290 # 80008228 <digits+0x1e8>
    80001d26:	00002097          	auipc	ra,0x2
    80001d2a:	622080e7          	jalr	1570(ra) # 80004348 <namei>
    80001d2e:	16a4b823          	sd	a0,368(s1)
	p->state = RUNNABLE;
    80001d32:	478d                	li	a5,3
    80001d34:	cc9c                	sw	a5,24(s1)
	release(&p->lock);
    80001d36:	8526                	mv	a0,s1
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	f3e080e7          	jalr	-194(ra) # 80000c76 <release>
}
    80001d40:	60e2                	ld	ra,24(sp)
    80001d42:	6442                	ld	s0,16(sp)
    80001d44:	64a2                	ld	s1,8(sp)
    80001d46:	6105                	addi	sp,sp,32
    80001d48:	8082                	ret

0000000080001d4a <growproc>:
{
    80001d4a:	1101                	addi	sp,sp,-32
    80001d4c:	ec06                	sd	ra,24(sp)
    80001d4e:	e822                	sd	s0,16(sp)
    80001d50:	e426                	sd	s1,8(sp)
    80001d52:	e04a                	sd	s2,0(sp)
    80001d54:	1000                	addi	s0,sp,32
    80001d56:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    80001d58:	00000097          	auipc	ra,0x0
    80001d5c:	c6a080e7          	jalr	-918(ra) # 800019c2 <myproc>
    80001d60:	892a                	mv	s2,a0
	sz = p->sz;
    80001d62:	752c                	ld	a1,104(a0)
    80001d64:	0005861b          	sext.w	a2,a1
	if (n > 0)
    80001d68:	00904f63          	bgtz	s1,80001d86 <growproc+0x3c>
	else if (n < 0)
    80001d6c:	0204cc63          	bltz	s1,80001da4 <growproc+0x5a>
	p->sz = sz;
    80001d70:	1602                	slli	a2,a2,0x20
    80001d72:	9201                	srli	a2,a2,0x20
    80001d74:	06c93423          	sd	a2,104(s2)
	return 0;
    80001d78:	4501                	li	a0,0
}
    80001d7a:	60e2                	ld	ra,24(sp)
    80001d7c:	6442                	ld	s0,16(sp)
    80001d7e:	64a2                	ld	s1,8(sp)
    80001d80:	6902                	ld	s2,0(sp)
    80001d82:	6105                	addi	sp,sp,32
    80001d84:	8082                	ret
		if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001d86:	9e25                	addw	a2,a2,s1
    80001d88:	1602                	slli	a2,a2,0x20
    80001d8a:	9201                	srli	a2,a2,0x20
    80001d8c:	1582                	slli	a1,a1,0x20
    80001d8e:	9181                	srli	a1,a1,0x20
    80001d90:	7928                	ld	a0,112(a0)
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	65c080e7          	jalr	1628(ra) # 800013ee <uvmalloc>
    80001d9a:	0005061b          	sext.w	a2,a0
    80001d9e:	fa69                	bnez	a2,80001d70 <growproc+0x26>
			return -1;
    80001da0:	557d                	li	a0,-1
    80001da2:	bfe1                	j	80001d7a <growproc+0x30>
		sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001da4:	9e25                	addw	a2,a2,s1
    80001da6:	1602                	slli	a2,a2,0x20
    80001da8:	9201                	srli	a2,a2,0x20
    80001daa:	1582                	slli	a1,a1,0x20
    80001dac:	9181                	srli	a1,a1,0x20
    80001dae:	7928                	ld	a0,112(a0)
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	5f6080e7          	jalr	1526(ra) # 800013a6 <uvmdealloc>
    80001db8:	0005061b          	sext.w	a2,a0
    80001dbc:	bf55                	j	80001d70 <growproc+0x26>

0000000080001dbe <fork>:
{
    80001dbe:	7139                	addi	sp,sp,-64
    80001dc0:	fc06                	sd	ra,56(sp)
    80001dc2:	f822                	sd	s0,48(sp)
    80001dc4:	f426                	sd	s1,40(sp)
    80001dc6:	f04a                	sd	s2,32(sp)
    80001dc8:	ec4e                	sd	s3,24(sp)
    80001dca:	e852                	sd	s4,16(sp)
    80001dcc:	e456                	sd	s5,8(sp)
    80001dce:	0080                	addi	s0,sp,64
	struct proc *p = myproc();
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	bf2080e7          	jalr	-1038(ra) # 800019c2 <myproc>
    80001dd8:	8aaa                	mv	s5,a0
	if ((np = allocproc()) == 0)
    80001dda:	00000097          	auipc	ra,0x0
    80001dde:	df2080e7          	jalr	-526(ra) # 80001bcc <allocproc>
    80001de2:	12050063          	beqz	a0,80001f02 <fork+0x144>
    80001de6:	89aa                	mv	s3,a0
	if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001de8:	068ab603          	ld	a2,104(s5)
    80001dec:	792c                	ld	a1,112(a0)
    80001dee:	070ab503          	ld	a0,112(s5)
    80001df2:	fffff097          	auipc	ra,0xfffff
    80001df6:	748080e7          	jalr	1864(ra) # 8000153a <uvmcopy>
    80001dfa:	04054863          	bltz	a0,80001e4a <fork+0x8c>
	np->sz = p->sz;
    80001dfe:	068ab783          	ld	a5,104(s5)
    80001e02:	06f9b423          	sd	a5,104(s3)
	*(np->trapframe) = *(p->trapframe);
    80001e06:	078ab683          	ld	a3,120(s5)
    80001e0a:	87b6                	mv	a5,a3
    80001e0c:	0789b703          	ld	a4,120(s3)
    80001e10:	12068693          	addi	a3,a3,288
    80001e14:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e18:	6788                	ld	a0,8(a5)
    80001e1a:	6b8c                	ld	a1,16(a5)
    80001e1c:	6f90                	ld	a2,24(a5)
    80001e1e:	01073023          	sd	a6,0(a4)
    80001e22:	e708                	sd	a0,8(a4)
    80001e24:	eb0c                	sd	a1,16(a4)
    80001e26:	ef10                	sd	a2,24(a4)
    80001e28:	02078793          	addi	a5,a5,32
    80001e2c:	02070713          	addi	a4,a4,32
    80001e30:	fed792e3          	bne	a5,a3,80001e14 <fork+0x56>
	np->trapframe->a0 = 0;
    80001e34:	0789b783          	ld	a5,120(s3)
    80001e38:	0607b823          	sd	zero,112(a5)
	for (i = 0; i < NOFILE; i++)
    80001e3c:	0f0a8493          	addi	s1,s5,240
    80001e40:	0f098913          	addi	s2,s3,240
    80001e44:	170a8a13          	addi	s4,s5,368
    80001e48:	a00d                	j	80001e6a <fork+0xac>
		freeproc(np);
    80001e4a:	854e                	mv	a0,s3
    80001e4c:	00000097          	auipc	ra,0x0
    80001e50:	d28080e7          	jalr	-728(ra) # 80001b74 <freeproc>
		release(&np->lock);
    80001e54:	854e                	mv	a0,s3
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	e20080e7          	jalr	-480(ra) # 80000c76 <release>
		return -1;
    80001e5e:	597d                	li	s2,-1
    80001e60:	a079                	j	80001eee <fork+0x130>
	for (i = 0; i < NOFILE; i++)
    80001e62:	04a1                	addi	s1,s1,8
    80001e64:	0921                	addi	s2,s2,8
    80001e66:	01448b63          	beq	s1,s4,80001e7c <fork+0xbe>
		if (p->ofile[i])
    80001e6a:	6088                	ld	a0,0(s1)
    80001e6c:	d97d                	beqz	a0,80001e62 <fork+0xa4>
			np->ofile[i] = filedup(p->ofile[i]);
    80001e6e:	00003097          	auipc	ra,0x3
    80001e72:	b74080e7          	jalr	-1164(ra) # 800049e2 <filedup>
    80001e76:	00a93023          	sd	a0,0(s2)
    80001e7a:	b7e5                	j	80001e62 <fork+0xa4>
	np->cwd = idup(p->cwd);
    80001e7c:	170ab503          	ld	a0,368(s5)
    80001e80:	00002097          	auipc	ra,0x2
    80001e84:	cd4080e7          	jalr	-812(ra) # 80003b54 <idup>
    80001e88:	16a9b823          	sd	a0,368(s3)
	safestrcpy(np->name, p->name, sizeof(p->name));
    80001e8c:	4641                	li	a2,16
    80001e8e:	178a8593          	addi	a1,s5,376
    80001e92:	17898513          	addi	a0,s3,376
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	f7a080e7          	jalr	-134(ra) # 80000e10 <safestrcpy>
	pid = np->pid;
    80001e9e:	0309a903          	lw	s2,48(s3)
	release(&np->lock);
    80001ea2:	854e                	mv	a0,s3
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	dd2080e7          	jalr	-558(ra) # 80000c76 <release>
	acquire(&wait_lock);
    80001eac:	0000f497          	auipc	s1,0xf
    80001eb0:	42448493          	addi	s1,s1,1060 # 800112d0 <wait_lock>
    80001eb4:	8526                	mv	a0,s1
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	d0c080e7          	jalr	-756(ra) # 80000bc2 <acquire>
	np->parent = p;
    80001ebe:	0559bc23          	sd	s5,88(s3)
	np->trace_mask = p->trace_mask; // ADDED
    80001ec2:	034aa783          	lw	a5,52(s5)
    80001ec6:	02f9aa23          	sw	a5,52(s3)
	release(&wait_lock);
    80001eca:	8526                	mv	a0,s1
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	daa080e7          	jalr	-598(ra) # 80000c76 <release>
	acquire(&np->lock);
    80001ed4:	854e                	mv	a0,s3
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	cec080e7          	jalr	-788(ra) # 80000bc2 <acquire>
	np->state = RUNNABLE;
    80001ede:	478d                	li	a5,3
    80001ee0:	00f9ac23          	sw	a5,24(s3)
	release(&np->lock);
    80001ee4:	854e                	mv	a0,s3
    80001ee6:	fffff097          	auipc	ra,0xfffff
    80001eea:	d90080e7          	jalr	-624(ra) # 80000c76 <release>
}
    80001eee:	854a                	mv	a0,s2
    80001ef0:	70e2                	ld	ra,56(sp)
    80001ef2:	7442                	ld	s0,48(sp)
    80001ef4:	74a2                	ld	s1,40(sp)
    80001ef6:	7902                	ld	s2,32(sp)
    80001ef8:	69e2                	ld	s3,24(sp)
    80001efa:	6a42                	ld	s4,16(sp)
    80001efc:	6aa2                	ld	s5,8(sp)
    80001efe:	6121                	addi	sp,sp,64
    80001f00:	8082                	ret
		return -1;
    80001f02:	597d                	li	s2,-1
    80001f04:	b7ed                	j	80001eee <fork+0x130>

0000000080001f06 <sched_default>:
{
    80001f06:	7139                	addi	sp,sp,-64
    80001f08:	fc06                	sd	ra,56(sp)
    80001f0a:	f822                	sd	s0,48(sp)
    80001f0c:	f426                	sd	s1,40(sp)
    80001f0e:	f04a                	sd	s2,32(sp)
    80001f10:	ec4e                	sd	s3,24(sp)
    80001f12:	e852                	sd	s4,16(sp)
    80001f14:	e456                	sd	s5,8(sp)
    80001f16:	e05a                	sd	s6,0(sp)
    80001f18:	0080                	addi	s0,sp,64
    80001f1a:	8792                	mv	a5,tp
	int id = r_tp();
    80001f1c:	2781                	sext.w	a5,a5
	c->proc = 0;
    80001f1e:	00779a93          	slli	s5,a5,0x7
    80001f22:	0000f717          	auipc	a4,0xf
    80001f26:	37e70713          	addi	a4,a4,894 # 800112a0 <TURNLOCK>
    80001f2a:	9756                	add	a4,a4,s5
    80001f2c:	04073423          	sd	zero,72(a4)
			swtch(&c->context, &p->context);
    80001f30:	0000f717          	auipc	a4,0xf
    80001f34:	3c070713          	addi	a4,a4,960 # 800112f0 <cpus+0x8>
    80001f38:	9aba                	add	s5,s5,a4
	for (p = proc; p < &proc[NPROC]; p++)
    80001f3a:	0000f497          	auipc	s1,0xf
    80001f3e:	7ae48493          	addi	s1,s1,1966 # 800116e8 <proc>
		if (p->state == RUNNABLE)
    80001f42:	498d                	li	s3,3
			p->state = RUNNING;
    80001f44:	4b11                	li	s6,4
			c->proc = p;
    80001f46:	079e                	slli	a5,a5,0x7
    80001f48:	0000fa17          	auipc	s4,0xf
    80001f4c:	358a0a13          	addi	s4,s4,856 # 800112a0 <TURNLOCK>
    80001f50:	9a3e                	add	s4,s4,a5
	for (p = proc; p < &proc[NPROC]; p++)
    80001f52:	00016917          	auipc	s2,0x16
    80001f56:	99690913          	addi	s2,s2,-1642 # 800178e8 <tickslock>
    80001f5a:	a811                	j	80001f6e <sched_default+0x68>
		release(&p->lock);
    80001f5c:	8526                	mv	a0,s1
    80001f5e:	fffff097          	auipc	ra,0xfffff
    80001f62:	d18080e7          	jalr	-744(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80001f66:	18848493          	addi	s1,s1,392
    80001f6a:	03248863          	beq	s1,s2,80001f9a <sched_default+0x94>
		acquire(&p->lock);
    80001f6e:	8526                	mv	a0,s1
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	c52080e7          	jalr	-942(ra) # 80000bc2 <acquire>
		if (p->state == RUNNABLE)
    80001f78:	4c9c                	lw	a5,24(s1)
    80001f7a:	ff3791e3          	bne	a5,s3,80001f5c <sched_default+0x56>
			p->state = RUNNING;
    80001f7e:	0164ac23          	sw	s6,24(s1)
			c->proc = p;
    80001f82:	049a3423          	sd	s1,72(s4)
			swtch(&c->context, &p->context);
    80001f86:	08048593          	addi	a1,s1,128
    80001f8a:	8556                	mv	a0,s5
    80001f8c:	00001097          	auipc	ra,0x1
    80001f90:	a52080e7          	jalr	-1454(ra) # 800029de <swtch>
			c->proc = 0;
    80001f94:	040a3423          	sd	zero,72(s4)
    80001f98:	b7d1                	j	80001f5c <sched_default+0x56>
}
    80001f9a:	70e2                	ld	ra,56(sp)
    80001f9c:	7442                	ld	s0,48(sp)
    80001f9e:	74a2                	ld	s1,40(sp)
    80001fa0:	7902                	ld	s2,32(sp)
    80001fa2:	69e2                	ld	s3,24(sp)
    80001fa4:	6a42                	ld	s4,16(sp)
    80001fa6:	6aa2                	ld	s5,8(sp)
    80001fa8:	6b02                	ld	s6,0(sp)
    80001faa:	6121                	addi	sp,sp,64
    80001fac:	8082                	ret

0000000080001fae <sched_fcfs>:
{
    80001fae:	715d                	addi	sp,sp,-80
    80001fb0:	e486                	sd	ra,72(sp)
    80001fb2:	e0a2                	sd	s0,64(sp)
    80001fb4:	fc26                	sd	s1,56(sp)
    80001fb6:	f84a                	sd	s2,48(sp)
    80001fb8:	f44e                	sd	s3,40(sp)
    80001fba:	f052                	sd	s4,32(sp)
    80001fbc:	ec56                	sd	s5,24(sp)
    80001fbe:	e85a                	sd	s6,16(sp)
    80001fc0:	e45e                	sd	s7,8(sp)
    80001fc2:	0880                	addi	s0,sp,80
    80001fc4:	8b92                	mv	s7,tp
	int id = r_tp();
    80001fc6:	2b81                	sext.w	s7,s7
	c->proc = 0;
    80001fc8:	007b9713          	slli	a4,s7,0x7
    80001fcc:	0000f797          	auipc	a5,0xf
    80001fd0:	2d478793          	addi	a5,a5,724 # 800112a0 <TURNLOCK>
    80001fd4:	97ba                	add	a5,a5,a4
    80001fd6:	0407b423          	sd	zero,72(a5)
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80001fda:	4901                	li	s2,0
	int proc_to_run_index = 0;
    80001fdc:	4b01                	li	s6,0
	uint first_turn = 4294967295;
    80001fde:	5afd                	li	s5,-1
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80001fe0:	0000f497          	auipc	s1,0xf
    80001fe4:	70848493          	addi	s1,s1,1800 # 800116e8 <proc>
		if (p->state == RUNNABLE && p->turn < first_turn)
    80001fe8:	4a0d                	li	s4,3
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80001fea:	00016997          	auipc	s3,0x16
    80001fee:	8fe98993          	addi	s3,s3,-1794 # 800178e8 <tickslock>
    80001ff2:	a819                	j	80002008 <sched_fcfs+0x5a>
		release(&p->lock);
    80001ff4:	8526                	mv	a0,s1
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	c80080e7          	jalr	-896(ra) # 80000c76 <release>
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80001ffe:	18848493          	addi	s1,s1,392
    80002002:	2905                	addiw	s2,s2,1
    80002004:	03348063          	beq	s1,s3,80002024 <sched_fcfs+0x76>
		acquire(&p->lock);
    80002008:	8526                	mv	a0,s1
    8000200a:	fffff097          	auipc	ra,0xfffff
    8000200e:	bb8080e7          	jalr	-1096(ra) # 80000bc2 <acquire>
		if (p->state == RUNNABLE && p->turn < first_turn)
    80002012:	4c9c                	lw	a5,24(s1)
    80002014:	ff4790e3          	bne	a5,s4,80001ff4 <sched_fcfs+0x46>
    80002018:	48bc                	lw	a5,80(s1)
    8000201a:	fd57fde3          	bgeu	a5,s5,80001ff4 <sched_fcfs+0x46>
    8000201e:	8b4a                	mv	s6,s2
			first_turn = p->turn;
    80002020:	8abe                	mv	s5,a5
    80002022:	bfc9                	j	80001ff4 <sched_fcfs+0x46>
	first = &proc[proc_to_run_index];
    80002024:	18800793          	li	a5,392
    80002028:	02fb09b3          	mul	s3,s6,a5
    8000202c:	0000f917          	auipc	s2,0xf
    80002030:	6bc90913          	addi	s2,s2,1724 # 800116e8 <proc>
    80002034:	994e                	add	s2,s2,s3
	acquire(&first->lock);
    80002036:	854a                	mv	a0,s2
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	b8a080e7          	jalr	-1142(ra) # 80000bc2 <acquire>
	if (first->state == RUNNABLE)
    80002040:	01892703          	lw	a4,24(s2)
    80002044:	478d                	li	a5,3
    80002046:	02f70263          	beq	a4,a5,8000206a <sched_fcfs+0xbc>
	release(&first->lock);
    8000204a:	854a                	mv	a0,s2
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	c2a080e7          	jalr	-982(ra) # 80000c76 <release>
}
    80002054:	60a6                	ld	ra,72(sp)
    80002056:	6406                	ld	s0,64(sp)
    80002058:	74e2                	ld	s1,56(sp)
    8000205a:	7942                	ld	s2,48(sp)
    8000205c:	79a2                	ld	s3,40(sp)
    8000205e:	7a02                	ld	s4,32(sp)
    80002060:	6ae2                	ld	s5,24(sp)
    80002062:	6b42                	ld	s6,16(sp)
    80002064:	6ba2                	ld	s7,8(sp)
    80002066:	6161                	addi	sp,sp,80
    80002068:	8082                	ret
		first->state = RUNNING;
    8000206a:	0000f597          	auipc	a1,0xf
    8000206e:	67e58593          	addi	a1,a1,1662 # 800116e8 <proc>
    80002072:	4791                	li	a5,4
    80002074:	00f92c23          	sw	a5,24(s2)
		c->proc = first;
    80002078:	0b9e                	slli	s7,s7,0x7
    8000207a:	0000fa17          	auipc	s4,0xf
    8000207e:	226a0a13          	addi	s4,s4,550 # 800112a0 <TURNLOCK>
    80002082:	9a5e                	add	s4,s4,s7
    80002084:	052a3423          	sd	s2,72(s4)
		swtch(&c->context, &first->context);
    80002088:	08098993          	addi	s3,s3,128
    8000208c:	95ce                	add	a1,a1,s3
    8000208e:	0000f517          	auipc	a0,0xf
    80002092:	26250513          	addi	a0,a0,610 # 800112f0 <cpus+0x8>
    80002096:	955e                	add	a0,a0,s7
    80002098:	00001097          	auipc	ra,0x1
    8000209c:	946080e7          	jalr	-1722(ra) # 800029de <swtch>
		printf("process %d came back with state %d\n", first->pid, first->state);
    800020a0:	01892603          	lw	a2,24(s2)
    800020a4:	03092583          	lw	a1,48(s2)
    800020a8:	00006517          	auipc	a0,0x6
    800020ac:	18850513          	addi	a0,a0,392 # 80008230 <digits+0x1f0>
    800020b0:	ffffe097          	auipc	ra,0xffffe
    800020b4:	4c4080e7          	jalr	1220(ra) # 80000574 <printf>
		c->proc = 0;
    800020b8:	040a3423          	sd	zero,72(s4)
    800020bc:	b779                	j	8000204a <sched_fcfs+0x9c>

00000000800020be <scheduler>:
{
    800020be:	1141                	addi	sp,sp,-16
    800020c0:	e406                	sd	ra,8(sp)
    800020c2:	e022                	sd	s0,0(sp)
    800020c4:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020c6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020ca:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020ce:	10079073          	csrw	sstatus,a5
		sched_fcfs();
    800020d2:	00000097          	auipc	ra,0x0
    800020d6:	edc080e7          	jalr	-292(ra) # 80001fae <sched_fcfs>
	for (;;)
    800020da:	b7f5                	j	800020c6 <scheduler+0x8>

00000000800020dc <sched>:
{
    800020dc:	7179                	addi	sp,sp,-48
    800020de:	f406                	sd	ra,40(sp)
    800020e0:	f022                	sd	s0,32(sp)
    800020e2:	ec26                	sd	s1,24(sp)
    800020e4:	e84a                	sd	s2,16(sp)
    800020e6:	e44e                	sd	s3,8(sp)
    800020e8:	1800                	addi	s0,sp,48
	struct proc *p = myproc();
    800020ea:	00000097          	auipc	ra,0x0
    800020ee:	8d8080e7          	jalr	-1832(ra) # 800019c2 <myproc>
    800020f2:	84aa                	mv	s1,a0
	if (!holding(&p->lock))
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	a54080e7          	jalr	-1452(ra) # 80000b48 <holding>
    800020fc:	c93d                	beqz	a0,80002172 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020fe:	8792                	mv	a5,tp
	if (mycpu()->noff != 1)
    80002100:	2781                	sext.w	a5,a5
    80002102:	079e                	slli	a5,a5,0x7
    80002104:	0000f717          	auipc	a4,0xf
    80002108:	19c70713          	addi	a4,a4,412 # 800112a0 <TURNLOCK>
    8000210c:	97ba                	add	a5,a5,a4
    8000210e:	0c07a703          	lw	a4,192(a5)
    80002112:	4785                	li	a5,1
    80002114:	06f71763          	bne	a4,a5,80002182 <sched+0xa6>
	if (p->state == RUNNING)
    80002118:	4c98                	lw	a4,24(s1)
    8000211a:	4791                	li	a5,4
    8000211c:	06f70b63          	beq	a4,a5,80002192 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002120:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002124:	8b89                	andi	a5,a5,2
	if (intr_get())
    80002126:	efb5                	bnez	a5,800021a2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002128:	8792                	mv	a5,tp
	intena = mycpu()->intena;
    8000212a:	0000f917          	auipc	s2,0xf
    8000212e:	17690913          	addi	s2,s2,374 # 800112a0 <TURNLOCK>
    80002132:	2781                	sext.w	a5,a5
    80002134:	079e                	slli	a5,a5,0x7
    80002136:	97ca                	add	a5,a5,s2
    80002138:	0c47a983          	lw	s3,196(a5)
    8000213c:	8792                	mv	a5,tp
	swtch(&p->context, &mycpu()->context);
    8000213e:	2781                	sext.w	a5,a5
    80002140:	079e                	slli	a5,a5,0x7
    80002142:	0000f597          	auipc	a1,0xf
    80002146:	1ae58593          	addi	a1,a1,430 # 800112f0 <cpus+0x8>
    8000214a:	95be                	add	a1,a1,a5
    8000214c:	08048513          	addi	a0,s1,128
    80002150:	00001097          	auipc	ra,0x1
    80002154:	88e080e7          	jalr	-1906(ra) # 800029de <swtch>
    80002158:	8792                	mv	a5,tp
	mycpu()->intena = intena;
    8000215a:	2781                	sext.w	a5,a5
    8000215c:	079e                	slli	a5,a5,0x7
    8000215e:	97ca                	add	a5,a5,s2
    80002160:	0d37a223          	sw	s3,196(a5)
}
    80002164:	70a2                	ld	ra,40(sp)
    80002166:	7402                	ld	s0,32(sp)
    80002168:	64e2                	ld	s1,24(sp)
    8000216a:	6942                	ld	s2,16(sp)
    8000216c:	69a2                	ld	s3,8(sp)
    8000216e:	6145                	addi	sp,sp,48
    80002170:	8082                	ret
		panic("sched p->lock");
    80002172:	00006517          	auipc	a0,0x6
    80002176:	0e650513          	addi	a0,a0,230 # 80008258 <digits+0x218>
    8000217a:	ffffe097          	auipc	ra,0xffffe
    8000217e:	3b0080e7          	jalr	944(ra) # 8000052a <panic>
		panic("sched locks");
    80002182:	00006517          	auipc	a0,0x6
    80002186:	0e650513          	addi	a0,a0,230 # 80008268 <digits+0x228>
    8000218a:	ffffe097          	auipc	ra,0xffffe
    8000218e:	3a0080e7          	jalr	928(ra) # 8000052a <panic>
		panic("sched running");
    80002192:	00006517          	auipc	a0,0x6
    80002196:	0e650513          	addi	a0,a0,230 # 80008278 <digits+0x238>
    8000219a:	ffffe097          	auipc	ra,0xffffe
    8000219e:	390080e7          	jalr	912(ra) # 8000052a <panic>
		panic("sched interruptible");
    800021a2:	00006517          	auipc	a0,0x6
    800021a6:	0e650513          	addi	a0,a0,230 # 80008288 <digits+0x248>
    800021aa:	ffffe097          	auipc	ra,0xffffe
    800021ae:	380080e7          	jalr	896(ra) # 8000052a <panic>

00000000800021b2 <yield>:
{
    800021b2:	1101                	addi	sp,sp,-32
    800021b4:	ec06                	sd	ra,24(sp)
    800021b6:	e822                	sd	s0,16(sp)
    800021b8:	e426                	sd	s1,8(sp)
    800021ba:	1000                	addi	s0,sp,32
	struct proc *p = myproc();
    800021bc:	00000097          	auipc	ra,0x0
    800021c0:	806080e7          	jalr	-2042(ra) # 800019c2 <myproc>
    800021c4:	84aa                	mv	s1,a0
	acquire(&p->lock);
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	9fc080e7          	jalr	-1540(ra) # 80000bc2 <acquire>
	p->state = RUNNABLE;
    800021ce:	478d                	li	a5,3
    800021d0:	cc9c                	sw	a5,24(s1)
	sched();
    800021d2:	00000097          	auipc	ra,0x0
    800021d6:	f0a080e7          	jalr	-246(ra) # 800020dc <sched>
	release(&p->lock);
    800021da:	8526                	mv	a0,s1
    800021dc:	fffff097          	auipc	ra,0xfffff
    800021e0:	a9a080e7          	jalr	-1382(ra) # 80000c76 <release>
}
    800021e4:	60e2                	ld	ra,24(sp)
    800021e6:	6442                	ld	s0,16(sp)
    800021e8:	64a2                	ld	s1,8(sp)
    800021ea:	6105                	addi	sp,sp,32
    800021ec:	8082                	ret

00000000800021ee <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800021ee:	7179                	addi	sp,sp,-48
    800021f0:	f406                	sd	ra,40(sp)
    800021f2:	f022                	sd	s0,32(sp)
    800021f4:	ec26                	sd	s1,24(sp)
    800021f6:	e84a                	sd	s2,16(sp)
    800021f8:	e44e                	sd	s3,8(sp)
    800021fa:	1800                	addi	s0,sp,48
    800021fc:	89aa                	mv	s3,a0
    800021fe:	892e                	mv	s2,a1
	struct proc *p = myproc();
    80002200:	fffff097          	auipc	ra,0xfffff
    80002204:	7c2080e7          	jalr	1986(ra) # 800019c2 <myproc>
    80002208:	84aa                	mv	s1,a0
	// Once we hold p->lock, we can be
	// guaranteed that we won't miss any wakeup
	// (wakeup locks p->lock),
	// so it's okay to release lk.

	acquire(&p->lock); //DOC: sleeplock1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	9b8080e7          	jalr	-1608(ra) # 80000bc2 <acquire>
	release(lk);
    80002212:	854a                	mv	a0,s2
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	a62080e7          	jalr	-1438(ra) # 80000c76 <release>

	// Go to sleep.
	p->chan = chan;
    8000221c:	0334b023          	sd	s3,32(s1)
	p->state = SLEEPING;
    80002220:	4789                	li	a5,2
    80002222:	cc9c                	sw	a5,24(s1)

	sched();
    80002224:	00000097          	auipc	ra,0x0
    80002228:	eb8080e7          	jalr	-328(ra) # 800020dc <sched>

	// Tidy up.
	p->chan = 0;
    8000222c:	0204b023          	sd	zero,32(s1)

	// Reacquire original lock.
	release(&p->lock);
    80002230:	8526                	mv	a0,s1
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	a44080e7          	jalr	-1468(ra) # 80000c76 <release>
	acquire(lk);
    8000223a:	854a                	mv	a0,s2
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	986080e7          	jalr	-1658(ra) # 80000bc2 <acquire>
}
    80002244:	70a2                	ld	ra,40(sp)
    80002246:	7402                	ld	s0,32(sp)
    80002248:	64e2                	ld	s1,24(sp)
    8000224a:	6942                	ld	s2,16(sp)
    8000224c:	69a2                	ld	s3,8(sp)
    8000224e:	6145                	addi	sp,sp,48
    80002250:	8082                	ret

0000000080002252 <wait>:
{
    80002252:	715d                	addi	sp,sp,-80
    80002254:	e486                	sd	ra,72(sp)
    80002256:	e0a2                	sd	s0,64(sp)
    80002258:	fc26                	sd	s1,56(sp)
    8000225a:	f84a                	sd	s2,48(sp)
    8000225c:	f44e                	sd	s3,40(sp)
    8000225e:	f052                	sd	s4,32(sp)
    80002260:	ec56                	sd	s5,24(sp)
    80002262:	e85a                	sd	s6,16(sp)
    80002264:	e45e                	sd	s7,8(sp)
    80002266:	e062                	sd	s8,0(sp)
    80002268:	0880                	addi	s0,sp,80
    8000226a:	8b2a                	mv	s6,a0
	struct proc *p = myproc();
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	756080e7          	jalr	1878(ra) # 800019c2 <myproc>
    80002274:	892a                	mv	s2,a0
	acquire(&wait_lock);
    80002276:	0000f517          	auipc	a0,0xf
    8000227a:	05a50513          	addi	a0,a0,90 # 800112d0 <wait_lock>
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	944080e7          	jalr	-1724(ra) # 80000bc2 <acquire>
		havekids = 0;
    80002286:	4b81                	li	s7,0
				if (np->state == ZOMBIE)
    80002288:	4a15                	li	s4,5
				havekids = 1;
    8000228a:	4a85                	li	s5,1
		for (np = proc; np < &proc[NPROC]; np++)
    8000228c:	00015997          	auipc	s3,0x15
    80002290:	65c98993          	addi	s3,s3,1628 # 800178e8 <tickslock>
		sleep(p, &wait_lock); //DOC: wait-sleep
    80002294:	0000fc17          	auipc	s8,0xf
    80002298:	03cc0c13          	addi	s8,s8,60 # 800112d0 <wait_lock>
		havekids = 0;
    8000229c:	875e                	mv	a4,s7
		for (np = proc; np < &proc[NPROC]; np++)
    8000229e:	0000f497          	auipc	s1,0xf
    800022a2:	44a48493          	addi	s1,s1,1098 # 800116e8 <proc>
    800022a6:	a0bd                	j	80002314 <wait+0xc2>
					pid = np->pid;
    800022a8:	0304a983          	lw	s3,48(s1)
					if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022ac:	000b0e63          	beqz	s6,800022c8 <wait+0x76>
    800022b0:	4691                	li	a3,4
    800022b2:	02c48613          	addi	a2,s1,44
    800022b6:	85da                	mv	a1,s6
    800022b8:	07093503          	ld	a0,112(s2)
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	382080e7          	jalr	898(ra) # 8000163e <copyout>
    800022c4:	02054563          	bltz	a0,800022ee <wait+0x9c>
					freeproc(np);
    800022c8:	8526                	mv	a0,s1
    800022ca:	00000097          	auipc	ra,0x0
    800022ce:	8aa080e7          	jalr	-1878(ra) # 80001b74 <freeproc>
					release(&np->lock);
    800022d2:	8526                	mv	a0,s1
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	9a2080e7          	jalr	-1630(ra) # 80000c76 <release>
					release(&wait_lock);
    800022dc:	0000f517          	auipc	a0,0xf
    800022e0:	ff450513          	addi	a0,a0,-12 # 800112d0 <wait_lock>
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	992080e7          	jalr	-1646(ra) # 80000c76 <release>
					return pid;
    800022ec:	a09d                	j	80002352 <wait+0x100>
						release(&np->lock);
    800022ee:	8526                	mv	a0,s1
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	986080e7          	jalr	-1658(ra) # 80000c76 <release>
						release(&wait_lock);
    800022f8:	0000f517          	auipc	a0,0xf
    800022fc:	fd850513          	addi	a0,a0,-40 # 800112d0 <wait_lock>
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	976080e7          	jalr	-1674(ra) # 80000c76 <release>
						return -1;
    80002308:	59fd                	li	s3,-1
    8000230a:	a0a1                	j	80002352 <wait+0x100>
		for (np = proc; np < &proc[NPROC]; np++)
    8000230c:	18848493          	addi	s1,s1,392
    80002310:	03348463          	beq	s1,s3,80002338 <wait+0xe6>
			if (np->parent == p)
    80002314:	6cbc                	ld	a5,88(s1)
    80002316:	ff279be3          	bne	a5,s2,8000230c <wait+0xba>
				acquire(&np->lock);
    8000231a:	8526                	mv	a0,s1
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	8a6080e7          	jalr	-1882(ra) # 80000bc2 <acquire>
				if (np->state == ZOMBIE)
    80002324:	4c9c                	lw	a5,24(s1)
    80002326:	f94781e3          	beq	a5,s4,800022a8 <wait+0x56>
				release(&np->lock);
    8000232a:	8526                	mv	a0,s1
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	94a080e7          	jalr	-1718(ra) # 80000c76 <release>
				havekids = 1;
    80002334:	8756                	mv	a4,s5
    80002336:	bfd9                	j	8000230c <wait+0xba>
		if (!havekids || p->killed)
    80002338:	c701                	beqz	a4,80002340 <wait+0xee>
    8000233a:	02892783          	lw	a5,40(s2)
    8000233e:	c79d                	beqz	a5,8000236c <wait+0x11a>
			release(&wait_lock);
    80002340:	0000f517          	auipc	a0,0xf
    80002344:	f9050513          	addi	a0,a0,-112 # 800112d0 <wait_lock>
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	92e080e7          	jalr	-1746(ra) # 80000c76 <release>
			return -1;
    80002350:	59fd                	li	s3,-1
}
    80002352:	854e                	mv	a0,s3
    80002354:	60a6                	ld	ra,72(sp)
    80002356:	6406                	ld	s0,64(sp)
    80002358:	74e2                	ld	s1,56(sp)
    8000235a:	7942                	ld	s2,48(sp)
    8000235c:	79a2                	ld	s3,40(sp)
    8000235e:	7a02                	ld	s4,32(sp)
    80002360:	6ae2                	ld	s5,24(sp)
    80002362:	6b42                	ld	s6,16(sp)
    80002364:	6ba2                	ld	s7,8(sp)
    80002366:	6c02                	ld	s8,0(sp)
    80002368:	6161                	addi	sp,sp,80
    8000236a:	8082                	ret
		sleep(p, &wait_lock); //DOC: wait-sleep
    8000236c:	85e2                	mv	a1,s8
    8000236e:	854a                	mv	a0,s2
    80002370:	00000097          	auipc	ra,0x0
    80002374:	e7e080e7          	jalr	-386(ra) # 800021ee <sleep>
		havekids = 0;
    80002378:	b715                	j	8000229c <wait+0x4a>

000000008000237a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000237a:	7139                	addi	sp,sp,-64
    8000237c:	fc06                	sd	ra,56(sp)
    8000237e:	f822                	sd	s0,48(sp)
    80002380:	f426                	sd	s1,40(sp)
    80002382:	f04a                	sd	s2,32(sp)
    80002384:	ec4e                	sd	s3,24(sp)
    80002386:	e852                	sd	s4,16(sp)
    80002388:	e456                	sd	s5,8(sp)
    8000238a:	0080                	addi	s0,sp,64
    8000238c:	8a2a                	mv	s4,a0
	struct proc *p;

	for (p = proc; p < &proc[NPROC]; p++)
    8000238e:	0000f497          	auipc	s1,0xf
    80002392:	35a48493          	addi	s1,s1,858 # 800116e8 <proc>
	{
		if (p != myproc())
		{
			acquire(&p->lock);
			if (p->state == SLEEPING && p->chan == chan)
    80002396:	4989                	li	s3,2
			{
				p->state = RUNNABLE;
    80002398:	4a8d                	li	s5,3
	for (p = proc; p < &proc[NPROC]; p++)
    8000239a:	00015917          	auipc	s2,0x15
    8000239e:	54e90913          	addi	s2,s2,1358 # 800178e8 <tickslock>
    800023a2:	a811                	j	800023b6 <wakeup+0x3c>
				p->turn = get_turn(); // ADDED: determin the turn of the process when it wakes up
			}
			release(&p->lock);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	8d0080e7          	jalr	-1840(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    800023ae:	18848493          	addi	s1,s1,392
    800023b2:	03248b63          	beq	s1,s2,800023e8 <wakeup+0x6e>
		if (p != myproc())
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	60c080e7          	jalr	1548(ra) # 800019c2 <myproc>
    800023be:	fea488e3          	beq	s1,a0,800023ae <wakeup+0x34>
			acquire(&p->lock);
    800023c2:	8526                	mv	a0,s1
    800023c4:	ffffe097          	auipc	ra,0xffffe
    800023c8:	7fe080e7          	jalr	2046(ra) # 80000bc2 <acquire>
			if (p->state == SLEEPING && p->chan == chan)
    800023cc:	4c9c                	lw	a5,24(s1)
    800023ce:	fd379be3          	bne	a5,s3,800023a4 <wakeup+0x2a>
    800023d2:	709c                	ld	a5,32(s1)
    800023d4:	fd4798e3          	bne	a5,s4,800023a4 <wakeup+0x2a>
				p->state = RUNNABLE;
    800023d8:	0154ac23          	sw	s5,24(s1)
				p->turn = get_turn(); // ADDED: determin the turn of the process when it wakes up
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	430080e7          	jalr	1072(ra) # 8000180c <get_turn>
    800023e4:	c8a8                	sw	a0,80(s1)
    800023e6:	bf7d                	j	800023a4 <wakeup+0x2a>
		}
	}
}
    800023e8:	70e2                	ld	ra,56(sp)
    800023ea:	7442                	ld	s0,48(sp)
    800023ec:	74a2                	ld	s1,40(sp)
    800023ee:	7902                	ld	s2,32(sp)
    800023f0:	69e2                	ld	s3,24(sp)
    800023f2:	6a42                	ld	s4,16(sp)
    800023f4:	6aa2                	ld	s5,8(sp)
    800023f6:	6121                	addi	sp,sp,64
    800023f8:	8082                	ret

00000000800023fa <reparent>:
{
    800023fa:	7179                	addi	sp,sp,-48
    800023fc:	f406                	sd	ra,40(sp)
    800023fe:	f022                	sd	s0,32(sp)
    80002400:	ec26                	sd	s1,24(sp)
    80002402:	e84a                	sd	s2,16(sp)
    80002404:	e44e                	sd	s3,8(sp)
    80002406:	e052                	sd	s4,0(sp)
    80002408:	1800                	addi	s0,sp,48
    8000240a:	892a                	mv	s2,a0
	for (pp = proc; pp < &proc[NPROC]; pp++)
    8000240c:	0000f497          	auipc	s1,0xf
    80002410:	2dc48493          	addi	s1,s1,732 # 800116e8 <proc>
			pp->parent = initproc;
    80002414:	00007a17          	auipc	s4,0x7
    80002418:	c14a0a13          	addi	s4,s4,-1004 # 80009028 <initproc>
	for (pp = proc; pp < &proc[NPROC]; pp++)
    8000241c:	00015997          	auipc	s3,0x15
    80002420:	4cc98993          	addi	s3,s3,1228 # 800178e8 <tickslock>
    80002424:	a029                	j	8000242e <reparent+0x34>
    80002426:	18848493          	addi	s1,s1,392
    8000242a:	01348d63          	beq	s1,s3,80002444 <reparent+0x4a>
		if (pp->parent == p)
    8000242e:	6cbc                	ld	a5,88(s1)
    80002430:	ff279be3          	bne	a5,s2,80002426 <reparent+0x2c>
			pp->parent = initproc;
    80002434:	000a3503          	ld	a0,0(s4)
    80002438:	eca8                	sd	a0,88(s1)
			wakeup(initproc);
    8000243a:	00000097          	auipc	ra,0x0
    8000243e:	f40080e7          	jalr	-192(ra) # 8000237a <wakeup>
    80002442:	b7d5                	j	80002426 <reparent+0x2c>
}
    80002444:	70a2                	ld	ra,40(sp)
    80002446:	7402                	ld	s0,32(sp)
    80002448:	64e2                	ld	s1,24(sp)
    8000244a:	6942                	ld	s2,16(sp)
    8000244c:	69a2                	ld	s3,8(sp)
    8000244e:	6a02                	ld	s4,0(sp)
    80002450:	6145                	addi	sp,sp,48
    80002452:	8082                	ret

0000000080002454 <exit>:
{
    80002454:	7179                	addi	sp,sp,-48
    80002456:	f406                	sd	ra,40(sp)
    80002458:	f022                	sd	s0,32(sp)
    8000245a:	ec26                	sd	s1,24(sp)
    8000245c:	e84a                	sd	s2,16(sp)
    8000245e:	e44e                	sd	s3,8(sp)
    80002460:	e052                	sd	s4,0(sp)
    80002462:	1800                	addi	s0,sp,48
    80002464:	8a2a                	mv	s4,a0
	struct proc *p = myproc();
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	55c080e7          	jalr	1372(ra) # 800019c2 <myproc>
    8000246e:	89aa                	mv	s3,a0
	if (p == initproc)
    80002470:	00007797          	auipc	a5,0x7
    80002474:	bb87b783          	ld	a5,-1096(a5) # 80009028 <initproc>
    80002478:	0f050493          	addi	s1,a0,240
    8000247c:	17050913          	addi	s2,a0,368
    80002480:	02a79363          	bne	a5,a0,800024a6 <exit+0x52>
		panic("init exiting");
    80002484:	00006517          	auipc	a0,0x6
    80002488:	e1c50513          	addi	a0,a0,-484 # 800082a0 <digits+0x260>
    8000248c:	ffffe097          	auipc	ra,0xffffe
    80002490:	09e080e7          	jalr	158(ra) # 8000052a <panic>
			fileclose(f);
    80002494:	00002097          	auipc	ra,0x2
    80002498:	5a0080e7          	jalr	1440(ra) # 80004a34 <fileclose>
			p->ofile[fd] = 0;
    8000249c:	0004b023          	sd	zero,0(s1)
	for (int fd = 0; fd < NOFILE; fd++)
    800024a0:	04a1                	addi	s1,s1,8
    800024a2:	01248563          	beq	s1,s2,800024ac <exit+0x58>
		if (p->ofile[fd])
    800024a6:	6088                	ld	a0,0(s1)
    800024a8:	f575                	bnez	a0,80002494 <exit+0x40>
    800024aa:	bfdd                	j	800024a0 <exit+0x4c>
	begin_op();
    800024ac:	00002097          	auipc	ra,0x2
    800024b0:	0bc080e7          	jalr	188(ra) # 80004568 <begin_op>
	iput(p->cwd);
    800024b4:	1709b503          	ld	a0,368(s3)
    800024b8:	00002097          	auipc	ra,0x2
    800024bc:	894080e7          	jalr	-1900(ra) # 80003d4c <iput>
	end_op();
    800024c0:	00002097          	auipc	ra,0x2
    800024c4:	128080e7          	jalr	296(ra) # 800045e8 <end_op>
	p->cwd = 0;
    800024c8:	1609b823          	sd	zero,368(s3)
	acquire(&wait_lock);
    800024cc:	0000f497          	auipc	s1,0xf
    800024d0:	e0448493          	addi	s1,s1,-508 # 800112d0 <wait_lock>
    800024d4:	8526                	mv	a0,s1
    800024d6:	ffffe097          	auipc	ra,0xffffe
    800024da:	6ec080e7          	jalr	1772(ra) # 80000bc2 <acquire>
	reparent(p);
    800024de:	854e                	mv	a0,s3
    800024e0:	00000097          	auipc	ra,0x0
    800024e4:	f1a080e7          	jalr	-230(ra) # 800023fa <reparent>
	wakeup(p->parent);
    800024e8:	0589b503          	ld	a0,88(s3)
    800024ec:	00000097          	auipc	ra,0x0
    800024f0:	e8e080e7          	jalr	-370(ra) # 8000237a <wakeup>
	acquire(&p->lock);
    800024f4:	854e                	mv	a0,s3
    800024f6:	ffffe097          	auipc	ra,0xffffe
    800024fa:	6cc080e7          	jalr	1740(ra) # 80000bc2 <acquire>
	p->xstate = status;
    800024fe:	0349a623          	sw	s4,44(s3)
	p->state = ZOMBIE;
    80002502:	4795                	li	a5,5
    80002504:	00f9ac23          	sw	a5,24(s3)
	release(&wait_lock);
    80002508:	8526                	mv	a0,s1
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	76c080e7          	jalr	1900(ra) # 80000c76 <release>
	sched();
    80002512:	00000097          	auipc	ra,0x0
    80002516:	bca080e7          	jalr	-1078(ra) # 800020dc <sched>
	panic("zombie exit");
    8000251a:	00006517          	auipc	a0,0x6
    8000251e:	d9650513          	addi	a0,a0,-618 # 800082b0 <digits+0x270>
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	008080e7          	jalr	8(ra) # 8000052a <panic>

000000008000252a <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000252a:	7179                	addi	sp,sp,-48
    8000252c:	f406                	sd	ra,40(sp)
    8000252e:	f022                	sd	s0,32(sp)
    80002530:	ec26                	sd	s1,24(sp)
    80002532:	e84a                	sd	s2,16(sp)
    80002534:	e44e                	sd	s3,8(sp)
    80002536:	1800                	addi	s0,sp,48
    80002538:	892a                	mv	s2,a0
	struct proc *p;

	for (p = proc; p < &proc[NPROC]; p++)
    8000253a:	0000f497          	auipc	s1,0xf
    8000253e:	1ae48493          	addi	s1,s1,430 # 800116e8 <proc>
    80002542:	00015997          	auipc	s3,0x15
    80002546:	3a698993          	addi	s3,s3,934 # 800178e8 <tickslock>
	{
		acquire(&p->lock);
    8000254a:	8526                	mv	a0,s1
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	676080e7          	jalr	1654(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    80002554:	589c                	lw	a5,48(s1)
    80002556:	01278d63          	beq	a5,s2,80002570 <kill+0x46>
				p->state = RUNNABLE;
			}
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    8000255a:	8526                	mv	a0,s1
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	71a080e7          	jalr	1818(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80002564:	18848493          	addi	s1,s1,392
    80002568:	ff3491e3          	bne	s1,s3,8000254a <kill+0x20>
	}
	return -1;
    8000256c:	557d                	li	a0,-1
    8000256e:	a829                	j	80002588 <kill+0x5e>
			p->killed = 1;
    80002570:	4785                	li	a5,1
    80002572:	d49c                	sw	a5,40(s1)
			if (p->state == SLEEPING)
    80002574:	4c98                	lw	a4,24(s1)
    80002576:	4789                	li	a5,2
    80002578:	00f70f63          	beq	a4,a5,80002596 <kill+0x6c>
			release(&p->lock);
    8000257c:	8526                	mv	a0,s1
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	6f8080e7          	jalr	1784(ra) # 80000c76 <release>
			return 0;
    80002586:	4501                	li	a0,0
}
    80002588:	70a2                	ld	ra,40(sp)
    8000258a:	7402                	ld	s0,32(sp)
    8000258c:	64e2                	ld	s1,24(sp)
    8000258e:	6942                	ld	s2,16(sp)
    80002590:	69a2                	ld	s3,8(sp)
    80002592:	6145                	addi	sp,sp,48
    80002594:	8082                	ret
				p->state = RUNNABLE;
    80002596:	478d                	li	a5,3
    80002598:	cc9c                	sw	a5,24(s1)
    8000259a:	b7cd                	j	8000257c <kill+0x52>

000000008000259c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000259c:	7179                	addi	sp,sp,-48
    8000259e:	f406                	sd	ra,40(sp)
    800025a0:	f022                	sd	s0,32(sp)
    800025a2:	ec26                	sd	s1,24(sp)
    800025a4:	e84a                	sd	s2,16(sp)
    800025a6:	e44e                	sd	s3,8(sp)
    800025a8:	e052                	sd	s4,0(sp)
    800025aa:	1800                	addi	s0,sp,48
    800025ac:	84aa                	mv	s1,a0
    800025ae:	892e                	mv	s2,a1
    800025b0:	89b2                	mv	s3,a2
    800025b2:	8a36                	mv	s4,a3
	struct proc *p = myproc();
    800025b4:	fffff097          	auipc	ra,0xfffff
    800025b8:	40e080e7          	jalr	1038(ra) # 800019c2 <myproc>
	if (user_dst)
    800025bc:	c08d                	beqz	s1,800025de <either_copyout+0x42>
	{
		return copyout(p->pagetable, dst, src, len);
    800025be:	86d2                	mv	a3,s4
    800025c0:	864e                	mv	a2,s3
    800025c2:	85ca                	mv	a1,s2
    800025c4:	7928                	ld	a0,112(a0)
    800025c6:	fffff097          	auipc	ra,0xfffff
    800025ca:	078080e7          	jalr	120(ra) # 8000163e <copyout>
	else
	{
		memmove((char *)dst, src, len);
		return 0;
	}
}
    800025ce:	70a2                	ld	ra,40(sp)
    800025d0:	7402                	ld	s0,32(sp)
    800025d2:	64e2                	ld	s1,24(sp)
    800025d4:	6942                	ld	s2,16(sp)
    800025d6:	69a2                	ld	s3,8(sp)
    800025d8:	6a02                	ld	s4,0(sp)
    800025da:	6145                	addi	sp,sp,48
    800025dc:	8082                	ret
		memmove((char *)dst, src, len);
    800025de:	000a061b          	sext.w	a2,s4
    800025e2:	85ce                	mv	a1,s3
    800025e4:	854a                	mv	a0,s2
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	734080e7          	jalr	1844(ra) # 80000d1a <memmove>
		return 0;
    800025ee:	8526                	mv	a0,s1
    800025f0:	bff9                	j	800025ce <either_copyout+0x32>

00000000800025f2 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025f2:	7179                	addi	sp,sp,-48
    800025f4:	f406                	sd	ra,40(sp)
    800025f6:	f022                	sd	s0,32(sp)
    800025f8:	ec26                	sd	s1,24(sp)
    800025fa:	e84a                	sd	s2,16(sp)
    800025fc:	e44e                	sd	s3,8(sp)
    800025fe:	e052                	sd	s4,0(sp)
    80002600:	1800                	addi	s0,sp,48
    80002602:	892a                	mv	s2,a0
    80002604:	84ae                	mv	s1,a1
    80002606:	89b2                	mv	s3,a2
    80002608:	8a36                	mv	s4,a3
	struct proc *p = myproc();
    8000260a:	fffff097          	auipc	ra,0xfffff
    8000260e:	3b8080e7          	jalr	952(ra) # 800019c2 <myproc>
	if (user_src)
    80002612:	c08d                	beqz	s1,80002634 <either_copyin+0x42>
	{
		return copyin(p->pagetable, dst, src, len);
    80002614:	86d2                	mv	a3,s4
    80002616:	864e                	mv	a2,s3
    80002618:	85ca                	mv	a1,s2
    8000261a:	7928                	ld	a0,112(a0)
    8000261c:	fffff097          	auipc	ra,0xfffff
    80002620:	0ae080e7          	jalr	174(ra) # 800016ca <copyin>
	else
	{
		memmove(dst, (char *)src, len);
		return 0;
	}
}
    80002624:	70a2                	ld	ra,40(sp)
    80002626:	7402                	ld	s0,32(sp)
    80002628:	64e2                	ld	s1,24(sp)
    8000262a:	6942                	ld	s2,16(sp)
    8000262c:	69a2                	ld	s3,8(sp)
    8000262e:	6a02                	ld	s4,0(sp)
    80002630:	6145                	addi	sp,sp,48
    80002632:	8082                	ret
		memmove(dst, (char *)src, len);
    80002634:	000a061b          	sext.w	a2,s4
    80002638:	85ce                	mv	a1,s3
    8000263a:	854a                	mv	a0,s2
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	6de080e7          	jalr	1758(ra) # 80000d1a <memmove>
		return 0;
    80002644:	8526                	mv	a0,s1
    80002646:	bff9                	j	80002624 <either_copyin+0x32>

0000000080002648 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002648:	715d                	addi	sp,sp,-80
    8000264a:	e486                	sd	ra,72(sp)
    8000264c:	e0a2                	sd	s0,64(sp)
    8000264e:	fc26                	sd	s1,56(sp)
    80002650:	f84a                	sd	s2,48(sp)
    80002652:	f44e                	sd	s3,40(sp)
    80002654:	f052                	sd	s4,32(sp)
    80002656:	ec56                	sd	s5,24(sp)
    80002658:	e85a                	sd	s6,16(sp)
    8000265a:	e45e                	sd	s7,8(sp)
    8000265c:	0880                	addi	s0,sp,80
		[RUNNING] "run   ",
		[ZOMBIE] "zombie"};
	struct proc *p;
	char *state;

	printf("\n");
    8000265e:	00006517          	auipc	a0,0x6
    80002662:	a6a50513          	addi	a0,a0,-1430 # 800080c8 <digits+0x88>
    80002666:	ffffe097          	auipc	ra,0xffffe
    8000266a:	f0e080e7          	jalr	-242(ra) # 80000574 <printf>
	for (p = proc; p < &proc[NPROC]; p++)
    8000266e:	0000f497          	auipc	s1,0xf
    80002672:	1f248493          	addi	s1,s1,498 # 80011860 <proc+0x178>
    80002676:	00015917          	auipc	s2,0x15
    8000267a:	3ea90913          	addi	s2,s2,1002 # 80017a60 <bcache+0x160>
	{
		if (p->state == UNUSED)
			continue;
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000267e:	4b15                	li	s6,5
			state = states[p->state];
		else
			state = "???";
    80002680:	00006997          	auipc	s3,0x6
    80002684:	c4098993          	addi	s3,s3,-960 # 800082c0 <digits+0x280>
		printf("%d %s %s", p->pid, state, p->name);
    80002688:	00006a97          	auipc	s5,0x6
    8000268c:	c40a8a93          	addi	s5,s5,-960 # 800082c8 <digits+0x288>
		printf("\n");
    80002690:	00006a17          	auipc	s4,0x6
    80002694:	a38a0a13          	addi	s4,s4,-1480 # 800080c8 <digits+0x88>
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002698:	00006b97          	auipc	s7,0x6
    8000269c:	c68b8b93          	addi	s7,s7,-920 # 80008300 <states.0>
    800026a0:	a00d                	j	800026c2 <procdump+0x7a>
		printf("%d %s %s", p->pid, state, p->name);
    800026a2:	eb86a583          	lw	a1,-328(a3)
    800026a6:	8556                	mv	a0,s5
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	ecc080e7          	jalr	-308(ra) # 80000574 <printf>
		printf("\n");
    800026b0:	8552                	mv	a0,s4
    800026b2:	ffffe097          	auipc	ra,0xffffe
    800026b6:	ec2080e7          	jalr	-318(ra) # 80000574 <printf>
	for (p = proc; p < &proc[NPROC]; p++)
    800026ba:	18848493          	addi	s1,s1,392
    800026be:	03248263          	beq	s1,s2,800026e2 <procdump+0x9a>
		if (p->state == UNUSED)
    800026c2:	86a6                	mv	a3,s1
    800026c4:	ea04a783          	lw	a5,-352(s1)
    800026c8:	dbed                	beqz	a5,800026ba <procdump+0x72>
			state = "???";
    800026ca:	864e                	mv	a2,s3
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026cc:	fcfb6be3          	bltu	s6,a5,800026a2 <procdump+0x5a>
    800026d0:	02079713          	slli	a4,a5,0x20
    800026d4:	01d75793          	srli	a5,a4,0x1d
    800026d8:	97de                	add	a5,a5,s7
    800026da:	6390                	ld	a2,0(a5)
    800026dc:	f279                	bnez	a2,800026a2 <procdump+0x5a>
			state = "???";
    800026de:	864e                	mv	a2,s3
    800026e0:	b7c9                	j	800026a2 <procdump+0x5a>
	}
}
    800026e2:	60a6                	ld	ra,72(sp)
    800026e4:	6406                	ld	s0,64(sp)
    800026e6:	74e2                	ld	s1,56(sp)
    800026e8:	7942                	ld	s2,48(sp)
    800026ea:	79a2                	ld	s3,40(sp)
    800026ec:	7a02                	ld	s4,32(sp)
    800026ee:	6ae2                	ld	s5,24(sp)
    800026f0:	6b42                	ld	s6,16(sp)
    800026f2:	6ba2                	ld	s7,8(sp)
    800026f4:	6161                	addi	sp,sp,80
    800026f6:	8082                	ret

00000000800026f8 <trace>:
//ADDED
int trace(int mask, int pid)
{
    800026f8:	7179                	addi	sp,sp,-48
    800026fa:	f406                	sd	ra,40(sp)
    800026fc:	f022                	sd	s0,32(sp)
    800026fe:	ec26                	sd	s1,24(sp)
    80002700:	e84a                	sd	s2,16(sp)
    80002702:	e44e                	sd	s3,8(sp)
    80002704:	e052                	sd	s4,0(sp)
    80002706:	1800                	addi	s0,sp,48
    80002708:	8a2a                	mv	s4,a0
    8000270a:	892e                	mv	s2,a1
	struct proc *p;
	for (p = proc; p < &proc[NPROC]; p++)
    8000270c:	0000f497          	auipc	s1,0xf
    80002710:	fdc48493          	addi	s1,s1,-36 # 800116e8 <proc>
    80002714:	00015997          	auipc	s3,0x15
    80002718:	1d498993          	addi	s3,s3,468 # 800178e8 <tickslock>
	{
		acquire(&p->lock);
    8000271c:	8526                	mv	a0,s1
    8000271e:	ffffe097          	auipc	ra,0xffffe
    80002722:	4a4080e7          	jalr	1188(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    80002726:	589c                	lw	a5,48(s1)
    80002728:	01278d63          	beq	a5,s2,80002742 <trace+0x4a>
		{
			p->trace_mask = mask;
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    8000272c:	8526                	mv	a0,s1
    8000272e:	ffffe097          	auipc	ra,0xffffe
    80002732:	548080e7          	jalr	1352(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80002736:	18848493          	addi	s1,s1,392
    8000273a:	ff3491e3          	bne	s1,s3,8000271c <trace+0x24>
	}

	return -1;
    8000273e:	557d                	li	a0,-1
    80002740:	a809                	j	80002752 <trace+0x5a>
			p->trace_mask = mask;
    80002742:	0344aa23          	sw	s4,52(s1)
			release(&p->lock);
    80002746:	8526                	mv	a0,s1
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	52e080e7          	jalr	1326(ra) # 80000c76 <release>
			return 0;
    80002750:	4501                	li	a0,0
}
    80002752:	70a2                	ld	ra,40(sp)
    80002754:	7402                	ld	s0,32(sp)
    80002756:	64e2                	ld	s1,24(sp)
    80002758:	6942                	ld	s2,16(sp)
    8000275a:	69a2                	ld	s3,8(sp)
    8000275c:	6a02                	ld	s4,0(sp)
    8000275e:	6145                	addi	sp,sp,48
    80002760:	8082                	ret

0000000080002762 <getmsk>:

int getmsk(int pid)
{
    80002762:	7179                	addi	sp,sp,-48
    80002764:	f406                	sd	ra,40(sp)
    80002766:	f022                	sd	s0,32(sp)
    80002768:	ec26                	sd	s1,24(sp)
    8000276a:	e84a                	sd	s2,16(sp)
    8000276c:	e44e                	sd	s3,8(sp)
    8000276e:	1800                	addi	s0,sp,48
    80002770:	892a                	mv	s2,a0
	struct proc *p;
	int mask;

	for (p = proc; p < &proc[NPROC]; p++)
    80002772:	0000f497          	auipc	s1,0xf
    80002776:	f7648493          	addi	s1,s1,-138 # 800116e8 <proc>
    8000277a:	00015997          	auipc	s3,0x15
    8000277e:	16e98993          	addi	s3,s3,366 # 800178e8 <tickslock>
	{
		acquire(&p->lock);
    80002782:	8526                	mv	a0,s1
    80002784:	ffffe097          	auipc	ra,0xffffe
    80002788:	43e080e7          	jalr	1086(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    8000278c:	589c                	lw	a5,48(s1)
    8000278e:	01278d63          	beq	a5,s2,800027a8 <getmsk+0x46>
		{
			mask = p->trace_mask;
			release(&p->lock);
			return mask;
		}
		release(&p->lock);
    80002792:	8526                	mv	a0,s1
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	4e2080e7          	jalr	1250(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    8000279c:	18848493          	addi	s1,s1,392
    800027a0:	ff3491e3          	bne	s1,s3,80002782 <getmsk+0x20>
	}

	return -1;
    800027a4:	597d                	li	s2,-1
    800027a6:	a801                	j	800027b6 <getmsk+0x54>
			mask = p->trace_mask;
    800027a8:	0344a903          	lw	s2,52(s1)
			release(&p->lock);
    800027ac:	8526                	mv	a0,s1
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	4c8080e7          	jalr	1224(ra) # 80000c76 <release>
}
    800027b6:	854a                	mv	a0,s2
    800027b8:	70a2                	ld	ra,40(sp)
    800027ba:	7402                	ld	s0,32(sp)
    800027bc:	64e2                	ld	s1,24(sp)
    800027be:	6942                	ld	s2,16(sp)
    800027c0:	69a2                	ld	s3,8(sp)
    800027c2:	6145                	addi	sp,sp,48
    800027c4:	8082                	ret

00000000800027c6 <update_perf>:
	}
}

// ADDED
void update_perf(uint ticks, struct proc *p)
{
    800027c6:	1141                	addi	sp,sp,-16
    800027c8:	e422                	sd	s0,8(sp)
    800027ca:	0800                	addi	s0,sp,16
	switch (p->state)
    800027cc:	4d9c                	lw	a5,24(a1)
    800027ce:	4711                	li	a4,4
    800027d0:	02e78763          	beq	a5,a4,800027fe <update_perf+0x38>
    800027d4:	00f76c63          	bltu	a4,a5,800027ec <update_perf+0x26>
    800027d8:	4709                	li	a4,2
    800027da:	02e78863          	beq	a5,a4,8000280a <update_perf+0x44>
    800027de:	470d                	li	a4,3
    800027e0:	02e79263          	bne	a5,a4,80002804 <update_perf+0x3e>
		break;
	case SLEEPING:
		p->performance.stime++;
		break;
	case RUNNABLE:
		p->performance.retime++;
    800027e4:	41fc                	lw	a5,68(a1)
    800027e6:	2785                	addiw	a5,a5,1
    800027e8:	c1fc                	sw	a5,68(a1)
		break;
    800027ea:	a829                	j	80002804 <update_perf+0x3e>
	switch (p->state)
    800027ec:	4715                	li	a4,5
    800027ee:	00e79b63          	bne	a5,a4,80002804 <update_perf+0x3e>
	case ZOMBIE:
		if (p->performance.ttime == -1)
    800027f2:	5dd8                	lw	a4,60(a1)
    800027f4:	57fd                	li	a5,-1
    800027f6:	00f71763          	bne	a4,a5,80002804 <update_perf+0x3e>
			p->performance.ttime = ticks;
    800027fa:	ddc8                	sw	a0,60(a1)
		break;
	default:
		break;
	}
}
    800027fc:	a021                	j	80002804 <update_perf+0x3e>
		p->performance.rutime++;
    800027fe:	45bc                	lw	a5,72(a1)
    80002800:	2785                	addiw	a5,a5,1
    80002802:	c5bc                	sw	a5,72(a1)
}
    80002804:	6422                	ld	s0,8(sp)
    80002806:	0141                	addi	sp,sp,16
    80002808:	8082                	ret
		p->performance.stime++;
    8000280a:	41bc                	lw	a5,64(a1)
    8000280c:	2785                	addiw	a5,a5,1
    8000280e:	c1bc                	sw	a5,64(a1)
		break;
    80002810:	bfd5                	j	80002804 <update_perf+0x3e>

0000000080002812 <wait_stat>:
{
    80002812:	711d                	addi	sp,sp,-96
    80002814:	ec86                	sd	ra,88(sp)
    80002816:	e8a2                	sd	s0,80(sp)
    80002818:	e4a6                	sd	s1,72(sp)
    8000281a:	e0ca                	sd	s2,64(sp)
    8000281c:	fc4e                	sd	s3,56(sp)
    8000281e:	f852                	sd	s4,48(sp)
    80002820:	f456                	sd	s5,40(sp)
    80002822:	f05a                	sd	s6,32(sp)
    80002824:	ec5e                	sd	s7,24(sp)
    80002826:	e862                	sd	s8,16(sp)
    80002828:	e466                	sd	s9,8(sp)
    8000282a:	1080                	addi	s0,sp,96
    8000282c:	8b2a                	mv	s6,a0
    8000282e:	8bae                	mv	s7,a1
	struct proc *p = myproc();
    80002830:	fffff097          	auipc	ra,0xfffff
    80002834:	192080e7          	jalr	402(ra) # 800019c2 <myproc>
    80002838:	892a                	mv	s2,a0
	acquire(&wait_lock);
    8000283a:	0000f517          	auipc	a0,0xf
    8000283e:	a9650513          	addi	a0,a0,-1386 # 800112d0 <wait_lock>
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	380080e7          	jalr	896(ra) # 80000bc2 <acquire>
		havekids = 0;
    8000284a:	4c01                	li	s8,0
				if (np->state == ZOMBIE)
    8000284c:	4a15                	li	s4,5
				havekids = 1;
    8000284e:	4a85                	li	s5,1
		for (np = proc; np < &proc[NPROC]; np++)
    80002850:	00015997          	auipc	s3,0x15
    80002854:	09898993          	addi	s3,s3,152 # 800178e8 <tickslock>
		sleep(p, &wait_lock); //DOC: wait-sleep
    80002858:	0000fc97          	auipc	s9,0xf
    8000285c:	a78c8c93          	addi	s9,s9,-1416 # 800112d0 <wait_lock>
		havekids = 0;
    80002860:	8762                	mv	a4,s8
		for (np = proc; np < &proc[NPROC]; np++)
    80002862:	0000f497          	auipc	s1,0xf
    80002866:	e8648493          	addi	s1,s1,-378 # 800116e8 <proc>
    8000286a:	a85d                	j	80002920 <wait_stat+0x10e>
					pid = np->pid;
    8000286c:	0304a983          	lw	s3,48(s1)
					update_perf(ticks, np);
    80002870:	85a6                	mv	a1,s1
    80002872:	00006517          	auipc	a0,0x6
    80002876:	7be52503          	lw	a0,1982(a0) # 80009030 <ticks>
    8000287a:	00000097          	auipc	ra,0x0
    8000287e:	f4c080e7          	jalr	-180(ra) # 800027c6 <update_perf>
					if (status != 0 && copyout(p->pagetable, status, (char *)&np->xstate,
    80002882:	000b0e63          	beqz	s6,8000289e <wait_stat+0x8c>
    80002886:	4691                	li	a3,4
    80002888:	02c48613          	addi	a2,s1,44
    8000288c:	85da                	mv	a1,s6
    8000288e:	07093503          	ld	a0,112(s2)
    80002892:	fffff097          	auipc	ra,0xfffff
    80002896:	dac080e7          	jalr	-596(ra) # 8000163e <copyout>
    8000289a:	04054163          	bltz	a0,800028dc <wait_stat+0xca>
					if (copyout(p->pagetable, performance, (char *)&(np->performance), sizeof(struct perf)) < 0)
    8000289e:	46e1                	li	a3,24
    800028a0:	03848613          	addi	a2,s1,56
    800028a4:	85de                	mv	a1,s7
    800028a6:	07093503          	ld	a0,112(s2)
    800028aa:	fffff097          	auipc	ra,0xfffff
    800028ae:	d94080e7          	jalr	-620(ra) # 8000163e <copyout>
    800028b2:	04054463          	bltz	a0,800028fa <wait_stat+0xe8>
					freeproc(np);
    800028b6:	8526                	mv	a0,s1
    800028b8:	fffff097          	auipc	ra,0xfffff
    800028bc:	2bc080e7          	jalr	700(ra) # 80001b74 <freeproc>
					release(&np->lock);
    800028c0:	8526                	mv	a0,s1
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	3b4080e7          	jalr	948(ra) # 80000c76 <release>
					release(&wait_lock);
    800028ca:	0000f517          	auipc	a0,0xf
    800028ce:	a0650513          	addi	a0,a0,-1530 # 800112d0 <wait_lock>
    800028d2:	ffffe097          	auipc	ra,0xffffe
    800028d6:	3a4080e7          	jalr	932(ra) # 80000c76 <release>
					return pid;
    800028da:	a051                	j	8000295e <wait_stat+0x14c>
						release(&np->lock);
    800028dc:	8526                	mv	a0,s1
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	398080e7          	jalr	920(ra) # 80000c76 <release>
						release(&wait_lock);
    800028e6:	0000f517          	auipc	a0,0xf
    800028ea:	9ea50513          	addi	a0,a0,-1558 # 800112d0 <wait_lock>
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	388080e7          	jalr	904(ra) # 80000c76 <release>
						return -1;
    800028f6:	59fd                	li	s3,-1
    800028f8:	a09d                	j	8000295e <wait_stat+0x14c>
						release(&np->lock);
    800028fa:	8526                	mv	a0,s1
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	37a080e7          	jalr	890(ra) # 80000c76 <release>
						release(&wait_lock);
    80002904:	0000f517          	auipc	a0,0xf
    80002908:	9cc50513          	addi	a0,a0,-1588 # 800112d0 <wait_lock>
    8000290c:	ffffe097          	auipc	ra,0xffffe
    80002910:	36a080e7          	jalr	874(ra) # 80000c76 <release>
						return -1;
    80002914:	59fd                	li	s3,-1
    80002916:	a0a1                	j	8000295e <wait_stat+0x14c>
		for (np = proc; np < &proc[NPROC]; np++)
    80002918:	18848493          	addi	s1,s1,392
    8000291c:	03348463          	beq	s1,s3,80002944 <wait_stat+0x132>
			if (np->parent == p)
    80002920:	6cbc                	ld	a5,88(s1)
    80002922:	ff279be3          	bne	a5,s2,80002918 <wait_stat+0x106>
				acquire(&np->lock);
    80002926:	8526                	mv	a0,s1
    80002928:	ffffe097          	auipc	ra,0xffffe
    8000292c:	29a080e7          	jalr	666(ra) # 80000bc2 <acquire>
				if (np->state == ZOMBIE)
    80002930:	4c9c                	lw	a5,24(s1)
    80002932:	f3478de3          	beq	a5,s4,8000286c <wait_stat+0x5a>
				release(&np->lock);
    80002936:	8526                	mv	a0,s1
    80002938:	ffffe097          	auipc	ra,0xffffe
    8000293c:	33e080e7          	jalr	830(ra) # 80000c76 <release>
				havekids = 1;
    80002940:	8756                	mv	a4,s5
    80002942:	bfd9                	j	80002918 <wait_stat+0x106>
		if (!havekids || p->killed)
    80002944:	c701                	beqz	a4,8000294c <wait_stat+0x13a>
    80002946:	02892783          	lw	a5,40(s2)
    8000294a:	cb85                	beqz	a5,8000297a <wait_stat+0x168>
			release(&wait_lock);
    8000294c:	0000f517          	auipc	a0,0xf
    80002950:	98450513          	addi	a0,a0,-1660 # 800112d0 <wait_lock>
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	322080e7          	jalr	802(ra) # 80000c76 <release>
			return -1;
    8000295c:	59fd                	li	s3,-1
}
    8000295e:	854e                	mv	a0,s3
    80002960:	60e6                	ld	ra,88(sp)
    80002962:	6446                	ld	s0,80(sp)
    80002964:	64a6                	ld	s1,72(sp)
    80002966:	6906                	ld	s2,64(sp)
    80002968:	79e2                	ld	s3,56(sp)
    8000296a:	7a42                	ld	s4,48(sp)
    8000296c:	7aa2                	ld	s5,40(sp)
    8000296e:	7b02                	ld	s6,32(sp)
    80002970:	6be2                	ld	s7,24(sp)
    80002972:	6c42                	ld	s8,16(sp)
    80002974:	6ca2                	ld	s9,8(sp)
    80002976:	6125                	addi	sp,sp,96
    80002978:	8082                	ret
		sleep(p, &wait_lock); //DOC: wait-sleep
    8000297a:	85e6                	mv	a1,s9
    8000297c:	854a                	mv	a0,s2
    8000297e:	00000097          	auipc	ra,0x0
    80002982:	870080e7          	jalr	-1936(ra) # 800021ee <sleep>
		havekids = 0;
    80002986:	bde9                	j	80002860 <wait_stat+0x4e>

0000000080002988 <update_perfs>:

// ADDED
void update_perfs(uint ticks)
{
    80002988:	7179                	addi	sp,sp,-48
    8000298a:	f406                	sd	ra,40(sp)
    8000298c:	f022                	sd	s0,32(sp)
    8000298e:	ec26                	sd	s1,24(sp)
    80002990:	e84a                	sd	s2,16(sp)
    80002992:	e44e                	sd	s3,8(sp)
    80002994:	1800                	addi	s0,sp,48
    80002996:	892a                	mv	s2,a0
	struct proc *p;
	for (p = proc; p < &proc[NPROC]; p++)
    80002998:	0000f497          	auipc	s1,0xf
    8000299c:	d5048493          	addi	s1,s1,-688 # 800116e8 <proc>
    800029a0:	00015997          	auipc	s3,0x15
    800029a4:	f4898993          	addi	s3,s3,-184 # 800178e8 <tickslock>
	{
		acquire(&p->lock);
    800029a8:	8526                	mv	a0,s1
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	218080e7          	jalr	536(ra) # 80000bc2 <acquire>
		update_perf(ticks, p);
    800029b2:	85a6                	mv	a1,s1
    800029b4:	854a                	mv	a0,s2
    800029b6:	00000097          	auipc	ra,0x0
    800029ba:	e10080e7          	jalr	-496(ra) # 800027c6 <update_perf>
		release(&p->lock);
    800029be:	8526                	mv	a0,s1
    800029c0:	ffffe097          	auipc	ra,0xffffe
    800029c4:	2b6080e7          	jalr	694(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    800029c8:	18848493          	addi	s1,s1,392
    800029cc:	fd349ee3          	bne	s1,s3,800029a8 <update_perfs+0x20>
	}
    800029d0:	70a2                	ld	ra,40(sp)
    800029d2:	7402                	ld	s0,32(sp)
    800029d4:	64e2                	ld	s1,24(sp)
    800029d6:	6942                	ld	s2,16(sp)
    800029d8:	69a2                	ld	s3,8(sp)
    800029da:	6145                	addi	sp,sp,48
    800029dc:	8082                	ret

00000000800029de <swtch>:
    800029de:	00153023          	sd	ra,0(a0)
    800029e2:	00253423          	sd	sp,8(a0)
    800029e6:	e900                	sd	s0,16(a0)
    800029e8:	ed04                	sd	s1,24(a0)
    800029ea:	03253023          	sd	s2,32(a0)
    800029ee:	03353423          	sd	s3,40(a0)
    800029f2:	03453823          	sd	s4,48(a0)
    800029f6:	03553c23          	sd	s5,56(a0)
    800029fa:	05653023          	sd	s6,64(a0)
    800029fe:	05753423          	sd	s7,72(a0)
    80002a02:	05853823          	sd	s8,80(a0)
    80002a06:	05953c23          	sd	s9,88(a0)
    80002a0a:	07a53023          	sd	s10,96(a0)
    80002a0e:	07b53423          	sd	s11,104(a0)
    80002a12:	0005b083          	ld	ra,0(a1)
    80002a16:	0085b103          	ld	sp,8(a1)
    80002a1a:	6980                	ld	s0,16(a1)
    80002a1c:	6d84                	ld	s1,24(a1)
    80002a1e:	0205b903          	ld	s2,32(a1)
    80002a22:	0285b983          	ld	s3,40(a1)
    80002a26:	0305ba03          	ld	s4,48(a1)
    80002a2a:	0385ba83          	ld	s5,56(a1)
    80002a2e:	0405bb03          	ld	s6,64(a1)
    80002a32:	0485bb83          	ld	s7,72(a1)
    80002a36:	0505bc03          	ld	s8,80(a1)
    80002a3a:	0585bc83          	ld	s9,88(a1)
    80002a3e:	0605bd03          	ld	s10,96(a1)
    80002a42:	0685bd83          	ld	s11,104(a1)
    80002a46:	8082                	ret

0000000080002a48 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a48:	1141                	addi	sp,sp,-16
    80002a4a:	e406                	sd	ra,8(sp)
    80002a4c:	e022                	sd	s0,0(sp)
    80002a4e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a50:	00006597          	auipc	a1,0x6
    80002a54:	8e058593          	addi	a1,a1,-1824 # 80008330 <states.0+0x30>
    80002a58:	00015517          	auipc	a0,0x15
    80002a5c:	e9050513          	addi	a0,a0,-368 # 800178e8 <tickslock>
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	0d2080e7          	jalr	210(ra) # 80000b32 <initlock>
}
    80002a68:	60a2                	ld	ra,8(sp)
    80002a6a:	6402                	ld	s0,0(sp)
    80002a6c:	0141                	addi	sp,sp,16
    80002a6e:	8082                	ret

0000000080002a70 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a70:	1141                	addi	sp,sp,-16
    80002a72:	e422                	sd	s0,8(sp)
    80002a74:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a76:	00003797          	auipc	a5,0x3
    80002a7a:	5ea78793          	addi	a5,a5,1514 # 80006060 <kernelvec>
    80002a7e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a82:	6422                	ld	s0,8(sp)
    80002a84:	0141                	addi	sp,sp,16
    80002a86:	8082                	ret

0000000080002a88 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a88:	1141                	addi	sp,sp,-16
    80002a8a:	e406                	sd	ra,8(sp)
    80002a8c:	e022                	sd	s0,0(sp)
    80002a8e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a90:	fffff097          	auipc	ra,0xfffff
    80002a94:	f32080e7          	jalr	-206(ra) # 800019c2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a9e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002aa2:	00004617          	auipc	a2,0x4
    80002aa6:	55e60613          	addi	a2,a2,1374 # 80007000 <_trampoline>
    80002aaa:	00004697          	auipc	a3,0x4
    80002aae:	55668693          	addi	a3,a3,1366 # 80007000 <_trampoline>
    80002ab2:	8e91                	sub	a3,a3,a2
    80002ab4:	040007b7          	lui	a5,0x4000
    80002ab8:	17fd                	addi	a5,a5,-1
    80002aba:	07b2                	slli	a5,a5,0xc
    80002abc:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002abe:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ac2:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ac4:	180026f3          	csrr	a3,satp
    80002ac8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002aca:	7d38                	ld	a4,120(a0)
    80002acc:	7134                	ld	a3,96(a0)
    80002ace:	6585                	lui	a1,0x1
    80002ad0:	96ae                	add	a3,a3,a1
    80002ad2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ad4:	7d38                	ld	a4,120(a0)
    80002ad6:	00000697          	auipc	a3,0x0
    80002ada:	14868693          	addi	a3,a3,328 # 80002c1e <usertrap>
    80002ade:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002ae0:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ae2:	8692                	mv	a3,tp
    80002ae4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ae6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002aea:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002aee:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002af2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002af6:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002af8:	6f18                	ld	a4,24(a4)
    80002afa:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002afe:	792c                	ld	a1,112(a0)
    80002b00:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002b02:	00004717          	auipc	a4,0x4
    80002b06:	58e70713          	addi	a4,a4,1422 # 80007090 <userret>
    80002b0a:	8f11                	sub	a4,a4,a2
    80002b0c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002b0e:	577d                	li	a4,-1
    80002b10:	177e                	slli	a4,a4,0x3f
    80002b12:	8dd9                	or	a1,a1,a4
    80002b14:	02000537          	lui	a0,0x2000
    80002b18:	157d                	addi	a0,a0,-1
    80002b1a:	0536                	slli	a0,a0,0xd
    80002b1c:	9782                	jalr	a5
}
    80002b1e:	60a2                	ld	ra,8(sp)
    80002b20:	6402                	ld	s0,0(sp)
    80002b22:	0141                	addi	sp,sp,16
    80002b24:	8082                	ret

0000000080002b26 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b26:	1101                	addi	sp,sp,-32
    80002b28:	ec06                	sd	ra,24(sp)
    80002b2a:	e822                	sd	s0,16(sp)
    80002b2c:	e426                	sd	s1,8(sp)
    80002b2e:	e04a                	sd	s2,0(sp)
    80002b30:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b32:	00015917          	auipc	s2,0x15
    80002b36:	db690913          	addi	s2,s2,-586 # 800178e8 <tickslock>
    80002b3a:	854a                	mv	a0,s2
    80002b3c:	ffffe097          	auipc	ra,0xffffe
    80002b40:	086080e7          	jalr	134(ra) # 80000bc2 <acquire>
  ticks++;
    80002b44:	00006497          	auipc	s1,0x6
    80002b48:	4ec48493          	addi	s1,s1,1260 # 80009030 <ticks>
    80002b4c:	4088                	lw	a0,0(s1)
    80002b4e:	2505                	addiw	a0,a0,1
    80002b50:	c088                	sw	a0,0(s1)
  update_perfs(ticks);
    80002b52:	2501                	sext.w	a0,a0
    80002b54:	00000097          	auipc	ra,0x0
    80002b58:	e34080e7          	jalr	-460(ra) # 80002988 <update_perfs>
  wakeup(&ticks);
    80002b5c:	8526                	mv	a0,s1
    80002b5e:	00000097          	auipc	ra,0x0
    80002b62:	81c080e7          	jalr	-2020(ra) # 8000237a <wakeup>
  release(&tickslock);
    80002b66:	854a                	mv	a0,s2
    80002b68:	ffffe097          	auipc	ra,0xffffe
    80002b6c:	10e080e7          	jalr	270(ra) # 80000c76 <release>
}
    80002b70:	60e2                	ld	ra,24(sp)
    80002b72:	6442                	ld	s0,16(sp)
    80002b74:	64a2                	ld	s1,8(sp)
    80002b76:	6902                	ld	s2,0(sp)
    80002b78:	6105                	addi	sp,sp,32
    80002b7a:	8082                	ret

0000000080002b7c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b7c:	1101                	addi	sp,sp,-32
    80002b7e:	ec06                	sd	ra,24(sp)
    80002b80:	e822                	sd	s0,16(sp)
    80002b82:	e426                	sd	s1,8(sp)
    80002b84:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b86:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b8a:	00074d63          	bltz	a4,80002ba4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b8e:	57fd                	li	a5,-1
    80002b90:	17fe                	slli	a5,a5,0x3f
    80002b92:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b94:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b96:	06f70363          	beq	a4,a5,80002bfc <devintr+0x80>
  }
}
    80002b9a:	60e2                	ld	ra,24(sp)
    80002b9c:	6442                	ld	s0,16(sp)
    80002b9e:	64a2                	ld	s1,8(sp)
    80002ba0:	6105                	addi	sp,sp,32
    80002ba2:	8082                	ret
     (scause & 0xff) == 9){
    80002ba4:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ba8:	46a5                	li	a3,9
    80002baa:	fed792e3          	bne	a5,a3,80002b8e <devintr+0x12>
    int irq = plic_claim();
    80002bae:	00003097          	auipc	ra,0x3
    80002bb2:	5ba080e7          	jalr	1466(ra) # 80006168 <plic_claim>
    80002bb6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002bb8:	47a9                	li	a5,10
    80002bba:	02f50763          	beq	a0,a5,80002be8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002bbe:	4785                	li	a5,1
    80002bc0:	02f50963          	beq	a0,a5,80002bf2 <devintr+0x76>
    return 1;
    80002bc4:	4505                	li	a0,1
    } else if(irq){
    80002bc6:	d8f1                	beqz	s1,80002b9a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002bc8:	85a6                	mv	a1,s1
    80002bca:	00005517          	auipc	a0,0x5
    80002bce:	76e50513          	addi	a0,a0,1902 # 80008338 <states.0+0x38>
    80002bd2:	ffffe097          	auipc	ra,0xffffe
    80002bd6:	9a2080e7          	jalr	-1630(ra) # 80000574 <printf>
      plic_complete(irq);
    80002bda:	8526                	mv	a0,s1
    80002bdc:	00003097          	auipc	ra,0x3
    80002be0:	5b0080e7          	jalr	1456(ra) # 8000618c <plic_complete>
    return 1;
    80002be4:	4505                	li	a0,1
    80002be6:	bf55                	j	80002b9a <devintr+0x1e>
      uartintr();
    80002be8:	ffffe097          	auipc	ra,0xffffe
    80002bec:	d9e080e7          	jalr	-610(ra) # 80000986 <uartintr>
    80002bf0:	b7ed                	j	80002bda <devintr+0x5e>
      virtio_disk_intr();
    80002bf2:	00004097          	auipc	ra,0x4
    80002bf6:	a2c080e7          	jalr	-1492(ra) # 8000661e <virtio_disk_intr>
    80002bfa:	b7c5                	j	80002bda <devintr+0x5e>
    if(cpuid() == 0){
    80002bfc:	fffff097          	auipc	ra,0xfffff
    80002c00:	d9a080e7          	jalr	-614(ra) # 80001996 <cpuid>
    80002c04:	c901                	beqz	a0,80002c14 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c06:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c0a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c0c:	14479073          	csrw	sip,a5
    return 2;
    80002c10:	4509                	li	a0,2
    80002c12:	b761                	j	80002b9a <devintr+0x1e>
      clockintr();
    80002c14:	00000097          	auipc	ra,0x0
    80002c18:	f12080e7          	jalr	-238(ra) # 80002b26 <clockintr>
    80002c1c:	b7ed                	j	80002c06 <devintr+0x8a>

0000000080002c1e <usertrap>:
{
    80002c1e:	1101                	addi	sp,sp,-32
    80002c20:	ec06                	sd	ra,24(sp)
    80002c22:	e822                	sd	s0,16(sp)
    80002c24:	e426                	sd	s1,8(sp)
    80002c26:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c28:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c2c:	1007f793          	andi	a5,a5,256
    80002c30:	e3a5                	bnez	a5,80002c90 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c32:	00003797          	auipc	a5,0x3
    80002c36:	42e78793          	addi	a5,a5,1070 # 80006060 <kernelvec>
    80002c3a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c3e:	fffff097          	auipc	ra,0xfffff
    80002c42:	d84080e7          	jalr	-636(ra) # 800019c2 <myproc>
    80002c46:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c48:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c4a:	14102773          	csrr	a4,sepc
    80002c4e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c50:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c54:	47a1                	li	a5,8
    80002c56:	04f71b63          	bne	a4,a5,80002cac <usertrap+0x8e>
    if(p->killed)
    80002c5a:	551c                	lw	a5,40(a0)
    80002c5c:	e3b1                	bnez	a5,80002ca0 <usertrap+0x82>
    p->trapframe->epc += 4;
    80002c5e:	7cb8                	ld	a4,120(s1)
    80002c60:	6f1c                	ld	a5,24(a4)
    80002c62:	0791                	addi	a5,a5,4
    80002c64:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c66:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c6a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c6e:	10079073          	csrw	sstatus,a5
    syscall();
    80002c72:	00000097          	auipc	ra,0x0
    80002c76:	366080e7          	jalr	870(ra) # 80002fd8 <syscall>
  if(p->killed)
    80002c7a:	549c                	lw	a5,40(s1)
    80002c7c:	e7b5                	bnez	a5,80002ce8 <usertrap+0xca>
  usertrapret();
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	e0a080e7          	jalr	-502(ra) # 80002a88 <usertrapret>
}
    80002c86:	60e2                	ld	ra,24(sp)
    80002c88:	6442                	ld	s0,16(sp)
    80002c8a:	64a2                	ld	s1,8(sp)
    80002c8c:	6105                	addi	sp,sp,32
    80002c8e:	8082                	ret
    panic("usertrap: not from user mode");
    80002c90:	00005517          	auipc	a0,0x5
    80002c94:	6c850513          	addi	a0,a0,1736 # 80008358 <states.0+0x58>
    80002c98:	ffffe097          	auipc	ra,0xffffe
    80002c9c:	892080e7          	jalr	-1902(ra) # 8000052a <panic>
      exit(-1);
    80002ca0:	557d                	li	a0,-1
    80002ca2:	fffff097          	auipc	ra,0xfffff
    80002ca6:	7b2080e7          	jalr	1970(ra) # 80002454 <exit>
    80002caa:	bf55                	j	80002c5e <usertrap+0x40>
  } else if((which_dev = devintr()) != 0){
    80002cac:	00000097          	auipc	ra,0x0
    80002cb0:	ed0080e7          	jalr	-304(ra) # 80002b7c <devintr>
    80002cb4:	f179                	bnez	a0,80002c7a <usertrap+0x5c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cb6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cba:	5890                	lw	a2,48(s1)
    80002cbc:	00005517          	auipc	a0,0x5
    80002cc0:	6bc50513          	addi	a0,a0,1724 # 80008378 <states.0+0x78>
    80002cc4:	ffffe097          	auipc	ra,0xffffe
    80002cc8:	8b0080e7          	jalr	-1872(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ccc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cd0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cd4:	00005517          	auipc	a0,0x5
    80002cd8:	6d450513          	addi	a0,a0,1748 # 800083a8 <states.0+0xa8>
    80002cdc:	ffffe097          	auipc	ra,0xffffe
    80002ce0:	898080e7          	jalr	-1896(ra) # 80000574 <printf>
    p->killed = 1;
    80002ce4:	4785                	li	a5,1
    80002ce6:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002ce8:	557d                	li	a0,-1
    80002cea:	fffff097          	auipc	ra,0xfffff
    80002cee:	76a080e7          	jalr	1898(ra) # 80002454 <exit>
    80002cf2:	b771                	j	80002c7e <usertrap+0x60>

0000000080002cf4 <kerneltrap>:
{
    80002cf4:	7179                	addi	sp,sp,-48
    80002cf6:	f406                	sd	ra,40(sp)
    80002cf8:	f022                	sd	s0,32(sp)
    80002cfa:	ec26                	sd	s1,24(sp)
    80002cfc:	e84a                	sd	s2,16(sp)
    80002cfe:	e44e                	sd	s3,8(sp)
    80002d00:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d02:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d06:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d0a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d0e:	1004f793          	andi	a5,s1,256
    80002d12:	c78d                	beqz	a5,80002d3c <kerneltrap+0x48>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d14:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d18:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d1a:	eb8d                	bnez	a5,80002d4c <kerneltrap+0x58>
  if((which_dev = devintr()) == 0){
    80002d1c:	00000097          	auipc	ra,0x0
    80002d20:	e60080e7          	jalr	-416(ra) # 80002b7c <devintr>
    80002d24:	cd05                	beqz	a0,80002d5c <kerneltrap+0x68>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d26:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d2a:	10049073          	csrw	sstatus,s1
}
    80002d2e:	70a2                	ld	ra,40(sp)
    80002d30:	7402                	ld	s0,32(sp)
    80002d32:	64e2                	ld	s1,24(sp)
    80002d34:	6942                	ld	s2,16(sp)
    80002d36:	69a2                	ld	s3,8(sp)
    80002d38:	6145                	addi	sp,sp,48
    80002d3a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d3c:	00005517          	auipc	a0,0x5
    80002d40:	68c50513          	addi	a0,a0,1676 # 800083c8 <states.0+0xc8>
    80002d44:	ffffd097          	auipc	ra,0xffffd
    80002d48:	7e6080e7          	jalr	2022(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002d4c:	00005517          	auipc	a0,0x5
    80002d50:	6a450513          	addi	a0,a0,1700 # 800083f0 <states.0+0xf0>
    80002d54:	ffffd097          	auipc	ra,0xffffd
    80002d58:	7d6080e7          	jalr	2006(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002d5c:	85ce                	mv	a1,s3
    80002d5e:	00005517          	auipc	a0,0x5
    80002d62:	6b250513          	addi	a0,a0,1714 # 80008410 <states.0+0x110>
    80002d66:	ffffe097          	auipc	ra,0xffffe
    80002d6a:	80e080e7          	jalr	-2034(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d6e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d72:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d76:	00005517          	auipc	a0,0x5
    80002d7a:	6aa50513          	addi	a0,a0,1706 # 80008420 <states.0+0x120>
    80002d7e:	ffffd097          	auipc	ra,0xffffd
    80002d82:	7f6080e7          	jalr	2038(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002d86:	00005517          	auipc	a0,0x5
    80002d8a:	6b250513          	addi	a0,a0,1714 # 80008438 <states.0+0x138>
    80002d8e:	ffffd097          	auipc	ra,0xffffd
    80002d92:	79c080e7          	jalr	1948(ra) # 8000052a <panic>

0000000080002d96 <argraw>:
	return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d96:	1101                	addi	sp,sp,-32
    80002d98:	ec06                	sd	ra,24(sp)
    80002d9a:	e822                	sd	s0,16(sp)
    80002d9c:	e426                	sd	s1,8(sp)
    80002d9e:	1000                	addi	s0,sp,32
    80002da0:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    80002da2:	fffff097          	auipc	ra,0xfffff
    80002da6:	c20080e7          	jalr	-992(ra) # 800019c2 <myproc>
	switch (n)
    80002daa:	4795                	li	a5,5
    80002dac:	0497e163          	bltu	a5,s1,80002dee <argraw+0x58>
    80002db0:	048a                	slli	s1,s1,0x2
    80002db2:	00005717          	auipc	a4,0x5
    80002db6:	7d670713          	addi	a4,a4,2006 # 80008588 <states.0+0x288>
    80002dba:	94ba                	add	s1,s1,a4
    80002dbc:	409c                	lw	a5,0(s1)
    80002dbe:	97ba                	add	a5,a5,a4
    80002dc0:	8782                	jr	a5
	{
	case 0:
		return p->trapframe->a0;
    80002dc2:	7d3c                	ld	a5,120(a0)
    80002dc4:	7ba8                	ld	a0,112(a5)
	case 5:
		return p->trapframe->a5;
	}
	panic("argraw");
	return -1;
}
    80002dc6:	60e2                	ld	ra,24(sp)
    80002dc8:	6442                	ld	s0,16(sp)
    80002dca:	64a2                	ld	s1,8(sp)
    80002dcc:	6105                	addi	sp,sp,32
    80002dce:	8082                	ret
		return p->trapframe->a1;
    80002dd0:	7d3c                	ld	a5,120(a0)
    80002dd2:	7fa8                	ld	a0,120(a5)
    80002dd4:	bfcd                	j	80002dc6 <argraw+0x30>
		return p->trapframe->a2;
    80002dd6:	7d3c                	ld	a5,120(a0)
    80002dd8:	63c8                	ld	a0,128(a5)
    80002dda:	b7f5                	j	80002dc6 <argraw+0x30>
		return p->trapframe->a3;
    80002ddc:	7d3c                	ld	a5,120(a0)
    80002dde:	67c8                	ld	a0,136(a5)
    80002de0:	b7dd                	j	80002dc6 <argraw+0x30>
		return p->trapframe->a4;
    80002de2:	7d3c                	ld	a5,120(a0)
    80002de4:	6bc8                	ld	a0,144(a5)
    80002de6:	b7c5                	j	80002dc6 <argraw+0x30>
		return p->trapframe->a5;
    80002de8:	7d3c                	ld	a5,120(a0)
    80002dea:	6fc8                	ld	a0,152(a5)
    80002dec:	bfe9                	j	80002dc6 <argraw+0x30>
	panic("argraw");
    80002dee:	00005517          	auipc	a0,0x5
    80002df2:	65a50513          	addi	a0,a0,1626 # 80008448 <states.0+0x148>
    80002df6:	ffffd097          	auipc	ra,0xffffd
    80002dfa:	734080e7          	jalr	1844(ra) # 8000052a <panic>

0000000080002dfe <fetchaddr>:
{
    80002dfe:	1101                	addi	sp,sp,-32
    80002e00:	ec06                	sd	ra,24(sp)
    80002e02:	e822                	sd	s0,16(sp)
    80002e04:	e426                	sd	s1,8(sp)
    80002e06:	e04a                	sd	s2,0(sp)
    80002e08:	1000                	addi	s0,sp,32
    80002e0a:	84aa                	mv	s1,a0
    80002e0c:	892e                	mv	s2,a1
	struct proc *p = myproc();
    80002e0e:	fffff097          	auipc	ra,0xfffff
    80002e12:	bb4080e7          	jalr	-1100(ra) # 800019c2 <myproc>
	if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002e16:	753c                	ld	a5,104(a0)
    80002e18:	02f4f863          	bgeu	s1,a5,80002e48 <fetchaddr+0x4a>
    80002e1c:	00848713          	addi	a4,s1,8
    80002e20:	02e7e663          	bltu	a5,a4,80002e4c <fetchaddr+0x4e>
	if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e24:	46a1                	li	a3,8
    80002e26:	8626                	mv	a2,s1
    80002e28:	85ca                	mv	a1,s2
    80002e2a:	7928                	ld	a0,112(a0)
    80002e2c:	fffff097          	auipc	ra,0xfffff
    80002e30:	89e080e7          	jalr	-1890(ra) # 800016ca <copyin>
    80002e34:	00a03533          	snez	a0,a0
    80002e38:	40a00533          	neg	a0,a0
}
    80002e3c:	60e2                	ld	ra,24(sp)
    80002e3e:	6442                	ld	s0,16(sp)
    80002e40:	64a2                	ld	s1,8(sp)
    80002e42:	6902                	ld	s2,0(sp)
    80002e44:	6105                	addi	sp,sp,32
    80002e46:	8082                	ret
		return -1;
    80002e48:	557d                	li	a0,-1
    80002e4a:	bfcd                	j	80002e3c <fetchaddr+0x3e>
    80002e4c:	557d                	li	a0,-1
    80002e4e:	b7fd                	j	80002e3c <fetchaddr+0x3e>

0000000080002e50 <fetchstr>:
{
    80002e50:	7179                	addi	sp,sp,-48
    80002e52:	f406                	sd	ra,40(sp)
    80002e54:	f022                	sd	s0,32(sp)
    80002e56:	ec26                	sd	s1,24(sp)
    80002e58:	e84a                	sd	s2,16(sp)
    80002e5a:	e44e                	sd	s3,8(sp)
    80002e5c:	1800                	addi	s0,sp,48
    80002e5e:	892a                	mv	s2,a0
    80002e60:	84ae                	mv	s1,a1
    80002e62:	89b2                	mv	s3,a2
	struct proc *p = myproc();
    80002e64:	fffff097          	auipc	ra,0xfffff
    80002e68:	b5e080e7          	jalr	-1186(ra) # 800019c2 <myproc>
	int err = copyinstr(p->pagetable, buf, addr, max);
    80002e6c:	86ce                	mv	a3,s3
    80002e6e:	864a                	mv	a2,s2
    80002e70:	85a6                	mv	a1,s1
    80002e72:	7928                	ld	a0,112(a0)
    80002e74:	fffff097          	auipc	ra,0xfffff
    80002e78:	8e4080e7          	jalr	-1820(ra) # 80001758 <copyinstr>
	if (err < 0)
    80002e7c:	00054763          	bltz	a0,80002e8a <fetchstr+0x3a>
	return strlen(buf);
    80002e80:	8526                	mv	a0,s1
    80002e82:	ffffe097          	auipc	ra,0xffffe
    80002e86:	fc0080e7          	jalr	-64(ra) # 80000e42 <strlen>
}
    80002e8a:	70a2                	ld	ra,40(sp)
    80002e8c:	7402                	ld	s0,32(sp)
    80002e8e:	64e2                	ld	s1,24(sp)
    80002e90:	6942                	ld	s2,16(sp)
    80002e92:	69a2                	ld	s3,8(sp)
    80002e94:	6145                	addi	sp,sp,48
    80002e96:	8082                	ret

0000000080002e98 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002e98:	1101                	addi	sp,sp,-32
    80002e9a:	ec06                	sd	ra,24(sp)
    80002e9c:	e822                	sd	s0,16(sp)
    80002e9e:	e426                	sd	s1,8(sp)
    80002ea0:	1000                	addi	s0,sp,32
    80002ea2:	84ae                	mv	s1,a1
	*ip = argraw(n);
    80002ea4:	00000097          	auipc	ra,0x0
    80002ea8:	ef2080e7          	jalr	-270(ra) # 80002d96 <argraw>
    80002eac:	c088                	sw	a0,0(s1)
	return 0;
}
    80002eae:	4501                	li	a0,0
    80002eb0:	60e2                	ld	ra,24(sp)
    80002eb2:	6442                	ld	s0,16(sp)
    80002eb4:	64a2                	ld	s1,8(sp)
    80002eb6:	6105                	addi	sp,sp,32
    80002eb8:	8082                	ret

0000000080002eba <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002eba:	1101                	addi	sp,sp,-32
    80002ebc:	ec06                	sd	ra,24(sp)
    80002ebe:	e822                	sd	s0,16(sp)
    80002ec0:	e426                	sd	s1,8(sp)
    80002ec2:	1000                	addi	s0,sp,32
    80002ec4:	84ae                	mv	s1,a1
	*ip = argraw(n);
    80002ec6:	00000097          	auipc	ra,0x0
    80002eca:	ed0080e7          	jalr	-304(ra) # 80002d96 <argraw>
    80002ece:	e088                	sd	a0,0(s1)
	return 0;
}
    80002ed0:	4501                	li	a0,0
    80002ed2:	60e2                	ld	ra,24(sp)
    80002ed4:	6442                	ld	s0,16(sp)
    80002ed6:	64a2                	ld	s1,8(sp)
    80002ed8:	6105                	addi	sp,sp,32
    80002eda:	8082                	ret

0000000080002edc <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002edc:	1101                	addi	sp,sp,-32
    80002ede:	ec06                	sd	ra,24(sp)
    80002ee0:	e822                	sd	s0,16(sp)
    80002ee2:	e426                	sd	s1,8(sp)
    80002ee4:	e04a                	sd	s2,0(sp)
    80002ee6:	1000                	addi	s0,sp,32
    80002ee8:	84ae                	mv	s1,a1
    80002eea:	8932                	mv	s2,a2
	*ip = argraw(n);
    80002eec:	00000097          	auipc	ra,0x0
    80002ef0:	eaa080e7          	jalr	-342(ra) # 80002d96 <argraw>
	uint64 addr;
	if (argaddr(n, &addr) < 0)
		return -1;
	return fetchstr(addr, buf, max);
    80002ef4:	864a                	mv	a2,s2
    80002ef6:	85a6                	mv	a1,s1
    80002ef8:	00000097          	auipc	ra,0x0
    80002efc:	f58080e7          	jalr	-168(ra) # 80002e50 <fetchstr>
}
    80002f00:	60e2                	ld	ra,24(sp)
    80002f02:	6442                	ld	s0,16(sp)
    80002f04:	64a2                	ld	s1,8(sp)
    80002f06:	6902                	ld	s2,0(sp)
    80002f08:	6105                	addi	sp,sp,32
    80002f0a:	8082                	ret

0000000080002f0c <print_trace>:
	}
}

// ADDED
void print_trace(int arg)
{
    80002f0c:	7179                	addi	sp,sp,-48
    80002f0e:	f406                	sd	ra,40(sp)
    80002f10:	f022                	sd	s0,32(sp)
    80002f12:	ec26                	sd	s1,24(sp)
    80002f14:	e84a                	sd	s2,16(sp)
    80002f16:	e44e                	sd	s3,8(sp)
    80002f18:	1800                	addi	s0,sp,48
    80002f1a:	89aa                	mv	s3,a0
	int num;
	struct proc *p = myproc();
    80002f1c:	fffff097          	auipc	ra,0xfffff
    80002f20:	aa6080e7          	jalr	-1370(ra) # 800019c2 <myproc>
	num = p->trapframe->a7;
    80002f24:	7d3c                	ld	a5,120(a0)
    80002f26:	0a87a903          	lw	s2,168(a5)

	int res = (1 << num) & p->trace_mask;
    80002f2a:	4785                	li	a5,1
    80002f2c:	012797bb          	sllw	a5,a5,s2
    80002f30:	5958                	lw	a4,52(a0)
    80002f32:	8ff9                	and	a5,a5,a4
	if (res != 0)
    80002f34:	2781                	sext.w	a5,a5
    80002f36:	eb81                	bnez	a5,80002f46 <print_trace+0x3a>
		else
		{
			printf("syscall %s  -> %d\n", syscallnames[num], p->trapframe->a0);
		}
	}
} // ADDED
    80002f38:	70a2                	ld	ra,40(sp)
    80002f3a:	7402                	ld	s0,32(sp)
    80002f3c:	64e2                	ld	s1,24(sp)
    80002f3e:	6942                	ld	s2,16(sp)
    80002f40:	69a2                	ld	s3,8(sp)
    80002f42:	6145                	addi	sp,sp,48
    80002f44:	8082                	ret
    80002f46:	84aa                	mv	s1,a0
		printf("%d: ", p->pid);
    80002f48:	590c                	lw	a1,48(a0)
    80002f4a:	00005517          	auipc	a0,0x5
    80002f4e:	50650513          	addi	a0,a0,1286 # 80008450 <states.0+0x150>
    80002f52:	ffffd097          	auipc	ra,0xffffd
    80002f56:	622080e7          	jalr	1570(ra) # 80000574 <printf>
		if (num == SYS_fork)
    80002f5a:	4785                	li	a5,1
    80002f5c:	02f90c63          	beq	s2,a5,80002f94 <print_trace+0x88>
		else if (num == SYS_kill || num == SYS_sbrk)
    80002f60:	4799                	li	a5,6
    80002f62:	00f90563          	beq	s2,a5,80002f6c <print_trace+0x60>
    80002f66:	47b1                	li	a5,12
    80002f68:	04f91563          	bne	s2,a5,80002fb2 <print_trace+0xa6>
			printf("syscall %s %d -> %d\n", syscallnames[num], arg, p->trapframe->a0);
    80002f6c:	7cb8                	ld	a4,120(s1)
    80002f6e:	090e                	slli	s2,s2,0x3
    80002f70:	00005797          	auipc	a5,0x5
    80002f74:	63078793          	addi	a5,a5,1584 # 800085a0 <syscallnames>
    80002f78:	993e                	add	s2,s2,a5
    80002f7a:	7b34                	ld	a3,112(a4)
    80002f7c:	864e                	mv	a2,s3
    80002f7e:	00093583          	ld	a1,0(s2)
    80002f82:	00005517          	auipc	a0,0x5
    80002f86:	4f650513          	addi	a0,a0,1270 # 80008478 <states.0+0x178>
    80002f8a:	ffffd097          	auipc	ra,0xffffd
    80002f8e:	5ea080e7          	jalr	1514(ra) # 80000574 <printf>
    80002f92:	b75d                	j	80002f38 <print_trace+0x2c>
			printf("syscall %s NULL -> %d\n", syscallnames[num], p->trapframe->a0);
    80002f94:	7cbc                	ld	a5,120(s1)
    80002f96:	7bb0                	ld	a2,112(a5)
    80002f98:	00005597          	auipc	a1,0x5
    80002f9c:	4c058593          	addi	a1,a1,1216 # 80008458 <states.0+0x158>
    80002fa0:	00005517          	auipc	a0,0x5
    80002fa4:	4c050513          	addi	a0,a0,1216 # 80008460 <states.0+0x160>
    80002fa8:	ffffd097          	auipc	ra,0xffffd
    80002fac:	5cc080e7          	jalr	1484(ra) # 80000574 <printf>
    80002fb0:	b761                	j	80002f38 <print_trace+0x2c>
			printf("syscall %s  -> %d\n", syscallnames[num], p->trapframe->a0);
    80002fb2:	7cb8                	ld	a4,120(s1)
    80002fb4:	090e                	slli	s2,s2,0x3
    80002fb6:	00005797          	auipc	a5,0x5
    80002fba:	5ea78793          	addi	a5,a5,1514 # 800085a0 <syscallnames>
    80002fbe:	993e                	add	s2,s2,a5
    80002fc0:	7b30                	ld	a2,112(a4)
    80002fc2:	00093583          	ld	a1,0(s2)
    80002fc6:	00005517          	auipc	a0,0x5
    80002fca:	4ca50513          	addi	a0,a0,1226 # 80008490 <states.0+0x190>
    80002fce:	ffffd097          	auipc	ra,0xffffd
    80002fd2:	5a6080e7          	jalr	1446(ra) # 80000574 <printf>
} // ADDED
    80002fd6:	b78d                	j	80002f38 <print_trace+0x2c>

0000000080002fd8 <syscall>:
{
    80002fd8:	7179                	addi	sp,sp,-48
    80002fda:	f406                	sd	ra,40(sp)
    80002fdc:	f022                	sd	s0,32(sp)
    80002fde:	ec26                	sd	s1,24(sp)
    80002fe0:	e84a                	sd	s2,16(sp)
    80002fe2:	1800                	addi	s0,sp,48
	struct proc *p = myproc();
    80002fe4:	fffff097          	auipc	ra,0xfffff
    80002fe8:	9de080e7          	jalr	-1570(ra) # 800019c2 <myproc>
    80002fec:	84aa                	mv	s1,a0
	num = p->trapframe->a7;
    80002fee:	7d3c                	ld	a5,120(a0)
    80002ff0:	77dc                	ld	a5,168(a5)
    80002ff2:	0007869b          	sext.w	a3,a5
	if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002ff6:	37fd                	addiw	a5,a5,-1
    80002ff8:	475d                	li	a4,23
    80002ffa:	02f76e63          	bltu	a4,a5,80003036 <syscall+0x5e>
    80002ffe:	00369713          	slli	a4,a3,0x3
    80003002:	00005797          	auipc	a5,0x5
    80003006:	59e78793          	addi	a5,a5,1438 # 800085a0 <syscallnames>
    8000300a:	97ba                	add	a5,a5,a4
    8000300c:	0c87b903          	ld	s2,200(a5)
    80003010:	02090363          	beqz	s2,80003036 <syscall+0x5e>
		argint(0, &arg); // ADDED
    80003014:	fdc40593          	addi	a1,s0,-36
    80003018:	4501                	li	a0,0
    8000301a:	00000097          	auipc	ra,0x0
    8000301e:	e7e080e7          	jalr	-386(ra) # 80002e98 <argint>
		p->trapframe->a0 = syscalls[num]();
    80003022:	7ca4                	ld	s1,120(s1)
    80003024:	9902                	jalr	s2
    80003026:	f8a8                	sd	a0,112(s1)
		print_trace(arg); // ADDED
    80003028:	fdc42503          	lw	a0,-36(s0)
    8000302c:	00000097          	auipc	ra,0x0
    80003030:	ee0080e7          	jalr	-288(ra) # 80002f0c <print_trace>
    80003034:	a839                	j	80003052 <syscall+0x7a>
		printf("%d %s: unknown sys call %d\n",
    80003036:	17848613          	addi	a2,s1,376
    8000303a:	588c                	lw	a1,48(s1)
    8000303c:	00005517          	auipc	a0,0x5
    80003040:	46c50513          	addi	a0,a0,1132 # 800084a8 <states.0+0x1a8>
    80003044:	ffffd097          	auipc	ra,0xffffd
    80003048:	530080e7          	jalr	1328(ra) # 80000574 <printf>
		p->trapframe->a0 = -1;
    8000304c:	7cbc                	ld	a5,120(s1)
    8000304e:	577d                	li	a4,-1
    80003050:	fbb8                	sd	a4,112(a5)
}
    80003052:	70a2                	ld	ra,40(sp)
    80003054:	7402                	ld	s0,32(sp)
    80003056:	64e2                	ld	s1,24(sp)
    80003058:	6942                	ld	s2,16(sp)
    8000305a:	6145                	addi	sp,sp,48
    8000305c:	8082                	ret

000000008000305e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000305e:	1101                	addi	sp,sp,-32
    80003060:	ec06                	sd	ra,24(sp)
    80003062:	e822                	sd	s0,16(sp)
    80003064:	1000                	addi	s0,sp,32
  int n;
  if (argint(0, &n) < 0)
    80003066:	fec40593          	addi	a1,s0,-20
    8000306a:	4501                	li	a0,0
    8000306c:	00000097          	auipc	ra,0x0
    80003070:	e2c080e7          	jalr	-468(ra) # 80002e98 <argint>
    return -1;
    80003074:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80003076:	00054963          	bltz	a0,80003088 <sys_exit+0x2a>
  exit(n);
    8000307a:	fec42503          	lw	a0,-20(s0)
    8000307e:	fffff097          	auipc	ra,0xfffff
    80003082:	3d6080e7          	jalr	982(ra) # 80002454 <exit>
  return 0; // not reached
    80003086:	4781                	li	a5,0
}
    80003088:	853e                	mv	a0,a5
    8000308a:	60e2                	ld	ra,24(sp)
    8000308c:	6442                	ld	s0,16(sp)
    8000308e:	6105                	addi	sp,sp,32
    80003090:	8082                	ret

0000000080003092 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003092:	1141                	addi	sp,sp,-16
    80003094:	e406                	sd	ra,8(sp)
    80003096:	e022                	sd	s0,0(sp)
    80003098:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000309a:	fffff097          	auipc	ra,0xfffff
    8000309e:	928080e7          	jalr	-1752(ra) # 800019c2 <myproc>
}
    800030a2:	5908                	lw	a0,48(a0)
    800030a4:	60a2                	ld	ra,8(sp)
    800030a6:	6402                	ld	s0,0(sp)
    800030a8:	0141                	addi	sp,sp,16
    800030aa:	8082                	ret

00000000800030ac <sys_fork>:

uint64
sys_fork(void)
{
    800030ac:	1141                	addi	sp,sp,-16
    800030ae:	e406                	sd	ra,8(sp)
    800030b0:	e022                	sd	s0,0(sp)
    800030b2:	0800                	addi	s0,sp,16
  return fork();
    800030b4:	fffff097          	auipc	ra,0xfffff
    800030b8:	d0a080e7          	jalr	-758(ra) # 80001dbe <fork>
}
    800030bc:	60a2                	ld	ra,8(sp)
    800030be:	6402                	ld	s0,0(sp)
    800030c0:	0141                	addi	sp,sp,16
    800030c2:	8082                	ret

00000000800030c4 <sys_wait>:

uint64
sys_wait(void)
{
    800030c4:	1101                	addi	sp,sp,-32
    800030c6:	ec06                	sd	ra,24(sp)
    800030c8:	e822                	sd	s0,16(sp)
    800030ca:	1000                	addi	s0,sp,32
  uint64 p;
  if (argaddr(0, &p) < 0)
    800030cc:	fe840593          	addi	a1,s0,-24
    800030d0:	4501                	li	a0,0
    800030d2:	00000097          	auipc	ra,0x0
    800030d6:	de8080e7          	jalr	-536(ra) # 80002eba <argaddr>
    800030da:	87aa                	mv	a5,a0
    return -1;
    800030dc:	557d                	li	a0,-1
  if (argaddr(0, &p) < 0)
    800030de:	0007c863          	bltz	a5,800030ee <sys_wait+0x2a>
  return wait(p);
    800030e2:	fe843503          	ld	a0,-24(s0)
    800030e6:	fffff097          	auipc	ra,0xfffff
    800030ea:	16c080e7          	jalr	364(ra) # 80002252 <wait>
}
    800030ee:	60e2                	ld	ra,24(sp)
    800030f0:	6442                	ld	s0,16(sp)
    800030f2:	6105                	addi	sp,sp,32
    800030f4:	8082                	ret

00000000800030f6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800030f6:	7179                	addi	sp,sp,-48
    800030f8:	f406                	sd	ra,40(sp)
    800030fa:	f022                	sd	s0,32(sp)
    800030fc:	ec26                	sd	s1,24(sp)
    800030fe:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if (argint(0, &n) < 0)
    80003100:	fdc40593          	addi	a1,s0,-36
    80003104:	4501                	li	a0,0
    80003106:	00000097          	auipc	ra,0x0
    8000310a:	d92080e7          	jalr	-622(ra) # 80002e98 <argint>
    return -1;
    8000310e:	54fd                	li	s1,-1
  if (argint(0, &n) < 0)
    80003110:	00054f63          	bltz	a0,8000312e <sys_sbrk+0x38>
  addr = myproc()->sz;
    80003114:	fffff097          	auipc	ra,0xfffff
    80003118:	8ae080e7          	jalr	-1874(ra) # 800019c2 <myproc>
    8000311c:	5524                	lw	s1,104(a0)
  if (growproc(n) < 0)
    8000311e:	fdc42503          	lw	a0,-36(s0)
    80003122:	fffff097          	auipc	ra,0xfffff
    80003126:	c28080e7          	jalr	-984(ra) # 80001d4a <growproc>
    8000312a:	00054863          	bltz	a0,8000313a <sys_sbrk+0x44>
    return -1;
  return addr;
}
    8000312e:	8526                	mv	a0,s1
    80003130:	70a2                	ld	ra,40(sp)
    80003132:	7402                	ld	s0,32(sp)
    80003134:	64e2                	ld	s1,24(sp)
    80003136:	6145                	addi	sp,sp,48
    80003138:	8082                	ret
    return -1;
    8000313a:	54fd                	li	s1,-1
    8000313c:	bfcd                	j	8000312e <sys_sbrk+0x38>

000000008000313e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000313e:	7139                	addi	sp,sp,-64
    80003140:	fc06                	sd	ra,56(sp)
    80003142:	f822                	sd	s0,48(sp)
    80003144:	f426                	sd	s1,40(sp)
    80003146:	f04a                	sd	s2,32(sp)
    80003148:	ec4e                	sd	s3,24(sp)
    8000314a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if (argint(0, &n) < 0)
    8000314c:	fcc40593          	addi	a1,s0,-52
    80003150:	4501                	li	a0,0
    80003152:	00000097          	auipc	ra,0x0
    80003156:	d46080e7          	jalr	-698(ra) # 80002e98 <argint>
    return -1;
    8000315a:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    8000315c:	06054563          	bltz	a0,800031c6 <sys_sleep+0x88>
  acquire(&tickslock);
    80003160:	00014517          	auipc	a0,0x14
    80003164:	78850513          	addi	a0,a0,1928 # 800178e8 <tickslock>
    80003168:	ffffe097          	auipc	ra,0xffffe
    8000316c:	a5a080e7          	jalr	-1446(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80003170:	00006917          	auipc	s2,0x6
    80003174:	ec092903          	lw	s2,-320(s2) # 80009030 <ticks>
  while (ticks - ticks0 < n)
    80003178:	fcc42783          	lw	a5,-52(s0)
    8000317c:	cf85                	beqz	a5,800031b4 <sys_sleep+0x76>
    if (myproc()->killed)
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000317e:	00014997          	auipc	s3,0x14
    80003182:	76a98993          	addi	s3,s3,1898 # 800178e8 <tickslock>
    80003186:	00006497          	auipc	s1,0x6
    8000318a:	eaa48493          	addi	s1,s1,-342 # 80009030 <ticks>
    if (myproc()->killed)
    8000318e:	fffff097          	auipc	ra,0xfffff
    80003192:	834080e7          	jalr	-1996(ra) # 800019c2 <myproc>
    80003196:	551c                	lw	a5,40(a0)
    80003198:	ef9d                	bnez	a5,800031d6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000319a:	85ce                	mv	a1,s3
    8000319c:	8526                	mv	a0,s1
    8000319e:	fffff097          	auipc	ra,0xfffff
    800031a2:	050080e7          	jalr	80(ra) # 800021ee <sleep>
  while (ticks - ticks0 < n)
    800031a6:	409c                	lw	a5,0(s1)
    800031a8:	412787bb          	subw	a5,a5,s2
    800031ac:	fcc42703          	lw	a4,-52(s0)
    800031b0:	fce7efe3          	bltu	a5,a4,8000318e <sys_sleep+0x50>
  }
  release(&tickslock);
    800031b4:	00014517          	auipc	a0,0x14
    800031b8:	73450513          	addi	a0,a0,1844 # 800178e8 <tickslock>
    800031bc:	ffffe097          	auipc	ra,0xffffe
    800031c0:	aba080e7          	jalr	-1350(ra) # 80000c76 <release>
  return 0;
    800031c4:	4781                	li	a5,0
}
    800031c6:	853e                	mv	a0,a5
    800031c8:	70e2                	ld	ra,56(sp)
    800031ca:	7442                	ld	s0,48(sp)
    800031cc:	74a2                	ld	s1,40(sp)
    800031ce:	7902                	ld	s2,32(sp)
    800031d0:	69e2                	ld	s3,24(sp)
    800031d2:	6121                	addi	sp,sp,64
    800031d4:	8082                	ret
      release(&tickslock);
    800031d6:	00014517          	auipc	a0,0x14
    800031da:	71250513          	addi	a0,a0,1810 # 800178e8 <tickslock>
    800031de:	ffffe097          	auipc	ra,0xffffe
    800031e2:	a98080e7          	jalr	-1384(ra) # 80000c76 <release>
      return -1;
    800031e6:	57fd                	li	a5,-1
    800031e8:	bff9                	j	800031c6 <sys_sleep+0x88>

00000000800031ea <sys_kill>:

uint64
sys_kill(void)
{
    800031ea:	1101                	addi	sp,sp,-32
    800031ec:	ec06                	sd	ra,24(sp)
    800031ee:	e822                	sd	s0,16(sp)
    800031f0:	1000                	addi	s0,sp,32
  int pid;

  if (argint(0, &pid) < 0)
    800031f2:	fec40593          	addi	a1,s0,-20
    800031f6:	4501                	li	a0,0
    800031f8:	00000097          	auipc	ra,0x0
    800031fc:	ca0080e7          	jalr	-864(ra) # 80002e98 <argint>
    80003200:	87aa                	mv	a5,a0
    return -1;
    80003202:	557d                	li	a0,-1
  if (argint(0, &pid) < 0)
    80003204:	0007c863          	bltz	a5,80003214 <sys_kill+0x2a>
  return kill(pid);
    80003208:	fec42503          	lw	a0,-20(s0)
    8000320c:	fffff097          	auipc	ra,0xfffff
    80003210:	31e080e7          	jalr	798(ra) # 8000252a <kill>
}
    80003214:	60e2                	ld	ra,24(sp)
    80003216:	6442                	ld	s0,16(sp)
    80003218:	6105                	addi	sp,sp,32
    8000321a:	8082                	ret

000000008000321c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000321c:	1101                	addi	sp,sp,-32
    8000321e:	ec06                	sd	ra,24(sp)
    80003220:	e822                	sd	s0,16(sp)
    80003222:	e426                	sd	s1,8(sp)
    80003224:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003226:	00014517          	auipc	a0,0x14
    8000322a:	6c250513          	addi	a0,a0,1730 # 800178e8 <tickslock>
    8000322e:	ffffe097          	auipc	ra,0xffffe
    80003232:	994080e7          	jalr	-1644(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80003236:	00006497          	auipc	s1,0x6
    8000323a:	dfa4a483          	lw	s1,-518(s1) # 80009030 <ticks>
  release(&tickslock);
    8000323e:	00014517          	auipc	a0,0x14
    80003242:	6aa50513          	addi	a0,a0,1706 # 800178e8 <tickslock>
    80003246:	ffffe097          	auipc	ra,0xffffe
    8000324a:	a30080e7          	jalr	-1488(ra) # 80000c76 <release>
  return xticks;
}
    8000324e:	02049513          	slli	a0,s1,0x20
    80003252:	9101                	srli	a0,a0,0x20
    80003254:	60e2                	ld	ra,24(sp)
    80003256:	6442                	ld	s0,16(sp)
    80003258:	64a2                	ld	s1,8(sp)
    8000325a:	6105                	addi	sp,sp,32
    8000325c:	8082                	ret

000000008000325e <sys_trace>:

//ADDED
uint64
sys_trace(void)
{
    8000325e:	1101                	addi	sp,sp,-32
    80003260:	ec06                	sd	ra,24(sp)
    80003262:	e822                	sd	s0,16(sp)
    80003264:	1000                	addi	s0,sp,32
  int mask, pid;
  argint(0, &mask);
    80003266:	fec40593          	addi	a1,s0,-20
    8000326a:	4501                	li	a0,0
    8000326c:	00000097          	auipc	ra,0x0
    80003270:	c2c080e7          	jalr	-980(ra) # 80002e98 <argint>
  argint(1, &pid);
    80003274:	fe840593          	addi	a1,s0,-24
    80003278:	4505                	li	a0,1
    8000327a:	00000097          	auipc	ra,0x0
    8000327e:	c1e080e7          	jalr	-994(ra) # 80002e98 <argint>
  return trace(mask, pid);
    80003282:	fe842583          	lw	a1,-24(s0)
    80003286:	fec42503          	lw	a0,-20(s0)
    8000328a:	fffff097          	auipc	ra,0xfffff
    8000328e:	46e080e7          	jalr	1134(ra) # 800026f8 <trace>
}
    80003292:	60e2                	ld	ra,24(sp)
    80003294:	6442                	ld	s0,16(sp)
    80003296:	6105                	addi	sp,sp,32
    80003298:	8082                	ret

000000008000329a <sys_getmsk>:

uint64
sys_getmsk(void)
{
    8000329a:	1101                	addi	sp,sp,-32
    8000329c:	ec06                	sd	ra,24(sp)
    8000329e:	e822                	sd	s0,16(sp)
    800032a0:	1000                	addi	s0,sp,32
  int pid;
  argint(0, &pid);
    800032a2:	fec40593          	addi	a1,s0,-20
    800032a6:	4501                	li	a0,0
    800032a8:	00000097          	auipc	ra,0x0
    800032ac:	bf0080e7          	jalr	-1040(ra) # 80002e98 <argint>
  return getmsk(pid);
    800032b0:	fec42503          	lw	a0,-20(s0)
    800032b4:	fffff097          	auipc	ra,0xfffff
    800032b8:	4ae080e7          	jalr	1198(ra) # 80002762 <getmsk>
}
    800032bc:	60e2                	ld	ra,24(sp)
    800032be:	6442                	ld	s0,16(sp)
    800032c0:	6105                	addi	sp,sp,32
    800032c2:	8082                	ret

00000000800032c4 <sys_wait_stat>:

uint64
sys_wait_stat(void)
{
    800032c4:	1101                	addi	sp,sp,-32
    800032c6:	ec06                	sd	ra,24(sp)
    800032c8:	e822                	sd	s0,16(sp)
    800032ca:	1000                	addi	s0,sp,32
  uint64 status;
  uint64 performance;
  argaddr(0,  &status);
    800032cc:	fe840593          	addi	a1,s0,-24
    800032d0:	4501                	li	a0,0
    800032d2:	00000097          	auipc	ra,0x0
    800032d6:	be8080e7          	jalr	-1048(ra) # 80002eba <argaddr>
  argaddr(1,  &performance);
    800032da:	fe040593          	addi	a1,s0,-32
    800032de:	4505                	li	a0,1
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	bda080e7          	jalr	-1062(ra) # 80002eba <argaddr>
  return wait_stat(status, performance);
    800032e8:	fe043583          	ld	a1,-32(s0)
    800032ec:	fe843503          	ld	a0,-24(s0)
    800032f0:	fffff097          	auipc	ra,0xfffff
    800032f4:	522080e7          	jalr	1314(ra) # 80002812 <wait_stat>
}
    800032f8:	60e2                	ld	ra,24(sp)
    800032fa:	6442                	ld	s0,16(sp)
    800032fc:	6105                	addi	sp,sp,32
    800032fe:	8082                	ret

0000000080003300 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003300:	7179                	addi	sp,sp,-48
    80003302:	f406                	sd	ra,40(sp)
    80003304:	f022                	sd	s0,32(sp)
    80003306:	ec26                	sd	s1,24(sp)
    80003308:	e84a                	sd	s2,16(sp)
    8000330a:	e44e                	sd	s3,8(sp)
    8000330c:	e052                	sd	s4,0(sp)
    8000330e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003310:	00005597          	auipc	a1,0x5
    80003314:	42058593          	addi	a1,a1,1056 # 80008730 <syscalls+0xc8>
    80003318:	00014517          	auipc	a0,0x14
    8000331c:	5e850513          	addi	a0,a0,1512 # 80017900 <bcache>
    80003320:	ffffe097          	auipc	ra,0xffffe
    80003324:	812080e7          	jalr	-2030(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003328:	0001c797          	auipc	a5,0x1c
    8000332c:	5d878793          	addi	a5,a5,1496 # 8001f900 <bcache+0x8000>
    80003330:	0001d717          	auipc	a4,0x1d
    80003334:	83870713          	addi	a4,a4,-1992 # 8001fb68 <bcache+0x8268>
    80003338:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000333c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003340:	00014497          	auipc	s1,0x14
    80003344:	5d848493          	addi	s1,s1,1496 # 80017918 <bcache+0x18>
    b->next = bcache.head.next;
    80003348:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000334a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000334c:	00005a17          	auipc	s4,0x5
    80003350:	3eca0a13          	addi	s4,s4,1004 # 80008738 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003354:	2b893783          	ld	a5,696(s2)
    80003358:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000335a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000335e:	85d2                	mv	a1,s4
    80003360:	01048513          	addi	a0,s1,16
    80003364:	00001097          	auipc	ra,0x1
    80003368:	4c2080e7          	jalr	1218(ra) # 80004826 <initsleeplock>
    bcache.head.next->prev = b;
    8000336c:	2b893783          	ld	a5,696(s2)
    80003370:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003372:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003376:	45848493          	addi	s1,s1,1112
    8000337a:	fd349de3          	bne	s1,s3,80003354 <binit+0x54>
  }
}
    8000337e:	70a2                	ld	ra,40(sp)
    80003380:	7402                	ld	s0,32(sp)
    80003382:	64e2                	ld	s1,24(sp)
    80003384:	6942                	ld	s2,16(sp)
    80003386:	69a2                	ld	s3,8(sp)
    80003388:	6a02                	ld	s4,0(sp)
    8000338a:	6145                	addi	sp,sp,48
    8000338c:	8082                	ret

000000008000338e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000338e:	7179                	addi	sp,sp,-48
    80003390:	f406                	sd	ra,40(sp)
    80003392:	f022                	sd	s0,32(sp)
    80003394:	ec26                	sd	s1,24(sp)
    80003396:	e84a                	sd	s2,16(sp)
    80003398:	e44e                	sd	s3,8(sp)
    8000339a:	1800                	addi	s0,sp,48
    8000339c:	892a                	mv	s2,a0
    8000339e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800033a0:	00014517          	auipc	a0,0x14
    800033a4:	56050513          	addi	a0,a0,1376 # 80017900 <bcache>
    800033a8:	ffffe097          	auipc	ra,0xffffe
    800033ac:	81a080e7          	jalr	-2022(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033b0:	0001d497          	auipc	s1,0x1d
    800033b4:	8084b483          	ld	s1,-2040(s1) # 8001fbb8 <bcache+0x82b8>
    800033b8:	0001c797          	auipc	a5,0x1c
    800033bc:	7b078793          	addi	a5,a5,1968 # 8001fb68 <bcache+0x8268>
    800033c0:	02f48f63          	beq	s1,a5,800033fe <bread+0x70>
    800033c4:	873e                	mv	a4,a5
    800033c6:	a021                	j	800033ce <bread+0x40>
    800033c8:	68a4                	ld	s1,80(s1)
    800033ca:	02e48a63          	beq	s1,a4,800033fe <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033ce:	449c                	lw	a5,8(s1)
    800033d0:	ff279ce3          	bne	a5,s2,800033c8 <bread+0x3a>
    800033d4:	44dc                	lw	a5,12(s1)
    800033d6:	ff3799e3          	bne	a5,s3,800033c8 <bread+0x3a>
      b->refcnt++;
    800033da:	40bc                	lw	a5,64(s1)
    800033dc:	2785                	addiw	a5,a5,1
    800033de:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033e0:	00014517          	auipc	a0,0x14
    800033e4:	52050513          	addi	a0,a0,1312 # 80017900 <bcache>
    800033e8:	ffffe097          	auipc	ra,0xffffe
    800033ec:	88e080e7          	jalr	-1906(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800033f0:	01048513          	addi	a0,s1,16
    800033f4:	00001097          	auipc	ra,0x1
    800033f8:	46c080e7          	jalr	1132(ra) # 80004860 <acquiresleep>
      return b;
    800033fc:	a8b9                	j	8000345a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033fe:	0001c497          	auipc	s1,0x1c
    80003402:	7b24b483          	ld	s1,1970(s1) # 8001fbb0 <bcache+0x82b0>
    80003406:	0001c797          	auipc	a5,0x1c
    8000340a:	76278793          	addi	a5,a5,1890 # 8001fb68 <bcache+0x8268>
    8000340e:	00f48863          	beq	s1,a5,8000341e <bread+0x90>
    80003412:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003414:	40bc                	lw	a5,64(s1)
    80003416:	cf81                	beqz	a5,8000342e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003418:	64a4                	ld	s1,72(s1)
    8000341a:	fee49de3          	bne	s1,a4,80003414 <bread+0x86>
  panic("bget: no buffers");
    8000341e:	00005517          	auipc	a0,0x5
    80003422:	32250513          	addi	a0,a0,802 # 80008740 <syscalls+0xd8>
    80003426:	ffffd097          	auipc	ra,0xffffd
    8000342a:	104080e7          	jalr	260(ra) # 8000052a <panic>
      b->dev = dev;
    8000342e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003432:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003436:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000343a:	4785                	li	a5,1
    8000343c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000343e:	00014517          	auipc	a0,0x14
    80003442:	4c250513          	addi	a0,a0,1218 # 80017900 <bcache>
    80003446:	ffffe097          	auipc	ra,0xffffe
    8000344a:	830080e7          	jalr	-2000(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000344e:	01048513          	addi	a0,s1,16
    80003452:	00001097          	auipc	ra,0x1
    80003456:	40e080e7          	jalr	1038(ra) # 80004860 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000345a:	409c                	lw	a5,0(s1)
    8000345c:	cb89                	beqz	a5,8000346e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000345e:	8526                	mv	a0,s1
    80003460:	70a2                	ld	ra,40(sp)
    80003462:	7402                	ld	s0,32(sp)
    80003464:	64e2                	ld	s1,24(sp)
    80003466:	6942                	ld	s2,16(sp)
    80003468:	69a2                	ld	s3,8(sp)
    8000346a:	6145                	addi	sp,sp,48
    8000346c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000346e:	4581                	li	a1,0
    80003470:	8526                	mv	a0,s1
    80003472:	00003097          	auipc	ra,0x3
    80003476:	f24080e7          	jalr	-220(ra) # 80006396 <virtio_disk_rw>
    b->valid = 1;
    8000347a:	4785                	li	a5,1
    8000347c:	c09c                	sw	a5,0(s1)
  return b;
    8000347e:	b7c5                	j	8000345e <bread+0xd0>

0000000080003480 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003480:	1101                	addi	sp,sp,-32
    80003482:	ec06                	sd	ra,24(sp)
    80003484:	e822                	sd	s0,16(sp)
    80003486:	e426                	sd	s1,8(sp)
    80003488:	1000                	addi	s0,sp,32
    8000348a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000348c:	0541                	addi	a0,a0,16
    8000348e:	00001097          	auipc	ra,0x1
    80003492:	46c080e7          	jalr	1132(ra) # 800048fa <holdingsleep>
    80003496:	cd01                	beqz	a0,800034ae <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003498:	4585                	li	a1,1
    8000349a:	8526                	mv	a0,s1
    8000349c:	00003097          	auipc	ra,0x3
    800034a0:	efa080e7          	jalr	-262(ra) # 80006396 <virtio_disk_rw>
}
    800034a4:	60e2                	ld	ra,24(sp)
    800034a6:	6442                	ld	s0,16(sp)
    800034a8:	64a2                	ld	s1,8(sp)
    800034aa:	6105                	addi	sp,sp,32
    800034ac:	8082                	ret
    panic("bwrite");
    800034ae:	00005517          	auipc	a0,0x5
    800034b2:	2aa50513          	addi	a0,a0,682 # 80008758 <syscalls+0xf0>
    800034b6:	ffffd097          	auipc	ra,0xffffd
    800034ba:	074080e7          	jalr	116(ra) # 8000052a <panic>

00000000800034be <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034be:	1101                	addi	sp,sp,-32
    800034c0:	ec06                	sd	ra,24(sp)
    800034c2:	e822                	sd	s0,16(sp)
    800034c4:	e426                	sd	s1,8(sp)
    800034c6:	e04a                	sd	s2,0(sp)
    800034c8:	1000                	addi	s0,sp,32
    800034ca:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034cc:	01050913          	addi	s2,a0,16
    800034d0:	854a                	mv	a0,s2
    800034d2:	00001097          	auipc	ra,0x1
    800034d6:	428080e7          	jalr	1064(ra) # 800048fa <holdingsleep>
    800034da:	c92d                	beqz	a0,8000354c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800034dc:	854a                	mv	a0,s2
    800034de:	00001097          	auipc	ra,0x1
    800034e2:	3d8080e7          	jalr	984(ra) # 800048b6 <releasesleep>

  acquire(&bcache.lock);
    800034e6:	00014517          	auipc	a0,0x14
    800034ea:	41a50513          	addi	a0,a0,1050 # 80017900 <bcache>
    800034ee:	ffffd097          	auipc	ra,0xffffd
    800034f2:	6d4080e7          	jalr	1748(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800034f6:	40bc                	lw	a5,64(s1)
    800034f8:	37fd                	addiw	a5,a5,-1
    800034fa:	0007871b          	sext.w	a4,a5
    800034fe:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003500:	eb05                	bnez	a4,80003530 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003502:	68bc                	ld	a5,80(s1)
    80003504:	64b8                	ld	a4,72(s1)
    80003506:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003508:	64bc                	ld	a5,72(s1)
    8000350a:	68b8                	ld	a4,80(s1)
    8000350c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000350e:	0001c797          	auipc	a5,0x1c
    80003512:	3f278793          	addi	a5,a5,1010 # 8001f900 <bcache+0x8000>
    80003516:	2b87b703          	ld	a4,696(a5)
    8000351a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000351c:	0001c717          	auipc	a4,0x1c
    80003520:	64c70713          	addi	a4,a4,1612 # 8001fb68 <bcache+0x8268>
    80003524:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003526:	2b87b703          	ld	a4,696(a5)
    8000352a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000352c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003530:	00014517          	auipc	a0,0x14
    80003534:	3d050513          	addi	a0,a0,976 # 80017900 <bcache>
    80003538:	ffffd097          	auipc	ra,0xffffd
    8000353c:	73e080e7          	jalr	1854(ra) # 80000c76 <release>
}
    80003540:	60e2                	ld	ra,24(sp)
    80003542:	6442                	ld	s0,16(sp)
    80003544:	64a2                	ld	s1,8(sp)
    80003546:	6902                	ld	s2,0(sp)
    80003548:	6105                	addi	sp,sp,32
    8000354a:	8082                	ret
    panic("brelse");
    8000354c:	00005517          	auipc	a0,0x5
    80003550:	21450513          	addi	a0,a0,532 # 80008760 <syscalls+0xf8>
    80003554:	ffffd097          	auipc	ra,0xffffd
    80003558:	fd6080e7          	jalr	-42(ra) # 8000052a <panic>

000000008000355c <bpin>:

void
bpin(struct buf *b) {
    8000355c:	1101                	addi	sp,sp,-32
    8000355e:	ec06                	sd	ra,24(sp)
    80003560:	e822                	sd	s0,16(sp)
    80003562:	e426                	sd	s1,8(sp)
    80003564:	1000                	addi	s0,sp,32
    80003566:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003568:	00014517          	auipc	a0,0x14
    8000356c:	39850513          	addi	a0,a0,920 # 80017900 <bcache>
    80003570:	ffffd097          	auipc	ra,0xffffd
    80003574:	652080e7          	jalr	1618(ra) # 80000bc2 <acquire>
  b->refcnt++;
    80003578:	40bc                	lw	a5,64(s1)
    8000357a:	2785                	addiw	a5,a5,1
    8000357c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000357e:	00014517          	auipc	a0,0x14
    80003582:	38250513          	addi	a0,a0,898 # 80017900 <bcache>
    80003586:	ffffd097          	auipc	ra,0xffffd
    8000358a:	6f0080e7          	jalr	1776(ra) # 80000c76 <release>
}
    8000358e:	60e2                	ld	ra,24(sp)
    80003590:	6442                	ld	s0,16(sp)
    80003592:	64a2                	ld	s1,8(sp)
    80003594:	6105                	addi	sp,sp,32
    80003596:	8082                	ret

0000000080003598 <bunpin>:

void
bunpin(struct buf *b) {
    80003598:	1101                	addi	sp,sp,-32
    8000359a:	ec06                	sd	ra,24(sp)
    8000359c:	e822                	sd	s0,16(sp)
    8000359e:	e426                	sd	s1,8(sp)
    800035a0:	1000                	addi	s0,sp,32
    800035a2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035a4:	00014517          	auipc	a0,0x14
    800035a8:	35c50513          	addi	a0,a0,860 # 80017900 <bcache>
    800035ac:	ffffd097          	auipc	ra,0xffffd
    800035b0:	616080e7          	jalr	1558(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800035b4:	40bc                	lw	a5,64(s1)
    800035b6:	37fd                	addiw	a5,a5,-1
    800035b8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035ba:	00014517          	auipc	a0,0x14
    800035be:	34650513          	addi	a0,a0,838 # 80017900 <bcache>
    800035c2:	ffffd097          	auipc	ra,0xffffd
    800035c6:	6b4080e7          	jalr	1716(ra) # 80000c76 <release>
}
    800035ca:	60e2                	ld	ra,24(sp)
    800035cc:	6442                	ld	s0,16(sp)
    800035ce:	64a2                	ld	s1,8(sp)
    800035d0:	6105                	addi	sp,sp,32
    800035d2:	8082                	ret

00000000800035d4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035d4:	1101                	addi	sp,sp,-32
    800035d6:	ec06                	sd	ra,24(sp)
    800035d8:	e822                	sd	s0,16(sp)
    800035da:	e426                	sd	s1,8(sp)
    800035dc:	e04a                	sd	s2,0(sp)
    800035de:	1000                	addi	s0,sp,32
    800035e0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035e2:	00d5d59b          	srliw	a1,a1,0xd
    800035e6:	0001d797          	auipc	a5,0x1d
    800035ea:	9f67a783          	lw	a5,-1546(a5) # 8001ffdc <sb+0x1c>
    800035ee:	9dbd                	addw	a1,a1,a5
    800035f0:	00000097          	auipc	ra,0x0
    800035f4:	d9e080e7          	jalr	-610(ra) # 8000338e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035f8:	0074f713          	andi	a4,s1,7
    800035fc:	4785                	li	a5,1
    800035fe:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003602:	14ce                	slli	s1,s1,0x33
    80003604:	90d9                	srli	s1,s1,0x36
    80003606:	00950733          	add	a4,a0,s1
    8000360a:	05874703          	lbu	a4,88(a4)
    8000360e:	00e7f6b3          	and	a3,a5,a4
    80003612:	c69d                	beqz	a3,80003640 <bfree+0x6c>
    80003614:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003616:	94aa                	add	s1,s1,a0
    80003618:	fff7c793          	not	a5,a5
    8000361c:	8ff9                	and	a5,a5,a4
    8000361e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003622:	00001097          	auipc	ra,0x1
    80003626:	11e080e7          	jalr	286(ra) # 80004740 <log_write>
  brelse(bp);
    8000362a:	854a                	mv	a0,s2
    8000362c:	00000097          	auipc	ra,0x0
    80003630:	e92080e7          	jalr	-366(ra) # 800034be <brelse>
}
    80003634:	60e2                	ld	ra,24(sp)
    80003636:	6442                	ld	s0,16(sp)
    80003638:	64a2                	ld	s1,8(sp)
    8000363a:	6902                	ld	s2,0(sp)
    8000363c:	6105                	addi	sp,sp,32
    8000363e:	8082                	ret
    panic("freeing free block");
    80003640:	00005517          	auipc	a0,0x5
    80003644:	12850513          	addi	a0,a0,296 # 80008768 <syscalls+0x100>
    80003648:	ffffd097          	auipc	ra,0xffffd
    8000364c:	ee2080e7          	jalr	-286(ra) # 8000052a <panic>

0000000080003650 <balloc>:
{
    80003650:	711d                	addi	sp,sp,-96
    80003652:	ec86                	sd	ra,88(sp)
    80003654:	e8a2                	sd	s0,80(sp)
    80003656:	e4a6                	sd	s1,72(sp)
    80003658:	e0ca                	sd	s2,64(sp)
    8000365a:	fc4e                	sd	s3,56(sp)
    8000365c:	f852                	sd	s4,48(sp)
    8000365e:	f456                	sd	s5,40(sp)
    80003660:	f05a                	sd	s6,32(sp)
    80003662:	ec5e                	sd	s7,24(sp)
    80003664:	e862                	sd	s8,16(sp)
    80003666:	e466                	sd	s9,8(sp)
    80003668:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000366a:	0001d797          	auipc	a5,0x1d
    8000366e:	95a7a783          	lw	a5,-1702(a5) # 8001ffc4 <sb+0x4>
    80003672:	cbd1                	beqz	a5,80003706 <balloc+0xb6>
    80003674:	8baa                	mv	s7,a0
    80003676:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003678:	0001db17          	auipc	s6,0x1d
    8000367c:	948b0b13          	addi	s6,s6,-1720 # 8001ffc0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003680:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003682:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003684:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003686:	6c89                	lui	s9,0x2
    80003688:	a831                	j	800036a4 <balloc+0x54>
    brelse(bp);
    8000368a:	854a                	mv	a0,s2
    8000368c:	00000097          	auipc	ra,0x0
    80003690:	e32080e7          	jalr	-462(ra) # 800034be <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003694:	015c87bb          	addw	a5,s9,s5
    80003698:	00078a9b          	sext.w	s5,a5
    8000369c:	004b2703          	lw	a4,4(s6)
    800036a0:	06eaf363          	bgeu	s5,a4,80003706 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800036a4:	41fad79b          	sraiw	a5,s5,0x1f
    800036a8:	0137d79b          	srliw	a5,a5,0x13
    800036ac:	015787bb          	addw	a5,a5,s5
    800036b0:	40d7d79b          	sraiw	a5,a5,0xd
    800036b4:	01cb2583          	lw	a1,28(s6)
    800036b8:	9dbd                	addw	a1,a1,a5
    800036ba:	855e                	mv	a0,s7
    800036bc:	00000097          	auipc	ra,0x0
    800036c0:	cd2080e7          	jalr	-814(ra) # 8000338e <bread>
    800036c4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036c6:	004b2503          	lw	a0,4(s6)
    800036ca:	000a849b          	sext.w	s1,s5
    800036ce:	8662                	mv	a2,s8
    800036d0:	faa4fde3          	bgeu	s1,a0,8000368a <balloc+0x3a>
      m = 1 << (bi % 8);
    800036d4:	41f6579b          	sraiw	a5,a2,0x1f
    800036d8:	01d7d69b          	srliw	a3,a5,0x1d
    800036dc:	00c6873b          	addw	a4,a3,a2
    800036e0:	00777793          	andi	a5,a4,7
    800036e4:	9f95                	subw	a5,a5,a3
    800036e6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036ea:	4037571b          	sraiw	a4,a4,0x3
    800036ee:	00e906b3          	add	a3,s2,a4
    800036f2:	0586c683          	lbu	a3,88(a3)
    800036f6:	00d7f5b3          	and	a1,a5,a3
    800036fa:	cd91                	beqz	a1,80003716 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036fc:	2605                	addiw	a2,a2,1
    800036fe:	2485                	addiw	s1,s1,1
    80003700:	fd4618e3          	bne	a2,s4,800036d0 <balloc+0x80>
    80003704:	b759                	j	8000368a <balloc+0x3a>
  panic("balloc: out of blocks");
    80003706:	00005517          	auipc	a0,0x5
    8000370a:	07a50513          	addi	a0,a0,122 # 80008780 <syscalls+0x118>
    8000370e:	ffffd097          	auipc	ra,0xffffd
    80003712:	e1c080e7          	jalr	-484(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003716:	974a                	add	a4,a4,s2
    80003718:	8fd5                	or	a5,a5,a3
    8000371a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000371e:	854a                	mv	a0,s2
    80003720:	00001097          	auipc	ra,0x1
    80003724:	020080e7          	jalr	32(ra) # 80004740 <log_write>
        brelse(bp);
    80003728:	854a                	mv	a0,s2
    8000372a:	00000097          	auipc	ra,0x0
    8000372e:	d94080e7          	jalr	-620(ra) # 800034be <brelse>
  bp = bread(dev, bno);
    80003732:	85a6                	mv	a1,s1
    80003734:	855e                	mv	a0,s7
    80003736:	00000097          	auipc	ra,0x0
    8000373a:	c58080e7          	jalr	-936(ra) # 8000338e <bread>
    8000373e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003740:	40000613          	li	a2,1024
    80003744:	4581                	li	a1,0
    80003746:	05850513          	addi	a0,a0,88
    8000374a:	ffffd097          	auipc	ra,0xffffd
    8000374e:	574080e7          	jalr	1396(ra) # 80000cbe <memset>
  log_write(bp);
    80003752:	854a                	mv	a0,s2
    80003754:	00001097          	auipc	ra,0x1
    80003758:	fec080e7          	jalr	-20(ra) # 80004740 <log_write>
  brelse(bp);
    8000375c:	854a                	mv	a0,s2
    8000375e:	00000097          	auipc	ra,0x0
    80003762:	d60080e7          	jalr	-672(ra) # 800034be <brelse>
}
    80003766:	8526                	mv	a0,s1
    80003768:	60e6                	ld	ra,88(sp)
    8000376a:	6446                	ld	s0,80(sp)
    8000376c:	64a6                	ld	s1,72(sp)
    8000376e:	6906                	ld	s2,64(sp)
    80003770:	79e2                	ld	s3,56(sp)
    80003772:	7a42                	ld	s4,48(sp)
    80003774:	7aa2                	ld	s5,40(sp)
    80003776:	7b02                	ld	s6,32(sp)
    80003778:	6be2                	ld	s7,24(sp)
    8000377a:	6c42                	ld	s8,16(sp)
    8000377c:	6ca2                	ld	s9,8(sp)
    8000377e:	6125                	addi	sp,sp,96
    80003780:	8082                	ret

0000000080003782 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003782:	7179                	addi	sp,sp,-48
    80003784:	f406                	sd	ra,40(sp)
    80003786:	f022                	sd	s0,32(sp)
    80003788:	ec26                	sd	s1,24(sp)
    8000378a:	e84a                	sd	s2,16(sp)
    8000378c:	e44e                	sd	s3,8(sp)
    8000378e:	e052                	sd	s4,0(sp)
    80003790:	1800                	addi	s0,sp,48
    80003792:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003794:	47ad                	li	a5,11
    80003796:	04b7fe63          	bgeu	a5,a1,800037f2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000379a:	ff45849b          	addiw	s1,a1,-12
    8000379e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800037a2:	0ff00793          	li	a5,255
    800037a6:	0ae7e463          	bltu	a5,a4,8000384e <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800037aa:	08052583          	lw	a1,128(a0)
    800037ae:	c5b5                	beqz	a1,8000381a <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800037b0:	00092503          	lw	a0,0(s2)
    800037b4:	00000097          	auipc	ra,0x0
    800037b8:	bda080e7          	jalr	-1062(ra) # 8000338e <bread>
    800037bc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037be:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800037c2:	02049713          	slli	a4,s1,0x20
    800037c6:	01e75593          	srli	a1,a4,0x1e
    800037ca:	00b784b3          	add	s1,a5,a1
    800037ce:	0004a983          	lw	s3,0(s1)
    800037d2:	04098e63          	beqz	s3,8000382e <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800037d6:	8552                	mv	a0,s4
    800037d8:	00000097          	auipc	ra,0x0
    800037dc:	ce6080e7          	jalr	-794(ra) # 800034be <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037e0:	854e                	mv	a0,s3
    800037e2:	70a2                	ld	ra,40(sp)
    800037e4:	7402                	ld	s0,32(sp)
    800037e6:	64e2                	ld	s1,24(sp)
    800037e8:	6942                	ld	s2,16(sp)
    800037ea:	69a2                	ld	s3,8(sp)
    800037ec:	6a02                	ld	s4,0(sp)
    800037ee:	6145                	addi	sp,sp,48
    800037f0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800037f2:	02059793          	slli	a5,a1,0x20
    800037f6:	01e7d593          	srli	a1,a5,0x1e
    800037fa:	00b504b3          	add	s1,a0,a1
    800037fe:	0504a983          	lw	s3,80(s1)
    80003802:	fc099fe3          	bnez	s3,800037e0 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003806:	4108                	lw	a0,0(a0)
    80003808:	00000097          	auipc	ra,0x0
    8000380c:	e48080e7          	jalr	-440(ra) # 80003650 <balloc>
    80003810:	0005099b          	sext.w	s3,a0
    80003814:	0534a823          	sw	s3,80(s1)
    80003818:	b7e1                	j	800037e0 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000381a:	4108                	lw	a0,0(a0)
    8000381c:	00000097          	auipc	ra,0x0
    80003820:	e34080e7          	jalr	-460(ra) # 80003650 <balloc>
    80003824:	0005059b          	sext.w	a1,a0
    80003828:	08b92023          	sw	a1,128(s2)
    8000382c:	b751                	j	800037b0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000382e:	00092503          	lw	a0,0(s2)
    80003832:	00000097          	auipc	ra,0x0
    80003836:	e1e080e7          	jalr	-482(ra) # 80003650 <balloc>
    8000383a:	0005099b          	sext.w	s3,a0
    8000383e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003842:	8552                	mv	a0,s4
    80003844:	00001097          	auipc	ra,0x1
    80003848:	efc080e7          	jalr	-260(ra) # 80004740 <log_write>
    8000384c:	b769                	j	800037d6 <bmap+0x54>
  panic("bmap: out of range");
    8000384e:	00005517          	auipc	a0,0x5
    80003852:	f4a50513          	addi	a0,a0,-182 # 80008798 <syscalls+0x130>
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	cd4080e7          	jalr	-812(ra) # 8000052a <panic>

000000008000385e <iget>:
{
    8000385e:	7179                	addi	sp,sp,-48
    80003860:	f406                	sd	ra,40(sp)
    80003862:	f022                	sd	s0,32(sp)
    80003864:	ec26                	sd	s1,24(sp)
    80003866:	e84a                	sd	s2,16(sp)
    80003868:	e44e                	sd	s3,8(sp)
    8000386a:	e052                	sd	s4,0(sp)
    8000386c:	1800                	addi	s0,sp,48
    8000386e:	89aa                	mv	s3,a0
    80003870:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003872:	0001c517          	auipc	a0,0x1c
    80003876:	76e50513          	addi	a0,a0,1902 # 8001ffe0 <itable>
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	348080e7          	jalr	840(ra) # 80000bc2 <acquire>
  empty = 0;
    80003882:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003884:	0001c497          	auipc	s1,0x1c
    80003888:	77448493          	addi	s1,s1,1908 # 8001fff8 <itable+0x18>
    8000388c:	0001e697          	auipc	a3,0x1e
    80003890:	1fc68693          	addi	a3,a3,508 # 80021a88 <log>
    80003894:	a039                	j	800038a2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003896:	02090b63          	beqz	s2,800038cc <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000389a:	08848493          	addi	s1,s1,136
    8000389e:	02d48a63          	beq	s1,a3,800038d2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038a2:	449c                	lw	a5,8(s1)
    800038a4:	fef059e3          	blez	a5,80003896 <iget+0x38>
    800038a8:	4098                	lw	a4,0(s1)
    800038aa:	ff3716e3          	bne	a4,s3,80003896 <iget+0x38>
    800038ae:	40d8                	lw	a4,4(s1)
    800038b0:	ff4713e3          	bne	a4,s4,80003896 <iget+0x38>
      ip->ref++;
    800038b4:	2785                	addiw	a5,a5,1
    800038b6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800038b8:	0001c517          	auipc	a0,0x1c
    800038bc:	72850513          	addi	a0,a0,1832 # 8001ffe0 <itable>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	3b6080e7          	jalr	950(ra) # 80000c76 <release>
      return ip;
    800038c8:	8926                	mv	s2,s1
    800038ca:	a03d                	j	800038f8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038cc:	f7f9                	bnez	a5,8000389a <iget+0x3c>
    800038ce:	8926                	mv	s2,s1
    800038d0:	b7e9                	j	8000389a <iget+0x3c>
  if(empty == 0)
    800038d2:	02090c63          	beqz	s2,8000390a <iget+0xac>
  ip->dev = dev;
    800038d6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038da:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038de:	4785                	li	a5,1
    800038e0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038e4:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800038e8:	0001c517          	auipc	a0,0x1c
    800038ec:	6f850513          	addi	a0,a0,1784 # 8001ffe0 <itable>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	386080e7          	jalr	902(ra) # 80000c76 <release>
}
    800038f8:	854a                	mv	a0,s2
    800038fa:	70a2                	ld	ra,40(sp)
    800038fc:	7402                	ld	s0,32(sp)
    800038fe:	64e2                	ld	s1,24(sp)
    80003900:	6942                	ld	s2,16(sp)
    80003902:	69a2                	ld	s3,8(sp)
    80003904:	6a02                	ld	s4,0(sp)
    80003906:	6145                	addi	sp,sp,48
    80003908:	8082                	ret
    panic("iget: no inodes");
    8000390a:	00005517          	auipc	a0,0x5
    8000390e:	ea650513          	addi	a0,a0,-346 # 800087b0 <syscalls+0x148>
    80003912:	ffffd097          	auipc	ra,0xffffd
    80003916:	c18080e7          	jalr	-1000(ra) # 8000052a <panic>

000000008000391a <fsinit>:
fsinit(int dev) {
    8000391a:	7179                	addi	sp,sp,-48
    8000391c:	f406                	sd	ra,40(sp)
    8000391e:	f022                	sd	s0,32(sp)
    80003920:	ec26                	sd	s1,24(sp)
    80003922:	e84a                	sd	s2,16(sp)
    80003924:	e44e                	sd	s3,8(sp)
    80003926:	1800                	addi	s0,sp,48
    80003928:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000392a:	4585                	li	a1,1
    8000392c:	00000097          	auipc	ra,0x0
    80003930:	a62080e7          	jalr	-1438(ra) # 8000338e <bread>
    80003934:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003936:	0001c997          	auipc	s3,0x1c
    8000393a:	68a98993          	addi	s3,s3,1674 # 8001ffc0 <sb>
    8000393e:	02000613          	li	a2,32
    80003942:	05850593          	addi	a1,a0,88
    80003946:	854e                	mv	a0,s3
    80003948:	ffffd097          	auipc	ra,0xffffd
    8000394c:	3d2080e7          	jalr	978(ra) # 80000d1a <memmove>
  brelse(bp);
    80003950:	8526                	mv	a0,s1
    80003952:	00000097          	auipc	ra,0x0
    80003956:	b6c080e7          	jalr	-1172(ra) # 800034be <brelse>
  if(sb.magic != FSMAGIC)
    8000395a:	0009a703          	lw	a4,0(s3)
    8000395e:	102037b7          	lui	a5,0x10203
    80003962:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003966:	02f71263          	bne	a4,a5,8000398a <fsinit+0x70>
  initlog(dev, &sb);
    8000396a:	0001c597          	auipc	a1,0x1c
    8000396e:	65658593          	addi	a1,a1,1622 # 8001ffc0 <sb>
    80003972:	854a                	mv	a0,s2
    80003974:	00001097          	auipc	ra,0x1
    80003978:	b4e080e7          	jalr	-1202(ra) # 800044c2 <initlog>
}
    8000397c:	70a2                	ld	ra,40(sp)
    8000397e:	7402                	ld	s0,32(sp)
    80003980:	64e2                	ld	s1,24(sp)
    80003982:	6942                	ld	s2,16(sp)
    80003984:	69a2                	ld	s3,8(sp)
    80003986:	6145                	addi	sp,sp,48
    80003988:	8082                	ret
    panic("invalid file system");
    8000398a:	00005517          	auipc	a0,0x5
    8000398e:	e3650513          	addi	a0,a0,-458 # 800087c0 <syscalls+0x158>
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	b98080e7          	jalr	-1128(ra) # 8000052a <panic>

000000008000399a <iinit>:
{
    8000399a:	7179                	addi	sp,sp,-48
    8000399c:	f406                	sd	ra,40(sp)
    8000399e:	f022                	sd	s0,32(sp)
    800039a0:	ec26                	sd	s1,24(sp)
    800039a2:	e84a                	sd	s2,16(sp)
    800039a4:	e44e                	sd	s3,8(sp)
    800039a6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800039a8:	00005597          	auipc	a1,0x5
    800039ac:	e3058593          	addi	a1,a1,-464 # 800087d8 <syscalls+0x170>
    800039b0:	0001c517          	auipc	a0,0x1c
    800039b4:	63050513          	addi	a0,a0,1584 # 8001ffe0 <itable>
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	17a080e7          	jalr	378(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    800039c0:	0001c497          	auipc	s1,0x1c
    800039c4:	64848493          	addi	s1,s1,1608 # 80020008 <itable+0x28>
    800039c8:	0001e997          	auipc	s3,0x1e
    800039cc:	0d098993          	addi	s3,s3,208 # 80021a98 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800039d0:	00005917          	auipc	s2,0x5
    800039d4:	e1090913          	addi	s2,s2,-496 # 800087e0 <syscalls+0x178>
    800039d8:	85ca                	mv	a1,s2
    800039da:	8526                	mv	a0,s1
    800039dc:	00001097          	auipc	ra,0x1
    800039e0:	e4a080e7          	jalr	-438(ra) # 80004826 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039e4:	08848493          	addi	s1,s1,136
    800039e8:	ff3498e3          	bne	s1,s3,800039d8 <iinit+0x3e>
}
    800039ec:	70a2                	ld	ra,40(sp)
    800039ee:	7402                	ld	s0,32(sp)
    800039f0:	64e2                	ld	s1,24(sp)
    800039f2:	6942                	ld	s2,16(sp)
    800039f4:	69a2                	ld	s3,8(sp)
    800039f6:	6145                	addi	sp,sp,48
    800039f8:	8082                	ret

00000000800039fa <ialloc>:
{
    800039fa:	715d                	addi	sp,sp,-80
    800039fc:	e486                	sd	ra,72(sp)
    800039fe:	e0a2                	sd	s0,64(sp)
    80003a00:	fc26                	sd	s1,56(sp)
    80003a02:	f84a                	sd	s2,48(sp)
    80003a04:	f44e                	sd	s3,40(sp)
    80003a06:	f052                	sd	s4,32(sp)
    80003a08:	ec56                	sd	s5,24(sp)
    80003a0a:	e85a                	sd	s6,16(sp)
    80003a0c:	e45e                	sd	s7,8(sp)
    80003a0e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a10:	0001c717          	auipc	a4,0x1c
    80003a14:	5bc72703          	lw	a4,1468(a4) # 8001ffcc <sb+0xc>
    80003a18:	4785                	li	a5,1
    80003a1a:	04e7fa63          	bgeu	a5,a4,80003a6e <ialloc+0x74>
    80003a1e:	8aaa                	mv	s5,a0
    80003a20:	8bae                	mv	s7,a1
    80003a22:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a24:	0001ca17          	auipc	s4,0x1c
    80003a28:	59ca0a13          	addi	s4,s4,1436 # 8001ffc0 <sb>
    80003a2c:	00048b1b          	sext.w	s6,s1
    80003a30:	0044d793          	srli	a5,s1,0x4
    80003a34:	018a2583          	lw	a1,24(s4)
    80003a38:	9dbd                	addw	a1,a1,a5
    80003a3a:	8556                	mv	a0,s5
    80003a3c:	00000097          	auipc	ra,0x0
    80003a40:	952080e7          	jalr	-1710(ra) # 8000338e <bread>
    80003a44:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a46:	05850993          	addi	s3,a0,88
    80003a4a:	00f4f793          	andi	a5,s1,15
    80003a4e:	079a                	slli	a5,a5,0x6
    80003a50:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a52:	00099783          	lh	a5,0(s3)
    80003a56:	c785                	beqz	a5,80003a7e <ialloc+0x84>
    brelse(bp);
    80003a58:	00000097          	auipc	ra,0x0
    80003a5c:	a66080e7          	jalr	-1434(ra) # 800034be <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a60:	0485                	addi	s1,s1,1
    80003a62:	00ca2703          	lw	a4,12(s4)
    80003a66:	0004879b          	sext.w	a5,s1
    80003a6a:	fce7e1e3          	bltu	a5,a4,80003a2c <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a6e:	00005517          	auipc	a0,0x5
    80003a72:	d7a50513          	addi	a0,a0,-646 # 800087e8 <syscalls+0x180>
    80003a76:	ffffd097          	auipc	ra,0xffffd
    80003a7a:	ab4080e7          	jalr	-1356(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003a7e:	04000613          	li	a2,64
    80003a82:	4581                	li	a1,0
    80003a84:	854e                	mv	a0,s3
    80003a86:	ffffd097          	auipc	ra,0xffffd
    80003a8a:	238080e7          	jalr	568(ra) # 80000cbe <memset>
      dip->type = type;
    80003a8e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a92:	854a                	mv	a0,s2
    80003a94:	00001097          	auipc	ra,0x1
    80003a98:	cac080e7          	jalr	-852(ra) # 80004740 <log_write>
      brelse(bp);
    80003a9c:	854a                	mv	a0,s2
    80003a9e:	00000097          	auipc	ra,0x0
    80003aa2:	a20080e7          	jalr	-1504(ra) # 800034be <brelse>
      return iget(dev, inum);
    80003aa6:	85da                	mv	a1,s6
    80003aa8:	8556                	mv	a0,s5
    80003aaa:	00000097          	auipc	ra,0x0
    80003aae:	db4080e7          	jalr	-588(ra) # 8000385e <iget>
}
    80003ab2:	60a6                	ld	ra,72(sp)
    80003ab4:	6406                	ld	s0,64(sp)
    80003ab6:	74e2                	ld	s1,56(sp)
    80003ab8:	7942                	ld	s2,48(sp)
    80003aba:	79a2                	ld	s3,40(sp)
    80003abc:	7a02                	ld	s4,32(sp)
    80003abe:	6ae2                	ld	s5,24(sp)
    80003ac0:	6b42                	ld	s6,16(sp)
    80003ac2:	6ba2                	ld	s7,8(sp)
    80003ac4:	6161                	addi	sp,sp,80
    80003ac6:	8082                	ret

0000000080003ac8 <iupdate>:
{
    80003ac8:	1101                	addi	sp,sp,-32
    80003aca:	ec06                	sd	ra,24(sp)
    80003acc:	e822                	sd	s0,16(sp)
    80003ace:	e426                	sd	s1,8(sp)
    80003ad0:	e04a                	sd	s2,0(sp)
    80003ad2:	1000                	addi	s0,sp,32
    80003ad4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ad6:	415c                	lw	a5,4(a0)
    80003ad8:	0047d79b          	srliw	a5,a5,0x4
    80003adc:	0001c597          	auipc	a1,0x1c
    80003ae0:	4fc5a583          	lw	a1,1276(a1) # 8001ffd8 <sb+0x18>
    80003ae4:	9dbd                	addw	a1,a1,a5
    80003ae6:	4108                	lw	a0,0(a0)
    80003ae8:	00000097          	auipc	ra,0x0
    80003aec:	8a6080e7          	jalr	-1882(ra) # 8000338e <bread>
    80003af0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003af2:	05850793          	addi	a5,a0,88
    80003af6:	40c8                	lw	a0,4(s1)
    80003af8:	893d                	andi	a0,a0,15
    80003afa:	051a                	slli	a0,a0,0x6
    80003afc:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003afe:	04449703          	lh	a4,68(s1)
    80003b02:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b06:	04649703          	lh	a4,70(s1)
    80003b0a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b0e:	04849703          	lh	a4,72(s1)
    80003b12:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b16:	04a49703          	lh	a4,74(s1)
    80003b1a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b1e:	44f8                	lw	a4,76(s1)
    80003b20:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b22:	03400613          	li	a2,52
    80003b26:	05048593          	addi	a1,s1,80
    80003b2a:	0531                	addi	a0,a0,12
    80003b2c:	ffffd097          	auipc	ra,0xffffd
    80003b30:	1ee080e7          	jalr	494(ra) # 80000d1a <memmove>
  log_write(bp);
    80003b34:	854a                	mv	a0,s2
    80003b36:	00001097          	auipc	ra,0x1
    80003b3a:	c0a080e7          	jalr	-1014(ra) # 80004740 <log_write>
  brelse(bp);
    80003b3e:	854a                	mv	a0,s2
    80003b40:	00000097          	auipc	ra,0x0
    80003b44:	97e080e7          	jalr	-1666(ra) # 800034be <brelse>
}
    80003b48:	60e2                	ld	ra,24(sp)
    80003b4a:	6442                	ld	s0,16(sp)
    80003b4c:	64a2                	ld	s1,8(sp)
    80003b4e:	6902                	ld	s2,0(sp)
    80003b50:	6105                	addi	sp,sp,32
    80003b52:	8082                	ret

0000000080003b54 <idup>:
{
    80003b54:	1101                	addi	sp,sp,-32
    80003b56:	ec06                	sd	ra,24(sp)
    80003b58:	e822                	sd	s0,16(sp)
    80003b5a:	e426                	sd	s1,8(sp)
    80003b5c:	1000                	addi	s0,sp,32
    80003b5e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b60:	0001c517          	auipc	a0,0x1c
    80003b64:	48050513          	addi	a0,a0,1152 # 8001ffe0 <itable>
    80003b68:	ffffd097          	auipc	ra,0xffffd
    80003b6c:	05a080e7          	jalr	90(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003b70:	449c                	lw	a5,8(s1)
    80003b72:	2785                	addiw	a5,a5,1
    80003b74:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b76:	0001c517          	auipc	a0,0x1c
    80003b7a:	46a50513          	addi	a0,a0,1130 # 8001ffe0 <itable>
    80003b7e:	ffffd097          	auipc	ra,0xffffd
    80003b82:	0f8080e7          	jalr	248(ra) # 80000c76 <release>
}
    80003b86:	8526                	mv	a0,s1
    80003b88:	60e2                	ld	ra,24(sp)
    80003b8a:	6442                	ld	s0,16(sp)
    80003b8c:	64a2                	ld	s1,8(sp)
    80003b8e:	6105                	addi	sp,sp,32
    80003b90:	8082                	ret

0000000080003b92 <ilock>:
{
    80003b92:	1101                	addi	sp,sp,-32
    80003b94:	ec06                	sd	ra,24(sp)
    80003b96:	e822                	sd	s0,16(sp)
    80003b98:	e426                	sd	s1,8(sp)
    80003b9a:	e04a                	sd	s2,0(sp)
    80003b9c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b9e:	c115                	beqz	a0,80003bc2 <ilock+0x30>
    80003ba0:	84aa                	mv	s1,a0
    80003ba2:	451c                	lw	a5,8(a0)
    80003ba4:	00f05f63          	blez	a5,80003bc2 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ba8:	0541                	addi	a0,a0,16
    80003baa:	00001097          	auipc	ra,0x1
    80003bae:	cb6080e7          	jalr	-842(ra) # 80004860 <acquiresleep>
  if(ip->valid == 0){
    80003bb2:	40bc                	lw	a5,64(s1)
    80003bb4:	cf99                	beqz	a5,80003bd2 <ilock+0x40>
}
    80003bb6:	60e2                	ld	ra,24(sp)
    80003bb8:	6442                	ld	s0,16(sp)
    80003bba:	64a2                	ld	s1,8(sp)
    80003bbc:	6902                	ld	s2,0(sp)
    80003bbe:	6105                	addi	sp,sp,32
    80003bc0:	8082                	ret
    panic("ilock");
    80003bc2:	00005517          	auipc	a0,0x5
    80003bc6:	c3e50513          	addi	a0,a0,-962 # 80008800 <syscalls+0x198>
    80003bca:	ffffd097          	auipc	ra,0xffffd
    80003bce:	960080e7          	jalr	-1696(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bd2:	40dc                	lw	a5,4(s1)
    80003bd4:	0047d79b          	srliw	a5,a5,0x4
    80003bd8:	0001c597          	auipc	a1,0x1c
    80003bdc:	4005a583          	lw	a1,1024(a1) # 8001ffd8 <sb+0x18>
    80003be0:	9dbd                	addw	a1,a1,a5
    80003be2:	4088                	lw	a0,0(s1)
    80003be4:	fffff097          	auipc	ra,0xfffff
    80003be8:	7aa080e7          	jalr	1962(ra) # 8000338e <bread>
    80003bec:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bee:	05850593          	addi	a1,a0,88
    80003bf2:	40dc                	lw	a5,4(s1)
    80003bf4:	8bbd                	andi	a5,a5,15
    80003bf6:	079a                	slli	a5,a5,0x6
    80003bf8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003bfa:	00059783          	lh	a5,0(a1)
    80003bfe:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c02:	00259783          	lh	a5,2(a1)
    80003c06:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c0a:	00459783          	lh	a5,4(a1)
    80003c0e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c12:	00659783          	lh	a5,6(a1)
    80003c16:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c1a:	459c                	lw	a5,8(a1)
    80003c1c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c1e:	03400613          	li	a2,52
    80003c22:	05b1                	addi	a1,a1,12
    80003c24:	05048513          	addi	a0,s1,80
    80003c28:	ffffd097          	auipc	ra,0xffffd
    80003c2c:	0f2080e7          	jalr	242(ra) # 80000d1a <memmove>
    brelse(bp);
    80003c30:	854a                	mv	a0,s2
    80003c32:	00000097          	auipc	ra,0x0
    80003c36:	88c080e7          	jalr	-1908(ra) # 800034be <brelse>
    ip->valid = 1;
    80003c3a:	4785                	li	a5,1
    80003c3c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c3e:	04449783          	lh	a5,68(s1)
    80003c42:	fbb5                	bnez	a5,80003bb6 <ilock+0x24>
      panic("ilock: no type");
    80003c44:	00005517          	auipc	a0,0x5
    80003c48:	bc450513          	addi	a0,a0,-1084 # 80008808 <syscalls+0x1a0>
    80003c4c:	ffffd097          	auipc	ra,0xffffd
    80003c50:	8de080e7          	jalr	-1826(ra) # 8000052a <panic>

0000000080003c54 <iunlock>:
{
    80003c54:	1101                	addi	sp,sp,-32
    80003c56:	ec06                	sd	ra,24(sp)
    80003c58:	e822                	sd	s0,16(sp)
    80003c5a:	e426                	sd	s1,8(sp)
    80003c5c:	e04a                	sd	s2,0(sp)
    80003c5e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c60:	c905                	beqz	a0,80003c90 <iunlock+0x3c>
    80003c62:	84aa                	mv	s1,a0
    80003c64:	01050913          	addi	s2,a0,16
    80003c68:	854a                	mv	a0,s2
    80003c6a:	00001097          	auipc	ra,0x1
    80003c6e:	c90080e7          	jalr	-880(ra) # 800048fa <holdingsleep>
    80003c72:	cd19                	beqz	a0,80003c90 <iunlock+0x3c>
    80003c74:	449c                	lw	a5,8(s1)
    80003c76:	00f05d63          	blez	a5,80003c90 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c7a:	854a                	mv	a0,s2
    80003c7c:	00001097          	auipc	ra,0x1
    80003c80:	c3a080e7          	jalr	-966(ra) # 800048b6 <releasesleep>
}
    80003c84:	60e2                	ld	ra,24(sp)
    80003c86:	6442                	ld	s0,16(sp)
    80003c88:	64a2                	ld	s1,8(sp)
    80003c8a:	6902                	ld	s2,0(sp)
    80003c8c:	6105                	addi	sp,sp,32
    80003c8e:	8082                	ret
    panic("iunlock");
    80003c90:	00005517          	auipc	a0,0x5
    80003c94:	b8850513          	addi	a0,a0,-1144 # 80008818 <syscalls+0x1b0>
    80003c98:	ffffd097          	auipc	ra,0xffffd
    80003c9c:	892080e7          	jalr	-1902(ra) # 8000052a <panic>

0000000080003ca0 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ca0:	7179                	addi	sp,sp,-48
    80003ca2:	f406                	sd	ra,40(sp)
    80003ca4:	f022                	sd	s0,32(sp)
    80003ca6:	ec26                	sd	s1,24(sp)
    80003ca8:	e84a                	sd	s2,16(sp)
    80003caa:	e44e                	sd	s3,8(sp)
    80003cac:	e052                	sd	s4,0(sp)
    80003cae:	1800                	addi	s0,sp,48
    80003cb0:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cb2:	05050493          	addi	s1,a0,80
    80003cb6:	08050913          	addi	s2,a0,128
    80003cba:	a021                	j	80003cc2 <itrunc+0x22>
    80003cbc:	0491                	addi	s1,s1,4
    80003cbe:	01248d63          	beq	s1,s2,80003cd8 <itrunc+0x38>
    if(ip->addrs[i]){
    80003cc2:	408c                	lw	a1,0(s1)
    80003cc4:	dde5                	beqz	a1,80003cbc <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cc6:	0009a503          	lw	a0,0(s3)
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	90a080e7          	jalr	-1782(ra) # 800035d4 <bfree>
      ip->addrs[i] = 0;
    80003cd2:	0004a023          	sw	zero,0(s1)
    80003cd6:	b7dd                	j	80003cbc <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cd8:	0809a583          	lw	a1,128(s3)
    80003cdc:	e185                	bnez	a1,80003cfc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003cde:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ce2:	854e                	mv	a0,s3
    80003ce4:	00000097          	auipc	ra,0x0
    80003ce8:	de4080e7          	jalr	-540(ra) # 80003ac8 <iupdate>
}
    80003cec:	70a2                	ld	ra,40(sp)
    80003cee:	7402                	ld	s0,32(sp)
    80003cf0:	64e2                	ld	s1,24(sp)
    80003cf2:	6942                	ld	s2,16(sp)
    80003cf4:	69a2                	ld	s3,8(sp)
    80003cf6:	6a02                	ld	s4,0(sp)
    80003cf8:	6145                	addi	sp,sp,48
    80003cfa:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003cfc:	0009a503          	lw	a0,0(s3)
    80003d00:	fffff097          	auipc	ra,0xfffff
    80003d04:	68e080e7          	jalr	1678(ra) # 8000338e <bread>
    80003d08:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d0a:	05850493          	addi	s1,a0,88
    80003d0e:	45850913          	addi	s2,a0,1112
    80003d12:	a021                	j	80003d1a <itrunc+0x7a>
    80003d14:	0491                	addi	s1,s1,4
    80003d16:	01248b63          	beq	s1,s2,80003d2c <itrunc+0x8c>
      if(a[j])
    80003d1a:	408c                	lw	a1,0(s1)
    80003d1c:	dde5                	beqz	a1,80003d14 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003d1e:	0009a503          	lw	a0,0(s3)
    80003d22:	00000097          	auipc	ra,0x0
    80003d26:	8b2080e7          	jalr	-1870(ra) # 800035d4 <bfree>
    80003d2a:	b7ed                	j	80003d14 <itrunc+0x74>
    brelse(bp);
    80003d2c:	8552                	mv	a0,s4
    80003d2e:	fffff097          	auipc	ra,0xfffff
    80003d32:	790080e7          	jalr	1936(ra) # 800034be <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d36:	0809a583          	lw	a1,128(s3)
    80003d3a:	0009a503          	lw	a0,0(s3)
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	896080e7          	jalr	-1898(ra) # 800035d4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d46:	0809a023          	sw	zero,128(s3)
    80003d4a:	bf51                	j	80003cde <itrunc+0x3e>

0000000080003d4c <iput>:
{
    80003d4c:	1101                	addi	sp,sp,-32
    80003d4e:	ec06                	sd	ra,24(sp)
    80003d50:	e822                	sd	s0,16(sp)
    80003d52:	e426                	sd	s1,8(sp)
    80003d54:	e04a                	sd	s2,0(sp)
    80003d56:	1000                	addi	s0,sp,32
    80003d58:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d5a:	0001c517          	auipc	a0,0x1c
    80003d5e:	28650513          	addi	a0,a0,646 # 8001ffe0 <itable>
    80003d62:	ffffd097          	auipc	ra,0xffffd
    80003d66:	e60080e7          	jalr	-416(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d6a:	4498                	lw	a4,8(s1)
    80003d6c:	4785                	li	a5,1
    80003d6e:	02f70363          	beq	a4,a5,80003d94 <iput+0x48>
  ip->ref--;
    80003d72:	449c                	lw	a5,8(s1)
    80003d74:	37fd                	addiw	a5,a5,-1
    80003d76:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d78:	0001c517          	auipc	a0,0x1c
    80003d7c:	26850513          	addi	a0,a0,616 # 8001ffe0 <itable>
    80003d80:	ffffd097          	auipc	ra,0xffffd
    80003d84:	ef6080e7          	jalr	-266(ra) # 80000c76 <release>
}
    80003d88:	60e2                	ld	ra,24(sp)
    80003d8a:	6442                	ld	s0,16(sp)
    80003d8c:	64a2                	ld	s1,8(sp)
    80003d8e:	6902                	ld	s2,0(sp)
    80003d90:	6105                	addi	sp,sp,32
    80003d92:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d94:	40bc                	lw	a5,64(s1)
    80003d96:	dff1                	beqz	a5,80003d72 <iput+0x26>
    80003d98:	04a49783          	lh	a5,74(s1)
    80003d9c:	fbf9                	bnez	a5,80003d72 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d9e:	01048913          	addi	s2,s1,16
    80003da2:	854a                	mv	a0,s2
    80003da4:	00001097          	auipc	ra,0x1
    80003da8:	abc080e7          	jalr	-1348(ra) # 80004860 <acquiresleep>
    release(&itable.lock);
    80003dac:	0001c517          	auipc	a0,0x1c
    80003db0:	23450513          	addi	a0,a0,564 # 8001ffe0 <itable>
    80003db4:	ffffd097          	auipc	ra,0xffffd
    80003db8:	ec2080e7          	jalr	-318(ra) # 80000c76 <release>
    itrunc(ip);
    80003dbc:	8526                	mv	a0,s1
    80003dbe:	00000097          	auipc	ra,0x0
    80003dc2:	ee2080e7          	jalr	-286(ra) # 80003ca0 <itrunc>
    ip->type = 0;
    80003dc6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003dca:	8526                	mv	a0,s1
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	cfc080e7          	jalr	-772(ra) # 80003ac8 <iupdate>
    ip->valid = 0;
    80003dd4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003dd8:	854a                	mv	a0,s2
    80003dda:	00001097          	auipc	ra,0x1
    80003dde:	adc080e7          	jalr	-1316(ra) # 800048b6 <releasesleep>
    acquire(&itable.lock);
    80003de2:	0001c517          	auipc	a0,0x1c
    80003de6:	1fe50513          	addi	a0,a0,510 # 8001ffe0 <itable>
    80003dea:	ffffd097          	auipc	ra,0xffffd
    80003dee:	dd8080e7          	jalr	-552(ra) # 80000bc2 <acquire>
    80003df2:	b741                	j	80003d72 <iput+0x26>

0000000080003df4 <iunlockput>:
{
    80003df4:	1101                	addi	sp,sp,-32
    80003df6:	ec06                	sd	ra,24(sp)
    80003df8:	e822                	sd	s0,16(sp)
    80003dfa:	e426                	sd	s1,8(sp)
    80003dfc:	1000                	addi	s0,sp,32
    80003dfe:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e00:	00000097          	auipc	ra,0x0
    80003e04:	e54080e7          	jalr	-428(ra) # 80003c54 <iunlock>
  iput(ip);
    80003e08:	8526                	mv	a0,s1
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	f42080e7          	jalr	-190(ra) # 80003d4c <iput>
}
    80003e12:	60e2                	ld	ra,24(sp)
    80003e14:	6442                	ld	s0,16(sp)
    80003e16:	64a2                	ld	s1,8(sp)
    80003e18:	6105                	addi	sp,sp,32
    80003e1a:	8082                	ret

0000000080003e1c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e1c:	1141                	addi	sp,sp,-16
    80003e1e:	e422                	sd	s0,8(sp)
    80003e20:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e22:	411c                	lw	a5,0(a0)
    80003e24:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e26:	415c                	lw	a5,4(a0)
    80003e28:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e2a:	04451783          	lh	a5,68(a0)
    80003e2e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e32:	04a51783          	lh	a5,74(a0)
    80003e36:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e3a:	04c56783          	lwu	a5,76(a0)
    80003e3e:	e99c                	sd	a5,16(a1)
}
    80003e40:	6422                	ld	s0,8(sp)
    80003e42:	0141                	addi	sp,sp,16
    80003e44:	8082                	ret

0000000080003e46 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e46:	457c                	lw	a5,76(a0)
    80003e48:	0ed7e963          	bltu	a5,a3,80003f3a <readi+0xf4>
{
    80003e4c:	7159                	addi	sp,sp,-112
    80003e4e:	f486                	sd	ra,104(sp)
    80003e50:	f0a2                	sd	s0,96(sp)
    80003e52:	eca6                	sd	s1,88(sp)
    80003e54:	e8ca                	sd	s2,80(sp)
    80003e56:	e4ce                	sd	s3,72(sp)
    80003e58:	e0d2                	sd	s4,64(sp)
    80003e5a:	fc56                	sd	s5,56(sp)
    80003e5c:	f85a                	sd	s6,48(sp)
    80003e5e:	f45e                	sd	s7,40(sp)
    80003e60:	f062                	sd	s8,32(sp)
    80003e62:	ec66                	sd	s9,24(sp)
    80003e64:	e86a                	sd	s10,16(sp)
    80003e66:	e46e                	sd	s11,8(sp)
    80003e68:	1880                	addi	s0,sp,112
    80003e6a:	8baa                	mv	s7,a0
    80003e6c:	8c2e                	mv	s8,a1
    80003e6e:	8ab2                	mv	s5,a2
    80003e70:	84b6                	mv	s1,a3
    80003e72:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e74:	9f35                	addw	a4,a4,a3
    return 0;
    80003e76:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e78:	0ad76063          	bltu	a4,a3,80003f18 <readi+0xd2>
  if(off + n > ip->size)
    80003e7c:	00e7f463          	bgeu	a5,a4,80003e84 <readi+0x3e>
    n = ip->size - off;
    80003e80:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e84:	0a0b0963          	beqz	s6,80003f36 <readi+0xf0>
    80003e88:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e8a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e8e:	5cfd                	li	s9,-1
    80003e90:	a82d                	j	80003eca <readi+0x84>
    80003e92:	020a1d93          	slli	s11,s4,0x20
    80003e96:	020ddd93          	srli	s11,s11,0x20
    80003e9a:	05890793          	addi	a5,s2,88
    80003e9e:	86ee                	mv	a3,s11
    80003ea0:	963e                	add	a2,a2,a5
    80003ea2:	85d6                	mv	a1,s5
    80003ea4:	8562                	mv	a0,s8
    80003ea6:	ffffe097          	auipc	ra,0xffffe
    80003eaa:	6f6080e7          	jalr	1782(ra) # 8000259c <either_copyout>
    80003eae:	05950d63          	beq	a0,s9,80003f08 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003eb2:	854a                	mv	a0,s2
    80003eb4:	fffff097          	auipc	ra,0xfffff
    80003eb8:	60a080e7          	jalr	1546(ra) # 800034be <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ebc:	013a09bb          	addw	s3,s4,s3
    80003ec0:	009a04bb          	addw	s1,s4,s1
    80003ec4:	9aee                	add	s5,s5,s11
    80003ec6:	0569f763          	bgeu	s3,s6,80003f14 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003eca:	000ba903          	lw	s2,0(s7)
    80003ece:	00a4d59b          	srliw	a1,s1,0xa
    80003ed2:	855e                	mv	a0,s7
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	8ae080e7          	jalr	-1874(ra) # 80003782 <bmap>
    80003edc:	0005059b          	sext.w	a1,a0
    80003ee0:	854a                	mv	a0,s2
    80003ee2:	fffff097          	auipc	ra,0xfffff
    80003ee6:	4ac080e7          	jalr	1196(ra) # 8000338e <bread>
    80003eea:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eec:	3ff4f613          	andi	a2,s1,1023
    80003ef0:	40cd07bb          	subw	a5,s10,a2
    80003ef4:	413b073b          	subw	a4,s6,s3
    80003ef8:	8a3e                	mv	s4,a5
    80003efa:	2781                	sext.w	a5,a5
    80003efc:	0007069b          	sext.w	a3,a4
    80003f00:	f8f6f9e3          	bgeu	a3,a5,80003e92 <readi+0x4c>
    80003f04:	8a3a                	mv	s4,a4
    80003f06:	b771                	j	80003e92 <readi+0x4c>
      brelse(bp);
    80003f08:	854a                	mv	a0,s2
    80003f0a:	fffff097          	auipc	ra,0xfffff
    80003f0e:	5b4080e7          	jalr	1460(ra) # 800034be <brelse>
      tot = -1;
    80003f12:	59fd                	li	s3,-1
  }
  return tot;
    80003f14:	0009851b          	sext.w	a0,s3
}
    80003f18:	70a6                	ld	ra,104(sp)
    80003f1a:	7406                	ld	s0,96(sp)
    80003f1c:	64e6                	ld	s1,88(sp)
    80003f1e:	6946                	ld	s2,80(sp)
    80003f20:	69a6                	ld	s3,72(sp)
    80003f22:	6a06                	ld	s4,64(sp)
    80003f24:	7ae2                	ld	s5,56(sp)
    80003f26:	7b42                	ld	s6,48(sp)
    80003f28:	7ba2                	ld	s7,40(sp)
    80003f2a:	7c02                	ld	s8,32(sp)
    80003f2c:	6ce2                	ld	s9,24(sp)
    80003f2e:	6d42                	ld	s10,16(sp)
    80003f30:	6da2                	ld	s11,8(sp)
    80003f32:	6165                	addi	sp,sp,112
    80003f34:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f36:	89da                	mv	s3,s6
    80003f38:	bff1                	j	80003f14 <readi+0xce>
    return 0;
    80003f3a:	4501                	li	a0,0
}
    80003f3c:	8082                	ret

0000000080003f3e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f3e:	457c                	lw	a5,76(a0)
    80003f40:	10d7e863          	bltu	a5,a3,80004050 <writei+0x112>
{
    80003f44:	7159                	addi	sp,sp,-112
    80003f46:	f486                	sd	ra,104(sp)
    80003f48:	f0a2                	sd	s0,96(sp)
    80003f4a:	eca6                	sd	s1,88(sp)
    80003f4c:	e8ca                	sd	s2,80(sp)
    80003f4e:	e4ce                	sd	s3,72(sp)
    80003f50:	e0d2                	sd	s4,64(sp)
    80003f52:	fc56                	sd	s5,56(sp)
    80003f54:	f85a                	sd	s6,48(sp)
    80003f56:	f45e                	sd	s7,40(sp)
    80003f58:	f062                	sd	s8,32(sp)
    80003f5a:	ec66                	sd	s9,24(sp)
    80003f5c:	e86a                	sd	s10,16(sp)
    80003f5e:	e46e                	sd	s11,8(sp)
    80003f60:	1880                	addi	s0,sp,112
    80003f62:	8b2a                	mv	s6,a0
    80003f64:	8c2e                	mv	s8,a1
    80003f66:	8ab2                	mv	s5,a2
    80003f68:	8936                	mv	s2,a3
    80003f6a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003f6c:	00e687bb          	addw	a5,a3,a4
    80003f70:	0ed7e263          	bltu	a5,a3,80004054 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f74:	00043737          	lui	a4,0x43
    80003f78:	0ef76063          	bltu	a4,a5,80004058 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f7c:	0c0b8863          	beqz	s7,8000404c <writei+0x10e>
    80003f80:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f82:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f86:	5cfd                	li	s9,-1
    80003f88:	a091                	j	80003fcc <writei+0x8e>
    80003f8a:	02099d93          	slli	s11,s3,0x20
    80003f8e:	020ddd93          	srli	s11,s11,0x20
    80003f92:	05848793          	addi	a5,s1,88
    80003f96:	86ee                	mv	a3,s11
    80003f98:	8656                	mv	a2,s5
    80003f9a:	85e2                	mv	a1,s8
    80003f9c:	953e                	add	a0,a0,a5
    80003f9e:	ffffe097          	auipc	ra,0xffffe
    80003fa2:	654080e7          	jalr	1620(ra) # 800025f2 <either_copyin>
    80003fa6:	07950263          	beq	a0,s9,8000400a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003faa:	8526                	mv	a0,s1
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	794080e7          	jalr	1940(ra) # 80004740 <log_write>
    brelse(bp);
    80003fb4:	8526                	mv	a0,s1
    80003fb6:	fffff097          	auipc	ra,0xfffff
    80003fba:	508080e7          	jalr	1288(ra) # 800034be <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fbe:	01498a3b          	addw	s4,s3,s4
    80003fc2:	0129893b          	addw	s2,s3,s2
    80003fc6:	9aee                	add	s5,s5,s11
    80003fc8:	057a7663          	bgeu	s4,s7,80004014 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fcc:	000b2483          	lw	s1,0(s6)
    80003fd0:	00a9559b          	srliw	a1,s2,0xa
    80003fd4:	855a                	mv	a0,s6
    80003fd6:	fffff097          	auipc	ra,0xfffff
    80003fda:	7ac080e7          	jalr	1964(ra) # 80003782 <bmap>
    80003fde:	0005059b          	sext.w	a1,a0
    80003fe2:	8526                	mv	a0,s1
    80003fe4:	fffff097          	auipc	ra,0xfffff
    80003fe8:	3aa080e7          	jalr	938(ra) # 8000338e <bread>
    80003fec:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fee:	3ff97513          	andi	a0,s2,1023
    80003ff2:	40ad07bb          	subw	a5,s10,a0
    80003ff6:	414b873b          	subw	a4,s7,s4
    80003ffa:	89be                	mv	s3,a5
    80003ffc:	2781                	sext.w	a5,a5
    80003ffe:	0007069b          	sext.w	a3,a4
    80004002:	f8f6f4e3          	bgeu	a3,a5,80003f8a <writei+0x4c>
    80004006:	89ba                	mv	s3,a4
    80004008:	b749                	j	80003f8a <writei+0x4c>
      brelse(bp);
    8000400a:	8526                	mv	a0,s1
    8000400c:	fffff097          	auipc	ra,0xfffff
    80004010:	4b2080e7          	jalr	1202(ra) # 800034be <brelse>
  }

  if(off > ip->size)
    80004014:	04cb2783          	lw	a5,76(s6)
    80004018:	0127f463          	bgeu	a5,s2,80004020 <writei+0xe2>
    ip->size = off;
    8000401c:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004020:	855a                	mv	a0,s6
    80004022:	00000097          	auipc	ra,0x0
    80004026:	aa6080e7          	jalr	-1370(ra) # 80003ac8 <iupdate>

  return tot;
    8000402a:	000a051b          	sext.w	a0,s4
}
    8000402e:	70a6                	ld	ra,104(sp)
    80004030:	7406                	ld	s0,96(sp)
    80004032:	64e6                	ld	s1,88(sp)
    80004034:	6946                	ld	s2,80(sp)
    80004036:	69a6                	ld	s3,72(sp)
    80004038:	6a06                	ld	s4,64(sp)
    8000403a:	7ae2                	ld	s5,56(sp)
    8000403c:	7b42                	ld	s6,48(sp)
    8000403e:	7ba2                	ld	s7,40(sp)
    80004040:	7c02                	ld	s8,32(sp)
    80004042:	6ce2                	ld	s9,24(sp)
    80004044:	6d42                	ld	s10,16(sp)
    80004046:	6da2                	ld	s11,8(sp)
    80004048:	6165                	addi	sp,sp,112
    8000404a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000404c:	8a5e                	mv	s4,s7
    8000404e:	bfc9                	j	80004020 <writei+0xe2>
    return -1;
    80004050:	557d                	li	a0,-1
}
    80004052:	8082                	ret
    return -1;
    80004054:	557d                	li	a0,-1
    80004056:	bfe1                	j	8000402e <writei+0xf0>
    return -1;
    80004058:	557d                	li	a0,-1
    8000405a:	bfd1                	j	8000402e <writei+0xf0>

000000008000405c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000405c:	1141                	addi	sp,sp,-16
    8000405e:	e406                	sd	ra,8(sp)
    80004060:	e022                	sd	s0,0(sp)
    80004062:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004064:	4639                	li	a2,14
    80004066:	ffffd097          	auipc	ra,0xffffd
    8000406a:	d30080e7          	jalr	-720(ra) # 80000d96 <strncmp>
}
    8000406e:	60a2                	ld	ra,8(sp)
    80004070:	6402                	ld	s0,0(sp)
    80004072:	0141                	addi	sp,sp,16
    80004074:	8082                	ret

0000000080004076 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004076:	7139                	addi	sp,sp,-64
    80004078:	fc06                	sd	ra,56(sp)
    8000407a:	f822                	sd	s0,48(sp)
    8000407c:	f426                	sd	s1,40(sp)
    8000407e:	f04a                	sd	s2,32(sp)
    80004080:	ec4e                	sd	s3,24(sp)
    80004082:	e852                	sd	s4,16(sp)
    80004084:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004086:	04451703          	lh	a4,68(a0)
    8000408a:	4785                	li	a5,1
    8000408c:	00f71a63          	bne	a4,a5,800040a0 <dirlookup+0x2a>
    80004090:	892a                	mv	s2,a0
    80004092:	89ae                	mv	s3,a1
    80004094:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004096:	457c                	lw	a5,76(a0)
    80004098:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000409a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000409c:	e79d                	bnez	a5,800040ca <dirlookup+0x54>
    8000409e:	a8a5                	j	80004116 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040a0:	00004517          	auipc	a0,0x4
    800040a4:	78050513          	addi	a0,a0,1920 # 80008820 <syscalls+0x1b8>
    800040a8:	ffffc097          	auipc	ra,0xffffc
    800040ac:	482080e7          	jalr	1154(ra) # 8000052a <panic>
      panic("dirlookup read");
    800040b0:	00004517          	auipc	a0,0x4
    800040b4:	78850513          	addi	a0,a0,1928 # 80008838 <syscalls+0x1d0>
    800040b8:	ffffc097          	auipc	ra,0xffffc
    800040bc:	472080e7          	jalr	1138(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040c0:	24c1                	addiw	s1,s1,16
    800040c2:	04c92783          	lw	a5,76(s2)
    800040c6:	04f4f763          	bgeu	s1,a5,80004114 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ca:	4741                	li	a4,16
    800040cc:	86a6                	mv	a3,s1
    800040ce:	fc040613          	addi	a2,s0,-64
    800040d2:	4581                	li	a1,0
    800040d4:	854a                	mv	a0,s2
    800040d6:	00000097          	auipc	ra,0x0
    800040da:	d70080e7          	jalr	-656(ra) # 80003e46 <readi>
    800040de:	47c1                	li	a5,16
    800040e0:	fcf518e3          	bne	a0,a5,800040b0 <dirlookup+0x3a>
    if(de.inum == 0)
    800040e4:	fc045783          	lhu	a5,-64(s0)
    800040e8:	dfe1                	beqz	a5,800040c0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040ea:	fc240593          	addi	a1,s0,-62
    800040ee:	854e                	mv	a0,s3
    800040f0:	00000097          	auipc	ra,0x0
    800040f4:	f6c080e7          	jalr	-148(ra) # 8000405c <namecmp>
    800040f8:	f561                	bnez	a0,800040c0 <dirlookup+0x4a>
      if(poff)
    800040fa:	000a0463          	beqz	s4,80004102 <dirlookup+0x8c>
        *poff = off;
    800040fe:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004102:	fc045583          	lhu	a1,-64(s0)
    80004106:	00092503          	lw	a0,0(s2)
    8000410a:	fffff097          	auipc	ra,0xfffff
    8000410e:	754080e7          	jalr	1876(ra) # 8000385e <iget>
    80004112:	a011                	j	80004116 <dirlookup+0xa0>
  return 0;
    80004114:	4501                	li	a0,0
}
    80004116:	70e2                	ld	ra,56(sp)
    80004118:	7442                	ld	s0,48(sp)
    8000411a:	74a2                	ld	s1,40(sp)
    8000411c:	7902                	ld	s2,32(sp)
    8000411e:	69e2                	ld	s3,24(sp)
    80004120:	6a42                	ld	s4,16(sp)
    80004122:	6121                	addi	sp,sp,64
    80004124:	8082                	ret

0000000080004126 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004126:	711d                	addi	sp,sp,-96
    80004128:	ec86                	sd	ra,88(sp)
    8000412a:	e8a2                	sd	s0,80(sp)
    8000412c:	e4a6                	sd	s1,72(sp)
    8000412e:	e0ca                	sd	s2,64(sp)
    80004130:	fc4e                	sd	s3,56(sp)
    80004132:	f852                	sd	s4,48(sp)
    80004134:	f456                	sd	s5,40(sp)
    80004136:	f05a                	sd	s6,32(sp)
    80004138:	ec5e                	sd	s7,24(sp)
    8000413a:	e862                	sd	s8,16(sp)
    8000413c:	e466                	sd	s9,8(sp)
    8000413e:	1080                	addi	s0,sp,96
    80004140:	84aa                	mv	s1,a0
    80004142:	8aae                	mv	s5,a1
    80004144:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004146:	00054703          	lbu	a4,0(a0)
    8000414a:	02f00793          	li	a5,47
    8000414e:	02f70363          	beq	a4,a5,80004174 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004152:	ffffe097          	auipc	ra,0xffffe
    80004156:	870080e7          	jalr	-1936(ra) # 800019c2 <myproc>
    8000415a:	17053503          	ld	a0,368(a0)
    8000415e:	00000097          	auipc	ra,0x0
    80004162:	9f6080e7          	jalr	-1546(ra) # 80003b54 <idup>
    80004166:	89aa                	mv	s3,a0
  while(*path == '/')
    80004168:	02f00913          	li	s2,47
  len = path - s;
    8000416c:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000416e:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004170:	4b85                	li	s7,1
    80004172:	a865                	j	8000422a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004174:	4585                	li	a1,1
    80004176:	4505                	li	a0,1
    80004178:	fffff097          	auipc	ra,0xfffff
    8000417c:	6e6080e7          	jalr	1766(ra) # 8000385e <iget>
    80004180:	89aa                	mv	s3,a0
    80004182:	b7dd                	j	80004168 <namex+0x42>
      iunlockput(ip);
    80004184:	854e                	mv	a0,s3
    80004186:	00000097          	auipc	ra,0x0
    8000418a:	c6e080e7          	jalr	-914(ra) # 80003df4 <iunlockput>
      return 0;
    8000418e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004190:	854e                	mv	a0,s3
    80004192:	60e6                	ld	ra,88(sp)
    80004194:	6446                	ld	s0,80(sp)
    80004196:	64a6                	ld	s1,72(sp)
    80004198:	6906                	ld	s2,64(sp)
    8000419a:	79e2                	ld	s3,56(sp)
    8000419c:	7a42                	ld	s4,48(sp)
    8000419e:	7aa2                	ld	s5,40(sp)
    800041a0:	7b02                	ld	s6,32(sp)
    800041a2:	6be2                	ld	s7,24(sp)
    800041a4:	6c42                	ld	s8,16(sp)
    800041a6:	6ca2                	ld	s9,8(sp)
    800041a8:	6125                	addi	sp,sp,96
    800041aa:	8082                	ret
      iunlock(ip);
    800041ac:	854e                	mv	a0,s3
    800041ae:	00000097          	auipc	ra,0x0
    800041b2:	aa6080e7          	jalr	-1370(ra) # 80003c54 <iunlock>
      return ip;
    800041b6:	bfe9                	j	80004190 <namex+0x6a>
      iunlockput(ip);
    800041b8:	854e                	mv	a0,s3
    800041ba:	00000097          	auipc	ra,0x0
    800041be:	c3a080e7          	jalr	-966(ra) # 80003df4 <iunlockput>
      return 0;
    800041c2:	89e6                	mv	s3,s9
    800041c4:	b7f1                	j	80004190 <namex+0x6a>
  len = path - s;
    800041c6:	40b48633          	sub	a2,s1,a1
    800041ca:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800041ce:	099c5463          	bge	s8,s9,80004256 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041d2:	4639                	li	a2,14
    800041d4:	8552                	mv	a0,s4
    800041d6:	ffffd097          	auipc	ra,0xffffd
    800041da:	b44080e7          	jalr	-1212(ra) # 80000d1a <memmove>
  while(*path == '/')
    800041de:	0004c783          	lbu	a5,0(s1)
    800041e2:	01279763          	bne	a5,s2,800041f0 <namex+0xca>
    path++;
    800041e6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041e8:	0004c783          	lbu	a5,0(s1)
    800041ec:	ff278de3          	beq	a5,s2,800041e6 <namex+0xc0>
    ilock(ip);
    800041f0:	854e                	mv	a0,s3
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	9a0080e7          	jalr	-1632(ra) # 80003b92 <ilock>
    if(ip->type != T_DIR){
    800041fa:	04499783          	lh	a5,68(s3)
    800041fe:	f97793e3          	bne	a5,s7,80004184 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004202:	000a8563          	beqz	s5,8000420c <namex+0xe6>
    80004206:	0004c783          	lbu	a5,0(s1)
    8000420a:	d3cd                	beqz	a5,800041ac <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000420c:	865a                	mv	a2,s6
    8000420e:	85d2                	mv	a1,s4
    80004210:	854e                	mv	a0,s3
    80004212:	00000097          	auipc	ra,0x0
    80004216:	e64080e7          	jalr	-412(ra) # 80004076 <dirlookup>
    8000421a:	8caa                	mv	s9,a0
    8000421c:	dd51                	beqz	a0,800041b8 <namex+0x92>
    iunlockput(ip);
    8000421e:	854e                	mv	a0,s3
    80004220:	00000097          	auipc	ra,0x0
    80004224:	bd4080e7          	jalr	-1068(ra) # 80003df4 <iunlockput>
    ip = next;
    80004228:	89e6                	mv	s3,s9
  while(*path == '/')
    8000422a:	0004c783          	lbu	a5,0(s1)
    8000422e:	05279763          	bne	a5,s2,8000427c <namex+0x156>
    path++;
    80004232:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004234:	0004c783          	lbu	a5,0(s1)
    80004238:	ff278de3          	beq	a5,s2,80004232 <namex+0x10c>
  if(*path == 0)
    8000423c:	c79d                	beqz	a5,8000426a <namex+0x144>
    path++;
    8000423e:	85a6                	mv	a1,s1
  len = path - s;
    80004240:	8cda                	mv	s9,s6
    80004242:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004244:	01278963          	beq	a5,s2,80004256 <namex+0x130>
    80004248:	dfbd                	beqz	a5,800041c6 <namex+0xa0>
    path++;
    8000424a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000424c:	0004c783          	lbu	a5,0(s1)
    80004250:	ff279ce3          	bne	a5,s2,80004248 <namex+0x122>
    80004254:	bf8d                	j	800041c6 <namex+0xa0>
    memmove(name, s, len);
    80004256:	2601                	sext.w	a2,a2
    80004258:	8552                	mv	a0,s4
    8000425a:	ffffd097          	auipc	ra,0xffffd
    8000425e:	ac0080e7          	jalr	-1344(ra) # 80000d1a <memmove>
    name[len] = 0;
    80004262:	9cd2                	add	s9,s9,s4
    80004264:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004268:	bf9d                	j	800041de <namex+0xb8>
  if(nameiparent){
    8000426a:	f20a83e3          	beqz	s5,80004190 <namex+0x6a>
    iput(ip);
    8000426e:	854e                	mv	a0,s3
    80004270:	00000097          	auipc	ra,0x0
    80004274:	adc080e7          	jalr	-1316(ra) # 80003d4c <iput>
    return 0;
    80004278:	4981                	li	s3,0
    8000427a:	bf19                	j	80004190 <namex+0x6a>
  if(*path == 0)
    8000427c:	d7fd                	beqz	a5,8000426a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000427e:	0004c783          	lbu	a5,0(s1)
    80004282:	85a6                	mv	a1,s1
    80004284:	b7d1                	j	80004248 <namex+0x122>

0000000080004286 <dirlink>:
{
    80004286:	7139                	addi	sp,sp,-64
    80004288:	fc06                	sd	ra,56(sp)
    8000428a:	f822                	sd	s0,48(sp)
    8000428c:	f426                	sd	s1,40(sp)
    8000428e:	f04a                	sd	s2,32(sp)
    80004290:	ec4e                	sd	s3,24(sp)
    80004292:	e852                	sd	s4,16(sp)
    80004294:	0080                	addi	s0,sp,64
    80004296:	892a                	mv	s2,a0
    80004298:	8a2e                	mv	s4,a1
    8000429a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000429c:	4601                	li	a2,0
    8000429e:	00000097          	auipc	ra,0x0
    800042a2:	dd8080e7          	jalr	-552(ra) # 80004076 <dirlookup>
    800042a6:	e93d                	bnez	a0,8000431c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042a8:	04c92483          	lw	s1,76(s2)
    800042ac:	c49d                	beqz	s1,800042da <dirlink+0x54>
    800042ae:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042b0:	4741                	li	a4,16
    800042b2:	86a6                	mv	a3,s1
    800042b4:	fc040613          	addi	a2,s0,-64
    800042b8:	4581                	li	a1,0
    800042ba:	854a                	mv	a0,s2
    800042bc:	00000097          	auipc	ra,0x0
    800042c0:	b8a080e7          	jalr	-1142(ra) # 80003e46 <readi>
    800042c4:	47c1                	li	a5,16
    800042c6:	06f51163          	bne	a0,a5,80004328 <dirlink+0xa2>
    if(de.inum == 0)
    800042ca:	fc045783          	lhu	a5,-64(s0)
    800042ce:	c791                	beqz	a5,800042da <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042d0:	24c1                	addiw	s1,s1,16
    800042d2:	04c92783          	lw	a5,76(s2)
    800042d6:	fcf4ede3          	bltu	s1,a5,800042b0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042da:	4639                	li	a2,14
    800042dc:	85d2                	mv	a1,s4
    800042de:	fc240513          	addi	a0,s0,-62
    800042e2:	ffffd097          	auipc	ra,0xffffd
    800042e6:	af0080e7          	jalr	-1296(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    800042ea:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042ee:	4741                	li	a4,16
    800042f0:	86a6                	mv	a3,s1
    800042f2:	fc040613          	addi	a2,s0,-64
    800042f6:	4581                	li	a1,0
    800042f8:	854a                	mv	a0,s2
    800042fa:	00000097          	auipc	ra,0x0
    800042fe:	c44080e7          	jalr	-956(ra) # 80003f3e <writei>
    80004302:	872a                	mv	a4,a0
    80004304:	47c1                	li	a5,16
  return 0;
    80004306:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004308:	02f71863          	bne	a4,a5,80004338 <dirlink+0xb2>
}
    8000430c:	70e2                	ld	ra,56(sp)
    8000430e:	7442                	ld	s0,48(sp)
    80004310:	74a2                	ld	s1,40(sp)
    80004312:	7902                	ld	s2,32(sp)
    80004314:	69e2                	ld	s3,24(sp)
    80004316:	6a42                	ld	s4,16(sp)
    80004318:	6121                	addi	sp,sp,64
    8000431a:	8082                	ret
    iput(ip);
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	a30080e7          	jalr	-1488(ra) # 80003d4c <iput>
    return -1;
    80004324:	557d                	li	a0,-1
    80004326:	b7dd                	j	8000430c <dirlink+0x86>
      panic("dirlink read");
    80004328:	00004517          	auipc	a0,0x4
    8000432c:	52050513          	addi	a0,a0,1312 # 80008848 <syscalls+0x1e0>
    80004330:	ffffc097          	auipc	ra,0xffffc
    80004334:	1fa080e7          	jalr	506(ra) # 8000052a <panic>
    panic("dirlink");
    80004338:	00004517          	auipc	a0,0x4
    8000433c:	61850513          	addi	a0,a0,1560 # 80008950 <syscalls+0x2e8>
    80004340:	ffffc097          	auipc	ra,0xffffc
    80004344:	1ea080e7          	jalr	490(ra) # 8000052a <panic>

0000000080004348 <namei>:

struct inode*
namei(char *path)
{
    80004348:	1101                	addi	sp,sp,-32
    8000434a:	ec06                	sd	ra,24(sp)
    8000434c:	e822                	sd	s0,16(sp)
    8000434e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004350:	fe040613          	addi	a2,s0,-32
    80004354:	4581                	li	a1,0
    80004356:	00000097          	auipc	ra,0x0
    8000435a:	dd0080e7          	jalr	-560(ra) # 80004126 <namex>
}
    8000435e:	60e2                	ld	ra,24(sp)
    80004360:	6442                	ld	s0,16(sp)
    80004362:	6105                	addi	sp,sp,32
    80004364:	8082                	ret

0000000080004366 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004366:	1141                	addi	sp,sp,-16
    80004368:	e406                	sd	ra,8(sp)
    8000436a:	e022                	sd	s0,0(sp)
    8000436c:	0800                	addi	s0,sp,16
    8000436e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004370:	4585                	li	a1,1
    80004372:	00000097          	auipc	ra,0x0
    80004376:	db4080e7          	jalr	-588(ra) # 80004126 <namex>
}
    8000437a:	60a2                	ld	ra,8(sp)
    8000437c:	6402                	ld	s0,0(sp)
    8000437e:	0141                	addi	sp,sp,16
    80004380:	8082                	ret

0000000080004382 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004382:	1101                	addi	sp,sp,-32
    80004384:	ec06                	sd	ra,24(sp)
    80004386:	e822                	sd	s0,16(sp)
    80004388:	e426                	sd	s1,8(sp)
    8000438a:	e04a                	sd	s2,0(sp)
    8000438c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000438e:	0001d917          	auipc	s2,0x1d
    80004392:	6fa90913          	addi	s2,s2,1786 # 80021a88 <log>
    80004396:	01892583          	lw	a1,24(s2)
    8000439a:	02892503          	lw	a0,40(s2)
    8000439e:	fffff097          	auipc	ra,0xfffff
    800043a2:	ff0080e7          	jalr	-16(ra) # 8000338e <bread>
    800043a6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043a8:	02c92683          	lw	a3,44(s2)
    800043ac:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043ae:	02d05863          	blez	a3,800043de <write_head+0x5c>
    800043b2:	0001d797          	auipc	a5,0x1d
    800043b6:	70678793          	addi	a5,a5,1798 # 80021ab8 <log+0x30>
    800043ba:	05c50713          	addi	a4,a0,92
    800043be:	36fd                	addiw	a3,a3,-1
    800043c0:	02069613          	slli	a2,a3,0x20
    800043c4:	01e65693          	srli	a3,a2,0x1e
    800043c8:	0001d617          	auipc	a2,0x1d
    800043cc:	6f460613          	addi	a2,a2,1780 # 80021abc <log+0x34>
    800043d0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043d2:	4390                	lw	a2,0(a5)
    800043d4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043d6:	0791                	addi	a5,a5,4
    800043d8:	0711                	addi	a4,a4,4
    800043da:	fed79ce3          	bne	a5,a3,800043d2 <write_head+0x50>
  }
  bwrite(buf);
    800043de:	8526                	mv	a0,s1
    800043e0:	fffff097          	auipc	ra,0xfffff
    800043e4:	0a0080e7          	jalr	160(ra) # 80003480 <bwrite>
  brelse(buf);
    800043e8:	8526                	mv	a0,s1
    800043ea:	fffff097          	auipc	ra,0xfffff
    800043ee:	0d4080e7          	jalr	212(ra) # 800034be <brelse>
}
    800043f2:	60e2                	ld	ra,24(sp)
    800043f4:	6442                	ld	s0,16(sp)
    800043f6:	64a2                	ld	s1,8(sp)
    800043f8:	6902                	ld	s2,0(sp)
    800043fa:	6105                	addi	sp,sp,32
    800043fc:	8082                	ret

00000000800043fe <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043fe:	0001d797          	auipc	a5,0x1d
    80004402:	6b67a783          	lw	a5,1718(a5) # 80021ab4 <log+0x2c>
    80004406:	0af05d63          	blez	a5,800044c0 <install_trans+0xc2>
{
    8000440a:	7139                	addi	sp,sp,-64
    8000440c:	fc06                	sd	ra,56(sp)
    8000440e:	f822                	sd	s0,48(sp)
    80004410:	f426                	sd	s1,40(sp)
    80004412:	f04a                	sd	s2,32(sp)
    80004414:	ec4e                	sd	s3,24(sp)
    80004416:	e852                	sd	s4,16(sp)
    80004418:	e456                	sd	s5,8(sp)
    8000441a:	e05a                	sd	s6,0(sp)
    8000441c:	0080                	addi	s0,sp,64
    8000441e:	8b2a                	mv	s6,a0
    80004420:	0001da97          	auipc	s5,0x1d
    80004424:	698a8a93          	addi	s5,s5,1688 # 80021ab8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004428:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000442a:	0001d997          	auipc	s3,0x1d
    8000442e:	65e98993          	addi	s3,s3,1630 # 80021a88 <log>
    80004432:	a00d                	j	80004454 <install_trans+0x56>
    brelse(lbuf);
    80004434:	854a                	mv	a0,s2
    80004436:	fffff097          	auipc	ra,0xfffff
    8000443a:	088080e7          	jalr	136(ra) # 800034be <brelse>
    brelse(dbuf);
    8000443e:	8526                	mv	a0,s1
    80004440:	fffff097          	auipc	ra,0xfffff
    80004444:	07e080e7          	jalr	126(ra) # 800034be <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004448:	2a05                	addiw	s4,s4,1
    8000444a:	0a91                	addi	s5,s5,4
    8000444c:	02c9a783          	lw	a5,44(s3)
    80004450:	04fa5e63          	bge	s4,a5,800044ac <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004454:	0189a583          	lw	a1,24(s3)
    80004458:	014585bb          	addw	a1,a1,s4
    8000445c:	2585                	addiw	a1,a1,1
    8000445e:	0289a503          	lw	a0,40(s3)
    80004462:	fffff097          	auipc	ra,0xfffff
    80004466:	f2c080e7          	jalr	-212(ra) # 8000338e <bread>
    8000446a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000446c:	000aa583          	lw	a1,0(s5)
    80004470:	0289a503          	lw	a0,40(s3)
    80004474:	fffff097          	auipc	ra,0xfffff
    80004478:	f1a080e7          	jalr	-230(ra) # 8000338e <bread>
    8000447c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000447e:	40000613          	li	a2,1024
    80004482:	05890593          	addi	a1,s2,88
    80004486:	05850513          	addi	a0,a0,88
    8000448a:	ffffd097          	auipc	ra,0xffffd
    8000448e:	890080e7          	jalr	-1904(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004492:	8526                	mv	a0,s1
    80004494:	fffff097          	auipc	ra,0xfffff
    80004498:	fec080e7          	jalr	-20(ra) # 80003480 <bwrite>
    if(recovering == 0)
    8000449c:	f80b1ce3          	bnez	s6,80004434 <install_trans+0x36>
      bunpin(dbuf);
    800044a0:	8526                	mv	a0,s1
    800044a2:	fffff097          	auipc	ra,0xfffff
    800044a6:	0f6080e7          	jalr	246(ra) # 80003598 <bunpin>
    800044aa:	b769                	j	80004434 <install_trans+0x36>
}
    800044ac:	70e2                	ld	ra,56(sp)
    800044ae:	7442                	ld	s0,48(sp)
    800044b0:	74a2                	ld	s1,40(sp)
    800044b2:	7902                	ld	s2,32(sp)
    800044b4:	69e2                	ld	s3,24(sp)
    800044b6:	6a42                	ld	s4,16(sp)
    800044b8:	6aa2                	ld	s5,8(sp)
    800044ba:	6b02                	ld	s6,0(sp)
    800044bc:	6121                	addi	sp,sp,64
    800044be:	8082                	ret
    800044c0:	8082                	ret

00000000800044c2 <initlog>:
{
    800044c2:	7179                	addi	sp,sp,-48
    800044c4:	f406                	sd	ra,40(sp)
    800044c6:	f022                	sd	s0,32(sp)
    800044c8:	ec26                	sd	s1,24(sp)
    800044ca:	e84a                	sd	s2,16(sp)
    800044cc:	e44e                	sd	s3,8(sp)
    800044ce:	1800                	addi	s0,sp,48
    800044d0:	892a                	mv	s2,a0
    800044d2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044d4:	0001d497          	auipc	s1,0x1d
    800044d8:	5b448493          	addi	s1,s1,1460 # 80021a88 <log>
    800044dc:	00004597          	auipc	a1,0x4
    800044e0:	37c58593          	addi	a1,a1,892 # 80008858 <syscalls+0x1f0>
    800044e4:	8526                	mv	a0,s1
    800044e6:	ffffc097          	auipc	ra,0xffffc
    800044ea:	64c080e7          	jalr	1612(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    800044ee:	0149a583          	lw	a1,20(s3)
    800044f2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044f4:	0109a783          	lw	a5,16(s3)
    800044f8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044fa:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044fe:	854a                	mv	a0,s2
    80004500:	fffff097          	auipc	ra,0xfffff
    80004504:	e8e080e7          	jalr	-370(ra) # 8000338e <bread>
  log.lh.n = lh->n;
    80004508:	4d34                	lw	a3,88(a0)
    8000450a:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000450c:	02d05663          	blez	a3,80004538 <initlog+0x76>
    80004510:	05c50793          	addi	a5,a0,92
    80004514:	0001d717          	auipc	a4,0x1d
    80004518:	5a470713          	addi	a4,a4,1444 # 80021ab8 <log+0x30>
    8000451c:	36fd                	addiw	a3,a3,-1
    8000451e:	02069613          	slli	a2,a3,0x20
    80004522:	01e65693          	srli	a3,a2,0x1e
    80004526:	06050613          	addi	a2,a0,96
    8000452a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000452c:	4390                	lw	a2,0(a5)
    8000452e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004530:	0791                	addi	a5,a5,4
    80004532:	0711                	addi	a4,a4,4
    80004534:	fed79ce3          	bne	a5,a3,8000452c <initlog+0x6a>
  brelse(buf);
    80004538:	fffff097          	auipc	ra,0xfffff
    8000453c:	f86080e7          	jalr	-122(ra) # 800034be <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004540:	4505                	li	a0,1
    80004542:	00000097          	auipc	ra,0x0
    80004546:	ebc080e7          	jalr	-324(ra) # 800043fe <install_trans>
  log.lh.n = 0;
    8000454a:	0001d797          	auipc	a5,0x1d
    8000454e:	5607a523          	sw	zero,1386(a5) # 80021ab4 <log+0x2c>
  write_head(); // clear the log
    80004552:	00000097          	auipc	ra,0x0
    80004556:	e30080e7          	jalr	-464(ra) # 80004382 <write_head>
}
    8000455a:	70a2                	ld	ra,40(sp)
    8000455c:	7402                	ld	s0,32(sp)
    8000455e:	64e2                	ld	s1,24(sp)
    80004560:	6942                	ld	s2,16(sp)
    80004562:	69a2                	ld	s3,8(sp)
    80004564:	6145                	addi	sp,sp,48
    80004566:	8082                	ret

0000000080004568 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004568:	1101                	addi	sp,sp,-32
    8000456a:	ec06                	sd	ra,24(sp)
    8000456c:	e822                	sd	s0,16(sp)
    8000456e:	e426                	sd	s1,8(sp)
    80004570:	e04a                	sd	s2,0(sp)
    80004572:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004574:	0001d517          	auipc	a0,0x1d
    80004578:	51450513          	addi	a0,a0,1300 # 80021a88 <log>
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	646080e7          	jalr	1606(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    80004584:	0001d497          	auipc	s1,0x1d
    80004588:	50448493          	addi	s1,s1,1284 # 80021a88 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000458c:	4979                	li	s2,30
    8000458e:	a039                	j	8000459c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004590:	85a6                	mv	a1,s1
    80004592:	8526                	mv	a0,s1
    80004594:	ffffe097          	auipc	ra,0xffffe
    80004598:	c5a080e7          	jalr	-934(ra) # 800021ee <sleep>
    if(log.committing){
    8000459c:	50dc                	lw	a5,36(s1)
    8000459e:	fbed                	bnez	a5,80004590 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045a0:	509c                	lw	a5,32(s1)
    800045a2:	0017871b          	addiw	a4,a5,1
    800045a6:	0007069b          	sext.w	a3,a4
    800045aa:	0027179b          	slliw	a5,a4,0x2
    800045ae:	9fb9                	addw	a5,a5,a4
    800045b0:	0017979b          	slliw	a5,a5,0x1
    800045b4:	54d8                	lw	a4,44(s1)
    800045b6:	9fb9                	addw	a5,a5,a4
    800045b8:	00f95963          	bge	s2,a5,800045ca <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045bc:	85a6                	mv	a1,s1
    800045be:	8526                	mv	a0,s1
    800045c0:	ffffe097          	auipc	ra,0xffffe
    800045c4:	c2e080e7          	jalr	-978(ra) # 800021ee <sleep>
    800045c8:	bfd1                	j	8000459c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045ca:	0001d517          	auipc	a0,0x1d
    800045ce:	4be50513          	addi	a0,a0,1214 # 80021a88 <log>
    800045d2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800045d4:	ffffc097          	auipc	ra,0xffffc
    800045d8:	6a2080e7          	jalr	1698(ra) # 80000c76 <release>
      break;
    }
  }
}
    800045dc:	60e2                	ld	ra,24(sp)
    800045de:	6442                	ld	s0,16(sp)
    800045e0:	64a2                	ld	s1,8(sp)
    800045e2:	6902                	ld	s2,0(sp)
    800045e4:	6105                	addi	sp,sp,32
    800045e6:	8082                	ret

00000000800045e8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045e8:	7139                	addi	sp,sp,-64
    800045ea:	fc06                	sd	ra,56(sp)
    800045ec:	f822                	sd	s0,48(sp)
    800045ee:	f426                	sd	s1,40(sp)
    800045f0:	f04a                	sd	s2,32(sp)
    800045f2:	ec4e                	sd	s3,24(sp)
    800045f4:	e852                	sd	s4,16(sp)
    800045f6:	e456                	sd	s5,8(sp)
    800045f8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045fa:	0001d497          	auipc	s1,0x1d
    800045fe:	48e48493          	addi	s1,s1,1166 # 80021a88 <log>
    80004602:	8526                	mv	a0,s1
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	5be080e7          	jalr	1470(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    8000460c:	509c                	lw	a5,32(s1)
    8000460e:	37fd                	addiw	a5,a5,-1
    80004610:	0007891b          	sext.w	s2,a5
    80004614:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004616:	50dc                	lw	a5,36(s1)
    80004618:	e7b9                	bnez	a5,80004666 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000461a:	04091e63          	bnez	s2,80004676 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000461e:	0001d497          	auipc	s1,0x1d
    80004622:	46a48493          	addi	s1,s1,1130 # 80021a88 <log>
    80004626:	4785                	li	a5,1
    80004628:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000462a:	8526                	mv	a0,s1
    8000462c:	ffffc097          	auipc	ra,0xffffc
    80004630:	64a080e7          	jalr	1610(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004634:	54dc                	lw	a5,44(s1)
    80004636:	06f04763          	bgtz	a5,800046a4 <end_op+0xbc>
    acquire(&log.lock);
    8000463a:	0001d497          	auipc	s1,0x1d
    8000463e:	44e48493          	addi	s1,s1,1102 # 80021a88 <log>
    80004642:	8526                	mv	a0,s1
    80004644:	ffffc097          	auipc	ra,0xffffc
    80004648:	57e080e7          	jalr	1406(ra) # 80000bc2 <acquire>
    log.committing = 0;
    8000464c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004650:	8526                	mv	a0,s1
    80004652:	ffffe097          	auipc	ra,0xffffe
    80004656:	d28080e7          	jalr	-728(ra) # 8000237a <wakeup>
    release(&log.lock);
    8000465a:	8526                	mv	a0,s1
    8000465c:	ffffc097          	auipc	ra,0xffffc
    80004660:	61a080e7          	jalr	1562(ra) # 80000c76 <release>
}
    80004664:	a03d                	j	80004692 <end_op+0xaa>
    panic("log.committing");
    80004666:	00004517          	auipc	a0,0x4
    8000466a:	1fa50513          	addi	a0,a0,506 # 80008860 <syscalls+0x1f8>
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	ebc080e7          	jalr	-324(ra) # 8000052a <panic>
    wakeup(&log);
    80004676:	0001d497          	auipc	s1,0x1d
    8000467a:	41248493          	addi	s1,s1,1042 # 80021a88 <log>
    8000467e:	8526                	mv	a0,s1
    80004680:	ffffe097          	auipc	ra,0xffffe
    80004684:	cfa080e7          	jalr	-774(ra) # 8000237a <wakeup>
  release(&log.lock);
    80004688:	8526                	mv	a0,s1
    8000468a:	ffffc097          	auipc	ra,0xffffc
    8000468e:	5ec080e7          	jalr	1516(ra) # 80000c76 <release>
}
    80004692:	70e2                	ld	ra,56(sp)
    80004694:	7442                	ld	s0,48(sp)
    80004696:	74a2                	ld	s1,40(sp)
    80004698:	7902                	ld	s2,32(sp)
    8000469a:	69e2                	ld	s3,24(sp)
    8000469c:	6a42                	ld	s4,16(sp)
    8000469e:	6aa2                	ld	s5,8(sp)
    800046a0:	6121                	addi	sp,sp,64
    800046a2:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800046a4:	0001da97          	auipc	s5,0x1d
    800046a8:	414a8a93          	addi	s5,s5,1044 # 80021ab8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046ac:	0001da17          	auipc	s4,0x1d
    800046b0:	3dca0a13          	addi	s4,s4,988 # 80021a88 <log>
    800046b4:	018a2583          	lw	a1,24(s4)
    800046b8:	012585bb          	addw	a1,a1,s2
    800046bc:	2585                	addiw	a1,a1,1
    800046be:	028a2503          	lw	a0,40(s4)
    800046c2:	fffff097          	auipc	ra,0xfffff
    800046c6:	ccc080e7          	jalr	-820(ra) # 8000338e <bread>
    800046ca:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046cc:	000aa583          	lw	a1,0(s5)
    800046d0:	028a2503          	lw	a0,40(s4)
    800046d4:	fffff097          	auipc	ra,0xfffff
    800046d8:	cba080e7          	jalr	-838(ra) # 8000338e <bread>
    800046dc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046de:	40000613          	li	a2,1024
    800046e2:	05850593          	addi	a1,a0,88
    800046e6:	05848513          	addi	a0,s1,88
    800046ea:	ffffc097          	auipc	ra,0xffffc
    800046ee:	630080e7          	jalr	1584(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    800046f2:	8526                	mv	a0,s1
    800046f4:	fffff097          	auipc	ra,0xfffff
    800046f8:	d8c080e7          	jalr	-628(ra) # 80003480 <bwrite>
    brelse(from);
    800046fc:	854e                	mv	a0,s3
    800046fe:	fffff097          	auipc	ra,0xfffff
    80004702:	dc0080e7          	jalr	-576(ra) # 800034be <brelse>
    brelse(to);
    80004706:	8526                	mv	a0,s1
    80004708:	fffff097          	auipc	ra,0xfffff
    8000470c:	db6080e7          	jalr	-586(ra) # 800034be <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004710:	2905                	addiw	s2,s2,1
    80004712:	0a91                	addi	s5,s5,4
    80004714:	02ca2783          	lw	a5,44(s4)
    80004718:	f8f94ee3          	blt	s2,a5,800046b4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000471c:	00000097          	auipc	ra,0x0
    80004720:	c66080e7          	jalr	-922(ra) # 80004382 <write_head>
    install_trans(0); // Now install writes to home locations
    80004724:	4501                	li	a0,0
    80004726:	00000097          	auipc	ra,0x0
    8000472a:	cd8080e7          	jalr	-808(ra) # 800043fe <install_trans>
    log.lh.n = 0;
    8000472e:	0001d797          	auipc	a5,0x1d
    80004732:	3807a323          	sw	zero,902(a5) # 80021ab4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004736:	00000097          	auipc	ra,0x0
    8000473a:	c4c080e7          	jalr	-948(ra) # 80004382 <write_head>
    8000473e:	bdf5                	j	8000463a <end_op+0x52>

0000000080004740 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004740:	1101                	addi	sp,sp,-32
    80004742:	ec06                	sd	ra,24(sp)
    80004744:	e822                	sd	s0,16(sp)
    80004746:	e426                	sd	s1,8(sp)
    80004748:	e04a                	sd	s2,0(sp)
    8000474a:	1000                	addi	s0,sp,32
    8000474c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000474e:	0001d917          	auipc	s2,0x1d
    80004752:	33a90913          	addi	s2,s2,826 # 80021a88 <log>
    80004756:	854a                	mv	a0,s2
    80004758:	ffffc097          	auipc	ra,0xffffc
    8000475c:	46a080e7          	jalr	1130(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004760:	02c92603          	lw	a2,44(s2)
    80004764:	47f5                	li	a5,29
    80004766:	06c7c563          	blt	a5,a2,800047d0 <log_write+0x90>
    8000476a:	0001d797          	auipc	a5,0x1d
    8000476e:	33a7a783          	lw	a5,826(a5) # 80021aa4 <log+0x1c>
    80004772:	37fd                	addiw	a5,a5,-1
    80004774:	04f65e63          	bge	a2,a5,800047d0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004778:	0001d797          	auipc	a5,0x1d
    8000477c:	3307a783          	lw	a5,816(a5) # 80021aa8 <log+0x20>
    80004780:	06f05063          	blez	a5,800047e0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004784:	4781                	li	a5,0
    80004786:	06c05563          	blez	a2,800047f0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000478a:	44cc                	lw	a1,12(s1)
    8000478c:	0001d717          	auipc	a4,0x1d
    80004790:	32c70713          	addi	a4,a4,812 # 80021ab8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004794:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004796:	4314                	lw	a3,0(a4)
    80004798:	04b68c63          	beq	a3,a1,800047f0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000479c:	2785                	addiw	a5,a5,1
    8000479e:	0711                	addi	a4,a4,4
    800047a0:	fef61be3          	bne	a2,a5,80004796 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047a4:	0621                	addi	a2,a2,8
    800047a6:	060a                	slli	a2,a2,0x2
    800047a8:	0001d797          	auipc	a5,0x1d
    800047ac:	2e078793          	addi	a5,a5,736 # 80021a88 <log>
    800047b0:	963e                	add	a2,a2,a5
    800047b2:	44dc                	lw	a5,12(s1)
    800047b4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047b6:	8526                	mv	a0,s1
    800047b8:	fffff097          	auipc	ra,0xfffff
    800047bc:	da4080e7          	jalr	-604(ra) # 8000355c <bpin>
    log.lh.n++;
    800047c0:	0001d717          	auipc	a4,0x1d
    800047c4:	2c870713          	addi	a4,a4,712 # 80021a88 <log>
    800047c8:	575c                	lw	a5,44(a4)
    800047ca:	2785                	addiw	a5,a5,1
    800047cc:	d75c                	sw	a5,44(a4)
    800047ce:	a835                	j	8000480a <log_write+0xca>
    panic("too big a transaction");
    800047d0:	00004517          	auipc	a0,0x4
    800047d4:	0a050513          	addi	a0,a0,160 # 80008870 <syscalls+0x208>
    800047d8:	ffffc097          	auipc	ra,0xffffc
    800047dc:	d52080e7          	jalr	-686(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    800047e0:	00004517          	auipc	a0,0x4
    800047e4:	0a850513          	addi	a0,a0,168 # 80008888 <syscalls+0x220>
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	d42080e7          	jalr	-702(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    800047f0:	00878713          	addi	a4,a5,8
    800047f4:	00271693          	slli	a3,a4,0x2
    800047f8:	0001d717          	auipc	a4,0x1d
    800047fc:	29070713          	addi	a4,a4,656 # 80021a88 <log>
    80004800:	9736                	add	a4,a4,a3
    80004802:	44d4                	lw	a3,12(s1)
    80004804:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004806:	faf608e3          	beq	a2,a5,800047b6 <log_write+0x76>
  }
  release(&log.lock);
    8000480a:	0001d517          	auipc	a0,0x1d
    8000480e:	27e50513          	addi	a0,a0,638 # 80021a88 <log>
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	464080e7          	jalr	1124(ra) # 80000c76 <release>
}
    8000481a:	60e2                	ld	ra,24(sp)
    8000481c:	6442                	ld	s0,16(sp)
    8000481e:	64a2                	ld	s1,8(sp)
    80004820:	6902                	ld	s2,0(sp)
    80004822:	6105                	addi	sp,sp,32
    80004824:	8082                	ret

0000000080004826 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004826:	1101                	addi	sp,sp,-32
    80004828:	ec06                	sd	ra,24(sp)
    8000482a:	e822                	sd	s0,16(sp)
    8000482c:	e426                	sd	s1,8(sp)
    8000482e:	e04a                	sd	s2,0(sp)
    80004830:	1000                	addi	s0,sp,32
    80004832:	84aa                	mv	s1,a0
    80004834:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004836:	00004597          	auipc	a1,0x4
    8000483a:	07258593          	addi	a1,a1,114 # 800088a8 <syscalls+0x240>
    8000483e:	0521                	addi	a0,a0,8
    80004840:	ffffc097          	auipc	ra,0xffffc
    80004844:	2f2080e7          	jalr	754(ra) # 80000b32 <initlock>
  lk->name = name;
    80004848:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000484c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004850:	0204a423          	sw	zero,40(s1)
}
    80004854:	60e2                	ld	ra,24(sp)
    80004856:	6442                	ld	s0,16(sp)
    80004858:	64a2                	ld	s1,8(sp)
    8000485a:	6902                	ld	s2,0(sp)
    8000485c:	6105                	addi	sp,sp,32
    8000485e:	8082                	ret

0000000080004860 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004860:	1101                	addi	sp,sp,-32
    80004862:	ec06                	sd	ra,24(sp)
    80004864:	e822                	sd	s0,16(sp)
    80004866:	e426                	sd	s1,8(sp)
    80004868:	e04a                	sd	s2,0(sp)
    8000486a:	1000                	addi	s0,sp,32
    8000486c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000486e:	00850913          	addi	s2,a0,8
    80004872:	854a                	mv	a0,s2
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	34e080e7          	jalr	846(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    8000487c:	409c                	lw	a5,0(s1)
    8000487e:	cb89                	beqz	a5,80004890 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004880:	85ca                	mv	a1,s2
    80004882:	8526                	mv	a0,s1
    80004884:	ffffe097          	auipc	ra,0xffffe
    80004888:	96a080e7          	jalr	-1686(ra) # 800021ee <sleep>
  while (lk->locked) {
    8000488c:	409c                	lw	a5,0(s1)
    8000488e:	fbed                	bnez	a5,80004880 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004890:	4785                	li	a5,1
    80004892:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004894:	ffffd097          	auipc	ra,0xffffd
    80004898:	12e080e7          	jalr	302(ra) # 800019c2 <myproc>
    8000489c:	591c                	lw	a5,48(a0)
    8000489e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800048a0:	854a                	mv	a0,s2
    800048a2:	ffffc097          	auipc	ra,0xffffc
    800048a6:	3d4080e7          	jalr	980(ra) # 80000c76 <release>
}
    800048aa:	60e2                	ld	ra,24(sp)
    800048ac:	6442                	ld	s0,16(sp)
    800048ae:	64a2                	ld	s1,8(sp)
    800048b0:	6902                	ld	s2,0(sp)
    800048b2:	6105                	addi	sp,sp,32
    800048b4:	8082                	ret

00000000800048b6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048b6:	1101                	addi	sp,sp,-32
    800048b8:	ec06                	sd	ra,24(sp)
    800048ba:	e822                	sd	s0,16(sp)
    800048bc:	e426                	sd	s1,8(sp)
    800048be:	e04a                	sd	s2,0(sp)
    800048c0:	1000                	addi	s0,sp,32
    800048c2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048c4:	00850913          	addi	s2,a0,8
    800048c8:	854a                	mv	a0,s2
    800048ca:	ffffc097          	auipc	ra,0xffffc
    800048ce:	2f8080e7          	jalr	760(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    800048d2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048d6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048da:	8526                	mv	a0,s1
    800048dc:	ffffe097          	auipc	ra,0xffffe
    800048e0:	a9e080e7          	jalr	-1378(ra) # 8000237a <wakeup>
  release(&lk->lk);
    800048e4:	854a                	mv	a0,s2
    800048e6:	ffffc097          	auipc	ra,0xffffc
    800048ea:	390080e7          	jalr	912(ra) # 80000c76 <release>
}
    800048ee:	60e2                	ld	ra,24(sp)
    800048f0:	6442                	ld	s0,16(sp)
    800048f2:	64a2                	ld	s1,8(sp)
    800048f4:	6902                	ld	s2,0(sp)
    800048f6:	6105                	addi	sp,sp,32
    800048f8:	8082                	ret

00000000800048fa <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048fa:	7179                	addi	sp,sp,-48
    800048fc:	f406                	sd	ra,40(sp)
    800048fe:	f022                	sd	s0,32(sp)
    80004900:	ec26                	sd	s1,24(sp)
    80004902:	e84a                	sd	s2,16(sp)
    80004904:	e44e                	sd	s3,8(sp)
    80004906:	1800                	addi	s0,sp,48
    80004908:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000490a:	00850913          	addi	s2,a0,8
    8000490e:	854a                	mv	a0,s2
    80004910:	ffffc097          	auipc	ra,0xffffc
    80004914:	2b2080e7          	jalr	690(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004918:	409c                	lw	a5,0(s1)
    8000491a:	ef99                	bnez	a5,80004938 <holdingsleep+0x3e>
    8000491c:	4481                	li	s1,0
  release(&lk->lk);
    8000491e:	854a                	mv	a0,s2
    80004920:	ffffc097          	auipc	ra,0xffffc
    80004924:	356080e7          	jalr	854(ra) # 80000c76 <release>
  return r;
}
    80004928:	8526                	mv	a0,s1
    8000492a:	70a2                	ld	ra,40(sp)
    8000492c:	7402                	ld	s0,32(sp)
    8000492e:	64e2                	ld	s1,24(sp)
    80004930:	6942                	ld	s2,16(sp)
    80004932:	69a2                	ld	s3,8(sp)
    80004934:	6145                	addi	sp,sp,48
    80004936:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004938:	0284a983          	lw	s3,40(s1)
    8000493c:	ffffd097          	auipc	ra,0xffffd
    80004940:	086080e7          	jalr	134(ra) # 800019c2 <myproc>
    80004944:	5904                	lw	s1,48(a0)
    80004946:	413484b3          	sub	s1,s1,s3
    8000494a:	0014b493          	seqz	s1,s1
    8000494e:	bfc1                	j	8000491e <holdingsleep+0x24>

0000000080004950 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004950:	1141                	addi	sp,sp,-16
    80004952:	e406                	sd	ra,8(sp)
    80004954:	e022                	sd	s0,0(sp)
    80004956:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004958:	00004597          	auipc	a1,0x4
    8000495c:	f6058593          	addi	a1,a1,-160 # 800088b8 <syscalls+0x250>
    80004960:	0001d517          	auipc	a0,0x1d
    80004964:	27050513          	addi	a0,a0,624 # 80021bd0 <ftable>
    80004968:	ffffc097          	auipc	ra,0xffffc
    8000496c:	1ca080e7          	jalr	458(ra) # 80000b32 <initlock>
}
    80004970:	60a2                	ld	ra,8(sp)
    80004972:	6402                	ld	s0,0(sp)
    80004974:	0141                	addi	sp,sp,16
    80004976:	8082                	ret

0000000080004978 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004978:	1101                	addi	sp,sp,-32
    8000497a:	ec06                	sd	ra,24(sp)
    8000497c:	e822                	sd	s0,16(sp)
    8000497e:	e426                	sd	s1,8(sp)
    80004980:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004982:	0001d517          	auipc	a0,0x1d
    80004986:	24e50513          	addi	a0,a0,590 # 80021bd0 <ftable>
    8000498a:	ffffc097          	auipc	ra,0xffffc
    8000498e:	238080e7          	jalr	568(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004992:	0001d497          	auipc	s1,0x1d
    80004996:	25648493          	addi	s1,s1,598 # 80021be8 <ftable+0x18>
    8000499a:	0001e717          	auipc	a4,0x1e
    8000499e:	1ee70713          	addi	a4,a4,494 # 80022b88 <ftable+0xfb8>
    if(f->ref == 0){
    800049a2:	40dc                	lw	a5,4(s1)
    800049a4:	cf99                	beqz	a5,800049c2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049a6:	02848493          	addi	s1,s1,40
    800049aa:	fee49ce3          	bne	s1,a4,800049a2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049ae:	0001d517          	auipc	a0,0x1d
    800049b2:	22250513          	addi	a0,a0,546 # 80021bd0 <ftable>
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	2c0080e7          	jalr	704(ra) # 80000c76 <release>
  return 0;
    800049be:	4481                	li	s1,0
    800049c0:	a819                	j	800049d6 <filealloc+0x5e>
      f->ref = 1;
    800049c2:	4785                	li	a5,1
    800049c4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049c6:	0001d517          	auipc	a0,0x1d
    800049ca:	20a50513          	addi	a0,a0,522 # 80021bd0 <ftable>
    800049ce:	ffffc097          	auipc	ra,0xffffc
    800049d2:	2a8080e7          	jalr	680(ra) # 80000c76 <release>
}
    800049d6:	8526                	mv	a0,s1
    800049d8:	60e2                	ld	ra,24(sp)
    800049da:	6442                	ld	s0,16(sp)
    800049dc:	64a2                	ld	s1,8(sp)
    800049de:	6105                	addi	sp,sp,32
    800049e0:	8082                	ret

00000000800049e2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049e2:	1101                	addi	sp,sp,-32
    800049e4:	ec06                	sd	ra,24(sp)
    800049e6:	e822                	sd	s0,16(sp)
    800049e8:	e426                	sd	s1,8(sp)
    800049ea:	1000                	addi	s0,sp,32
    800049ec:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049ee:	0001d517          	auipc	a0,0x1d
    800049f2:	1e250513          	addi	a0,a0,482 # 80021bd0 <ftable>
    800049f6:	ffffc097          	auipc	ra,0xffffc
    800049fa:	1cc080e7          	jalr	460(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800049fe:	40dc                	lw	a5,4(s1)
    80004a00:	02f05263          	blez	a5,80004a24 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a04:	2785                	addiw	a5,a5,1
    80004a06:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a08:	0001d517          	auipc	a0,0x1d
    80004a0c:	1c850513          	addi	a0,a0,456 # 80021bd0 <ftable>
    80004a10:	ffffc097          	auipc	ra,0xffffc
    80004a14:	266080e7          	jalr	614(ra) # 80000c76 <release>
  return f;
}
    80004a18:	8526                	mv	a0,s1
    80004a1a:	60e2                	ld	ra,24(sp)
    80004a1c:	6442                	ld	s0,16(sp)
    80004a1e:	64a2                	ld	s1,8(sp)
    80004a20:	6105                	addi	sp,sp,32
    80004a22:	8082                	ret
    panic("filedup");
    80004a24:	00004517          	auipc	a0,0x4
    80004a28:	e9c50513          	addi	a0,a0,-356 # 800088c0 <syscalls+0x258>
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	afe080e7          	jalr	-1282(ra) # 8000052a <panic>

0000000080004a34 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a34:	7139                	addi	sp,sp,-64
    80004a36:	fc06                	sd	ra,56(sp)
    80004a38:	f822                	sd	s0,48(sp)
    80004a3a:	f426                	sd	s1,40(sp)
    80004a3c:	f04a                	sd	s2,32(sp)
    80004a3e:	ec4e                	sd	s3,24(sp)
    80004a40:	e852                	sd	s4,16(sp)
    80004a42:	e456                	sd	s5,8(sp)
    80004a44:	0080                	addi	s0,sp,64
    80004a46:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a48:	0001d517          	auipc	a0,0x1d
    80004a4c:	18850513          	addi	a0,a0,392 # 80021bd0 <ftable>
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	172080e7          	jalr	370(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004a58:	40dc                	lw	a5,4(s1)
    80004a5a:	06f05163          	blez	a5,80004abc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a5e:	37fd                	addiw	a5,a5,-1
    80004a60:	0007871b          	sext.w	a4,a5
    80004a64:	c0dc                	sw	a5,4(s1)
    80004a66:	06e04363          	bgtz	a4,80004acc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a6a:	0004a903          	lw	s2,0(s1)
    80004a6e:	0094ca83          	lbu	s5,9(s1)
    80004a72:	0104ba03          	ld	s4,16(s1)
    80004a76:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a7a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a7e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a82:	0001d517          	auipc	a0,0x1d
    80004a86:	14e50513          	addi	a0,a0,334 # 80021bd0 <ftable>
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	1ec080e7          	jalr	492(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004a92:	4785                	li	a5,1
    80004a94:	04f90d63          	beq	s2,a5,80004aee <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a98:	3979                	addiw	s2,s2,-2
    80004a9a:	4785                	li	a5,1
    80004a9c:	0527e063          	bltu	a5,s2,80004adc <fileclose+0xa8>
    begin_op();
    80004aa0:	00000097          	auipc	ra,0x0
    80004aa4:	ac8080e7          	jalr	-1336(ra) # 80004568 <begin_op>
    iput(ff.ip);
    80004aa8:	854e                	mv	a0,s3
    80004aaa:	fffff097          	auipc	ra,0xfffff
    80004aae:	2a2080e7          	jalr	674(ra) # 80003d4c <iput>
    end_op();
    80004ab2:	00000097          	auipc	ra,0x0
    80004ab6:	b36080e7          	jalr	-1226(ra) # 800045e8 <end_op>
    80004aba:	a00d                	j	80004adc <fileclose+0xa8>
    panic("fileclose");
    80004abc:	00004517          	auipc	a0,0x4
    80004ac0:	e0c50513          	addi	a0,a0,-500 # 800088c8 <syscalls+0x260>
    80004ac4:	ffffc097          	auipc	ra,0xffffc
    80004ac8:	a66080e7          	jalr	-1434(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004acc:	0001d517          	auipc	a0,0x1d
    80004ad0:	10450513          	addi	a0,a0,260 # 80021bd0 <ftable>
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	1a2080e7          	jalr	418(ra) # 80000c76 <release>
  }
}
    80004adc:	70e2                	ld	ra,56(sp)
    80004ade:	7442                	ld	s0,48(sp)
    80004ae0:	74a2                	ld	s1,40(sp)
    80004ae2:	7902                	ld	s2,32(sp)
    80004ae4:	69e2                	ld	s3,24(sp)
    80004ae6:	6a42                	ld	s4,16(sp)
    80004ae8:	6aa2                	ld	s5,8(sp)
    80004aea:	6121                	addi	sp,sp,64
    80004aec:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004aee:	85d6                	mv	a1,s5
    80004af0:	8552                	mv	a0,s4
    80004af2:	00000097          	auipc	ra,0x0
    80004af6:	34c080e7          	jalr	844(ra) # 80004e3e <pipeclose>
    80004afa:	b7cd                	j	80004adc <fileclose+0xa8>

0000000080004afc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004afc:	715d                	addi	sp,sp,-80
    80004afe:	e486                	sd	ra,72(sp)
    80004b00:	e0a2                	sd	s0,64(sp)
    80004b02:	fc26                	sd	s1,56(sp)
    80004b04:	f84a                	sd	s2,48(sp)
    80004b06:	f44e                	sd	s3,40(sp)
    80004b08:	0880                	addi	s0,sp,80
    80004b0a:	84aa                	mv	s1,a0
    80004b0c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b0e:	ffffd097          	auipc	ra,0xffffd
    80004b12:	eb4080e7          	jalr	-332(ra) # 800019c2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b16:	409c                	lw	a5,0(s1)
    80004b18:	37f9                	addiw	a5,a5,-2
    80004b1a:	4705                	li	a4,1
    80004b1c:	04f76763          	bltu	a4,a5,80004b6a <filestat+0x6e>
    80004b20:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b22:	6c88                	ld	a0,24(s1)
    80004b24:	fffff097          	auipc	ra,0xfffff
    80004b28:	06e080e7          	jalr	110(ra) # 80003b92 <ilock>
    stati(f->ip, &st);
    80004b2c:	fb840593          	addi	a1,s0,-72
    80004b30:	6c88                	ld	a0,24(s1)
    80004b32:	fffff097          	auipc	ra,0xfffff
    80004b36:	2ea080e7          	jalr	746(ra) # 80003e1c <stati>
    iunlock(f->ip);
    80004b3a:	6c88                	ld	a0,24(s1)
    80004b3c:	fffff097          	auipc	ra,0xfffff
    80004b40:	118080e7          	jalr	280(ra) # 80003c54 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b44:	46e1                	li	a3,24
    80004b46:	fb840613          	addi	a2,s0,-72
    80004b4a:	85ce                	mv	a1,s3
    80004b4c:	07093503          	ld	a0,112(s2)
    80004b50:	ffffd097          	auipc	ra,0xffffd
    80004b54:	aee080e7          	jalr	-1298(ra) # 8000163e <copyout>
    80004b58:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b5c:	60a6                	ld	ra,72(sp)
    80004b5e:	6406                	ld	s0,64(sp)
    80004b60:	74e2                	ld	s1,56(sp)
    80004b62:	7942                	ld	s2,48(sp)
    80004b64:	79a2                	ld	s3,40(sp)
    80004b66:	6161                	addi	sp,sp,80
    80004b68:	8082                	ret
  return -1;
    80004b6a:	557d                	li	a0,-1
    80004b6c:	bfc5                	j	80004b5c <filestat+0x60>

0000000080004b6e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b6e:	7179                	addi	sp,sp,-48
    80004b70:	f406                	sd	ra,40(sp)
    80004b72:	f022                	sd	s0,32(sp)
    80004b74:	ec26                	sd	s1,24(sp)
    80004b76:	e84a                	sd	s2,16(sp)
    80004b78:	e44e                	sd	s3,8(sp)
    80004b7a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b7c:	00854783          	lbu	a5,8(a0)
    80004b80:	c3d5                	beqz	a5,80004c24 <fileread+0xb6>
    80004b82:	84aa                	mv	s1,a0
    80004b84:	89ae                	mv	s3,a1
    80004b86:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b88:	411c                	lw	a5,0(a0)
    80004b8a:	4705                	li	a4,1
    80004b8c:	04e78963          	beq	a5,a4,80004bde <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b90:	470d                	li	a4,3
    80004b92:	04e78d63          	beq	a5,a4,80004bec <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b96:	4709                	li	a4,2
    80004b98:	06e79e63          	bne	a5,a4,80004c14 <fileread+0xa6>
    ilock(f->ip);
    80004b9c:	6d08                	ld	a0,24(a0)
    80004b9e:	fffff097          	auipc	ra,0xfffff
    80004ba2:	ff4080e7          	jalr	-12(ra) # 80003b92 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ba6:	874a                	mv	a4,s2
    80004ba8:	5094                	lw	a3,32(s1)
    80004baa:	864e                	mv	a2,s3
    80004bac:	4585                	li	a1,1
    80004bae:	6c88                	ld	a0,24(s1)
    80004bb0:	fffff097          	auipc	ra,0xfffff
    80004bb4:	296080e7          	jalr	662(ra) # 80003e46 <readi>
    80004bb8:	892a                	mv	s2,a0
    80004bba:	00a05563          	blez	a0,80004bc4 <fileread+0x56>
      f->off += r;
    80004bbe:	509c                	lw	a5,32(s1)
    80004bc0:	9fa9                	addw	a5,a5,a0
    80004bc2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bc4:	6c88                	ld	a0,24(s1)
    80004bc6:	fffff097          	auipc	ra,0xfffff
    80004bca:	08e080e7          	jalr	142(ra) # 80003c54 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bce:	854a                	mv	a0,s2
    80004bd0:	70a2                	ld	ra,40(sp)
    80004bd2:	7402                	ld	s0,32(sp)
    80004bd4:	64e2                	ld	s1,24(sp)
    80004bd6:	6942                	ld	s2,16(sp)
    80004bd8:	69a2                	ld	s3,8(sp)
    80004bda:	6145                	addi	sp,sp,48
    80004bdc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004bde:	6908                	ld	a0,16(a0)
    80004be0:	00000097          	auipc	ra,0x0
    80004be4:	3c0080e7          	jalr	960(ra) # 80004fa0 <piperead>
    80004be8:	892a                	mv	s2,a0
    80004bea:	b7d5                	j	80004bce <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bec:	02451783          	lh	a5,36(a0)
    80004bf0:	03079693          	slli	a3,a5,0x30
    80004bf4:	92c1                	srli	a3,a3,0x30
    80004bf6:	4725                	li	a4,9
    80004bf8:	02d76863          	bltu	a4,a3,80004c28 <fileread+0xba>
    80004bfc:	0792                	slli	a5,a5,0x4
    80004bfe:	0001d717          	auipc	a4,0x1d
    80004c02:	f3270713          	addi	a4,a4,-206 # 80021b30 <devsw>
    80004c06:	97ba                	add	a5,a5,a4
    80004c08:	639c                	ld	a5,0(a5)
    80004c0a:	c38d                	beqz	a5,80004c2c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c0c:	4505                	li	a0,1
    80004c0e:	9782                	jalr	a5
    80004c10:	892a                	mv	s2,a0
    80004c12:	bf75                	j	80004bce <fileread+0x60>
    panic("fileread");
    80004c14:	00004517          	auipc	a0,0x4
    80004c18:	cc450513          	addi	a0,a0,-828 # 800088d8 <syscalls+0x270>
    80004c1c:	ffffc097          	auipc	ra,0xffffc
    80004c20:	90e080e7          	jalr	-1778(ra) # 8000052a <panic>
    return -1;
    80004c24:	597d                	li	s2,-1
    80004c26:	b765                	j	80004bce <fileread+0x60>
      return -1;
    80004c28:	597d                	li	s2,-1
    80004c2a:	b755                	j	80004bce <fileread+0x60>
    80004c2c:	597d                	li	s2,-1
    80004c2e:	b745                	j	80004bce <fileread+0x60>

0000000080004c30 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c30:	715d                	addi	sp,sp,-80
    80004c32:	e486                	sd	ra,72(sp)
    80004c34:	e0a2                	sd	s0,64(sp)
    80004c36:	fc26                	sd	s1,56(sp)
    80004c38:	f84a                	sd	s2,48(sp)
    80004c3a:	f44e                	sd	s3,40(sp)
    80004c3c:	f052                	sd	s4,32(sp)
    80004c3e:	ec56                	sd	s5,24(sp)
    80004c40:	e85a                	sd	s6,16(sp)
    80004c42:	e45e                	sd	s7,8(sp)
    80004c44:	e062                	sd	s8,0(sp)
    80004c46:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c48:	00954783          	lbu	a5,9(a0)
    80004c4c:	10078663          	beqz	a5,80004d58 <filewrite+0x128>
    80004c50:	892a                	mv	s2,a0
    80004c52:	8aae                	mv	s5,a1
    80004c54:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c56:	411c                	lw	a5,0(a0)
    80004c58:	4705                	li	a4,1
    80004c5a:	02e78263          	beq	a5,a4,80004c7e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c5e:	470d                	li	a4,3
    80004c60:	02e78663          	beq	a5,a4,80004c8c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c64:	4709                	li	a4,2
    80004c66:	0ee79163          	bne	a5,a4,80004d48 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c6a:	0ac05d63          	blez	a2,80004d24 <filewrite+0xf4>
    int i = 0;
    80004c6e:	4981                	li	s3,0
    80004c70:	6b05                	lui	s6,0x1
    80004c72:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c76:	6b85                	lui	s7,0x1
    80004c78:	c00b8b9b          	addiw	s7,s7,-1024
    80004c7c:	a861                	j	80004d14 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c7e:	6908                	ld	a0,16(a0)
    80004c80:	00000097          	auipc	ra,0x0
    80004c84:	22e080e7          	jalr	558(ra) # 80004eae <pipewrite>
    80004c88:	8a2a                	mv	s4,a0
    80004c8a:	a045                	j	80004d2a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c8c:	02451783          	lh	a5,36(a0)
    80004c90:	03079693          	slli	a3,a5,0x30
    80004c94:	92c1                	srli	a3,a3,0x30
    80004c96:	4725                	li	a4,9
    80004c98:	0cd76263          	bltu	a4,a3,80004d5c <filewrite+0x12c>
    80004c9c:	0792                	slli	a5,a5,0x4
    80004c9e:	0001d717          	auipc	a4,0x1d
    80004ca2:	e9270713          	addi	a4,a4,-366 # 80021b30 <devsw>
    80004ca6:	97ba                	add	a5,a5,a4
    80004ca8:	679c                	ld	a5,8(a5)
    80004caa:	cbdd                	beqz	a5,80004d60 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004cac:	4505                	li	a0,1
    80004cae:	9782                	jalr	a5
    80004cb0:	8a2a                	mv	s4,a0
    80004cb2:	a8a5                	j	80004d2a <filewrite+0xfa>
    80004cb4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004cb8:	00000097          	auipc	ra,0x0
    80004cbc:	8b0080e7          	jalr	-1872(ra) # 80004568 <begin_op>
      ilock(f->ip);
    80004cc0:	01893503          	ld	a0,24(s2)
    80004cc4:	fffff097          	auipc	ra,0xfffff
    80004cc8:	ece080e7          	jalr	-306(ra) # 80003b92 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ccc:	8762                	mv	a4,s8
    80004cce:	02092683          	lw	a3,32(s2)
    80004cd2:	01598633          	add	a2,s3,s5
    80004cd6:	4585                	li	a1,1
    80004cd8:	01893503          	ld	a0,24(s2)
    80004cdc:	fffff097          	auipc	ra,0xfffff
    80004ce0:	262080e7          	jalr	610(ra) # 80003f3e <writei>
    80004ce4:	84aa                	mv	s1,a0
    80004ce6:	00a05763          	blez	a0,80004cf4 <filewrite+0xc4>
        f->off += r;
    80004cea:	02092783          	lw	a5,32(s2)
    80004cee:	9fa9                	addw	a5,a5,a0
    80004cf0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cf4:	01893503          	ld	a0,24(s2)
    80004cf8:	fffff097          	auipc	ra,0xfffff
    80004cfc:	f5c080e7          	jalr	-164(ra) # 80003c54 <iunlock>
      end_op();
    80004d00:	00000097          	auipc	ra,0x0
    80004d04:	8e8080e7          	jalr	-1816(ra) # 800045e8 <end_op>

      if(r != n1){
    80004d08:	009c1f63          	bne	s8,s1,80004d26 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d0c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d10:	0149db63          	bge	s3,s4,80004d26 <filewrite+0xf6>
      int n1 = n - i;
    80004d14:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d18:	84be                	mv	s1,a5
    80004d1a:	2781                	sext.w	a5,a5
    80004d1c:	f8fb5ce3          	bge	s6,a5,80004cb4 <filewrite+0x84>
    80004d20:	84de                	mv	s1,s7
    80004d22:	bf49                	j	80004cb4 <filewrite+0x84>
    int i = 0;
    80004d24:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d26:	013a1f63          	bne	s4,s3,80004d44 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d2a:	8552                	mv	a0,s4
    80004d2c:	60a6                	ld	ra,72(sp)
    80004d2e:	6406                	ld	s0,64(sp)
    80004d30:	74e2                	ld	s1,56(sp)
    80004d32:	7942                	ld	s2,48(sp)
    80004d34:	79a2                	ld	s3,40(sp)
    80004d36:	7a02                	ld	s4,32(sp)
    80004d38:	6ae2                	ld	s5,24(sp)
    80004d3a:	6b42                	ld	s6,16(sp)
    80004d3c:	6ba2                	ld	s7,8(sp)
    80004d3e:	6c02                	ld	s8,0(sp)
    80004d40:	6161                	addi	sp,sp,80
    80004d42:	8082                	ret
    ret = (i == n ? n : -1);
    80004d44:	5a7d                	li	s4,-1
    80004d46:	b7d5                	j	80004d2a <filewrite+0xfa>
    panic("filewrite");
    80004d48:	00004517          	auipc	a0,0x4
    80004d4c:	ba050513          	addi	a0,a0,-1120 # 800088e8 <syscalls+0x280>
    80004d50:	ffffb097          	auipc	ra,0xffffb
    80004d54:	7da080e7          	jalr	2010(ra) # 8000052a <panic>
    return -1;
    80004d58:	5a7d                	li	s4,-1
    80004d5a:	bfc1                	j	80004d2a <filewrite+0xfa>
      return -1;
    80004d5c:	5a7d                	li	s4,-1
    80004d5e:	b7f1                	j	80004d2a <filewrite+0xfa>
    80004d60:	5a7d                	li	s4,-1
    80004d62:	b7e1                	j	80004d2a <filewrite+0xfa>

0000000080004d64 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d64:	7179                	addi	sp,sp,-48
    80004d66:	f406                	sd	ra,40(sp)
    80004d68:	f022                	sd	s0,32(sp)
    80004d6a:	ec26                	sd	s1,24(sp)
    80004d6c:	e84a                	sd	s2,16(sp)
    80004d6e:	e44e                	sd	s3,8(sp)
    80004d70:	e052                	sd	s4,0(sp)
    80004d72:	1800                	addi	s0,sp,48
    80004d74:	84aa                	mv	s1,a0
    80004d76:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d78:	0005b023          	sd	zero,0(a1)
    80004d7c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d80:	00000097          	auipc	ra,0x0
    80004d84:	bf8080e7          	jalr	-1032(ra) # 80004978 <filealloc>
    80004d88:	e088                	sd	a0,0(s1)
    80004d8a:	c551                	beqz	a0,80004e16 <pipealloc+0xb2>
    80004d8c:	00000097          	auipc	ra,0x0
    80004d90:	bec080e7          	jalr	-1044(ra) # 80004978 <filealloc>
    80004d94:	00aa3023          	sd	a0,0(s4)
    80004d98:	c92d                	beqz	a0,80004e0a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	d38080e7          	jalr	-712(ra) # 80000ad2 <kalloc>
    80004da2:	892a                	mv	s2,a0
    80004da4:	c125                	beqz	a0,80004e04 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004da6:	4985                	li	s3,1
    80004da8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004dac:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004db0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004db4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004db8:	00003597          	auipc	a1,0x3
    80004dbc:	72858593          	addi	a1,a1,1832 # 800084e0 <states.0+0x1e0>
    80004dc0:	ffffc097          	auipc	ra,0xffffc
    80004dc4:	d72080e7          	jalr	-654(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004dc8:	609c                	ld	a5,0(s1)
    80004dca:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004dce:	609c                	ld	a5,0(s1)
    80004dd0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004dd4:	609c                	ld	a5,0(s1)
    80004dd6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004dda:	609c                	ld	a5,0(s1)
    80004ddc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004de0:	000a3783          	ld	a5,0(s4)
    80004de4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004de8:	000a3783          	ld	a5,0(s4)
    80004dec:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004df0:	000a3783          	ld	a5,0(s4)
    80004df4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004df8:	000a3783          	ld	a5,0(s4)
    80004dfc:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e00:	4501                	li	a0,0
    80004e02:	a025                	j	80004e2a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e04:	6088                	ld	a0,0(s1)
    80004e06:	e501                	bnez	a0,80004e0e <pipealloc+0xaa>
    80004e08:	a039                	j	80004e16 <pipealloc+0xb2>
    80004e0a:	6088                	ld	a0,0(s1)
    80004e0c:	c51d                	beqz	a0,80004e3a <pipealloc+0xd6>
    fileclose(*f0);
    80004e0e:	00000097          	auipc	ra,0x0
    80004e12:	c26080e7          	jalr	-986(ra) # 80004a34 <fileclose>
  if(*f1)
    80004e16:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e1a:	557d                	li	a0,-1
  if(*f1)
    80004e1c:	c799                	beqz	a5,80004e2a <pipealloc+0xc6>
    fileclose(*f1);
    80004e1e:	853e                	mv	a0,a5
    80004e20:	00000097          	auipc	ra,0x0
    80004e24:	c14080e7          	jalr	-1004(ra) # 80004a34 <fileclose>
  return -1;
    80004e28:	557d                	li	a0,-1
}
    80004e2a:	70a2                	ld	ra,40(sp)
    80004e2c:	7402                	ld	s0,32(sp)
    80004e2e:	64e2                	ld	s1,24(sp)
    80004e30:	6942                	ld	s2,16(sp)
    80004e32:	69a2                	ld	s3,8(sp)
    80004e34:	6a02                	ld	s4,0(sp)
    80004e36:	6145                	addi	sp,sp,48
    80004e38:	8082                	ret
  return -1;
    80004e3a:	557d                	li	a0,-1
    80004e3c:	b7fd                	j	80004e2a <pipealloc+0xc6>

0000000080004e3e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e3e:	1101                	addi	sp,sp,-32
    80004e40:	ec06                	sd	ra,24(sp)
    80004e42:	e822                	sd	s0,16(sp)
    80004e44:	e426                	sd	s1,8(sp)
    80004e46:	e04a                	sd	s2,0(sp)
    80004e48:	1000                	addi	s0,sp,32
    80004e4a:	84aa                	mv	s1,a0
    80004e4c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e4e:	ffffc097          	auipc	ra,0xffffc
    80004e52:	d74080e7          	jalr	-652(ra) # 80000bc2 <acquire>
  if(writable){
    80004e56:	02090d63          	beqz	s2,80004e90 <pipeclose+0x52>
    pi->writeopen = 0;
    80004e5a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e5e:	21848513          	addi	a0,s1,536
    80004e62:	ffffd097          	auipc	ra,0xffffd
    80004e66:	518080e7          	jalr	1304(ra) # 8000237a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e6a:	2204b783          	ld	a5,544(s1)
    80004e6e:	eb95                	bnez	a5,80004ea2 <pipeclose+0x64>
    release(&pi->lock);
    80004e70:	8526                	mv	a0,s1
    80004e72:	ffffc097          	auipc	ra,0xffffc
    80004e76:	e04080e7          	jalr	-508(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004e7a:	8526                	mv	a0,s1
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	b5a080e7          	jalr	-1190(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004e84:	60e2                	ld	ra,24(sp)
    80004e86:	6442                	ld	s0,16(sp)
    80004e88:	64a2                	ld	s1,8(sp)
    80004e8a:	6902                	ld	s2,0(sp)
    80004e8c:	6105                	addi	sp,sp,32
    80004e8e:	8082                	ret
    pi->readopen = 0;
    80004e90:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e94:	21c48513          	addi	a0,s1,540
    80004e98:	ffffd097          	auipc	ra,0xffffd
    80004e9c:	4e2080e7          	jalr	1250(ra) # 8000237a <wakeup>
    80004ea0:	b7e9                	j	80004e6a <pipeclose+0x2c>
    release(&pi->lock);
    80004ea2:	8526                	mv	a0,s1
    80004ea4:	ffffc097          	auipc	ra,0xffffc
    80004ea8:	dd2080e7          	jalr	-558(ra) # 80000c76 <release>
}
    80004eac:	bfe1                	j	80004e84 <pipeclose+0x46>

0000000080004eae <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004eae:	711d                	addi	sp,sp,-96
    80004eb0:	ec86                	sd	ra,88(sp)
    80004eb2:	e8a2                	sd	s0,80(sp)
    80004eb4:	e4a6                	sd	s1,72(sp)
    80004eb6:	e0ca                	sd	s2,64(sp)
    80004eb8:	fc4e                	sd	s3,56(sp)
    80004eba:	f852                	sd	s4,48(sp)
    80004ebc:	f456                	sd	s5,40(sp)
    80004ebe:	f05a                	sd	s6,32(sp)
    80004ec0:	ec5e                	sd	s7,24(sp)
    80004ec2:	e862                	sd	s8,16(sp)
    80004ec4:	1080                	addi	s0,sp,96
    80004ec6:	84aa                	mv	s1,a0
    80004ec8:	8aae                	mv	s5,a1
    80004eca:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ecc:	ffffd097          	auipc	ra,0xffffd
    80004ed0:	af6080e7          	jalr	-1290(ra) # 800019c2 <myproc>
    80004ed4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ed6:	8526                	mv	a0,s1
    80004ed8:	ffffc097          	auipc	ra,0xffffc
    80004edc:	cea080e7          	jalr	-790(ra) # 80000bc2 <acquire>
  while(i < n){
    80004ee0:	0b405363          	blez	s4,80004f86 <pipewrite+0xd8>
  int i = 0;
    80004ee4:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ee6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ee8:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004eec:	21c48b93          	addi	s7,s1,540
    80004ef0:	a089                	j	80004f32 <pipewrite+0x84>
      release(&pi->lock);
    80004ef2:	8526                	mv	a0,s1
    80004ef4:	ffffc097          	auipc	ra,0xffffc
    80004ef8:	d82080e7          	jalr	-638(ra) # 80000c76 <release>
      return -1;
    80004efc:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004efe:	854a                	mv	a0,s2
    80004f00:	60e6                	ld	ra,88(sp)
    80004f02:	6446                	ld	s0,80(sp)
    80004f04:	64a6                	ld	s1,72(sp)
    80004f06:	6906                	ld	s2,64(sp)
    80004f08:	79e2                	ld	s3,56(sp)
    80004f0a:	7a42                	ld	s4,48(sp)
    80004f0c:	7aa2                	ld	s5,40(sp)
    80004f0e:	7b02                	ld	s6,32(sp)
    80004f10:	6be2                	ld	s7,24(sp)
    80004f12:	6c42                	ld	s8,16(sp)
    80004f14:	6125                	addi	sp,sp,96
    80004f16:	8082                	ret
      wakeup(&pi->nread);
    80004f18:	8562                	mv	a0,s8
    80004f1a:	ffffd097          	auipc	ra,0xffffd
    80004f1e:	460080e7          	jalr	1120(ra) # 8000237a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f22:	85a6                	mv	a1,s1
    80004f24:	855e                	mv	a0,s7
    80004f26:	ffffd097          	auipc	ra,0xffffd
    80004f2a:	2c8080e7          	jalr	712(ra) # 800021ee <sleep>
  while(i < n){
    80004f2e:	05495d63          	bge	s2,s4,80004f88 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004f32:	2204a783          	lw	a5,544(s1)
    80004f36:	dfd5                	beqz	a5,80004ef2 <pipewrite+0x44>
    80004f38:	0289a783          	lw	a5,40(s3)
    80004f3c:	fbdd                	bnez	a5,80004ef2 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f3e:	2184a783          	lw	a5,536(s1)
    80004f42:	21c4a703          	lw	a4,540(s1)
    80004f46:	2007879b          	addiw	a5,a5,512
    80004f4a:	fcf707e3          	beq	a4,a5,80004f18 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f4e:	4685                	li	a3,1
    80004f50:	01590633          	add	a2,s2,s5
    80004f54:	faf40593          	addi	a1,s0,-81
    80004f58:	0709b503          	ld	a0,112(s3)
    80004f5c:	ffffc097          	auipc	ra,0xffffc
    80004f60:	76e080e7          	jalr	1902(ra) # 800016ca <copyin>
    80004f64:	03650263          	beq	a0,s6,80004f88 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f68:	21c4a783          	lw	a5,540(s1)
    80004f6c:	0017871b          	addiw	a4,a5,1
    80004f70:	20e4ae23          	sw	a4,540(s1)
    80004f74:	1ff7f793          	andi	a5,a5,511
    80004f78:	97a6                	add	a5,a5,s1
    80004f7a:	faf44703          	lbu	a4,-81(s0)
    80004f7e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f82:	2905                	addiw	s2,s2,1
    80004f84:	b76d                	j	80004f2e <pipewrite+0x80>
  int i = 0;
    80004f86:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004f88:	21848513          	addi	a0,s1,536
    80004f8c:	ffffd097          	auipc	ra,0xffffd
    80004f90:	3ee080e7          	jalr	1006(ra) # 8000237a <wakeup>
  release(&pi->lock);
    80004f94:	8526                	mv	a0,s1
    80004f96:	ffffc097          	auipc	ra,0xffffc
    80004f9a:	ce0080e7          	jalr	-800(ra) # 80000c76 <release>
  return i;
    80004f9e:	b785                	j	80004efe <pipewrite+0x50>

0000000080004fa0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004fa0:	715d                	addi	sp,sp,-80
    80004fa2:	e486                	sd	ra,72(sp)
    80004fa4:	e0a2                	sd	s0,64(sp)
    80004fa6:	fc26                	sd	s1,56(sp)
    80004fa8:	f84a                	sd	s2,48(sp)
    80004faa:	f44e                	sd	s3,40(sp)
    80004fac:	f052                	sd	s4,32(sp)
    80004fae:	ec56                	sd	s5,24(sp)
    80004fb0:	e85a                	sd	s6,16(sp)
    80004fb2:	0880                	addi	s0,sp,80
    80004fb4:	84aa                	mv	s1,a0
    80004fb6:	892e                	mv	s2,a1
    80004fb8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004fba:	ffffd097          	auipc	ra,0xffffd
    80004fbe:	a08080e7          	jalr	-1528(ra) # 800019c2 <myproc>
    80004fc2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004fc4:	8526                	mv	a0,s1
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	bfc080e7          	jalr	-1028(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fce:	2184a703          	lw	a4,536(s1)
    80004fd2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fd6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fda:	02f71463          	bne	a4,a5,80005002 <piperead+0x62>
    80004fde:	2244a783          	lw	a5,548(s1)
    80004fe2:	c385                	beqz	a5,80005002 <piperead+0x62>
    if(pr->killed){
    80004fe4:	028a2783          	lw	a5,40(s4)
    80004fe8:	ebc1                	bnez	a5,80005078 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fea:	85a6                	mv	a1,s1
    80004fec:	854e                	mv	a0,s3
    80004fee:	ffffd097          	auipc	ra,0xffffd
    80004ff2:	200080e7          	jalr	512(ra) # 800021ee <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ff6:	2184a703          	lw	a4,536(s1)
    80004ffa:	21c4a783          	lw	a5,540(s1)
    80004ffe:	fef700e3          	beq	a4,a5,80004fde <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005002:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005004:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005006:	05505363          	blez	s5,8000504c <piperead+0xac>
    if(pi->nread == pi->nwrite)
    8000500a:	2184a783          	lw	a5,536(s1)
    8000500e:	21c4a703          	lw	a4,540(s1)
    80005012:	02f70d63          	beq	a4,a5,8000504c <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005016:	0017871b          	addiw	a4,a5,1
    8000501a:	20e4ac23          	sw	a4,536(s1)
    8000501e:	1ff7f793          	andi	a5,a5,511
    80005022:	97a6                	add	a5,a5,s1
    80005024:	0187c783          	lbu	a5,24(a5)
    80005028:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000502c:	4685                	li	a3,1
    8000502e:	fbf40613          	addi	a2,s0,-65
    80005032:	85ca                	mv	a1,s2
    80005034:	070a3503          	ld	a0,112(s4)
    80005038:	ffffc097          	auipc	ra,0xffffc
    8000503c:	606080e7          	jalr	1542(ra) # 8000163e <copyout>
    80005040:	01650663          	beq	a0,s6,8000504c <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005044:	2985                	addiw	s3,s3,1
    80005046:	0905                	addi	s2,s2,1
    80005048:	fd3a91e3          	bne	s5,s3,8000500a <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000504c:	21c48513          	addi	a0,s1,540
    80005050:	ffffd097          	auipc	ra,0xffffd
    80005054:	32a080e7          	jalr	810(ra) # 8000237a <wakeup>
  release(&pi->lock);
    80005058:	8526                	mv	a0,s1
    8000505a:	ffffc097          	auipc	ra,0xffffc
    8000505e:	c1c080e7          	jalr	-996(ra) # 80000c76 <release>
  return i;
}
    80005062:	854e                	mv	a0,s3
    80005064:	60a6                	ld	ra,72(sp)
    80005066:	6406                	ld	s0,64(sp)
    80005068:	74e2                	ld	s1,56(sp)
    8000506a:	7942                	ld	s2,48(sp)
    8000506c:	79a2                	ld	s3,40(sp)
    8000506e:	7a02                	ld	s4,32(sp)
    80005070:	6ae2                	ld	s5,24(sp)
    80005072:	6b42                	ld	s6,16(sp)
    80005074:	6161                	addi	sp,sp,80
    80005076:	8082                	ret
      release(&pi->lock);
    80005078:	8526                	mv	a0,s1
    8000507a:	ffffc097          	auipc	ra,0xffffc
    8000507e:	bfc080e7          	jalr	-1028(ra) # 80000c76 <release>
      return -1;
    80005082:	59fd                	li	s3,-1
    80005084:	bff9                	j	80005062 <piperead+0xc2>

0000000080005086 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005086:	de010113          	addi	sp,sp,-544
    8000508a:	20113c23          	sd	ra,536(sp)
    8000508e:	20813823          	sd	s0,528(sp)
    80005092:	20913423          	sd	s1,520(sp)
    80005096:	21213023          	sd	s2,512(sp)
    8000509a:	ffce                	sd	s3,504(sp)
    8000509c:	fbd2                	sd	s4,496(sp)
    8000509e:	f7d6                	sd	s5,488(sp)
    800050a0:	f3da                	sd	s6,480(sp)
    800050a2:	efde                	sd	s7,472(sp)
    800050a4:	ebe2                	sd	s8,464(sp)
    800050a6:	e7e6                	sd	s9,456(sp)
    800050a8:	e3ea                	sd	s10,448(sp)
    800050aa:	ff6e                	sd	s11,440(sp)
    800050ac:	1400                	addi	s0,sp,544
    800050ae:	892a                	mv	s2,a0
    800050b0:	dea43423          	sd	a0,-536(s0)
    800050b4:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050b8:	ffffd097          	auipc	ra,0xffffd
    800050bc:	90a080e7          	jalr	-1782(ra) # 800019c2 <myproc>
    800050c0:	84aa                	mv	s1,a0

  begin_op();
    800050c2:	fffff097          	auipc	ra,0xfffff
    800050c6:	4a6080e7          	jalr	1190(ra) # 80004568 <begin_op>

  if((ip = namei(path)) == 0){
    800050ca:	854a                	mv	a0,s2
    800050cc:	fffff097          	auipc	ra,0xfffff
    800050d0:	27c080e7          	jalr	636(ra) # 80004348 <namei>
    800050d4:	c93d                	beqz	a0,8000514a <exec+0xc4>
    800050d6:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050d8:	fffff097          	auipc	ra,0xfffff
    800050dc:	aba080e7          	jalr	-1350(ra) # 80003b92 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050e0:	04000713          	li	a4,64
    800050e4:	4681                	li	a3,0
    800050e6:	e4840613          	addi	a2,s0,-440
    800050ea:	4581                	li	a1,0
    800050ec:	8556                	mv	a0,s5
    800050ee:	fffff097          	auipc	ra,0xfffff
    800050f2:	d58080e7          	jalr	-680(ra) # 80003e46 <readi>
    800050f6:	04000793          	li	a5,64
    800050fa:	00f51a63          	bne	a0,a5,8000510e <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800050fe:	e4842703          	lw	a4,-440(s0)
    80005102:	464c47b7          	lui	a5,0x464c4
    80005106:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000510a:	04f70663          	beq	a4,a5,80005156 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000510e:	8556                	mv	a0,s5
    80005110:	fffff097          	auipc	ra,0xfffff
    80005114:	ce4080e7          	jalr	-796(ra) # 80003df4 <iunlockput>
    end_op();
    80005118:	fffff097          	auipc	ra,0xfffff
    8000511c:	4d0080e7          	jalr	1232(ra) # 800045e8 <end_op>
  }
  return -1;
    80005120:	557d                	li	a0,-1
}
    80005122:	21813083          	ld	ra,536(sp)
    80005126:	21013403          	ld	s0,528(sp)
    8000512a:	20813483          	ld	s1,520(sp)
    8000512e:	20013903          	ld	s2,512(sp)
    80005132:	79fe                	ld	s3,504(sp)
    80005134:	7a5e                	ld	s4,496(sp)
    80005136:	7abe                	ld	s5,488(sp)
    80005138:	7b1e                	ld	s6,480(sp)
    8000513a:	6bfe                	ld	s7,472(sp)
    8000513c:	6c5e                	ld	s8,464(sp)
    8000513e:	6cbe                	ld	s9,456(sp)
    80005140:	6d1e                	ld	s10,448(sp)
    80005142:	7dfa                	ld	s11,440(sp)
    80005144:	22010113          	addi	sp,sp,544
    80005148:	8082                	ret
    end_op();
    8000514a:	fffff097          	auipc	ra,0xfffff
    8000514e:	49e080e7          	jalr	1182(ra) # 800045e8 <end_op>
    return -1;
    80005152:	557d                	li	a0,-1
    80005154:	b7f9                	j	80005122 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005156:	8526                	mv	a0,s1
    80005158:	ffffd097          	auipc	ra,0xffffd
    8000515c:	92e080e7          	jalr	-1746(ra) # 80001a86 <proc_pagetable>
    80005160:	8b2a                	mv	s6,a0
    80005162:	d555                	beqz	a0,8000510e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005164:	e6842783          	lw	a5,-408(s0)
    80005168:	e8045703          	lhu	a4,-384(s0)
    8000516c:	c735                	beqz	a4,800051d8 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000516e:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005170:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005174:	6a05                	lui	s4,0x1
    80005176:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000517a:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    8000517e:	6d85                	lui	s11,0x1
    80005180:	7d7d                	lui	s10,0xfffff
    80005182:	ac1d                	j	800053b8 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005184:	00003517          	auipc	a0,0x3
    80005188:	77450513          	addi	a0,a0,1908 # 800088f8 <syscalls+0x290>
    8000518c:	ffffb097          	auipc	ra,0xffffb
    80005190:	39e080e7          	jalr	926(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005194:	874a                	mv	a4,s2
    80005196:	009c86bb          	addw	a3,s9,s1
    8000519a:	4581                	li	a1,0
    8000519c:	8556                	mv	a0,s5
    8000519e:	fffff097          	auipc	ra,0xfffff
    800051a2:	ca8080e7          	jalr	-856(ra) # 80003e46 <readi>
    800051a6:	2501                	sext.w	a0,a0
    800051a8:	1aa91863          	bne	s2,a0,80005358 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    800051ac:	009d84bb          	addw	s1,s11,s1
    800051b0:	013d09bb          	addw	s3,s10,s3
    800051b4:	1f74f263          	bgeu	s1,s7,80005398 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    800051b8:	02049593          	slli	a1,s1,0x20
    800051bc:	9181                	srli	a1,a1,0x20
    800051be:	95e2                	add	a1,a1,s8
    800051c0:	855a                	mv	a0,s6
    800051c2:	ffffc097          	auipc	ra,0xffffc
    800051c6:	e8a080e7          	jalr	-374(ra) # 8000104c <walkaddr>
    800051ca:	862a                	mv	a2,a0
    if(pa == 0)
    800051cc:	dd45                	beqz	a0,80005184 <exec+0xfe>
      n = PGSIZE;
    800051ce:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800051d0:	fd49f2e3          	bgeu	s3,s4,80005194 <exec+0x10e>
      n = sz - i;
    800051d4:	894e                	mv	s2,s3
    800051d6:	bf7d                	j	80005194 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800051d8:	4481                	li	s1,0
  iunlockput(ip);
    800051da:	8556                	mv	a0,s5
    800051dc:	fffff097          	auipc	ra,0xfffff
    800051e0:	c18080e7          	jalr	-1000(ra) # 80003df4 <iunlockput>
  end_op();
    800051e4:	fffff097          	auipc	ra,0xfffff
    800051e8:	404080e7          	jalr	1028(ra) # 800045e8 <end_op>
  p = myproc();
    800051ec:	ffffc097          	auipc	ra,0xffffc
    800051f0:	7d6080e7          	jalr	2006(ra) # 800019c2 <myproc>
    800051f4:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800051f6:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    800051fa:	6785                	lui	a5,0x1
    800051fc:	17fd                	addi	a5,a5,-1
    800051fe:	94be                	add	s1,s1,a5
    80005200:	77fd                	lui	a5,0xfffff
    80005202:	8fe5                	and	a5,a5,s1
    80005204:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005208:	6609                	lui	a2,0x2
    8000520a:	963e                	add	a2,a2,a5
    8000520c:	85be                	mv	a1,a5
    8000520e:	855a                	mv	a0,s6
    80005210:	ffffc097          	auipc	ra,0xffffc
    80005214:	1de080e7          	jalr	478(ra) # 800013ee <uvmalloc>
    80005218:	8c2a                	mv	s8,a0
  ip = 0;
    8000521a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000521c:	12050e63          	beqz	a0,80005358 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005220:	75f9                	lui	a1,0xffffe
    80005222:	95aa                	add	a1,a1,a0
    80005224:	855a                	mv	a0,s6
    80005226:	ffffc097          	auipc	ra,0xffffc
    8000522a:	3e6080e7          	jalr	998(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    8000522e:	7afd                	lui	s5,0xfffff
    80005230:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005232:	df043783          	ld	a5,-528(s0)
    80005236:	6388                	ld	a0,0(a5)
    80005238:	c925                	beqz	a0,800052a8 <exec+0x222>
    8000523a:	e8840993          	addi	s3,s0,-376
    8000523e:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005242:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005244:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005246:	ffffc097          	auipc	ra,0xffffc
    8000524a:	bfc080e7          	jalr	-1028(ra) # 80000e42 <strlen>
    8000524e:	0015079b          	addiw	a5,a0,1
    80005252:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005256:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000525a:	13596363          	bltu	s2,s5,80005380 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000525e:	df043d83          	ld	s11,-528(s0)
    80005262:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005266:	8552                	mv	a0,s4
    80005268:	ffffc097          	auipc	ra,0xffffc
    8000526c:	bda080e7          	jalr	-1062(ra) # 80000e42 <strlen>
    80005270:	0015069b          	addiw	a3,a0,1
    80005274:	8652                	mv	a2,s4
    80005276:	85ca                	mv	a1,s2
    80005278:	855a                	mv	a0,s6
    8000527a:	ffffc097          	auipc	ra,0xffffc
    8000527e:	3c4080e7          	jalr	964(ra) # 8000163e <copyout>
    80005282:	10054363          	bltz	a0,80005388 <exec+0x302>
    ustack[argc] = sp;
    80005286:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000528a:	0485                	addi	s1,s1,1
    8000528c:	008d8793          	addi	a5,s11,8
    80005290:	def43823          	sd	a5,-528(s0)
    80005294:	008db503          	ld	a0,8(s11)
    80005298:	c911                	beqz	a0,800052ac <exec+0x226>
    if(argc >= MAXARG)
    8000529a:	09a1                	addi	s3,s3,8
    8000529c:	fb3c95e3          	bne	s9,s3,80005246 <exec+0x1c0>
  sz = sz1;
    800052a0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052a4:	4a81                	li	s5,0
    800052a6:	a84d                	j	80005358 <exec+0x2d2>
  sp = sz;
    800052a8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800052aa:	4481                	li	s1,0
  ustack[argc] = 0;
    800052ac:	00349793          	slli	a5,s1,0x3
    800052b0:	f9040713          	addi	a4,s0,-112
    800052b4:	97ba                	add	a5,a5,a4
    800052b6:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    800052ba:	00148693          	addi	a3,s1,1
    800052be:	068e                	slli	a3,a3,0x3
    800052c0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800052c4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800052c8:	01597663          	bgeu	s2,s5,800052d4 <exec+0x24e>
  sz = sz1;
    800052cc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052d0:	4a81                	li	s5,0
    800052d2:	a059                	j	80005358 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800052d4:	e8840613          	addi	a2,s0,-376
    800052d8:	85ca                	mv	a1,s2
    800052da:	855a                	mv	a0,s6
    800052dc:	ffffc097          	auipc	ra,0xffffc
    800052e0:	362080e7          	jalr	866(ra) # 8000163e <copyout>
    800052e4:	0a054663          	bltz	a0,80005390 <exec+0x30a>
  p->trapframe->a1 = sp;
    800052e8:	078bb783          	ld	a5,120(s7) # 1078 <_entry-0x7fffef88>
    800052ec:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052f0:	de843783          	ld	a5,-536(s0)
    800052f4:	0007c703          	lbu	a4,0(a5)
    800052f8:	cf11                	beqz	a4,80005314 <exec+0x28e>
    800052fa:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052fc:	02f00693          	li	a3,47
    80005300:	a039                	j	8000530e <exec+0x288>
      last = s+1;
    80005302:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005306:	0785                	addi	a5,a5,1
    80005308:	fff7c703          	lbu	a4,-1(a5)
    8000530c:	c701                	beqz	a4,80005314 <exec+0x28e>
    if(*s == '/')
    8000530e:	fed71ce3          	bne	a4,a3,80005306 <exec+0x280>
    80005312:	bfc5                	j	80005302 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005314:	4641                	li	a2,16
    80005316:	de843583          	ld	a1,-536(s0)
    8000531a:	178b8513          	addi	a0,s7,376
    8000531e:	ffffc097          	auipc	ra,0xffffc
    80005322:	af2080e7          	jalr	-1294(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005326:	070bb503          	ld	a0,112(s7)
  p->pagetable = pagetable;
    8000532a:	076bb823          	sd	s6,112(s7)
  p->sz = sz;
    8000532e:	078bb423          	sd	s8,104(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005332:	078bb783          	ld	a5,120(s7)
    80005336:	e6043703          	ld	a4,-416(s0)
    8000533a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000533c:	078bb783          	ld	a5,120(s7)
    80005340:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005344:	85ea                	mv	a1,s10
    80005346:	ffffc097          	auipc	ra,0xffffc
    8000534a:	7dc080e7          	jalr	2012(ra) # 80001b22 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000534e:	0004851b          	sext.w	a0,s1
    80005352:	bbc1                	j	80005122 <exec+0x9c>
    80005354:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005358:	df843583          	ld	a1,-520(s0)
    8000535c:	855a                	mv	a0,s6
    8000535e:	ffffc097          	auipc	ra,0xffffc
    80005362:	7c4080e7          	jalr	1988(ra) # 80001b22 <proc_freepagetable>
  if(ip){
    80005366:	da0a94e3          	bnez	s5,8000510e <exec+0x88>
  return -1;
    8000536a:	557d                	li	a0,-1
    8000536c:	bb5d                	j	80005122 <exec+0x9c>
    8000536e:	de943c23          	sd	s1,-520(s0)
    80005372:	b7dd                	j	80005358 <exec+0x2d2>
    80005374:	de943c23          	sd	s1,-520(s0)
    80005378:	b7c5                	j	80005358 <exec+0x2d2>
    8000537a:	de943c23          	sd	s1,-520(s0)
    8000537e:	bfe9                	j	80005358 <exec+0x2d2>
  sz = sz1;
    80005380:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005384:	4a81                	li	s5,0
    80005386:	bfc9                	j	80005358 <exec+0x2d2>
  sz = sz1;
    80005388:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000538c:	4a81                	li	s5,0
    8000538e:	b7e9                	j	80005358 <exec+0x2d2>
  sz = sz1;
    80005390:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005394:	4a81                	li	s5,0
    80005396:	b7c9                	j	80005358 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005398:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000539c:	e0843783          	ld	a5,-504(s0)
    800053a0:	0017869b          	addiw	a3,a5,1
    800053a4:	e0d43423          	sd	a3,-504(s0)
    800053a8:	e0043783          	ld	a5,-512(s0)
    800053ac:	0387879b          	addiw	a5,a5,56
    800053b0:	e8045703          	lhu	a4,-384(s0)
    800053b4:	e2e6d3e3          	bge	a3,a4,800051da <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053b8:	2781                	sext.w	a5,a5
    800053ba:	e0f43023          	sd	a5,-512(s0)
    800053be:	03800713          	li	a4,56
    800053c2:	86be                	mv	a3,a5
    800053c4:	e1040613          	addi	a2,s0,-496
    800053c8:	4581                	li	a1,0
    800053ca:	8556                	mv	a0,s5
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	a7a080e7          	jalr	-1414(ra) # 80003e46 <readi>
    800053d4:	03800793          	li	a5,56
    800053d8:	f6f51ee3          	bne	a0,a5,80005354 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800053dc:	e1042783          	lw	a5,-496(s0)
    800053e0:	4705                	li	a4,1
    800053e2:	fae79de3          	bne	a5,a4,8000539c <exec+0x316>
    if(ph.memsz < ph.filesz)
    800053e6:	e3843603          	ld	a2,-456(s0)
    800053ea:	e3043783          	ld	a5,-464(s0)
    800053ee:	f8f660e3          	bltu	a2,a5,8000536e <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053f2:	e2043783          	ld	a5,-480(s0)
    800053f6:	963e                	add	a2,a2,a5
    800053f8:	f6f66ee3          	bltu	a2,a5,80005374 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053fc:	85a6                	mv	a1,s1
    800053fe:	855a                	mv	a0,s6
    80005400:	ffffc097          	auipc	ra,0xffffc
    80005404:	fee080e7          	jalr	-18(ra) # 800013ee <uvmalloc>
    80005408:	dea43c23          	sd	a0,-520(s0)
    8000540c:	d53d                	beqz	a0,8000537a <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    8000540e:	e2043c03          	ld	s8,-480(s0)
    80005412:	de043783          	ld	a5,-544(s0)
    80005416:	00fc77b3          	and	a5,s8,a5
    8000541a:	ff9d                	bnez	a5,80005358 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000541c:	e1842c83          	lw	s9,-488(s0)
    80005420:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005424:	f60b8ae3          	beqz	s7,80005398 <exec+0x312>
    80005428:	89de                	mv	s3,s7
    8000542a:	4481                	li	s1,0
    8000542c:	b371                	j	800051b8 <exec+0x132>

000000008000542e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000542e:	7179                	addi	sp,sp,-48
    80005430:	f406                	sd	ra,40(sp)
    80005432:	f022                	sd	s0,32(sp)
    80005434:	ec26                	sd	s1,24(sp)
    80005436:	e84a                	sd	s2,16(sp)
    80005438:	1800                	addi	s0,sp,48
    8000543a:	892e                	mv	s2,a1
    8000543c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000543e:	fdc40593          	addi	a1,s0,-36
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	a56080e7          	jalr	-1450(ra) # 80002e98 <argint>
    8000544a:	04054063          	bltz	a0,8000548a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000544e:	fdc42703          	lw	a4,-36(s0)
    80005452:	47bd                	li	a5,15
    80005454:	02e7ed63          	bltu	a5,a4,8000548e <argfd+0x60>
    80005458:	ffffc097          	auipc	ra,0xffffc
    8000545c:	56a080e7          	jalr	1386(ra) # 800019c2 <myproc>
    80005460:	fdc42703          	lw	a4,-36(s0)
    80005464:	01e70793          	addi	a5,a4,30
    80005468:	078e                	slli	a5,a5,0x3
    8000546a:	953e                	add	a0,a0,a5
    8000546c:	611c                	ld	a5,0(a0)
    8000546e:	c395                	beqz	a5,80005492 <argfd+0x64>
    return -1;
  if(pfd)
    80005470:	00090463          	beqz	s2,80005478 <argfd+0x4a>
    *pfd = fd;
    80005474:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005478:	4501                	li	a0,0
  if(pf)
    8000547a:	c091                	beqz	s1,8000547e <argfd+0x50>
    *pf = f;
    8000547c:	e09c                	sd	a5,0(s1)
}
    8000547e:	70a2                	ld	ra,40(sp)
    80005480:	7402                	ld	s0,32(sp)
    80005482:	64e2                	ld	s1,24(sp)
    80005484:	6942                	ld	s2,16(sp)
    80005486:	6145                	addi	sp,sp,48
    80005488:	8082                	ret
    return -1;
    8000548a:	557d                	li	a0,-1
    8000548c:	bfcd                	j	8000547e <argfd+0x50>
    return -1;
    8000548e:	557d                	li	a0,-1
    80005490:	b7fd                	j	8000547e <argfd+0x50>
    80005492:	557d                	li	a0,-1
    80005494:	b7ed                	j	8000547e <argfd+0x50>

0000000080005496 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005496:	1101                	addi	sp,sp,-32
    80005498:	ec06                	sd	ra,24(sp)
    8000549a:	e822                	sd	s0,16(sp)
    8000549c:	e426                	sd	s1,8(sp)
    8000549e:	1000                	addi	s0,sp,32
    800054a0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054a2:	ffffc097          	auipc	ra,0xffffc
    800054a6:	520080e7          	jalr	1312(ra) # 800019c2 <myproc>
    800054aa:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054ac:	0f050793          	addi	a5,a0,240
    800054b0:	4501                	li	a0,0
    800054b2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054b4:	6398                	ld	a4,0(a5)
    800054b6:	cb19                	beqz	a4,800054cc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800054b8:	2505                	addiw	a0,a0,1
    800054ba:	07a1                	addi	a5,a5,8
    800054bc:	fed51ce3          	bne	a0,a3,800054b4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800054c0:	557d                	li	a0,-1
}
    800054c2:	60e2                	ld	ra,24(sp)
    800054c4:	6442                	ld	s0,16(sp)
    800054c6:	64a2                	ld	s1,8(sp)
    800054c8:	6105                	addi	sp,sp,32
    800054ca:	8082                	ret
      p->ofile[fd] = f;
    800054cc:	01e50793          	addi	a5,a0,30
    800054d0:	078e                	slli	a5,a5,0x3
    800054d2:	963e                	add	a2,a2,a5
    800054d4:	e204                	sd	s1,0(a2)
      return fd;
    800054d6:	b7f5                	j	800054c2 <fdalloc+0x2c>

00000000800054d8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054d8:	715d                	addi	sp,sp,-80
    800054da:	e486                	sd	ra,72(sp)
    800054dc:	e0a2                	sd	s0,64(sp)
    800054de:	fc26                	sd	s1,56(sp)
    800054e0:	f84a                	sd	s2,48(sp)
    800054e2:	f44e                	sd	s3,40(sp)
    800054e4:	f052                	sd	s4,32(sp)
    800054e6:	ec56                	sd	s5,24(sp)
    800054e8:	0880                	addi	s0,sp,80
    800054ea:	89ae                	mv	s3,a1
    800054ec:	8ab2                	mv	s5,a2
    800054ee:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054f0:	fb040593          	addi	a1,s0,-80
    800054f4:	fffff097          	auipc	ra,0xfffff
    800054f8:	e72080e7          	jalr	-398(ra) # 80004366 <nameiparent>
    800054fc:	892a                	mv	s2,a0
    800054fe:	12050e63          	beqz	a0,8000563a <create+0x162>
    return 0;

  ilock(dp);
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	690080e7          	jalr	1680(ra) # 80003b92 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000550a:	4601                	li	a2,0
    8000550c:	fb040593          	addi	a1,s0,-80
    80005510:	854a                	mv	a0,s2
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	b64080e7          	jalr	-1180(ra) # 80004076 <dirlookup>
    8000551a:	84aa                	mv	s1,a0
    8000551c:	c921                	beqz	a0,8000556c <create+0x94>
    iunlockput(dp);
    8000551e:	854a                	mv	a0,s2
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	8d4080e7          	jalr	-1836(ra) # 80003df4 <iunlockput>
    ilock(ip);
    80005528:	8526                	mv	a0,s1
    8000552a:	ffffe097          	auipc	ra,0xffffe
    8000552e:	668080e7          	jalr	1640(ra) # 80003b92 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005532:	2981                	sext.w	s3,s3
    80005534:	4789                	li	a5,2
    80005536:	02f99463          	bne	s3,a5,8000555e <create+0x86>
    8000553a:	0444d783          	lhu	a5,68(s1)
    8000553e:	37f9                	addiw	a5,a5,-2
    80005540:	17c2                	slli	a5,a5,0x30
    80005542:	93c1                	srli	a5,a5,0x30
    80005544:	4705                	li	a4,1
    80005546:	00f76c63          	bltu	a4,a5,8000555e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000554a:	8526                	mv	a0,s1
    8000554c:	60a6                	ld	ra,72(sp)
    8000554e:	6406                	ld	s0,64(sp)
    80005550:	74e2                	ld	s1,56(sp)
    80005552:	7942                	ld	s2,48(sp)
    80005554:	79a2                	ld	s3,40(sp)
    80005556:	7a02                	ld	s4,32(sp)
    80005558:	6ae2                	ld	s5,24(sp)
    8000555a:	6161                	addi	sp,sp,80
    8000555c:	8082                	ret
    iunlockput(ip);
    8000555e:	8526                	mv	a0,s1
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	894080e7          	jalr	-1900(ra) # 80003df4 <iunlockput>
    return 0;
    80005568:	4481                	li	s1,0
    8000556a:	b7c5                	j	8000554a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000556c:	85ce                	mv	a1,s3
    8000556e:	00092503          	lw	a0,0(s2)
    80005572:	ffffe097          	auipc	ra,0xffffe
    80005576:	488080e7          	jalr	1160(ra) # 800039fa <ialloc>
    8000557a:	84aa                	mv	s1,a0
    8000557c:	c521                	beqz	a0,800055c4 <create+0xec>
  ilock(ip);
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	614080e7          	jalr	1556(ra) # 80003b92 <ilock>
  ip->major = major;
    80005586:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000558a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000558e:	4a05                	li	s4,1
    80005590:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005594:	8526                	mv	a0,s1
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	532080e7          	jalr	1330(ra) # 80003ac8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000559e:	2981                	sext.w	s3,s3
    800055a0:	03498a63          	beq	s3,s4,800055d4 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800055a4:	40d0                	lw	a2,4(s1)
    800055a6:	fb040593          	addi	a1,s0,-80
    800055aa:	854a                	mv	a0,s2
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	cda080e7          	jalr	-806(ra) # 80004286 <dirlink>
    800055b4:	06054b63          	bltz	a0,8000562a <create+0x152>
  iunlockput(dp);
    800055b8:	854a                	mv	a0,s2
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	83a080e7          	jalr	-1990(ra) # 80003df4 <iunlockput>
  return ip;
    800055c2:	b761                	j	8000554a <create+0x72>
    panic("create: ialloc");
    800055c4:	00003517          	auipc	a0,0x3
    800055c8:	35450513          	addi	a0,a0,852 # 80008918 <syscalls+0x2b0>
    800055cc:	ffffb097          	auipc	ra,0xffffb
    800055d0:	f5e080e7          	jalr	-162(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    800055d4:	04a95783          	lhu	a5,74(s2)
    800055d8:	2785                	addiw	a5,a5,1
    800055da:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800055de:	854a                	mv	a0,s2
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	4e8080e7          	jalr	1256(ra) # 80003ac8 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055e8:	40d0                	lw	a2,4(s1)
    800055ea:	00003597          	auipc	a1,0x3
    800055ee:	33e58593          	addi	a1,a1,830 # 80008928 <syscalls+0x2c0>
    800055f2:	8526                	mv	a0,s1
    800055f4:	fffff097          	auipc	ra,0xfffff
    800055f8:	c92080e7          	jalr	-878(ra) # 80004286 <dirlink>
    800055fc:	00054f63          	bltz	a0,8000561a <create+0x142>
    80005600:	00492603          	lw	a2,4(s2)
    80005604:	00003597          	auipc	a1,0x3
    80005608:	32c58593          	addi	a1,a1,812 # 80008930 <syscalls+0x2c8>
    8000560c:	8526                	mv	a0,s1
    8000560e:	fffff097          	auipc	ra,0xfffff
    80005612:	c78080e7          	jalr	-904(ra) # 80004286 <dirlink>
    80005616:	f80557e3          	bgez	a0,800055a4 <create+0xcc>
      panic("create dots");
    8000561a:	00003517          	auipc	a0,0x3
    8000561e:	31e50513          	addi	a0,a0,798 # 80008938 <syscalls+0x2d0>
    80005622:	ffffb097          	auipc	ra,0xffffb
    80005626:	f08080e7          	jalr	-248(ra) # 8000052a <panic>
    panic("create: dirlink");
    8000562a:	00003517          	auipc	a0,0x3
    8000562e:	31e50513          	addi	a0,a0,798 # 80008948 <syscalls+0x2e0>
    80005632:	ffffb097          	auipc	ra,0xffffb
    80005636:	ef8080e7          	jalr	-264(ra) # 8000052a <panic>
    return 0;
    8000563a:	84aa                	mv	s1,a0
    8000563c:	b739                	j	8000554a <create+0x72>

000000008000563e <sys_dup>:
{
    8000563e:	7179                	addi	sp,sp,-48
    80005640:	f406                	sd	ra,40(sp)
    80005642:	f022                	sd	s0,32(sp)
    80005644:	ec26                	sd	s1,24(sp)
    80005646:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005648:	fd840613          	addi	a2,s0,-40
    8000564c:	4581                	li	a1,0
    8000564e:	4501                	li	a0,0
    80005650:	00000097          	auipc	ra,0x0
    80005654:	dde080e7          	jalr	-546(ra) # 8000542e <argfd>
    return -1;
    80005658:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000565a:	02054363          	bltz	a0,80005680 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000565e:	fd843503          	ld	a0,-40(s0)
    80005662:	00000097          	auipc	ra,0x0
    80005666:	e34080e7          	jalr	-460(ra) # 80005496 <fdalloc>
    8000566a:	84aa                	mv	s1,a0
    return -1;
    8000566c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000566e:	00054963          	bltz	a0,80005680 <sys_dup+0x42>
  filedup(f);
    80005672:	fd843503          	ld	a0,-40(s0)
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	36c080e7          	jalr	876(ra) # 800049e2 <filedup>
  return fd;
    8000567e:	87a6                	mv	a5,s1
}
    80005680:	853e                	mv	a0,a5
    80005682:	70a2                	ld	ra,40(sp)
    80005684:	7402                	ld	s0,32(sp)
    80005686:	64e2                	ld	s1,24(sp)
    80005688:	6145                	addi	sp,sp,48
    8000568a:	8082                	ret

000000008000568c <sys_read>:
{
    8000568c:	7179                	addi	sp,sp,-48
    8000568e:	f406                	sd	ra,40(sp)
    80005690:	f022                	sd	s0,32(sp)
    80005692:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005694:	fe840613          	addi	a2,s0,-24
    80005698:	4581                	li	a1,0
    8000569a:	4501                	li	a0,0
    8000569c:	00000097          	auipc	ra,0x0
    800056a0:	d92080e7          	jalr	-622(ra) # 8000542e <argfd>
    return -1;
    800056a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056a6:	04054163          	bltz	a0,800056e8 <sys_read+0x5c>
    800056aa:	fe440593          	addi	a1,s0,-28
    800056ae:	4509                	li	a0,2
    800056b0:	ffffd097          	auipc	ra,0xffffd
    800056b4:	7e8080e7          	jalr	2024(ra) # 80002e98 <argint>
    return -1;
    800056b8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056ba:	02054763          	bltz	a0,800056e8 <sys_read+0x5c>
    800056be:	fd840593          	addi	a1,s0,-40
    800056c2:	4505                	li	a0,1
    800056c4:	ffffd097          	auipc	ra,0xffffd
    800056c8:	7f6080e7          	jalr	2038(ra) # 80002eba <argaddr>
    return -1;
    800056cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056ce:	00054d63          	bltz	a0,800056e8 <sys_read+0x5c>
  return fileread(f, p, n);
    800056d2:	fe442603          	lw	a2,-28(s0)
    800056d6:	fd843583          	ld	a1,-40(s0)
    800056da:	fe843503          	ld	a0,-24(s0)
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	490080e7          	jalr	1168(ra) # 80004b6e <fileread>
    800056e6:	87aa                	mv	a5,a0
}
    800056e8:	853e                	mv	a0,a5
    800056ea:	70a2                	ld	ra,40(sp)
    800056ec:	7402                	ld	s0,32(sp)
    800056ee:	6145                	addi	sp,sp,48
    800056f0:	8082                	ret

00000000800056f2 <sys_write>:
{
    800056f2:	7179                	addi	sp,sp,-48
    800056f4:	f406                	sd	ra,40(sp)
    800056f6:	f022                	sd	s0,32(sp)
    800056f8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056fa:	fe840613          	addi	a2,s0,-24
    800056fe:	4581                	li	a1,0
    80005700:	4501                	li	a0,0
    80005702:	00000097          	auipc	ra,0x0
    80005706:	d2c080e7          	jalr	-724(ra) # 8000542e <argfd>
    return -1;
    8000570a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000570c:	04054163          	bltz	a0,8000574e <sys_write+0x5c>
    80005710:	fe440593          	addi	a1,s0,-28
    80005714:	4509                	li	a0,2
    80005716:	ffffd097          	auipc	ra,0xffffd
    8000571a:	782080e7          	jalr	1922(ra) # 80002e98 <argint>
    return -1;
    8000571e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005720:	02054763          	bltz	a0,8000574e <sys_write+0x5c>
    80005724:	fd840593          	addi	a1,s0,-40
    80005728:	4505                	li	a0,1
    8000572a:	ffffd097          	auipc	ra,0xffffd
    8000572e:	790080e7          	jalr	1936(ra) # 80002eba <argaddr>
    return -1;
    80005732:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005734:	00054d63          	bltz	a0,8000574e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005738:	fe442603          	lw	a2,-28(s0)
    8000573c:	fd843583          	ld	a1,-40(s0)
    80005740:	fe843503          	ld	a0,-24(s0)
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	4ec080e7          	jalr	1260(ra) # 80004c30 <filewrite>
    8000574c:	87aa                	mv	a5,a0
}
    8000574e:	853e                	mv	a0,a5
    80005750:	70a2                	ld	ra,40(sp)
    80005752:	7402                	ld	s0,32(sp)
    80005754:	6145                	addi	sp,sp,48
    80005756:	8082                	ret

0000000080005758 <sys_close>:
{
    80005758:	1101                	addi	sp,sp,-32
    8000575a:	ec06                	sd	ra,24(sp)
    8000575c:	e822                	sd	s0,16(sp)
    8000575e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005760:	fe040613          	addi	a2,s0,-32
    80005764:	fec40593          	addi	a1,s0,-20
    80005768:	4501                	li	a0,0
    8000576a:	00000097          	auipc	ra,0x0
    8000576e:	cc4080e7          	jalr	-828(ra) # 8000542e <argfd>
    return -1;
    80005772:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005774:	02054463          	bltz	a0,8000579c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005778:	ffffc097          	auipc	ra,0xffffc
    8000577c:	24a080e7          	jalr	586(ra) # 800019c2 <myproc>
    80005780:	fec42783          	lw	a5,-20(s0)
    80005784:	07f9                	addi	a5,a5,30
    80005786:	078e                	slli	a5,a5,0x3
    80005788:	97aa                	add	a5,a5,a0
    8000578a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000578e:	fe043503          	ld	a0,-32(s0)
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	2a2080e7          	jalr	674(ra) # 80004a34 <fileclose>
  return 0;
    8000579a:	4781                	li	a5,0
}
    8000579c:	853e                	mv	a0,a5
    8000579e:	60e2                	ld	ra,24(sp)
    800057a0:	6442                	ld	s0,16(sp)
    800057a2:	6105                	addi	sp,sp,32
    800057a4:	8082                	ret

00000000800057a6 <sys_fstat>:
{
    800057a6:	1101                	addi	sp,sp,-32
    800057a8:	ec06                	sd	ra,24(sp)
    800057aa:	e822                	sd	s0,16(sp)
    800057ac:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057ae:	fe840613          	addi	a2,s0,-24
    800057b2:	4581                	li	a1,0
    800057b4:	4501                	li	a0,0
    800057b6:	00000097          	auipc	ra,0x0
    800057ba:	c78080e7          	jalr	-904(ra) # 8000542e <argfd>
    return -1;
    800057be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057c0:	02054563          	bltz	a0,800057ea <sys_fstat+0x44>
    800057c4:	fe040593          	addi	a1,s0,-32
    800057c8:	4505                	li	a0,1
    800057ca:	ffffd097          	auipc	ra,0xffffd
    800057ce:	6f0080e7          	jalr	1776(ra) # 80002eba <argaddr>
    return -1;
    800057d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057d4:	00054b63          	bltz	a0,800057ea <sys_fstat+0x44>
  return filestat(f, st);
    800057d8:	fe043583          	ld	a1,-32(s0)
    800057dc:	fe843503          	ld	a0,-24(s0)
    800057e0:	fffff097          	auipc	ra,0xfffff
    800057e4:	31c080e7          	jalr	796(ra) # 80004afc <filestat>
    800057e8:	87aa                	mv	a5,a0
}
    800057ea:	853e                	mv	a0,a5
    800057ec:	60e2                	ld	ra,24(sp)
    800057ee:	6442                	ld	s0,16(sp)
    800057f0:	6105                	addi	sp,sp,32
    800057f2:	8082                	ret

00000000800057f4 <sys_link>:
{
    800057f4:	7169                	addi	sp,sp,-304
    800057f6:	f606                	sd	ra,296(sp)
    800057f8:	f222                	sd	s0,288(sp)
    800057fa:	ee26                	sd	s1,280(sp)
    800057fc:	ea4a                	sd	s2,272(sp)
    800057fe:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005800:	08000613          	li	a2,128
    80005804:	ed040593          	addi	a1,s0,-304
    80005808:	4501                	li	a0,0
    8000580a:	ffffd097          	auipc	ra,0xffffd
    8000580e:	6d2080e7          	jalr	1746(ra) # 80002edc <argstr>
    return -1;
    80005812:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005814:	10054e63          	bltz	a0,80005930 <sys_link+0x13c>
    80005818:	08000613          	li	a2,128
    8000581c:	f5040593          	addi	a1,s0,-176
    80005820:	4505                	li	a0,1
    80005822:	ffffd097          	auipc	ra,0xffffd
    80005826:	6ba080e7          	jalr	1722(ra) # 80002edc <argstr>
    return -1;
    8000582a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000582c:	10054263          	bltz	a0,80005930 <sys_link+0x13c>
  begin_op();
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	d38080e7          	jalr	-712(ra) # 80004568 <begin_op>
  if((ip = namei(old)) == 0){
    80005838:	ed040513          	addi	a0,s0,-304
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	b0c080e7          	jalr	-1268(ra) # 80004348 <namei>
    80005844:	84aa                	mv	s1,a0
    80005846:	c551                	beqz	a0,800058d2 <sys_link+0xde>
  ilock(ip);
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	34a080e7          	jalr	842(ra) # 80003b92 <ilock>
  if(ip->type == T_DIR){
    80005850:	04449703          	lh	a4,68(s1)
    80005854:	4785                	li	a5,1
    80005856:	08f70463          	beq	a4,a5,800058de <sys_link+0xea>
  ip->nlink++;
    8000585a:	04a4d783          	lhu	a5,74(s1)
    8000585e:	2785                	addiw	a5,a5,1
    80005860:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005864:	8526                	mv	a0,s1
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	262080e7          	jalr	610(ra) # 80003ac8 <iupdate>
  iunlock(ip);
    8000586e:	8526                	mv	a0,s1
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	3e4080e7          	jalr	996(ra) # 80003c54 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005878:	fd040593          	addi	a1,s0,-48
    8000587c:	f5040513          	addi	a0,s0,-176
    80005880:	fffff097          	auipc	ra,0xfffff
    80005884:	ae6080e7          	jalr	-1306(ra) # 80004366 <nameiparent>
    80005888:	892a                	mv	s2,a0
    8000588a:	c935                	beqz	a0,800058fe <sys_link+0x10a>
  ilock(dp);
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	306080e7          	jalr	774(ra) # 80003b92 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005894:	00092703          	lw	a4,0(s2)
    80005898:	409c                	lw	a5,0(s1)
    8000589a:	04f71d63          	bne	a4,a5,800058f4 <sys_link+0x100>
    8000589e:	40d0                	lw	a2,4(s1)
    800058a0:	fd040593          	addi	a1,s0,-48
    800058a4:	854a                	mv	a0,s2
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	9e0080e7          	jalr	-1568(ra) # 80004286 <dirlink>
    800058ae:	04054363          	bltz	a0,800058f4 <sys_link+0x100>
  iunlockput(dp);
    800058b2:	854a                	mv	a0,s2
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	540080e7          	jalr	1344(ra) # 80003df4 <iunlockput>
  iput(ip);
    800058bc:	8526                	mv	a0,s1
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	48e080e7          	jalr	1166(ra) # 80003d4c <iput>
  end_op();
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	d22080e7          	jalr	-734(ra) # 800045e8 <end_op>
  return 0;
    800058ce:	4781                	li	a5,0
    800058d0:	a085                	j	80005930 <sys_link+0x13c>
    end_op();
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	d16080e7          	jalr	-746(ra) # 800045e8 <end_op>
    return -1;
    800058da:	57fd                	li	a5,-1
    800058dc:	a891                	j	80005930 <sys_link+0x13c>
    iunlockput(ip);
    800058de:	8526                	mv	a0,s1
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	514080e7          	jalr	1300(ra) # 80003df4 <iunlockput>
    end_op();
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	d00080e7          	jalr	-768(ra) # 800045e8 <end_op>
    return -1;
    800058f0:	57fd                	li	a5,-1
    800058f2:	a83d                	j	80005930 <sys_link+0x13c>
    iunlockput(dp);
    800058f4:	854a                	mv	a0,s2
    800058f6:	ffffe097          	auipc	ra,0xffffe
    800058fa:	4fe080e7          	jalr	1278(ra) # 80003df4 <iunlockput>
  ilock(ip);
    800058fe:	8526                	mv	a0,s1
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	292080e7          	jalr	658(ra) # 80003b92 <ilock>
  ip->nlink--;
    80005908:	04a4d783          	lhu	a5,74(s1)
    8000590c:	37fd                	addiw	a5,a5,-1
    8000590e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005912:	8526                	mv	a0,s1
    80005914:	ffffe097          	auipc	ra,0xffffe
    80005918:	1b4080e7          	jalr	436(ra) # 80003ac8 <iupdate>
  iunlockput(ip);
    8000591c:	8526                	mv	a0,s1
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	4d6080e7          	jalr	1238(ra) # 80003df4 <iunlockput>
  end_op();
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	cc2080e7          	jalr	-830(ra) # 800045e8 <end_op>
  return -1;
    8000592e:	57fd                	li	a5,-1
}
    80005930:	853e                	mv	a0,a5
    80005932:	70b2                	ld	ra,296(sp)
    80005934:	7412                	ld	s0,288(sp)
    80005936:	64f2                	ld	s1,280(sp)
    80005938:	6952                	ld	s2,272(sp)
    8000593a:	6155                	addi	sp,sp,304
    8000593c:	8082                	ret

000000008000593e <sys_unlink>:
{
    8000593e:	7151                	addi	sp,sp,-240
    80005940:	f586                	sd	ra,232(sp)
    80005942:	f1a2                	sd	s0,224(sp)
    80005944:	eda6                	sd	s1,216(sp)
    80005946:	e9ca                	sd	s2,208(sp)
    80005948:	e5ce                	sd	s3,200(sp)
    8000594a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000594c:	08000613          	li	a2,128
    80005950:	f3040593          	addi	a1,s0,-208
    80005954:	4501                	li	a0,0
    80005956:	ffffd097          	auipc	ra,0xffffd
    8000595a:	586080e7          	jalr	1414(ra) # 80002edc <argstr>
    8000595e:	18054163          	bltz	a0,80005ae0 <sys_unlink+0x1a2>
  begin_op();
    80005962:	fffff097          	auipc	ra,0xfffff
    80005966:	c06080e7          	jalr	-1018(ra) # 80004568 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000596a:	fb040593          	addi	a1,s0,-80
    8000596e:	f3040513          	addi	a0,s0,-208
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	9f4080e7          	jalr	-1548(ra) # 80004366 <nameiparent>
    8000597a:	84aa                	mv	s1,a0
    8000597c:	c979                	beqz	a0,80005a52 <sys_unlink+0x114>
  ilock(dp);
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	214080e7          	jalr	532(ra) # 80003b92 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005986:	00003597          	auipc	a1,0x3
    8000598a:	fa258593          	addi	a1,a1,-94 # 80008928 <syscalls+0x2c0>
    8000598e:	fb040513          	addi	a0,s0,-80
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	6ca080e7          	jalr	1738(ra) # 8000405c <namecmp>
    8000599a:	14050a63          	beqz	a0,80005aee <sys_unlink+0x1b0>
    8000599e:	00003597          	auipc	a1,0x3
    800059a2:	f9258593          	addi	a1,a1,-110 # 80008930 <syscalls+0x2c8>
    800059a6:	fb040513          	addi	a0,s0,-80
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	6b2080e7          	jalr	1714(ra) # 8000405c <namecmp>
    800059b2:	12050e63          	beqz	a0,80005aee <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800059b6:	f2c40613          	addi	a2,s0,-212
    800059ba:	fb040593          	addi	a1,s0,-80
    800059be:	8526                	mv	a0,s1
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	6b6080e7          	jalr	1718(ra) # 80004076 <dirlookup>
    800059c8:	892a                	mv	s2,a0
    800059ca:	12050263          	beqz	a0,80005aee <sys_unlink+0x1b0>
  ilock(ip);
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	1c4080e7          	jalr	452(ra) # 80003b92 <ilock>
  if(ip->nlink < 1)
    800059d6:	04a91783          	lh	a5,74(s2)
    800059da:	08f05263          	blez	a5,80005a5e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059de:	04491703          	lh	a4,68(s2)
    800059e2:	4785                	li	a5,1
    800059e4:	08f70563          	beq	a4,a5,80005a6e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059e8:	4641                	li	a2,16
    800059ea:	4581                	li	a1,0
    800059ec:	fc040513          	addi	a0,s0,-64
    800059f0:	ffffb097          	auipc	ra,0xffffb
    800059f4:	2ce080e7          	jalr	718(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059f8:	4741                	li	a4,16
    800059fa:	f2c42683          	lw	a3,-212(s0)
    800059fe:	fc040613          	addi	a2,s0,-64
    80005a02:	4581                	li	a1,0
    80005a04:	8526                	mv	a0,s1
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	538080e7          	jalr	1336(ra) # 80003f3e <writei>
    80005a0e:	47c1                	li	a5,16
    80005a10:	0af51563          	bne	a0,a5,80005aba <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a14:	04491703          	lh	a4,68(s2)
    80005a18:	4785                	li	a5,1
    80005a1a:	0af70863          	beq	a4,a5,80005aca <sys_unlink+0x18c>
  iunlockput(dp);
    80005a1e:	8526                	mv	a0,s1
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	3d4080e7          	jalr	980(ra) # 80003df4 <iunlockput>
  ip->nlink--;
    80005a28:	04a95783          	lhu	a5,74(s2)
    80005a2c:	37fd                	addiw	a5,a5,-1
    80005a2e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a32:	854a                	mv	a0,s2
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	094080e7          	jalr	148(ra) # 80003ac8 <iupdate>
  iunlockput(ip);
    80005a3c:	854a                	mv	a0,s2
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	3b6080e7          	jalr	950(ra) # 80003df4 <iunlockput>
  end_op();
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	ba2080e7          	jalr	-1118(ra) # 800045e8 <end_op>
  return 0;
    80005a4e:	4501                	li	a0,0
    80005a50:	a84d                	j	80005b02 <sys_unlink+0x1c4>
    end_op();
    80005a52:	fffff097          	auipc	ra,0xfffff
    80005a56:	b96080e7          	jalr	-1130(ra) # 800045e8 <end_op>
    return -1;
    80005a5a:	557d                	li	a0,-1
    80005a5c:	a05d                	j	80005b02 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a5e:	00003517          	auipc	a0,0x3
    80005a62:	efa50513          	addi	a0,a0,-262 # 80008958 <syscalls+0x2f0>
    80005a66:	ffffb097          	auipc	ra,0xffffb
    80005a6a:	ac4080e7          	jalr	-1340(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a6e:	04c92703          	lw	a4,76(s2)
    80005a72:	02000793          	li	a5,32
    80005a76:	f6e7f9e3          	bgeu	a5,a4,800059e8 <sys_unlink+0xaa>
    80005a7a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a7e:	4741                	li	a4,16
    80005a80:	86ce                	mv	a3,s3
    80005a82:	f1840613          	addi	a2,s0,-232
    80005a86:	4581                	li	a1,0
    80005a88:	854a                	mv	a0,s2
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	3bc080e7          	jalr	956(ra) # 80003e46 <readi>
    80005a92:	47c1                	li	a5,16
    80005a94:	00f51b63          	bne	a0,a5,80005aaa <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a98:	f1845783          	lhu	a5,-232(s0)
    80005a9c:	e7a1                	bnez	a5,80005ae4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a9e:	29c1                	addiw	s3,s3,16
    80005aa0:	04c92783          	lw	a5,76(s2)
    80005aa4:	fcf9ede3          	bltu	s3,a5,80005a7e <sys_unlink+0x140>
    80005aa8:	b781                	j	800059e8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005aaa:	00003517          	auipc	a0,0x3
    80005aae:	ec650513          	addi	a0,a0,-314 # 80008970 <syscalls+0x308>
    80005ab2:	ffffb097          	auipc	ra,0xffffb
    80005ab6:	a78080e7          	jalr	-1416(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005aba:	00003517          	auipc	a0,0x3
    80005abe:	ece50513          	addi	a0,a0,-306 # 80008988 <syscalls+0x320>
    80005ac2:	ffffb097          	auipc	ra,0xffffb
    80005ac6:	a68080e7          	jalr	-1432(ra) # 8000052a <panic>
    dp->nlink--;
    80005aca:	04a4d783          	lhu	a5,74(s1)
    80005ace:	37fd                	addiw	a5,a5,-1
    80005ad0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ad4:	8526                	mv	a0,s1
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	ff2080e7          	jalr	-14(ra) # 80003ac8 <iupdate>
    80005ade:	b781                	j	80005a1e <sys_unlink+0xe0>
    return -1;
    80005ae0:	557d                	li	a0,-1
    80005ae2:	a005                	j	80005b02 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005ae4:	854a                	mv	a0,s2
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	30e080e7          	jalr	782(ra) # 80003df4 <iunlockput>
  iunlockput(dp);
    80005aee:	8526                	mv	a0,s1
    80005af0:	ffffe097          	auipc	ra,0xffffe
    80005af4:	304080e7          	jalr	772(ra) # 80003df4 <iunlockput>
  end_op();
    80005af8:	fffff097          	auipc	ra,0xfffff
    80005afc:	af0080e7          	jalr	-1296(ra) # 800045e8 <end_op>
  return -1;
    80005b00:	557d                	li	a0,-1
}
    80005b02:	70ae                	ld	ra,232(sp)
    80005b04:	740e                	ld	s0,224(sp)
    80005b06:	64ee                	ld	s1,216(sp)
    80005b08:	694e                	ld	s2,208(sp)
    80005b0a:	69ae                	ld	s3,200(sp)
    80005b0c:	616d                	addi	sp,sp,240
    80005b0e:	8082                	ret

0000000080005b10 <sys_open>:

uint64
sys_open(void)
{
    80005b10:	7131                	addi	sp,sp,-192
    80005b12:	fd06                	sd	ra,184(sp)
    80005b14:	f922                	sd	s0,176(sp)
    80005b16:	f526                	sd	s1,168(sp)
    80005b18:	f14a                	sd	s2,160(sp)
    80005b1a:	ed4e                	sd	s3,152(sp)
    80005b1c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b1e:	08000613          	li	a2,128
    80005b22:	f5040593          	addi	a1,s0,-176
    80005b26:	4501                	li	a0,0
    80005b28:	ffffd097          	auipc	ra,0xffffd
    80005b2c:	3b4080e7          	jalr	948(ra) # 80002edc <argstr>
    return -1;
    80005b30:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b32:	0c054163          	bltz	a0,80005bf4 <sys_open+0xe4>
    80005b36:	f4c40593          	addi	a1,s0,-180
    80005b3a:	4505                	li	a0,1
    80005b3c:	ffffd097          	auipc	ra,0xffffd
    80005b40:	35c080e7          	jalr	860(ra) # 80002e98 <argint>
    80005b44:	0a054863          	bltz	a0,80005bf4 <sys_open+0xe4>

  begin_op();
    80005b48:	fffff097          	auipc	ra,0xfffff
    80005b4c:	a20080e7          	jalr	-1504(ra) # 80004568 <begin_op>

  if(omode & O_CREATE){
    80005b50:	f4c42783          	lw	a5,-180(s0)
    80005b54:	2007f793          	andi	a5,a5,512
    80005b58:	cbdd                	beqz	a5,80005c0e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b5a:	4681                	li	a3,0
    80005b5c:	4601                	li	a2,0
    80005b5e:	4589                	li	a1,2
    80005b60:	f5040513          	addi	a0,s0,-176
    80005b64:	00000097          	auipc	ra,0x0
    80005b68:	974080e7          	jalr	-1676(ra) # 800054d8 <create>
    80005b6c:	892a                	mv	s2,a0
    if(ip == 0){
    80005b6e:	c959                	beqz	a0,80005c04 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b70:	04491703          	lh	a4,68(s2)
    80005b74:	478d                	li	a5,3
    80005b76:	00f71763          	bne	a4,a5,80005b84 <sys_open+0x74>
    80005b7a:	04695703          	lhu	a4,70(s2)
    80005b7e:	47a5                	li	a5,9
    80005b80:	0ce7ec63          	bltu	a5,a4,80005c58 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b84:	fffff097          	auipc	ra,0xfffff
    80005b88:	df4080e7          	jalr	-524(ra) # 80004978 <filealloc>
    80005b8c:	89aa                	mv	s3,a0
    80005b8e:	10050263          	beqz	a0,80005c92 <sys_open+0x182>
    80005b92:	00000097          	auipc	ra,0x0
    80005b96:	904080e7          	jalr	-1788(ra) # 80005496 <fdalloc>
    80005b9a:	84aa                	mv	s1,a0
    80005b9c:	0e054663          	bltz	a0,80005c88 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005ba0:	04491703          	lh	a4,68(s2)
    80005ba4:	478d                	li	a5,3
    80005ba6:	0cf70463          	beq	a4,a5,80005c6e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005baa:	4789                	li	a5,2
    80005bac:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005bb0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005bb4:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005bb8:	f4c42783          	lw	a5,-180(s0)
    80005bbc:	0017c713          	xori	a4,a5,1
    80005bc0:	8b05                	andi	a4,a4,1
    80005bc2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005bc6:	0037f713          	andi	a4,a5,3
    80005bca:	00e03733          	snez	a4,a4
    80005bce:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005bd2:	4007f793          	andi	a5,a5,1024
    80005bd6:	c791                	beqz	a5,80005be2 <sys_open+0xd2>
    80005bd8:	04491703          	lh	a4,68(s2)
    80005bdc:	4789                	li	a5,2
    80005bde:	08f70f63          	beq	a4,a5,80005c7c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005be2:	854a                	mv	a0,s2
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	070080e7          	jalr	112(ra) # 80003c54 <iunlock>
  end_op();
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	9fc080e7          	jalr	-1540(ra) # 800045e8 <end_op>

  return fd;
}
    80005bf4:	8526                	mv	a0,s1
    80005bf6:	70ea                	ld	ra,184(sp)
    80005bf8:	744a                	ld	s0,176(sp)
    80005bfa:	74aa                	ld	s1,168(sp)
    80005bfc:	790a                	ld	s2,160(sp)
    80005bfe:	69ea                	ld	s3,152(sp)
    80005c00:	6129                	addi	sp,sp,192
    80005c02:	8082                	ret
      end_op();
    80005c04:	fffff097          	auipc	ra,0xfffff
    80005c08:	9e4080e7          	jalr	-1564(ra) # 800045e8 <end_op>
      return -1;
    80005c0c:	b7e5                	j	80005bf4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c0e:	f5040513          	addi	a0,s0,-176
    80005c12:	ffffe097          	auipc	ra,0xffffe
    80005c16:	736080e7          	jalr	1846(ra) # 80004348 <namei>
    80005c1a:	892a                	mv	s2,a0
    80005c1c:	c905                	beqz	a0,80005c4c <sys_open+0x13c>
    ilock(ip);
    80005c1e:	ffffe097          	auipc	ra,0xffffe
    80005c22:	f74080e7          	jalr	-140(ra) # 80003b92 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c26:	04491703          	lh	a4,68(s2)
    80005c2a:	4785                	li	a5,1
    80005c2c:	f4f712e3          	bne	a4,a5,80005b70 <sys_open+0x60>
    80005c30:	f4c42783          	lw	a5,-180(s0)
    80005c34:	dba1                	beqz	a5,80005b84 <sys_open+0x74>
      iunlockput(ip);
    80005c36:	854a                	mv	a0,s2
    80005c38:	ffffe097          	auipc	ra,0xffffe
    80005c3c:	1bc080e7          	jalr	444(ra) # 80003df4 <iunlockput>
      end_op();
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	9a8080e7          	jalr	-1624(ra) # 800045e8 <end_op>
      return -1;
    80005c48:	54fd                	li	s1,-1
    80005c4a:	b76d                	j	80005bf4 <sys_open+0xe4>
      end_op();
    80005c4c:	fffff097          	auipc	ra,0xfffff
    80005c50:	99c080e7          	jalr	-1636(ra) # 800045e8 <end_op>
      return -1;
    80005c54:	54fd                	li	s1,-1
    80005c56:	bf79                	j	80005bf4 <sys_open+0xe4>
    iunlockput(ip);
    80005c58:	854a                	mv	a0,s2
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	19a080e7          	jalr	410(ra) # 80003df4 <iunlockput>
    end_op();
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	986080e7          	jalr	-1658(ra) # 800045e8 <end_op>
    return -1;
    80005c6a:	54fd                	li	s1,-1
    80005c6c:	b761                	j	80005bf4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c6e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c72:	04691783          	lh	a5,70(s2)
    80005c76:	02f99223          	sh	a5,36(s3)
    80005c7a:	bf2d                	j	80005bb4 <sys_open+0xa4>
    itrunc(ip);
    80005c7c:	854a                	mv	a0,s2
    80005c7e:	ffffe097          	auipc	ra,0xffffe
    80005c82:	022080e7          	jalr	34(ra) # 80003ca0 <itrunc>
    80005c86:	bfb1                	j	80005be2 <sys_open+0xd2>
      fileclose(f);
    80005c88:	854e                	mv	a0,s3
    80005c8a:	fffff097          	auipc	ra,0xfffff
    80005c8e:	daa080e7          	jalr	-598(ra) # 80004a34 <fileclose>
    iunlockput(ip);
    80005c92:	854a                	mv	a0,s2
    80005c94:	ffffe097          	auipc	ra,0xffffe
    80005c98:	160080e7          	jalr	352(ra) # 80003df4 <iunlockput>
    end_op();
    80005c9c:	fffff097          	auipc	ra,0xfffff
    80005ca0:	94c080e7          	jalr	-1716(ra) # 800045e8 <end_op>
    return -1;
    80005ca4:	54fd                	li	s1,-1
    80005ca6:	b7b9                	j	80005bf4 <sys_open+0xe4>

0000000080005ca8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ca8:	7175                	addi	sp,sp,-144
    80005caa:	e506                	sd	ra,136(sp)
    80005cac:	e122                	sd	s0,128(sp)
    80005cae:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	8b8080e7          	jalr	-1864(ra) # 80004568 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005cb8:	08000613          	li	a2,128
    80005cbc:	f7040593          	addi	a1,s0,-144
    80005cc0:	4501                	li	a0,0
    80005cc2:	ffffd097          	auipc	ra,0xffffd
    80005cc6:	21a080e7          	jalr	538(ra) # 80002edc <argstr>
    80005cca:	02054963          	bltz	a0,80005cfc <sys_mkdir+0x54>
    80005cce:	4681                	li	a3,0
    80005cd0:	4601                	li	a2,0
    80005cd2:	4585                	li	a1,1
    80005cd4:	f7040513          	addi	a0,s0,-144
    80005cd8:	00000097          	auipc	ra,0x0
    80005cdc:	800080e7          	jalr	-2048(ra) # 800054d8 <create>
    80005ce0:	cd11                	beqz	a0,80005cfc <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ce2:	ffffe097          	auipc	ra,0xffffe
    80005ce6:	112080e7          	jalr	274(ra) # 80003df4 <iunlockput>
  end_op();
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	8fe080e7          	jalr	-1794(ra) # 800045e8 <end_op>
  return 0;
    80005cf2:	4501                	li	a0,0
}
    80005cf4:	60aa                	ld	ra,136(sp)
    80005cf6:	640a                	ld	s0,128(sp)
    80005cf8:	6149                	addi	sp,sp,144
    80005cfa:	8082                	ret
    end_op();
    80005cfc:	fffff097          	auipc	ra,0xfffff
    80005d00:	8ec080e7          	jalr	-1812(ra) # 800045e8 <end_op>
    return -1;
    80005d04:	557d                	li	a0,-1
    80005d06:	b7fd                	j	80005cf4 <sys_mkdir+0x4c>

0000000080005d08 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d08:	7135                	addi	sp,sp,-160
    80005d0a:	ed06                	sd	ra,152(sp)
    80005d0c:	e922                	sd	s0,144(sp)
    80005d0e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d10:	fffff097          	auipc	ra,0xfffff
    80005d14:	858080e7          	jalr	-1960(ra) # 80004568 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d18:	08000613          	li	a2,128
    80005d1c:	f7040593          	addi	a1,s0,-144
    80005d20:	4501                	li	a0,0
    80005d22:	ffffd097          	auipc	ra,0xffffd
    80005d26:	1ba080e7          	jalr	442(ra) # 80002edc <argstr>
    80005d2a:	04054a63          	bltz	a0,80005d7e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d2e:	f6c40593          	addi	a1,s0,-148
    80005d32:	4505                	li	a0,1
    80005d34:	ffffd097          	auipc	ra,0xffffd
    80005d38:	164080e7          	jalr	356(ra) # 80002e98 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d3c:	04054163          	bltz	a0,80005d7e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d40:	f6840593          	addi	a1,s0,-152
    80005d44:	4509                	li	a0,2
    80005d46:	ffffd097          	auipc	ra,0xffffd
    80005d4a:	152080e7          	jalr	338(ra) # 80002e98 <argint>
     argint(1, &major) < 0 ||
    80005d4e:	02054863          	bltz	a0,80005d7e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d52:	f6841683          	lh	a3,-152(s0)
    80005d56:	f6c41603          	lh	a2,-148(s0)
    80005d5a:	458d                	li	a1,3
    80005d5c:	f7040513          	addi	a0,s0,-144
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	778080e7          	jalr	1912(ra) # 800054d8 <create>
     argint(2, &minor) < 0 ||
    80005d68:	c919                	beqz	a0,80005d7e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d6a:	ffffe097          	auipc	ra,0xffffe
    80005d6e:	08a080e7          	jalr	138(ra) # 80003df4 <iunlockput>
  end_op();
    80005d72:	fffff097          	auipc	ra,0xfffff
    80005d76:	876080e7          	jalr	-1930(ra) # 800045e8 <end_op>
  return 0;
    80005d7a:	4501                	li	a0,0
    80005d7c:	a031                	j	80005d88 <sys_mknod+0x80>
    end_op();
    80005d7e:	fffff097          	auipc	ra,0xfffff
    80005d82:	86a080e7          	jalr	-1942(ra) # 800045e8 <end_op>
    return -1;
    80005d86:	557d                	li	a0,-1
}
    80005d88:	60ea                	ld	ra,152(sp)
    80005d8a:	644a                	ld	s0,144(sp)
    80005d8c:	610d                	addi	sp,sp,160
    80005d8e:	8082                	ret

0000000080005d90 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d90:	7135                	addi	sp,sp,-160
    80005d92:	ed06                	sd	ra,152(sp)
    80005d94:	e922                	sd	s0,144(sp)
    80005d96:	e526                	sd	s1,136(sp)
    80005d98:	e14a                	sd	s2,128(sp)
    80005d9a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d9c:	ffffc097          	auipc	ra,0xffffc
    80005da0:	c26080e7          	jalr	-986(ra) # 800019c2 <myproc>
    80005da4:	892a                	mv	s2,a0
  
  begin_op();
    80005da6:	ffffe097          	auipc	ra,0xffffe
    80005daa:	7c2080e7          	jalr	1986(ra) # 80004568 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005dae:	08000613          	li	a2,128
    80005db2:	f6040593          	addi	a1,s0,-160
    80005db6:	4501                	li	a0,0
    80005db8:	ffffd097          	auipc	ra,0xffffd
    80005dbc:	124080e7          	jalr	292(ra) # 80002edc <argstr>
    80005dc0:	04054b63          	bltz	a0,80005e16 <sys_chdir+0x86>
    80005dc4:	f6040513          	addi	a0,s0,-160
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	580080e7          	jalr	1408(ra) # 80004348 <namei>
    80005dd0:	84aa                	mv	s1,a0
    80005dd2:	c131                	beqz	a0,80005e16 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005dd4:	ffffe097          	auipc	ra,0xffffe
    80005dd8:	dbe080e7          	jalr	-578(ra) # 80003b92 <ilock>
  if(ip->type != T_DIR){
    80005ddc:	04449703          	lh	a4,68(s1)
    80005de0:	4785                	li	a5,1
    80005de2:	04f71063          	bne	a4,a5,80005e22 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005de6:	8526                	mv	a0,s1
    80005de8:	ffffe097          	auipc	ra,0xffffe
    80005dec:	e6c080e7          	jalr	-404(ra) # 80003c54 <iunlock>
  iput(p->cwd);
    80005df0:	17093503          	ld	a0,368(s2)
    80005df4:	ffffe097          	auipc	ra,0xffffe
    80005df8:	f58080e7          	jalr	-168(ra) # 80003d4c <iput>
  end_op();
    80005dfc:	ffffe097          	auipc	ra,0xffffe
    80005e00:	7ec080e7          	jalr	2028(ra) # 800045e8 <end_op>
  p->cwd = ip;
    80005e04:	16993823          	sd	s1,368(s2)
  return 0;
    80005e08:	4501                	li	a0,0
}
    80005e0a:	60ea                	ld	ra,152(sp)
    80005e0c:	644a                	ld	s0,144(sp)
    80005e0e:	64aa                	ld	s1,136(sp)
    80005e10:	690a                	ld	s2,128(sp)
    80005e12:	610d                	addi	sp,sp,160
    80005e14:	8082                	ret
    end_op();
    80005e16:	ffffe097          	auipc	ra,0xffffe
    80005e1a:	7d2080e7          	jalr	2002(ra) # 800045e8 <end_op>
    return -1;
    80005e1e:	557d                	li	a0,-1
    80005e20:	b7ed                	j	80005e0a <sys_chdir+0x7a>
    iunlockput(ip);
    80005e22:	8526                	mv	a0,s1
    80005e24:	ffffe097          	auipc	ra,0xffffe
    80005e28:	fd0080e7          	jalr	-48(ra) # 80003df4 <iunlockput>
    end_op();
    80005e2c:	ffffe097          	auipc	ra,0xffffe
    80005e30:	7bc080e7          	jalr	1980(ra) # 800045e8 <end_op>
    return -1;
    80005e34:	557d                	li	a0,-1
    80005e36:	bfd1                	j	80005e0a <sys_chdir+0x7a>

0000000080005e38 <sys_exec>:

uint64
sys_exec(void)
{
    80005e38:	7145                	addi	sp,sp,-464
    80005e3a:	e786                	sd	ra,456(sp)
    80005e3c:	e3a2                	sd	s0,448(sp)
    80005e3e:	ff26                	sd	s1,440(sp)
    80005e40:	fb4a                	sd	s2,432(sp)
    80005e42:	f74e                	sd	s3,424(sp)
    80005e44:	f352                	sd	s4,416(sp)
    80005e46:	ef56                	sd	s5,408(sp)
    80005e48:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e4a:	08000613          	li	a2,128
    80005e4e:	f4040593          	addi	a1,s0,-192
    80005e52:	4501                	li	a0,0
    80005e54:	ffffd097          	auipc	ra,0xffffd
    80005e58:	088080e7          	jalr	136(ra) # 80002edc <argstr>
    return -1;
    80005e5c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e5e:	0c054a63          	bltz	a0,80005f32 <sys_exec+0xfa>
    80005e62:	e3840593          	addi	a1,s0,-456
    80005e66:	4505                	li	a0,1
    80005e68:	ffffd097          	auipc	ra,0xffffd
    80005e6c:	052080e7          	jalr	82(ra) # 80002eba <argaddr>
    80005e70:	0c054163          	bltz	a0,80005f32 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e74:	10000613          	li	a2,256
    80005e78:	4581                	li	a1,0
    80005e7a:	e4040513          	addi	a0,s0,-448
    80005e7e:	ffffb097          	auipc	ra,0xffffb
    80005e82:	e40080e7          	jalr	-448(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e86:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e8a:	89a6                	mv	s3,s1
    80005e8c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e8e:	02000a13          	li	s4,32
    80005e92:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e96:	00391793          	slli	a5,s2,0x3
    80005e9a:	e3040593          	addi	a1,s0,-464
    80005e9e:	e3843503          	ld	a0,-456(s0)
    80005ea2:	953e                	add	a0,a0,a5
    80005ea4:	ffffd097          	auipc	ra,0xffffd
    80005ea8:	f5a080e7          	jalr	-166(ra) # 80002dfe <fetchaddr>
    80005eac:	02054a63          	bltz	a0,80005ee0 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005eb0:	e3043783          	ld	a5,-464(s0)
    80005eb4:	c3b9                	beqz	a5,80005efa <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005eb6:	ffffb097          	auipc	ra,0xffffb
    80005eba:	c1c080e7          	jalr	-996(ra) # 80000ad2 <kalloc>
    80005ebe:	85aa                	mv	a1,a0
    80005ec0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ec4:	cd11                	beqz	a0,80005ee0 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ec6:	6605                	lui	a2,0x1
    80005ec8:	e3043503          	ld	a0,-464(s0)
    80005ecc:	ffffd097          	auipc	ra,0xffffd
    80005ed0:	f84080e7          	jalr	-124(ra) # 80002e50 <fetchstr>
    80005ed4:	00054663          	bltz	a0,80005ee0 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ed8:	0905                	addi	s2,s2,1
    80005eda:	09a1                	addi	s3,s3,8
    80005edc:	fb491be3          	bne	s2,s4,80005e92 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ee0:	10048913          	addi	s2,s1,256
    80005ee4:	6088                	ld	a0,0(s1)
    80005ee6:	c529                	beqz	a0,80005f30 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ee8:	ffffb097          	auipc	ra,0xffffb
    80005eec:	aee080e7          	jalr	-1298(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ef0:	04a1                	addi	s1,s1,8
    80005ef2:	ff2499e3          	bne	s1,s2,80005ee4 <sys_exec+0xac>
  return -1;
    80005ef6:	597d                	li	s2,-1
    80005ef8:	a82d                	j	80005f32 <sys_exec+0xfa>
      argv[i] = 0;
    80005efa:	0a8e                	slli	s5,s5,0x3
    80005efc:	fc040793          	addi	a5,s0,-64
    80005f00:	9abe                	add	s5,s5,a5
    80005f02:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005f06:	e4040593          	addi	a1,s0,-448
    80005f0a:	f4040513          	addi	a0,s0,-192
    80005f0e:	fffff097          	auipc	ra,0xfffff
    80005f12:	178080e7          	jalr	376(ra) # 80005086 <exec>
    80005f16:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f18:	10048993          	addi	s3,s1,256
    80005f1c:	6088                	ld	a0,0(s1)
    80005f1e:	c911                	beqz	a0,80005f32 <sys_exec+0xfa>
    kfree(argv[i]);
    80005f20:	ffffb097          	auipc	ra,0xffffb
    80005f24:	ab6080e7          	jalr	-1354(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f28:	04a1                	addi	s1,s1,8
    80005f2a:	ff3499e3          	bne	s1,s3,80005f1c <sys_exec+0xe4>
    80005f2e:	a011                	j	80005f32 <sys_exec+0xfa>
  return -1;
    80005f30:	597d                	li	s2,-1
}
    80005f32:	854a                	mv	a0,s2
    80005f34:	60be                	ld	ra,456(sp)
    80005f36:	641e                	ld	s0,448(sp)
    80005f38:	74fa                	ld	s1,440(sp)
    80005f3a:	795a                	ld	s2,432(sp)
    80005f3c:	79ba                	ld	s3,424(sp)
    80005f3e:	7a1a                	ld	s4,416(sp)
    80005f40:	6afa                	ld	s5,408(sp)
    80005f42:	6179                	addi	sp,sp,464
    80005f44:	8082                	ret

0000000080005f46 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f46:	7139                	addi	sp,sp,-64
    80005f48:	fc06                	sd	ra,56(sp)
    80005f4a:	f822                	sd	s0,48(sp)
    80005f4c:	f426                	sd	s1,40(sp)
    80005f4e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f50:	ffffc097          	auipc	ra,0xffffc
    80005f54:	a72080e7          	jalr	-1422(ra) # 800019c2 <myproc>
    80005f58:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f5a:	fd840593          	addi	a1,s0,-40
    80005f5e:	4501                	li	a0,0
    80005f60:	ffffd097          	auipc	ra,0xffffd
    80005f64:	f5a080e7          	jalr	-166(ra) # 80002eba <argaddr>
    return -1;
    80005f68:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f6a:	0e054063          	bltz	a0,8000604a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f6e:	fc840593          	addi	a1,s0,-56
    80005f72:	fd040513          	addi	a0,s0,-48
    80005f76:	fffff097          	auipc	ra,0xfffff
    80005f7a:	dee080e7          	jalr	-530(ra) # 80004d64 <pipealloc>
    return -1;
    80005f7e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f80:	0c054563          	bltz	a0,8000604a <sys_pipe+0x104>
  fd0 = -1;
    80005f84:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f88:	fd043503          	ld	a0,-48(s0)
    80005f8c:	fffff097          	auipc	ra,0xfffff
    80005f90:	50a080e7          	jalr	1290(ra) # 80005496 <fdalloc>
    80005f94:	fca42223          	sw	a0,-60(s0)
    80005f98:	08054c63          	bltz	a0,80006030 <sys_pipe+0xea>
    80005f9c:	fc843503          	ld	a0,-56(s0)
    80005fa0:	fffff097          	auipc	ra,0xfffff
    80005fa4:	4f6080e7          	jalr	1270(ra) # 80005496 <fdalloc>
    80005fa8:	fca42023          	sw	a0,-64(s0)
    80005fac:	06054863          	bltz	a0,8000601c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fb0:	4691                	li	a3,4
    80005fb2:	fc440613          	addi	a2,s0,-60
    80005fb6:	fd843583          	ld	a1,-40(s0)
    80005fba:	78a8                	ld	a0,112(s1)
    80005fbc:	ffffb097          	auipc	ra,0xffffb
    80005fc0:	682080e7          	jalr	1666(ra) # 8000163e <copyout>
    80005fc4:	02054063          	bltz	a0,80005fe4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fc8:	4691                	li	a3,4
    80005fca:	fc040613          	addi	a2,s0,-64
    80005fce:	fd843583          	ld	a1,-40(s0)
    80005fd2:	0591                	addi	a1,a1,4
    80005fd4:	78a8                	ld	a0,112(s1)
    80005fd6:	ffffb097          	auipc	ra,0xffffb
    80005fda:	668080e7          	jalr	1640(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fde:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fe0:	06055563          	bgez	a0,8000604a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005fe4:	fc442783          	lw	a5,-60(s0)
    80005fe8:	07f9                	addi	a5,a5,30
    80005fea:	078e                	slli	a5,a5,0x3
    80005fec:	97a6                	add	a5,a5,s1
    80005fee:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ff2:	fc042503          	lw	a0,-64(s0)
    80005ff6:	0579                	addi	a0,a0,30
    80005ff8:	050e                	slli	a0,a0,0x3
    80005ffa:	9526                	add	a0,a0,s1
    80005ffc:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006000:	fd043503          	ld	a0,-48(s0)
    80006004:	fffff097          	auipc	ra,0xfffff
    80006008:	a30080e7          	jalr	-1488(ra) # 80004a34 <fileclose>
    fileclose(wf);
    8000600c:	fc843503          	ld	a0,-56(s0)
    80006010:	fffff097          	auipc	ra,0xfffff
    80006014:	a24080e7          	jalr	-1500(ra) # 80004a34 <fileclose>
    return -1;
    80006018:	57fd                	li	a5,-1
    8000601a:	a805                	j	8000604a <sys_pipe+0x104>
    if(fd0 >= 0)
    8000601c:	fc442783          	lw	a5,-60(s0)
    80006020:	0007c863          	bltz	a5,80006030 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006024:	01e78513          	addi	a0,a5,30
    80006028:	050e                	slli	a0,a0,0x3
    8000602a:	9526                	add	a0,a0,s1
    8000602c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006030:	fd043503          	ld	a0,-48(s0)
    80006034:	fffff097          	auipc	ra,0xfffff
    80006038:	a00080e7          	jalr	-1536(ra) # 80004a34 <fileclose>
    fileclose(wf);
    8000603c:	fc843503          	ld	a0,-56(s0)
    80006040:	fffff097          	auipc	ra,0xfffff
    80006044:	9f4080e7          	jalr	-1548(ra) # 80004a34 <fileclose>
    return -1;
    80006048:	57fd                	li	a5,-1
}
    8000604a:	853e                	mv	a0,a5
    8000604c:	70e2                	ld	ra,56(sp)
    8000604e:	7442                	ld	s0,48(sp)
    80006050:	74a2                	ld	s1,40(sp)
    80006052:	6121                	addi	sp,sp,64
    80006054:	8082                	ret
	...

0000000080006060 <kernelvec>:
    80006060:	7111                	addi	sp,sp,-256
    80006062:	e006                	sd	ra,0(sp)
    80006064:	e40a                	sd	sp,8(sp)
    80006066:	e80e                	sd	gp,16(sp)
    80006068:	ec12                	sd	tp,24(sp)
    8000606a:	f016                	sd	t0,32(sp)
    8000606c:	f41a                	sd	t1,40(sp)
    8000606e:	f81e                	sd	t2,48(sp)
    80006070:	fc22                	sd	s0,56(sp)
    80006072:	e0a6                	sd	s1,64(sp)
    80006074:	e4aa                	sd	a0,72(sp)
    80006076:	e8ae                	sd	a1,80(sp)
    80006078:	ecb2                	sd	a2,88(sp)
    8000607a:	f0b6                	sd	a3,96(sp)
    8000607c:	f4ba                	sd	a4,104(sp)
    8000607e:	f8be                	sd	a5,112(sp)
    80006080:	fcc2                	sd	a6,120(sp)
    80006082:	e146                	sd	a7,128(sp)
    80006084:	e54a                	sd	s2,136(sp)
    80006086:	e94e                	sd	s3,144(sp)
    80006088:	ed52                	sd	s4,152(sp)
    8000608a:	f156                	sd	s5,160(sp)
    8000608c:	f55a                	sd	s6,168(sp)
    8000608e:	f95e                	sd	s7,176(sp)
    80006090:	fd62                	sd	s8,184(sp)
    80006092:	e1e6                	sd	s9,192(sp)
    80006094:	e5ea                	sd	s10,200(sp)
    80006096:	e9ee                	sd	s11,208(sp)
    80006098:	edf2                	sd	t3,216(sp)
    8000609a:	f1f6                	sd	t4,224(sp)
    8000609c:	f5fa                	sd	t5,232(sp)
    8000609e:	f9fe                	sd	t6,240(sp)
    800060a0:	c55fc0ef          	jal	ra,80002cf4 <kerneltrap>
    800060a4:	6082                	ld	ra,0(sp)
    800060a6:	6122                	ld	sp,8(sp)
    800060a8:	61c2                	ld	gp,16(sp)
    800060aa:	7282                	ld	t0,32(sp)
    800060ac:	7322                	ld	t1,40(sp)
    800060ae:	73c2                	ld	t2,48(sp)
    800060b0:	7462                	ld	s0,56(sp)
    800060b2:	6486                	ld	s1,64(sp)
    800060b4:	6526                	ld	a0,72(sp)
    800060b6:	65c6                	ld	a1,80(sp)
    800060b8:	6666                	ld	a2,88(sp)
    800060ba:	7686                	ld	a3,96(sp)
    800060bc:	7726                	ld	a4,104(sp)
    800060be:	77c6                	ld	a5,112(sp)
    800060c0:	7866                	ld	a6,120(sp)
    800060c2:	688a                	ld	a7,128(sp)
    800060c4:	692a                	ld	s2,136(sp)
    800060c6:	69ca                	ld	s3,144(sp)
    800060c8:	6a6a                	ld	s4,152(sp)
    800060ca:	7a8a                	ld	s5,160(sp)
    800060cc:	7b2a                	ld	s6,168(sp)
    800060ce:	7bca                	ld	s7,176(sp)
    800060d0:	7c6a                	ld	s8,184(sp)
    800060d2:	6c8e                	ld	s9,192(sp)
    800060d4:	6d2e                	ld	s10,200(sp)
    800060d6:	6dce                	ld	s11,208(sp)
    800060d8:	6e6e                	ld	t3,216(sp)
    800060da:	7e8e                	ld	t4,224(sp)
    800060dc:	7f2e                	ld	t5,232(sp)
    800060de:	7fce                	ld	t6,240(sp)
    800060e0:	6111                	addi	sp,sp,256
    800060e2:	10200073          	sret
    800060e6:	00000013          	nop
    800060ea:	00000013          	nop
    800060ee:	0001                	nop

00000000800060f0 <timervec>:
    800060f0:	34051573          	csrrw	a0,mscratch,a0
    800060f4:	e10c                	sd	a1,0(a0)
    800060f6:	e510                	sd	a2,8(a0)
    800060f8:	e914                	sd	a3,16(a0)
    800060fa:	6d0c                	ld	a1,24(a0)
    800060fc:	7110                	ld	a2,32(a0)
    800060fe:	6194                	ld	a3,0(a1)
    80006100:	96b2                	add	a3,a3,a2
    80006102:	e194                	sd	a3,0(a1)
    80006104:	4589                	li	a1,2
    80006106:	14459073          	csrw	sip,a1
    8000610a:	6914                	ld	a3,16(a0)
    8000610c:	6510                	ld	a2,8(a0)
    8000610e:	610c                	ld	a1,0(a0)
    80006110:	34051573          	csrrw	a0,mscratch,a0
    80006114:	30200073          	mret
	...

000000008000611a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000611a:	1141                	addi	sp,sp,-16
    8000611c:	e422                	sd	s0,8(sp)
    8000611e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006120:	0c0007b7          	lui	a5,0xc000
    80006124:	4705                	li	a4,1
    80006126:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006128:	c3d8                	sw	a4,4(a5)
}
    8000612a:	6422                	ld	s0,8(sp)
    8000612c:	0141                	addi	sp,sp,16
    8000612e:	8082                	ret

0000000080006130 <plicinithart>:

void
plicinithart(void)
{
    80006130:	1141                	addi	sp,sp,-16
    80006132:	e406                	sd	ra,8(sp)
    80006134:	e022                	sd	s0,0(sp)
    80006136:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006138:	ffffc097          	auipc	ra,0xffffc
    8000613c:	85e080e7          	jalr	-1954(ra) # 80001996 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006140:	0085171b          	slliw	a4,a0,0x8
    80006144:	0c0027b7          	lui	a5,0xc002
    80006148:	97ba                	add	a5,a5,a4
    8000614a:	40200713          	li	a4,1026
    8000614e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006152:	00d5151b          	slliw	a0,a0,0xd
    80006156:	0c2017b7          	lui	a5,0xc201
    8000615a:	953e                	add	a0,a0,a5
    8000615c:	00052023          	sw	zero,0(a0)
}
    80006160:	60a2                	ld	ra,8(sp)
    80006162:	6402                	ld	s0,0(sp)
    80006164:	0141                	addi	sp,sp,16
    80006166:	8082                	ret

0000000080006168 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006168:	1141                	addi	sp,sp,-16
    8000616a:	e406                	sd	ra,8(sp)
    8000616c:	e022                	sd	s0,0(sp)
    8000616e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006170:	ffffc097          	auipc	ra,0xffffc
    80006174:	826080e7          	jalr	-2010(ra) # 80001996 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006178:	00d5179b          	slliw	a5,a0,0xd
    8000617c:	0c201537          	lui	a0,0xc201
    80006180:	953e                	add	a0,a0,a5
  return irq;
}
    80006182:	4148                	lw	a0,4(a0)
    80006184:	60a2                	ld	ra,8(sp)
    80006186:	6402                	ld	s0,0(sp)
    80006188:	0141                	addi	sp,sp,16
    8000618a:	8082                	ret

000000008000618c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000618c:	1101                	addi	sp,sp,-32
    8000618e:	ec06                	sd	ra,24(sp)
    80006190:	e822                	sd	s0,16(sp)
    80006192:	e426                	sd	s1,8(sp)
    80006194:	1000                	addi	s0,sp,32
    80006196:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006198:	ffffb097          	auipc	ra,0xffffb
    8000619c:	7fe080e7          	jalr	2046(ra) # 80001996 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061a0:	00d5151b          	slliw	a0,a0,0xd
    800061a4:	0c2017b7          	lui	a5,0xc201
    800061a8:	97aa                	add	a5,a5,a0
    800061aa:	c3c4                	sw	s1,4(a5)
}
    800061ac:	60e2                	ld	ra,24(sp)
    800061ae:	6442                	ld	s0,16(sp)
    800061b0:	64a2                	ld	s1,8(sp)
    800061b2:	6105                	addi	sp,sp,32
    800061b4:	8082                	ret

00000000800061b6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800061b6:	1141                	addi	sp,sp,-16
    800061b8:	e406                	sd	ra,8(sp)
    800061ba:	e022                	sd	s0,0(sp)
    800061bc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800061be:	479d                	li	a5,7
    800061c0:	06a7c963          	blt	a5,a0,80006232 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800061c4:	0001d797          	auipc	a5,0x1d
    800061c8:	e3c78793          	addi	a5,a5,-452 # 80023000 <disk>
    800061cc:	00a78733          	add	a4,a5,a0
    800061d0:	6789                	lui	a5,0x2
    800061d2:	97ba                	add	a5,a5,a4
    800061d4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800061d8:	e7ad                	bnez	a5,80006242 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800061da:	00451793          	slli	a5,a0,0x4
    800061de:	0001f717          	auipc	a4,0x1f
    800061e2:	e2270713          	addi	a4,a4,-478 # 80025000 <disk+0x2000>
    800061e6:	6314                	ld	a3,0(a4)
    800061e8:	96be                	add	a3,a3,a5
    800061ea:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800061ee:	6314                	ld	a3,0(a4)
    800061f0:	96be                	add	a3,a3,a5
    800061f2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800061f6:	6314                	ld	a3,0(a4)
    800061f8:	96be                	add	a3,a3,a5
    800061fa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800061fe:	6318                	ld	a4,0(a4)
    80006200:	97ba                	add	a5,a5,a4
    80006202:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006206:	0001d797          	auipc	a5,0x1d
    8000620a:	dfa78793          	addi	a5,a5,-518 # 80023000 <disk>
    8000620e:	97aa                	add	a5,a5,a0
    80006210:	6509                	lui	a0,0x2
    80006212:	953e                	add	a0,a0,a5
    80006214:	4785                	li	a5,1
    80006216:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000621a:	0001f517          	auipc	a0,0x1f
    8000621e:	dfe50513          	addi	a0,a0,-514 # 80025018 <disk+0x2018>
    80006222:	ffffc097          	auipc	ra,0xffffc
    80006226:	158080e7          	jalr	344(ra) # 8000237a <wakeup>
}
    8000622a:	60a2                	ld	ra,8(sp)
    8000622c:	6402                	ld	s0,0(sp)
    8000622e:	0141                	addi	sp,sp,16
    80006230:	8082                	ret
    panic("free_desc 1");
    80006232:	00002517          	auipc	a0,0x2
    80006236:	76650513          	addi	a0,a0,1894 # 80008998 <syscalls+0x330>
    8000623a:	ffffa097          	auipc	ra,0xffffa
    8000623e:	2f0080e7          	jalr	752(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006242:	00002517          	auipc	a0,0x2
    80006246:	76650513          	addi	a0,a0,1894 # 800089a8 <syscalls+0x340>
    8000624a:	ffffa097          	auipc	ra,0xffffa
    8000624e:	2e0080e7          	jalr	736(ra) # 8000052a <panic>

0000000080006252 <virtio_disk_init>:
{
    80006252:	1101                	addi	sp,sp,-32
    80006254:	ec06                	sd	ra,24(sp)
    80006256:	e822                	sd	s0,16(sp)
    80006258:	e426                	sd	s1,8(sp)
    8000625a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000625c:	00002597          	auipc	a1,0x2
    80006260:	75c58593          	addi	a1,a1,1884 # 800089b8 <syscalls+0x350>
    80006264:	0001f517          	auipc	a0,0x1f
    80006268:	ec450513          	addi	a0,a0,-316 # 80025128 <disk+0x2128>
    8000626c:	ffffb097          	auipc	ra,0xffffb
    80006270:	8c6080e7          	jalr	-1850(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006274:	100017b7          	lui	a5,0x10001
    80006278:	4398                	lw	a4,0(a5)
    8000627a:	2701                	sext.w	a4,a4
    8000627c:	747277b7          	lui	a5,0x74727
    80006280:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006284:	0ef71163          	bne	a4,a5,80006366 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006288:	100017b7          	lui	a5,0x10001
    8000628c:	43dc                	lw	a5,4(a5)
    8000628e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006290:	4705                	li	a4,1
    80006292:	0ce79a63          	bne	a5,a4,80006366 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006296:	100017b7          	lui	a5,0x10001
    8000629a:	479c                	lw	a5,8(a5)
    8000629c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000629e:	4709                	li	a4,2
    800062a0:	0ce79363          	bne	a5,a4,80006366 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062a4:	100017b7          	lui	a5,0x10001
    800062a8:	47d8                	lw	a4,12(a5)
    800062aa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062ac:	554d47b7          	lui	a5,0x554d4
    800062b0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800062b4:	0af71963          	bne	a4,a5,80006366 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800062b8:	100017b7          	lui	a5,0x10001
    800062bc:	4705                	li	a4,1
    800062be:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062c0:	470d                	li	a4,3
    800062c2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800062c4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800062c6:	c7ffe737          	lui	a4,0xc7ffe
    800062ca:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800062ce:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800062d0:	2701                	sext.w	a4,a4
    800062d2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062d4:	472d                	li	a4,11
    800062d6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800062d8:	473d                	li	a4,15
    800062da:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800062dc:	6705                	lui	a4,0x1
    800062de:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800062e0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062e4:	5bdc                	lw	a5,52(a5)
    800062e6:	2781                	sext.w	a5,a5
  if(max == 0)
    800062e8:	c7d9                	beqz	a5,80006376 <virtio_disk_init+0x124>
  if(max < NUM)
    800062ea:	471d                	li	a4,7
    800062ec:	08f77d63          	bgeu	a4,a5,80006386 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062f0:	100014b7          	lui	s1,0x10001
    800062f4:	47a1                	li	a5,8
    800062f6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800062f8:	6609                	lui	a2,0x2
    800062fa:	4581                	li	a1,0
    800062fc:	0001d517          	auipc	a0,0x1d
    80006300:	d0450513          	addi	a0,a0,-764 # 80023000 <disk>
    80006304:	ffffb097          	auipc	ra,0xffffb
    80006308:	9ba080e7          	jalr	-1606(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000630c:	0001d717          	auipc	a4,0x1d
    80006310:	cf470713          	addi	a4,a4,-780 # 80023000 <disk>
    80006314:	00c75793          	srli	a5,a4,0xc
    80006318:	2781                	sext.w	a5,a5
    8000631a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000631c:	0001f797          	auipc	a5,0x1f
    80006320:	ce478793          	addi	a5,a5,-796 # 80025000 <disk+0x2000>
    80006324:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006326:	0001d717          	auipc	a4,0x1d
    8000632a:	d5a70713          	addi	a4,a4,-678 # 80023080 <disk+0x80>
    8000632e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006330:	0001e717          	auipc	a4,0x1e
    80006334:	cd070713          	addi	a4,a4,-816 # 80024000 <disk+0x1000>
    80006338:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000633a:	4705                	li	a4,1
    8000633c:	00e78c23          	sb	a4,24(a5)
    80006340:	00e78ca3          	sb	a4,25(a5)
    80006344:	00e78d23          	sb	a4,26(a5)
    80006348:	00e78da3          	sb	a4,27(a5)
    8000634c:	00e78e23          	sb	a4,28(a5)
    80006350:	00e78ea3          	sb	a4,29(a5)
    80006354:	00e78f23          	sb	a4,30(a5)
    80006358:	00e78fa3          	sb	a4,31(a5)
}
    8000635c:	60e2                	ld	ra,24(sp)
    8000635e:	6442                	ld	s0,16(sp)
    80006360:	64a2                	ld	s1,8(sp)
    80006362:	6105                	addi	sp,sp,32
    80006364:	8082                	ret
    panic("could not find virtio disk");
    80006366:	00002517          	auipc	a0,0x2
    8000636a:	66250513          	addi	a0,a0,1634 # 800089c8 <syscalls+0x360>
    8000636e:	ffffa097          	auipc	ra,0xffffa
    80006372:	1bc080e7          	jalr	444(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006376:	00002517          	auipc	a0,0x2
    8000637a:	67250513          	addi	a0,a0,1650 # 800089e8 <syscalls+0x380>
    8000637e:	ffffa097          	auipc	ra,0xffffa
    80006382:	1ac080e7          	jalr	428(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006386:	00002517          	auipc	a0,0x2
    8000638a:	68250513          	addi	a0,a0,1666 # 80008a08 <syscalls+0x3a0>
    8000638e:	ffffa097          	auipc	ra,0xffffa
    80006392:	19c080e7          	jalr	412(ra) # 8000052a <panic>

0000000080006396 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006396:	7119                	addi	sp,sp,-128
    80006398:	fc86                	sd	ra,120(sp)
    8000639a:	f8a2                	sd	s0,112(sp)
    8000639c:	f4a6                	sd	s1,104(sp)
    8000639e:	f0ca                	sd	s2,96(sp)
    800063a0:	ecce                	sd	s3,88(sp)
    800063a2:	e8d2                	sd	s4,80(sp)
    800063a4:	e4d6                	sd	s5,72(sp)
    800063a6:	e0da                	sd	s6,64(sp)
    800063a8:	fc5e                	sd	s7,56(sp)
    800063aa:	f862                	sd	s8,48(sp)
    800063ac:	f466                	sd	s9,40(sp)
    800063ae:	f06a                	sd	s10,32(sp)
    800063b0:	ec6e                	sd	s11,24(sp)
    800063b2:	0100                	addi	s0,sp,128
    800063b4:	8aaa                	mv	s5,a0
    800063b6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063b8:	00c52c83          	lw	s9,12(a0)
    800063bc:	001c9c9b          	slliw	s9,s9,0x1
    800063c0:	1c82                	slli	s9,s9,0x20
    800063c2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800063c6:	0001f517          	auipc	a0,0x1f
    800063ca:	d6250513          	addi	a0,a0,-670 # 80025128 <disk+0x2128>
    800063ce:	ffffa097          	auipc	ra,0xffffa
    800063d2:	7f4080e7          	jalr	2036(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    800063d6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063d8:	44a1                	li	s1,8
      disk.free[i] = 0;
    800063da:	0001dc17          	auipc	s8,0x1d
    800063de:	c26c0c13          	addi	s8,s8,-986 # 80023000 <disk>
    800063e2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    800063e4:	4b0d                	li	s6,3
    800063e6:	a0ad                	j	80006450 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    800063e8:	00fc0733          	add	a4,s8,a5
    800063ec:	975e                	add	a4,a4,s7
    800063ee:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800063f2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800063f4:	0207c563          	bltz	a5,8000641e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800063f8:	2905                	addiw	s2,s2,1
    800063fa:	0611                	addi	a2,a2,4
    800063fc:	19690d63          	beq	s2,s6,80006596 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006400:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006402:	0001f717          	auipc	a4,0x1f
    80006406:	c1670713          	addi	a4,a4,-1002 # 80025018 <disk+0x2018>
    8000640a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000640c:	00074683          	lbu	a3,0(a4)
    80006410:	fee1                	bnez	a3,800063e8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006412:	2785                	addiw	a5,a5,1
    80006414:	0705                	addi	a4,a4,1
    80006416:	fe979be3          	bne	a5,s1,8000640c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000641a:	57fd                	li	a5,-1
    8000641c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000641e:	01205d63          	blez	s2,80006438 <virtio_disk_rw+0xa2>
    80006422:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006424:	000a2503          	lw	a0,0(s4)
    80006428:	00000097          	auipc	ra,0x0
    8000642c:	d8e080e7          	jalr	-626(ra) # 800061b6 <free_desc>
      for(int j = 0; j < i; j++)
    80006430:	2d85                	addiw	s11,s11,1
    80006432:	0a11                	addi	s4,s4,4
    80006434:	ffb918e3          	bne	s2,s11,80006424 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006438:	0001f597          	auipc	a1,0x1f
    8000643c:	cf058593          	addi	a1,a1,-784 # 80025128 <disk+0x2128>
    80006440:	0001f517          	auipc	a0,0x1f
    80006444:	bd850513          	addi	a0,a0,-1064 # 80025018 <disk+0x2018>
    80006448:	ffffc097          	auipc	ra,0xffffc
    8000644c:	da6080e7          	jalr	-602(ra) # 800021ee <sleep>
  for(int i = 0; i < 3; i++){
    80006450:	f8040a13          	addi	s4,s0,-128
{
    80006454:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006456:	894e                	mv	s2,s3
    80006458:	b765                	j	80006400 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000645a:	0001f697          	auipc	a3,0x1f
    8000645e:	ba66b683          	ld	a3,-1114(a3) # 80025000 <disk+0x2000>
    80006462:	96ba                	add	a3,a3,a4
    80006464:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006468:	0001d817          	auipc	a6,0x1d
    8000646c:	b9880813          	addi	a6,a6,-1128 # 80023000 <disk>
    80006470:	0001f697          	auipc	a3,0x1f
    80006474:	b9068693          	addi	a3,a3,-1136 # 80025000 <disk+0x2000>
    80006478:	6290                	ld	a2,0(a3)
    8000647a:	963a                	add	a2,a2,a4
    8000647c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006480:	0015e593          	ori	a1,a1,1
    80006484:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006488:	f8842603          	lw	a2,-120(s0)
    8000648c:	628c                	ld	a1,0(a3)
    8000648e:	972e                	add	a4,a4,a1
    80006490:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006494:	20050593          	addi	a1,a0,512
    80006498:	0592                	slli	a1,a1,0x4
    8000649a:	95c2                	add	a1,a1,a6
    8000649c:	577d                	li	a4,-1
    8000649e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064a2:	00461713          	slli	a4,a2,0x4
    800064a6:	6290                	ld	a2,0(a3)
    800064a8:	963a                	add	a2,a2,a4
    800064aa:	03078793          	addi	a5,a5,48
    800064ae:	97c2                	add	a5,a5,a6
    800064b0:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800064b2:	629c                	ld	a5,0(a3)
    800064b4:	97ba                	add	a5,a5,a4
    800064b6:	4605                	li	a2,1
    800064b8:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800064ba:	629c                	ld	a5,0(a3)
    800064bc:	97ba                	add	a5,a5,a4
    800064be:	4809                	li	a6,2
    800064c0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800064c4:	629c                	ld	a5,0(a3)
    800064c6:	973e                	add	a4,a4,a5
    800064c8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800064cc:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800064d0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800064d4:	6698                	ld	a4,8(a3)
    800064d6:	00275783          	lhu	a5,2(a4)
    800064da:	8b9d                	andi	a5,a5,7
    800064dc:	0786                	slli	a5,a5,0x1
    800064de:	97ba                	add	a5,a5,a4
    800064e0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    800064e4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800064e8:	6698                	ld	a4,8(a3)
    800064ea:	00275783          	lhu	a5,2(a4)
    800064ee:	2785                	addiw	a5,a5,1
    800064f0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800064f4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800064f8:	100017b7          	lui	a5,0x10001
    800064fc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006500:	004aa783          	lw	a5,4(s5)
    80006504:	02c79163          	bne	a5,a2,80006526 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006508:	0001f917          	auipc	s2,0x1f
    8000650c:	c2090913          	addi	s2,s2,-992 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006510:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006512:	85ca                	mv	a1,s2
    80006514:	8556                	mv	a0,s5
    80006516:	ffffc097          	auipc	ra,0xffffc
    8000651a:	cd8080e7          	jalr	-808(ra) # 800021ee <sleep>
  while(b->disk == 1) {
    8000651e:	004aa783          	lw	a5,4(s5)
    80006522:	fe9788e3          	beq	a5,s1,80006512 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006526:	f8042903          	lw	s2,-128(s0)
    8000652a:	20090793          	addi	a5,s2,512
    8000652e:	00479713          	slli	a4,a5,0x4
    80006532:	0001d797          	auipc	a5,0x1d
    80006536:	ace78793          	addi	a5,a5,-1330 # 80023000 <disk>
    8000653a:	97ba                	add	a5,a5,a4
    8000653c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006540:	0001f997          	auipc	s3,0x1f
    80006544:	ac098993          	addi	s3,s3,-1344 # 80025000 <disk+0x2000>
    80006548:	00491713          	slli	a4,s2,0x4
    8000654c:	0009b783          	ld	a5,0(s3)
    80006550:	97ba                	add	a5,a5,a4
    80006552:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006556:	854a                	mv	a0,s2
    80006558:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000655c:	00000097          	auipc	ra,0x0
    80006560:	c5a080e7          	jalr	-934(ra) # 800061b6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006564:	8885                	andi	s1,s1,1
    80006566:	f0ed                	bnez	s1,80006548 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006568:	0001f517          	auipc	a0,0x1f
    8000656c:	bc050513          	addi	a0,a0,-1088 # 80025128 <disk+0x2128>
    80006570:	ffffa097          	auipc	ra,0xffffa
    80006574:	706080e7          	jalr	1798(ra) # 80000c76 <release>
}
    80006578:	70e6                	ld	ra,120(sp)
    8000657a:	7446                	ld	s0,112(sp)
    8000657c:	74a6                	ld	s1,104(sp)
    8000657e:	7906                	ld	s2,96(sp)
    80006580:	69e6                	ld	s3,88(sp)
    80006582:	6a46                	ld	s4,80(sp)
    80006584:	6aa6                	ld	s5,72(sp)
    80006586:	6b06                	ld	s6,64(sp)
    80006588:	7be2                	ld	s7,56(sp)
    8000658a:	7c42                	ld	s8,48(sp)
    8000658c:	7ca2                	ld	s9,40(sp)
    8000658e:	7d02                	ld	s10,32(sp)
    80006590:	6de2                	ld	s11,24(sp)
    80006592:	6109                	addi	sp,sp,128
    80006594:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006596:	f8042503          	lw	a0,-128(s0)
    8000659a:	20050793          	addi	a5,a0,512
    8000659e:	0792                	slli	a5,a5,0x4
  if(write)
    800065a0:	0001d817          	auipc	a6,0x1d
    800065a4:	a6080813          	addi	a6,a6,-1440 # 80023000 <disk>
    800065a8:	00f80733          	add	a4,a6,a5
    800065ac:	01a036b3          	snez	a3,s10
    800065b0:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800065b4:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800065b8:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800065bc:	7679                	lui	a2,0xffffe
    800065be:	963e                	add	a2,a2,a5
    800065c0:	0001f697          	auipc	a3,0x1f
    800065c4:	a4068693          	addi	a3,a3,-1472 # 80025000 <disk+0x2000>
    800065c8:	6298                	ld	a4,0(a3)
    800065ca:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065cc:	0a878593          	addi	a1,a5,168
    800065d0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800065d2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800065d4:	6298                	ld	a4,0(a3)
    800065d6:	9732                	add	a4,a4,a2
    800065d8:	45c1                	li	a1,16
    800065da:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800065dc:	6298                	ld	a4,0(a3)
    800065de:	9732                	add	a4,a4,a2
    800065e0:	4585                	li	a1,1
    800065e2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800065e6:	f8442703          	lw	a4,-124(s0)
    800065ea:	628c                	ld	a1,0(a3)
    800065ec:	962e                	add	a2,a2,a1
    800065ee:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800065f2:	0712                	slli	a4,a4,0x4
    800065f4:	6290                	ld	a2,0(a3)
    800065f6:	963a                	add	a2,a2,a4
    800065f8:	058a8593          	addi	a1,s5,88
    800065fc:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800065fe:	6294                	ld	a3,0(a3)
    80006600:	96ba                	add	a3,a3,a4
    80006602:	40000613          	li	a2,1024
    80006606:	c690                	sw	a2,8(a3)
  if(write)
    80006608:	e40d19e3          	bnez	s10,8000645a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000660c:	0001f697          	auipc	a3,0x1f
    80006610:	9f46b683          	ld	a3,-1548(a3) # 80025000 <disk+0x2000>
    80006614:	96ba                	add	a3,a3,a4
    80006616:	4609                	li	a2,2
    80006618:	00c69623          	sh	a2,12(a3)
    8000661c:	b5b1                	j	80006468 <virtio_disk_rw+0xd2>

000000008000661e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000661e:	1101                	addi	sp,sp,-32
    80006620:	ec06                	sd	ra,24(sp)
    80006622:	e822                	sd	s0,16(sp)
    80006624:	e426                	sd	s1,8(sp)
    80006626:	e04a                	sd	s2,0(sp)
    80006628:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000662a:	0001f517          	auipc	a0,0x1f
    8000662e:	afe50513          	addi	a0,a0,-1282 # 80025128 <disk+0x2128>
    80006632:	ffffa097          	auipc	ra,0xffffa
    80006636:	590080e7          	jalr	1424(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000663a:	10001737          	lui	a4,0x10001
    8000663e:	533c                	lw	a5,96(a4)
    80006640:	8b8d                	andi	a5,a5,3
    80006642:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006644:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006648:	0001f797          	auipc	a5,0x1f
    8000664c:	9b878793          	addi	a5,a5,-1608 # 80025000 <disk+0x2000>
    80006650:	6b94                	ld	a3,16(a5)
    80006652:	0207d703          	lhu	a4,32(a5)
    80006656:	0026d783          	lhu	a5,2(a3)
    8000665a:	06f70163          	beq	a4,a5,800066bc <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000665e:	0001d917          	auipc	s2,0x1d
    80006662:	9a290913          	addi	s2,s2,-1630 # 80023000 <disk>
    80006666:	0001f497          	auipc	s1,0x1f
    8000666a:	99a48493          	addi	s1,s1,-1638 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000666e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006672:	6898                	ld	a4,16(s1)
    80006674:	0204d783          	lhu	a5,32(s1)
    80006678:	8b9d                	andi	a5,a5,7
    8000667a:	078e                	slli	a5,a5,0x3
    8000667c:	97ba                	add	a5,a5,a4
    8000667e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006680:	20078713          	addi	a4,a5,512
    80006684:	0712                	slli	a4,a4,0x4
    80006686:	974a                	add	a4,a4,s2
    80006688:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000668c:	e731                	bnez	a4,800066d8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000668e:	20078793          	addi	a5,a5,512
    80006692:	0792                	slli	a5,a5,0x4
    80006694:	97ca                	add	a5,a5,s2
    80006696:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006698:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000669c:	ffffc097          	auipc	ra,0xffffc
    800066a0:	cde080e7          	jalr	-802(ra) # 8000237a <wakeup>

    disk.used_idx += 1;
    800066a4:	0204d783          	lhu	a5,32(s1)
    800066a8:	2785                	addiw	a5,a5,1
    800066aa:	17c2                	slli	a5,a5,0x30
    800066ac:	93c1                	srli	a5,a5,0x30
    800066ae:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066b2:	6898                	ld	a4,16(s1)
    800066b4:	00275703          	lhu	a4,2(a4)
    800066b8:	faf71be3          	bne	a4,a5,8000666e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800066bc:	0001f517          	auipc	a0,0x1f
    800066c0:	a6c50513          	addi	a0,a0,-1428 # 80025128 <disk+0x2128>
    800066c4:	ffffa097          	auipc	ra,0xffffa
    800066c8:	5b2080e7          	jalr	1458(ra) # 80000c76 <release>
}
    800066cc:	60e2                	ld	ra,24(sp)
    800066ce:	6442                	ld	s0,16(sp)
    800066d0:	64a2                	ld	s1,8(sp)
    800066d2:	6902                	ld	s2,0(sp)
    800066d4:	6105                	addi	sp,sp,32
    800066d6:	8082                	ret
      panic("virtio_disk_intr status");
    800066d8:	00002517          	auipc	a0,0x2
    800066dc:	35050513          	addi	a0,a0,848 # 80008a28 <syscalls+0x3c0>
    800066e0:	ffffa097          	auipc	ra,0xffffa
    800066e4:	e4a080e7          	jalr	-438(ra) # 8000052a <panic>
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
