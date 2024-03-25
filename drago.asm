  *=$8000 "Drago"

// program addresses
.var vzero     = 127
.var maxhvl    = 88
.var maxhvr    = 166

.var scrcol0   = 1
.var scrwidth  = 38
.var scrrow0   = 4
.var scrheight = 20

  jmp init

#import "const.s"
#import "data.s"
#import "utils.s"
#import "tm.s"
#import "tme.s"

init:
  lda #0
  sta ptime
  sta ptime+1
  sta ptime+2
  sta etime
  sta etime+1
  sta etime+2
  sta time
  sta time+1
  sta time+2
  sta eb.l
  sta eb.r
  sta eb.u
  sta eb.d
  sta eb.p
  sta eb.kf1
  sta eb.kf3
  sta eb.kf5
  sta eb.kw
  sta eb.ka
  sta eb.ks
  sta eb.kd
  sta eb.ksp
  sta p1hva
  sta p1hva+1
  sta p1vva
  sta p1vva+1
  sta p1gx+1
  sta p1lx+1
  sta p1gy+1
  sta p1ly+1
  //sta p1vv
  //sta p1tvv
  //sta p1vh
  //sta p1tvh
  //sta p1vdir
  //sta p1x
  //sta p1y

  lda #hvzero
  sta p1hvi
  sta p1vvi

  lda #0
  sta p1gx+1

  lda #128
  sta p1gx
  clc
  rol p1gx
  rol p1gx+1
  clc
  rol p1gx
  rol p1gx+1
  clc
  rol p1gx
  rol p1gx+1
  lda #128
  sta p1gy

//setup multicolor char mode
//and set colors
  lda #0    //blk
  sta $d021 //bg color

  lda #14   //lt blue
  sta $d022 //bg color 1

  lda #11   //gray 1
  sta $d023 //bg color 2

// turn on multiclr char mode
  lda $d016 //vic ctrl
  ora #%00010000
  sta $d016

// turn off keyscan interrupts
// and switch in character set
  lda $dc0e //cia ctrl
  and #%11111110
  sta $dc0e

  lda $01 //ioport
  and #%11111011
  sta $01

// copy character rom into program
// character area
  lda #$00
  sta $fb
  lda #$d0
  sta $fc

  lda #$00
  sta $fd
  lda #$20
  sta $fe
  
  lda #$00
  sta $bb
  lda #$08
  sta $bc

  jsr copy

// switch in i/o and restart keyscan
// interrupt timer
  lda $01 //ioport
  ora #%00000100
  sta $01

  lda $dc0e //cia ctrl
  ora #%00000001
  sta $dc0e //cia ctrl

// use our in-memory charset
  lda $d018 //vic m ctrl
  and #%11110000
  ora #%00001000
  sta $d018
  
cls:
  ldy #$00
clsl:
  lda #1 //white
  sta $d800,y
  sta $d800+$100,y
  sta $d800+$200,y
  sta $d800+$300,y
  lda #32
  sta $0400,y
  sta $0400+$100,y
  sta $0400+$200,y
  sta $0400+$300,y
  iny
  bne clsl

  ldx #63
copyspr:
  lda sprbox8x8,X
  sta $3000,X
  sta $3040,X
  sta $3080,X
  dex
  bpl copyspr

  ldx #192
  stx $07f8 //spr ptr
  inx
  stx $07f8+1
  inx
  stx $07f8+2

  //lda #%00000111
  lda #0
  sta $d015 //spr enable

  lda #7
  sta $d027 //spr 0 clr
  sta $d028 //spr 1 clr
  sta $d029 //spr 2 clr

  lda #128
  sta $d000 //spr0x
  lda #16
  sta $d002 //spr1x
  sta $d004 //spr2x
  lda #%00000110
  sta $d010 //spr msb

  lda #208
  sta $d001 //spr0y
  lda #58
  sta $d003 //spr1y
  lda #106
  sta $d005 //spr2y

 

  jsr inittm

  lda tmrowc
  sec
  sbc #scrheight
  sta maxrow0
  lda tmrowc+1
  sbc #0
  sta maxrow0+1

  lda tmcolc
  sec
  sbc #scrwidth
  sta maxcol0
  lda tmcolc+1
  sbc #0
  sta maxcol0+1
  
  jsr redraw  
loop:
  lda $d012
  cmp #$FC
  bne loop
  
  jsr inkbd
  jsr pkbd

  lda $dc01
  jsr injs
  jsr mvmaph
  jsr mvmapv
  jsr press  
  //jsr updp1v
  //jsr updp1p
  //jsr log
  jsr log2
  jmp loop

// todo dont assemble for release
log:
  lda #$00
  sta zpb0
  lda #$04
  sta zpb1

  ldy #26

  lda p1gx+1
  jsr loghexit
  iny
  lda p1gx
  jsr loghexit

  iny
  iny
  lda p1lx+1
  jsr loghexit
  iny
  lda p1lx
  jsr loghexit

  iny
  iny
  lda p1hva+1
  jsr loghexit
  iny
  lda p1hva
  jsr loghexit

  // next row
  lda #$28
  sta zpb0
  lda #$04
  sta zpb1

  ldy #26

  lda p1gy+1
  jsr loghexit
  iny
  lda p1gy
  jsr loghexit

  iny
  iny
  lda p1ly+1
  jsr loghexit
  iny
  lda p1ly
  jsr loghexit

  iny
  iny
  lda p1vva+1
  jsr loghexit
  iny
  lda p1vva
  jsr loghexit
  rts


// todo dont assemble for release
log2:
  lda #$00
  sta zpb0
  lda #$04
  sta zpb1

  ldy #0

  lda tmrowc+1
  jsr loghexit
  iny
  lda tmrowc
  jsr loghexit

  iny
  iny
  lda tmcolc+1
  jsr loghexit
  iny
  lda tmcolc
  jsr loghexit

  iny
  iny
  lda chrtmrunlast+1
  jsr loghexit
  iny
  lda chrtmrunlast
  jsr loghexit

  // next row
  lda #$28
  sta zpb0
  lda #$04
  sta zpb1

  ldy #0

  lda etime+2
  jsr loghexit
  iny
  lda etime+1
  jsr loghexit
  iny
  lda etime
  jsr loghexit

  iny
  iny
  lda tmrow0+1
  jsr loghexit
  iny
  lda tmrow0
  jsr loghexit

  iny
  iny
  lda tmcol0+1
  jsr loghexit
  iny
  lda tmcol0
  jsr loghexit

  iny
  iny
  lda byteinfo
  jsr loghexit

  rts

inittm:
  lda #0
  sta tmrow0
  sta tmrow0+1
  sta tmcol0
  sta tmcol0+1

  lda #$00
  sta chrtmrun0
  lda #$40
  sta chrtmrun0+1
  
  lda #<chrtm
  sta zpb0
  lda #>chrtm
  sta zpb1
  jsr settmi

  //lda #3
  //sta newbyte

  jsr testscrn
  jsr gettmi

  rts

// in its own subroutine just
// so we can time it
redraw:
  jsr gettime
  lda time
  sta ptime
  lda time+1
  sta ptime+1
  lda time+2
  sta ptime+2

  jsr drawscrn
  jsr gettime

  lda time
  sec
  sbc ptime
  sta etime
  lda time+1
  sbc ptime+1
  sta etime+1
  lda time+2
  sbc ptime+2
  sta etime+2
  rts

paddcols:
  lda maxcol0
  clc
  adc #1
  sta maxcol0
  lda maxcol0+1
  adc #0
  sta maxcol0+1

  lda tmcol0
  sta tmcol
  lda tmcol0+1
  sta tmcol+1
  //lda #79
  //sta tmcol
  //lda #0
  //sta tmcol+1
  lda #43
  sta newbyte
  jsr addcol

  rts

psetchar:
  lda tmcol0
  sta tmcol
  lda tmcol0+1
  sta tmcol+1
  lda tmrow0
  sta tmrow
  lda tmrow0+1
  sta tmrow+1
  lda #28
  sta newbyte
  jsr setbyte

  rts

press:
  lda eb.p
  and #%00000001
  bne pressd

  lda #<chrtm
  sta zpb0
  lda #>chrtm
  sta zpb1
  jsr settmi
  //jsr paddcols
  jsr psetchar
  jsr gettmi
  
  jsr redraw

pressd:
  rts

mvmaph:
  lda eb.l
  and #%00000001
  beq mvmapl
  lda eb.r
  and #%00000001
  beq mvmapr
  jmp mvmaphd
mvmapl:
  lda tmcol0
  bne mvmaplt
  lda tmcol0+1
  bne mvmaplt
  beq mvmaphd 
mvmaplt:
  lda tmcol0
  sec
  sbc #1
  sta tmcol0
  lda tmcol0+1
  sbc #0
  sta tmcol0+1
  jsr redraw 
  jmp mvmaphd
mvmapr:
  lda tmcol0+1
  cmp maxcol0+1
  bcc mvmaprt
  lda tmcol0
  cmp maxcol0
  bcc mvmaprt
  bcs mvmaphd
mvmaprt:
  lda tmcol0
  clc
  adc #1
  sta tmcol0
  lda tmcol0+1
  adc #0
  sta tmcol0+1
  jsr redraw
mvmaphd:
  rts

mvmapv:
  lda eb.u
  and #%00000001
  beq mvmapu
  lda eb.d
  and #%00000001
  beq mvmapd
  jmp mvmapvd
mvmapu:
  lda tmrow0
  bne mvmaput
  lda tmrow0+1
  bne mvmaput
  beq mvmapvd 
mvmaput:
  lda tmrow0
  sec
  sbc #1
  sta tmrow0
  lda tmrow0+1
  sbc #0
  sta tmrow0+1
  jsr redraw 
  jmp mvmapvd
mvmapd:
  lda tmrow0+1
  cmp maxrow0+1
  bcc mvmapdt
  lda tmrow0
  cmp maxrow0
  bcc mvmapdt
  bcs mvmapvd
mvmapdt:
  lda tmrow0
  clc
  adc #1
  sta tmrow0
  lda tmrow0+1
  adc #0
  sta tmrow0+1
  jsr redraw
mvmapvd:
  rts


updp1v:
  lda eb.l
  and #%00000001
  beq updp1vl
  lda eb.r
  and #%00000001
  beq updp1vr
  lda #hvzero
  sta p1hvt
  bne updp1tvd
updp1vl:
  lda #maxhvl
  sta p1hvt
  bne updp1tvd
updp1vr:
  lda #maxhvr
  sta p1hvt
updp1tvd:
  lda p1hvi
  cmp p1hvt
  beq updp1vd
  bcc updp1accel
  cmp #(hvzero+2)
  bcs updp1decel2
  dec p1hvi
  bne updp1vd
updp1decel2:
  sec
  sbc #2
  sta p1hvi
  bne updp1vd  
updp1accel:
  cmp #(hvzero-1)
  bcc updp1accel2
  inc p1hvi
  bne updp1vd
updp1accel2:
  clc
  adc #2
  sta p1hvi
updp1vd:
  lda p1hvi
  sec
  sbc #hvzero
  sta p1hva
  lda #0
  sbc #0
  sta p1hva+1
  rts
  
updp1p:
  clc
  lda p1gx
  adc p1hva
  sta p1gx  
  sta zpb0

  lda p1gx+1
  adc p1hva+1
  sta p1gx+1
  sta zpb1

  clc
  ror zpb1
  ror zpb0
  ror zpb1
  ror zpb0
  ror zpb1
  ror zpb0
  lda zpb0
  sta $d000 //spr0x
  
  rts

pkbd:
  Debounce(eb.kf1,pkf1)
  Debounce(eb.kf3,pkf3)
  Debounce(eb.kf5,pkf5)
  rts
pkf1:
  //jsr mapmode
  rts
pkf3:
  //jsr tilesmode
  rts
pkf5:
  //jsr tilemode
  rts

// reads keyboard
inkbd:
  jsr $ffe4
  InKBD(133,eb.kf1,inf3)
inf3:
  InKBD(134,eb.kf3,inf5)
inf5:
  InKBD(135,eb.kf5,inw)
inw:
  InKBD(87,eb.kw,ina)
ina:
  InKBD(65,eb.ka,ins)
ins:
  InKBD(83,eb.ks,ind)
ind:
  InKBD(68,eb.kd,insp)
insp:
  InKBD(32,eb.ksp,inkbdd)
inkbdd:
  rts


// read a joystick
// inputs
//   A - joystick port value
injs:
  lsr
  rol eb.u
  lsr
  rol eb.d
  lsr
  rol eb.l
  lsr
  rol eb.r
  lsr
  rol eb.p
  rts

gettime:
  jsr $ffde
  sty time+2
  stx time+1
  sta time
  rts

// data area
maxcol0:     .byte 0,0
maxrow0:     .byte 0,0
minx:        .byte 0,0
maxx:        .byte 0,0
scrollx:     .byte 0,0
miny:        .byte 0,0
maxy:        .byte 0,0
scrolly:     .byte 0,0
ptime:       .byte 0,0,0
etime:       .byte 0,0,0
time:        .byte 0,0,0

p1hvi:       .byte 0   //horiz vel,indexed
p1hva:       .byte 0,0 //horiz vel,actual
p1gx:        .byte 0,0 //global xpos
p1lx:        .byte 0,0 //local xpos
p1vvi:       .byte 0   //vert vel,indexed
p1vva:       .byte 0,0 //vert vel,actual
p1gy:        .byte 0,0 //global ypos
p1ly:        .byte 0,0 //local ypos
p1hvt:       .byte 0   //horiz target vel
p1vvt:       .byte 0

//p1vv       .byte 0
//p1tvv      .byte 0
//p1vh       .byte 0
//p1tvh      .byte 0
//p1vdir     .byte 0
//p1x        .byte 0,0
//p1y        .byte 0,0
// event buffers for each key
eb.l:       .byte 0
eb.r:       .byte 0
eb.u:       .byte 0
eb.d:       .byte 0
eb.p:       .byte 0
eb.kf1:     .byte 0
eb.kf3:     .byte 0
eb.kf5:     .byte 0
eb.kw:      .byte 0
eb.ka:      .byte 0
eb.ks:      .byte 0
eb.kd:      .byte 0
eb.ksp:     .byte 0


