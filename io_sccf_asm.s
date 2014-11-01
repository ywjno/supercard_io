    .TEXT
@support Super card cf
@--------------------------------sd data--------------------------------

.equ use_dma,0

.equ cfstatns,0x99c0000
.equ cfaddressbase,0x9000000
.GLOBAL sccf_ReadSector,sccf_WriteSector,sccf_InitSCMode,sccf_MemoryCard_IsInserted
@extern "C" void sccf_ReadSector(u16 *buff,u32 sector,u8 ReadNumber);
@extern "C" void sccf_WriteSector (u16 *buff,u32 sector,u8 writeNumber);
@extern "C" void sccf_InitSCMode (void);
@extern "C" bool sccf_MemoryCard_IsInserted(void);

@---------------------------void CFCommand(u8 command,u8 num,u32 sector )--------------------
		.ALIGN
@		.GLOBAL	 CFCommand @ r0:Srcp r1:num ok
		.CODE 32
@void CFCommand(u8 command,u8 num,u32 sector )
@{
@	register u32 tempaddr;
@	while (((*(u8*)cfstatns)&0xc0)!=0x40);
@	tempaddr=cfaddressbase;
@	tempaddr+=0x40000;
@	*(u16*)tempaddr=num;
@	tempaddr+=0x20000;
@	*(u16*)tempaddr=(sector);
@	tempaddr+=0x20000;
@	*(u16*)tempaddr=(sector>>8);
@	tempaddr+=0x20000;
@	*(u16*)tempaddr=(sector>>16);
@	tempaddr+=0x20000;
@	*(u16*)tempaddr=((u8)(sector>>24)+0xe0);
@	tempaddr+=0x20000;
@	*(u16*)tempaddr=command;
@
@}
CFCommand:
	stmfd   r13!,{r4-r5}
	ldr	r4,=cfstatns	
CFCommand_loop10:
	ldrh	r5,[r4]
	and	r5,r5,#0xc0
	cmp	r5,#0x40
	bne	CFCommand_loop10

	ldr	r4,=cfaddressbase
	add	r4,r4,#0x40000
	strh	r1,[r4]

	add	r4,r4,#0x20000
	strh	r2,[r4]

	mov	r2,r2,lsr #8
	add	r4,r4,#0x20000
	strh	r2,[r4]

	mov	r2,r2,lsr #8
	add	r4,r4,#0x20000
	strh	r2,[r4]

	mov	r2,r2,lsr #8
	add	r2,r2,#0xe0
	add	r4,r4,#0x20000
	strh	r2,[r4]

	add	r4,r4,#0x20000
	strh	r0,[r4]
	ldmfd	r13!,{r4-r5}
	bx	r14
@-------------------------end CFCommand-------------------


@----------void ReadSector(u16 *buff,u32 sector,u8 readnum)-------------
		.ALIGN
@		.GLOBAL	 sccf_ReadSector @ r0:Srcp r1:num ok
		.CODE 32

@void ReadSector(u16 *buff,u32 sector,u8 readnum)
@{
@	register u16 i,j;
@	CFCommand(0x20,readnum,sector);
@	Wait(0x10);
@	i=readnum;
@	for (j=0;j<i ; j++)
@	{
@		while (((*(u16*)cfstatns)&0x88)==0x80);
@		loaddata(0x9000000,(u32)buff+j*512,512);
@	}
@
@}
sccf_ReadSector:
	stmfd   r13!,{r4-r6,r14}

	mov	r4,r0
	mov	r5,r2
    mov r6,r1
    bl sccf_InitSCMode
	mov	r2,r6
	mov	r0,#0x20
	mov	r1,r5
	bl	CFCommand
	mov	r0,#0x10
	bl	Wait
	mov	r6,#0
beginforj_ReadSector:
	cmp	r6,r5
	bge	endforj_ReadSector
	ldr	r0,=cfstatns
whileloop_ReadSector:
	ldrh	r1,[r0]
	and	r1,r1,#0x88
	cmp	r1,#0x80
	beq	whileloop_ReadSector
	mov	r0,#0x9000000
	mov	r1,r4
	add	r1,r1,r6,lsl #9 
	mov	r2,#512
	bl	loaddata
	add	r6,r6,#1
	b	beginforj_ReadSector
endforj_ReadSector:
	mov	r0,#1
	ldmfd   r13!,{r4-r6,r14}
	bx	r14
@----------end ReadSector-------------


@------------void Wait(u32 num)----------------------------
		.ALIGN
		.CODE 32
Wait:
beginwhile_Wait:
	subs	r0,r0,#1
	bne	beginwhile_Wait
	bx	r14
@------------end Wait----------------------------

@---------------void WriteSector(u16 *buff,u32 sector,u8 writenum)---------------------
		.ALIGN
@		.GLOBAL	 sccf_WriteSector @ r0:Srcp r1:num ok
		.CODE 32

@void WriteSector(u16 *buff,u32 sector,u8 writenum)
@{
@	register u16 i,j;
@
@	CFCommand(0x30,writenum,sector);
@	Wait(0x10);
@	i=writenum;
@	for (j=0;j<i ; j++)
@	{
@		while (((*(u16*)cfstatns)&0x88)==0x80);
@		loaddata((u32)buff+j*512,0x9000000,512);
@	}
@	while ((((*(u16*)cfstatns)&0x80)!=0));
@}
@
sccf_WriteSector:
	stmfd   r13!,{r4-r6,r14}
	mov	r4,r0
	mov	r5,r2
    mov r6,r1
    bl sccf_InitSCMode

	mov	r2,r6
	mov	r0,#0x30
	mov	r1,r5
	bl	CFCommand
	mov	r0,#0x10
	bl	Wait
	mov	r6,#0
beginforj_WriteSector:
	cmp	r6,r5
	bge	endforj_WriteSector
	ldr	r0,=cfstatns
whileloop_WriteSector:
	ldrh	r1,[r0]
	and	r1,r1,#0x88
	cmp	r1,#0x80
	beq	whileloop_WriteSector
	mov	r1,#0x9000000
	mov	r0,r4
	add	r0,r0,r6,lsl #9 
	mov	r2,#512
	bl	loaddata
	add	r6,r6,#1
	b	beginforj_WriteSector
endforj_WriteSector:
	ldr	r0,=cfstatns
whileloop2_WriteSector:
	ldrh	r1,[r0]
	ands	r1,r1,#0x80
	bne	whileloop2_WriteSector
	mov	r0,#1
	ldmfd   r13!,{r4-r6,r14}
	bx	r14
@---------------end WriteSector---------------------

@----------------void sccf_InitSCMode(void)---------------
		.ALIGN
@		.GLOBAL	 sccf_InitSCMode
		.CODE 32
sccf_InitSCMode:
	mvn     r0,#0x0F6000000 
	sub     r0,r0,#0x01
	mov     r1,#0x0A500
	add     r1,r1,#0x5A
	strh    r1,[r0]
	strh    r1,[r0]
	mov	r2,#3
	strh    r2,[r0]
	strh    r2,[r0]
	bx	r14
@----------------end InitSCMode ---------------

@----------------bool sccf_MemoryCard_IsInserted(void)---------------
		.ALIGN
@		.GLOBAL	 sccf_MemoryCard_IsInserted
		.CODE 32
sccf_MemoryCard_IsInserted:
	ldr	r0,=cfstatns
	mov	r1,#0x50
	strh	r1,[r0]
	nop
	ldrb	r2,[r0]
	cmp	r2,r1
	moveq	r0,#1
	movne	r0,#0
	bx	r14
@----------------end MemoryCard_IsInserted---------------
@-------------void loaddata(u16* s,u16* d,u32 num)------------
		.ALIGN
		.CODE 32
loaddata:
.if !use_dma
	add	r2,r1,r2
loaddata_loop:
	cmp	r1,r2
	ldrcch	r3,[r0],#2
	strcch	r3,[r1],#2
	bcc	loaddata_loop
	bx	r14
.else
	mov	r3,#0x4000000
	str	r0,[r3,#0xd4]
	str	r1,[r3,#0xd8]
	mov	r0,#0x80000000
	add	r0,r0,r2,lsr #1
	str	r0,[r3,#0xdc]
dma_l_loop:
	ldr	r3,[r4,#0xdc]  
    tst r3,#0x80000000
    bne dma_l_loop
	bx	r14

.endif
@-------------end loaddata------------




   .END






