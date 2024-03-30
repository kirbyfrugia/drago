//tm.s

//tilemap constants, not
//safe to use these memory
//locations outside.

//constants needing defined
//scrrow0 1st row on screen visible
//scrcol0 1st col on screen visible 
//scrwidth
//scrheight

//!!! WARN do not change the !!!
//!!! order of these vars.   !!!
//!!! They are a struct:     !!!
//!!! *ptr ptr to run data   !!!
//!!! *b   byte at run index !!!
//!!! *rl  run length        !!!
//!!! *bl  bytes left        !!!
//character tilemap
.var chrptr = $43 //and $44
.var chrb   = $45
.var chrrl  = $46
.var chrbl  = $47
//metadata tilemap
.var mdptr  = $48 //and $49
.var mdrb   = $4a
.var mdrl   = $4b
.var mdbl   = $4c
//temp tilemap used by routines
.var tmrptr = $4d //and $4e
.var tmrb   = $4f
.var tmrl   = $50
.var tmbl   = $51

.var scrptr  = $52 //and $53
.var clrptr  = $3f //and $40

.var corow    = $54
.var tmvar0   = $55
.var cused    = $56
//WARN $59-$60 used by editor 

// tilemap viewer
// INIT
//   make sure screen info is set
//     row0,col0,width,height
//
// API
//
// DATA
//
//   render info
//     tmrow0 1 byte,1st visible
//            row on screen
//     tmcol0 2 bytes,1st visible
//            column on screen
//
//   tilemap data structure:
//     (0,1)   run ptr
//     (2,3)   last run ptr
//     (4,5)   col count
//   * all 16bit nums lo byte first

// modifies A and Y
.macro NextRun(runptr) {
  lda runptr
  clc
  adc #2
  sta runptr
  bcc nrd
  inc runptr+1
nrd:
  ReadRun(runptr)
}

// // modifies A and Y
// // @P1 run ptr
// PREVR2 MACRO
//   lda @P1
//   sec
//   sbc #2
//   sta @P1
//   bcs pr2d@$MC
//   dec @P1+1
// pr2d@$MC
//   ReadRun(@P1)
//   ENDM

// modifies A and Y
.macro ReadRun(runptr) {
  ldy #0
  lda (runptr),Y
  sta runptr+3
  sec
  sbc #1
  sta runptr+4
  iny
  lda (runptr),Y
  sta runptr+2
}

// call when num rows or cols change
updscrn:
  lda tmrowc
  sec
  sbc #scrheight
  sta maxrow0

  lda tmcolc
  sec
  sbc #scrwidth
  sta maxcol0
  lda tmcolc+1
  sbc #0
  sta maxcol0+1

  lda tmcol0
  sta offsetlo
  lda tmcol0+1
  sta offsethi

  ldx #0
usil:
  cpx tmrow0
  beq usild
  lda offsetlo
  clc
  adc tmcolc
  sta offsetlo
  lda offsethi
  adc tmcolc+1
  sta offsethi
  inx
  jmp usil
usild:
  pha
  lda offsetlo
  pha

  lda chrtmrun0
  sta tmrptr
  lda chrtmrun0+1
  sta tmrptr+1
  ReadRun(tmrptr)

  ldx #0
uscl:
  jsr seek2
  lda tmrptr
  sta crunlo,X
  lda tmrptr+1
  sta crunhi,X
  lda tmbl
  sta crunrem,X
  sta $7900  

  inx
  cpx #scrheight
  beq uscld

  lda tmcolc
  sta offsetlo
  lda tmcolc+1
  sta offsethi
  jmp uscl
uscld:

  pla
  sta offsetlo
  pla
  sta offsethi 

  lda mdtmrun0
  sta tmrptr
  lda mdtmrun0+1
  sta tmrptr+1
  ReadRun(tmrptr)
  ldx #0
usmdl:
  jsr seek2
  lda tmrptr
  sta mdrunlo,X
  lda tmrptr+1
  sta mdrunhi,X
  lda tmbl
  sta mdrunrem,X

  inx
  cpx #scrheight
  beq usmdld

  lda tmcolc
  sta offsetlo
  lda tmcolc+1
  sta offsethi
  jmp usmdl
usmdld:

  lda #scrcol0
  sta scrptr
  sta clrptr
  lda #$04
  sta scrptr+1
  lda #$d8
  sta clrptr+1

  ldx #0
usirl:
  cpx #scrrow0
  beq usirld
  inx
  lda scrptr
  clc
  adc #40
  sta scrptr
  sta clrptr
  bcc usirl
  inc scrptr+1
  inc clrptr+1
  bcs usirl
usirld:
  lda scrptr
  sta scrptr0
  lda scrptr+1
  sta scrptr0+1
  lda clrptr
  sta clrptr0
  lda clrptr+1
  sta clrptr0+1

  rts

// draws full tilemap to the screen
drawscrn:
  pha
  txa
  pha
  tya
  pha

  lda scrptr0
  sta scrptr
  lda scrptr0+1
  sta scrptr+1
  lda clrptr0
  sta clrptr
  lda clrptr0+1
  sta clrptr+1

  ldx #0   
dsl:
  lda crunlo,X
  sta chrptr
  lda crunhi,X
  sta chrptr+1
  ReadRun(chrptr)
  lda crunrem,X
  sta chrbl

  lda mdrunlo,X
  sta mdptr
  lda mdrunhi,X
  sta mdptr+1
  ReadRun(mdptr)
  lda mdrunrem,X
  sta mdbl

  ldy #0
dsol:
  //READB chrptr,tmvar0
  lda chrb
  sta (scrptr),Y

  //READB mdptr,tmvar0
  lda mdrb
  //AND #%00001111
  sta (clrptr),Y

  iny
  cpy #scrwidth
  beq dsold

  lda chrbl
  bne dsoljdc
  sty tmvar0
  NextRun(chrptr)
  ldy tmvar0
  jmp dsoldmd
dsoljdc:
  dec chrbl
dsoldmd:
  lda mdbl
  bne dsoljdm
  sty tmvar0
  NextRun(mdptr)
  ldy tmvar0
  jmp dsol
dsoljdm:
  dec mdbl
  jmp dsol
dsold:

  inx
  cpx #scrheight
  beq dsd

  lda scrptr
  clc
  adc #40
  sta scrptr
  sta clrptr
  bcc dsln
  inc scrptr+1
  inc clrptr+1
dsln:
  jmp dsl 
dsd:
  pla
  tax 
  pla
  tay
  pla 
  rts

//move map right if possible
mvmr:
  lda tmcol0
  bne mvmrt
  lda tmcol0+1
  bne mvmrt
  jmp mvmrd 
mvmrt:
  lda scrptr0
  sta scrptr
  lda scrptr0+1
  sta scrptr+1
  lda clrptr0
  sta clrptr
  lda clrptr0+1
  sta clrptr+1
  ldx #0
mvmrtl:
  lda #0
  sta cused

  lda crunlo,X
  sta chrptr
  lda crunhi,X
  sta chrptr+1

  lda crunrem,X
  clc
  adc #1
  ldy #0
  cmp (chrptr),Y
  beq mvmrchpr
  sta crunrem,X
  jmp mvmrtchl
mvmrchpr:
  lda chrptr
  sec
  sbc #2
  sta chrptr
  sta crunlo,X
  lda chrptr+1
  sbc #0
  sta chrptr+1
  sta crunhi,X
  lda #0
  sta crunrem,X
mvmrtchl:
  clc
  adc cused
  bcs mvmrtchld
  cmp #scrwidth
  bcs mvmrtchld
  sta cused

  ldy #1
  lda (chrptr),Y
  ldy cused
  sta (scrptr),Y

  lda chrptr
  clc
  adc #2
  sta chrptr
  lda chrptr+1
  adc #0
  sta chrptr+1
  ldy #0
  lda (chrptr),Y
  jmp mvmrtchl 
mvmrtchld:
  lda #0
  sta cused

  lda mdrunlo,X
  sta mdptr
  lda mdrunhi,X
  sta mdptr+1

  lda mdrunrem,X
  clc
  adc #1
  ldy #0
  cmp (mdptr),Y
  beq mvmrmdpr
  sta mdrunrem,X
  jmp mvmrtmdl
mvmrmdpr:
  lda mdptr
  sec
  sbc #2
  sta mdptr
  sta mdrunlo,X
  lda mdptr+1
  sbc #0
  sta mdptr+1
  sta mdrunhi,X
  lda #0
  sta mdrunrem,X
mvmrtmdl:
  clc
  adc cused
  bcs mvmrtmdld
  cmp #scrwidth
  bcs mvmrtmdld
  sta cused

  ldy #1
  lda (mdptr),Y
  ldy cused
  sta (clrptr),Y

  lda mdptr
  clc
  adc #2
  sta mdptr
  lda mdptr+1
  adc #0
  sta mdptr+1
  ldy #0
  lda (mdptr),Y
  jmp mvmrtmdl 
mvmrtmdld:
  inx
  cpx #scrheight
  beq mvmrtd

  lda scrptr
  clc
  adc #40
  sta scrptr
  sta clrptr
  bcc mvmrtn
  inc scrptr+1
  inc clrptr+1
mvmrtn:
  jmp mvmrtl
mvmrtd:
  lda tmcol0
  sec
  sbc #1
  sta tmcol0
  lda tmcol0+1
  sbc #0
  sta tmcol0+1 
mvmrd:
  rts

// move map left if possible
mvml:
  lda tmcol0+1
  cmp maxcol0+1
  bcc mvmlt
  lda tmcol0
  cmp maxcol0
  bcc mvmlt
  jmp mvmld
mvmlt:
  lda scrptr0
  sta scrptr
  lda scrptr0+1
  sta scrptr+1
  lda clrptr0
  sta clrptr
  lda clrptr0+1
  sta clrptr+1
  ldx #0
mvmltl:
  lda #0
  sta cused

  lda crunlo,X
  sta chrptr
  lda crunhi,X
  sta chrptr+1

  lda crunrem,X
  beq mvmlnchr
  dec crunrem,X
  // keep original crunrem in A
  jmp mvmltchl
mvmlnchr:
  NextRun(chrptr)
  lda chrptr
  sta crunlo,X
  lda chrptr+1
  sta crunhi,X
  ldy #0
  lda chrb
  sta (scrptr),Y
  lda chrbl
  sta crunrem,X
  clc
  adc #1
mvmltchl:
  clc
  adc cused
  bcs mvmltchld
  cmp #scrwidth
  bcs mvmltchld
  sta cused

  lda chrptr
  clc
  adc #2
  sta chrptr
  lda chrptr+1
  adc #0
  sta chrptr+1
  ldy #1
  lda (chrptr),Y
  ldy cused
  sta (scrptr),Y
  ldy #0
  lda (chrptr),Y
  jmp mvmltchl 
mvmltchld:
  lda #0
  sta cused

  lda mdrunlo,X
  sta mdptr
  lda mdrunhi,X
  sta mdptr+1

  lda mdrunrem,X
  beq mvmlnmdr
  dec mdrunrem,X
  // keep original crunrem in A
  jmp mvmltmdl
mvmlnmdr:
  NextRun(mdptr)
  lda mdptr
  sta mdrunlo,X
  lda mdptr+1
  sta mdrunhi,X
  ldy #0
  lda mdrb
  sta (clrptr),Y
  lda mdbl
  sta mdrunrem,X
  clc
  adc #1
mvmltmdl:
  clc
  adc cused
  bcs mvmltmdld
  cmp #scrwidth
  bcs mvmltmdld
  sta cused

  lda mdptr
  clc
  adc #2
  sta mdptr
  lda mdptr+1
  adc #0
  sta mdptr+1
  ldy #1
  lda (mdptr),Y
  ldy cused
  sta (clrptr),Y
  ldy #0
  lda (mdptr),Y
  jmp mvmltmdl 
mvmltmdld:
  inx
  cpx #scrheight
  beq mvmltd

  lda scrptr
  clc
  adc #40
  sta scrptr
  sta clrptr
  bcc mvmltn
  inc scrptr+1
  inc clrptr+1
mvmltn:
  jmp mvmltl
mvmltd:
  lda tmcol0
  clc
  adc #1
  sta tmcol0
  lda tmcol0+1
  adc #0
  sta tmcol0+1
mvmld:
  rts

// move map up if possible
mvmu:
  lda tmrow0
  bne mvmut
  beq mvmud 
mvmut:
  lda tmrow0
  sec
  sbc #1
  sta tmrow0 
mvmud:
  // todo optimize
  jsr updscrn
  rts

mvmd:
  lda tmrow0
  cmp maxrow0
  bcc mvmdt
  bcs mvmdd
mvmdt:
  lda tmrow0 
  clc
  adc #1
  sta tmrow0
mvmdd:
  // todo optimize
  jsr updscrn
  rts

// outputs
//   offsetlo/hi the number of 
//   characters from zpb2/3
//   for the given row and column 
// inputs
//   tmcol0/+1 the column
//   tmrow0    the row
calcoffset:
  pha
 
  lda tmcol
  sta offsetlo
  lda tmcol+1
  sta offsethi

  lda tmrow
  sta corow
corcl:
  lda corow
  bne corcln
  beq corcld
corcln:
  lda offsetlo
  clc
  adc tmcolc
  sta offsetlo
  lda offsethi
  adc tmcolc+1
  sta offsethi
  
  lda corow
  sec
  sbc #1
  sta corow
  jmp corcl
corcld:
  pla
  rts

seek2:
  pha
  tya
  pha
s2ol:
  lda offsetlo
  bne s2l
  lda offsethi
  bne s2l
  beq s2d
s2l:
  // runlen <=255, so offsethi
  // being >0 means we know we use
  // this whole run
  lda offsethi
  bne s2lnr
  lda offsetlo
  sec
  sbc tmbl
  beq s2lao
  bcs s2lnr
  // offset < tmbl
  lda tmbl
  sec
  sbc offsetlo
  sta tmbl
  bne s2d
s2lao:
  // at offset, at end of run
  sta tmbl
  beq s2d
s2lnr:
  // offset > tmbl
  // subtract 1 from offset since we
  // will be consuming a byte to get to
  // the next run
  lda offsetlo
  sec
  sbc #1
  sta offsetlo
  bcs s2lnw1
  dec offsethi
s2lnw1:
  lda offsetlo
  sec
  sbc tmbl
  sta offsetlo
  bcs s2lnw2
  dec offsethi
s2lnw2:
  NextRun(tmrptr)
  jmp s2ol
s2d:
  pla
  tay
  pla
  rts


// API vars
tmrow0:     .byte 0
tmcol0:     .byte 0,0
tmcolc:     .byte 0,0
tmrowc:     .byte 0

// internal vars
offsetlo:   .byte 0
offsethi:   .byte 0
maxrow0:    .byte 0
maxcol0:    .byte 0,0

// ptrs to upper left of screen
scrptr0:    .byte 0,0
clrptr0:    .byte 0,0

// these two tables are indexes into the
// tile maps, based on screen row/col.
crunlo:    .fill scrheight,0
crunhi:    .fill scrheight,0
crunrem:   .fill scrheight,0

mdrunlo:   .fill scrheight,0
mdrunhi:   .fill scrheight,0
mdrunrem:  .fill scrheight,0

