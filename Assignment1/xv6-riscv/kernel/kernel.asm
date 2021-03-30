
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
    80000068:	1ec78793          	addi	a5,a5,492 # 80006250 <timervec>
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
    80000122:	5c8080e7          	jalr	1480(ra) # 800026e6 <either_copyin>
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
    800001c6:	120080e7          	jalr	288(ra) # 800022e2 <sleep>
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
    80000202:	492080e7          	jalr	1170(ra) # 80002690 <either_copyout>
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
    800002e2:	45e080e7          	jalr	1118(ra) # 8000273c <procdump>
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
    80000436:	03c080e7          	jalr	60(ra) # 8000246e <wakeup>
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
    8000055c:	ce050513          	addi	a0,a0,-800 # 80008238 <digits+0x1f8>
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
    80000882:	bf0080e7          	jalr	-1040(ra) # 8000246e <wakeup>
    
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
    8000090e:	9d8080e7          	jalr	-1576(ra) # 800022e2 <sleep>
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
    80000eb6:	cb2080e7          	jalr	-846(ra) # 80002b64 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	3d6080e7          	jalr	982(ra) # 80006290 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	2f0080e7          	jalr	752(ra) # 800021b2 <scheduler>
    consoleinit();
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	572080e7          	jalr	1394(ra) # 8000043c <consoleinit>
    printfinit();
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	882080e7          	jalr	-1918(ra) # 80000754 <printfinit>
    printf("\n");
    80000eda:	00007517          	auipc	a0,0x7
    80000ede:	35e50513          	addi	a0,a0,862 # 80008238 <digits+0x1f8>
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	692080e7          	jalr	1682(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000eea:	00007517          	auipc	a0,0x7
    80000eee:	1b650513          	addi	a0,a0,438 # 800080a0 <digits+0x60>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("\n");
    80000efa:	00007517          	auipc	a0,0x7
    80000efe:	33e50513          	addi	a0,a0,830 # 80008238 <digits+0x1f8>
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
    80000f2e:	c12080e7          	jalr	-1006(ra) # 80002b3c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	c32080e7          	jalr	-974(ra) # 80002b64 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	340080e7          	jalr	832(ra) # 8000627a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	34e080e7          	jalr	846(ra) # 80006290 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	512080e7          	jalr	1298(ra) # 8000345c <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	ba4080e7          	jalr	-1116(ra) # 80003af6 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	b52080e7          	jalr	-1198(ra) # 80004aac <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	450080e7          	jalr	1104(ra) # 800063b2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	d4e080e7          	jalr	-690(ra) # 80001cb8 <userinit>
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
    8000182e:	20e48493          	addi	s1,s1,526 # 80008a38 <TURN>
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
    80001a16:	01e7a783          	lw	a5,30(a5) # 80008a30 <first.1>
    80001a1a:	eb89                	bnez	a5,80001a2c <forkret+0x32>
		// be run from main().
		first = 0;
		fsinit(ROOTDEV);
	}

	usertrapret();
    80001a1c:	00001097          	auipc	ra,0x1
    80001a20:	160080e7          	jalr	352(ra) # 80002b7c <usertrapret>
}
    80001a24:	60a2                	ld	ra,8(sp)
    80001a26:	6402                	ld	s0,0(sp)
    80001a28:	0141                	addi	sp,sp,16
    80001a2a:	8082                	ret
		first = 0;
    80001a2c:	00007797          	auipc	a5,0x7
    80001a30:	0007a223          	sw	zero,4(a5) # 80008a30 <first.1>
		fsinit(ROOTDEV);
    80001a34:	4505                	li	a0,1
    80001a36:	00002097          	auipc	ra,0x2
    80001a3a:	040080e7          	jalr	64(ra) # 80003a76 <fsinit>
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
    80001a62:	fd678793          	addi	a5,a5,-42 # 80008a34 <nextpid>
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
    80001c0a:	a885                	j	80001c7a <allocproc+0xae>
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
	p->performance.average_bursttime = QUANTUM * 100; // TODO: can't work with float in this OS
    80001c32:	1f400793          	li	a5,500
    80001c36:	c4fc                	sw	a5,76(s1)
	if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	e9a080e7          	jalr	-358(ra) # 80000ad2 <kalloc>
    80001c40:	892a                	mv	s2,a0
    80001c42:	fca8                	sd	a0,120(s1)
    80001c44:	c131                	beqz	a0,80001c88 <allocproc+0xbc>
	p->pagetable = proc_pagetable(p);
    80001c46:	8526                	mv	a0,s1
    80001c48:	00000097          	auipc	ra,0x0
    80001c4c:	e3e080e7          	jalr	-450(ra) # 80001a86 <proc_pagetable>
    80001c50:	892a                	mv	s2,a0
    80001c52:	f8a8                	sd	a0,112(s1)
	if (p->pagetable == 0)
    80001c54:	c531                	beqz	a0,80001ca0 <allocproc+0xd4>
	memset(&p->context, 0, sizeof(p->context));
    80001c56:	07000613          	li	a2,112
    80001c5a:	4581                	li	a1,0
    80001c5c:	08048513          	addi	a0,s1,128
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	05e080e7          	jalr	94(ra) # 80000cbe <memset>
	p->context.ra = (uint64)forkret;
    80001c68:	00000797          	auipc	a5,0x0
    80001c6c:	d9278793          	addi	a5,a5,-622 # 800019fa <forkret>
    80001c70:	e0dc                	sd	a5,128(s1)
	p->context.sp = p->kstack + PGSIZE;
    80001c72:	70bc                	ld	a5,96(s1)
    80001c74:	6705                	lui	a4,0x1
    80001c76:	97ba                	add	a5,a5,a4
    80001c78:	e4dc                	sd	a5,136(s1)
}
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	60e2                	ld	ra,24(sp)
    80001c7e:	6442                	ld	s0,16(sp)
    80001c80:	64a2                	ld	s1,8(sp)
    80001c82:	6902                	ld	s2,0(sp)
    80001c84:	6105                	addi	sp,sp,32
    80001c86:	8082                	ret
		freeproc(p);
    80001c88:	8526                	mv	a0,s1
    80001c8a:	00000097          	auipc	ra,0x0
    80001c8e:	eea080e7          	jalr	-278(ra) # 80001b74 <freeproc>
		release(&p->lock);
    80001c92:	8526                	mv	a0,s1
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	fe2080e7          	jalr	-30(ra) # 80000c76 <release>
		return 0;
    80001c9c:	84ca                	mv	s1,s2
    80001c9e:	bff1                	j	80001c7a <allocproc+0xae>
		freeproc(p);
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	ed2080e7          	jalr	-302(ra) # 80001b74 <freeproc>
		release(&p->lock);
    80001caa:	8526                	mv	a0,s1
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	fca080e7          	jalr	-54(ra) # 80000c76 <release>
		return 0;
    80001cb4:	84ca                	mv	s1,s2
    80001cb6:	b7d1                	j	80001c7a <allocproc+0xae>

0000000080001cb8 <userinit>:
{
    80001cb8:	1101                	addi	sp,sp,-32
    80001cba:	ec06                	sd	ra,24(sp)
    80001cbc:	e822                	sd	s0,16(sp)
    80001cbe:	e426                	sd	s1,8(sp)
    80001cc0:	1000                	addi	s0,sp,32
	p = allocproc();
    80001cc2:	00000097          	auipc	ra,0x0
    80001cc6:	f0a080e7          	jalr	-246(ra) # 80001bcc <allocproc>
    80001cca:	84aa                	mv	s1,a0
	initproc = p;
    80001ccc:	00007797          	auipc	a5,0x7
    80001cd0:	34a7be23          	sd	a0,860(a5) # 80009028 <initproc>
	uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cd4:	03400613          	li	a2,52
    80001cd8:	00007597          	auipc	a1,0x7
    80001cdc:	d6858593          	addi	a1,a1,-664 # 80008a40 <initcode>
    80001ce0:	7928                	ld	a0,112(a0)
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	652080e7          	jalr	1618(ra) # 80001334 <uvminit>
	p->sz = PGSIZE;
    80001cea:	6785                	lui	a5,0x1
    80001cec:	f4bc                	sd	a5,104(s1)
	p->trapframe->epc = 0;	   // user program counter
    80001cee:	7cb8                	ld	a4,120(s1)
    80001cf0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
	p->trapframe->sp = PGSIZE; // user stack pointer
    80001cf4:	7cb8                	ld	a4,120(s1)
    80001cf6:	fb1c                	sd	a5,48(a4)
	safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf8:	4641                	li	a2,16
    80001cfa:	00006597          	auipc	a1,0x6
    80001cfe:	4ee58593          	addi	a1,a1,1262 # 800081e8 <digits+0x1a8>
    80001d02:	17848513          	addi	a0,s1,376
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	10a080e7          	jalr	266(ra) # 80000e10 <safestrcpy>
	p->cwd = namei("/");
    80001d0e:	00006517          	auipc	a0,0x6
    80001d12:	4ea50513          	addi	a0,a0,1258 # 800081f8 <digits+0x1b8>
    80001d16:	00002097          	auipc	ra,0x2
    80001d1a:	78e080e7          	jalr	1934(ra) # 800044a4 <namei>
    80001d1e:	16a4b823          	sd	a0,368(s1)
	p->state = RUNNABLE;
    80001d22:	478d                	li	a5,3
    80001d24:	cc9c                	sw	a5,24(s1)
	release(&p->lock);
    80001d26:	8526                	mv	a0,s1
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	f4e080e7          	jalr	-178(ra) # 80000c76 <release>
}
    80001d30:	60e2                	ld	ra,24(sp)
    80001d32:	6442                	ld	s0,16(sp)
    80001d34:	64a2                	ld	s1,8(sp)
    80001d36:	6105                	addi	sp,sp,32
    80001d38:	8082                	ret

0000000080001d3a <growproc>:
{
    80001d3a:	1101                	addi	sp,sp,-32
    80001d3c:	ec06                	sd	ra,24(sp)
    80001d3e:	e822                	sd	s0,16(sp)
    80001d40:	e426                	sd	s1,8(sp)
    80001d42:	e04a                	sd	s2,0(sp)
    80001d44:	1000                	addi	s0,sp,32
    80001d46:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    80001d48:	00000097          	auipc	ra,0x0
    80001d4c:	c7a080e7          	jalr	-902(ra) # 800019c2 <myproc>
    80001d50:	892a                	mv	s2,a0
	sz = p->sz;
    80001d52:	752c                	ld	a1,104(a0)
    80001d54:	0005861b          	sext.w	a2,a1
	if (n > 0)
    80001d58:	00904f63          	bgtz	s1,80001d76 <growproc+0x3c>
	else if (n < 0)
    80001d5c:	0204cc63          	bltz	s1,80001d94 <growproc+0x5a>
	p->sz = sz;
    80001d60:	1602                	slli	a2,a2,0x20
    80001d62:	9201                	srli	a2,a2,0x20
    80001d64:	06c93423          	sd	a2,104(s2)
	return 0;
    80001d68:	4501                	li	a0,0
}
    80001d6a:	60e2                	ld	ra,24(sp)
    80001d6c:	6442                	ld	s0,16(sp)
    80001d6e:	64a2                	ld	s1,8(sp)
    80001d70:	6902                	ld	s2,0(sp)
    80001d72:	6105                	addi	sp,sp,32
    80001d74:	8082                	ret
		if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001d76:	9e25                	addw	a2,a2,s1
    80001d78:	1602                	slli	a2,a2,0x20
    80001d7a:	9201                	srli	a2,a2,0x20
    80001d7c:	1582                	slli	a1,a1,0x20
    80001d7e:	9181                	srli	a1,a1,0x20
    80001d80:	7928                	ld	a0,112(a0)
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	66c080e7          	jalr	1644(ra) # 800013ee <uvmalloc>
    80001d8a:	0005061b          	sext.w	a2,a0
    80001d8e:	fa69                	bnez	a2,80001d60 <growproc+0x26>
			return -1;
    80001d90:	557d                	li	a0,-1
    80001d92:	bfe1                	j	80001d6a <growproc+0x30>
		sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d94:	9e25                	addw	a2,a2,s1
    80001d96:	1602                	slli	a2,a2,0x20
    80001d98:	9201                	srli	a2,a2,0x20
    80001d9a:	1582                	slli	a1,a1,0x20
    80001d9c:	9181                	srli	a1,a1,0x20
    80001d9e:	7928                	ld	a0,112(a0)
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	606080e7          	jalr	1542(ra) # 800013a6 <uvmdealloc>
    80001da8:	0005061b          	sext.w	a2,a0
    80001dac:	bf55                	j	80001d60 <growproc+0x26>

0000000080001dae <fork>:
{
    80001dae:	7139                	addi	sp,sp,-64
    80001db0:	fc06                	sd	ra,56(sp)
    80001db2:	f822                	sd	s0,48(sp)
    80001db4:	f426                	sd	s1,40(sp)
    80001db6:	f04a                	sd	s2,32(sp)
    80001db8:	ec4e                	sd	s3,24(sp)
    80001dba:	e852                	sd	s4,16(sp)
    80001dbc:	e456                	sd	s5,8(sp)
    80001dbe:	0080                	addi	s0,sp,64
	struct proc *p = myproc();
    80001dc0:	00000097          	auipc	ra,0x0
    80001dc4:	c02080e7          	jalr	-1022(ra) # 800019c2 <myproc>
    80001dc8:	8aaa                	mv	s5,a0
	if ((np = allocproc()) == 0)
    80001dca:	00000097          	auipc	ra,0x0
    80001dce:	e02080e7          	jalr	-510(ra) # 80001bcc <allocproc>
    80001dd2:	12050063          	beqz	a0,80001ef2 <fork+0x144>
    80001dd6:	89aa                	mv	s3,a0
	if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dd8:	068ab603          	ld	a2,104(s5)
    80001ddc:	792c                	ld	a1,112(a0)
    80001dde:	070ab503          	ld	a0,112(s5)
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	758080e7          	jalr	1880(ra) # 8000153a <uvmcopy>
    80001dea:	04054863          	bltz	a0,80001e3a <fork+0x8c>
	np->sz = p->sz;
    80001dee:	068ab783          	ld	a5,104(s5)
    80001df2:	06f9b423          	sd	a5,104(s3)
	*(np->trapframe) = *(p->trapframe);
    80001df6:	078ab683          	ld	a3,120(s5)
    80001dfa:	87b6                	mv	a5,a3
    80001dfc:	0789b703          	ld	a4,120(s3)
    80001e00:	12068693          	addi	a3,a3,288
    80001e04:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e08:	6788                	ld	a0,8(a5)
    80001e0a:	6b8c                	ld	a1,16(a5)
    80001e0c:	6f90                	ld	a2,24(a5)
    80001e0e:	01073023          	sd	a6,0(a4)
    80001e12:	e708                	sd	a0,8(a4)
    80001e14:	eb0c                	sd	a1,16(a4)
    80001e16:	ef10                	sd	a2,24(a4)
    80001e18:	02078793          	addi	a5,a5,32
    80001e1c:	02070713          	addi	a4,a4,32
    80001e20:	fed792e3          	bne	a5,a3,80001e04 <fork+0x56>
	np->trapframe->a0 = 0;
    80001e24:	0789b783          	ld	a5,120(s3)
    80001e28:	0607b823          	sd	zero,112(a5)
	for (i = 0; i < NOFILE; i++)
    80001e2c:	0f0a8493          	addi	s1,s5,240
    80001e30:	0f098913          	addi	s2,s3,240
    80001e34:	170a8a13          	addi	s4,s5,368
    80001e38:	a00d                	j	80001e5a <fork+0xac>
		freeproc(np);
    80001e3a:	854e                	mv	a0,s3
    80001e3c:	00000097          	auipc	ra,0x0
    80001e40:	d38080e7          	jalr	-712(ra) # 80001b74 <freeproc>
		release(&np->lock);
    80001e44:	854e                	mv	a0,s3
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	e30080e7          	jalr	-464(ra) # 80000c76 <release>
		return -1;
    80001e4e:	597d                	li	s2,-1
    80001e50:	a079                	j	80001ede <fork+0x130>
	for (i = 0; i < NOFILE; i++)
    80001e52:	04a1                	addi	s1,s1,8
    80001e54:	0921                	addi	s2,s2,8
    80001e56:	01448b63          	beq	s1,s4,80001e6c <fork+0xbe>
		if (p->ofile[i])
    80001e5a:	6088                	ld	a0,0(s1)
    80001e5c:	d97d                	beqz	a0,80001e52 <fork+0xa4>
			np->ofile[i] = filedup(p->ofile[i]);
    80001e5e:	00003097          	auipc	ra,0x3
    80001e62:	ce0080e7          	jalr	-800(ra) # 80004b3e <filedup>
    80001e66:	00a93023          	sd	a0,0(s2)
    80001e6a:	b7e5                	j	80001e52 <fork+0xa4>
	np->cwd = idup(p->cwd);
    80001e6c:	170ab503          	ld	a0,368(s5)
    80001e70:	00002097          	auipc	ra,0x2
    80001e74:	e40080e7          	jalr	-448(ra) # 80003cb0 <idup>
    80001e78:	16a9b823          	sd	a0,368(s3)
	safestrcpy(np->name, p->name, sizeof(p->name));
    80001e7c:	4641                	li	a2,16
    80001e7e:	178a8593          	addi	a1,s5,376
    80001e82:	17898513          	addi	a0,s3,376
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	f8a080e7          	jalr	-118(ra) # 80000e10 <safestrcpy>
	pid = np->pid;
    80001e8e:	0309a903          	lw	s2,48(s3)
	release(&np->lock);
    80001e92:	854e                	mv	a0,s3
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	de2080e7          	jalr	-542(ra) # 80000c76 <release>
	acquire(&wait_lock);
    80001e9c:	0000f497          	auipc	s1,0xf
    80001ea0:	43448493          	addi	s1,s1,1076 # 800112d0 <wait_lock>
    80001ea4:	8526                	mv	a0,s1
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	d1c080e7          	jalr	-740(ra) # 80000bc2 <acquire>
	np->parent = p;
    80001eae:	0559bc23          	sd	s5,88(s3)
	np->trace_mask = p->trace_mask; // ADDED
    80001eb2:	034aa783          	lw	a5,52(s5)
    80001eb6:	02f9aa23          	sw	a5,52(s3)
	release(&wait_lock);
    80001eba:	8526                	mv	a0,s1
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	dba080e7          	jalr	-582(ra) # 80000c76 <release>
	acquire(&np->lock);
    80001ec4:	854e                	mv	a0,s3
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	cfc080e7          	jalr	-772(ra) # 80000bc2 <acquire>
	np->state = RUNNABLE;
    80001ece:	478d                	li	a5,3
    80001ed0:	00f9ac23          	sw	a5,24(s3)
	release(&np->lock);
    80001ed4:	854e                	mv	a0,s3
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	da0080e7          	jalr	-608(ra) # 80000c76 <release>
}
    80001ede:	854a                	mv	a0,s2
    80001ee0:	70e2                	ld	ra,56(sp)
    80001ee2:	7442                	ld	s0,48(sp)
    80001ee4:	74a2                	ld	s1,40(sp)
    80001ee6:	7902                	ld	s2,32(sp)
    80001ee8:	69e2                	ld	s3,24(sp)
    80001eea:	6a42                	ld	s4,16(sp)
    80001eec:	6aa2                	ld	s5,8(sp)
    80001eee:	6121                	addi	sp,sp,64
    80001ef0:	8082                	ret
		return -1;
    80001ef2:	597d                	li	s2,-1
    80001ef4:	b7ed                	j	80001ede <fork+0x130>

0000000080001ef6 <sched_default>:
{
    80001ef6:	7139                	addi	sp,sp,-64
    80001ef8:	fc06                	sd	ra,56(sp)
    80001efa:	f822                	sd	s0,48(sp)
    80001efc:	f426                	sd	s1,40(sp)
    80001efe:	f04a                	sd	s2,32(sp)
    80001f00:	ec4e                	sd	s3,24(sp)
    80001f02:	e852                	sd	s4,16(sp)
    80001f04:	e456                	sd	s5,8(sp)
    80001f06:	e05a                	sd	s6,0(sp)
    80001f08:	0080                	addi	s0,sp,64
    80001f0a:	8792                	mv	a5,tp
	int id = r_tp();
    80001f0c:	2781                	sext.w	a5,a5
	c->proc = 0;
    80001f0e:	00779a93          	slli	s5,a5,0x7
    80001f12:	0000f717          	auipc	a4,0xf
    80001f16:	38e70713          	addi	a4,a4,910 # 800112a0 <TURNLOCK>
    80001f1a:	9756                	add	a4,a4,s5
    80001f1c:	04073423          	sd	zero,72(a4)
			swtch(&c->context, &p->context);
    80001f20:	0000f717          	auipc	a4,0xf
    80001f24:	3d070713          	addi	a4,a4,976 # 800112f0 <cpus+0x8>
    80001f28:	9aba                	add	s5,s5,a4
	for (p = proc; p < &proc[NPROC]; p++)
    80001f2a:	0000f497          	auipc	s1,0xf
    80001f2e:	7be48493          	addi	s1,s1,1982 # 800116e8 <proc>
		if (p->state == RUNNABLE)
    80001f32:	498d                	li	s3,3
			p->state = RUNNING;
    80001f34:	4b11                	li	s6,4
			c->proc = p;
    80001f36:	079e                	slli	a5,a5,0x7
    80001f38:	0000fa17          	auipc	s4,0xf
    80001f3c:	368a0a13          	addi	s4,s4,872 # 800112a0 <TURNLOCK>
    80001f40:	9a3e                	add	s4,s4,a5
	for (p = proc; p < &proc[NPROC]; p++)
    80001f42:	00016917          	auipc	s2,0x16
    80001f46:	9a690913          	addi	s2,s2,-1626 # 800178e8 <tickslock>
    80001f4a:	a811                	j	80001f5e <sched_default+0x68>
		release(&p->lock);
    80001f4c:	8526                	mv	a0,s1
    80001f4e:	fffff097          	auipc	ra,0xfffff
    80001f52:	d28080e7          	jalr	-728(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80001f56:	18848493          	addi	s1,s1,392
    80001f5a:	03248863          	beq	s1,s2,80001f8a <sched_default+0x94>
		acquire(&p->lock);
    80001f5e:	8526                	mv	a0,s1
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	c62080e7          	jalr	-926(ra) # 80000bc2 <acquire>
		if (p->state == RUNNABLE)
    80001f68:	4c9c                	lw	a5,24(s1)
    80001f6a:	ff3791e3          	bne	a5,s3,80001f4c <sched_default+0x56>
			p->state = RUNNING;
    80001f6e:	0164ac23          	sw	s6,24(s1)
			c->proc = p;
    80001f72:	049a3423          	sd	s1,72(s4)
			swtch(&c->context, &p->context);
    80001f76:	08048593          	addi	a1,s1,128
    80001f7a:	8556                	mv	a0,s5
    80001f7c:	00001097          	auipc	ra,0x1
    80001f80:	b56080e7          	jalr	-1194(ra) # 80002ad2 <swtch>
			c->proc = 0;
    80001f84:	040a3423          	sd	zero,72(s4)
    80001f88:	b7d1                	j	80001f4c <sched_default+0x56>
}
    80001f8a:	70e2                	ld	ra,56(sp)
    80001f8c:	7442                	ld	s0,48(sp)
    80001f8e:	74a2                	ld	s1,40(sp)
    80001f90:	7902                	ld	s2,32(sp)
    80001f92:	69e2                	ld	s3,24(sp)
    80001f94:	6a42                	ld	s4,16(sp)
    80001f96:	6aa2                	ld	s5,8(sp)
    80001f98:	6b02                	ld	s6,0(sp)
    80001f9a:	6121                	addi	sp,sp,64
    80001f9c:	8082                	ret

0000000080001f9e <sched_fcfs>:
{
    80001f9e:	715d                	addi	sp,sp,-80
    80001fa0:	e486                	sd	ra,72(sp)
    80001fa2:	e0a2                	sd	s0,64(sp)
    80001fa4:	fc26                	sd	s1,56(sp)
    80001fa6:	f84a                	sd	s2,48(sp)
    80001fa8:	f44e                	sd	s3,40(sp)
    80001faa:	f052                	sd	s4,32(sp)
    80001fac:	ec56                	sd	s5,24(sp)
    80001fae:	e85a                	sd	s6,16(sp)
    80001fb0:	e45e                	sd	s7,8(sp)
    80001fb2:	0880                	addi	s0,sp,80
    80001fb4:	8b92                	mv	s7,tp
	int id = r_tp();
    80001fb6:	2b81                	sext.w	s7,s7
	c->proc = 0;
    80001fb8:	007b9713          	slli	a4,s7,0x7
    80001fbc:	0000f797          	auipc	a5,0xf
    80001fc0:	2e478793          	addi	a5,a5,740 # 800112a0 <TURNLOCK>
    80001fc4:	97ba                	add	a5,a5,a4
    80001fc6:	0407b423          	sd	zero,72(a5)
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80001fca:	4901                	li	s2,0
	int proc_to_run_index = 0;
    80001fcc:	4b01                	li	s6,0
	uint first_turn = 4294967295;
    80001fce:	5afd                	li	s5,-1
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80001fd0:	0000f497          	auipc	s1,0xf
    80001fd4:	71848493          	addi	s1,s1,1816 # 800116e8 <proc>
		if (p->state == RUNNABLE && p->turn < first_turn)
    80001fd8:	4a0d                	li	s4,3
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80001fda:	00016997          	auipc	s3,0x16
    80001fde:	90e98993          	addi	s3,s3,-1778 # 800178e8 <tickslock>
    80001fe2:	a819                	j	80001ff8 <sched_fcfs+0x5a>
		release(&p->lock);
    80001fe4:	8526                	mv	a0,s1
    80001fe6:	fffff097          	auipc	ra,0xfffff
    80001fea:	c90080e7          	jalr	-880(ra) # 80000c76 <release>
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80001fee:	18848493          	addi	s1,s1,392
    80001ff2:	2905                	addiw	s2,s2,1
    80001ff4:	03348063          	beq	s1,s3,80002014 <sched_fcfs+0x76>
		acquire(&p->lock);
    80001ff8:	8526                	mv	a0,s1
    80001ffa:	fffff097          	auipc	ra,0xfffff
    80001ffe:	bc8080e7          	jalr	-1080(ra) # 80000bc2 <acquire>
		if (p->state == RUNNABLE && p->turn < first_turn)
    80002002:	4c9c                	lw	a5,24(s1)
    80002004:	ff4790e3          	bne	a5,s4,80001fe4 <sched_fcfs+0x46>
    80002008:	48bc                	lw	a5,80(s1)
    8000200a:	fd57fde3          	bgeu	a5,s5,80001fe4 <sched_fcfs+0x46>
    8000200e:	8b4a                	mv	s6,s2
			first_turn = p->turn;
    80002010:	8abe                	mv	s5,a5
    80002012:	bfc9                	j	80001fe4 <sched_fcfs+0x46>
	first = &proc[proc_to_run_index];
    80002014:	18800793          	li	a5,392
    80002018:	02fb0933          	mul	s2,s6,a5
    8000201c:	0000f497          	auipc	s1,0xf
    80002020:	6cc48493          	addi	s1,s1,1740 # 800116e8 <proc>
    80002024:	94ca                	add	s1,s1,s2
	acquire(&first->lock);
    80002026:	8526                	mv	a0,s1
    80002028:	fffff097          	auipc	ra,0xfffff
    8000202c:	b9a080e7          	jalr	-1126(ra) # 80000bc2 <acquire>
	if (first->state == RUNNABLE)
    80002030:	4c98                	lw	a4,24(s1)
    80002032:	478d                	li	a5,3
    80002034:	02f70263          	beq	a4,a5,80002058 <sched_fcfs+0xba>
	release(&first->lock);
    80002038:	8526                	mv	a0,s1
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	c3c080e7          	jalr	-964(ra) # 80000c76 <release>
}
    80002042:	60a6                	ld	ra,72(sp)
    80002044:	6406                	ld	s0,64(sp)
    80002046:	74e2                	ld	s1,56(sp)
    80002048:	7942                	ld	s2,48(sp)
    8000204a:	79a2                	ld	s3,40(sp)
    8000204c:	7a02                	ld	s4,32(sp)
    8000204e:	6ae2                	ld	s5,24(sp)
    80002050:	6b42                	ld	s6,16(sp)
    80002052:	6ba2                	ld	s7,8(sp)
    80002054:	6161                	addi	sp,sp,80
    80002056:	8082                	ret
		first->state = RUNNING;
    80002058:	0000f597          	auipc	a1,0xf
    8000205c:	69058593          	addi	a1,a1,1680 # 800116e8 <proc>
    80002060:	4711                	li	a4,4
    80002062:	cc98                	sw	a4,24(s1)
		c->proc = first;
    80002064:	0b9e                	slli	s7,s7,0x7
    80002066:	0000f997          	auipc	s3,0xf
    8000206a:	23a98993          	addi	s3,s3,570 # 800112a0 <TURNLOCK>
    8000206e:	99de                	add	s3,s3,s7
    80002070:	0499b423          	sd	s1,72(s3)
		swtch(&c->context, &first->context);
    80002074:	08090913          	addi	s2,s2,128
    80002078:	95ca                	add	a1,a1,s2
    8000207a:	0000f517          	auipc	a0,0xf
    8000207e:	27650513          	addi	a0,a0,630 # 800112f0 <cpus+0x8>
    80002082:	955e                	add	a0,a0,s7
    80002084:	00001097          	auipc	ra,0x1
    80002088:	a4e080e7          	jalr	-1458(ra) # 80002ad2 <swtch>
		c->proc = 0;
    8000208c:	0409b423          	sd	zero,72(s3)
    80002090:	b765                	j	80002038 <sched_fcfs+0x9a>

0000000080002092 <sched_srt>:
{
    80002092:	7159                	addi	sp,sp,-112
    80002094:	f486                	sd	ra,104(sp)
    80002096:	f0a2                	sd	s0,96(sp)
    80002098:	eca6                	sd	s1,88(sp)
    8000209a:	e8ca                	sd	s2,80(sp)
    8000209c:	e4ce                	sd	s3,72(sp)
    8000209e:	e0d2                	sd	s4,64(sp)
    800020a0:	fc56                	sd	s5,56(sp)
    800020a2:	f85a                	sd	s6,48(sp)
    800020a4:	f45e                	sd	s7,40(sp)
    800020a6:	f062                	sd	s8,32(sp)
    800020a8:	ec66                	sd	s9,24(sp)
    800020aa:	e86a                	sd	s10,16(sp)
    800020ac:	e46e                	sd	s11,8(sp)
    800020ae:	1880                	addi	s0,sp,112
    800020b0:	8792                	mv	a5,tp
	int id = r_tp();
    800020b2:	2781                	sext.w	a5,a5
	c->proc = 0;
    800020b4:	00779b93          	slli	s7,a5,0x7
    800020b8:	0000f717          	auipc	a4,0xf
    800020bc:	1e870713          	addi	a4,a4,488 # 800112a0 <TURNLOCK>
    800020c0:	975e                	add	a4,a4,s7
    800020c2:	04073423          	sd	zero,72(a4)
			swtch(&c->context, &p->context);
    800020c6:	0000f717          	auipc	a4,0xf
    800020ca:	22a70713          	addi	a4,a4,554 # 800112f0 <cpus+0x8>
    800020ce:	9bba                	add	s7,s7,a4
	for (p = proc; p < &proc[NPROC]; p++)
    800020d0:	0000f497          	auipc	s1,0xf
    800020d4:	61848493          	addi	s1,s1,1560 # 800116e8 <proc>
		if (p->state == RUNNABLE)
    800020d8:	4a0d                	li	s4,3
			p->state = RUNNING;
    800020da:	4c91                	li	s9,4
			c->proc = p;
    800020dc:	079e                	slli	a5,a5,0x7
    800020de:	0000fa97          	auipc	s5,0xf
    800020e2:	1c2a8a93          	addi	s5,s5,450 # 800112a0 <TURNLOCK>
    800020e6:	9abe                	add	s5,s5,a5
			uint prev_ticks = ticks;
    800020e8:	00007b17          	auipc	s6,0x7
    800020ec:	f48b0b13          	addi	s6,s6,-184 # 80009030 <ticks>
			printf("PID: %d BEFORE: B:%d A:%d\n",p->pid,B,A);
    800020f0:	00006c17          	auipc	s8,0x6
    800020f4:	110c0c13          	addi	s8,s8,272 # 80008200 <digits+0x1c0>
	for (p = proc; p < &proc[NPROC]; p++)
    800020f8:	00015997          	auipc	s3,0x15
    800020fc:	7f098993          	addi	s3,s3,2032 # 800178e8 <tickslock>
    80002100:	a811                	j	80002114 <sched_srt+0x82>
		release(&p->lock);
    80002102:	8526                	mv	a0,s1
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	b72080e7          	jalr	-1166(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    8000210c:	18848493          	addi	s1,s1,392
    80002110:	09348263          	beq	s1,s3,80002194 <sched_srt+0x102>
		acquire(&p->lock);
    80002114:	8526                	mv	a0,s1
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	aac080e7          	jalr	-1364(ra) # 80000bc2 <acquire>
		if (p->state == RUNNABLE)
    8000211e:	4c9c                	lw	a5,24(s1)
    80002120:	ff4791e3          	bne	a5,s4,80002102 <sched_srt+0x70>
			p->state = RUNNING;
    80002124:	0194ac23          	sw	s9,24(s1)
			c->proc = p;
    80002128:	049ab423          	sd	s1,72(s5)
			uint prev_ticks = ticks;
    8000212c:	000b2903          	lw	s2,0(s6)
			swtch(&c->context, &p->context);
    80002130:	08048593          	addi	a1,s1,128
    80002134:	855e                	mv	a0,s7
    80002136:	00001097          	auipc	ra,0x1
    8000213a:	99c080e7          	jalr	-1636(ra) # 80002ad2 <swtch>
			uint B = ticks - prev_ticks;
    8000213e:	000b2d83          	lw	s11,0(s6)
    80002142:	412d8dbb          	subw	s11,s11,s2
    80002146:	000d8d1b          	sext.w	s10,s11
			uint A = p->performance.average_bursttime;
    8000214a:	04c4a903          	lw	s2,76(s1)
			printf("PID: %d BEFORE: B:%d A:%d\n",p->pid,B,A);
    8000214e:	86ca                	mv	a3,s2
    80002150:	866a                	mv	a2,s10
    80002152:	588c                	lw	a1,48(s1)
    80002154:	8562                	mv	a0,s8
    80002156:	ffffe097          	auipc	ra,0xffffe
    8000215a:	41e080e7          	jalr	1054(ra) # 80000574 <printf>
			A = ALPHA * B + (100 - ALPHA) * A / 100;
    8000215e:	03200793          	li	a5,50
    80002162:	0327893b          	mulw	s2,a5,s2
    80002166:	06400693          	li	a3,100
    8000216a:	02d9593b          	divuw	s2,s2,a3
    8000216e:	03b786bb          	mulw	a3,a5,s11
    80002172:	012686bb          	addw	a3,a3,s2
			p->performance.average_bursttime = A;
    80002176:	c4f4                	sw	a3,76(s1)
			printf("PID: %d AFTER: B:%d A:%d\n",p->pid,B,A);
    80002178:	2681                	sext.w	a3,a3
    8000217a:	866a                	mv	a2,s10
    8000217c:	588c                	lw	a1,48(s1)
    8000217e:	00006517          	auipc	a0,0x6
    80002182:	0a250513          	addi	a0,a0,162 # 80008220 <digits+0x1e0>
    80002186:	ffffe097          	auipc	ra,0xffffe
    8000218a:	3ee080e7          	jalr	1006(ra) # 80000574 <printf>
			c->proc = 0;
    8000218e:	040ab423          	sd	zero,72(s5)
    80002192:	bf85                	j	80002102 <sched_srt+0x70>
}
    80002194:	70a6                	ld	ra,104(sp)
    80002196:	7406                	ld	s0,96(sp)
    80002198:	64e6                	ld	s1,88(sp)
    8000219a:	6946                	ld	s2,80(sp)
    8000219c:	69a6                	ld	s3,72(sp)
    8000219e:	6a06                	ld	s4,64(sp)
    800021a0:	7ae2                	ld	s5,56(sp)
    800021a2:	7b42                	ld	s6,48(sp)
    800021a4:	7ba2                	ld	s7,40(sp)
    800021a6:	7c02                	ld	s8,32(sp)
    800021a8:	6ce2                	ld	s9,24(sp)
    800021aa:	6d42                	ld	s10,16(sp)
    800021ac:	6da2                	ld	s11,8(sp)
    800021ae:	6165                	addi	sp,sp,112
    800021b0:	8082                	ret

00000000800021b2 <scheduler>:
{
    800021b2:	1141                	addi	sp,sp,-16
    800021b4:	e406                	sd	ra,8(sp)
    800021b6:	e022                	sd	s0,0(sp)
    800021b8:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021ba:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021be:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021c2:	10079073          	csrw	sstatus,a5
		sched_srt();
    800021c6:	00000097          	auipc	ra,0x0
    800021ca:	ecc080e7          	jalr	-308(ra) # 80002092 <sched_srt>
	for (;;)
    800021ce:	b7f5                	j	800021ba <scheduler+0x8>

00000000800021d0 <sched>:
{
    800021d0:	7179                	addi	sp,sp,-48
    800021d2:	f406                	sd	ra,40(sp)
    800021d4:	f022                	sd	s0,32(sp)
    800021d6:	ec26                	sd	s1,24(sp)
    800021d8:	e84a                	sd	s2,16(sp)
    800021da:	e44e                	sd	s3,8(sp)
    800021dc:	1800                	addi	s0,sp,48
	struct proc *p = myproc();
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	7e4080e7          	jalr	2020(ra) # 800019c2 <myproc>
    800021e6:	84aa                	mv	s1,a0
	if (!holding(&p->lock))
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	960080e7          	jalr	-1696(ra) # 80000b48 <holding>
    800021f0:	c93d                	beqz	a0,80002266 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021f2:	8792                	mv	a5,tp
	if (mycpu()->noff != 1)
    800021f4:	2781                	sext.w	a5,a5
    800021f6:	079e                	slli	a5,a5,0x7
    800021f8:	0000f717          	auipc	a4,0xf
    800021fc:	0a870713          	addi	a4,a4,168 # 800112a0 <TURNLOCK>
    80002200:	97ba                	add	a5,a5,a4
    80002202:	0c07a703          	lw	a4,192(a5)
    80002206:	4785                	li	a5,1
    80002208:	06f71763          	bne	a4,a5,80002276 <sched+0xa6>
	if (p->state == RUNNING)
    8000220c:	4c98                	lw	a4,24(s1)
    8000220e:	4791                	li	a5,4
    80002210:	06f70b63          	beq	a4,a5,80002286 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002214:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002218:	8b89                	andi	a5,a5,2
	if (intr_get())
    8000221a:	efb5                	bnez	a5,80002296 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000221c:	8792                	mv	a5,tp
	intena = mycpu()->intena;
    8000221e:	0000f917          	auipc	s2,0xf
    80002222:	08290913          	addi	s2,s2,130 # 800112a0 <TURNLOCK>
    80002226:	2781                	sext.w	a5,a5
    80002228:	079e                	slli	a5,a5,0x7
    8000222a:	97ca                	add	a5,a5,s2
    8000222c:	0c47a983          	lw	s3,196(a5)
    80002230:	8792                	mv	a5,tp
	swtch(&p->context, &mycpu()->context);
    80002232:	2781                	sext.w	a5,a5
    80002234:	079e                	slli	a5,a5,0x7
    80002236:	0000f597          	auipc	a1,0xf
    8000223a:	0ba58593          	addi	a1,a1,186 # 800112f0 <cpus+0x8>
    8000223e:	95be                	add	a1,a1,a5
    80002240:	08048513          	addi	a0,s1,128
    80002244:	00001097          	auipc	ra,0x1
    80002248:	88e080e7          	jalr	-1906(ra) # 80002ad2 <swtch>
    8000224c:	8792                	mv	a5,tp
	mycpu()->intena = intena;
    8000224e:	2781                	sext.w	a5,a5
    80002250:	079e                	slli	a5,a5,0x7
    80002252:	97ca                	add	a5,a5,s2
    80002254:	0d37a223          	sw	s3,196(a5)
}
    80002258:	70a2                	ld	ra,40(sp)
    8000225a:	7402                	ld	s0,32(sp)
    8000225c:	64e2                	ld	s1,24(sp)
    8000225e:	6942                	ld	s2,16(sp)
    80002260:	69a2                	ld	s3,8(sp)
    80002262:	6145                	addi	sp,sp,48
    80002264:	8082                	ret
		panic("sched p->lock");
    80002266:	00006517          	auipc	a0,0x6
    8000226a:	fda50513          	addi	a0,a0,-38 # 80008240 <digits+0x200>
    8000226e:	ffffe097          	auipc	ra,0xffffe
    80002272:	2bc080e7          	jalr	700(ra) # 8000052a <panic>
		panic("sched locks");
    80002276:	00006517          	auipc	a0,0x6
    8000227a:	fda50513          	addi	a0,a0,-38 # 80008250 <digits+0x210>
    8000227e:	ffffe097          	auipc	ra,0xffffe
    80002282:	2ac080e7          	jalr	684(ra) # 8000052a <panic>
		panic("sched running");
    80002286:	00006517          	auipc	a0,0x6
    8000228a:	fda50513          	addi	a0,a0,-38 # 80008260 <digits+0x220>
    8000228e:	ffffe097          	auipc	ra,0xffffe
    80002292:	29c080e7          	jalr	668(ra) # 8000052a <panic>
		panic("sched interruptible");
    80002296:	00006517          	auipc	a0,0x6
    8000229a:	fda50513          	addi	a0,a0,-38 # 80008270 <digits+0x230>
    8000229e:	ffffe097          	auipc	ra,0xffffe
    800022a2:	28c080e7          	jalr	652(ra) # 8000052a <panic>

00000000800022a6 <yield>:
{
    800022a6:	1101                	addi	sp,sp,-32
    800022a8:	ec06                	sd	ra,24(sp)
    800022aa:	e822                	sd	s0,16(sp)
    800022ac:	e426                	sd	s1,8(sp)
    800022ae:	1000                	addi	s0,sp,32
	struct proc *p = myproc();
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	712080e7          	jalr	1810(ra) # 800019c2 <myproc>
    800022b8:	84aa                	mv	s1,a0
	acquire(&p->lock);
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	908080e7          	jalr	-1784(ra) # 80000bc2 <acquire>
	p->state = RUNNABLE;
    800022c2:	478d                	li	a5,3
    800022c4:	cc9c                	sw	a5,24(s1)
	sched();
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	f0a080e7          	jalr	-246(ra) # 800021d0 <sched>
	release(&p->lock);
    800022ce:	8526                	mv	a0,s1
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	9a6080e7          	jalr	-1626(ra) # 80000c76 <release>
}
    800022d8:	60e2                	ld	ra,24(sp)
    800022da:	6442                	ld	s0,16(sp)
    800022dc:	64a2                	ld	s1,8(sp)
    800022de:	6105                	addi	sp,sp,32
    800022e0:	8082                	ret

00000000800022e2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800022e2:	7179                	addi	sp,sp,-48
    800022e4:	f406                	sd	ra,40(sp)
    800022e6:	f022                	sd	s0,32(sp)
    800022e8:	ec26                	sd	s1,24(sp)
    800022ea:	e84a                	sd	s2,16(sp)
    800022ec:	e44e                	sd	s3,8(sp)
    800022ee:	1800                	addi	s0,sp,48
    800022f0:	89aa                	mv	s3,a0
    800022f2:	892e                	mv	s2,a1
	struct proc *p = myproc();
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	6ce080e7          	jalr	1742(ra) # 800019c2 <myproc>
    800022fc:	84aa                	mv	s1,a0
	// Once we hold p->lock, we can be
	// guaranteed that we won't miss any wakeup
	// (wakeup locks p->lock),
	// so it's okay to release lk.

	acquire(&p->lock); //DOC: sleeplock1
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	8c4080e7          	jalr	-1852(ra) # 80000bc2 <acquire>
	release(lk);
    80002306:	854a                	mv	a0,s2
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	96e080e7          	jalr	-1682(ra) # 80000c76 <release>

	// Go to sleep.
	p->chan = chan;
    80002310:	0334b023          	sd	s3,32(s1)
	p->state = SLEEPING;
    80002314:	4789                	li	a5,2
    80002316:	cc9c                	sw	a5,24(s1)

	sched();
    80002318:	00000097          	auipc	ra,0x0
    8000231c:	eb8080e7          	jalr	-328(ra) # 800021d0 <sched>

	// Tidy up.
	p->chan = 0;
    80002320:	0204b023          	sd	zero,32(s1)

	// Reacquire original lock.
	release(&p->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	950080e7          	jalr	-1712(ra) # 80000c76 <release>
	acquire(lk);
    8000232e:	854a                	mv	a0,s2
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	892080e7          	jalr	-1902(ra) # 80000bc2 <acquire>
}
    80002338:	70a2                	ld	ra,40(sp)
    8000233a:	7402                	ld	s0,32(sp)
    8000233c:	64e2                	ld	s1,24(sp)
    8000233e:	6942                	ld	s2,16(sp)
    80002340:	69a2                	ld	s3,8(sp)
    80002342:	6145                	addi	sp,sp,48
    80002344:	8082                	ret

0000000080002346 <wait>:
{
    80002346:	715d                	addi	sp,sp,-80
    80002348:	e486                	sd	ra,72(sp)
    8000234a:	e0a2                	sd	s0,64(sp)
    8000234c:	fc26                	sd	s1,56(sp)
    8000234e:	f84a                	sd	s2,48(sp)
    80002350:	f44e                	sd	s3,40(sp)
    80002352:	f052                	sd	s4,32(sp)
    80002354:	ec56                	sd	s5,24(sp)
    80002356:	e85a                	sd	s6,16(sp)
    80002358:	e45e                	sd	s7,8(sp)
    8000235a:	e062                	sd	s8,0(sp)
    8000235c:	0880                	addi	s0,sp,80
    8000235e:	8b2a                	mv	s6,a0
	struct proc *p = myproc();
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	662080e7          	jalr	1634(ra) # 800019c2 <myproc>
    80002368:	892a                	mv	s2,a0
	acquire(&wait_lock);
    8000236a:	0000f517          	auipc	a0,0xf
    8000236e:	f6650513          	addi	a0,a0,-154 # 800112d0 <wait_lock>
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	850080e7          	jalr	-1968(ra) # 80000bc2 <acquire>
		havekids = 0;
    8000237a:	4b81                	li	s7,0
				if (np->state == ZOMBIE)
    8000237c:	4a15                	li	s4,5
				havekids = 1;
    8000237e:	4a85                	li	s5,1
		for (np = proc; np < &proc[NPROC]; np++)
    80002380:	00015997          	auipc	s3,0x15
    80002384:	56898993          	addi	s3,s3,1384 # 800178e8 <tickslock>
		sleep(p, &wait_lock); //DOC: wait-sleep
    80002388:	0000fc17          	auipc	s8,0xf
    8000238c:	f48c0c13          	addi	s8,s8,-184 # 800112d0 <wait_lock>
		havekids = 0;
    80002390:	875e                	mv	a4,s7
		for (np = proc; np < &proc[NPROC]; np++)
    80002392:	0000f497          	auipc	s1,0xf
    80002396:	35648493          	addi	s1,s1,854 # 800116e8 <proc>
    8000239a:	a0bd                	j	80002408 <wait+0xc2>
					pid = np->pid;
    8000239c:	0304a983          	lw	s3,48(s1)
					if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023a0:	000b0e63          	beqz	s6,800023bc <wait+0x76>
    800023a4:	4691                	li	a3,4
    800023a6:	02c48613          	addi	a2,s1,44
    800023aa:	85da                	mv	a1,s6
    800023ac:	07093503          	ld	a0,112(s2)
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	28e080e7          	jalr	654(ra) # 8000163e <copyout>
    800023b8:	02054563          	bltz	a0,800023e2 <wait+0x9c>
					freeproc(np);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	7b6080e7          	jalr	1974(ra) # 80001b74 <freeproc>
					release(&np->lock);
    800023c6:	8526                	mv	a0,s1
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	8ae080e7          	jalr	-1874(ra) # 80000c76 <release>
					release(&wait_lock);
    800023d0:	0000f517          	auipc	a0,0xf
    800023d4:	f0050513          	addi	a0,a0,-256 # 800112d0 <wait_lock>
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	89e080e7          	jalr	-1890(ra) # 80000c76 <release>
					return pid;
    800023e0:	a09d                	j	80002446 <wait+0x100>
						release(&np->lock);
    800023e2:	8526                	mv	a0,s1
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	892080e7          	jalr	-1902(ra) # 80000c76 <release>
						release(&wait_lock);
    800023ec:	0000f517          	auipc	a0,0xf
    800023f0:	ee450513          	addi	a0,a0,-284 # 800112d0 <wait_lock>
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	882080e7          	jalr	-1918(ra) # 80000c76 <release>
						return -1;
    800023fc:	59fd                	li	s3,-1
    800023fe:	a0a1                	j	80002446 <wait+0x100>
		for (np = proc; np < &proc[NPROC]; np++)
    80002400:	18848493          	addi	s1,s1,392
    80002404:	03348463          	beq	s1,s3,8000242c <wait+0xe6>
			if (np->parent == p)
    80002408:	6cbc                	ld	a5,88(s1)
    8000240a:	ff279be3          	bne	a5,s2,80002400 <wait+0xba>
				acquire(&np->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	ffffe097          	auipc	ra,0xffffe
    80002414:	7b2080e7          	jalr	1970(ra) # 80000bc2 <acquire>
				if (np->state == ZOMBIE)
    80002418:	4c9c                	lw	a5,24(s1)
    8000241a:	f94781e3          	beq	a5,s4,8000239c <wait+0x56>
				release(&np->lock);
    8000241e:	8526                	mv	a0,s1
    80002420:	fffff097          	auipc	ra,0xfffff
    80002424:	856080e7          	jalr	-1962(ra) # 80000c76 <release>
				havekids = 1;
    80002428:	8756                	mv	a4,s5
    8000242a:	bfd9                	j	80002400 <wait+0xba>
		if (!havekids || p->killed)
    8000242c:	c701                	beqz	a4,80002434 <wait+0xee>
    8000242e:	02892783          	lw	a5,40(s2)
    80002432:	c79d                	beqz	a5,80002460 <wait+0x11a>
			release(&wait_lock);
    80002434:	0000f517          	auipc	a0,0xf
    80002438:	e9c50513          	addi	a0,a0,-356 # 800112d0 <wait_lock>
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	83a080e7          	jalr	-1990(ra) # 80000c76 <release>
			return -1;
    80002444:	59fd                	li	s3,-1
}
    80002446:	854e                	mv	a0,s3
    80002448:	60a6                	ld	ra,72(sp)
    8000244a:	6406                	ld	s0,64(sp)
    8000244c:	74e2                	ld	s1,56(sp)
    8000244e:	7942                	ld	s2,48(sp)
    80002450:	79a2                	ld	s3,40(sp)
    80002452:	7a02                	ld	s4,32(sp)
    80002454:	6ae2                	ld	s5,24(sp)
    80002456:	6b42                	ld	s6,16(sp)
    80002458:	6ba2                	ld	s7,8(sp)
    8000245a:	6c02                	ld	s8,0(sp)
    8000245c:	6161                	addi	sp,sp,80
    8000245e:	8082                	ret
		sleep(p, &wait_lock); //DOC: wait-sleep
    80002460:	85e2                	mv	a1,s8
    80002462:	854a                	mv	a0,s2
    80002464:	00000097          	auipc	ra,0x0
    80002468:	e7e080e7          	jalr	-386(ra) # 800022e2 <sleep>
		havekids = 0;
    8000246c:	b715                	j	80002390 <wait+0x4a>

000000008000246e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000246e:	7139                	addi	sp,sp,-64
    80002470:	fc06                	sd	ra,56(sp)
    80002472:	f822                	sd	s0,48(sp)
    80002474:	f426                	sd	s1,40(sp)
    80002476:	f04a                	sd	s2,32(sp)
    80002478:	ec4e                	sd	s3,24(sp)
    8000247a:	e852                	sd	s4,16(sp)
    8000247c:	e456                	sd	s5,8(sp)
    8000247e:	0080                	addi	s0,sp,64
    80002480:	8a2a                	mv	s4,a0
	struct proc *p;

	for (p = proc; p < &proc[NPROC]; p++)
    80002482:	0000f497          	auipc	s1,0xf
    80002486:	26648493          	addi	s1,s1,614 # 800116e8 <proc>
	{
		if (p != myproc())
		{
			acquire(&p->lock);
			if (p->state == SLEEPING && p->chan == chan)
    8000248a:	4989                	li	s3,2
			{
				p->state = RUNNABLE;
    8000248c:	4a8d                	li	s5,3
	for (p = proc; p < &proc[NPROC]; p++)
    8000248e:	00015917          	auipc	s2,0x15
    80002492:	45a90913          	addi	s2,s2,1114 # 800178e8 <tickslock>
    80002496:	a811                	j	800024aa <wakeup+0x3c>
				p->turn = get_turn(); // ADDED: determin the turn of the process when it wakes up
			}
			release(&p->lock);
    80002498:	8526                	mv	a0,s1
    8000249a:	ffffe097          	auipc	ra,0xffffe
    8000249e:	7dc080e7          	jalr	2012(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    800024a2:	18848493          	addi	s1,s1,392
    800024a6:	03248b63          	beq	s1,s2,800024dc <wakeup+0x6e>
		if (p != myproc())
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	518080e7          	jalr	1304(ra) # 800019c2 <myproc>
    800024b2:	fea488e3          	beq	s1,a0,800024a2 <wakeup+0x34>
			acquire(&p->lock);
    800024b6:	8526                	mv	a0,s1
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	70a080e7          	jalr	1802(ra) # 80000bc2 <acquire>
			if (p->state == SLEEPING && p->chan == chan)
    800024c0:	4c9c                	lw	a5,24(s1)
    800024c2:	fd379be3          	bne	a5,s3,80002498 <wakeup+0x2a>
    800024c6:	709c                	ld	a5,32(s1)
    800024c8:	fd4798e3          	bne	a5,s4,80002498 <wakeup+0x2a>
				p->state = RUNNABLE;
    800024cc:	0154ac23          	sw	s5,24(s1)
				p->turn = get_turn(); // ADDED: determin the turn of the process when it wakes up
    800024d0:	fffff097          	auipc	ra,0xfffff
    800024d4:	33c080e7          	jalr	828(ra) # 8000180c <get_turn>
    800024d8:	c8a8                	sw	a0,80(s1)
    800024da:	bf7d                	j	80002498 <wakeup+0x2a>
		}
	}
}
    800024dc:	70e2                	ld	ra,56(sp)
    800024de:	7442                	ld	s0,48(sp)
    800024e0:	74a2                	ld	s1,40(sp)
    800024e2:	7902                	ld	s2,32(sp)
    800024e4:	69e2                	ld	s3,24(sp)
    800024e6:	6a42                	ld	s4,16(sp)
    800024e8:	6aa2                	ld	s5,8(sp)
    800024ea:	6121                	addi	sp,sp,64
    800024ec:	8082                	ret

00000000800024ee <reparent>:
{
    800024ee:	7179                	addi	sp,sp,-48
    800024f0:	f406                	sd	ra,40(sp)
    800024f2:	f022                	sd	s0,32(sp)
    800024f4:	ec26                	sd	s1,24(sp)
    800024f6:	e84a                	sd	s2,16(sp)
    800024f8:	e44e                	sd	s3,8(sp)
    800024fa:	e052                	sd	s4,0(sp)
    800024fc:	1800                	addi	s0,sp,48
    800024fe:	892a                	mv	s2,a0
	for (pp = proc; pp < &proc[NPROC]; pp++)
    80002500:	0000f497          	auipc	s1,0xf
    80002504:	1e848493          	addi	s1,s1,488 # 800116e8 <proc>
			pp->parent = initproc;
    80002508:	00007a17          	auipc	s4,0x7
    8000250c:	b20a0a13          	addi	s4,s4,-1248 # 80009028 <initproc>
	for (pp = proc; pp < &proc[NPROC]; pp++)
    80002510:	00015997          	auipc	s3,0x15
    80002514:	3d898993          	addi	s3,s3,984 # 800178e8 <tickslock>
    80002518:	a029                	j	80002522 <reparent+0x34>
    8000251a:	18848493          	addi	s1,s1,392
    8000251e:	01348d63          	beq	s1,s3,80002538 <reparent+0x4a>
		if (pp->parent == p)
    80002522:	6cbc                	ld	a5,88(s1)
    80002524:	ff279be3          	bne	a5,s2,8000251a <reparent+0x2c>
			pp->parent = initproc;
    80002528:	000a3503          	ld	a0,0(s4)
    8000252c:	eca8                	sd	a0,88(s1)
			wakeup(initproc);
    8000252e:	00000097          	auipc	ra,0x0
    80002532:	f40080e7          	jalr	-192(ra) # 8000246e <wakeup>
    80002536:	b7d5                	j	8000251a <reparent+0x2c>
}
    80002538:	70a2                	ld	ra,40(sp)
    8000253a:	7402                	ld	s0,32(sp)
    8000253c:	64e2                	ld	s1,24(sp)
    8000253e:	6942                	ld	s2,16(sp)
    80002540:	69a2                	ld	s3,8(sp)
    80002542:	6a02                	ld	s4,0(sp)
    80002544:	6145                	addi	sp,sp,48
    80002546:	8082                	ret

0000000080002548 <exit>:
{
    80002548:	7179                	addi	sp,sp,-48
    8000254a:	f406                	sd	ra,40(sp)
    8000254c:	f022                	sd	s0,32(sp)
    8000254e:	ec26                	sd	s1,24(sp)
    80002550:	e84a                	sd	s2,16(sp)
    80002552:	e44e                	sd	s3,8(sp)
    80002554:	e052                	sd	s4,0(sp)
    80002556:	1800                	addi	s0,sp,48
    80002558:	8a2a                	mv	s4,a0
	struct proc *p = myproc();
    8000255a:	fffff097          	auipc	ra,0xfffff
    8000255e:	468080e7          	jalr	1128(ra) # 800019c2 <myproc>
    80002562:	89aa                	mv	s3,a0
	if (p == initproc)
    80002564:	00007797          	auipc	a5,0x7
    80002568:	ac47b783          	ld	a5,-1340(a5) # 80009028 <initproc>
    8000256c:	0f050493          	addi	s1,a0,240
    80002570:	17050913          	addi	s2,a0,368
    80002574:	02a79363          	bne	a5,a0,8000259a <exit+0x52>
		panic("init exiting");
    80002578:	00006517          	auipc	a0,0x6
    8000257c:	d1050513          	addi	a0,a0,-752 # 80008288 <digits+0x248>
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	faa080e7          	jalr	-86(ra) # 8000052a <panic>
			fileclose(f);
    80002588:	00002097          	auipc	ra,0x2
    8000258c:	608080e7          	jalr	1544(ra) # 80004b90 <fileclose>
			p->ofile[fd] = 0;
    80002590:	0004b023          	sd	zero,0(s1)
	for (int fd = 0; fd < NOFILE; fd++)
    80002594:	04a1                	addi	s1,s1,8
    80002596:	01248563          	beq	s1,s2,800025a0 <exit+0x58>
		if (p->ofile[fd])
    8000259a:	6088                	ld	a0,0(s1)
    8000259c:	f575                	bnez	a0,80002588 <exit+0x40>
    8000259e:	bfdd                	j	80002594 <exit+0x4c>
	begin_op();
    800025a0:	00002097          	auipc	ra,0x2
    800025a4:	124080e7          	jalr	292(ra) # 800046c4 <begin_op>
	iput(p->cwd);
    800025a8:	1709b503          	ld	a0,368(s3)
    800025ac:	00002097          	auipc	ra,0x2
    800025b0:	8fc080e7          	jalr	-1796(ra) # 80003ea8 <iput>
	end_op();
    800025b4:	00002097          	auipc	ra,0x2
    800025b8:	190080e7          	jalr	400(ra) # 80004744 <end_op>
	p->cwd = 0;
    800025bc:	1609b823          	sd	zero,368(s3)
	acquire(&wait_lock);
    800025c0:	0000f497          	auipc	s1,0xf
    800025c4:	d1048493          	addi	s1,s1,-752 # 800112d0 <wait_lock>
    800025c8:	8526                	mv	a0,s1
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	5f8080e7          	jalr	1528(ra) # 80000bc2 <acquire>
	reparent(p);
    800025d2:	854e                	mv	a0,s3
    800025d4:	00000097          	auipc	ra,0x0
    800025d8:	f1a080e7          	jalr	-230(ra) # 800024ee <reparent>
	wakeup(p->parent);
    800025dc:	0589b503          	ld	a0,88(s3)
    800025e0:	00000097          	auipc	ra,0x0
    800025e4:	e8e080e7          	jalr	-370(ra) # 8000246e <wakeup>
	acquire(&p->lock);
    800025e8:	854e                	mv	a0,s3
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	5d8080e7          	jalr	1496(ra) # 80000bc2 <acquire>
	p->xstate = status;
    800025f2:	0349a623          	sw	s4,44(s3)
	p->state = ZOMBIE;
    800025f6:	4795                	li	a5,5
    800025f8:	00f9ac23          	sw	a5,24(s3)
	release(&wait_lock);
    800025fc:	8526                	mv	a0,s1
    800025fe:	ffffe097          	auipc	ra,0xffffe
    80002602:	678080e7          	jalr	1656(ra) # 80000c76 <release>
	sched();
    80002606:	00000097          	auipc	ra,0x0
    8000260a:	bca080e7          	jalr	-1078(ra) # 800021d0 <sched>
	panic("zombie exit");
    8000260e:	00006517          	auipc	a0,0x6
    80002612:	c8a50513          	addi	a0,a0,-886 # 80008298 <digits+0x258>
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	f14080e7          	jalr	-236(ra) # 8000052a <panic>

000000008000261e <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000261e:	7179                	addi	sp,sp,-48
    80002620:	f406                	sd	ra,40(sp)
    80002622:	f022                	sd	s0,32(sp)
    80002624:	ec26                	sd	s1,24(sp)
    80002626:	e84a                	sd	s2,16(sp)
    80002628:	e44e                	sd	s3,8(sp)
    8000262a:	1800                	addi	s0,sp,48
    8000262c:	892a                	mv	s2,a0
	struct proc *p;

	for (p = proc; p < &proc[NPROC]; p++)
    8000262e:	0000f497          	auipc	s1,0xf
    80002632:	0ba48493          	addi	s1,s1,186 # 800116e8 <proc>
    80002636:	00015997          	auipc	s3,0x15
    8000263a:	2b298993          	addi	s3,s3,690 # 800178e8 <tickslock>
	{
		acquire(&p->lock);
    8000263e:	8526                	mv	a0,s1
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	582080e7          	jalr	1410(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    80002648:	589c                	lw	a5,48(s1)
    8000264a:	01278d63          	beq	a5,s2,80002664 <kill+0x46>
				p->state = RUNNABLE;
			}
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    8000264e:	8526                	mv	a0,s1
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	626080e7          	jalr	1574(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80002658:	18848493          	addi	s1,s1,392
    8000265c:	ff3491e3          	bne	s1,s3,8000263e <kill+0x20>
	}
	return -1;
    80002660:	557d                	li	a0,-1
    80002662:	a829                	j	8000267c <kill+0x5e>
			p->killed = 1;
    80002664:	4785                	li	a5,1
    80002666:	d49c                	sw	a5,40(s1)
			if (p->state == SLEEPING)
    80002668:	4c98                	lw	a4,24(s1)
    8000266a:	4789                	li	a5,2
    8000266c:	00f70f63          	beq	a4,a5,8000268a <kill+0x6c>
			release(&p->lock);
    80002670:	8526                	mv	a0,s1
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	604080e7          	jalr	1540(ra) # 80000c76 <release>
			return 0;
    8000267a:	4501                	li	a0,0
}
    8000267c:	70a2                	ld	ra,40(sp)
    8000267e:	7402                	ld	s0,32(sp)
    80002680:	64e2                	ld	s1,24(sp)
    80002682:	6942                	ld	s2,16(sp)
    80002684:	69a2                	ld	s3,8(sp)
    80002686:	6145                	addi	sp,sp,48
    80002688:	8082                	ret
				p->state = RUNNABLE;
    8000268a:	478d                	li	a5,3
    8000268c:	cc9c                	sw	a5,24(s1)
    8000268e:	b7cd                	j	80002670 <kill+0x52>

0000000080002690 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002690:	7179                	addi	sp,sp,-48
    80002692:	f406                	sd	ra,40(sp)
    80002694:	f022                	sd	s0,32(sp)
    80002696:	ec26                	sd	s1,24(sp)
    80002698:	e84a                	sd	s2,16(sp)
    8000269a:	e44e                	sd	s3,8(sp)
    8000269c:	e052                	sd	s4,0(sp)
    8000269e:	1800                	addi	s0,sp,48
    800026a0:	84aa                	mv	s1,a0
    800026a2:	892e                	mv	s2,a1
    800026a4:	89b2                	mv	s3,a2
    800026a6:	8a36                	mv	s4,a3
	struct proc *p = myproc();
    800026a8:	fffff097          	auipc	ra,0xfffff
    800026ac:	31a080e7          	jalr	794(ra) # 800019c2 <myproc>
	if (user_dst)
    800026b0:	c08d                	beqz	s1,800026d2 <either_copyout+0x42>
	{
		return copyout(p->pagetable, dst, src, len);
    800026b2:	86d2                	mv	a3,s4
    800026b4:	864e                	mv	a2,s3
    800026b6:	85ca                	mv	a1,s2
    800026b8:	7928                	ld	a0,112(a0)
    800026ba:	fffff097          	auipc	ra,0xfffff
    800026be:	f84080e7          	jalr	-124(ra) # 8000163e <copyout>
	else
	{
		memmove((char *)dst, src, len);
		return 0;
	}
}
    800026c2:	70a2                	ld	ra,40(sp)
    800026c4:	7402                	ld	s0,32(sp)
    800026c6:	64e2                	ld	s1,24(sp)
    800026c8:	6942                	ld	s2,16(sp)
    800026ca:	69a2                	ld	s3,8(sp)
    800026cc:	6a02                	ld	s4,0(sp)
    800026ce:	6145                	addi	sp,sp,48
    800026d0:	8082                	ret
		memmove((char *)dst, src, len);
    800026d2:	000a061b          	sext.w	a2,s4
    800026d6:	85ce                	mv	a1,s3
    800026d8:	854a                	mv	a0,s2
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	640080e7          	jalr	1600(ra) # 80000d1a <memmove>
		return 0;
    800026e2:	8526                	mv	a0,s1
    800026e4:	bff9                	j	800026c2 <either_copyout+0x32>

00000000800026e6 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026e6:	7179                	addi	sp,sp,-48
    800026e8:	f406                	sd	ra,40(sp)
    800026ea:	f022                	sd	s0,32(sp)
    800026ec:	ec26                	sd	s1,24(sp)
    800026ee:	e84a                	sd	s2,16(sp)
    800026f0:	e44e                	sd	s3,8(sp)
    800026f2:	e052                	sd	s4,0(sp)
    800026f4:	1800                	addi	s0,sp,48
    800026f6:	892a                	mv	s2,a0
    800026f8:	84ae                	mv	s1,a1
    800026fa:	89b2                	mv	s3,a2
    800026fc:	8a36                	mv	s4,a3
	struct proc *p = myproc();
    800026fe:	fffff097          	auipc	ra,0xfffff
    80002702:	2c4080e7          	jalr	708(ra) # 800019c2 <myproc>
	if (user_src)
    80002706:	c08d                	beqz	s1,80002728 <either_copyin+0x42>
	{
		return copyin(p->pagetable, dst, src, len);
    80002708:	86d2                	mv	a3,s4
    8000270a:	864e                	mv	a2,s3
    8000270c:	85ca                	mv	a1,s2
    8000270e:	7928                	ld	a0,112(a0)
    80002710:	fffff097          	auipc	ra,0xfffff
    80002714:	fba080e7          	jalr	-70(ra) # 800016ca <copyin>
	else
	{
		memmove(dst, (char *)src, len);
		return 0;
	}
}
    80002718:	70a2                	ld	ra,40(sp)
    8000271a:	7402                	ld	s0,32(sp)
    8000271c:	64e2                	ld	s1,24(sp)
    8000271e:	6942                	ld	s2,16(sp)
    80002720:	69a2                	ld	s3,8(sp)
    80002722:	6a02                	ld	s4,0(sp)
    80002724:	6145                	addi	sp,sp,48
    80002726:	8082                	ret
		memmove(dst, (char *)src, len);
    80002728:	000a061b          	sext.w	a2,s4
    8000272c:	85ce                	mv	a1,s3
    8000272e:	854a                	mv	a0,s2
    80002730:	ffffe097          	auipc	ra,0xffffe
    80002734:	5ea080e7          	jalr	1514(ra) # 80000d1a <memmove>
		return 0;
    80002738:	8526                	mv	a0,s1
    8000273a:	bff9                	j	80002718 <either_copyin+0x32>

000000008000273c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000273c:	715d                	addi	sp,sp,-80
    8000273e:	e486                	sd	ra,72(sp)
    80002740:	e0a2                	sd	s0,64(sp)
    80002742:	fc26                	sd	s1,56(sp)
    80002744:	f84a                	sd	s2,48(sp)
    80002746:	f44e                	sd	s3,40(sp)
    80002748:	f052                	sd	s4,32(sp)
    8000274a:	ec56                	sd	s5,24(sp)
    8000274c:	e85a                	sd	s6,16(sp)
    8000274e:	e45e                	sd	s7,8(sp)
    80002750:	0880                	addi	s0,sp,80
		[RUNNING] "run   ",
		[ZOMBIE] "zombie"};
	struct proc *p;
	char *state;

	printf("\n");
    80002752:	00006517          	auipc	a0,0x6
    80002756:	ae650513          	addi	a0,a0,-1306 # 80008238 <digits+0x1f8>
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	e1a080e7          	jalr	-486(ra) # 80000574 <printf>
	for (p = proc; p < &proc[NPROC]; p++)
    80002762:	0000f497          	auipc	s1,0xf
    80002766:	0fe48493          	addi	s1,s1,254 # 80011860 <proc+0x178>
    8000276a:	00015917          	auipc	s2,0x15
    8000276e:	2f690913          	addi	s2,s2,758 # 80017a60 <bcache+0x160>
	{
		if (p->state == UNUSED)
			continue;
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002772:	4b15                	li	s6,5
			state = states[p->state];
		else
			state = "???";
    80002774:	00006997          	auipc	s3,0x6
    80002778:	b3498993          	addi	s3,s3,-1228 # 800082a8 <digits+0x268>
		printf("%d %s %s", p->pid, state, p->name);
    8000277c:	00006a97          	auipc	s5,0x6
    80002780:	b34a8a93          	addi	s5,s5,-1228 # 800082b0 <digits+0x270>
		printf("\n");
    80002784:	00006a17          	auipc	s4,0x6
    80002788:	ab4a0a13          	addi	s4,s4,-1356 # 80008238 <digits+0x1f8>
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000278c:	00006b97          	auipc	s7,0x6
    80002790:	b5cb8b93          	addi	s7,s7,-1188 # 800082e8 <states.0>
    80002794:	a00d                	j	800027b6 <procdump+0x7a>
		printf("%d %s %s", p->pid, state, p->name);
    80002796:	eb86a583          	lw	a1,-328(a3)
    8000279a:	8556                	mv	a0,s5
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	dd8080e7          	jalr	-552(ra) # 80000574 <printf>
		printf("\n");
    800027a4:	8552                	mv	a0,s4
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	dce080e7          	jalr	-562(ra) # 80000574 <printf>
	for (p = proc; p < &proc[NPROC]; p++)
    800027ae:	18848493          	addi	s1,s1,392
    800027b2:	03248263          	beq	s1,s2,800027d6 <procdump+0x9a>
		if (p->state == UNUSED)
    800027b6:	86a6                	mv	a3,s1
    800027b8:	ea04a783          	lw	a5,-352(s1)
    800027bc:	dbed                	beqz	a5,800027ae <procdump+0x72>
			state = "???";
    800027be:	864e                	mv	a2,s3
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027c0:	fcfb6be3          	bltu	s6,a5,80002796 <procdump+0x5a>
    800027c4:	02079713          	slli	a4,a5,0x20
    800027c8:	01d75793          	srli	a5,a4,0x1d
    800027cc:	97de                	add	a5,a5,s7
    800027ce:	6390                	ld	a2,0(a5)
    800027d0:	f279                	bnez	a2,80002796 <procdump+0x5a>
			state = "???";
    800027d2:	864e                	mv	a2,s3
    800027d4:	b7c9                	j	80002796 <procdump+0x5a>
	}
}
    800027d6:	60a6                	ld	ra,72(sp)
    800027d8:	6406                	ld	s0,64(sp)
    800027da:	74e2                	ld	s1,56(sp)
    800027dc:	7942                	ld	s2,48(sp)
    800027de:	79a2                	ld	s3,40(sp)
    800027e0:	7a02                	ld	s4,32(sp)
    800027e2:	6ae2                	ld	s5,24(sp)
    800027e4:	6b42                	ld	s6,16(sp)
    800027e6:	6ba2                	ld	s7,8(sp)
    800027e8:	6161                	addi	sp,sp,80
    800027ea:	8082                	ret

00000000800027ec <trace>:
//ADDED
int trace(int mask, int pid)
{
    800027ec:	7179                	addi	sp,sp,-48
    800027ee:	f406                	sd	ra,40(sp)
    800027f0:	f022                	sd	s0,32(sp)
    800027f2:	ec26                	sd	s1,24(sp)
    800027f4:	e84a                	sd	s2,16(sp)
    800027f6:	e44e                	sd	s3,8(sp)
    800027f8:	e052                	sd	s4,0(sp)
    800027fa:	1800                	addi	s0,sp,48
    800027fc:	8a2a                	mv	s4,a0
    800027fe:	892e                	mv	s2,a1
	struct proc *p;
	for (p = proc; p < &proc[NPROC]; p++)
    80002800:	0000f497          	auipc	s1,0xf
    80002804:	ee848493          	addi	s1,s1,-280 # 800116e8 <proc>
    80002808:	00015997          	auipc	s3,0x15
    8000280c:	0e098993          	addi	s3,s3,224 # 800178e8 <tickslock>
	{
		acquire(&p->lock);
    80002810:	8526                	mv	a0,s1
    80002812:	ffffe097          	auipc	ra,0xffffe
    80002816:	3b0080e7          	jalr	944(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    8000281a:	589c                	lw	a5,48(s1)
    8000281c:	01278d63          	beq	a5,s2,80002836 <trace+0x4a>
		{
			p->trace_mask = mask;
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    80002820:	8526                	mv	a0,s1
    80002822:	ffffe097          	auipc	ra,0xffffe
    80002826:	454080e7          	jalr	1108(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    8000282a:	18848493          	addi	s1,s1,392
    8000282e:	ff3491e3          	bne	s1,s3,80002810 <trace+0x24>
	}

	return -1;
    80002832:	557d                	li	a0,-1
    80002834:	a809                	j	80002846 <trace+0x5a>
			p->trace_mask = mask;
    80002836:	0344aa23          	sw	s4,52(s1)
			release(&p->lock);
    8000283a:	8526                	mv	a0,s1
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	43a080e7          	jalr	1082(ra) # 80000c76 <release>
			return 0;
    80002844:	4501                	li	a0,0
}
    80002846:	70a2                	ld	ra,40(sp)
    80002848:	7402                	ld	s0,32(sp)
    8000284a:	64e2                	ld	s1,24(sp)
    8000284c:	6942                	ld	s2,16(sp)
    8000284e:	69a2                	ld	s3,8(sp)
    80002850:	6a02                	ld	s4,0(sp)
    80002852:	6145                	addi	sp,sp,48
    80002854:	8082                	ret

0000000080002856 <getmsk>:

int getmsk(int pid)
{
    80002856:	7179                	addi	sp,sp,-48
    80002858:	f406                	sd	ra,40(sp)
    8000285a:	f022                	sd	s0,32(sp)
    8000285c:	ec26                	sd	s1,24(sp)
    8000285e:	e84a                	sd	s2,16(sp)
    80002860:	e44e                	sd	s3,8(sp)
    80002862:	1800                	addi	s0,sp,48
    80002864:	892a                	mv	s2,a0
	struct proc *p;
	int mask;

	for (p = proc; p < &proc[NPROC]; p++)
    80002866:	0000f497          	auipc	s1,0xf
    8000286a:	e8248493          	addi	s1,s1,-382 # 800116e8 <proc>
    8000286e:	00015997          	auipc	s3,0x15
    80002872:	07a98993          	addi	s3,s3,122 # 800178e8 <tickslock>
	{
		acquire(&p->lock);
    80002876:	8526                	mv	a0,s1
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	34a080e7          	jalr	842(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    80002880:	589c                	lw	a5,48(s1)
    80002882:	01278d63          	beq	a5,s2,8000289c <getmsk+0x46>
		{
			mask = p->trace_mask;
			release(&p->lock);
			return mask;
		}
		release(&p->lock);
    80002886:	8526                	mv	a0,s1
    80002888:	ffffe097          	auipc	ra,0xffffe
    8000288c:	3ee080e7          	jalr	1006(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80002890:	18848493          	addi	s1,s1,392
    80002894:	ff3491e3          	bne	s1,s3,80002876 <getmsk+0x20>
	}

	return -1;
    80002898:	597d                	li	s2,-1
    8000289a:	a801                	j	800028aa <getmsk+0x54>
			mask = p->trace_mask;
    8000289c:	0344a903          	lw	s2,52(s1)
			release(&p->lock);
    800028a0:	8526                	mv	a0,s1
    800028a2:	ffffe097          	auipc	ra,0xffffe
    800028a6:	3d4080e7          	jalr	980(ra) # 80000c76 <release>
}
    800028aa:	854a                	mv	a0,s2
    800028ac:	70a2                	ld	ra,40(sp)
    800028ae:	7402                	ld	s0,32(sp)
    800028b0:	64e2                	ld	s1,24(sp)
    800028b2:	6942                	ld	s2,16(sp)
    800028b4:	69a2                	ld	s3,8(sp)
    800028b6:	6145                	addi	sp,sp,48
    800028b8:	8082                	ret

00000000800028ba <update_perf>:
	}
}

// ADDED
void update_perf(uint ticks, struct proc *p)
{
    800028ba:	1141                	addi	sp,sp,-16
    800028bc:	e422                	sd	s0,8(sp)
    800028be:	0800                	addi	s0,sp,16
	switch (p->state)
    800028c0:	4d9c                	lw	a5,24(a1)
    800028c2:	4711                	li	a4,4
    800028c4:	02e78763          	beq	a5,a4,800028f2 <update_perf+0x38>
    800028c8:	00f76c63          	bltu	a4,a5,800028e0 <update_perf+0x26>
    800028cc:	4709                	li	a4,2
    800028ce:	02e78863          	beq	a5,a4,800028fe <update_perf+0x44>
    800028d2:	470d                	li	a4,3
    800028d4:	02e79263          	bne	a5,a4,800028f8 <update_perf+0x3e>
		break;
	case SLEEPING:
		p->performance.stime++;
		break;
	case RUNNABLE:
		p->performance.retime++;
    800028d8:	41fc                	lw	a5,68(a1)
    800028da:	2785                	addiw	a5,a5,1
    800028dc:	c1fc                	sw	a5,68(a1)
		break;
    800028de:	a829                	j	800028f8 <update_perf+0x3e>
	switch (p->state)
    800028e0:	4715                	li	a4,5
    800028e2:	00e79b63          	bne	a5,a4,800028f8 <update_perf+0x3e>
	case ZOMBIE:
		if (p->performance.ttime == -1)
    800028e6:	5dd8                	lw	a4,60(a1)
    800028e8:	57fd                	li	a5,-1
    800028ea:	00f71763          	bne	a4,a5,800028f8 <update_perf+0x3e>
			p->performance.ttime = ticks;
    800028ee:	ddc8                	sw	a0,60(a1)
		break;
	default:
		break;
	}
}
    800028f0:	a021                	j	800028f8 <update_perf+0x3e>
		p->performance.rutime++;
    800028f2:	45bc                	lw	a5,72(a1)
    800028f4:	2785                	addiw	a5,a5,1
    800028f6:	c5bc                	sw	a5,72(a1)
}
    800028f8:	6422                	ld	s0,8(sp)
    800028fa:	0141                	addi	sp,sp,16
    800028fc:	8082                	ret
		p->performance.stime++;
    800028fe:	41bc                	lw	a5,64(a1)
    80002900:	2785                	addiw	a5,a5,1
    80002902:	c1bc                	sw	a5,64(a1)
		break;
    80002904:	bfd5                	j	800028f8 <update_perf+0x3e>

0000000080002906 <wait_stat>:
{
    80002906:	711d                	addi	sp,sp,-96
    80002908:	ec86                	sd	ra,88(sp)
    8000290a:	e8a2                	sd	s0,80(sp)
    8000290c:	e4a6                	sd	s1,72(sp)
    8000290e:	e0ca                	sd	s2,64(sp)
    80002910:	fc4e                	sd	s3,56(sp)
    80002912:	f852                	sd	s4,48(sp)
    80002914:	f456                	sd	s5,40(sp)
    80002916:	f05a                	sd	s6,32(sp)
    80002918:	ec5e                	sd	s7,24(sp)
    8000291a:	e862                	sd	s8,16(sp)
    8000291c:	e466                	sd	s9,8(sp)
    8000291e:	1080                	addi	s0,sp,96
    80002920:	8b2a                	mv	s6,a0
    80002922:	8bae                	mv	s7,a1
	struct proc *p = myproc();
    80002924:	fffff097          	auipc	ra,0xfffff
    80002928:	09e080e7          	jalr	158(ra) # 800019c2 <myproc>
    8000292c:	892a                	mv	s2,a0
	acquire(&wait_lock);
    8000292e:	0000f517          	auipc	a0,0xf
    80002932:	9a250513          	addi	a0,a0,-1630 # 800112d0 <wait_lock>
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	28c080e7          	jalr	652(ra) # 80000bc2 <acquire>
		havekids = 0;
    8000293e:	4c01                	li	s8,0
				if (np->state == ZOMBIE)
    80002940:	4a15                	li	s4,5
				havekids = 1;
    80002942:	4a85                	li	s5,1
		for (np = proc; np < &proc[NPROC]; np++)
    80002944:	00015997          	auipc	s3,0x15
    80002948:	fa498993          	addi	s3,s3,-92 # 800178e8 <tickslock>
		sleep(p, &wait_lock); //DOC: wait-sleep
    8000294c:	0000fc97          	auipc	s9,0xf
    80002950:	984c8c93          	addi	s9,s9,-1660 # 800112d0 <wait_lock>
		havekids = 0;
    80002954:	8762                	mv	a4,s8
		for (np = proc; np < &proc[NPROC]; np++)
    80002956:	0000f497          	auipc	s1,0xf
    8000295a:	d9248493          	addi	s1,s1,-622 # 800116e8 <proc>
    8000295e:	a85d                	j	80002a14 <wait_stat+0x10e>
					pid = np->pid;
    80002960:	0304a983          	lw	s3,48(s1)
					update_perf(ticks, np);
    80002964:	85a6                	mv	a1,s1
    80002966:	00006517          	auipc	a0,0x6
    8000296a:	6ca52503          	lw	a0,1738(a0) # 80009030 <ticks>
    8000296e:	00000097          	auipc	ra,0x0
    80002972:	f4c080e7          	jalr	-180(ra) # 800028ba <update_perf>
					if (status != 0 && copyout(p->pagetable, status, (char *)&np->xstate,
    80002976:	000b0e63          	beqz	s6,80002992 <wait_stat+0x8c>
    8000297a:	4691                	li	a3,4
    8000297c:	02c48613          	addi	a2,s1,44
    80002980:	85da                	mv	a1,s6
    80002982:	07093503          	ld	a0,112(s2)
    80002986:	fffff097          	auipc	ra,0xfffff
    8000298a:	cb8080e7          	jalr	-840(ra) # 8000163e <copyout>
    8000298e:	04054163          	bltz	a0,800029d0 <wait_stat+0xca>
					if (copyout(p->pagetable, performance, (char *)&(np->performance), sizeof(struct perf)) < 0)
    80002992:	46e1                	li	a3,24
    80002994:	03848613          	addi	a2,s1,56
    80002998:	85de                	mv	a1,s7
    8000299a:	07093503          	ld	a0,112(s2)
    8000299e:	fffff097          	auipc	ra,0xfffff
    800029a2:	ca0080e7          	jalr	-864(ra) # 8000163e <copyout>
    800029a6:	04054463          	bltz	a0,800029ee <wait_stat+0xe8>
					freeproc(np);
    800029aa:	8526                	mv	a0,s1
    800029ac:	fffff097          	auipc	ra,0xfffff
    800029b0:	1c8080e7          	jalr	456(ra) # 80001b74 <freeproc>
					release(&np->lock);
    800029b4:	8526                	mv	a0,s1
    800029b6:	ffffe097          	auipc	ra,0xffffe
    800029ba:	2c0080e7          	jalr	704(ra) # 80000c76 <release>
					release(&wait_lock);
    800029be:	0000f517          	auipc	a0,0xf
    800029c2:	91250513          	addi	a0,a0,-1774 # 800112d0 <wait_lock>
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	2b0080e7          	jalr	688(ra) # 80000c76 <release>
					return pid;
    800029ce:	a051                	j	80002a52 <wait_stat+0x14c>
						release(&np->lock);
    800029d0:	8526                	mv	a0,s1
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	2a4080e7          	jalr	676(ra) # 80000c76 <release>
						release(&wait_lock);
    800029da:	0000f517          	auipc	a0,0xf
    800029de:	8f650513          	addi	a0,a0,-1802 # 800112d0 <wait_lock>
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	294080e7          	jalr	660(ra) # 80000c76 <release>
						return -1;
    800029ea:	59fd                	li	s3,-1
    800029ec:	a09d                	j	80002a52 <wait_stat+0x14c>
						release(&np->lock);
    800029ee:	8526                	mv	a0,s1
    800029f0:	ffffe097          	auipc	ra,0xffffe
    800029f4:	286080e7          	jalr	646(ra) # 80000c76 <release>
						release(&wait_lock);
    800029f8:	0000f517          	auipc	a0,0xf
    800029fc:	8d850513          	addi	a0,a0,-1832 # 800112d0 <wait_lock>
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	276080e7          	jalr	630(ra) # 80000c76 <release>
						return -1;
    80002a08:	59fd                	li	s3,-1
    80002a0a:	a0a1                	j	80002a52 <wait_stat+0x14c>
		for (np = proc; np < &proc[NPROC]; np++)
    80002a0c:	18848493          	addi	s1,s1,392
    80002a10:	03348463          	beq	s1,s3,80002a38 <wait_stat+0x132>
			if (np->parent == p)
    80002a14:	6cbc                	ld	a5,88(s1)
    80002a16:	ff279be3          	bne	a5,s2,80002a0c <wait_stat+0x106>
				acquire(&np->lock);
    80002a1a:	8526                	mv	a0,s1
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	1a6080e7          	jalr	422(ra) # 80000bc2 <acquire>
				if (np->state == ZOMBIE)
    80002a24:	4c9c                	lw	a5,24(s1)
    80002a26:	f3478de3          	beq	a5,s4,80002960 <wait_stat+0x5a>
				release(&np->lock);
    80002a2a:	8526                	mv	a0,s1
    80002a2c:	ffffe097          	auipc	ra,0xffffe
    80002a30:	24a080e7          	jalr	586(ra) # 80000c76 <release>
				havekids = 1;
    80002a34:	8756                	mv	a4,s5
    80002a36:	bfd9                	j	80002a0c <wait_stat+0x106>
		if (!havekids || p->killed)
    80002a38:	c701                	beqz	a4,80002a40 <wait_stat+0x13a>
    80002a3a:	02892783          	lw	a5,40(s2)
    80002a3e:	cb85                	beqz	a5,80002a6e <wait_stat+0x168>
			release(&wait_lock);
    80002a40:	0000f517          	auipc	a0,0xf
    80002a44:	89050513          	addi	a0,a0,-1904 # 800112d0 <wait_lock>
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	22e080e7          	jalr	558(ra) # 80000c76 <release>
			return -1;
    80002a50:	59fd                	li	s3,-1
}
    80002a52:	854e                	mv	a0,s3
    80002a54:	60e6                	ld	ra,88(sp)
    80002a56:	6446                	ld	s0,80(sp)
    80002a58:	64a6                	ld	s1,72(sp)
    80002a5a:	6906                	ld	s2,64(sp)
    80002a5c:	79e2                	ld	s3,56(sp)
    80002a5e:	7a42                	ld	s4,48(sp)
    80002a60:	7aa2                	ld	s5,40(sp)
    80002a62:	7b02                	ld	s6,32(sp)
    80002a64:	6be2                	ld	s7,24(sp)
    80002a66:	6c42                	ld	s8,16(sp)
    80002a68:	6ca2                	ld	s9,8(sp)
    80002a6a:	6125                	addi	sp,sp,96
    80002a6c:	8082                	ret
		sleep(p, &wait_lock); //DOC: wait-sleep
    80002a6e:	85e6                	mv	a1,s9
    80002a70:	854a                	mv	a0,s2
    80002a72:	00000097          	auipc	ra,0x0
    80002a76:	870080e7          	jalr	-1936(ra) # 800022e2 <sleep>
		havekids = 0;
    80002a7a:	bde9                	j	80002954 <wait_stat+0x4e>

0000000080002a7c <update_perfs>:

// ADDED
void update_perfs(uint ticks)
{
    80002a7c:	7179                	addi	sp,sp,-48
    80002a7e:	f406                	sd	ra,40(sp)
    80002a80:	f022                	sd	s0,32(sp)
    80002a82:	ec26                	sd	s1,24(sp)
    80002a84:	e84a                	sd	s2,16(sp)
    80002a86:	e44e                	sd	s3,8(sp)
    80002a88:	1800                	addi	s0,sp,48
    80002a8a:	892a                	mv	s2,a0
	struct proc *p;
	for (p = proc; p < &proc[NPROC]; p++)
    80002a8c:	0000f497          	auipc	s1,0xf
    80002a90:	c5c48493          	addi	s1,s1,-932 # 800116e8 <proc>
    80002a94:	00015997          	auipc	s3,0x15
    80002a98:	e5498993          	addi	s3,s3,-428 # 800178e8 <tickslock>
	{
		acquire(&p->lock);
    80002a9c:	8526                	mv	a0,s1
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	124080e7          	jalr	292(ra) # 80000bc2 <acquire>
		update_perf(ticks, p);
    80002aa6:	85a6                	mv	a1,s1
    80002aa8:	854a                	mv	a0,s2
    80002aaa:	00000097          	auipc	ra,0x0
    80002aae:	e10080e7          	jalr	-496(ra) # 800028ba <update_perf>
		release(&p->lock);
    80002ab2:	8526                	mv	a0,s1
    80002ab4:	ffffe097          	auipc	ra,0xffffe
    80002ab8:	1c2080e7          	jalr	450(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80002abc:	18848493          	addi	s1,s1,392
    80002ac0:	fd349ee3          	bne	s1,s3,80002a9c <update_perfs+0x20>
	}
    80002ac4:	70a2                	ld	ra,40(sp)
    80002ac6:	7402                	ld	s0,32(sp)
    80002ac8:	64e2                	ld	s1,24(sp)
    80002aca:	6942                	ld	s2,16(sp)
    80002acc:	69a2                	ld	s3,8(sp)
    80002ace:	6145                	addi	sp,sp,48
    80002ad0:	8082                	ret

0000000080002ad2 <swtch>:
    80002ad2:	00153023          	sd	ra,0(a0)
    80002ad6:	00253423          	sd	sp,8(a0)
    80002ada:	e900                	sd	s0,16(a0)
    80002adc:	ed04                	sd	s1,24(a0)
    80002ade:	03253023          	sd	s2,32(a0)
    80002ae2:	03353423          	sd	s3,40(a0)
    80002ae6:	03453823          	sd	s4,48(a0)
    80002aea:	03553c23          	sd	s5,56(a0)
    80002aee:	05653023          	sd	s6,64(a0)
    80002af2:	05753423          	sd	s7,72(a0)
    80002af6:	05853823          	sd	s8,80(a0)
    80002afa:	05953c23          	sd	s9,88(a0)
    80002afe:	07a53023          	sd	s10,96(a0)
    80002b02:	07b53423          	sd	s11,104(a0)
    80002b06:	0005b083          	ld	ra,0(a1)
    80002b0a:	0085b103          	ld	sp,8(a1)
    80002b0e:	6980                	ld	s0,16(a1)
    80002b10:	6d84                	ld	s1,24(a1)
    80002b12:	0205b903          	ld	s2,32(a1)
    80002b16:	0285b983          	ld	s3,40(a1)
    80002b1a:	0305ba03          	ld	s4,48(a1)
    80002b1e:	0385ba83          	ld	s5,56(a1)
    80002b22:	0405bb03          	ld	s6,64(a1)
    80002b26:	0485bb83          	ld	s7,72(a1)
    80002b2a:	0505bc03          	ld	s8,80(a1)
    80002b2e:	0585bc83          	ld	s9,88(a1)
    80002b32:	0605bd03          	ld	s10,96(a1)
    80002b36:	0685bd83          	ld	s11,104(a1)
    80002b3a:	8082                	ret

0000000080002b3c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b3c:	1141                	addi	sp,sp,-16
    80002b3e:	e406                	sd	ra,8(sp)
    80002b40:	e022                	sd	s0,0(sp)
    80002b42:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b44:	00005597          	auipc	a1,0x5
    80002b48:	7d458593          	addi	a1,a1,2004 # 80008318 <states.0+0x30>
    80002b4c:	00015517          	auipc	a0,0x15
    80002b50:	d9c50513          	addi	a0,a0,-612 # 800178e8 <tickslock>
    80002b54:	ffffe097          	auipc	ra,0xffffe
    80002b58:	fde080e7          	jalr	-34(ra) # 80000b32 <initlock>
}
    80002b5c:	60a2                	ld	ra,8(sp)
    80002b5e:	6402                	ld	s0,0(sp)
    80002b60:	0141                	addi	sp,sp,16
    80002b62:	8082                	ret

0000000080002b64 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b64:	1141                	addi	sp,sp,-16
    80002b66:	e422                	sd	s0,8(sp)
    80002b68:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b6a:	00003797          	auipc	a5,0x3
    80002b6e:	65678793          	addi	a5,a5,1622 # 800061c0 <kernelvec>
    80002b72:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b76:	6422                	ld	s0,8(sp)
    80002b78:	0141                	addi	sp,sp,16
    80002b7a:	8082                	ret

0000000080002b7c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002b7c:	1141                	addi	sp,sp,-16
    80002b7e:	e406                	sd	ra,8(sp)
    80002b80:	e022                	sd	s0,0(sp)
    80002b82:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b84:	fffff097          	auipc	ra,0xfffff
    80002b88:	e3e080e7          	jalr	-450(ra) # 800019c2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b8c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b90:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b92:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002b96:	00004617          	auipc	a2,0x4
    80002b9a:	46a60613          	addi	a2,a2,1130 # 80007000 <_trampoline>
    80002b9e:	00004697          	auipc	a3,0x4
    80002ba2:	46268693          	addi	a3,a3,1122 # 80007000 <_trampoline>
    80002ba6:	8e91                	sub	a3,a3,a2
    80002ba8:	040007b7          	lui	a5,0x4000
    80002bac:	17fd                	addi	a5,a5,-1
    80002bae:	07b2                	slli	a5,a5,0xc
    80002bb0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bb2:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002bb6:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002bb8:	180026f3          	csrr	a3,satp
    80002bbc:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002bbe:	7d38                	ld	a4,120(a0)
    80002bc0:	7134                	ld	a3,96(a0)
    80002bc2:	6585                	lui	a1,0x1
    80002bc4:	96ae                	add	a3,a3,a1
    80002bc6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002bc8:	7d38                	ld	a4,120(a0)
    80002bca:	00000697          	auipc	a3,0x0
    80002bce:	14868693          	addi	a3,a3,328 # 80002d12 <usertrap>
    80002bd2:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002bd4:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002bd6:	8692                	mv	a3,tp
    80002bd8:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bda:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002bde:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002be2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002be6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002bea:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bec:	6f18                	ld	a4,24(a4)
    80002bee:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002bf2:	792c                	ld	a1,112(a0)
    80002bf4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002bf6:	00004717          	auipc	a4,0x4
    80002bfa:	49a70713          	addi	a4,a4,1178 # 80007090 <userret>
    80002bfe:	8f11                	sub	a4,a4,a2
    80002c00:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002c02:	577d                	li	a4,-1
    80002c04:	177e                	slli	a4,a4,0x3f
    80002c06:	8dd9                	or	a1,a1,a4
    80002c08:	02000537          	lui	a0,0x2000
    80002c0c:	157d                	addi	a0,a0,-1
    80002c0e:	0536                	slli	a0,a0,0xd
    80002c10:	9782                	jalr	a5
}
    80002c12:	60a2                	ld	ra,8(sp)
    80002c14:	6402                	ld	s0,0(sp)
    80002c16:	0141                	addi	sp,sp,16
    80002c18:	8082                	ret

0000000080002c1a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c1a:	1101                	addi	sp,sp,-32
    80002c1c:	ec06                	sd	ra,24(sp)
    80002c1e:	e822                	sd	s0,16(sp)
    80002c20:	e426                	sd	s1,8(sp)
    80002c22:	e04a                	sd	s2,0(sp)
    80002c24:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c26:	00015917          	auipc	s2,0x15
    80002c2a:	cc290913          	addi	s2,s2,-830 # 800178e8 <tickslock>
    80002c2e:	854a                	mv	a0,s2
    80002c30:	ffffe097          	auipc	ra,0xffffe
    80002c34:	f92080e7          	jalr	-110(ra) # 80000bc2 <acquire>
  ticks++;
    80002c38:	00006497          	auipc	s1,0x6
    80002c3c:	3f848493          	addi	s1,s1,1016 # 80009030 <ticks>
    80002c40:	4088                	lw	a0,0(s1)
    80002c42:	2505                	addiw	a0,a0,1
    80002c44:	c088                	sw	a0,0(s1)
  update_perfs(ticks);
    80002c46:	2501                	sext.w	a0,a0
    80002c48:	00000097          	auipc	ra,0x0
    80002c4c:	e34080e7          	jalr	-460(ra) # 80002a7c <update_perfs>
  wakeup(&ticks);
    80002c50:	8526                	mv	a0,s1
    80002c52:	00000097          	auipc	ra,0x0
    80002c56:	81c080e7          	jalr	-2020(ra) # 8000246e <wakeup>
  release(&tickslock);
    80002c5a:	854a                	mv	a0,s2
    80002c5c:	ffffe097          	auipc	ra,0xffffe
    80002c60:	01a080e7          	jalr	26(ra) # 80000c76 <release>
}
    80002c64:	60e2                	ld	ra,24(sp)
    80002c66:	6442                	ld	s0,16(sp)
    80002c68:	64a2                	ld	s1,8(sp)
    80002c6a:	6902                	ld	s2,0(sp)
    80002c6c:	6105                	addi	sp,sp,32
    80002c6e:	8082                	ret

0000000080002c70 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c70:	1101                	addi	sp,sp,-32
    80002c72:	ec06                	sd	ra,24(sp)
    80002c74:	e822                	sd	s0,16(sp)
    80002c76:	e426                	sd	s1,8(sp)
    80002c78:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c7a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002c7e:	00074d63          	bltz	a4,80002c98 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002c82:	57fd                	li	a5,-1
    80002c84:	17fe                	slli	a5,a5,0x3f
    80002c86:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002c88:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002c8a:	06f70363          	beq	a4,a5,80002cf0 <devintr+0x80>
  }
}
    80002c8e:	60e2                	ld	ra,24(sp)
    80002c90:	6442                	ld	s0,16(sp)
    80002c92:	64a2                	ld	s1,8(sp)
    80002c94:	6105                	addi	sp,sp,32
    80002c96:	8082                	ret
     (scause & 0xff) == 9){
    80002c98:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002c9c:	46a5                	li	a3,9
    80002c9e:	fed792e3          	bne	a5,a3,80002c82 <devintr+0x12>
    int irq = plic_claim();
    80002ca2:	00003097          	auipc	ra,0x3
    80002ca6:	626080e7          	jalr	1574(ra) # 800062c8 <plic_claim>
    80002caa:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002cac:	47a9                	li	a5,10
    80002cae:	02f50763          	beq	a0,a5,80002cdc <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002cb2:	4785                	li	a5,1
    80002cb4:	02f50963          	beq	a0,a5,80002ce6 <devintr+0x76>
    return 1;
    80002cb8:	4505                	li	a0,1
    } else if(irq){
    80002cba:	d8f1                	beqz	s1,80002c8e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002cbc:	85a6                	mv	a1,s1
    80002cbe:	00005517          	auipc	a0,0x5
    80002cc2:	66250513          	addi	a0,a0,1634 # 80008320 <states.0+0x38>
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	8ae080e7          	jalr	-1874(ra) # 80000574 <printf>
      plic_complete(irq);
    80002cce:	8526                	mv	a0,s1
    80002cd0:	00003097          	auipc	ra,0x3
    80002cd4:	61c080e7          	jalr	1564(ra) # 800062ec <plic_complete>
    return 1;
    80002cd8:	4505                	li	a0,1
    80002cda:	bf55                	j	80002c8e <devintr+0x1e>
      uartintr();
    80002cdc:	ffffe097          	auipc	ra,0xffffe
    80002ce0:	caa080e7          	jalr	-854(ra) # 80000986 <uartintr>
    80002ce4:	b7ed                	j	80002cce <devintr+0x5e>
      virtio_disk_intr();
    80002ce6:	00004097          	auipc	ra,0x4
    80002cea:	a98080e7          	jalr	-1384(ra) # 8000677e <virtio_disk_intr>
    80002cee:	b7c5                	j	80002cce <devintr+0x5e>
    if(cpuid() == 0){
    80002cf0:	fffff097          	auipc	ra,0xfffff
    80002cf4:	ca6080e7          	jalr	-858(ra) # 80001996 <cpuid>
    80002cf8:	c901                	beqz	a0,80002d08 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002cfa:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002cfe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d00:	14479073          	csrw	sip,a5
    return 2;
    80002d04:	4509                	li	a0,2
    80002d06:	b761                	j	80002c8e <devintr+0x1e>
      clockintr();
    80002d08:	00000097          	auipc	ra,0x0
    80002d0c:	f12080e7          	jalr	-238(ra) # 80002c1a <clockintr>
    80002d10:	b7ed                	j	80002cfa <devintr+0x8a>

0000000080002d12 <usertrap>:
{
    80002d12:	1101                	addi	sp,sp,-32
    80002d14:	ec06                	sd	ra,24(sp)
    80002d16:	e822                	sd	s0,16(sp)
    80002d18:	e426                	sd	s1,8(sp)
    80002d1a:	e04a                	sd	s2,0(sp)
    80002d1c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d1e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d22:	1007f793          	andi	a5,a5,256
    80002d26:	e3ad                	bnez	a5,80002d88 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d28:	00003797          	auipc	a5,0x3
    80002d2c:	49878793          	addi	a5,a5,1176 # 800061c0 <kernelvec>
    80002d30:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	c8e080e7          	jalr	-882(ra) # 800019c2 <myproc>
    80002d3c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d3e:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d40:	14102773          	csrr	a4,sepc
    80002d44:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d46:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d4a:	47a1                	li	a5,8
    80002d4c:	04f71c63          	bne	a4,a5,80002da4 <usertrap+0x92>
    if(p->killed)
    80002d50:	551c                	lw	a5,40(a0)
    80002d52:	e3b9                	bnez	a5,80002d98 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002d54:	7cb8                	ld	a4,120(s1)
    80002d56:	6f1c                	ld	a5,24(a4)
    80002d58:	0791                	addi	a5,a5,4
    80002d5a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d5c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d60:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d64:	10079073          	csrw	sstatus,a5
    syscall();
    80002d68:	00000097          	auipc	ra,0x0
    80002d6c:	3cc080e7          	jalr	972(ra) # 80003134 <syscall>
  if(p->killed)
    80002d70:	549c                	lw	a5,40(s1)
    80002d72:	e3c5                	bnez	a5,80002e12 <usertrap+0x100>
  usertrapret();
    80002d74:	00000097          	auipc	ra,0x0
    80002d78:	e08080e7          	jalr	-504(ra) # 80002b7c <usertrapret>
}
    80002d7c:	60e2                	ld	ra,24(sp)
    80002d7e:	6442                	ld	s0,16(sp)
    80002d80:	64a2                	ld	s1,8(sp)
    80002d82:	6902                	ld	s2,0(sp)
    80002d84:	6105                	addi	sp,sp,32
    80002d86:	8082                	ret
    panic("usertrap: not from user mode");
    80002d88:	00005517          	auipc	a0,0x5
    80002d8c:	5b850513          	addi	a0,a0,1464 # 80008340 <states.0+0x58>
    80002d90:	ffffd097          	auipc	ra,0xffffd
    80002d94:	79a080e7          	jalr	1946(ra) # 8000052a <panic>
      exit(-1);
    80002d98:	557d                	li	a0,-1
    80002d9a:	fffff097          	auipc	ra,0xfffff
    80002d9e:	7ae080e7          	jalr	1966(ra) # 80002548 <exit>
    80002da2:	bf4d                	j	80002d54 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	ecc080e7          	jalr	-308(ra) # 80002c70 <devintr>
    80002dac:	892a                	mv	s2,a0
    80002dae:	c501                	beqz	a0,80002db6 <usertrap+0xa4>
  if(p->killed)
    80002db0:	549c                	lw	a5,40(s1)
    80002db2:	c3a1                	beqz	a5,80002df2 <usertrap+0xe0>
    80002db4:	a815                	j	80002de8 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002db6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002dba:	5890                	lw	a2,48(s1)
    80002dbc:	00005517          	auipc	a0,0x5
    80002dc0:	5a450513          	addi	a0,a0,1444 # 80008360 <states.0+0x78>
    80002dc4:	ffffd097          	auipc	ra,0xffffd
    80002dc8:	7b0080e7          	jalr	1968(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dcc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dd0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dd4:	00005517          	auipc	a0,0x5
    80002dd8:	5bc50513          	addi	a0,a0,1468 # 80008390 <states.0+0xa8>
    80002ddc:	ffffd097          	auipc	ra,0xffffd
    80002de0:	798080e7          	jalr	1944(ra) # 80000574 <printf>
    p->killed = 1;
    80002de4:	4785                	li	a5,1
    80002de6:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002de8:	557d                	li	a0,-1
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	75e080e7          	jalr	1886(ra) # 80002548 <exit>
    if(which_dev == 2 && ticks % QUANTUM == 0)
    80002df2:	4789                	li	a5,2
    80002df4:	f8f910e3          	bne	s2,a5,80002d74 <usertrap+0x62>
    80002df8:	00006797          	auipc	a5,0x6
    80002dfc:	2387a783          	lw	a5,568(a5) # 80009030 <ticks>
    80002e00:	4715                	li	a4,5
    80002e02:	02e7f7bb          	remuw	a5,a5,a4
    80002e06:	f7bd                	bnez	a5,80002d74 <usertrap+0x62>
      yield();
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	49e080e7          	jalr	1182(ra) # 800022a6 <yield>
    80002e10:	b795                	j	80002d74 <usertrap+0x62>
  int which_dev = 0;
    80002e12:	4901                	li	s2,0
    80002e14:	bfd1                	j	80002de8 <usertrap+0xd6>

0000000080002e16 <kerneltrap>:
{
    80002e16:	7179                	addi	sp,sp,-48
    80002e18:	f406                	sd	ra,40(sp)
    80002e1a:	f022                	sd	s0,32(sp)
    80002e1c:	ec26                	sd	s1,24(sp)
    80002e1e:	e84a                	sd	s2,16(sp)
    80002e20:	e44e                	sd	s3,8(sp)
    80002e22:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e24:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e28:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e2c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e30:	1004f793          	andi	a5,s1,256
    80002e34:	cb85                	beqz	a5,80002e64 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e3a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e3c:	ef85                	bnez	a5,80002e74 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e3e:	00000097          	auipc	ra,0x0
    80002e42:	e32080e7          	jalr	-462(ra) # 80002c70 <devintr>
    80002e46:	cd1d                	beqz	a0,80002e84 <kerneltrap+0x6e>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && ticks % QUANTUM == 0)
    80002e48:	4789                	li	a5,2
    80002e4a:	06f50a63          	beq	a0,a5,80002ebe <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e4e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e52:	10049073          	csrw	sstatus,s1
}
    80002e56:	70a2                	ld	ra,40(sp)
    80002e58:	7402                	ld	s0,32(sp)
    80002e5a:	64e2                	ld	s1,24(sp)
    80002e5c:	6942                	ld	s2,16(sp)
    80002e5e:	69a2                	ld	s3,8(sp)
    80002e60:	6145                	addi	sp,sp,48
    80002e62:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e64:	00005517          	auipc	a0,0x5
    80002e68:	54c50513          	addi	a0,a0,1356 # 800083b0 <states.0+0xc8>
    80002e6c:	ffffd097          	auipc	ra,0xffffd
    80002e70:	6be080e7          	jalr	1726(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002e74:	00005517          	auipc	a0,0x5
    80002e78:	56450513          	addi	a0,a0,1380 # 800083d8 <states.0+0xf0>
    80002e7c:	ffffd097          	auipc	ra,0xffffd
    80002e80:	6ae080e7          	jalr	1710(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002e84:	85ce                	mv	a1,s3
    80002e86:	00005517          	auipc	a0,0x5
    80002e8a:	57250513          	addi	a0,a0,1394 # 800083f8 <states.0+0x110>
    80002e8e:	ffffd097          	auipc	ra,0xffffd
    80002e92:	6e6080e7          	jalr	1766(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e96:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e9a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e9e:	00005517          	auipc	a0,0x5
    80002ea2:	56a50513          	addi	a0,a0,1386 # 80008408 <states.0+0x120>
    80002ea6:	ffffd097          	auipc	ra,0xffffd
    80002eaa:	6ce080e7          	jalr	1742(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002eae:	00005517          	auipc	a0,0x5
    80002eb2:	57250513          	addi	a0,a0,1394 # 80008420 <states.0+0x138>
    80002eb6:	ffffd097          	auipc	ra,0xffffd
    80002eba:	674080e7          	jalr	1652(ra) # 8000052a <panic>
    if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && ticks % QUANTUM == 0)
    80002ebe:	fffff097          	auipc	ra,0xfffff
    80002ec2:	b04080e7          	jalr	-1276(ra) # 800019c2 <myproc>
    80002ec6:	d541                	beqz	a0,80002e4e <kerneltrap+0x38>
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	afa080e7          	jalr	-1286(ra) # 800019c2 <myproc>
    80002ed0:	4d18                	lw	a4,24(a0)
    80002ed2:	4791                	li	a5,4
    80002ed4:	f6f71de3          	bne	a4,a5,80002e4e <kerneltrap+0x38>
    80002ed8:	00006797          	auipc	a5,0x6
    80002edc:	1587a783          	lw	a5,344(a5) # 80009030 <ticks>
    80002ee0:	4715                	li	a4,5
    80002ee2:	02e7f7bb          	remuw	a5,a5,a4
    80002ee6:	f7a5                	bnez	a5,80002e4e <kerneltrap+0x38>
      yield();
    80002ee8:	fffff097          	auipc	ra,0xfffff
    80002eec:	3be080e7          	jalr	958(ra) # 800022a6 <yield>
    80002ef0:	bfb9                	j	80002e4e <kerneltrap+0x38>

0000000080002ef2 <argraw>:
	return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ef2:	1101                	addi	sp,sp,-32
    80002ef4:	ec06                	sd	ra,24(sp)
    80002ef6:	e822                	sd	s0,16(sp)
    80002ef8:	e426                	sd	s1,8(sp)
    80002efa:	1000                	addi	s0,sp,32
    80002efc:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    80002efe:	fffff097          	auipc	ra,0xfffff
    80002f02:	ac4080e7          	jalr	-1340(ra) # 800019c2 <myproc>
	switch (n)
    80002f06:	4795                	li	a5,5
    80002f08:	0497e163          	bltu	a5,s1,80002f4a <argraw+0x58>
    80002f0c:	048a                	slli	s1,s1,0x2
    80002f0e:	00005717          	auipc	a4,0x5
    80002f12:	66270713          	addi	a4,a4,1634 # 80008570 <states.0+0x288>
    80002f16:	94ba                	add	s1,s1,a4
    80002f18:	409c                	lw	a5,0(s1)
    80002f1a:	97ba                	add	a5,a5,a4
    80002f1c:	8782                	jr	a5
	{
	case 0:
		return p->trapframe->a0;
    80002f1e:	7d3c                	ld	a5,120(a0)
    80002f20:	7ba8                	ld	a0,112(a5)
	case 5:
		return p->trapframe->a5;
	}
	panic("argraw");
	return -1;
}
    80002f22:	60e2                	ld	ra,24(sp)
    80002f24:	6442                	ld	s0,16(sp)
    80002f26:	64a2                	ld	s1,8(sp)
    80002f28:	6105                	addi	sp,sp,32
    80002f2a:	8082                	ret
		return p->trapframe->a1;
    80002f2c:	7d3c                	ld	a5,120(a0)
    80002f2e:	7fa8                	ld	a0,120(a5)
    80002f30:	bfcd                	j	80002f22 <argraw+0x30>
		return p->trapframe->a2;
    80002f32:	7d3c                	ld	a5,120(a0)
    80002f34:	63c8                	ld	a0,128(a5)
    80002f36:	b7f5                	j	80002f22 <argraw+0x30>
		return p->trapframe->a3;
    80002f38:	7d3c                	ld	a5,120(a0)
    80002f3a:	67c8                	ld	a0,136(a5)
    80002f3c:	b7dd                	j	80002f22 <argraw+0x30>
		return p->trapframe->a4;
    80002f3e:	7d3c                	ld	a5,120(a0)
    80002f40:	6bc8                	ld	a0,144(a5)
    80002f42:	b7c5                	j	80002f22 <argraw+0x30>
		return p->trapframe->a5;
    80002f44:	7d3c                	ld	a5,120(a0)
    80002f46:	6fc8                	ld	a0,152(a5)
    80002f48:	bfe9                	j	80002f22 <argraw+0x30>
	panic("argraw");
    80002f4a:	00005517          	auipc	a0,0x5
    80002f4e:	4e650513          	addi	a0,a0,1254 # 80008430 <states.0+0x148>
    80002f52:	ffffd097          	auipc	ra,0xffffd
    80002f56:	5d8080e7          	jalr	1496(ra) # 8000052a <panic>

0000000080002f5a <fetchaddr>:
{
    80002f5a:	1101                	addi	sp,sp,-32
    80002f5c:	ec06                	sd	ra,24(sp)
    80002f5e:	e822                	sd	s0,16(sp)
    80002f60:	e426                	sd	s1,8(sp)
    80002f62:	e04a                	sd	s2,0(sp)
    80002f64:	1000                	addi	s0,sp,32
    80002f66:	84aa                	mv	s1,a0
    80002f68:	892e                	mv	s2,a1
	struct proc *p = myproc();
    80002f6a:	fffff097          	auipc	ra,0xfffff
    80002f6e:	a58080e7          	jalr	-1448(ra) # 800019c2 <myproc>
	if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002f72:	753c                	ld	a5,104(a0)
    80002f74:	02f4f863          	bgeu	s1,a5,80002fa4 <fetchaddr+0x4a>
    80002f78:	00848713          	addi	a4,s1,8
    80002f7c:	02e7e663          	bltu	a5,a4,80002fa8 <fetchaddr+0x4e>
	if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f80:	46a1                	li	a3,8
    80002f82:	8626                	mv	a2,s1
    80002f84:	85ca                	mv	a1,s2
    80002f86:	7928                	ld	a0,112(a0)
    80002f88:	ffffe097          	auipc	ra,0xffffe
    80002f8c:	742080e7          	jalr	1858(ra) # 800016ca <copyin>
    80002f90:	00a03533          	snez	a0,a0
    80002f94:	40a00533          	neg	a0,a0
}
    80002f98:	60e2                	ld	ra,24(sp)
    80002f9a:	6442                	ld	s0,16(sp)
    80002f9c:	64a2                	ld	s1,8(sp)
    80002f9e:	6902                	ld	s2,0(sp)
    80002fa0:	6105                	addi	sp,sp,32
    80002fa2:	8082                	ret
		return -1;
    80002fa4:	557d                	li	a0,-1
    80002fa6:	bfcd                	j	80002f98 <fetchaddr+0x3e>
    80002fa8:	557d                	li	a0,-1
    80002faa:	b7fd                	j	80002f98 <fetchaddr+0x3e>

0000000080002fac <fetchstr>:
{
    80002fac:	7179                	addi	sp,sp,-48
    80002fae:	f406                	sd	ra,40(sp)
    80002fb0:	f022                	sd	s0,32(sp)
    80002fb2:	ec26                	sd	s1,24(sp)
    80002fb4:	e84a                	sd	s2,16(sp)
    80002fb6:	e44e                	sd	s3,8(sp)
    80002fb8:	1800                	addi	s0,sp,48
    80002fba:	892a                	mv	s2,a0
    80002fbc:	84ae                	mv	s1,a1
    80002fbe:	89b2                	mv	s3,a2
	struct proc *p = myproc();
    80002fc0:	fffff097          	auipc	ra,0xfffff
    80002fc4:	a02080e7          	jalr	-1534(ra) # 800019c2 <myproc>
	int err = copyinstr(p->pagetable, buf, addr, max);
    80002fc8:	86ce                	mv	a3,s3
    80002fca:	864a                	mv	a2,s2
    80002fcc:	85a6                	mv	a1,s1
    80002fce:	7928                	ld	a0,112(a0)
    80002fd0:	ffffe097          	auipc	ra,0xffffe
    80002fd4:	788080e7          	jalr	1928(ra) # 80001758 <copyinstr>
	if (err < 0)
    80002fd8:	00054763          	bltz	a0,80002fe6 <fetchstr+0x3a>
	return strlen(buf);
    80002fdc:	8526                	mv	a0,s1
    80002fde:	ffffe097          	auipc	ra,0xffffe
    80002fe2:	e64080e7          	jalr	-412(ra) # 80000e42 <strlen>
}
    80002fe6:	70a2                	ld	ra,40(sp)
    80002fe8:	7402                	ld	s0,32(sp)
    80002fea:	64e2                	ld	s1,24(sp)
    80002fec:	6942                	ld	s2,16(sp)
    80002fee:	69a2                	ld	s3,8(sp)
    80002ff0:	6145                	addi	sp,sp,48
    80002ff2:	8082                	ret

0000000080002ff4 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002ff4:	1101                	addi	sp,sp,-32
    80002ff6:	ec06                	sd	ra,24(sp)
    80002ff8:	e822                	sd	s0,16(sp)
    80002ffa:	e426                	sd	s1,8(sp)
    80002ffc:	1000                	addi	s0,sp,32
    80002ffe:	84ae                	mv	s1,a1
	*ip = argraw(n);
    80003000:	00000097          	auipc	ra,0x0
    80003004:	ef2080e7          	jalr	-270(ra) # 80002ef2 <argraw>
    80003008:	c088                	sw	a0,0(s1)
	return 0;
}
    8000300a:	4501                	li	a0,0
    8000300c:	60e2                	ld	ra,24(sp)
    8000300e:	6442                	ld	s0,16(sp)
    80003010:	64a2                	ld	s1,8(sp)
    80003012:	6105                	addi	sp,sp,32
    80003014:	8082                	ret

0000000080003016 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80003016:	1101                	addi	sp,sp,-32
    80003018:	ec06                	sd	ra,24(sp)
    8000301a:	e822                	sd	s0,16(sp)
    8000301c:	e426                	sd	s1,8(sp)
    8000301e:	1000                	addi	s0,sp,32
    80003020:	84ae                	mv	s1,a1
	*ip = argraw(n);
    80003022:	00000097          	auipc	ra,0x0
    80003026:	ed0080e7          	jalr	-304(ra) # 80002ef2 <argraw>
    8000302a:	e088                	sd	a0,0(s1)
	return 0;
}
    8000302c:	4501                	li	a0,0
    8000302e:	60e2                	ld	ra,24(sp)
    80003030:	6442                	ld	s0,16(sp)
    80003032:	64a2                	ld	s1,8(sp)
    80003034:	6105                	addi	sp,sp,32
    80003036:	8082                	ret

0000000080003038 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80003038:	1101                	addi	sp,sp,-32
    8000303a:	ec06                	sd	ra,24(sp)
    8000303c:	e822                	sd	s0,16(sp)
    8000303e:	e426                	sd	s1,8(sp)
    80003040:	e04a                	sd	s2,0(sp)
    80003042:	1000                	addi	s0,sp,32
    80003044:	84ae                	mv	s1,a1
    80003046:	8932                	mv	s2,a2
	*ip = argraw(n);
    80003048:	00000097          	auipc	ra,0x0
    8000304c:	eaa080e7          	jalr	-342(ra) # 80002ef2 <argraw>
	uint64 addr;
	if (argaddr(n, &addr) < 0)
		return -1;
	return fetchstr(addr, buf, max);
    80003050:	864a                	mv	a2,s2
    80003052:	85a6                	mv	a1,s1
    80003054:	00000097          	auipc	ra,0x0
    80003058:	f58080e7          	jalr	-168(ra) # 80002fac <fetchstr>
}
    8000305c:	60e2                	ld	ra,24(sp)
    8000305e:	6442                	ld	s0,16(sp)
    80003060:	64a2                	ld	s1,8(sp)
    80003062:	6902                	ld	s2,0(sp)
    80003064:	6105                	addi	sp,sp,32
    80003066:	8082                	ret

0000000080003068 <print_trace>:
	}
}

// ADDED
void print_trace(int arg)
{
    80003068:	7179                	addi	sp,sp,-48
    8000306a:	f406                	sd	ra,40(sp)
    8000306c:	f022                	sd	s0,32(sp)
    8000306e:	ec26                	sd	s1,24(sp)
    80003070:	e84a                	sd	s2,16(sp)
    80003072:	e44e                	sd	s3,8(sp)
    80003074:	1800                	addi	s0,sp,48
    80003076:	89aa                	mv	s3,a0
	int num;
	struct proc *p = myproc();
    80003078:	fffff097          	auipc	ra,0xfffff
    8000307c:	94a080e7          	jalr	-1718(ra) # 800019c2 <myproc>
	num = p->trapframe->a7;
    80003080:	7d3c                	ld	a5,120(a0)
    80003082:	0a87a903          	lw	s2,168(a5)

	int res = (1 << num) & p->trace_mask;
    80003086:	4785                	li	a5,1
    80003088:	012797bb          	sllw	a5,a5,s2
    8000308c:	5958                	lw	a4,52(a0)
    8000308e:	8ff9                	and	a5,a5,a4
	if (res != 0)
    80003090:	2781                	sext.w	a5,a5
    80003092:	eb81                	bnez	a5,800030a2 <print_trace+0x3a>
		else
		{
			printf("syscall %s  -> %d\n", syscallnames[num], p->trapframe->a0);
		}
	}
} // ADDED
    80003094:	70a2                	ld	ra,40(sp)
    80003096:	7402                	ld	s0,32(sp)
    80003098:	64e2                	ld	s1,24(sp)
    8000309a:	6942                	ld	s2,16(sp)
    8000309c:	69a2                	ld	s3,8(sp)
    8000309e:	6145                	addi	sp,sp,48
    800030a0:	8082                	ret
    800030a2:	84aa                	mv	s1,a0
		printf("%d: ", p->pid);
    800030a4:	590c                	lw	a1,48(a0)
    800030a6:	00005517          	auipc	a0,0x5
    800030aa:	39250513          	addi	a0,a0,914 # 80008438 <states.0+0x150>
    800030ae:	ffffd097          	auipc	ra,0xffffd
    800030b2:	4c6080e7          	jalr	1222(ra) # 80000574 <printf>
		if (num == SYS_fork)
    800030b6:	4785                	li	a5,1
    800030b8:	02f90c63          	beq	s2,a5,800030f0 <print_trace+0x88>
		else if (num == SYS_kill || num == SYS_sbrk)
    800030bc:	4799                	li	a5,6
    800030be:	00f90563          	beq	s2,a5,800030c8 <print_trace+0x60>
    800030c2:	47b1                	li	a5,12
    800030c4:	04f91563          	bne	s2,a5,8000310e <print_trace+0xa6>
			printf("syscall %s %d -> %d\n", syscallnames[num], arg, p->trapframe->a0);
    800030c8:	7cb8                	ld	a4,120(s1)
    800030ca:	090e                	slli	s2,s2,0x3
    800030cc:	00005797          	auipc	a5,0x5
    800030d0:	4bc78793          	addi	a5,a5,1212 # 80008588 <syscallnames>
    800030d4:	993e                	add	s2,s2,a5
    800030d6:	7b34                	ld	a3,112(a4)
    800030d8:	864e                	mv	a2,s3
    800030da:	00093583          	ld	a1,0(s2)
    800030de:	00005517          	auipc	a0,0x5
    800030e2:	38250513          	addi	a0,a0,898 # 80008460 <states.0+0x178>
    800030e6:	ffffd097          	auipc	ra,0xffffd
    800030ea:	48e080e7          	jalr	1166(ra) # 80000574 <printf>
    800030ee:	b75d                	j	80003094 <print_trace+0x2c>
			printf("syscall %s NULL -> %d\n", syscallnames[num], p->trapframe->a0);
    800030f0:	7cbc                	ld	a5,120(s1)
    800030f2:	7bb0                	ld	a2,112(a5)
    800030f4:	00005597          	auipc	a1,0x5
    800030f8:	34c58593          	addi	a1,a1,844 # 80008440 <states.0+0x158>
    800030fc:	00005517          	auipc	a0,0x5
    80003100:	34c50513          	addi	a0,a0,844 # 80008448 <states.0+0x160>
    80003104:	ffffd097          	auipc	ra,0xffffd
    80003108:	470080e7          	jalr	1136(ra) # 80000574 <printf>
    8000310c:	b761                	j	80003094 <print_trace+0x2c>
			printf("syscall %s  -> %d\n", syscallnames[num], p->trapframe->a0);
    8000310e:	7cb8                	ld	a4,120(s1)
    80003110:	090e                	slli	s2,s2,0x3
    80003112:	00005797          	auipc	a5,0x5
    80003116:	47678793          	addi	a5,a5,1142 # 80008588 <syscallnames>
    8000311a:	993e                	add	s2,s2,a5
    8000311c:	7b30                	ld	a2,112(a4)
    8000311e:	00093583          	ld	a1,0(s2)
    80003122:	00005517          	auipc	a0,0x5
    80003126:	35650513          	addi	a0,a0,854 # 80008478 <states.0+0x190>
    8000312a:	ffffd097          	auipc	ra,0xffffd
    8000312e:	44a080e7          	jalr	1098(ra) # 80000574 <printf>
} // ADDED
    80003132:	b78d                	j	80003094 <print_trace+0x2c>

0000000080003134 <syscall>:
{
    80003134:	7179                	addi	sp,sp,-48
    80003136:	f406                	sd	ra,40(sp)
    80003138:	f022                	sd	s0,32(sp)
    8000313a:	ec26                	sd	s1,24(sp)
    8000313c:	e84a                	sd	s2,16(sp)
    8000313e:	1800                	addi	s0,sp,48
	struct proc *p = myproc();
    80003140:	fffff097          	auipc	ra,0xfffff
    80003144:	882080e7          	jalr	-1918(ra) # 800019c2 <myproc>
    80003148:	84aa                	mv	s1,a0
	num = p->trapframe->a7;
    8000314a:	7d3c                	ld	a5,120(a0)
    8000314c:	77dc                	ld	a5,168(a5)
    8000314e:	0007869b          	sext.w	a3,a5
	if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003152:	37fd                	addiw	a5,a5,-1
    80003154:	475d                	li	a4,23
    80003156:	02f76e63          	bltu	a4,a5,80003192 <syscall+0x5e>
    8000315a:	00369713          	slli	a4,a3,0x3
    8000315e:	00005797          	auipc	a5,0x5
    80003162:	42a78793          	addi	a5,a5,1066 # 80008588 <syscallnames>
    80003166:	97ba                	add	a5,a5,a4
    80003168:	0c87b903          	ld	s2,200(a5)
    8000316c:	02090363          	beqz	s2,80003192 <syscall+0x5e>
		argint(0, &arg); // ADDED
    80003170:	fdc40593          	addi	a1,s0,-36
    80003174:	4501                	li	a0,0
    80003176:	00000097          	auipc	ra,0x0
    8000317a:	e7e080e7          	jalr	-386(ra) # 80002ff4 <argint>
		p->trapframe->a0 = syscalls[num]();
    8000317e:	7ca4                	ld	s1,120(s1)
    80003180:	9902                	jalr	s2
    80003182:	f8a8                	sd	a0,112(s1)
		print_trace(arg); // ADDED
    80003184:	fdc42503          	lw	a0,-36(s0)
    80003188:	00000097          	auipc	ra,0x0
    8000318c:	ee0080e7          	jalr	-288(ra) # 80003068 <print_trace>
    80003190:	a839                	j	800031ae <syscall+0x7a>
		printf("%d %s: unknown sys call %d\n",
    80003192:	17848613          	addi	a2,s1,376
    80003196:	588c                	lw	a1,48(s1)
    80003198:	00005517          	auipc	a0,0x5
    8000319c:	2f850513          	addi	a0,a0,760 # 80008490 <states.0+0x1a8>
    800031a0:	ffffd097          	auipc	ra,0xffffd
    800031a4:	3d4080e7          	jalr	980(ra) # 80000574 <printf>
		p->trapframe->a0 = -1;
    800031a8:	7cbc                	ld	a5,120(s1)
    800031aa:	577d                	li	a4,-1
    800031ac:	fbb8                	sd	a4,112(a5)
}
    800031ae:	70a2                	ld	ra,40(sp)
    800031b0:	7402                	ld	s0,32(sp)
    800031b2:	64e2                	ld	s1,24(sp)
    800031b4:	6942                	ld	s2,16(sp)
    800031b6:	6145                	addi	sp,sp,48
    800031b8:	8082                	ret

00000000800031ba <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800031ba:	1101                	addi	sp,sp,-32
    800031bc:	ec06                	sd	ra,24(sp)
    800031be:	e822                	sd	s0,16(sp)
    800031c0:	1000                	addi	s0,sp,32
  int n;
  if (argint(0, &n) < 0)
    800031c2:	fec40593          	addi	a1,s0,-20
    800031c6:	4501                	li	a0,0
    800031c8:	00000097          	auipc	ra,0x0
    800031cc:	e2c080e7          	jalr	-468(ra) # 80002ff4 <argint>
    return -1;
    800031d0:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    800031d2:	00054963          	bltz	a0,800031e4 <sys_exit+0x2a>
  exit(n);
    800031d6:	fec42503          	lw	a0,-20(s0)
    800031da:	fffff097          	auipc	ra,0xfffff
    800031de:	36e080e7          	jalr	878(ra) # 80002548 <exit>
  return 0; // not reached
    800031e2:	4781                	li	a5,0
}
    800031e4:	853e                	mv	a0,a5
    800031e6:	60e2                	ld	ra,24(sp)
    800031e8:	6442                	ld	s0,16(sp)
    800031ea:	6105                	addi	sp,sp,32
    800031ec:	8082                	ret

00000000800031ee <sys_getpid>:

uint64
sys_getpid(void)
{
    800031ee:	1141                	addi	sp,sp,-16
    800031f0:	e406                	sd	ra,8(sp)
    800031f2:	e022                	sd	s0,0(sp)
    800031f4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800031f6:	ffffe097          	auipc	ra,0xffffe
    800031fa:	7cc080e7          	jalr	1996(ra) # 800019c2 <myproc>
}
    800031fe:	5908                	lw	a0,48(a0)
    80003200:	60a2                	ld	ra,8(sp)
    80003202:	6402                	ld	s0,0(sp)
    80003204:	0141                	addi	sp,sp,16
    80003206:	8082                	ret

0000000080003208 <sys_fork>:

uint64
sys_fork(void)
{
    80003208:	1141                	addi	sp,sp,-16
    8000320a:	e406                	sd	ra,8(sp)
    8000320c:	e022                	sd	s0,0(sp)
    8000320e:	0800                	addi	s0,sp,16
  return fork();
    80003210:	fffff097          	auipc	ra,0xfffff
    80003214:	b9e080e7          	jalr	-1122(ra) # 80001dae <fork>
}
    80003218:	60a2                	ld	ra,8(sp)
    8000321a:	6402                	ld	s0,0(sp)
    8000321c:	0141                	addi	sp,sp,16
    8000321e:	8082                	ret

0000000080003220 <sys_wait>:

uint64
sys_wait(void)
{
    80003220:	1101                	addi	sp,sp,-32
    80003222:	ec06                	sd	ra,24(sp)
    80003224:	e822                	sd	s0,16(sp)
    80003226:	1000                	addi	s0,sp,32
  uint64 p;
  if (argaddr(0, &p) < 0)
    80003228:	fe840593          	addi	a1,s0,-24
    8000322c:	4501                	li	a0,0
    8000322e:	00000097          	auipc	ra,0x0
    80003232:	de8080e7          	jalr	-536(ra) # 80003016 <argaddr>
    80003236:	87aa                	mv	a5,a0
    return -1;
    80003238:	557d                	li	a0,-1
  if (argaddr(0, &p) < 0)
    8000323a:	0007c863          	bltz	a5,8000324a <sys_wait+0x2a>
  return wait(p);
    8000323e:	fe843503          	ld	a0,-24(s0)
    80003242:	fffff097          	auipc	ra,0xfffff
    80003246:	104080e7          	jalr	260(ra) # 80002346 <wait>
}
    8000324a:	60e2                	ld	ra,24(sp)
    8000324c:	6442                	ld	s0,16(sp)
    8000324e:	6105                	addi	sp,sp,32
    80003250:	8082                	ret

0000000080003252 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003252:	7179                	addi	sp,sp,-48
    80003254:	f406                	sd	ra,40(sp)
    80003256:	f022                	sd	s0,32(sp)
    80003258:	ec26                	sd	s1,24(sp)
    8000325a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if (argint(0, &n) < 0)
    8000325c:	fdc40593          	addi	a1,s0,-36
    80003260:	4501                	li	a0,0
    80003262:	00000097          	auipc	ra,0x0
    80003266:	d92080e7          	jalr	-622(ra) # 80002ff4 <argint>
    return -1;
    8000326a:	54fd                	li	s1,-1
  if (argint(0, &n) < 0)
    8000326c:	00054f63          	bltz	a0,8000328a <sys_sbrk+0x38>
  addr = myproc()->sz;
    80003270:	ffffe097          	auipc	ra,0xffffe
    80003274:	752080e7          	jalr	1874(ra) # 800019c2 <myproc>
    80003278:	5524                	lw	s1,104(a0)
  if (growproc(n) < 0)
    8000327a:	fdc42503          	lw	a0,-36(s0)
    8000327e:	fffff097          	auipc	ra,0xfffff
    80003282:	abc080e7          	jalr	-1348(ra) # 80001d3a <growproc>
    80003286:	00054863          	bltz	a0,80003296 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    8000328a:	8526                	mv	a0,s1
    8000328c:	70a2                	ld	ra,40(sp)
    8000328e:	7402                	ld	s0,32(sp)
    80003290:	64e2                	ld	s1,24(sp)
    80003292:	6145                	addi	sp,sp,48
    80003294:	8082                	ret
    return -1;
    80003296:	54fd                	li	s1,-1
    80003298:	bfcd                	j	8000328a <sys_sbrk+0x38>

000000008000329a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000329a:	7139                	addi	sp,sp,-64
    8000329c:	fc06                	sd	ra,56(sp)
    8000329e:	f822                	sd	s0,48(sp)
    800032a0:	f426                	sd	s1,40(sp)
    800032a2:	f04a                	sd	s2,32(sp)
    800032a4:	ec4e                	sd	s3,24(sp)
    800032a6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if (argint(0, &n) < 0)
    800032a8:	fcc40593          	addi	a1,s0,-52
    800032ac:	4501                	li	a0,0
    800032ae:	00000097          	auipc	ra,0x0
    800032b2:	d46080e7          	jalr	-698(ra) # 80002ff4 <argint>
    return -1;
    800032b6:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    800032b8:	06054563          	bltz	a0,80003322 <sys_sleep+0x88>
  acquire(&tickslock);
    800032bc:	00014517          	auipc	a0,0x14
    800032c0:	62c50513          	addi	a0,a0,1580 # 800178e8 <tickslock>
    800032c4:	ffffe097          	auipc	ra,0xffffe
    800032c8:	8fe080e7          	jalr	-1794(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    800032cc:	00006917          	auipc	s2,0x6
    800032d0:	d6492903          	lw	s2,-668(s2) # 80009030 <ticks>
  while (ticks - ticks0 < n)
    800032d4:	fcc42783          	lw	a5,-52(s0)
    800032d8:	cf85                	beqz	a5,80003310 <sys_sleep+0x76>
    if (myproc()->killed)
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800032da:	00014997          	auipc	s3,0x14
    800032de:	60e98993          	addi	s3,s3,1550 # 800178e8 <tickslock>
    800032e2:	00006497          	auipc	s1,0x6
    800032e6:	d4e48493          	addi	s1,s1,-690 # 80009030 <ticks>
    if (myproc()->killed)
    800032ea:	ffffe097          	auipc	ra,0xffffe
    800032ee:	6d8080e7          	jalr	1752(ra) # 800019c2 <myproc>
    800032f2:	551c                	lw	a5,40(a0)
    800032f4:	ef9d                	bnez	a5,80003332 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800032f6:	85ce                	mv	a1,s3
    800032f8:	8526                	mv	a0,s1
    800032fa:	fffff097          	auipc	ra,0xfffff
    800032fe:	fe8080e7          	jalr	-24(ra) # 800022e2 <sleep>
  while (ticks - ticks0 < n)
    80003302:	409c                	lw	a5,0(s1)
    80003304:	412787bb          	subw	a5,a5,s2
    80003308:	fcc42703          	lw	a4,-52(s0)
    8000330c:	fce7efe3          	bltu	a5,a4,800032ea <sys_sleep+0x50>
  }
  release(&tickslock);
    80003310:	00014517          	auipc	a0,0x14
    80003314:	5d850513          	addi	a0,a0,1496 # 800178e8 <tickslock>
    80003318:	ffffe097          	auipc	ra,0xffffe
    8000331c:	95e080e7          	jalr	-1698(ra) # 80000c76 <release>
  return 0;
    80003320:	4781                	li	a5,0
}
    80003322:	853e                	mv	a0,a5
    80003324:	70e2                	ld	ra,56(sp)
    80003326:	7442                	ld	s0,48(sp)
    80003328:	74a2                	ld	s1,40(sp)
    8000332a:	7902                	ld	s2,32(sp)
    8000332c:	69e2                	ld	s3,24(sp)
    8000332e:	6121                	addi	sp,sp,64
    80003330:	8082                	ret
      release(&tickslock);
    80003332:	00014517          	auipc	a0,0x14
    80003336:	5b650513          	addi	a0,a0,1462 # 800178e8 <tickslock>
    8000333a:	ffffe097          	auipc	ra,0xffffe
    8000333e:	93c080e7          	jalr	-1732(ra) # 80000c76 <release>
      return -1;
    80003342:	57fd                	li	a5,-1
    80003344:	bff9                	j	80003322 <sys_sleep+0x88>

0000000080003346 <sys_kill>:

uint64
sys_kill(void)
{
    80003346:	1101                	addi	sp,sp,-32
    80003348:	ec06                	sd	ra,24(sp)
    8000334a:	e822                	sd	s0,16(sp)
    8000334c:	1000                	addi	s0,sp,32
  int pid;

  if (argint(0, &pid) < 0)
    8000334e:	fec40593          	addi	a1,s0,-20
    80003352:	4501                	li	a0,0
    80003354:	00000097          	auipc	ra,0x0
    80003358:	ca0080e7          	jalr	-864(ra) # 80002ff4 <argint>
    8000335c:	87aa                	mv	a5,a0
    return -1;
    8000335e:	557d                	li	a0,-1
  if (argint(0, &pid) < 0)
    80003360:	0007c863          	bltz	a5,80003370 <sys_kill+0x2a>
  return kill(pid);
    80003364:	fec42503          	lw	a0,-20(s0)
    80003368:	fffff097          	auipc	ra,0xfffff
    8000336c:	2b6080e7          	jalr	694(ra) # 8000261e <kill>
}
    80003370:	60e2                	ld	ra,24(sp)
    80003372:	6442                	ld	s0,16(sp)
    80003374:	6105                	addi	sp,sp,32
    80003376:	8082                	ret

0000000080003378 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003378:	1101                	addi	sp,sp,-32
    8000337a:	ec06                	sd	ra,24(sp)
    8000337c:	e822                	sd	s0,16(sp)
    8000337e:	e426                	sd	s1,8(sp)
    80003380:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003382:	00014517          	auipc	a0,0x14
    80003386:	56650513          	addi	a0,a0,1382 # 800178e8 <tickslock>
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	838080e7          	jalr	-1992(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80003392:	00006497          	auipc	s1,0x6
    80003396:	c9e4a483          	lw	s1,-866(s1) # 80009030 <ticks>
  release(&tickslock);
    8000339a:	00014517          	auipc	a0,0x14
    8000339e:	54e50513          	addi	a0,a0,1358 # 800178e8 <tickslock>
    800033a2:	ffffe097          	auipc	ra,0xffffe
    800033a6:	8d4080e7          	jalr	-1836(ra) # 80000c76 <release>
  return xticks;
}
    800033aa:	02049513          	slli	a0,s1,0x20
    800033ae:	9101                	srli	a0,a0,0x20
    800033b0:	60e2                	ld	ra,24(sp)
    800033b2:	6442                	ld	s0,16(sp)
    800033b4:	64a2                	ld	s1,8(sp)
    800033b6:	6105                	addi	sp,sp,32
    800033b8:	8082                	ret

00000000800033ba <sys_trace>:

//ADDED
uint64
sys_trace(void)
{
    800033ba:	1101                	addi	sp,sp,-32
    800033bc:	ec06                	sd	ra,24(sp)
    800033be:	e822                	sd	s0,16(sp)
    800033c0:	1000                	addi	s0,sp,32
  int mask, pid;
  argint(0, &mask);
    800033c2:	fec40593          	addi	a1,s0,-20
    800033c6:	4501                	li	a0,0
    800033c8:	00000097          	auipc	ra,0x0
    800033cc:	c2c080e7          	jalr	-980(ra) # 80002ff4 <argint>
  argint(1, &pid);
    800033d0:	fe840593          	addi	a1,s0,-24
    800033d4:	4505                	li	a0,1
    800033d6:	00000097          	auipc	ra,0x0
    800033da:	c1e080e7          	jalr	-994(ra) # 80002ff4 <argint>
  return trace(mask, pid);
    800033de:	fe842583          	lw	a1,-24(s0)
    800033e2:	fec42503          	lw	a0,-20(s0)
    800033e6:	fffff097          	auipc	ra,0xfffff
    800033ea:	406080e7          	jalr	1030(ra) # 800027ec <trace>
}
    800033ee:	60e2                	ld	ra,24(sp)
    800033f0:	6442                	ld	s0,16(sp)
    800033f2:	6105                	addi	sp,sp,32
    800033f4:	8082                	ret

00000000800033f6 <sys_getmsk>:

uint64
sys_getmsk(void)
{
    800033f6:	1101                	addi	sp,sp,-32
    800033f8:	ec06                	sd	ra,24(sp)
    800033fa:	e822                	sd	s0,16(sp)
    800033fc:	1000                	addi	s0,sp,32
  int pid;
  argint(0, &pid);
    800033fe:	fec40593          	addi	a1,s0,-20
    80003402:	4501                	li	a0,0
    80003404:	00000097          	auipc	ra,0x0
    80003408:	bf0080e7          	jalr	-1040(ra) # 80002ff4 <argint>
  return getmsk(pid);
    8000340c:	fec42503          	lw	a0,-20(s0)
    80003410:	fffff097          	auipc	ra,0xfffff
    80003414:	446080e7          	jalr	1094(ra) # 80002856 <getmsk>
}
    80003418:	60e2                	ld	ra,24(sp)
    8000341a:	6442                	ld	s0,16(sp)
    8000341c:	6105                	addi	sp,sp,32
    8000341e:	8082                	ret

0000000080003420 <sys_wait_stat>:

uint64
sys_wait_stat(void)
{
    80003420:	1101                	addi	sp,sp,-32
    80003422:	ec06                	sd	ra,24(sp)
    80003424:	e822                	sd	s0,16(sp)
    80003426:	1000                	addi	s0,sp,32
  uint64 status;
  uint64 performance;
  argaddr(0,  &status);
    80003428:	fe840593          	addi	a1,s0,-24
    8000342c:	4501                	li	a0,0
    8000342e:	00000097          	auipc	ra,0x0
    80003432:	be8080e7          	jalr	-1048(ra) # 80003016 <argaddr>
  argaddr(1,  &performance);
    80003436:	fe040593          	addi	a1,s0,-32
    8000343a:	4505                	li	a0,1
    8000343c:	00000097          	auipc	ra,0x0
    80003440:	bda080e7          	jalr	-1062(ra) # 80003016 <argaddr>
  return wait_stat(status, performance);
    80003444:	fe043583          	ld	a1,-32(s0)
    80003448:	fe843503          	ld	a0,-24(s0)
    8000344c:	fffff097          	auipc	ra,0xfffff
    80003450:	4ba080e7          	jalr	1210(ra) # 80002906 <wait_stat>
}
    80003454:	60e2                	ld	ra,24(sp)
    80003456:	6442                	ld	s0,16(sp)
    80003458:	6105                	addi	sp,sp,32
    8000345a:	8082                	ret

000000008000345c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000345c:	7179                	addi	sp,sp,-48
    8000345e:	f406                	sd	ra,40(sp)
    80003460:	f022                	sd	s0,32(sp)
    80003462:	ec26                	sd	s1,24(sp)
    80003464:	e84a                	sd	s2,16(sp)
    80003466:	e44e                	sd	s3,8(sp)
    80003468:	e052                	sd	s4,0(sp)
    8000346a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000346c:	00005597          	auipc	a1,0x5
    80003470:	2ac58593          	addi	a1,a1,684 # 80008718 <syscalls+0xc8>
    80003474:	00014517          	auipc	a0,0x14
    80003478:	48c50513          	addi	a0,a0,1164 # 80017900 <bcache>
    8000347c:	ffffd097          	auipc	ra,0xffffd
    80003480:	6b6080e7          	jalr	1718(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003484:	0001c797          	auipc	a5,0x1c
    80003488:	47c78793          	addi	a5,a5,1148 # 8001f900 <bcache+0x8000>
    8000348c:	0001c717          	auipc	a4,0x1c
    80003490:	6dc70713          	addi	a4,a4,1756 # 8001fb68 <bcache+0x8268>
    80003494:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003498:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000349c:	00014497          	auipc	s1,0x14
    800034a0:	47c48493          	addi	s1,s1,1148 # 80017918 <bcache+0x18>
    b->next = bcache.head.next;
    800034a4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034a6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034a8:	00005a17          	auipc	s4,0x5
    800034ac:	278a0a13          	addi	s4,s4,632 # 80008720 <syscalls+0xd0>
    b->next = bcache.head.next;
    800034b0:	2b893783          	ld	a5,696(s2)
    800034b4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034b6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034ba:	85d2                	mv	a1,s4
    800034bc:	01048513          	addi	a0,s1,16
    800034c0:	00001097          	auipc	ra,0x1
    800034c4:	4c2080e7          	jalr	1218(ra) # 80004982 <initsleeplock>
    bcache.head.next->prev = b;
    800034c8:	2b893783          	ld	a5,696(s2)
    800034cc:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034ce:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034d2:	45848493          	addi	s1,s1,1112
    800034d6:	fd349de3          	bne	s1,s3,800034b0 <binit+0x54>
  }
}
    800034da:	70a2                	ld	ra,40(sp)
    800034dc:	7402                	ld	s0,32(sp)
    800034de:	64e2                	ld	s1,24(sp)
    800034e0:	6942                	ld	s2,16(sp)
    800034e2:	69a2                	ld	s3,8(sp)
    800034e4:	6a02                	ld	s4,0(sp)
    800034e6:	6145                	addi	sp,sp,48
    800034e8:	8082                	ret

00000000800034ea <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800034ea:	7179                	addi	sp,sp,-48
    800034ec:	f406                	sd	ra,40(sp)
    800034ee:	f022                	sd	s0,32(sp)
    800034f0:	ec26                	sd	s1,24(sp)
    800034f2:	e84a                	sd	s2,16(sp)
    800034f4:	e44e                	sd	s3,8(sp)
    800034f6:	1800                	addi	s0,sp,48
    800034f8:	892a                	mv	s2,a0
    800034fa:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800034fc:	00014517          	auipc	a0,0x14
    80003500:	40450513          	addi	a0,a0,1028 # 80017900 <bcache>
    80003504:	ffffd097          	auipc	ra,0xffffd
    80003508:	6be080e7          	jalr	1726(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000350c:	0001c497          	auipc	s1,0x1c
    80003510:	6ac4b483          	ld	s1,1708(s1) # 8001fbb8 <bcache+0x82b8>
    80003514:	0001c797          	auipc	a5,0x1c
    80003518:	65478793          	addi	a5,a5,1620 # 8001fb68 <bcache+0x8268>
    8000351c:	02f48f63          	beq	s1,a5,8000355a <bread+0x70>
    80003520:	873e                	mv	a4,a5
    80003522:	a021                	j	8000352a <bread+0x40>
    80003524:	68a4                	ld	s1,80(s1)
    80003526:	02e48a63          	beq	s1,a4,8000355a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000352a:	449c                	lw	a5,8(s1)
    8000352c:	ff279ce3          	bne	a5,s2,80003524 <bread+0x3a>
    80003530:	44dc                	lw	a5,12(s1)
    80003532:	ff3799e3          	bne	a5,s3,80003524 <bread+0x3a>
      b->refcnt++;
    80003536:	40bc                	lw	a5,64(s1)
    80003538:	2785                	addiw	a5,a5,1
    8000353a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000353c:	00014517          	auipc	a0,0x14
    80003540:	3c450513          	addi	a0,a0,964 # 80017900 <bcache>
    80003544:	ffffd097          	auipc	ra,0xffffd
    80003548:	732080e7          	jalr	1842(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000354c:	01048513          	addi	a0,s1,16
    80003550:	00001097          	auipc	ra,0x1
    80003554:	46c080e7          	jalr	1132(ra) # 800049bc <acquiresleep>
      return b;
    80003558:	a8b9                	j	800035b6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000355a:	0001c497          	auipc	s1,0x1c
    8000355e:	6564b483          	ld	s1,1622(s1) # 8001fbb0 <bcache+0x82b0>
    80003562:	0001c797          	auipc	a5,0x1c
    80003566:	60678793          	addi	a5,a5,1542 # 8001fb68 <bcache+0x8268>
    8000356a:	00f48863          	beq	s1,a5,8000357a <bread+0x90>
    8000356e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003570:	40bc                	lw	a5,64(s1)
    80003572:	cf81                	beqz	a5,8000358a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003574:	64a4                	ld	s1,72(s1)
    80003576:	fee49de3          	bne	s1,a4,80003570 <bread+0x86>
  panic("bget: no buffers");
    8000357a:	00005517          	auipc	a0,0x5
    8000357e:	1ae50513          	addi	a0,a0,430 # 80008728 <syscalls+0xd8>
    80003582:	ffffd097          	auipc	ra,0xffffd
    80003586:	fa8080e7          	jalr	-88(ra) # 8000052a <panic>
      b->dev = dev;
    8000358a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000358e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003592:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003596:	4785                	li	a5,1
    80003598:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000359a:	00014517          	auipc	a0,0x14
    8000359e:	36650513          	addi	a0,a0,870 # 80017900 <bcache>
    800035a2:	ffffd097          	auipc	ra,0xffffd
    800035a6:	6d4080e7          	jalr	1748(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800035aa:	01048513          	addi	a0,s1,16
    800035ae:	00001097          	auipc	ra,0x1
    800035b2:	40e080e7          	jalr	1038(ra) # 800049bc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035b6:	409c                	lw	a5,0(s1)
    800035b8:	cb89                	beqz	a5,800035ca <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035ba:	8526                	mv	a0,s1
    800035bc:	70a2                	ld	ra,40(sp)
    800035be:	7402                	ld	s0,32(sp)
    800035c0:	64e2                	ld	s1,24(sp)
    800035c2:	6942                	ld	s2,16(sp)
    800035c4:	69a2                	ld	s3,8(sp)
    800035c6:	6145                	addi	sp,sp,48
    800035c8:	8082                	ret
    virtio_disk_rw(b, 0);
    800035ca:	4581                	li	a1,0
    800035cc:	8526                	mv	a0,s1
    800035ce:	00003097          	auipc	ra,0x3
    800035d2:	f28080e7          	jalr	-216(ra) # 800064f6 <virtio_disk_rw>
    b->valid = 1;
    800035d6:	4785                	li	a5,1
    800035d8:	c09c                	sw	a5,0(s1)
  return b;
    800035da:	b7c5                	j	800035ba <bread+0xd0>

00000000800035dc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035dc:	1101                	addi	sp,sp,-32
    800035de:	ec06                	sd	ra,24(sp)
    800035e0:	e822                	sd	s0,16(sp)
    800035e2:	e426                	sd	s1,8(sp)
    800035e4:	1000                	addi	s0,sp,32
    800035e6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035e8:	0541                	addi	a0,a0,16
    800035ea:	00001097          	auipc	ra,0x1
    800035ee:	46c080e7          	jalr	1132(ra) # 80004a56 <holdingsleep>
    800035f2:	cd01                	beqz	a0,8000360a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800035f4:	4585                	li	a1,1
    800035f6:	8526                	mv	a0,s1
    800035f8:	00003097          	auipc	ra,0x3
    800035fc:	efe080e7          	jalr	-258(ra) # 800064f6 <virtio_disk_rw>
}
    80003600:	60e2                	ld	ra,24(sp)
    80003602:	6442                	ld	s0,16(sp)
    80003604:	64a2                	ld	s1,8(sp)
    80003606:	6105                	addi	sp,sp,32
    80003608:	8082                	ret
    panic("bwrite");
    8000360a:	00005517          	auipc	a0,0x5
    8000360e:	13650513          	addi	a0,a0,310 # 80008740 <syscalls+0xf0>
    80003612:	ffffd097          	auipc	ra,0xffffd
    80003616:	f18080e7          	jalr	-232(ra) # 8000052a <panic>

000000008000361a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000361a:	1101                	addi	sp,sp,-32
    8000361c:	ec06                	sd	ra,24(sp)
    8000361e:	e822                	sd	s0,16(sp)
    80003620:	e426                	sd	s1,8(sp)
    80003622:	e04a                	sd	s2,0(sp)
    80003624:	1000                	addi	s0,sp,32
    80003626:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003628:	01050913          	addi	s2,a0,16
    8000362c:	854a                	mv	a0,s2
    8000362e:	00001097          	auipc	ra,0x1
    80003632:	428080e7          	jalr	1064(ra) # 80004a56 <holdingsleep>
    80003636:	c92d                	beqz	a0,800036a8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003638:	854a                	mv	a0,s2
    8000363a:	00001097          	auipc	ra,0x1
    8000363e:	3d8080e7          	jalr	984(ra) # 80004a12 <releasesleep>

  acquire(&bcache.lock);
    80003642:	00014517          	auipc	a0,0x14
    80003646:	2be50513          	addi	a0,a0,702 # 80017900 <bcache>
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	578080e7          	jalr	1400(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003652:	40bc                	lw	a5,64(s1)
    80003654:	37fd                	addiw	a5,a5,-1
    80003656:	0007871b          	sext.w	a4,a5
    8000365a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000365c:	eb05                	bnez	a4,8000368c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000365e:	68bc                	ld	a5,80(s1)
    80003660:	64b8                	ld	a4,72(s1)
    80003662:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003664:	64bc                	ld	a5,72(s1)
    80003666:	68b8                	ld	a4,80(s1)
    80003668:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000366a:	0001c797          	auipc	a5,0x1c
    8000366e:	29678793          	addi	a5,a5,662 # 8001f900 <bcache+0x8000>
    80003672:	2b87b703          	ld	a4,696(a5)
    80003676:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003678:	0001c717          	auipc	a4,0x1c
    8000367c:	4f070713          	addi	a4,a4,1264 # 8001fb68 <bcache+0x8268>
    80003680:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003682:	2b87b703          	ld	a4,696(a5)
    80003686:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003688:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000368c:	00014517          	auipc	a0,0x14
    80003690:	27450513          	addi	a0,a0,628 # 80017900 <bcache>
    80003694:	ffffd097          	auipc	ra,0xffffd
    80003698:	5e2080e7          	jalr	1506(ra) # 80000c76 <release>
}
    8000369c:	60e2                	ld	ra,24(sp)
    8000369e:	6442                	ld	s0,16(sp)
    800036a0:	64a2                	ld	s1,8(sp)
    800036a2:	6902                	ld	s2,0(sp)
    800036a4:	6105                	addi	sp,sp,32
    800036a6:	8082                	ret
    panic("brelse");
    800036a8:	00005517          	auipc	a0,0x5
    800036ac:	0a050513          	addi	a0,a0,160 # 80008748 <syscalls+0xf8>
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	e7a080e7          	jalr	-390(ra) # 8000052a <panic>

00000000800036b8 <bpin>:

void
bpin(struct buf *b) {
    800036b8:	1101                	addi	sp,sp,-32
    800036ba:	ec06                	sd	ra,24(sp)
    800036bc:	e822                	sd	s0,16(sp)
    800036be:	e426                	sd	s1,8(sp)
    800036c0:	1000                	addi	s0,sp,32
    800036c2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036c4:	00014517          	auipc	a0,0x14
    800036c8:	23c50513          	addi	a0,a0,572 # 80017900 <bcache>
    800036cc:	ffffd097          	auipc	ra,0xffffd
    800036d0:	4f6080e7          	jalr	1270(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800036d4:	40bc                	lw	a5,64(s1)
    800036d6:	2785                	addiw	a5,a5,1
    800036d8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036da:	00014517          	auipc	a0,0x14
    800036de:	22650513          	addi	a0,a0,550 # 80017900 <bcache>
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	594080e7          	jalr	1428(ra) # 80000c76 <release>
}
    800036ea:	60e2                	ld	ra,24(sp)
    800036ec:	6442                	ld	s0,16(sp)
    800036ee:	64a2                	ld	s1,8(sp)
    800036f0:	6105                	addi	sp,sp,32
    800036f2:	8082                	ret

00000000800036f4 <bunpin>:

void
bunpin(struct buf *b) {
    800036f4:	1101                	addi	sp,sp,-32
    800036f6:	ec06                	sd	ra,24(sp)
    800036f8:	e822                	sd	s0,16(sp)
    800036fa:	e426                	sd	s1,8(sp)
    800036fc:	1000                	addi	s0,sp,32
    800036fe:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003700:	00014517          	auipc	a0,0x14
    80003704:	20050513          	addi	a0,a0,512 # 80017900 <bcache>
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	4ba080e7          	jalr	1210(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003710:	40bc                	lw	a5,64(s1)
    80003712:	37fd                	addiw	a5,a5,-1
    80003714:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003716:	00014517          	auipc	a0,0x14
    8000371a:	1ea50513          	addi	a0,a0,490 # 80017900 <bcache>
    8000371e:	ffffd097          	auipc	ra,0xffffd
    80003722:	558080e7          	jalr	1368(ra) # 80000c76 <release>
}
    80003726:	60e2                	ld	ra,24(sp)
    80003728:	6442                	ld	s0,16(sp)
    8000372a:	64a2                	ld	s1,8(sp)
    8000372c:	6105                	addi	sp,sp,32
    8000372e:	8082                	ret

0000000080003730 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003730:	1101                	addi	sp,sp,-32
    80003732:	ec06                	sd	ra,24(sp)
    80003734:	e822                	sd	s0,16(sp)
    80003736:	e426                	sd	s1,8(sp)
    80003738:	e04a                	sd	s2,0(sp)
    8000373a:	1000                	addi	s0,sp,32
    8000373c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000373e:	00d5d59b          	srliw	a1,a1,0xd
    80003742:	0001d797          	auipc	a5,0x1d
    80003746:	89a7a783          	lw	a5,-1894(a5) # 8001ffdc <sb+0x1c>
    8000374a:	9dbd                	addw	a1,a1,a5
    8000374c:	00000097          	auipc	ra,0x0
    80003750:	d9e080e7          	jalr	-610(ra) # 800034ea <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003754:	0074f713          	andi	a4,s1,7
    80003758:	4785                	li	a5,1
    8000375a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000375e:	14ce                	slli	s1,s1,0x33
    80003760:	90d9                	srli	s1,s1,0x36
    80003762:	00950733          	add	a4,a0,s1
    80003766:	05874703          	lbu	a4,88(a4)
    8000376a:	00e7f6b3          	and	a3,a5,a4
    8000376e:	c69d                	beqz	a3,8000379c <bfree+0x6c>
    80003770:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003772:	94aa                	add	s1,s1,a0
    80003774:	fff7c793          	not	a5,a5
    80003778:	8ff9                	and	a5,a5,a4
    8000377a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000377e:	00001097          	auipc	ra,0x1
    80003782:	11e080e7          	jalr	286(ra) # 8000489c <log_write>
  brelse(bp);
    80003786:	854a                	mv	a0,s2
    80003788:	00000097          	auipc	ra,0x0
    8000378c:	e92080e7          	jalr	-366(ra) # 8000361a <brelse>
}
    80003790:	60e2                	ld	ra,24(sp)
    80003792:	6442                	ld	s0,16(sp)
    80003794:	64a2                	ld	s1,8(sp)
    80003796:	6902                	ld	s2,0(sp)
    80003798:	6105                	addi	sp,sp,32
    8000379a:	8082                	ret
    panic("freeing free block");
    8000379c:	00005517          	auipc	a0,0x5
    800037a0:	fb450513          	addi	a0,a0,-76 # 80008750 <syscalls+0x100>
    800037a4:	ffffd097          	auipc	ra,0xffffd
    800037a8:	d86080e7          	jalr	-634(ra) # 8000052a <panic>

00000000800037ac <balloc>:
{
    800037ac:	711d                	addi	sp,sp,-96
    800037ae:	ec86                	sd	ra,88(sp)
    800037b0:	e8a2                	sd	s0,80(sp)
    800037b2:	e4a6                	sd	s1,72(sp)
    800037b4:	e0ca                	sd	s2,64(sp)
    800037b6:	fc4e                	sd	s3,56(sp)
    800037b8:	f852                	sd	s4,48(sp)
    800037ba:	f456                	sd	s5,40(sp)
    800037bc:	f05a                	sd	s6,32(sp)
    800037be:	ec5e                	sd	s7,24(sp)
    800037c0:	e862                	sd	s8,16(sp)
    800037c2:	e466                	sd	s9,8(sp)
    800037c4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037c6:	0001c797          	auipc	a5,0x1c
    800037ca:	7fe7a783          	lw	a5,2046(a5) # 8001ffc4 <sb+0x4>
    800037ce:	cbd1                	beqz	a5,80003862 <balloc+0xb6>
    800037d0:	8baa                	mv	s7,a0
    800037d2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037d4:	0001cb17          	auipc	s6,0x1c
    800037d8:	7ecb0b13          	addi	s6,s6,2028 # 8001ffc0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037dc:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037de:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037e0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800037e2:	6c89                	lui	s9,0x2
    800037e4:	a831                	j	80003800 <balloc+0x54>
    brelse(bp);
    800037e6:	854a                	mv	a0,s2
    800037e8:	00000097          	auipc	ra,0x0
    800037ec:	e32080e7          	jalr	-462(ra) # 8000361a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800037f0:	015c87bb          	addw	a5,s9,s5
    800037f4:	00078a9b          	sext.w	s5,a5
    800037f8:	004b2703          	lw	a4,4(s6)
    800037fc:	06eaf363          	bgeu	s5,a4,80003862 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003800:	41fad79b          	sraiw	a5,s5,0x1f
    80003804:	0137d79b          	srliw	a5,a5,0x13
    80003808:	015787bb          	addw	a5,a5,s5
    8000380c:	40d7d79b          	sraiw	a5,a5,0xd
    80003810:	01cb2583          	lw	a1,28(s6)
    80003814:	9dbd                	addw	a1,a1,a5
    80003816:	855e                	mv	a0,s7
    80003818:	00000097          	auipc	ra,0x0
    8000381c:	cd2080e7          	jalr	-814(ra) # 800034ea <bread>
    80003820:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003822:	004b2503          	lw	a0,4(s6)
    80003826:	000a849b          	sext.w	s1,s5
    8000382a:	8662                	mv	a2,s8
    8000382c:	faa4fde3          	bgeu	s1,a0,800037e6 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003830:	41f6579b          	sraiw	a5,a2,0x1f
    80003834:	01d7d69b          	srliw	a3,a5,0x1d
    80003838:	00c6873b          	addw	a4,a3,a2
    8000383c:	00777793          	andi	a5,a4,7
    80003840:	9f95                	subw	a5,a5,a3
    80003842:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003846:	4037571b          	sraiw	a4,a4,0x3
    8000384a:	00e906b3          	add	a3,s2,a4
    8000384e:	0586c683          	lbu	a3,88(a3)
    80003852:	00d7f5b3          	and	a1,a5,a3
    80003856:	cd91                	beqz	a1,80003872 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003858:	2605                	addiw	a2,a2,1
    8000385a:	2485                	addiw	s1,s1,1
    8000385c:	fd4618e3          	bne	a2,s4,8000382c <balloc+0x80>
    80003860:	b759                	j	800037e6 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003862:	00005517          	auipc	a0,0x5
    80003866:	f0650513          	addi	a0,a0,-250 # 80008768 <syscalls+0x118>
    8000386a:	ffffd097          	auipc	ra,0xffffd
    8000386e:	cc0080e7          	jalr	-832(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003872:	974a                	add	a4,a4,s2
    80003874:	8fd5                	or	a5,a5,a3
    80003876:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000387a:	854a                	mv	a0,s2
    8000387c:	00001097          	auipc	ra,0x1
    80003880:	020080e7          	jalr	32(ra) # 8000489c <log_write>
        brelse(bp);
    80003884:	854a                	mv	a0,s2
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	d94080e7          	jalr	-620(ra) # 8000361a <brelse>
  bp = bread(dev, bno);
    8000388e:	85a6                	mv	a1,s1
    80003890:	855e                	mv	a0,s7
    80003892:	00000097          	auipc	ra,0x0
    80003896:	c58080e7          	jalr	-936(ra) # 800034ea <bread>
    8000389a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000389c:	40000613          	li	a2,1024
    800038a0:	4581                	li	a1,0
    800038a2:	05850513          	addi	a0,a0,88
    800038a6:	ffffd097          	auipc	ra,0xffffd
    800038aa:	418080e7          	jalr	1048(ra) # 80000cbe <memset>
  log_write(bp);
    800038ae:	854a                	mv	a0,s2
    800038b0:	00001097          	auipc	ra,0x1
    800038b4:	fec080e7          	jalr	-20(ra) # 8000489c <log_write>
  brelse(bp);
    800038b8:	854a                	mv	a0,s2
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	d60080e7          	jalr	-672(ra) # 8000361a <brelse>
}
    800038c2:	8526                	mv	a0,s1
    800038c4:	60e6                	ld	ra,88(sp)
    800038c6:	6446                	ld	s0,80(sp)
    800038c8:	64a6                	ld	s1,72(sp)
    800038ca:	6906                	ld	s2,64(sp)
    800038cc:	79e2                	ld	s3,56(sp)
    800038ce:	7a42                	ld	s4,48(sp)
    800038d0:	7aa2                	ld	s5,40(sp)
    800038d2:	7b02                	ld	s6,32(sp)
    800038d4:	6be2                	ld	s7,24(sp)
    800038d6:	6c42                	ld	s8,16(sp)
    800038d8:	6ca2                	ld	s9,8(sp)
    800038da:	6125                	addi	sp,sp,96
    800038dc:	8082                	ret

00000000800038de <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800038de:	7179                	addi	sp,sp,-48
    800038e0:	f406                	sd	ra,40(sp)
    800038e2:	f022                	sd	s0,32(sp)
    800038e4:	ec26                	sd	s1,24(sp)
    800038e6:	e84a                	sd	s2,16(sp)
    800038e8:	e44e                	sd	s3,8(sp)
    800038ea:	e052                	sd	s4,0(sp)
    800038ec:	1800                	addi	s0,sp,48
    800038ee:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800038f0:	47ad                	li	a5,11
    800038f2:	04b7fe63          	bgeu	a5,a1,8000394e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800038f6:	ff45849b          	addiw	s1,a1,-12
    800038fa:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800038fe:	0ff00793          	li	a5,255
    80003902:	0ae7e463          	bltu	a5,a4,800039aa <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003906:	08052583          	lw	a1,128(a0)
    8000390a:	c5b5                	beqz	a1,80003976 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000390c:	00092503          	lw	a0,0(s2)
    80003910:	00000097          	auipc	ra,0x0
    80003914:	bda080e7          	jalr	-1062(ra) # 800034ea <bread>
    80003918:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000391a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000391e:	02049713          	slli	a4,s1,0x20
    80003922:	01e75593          	srli	a1,a4,0x1e
    80003926:	00b784b3          	add	s1,a5,a1
    8000392a:	0004a983          	lw	s3,0(s1)
    8000392e:	04098e63          	beqz	s3,8000398a <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003932:	8552                	mv	a0,s4
    80003934:	00000097          	auipc	ra,0x0
    80003938:	ce6080e7          	jalr	-794(ra) # 8000361a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000393c:	854e                	mv	a0,s3
    8000393e:	70a2                	ld	ra,40(sp)
    80003940:	7402                	ld	s0,32(sp)
    80003942:	64e2                	ld	s1,24(sp)
    80003944:	6942                	ld	s2,16(sp)
    80003946:	69a2                	ld	s3,8(sp)
    80003948:	6a02                	ld	s4,0(sp)
    8000394a:	6145                	addi	sp,sp,48
    8000394c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000394e:	02059793          	slli	a5,a1,0x20
    80003952:	01e7d593          	srli	a1,a5,0x1e
    80003956:	00b504b3          	add	s1,a0,a1
    8000395a:	0504a983          	lw	s3,80(s1)
    8000395e:	fc099fe3          	bnez	s3,8000393c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003962:	4108                	lw	a0,0(a0)
    80003964:	00000097          	auipc	ra,0x0
    80003968:	e48080e7          	jalr	-440(ra) # 800037ac <balloc>
    8000396c:	0005099b          	sext.w	s3,a0
    80003970:	0534a823          	sw	s3,80(s1)
    80003974:	b7e1                	j	8000393c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003976:	4108                	lw	a0,0(a0)
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	e34080e7          	jalr	-460(ra) # 800037ac <balloc>
    80003980:	0005059b          	sext.w	a1,a0
    80003984:	08b92023          	sw	a1,128(s2)
    80003988:	b751                	j	8000390c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000398a:	00092503          	lw	a0,0(s2)
    8000398e:	00000097          	auipc	ra,0x0
    80003992:	e1e080e7          	jalr	-482(ra) # 800037ac <balloc>
    80003996:	0005099b          	sext.w	s3,a0
    8000399a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000399e:	8552                	mv	a0,s4
    800039a0:	00001097          	auipc	ra,0x1
    800039a4:	efc080e7          	jalr	-260(ra) # 8000489c <log_write>
    800039a8:	b769                	j	80003932 <bmap+0x54>
  panic("bmap: out of range");
    800039aa:	00005517          	auipc	a0,0x5
    800039ae:	dd650513          	addi	a0,a0,-554 # 80008780 <syscalls+0x130>
    800039b2:	ffffd097          	auipc	ra,0xffffd
    800039b6:	b78080e7          	jalr	-1160(ra) # 8000052a <panic>

00000000800039ba <iget>:
{
    800039ba:	7179                	addi	sp,sp,-48
    800039bc:	f406                	sd	ra,40(sp)
    800039be:	f022                	sd	s0,32(sp)
    800039c0:	ec26                	sd	s1,24(sp)
    800039c2:	e84a                	sd	s2,16(sp)
    800039c4:	e44e                	sd	s3,8(sp)
    800039c6:	e052                	sd	s4,0(sp)
    800039c8:	1800                	addi	s0,sp,48
    800039ca:	89aa                	mv	s3,a0
    800039cc:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039ce:	0001c517          	auipc	a0,0x1c
    800039d2:	61250513          	addi	a0,a0,1554 # 8001ffe0 <itable>
    800039d6:	ffffd097          	auipc	ra,0xffffd
    800039da:	1ec080e7          	jalr	492(ra) # 80000bc2 <acquire>
  empty = 0;
    800039de:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039e0:	0001c497          	auipc	s1,0x1c
    800039e4:	61848493          	addi	s1,s1,1560 # 8001fff8 <itable+0x18>
    800039e8:	0001e697          	auipc	a3,0x1e
    800039ec:	0a068693          	addi	a3,a3,160 # 80021a88 <log>
    800039f0:	a039                	j	800039fe <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039f2:	02090b63          	beqz	s2,80003a28 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039f6:	08848493          	addi	s1,s1,136
    800039fa:	02d48a63          	beq	s1,a3,80003a2e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800039fe:	449c                	lw	a5,8(s1)
    80003a00:	fef059e3          	blez	a5,800039f2 <iget+0x38>
    80003a04:	4098                	lw	a4,0(s1)
    80003a06:	ff3716e3          	bne	a4,s3,800039f2 <iget+0x38>
    80003a0a:	40d8                	lw	a4,4(s1)
    80003a0c:	ff4713e3          	bne	a4,s4,800039f2 <iget+0x38>
      ip->ref++;
    80003a10:	2785                	addiw	a5,a5,1
    80003a12:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a14:	0001c517          	auipc	a0,0x1c
    80003a18:	5cc50513          	addi	a0,a0,1484 # 8001ffe0 <itable>
    80003a1c:	ffffd097          	auipc	ra,0xffffd
    80003a20:	25a080e7          	jalr	602(ra) # 80000c76 <release>
      return ip;
    80003a24:	8926                	mv	s2,s1
    80003a26:	a03d                	j	80003a54 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a28:	f7f9                	bnez	a5,800039f6 <iget+0x3c>
    80003a2a:	8926                	mv	s2,s1
    80003a2c:	b7e9                	j	800039f6 <iget+0x3c>
  if(empty == 0)
    80003a2e:	02090c63          	beqz	s2,80003a66 <iget+0xac>
  ip->dev = dev;
    80003a32:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a36:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a3a:	4785                	li	a5,1
    80003a3c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a40:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a44:	0001c517          	auipc	a0,0x1c
    80003a48:	59c50513          	addi	a0,a0,1436 # 8001ffe0 <itable>
    80003a4c:	ffffd097          	auipc	ra,0xffffd
    80003a50:	22a080e7          	jalr	554(ra) # 80000c76 <release>
}
    80003a54:	854a                	mv	a0,s2
    80003a56:	70a2                	ld	ra,40(sp)
    80003a58:	7402                	ld	s0,32(sp)
    80003a5a:	64e2                	ld	s1,24(sp)
    80003a5c:	6942                	ld	s2,16(sp)
    80003a5e:	69a2                	ld	s3,8(sp)
    80003a60:	6a02                	ld	s4,0(sp)
    80003a62:	6145                	addi	sp,sp,48
    80003a64:	8082                	ret
    panic("iget: no inodes");
    80003a66:	00005517          	auipc	a0,0x5
    80003a6a:	d3250513          	addi	a0,a0,-718 # 80008798 <syscalls+0x148>
    80003a6e:	ffffd097          	auipc	ra,0xffffd
    80003a72:	abc080e7          	jalr	-1348(ra) # 8000052a <panic>

0000000080003a76 <fsinit>:
fsinit(int dev) {
    80003a76:	7179                	addi	sp,sp,-48
    80003a78:	f406                	sd	ra,40(sp)
    80003a7a:	f022                	sd	s0,32(sp)
    80003a7c:	ec26                	sd	s1,24(sp)
    80003a7e:	e84a                	sd	s2,16(sp)
    80003a80:	e44e                	sd	s3,8(sp)
    80003a82:	1800                	addi	s0,sp,48
    80003a84:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a86:	4585                	li	a1,1
    80003a88:	00000097          	auipc	ra,0x0
    80003a8c:	a62080e7          	jalr	-1438(ra) # 800034ea <bread>
    80003a90:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a92:	0001c997          	auipc	s3,0x1c
    80003a96:	52e98993          	addi	s3,s3,1326 # 8001ffc0 <sb>
    80003a9a:	02000613          	li	a2,32
    80003a9e:	05850593          	addi	a1,a0,88
    80003aa2:	854e                	mv	a0,s3
    80003aa4:	ffffd097          	auipc	ra,0xffffd
    80003aa8:	276080e7          	jalr	630(ra) # 80000d1a <memmove>
  brelse(bp);
    80003aac:	8526                	mv	a0,s1
    80003aae:	00000097          	auipc	ra,0x0
    80003ab2:	b6c080e7          	jalr	-1172(ra) # 8000361a <brelse>
  if(sb.magic != FSMAGIC)
    80003ab6:	0009a703          	lw	a4,0(s3)
    80003aba:	102037b7          	lui	a5,0x10203
    80003abe:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ac2:	02f71263          	bne	a4,a5,80003ae6 <fsinit+0x70>
  initlog(dev, &sb);
    80003ac6:	0001c597          	auipc	a1,0x1c
    80003aca:	4fa58593          	addi	a1,a1,1274 # 8001ffc0 <sb>
    80003ace:	854a                	mv	a0,s2
    80003ad0:	00001097          	auipc	ra,0x1
    80003ad4:	b4e080e7          	jalr	-1202(ra) # 8000461e <initlog>
}
    80003ad8:	70a2                	ld	ra,40(sp)
    80003ada:	7402                	ld	s0,32(sp)
    80003adc:	64e2                	ld	s1,24(sp)
    80003ade:	6942                	ld	s2,16(sp)
    80003ae0:	69a2                	ld	s3,8(sp)
    80003ae2:	6145                	addi	sp,sp,48
    80003ae4:	8082                	ret
    panic("invalid file system");
    80003ae6:	00005517          	auipc	a0,0x5
    80003aea:	cc250513          	addi	a0,a0,-830 # 800087a8 <syscalls+0x158>
    80003aee:	ffffd097          	auipc	ra,0xffffd
    80003af2:	a3c080e7          	jalr	-1476(ra) # 8000052a <panic>

0000000080003af6 <iinit>:
{
    80003af6:	7179                	addi	sp,sp,-48
    80003af8:	f406                	sd	ra,40(sp)
    80003afa:	f022                	sd	s0,32(sp)
    80003afc:	ec26                	sd	s1,24(sp)
    80003afe:	e84a                	sd	s2,16(sp)
    80003b00:	e44e                	sd	s3,8(sp)
    80003b02:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b04:	00005597          	auipc	a1,0x5
    80003b08:	cbc58593          	addi	a1,a1,-836 # 800087c0 <syscalls+0x170>
    80003b0c:	0001c517          	auipc	a0,0x1c
    80003b10:	4d450513          	addi	a0,a0,1236 # 8001ffe0 <itable>
    80003b14:	ffffd097          	auipc	ra,0xffffd
    80003b18:	01e080e7          	jalr	30(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b1c:	0001c497          	auipc	s1,0x1c
    80003b20:	4ec48493          	addi	s1,s1,1260 # 80020008 <itable+0x28>
    80003b24:	0001e997          	auipc	s3,0x1e
    80003b28:	f7498993          	addi	s3,s3,-140 # 80021a98 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b2c:	00005917          	auipc	s2,0x5
    80003b30:	c9c90913          	addi	s2,s2,-868 # 800087c8 <syscalls+0x178>
    80003b34:	85ca                	mv	a1,s2
    80003b36:	8526                	mv	a0,s1
    80003b38:	00001097          	auipc	ra,0x1
    80003b3c:	e4a080e7          	jalr	-438(ra) # 80004982 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b40:	08848493          	addi	s1,s1,136
    80003b44:	ff3498e3          	bne	s1,s3,80003b34 <iinit+0x3e>
}
    80003b48:	70a2                	ld	ra,40(sp)
    80003b4a:	7402                	ld	s0,32(sp)
    80003b4c:	64e2                	ld	s1,24(sp)
    80003b4e:	6942                	ld	s2,16(sp)
    80003b50:	69a2                	ld	s3,8(sp)
    80003b52:	6145                	addi	sp,sp,48
    80003b54:	8082                	ret

0000000080003b56 <ialloc>:
{
    80003b56:	715d                	addi	sp,sp,-80
    80003b58:	e486                	sd	ra,72(sp)
    80003b5a:	e0a2                	sd	s0,64(sp)
    80003b5c:	fc26                	sd	s1,56(sp)
    80003b5e:	f84a                	sd	s2,48(sp)
    80003b60:	f44e                	sd	s3,40(sp)
    80003b62:	f052                	sd	s4,32(sp)
    80003b64:	ec56                	sd	s5,24(sp)
    80003b66:	e85a                	sd	s6,16(sp)
    80003b68:	e45e                	sd	s7,8(sp)
    80003b6a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b6c:	0001c717          	auipc	a4,0x1c
    80003b70:	46072703          	lw	a4,1120(a4) # 8001ffcc <sb+0xc>
    80003b74:	4785                	li	a5,1
    80003b76:	04e7fa63          	bgeu	a5,a4,80003bca <ialloc+0x74>
    80003b7a:	8aaa                	mv	s5,a0
    80003b7c:	8bae                	mv	s7,a1
    80003b7e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b80:	0001ca17          	auipc	s4,0x1c
    80003b84:	440a0a13          	addi	s4,s4,1088 # 8001ffc0 <sb>
    80003b88:	00048b1b          	sext.w	s6,s1
    80003b8c:	0044d793          	srli	a5,s1,0x4
    80003b90:	018a2583          	lw	a1,24(s4)
    80003b94:	9dbd                	addw	a1,a1,a5
    80003b96:	8556                	mv	a0,s5
    80003b98:	00000097          	auipc	ra,0x0
    80003b9c:	952080e7          	jalr	-1710(ra) # 800034ea <bread>
    80003ba0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ba2:	05850993          	addi	s3,a0,88
    80003ba6:	00f4f793          	andi	a5,s1,15
    80003baa:	079a                	slli	a5,a5,0x6
    80003bac:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003bae:	00099783          	lh	a5,0(s3)
    80003bb2:	c785                	beqz	a5,80003bda <ialloc+0x84>
    brelse(bp);
    80003bb4:	00000097          	auipc	ra,0x0
    80003bb8:	a66080e7          	jalr	-1434(ra) # 8000361a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bbc:	0485                	addi	s1,s1,1
    80003bbe:	00ca2703          	lw	a4,12(s4)
    80003bc2:	0004879b          	sext.w	a5,s1
    80003bc6:	fce7e1e3          	bltu	a5,a4,80003b88 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003bca:	00005517          	auipc	a0,0x5
    80003bce:	c0650513          	addi	a0,a0,-1018 # 800087d0 <syscalls+0x180>
    80003bd2:	ffffd097          	auipc	ra,0xffffd
    80003bd6:	958080e7          	jalr	-1704(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003bda:	04000613          	li	a2,64
    80003bde:	4581                	li	a1,0
    80003be0:	854e                	mv	a0,s3
    80003be2:	ffffd097          	auipc	ra,0xffffd
    80003be6:	0dc080e7          	jalr	220(ra) # 80000cbe <memset>
      dip->type = type;
    80003bea:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003bee:	854a                	mv	a0,s2
    80003bf0:	00001097          	auipc	ra,0x1
    80003bf4:	cac080e7          	jalr	-852(ra) # 8000489c <log_write>
      brelse(bp);
    80003bf8:	854a                	mv	a0,s2
    80003bfa:	00000097          	auipc	ra,0x0
    80003bfe:	a20080e7          	jalr	-1504(ra) # 8000361a <brelse>
      return iget(dev, inum);
    80003c02:	85da                	mv	a1,s6
    80003c04:	8556                	mv	a0,s5
    80003c06:	00000097          	auipc	ra,0x0
    80003c0a:	db4080e7          	jalr	-588(ra) # 800039ba <iget>
}
    80003c0e:	60a6                	ld	ra,72(sp)
    80003c10:	6406                	ld	s0,64(sp)
    80003c12:	74e2                	ld	s1,56(sp)
    80003c14:	7942                	ld	s2,48(sp)
    80003c16:	79a2                	ld	s3,40(sp)
    80003c18:	7a02                	ld	s4,32(sp)
    80003c1a:	6ae2                	ld	s5,24(sp)
    80003c1c:	6b42                	ld	s6,16(sp)
    80003c1e:	6ba2                	ld	s7,8(sp)
    80003c20:	6161                	addi	sp,sp,80
    80003c22:	8082                	ret

0000000080003c24 <iupdate>:
{
    80003c24:	1101                	addi	sp,sp,-32
    80003c26:	ec06                	sd	ra,24(sp)
    80003c28:	e822                	sd	s0,16(sp)
    80003c2a:	e426                	sd	s1,8(sp)
    80003c2c:	e04a                	sd	s2,0(sp)
    80003c2e:	1000                	addi	s0,sp,32
    80003c30:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c32:	415c                	lw	a5,4(a0)
    80003c34:	0047d79b          	srliw	a5,a5,0x4
    80003c38:	0001c597          	auipc	a1,0x1c
    80003c3c:	3a05a583          	lw	a1,928(a1) # 8001ffd8 <sb+0x18>
    80003c40:	9dbd                	addw	a1,a1,a5
    80003c42:	4108                	lw	a0,0(a0)
    80003c44:	00000097          	auipc	ra,0x0
    80003c48:	8a6080e7          	jalr	-1882(ra) # 800034ea <bread>
    80003c4c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c4e:	05850793          	addi	a5,a0,88
    80003c52:	40c8                	lw	a0,4(s1)
    80003c54:	893d                	andi	a0,a0,15
    80003c56:	051a                	slli	a0,a0,0x6
    80003c58:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c5a:	04449703          	lh	a4,68(s1)
    80003c5e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c62:	04649703          	lh	a4,70(s1)
    80003c66:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c6a:	04849703          	lh	a4,72(s1)
    80003c6e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c72:	04a49703          	lh	a4,74(s1)
    80003c76:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c7a:	44f8                	lw	a4,76(s1)
    80003c7c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c7e:	03400613          	li	a2,52
    80003c82:	05048593          	addi	a1,s1,80
    80003c86:	0531                	addi	a0,a0,12
    80003c88:	ffffd097          	auipc	ra,0xffffd
    80003c8c:	092080e7          	jalr	146(ra) # 80000d1a <memmove>
  log_write(bp);
    80003c90:	854a                	mv	a0,s2
    80003c92:	00001097          	auipc	ra,0x1
    80003c96:	c0a080e7          	jalr	-1014(ra) # 8000489c <log_write>
  brelse(bp);
    80003c9a:	854a                	mv	a0,s2
    80003c9c:	00000097          	auipc	ra,0x0
    80003ca0:	97e080e7          	jalr	-1666(ra) # 8000361a <brelse>
}
    80003ca4:	60e2                	ld	ra,24(sp)
    80003ca6:	6442                	ld	s0,16(sp)
    80003ca8:	64a2                	ld	s1,8(sp)
    80003caa:	6902                	ld	s2,0(sp)
    80003cac:	6105                	addi	sp,sp,32
    80003cae:	8082                	ret

0000000080003cb0 <idup>:
{
    80003cb0:	1101                	addi	sp,sp,-32
    80003cb2:	ec06                	sd	ra,24(sp)
    80003cb4:	e822                	sd	s0,16(sp)
    80003cb6:	e426                	sd	s1,8(sp)
    80003cb8:	1000                	addi	s0,sp,32
    80003cba:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cbc:	0001c517          	auipc	a0,0x1c
    80003cc0:	32450513          	addi	a0,a0,804 # 8001ffe0 <itable>
    80003cc4:	ffffd097          	auipc	ra,0xffffd
    80003cc8:	efe080e7          	jalr	-258(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003ccc:	449c                	lw	a5,8(s1)
    80003cce:	2785                	addiw	a5,a5,1
    80003cd0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cd2:	0001c517          	auipc	a0,0x1c
    80003cd6:	30e50513          	addi	a0,a0,782 # 8001ffe0 <itable>
    80003cda:	ffffd097          	auipc	ra,0xffffd
    80003cde:	f9c080e7          	jalr	-100(ra) # 80000c76 <release>
}
    80003ce2:	8526                	mv	a0,s1
    80003ce4:	60e2                	ld	ra,24(sp)
    80003ce6:	6442                	ld	s0,16(sp)
    80003ce8:	64a2                	ld	s1,8(sp)
    80003cea:	6105                	addi	sp,sp,32
    80003cec:	8082                	ret

0000000080003cee <ilock>:
{
    80003cee:	1101                	addi	sp,sp,-32
    80003cf0:	ec06                	sd	ra,24(sp)
    80003cf2:	e822                	sd	s0,16(sp)
    80003cf4:	e426                	sd	s1,8(sp)
    80003cf6:	e04a                	sd	s2,0(sp)
    80003cf8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003cfa:	c115                	beqz	a0,80003d1e <ilock+0x30>
    80003cfc:	84aa                	mv	s1,a0
    80003cfe:	451c                	lw	a5,8(a0)
    80003d00:	00f05f63          	blez	a5,80003d1e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d04:	0541                	addi	a0,a0,16
    80003d06:	00001097          	auipc	ra,0x1
    80003d0a:	cb6080e7          	jalr	-842(ra) # 800049bc <acquiresleep>
  if(ip->valid == 0){
    80003d0e:	40bc                	lw	a5,64(s1)
    80003d10:	cf99                	beqz	a5,80003d2e <ilock+0x40>
}
    80003d12:	60e2                	ld	ra,24(sp)
    80003d14:	6442                	ld	s0,16(sp)
    80003d16:	64a2                	ld	s1,8(sp)
    80003d18:	6902                	ld	s2,0(sp)
    80003d1a:	6105                	addi	sp,sp,32
    80003d1c:	8082                	ret
    panic("ilock");
    80003d1e:	00005517          	auipc	a0,0x5
    80003d22:	aca50513          	addi	a0,a0,-1334 # 800087e8 <syscalls+0x198>
    80003d26:	ffffd097          	auipc	ra,0xffffd
    80003d2a:	804080e7          	jalr	-2044(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d2e:	40dc                	lw	a5,4(s1)
    80003d30:	0047d79b          	srliw	a5,a5,0x4
    80003d34:	0001c597          	auipc	a1,0x1c
    80003d38:	2a45a583          	lw	a1,676(a1) # 8001ffd8 <sb+0x18>
    80003d3c:	9dbd                	addw	a1,a1,a5
    80003d3e:	4088                	lw	a0,0(s1)
    80003d40:	fffff097          	auipc	ra,0xfffff
    80003d44:	7aa080e7          	jalr	1962(ra) # 800034ea <bread>
    80003d48:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d4a:	05850593          	addi	a1,a0,88
    80003d4e:	40dc                	lw	a5,4(s1)
    80003d50:	8bbd                	andi	a5,a5,15
    80003d52:	079a                	slli	a5,a5,0x6
    80003d54:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d56:	00059783          	lh	a5,0(a1)
    80003d5a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d5e:	00259783          	lh	a5,2(a1)
    80003d62:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d66:	00459783          	lh	a5,4(a1)
    80003d6a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d6e:	00659783          	lh	a5,6(a1)
    80003d72:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d76:	459c                	lw	a5,8(a1)
    80003d78:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d7a:	03400613          	li	a2,52
    80003d7e:	05b1                	addi	a1,a1,12
    80003d80:	05048513          	addi	a0,s1,80
    80003d84:	ffffd097          	auipc	ra,0xffffd
    80003d88:	f96080e7          	jalr	-106(ra) # 80000d1a <memmove>
    brelse(bp);
    80003d8c:	854a                	mv	a0,s2
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	88c080e7          	jalr	-1908(ra) # 8000361a <brelse>
    ip->valid = 1;
    80003d96:	4785                	li	a5,1
    80003d98:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d9a:	04449783          	lh	a5,68(s1)
    80003d9e:	fbb5                	bnez	a5,80003d12 <ilock+0x24>
      panic("ilock: no type");
    80003da0:	00005517          	auipc	a0,0x5
    80003da4:	a5050513          	addi	a0,a0,-1456 # 800087f0 <syscalls+0x1a0>
    80003da8:	ffffc097          	auipc	ra,0xffffc
    80003dac:	782080e7          	jalr	1922(ra) # 8000052a <panic>

0000000080003db0 <iunlock>:
{
    80003db0:	1101                	addi	sp,sp,-32
    80003db2:	ec06                	sd	ra,24(sp)
    80003db4:	e822                	sd	s0,16(sp)
    80003db6:	e426                	sd	s1,8(sp)
    80003db8:	e04a                	sd	s2,0(sp)
    80003dba:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003dbc:	c905                	beqz	a0,80003dec <iunlock+0x3c>
    80003dbe:	84aa                	mv	s1,a0
    80003dc0:	01050913          	addi	s2,a0,16
    80003dc4:	854a                	mv	a0,s2
    80003dc6:	00001097          	auipc	ra,0x1
    80003dca:	c90080e7          	jalr	-880(ra) # 80004a56 <holdingsleep>
    80003dce:	cd19                	beqz	a0,80003dec <iunlock+0x3c>
    80003dd0:	449c                	lw	a5,8(s1)
    80003dd2:	00f05d63          	blez	a5,80003dec <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003dd6:	854a                	mv	a0,s2
    80003dd8:	00001097          	auipc	ra,0x1
    80003ddc:	c3a080e7          	jalr	-966(ra) # 80004a12 <releasesleep>
}
    80003de0:	60e2                	ld	ra,24(sp)
    80003de2:	6442                	ld	s0,16(sp)
    80003de4:	64a2                	ld	s1,8(sp)
    80003de6:	6902                	ld	s2,0(sp)
    80003de8:	6105                	addi	sp,sp,32
    80003dea:	8082                	ret
    panic("iunlock");
    80003dec:	00005517          	auipc	a0,0x5
    80003df0:	a1450513          	addi	a0,a0,-1516 # 80008800 <syscalls+0x1b0>
    80003df4:	ffffc097          	auipc	ra,0xffffc
    80003df8:	736080e7          	jalr	1846(ra) # 8000052a <panic>

0000000080003dfc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003dfc:	7179                	addi	sp,sp,-48
    80003dfe:	f406                	sd	ra,40(sp)
    80003e00:	f022                	sd	s0,32(sp)
    80003e02:	ec26                	sd	s1,24(sp)
    80003e04:	e84a                	sd	s2,16(sp)
    80003e06:	e44e                	sd	s3,8(sp)
    80003e08:	e052                	sd	s4,0(sp)
    80003e0a:	1800                	addi	s0,sp,48
    80003e0c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e0e:	05050493          	addi	s1,a0,80
    80003e12:	08050913          	addi	s2,a0,128
    80003e16:	a021                	j	80003e1e <itrunc+0x22>
    80003e18:	0491                	addi	s1,s1,4
    80003e1a:	01248d63          	beq	s1,s2,80003e34 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e1e:	408c                	lw	a1,0(s1)
    80003e20:	dde5                	beqz	a1,80003e18 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e22:	0009a503          	lw	a0,0(s3)
    80003e26:	00000097          	auipc	ra,0x0
    80003e2a:	90a080e7          	jalr	-1782(ra) # 80003730 <bfree>
      ip->addrs[i] = 0;
    80003e2e:	0004a023          	sw	zero,0(s1)
    80003e32:	b7dd                	j	80003e18 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e34:	0809a583          	lw	a1,128(s3)
    80003e38:	e185                	bnez	a1,80003e58 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e3a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e3e:	854e                	mv	a0,s3
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	de4080e7          	jalr	-540(ra) # 80003c24 <iupdate>
}
    80003e48:	70a2                	ld	ra,40(sp)
    80003e4a:	7402                	ld	s0,32(sp)
    80003e4c:	64e2                	ld	s1,24(sp)
    80003e4e:	6942                	ld	s2,16(sp)
    80003e50:	69a2                	ld	s3,8(sp)
    80003e52:	6a02                	ld	s4,0(sp)
    80003e54:	6145                	addi	sp,sp,48
    80003e56:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e58:	0009a503          	lw	a0,0(s3)
    80003e5c:	fffff097          	auipc	ra,0xfffff
    80003e60:	68e080e7          	jalr	1678(ra) # 800034ea <bread>
    80003e64:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e66:	05850493          	addi	s1,a0,88
    80003e6a:	45850913          	addi	s2,a0,1112
    80003e6e:	a021                	j	80003e76 <itrunc+0x7a>
    80003e70:	0491                	addi	s1,s1,4
    80003e72:	01248b63          	beq	s1,s2,80003e88 <itrunc+0x8c>
      if(a[j])
    80003e76:	408c                	lw	a1,0(s1)
    80003e78:	dde5                	beqz	a1,80003e70 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003e7a:	0009a503          	lw	a0,0(s3)
    80003e7e:	00000097          	auipc	ra,0x0
    80003e82:	8b2080e7          	jalr	-1870(ra) # 80003730 <bfree>
    80003e86:	b7ed                	j	80003e70 <itrunc+0x74>
    brelse(bp);
    80003e88:	8552                	mv	a0,s4
    80003e8a:	fffff097          	auipc	ra,0xfffff
    80003e8e:	790080e7          	jalr	1936(ra) # 8000361a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e92:	0809a583          	lw	a1,128(s3)
    80003e96:	0009a503          	lw	a0,0(s3)
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	896080e7          	jalr	-1898(ra) # 80003730 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ea2:	0809a023          	sw	zero,128(s3)
    80003ea6:	bf51                	j	80003e3a <itrunc+0x3e>

0000000080003ea8 <iput>:
{
    80003ea8:	1101                	addi	sp,sp,-32
    80003eaa:	ec06                	sd	ra,24(sp)
    80003eac:	e822                	sd	s0,16(sp)
    80003eae:	e426                	sd	s1,8(sp)
    80003eb0:	e04a                	sd	s2,0(sp)
    80003eb2:	1000                	addi	s0,sp,32
    80003eb4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003eb6:	0001c517          	auipc	a0,0x1c
    80003eba:	12a50513          	addi	a0,a0,298 # 8001ffe0 <itable>
    80003ebe:	ffffd097          	auipc	ra,0xffffd
    80003ec2:	d04080e7          	jalr	-764(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ec6:	4498                	lw	a4,8(s1)
    80003ec8:	4785                	li	a5,1
    80003eca:	02f70363          	beq	a4,a5,80003ef0 <iput+0x48>
  ip->ref--;
    80003ece:	449c                	lw	a5,8(s1)
    80003ed0:	37fd                	addiw	a5,a5,-1
    80003ed2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ed4:	0001c517          	auipc	a0,0x1c
    80003ed8:	10c50513          	addi	a0,a0,268 # 8001ffe0 <itable>
    80003edc:	ffffd097          	auipc	ra,0xffffd
    80003ee0:	d9a080e7          	jalr	-614(ra) # 80000c76 <release>
}
    80003ee4:	60e2                	ld	ra,24(sp)
    80003ee6:	6442                	ld	s0,16(sp)
    80003ee8:	64a2                	ld	s1,8(sp)
    80003eea:	6902                	ld	s2,0(sp)
    80003eec:	6105                	addi	sp,sp,32
    80003eee:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ef0:	40bc                	lw	a5,64(s1)
    80003ef2:	dff1                	beqz	a5,80003ece <iput+0x26>
    80003ef4:	04a49783          	lh	a5,74(s1)
    80003ef8:	fbf9                	bnez	a5,80003ece <iput+0x26>
    acquiresleep(&ip->lock);
    80003efa:	01048913          	addi	s2,s1,16
    80003efe:	854a                	mv	a0,s2
    80003f00:	00001097          	auipc	ra,0x1
    80003f04:	abc080e7          	jalr	-1348(ra) # 800049bc <acquiresleep>
    release(&itable.lock);
    80003f08:	0001c517          	auipc	a0,0x1c
    80003f0c:	0d850513          	addi	a0,a0,216 # 8001ffe0 <itable>
    80003f10:	ffffd097          	auipc	ra,0xffffd
    80003f14:	d66080e7          	jalr	-666(ra) # 80000c76 <release>
    itrunc(ip);
    80003f18:	8526                	mv	a0,s1
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	ee2080e7          	jalr	-286(ra) # 80003dfc <itrunc>
    ip->type = 0;
    80003f22:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f26:	8526                	mv	a0,s1
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	cfc080e7          	jalr	-772(ra) # 80003c24 <iupdate>
    ip->valid = 0;
    80003f30:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f34:	854a                	mv	a0,s2
    80003f36:	00001097          	auipc	ra,0x1
    80003f3a:	adc080e7          	jalr	-1316(ra) # 80004a12 <releasesleep>
    acquire(&itable.lock);
    80003f3e:	0001c517          	auipc	a0,0x1c
    80003f42:	0a250513          	addi	a0,a0,162 # 8001ffe0 <itable>
    80003f46:	ffffd097          	auipc	ra,0xffffd
    80003f4a:	c7c080e7          	jalr	-900(ra) # 80000bc2 <acquire>
    80003f4e:	b741                	j	80003ece <iput+0x26>

0000000080003f50 <iunlockput>:
{
    80003f50:	1101                	addi	sp,sp,-32
    80003f52:	ec06                	sd	ra,24(sp)
    80003f54:	e822                	sd	s0,16(sp)
    80003f56:	e426                	sd	s1,8(sp)
    80003f58:	1000                	addi	s0,sp,32
    80003f5a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	e54080e7          	jalr	-428(ra) # 80003db0 <iunlock>
  iput(ip);
    80003f64:	8526                	mv	a0,s1
    80003f66:	00000097          	auipc	ra,0x0
    80003f6a:	f42080e7          	jalr	-190(ra) # 80003ea8 <iput>
}
    80003f6e:	60e2                	ld	ra,24(sp)
    80003f70:	6442                	ld	s0,16(sp)
    80003f72:	64a2                	ld	s1,8(sp)
    80003f74:	6105                	addi	sp,sp,32
    80003f76:	8082                	ret

0000000080003f78 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f78:	1141                	addi	sp,sp,-16
    80003f7a:	e422                	sd	s0,8(sp)
    80003f7c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f7e:	411c                	lw	a5,0(a0)
    80003f80:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f82:	415c                	lw	a5,4(a0)
    80003f84:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f86:	04451783          	lh	a5,68(a0)
    80003f8a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f8e:	04a51783          	lh	a5,74(a0)
    80003f92:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f96:	04c56783          	lwu	a5,76(a0)
    80003f9a:	e99c                	sd	a5,16(a1)
}
    80003f9c:	6422                	ld	s0,8(sp)
    80003f9e:	0141                	addi	sp,sp,16
    80003fa0:	8082                	ret

0000000080003fa2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fa2:	457c                	lw	a5,76(a0)
    80003fa4:	0ed7e963          	bltu	a5,a3,80004096 <readi+0xf4>
{
    80003fa8:	7159                	addi	sp,sp,-112
    80003faa:	f486                	sd	ra,104(sp)
    80003fac:	f0a2                	sd	s0,96(sp)
    80003fae:	eca6                	sd	s1,88(sp)
    80003fb0:	e8ca                	sd	s2,80(sp)
    80003fb2:	e4ce                	sd	s3,72(sp)
    80003fb4:	e0d2                	sd	s4,64(sp)
    80003fb6:	fc56                	sd	s5,56(sp)
    80003fb8:	f85a                	sd	s6,48(sp)
    80003fba:	f45e                	sd	s7,40(sp)
    80003fbc:	f062                	sd	s8,32(sp)
    80003fbe:	ec66                	sd	s9,24(sp)
    80003fc0:	e86a                	sd	s10,16(sp)
    80003fc2:	e46e                	sd	s11,8(sp)
    80003fc4:	1880                	addi	s0,sp,112
    80003fc6:	8baa                	mv	s7,a0
    80003fc8:	8c2e                	mv	s8,a1
    80003fca:	8ab2                	mv	s5,a2
    80003fcc:	84b6                	mv	s1,a3
    80003fce:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003fd0:	9f35                	addw	a4,a4,a3
    return 0;
    80003fd2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003fd4:	0ad76063          	bltu	a4,a3,80004074 <readi+0xd2>
  if(off + n > ip->size)
    80003fd8:	00e7f463          	bgeu	a5,a4,80003fe0 <readi+0x3e>
    n = ip->size - off;
    80003fdc:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fe0:	0a0b0963          	beqz	s6,80004092 <readi+0xf0>
    80003fe4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fe6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003fea:	5cfd                	li	s9,-1
    80003fec:	a82d                	j	80004026 <readi+0x84>
    80003fee:	020a1d93          	slli	s11,s4,0x20
    80003ff2:	020ddd93          	srli	s11,s11,0x20
    80003ff6:	05890793          	addi	a5,s2,88
    80003ffa:	86ee                	mv	a3,s11
    80003ffc:	963e                	add	a2,a2,a5
    80003ffe:	85d6                	mv	a1,s5
    80004000:	8562                	mv	a0,s8
    80004002:	ffffe097          	auipc	ra,0xffffe
    80004006:	68e080e7          	jalr	1678(ra) # 80002690 <either_copyout>
    8000400a:	05950d63          	beq	a0,s9,80004064 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000400e:	854a                	mv	a0,s2
    80004010:	fffff097          	auipc	ra,0xfffff
    80004014:	60a080e7          	jalr	1546(ra) # 8000361a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004018:	013a09bb          	addw	s3,s4,s3
    8000401c:	009a04bb          	addw	s1,s4,s1
    80004020:	9aee                	add	s5,s5,s11
    80004022:	0569f763          	bgeu	s3,s6,80004070 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004026:	000ba903          	lw	s2,0(s7)
    8000402a:	00a4d59b          	srliw	a1,s1,0xa
    8000402e:	855e                	mv	a0,s7
    80004030:	00000097          	auipc	ra,0x0
    80004034:	8ae080e7          	jalr	-1874(ra) # 800038de <bmap>
    80004038:	0005059b          	sext.w	a1,a0
    8000403c:	854a                	mv	a0,s2
    8000403e:	fffff097          	auipc	ra,0xfffff
    80004042:	4ac080e7          	jalr	1196(ra) # 800034ea <bread>
    80004046:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004048:	3ff4f613          	andi	a2,s1,1023
    8000404c:	40cd07bb          	subw	a5,s10,a2
    80004050:	413b073b          	subw	a4,s6,s3
    80004054:	8a3e                	mv	s4,a5
    80004056:	2781                	sext.w	a5,a5
    80004058:	0007069b          	sext.w	a3,a4
    8000405c:	f8f6f9e3          	bgeu	a3,a5,80003fee <readi+0x4c>
    80004060:	8a3a                	mv	s4,a4
    80004062:	b771                	j	80003fee <readi+0x4c>
      brelse(bp);
    80004064:	854a                	mv	a0,s2
    80004066:	fffff097          	auipc	ra,0xfffff
    8000406a:	5b4080e7          	jalr	1460(ra) # 8000361a <brelse>
      tot = -1;
    8000406e:	59fd                	li	s3,-1
  }
  return tot;
    80004070:	0009851b          	sext.w	a0,s3
}
    80004074:	70a6                	ld	ra,104(sp)
    80004076:	7406                	ld	s0,96(sp)
    80004078:	64e6                	ld	s1,88(sp)
    8000407a:	6946                	ld	s2,80(sp)
    8000407c:	69a6                	ld	s3,72(sp)
    8000407e:	6a06                	ld	s4,64(sp)
    80004080:	7ae2                	ld	s5,56(sp)
    80004082:	7b42                	ld	s6,48(sp)
    80004084:	7ba2                	ld	s7,40(sp)
    80004086:	7c02                	ld	s8,32(sp)
    80004088:	6ce2                	ld	s9,24(sp)
    8000408a:	6d42                	ld	s10,16(sp)
    8000408c:	6da2                	ld	s11,8(sp)
    8000408e:	6165                	addi	sp,sp,112
    80004090:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004092:	89da                	mv	s3,s6
    80004094:	bff1                	j	80004070 <readi+0xce>
    return 0;
    80004096:	4501                	li	a0,0
}
    80004098:	8082                	ret

000000008000409a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000409a:	457c                	lw	a5,76(a0)
    8000409c:	10d7e863          	bltu	a5,a3,800041ac <writei+0x112>
{
    800040a0:	7159                	addi	sp,sp,-112
    800040a2:	f486                	sd	ra,104(sp)
    800040a4:	f0a2                	sd	s0,96(sp)
    800040a6:	eca6                	sd	s1,88(sp)
    800040a8:	e8ca                	sd	s2,80(sp)
    800040aa:	e4ce                	sd	s3,72(sp)
    800040ac:	e0d2                	sd	s4,64(sp)
    800040ae:	fc56                	sd	s5,56(sp)
    800040b0:	f85a                	sd	s6,48(sp)
    800040b2:	f45e                	sd	s7,40(sp)
    800040b4:	f062                	sd	s8,32(sp)
    800040b6:	ec66                	sd	s9,24(sp)
    800040b8:	e86a                	sd	s10,16(sp)
    800040ba:	e46e                	sd	s11,8(sp)
    800040bc:	1880                	addi	s0,sp,112
    800040be:	8b2a                	mv	s6,a0
    800040c0:	8c2e                	mv	s8,a1
    800040c2:	8ab2                	mv	s5,a2
    800040c4:	8936                	mv	s2,a3
    800040c6:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800040c8:	00e687bb          	addw	a5,a3,a4
    800040cc:	0ed7e263          	bltu	a5,a3,800041b0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040d0:	00043737          	lui	a4,0x43
    800040d4:	0ef76063          	bltu	a4,a5,800041b4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040d8:	0c0b8863          	beqz	s7,800041a8 <writei+0x10e>
    800040dc:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040de:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800040e2:	5cfd                	li	s9,-1
    800040e4:	a091                	j	80004128 <writei+0x8e>
    800040e6:	02099d93          	slli	s11,s3,0x20
    800040ea:	020ddd93          	srli	s11,s11,0x20
    800040ee:	05848793          	addi	a5,s1,88
    800040f2:	86ee                	mv	a3,s11
    800040f4:	8656                	mv	a2,s5
    800040f6:	85e2                	mv	a1,s8
    800040f8:	953e                	add	a0,a0,a5
    800040fa:	ffffe097          	auipc	ra,0xffffe
    800040fe:	5ec080e7          	jalr	1516(ra) # 800026e6 <either_copyin>
    80004102:	07950263          	beq	a0,s9,80004166 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004106:	8526                	mv	a0,s1
    80004108:	00000097          	auipc	ra,0x0
    8000410c:	794080e7          	jalr	1940(ra) # 8000489c <log_write>
    brelse(bp);
    80004110:	8526                	mv	a0,s1
    80004112:	fffff097          	auipc	ra,0xfffff
    80004116:	508080e7          	jalr	1288(ra) # 8000361a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000411a:	01498a3b          	addw	s4,s3,s4
    8000411e:	0129893b          	addw	s2,s3,s2
    80004122:	9aee                	add	s5,s5,s11
    80004124:	057a7663          	bgeu	s4,s7,80004170 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004128:	000b2483          	lw	s1,0(s6)
    8000412c:	00a9559b          	srliw	a1,s2,0xa
    80004130:	855a                	mv	a0,s6
    80004132:	fffff097          	auipc	ra,0xfffff
    80004136:	7ac080e7          	jalr	1964(ra) # 800038de <bmap>
    8000413a:	0005059b          	sext.w	a1,a0
    8000413e:	8526                	mv	a0,s1
    80004140:	fffff097          	auipc	ra,0xfffff
    80004144:	3aa080e7          	jalr	938(ra) # 800034ea <bread>
    80004148:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000414a:	3ff97513          	andi	a0,s2,1023
    8000414e:	40ad07bb          	subw	a5,s10,a0
    80004152:	414b873b          	subw	a4,s7,s4
    80004156:	89be                	mv	s3,a5
    80004158:	2781                	sext.w	a5,a5
    8000415a:	0007069b          	sext.w	a3,a4
    8000415e:	f8f6f4e3          	bgeu	a3,a5,800040e6 <writei+0x4c>
    80004162:	89ba                	mv	s3,a4
    80004164:	b749                	j	800040e6 <writei+0x4c>
      brelse(bp);
    80004166:	8526                	mv	a0,s1
    80004168:	fffff097          	auipc	ra,0xfffff
    8000416c:	4b2080e7          	jalr	1202(ra) # 8000361a <brelse>
  }

  if(off > ip->size)
    80004170:	04cb2783          	lw	a5,76(s6)
    80004174:	0127f463          	bgeu	a5,s2,8000417c <writei+0xe2>
    ip->size = off;
    80004178:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000417c:	855a                	mv	a0,s6
    8000417e:	00000097          	auipc	ra,0x0
    80004182:	aa6080e7          	jalr	-1370(ra) # 80003c24 <iupdate>

  return tot;
    80004186:	000a051b          	sext.w	a0,s4
}
    8000418a:	70a6                	ld	ra,104(sp)
    8000418c:	7406                	ld	s0,96(sp)
    8000418e:	64e6                	ld	s1,88(sp)
    80004190:	6946                	ld	s2,80(sp)
    80004192:	69a6                	ld	s3,72(sp)
    80004194:	6a06                	ld	s4,64(sp)
    80004196:	7ae2                	ld	s5,56(sp)
    80004198:	7b42                	ld	s6,48(sp)
    8000419a:	7ba2                	ld	s7,40(sp)
    8000419c:	7c02                	ld	s8,32(sp)
    8000419e:	6ce2                	ld	s9,24(sp)
    800041a0:	6d42                	ld	s10,16(sp)
    800041a2:	6da2                	ld	s11,8(sp)
    800041a4:	6165                	addi	sp,sp,112
    800041a6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041a8:	8a5e                	mv	s4,s7
    800041aa:	bfc9                	j	8000417c <writei+0xe2>
    return -1;
    800041ac:	557d                	li	a0,-1
}
    800041ae:	8082                	ret
    return -1;
    800041b0:	557d                	li	a0,-1
    800041b2:	bfe1                	j	8000418a <writei+0xf0>
    return -1;
    800041b4:	557d                	li	a0,-1
    800041b6:	bfd1                	j	8000418a <writei+0xf0>

00000000800041b8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041b8:	1141                	addi	sp,sp,-16
    800041ba:	e406                	sd	ra,8(sp)
    800041bc:	e022                	sd	s0,0(sp)
    800041be:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041c0:	4639                	li	a2,14
    800041c2:	ffffd097          	auipc	ra,0xffffd
    800041c6:	bd4080e7          	jalr	-1068(ra) # 80000d96 <strncmp>
}
    800041ca:	60a2                	ld	ra,8(sp)
    800041cc:	6402                	ld	s0,0(sp)
    800041ce:	0141                	addi	sp,sp,16
    800041d0:	8082                	ret

00000000800041d2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041d2:	7139                	addi	sp,sp,-64
    800041d4:	fc06                	sd	ra,56(sp)
    800041d6:	f822                	sd	s0,48(sp)
    800041d8:	f426                	sd	s1,40(sp)
    800041da:	f04a                	sd	s2,32(sp)
    800041dc:	ec4e                	sd	s3,24(sp)
    800041de:	e852                	sd	s4,16(sp)
    800041e0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800041e2:	04451703          	lh	a4,68(a0)
    800041e6:	4785                	li	a5,1
    800041e8:	00f71a63          	bne	a4,a5,800041fc <dirlookup+0x2a>
    800041ec:	892a                	mv	s2,a0
    800041ee:	89ae                	mv	s3,a1
    800041f0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800041f2:	457c                	lw	a5,76(a0)
    800041f4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800041f6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041f8:	e79d                	bnez	a5,80004226 <dirlookup+0x54>
    800041fa:	a8a5                	j	80004272 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800041fc:	00004517          	auipc	a0,0x4
    80004200:	60c50513          	addi	a0,a0,1548 # 80008808 <syscalls+0x1b8>
    80004204:	ffffc097          	auipc	ra,0xffffc
    80004208:	326080e7          	jalr	806(ra) # 8000052a <panic>
      panic("dirlookup read");
    8000420c:	00004517          	auipc	a0,0x4
    80004210:	61450513          	addi	a0,a0,1556 # 80008820 <syscalls+0x1d0>
    80004214:	ffffc097          	auipc	ra,0xffffc
    80004218:	316080e7          	jalr	790(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000421c:	24c1                	addiw	s1,s1,16
    8000421e:	04c92783          	lw	a5,76(s2)
    80004222:	04f4f763          	bgeu	s1,a5,80004270 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004226:	4741                	li	a4,16
    80004228:	86a6                	mv	a3,s1
    8000422a:	fc040613          	addi	a2,s0,-64
    8000422e:	4581                	li	a1,0
    80004230:	854a                	mv	a0,s2
    80004232:	00000097          	auipc	ra,0x0
    80004236:	d70080e7          	jalr	-656(ra) # 80003fa2 <readi>
    8000423a:	47c1                	li	a5,16
    8000423c:	fcf518e3          	bne	a0,a5,8000420c <dirlookup+0x3a>
    if(de.inum == 0)
    80004240:	fc045783          	lhu	a5,-64(s0)
    80004244:	dfe1                	beqz	a5,8000421c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004246:	fc240593          	addi	a1,s0,-62
    8000424a:	854e                	mv	a0,s3
    8000424c:	00000097          	auipc	ra,0x0
    80004250:	f6c080e7          	jalr	-148(ra) # 800041b8 <namecmp>
    80004254:	f561                	bnez	a0,8000421c <dirlookup+0x4a>
      if(poff)
    80004256:	000a0463          	beqz	s4,8000425e <dirlookup+0x8c>
        *poff = off;
    8000425a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000425e:	fc045583          	lhu	a1,-64(s0)
    80004262:	00092503          	lw	a0,0(s2)
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	754080e7          	jalr	1876(ra) # 800039ba <iget>
    8000426e:	a011                	j	80004272 <dirlookup+0xa0>
  return 0;
    80004270:	4501                	li	a0,0
}
    80004272:	70e2                	ld	ra,56(sp)
    80004274:	7442                	ld	s0,48(sp)
    80004276:	74a2                	ld	s1,40(sp)
    80004278:	7902                	ld	s2,32(sp)
    8000427a:	69e2                	ld	s3,24(sp)
    8000427c:	6a42                	ld	s4,16(sp)
    8000427e:	6121                	addi	sp,sp,64
    80004280:	8082                	ret

0000000080004282 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004282:	711d                	addi	sp,sp,-96
    80004284:	ec86                	sd	ra,88(sp)
    80004286:	e8a2                	sd	s0,80(sp)
    80004288:	e4a6                	sd	s1,72(sp)
    8000428a:	e0ca                	sd	s2,64(sp)
    8000428c:	fc4e                	sd	s3,56(sp)
    8000428e:	f852                	sd	s4,48(sp)
    80004290:	f456                	sd	s5,40(sp)
    80004292:	f05a                	sd	s6,32(sp)
    80004294:	ec5e                	sd	s7,24(sp)
    80004296:	e862                	sd	s8,16(sp)
    80004298:	e466                	sd	s9,8(sp)
    8000429a:	1080                	addi	s0,sp,96
    8000429c:	84aa                	mv	s1,a0
    8000429e:	8aae                	mv	s5,a1
    800042a0:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042a2:	00054703          	lbu	a4,0(a0)
    800042a6:	02f00793          	li	a5,47
    800042aa:	02f70363          	beq	a4,a5,800042d0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042ae:	ffffd097          	auipc	ra,0xffffd
    800042b2:	714080e7          	jalr	1812(ra) # 800019c2 <myproc>
    800042b6:	17053503          	ld	a0,368(a0)
    800042ba:	00000097          	auipc	ra,0x0
    800042be:	9f6080e7          	jalr	-1546(ra) # 80003cb0 <idup>
    800042c2:	89aa                	mv	s3,a0
  while(*path == '/')
    800042c4:	02f00913          	li	s2,47
  len = path - s;
    800042c8:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800042ca:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042cc:	4b85                	li	s7,1
    800042ce:	a865                	j	80004386 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800042d0:	4585                	li	a1,1
    800042d2:	4505                	li	a0,1
    800042d4:	fffff097          	auipc	ra,0xfffff
    800042d8:	6e6080e7          	jalr	1766(ra) # 800039ba <iget>
    800042dc:	89aa                	mv	s3,a0
    800042de:	b7dd                	j	800042c4 <namex+0x42>
      iunlockput(ip);
    800042e0:	854e                	mv	a0,s3
    800042e2:	00000097          	auipc	ra,0x0
    800042e6:	c6e080e7          	jalr	-914(ra) # 80003f50 <iunlockput>
      return 0;
    800042ea:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800042ec:	854e                	mv	a0,s3
    800042ee:	60e6                	ld	ra,88(sp)
    800042f0:	6446                	ld	s0,80(sp)
    800042f2:	64a6                	ld	s1,72(sp)
    800042f4:	6906                	ld	s2,64(sp)
    800042f6:	79e2                	ld	s3,56(sp)
    800042f8:	7a42                	ld	s4,48(sp)
    800042fa:	7aa2                	ld	s5,40(sp)
    800042fc:	7b02                	ld	s6,32(sp)
    800042fe:	6be2                	ld	s7,24(sp)
    80004300:	6c42                	ld	s8,16(sp)
    80004302:	6ca2                	ld	s9,8(sp)
    80004304:	6125                	addi	sp,sp,96
    80004306:	8082                	ret
      iunlock(ip);
    80004308:	854e                	mv	a0,s3
    8000430a:	00000097          	auipc	ra,0x0
    8000430e:	aa6080e7          	jalr	-1370(ra) # 80003db0 <iunlock>
      return ip;
    80004312:	bfe9                	j	800042ec <namex+0x6a>
      iunlockput(ip);
    80004314:	854e                	mv	a0,s3
    80004316:	00000097          	auipc	ra,0x0
    8000431a:	c3a080e7          	jalr	-966(ra) # 80003f50 <iunlockput>
      return 0;
    8000431e:	89e6                	mv	s3,s9
    80004320:	b7f1                	j	800042ec <namex+0x6a>
  len = path - s;
    80004322:	40b48633          	sub	a2,s1,a1
    80004326:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000432a:	099c5463          	bge	s8,s9,800043b2 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000432e:	4639                	li	a2,14
    80004330:	8552                	mv	a0,s4
    80004332:	ffffd097          	auipc	ra,0xffffd
    80004336:	9e8080e7          	jalr	-1560(ra) # 80000d1a <memmove>
  while(*path == '/')
    8000433a:	0004c783          	lbu	a5,0(s1)
    8000433e:	01279763          	bne	a5,s2,8000434c <namex+0xca>
    path++;
    80004342:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004344:	0004c783          	lbu	a5,0(s1)
    80004348:	ff278de3          	beq	a5,s2,80004342 <namex+0xc0>
    ilock(ip);
    8000434c:	854e                	mv	a0,s3
    8000434e:	00000097          	auipc	ra,0x0
    80004352:	9a0080e7          	jalr	-1632(ra) # 80003cee <ilock>
    if(ip->type != T_DIR){
    80004356:	04499783          	lh	a5,68(s3)
    8000435a:	f97793e3          	bne	a5,s7,800042e0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000435e:	000a8563          	beqz	s5,80004368 <namex+0xe6>
    80004362:	0004c783          	lbu	a5,0(s1)
    80004366:	d3cd                	beqz	a5,80004308 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004368:	865a                	mv	a2,s6
    8000436a:	85d2                	mv	a1,s4
    8000436c:	854e                	mv	a0,s3
    8000436e:	00000097          	auipc	ra,0x0
    80004372:	e64080e7          	jalr	-412(ra) # 800041d2 <dirlookup>
    80004376:	8caa                	mv	s9,a0
    80004378:	dd51                	beqz	a0,80004314 <namex+0x92>
    iunlockput(ip);
    8000437a:	854e                	mv	a0,s3
    8000437c:	00000097          	auipc	ra,0x0
    80004380:	bd4080e7          	jalr	-1068(ra) # 80003f50 <iunlockput>
    ip = next;
    80004384:	89e6                	mv	s3,s9
  while(*path == '/')
    80004386:	0004c783          	lbu	a5,0(s1)
    8000438a:	05279763          	bne	a5,s2,800043d8 <namex+0x156>
    path++;
    8000438e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004390:	0004c783          	lbu	a5,0(s1)
    80004394:	ff278de3          	beq	a5,s2,8000438e <namex+0x10c>
  if(*path == 0)
    80004398:	c79d                	beqz	a5,800043c6 <namex+0x144>
    path++;
    8000439a:	85a6                	mv	a1,s1
  len = path - s;
    8000439c:	8cda                	mv	s9,s6
    8000439e:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800043a0:	01278963          	beq	a5,s2,800043b2 <namex+0x130>
    800043a4:	dfbd                	beqz	a5,80004322 <namex+0xa0>
    path++;
    800043a6:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800043a8:	0004c783          	lbu	a5,0(s1)
    800043ac:	ff279ce3          	bne	a5,s2,800043a4 <namex+0x122>
    800043b0:	bf8d                	j	80004322 <namex+0xa0>
    memmove(name, s, len);
    800043b2:	2601                	sext.w	a2,a2
    800043b4:	8552                	mv	a0,s4
    800043b6:	ffffd097          	auipc	ra,0xffffd
    800043ba:	964080e7          	jalr	-1692(ra) # 80000d1a <memmove>
    name[len] = 0;
    800043be:	9cd2                	add	s9,s9,s4
    800043c0:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800043c4:	bf9d                	j	8000433a <namex+0xb8>
  if(nameiparent){
    800043c6:	f20a83e3          	beqz	s5,800042ec <namex+0x6a>
    iput(ip);
    800043ca:	854e                	mv	a0,s3
    800043cc:	00000097          	auipc	ra,0x0
    800043d0:	adc080e7          	jalr	-1316(ra) # 80003ea8 <iput>
    return 0;
    800043d4:	4981                	li	s3,0
    800043d6:	bf19                	j	800042ec <namex+0x6a>
  if(*path == 0)
    800043d8:	d7fd                	beqz	a5,800043c6 <namex+0x144>
  while(*path != '/' && *path != 0)
    800043da:	0004c783          	lbu	a5,0(s1)
    800043de:	85a6                	mv	a1,s1
    800043e0:	b7d1                	j	800043a4 <namex+0x122>

00000000800043e2 <dirlink>:
{
    800043e2:	7139                	addi	sp,sp,-64
    800043e4:	fc06                	sd	ra,56(sp)
    800043e6:	f822                	sd	s0,48(sp)
    800043e8:	f426                	sd	s1,40(sp)
    800043ea:	f04a                	sd	s2,32(sp)
    800043ec:	ec4e                	sd	s3,24(sp)
    800043ee:	e852                	sd	s4,16(sp)
    800043f0:	0080                	addi	s0,sp,64
    800043f2:	892a                	mv	s2,a0
    800043f4:	8a2e                	mv	s4,a1
    800043f6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800043f8:	4601                	li	a2,0
    800043fa:	00000097          	auipc	ra,0x0
    800043fe:	dd8080e7          	jalr	-552(ra) # 800041d2 <dirlookup>
    80004402:	e93d                	bnez	a0,80004478 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004404:	04c92483          	lw	s1,76(s2)
    80004408:	c49d                	beqz	s1,80004436 <dirlink+0x54>
    8000440a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000440c:	4741                	li	a4,16
    8000440e:	86a6                	mv	a3,s1
    80004410:	fc040613          	addi	a2,s0,-64
    80004414:	4581                	li	a1,0
    80004416:	854a                	mv	a0,s2
    80004418:	00000097          	auipc	ra,0x0
    8000441c:	b8a080e7          	jalr	-1142(ra) # 80003fa2 <readi>
    80004420:	47c1                	li	a5,16
    80004422:	06f51163          	bne	a0,a5,80004484 <dirlink+0xa2>
    if(de.inum == 0)
    80004426:	fc045783          	lhu	a5,-64(s0)
    8000442a:	c791                	beqz	a5,80004436 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000442c:	24c1                	addiw	s1,s1,16
    8000442e:	04c92783          	lw	a5,76(s2)
    80004432:	fcf4ede3          	bltu	s1,a5,8000440c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004436:	4639                	li	a2,14
    80004438:	85d2                	mv	a1,s4
    8000443a:	fc240513          	addi	a0,s0,-62
    8000443e:	ffffd097          	auipc	ra,0xffffd
    80004442:	994080e7          	jalr	-1644(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004446:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000444a:	4741                	li	a4,16
    8000444c:	86a6                	mv	a3,s1
    8000444e:	fc040613          	addi	a2,s0,-64
    80004452:	4581                	li	a1,0
    80004454:	854a                	mv	a0,s2
    80004456:	00000097          	auipc	ra,0x0
    8000445a:	c44080e7          	jalr	-956(ra) # 8000409a <writei>
    8000445e:	872a                	mv	a4,a0
    80004460:	47c1                	li	a5,16
  return 0;
    80004462:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004464:	02f71863          	bne	a4,a5,80004494 <dirlink+0xb2>
}
    80004468:	70e2                	ld	ra,56(sp)
    8000446a:	7442                	ld	s0,48(sp)
    8000446c:	74a2                	ld	s1,40(sp)
    8000446e:	7902                	ld	s2,32(sp)
    80004470:	69e2                	ld	s3,24(sp)
    80004472:	6a42                	ld	s4,16(sp)
    80004474:	6121                	addi	sp,sp,64
    80004476:	8082                	ret
    iput(ip);
    80004478:	00000097          	auipc	ra,0x0
    8000447c:	a30080e7          	jalr	-1488(ra) # 80003ea8 <iput>
    return -1;
    80004480:	557d                	li	a0,-1
    80004482:	b7dd                	j	80004468 <dirlink+0x86>
      panic("dirlink read");
    80004484:	00004517          	auipc	a0,0x4
    80004488:	3ac50513          	addi	a0,a0,940 # 80008830 <syscalls+0x1e0>
    8000448c:	ffffc097          	auipc	ra,0xffffc
    80004490:	09e080e7          	jalr	158(ra) # 8000052a <panic>
    panic("dirlink");
    80004494:	00004517          	auipc	a0,0x4
    80004498:	4a450513          	addi	a0,a0,1188 # 80008938 <syscalls+0x2e8>
    8000449c:	ffffc097          	auipc	ra,0xffffc
    800044a0:	08e080e7          	jalr	142(ra) # 8000052a <panic>

00000000800044a4 <namei>:

struct inode*
namei(char *path)
{
    800044a4:	1101                	addi	sp,sp,-32
    800044a6:	ec06                	sd	ra,24(sp)
    800044a8:	e822                	sd	s0,16(sp)
    800044aa:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044ac:	fe040613          	addi	a2,s0,-32
    800044b0:	4581                	li	a1,0
    800044b2:	00000097          	auipc	ra,0x0
    800044b6:	dd0080e7          	jalr	-560(ra) # 80004282 <namex>
}
    800044ba:	60e2                	ld	ra,24(sp)
    800044bc:	6442                	ld	s0,16(sp)
    800044be:	6105                	addi	sp,sp,32
    800044c0:	8082                	ret

00000000800044c2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044c2:	1141                	addi	sp,sp,-16
    800044c4:	e406                	sd	ra,8(sp)
    800044c6:	e022                	sd	s0,0(sp)
    800044c8:	0800                	addi	s0,sp,16
    800044ca:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044cc:	4585                	li	a1,1
    800044ce:	00000097          	auipc	ra,0x0
    800044d2:	db4080e7          	jalr	-588(ra) # 80004282 <namex>
}
    800044d6:	60a2                	ld	ra,8(sp)
    800044d8:	6402                	ld	s0,0(sp)
    800044da:	0141                	addi	sp,sp,16
    800044dc:	8082                	ret

00000000800044de <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044de:	1101                	addi	sp,sp,-32
    800044e0:	ec06                	sd	ra,24(sp)
    800044e2:	e822                	sd	s0,16(sp)
    800044e4:	e426                	sd	s1,8(sp)
    800044e6:	e04a                	sd	s2,0(sp)
    800044e8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800044ea:	0001d917          	auipc	s2,0x1d
    800044ee:	59e90913          	addi	s2,s2,1438 # 80021a88 <log>
    800044f2:	01892583          	lw	a1,24(s2)
    800044f6:	02892503          	lw	a0,40(s2)
    800044fa:	fffff097          	auipc	ra,0xfffff
    800044fe:	ff0080e7          	jalr	-16(ra) # 800034ea <bread>
    80004502:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004504:	02c92683          	lw	a3,44(s2)
    80004508:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000450a:	02d05863          	blez	a3,8000453a <write_head+0x5c>
    8000450e:	0001d797          	auipc	a5,0x1d
    80004512:	5aa78793          	addi	a5,a5,1450 # 80021ab8 <log+0x30>
    80004516:	05c50713          	addi	a4,a0,92
    8000451a:	36fd                	addiw	a3,a3,-1
    8000451c:	02069613          	slli	a2,a3,0x20
    80004520:	01e65693          	srli	a3,a2,0x1e
    80004524:	0001d617          	auipc	a2,0x1d
    80004528:	59860613          	addi	a2,a2,1432 # 80021abc <log+0x34>
    8000452c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000452e:	4390                	lw	a2,0(a5)
    80004530:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004532:	0791                	addi	a5,a5,4
    80004534:	0711                	addi	a4,a4,4
    80004536:	fed79ce3          	bne	a5,a3,8000452e <write_head+0x50>
  }
  bwrite(buf);
    8000453a:	8526                	mv	a0,s1
    8000453c:	fffff097          	auipc	ra,0xfffff
    80004540:	0a0080e7          	jalr	160(ra) # 800035dc <bwrite>
  brelse(buf);
    80004544:	8526                	mv	a0,s1
    80004546:	fffff097          	auipc	ra,0xfffff
    8000454a:	0d4080e7          	jalr	212(ra) # 8000361a <brelse>
}
    8000454e:	60e2                	ld	ra,24(sp)
    80004550:	6442                	ld	s0,16(sp)
    80004552:	64a2                	ld	s1,8(sp)
    80004554:	6902                	ld	s2,0(sp)
    80004556:	6105                	addi	sp,sp,32
    80004558:	8082                	ret

000000008000455a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000455a:	0001d797          	auipc	a5,0x1d
    8000455e:	55a7a783          	lw	a5,1370(a5) # 80021ab4 <log+0x2c>
    80004562:	0af05d63          	blez	a5,8000461c <install_trans+0xc2>
{
    80004566:	7139                	addi	sp,sp,-64
    80004568:	fc06                	sd	ra,56(sp)
    8000456a:	f822                	sd	s0,48(sp)
    8000456c:	f426                	sd	s1,40(sp)
    8000456e:	f04a                	sd	s2,32(sp)
    80004570:	ec4e                	sd	s3,24(sp)
    80004572:	e852                	sd	s4,16(sp)
    80004574:	e456                	sd	s5,8(sp)
    80004576:	e05a                	sd	s6,0(sp)
    80004578:	0080                	addi	s0,sp,64
    8000457a:	8b2a                	mv	s6,a0
    8000457c:	0001da97          	auipc	s5,0x1d
    80004580:	53ca8a93          	addi	s5,s5,1340 # 80021ab8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004584:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004586:	0001d997          	auipc	s3,0x1d
    8000458a:	50298993          	addi	s3,s3,1282 # 80021a88 <log>
    8000458e:	a00d                	j	800045b0 <install_trans+0x56>
    brelse(lbuf);
    80004590:	854a                	mv	a0,s2
    80004592:	fffff097          	auipc	ra,0xfffff
    80004596:	088080e7          	jalr	136(ra) # 8000361a <brelse>
    brelse(dbuf);
    8000459a:	8526                	mv	a0,s1
    8000459c:	fffff097          	auipc	ra,0xfffff
    800045a0:	07e080e7          	jalr	126(ra) # 8000361a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045a4:	2a05                	addiw	s4,s4,1
    800045a6:	0a91                	addi	s5,s5,4
    800045a8:	02c9a783          	lw	a5,44(s3)
    800045ac:	04fa5e63          	bge	s4,a5,80004608 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045b0:	0189a583          	lw	a1,24(s3)
    800045b4:	014585bb          	addw	a1,a1,s4
    800045b8:	2585                	addiw	a1,a1,1
    800045ba:	0289a503          	lw	a0,40(s3)
    800045be:	fffff097          	auipc	ra,0xfffff
    800045c2:	f2c080e7          	jalr	-212(ra) # 800034ea <bread>
    800045c6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045c8:	000aa583          	lw	a1,0(s5)
    800045cc:	0289a503          	lw	a0,40(s3)
    800045d0:	fffff097          	auipc	ra,0xfffff
    800045d4:	f1a080e7          	jalr	-230(ra) # 800034ea <bread>
    800045d8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800045da:	40000613          	li	a2,1024
    800045de:	05890593          	addi	a1,s2,88
    800045e2:	05850513          	addi	a0,a0,88
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	734080e7          	jalr	1844(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    800045ee:	8526                	mv	a0,s1
    800045f0:	fffff097          	auipc	ra,0xfffff
    800045f4:	fec080e7          	jalr	-20(ra) # 800035dc <bwrite>
    if(recovering == 0)
    800045f8:	f80b1ce3          	bnez	s6,80004590 <install_trans+0x36>
      bunpin(dbuf);
    800045fc:	8526                	mv	a0,s1
    800045fe:	fffff097          	auipc	ra,0xfffff
    80004602:	0f6080e7          	jalr	246(ra) # 800036f4 <bunpin>
    80004606:	b769                	j	80004590 <install_trans+0x36>
}
    80004608:	70e2                	ld	ra,56(sp)
    8000460a:	7442                	ld	s0,48(sp)
    8000460c:	74a2                	ld	s1,40(sp)
    8000460e:	7902                	ld	s2,32(sp)
    80004610:	69e2                	ld	s3,24(sp)
    80004612:	6a42                	ld	s4,16(sp)
    80004614:	6aa2                	ld	s5,8(sp)
    80004616:	6b02                	ld	s6,0(sp)
    80004618:	6121                	addi	sp,sp,64
    8000461a:	8082                	ret
    8000461c:	8082                	ret

000000008000461e <initlog>:
{
    8000461e:	7179                	addi	sp,sp,-48
    80004620:	f406                	sd	ra,40(sp)
    80004622:	f022                	sd	s0,32(sp)
    80004624:	ec26                	sd	s1,24(sp)
    80004626:	e84a                	sd	s2,16(sp)
    80004628:	e44e                	sd	s3,8(sp)
    8000462a:	1800                	addi	s0,sp,48
    8000462c:	892a                	mv	s2,a0
    8000462e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004630:	0001d497          	auipc	s1,0x1d
    80004634:	45848493          	addi	s1,s1,1112 # 80021a88 <log>
    80004638:	00004597          	auipc	a1,0x4
    8000463c:	20858593          	addi	a1,a1,520 # 80008840 <syscalls+0x1f0>
    80004640:	8526                	mv	a0,s1
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	4f0080e7          	jalr	1264(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    8000464a:	0149a583          	lw	a1,20(s3)
    8000464e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004650:	0109a783          	lw	a5,16(s3)
    80004654:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004656:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000465a:	854a                	mv	a0,s2
    8000465c:	fffff097          	auipc	ra,0xfffff
    80004660:	e8e080e7          	jalr	-370(ra) # 800034ea <bread>
  log.lh.n = lh->n;
    80004664:	4d34                	lw	a3,88(a0)
    80004666:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004668:	02d05663          	blez	a3,80004694 <initlog+0x76>
    8000466c:	05c50793          	addi	a5,a0,92
    80004670:	0001d717          	auipc	a4,0x1d
    80004674:	44870713          	addi	a4,a4,1096 # 80021ab8 <log+0x30>
    80004678:	36fd                	addiw	a3,a3,-1
    8000467a:	02069613          	slli	a2,a3,0x20
    8000467e:	01e65693          	srli	a3,a2,0x1e
    80004682:	06050613          	addi	a2,a0,96
    80004686:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004688:	4390                	lw	a2,0(a5)
    8000468a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000468c:	0791                	addi	a5,a5,4
    8000468e:	0711                	addi	a4,a4,4
    80004690:	fed79ce3          	bne	a5,a3,80004688 <initlog+0x6a>
  brelse(buf);
    80004694:	fffff097          	auipc	ra,0xfffff
    80004698:	f86080e7          	jalr	-122(ra) # 8000361a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000469c:	4505                	li	a0,1
    8000469e:	00000097          	auipc	ra,0x0
    800046a2:	ebc080e7          	jalr	-324(ra) # 8000455a <install_trans>
  log.lh.n = 0;
    800046a6:	0001d797          	auipc	a5,0x1d
    800046aa:	4007a723          	sw	zero,1038(a5) # 80021ab4 <log+0x2c>
  write_head(); // clear the log
    800046ae:	00000097          	auipc	ra,0x0
    800046b2:	e30080e7          	jalr	-464(ra) # 800044de <write_head>
}
    800046b6:	70a2                	ld	ra,40(sp)
    800046b8:	7402                	ld	s0,32(sp)
    800046ba:	64e2                	ld	s1,24(sp)
    800046bc:	6942                	ld	s2,16(sp)
    800046be:	69a2                	ld	s3,8(sp)
    800046c0:	6145                	addi	sp,sp,48
    800046c2:	8082                	ret

00000000800046c4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046c4:	1101                	addi	sp,sp,-32
    800046c6:	ec06                	sd	ra,24(sp)
    800046c8:	e822                	sd	s0,16(sp)
    800046ca:	e426                	sd	s1,8(sp)
    800046cc:	e04a                	sd	s2,0(sp)
    800046ce:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046d0:	0001d517          	auipc	a0,0x1d
    800046d4:	3b850513          	addi	a0,a0,952 # 80021a88 <log>
    800046d8:	ffffc097          	auipc	ra,0xffffc
    800046dc:	4ea080e7          	jalr	1258(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800046e0:	0001d497          	auipc	s1,0x1d
    800046e4:	3a848493          	addi	s1,s1,936 # 80021a88 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046e8:	4979                	li	s2,30
    800046ea:	a039                	j	800046f8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800046ec:	85a6                	mv	a1,s1
    800046ee:	8526                	mv	a0,s1
    800046f0:	ffffe097          	auipc	ra,0xffffe
    800046f4:	bf2080e7          	jalr	-1038(ra) # 800022e2 <sleep>
    if(log.committing){
    800046f8:	50dc                	lw	a5,36(s1)
    800046fa:	fbed                	bnez	a5,800046ec <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046fc:	509c                	lw	a5,32(s1)
    800046fe:	0017871b          	addiw	a4,a5,1
    80004702:	0007069b          	sext.w	a3,a4
    80004706:	0027179b          	slliw	a5,a4,0x2
    8000470a:	9fb9                	addw	a5,a5,a4
    8000470c:	0017979b          	slliw	a5,a5,0x1
    80004710:	54d8                	lw	a4,44(s1)
    80004712:	9fb9                	addw	a5,a5,a4
    80004714:	00f95963          	bge	s2,a5,80004726 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004718:	85a6                	mv	a1,s1
    8000471a:	8526                	mv	a0,s1
    8000471c:	ffffe097          	auipc	ra,0xffffe
    80004720:	bc6080e7          	jalr	-1082(ra) # 800022e2 <sleep>
    80004724:	bfd1                	j	800046f8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004726:	0001d517          	auipc	a0,0x1d
    8000472a:	36250513          	addi	a0,a0,866 # 80021a88 <log>
    8000472e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	546080e7          	jalr	1350(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004738:	60e2                	ld	ra,24(sp)
    8000473a:	6442                	ld	s0,16(sp)
    8000473c:	64a2                	ld	s1,8(sp)
    8000473e:	6902                	ld	s2,0(sp)
    80004740:	6105                	addi	sp,sp,32
    80004742:	8082                	ret

0000000080004744 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004744:	7139                	addi	sp,sp,-64
    80004746:	fc06                	sd	ra,56(sp)
    80004748:	f822                	sd	s0,48(sp)
    8000474a:	f426                	sd	s1,40(sp)
    8000474c:	f04a                	sd	s2,32(sp)
    8000474e:	ec4e                	sd	s3,24(sp)
    80004750:	e852                	sd	s4,16(sp)
    80004752:	e456                	sd	s5,8(sp)
    80004754:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004756:	0001d497          	auipc	s1,0x1d
    8000475a:	33248493          	addi	s1,s1,818 # 80021a88 <log>
    8000475e:	8526                	mv	a0,s1
    80004760:	ffffc097          	auipc	ra,0xffffc
    80004764:	462080e7          	jalr	1122(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004768:	509c                	lw	a5,32(s1)
    8000476a:	37fd                	addiw	a5,a5,-1
    8000476c:	0007891b          	sext.w	s2,a5
    80004770:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004772:	50dc                	lw	a5,36(s1)
    80004774:	e7b9                	bnez	a5,800047c2 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004776:	04091e63          	bnez	s2,800047d2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000477a:	0001d497          	auipc	s1,0x1d
    8000477e:	30e48493          	addi	s1,s1,782 # 80021a88 <log>
    80004782:	4785                	li	a5,1
    80004784:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004786:	8526                	mv	a0,s1
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	4ee080e7          	jalr	1262(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004790:	54dc                	lw	a5,44(s1)
    80004792:	06f04763          	bgtz	a5,80004800 <end_op+0xbc>
    acquire(&log.lock);
    80004796:	0001d497          	auipc	s1,0x1d
    8000479a:	2f248493          	addi	s1,s1,754 # 80021a88 <log>
    8000479e:	8526                	mv	a0,s1
    800047a0:	ffffc097          	auipc	ra,0xffffc
    800047a4:	422080e7          	jalr	1058(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800047a8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047ac:	8526                	mv	a0,s1
    800047ae:	ffffe097          	auipc	ra,0xffffe
    800047b2:	cc0080e7          	jalr	-832(ra) # 8000246e <wakeup>
    release(&log.lock);
    800047b6:	8526                	mv	a0,s1
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	4be080e7          	jalr	1214(ra) # 80000c76 <release>
}
    800047c0:	a03d                	j	800047ee <end_op+0xaa>
    panic("log.committing");
    800047c2:	00004517          	auipc	a0,0x4
    800047c6:	08650513          	addi	a0,a0,134 # 80008848 <syscalls+0x1f8>
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	d60080e7          	jalr	-672(ra) # 8000052a <panic>
    wakeup(&log);
    800047d2:	0001d497          	auipc	s1,0x1d
    800047d6:	2b648493          	addi	s1,s1,694 # 80021a88 <log>
    800047da:	8526                	mv	a0,s1
    800047dc:	ffffe097          	auipc	ra,0xffffe
    800047e0:	c92080e7          	jalr	-878(ra) # 8000246e <wakeup>
  release(&log.lock);
    800047e4:	8526                	mv	a0,s1
    800047e6:	ffffc097          	auipc	ra,0xffffc
    800047ea:	490080e7          	jalr	1168(ra) # 80000c76 <release>
}
    800047ee:	70e2                	ld	ra,56(sp)
    800047f0:	7442                	ld	s0,48(sp)
    800047f2:	74a2                	ld	s1,40(sp)
    800047f4:	7902                	ld	s2,32(sp)
    800047f6:	69e2                	ld	s3,24(sp)
    800047f8:	6a42                	ld	s4,16(sp)
    800047fa:	6aa2                	ld	s5,8(sp)
    800047fc:	6121                	addi	sp,sp,64
    800047fe:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004800:	0001da97          	auipc	s5,0x1d
    80004804:	2b8a8a93          	addi	s5,s5,696 # 80021ab8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004808:	0001da17          	auipc	s4,0x1d
    8000480c:	280a0a13          	addi	s4,s4,640 # 80021a88 <log>
    80004810:	018a2583          	lw	a1,24(s4)
    80004814:	012585bb          	addw	a1,a1,s2
    80004818:	2585                	addiw	a1,a1,1
    8000481a:	028a2503          	lw	a0,40(s4)
    8000481e:	fffff097          	auipc	ra,0xfffff
    80004822:	ccc080e7          	jalr	-820(ra) # 800034ea <bread>
    80004826:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004828:	000aa583          	lw	a1,0(s5)
    8000482c:	028a2503          	lw	a0,40(s4)
    80004830:	fffff097          	auipc	ra,0xfffff
    80004834:	cba080e7          	jalr	-838(ra) # 800034ea <bread>
    80004838:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000483a:	40000613          	li	a2,1024
    8000483e:	05850593          	addi	a1,a0,88
    80004842:	05848513          	addi	a0,s1,88
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	4d4080e7          	jalr	1236(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    8000484e:	8526                	mv	a0,s1
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	d8c080e7          	jalr	-628(ra) # 800035dc <bwrite>
    brelse(from);
    80004858:	854e                	mv	a0,s3
    8000485a:	fffff097          	auipc	ra,0xfffff
    8000485e:	dc0080e7          	jalr	-576(ra) # 8000361a <brelse>
    brelse(to);
    80004862:	8526                	mv	a0,s1
    80004864:	fffff097          	auipc	ra,0xfffff
    80004868:	db6080e7          	jalr	-586(ra) # 8000361a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000486c:	2905                	addiw	s2,s2,1
    8000486e:	0a91                	addi	s5,s5,4
    80004870:	02ca2783          	lw	a5,44(s4)
    80004874:	f8f94ee3          	blt	s2,a5,80004810 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004878:	00000097          	auipc	ra,0x0
    8000487c:	c66080e7          	jalr	-922(ra) # 800044de <write_head>
    install_trans(0); // Now install writes to home locations
    80004880:	4501                	li	a0,0
    80004882:	00000097          	auipc	ra,0x0
    80004886:	cd8080e7          	jalr	-808(ra) # 8000455a <install_trans>
    log.lh.n = 0;
    8000488a:	0001d797          	auipc	a5,0x1d
    8000488e:	2207a523          	sw	zero,554(a5) # 80021ab4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004892:	00000097          	auipc	ra,0x0
    80004896:	c4c080e7          	jalr	-948(ra) # 800044de <write_head>
    8000489a:	bdf5                	j	80004796 <end_op+0x52>

000000008000489c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000489c:	1101                	addi	sp,sp,-32
    8000489e:	ec06                	sd	ra,24(sp)
    800048a0:	e822                	sd	s0,16(sp)
    800048a2:	e426                	sd	s1,8(sp)
    800048a4:	e04a                	sd	s2,0(sp)
    800048a6:	1000                	addi	s0,sp,32
    800048a8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048aa:	0001d917          	auipc	s2,0x1d
    800048ae:	1de90913          	addi	s2,s2,478 # 80021a88 <log>
    800048b2:	854a                	mv	a0,s2
    800048b4:	ffffc097          	auipc	ra,0xffffc
    800048b8:	30e080e7          	jalr	782(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048bc:	02c92603          	lw	a2,44(s2)
    800048c0:	47f5                	li	a5,29
    800048c2:	06c7c563          	blt	a5,a2,8000492c <log_write+0x90>
    800048c6:	0001d797          	auipc	a5,0x1d
    800048ca:	1de7a783          	lw	a5,478(a5) # 80021aa4 <log+0x1c>
    800048ce:	37fd                	addiw	a5,a5,-1
    800048d0:	04f65e63          	bge	a2,a5,8000492c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048d4:	0001d797          	auipc	a5,0x1d
    800048d8:	1d47a783          	lw	a5,468(a5) # 80021aa8 <log+0x20>
    800048dc:	06f05063          	blez	a5,8000493c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048e0:	4781                	li	a5,0
    800048e2:	06c05563          	blez	a2,8000494c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800048e6:	44cc                	lw	a1,12(s1)
    800048e8:	0001d717          	auipc	a4,0x1d
    800048ec:	1d070713          	addi	a4,a4,464 # 80021ab8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800048f0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800048f2:	4314                	lw	a3,0(a4)
    800048f4:	04b68c63          	beq	a3,a1,8000494c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800048f8:	2785                	addiw	a5,a5,1
    800048fa:	0711                	addi	a4,a4,4
    800048fc:	fef61be3          	bne	a2,a5,800048f2 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004900:	0621                	addi	a2,a2,8
    80004902:	060a                	slli	a2,a2,0x2
    80004904:	0001d797          	auipc	a5,0x1d
    80004908:	18478793          	addi	a5,a5,388 # 80021a88 <log>
    8000490c:	963e                	add	a2,a2,a5
    8000490e:	44dc                	lw	a5,12(s1)
    80004910:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004912:	8526                	mv	a0,s1
    80004914:	fffff097          	auipc	ra,0xfffff
    80004918:	da4080e7          	jalr	-604(ra) # 800036b8 <bpin>
    log.lh.n++;
    8000491c:	0001d717          	auipc	a4,0x1d
    80004920:	16c70713          	addi	a4,a4,364 # 80021a88 <log>
    80004924:	575c                	lw	a5,44(a4)
    80004926:	2785                	addiw	a5,a5,1
    80004928:	d75c                	sw	a5,44(a4)
    8000492a:	a835                	j	80004966 <log_write+0xca>
    panic("too big a transaction");
    8000492c:	00004517          	auipc	a0,0x4
    80004930:	f2c50513          	addi	a0,a0,-212 # 80008858 <syscalls+0x208>
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	bf6080e7          	jalr	-1034(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    8000493c:	00004517          	auipc	a0,0x4
    80004940:	f3450513          	addi	a0,a0,-204 # 80008870 <syscalls+0x220>
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	be6080e7          	jalr	-1050(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    8000494c:	00878713          	addi	a4,a5,8
    80004950:	00271693          	slli	a3,a4,0x2
    80004954:	0001d717          	auipc	a4,0x1d
    80004958:	13470713          	addi	a4,a4,308 # 80021a88 <log>
    8000495c:	9736                	add	a4,a4,a3
    8000495e:	44d4                	lw	a3,12(s1)
    80004960:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004962:	faf608e3          	beq	a2,a5,80004912 <log_write+0x76>
  }
  release(&log.lock);
    80004966:	0001d517          	auipc	a0,0x1d
    8000496a:	12250513          	addi	a0,a0,290 # 80021a88 <log>
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	308080e7          	jalr	776(ra) # 80000c76 <release>
}
    80004976:	60e2                	ld	ra,24(sp)
    80004978:	6442                	ld	s0,16(sp)
    8000497a:	64a2                	ld	s1,8(sp)
    8000497c:	6902                	ld	s2,0(sp)
    8000497e:	6105                	addi	sp,sp,32
    80004980:	8082                	ret

0000000080004982 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004982:	1101                	addi	sp,sp,-32
    80004984:	ec06                	sd	ra,24(sp)
    80004986:	e822                	sd	s0,16(sp)
    80004988:	e426                	sd	s1,8(sp)
    8000498a:	e04a                	sd	s2,0(sp)
    8000498c:	1000                	addi	s0,sp,32
    8000498e:	84aa                	mv	s1,a0
    80004990:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004992:	00004597          	auipc	a1,0x4
    80004996:	efe58593          	addi	a1,a1,-258 # 80008890 <syscalls+0x240>
    8000499a:	0521                	addi	a0,a0,8
    8000499c:	ffffc097          	auipc	ra,0xffffc
    800049a0:	196080e7          	jalr	406(ra) # 80000b32 <initlock>
  lk->name = name;
    800049a4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049a8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049ac:	0204a423          	sw	zero,40(s1)
}
    800049b0:	60e2                	ld	ra,24(sp)
    800049b2:	6442                	ld	s0,16(sp)
    800049b4:	64a2                	ld	s1,8(sp)
    800049b6:	6902                	ld	s2,0(sp)
    800049b8:	6105                	addi	sp,sp,32
    800049ba:	8082                	ret

00000000800049bc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049bc:	1101                	addi	sp,sp,-32
    800049be:	ec06                	sd	ra,24(sp)
    800049c0:	e822                	sd	s0,16(sp)
    800049c2:	e426                	sd	s1,8(sp)
    800049c4:	e04a                	sd	s2,0(sp)
    800049c6:	1000                	addi	s0,sp,32
    800049c8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049ca:	00850913          	addi	s2,a0,8
    800049ce:	854a                	mv	a0,s2
    800049d0:	ffffc097          	auipc	ra,0xffffc
    800049d4:	1f2080e7          	jalr	498(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800049d8:	409c                	lw	a5,0(s1)
    800049da:	cb89                	beqz	a5,800049ec <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049dc:	85ca                	mv	a1,s2
    800049de:	8526                	mv	a0,s1
    800049e0:	ffffe097          	auipc	ra,0xffffe
    800049e4:	902080e7          	jalr	-1790(ra) # 800022e2 <sleep>
  while (lk->locked) {
    800049e8:	409c                	lw	a5,0(s1)
    800049ea:	fbed                	bnez	a5,800049dc <acquiresleep+0x20>
  }
  lk->locked = 1;
    800049ec:	4785                	li	a5,1
    800049ee:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800049f0:	ffffd097          	auipc	ra,0xffffd
    800049f4:	fd2080e7          	jalr	-46(ra) # 800019c2 <myproc>
    800049f8:	591c                	lw	a5,48(a0)
    800049fa:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800049fc:	854a                	mv	a0,s2
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	278080e7          	jalr	632(ra) # 80000c76 <release>
}
    80004a06:	60e2                	ld	ra,24(sp)
    80004a08:	6442                	ld	s0,16(sp)
    80004a0a:	64a2                	ld	s1,8(sp)
    80004a0c:	6902                	ld	s2,0(sp)
    80004a0e:	6105                	addi	sp,sp,32
    80004a10:	8082                	ret

0000000080004a12 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a12:	1101                	addi	sp,sp,-32
    80004a14:	ec06                	sd	ra,24(sp)
    80004a16:	e822                	sd	s0,16(sp)
    80004a18:	e426                	sd	s1,8(sp)
    80004a1a:	e04a                	sd	s2,0(sp)
    80004a1c:	1000                	addi	s0,sp,32
    80004a1e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a20:	00850913          	addi	s2,a0,8
    80004a24:	854a                	mv	a0,s2
    80004a26:	ffffc097          	auipc	ra,0xffffc
    80004a2a:	19c080e7          	jalr	412(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004a2e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a32:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a36:	8526                	mv	a0,s1
    80004a38:	ffffe097          	auipc	ra,0xffffe
    80004a3c:	a36080e7          	jalr	-1482(ra) # 8000246e <wakeup>
  release(&lk->lk);
    80004a40:	854a                	mv	a0,s2
    80004a42:	ffffc097          	auipc	ra,0xffffc
    80004a46:	234080e7          	jalr	564(ra) # 80000c76 <release>
}
    80004a4a:	60e2                	ld	ra,24(sp)
    80004a4c:	6442                	ld	s0,16(sp)
    80004a4e:	64a2                	ld	s1,8(sp)
    80004a50:	6902                	ld	s2,0(sp)
    80004a52:	6105                	addi	sp,sp,32
    80004a54:	8082                	ret

0000000080004a56 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a56:	7179                	addi	sp,sp,-48
    80004a58:	f406                	sd	ra,40(sp)
    80004a5a:	f022                	sd	s0,32(sp)
    80004a5c:	ec26                	sd	s1,24(sp)
    80004a5e:	e84a                	sd	s2,16(sp)
    80004a60:	e44e                	sd	s3,8(sp)
    80004a62:	1800                	addi	s0,sp,48
    80004a64:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a66:	00850913          	addi	s2,a0,8
    80004a6a:	854a                	mv	a0,s2
    80004a6c:	ffffc097          	auipc	ra,0xffffc
    80004a70:	156080e7          	jalr	342(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a74:	409c                	lw	a5,0(s1)
    80004a76:	ef99                	bnez	a5,80004a94 <holdingsleep+0x3e>
    80004a78:	4481                	li	s1,0
  release(&lk->lk);
    80004a7a:	854a                	mv	a0,s2
    80004a7c:	ffffc097          	auipc	ra,0xffffc
    80004a80:	1fa080e7          	jalr	506(ra) # 80000c76 <release>
  return r;
}
    80004a84:	8526                	mv	a0,s1
    80004a86:	70a2                	ld	ra,40(sp)
    80004a88:	7402                	ld	s0,32(sp)
    80004a8a:	64e2                	ld	s1,24(sp)
    80004a8c:	6942                	ld	s2,16(sp)
    80004a8e:	69a2                	ld	s3,8(sp)
    80004a90:	6145                	addi	sp,sp,48
    80004a92:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a94:	0284a983          	lw	s3,40(s1)
    80004a98:	ffffd097          	auipc	ra,0xffffd
    80004a9c:	f2a080e7          	jalr	-214(ra) # 800019c2 <myproc>
    80004aa0:	5904                	lw	s1,48(a0)
    80004aa2:	413484b3          	sub	s1,s1,s3
    80004aa6:	0014b493          	seqz	s1,s1
    80004aaa:	bfc1                	j	80004a7a <holdingsleep+0x24>

0000000080004aac <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004aac:	1141                	addi	sp,sp,-16
    80004aae:	e406                	sd	ra,8(sp)
    80004ab0:	e022                	sd	s0,0(sp)
    80004ab2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ab4:	00004597          	auipc	a1,0x4
    80004ab8:	dec58593          	addi	a1,a1,-532 # 800088a0 <syscalls+0x250>
    80004abc:	0001d517          	auipc	a0,0x1d
    80004ac0:	11450513          	addi	a0,a0,276 # 80021bd0 <ftable>
    80004ac4:	ffffc097          	auipc	ra,0xffffc
    80004ac8:	06e080e7          	jalr	110(ra) # 80000b32 <initlock>
}
    80004acc:	60a2                	ld	ra,8(sp)
    80004ace:	6402                	ld	s0,0(sp)
    80004ad0:	0141                	addi	sp,sp,16
    80004ad2:	8082                	ret

0000000080004ad4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004ad4:	1101                	addi	sp,sp,-32
    80004ad6:	ec06                	sd	ra,24(sp)
    80004ad8:	e822                	sd	s0,16(sp)
    80004ada:	e426                	sd	s1,8(sp)
    80004adc:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004ade:	0001d517          	auipc	a0,0x1d
    80004ae2:	0f250513          	addi	a0,a0,242 # 80021bd0 <ftable>
    80004ae6:	ffffc097          	auipc	ra,0xffffc
    80004aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004aee:	0001d497          	auipc	s1,0x1d
    80004af2:	0fa48493          	addi	s1,s1,250 # 80021be8 <ftable+0x18>
    80004af6:	0001e717          	auipc	a4,0x1e
    80004afa:	09270713          	addi	a4,a4,146 # 80022b88 <ftable+0xfb8>
    if(f->ref == 0){
    80004afe:	40dc                	lw	a5,4(s1)
    80004b00:	cf99                	beqz	a5,80004b1e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b02:	02848493          	addi	s1,s1,40
    80004b06:	fee49ce3          	bne	s1,a4,80004afe <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b0a:	0001d517          	auipc	a0,0x1d
    80004b0e:	0c650513          	addi	a0,a0,198 # 80021bd0 <ftable>
    80004b12:	ffffc097          	auipc	ra,0xffffc
    80004b16:	164080e7          	jalr	356(ra) # 80000c76 <release>
  return 0;
    80004b1a:	4481                	li	s1,0
    80004b1c:	a819                	j	80004b32 <filealloc+0x5e>
      f->ref = 1;
    80004b1e:	4785                	li	a5,1
    80004b20:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b22:	0001d517          	auipc	a0,0x1d
    80004b26:	0ae50513          	addi	a0,a0,174 # 80021bd0 <ftable>
    80004b2a:	ffffc097          	auipc	ra,0xffffc
    80004b2e:	14c080e7          	jalr	332(ra) # 80000c76 <release>
}
    80004b32:	8526                	mv	a0,s1
    80004b34:	60e2                	ld	ra,24(sp)
    80004b36:	6442                	ld	s0,16(sp)
    80004b38:	64a2                	ld	s1,8(sp)
    80004b3a:	6105                	addi	sp,sp,32
    80004b3c:	8082                	ret

0000000080004b3e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b3e:	1101                	addi	sp,sp,-32
    80004b40:	ec06                	sd	ra,24(sp)
    80004b42:	e822                	sd	s0,16(sp)
    80004b44:	e426                	sd	s1,8(sp)
    80004b46:	1000                	addi	s0,sp,32
    80004b48:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b4a:	0001d517          	auipc	a0,0x1d
    80004b4e:	08650513          	addi	a0,a0,134 # 80021bd0 <ftable>
    80004b52:	ffffc097          	auipc	ra,0xffffc
    80004b56:	070080e7          	jalr	112(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004b5a:	40dc                	lw	a5,4(s1)
    80004b5c:	02f05263          	blez	a5,80004b80 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b60:	2785                	addiw	a5,a5,1
    80004b62:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b64:	0001d517          	auipc	a0,0x1d
    80004b68:	06c50513          	addi	a0,a0,108 # 80021bd0 <ftable>
    80004b6c:	ffffc097          	auipc	ra,0xffffc
    80004b70:	10a080e7          	jalr	266(ra) # 80000c76 <release>
  return f;
}
    80004b74:	8526                	mv	a0,s1
    80004b76:	60e2                	ld	ra,24(sp)
    80004b78:	6442                	ld	s0,16(sp)
    80004b7a:	64a2                	ld	s1,8(sp)
    80004b7c:	6105                	addi	sp,sp,32
    80004b7e:	8082                	ret
    panic("filedup");
    80004b80:	00004517          	auipc	a0,0x4
    80004b84:	d2850513          	addi	a0,a0,-728 # 800088a8 <syscalls+0x258>
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	9a2080e7          	jalr	-1630(ra) # 8000052a <panic>

0000000080004b90 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b90:	7139                	addi	sp,sp,-64
    80004b92:	fc06                	sd	ra,56(sp)
    80004b94:	f822                	sd	s0,48(sp)
    80004b96:	f426                	sd	s1,40(sp)
    80004b98:	f04a                	sd	s2,32(sp)
    80004b9a:	ec4e                	sd	s3,24(sp)
    80004b9c:	e852                	sd	s4,16(sp)
    80004b9e:	e456                	sd	s5,8(sp)
    80004ba0:	0080                	addi	s0,sp,64
    80004ba2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ba4:	0001d517          	auipc	a0,0x1d
    80004ba8:	02c50513          	addi	a0,a0,44 # 80021bd0 <ftable>
    80004bac:	ffffc097          	auipc	ra,0xffffc
    80004bb0:	016080e7          	jalr	22(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004bb4:	40dc                	lw	a5,4(s1)
    80004bb6:	06f05163          	blez	a5,80004c18 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004bba:	37fd                	addiw	a5,a5,-1
    80004bbc:	0007871b          	sext.w	a4,a5
    80004bc0:	c0dc                	sw	a5,4(s1)
    80004bc2:	06e04363          	bgtz	a4,80004c28 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004bc6:	0004a903          	lw	s2,0(s1)
    80004bca:	0094ca83          	lbu	s5,9(s1)
    80004bce:	0104ba03          	ld	s4,16(s1)
    80004bd2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bd6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004bda:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004bde:	0001d517          	auipc	a0,0x1d
    80004be2:	ff250513          	addi	a0,a0,-14 # 80021bd0 <ftable>
    80004be6:	ffffc097          	auipc	ra,0xffffc
    80004bea:	090080e7          	jalr	144(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004bee:	4785                	li	a5,1
    80004bf0:	04f90d63          	beq	s2,a5,80004c4a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004bf4:	3979                	addiw	s2,s2,-2
    80004bf6:	4785                	li	a5,1
    80004bf8:	0527e063          	bltu	a5,s2,80004c38 <fileclose+0xa8>
    begin_op();
    80004bfc:	00000097          	auipc	ra,0x0
    80004c00:	ac8080e7          	jalr	-1336(ra) # 800046c4 <begin_op>
    iput(ff.ip);
    80004c04:	854e                	mv	a0,s3
    80004c06:	fffff097          	auipc	ra,0xfffff
    80004c0a:	2a2080e7          	jalr	674(ra) # 80003ea8 <iput>
    end_op();
    80004c0e:	00000097          	auipc	ra,0x0
    80004c12:	b36080e7          	jalr	-1226(ra) # 80004744 <end_op>
    80004c16:	a00d                	j	80004c38 <fileclose+0xa8>
    panic("fileclose");
    80004c18:	00004517          	auipc	a0,0x4
    80004c1c:	c9850513          	addi	a0,a0,-872 # 800088b0 <syscalls+0x260>
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	90a080e7          	jalr	-1782(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004c28:	0001d517          	auipc	a0,0x1d
    80004c2c:	fa850513          	addi	a0,a0,-88 # 80021bd0 <ftable>
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	046080e7          	jalr	70(ra) # 80000c76 <release>
  }
}
    80004c38:	70e2                	ld	ra,56(sp)
    80004c3a:	7442                	ld	s0,48(sp)
    80004c3c:	74a2                	ld	s1,40(sp)
    80004c3e:	7902                	ld	s2,32(sp)
    80004c40:	69e2                	ld	s3,24(sp)
    80004c42:	6a42                	ld	s4,16(sp)
    80004c44:	6aa2                	ld	s5,8(sp)
    80004c46:	6121                	addi	sp,sp,64
    80004c48:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c4a:	85d6                	mv	a1,s5
    80004c4c:	8552                	mv	a0,s4
    80004c4e:	00000097          	auipc	ra,0x0
    80004c52:	34c080e7          	jalr	844(ra) # 80004f9a <pipeclose>
    80004c56:	b7cd                	j	80004c38 <fileclose+0xa8>

0000000080004c58 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c58:	715d                	addi	sp,sp,-80
    80004c5a:	e486                	sd	ra,72(sp)
    80004c5c:	e0a2                	sd	s0,64(sp)
    80004c5e:	fc26                	sd	s1,56(sp)
    80004c60:	f84a                	sd	s2,48(sp)
    80004c62:	f44e                	sd	s3,40(sp)
    80004c64:	0880                	addi	s0,sp,80
    80004c66:	84aa                	mv	s1,a0
    80004c68:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c6a:	ffffd097          	auipc	ra,0xffffd
    80004c6e:	d58080e7          	jalr	-680(ra) # 800019c2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c72:	409c                	lw	a5,0(s1)
    80004c74:	37f9                	addiw	a5,a5,-2
    80004c76:	4705                	li	a4,1
    80004c78:	04f76763          	bltu	a4,a5,80004cc6 <filestat+0x6e>
    80004c7c:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c7e:	6c88                	ld	a0,24(s1)
    80004c80:	fffff097          	auipc	ra,0xfffff
    80004c84:	06e080e7          	jalr	110(ra) # 80003cee <ilock>
    stati(f->ip, &st);
    80004c88:	fb840593          	addi	a1,s0,-72
    80004c8c:	6c88                	ld	a0,24(s1)
    80004c8e:	fffff097          	auipc	ra,0xfffff
    80004c92:	2ea080e7          	jalr	746(ra) # 80003f78 <stati>
    iunlock(f->ip);
    80004c96:	6c88                	ld	a0,24(s1)
    80004c98:	fffff097          	auipc	ra,0xfffff
    80004c9c:	118080e7          	jalr	280(ra) # 80003db0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ca0:	46e1                	li	a3,24
    80004ca2:	fb840613          	addi	a2,s0,-72
    80004ca6:	85ce                	mv	a1,s3
    80004ca8:	07093503          	ld	a0,112(s2)
    80004cac:	ffffd097          	auipc	ra,0xffffd
    80004cb0:	992080e7          	jalr	-1646(ra) # 8000163e <copyout>
    80004cb4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004cb8:	60a6                	ld	ra,72(sp)
    80004cba:	6406                	ld	s0,64(sp)
    80004cbc:	74e2                	ld	s1,56(sp)
    80004cbe:	7942                	ld	s2,48(sp)
    80004cc0:	79a2                	ld	s3,40(sp)
    80004cc2:	6161                	addi	sp,sp,80
    80004cc4:	8082                	ret
  return -1;
    80004cc6:	557d                	li	a0,-1
    80004cc8:	bfc5                	j	80004cb8 <filestat+0x60>

0000000080004cca <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004cca:	7179                	addi	sp,sp,-48
    80004ccc:	f406                	sd	ra,40(sp)
    80004cce:	f022                	sd	s0,32(sp)
    80004cd0:	ec26                	sd	s1,24(sp)
    80004cd2:	e84a                	sd	s2,16(sp)
    80004cd4:	e44e                	sd	s3,8(sp)
    80004cd6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004cd8:	00854783          	lbu	a5,8(a0)
    80004cdc:	c3d5                	beqz	a5,80004d80 <fileread+0xb6>
    80004cde:	84aa                	mv	s1,a0
    80004ce0:	89ae                	mv	s3,a1
    80004ce2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ce4:	411c                	lw	a5,0(a0)
    80004ce6:	4705                	li	a4,1
    80004ce8:	04e78963          	beq	a5,a4,80004d3a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cec:	470d                	li	a4,3
    80004cee:	04e78d63          	beq	a5,a4,80004d48 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cf2:	4709                	li	a4,2
    80004cf4:	06e79e63          	bne	a5,a4,80004d70 <fileread+0xa6>
    ilock(f->ip);
    80004cf8:	6d08                	ld	a0,24(a0)
    80004cfa:	fffff097          	auipc	ra,0xfffff
    80004cfe:	ff4080e7          	jalr	-12(ra) # 80003cee <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d02:	874a                	mv	a4,s2
    80004d04:	5094                	lw	a3,32(s1)
    80004d06:	864e                	mv	a2,s3
    80004d08:	4585                	li	a1,1
    80004d0a:	6c88                	ld	a0,24(s1)
    80004d0c:	fffff097          	auipc	ra,0xfffff
    80004d10:	296080e7          	jalr	662(ra) # 80003fa2 <readi>
    80004d14:	892a                	mv	s2,a0
    80004d16:	00a05563          	blez	a0,80004d20 <fileread+0x56>
      f->off += r;
    80004d1a:	509c                	lw	a5,32(s1)
    80004d1c:	9fa9                	addw	a5,a5,a0
    80004d1e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d20:	6c88                	ld	a0,24(s1)
    80004d22:	fffff097          	auipc	ra,0xfffff
    80004d26:	08e080e7          	jalr	142(ra) # 80003db0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d2a:	854a                	mv	a0,s2
    80004d2c:	70a2                	ld	ra,40(sp)
    80004d2e:	7402                	ld	s0,32(sp)
    80004d30:	64e2                	ld	s1,24(sp)
    80004d32:	6942                	ld	s2,16(sp)
    80004d34:	69a2                	ld	s3,8(sp)
    80004d36:	6145                	addi	sp,sp,48
    80004d38:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d3a:	6908                	ld	a0,16(a0)
    80004d3c:	00000097          	auipc	ra,0x0
    80004d40:	3c0080e7          	jalr	960(ra) # 800050fc <piperead>
    80004d44:	892a                	mv	s2,a0
    80004d46:	b7d5                	j	80004d2a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d48:	02451783          	lh	a5,36(a0)
    80004d4c:	03079693          	slli	a3,a5,0x30
    80004d50:	92c1                	srli	a3,a3,0x30
    80004d52:	4725                	li	a4,9
    80004d54:	02d76863          	bltu	a4,a3,80004d84 <fileread+0xba>
    80004d58:	0792                	slli	a5,a5,0x4
    80004d5a:	0001d717          	auipc	a4,0x1d
    80004d5e:	dd670713          	addi	a4,a4,-554 # 80021b30 <devsw>
    80004d62:	97ba                	add	a5,a5,a4
    80004d64:	639c                	ld	a5,0(a5)
    80004d66:	c38d                	beqz	a5,80004d88 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d68:	4505                	li	a0,1
    80004d6a:	9782                	jalr	a5
    80004d6c:	892a                	mv	s2,a0
    80004d6e:	bf75                	j	80004d2a <fileread+0x60>
    panic("fileread");
    80004d70:	00004517          	auipc	a0,0x4
    80004d74:	b5050513          	addi	a0,a0,-1200 # 800088c0 <syscalls+0x270>
    80004d78:	ffffb097          	auipc	ra,0xffffb
    80004d7c:	7b2080e7          	jalr	1970(ra) # 8000052a <panic>
    return -1;
    80004d80:	597d                	li	s2,-1
    80004d82:	b765                	j	80004d2a <fileread+0x60>
      return -1;
    80004d84:	597d                	li	s2,-1
    80004d86:	b755                	j	80004d2a <fileread+0x60>
    80004d88:	597d                	li	s2,-1
    80004d8a:	b745                	j	80004d2a <fileread+0x60>

0000000080004d8c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d8c:	715d                	addi	sp,sp,-80
    80004d8e:	e486                	sd	ra,72(sp)
    80004d90:	e0a2                	sd	s0,64(sp)
    80004d92:	fc26                	sd	s1,56(sp)
    80004d94:	f84a                	sd	s2,48(sp)
    80004d96:	f44e                	sd	s3,40(sp)
    80004d98:	f052                	sd	s4,32(sp)
    80004d9a:	ec56                	sd	s5,24(sp)
    80004d9c:	e85a                	sd	s6,16(sp)
    80004d9e:	e45e                	sd	s7,8(sp)
    80004da0:	e062                	sd	s8,0(sp)
    80004da2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004da4:	00954783          	lbu	a5,9(a0)
    80004da8:	10078663          	beqz	a5,80004eb4 <filewrite+0x128>
    80004dac:	892a                	mv	s2,a0
    80004dae:	8aae                	mv	s5,a1
    80004db0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004db2:	411c                	lw	a5,0(a0)
    80004db4:	4705                	li	a4,1
    80004db6:	02e78263          	beq	a5,a4,80004dda <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dba:	470d                	li	a4,3
    80004dbc:	02e78663          	beq	a5,a4,80004de8 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dc0:	4709                	li	a4,2
    80004dc2:	0ee79163          	bne	a5,a4,80004ea4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004dc6:	0ac05d63          	blez	a2,80004e80 <filewrite+0xf4>
    int i = 0;
    80004dca:	4981                	li	s3,0
    80004dcc:	6b05                	lui	s6,0x1
    80004dce:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004dd2:	6b85                	lui	s7,0x1
    80004dd4:	c00b8b9b          	addiw	s7,s7,-1024
    80004dd8:	a861                	j	80004e70 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004dda:	6908                	ld	a0,16(a0)
    80004ddc:	00000097          	auipc	ra,0x0
    80004de0:	22e080e7          	jalr	558(ra) # 8000500a <pipewrite>
    80004de4:	8a2a                	mv	s4,a0
    80004de6:	a045                	j	80004e86 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004de8:	02451783          	lh	a5,36(a0)
    80004dec:	03079693          	slli	a3,a5,0x30
    80004df0:	92c1                	srli	a3,a3,0x30
    80004df2:	4725                	li	a4,9
    80004df4:	0cd76263          	bltu	a4,a3,80004eb8 <filewrite+0x12c>
    80004df8:	0792                	slli	a5,a5,0x4
    80004dfa:	0001d717          	auipc	a4,0x1d
    80004dfe:	d3670713          	addi	a4,a4,-714 # 80021b30 <devsw>
    80004e02:	97ba                	add	a5,a5,a4
    80004e04:	679c                	ld	a5,8(a5)
    80004e06:	cbdd                	beqz	a5,80004ebc <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e08:	4505                	li	a0,1
    80004e0a:	9782                	jalr	a5
    80004e0c:	8a2a                	mv	s4,a0
    80004e0e:	a8a5                	j	80004e86 <filewrite+0xfa>
    80004e10:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e14:	00000097          	auipc	ra,0x0
    80004e18:	8b0080e7          	jalr	-1872(ra) # 800046c4 <begin_op>
      ilock(f->ip);
    80004e1c:	01893503          	ld	a0,24(s2)
    80004e20:	fffff097          	auipc	ra,0xfffff
    80004e24:	ece080e7          	jalr	-306(ra) # 80003cee <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e28:	8762                	mv	a4,s8
    80004e2a:	02092683          	lw	a3,32(s2)
    80004e2e:	01598633          	add	a2,s3,s5
    80004e32:	4585                	li	a1,1
    80004e34:	01893503          	ld	a0,24(s2)
    80004e38:	fffff097          	auipc	ra,0xfffff
    80004e3c:	262080e7          	jalr	610(ra) # 8000409a <writei>
    80004e40:	84aa                	mv	s1,a0
    80004e42:	00a05763          	blez	a0,80004e50 <filewrite+0xc4>
        f->off += r;
    80004e46:	02092783          	lw	a5,32(s2)
    80004e4a:	9fa9                	addw	a5,a5,a0
    80004e4c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e50:	01893503          	ld	a0,24(s2)
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	f5c080e7          	jalr	-164(ra) # 80003db0 <iunlock>
      end_op();
    80004e5c:	00000097          	auipc	ra,0x0
    80004e60:	8e8080e7          	jalr	-1816(ra) # 80004744 <end_op>

      if(r != n1){
    80004e64:	009c1f63          	bne	s8,s1,80004e82 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e68:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e6c:	0149db63          	bge	s3,s4,80004e82 <filewrite+0xf6>
      int n1 = n - i;
    80004e70:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e74:	84be                	mv	s1,a5
    80004e76:	2781                	sext.w	a5,a5
    80004e78:	f8fb5ce3          	bge	s6,a5,80004e10 <filewrite+0x84>
    80004e7c:	84de                	mv	s1,s7
    80004e7e:	bf49                	j	80004e10 <filewrite+0x84>
    int i = 0;
    80004e80:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e82:	013a1f63          	bne	s4,s3,80004ea0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e86:	8552                	mv	a0,s4
    80004e88:	60a6                	ld	ra,72(sp)
    80004e8a:	6406                	ld	s0,64(sp)
    80004e8c:	74e2                	ld	s1,56(sp)
    80004e8e:	7942                	ld	s2,48(sp)
    80004e90:	79a2                	ld	s3,40(sp)
    80004e92:	7a02                	ld	s4,32(sp)
    80004e94:	6ae2                	ld	s5,24(sp)
    80004e96:	6b42                	ld	s6,16(sp)
    80004e98:	6ba2                	ld	s7,8(sp)
    80004e9a:	6c02                	ld	s8,0(sp)
    80004e9c:	6161                	addi	sp,sp,80
    80004e9e:	8082                	ret
    ret = (i == n ? n : -1);
    80004ea0:	5a7d                	li	s4,-1
    80004ea2:	b7d5                	j	80004e86 <filewrite+0xfa>
    panic("filewrite");
    80004ea4:	00004517          	auipc	a0,0x4
    80004ea8:	a2c50513          	addi	a0,a0,-1492 # 800088d0 <syscalls+0x280>
    80004eac:	ffffb097          	auipc	ra,0xffffb
    80004eb0:	67e080e7          	jalr	1662(ra) # 8000052a <panic>
    return -1;
    80004eb4:	5a7d                	li	s4,-1
    80004eb6:	bfc1                	j	80004e86 <filewrite+0xfa>
      return -1;
    80004eb8:	5a7d                	li	s4,-1
    80004eba:	b7f1                	j	80004e86 <filewrite+0xfa>
    80004ebc:	5a7d                	li	s4,-1
    80004ebe:	b7e1                	j	80004e86 <filewrite+0xfa>

0000000080004ec0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ec0:	7179                	addi	sp,sp,-48
    80004ec2:	f406                	sd	ra,40(sp)
    80004ec4:	f022                	sd	s0,32(sp)
    80004ec6:	ec26                	sd	s1,24(sp)
    80004ec8:	e84a                	sd	s2,16(sp)
    80004eca:	e44e                	sd	s3,8(sp)
    80004ecc:	e052                	sd	s4,0(sp)
    80004ece:	1800                	addi	s0,sp,48
    80004ed0:	84aa                	mv	s1,a0
    80004ed2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ed4:	0005b023          	sd	zero,0(a1)
    80004ed8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004edc:	00000097          	auipc	ra,0x0
    80004ee0:	bf8080e7          	jalr	-1032(ra) # 80004ad4 <filealloc>
    80004ee4:	e088                	sd	a0,0(s1)
    80004ee6:	c551                	beqz	a0,80004f72 <pipealloc+0xb2>
    80004ee8:	00000097          	auipc	ra,0x0
    80004eec:	bec080e7          	jalr	-1044(ra) # 80004ad4 <filealloc>
    80004ef0:	00aa3023          	sd	a0,0(s4)
    80004ef4:	c92d                	beqz	a0,80004f66 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	bdc080e7          	jalr	-1060(ra) # 80000ad2 <kalloc>
    80004efe:	892a                	mv	s2,a0
    80004f00:	c125                	beqz	a0,80004f60 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f02:	4985                	li	s3,1
    80004f04:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f08:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f0c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f10:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f14:	00003597          	auipc	a1,0x3
    80004f18:	5b458593          	addi	a1,a1,1460 # 800084c8 <states.0+0x1e0>
    80004f1c:	ffffc097          	auipc	ra,0xffffc
    80004f20:	c16080e7          	jalr	-1002(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004f24:	609c                	ld	a5,0(s1)
    80004f26:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f2a:	609c                	ld	a5,0(s1)
    80004f2c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f30:	609c                	ld	a5,0(s1)
    80004f32:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f36:	609c                	ld	a5,0(s1)
    80004f38:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f3c:	000a3783          	ld	a5,0(s4)
    80004f40:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f44:	000a3783          	ld	a5,0(s4)
    80004f48:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f4c:	000a3783          	ld	a5,0(s4)
    80004f50:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f54:	000a3783          	ld	a5,0(s4)
    80004f58:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f5c:	4501                	li	a0,0
    80004f5e:	a025                	j	80004f86 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f60:	6088                	ld	a0,0(s1)
    80004f62:	e501                	bnez	a0,80004f6a <pipealloc+0xaa>
    80004f64:	a039                	j	80004f72 <pipealloc+0xb2>
    80004f66:	6088                	ld	a0,0(s1)
    80004f68:	c51d                	beqz	a0,80004f96 <pipealloc+0xd6>
    fileclose(*f0);
    80004f6a:	00000097          	auipc	ra,0x0
    80004f6e:	c26080e7          	jalr	-986(ra) # 80004b90 <fileclose>
  if(*f1)
    80004f72:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f76:	557d                	li	a0,-1
  if(*f1)
    80004f78:	c799                	beqz	a5,80004f86 <pipealloc+0xc6>
    fileclose(*f1);
    80004f7a:	853e                	mv	a0,a5
    80004f7c:	00000097          	auipc	ra,0x0
    80004f80:	c14080e7          	jalr	-1004(ra) # 80004b90 <fileclose>
  return -1;
    80004f84:	557d                	li	a0,-1
}
    80004f86:	70a2                	ld	ra,40(sp)
    80004f88:	7402                	ld	s0,32(sp)
    80004f8a:	64e2                	ld	s1,24(sp)
    80004f8c:	6942                	ld	s2,16(sp)
    80004f8e:	69a2                	ld	s3,8(sp)
    80004f90:	6a02                	ld	s4,0(sp)
    80004f92:	6145                	addi	sp,sp,48
    80004f94:	8082                	ret
  return -1;
    80004f96:	557d                	li	a0,-1
    80004f98:	b7fd                	j	80004f86 <pipealloc+0xc6>

0000000080004f9a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f9a:	1101                	addi	sp,sp,-32
    80004f9c:	ec06                	sd	ra,24(sp)
    80004f9e:	e822                	sd	s0,16(sp)
    80004fa0:	e426                	sd	s1,8(sp)
    80004fa2:	e04a                	sd	s2,0(sp)
    80004fa4:	1000                	addi	s0,sp,32
    80004fa6:	84aa                	mv	s1,a0
    80004fa8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004faa:	ffffc097          	auipc	ra,0xffffc
    80004fae:	c18080e7          	jalr	-1000(ra) # 80000bc2 <acquire>
  if(writable){
    80004fb2:	02090d63          	beqz	s2,80004fec <pipeclose+0x52>
    pi->writeopen = 0;
    80004fb6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004fba:	21848513          	addi	a0,s1,536
    80004fbe:	ffffd097          	auipc	ra,0xffffd
    80004fc2:	4b0080e7          	jalr	1200(ra) # 8000246e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004fc6:	2204b783          	ld	a5,544(s1)
    80004fca:	eb95                	bnez	a5,80004ffe <pipeclose+0x64>
    release(&pi->lock);
    80004fcc:	8526                	mv	a0,s1
    80004fce:	ffffc097          	auipc	ra,0xffffc
    80004fd2:	ca8080e7          	jalr	-856(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004fd6:	8526                	mv	a0,s1
    80004fd8:	ffffc097          	auipc	ra,0xffffc
    80004fdc:	9fe080e7          	jalr	-1538(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004fe0:	60e2                	ld	ra,24(sp)
    80004fe2:	6442                	ld	s0,16(sp)
    80004fe4:	64a2                	ld	s1,8(sp)
    80004fe6:	6902                	ld	s2,0(sp)
    80004fe8:	6105                	addi	sp,sp,32
    80004fea:	8082                	ret
    pi->readopen = 0;
    80004fec:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ff0:	21c48513          	addi	a0,s1,540
    80004ff4:	ffffd097          	auipc	ra,0xffffd
    80004ff8:	47a080e7          	jalr	1146(ra) # 8000246e <wakeup>
    80004ffc:	b7e9                	j	80004fc6 <pipeclose+0x2c>
    release(&pi->lock);
    80004ffe:	8526                	mv	a0,s1
    80005000:	ffffc097          	auipc	ra,0xffffc
    80005004:	c76080e7          	jalr	-906(ra) # 80000c76 <release>
}
    80005008:	bfe1                	j	80004fe0 <pipeclose+0x46>

000000008000500a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000500a:	711d                	addi	sp,sp,-96
    8000500c:	ec86                	sd	ra,88(sp)
    8000500e:	e8a2                	sd	s0,80(sp)
    80005010:	e4a6                	sd	s1,72(sp)
    80005012:	e0ca                	sd	s2,64(sp)
    80005014:	fc4e                	sd	s3,56(sp)
    80005016:	f852                	sd	s4,48(sp)
    80005018:	f456                	sd	s5,40(sp)
    8000501a:	f05a                	sd	s6,32(sp)
    8000501c:	ec5e                	sd	s7,24(sp)
    8000501e:	e862                	sd	s8,16(sp)
    80005020:	1080                	addi	s0,sp,96
    80005022:	84aa                	mv	s1,a0
    80005024:	8aae                	mv	s5,a1
    80005026:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005028:	ffffd097          	auipc	ra,0xffffd
    8000502c:	99a080e7          	jalr	-1638(ra) # 800019c2 <myproc>
    80005030:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005032:	8526                	mv	a0,s1
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	b8e080e7          	jalr	-1138(ra) # 80000bc2 <acquire>
  while(i < n){
    8000503c:	0b405363          	blez	s4,800050e2 <pipewrite+0xd8>
  int i = 0;
    80005040:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005042:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005044:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005048:	21c48b93          	addi	s7,s1,540
    8000504c:	a089                	j	8000508e <pipewrite+0x84>
      release(&pi->lock);
    8000504e:	8526                	mv	a0,s1
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	c26080e7          	jalr	-986(ra) # 80000c76 <release>
      return -1;
    80005058:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000505a:	854a                	mv	a0,s2
    8000505c:	60e6                	ld	ra,88(sp)
    8000505e:	6446                	ld	s0,80(sp)
    80005060:	64a6                	ld	s1,72(sp)
    80005062:	6906                	ld	s2,64(sp)
    80005064:	79e2                	ld	s3,56(sp)
    80005066:	7a42                	ld	s4,48(sp)
    80005068:	7aa2                	ld	s5,40(sp)
    8000506a:	7b02                	ld	s6,32(sp)
    8000506c:	6be2                	ld	s7,24(sp)
    8000506e:	6c42                	ld	s8,16(sp)
    80005070:	6125                	addi	sp,sp,96
    80005072:	8082                	ret
      wakeup(&pi->nread);
    80005074:	8562                	mv	a0,s8
    80005076:	ffffd097          	auipc	ra,0xffffd
    8000507a:	3f8080e7          	jalr	1016(ra) # 8000246e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000507e:	85a6                	mv	a1,s1
    80005080:	855e                	mv	a0,s7
    80005082:	ffffd097          	auipc	ra,0xffffd
    80005086:	260080e7          	jalr	608(ra) # 800022e2 <sleep>
  while(i < n){
    8000508a:	05495d63          	bge	s2,s4,800050e4 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    8000508e:	2204a783          	lw	a5,544(s1)
    80005092:	dfd5                	beqz	a5,8000504e <pipewrite+0x44>
    80005094:	0289a783          	lw	a5,40(s3)
    80005098:	fbdd                	bnez	a5,8000504e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000509a:	2184a783          	lw	a5,536(s1)
    8000509e:	21c4a703          	lw	a4,540(s1)
    800050a2:	2007879b          	addiw	a5,a5,512
    800050a6:	fcf707e3          	beq	a4,a5,80005074 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050aa:	4685                	li	a3,1
    800050ac:	01590633          	add	a2,s2,s5
    800050b0:	faf40593          	addi	a1,s0,-81
    800050b4:	0709b503          	ld	a0,112(s3)
    800050b8:	ffffc097          	auipc	ra,0xffffc
    800050bc:	612080e7          	jalr	1554(ra) # 800016ca <copyin>
    800050c0:	03650263          	beq	a0,s6,800050e4 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050c4:	21c4a783          	lw	a5,540(s1)
    800050c8:	0017871b          	addiw	a4,a5,1
    800050cc:	20e4ae23          	sw	a4,540(s1)
    800050d0:	1ff7f793          	andi	a5,a5,511
    800050d4:	97a6                	add	a5,a5,s1
    800050d6:	faf44703          	lbu	a4,-81(s0)
    800050da:	00e78c23          	sb	a4,24(a5)
      i++;
    800050de:	2905                	addiw	s2,s2,1
    800050e0:	b76d                	j	8000508a <pipewrite+0x80>
  int i = 0;
    800050e2:	4901                	li	s2,0
  wakeup(&pi->nread);
    800050e4:	21848513          	addi	a0,s1,536
    800050e8:	ffffd097          	auipc	ra,0xffffd
    800050ec:	386080e7          	jalr	902(ra) # 8000246e <wakeup>
  release(&pi->lock);
    800050f0:	8526                	mv	a0,s1
    800050f2:	ffffc097          	auipc	ra,0xffffc
    800050f6:	b84080e7          	jalr	-1148(ra) # 80000c76 <release>
  return i;
    800050fa:	b785                	j	8000505a <pipewrite+0x50>

00000000800050fc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800050fc:	715d                	addi	sp,sp,-80
    800050fe:	e486                	sd	ra,72(sp)
    80005100:	e0a2                	sd	s0,64(sp)
    80005102:	fc26                	sd	s1,56(sp)
    80005104:	f84a                	sd	s2,48(sp)
    80005106:	f44e                	sd	s3,40(sp)
    80005108:	f052                	sd	s4,32(sp)
    8000510a:	ec56                	sd	s5,24(sp)
    8000510c:	e85a                	sd	s6,16(sp)
    8000510e:	0880                	addi	s0,sp,80
    80005110:	84aa                	mv	s1,a0
    80005112:	892e                	mv	s2,a1
    80005114:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005116:	ffffd097          	auipc	ra,0xffffd
    8000511a:	8ac080e7          	jalr	-1876(ra) # 800019c2 <myproc>
    8000511e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005120:	8526                	mv	a0,s1
    80005122:	ffffc097          	auipc	ra,0xffffc
    80005126:	aa0080e7          	jalr	-1376(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000512a:	2184a703          	lw	a4,536(s1)
    8000512e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005132:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005136:	02f71463          	bne	a4,a5,8000515e <piperead+0x62>
    8000513a:	2244a783          	lw	a5,548(s1)
    8000513e:	c385                	beqz	a5,8000515e <piperead+0x62>
    if(pr->killed){
    80005140:	028a2783          	lw	a5,40(s4)
    80005144:	ebc1                	bnez	a5,800051d4 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005146:	85a6                	mv	a1,s1
    80005148:	854e                	mv	a0,s3
    8000514a:	ffffd097          	auipc	ra,0xffffd
    8000514e:	198080e7          	jalr	408(ra) # 800022e2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005152:	2184a703          	lw	a4,536(s1)
    80005156:	21c4a783          	lw	a5,540(s1)
    8000515a:	fef700e3          	beq	a4,a5,8000513a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000515e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005160:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005162:	05505363          	blez	s5,800051a8 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80005166:	2184a783          	lw	a5,536(s1)
    8000516a:	21c4a703          	lw	a4,540(s1)
    8000516e:	02f70d63          	beq	a4,a5,800051a8 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005172:	0017871b          	addiw	a4,a5,1
    80005176:	20e4ac23          	sw	a4,536(s1)
    8000517a:	1ff7f793          	andi	a5,a5,511
    8000517e:	97a6                	add	a5,a5,s1
    80005180:	0187c783          	lbu	a5,24(a5)
    80005184:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005188:	4685                	li	a3,1
    8000518a:	fbf40613          	addi	a2,s0,-65
    8000518e:	85ca                	mv	a1,s2
    80005190:	070a3503          	ld	a0,112(s4)
    80005194:	ffffc097          	auipc	ra,0xffffc
    80005198:	4aa080e7          	jalr	1194(ra) # 8000163e <copyout>
    8000519c:	01650663          	beq	a0,s6,800051a8 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051a0:	2985                	addiw	s3,s3,1
    800051a2:	0905                	addi	s2,s2,1
    800051a4:	fd3a91e3          	bne	s5,s3,80005166 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051a8:	21c48513          	addi	a0,s1,540
    800051ac:	ffffd097          	auipc	ra,0xffffd
    800051b0:	2c2080e7          	jalr	706(ra) # 8000246e <wakeup>
  release(&pi->lock);
    800051b4:	8526                	mv	a0,s1
    800051b6:	ffffc097          	auipc	ra,0xffffc
    800051ba:	ac0080e7          	jalr	-1344(ra) # 80000c76 <release>
  return i;
}
    800051be:	854e                	mv	a0,s3
    800051c0:	60a6                	ld	ra,72(sp)
    800051c2:	6406                	ld	s0,64(sp)
    800051c4:	74e2                	ld	s1,56(sp)
    800051c6:	7942                	ld	s2,48(sp)
    800051c8:	79a2                	ld	s3,40(sp)
    800051ca:	7a02                	ld	s4,32(sp)
    800051cc:	6ae2                	ld	s5,24(sp)
    800051ce:	6b42                	ld	s6,16(sp)
    800051d0:	6161                	addi	sp,sp,80
    800051d2:	8082                	ret
      release(&pi->lock);
    800051d4:	8526                	mv	a0,s1
    800051d6:	ffffc097          	auipc	ra,0xffffc
    800051da:	aa0080e7          	jalr	-1376(ra) # 80000c76 <release>
      return -1;
    800051de:	59fd                	li	s3,-1
    800051e0:	bff9                	j	800051be <piperead+0xc2>

00000000800051e2 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800051e2:	de010113          	addi	sp,sp,-544
    800051e6:	20113c23          	sd	ra,536(sp)
    800051ea:	20813823          	sd	s0,528(sp)
    800051ee:	20913423          	sd	s1,520(sp)
    800051f2:	21213023          	sd	s2,512(sp)
    800051f6:	ffce                	sd	s3,504(sp)
    800051f8:	fbd2                	sd	s4,496(sp)
    800051fa:	f7d6                	sd	s5,488(sp)
    800051fc:	f3da                	sd	s6,480(sp)
    800051fe:	efde                	sd	s7,472(sp)
    80005200:	ebe2                	sd	s8,464(sp)
    80005202:	e7e6                	sd	s9,456(sp)
    80005204:	e3ea                	sd	s10,448(sp)
    80005206:	ff6e                	sd	s11,440(sp)
    80005208:	1400                	addi	s0,sp,544
    8000520a:	892a                	mv	s2,a0
    8000520c:	dea43423          	sd	a0,-536(s0)
    80005210:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005214:	ffffc097          	auipc	ra,0xffffc
    80005218:	7ae080e7          	jalr	1966(ra) # 800019c2 <myproc>
    8000521c:	84aa                	mv	s1,a0

  begin_op();
    8000521e:	fffff097          	auipc	ra,0xfffff
    80005222:	4a6080e7          	jalr	1190(ra) # 800046c4 <begin_op>

  if((ip = namei(path)) == 0){
    80005226:	854a                	mv	a0,s2
    80005228:	fffff097          	auipc	ra,0xfffff
    8000522c:	27c080e7          	jalr	636(ra) # 800044a4 <namei>
    80005230:	c93d                	beqz	a0,800052a6 <exec+0xc4>
    80005232:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	aba080e7          	jalr	-1350(ra) # 80003cee <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000523c:	04000713          	li	a4,64
    80005240:	4681                	li	a3,0
    80005242:	e4840613          	addi	a2,s0,-440
    80005246:	4581                	li	a1,0
    80005248:	8556                	mv	a0,s5
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	d58080e7          	jalr	-680(ra) # 80003fa2 <readi>
    80005252:	04000793          	li	a5,64
    80005256:	00f51a63          	bne	a0,a5,8000526a <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000525a:	e4842703          	lw	a4,-440(s0)
    8000525e:	464c47b7          	lui	a5,0x464c4
    80005262:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005266:	04f70663          	beq	a4,a5,800052b2 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000526a:	8556                	mv	a0,s5
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	ce4080e7          	jalr	-796(ra) # 80003f50 <iunlockput>
    end_op();
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	4d0080e7          	jalr	1232(ra) # 80004744 <end_op>
  }
  return -1;
    8000527c:	557d                	li	a0,-1
}
    8000527e:	21813083          	ld	ra,536(sp)
    80005282:	21013403          	ld	s0,528(sp)
    80005286:	20813483          	ld	s1,520(sp)
    8000528a:	20013903          	ld	s2,512(sp)
    8000528e:	79fe                	ld	s3,504(sp)
    80005290:	7a5e                	ld	s4,496(sp)
    80005292:	7abe                	ld	s5,488(sp)
    80005294:	7b1e                	ld	s6,480(sp)
    80005296:	6bfe                	ld	s7,472(sp)
    80005298:	6c5e                	ld	s8,464(sp)
    8000529a:	6cbe                	ld	s9,456(sp)
    8000529c:	6d1e                	ld	s10,448(sp)
    8000529e:	7dfa                	ld	s11,440(sp)
    800052a0:	22010113          	addi	sp,sp,544
    800052a4:	8082                	ret
    end_op();
    800052a6:	fffff097          	auipc	ra,0xfffff
    800052aa:	49e080e7          	jalr	1182(ra) # 80004744 <end_op>
    return -1;
    800052ae:	557d                	li	a0,-1
    800052b0:	b7f9                	j	8000527e <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800052b2:	8526                	mv	a0,s1
    800052b4:	ffffc097          	auipc	ra,0xffffc
    800052b8:	7d2080e7          	jalr	2002(ra) # 80001a86 <proc_pagetable>
    800052bc:	8b2a                	mv	s6,a0
    800052be:	d555                	beqz	a0,8000526a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052c0:	e6842783          	lw	a5,-408(s0)
    800052c4:	e8045703          	lhu	a4,-384(s0)
    800052c8:	c735                	beqz	a4,80005334 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800052ca:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052cc:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800052d0:	6a05                	lui	s4,0x1
    800052d2:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800052d6:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    800052da:	6d85                	lui	s11,0x1
    800052dc:	7d7d                	lui	s10,0xfffff
    800052de:	ac1d                	j	80005514 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800052e0:	00003517          	auipc	a0,0x3
    800052e4:	60050513          	addi	a0,a0,1536 # 800088e0 <syscalls+0x290>
    800052e8:	ffffb097          	auipc	ra,0xffffb
    800052ec:	242080e7          	jalr	578(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800052f0:	874a                	mv	a4,s2
    800052f2:	009c86bb          	addw	a3,s9,s1
    800052f6:	4581                	li	a1,0
    800052f8:	8556                	mv	a0,s5
    800052fa:	fffff097          	auipc	ra,0xfffff
    800052fe:	ca8080e7          	jalr	-856(ra) # 80003fa2 <readi>
    80005302:	2501                	sext.w	a0,a0
    80005304:	1aa91863          	bne	s2,a0,800054b4 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80005308:	009d84bb          	addw	s1,s11,s1
    8000530c:	013d09bb          	addw	s3,s10,s3
    80005310:	1f74f263          	bgeu	s1,s7,800054f4 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005314:	02049593          	slli	a1,s1,0x20
    80005318:	9181                	srli	a1,a1,0x20
    8000531a:	95e2                	add	a1,a1,s8
    8000531c:	855a                	mv	a0,s6
    8000531e:	ffffc097          	auipc	ra,0xffffc
    80005322:	d2e080e7          	jalr	-722(ra) # 8000104c <walkaddr>
    80005326:	862a                	mv	a2,a0
    if(pa == 0)
    80005328:	dd45                	beqz	a0,800052e0 <exec+0xfe>
      n = PGSIZE;
    8000532a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000532c:	fd49f2e3          	bgeu	s3,s4,800052f0 <exec+0x10e>
      n = sz - i;
    80005330:	894e                	mv	s2,s3
    80005332:	bf7d                	j	800052f0 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005334:	4481                	li	s1,0
  iunlockput(ip);
    80005336:	8556                	mv	a0,s5
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	c18080e7          	jalr	-1000(ra) # 80003f50 <iunlockput>
  end_op();
    80005340:	fffff097          	auipc	ra,0xfffff
    80005344:	404080e7          	jalr	1028(ra) # 80004744 <end_op>
  p = myproc();
    80005348:	ffffc097          	auipc	ra,0xffffc
    8000534c:	67a080e7          	jalr	1658(ra) # 800019c2 <myproc>
    80005350:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005352:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    80005356:	6785                	lui	a5,0x1
    80005358:	17fd                	addi	a5,a5,-1
    8000535a:	94be                	add	s1,s1,a5
    8000535c:	77fd                	lui	a5,0xfffff
    8000535e:	8fe5                	and	a5,a5,s1
    80005360:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005364:	6609                	lui	a2,0x2
    80005366:	963e                	add	a2,a2,a5
    80005368:	85be                	mv	a1,a5
    8000536a:	855a                	mv	a0,s6
    8000536c:	ffffc097          	auipc	ra,0xffffc
    80005370:	082080e7          	jalr	130(ra) # 800013ee <uvmalloc>
    80005374:	8c2a                	mv	s8,a0
  ip = 0;
    80005376:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005378:	12050e63          	beqz	a0,800054b4 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000537c:	75f9                	lui	a1,0xffffe
    8000537e:	95aa                	add	a1,a1,a0
    80005380:	855a                	mv	a0,s6
    80005382:	ffffc097          	auipc	ra,0xffffc
    80005386:	28a080e7          	jalr	650(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    8000538a:	7afd                	lui	s5,0xfffff
    8000538c:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000538e:	df043783          	ld	a5,-528(s0)
    80005392:	6388                	ld	a0,0(a5)
    80005394:	c925                	beqz	a0,80005404 <exec+0x222>
    80005396:	e8840993          	addi	s3,s0,-376
    8000539a:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    8000539e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800053a0:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800053a2:	ffffc097          	auipc	ra,0xffffc
    800053a6:	aa0080e7          	jalr	-1376(ra) # 80000e42 <strlen>
    800053aa:	0015079b          	addiw	a5,a0,1
    800053ae:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053b2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800053b6:	13596363          	bltu	s2,s5,800054dc <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800053ba:	df043d83          	ld	s11,-528(s0)
    800053be:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800053c2:	8552                	mv	a0,s4
    800053c4:	ffffc097          	auipc	ra,0xffffc
    800053c8:	a7e080e7          	jalr	-1410(ra) # 80000e42 <strlen>
    800053cc:	0015069b          	addiw	a3,a0,1
    800053d0:	8652                	mv	a2,s4
    800053d2:	85ca                	mv	a1,s2
    800053d4:	855a                	mv	a0,s6
    800053d6:	ffffc097          	auipc	ra,0xffffc
    800053da:	268080e7          	jalr	616(ra) # 8000163e <copyout>
    800053de:	10054363          	bltz	a0,800054e4 <exec+0x302>
    ustack[argc] = sp;
    800053e2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800053e6:	0485                	addi	s1,s1,1
    800053e8:	008d8793          	addi	a5,s11,8
    800053ec:	def43823          	sd	a5,-528(s0)
    800053f0:	008db503          	ld	a0,8(s11)
    800053f4:	c911                	beqz	a0,80005408 <exec+0x226>
    if(argc >= MAXARG)
    800053f6:	09a1                	addi	s3,s3,8
    800053f8:	fb3c95e3          	bne	s9,s3,800053a2 <exec+0x1c0>
  sz = sz1;
    800053fc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005400:	4a81                	li	s5,0
    80005402:	a84d                	j	800054b4 <exec+0x2d2>
  sp = sz;
    80005404:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005406:	4481                	li	s1,0
  ustack[argc] = 0;
    80005408:	00349793          	slli	a5,s1,0x3
    8000540c:	f9040713          	addi	a4,s0,-112
    80005410:	97ba                	add	a5,a5,a4
    80005412:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80005416:	00148693          	addi	a3,s1,1
    8000541a:	068e                	slli	a3,a3,0x3
    8000541c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005420:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005424:	01597663          	bgeu	s2,s5,80005430 <exec+0x24e>
  sz = sz1;
    80005428:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000542c:	4a81                	li	s5,0
    8000542e:	a059                	j	800054b4 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005430:	e8840613          	addi	a2,s0,-376
    80005434:	85ca                	mv	a1,s2
    80005436:	855a                	mv	a0,s6
    80005438:	ffffc097          	auipc	ra,0xffffc
    8000543c:	206080e7          	jalr	518(ra) # 8000163e <copyout>
    80005440:	0a054663          	bltz	a0,800054ec <exec+0x30a>
  p->trapframe->a1 = sp;
    80005444:	078bb783          	ld	a5,120(s7) # 1078 <_entry-0x7fffef88>
    80005448:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000544c:	de843783          	ld	a5,-536(s0)
    80005450:	0007c703          	lbu	a4,0(a5)
    80005454:	cf11                	beqz	a4,80005470 <exec+0x28e>
    80005456:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005458:	02f00693          	li	a3,47
    8000545c:	a039                	j	8000546a <exec+0x288>
      last = s+1;
    8000545e:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005462:	0785                	addi	a5,a5,1
    80005464:	fff7c703          	lbu	a4,-1(a5)
    80005468:	c701                	beqz	a4,80005470 <exec+0x28e>
    if(*s == '/')
    8000546a:	fed71ce3          	bne	a4,a3,80005462 <exec+0x280>
    8000546e:	bfc5                	j	8000545e <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005470:	4641                	li	a2,16
    80005472:	de843583          	ld	a1,-536(s0)
    80005476:	178b8513          	addi	a0,s7,376
    8000547a:	ffffc097          	auipc	ra,0xffffc
    8000547e:	996080e7          	jalr	-1642(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005482:	070bb503          	ld	a0,112(s7)
  p->pagetable = pagetable;
    80005486:	076bb823          	sd	s6,112(s7)
  p->sz = sz;
    8000548a:	078bb423          	sd	s8,104(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000548e:	078bb783          	ld	a5,120(s7)
    80005492:	e6043703          	ld	a4,-416(s0)
    80005496:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005498:	078bb783          	ld	a5,120(s7)
    8000549c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054a0:	85ea                	mv	a1,s10
    800054a2:	ffffc097          	auipc	ra,0xffffc
    800054a6:	680080e7          	jalr	1664(ra) # 80001b22 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054aa:	0004851b          	sext.w	a0,s1
    800054ae:	bbc1                	j	8000527e <exec+0x9c>
    800054b0:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800054b4:	df843583          	ld	a1,-520(s0)
    800054b8:	855a                	mv	a0,s6
    800054ba:	ffffc097          	auipc	ra,0xffffc
    800054be:	668080e7          	jalr	1640(ra) # 80001b22 <proc_freepagetable>
  if(ip){
    800054c2:	da0a94e3          	bnez	s5,8000526a <exec+0x88>
  return -1;
    800054c6:	557d                	li	a0,-1
    800054c8:	bb5d                	j	8000527e <exec+0x9c>
    800054ca:	de943c23          	sd	s1,-520(s0)
    800054ce:	b7dd                	j	800054b4 <exec+0x2d2>
    800054d0:	de943c23          	sd	s1,-520(s0)
    800054d4:	b7c5                	j	800054b4 <exec+0x2d2>
    800054d6:	de943c23          	sd	s1,-520(s0)
    800054da:	bfe9                	j	800054b4 <exec+0x2d2>
  sz = sz1;
    800054dc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054e0:	4a81                	li	s5,0
    800054e2:	bfc9                	j	800054b4 <exec+0x2d2>
  sz = sz1;
    800054e4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054e8:	4a81                	li	s5,0
    800054ea:	b7e9                	j	800054b4 <exec+0x2d2>
  sz = sz1;
    800054ec:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054f0:	4a81                	li	s5,0
    800054f2:	b7c9                	j	800054b4 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800054f4:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054f8:	e0843783          	ld	a5,-504(s0)
    800054fc:	0017869b          	addiw	a3,a5,1
    80005500:	e0d43423          	sd	a3,-504(s0)
    80005504:	e0043783          	ld	a5,-512(s0)
    80005508:	0387879b          	addiw	a5,a5,56
    8000550c:	e8045703          	lhu	a4,-384(s0)
    80005510:	e2e6d3e3          	bge	a3,a4,80005336 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005514:	2781                	sext.w	a5,a5
    80005516:	e0f43023          	sd	a5,-512(s0)
    8000551a:	03800713          	li	a4,56
    8000551e:	86be                	mv	a3,a5
    80005520:	e1040613          	addi	a2,s0,-496
    80005524:	4581                	li	a1,0
    80005526:	8556                	mv	a0,s5
    80005528:	fffff097          	auipc	ra,0xfffff
    8000552c:	a7a080e7          	jalr	-1414(ra) # 80003fa2 <readi>
    80005530:	03800793          	li	a5,56
    80005534:	f6f51ee3          	bne	a0,a5,800054b0 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005538:	e1042783          	lw	a5,-496(s0)
    8000553c:	4705                	li	a4,1
    8000553e:	fae79de3          	bne	a5,a4,800054f8 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005542:	e3843603          	ld	a2,-456(s0)
    80005546:	e3043783          	ld	a5,-464(s0)
    8000554a:	f8f660e3          	bltu	a2,a5,800054ca <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000554e:	e2043783          	ld	a5,-480(s0)
    80005552:	963e                	add	a2,a2,a5
    80005554:	f6f66ee3          	bltu	a2,a5,800054d0 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005558:	85a6                	mv	a1,s1
    8000555a:	855a                	mv	a0,s6
    8000555c:	ffffc097          	auipc	ra,0xffffc
    80005560:	e92080e7          	jalr	-366(ra) # 800013ee <uvmalloc>
    80005564:	dea43c23          	sd	a0,-520(s0)
    80005568:	d53d                	beqz	a0,800054d6 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    8000556a:	e2043c03          	ld	s8,-480(s0)
    8000556e:	de043783          	ld	a5,-544(s0)
    80005572:	00fc77b3          	and	a5,s8,a5
    80005576:	ff9d                	bnez	a5,800054b4 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005578:	e1842c83          	lw	s9,-488(s0)
    8000557c:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005580:	f60b8ae3          	beqz	s7,800054f4 <exec+0x312>
    80005584:	89de                	mv	s3,s7
    80005586:	4481                	li	s1,0
    80005588:	b371                	j	80005314 <exec+0x132>

000000008000558a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000558a:	7179                	addi	sp,sp,-48
    8000558c:	f406                	sd	ra,40(sp)
    8000558e:	f022                	sd	s0,32(sp)
    80005590:	ec26                	sd	s1,24(sp)
    80005592:	e84a                	sd	s2,16(sp)
    80005594:	1800                	addi	s0,sp,48
    80005596:	892e                	mv	s2,a1
    80005598:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000559a:	fdc40593          	addi	a1,s0,-36
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	a56080e7          	jalr	-1450(ra) # 80002ff4 <argint>
    800055a6:	04054063          	bltz	a0,800055e6 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055aa:	fdc42703          	lw	a4,-36(s0)
    800055ae:	47bd                	li	a5,15
    800055b0:	02e7ed63          	bltu	a5,a4,800055ea <argfd+0x60>
    800055b4:	ffffc097          	auipc	ra,0xffffc
    800055b8:	40e080e7          	jalr	1038(ra) # 800019c2 <myproc>
    800055bc:	fdc42703          	lw	a4,-36(s0)
    800055c0:	01e70793          	addi	a5,a4,30
    800055c4:	078e                	slli	a5,a5,0x3
    800055c6:	953e                	add	a0,a0,a5
    800055c8:	611c                	ld	a5,0(a0)
    800055ca:	c395                	beqz	a5,800055ee <argfd+0x64>
    return -1;
  if(pfd)
    800055cc:	00090463          	beqz	s2,800055d4 <argfd+0x4a>
    *pfd = fd;
    800055d0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800055d4:	4501                	li	a0,0
  if(pf)
    800055d6:	c091                	beqz	s1,800055da <argfd+0x50>
    *pf = f;
    800055d8:	e09c                	sd	a5,0(s1)
}
    800055da:	70a2                	ld	ra,40(sp)
    800055dc:	7402                	ld	s0,32(sp)
    800055de:	64e2                	ld	s1,24(sp)
    800055e0:	6942                	ld	s2,16(sp)
    800055e2:	6145                	addi	sp,sp,48
    800055e4:	8082                	ret
    return -1;
    800055e6:	557d                	li	a0,-1
    800055e8:	bfcd                	j	800055da <argfd+0x50>
    return -1;
    800055ea:	557d                	li	a0,-1
    800055ec:	b7fd                	j	800055da <argfd+0x50>
    800055ee:	557d                	li	a0,-1
    800055f0:	b7ed                	j	800055da <argfd+0x50>

00000000800055f2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800055f2:	1101                	addi	sp,sp,-32
    800055f4:	ec06                	sd	ra,24(sp)
    800055f6:	e822                	sd	s0,16(sp)
    800055f8:	e426                	sd	s1,8(sp)
    800055fa:	1000                	addi	s0,sp,32
    800055fc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800055fe:	ffffc097          	auipc	ra,0xffffc
    80005602:	3c4080e7          	jalr	964(ra) # 800019c2 <myproc>
    80005606:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005608:	0f050793          	addi	a5,a0,240
    8000560c:	4501                	li	a0,0
    8000560e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005610:	6398                	ld	a4,0(a5)
    80005612:	cb19                	beqz	a4,80005628 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005614:	2505                	addiw	a0,a0,1
    80005616:	07a1                	addi	a5,a5,8
    80005618:	fed51ce3          	bne	a0,a3,80005610 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000561c:	557d                	li	a0,-1
}
    8000561e:	60e2                	ld	ra,24(sp)
    80005620:	6442                	ld	s0,16(sp)
    80005622:	64a2                	ld	s1,8(sp)
    80005624:	6105                	addi	sp,sp,32
    80005626:	8082                	ret
      p->ofile[fd] = f;
    80005628:	01e50793          	addi	a5,a0,30
    8000562c:	078e                	slli	a5,a5,0x3
    8000562e:	963e                	add	a2,a2,a5
    80005630:	e204                	sd	s1,0(a2)
      return fd;
    80005632:	b7f5                	j	8000561e <fdalloc+0x2c>

0000000080005634 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005634:	715d                	addi	sp,sp,-80
    80005636:	e486                	sd	ra,72(sp)
    80005638:	e0a2                	sd	s0,64(sp)
    8000563a:	fc26                	sd	s1,56(sp)
    8000563c:	f84a                	sd	s2,48(sp)
    8000563e:	f44e                	sd	s3,40(sp)
    80005640:	f052                	sd	s4,32(sp)
    80005642:	ec56                	sd	s5,24(sp)
    80005644:	0880                	addi	s0,sp,80
    80005646:	89ae                	mv	s3,a1
    80005648:	8ab2                	mv	s5,a2
    8000564a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000564c:	fb040593          	addi	a1,s0,-80
    80005650:	fffff097          	auipc	ra,0xfffff
    80005654:	e72080e7          	jalr	-398(ra) # 800044c2 <nameiparent>
    80005658:	892a                	mv	s2,a0
    8000565a:	12050e63          	beqz	a0,80005796 <create+0x162>
    return 0;

  ilock(dp);
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	690080e7          	jalr	1680(ra) # 80003cee <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005666:	4601                	li	a2,0
    80005668:	fb040593          	addi	a1,s0,-80
    8000566c:	854a                	mv	a0,s2
    8000566e:	fffff097          	auipc	ra,0xfffff
    80005672:	b64080e7          	jalr	-1180(ra) # 800041d2 <dirlookup>
    80005676:	84aa                	mv	s1,a0
    80005678:	c921                	beqz	a0,800056c8 <create+0x94>
    iunlockput(dp);
    8000567a:	854a                	mv	a0,s2
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	8d4080e7          	jalr	-1836(ra) # 80003f50 <iunlockput>
    ilock(ip);
    80005684:	8526                	mv	a0,s1
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	668080e7          	jalr	1640(ra) # 80003cee <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000568e:	2981                	sext.w	s3,s3
    80005690:	4789                	li	a5,2
    80005692:	02f99463          	bne	s3,a5,800056ba <create+0x86>
    80005696:	0444d783          	lhu	a5,68(s1)
    8000569a:	37f9                	addiw	a5,a5,-2
    8000569c:	17c2                	slli	a5,a5,0x30
    8000569e:	93c1                	srli	a5,a5,0x30
    800056a0:	4705                	li	a4,1
    800056a2:	00f76c63          	bltu	a4,a5,800056ba <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800056a6:	8526                	mv	a0,s1
    800056a8:	60a6                	ld	ra,72(sp)
    800056aa:	6406                	ld	s0,64(sp)
    800056ac:	74e2                	ld	s1,56(sp)
    800056ae:	7942                	ld	s2,48(sp)
    800056b0:	79a2                	ld	s3,40(sp)
    800056b2:	7a02                	ld	s4,32(sp)
    800056b4:	6ae2                	ld	s5,24(sp)
    800056b6:	6161                	addi	sp,sp,80
    800056b8:	8082                	ret
    iunlockput(ip);
    800056ba:	8526                	mv	a0,s1
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	894080e7          	jalr	-1900(ra) # 80003f50 <iunlockput>
    return 0;
    800056c4:	4481                	li	s1,0
    800056c6:	b7c5                	j	800056a6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800056c8:	85ce                	mv	a1,s3
    800056ca:	00092503          	lw	a0,0(s2)
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	488080e7          	jalr	1160(ra) # 80003b56 <ialloc>
    800056d6:	84aa                	mv	s1,a0
    800056d8:	c521                	beqz	a0,80005720 <create+0xec>
  ilock(ip);
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	614080e7          	jalr	1556(ra) # 80003cee <ilock>
  ip->major = major;
    800056e2:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800056e6:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800056ea:	4a05                	li	s4,1
    800056ec:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800056f0:	8526                	mv	a0,s1
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	532080e7          	jalr	1330(ra) # 80003c24 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800056fa:	2981                	sext.w	s3,s3
    800056fc:	03498a63          	beq	s3,s4,80005730 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005700:	40d0                	lw	a2,4(s1)
    80005702:	fb040593          	addi	a1,s0,-80
    80005706:	854a                	mv	a0,s2
    80005708:	fffff097          	auipc	ra,0xfffff
    8000570c:	cda080e7          	jalr	-806(ra) # 800043e2 <dirlink>
    80005710:	06054b63          	bltz	a0,80005786 <create+0x152>
  iunlockput(dp);
    80005714:	854a                	mv	a0,s2
    80005716:	fffff097          	auipc	ra,0xfffff
    8000571a:	83a080e7          	jalr	-1990(ra) # 80003f50 <iunlockput>
  return ip;
    8000571e:	b761                	j	800056a6 <create+0x72>
    panic("create: ialloc");
    80005720:	00003517          	auipc	a0,0x3
    80005724:	1e050513          	addi	a0,a0,480 # 80008900 <syscalls+0x2b0>
    80005728:	ffffb097          	auipc	ra,0xffffb
    8000572c:	e02080e7          	jalr	-510(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005730:	04a95783          	lhu	a5,74(s2)
    80005734:	2785                	addiw	a5,a5,1
    80005736:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000573a:	854a                	mv	a0,s2
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	4e8080e7          	jalr	1256(ra) # 80003c24 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005744:	40d0                	lw	a2,4(s1)
    80005746:	00003597          	auipc	a1,0x3
    8000574a:	1ca58593          	addi	a1,a1,458 # 80008910 <syscalls+0x2c0>
    8000574e:	8526                	mv	a0,s1
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	c92080e7          	jalr	-878(ra) # 800043e2 <dirlink>
    80005758:	00054f63          	bltz	a0,80005776 <create+0x142>
    8000575c:	00492603          	lw	a2,4(s2)
    80005760:	00003597          	auipc	a1,0x3
    80005764:	1b858593          	addi	a1,a1,440 # 80008918 <syscalls+0x2c8>
    80005768:	8526                	mv	a0,s1
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	c78080e7          	jalr	-904(ra) # 800043e2 <dirlink>
    80005772:	f80557e3          	bgez	a0,80005700 <create+0xcc>
      panic("create dots");
    80005776:	00003517          	auipc	a0,0x3
    8000577a:	1aa50513          	addi	a0,a0,426 # 80008920 <syscalls+0x2d0>
    8000577e:	ffffb097          	auipc	ra,0xffffb
    80005782:	dac080e7          	jalr	-596(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005786:	00003517          	auipc	a0,0x3
    8000578a:	1aa50513          	addi	a0,a0,426 # 80008930 <syscalls+0x2e0>
    8000578e:	ffffb097          	auipc	ra,0xffffb
    80005792:	d9c080e7          	jalr	-612(ra) # 8000052a <panic>
    return 0;
    80005796:	84aa                	mv	s1,a0
    80005798:	b739                	j	800056a6 <create+0x72>

000000008000579a <sys_dup>:
{
    8000579a:	7179                	addi	sp,sp,-48
    8000579c:	f406                	sd	ra,40(sp)
    8000579e:	f022                	sd	s0,32(sp)
    800057a0:	ec26                	sd	s1,24(sp)
    800057a2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057a4:	fd840613          	addi	a2,s0,-40
    800057a8:	4581                	li	a1,0
    800057aa:	4501                	li	a0,0
    800057ac:	00000097          	auipc	ra,0x0
    800057b0:	dde080e7          	jalr	-546(ra) # 8000558a <argfd>
    return -1;
    800057b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800057b6:	02054363          	bltz	a0,800057dc <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800057ba:	fd843503          	ld	a0,-40(s0)
    800057be:	00000097          	auipc	ra,0x0
    800057c2:	e34080e7          	jalr	-460(ra) # 800055f2 <fdalloc>
    800057c6:	84aa                	mv	s1,a0
    return -1;
    800057c8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800057ca:	00054963          	bltz	a0,800057dc <sys_dup+0x42>
  filedup(f);
    800057ce:	fd843503          	ld	a0,-40(s0)
    800057d2:	fffff097          	auipc	ra,0xfffff
    800057d6:	36c080e7          	jalr	876(ra) # 80004b3e <filedup>
  return fd;
    800057da:	87a6                	mv	a5,s1
}
    800057dc:	853e                	mv	a0,a5
    800057de:	70a2                	ld	ra,40(sp)
    800057e0:	7402                	ld	s0,32(sp)
    800057e2:	64e2                	ld	s1,24(sp)
    800057e4:	6145                	addi	sp,sp,48
    800057e6:	8082                	ret

00000000800057e8 <sys_read>:
{
    800057e8:	7179                	addi	sp,sp,-48
    800057ea:	f406                	sd	ra,40(sp)
    800057ec:	f022                	sd	s0,32(sp)
    800057ee:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057f0:	fe840613          	addi	a2,s0,-24
    800057f4:	4581                	li	a1,0
    800057f6:	4501                	li	a0,0
    800057f8:	00000097          	auipc	ra,0x0
    800057fc:	d92080e7          	jalr	-622(ra) # 8000558a <argfd>
    return -1;
    80005800:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005802:	04054163          	bltz	a0,80005844 <sys_read+0x5c>
    80005806:	fe440593          	addi	a1,s0,-28
    8000580a:	4509                	li	a0,2
    8000580c:	ffffd097          	auipc	ra,0xffffd
    80005810:	7e8080e7          	jalr	2024(ra) # 80002ff4 <argint>
    return -1;
    80005814:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005816:	02054763          	bltz	a0,80005844 <sys_read+0x5c>
    8000581a:	fd840593          	addi	a1,s0,-40
    8000581e:	4505                	li	a0,1
    80005820:	ffffd097          	auipc	ra,0xffffd
    80005824:	7f6080e7          	jalr	2038(ra) # 80003016 <argaddr>
    return -1;
    80005828:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000582a:	00054d63          	bltz	a0,80005844 <sys_read+0x5c>
  return fileread(f, p, n);
    8000582e:	fe442603          	lw	a2,-28(s0)
    80005832:	fd843583          	ld	a1,-40(s0)
    80005836:	fe843503          	ld	a0,-24(s0)
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	490080e7          	jalr	1168(ra) # 80004cca <fileread>
    80005842:	87aa                	mv	a5,a0
}
    80005844:	853e                	mv	a0,a5
    80005846:	70a2                	ld	ra,40(sp)
    80005848:	7402                	ld	s0,32(sp)
    8000584a:	6145                	addi	sp,sp,48
    8000584c:	8082                	ret

000000008000584e <sys_write>:
{
    8000584e:	7179                	addi	sp,sp,-48
    80005850:	f406                	sd	ra,40(sp)
    80005852:	f022                	sd	s0,32(sp)
    80005854:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005856:	fe840613          	addi	a2,s0,-24
    8000585a:	4581                	li	a1,0
    8000585c:	4501                	li	a0,0
    8000585e:	00000097          	auipc	ra,0x0
    80005862:	d2c080e7          	jalr	-724(ra) # 8000558a <argfd>
    return -1;
    80005866:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005868:	04054163          	bltz	a0,800058aa <sys_write+0x5c>
    8000586c:	fe440593          	addi	a1,s0,-28
    80005870:	4509                	li	a0,2
    80005872:	ffffd097          	auipc	ra,0xffffd
    80005876:	782080e7          	jalr	1922(ra) # 80002ff4 <argint>
    return -1;
    8000587a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000587c:	02054763          	bltz	a0,800058aa <sys_write+0x5c>
    80005880:	fd840593          	addi	a1,s0,-40
    80005884:	4505                	li	a0,1
    80005886:	ffffd097          	auipc	ra,0xffffd
    8000588a:	790080e7          	jalr	1936(ra) # 80003016 <argaddr>
    return -1;
    8000588e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005890:	00054d63          	bltz	a0,800058aa <sys_write+0x5c>
  return filewrite(f, p, n);
    80005894:	fe442603          	lw	a2,-28(s0)
    80005898:	fd843583          	ld	a1,-40(s0)
    8000589c:	fe843503          	ld	a0,-24(s0)
    800058a0:	fffff097          	auipc	ra,0xfffff
    800058a4:	4ec080e7          	jalr	1260(ra) # 80004d8c <filewrite>
    800058a8:	87aa                	mv	a5,a0
}
    800058aa:	853e                	mv	a0,a5
    800058ac:	70a2                	ld	ra,40(sp)
    800058ae:	7402                	ld	s0,32(sp)
    800058b0:	6145                	addi	sp,sp,48
    800058b2:	8082                	ret

00000000800058b4 <sys_close>:
{
    800058b4:	1101                	addi	sp,sp,-32
    800058b6:	ec06                	sd	ra,24(sp)
    800058b8:	e822                	sd	s0,16(sp)
    800058ba:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800058bc:	fe040613          	addi	a2,s0,-32
    800058c0:	fec40593          	addi	a1,s0,-20
    800058c4:	4501                	li	a0,0
    800058c6:	00000097          	auipc	ra,0x0
    800058ca:	cc4080e7          	jalr	-828(ra) # 8000558a <argfd>
    return -1;
    800058ce:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800058d0:	02054463          	bltz	a0,800058f8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800058d4:	ffffc097          	auipc	ra,0xffffc
    800058d8:	0ee080e7          	jalr	238(ra) # 800019c2 <myproc>
    800058dc:	fec42783          	lw	a5,-20(s0)
    800058e0:	07f9                	addi	a5,a5,30
    800058e2:	078e                	slli	a5,a5,0x3
    800058e4:	97aa                	add	a5,a5,a0
    800058e6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800058ea:	fe043503          	ld	a0,-32(s0)
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	2a2080e7          	jalr	674(ra) # 80004b90 <fileclose>
  return 0;
    800058f6:	4781                	li	a5,0
}
    800058f8:	853e                	mv	a0,a5
    800058fa:	60e2                	ld	ra,24(sp)
    800058fc:	6442                	ld	s0,16(sp)
    800058fe:	6105                	addi	sp,sp,32
    80005900:	8082                	ret

0000000080005902 <sys_fstat>:
{
    80005902:	1101                	addi	sp,sp,-32
    80005904:	ec06                	sd	ra,24(sp)
    80005906:	e822                	sd	s0,16(sp)
    80005908:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000590a:	fe840613          	addi	a2,s0,-24
    8000590e:	4581                	li	a1,0
    80005910:	4501                	li	a0,0
    80005912:	00000097          	auipc	ra,0x0
    80005916:	c78080e7          	jalr	-904(ra) # 8000558a <argfd>
    return -1;
    8000591a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000591c:	02054563          	bltz	a0,80005946 <sys_fstat+0x44>
    80005920:	fe040593          	addi	a1,s0,-32
    80005924:	4505                	li	a0,1
    80005926:	ffffd097          	auipc	ra,0xffffd
    8000592a:	6f0080e7          	jalr	1776(ra) # 80003016 <argaddr>
    return -1;
    8000592e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005930:	00054b63          	bltz	a0,80005946 <sys_fstat+0x44>
  return filestat(f, st);
    80005934:	fe043583          	ld	a1,-32(s0)
    80005938:	fe843503          	ld	a0,-24(s0)
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	31c080e7          	jalr	796(ra) # 80004c58 <filestat>
    80005944:	87aa                	mv	a5,a0
}
    80005946:	853e                	mv	a0,a5
    80005948:	60e2                	ld	ra,24(sp)
    8000594a:	6442                	ld	s0,16(sp)
    8000594c:	6105                	addi	sp,sp,32
    8000594e:	8082                	ret

0000000080005950 <sys_link>:
{
    80005950:	7169                	addi	sp,sp,-304
    80005952:	f606                	sd	ra,296(sp)
    80005954:	f222                	sd	s0,288(sp)
    80005956:	ee26                	sd	s1,280(sp)
    80005958:	ea4a                	sd	s2,272(sp)
    8000595a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000595c:	08000613          	li	a2,128
    80005960:	ed040593          	addi	a1,s0,-304
    80005964:	4501                	li	a0,0
    80005966:	ffffd097          	auipc	ra,0xffffd
    8000596a:	6d2080e7          	jalr	1746(ra) # 80003038 <argstr>
    return -1;
    8000596e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005970:	10054e63          	bltz	a0,80005a8c <sys_link+0x13c>
    80005974:	08000613          	li	a2,128
    80005978:	f5040593          	addi	a1,s0,-176
    8000597c:	4505                	li	a0,1
    8000597e:	ffffd097          	auipc	ra,0xffffd
    80005982:	6ba080e7          	jalr	1722(ra) # 80003038 <argstr>
    return -1;
    80005986:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005988:	10054263          	bltz	a0,80005a8c <sys_link+0x13c>
  begin_op();
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	d38080e7          	jalr	-712(ra) # 800046c4 <begin_op>
  if((ip = namei(old)) == 0){
    80005994:	ed040513          	addi	a0,s0,-304
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	b0c080e7          	jalr	-1268(ra) # 800044a4 <namei>
    800059a0:	84aa                	mv	s1,a0
    800059a2:	c551                	beqz	a0,80005a2e <sys_link+0xde>
  ilock(ip);
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	34a080e7          	jalr	842(ra) # 80003cee <ilock>
  if(ip->type == T_DIR){
    800059ac:	04449703          	lh	a4,68(s1)
    800059b0:	4785                	li	a5,1
    800059b2:	08f70463          	beq	a4,a5,80005a3a <sys_link+0xea>
  ip->nlink++;
    800059b6:	04a4d783          	lhu	a5,74(s1)
    800059ba:	2785                	addiw	a5,a5,1
    800059bc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059c0:	8526                	mv	a0,s1
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	262080e7          	jalr	610(ra) # 80003c24 <iupdate>
  iunlock(ip);
    800059ca:	8526                	mv	a0,s1
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	3e4080e7          	jalr	996(ra) # 80003db0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800059d4:	fd040593          	addi	a1,s0,-48
    800059d8:	f5040513          	addi	a0,s0,-176
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	ae6080e7          	jalr	-1306(ra) # 800044c2 <nameiparent>
    800059e4:	892a                	mv	s2,a0
    800059e6:	c935                	beqz	a0,80005a5a <sys_link+0x10a>
  ilock(dp);
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	306080e7          	jalr	774(ra) # 80003cee <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800059f0:	00092703          	lw	a4,0(s2)
    800059f4:	409c                	lw	a5,0(s1)
    800059f6:	04f71d63          	bne	a4,a5,80005a50 <sys_link+0x100>
    800059fa:	40d0                	lw	a2,4(s1)
    800059fc:	fd040593          	addi	a1,s0,-48
    80005a00:	854a                	mv	a0,s2
    80005a02:	fffff097          	auipc	ra,0xfffff
    80005a06:	9e0080e7          	jalr	-1568(ra) # 800043e2 <dirlink>
    80005a0a:	04054363          	bltz	a0,80005a50 <sys_link+0x100>
  iunlockput(dp);
    80005a0e:	854a                	mv	a0,s2
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	540080e7          	jalr	1344(ra) # 80003f50 <iunlockput>
  iput(ip);
    80005a18:	8526                	mv	a0,s1
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	48e080e7          	jalr	1166(ra) # 80003ea8 <iput>
  end_op();
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	d22080e7          	jalr	-734(ra) # 80004744 <end_op>
  return 0;
    80005a2a:	4781                	li	a5,0
    80005a2c:	a085                	j	80005a8c <sys_link+0x13c>
    end_op();
    80005a2e:	fffff097          	auipc	ra,0xfffff
    80005a32:	d16080e7          	jalr	-746(ra) # 80004744 <end_op>
    return -1;
    80005a36:	57fd                	li	a5,-1
    80005a38:	a891                	j	80005a8c <sys_link+0x13c>
    iunlockput(ip);
    80005a3a:	8526                	mv	a0,s1
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	514080e7          	jalr	1300(ra) # 80003f50 <iunlockput>
    end_op();
    80005a44:	fffff097          	auipc	ra,0xfffff
    80005a48:	d00080e7          	jalr	-768(ra) # 80004744 <end_op>
    return -1;
    80005a4c:	57fd                	li	a5,-1
    80005a4e:	a83d                	j	80005a8c <sys_link+0x13c>
    iunlockput(dp);
    80005a50:	854a                	mv	a0,s2
    80005a52:	ffffe097          	auipc	ra,0xffffe
    80005a56:	4fe080e7          	jalr	1278(ra) # 80003f50 <iunlockput>
  ilock(ip);
    80005a5a:	8526                	mv	a0,s1
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	292080e7          	jalr	658(ra) # 80003cee <ilock>
  ip->nlink--;
    80005a64:	04a4d783          	lhu	a5,74(s1)
    80005a68:	37fd                	addiw	a5,a5,-1
    80005a6a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a6e:	8526                	mv	a0,s1
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	1b4080e7          	jalr	436(ra) # 80003c24 <iupdate>
  iunlockput(ip);
    80005a78:	8526                	mv	a0,s1
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	4d6080e7          	jalr	1238(ra) # 80003f50 <iunlockput>
  end_op();
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	cc2080e7          	jalr	-830(ra) # 80004744 <end_op>
  return -1;
    80005a8a:	57fd                	li	a5,-1
}
    80005a8c:	853e                	mv	a0,a5
    80005a8e:	70b2                	ld	ra,296(sp)
    80005a90:	7412                	ld	s0,288(sp)
    80005a92:	64f2                	ld	s1,280(sp)
    80005a94:	6952                	ld	s2,272(sp)
    80005a96:	6155                	addi	sp,sp,304
    80005a98:	8082                	ret

0000000080005a9a <sys_unlink>:
{
    80005a9a:	7151                	addi	sp,sp,-240
    80005a9c:	f586                	sd	ra,232(sp)
    80005a9e:	f1a2                	sd	s0,224(sp)
    80005aa0:	eda6                	sd	s1,216(sp)
    80005aa2:	e9ca                	sd	s2,208(sp)
    80005aa4:	e5ce                	sd	s3,200(sp)
    80005aa6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005aa8:	08000613          	li	a2,128
    80005aac:	f3040593          	addi	a1,s0,-208
    80005ab0:	4501                	li	a0,0
    80005ab2:	ffffd097          	auipc	ra,0xffffd
    80005ab6:	586080e7          	jalr	1414(ra) # 80003038 <argstr>
    80005aba:	18054163          	bltz	a0,80005c3c <sys_unlink+0x1a2>
  begin_op();
    80005abe:	fffff097          	auipc	ra,0xfffff
    80005ac2:	c06080e7          	jalr	-1018(ra) # 800046c4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005ac6:	fb040593          	addi	a1,s0,-80
    80005aca:	f3040513          	addi	a0,s0,-208
    80005ace:	fffff097          	auipc	ra,0xfffff
    80005ad2:	9f4080e7          	jalr	-1548(ra) # 800044c2 <nameiparent>
    80005ad6:	84aa                	mv	s1,a0
    80005ad8:	c979                	beqz	a0,80005bae <sys_unlink+0x114>
  ilock(dp);
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	214080e7          	jalr	532(ra) # 80003cee <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005ae2:	00003597          	auipc	a1,0x3
    80005ae6:	e2e58593          	addi	a1,a1,-466 # 80008910 <syscalls+0x2c0>
    80005aea:	fb040513          	addi	a0,s0,-80
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	6ca080e7          	jalr	1738(ra) # 800041b8 <namecmp>
    80005af6:	14050a63          	beqz	a0,80005c4a <sys_unlink+0x1b0>
    80005afa:	00003597          	auipc	a1,0x3
    80005afe:	e1e58593          	addi	a1,a1,-482 # 80008918 <syscalls+0x2c8>
    80005b02:	fb040513          	addi	a0,s0,-80
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	6b2080e7          	jalr	1714(ra) # 800041b8 <namecmp>
    80005b0e:	12050e63          	beqz	a0,80005c4a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b12:	f2c40613          	addi	a2,s0,-212
    80005b16:	fb040593          	addi	a1,s0,-80
    80005b1a:	8526                	mv	a0,s1
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	6b6080e7          	jalr	1718(ra) # 800041d2 <dirlookup>
    80005b24:	892a                	mv	s2,a0
    80005b26:	12050263          	beqz	a0,80005c4a <sys_unlink+0x1b0>
  ilock(ip);
    80005b2a:	ffffe097          	auipc	ra,0xffffe
    80005b2e:	1c4080e7          	jalr	452(ra) # 80003cee <ilock>
  if(ip->nlink < 1)
    80005b32:	04a91783          	lh	a5,74(s2)
    80005b36:	08f05263          	blez	a5,80005bba <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b3a:	04491703          	lh	a4,68(s2)
    80005b3e:	4785                	li	a5,1
    80005b40:	08f70563          	beq	a4,a5,80005bca <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b44:	4641                	li	a2,16
    80005b46:	4581                	li	a1,0
    80005b48:	fc040513          	addi	a0,s0,-64
    80005b4c:	ffffb097          	auipc	ra,0xffffb
    80005b50:	172080e7          	jalr	370(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b54:	4741                	li	a4,16
    80005b56:	f2c42683          	lw	a3,-212(s0)
    80005b5a:	fc040613          	addi	a2,s0,-64
    80005b5e:	4581                	li	a1,0
    80005b60:	8526                	mv	a0,s1
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	538080e7          	jalr	1336(ra) # 8000409a <writei>
    80005b6a:	47c1                	li	a5,16
    80005b6c:	0af51563          	bne	a0,a5,80005c16 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b70:	04491703          	lh	a4,68(s2)
    80005b74:	4785                	li	a5,1
    80005b76:	0af70863          	beq	a4,a5,80005c26 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b7a:	8526                	mv	a0,s1
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	3d4080e7          	jalr	980(ra) # 80003f50 <iunlockput>
  ip->nlink--;
    80005b84:	04a95783          	lhu	a5,74(s2)
    80005b88:	37fd                	addiw	a5,a5,-1
    80005b8a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b8e:	854a                	mv	a0,s2
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	094080e7          	jalr	148(ra) # 80003c24 <iupdate>
  iunlockput(ip);
    80005b98:	854a                	mv	a0,s2
    80005b9a:	ffffe097          	auipc	ra,0xffffe
    80005b9e:	3b6080e7          	jalr	950(ra) # 80003f50 <iunlockput>
  end_op();
    80005ba2:	fffff097          	auipc	ra,0xfffff
    80005ba6:	ba2080e7          	jalr	-1118(ra) # 80004744 <end_op>
  return 0;
    80005baa:	4501                	li	a0,0
    80005bac:	a84d                	j	80005c5e <sys_unlink+0x1c4>
    end_op();
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	b96080e7          	jalr	-1130(ra) # 80004744 <end_op>
    return -1;
    80005bb6:	557d                	li	a0,-1
    80005bb8:	a05d                	j	80005c5e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005bba:	00003517          	auipc	a0,0x3
    80005bbe:	d8650513          	addi	a0,a0,-634 # 80008940 <syscalls+0x2f0>
    80005bc2:	ffffb097          	auipc	ra,0xffffb
    80005bc6:	968080e7          	jalr	-1688(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bca:	04c92703          	lw	a4,76(s2)
    80005bce:	02000793          	li	a5,32
    80005bd2:	f6e7f9e3          	bgeu	a5,a4,80005b44 <sys_unlink+0xaa>
    80005bd6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bda:	4741                	li	a4,16
    80005bdc:	86ce                	mv	a3,s3
    80005bde:	f1840613          	addi	a2,s0,-232
    80005be2:	4581                	li	a1,0
    80005be4:	854a                	mv	a0,s2
    80005be6:	ffffe097          	auipc	ra,0xffffe
    80005bea:	3bc080e7          	jalr	956(ra) # 80003fa2 <readi>
    80005bee:	47c1                	li	a5,16
    80005bf0:	00f51b63          	bne	a0,a5,80005c06 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005bf4:	f1845783          	lhu	a5,-232(s0)
    80005bf8:	e7a1                	bnez	a5,80005c40 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bfa:	29c1                	addiw	s3,s3,16
    80005bfc:	04c92783          	lw	a5,76(s2)
    80005c00:	fcf9ede3          	bltu	s3,a5,80005bda <sys_unlink+0x140>
    80005c04:	b781                	j	80005b44 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c06:	00003517          	auipc	a0,0x3
    80005c0a:	d5250513          	addi	a0,a0,-686 # 80008958 <syscalls+0x308>
    80005c0e:	ffffb097          	auipc	ra,0xffffb
    80005c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005c16:	00003517          	auipc	a0,0x3
    80005c1a:	d5a50513          	addi	a0,a0,-678 # 80008970 <syscalls+0x320>
    80005c1e:	ffffb097          	auipc	ra,0xffffb
    80005c22:	90c080e7          	jalr	-1780(ra) # 8000052a <panic>
    dp->nlink--;
    80005c26:	04a4d783          	lhu	a5,74(s1)
    80005c2a:	37fd                	addiw	a5,a5,-1
    80005c2c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c30:	8526                	mv	a0,s1
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	ff2080e7          	jalr	-14(ra) # 80003c24 <iupdate>
    80005c3a:	b781                	j	80005b7a <sys_unlink+0xe0>
    return -1;
    80005c3c:	557d                	li	a0,-1
    80005c3e:	a005                	j	80005c5e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c40:	854a                	mv	a0,s2
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	30e080e7          	jalr	782(ra) # 80003f50 <iunlockput>
  iunlockput(dp);
    80005c4a:	8526                	mv	a0,s1
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	304080e7          	jalr	772(ra) # 80003f50 <iunlockput>
  end_op();
    80005c54:	fffff097          	auipc	ra,0xfffff
    80005c58:	af0080e7          	jalr	-1296(ra) # 80004744 <end_op>
  return -1;
    80005c5c:	557d                	li	a0,-1
}
    80005c5e:	70ae                	ld	ra,232(sp)
    80005c60:	740e                	ld	s0,224(sp)
    80005c62:	64ee                	ld	s1,216(sp)
    80005c64:	694e                	ld	s2,208(sp)
    80005c66:	69ae                	ld	s3,200(sp)
    80005c68:	616d                	addi	sp,sp,240
    80005c6a:	8082                	ret

0000000080005c6c <sys_open>:

uint64
sys_open(void)
{
    80005c6c:	7131                	addi	sp,sp,-192
    80005c6e:	fd06                	sd	ra,184(sp)
    80005c70:	f922                	sd	s0,176(sp)
    80005c72:	f526                	sd	s1,168(sp)
    80005c74:	f14a                	sd	s2,160(sp)
    80005c76:	ed4e                	sd	s3,152(sp)
    80005c78:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c7a:	08000613          	li	a2,128
    80005c7e:	f5040593          	addi	a1,s0,-176
    80005c82:	4501                	li	a0,0
    80005c84:	ffffd097          	auipc	ra,0xffffd
    80005c88:	3b4080e7          	jalr	948(ra) # 80003038 <argstr>
    return -1;
    80005c8c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c8e:	0c054163          	bltz	a0,80005d50 <sys_open+0xe4>
    80005c92:	f4c40593          	addi	a1,s0,-180
    80005c96:	4505                	li	a0,1
    80005c98:	ffffd097          	auipc	ra,0xffffd
    80005c9c:	35c080e7          	jalr	860(ra) # 80002ff4 <argint>
    80005ca0:	0a054863          	bltz	a0,80005d50 <sys_open+0xe4>

  begin_op();
    80005ca4:	fffff097          	auipc	ra,0xfffff
    80005ca8:	a20080e7          	jalr	-1504(ra) # 800046c4 <begin_op>

  if(omode & O_CREATE){
    80005cac:	f4c42783          	lw	a5,-180(s0)
    80005cb0:	2007f793          	andi	a5,a5,512
    80005cb4:	cbdd                	beqz	a5,80005d6a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005cb6:	4681                	li	a3,0
    80005cb8:	4601                	li	a2,0
    80005cba:	4589                	li	a1,2
    80005cbc:	f5040513          	addi	a0,s0,-176
    80005cc0:	00000097          	auipc	ra,0x0
    80005cc4:	974080e7          	jalr	-1676(ra) # 80005634 <create>
    80005cc8:	892a                	mv	s2,a0
    if(ip == 0){
    80005cca:	c959                	beqz	a0,80005d60 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ccc:	04491703          	lh	a4,68(s2)
    80005cd0:	478d                	li	a5,3
    80005cd2:	00f71763          	bne	a4,a5,80005ce0 <sys_open+0x74>
    80005cd6:	04695703          	lhu	a4,70(s2)
    80005cda:	47a5                	li	a5,9
    80005cdc:	0ce7ec63          	bltu	a5,a4,80005db4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	df4080e7          	jalr	-524(ra) # 80004ad4 <filealloc>
    80005ce8:	89aa                	mv	s3,a0
    80005cea:	10050263          	beqz	a0,80005dee <sys_open+0x182>
    80005cee:	00000097          	auipc	ra,0x0
    80005cf2:	904080e7          	jalr	-1788(ra) # 800055f2 <fdalloc>
    80005cf6:	84aa                	mv	s1,a0
    80005cf8:	0e054663          	bltz	a0,80005de4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005cfc:	04491703          	lh	a4,68(s2)
    80005d00:	478d                	li	a5,3
    80005d02:	0cf70463          	beq	a4,a5,80005dca <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d06:	4789                	li	a5,2
    80005d08:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d0c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d10:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d14:	f4c42783          	lw	a5,-180(s0)
    80005d18:	0017c713          	xori	a4,a5,1
    80005d1c:	8b05                	andi	a4,a4,1
    80005d1e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d22:	0037f713          	andi	a4,a5,3
    80005d26:	00e03733          	snez	a4,a4
    80005d2a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d2e:	4007f793          	andi	a5,a5,1024
    80005d32:	c791                	beqz	a5,80005d3e <sys_open+0xd2>
    80005d34:	04491703          	lh	a4,68(s2)
    80005d38:	4789                	li	a5,2
    80005d3a:	08f70f63          	beq	a4,a5,80005dd8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d3e:	854a                	mv	a0,s2
    80005d40:	ffffe097          	auipc	ra,0xffffe
    80005d44:	070080e7          	jalr	112(ra) # 80003db0 <iunlock>
  end_op();
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	9fc080e7          	jalr	-1540(ra) # 80004744 <end_op>

  return fd;
}
    80005d50:	8526                	mv	a0,s1
    80005d52:	70ea                	ld	ra,184(sp)
    80005d54:	744a                	ld	s0,176(sp)
    80005d56:	74aa                	ld	s1,168(sp)
    80005d58:	790a                	ld	s2,160(sp)
    80005d5a:	69ea                	ld	s3,152(sp)
    80005d5c:	6129                	addi	sp,sp,192
    80005d5e:	8082                	ret
      end_op();
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	9e4080e7          	jalr	-1564(ra) # 80004744 <end_op>
      return -1;
    80005d68:	b7e5                	j	80005d50 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d6a:	f5040513          	addi	a0,s0,-176
    80005d6e:	ffffe097          	auipc	ra,0xffffe
    80005d72:	736080e7          	jalr	1846(ra) # 800044a4 <namei>
    80005d76:	892a                	mv	s2,a0
    80005d78:	c905                	beqz	a0,80005da8 <sys_open+0x13c>
    ilock(ip);
    80005d7a:	ffffe097          	auipc	ra,0xffffe
    80005d7e:	f74080e7          	jalr	-140(ra) # 80003cee <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d82:	04491703          	lh	a4,68(s2)
    80005d86:	4785                	li	a5,1
    80005d88:	f4f712e3          	bne	a4,a5,80005ccc <sys_open+0x60>
    80005d8c:	f4c42783          	lw	a5,-180(s0)
    80005d90:	dba1                	beqz	a5,80005ce0 <sys_open+0x74>
      iunlockput(ip);
    80005d92:	854a                	mv	a0,s2
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	1bc080e7          	jalr	444(ra) # 80003f50 <iunlockput>
      end_op();
    80005d9c:	fffff097          	auipc	ra,0xfffff
    80005da0:	9a8080e7          	jalr	-1624(ra) # 80004744 <end_op>
      return -1;
    80005da4:	54fd                	li	s1,-1
    80005da6:	b76d                	j	80005d50 <sys_open+0xe4>
      end_op();
    80005da8:	fffff097          	auipc	ra,0xfffff
    80005dac:	99c080e7          	jalr	-1636(ra) # 80004744 <end_op>
      return -1;
    80005db0:	54fd                	li	s1,-1
    80005db2:	bf79                	j	80005d50 <sys_open+0xe4>
    iunlockput(ip);
    80005db4:	854a                	mv	a0,s2
    80005db6:	ffffe097          	auipc	ra,0xffffe
    80005dba:	19a080e7          	jalr	410(ra) # 80003f50 <iunlockput>
    end_op();
    80005dbe:	fffff097          	auipc	ra,0xfffff
    80005dc2:	986080e7          	jalr	-1658(ra) # 80004744 <end_op>
    return -1;
    80005dc6:	54fd                	li	s1,-1
    80005dc8:	b761                	j	80005d50 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005dca:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005dce:	04691783          	lh	a5,70(s2)
    80005dd2:	02f99223          	sh	a5,36(s3)
    80005dd6:	bf2d                	j	80005d10 <sys_open+0xa4>
    itrunc(ip);
    80005dd8:	854a                	mv	a0,s2
    80005dda:	ffffe097          	auipc	ra,0xffffe
    80005dde:	022080e7          	jalr	34(ra) # 80003dfc <itrunc>
    80005de2:	bfb1                	j	80005d3e <sys_open+0xd2>
      fileclose(f);
    80005de4:	854e                	mv	a0,s3
    80005de6:	fffff097          	auipc	ra,0xfffff
    80005dea:	daa080e7          	jalr	-598(ra) # 80004b90 <fileclose>
    iunlockput(ip);
    80005dee:	854a                	mv	a0,s2
    80005df0:	ffffe097          	auipc	ra,0xffffe
    80005df4:	160080e7          	jalr	352(ra) # 80003f50 <iunlockput>
    end_op();
    80005df8:	fffff097          	auipc	ra,0xfffff
    80005dfc:	94c080e7          	jalr	-1716(ra) # 80004744 <end_op>
    return -1;
    80005e00:	54fd                	li	s1,-1
    80005e02:	b7b9                	j	80005d50 <sys_open+0xe4>

0000000080005e04 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e04:	7175                	addi	sp,sp,-144
    80005e06:	e506                	sd	ra,136(sp)
    80005e08:	e122                	sd	s0,128(sp)
    80005e0a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e0c:	fffff097          	auipc	ra,0xfffff
    80005e10:	8b8080e7          	jalr	-1864(ra) # 800046c4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e14:	08000613          	li	a2,128
    80005e18:	f7040593          	addi	a1,s0,-144
    80005e1c:	4501                	li	a0,0
    80005e1e:	ffffd097          	auipc	ra,0xffffd
    80005e22:	21a080e7          	jalr	538(ra) # 80003038 <argstr>
    80005e26:	02054963          	bltz	a0,80005e58 <sys_mkdir+0x54>
    80005e2a:	4681                	li	a3,0
    80005e2c:	4601                	li	a2,0
    80005e2e:	4585                	li	a1,1
    80005e30:	f7040513          	addi	a0,s0,-144
    80005e34:	00000097          	auipc	ra,0x0
    80005e38:	800080e7          	jalr	-2048(ra) # 80005634 <create>
    80005e3c:	cd11                	beqz	a0,80005e58 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e3e:	ffffe097          	auipc	ra,0xffffe
    80005e42:	112080e7          	jalr	274(ra) # 80003f50 <iunlockput>
  end_op();
    80005e46:	fffff097          	auipc	ra,0xfffff
    80005e4a:	8fe080e7          	jalr	-1794(ra) # 80004744 <end_op>
  return 0;
    80005e4e:	4501                	li	a0,0
}
    80005e50:	60aa                	ld	ra,136(sp)
    80005e52:	640a                	ld	s0,128(sp)
    80005e54:	6149                	addi	sp,sp,144
    80005e56:	8082                	ret
    end_op();
    80005e58:	fffff097          	auipc	ra,0xfffff
    80005e5c:	8ec080e7          	jalr	-1812(ra) # 80004744 <end_op>
    return -1;
    80005e60:	557d                	li	a0,-1
    80005e62:	b7fd                	j	80005e50 <sys_mkdir+0x4c>

0000000080005e64 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e64:	7135                	addi	sp,sp,-160
    80005e66:	ed06                	sd	ra,152(sp)
    80005e68:	e922                	sd	s0,144(sp)
    80005e6a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e6c:	fffff097          	auipc	ra,0xfffff
    80005e70:	858080e7          	jalr	-1960(ra) # 800046c4 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e74:	08000613          	li	a2,128
    80005e78:	f7040593          	addi	a1,s0,-144
    80005e7c:	4501                	li	a0,0
    80005e7e:	ffffd097          	auipc	ra,0xffffd
    80005e82:	1ba080e7          	jalr	442(ra) # 80003038 <argstr>
    80005e86:	04054a63          	bltz	a0,80005eda <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e8a:	f6c40593          	addi	a1,s0,-148
    80005e8e:	4505                	li	a0,1
    80005e90:	ffffd097          	auipc	ra,0xffffd
    80005e94:	164080e7          	jalr	356(ra) # 80002ff4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e98:	04054163          	bltz	a0,80005eda <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005e9c:	f6840593          	addi	a1,s0,-152
    80005ea0:	4509                	li	a0,2
    80005ea2:	ffffd097          	auipc	ra,0xffffd
    80005ea6:	152080e7          	jalr	338(ra) # 80002ff4 <argint>
     argint(1, &major) < 0 ||
    80005eaa:	02054863          	bltz	a0,80005eda <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005eae:	f6841683          	lh	a3,-152(s0)
    80005eb2:	f6c41603          	lh	a2,-148(s0)
    80005eb6:	458d                	li	a1,3
    80005eb8:	f7040513          	addi	a0,s0,-144
    80005ebc:	fffff097          	auipc	ra,0xfffff
    80005ec0:	778080e7          	jalr	1912(ra) # 80005634 <create>
     argint(2, &minor) < 0 ||
    80005ec4:	c919                	beqz	a0,80005eda <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ec6:	ffffe097          	auipc	ra,0xffffe
    80005eca:	08a080e7          	jalr	138(ra) # 80003f50 <iunlockput>
  end_op();
    80005ece:	fffff097          	auipc	ra,0xfffff
    80005ed2:	876080e7          	jalr	-1930(ra) # 80004744 <end_op>
  return 0;
    80005ed6:	4501                	li	a0,0
    80005ed8:	a031                	j	80005ee4 <sys_mknod+0x80>
    end_op();
    80005eda:	fffff097          	auipc	ra,0xfffff
    80005ede:	86a080e7          	jalr	-1942(ra) # 80004744 <end_op>
    return -1;
    80005ee2:	557d                	li	a0,-1
}
    80005ee4:	60ea                	ld	ra,152(sp)
    80005ee6:	644a                	ld	s0,144(sp)
    80005ee8:	610d                	addi	sp,sp,160
    80005eea:	8082                	ret

0000000080005eec <sys_chdir>:

uint64
sys_chdir(void)
{
    80005eec:	7135                	addi	sp,sp,-160
    80005eee:	ed06                	sd	ra,152(sp)
    80005ef0:	e922                	sd	s0,144(sp)
    80005ef2:	e526                	sd	s1,136(sp)
    80005ef4:	e14a                	sd	s2,128(sp)
    80005ef6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	aca080e7          	jalr	-1334(ra) # 800019c2 <myproc>
    80005f00:	892a                	mv	s2,a0
  
  begin_op();
    80005f02:	ffffe097          	auipc	ra,0xffffe
    80005f06:	7c2080e7          	jalr	1986(ra) # 800046c4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f0a:	08000613          	li	a2,128
    80005f0e:	f6040593          	addi	a1,s0,-160
    80005f12:	4501                	li	a0,0
    80005f14:	ffffd097          	auipc	ra,0xffffd
    80005f18:	124080e7          	jalr	292(ra) # 80003038 <argstr>
    80005f1c:	04054b63          	bltz	a0,80005f72 <sys_chdir+0x86>
    80005f20:	f6040513          	addi	a0,s0,-160
    80005f24:	ffffe097          	auipc	ra,0xffffe
    80005f28:	580080e7          	jalr	1408(ra) # 800044a4 <namei>
    80005f2c:	84aa                	mv	s1,a0
    80005f2e:	c131                	beqz	a0,80005f72 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f30:	ffffe097          	auipc	ra,0xffffe
    80005f34:	dbe080e7          	jalr	-578(ra) # 80003cee <ilock>
  if(ip->type != T_DIR){
    80005f38:	04449703          	lh	a4,68(s1)
    80005f3c:	4785                	li	a5,1
    80005f3e:	04f71063          	bne	a4,a5,80005f7e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f42:	8526                	mv	a0,s1
    80005f44:	ffffe097          	auipc	ra,0xffffe
    80005f48:	e6c080e7          	jalr	-404(ra) # 80003db0 <iunlock>
  iput(p->cwd);
    80005f4c:	17093503          	ld	a0,368(s2)
    80005f50:	ffffe097          	auipc	ra,0xffffe
    80005f54:	f58080e7          	jalr	-168(ra) # 80003ea8 <iput>
  end_op();
    80005f58:	ffffe097          	auipc	ra,0xffffe
    80005f5c:	7ec080e7          	jalr	2028(ra) # 80004744 <end_op>
  p->cwd = ip;
    80005f60:	16993823          	sd	s1,368(s2)
  return 0;
    80005f64:	4501                	li	a0,0
}
    80005f66:	60ea                	ld	ra,152(sp)
    80005f68:	644a                	ld	s0,144(sp)
    80005f6a:	64aa                	ld	s1,136(sp)
    80005f6c:	690a                	ld	s2,128(sp)
    80005f6e:	610d                	addi	sp,sp,160
    80005f70:	8082                	ret
    end_op();
    80005f72:	ffffe097          	auipc	ra,0xffffe
    80005f76:	7d2080e7          	jalr	2002(ra) # 80004744 <end_op>
    return -1;
    80005f7a:	557d                	li	a0,-1
    80005f7c:	b7ed                	j	80005f66 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f7e:	8526                	mv	a0,s1
    80005f80:	ffffe097          	auipc	ra,0xffffe
    80005f84:	fd0080e7          	jalr	-48(ra) # 80003f50 <iunlockput>
    end_op();
    80005f88:	ffffe097          	auipc	ra,0xffffe
    80005f8c:	7bc080e7          	jalr	1980(ra) # 80004744 <end_op>
    return -1;
    80005f90:	557d                	li	a0,-1
    80005f92:	bfd1                	j	80005f66 <sys_chdir+0x7a>

0000000080005f94 <sys_exec>:

uint64
sys_exec(void)
{
    80005f94:	7145                	addi	sp,sp,-464
    80005f96:	e786                	sd	ra,456(sp)
    80005f98:	e3a2                	sd	s0,448(sp)
    80005f9a:	ff26                	sd	s1,440(sp)
    80005f9c:	fb4a                	sd	s2,432(sp)
    80005f9e:	f74e                	sd	s3,424(sp)
    80005fa0:	f352                	sd	s4,416(sp)
    80005fa2:	ef56                	sd	s5,408(sp)
    80005fa4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fa6:	08000613          	li	a2,128
    80005faa:	f4040593          	addi	a1,s0,-192
    80005fae:	4501                	li	a0,0
    80005fb0:	ffffd097          	auipc	ra,0xffffd
    80005fb4:	088080e7          	jalr	136(ra) # 80003038 <argstr>
    return -1;
    80005fb8:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fba:	0c054a63          	bltz	a0,8000608e <sys_exec+0xfa>
    80005fbe:	e3840593          	addi	a1,s0,-456
    80005fc2:	4505                	li	a0,1
    80005fc4:	ffffd097          	auipc	ra,0xffffd
    80005fc8:	052080e7          	jalr	82(ra) # 80003016 <argaddr>
    80005fcc:	0c054163          	bltz	a0,8000608e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005fd0:	10000613          	li	a2,256
    80005fd4:	4581                	li	a1,0
    80005fd6:	e4040513          	addi	a0,s0,-448
    80005fda:	ffffb097          	auipc	ra,0xffffb
    80005fde:	ce4080e7          	jalr	-796(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005fe2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005fe6:	89a6                	mv	s3,s1
    80005fe8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005fea:	02000a13          	li	s4,32
    80005fee:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ff2:	00391793          	slli	a5,s2,0x3
    80005ff6:	e3040593          	addi	a1,s0,-464
    80005ffa:	e3843503          	ld	a0,-456(s0)
    80005ffe:	953e                	add	a0,a0,a5
    80006000:	ffffd097          	auipc	ra,0xffffd
    80006004:	f5a080e7          	jalr	-166(ra) # 80002f5a <fetchaddr>
    80006008:	02054a63          	bltz	a0,8000603c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000600c:	e3043783          	ld	a5,-464(s0)
    80006010:	c3b9                	beqz	a5,80006056 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006012:	ffffb097          	auipc	ra,0xffffb
    80006016:	ac0080e7          	jalr	-1344(ra) # 80000ad2 <kalloc>
    8000601a:	85aa                	mv	a1,a0
    8000601c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006020:	cd11                	beqz	a0,8000603c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006022:	6605                	lui	a2,0x1
    80006024:	e3043503          	ld	a0,-464(s0)
    80006028:	ffffd097          	auipc	ra,0xffffd
    8000602c:	f84080e7          	jalr	-124(ra) # 80002fac <fetchstr>
    80006030:	00054663          	bltz	a0,8000603c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006034:	0905                	addi	s2,s2,1
    80006036:	09a1                	addi	s3,s3,8
    80006038:	fb491be3          	bne	s2,s4,80005fee <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000603c:	10048913          	addi	s2,s1,256
    80006040:	6088                	ld	a0,0(s1)
    80006042:	c529                	beqz	a0,8000608c <sys_exec+0xf8>
    kfree(argv[i]);
    80006044:	ffffb097          	auipc	ra,0xffffb
    80006048:	992080e7          	jalr	-1646(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000604c:	04a1                	addi	s1,s1,8
    8000604e:	ff2499e3          	bne	s1,s2,80006040 <sys_exec+0xac>
  return -1;
    80006052:	597d                	li	s2,-1
    80006054:	a82d                	j	8000608e <sys_exec+0xfa>
      argv[i] = 0;
    80006056:	0a8e                	slli	s5,s5,0x3
    80006058:	fc040793          	addi	a5,s0,-64
    8000605c:	9abe                	add	s5,s5,a5
    8000605e:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80006062:	e4040593          	addi	a1,s0,-448
    80006066:	f4040513          	addi	a0,s0,-192
    8000606a:	fffff097          	auipc	ra,0xfffff
    8000606e:	178080e7          	jalr	376(ra) # 800051e2 <exec>
    80006072:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006074:	10048993          	addi	s3,s1,256
    80006078:	6088                	ld	a0,0(s1)
    8000607a:	c911                	beqz	a0,8000608e <sys_exec+0xfa>
    kfree(argv[i]);
    8000607c:	ffffb097          	auipc	ra,0xffffb
    80006080:	95a080e7          	jalr	-1702(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006084:	04a1                	addi	s1,s1,8
    80006086:	ff3499e3          	bne	s1,s3,80006078 <sys_exec+0xe4>
    8000608a:	a011                	j	8000608e <sys_exec+0xfa>
  return -1;
    8000608c:	597d                	li	s2,-1
}
    8000608e:	854a                	mv	a0,s2
    80006090:	60be                	ld	ra,456(sp)
    80006092:	641e                	ld	s0,448(sp)
    80006094:	74fa                	ld	s1,440(sp)
    80006096:	795a                	ld	s2,432(sp)
    80006098:	79ba                	ld	s3,424(sp)
    8000609a:	7a1a                	ld	s4,416(sp)
    8000609c:	6afa                	ld	s5,408(sp)
    8000609e:	6179                	addi	sp,sp,464
    800060a0:	8082                	ret

00000000800060a2 <sys_pipe>:

uint64
sys_pipe(void)
{
    800060a2:	7139                	addi	sp,sp,-64
    800060a4:	fc06                	sd	ra,56(sp)
    800060a6:	f822                	sd	s0,48(sp)
    800060a8:	f426                	sd	s1,40(sp)
    800060aa:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060ac:	ffffc097          	auipc	ra,0xffffc
    800060b0:	916080e7          	jalr	-1770(ra) # 800019c2 <myproc>
    800060b4:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800060b6:	fd840593          	addi	a1,s0,-40
    800060ba:	4501                	li	a0,0
    800060bc:	ffffd097          	auipc	ra,0xffffd
    800060c0:	f5a080e7          	jalr	-166(ra) # 80003016 <argaddr>
    return -1;
    800060c4:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800060c6:	0e054063          	bltz	a0,800061a6 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800060ca:	fc840593          	addi	a1,s0,-56
    800060ce:	fd040513          	addi	a0,s0,-48
    800060d2:	fffff097          	auipc	ra,0xfffff
    800060d6:	dee080e7          	jalr	-530(ra) # 80004ec0 <pipealloc>
    return -1;
    800060da:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800060dc:	0c054563          	bltz	a0,800061a6 <sys_pipe+0x104>
  fd0 = -1;
    800060e0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800060e4:	fd043503          	ld	a0,-48(s0)
    800060e8:	fffff097          	auipc	ra,0xfffff
    800060ec:	50a080e7          	jalr	1290(ra) # 800055f2 <fdalloc>
    800060f0:	fca42223          	sw	a0,-60(s0)
    800060f4:	08054c63          	bltz	a0,8000618c <sys_pipe+0xea>
    800060f8:	fc843503          	ld	a0,-56(s0)
    800060fc:	fffff097          	auipc	ra,0xfffff
    80006100:	4f6080e7          	jalr	1270(ra) # 800055f2 <fdalloc>
    80006104:	fca42023          	sw	a0,-64(s0)
    80006108:	06054863          	bltz	a0,80006178 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000610c:	4691                	li	a3,4
    8000610e:	fc440613          	addi	a2,s0,-60
    80006112:	fd843583          	ld	a1,-40(s0)
    80006116:	78a8                	ld	a0,112(s1)
    80006118:	ffffb097          	auipc	ra,0xffffb
    8000611c:	526080e7          	jalr	1318(ra) # 8000163e <copyout>
    80006120:	02054063          	bltz	a0,80006140 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006124:	4691                	li	a3,4
    80006126:	fc040613          	addi	a2,s0,-64
    8000612a:	fd843583          	ld	a1,-40(s0)
    8000612e:	0591                	addi	a1,a1,4
    80006130:	78a8                	ld	a0,112(s1)
    80006132:	ffffb097          	auipc	ra,0xffffb
    80006136:	50c080e7          	jalr	1292(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000613a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000613c:	06055563          	bgez	a0,800061a6 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006140:	fc442783          	lw	a5,-60(s0)
    80006144:	07f9                	addi	a5,a5,30
    80006146:	078e                	slli	a5,a5,0x3
    80006148:	97a6                	add	a5,a5,s1
    8000614a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000614e:	fc042503          	lw	a0,-64(s0)
    80006152:	0579                	addi	a0,a0,30
    80006154:	050e                	slli	a0,a0,0x3
    80006156:	9526                	add	a0,a0,s1
    80006158:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000615c:	fd043503          	ld	a0,-48(s0)
    80006160:	fffff097          	auipc	ra,0xfffff
    80006164:	a30080e7          	jalr	-1488(ra) # 80004b90 <fileclose>
    fileclose(wf);
    80006168:	fc843503          	ld	a0,-56(s0)
    8000616c:	fffff097          	auipc	ra,0xfffff
    80006170:	a24080e7          	jalr	-1500(ra) # 80004b90 <fileclose>
    return -1;
    80006174:	57fd                	li	a5,-1
    80006176:	a805                	j	800061a6 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006178:	fc442783          	lw	a5,-60(s0)
    8000617c:	0007c863          	bltz	a5,8000618c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006180:	01e78513          	addi	a0,a5,30
    80006184:	050e                	slli	a0,a0,0x3
    80006186:	9526                	add	a0,a0,s1
    80006188:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000618c:	fd043503          	ld	a0,-48(s0)
    80006190:	fffff097          	auipc	ra,0xfffff
    80006194:	a00080e7          	jalr	-1536(ra) # 80004b90 <fileclose>
    fileclose(wf);
    80006198:	fc843503          	ld	a0,-56(s0)
    8000619c:	fffff097          	auipc	ra,0xfffff
    800061a0:	9f4080e7          	jalr	-1548(ra) # 80004b90 <fileclose>
    return -1;
    800061a4:	57fd                	li	a5,-1
}
    800061a6:	853e                	mv	a0,a5
    800061a8:	70e2                	ld	ra,56(sp)
    800061aa:	7442                	ld	s0,48(sp)
    800061ac:	74a2                	ld	s1,40(sp)
    800061ae:	6121                	addi	sp,sp,64
    800061b0:	8082                	ret
	...

00000000800061c0 <kernelvec>:
    800061c0:	7111                	addi	sp,sp,-256
    800061c2:	e006                	sd	ra,0(sp)
    800061c4:	e40a                	sd	sp,8(sp)
    800061c6:	e80e                	sd	gp,16(sp)
    800061c8:	ec12                	sd	tp,24(sp)
    800061ca:	f016                	sd	t0,32(sp)
    800061cc:	f41a                	sd	t1,40(sp)
    800061ce:	f81e                	sd	t2,48(sp)
    800061d0:	fc22                	sd	s0,56(sp)
    800061d2:	e0a6                	sd	s1,64(sp)
    800061d4:	e4aa                	sd	a0,72(sp)
    800061d6:	e8ae                	sd	a1,80(sp)
    800061d8:	ecb2                	sd	a2,88(sp)
    800061da:	f0b6                	sd	a3,96(sp)
    800061dc:	f4ba                	sd	a4,104(sp)
    800061de:	f8be                	sd	a5,112(sp)
    800061e0:	fcc2                	sd	a6,120(sp)
    800061e2:	e146                	sd	a7,128(sp)
    800061e4:	e54a                	sd	s2,136(sp)
    800061e6:	e94e                	sd	s3,144(sp)
    800061e8:	ed52                	sd	s4,152(sp)
    800061ea:	f156                	sd	s5,160(sp)
    800061ec:	f55a                	sd	s6,168(sp)
    800061ee:	f95e                	sd	s7,176(sp)
    800061f0:	fd62                	sd	s8,184(sp)
    800061f2:	e1e6                	sd	s9,192(sp)
    800061f4:	e5ea                	sd	s10,200(sp)
    800061f6:	e9ee                	sd	s11,208(sp)
    800061f8:	edf2                	sd	t3,216(sp)
    800061fa:	f1f6                	sd	t4,224(sp)
    800061fc:	f5fa                	sd	t5,232(sp)
    800061fe:	f9fe                	sd	t6,240(sp)
    80006200:	c17fc0ef          	jal	ra,80002e16 <kerneltrap>
    80006204:	6082                	ld	ra,0(sp)
    80006206:	6122                	ld	sp,8(sp)
    80006208:	61c2                	ld	gp,16(sp)
    8000620a:	7282                	ld	t0,32(sp)
    8000620c:	7322                	ld	t1,40(sp)
    8000620e:	73c2                	ld	t2,48(sp)
    80006210:	7462                	ld	s0,56(sp)
    80006212:	6486                	ld	s1,64(sp)
    80006214:	6526                	ld	a0,72(sp)
    80006216:	65c6                	ld	a1,80(sp)
    80006218:	6666                	ld	a2,88(sp)
    8000621a:	7686                	ld	a3,96(sp)
    8000621c:	7726                	ld	a4,104(sp)
    8000621e:	77c6                	ld	a5,112(sp)
    80006220:	7866                	ld	a6,120(sp)
    80006222:	688a                	ld	a7,128(sp)
    80006224:	692a                	ld	s2,136(sp)
    80006226:	69ca                	ld	s3,144(sp)
    80006228:	6a6a                	ld	s4,152(sp)
    8000622a:	7a8a                	ld	s5,160(sp)
    8000622c:	7b2a                	ld	s6,168(sp)
    8000622e:	7bca                	ld	s7,176(sp)
    80006230:	7c6a                	ld	s8,184(sp)
    80006232:	6c8e                	ld	s9,192(sp)
    80006234:	6d2e                	ld	s10,200(sp)
    80006236:	6dce                	ld	s11,208(sp)
    80006238:	6e6e                	ld	t3,216(sp)
    8000623a:	7e8e                	ld	t4,224(sp)
    8000623c:	7f2e                	ld	t5,232(sp)
    8000623e:	7fce                	ld	t6,240(sp)
    80006240:	6111                	addi	sp,sp,256
    80006242:	10200073          	sret
    80006246:	00000013          	nop
    8000624a:	00000013          	nop
    8000624e:	0001                	nop

0000000080006250 <timervec>:
    80006250:	34051573          	csrrw	a0,mscratch,a0
    80006254:	e10c                	sd	a1,0(a0)
    80006256:	e510                	sd	a2,8(a0)
    80006258:	e914                	sd	a3,16(a0)
    8000625a:	6d0c                	ld	a1,24(a0)
    8000625c:	7110                	ld	a2,32(a0)
    8000625e:	6194                	ld	a3,0(a1)
    80006260:	96b2                	add	a3,a3,a2
    80006262:	e194                	sd	a3,0(a1)
    80006264:	4589                	li	a1,2
    80006266:	14459073          	csrw	sip,a1
    8000626a:	6914                	ld	a3,16(a0)
    8000626c:	6510                	ld	a2,8(a0)
    8000626e:	610c                	ld	a1,0(a0)
    80006270:	34051573          	csrrw	a0,mscratch,a0
    80006274:	30200073          	mret
	...

000000008000627a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000627a:	1141                	addi	sp,sp,-16
    8000627c:	e422                	sd	s0,8(sp)
    8000627e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006280:	0c0007b7          	lui	a5,0xc000
    80006284:	4705                	li	a4,1
    80006286:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006288:	c3d8                	sw	a4,4(a5)
}
    8000628a:	6422                	ld	s0,8(sp)
    8000628c:	0141                	addi	sp,sp,16
    8000628e:	8082                	ret

0000000080006290 <plicinithart>:

void
plicinithart(void)
{
    80006290:	1141                	addi	sp,sp,-16
    80006292:	e406                	sd	ra,8(sp)
    80006294:	e022                	sd	s0,0(sp)
    80006296:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006298:	ffffb097          	auipc	ra,0xffffb
    8000629c:	6fe080e7          	jalr	1790(ra) # 80001996 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062a0:	0085171b          	slliw	a4,a0,0x8
    800062a4:	0c0027b7          	lui	a5,0xc002
    800062a8:	97ba                	add	a5,a5,a4
    800062aa:	40200713          	li	a4,1026
    800062ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062b2:	00d5151b          	slliw	a0,a0,0xd
    800062b6:	0c2017b7          	lui	a5,0xc201
    800062ba:	953e                	add	a0,a0,a5
    800062bc:	00052023          	sw	zero,0(a0)
}
    800062c0:	60a2                	ld	ra,8(sp)
    800062c2:	6402                	ld	s0,0(sp)
    800062c4:	0141                	addi	sp,sp,16
    800062c6:	8082                	ret

00000000800062c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062c8:	1141                	addi	sp,sp,-16
    800062ca:	e406                	sd	ra,8(sp)
    800062cc:	e022                	sd	s0,0(sp)
    800062ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062d0:	ffffb097          	auipc	ra,0xffffb
    800062d4:	6c6080e7          	jalr	1734(ra) # 80001996 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800062d8:	00d5179b          	slliw	a5,a0,0xd
    800062dc:	0c201537          	lui	a0,0xc201
    800062e0:	953e                	add	a0,a0,a5
  return irq;
}
    800062e2:	4148                	lw	a0,4(a0)
    800062e4:	60a2                	ld	ra,8(sp)
    800062e6:	6402                	ld	s0,0(sp)
    800062e8:	0141                	addi	sp,sp,16
    800062ea:	8082                	ret

00000000800062ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800062ec:	1101                	addi	sp,sp,-32
    800062ee:	ec06                	sd	ra,24(sp)
    800062f0:	e822                	sd	s0,16(sp)
    800062f2:	e426                	sd	s1,8(sp)
    800062f4:	1000                	addi	s0,sp,32
    800062f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800062f8:	ffffb097          	auipc	ra,0xffffb
    800062fc:	69e080e7          	jalr	1694(ra) # 80001996 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006300:	00d5151b          	slliw	a0,a0,0xd
    80006304:	0c2017b7          	lui	a5,0xc201
    80006308:	97aa                	add	a5,a5,a0
    8000630a:	c3c4                	sw	s1,4(a5)
}
    8000630c:	60e2                	ld	ra,24(sp)
    8000630e:	6442                	ld	s0,16(sp)
    80006310:	64a2                	ld	s1,8(sp)
    80006312:	6105                	addi	sp,sp,32
    80006314:	8082                	ret

0000000080006316 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006316:	1141                	addi	sp,sp,-16
    80006318:	e406                	sd	ra,8(sp)
    8000631a:	e022                	sd	s0,0(sp)
    8000631c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000631e:	479d                	li	a5,7
    80006320:	06a7c963          	blt	a5,a0,80006392 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006324:	0001d797          	auipc	a5,0x1d
    80006328:	cdc78793          	addi	a5,a5,-804 # 80023000 <disk>
    8000632c:	00a78733          	add	a4,a5,a0
    80006330:	6789                	lui	a5,0x2
    80006332:	97ba                	add	a5,a5,a4
    80006334:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006338:	e7ad                	bnez	a5,800063a2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000633a:	00451793          	slli	a5,a0,0x4
    8000633e:	0001f717          	auipc	a4,0x1f
    80006342:	cc270713          	addi	a4,a4,-830 # 80025000 <disk+0x2000>
    80006346:	6314                	ld	a3,0(a4)
    80006348:	96be                	add	a3,a3,a5
    8000634a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000634e:	6314                	ld	a3,0(a4)
    80006350:	96be                	add	a3,a3,a5
    80006352:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006356:	6314                	ld	a3,0(a4)
    80006358:	96be                	add	a3,a3,a5
    8000635a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000635e:	6318                	ld	a4,0(a4)
    80006360:	97ba                	add	a5,a5,a4
    80006362:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006366:	0001d797          	auipc	a5,0x1d
    8000636a:	c9a78793          	addi	a5,a5,-870 # 80023000 <disk>
    8000636e:	97aa                	add	a5,a5,a0
    80006370:	6509                	lui	a0,0x2
    80006372:	953e                	add	a0,a0,a5
    80006374:	4785                	li	a5,1
    80006376:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000637a:	0001f517          	auipc	a0,0x1f
    8000637e:	c9e50513          	addi	a0,a0,-866 # 80025018 <disk+0x2018>
    80006382:	ffffc097          	auipc	ra,0xffffc
    80006386:	0ec080e7          	jalr	236(ra) # 8000246e <wakeup>
}
    8000638a:	60a2                	ld	ra,8(sp)
    8000638c:	6402                	ld	s0,0(sp)
    8000638e:	0141                	addi	sp,sp,16
    80006390:	8082                	ret
    panic("free_desc 1");
    80006392:	00002517          	auipc	a0,0x2
    80006396:	5ee50513          	addi	a0,a0,1518 # 80008980 <syscalls+0x330>
    8000639a:	ffffa097          	auipc	ra,0xffffa
    8000639e:	190080e7          	jalr	400(ra) # 8000052a <panic>
    panic("free_desc 2");
    800063a2:	00002517          	auipc	a0,0x2
    800063a6:	5ee50513          	addi	a0,a0,1518 # 80008990 <syscalls+0x340>
    800063aa:	ffffa097          	auipc	ra,0xffffa
    800063ae:	180080e7          	jalr	384(ra) # 8000052a <panic>

00000000800063b2 <virtio_disk_init>:
{
    800063b2:	1101                	addi	sp,sp,-32
    800063b4:	ec06                	sd	ra,24(sp)
    800063b6:	e822                	sd	s0,16(sp)
    800063b8:	e426                	sd	s1,8(sp)
    800063ba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063bc:	00002597          	auipc	a1,0x2
    800063c0:	5e458593          	addi	a1,a1,1508 # 800089a0 <syscalls+0x350>
    800063c4:	0001f517          	auipc	a0,0x1f
    800063c8:	d6450513          	addi	a0,a0,-668 # 80025128 <disk+0x2128>
    800063cc:	ffffa097          	auipc	ra,0xffffa
    800063d0:	766080e7          	jalr	1894(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063d4:	100017b7          	lui	a5,0x10001
    800063d8:	4398                	lw	a4,0(a5)
    800063da:	2701                	sext.w	a4,a4
    800063dc:	747277b7          	lui	a5,0x74727
    800063e0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800063e4:	0ef71163          	bne	a4,a5,800064c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800063e8:	100017b7          	lui	a5,0x10001
    800063ec:	43dc                	lw	a5,4(a5)
    800063ee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063f0:	4705                	li	a4,1
    800063f2:	0ce79a63          	bne	a5,a4,800064c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063f6:	100017b7          	lui	a5,0x10001
    800063fa:	479c                	lw	a5,8(a5)
    800063fc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800063fe:	4709                	li	a4,2
    80006400:	0ce79363          	bne	a5,a4,800064c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006404:	100017b7          	lui	a5,0x10001
    80006408:	47d8                	lw	a4,12(a5)
    8000640a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000640c:	554d47b7          	lui	a5,0x554d4
    80006410:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006414:	0af71963          	bne	a4,a5,800064c6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006418:	100017b7          	lui	a5,0x10001
    8000641c:	4705                	li	a4,1
    8000641e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006420:	470d                	li	a4,3
    80006422:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006424:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006426:	c7ffe737          	lui	a4,0xc7ffe
    8000642a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000642e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006430:	2701                	sext.w	a4,a4
    80006432:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006434:	472d                	li	a4,11
    80006436:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006438:	473d                	li	a4,15
    8000643a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000643c:	6705                	lui	a4,0x1
    8000643e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006440:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006444:	5bdc                	lw	a5,52(a5)
    80006446:	2781                	sext.w	a5,a5
  if(max == 0)
    80006448:	c7d9                	beqz	a5,800064d6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000644a:	471d                	li	a4,7
    8000644c:	08f77d63          	bgeu	a4,a5,800064e6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006450:	100014b7          	lui	s1,0x10001
    80006454:	47a1                	li	a5,8
    80006456:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006458:	6609                	lui	a2,0x2
    8000645a:	4581                	li	a1,0
    8000645c:	0001d517          	auipc	a0,0x1d
    80006460:	ba450513          	addi	a0,a0,-1116 # 80023000 <disk>
    80006464:	ffffb097          	auipc	ra,0xffffb
    80006468:	85a080e7          	jalr	-1958(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000646c:	0001d717          	auipc	a4,0x1d
    80006470:	b9470713          	addi	a4,a4,-1132 # 80023000 <disk>
    80006474:	00c75793          	srli	a5,a4,0xc
    80006478:	2781                	sext.w	a5,a5
    8000647a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000647c:	0001f797          	auipc	a5,0x1f
    80006480:	b8478793          	addi	a5,a5,-1148 # 80025000 <disk+0x2000>
    80006484:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006486:	0001d717          	auipc	a4,0x1d
    8000648a:	bfa70713          	addi	a4,a4,-1030 # 80023080 <disk+0x80>
    8000648e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006490:	0001e717          	auipc	a4,0x1e
    80006494:	b7070713          	addi	a4,a4,-1168 # 80024000 <disk+0x1000>
    80006498:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000649a:	4705                	li	a4,1
    8000649c:	00e78c23          	sb	a4,24(a5)
    800064a0:	00e78ca3          	sb	a4,25(a5)
    800064a4:	00e78d23          	sb	a4,26(a5)
    800064a8:	00e78da3          	sb	a4,27(a5)
    800064ac:	00e78e23          	sb	a4,28(a5)
    800064b0:	00e78ea3          	sb	a4,29(a5)
    800064b4:	00e78f23          	sb	a4,30(a5)
    800064b8:	00e78fa3          	sb	a4,31(a5)
}
    800064bc:	60e2                	ld	ra,24(sp)
    800064be:	6442                	ld	s0,16(sp)
    800064c0:	64a2                	ld	s1,8(sp)
    800064c2:	6105                	addi	sp,sp,32
    800064c4:	8082                	ret
    panic("could not find virtio disk");
    800064c6:	00002517          	auipc	a0,0x2
    800064ca:	4ea50513          	addi	a0,a0,1258 # 800089b0 <syscalls+0x360>
    800064ce:	ffffa097          	auipc	ra,0xffffa
    800064d2:	05c080e7          	jalr	92(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    800064d6:	00002517          	auipc	a0,0x2
    800064da:	4fa50513          	addi	a0,a0,1274 # 800089d0 <syscalls+0x380>
    800064de:	ffffa097          	auipc	ra,0xffffa
    800064e2:	04c080e7          	jalr	76(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    800064e6:	00002517          	auipc	a0,0x2
    800064ea:	50a50513          	addi	a0,a0,1290 # 800089f0 <syscalls+0x3a0>
    800064ee:	ffffa097          	auipc	ra,0xffffa
    800064f2:	03c080e7          	jalr	60(ra) # 8000052a <panic>

00000000800064f6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800064f6:	7119                	addi	sp,sp,-128
    800064f8:	fc86                	sd	ra,120(sp)
    800064fa:	f8a2                	sd	s0,112(sp)
    800064fc:	f4a6                	sd	s1,104(sp)
    800064fe:	f0ca                	sd	s2,96(sp)
    80006500:	ecce                	sd	s3,88(sp)
    80006502:	e8d2                	sd	s4,80(sp)
    80006504:	e4d6                	sd	s5,72(sp)
    80006506:	e0da                	sd	s6,64(sp)
    80006508:	fc5e                	sd	s7,56(sp)
    8000650a:	f862                	sd	s8,48(sp)
    8000650c:	f466                	sd	s9,40(sp)
    8000650e:	f06a                	sd	s10,32(sp)
    80006510:	ec6e                	sd	s11,24(sp)
    80006512:	0100                	addi	s0,sp,128
    80006514:	8aaa                	mv	s5,a0
    80006516:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006518:	00c52c83          	lw	s9,12(a0)
    8000651c:	001c9c9b          	slliw	s9,s9,0x1
    80006520:	1c82                	slli	s9,s9,0x20
    80006522:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006526:	0001f517          	auipc	a0,0x1f
    8000652a:	c0250513          	addi	a0,a0,-1022 # 80025128 <disk+0x2128>
    8000652e:	ffffa097          	auipc	ra,0xffffa
    80006532:	694080e7          	jalr	1684(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006536:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006538:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000653a:	0001dc17          	auipc	s8,0x1d
    8000653e:	ac6c0c13          	addi	s8,s8,-1338 # 80023000 <disk>
    80006542:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006544:	4b0d                	li	s6,3
    80006546:	a0ad                	j	800065b0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006548:	00fc0733          	add	a4,s8,a5
    8000654c:	975e                	add	a4,a4,s7
    8000654e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006552:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006554:	0207c563          	bltz	a5,8000657e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006558:	2905                	addiw	s2,s2,1
    8000655a:	0611                	addi	a2,a2,4
    8000655c:	19690d63          	beq	s2,s6,800066f6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006560:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006562:	0001f717          	auipc	a4,0x1f
    80006566:	ab670713          	addi	a4,a4,-1354 # 80025018 <disk+0x2018>
    8000656a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000656c:	00074683          	lbu	a3,0(a4)
    80006570:	fee1                	bnez	a3,80006548 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006572:	2785                	addiw	a5,a5,1
    80006574:	0705                	addi	a4,a4,1
    80006576:	fe979be3          	bne	a5,s1,8000656c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000657a:	57fd                	li	a5,-1
    8000657c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000657e:	01205d63          	blez	s2,80006598 <virtio_disk_rw+0xa2>
    80006582:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006584:	000a2503          	lw	a0,0(s4)
    80006588:	00000097          	auipc	ra,0x0
    8000658c:	d8e080e7          	jalr	-626(ra) # 80006316 <free_desc>
      for(int j = 0; j < i; j++)
    80006590:	2d85                	addiw	s11,s11,1
    80006592:	0a11                	addi	s4,s4,4
    80006594:	ffb918e3          	bne	s2,s11,80006584 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006598:	0001f597          	auipc	a1,0x1f
    8000659c:	b9058593          	addi	a1,a1,-1136 # 80025128 <disk+0x2128>
    800065a0:	0001f517          	auipc	a0,0x1f
    800065a4:	a7850513          	addi	a0,a0,-1416 # 80025018 <disk+0x2018>
    800065a8:	ffffc097          	auipc	ra,0xffffc
    800065ac:	d3a080e7          	jalr	-710(ra) # 800022e2 <sleep>
  for(int i = 0; i < 3; i++){
    800065b0:	f8040a13          	addi	s4,s0,-128
{
    800065b4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800065b6:	894e                	mv	s2,s3
    800065b8:	b765                	j	80006560 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800065ba:	0001f697          	auipc	a3,0x1f
    800065be:	a466b683          	ld	a3,-1466(a3) # 80025000 <disk+0x2000>
    800065c2:	96ba                	add	a3,a3,a4
    800065c4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065c8:	0001d817          	auipc	a6,0x1d
    800065cc:	a3880813          	addi	a6,a6,-1480 # 80023000 <disk>
    800065d0:	0001f697          	auipc	a3,0x1f
    800065d4:	a3068693          	addi	a3,a3,-1488 # 80025000 <disk+0x2000>
    800065d8:	6290                	ld	a2,0(a3)
    800065da:	963a                	add	a2,a2,a4
    800065dc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800065e0:	0015e593          	ori	a1,a1,1
    800065e4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800065e8:	f8842603          	lw	a2,-120(s0)
    800065ec:	628c                	ld	a1,0(a3)
    800065ee:	972e                	add	a4,a4,a1
    800065f0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800065f4:	20050593          	addi	a1,a0,512
    800065f8:	0592                	slli	a1,a1,0x4
    800065fa:	95c2                	add	a1,a1,a6
    800065fc:	577d                	li	a4,-1
    800065fe:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006602:	00461713          	slli	a4,a2,0x4
    80006606:	6290                	ld	a2,0(a3)
    80006608:	963a                	add	a2,a2,a4
    8000660a:	03078793          	addi	a5,a5,48
    8000660e:	97c2                	add	a5,a5,a6
    80006610:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006612:	629c                	ld	a5,0(a3)
    80006614:	97ba                	add	a5,a5,a4
    80006616:	4605                	li	a2,1
    80006618:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000661a:	629c                	ld	a5,0(a3)
    8000661c:	97ba                	add	a5,a5,a4
    8000661e:	4809                	li	a6,2
    80006620:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006624:	629c                	ld	a5,0(a3)
    80006626:	973e                	add	a4,a4,a5
    80006628:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000662c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006630:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006634:	6698                	ld	a4,8(a3)
    80006636:	00275783          	lhu	a5,2(a4)
    8000663a:	8b9d                	andi	a5,a5,7
    8000663c:	0786                	slli	a5,a5,0x1
    8000663e:	97ba                	add	a5,a5,a4
    80006640:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006644:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006648:	6698                	ld	a4,8(a3)
    8000664a:	00275783          	lhu	a5,2(a4)
    8000664e:	2785                	addiw	a5,a5,1
    80006650:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006654:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006658:	100017b7          	lui	a5,0x10001
    8000665c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006660:	004aa783          	lw	a5,4(s5)
    80006664:	02c79163          	bne	a5,a2,80006686 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006668:	0001f917          	auipc	s2,0x1f
    8000666c:	ac090913          	addi	s2,s2,-1344 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006670:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006672:	85ca                	mv	a1,s2
    80006674:	8556                	mv	a0,s5
    80006676:	ffffc097          	auipc	ra,0xffffc
    8000667a:	c6c080e7          	jalr	-916(ra) # 800022e2 <sleep>
  while(b->disk == 1) {
    8000667e:	004aa783          	lw	a5,4(s5)
    80006682:	fe9788e3          	beq	a5,s1,80006672 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006686:	f8042903          	lw	s2,-128(s0)
    8000668a:	20090793          	addi	a5,s2,512
    8000668e:	00479713          	slli	a4,a5,0x4
    80006692:	0001d797          	auipc	a5,0x1d
    80006696:	96e78793          	addi	a5,a5,-1682 # 80023000 <disk>
    8000669a:	97ba                	add	a5,a5,a4
    8000669c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800066a0:	0001f997          	auipc	s3,0x1f
    800066a4:	96098993          	addi	s3,s3,-1696 # 80025000 <disk+0x2000>
    800066a8:	00491713          	slli	a4,s2,0x4
    800066ac:	0009b783          	ld	a5,0(s3)
    800066b0:	97ba                	add	a5,a5,a4
    800066b2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066b6:	854a                	mv	a0,s2
    800066b8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066bc:	00000097          	auipc	ra,0x0
    800066c0:	c5a080e7          	jalr	-934(ra) # 80006316 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066c4:	8885                	andi	s1,s1,1
    800066c6:	f0ed                	bnez	s1,800066a8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066c8:	0001f517          	auipc	a0,0x1f
    800066cc:	a6050513          	addi	a0,a0,-1440 # 80025128 <disk+0x2128>
    800066d0:	ffffa097          	auipc	ra,0xffffa
    800066d4:	5a6080e7          	jalr	1446(ra) # 80000c76 <release>
}
    800066d8:	70e6                	ld	ra,120(sp)
    800066da:	7446                	ld	s0,112(sp)
    800066dc:	74a6                	ld	s1,104(sp)
    800066de:	7906                	ld	s2,96(sp)
    800066e0:	69e6                	ld	s3,88(sp)
    800066e2:	6a46                	ld	s4,80(sp)
    800066e4:	6aa6                	ld	s5,72(sp)
    800066e6:	6b06                	ld	s6,64(sp)
    800066e8:	7be2                	ld	s7,56(sp)
    800066ea:	7c42                	ld	s8,48(sp)
    800066ec:	7ca2                	ld	s9,40(sp)
    800066ee:	7d02                	ld	s10,32(sp)
    800066f0:	6de2                	ld	s11,24(sp)
    800066f2:	6109                	addi	sp,sp,128
    800066f4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066f6:	f8042503          	lw	a0,-128(s0)
    800066fa:	20050793          	addi	a5,a0,512
    800066fe:	0792                	slli	a5,a5,0x4
  if(write)
    80006700:	0001d817          	auipc	a6,0x1d
    80006704:	90080813          	addi	a6,a6,-1792 # 80023000 <disk>
    80006708:	00f80733          	add	a4,a6,a5
    8000670c:	01a036b3          	snez	a3,s10
    80006710:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006714:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006718:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000671c:	7679                	lui	a2,0xffffe
    8000671e:	963e                	add	a2,a2,a5
    80006720:	0001f697          	auipc	a3,0x1f
    80006724:	8e068693          	addi	a3,a3,-1824 # 80025000 <disk+0x2000>
    80006728:	6298                	ld	a4,0(a3)
    8000672a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000672c:	0a878593          	addi	a1,a5,168
    80006730:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006732:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006734:	6298                	ld	a4,0(a3)
    80006736:	9732                	add	a4,a4,a2
    80006738:	45c1                	li	a1,16
    8000673a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000673c:	6298                	ld	a4,0(a3)
    8000673e:	9732                	add	a4,a4,a2
    80006740:	4585                	li	a1,1
    80006742:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006746:	f8442703          	lw	a4,-124(s0)
    8000674a:	628c                	ld	a1,0(a3)
    8000674c:	962e                	add	a2,a2,a1
    8000674e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006752:	0712                	slli	a4,a4,0x4
    80006754:	6290                	ld	a2,0(a3)
    80006756:	963a                	add	a2,a2,a4
    80006758:	058a8593          	addi	a1,s5,88
    8000675c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000675e:	6294                	ld	a3,0(a3)
    80006760:	96ba                	add	a3,a3,a4
    80006762:	40000613          	li	a2,1024
    80006766:	c690                	sw	a2,8(a3)
  if(write)
    80006768:	e40d19e3          	bnez	s10,800065ba <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000676c:	0001f697          	auipc	a3,0x1f
    80006770:	8946b683          	ld	a3,-1900(a3) # 80025000 <disk+0x2000>
    80006774:	96ba                	add	a3,a3,a4
    80006776:	4609                	li	a2,2
    80006778:	00c69623          	sh	a2,12(a3)
    8000677c:	b5b1                	j	800065c8 <virtio_disk_rw+0xd2>

000000008000677e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000677e:	1101                	addi	sp,sp,-32
    80006780:	ec06                	sd	ra,24(sp)
    80006782:	e822                	sd	s0,16(sp)
    80006784:	e426                	sd	s1,8(sp)
    80006786:	e04a                	sd	s2,0(sp)
    80006788:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000678a:	0001f517          	auipc	a0,0x1f
    8000678e:	99e50513          	addi	a0,a0,-1634 # 80025128 <disk+0x2128>
    80006792:	ffffa097          	auipc	ra,0xffffa
    80006796:	430080e7          	jalr	1072(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000679a:	10001737          	lui	a4,0x10001
    8000679e:	533c                	lw	a5,96(a4)
    800067a0:	8b8d                	andi	a5,a5,3
    800067a2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800067a4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800067a8:	0001f797          	auipc	a5,0x1f
    800067ac:	85878793          	addi	a5,a5,-1960 # 80025000 <disk+0x2000>
    800067b0:	6b94                	ld	a3,16(a5)
    800067b2:	0207d703          	lhu	a4,32(a5)
    800067b6:	0026d783          	lhu	a5,2(a3)
    800067ba:	06f70163          	beq	a4,a5,8000681c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067be:	0001d917          	auipc	s2,0x1d
    800067c2:	84290913          	addi	s2,s2,-1982 # 80023000 <disk>
    800067c6:	0001f497          	auipc	s1,0x1f
    800067ca:	83a48493          	addi	s1,s1,-1990 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800067ce:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067d2:	6898                	ld	a4,16(s1)
    800067d4:	0204d783          	lhu	a5,32(s1)
    800067d8:	8b9d                	andi	a5,a5,7
    800067da:	078e                	slli	a5,a5,0x3
    800067dc:	97ba                	add	a5,a5,a4
    800067de:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800067e0:	20078713          	addi	a4,a5,512
    800067e4:	0712                	slli	a4,a4,0x4
    800067e6:	974a                	add	a4,a4,s2
    800067e8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800067ec:	e731                	bnez	a4,80006838 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800067ee:	20078793          	addi	a5,a5,512
    800067f2:	0792                	slli	a5,a5,0x4
    800067f4:	97ca                	add	a5,a5,s2
    800067f6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800067f8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800067fc:	ffffc097          	auipc	ra,0xffffc
    80006800:	c72080e7          	jalr	-910(ra) # 8000246e <wakeup>

    disk.used_idx += 1;
    80006804:	0204d783          	lhu	a5,32(s1)
    80006808:	2785                	addiw	a5,a5,1
    8000680a:	17c2                	slli	a5,a5,0x30
    8000680c:	93c1                	srli	a5,a5,0x30
    8000680e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006812:	6898                	ld	a4,16(s1)
    80006814:	00275703          	lhu	a4,2(a4)
    80006818:	faf71be3          	bne	a4,a5,800067ce <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000681c:	0001f517          	auipc	a0,0x1f
    80006820:	90c50513          	addi	a0,a0,-1780 # 80025128 <disk+0x2128>
    80006824:	ffffa097          	auipc	ra,0xffffa
    80006828:	452080e7          	jalr	1106(ra) # 80000c76 <release>
}
    8000682c:	60e2                	ld	ra,24(sp)
    8000682e:	6442                	ld	s0,16(sp)
    80006830:	64a2                	ld	s1,8(sp)
    80006832:	6902                	ld	s2,0(sp)
    80006834:	6105                	addi	sp,sp,32
    80006836:	8082                	ret
      panic("virtio_disk_intr status");
    80006838:	00002517          	auipc	a0,0x2
    8000683c:	1d850513          	addi	a0,a0,472 # 80008a10 <syscalls+0x3c0>
    80006840:	ffffa097          	auipc	ra,0xffffa
    80006844:	cea080e7          	jalr	-790(ra) # 8000052a <panic>
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
