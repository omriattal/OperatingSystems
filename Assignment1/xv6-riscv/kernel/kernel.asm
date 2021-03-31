
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
    80000068:	3fc78793          	addi	a5,a5,1020 # 80006460 <timervec>
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
    80000122:	6bc080e7          	jalr	1724(ra) # 800027da <either_copyin>
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
    800001c6:	214080e7          	jalr	532(ra) # 800023d6 <sleep>
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
    80000202:	586080e7          	jalr	1414(ra) # 80002784 <either_copyout>
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
    800002e2:	552080e7          	jalr	1362(ra) # 80002830 <procdump>
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
    80000436:	130080e7          	jalr	304(ra) # 80002562 <wakeup>
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
    80000882:	ce4080e7          	jalr	-796(ra) # 80002562 <wakeup>
    
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
    8000090e:	acc080e7          	jalr	-1332(ra) # 800023d6 <sleep>
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
    80000eb6:	e66080e7          	jalr	-410(ra) # 80002d18 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	5e6080e7          	jalr	1510(ra) # 800064a0 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	3e4080e7          	jalr	996(ra) # 800022a6 <scheduler>
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
    80000f2e:	dc6080e7          	jalr	-570(ra) # 80002cf0 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	de6080e7          	jalr	-538(ra) # 80002d18 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	550080e7          	jalr	1360(ra) # 8000648a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	55e080e7          	jalr	1374(ra) # 800064a0 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	724080e7          	jalr	1828(ra) # 8000366e <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	db6080e7          	jalr	-586(ra) # 80003d08 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	d64080e7          	jalr	-668(ra) # 80004cbe <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	660080e7          	jalr	1632(ra) # 800065c2 <virtio_disk_init>
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
    8000182e:	21e48493          	addi	s1,s1,542 # 80008a48 <TURN>
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
    80001a16:	02e7a783          	lw	a5,46(a5) # 80008a40 <first.1>
    80001a1a:	eb89                	bnez	a5,80001a2c <forkret+0x32>
		// be run from main().
		first = 0;
		fsinit(ROOTDEV);
	}

	usertrapret();
    80001a1c:	00001097          	auipc	ra,0x1
    80001a20:	314080e7          	jalr	788(ra) # 80002d30 <usertrapret>
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
    80001a3a:	252080e7          	jalr	594(ra) # 80003c88 <fsinit>
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
    80001ce0:	d7458593          	addi	a1,a1,-652 # 80008a50 <initcode>
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
    80001d1e:	99c080e7          	jalr	-1636(ra) # 800046b6 <namei>
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
    80001e66:	eee080e7          	jalr	-274(ra) # 80004d50 <filedup>
    80001e6a:	00a93023          	sd	a0,0(s2)
    80001e6e:	b7e5                	j	80001e56 <fork+0xa4>
	np->cwd = idup(p->cwd);
    80001e70:	178ab503          	ld	a0,376(s5)
    80001e74:	00002097          	auipc	ra,0x2
    80001e78:	04e080e7          	jalr	78(ra) # 80003ec2 <idup>
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
    80001f8c:	cfe080e7          	jalr	-770(ra) # 80002c86 <swtch>
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

0000000080001faa <sched_fcfs>:
{
    80001faa:	715d                	addi	sp,sp,-80
    80001fac:	e486                	sd	ra,72(sp)
    80001fae:	e0a2                	sd	s0,64(sp)
    80001fb0:	fc26                	sd	s1,56(sp)
    80001fb2:	f84a                	sd	s2,48(sp)
    80001fb4:	f44e                	sd	s3,40(sp)
    80001fb6:	f052                	sd	s4,32(sp)
    80001fb8:	ec56                	sd	s5,24(sp)
    80001fba:	e85a                	sd	s6,16(sp)
    80001fbc:	e45e                	sd	s7,8(sp)
    80001fbe:	0880                	addi	s0,sp,80
    80001fc0:	8b92                	mv	s7,tp
	int id = r_tp();
    80001fc2:	2b81                	sext.w	s7,s7
	c->proc = 0;
    80001fc4:	007b9713          	slli	a4,s7,0x7
    80001fc8:	0000f797          	auipc	a5,0xf
    80001fcc:	2d878793          	addi	a5,a5,728 # 800112a0 <TURNLOCK>
    80001fd0:	97ba                	add	a5,a5,a4
    80001fd2:	0407b423          	sd	zero,72(a5)
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80001fd6:	4901                	li	s2,0
	int proc_to_run_index = 0;
    80001fd8:	4b01                	li	s6,0
	uint first_turn = 4294967295;
    80001fda:	5afd                	li	s5,-1
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80001fdc:	0000f497          	auipc	s1,0xf
    80001fe0:	70c48493          	addi	s1,s1,1804 # 800116e8 <proc>
		if (p->state == RUNNABLE && p->turn < first_turn)
    80001fe4:	4a0d                	li	s4,3
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80001fe6:	00016997          	auipc	s3,0x16
    80001fea:	b0298993          	addi	s3,s3,-1278 # 80017ae8 <tickslock>
    80001fee:	a819                	j	80002004 <sched_fcfs+0x5a>
		release(&p->lock);
    80001ff0:	8526                	mv	a0,s1
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	c84080e7          	jalr	-892(ra) # 80000c76 <release>
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    80001ffa:	19048493          	addi	s1,s1,400
    80001ffe:	2905                	addiw	s2,s2,1
    80002000:	03348063          	beq	s1,s3,80002020 <sched_fcfs+0x76>
		acquire(&p->lock);
    80002004:	8526                	mv	a0,s1
    80002006:	fffff097          	auipc	ra,0xfffff
    8000200a:	bbc080e7          	jalr	-1092(ra) # 80000bc2 <acquire>
		if (p->state == RUNNABLE && p->turn < first_turn)
    8000200e:	4c9c                	lw	a5,24(s1)
    80002010:	ff4790e3          	bne	a5,s4,80001ff0 <sched_fcfs+0x46>
    80002014:	48bc                	lw	a5,80(s1)
    80002016:	fd57fde3          	bgeu	a5,s5,80001ff0 <sched_fcfs+0x46>
    8000201a:	8b4a                	mv	s6,s2
			first_turn = p->turn;
    8000201c:	8abe                	mv	s5,a5
    8000201e:	bfc9                	j	80001ff0 <sched_fcfs+0x46>
	first = &proc[proc_to_run_index];
    80002020:	19000793          	li	a5,400
    80002024:	02fb0933          	mul	s2,s6,a5
    80002028:	0000f497          	auipc	s1,0xf
    8000202c:	6c048493          	addi	s1,s1,1728 # 800116e8 <proc>
    80002030:	94ca                	add	s1,s1,s2
	acquire(&first->lock);
    80002032:	8526                	mv	a0,s1
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	b8e080e7          	jalr	-1138(ra) # 80000bc2 <acquire>
	if (first->state == RUNNABLE)
    8000203c:	4c98                	lw	a4,24(s1)
    8000203e:	478d                	li	a5,3
    80002040:	02f70263          	beq	a4,a5,80002064 <sched_fcfs+0xba>
	release(&first->lock);
    80002044:	8526                	mv	a0,s1
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	c30080e7          	jalr	-976(ra) # 80000c76 <release>
}
    8000204e:	60a6                	ld	ra,72(sp)
    80002050:	6406                	ld	s0,64(sp)
    80002052:	74e2                	ld	s1,56(sp)
    80002054:	7942                	ld	s2,48(sp)
    80002056:	79a2                	ld	s3,40(sp)
    80002058:	7a02                	ld	s4,32(sp)
    8000205a:	6ae2                	ld	s5,24(sp)
    8000205c:	6b42                	ld	s6,16(sp)
    8000205e:	6ba2                	ld	s7,8(sp)
    80002060:	6161                	addi	sp,sp,80
    80002062:	8082                	ret
		first->state = RUNNING;
    80002064:	0000f597          	auipc	a1,0xf
    80002068:	68458593          	addi	a1,a1,1668 # 800116e8 <proc>
    8000206c:	4711                	li	a4,4
    8000206e:	cc98                	sw	a4,24(s1)
		c->proc = first;
    80002070:	0b9e                	slli	s7,s7,0x7
    80002072:	0000f997          	auipc	s3,0xf
    80002076:	22e98993          	addi	s3,s3,558 # 800112a0 <TURNLOCK>
    8000207a:	99de                	add	s3,s3,s7
    8000207c:	0499b423          	sd	s1,72(s3)
		swtch(&c->context,&first->context);
    80002080:	08890913          	addi	s2,s2,136
    80002084:	95ca                	add	a1,a1,s2
    80002086:	0000f517          	auipc	a0,0xf
    8000208a:	26a50513          	addi	a0,a0,618 # 800112f0 <cpus+0x8>
    8000208e:	955e                	add	a0,a0,s7
    80002090:	00001097          	auipc	ra,0x1
    80002094:	bf6080e7          	jalr	-1034(ra) # 80002c86 <swtch>
		c->proc = 0;
    80002098:	0409b423          	sd	zero,72(s3)
    8000209c:	b765                	j	80002044 <sched_fcfs+0x9a>

000000008000209e <sched_srt>:
{
    8000209e:	715d                	addi	sp,sp,-80
    800020a0:	e486                	sd	ra,72(sp)
    800020a2:	e0a2                	sd	s0,64(sp)
    800020a4:	fc26                	sd	s1,56(sp)
    800020a6:	f84a                	sd	s2,48(sp)
    800020a8:	f44e                	sd	s3,40(sp)
    800020aa:	f052                	sd	s4,32(sp)
    800020ac:	ec56                	sd	s5,24(sp)
    800020ae:	e85a                	sd	s6,16(sp)
    800020b0:	e45e                	sd	s7,8(sp)
    800020b2:	0880                	addi	s0,sp,80
    800020b4:	8b92                	mv	s7,tp
	int id = r_tp();
    800020b6:	2b81                	sext.w	s7,s7
	c->proc = 0;
    800020b8:	007b9713          	slli	a4,s7,0x7
    800020bc:	0000f797          	auipc	a5,0xf
    800020c0:	1e478793          	addi	a5,a5,484 # 800112a0 <TURNLOCK>
    800020c4:	97ba                	add	a5,a5,a4
    800020c6:	0407b423          	sd	zero,72(a5)
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    800020ca:	4901                	li	s2,0
	int proc_to_run_index = 0;
    800020cc:	4b01                	li	s6,0
	uint least_average_bursttime = 4294967295;
    800020ce:	5afd                	li	s5,-1
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    800020d0:	0000f497          	auipc	s1,0xf
    800020d4:	61848493          	addi	s1,s1,1560 # 800116e8 <proc>
		if (p->state == RUNNABLE && p->performance.average_bursttime < least_average_bursttime)
    800020d8:	4a0d                	li	s4,3
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    800020da:	00016997          	auipc	s3,0x16
    800020de:	a0e98993          	addi	s3,s3,-1522 # 80017ae8 <tickslock>
    800020e2:	a819                	j	800020f8 <sched_srt+0x5a>
		release(&p->lock);
    800020e4:	8526                	mv	a0,s1
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	b90080e7          	jalr	-1136(ra) # 80000c76 <release>
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    800020ee:	19048493          	addi	s1,s1,400
    800020f2:	2905                	addiw	s2,s2,1
    800020f4:	03348063          	beq	s1,s3,80002114 <sched_srt+0x76>
		acquire(&p->lock);
    800020f8:	8526                	mv	a0,s1
    800020fa:	fffff097          	auipc	ra,0xfffff
    800020fe:	ac8080e7          	jalr	-1336(ra) # 80000bc2 <acquire>
		if (p->state == RUNNABLE && p->performance.average_bursttime < least_average_bursttime)
    80002102:	4c9c                	lw	a5,24(s1)
    80002104:	ff4790e3          	bne	a5,s4,800020e4 <sched_srt+0x46>
    80002108:	44fc                	lw	a5,76(s1)
    8000210a:	fd57fde3          	bgeu	a5,s5,800020e4 <sched_srt+0x46>
    8000210e:	8b4a                	mv	s6,s2
			least_average_bursttime = p->performance.average_bursttime;
    80002110:	8abe                	mv	s5,a5
    80002112:	bfc9                	j	800020e4 <sched_srt+0x46>
	first = &proc[proc_to_run_index];
    80002114:	19000793          	li	a5,400
    80002118:	02fb0933          	mul	s2,s6,a5
    8000211c:	0000f497          	auipc	s1,0xf
    80002120:	5cc48493          	addi	s1,s1,1484 # 800116e8 <proc>
    80002124:	94ca                	add	s1,s1,s2
	acquire(&first->lock);
    80002126:	8526                	mv	a0,s1
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	a9a080e7          	jalr	-1382(ra) # 80000bc2 <acquire>
	if (first->state == RUNNABLE)
    80002130:	4c98                	lw	a4,24(s1)
    80002132:	478d                	li	a5,3
    80002134:	02f70263          	beq	a4,a5,80002158 <sched_srt+0xba>
	release(&first->lock);
    80002138:	8526                	mv	a0,s1
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	b3c080e7          	jalr	-1220(ra) # 80000c76 <release>
}
    80002142:	60a6                	ld	ra,72(sp)
    80002144:	6406                	ld	s0,64(sp)
    80002146:	74e2                	ld	s1,56(sp)
    80002148:	7942                	ld	s2,48(sp)
    8000214a:	79a2                	ld	s3,40(sp)
    8000214c:	7a02                	ld	s4,32(sp)
    8000214e:	6ae2                	ld	s5,24(sp)
    80002150:	6b42                	ld	s6,16(sp)
    80002152:	6ba2                	ld	s7,8(sp)
    80002154:	6161                	addi	sp,sp,80
    80002156:	8082                	ret
		first->state = RUNNING;
    80002158:	0000f597          	auipc	a1,0xf
    8000215c:	59058593          	addi	a1,a1,1424 # 800116e8 <proc>
    80002160:	4711                	li	a4,4
    80002162:	cc98                	sw	a4,24(s1)
		c->proc = first;
    80002164:	0b9e                	slli	s7,s7,0x7
    80002166:	0000f997          	auipc	s3,0xf
    8000216a:	13a98993          	addi	s3,s3,314 # 800112a0 <TURNLOCK>
    8000216e:	99de                	add	s3,s3,s7
    80002170:	0499b423          	sd	s1,72(s3)
		swtch(&c->context,&first->context);
    80002174:	08890913          	addi	s2,s2,136
    80002178:	95ca                	add	a1,a1,s2
    8000217a:	0000f517          	auipc	a0,0xf
    8000217e:	17650513          	addi	a0,a0,374 # 800112f0 <cpus+0x8>
    80002182:	955e                	add	a0,a0,s7
    80002184:	00001097          	auipc	ra,0x1
    80002188:	b02080e7          	jalr	-1278(ra) # 80002c86 <swtch>
		c->proc = 0;
    8000218c:	0409b423          	sd	zero,72(s3)
    80002190:	b765                	j	80002138 <sched_srt+0x9a>

0000000080002192 <sched_cfsd>:
void sched_cfsd() {
    80002192:	715d                	addi	sp,sp,-80
    80002194:	e486                	sd	ra,72(sp)
    80002196:	e0a2                	sd	s0,64(sp)
    80002198:	fc26                	sd	s1,56(sp)
    8000219a:	f84a                	sd	s2,48(sp)
    8000219c:	f44e                	sd	s3,40(sp)
    8000219e:	f052                	sd	s4,32(sp)
    800021a0:	ec56                	sd	s5,24(sp)
    800021a2:	e85a                	sd	s6,16(sp)
    800021a4:	e45e                	sd	s7,8(sp)
    800021a6:	e062                	sd	s8,0(sp)
    800021a8:	0880                	addi	s0,sp,80
    800021aa:	8c12                	mv	s8,tp
	int id = r_tp();
    800021ac:	2c01                	sext.w	s8,s8
	c->proc = 0;
    800021ae:	007c1713          	slli	a4,s8,0x7
    800021b2:	0000f797          	auipc	a5,0xf
    800021b6:	0ee78793          	addi	a5,a5,238 # 800112a0 <TURNLOCK>
    800021ba:	97ba                	add	a5,a5,a4
    800021bc:	0407b423          	sd	zero,72(a5)
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    800021c0:	4901                	li	s2,0
	int proc_to_run_index = 0;
    800021c2:	4b81                	li	s7,0
	uint least_runtime_ratio = 4294967295;
    800021c4:	5b7d                	li	s6,-1
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    800021c6:	0000f497          	auipc	s1,0xf
    800021ca:	52248493          	addi	s1,s1,1314 # 800116e8 <proc>
		run_time_ratio = (p->performance.rutime * decay_factors[p->priority]) / (p->performance.rutime + p->performance.stime);
    800021ce:	00007a97          	auipc	s5,0x7
    800021d2:	882a8a93          	addi	s5,s5,-1918 # 80008a50 <initcode>
		if (p->state == RUNNABLE && run_time_ratio < least_runtime_ratio)
    800021d6:	4a0d                	li	s4,3
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    800021d8:	00016997          	auipc	s3,0x16
    800021dc:	91098993          	addi	s3,s3,-1776 # 80017ae8 <tickslock>
    800021e0:	a819                	j	800021f6 <sched_cfsd+0x64>
		release(&p->lock);
    800021e2:	8526                	mv	a0,s1
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	a92080e7          	jalr	-1390(ra) # 80000c76 <release>
	for (p = proc, i = 0; p < &proc[NPROC]; p++, i++)
    800021ec:	19048493          	addi	s1,s1,400
    800021f0:	2905                	addiw	s2,s2,1
    800021f2:	03348a63          	beq	s1,s3,80002226 <sched_cfsd+0x94>
		acquire(&p->lock);
    800021f6:	8526                	mv	a0,s1
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	9ca080e7          	jalr	-1590(ra) # 80000bc2 <acquire>
		run_time_ratio = (p->performance.rutime * decay_factors[p->priority]) / (p->performance.rutime + p->performance.stime);
    80002200:	44b8                	lw	a4,72(s1)
    80002202:	4cbc                	lw	a5,88(s1)
    80002204:	078a                	slli	a5,a5,0x2
    80002206:	97d6                	add	a5,a5,s5
    80002208:	5f9c                	lw	a5,56(a5)
    8000220a:	40b0                	lw	a2,64(s1)
		if (p->state == RUNNABLE && run_time_ratio < least_runtime_ratio)
    8000220c:	4c94                	lw	a3,24(s1)
    8000220e:	fd469ae3          	bne	a3,s4,800021e2 <sched_cfsd+0x50>
		run_time_ratio = (p->performance.rutime * decay_factors[p->priority]) / (p->performance.rutime + p->performance.stime);
    80002212:	02f707bb          	mulw	a5,a4,a5
    80002216:	9f31                	addw	a4,a4,a2
    80002218:	02e7c7bb          	divw	a5,a5,a4
		if (p->state == RUNNABLE && run_time_ratio < least_runtime_ratio)
    8000221c:	fd67f3e3          	bgeu	a5,s6,800021e2 <sched_cfsd+0x50>
    80002220:	8bca                	mv	s7,s2
			least_runtime_ratio = run_time_ratio;   
    80002222:	8b3e                	mv	s6,a5
    80002224:	bf7d                	j	800021e2 <sched_cfsd+0x50>
	first = &proc[proc_to_run_index];
    80002226:	19000793          	li	a5,400
    8000222a:	02fb8933          	mul	s2,s7,a5
    8000222e:	0000f497          	auipc	s1,0xf
    80002232:	4ba48493          	addi	s1,s1,1210 # 800116e8 <proc>
    80002236:	94ca                	add	s1,s1,s2
	acquire(&first->lock);
    80002238:	8526                	mv	a0,s1
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	988080e7          	jalr	-1656(ra) # 80000bc2 <acquire>
	if (first->state == RUNNABLE)
    80002242:	4c98                	lw	a4,24(s1)
    80002244:	478d                	li	a5,3
    80002246:	02f70363          	beq	a4,a5,8000226c <sched_cfsd+0xda>
	release(&first->lock);
    8000224a:	8526                	mv	a0,s1
    8000224c:	fffff097          	auipc	ra,0xfffff
    80002250:	a2a080e7          	jalr	-1494(ra) # 80000c76 <release>
}
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
		first->state = RUNNING;
    8000226c:	0000f597          	auipc	a1,0xf
    80002270:	47c58593          	addi	a1,a1,1148 # 800116e8 <proc>
    80002274:	4711                	li	a4,4
    80002276:	cc98                	sw	a4,24(s1)
		c->proc = first;
    80002278:	0c1e                	slli	s8,s8,0x7
    8000227a:	0000f997          	auipc	s3,0xf
    8000227e:	02698993          	addi	s3,s3,38 # 800112a0 <TURNLOCK>
    80002282:	99e2                	add	s3,s3,s8
    80002284:	0499b423          	sd	s1,72(s3)
		swtch(&c->context,&first->context);
    80002288:	08890913          	addi	s2,s2,136
    8000228c:	95ca                	add	a1,a1,s2
    8000228e:	0000f517          	auipc	a0,0xf
    80002292:	06250513          	addi	a0,a0,98 # 800112f0 <cpus+0x8>
    80002296:	9562                	add	a0,a0,s8
    80002298:	00001097          	auipc	ra,0x1
    8000229c:	9ee080e7          	jalr	-1554(ra) # 80002c86 <swtch>
		c->proc = 0;
    800022a0:	0409b423          	sd	zero,72(s3)
    800022a4:	b75d                	j	8000224a <sched_cfsd+0xb8>

00000000800022a6 <scheduler>:
{
    800022a6:	1141                	addi	sp,sp,-16
    800022a8:	e406                	sd	ra,8(sp)
    800022aa:	e022                	sd	s0,0(sp)
    800022ac:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022ae:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022b2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022b6:	10079073          	csrw	sstatus,a5
		sched_default();
    800022ba:	00000097          	auipc	ra,0x0
    800022be:	c48080e7          	jalr	-952(ra) # 80001f02 <sched_default>
	for (;;)
    800022c2:	b7f5                	j	800022ae <scheduler+0x8>

00000000800022c4 <sched>:
{
    800022c4:	7179                	addi	sp,sp,-48
    800022c6:	f406                	sd	ra,40(sp)
    800022c8:	f022                	sd	s0,32(sp)
    800022ca:	ec26                	sd	s1,24(sp)
    800022cc:	e84a                	sd	s2,16(sp)
    800022ce:	e44e                	sd	s3,8(sp)
    800022d0:	1800                	addi	s0,sp,48
	struct proc *p = myproc();
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	6f0080e7          	jalr	1776(ra) # 800019c2 <myproc>
    800022da:	84aa                	mv	s1,a0
	if (!holding(&p->lock))
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	86c080e7          	jalr	-1940(ra) # 80000b48 <holding>
    800022e4:	c93d                	beqz	a0,8000235a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022e6:	8792                	mv	a5,tp
	if (mycpu()->noff != 1)
    800022e8:	2781                	sext.w	a5,a5
    800022ea:	079e                	slli	a5,a5,0x7
    800022ec:	0000f717          	auipc	a4,0xf
    800022f0:	fb470713          	addi	a4,a4,-76 # 800112a0 <TURNLOCK>
    800022f4:	97ba                	add	a5,a5,a4
    800022f6:	0c07a703          	lw	a4,192(a5)
    800022fa:	4785                	li	a5,1
    800022fc:	06f71763          	bne	a4,a5,8000236a <sched+0xa6>
	if (p->state == RUNNING)
    80002300:	4c98                	lw	a4,24(s1)
    80002302:	4791                	li	a5,4
    80002304:	06f70b63          	beq	a4,a5,8000237a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002308:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000230c:	8b89                	andi	a5,a5,2
	if (intr_get())
    8000230e:	efb5                	bnez	a5,8000238a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002310:	8792                	mv	a5,tp
	intena = mycpu()->intena;
    80002312:	0000f917          	auipc	s2,0xf
    80002316:	f8e90913          	addi	s2,s2,-114 # 800112a0 <TURNLOCK>
    8000231a:	2781                	sext.w	a5,a5
    8000231c:	079e                	slli	a5,a5,0x7
    8000231e:	97ca                	add	a5,a5,s2
    80002320:	0c47a983          	lw	s3,196(a5)
    80002324:	8792                	mv	a5,tp
	swtch(&p->context, &mycpu()->context);
    80002326:	2781                	sext.w	a5,a5
    80002328:	079e                	slli	a5,a5,0x7
    8000232a:	0000f597          	auipc	a1,0xf
    8000232e:	fc658593          	addi	a1,a1,-58 # 800112f0 <cpus+0x8>
    80002332:	95be                	add	a1,a1,a5
    80002334:	08848513          	addi	a0,s1,136
    80002338:	00001097          	auipc	ra,0x1
    8000233c:	94e080e7          	jalr	-1714(ra) # 80002c86 <swtch>
    80002340:	8792                	mv	a5,tp
	mycpu()->intena = intena;
    80002342:	2781                	sext.w	a5,a5
    80002344:	079e                	slli	a5,a5,0x7
    80002346:	97ca                	add	a5,a5,s2
    80002348:	0d37a223          	sw	s3,196(a5)
}
    8000234c:	70a2                	ld	ra,40(sp)
    8000234e:	7402                	ld	s0,32(sp)
    80002350:	64e2                	ld	s1,24(sp)
    80002352:	6942                	ld	s2,16(sp)
    80002354:	69a2                	ld	s3,8(sp)
    80002356:	6145                	addi	sp,sp,48
    80002358:	8082                	ret
		panic("sched p->lock");
    8000235a:	00006517          	auipc	a0,0x6
    8000235e:	ea650513          	addi	a0,a0,-346 # 80008200 <digits+0x1c0>
    80002362:	ffffe097          	auipc	ra,0xffffe
    80002366:	1c8080e7          	jalr	456(ra) # 8000052a <panic>
		panic("sched locks");
    8000236a:	00006517          	auipc	a0,0x6
    8000236e:	ea650513          	addi	a0,a0,-346 # 80008210 <digits+0x1d0>
    80002372:	ffffe097          	auipc	ra,0xffffe
    80002376:	1b8080e7          	jalr	440(ra) # 8000052a <panic>
		panic("sched running");
    8000237a:	00006517          	auipc	a0,0x6
    8000237e:	ea650513          	addi	a0,a0,-346 # 80008220 <digits+0x1e0>
    80002382:	ffffe097          	auipc	ra,0xffffe
    80002386:	1a8080e7          	jalr	424(ra) # 8000052a <panic>
		panic("sched interruptible");
    8000238a:	00006517          	auipc	a0,0x6
    8000238e:	ea650513          	addi	a0,a0,-346 # 80008230 <digits+0x1f0>
    80002392:	ffffe097          	auipc	ra,0xffffe
    80002396:	198080e7          	jalr	408(ra) # 8000052a <panic>

000000008000239a <yield>:
{
    8000239a:	1101                	addi	sp,sp,-32
    8000239c:	ec06                	sd	ra,24(sp)
    8000239e:	e822                	sd	s0,16(sp)
    800023a0:	e426                	sd	s1,8(sp)
    800023a2:	1000                	addi	s0,sp,32
	struct proc *p = myproc();
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	61e080e7          	jalr	1566(ra) # 800019c2 <myproc>
    800023ac:	84aa                	mv	s1,a0
	acquire(&p->lock);
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	814080e7          	jalr	-2028(ra) # 80000bc2 <acquire>
	p->state = RUNNABLE;
    800023b6:	478d                	li	a5,3
    800023b8:	cc9c                	sw	a5,24(s1)
	sched();
    800023ba:	00000097          	auipc	ra,0x0
    800023be:	f0a080e7          	jalr	-246(ra) # 800022c4 <sched>
	release(&p->lock);
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	8b2080e7          	jalr	-1870(ra) # 80000c76 <release>
}
    800023cc:	60e2                	ld	ra,24(sp)
    800023ce:	6442                	ld	s0,16(sp)
    800023d0:	64a2                	ld	s1,8(sp)
    800023d2:	6105                	addi	sp,sp,32
    800023d4:	8082                	ret

00000000800023d6 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800023d6:	7179                	addi	sp,sp,-48
    800023d8:	f406                	sd	ra,40(sp)
    800023da:	f022                	sd	s0,32(sp)
    800023dc:	ec26                	sd	s1,24(sp)
    800023de:	e84a                	sd	s2,16(sp)
    800023e0:	e44e                	sd	s3,8(sp)
    800023e2:	1800                	addi	s0,sp,48
    800023e4:	89aa                	mv	s3,a0
    800023e6:	892e                	mv	s2,a1
	struct proc *p = myproc();
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	5da080e7          	jalr	1498(ra) # 800019c2 <myproc>
    800023f0:	84aa                	mv	s1,a0
	// Once we hold p->lock, we can be
	// guaranteed that we won't miss any wakeup
	// (wakeup locks p->lock),
	// so it's okay to release lk.

	acquire(&p->lock); //DOC: sleeplock1
    800023f2:	ffffe097          	auipc	ra,0xffffe
    800023f6:	7d0080e7          	jalr	2000(ra) # 80000bc2 <acquire>
	release(lk);
    800023fa:	854a                	mv	a0,s2
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	87a080e7          	jalr	-1926(ra) # 80000c76 <release>

	// Go to sleep.
	p->chan = chan;
    80002404:	0334b023          	sd	s3,32(s1)
	p->state = SLEEPING;
    80002408:	4789                	li	a5,2
    8000240a:	cc9c                	sw	a5,24(s1)

	sched();
    8000240c:	00000097          	auipc	ra,0x0
    80002410:	eb8080e7          	jalr	-328(ra) # 800022c4 <sched>

	// Tidy up.
	p->chan = 0;
    80002414:	0204b023          	sd	zero,32(s1)

	// Reacquire original lock.
	release(&p->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	85c080e7          	jalr	-1956(ra) # 80000c76 <release>
	acquire(lk);
    80002422:	854a                	mv	a0,s2
    80002424:	ffffe097          	auipc	ra,0xffffe
    80002428:	79e080e7          	jalr	1950(ra) # 80000bc2 <acquire>
}
    8000242c:	70a2                	ld	ra,40(sp)
    8000242e:	7402                	ld	s0,32(sp)
    80002430:	64e2                	ld	s1,24(sp)
    80002432:	6942                	ld	s2,16(sp)
    80002434:	69a2                	ld	s3,8(sp)
    80002436:	6145                	addi	sp,sp,48
    80002438:	8082                	ret

000000008000243a <wait>:
{
    8000243a:	715d                	addi	sp,sp,-80
    8000243c:	e486                	sd	ra,72(sp)
    8000243e:	e0a2                	sd	s0,64(sp)
    80002440:	fc26                	sd	s1,56(sp)
    80002442:	f84a                	sd	s2,48(sp)
    80002444:	f44e                	sd	s3,40(sp)
    80002446:	f052                	sd	s4,32(sp)
    80002448:	ec56                	sd	s5,24(sp)
    8000244a:	e85a                	sd	s6,16(sp)
    8000244c:	e45e                	sd	s7,8(sp)
    8000244e:	e062                	sd	s8,0(sp)
    80002450:	0880                	addi	s0,sp,80
    80002452:	8b2a                	mv	s6,a0
	struct proc *p = myproc();
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	56e080e7          	jalr	1390(ra) # 800019c2 <myproc>
    8000245c:	892a                	mv	s2,a0
	acquire(&wait_lock);
    8000245e:	0000f517          	auipc	a0,0xf
    80002462:	e7250513          	addi	a0,a0,-398 # 800112d0 <wait_lock>
    80002466:	ffffe097          	auipc	ra,0xffffe
    8000246a:	75c080e7          	jalr	1884(ra) # 80000bc2 <acquire>
		havekids = 0;
    8000246e:	4b81                	li	s7,0
				if (np->state == ZOMBIE)
    80002470:	4a15                	li	s4,5
				havekids = 1;
    80002472:	4a85                	li	s5,1
		for (np = proc; np < &proc[NPROC]; np++)
    80002474:	00015997          	auipc	s3,0x15
    80002478:	67498993          	addi	s3,s3,1652 # 80017ae8 <tickslock>
		sleep(p, &wait_lock); //DOC: wait-sleep
    8000247c:	0000fc17          	auipc	s8,0xf
    80002480:	e54c0c13          	addi	s8,s8,-428 # 800112d0 <wait_lock>
		havekids = 0;
    80002484:	875e                	mv	a4,s7
		for (np = proc; np < &proc[NPROC]; np++)
    80002486:	0000f497          	auipc	s1,0xf
    8000248a:	26248493          	addi	s1,s1,610 # 800116e8 <proc>
    8000248e:	a0bd                	j	800024fc <wait+0xc2>
					pid = np->pid;
    80002490:	0304a983          	lw	s3,48(s1)
					if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002494:	000b0e63          	beqz	s6,800024b0 <wait+0x76>
    80002498:	4691                	li	a3,4
    8000249a:	02c48613          	addi	a2,s1,44
    8000249e:	85da                	mv	a1,s6
    800024a0:	07893503          	ld	a0,120(s2)
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	19a080e7          	jalr	410(ra) # 8000163e <copyout>
    800024ac:	02054563          	bltz	a0,800024d6 <wait+0x9c>
					freeproc(np);
    800024b0:	8526                	mv	a0,s1
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	6c2080e7          	jalr	1730(ra) # 80001b74 <freeproc>
					release(&np->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	7ba080e7          	jalr	1978(ra) # 80000c76 <release>
					release(&wait_lock);
    800024c4:	0000f517          	auipc	a0,0xf
    800024c8:	e0c50513          	addi	a0,a0,-500 # 800112d0 <wait_lock>
    800024cc:	ffffe097          	auipc	ra,0xffffe
    800024d0:	7aa080e7          	jalr	1962(ra) # 80000c76 <release>
					return pid;
    800024d4:	a09d                	j	8000253a <wait+0x100>
						release(&np->lock);
    800024d6:	8526                	mv	a0,s1
    800024d8:	ffffe097          	auipc	ra,0xffffe
    800024dc:	79e080e7          	jalr	1950(ra) # 80000c76 <release>
						release(&wait_lock);
    800024e0:	0000f517          	auipc	a0,0xf
    800024e4:	df050513          	addi	a0,a0,-528 # 800112d0 <wait_lock>
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	78e080e7          	jalr	1934(ra) # 80000c76 <release>
						return -1;
    800024f0:	59fd                	li	s3,-1
    800024f2:	a0a1                	j	8000253a <wait+0x100>
		for (np = proc; np < &proc[NPROC]; np++)
    800024f4:	19048493          	addi	s1,s1,400
    800024f8:	03348463          	beq	s1,s3,80002520 <wait+0xe6>
			if (np->parent == p)
    800024fc:	70bc                	ld	a5,96(s1)
    800024fe:	ff279be3          	bne	a5,s2,800024f4 <wait+0xba>
				acquire(&np->lock);
    80002502:	8526                	mv	a0,s1
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	6be080e7          	jalr	1726(ra) # 80000bc2 <acquire>
				if (np->state == ZOMBIE)
    8000250c:	4c9c                	lw	a5,24(s1)
    8000250e:	f94781e3          	beq	a5,s4,80002490 <wait+0x56>
				release(&np->lock);
    80002512:	8526                	mv	a0,s1
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	762080e7          	jalr	1890(ra) # 80000c76 <release>
				havekids = 1;
    8000251c:	8756                	mv	a4,s5
    8000251e:	bfd9                	j	800024f4 <wait+0xba>
		if (!havekids || p->killed)
    80002520:	c701                	beqz	a4,80002528 <wait+0xee>
    80002522:	02892783          	lw	a5,40(s2)
    80002526:	c79d                	beqz	a5,80002554 <wait+0x11a>
			release(&wait_lock);
    80002528:	0000f517          	auipc	a0,0xf
    8000252c:	da850513          	addi	a0,a0,-600 # 800112d0 <wait_lock>
    80002530:	ffffe097          	auipc	ra,0xffffe
    80002534:	746080e7          	jalr	1862(ra) # 80000c76 <release>
			return -1;
    80002538:	59fd                	li	s3,-1
}
    8000253a:	854e                	mv	a0,s3
    8000253c:	60a6                	ld	ra,72(sp)
    8000253e:	6406                	ld	s0,64(sp)
    80002540:	74e2                	ld	s1,56(sp)
    80002542:	7942                	ld	s2,48(sp)
    80002544:	79a2                	ld	s3,40(sp)
    80002546:	7a02                	ld	s4,32(sp)
    80002548:	6ae2                	ld	s5,24(sp)
    8000254a:	6b42                	ld	s6,16(sp)
    8000254c:	6ba2                	ld	s7,8(sp)
    8000254e:	6c02                	ld	s8,0(sp)
    80002550:	6161                	addi	sp,sp,80
    80002552:	8082                	ret
		sleep(p, &wait_lock); //DOC: wait-sleep
    80002554:	85e2                	mv	a1,s8
    80002556:	854a                	mv	a0,s2
    80002558:	00000097          	auipc	ra,0x0
    8000255c:	e7e080e7          	jalr	-386(ra) # 800023d6 <sleep>
		havekids = 0;
    80002560:	b715                	j	80002484 <wait+0x4a>

0000000080002562 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002562:	7139                	addi	sp,sp,-64
    80002564:	fc06                	sd	ra,56(sp)
    80002566:	f822                	sd	s0,48(sp)
    80002568:	f426                	sd	s1,40(sp)
    8000256a:	f04a                	sd	s2,32(sp)
    8000256c:	ec4e                	sd	s3,24(sp)
    8000256e:	e852                	sd	s4,16(sp)
    80002570:	e456                	sd	s5,8(sp)
    80002572:	0080                	addi	s0,sp,64
    80002574:	8a2a                	mv	s4,a0
	struct proc *p;

	for (p = proc; p < &proc[NPROC]; p++)
    80002576:	0000f497          	auipc	s1,0xf
    8000257a:	17248493          	addi	s1,s1,370 # 800116e8 <proc>
	{
		if (p != myproc())
		{
			acquire(&p->lock);
			if (p->state == SLEEPING && p->chan == chan)
    8000257e:	4989                	li	s3,2
			{
				p->state = RUNNABLE;
    80002580:	4a8d                	li	s5,3
	for (p = proc; p < &proc[NPROC]; p++)
    80002582:	00015917          	auipc	s2,0x15
    80002586:	56690913          	addi	s2,s2,1382 # 80017ae8 <tickslock>
    8000258a:	a811                	j	8000259e <wakeup+0x3c>
				p->turn = get_turn(); // ADDED: determin the turn of the process when it wakes up
			}
			release(&p->lock);
    8000258c:	8526                	mv	a0,s1
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	6e8080e7          	jalr	1768(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80002596:	19048493          	addi	s1,s1,400
    8000259a:	03248b63          	beq	s1,s2,800025d0 <wakeup+0x6e>
		if (p != myproc())
    8000259e:	fffff097          	auipc	ra,0xfffff
    800025a2:	424080e7          	jalr	1060(ra) # 800019c2 <myproc>
    800025a6:	fea488e3          	beq	s1,a0,80002596 <wakeup+0x34>
			acquire(&p->lock);
    800025aa:	8526                	mv	a0,s1
    800025ac:	ffffe097          	auipc	ra,0xffffe
    800025b0:	616080e7          	jalr	1558(ra) # 80000bc2 <acquire>
			if (p->state == SLEEPING && p->chan == chan)
    800025b4:	4c9c                	lw	a5,24(s1)
    800025b6:	fd379be3          	bne	a5,s3,8000258c <wakeup+0x2a>
    800025ba:	709c                	ld	a5,32(s1)
    800025bc:	fd4798e3          	bne	a5,s4,8000258c <wakeup+0x2a>
				p->state = RUNNABLE;
    800025c0:	0154ac23          	sw	s5,24(s1)
				p->turn = get_turn(); // ADDED: determin the turn of the process when it wakes up
    800025c4:	fffff097          	auipc	ra,0xfffff
    800025c8:	248080e7          	jalr	584(ra) # 8000180c <get_turn>
    800025cc:	c8a8                	sw	a0,80(s1)
    800025ce:	bf7d                	j	8000258c <wakeup+0x2a>
		}
	}
}
    800025d0:	70e2                	ld	ra,56(sp)
    800025d2:	7442                	ld	s0,48(sp)
    800025d4:	74a2                	ld	s1,40(sp)
    800025d6:	7902                	ld	s2,32(sp)
    800025d8:	69e2                	ld	s3,24(sp)
    800025da:	6a42                	ld	s4,16(sp)
    800025dc:	6aa2                	ld	s5,8(sp)
    800025de:	6121                	addi	sp,sp,64
    800025e0:	8082                	ret

00000000800025e2 <reparent>:
{
    800025e2:	7179                	addi	sp,sp,-48
    800025e4:	f406                	sd	ra,40(sp)
    800025e6:	f022                	sd	s0,32(sp)
    800025e8:	ec26                	sd	s1,24(sp)
    800025ea:	e84a                	sd	s2,16(sp)
    800025ec:	e44e                	sd	s3,8(sp)
    800025ee:	e052                	sd	s4,0(sp)
    800025f0:	1800                	addi	s0,sp,48
    800025f2:	892a                	mv	s2,a0
	for (pp = proc; pp < &proc[NPROC]; pp++)
    800025f4:	0000f497          	auipc	s1,0xf
    800025f8:	0f448493          	addi	s1,s1,244 # 800116e8 <proc>
			pp->parent = initproc;
    800025fc:	00007a17          	auipc	s4,0x7
    80002600:	a2ca0a13          	addi	s4,s4,-1492 # 80009028 <initproc>
	for (pp = proc; pp < &proc[NPROC]; pp++)
    80002604:	00015997          	auipc	s3,0x15
    80002608:	4e498993          	addi	s3,s3,1252 # 80017ae8 <tickslock>
    8000260c:	a029                	j	80002616 <reparent+0x34>
    8000260e:	19048493          	addi	s1,s1,400
    80002612:	01348d63          	beq	s1,s3,8000262c <reparent+0x4a>
		if (pp->parent == p)
    80002616:	70bc                	ld	a5,96(s1)
    80002618:	ff279be3          	bne	a5,s2,8000260e <reparent+0x2c>
			pp->parent = initproc;
    8000261c:	000a3503          	ld	a0,0(s4)
    80002620:	f0a8                	sd	a0,96(s1)
			wakeup(initproc);
    80002622:	00000097          	auipc	ra,0x0
    80002626:	f40080e7          	jalr	-192(ra) # 80002562 <wakeup>
    8000262a:	b7d5                	j	8000260e <reparent+0x2c>
}
    8000262c:	70a2                	ld	ra,40(sp)
    8000262e:	7402                	ld	s0,32(sp)
    80002630:	64e2                	ld	s1,24(sp)
    80002632:	6942                	ld	s2,16(sp)
    80002634:	69a2                	ld	s3,8(sp)
    80002636:	6a02                	ld	s4,0(sp)
    80002638:	6145                	addi	sp,sp,48
    8000263a:	8082                	ret

000000008000263c <exit>:
{
    8000263c:	7179                	addi	sp,sp,-48
    8000263e:	f406                	sd	ra,40(sp)
    80002640:	f022                	sd	s0,32(sp)
    80002642:	ec26                	sd	s1,24(sp)
    80002644:	e84a                	sd	s2,16(sp)
    80002646:	e44e                	sd	s3,8(sp)
    80002648:	e052                	sd	s4,0(sp)
    8000264a:	1800                	addi	s0,sp,48
    8000264c:	8a2a                	mv	s4,a0
	struct proc *p = myproc();
    8000264e:	fffff097          	auipc	ra,0xfffff
    80002652:	374080e7          	jalr	884(ra) # 800019c2 <myproc>
    80002656:	89aa                	mv	s3,a0
	if (p == initproc)
    80002658:	00007797          	auipc	a5,0x7
    8000265c:	9d07b783          	ld	a5,-1584(a5) # 80009028 <initproc>
    80002660:	0f850493          	addi	s1,a0,248
    80002664:	17850913          	addi	s2,a0,376
    80002668:	02a79363          	bne	a5,a0,8000268e <exit+0x52>
		panic("init exiting");
    8000266c:	00006517          	auipc	a0,0x6
    80002670:	bdc50513          	addi	a0,a0,-1060 # 80008248 <digits+0x208>
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	eb6080e7          	jalr	-330(ra) # 8000052a <panic>
			fileclose(f);
    8000267c:	00002097          	auipc	ra,0x2
    80002680:	726080e7          	jalr	1830(ra) # 80004da2 <fileclose>
			p->ofile[fd] = 0;
    80002684:	0004b023          	sd	zero,0(s1)
	for (int fd = 0; fd < NOFILE; fd++)
    80002688:	04a1                	addi	s1,s1,8
    8000268a:	01248563          	beq	s1,s2,80002694 <exit+0x58>
		if (p->ofile[fd])
    8000268e:	6088                	ld	a0,0(s1)
    80002690:	f575                	bnez	a0,8000267c <exit+0x40>
    80002692:	bfdd                	j	80002688 <exit+0x4c>
	begin_op();
    80002694:	00002097          	auipc	ra,0x2
    80002698:	242080e7          	jalr	578(ra) # 800048d6 <begin_op>
	iput(p->cwd);
    8000269c:	1789b503          	ld	a0,376(s3)
    800026a0:	00002097          	auipc	ra,0x2
    800026a4:	a1a080e7          	jalr	-1510(ra) # 800040ba <iput>
	end_op();
    800026a8:	00002097          	auipc	ra,0x2
    800026ac:	2ae080e7          	jalr	686(ra) # 80004956 <end_op>
	p->cwd = 0;
    800026b0:	1609bc23          	sd	zero,376(s3)
	acquire(&wait_lock);
    800026b4:	0000f497          	auipc	s1,0xf
    800026b8:	c1c48493          	addi	s1,s1,-996 # 800112d0 <wait_lock>
    800026bc:	8526                	mv	a0,s1
    800026be:	ffffe097          	auipc	ra,0xffffe
    800026c2:	504080e7          	jalr	1284(ra) # 80000bc2 <acquire>
	reparent(p);
    800026c6:	854e                	mv	a0,s3
    800026c8:	00000097          	auipc	ra,0x0
    800026cc:	f1a080e7          	jalr	-230(ra) # 800025e2 <reparent>
	wakeup(p->parent);
    800026d0:	0609b503          	ld	a0,96(s3)
    800026d4:	00000097          	auipc	ra,0x0
    800026d8:	e8e080e7          	jalr	-370(ra) # 80002562 <wakeup>
	acquire(&p->lock);
    800026dc:	854e                	mv	a0,s3
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	4e4080e7          	jalr	1252(ra) # 80000bc2 <acquire>
	p->xstate = status;
    800026e6:	0349a623          	sw	s4,44(s3)
	p->state = ZOMBIE;
    800026ea:	4795                	li	a5,5
    800026ec:	00f9ac23          	sw	a5,24(s3)
	release(&wait_lock);
    800026f0:	8526                	mv	a0,s1
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	584080e7          	jalr	1412(ra) # 80000c76 <release>
	sched();
    800026fa:	00000097          	auipc	ra,0x0
    800026fe:	bca080e7          	jalr	-1078(ra) # 800022c4 <sched>
	panic("zombie exit");
    80002702:	00006517          	auipc	a0,0x6
    80002706:	b5650513          	addi	a0,a0,-1194 # 80008258 <digits+0x218>
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	e20080e7          	jalr	-480(ra) # 8000052a <panic>

0000000080002712 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002712:	7179                	addi	sp,sp,-48
    80002714:	f406                	sd	ra,40(sp)
    80002716:	f022                	sd	s0,32(sp)
    80002718:	ec26                	sd	s1,24(sp)
    8000271a:	e84a                	sd	s2,16(sp)
    8000271c:	e44e                	sd	s3,8(sp)
    8000271e:	1800                	addi	s0,sp,48
    80002720:	892a                	mv	s2,a0
	struct proc *p;

	for (p = proc; p < &proc[NPROC]; p++)
    80002722:	0000f497          	auipc	s1,0xf
    80002726:	fc648493          	addi	s1,s1,-58 # 800116e8 <proc>
    8000272a:	00015997          	auipc	s3,0x15
    8000272e:	3be98993          	addi	s3,s3,958 # 80017ae8 <tickslock>
	{
		acquire(&p->lock);
    80002732:	8526                	mv	a0,s1
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	48e080e7          	jalr	1166(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    8000273c:	589c                	lw	a5,48(s1)
    8000273e:	01278d63          	beq	a5,s2,80002758 <kill+0x46>
				p->state = RUNNABLE;
			}
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    80002742:	8526                	mv	a0,s1
    80002744:	ffffe097          	auipc	ra,0xffffe
    80002748:	532080e7          	jalr	1330(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    8000274c:	19048493          	addi	s1,s1,400
    80002750:	ff3491e3          	bne	s1,s3,80002732 <kill+0x20>
	}
	return -1;
    80002754:	557d                	li	a0,-1
    80002756:	a829                	j	80002770 <kill+0x5e>
			p->killed = 1;
    80002758:	4785                	li	a5,1
    8000275a:	d49c                	sw	a5,40(s1)
			if (p->state == SLEEPING)
    8000275c:	4c98                	lw	a4,24(s1)
    8000275e:	4789                	li	a5,2
    80002760:	00f70f63          	beq	a4,a5,8000277e <kill+0x6c>
			release(&p->lock);
    80002764:	8526                	mv	a0,s1
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	510080e7          	jalr	1296(ra) # 80000c76 <release>
			return 0;
    8000276e:	4501                	li	a0,0
}
    80002770:	70a2                	ld	ra,40(sp)
    80002772:	7402                	ld	s0,32(sp)
    80002774:	64e2                	ld	s1,24(sp)
    80002776:	6942                	ld	s2,16(sp)
    80002778:	69a2                	ld	s3,8(sp)
    8000277a:	6145                	addi	sp,sp,48
    8000277c:	8082                	ret
				p->state = RUNNABLE;
    8000277e:	478d                	li	a5,3
    80002780:	cc9c                	sw	a5,24(s1)
    80002782:	b7cd                	j	80002764 <kill+0x52>

0000000080002784 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002784:	7179                	addi	sp,sp,-48
    80002786:	f406                	sd	ra,40(sp)
    80002788:	f022                	sd	s0,32(sp)
    8000278a:	ec26                	sd	s1,24(sp)
    8000278c:	e84a                	sd	s2,16(sp)
    8000278e:	e44e                	sd	s3,8(sp)
    80002790:	e052                	sd	s4,0(sp)
    80002792:	1800                	addi	s0,sp,48
    80002794:	84aa                	mv	s1,a0
    80002796:	892e                	mv	s2,a1
    80002798:	89b2                	mv	s3,a2
    8000279a:	8a36                	mv	s4,a3
	struct proc *p = myproc();
    8000279c:	fffff097          	auipc	ra,0xfffff
    800027a0:	226080e7          	jalr	550(ra) # 800019c2 <myproc>
	if (user_dst)
    800027a4:	c08d                	beqz	s1,800027c6 <either_copyout+0x42>
	{
		return copyout(p->pagetable, dst, src, len);
    800027a6:	86d2                	mv	a3,s4
    800027a8:	864e                	mv	a2,s3
    800027aa:	85ca                	mv	a1,s2
    800027ac:	7d28                	ld	a0,120(a0)
    800027ae:	fffff097          	auipc	ra,0xfffff
    800027b2:	e90080e7          	jalr	-368(ra) # 8000163e <copyout>
	else
	{
		memmove((char *)dst, src, len);
		return 0;
	}
}
    800027b6:	70a2                	ld	ra,40(sp)
    800027b8:	7402                	ld	s0,32(sp)
    800027ba:	64e2                	ld	s1,24(sp)
    800027bc:	6942                	ld	s2,16(sp)
    800027be:	69a2                	ld	s3,8(sp)
    800027c0:	6a02                	ld	s4,0(sp)
    800027c2:	6145                	addi	sp,sp,48
    800027c4:	8082                	ret
		memmove((char *)dst, src, len);
    800027c6:	000a061b          	sext.w	a2,s4
    800027ca:	85ce                	mv	a1,s3
    800027cc:	854a                	mv	a0,s2
    800027ce:	ffffe097          	auipc	ra,0xffffe
    800027d2:	54c080e7          	jalr	1356(ra) # 80000d1a <memmove>
		return 0;
    800027d6:	8526                	mv	a0,s1
    800027d8:	bff9                	j	800027b6 <either_copyout+0x32>

00000000800027da <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027da:	7179                	addi	sp,sp,-48
    800027dc:	f406                	sd	ra,40(sp)
    800027de:	f022                	sd	s0,32(sp)
    800027e0:	ec26                	sd	s1,24(sp)
    800027e2:	e84a                	sd	s2,16(sp)
    800027e4:	e44e                	sd	s3,8(sp)
    800027e6:	e052                	sd	s4,0(sp)
    800027e8:	1800                	addi	s0,sp,48
    800027ea:	892a                	mv	s2,a0
    800027ec:	84ae                	mv	s1,a1
    800027ee:	89b2                	mv	s3,a2
    800027f0:	8a36                	mv	s4,a3
	struct proc *p = myproc();
    800027f2:	fffff097          	auipc	ra,0xfffff
    800027f6:	1d0080e7          	jalr	464(ra) # 800019c2 <myproc>
	if (user_src)
    800027fa:	c08d                	beqz	s1,8000281c <either_copyin+0x42>
	{
		return copyin(p->pagetable, dst, src, len);
    800027fc:	86d2                	mv	a3,s4
    800027fe:	864e                	mv	a2,s3
    80002800:	85ca                	mv	a1,s2
    80002802:	7d28                	ld	a0,120(a0)
    80002804:	fffff097          	auipc	ra,0xfffff
    80002808:	ec6080e7          	jalr	-314(ra) # 800016ca <copyin>
	else
	{
		memmove(dst, (char *)src, len);
		return 0;
	}
}
    8000280c:	70a2                	ld	ra,40(sp)
    8000280e:	7402                	ld	s0,32(sp)
    80002810:	64e2                	ld	s1,24(sp)
    80002812:	6942                	ld	s2,16(sp)
    80002814:	69a2                	ld	s3,8(sp)
    80002816:	6a02                	ld	s4,0(sp)
    80002818:	6145                	addi	sp,sp,48
    8000281a:	8082                	ret
		memmove(dst, (char *)src, len);
    8000281c:	000a061b          	sext.w	a2,s4
    80002820:	85ce                	mv	a1,s3
    80002822:	854a                	mv	a0,s2
    80002824:	ffffe097          	auipc	ra,0xffffe
    80002828:	4f6080e7          	jalr	1270(ra) # 80000d1a <memmove>
		return 0;
    8000282c:	8526                	mv	a0,s1
    8000282e:	bff9                	j	8000280c <either_copyin+0x32>

0000000080002830 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002830:	715d                	addi	sp,sp,-80
    80002832:	e486                	sd	ra,72(sp)
    80002834:	e0a2                	sd	s0,64(sp)
    80002836:	fc26                	sd	s1,56(sp)
    80002838:	f84a                	sd	s2,48(sp)
    8000283a:	f44e                	sd	s3,40(sp)
    8000283c:	f052                	sd	s4,32(sp)
    8000283e:	ec56                	sd	s5,24(sp)
    80002840:	e85a                	sd	s6,16(sp)
    80002842:	e45e                	sd	s7,8(sp)
    80002844:	0880                	addi	s0,sp,80
		[RUNNING] "run   ",
		[ZOMBIE] "zombie"};
	struct proc *p;
	char *state;

	printf("\n");
    80002846:	00006517          	auipc	a0,0x6
    8000284a:	88250513          	addi	a0,a0,-1918 # 800080c8 <digits+0x88>
    8000284e:	ffffe097          	auipc	ra,0xffffe
    80002852:	d26080e7          	jalr	-730(ra) # 80000574 <printf>
	for (p = proc; p < &proc[NPROC]; p++)
    80002856:	0000f497          	auipc	s1,0xf
    8000285a:	01248493          	addi	s1,s1,18 # 80011868 <proc+0x180>
    8000285e:	00015917          	auipc	s2,0x15
    80002862:	40a90913          	addi	s2,s2,1034 # 80017c68 <bcache+0x168>
	{
		if (p->state == UNUSED)
			continue;
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002866:	4b15                	li	s6,5
			state = states[p->state];
		else
			state = "???";
    80002868:	00006997          	auipc	s3,0x6
    8000286c:	a0098993          	addi	s3,s3,-1536 # 80008268 <digits+0x228>
		printf("%d %s %s", p->pid, state, p->name);
    80002870:	00006a97          	auipc	s5,0x6
    80002874:	a00a8a93          	addi	s5,s5,-1536 # 80008270 <digits+0x230>
		printf("\n");
    80002878:	00006a17          	auipc	s4,0x6
    8000287c:	850a0a13          	addi	s4,s4,-1968 # 800080c8 <digits+0x88>
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002880:	00006b97          	auipc	s7,0x6
    80002884:	a40b8b93          	addi	s7,s7,-1472 # 800082c0 <states.0>
    80002888:	a00d                	j	800028aa <procdump+0x7a>
		printf("%d %s %s", p->pid, state, p->name);
    8000288a:	eb06a583          	lw	a1,-336(a3)
    8000288e:	8556                	mv	a0,s5
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	ce4080e7          	jalr	-796(ra) # 80000574 <printf>
		printf("\n");
    80002898:	8552                	mv	a0,s4
    8000289a:	ffffe097          	auipc	ra,0xffffe
    8000289e:	cda080e7          	jalr	-806(ra) # 80000574 <printf>
	for (p = proc; p < &proc[NPROC]; p++)
    800028a2:	19048493          	addi	s1,s1,400
    800028a6:	03248263          	beq	s1,s2,800028ca <procdump+0x9a>
		if (p->state == UNUSED)
    800028aa:	86a6                	mv	a3,s1
    800028ac:	e984a783          	lw	a5,-360(s1)
    800028b0:	dbed                	beqz	a5,800028a2 <procdump+0x72>
			state = "???";
    800028b2:	864e                	mv	a2,s3
		if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028b4:	fcfb6be3          	bltu	s6,a5,8000288a <procdump+0x5a>
    800028b8:	02079713          	slli	a4,a5,0x20
    800028bc:	01d75793          	srli	a5,a4,0x1d
    800028c0:	97de                	add	a5,a5,s7
    800028c2:	6390                	ld	a2,0(a5)
    800028c4:	f279                	bnez	a2,8000288a <procdump+0x5a>
			state = "???";
    800028c6:	864e                	mv	a2,s3
    800028c8:	b7c9                	j	8000288a <procdump+0x5a>
	}
}
    800028ca:	60a6                	ld	ra,72(sp)
    800028cc:	6406                	ld	s0,64(sp)
    800028ce:	74e2                	ld	s1,56(sp)
    800028d0:	7942                	ld	s2,48(sp)
    800028d2:	79a2                	ld	s3,40(sp)
    800028d4:	7a02                	ld	s4,32(sp)
    800028d6:	6ae2                	ld	s5,24(sp)
    800028d8:	6b42                	ld	s6,16(sp)
    800028da:	6ba2                	ld	s7,8(sp)
    800028dc:	6161                	addi	sp,sp,80
    800028de:	8082                	ret

00000000800028e0 <trace>:
// ADDED: trace
int trace(int mask, int pid)
{
    800028e0:	7179                	addi	sp,sp,-48
    800028e2:	f406                	sd	ra,40(sp)
    800028e4:	f022                	sd	s0,32(sp)
    800028e6:	ec26                	sd	s1,24(sp)
    800028e8:	e84a                	sd	s2,16(sp)
    800028ea:	e44e                	sd	s3,8(sp)
    800028ec:	e052                	sd	s4,0(sp)
    800028ee:	1800                	addi	s0,sp,48
    800028f0:	8a2a                	mv	s4,a0
    800028f2:	892e                	mv	s2,a1
	struct proc *p;
	for (p = proc; p < &proc[NPROC]; p++)
    800028f4:	0000f497          	auipc	s1,0xf
    800028f8:	df448493          	addi	s1,s1,-524 # 800116e8 <proc>
    800028fc:	00015997          	auipc	s3,0x15
    80002900:	1ec98993          	addi	s3,s3,492 # 80017ae8 <tickslock>
	{
		acquire(&p->lock);
    80002904:	8526                	mv	a0,s1
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	2bc080e7          	jalr	700(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    8000290e:	589c                	lw	a5,48(s1)
    80002910:	01278d63          	beq	a5,s2,8000292a <trace+0x4a>
		{
			p->trace_mask = mask;
			release(&p->lock);
			return 0;
		}
		release(&p->lock);
    80002914:	8526                	mv	a0,s1
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	360080e7          	jalr	864(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    8000291e:	19048493          	addi	s1,s1,400
    80002922:	ff3491e3          	bne	s1,s3,80002904 <trace+0x24>
	}

	return -1;
    80002926:	557d                	li	a0,-1
    80002928:	a809                	j	8000293a <trace+0x5a>
			p->trace_mask = mask;
    8000292a:	0344aa23          	sw	s4,52(s1)
			release(&p->lock);
    8000292e:	8526                	mv	a0,s1
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	346080e7          	jalr	838(ra) # 80000c76 <release>
			return 0;
    80002938:	4501                	li	a0,0
}
    8000293a:	70a2                	ld	ra,40(sp)
    8000293c:	7402                	ld	s0,32(sp)
    8000293e:	64e2                	ld	s1,24(sp)
    80002940:	6942                	ld	s2,16(sp)
    80002942:	69a2                	ld	s3,8(sp)
    80002944:	6a02                	ld	s4,0(sp)
    80002946:	6145                	addi	sp,sp,48
    80002948:	8082                	ret

000000008000294a <getmsk>:
// ADDED: getmsk
int getmsk(int pid)
{
    8000294a:	7179                	addi	sp,sp,-48
    8000294c:	f406                	sd	ra,40(sp)
    8000294e:	f022                	sd	s0,32(sp)
    80002950:	ec26                	sd	s1,24(sp)
    80002952:	e84a                	sd	s2,16(sp)
    80002954:	e44e                	sd	s3,8(sp)
    80002956:	1800                	addi	s0,sp,48
    80002958:	892a                	mv	s2,a0
	struct proc *p;
	int mask;

	for (p = proc; p < &proc[NPROC]; p++)
    8000295a:	0000f497          	auipc	s1,0xf
    8000295e:	d8e48493          	addi	s1,s1,-626 # 800116e8 <proc>
    80002962:	00015997          	auipc	s3,0x15
    80002966:	18698993          	addi	s3,s3,390 # 80017ae8 <tickslock>
	{
		acquire(&p->lock);
    8000296a:	8526                	mv	a0,s1
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	256080e7          	jalr	598(ra) # 80000bc2 <acquire>
		if (p->pid == pid)
    80002974:	589c                	lw	a5,48(s1)
    80002976:	01278d63          	beq	a5,s2,80002990 <getmsk+0x46>
		{
			mask = p->trace_mask;
			release(&p->lock);
			return mask;
		}
		release(&p->lock);
    8000297a:	8526                	mv	a0,s1
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	2fa080e7          	jalr	762(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80002984:	19048493          	addi	s1,s1,400
    80002988:	ff3491e3          	bne	s1,s3,8000296a <getmsk+0x20>
	}

	return -1;
    8000298c:	597d                	li	s2,-1
    8000298e:	a801                	j	8000299e <getmsk+0x54>
			mask = p->trace_mask;
    80002990:	0344a903          	lw	s2,52(s1)
			release(&p->lock);
    80002994:	8526                	mv	a0,s1
    80002996:	ffffe097          	auipc	ra,0xffffe
    8000299a:	2e0080e7          	jalr	736(ra) # 80000c76 <release>
}
    8000299e:	854a                	mv	a0,s2
    800029a0:	70a2                	ld	ra,40(sp)
    800029a2:	7402                	ld	s0,32(sp)
    800029a4:	64e2                	ld	s1,24(sp)
    800029a6:	6942                	ld	s2,16(sp)
    800029a8:	69a2                	ld	s3,8(sp)
    800029aa:	6145                	addi	sp,sp,48
    800029ac:	8082                	ret

00000000800029ae <update_avg_burst_zero_burst>:
		// Wait for a child to exit.
		sleep(p, &wait_lock); //DOC: wait-sleep
	}
}

void update_avg_burst_zero_burst(struct proc *p){
    800029ae:	1101                	addi	sp,sp,-32
    800029b0:	ec06                	sd	ra,24(sp)
    800029b2:	e822                	sd	s0,16(sp)
    800029b4:	e426                	sd	s1,8(sp)
    800029b6:	1000                	addi	s0,sp,32
    800029b8:	84aa                	mv	s1,a0
	uint B = p->burst;
    800029ba:	4970                	lw	a2,84(a0)
	uint A = p->performance.average_bursttime;
	A = ALPHA * B + (100 - ALPHA) * A / 100;
    800029bc:	03200793          	li	a5,50
    800029c0:	4578                	lw	a4,76(a0)
    800029c2:	02e7873b          	mulw	a4,a5,a4
    800029c6:	06400693          	li	a3,100
    800029ca:	02d7573b          	divuw	a4,a4,a3
    800029ce:	02c787bb          	mulw	a5,a5,a2
    800029d2:	9fb9                	addw	a5,a5,a4
	p->performance.average_bursttime = A;
    800029d4:	c57c                	sw	a5,76(a0)
	printf("process: %d burst: %d\n", p->pid, p->burst);
    800029d6:	590c                	lw	a1,48(a0)
    800029d8:	00006517          	auipc	a0,0x6
    800029dc:	8a850513          	addi	a0,a0,-1880 # 80008280 <digits+0x240>
    800029e0:	ffffe097          	auipc	ra,0xffffe
    800029e4:	b94080e7          	jalr	-1132(ra) # 80000574 <printf>
	p->burst = 0;
    800029e8:	0404aa23          	sw	zero,84(s1)
}
    800029ec:	60e2                	ld	ra,24(sp)
    800029ee:	6442                	ld	s0,16(sp)
    800029f0:	64a2                	ld	s1,8(sp)
    800029f2:	6105                	addi	sp,sp,32
    800029f4:	8082                	ret

00000000800029f6 <update_perf>:

// ADDED: update_perf
void update_perf(uint ticks, struct proc *p)
{
    800029f6:	1101                	addi	sp,sp,-32
    800029f8:	ec06                	sd	ra,24(sp)
    800029fa:	e822                	sd	s0,16(sp)
    800029fc:	e426                	sd	s1,8(sp)
    800029fe:	e04a                	sd	s2,0(sp)
    80002a00:	1000                	addi	s0,sp,32
    80002a02:	84ae                	mv	s1,a1
	switch (p->state)
    80002a04:	4d9c                	lw	a5,24(a1)
    80002a06:	4711                	li	a4,4
    80002a08:	02e78d63          	beq	a5,a4,80002a42 <update_perf+0x4c>
    80002a0c:	892a                	mv	s2,a0
    80002a0e:	00f76e63          	bltu	a4,a5,80002a2a <update_perf+0x34>
    80002a12:	4709                	li	a4,2
    80002a14:	04e78363          	beq	a5,a4,80002a5a <update_perf+0x64>
    80002a18:	470d                	li	a4,3
    80002a1a:	02e79a63          	bne	a5,a4,80002a4e <update_perf+0x58>
		if(p->burst > 0)
			update_avg_burst_zero_burst(p);
		p->performance.stime++;
		break;
	case RUNNABLE:
		if(p->burst > 0)
    80002a1e:	49fc                	lw	a5,84(a1)
    80002a20:	eba9                	bnez	a5,80002a72 <update_perf+0x7c>
			update_avg_burst_zero_burst(p);
		p->performance.retime++;
    80002a22:	40fc                	lw	a5,68(s1)
    80002a24:	2785                	addiw	a5,a5,1
    80002a26:	c0fc                	sw	a5,68(s1)
		break;
    80002a28:	a01d                	j	80002a4e <update_perf+0x58>
	switch (p->state)
    80002a2a:	4715                	li	a4,5
    80002a2c:	02e79163          	bne	a5,a4,80002a4e <update_perf+0x58>
	case ZOMBIE:
		if(p->burst > 0)
    80002a30:	49fc                	lw	a5,84(a1)
    80002a32:	e7b1                	bnez	a5,80002a7e <update_perf+0x88>
			update_avg_burst_zero_burst(p);
		if (p->performance.ttime == -1)
    80002a34:	5cd8                	lw	a4,60(s1)
    80002a36:	57fd                	li	a5,-1
    80002a38:	00f71b63          	bne	a4,a5,80002a4e <update_perf+0x58>
			p->performance.ttime = ticks;
    80002a3c:	0324ae23          	sw	s2,60(s1)
		break;
	default:
		break;
	}
}
    80002a40:	a039                	j	80002a4e <update_perf+0x58>
		p->burst++;
    80002a42:	49fc                	lw	a5,84(a1)
    80002a44:	2785                	addiw	a5,a5,1
    80002a46:	c9fc                	sw	a5,84(a1)
		p->performance.rutime++;
    80002a48:	45bc                	lw	a5,72(a1)
    80002a4a:	2785                	addiw	a5,a5,1
    80002a4c:	c5bc                	sw	a5,72(a1)
}
    80002a4e:	60e2                	ld	ra,24(sp)
    80002a50:	6442                	ld	s0,16(sp)
    80002a52:	64a2                	ld	s1,8(sp)
    80002a54:	6902                	ld	s2,0(sp)
    80002a56:	6105                	addi	sp,sp,32
    80002a58:	8082                	ret
		if(p->burst > 0)
    80002a5a:	49fc                	lw	a5,84(a1)
    80002a5c:	e789                	bnez	a5,80002a66 <update_perf+0x70>
		p->performance.stime++;
    80002a5e:	40bc                	lw	a5,64(s1)
    80002a60:	2785                	addiw	a5,a5,1
    80002a62:	c0bc                	sw	a5,64(s1)
		break;
    80002a64:	b7ed                	j	80002a4e <update_perf+0x58>
			update_avg_burst_zero_burst(p);
    80002a66:	852e                	mv	a0,a1
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	f46080e7          	jalr	-186(ra) # 800029ae <update_avg_burst_zero_burst>
    80002a70:	b7fd                	j	80002a5e <update_perf+0x68>
			update_avg_burst_zero_burst(p);
    80002a72:	852e                	mv	a0,a1
    80002a74:	00000097          	auipc	ra,0x0
    80002a78:	f3a080e7          	jalr	-198(ra) # 800029ae <update_avg_burst_zero_burst>
    80002a7c:	b75d                	j	80002a22 <update_perf+0x2c>
			update_avg_burst_zero_burst(p);
    80002a7e:	852e                	mv	a0,a1
    80002a80:	00000097          	auipc	ra,0x0
    80002a84:	f2e080e7          	jalr	-210(ra) # 800029ae <update_avg_burst_zero_burst>
    80002a88:	b775                	j	80002a34 <update_perf+0x3e>

0000000080002a8a <wait_stat>:
{
    80002a8a:	711d                	addi	sp,sp,-96
    80002a8c:	ec86                	sd	ra,88(sp)
    80002a8e:	e8a2                	sd	s0,80(sp)
    80002a90:	e4a6                	sd	s1,72(sp)
    80002a92:	e0ca                	sd	s2,64(sp)
    80002a94:	fc4e                	sd	s3,56(sp)
    80002a96:	f852                	sd	s4,48(sp)
    80002a98:	f456                	sd	s5,40(sp)
    80002a9a:	f05a                	sd	s6,32(sp)
    80002a9c:	ec5e                	sd	s7,24(sp)
    80002a9e:	e862                	sd	s8,16(sp)
    80002aa0:	e466                	sd	s9,8(sp)
    80002aa2:	1080                	addi	s0,sp,96
    80002aa4:	8b2a                	mv	s6,a0
    80002aa6:	8bae                	mv	s7,a1
	struct proc *p = myproc();
    80002aa8:	fffff097          	auipc	ra,0xfffff
    80002aac:	f1a080e7          	jalr	-230(ra) # 800019c2 <myproc>
    80002ab0:	892a                	mv	s2,a0
	acquire(&wait_lock);
    80002ab2:	0000f517          	auipc	a0,0xf
    80002ab6:	81e50513          	addi	a0,a0,-2018 # 800112d0 <wait_lock>
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	108080e7          	jalr	264(ra) # 80000bc2 <acquire>
		havekids = 0;
    80002ac2:	4c01                	li	s8,0
				if (np->state == ZOMBIE)
    80002ac4:	4a15                	li	s4,5
				havekids = 1;
    80002ac6:	4a85                	li	s5,1
		for (np = proc; np < &proc[NPROC]; np++)
    80002ac8:	00015997          	auipc	s3,0x15
    80002acc:	02098993          	addi	s3,s3,32 # 80017ae8 <tickslock>
		sleep(p, &wait_lock); //DOC: wait-sleep
    80002ad0:	0000fc97          	auipc	s9,0xf
    80002ad4:	800c8c93          	addi	s9,s9,-2048 # 800112d0 <wait_lock>
		havekids = 0;
    80002ad8:	8762                	mv	a4,s8
		for (np = proc; np < &proc[NPROC]; np++)
    80002ada:	0000f497          	auipc	s1,0xf
    80002ade:	c0e48493          	addi	s1,s1,-1010 # 800116e8 <proc>
    80002ae2:	a85d                	j	80002b98 <wait_stat+0x10e>
					pid = np->pid;
    80002ae4:	0304a983          	lw	s3,48(s1)
					update_perf(ticks, np);
    80002ae8:	85a6                	mv	a1,s1
    80002aea:	00006517          	auipc	a0,0x6
    80002aee:	54652503          	lw	a0,1350(a0) # 80009030 <ticks>
    80002af2:	00000097          	auipc	ra,0x0
    80002af6:	f04080e7          	jalr	-252(ra) # 800029f6 <update_perf>
					if (status != 0 && copyout(p->pagetable, status, (char *)&np->xstate,
    80002afa:	000b0e63          	beqz	s6,80002b16 <wait_stat+0x8c>
    80002afe:	4691                	li	a3,4
    80002b00:	02c48613          	addi	a2,s1,44
    80002b04:	85da                	mv	a1,s6
    80002b06:	07893503          	ld	a0,120(s2)
    80002b0a:	fffff097          	auipc	ra,0xfffff
    80002b0e:	b34080e7          	jalr	-1228(ra) # 8000163e <copyout>
    80002b12:	04054163          	bltz	a0,80002b54 <wait_stat+0xca>
					if (copyout(p->pagetable, performance, (char *)&(np->performance), sizeof(struct perf)) < 0)
    80002b16:	46e1                	li	a3,24
    80002b18:	03848613          	addi	a2,s1,56
    80002b1c:	85de                	mv	a1,s7
    80002b1e:	07893503          	ld	a0,120(s2)
    80002b22:	fffff097          	auipc	ra,0xfffff
    80002b26:	b1c080e7          	jalr	-1252(ra) # 8000163e <copyout>
    80002b2a:	04054463          	bltz	a0,80002b72 <wait_stat+0xe8>
					freeproc(np);
    80002b2e:	8526                	mv	a0,s1
    80002b30:	fffff097          	auipc	ra,0xfffff
    80002b34:	044080e7          	jalr	68(ra) # 80001b74 <freeproc>
					release(&np->lock);
    80002b38:	8526                	mv	a0,s1
    80002b3a:	ffffe097          	auipc	ra,0xffffe
    80002b3e:	13c080e7          	jalr	316(ra) # 80000c76 <release>
					release(&wait_lock);
    80002b42:	0000e517          	auipc	a0,0xe
    80002b46:	78e50513          	addi	a0,a0,1934 # 800112d0 <wait_lock>
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	12c080e7          	jalr	300(ra) # 80000c76 <release>
					return pid;
    80002b52:	a051                	j	80002bd6 <wait_stat+0x14c>
						release(&np->lock);
    80002b54:	8526                	mv	a0,s1
    80002b56:	ffffe097          	auipc	ra,0xffffe
    80002b5a:	120080e7          	jalr	288(ra) # 80000c76 <release>
						release(&wait_lock);
    80002b5e:	0000e517          	auipc	a0,0xe
    80002b62:	77250513          	addi	a0,a0,1906 # 800112d0 <wait_lock>
    80002b66:	ffffe097          	auipc	ra,0xffffe
    80002b6a:	110080e7          	jalr	272(ra) # 80000c76 <release>
						return -1;
    80002b6e:	59fd                	li	s3,-1
    80002b70:	a09d                	j	80002bd6 <wait_stat+0x14c>
						release(&np->lock);
    80002b72:	8526                	mv	a0,s1
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	102080e7          	jalr	258(ra) # 80000c76 <release>
						release(&wait_lock);
    80002b7c:	0000e517          	auipc	a0,0xe
    80002b80:	75450513          	addi	a0,a0,1876 # 800112d0 <wait_lock>
    80002b84:	ffffe097          	auipc	ra,0xffffe
    80002b88:	0f2080e7          	jalr	242(ra) # 80000c76 <release>
						return -1;
    80002b8c:	59fd                	li	s3,-1
    80002b8e:	a0a1                	j	80002bd6 <wait_stat+0x14c>
		for (np = proc; np < &proc[NPROC]; np++)
    80002b90:	19048493          	addi	s1,s1,400
    80002b94:	03348463          	beq	s1,s3,80002bbc <wait_stat+0x132>
			if (np->parent == p)
    80002b98:	70bc                	ld	a5,96(s1)
    80002b9a:	ff279be3          	bne	a5,s2,80002b90 <wait_stat+0x106>
				acquire(&np->lock);
    80002b9e:	8526                	mv	a0,s1
    80002ba0:	ffffe097          	auipc	ra,0xffffe
    80002ba4:	022080e7          	jalr	34(ra) # 80000bc2 <acquire>
				if (np->state == ZOMBIE)
    80002ba8:	4c9c                	lw	a5,24(s1)
    80002baa:	f3478de3          	beq	a5,s4,80002ae4 <wait_stat+0x5a>
				release(&np->lock);
    80002bae:	8526                	mv	a0,s1
    80002bb0:	ffffe097          	auipc	ra,0xffffe
    80002bb4:	0c6080e7          	jalr	198(ra) # 80000c76 <release>
				havekids = 1;
    80002bb8:	8756                	mv	a4,s5
    80002bba:	bfd9                	j	80002b90 <wait_stat+0x106>
		if (!havekids || p->killed)
    80002bbc:	c701                	beqz	a4,80002bc4 <wait_stat+0x13a>
    80002bbe:	02892783          	lw	a5,40(s2)
    80002bc2:	cb85                	beqz	a5,80002bf2 <wait_stat+0x168>
			release(&wait_lock);
    80002bc4:	0000e517          	auipc	a0,0xe
    80002bc8:	70c50513          	addi	a0,a0,1804 # 800112d0 <wait_lock>
    80002bcc:	ffffe097          	auipc	ra,0xffffe
    80002bd0:	0aa080e7          	jalr	170(ra) # 80000c76 <release>
			return -1;
    80002bd4:	59fd                	li	s3,-1
}
    80002bd6:	854e                	mv	a0,s3
    80002bd8:	60e6                	ld	ra,88(sp)
    80002bda:	6446                	ld	s0,80(sp)
    80002bdc:	64a6                	ld	s1,72(sp)
    80002bde:	6906                	ld	s2,64(sp)
    80002be0:	79e2                	ld	s3,56(sp)
    80002be2:	7a42                	ld	s4,48(sp)
    80002be4:	7aa2                	ld	s5,40(sp)
    80002be6:	7b02                	ld	s6,32(sp)
    80002be8:	6be2                	ld	s7,24(sp)
    80002bea:	6c42                	ld	s8,16(sp)
    80002bec:	6ca2                	ld	s9,8(sp)
    80002bee:	6125                	addi	sp,sp,96
    80002bf0:	8082                	ret
		sleep(p, &wait_lock); //DOC: wait-sleep
    80002bf2:	85e6                	mv	a1,s9
    80002bf4:	854a                	mv	a0,s2
    80002bf6:	fffff097          	auipc	ra,0xfffff
    80002bfa:	7e0080e7          	jalr	2016(ra) # 800023d6 <sleep>
		havekids = 0;
    80002bfe:	bde9                	j	80002ad8 <wait_stat+0x4e>

0000000080002c00 <update_perfs>:

// ADDED: update_perfs
void update_perfs(uint ticks)
{
    80002c00:	7179                	addi	sp,sp,-48
    80002c02:	f406                	sd	ra,40(sp)
    80002c04:	f022                	sd	s0,32(sp)
    80002c06:	ec26                	sd	s1,24(sp)
    80002c08:	e84a                	sd	s2,16(sp)
    80002c0a:	e44e                	sd	s3,8(sp)
    80002c0c:	1800                	addi	s0,sp,48
    80002c0e:	892a                	mv	s2,a0
	struct proc *p;
	for (p = proc; p < &proc[NPROC]; p++)
    80002c10:	0000f497          	auipc	s1,0xf
    80002c14:	ad848493          	addi	s1,s1,-1320 # 800116e8 <proc>
    80002c18:	00015997          	auipc	s3,0x15
    80002c1c:	ed098993          	addi	s3,s3,-304 # 80017ae8 <tickslock>
	{
		acquire(&p->lock);
    80002c20:	8526                	mv	a0,s1
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	fa0080e7          	jalr	-96(ra) # 80000bc2 <acquire>
		update_perf(ticks, p);
    80002c2a:	85a6                	mv	a1,s1
    80002c2c:	854a                	mv	a0,s2
    80002c2e:	00000097          	auipc	ra,0x0
    80002c32:	dc8080e7          	jalr	-568(ra) # 800029f6 <update_perf>
		release(&p->lock);
    80002c36:	8526                	mv	a0,s1
    80002c38:	ffffe097          	auipc	ra,0xffffe
    80002c3c:	03e080e7          	jalr	62(ra) # 80000c76 <release>
	for (p = proc; p < &proc[NPROC]; p++)
    80002c40:	19048493          	addi	s1,s1,400
    80002c44:	fd349ee3          	bne	s1,s3,80002c20 <update_perfs+0x20>
	}
}
    80002c48:	70a2                	ld	ra,40(sp)
    80002c4a:	7402                	ld	s0,32(sp)
    80002c4c:	64e2                	ld	s1,24(sp)
    80002c4e:	6942                	ld	s2,16(sp)
    80002c50:	69a2                	ld	s3,8(sp)
    80002c52:	6145                	addi	sp,sp,48
    80002c54:	8082                	ret

0000000080002c56 <set_priority>:

// ADDED: set_priority
int set_priority(int priority) {
    80002c56:	1101                	addi	sp,sp,-32
    80002c58:	ec06                	sd	ra,24(sp)
    80002c5a:	e822                	sd	s0,16(sp)
    80002c5c:	e426                	sd	s1,8(sp)
    80002c5e:	1000                	addi	s0,sp,32
    80002c60:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    80002c62:	fffff097          	auipc	ra,0xfffff
    80002c66:	d60080e7          	jalr	-672(ra) # 800019c2 <myproc>
	if (priority >= 1 && priority <= 5) {
    80002c6a:	fff4871b          	addiw	a4,s1,-1
    80002c6e:	4791                	li	a5,4
    80002c70:	00e7e963          	bltu	a5,a4,80002c82 <set_priority+0x2c>
		p->priority = priority;
    80002c74:	cd24                	sw	s1,88(a0)
		return 0;
    80002c76:	4501                	li	a0,0
	}
	return -1;
    80002c78:	60e2                	ld	ra,24(sp)
    80002c7a:	6442                	ld	s0,16(sp)
    80002c7c:	64a2                	ld	s1,8(sp)
    80002c7e:	6105                	addi	sp,sp,32
    80002c80:	8082                	ret
	return -1;
    80002c82:	557d                	li	a0,-1
    80002c84:	bfd5                	j	80002c78 <set_priority+0x22>

0000000080002c86 <swtch>:
    80002c86:	00153023          	sd	ra,0(a0)
    80002c8a:	00253423          	sd	sp,8(a0)
    80002c8e:	e900                	sd	s0,16(a0)
    80002c90:	ed04                	sd	s1,24(a0)
    80002c92:	03253023          	sd	s2,32(a0)
    80002c96:	03353423          	sd	s3,40(a0)
    80002c9a:	03453823          	sd	s4,48(a0)
    80002c9e:	03553c23          	sd	s5,56(a0)
    80002ca2:	05653023          	sd	s6,64(a0)
    80002ca6:	05753423          	sd	s7,72(a0)
    80002caa:	05853823          	sd	s8,80(a0)
    80002cae:	05953c23          	sd	s9,88(a0)
    80002cb2:	07a53023          	sd	s10,96(a0)
    80002cb6:	07b53423          	sd	s11,104(a0)
    80002cba:	0005b083          	ld	ra,0(a1)
    80002cbe:	0085b103          	ld	sp,8(a1)
    80002cc2:	6980                	ld	s0,16(a1)
    80002cc4:	6d84                	ld	s1,24(a1)
    80002cc6:	0205b903          	ld	s2,32(a1)
    80002cca:	0285b983          	ld	s3,40(a1)
    80002cce:	0305ba03          	ld	s4,48(a1)
    80002cd2:	0385ba83          	ld	s5,56(a1)
    80002cd6:	0405bb03          	ld	s6,64(a1)
    80002cda:	0485bb83          	ld	s7,72(a1)
    80002cde:	0505bc03          	ld	s8,80(a1)
    80002ce2:	0585bc83          	ld	s9,88(a1)
    80002ce6:	0605bd03          	ld	s10,96(a1)
    80002cea:	0685bd83          	ld	s11,104(a1)
    80002cee:	8082                	ret

0000000080002cf0 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002cf0:	1141                	addi	sp,sp,-16
    80002cf2:	e406                	sd	ra,8(sp)
    80002cf4:	e022                	sd	s0,0(sp)
    80002cf6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002cf8:	00005597          	auipc	a1,0x5
    80002cfc:	5f858593          	addi	a1,a1,1528 # 800082f0 <states.0+0x30>
    80002d00:	00015517          	auipc	a0,0x15
    80002d04:	de850513          	addi	a0,a0,-536 # 80017ae8 <tickslock>
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	e2a080e7          	jalr	-470(ra) # 80000b32 <initlock>
}
    80002d10:	60a2                	ld	ra,8(sp)
    80002d12:	6402                	ld	s0,0(sp)
    80002d14:	0141                	addi	sp,sp,16
    80002d16:	8082                	ret

0000000080002d18 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002d18:	1141                	addi	sp,sp,-16
    80002d1a:	e422                	sd	s0,8(sp)
    80002d1c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d1e:	00003797          	auipc	a5,0x3
    80002d22:	6b278793          	addi	a5,a5,1714 # 800063d0 <kernelvec>
    80002d26:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002d2a:	6422                	ld	s0,8(sp)
    80002d2c:	0141                	addi	sp,sp,16
    80002d2e:	8082                	ret

0000000080002d30 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002d30:	1141                	addi	sp,sp,-16
    80002d32:	e406                	sd	ra,8(sp)
    80002d34:	e022                	sd	s0,0(sp)
    80002d36:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d38:	fffff097          	auipc	ra,0xfffff
    80002d3c:	c8a080e7          	jalr	-886(ra) # 800019c2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d40:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d44:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d46:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002d4a:	00004617          	auipc	a2,0x4
    80002d4e:	2b660613          	addi	a2,a2,694 # 80007000 <_trampoline>
    80002d52:	00004697          	auipc	a3,0x4
    80002d56:	2ae68693          	addi	a3,a3,686 # 80007000 <_trampoline>
    80002d5a:	8e91                	sub	a3,a3,a2
    80002d5c:	040007b7          	lui	a5,0x4000
    80002d60:	17fd                	addi	a5,a5,-1
    80002d62:	07b2                	slli	a5,a5,0xc
    80002d64:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d66:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d6a:	6158                	ld	a4,128(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d6c:	180026f3          	csrr	a3,satp
    80002d70:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d72:	6158                	ld	a4,128(a0)
    80002d74:	7534                	ld	a3,104(a0)
    80002d76:	6585                	lui	a1,0x1
    80002d78:	96ae                	add	a3,a3,a1
    80002d7a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d7c:	6158                	ld	a4,128(a0)
    80002d7e:	00000697          	auipc	a3,0x0
    80002d82:	14868693          	addi	a3,a3,328 # 80002ec6 <usertrap>
    80002d86:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002d88:	6158                	ld	a4,128(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d8a:	8692                	mv	a3,tp
    80002d8c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d8e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d92:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d96:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d9a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d9e:	6158                	ld	a4,128(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002da0:	6f18                	ld	a4,24(a4)
    80002da2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002da6:	7d2c                	ld	a1,120(a0)
    80002da8:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002daa:	00004717          	auipc	a4,0x4
    80002dae:	2e670713          	addi	a4,a4,742 # 80007090 <userret>
    80002db2:	8f11                	sub	a4,a4,a2
    80002db4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64, uint64))fn)(TRAPFRAME, satp);
    80002db6:	577d                	li	a4,-1
    80002db8:	177e                	slli	a4,a4,0x3f
    80002dba:	8dd9                	or	a1,a1,a4
    80002dbc:	02000537          	lui	a0,0x2000
    80002dc0:	157d                	addi	a0,a0,-1
    80002dc2:	0536                	slli	a0,a0,0xd
    80002dc4:	9782                	jalr	a5
}
    80002dc6:	60a2                	ld	ra,8(sp)
    80002dc8:	6402                	ld	s0,0(sp)
    80002dca:	0141                	addi	sp,sp,16
    80002dcc:	8082                	ret

0000000080002dce <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002dce:	1101                	addi	sp,sp,-32
    80002dd0:	ec06                	sd	ra,24(sp)
    80002dd2:	e822                	sd	s0,16(sp)
    80002dd4:	e426                	sd	s1,8(sp)
    80002dd6:	e04a                	sd	s2,0(sp)
    80002dd8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002dda:	00015917          	auipc	s2,0x15
    80002dde:	d0e90913          	addi	s2,s2,-754 # 80017ae8 <tickslock>
    80002de2:	854a                	mv	a0,s2
    80002de4:	ffffe097          	auipc	ra,0xffffe
    80002de8:	dde080e7          	jalr	-546(ra) # 80000bc2 <acquire>
  ticks++;
    80002dec:	00006497          	auipc	s1,0x6
    80002df0:	24448493          	addi	s1,s1,580 # 80009030 <ticks>
    80002df4:	4088                	lw	a0,0(s1)
    80002df6:	2505                	addiw	a0,a0,1
    80002df8:	c088                	sw	a0,0(s1)
  update_perfs(ticks);
    80002dfa:	2501                	sext.w	a0,a0
    80002dfc:	00000097          	auipc	ra,0x0
    80002e00:	e04080e7          	jalr	-508(ra) # 80002c00 <update_perfs>
  wakeup(&ticks);
    80002e04:	8526                	mv	a0,s1
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	75c080e7          	jalr	1884(ra) # 80002562 <wakeup>
  release(&tickslock);
    80002e0e:	854a                	mv	a0,s2
    80002e10:	ffffe097          	auipc	ra,0xffffe
    80002e14:	e66080e7          	jalr	-410(ra) # 80000c76 <release>
}
    80002e18:	60e2                	ld	ra,24(sp)
    80002e1a:	6442                	ld	s0,16(sp)
    80002e1c:	64a2                	ld	s1,8(sp)
    80002e1e:	6902                	ld	s2,0(sp)
    80002e20:	6105                	addi	sp,sp,32
    80002e22:	8082                	ret

0000000080002e24 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002e24:	1101                	addi	sp,sp,-32
    80002e26:	ec06                	sd	ra,24(sp)
    80002e28:	e822                	sd	s0,16(sp)
    80002e2a:	e426                	sd	s1,8(sp)
    80002e2c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e2e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002e32:	00074d63          	bltz	a4,80002e4c <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002e36:	57fd                	li	a5,-1
    80002e38:	17fe                	slli	a5,a5,0x3f
    80002e3a:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002e3c:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002e3e:	06f70363          	beq	a4,a5,80002ea4 <devintr+0x80>
  }
}
    80002e42:	60e2                	ld	ra,24(sp)
    80002e44:	6442                	ld	s0,16(sp)
    80002e46:	64a2                	ld	s1,8(sp)
    80002e48:	6105                	addi	sp,sp,32
    80002e4a:	8082                	ret
      (scause & 0xff) == 9)
    80002e4c:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002e50:	46a5                	li	a3,9
    80002e52:	fed792e3          	bne	a5,a3,80002e36 <devintr+0x12>
    int irq = plic_claim();
    80002e56:	00003097          	auipc	ra,0x3
    80002e5a:	682080e7          	jalr	1666(ra) # 800064d8 <plic_claim>
    80002e5e:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002e60:	47a9                	li	a5,10
    80002e62:	02f50763          	beq	a0,a5,80002e90 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002e66:	4785                	li	a5,1
    80002e68:	02f50963          	beq	a0,a5,80002e9a <devintr+0x76>
    return 1;
    80002e6c:	4505                	li	a0,1
    else if (irq)
    80002e6e:	d8f1                	beqz	s1,80002e42 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e70:	85a6                	mv	a1,s1
    80002e72:	00005517          	auipc	a0,0x5
    80002e76:	48650513          	addi	a0,a0,1158 # 800082f8 <states.0+0x38>
    80002e7a:	ffffd097          	auipc	ra,0xffffd
    80002e7e:	6fa080e7          	jalr	1786(ra) # 80000574 <printf>
      plic_complete(irq);
    80002e82:	8526                	mv	a0,s1
    80002e84:	00003097          	auipc	ra,0x3
    80002e88:	678080e7          	jalr	1656(ra) # 800064fc <plic_complete>
    return 1;
    80002e8c:	4505                	li	a0,1
    80002e8e:	bf55                	j	80002e42 <devintr+0x1e>
      uartintr();
    80002e90:	ffffe097          	auipc	ra,0xffffe
    80002e94:	af6080e7          	jalr	-1290(ra) # 80000986 <uartintr>
    80002e98:	b7ed                	j	80002e82 <devintr+0x5e>
      virtio_disk_intr();
    80002e9a:	00004097          	auipc	ra,0x4
    80002e9e:	af4080e7          	jalr	-1292(ra) # 8000698e <virtio_disk_intr>
    80002ea2:	b7c5                	j	80002e82 <devintr+0x5e>
    if (cpuid() == 0)
    80002ea4:	fffff097          	auipc	ra,0xfffff
    80002ea8:	af2080e7          	jalr	-1294(ra) # 80001996 <cpuid>
    80002eac:	c901                	beqz	a0,80002ebc <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002eae:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002eb2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002eb4:	14479073          	csrw	sip,a5
    return 2;
    80002eb8:	4509                	li	a0,2
    80002eba:	b761                	j	80002e42 <devintr+0x1e>
      clockintr();
    80002ebc:	00000097          	auipc	ra,0x0
    80002ec0:	f12080e7          	jalr	-238(ra) # 80002dce <clockintr>
    80002ec4:	b7ed                	j	80002eae <devintr+0x8a>

0000000080002ec6 <usertrap>:
{
    80002ec6:	1101                	addi	sp,sp,-32
    80002ec8:	ec06                	sd	ra,24(sp)
    80002eca:	e822                	sd	s0,16(sp)
    80002ecc:	e426                	sd	s1,8(sp)
    80002ece:	e04a                	sd	s2,0(sp)
    80002ed0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ed2:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002ed6:	1007f793          	andi	a5,a5,256
    80002eda:	e3ad                	bnez	a5,80002f3c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002edc:	00003797          	auipc	a5,0x3
    80002ee0:	4f478793          	addi	a5,a5,1268 # 800063d0 <kernelvec>
    80002ee4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ee8:	fffff097          	auipc	ra,0xfffff
    80002eec:	ada080e7          	jalr	-1318(ra) # 800019c2 <myproc>
    80002ef0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ef2:	615c                	ld	a5,128(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ef4:	14102773          	csrr	a4,sepc
    80002ef8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002efa:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002efe:	47a1                	li	a5,8
    80002f00:	04f71c63          	bne	a4,a5,80002f58 <usertrap+0x92>
    if (p->killed)
    80002f04:	551c                	lw	a5,40(a0)
    80002f06:	e3b9                	bnez	a5,80002f4c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002f08:	60d8                	ld	a4,128(s1)
    80002f0a:	6f1c                	ld	a5,24(a4)
    80002f0c:	0791                	addi	a5,a5,4
    80002f0e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f10:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f14:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f18:	10079073          	csrw	sstatus,a5
    syscall();
    80002f1c:	00000097          	auipc	ra,0x0
    80002f20:	400080e7          	jalr	1024(ra) # 8000331c <syscall>
  if (p->killed)
    80002f24:	549c                	lw	a5,40(s1)
    80002f26:	efcd                	bnez	a5,80002fe0 <usertrap+0x11a>
  usertrapret();
    80002f28:	00000097          	auipc	ra,0x0
    80002f2c:	e08080e7          	jalr	-504(ra) # 80002d30 <usertrapret>
}
    80002f30:	60e2                	ld	ra,24(sp)
    80002f32:	6442                	ld	s0,16(sp)
    80002f34:	64a2                	ld	s1,8(sp)
    80002f36:	6902                	ld	s2,0(sp)
    80002f38:	6105                	addi	sp,sp,32
    80002f3a:	8082                	ret
    panic("usertrap: not from user mode");
    80002f3c:	00005517          	auipc	a0,0x5
    80002f40:	3dc50513          	addi	a0,a0,988 # 80008318 <states.0+0x58>
    80002f44:	ffffd097          	auipc	ra,0xffffd
    80002f48:	5e6080e7          	jalr	1510(ra) # 8000052a <panic>
      exit(-1);
    80002f4c:	557d                	li	a0,-1
    80002f4e:	fffff097          	auipc	ra,0xfffff
    80002f52:	6ee080e7          	jalr	1774(ra) # 8000263c <exit>
    80002f56:	bf4d                	j	80002f08 <usertrap+0x42>
  else if ((which_dev = devintr()) != 0)
    80002f58:	00000097          	auipc	ra,0x0
    80002f5c:	ecc080e7          	jalr	-308(ra) # 80002e24 <devintr>
    80002f60:	892a                	mv	s2,a0
    80002f62:	c501                	beqz	a0,80002f6a <usertrap+0xa4>
  if (p->killed)
    80002f64:	549c                	lw	a5,40(s1)
    80002f66:	c3a1                	beqz	a5,80002fa6 <usertrap+0xe0>
    80002f68:	a815                	j	80002f9c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f6a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f6e:	5890                	lw	a2,48(s1)
    80002f70:	00005517          	auipc	a0,0x5
    80002f74:	3c850513          	addi	a0,a0,968 # 80008338 <states.0+0x78>
    80002f78:	ffffd097          	auipc	ra,0xffffd
    80002f7c:	5fc080e7          	jalr	1532(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f80:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f84:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f88:	00005517          	auipc	a0,0x5
    80002f8c:	3e050513          	addi	a0,a0,992 # 80008368 <states.0+0xa8>
    80002f90:	ffffd097          	auipc	ra,0xffffd
    80002f94:	5e4080e7          	jalr	1508(ra) # 80000574 <printf>
    p->killed = 1;
    80002f98:	4785                	li	a5,1
    80002f9a:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002f9c:	557d                	li	a0,-1
    80002f9e:	fffff097          	auipc	ra,0xfffff
    80002fa2:	69e080e7          	jalr	1694(ra) # 8000263c <exit>
  if (which_dev == 2 && ticks % QUANTUM == 0)
    80002fa6:	4789                	li	a5,2
    80002fa8:	f8f910e3          	bne	s2,a5,80002f28 <usertrap+0x62>
    80002fac:	00006797          	auipc	a5,0x6
    80002fb0:	0847a783          	lw	a5,132(a5) # 80009030 <ticks>
    80002fb4:	4715                	li	a4,5
    80002fb6:	02e7f7bb          	remuw	a5,a5,a4
    80002fba:	f7bd                	bnez	a5,80002f28 <usertrap+0x62>
    printf("process %d yielding\n", myproc()->pid);
    80002fbc:	fffff097          	auipc	ra,0xfffff
    80002fc0:	a06080e7          	jalr	-1530(ra) # 800019c2 <myproc>
    80002fc4:	590c                	lw	a1,48(a0)
    80002fc6:	00005517          	auipc	a0,0x5
    80002fca:	3c250513          	addi	a0,a0,962 # 80008388 <states.0+0xc8>
    80002fce:	ffffd097          	auipc	ra,0xffffd
    80002fd2:	5a6080e7          	jalr	1446(ra) # 80000574 <printf>
    yield();
    80002fd6:	fffff097          	auipc	ra,0xfffff
    80002fda:	3c4080e7          	jalr	964(ra) # 8000239a <yield>
    80002fde:	b7a9                	j	80002f28 <usertrap+0x62>
  int which_dev = 0;
    80002fe0:	4901                	li	s2,0
    80002fe2:	bf6d                	j	80002f9c <usertrap+0xd6>

0000000080002fe4 <kerneltrap>:
{
    80002fe4:	7179                	addi	sp,sp,-48
    80002fe6:	f406                	sd	ra,40(sp)
    80002fe8:	f022                	sd	s0,32(sp)
    80002fea:	ec26                	sd	s1,24(sp)
    80002fec:	e84a                	sd	s2,16(sp)
    80002fee:	e44e                	sd	s3,8(sp)
    80002ff0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ff2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ff6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ffa:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002ffe:	1004f793          	andi	a5,s1,256
    80003002:	cb85                	beqz	a5,80003032 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003004:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003008:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    8000300a:	ef85                	bnez	a5,80003042 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    8000300c:	00000097          	auipc	ra,0x0
    80003010:	e18080e7          	jalr	-488(ra) # 80002e24 <devintr>
    80003014:	cd1d                	beqz	a0,80003052 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && ticks % QUANTUM == 0)
    80003016:	4789                	li	a5,2
    80003018:	06f50a63          	beq	a0,a5,8000308c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000301c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003020:	10049073          	csrw	sstatus,s1
}
    80003024:	70a2                	ld	ra,40(sp)
    80003026:	7402                	ld	s0,32(sp)
    80003028:	64e2                	ld	s1,24(sp)
    8000302a:	6942                	ld	s2,16(sp)
    8000302c:	69a2                	ld	s3,8(sp)
    8000302e:	6145                	addi	sp,sp,48
    80003030:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003032:	00005517          	auipc	a0,0x5
    80003036:	36e50513          	addi	a0,a0,878 # 800083a0 <states.0+0xe0>
    8000303a:	ffffd097          	auipc	ra,0xffffd
    8000303e:	4f0080e7          	jalr	1264(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80003042:	00005517          	auipc	a0,0x5
    80003046:	38650513          	addi	a0,a0,902 # 800083c8 <states.0+0x108>
    8000304a:	ffffd097          	auipc	ra,0xffffd
    8000304e:	4e0080e7          	jalr	1248(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80003052:	85ce                	mv	a1,s3
    80003054:	00005517          	auipc	a0,0x5
    80003058:	39450513          	addi	a0,a0,916 # 800083e8 <states.0+0x128>
    8000305c:	ffffd097          	auipc	ra,0xffffd
    80003060:	518080e7          	jalr	1304(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003064:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003068:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000306c:	00005517          	auipc	a0,0x5
    80003070:	38c50513          	addi	a0,a0,908 # 800083f8 <states.0+0x138>
    80003074:	ffffd097          	auipc	ra,0xffffd
    80003078:	500080e7          	jalr	1280(ra) # 80000574 <printf>
    panic("kerneltrap");
    8000307c:	00005517          	auipc	a0,0x5
    80003080:	39450513          	addi	a0,a0,916 # 80008410 <states.0+0x150>
    80003084:	ffffd097          	auipc	ra,0xffffd
    80003088:	4a6080e7          	jalr	1190(ra) # 8000052a <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING && ticks % QUANTUM == 0)
    8000308c:	fffff097          	auipc	ra,0xfffff
    80003090:	936080e7          	jalr	-1738(ra) # 800019c2 <myproc>
    80003094:	d541                	beqz	a0,8000301c <kerneltrap+0x38>
    80003096:	fffff097          	auipc	ra,0xfffff
    8000309a:	92c080e7          	jalr	-1748(ra) # 800019c2 <myproc>
    8000309e:	4d18                	lw	a4,24(a0)
    800030a0:	4791                	li	a5,4
    800030a2:	f6f71de3          	bne	a4,a5,8000301c <kerneltrap+0x38>
    800030a6:	00006797          	auipc	a5,0x6
    800030aa:	f8a7a783          	lw	a5,-118(a5) # 80009030 <ticks>
    800030ae:	4715                	li	a4,5
    800030b0:	02e7f7bb          	remuw	a5,a5,a4
    800030b4:	f7a5                	bnez	a5,8000301c <kerneltrap+0x38>
    printf("process %d yielding\n", myproc()->pid);
    800030b6:	fffff097          	auipc	ra,0xfffff
    800030ba:	90c080e7          	jalr	-1780(ra) # 800019c2 <myproc>
    800030be:	590c                	lw	a1,48(a0)
    800030c0:	00005517          	auipc	a0,0x5
    800030c4:	2c850513          	addi	a0,a0,712 # 80008388 <states.0+0xc8>
    800030c8:	ffffd097          	auipc	ra,0xffffd
    800030cc:	4ac080e7          	jalr	1196(ra) # 80000574 <printf>
    yield();
    800030d0:	fffff097          	auipc	ra,0xfffff
    800030d4:	2ca080e7          	jalr	714(ra) # 8000239a <yield>
    800030d8:	b791                	j	8000301c <kerneltrap+0x38>

00000000800030da <argraw>:
	return strlen(buf);
}

static uint64
argraw(int n)
{
    800030da:	1101                	addi	sp,sp,-32
    800030dc:	ec06                	sd	ra,24(sp)
    800030de:	e822                	sd	s0,16(sp)
    800030e0:	e426                	sd	s1,8(sp)
    800030e2:	1000                	addi	s0,sp,32
    800030e4:	84aa                	mv	s1,a0
	struct proc *p = myproc();
    800030e6:	fffff097          	auipc	ra,0xfffff
    800030ea:	8dc080e7          	jalr	-1828(ra) # 800019c2 <myproc>
	switch (n)
    800030ee:	4795                	li	a5,5
    800030f0:	0497e163          	bltu	a5,s1,80003132 <argraw+0x58>
    800030f4:	048a                	slli	s1,s1,0x2
    800030f6:	00005717          	auipc	a4,0x5
    800030fa:	47a70713          	addi	a4,a4,1146 # 80008570 <states.0+0x2b0>
    800030fe:	94ba                	add	s1,s1,a4
    80003100:	409c                	lw	a5,0(s1)
    80003102:	97ba                	add	a5,a5,a4
    80003104:	8782                	jr	a5
	{
	case 0:
		return p->trapframe->a0;
    80003106:	615c                	ld	a5,128(a0)
    80003108:	7ba8                	ld	a0,112(a5)
	case 5:
		return p->trapframe->a5;
	}
	panic("argraw");
	return -1;
}
    8000310a:	60e2                	ld	ra,24(sp)
    8000310c:	6442                	ld	s0,16(sp)
    8000310e:	64a2                	ld	s1,8(sp)
    80003110:	6105                	addi	sp,sp,32
    80003112:	8082                	ret
		return p->trapframe->a1;
    80003114:	615c                	ld	a5,128(a0)
    80003116:	7fa8                	ld	a0,120(a5)
    80003118:	bfcd                	j	8000310a <argraw+0x30>
		return p->trapframe->a2;
    8000311a:	615c                	ld	a5,128(a0)
    8000311c:	63c8                	ld	a0,128(a5)
    8000311e:	b7f5                	j	8000310a <argraw+0x30>
		return p->trapframe->a3;
    80003120:	615c                	ld	a5,128(a0)
    80003122:	67c8                	ld	a0,136(a5)
    80003124:	b7dd                	j	8000310a <argraw+0x30>
		return p->trapframe->a4;
    80003126:	615c                	ld	a5,128(a0)
    80003128:	6bc8                	ld	a0,144(a5)
    8000312a:	b7c5                	j	8000310a <argraw+0x30>
		return p->trapframe->a5;
    8000312c:	615c                	ld	a5,128(a0)
    8000312e:	6fc8                	ld	a0,152(a5)
    80003130:	bfe9                	j	8000310a <argraw+0x30>
	panic("argraw");
    80003132:	00005517          	auipc	a0,0x5
    80003136:	2ee50513          	addi	a0,a0,750 # 80008420 <states.0+0x160>
    8000313a:	ffffd097          	auipc	ra,0xffffd
    8000313e:	3f0080e7          	jalr	1008(ra) # 8000052a <panic>

0000000080003142 <fetchaddr>:
{
    80003142:	1101                	addi	sp,sp,-32
    80003144:	ec06                	sd	ra,24(sp)
    80003146:	e822                	sd	s0,16(sp)
    80003148:	e426                	sd	s1,8(sp)
    8000314a:	e04a                	sd	s2,0(sp)
    8000314c:	1000                	addi	s0,sp,32
    8000314e:	84aa                	mv	s1,a0
    80003150:	892e                	mv	s2,a1
	struct proc *p = myproc();
    80003152:	fffff097          	auipc	ra,0xfffff
    80003156:	870080e7          	jalr	-1936(ra) # 800019c2 <myproc>
	if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    8000315a:	793c                	ld	a5,112(a0)
    8000315c:	02f4f863          	bgeu	s1,a5,8000318c <fetchaddr+0x4a>
    80003160:	00848713          	addi	a4,s1,8
    80003164:	02e7e663          	bltu	a5,a4,80003190 <fetchaddr+0x4e>
	if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003168:	46a1                	li	a3,8
    8000316a:	8626                	mv	a2,s1
    8000316c:	85ca                	mv	a1,s2
    8000316e:	7d28                	ld	a0,120(a0)
    80003170:	ffffe097          	auipc	ra,0xffffe
    80003174:	55a080e7          	jalr	1370(ra) # 800016ca <copyin>
    80003178:	00a03533          	snez	a0,a0
    8000317c:	40a00533          	neg	a0,a0
}
    80003180:	60e2                	ld	ra,24(sp)
    80003182:	6442                	ld	s0,16(sp)
    80003184:	64a2                	ld	s1,8(sp)
    80003186:	6902                	ld	s2,0(sp)
    80003188:	6105                	addi	sp,sp,32
    8000318a:	8082                	ret
		return -1;
    8000318c:	557d                	li	a0,-1
    8000318e:	bfcd                	j	80003180 <fetchaddr+0x3e>
    80003190:	557d                	li	a0,-1
    80003192:	b7fd                	j	80003180 <fetchaddr+0x3e>

0000000080003194 <fetchstr>:
{
    80003194:	7179                	addi	sp,sp,-48
    80003196:	f406                	sd	ra,40(sp)
    80003198:	f022                	sd	s0,32(sp)
    8000319a:	ec26                	sd	s1,24(sp)
    8000319c:	e84a                	sd	s2,16(sp)
    8000319e:	e44e                	sd	s3,8(sp)
    800031a0:	1800                	addi	s0,sp,48
    800031a2:	892a                	mv	s2,a0
    800031a4:	84ae                	mv	s1,a1
    800031a6:	89b2                	mv	s3,a2
	struct proc *p = myproc();
    800031a8:	fffff097          	auipc	ra,0xfffff
    800031ac:	81a080e7          	jalr	-2022(ra) # 800019c2 <myproc>
	int err = copyinstr(p->pagetable, buf, addr, max);
    800031b0:	86ce                	mv	a3,s3
    800031b2:	864a                	mv	a2,s2
    800031b4:	85a6                	mv	a1,s1
    800031b6:	7d28                	ld	a0,120(a0)
    800031b8:	ffffe097          	auipc	ra,0xffffe
    800031bc:	5a0080e7          	jalr	1440(ra) # 80001758 <copyinstr>
	if (err < 0)
    800031c0:	00054763          	bltz	a0,800031ce <fetchstr+0x3a>
	return strlen(buf);
    800031c4:	8526                	mv	a0,s1
    800031c6:	ffffe097          	auipc	ra,0xffffe
    800031ca:	c7c080e7          	jalr	-900(ra) # 80000e42 <strlen>
}
    800031ce:	70a2                	ld	ra,40(sp)
    800031d0:	7402                	ld	s0,32(sp)
    800031d2:	64e2                	ld	s1,24(sp)
    800031d4:	6942                	ld	s2,16(sp)
    800031d6:	69a2                	ld	s3,8(sp)
    800031d8:	6145                	addi	sp,sp,48
    800031da:	8082                	ret

00000000800031dc <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    800031dc:	1101                	addi	sp,sp,-32
    800031de:	ec06                	sd	ra,24(sp)
    800031e0:	e822                	sd	s0,16(sp)
    800031e2:	e426                	sd	s1,8(sp)
    800031e4:	1000                	addi	s0,sp,32
    800031e6:	84ae                	mv	s1,a1
	*ip = argraw(n);
    800031e8:	00000097          	auipc	ra,0x0
    800031ec:	ef2080e7          	jalr	-270(ra) # 800030da <argraw>
    800031f0:	c088                	sw	a0,0(s1)
	return 0;
}
    800031f2:	4501                	li	a0,0
    800031f4:	60e2                	ld	ra,24(sp)
    800031f6:	6442                	ld	s0,16(sp)
    800031f8:	64a2                	ld	s1,8(sp)
    800031fa:	6105                	addi	sp,sp,32
    800031fc:	8082                	ret

00000000800031fe <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    800031fe:	1101                	addi	sp,sp,-32
    80003200:	ec06                	sd	ra,24(sp)
    80003202:	e822                	sd	s0,16(sp)
    80003204:	e426                	sd	s1,8(sp)
    80003206:	1000                	addi	s0,sp,32
    80003208:	84ae                	mv	s1,a1
	*ip = argraw(n);
    8000320a:	00000097          	auipc	ra,0x0
    8000320e:	ed0080e7          	jalr	-304(ra) # 800030da <argraw>
    80003212:	e088                	sd	a0,0(s1)
	return 0;
}
    80003214:	4501                	li	a0,0
    80003216:	60e2                	ld	ra,24(sp)
    80003218:	6442                	ld	s0,16(sp)
    8000321a:	64a2                	ld	s1,8(sp)
    8000321c:	6105                	addi	sp,sp,32
    8000321e:	8082                	ret

0000000080003220 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80003220:	1101                	addi	sp,sp,-32
    80003222:	ec06                	sd	ra,24(sp)
    80003224:	e822                	sd	s0,16(sp)
    80003226:	e426                	sd	s1,8(sp)
    80003228:	e04a                	sd	s2,0(sp)
    8000322a:	1000                	addi	s0,sp,32
    8000322c:	84ae                	mv	s1,a1
    8000322e:	8932                	mv	s2,a2
	*ip = argraw(n);
    80003230:	00000097          	auipc	ra,0x0
    80003234:	eaa080e7          	jalr	-342(ra) # 800030da <argraw>
	uint64 addr;
	if (argaddr(n, &addr) < 0)
		return -1;
	return fetchstr(addr, buf, max);
    80003238:	864a                	mv	a2,s2
    8000323a:	85a6                	mv	a1,s1
    8000323c:	00000097          	auipc	ra,0x0
    80003240:	f58080e7          	jalr	-168(ra) # 80003194 <fetchstr>
}
    80003244:	60e2                	ld	ra,24(sp)
    80003246:	6442                	ld	s0,16(sp)
    80003248:	64a2                	ld	s1,8(sp)
    8000324a:	6902                	ld	s2,0(sp)
    8000324c:	6105                	addi	sp,sp,32
    8000324e:	8082                	ret

0000000080003250 <print_trace>:
	}
}

// ADDED
void print_trace(int arg)
{
    80003250:	7179                	addi	sp,sp,-48
    80003252:	f406                	sd	ra,40(sp)
    80003254:	f022                	sd	s0,32(sp)
    80003256:	ec26                	sd	s1,24(sp)
    80003258:	e84a                	sd	s2,16(sp)
    8000325a:	e44e                	sd	s3,8(sp)
    8000325c:	1800                	addi	s0,sp,48
    8000325e:	89aa                	mv	s3,a0
	int num;
	struct proc *p = myproc();
    80003260:	ffffe097          	auipc	ra,0xffffe
    80003264:	762080e7          	jalr	1890(ra) # 800019c2 <myproc>
	num = p->trapframe->a7;
    80003268:	615c                	ld	a5,128(a0)
    8000326a:	0a87a903          	lw	s2,168(a5)

	int res = (1 << num) & p->trace_mask;
    8000326e:	4785                	li	a5,1
    80003270:	012797bb          	sllw	a5,a5,s2
    80003274:	5958                	lw	a4,52(a0)
    80003276:	8ff9                	and	a5,a5,a4
	if (res != 0)
    80003278:	2781                	sext.w	a5,a5
    8000327a:	eb81                	bnez	a5,8000328a <print_trace+0x3a>
		else
		{
			printf("syscall %s  -> %d\n", syscallnames[num], p->trapframe->a0);
		}
	}
} // ADDED
    8000327c:	70a2                	ld	ra,40(sp)
    8000327e:	7402                	ld	s0,32(sp)
    80003280:	64e2                	ld	s1,24(sp)
    80003282:	6942                	ld	s2,16(sp)
    80003284:	69a2                	ld	s3,8(sp)
    80003286:	6145                	addi	sp,sp,48
    80003288:	8082                	ret
    8000328a:	84aa                	mv	s1,a0
		printf("%d: ", p->pid);
    8000328c:	590c                	lw	a1,48(a0)
    8000328e:	00005517          	auipc	a0,0x5
    80003292:	19a50513          	addi	a0,a0,410 # 80008428 <states.0+0x168>
    80003296:	ffffd097          	auipc	ra,0xffffd
    8000329a:	2de080e7          	jalr	734(ra) # 80000574 <printf>
		if (num == SYS_fork)
    8000329e:	4785                	li	a5,1
    800032a0:	02f90c63          	beq	s2,a5,800032d8 <print_trace+0x88>
		else if (num == SYS_kill || num == SYS_sbrk)
    800032a4:	4799                	li	a5,6
    800032a6:	00f90563          	beq	s2,a5,800032b0 <print_trace+0x60>
    800032aa:	47b1                	li	a5,12
    800032ac:	04f91563          	bne	s2,a5,800032f6 <print_trace+0xa6>
			printf("syscall %s %d -> %d\n", syscallnames[num], arg, p->trapframe->a0);
    800032b0:	60d8                	ld	a4,128(s1)
    800032b2:	090e                	slli	s2,s2,0x3
    800032b4:	00005797          	auipc	a5,0x5
    800032b8:	2d478793          	addi	a5,a5,724 # 80008588 <syscallnames>
    800032bc:	993e                	add	s2,s2,a5
    800032be:	7b34                	ld	a3,112(a4)
    800032c0:	864e                	mv	a2,s3
    800032c2:	00093583          	ld	a1,0(s2)
    800032c6:	00005517          	auipc	a0,0x5
    800032ca:	18a50513          	addi	a0,a0,394 # 80008450 <states.0+0x190>
    800032ce:	ffffd097          	auipc	ra,0xffffd
    800032d2:	2a6080e7          	jalr	678(ra) # 80000574 <printf>
    800032d6:	b75d                	j	8000327c <print_trace+0x2c>
			printf("syscall %s NULL -> %d\n", syscallnames[num], p->trapframe->a0);
    800032d8:	60dc                	ld	a5,128(s1)
    800032da:	7bb0                	ld	a2,112(a5)
    800032dc:	00005597          	auipc	a1,0x5
    800032e0:	15458593          	addi	a1,a1,340 # 80008430 <states.0+0x170>
    800032e4:	00005517          	auipc	a0,0x5
    800032e8:	15450513          	addi	a0,a0,340 # 80008438 <states.0+0x178>
    800032ec:	ffffd097          	auipc	ra,0xffffd
    800032f0:	288080e7          	jalr	648(ra) # 80000574 <printf>
    800032f4:	b761                	j	8000327c <print_trace+0x2c>
			printf("syscall %s  -> %d\n", syscallnames[num], p->trapframe->a0);
    800032f6:	60d8                	ld	a4,128(s1)
    800032f8:	090e                	slli	s2,s2,0x3
    800032fa:	00005797          	auipc	a5,0x5
    800032fe:	28e78793          	addi	a5,a5,654 # 80008588 <syscallnames>
    80003302:	993e                	add	s2,s2,a5
    80003304:	7b30                	ld	a2,112(a4)
    80003306:	00093583          	ld	a1,0(s2)
    8000330a:	00005517          	auipc	a0,0x5
    8000330e:	15e50513          	addi	a0,a0,350 # 80008468 <states.0+0x1a8>
    80003312:	ffffd097          	auipc	ra,0xffffd
    80003316:	262080e7          	jalr	610(ra) # 80000574 <printf>
} // ADDED
    8000331a:	b78d                	j	8000327c <print_trace+0x2c>

000000008000331c <syscall>:
{
    8000331c:	7179                	addi	sp,sp,-48
    8000331e:	f406                	sd	ra,40(sp)
    80003320:	f022                	sd	s0,32(sp)
    80003322:	ec26                	sd	s1,24(sp)
    80003324:	e84a                	sd	s2,16(sp)
    80003326:	1800                	addi	s0,sp,48
	struct proc *p = myproc();
    80003328:	ffffe097          	auipc	ra,0xffffe
    8000332c:	69a080e7          	jalr	1690(ra) # 800019c2 <myproc>
    80003330:	84aa                	mv	s1,a0
	num = p->trapframe->a7;
    80003332:	615c                	ld	a5,128(a0)
    80003334:	77dc                	ld	a5,168(a5)
    80003336:	0007869b          	sext.w	a3,a5
	if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    8000333a:	37fd                	addiw	a5,a5,-1
    8000333c:	4761                	li	a4,24
    8000333e:	02f76e63          	bltu	a4,a5,8000337a <syscall+0x5e>
    80003342:	00369713          	slli	a4,a3,0x3
    80003346:	00005797          	auipc	a5,0x5
    8000334a:	24278793          	addi	a5,a5,578 # 80008588 <syscallnames>
    8000334e:	97ba                	add	a5,a5,a4
    80003350:	0d07b903          	ld	s2,208(a5)
    80003354:	02090363          	beqz	s2,8000337a <syscall+0x5e>
		argint(0, &arg); // ADDED
    80003358:	fdc40593          	addi	a1,s0,-36
    8000335c:	4501                	li	a0,0
    8000335e:	00000097          	auipc	ra,0x0
    80003362:	e7e080e7          	jalr	-386(ra) # 800031dc <argint>
		p->trapframe->a0 = syscalls[num]();
    80003366:	60c4                	ld	s1,128(s1)
    80003368:	9902                	jalr	s2
    8000336a:	f8a8                	sd	a0,112(s1)
		print_trace(arg); // ADDED
    8000336c:	fdc42503          	lw	a0,-36(s0)
    80003370:	00000097          	auipc	ra,0x0
    80003374:	ee0080e7          	jalr	-288(ra) # 80003250 <print_trace>
    80003378:	a839                	j	80003396 <syscall+0x7a>
		printf("%d %s: unknown sys call %d\n",
    8000337a:	18048613          	addi	a2,s1,384
    8000337e:	588c                	lw	a1,48(s1)
    80003380:	00005517          	auipc	a0,0x5
    80003384:	10050513          	addi	a0,a0,256 # 80008480 <states.0+0x1c0>
    80003388:	ffffd097          	auipc	ra,0xffffd
    8000338c:	1ec080e7          	jalr	492(ra) # 80000574 <printf>
		p->trapframe->a0 = -1;
    80003390:	60dc                	ld	a5,128(s1)
    80003392:	577d                	li	a4,-1
    80003394:	fbb8                	sd	a4,112(a5)
}
    80003396:	70a2                	ld	ra,40(sp)
    80003398:	7402                	ld	s0,32(sp)
    8000339a:	64e2                	ld	s1,24(sp)
    8000339c:	6942                	ld	s2,16(sp)
    8000339e:	6145                	addi	sp,sp,48
    800033a0:	8082                	ret

00000000800033a2 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800033a2:	1101                	addi	sp,sp,-32
    800033a4:	ec06                	sd	ra,24(sp)
    800033a6:	e822                	sd	s0,16(sp)
    800033a8:	1000                	addi	s0,sp,32
  int n;
  if (argint(0, &n) < 0)
    800033aa:	fec40593          	addi	a1,s0,-20
    800033ae:	4501                	li	a0,0
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	e2c080e7          	jalr	-468(ra) # 800031dc <argint>
    return -1;
    800033b8:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    800033ba:	00054963          	bltz	a0,800033cc <sys_exit+0x2a>
  exit(n);
    800033be:	fec42503          	lw	a0,-20(s0)
    800033c2:	fffff097          	auipc	ra,0xfffff
    800033c6:	27a080e7          	jalr	634(ra) # 8000263c <exit>
  return 0; // not reached
    800033ca:	4781                	li	a5,0
}
    800033cc:	853e                	mv	a0,a5
    800033ce:	60e2                	ld	ra,24(sp)
    800033d0:	6442                	ld	s0,16(sp)
    800033d2:	6105                	addi	sp,sp,32
    800033d4:	8082                	ret

00000000800033d6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800033d6:	1141                	addi	sp,sp,-16
    800033d8:	e406                	sd	ra,8(sp)
    800033da:	e022                	sd	s0,0(sp)
    800033dc:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800033de:	ffffe097          	auipc	ra,0xffffe
    800033e2:	5e4080e7          	jalr	1508(ra) # 800019c2 <myproc>
}
    800033e6:	5908                	lw	a0,48(a0)
    800033e8:	60a2                	ld	ra,8(sp)
    800033ea:	6402                	ld	s0,0(sp)
    800033ec:	0141                	addi	sp,sp,16
    800033ee:	8082                	ret

00000000800033f0 <sys_fork>:

uint64
sys_fork(void)
{
    800033f0:	1141                	addi	sp,sp,-16
    800033f2:	e406                	sd	ra,8(sp)
    800033f4:	e022                	sd	s0,0(sp)
    800033f6:	0800                	addi	s0,sp,16
  return fork();
    800033f8:	fffff097          	auipc	ra,0xfffff
    800033fc:	9ba080e7          	jalr	-1606(ra) # 80001db2 <fork>
}
    80003400:	60a2                	ld	ra,8(sp)
    80003402:	6402                	ld	s0,0(sp)
    80003404:	0141                	addi	sp,sp,16
    80003406:	8082                	ret

0000000080003408 <sys_wait>:

uint64
sys_wait(void)
{
    80003408:	1101                	addi	sp,sp,-32
    8000340a:	ec06                	sd	ra,24(sp)
    8000340c:	e822                	sd	s0,16(sp)
    8000340e:	1000                	addi	s0,sp,32
  uint64 p;
  if (argaddr(0, &p) < 0)
    80003410:	fe840593          	addi	a1,s0,-24
    80003414:	4501                	li	a0,0
    80003416:	00000097          	auipc	ra,0x0
    8000341a:	de8080e7          	jalr	-536(ra) # 800031fe <argaddr>
    8000341e:	87aa                	mv	a5,a0
    return -1;
    80003420:	557d                	li	a0,-1
  if (argaddr(0, &p) < 0)
    80003422:	0007c863          	bltz	a5,80003432 <sys_wait+0x2a>
  return wait(p);
    80003426:	fe843503          	ld	a0,-24(s0)
    8000342a:	fffff097          	auipc	ra,0xfffff
    8000342e:	010080e7          	jalr	16(ra) # 8000243a <wait>
}
    80003432:	60e2                	ld	ra,24(sp)
    80003434:	6442                	ld	s0,16(sp)
    80003436:	6105                	addi	sp,sp,32
    80003438:	8082                	ret

000000008000343a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000343a:	7179                	addi	sp,sp,-48
    8000343c:	f406                	sd	ra,40(sp)
    8000343e:	f022                	sd	s0,32(sp)
    80003440:	ec26                	sd	s1,24(sp)
    80003442:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if (argint(0, &n) < 0)
    80003444:	fdc40593          	addi	a1,s0,-36
    80003448:	4501                	li	a0,0
    8000344a:	00000097          	auipc	ra,0x0
    8000344e:	d92080e7          	jalr	-622(ra) # 800031dc <argint>
    return -1;
    80003452:	54fd                	li	s1,-1
  if (argint(0, &n) < 0)
    80003454:	00054f63          	bltz	a0,80003472 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80003458:	ffffe097          	auipc	ra,0xffffe
    8000345c:	56a080e7          	jalr	1386(ra) # 800019c2 <myproc>
    80003460:	5924                	lw	s1,112(a0)
  if (growproc(n) < 0)
    80003462:	fdc42503          	lw	a0,-36(s0)
    80003466:	fffff097          	auipc	ra,0xfffff
    8000346a:	8d8080e7          	jalr	-1832(ra) # 80001d3e <growproc>
    8000346e:	00054863          	bltz	a0,8000347e <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80003472:	8526                	mv	a0,s1
    80003474:	70a2                	ld	ra,40(sp)
    80003476:	7402                	ld	s0,32(sp)
    80003478:	64e2                	ld	s1,24(sp)
    8000347a:	6145                	addi	sp,sp,48
    8000347c:	8082                	ret
    return -1;
    8000347e:	54fd                	li	s1,-1
    80003480:	bfcd                	j	80003472 <sys_sbrk+0x38>

0000000080003482 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003482:	7139                	addi	sp,sp,-64
    80003484:	fc06                	sd	ra,56(sp)
    80003486:	f822                	sd	s0,48(sp)
    80003488:	f426                	sd	s1,40(sp)
    8000348a:	f04a                	sd	s2,32(sp)
    8000348c:	ec4e                	sd	s3,24(sp)
    8000348e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if (argint(0, &n) < 0)
    80003490:	fcc40593          	addi	a1,s0,-52
    80003494:	4501                	li	a0,0
    80003496:	00000097          	auipc	ra,0x0
    8000349a:	d46080e7          	jalr	-698(ra) # 800031dc <argint>
    return -1;
    8000349e:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    800034a0:	06054563          	bltz	a0,8000350a <sys_sleep+0x88>
  acquire(&tickslock);
    800034a4:	00014517          	auipc	a0,0x14
    800034a8:	64450513          	addi	a0,a0,1604 # 80017ae8 <tickslock>
    800034ac:	ffffd097          	auipc	ra,0xffffd
    800034b0:	716080e7          	jalr	1814(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    800034b4:	00006917          	auipc	s2,0x6
    800034b8:	b7c92903          	lw	s2,-1156(s2) # 80009030 <ticks>
  while (ticks - ticks0 < n)
    800034bc:	fcc42783          	lw	a5,-52(s0)
    800034c0:	cf85                	beqz	a5,800034f8 <sys_sleep+0x76>
    if (myproc()->killed)
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800034c2:	00014997          	auipc	s3,0x14
    800034c6:	62698993          	addi	s3,s3,1574 # 80017ae8 <tickslock>
    800034ca:	00006497          	auipc	s1,0x6
    800034ce:	b6648493          	addi	s1,s1,-1178 # 80009030 <ticks>
    if (myproc()->killed)
    800034d2:	ffffe097          	auipc	ra,0xffffe
    800034d6:	4f0080e7          	jalr	1264(ra) # 800019c2 <myproc>
    800034da:	551c                	lw	a5,40(a0)
    800034dc:	ef9d                	bnez	a5,8000351a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800034de:	85ce                	mv	a1,s3
    800034e0:	8526                	mv	a0,s1
    800034e2:	fffff097          	auipc	ra,0xfffff
    800034e6:	ef4080e7          	jalr	-268(ra) # 800023d6 <sleep>
  while (ticks - ticks0 < n)
    800034ea:	409c                	lw	a5,0(s1)
    800034ec:	412787bb          	subw	a5,a5,s2
    800034f0:	fcc42703          	lw	a4,-52(s0)
    800034f4:	fce7efe3          	bltu	a5,a4,800034d2 <sys_sleep+0x50>
  }
  release(&tickslock);
    800034f8:	00014517          	auipc	a0,0x14
    800034fc:	5f050513          	addi	a0,a0,1520 # 80017ae8 <tickslock>
    80003500:	ffffd097          	auipc	ra,0xffffd
    80003504:	776080e7          	jalr	1910(ra) # 80000c76 <release>
  return 0;
    80003508:	4781                	li	a5,0
}
    8000350a:	853e                	mv	a0,a5
    8000350c:	70e2                	ld	ra,56(sp)
    8000350e:	7442                	ld	s0,48(sp)
    80003510:	74a2                	ld	s1,40(sp)
    80003512:	7902                	ld	s2,32(sp)
    80003514:	69e2                	ld	s3,24(sp)
    80003516:	6121                	addi	sp,sp,64
    80003518:	8082                	ret
      release(&tickslock);
    8000351a:	00014517          	auipc	a0,0x14
    8000351e:	5ce50513          	addi	a0,a0,1486 # 80017ae8 <tickslock>
    80003522:	ffffd097          	auipc	ra,0xffffd
    80003526:	754080e7          	jalr	1876(ra) # 80000c76 <release>
      return -1;
    8000352a:	57fd                	li	a5,-1
    8000352c:	bff9                	j	8000350a <sys_sleep+0x88>

000000008000352e <sys_kill>:

uint64
sys_kill(void)
{
    8000352e:	1101                	addi	sp,sp,-32
    80003530:	ec06                	sd	ra,24(sp)
    80003532:	e822                	sd	s0,16(sp)
    80003534:	1000                	addi	s0,sp,32
  int pid;

  if (argint(0, &pid) < 0)
    80003536:	fec40593          	addi	a1,s0,-20
    8000353a:	4501                	li	a0,0
    8000353c:	00000097          	auipc	ra,0x0
    80003540:	ca0080e7          	jalr	-864(ra) # 800031dc <argint>
    80003544:	87aa                	mv	a5,a0
    return -1;
    80003546:	557d                	li	a0,-1
  if (argint(0, &pid) < 0)
    80003548:	0007c863          	bltz	a5,80003558 <sys_kill+0x2a>
  return kill(pid);
    8000354c:	fec42503          	lw	a0,-20(s0)
    80003550:	fffff097          	auipc	ra,0xfffff
    80003554:	1c2080e7          	jalr	450(ra) # 80002712 <kill>
}
    80003558:	60e2                	ld	ra,24(sp)
    8000355a:	6442                	ld	s0,16(sp)
    8000355c:	6105                	addi	sp,sp,32
    8000355e:	8082                	ret

0000000080003560 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003560:	1101                	addi	sp,sp,-32
    80003562:	ec06                	sd	ra,24(sp)
    80003564:	e822                	sd	s0,16(sp)
    80003566:	e426                	sd	s1,8(sp)
    80003568:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000356a:	00014517          	auipc	a0,0x14
    8000356e:	57e50513          	addi	a0,a0,1406 # 80017ae8 <tickslock>
    80003572:	ffffd097          	auipc	ra,0xffffd
    80003576:	650080e7          	jalr	1616(ra) # 80000bc2 <acquire>
  xticks = ticks;
    8000357a:	00006497          	auipc	s1,0x6
    8000357e:	ab64a483          	lw	s1,-1354(s1) # 80009030 <ticks>
  release(&tickslock);
    80003582:	00014517          	auipc	a0,0x14
    80003586:	56650513          	addi	a0,a0,1382 # 80017ae8 <tickslock>
    8000358a:	ffffd097          	auipc	ra,0xffffd
    8000358e:	6ec080e7          	jalr	1772(ra) # 80000c76 <release>
  return xticks;
}
    80003592:	02049513          	slli	a0,s1,0x20
    80003596:	9101                	srli	a0,a0,0x20
    80003598:	60e2                	ld	ra,24(sp)
    8000359a:	6442                	ld	s0,16(sp)
    8000359c:	64a2                	ld	s1,8(sp)
    8000359e:	6105                	addi	sp,sp,32
    800035a0:	8082                	ret

00000000800035a2 <sys_trace>:

//ADDED: sys_
uint64
sys_trace(void)
{
    800035a2:	1101                	addi	sp,sp,-32
    800035a4:	ec06                	sd	ra,24(sp)
    800035a6:	e822                	sd	s0,16(sp)
    800035a8:	1000                	addi	s0,sp,32
  int mask, pid;
  argint(0, &mask);
    800035aa:	fec40593          	addi	a1,s0,-20
    800035ae:	4501                	li	a0,0
    800035b0:	00000097          	auipc	ra,0x0
    800035b4:	c2c080e7          	jalr	-980(ra) # 800031dc <argint>
  argint(1, &pid);
    800035b8:	fe840593          	addi	a1,s0,-24
    800035bc:	4505                	li	a0,1
    800035be:	00000097          	auipc	ra,0x0
    800035c2:	c1e080e7          	jalr	-994(ra) # 800031dc <argint>
  return trace(mask, pid);
    800035c6:	fe842583          	lw	a1,-24(s0)
    800035ca:	fec42503          	lw	a0,-20(s0)
    800035ce:	fffff097          	auipc	ra,0xfffff
    800035d2:	312080e7          	jalr	786(ra) # 800028e0 <trace>
}
    800035d6:	60e2                	ld	ra,24(sp)
    800035d8:	6442                	ld	s0,16(sp)
    800035da:	6105                	addi	sp,sp,32
    800035dc:	8082                	ret

00000000800035de <sys_getmsk>:

uint64
sys_getmsk(void)
{
    800035de:	1101                	addi	sp,sp,-32
    800035e0:	ec06                	sd	ra,24(sp)
    800035e2:	e822                	sd	s0,16(sp)
    800035e4:	1000                	addi	s0,sp,32
  int pid;
  argint(0, &pid);
    800035e6:	fec40593          	addi	a1,s0,-20
    800035ea:	4501                	li	a0,0
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	bf0080e7          	jalr	-1040(ra) # 800031dc <argint>
  return getmsk(pid);
    800035f4:	fec42503          	lw	a0,-20(s0)
    800035f8:	fffff097          	auipc	ra,0xfffff
    800035fc:	352080e7          	jalr	850(ra) # 8000294a <getmsk>
}
    80003600:	60e2                	ld	ra,24(sp)
    80003602:	6442                	ld	s0,16(sp)
    80003604:	6105                	addi	sp,sp,32
    80003606:	8082                	ret

0000000080003608 <sys_wait_stat>:

uint64
sys_wait_stat(void)
{
    80003608:	1101                	addi	sp,sp,-32
    8000360a:	ec06                	sd	ra,24(sp)
    8000360c:	e822                	sd	s0,16(sp)
    8000360e:	1000                	addi	s0,sp,32
  uint64 status;
  uint64 performance;
  argaddr(0,  &status);
    80003610:	fe840593          	addi	a1,s0,-24
    80003614:	4501                	li	a0,0
    80003616:	00000097          	auipc	ra,0x0
    8000361a:	be8080e7          	jalr	-1048(ra) # 800031fe <argaddr>
  argaddr(1,  &performance);
    8000361e:	fe040593          	addi	a1,s0,-32
    80003622:	4505                	li	a0,1
    80003624:	00000097          	auipc	ra,0x0
    80003628:	bda080e7          	jalr	-1062(ra) # 800031fe <argaddr>
  return wait_stat(status, performance);
    8000362c:	fe043583          	ld	a1,-32(s0)
    80003630:	fe843503          	ld	a0,-24(s0)
    80003634:	fffff097          	auipc	ra,0xfffff
    80003638:	456080e7          	jalr	1110(ra) # 80002a8a <wait_stat>
}
    8000363c:	60e2                	ld	ra,24(sp)
    8000363e:	6442                	ld	s0,16(sp)
    80003640:	6105                	addi	sp,sp,32
    80003642:	8082                	ret

0000000080003644 <sys_set_priority>:

uint64
sys_set_priority(void)
{
    80003644:	1101                	addi	sp,sp,-32
    80003646:	ec06                	sd	ra,24(sp)
    80003648:	e822                	sd	s0,16(sp)
    8000364a:	1000                	addi	s0,sp,32
  int priority;
  argint(0, &priority);
    8000364c:	fec40593          	addi	a1,s0,-20
    80003650:	4501                	li	a0,0
    80003652:	00000097          	auipc	ra,0x0
    80003656:	b8a080e7          	jalr	-1142(ra) # 800031dc <argint>
  return set_priority(priority);
    8000365a:	fec42503          	lw	a0,-20(s0)
    8000365e:	fffff097          	auipc	ra,0xfffff
    80003662:	5f8080e7          	jalr	1528(ra) # 80002c56 <set_priority>
}
    80003666:	60e2                	ld	ra,24(sp)
    80003668:	6442                	ld	s0,16(sp)
    8000366a:	6105                	addi	sp,sp,32
    8000366c:	8082                	ret

000000008000366e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000366e:	7179                	addi	sp,sp,-48
    80003670:	f406                	sd	ra,40(sp)
    80003672:	f022                	sd	s0,32(sp)
    80003674:	ec26                	sd	s1,24(sp)
    80003676:	e84a                	sd	s2,16(sp)
    80003678:	e44e                	sd	s3,8(sp)
    8000367a:	e052                	sd	s4,0(sp)
    8000367c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000367e:	00005597          	auipc	a1,0x5
    80003682:	0aa58593          	addi	a1,a1,170 # 80008728 <syscalls+0xd0>
    80003686:	00014517          	auipc	a0,0x14
    8000368a:	47a50513          	addi	a0,a0,1146 # 80017b00 <bcache>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	4a4080e7          	jalr	1188(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003696:	0001c797          	auipc	a5,0x1c
    8000369a:	46a78793          	addi	a5,a5,1130 # 8001fb00 <bcache+0x8000>
    8000369e:	0001c717          	auipc	a4,0x1c
    800036a2:	6ca70713          	addi	a4,a4,1738 # 8001fd68 <bcache+0x8268>
    800036a6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800036aa:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036ae:	00014497          	auipc	s1,0x14
    800036b2:	46a48493          	addi	s1,s1,1130 # 80017b18 <bcache+0x18>
    b->next = bcache.head.next;
    800036b6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800036b8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800036ba:	00005a17          	auipc	s4,0x5
    800036be:	076a0a13          	addi	s4,s4,118 # 80008730 <syscalls+0xd8>
    b->next = bcache.head.next;
    800036c2:	2b893783          	ld	a5,696(s2)
    800036c6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800036c8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800036cc:	85d2                	mv	a1,s4
    800036ce:	01048513          	addi	a0,s1,16
    800036d2:	00001097          	auipc	ra,0x1
    800036d6:	4c2080e7          	jalr	1218(ra) # 80004b94 <initsleeplock>
    bcache.head.next->prev = b;
    800036da:	2b893783          	ld	a5,696(s2)
    800036de:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800036e0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036e4:	45848493          	addi	s1,s1,1112
    800036e8:	fd349de3          	bne	s1,s3,800036c2 <binit+0x54>
  }
}
    800036ec:	70a2                	ld	ra,40(sp)
    800036ee:	7402                	ld	s0,32(sp)
    800036f0:	64e2                	ld	s1,24(sp)
    800036f2:	6942                	ld	s2,16(sp)
    800036f4:	69a2                	ld	s3,8(sp)
    800036f6:	6a02                	ld	s4,0(sp)
    800036f8:	6145                	addi	sp,sp,48
    800036fa:	8082                	ret

00000000800036fc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800036fc:	7179                	addi	sp,sp,-48
    800036fe:	f406                	sd	ra,40(sp)
    80003700:	f022                	sd	s0,32(sp)
    80003702:	ec26                	sd	s1,24(sp)
    80003704:	e84a                	sd	s2,16(sp)
    80003706:	e44e                	sd	s3,8(sp)
    80003708:	1800                	addi	s0,sp,48
    8000370a:	892a                	mv	s2,a0
    8000370c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000370e:	00014517          	auipc	a0,0x14
    80003712:	3f250513          	addi	a0,a0,1010 # 80017b00 <bcache>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	4ac080e7          	jalr	1196(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000371e:	0001c497          	auipc	s1,0x1c
    80003722:	69a4b483          	ld	s1,1690(s1) # 8001fdb8 <bcache+0x82b8>
    80003726:	0001c797          	auipc	a5,0x1c
    8000372a:	64278793          	addi	a5,a5,1602 # 8001fd68 <bcache+0x8268>
    8000372e:	02f48f63          	beq	s1,a5,8000376c <bread+0x70>
    80003732:	873e                	mv	a4,a5
    80003734:	a021                	j	8000373c <bread+0x40>
    80003736:	68a4                	ld	s1,80(s1)
    80003738:	02e48a63          	beq	s1,a4,8000376c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000373c:	449c                	lw	a5,8(s1)
    8000373e:	ff279ce3          	bne	a5,s2,80003736 <bread+0x3a>
    80003742:	44dc                	lw	a5,12(s1)
    80003744:	ff3799e3          	bne	a5,s3,80003736 <bread+0x3a>
      b->refcnt++;
    80003748:	40bc                	lw	a5,64(s1)
    8000374a:	2785                	addiw	a5,a5,1
    8000374c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000374e:	00014517          	auipc	a0,0x14
    80003752:	3b250513          	addi	a0,a0,946 # 80017b00 <bcache>
    80003756:	ffffd097          	auipc	ra,0xffffd
    8000375a:	520080e7          	jalr	1312(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000375e:	01048513          	addi	a0,s1,16
    80003762:	00001097          	auipc	ra,0x1
    80003766:	46c080e7          	jalr	1132(ra) # 80004bce <acquiresleep>
      return b;
    8000376a:	a8b9                	j	800037c8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000376c:	0001c497          	auipc	s1,0x1c
    80003770:	6444b483          	ld	s1,1604(s1) # 8001fdb0 <bcache+0x82b0>
    80003774:	0001c797          	auipc	a5,0x1c
    80003778:	5f478793          	addi	a5,a5,1524 # 8001fd68 <bcache+0x8268>
    8000377c:	00f48863          	beq	s1,a5,8000378c <bread+0x90>
    80003780:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003782:	40bc                	lw	a5,64(s1)
    80003784:	cf81                	beqz	a5,8000379c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003786:	64a4                	ld	s1,72(s1)
    80003788:	fee49de3          	bne	s1,a4,80003782 <bread+0x86>
  panic("bget: no buffers");
    8000378c:	00005517          	auipc	a0,0x5
    80003790:	fac50513          	addi	a0,a0,-84 # 80008738 <syscalls+0xe0>
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	d96080e7          	jalr	-618(ra) # 8000052a <panic>
      b->dev = dev;
    8000379c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800037a0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800037a4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800037a8:	4785                	li	a5,1
    800037aa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800037ac:	00014517          	auipc	a0,0x14
    800037b0:	35450513          	addi	a0,a0,852 # 80017b00 <bcache>
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	4c2080e7          	jalr	1218(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800037bc:	01048513          	addi	a0,s1,16
    800037c0:	00001097          	auipc	ra,0x1
    800037c4:	40e080e7          	jalr	1038(ra) # 80004bce <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800037c8:	409c                	lw	a5,0(s1)
    800037ca:	cb89                	beqz	a5,800037dc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800037cc:	8526                	mv	a0,s1
    800037ce:	70a2                	ld	ra,40(sp)
    800037d0:	7402                	ld	s0,32(sp)
    800037d2:	64e2                	ld	s1,24(sp)
    800037d4:	6942                	ld	s2,16(sp)
    800037d6:	69a2                	ld	s3,8(sp)
    800037d8:	6145                	addi	sp,sp,48
    800037da:	8082                	ret
    virtio_disk_rw(b, 0);
    800037dc:	4581                	li	a1,0
    800037de:	8526                	mv	a0,s1
    800037e0:	00003097          	auipc	ra,0x3
    800037e4:	f26080e7          	jalr	-218(ra) # 80006706 <virtio_disk_rw>
    b->valid = 1;
    800037e8:	4785                	li	a5,1
    800037ea:	c09c                	sw	a5,0(s1)
  return b;
    800037ec:	b7c5                	j	800037cc <bread+0xd0>

00000000800037ee <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800037ee:	1101                	addi	sp,sp,-32
    800037f0:	ec06                	sd	ra,24(sp)
    800037f2:	e822                	sd	s0,16(sp)
    800037f4:	e426                	sd	s1,8(sp)
    800037f6:	1000                	addi	s0,sp,32
    800037f8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037fa:	0541                	addi	a0,a0,16
    800037fc:	00001097          	auipc	ra,0x1
    80003800:	46c080e7          	jalr	1132(ra) # 80004c68 <holdingsleep>
    80003804:	cd01                	beqz	a0,8000381c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003806:	4585                	li	a1,1
    80003808:	8526                	mv	a0,s1
    8000380a:	00003097          	auipc	ra,0x3
    8000380e:	efc080e7          	jalr	-260(ra) # 80006706 <virtio_disk_rw>
}
    80003812:	60e2                	ld	ra,24(sp)
    80003814:	6442                	ld	s0,16(sp)
    80003816:	64a2                	ld	s1,8(sp)
    80003818:	6105                	addi	sp,sp,32
    8000381a:	8082                	ret
    panic("bwrite");
    8000381c:	00005517          	auipc	a0,0x5
    80003820:	f3450513          	addi	a0,a0,-204 # 80008750 <syscalls+0xf8>
    80003824:	ffffd097          	auipc	ra,0xffffd
    80003828:	d06080e7          	jalr	-762(ra) # 8000052a <panic>

000000008000382c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000382c:	1101                	addi	sp,sp,-32
    8000382e:	ec06                	sd	ra,24(sp)
    80003830:	e822                	sd	s0,16(sp)
    80003832:	e426                	sd	s1,8(sp)
    80003834:	e04a                	sd	s2,0(sp)
    80003836:	1000                	addi	s0,sp,32
    80003838:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000383a:	01050913          	addi	s2,a0,16
    8000383e:	854a                	mv	a0,s2
    80003840:	00001097          	auipc	ra,0x1
    80003844:	428080e7          	jalr	1064(ra) # 80004c68 <holdingsleep>
    80003848:	c92d                	beqz	a0,800038ba <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000384a:	854a                	mv	a0,s2
    8000384c:	00001097          	auipc	ra,0x1
    80003850:	3d8080e7          	jalr	984(ra) # 80004c24 <releasesleep>

  acquire(&bcache.lock);
    80003854:	00014517          	auipc	a0,0x14
    80003858:	2ac50513          	addi	a0,a0,684 # 80017b00 <bcache>
    8000385c:	ffffd097          	auipc	ra,0xffffd
    80003860:	366080e7          	jalr	870(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003864:	40bc                	lw	a5,64(s1)
    80003866:	37fd                	addiw	a5,a5,-1
    80003868:	0007871b          	sext.w	a4,a5
    8000386c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000386e:	eb05                	bnez	a4,8000389e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003870:	68bc                	ld	a5,80(s1)
    80003872:	64b8                	ld	a4,72(s1)
    80003874:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003876:	64bc                	ld	a5,72(s1)
    80003878:	68b8                	ld	a4,80(s1)
    8000387a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000387c:	0001c797          	auipc	a5,0x1c
    80003880:	28478793          	addi	a5,a5,644 # 8001fb00 <bcache+0x8000>
    80003884:	2b87b703          	ld	a4,696(a5)
    80003888:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000388a:	0001c717          	auipc	a4,0x1c
    8000388e:	4de70713          	addi	a4,a4,1246 # 8001fd68 <bcache+0x8268>
    80003892:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003894:	2b87b703          	ld	a4,696(a5)
    80003898:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000389a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000389e:	00014517          	auipc	a0,0x14
    800038a2:	26250513          	addi	a0,a0,610 # 80017b00 <bcache>
    800038a6:	ffffd097          	auipc	ra,0xffffd
    800038aa:	3d0080e7          	jalr	976(ra) # 80000c76 <release>
}
    800038ae:	60e2                	ld	ra,24(sp)
    800038b0:	6442                	ld	s0,16(sp)
    800038b2:	64a2                	ld	s1,8(sp)
    800038b4:	6902                	ld	s2,0(sp)
    800038b6:	6105                	addi	sp,sp,32
    800038b8:	8082                	ret
    panic("brelse");
    800038ba:	00005517          	auipc	a0,0x5
    800038be:	e9e50513          	addi	a0,a0,-354 # 80008758 <syscalls+0x100>
    800038c2:	ffffd097          	auipc	ra,0xffffd
    800038c6:	c68080e7          	jalr	-920(ra) # 8000052a <panic>

00000000800038ca <bpin>:

void
bpin(struct buf *b) {
    800038ca:	1101                	addi	sp,sp,-32
    800038cc:	ec06                	sd	ra,24(sp)
    800038ce:	e822                	sd	s0,16(sp)
    800038d0:	e426                	sd	s1,8(sp)
    800038d2:	1000                	addi	s0,sp,32
    800038d4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038d6:	00014517          	auipc	a0,0x14
    800038da:	22a50513          	addi	a0,a0,554 # 80017b00 <bcache>
    800038de:	ffffd097          	auipc	ra,0xffffd
    800038e2:	2e4080e7          	jalr	740(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800038e6:	40bc                	lw	a5,64(s1)
    800038e8:	2785                	addiw	a5,a5,1
    800038ea:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038ec:	00014517          	auipc	a0,0x14
    800038f0:	21450513          	addi	a0,a0,532 # 80017b00 <bcache>
    800038f4:	ffffd097          	auipc	ra,0xffffd
    800038f8:	382080e7          	jalr	898(ra) # 80000c76 <release>
}
    800038fc:	60e2                	ld	ra,24(sp)
    800038fe:	6442                	ld	s0,16(sp)
    80003900:	64a2                	ld	s1,8(sp)
    80003902:	6105                	addi	sp,sp,32
    80003904:	8082                	ret

0000000080003906 <bunpin>:

void
bunpin(struct buf *b) {
    80003906:	1101                	addi	sp,sp,-32
    80003908:	ec06                	sd	ra,24(sp)
    8000390a:	e822                	sd	s0,16(sp)
    8000390c:	e426                	sd	s1,8(sp)
    8000390e:	1000                	addi	s0,sp,32
    80003910:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003912:	00014517          	auipc	a0,0x14
    80003916:	1ee50513          	addi	a0,a0,494 # 80017b00 <bcache>
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	2a8080e7          	jalr	680(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003922:	40bc                	lw	a5,64(s1)
    80003924:	37fd                	addiw	a5,a5,-1
    80003926:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003928:	00014517          	auipc	a0,0x14
    8000392c:	1d850513          	addi	a0,a0,472 # 80017b00 <bcache>
    80003930:	ffffd097          	auipc	ra,0xffffd
    80003934:	346080e7          	jalr	838(ra) # 80000c76 <release>
}
    80003938:	60e2                	ld	ra,24(sp)
    8000393a:	6442                	ld	s0,16(sp)
    8000393c:	64a2                	ld	s1,8(sp)
    8000393e:	6105                	addi	sp,sp,32
    80003940:	8082                	ret

0000000080003942 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003942:	1101                	addi	sp,sp,-32
    80003944:	ec06                	sd	ra,24(sp)
    80003946:	e822                	sd	s0,16(sp)
    80003948:	e426                	sd	s1,8(sp)
    8000394a:	e04a                	sd	s2,0(sp)
    8000394c:	1000                	addi	s0,sp,32
    8000394e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003950:	00d5d59b          	srliw	a1,a1,0xd
    80003954:	0001d797          	auipc	a5,0x1d
    80003958:	8887a783          	lw	a5,-1912(a5) # 800201dc <sb+0x1c>
    8000395c:	9dbd                	addw	a1,a1,a5
    8000395e:	00000097          	auipc	ra,0x0
    80003962:	d9e080e7          	jalr	-610(ra) # 800036fc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003966:	0074f713          	andi	a4,s1,7
    8000396a:	4785                	li	a5,1
    8000396c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003970:	14ce                	slli	s1,s1,0x33
    80003972:	90d9                	srli	s1,s1,0x36
    80003974:	00950733          	add	a4,a0,s1
    80003978:	05874703          	lbu	a4,88(a4)
    8000397c:	00e7f6b3          	and	a3,a5,a4
    80003980:	c69d                	beqz	a3,800039ae <bfree+0x6c>
    80003982:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003984:	94aa                	add	s1,s1,a0
    80003986:	fff7c793          	not	a5,a5
    8000398a:	8ff9                	and	a5,a5,a4
    8000398c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003990:	00001097          	auipc	ra,0x1
    80003994:	11e080e7          	jalr	286(ra) # 80004aae <log_write>
  brelse(bp);
    80003998:	854a                	mv	a0,s2
    8000399a:	00000097          	auipc	ra,0x0
    8000399e:	e92080e7          	jalr	-366(ra) # 8000382c <brelse>
}
    800039a2:	60e2                	ld	ra,24(sp)
    800039a4:	6442                	ld	s0,16(sp)
    800039a6:	64a2                	ld	s1,8(sp)
    800039a8:	6902                	ld	s2,0(sp)
    800039aa:	6105                	addi	sp,sp,32
    800039ac:	8082                	ret
    panic("freeing free block");
    800039ae:	00005517          	auipc	a0,0x5
    800039b2:	db250513          	addi	a0,a0,-590 # 80008760 <syscalls+0x108>
    800039b6:	ffffd097          	auipc	ra,0xffffd
    800039ba:	b74080e7          	jalr	-1164(ra) # 8000052a <panic>

00000000800039be <balloc>:
{
    800039be:	711d                	addi	sp,sp,-96
    800039c0:	ec86                	sd	ra,88(sp)
    800039c2:	e8a2                	sd	s0,80(sp)
    800039c4:	e4a6                	sd	s1,72(sp)
    800039c6:	e0ca                	sd	s2,64(sp)
    800039c8:	fc4e                	sd	s3,56(sp)
    800039ca:	f852                	sd	s4,48(sp)
    800039cc:	f456                	sd	s5,40(sp)
    800039ce:	f05a                	sd	s6,32(sp)
    800039d0:	ec5e                	sd	s7,24(sp)
    800039d2:	e862                	sd	s8,16(sp)
    800039d4:	e466                	sd	s9,8(sp)
    800039d6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800039d8:	0001c797          	auipc	a5,0x1c
    800039dc:	7ec7a783          	lw	a5,2028(a5) # 800201c4 <sb+0x4>
    800039e0:	cbd1                	beqz	a5,80003a74 <balloc+0xb6>
    800039e2:	8baa                	mv	s7,a0
    800039e4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800039e6:	0001cb17          	auipc	s6,0x1c
    800039ea:	7dab0b13          	addi	s6,s6,2010 # 800201c0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039ee:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800039f0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039f2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800039f4:	6c89                	lui	s9,0x2
    800039f6:	a831                	j	80003a12 <balloc+0x54>
    brelse(bp);
    800039f8:	854a                	mv	a0,s2
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	e32080e7          	jalr	-462(ra) # 8000382c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003a02:	015c87bb          	addw	a5,s9,s5
    80003a06:	00078a9b          	sext.w	s5,a5
    80003a0a:	004b2703          	lw	a4,4(s6)
    80003a0e:	06eaf363          	bgeu	s5,a4,80003a74 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003a12:	41fad79b          	sraiw	a5,s5,0x1f
    80003a16:	0137d79b          	srliw	a5,a5,0x13
    80003a1a:	015787bb          	addw	a5,a5,s5
    80003a1e:	40d7d79b          	sraiw	a5,a5,0xd
    80003a22:	01cb2583          	lw	a1,28(s6)
    80003a26:	9dbd                	addw	a1,a1,a5
    80003a28:	855e                	mv	a0,s7
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	cd2080e7          	jalr	-814(ra) # 800036fc <bread>
    80003a32:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a34:	004b2503          	lw	a0,4(s6)
    80003a38:	000a849b          	sext.w	s1,s5
    80003a3c:	8662                	mv	a2,s8
    80003a3e:	faa4fde3          	bgeu	s1,a0,800039f8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003a42:	41f6579b          	sraiw	a5,a2,0x1f
    80003a46:	01d7d69b          	srliw	a3,a5,0x1d
    80003a4a:	00c6873b          	addw	a4,a3,a2
    80003a4e:	00777793          	andi	a5,a4,7
    80003a52:	9f95                	subw	a5,a5,a3
    80003a54:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a58:	4037571b          	sraiw	a4,a4,0x3
    80003a5c:	00e906b3          	add	a3,s2,a4
    80003a60:	0586c683          	lbu	a3,88(a3)
    80003a64:	00d7f5b3          	and	a1,a5,a3
    80003a68:	cd91                	beqz	a1,80003a84 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a6a:	2605                	addiw	a2,a2,1
    80003a6c:	2485                	addiw	s1,s1,1
    80003a6e:	fd4618e3          	bne	a2,s4,80003a3e <balloc+0x80>
    80003a72:	b759                	j	800039f8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003a74:	00005517          	auipc	a0,0x5
    80003a78:	d0450513          	addi	a0,a0,-764 # 80008778 <syscalls+0x120>
    80003a7c:	ffffd097          	auipc	ra,0xffffd
    80003a80:	aae080e7          	jalr	-1362(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003a84:	974a                	add	a4,a4,s2
    80003a86:	8fd5                	or	a5,a5,a3
    80003a88:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003a8c:	854a                	mv	a0,s2
    80003a8e:	00001097          	auipc	ra,0x1
    80003a92:	020080e7          	jalr	32(ra) # 80004aae <log_write>
        brelse(bp);
    80003a96:	854a                	mv	a0,s2
    80003a98:	00000097          	auipc	ra,0x0
    80003a9c:	d94080e7          	jalr	-620(ra) # 8000382c <brelse>
  bp = bread(dev, bno);
    80003aa0:	85a6                	mv	a1,s1
    80003aa2:	855e                	mv	a0,s7
    80003aa4:	00000097          	auipc	ra,0x0
    80003aa8:	c58080e7          	jalr	-936(ra) # 800036fc <bread>
    80003aac:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003aae:	40000613          	li	a2,1024
    80003ab2:	4581                	li	a1,0
    80003ab4:	05850513          	addi	a0,a0,88
    80003ab8:	ffffd097          	auipc	ra,0xffffd
    80003abc:	206080e7          	jalr	518(ra) # 80000cbe <memset>
  log_write(bp);
    80003ac0:	854a                	mv	a0,s2
    80003ac2:	00001097          	auipc	ra,0x1
    80003ac6:	fec080e7          	jalr	-20(ra) # 80004aae <log_write>
  brelse(bp);
    80003aca:	854a                	mv	a0,s2
    80003acc:	00000097          	auipc	ra,0x0
    80003ad0:	d60080e7          	jalr	-672(ra) # 8000382c <brelse>
}
    80003ad4:	8526                	mv	a0,s1
    80003ad6:	60e6                	ld	ra,88(sp)
    80003ad8:	6446                	ld	s0,80(sp)
    80003ada:	64a6                	ld	s1,72(sp)
    80003adc:	6906                	ld	s2,64(sp)
    80003ade:	79e2                	ld	s3,56(sp)
    80003ae0:	7a42                	ld	s4,48(sp)
    80003ae2:	7aa2                	ld	s5,40(sp)
    80003ae4:	7b02                	ld	s6,32(sp)
    80003ae6:	6be2                	ld	s7,24(sp)
    80003ae8:	6c42                	ld	s8,16(sp)
    80003aea:	6ca2                	ld	s9,8(sp)
    80003aec:	6125                	addi	sp,sp,96
    80003aee:	8082                	ret

0000000080003af0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003af0:	7179                	addi	sp,sp,-48
    80003af2:	f406                	sd	ra,40(sp)
    80003af4:	f022                	sd	s0,32(sp)
    80003af6:	ec26                	sd	s1,24(sp)
    80003af8:	e84a                	sd	s2,16(sp)
    80003afa:	e44e                	sd	s3,8(sp)
    80003afc:	e052                	sd	s4,0(sp)
    80003afe:	1800                	addi	s0,sp,48
    80003b00:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003b02:	47ad                	li	a5,11
    80003b04:	04b7fe63          	bgeu	a5,a1,80003b60 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003b08:	ff45849b          	addiw	s1,a1,-12
    80003b0c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003b10:	0ff00793          	li	a5,255
    80003b14:	0ae7e463          	bltu	a5,a4,80003bbc <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003b18:	08052583          	lw	a1,128(a0)
    80003b1c:	c5b5                	beqz	a1,80003b88 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003b1e:	00092503          	lw	a0,0(s2)
    80003b22:	00000097          	auipc	ra,0x0
    80003b26:	bda080e7          	jalr	-1062(ra) # 800036fc <bread>
    80003b2a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b2c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b30:	02049713          	slli	a4,s1,0x20
    80003b34:	01e75593          	srli	a1,a4,0x1e
    80003b38:	00b784b3          	add	s1,a5,a1
    80003b3c:	0004a983          	lw	s3,0(s1)
    80003b40:	04098e63          	beqz	s3,80003b9c <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003b44:	8552                	mv	a0,s4
    80003b46:	00000097          	auipc	ra,0x0
    80003b4a:	ce6080e7          	jalr	-794(ra) # 8000382c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b4e:	854e                	mv	a0,s3
    80003b50:	70a2                	ld	ra,40(sp)
    80003b52:	7402                	ld	s0,32(sp)
    80003b54:	64e2                	ld	s1,24(sp)
    80003b56:	6942                	ld	s2,16(sp)
    80003b58:	69a2                	ld	s3,8(sp)
    80003b5a:	6a02                	ld	s4,0(sp)
    80003b5c:	6145                	addi	sp,sp,48
    80003b5e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003b60:	02059793          	slli	a5,a1,0x20
    80003b64:	01e7d593          	srli	a1,a5,0x1e
    80003b68:	00b504b3          	add	s1,a0,a1
    80003b6c:	0504a983          	lw	s3,80(s1)
    80003b70:	fc099fe3          	bnez	s3,80003b4e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003b74:	4108                	lw	a0,0(a0)
    80003b76:	00000097          	auipc	ra,0x0
    80003b7a:	e48080e7          	jalr	-440(ra) # 800039be <balloc>
    80003b7e:	0005099b          	sext.w	s3,a0
    80003b82:	0534a823          	sw	s3,80(s1)
    80003b86:	b7e1                	j	80003b4e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003b88:	4108                	lw	a0,0(a0)
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	e34080e7          	jalr	-460(ra) # 800039be <balloc>
    80003b92:	0005059b          	sext.w	a1,a0
    80003b96:	08b92023          	sw	a1,128(s2)
    80003b9a:	b751                	j	80003b1e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003b9c:	00092503          	lw	a0,0(s2)
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	e1e080e7          	jalr	-482(ra) # 800039be <balloc>
    80003ba8:	0005099b          	sext.w	s3,a0
    80003bac:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003bb0:	8552                	mv	a0,s4
    80003bb2:	00001097          	auipc	ra,0x1
    80003bb6:	efc080e7          	jalr	-260(ra) # 80004aae <log_write>
    80003bba:	b769                	j	80003b44 <bmap+0x54>
  panic("bmap: out of range");
    80003bbc:	00005517          	auipc	a0,0x5
    80003bc0:	bd450513          	addi	a0,a0,-1068 # 80008790 <syscalls+0x138>
    80003bc4:	ffffd097          	auipc	ra,0xffffd
    80003bc8:	966080e7          	jalr	-1690(ra) # 8000052a <panic>

0000000080003bcc <iget>:
{
    80003bcc:	7179                	addi	sp,sp,-48
    80003bce:	f406                	sd	ra,40(sp)
    80003bd0:	f022                	sd	s0,32(sp)
    80003bd2:	ec26                	sd	s1,24(sp)
    80003bd4:	e84a                	sd	s2,16(sp)
    80003bd6:	e44e                	sd	s3,8(sp)
    80003bd8:	e052                	sd	s4,0(sp)
    80003bda:	1800                	addi	s0,sp,48
    80003bdc:	89aa                	mv	s3,a0
    80003bde:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003be0:	0001c517          	auipc	a0,0x1c
    80003be4:	60050513          	addi	a0,a0,1536 # 800201e0 <itable>
    80003be8:	ffffd097          	auipc	ra,0xffffd
    80003bec:	fda080e7          	jalr	-38(ra) # 80000bc2 <acquire>
  empty = 0;
    80003bf0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bf2:	0001c497          	auipc	s1,0x1c
    80003bf6:	60648493          	addi	s1,s1,1542 # 800201f8 <itable+0x18>
    80003bfa:	0001e697          	auipc	a3,0x1e
    80003bfe:	08e68693          	addi	a3,a3,142 # 80021c88 <log>
    80003c02:	a039                	j	80003c10 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c04:	02090b63          	beqz	s2,80003c3a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003c08:	08848493          	addi	s1,s1,136
    80003c0c:	02d48a63          	beq	s1,a3,80003c40 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003c10:	449c                	lw	a5,8(s1)
    80003c12:	fef059e3          	blez	a5,80003c04 <iget+0x38>
    80003c16:	4098                	lw	a4,0(s1)
    80003c18:	ff3716e3          	bne	a4,s3,80003c04 <iget+0x38>
    80003c1c:	40d8                	lw	a4,4(s1)
    80003c1e:	ff4713e3          	bne	a4,s4,80003c04 <iget+0x38>
      ip->ref++;
    80003c22:	2785                	addiw	a5,a5,1
    80003c24:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003c26:	0001c517          	auipc	a0,0x1c
    80003c2a:	5ba50513          	addi	a0,a0,1466 # 800201e0 <itable>
    80003c2e:	ffffd097          	auipc	ra,0xffffd
    80003c32:	048080e7          	jalr	72(ra) # 80000c76 <release>
      return ip;
    80003c36:	8926                	mv	s2,s1
    80003c38:	a03d                	j	80003c66 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c3a:	f7f9                	bnez	a5,80003c08 <iget+0x3c>
    80003c3c:	8926                	mv	s2,s1
    80003c3e:	b7e9                	j	80003c08 <iget+0x3c>
  if(empty == 0)
    80003c40:	02090c63          	beqz	s2,80003c78 <iget+0xac>
  ip->dev = dev;
    80003c44:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c48:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c4c:	4785                	li	a5,1
    80003c4e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c52:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c56:	0001c517          	auipc	a0,0x1c
    80003c5a:	58a50513          	addi	a0,a0,1418 # 800201e0 <itable>
    80003c5e:	ffffd097          	auipc	ra,0xffffd
    80003c62:	018080e7          	jalr	24(ra) # 80000c76 <release>
}
    80003c66:	854a                	mv	a0,s2
    80003c68:	70a2                	ld	ra,40(sp)
    80003c6a:	7402                	ld	s0,32(sp)
    80003c6c:	64e2                	ld	s1,24(sp)
    80003c6e:	6942                	ld	s2,16(sp)
    80003c70:	69a2                	ld	s3,8(sp)
    80003c72:	6a02                	ld	s4,0(sp)
    80003c74:	6145                	addi	sp,sp,48
    80003c76:	8082                	ret
    panic("iget: no inodes");
    80003c78:	00005517          	auipc	a0,0x5
    80003c7c:	b3050513          	addi	a0,a0,-1232 # 800087a8 <syscalls+0x150>
    80003c80:	ffffd097          	auipc	ra,0xffffd
    80003c84:	8aa080e7          	jalr	-1878(ra) # 8000052a <panic>

0000000080003c88 <fsinit>:
fsinit(int dev) {
    80003c88:	7179                	addi	sp,sp,-48
    80003c8a:	f406                	sd	ra,40(sp)
    80003c8c:	f022                	sd	s0,32(sp)
    80003c8e:	ec26                	sd	s1,24(sp)
    80003c90:	e84a                	sd	s2,16(sp)
    80003c92:	e44e                	sd	s3,8(sp)
    80003c94:	1800                	addi	s0,sp,48
    80003c96:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c98:	4585                	li	a1,1
    80003c9a:	00000097          	auipc	ra,0x0
    80003c9e:	a62080e7          	jalr	-1438(ra) # 800036fc <bread>
    80003ca2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ca4:	0001c997          	auipc	s3,0x1c
    80003ca8:	51c98993          	addi	s3,s3,1308 # 800201c0 <sb>
    80003cac:	02000613          	li	a2,32
    80003cb0:	05850593          	addi	a1,a0,88
    80003cb4:	854e                	mv	a0,s3
    80003cb6:	ffffd097          	auipc	ra,0xffffd
    80003cba:	064080e7          	jalr	100(ra) # 80000d1a <memmove>
  brelse(bp);
    80003cbe:	8526                	mv	a0,s1
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	b6c080e7          	jalr	-1172(ra) # 8000382c <brelse>
  if(sb.magic != FSMAGIC)
    80003cc8:	0009a703          	lw	a4,0(s3)
    80003ccc:	102037b7          	lui	a5,0x10203
    80003cd0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003cd4:	02f71263          	bne	a4,a5,80003cf8 <fsinit+0x70>
  initlog(dev, &sb);
    80003cd8:	0001c597          	auipc	a1,0x1c
    80003cdc:	4e858593          	addi	a1,a1,1256 # 800201c0 <sb>
    80003ce0:	854a                	mv	a0,s2
    80003ce2:	00001097          	auipc	ra,0x1
    80003ce6:	b4e080e7          	jalr	-1202(ra) # 80004830 <initlog>
}
    80003cea:	70a2                	ld	ra,40(sp)
    80003cec:	7402                	ld	s0,32(sp)
    80003cee:	64e2                	ld	s1,24(sp)
    80003cf0:	6942                	ld	s2,16(sp)
    80003cf2:	69a2                	ld	s3,8(sp)
    80003cf4:	6145                	addi	sp,sp,48
    80003cf6:	8082                	ret
    panic("invalid file system");
    80003cf8:	00005517          	auipc	a0,0x5
    80003cfc:	ac050513          	addi	a0,a0,-1344 # 800087b8 <syscalls+0x160>
    80003d00:	ffffd097          	auipc	ra,0xffffd
    80003d04:	82a080e7          	jalr	-2006(ra) # 8000052a <panic>

0000000080003d08 <iinit>:
{
    80003d08:	7179                	addi	sp,sp,-48
    80003d0a:	f406                	sd	ra,40(sp)
    80003d0c:	f022                	sd	s0,32(sp)
    80003d0e:	ec26                	sd	s1,24(sp)
    80003d10:	e84a                	sd	s2,16(sp)
    80003d12:	e44e                	sd	s3,8(sp)
    80003d14:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003d16:	00005597          	auipc	a1,0x5
    80003d1a:	aba58593          	addi	a1,a1,-1350 # 800087d0 <syscalls+0x178>
    80003d1e:	0001c517          	auipc	a0,0x1c
    80003d22:	4c250513          	addi	a0,a0,1218 # 800201e0 <itable>
    80003d26:	ffffd097          	auipc	ra,0xffffd
    80003d2a:	e0c080e7          	jalr	-500(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d2e:	0001c497          	auipc	s1,0x1c
    80003d32:	4da48493          	addi	s1,s1,1242 # 80020208 <itable+0x28>
    80003d36:	0001e997          	auipc	s3,0x1e
    80003d3a:	f6298993          	addi	s3,s3,-158 # 80021c98 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d3e:	00005917          	auipc	s2,0x5
    80003d42:	a9a90913          	addi	s2,s2,-1382 # 800087d8 <syscalls+0x180>
    80003d46:	85ca                	mv	a1,s2
    80003d48:	8526                	mv	a0,s1
    80003d4a:	00001097          	auipc	ra,0x1
    80003d4e:	e4a080e7          	jalr	-438(ra) # 80004b94 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d52:	08848493          	addi	s1,s1,136
    80003d56:	ff3498e3          	bne	s1,s3,80003d46 <iinit+0x3e>
}
    80003d5a:	70a2                	ld	ra,40(sp)
    80003d5c:	7402                	ld	s0,32(sp)
    80003d5e:	64e2                	ld	s1,24(sp)
    80003d60:	6942                	ld	s2,16(sp)
    80003d62:	69a2                	ld	s3,8(sp)
    80003d64:	6145                	addi	sp,sp,48
    80003d66:	8082                	ret

0000000080003d68 <ialloc>:
{
    80003d68:	715d                	addi	sp,sp,-80
    80003d6a:	e486                	sd	ra,72(sp)
    80003d6c:	e0a2                	sd	s0,64(sp)
    80003d6e:	fc26                	sd	s1,56(sp)
    80003d70:	f84a                	sd	s2,48(sp)
    80003d72:	f44e                	sd	s3,40(sp)
    80003d74:	f052                	sd	s4,32(sp)
    80003d76:	ec56                	sd	s5,24(sp)
    80003d78:	e85a                	sd	s6,16(sp)
    80003d7a:	e45e                	sd	s7,8(sp)
    80003d7c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d7e:	0001c717          	auipc	a4,0x1c
    80003d82:	44e72703          	lw	a4,1102(a4) # 800201cc <sb+0xc>
    80003d86:	4785                	li	a5,1
    80003d88:	04e7fa63          	bgeu	a5,a4,80003ddc <ialloc+0x74>
    80003d8c:	8aaa                	mv	s5,a0
    80003d8e:	8bae                	mv	s7,a1
    80003d90:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d92:	0001ca17          	auipc	s4,0x1c
    80003d96:	42ea0a13          	addi	s4,s4,1070 # 800201c0 <sb>
    80003d9a:	00048b1b          	sext.w	s6,s1
    80003d9e:	0044d793          	srli	a5,s1,0x4
    80003da2:	018a2583          	lw	a1,24(s4)
    80003da6:	9dbd                	addw	a1,a1,a5
    80003da8:	8556                	mv	a0,s5
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	952080e7          	jalr	-1710(ra) # 800036fc <bread>
    80003db2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003db4:	05850993          	addi	s3,a0,88
    80003db8:	00f4f793          	andi	a5,s1,15
    80003dbc:	079a                	slli	a5,a5,0x6
    80003dbe:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003dc0:	00099783          	lh	a5,0(s3)
    80003dc4:	c785                	beqz	a5,80003dec <ialloc+0x84>
    brelse(bp);
    80003dc6:	00000097          	auipc	ra,0x0
    80003dca:	a66080e7          	jalr	-1434(ra) # 8000382c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003dce:	0485                	addi	s1,s1,1
    80003dd0:	00ca2703          	lw	a4,12(s4)
    80003dd4:	0004879b          	sext.w	a5,s1
    80003dd8:	fce7e1e3          	bltu	a5,a4,80003d9a <ialloc+0x32>
  panic("ialloc: no inodes");
    80003ddc:	00005517          	auipc	a0,0x5
    80003de0:	a0450513          	addi	a0,a0,-1532 # 800087e0 <syscalls+0x188>
    80003de4:	ffffc097          	auipc	ra,0xffffc
    80003de8:	746080e7          	jalr	1862(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003dec:	04000613          	li	a2,64
    80003df0:	4581                	li	a1,0
    80003df2:	854e                	mv	a0,s3
    80003df4:	ffffd097          	auipc	ra,0xffffd
    80003df8:	eca080e7          	jalr	-310(ra) # 80000cbe <memset>
      dip->type = type;
    80003dfc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003e00:	854a                	mv	a0,s2
    80003e02:	00001097          	auipc	ra,0x1
    80003e06:	cac080e7          	jalr	-852(ra) # 80004aae <log_write>
      brelse(bp);
    80003e0a:	854a                	mv	a0,s2
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	a20080e7          	jalr	-1504(ra) # 8000382c <brelse>
      return iget(dev, inum);
    80003e14:	85da                	mv	a1,s6
    80003e16:	8556                	mv	a0,s5
    80003e18:	00000097          	auipc	ra,0x0
    80003e1c:	db4080e7          	jalr	-588(ra) # 80003bcc <iget>
}
    80003e20:	60a6                	ld	ra,72(sp)
    80003e22:	6406                	ld	s0,64(sp)
    80003e24:	74e2                	ld	s1,56(sp)
    80003e26:	7942                	ld	s2,48(sp)
    80003e28:	79a2                	ld	s3,40(sp)
    80003e2a:	7a02                	ld	s4,32(sp)
    80003e2c:	6ae2                	ld	s5,24(sp)
    80003e2e:	6b42                	ld	s6,16(sp)
    80003e30:	6ba2                	ld	s7,8(sp)
    80003e32:	6161                	addi	sp,sp,80
    80003e34:	8082                	ret

0000000080003e36 <iupdate>:
{
    80003e36:	1101                	addi	sp,sp,-32
    80003e38:	ec06                	sd	ra,24(sp)
    80003e3a:	e822                	sd	s0,16(sp)
    80003e3c:	e426                	sd	s1,8(sp)
    80003e3e:	e04a                	sd	s2,0(sp)
    80003e40:	1000                	addi	s0,sp,32
    80003e42:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e44:	415c                	lw	a5,4(a0)
    80003e46:	0047d79b          	srliw	a5,a5,0x4
    80003e4a:	0001c597          	auipc	a1,0x1c
    80003e4e:	38e5a583          	lw	a1,910(a1) # 800201d8 <sb+0x18>
    80003e52:	9dbd                	addw	a1,a1,a5
    80003e54:	4108                	lw	a0,0(a0)
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	8a6080e7          	jalr	-1882(ra) # 800036fc <bread>
    80003e5e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e60:	05850793          	addi	a5,a0,88
    80003e64:	40c8                	lw	a0,4(s1)
    80003e66:	893d                	andi	a0,a0,15
    80003e68:	051a                	slli	a0,a0,0x6
    80003e6a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003e6c:	04449703          	lh	a4,68(s1)
    80003e70:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003e74:	04649703          	lh	a4,70(s1)
    80003e78:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003e7c:	04849703          	lh	a4,72(s1)
    80003e80:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003e84:	04a49703          	lh	a4,74(s1)
    80003e88:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003e8c:	44f8                	lw	a4,76(s1)
    80003e8e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e90:	03400613          	li	a2,52
    80003e94:	05048593          	addi	a1,s1,80
    80003e98:	0531                	addi	a0,a0,12
    80003e9a:	ffffd097          	auipc	ra,0xffffd
    80003e9e:	e80080e7          	jalr	-384(ra) # 80000d1a <memmove>
  log_write(bp);
    80003ea2:	854a                	mv	a0,s2
    80003ea4:	00001097          	auipc	ra,0x1
    80003ea8:	c0a080e7          	jalr	-1014(ra) # 80004aae <log_write>
  brelse(bp);
    80003eac:	854a                	mv	a0,s2
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	97e080e7          	jalr	-1666(ra) # 8000382c <brelse>
}
    80003eb6:	60e2                	ld	ra,24(sp)
    80003eb8:	6442                	ld	s0,16(sp)
    80003eba:	64a2                	ld	s1,8(sp)
    80003ebc:	6902                	ld	s2,0(sp)
    80003ebe:	6105                	addi	sp,sp,32
    80003ec0:	8082                	ret

0000000080003ec2 <idup>:
{
    80003ec2:	1101                	addi	sp,sp,-32
    80003ec4:	ec06                	sd	ra,24(sp)
    80003ec6:	e822                	sd	s0,16(sp)
    80003ec8:	e426                	sd	s1,8(sp)
    80003eca:	1000                	addi	s0,sp,32
    80003ecc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ece:	0001c517          	auipc	a0,0x1c
    80003ed2:	31250513          	addi	a0,a0,786 # 800201e0 <itable>
    80003ed6:	ffffd097          	auipc	ra,0xffffd
    80003eda:	cec080e7          	jalr	-788(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003ede:	449c                	lw	a5,8(s1)
    80003ee0:	2785                	addiw	a5,a5,1
    80003ee2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ee4:	0001c517          	auipc	a0,0x1c
    80003ee8:	2fc50513          	addi	a0,a0,764 # 800201e0 <itable>
    80003eec:	ffffd097          	auipc	ra,0xffffd
    80003ef0:	d8a080e7          	jalr	-630(ra) # 80000c76 <release>
}
    80003ef4:	8526                	mv	a0,s1
    80003ef6:	60e2                	ld	ra,24(sp)
    80003ef8:	6442                	ld	s0,16(sp)
    80003efa:	64a2                	ld	s1,8(sp)
    80003efc:	6105                	addi	sp,sp,32
    80003efe:	8082                	ret

0000000080003f00 <ilock>:
{
    80003f00:	1101                	addi	sp,sp,-32
    80003f02:	ec06                	sd	ra,24(sp)
    80003f04:	e822                	sd	s0,16(sp)
    80003f06:	e426                	sd	s1,8(sp)
    80003f08:	e04a                	sd	s2,0(sp)
    80003f0a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003f0c:	c115                	beqz	a0,80003f30 <ilock+0x30>
    80003f0e:	84aa                	mv	s1,a0
    80003f10:	451c                	lw	a5,8(a0)
    80003f12:	00f05f63          	blez	a5,80003f30 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003f16:	0541                	addi	a0,a0,16
    80003f18:	00001097          	auipc	ra,0x1
    80003f1c:	cb6080e7          	jalr	-842(ra) # 80004bce <acquiresleep>
  if(ip->valid == 0){
    80003f20:	40bc                	lw	a5,64(s1)
    80003f22:	cf99                	beqz	a5,80003f40 <ilock+0x40>
}
    80003f24:	60e2                	ld	ra,24(sp)
    80003f26:	6442                	ld	s0,16(sp)
    80003f28:	64a2                	ld	s1,8(sp)
    80003f2a:	6902                	ld	s2,0(sp)
    80003f2c:	6105                	addi	sp,sp,32
    80003f2e:	8082                	ret
    panic("ilock");
    80003f30:	00005517          	auipc	a0,0x5
    80003f34:	8c850513          	addi	a0,a0,-1848 # 800087f8 <syscalls+0x1a0>
    80003f38:	ffffc097          	auipc	ra,0xffffc
    80003f3c:	5f2080e7          	jalr	1522(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f40:	40dc                	lw	a5,4(s1)
    80003f42:	0047d79b          	srliw	a5,a5,0x4
    80003f46:	0001c597          	auipc	a1,0x1c
    80003f4a:	2925a583          	lw	a1,658(a1) # 800201d8 <sb+0x18>
    80003f4e:	9dbd                	addw	a1,a1,a5
    80003f50:	4088                	lw	a0,0(s1)
    80003f52:	fffff097          	auipc	ra,0xfffff
    80003f56:	7aa080e7          	jalr	1962(ra) # 800036fc <bread>
    80003f5a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f5c:	05850593          	addi	a1,a0,88
    80003f60:	40dc                	lw	a5,4(s1)
    80003f62:	8bbd                	andi	a5,a5,15
    80003f64:	079a                	slli	a5,a5,0x6
    80003f66:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f68:	00059783          	lh	a5,0(a1)
    80003f6c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f70:	00259783          	lh	a5,2(a1)
    80003f74:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f78:	00459783          	lh	a5,4(a1)
    80003f7c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f80:	00659783          	lh	a5,6(a1)
    80003f84:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f88:	459c                	lw	a5,8(a1)
    80003f8a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f8c:	03400613          	li	a2,52
    80003f90:	05b1                	addi	a1,a1,12
    80003f92:	05048513          	addi	a0,s1,80
    80003f96:	ffffd097          	auipc	ra,0xffffd
    80003f9a:	d84080e7          	jalr	-636(ra) # 80000d1a <memmove>
    brelse(bp);
    80003f9e:	854a                	mv	a0,s2
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	88c080e7          	jalr	-1908(ra) # 8000382c <brelse>
    ip->valid = 1;
    80003fa8:	4785                	li	a5,1
    80003faa:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003fac:	04449783          	lh	a5,68(s1)
    80003fb0:	fbb5                	bnez	a5,80003f24 <ilock+0x24>
      panic("ilock: no type");
    80003fb2:	00005517          	auipc	a0,0x5
    80003fb6:	84e50513          	addi	a0,a0,-1970 # 80008800 <syscalls+0x1a8>
    80003fba:	ffffc097          	auipc	ra,0xffffc
    80003fbe:	570080e7          	jalr	1392(ra) # 8000052a <panic>

0000000080003fc2 <iunlock>:
{
    80003fc2:	1101                	addi	sp,sp,-32
    80003fc4:	ec06                	sd	ra,24(sp)
    80003fc6:	e822                	sd	s0,16(sp)
    80003fc8:	e426                	sd	s1,8(sp)
    80003fca:	e04a                	sd	s2,0(sp)
    80003fcc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003fce:	c905                	beqz	a0,80003ffe <iunlock+0x3c>
    80003fd0:	84aa                	mv	s1,a0
    80003fd2:	01050913          	addi	s2,a0,16
    80003fd6:	854a                	mv	a0,s2
    80003fd8:	00001097          	auipc	ra,0x1
    80003fdc:	c90080e7          	jalr	-880(ra) # 80004c68 <holdingsleep>
    80003fe0:	cd19                	beqz	a0,80003ffe <iunlock+0x3c>
    80003fe2:	449c                	lw	a5,8(s1)
    80003fe4:	00f05d63          	blez	a5,80003ffe <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003fe8:	854a                	mv	a0,s2
    80003fea:	00001097          	auipc	ra,0x1
    80003fee:	c3a080e7          	jalr	-966(ra) # 80004c24 <releasesleep>
}
    80003ff2:	60e2                	ld	ra,24(sp)
    80003ff4:	6442                	ld	s0,16(sp)
    80003ff6:	64a2                	ld	s1,8(sp)
    80003ff8:	6902                	ld	s2,0(sp)
    80003ffa:	6105                	addi	sp,sp,32
    80003ffc:	8082                	ret
    panic("iunlock");
    80003ffe:	00005517          	auipc	a0,0x5
    80004002:	81250513          	addi	a0,a0,-2030 # 80008810 <syscalls+0x1b8>
    80004006:	ffffc097          	auipc	ra,0xffffc
    8000400a:	524080e7          	jalr	1316(ra) # 8000052a <panic>

000000008000400e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000400e:	7179                	addi	sp,sp,-48
    80004010:	f406                	sd	ra,40(sp)
    80004012:	f022                	sd	s0,32(sp)
    80004014:	ec26                	sd	s1,24(sp)
    80004016:	e84a                	sd	s2,16(sp)
    80004018:	e44e                	sd	s3,8(sp)
    8000401a:	e052                	sd	s4,0(sp)
    8000401c:	1800                	addi	s0,sp,48
    8000401e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004020:	05050493          	addi	s1,a0,80
    80004024:	08050913          	addi	s2,a0,128
    80004028:	a021                	j	80004030 <itrunc+0x22>
    8000402a:	0491                	addi	s1,s1,4
    8000402c:	01248d63          	beq	s1,s2,80004046 <itrunc+0x38>
    if(ip->addrs[i]){
    80004030:	408c                	lw	a1,0(s1)
    80004032:	dde5                	beqz	a1,8000402a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004034:	0009a503          	lw	a0,0(s3)
    80004038:	00000097          	auipc	ra,0x0
    8000403c:	90a080e7          	jalr	-1782(ra) # 80003942 <bfree>
      ip->addrs[i] = 0;
    80004040:	0004a023          	sw	zero,0(s1)
    80004044:	b7dd                	j	8000402a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004046:	0809a583          	lw	a1,128(s3)
    8000404a:	e185                	bnez	a1,8000406a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000404c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004050:	854e                	mv	a0,s3
    80004052:	00000097          	auipc	ra,0x0
    80004056:	de4080e7          	jalr	-540(ra) # 80003e36 <iupdate>
}
    8000405a:	70a2                	ld	ra,40(sp)
    8000405c:	7402                	ld	s0,32(sp)
    8000405e:	64e2                	ld	s1,24(sp)
    80004060:	6942                	ld	s2,16(sp)
    80004062:	69a2                	ld	s3,8(sp)
    80004064:	6a02                	ld	s4,0(sp)
    80004066:	6145                	addi	sp,sp,48
    80004068:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000406a:	0009a503          	lw	a0,0(s3)
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	68e080e7          	jalr	1678(ra) # 800036fc <bread>
    80004076:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004078:	05850493          	addi	s1,a0,88
    8000407c:	45850913          	addi	s2,a0,1112
    80004080:	a021                	j	80004088 <itrunc+0x7a>
    80004082:	0491                	addi	s1,s1,4
    80004084:	01248b63          	beq	s1,s2,8000409a <itrunc+0x8c>
      if(a[j])
    80004088:	408c                	lw	a1,0(s1)
    8000408a:	dde5                	beqz	a1,80004082 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000408c:	0009a503          	lw	a0,0(s3)
    80004090:	00000097          	auipc	ra,0x0
    80004094:	8b2080e7          	jalr	-1870(ra) # 80003942 <bfree>
    80004098:	b7ed                	j	80004082 <itrunc+0x74>
    brelse(bp);
    8000409a:	8552                	mv	a0,s4
    8000409c:	fffff097          	auipc	ra,0xfffff
    800040a0:	790080e7          	jalr	1936(ra) # 8000382c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800040a4:	0809a583          	lw	a1,128(s3)
    800040a8:	0009a503          	lw	a0,0(s3)
    800040ac:	00000097          	auipc	ra,0x0
    800040b0:	896080e7          	jalr	-1898(ra) # 80003942 <bfree>
    ip->addrs[NDIRECT] = 0;
    800040b4:	0809a023          	sw	zero,128(s3)
    800040b8:	bf51                	j	8000404c <itrunc+0x3e>

00000000800040ba <iput>:
{
    800040ba:	1101                	addi	sp,sp,-32
    800040bc:	ec06                	sd	ra,24(sp)
    800040be:	e822                	sd	s0,16(sp)
    800040c0:	e426                	sd	s1,8(sp)
    800040c2:	e04a                	sd	s2,0(sp)
    800040c4:	1000                	addi	s0,sp,32
    800040c6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800040c8:	0001c517          	auipc	a0,0x1c
    800040cc:	11850513          	addi	a0,a0,280 # 800201e0 <itable>
    800040d0:	ffffd097          	auipc	ra,0xffffd
    800040d4:	af2080e7          	jalr	-1294(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040d8:	4498                	lw	a4,8(s1)
    800040da:	4785                	li	a5,1
    800040dc:	02f70363          	beq	a4,a5,80004102 <iput+0x48>
  ip->ref--;
    800040e0:	449c                	lw	a5,8(s1)
    800040e2:	37fd                	addiw	a5,a5,-1
    800040e4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040e6:	0001c517          	auipc	a0,0x1c
    800040ea:	0fa50513          	addi	a0,a0,250 # 800201e0 <itable>
    800040ee:	ffffd097          	auipc	ra,0xffffd
    800040f2:	b88080e7          	jalr	-1144(ra) # 80000c76 <release>
}
    800040f6:	60e2                	ld	ra,24(sp)
    800040f8:	6442                	ld	s0,16(sp)
    800040fa:	64a2                	ld	s1,8(sp)
    800040fc:	6902                	ld	s2,0(sp)
    800040fe:	6105                	addi	sp,sp,32
    80004100:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004102:	40bc                	lw	a5,64(s1)
    80004104:	dff1                	beqz	a5,800040e0 <iput+0x26>
    80004106:	04a49783          	lh	a5,74(s1)
    8000410a:	fbf9                	bnez	a5,800040e0 <iput+0x26>
    acquiresleep(&ip->lock);
    8000410c:	01048913          	addi	s2,s1,16
    80004110:	854a                	mv	a0,s2
    80004112:	00001097          	auipc	ra,0x1
    80004116:	abc080e7          	jalr	-1348(ra) # 80004bce <acquiresleep>
    release(&itable.lock);
    8000411a:	0001c517          	auipc	a0,0x1c
    8000411e:	0c650513          	addi	a0,a0,198 # 800201e0 <itable>
    80004122:	ffffd097          	auipc	ra,0xffffd
    80004126:	b54080e7          	jalr	-1196(ra) # 80000c76 <release>
    itrunc(ip);
    8000412a:	8526                	mv	a0,s1
    8000412c:	00000097          	auipc	ra,0x0
    80004130:	ee2080e7          	jalr	-286(ra) # 8000400e <itrunc>
    ip->type = 0;
    80004134:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004138:	8526                	mv	a0,s1
    8000413a:	00000097          	auipc	ra,0x0
    8000413e:	cfc080e7          	jalr	-772(ra) # 80003e36 <iupdate>
    ip->valid = 0;
    80004142:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004146:	854a                	mv	a0,s2
    80004148:	00001097          	auipc	ra,0x1
    8000414c:	adc080e7          	jalr	-1316(ra) # 80004c24 <releasesleep>
    acquire(&itable.lock);
    80004150:	0001c517          	auipc	a0,0x1c
    80004154:	09050513          	addi	a0,a0,144 # 800201e0 <itable>
    80004158:	ffffd097          	auipc	ra,0xffffd
    8000415c:	a6a080e7          	jalr	-1430(ra) # 80000bc2 <acquire>
    80004160:	b741                	j	800040e0 <iput+0x26>

0000000080004162 <iunlockput>:
{
    80004162:	1101                	addi	sp,sp,-32
    80004164:	ec06                	sd	ra,24(sp)
    80004166:	e822                	sd	s0,16(sp)
    80004168:	e426                	sd	s1,8(sp)
    8000416a:	1000                	addi	s0,sp,32
    8000416c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000416e:	00000097          	auipc	ra,0x0
    80004172:	e54080e7          	jalr	-428(ra) # 80003fc2 <iunlock>
  iput(ip);
    80004176:	8526                	mv	a0,s1
    80004178:	00000097          	auipc	ra,0x0
    8000417c:	f42080e7          	jalr	-190(ra) # 800040ba <iput>
}
    80004180:	60e2                	ld	ra,24(sp)
    80004182:	6442                	ld	s0,16(sp)
    80004184:	64a2                	ld	s1,8(sp)
    80004186:	6105                	addi	sp,sp,32
    80004188:	8082                	ret

000000008000418a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000418a:	1141                	addi	sp,sp,-16
    8000418c:	e422                	sd	s0,8(sp)
    8000418e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004190:	411c                	lw	a5,0(a0)
    80004192:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004194:	415c                	lw	a5,4(a0)
    80004196:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004198:	04451783          	lh	a5,68(a0)
    8000419c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800041a0:	04a51783          	lh	a5,74(a0)
    800041a4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800041a8:	04c56783          	lwu	a5,76(a0)
    800041ac:	e99c                	sd	a5,16(a1)
}
    800041ae:	6422                	ld	s0,8(sp)
    800041b0:	0141                	addi	sp,sp,16
    800041b2:	8082                	ret

00000000800041b4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041b4:	457c                	lw	a5,76(a0)
    800041b6:	0ed7e963          	bltu	a5,a3,800042a8 <readi+0xf4>
{
    800041ba:	7159                	addi	sp,sp,-112
    800041bc:	f486                	sd	ra,104(sp)
    800041be:	f0a2                	sd	s0,96(sp)
    800041c0:	eca6                	sd	s1,88(sp)
    800041c2:	e8ca                	sd	s2,80(sp)
    800041c4:	e4ce                	sd	s3,72(sp)
    800041c6:	e0d2                	sd	s4,64(sp)
    800041c8:	fc56                	sd	s5,56(sp)
    800041ca:	f85a                	sd	s6,48(sp)
    800041cc:	f45e                	sd	s7,40(sp)
    800041ce:	f062                	sd	s8,32(sp)
    800041d0:	ec66                	sd	s9,24(sp)
    800041d2:	e86a                	sd	s10,16(sp)
    800041d4:	e46e                	sd	s11,8(sp)
    800041d6:	1880                	addi	s0,sp,112
    800041d8:	8baa                	mv	s7,a0
    800041da:	8c2e                	mv	s8,a1
    800041dc:	8ab2                	mv	s5,a2
    800041de:	84b6                	mv	s1,a3
    800041e0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800041e2:	9f35                	addw	a4,a4,a3
    return 0;
    800041e4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800041e6:	0ad76063          	bltu	a4,a3,80004286 <readi+0xd2>
  if(off + n > ip->size)
    800041ea:	00e7f463          	bgeu	a5,a4,800041f2 <readi+0x3e>
    n = ip->size - off;
    800041ee:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041f2:	0a0b0963          	beqz	s6,800042a4 <readi+0xf0>
    800041f6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041f8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800041fc:	5cfd                	li	s9,-1
    800041fe:	a82d                	j	80004238 <readi+0x84>
    80004200:	020a1d93          	slli	s11,s4,0x20
    80004204:	020ddd93          	srli	s11,s11,0x20
    80004208:	05890793          	addi	a5,s2,88
    8000420c:	86ee                	mv	a3,s11
    8000420e:	963e                	add	a2,a2,a5
    80004210:	85d6                	mv	a1,s5
    80004212:	8562                	mv	a0,s8
    80004214:	ffffe097          	auipc	ra,0xffffe
    80004218:	570080e7          	jalr	1392(ra) # 80002784 <either_copyout>
    8000421c:	05950d63          	beq	a0,s9,80004276 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004220:	854a                	mv	a0,s2
    80004222:	fffff097          	auipc	ra,0xfffff
    80004226:	60a080e7          	jalr	1546(ra) # 8000382c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000422a:	013a09bb          	addw	s3,s4,s3
    8000422e:	009a04bb          	addw	s1,s4,s1
    80004232:	9aee                	add	s5,s5,s11
    80004234:	0569f763          	bgeu	s3,s6,80004282 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004238:	000ba903          	lw	s2,0(s7)
    8000423c:	00a4d59b          	srliw	a1,s1,0xa
    80004240:	855e                	mv	a0,s7
    80004242:	00000097          	auipc	ra,0x0
    80004246:	8ae080e7          	jalr	-1874(ra) # 80003af0 <bmap>
    8000424a:	0005059b          	sext.w	a1,a0
    8000424e:	854a                	mv	a0,s2
    80004250:	fffff097          	auipc	ra,0xfffff
    80004254:	4ac080e7          	jalr	1196(ra) # 800036fc <bread>
    80004258:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000425a:	3ff4f613          	andi	a2,s1,1023
    8000425e:	40cd07bb          	subw	a5,s10,a2
    80004262:	413b073b          	subw	a4,s6,s3
    80004266:	8a3e                	mv	s4,a5
    80004268:	2781                	sext.w	a5,a5
    8000426a:	0007069b          	sext.w	a3,a4
    8000426e:	f8f6f9e3          	bgeu	a3,a5,80004200 <readi+0x4c>
    80004272:	8a3a                	mv	s4,a4
    80004274:	b771                	j	80004200 <readi+0x4c>
      brelse(bp);
    80004276:	854a                	mv	a0,s2
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	5b4080e7          	jalr	1460(ra) # 8000382c <brelse>
      tot = -1;
    80004280:	59fd                	li	s3,-1
  }
  return tot;
    80004282:	0009851b          	sext.w	a0,s3
}
    80004286:	70a6                	ld	ra,104(sp)
    80004288:	7406                	ld	s0,96(sp)
    8000428a:	64e6                	ld	s1,88(sp)
    8000428c:	6946                	ld	s2,80(sp)
    8000428e:	69a6                	ld	s3,72(sp)
    80004290:	6a06                	ld	s4,64(sp)
    80004292:	7ae2                	ld	s5,56(sp)
    80004294:	7b42                	ld	s6,48(sp)
    80004296:	7ba2                	ld	s7,40(sp)
    80004298:	7c02                	ld	s8,32(sp)
    8000429a:	6ce2                	ld	s9,24(sp)
    8000429c:	6d42                	ld	s10,16(sp)
    8000429e:	6da2                	ld	s11,8(sp)
    800042a0:	6165                	addi	sp,sp,112
    800042a2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042a4:	89da                	mv	s3,s6
    800042a6:	bff1                	j	80004282 <readi+0xce>
    return 0;
    800042a8:	4501                	li	a0,0
}
    800042aa:	8082                	ret

00000000800042ac <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800042ac:	457c                	lw	a5,76(a0)
    800042ae:	10d7e863          	bltu	a5,a3,800043be <writei+0x112>
{
    800042b2:	7159                	addi	sp,sp,-112
    800042b4:	f486                	sd	ra,104(sp)
    800042b6:	f0a2                	sd	s0,96(sp)
    800042b8:	eca6                	sd	s1,88(sp)
    800042ba:	e8ca                	sd	s2,80(sp)
    800042bc:	e4ce                	sd	s3,72(sp)
    800042be:	e0d2                	sd	s4,64(sp)
    800042c0:	fc56                	sd	s5,56(sp)
    800042c2:	f85a                	sd	s6,48(sp)
    800042c4:	f45e                	sd	s7,40(sp)
    800042c6:	f062                	sd	s8,32(sp)
    800042c8:	ec66                	sd	s9,24(sp)
    800042ca:	e86a                	sd	s10,16(sp)
    800042cc:	e46e                	sd	s11,8(sp)
    800042ce:	1880                	addi	s0,sp,112
    800042d0:	8b2a                	mv	s6,a0
    800042d2:	8c2e                	mv	s8,a1
    800042d4:	8ab2                	mv	s5,a2
    800042d6:	8936                	mv	s2,a3
    800042d8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800042da:	00e687bb          	addw	a5,a3,a4
    800042de:	0ed7e263          	bltu	a5,a3,800043c2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800042e2:	00043737          	lui	a4,0x43
    800042e6:	0ef76063          	bltu	a4,a5,800043c6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042ea:	0c0b8863          	beqz	s7,800043ba <writei+0x10e>
    800042ee:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800042f0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800042f4:	5cfd                	li	s9,-1
    800042f6:	a091                	j	8000433a <writei+0x8e>
    800042f8:	02099d93          	slli	s11,s3,0x20
    800042fc:	020ddd93          	srli	s11,s11,0x20
    80004300:	05848793          	addi	a5,s1,88
    80004304:	86ee                	mv	a3,s11
    80004306:	8656                	mv	a2,s5
    80004308:	85e2                	mv	a1,s8
    8000430a:	953e                	add	a0,a0,a5
    8000430c:	ffffe097          	auipc	ra,0xffffe
    80004310:	4ce080e7          	jalr	1230(ra) # 800027da <either_copyin>
    80004314:	07950263          	beq	a0,s9,80004378 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004318:	8526                	mv	a0,s1
    8000431a:	00000097          	auipc	ra,0x0
    8000431e:	794080e7          	jalr	1940(ra) # 80004aae <log_write>
    brelse(bp);
    80004322:	8526                	mv	a0,s1
    80004324:	fffff097          	auipc	ra,0xfffff
    80004328:	508080e7          	jalr	1288(ra) # 8000382c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000432c:	01498a3b          	addw	s4,s3,s4
    80004330:	0129893b          	addw	s2,s3,s2
    80004334:	9aee                	add	s5,s5,s11
    80004336:	057a7663          	bgeu	s4,s7,80004382 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000433a:	000b2483          	lw	s1,0(s6)
    8000433e:	00a9559b          	srliw	a1,s2,0xa
    80004342:	855a                	mv	a0,s6
    80004344:	fffff097          	auipc	ra,0xfffff
    80004348:	7ac080e7          	jalr	1964(ra) # 80003af0 <bmap>
    8000434c:	0005059b          	sext.w	a1,a0
    80004350:	8526                	mv	a0,s1
    80004352:	fffff097          	auipc	ra,0xfffff
    80004356:	3aa080e7          	jalr	938(ra) # 800036fc <bread>
    8000435a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000435c:	3ff97513          	andi	a0,s2,1023
    80004360:	40ad07bb          	subw	a5,s10,a0
    80004364:	414b873b          	subw	a4,s7,s4
    80004368:	89be                	mv	s3,a5
    8000436a:	2781                	sext.w	a5,a5
    8000436c:	0007069b          	sext.w	a3,a4
    80004370:	f8f6f4e3          	bgeu	a3,a5,800042f8 <writei+0x4c>
    80004374:	89ba                	mv	s3,a4
    80004376:	b749                	j	800042f8 <writei+0x4c>
      brelse(bp);
    80004378:	8526                	mv	a0,s1
    8000437a:	fffff097          	auipc	ra,0xfffff
    8000437e:	4b2080e7          	jalr	1202(ra) # 8000382c <brelse>
  }

  if(off > ip->size)
    80004382:	04cb2783          	lw	a5,76(s6)
    80004386:	0127f463          	bgeu	a5,s2,8000438e <writei+0xe2>
    ip->size = off;
    8000438a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000438e:	855a                	mv	a0,s6
    80004390:	00000097          	auipc	ra,0x0
    80004394:	aa6080e7          	jalr	-1370(ra) # 80003e36 <iupdate>

  return tot;
    80004398:	000a051b          	sext.w	a0,s4
}
    8000439c:	70a6                	ld	ra,104(sp)
    8000439e:	7406                	ld	s0,96(sp)
    800043a0:	64e6                	ld	s1,88(sp)
    800043a2:	6946                	ld	s2,80(sp)
    800043a4:	69a6                	ld	s3,72(sp)
    800043a6:	6a06                	ld	s4,64(sp)
    800043a8:	7ae2                	ld	s5,56(sp)
    800043aa:	7b42                	ld	s6,48(sp)
    800043ac:	7ba2                	ld	s7,40(sp)
    800043ae:	7c02                	ld	s8,32(sp)
    800043b0:	6ce2                	ld	s9,24(sp)
    800043b2:	6d42                	ld	s10,16(sp)
    800043b4:	6da2                	ld	s11,8(sp)
    800043b6:	6165                	addi	sp,sp,112
    800043b8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043ba:	8a5e                	mv	s4,s7
    800043bc:	bfc9                	j	8000438e <writei+0xe2>
    return -1;
    800043be:	557d                	li	a0,-1
}
    800043c0:	8082                	ret
    return -1;
    800043c2:	557d                	li	a0,-1
    800043c4:	bfe1                	j	8000439c <writei+0xf0>
    return -1;
    800043c6:	557d                	li	a0,-1
    800043c8:	bfd1                	j	8000439c <writei+0xf0>

00000000800043ca <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800043ca:	1141                	addi	sp,sp,-16
    800043cc:	e406                	sd	ra,8(sp)
    800043ce:	e022                	sd	s0,0(sp)
    800043d0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800043d2:	4639                	li	a2,14
    800043d4:	ffffd097          	auipc	ra,0xffffd
    800043d8:	9c2080e7          	jalr	-1598(ra) # 80000d96 <strncmp>
}
    800043dc:	60a2                	ld	ra,8(sp)
    800043de:	6402                	ld	s0,0(sp)
    800043e0:	0141                	addi	sp,sp,16
    800043e2:	8082                	ret

00000000800043e4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800043e4:	7139                	addi	sp,sp,-64
    800043e6:	fc06                	sd	ra,56(sp)
    800043e8:	f822                	sd	s0,48(sp)
    800043ea:	f426                	sd	s1,40(sp)
    800043ec:	f04a                	sd	s2,32(sp)
    800043ee:	ec4e                	sd	s3,24(sp)
    800043f0:	e852                	sd	s4,16(sp)
    800043f2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800043f4:	04451703          	lh	a4,68(a0)
    800043f8:	4785                	li	a5,1
    800043fa:	00f71a63          	bne	a4,a5,8000440e <dirlookup+0x2a>
    800043fe:	892a                	mv	s2,a0
    80004400:	89ae                	mv	s3,a1
    80004402:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004404:	457c                	lw	a5,76(a0)
    80004406:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004408:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000440a:	e79d                	bnez	a5,80004438 <dirlookup+0x54>
    8000440c:	a8a5                	j	80004484 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000440e:	00004517          	auipc	a0,0x4
    80004412:	40a50513          	addi	a0,a0,1034 # 80008818 <syscalls+0x1c0>
    80004416:	ffffc097          	auipc	ra,0xffffc
    8000441a:	114080e7          	jalr	276(ra) # 8000052a <panic>
      panic("dirlookup read");
    8000441e:	00004517          	auipc	a0,0x4
    80004422:	41250513          	addi	a0,a0,1042 # 80008830 <syscalls+0x1d8>
    80004426:	ffffc097          	auipc	ra,0xffffc
    8000442a:	104080e7          	jalr	260(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000442e:	24c1                	addiw	s1,s1,16
    80004430:	04c92783          	lw	a5,76(s2)
    80004434:	04f4f763          	bgeu	s1,a5,80004482 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004438:	4741                	li	a4,16
    8000443a:	86a6                	mv	a3,s1
    8000443c:	fc040613          	addi	a2,s0,-64
    80004440:	4581                	li	a1,0
    80004442:	854a                	mv	a0,s2
    80004444:	00000097          	auipc	ra,0x0
    80004448:	d70080e7          	jalr	-656(ra) # 800041b4 <readi>
    8000444c:	47c1                	li	a5,16
    8000444e:	fcf518e3          	bne	a0,a5,8000441e <dirlookup+0x3a>
    if(de.inum == 0)
    80004452:	fc045783          	lhu	a5,-64(s0)
    80004456:	dfe1                	beqz	a5,8000442e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004458:	fc240593          	addi	a1,s0,-62
    8000445c:	854e                	mv	a0,s3
    8000445e:	00000097          	auipc	ra,0x0
    80004462:	f6c080e7          	jalr	-148(ra) # 800043ca <namecmp>
    80004466:	f561                	bnez	a0,8000442e <dirlookup+0x4a>
      if(poff)
    80004468:	000a0463          	beqz	s4,80004470 <dirlookup+0x8c>
        *poff = off;
    8000446c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004470:	fc045583          	lhu	a1,-64(s0)
    80004474:	00092503          	lw	a0,0(s2)
    80004478:	fffff097          	auipc	ra,0xfffff
    8000447c:	754080e7          	jalr	1876(ra) # 80003bcc <iget>
    80004480:	a011                	j	80004484 <dirlookup+0xa0>
  return 0;
    80004482:	4501                	li	a0,0
}
    80004484:	70e2                	ld	ra,56(sp)
    80004486:	7442                	ld	s0,48(sp)
    80004488:	74a2                	ld	s1,40(sp)
    8000448a:	7902                	ld	s2,32(sp)
    8000448c:	69e2                	ld	s3,24(sp)
    8000448e:	6a42                	ld	s4,16(sp)
    80004490:	6121                	addi	sp,sp,64
    80004492:	8082                	ret

0000000080004494 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004494:	711d                	addi	sp,sp,-96
    80004496:	ec86                	sd	ra,88(sp)
    80004498:	e8a2                	sd	s0,80(sp)
    8000449a:	e4a6                	sd	s1,72(sp)
    8000449c:	e0ca                	sd	s2,64(sp)
    8000449e:	fc4e                	sd	s3,56(sp)
    800044a0:	f852                	sd	s4,48(sp)
    800044a2:	f456                	sd	s5,40(sp)
    800044a4:	f05a                	sd	s6,32(sp)
    800044a6:	ec5e                	sd	s7,24(sp)
    800044a8:	e862                	sd	s8,16(sp)
    800044aa:	e466                	sd	s9,8(sp)
    800044ac:	1080                	addi	s0,sp,96
    800044ae:	84aa                	mv	s1,a0
    800044b0:	8aae                	mv	s5,a1
    800044b2:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800044b4:	00054703          	lbu	a4,0(a0)
    800044b8:	02f00793          	li	a5,47
    800044bc:	02f70363          	beq	a4,a5,800044e2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800044c0:	ffffd097          	auipc	ra,0xffffd
    800044c4:	502080e7          	jalr	1282(ra) # 800019c2 <myproc>
    800044c8:	17853503          	ld	a0,376(a0)
    800044cc:	00000097          	auipc	ra,0x0
    800044d0:	9f6080e7          	jalr	-1546(ra) # 80003ec2 <idup>
    800044d4:	89aa                	mv	s3,a0
  while(*path == '/')
    800044d6:	02f00913          	li	s2,47
  len = path - s;
    800044da:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800044dc:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800044de:	4b85                	li	s7,1
    800044e0:	a865                	j	80004598 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800044e2:	4585                	li	a1,1
    800044e4:	4505                	li	a0,1
    800044e6:	fffff097          	auipc	ra,0xfffff
    800044ea:	6e6080e7          	jalr	1766(ra) # 80003bcc <iget>
    800044ee:	89aa                	mv	s3,a0
    800044f0:	b7dd                	j	800044d6 <namex+0x42>
      iunlockput(ip);
    800044f2:	854e                	mv	a0,s3
    800044f4:	00000097          	auipc	ra,0x0
    800044f8:	c6e080e7          	jalr	-914(ra) # 80004162 <iunlockput>
      return 0;
    800044fc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800044fe:	854e                	mv	a0,s3
    80004500:	60e6                	ld	ra,88(sp)
    80004502:	6446                	ld	s0,80(sp)
    80004504:	64a6                	ld	s1,72(sp)
    80004506:	6906                	ld	s2,64(sp)
    80004508:	79e2                	ld	s3,56(sp)
    8000450a:	7a42                	ld	s4,48(sp)
    8000450c:	7aa2                	ld	s5,40(sp)
    8000450e:	7b02                	ld	s6,32(sp)
    80004510:	6be2                	ld	s7,24(sp)
    80004512:	6c42                	ld	s8,16(sp)
    80004514:	6ca2                	ld	s9,8(sp)
    80004516:	6125                	addi	sp,sp,96
    80004518:	8082                	ret
      iunlock(ip);
    8000451a:	854e                	mv	a0,s3
    8000451c:	00000097          	auipc	ra,0x0
    80004520:	aa6080e7          	jalr	-1370(ra) # 80003fc2 <iunlock>
      return ip;
    80004524:	bfe9                	j	800044fe <namex+0x6a>
      iunlockput(ip);
    80004526:	854e                	mv	a0,s3
    80004528:	00000097          	auipc	ra,0x0
    8000452c:	c3a080e7          	jalr	-966(ra) # 80004162 <iunlockput>
      return 0;
    80004530:	89e6                	mv	s3,s9
    80004532:	b7f1                	j	800044fe <namex+0x6a>
  len = path - s;
    80004534:	40b48633          	sub	a2,s1,a1
    80004538:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000453c:	099c5463          	bge	s8,s9,800045c4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004540:	4639                	li	a2,14
    80004542:	8552                	mv	a0,s4
    80004544:	ffffc097          	auipc	ra,0xffffc
    80004548:	7d6080e7          	jalr	2006(ra) # 80000d1a <memmove>
  while(*path == '/')
    8000454c:	0004c783          	lbu	a5,0(s1)
    80004550:	01279763          	bne	a5,s2,8000455e <namex+0xca>
    path++;
    80004554:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004556:	0004c783          	lbu	a5,0(s1)
    8000455a:	ff278de3          	beq	a5,s2,80004554 <namex+0xc0>
    ilock(ip);
    8000455e:	854e                	mv	a0,s3
    80004560:	00000097          	auipc	ra,0x0
    80004564:	9a0080e7          	jalr	-1632(ra) # 80003f00 <ilock>
    if(ip->type != T_DIR){
    80004568:	04499783          	lh	a5,68(s3)
    8000456c:	f97793e3          	bne	a5,s7,800044f2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004570:	000a8563          	beqz	s5,8000457a <namex+0xe6>
    80004574:	0004c783          	lbu	a5,0(s1)
    80004578:	d3cd                	beqz	a5,8000451a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000457a:	865a                	mv	a2,s6
    8000457c:	85d2                	mv	a1,s4
    8000457e:	854e                	mv	a0,s3
    80004580:	00000097          	auipc	ra,0x0
    80004584:	e64080e7          	jalr	-412(ra) # 800043e4 <dirlookup>
    80004588:	8caa                	mv	s9,a0
    8000458a:	dd51                	beqz	a0,80004526 <namex+0x92>
    iunlockput(ip);
    8000458c:	854e                	mv	a0,s3
    8000458e:	00000097          	auipc	ra,0x0
    80004592:	bd4080e7          	jalr	-1068(ra) # 80004162 <iunlockput>
    ip = next;
    80004596:	89e6                	mv	s3,s9
  while(*path == '/')
    80004598:	0004c783          	lbu	a5,0(s1)
    8000459c:	05279763          	bne	a5,s2,800045ea <namex+0x156>
    path++;
    800045a0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800045a2:	0004c783          	lbu	a5,0(s1)
    800045a6:	ff278de3          	beq	a5,s2,800045a0 <namex+0x10c>
  if(*path == 0)
    800045aa:	c79d                	beqz	a5,800045d8 <namex+0x144>
    path++;
    800045ac:	85a6                	mv	a1,s1
  len = path - s;
    800045ae:	8cda                	mv	s9,s6
    800045b0:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800045b2:	01278963          	beq	a5,s2,800045c4 <namex+0x130>
    800045b6:	dfbd                	beqz	a5,80004534 <namex+0xa0>
    path++;
    800045b8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800045ba:	0004c783          	lbu	a5,0(s1)
    800045be:	ff279ce3          	bne	a5,s2,800045b6 <namex+0x122>
    800045c2:	bf8d                	j	80004534 <namex+0xa0>
    memmove(name, s, len);
    800045c4:	2601                	sext.w	a2,a2
    800045c6:	8552                	mv	a0,s4
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	752080e7          	jalr	1874(ra) # 80000d1a <memmove>
    name[len] = 0;
    800045d0:	9cd2                	add	s9,s9,s4
    800045d2:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800045d6:	bf9d                	j	8000454c <namex+0xb8>
  if(nameiparent){
    800045d8:	f20a83e3          	beqz	s5,800044fe <namex+0x6a>
    iput(ip);
    800045dc:	854e                	mv	a0,s3
    800045de:	00000097          	auipc	ra,0x0
    800045e2:	adc080e7          	jalr	-1316(ra) # 800040ba <iput>
    return 0;
    800045e6:	4981                	li	s3,0
    800045e8:	bf19                	j	800044fe <namex+0x6a>
  if(*path == 0)
    800045ea:	d7fd                	beqz	a5,800045d8 <namex+0x144>
  while(*path != '/' && *path != 0)
    800045ec:	0004c783          	lbu	a5,0(s1)
    800045f0:	85a6                	mv	a1,s1
    800045f2:	b7d1                	j	800045b6 <namex+0x122>

00000000800045f4 <dirlink>:
{
    800045f4:	7139                	addi	sp,sp,-64
    800045f6:	fc06                	sd	ra,56(sp)
    800045f8:	f822                	sd	s0,48(sp)
    800045fa:	f426                	sd	s1,40(sp)
    800045fc:	f04a                	sd	s2,32(sp)
    800045fe:	ec4e                	sd	s3,24(sp)
    80004600:	e852                	sd	s4,16(sp)
    80004602:	0080                	addi	s0,sp,64
    80004604:	892a                	mv	s2,a0
    80004606:	8a2e                	mv	s4,a1
    80004608:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000460a:	4601                	li	a2,0
    8000460c:	00000097          	auipc	ra,0x0
    80004610:	dd8080e7          	jalr	-552(ra) # 800043e4 <dirlookup>
    80004614:	e93d                	bnez	a0,8000468a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004616:	04c92483          	lw	s1,76(s2)
    8000461a:	c49d                	beqz	s1,80004648 <dirlink+0x54>
    8000461c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000461e:	4741                	li	a4,16
    80004620:	86a6                	mv	a3,s1
    80004622:	fc040613          	addi	a2,s0,-64
    80004626:	4581                	li	a1,0
    80004628:	854a                	mv	a0,s2
    8000462a:	00000097          	auipc	ra,0x0
    8000462e:	b8a080e7          	jalr	-1142(ra) # 800041b4 <readi>
    80004632:	47c1                	li	a5,16
    80004634:	06f51163          	bne	a0,a5,80004696 <dirlink+0xa2>
    if(de.inum == 0)
    80004638:	fc045783          	lhu	a5,-64(s0)
    8000463c:	c791                	beqz	a5,80004648 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000463e:	24c1                	addiw	s1,s1,16
    80004640:	04c92783          	lw	a5,76(s2)
    80004644:	fcf4ede3          	bltu	s1,a5,8000461e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004648:	4639                	li	a2,14
    8000464a:	85d2                	mv	a1,s4
    8000464c:	fc240513          	addi	a0,s0,-62
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	782080e7          	jalr	1922(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004658:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000465c:	4741                	li	a4,16
    8000465e:	86a6                	mv	a3,s1
    80004660:	fc040613          	addi	a2,s0,-64
    80004664:	4581                	li	a1,0
    80004666:	854a                	mv	a0,s2
    80004668:	00000097          	auipc	ra,0x0
    8000466c:	c44080e7          	jalr	-956(ra) # 800042ac <writei>
    80004670:	872a                	mv	a4,a0
    80004672:	47c1                	li	a5,16
  return 0;
    80004674:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004676:	02f71863          	bne	a4,a5,800046a6 <dirlink+0xb2>
}
    8000467a:	70e2                	ld	ra,56(sp)
    8000467c:	7442                	ld	s0,48(sp)
    8000467e:	74a2                	ld	s1,40(sp)
    80004680:	7902                	ld	s2,32(sp)
    80004682:	69e2                	ld	s3,24(sp)
    80004684:	6a42                	ld	s4,16(sp)
    80004686:	6121                	addi	sp,sp,64
    80004688:	8082                	ret
    iput(ip);
    8000468a:	00000097          	auipc	ra,0x0
    8000468e:	a30080e7          	jalr	-1488(ra) # 800040ba <iput>
    return -1;
    80004692:	557d                	li	a0,-1
    80004694:	b7dd                	j	8000467a <dirlink+0x86>
      panic("dirlink read");
    80004696:	00004517          	auipc	a0,0x4
    8000469a:	1aa50513          	addi	a0,a0,426 # 80008840 <syscalls+0x1e8>
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	e8c080e7          	jalr	-372(ra) # 8000052a <panic>
    panic("dirlink");
    800046a6:	00004517          	auipc	a0,0x4
    800046aa:	2a250513          	addi	a0,a0,674 # 80008948 <syscalls+0x2f0>
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	e7c080e7          	jalr	-388(ra) # 8000052a <panic>

00000000800046b6 <namei>:

struct inode*
namei(char *path)
{
    800046b6:	1101                	addi	sp,sp,-32
    800046b8:	ec06                	sd	ra,24(sp)
    800046ba:	e822                	sd	s0,16(sp)
    800046bc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800046be:	fe040613          	addi	a2,s0,-32
    800046c2:	4581                	li	a1,0
    800046c4:	00000097          	auipc	ra,0x0
    800046c8:	dd0080e7          	jalr	-560(ra) # 80004494 <namex>
}
    800046cc:	60e2                	ld	ra,24(sp)
    800046ce:	6442                	ld	s0,16(sp)
    800046d0:	6105                	addi	sp,sp,32
    800046d2:	8082                	ret

00000000800046d4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800046d4:	1141                	addi	sp,sp,-16
    800046d6:	e406                	sd	ra,8(sp)
    800046d8:	e022                	sd	s0,0(sp)
    800046da:	0800                	addi	s0,sp,16
    800046dc:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800046de:	4585                	li	a1,1
    800046e0:	00000097          	auipc	ra,0x0
    800046e4:	db4080e7          	jalr	-588(ra) # 80004494 <namex>
}
    800046e8:	60a2                	ld	ra,8(sp)
    800046ea:	6402                	ld	s0,0(sp)
    800046ec:	0141                	addi	sp,sp,16
    800046ee:	8082                	ret

00000000800046f0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800046f0:	1101                	addi	sp,sp,-32
    800046f2:	ec06                	sd	ra,24(sp)
    800046f4:	e822                	sd	s0,16(sp)
    800046f6:	e426                	sd	s1,8(sp)
    800046f8:	e04a                	sd	s2,0(sp)
    800046fa:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800046fc:	0001d917          	auipc	s2,0x1d
    80004700:	58c90913          	addi	s2,s2,1420 # 80021c88 <log>
    80004704:	01892583          	lw	a1,24(s2)
    80004708:	02892503          	lw	a0,40(s2)
    8000470c:	fffff097          	auipc	ra,0xfffff
    80004710:	ff0080e7          	jalr	-16(ra) # 800036fc <bread>
    80004714:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004716:	02c92683          	lw	a3,44(s2)
    8000471a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000471c:	02d05863          	blez	a3,8000474c <write_head+0x5c>
    80004720:	0001d797          	auipc	a5,0x1d
    80004724:	59878793          	addi	a5,a5,1432 # 80021cb8 <log+0x30>
    80004728:	05c50713          	addi	a4,a0,92
    8000472c:	36fd                	addiw	a3,a3,-1
    8000472e:	02069613          	slli	a2,a3,0x20
    80004732:	01e65693          	srli	a3,a2,0x1e
    80004736:	0001d617          	auipc	a2,0x1d
    8000473a:	58660613          	addi	a2,a2,1414 # 80021cbc <log+0x34>
    8000473e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004740:	4390                	lw	a2,0(a5)
    80004742:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004744:	0791                	addi	a5,a5,4
    80004746:	0711                	addi	a4,a4,4
    80004748:	fed79ce3          	bne	a5,a3,80004740 <write_head+0x50>
  }
  bwrite(buf);
    8000474c:	8526                	mv	a0,s1
    8000474e:	fffff097          	auipc	ra,0xfffff
    80004752:	0a0080e7          	jalr	160(ra) # 800037ee <bwrite>
  brelse(buf);
    80004756:	8526                	mv	a0,s1
    80004758:	fffff097          	auipc	ra,0xfffff
    8000475c:	0d4080e7          	jalr	212(ra) # 8000382c <brelse>
}
    80004760:	60e2                	ld	ra,24(sp)
    80004762:	6442                	ld	s0,16(sp)
    80004764:	64a2                	ld	s1,8(sp)
    80004766:	6902                	ld	s2,0(sp)
    80004768:	6105                	addi	sp,sp,32
    8000476a:	8082                	ret

000000008000476c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000476c:	0001d797          	auipc	a5,0x1d
    80004770:	5487a783          	lw	a5,1352(a5) # 80021cb4 <log+0x2c>
    80004774:	0af05d63          	blez	a5,8000482e <install_trans+0xc2>
{
    80004778:	7139                	addi	sp,sp,-64
    8000477a:	fc06                	sd	ra,56(sp)
    8000477c:	f822                	sd	s0,48(sp)
    8000477e:	f426                	sd	s1,40(sp)
    80004780:	f04a                	sd	s2,32(sp)
    80004782:	ec4e                	sd	s3,24(sp)
    80004784:	e852                	sd	s4,16(sp)
    80004786:	e456                	sd	s5,8(sp)
    80004788:	e05a                	sd	s6,0(sp)
    8000478a:	0080                	addi	s0,sp,64
    8000478c:	8b2a                	mv	s6,a0
    8000478e:	0001da97          	auipc	s5,0x1d
    80004792:	52aa8a93          	addi	s5,s5,1322 # 80021cb8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004796:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004798:	0001d997          	auipc	s3,0x1d
    8000479c:	4f098993          	addi	s3,s3,1264 # 80021c88 <log>
    800047a0:	a00d                	j	800047c2 <install_trans+0x56>
    brelse(lbuf);
    800047a2:	854a                	mv	a0,s2
    800047a4:	fffff097          	auipc	ra,0xfffff
    800047a8:	088080e7          	jalr	136(ra) # 8000382c <brelse>
    brelse(dbuf);
    800047ac:	8526                	mv	a0,s1
    800047ae:	fffff097          	auipc	ra,0xfffff
    800047b2:	07e080e7          	jalr	126(ra) # 8000382c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047b6:	2a05                	addiw	s4,s4,1
    800047b8:	0a91                	addi	s5,s5,4
    800047ba:	02c9a783          	lw	a5,44(s3)
    800047be:	04fa5e63          	bge	s4,a5,8000481a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800047c2:	0189a583          	lw	a1,24(s3)
    800047c6:	014585bb          	addw	a1,a1,s4
    800047ca:	2585                	addiw	a1,a1,1
    800047cc:	0289a503          	lw	a0,40(s3)
    800047d0:	fffff097          	auipc	ra,0xfffff
    800047d4:	f2c080e7          	jalr	-212(ra) # 800036fc <bread>
    800047d8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800047da:	000aa583          	lw	a1,0(s5)
    800047de:	0289a503          	lw	a0,40(s3)
    800047e2:	fffff097          	auipc	ra,0xfffff
    800047e6:	f1a080e7          	jalr	-230(ra) # 800036fc <bread>
    800047ea:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800047ec:	40000613          	li	a2,1024
    800047f0:	05890593          	addi	a1,s2,88
    800047f4:	05850513          	addi	a0,a0,88
    800047f8:	ffffc097          	auipc	ra,0xffffc
    800047fc:	522080e7          	jalr	1314(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004800:	8526                	mv	a0,s1
    80004802:	fffff097          	auipc	ra,0xfffff
    80004806:	fec080e7          	jalr	-20(ra) # 800037ee <bwrite>
    if(recovering == 0)
    8000480a:	f80b1ce3          	bnez	s6,800047a2 <install_trans+0x36>
      bunpin(dbuf);
    8000480e:	8526                	mv	a0,s1
    80004810:	fffff097          	auipc	ra,0xfffff
    80004814:	0f6080e7          	jalr	246(ra) # 80003906 <bunpin>
    80004818:	b769                	j	800047a2 <install_trans+0x36>
}
    8000481a:	70e2                	ld	ra,56(sp)
    8000481c:	7442                	ld	s0,48(sp)
    8000481e:	74a2                	ld	s1,40(sp)
    80004820:	7902                	ld	s2,32(sp)
    80004822:	69e2                	ld	s3,24(sp)
    80004824:	6a42                	ld	s4,16(sp)
    80004826:	6aa2                	ld	s5,8(sp)
    80004828:	6b02                	ld	s6,0(sp)
    8000482a:	6121                	addi	sp,sp,64
    8000482c:	8082                	ret
    8000482e:	8082                	ret

0000000080004830 <initlog>:
{
    80004830:	7179                	addi	sp,sp,-48
    80004832:	f406                	sd	ra,40(sp)
    80004834:	f022                	sd	s0,32(sp)
    80004836:	ec26                	sd	s1,24(sp)
    80004838:	e84a                	sd	s2,16(sp)
    8000483a:	e44e                	sd	s3,8(sp)
    8000483c:	1800                	addi	s0,sp,48
    8000483e:	892a                	mv	s2,a0
    80004840:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004842:	0001d497          	auipc	s1,0x1d
    80004846:	44648493          	addi	s1,s1,1094 # 80021c88 <log>
    8000484a:	00004597          	auipc	a1,0x4
    8000484e:	00658593          	addi	a1,a1,6 # 80008850 <syscalls+0x1f8>
    80004852:	8526                	mv	a0,s1
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	2de080e7          	jalr	734(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    8000485c:	0149a583          	lw	a1,20(s3)
    80004860:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004862:	0109a783          	lw	a5,16(s3)
    80004866:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004868:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000486c:	854a                	mv	a0,s2
    8000486e:	fffff097          	auipc	ra,0xfffff
    80004872:	e8e080e7          	jalr	-370(ra) # 800036fc <bread>
  log.lh.n = lh->n;
    80004876:	4d34                	lw	a3,88(a0)
    80004878:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000487a:	02d05663          	blez	a3,800048a6 <initlog+0x76>
    8000487e:	05c50793          	addi	a5,a0,92
    80004882:	0001d717          	auipc	a4,0x1d
    80004886:	43670713          	addi	a4,a4,1078 # 80021cb8 <log+0x30>
    8000488a:	36fd                	addiw	a3,a3,-1
    8000488c:	02069613          	slli	a2,a3,0x20
    80004890:	01e65693          	srli	a3,a2,0x1e
    80004894:	06050613          	addi	a2,a0,96
    80004898:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000489a:	4390                	lw	a2,0(a5)
    8000489c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000489e:	0791                	addi	a5,a5,4
    800048a0:	0711                	addi	a4,a4,4
    800048a2:	fed79ce3          	bne	a5,a3,8000489a <initlog+0x6a>
  brelse(buf);
    800048a6:	fffff097          	auipc	ra,0xfffff
    800048aa:	f86080e7          	jalr	-122(ra) # 8000382c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800048ae:	4505                	li	a0,1
    800048b0:	00000097          	auipc	ra,0x0
    800048b4:	ebc080e7          	jalr	-324(ra) # 8000476c <install_trans>
  log.lh.n = 0;
    800048b8:	0001d797          	auipc	a5,0x1d
    800048bc:	3e07ae23          	sw	zero,1020(a5) # 80021cb4 <log+0x2c>
  write_head(); // clear the log
    800048c0:	00000097          	auipc	ra,0x0
    800048c4:	e30080e7          	jalr	-464(ra) # 800046f0 <write_head>
}
    800048c8:	70a2                	ld	ra,40(sp)
    800048ca:	7402                	ld	s0,32(sp)
    800048cc:	64e2                	ld	s1,24(sp)
    800048ce:	6942                	ld	s2,16(sp)
    800048d0:	69a2                	ld	s3,8(sp)
    800048d2:	6145                	addi	sp,sp,48
    800048d4:	8082                	ret

00000000800048d6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800048d6:	1101                	addi	sp,sp,-32
    800048d8:	ec06                	sd	ra,24(sp)
    800048da:	e822                	sd	s0,16(sp)
    800048dc:	e426                	sd	s1,8(sp)
    800048de:	e04a                	sd	s2,0(sp)
    800048e0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800048e2:	0001d517          	auipc	a0,0x1d
    800048e6:	3a650513          	addi	a0,a0,934 # 80021c88 <log>
    800048ea:	ffffc097          	auipc	ra,0xffffc
    800048ee:	2d8080e7          	jalr	728(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800048f2:	0001d497          	auipc	s1,0x1d
    800048f6:	39648493          	addi	s1,s1,918 # 80021c88 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048fa:	4979                	li	s2,30
    800048fc:	a039                	j	8000490a <begin_op+0x34>
      sleep(&log, &log.lock);
    800048fe:	85a6                	mv	a1,s1
    80004900:	8526                	mv	a0,s1
    80004902:	ffffe097          	auipc	ra,0xffffe
    80004906:	ad4080e7          	jalr	-1324(ra) # 800023d6 <sleep>
    if(log.committing){
    8000490a:	50dc                	lw	a5,36(s1)
    8000490c:	fbed                	bnez	a5,800048fe <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000490e:	509c                	lw	a5,32(s1)
    80004910:	0017871b          	addiw	a4,a5,1
    80004914:	0007069b          	sext.w	a3,a4
    80004918:	0027179b          	slliw	a5,a4,0x2
    8000491c:	9fb9                	addw	a5,a5,a4
    8000491e:	0017979b          	slliw	a5,a5,0x1
    80004922:	54d8                	lw	a4,44(s1)
    80004924:	9fb9                	addw	a5,a5,a4
    80004926:	00f95963          	bge	s2,a5,80004938 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000492a:	85a6                	mv	a1,s1
    8000492c:	8526                	mv	a0,s1
    8000492e:	ffffe097          	auipc	ra,0xffffe
    80004932:	aa8080e7          	jalr	-1368(ra) # 800023d6 <sleep>
    80004936:	bfd1                	j	8000490a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004938:	0001d517          	auipc	a0,0x1d
    8000493c:	35050513          	addi	a0,a0,848 # 80021c88 <log>
    80004940:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	334080e7          	jalr	820(ra) # 80000c76 <release>
      break;
    }
  }
}
    8000494a:	60e2                	ld	ra,24(sp)
    8000494c:	6442                	ld	s0,16(sp)
    8000494e:	64a2                	ld	s1,8(sp)
    80004950:	6902                	ld	s2,0(sp)
    80004952:	6105                	addi	sp,sp,32
    80004954:	8082                	ret

0000000080004956 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004956:	7139                	addi	sp,sp,-64
    80004958:	fc06                	sd	ra,56(sp)
    8000495a:	f822                	sd	s0,48(sp)
    8000495c:	f426                	sd	s1,40(sp)
    8000495e:	f04a                	sd	s2,32(sp)
    80004960:	ec4e                	sd	s3,24(sp)
    80004962:	e852                	sd	s4,16(sp)
    80004964:	e456                	sd	s5,8(sp)
    80004966:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004968:	0001d497          	auipc	s1,0x1d
    8000496c:	32048493          	addi	s1,s1,800 # 80021c88 <log>
    80004970:	8526                	mv	a0,s1
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	250080e7          	jalr	592(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    8000497a:	509c                	lw	a5,32(s1)
    8000497c:	37fd                	addiw	a5,a5,-1
    8000497e:	0007891b          	sext.w	s2,a5
    80004982:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004984:	50dc                	lw	a5,36(s1)
    80004986:	e7b9                	bnez	a5,800049d4 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004988:	04091e63          	bnez	s2,800049e4 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000498c:	0001d497          	auipc	s1,0x1d
    80004990:	2fc48493          	addi	s1,s1,764 # 80021c88 <log>
    80004994:	4785                	li	a5,1
    80004996:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004998:	8526                	mv	a0,s1
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	2dc080e7          	jalr	732(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800049a2:	54dc                	lw	a5,44(s1)
    800049a4:	06f04763          	bgtz	a5,80004a12 <end_op+0xbc>
    acquire(&log.lock);
    800049a8:	0001d497          	auipc	s1,0x1d
    800049ac:	2e048493          	addi	s1,s1,736 # 80021c88 <log>
    800049b0:	8526                	mv	a0,s1
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	210080e7          	jalr	528(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800049ba:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800049be:	8526                	mv	a0,s1
    800049c0:	ffffe097          	auipc	ra,0xffffe
    800049c4:	ba2080e7          	jalr	-1118(ra) # 80002562 <wakeup>
    release(&log.lock);
    800049c8:	8526                	mv	a0,s1
    800049ca:	ffffc097          	auipc	ra,0xffffc
    800049ce:	2ac080e7          	jalr	684(ra) # 80000c76 <release>
}
    800049d2:	a03d                	j	80004a00 <end_op+0xaa>
    panic("log.committing");
    800049d4:	00004517          	auipc	a0,0x4
    800049d8:	e8450513          	addi	a0,a0,-380 # 80008858 <syscalls+0x200>
    800049dc:	ffffc097          	auipc	ra,0xffffc
    800049e0:	b4e080e7          	jalr	-1202(ra) # 8000052a <panic>
    wakeup(&log);
    800049e4:	0001d497          	auipc	s1,0x1d
    800049e8:	2a448493          	addi	s1,s1,676 # 80021c88 <log>
    800049ec:	8526                	mv	a0,s1
    800049ee:	ffffe097          	auipc	ra,0xffffe
    800049f2:	b74080e7          	jalr	-1164(ra) # 80002562 <wakeup>
  release(&log.lock);
    800049f6:	8526                	mv	a0,s1
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	27e080e7          	jalr	638(ra) # 80000c76 <release>
}
    80004a00:	70e2                	ld	ra,56(sp)
    80004a02:	7442                	ld	s0,48(sp)
    80004a04:	74a2                	ld	s1,40(sp)
    80004a06:	7902                	ld	s2,32(sp)
    80004a08:	69e2                	ld	s3,24(sp)
    80004a0a:	6a42                	ld	s4,16(sp)
    80004a0c:	6aa2                	ld	s5,8(sp)
    80004a0e:	6121                	addi	sp,sp,64
    80004a10:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a12:	0001da97          	auipc	s5,0x1d
    80004a16:	2a6a8a93          	addi	s5,s5,678 # 80021cb8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004a1a:	0001da17          	auipc	s4,0x1d
    80004a1e:	26ea0a13          	addi	s4,s4,622 # 80021c88 <log>
    80004a22:	018a2583          	lw	a1,24(s4)
    80004a26:	012585bb          	addw	a1,a1,s2
    80004a2a:	2585                	addiw	a1,a1,1
    80004a2c:	028a2503          	lw	a0,40(s4)
    80004a30:	fffff097          	auipc	ra,0xfffff
    80004a34:	ccc080e7          	jalr	-820(ra) # 800036fc <bread>
    80004a38:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004a3a:	000aa583          	lw	a1,0(s5)
    80004a3e:	028a2503          	lw	a0,40(s4)
    80004a42:	fffff097          	auipc	ra,0xfffff
    80004a46:	cba080e7          	jalr	-838(ra) # 800036fc <bread>
    80004a4a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004a4c:	40000613          	li	a2,1024
    80004a50:	05850593          	addi	a1,a0,88
    80004a54:	05848513          	addi	a0,s1,88
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	2c2080e7          	jalr	706(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004a60:	8526                	mv	a0,s1
    80004a62:	fffff097          	auipc	ra,0xfffff
    80004a66:	d8c080e7          	jalr	-628(ra) # 800037ee <bwrite>
    brelse(from);
    80004a6a:	854e                	mv	a0,s3
    80004a6c:	fffff097          	auipc	ra,0xfffff
    80004a70:	dc0080e7          	jalr	-576(ra) # 8000382c <brelse>
    brelse(to);
    80004a74:	8526                	mv	a0,s1
    80004a76:	fffff097          	auipc	ra,0xfffff
    80004a7a:	db6080e7          	jalr	-586(ra) # 8000382c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a7e:	2905                	addiw	s2,s2,1
    80004a80:	0a91                	addi	s5,s5,4
    80004a82:	02ca2783          	lw	a5,44(s4)
    80004a86:	f8f94ee3          	blt	s2,a5,80004a22 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a8a:	00000097          	auipc	ra,0x0
    80004a8e:	c66080e7          	jalr	-922(ra) # 800046f0 <write_head>
    install_trans(0); // Now install writes to home locations
    80004a92:	4501                	li	a0,0
    80004a94:	00000097          	auipc	ra,0x0
    80004a98:	cd8080e7          	jalr	-808(ra) # 8000476c <install_trans>
    log.lh.n = 0;
    80004a9c:	0001d797          	auipc	a5,0x1d
    80004aa0:	2007ac23          	sw	zero,536(a5) # 80021cb4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004aa4:	00000097          	auipc	ra,0x0
    80004aa8:	c4c080e7          	jalr	-948(ra) # 800046f0 <write_head>
    80004aac:	bdf5                	j	800049a8 <end_op+0x52>

0000000080004aae <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004aae:	1101                	addi	sp,sp,-32
    80004ab0:	ec06                	sd	ra,24(sp)
    80004ab2:	e822                	sd	s0,16(sp)
    80004ab4:	e426                	sd	s1,8(sp)
    80004ab6:	e04a                	sd	s2,0(sp)
    80004ab8:	1000                	addi	s0,sp,32
    80004aba:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004abc:	0001d917          	auipc	s2,0x1d
    80004ac0:	1cc90913          	addi	s2,s2,460 # 80021c88 <log>
    80004ac4:	854a                	mv	a0,s2
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	0fc080e7          	jalr	252(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004ace:	02c92603          	lw	a2,44(s2)
    80004ad2:	47f5                	li	a5,29
    80004ad4:	06c7c563          	blt	a5,a2,80004b3e <log_write+0x90>
    80004ad8:	0001d797          	auipc	a5,0x1d
    80004adc:	1cc7a783          	lw	a5,460(a5) # 80021ca4 <log+0x1c>
    80004ae0:	37fd                	addiw	a5,a5,-1
    80004ae2:	04f65e63          	bge	a2,a5,80004b3e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004ae6:	0001d797          	auipc	a5,0x1d
    80004aea:	1c27a783          	lw	a5,450(a5) # 80021ca8 <log+0x20>
    80004aee:	06f05063          	blez	a5,80004b4e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004af2:	4781                	li	a5,0
    80004af4:	06c05563          	blez	a2,80004b5e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004af8:	44cc                	lw	a1,12(s1)
    80004afa:	0001d717          	auipc	a4,0x1d
    80004afe:	1be70713          	addi	a4,a4,446 # 80021cb8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004b02:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004b04:	4314                	lw	a3,0(a4)
    80004b06:	04b68c63          	beq	a3,a1,80004b5e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004b0a:	2785                	addiw	a5,a5,1
    80004b0c:	0711                	addi	a4,a4,4
    80004b0e:	fef61be3          	bne	a2,a5,80004b04 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004b12:	0621                	addi	a2,a2,8
    80004b14:	060a                	slli	a2,a2,0x2
    80004b16:	0001d797          	auipc	a5,0x1d
    80004b1a:	17278793          	addi	a5,a5,370 # 80021c88 <log>
    80004b1e:	963e                	add	a2,a2,a5
    80004b20:	44dc                	lw	a5,12(s1)
    80004b22:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004b24:	8526                	mv	a0,s1
    80004b26:	fffff097          	auipc	ra,0xfffff
    80004b2a:	da4080e7          	jalr	-604(ra) # 800038ca <bpin>
    log.lh.n++;
    80004b2e:	0001d717          	auipc	a4,0x1d
    80004b32:	15a70713          	addi	a4,a4,346 # 80021c88 <log>
    80004b36:	575c                	lw	a5,44(a4)
    80004b38:	2785                	addiw	a5,a5,1
    80004b3a:	d75c                	sw	a5,44(a4)
    80004b3c:	a835                	j	80004b78 <log_write+0xca>
    panic("too big a transaction");
    80004b3e:	00004517          	auipc	a0,0x4
    80004b42:	d2a50513          	addi	a0,a0,-726 # 80008868 <syscalls+0x210>
    80004b46:	ffffc097          	auipc	ra,0xffffc
    80004b4a:	9e4080e7          	jalr	-1564(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004b4e:	00004517          	auipc	a0,0x4
    80004b52:	d3250513          	addi	a0,a0,-718 # 80008880 <syscalls+0x228>
    80004b56:	ffffc097          	auipc	ra,0xffffc
    80004b5a:	9d4080e7          	jalr	-1580(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004b5e:	00878713          	addi	a4,a5,8
    80004b62:	00271693          	slli	a3,a4,0x2
    80004b66:	0001d717          	auipc	a4,0x1d
    80004b6a:	12270713          	addi	a4,a4,290 # 80021c88 <log>
    80004b6e:	9736                	add	a4,a4,a3
    80004b70:	44d4                	lw	a3,12(s1)
    80004b72:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004b74:	faf608e3          	beq	a2,a5,80004b24 <log_write+0x76>
  }
  release(&log.lock);
    80004b78:	0001d517          	auipc	a0,0x1d
    80004b7c:	11050513          	addi	a0,a0,272 # 80021c88 <log>
    80004b80:	ffffc097          	auipc	ra,0xffffc
    80004b84:	0f6080e7          	jalr	246(ra) # 80000c76 <release>
}
    80004b88:	60e2                	ld	ra,24(sp)
    80004b8a:	6442                	ld	s0,16(sp)
    80004b8c:	64a2                	ld	s1,8(sp)
    80004b8e:	6902                	ld	s2,0(sp)
    80004b90:	6105                	addi	sp,sp,32
    80004b92:	8082                	ret

0000000080004b94 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004b94:	1101                	addi	sp,sp,-32
    80004b96:	ec06                	sd	ra,24(sp)
    80004b98:	e822                	sd	s0,16(sp)
    80004b9a:	e426                	sd	s1,8(sp)
    80004b9c:	e04a                	sd	s2,0(sp)
    80004b9e:	1000                	addi	s0,sp,32
    80004ba0:	84aa                	mv	s1,a0
    80004ba2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004ba4:	00004597          	auipc	a1,0x4
    80004ba8:	cfc58593          	addi	a1,a1,-772 # 800088a0 <syscalls+0x248>
    80004bac:	0521                	addi	a0,a0,8
    80004bae:	ffffc097          	auipc	ra,0xffffc
    80004bb2:	f84080e7          	jalr	-124(ra) # 80000b32 <initlock>
  lk->name = name;
    80004bb6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004bba:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004bbe:	0204a423          	sw	zero,40(s1)
}
    80004bc2:	60e2                	ld	ra,24(sp)
    80004bc4:	6442                	ld	s0,16(sp)
    80004bc6:	64a2                	ld	s1,8(sp)
    80004bc8:	6902                	ld	s2,0(sp)
    80004bca:	6105                	addi	sp,sp,32
    80004bcc:	8082                	ret

0000000080004bce <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004bce:	1101                	addi	sp,sp,-32
    80004bd0:	ec06                	sd	ra,24(sp)
    80004bd2:	e822                	sd	s0,16(sp)
    80004bd4:	e426                	sd	s1,8(sp)
    80004bd6:	e04a                	sd	s2,0(sp)
    80004bd8:	1000                	addi	s0,sp,32
    80004bda:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bdc:	00850913          	addi	s2,a0,8
    80004be0:	854a                	mv	a0,s2
    80004be2:	ffffc097          	auipc	ra,0xffffc
    80004be6:	fe0080e7          	jalr	-32(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004bea:	409c                	lw	a5,0(s1)
    80004bec:	cb89                	beqz	a5,80004bfe <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004bee:	85ca                	mv	a1,s2
    80004bf0:	8526                	mv	a0,s1
    80004bf2:	ffffd097          	auipc	ra,0xffffd
    80004bf6:	7e4080e7          	jalr	2020(ra) # 800023d6 <sleep>
  while (lk->locked) {
    80004bfa:	409c                	lw	a5,0(s1)
    80004bfc:	fbed                	bnez	a5,80004bee <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004bfe:	4785                	li	a5,1
    80004c00:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004c02:	ffffd097          	auipc	ra,0xffffd
    80004c06:	dc0080e7          	jalr	-576(ra) # 800019c2 <myproc>
    80004c0a:	591c                	lw	a5,48(a0)
    80004c0c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004c0e:	854a                	mv	a0,s2
    80004c10:	ffffc097          	auipc	ra,0xffffc
    80004c14:	066080e7          	jalr	102(ra) # 80000c76 <release>
}
    80004c18:	60e2                	ld	ra,24(sp)
    80004c1a:	6442                	ld	s0,16(sp)
    80004c1c:	64a2                	ld	s1,8(sp)
    80004c1e:	6902                	ld	s2,0(sp)
    80004c20:	6105                	addi	sp,sp,32
    80004c22:	8082                	ret

0000000080004c24 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004c24:	1101                	addi	sp,sp,-32
    80004c26:	ec06                	sd	ra,24(sp)
    80004c28:	e822                	sd	s0,16(sp)
    80004c2a:	e426                	sd	s1,8(sp)
    80004c2c:	e04a                	sd	s2,0(sp)
    80004c2e:	1000                	addi	s0,sp,32
    80004c30:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c32:	00850913          	addi	s2,a0,8
    80004c36:	854a                	mv	a0,s2
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	f8a080e7          	jalr	-118(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004c40:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c44:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004c48:	8526                	mv	a0,s1
    80004c4a:	ffffe097          	auipc	ra,0xffffe
    80004c4e:	918080e7          	jalr	-1768(ra) # 80002562 <wakeup>
  release(&lk->lk);
    80004c52:	854a                	mv	a0,s2
    80004c54:	ffffc097          	auipc	ra,0xffffc
    80004c58:	022080e7          	jalr	34(ra) # 80000c76 <release>
}
    80004c5c:	60e2                	ld	ra,24(sp)
    80004c5e:	6442                	ld	s0,16(sp)
    80004c60:	64a2                	ld	s1,8(sp)
    80004c62:	6902                	ld	s2,0(sp)
    80004c64:	6105                	addi	sp,sp,32
    80004c66:	8082                	ret

0000000080004c68 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004c68:	7179                	addi	sp,sp,-48
    80004c6a:	f406                	sd	ra,40(sp)
    80004c6c:	f022                	sd	s0,32(sp)
    80004c6e:	ec26                	sd	s1,24(sp)
    80004c70:	e84a                	sd	s2,16(sp)
    80004c72:	e44e                	sd	s3,8(sp)
    80004c74:	1800                	addi	s0,sp,48
    80004c76:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004c78:	00850913          	addi	s2,a0,8
    80004c7c:	854a                	mv	a0,s2
    80004c7e:	ffffc097          	auipc	ra,0xffffc
    80004c82:	f44080e7          	jalr	-188(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c86:	409c                	lw	a5,0(s1)
    80004c88:	ef99                	bnez	a5,80004ca6 <holdingsleep+0x3e>
    80004c8a:	4481                	li	s1,0
  release(&lk->lk);
    80004c8c:	854a                	mv	a0,s2
    80004c8e:	ffffc097          	auipc	ra,0xffffc
    80004c92:	fe8080e7          	jalr	-24(ra) # 80000c76 <release>
  return r;
}
    80004c96:	8526                	mv	a0,s1
    80004c98:	70a2                	ld	ra,40(sp)
    80004c9a:	7402                	ld	s0,32(sp)
    80004c9c:	64e2                	ld	s1,24(sp)
    80004c9e:	6942                	ld	s2,16(sp)
    80004ca0:	69a2                	ld	s3,8(sp)
    80004ca2:	6145                	addi	sp,sp,48
    80004ca4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ca6:	0284a983          	lw	s3,40(s1)
    80004caa:	ffffd097          	auipc	ra,0xffffd
    80004cae:	d18080e7          	jalr	-744(ra) # 800019c2 <myproc>
    80004cb2:	5904                	lw	s1,48(a0)
    80004cb4:	413484b3          	sub	s1,s1,s3
    80004cb8:	0014b493          	seqz	s1,s1
    80004cbc:	bfc1                	j	80004c8c <holdingsleep+0x24>

0000000080004cbe <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004cbe:	1141                	addi	sp,sp,-16
    80004cc0:	e406                	sd	ra,8(sp)
    80004cc2:	e022                	sd	s0,0(sp)
    80004cc4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004cc6:	00004597          	auipc	a1,0x4
    80004cca:	bea58593          	addi	a1,a1,-1046 # 800088b0 <syscalls+0x258>
    80004cce:	0001d517          	auipc	a0,0x1d
    80004cd2:	10250513          	addi	a0,a0,258 # 80021dd0 <ftable>
    80004cd6:	ffffc097          	auipc	ra,0xffffc
    80004cda:	e5c080e7          	jalr	-420(ra) # 80000b32 <initlock>
}
    80004cde:	60a2                	ld	ra,8(sp)
    80004ce0:	6402                	ld	s0,0(sp)
    80004ce2:	0141                	addi	sp,sp,16
    80004ce4:	8082                	ret

0000000080004ce6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004ce6:	1101                	addi	sp,sp,-32
    80004ce8:	ec06                	sd	ra,24(sp)
    80004cea:	e822                	sd	s0,16(sp)
    80004cec:	e426                	sd	s1,8(sp)
    80004cee:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004cf0:	0001d517          	auipc	a0,0x1d
    80004cf4:	0e050513          	addi	a0,a0,224 # 80021dd0 <ftable>
    80004cf8:	ffffc097          	auipc	ra,0xffffc
    80004cfc:	eca080e7          	jalr	-310(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d00:	0001d497          	auipc	s1,0x1d
    80004d04:	0e848493          	addi	s1,s1,232 # 80021de8 <ftable+0x18>
    80004d08:	0001e717          	auipc	a4,0x1e
    80004d0c:	08070713          	addi	a4,a4,128 # 80022d88 <ftable+0xfb8>
    if(f->ref == 0){
    80004d10:	40dc                	lw	a5,4(s1)
    80004d12:	cf99                	beqz	a5,80004d30 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004d14:	02848493          	addi	s1,s1,40
    80004d18:	fee49ce3          	bne	s1,a4,80004d10 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004d1c:	0001d517          	auipc	a0,0x1d
    80004d20:	0b450513          	addi	a0,a0,180 # 80021dd0 <ftable>
    80004d24:	ffffc097          	auipc	ra,0xffffc
    80004d28:	f52080e7          	jalr	-174(ra) # 80000c76 <release>
  return 0;
    80004d2c:	4481                	li	s1,0
    80004d2e:	a819                	j	80004d44 <filealloc+0x5e>
      f->ref = 1;
    80004d30:	4785                	li	a5,1
    80004d32:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004d34:	0001d517          	auipc	a0,0x1d
    80004d38:	09c50513          	addi	a0,a0,156 # 80021dd0 <ftable>
    80004d3c:	ffffc097          	auipc	ra,0xffffc
    80004d40:	f3a080e7          	jalr	-198(ra) # 80000c76 <release>
}
    80004d44:	8526                	mv	a0,s1
    80004d46:	60e2                	ld	ra,24(sp)
    80004d48:	6442                	ld	s0,16(sp)
    80004d4a:	64a2                	ld	s1,8(sp)
    80004d4c:	6105                	addi	sp,sp,32
    80004d4e:	8082                	ret

0000000080004d50 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004d50:	1101                	addi	sp,sp,-32
    80004d52:	ec06                	sd	ra,24(sp)
    80004d54:	e822                	sd	s0,16(sp)
    80004d56:	e426                	sd	s1,8(sp)
    80004d58:	1000                	addi	s0,sp,32
    80004d5a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004d5c:	0001d517          	auipc	a0,0x1d
    80004d60:	07450513          	addi	a0,a0,116 # 80021dd0 <ftable>
    80004d64:	ffffc097          	auipc	ra,0xffffc
    80004d68:	e5e080e7          	jalr	-418(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004d6c:	40dc                	lw	a5,4(s1)
    80004d6e:	02f05263          	blez	a5,80004d92 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004d72:	2785                	addiw	a5,a5,1
    80004d74:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004d76:	0001d517          	auipc	a0,0x1d
    80004d7a:	05a50513          	addi	a0,a0,90 # 80021dd0 <ftable>
    80004d7e:	ffffc097          	auipc	ra,0xffffc
    80004d82:	ef8080e7          	jalr	-264(ra) # 80000c76 <release>
  return f;
}
    80004d86:	8526                	mv	a0,s1
    80004d88:	60e2                	ld	ra,24(sp)
    80004d8a:	6442                	ld	s0,16(sp)
    80004d8c:	64a2                	ld	s1,8(sp)
    80004d8e:	6105                	addi	sp,sp,32
    80004d90:	8082                	ret
    panic("filedup");
    80004d92:	00004517          	auipc	a0,0x4
    80004d96:	b2650513          	addi	a0,a0,-1242 # 800088b8 <syscalls+0x260>
    80004d9a:	ffffb097          	auipc	ra,0xffffb
    80004d9e:	790080e7          	jalr	1936(ra) # 8000052a <panic>

0000000080004da2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004da2:	7139                	addi	sp,sp,-64
    80004da4:	fc06                	sd	ra,56(sp)
    80004da6:	f822                	sd	s0,48(sp)
    80004da8:	f426                	sd	s1,40(sp)
    80004daa:	f04a                	sd	s2,32(sp)
    80004dac:	ec4e                	sd	s3,24(sp)
    80004dae:	e852                	sd	s4,16(sp)
    80004db0:	e456                	sd	s5,8(sp)
    80004db2:	0080                	addi	s0,sp,64
    80004db4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004db6:	0001d517          	auipc	a0,0x1d
    80004dba:	01a50513          	addi	a0,a0,26 # 80021dd0 <ftable>
    80004dbe:	ffffc097          	auipc	ra,0xffffc
    80004dc2:	e04080e7          	jalr	-508(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004dc6:	40dc                	lw	a5,4(s1)
    80004dc8:	06f05163          	blez	a5,80004e2a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004dcc:	37fd                	addiw	a5,a5,-1
    80004dce:	0007871b          	sext.w	a4,a5
    80004dd2:	c0dc                	sw	a5,4(s1)
    80004dd4:	06e04363          	bgtz	a4,80004e3a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004dd8:	0004a903          	lw	s2,0(s1)
    80004ddc:	0094ca83          	lbu	s5,9(s1)
    80004de0:	0104ba03          	ld	s4,16(s1)
    80004de4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004de8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004dec:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004df0:	0001d517          	auipc	a0,0x1d
    80004df4:	fe050513          	addi	a0,a0,-32 # 80021dd0 <ftable>
    80004df8:	ffffc097          	auipc	ra,0xffffc
    80004dfc:	e7e080e7          	jalr	-386(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004e00:	4785                	li	a5,1
    80004e02:	04f90d63          	beq	s2,a5,80004e5c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004e06:	3979                	addiw	s2,s2,-2
    80004e08:	4785                	li	a5,1
    80004e0a:	0527e063          	bltu	a5,s2,80004e4a <fileclose+0xa8>
    begin_op();
    80004e0e:	00000097          	auipc	ra,0x0
    80004e12:	ac8080e7          	jalr	-1336(ra) # 800048d6 <begin_op>
    iput(ff.ip);
    80004e16:	854e                	mv	a0,s3
    80004e18:	fffff097          	auipc	ra,0xfffff
    80004e1c:	2a2080e7          	jalr	674(ra) # 800040ba <iput>
    end_op();
    80004e20:	00000097          	auipc	ra,0x0
    80004e24:	b36080e7          	jalr	-1226(ra) # 80004956 <end_op>
    80004e28:	a00d                	j	80004e4a <fileclose+0xa8>
    panic("fileclose");
    80004e2a:	00004517          	auipc	a0,0x4
    80004e2e:	a9650513          	addi	a0,a0,-1386 # 800088c0 <syscalls+0x268>
    80004e32:	ffffb097          	auipc	ra,0xffffb
    80004e36:	6f8080e7          	jalr	1784(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004e3a:	0001d517          	auipc	a0,0x1d
    80004e3e:	f9650513          	addi	a0,a0,-106 # 80021dd0 <ftable>
    80004e42:	ffffc097          	auipc	ra,0xffffc
    80004e46:	e34080e7          	jalr	-460(ra) # 80000c76 <release>
  }
}
    80004e4a:	70e2                	ld	ra,56(sp)
    80004e4c:	7442                	ld	s0,48(sp)
    80004e4e:	74a2                	ld	s1,40(sp)
    80004e50:	7902                	ld	s2,32(sp)
    80004e52:	69e2                	ld	s3,24(sp)
    80004e54:	6a42                	ld	s4,16(sp)
    80004e56:	6aa2                	ld	s5,8(sp)
    80004e58:	6121                	addi	sp,sp,64
    80004e5a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004e5c:	85d6                	mv	a1,s5
    80004e5e:	8552                	mv	a0,s4
    80004e60:	00000097          	auipc	ra,0x0
    80004e64:	34c080e7          	jalr	844(ra) # 800051ac <pipeclose>
    80004e68:	b7cd                	j	80004e4a <fileclose+0xa8>

0000000080004e6a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004e6a:	715d                	addi	sp,sp,-80
    80004e6c:	e486                	sd	ra,72(sp)
    80004e6e:	e0a2                	sd	s0,64(sp)
    80004e70:	fc26                	sd	s1,56(sp)
    80004e72:	f84a                	sd	s2,48(sp)
    80004e74:	f44e                	sd	s3,40(sp)
    80004e76:	0880                	addi	s0,sp,80
    80004e78:	84aa                	mv	s1,a0
    80004e7a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004e7c:	ffffd097          	auipc	ra,0xffffd
    80004e80:	b46080e7          	jalr	-1210(ra) # 800019c2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e84:	409c                	lw	a5,0(s1)
    80004e86:	37f9                	addiw	a5,a5,-2
    80004e88:	4705                	li	a4,1
    80004e8a:	04f76763          	bltu	a4,a5,80004ed8 <filestat+0x6e>
    80004e8e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004e90:	6c88                	ld	a0,24(s1)
    80004e92:	fffff097          	auipc	ra,0xfffff
    80004e96:	06e080e7          	jalr	110(ra) # 80003f00 <ilock>
    stati(f->ip, &st);
    80004e9a:	fb840593          	addi	a1,s0,-72
    80004e9e:	6c88                	ld	a0,24(s1)
    80004ea0:	fffff097          	auipc	ra,0xfffff
    80004ea4:	2ea080e7          	jalr	746(ra) # 8000418a <stati>
    iunlock(f->ip);
    80004ea8:	6c88                	ld	a0,24(s1)
    80004eaa:	fffff097          	auipc	ra,0xfffff
    80004eae:	118080e7          	jalr	280(ra) # 80003fc2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004eb2:	46e1                	li	a3,24
    80004eb4:	fb840613          	addi	a2,s0,-72
    80004eb8:	85ce                	mv	a1,s3
    80004eba:	07893503          	ld	a0,120(s2)
    80004ebe:	ffffc097          	auipc	ra,0xffffc
    80004ec2:	780080e7          	jalr	1920(ra) # 8000163e <copyout>
    80004ec6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004eca:	60a6                	ld	ra,72(sp)
    80004ecc:	6406                	ld	s0,64(sp)
    80004ece:	74e2                	ld	s1,56(sp)
    80004ed0:	7942                	ld	s2,48(sp)
    80004ed2:	79a2                	ld	s3,40(sp)
    80004ed4:	6161                	addi	sp,sp,80
    80004ed6:	8082                	ret
  return -1;
    80004ed8:	557d                	li	a0,-1
    80004eda:	bfc5                	j	80004eca <filestat+0x60>

0000000080004edc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004edc:	7179                	addi	sp,sp,-48
    80004ede:	f406                	sd	ra,40(sp)
    80004ee0:	f022                	sd	s0,32(sp)
    80004ee2:	ec26                	sd	s1,24(sp)
    80004ee4:	e84a                	sd	s2,16(sp)
    80004ee6:	e44e                	sd	s3,8(sp)
    80004ee8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004eea:	00854783          	lbu	a5,8(a0)
    80004eee:	c3d5                	beqz	a5,80004f92 <fileread+0xb6>
    80004ef0:	84aa                	mv	s1,a0
    80004ef2:	89ae                	mv	s3,a1
    80004ef4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ef6:	411c                	lw	a5,0(a0)
    80004ef8:	4705                	li	a4,1
    80004efa:	04e78963          	beq	a5,a4,80004f4c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004efe:	470d                	li	a4,3
    80004f00:	04e78d63          	beq	a5,a4,80004f5a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f04:	4709                	li	a4,2
    80004f06:	06e79e63          	bne	a5,a4,80004f82 <fileread+0xa6>
    ilock(f->ip);
    80004f0a:	6d08                	ld	a0,24(a0)
    80004f0c:	fffff097          	auipc	ra,0xfffff
    80004f10:	ff4080e7          	jalr	-12(ra) # 80003f00 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004f14:	874a                	mv	a4,s2
    80004f16:	5094                	lw	a3,32(s1)
    80004f18:	864e                	mv	a2,s3
    80004f1a:	4585                	li	a1,1
    80004f1c:	6c88                	ld	a0,24(s1)
    80004f1e:	fffff097          	auipc	ra,0xfffff
    80004f22:	296080e7          	jalr	662(ra) # 800041b4 <readi>
    80004f26:	892a                	mv	s2,a0
    80004f28:	00a05563          	blez	a0,80004f32 <fileread+0x56>
      f->off += r;
    80004f2c:	509c                	lw	a5,32(s1)
    80004f2e:	9fa9                	addw	a5,a5,a0
    80004f30:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f32:	6c88                	ld	a0,24(s1)
    80004f34:	fffff097          	auipc	ra,0xfffff
    80004f38:	08e080e7          	jalr	142(ra) # 80003fc2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004f3c:	854a                	mv	a0,s2
    80004f3e:	70a2                	ld	ra,40(sp)
    80004f40:	7402                	ld	s0,32(sp)
    80004f42:	64e2                	ld	s1,24(sp)
    80004f44:	6942                	ld	s2,16(sp)
    80004f46:	69a2                	ld	s3,8(sp)
    80004f48:	6145                	addi	sp,sp,48
    80004f4a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f4c:	6908                	ld	a0,16(a0)
    80004f4e:	00000097          	auipc	ra,0x0
    80004f52:	3c0080e7          	jalr	960(ra) # 8000530e <piperead>
    80004f56:	892a                	mv	s2,a0
    80004f58:	b7d5                	j	80004f3c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f5a:	02451783          	lh	a5,36(a0)
    80004f5e:	03079693          	slli	a3,a5,0x30
    80004f62:	92c1                	srli	a3,a3,0x30
    80004f64:	4725                	li	a4,9
    80004f66:	02d76863          	bltu	a4,a3,80004f96 <fileread+0xba>
    80004f6a:	0792                	slli	a5,a5,0x4
    80004f6c:	0001d717          	auipc	a4,0x1d
    80004f70:	dc470713          	addi	a4,a4,-572 # 80021d30 <devsw>
    80004f74:	97ba                	add	a5,a5,a4
    80004f76:	639c                	ld	a5,0(a5)
    80004f78:	c38d                	beqz	a5,80004f9a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004f7a:	4505                	li	a0,1
    80004f7c:	9782                	jalr	a5
    80004f7e:	892a                	mv	s2,a0
    80004f80:	bf75                	j	80004f3c <fileread+0x60>
    panic("fileread");
    80004f82:	00004517          	auipc	a0,0x4
    80004f86:	94e50513          	addi	a0,a0,-1714 # 800088d0 <syscalls+0x278>
    80004f8a:	ffffb097          	auipc	ra,0xffffb
    80004f8e:	5a0080e7          	jalr	1440(ra) # 8000052a <panic>
    return -1;
    80004f92:	597d                	li	s2,-1
    80004f94:	b765                	j	80004f3c <fileread+0x60>
      return -1;
    80004f96:	597d                	li	s2,-1
    80004f98:	b755                	j	80004f3c <fileread+0x60>
    80004f9a:	597d                	li	s2,-1
    80004f9c:	b745                	j	80004f3c <fileread+0x60>

0000000080004f9e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004f9e:	715d                	addi	sp,sp,-80
    80004fa0:	e486                	sd	ra,72(sp)
    80004fa2:	e0a2                	sd	s0,64(sp)
    80004fa4:	fc26                	sd	s1,56(sp)
    80004fa6:	f84a                	sd	s2,48(sp)
    80004fa8:	f44e                	sd	s3,40(sp)
    80004faa:	f052                	sd	s4,32(sp)
    80004fac:	ec56                	sd	s5,24(sp)
    80004fae:	e85a                	sd	s6,16(sp)
    80004fb0:	e45e                	sd	s7,8(sp)
    80004fb2:	e062                	sd	s8,0(sp)
    80004fb4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004fb6:	00954783          	lbu	a5,9(a0)
    80004fba:	10078663          	beqz	a5,800050c6 <filewrite+0x128>
    80004fbe:	892a                	mv	s2,a0
    80004fc0:	8aae                	mv	s5,a1
    80004fc2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004fc4:	411c                	lw	a5,0(a0)
    80004fc6:	4705                	li	a4,1
    80004fc8:	02e78263          	beq	a5,a4,80004fec <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004fcc:	470d                	li	a4,3
    80004fce:	02e78663          	beq	a5,a4,80004ffa <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fd2:	4709                	li	a4,2
    80004fd4:	0ee79163          	bne	a5,a4,800050b6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004fd8:	0ac05d63          	blez	a2,80005092 <filewrite+0xf4>
    int i = 0;
    80004fdc:	4981                	li	s3,0
    80004fde:	6b05                	lui	s6,0x1
    80004fe0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004fe4:	6b85                	lui	s7,0x1
    80004fe6:	c00b8b9b          	addiw	s7,s7,-1024
    80004fea:	a861                	j	80005082 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004fec:	6908                	ld	a0,16(a0)
    80004fee:	00000097          	auipc	ra,0x0
    80004ff2:	22e080e7          	jalr	558(ra) # 8000521c <pipewrite>
    80004ff6:	8a2a                	mv	s4,a0
    80004ff8:	a045                	j	80005098 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ffa:	02451783          	lh	a5,36(a0)
    80004ffe:	03079693          	slli	a3,a5,0x30
    80005002:	92c1                	srli	a3,a3,0x30
    80005004:	4725                	li	a4,9
    80005006:	0cd76263          	bltu	a4,a3,800050ca <filewrite+0x12c>
    8000500a:	0792                	slli	a5,a5,0x4
    8000500c:	0001d717          	auipc	a4,0x1d
    80005010:	d2470713          	addi	a4,a4,-732 # 80021d30 <devsw>
    80005014:	97ba                	add	a5,a5,a4
    80005016:	679c                	ld	a5,8(a5)
    80005018:	cbdd                	beqz	a5,800050ce <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000501a:	4505                	li	a0,1
    8000501c:	9782                	jalr	a5
    8000501e:	8a2a                	mv	s4,a0
    80005020:	a8a5                	j	80005098 <filewrite+0xfa>
    80005022:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005026:	00000097          	auipc	ra,0x0
    8000502a:	8b0080e7          	jalr	-1872(ra) # 800048d6 <begin_op>
      ilock(f->ip);
    8000502e:	01893503          	ld	a0,24(s2)
    80005032:	fffff097          	auipc	ra,0xfffff
    80005036:	ece080e7          	jalr	-306(ra) # 80003f00 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000503a:	8762                	mv	a4,s8
    8000503c:	02092683          	lw	a3,32(s2)
    80005040:	01598633          	add	a2,s3,s5
    80005044:	4585                	li	a1,1
    80005046:	01893503          	ld	a0,24(s2)
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	262080e7          	jalr	610(ra) # 800042ac <writei>
    80005052:	84aa                	mv	s1,a0
    80005054:	00a05763          	blez	a0,80005062 <filewrite+0xc4>
        f->off += r;
    80005058:	02092783          	lw	a5,32(s2)
    8000505c:	9fa9                	addw	a5,a5,a0
    8000505e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005062:	01893503          	ld	a0,24(s2)
    80005066:	fffff097          	auipc	ra,0xfffff
    8000506a:	f5c080e7          	jalr	-164(ra) # 80003fc2 <iunlock>
      end_op();
    8000506e:	00000097          	auipc	ra,0x0
    80005072:	8e8080e7          	jalr	-1816(ra) # 80004956 <end_op>

      if(r != n1){
    80005076:	009c1f63          	bne	s8,s1,80005094 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000507a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000507e:	0149db63          	bge	s3,s4,80005094 <filewrite+0xf6>
      int n1 = n - i;
    80005082:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005086:	84be                	mv	s1,a5
    80005088:	2781                	sext.w	a5,a5
    8000508a:	f8fb5ce3          	bge	s6,a5,80005022 <filewrite+0x84>
    8000508e:	84de                	mv	s1,s7
    80005090:	bf49                	j	80005022 <filewrite+0x84>
    int i = 0;
    80005092:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005094:	013a1f63          	bne	s4,s3,800050b2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005098:	8552                	mv	a0,s4
    8000509a:	60a6                	ld	ra,72(sp)
    8000509c:	6406                	ld	s0,64(sp)
    8000509e:	74e2                	ld	s1,56(sp)
    800050a0:	7942                	ld	s2,48(sp)
    800050a2:	79a2                	ld	s3,40(sp)
    800050a4:	7a02                	ld	s4,32(sp)
    800050a6:	6ae2                	ld	s5,24(sp)
    800050a8:	6b42                	ld	s6,16(sp)
    800050aa:	6ba2                	ld	s7,8(sp)
    800050ac:	6c02                	ld	s8,0(sp)
    800050ae:	6161                	addi	sp,sp,80
    800050b0:	8082                	ret
    ret = (i == n ? n : -1);
    800050b2:	5a7d                	li	s4,-1
    800050b4:	b7d5                	j	80005098 <filewrite+0xfa>
    panic("filewrite");
    800050b6:	00004517          	auipc	a0,0x4
    800050ba:	82a50513          	addi	a0,a0,-2006 # 800088e0 <syscalls+0x288>
    800050be:	ffffb097          	auipc	ra,0xffffb
    800050c2:	46c080e7          	jalr	1132(ra) # 8000052a <panic>
    return -1;
    800050c6:	5a7d                	li	s4,-1
    800050c8:	bfc1                	j	80005098 <filewrite+0xfa>
      return -1;
    800050ca:	5a7d                	li	s4,-1
    800050cc:	b7f1                	j	80005098 <filewrite+0xfa>
    800050ce:	5a7d                	li	s4,-1
    800050d0:	b7e1                	j	80005098 <filewrite+0xfa>

00000000800050d2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800050d2:	7179                	addi	sp,sp,-48
    800050d4:	f406                	sd	ra,40(sp)
    800050d6:	f022                	sd	s0,32(sp)
    800050d8:	ec26                	sd	s1,24(sp)
    800050da:	e84a                	sd	s2,16(sp)
    800050dc:	e44e                	sd	s3,8(sp)
    800050de:	e052                	sd	s4,0(sp)
    800050e0:	1800                	addi	s0,sp,48
    800050e2:	84aa                	mv	s1,a0
    800050e4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800050e6:	0005b023          	sd	zero,0(a1)
    800050ea:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800050ee:	00000097          	auipc	ra,0x0
    800050f2:	bf8080e7          	jalr	-1032(ra) # 80004ce6 <filealloc>
    800050f6:	e088                	sd	a0,0(s1)
    800050f8:	c551                	beqz	a0,80005184 <pipealloc+0xb2>
    800050fa:	00000097          	auipc	ra,0x0
    800050fe:	bec080e7          	jalr	-1044(ra) # 80004ce6 <filealloc>
    80005102:	00aa3023          	sd	a0,0(s4)
    80005106:	c92d                	beqz	a0,80005178 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005108:	ffffc097          	auipc	ra,0xffffc
    8000510c:	9ca080e7          	jalr	-1590(ra) # 80000ad2 <kalloc>
    80005110:	892a                	mv	s2,a0
    80005112:	c125                	beqz	a0,80005172 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005114:	4985                	li	s3,1
    80005116:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000511a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000511e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005122:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005126:	00003597          	auipc	a1,0x3
    8000512a:	39258593          	addi	a1,a1,914 # 800084b8 <states.0+0x1f8>
    8000512e:	ffffc097          	auipc	ra,0xffffc
    80005132:	a04080e7          	jalr	-1532(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80005136:	609c                	ld	a5,0(s1)
    80005138:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000513c:	609c                	ld	a5,0(s1)
    8000513e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005142:	609c                	ld	a5,0(s1)
    80005144:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005148:	609c                	ld	a5,0(s1)
    8000514a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000514e:	000a3783          	ld	a5,0(s4)
    80005152:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005156:	000a3783          	ld	a5,0(s4)
    8000515a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000515e:	000a3783          	ld	a5,0(s4)
    80005162:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005166:	000a3783          	ld	a5,0(s4)
    8000516a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000516e:	4501                	li	a0,0
    80005170:	a025                	j	80005198 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005172:	6088                	ld	a0,0(s1)
    80005174:	e501                	bnez	a0,8000517c <pipealloc+0xaa>
    80005176:	a039                	j	80005184 <pipealloc+0xb2>
    80005178:	6088                	ld	a0,0(s1)
    8000517a:	c51d                	beqz	a0,800051a8 <pipealloc+0xd6>
    fileclose(*f0);
    8000517c:	00000097          	auipc	ra,0x0
    80005180:	c26080e7          	jalr	-986(ra) # 80004da2 <fileclose>
  if(*f1)
    80005184:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005188:	557d                	li	a0,-1
  if(*f1)
    8000518a:	c799                	beqz	a5,80005198 <pipealloc+0xc6>
    fileclose(*f1);
    8000518c:	853e                	mv	a0,a5
    8000518e:	00000097          	auipc	ra,0x0
    80005192:	c14080e7          	jalr	-1004(ra) # 80004da2 <fileclose>
  return -1;
    80005196:	557d                	li	a0,-1
}
    80005198:	70a2                	ld	ra,40(sp)
    8000519a:	7402                	ld	s0,32(sp)
    8000519c:	64e2                	ld	s1,24(sp)
    8000519e:	6942                	ld	s2,16(sp)
    800051a0:	69a2                	ld	s3,8(sp)
    800051a2:	6a02                	ld	s4,0(sp)
    800051a4:	6145                	addi	sp,sp,48
    800051a6:	8082                	ret
  return -1;
    800051a8:	557d                	li	a0,-1
    800051aa:	b7fd                	j	80005198 <pipealloc+0xc6>

00000000800051ac <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800051ac:	1101                	addi	sp,sp,-32
    800051ae:	ec06                	sd	ra,24(sp)
    800051b0:	e822                	sd	s0,16(sp)
    800051b2:	e426                	sd	s1,8(sp)
    800051b4:	e04a                	sd	s2,0(sp)
    800051b6:	1000                	addi	s0,sp,32
    800051b8:	84aa                	mv	s1,a0
    800051ba:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800051bc:	ffffc097          	auipc	ra,0xffffc
    800051c0:	a06080e7          	jalr	-1530(ra) # 80000bc2 <acquire>
  if(writable){
    800051c4:	02090d63          	beqz	s2,800051fe <pipeclose+0x52>
    pi->writeopen = 0;
    800051c8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800051cc:	21848513          	addi	a0,s1,536
    800051d0:	ffffd097          	auipc	ra,0xffffd
    800051d4:	392080e7          	jalr	914(ra) # 80002562 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800051d8:	2204b783          	ld	a5,544(s1)
    800051dc:	eb95                	bnez	a5,80005210 <pipeclose+0x64>
    release(&pi->lock);
    800051de:	8526                	mv	a0,s1
    800051e0:	ffffc097          	auipc	ra,0xffffc
    800051e4:	a96080e7          	jalr	-1386(ra) # 80000c76 <release>
    kfree((char*)pi);
    800051e8:	8526                	mv	a0,s1
    800051ea:	ffffb097          	auipc	ra,0xffffb
    800051ee:	7ec080e7          	jalr	2028(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800051f2:	60e2                	ld	ra,24(sp)
    800051f4:	6442                	ld	s0,16(sp)
    800051f6:	64a2                	ld	s1,8(sp)
    800051f8:	6902                	ld	s2,0(sp)
    800051fa:	6105                	addi	sp,sp,32
    800051fc:	8082                	ret
    pi->readopen = 0;
    800051fe:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005202:	21c48513          	addi	a0,s1,540
    80005206:	ffffd097          	auipc	ra,0xffffd
    8000520a:	35c080e7          	jalr	860(ra) # 80002562 <wakeup>
    8000520e:	b7e9                	j	800051d8 <pipeclose+0x2c>
    release(&pi->lock);
    80005210:	8526                	mv	a0,s1
    80005212:	ffffc097          	auipc	ra,0xffffc
    80005216:	a64080e7          	jalr	-1436(ra) # 80000c76 <release>
}
    8000521a:	bfe1                	j	800051f2 <pipeclose+0x46>

000000008000521c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000521c:	711d                	addi	sp,sp,-96
    8000521e:	ec86                	sd	ra,88(sp)
    80005220:	e8a2                	sd	s0,80(sp)
    80005222:	e4a6                	sd	s1,72(sp)
    80005224:	e0ca                	sd	s2,64(sp)
    80005226:	fc4e                	sd	s3,56(sp)
    80005228:	f852                	sd	s4,48(sp)
    8000522a:	f456                	sd	s5,40(sp)
    8000522c:	f05a                	sd	s6,32(sp)
    8000522e:	ec5e                	sd	s7,24(sp)
    80005230:	e862                	sd	s8,16(sp)
    80005232:	1080                	addi	s0,sp,96
    80005234:	84aa                	mv	s1,a0
    80005236:	8aae                	mv	s5,a1
    80005238:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000523a:	ffffc097          	auipc	ra,0xffffc
    8000523e:	788080e7          	jalr	1928(ra) # 800019c2 <myproc>
    80005242:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005244:	8526                	mv	a0,s1
    80005246:	ffffc097          	auipc	ra,0xffffc
    8000524a:	97c080e7          	jalr	-1668(ra) # 80000bc2 <acquire>
  while(i < n){
    8000524e:	0b405363          	blez	s4,800052f4 <pipewrite+0xd8>
  int i = 0;
    80005252:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005254:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005256:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000525a:	21c48b93          	addi	s7,s1,540
    8000525e:	a089                	j	800052a0 <pipewrite+0x84>
      release(&pi->lock);
    80005260:	8526                	mv	a0,s1
    80005262:	ffffc097          	auipc	ra,0xffffc
    80005266:	a14080e7          	jalr	-1516(ra) # 80000c76 <release>
      return -1;
    8000526a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000526c:	854a                	mv	a0,s2
    8000526e:	60e6                	ld	ra,88(sp)
    80005270:	6446                	ld	s0,80(sp)
    80005272:	64a6                	ld	s1,72(sp)
    80005274:	6906                	ld	s2,64(sp)
    80005276:	79e2                	ld	s3,56(sp)
    80005278:	7a42                	ld	s4,48(sp)
    8000527a:	7aa2                	ld	s5,40(sp)
    8000527c:	7b02                	ld	s6,32(sp)
    8000527e:	6be2                	ld	s7,24(sp)
    80005280:	6c42                	ld	s8,16(sp)
    80005282:	6125                	addi	sp,sp,96
    80005284:	8082                	ret
      wakeup(&pi->nread);
    80005286:	8562                	mv	a0,s8
    80005288:	ffffd097          	auipc	ra,0xffffd
    8000528c:	2da080e7          	jalr	730(ra) # 80002562 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005290:	85a6                	mv	a1,s1
    80005292:	855e                	mv	a0,s7
    80005294:	ffffd097          	auipc	ra,0xffffd
    80005298:	142080e7          	jalr	322(ra) # 800023d6 <sleep>
  while(i < n){
    8000529c:	05495d63          	bge	s2,s4,800052f6 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    800052a0:	2204a783          	lw	a5,544(s1)
    800052a4:	dfd5                	beqz	a5,80005260 <pipewrite+0x44>
    800052a6:	0289a783          	lw	a5,40(s3)
    800052aa:	fbdd                	bnez	a5,80005260 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800052ac:	2184a783          	lw	a5,536(s1)
    800052b0:	21c4a703          	lw	a4,540(s1)
    800052b4:	2007879b          	addiw	a5,a5,512
    800052b8:	fcf707e3          	beq	a4,a5,80005286 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800052bc:	4685                	li	a3,1
    800052be:	01590633          	add	a2,s2,s5
    800052c2:	faf40593          	addi	a1,s0,-81
    800052c6:	0789b503          	ld	a0,120(s3)
    800052ca:	ffffc097          	auipc	ra,0xffffc
    800052ce:	400080e7          	jalr	1024(ra) # 800016ca <copyin>
    800052d2:	03650263          	beq	a0,s6,800052f6 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800052d6:	21c4a783          	lw	a5,540(s1)
    800052da:	0017871b          	addiw	a4,a5,1
    800052de:	20e4ae23          	sw	a4,540(s1)
    800052e2:	1ff7f793          	andi	a5,a5,511
    800052e6:	97a6                	add	a5,a5,s1
    800052e8:	faf44703          	lbu	a4,-81(s0)
    800052ec:	00e78c23          	sb	a4,24(a5)
      i++;
    800052f0:	2905                	addiw	s2,s2,1
    800052f2:	b76d                	j	8000529c <pipewrite+0x80>
  int i = 0;
    800052f4:	4901                	li	s2,0
  wakeup(&pi->nread);
    800052f6:	21848513          	addi	a0,s1,536
    800052fa:	ffffd097          	auipc	ra,0xffffd
    800052fe:	268080e7          	jalr	616(ra) # 80002562 <wakeup>
  release(&pi->lock);
    80005302:	8526                	mv	a0,s1
    80005304:	ffffc097          	auipc	ra,0xffffc
    80005308:	972080e7          	jalr	-1678(ra) # 80000c76 <release>
  return i;
    8000530c:	b785                	j	8000526c <pipewrite+0x50>

000000008000530e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000530e:	715d                	addi	sp,sp,-80
    80005310:	e486                	sd	ra,72(sp)
    80005312:	e0a2                	sd	s0,64(sp)
    80005314:	fc26                	sd	s1,56(sp)
    80005316:	f84a                	sd	s2,48(sp)
    80005318:	f44e                	sd	s3,40(sp)
    8000531a:	f052                	sd	s4,32(sp)
    8000531c:	ec56                	sd	s5,24(sp)
    8000531e:	e85a                	sd	s6,16(sp)
    80005320:	0880                	addi	s0,sp,80
    80005322:	84aa                	mv	s1,a0
    80005324:	892e                	mv	s2,a1
    80005326:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005328:	ffffc097          	auipc	ra,0xffffc
    8000532c:	69a080e7          	jalr	1690(ra) # 800019c2 <myproc>
    80005330:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005332:	8526                	mv	a0,s1
    80005334:	ffffc097          	auipc	ra,0xffffc
    80005338:	88e080e7          	jalr	-1906(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000533c:	2184a703          	lw	a4,536(s1)
    80005340:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005344:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005348:	02f71463          	bne	a4,a5,80005370 <piperead+0x62>
    8000534c:	2244a783          	lw	a5,548(s1)
    80005350:	c385                	beqz	a5,80005370 <piperead+0x62>
    if(pr->killed){
    80005352:	028a2783          	lw	a5,40(s4)
    80005356:	ebc1                	bnez	a5,800053e6 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005358:	85a6                	mv	a1,s1
    8000535a:	854e                	mv	a0,s3
    8000535c:	ffffd097          	auipc	ra,0xffffd
    80005360:	07a080e7          	jalr	122(ra) # 800023d6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005364:	2184a703          	lw	a4,536(s1)
    80005368:	21c4a783          	lw	a5,540(s1)
    8000536c:	fef700e3          	beq	a4,a5,8000534c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005370:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005372:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005374:	05505363          	blez	s5,800053ba <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80005378:	2184a783          	lw	a5,536(s1)
    8000537c:	21c4a703          	lw	a4,540(s1)
    80005380:	02f70d63          	beq	a4,a5,800053ba <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005384:	0017871b          	addiw	a4,a5,1
    80005388:	20e4ac23          	sw	a4,536(s1)
    8000538c:	1ff7f793          	andi	a5,a5,511
    80005390:	97a6                	add	a5,a5,s1
    80005392:	0187c783          	lbu	a5,24(a5)
    80005396:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000539a:	4685                	li	a3,1
    8000539c:	fbf40613          	addi	a2,s0,-65
    800053a0:	85ca                	mv	a1,s2
    800053a2:	078a3503          	ld	a0,120(s4)
    800053a6:	ffffc097          	auipc	ra,0xffffc
    800053aa:	298080e7          	jalr	664(ra) # 8000163e <copyout>
    800053ae:	01650663          	beq	a0,s6,800053ba <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800053b2:	2985                	addiw	s3,s3,1
    800053b4:	0905                	addi	s2,s2,1
    800053b6:	fd3a91e3          	bne	s5,s3,80005378 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800053ba:	21c48513          	addi	a0,s1,540
    800053be:	ffffd097          	auipc	ra,0xffffd
    800053c2:	1a4080e7          	jalr	420(ra) # 80002562 <wakeup>
  release(&pi->lock);
    800053c6:	8526                	mv	a0,s1
    800053c8:	ffffc097          	auipc	ra,0xffffc
    800053cc:	8ae080e7          	jalr	-1874(ra) # 80000c76 <release>
  return i;
}
    800053d0:	854e                	mv	a0,s3
    800053d2:	60a6                	ld	ra,72(sp)
    800053d4:	6406                	ld	s0,64(sp)
    800053d6:	74e2                	ld	s1,56(sp)
    800053d8:	7942                	ld	s2,48(sp)
    800053da:	79a2                	ld	s3,40(sp)
    800053dc:	7a02                	ld	s4,32(sp)
    800053de:	6ae2                	ld	s5,24(sp)
    800053e0:	6b42                	ld	s6,16(sp)
    800053e2:	6161                	addi	sp,sp,80
    800053e4:	8082                	ret
      release(&pi->lock);
    800053e6:	8526                	mv	a0,s1
    800053e8:	ffffc097          	auipc	ra,0xffffc
    800053ec:	88e080e7          	jalr	-1906(ra) # 80000c76 <release>
      return -1;
    800053f0:	59fd                	li	s3,-1
    800053f2:	bff9                	j	800053d0 <piperead+0xc2>

00000000800053f4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800053f4:	de010113          	addi	sp,sp,-544
    800053f8:	20113c23          	sd	ra,536(sp)
    800053fc:	20813823          	sd	s0,528(sp)
    80005400:	20913423          	sd	s1,520(sp)
    80005404:	21213023          	sd	s2,512(sp)
    80005408:	ffce                	sd	s3,504(sp)
    8000540a:	fbd2                	sd	s4,496(sp)
    8000540c:	f7d6                	sd	s5,488(sp)
    8000540e:	f3da                	sd	s6,480(sp)
    80005410:	efde                	sd	s7,472(sp)
    80005412:	ebe2                	sd	s8,464(sp)
    80005414:	e7e6                	sd	s9,456(sp)
    80005416:	e3ea                	sd	s10,448(sp)
    80005418:	ff6e                	sd	s11,440(sp)
    8000541a:	1400                	addi	s0,sp,544
    8000541c:	892a                	mv	s2,a0
    8000541e:	dea43423          	sd	a0,-536(s0)
    80005422:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005426:	ffffc097          	auipc	ra,0xffffc
    8000542a:	59c080e7          	jalr	1436(ra) # 800019c2 <myproc>
    8000542e:	84aa                	mv	s1,a0

  begin_op();
    80005430:	fffff097          	auipc	ra,0xfffff
    80005434:	4a6080e7          	jalr	1190(ra) # 800048d6 <begin_op>

  if((ip = namei(path)) == 0){
    80005438:	854a                	mv	a0,s2
    8000543a:	fffff097          	auipc	ra,0xfffff
    8000543e:	27c080e7          	jalr	636(ra) # 800046b6 <namei>
    80005442:	c93d                	beqz	a0,800054b8 <exec+0xc4>
    80005444:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005446:	fffff097          	auipc	ra,0xfffff
    8000544a:	aba080e7          	jalr	-1350(ra) # 80003f00 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000544e:	04000713          	li	a4,64
    80005452:	4681                	li	a3,0
    80005454:	e4840613          	addi	a2,s0,-440
    80005458:	4581                	li	a1,0
    8000545a:	8556                	mv	a0,s5
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	d58080e7          	jalr	-680(ra) # 800041b4 <readi>
    80005464:	04000793          	li	a5,64
    80005468:	00f51a63          	bne	a0,a5,8000547c <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000546c:	e4842703          	lw	a4,-440(s0)
    80005470:	464c47b7          	lui	a5,0x464c4
    80005474:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005478:	04f70663          	beq	a4,a5,800054c4 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000547c:	8556                	mv	a0,s5
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	ce4080e7          	jalr	-796(ra) # 80004162 <iunlockput>
    end_op();
    80005486:	fffff097          	auipc	ra,0xfffff
    8000548a:	4d0080e7          	jalr	1232(ra) # 80004956 <end_op>
  }
  return -1;
    8000548e:	557d                	li	a0,-1
}
    80005490:	21813083          	ld	ra,536(sp)
    80005494:	21013403          	ld	s0,528(sp)
    80005498:	20813483          	ld	s1,520(sp)
    8000549c:	20013903          	ld	s2,512(sp)
    800054a0:	79fe                	ld	s3,504(sp)
    800054a2:	7a5e                	ld	s4,496(sp)
    800054a4:	7abe                	ld	s5,488(sp)
    800054a6:	7b1e                	ld	s6,480(sp)
    800054a8:	6bfe                	ld	s7,472(sp)
    800054aa:	6c5e                	ld	s8,464(sp)
    800054ac:	6cbe                	ld	s9,456(sp)
    800054ae:	6d1e                	ld	s10,448(sp)
    800054b0:	7dfa                	ld	s11,440(sp)
    800054b2:	22010113          	addi	sp,sp,544
    800054b6:	8082                	ret
    end_op();
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	49e080e7          	jalr	1182(ra) # 80004956 <end_op>
    return -1;
    800054c0:	557d                	li	a0,-1
    800054c2:	b7f9                	j	80005490 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800054c4:	8526                	mv	a0,s1
    800054c6:	ffffc097          	auipc	ra,0xffffc
    800054ca:	5c0080e7          	jalr	1472(ra) # 80001a86 <proc_pagetable>
    800054ce:	8b2a                	mv	s6,a0
    800054d0:	d555                	beqz	a0,8000547c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054d2:	e6842783          	lw	a5,-408(s0)
    800054d6:	e8045703          	lhu	a4,-384(s0)
    800054da:	c735                	beqz	a4,80005546 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800054dc:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054de:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800054e2:	6a05                	lui	s4,0x1
    800054e4:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800054e8:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    800054ec:	6d85                	lui	s11,0x1
    800054ee:	7d7d                	lui	s10,0xfffff
    800054f0:	ac1d                	j	80005726 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800054f2:	00003517          	auipc	a0,0x3
    800054f6:	3fe50513          	addi	a0,a0,1022 # 800088f0 <syscalls+0x298>
    800054fa:	ffffb097          	auipc	ra,0xffffb
    800054fe:	030080e7          	jalr	48(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005502:	874a                	mv	a4,s2
    80005504:	009c86bb          	addw	a3,s9,s1
    80005508:	4581                	li	a1,0
    8000550a:	8556                	mv	a0,s5
    8000550c:	fffff097          	auipc	ra,0xfffff
    80005510:	ca8080e7          	jalr	-856(ra) # 800041b4 <readi>
    80005514:	2501                	sext.w	a0,a0
    80005516:	1aa91863          	bne	s2,a0,800056c6 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    8000551a:	009d84bb          	addw	s1,s11,s1
    8000551e:	013d09bb          	addw	s3,s10,s3
    80005522:	1f74f263          	bgeu	s1,s7,80005706 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005526:	02049593          	slli	a1,s1,0x20
    8000552a:	9181                	srli	a1,a1,0x20
    8000552c:	95e2                	add	a1,a1,s8
    8000552e:	855a                	mv	a0,s6
    80005530:	ffffc097          	auipc	ra,0xffffc
    80005534:	b1c080e7          	jalr	-1252(ra) # 8000104c <walkaddr>
    80005538:	862a                	mv	a2,a0
    if(pa == 0)
    8000553a:	dd45                	beqz	a0,800054f2 <exec+0xfe>
      n = PGSIZE;
    8000553c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000553e:	fd49f2e3          	bgeu	s3,s4,80005502 <exec+0x10e>
      n = sz - i;
    80005542:	894e                	mv	s2,s3
    80005544:	bf7d                	j	80005502 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005546:	4481                	li	s1,0
  iunlockput(ip);
    80005548:	8556                	mv	a0,s5
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	c18080e7          	jalr	-1000(ra) # 80004162 <iunlockput>
  end_op();
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	404080e7          	jalr	1028(ra) # 80004956 <end_op>
  p = myproc();
    8000555a:	ffffc097          	auipc	ra,0xffffc
    8000555e:	468080e7          	jalr	1128(ra) # 800019c2 <myproc>
    80005562:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005564:	07053d03          	ld	s10,112(a0)
  sz = PGROUNDUP(sz);
    80005568:	6785                	lui	a5,0x1
    8000556a:	17fd                	addi	a5,a5,-1
    8000556c:	94be                	add	s1,s1,a5
    8000556e:	77fd                	lui	a5,0xfffff
    80005570:	8fe5                	and	a5,a5,s1
    80005572:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005576:	6609                	lui	a2,0x2
    80005578:	963e                	add	a2,a2,a5
    8000557a:	85be                	mv	a1,a5
    8000557c:	855a                	mv	a0,s6
    8000557e:	ffffc097          	auipc	ra,0xffffc
    80005582:	e70080e7          	jalr	-400(ra) # 800013ee <uvmalloc>
    80005586:	8c2a                	mv	s8,a0
  ip = 0;
    80005588:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000558a:	12050e63          	beqz	a0,800056c6 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000558e:	75f9                	lui	a1,0xffffe
    80005590:	95aa                	add	a1,a1,a0
    80005592:	855a                	mv	a0,s6
    80005594:	ffffc097          	auipc	ra,0xffffc
    80005598:	078080e7          	jalr	120(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    8000559c:	7afd                	lui	s5,0xfffff
    8000559e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800055a0:	df043783          	ld	a5,-528(s0)
    800055a4:	6388                	ld	a0,0(a5)
    800055a6:	c925                	beqz	a0,80005616 <exec+0x222>
    800055a8:	e8840993          	addi	s3,s0,-376
    800055ac:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    800055b0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800055b2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800055b4:	ffffc097          	auipc	ra,0xffffc
    800055b8:	88e080e7          	jalr	-1906(ra) # 80000e42 <strlen>
    800055bc:	0015079b          	addiw	a5,a0,1
    800055c0:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800055c4:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800055c8:	13596363          	bltu	s2,s5,800056ee <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800055cc:	df043d83          	ld	s11,-528(s0)
    800055d0:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800055d4:	8552                	mv	a0,s4
    800055d6:	ffffc097          	auipc	ra,0xffffc
    800055da:	86c080e7          	jalr	-1940(ra) # 80000e42 <strlen>
    800055de:	0015069b          	addiw	a3,a0,1
    800055e2:	8652                	mv	a2,s4
    800055e4:	85ca                	mv	a1,s2
    800055e6:	855a                	mv	a0,s6
    800055e8:	ffffc097          	auipc	ra,0xffffc
    800055ec:	056080e7          	jalr	86(ra) # 8000163e <copyout>
    800055f0:	10054363          	bltz	a0,800056f6 <exec+0x302>
    ustack[argc] = sp;
    800055f4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800055f8:	0485                	addi	s1,s1,1
    800055fa:	008d8793          	addi	a5,s11,8
    800055fe:	def43823          	sd	a5,-528(s0)
    80005602:	008db503          	ld	a0,8(s11)
    80005606:	c911                	beqz	a0,8000561a <exec+0x226>
    if(argc >= MAXARG)
    80005608:	09a1                	addi	s3,s3,8
    8000560a:	fb3c95e3          	bne	s9,s3,800055b4 <exec+0x1c0>
  sz = sz1;
    8000560e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005612:	4a81                	li	s5,0
    80005614:	a84d                	j	800056c6 <exec+0x2d2>
  sp = sz;
    80005616:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005618:	4481                	li	s1,0
  ustack[argc] = 0;
    8000561a:	00349793          	slli	a5,s1,0x3
    8000561e:	f9040713          	addi	a4,s0,-112
    80005622:	97ba                	add	a5,a5,a4
    80005624:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80005628:	00148693          	addi	a3,s1,1
    8000562c:	068e                	slli	a3,a3,0x3
    8000562e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005632:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005636:	01597663          	bgeu	s2,s5,80005642 <exec+0x24e>
  sz = sz1;
    8000563a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000563e:	4a81                	li	s5,0
    80005640:	a059                	j	800056c6 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005642:	e8840613          	addi	a2,s0,-376
    80005646:	85ca                	mv	a1,s2
    80005648:	855a                	mv	a0,s6
    8000564a:	ffffc097          	auipc	ra,0xffffc
    8000564e:	ff4080e7          	jalr	-12(ra) # 8000163e <copyout>
    80005652:	0a054663          	bltz	a0,800056fe <exec+0x30a>
  p->trapframe->a1 = sp;
    80005656:	080bb783          	ld	a5,128(s7) # 1080 <_entry-0x7fffef80>
    8000565a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000565e:	de843783          	ld	a5,-536(s0)
    80005662:	0007c703          	lbu	a4,0(a5)
    80005666:	cf11                	beqz	a4,80005682 <exec+0x28e>
    80005668:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000566a:	02f00693          	li	a3,47
    8000566e:	a039                	j	8000567c <exec+0x288>
      last = s+1;
    80005670:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005674:	0785                	addi	a5,a5,1
    80005676:	fff7c703          	lbu	a4,-1(a5)
    8000567a:	c701                	beqz	a4,80005682 <exec+0x28e>
    if(*s == '/')
    8000567c:	fed71ce3          	bne	a4,a3,80005674 <exec+0x280>
    80005680:	bfc5                	j	80005670 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005682:	4641                	li	a2,16
    80005684:	de843583          	ld	a1,-536(s0)
    80005688:	180b8513          	addi	a0,s7,384
    8000568c:	ffffb097          	auipc	ra,0xffffb
    80005690:	784080e7          	jalr	1924(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005694:	078bb503          	ld	a0,120(s7)
  p->pagetable = pagetable;
    80005698:	076bbc23          	sd	s6,120(s7)
  p->sz = sz;
    8000569c:	078bb823          	sd	s8,112(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800056a0:	080bb783          	ld	a5,128(s7)
    800056a4:	e6043703          	ld	a4,-416(s0)
    800056a8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800056aa:	080bb783          	ld	a5,128(s7)
    800056ae:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800056b2:	85ea                	mv	a1,s10
    800056b4:	ffffc097          	auipc	ra,0xffffc
    800056b8:	46e080e7          	jalr	1134(ra) # 80001b22 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800056bc:	0004851b          	sext.w	a0,s1
    800056c0:	bbc1                	j	80005490 <exec+0x9c>
    800056c2:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800056c6:	df843583          	ld	a1,-520(s0)
    800056ca:	855a                	mv	a0,s6
    800056cc:	ffffc097          	auipc	ra,0xffffc
    800056d0:	456080e7          	jalr	1110(ra) # 80001b22 <proc_freepagetable>
  if(ip){
    800056d4:	da0a94e3          	bnez	s5,8000547c <exec+0x88>
  return -1;
    800056d8:	557d                	li	a0,-1
    800056da:	bb5d                	j	80005490 <exec+0x9c>
    800056dc:	de943c23          	sd	s1,-520(s0)
    800056e0:	b7dd                	j	800056c6 <exec+0x2d2>
    800056e2:	de943c23          	sd	s1,-520(s0)
    800056e6:	b7c5                	j	800056c6 <exec+0x2d2>
    800056e8:	de943c23          	sd	s1,-520(s0)
    800056ec:	bfe9                	j	800056c6 <exec+0x2d2>
  sz = sz1;
    800056ee:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056f2:	4a81                	li	s5,0
    800056f4:	bfc9                	j	800056c6 <exec+0x2d2>
  sz = sz1;
    800056f6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056fa:	4a81                	li	s5,0
    800056fc:	b7e9                	j	800056c6 <exec+0x2d2>
  sz = sz1;
    800056fe:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005702:	4a81                	li	s5,0
    80005704:	b7c9                	j	800056c6 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005706:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000570a:	e0843783          	ld	a5,-504(s0)
    8000570e:	0017869b          	addiw	a3,a5,1
    80005712:	e0d43423          	sd	a3,-504(s0)
    80005716:	e0043783          	ld	a5,-512(s0)
    8000571a:	0387879b          	addiw	a5,a5,56
    8000571e:	e8045703          	lhu	a4,-384(s0)
    80005722:	e2e6d3e3          	bge	a3,a4,80005548 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005726:	2781                	sext.w	a5,a5
    80005728:	e0f43023          	sd	a5,-512(s0)
    8000572c:	03800713          	li	a4,56
    80005730:	86be                	mv	a3,a5
    80005732:	e1040613          	addi	a2,s0,-496
    80005736:	4581                	li	a1,0
    80005738:	8556                	mv	a0,s5
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	a7a080e7          	jalr	-1414(ra) # 800041b4 <readi>
    80005742:	03800793          	li	a5,56
    80005746:	f6f51ee3          	bne	a0,a5,800056c2 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000574a:	e1042783          	lw	a5,-496(s0)
    8000574e:	4705                	li	a4,1
    80005750:	fae79de3          	bne	a5,a4,8000570a <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005754:	e3843603          	ld	a2,-456(s0)
    80005758:	e3043783          	ld	a5,-464(s0)
    8000575c:	f8f660e3          	bltu	a2,a5,800056dc <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005760:	e2043783          	ld	a5,-480(s0)
    80005764:	963e                	add	a2,a2,a5
    80005766:	f6f66ee3          	bltu	a2,a5,800056e2 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000576a:	85a6                	mv	a1,s1
    8000576c:	855a                	mv	a0,s6
    8000576e:	ffffc097          	auipc	ra,0xffffc
    80005772:	c80080e7          	jalr	-896(ra) # 800013ee <uvmalloc>
    80005776:	dea43c23          	sd	a0,-520(s0)
    8000577a:	d53d                	beqz	a0,800056e8 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    8000577c:	e2043c03          	ld	s8,-480(s0)
    80005780:	de043783          	ld	a5,-544(s0)
    80005784:	00fc77b3          	and	a5,s8,a5
    80005788:	ff9d                	bnez	a5,800056c6 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000578a:	e1842c83          	lw	s9,-488(s0)
    8000578e:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005792:	f60b8ae3          	beqz	s7,80005706 <exec+0x312>
    80005796:	89de                	mv	s3,s7
    80005798:	4481                	li	s1,0
    8000579a:	b371                	j	80005526 <exec+0x132>

000000008000579c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000579c:	7179                	addi	sp,sp,-48
    8000579e:	f406                	sd	ra,40(sp)
    800057a0:	f022                	sd	s0,32(sp)
    800057a2:	ec26                	sd	s1,24(sp)
    800057a4:	e84a                	sd	s2,16(sp)
    800057a6:	1800                	addi	s0,sp,48
    800057a8:	892e                	mv	s2,a1
    800057aa:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800057ac:	fdc40593          	addi	a1,s0,-36
    800057b0:	ffffe097          	auipc	ra,0xffffe
    800057b4:	a2c080e7          	jalr	-1492(ra) # 800031dc <argint>
    800057b8:	04054063          	bltz	a0,800057f8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800057bc:	fdc42703          	lw	a4,-36(s0)
    800057c0:	47bd                	li	a5,15
    800057c2:	02e7ed63          	bltu	a5,a4,800057fc <argfd+0x60>
    800057c6:	ffffc097          	auipc	ra,0xffffc
    800057ca:	1fc080e7          	jalr	508(ra) # 800019c2 <myproc>
    800057ce:	fdc42703          	lw	a4,-36(s0)
    800057d2:	01e70793          	addi	a5,a4,30
    800057d6:	078e                	slli	a5,a5,0x3
    800057d8:	953e                	add	a0,a0,a5
    800057da:	651c                	ld	a5,8(a0)
    800057dc:	c395                	beqz	a5,80005800 <argfd+0x64>
    return -1;
  if(pfd)
    800057de:	00090463          	beqz	s2,800057e6 <argfd+0x4a>
    *pfd = fd;
    800057e2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800057e6:	4501                	li	a0,0
  if(pf)
    800057e8:	c091                	beqz	s1,800057ec <argfd+0x50>
    *pf = f;
    800057ea:	e09c                	sd	a5,0(s1)
}
    800057ec:	70a2                	ld	ra,40(sp)
    800057ee:	7402                	ld	s0,32(sp)
    800057f0:	64e2                	ld	s1,24(sp)
    800057f2:	6942                	ld	s2,16(sp)
    800057f4:	6145                	addi	sp,sp,48
    800057f6:	8082                	ret
    return -1;
    800057f8:	557d                	li	a0,-1
    800057fa:	bfcd                	j	800057ec <argfd+0x50>
    return -1;
    800057fc:	557d                	li	a0,-1
    800057fe:	b7fd                	j	800057ec <argfd+0x50>
    80005800:	557d                	li	a0,-1
    80005802:	b7ed                	j	800057ec <argfd+0x50>

0000000080005804 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005804:	1101                	addi	sp,sp,-32
    80005806:	ec06                	sd	ra,24(sp)
    80005808:	e822                	sd	s0,16(sp)
    8000580a:	e426                	sd	s1,8(sp)
    8000580c:	1000                	addi	s0,sp,32
    8000580e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005810:	ffffc097          	auipc	ra,0xffffc
    80005814:	1b2080e7          	jalr	434(ra) # 800019c2 <myproc>
    80005818:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000581a:	0f850793          	addi	a5,a0,248
    8000581e:	4501                	li	a0,0
    80005820:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005822:	6398                	ld	a4,0(a5)
    80005824:	cb19                	beqz	a4,8000583a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005826:	2505                	addiw	a0,a0,1
    80005828:	07a1                	addi	a5,a5,8
    8000582a:	fed51ce3          	bne	a0,a3,80005822 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000582e:	557d                	li	a0,-1
}
    80005830:	60e2                	ld	ra,24(sp)
    80005832:	6442                	ld	s0,16(sp)
    80005834:	64a2                	ld	s1,8(sp)
    80005836:	6105                	addi	sp,sp,32
    80005838:	8082                	ret
      p->ofile[fd] = f;
    8000583a:	01e50793          	addi	a5,a0,30
    8000583e:	078e                	slli	a5,a5,0x3
    80005840:	963e                	add	a2,a2,a5
    80005842:	e604                	sd	s1,8(a2)
      return fd;
    80005844:	b7f5                	j	80005830 <fdalloc+0x2c>

0000000080005846 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005846:	715d                	addi	sp,sp,-80
    80005848:	e486                	sd	ra,72(sp)
    8000584a:	e0a2                	sd	s0,64(sp)
    8000584c:	fc26                	sd	s1,56(sp)
    8000584e:	f84a                	sd	s2,48(sp)
    80005850:	f44e                	sd	s3,40(sp)
    80005852:	f052                	sd	s4,32(sp)
    80005854:	ec56                	sd	s5,24(sp)
    80005856:	0880                	addi	s0,sp,80
    80005858:	89ae                	mv	s3,a1
    8000585a:	8ab2                	mv	s5,a2
    8000585c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000585e:	fb040593          	addi	a1,s0,-80
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	e72080e7          	jalr	-398(ra) # 800046d4 <nameiparent>
    8000586a:	892a                	mv	s2,a0
    8000586c:	12050e63          	beqz	a0,800059a8 <create+0x162>
    return 0;

  ilock(dp);
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	690080e7          	jalr	1680(ra) # 80003f00 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005878:	4601                	li	a2,0
    8000587a:	fb040593          	addi	a1,s0,-80
    8000587e:	854a                	mv	a0,s2
    80005880:	fffff097          	auipc	ra,0xfffff
    80005884:	b64080e7          	jalr	-1180(ra) # 800043e4 <dirlookup>
    80005888:	84aa                	mv	s1,a0
    8000588a:	c921                	beqz	a0,800058da <create+0x94>
    iunlockput(dp);
    8000588c:	854a                	mv	a0,s2
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	8d4080e7          	jalr	-1836(ra) # 80004162 <iunlockput>
    ilock(ip);
    80005896:	8526                	mv	a0,s1
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	668080e7          	jalr	1640(ra) # 80003f00 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800058a0:	2981                	sext.w	s3,s3
    800058a2:	4789                	li	a5,2
    800058a4:	02f99463          	bne	s3,a5,800058cc <create+0x86>
    800058a8:	0444d783          	lhu	a5,68(s1)
    800058ac:	37f9                	addiw	a5,a5,-2
    800058ae:	17c2                	slli	a5,a5,0x30
    800058b0:	93c1                	srli	a5,a5,0x30
    800058b2:	4705                	li	a4,1
    800058b4:	00f76c63          	bltu	a4,a5,800058cc <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800058b8:	8526                	mv	a0,s1
    800058ba:	60a6                	ld	ra,72(sp)
    800058bc:	6406                	ld	s0,64(sp)
    800058be:	74e2                	ld	s1,56(sp)
    800058c0:	7942                	ld	s2,48(sp)
    800058c2:	79a2                	ld	s3,40(sp)
    800058c4:	7a02                	ld	s4,32(sp)
    800058c6:	6ae2                	ld	s5,24(sp)
    800058c8:	6161                	addi	sp,sp,80
    800058ca:	8082                	ret
    iunlockput(ip);
    800058cc:	8526                	mv	a0,s1
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	894080e7          	jalr	-1900(ra) # 80004162 <iunlockput>
    return 0;
    800058d6:	4481                	li	s1,0
    800058d8:	b7c5                	j	800058b8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800058da:	85ce                	mv	a1,s3
    800058dc:	00092503          	lw	a0,0(s2)
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	488080e7          	jalr	1160(ra) # 80003d68 <ialloc>
    800058e8:	84aa                	mv	s1,a0
    800058ea:	c521                	beqz	a0,80005932 <create+0xec>
  ilock(ip);
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	614080e7          	jalr	1556(ra) # 80003f00 <ilock>
  ip->major = major;
    800058f4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800058f8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800058fc:	4a05                	li	s4,1
    800058fe:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005902:	8526                	mv	a0,s1
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	532080e7          	jalr	1330(ra) # 80003e36 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000590c:	2981                	sext.w	s3,s3
    8000590e:	03498a63          	beq	s3,s4,80005942 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005912:	40d0                	lw	a2,4(s1)
    80005914:	fb040593          	addi	a1,s0,-80
    80005918:	854a                	mv	a0,s2
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	cda080e7          	jalr	-806(ra) # 800045f4 <dirlink>
    80005922:	06054b63          	bltz	a0,80005998 <create+0x152>
  iunlockput(dp);
    80005926:	854a                	mv	a0,s2
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	83a080e7          	jalr	-1990(ra) # 80004162 <iunlockput>
  return ip;
    80005930:	b761                	j	800058b8 <create+0x72>
    panic("create: ialloc");
    80005932:	00003517          	auipc	a0,0x3
    80005936:	fde50513          	addi	a0,a0,-34 # 80008910 <syscalls+0x2b8>
    8000593a:	ffffb097          	auipc	ra,0xffffb
    8000593e:	bf0080e7          	jalr	-1040(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005942:	04a95783          	lhu	a5,74(s2)
    80005946:	2785                	addiw	a5,a5,1
    80005948:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000594c:	854a                	mv	a0,s2
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	4e8080e7          	jalr	1256(ra) # 80003e36 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005956:	40d0                	lw	a2,4(s1)
    80005958:	00003597          	auipc	a1,0x3
    8000595c:	fc858593          	addi	a1,a1,-56 # 80008920 <syscalls+0x2c8>
    80005960:	8526                	mv	a0,s1
    80005962:	fffff097          	auipc	ra,0xfffff
    80005966:	c92080e7          	jalr	-878(ra) # 800045f4 <dirlink>
    8000596a:	00054f63          	bltz	a0,80005988 <create+0x142>
    8000596e:	00492603          	lw	a2,4(s2)
    80005972:	00003597          	auipc	a1,0x3
    80005976:	fb658593          	addi	a1,a1,-74 # 80008928 <syscalls+0x2d0>
    8000597a:	8526                	mv	a0,s1
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	c78080e7          	jalr	-904(ra) # 800045f4 <dirlink>
    80005984:	f80557e3          	bgez	a0,80005912 <create+0xcc>
      panic("create dots");
    80005988:	00003517          	auipc	a0,0x3
    8000598c:	fa850513          	addi	a0,a0,-88 # 80008930 <syscalls+0x2d8>
    80005990:	ffffb097          	auipc	ra,0xffffb
    80005994:	b9a080e7          	jalr	-1126(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005998:	00003517          	auipc	a0,0x3
    8000599c:	fa850513          	addi	a0,a0,-88 # 80008940 <syscalls+0x2e8>
    800059a0:	ffffb097          	auipc	ra,0xffffb
    800059a4:	b8a080e7          	jalr	-1142(ra) # 8000052a <panic>
    return 0;
    800059a8:	84aa                	mv	s1,a0
    800059aa:	b739                	j	800058b8 <create+0x72>

00000000800059ac <sys_dup>:
{
    800059ac:	7179                	addi	sp,sp,-48
    800059ae:	f406                	sd	ra,40(sp)
    800059b0:	f022                	sd	s0,32(sp)
    800059b2:	ec26                	sd	s1,24(sp)
    800059b4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800059b6:	fd840613          	addi	a2,s0,-40
    800059ba:	4581                	li	a1,0
    800059bc:	4501                	li	a0,0
    800059be:	00000097          	auipc	ra,0x0
    800059c2:	dde080e7          	jalr	-546(ra) # 8000579c <argfd>
    return -1;
    800059c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800059c8:	02054363          	bltz	a0,800059ee <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800059cc:	fd843503          	ld	a0,-40(s0)
    800059d0:	00000097          	auipc	ra,0x0
    800059d4:	e34080e7          	jalr	-460(ra) # 80005804 <fdalloc>
    800059d8:	84aa                	mv	s1,a0
    return -1;
    800059da:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800059dc:	00054963          	bltz	a0,800059ee <sys_dup+0x42>
  filedup(f);
    800059e0:	fd843503          	ld	a0,-40(s0)
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	36c080e7          	jalr	876(ra) # 80004d50 <filedup>
  return fd;
    800059ec:	87a6                	mv	a5,s1
}
    800059ee:	853e                	mv	a0,a5
    800059f0:	70a2                	ld	ra,40(sp)
    800059f2:	7402                	ld	s0,32(sp)
    800059f4:	64e2                	ld	s1,24(sp)
    800059f6:	6145                	addi	sp,sp,48
    800059f8:	8082                	ret

00000000800059fa <sys_read>:
{
    800059fa:	7179                	addi	sp,sp,-48
    800059fc:	f406                	sd	ra,40(sp)
    800059fe:	f022                	sd	s0,32(sp)
    80005a00:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a02:	fe840613          	addi	a2,s0,-24
    80005a06:	4581                	li	a1,0
    80005a08:	4501                	li	a0,0
    80005a0a:	00000097          	auipc	ra,0x0
    80005a0e:	d92080e7          	jalr	-622(ra) # 8000579c <argfd>
    return -1;
    80005a12:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a14:	04054163          	bltz	a0,80005a56 <sys_read+0x5c>
    80005a18:	fe440593          	addi	a1,s0,-28
    80005a1c:	4509                	li	a0,2
    80005a1e:	ffffd097          	auipc	ra,0xffffd
    80005a22:	7be080e7          	jalr	1982(ra) # 800031dc <argint>
    return -1;
    80005a26:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a28:	02054763          	bltz	a0,80005a56 <sys_read+0x5c>
    80005a2c:	fd840593          	addi	a1,s0,-40
    80005a30:	4505                	li	a0,1
    80005a32:	ffffd097          	auipc	ra,0xffffd
    80005a36:	7cc080e7          	jalr	1996(ra) # 800031fe <argaddr>
    return -1;
    80005a3a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a3c:	00054d63          	bltz	a0,80005a56 <sys_read+0x5c>
  return fileread(f, p, n);
    80005a40:	fe442603          	lw	a2,-28(s0)
    80005a44:	fd843583          	ld	a1,-40(s0)
    80005a48:	fe843503          	ld	a0,-24(s0)
    80005a4c:	fffff097          	auipc	ra,0xfffff
    80005a50:	490080e7          	jalr	1168(ra) # 80004edc <fileread>
    80005a54:	87aa                	mv	a5,a0
}
    80005a56:	853e                	mv	a0,a5
    80005a58:	70a2                	ld	ra,40(sp)
    80005a5a:	7402                	ld	s0,32(sp)
    80005a5c:	6145                	addi	sp,sp,48
    80005a5e:	8082                	ret

0000000080005a60 <sys_write>:
{
    80005a60:	7179                	addi	sp,sp,-48
    80005a62:	f406                	sd	ra,40(sp)
    80005a64:	f022                	sd	s0,32(sp)
    80005a66:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a68:	fe840613          	addi	a2,s0,-24
    80005a6c:	4581                	li	a1,0
    80005a6e:	4501                	li	a0,0
    80005a70:	00000097          	auipc	ra,0x0
    80005a74:	d2c080e7          	jalr	-724(ra) # 8000579c <argfd>
    return -1;
    80005a78:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a7a:	04054163          	bltz	a0,80005abc <sys_write+0x5c>
    80005a7e:	fe440593          	addi	a1,s0,-28
    80005a82:	4509                	li	a0,2
    80005a84:	ffffd097          	auipc	ra,0xffffd
    80005a88:	758080e7          	jalr	1880(ra) # 800031dc <argint>
    return -1;
    80005a8c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005a8e:	02054763          	bltz	a0,80005abc <sys_write+0x5c>
    80005a92:	fd840593          	addi	a1,s0,-40
    80005a96:	4505                	li	a0,1
    80005a98:	ffffd097          	auipc	ra,0xffffd
    80005a9c:	766080e7          	jalr	1894(ra) # 800031fe <argaddr>
    return -1;
    80005aa0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005aa2:	00054d63          	bltz	a0,80005abc <sys_write+0x5c>
  return filewrite(f, p, n);
    80005aa6:	fe442603          	lw	a2,-28(s0)
    80005aaa:	fd843583          	ld	a1,-40(s0)
    80005aae:	fe843503          	ld	a0,-24(s0)
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	4ec080e7          	jalr	1260(ra) # 80004f9e <filewrite>
    80005aba:	87aa                	mv	a5,a0
}
    80005abc:	853e                	mv	a0,a5
    80005abe:	70a2                	ld	ra,40(sp)
    80005ac0:	7402                	ld	s0,32(sp)
    80005ac2:	6145                	addi	sp,sp,48
    80005ac4:	8082                	ret

0000000080005ac6 <sys_close>:
{
    80005ac6:	1101                	addi	sp,sp,-32
    80005ac8:	ec06                	sd	ra,24(sp)
    80005aca:	e822                	sd	s0,16(sp)
    80005acc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005ace:	fe040613          	addi	a2,s0,-32
    80005ad2:	fec40593          	addi	a1,s0,-20
    80005ad6:	4501                	li	a0,0
    80005ad8:	00000097          	auipc	ra,0x0
    80005adc:	cc4080e7          	jalr	-828(ra) # 8000579c <argfd>
    return -1;
    80005ae0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005ae2:	02054463          	bltz	a0,80005b0a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005ae6:	ffffc097          	auipc	ra,0xffffc
    80005aea:	edc080e7          	jalr	-292(ra) # 800019c2 <myproc>
    80005aee:	fec42783          	lw	a5,-20(s0)
    80005af2:	07f9                	addi	a5,a5,30
    80005af4:	078e                	slli	a5,a5,0x3
    80005af6:	97aa                	add	a5,a5,a0
    80005af8:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005afc:	fe043503          	ld	a0,-32(s0)
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	2a2080e7          	jalr	674(ra) # 80004da2 <fileclose>
  return 0;
    80005b08:	4781                	li	a5,0
}
    80005b0a:	853e                	mv	a0,a5
    80005b0c:	60e2                	ld	ra,24(sp)
    80005b0e:	6442                	ld	s0,16(sp)
    80005b10:	6105                	addi	sp,sp,32
    80005b12:	8082                	ret

0000000080005b14 <sys_fstat>:
{
    80005b14:	1101                	addi	sp,sp,-32
    80005b16:	ec06                	sd	ra,24(sp)
    80005b18:	e822                	sd	s0,16(sp)
    80005b1a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b1c:	fe840613          	addi	a2,s0,-24
    80005b20:	4581                	li	a1,0
    80005b22:	4501                	li	a0,0
    80005b24:	00000097          	auipc	ra,0x0
    80005b28:	c78080e7          	jalr	-904(ra) # 8000579c <argfd>
    return -1;
    80005b2c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b2e:	02054563          	bltz	a0,80005b58 <sys_fstat+0x44>
    80005b32:	fe040593          	addi	a1,s0,-32
    80005b36:	4505                	li	a0,1
    80005b38:	ffffd097          	auipc	ra,0xffffd
    80005b3c:	6c6080e7          	jalr	1734(ra) # 800031fe <argaddr>
    return -1;
    80005b40:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005b42:	00054b63          	bltz	a0,80005b58 <sys_fstat+0x44>
  return filestat(f, st);
    80005b46:	fe043583          	ld	a1,-32(s0)
    80005b4a:	fe843503          	ld	a0,-24(s0)
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	31c080e7          	jalr	796(ra) # 80004e6a <filestat>
    80005b56:	87aa                	mv	a5,a0
}
    80005b58:	853e                	mv	a0,a5
    80005b5a:	60e2                	ld	ra,24(sp)
    80005b5c:	6442                	ld	s0,16(sp)
    80005b5e:	6105                	addi	sp,sp,32
    80005b60:	8082                	ret

0000000080005b62 <sys_link>:
{
    80005b62:	7169                	addi	sp,sp,-304
    80005b64:	f606                	sd	ra,296(sp)
    80005b66:	f222                	sd	s0,288(sp)
    80005b68:	ee26                	sd	s1,280(sp)
    80005b6a:	ea4a                	sd	s2,272(sp)
    80005b6c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b6e:	08000613          	li	a2,128
    80005b72:	ed040593          	addi	a1,s0,-304
    80005b76:	4501                	li	a0,0
    80005b78:	ffffd097          	auipc	ra,0xffffd
    80005b7c:	6a8080e7          	jalr	1704(ra) # 80003220 <argstr>
    return -1;
    80005b80:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b82:	10054e63          	bltz	a0,80005c9e <sys_link+0x13c>
    80005b86:	08000613          	li	a2,128
    80005b8a:	f5040593          	addi	a1,s0,-176
    80005b8e:	4505                	li	a0,1
    80005b90:	ffffd097          	auipc	ra,0xffffd
    80005b94:	690080e7          	jalr	1680(ra) # 80003220 <argstr>
    return -1;
    80005b98:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b9a:	10054263          	bltz	a0,80005c9e <sys_link+0x13c>
  begin_op();
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	d38080e7          	jalr	-712(ra) # 800048d6 <begin_op>
  if((ip = namei(old)) == 0){
    80005ba6:	ed040513          	addi	a0,s0,-304
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	b0c080e7          	jalr	-1268(ra) # 800046b6 <namei>
    80005bb2:	84aa                	mv	s1,a0
    80005bb4:	c551                	beqz	a0,80005c40 <sys_link+0xde>
  ilock(ip);
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	34a080e7          	jalr	842(ra) # 80003f00 <ilock>
  if(ip->type == T_DIR){
    80005bbe:	04449703          	lh	a4,68(s1)
    80005bc2:	4785                	li	a5,1
    80005bc4:	08f70463          	beq	a4,a5,80005c4c <sys_link+0xea>
  ip->nlink++;
    80005bc8:	04a4d783          	lhu	a5,74(s1)
    80005bcc:	2785                	addiw	a5,a5,1
    80005bce:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005bd2:	8526                	mv	a0,s1
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	262080e7          	jalr	610(ra) # 80003e36 <iupdate>
  iunlock(ip);
    80005bdc:	8526                	mv	a0,s1
    80005bde:	ffffe097          	auipc	ra,0xffffe
    80005be2:	3e4080e7          	jalr	996(ra) # 80003fc2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005be6:	fd040593          	addi	a1,s0,-48
    80005bea:	f5040513          	addi	a0,s0,-176
    80005bee:	fffff097          	auipc	ra,0xfffff
    80005bf2:	ae6080e7          	jalr	-1306(ra) # 800046d4 <nameiparent>
    80005bf6:	892a                	mv	s2,a0
    80005bf8:	c935                	beqz	a0,80005c6c <sys_link+0x10a>
  ilock(dp);
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	306080e7          	jalr	774(ra) # 80003f00 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005c02:	00092703          	lw	a4,0(s2)
    80005c06:	409c                	lw	a5,0(s1)
    80005c08:	04f71d63          	bne	a4,a5,80005c62 <sys_link+0x100>
    80005c0c:	40d0                	lw	a2,4(s1)
    80005c0e:	fd040593          	addi	a1,s0,-48
    80005c12:	854a                	mv	a0,s2
    80005c14:	fffff097          	auipc	ra,0xfffff
    80005c18:	9e0080e7          	jalr	-1568(ra) # 800045f4 <dirlink>
    80005c1c:	04054363          	bltz	a0,80005c62 <sys_link+0x100>
  iunlockput(dp);
    80005c20:	854a                	mv	a0,s2
    80005c22:	ffffe097          	auipc	ra,0xffffe
    80005c26:	540080e7          	jalr	1344(ra) # 80004162 <iunlockput>
  iput(ip);
    80005c2a:	8526                	mv	a0,s1
    80005c2c:	ffffe097          	auipc	ra,0xffffe
    80005c30:	48e080e7          	jalr	1166(ra) # 800040ba <iput>
  end_op();
    80005c34:	fffff097          	auipc	ra,0xfffff
    80005c38:	d22080e7          	jalr	-734(ra) # 80004956 <end_op>
  return 0;
    80005c3c:	4781                	li	a5,0
    80005c3e:	a085                	j	80005c9e <sys_link+0x13c>
    end_op();
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	d16080e7          	jalr	-746(ra) # 80004956 <end_op>
    return -1;
    80005c48:	57fd                	li	a5,-1
    80005c4a:	a891                	j	80005c9e <sys_link+0x13c>
    iunlockput(ip);
    80005c4c:	8526                	mv	a0,s1
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	514080e7          	jalr	1300(ra) # 80004162 <iunlockput>
    end_op();
    80005c56:	fffff097          	auipc	ra,0xfffff
    80005c5a:	d00080e7          	jalr	-768(ra) # 80004956 <end_op>
    return -1;
    80005c5e:	57fd                	li	a5,-1
    80005c60:	a83d                	j	80005c9e <sys_link+0x13c>
    iunlockput(dp);
    80005c62:	854a                	mv	a0,s2
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	4fe080e7          	jalr	1278(ra) # 80004162 <iunlockput>
  ilock(ip);
    80005c6c:	8526                	mv	a0,s1
    80005c6e:	ffffe097          	auipc	ra,0xffffe
    80005c72:	292080e7          	jalr	658(ra) # 80003f00 <ilock>
  ip->nlink--;
    80005c76:	04a4d783          	lhu	a5,74(s1)
    80005c7a:	37fd                	addiw	a5,a5,-1
    80005c7c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c80:	8526                	mv	a0,s1
    80005c82:	ffffe097          	auipc	ra,0xffffe
    80005c86:	1b4080e7          	jalr	436(ra) # 80003e36 <iupdate>
  iunlockput(ip);
    80005c8a:	8526                	mv	a0,s1
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	4d6080e7          	jalr	1238(ra) # 80004162 <iunlockput>
  end_op();
    80005c94:	fffff097          	auipc	ra,0xfffff
    80005c98:	cc2080e7          	jalr	-830(ra) # 80004956 <end_op>
  return -1;
    80005c9c:	57fd                	li	a5,-1
}
    80005c9e:	853e                	mv	a0,a5
    80005ca0:	70b2                	ld	ra,296(sp)
    80005ca2:	7412                	ld	s0,288(sp)
    80005ca4:	64f2                	ld	s1,280(sp)
    80005ca6:	6952                	ld	s2,272(sp)
    80005ca8:	6155                	addi	sp,sp,304
    80005caa:	8082                	ret

0000000080005cac <sys_unlink>:
{
    80005cac:	7151                	addi	sp,sp,-240
    80005cae:	f586                	sd	ra,232(sp)
    80005cb0:	f1a2                	sd	s0,224(sp)
    80005cb2:	eda6                	sd	s1,216(sp)
    80005cb4:	e9ca                	sd	s2,208(sp)
    80005cb6:	e5ce                	sd	s3,200(sp)
    80005cb8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005cba:	08000613          	li	a2,128
    80005cbe:	f3040593          	addi	a1,s0,-208
    80005cc2:	4501                	li	a0,0
    80005cc4:	ffffd097          	auipc	ra,0xffffd
    80005cc8:	55c080e7          	jalr	1372(ra) # 80003220 <argstr>
    80005ccc:	18054163          	bltz	a0,80005e4e <sys_unlink+0x1a2>
  begin_op();
    80005cd0:	fffff097          	auipc	ra,0xfffff
    80005cd4:	c06080e7          	jalr	-1018(ra) # 800048d6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005cd8:	fb040593          	addi	a1,s0,-80
    80005cdc:	f3040513          	addi	a0,s0,-208
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	9f4080e7          	jalr	-1548(ra) # 800046d4 <nameiparent>
    80005ce8:	84aa                	mv	s1,a0
    80005cea:	c979                	beqz	a0,80005dc0 <sys_unlink+0x114>
  ilock(dp);
    80005cec:	ffffe097          	auipc	ra,0xffffe
    80005cf0:	214080e7          	jalr	532(ra) # 80003f00 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005cf4:	00003597          	auipc	a1,0x3
    80005cf8:	c2c58593          	addi	a1,a1,-980 # 80008920 <syscalls+0x2c8>
    80005cfc:	fb040513          	addi	a0,s0,-80
    80005d00:	ffffe097          	auipc	ra,0xffffe
    80005d04:	6ca080e7          	jalr	1738(ra) # 800043ca <namecmp>
    80005d08:	14050a63          	beqz	a0,80005e5c <sys_unlink+0x1b0>
    80005d0c:	00003597          	auipc	a1,0x3
    80005d10:	c1c58593          	addi	a1,a1,-996 # 80008928 <syscalls+0x2d0>
    80005d14:	fb040513          	addi	a0,s0,-80
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	6b2080e7          	jalr	1714(ra) # 800043ca <namecmp>
    80005d20:	12050e63          	beqz	a0,80005e5c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005d24:	f2c40613          	addi	a2,s0,-212
    80005d28:	fb040593          	addi	a1,s0,-80
    80005d2c:	8526                	mv	a0,s1
    80005d2e:	ffffe097          	auipc	ra,0xffffe
    80005d32:	6b6080e7          	jalr	1718(ra) # 800043e4 <dirlookup>
    80005d36:	892a                	mv	s2,a0
    80005d38:	12050263          	beqz	a0,80005e5c <sys_unlink+0x1b0>
  ilock(ip);
    80005d3c:	ffffe097          	auipc	ra,0xffffe
    80005d40:	1c4080e7          	jalr	452(ra) # 80003f00 <ilock>
  if(ip->nlink < 1)
    80005d44:	04a91783          	lh	a5,74(s2)
    80005d48:	08f05263          	blez	a5,80005dcc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005d4c:	04491703          	lh	a4,68(s2)
    80005d50:	4785                	li	a5,1
    80005d52:	08f70563          	beq	a4,a5,80005ddc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005d56:	4641                	li	a2,16
    80005d58:	4581                	li	a1,0
    80005d5a:	fc040513          	addi	a0,s0,-64
    80005d5e:	ffffb097          	auipc	ra,0xffffb
    80005d62:	f60080e7          	jalr	-160(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d66:	4741                	li	a4,16
    80005d68:	f2c42683          	lw	a3,-212(s0)
    80005d6c:	fc040613          	addi	a2,s0,-64
    80005d70:	4581                	li	a1,0
    80005d72:	8526                	mv	a0,s1
    80005d74:	ffffe097          	auipc	ra,0xffffe
    80005d78:	538080e7          	jalr	1336(ra) # 800042ac <writei>
    80005d7c:	47c1                	li	a5,16
    80005d7e:	0af51563          	bne	a0,a5,80005e28 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005d82:	04491703          	lh	a4,68(s2)
    80005d86:	4785                	li	a5,1
    80005d88:	0af70863          	beq	a4,a5,80005e38 <sys_unlink+0x18c>
  iunlockput(dp);
    80005d8c:	8526                	mv	a0,s1
    80005d8e:	ffffe097          	auipc	ra,0xffffe
    80005d92:	3d4080e7          	jalr	980(ra) # 80004162 <iunlockput>
  ip->nlink--;
    80005d96:	04a95783          	lhu	a5,74(s2)
    80005d9a:	37fd                	addiw	a5,a5,-1
    80005d9c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005da0:	854a                	mv	a0,s2
    80005da2:	ffffe097          	auipc	ra,0xffffe
    80005da6:	094080e7          	jalr	148(ra) # 80003e36 <iupdate>
  iunlockput(ip);
    80005daa:	854a                	mv	a0,s2
    80005dac:	ffffe097          	auipc	ra,0xffffe
    80005db0:	3b6080e7          	jalr	950(ra) # 80004162 <iunlockput>
  end_op();
    80005db4:	fffff097          	auipc	ra,0xfffff
    80005db8:	ba2080e7          	jalr	-1118(ra) # 80004956 <end_op>
  return 0;
    80005dbc:	4501                	li	a0,0
    80005dbe:	a84d                	j	80005e70 <sys_unlink+0x1c4>
    end_op();
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	b96080e7          	jalr	-1130(ra) # 80004956 <end_op>
    return -1;
    80005dc8:	557d                	li	a0,-1
    80005dca:	a05d                	j	80005e70 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005dcc:	00003517          	auipc	a0,0x3
    80005dd0:	b8450513          	addi	a0,a0,-1148 # 80008950 <syscalls+0x2f8>
    80005dd4:	ffffa097          	auipc	ra,0xffffa
    80005dd8:	756080e7          	jalr	1878(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ddc:	04c92703          	lw	a4,76(s2)
    80005de0:	02000793          	li	a5,32
    80005de4:	f6e7f9e3          	bgeu	a5,a4,80005d56 <sys_unlink+0xaa>
    80005de8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005dec:	4741                	li	a4,16
    80005dee:	86ce                	mv	a3,s3
    80005df0:	f1840613          	addi	a2,s0,-232
    80005df4:	4581                	li	a1,0
    80005df6:	854a                	mv	a0,s2
    80005df8:	ffffe097          	auipc	ra,0xffffe
    80005dfc:	3bc080e7          	jalr	956(ra) # 800041b4 <readi>
    80005e00:	47c1                	li	a5,16
    80005e02:	00f51b63          	bne	a0,a5,80005e18 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005e06:	f1845783          	lhu	a5,-232(s0)
    80005e0a:	e7a1                	bnez	a5,80005e52 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e0c:	29c1                	addiw	s3,s3,16
    80005e0e:	04c92783          	lw	a5,76(s2)
    80005e12:	fcf9ede3          	bltu	s3,a5,80005dec <sys_unlink+0x140>
    80005e16:	b781                	j	80005d56 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005e18:	00003517          	auipc	a0,0x3
    80005e1c:	b5050513          	addi	a0,a0,-1200 # 80008968 <syscalls+0x310>
    80005e20:	ffffa097          	auipc	ra,0xffffa
    80005e24:	70a080e7          	jalr	1802(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005e28:	00003517          	auipc	a0,0x3
    80005e2c:	b5850513          	addi	a0,a0,-1192 # 80008980 <syscalls+0x328>
    80005e30:	ffffa097          	auipc	ra,0xffffa
    80005e34:	6fa080e7          	jalr	1786(ra) # 8000052a <panic>
    dp->nlink--;
    80005e38:	04a4d783          	lhu	a5,74(s1)
    80005e3c:	37fd                	addiw	a5,a5,-1
    80005e3e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005e42:	8526                	mv	a0,s1
    80005e44:	ffffe097          	auipc	ra,0xffffe
    80005e48:	ff2080e7          	jalr	-14(ra) # 80003e36 <iupdate>
    80005e4c:	b781                	j	80005d8c <sys_unlink+0xe0>
    return -1;
    80005e4e:	557d                	li	a0,-1
    80005e50:	a005                	j	80005e70 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005e52:	854a                	mv	a0,s2
    80005e54:	ffffe097          	auipc	ra,0xffffe
    80005e58:	30e080e7          	jalr	782(ra) # 80004162 <iunlockput>
  iunlockput(dp);
    80005e5c:	8526                	mv	a0,s1
    80005e5e:	ffffe097          	auipc	ra,0xffffe
    80005e62:	304080e7          	jalr	772(ra) # 80004162 <iunlockput>
  end_op();
    80005e66:	fffff097          	auipc	ra,0xfffff
    80005e6a:	af0080e7          	jalr	-1296(ra) # 80004956 <end_op>
  return -1;
    80005e6e:	557d                	li	a0,-1
}
    80005e70:	70ae                	ld	ra,232(sp)
    80005e72:	740e                	ld	s0,224(sp)
    80005e74:	64ee                	ld	s1,216(sp)
    80005e76:	694e                	ld	s2,208(sp)
    80005e78:	69ae                	ld	s3,200(sp)
    80005e7a:	616d                	addi	sp,sp,240
    80005e7c:	8082                	ret

0000000080005e7e <sys_open>:

uint64
sys_open(void)
{
    80005e7e:	7131                	addi	sp,sp,-192
    80005e80:	fd06                	sd	ra,184(sp)
    80005e82:	f922                	sd	s0,176(sp)
    80005e84:	f526                	sd	s1,168(sp)
    80005e86:	f14a                	sd	s2,160(sp)
    80005e88:	ed4e                	sd	s3,152(sp)
    80005e8a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005e8c:	08000613          	li	a2,128
    80005e90:	f5040593          	addi	a1,s0,-176
    80005e94:	4501                	li	a0,0
    80005e96:	ffffd097          	auipc	ra,0xffffd
    80005e9a:	38a080e7          	jalr	906(ra) # 80003220 <argstr>
    return -1;
    80005e9e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ea0:	0c054163          	bltz	a0,80005f62 <sys_open+0xe4>
    80005ea4:	f4c40593          	addi	a1,s0,-180
    80005ea8:	4505                	li	a0,1
    80005eaa:	ffffd097          	auipc	ra,0xffffd
    80005eae:	332080e7          	jalr	818(ra) # 800031dc <argint>
    80005eb2:	0a054863          	bltz	a0,80005f62 <sys_open+0xe4>

  begin_op();
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	a20080e7          	jalr	-1504(ra) # 800048d6 <begin_op>

  if(omode & O_CREATE){
    80005ebe:	f4c42783          	lw	a5,-180(s0)
    80005ec2:	2007f793          	andi	a5,a5,512
    80005ec6:	cbdd                	beqz	a5,80005f7c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ec8:	4681                	li	a3,0
    80005eca:	4601                	li	a2,0
    80005ecc:	4589                	li	a1,2
    80005ece:	f5040513          	addi	a0,s0,-176
    80005ed2:	00000097          	auipc	ra,0x0
    80005ed6:	974080e7          	jalr	-1676(ra) # 80005846 <create>
    80005eda:	892a                	mv	s2,a0
    if(ip == 0){
    80005edc:	c959                	beqz	a0,80005f72 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ede:	04491703          	lh	a4,68(s2)
    80005ee2:	478d                	li	a5,3
    80005ee4:	00f71763          	bne	a4,a5,80005ef2 <sys_open+0x74>
    80005ee8:	04695703          	lhu	a4,70(s2)
    80005eec:	47a5                	li	a5,9
    80005eee:	0ce7ec63          	bltu	a5,a4,80005fc6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ef2:	fffff097          	auipc	ra,0xfffff
    80005ef6:	df4080e7          	jalr	-524(ra) # 80004ce6 <filealloc>
    80005efa:	89aa                	mv	s3,a0
    80005efc:	10050263          	beqz	a0,80006000 <sys_open+0x182>
    80005f00:	00000097          	auipc	ra,0x0
    80005f04:	904080e7          	jalr	-1788(ra) # 80005804 <fdalloc>
    80005f08:	84aa                	mv	s1,a0
    80005f0a:	0e054663          	bltz	a0,80005ff6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005f0e:	04491703          	lh	a4,68(s2)
    80005f12:	478d                	li	a5,3
    80005f14:	0cf70463          	beq	a4,a5,80005fdc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005f18:	4789                	li	a5,2
    80005f1a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005f1e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005f22:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005f26:	f4c42783          	lw	a5,-180(s0)
    80005f2a:	0017c713          	xori	a4,a5,1
    80005f2e:	8b05                	andi	a4,a4,1
    80005f30:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005f34:	0037f713          	andi	a4,a5,3
    80005f38:	00e03733          	snez	a4,a4
    80005f3c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005f40:	4007f793          	andi	a5,a5,1024
    80005f44:	c791                	beqz	a5,80005f50 <sys_open+0xd2>
    80005f46:	04491703          	lh	a4,68(s2)
    80005f4a:	4789                	li	a5,2
    80005f4c:	08f70f63          	beq	a4,a5,80005fea <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005f50:	854a                	mv	a0,s2
    80005f52:	ffffe097          	auipc	ra,0xffffe
    80005f56:	070080e7          	jalr	112(ra) # 80003fc2 <iunlock>
  end_op();
    80005f5a:	fffff097          	auipc	ra,0xfffff
    80005f5e:	9fc080e7          	jalr	-1540(ra) # 80004956 <end_op>

  return fd;
}
    80005f62:	8526                	mv	a0,s1
    80005f64:	70ea                	ld	ra,184(sp)
    80005f66:	744a                	ld	s0,176(sp)
    80005f68:	74aa                	ld	s1,168(sp)
    80005f6a:	790a                	ld	s2,160(sp)
    80005f6c:	69ea                	ld	s3,152(sp)
    80005f6e:	6129                	addi	sp,sp,192
    80005f70:	8082                	ret
      end_op();
    80005f72:	fffff097          	auipc	ra,0xfffff
    80005f76:	9e4080e7          	jalr	-1564(ra) # 80004956 <end_op>
      return -1;
    80005f7a:	b7e5                	j	80005f62 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005f7c:	f5040513          	addi	a0,s0,-176
    80005f80:	ffffe097          	auipc	ra,0xffffe
    80005f84:	736080e7          	jalr	1846(ra) # 800046b6 <namei>
    80005f88:	892a                	mv	s2,a0
    80005f8a:	c905                	beqz	a0,80005fba <sys_open+0x13c>
    ilock(ip);
    80005f8c:	ffffe097          	auipc	ra,0xffffe
    80005f90:	f74080e7          	jalr	-140(ra) # 80003f00 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005f94:	04491703          	lh	a4,68(s2)
    80005f98:	4785                	li	a5,1
    80005f9a:	f4f712e3          	bne	a4,a5,80005ede <sys_open+0x60>
    80005f9e:	f4c42783          	lw	a5,-180(s0)
    80005fa2:	dba1                	beqz	a5,80005ef2 <sys_open+0x74>
      iunlockput(ip);
    80005fa4:	854a                	mv	a0,s2
    80005fa6:	ffffe097          	auipc	ra,0xffffe
    80005faa:	1bc080e7          	jalr	444(ra) # 80004162 <iunlockput>
      end_op();
    80005fae:	fffff097          	auipc	ra,0xfffff
    80005fb2:	9a8080e7          	jalr	-1624(ra) # 80004956 <end_op>
      return -1;
    80005fb6:	54fd                	li	s1,-1
    80005fb8:	b76d                	j	80005f62 <sys_open+0xe4>
      end_op();
    80005fba:	fffff097          	auipc	ra,0xfffff
    80005fbe:	99c080e7          	jalr	-1636(ra) # 80004956 <end_op>
      return -1;
    80005fc2:	54fd                	li	s1,-1
    80005fc4:	bf79                	j	80005f62 <sys_open+0xe4>
    iunlockput(ip);
    80005fc6:	854a                	mv	a0,s2
    80005fc8:	ffffe097          	auipc	ra,0xffffe
    80005fcc:	19a080e7          	jalr	410(ra) # 80004162 <iunlockput>
    end_op();
    80005fd0:	fffff097          	auipc	ra,0xfffff
    80005fd4:	986080e7          	jalr	-1658(ra) # 80004956 <end_op>
    return -1;
    80005fd8:	54fd                	li	s1,-1
    80005fda:	b761                	j	80005f62 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005fdc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005fe0:	04691783          	lh	a5,70(s2)
    80005fe4:	02f99223          	sh	a5,36(s3)
    80005fe8:	bf2d                	j	80005f22 <sys_open+0xa4>
    itrunc(ip);
    80005fea:	854a                	mv	a0,s2
    80005fec:	ffffe097          	auipc	ra,0xffffe
    80005ff0:	022080e7          	jalr	34(ra) # 8000400e <itrunc>
    80005ff4:	bfb1                	j	80005f50 <sys_open+0xd2>
      fileclose(f);
    80005ff6:	854e                	mv	a0,s3
    80005ff8:	fffff097          	auipc	ra,0xfffff
    80005ffc:	daa080e7          	jalr	-598(ra) # 80004da2 <fileclose>
    iunlockput(ip);
    80006000:	854a                	mv	a0,s2
    80006002:	ffffe097          	auipc	ra,0xffffe
    80006006:	160080e7          	jalr	352(ra) # 80004162 <iunlockput>
    end_op();
    8000600a:	fffff097          	auipc	ra,0xfffff
    8000600e:	94c080e7          	jalr	-1716(ra) # 80004956 <end_op>
    return -1;
    80006012:	54fd                	li	s1,-1
    80006014:	b7b9                	j	80005f62 <sys_open+0xe4>

0000000080006016 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006016:	7175                	addi	sp,sp,-144
    80006018:	e506                	sd	ra,136(sp)
    8000601a:	e122                	sd	s0,128(sp)
    8000601c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000601e:	fffff097          	auipc	ra,0xfffff
    80006022:	8b8080e7          	jalr	-1864(ra) # 800048d6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006026:	08000613          	li	a2,128
    8000602a:	f7040593          	addi	a1,s0,-144
    8000602e:	4501                	li	a0,0
    80006030:	ffffd097          	auipc	ra,0xffffd
    80006034:	1f0080e7          	jalr	496(ra) # 80003220 <argstr>
    80006038:	02054963          	bltz	a0,8000606a <sys_mkdir+0x54>
    8000603c:	4681                	li	a3,0
    8000603e:	4601                	li	a2,0
    80006040:	4585                	li	a1,1
    80006042:	f7040513          	addi	a0,s0,-144
    80006046:	00000097          	auipc	ra,0x0
    8000604a:	800080e7          	jalr	-2048(ra) # 80005846 <create>
    8000604e:	cd11                	beqz	a0,8000606a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006050:	ffffe097          	auipc	ra,0xffffe
    80006054:	112080e7          	jalr	274(ra) # 80004162 <iunlockput>
  end_op();
    80006058:	fffff097          	auipc	ra,0xfffff
    8000605c:	8fe080e7          	jalr	-1794(ra) # 80004956 <end_op>
  return 0;
    80006060:	4501                	li	a0,0
}
    80006062:	60aa                	ld	ra,136(sp)
    80006064:	640a                	ld	s0,128(sp)
    80006066:	6149                	addi	sp,sp,144
    80006068:	8082                	ret
    end_op();
    8000606a:	fffff097          	auipc	ra,0xfffff
    8000606e:	8ec080e7          	jalr	-1812(ra) # 80004956 <end_op>
    return -1;
    80006072:	557d                	li	a0,-1
    80006074:	b7fd                	j	80006062 <sys_mkdir+0x4c>

0000000080006076 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006076:	7135                	addi	sp,sp,-160
    80006078:	ed06                	sd	ra,152(sp)
    8000607a:	e922                	sd	s0,144(sp)
    8000607c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000607e:	fffff097          	auipc	ra,0xfffff
    80006082:	858080e7          	jalr	-1960(ra) # 800048d6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006086:	08000613          	li	a2,128
    8000608a:	f7040593          	addi	a1,s0,-144
    8000608e:	4501                	li	a0,0
    80006090:	ffffd097          	auipc	ra,0xffffd
    80006094:	190080e7          	jalr	400(ra) # 80003220 <argstr>
    80006098:	04054a63          	bltz	a0,800060ec <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000609c:	f6c40593          	addi	a1,s0,-148
    800060a0:	4505                	li	a0,1
    800060a2:	ffffd097          	auipc	ra,0xffffd
    800060a6:	13a080e7          	jalr	314(ra) # 800031dc <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060aa:	04054163          	bltz	a0,800060ec <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800060ae:	f6840593          	addi	a1,s0,-152
    800060b2:	4509                	li	a0,2
    800060b4:	ffffd097          	auipc	ra,0xffffd
    800060b8:	128080e7          	jalr	296(ra) # 800031dc <argint>
     argint(1, &major) < 0 ||
    800060bc:	02054863          	bltz	a0,800060ec <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800060c0:	f6841683          	lh	a3,-152(s0)
    800060c4:	f6c41603          	lh	a2,-148(s0)
    800060c8:	458d                	li	a1,3
    800060ca:	f7040513          	addi	a0,s0,-144
    800060ce:	fffff097          	auipc	ra,0xfffff
    800060d2:	778080e7          	jalr	1912(ra) # 80005846 <create>
     argint(2, &minor) < 0 ||
    800060d6:	c919                	beqz	a0,800060ec <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800060d8:	ffffe097          	auipc	ra,0xffffe
    800060dc:	08a080e7          	jalr	138(ra) # 80004162 <iunlockput>
  end_op();
    800060e0:	fffff097          	auipc	ra,0xfffff
    800060e4:	876080e7          	jalr	-1930(ra) # 80004956 <end_op>
  return 0;
    800060e8:	4501                	li	a0,0
    800060ea:	a031                	j	800060f6 <sys_mknod+0x80>
    end_op();
    800060ec:	fffff097          	auipc	ra,0xfffff
    800060f0:	86a080e7          	jalr	-1942(ra) # 80004956 <end_op>
    return -1;
    800060f4:	557d                	li	a0,-1
}
    800060f6:	60ea                	ld	ra,152(sp)
    800060f8:	644a                	ld	s0,144(sp)
    800060fa:	610d                	addi	sp,sp,160
    800060fc:	8082                	ret

00000000800060fe <sys_chdir>:

uint64
sys_chdir(void)
{
    800060fe:	7135                	addi	sp,sp,-160
    80006100:	ed06                	sd	ra,152(sp)
    80006102:	e922                	sd	s0,144(sp)
    80006104:	e526                	sd	s1,136(sp)
    80006106:	e14a                	sd	s2,128(sp)
    80006108:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000610a:	ffffc097          	auipc	ra,0xffffc
    8000610e:	8b8080e7          	jalr	-1864(ra) # 800019c2 <myproc>
    80006112:	892a                	mv	s2,a0
  
  begin_op();
    80006114:	ffffe097          	auipc	ra,0xffffe
    80006118:	7c2080e7          	jalr	1986(ra) # 800048d6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000611c:	08000613          	li	a2,128
    80006120:	f6040593          	addi	a1,s0,-160
    80006124:	4501                	li	a0,0
    80006126:	ffffd097          	auipc	ra,0xffffd
    8000612a:	0fa080e7          	jalr	250(ra) # 80003220 <argstr>
    8000612e:	04054b63          	bltz	a0,80006184 <sys_chdir+0x86>
    80006132:	f6040513          	addi	a0,s0,-160
    80006136:	ffffe097          	auipc	ra,0xffffe
    8000613a:	580080e7          	jalr	1408(ra) # 800046b6 <namei>
    8000613e:	84aa                	mv	s1,a0
    80006140:	c131                	beqz	a0,80006184 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006142:	ffffe097          	auipc	ra,0xffffe
    80006146:	dbe080e7          	jalr	-578(ra) # 80003f00 <ilock>
  if(ip->type != T_DIR){
    8000614a:	04449703          	lh	a4,68(s1)
    8000614e:	4785                	li	a5,1
    80006150:	04f71063          	bne	a4,a5,80006190 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006154:	8526                	mv	a0,s1
    80006156:	ffffe097          	auipc	ra,0xffffe
    8000615a:	e6c080e7          	jalr	-404(ra) # 80003fc2 <iunlock>
  iput(p->cwd);
    8000615e:	17893503          	ld	a0,376(s2)
    80006162:	ffffe097          	auipc	ra,0xffffe
    80006166:	f58080e7          	jalr	-168(ra) # 800040ba <iput>
  end_op();
    8000616a:	ffffe097          	auipc	ra,0xffffe
    8000616e:	7ec080e7          	jalr	2028(ra) # 80004956 <end_op>
  p->cwd = ip;
    80006172:	16993c23          	sd	s1,376(s2)
  return 0;
    80006176:	4501                	li	a0,0
}
    80006178:	60ea                	ld	ra,152(sp)
    8000617a:	644a                	ld	s0,144(sp)
    8000617c:	64aa                	ld	s1,136(sp)
    8000617e:	690a                	ld	s2,128(sp)
    80006180:	610d                	addi	sp,sp,160
    80006182:	8082                	ret
    end_op();
    80006184:	ffffe097          	auipc	ra,0xffffe
    80006188:	7d2080e7          	jalr	2002(ra) # 80004956 <end_op>
    return -1;
    8000618c:	557d                	li	a0,-1
    8000618e:	b7ed                	j	80006178 <sys_chdir+0x7a>
    iunlockput(ip);
    80006190:	8526                	mv	a0,s1
    80006192:	ffffe097          	auipc	ra,0xffffe
    80006196:	fd0080e7          	jalr	-48(ra) # 80004162 <iunlockput>
    end_op();
    8000619a:	ffffe097          	auipc	ra,0xffffe
    8000619e:	7bc080e7          	jalr	1980(ra) # 80004956 <end_op>
    return -1;
    800061a2:	557d                	li	a0,-1
    800061a4:	bfd1                	j	80006178 <sys_chdir+0x7a>

00000000800061a6 <sys_exec>:

uint64
sys_exec(void)
{
    800061a6:	7145                	addi	sp,sp,-464
    800061a8:	e786                	sd	ra,456(sp)
    800061aa:	e3a2                	sd	s0,448(sp)
    800061ac:	ff26                	sd	s1,440(sp)
    800061ae:	fb4a                	sd	s2,432(sp)
    800061b0:	f74e                	sd	s3,424(sp)
    800061b2:	f352                	sd	s4,416(sp)
    800061b4:	ef56                	sd	s5,408(sp)
    800061b6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800061b8:	08000613          	li	a2,128
    800061bc:	f4040593          	addi	a1,s0,-192
    800061c0:	4501                	li	a0,0
    800061c2:	ffffd097          	auipc	ra,0xffffd
    800061c6:	05e080e7          	jalr	94(ra) # 80003220 <argstr>
    return -1;
    800061ca:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800061cc:	0c054a63          	bltz	a0,800062a0 <sys_exec+0xfa>
    800061d0:	e3840593          	addi	a1,s0,-456
    800061d4:	4505                	li	a0,1
    800061d6:	ffffd097          	auipc	ra,0xffffd
    800061da:	028080e7          	jalr	40(ra) # 800031fe <argaddr>
    800061de:	0c054163          	bltz	a0,800062a0 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800061e2:	10000613          	li	a2,256
    800061e6:	4581                	li	a1,0
    800061e8:	e4040513          	addi	a0,s0,-448
    800061ec:	ffffb097          	auipc	ra,0xffffb
    800061f0:	ad2080e7          	jalr	-1326(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800061f4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800061f8:	89a6                	mv	s3,s1
    800061fa:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800061fc:	02000a13          	li	s4,32
    80006200:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006204:	00391793          	slli	a5,s2,0x3
    80006208:	e3040593          	addi	a1,s0,-464
    8000620c:	e3843503          	ld	a0,-456(s0)
    80006210:	953e                	add	a0,a0,a5
    80006212:	ffffd097          	auipc	ra,0xffffd
    80006216:	f30080e7          	jalr	-208(ra) # 80003142 <fetchaddr>
    8000621a:	02054a63          	bltz	a0,8000624e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000621e:	e3043783          	ld	a5,-464(s0)
    80006222:	c3b9                	beqz	a5,80006268 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006224:	ffffb097          	auipc	ra,0xffffb
    80006228:	8ae080e7          	jalr	-1874(ra) # 80000ad2 <kalloc>
    8000622c:	85aa                	mv	a1,a0
    8000622e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006232:	cd11                	beqz	a0,8000624e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006234:	6605                	lui	a2,0x1
    80006236:	e3043503          	ld	a0,-464(s0)
    8000623a:	ffffd097          	auipc	ra,0xffffd
    8000623e:	f5a080e7          	jalr	-166(ra) # 80003194 <fetchstr>
    80006242:	00054663          	bltz	a0,8000624e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006246:	0905                	addi	s2,s2,1
    80006248:	09a1                	addi	s3,s3,8
    8000624a:	fb491be3          	bne	s2,s4,80006200 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000624e:	10048913          	addi	s2,s1,256
    80006252:	6088                	ld	a0,0(s1)
    80006254:	c529                	beqz	a0,8000629e <sys_exec+0xf8>
    kfree(argv[i]);
    80006256:	ffffa097          	auipc	ra,0xffffa
    8000625a:	780080e7          	jalr	1920(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000625e:	04a1                	addi	s1,s1,8
    80006260:	ff2499e3          	bne	s1,s2,80006252 <sys_exec+0xac>
  return -1;
    80006264:	597d                	li	s2,-1
    80006266:	a82d                	j	800062a0 <sys_exec+0xfa>
      argv[i] = 0;
    80006268:	0a8e                	slli	s5,s5,0x3
    8000626a:	fc040793          	addi	a5,s0,-64
    8000626e:	9abe                	add	s5,s5,a5
    80006270:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80006274:	e4040593          	addi	a1,s0,-448
    80006278:	f4040513          	addi	a0,s0,-192
    8000627c:	fffff097          	auipc	ra,0xfffff
    80006280:	178080e7          	jalr	376(ra) # 800053f4 <exec>
    80006284:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006286:	10048993          	addi	s3,s1,256
    8000628a:	6088                	ld	a0,0(s1)
    8000628c:	c911                	beqz	a0,800062a0 <sys_exec+0xfa>
    kfree(argv[i]);
    8000628e:	ffffa097          	auipc	ra,0xffffa
    80006292:	748080e7          	jalr	1864(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006296:	04a1                	addi	s1,s1,8
    80006298:	ff3499e3          	bne	s1,s3,8000628a <sys_exec+0xe4>
    8000629c:	a011                	j	800062a0 <sys_exec+0xfa>
  return -1;
    8000629e:	597d                	li	s2,-1
}
    800062a0:	854a                	mv	a0,s2
    800062a2:	60be                	ld	ra,456(sp)
    800062a4:	641e                	ld	s0,448(sp)
    800062a6:	74fa                	ld	s1,440(sp)
    800062a8:	795a                	ld	s2,432(sp)
    800062aa:	79ba                	ld	s3,424(sp)
    800062ac:	7a1a                	ld	s4,416(sp)
    800062ae:	6afa                	ld	s5,408(sp)
    800062b0:	6179                	addi	sp,sp,464
    800062b2:	8082                	ret

00000000800062b4 <sys_pipe>:

uint64
sys_pipe(void)
{
    800062b4:	7139                	addi	sp,sp,-64
    800062b6:	fc06                	sd	ra,56(sp)
    800062b8:	f822                	sd	s0,48(sp)
    800062ba:	f426                	sd	s1,40(sp)
    800062bc:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800062be:	ffffb097          	auipc	ra,0xffffb
    800062c2:	704080e7          	jalr	1796(ra) # 800019c2 <myproc>
    800062c6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800062c8:	fd840593          	addi	a1,s0,-40
    800062cc:	4501                	li	a0,0
    800062ce:	ffffd097          	auipc	ra,0xffffd
    800062d2:	f30080e7          	jalr	-208(ra) # 800031fe <argaddr>
    return -1;
    800062d6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800062d8:	0e054063          	bltz	a0,800063b8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800062dc:	fc840593          	addi	a1,s0,-56
    800062e0:	fd040513          	addi	a0,s0,-48
    800062e4:	fffff097          	auipc	ra,0xfffff
    800062e8:	dee080e7          	jalr	-530(ra) # 800050d2 <pipealloc>
    return -1;
    800062ec:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800062ee:	0c054563          	bltz	a0,800063b8 <sys_pipe+0x104>
  fd0 = -1;
    800062f2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800062f6:	fd043503          	ld	a0,-48(s0)
    800062fa:	fffff097          	auipc	ra,0xfffff
    800062fe:	50a080e7          	jalr	1290(ra) # 80005804 <fdalloc>
    80006302:	fca42223          	sw	a0,-60(s0)
    80006306:	08054c63          	bltz	a0,8000639e <sys_pipe+0xea>
    8000630a:	fc843503          	ld	a0,-56(s0)
    8000630e:	fffff097          	auipc	ra,0xfffff
    80006312:	4f6080e7          	jalr	1270(ra) # 80005804 <fdalloc>
    80006316:	fca42023          	sw	a0,-64(s0)
    8000631a:	06054863          	bltz	a0,8000638a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000631e:	4691                	li	a3,4
    80006320:	fc440613          	addi	a2,s0,-60
    80006324:	fd843583          	ld	a1,-40(s0)
    80006328:	7ca8                	ld	a0,120(s1)
    8000632a:	ffffb097          	auipc	ra,0xffffb
    8000632e:	314080e7          	jalr	788(ra) # 8000163e <copyout>
    80006332:	02054063          	bltz	a0,80006352 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006336:	4691                	li	a3,4
    80006338:	fc040613          	addi	a2,s0,-64
    8000633c:	fd843583          	ld	a1,-40(s0)
    80006340:	0591                	addi	a1,a1,4
    80006342:	7ca8                	ld	a0,120(s1)
    80006344:	ffffb097          	auipc	ra,0xffffb
    80006348:	2fa080e7          	jalr	762(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000634c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000634e:	06055563          	bgez	a0,800063b8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006352:	fc442783          	lw	a5,-60(s0)
    80006356:	07f9                	addi	a5,a5,30
    80006358:	078e                	slli	a5,a5,0x3
    8000635a:	97a6                	add	a5,a5,s1
    8000635c:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006360:	fc042503          	lw	a0,-64(s0)
    80006364:	0579                	addi	a0,a0,30
    80006366:	050e                	slli	a0,a0,0x3
    80006368:	9526                	add	a0,a0,s1
    8000636a:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000636e:	fd043503          	ld	a0,-48(s0)
    80006372:	fffff097          	auipc	ra,0xfffff
    80006376:	a30080e7          	jalr	-1488(ra) # 80004da2 <fileclose>
    fileclose(wf);
    8000637a:	fc843503          	ld	a0,-56(s0)
    8000637e:	fffff097          	auipc	ra,0xfffff
    80006382:	a24080e7          	jalr	-1500(ra) # 80004da2 <fileclose>
    return -1;
    80006386:	57fd                	li	a5,-1
    80006388:	a805                	j	800063b8 <sys_pipe+0x104>
    if(fd0 >= 0)
    8000638a:	fc442783          	lw	a5,-60(s0)
    8000638e:	0007c863          	bltz	a5,8000639e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006392:	01e78513          	addi	a0,a5,30
    80006396:	050e                	slli	a0,a0,0x3
    80006398:	9526                	add	a0,a0,s1
    8000639a:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000639e:	fd043503          	ld	a0,-48(s0)
    800063a2:	fffff097          	auipc	ra,0xfffff
    800063a6:	a00080e7          	jalr	-1536(ra) # 80004da2 <fileclose>
    fileclose(wf);
    800063aa:	fc843503          	ld	a0,-56(s0)
    800063ae:	fffff097          	auipc	ra,0xfffff
    800063b2:	9f4080e7          	jalr	-1548(ra) # 80004da2 <fileclose>
    return -1;
    800063b6:	57fd                	li	a5,-1
}
    800063b8:	853e                	mv	a0,a5
    800063ba:	70e2                	ld	ra,56(sp)
    800063bc:	7442                	ld	s0,48(sp)
    800063be:	74a2                	ld	s1,40(sp)
    800063c0:	6121                	addi	sp,sp,64
    800063c2:	8082                	ret
	...

00000000800063d0 <kernelvec>:
    800063d0:	7111                	addi	sp,sp,-256
    800063d2:	e006                	sd	ra,0(sp)
    800063d4:	e40a                	sd	sp,8(sp)
    800063d6:	e80e                	sd	gp,16(sp)
    800063d8:	ec12                	sd	tp,24(sp)
    800063da:	f016                	sd	t0,32(sp)
    800063dc:	f41a                	sd	t1,40(sp)
    800063de:	f81e                	sd	t2,48(sp)
    800063e0:	fc22                	sd	s0,56(sp)
    800063e2:	e0a6                	sd	s1,64(sp)
    800063e4:	e4aa                	sd	a0,72(sp)
    800063e6:	e8ae                	sd	a1,80(sp)
    800063e8:	ecb2                	sd	a2,88(sp)
    800063ea:	f0b6                	sd	a3,96(sp)
    800063ec:	f4ba                	sd	a4,104(sp)
    800063ee:	f8be                	sd	a5,112(sp)
    800063f0:	fcc2                	sd	a6,120(sp)
    800063f2:	e146                	sd	a7,128(sp)
    800063f4:	e54a                	sd	s2,136(sp)
    800063f6:	e94e                	sd	s3,144(sp)
    800063f8:	ed52                	sd	s4,152(sp)
    800063fa:	f156                	sd	s5,160(sp)
    800063fc:	f55a                	sd	s6,168(sp)
    800063fe:	f95e                	sd	s7,176(sp)
    80006400:	fd62                	sd	s8,184(sp)
    80006402:	e1e6                	sd	s9,192(sp)
    80006404:	e5ea                	sd	s10,200(sp)
    80006406:	e9ee                	sd	s11,208(sp)
    80006408:	edf2                	sd	t3,216(sp)
    8000640a:	f1f6                	sd	t4,224(sp)
    8000640c:	f5fa                	sd	t5,232(sp)
    8000640e:	f9fe                	sd	t6,240(sp)
    80006410:	bd5fc0ef          	jal	ra,80002fe4 <kerneltrap>
    80006414:	6082                	ld	ra,0(sp)
    80006416:	6122                	ld	sp,8(sp)
    80006418:	61c2                	ld	gp,16(sp)
    8000641a:	7282                	ld	t0,32(sp)
    8000641c:	7322                	ld	t1,40(sp)
    8000641e:	73c2                	ld	t2,48(sp)
    80006420:	7462                	ld	s0,56(sp)
    80006422:	6486                	ld	s1,64(sp)
    80006424:	6526                	ld	a0,72(sp)
    80006426:	65c6                	ld	a1,80(sp)
    80006428:	6666                	ld	a2,88(sp)
    8000642a:	7686                	ld	a3,96(sp)
    8000642c:	7726                	ld	a4,104(sp)
    8000642e:	77c6                	ld	a5,112(sp)
    80006430:	7866                	ld	a6,120(sp)
    80006432:	688a                	ld	a7,128(sp)
    80006434:	692a                	ld	s2,136(sp)
    80006436:	69ca                	ld	s3,144(sp)
    80006438:	6a6a                	ld	s4,152(sp)
    8000643a:	7a8a                	ld	s5,160(sp)
    8000643c:	7b2a                	ld	s6,168(sp)
    8000643e:	7bca                	ld	s7,176(sp)
    80006440:	7c6a                	ld	s8,184(sp)
    80006442:	6c8e                	ld	s9,192(sp)
    80006444:	6d2e                	ld	s10,200(sp)
    80006446:	6dce                	ld	s11,208(sp)
    80006448:	6e6e                	ld	t3,216(sp)
    8000644a:	7e8e                	ld	t4,224(sp)
    8000644c:	7f2e                	ld	t5,232(sp)
    8000644e:	7fce                	ld	t6,240(sp)
    80006450:	6111                	addi	sp,sp,256
    80006452:	10200073          	sret
    80006456:	00000013          	nop
    8000645a:	00000013          	nop
    8000645e:	0001                	nop

0000000080006460 <timervec>:
    80006460:	34051573          	csrrw	a0,mscratch,a0
    80006464:	e10c                	sd	a1,0(a0)
    80006466:	e510                	sd	a2,8(a0)
    80006468:	e914                	sd	a3,16(a0)
    8000646a:	6d0c                	ld	a1,24(a0)
    8000646c:	7110                	ld	a2,32(a0)
    8000646e:	6194                	ld	a3,0(a1)
    80006470:	96b2                	add	a3,a3,a2
    80006472:	e194                	sd	a3,0(a1)
    80006474:	4589                	li	a1,2
    80006476:	14459073          	csrw	sip,a1
    8000647a:	6914                	ld	a3,16(a0)
    8000647c:	6510                	ld	a2,8(a0)
    8000647e:	610c                	ld	a1,0(a0)
    80006480:	34051573          	csrrw	a0,mscratch,a0
    80006484:	30200073          	mret
	...

000000008000648a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000648a:	1141                	addi	sp,sp,-16
    8000648c:	e422                	sd	s0,8(sp)
    8000648e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006490:	0c0007b7          	lui	a5,0xc000
    80006494:	4705                	li	a4,1
    80006496:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006498:	c3d8                	sw	a4,4(a5)
}
    8000649a:	6422                	ld	s0,8(sp)
    8000649c:	0141                	addi	sp,sp,16
    8000649e:	8082                	ret

00000000800064a0 <plicinithart>:

void
plicinithart(void)
{
    800064a0:	1141                	addi	sp,sp,-16
    800064a2:	e406                	sd	ra,8(sp)
    800064a4:	e022                	sd	s0,0(sp)
    800064a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064a8:	ffffb097          	auipc	ra,0xffffb
    800064ac:	4ee080e7          	jalr	1262(ra) # 80001996 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800064b0:	0085171b          	slliw	a4,a0,0x8
    800064b4:	0c0027b7          	lui	a5,0xc002
    800064b8:	97ba                	add	a5,a5,a4
    800064ba:	40200713          	li	a4,1026
    800064be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800064c2:	00d5151b          	slliw	a0,a0,0xd
    800064c6:	0c2017b7          	lui	a5,0xc201
    800064ca:	953e                	add	a0,a0,a5
    800064cc:	00052023          	sw	zero,0(a0)
}
    800064d0:	60a2                	ld	ra,8(sp)
    800064d2:	6402                	ld	s0,0(sp)
    800064d4:	0141                	addi	sp,sp,16
    800064d6:	8082                	ret

00000000800064d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800064d8:	1141                	addi	sp,sp,-16
    800064da:	e406                	sd	ra,8(sp)
    800064dc:	e022                	sd	s0,0(sp)
    800064de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064e0:	ffffb097          	auipc	ra,0xffffb
    800064e4:	4b6080e7          	jalr	1206(ra) # 80001996 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800064e8:	00d5179b          	slliw	a5,a0,0xd
    800064ec:	0c201537          	lui	a0,0xc201
    800064f0:	953e                	add	a0,a0,a5
  return irq;
}
    800064f2:	4148                	lw	a0,4(a0)
    800064f4:	60a2                	ld	ra,8(sp)
    800064f6:	6402                	ld	s0,0(sp)
    800064f8:	0141                	addi	sp,sp,16
    800064fa:	8082                	ret

00000000800064fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800064fc:	1101                	addi	sp,sp,-32
    800064fe:	ec06                	sd	ra,24(sp)
    80006500:	e822                	sd	s0,16(sp)
    80006502:	e426                	sd	s1,8(sp)
    80006504:	1000                	addi	s0,sp,32
    80006506:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006508:	ffffb097          	auipc	ra,0xffffb
    8000650c:	48e080e7          	jalr	1166(ra) # 80001996 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006510:	00d5151b          	slliw	a0,a0,0xd
    80006514:	0c2017b7          	lui	a5,0xc201
    80006518:	97aa                	add	a5,a5,a0
    8000651a:	c3c4                	sw	s1,4(a5)
}
    8000651c:	60e2                	ld	ra,24(sp)
    8000651e:	6442                	ld	s0,16(sp)
    80006520:	64a2                	ld	s1,8(sp)
    80006522:	6105                	addi	sp,sp,32
    80006524:	8082                	ret

0000000080006526 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006526:	1141                	addi	sp,sp,-16
    80006528:	e406                	sd	ra,8(sp)
    8000652a:	e022                	sd	s0,0(sp)
    8000652c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000652e:	479d                	li	a5,7
    80006530:	06a7c963          	blt	a5,a0,800065a2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006534:	0001d797          	auipc	a5,0x1d
    80006538:	acc78793          	addi	a5,a5,-1332 # 80023000 <disk>
    8000653c:	00a78733          	add	a4,a5,a0
    80006540:	6789                	lui	a5,0x2
    80006542:	97ba                	add	a5,a5,a4
    80006544:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006548:	e7ad                	bnez	a5,800065b2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000654a:	00451793          	slli	a5,a0,0x4
    8000654e:	0001f717          	auipc	a4,0x1f
    80006552:	ab270713          	addi	a4,a4,-1358 # 80025000 <disk+0x2000>
    80006556:	6314                	ld	a3,0(a4)
    80006558:	96be                	add	a3,a3,a5
    8000655a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000655e:	6314                	ld	a3,0(a4)
    80006560:	96be                	add	a3,a3,a5
    80006562:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006566:	6314                	ld	a3,0(a4)
    80006568:	96be                	add	a3,a3,a5
    8000656a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000656e:	6318                	ld	a4,0(a4)
    80006570:	97ba                	add	a5,a5,a4
    80006572:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006576:	0001d797          	auipc	a5,0x1d
    8000657a:	a8a78793          	addi	a5,a5,-1398 # 80023000 <disk>
    8000657e:	97aa                	add	a5,a5,a0
    80006580:	6509                	lui	a0,0x2
    80006582:	953e                	add	a0,a0,a5
    80006584:	4785                	li	a5,1
    80006586:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000658a:	0001f517          	auipc	a0,0x1f
    8000658e:	a8e50513          	addi	a0,a0,-1394 # 80025018 <disk+0x2018>
    80006592:	ffffc097          	auipc	ra,0xffffc
    80006596:	fd0080e7          	jalr	-48(ra) # 80002562 <wakeup>
}
    8000659a:	60a2                	ld	ra,8(sp)
    8000659c:	6402                	ld	s0,0(sp)
    8000659e:	0141                	addi	sp,sp,16
    800065a0:	8082                	ret
    panic("free_desc 1");
    800065a2:	00002517          	auipc	a0,0x2
    800065a6:	3ee50513          	addi	a0,a0,1006 # 80008990 <syscalls+0x338>
    800065aa:	ffffa097          	auipc	ra,0xffffa
    800065ae:	f80080e7          	jalr	-128(ra) # 8000052a <panic>
    panic("free_desc 2");
    800065b2:	00002517          	auipc	a0,0x2
    800065b6:	3ee50513          	addi	a0,a0,1006 # 800089a0 <syscalls+0x348>
    800065ba:	ffffa097          	auipc	ra,0xffffa
    800065be:	f70080e7          	jalr	-144(ra) # 8000052a <panic>

00000000800065c2 <virtio_disk_init>:
{
    800065c2:	1101                	addi	sp,sp,-32
    800065c4:	ec06                	sd	ra,24(sp)
    800065c6:	e822                	sd	s0,16(sp)
    800065c8:	e426                	sd	s1,8(sp)
    800065ca:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800065cc:	00002597          	auipc	a1,0x2
    800065d0:	3e458593          	addi	a1,a1,996 # 800089b0 <syscalls+0x358>
    800065d4:	0001f517          	auipc	a0,0x1f
    800065d8:	b5450513          	addi	a0,a0,-1196 # 80025128 <disk+0x2128>
    800065dc:	ffffa097          	auipc	ra,0xffffa
    800065e0:	556080e7          	jalr	1366(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065e4:	100017b7          	lui	a5,0x10001
    800065e8:	4398                	lw	a4,0(a5)
    800065ea:	2701                	sext.w	a4,a4
    800065ec:	747277b7          	lui	a5,0x74727
    800065f0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800065f4:	0ef71163          	bne	a4,a5,800066d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800065f8:	100017b7          	lui	a5,0x10001
    800065fc:	43dc                	lw	a5,4(a5)
    800065fe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006600:	4705                	li	a4,1
    80006602:	0ce79a63          	bne	a5,a4,800066d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006606:	100017b7          	lui	a5,0x10001
    8000660a:	479c                	lw	a5,8(a5)
    8000660c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000660e:	4709                	li	a4,2
    80006610:	0ce79363          	bne	a5,a4,800066d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006614:	100017b7          	lui	a5,0x10001
    80006618:	47d8                	lw	a4,12(a5)
    8000661a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000661c:	554d47b7          	lui	a5,0x554d4
    80006620:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006624:	0af71963          	bne	a4,a5,800066d6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006628:	100017b7          	lui	a5,0x10001
    8000662c:	4705                	li	a4,1
    8000662e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006630:	470d                	li	a4,3
    80006632:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006634:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006636:	c7ffe737          	lui	a4,0xc7ffe
    8000663a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000663e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006640:	2701                	sext.w	a4,a4
    80006642:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006644:	472d                	li	a4,11
    80006646:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006648:	473d                	li	a4,15
    8000664a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000664c:	6705                	lui	a4,0x1
    8000664e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006650:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006654:	5bdc                	lw	a5,52(a5)
    80006656:	2781                	sext.w	a5,a5
  if(max == 0)
    80006658:	c7d9                	beqz	a5,800066e6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000665a:	471d                	li	a4,7
    8000665c:	08f77d63          	bgeu	a4,a5,800066f6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006660:	100014b7          	lui	s1,0x10001
    80006664:	47a1                	li	a5,8
    80006666:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006668:	6609                	lui	a2,0x2
    8000666a:	4581                	li	a1,0
    8000666c:	0001d517          	auipc	a0,0x1d
    80006670:	99450513          	addi	a0,a0,-1644 # 80023000 <disk>
    80006674:	ffffa097          	auipc	ra,0xffffa
    80006678:	64a080e7          	jalr	1610(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000667c:	0001d717          	auipc	a4,0x1d
    80006680:	98470713          	addi	a4,a4,-1660 # 80023000 <disk>
    80006684:	00c75793          	srli	a5,a4,0xc
    80006688:	2781                	sext.w	a5,a5
    8000668a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000668c:	0001f797          	auipc	a5,0x1f
    80006690:	97478793          	addi	a5,a5,-1676 # 80025000 <disk+0x2000>
    80006694:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006696:	0001d717          	auipc	a4,0x1d
    8000669a:	9ea70713          	addi	a4,a4,-1558 # 80023080 <disk+0x80>
    8000669e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800066a0:	0001e717          	auipc	a4,0x1e
    800066a4:	96070713          	addi	a4,a4,-1696 # 80024000 <disk+0x1000>
    800066a8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800066aa:	4705                	li	a4,1
    800066ac:	00e78c23          	sb	a4,24(a5)
    800066b0:	00e78ca3          	sb	a4,25(a5)
    800066b4:	00e78d23          	sb	a4,26(a5)
    800066b8:	00e78da3          	sb	a4,27(a5)
    800066bc:	00e78e23          	sb	a4,28(a5)
    800066c0:	00e78ea3          	sb	a4,29(a5)
    800066c4:	00e78f23          	sb	a4,30(a5)
    800066c8:	00e78fa3          	sb	a4,31(a5)
}
    800066cc:	60e2                	ld	ra,24(sp)
    800066ce:	6442                	ld	s0,16(sp)
    800066d0:	64a2                	ld	s1,8(sp)
    800066d2:	6105                	addi	sp,sp,32
    800066d4:	8082                	ret
    panic("could not find virtio disk");
    800066d6:	00002517          	auipc	a0,0x2
    800066da:	2ea50513          	addi	a0,a0,746 # 800089c0 <syscalls+0x368>
    800066de:	ffffa097          	auipc	ra,0xffffa
    800066e2:	e4c080e7          	jalr	-436(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    800066e6:	00002517          	auipc	a0,0x2
    800066ea:	2fa50513          	addi	a0,a0,762 # 800089e0 <syscalls+0x388>
    800066ee:	ffffa097          	auipc	ra,0xffffa
    800066f2:	e3c080e7          	jalr	-452(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    800066f6:	00002517          	auipc	a0,0x2
    800066fa:	30a50513          	addi	a0,a0,778 # 80008a00 <syscalls+0x3a8>
    800066fe:	ffffa097          	auipc	ra,0xffffa
    80006702:	e2c080e7          	jalr	-468(ra) # 8000052a <panic>

0000000080006706 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006706:	7119                	addi	sp,sp,-128
    80006708:	fc86                	sd	ra,120(sp)
    8000670a:	f8a2                	sd	s0,112(sp)
    8000670c:	f4a6                	sd	s1,104(sp)
    8000670e:	f0ca                	sd	s2,96(sp)
    80006710:	ecce                	sd	s3,88(sp)
    80006712:	e8d2                	sd	s4,80(sp)
    80006714:	e4d6                	sd	s5,72(sp)
    80006716:	e0da                	sd	s6,64(sp)
    80006718:	fc5e                	sd	s7,56(sp)
    8000671a:	f862                	sd	s8,48(sp)
    8000671c:	f466                	sd	s9,40(sp)
    8000671e:	f06a                	sd	s10,32(sp)
    80006720:	ec6e                	sd	s11,24(sp)
    80006722:	0100                	addi	s0,sp,128
    80006724:	8aaa                	mv	s5,a0
    80006726:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006728:	00c52c83          	lw	s9,12(a0)
    8000672c:	001c9c9b          	slliw	s9,s9,0x1
    80006730:	1c82                	slli	s9,s9,0x20
    80006732:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006736:	0001f517          	auipc	a0,0x1f
    8000673a:	9f250513          	addi	a0,a0,-1550 # 80025128 <disk+0x2128>
    8000673e:	ffffa097          	auipc	ra,0xffffa
    80006742:	484080e7          	jalr	1156(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006746:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006748:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000674a:	0001dc17          	auipc	s8,0x1d
    8000674e:	8b6c0c13          	addi	s8,s8,-1866 # 80023000 <disk>
    80006752:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006754:	4b0d                	li	s6,3
    80006756:	a0ad                	j	800067c0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006758:	00fc0733          	add	a4,s8,a5
    8000675c:	975e                	add	a4,a4,s7
    8000675e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006762:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006764:	0207c563          	bltz	a5,8000678e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006768:	2905                	addiw	s2,s2,1
    8000676a:	0611                	addi	a2,a2,4
    8000676c:	19690d63          	beq	s2,s6,80006906 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006770:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006772:	0001f717          	auipc	a4,0x1f
    80006776:	8a670713          	addi	a4,a4,-1882 # 80025018 <disk+0x2018>
    8000677a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000677c:	00074683          	lbu	a3,0(a4)
    80006780:	fee1                	bnez	a3,80006758 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006782:	2785                	addiw	a5,a5,1
    80006784:	0705                	addi	a4,a4,1
    80006786:	fe979be3          	bne	a5,s1,8000677c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000678a:	57fd                	li	a5,-1
    8000678c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000678e:	01205d63          	blez	s2,800067a8 <virtio_disk_rw+0xa2>
    80006792:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006794:	000a2503          	lw	a0,0(s4)
    80006798:	00000097          	auipc	ra,0x0
    8000679c:	d8e080e7          	jalr	-626(ra) # 80006526 <free_desc>
      for(int j = 0; j < i; j++)
    800067a0:	2d85                	addiw	s11,s11,1
    800067a2:	0a11                	addi	s4,s4,4
    800067a4:	ffb918e3          	bne	s2,s11,80006794 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800067a8:	0001f597          	auipc	a1,0x1f
    800067ac:	98058593          	addi	a1,a1,-1664 # 80025128 <disk+0x2128>
    800067b0:	0001f517          	auipc	a0,0x1f
    800067b4:	86850513          	addi	a0,a0,-1944 # 80025018 <disk+0x2018>
    800067b8:	ffffc097          	auipc	ra,0xffffc
    800067bc:	c1e080e7          	jalr	-994(ra) # 800023d6 <sleep>
  for(int i = 0; i < 3; i++){
    800067c0:	f8040a13          	addi	s4,s0,-128
{
    800067c4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800067c6:	894e                	mv	s2,s3
    800067c8:	b765                	j	80006770 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800067ca:	0001f697          	auipc	a3,0x1f
    800067ce:	8366b683          	ld	a3,-1994(a3) # 80025000 <disk+0x2000>
    800067d2:	96ba                	add	a3,a3,a4
    800067d4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800067d8:	0001d817          	auipc	a6,0x1d
    800067dc:	82880813          	addi	a6,a6,-2008 # 80023000 <disk>
    800067e0:	0001f697          	auipc	a3,0x1f
    800067e4:	82068693          	addi	a3,a3,-2016 # 80025000 <disk+0x2000>
    800067e8:	6290                	ld	a2,0(a3)
    800067ea:	963a                	add	a2,a2,a4
    800067ec:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800067f0:	0015e593          	ori	a1,a1,1
    800067f4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800067f8:	f8842603          	lw	a2,-120(s0)
    800067fc:	628c                	ld	a1,0(a3)
    800067fe:	972e                	add	a4,a4,a1
    80006800:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006804:	20050593          	addi	a1,a0,512
    80006808:	0592                	slli	a1,a1,0x4
    8000680a:	95c2                	add	a1,a1,a6
    8000680c:	577d                	li	a4,-1
    8000680e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006812:	00461713          	slli	a4,a2,0x4
    80006816:	6290                	ld	a2,0(a3)
    80006818:	963a                	add	a2,a2,a4
    8000681a:	03078793          	addi	a5,a5,48
    8000681e:	97c2                	add	a5,a5,a6
    80006820:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006822:	629c                	ld	a5,0(a3)
    80006824:	97ba                	add	a5,a5,a4
    80006826:	4605                	li	a2,1
    80006828:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000682a:	629c                	ld	a5,0(a3)
    8000682c:	97ba                	add	a5,a5,a4
    8000682e:	4809                	li	a6,2
    80006830:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006834:	629c                	ld	a5,0(a3)
    80006836:	973e                	add	a4,a4,a5
    80006838:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000683c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006840:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006844:	6698                	ld	a4,8(a3)
    80006846:	00275783          	lhu	a5,2(a4)
    8000684a:	8b9d                	andi	a5,a5,7
    8000684c:	0786                	slli	a5,a5,0x1
    8000684e:	97ba                	add	a5,a5,a4
    80006850:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006854:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006858:	6698                	ld	a4,8(a3)
    8000685a:	00275783          	lhu	a5,2(a4)
    8000685e:	2785                	addiw	a5,a5,1
    80006860:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006864:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006868:	100017b7          	lui	a5,0x10001
    8000686c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006870:	004aa783          	lw	a5,4(s5)
    80006874:	02c79163          	bne	a5,a2,80006896 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006878:	0001f917          	auipc	s2,0x1f
    8000687c:	8b090913          	addi	s2,s2,-1872 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006880:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006882:	85ca                	mv	a1,s2
    80006884:	8556                	mv	a0,s5
    80006886:	ffffc097          	auipc	ra,0xffffc
    8000688a:	b50080e7          	jalr	-1200(ra) # 800023d6 <sleep>
  while(b->disk == 1) {
    8000688e:	004aa783          	lw	a5,4(s5)
    80006892:	fe9788e3          	beq	a5,s1,80006882 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006896:	f8042903          	lw	s2,-128(s0)
    8000689a:	20090793          	addi	a5,s2,512
    8000689e:	00479713          	slli	a4,a5,0x4
    800068a2:	0001c797          	auipc	a5,0x1c
    800068a6:	75e78793          	addi	a5,a5,1886 # 80023000 <disk>
    800068aa:	97ba                	add	a5,a5,a4
    800068ac:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800068b0:	0001e997          	auipc	s3,0x1e
    800068b4:	75098993          	addi	s3,s3,1872 # 80025000 <disk+0x2000>
    800068b8:	00491713          	slli	a4,s2,0x4
    800068bc:	0009b783          	ld	a5,0(s3)
    800068c0:	97ba                	add	a5,a5,a4
    800068c2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800068c6:	854a                	mv	a0,s2
    800068c8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800068cc:	00000097          	auipc	ra,0x0
    800068d0:	c5a080e7          	jalr	-934(ra) # 80006526 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800068d4:	8885                	andi	s1,s1,1
    800068d6:	f0ed                	bnez	s1,800068b8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800068d8:	0001f517          	auipc	a0,0x1f
    800068dc:	85050513          	addi	a0,a0,-1968 # 80025128 <disk+0x2128>
    800068e0:	ffffa097          	auipc	ra,0xffffa
    800068e4:	396080e7          	jalr	918(ra) # 80000c76 <release>
}
    800068e8:	70e6                	ld	ra,120(sp)
    800068ea:	7446                	ld	s0,112(sp)
    800068ec:	74a6                	ld	s1,104(sp)
    800068ee:	7906                	ld	s2,96(sp)
    800068f0:	69e6                	ld	s3,88(sp)
    800068f2:	6a46                	ld	s4,80(sp)
    800068f4:	6aa6                	ld	s5,72(sp)
    800068f6:	6b06                	ld	s6,64(sp)
    800068f8:	7be2                	ld	s7,56(sp)
    800068fa:	7c42                	ld	s8,48(sp)
    800068fc:	7ca2                	ld	s9,40(sp)
    800068fe:	7d02                	ld	s10,32(sp)
    80006900:	6de2                	ld	s11,24(sp)
    80006902:	6109                	addi	sp,sp,128
    80006904:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006906:	f8042503          	lw	a0,-128(s0)
    8000690a:	20050793          	addi	a5,a0,512
    8000690e:	0792                	slli	a5,a5,0x4
  if(write)
    80006910:	0001c817          	auipc	a6,0x1c
    80006914:	6f080813          	addi	a6,a6,1776 # 80023000 <disk>
    80006918:	00f80733          	add	a4,a6,a5
    8000691c:	01a036b3          	snez	a3,s10
    80006920:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006924:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006928:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000692c:	7679                	lui	a2,0xffffe
    8000692e:	963e                	add	a2,a2,a5
    80006930:	0001e697          	auipc	a3,0x1e
    80006934:	6d068693          	addi	a3,a3,1744 # 80025000 <disk+0x2000>
    80006938:	6298                	ld	a4,0(a3)
    8000693a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000693c:	0a878593          	addi	a1,a5,168
    80006940:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006942:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006944:	6298                	ld	a4,0(a3)
    80006946:	9732                	add	a4,a4,a2
    80006948:	45c1                	li	a1,16
    8000694a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000694c:	6298                	ld	a4,0(a3)
    8000694e:	9732                	add	a4,a4,a2
    80006950:	4585                	li	a1,1
    80006952:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006956:	f8442703          	lw	a4,-124(s0)
    8000695a:	628c                	ld	a1,0(a3)
    8000695c:	962e                	add	a2,a2,a1
    8000695e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006962:	0712                	slli	a4,a4,0x4
    80006964:	6290                	ld	a2,0(a3)
    80006966:	963a                	add	a2,a2,a4
    80006968:	058a8593          	addi	a1,s5,88
    8000696c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000696e:	6294                	ld	a3,0(a3)
    80006970:	96ba                	add	a3,a3,a4
    80006972:	40000613          	li	a2,1024
    80006976:	c690                	sw	a2,8(a3)
  if(write)
    80006978:	e40d19e3          	bnez	s10,800067ca <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000697c:	0001e697          	auipc	a3,0x1e
    80006980:	6846b683          	ld	a3,1668(a3) # 80025000 <disk+0x2000>
    80006984:	96ba                	add	a3,a3,a4
    80006986:	4609                	li	a2,2
    80006988:	00c69623          	sh	a2,12(a3)
    8000698c:	b5b1                	j	800067d8 <virtio_disk_rw+0xd2>

000000008000698e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000698e:	1101                	addi	sp,sp,-32
    80006990:	ec06                	sd	ra,24(sp)
    80006992:	e822                	sd	s0,16(sp)
    80006994:	e426                	sd	s1,8(sp)
    80006996:	e04a                	sd	s2,0(sp)
    80006998:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000699a:	0001e517          	auipc	a0,0x1e
    8000699e:	78e50513          	addi	a0,a0,1934 # 80025128 <disk+0x2128>
    800069a2:	ffffa097          	auipc	ra,0xffffa
    800069a6:	220080e7          	jalr	544(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800069aa:	10001737          	lui	a4,0x10001
    800069ae:	533c                	lw	a5,96(a4)
    800069b0:	8b8d                	andi	a5,a5,3
    800069b2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800069b4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800069b8:	0001e797          	auipc	a5,0x1e
    800069bc:	64878793          	addi	a5,a5,1608 # 80025000 <disk+0x2000>
    800069c0:	6b94                	ld	a3,16(a5)
    800069c2:	0207d703          	lhu	a4,32(a5)
    800069c6:	0026d783          	lhu	a5,2(a3)
    800069ca:	06f70163          	beq	a4,a5,80006a2c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069ce:	0001c917          	auipc	s2,0x1c
    800069d2:	63290913          	addi	s2,s2,1586 # 80023000 <disk>
    800069d6:	0001e497          	auipc	s1,0x1e
    800069da:	62a48493          	addi	s1,s1,1578 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800069de:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069e2:	6898                	ld	a4,16(s1)
    800069e4:	0204d783          	lhu	a5,32(s1)
    800069e8:	8b9d                	andi	a5,a5,7
    800069ea:	078e                	slli	a5,a5,0x3
    800069ec:	97ba                	add	a5,a5,a4
    800069ee:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800069f0:	20078713          	addi	a4,a5,512
    800069f4:	0712                	slli	a4,a4,0x4
    800069f6:	974a                	add	a4,a4,s2
    800069f8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800069fc:	e731                	bnez	a4,80006a48 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800069fe:	20078793          	addi	a5,a5,512
    80006a02:	0792                	slli	a5,a5,0x4
    80006a04:	97ca                	add	a5,a5,s2
    80006a06:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006a08:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006a0c:	ffffc097          	auipc	ra,0xffffc
    80006a10:	b56080e7          	jalr	-1194(ra) # 80002562 <wakeup>

    disk.used_idx += 1;
    80006a14:	0204d783          	lhu	a5,32(s1)
    80006a18:	2785                	addiw	a5,a5,1
    80006a1a:	17c2                	slli	a5,a5,0x30
    80006a1c:	93c1                	srli	a5,a5,0x30
    80006a1e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006a22:	6898                	ld	a4,16(s1)
    80006a24:	00275703          	lhu	a4,2(a4)
    80006a28:	faf71be3          	bne	a4,a5,800069de <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006a2c:	0001e517          	auipc	a0,0x1e
    80006a30:	6fc50513          	addi	a0,a0,1788 # 80025128 <disk+0x2128>
    80006a34:	ffffa097          	auipc	ra,0xffffa
    80006a38:	242080e7          	jalr	578(ra) # 80000c76 <release>
}
    80006a3c:	60e2                	ld	ra,24(sp)
    80006a3e:	6442                	ld	s0,16(sp)
    80006a40:	64a2                	ld	s1,8(sp)
    80006a42:	6902                	ld	s2,0(sp)
    80006a44:	6105                	addi	sp,sp,32
    80006a46:	8082                	ret
      panic("virtio_disk_intr status");
    80006a48:	00002517          	auipc	a0,0x2
    80006a4c:	fd850513          	addi	a0,a0,-40 # 80008a20 <syscalls+0x3c8>
    80006a50:	ffffa097          	auipc	ra,0xffffa
    80006a54:	ada080e7          	jalr	-1318(ra) # 8000052a <panic>
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
