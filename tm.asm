//tm.s

//tilemap constants, not safe to use these memory locations outside.

//!!! WARN do not change the  order of these vars. !!!
//!!! They are a struct:                           !!!
//!!!   *ptr ptr to run data (2 bytes)             !!!
//!!!   *b   byte at run index                     !!!
//!!!   *rl  run length                            !!!
//!!!   *bl  bytes left                             !!!
//character tilemap
.var TM_chrtm_ptr = $43 //and $44
.var TM_chrtm_char   = $45
.var TM_chrtm_run_length  = $46
.var TM_chrtm_bytes_remaining  = $47
//metadata tilemap
.var TM_mdtm_ptr  = $48 //and $49
.var TM_mdtm_char   = $4a
.var TM_mdtm_run_length   = $4b
.var TM_mdtm_bytes_remaining   = $4c
//temp tilemap used by routines
.var TM_tmptm_ptr = $4d //and $4e
.var TM_tmptm_char   = $4f
.var TM_tmptm_run_length   = $50
.var TM_tmptm_bytes_remaining   = $51

.var scrptr  = $52 //and $53
.var clrptr  = $3f //and $40

.var tmvar0       = $54
.var cused        = $55
.var scrollx      = $56
.var scrollreg    = $57
.var scrolloffset = $58
.var mapmoved     = $59
//WARN $5a-$60 used by editor 

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
  sta TM_tmptm_ptr
  lda chrtmrun0+1
  sta TM_tmptm_ptr+1
  ReadRun(TM_tmptm_ptr)

  ldx #0
uscl:
  jsr seek2
  lda TM_tmptm_ptr
  sta crunlo,X
  lda TM_tmptm_ptr+1
  sta crunhi,X
  lda TM_tmptm_bytes_remaining
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
  sta TM_tmptm_ptr
  lda mdtmrun0+1
  sta TM_tmptm_ptr+1
  ReadRun(TM_tmptm_ptr)
  ldx #0
usmdl:
  jsr seek2
  lda TM_tmptm_ptr
  sta mdrunlo,X
  lda TM_tmptm_ptr+1
  sta mdrunhi,X
  lda TM_tmptm_bytes_remaining
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
  sta TM_chrtm_ptr
  lda crunhi,X
  sta TM_chrtm_ptr+1
  ReadRun(TM_chrtm_ptr)
  lda crunrem,X
  sta TM_chrtm_bytes_remaining

  lda mdrunlo,X
  sta TM_mdtm_ptr
  lda mdrunhi,X
  sta TM_mdtm_ptr+1
  ReadRun(TM_mdtm_ptr)
  lda mdrunrem,X
  sta TM_mdtm_bytes_remaining

  ldy #0
dsol:
  //READB TM_chrtm_ptr,tmvar0
  lda TM_chrtm_char
  sta (scrptr),Y

  //READB TM_mdtm_ptr,tmvar0
  lda TM_mdtm_char
  //AND #%00001111
  sta (clrptr),Y

  iny
  cpy #scrwidth
  beq dsold

  lda TM_chrtm_bytes_remaining
  bne dsoljdc
  sty tmvar0
  NextRun(TM_chrtm_ptr)
  ldy tmvar0
  jmp dsoldmd
dsoljdc:
  dec TM_chrtm_bytes_remaining
dsoldmd:
  lda TM_mdtm_bytes_remaining
  bne dsoljdm
  sty tmvar0
  NextRun(TM_mdtm_ptr)
  ldy tmvar0
  jmp dsol
dsoljdm:
  dec TM_mdtm_bytes_remaining
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

// affects A,X,Y
// inputs:
//   scrollx - the amount to scroll
// outputs:
//   scrollx - the amount actually scrolled
scrolll:
  ldx scrollx
  lda #0
  sta scrollx
  cpx #0
  beq sld
sll:
  lda scrolloffset
  clc
  adc #1
  cmp #8
  beq slredraw
  sta scrolloffset
  dec scrollreg
  lda $d016
  and #%11110000
  ora scrollreg
  sta $d016
  jmp slln
slredraw:  
  lda tmcol0+1
  cmp maxcol0+1
  bcc slredrawok
  lda tmcol0
  cmp maxcol0
  bcc slredrawok
  bcs sld
slredrawok:
  lda #0
  sta scrolloffset
  lda #%00000111
  sta scrollreg
  lda $d016
  ora #%00000111
  sta $d016

  stx tmvar0
  jsr mvmlt
  ldx tmvar0
slln:
  inc scrollx
  dex
  bne sll
sld:
  rts

// affects A,X,Y
// inputs:
//   scrollx - the amount to scroll
// outputs:
//   scrollx - the amount actually scrolled
scrollr:
  ldx scrollx
  lda #0
  sta scrollx
  cpx #0
  beq sld
srl:
  lda scrolloffset
  sec
  sbc #1
  bmi srredraw
  sta scrolloffset
  inc scrollreg
  lda $d016
  and #%11110000
  ora scrollreg
  sta $d016
  jmp srln
srredraw:  
  lda tmcol0
  bne srredrawok
  lda tmcol0+1
  bne srredrawok
  beq srd
srredrawok:
  lda #7
  sta scrolloffset
  lda #%00000000
  sta scrollreg
  lda $d016
  and #%11111000
  sta $d016

  stx tmvar0
  jsr mvmrt
  ldx tmvar0
srln:
  inc scrollx
  dex
  bne srl
srd:
  rts

//move map right if possible
mvmr:
  lda tmcol0
  bne mvmrt
  lda tmcol0+1
  bne mvmrt
  lda #1
  sta mapmoved
  jmp mvmrd 
mvmrt:
  lda #0
  sta mapmoved
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
  sta TM_chrtm_ptr
  lda crunhi,X
  sta TM_chrtm_ptr+1

  lda crunrem,X
  clc
  adc #1
  ldy #0
  cmp (TM_chrtm_ptr),Y
  beq mvmrchpr
  sta crunrem,X
  jmp mvmrtchl
mvmrchpr:
  lda TM_chrtm_ptr
  sec
  sbc #2
  sta TM_chrtm_ptr
  sta crunlo,X
  lda TM_chrtm_ptr+1
  sbc #0
  sta TM_chrtm_ptr+1
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
  lda (TM_chrtm_ptr),Y
  ldy cused
  sta (scrptr),Y

  lda TM_chrtm_ptr
  clc
  adc #2
  sta TM_chrtm_ptr
  lda TM_chrtm_ptr+1
  adc #0
  sta TM_chrtm_ptr+1
  ldy #0
  lda (TM_chrtm_ptr),Y
  jmp mvmrtchl 
mvmrtchld:
  lda #0
  sta cused

  lda mdrunlo,X
  sta TM_mdtm_ptr
  lda mdrunhi,X
  sta TM_mdtm_ptr+1

  lda mdrunrem,X
  clc
  adc #1
  ldy #0
  cmp (TM_mdtm_ptr),Y
  beq mvmrmdpr
  sta mdrunrem,X
  jmp mvmrtmdl
mvmrmdpr:
  lda TM_mdtm_ptr
  sec
  sbc #2
  sta TM_mdtm_ptr
  sta mdrunlo,X
  lda TM_mdtm_ptr+1
  sbc #0
  sta TM_mdtm_ptr+1
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
  lda (TM_mdtm_ptr),Y
  ldy cused
  sta (clrptr),Y

  lda TM_mdtm_ptr
  clc
  adc #2
  sta TM_mdtm_ptr
  lda TM_mdtm_ptr+1
  adc #0
  sta TM_mdtm_ptr+1
  ldy #0
  lda (TM_mdtm_ptr),Y
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
  lda #1
  sta mapmoved
  jmp mvmld
mvmlt:
  lda #0
  sta mapmoved
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
  sta TM_chrtm_ptr
  lda crunhi,X
  sta TM_chrtm_ptr+1

  lda crunrem,X
  beq mvmlnchr
  dec crunrem,X
  // keep original crunrem in A
  jmp mvmltchl
mvmlnchr:
  NextRun(TM_chrtm_ptr)
  lda TM_chrtm_ptr
  sta crunlo,X
  lda TM_chrtm_ptr+1
  sta crunhi,X
  ldy #0
  lda TM_chrtm_char
  sta (scrptr),Y
  lda TM_chrtm_bytes_remaining
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

  lda TM_chrtm_ptr
  clc
  adc #2
  sta TM_chrtm_ptr
  lda TM_chrtm_ptr+1
  adc #0
  sta TM_chrtm_ptr+1
  ldy #1
  lda (TM_chrtm_ptr),Y
  ldy cused
  sta (scrptr),Y
  ldy #0
  lda (TM_chrtm_ptr),Y
  jmp mvmltchl 
mvmltchld:
  lda #0
  sta cused

  lda mdrunlo,X
  sta TM_mdtm_ptr
  lda mdrunhi,X
  sta TM_mdtm_ptr+1

  lda mdrunrem,X
  beq mvmlnmdr
  dec mdrunrem,X
  // keep original crunrem in A
  jmp mvmltmdl
mvmlnmdr:
  NextRun(TM_mdtm_ptr)
  lda TM_mdtm_ptr
  sta mdrunlo,X
  lda TM_mdtm_ptr+1
  sta mdrunhi,X
  ldy #0
  lda TM_mdtm_char
  sta (clrptr),Y
  lda TM_mdtm_bytes_remaining
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

  lda TM_mdtm_ptr
  clc
  adc #2
  sta TM_mdtm_ptr
  lda TM_mdtm_ptr+1
  adc #0
  sta TM_mdtm_ptr+1
  ldy #1
  lda (TM_mdtm_ptr),Y
  ldy cused
  sta (clrptr),Y
  ldy #0
  lda (TM_mdtm_ptr),Y
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

// todo: move this to tme.asm
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
  sbc TM_tmptm_bytes_remaining
  beq s2lao
  bcs s2lnr
  // offset < TM_tmptm_bytes_remaining
  lda TM_tmptm_bytes_remaining
  sec
  sbc offsetlo
  sta TM_tmptm_bytes_remaining
  bne s2d
s2lao:
  // at offset, at end of run
  sta TM_tmptm_bytes_remaining
  beq s2d
s2lnr:
  // offset > TM_tmptm_bytes_remaining
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
  sbc TM_tmptm_bytes_remaining
  sta offsetlo
  bcs s2lnw2
  dec offsethi
s2lnw2:
  NextRun(TM_tmptm_ptr)
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
corow:      .byte 0

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

