  *=$8000 "Drago"

//.var hvzero    = 127
//.var maxhvl    = 88
//.var maxhvr    = 166
//
//.var vvzero    = 127
//.var maxvvu    = 88
//.var maxvvd    = 166

.var hvzero    = 127
.var maxhvl    = 98
.var maxhvr    = 156

.var vvzero    = 127
.var maxvvu    = 88
.var maxvvd    = 166

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
  sta scrolloffset

  lda #hvzero
  sta p1hvi
  sta p1vvi

  lda #vvzero
  sta p1vvi
  sta p1vvi

  lda #0
  sta p1gx+1

  lda #8
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

  lda #176
  sta p1gy
  clc
  rol p1gy
  rol p1gy+1
  clc
  rol p1gy
  rol p1gy+1
  clc
  rol p1gy
  rol p1gy+1
 
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
  jsr updp1hv
  jsr updp1vv
  jsr updp1p
  //jsr log
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

  lda #0
  sta scrolloffset
  lda #%00000111
  sta scrollreg

  lda $d016
  and #%11110000 // enable smooth scrolling
  ora scrollreg  // set initial scroll
  sta $d016

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

  lda #218
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
  lda strlevel3,y
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
  beq loadok
  jmp loaderr
loadok:

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

  lda bgclr
  sta $d021
  lda bgclr1
  sta $d022
  lda bgclr2
  sta $d023

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

  lda tmcolc
  sec
  sbc #2
  sta maxp1px
  lda tmcolc+1
  sbc #0
  sta maxp1px+1

  // multiply by 24 to go from column count to pixels
  // and then shift 3 more to the left to remove fractional portion
  lda maxp1px
  rol maxp1px
  rol maxp1px+1
  rol maxp1px
  rol maxp1px+1
  rol maxp1px
  rol maxp1px+1
  rol maxp1px
  rol maxp1px+1
  rol maxp1px
  rol maxp1px+1
  rol maxp1px
  rol maxp1px+1
  lda maxp1px
  and #%11000000
  sta maxp1px

  lda #176
  sta maxp1py
  lda #0
  sta maxp1py+1

  rol maxp1py
  rol maxp1py+1
  rol maxp1py
  rol maxp1py+1
  rol maxp1py
  rol maxp1py+1
  lda maxp1py
  and #%11111000
  sta maxp1py


  rts


// todo dont assemble for release
log:
  lda #$00
  sta zpb0
  lda #$04
  sta zpb1

  ldy #1

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

  iny
  iny
  lda tmcol0+1
  jsr loghexit
  iny
  lda tmcol0
  jsr loghexit
  iny
  lda #43
  sta (zpb0),y
  iny
  lda scrolloffset
  jsr loghexit

  iny
  iny
  lda scrollreg
  jsr loghexit

  iny
  iny
  lda scrollx
  jsr loghexit

  iny
  iny
  lda $d010
  jsr loghexit
  iny
  lda $d000
  jsr loghexit

  // next row
  lda #$28
  sta zpb0
  lda #$04
  sta zpb1

  ldy #1

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


// How player velocity and positioning works.
// Velocity
//   There are two velocities: indexed velocity and actual velocity.
//     indexed velocity is a value from 0 to 255, unsigned.
//       0 is moving top speed to the left, 255 is top to the right, 127 is zero speed.
//     actual velocity is a signed value calculated by subtracting 127 from the indexed velocity.
//       the actual velocity is used when updating the player's position.
//   Player input determines target indexed velocity, which is either 0,127, or 255.
// Acceleration
//   If the player is moving one direction and is changing directions, then accel/decel
//     rate is higher.
// Position 
//   Player position is calculated by adding the current position to the actual velocity.
//     Global position is a 16 bit number stored in p1gx/+1.
// The 3 least significant bits of the actual velocity and position are fractional
//   and are truncated when updating the sprite's actual position on the screen.
//   This allows smoother movement, acceleration, etc.
// Key variables:
//   p1hvi - horiz vel,indexed
//   p1hva - horiz vel,actual
//   p1gx  - global xpos
//   p1lx  - local xpos
//   p1vvi - vert vel,indexed
//   p1vva - vert vel,actual
//   p1gy  - global ypos
//   p1ly  - local ypos
//   p1hvt - horiz target vel
//   p1vvt - vert target vel
//   maxhvl - max velocity when moving left
//   maxhvr - max velocity when moving right

updp1hv:
  lda ebl
  and #%00000001
  beq updp1hvl
  lda ebr
  and #%00000001
  beq updp1hvr
  lda #hvzero
  sta p1hvt
  bne updp1htvd
updp1hvl:
  lda #maxhvl
  sta p1hvt
  bne updp1htvd
updp1hvr:
  lda #maxhvr
  sta p1hvt
updp1htvd:
  lda p1hvi
  cmp p1hvt
  beq updp1hvd
  bcc updp1haccel
  cmp #(hvzero+2)
  bcs updp1hdecel2
  dec p1hvi
  bne updp1hvd
updp1hdecel2:
  sec
  sbc #2
  sta p1hvi
  bne updp1hvd  
updp1haccel:
  cmp #(hvzero-1)
  bcc updp1haccel2
  inc p1hvi
  bne updp1hvd
updp1haccel2:
  clc
  adc #2
  sta p1hvi
updp1hvd:
  lda p1hvi
  sec
  sbc #hvzero
  sta p1hva
  lda #0
  sbc #0
  sta p1hva+1
  rts

updp1vv:
  lda ebu
  and #%00000001
  beq updp1vvup
  lda ebd
  and #%00000001
  beq updp1vvdown
  lda #maxvvd
  sta p1vvt
  bne updp1vtvd
updp1vvup:
  // if not on the ground, ignore
  lda p1gy+1
  cmp maxp1py+1
  bne updp1vtvd
  lda p1gy
  cmp maxp1py
  bne updp1vtvd
  
  lda #maxvvu
  sta p1vvi
  lda #maxvvd
  sta p1vvt

  bne updp1vvd
updp1vvdown:
  lda #maxvvd
  sta p1vvt
updp1vtvd:
  lda p1vvi
  cmp p1vvt
  beq updp1vvd
  bcc updp1vaccel
  cmp #(vvzero+2)
  bcs updp1vdecel2
  lda p1vvi
  sec
  sbc #2
  dec p1vvi
  bne updp1vvd
updp1vdecel2:
  sec
  sbc #4
  sta p1vvi
  bne updp1vvd  
updp1vaccel:
  cmp #(vvzero-1)
  bcc updp1vaccel2
  inc p1vvi
  bne updp1vvd
updp1vaccel2:
  clc
  adc #2
  sta p1vvi
updp1vvd:
  lda p1vvi
  sec
  sbc #vvzero
  sta p1vva
  lda #0
  sbc #0
  sta p1vva+1
  rts




updp1p:
  // vertical position first
  lda p1gy
  clc
  adc p1vva
  sta p1gy
  sta zpb2

  lda p1gy+1
  adc p1vva+1
  sta p1gy+1
  sta zpb3

  bmi updp1vpneg
  
  cmp maxp1py+1
  bcc updp1vpt
  lda zpb2
  cmp maxp1py
  bcc updp1vpt
 
  // moved below the bottom of the screen
  lda #0
  sta p1vva
  lda #vvzero
  sta p1vvi

  lda maxp1py
  sta p1gy
  lda maxp1py+1
  sta p1gy+1
  lda #226
  sta zpb2
  bne updp1hp
updp1vpneg:
  // move would have moved char above level
  lda #0
  sta p1gy
  sta p1gy+1
  sta p1vva

  lda #vvzero
  sta p1vvi

  lda #50
  sta zpb2
  bne updp1hp
updp1vpt:
  clc
  ror zpb3
  ror zpb2
  ror zpb3
  ror zpb2
  ror zpb3
  ror zpb2
  lda zpb3
  and #%00011111
  sta zpb3

  // zpb2/zpb3 now contain actual position with fractional part truncated
  // sprite position is (trunc position + 50)
  lda zpb2
  clc
  adc #50
  sta zpb2
  lda zpb3
  adc #0
  sta zpb3

updp1hp:
  lda p1gx
  clc
  adc p1hva
  sta p1gx  
  sta zpb0

  lda p1gx+1
  adc p1hva+1
  sta p1gx+1
  sta zpb1

  bmi updp1hpneg

  cmp maxp1px+1
  bcc updp1hpt
  lda zpb0
  cmp maxp1px
  bcc updp1hpt
  // if here, moved past right edge of screen

  lda #0
  sta p1hva
  lda #hvzero
  sta p1hvi

  lda maxp1px
  sta p1gx
  lda maxp1px+1
  sta p1gx+1
  lda #71
  sta zpb0
  lda #1
  sta zpb1
  jmp updp1psprite
updp1hpneg:
  // move would have moved char to left of level
  lda #0
  sta p1gx
  sta p1gx+1
  sta p1hva

  lda #hvzero
  sta p1hvi

  lda #31
  sta zpb0
  lda #0
  sta zpb1
  jmp updp1psprite
updp1hpt:
  clc
  ror zpb1
  ror zpb0
  ror zpb1
  ror zpb0
  ror zpb1
  ror zpb0
  lda zpb1
  and #%00011111
  sta zpb1

  // zpb0/zpb1 now contain actual position with fractional part truncated
  // sprite position is (trunc position + 31) - (tmcol0 + scroll offset)
  lda zpb0
  clc
  adc #31
  sta zpb0
  lda zpb1
  adc #0
  sta zpb1

  // multiply by 8 (shift right 3 to get column in x coords)
  lda tmcol0
  sta colshift
  lda tmcol0+1
  sta colshift+1
  rol colshift
  rol colshift+1
  rol colshift
  rol colshift+1
  rol colshift
  rol colshift+1

  lda colshift
  and #%11111000 // drop last 3 bits after rotates
  clc
  adc scrolloffset
  sta colshift
  lda colshift+1
  adc #0
  sta colshift+1

  lda zpb0
  sec
  sbc colshift
  sta zpb0
  lda zpb1
  sbc colshift+1
  sta zpb1

  // sprite position is now calculated and stored in zpb0/1, but we might
  // need to scroll which will impact the sprite position

  lda zpb1
  bne updp1psprite
  lda zpb0
  cmp #200
  bcs updp1hpsl
  cmp #100
  bcc updp1hpsr
  bcs updp1psprite
updp1hpsl:
  // greater than 200, scroll left if moving right
  lda p1hva
  beq updp1psprite
  bmi updp1psprite
  // moving right, try to scroll
  lda zpb0
  sec
  sbc $d000
  sta scrollx
  jsr scrolll
  // sprite position is new sprite position minus amount we scrolled
  lda zpb0
  sec
  sbc scrollx
  sta zpb0
  lda #0
  sta zpb1
  beq updp1psprite
updp1hpsr:
  // less than 100, scroll right if moving left
  lda p1hva
  beq updp1psprite
  bpl updp1psprite
  // moving left, try to scroll
  lda $d000
  sec
  sbc zpb0
  sta scrollx
  jsr scrollr
  // sprite position is new sprite position plus amount we scrolled
  lda zpb0
  clc
  adc scrollx
  sta zpb0
  lda #0
  sta zpb1
updp1psprite:
  lda zpb2
  sta $d001
  lda zpb0
  sta $d000
  lda zpb1
  bne updp1pmsb
  lda $d010
  and #%11111110
  sta $d010
  jmp updp1pd
updp1pmsb:
  lda $d010
  ora #%00000001
  sta $d010
updp1pd:
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
miny:        .byte 0,0
maxy:        .byte 0,0
ptime:       .byte 0,0,0
etime:       .byte 0,0,0
time:        .byte 0,0,0

p1hvi:       .byte 0
p1hva:       .byte 0,0
p1gx:        .byte 0,0
p1lx:        .byte 0,0
p1vvi:       .byte 0
p1vva:       .byte 0,0
p1gy:        .byte 0,0
p1ly:        .byte 0,0
p1hvt:       .byte 0
p1vvt:       .byte 0

// event buffers for each jostick press
ebl:       .byte 0
ebr:       .byte 0
ebu:       .byte 0
ebd:       .byte 0
ebp:       .byte 0

tmp0:      .byte 0

maxp1px:   .byte 0,0
maxp1py:   .byte 0,0

colshift:  .byte 0,0

