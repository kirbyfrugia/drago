 


 
// todo make sure that we are turning off interrupts when loading new chars!





  *=$8000 "Drago"

// program addresses
.var hvzero    = 127
.var maxhvl    = 88
.var maxhvr    = 166

  jmp init

#import "const.asm"
#import "dragoconst.asm"
#import "dragodata.asm"
#import "utils.asm"
#import "tm.asm"
#import "tme.asm"

init:
  // switch out basic
  lda $01
  and #%11111110
  sta $01

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
  sta ebl
  sta ebr
  sta ebu
  sta ebd
  sta ebp
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
 
  jsr initui
  jsr initsys
  jsr loadmap
  jsr redraw
  jsr initspr
loop:
  lda $d012
  cmp #$f8
  bne loop 
  
  lda $dc00
  jsr injs
  jsr updp1v
  jsr updp1p
  jsr log
  jmp loop

cls:
  ldy #0
clsl:
  lda #1
  sta $d800,y
  sta $d800+$0100,y
  sta $d800+$0200,y
  sta $d800+$0300,y
  lda #252
  sta $0400,y
  sta $0400+$0100,y
  sta $0400+$0200,y
  sta $0400+$0300,y
  iny
  bne clsl
  rts

initsys:
  // turn on multiclr char mode
  lda $d016
  ora #%00010000
  sta $d016

  // use our in-memory charset
  lda $d018
  and #%11110000
  ora #%00001000
  sta $d018

  //set colors
  //bgclr
  lda #0
  sta $d021

  //bgclr1
  lda #7
  sta $d022

  //bgclr2
  lda #12
  sta $d023 

  rts

initspr:
  ldx #63
copyspr:
  lda sprbox8x8,X
  sta $3000,X
  //sta $3040,X
  //sta $3080,X
  dex
  bpl copyspr

  ldx #192
  stx $07f8 //spr ptr
  //inx
  //stx $07f8+1
  //inx
  //stx $07f8+2

  lda #%00000001
  sta $d015 //spr enable

  lda #7
  sta $d027 //spr 0 clr
  //sta $d028 //spr 1 clr
  //sta $d029 //spr 2 clr

  lda #128
  sta $d000 //spr0x
  //lda #16
  //sta $d002 //spr1x
  //sta $d004 //spr2x
  lda #%00000000
  sta $d010 //spr msb

  lda #208
  sta $d001 //spr0y
  //lda #58
  //sta $d003 //spr1y
  //lda #106
  //sta $d005 //spr2y

  rts

initui:
  jsr cls
  rts


loadmap:
  ldx #9
  stx fdev

  ldy #0
lml:
  lda strlevel1,y
  beq lmld
  sta fname,y
  iny
  bne lml
lmld:
  sty fnamelen

  // load main data
  lda #<filedatas
  sta zpb0
  lda #>filedatas
  sta zpb1 
  jsr fload
  lda fstatus
  bne loaderr

  // load the char map
  // set file name, append a "C" to the end of the name
  ldx fnamelen
  lda #67 // C
  sta fname,x

  lda #<chrtmdatas
  sta zpb0
  lda #>chrtmdatas
  sta zpb1 
  inc fnamelen
  jsr fload
  dec fnamelen
  lda #0
  ldx fnamelen
  sta fname,x
  lda fstatus
  bne loaderr

  // load the metadata map
  // set file name, append a "M" to the end of the name
  ldx fnamelen
  lda #77 // M
  sta fname,x

  lda #<mdtmdatas
  sta zpb0
  lda #>mdtmdatas
  sta zpb1 
  inc fnamelen
  jsr fload
  dec fnamelen
  lda #0
  ldx fnamelen
  sta fname,x
  lda fstatus
  bne loaderr

  lda #25
  sta tmrowc
  lda #scrrow0
  sta tmrow0
  lda #0
  sta tmcol0
  sta tmcol0+1

  lda chrtmcolc
  sta tmcolc
  lda chrtmcolc+1
  sta tmcolc+1
  jmp loadd
loaderr:
  jsr emptyscrn
loadd:
  jsr updscrn
  jsr drawscrn
  rts


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


updp1v:
  lda ebl
  and #%00000001
  beq updp1vl
  lda ebr
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

// read a joystick
// inputs
//   A - joystick port value
injs:
  lsr
  rol ebu
  lsr
  rol ebd
  lsr
  rol ebl
  lsr
  rol ebr
  lsr
  rol ebp
  rts

gettime:
  jsr $ffde
  sty time+2
  stx time+1
  sta time
  rts

// data area
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
ebl:       .byte 0
ebr:       .byte 0
ebu:       .byte 0
ebd:       .byte 0
ebp:       .byte 0

