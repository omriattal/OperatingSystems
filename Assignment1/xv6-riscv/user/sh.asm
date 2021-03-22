
user/_sh:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <getcmd>:
    }
    exit(0);
}

int getcmd(char *buf, int nbuf)
{
       0:	1101                	addi	sp,sp,-32
       2:	ec06                	sd	ra,24(sp)
       4:	e822                	sd	s0,16(sp)
       6:	e426                	sd	s1,8(sp)
       8:	e04a                	sd	s2,0(sp)
       a:	1000                	addi	s0,sp,32
       c:	84aa                	mv	s1,a0
       e:	892e                	mv	s2,a1
    fprintf(2, "$ ");
      10:	00001597          	auipc	a1,0x1
      14:	3b858593          	addi	a1,a1,952 # 13c8 <malloc+0xe6>
      18:	4509                	li	a0,2
      1a:	00001097          	auipc	ra,0x1
      1e:	1dc080e7          	jalr	476(ra) # 11f6 <fprintf>
    memset(buf, 0, nbuf);
      22:	864a                	mv	a2,s2
      24:	4581                	li	a1,0
      26:	8526                	mv	a0,s1
      28:	00001097          	auipc	ra,0x1
      2c:	c88080e7          	jalr	-888(ra) # cb0 <memset>
    gets(buf, nbuf);
      30:	85ca                	mv	a1,s2
      32:	8526                	mv	a0,s1
      34:	00001097          	auipc	ra,0x1
      38:	cc2080e7          	jalr	-830(ra) # cf6 <gets>
    if (buf[0] == 0) // EOF
      3c:	0004c503          	lbu	a0,0(s1)
      40:	00153513          	seqz	a0,a0
        return -1;
    return 0;
}
      44:	40a00533          	neg	a0,a0
      48:	60e2                	ld	ra,24(sp)
      4a:	6442                	ld	s0,16(sp)
      4c:	64a2                	ld	s1,8(sp)
      4e:	6902                	ld	s2,0(sp)
      50:	6105                	addi	sp,sp,32
      52:	8082                	ret

0000000000000054 <panic>:
    }
    exit(0);
}

void panic(char *s)
{
      54:	1141                	addi	sp,sp,-16
      56:	e406                	sd	ra,8(sp)
      58:	e022                	sd	s0,0(sp)
      5a:	0800                	addi	s0,sp,16
      5c:	862a                	mv	a2,a0
    fprintf(2, "%s\n", s);
      5e:	00001597          	auipc	a1,0x1
      62:	37258593          	addi	a1,a1,882 # 13d0 <malloc+0xee>
      66:	4509                	li	a0,2
      68:	00001097          	auipc	ra,0x1
      6c:	18e080e7          	jalr	398(ra) # 11f6 <fprintf>
    exit(1);
      70:	4505                	li	a0,1
      72:	00001097          	auipc	ra,0x1
      76:	e3a080e7          	jalr	-454(ra) # eac <exit>

000000000000007a <fork1>:
}

int fork1(void)
{
      7a:	1141                	addi	sp,sp,-16
      7c:	e406                	sd	ra,8(sp)
      7e:	e022                	sd	s0,0(sp)
      80:	0800                	addi	s0,sp,16
    int pid;

    pid = fork();
      82:	00001097          	auipc	ra,0x1
      86:	e22080e7          	jalr	-478(ra) # ea4 <fork>
    if (pid == -1)
      8a:	57fd                	li	a5,-1
      8c:	00f50663          	beq	a0,a5,98 <fork1+0x1e>
        panic("fork");
    return pid;
}
      90:	60a2                	ld	ra,8(sp)
      92:	6402                	ld	s0,0(sp)
      94:	0141                	addi	sp,sp,16
      96:	8082                	ret
        panic("fork");
      98:	00001517          	auipc	a0,0x1
      9c:	34050513          	addi	a0,a0,832 # 13d8 <malloc+0xf6>
      a0:	00000097          	auipc	ra,0x0
      a4:	fb4080e7          	jalr	-76(ra) # 54 <panic>

00000000000000a8 <runcmd>:
{
      a8:	7159                	addi	sp,sp,-112
      aa:	f486                	sd	ra,104(sp)
      ac:	f0a2                	sd	s0,96(sp)
      ae:	eca6                	sd	s1,88(sp)
      b0:	e8ca                	sd	s2,80(sp)
      b2:	e4ce                	sd	s3,72(sp)
      b4:	e0d2                	sd	s4,64(sp)
      b6:	fc56                	sd	s5,56(sp)
      b8:	f85a                	sd	s6,48(sp)
      ba:	f45e                	sd	s7,40(sp)
      bc:	f062                	sd	s8,32(sp)
      be:	ec66                	sd	s9,24(sp)
      c0:	1880                	addi	s0,sp,112
    if (cmd == 0)
      c2:	c10d                	beqz	a0,e4 <runcmd+0x3c>
      c4:	84aa                	mv	s1,a0
    switch (cmd->type)
      c6:	4118                	lw	a4,0(a0)
      c8:	4795                	li	a5,5
      ca:	02e7e263          	bltu	a5,a4,ee <runcmd+0x46>
      ce:	00056783          	lwu	a5,0(a0)
      d2:	078a                	slli	a5,a5,0x2
      d4:	00001717          	auipc	a4,0x1
      d8:	40c70713          	addi	a4,a4,1036 # 14e0 <malloc+0x1fe>
      dc:	97ba                	add	a5,a5,a4
      de:	439c                	lw	a5,0(a5)
      e0:	97ba                	add	a5,a5,a4
      e2:	8782                	jr	a5
        exit(1);
      e4:	4505                	li	a0,1
      e6:	00001097          	auipc	ra,0x1
      ea:	dc6080e7          	jalr	-570(ra) # eac <exit>
        panic("runcmd");
      ee:	00001517          	auipc	a0,0x1
      f2:	2f250513          	addi	a0,a0,754 # 13e0 <malloc+0xfe>
      f6:	00000097          	auipc	ra,0x0
      fa:	f5e080e7          	jalr	-162(ra) # 54 <panic>
        if (ecmd->argv[0] == 0)
      fe:	6508                	ld	a0,8(a0)
     100:	10050363          	beqz	a0,206 <runcmd+0x15e>
        exec(ecmd->argv[0], ecmd->argv);
     104:	00848c93          	addi	s9,s1,8
     108:	85e6                	mv	a1,s9
     10a:	00001097          	auipc	ra,0x1
     10e:	dda080e7          	jalr	-550(ra) # ee4 <exec>
        struct stat *pathst = (struct stat *)malloc(sizeof(struct stat));
     112:	4561                	li	a0,24
     114:	00001097          	auipc	ra,0x1
     118:	1ce080e7          	jalr	462(ra) # 12e2 <malloc>
     11c:	892a                	mv	s2,a0
        stat("/path", pathst);
     11e:	85aa                	mv	a1,a0
     120:	00001517          	auipc	a0,0x1
     124:	2c850513          	addi	a0,a0,712 # 13e8 <malloc+0x106>
     128:	00001097          	auipc	ra,0x1
     12c:	c42080e7          	jalr	-958(ra) # d6a <stat>
        int file_size = pathst->size;
     130:	01092c03          	lw	s8,16(s2)
        char *buffer = (char *)malloc(file_size);
     134:	8562                	mv	a0,s8
     136:	00001097          	auipc	ra,0x1
     13a:	1ac080e7          	jalr	428(ra) # 12e2 <malloc>
     13e:	8aaa                	mv	s5,a0
        int pathfd = open("/path", O_RDONLY);
     140:	4581                	li	a1,0
     142:	00001517          	auipc	a0,0x1
     146:	2a650513          	addi	a0,a0,678 # 13e8 <malloc+0x106>
     14a:	00001097          	auipc	ra,0x1
     14e:	da2080e7          	jalr	-606(ra) # eec <open>
     152:	892a                	mv	s2,a0
        read(pathfd, buffer, file_size);
     154:	8662                	mv	a2,s8
     156:	85d6                	mv	a1,s5
     158:	00001097          	auipc	ra,0x1
     15c:	d6c080e7          	jalr	-660(ra) # ec4 <read>
        close(pathfd);
     160:	854a                	mv	a0,s2
     162:	00001097          	auipc	ra,0x1
     166:	d72080e7          	jalr	-654(ra) # ed4 <close>
        while (index_from < file_size)
     16a:	07805f63          	blez	s8,1e8 <runcmd+0x140>
        int index_from = 0;
     16e:	4b81                	li	s7,0
            char *to = strchr(from, PATHSEP); //will get us the string that starts with :
     170:	03a00593          	li	a1,58
     174:	8556                	mv	a0,s5
     176:	00001097          	auipc	ra,0x1
     17a:	b5c080e7          	jalr	-1188(ra) # cd2 <strchr>
     17e:	89aa                	mv	s3,a0
            int dir_len = to - from;
     180:	41550a33          	sub	s4,a0,s5
     184:	000a091b          	sext.w	s2,s4
            char *program = ecmd->argv[0];
     188:	0084bb03          	ld	s6,8(s1)
            char *file_path = (char *)malloc(dir_len + strlen(program));
     18c:	855a                	mv	a0,s6
     18e:	00001097          	auipc	ra,0x1
     192:	af8080e7          	jalr	-1288(ra) # c86 <strlen>
     196:	00aa053b          	addw	a0,s4,a0
     19a:	00001097          	auipc	ra,0x1
     19e:	148080e7          	jalr	328(ra) # 12e2 <malloc>
     1a2:	8a2a                	mv	s4,a0
            memmove(file_path, from, dir_len);
     1a4:	864a                	mv	a2,s2
     1a6:	85d6                	mv	a1,s5
     1a8:	00001097          	auipc	ra,0x1
     1ac:	c52080e7          	jalr	-942(ra) # dfa <memmove>
            memmove(file_path + dir_len, program, strlen(program));
     1b0:	012a0ab3          	add	s5,s4,s2
     1b4:	855a                	mv	a0,s6
     1b6:	00001097          	auipc	ra,0x1
     1ba:	ad0080e7          	jalr	-1328(ra) # c86 <strlen>
     1be:	0005061b          	sext.w	a2,a0
     1c2:	85da                	mv	a1,s6
     1c4:	8556                	mv	a0,s5
     1c6:	00001097          	auipc	ra,0x1
     1ca:	c34080e7          	jalr	-972(ra) # dfa <memmove>
            exec(file_path,ecmd->argv);
     1ce:	85e6                	mv	a1,s9
     1d0:	8552                	mv	a0,s4
     1d2:	00001097          	auipc	ra,0x1
     1d6:	d12080e7          	jalr	-750(ra) # ee4 <exec>
            index_from += dir_len + 1;
     1da:	2905                	addiw	s2,s2,1
     1dc:	01790bbb          	addw	s7,s2,s7
            from = to + 1;
     1e0:	00198a93          	addi	s5,s3,1
        while (index_from < file_size)
     1e4:	f98bc6e3          	blt	s7,s8,170 <runcmd+0xc8>
        fprintf(2, "exec %s failed\n", ecmd->argv[0]);
     1e8:	6490                	ld	a2,8(s1)
     1ea:	00001597          	auipc	a1,0x1
     1ee:	20658593          	addi	a1,a1,518 # 13f0 <malloc+0x10e>
     1f2:	4509                	li	a0,2
     1f4:	00001097          	auipc	ra,0x1
     1f8:	002080e7          	jalr	2(ra) # 11f6 <fprintf>
    exit(0);
     1fc:	4501                	li	a0,0
     1fe:	00001097          	auipc	ra,0x1
     202:	cae080e7          	jalr	-850(ra) # eac <exit>
            exit(1);
     206:	4505                	li	a0,1
     208:	00001097          	auipc	ra,0x1
     20c:	ca4080e7          	jalr	-860(ra) # eac <exit>
        close(rcmd->fd);
     210:	5148                	lw	a0,36(a0)
     212:	00001097          	auipc	ra,0x1
     216:	cc2080e7          	jalr	-830(ra) # ed4 <close>
        if (open(rcmd->file, rcmd->mode) < 0)
     21a:	508c                	lw	a1,32(s1)
     21c:	6888                	ld	a0,16(s1)
     21e:	00001097          	auipc	ra,0x1
     222:	cce080e7          	jalr	-818(ra) # eec <open>
     226:	00054763          	bltz	a0,234 <runcmd+0x18c>
        runcmd(rcmd->cmd);
     22a:	6488                	ld	a0,8(s1)
     22c:	00000097          	auipc	ra,0x0
     230:	e7c080e7          	jalr	-388(ra) # a8 <runcmd>
            fprintf(2, "open %s failed\n", rcmd->file);
     234:	6890                	ld	a2,16(s1)
     236:	00001597          	auipc	a1,0x1
     23a:	1ca58593          	addi	a1,a1,458 # 1400 <malloc+0x11e>
     23e:	4509                	li	a0,2
     240:	00001097          	auipc	ra,0x1
     244:	fb6080e7          	jalr	-74(ra) # 11f6 <fprintf>
            exit(1);
     248:	4505                	li	a0,1
     24a:	00001097          	auipc	ra,0x1
     24e:	c62080e7          	jalr	-926(ra) # eac <exit>
        if (fork1() == 0)
     252:	00000097          	auipc	ra,0x0
     256:	e28080e7          	jalr	-472(ra) # 7a <fork1>
     25a:	c919                	beqz	a0,270 <runcmd+0x1c8>
        wait(0);
     25c:	4501                	li	a0,0
     25e:	00001097          	auipc	ra,0x1
     262:	c56080e7          	jalr	-938(ra) # eb4 <wait>
        runcmd(lcmd->right);
     266:	6888                	ld	a0,16(s1)
     268:	00000097          	auipc	ra,0x0
     26c:	e40080e7          	jalr	-448(ra) # a8 <runcmd>
            runcmd(lcmd->left);
     270:	6488                	ld	a0,8(s1)
     272:	00000097          	auipc	ra,0x0
     276:	e36080e7          	jalr	-458(ra) # a8 <runcmd>
        if (pipe(p) < 0)
     27a:	f9840513          	addi	a0,s0,-104
     27e:	00001097          	auipc	ra,0x1
     282:	c3e080e7          	jalr	-962(ra) # ebc <pipe>
     286:	04054363          	bltz	a0,2cc <runcmd+0x224>
        if (fork1() == 0)
     28a:	00000097          	auipc	ra,0x0
     28e:	df0080e7          	jalr	-528(ra) # 7a <fork1>
     292:	c529                	beqz	a0,2dc <runcmd+0x234>
        if (fork1() == 0)
     294:	00000097          	auipc	ra,0x0
     298:	de6080e7          	jalr	-538(ra) # 7a <fork1>
     29c:	cd25                	beqz	a0,314 <runcmd+0x26c>
        close(p[0]);
     29e:	f9842503          	lw	a0,-104(s0)
     2a2:	00001097          	auipc	ra,0x1
     2a6:	c32080e7          	jalr	-974(ra) # ed4 <close>
        close(p[1]);
     2aa:	f9c42503          	lw	a0,-100(s0)
     2ae:	00001097          	auipc	ra,0x1
     2b2:	c26080e7          	jalr	-986(ra) # ed4 <close>
        wait(0);
     2b6:	4501                	li	a0,0
     2b8:	00001097          	auipc	ra,0x1
     2bc:	bfc080e7          	jalr	-1028(ra) # eb4 <wait>
        wait(0);
     2c0:	4501                	li	a0,0
     2c2:	00001097          	auipc	ra,0x1
     2c6:	bf2080e7          	jalr	-1038(ra) # eb4 <wait>
        break;
     2ca:	bf0d                	j	1fc <runcmd+0x154>
            panic("pipe");
     2cc:	00001517          	auipc	a0,0x1
     2d0:	14450513          	addi	a0,a0,324 # 1410 <malloc+0x12e>
     2d4:	00000097          	auipc	ra,0x0
     2d8:	d80080e7          	jalr	-640(ra) # 54 <panic>
            close(1);
     2dc:	4505                	li	a0,1
     2de:	00001097          	auipc	ra,0x1
     2e2:	bf6080e7          	jalr	-1034(ra) # ed4 <close>
            dup(p[1]);
     2e6:	f9c42503          	lw	a0,-100(s0)
     2ea:	00001097          	auipc	ra,0x1
     2ee:	c3a080e7          	jalr	-966(ra) # f24 <dup>
            close(p[0]);
     2f2:	f9842503          	lw	a0,-104(s0)
     2f6:	00001097          	auipc	ra,0x1
     2fa:	bde080e7          	jalr	-1058(ra) # ed4 <close>
            close(p[1]);
     2fe:	f9c42503          	lw	a0,-100(s0)
     302:	00001097          	auipc	ra,0x1
     306:	bd2080e7          	jalr	-1070(ra) # ed4 <close>
            runcmd(pcmd->left);
     30a:	6488                	ld	a0,8(s1)
     30c:	00000097          	auipc	ra,0x0
     310:	d9c080e7          	jalr	-612(ra) # a8 <runcmd>
            close(0);
     314:	00001097          	auipc	ra,0x1
     318:	bc0080e7          	jalr	-1088(ra) # ed4 <close>
            dup(p[0]);
     31c:	f9842503          	lw	a0,-104(s0)
     320:	00001097          	auipc	ra,0x1
     324:	c04080e7          	jalr	-1020(ra) # f24 <dup>
            close(p[0]);
     328:	f9842503          	lw	a0,-104(s0)
     32c:	00001097          	auipc	ra,0x1
     330:	ba8080e7          	jalr	-1112(ra) # ed4 <close>
            close(p[1]);
     334:	f9c42503          	lw	a0,-100(s0)
     338:	00001097          	auipc	ra,0x1
     33c:	b9c080e7          	jalr	-1124(ra) # ed4 <close>
            runcmd(pcmd->right);
     340:	6888                	ld	a0,16(s1)
     342:	00000097          	auipc	ra,0x0
     346:	d66080e7          	jalr	-666(ra) # a8 <runcmd>
        if (fork1() == 0)
     34a:	00000097          	auipc	ra,0x0
     34e:	d30080e7          	jalr	-720(ra) # 7a <fork1>
     352:	ea0515e3          	bnez	a0,1fc <runcmd+0x154>
            runcmd(bcmd->cmd);
     356:	6488                	ld	a0,8(s1)
     358:	00000097          	auipc	ra,0x0
     35c:	d50080e7          	jalr	-688(ra) # a8 <runcmd>

0000000000000360 <execcmd>:
//PAGEBREAK!
// Constructors

struct cmd *
execcmd(void)
{
     360:	1101                	addi	sp,sp,-32
     362:	ec06                	sd	ra,24(sp)
     364:	e822                	sd	s0,16(sp)
     366:	e426                	sd	s1,8(sp)
     368:	1000                	addi	s0,sp,32
    struct execcmd *cmd;

    cmd = malloc(sizeof(*cmd));
     36a:	0a800513          	li	a0,168
     36e:	00001097          	auipc	ra,0x1
     372:	f74080e7          	jalr	-140(ra) # 12e2 <malloc>
     376:	84aa                	mv	s1,a0
    memset(cmd, 0, sizeof(*cmd));
     378:	0a800613          	li	a2,168
     37c:	4581                	li	a1,0
     37e:	00001097          	auipc	ra,0x1
     382:	932080e7          	jalr	-1742(ra) # cb0 <memset>
    cmd->type = EXEC;
     386:	4785                	li	a5,1
     388:	c09c                	sw	a5,0(s1)
    return (struct cmd *)cmd;
}
     38a:	8526                	mv	a0,s1
     38c:	60e2                	ld	ra,24(sp)
     38e:	6442                	ld	s0,16(sp)
     390:	64a2                	ld	s1,8(sp)
     392:	6105                	addi	sp,sp,32
     394:	8082                	ret

0000000000000396 <redircmd>:

struct cmd *
redircmd(struct cmd *subcmd, char *file, char *efile, int mode, int fd)
{
     396:	7139                	addi	sp,sp,-64
     398:	fc06                	sd	ra,56(sp)
     39a:	f822                	sd	s0,48(sp)
     39c:	f426                	sd	s1,40(sp)
     39e:	f04a                	sd	s2,32(sp)
     3a0:	ec4e                	sd	s3,24(sp)
     3a2:	e852                	sd	s4,16(sp)
     3a4:	e456                	sd	s5,8(sp)
     3a6:	e05a                	sd	s6,0(sp)
     3a8:	0080                	addi	s0,sp,64
     3aa:	8b2a                	mv	s6,a0
     3ac:	8aae                	mv	s5,a1
     3ae:	8a32                	mv	s4,a2
     3b0:	89b6                	mv	s3,a3
     3b2:	893a                	mv	s2,a4
    struct redircmd *cmd;

    cmd = malloc(sizeof(*cmd));
     3b4:	02800513          	li	a0,40
     3b8:	00001097          	auipc	ra,0x1
     3bc:	f2a080e7          	jalr	-214(ra) # 12e2 <malloc>
     3c0:	84aa                	mv	s1,a0
    memset(cmd, 0, sizeof(*cmd));
     3c2:	02800613          	li	a2,40
     3c6:	4581                	li	a1,0
     3c8:	00001097          	auipc	ra,0x1
     3cc:	8e8080e7          	jalr	-1816(ra) # cb0 <memset>
    cmd->type = REDIR;
     3d0:	4789                	li	a5,2
     3d2:	c09c                	sw	a5,0(s1)
    cmd->cmd = subcmd;
     3d4:	0164b423          	sd	s6,8(s1)
    cmd->file = file;
     3d8:	0154b823          	sd	s5,16(s1)
    cmd->efile = efile;
     3dc:	0144bc23          	sd	s4,24(s1)
    cmd->mode = mode;
     3e0:	0334a023          	sw	s3,32(s1)
    cmd->fd = fd;
     3e4:	0324a223          	sw	s2,36(s1)
    return (struct cmd *)cmd;
}
     3e8:	8526                	mv	a0,s1
     3ea:	70e2                	ld	ra,56(sp)
     3ec:	7442                	ld	s0,48(sp)
     3ee:	74a2                	ld	s1,40(sp)
     3f0:	7902                	ld	s2,32(sp)
     3f2:	69e2                	ld	s3,24(sp)
     3f4:	6a42                	ld	s4,16(sp)
     3f6:	6aa2                	ld	s5,8(sp)
     3f8:	6b02                	ld	s6,0(sp)
     3fa:	6121                	addi	sp,sp,64
     3fc:	8082                	ret

00000000000003fe <pipecmd>:

struct cmd *
pipecmd(struct cmd *left, struct cmd *right)
{
     3fe:	7179                	addi	sp,sp,-48
     400:	f406                	sd	ra,40(sp)
     402:	f022                	sd	s0,32(sp)
     404:	ec26                	sd	s1,24(sp)
     406:	e84a                	sd	s2,16(sp)
     408:	e44e                	sd	s3,8(sp)
     40a:	1800                	addi	s0,sp,48
     40c:	89aa                	mv	s3,a0
     40e:	892e                	mv	s2,a1
    struct pipecmd *cmd;

    cmd = malloc(sizeof(*cmd));
     410:	4561                	li	a0,24
     412:	00001097          	auipc	ra,0x1
     416:	ed0080e7          	jalr	-304(ra) # 12e2 <malloc>
     41a:	84aa                	mv	s1,a0
    memset(cmd, 0, sizeof(*cmd));
     41c:	4661                	li	a2,24
     41e:	4581                	li	a1,0
     420:	00001097          	auipc	ra,0x1
     424:	890080e7          	jalr	-1904(ra) # cb0 <memset>
    cmd->type = PIPE;
     428:	478d                	li	a5,3
     42a:	c09c                	sw	a5,0(s1)
    cmd->left = left;
     42c:	0134b423          	sd	s3,8(s1)
    cmd->right = right;
     430:	0124b823          	sd	s2,16(s1)
    return (struct cmd *)cmd;
}
     434:	8526                	mv	a0,s1
     436:	70a2                	ld	ra,40(sp)
     438:	7402                	ld	s0,32(sp)
     43a:	64e2                	ld	s1,24(sp)
     43c:	6942                	ld	s2,16(sp)
     43e:	69a2                	ld	s3,8(sp)
     440:	6145                	addi	sp,sp,48
     442:	8082                	ret

0000000000000444 <listcmd>:

struct cmd *
listcmd(struct cmd *left, struct cmd *right)
{
     444:	7179                	addi	sp,sp,-48
     446:	f406                	sd	ra,40(sp)
     448:	f022                	sd	s0,32(sp)
     44a:	ec26                	sd	s1,24(sp)
     44c:	e84a                	sd	s2,16(sp)
     44e:	e44e                	sd	s3,8(sp)
     450:	1800                	addi	s0,sp,48
     452:	89aa                	mv	s3,a0
     454:	892e                	mv	s2,a1
    struct listcmd *cmd;

    cmd = malloc(sizeof(*cmd));
     456:	4561                	li	a0,24
     458:	00001097          	auipc	ra,0x1
     45c:	e8a080e7          	jalr	-374(ra) # 12e2 <malloc>
     460:	84aa                	mv	s1,a0
    memset(cmd, 0, sizeof(*cmd));
     462:	4661                	li	a2,24
     464:	4581                	li	a1,0
     466:	00001097          	auipc	ra,0x1
     46a:	84a080e7          	jalr	-1974(ra) # cb0 <memset>
    cmd->type = LIST;
     46e:	4791                	li	a5,4
     470:	c09c                	sw	a5,0(s1)
    cmd->left = left;
     472:	0134b423          	sd	s3,8(s1)
    cmd->right = right;
     476:	0124b823          	sd	s2,16(s1)
    return (struct cmd *)cmd;
}
     47a:	8526                	mv	a0,s1
     47c:	70a2                	ld	ra,40(sp)
     47e:	7402                	ld	s0,32(sp)
     480:	64e2                	ld	s1,24(sp)
     482:	6942                	ld	s2,16(sp)
     484:	69a2                	ld	s3,8(sp)
     486:	6145                	addi	sp,sp,48
     488:	8082                	ret

000000000000048a <backcmd>:

struct cmd *
backcmd(struct cmd *subcmd)
{
     48a:	1101                	addi	sp,sp,-32
     48c:	ec06                	sd	ra,24(sp)
     48e:	e822                	sd	s0,16(sp)
     490:	e426                	sd	s1,8(sp)
     492:	e04a                	sd	s2,0(sp)
     494:	1000                	addi	s0,sp,32
     496:	892a                	mv	s2,a0
    struct backcmd *cmd;

    cmd = malloc(sizeof(*cmd));
     498:	4541                	li	a0,16
     49a:	00001097          	auipc	ra,0x1
     49e:	e48080e7          	jalr	-440(ra) # 12e2 <malloc>
     4a2:	84aa                	mv	s1,a0
    memset(cmd, 0, sizeof(*cmd));
     4a4:	4641                	li	a2,16
     4a6:	4581                	li	a1,0
     4a8:	00001097          	auipc	ra,0x1
     4ac:	808080e7          	jalr	-2040(ra) # cb0 <memset>
    cmd->type = BACK;
     4b0:	4795                	li	a5,5
     4b2:	c09c                	sw	a5,0(s1)
    cmd->cmd = subcmd;
     4b4:	0124b423          	sd	s2,8(s1)
    return (struct cmd *)cmd;
}
     4b8:	8526                	mv	a0,s1
     4ba:	60e2                	ld	ra,24(sp)
     4bc:	6442                	ld	s0,16(sp)
     4be:	64a2                	ld	s1,8(sp)
     4c0:	6902                	ld	s2,0(sp)
     4c2:	6105                	addi	sp,sp,32
     4c4:	8082                	ret

00000000000004c6 <gettoken>:

char whitespace[] = " \t\r\n\v";
char symbols[] = "<|>&;()";

int gettoken(char **ps, char *es, char **q, char **eq)
{
     4c6:	7139                	addi	sp,sp,-64
     4c8:	fc06                	sd	ra,56(sp)
     4ca:	f822                	sd	s0,48(sp)
     4cc:	f426                	sd	s1,40(sp)
     4ce:	f04a                	sd	s2,32(sp)
     4d0:	ec4e                	sd	s3,24(sp)
     4d2:	e852                	sd	s4,16(sp)
     4d4:	e456                	sd	s5,8(sp)
     4d6:	e05a                	sd	s6,0(sp)
     4d8:	0080                	addi	s0,sp,64
     4da:	8a2a                	mv	s4,a0
     4dc:	892e                	mv	s2,a1
     4de:	8ab2                	mv	s5,a2
     4e0:	8b36                	mv	s6,a3
    char *s;
    int ret;

    s = *ps;
     4e2:	6104                	ld	s1,0(a0)
    while (s < es && strchr(whitespace, *s))
     4e4:	00001997          	auipc	s3,0x1
     4e8:	05498993          	addi	s3,s3,84 # 1538 <whitespace>
     4ec:	00b4fd63          	bgeu	s1,a1,506 <gettoken+0x40>
     4f0:	0004c583          	lbu	a1,0(s1)
     4f4:	854e                	mv	a0,s3
     4f6:	00000097          	auipc	ra,0x0
     4fa:	7dc080e7          	jalr	2012(ra) # cd2 <strchr>
     4fe:	c501                	beqz	a0,506 <gettoken+0x40>
        s++;
     500:	0485                	addi	s1,s1,1
    while (s < es && strchr(whitespace, *s))
     502:	fe9917e3          	bne	s2,s1,4f0 <gettoken+0x2a>
    if (q)
     506:	000a8463          	beqz	s5,50e <gettoken+0x48>
        *q = s;
     50a:	009ab023          	sd	s1,0(s5)
    ret = *s;
     50e:	0004c783          	lbu	a5,0(s1)
     512:	00078a9b          	sext.w	s5,a5
    switch (*s)
     516:	03c00713          	li	a4,60
     51a:	06f76563          	bltu	a4,a5,584 <gettoken+0xbe>
     51e:	03a00713          	li	a4,58
     522:	00f76e63          	bltu	a4,a5,53e <gettoken+0x78>
     526:	cf89                	beqz	a5,540 <gettoken+0x7a>
     528:	02600713          	li	a4,38
     52c:	00e78963          	beq	a5,a4,53e <gettoken+0x78>
     530:	fd87879b          	addiw	a5,a5,-40
     534:	0ff7f793          	andi	a5,a5,255
     538:	4705                	li	a4,1
     53a:	06f76c63          	bltu	a4,a5,5b2 <gettoken+0xec>
    case '(':
    case ')':
    case ';':
    case '&':
    case '<':
        s++;
     53e:	0485                	addi	s1,s1,1
        ret = 'a';
        while (s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
            s++;
        break;
    }
    if (eq)
     540:	000b0463          	beqz	s6,548 <gettoken+0x82>
        *eq = s;
     544:	009b3023          	sd	s1,0(s6)

    while (s < es && strchr(whitespace, *s))
     548:	00001997          	auipc	s3,0x1
     54c:	ff098993          	addi	s3,s3,-16 # 1538 <whitespace>
     550:	0124fd63          	bgeu	s1,s2,56a <gettoken+0xa4>
     554:	0004c583          	lbu	a1,0(s1)
     558:	854e                	mv	a0,s3
     55a:	00000097          	auipc	ra,0x0
     55e:	778080e7          	jalr	1912(ra) # cd2 <strchr>
     562:	c501                	beqz	a0,56a <gettoken+0xa4>
        s++;
     564:	0485                	addi	s1,s1,1
    while (s < es && strchr(whitespace, *s))
     566:	fe9917e3          	bne	s2,s1,554 <gettoken+0x8e>
    *ps = s;
     56a:	009a3023          	sd	s1,0(s4)
    return ret;
}
     56e:	8556                	mv	a0,s5
     570:	70e2                	ld	ra,56(sp)
     572:	7442                	ld	s0,48(sp)
     574:	74a2                	ld	s1,40(sp)
     576:	7902                	ld	s2,32(sp)
     578:	69e2                	ld	s3,24(sp)
     57a:	6a42                	ld	s4,16(sp)
     57c:	6aa2                	ld	s5,8(sp)
     57e:	6b02                	ld	s6,0(sp)
     580:	6121                	addi	sp,sp,64
     582:	8082                	ret
    switch (*s)
     584:	03e00713          	li	a4,62
     588:	02e79163          	bne	a5,a4,5aa <gettoken+0xe4>
        s++;
     58c:	00148693          	addi	a3,s1,1
        if (*s == '>')
     590:	0014c703          	lbu	a4,1(s1)
     594:	03e00793          	li	a5,62
            s++;
     598:	0489                	addi	s1,s1,2
            ret = '+';
     59a:	02b00a93          	li	s5,43
        if (*s == '>')
     59e:	faf701e3          	beq	a4,a5,540 <gettoken+0x7a>
        s++;
     5a2:	84b6                	mv	s1,a3
    ret = *s;
     5a4:	03e00a93          	li	s5,62
     5a8:	bf61                	j	540 <gettoken+0x7a>
    switch (*s)
     5aa:	07c00713          	li	a4,124
     5ae:	f8e788e3          	beq	a5,a4,53e <gettoken+0x78>
        while (s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
     5b2:	00001997          	auipc	s3,0x1
     5b6:	f8698993          	addi	s3,s3,-122 # 1538 <whitespace>
     5ba:	00001a97          	auipc	s5,0x1
     5be:	f76a8a93          	addi	s5,s5,-138 # 1530 <symbols>
     5c2:	0324f563          	bgeu	s1,s2,5ec <gettoken+0x126>
     5c6:	0004c583          	lbu	a1,0(s1)
     5ca:	854e                	mv	a0,s3
     5cc:	00000097          	auipc	ra,0x0
     5d0:	706080e7          	jalr	1798(ra) # cd2 <strchr>
     5d4:	e505                	bnez	a0,5fc <gettoken+0x136>
     5d6:	0004c583          	lbu	a1,0(s1)
     5da:	8556                	mv	a0,s5
     5dc:	00000097          	auipc	ra,0x0
     5e0:	6f6080e7          	jalr	1782(ra) # cd2 <strchr>
     5e4:	e909                	bnez	a0,5f6 <gettoken+0x130>
            s++;
     5e6:	0485                	addi	s1,s1,1
        while (s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
     5e8:	fc991fe3          	bne	s2,s1,5c6 <gettoken+0x100>
    if (eq)
     5ec:	06100a93          	li	s5,97
     5f0:	f40b1ae3          	bnez	s6,544 <gettoken+0x7e>
     5f4:	bf9d                	j	56a <gettoken+0xa4>
        ret = 'a';
     5f6:	06100a93          	li	s5,97
     5fa:	b799                	j	540 <gettoken+0x7a>
     5fc:	06100a93          	li	s5,97
     600:	b781                	j	540 <gettoken+0x7a>

0000000000000602 <peek>:

int peek(char **ps, char *es, char *toks)
{
     602:	7139                	addi	sp,sp,-64
     604:	fc06                	sd	ra,56(sp)
     606:	f822                	sd	s0,48(sp)
     608:	f426                	sd	s1,40(sp)
     60a:	f04a                	sd	s2,32(sp)
     60c:	ec4e                	sd	s3,24(sp)
     60e:	e852                	sd	s4,16(sp)
     610:	e456                	sd	s5,8(sp)
     612:	0080                	addi	s0,sp,64
     614:	8a2a                	mv	s4,a0
     616:	892e                	mv	s2,a1
     618:	8ab2                	mv	s5,a2
    char *s;

    s = *ps;
     61a:	6104                	ld	s1,0(a0)
    while (s < es && strchr(whitespace, *s))
     61c:	00001997          	auipc	s3,0x1
     620:	f1c98993          	addi	s3,s3,-228 # 1538 <whitespace>
     624:	00b4fd63          	bgeu	s1,a1,63e <peek+0x3c>
     628:	0004c583          	lbu	a1,0(s1)
     62c:	854e                	mv	a0,s3
     62e:	00000097          	auipc	ra,0x0
     632:	6a4080e7          	jalr	1700(ra) # cd2 <strchr>
     636:	c501                	beqz	a0,63e <peek+0x3c>
        s++;
     638:	0485                	addi	s1,s1,1
    while (s < es && strchr(whitespace, *s))
     63a:	fe9917e3          	bne	s2,s1,628 <peek+0x26>
    *ps = s;
     63e:	009a3023          	sd	s1,0(s4)
    return *s && strchr(toks, *s);
     642:	0004c583          	lbu	a1,0(s1)
     646:	4501                	li	a0,0
     648:	e991                	bnez	a1,65c <peek+0x5a>
}
     64a:	70e2                	ld	ra,56(sp)
     64c:	7442                	ld	s0,48(sp)
     64e:	74a2                	ld	s1,40(sp)
     650:	7902                	ld	s2,32(sp)
     652:	69e2                	ld	s3,24(sp)
     654:	6a42                	ld	s4,16(sp)
     656:	6aa2                	ld	s5,8(sp)
     658:	6121                	addi	sp,sp,64
     65a:	8082                	ret
    return *s && strchr(toks, *s);
     65c:	8556                	mv	a0,s5
     65e:	00000097          	auipc	ra,0x0
     662:	674080e7          	jalr	1652(ra) # cd2 <strchr>
     666:	00a03533          	snez	a0,a0
     66a:	b7c5                	j	64a <peek+0x48>

000000000000066c <parseredirs>:
    return cmd;
}

struct cmd *
parseredirs(struct cmd *cmd, char **ps, char *es)
{
     66c:	7159                	addi	sp,sp,-112
     66e:	f486                	sd	ra,104(sp)
     670:	f0a2                	sd	s0,96(sp)
     672:	eca6                	sd	s1,88(sp)
     674:	e8ca                	sd	s2,80(sp)
     676:	e4ce                	sd	s3,72(sp)
     678:	e0d2                	sd	s4,64(sp)
     67a:	fc56                	sd	s5,56(sp)
     67c:	f85a                	sd	s6,48(sp)
     67e:	f45e                	sd	s7,40(sp)
     680:	f062                	sd	s8,32(sp)
     682:	ec66                	sd	s9,24(sp)
     684:	1880                	addi	s0,sp,112
     686:	8a2a                	mv	s4,a0
     688:	89ae                	mv	s3,a1
     68a:	8932                	mv	s2,a2
    int tok;
    char *q, *eq;

    while (peek(ps, es, "<>"))
     68c:	00001b97          	auipc	s7,0x1
     690:	dacb8b93          	addi	s7,s7,-596 # 1438 <malloc+0x156>
    {
        tok = gettoken(ps, es, 0, 0);
        if (gettoken(ps, es, &q, &eq) != 'a')
     694:	06100c13          	li	s8,97
            panic("missing file for redirection");
        switch (tok)
     698:	03c00c93          	li	s9,60
    while (peek(ps, es, "<>"))
     69c:	a02d                	j	6c6 <parseredirs+0x5a>
            panic("missing file for redirection");
     69e:	00001517          	auipc	a0,0x1
     6a2:	d7a50513          	addi	a0,a0,-646 # 1418 <malloc+0x136>
     6a6:	00000097          	auipc	ra,0x0
     6aa:	9ae080e7          	jalr	-1618(ra) # 54 <panic>
        {
        case '<':
            cmd = redircmd(cmd, q, eq, O_RDONLY, 0);
     6ae:	4701                	li	a4,0
     6b0:	4681                	li	a3,0
     6b2:	f9043603          	ld	a2,-112(s0)
     6b6:	f9843583          	ld	a1,-104(s0)
     6ba:	8552                	mv	a0,s4
     6bc:	00000097          	auipc	ra,0x0
     6c0:	cda080e7          	jalr	-806(ra) # 396 <redircmd>
     6c4:	8a2a                	mv	s4,a0
        switch (tok)
     6c6:	03e00b13          	li	s6,62
     6ca:	02b00a93          	li	s5,43
    while (peek(ps, es, "<>"))
     6ce:	865e                	mv	a2,s7
     6d0:	85ca                	mv	a1,s2
     6d2:	854e                	mv	a0,s3
     6d4:	00000097          	auipc	ra,0x0
     6d8:	f2e080e7          	jalr	-210(ra) # 602 <peek>
     6dc:	c925                	beqz	a0,74c <parseredirs+0xe0>
        tok = gettoken(ps, es, 0, 0);
     6de:	4681                	li	a3,0
     6e0:	4601                	li	a2,0
     6e2:	85ca                	mv	a1,s2
     6e4:	854e                	mv	a0,s3
     6e6:	00000097          	auipc	ra,0x0
     6ea:	de0080e7          	jalr	-544(ra) # 4c6 <gettoken>
     6ee:	84aa                	mv	s1,a0
        if (gettoken(ps, es, &q, &eq) != 'a')
     6f0:	f9040693          	addi	a3,s0,-112
     6f4:	f9840613          	addi	a2,s0,-104
     6f8:	85ca                	mv	a1,s2
     6fa:	854e                	mv	a0,s3
     6fc:	00000097          	auipc	ra,0x0
     700:	dca080e7          	jalr	-566(ra) # 4c6 <gettoken>
     704:	f9851de3          	bne	a0,s8,69e <parseredirs+0x32>
        switch (tok)
     708:	fb9483e3          	beq	s1,s9,6ae <parseredirs+0x42>
     70c:	03648263          	beq	s1,s6,730 <parseredirs+0xc4>
     710:	fb549fe3          	bne	s1,s5,6ce <parseredirs+0x62>
            break;
        case '>':
            cmd = redircmd(cmd, q, eq, O_WRONLY | O_CREATE | O_TRUNC, 1);
            break;
        case '+': // >>
            cmd = redircmd(cmd, q, eq, O_WRONLY | O_CREATE, 1);
     714:	4705                	li	a4,1
     716:	20100693          	li	a3,513
     71a:	f9043603          	ld	a2,-112(s0)
     71e:	f9843583          	ld	a1,-104(s0)
     722:	8552                	mv	a0,s4
     724:	00000097          	auipc	ra,0x0
     728:	c72080e7          	jalr	-910(ra) # 396 <redircmd>
     72c:	8a2a                	mv	s4,a0
            break;
     72e:	bf61                	j	6c6 <parseredirs+0x5a>
            cmd = redircmd(cmd, q, eq, O_WRONLY | O_CREATE | O_TRUNC, 1);
     730:	4705                	li	a4,1
     732:	60100693          	li	a3,1537
     736:	f9043603          	ld	a2,-112(s0)
     73a:	f9843583          	ld	a1,-104(s0)
     73e:	8552                	mv	a0,s4
     740:	00000097          	auipc	ra,0x0
     744:	c56080e7          	jalr	-938(ra) # 396 <redircmd>
     748:	8a2a                	mv	s4,a0
            break;
     74a:	bfb5                	j	6c6 <parseredirs+0x5a>
        }
    }
    return cmd;
}
     74c:	8552                	mv	a0,s4
     74e:	70a6                	ld	ra,104(sp)
     750:	7406                	ld	s0,96(sp)
     752:	64e6                	ld	s1,88(sp)
     754:	6946                	ld	s2,80(sp)
     756:	69a6                	ld	s3,72(sp)
     758:	6a06                	ld	s4,64(sp)
     75a:	7ae2                	ld	s5,56(sp)
     75c:	7b42                	ld	s6,48(sp)
     75e:	7ba2                	ld	s7,40(sp)
     760:	7c02                	ld	s8,32(sp)
     762:	6ce2                	ld	s9,24(sp)
     764:	6165                	addi	sp,sp,112
     766:	8082                	ret

0000000000000768 <parseexec>:
    return cmd;
}

struct cmd *
parseexec(char **ps, char *es)
{
     768:	7159                	addi	sp,sp,-112
     76a:	f486                	sd	ra,104(sp)
     76c:	f0a2                	sd	s0,96(sp)
     76e:	eca6                	sd	s1,88(sp)
     770:	e8ca                	sd	s2,80(sp)
     772:	e4ce                	sd	s3,72(sp)
     774:	e0d2                	sd	s4,64(sp)
     776:	fc56                	sd	s5,56(sp)
     778:	f85a                	sd	s6,48(sp)
     77a:	f45e                	sd	s7,40(sp)
     77c:	f062                	sd	s8,32(sp)
     77e:	ec66                	sd	s9,24(sp)
     780:	1880                	addi	s0,sp,112
     782:	8a2a                	mv	s4,a0
     784:	8aae                	mv	s5,a1
    char *q, *eq;
    int tok, argc;
    struct execcmd *cmd;
    struct cmd *ret;

    if (peek(ps, es, "("))
     786:	00001617          	auipc	a2,0x1
     78a:	cba60613          	addi	a2,a2,-838 # 1440 <malloc+0x15e>
     78e:	00000097          	auipc	ra,0x0
     792:	e74080e7          	jalr	-396(ra) # 602 <peek>
     796:	e905                	bnez	a0,7c6 <parseexec+0x5e>
     798:	89aa                	mv	s3,a0
        return parseblock(ps, es);

    ret = execcmd();
     79a:	00000097          	auipc	ra,0x0
     79e:	bc6080e7          	jalr	-1082(ra) # 360 <execcmd>
     7a2:	8c2a                	mv	s8,a0
    cmd = (struct execcmd *)ret;

    argc = 0;
    ret = parseredirs(ret, ps, es);
     7a4:	8656                	mv	a2,s5
     7a6:	85d2                	mv	a1,s4
     7a8:	00000097          	auipc	ra,0x0
     7ac:	ec4080e7          	jalr	-316(ra) # 66c <parseredirs>
     7b0:	84aa                	mv	s1,a0
    while (!peek(ps, es, "|)&;"))
     7b2:	008c0913          	addi	s2,s8,8
     7b6:	00001b17          	auipc	s6,0x1
     7ba:	caab0b13          	addi	s6,s6,-854 # 1460 <malloc+0x17e>
    {
        if ((tok = gettoken(ps, es, &q, &eq)) == 0)
            break;
        if (tok != 'a')
     7be:	06100c93          	li	s9,97
            panic("syntax");
        cmd->argv[argc] = q;
        cmd->eargv[argc] = eq;
        argc++;
        if (argc >= MAXARGS)
     7c2:	4ba9                	li	s7,10
    while (!peek(ps, es, "|)&;"))
     7c4:	a0b1                	j	810 <parseexec+0xa8>
        return parseblock(ps, es);
     7c6:	85d6                	mv	a1,s5
     7c8:	8552                	mv	a0,s4
     7ca:	00000097          	auipc	ra,0x0
     7ce:	1bc080e7          	jalr	444(ra) # 986 <parseblock>
     7d2:	84aa                	mv	s1,a0
        ret = parseredirs(ret, ps, es);
    }
    cmd->argv[argc] = 0;
    cmd->eargv[argc] = 0;
    return ret;
}
     7d4:	8526                	mv	a0,s1
     7d6:	70a6                	ld	ra,104(sp)
     7d8:	7406                	ld	s0,96(sp)
     7da:	64e6                	ld	s1,88(sp)
     7dc:	6946                	ld	s2,80(sp)
     7de:	69a6                	ld	s3,72(sp)
     7e0:	6a06                	ld	s4,64(sp)
     7e2:	7ae2                	ld	s5,56(sp)
     7e4:	7b42                	ld	s6,48(sp)
     7e6:	7ba2                	ld	s7,40(sp)
     7e8:	7c02                	ld	s8,32(sp)
     7ea:	6ce2                	ld	s9,24(sp)
     7ec:	6165                	addi	sp,sp,112
     7ee:	8082                	ret
            panic("syntax");
     7f0:	00001517          	auipc	a0,0x1
     7f4:	c5850513          	addi	a0,a0,-936 # 1448 <malloc+0x166>
     7f8:	00000097          	auipc	ra,0x0
     7fc:	85c080e7          	jalr	-1956(ra) # 54 <panic>
        ret = parseredirs(ret, ps, es);
     800:	8656                	mv	a2,s5
     802:	85d2                	mv	a1,s4
     804:	8526                	mv	a0,s1
     806:	00000097          	auipc	ra,0x0
     80a:	e66080e7          	jalr	-410(ra) # 66c <parseredirs>
     80e:	84aa                	mv	s1,a0
    while (!peek(ps, es, "|)&;"))
     810:	865a                	mv	a2,s6
     812:	85d6                	mv	a1,s5
     814:	8552                	mv	a0,s4
     816:	00000097          	auipc	ra,0x0
     81a:	dec080e7          	jalr	-532(ra) # 602 <peek>
     81e:	e131                	bnez	a0,862 <parseexec+0xfa>
        if ((tok = gettoken(ps, es, &q, &eq)) == 0)
     820:	f9040693          	addi	a3,s0,-112
     824:	f9840613          	addi	a2,s0,-104
     828:	85d6                	mv	a1,s5
     82a:	8552                	mv	a0,s4
     82c:	00000097          	auipc	ra,0x0
     830:	c9a080e7          	jalr	-870(ra) # 4c6 <gettoken>
     834:	c51d                	beqz	a0,862 <parseexec+0xfa>
        if (tok != 'a')
     836:	fb951de3          	bne	a0,s9,7f0 <parseexec+0x88>
        cmd->argv[argc] = q;
     83a:	f9843783          	ld	a5,-104(s0)
     83e:	00f93023          	sd	a5,0(s2)
        cmd->eargv[argc] = eq;
     842:	f9043783          	ld	a5,-112(s0)
     846:	04f93823          	sd	a5,80(s2)
        argc++;
     84a:	2985                	addiw	s3,s3,1
        if (argc >= MAXARGS)
     84c:	0921                	addi	s2,s2,8
     84e:	fb7999e3          	bne	s3,s7,800 <parseexec+0x98>
            panic("too many args");
     852:	00001517          	auipc	a0,0x1
     856:	bfe50513          	addi	a0,a0,-1026 # 1450 <malloc+0x16e>
     85a:	fffff097          	auipc	ra,0xfffff
     85e:	7fa080e7          	jalr	2042(ra) # 54 <panic>
    cmd->argv[argc] = 0;
     862:	098e                	slli	s3,s3,0x3
     864:	99e2                	add	s3,s3,s8
     866:	0009b423          	sd	zero,8(s3)
    cmd->eargv[argc] = 0;
     86a:	0409bc23          	sd	zero,88(s3)
    return ret;
     86e:	b79d                	j	7d4 <parseexec+0x6c>

0000000000000870 <parsepipe>:
{
     870:	7179                	addi	sp,sp,-48
     872:	f406                	sd	ra,40(sp)
     874:	f022                	sd	s0,32(sp)
     876:	ec26                	sd	s1,24(sp)
     878:	e84a                	sd	s2,16(sp)
     87a:	e44e                	sd	s3,8(sp)
     87c:	1800                	addi	s0,sp,48
     87e:	892a                	mv	s2,a0
     880:	89ae                	mv	s3,a1
    cmd = parseexec(ps, es);
     882:	00000097          	auipc	ra,0x0
     886:	ee6080e7          	jalr	-282(ra) # 768 <parseexec>
     88a:	84aa                	mv	s1,a0
    if (peek(ps, es, "|"))
     88c:	00001617          	auipc	a2,0x1
     890:	bdc60613          	addi	a2,a2,-1060 # 1468 <malloc+0x186>
     894:	85ce                	mv	a1,s3
     896:	854a                	mv	a0,s2
     898:	00000097          	auipc	ra,0x0
     89c:	d6a080e7          	jalr	-662(ra) # 602 <peek>
     8a0:	e909                	bnez	a0,8b2 <parsepipe+0x42>
}
     8a2:	8526                	mv	a0,s1
     8a4:	70a2                	ld	ra,40(sp)
     8a6:	7402                	ld	s0,32(sp)
     8a8:	64e2                	ld	s1,24(sp)
     8aa:	6942                	ld	s2,16(sp)
     8ac:	69a2                	ld	s3,8(sp)
     8ae:	6145                	addi	sp,sp,48
     8b0:	8082                	ret
        gettoken(ps, es, 0, 0);
     8b2:	4681                	li	a3,0
     8b4:	4601                	li	a2,0
     8b6:	85ce                	mv	a1,s3
     8b8:	854a                	mv	a0,s2
     8ba:	00000097          	auipc	ra,0x0
     8be:	c0c080e7          	jalr	-1012(ra) # 4c6 <gettoken>
        cmd = pipecmd(cmd, parsepipe(ps, es));
     8c2:	85ce                	mv	a1,s3
     8c4:	854a                	mv	a0,s2
     8c6:	00000097          	auipc	ra,0x0
     8ca:	faa080e7          	jalr	-86(ra) # 870 <parsepipe>
     8ce:	85aa                	mv	a1,a0
     8d0:	8526                	mv	a0,s1
     8d2:	00000097          	auipc	ra,0x0
     8d6:	b2c080e7          	jalr	-1236(ra) # 3fe <pipecmd>
     8da:	84aa                	mv	s1,a0
    return cmd;
     8dc:	b7d9                	j	8a2 <parsepipe+0x32>

00000000000008de <parseline>:
{
     8de:	7179                	addi	sp,sp,-48
     8e0:	f406                	sd	ra,40(sp)
     8e2:	f022                	sd	s0,32(sp)
     8e4:	ec26                	sd	s1,24(sp)
     8e6:	e84a                	sd	s2,16(sp)
     8e8:	e44e                	sd	s3,8(sp)
     8ea:	e052                	sd	s4,0(sp)
     8ec:	1800                	addi	s0,sp,48
     8ee:	892a                	mv	s2,a0
     8f0:	89ae                	mv	s3,a1
    cmd = parsepipe(ps, es);
     8f2:	00000097          	auipc	ra,0x0
     8f6:	f7e080e7          	jalr	-130(ra) # 870 <parsepipe>
     8fa:	84aa                	mv	s1,a0
    while (peek(ps, es, "&"))
     8fc:	00001a17          	auipc	s4,0x1
     900:	b74a0a13          	addi	s4,s4,-1164 # 1470 <malloc+0x18e>
     904:	a839                	j	922 <parseline+0x44>
        gettoken(ps, es, 0, 0);
     906:	4681                	li	a3,0
     908:	4601                	li	a2,0
     90a:	85ce                	mv	a1,s3
     90c:	854a                	mv	a0,s2
     90e:	00000097          	auipc	ra,0x0
     912:	bb8080e7          	jalr	-1096(ra) # 4c6 <gettoken>
        cmd = backcmd(cmd);
     916:	8526                	mv	a0,s1
     918:	00000097          	auipc	ra,0x0
     91c:	b72080e7          	jalr	-1166(ra) # 48a <backcmd>
     920:	84aa                	mv	s1,a0
    while (peek(ps, es, "&"))
     922:	8652                	mv	a2,s4
     924:	85ce                	mv	a1,s3
     926:	854a                	mv	a0,s2
     928:	00000097          	auipc	ra,0x0
     92c:	cda080e7          	jalr	-806(ra) # 602 <peek>
     930:	f979                	bnez	a0,906 <parseline+0x28>
    if (peek(ps, es, ";"))
     932:	00001617          	auipc	a2,0x1
     936:	b4660613          	addi	a2,a2,-1210 # 1478 <malloc+0x196>
     93a:	85ce                	mv	a1,s3
     93c:	854a                	mv	a0,s2
     93e:	00000097          	auipc	ra,0x0
     942:	cc4080e7          	jalr	-828(ra) # 602 <peek>
     946:	e911                	bnez	a0,95a <parseline+0x7c>
}
     948:	8526                	mv	a0,s1
     94a:	70a2                	ld	ra,40(sp)
     94c:	7402                	ld	s0,32(sp)
     94e:	64e2                	ld	s1,24(sp)
     950:	6942                	ld	s2,16(sp)
     952:	69a2                	ld	s3,8(sp)
     954:	6a02                	ld	s4,0(sp)
     956:	6145                	addi	sp,sp,48
     958:	8082                	ret
        gettoken(ps, es, 0, 0);
     95a:	4681                	li	a3,0
     95c:	4601                	li	a2,0
     95e:	85ce                	mv	a1,s3
     960:	854a                	mv	a0,s2
     962:	00000097          	auipc	ra,0x0
     966:	b64080e7          	jalr	-1180(ra) # 4c6 <gettoken>
        cmd = listcmd(cmd, parseline(ps, es));
     96a:	85ce                	mv	a1,s3
     96c:	854a                	mv	a0,s2
     96e:	00000097          	auipc	ra,0x0
     972:	f70080e7          	jalr	-144(ra) # 8de <parseline>
     976:	85aa                	mv	a1,a0
     978:	8526                	mv	a0,s1
     97a:	00000097          	auipc	ra,0x0
     97e:	aca080e7          	jalr	-1334(ra) # 444 <listcmd>
     982:	84aa                	mv	s1,a0
    return cmd;
     984:	b7d1                	j	948 <parseline+0x6a>

0000000000000986 <parseblock>:
{
     986:	7179                	addi	sp,sp,-48
     988:	f406                	sd	ra,40(sp)
     98a:	f022                	sd	s0,32(sp)
     98c:	ec26                	sd	s1,24(sp)
     98e:	e84a                	sd	s2,16(sp)
     990:	e44e                	sd	s3,8(sp)
     992:	1800                	addi	s0,sp,48
     994:	84aa                	mv	s1,a0
     996:	892e                	mv	s2,a1
    if (!peek(ps, es, "("))
     998:	00001617          	auipc	a2,0x1
     99c:	aa860613          	addi	a2,a2,-1368 # 1440 <malloc+0x15e>
     9a0:	00000097          	auipc	ra,0x0
     9a4:	c62080e7          	jalr	-926(ra) # 602 <peek>
     9a8:	c12d                	beqz	a0,a0a <parseblock+0x84>
    gettoken(ps, es, 0, 0);
     9aa:	4681                	li	a3,0
     9ac:	4601                	li	a2,0
     9ae:	85ca                	mv	a1,s2
     9b0:	8526                	mv	a0,s1
     9b2:	00000097          	auipc	ra,0x0
     9b6:	b14080e7          	jalr	-1260(ra) # 4c6 <gettoken>
    cmd = parseline(ps, es);
     9ba:	85ca                	mv	a1,s2
     9bc:	8526                	mv	a0,s1
     9be:	00000097          	auipc	ra,0x0
     9c2:	f20080e7          	jalr	-224(ra) # 8de <parseline>
     9c6:	89aa                	mv	s3,a0
    if (!peek(ps, es, ")"))
     9c8:	00001617          	auipc	a2,0x1
     9cc:	ac860613          	addi	a2,a2,-1336 # 1490 <malloc+0x1ae>
     9d0:	85ca                	mv	a1,s2
     9d2:	8526                	mv	a0,s1
     9d4:	00000097          	auipc	ra,0x0
     9d8:	c2e080e7          	jalr	-978(ra) # 602 <peek>
     9dc:	cd1d                	beqz	a0,a1a <parseblock+0x94>
    gettoken(ps, es, 0, 0);
     9de:	4681                	li	a3,0
     9e0:	4601                	li	a2,0
     9e2:	85ca                	mv	a1,s2
     9e4:	8526                	mv	a0,s1
     9e6:	00000097          	auipc	ra,0x0
     9ea:	ae0080e7          	jalr	-1312(ra) # 4c6 <gettoken>
    cmd = parseredirs(cmd, ps, es);
     9ee:	864a                	mv	a2,s2
     9f0:	85a6                	mv	a1,s1
     9f2:	854e                	mv	a0,s3
     9f4:	00000097          	auipc	ra,0x0
     9f8:	c78080e7          	jalr	-904(ra) # 66c <parseredirs>
}
     9fc:	70a2                	ld	ra,40(sp)
     9fe:	7402                	ld	s0,32(sp)
     a00:	64e2                	ld	s1,24(sp)
     a02:	6942                	ld	s2,16(sp)
     a04:	69a2                	ld	s3,8(sp)
     a06:	6145                	addi	sp,sp,48
     a08:	8082                	ret
        panic("parseblock");
     a0a:	00001517          	auipc	a0,0x1
     a0e:	a7650513          	addi	a0,a0,-1418 # 1480 <malloc+0x19e>
     a12:	fffff097          	auipc	ra,0xfffff
     a16:	642080e7          	jalr	1602(ra) # 54 <panic>
        panic("syntax - missing )");
     a1a:	00001517          	auipc	a0,0x1
     a1e:	a7e50513          	addi	a0,a0,-1410 # 1498 <malloc+0x1b6>
     a22:	fffff097          	auipc	ra,0xfffff
     a26:	632080e7          	jalr	1586(ra) # 54 <panic>

0000000000000a2a <nulterminate>:

// NUL-terminate all the counted strings.
struct cmd *
nulterminate(struct cmd *cmd)
{
     a2a:	1101                	addi	sp,sp,-32
     a2c:	ec06                	sd	ra,24(sp)
     a2e:	e822                	sd	s0,16(sp)
     a30:	e426                	sd	s1,8(sp)
     a32:	1000                	addi	s0,sp,32
     a34:	84aa                	mv	s1,a0
    struct execcmd *ecmd;
    struct listcmd *lcmd;
    struct pipecmd *pcmd;
    struct redircmd *rcmd;

    if (cmd == 0)
     a36:	c521                	beqz	a0,a7e <nulterminate+0x54>
        return 0;

    switch (cmd->type)
     a38:	4118                	lw	a4,0(a0)
     a3a:	4795                	li	a5,5
     a3c:	04e7e163          	bltu	a5,a4,a7e <nulterminate+0x54>
     a40:	00056783          	lwu	a5,0(a0)
     a44:	078a                	slli	a5,a5,0x2
     a46:	00001717          	auipc	a4,0x1
     a4a:	ab270713          	addi	a4,a4,-1358 # 14f8 <malloc+0x216>
     a4e:	97ba                	add	a5,a5,a4
     a50:	439c                	lw	a5,0(a5)
     a52:	97ba                	add	a5,a5,a4
     a54:	8782                	jr	a5
    {
    case EXEC:
        ecmd = (struct execcmd *)cmd;
        for (i = 0; ecmd->argv[i]; i++)
     a56:	651c                	ld	a5,8(a0)
     a58:	c39d                	beqz	a5,a7e <nulterminate+0x54>
     a5a:	01050793          	addi	a5,a0,16
            *ecmd->eargv[i] = 0;
     a5e:	67b8                	ld	a4,72(a5)
     a60:	00070023          	sb	zero,0(a4)
        for (i = 0; ecmd->argv[i]; i++)
     a64:	07a1                	addi	a5,a5,8
     a66:	ff87b703          	ld	a4,-8(a5)
     a6a:	fb75                	bnez	a4,a5e <nulterminate+0x34>
     a6c:	a809                	j	a7e <nulterminate+0x54>
        break;

    case REDIR:
        rcmd = (struct redircmd *)cmd;
        nulterminate(rcmd->cmd);
     a6e:	6508                	ld	a0,8(a0)
     a70:	00000097          	auipc	ra,0x0
     a74:	fba080e7          	jalr	-70(ra) # a2a <nulterminate>
        *rcmd->efile = 0;
     a78:	6c9c                	ld	a5,24(s1)
     a7a:	00078023          	sb	zero,0(a5)
        bcmd = (struct backcmd *)cmd;
        nulterminate(bcmd->cmd);
        break;
    }
    return cmd;
}
     a7e:	8526                	mv	a0,s1
     a80:	60e2                	ld	ra,24(sp)
     a82:	6442                	ld	s0,16(sp)
     a84:	64a2                	ld	s1,8(sp)
     a86:	6105                	addi	sp,sp,32
     a88:	8082                	ret
        nulterminate(pcmd->left);
     a8a:	6508                	ld	a0,8(a0)
     a8c:	00000097          	auipc	ra,0x0
     a90:	f9e080e7          	jalr	-98(ra) # a2a <nulterminate>
        nulterminate(pcmd->right);
     a94:	6888                	ld	a0,16(s1)
     a96:	00000097          	auipc	ra,0x0
     a9a:	f94080e7          	jalr	-108(ra) # a2a <nulterminate>
        break;
     a9e:	b7c5                	j	a7e <nulterminate+0x54>
        nulterminate(lcmd->left);
     aa0:	6508                	ld	a0,8(a0)
     aa2:	00000097          	auipc	ra,0x0
     aa6:	f88080e7          	jalr	-120(ra) # a2a <nulterminate>
        nulterminate(lcmd->right);
     aaa:	6888                	ld	a0,16(s1)
     aac:	00000097          	auipc	ra,0x0
     ab0:	f7e080e7          	jalr	-130(ra) # a2a <nulterminate>
        break;
     ab4:	b7e9                	j	a7e <nulterminate+0x54>
        nulterminate(bcmd->cmd);
     ab6:	6508                	ld	a0,8(a0)
     ab8:	00000097          	auipc	ra,0x0
     abc:	f72080e7          	jalr	-142(ra) # a2a <nulterminate>
        break;
     ac0:	bf7d                	j	a7e <nulterminate+0x54>

0000000000000ac2 <parsecmd>:
{
     ac2:	7179                	addi	sp,sp,-48
     ac4:	f406                	sd	ra,40(sp)
     ac6:	f022                	sd	s0,32(sp)
     ac8:	ec26                	sd	s1,24(sp)
     aca:	e84a                	sd	s2,16(sp)
     acc:	1800                	addi	s0,sp,48
     ace:	fca43c23          	sd	a0,-40(s0)
    es = s + strlen(s);
     ad2:	84aa                	mv	s1,a0
     ad4:	00000097          	auipc	ra,0x0
     ad8:	1b2080e7          	jalr	434(ra) # c86 <strlen>
     adc:	1502                	slli	a0,a0,0x20
     ade:	9101                	srli	a0,a0,0x20
     ae0:	94aa                	add	s1,s1,a0
    cmd = parseline(&s, es);
     ae2:	85a6                	mv	a1,s1
     ae4:	fd840513          	addi	a0,s0,-40
     ae8:	00000097          	auipc	ra,0x0
     aec:	df6080e7          	jalr	-522(ra) # 8de <parseline>
     af0:	892a                	mv	s2,a0
    peek(&s, es, "");
     af2:	00001617          	auipc	a2,0x1
     af6:	9be60613          	addi	a2,a2,-1602 # 14b0 <malloc+0x1ce>
     afa:	85a6                	mv	a1,s1
     afc:	fd840513          	addi	a0,s0,-40
     b00:	00000097          	auipc	ra,0x0
     b04:	b02080e7          	jalr	-1278(ra) # 602 <peek>
    if (s != es)
     b08:	fd843603          	ld	a2,-40(s0)
     b0c:	00961e63          	bne	a2,s1,b28 <parsecmd+0x66>
    nulterminate(cmd);
     b10:	854a                	mv	a0,s2
     b12:	00000097          	auipc	ra,0x0
     b16:	f18080e7          	jalr	-232(ra) # a2a <nulterminate>
}
     b1a:	854a                	mv	a0,s2
     b1c:	70a2                	ld	ra,40(sp)
     b1e:	7402                	ld	s0,32(sp)
     b20:	64e2                	ld	s1,24(sp)
     b22:	6942                	ld	s2,16(sp)
     b24:	6145                	addi	sp,sp,48
     b26:	8082                	ret
        fprintf(2, "leftovers: %s\n", s);
     b28:	00001597          	auipc	a1,0x1
     b2c:	99058593          	addi	a1,a1,-1648 # 14b8 <malloc+0x1d6>
     b30:	4509                	li	a0,2
     b32:	00000097          	auipc	ra,0x0
     b36:	6c4080e7          	jalr	1732(ra) # 11f6 <fprintf>
        panic("syntax");
     b3a:	00001517          	auipc	a0,0x1
     b3e:	90e50513          	addi	a0,a0,-1778 # 1448 <malloc+0x166>
     b42:	fffff097          	auipc	ra,0xfffff
     b46:	512080e7          	jalr	1298(ra) # 54 <panic>

0000000000000b4a <main>:
{
     b4a:	7139                	addi	sp,sp,-64
     b4c:	fc06                	sd	ra,56(sp)
     b4e:	f822                	sd	s0,48(sp)
     b50:	f426                	sd	s1,40(sp)
     b52:	f04a                	sd	s2,32(sp)
     b54:	ec4e                	sd	s3,24(sp)
     b56:	e852                	sd	s4,16(sp)
     b58:	e456                	sd	s5,8(sp)
     b5a:	0080                	addi	s0,sp,64
    while ((fd = open("console", O_RDWR)) >= 0)
     b5c:	00001497          	auipc	s1,0x1
     b60:	96c48493          	addi	s1,s1,-1684 # 14c8 <malloc+0x1e6>
     b64:	4589                	li	a1,2
     b66:	8526                	mv	a0,s1
     b68:	00000097          	auipc	ra,0x0
     b6c:	384080e7          	jalr	900(ra) # eec <open>
     b70:	00054963          	bltz	a0,b82 <main+0x38>
        if (fd >= 3)
     b74:	4789                	li	a5,2
     b76:	fea7d7e3          	bge	a5,a0,b64 <main+0x1a>
            close(fd);
     b7a:	00000097          	auipc	ra,0x0
     b7e:	35a080e7          	jalr	858(ra) # ed4 <close>
    while (getcmd(buf, sizeof(buf)) >= 0)
     b82:	00001497          	auipc	s1,0x1
     b86:	9c648493          	addi	s1,s1,-1594 # 1548 <buf.0>
        if (buf[0] == 'c' && buf[1] == 'd' && buf[2] == ' ')
     b8a:	06300913          	li	s2,99
     b8e:	02000993          	li	s3,32
            if (chdir(buf + 3) < 0)
     b92:	00001a17          	auipc	s4,0x1
     b96:	9b9a0a13          	addi	s4,s4,-1607 # 154b <buf.0+0x3>
                fprintf(2, "cannot cd %s\n", buf + 3);
     b9a:	00001a97          	auipc	s5,0x1
     b9e:	936a8a93          	addi	s5,s5,-1738 # 14d0 <malloc+0x1ee>
     ba2:	a819                	j	bb8 <main+0x6e>
        if (fork1() == 0)
     ba4:	fffff097          	auipc	ra,0xfffff
     ba8:	4d6080e7          	jalr	1238(ra) # 7a <fork1>
     bac:	c925                	beqz	a0,c1c <main+0xd2>
        wait(0);
     bae:	4501                	li	a0,0
     bb0:	00000097          	auipc	ra,0x0
     bb4:	304080e7          	jalr	772(ra) # eb4 <wait>
    while (getcmd(buf, sizeof(buf)) >= 0)
     bb8:	06400593          	li	a1,100
     bbc:	8526                	mv	a0,s1
     bbe:	fffff097          	auipc	ra,0xfffff
     bc2:	442080e7          	jalr	1090(ra) # 0 <getcmd>
     bc6:	06054763          	bltz	a0,c34 <main+0xea>
        if (buf[0] == 'c' && buf[1] == 'd' && buf[2] == ' ')
     bca:	0004c783          	lbu	a5,0(s1)
     bce:	fd279be3          	bne	a5,s2,ba4 <main+0x5a>
     bd2:	0014c703          	lbu	a4,1(s1)
     bd6:	06400793          	li	a5,100
     bda:	fcf715e3          	bne	a4,a5,ba4 <main+0x5a>
     bde:	0024c783          	lbu	a5,2(s1)
     be2:	fd3791e3          	bne	a5,s3,ba4 <main+0x5a>
            buf[strlen(buf) - 1] = 0; // chop \n
     be6:	8526                	mv	a0,s1
     be8:	00000097          	auipc	ra,0x0
     bec:	09e080e7          	jalr	158(ra) # c86 <strlen>
     bf0:	fff5079b          	addiw	a5,a0,-1
     bf4:	1782                	slli	a5,a5,0x20
     bf6:	9381                	srli	a5,a5,0x20
     bf8:	97a6                	add	a5,a5,s1
     bfa:	00078023          	sb	zero,0(a5)
            if (chdir(buf + 3) < 0)
     bfe:	8552                	mv	a0,s4
     c00:	00000097          	auipc	ra,0x0
     c04:	31c080e7          	jalr	796(ra) # f1c <chdir>
     c08:	fa0558e3          	bgez	a0,bb8 <main+0x6e>
                fprintf(2, "cannot cd %s\n", buf + 3);
     c0c:	8652                	mv	a2,s4
     c0e:	85d6                	mv	a1,s5
     c10:	4509                	li	a0,2
     c12:	00000097          	auipc	ra,0x0
     c16:	5e4080e7          	jalr	1508(ra) # 11f6 <fprintf>
     c1a:	bf79                	j	bb8 <main+0x6e>
            runcmd(parsecmd(buf));
     c1c:	00001517          	auipc	a0,0x1
     c20:	92c50513          	addi	a0,a0,-1748 # 1548 <buf.0>
     c24:	00000097          	auipc	ra,0x0
     c28:	e9e080e7          	jalr	-354(ra) # ac2 <parsecmd>
     c2c:	fffff097          	auipc	ra,0xfffff
     c30:	47c080e7          	jalr	1148(ra) # a8 <runcmd>
    exit(0);
     c34:	4501                	li	a0,0
     c36:	00000097          	auipc	ra,0x0
     c3a:	276080e7          	jalr	630(ra) # eac <exit>

0000000000000c3e <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
     c3e:	1141                	addi	sp,sp,-16
     c40:	e422                	sd	s0,8(sp)
     c42:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
     c44:	87aa                	mv	a5,a0
     c46:	0585                	addi	a1,a1,1
     c48:	0785                	addi	a5,a5,1
     c4a:	fff5c703          	lbu	a4,-1(a1)
     c4e:	fee78fa3          	sb	a4,-1(a5)
     c52:	fb75                	bnez	a4,c46 <strcpy+0x8>
    ;
  return os;
}
     c54:	6422                	ld	s0,8(sp)
     c56:	0141                	addi	sp,sp,16
     c58:	8082                	ret

0000000000000c5a <strcmp>:

int
strcmp(const char *p, const char *q)
{
     c5a:	1141                	addi	sp,sp,-16
     c5c:	e422                	sd	s0,8(sp)
     c5e:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
     c60:	00054783          	lbu	a5,0(a0)
     c64:	cb91                	beqz	a5,c78 <strcmp+0x1e>
     c66:	0005c703          	lbu	a4,0(a1)
     c6a:	00f71763          	bne	a4,a5,c78 <strcmp+0x1e>
    p++, q++;
     c6e:	0505                	addi	a0,a0,1
     c70:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
     c72:	00054783          	lbu	a5,0(a0)
     c76:	fbe5                	bnez	a5,c66 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
     c78:	0005c503          	lbu	a0,0(a1)
}
     c7c:	40a7853b          	subw	a0,a5,a0
     c80:	6422                	ld	s0,8(sp)
     c82:	0141                	addi	sp,sp,16
     c84:	8082                	ret

0000000000000c86 <strlen>:

uint
strlen(const char *s)
{
     c86:	1141                	addi	sp,sp,-16
     c88:	e422                	sd	s0,8(sp)
     c8a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
     c8c:	00054783          	lbu	a5,0(a0)
     c90:	cf91                	beqz	a5,cac <strlen+0x26>
     c92:	0505                	addi	a0,a0,1
     c94:	87aa                	mv	a5,a0
     c96:	4685                	li	a3,1
     c98:	9e89                	subw	a3,a3,a0
     c9a:	00f6853b          	addw	a0,a3,a5
     c9e:	0785                	addi	a5,a5,1
     ca0:	fff7c703          	lbu	a4,-1(a5)
     ca4:	fb7d                	bnez	a4,c9a <strlen+0x14>
    ;
  return n;
}
     ca6:	6422                	ld	s0,8(sp)
     ca8:	0141                	addi	sp,sp,16
     caa:	8082                	ret
  for(n = 0; s[n]; n++)
     cac:	4501                	li	a0,0
     cae:	bfe5                	j	ca6 <strlen+0x20>

0000000000000cb0 <memset>:

void*
memset(void *dst, int c, uint n)
{
     cb0:	1141                	addi	sp,sp,-16
     cb2:	e422                	sd	s0,8(sp)
     cb4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
     cb6:	ca19                	beqz	a2,ccc <memset+0x1c>
     cb8:	87aa                	mv	a5,a0
     cba:	1602                	slli	a2,a2,0x20
     cbc:	9201                	srli	a2,a2,0x20
     cbe:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
     cc2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
     cc6:	0785                	addi	a5,a5,1
     cc8:	fee79de3          	bne	a5,a4,cc2 <memset+0x12>
  }
  return dst;
}
     ccc:	6422                	ld	s0,8(sp)
     cce:	0141                	addi	sp,sp,16
     cd0:	8082                	ret

0000000000000cd2 <strchr>:

char*
strchr(const char *s, char c)
{
     cd2:	1141                	addi	sp,sp,-16
     cd4:	e422                	sd	s0,8(sp)
     cd6:	0800                	addi	s0,sp,16
  for(; *s; s++)
     cd8:	00054783          	lbu	a5,0(a0)
     cdc:	cb99                	beqz	a5,cf2 <strchr+0x20>
    if(*s == c)
     cde:	00f58763          	beq	a1,a5,cec <strchr+0x1a>
  for(; *s; s++)
     ce2:	0505                	addi	a0,a0,1
     ce4:	00054783          	lbu	a5,0(a0)
     ce8:	fbfd                	bnez	a5,cde <strchr+0xc>
      return (char*)s;
  return 0;
     cea:	4501                	li	a0,0
}
     cec:	6422                	ld	s0,8(sp)
     cee:	0141                	addi	sp,sp,16
     cf0:	8082                	ret
  return 0;
     cf2:	4501                	li	a0,0
     cf4:	bfe5                	j	cec <strchr+0x1a>

0000000000000cf6 <gets>:

char*
gets(char *buf, int max)
{
     cf6:	711d                	addi	sp,sp,-96
     cf8:	ec86                	sd	ra,88(sp)
     cfa:	e8a2                	sd	s0,80(sp)
     cfc:	e4a6                	sd	s1,72(sp)
     cfe:	e0ca                	sd	s2,64(sp)
     d00:	fc4e                	sd	s3,56(sp)
     d02:	f852                	sd	s4,48(sp)
     d04:	f456                	sd	s5,40(sp)
     d06:	f05a                	sd	s6,32(sp)
     d08:	ec5e                	sd	s7,24(sp)
     d0a:	1080                	addi	s0,sp,96
     d0c:	8baa                	mv	s7,a0
     d0e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
     d10:	892a                	mv	s2,a0
     d12:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
     d14:	4aa9                	li	s5,10
     d16:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
     d18:	89a6                	mv	s3,s1
     d1a:	2485                	addiw	s1,s1,1
     d1c:	0344d863          	bge	s1,s4,d4c <gets+0x56>
    cc = read(0, &c, 1);
     d20:	4605                	li	a2,1
     d22:	faf40593          	addi	a1,s0,-81
     d26:	4501                	li	a0,0
     d28:	00000097          	auipc	ra,0x0
     d2c:	19c080e7          	jalr	412(ra) # ec4 <read>
    if(cc < 1)
     d30:	00a05e63          	blez	a0,d4c <gets+0x56>
    buf[i++] = c;
     d34:	faf44783          	lbu	a5,-81(s0)
     d38:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
     d3c:	01578763          	beq	a5,s5,d4a <gets+0x54>
     d40:	0905                	addi	s2,s2,1
     d42:	fd679be3          	bne	a5,s6,d18 <gets+0x22>
  for(i=0; i+1 < max; ){
     d46:	89a6                	mv	s3,s1
     d48:	a011                	j	d4c <gets+0x56>
     d4a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
     d4c:	99de                	add	s3,s3,s7
     d4e:	00098023          	sb	zero,0(s3)
  return buf;
}
     d52:	855e                	mv	a0,s7
     d54:	60e6                	ld	ra,88(sp)
     d56:	6446                	ld	s0,80(sp)
     d58:	64a6                	ld	s1,72(sp)
     d5a:	6906                	ld	s2,64(sp)
     d5c:	79e2                	ld	s3,56(sp)
     d5e:	7a42                	ld	s4,48(sp)
     d60:	7aa2                	ld	s5,40(sp)
     d62:	7b02                	ld	s6,32(sp)
     d64:	6be2                	ld	s7,24(sp)
     d66:	6125                	addi	sp,sp,96
     d68:	8082                	ret

0000000000000d6a <stat>:

int
stat(const char *n, struct stat *st)
{
     d6a:	1101                	addi	sp,sp,-32
     d6c:	ec06                	sd	ra,24(sp)
     d6e:	e822                	sd	s0,16(sp)
     d70:	e426                	sd	s1,8(sp)
     d72:	e04a                	sd	s2,0(sp)
     d74:	1000                	addi	s0,sp,32
     d76:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
     d78:	4581                	li	a1,0
     d7a:	00000097          	auipc	ra,0x0
     d7e:	172080e7          	jalr	370(ra) # eec <open>
  if(fd < 0)
     d82:	02054563          	bltz	a0,dac <stat+0x42>
     d86:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
     d88:	85ca                	mv	a1,s2
     d8a:	00000097          	auipc	ra,0x0
     d8e:	17a080e7          	jalr	378(ra) # f04 <fstat>
     d92:	892a                	mv	s2,a0
  close(fd);
     d94:	8526                	mv	a0,s1
     d96:	00000097          	auipc	ra,0x0
     d9a:	13e080e7          	jalr	318(ra) # ed4 <close>
  return r;
}
     d9e:	854a                	mv	a0,s2
     da0:	60e2                	ld	ra,24(sp)
     da2:	6442                	ld	s0,16(sp)
     da4:	64a2                	ld	s1,8(sp)
     da6:	6902                	ld	s2,0(sp)
     da8:	6105                	addi	sp,sp,32
     daa:	8082                	ret
    return -1;
     dac:	597d                	li	s2,-1
     dae:	bfc5                	j	d9e <stat+0x34>

0000000000000db0 <atoi>:

int
atoi(const char *s)
{
     db0:	1141                	addi	sp,sp,-16
     db2:	e422                	sd	s0,8(sp)
     db4:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
     db6:	00054603          	lbu	a2,0(a0)
     dba:	fd06079b          	addiw	a5,a2,-48
     dbe:	0ff7f793          	andi	a5,a5,255
     dc2:	4725                	li	a4,9
     dc4:	02f76963          	bltu	a4,a5,df6 <atoi+0x46>
     dc8:	86aa                	mv	a3,a0
  n = 0;
     dca:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
     dcc:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
     dce:	0685                	addi	a3,a3,1
     dd0:	0025179b          	slliw	a5,a0,0x2
     dd4:	9fa9                	addw	a5,a5,a0
     dd6:	0017979b          	slliw	a5,a5,0x1
     dda:	9fb1                	addw	a5,a5,a2
     ddc:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
     de0:	0006c603          	lbu	a2,0(a3)
     de4:	fd06071b          	addiw	a4,a2,-48
     de8:	0ff77713          	andi	a4,a4,255
     dec:	fee5f1e3          	bgeu	a1,a4,dce <atoi+0x1e>
  return n;
}
     df0:	6422                	ld	s0,8(sp)
     df2:	0141                	addi	sp,sp,16
     df4:	8082                	ret
  n = 0;
     df6:	4501                	li	a0,0
     df8:	bfe5                	j	df0 <atoi+0x40>

0000000000000dfa <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
     dfa:	1141                	addi	sp,sp,-16
     dfc:	e422                	sd	s0,8(sp)
     dfe:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
     e00:	02b57463          	bgeu	a0,a1,e28 <memmove+0x2e>
    while(n-- > 0)
     e04:	00c05f63          	blez	a2,e22 <memmove+0x28>
     e08:	1602                	slli	a2,a2,0x20
     e0a:	9201                	srli	a2,a2,0x20
     e0c:	00c507b3          	add	a5,a0,a2
  dst = vdst;
     e10:	872a                	mv	a4,a0
      *dst++ = *src++;
     e12:	0585                	addi	a1,a1,1
     e14:	0705                	addi	a4,a4,1
     e16:	fff5c683          	lbu	a3,-1(a1)
     e1a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
     e1e:	fee79ae3          	bne	a5,a4,e12 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
     e22:	6422                	ld	s0,8(sp)
     e24:	0141                	addi	sp,sp,16
     e26:	8082                	ret
    dst += n;
     e28:	00c50733          	add	a4,a0,a2
    src += n;
     e2c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
     e2e:	fec05ae3          	blez	a2,e22 <memmove+0x28>
     e32:	fff6079b          	addiw	a5,a2,-1
     e36:	1782                	slli	a5,a5,0x20
     e38:	9381                	srli	a5,a5,0x20
     e3a:	fff7c793          	not	a5,a5
     e3e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
     e40:	15fd                	addi	a1,a1,-1
     e42:	177d                	addi	a4,a4,-1
     e44:	0005c683          	lbu	a3,0(a1)
     e48:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
     e4c:	fee79ae3          	bne	a5,a4,e40 <memmove+0x46>
     e50:	bfc9                	j	e22 <memmove+0x28>

0000000000000e52 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
     e52:	1141                	addi	sp,sp,-16
     e54:	e422                	sd	s0,8(sp)
     e56:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
     e58:	ca05                	beqz	a2,e88 <memcmp+0x36>
     e5a:	fff6069b          	addiw	a3,a2,-1
     e5e:	1682                	slli	a3,a3,0x20
     e60:	9281                	srli	a3,a3,0x20
     e62:	0685                	addi	a3,a3,1
     e64:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
     e66:	00054783          	lbu	a5,0(a0)
     e6a:	0005c703          	lbu	a4,0(a1)
     e6e:	00e79863          	bne	a5,a4,e7e <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
     e72:	0505                	addi	a0,a0,1
    p2++;
     e74:	0585                	addi	a1,a1,1
  while (n-- > 0) {
     e76:	fed518e3          	bne	a0,a3,e66 <memcmp+0x14>
  }
  return 0;
     e7a:	4501                	li	a0,0
     e7c:	a019                	j	e82 <memcmp+0x30>
      return *p1 - *p2;
     e7e:	40e7853b          	subw	a0,a5,a4
}
     e82:	6422                	ld	s0,8(sp)
     e84:	0141                	addi	sp,sp,16
     e86:	8082                	ret
  return 0;
     e88:	4501                	li	a0,0
     e8a:	bfe5                	j	e82 <memcmp+0x30>

0000000000000e8c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
     e8c:	1141                	addi	sp,sp,-16
     e8e:	e406                	sd	ra,8(sp)
     e90:	e022                	sd	s0,0(sp)
     e92:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
     e94:	00000097          	auipc	ra,0x0
     e98:	f66080e7          	jalr	-154(ra) # dfa <memmove>
}
     e9c:	60a2                	ld	ra,8(sp)
     e9e:	6402                	ld	s0,0(sp)
     ea0:	0141                	addi	sp,sp,16
     ea2:	8082                	ret

0000000000000ea4 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
     ea4:	4885                	li	a7,1
 ecall
     ea6:	00000073          	ecall
 ret
     eaa:	8082                	ret

0000000000000eac <exit>:
.global exit
exit:
 li a7, SYS_exit
     eac:	4889                	li	a7,2
 ecall
     eae:	00000073          	ecall
 ret
     eb2:	8082                	ret

0000000000000eb4 <wait>:
.global wait
wait:
 li a7, SYS_wait
     eb4:	488d                	li	a7,3
 ecall
     eb6:	00000073          	ecall
 ret
     eba:	8082                	ret

0000000000000ebc <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
     ebc:	4891                	li	a7,4
 ecall
     ebe:	00000073          	ecall
 ret
     ec2:	8082                	ret

0000000000000ec4 <read>:
.global read
read:
 li a7, SYS_read
     ec4:	4895                	li	a7,5
 ecall
     ec6:	00000073          	ecall
 ret
     eca:	8082                	ret

0000000000000ecc <write>:
.global write
write:
 li a7, SYS_write
     ecc:	48c1                	li	a7,16
 ecall
     ece:	00000073          	ecall
 ret
     ed2:	8082                	ret

0000000000000ed4 <close>:
.global close
close:
 li a7, SYS_close
     ed4:	48d5                	li	a7,21
 ecall
     ed6:	00000073          	ecall
 ret
     eda:	8082                	ret

0000000000000edc <kill>:
.global kill
kill:
 li a7, SYS_kill
     edc:	4899                	li	a7,6
 ecall
     ede:	00000073          	ecall
 ret
     ee2:	8082                	ret

0000000000000ee4 <exec>:
.global exec
exec:
 li a7, SYS_exec
     ee4:	489d                	li	a7,7
 ecall
     ee6:	00000073          	ecall
 ret
     eea:	8082                	ret

0000000000000eec <open>:
.global open
open:
 li a7, SYS_open
     eec:	48bd                	li	a7,15
 ecall
     eee:	00000073          	ecall
 ret
     ef2:	8082                	ret

0000000000000ef4 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
     ef4:	48c5                	li	a7,17
 ecall
     ef6:	00000073          	ecall
 ret
     efa:	8082                	ret

0000000000000efc <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
     efc:	48c9                	li	a7,18
 ecall
     efe:	00000073          	ecall
 ret
     f02:	8082                	ret

0000000000000f04 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
     f04:	48a1                	li	a7,8
 ecall
     f06:	00000073          	ecall
 ret
     f0a:	8082                	ret

0000000000000f0c <link>:
.global link
link:
 li a7, SYS_link
     f0c:	48cd                	li	a7,19
 ecall
     f0e:	00000073          	ecall
 ret
     f12:	8082                	ret

0000000000000f14 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
     f14:	48d1                	li	a7,20
 ecall
     f16:	00000073          	ecall
 ret
     f1a:	8082                	ret

0000000000000f1c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
     f1c:	48a5                	li	a7,9
 ecall
     f1e:	00000073          	ecall
 ret
     f22:	8082                	ret

0000000000000f24 <dup>:
.global dup
dup:
 li a7, SYS_dup
     f24:	48a9                	li	a7,10
 ecall
     f26:	00000073          	ecall
 ret
     f2a:	8082                	ret

0000000000000f2c <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
     f2c:	48ad                	li	a7,11
 ecall
     f2e:	00000073          	ecall
 ret
     f32:	8082                	ret

0000000000000f34 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
     f34:	48b1                	li	a7,12
 ecall
     f36:	00000073          	ecall
 ret
     f3a:	8082                	ret

0000000000000f3c <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
     f3c:	48b5                	li	a7,13
 ecall
     f3e:	00000073          	ecall
 ret
     f42:	8082                	ret

0000000000000f44 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
     f44:	48b9                	li	a7,14
 ecall
     f46:	00000073          	ecall
 ret
     f4a:	8082                	ret

0000000000000f4c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
     f4c:	1101                	addi	sp,sp,-32
     f4e:	ec06                	sd	ra,24(sp)
     f50:	e822                	sd	s0,16(sp)
     f52:	1000                	addi	s0,sp,32
     f54:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
     f58:	4605                	li	a2,1
     f5a:	fef40593          	addi	a1,s0,-17
     f5e:	00000097          	auipc	ra,0x0
     f62:	f6e080e7          	jalr	-146(ra) # ecc <write>
}
     f66:	60e2                	ld	ra,24(sp)
     f68:	6442                	ld	s0,16(sp)
     f6a:	6105                	addi	sp,sp,32
     f6c:	8082                	ret

0000000000000f6e <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
     f6e:	7139                	addi	sp,sp,-64
     f70:	fc06                	sd	ra,56(sp)
     f72:	f822                	sd	s0,48(sp)
     f74:	f426                	sd	s1,40(sp)
     f76:	f04a                	sd	s2,32(sp)
     f78:	ec4e                	sd	s3,24(sp)
     f7a:	0080                	addi	s0,sp,64
     f7c:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
     f7e:	c299                	beqz	a3,f84 <printint+0x16>
     f80:	0805c863          	bltz	a1,1010 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
     f84:	2581                	sext.w	a1,a1
  neg = 0;
     f86:	4881                	li	a7,0
     f88:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
     f8c:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
     f8e:	2601                	sext.w	a2,a2
     f90:	00000517          	auipc	a0,0x0
     f94:	58850513          	addi	a0,a0,1416 # 1518 <digits>
     f98:	883a                	mv	a6,a4
     f9a:	2705                	addiw	a4,a4,1
     f9c:	02c5f7bb          	remuw	a5,a1,a2
     fa0:	1782                	slli	a5,a5,0x20
     fa2:	9381                	srli	a5,a5,0x20
     fa4:	97aa                	add	a5,a5,a0
     fa6:	0007c783          	lbu	a5,0(a5)
     faa:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
     fae:	0005879b          	sext.w	a5,a1
     fb2:	02c5d5bb          	divuw	a1,a1,a2
     fb6:	0685                	addi	a3,a3,1
     fb8:	fec7f0e3          	bgeu	a5,a2,f98 <printint+0x2a>
  if(neg)
     fbc:	00088b63          	beqz	a7,fd2 <printint+0x64>
    buf[i++] = '-';
     fc0:	fd040793          	addi	a5,s0,-48
     fc4:	973e                	add	a4,a4,a5
     fc6:	02d00793          	li	a5,45
     fca:	fef70823          	sb	a5,-16(a4)
     fce:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
     fd2:	02e05863          	blez	a4,1002 <printint+0x94>
     fd6:	fc040793          	addi	a5,s0,-64
     fda:	00e78933          	add	s2,a5,a4
     fde:	fff78993          	addi	s3,a5,-1
     fe2:	99ba                	add	s3,s3,a4
     fe4:	377d                	addiw	a4,a4,-1
     fe6:	1702                	slli	a4,a4,0x20
     fe8:	9301                	srli	a4,a4,0x20
     fea:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
     fee:	fff94583          	lbu	a1,-1(s2)
     ff2:	8526                	mv	a0,s1
     ff4:	00000097          	auipc	ra,0x0
     ff8:	f58080e7          	jalr	-168(ra) # f4c <putc>
  while(--i >= 0)
     ffc:	197d                	addi	s2,s2,-1
     ffe:	ff3918e3          	bne	s2,s3,fee <printint+0x80>
}
    1002:	70e2                	ld	ra,56(sp)
    1004:	7442                	ld	s0,48(sp)
    1006:	74a2                	ld	s1,40(sp)
    1008:	7902                	ld	s2,32(sp)
    100a:	69e2                	ld	s3,24(sp)
    100c:	6121                	addi	sp,sp,64
    100e:	8082                	ret
    x = -xx;
    1010:	40b005bb          	negw	a1,a1
    neg = 1;
    1014:	4885                	li	a7,1
    x = -xx;
    1016:	bf8d                	j	f88 <printint+0x1a>

0000000000001018 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
    1018:	7119                	addi	sp,sp,-128
    101a:	fc86                	sd	ra,120(sp)
    101c:	f8a2                	sd	s0,112(sp)
    101e:	f4a6                	sd	s1,104(sp)
    1020:	f0ca                	sd	s2,96(sp)
    1022:	ecce                	sd	s3,88(sp)
    1024:	e8d2                	sd	s4,80(sp)
    1026:	e4d6                	sd	s5,72(sp)
    1028:	e0da                	sd	s6,64(sp)
    102a:	fc5e                	sd	s7,56(sp)
    102c:	f862                	sd	s8,48(sp)
    102e:	f466                	sd	s9,40(sp)
    1030:	f06a                	sd	s10,32(sp)
    1032:	ec6e                	sd	s11,24(sp)
    1034:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
    1036:	0005c903          	lbu	s2,0(a1)
    103a:	18090f63          	beqz	s2,11d8 <vprintf+0x1c0>
    103e:	8aaa                	mv	s5,a0
    1040:	8b32                	mv	s6,a2
    1042:	00158493          	addi	s1,a1,1
  state = 0;
    1046:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
    1048:	02500a13          	li	s4,37
      if(c == 'd'){
    104c:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
    1050:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
    1054:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
    1058:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    105c:	00000b97          	auipc	s7,0x0
    1060:	4bcb8b93          	addi	s7,s7,1212 # 1518 <digits>
    1064:	a839                	j	1082 <vprintf+0x6a>
        putc(fd, c);
    1066:	85ca                	mv	a1,s2
    1068:	8556                	mv	a0,s5
    106a:	00000097          	auipc	ra,0x0
    106e:	ee2080e7          	jalr	-286(ra) # f4c <putc>
    1072:	a019                	j	1078 <vprintf+0x60>
    } else if(state == '%'){
    1074:	01498f63          	beq	s3,s4,1092 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
    1078:	0485                	addi	s1,s1,1
    107a:	fff4c903          	lbu	s2,-1(s1)
    107e:	14090d63          	beqz	s2,11d8 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
    1082:	0009079b          	sext.w	a5,s2
    if(state == 0){
    1086:	fe0997e3          	bnez	s3,1074 <vprintf+0x5c>
      if(c == '%'){
    108a:	fd479ee3          	bne	a5,s4,1066 <vprintf+0x4e>
        state = '%';
    108e:	89be                	mv	s3,a5
    1090:	b7e5                	j	1078 <vprintf+0x60>
      if(c == 'd'){
    1092:	05878063          	beq	a5,s8,10d2 <vprintf+0xba>
      } else if(c == 'l') {
    1096:	05978c63          	beq	a5,s9,10ee <vprintf+0xd6>
      } else if(c == 'x') {
    109a:	07a78863          	beq	a5,s10,110a <vprintf+0xf2>
      } else if(c == 'p') {
    109e:	09b78463          	beq	a5,s11,1126 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
    10a2:	07300713          	li	a4,115
    10a6:	0ce78663          	beq	a5,a4,1172 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
    10aa:	06300713          	li	a4,99
    10ae:	0ee78e63          	beq	a5,a4,11aa <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
    10b2:	11478863          	beq	a5,s4,11c2 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
    10b6:	85d2                	mv	a1,s4
    10b8:	8556                	mv	a0,s5
    10ba:	00000097          	auipc	ra,0x0
    10be:	e92080e7          	jalr	-366(ra) # f4c <putc>
        putc(fd, c);
    10c2:	85ca                	mv	a1,s2
    10c4:	8556                	mv	a0,s5
    10c6:	00000097          	auipc	ra,0x0
    10ca:	e86080e7          	jalr	-378(ra) # f4c <putc>
      }
      state = 0;
    10ce:	4981                	li	s3,0
    10d0:	b765                	j	1078 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
    10d2:	008b0913          	addi	s2,s6,8
    10d6:	4685                	li	a3,1
    10d8:	4629                	li	a2,10
    10da:	000b2583          	lw	a1,0(s6)
    10de:	8556                	mv	a0,s5
    10e0:	00000097          	auipc	ra,0x0
    10e4:	e8e080e7          	jalr	-370(ra) # f6e <printint>
    10e8:	8b4a                	mv	s6,s2
      state = 0;
    10ea:	4981                	li	s3,0
    10ec:	b771                	j	1078 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
    10ee:	008b0913          	addi	s2,s6,8
    10f2:	4681                	li	a3,0
    10f4:	4629                	li	a2,10
    10f6:	000b2583          	lw	a1,0(s6)
    10fa:	8556                	mv	a0,s5
    10fc:	00000097          	auipc	ra,0x0
    1100:	e72080e7          	jalr	-398(ra) # f6e <printint>
    1104:	8b4a                	mv	s6,s2
      state = 0;
    1106:	4981                	li	s3,0
    1108:	bf85                	j	1078 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
    110a:	008b0913          	addi	s2,s6,8
    110e:	4681                	li	a3,0
    1110:	4641                	li	a2,16
    1112:	000b2583          	lw	a1,0(s6)
    1116:	8556                	mv	a0,s5
    1118:	00000097          	auipc	ra,0x0
    111c:	e56080e7          	jalr	-426(ra) # f6e <printint>
    1120:	8b4a                	mv	s6,s2
      state = 0;
    1122:	4981                	li	s3,0
    1124:	bf91                	j	1078 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
    1126:	008b0793          	addi	a5,s6,8
    112a:	f8f43423          	sd	a5,-120(s0)
    112e:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
    1132:	03000593          	li	a1,48
    1136:	8556                	mv	a0,s5
    1138:	00000097          	auipc	ra,0x0
    113c:	e14080e7          	jalr	-492(ra) # f4c <putc>
  putc(fd, 'x');
    1140:	85ea                	mv	a1,s10
    1142:	8556                	mv	a0,s5
    1144:	00000097          	auipc	ra,0x0
    1148:	e08080e7          	jalr	-504(ra) # f4c <putc>
    114c:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    114e:	03c9d793          	srli	a5,s3,0x3c
    1152:	97de                	add	a5,a5,s7
    1154:	0007c583          	lbu	a1,0(a5)
    1158:	8556                	mv	a0,s5
    115a:	00000097          	auipc	ra,0x0
    115e:	df2080e7          	jalr	-526(ra) # f4c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    1162:	0992                	slli	s3,s3,0x4
    1164:	397d                	addiw	s2,s2,-1
    1166:	fe0914e3          	bnez	s2,114e <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
    116a:	f8843b03          	ld	s6,-120(s0)
      state = 0;
    116e:	4981                	li	s3,0
    1170:	b721                	j	1078 <vprintf+0x60>
        s = va_arg(ap, char*);
    1172:	008b0993          	addi	s3,s6,8
    1176:	000b3903          	ld	s2,0(s6)
        if(s == 0)
    117a:	02090163          	beqz	s2,119c <vprintf+0x184>
        while(*s != 0){
    117e:	00094583          	lbu	a1,0(s2)
    1182:	c9a1                	beqz	a1,11d2 <vprintf+0x1ba>
          putc(fd, *s);
    1184:	8556                	mv	a0,s5
    1186:	00000097          	auipc	ra,0x0
    118a:	dc6080e7          	jalr	-570(ra) # f4c <putc>
          s++;
    118e:	0905                	addi	s2,s2,1
        while(*s != 0){
    1190:	00094583          	lbu	a1,0(s2)
    1194:	f9e5                	bnez	a1,1184 <vprintf+0x16c>
        s = va_arg(ap, char*);
    1196:	8b4e                	mv	s6,s3
      state = 0;
    1198:	4981                	li	s3,0
    119a:	bdf9                	j	1078 <vprintf+0x60>
          s = "(null)";
    119c:	00000917          	auipc	s2,0x0
    11a0:	37490913          	addi	s2,s2,884 # 1510 <malloc+0x22e>
        while(*s != 0){
    11a4:	02800593          	li	a1,40
    11a8:	bff1                	j	1184 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
    11aa:	008b0913          	addi	s2,s6,8
    11ae:	000b4583          	lbu	a1,0(s6)
    11b2:	8556                	mv	a0,s5
    11b4:	00000097          	auipc	ra,0x0
    11b8:	d98080e7          	jalr	-616(ra) # f4c <putc>
    11bc:	8b4a                	mv	s6,s2
      state = 0;
    11be:	4981                	li	s3,0
    11c0:	bd65                	j	1078 <vprintf+0x60>
        putc(fd, c);
    11c2:	85d2                	mv	a1,s4
    11c4:	8556                	mv	a0,s5
    11c6:	00000097          	auipc	ra,0x0
    11ca:	d86080e7          	jalr	-634(ra) # f4c <putc>
      state = 0;
    11ce:	4981                	li	s3,0
    11d0:	b565                	j	1078 <vprintf+0x60>
        s = va_arg(ap, char*);
    11d2:	8b4e                	mv	s6,s3
      state = 0;
    11d4:	4981                	li	s3,0
    11d6:	b54d                	j	1078 <vprintf+0x60>
    }
  }
}
    11d8:	70e6                	ld	ra,120(sp)
    11da:	7446                	ld	s0,112(sp)
    11dc:	74a6                	ld	s1,104(sp)
    11de:	7906                	ld	s2,96(sp)
    11e0:	69e6                	ld	s3,88(sp)
    11e2:	6a46                	ld	s4,80(sp)
    11e4:	6aa6                	ld	s5,72(sp)
    11e6:	6b06                	ld	s6,64(sp)
    11e8:	7be2                	ld	s7,56(sp)
    11ea:	7c42                	ld	s8,48(sp)
    11ec:	7ca2                	ld	s9,40(sp)
    11ee:	7d02                	ld	s10,32(sp)
    11f0:	6de2                	ld	s11,24(sp)
    11f2:	6109                	addi	sp,sp,128
    11f4:	8082                	ret

00000000000011f6 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
    11f6:	715d                	addi	sp,sp,-80
    11f8:	ec06                	sd	ra,24(sp)
    11fa:	e822                	sd	s0,16(sp)
    11fc:	1000                	addi	s0,sp,32
    11fe:	e010                	sd	a2,0(s0)
    1200:	e414                	sd	a3,8(s0)
    1202:	e818                	sd	a4,16(s0)
    1204:	ec1c                	sd	a5,24(s0)
    1206:	03043023          	sd	a6,32(s0)
    120a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
    120e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
    1212:	8622                	mv	a2,s0
    1214:	00000097          	auipc	ra,0x0
    1218:	e04080e7          	jalr	-508(ra) # 1018 <vprintf>
}
    121c:	60e2                	ld	ra,24(sp)
    121e:	6442                	ld	s0,16(sp)
    1220:	6161                	addi	sp,sp,80
    1222:	8082                	ret

0000000000001224 <printf>:

void
printf(const char *fmt, ...)
{
    1224:	711d                	addi	sp,sp,-96
    1226:	ec06                	sd	ra,24(sp)
    1228:	e822                	sd	s0,16(sp)
    122a:	1000                	addi	s0,sp,32
    122c:	e40c                	sd	a1,8(s0)
    122e:	e810                	sd	a2,16(s0)
    1230:	ec14                	sd	a3,24(s0)
    1232:	f018                	sd	a4,32(s0)
    1234:	f41c                	sd	a5,40(s0)
    1236:	03043823          	sd	a6,48(s0)
    123a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
    123e:	00840613          	addi	a2,s0,8
    1242:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
    1246:	85aa                	mv	a1,a0
    1248:	4505                	li	a0,1
    124a:	00000097          	auipc	ra,0x0
    124e:	dce080e7          	jalr	-562(ra) # 1018 <vprintf>
}
    1252:	60e2                	ld	ra,24(sp)
    1254:	6442                	ld	s0,16(sp)
    1256:	6125                	addi	sp,sp,96
    1258:	8082                	ret

000000000000125a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
    125a:	1141                	addi	sp,sp,-16
    125c:	e422                	sd	s0,8(sp)
    125e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
    1260:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    1264:	00000797          	auipc	a5,0x0
    1268:	2dc7b783          	ld	a5,732(a5) # 1540 <freep>
    126c:	a805                	j	129c <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
    126e:	4618                	lw	a4,8(a2)
    1270:	9db9                	addw	a1,a1,a4
    1272:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
    1276:	6398                	ld	a4,0(a5)
    1278:	6318                	ld	a4,0(a4)
    127a:	fee53823          	sd	a4,-16(a0)
    127e:	a091                	j	12c2 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
    1280:	ff852703          	lw	a4,-8(a0)
    1284:	9e39                	addw	a2,a2,a4
    1286:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
    1288:	ff053703          	ld	a4,-16(a0)
    128c:	e398                	sd	a4,0(a5)
    128e:	a099                	j	12d4 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    1290:	6398                	ld	a4,0(a5)
    1292:	00e7e463          	bltu	a5,a4,129a <free+0x40>
    1296:	00e6ea63          	bltu	a3,a4,12aa <free+0x50>
{
    129a:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    129c:	fed7fae3          	bgeu	a5,a3,1290 <free+0x36>
    12a0:	6398                	ld	a4,0(a5)
    12a2:	00e6e463          	bltu	a3,a4,12aa <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    12a6:	fee7eae3          	bltu	a5,a4,129a <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
    12aa:	ff852583          	lw	a1,-8(a0)
    12ae:	6390                	ld	a2,0(a5)
    12b0:	02059813          	slli	a6,a1,0x20
    12b4:	01c85713          	srli	a4,a6,0x1c
    12b8:	9736                	add	a4,a4,a3
    12ba:	fae60ae3          	beq	a2,a4,126e <free+0x14>
    bp->s.ptr = p->s.ptr;
    12be:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
    12c2:	4790                	lw	a2,8(a5)
    12c4:	02061593          	slli	a1,a2,0x20
    12c8:	01c5d713          	srli	a4,a1,0x1c
    12cc:	973e                	add	a4,a4,a5
    12ce:	fae689e3          	beq	a3,a4,1280 <free+0x26>
  } else
    p->s.ptr = bp;
    12d2:	e394                	sd	a3,0(a5)
  freep = p;
    12d4:	00000717          	auipc	a4,0x0
    12d8:	26f73623          	sd	a5,620(a4) # 1540 <freep>
}
    12dc:	6422                	ld	s0,8(sp)
    12de:	0141                	addi	sp,sp,16
    12e0:	8082                	ret

00000000000012e2 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
    12e2:	7139                	addi	sp,sp,-64
    12e4:	fc06                	sd	ra,56(sp)
    12e6:	f822                	sd	s0,48(sp)
    12e8:	f426                	sd	s1,40(sp)
    12ea:	f04a                	sd	s2,32(sp)
    12ec:	ec4e                	sd	s3,24(sp)
    12ee:	e852                	sd	s4,16(sp)
    12f0:	e456                	sd	s5,8(sp)
    12f2:	e05a                	sd	s6,0(sp)
    12f4:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
    12f6:	02051493          	slli	s1,a0,0x20
    12fa:	9081                	srli	s1,s1,0x20
    12fc:	04bd                	addi	s1,s1,15
    12fe:	8091                	srli	s1,s1,0x4
    1300:	0014899b          	addiw	s3,s1,1
    1304:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
    1306:	00000517          	auipc	a0,0x0
    130a:	23a53503          	ld	a0,570(a0) # 1540 <freep>
    130e:	c515                	beqz	a0,133a <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    1310:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    1312:	4798                	lw	a4,8(a5)
    1314:	02977f63          	bgeu	a4,s1,1352 <malloc+0x70>
    1318:	8a4e                	mv	s4,s3
    131a:	0009871b          	sext.w	a4,s3
    131e:	6685                	lui	a3,0x1
    1320:	00d77363          	bgeu	a4,a3,1326 <malloc+0x44>
    1324:	6a05                	lui	s4,0x1
    1326:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
    132a:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
    132e:	00000917          	auipc	s2,0x0
    1332:	21290913          	addi	s2,s2,530 # 1540 <freep>
  if(p == (char*)-1)
    1336:	5afd                	li	s5,-1
    1338:	a895                	j	13ac <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
    133a:	00000797          	auipc	a5,0x0
    133e:	27678793          	addi	a5,a5,630 # 15b0 <base>
    1342:	00000717          	auipc	a4,0x0
    1346:	1ef73f23          	sd	a5,510(a4) # 1540 <freep>
    134a:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
    134c:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
    1350:	b7e1                	j	1318 <malloc+0x36>
      if(p->s.size == nunits)
    1352:	02e48c63          	beq	s1,a4,138a <malloc+0xa8>
        p->s.size -= nunits;
    1356:	4137073b          	subw	a4,a4,s3
    135a:	c798                	sw	a4,8(a5)
        p += p->s.size;
    135c:	02071693          	slli	a3,a4,0x20
    1360:	01c6d713          	srli	a4,a3,0x1c
    1364:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
    1366:	0137a423          	sw	s3,8(a5)
      freep = prevp;
    136a:	00000717          	auipc	a4,0x0
    136e:	1ca73b23          	sd	a0,470(a4) # 1540 <freep>
      return (void*)(p + 1);
    1372:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
    1376:	70e2                	ld	ra,56(sp)
    1378:	7442                	ld	s0,48(sp)
    137a:	74a2                	ld	s1,40(sp)
    137c:	7902                	ld	s2,32(sp)
    137e:	69e2                	ld	s3,24(sp)
    1380:	6a42                	ld	s4,16(sp)
    1382:	6aa2                	ld	s5,8(sp)
    1384:	6b02                	ld	s6,0(sp)
    1386:	6121                	addi	sp,sp,64
    1388:	8082                	ret
        prevp->s.ptr = p->s.ptr;
    138a:	6398                	ld	a4,0(a5)
    138c:	e118                	sd	a4,0(a0)
    138e:	bff1                	j	136a <malloc+0x88>
  hp->s.size = nu;
    1390:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
    1394:	0541                	addi	a0,a0,16
    1396:	00000097          	auipc	ra,0x0
    139a:	ec4080e7          	jalr	-316(ra) # 125a <free>
  return freep;
    139e:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
    13a2:	d971                	beqz	a0,1376 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    13a4:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    13a6:	4798                	lw	a4,8(a5)
    13a8:	fa9775e3          	bgeu	a4,s1,1352 <malloc+0x70>
    if(p == freep)
    13ac:	00093703          	ld	a4,0(s2)
    13b0:	853e                	mv	a0,a5
    13b2:	fef719e3          	bne	a4,a5,13a4 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
    13b6:	8552                	mv	a0,s4
    13b8:	00000097          	auipc	ra,0x0
    13bc:	b7c080e7          	jalr	-1156(ra) # f34 <sbrk>
  if(p == (char*)-1)
    13c0:	fd5518e3          	bne	a0,s5,1390 <malloc+0xae>
        return 0;
    13c4:	4501                	li	a0,0
    13c6:	bf45                	j	1376 <malloc+0x94>
