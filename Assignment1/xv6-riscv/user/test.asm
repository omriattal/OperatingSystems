
user/_test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user.h"

int main(void)
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
	int pid;
	if ((pid = fork()) > 0) {
   e:	00000097          	auipc	ra,0x0
  12:	2ec080e7          	jalr	748(ra) # 2fa <fork>
  16:	02a05e63          	blez	a0,52 <main+0x52>
		printf("Dad running\n");
  1a:	00001517          	auipc	a0,0x1
  1e:	81e50513          	addi	a0,a0,-2018 # 838 <malloc+0xe8>
  22:	00000097          	auipc	ra,0x0
  26:	670080e7          	jalr	1648(ra) # 692 <printf>
		for(int i = 0; i <= 10; i++){
  2a:	4481                	li	s1,0
			printf("%d bottles on the wall\n", i);
  2c:	00001997          	auipc	s3,0x1
  30:	81c98993          	addi	s3,s3,-2020 # 848 <malloc+0xf8>
		for(int i = 0; i <= 10; i++){
  34:	492d                	li	s2,11
			printf("%d bottles on the wall\n", i);
  36:	85a6                	mv	a1,s1
  38:	854e                	mv	a0,s3
  3a:	00000097          	auipc	ra,0x0
  3e:	658080e7          	jalr	1624(ra) # 692 <printf>
		for(int i = 0; i <= 10; i++){
  42:	2485                	addiw	s1,s1,1
  44:	ff2499e3          	bne	s1,s2,36 <main+0x36>
		}
		else{
			for(int i = 0; i < 2147483647; i++);
		}
	}
    exit(0);
  48:	4501                	li	a0,0
  4a:	00000097          	auipc	ra,0x0
  4e:	2b8080e7          	jalr	696(ra) # 302 <exit>
		if(fork() == 0){
  52:	00000097          	auipc	ra,0x0
  56:	2a8080e7          	jalr	680(ra) # 2fa <fork>
  5a:	c901                	beqz	a0,6a <main+0x6a>
  5c:	800007b7          	lui	a5,0x80000
  60:	fff7c793          	not	a5,a5
			for(int i = 0; i < 2147483647; i++);
  64:	37fd                	addiw	a5,a5,-1
  66:	fffd                	bnez	a5,64 <main+0x64>
  68:	b7c5                	j	48 <main+0x48>
			if(fork() == 0){
  6a:	00000097          	auipc	ra,0x0
  6e:	290080e7          	jalr	656(ra) # 2fa <fork>
  72:	c901                	beqz	a0,82 <main+0x82>
  74:	800007b7          	lui	a5,0x80000
  78:	fff7c793          	not	a5,a5
				for(int i = 0; i < 2147483647; i++);
  7c:	37fd                	addiw	a5,a5,-1
  7e:	fffd                	bnez	a5,7c <main+0x7c>
  80:	b7e1                	j	48 <main+0x48>
				printf("Jesus christ that was just 10 bottles");
  82:	00000517          	auipc	a0,0x0
  86:	7de50513          	addi	a0,a0,2014 # 860 <malloc+0x110>
  8a:	00000097          	auipc	ra,0x0
  8e:	608080e7          	jalr	1544(ra) # 692 <printf>
  92:	bf5d                	j	48 <main+0x48>

0000000000000094 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  94:	1141                	addi	sp,sp,-16
  96:	e422                	sd	s0,8(sp)
  98:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  9a:	87aa                	mv	a5,a0
  9c:	0585                	addi	a1,a1,1
  9e:	0785                	addi	a5,a5,1
  a0:	fff5c703          	lbu	a4,-1(a1)
  a4:	fee78fa3          	sb	a4,-1(a5) # ffffffff7fffffff <__global_pointer$+0xffffffff7fffef5e>
  a8:	fb75                	bnez	a4,9c <strcpy+0x8>
    ;
  return os;
}
  aa:	6422                	ld	s0,8(sp)
  ac:	0141                	addi	sp,sp,16
  ae:	8082                	ret

00000000000000b0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  b0:	1141                	addi	sp,sp,-16
  b2:	e422                	sd	s0,8(sp)
  b4:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  b6:	00054783          	lbu	a5,0(a0)
  ba:	cb91                	beqz	a5,ce <strcmp+0x1e>
  bc:	0005c703          	lbu	a4,0(a1)
  c0:	00f71763          	bne	a4,a5,ce <strcmp+0x1e>
    p++, q++;
  c4:	0505                	addi	a0,a0,1
  c6:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  c8:	00054783          	lbu	a5,0(a0)
  cc:	fbe5                	bnez	a5,bc <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  ce:	0005c503          	lbu	a0,0(a1)
}
  d2:	40a7853b          	subw	a0,a5,a0
  d6:	6422                	ld	s0,8(sp)
  d8:	0141                	addi	sp,sp,16
  da:	8082                	ret

00000000000000dc <strlen>:

uint
strlen(const char *s)
{
  dc:	1141                	addi	sp,sp,-16
  de:	e422                	sd	s0,8(sp)
  e0:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  e2:	00054783          	lbu	a5,0(a0)
  e6:	cf91                	beqz	a5,102 <strlen+0x26>
  e8:	0505                	addi	a0,a0,1
  ea:	87aa                	mv	a5,a0
  ec:	4685                	li	a3,1
  ee:	9e89                	subw	a3,a3,a0
  f0:	00f6853b          	addw	a0,a3,a5
  f4:	0785                	addi	a5,a5,1
  f6:	fff7c703          	lbu	a4,-1(a5)
  fa:	fb7d                	bnez	a4,f0 <strlen+0x14>
    ;
  return n;
}
  fc:	6422                	ld	s0,8(sp)
  fe:	0141                	addi	sp,sp,16
 100:	8082                	ret
  for(n = 0; s[n]; n++)
 102:	4501                	li	a0,0
 104:	bfe5                	j	fc <strlen+0x20>

0000000000000106 <memset>:

void*
memset(void *dst, int c, uint n)
{
 106:	1141                	addi	sp,sp,-16
 108:	e422                	sd	s0,8(sp)
 10a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 10c:	ca19                	beqz	a2,122 <memset+0x1c>
 10e:	87aa                	mv	a5,a0
 110:	1602                	slli	a2,a2,0x20
 112:	9201                	srli	a2,a2,0x20
 114:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 118:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 11c:	0785                	addi	a5,a5,1
 11e:	fee79de3          	bne	a5,a4,118 <memset+0x12>
  }
  return dst;
}
 122:	6422                	ld	s0,8(sp)
 124:	0141                	addi	sp,sp,16
 126:	8082                	ret

0000000000000128 <strchr>:

char*
strchr(const char *s, char c)
{
 128:	1141                	addi	sp,sp,-16
 12a:	e422                	sd	s0,8(sp)
 12c:	0800                	addi	s0,sp,16
  for(; *s; s++)
 12e:	00054783          	lbu	a5,0(a0)
 132:	cb99                	beqz	a5,148 <strchr+0x20>
    if(*s == c)
 134:	00f58763          	beq	a1,a5,142 <strchr+0x1a>
  for(; *s; s++)
 138:	0505                	addi	a0,a0,1
 13a:	00054783          	lbu	a5,0(a0)
 13e:	fbfd                	bnez	a5,134 <strchr+0xc>
      return (char*)s;
  return 0;
 140:	4501                	li	a0,0
}
 142:	6422                	ld	s0,8(sp)
 144:	0141                	addi	sp,sp,16
 146:	8082                	ret
  return 0;
 148:	4501                	li	a0,0
 14a:	bfe5                	j	142 <strchr+0x1a>

000000000000014c <gets>:

char*
gets(char *buf, int max)
{
 14c:	711d                	addi	sp,sp,-96
 14e:	ec86                	sd	ra,88(sp)
 150:	e8a2                	sd	s0,80(sp)
 152:	e4a6                	sd	s1,72(sp)
 154:	e0ca                	sd	s2,64(sp)
 156:	fc4e                	sd	s3,56(sp)
 158:	f852                	sd	s4,48(sp)
 15a:	f456                	sd	s5,40(sp)
 15c:	f05a                	sd	s6,32(sp)
 15e:	ec5e                	sd	s7,24(sp)
 160:	1080                	addi	s0,sp,96
 162:	8baa                	mv	s7,a0
 164:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 166:	892a                	mv	s2,a0
 168:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 16a:	4aa9                	li	s5,10
 16c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 16e:	89a6                	mv	s3,s1
 170:	2485                	addiw	s1,s1,1
 172:	0344d863          	bge	s1,s4,1a2 <gets+0x56>
    cc = read(0, &c, 1);
 176:	4605                	li	a2,1
 178:	faf40593          	addi	a1,s0,-81
 17c:	4501                	li	a0,0
 17e:	00000097          	auipc	ra,0x0
 182:	19c080e7          	jalr	412(ra) # 31a <read>
    if(cc < 1)
 186:	00a05e63          	blez	a0,1a2 <gets+0x56>
    buf[i++] = c;
 18a:	faf44783          	lbu	a5,-81(s0)
 18e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 192:	01578763          	beq	a5,s5,1a0 <gets+0x54>
 196:	0905                	addi	s2,s2,1
 198:	fd679be3          	bne	a5,s6,16e <gets+0x22>
  for(i=0; i+1 < max; ){
 19c:	89a6                	mv	s3,s1
 19e:	a011                	j	1a2 <gets+0x56>
 1a0:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1a2:	99de                	add	s3,s3,s7
 1a4:	00098023          	sb	zero,0(s3)
  return buf;
}
 1a8:	855e                	mv	a0,s7
 1aa:	60e6                	ld	ra,88(sp)
 1ac:	6446                	ld	s0,80(sp)
 1ae:	64a6                	ld	s1,72(sp)
 1b0:	6906                	ld	s2,64(sp)
 1b2:	79e2                	ld	s3,56(sp)
 1b4:	7a42                	ld	s4,48(sp)
 1b6:	7aa2                	ld	s5,40(sp)
 1b8:	7b02                	ld	s6,32(sp)
 1ba:	6be2                	ld	s7,24(sp)
 1bc:	6125                	addi	sp,sp,96
 1be:	8082                	ret

00000000000001c0 <stat>:

int
stat(const char *n, struct stat *st)
{
 1c0:	1101                	addi	sp,sp,-32
 1c2:	ec06                	sd	ra,24(sp)
 1c4:	e822                	sd	s0,16(sp)
 1c6:	e426                	sd	s1,8(sp)
 1c8:	e04a                	sd	s2,0(sp)
 1ca:	1000                	addi	s0,sp,32
 1cc:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1ce:	4581                	li	a1,0
 1d0:	00000097          	auipc	ra,0x0
 1d4:	172080e7          	jalr	370(ra) # 342 <open>
  if(fd < 0)
 1d8:	02054563          	bltz	a0,202 <stat+0x42>
 1dc:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1de:	85ca                	mv	a1,s2
 1e0:	00000097          	auipc	ra,0x0
 1e4:	17a080e7          	jalr	378(ra) # 35a <fstat>
 1e8:	892a                	mv	s2,a0
  close(fd);
 1ea:	8526                	mv	a0,s1
 1ec:	00000097          	auipc	ra,0x0
 1f0:	13e080e7          	jalr	318(ra) # 32a <close>
  return r;
}
 1f4:	854a                	mv	a0,s2
 1f6:	60e2                	ld	ra,24(sp)
 1f8:	6442                	ld	s0,16(sp)
 1fa:	64a2                	ld	s1,8(sp)
 1fc:	6902                	ld	s2,0(sp)
 1fe:	6105                	addi	sp,sp,32
 200:	8082                	ret
    return -1;
 202:	597d                	li	s2,-1
 204:	bfc5                	j	1f4 <stat+0x34>

0000000000000206 <atoi>:

int
atoi(const char *s)
{
 206:	1141                	addi	sp,sp,-16
 208:	e422                	sd	s0,8(sp)
 20a:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 20c:	00054603          	lbu	a2,0(a0)
 210:	fd06079b          	addiw	a5,a2,-48
 214:	0ff7f793          	andi	a5,a5,255
 218:	4725                	li	a4,9
 21a:	02f76963          	bltu	a4,a5,24c <atoi+0x46>
 21e:	86aa                	mv	a3,a0
  n = 0;
 220:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 222:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 224:	0685                	addi	a3,a3,1
 226:	0025179b          	slliw	a5,a0,0x2
 22a:	9fa9                	addw	a5,a5,a0
 22c:	0017979b          	slliw	a5,a5,0x1
 230:	9fb1                	addw	a5,a5,a2
 232:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 236:	0006c603          	lbu	a2,0(a3)
 23a:	fd06071b          	addiw	a4,a2,-48
 23e:	0ff77713          	andi	a4,a4,255
 242:	fee5f1e3          	bgeu	a1,a4,224 <atoi+0x1e>
  return n;
}
 246:	6422                	ld	s0,8(sp)
 248:	0141                	addi	sp,sp,16
 24a:	8082                	ret
  n = 0;
 24c:	4501                	li	a0,0
 24e:	bfe5                	j	246 <atoi+0x40>

0000000000000250 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 250:	1141                	addi	sp,sp,-16
 252:	e422                	sd	s0,8(sp)
 254:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 256:	02b57463          	bgeu	a0,a1,27e <memmove+0x2e>
    while(n-- > 0)
 25a:	00c05f63          	blez	a2,278 <memmove+0x28>
 25e:	1602                	slli	a2,a2,0x20
 260:	9201                	srli	a2,a2,0x20
 262:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 266:	872a                	mv	a4,a0
      *dst++ = *src++;
 268:	0585                	addi	a1,a1,1
 26a:	0705                	addi	a4,a4,1
 26c:	fff5c683          	lbu	a3,-1(a1)
 270:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 274:	fee79ae3          	bne	a5,a4,268 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 278:	6422                	ld	s0,8(sp)
 27a:	0141                	addi	sp,sp,16
 27c:	8082                	ret
    dst += n;
 27e:	00c50733          	add	a4,a0,a2
    src += n;
 282:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 284:	fec05ae3          	blez	a2,278 <memmove+0x28>
 288:	fff6079b          	addiw	a5,a2,-1
 28c:	1782                	slli	a5,a5,0x20
 28e:	9381                	srli	a5,a5,0x20
 290:	fff7c793          	not	a5,a5
 294:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 296:	15fd                	addi	a1,a1,-1
 298:	177d                	addi	a4,a4,-1
 29a:	0005c683          	lbu	a3,0(a1)
 29e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2a2:	fee79ae3          	bne	a5,a4,296 <memmove+0x46>
 2a6:	bfc9                	j	278 <memmove+0x28>

00000000000002a8 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2a8:	1141                	addi	sp,sp,-16
 2aa:	e422                	sd	s0,8(sp)
 2ac:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2ae:	ca05                	beqz	a2,2de <memcmp+0x36>
 2b0:	fff6069b          	addiw	a3,a2,-1
 2b4:	1682                	slli	a3,a3,0x20
 2b6:	9281                	srli	a3,a3,0x20
 2b8:	0685                	addi	a3,a3,1
 2ba:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2bc:	00054783          	lbu	a5,0(a0)
 2c0:	0005c703          	lbu	a4,0(a1)
 2c4:	00e79863          	bne	a5,a4,2d4 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2c8:	0505                	addi	a0,a0,1
    p2++;
 2ca:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2cc:	fed518e3          	bne	a0,a3,2bc <memcmp+0x14>
  }
  return 0;
 2d0:	4501                	li	a0,0
 2d2:	a019                	j	2d8 <memcmp+0x30>
      return *p1 - *p2;
 2d4:	40e7853b          	subw	a0,a5,a4
}
 2d8:	6422                	ld	s0,8(sp)
 2da:	0141                	addi	sp,sp,16
 2dc:	8082                	ret
  return 0;
 2de:	4501                	li	a0,0
 2e0:	bfe5                	j	2d8 <memcmp+0x30>

00000000000002e2 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2e2:	1141                	addi	sp,sp,-16
 2e4:	e406                	sd	ra,8(sp)
 2e6:	e022                	sd	s0,0(sp)
 2e8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2ea:	00000097          	auipc	ra,0x0
 2ee:	f66080e7          	jalr	-154(ra) # 250 <memmove>
}
 2f2:	60a2                	ld	ra,8(sp)
 2f4:	6402                	ld	s0,0(sp)
 2f6:	0141                	addi	sp,sp,16
 2f8:	8082                	ret

00000000000002fa <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2fa:	4885                	li	a7,1
 ecall
 2fc:	00000073          	ecall
 ret
 300:	8082                	ret

0000000000000302 <exit>:
.global exit
exit:
 li a7, SYS_exit
 302:	4889                	li	a7,2
 ecall
 304:	00000073          	ecall
 ret
 308:	8082                	ret

000000000000030a <wait>:
.global wait
wait:
 li a7, SYS_wait
 30a:	488d                	li	a7,3
 ecall
 30c:	00000073          	ecall
 ret
 310:	8082                	ret

0000000000000312 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 312:	4891                	li	a7,4
 ecall
 314:	00000073          	ecall
 ret
 318:	8082                	ret

000000000000031a <read>:
.global read
read:
 li a7, SYS_read
 31a:	4895                	li	a7,5
 ecall
 31c:	00000073          	ecall
 ret
 320:	8082                	ret

0000000000000322 <write>:
.global write
write:
 li a7, SYS_write
 322:	48c1                	li	a7,16
 ecall
 324:	00000073          	ecall
 ret
 328:	8082                	ret

000000000000032a <close>:
.global close
close:
 li a7, SYS_close
 32a:	48d5                	li	a7,21
 ecall
 32c:	00000073          	ecall
 ret
 330:	8082                	ret

0000000000000332 <kill>:
.global kill
kill:
 li a7, SYS_kill
 332:	4899                	li	a7,6
 ecall
 334:	00000073          	ecall
 ret
 338:	8082                	ret

000000000000033a <exec>:
.global exec
exec:
 li a7, SYS_exec
 33a:	489d                	li	a7,7
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <open>:
.global open
open:
 li a7, SYS_open
 342:	48bd                	li	a7,15
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 34a:	48c5                	li	a7,17
 ecall
 34c:	00000073          	ecall
 ret
 350:	8082                	ret

0000000000000352 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 352:	48c9                	li	a7,18
 ecall
 354:	00000073          	ecall
 ret
 358:	8082                	ret

000000000000035a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 35a:	48a1                	li	a7,8
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <link>:
.global link
link:
 li a7, SYS_link
 362:	48cd                	li	a7,19
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 36a:	48d1                	li	a7,20
 ecall
 36c:	00000073          	ecall
 ret
 370:	8082                	ret

0000000000000372 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 372:	48a5                	li	a7,9
 ecall
 374:	00000073          	ecall
 ret
 378:	8082                	ret

000000000000037a <dup>:
.global dup
dup:
 li a7, SYS_dup
 37a:	48a9                	li	a7,10
 ecall
 37c:	00000073          	ecall
 ret
 380:	8082                	ret

0000000000000382 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 382:	48ad                	li	a7,11
 ecall
 384:	00000073          	ecall
 ret
 388:	8082                	ret

000000000000038a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 38a:	48b1                	li	a7,12
 ecall
 38c:	00000073          	ecall
 ret
 390:	8082                	ret

0000000000000392 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 392:	48b5                	li	a7,13
 ecall
 394:	00000073          	ecall
 ret
 398:	8082                	ret

000000000000039a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 39a:	48b9                	li	a7,14
 ecall
 39c:	00000073          	ecall
 ret
 3a0:	8082                	ret

00000000000003a2 <trace>:
.global trace
trace:
 li a7, SYS_trace
 3a2:	48d9                	li	a7,22
 ecall
 3a4:	00000073          	ecall
 ret
 3a8:	8082                	ret

00000000000003aa <getmsk>:
.global getmsk
getmsk:
 li a7, SYS_getmsk
 3aa:	48dd                	li	a7,23
 ecall
 3ac:	00000073          	ecall
 ret
 3b0:	8082                	ret

00000000000003b2 <wait_stat>:
.global wait_stat
wait_stat:
 li a7, SYS_wait_stat
 3b2:	48e1                	li	a7,24
 ecall
 3b4:	00000073          	ecall
 ret
 3b8:	8082                	ret

00000000000003ba <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3ba:	1101                	addi	sp,sp,-32
 3bc:	ec06                	sd	ra,24(sp)
 3be:	e822                	sd	s0,16(sp)
 3c0:	1000                	addi	s0,sp,32
 3c2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3c6:	4605                	li	a2,1
 3c8:	fef40593          	addi	a1,s0,-17
 3cc:	00000097          	auipc	ra,0x0
 3d0:	f56080e7          	jalr	-170(ra) # 322 <write>
}
 3d4:	60e2                	ld	ra,24(sp)
 3d6:	6442                	ld	s0,16(sp)
 3d8:	6105                	addi	sp,sp,32
 3da:	8082                	ret

00000000000003dc <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3dc:	7139                	addi	sp,sp,-64
 3de:	fc06                	sd	ra,56(sp)
 3e0:	f822                	sd	s0,48(sp)
 3e2:	f426                	sd	s1,40(sp)
 3e4:	f04a                	sd	s2,32(sp)
 3e6:	ec4e                	sd	s3,24(sp)
 3e8:	0080                	addi	s0,sp,64
 3ea:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3ec:	c299                	beqz	a3,3f2 <printint+0x16>
 3ee:	0805c863          	bltz	a1,47e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3f2:	2581                	sext.w	a1,a1
  neg = 0;
 3f4:	4881                	li	a7,0
 3f6:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3fa:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3fc:	2601                	sext.w	a2,a2
 3fe:	00000517          	auipc	a0,0x0
 402:	49250513          	addi	a0,a0,1170 # 890 <digits>
 406:	883a                	mv	a6,a4
 408:	2705                	addiw	a4,a4,1
 40a:	02c5f7bb          	remuw	a5,a1,a2
 40e:	1782                	slli	a5,a5,0x20
 410:	9381                	srli	a5,a5,0x20
 412:	97aa                	add	a5,a5,a0
 414:	0007c783          	lbu	a5,0(a5)
 418:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 41c:	0005879b          	sext.w	a5,a1
 420:	02c5d5bb          	divuw	a1,a1,a2
 424:	0685                	addi	a3,a3,1
 426:	fec7f0e3          	bgeu	a5,a2,406 <printint+0x2a>
  if(neg)
 42a:	00088b63          	beqz	a7,440 <printint+0x64>
    buf[i++] = '-';
 42e:	fd040793          	addi	a5,s0,-48
 432:	973e                	add	a4,a4,a5
 434:	02d00793          	li	a5,45
 438:	fef70823          	sb	a5,-16(a4)
 43c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 440:	02e05863          	blez	a4,470 <printint+0x94>
 444:	fc040793          	addi	a5,s0,-64
 448:	00e78933          	add	s2,a5,a4
 44c:	fff78993          	addi	s3,a5,-1
 450:	99ba                	add	s3,s3,a4
 452:	377d                	addiw	a4,a4,-1
 454:	1702                	slli	a4,a4,0x20
 456:	9301                	srli	a4,a4,0x20
 458:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 45c:	fff94583          	lbu	a1,-1(s2)
 460:	8526                	mv	a0,s1
 462:	00000097          	auipc	ra,0x0
 466:	f58080e7          	jalr	-168(ra) # 3ba <putc>
  while(--i >= 0)
 46a:	197d                	addi	s2,s2,-1
 46c:	ff3918e3          	bne	s2,s3,45c <printint+0x80>
}
 470:	70e2                	ld	ra,56(sp)
 472:	7442                	ld	s0,48(sp)
 474:	74a2                	ld	s1,40(sp)
 476:	7902                	ld	s2,32(sp)
 478:	69e2                	ld	s3,24(sp)
 47a:	6121                	addi	sp,sp,64
 47c:	8082                	ret
    x = -xx;
 47e:	40b005bb          	negw	a1,a1
    neg = 1;
 482:	4885                	li	a7,1
    x = -xx;
 484:	bf8d                	j	3f6 <printint+0x1a>

0000000000000486 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 486:	7119                	addi	sp,sp,-128
 488:	fc86                	sd	ra,120(sp)
 48a:	f8a2                	sd	s0,112(sp)
 48c:	f4a6                	sd	s1,104(sp)
 48e:	f0ca                	sd	s2,96(sp)
 490:	ecce                	sd	s3,88(sp)
 492:	e8d2                	sd	s4,80(sp)
 494:	e4d6                	sd	s5,72(sp)
 496:	e0da                	sd	s6,64(sp)
 498:	fc5e                	sd	s7,56(sp)
 49a:	f862                	sd	s8,48(sp)
 49c:	f466                	sd	s9,40(sp)
 49e:	f06a                	sd	s10,32(sp)
 4a0:	ec6e                	sd	s11,24(sp)
 4a2:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4a4:	0005c903          	lbu	s2,0(a1)
 4a8:	18090f63          	beqz	s2,646 <vprintf+0x1c0>
 4ac:	8aaa                	mv	s5,a0
 4ae:	8b32                	mv	s6,a2
 4b0:	00158493          	addi	s1,a1,1
  state = 0;
 4b4:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4b6:	02500a13          	li	s4,37
      if(c == 'd'){
 4ba:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 4be:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 4c2:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 4c6:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4ca:	00000b97          	auipc	s7,0x0
 4ce:	3c6b8b93          	addi	s7,s7,966 # 890 <digits>
 4d2:	a839                	j	4f0 <vprintf+0x6a>
        putc(fd, c);
 4d4:	85ca                	mv	a1,s2
 4d6:	8556                	mv	a0,s5
 4d8:	00000097          	auipc	ra,0x0
 4dc:	ee2080e7          	jalr	-286(ra) # 3ba <putc>
 4e0:	a019                	j	4e6 <vprintf+0x60>
    } else if(state == '%'){
 4e2:	01498f63          	beq	s3,s4,500 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 4e6:	0485                	addi	s1,s1,1
 4e8:	fff4c903          	lbu	s2,-1(s1)
 4ec:	14090d63          	beqz	s2,646 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 4f0:	0009079b          	sext.w	a5,s2
    if(state == 0){
 4f4:	fe0997e3          	bnez	s3,4e2 <vprintf+0x5c>
      if(c == '%'){
 4f8:	fd479ee3          	bne	a5,s4,4d4 <vprintf+0x4e>
        state = '%';
 4fc:	89be                	mv	s3,a5
 4fe:	b7e5                	j	4e6 <vprintf+0x60>
      if(c == 'd'){
 500:	05878063          	beq	a5,s8,540 <vprintf+0xba>
      } else if(c == 'l') {
 504:	05978c63          	beq	a5,s9,55c <vprintf+0xd6>
      } else if(c == 'x') {
 508:	07a78863          	beq	a5,s10,578 <vprintf+0xf2>
      } else if(c == 'p') {
 50c:	09b78463          	beq	a5,s11,594 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 510:	07300713          	li	a4,115
 514:	0ce78663          	beq	a5,a4,5e0 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 518:	06300713          	li	a4,99
 51c:	0ee78e63          	beq	a5,a4,618 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 520:	11478863          	beq	a5,s4,630 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 524:	85d2                	mv	a1,s4
 526:	8556                	mv	a0,s5
 528:	00000097          	auipc	ra,0x0
 52c:	e92080e7          	jalr	-366(ra) # 3ba <putc>
        putc(fd, c);
 530:	85ca                	mv	a1,s2
 532:	8556                	mv	a0,s5
 534:	00000097          	auipc	ra,0x0
 538:	e86080e7          	jalr	-378(ra) # 3ba <putc>
      }
      state = 0;
 53c:	4981                	li	s3,0
 53e:	b765                	j	4e6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 540:	008b0913          	addi	s2,s6,8
 544:	4685                	li	a3,1
 546:	4629                	li	a2,10
 548:	000b2583          	lw	a1,0(s6)
 54c:	8556                	mv	a0,s5
 54e:	00000097          	auipc	ra,0x0
 552:	e8e080e7          	jalr	-370(ra) # 3dc <printint>
 556:	8b4a                	mv	s6,s2
      state = 0;
 558:	4981                	li	s3,0
 55a:	b771                	j	4e6 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 55c:	008b0913          	addi	s2,s6,8
 560:	4681                	li	a3,0
 562:	4629                	li	a2,10
 564:	000b2583          	lw	a1,0(s6)
 568:	8556                	mv	a0,s5
 56a:	00000097          	auipc	ra,0x0
 56e:	e72080e7          	jalr	-398(ra) # 3dc <printint>
 572:	8b4a                	mv	s6,s2
      state = 0;
 574:	4981                	li	s3,0
 576:	bf85                	j	4e6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 578:	008b0913          	addi	s2,s6,8
 57c:	4681                	li	a3,0
 57e:	4641                	li	a2,16
 580:	000b2583          	lw	a1,0(s6)
 584:	8556                	mv	a0,s5
 586:	00000097          	auipc	ra,0x0
 58a:	e56080e7          	jalr	-426(ra) # 3dc <printint>
 58e:	8b4a                	mv	s6,s2
      state = 0;
 590:	4981                	li	s3,0
 592:	bf91                	j	4e6 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 594:	008b0793          	addi	a5,s6,8
 598:	f8f43423          	sd	a5,-120(s0)
 59c:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5a0:	03000593          	li	a1,48
 5a4:	8556                	mv	a0,s5
 5a6:	00000097          	auipc	ra,0x0
 5aa:	e14080e7          	jalr	-492(ra) # 3ba <putc>
  putc(fd, 'x');
 5ae:	85ea                	mv	a1,s10
 5b0:	8556                	mv	a0,s5
 5b2:	00000097          	auipc	ra,0x0
 5b6:	e08080e7          	jalr	-504(ra) # 3ba <putc>
 5ba:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5bc:	03c9d793          	srli	a5,s3,0x3c
 5c0:	97de                	add	a5,a5,s7
 5c2:	0007c583          	lbu	a1,0(a5)
 5c6:	8556                	mv	a0,s5
 5c8:	00000097          	auipc	ra,0x0
 5cc:	df2080e7          	jalr	-526(ra) # 3ba <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5d0:	0992                	slli	s3,s3,0x4
 5d2:	397d                	addiw	s2,s2,-1
 5d4:	fe0914e3          	bnez	s2,5bc <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 5d8:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5dc:	4981                	li	s3,0
 5de:	b721                	j	4e6 <vprintf+0x60>
        s = va_arg(ap, char*);
 5e0:	008b0993          	addi	s3,s6,8
 5e4:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 5e8:	02090163          	beqz	s2,60a <vprintf+0x184>
        while(*s != 0){
 5ec:	00094583          	lbu	a1,0(s2)
 5f0:	c9a1                	beqz	a1,640 <vprintf+0x1ba>
          putc(fd, *s);
 5f2:	8556                	mv	a0,s5
 5f4:	00000097          	auipc	ra,0x0
 5f8:	dc6080e7          	jalr	-570(ra) # 3ba <putc>
          s++;
 5fc:	0905                	addi	s2,s2,1
        while(*s != 0){
 5fe:	00094583          	lbu	a1,0(s2)
 602:	f9e5                	bnez	a1,5f2 <vprintf+0x16c>
        s = va_arg(ap, char*);
 604:	8b4e                	mv	s6,s3
      state = 0;
 606:	4981                	li	s3,0
 608:	bdf9                	j	4e6 <vprintf+0x60>
          s = "(null)";
 60a:	00000917          	auipc	s2,0x0
 60e:	27e90913          	addi	s2,s2,638 # 888 <malloc+0x138>
        while(*s != 0){
 612:	02800593          	li	a1,40
 616:	bff1                	j	5f2 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 618:	008b0913          	addi	s2,s6,8
 61c:	000b4583          	lbu	a1,0(s6)
 620:	8556                	mv	a0,s5
 622:	00000097          	auipc	ra,0x0
 626:	d98080e7          	jalr	-616(ra) # 3ba <putc>
 62a:	8b4a                	mv	s6,s2
      state = 0;
 62c:	4981                	li	s3,0
 62e:	bd65                	j	4e6 <vprintf+0x60>
        putc(fd, c);
 630:	85d2                	mv	a1,s4
 632:	8556                	mv	a0,s5
 634:	00000097          	auipc	ra,0x0
 638:	d86080e7          	jalr	-634(ra) # 3ba <putc>
      state = 0;
 63c:	4981                	li	s3,0
 63e:	b565                	j	4e6 <vprintf+0x60>
        s = va_arg(ap, char*);
 640:	8b4e                	mv	s6,s3
      state = 0;
 642:	4981                	li	s3,0
 644:	b54d                	j	4e6 <vprintf+0x60>
    }
  }
}
 646:	70e6                	ld	ra,120(sp)
 648:	7446                	ld	s0,112(sp)
 64a:	74a6                	ld	s1,104(sp)
 64c:	7906                	ld	s2,96(sp)
 64e:	69e6                	ld	s3,88(sp)
 650:	6a46                	ld	s4,80(sp)
 652:	6aa6                	ld	s5,72(sp)
 654:	6b06                	ld	s6,64(sp)
 656:	7be2                	ld	s7,56(sp)
 658:	7c42                	ld	s8,48(sp)
 65a:	7ca2                	ld	s9,40(sp)
 65c:	7d02                	ld	s10,32(sp)
 65e:	6de2                	ld	s11,24(sp)
 660:	6109                	addi	sp,sp,128
 662:	8082                	ret

0000000000000664 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 664:	715d                	addi	sp,sp,-80
 666:	ec06                	sd	ra,24(sp)
 668:	e822                	sd	s0,16(sp)
 66a:	1000                	addi	s0,sp,32
 66c:	e010                	sd	a2,0(s0)
 66e:	e414                	sd	a3,8(s0)
 670:	e818                	sd	a4,16(s0)
 672:	ec1c                	sd	a5,24(s0)
 674:	03043023          	sd	a6,32(s0)
 678:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 67c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 680:	8622                	mv	a2,s0
 682:	00000097          	auipc	ra,0x0
 686:	e04080e7          	jalr	-508(ra) # 486 <vprintf>
}
 68a:	60e2                	ld	ra,24(sp)
 68c:	6442                	ld	s0,16(sp)
 68e:	6161                	addi	sp,sp,80
 690:	8082                	ret

0000000000000692 <printf>:

void
printf(const char *fmt, ...)
{
 692:	711d                	addi	sp,sp,-96
 694:	ec06                	sd	ra,24(sp)
 696:	e822                	sd	s0,16(sp)
 698:	1000                	addi	s0,sp,32
 69a:	e40c                	sd	a1,8(s0)
 69c:	e810                	sd	a2,16(s0)
 69e:	ec14                	sd	a3,24(s0)
 6a0:	f018                	sd	a4,32(s0)
 6a2:	f41c                	sd	a5,40(s0)
 6a4:	03043823          	sd	a6,48(s0)
 6a8:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6ac:	00840613          	addi	a2,s0,8
 6b0:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6b4:	85aa                	mv	a1,a0
 6b6:	4505                	li	a0,1
 6b8:	00000097          	auipc	ra,0x0
 6bc:	dce080e7          	jalr	-562(ra) # 486 <vprintf>
}
 6c0:	60e2                	ld	ra,24(sp)
 6c2:	6442                	ld	s0,16(sp)
 6c4:	6125                	addi	sp,sp,96
 6c6:	8082                	ret

00000000000006c8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6c8:	1141                	addi	sp,sp,-16
 6ca:	e422                	sd	s0,8(sp)
 6cc:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6ce:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6d2:	00000797          	auipc	a5,0x0
 6d6:	1d67b783          	ld	a5,470(a5) # 8a8 <freep>
 6da:	a805                	j	70a <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6dc:	4618                	lw	a4,8(a2)
 6de:	9db9                	addw	a1,a1,a4
 6e0:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6e4:	6398                	ld	a4,0(a5)
 6e6:	6318                	ld	a4,0(a4)
 6e8:	fee53823          	sd	a4,-16(a0)
 6ec:	a091                	j	730 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6ee:	ff852703          	lw	a4,-8(a0)
 6f2:	9e39                	addw	a2,a2,a4
 6f4:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 6f6:	ff053703          	ld	a4,-16(a0)
 6fa:	e398                	sd	a4,0(a5)
 6fc:	a099                	j	742 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6fe:	6398                	ld	a4,0(a5)
 700:	00e7e463          	bltu	a5,a4,708 <free+0x40>
 704:	00e6ea63          	bltu	a3,a4,718 <free+0x50>
{
 708:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 70a:	fed7fae3          	bgeu	a5,a3,6fe <free+0x36>
 70e:	6398                	ld	a4,0(a5)
 710:	00e6e463          	bltu	a3,a4,718 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 714:	fee7eae3          	bltu	a5,a4,708 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 718:	ff852583          	lw	a1,-8(a0)
 71c:	6390                	ld	a2,0(a5)
 71e:	02059813          	slli	a6,a1,0x20
 722:	01c85713          	srli	a4,a6,0x1c
 726:	9736                	add	a4,a4,a3
 728:	fae60ae3          	beq	a2,a4,6dc <free+0x14>
    bp->s.ptr = p->s.ptr;
 72c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 730:	4790                	lw	a2,8(a5)
 732:	02061593          	slli	a1,a2,0x20
 736:	01c5d713          	srli	a4,a1,0x1c
 73a:	973e                	add	a4,a4,a5
 73c:	fae689e3          	beq	a3,a4,6ee <free+0x26>
  } else
    p->s.ptr = bp;
 740:	e394                	sd	a3,0(a5)
  freep = p;
 742:	00000717          	auipc	a4,0x0
 746:	16f73323          	sd	a5,358(a4) # 8a8 <freep>
}
 74a:	6422                	ld	s0,8(sp)
 74c:	0141                	addi	sp,sp,16
 74e:	8082                	ret

0000000000000750 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 750:	7139                	addi	sp,sp,-64
 752:	fc06                	sd	ra,56(sp)
 754:	f822                	sd	s0,48(sp)
 756:	f426                	sd	s1,40(sp)
 758:	f04a                	sd	s2,32(sp)
 75a:	ec4e                	sd	s3,24(sp)
 75c:	e852                	sd	s4,16(sp)
 75e:	e456                	sd	s5,8(sp)
 760:	e05a                	sd	s6,0(sp)
 762:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 764:	02051493          	slli	s1,a0,0x20
 768:	9081                	srli	s1,s1,0x20
 76a:	04bd                	addi	s1,s1,15
 76c:	8091                	srli	s1,s1,0x4
 76e:	0014899b          	addiw	s3,s1,1
 772:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 774:	00000517          	auipc	a0,0x0
 778:	13453503          	ld	a0,308(a0) # 8a8 <freep>
 77c:	c515                	beqz	a0,7a8 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 77e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 780:	4798                	lw	a4,8(a5)
 782:	02977f63          	bgeu	a4,s1,7c0 <malloc+0x70>
 786:	8a4e                	mv	s4,s3
 788:	0009871b          	sext.w	a4,s3
 78c:	6685                	lui	a3,0x1
 78e:	00d77363          	bgeu	a4,a3,794 <malloc+0x44>
 792:	6a05                	lui	s4,0x1
 794:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 798:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 79c:	00000917          	auipc	s2,0x0
 7a0:	10c90913          	addi	s2,s2,268 # 8a8 <freep>
  if(p == (char*)-1)
 7a4:	5afd                	li	s5,-1
 7a6:	a895                	j	81a <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7a8:	00000797          	auipc	a5,0x0
 7ac:	10878793          	addi	a5,a5,264 # 8b0 <base>
 7b0:	00000717          	auipc	a4,0x0
 7b4:	0ef73c23          	sd	a5,248(a4) # 8a8 <freep>
 7b8:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7ba:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7be:	b7e1                	j	786 <malloc+0x36>
      if(p->s.size == nunits)
 7c0:	02e48c63          	beq	s1,a4,7f8 <malloc+0xa8>
        p->s.size -= nunits;
 7c4:	4137073b          	subw	a4,a4,s3
 7c8:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7ca:	02071693          	slli	a3,a4,0x20
 7ce:	01c6d713          	srli	a4,a3,0x1c
 7d2:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7d4:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7d8:	00000717          	auipc	a4,0x0
 7dc:	0ca73823          	sd	a0,208(a4) # 8a8 <freep>
      return (void*)(p + 1);
 7e0:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7e4:	70e2                	ld	ra,56(sp)
 7e6:	7442                	ld	s0,48(sp)
 7e8:	74a2                	ld	s1,40(sp)
 7ea:	7902                	ld	s2,32(sp)
 7ec:	69e2                	ld	s3,24(sp)
 7ee:	6a42                	ld	s4,16(sp)
 7f0:	6aa2                	ld	s5,8(sp)
 7f2:	6b02                	ld	s6,0(sp)
 7f4:	6121                	addi	sp,sp,64
 7f6:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7f8:	6398                	ld	a4,0(a5)
 7fa:	e118                	sd	a4,0(a0)
 7fc:	bff1                	j	7d8 <malloc+0x88>
  hp->s.size = nu;
 7fe:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 802:	0541                	addi	a0,a0,16
 804:	00000097          	auipc	ra,0x0
 808:	ec4080e7          	jalr	-316(ra) # 6c8 <free>
  return freep;
 80c:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 810:	d971                	beqz	a0,7e4 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 812:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 814:	4798                	lw	a4,8(a5)
 816:	fa9775e3          	bgeu	a4,s1,7c0 <malloc+0x70>
    if(p == freep)
 81a:	00093703          	ld	a4,0(s2)
 81e:	853e                	mv	a0,a5
 820:	fef719e3          	bne	a4,a5,812 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 824:	8552                	mv	a0,s4
 826:	00000097          	auipc	ra,0x0
 82a:	b64080e7          	jalr	-1180(ra) # 38a <sbrk>
  if(p == (char*)-1)
 82e:	fd5518e3          	bne	a0,s5,7fe <malloc+0xae>
        return 0;
 832:	4501                	li	a0,0
 834:	bf45                	j	7e4 <malloc+0x94>
