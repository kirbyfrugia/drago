//maped.s

  //*= $0801 "Basic Upstart"
  //BasicUpstart(init)

  *=$8000 "MapEd"

  jmp init

#import "const.asm"
#import "mapedconst.asm"
#import "mapeddata.asm"
#import "mapedutils.asm"
#import "utils.asm"
#import "tm.asm"
#import "tme.asm"

init:
  // switch out basic
  lda $01
  and #%11111110
  sta $01

  lda #0
  sta cursx
  sta cursy
  sta tsf
  sta ctidx
  //sta logy
  //sta logtmp0
  //sta logtmp1
  //sta logtmp2
  //sta logtmp3

  lda #8
  sta cursmvsprx
  lda #1
  sta cursmvx
  lda #38
  sta curstedmaxx

  lda #%01111111
  sta brushm
  lda #%10000000
  sta brushp

  lda #%11110001
  ldx #0
tsdatal:
  sta tsdata,X
  inx
  bne tsdatal

  jsr initsys
  jsr initui
  jsr redrawui
  jsr initspr
  jsr settile
  jsr drawtile
  jsr fgbp
  jsr setbrush
  jsr redrawmap
  jsr initevents
  
  //jsr test
loop:
  lda $d012
  cmp #$F8
  bne loop
  
  lda $dc00
  jsr injs
  jsr inkb
  jsr events
  jsr statline
loopd:
  jmp loop

cls:
  ldy #0
clsl:
  lda fghclr
  sta $d800,y
  sta $d800+$0100,y
  sta $d800+$0200,y
  sta $d800+$0300,y
  lda #emptychr
  sta $0400,y
  sta $0400+$0100,y
  sta $0400+$0200,y
  sta $0400+$0300,y
  iny
  bne clsl
  rts

initchrs:
  // turn off keyscan interrupts and switch in character set
  lda $dc0e
  and #%11111110
  sta $dc0e

  // ioport
  lda $01
  and #%11111011
  sta $01

  // copy character rom into program character area
  lda #$00
  sta $fb
  lda #$d0
  sta $fc

  lda #<tiles
  sta $fd
  lda #>tiles
  sta $fe
  
  lda #$00
  sta $bb
  lda #$08
  sta $bc

  jsr copy

  // reserved and custom chars
  ldy #7
custl:
  lda 32*8+tiles,Y //empty
  sta emptychr*8+tiles,Y
  lda 66*8+tiles,Y //vbar
  sta vbarchr*8+tiles,Y
  lda 81*8+tiles,Y //filled circle
  sta rbonchr*8+tiles,Y
  lda 87*8+tiles,Y //empty circle
  sta rboffchr*8+tiles,Y
  lda 30*8+tiles,Y //up arrow
  sta upchr*8+tiles,Y
  lda 31*8+tiles,Y //left arrow
  sta lchr*8+tiles,Y
  dey
  bpl custl

  ldy #7
custl2:
  lda #$ff //filled box
  sta $27e8,Y
  lda #%01010101 //bgclr1
  sta $27f0,Y
  lda #%10101010 //bclr2
  sta $27f8,Y
  dey
  bpl custl2

  ldy #0
  lda #$18
  sta downchr*8+tiles,Y
  sta downchr*8+tiles+1,Y
  sta downchr*8+tiles+2,Y
  sta downchr*8+tiles+3,Y
  sta downchr*8+tiles+6,Y
  lda #$7e
  sta downchr*8+tiles+4,Y
  lda #$3c
  sta downchr*8+tiles+5,Y
  lda #0
  sta downchr*8+tiles+7,Y
  
  lda #$0
  sta rchr*8+tiles
  sta rchr*8+tiles+7
  lda #$08
  sta rchr*8+tiles+1
  sta rchr*8+tiles+6
  lda #$0c
  sta rchr*8+tiles+2
  sta rchr*8+tiles+5
  lda #$fe
  sta rchr*8+tiles+3
  sta rchr*8+tiles+4

  // switch in i/o and restart keyscan interrupt timer
  lda $01
  ora #%00000100
  sta $01

  lda $dc0e
  ora #%00000001
  sta $dc0e

  // use our in-memory charset
  lda $d018
  and #%11110000
  ora #%00001000
  sta $d018

  rts

initsys:
  // turn on multiclr char mode
  lda $d016
  ora #%00010000
  sta $d016

  jsr initchrs

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
  lda sprbox16x8,X
  sta $3040,X
  dex
  bpl copyspr

  //sprite ptr
  ldx #192
  stx $07f8

  //sprite enable
  lda #%00000001
  sta $d015

  //single color mode
  lda #%00000000
  sta $d01c

  lda #24
  sta $d000 //spr0x
  lda #%00000000
  sta $d010 //spr msb
  lda #50
  sta $d001 //spr0y
  rts

clearinput:
  ldy #29
clinl:
  lda #emptychr
  sta $0400,y
  lda fghclr
  sta $d800,y
  dey
  bpl clinl
  rts

redrawinput:
  lda fghclr
  tax
  ToZPB(<strnew,>strnew,zpb0)
  ToZPB($00,$04,zpb2)
  jsr ps
  ToZPB($00,$d8,zpb2)
  jsr cs

  lda #emptychr
  sta $0405
  stx $d805

  ToZPB(<strload,>strload,zpb0)
  ToZPB($06,$04,zpb2)
  jsr ps
  ToZPB($06,$d8,zpb2)
  jsr cs

  lda #emptychr
  sta $040c
  stx $d80c

  ToZPB(<strsave,>strsave,zpb0)
  ToZPB($0d,$04,zpb2)
  jsr ps
  ToZPB($0d,$d8,zpb2)
  jsr cs

  rts

redrawui:
  lda $d021
  and #%00001111
  tax
  lda cfg,X
  sta fghclr
  lda ch,X
  sta fghclr+1
 
  ToZPB($95,$04,zpb0)
  ToZPB($95,$d8,zpb2)
  ldy #0
  ldx #20
vbarl:
  lda #vbarchr
  sta (zpb0),Y
  lda fghclr
  sta (zpb2),Y
  dex
  beq vbarld
  lda zpb0
  clc
  adc #40
  sta zpb0
  sta zpb2
  bcc vbarlnw
  inc zpb1
  inc zpb3
vbarlnw:
  jmp vbarl  
vbarld:

  lda fghclr
  tax

  jsr clearinput
  jsr redrawinput

  ToZPB(<strmapl,>strmapl,zpb0)
  ToZPB($28,$04,zpb2)
  jsr ps
  ToZPB($28,$d8,zpb2)
  jsr cs
  
  ToZPB(<strtiles,>strtiles,zpb0)
  ToZPB($1e,$04,zpb2)
  jsr ps
  ToZPB($1e,$d8,zpb2)
  jsr cs

  ToZPB(<strload,>strload,zpb0)
  ToZPB($ea,$04,zpb2)
  jsr ps
  ToZPB($ea,$d8,zpb2)
  jsr cs

  ToZPB(<strtile,>strtile,zpb0)
  ToZPB($0e,$05,zpb2)
  jsr ps
  ToZPB($0e,$d9,zpb2)
  jsr cs

  ToZPB(<strmc,>strmc,zpb0)
  ToZPB($76,$06,zpb2)
  jsr ps
  ToZPB($76,$da,zpb2)
  jsr cs

  ToZPB(<strfg,>strfg,zpb0)
  ToZPB($9e,$06,zpb2)
  jsr ps
  ToZPB($9e,$da,zpb2)
  jsr cs

  ToZPB(<strbrush,>strbrush,zpb0)
  ToZPB($c6,$06,zpb2)
  jsr ps
  ToZPB($c6,$da,zpb2)
  jsr cs

  ToZPB(<strfgbg,>strfgbg,zpb0)
  ToZPB($ee,$06,zpb2)
  jsr ps
  ToZPB($ee,$da,zpb2)
  jsr cs

  ToZPB(<strc1c2,>strc1c2,zpb0)
  ToZPB($16,$07,zpb2)
  jsr ps
  ToZPB($16,$db,zpb2)
  jsr cs

  ToZPB(<strcoll,>strcoll,zpb0)
  ToZPB($3e,$07,zpb2)
  jsr ps
  ToZPB($3e,$db,zpb2)
  jsr cs
  
  ToZPB(<strlrtb,>strlrtb,zpb0)
  ToZPB($66,$07,zpb2)
  jsr ps
  ToZPB($66,$db,zpb2)
  jsr cs

  // upd fg color disp
  ldx ctidx
  lda tsdata,X
  sta $daa1

  // color line 2 and last
  lda fghclr
  ldy #29
ruil2l:
  sta $d828,Y
  sta $dbc0,Y
  dey
  bpl ruil2l

  //bgclrs, set fg color to indicate
  //multicolor character
  lda #$0f
  sta 55336+11
  sta 55336+17

  //map arrows
  lda #upchr
  sta $046d
  lda #downchr
  sta $07b5
  lda #lchr
  sta $07c0
  lda #rchr
  sta $07dc

  lda fghclr
  sta $d86d
  sta $dbb5
  sta $dbc0
  sta $dbdc

  //tile sel arrows  
  lda #upchr
  sta $044f
  lda #vbarchr
  sta $0477
  sta $049f
  lda #downchr
  sta $04c7

  lda fghclr
  sta $d84f
  sta $d877
  sta $d89f
  sta $d8c7

  jsr lts

  //upd curs clr
  lda fghclr+1
  sta $d027

  rts

lts:
  ldx tsf
  ldy #0
ltsl:
  txa
  sta 1064+30+1,Y
  clc
  adc #8
  sta 1104+30+1,Y
  adc #8
  sta 1144+30+1,Y
  adc #8
  sta 1184+30+1,Y

  lda tsdata,X
  and #%00001111
  sta 55336+30+1,Y
  lda tsdata+8,X
  and #%00001111
  sta 55376+30+1,Y
  lda tsdata+16,X
  and #%00001111
  sta 55416+30+1,Y
  lda tsdata+24,X
  and #%00001111
  sta 55456+30+1,Y

  inx
  iny
  cpy #8
  bne ltsl
  rts


initui:
  lda $d021
  and #%00001111
  tax
  lda cfg,X
  sta fghclr
  jsr cls
 
  ldx #1
  stx uimc+2
  stx uibgb+2
  stx uic1b+2
  stx uic2b+2

  ldx #0
  stx uifgclr+2
  stx uicl+2
  stx uicr+2
  stx uict+2
  stx uicb+2
  stx uifgb+2

  lda #3
  sta tmrow0
  lda #0
  sta tmcol0
  sta tmcol0+1

  // todo this isn't enough space
  //first and last run, lo/hi
  lda #<chrtmdatas
  sta chrtmrun0
  sta chrtmrunlast
  lda #<mdtmdatas
  sta mdtmrun0
  sta mdtmrunlast
  lda #>chrtmdatas
  sta chrtmrun0+1
  sta chrtmrunlast+1
  lda #>mdtmdatas
  sta mdtmrun0+1
  sta mdtmrunlast+1
  
  jsr emptyscrn
  rts



statline:
  lda #$c1
  sta zpb0
  lda #$07
  sta zpb1
  ldy #0

  lda #24 //X
  sta (zpb0),Y
  iny
  lda #58 //:
  sta (zpb0),Y

  iny
  lda tmcol0+1
  jsr loghexit
  iny
  lda tmcol0
  jsr loghexit

  iny
  lda #43 //+
  sta (zpb0),Y
  iny
  lda cursx
  jsr loghexit  

  iny
  iny
  lda #25 //Y
  sta (zpb0),Y
  iny
  lda #58 //:
  sta (zpb0),Y

  iny
  lda tmrow0
  jsr loghexit
  iny
  lda #43 //+
  sta (zpb0),Y

  iny
  lda cursy
  sec
  sbc #scrrow0
  jsr loghexit

  lda chrtmrunlast
  sec
  sbc chrtmrun0
  sta tmp0
  lda chrtmrunlast+1
  sbc chrtmrun0+1
  sta tmp1

  lda tmp0
  clc
  adc mdtmrunlast
  sta tmp0
  lda tmp1
  adc mdtmrunlast+1
  sta tmp1

  lda tmp0
  sec
  sbc mdtmrun0
  sta tmp0
  lda tmp1
  sbc mdtmrun0+1
  sta tmp1

  lda tmp0
  clc
  adc #4
  sta tmp0
  lda tmp1
  adc #0
  sta tmp1

  iny
  iny
  lda #13 //m
  sta (zpb0),Y
  iny
  lda #58 //:
  sta (zpb0),Y
  iny
  lda tmp1
  jsr loghexit
  iny
  lda tmp0
  jsr loghexit

  iny
  iny
  lda etime
  jsr loghexit
  rts

redrawmap:
  jsr drawscrn
  rts

//test:
//  lda cursx
//  pha
//  lda cursy
//  pha
//
//  lda #$04
//  sta cursx
//  lda #$06
//  sta cursy
//  jsr psetchr
//
//  lda #$07
//  sta cursx
//  lda #$0b
//  sta cursy
//  jsr psetchr
//
//  lda #$07
//  sta cursx
//  lda $0f
//  sta cursy
//  jsr psetchr
//
//  lda #$0b
//  sta cursx
//  lda #$13
//  sta cursy
//  jsr psetchr
//
//  lda #$12
//  sta cursx
//  lda #$13
//  sta cursy
//  jsr psetchr
//
//  lda #$07
//  sta cursx
//  lda #$13
//  sta cursy
//  jsr addcp
//  jsr addcp
//  jsr addcp
//  jsr addcp
//  jsr addcp
//  jsr addcp
//  jsr addcp
//  jsr addcp
//  jsr addcp
//  jsr addcp
//  //jsr addcp
//  //jsr addcp
//
//  pla
//  sta cursy
//  pla
//  sta cursx
//  rts

//dump:
//  lda #$00
//  sta $fb
//  lda #$40
//  sta $fc
//
//  lda #$00
//  sta $fd
//  lda #$10
//  sta $fe
//  
//  lda #$ff
//  sta $bb
//  lda #$07
//  sta $bc
//
//  jsr copy
//
//  lda #$00
//  sta $fb
//  lda #$60
//  sta $fc
//
//  lda #$00
//  sta $fd
//  lda #$18
//  sta $fe
//  
//  lda #$ff
//  sta $bb
//  lda #$07
//  sta $bc
//
//  jsr copy
//
//  lda #<chrtm
//  sta $fb
//  lda #>chrtm
//  sta $fc
//
//  lda #$00
//  sta $fd
//  lda #$c0
//  sta $fe
//  
//  lda #$06
//  sta $bb
//  lda #$00
//  sta $bc
//
//  jsr copy
//
//  lda #<mdtm
//  sta $fb
//  lda #>mdtm
//  sta $fc
//
//  lda #$10
//  sta $fd
//  lda #$c0
//  sta $fe
//  
//  lda #$06
//  sta $bb
//  lda #$00
//  sta $bc
//
//  jsr copy
//  rts

//log:
//  pha
//  tya
//  pha
//
//  ldy logy
//  lda logtmp0
//  sta $c060,Y
//  iny
//  lda logtmp1
//  sta $c060,Y
//  iny
//  lda logtmp2
//  sta $c060,Y
//  iny
//  lda logtmp3
//  sta $c060,Y
//  iny
//  sty logy
//
//  pla
//  tay
//  pla
//  rts
//
//
addcp:
  lda cursx
  cmp #29
  bcs addcpd
  lda cursy
  cmp #2
  bcc addcpd
  cmp #24
  bcs addcpd

  lda tmcol0
  clc
  adc cursx
  sta tmcol
  lda tmcol0+1
  adc #0
  sta tmcol+1

  lda #<chrtm
  sta tmptr
  lda #>chrtm
  sta tmptr+1
  jsr addcol

  lda #<mdtm
  sta tmptr
  lda #>mdtm
  sta tmptr+1
  jsr addcol

  lda tmcolc
  clc
  adc #1
  sta tmcolc
  lda tmcolc+1
  adc #0
  sta tmcolc+1

  jsr updscrn
  jsr redrawmap  
addcpd:
  rts

delcp:
  lda cursx
  cmp #29
  bcs delcpd
  lda cursy
  cmp #2
  bcc delcpd
  cmp #24
  bcs delcpd

  lda tmcolc
  cmp #41
  bcs decpok
  lda tmcolc+1
  bne decpok
  jmp delcpd
decpok:
  lda tmcol0
  clc
  adc cursx
  sta tmcol
  lda tmcol0+1
  adc #0
  sta tmcol+1

  lda #<chrtm
  sta tmptr
  lda #>chrtm
  sta tmptr+1
  jsr delcol

  lda #<mdtm
  sta tmptr
  lda #>mdtm
  sta tmptr+1
  jsr delcol

  lda tmcolc
  sec
  sbc #1
  sta tmcolc
  lda tmcolc+1
  sbc #0
  sta tmcolc+1

  lda tmcol0
  bne delcps
  lda tmcol0+1
  bne delcps
  beq delcpu
delcps:
  lda tmcol0
  sec
  sbc #1
  sta tmcol0
  lda tmcol0+1
  sbc #0
  sta tmcol0+1
delcpu:
  jsr updscrn
  jsr redrawmap  
delcpd:
  rts

psetchr:
  lda tmcol0
  clc
  adc cursx
  sta tmcol
  lda tmcol0+1
  adc #0
  sta tmcol+2

  lda tmrow0
  clc
  adc cursy
  sta tmrow

  lda tmrow
  sec
  sbc #scrrow0
  sta tmrow

  lda #<chrtm
  sta tmptr
  lda #>chrtm
  sta tmptr+1
  lda sbchr
  sta newb
  jsr setbyte

  lda #<mdtm
  sta tmptr
  lda #>mdtm
  sta tmptr+1
  lda sbmd
  sta newb
  jsr setbyte  

  rts

mapp:
  lda ctidx
  sta sbchr
  ldx ctidx
  lda tsdata,x
  sta sbmd

  jsr psetchr
  jsr updscrn
  jsr redrawmap  
  rts

tsp:
  lda cursx
  sec
  sbc #(30+1)
  clc
  adc tsf
tspl:
  cpy #1
  beq tspd
  clc
  adc #8
  dey
  bne tspl
tspd:
  sta ctidx
  jsr settile
  jsr drawtile
  rts

tep:
  jsr modtile
  jsr settile
  jsr drawtile
  jsr lts
  rts

click:
  ldx cursx
  stx clickx
  ldy cursy
  sty clicky
  jsr onclick
clickd:
  rts

settile:
  ldx ctidx
  lda tsdata,X
  and #%00001000
  beq stsc
  ldy #0
  sty uimc
  ldy #rbonchr
  sty 1624+30
  bne stfgclr
stsc:
  ldy #1
  sty uimc
  ldy #rboffchr
  sty 1624+30
stfgclr:
  lda tsdata,X
  and #%00000111
  sta uifgclr
  sta 55936+30+3
stcl:
  lda tsdata,X
  bmi stclt
  ldy #1
  sty uicl
  ldy #rboffchr
  sty 1864+30+1
  bne stcr
stclt:
  ldy #0
  sty uicl
  ldy #rbonchr
  sty 1864+30+1
stcr:
  rol
  bmi stcrt
  ldy #1
  sty uicr
  ldy #rboffchr
  sty 1864+30+3
  bne stct
stcrt:
  ldy #0
  sty uicr
  ldy #rbonchr
  sty 1864+30+3
stct:
  rol
  bmi stctt
  ldy #1
  sty uict
  ldy #rboffchr
  sty 1864+30+5 
  bne stcb
stctt:
  ldy #0
  sty uict
  ldy #rbonchr
  sty 1864+30+5
stcb:
  rol
  bmi stcbt
  ldy #1
  sty uicb
  ldy #rboffchr
  sty 1864+30+7
  bne std
stcbt:
  ldy #0
  sty uicb
  ldy #rbonchr
  sty 1864+30+7
std:
  rts

setbrush:
  ldy uifgb
  beq sbfgt
  ldy #rboffchr
  sty 1744+30+1
  bne sbbg
sbfgt:
  ldy #rbonchr
  sty 1744+30+1
sbbg:
  ldy uibgb
  beq sbbgt
  ldy #rboffchr
  sty 1744+30+5
  bne sbc1
sbbgt:
  ldy #rbonchr
  sty 1744+30+5
sbc1:
  ldy uic1b
  beq sbc1t
  ldy #rboffchr
  sty 1784+30+1
  bne sbc2
sbc1t:
  ldy #rbonchr
  sty 1784+30+1
sbc2:
  ldy uic2b
  beq sbc2t
  ldy #rboffchr
  sty 1784+30+5
  bne sbd
sbc2t:
  ldy #rbonchr
  sty 1784+30+5
sbd:
  rts

// gets multicolor char
// given the bits stored in tmp0
// looks at first 2. outputs a
// char that is either full fg,bg,
// bgclr1,bgclr2 in A
getmcchr:
  lda #%11000000
  bit tmp0
  bmi getmccnt
  bvs getmccnfvt
  // if here, 00
  lda #emptychr
  jmp getmccd
getmccnfvt:
  // if here, 01
  lda #bgclr1chr
  jmp getmccd
getmccnt:
  bvs getmccntvt
  // if here, 10
  lda #bgclr2chr
  jmp getmccd
getmccntvt:
  // if here 11
  lda #filledchr
getmccd:
  rts

// sets fg of all tiles in
// tile edit area to the 
// selected color 
drawtilec:
  ToZPB($37,$d9,zpb0)
  ldx ctidx
  lda tsdata,X
  and #%00001111
  ldx #7
dtilecl1:
  ldy #7
dtilecl2:
  sta (zpb0),Y
  dey
  bpl dtilecl2
  dex
  bmi dtilecd
  jsr nscreenrow
  jmp dtilecl1
dtilecd:
  rts

// finds the memory location of
// the raw tile data in memory
// and stores it in zpb2
rawtile:
  ToZPB(<tiles,>tiles,zpb2)
  ldx ctidx
  beq rawtiled
rawtilel:
  lda zpb2
  clc
  adc #8
  sta zpb2
  bcc rawtileld
  inc zpb3
rawtileld:
  dex
  bne rawtilel
rawtiled:
  rts  

// updates the current tile display
drawtile:
  jsr drawtilec
  jsr rawtile
  ToZPB($37,$05,zpb0)

  ldx ctidx
  stx 1264+30+9
  lda tsdata,X
  ldx #0
  and #%00001111
  sta 55536+30+9
  and #%00001000
  bne dtmcl
dtscl:
  txa
  tay
  // for each byte in the tile
  lda (zpb2),Y
  ldy #7
dtscl2:
  // for each bit in the byte
  ror
  pha
  bcc dtscl2b
  lda #filledchr
  bne dtscl2c
dtscl2b:
  lda #emptychr
dtscl2c:
  sta (zpb0),Y
  pla
  dey
  bpl dtscl2
  inx
  cpx #8
  beq dtd
  jsr nscreenrow
  jmp dtscl
dtmcl:
  txa
  tay
  // for each byte in the tile
  lda (zpb2),Y
  sta tmp0
  ldy #0
dtmcl2:
  jsr getmcchr
  sta (zpb0),Y
  iny
  sta (zpb0),Y
  iny
  cpy #8
  beq dtmcl2n
  rol tmp0
  rol tmp0
  jmp dtmcl2
dtmcl2n:
  inx
  cpx #8
  beq dtd
  jsr nscreenrow
  jmp dtmcl  
dtd:
  rts    

// modifies the tile in memory that
// we are editing in tile mode
modtile:
  jsr rawtile
  lda cursy
  sec
  sbc #7
  tay
  sty tmp0
  lda (zpb2),Y
  pha
  lda cursx
  sec
  sbc #(30+1)
  tax
  stx zpb0
  stx tmp1
  pla
  sta tmp2
modtilel:
  dex
  bmi modtileld
  rol
  jmp modtilel
modtileld:
  and brushm
  ora brushp
  ldx zpb0
  beq modtilel2d
modtilel2:
  ror
  dex
  bne modtilel2
modtilel2d:
  sta (zpb2),Y
  rts

// sets A to zero if X,Y
// are inside the tile editor
// into the tile editor
inted:
  lda #1
  cpx #(30+1)
  bcc intedd
  cpx #39
  bcs intedd
  cpy #7
  bcc intedd
  cpy #15
  bcs intedd
  lda #0
intedd:
  rts

scspr:
  lda #192
  sta $07f8 //spr ptr
  lda #1
  sta cursmvx
  lda #8
  sta cursmvsprx
  rts

mcspr:
  lda #193
  sta $07f8 //spr ptr
  lda #2
  sta cursmvx
  lda #16
  sta cursmvsprx
  rts

mvcr:
  ldx cursx
  cpx #39
  beq mvcrd
  ldy cursy
  jsr inted
  sta tmp0
  sta zpb0 //in tile editor before
  txa
  clc
  adc cursmvx
  tax
  jsr inted
  sta tmp1
  sta zpb1 //in tile editor after

  lda zpb0
  clc
  rol
  ora zpb1
  sta tmp2

  // bit 1, after, bit 0 before
  // 00000010 // out to in
  // 00000001 // in to out
  // 00000011 // out to out
  // 00000000 // in to in
  cmp #%00000001
  beq mvcrio
  cmp #%00000010
  beq mvcroi
  bne mvcrmv
mvcrio:
  jsr scspr
  lda #80
  sta $d000 //spr0x
  lda #39
  sta cursx
  bne mvcrd  
mvcroi:
  lda uimc
  bne mvcrmv
  jsr mcspr
  lda #16
  sta $d000 //spr0x
  lda #(30+1)
  sta cursx
  bne mvcrd
mvcrmv:
  lda cursx
  clc
  adc cursmvx
  sta cursx
  lda $d000 //spr0x
  clc
  adc cursmvsprx
  sta $d000 
  bcc mvcrnw
  lda $d010 //spr msb
  ora #%00000001
  sta $d010 //spr msb  
mvcrnw:
mvcrd:
  rts

mvcl:
  ldx cursx
  cpx #0
  beq mvcld
  ldy cursy
  jsr inted
  sta tmp0
  sta zpb0 //in tile editor before
  txa
  sec
  sbc cursmvx
  tax
  jsr inted
  sta tmp1
  sta zpb1 //in tile editor after

  lda zpb0
  clc
  rol
  ora zpb1
  sta tmp2

  // bit 1, after, bit 0 before
  // 00000010 // out to in
  // 00000001 // in to out
  // 00000011 // out to out
  // 00000000 // in to in
  cmp #%00000001
  beq mvclio
  cmp #%00000010
  beq mvcloi
  bne mvclmv
mvclio:
  jsr scspr
  lda #8
  sta $d000 //spr0x
  lda #30
  sta cursx
  bne mvcld  
mvcloi:
  lda uimc
  bne mvclmv
  jsr mcspr
  lda #64
  sta $d000 //spr0x
  lda #37
  sta cursx
  bne mvcld
mvclmv:
  lda cursx
  sec
  sbc cursmvx
  sta cursx
  lda $d000 //spr0x
  sec
  sbc cursmvsprx
  sta $d000 //spr0x 
  bcs mvclnw
  lda $d010 //spr msb
  and #%11111110
  sta $d010  
mvclnw:
mvcld:
  rts

mvcu:
  ldy cursy
  cpy #0
  beq mvcud
  ldx cursx
  jsr inted
  sta tmp0
  sta zpb0 //in tile editor before
  dey
  jsr inted
  sta tmp1
  sta zpb1 //in tile editor after

  lda zpb0
  clc
  rol
  ora zpb1
  sta tmp2

  // bit 1, after, bit 0 before
  // 00000010 // out to in
  // 00000001 // in to out
  // 00000011 // out to out
  // 00000000 // in to in
  cmp #%00000001
  beq mvcuio
  cmp #%00000010
  beq mvcuoi
  bne mvcumv
mvcuio:
  jsr scspr
  jmp mvcumv 
mvcuoi:
  lda uimc
  bne mvcumv
  jsr mcspr
  lda cursx
  ror
  bcs mvcumv
  dec cursx
  lda $d000 //spr0x
  sec
  sbc #8
  sta $d000
mvcumv:
  lda $d001 //spr0y
  sec
  sbc #8
  sta $d001
  dec cursy
mvcud:
  rts

mvcd:
  ldy cursy
  cpy #24
  beq mvcdd
  ldx cursx
  jsr inted
  sta tmp0
  sta zpb0 //in tile editor before
  iny
  jsr inted
  sta tmp1
  sta zpb1 //in tile editor after

  lda zpb0
  clc
  rol
  ora zpb1
  sta tmp2

  // bit 1, after, bit 0 before
  // 00000010 // out to in
  // 00000001 // in to out
  // 00000011 // out to out
  // 00000000 // in to in
  cmp #%00000001
  beq mvcdio
  cmp #%00000010
  beq mvcdoi
  bne mvcdmv
mvcdio:
  jsr scspr
  jmp mvcdmv 
mvcdoi:
  lda uimc
  bne mvcdmv
  jsr mcspr
  lda cursx
  ror
  bcs mvcdmv
  dec cursx
  lda $d000 //spr0x
  sec
  sbc #8
  sta $d000
mvcdmv:
  lda $d001 //spr0y
  clc
  adc #8
  sta $d001
  inc cursy
mvcdd:
  rts

bgclrs:
  lda $d021
  and #%00001111
  cmp #15
  beq sclrw
  inc $d021
  jmp sclrd
sclrw:
  lda #0
  sta $d021
sclrd:
  rts

bgclr1s:
  lda $d022
  and #%00001111
  cmp #15
  beq bgclr1w
  inc $d022
  jmp bgclr1d
bgclr1w:
  lda #0
  sta $d022
bgclr1d:
  rts

bgclr2s:
  lda $d023
  and #%00001111
  cmp #15
  beq bgclr2w
  inc $d023
  jmp bgclr2d
bgclr2w:
  lda #0
  sta $d023
bgclr2d:
  rts

incfgclr:
  ldx ctidx
  lda tsdata,X
  pha
  and #%11111000 //save non clr bits 
  sta zpb0
  pla
  and #%00000111
  cmp #%00000111
  beq ifgcw
  clc
  adc #1
  bne ifgcu
ifgcw:
  lda #%00000000
ifgcu:
  ora zpb0
  sta tsdata,X
  rts

bgclrp:
  jsr bgclrs
  jsr redrawui
  jsr drawtile
  rts

bgclr1p:
  jsr bgclr1s
  jsr redrawui
  jsr drawtile
  rts

bgclr2p:
  jsr bgclr2s
  jsr redrawui
  jsr drawtile
  rts

mclrp:
  ldx ctidx
  lda tsdata,X
  eor #%00001000
  sta tsdata,X
  jsr settile
  jsr drawtile
  jsr lts
  jsr fgbp
  jsr setbrush
  rts

fgbp:
  lda uimc
  beq fgbpmc
  lda #%01111111
  sta brushm
  sta tmp1
  lda #%10000000
  sta brushp
  sta tmp2
  bne fgbpmcpd
fgbpmc:
  lda #%00111111
  sta brushm
  sta tmp1
  lda #%11000000
  sta brushp
  sta tmp2
fgbpmcpd:
  lda #0
  sta uifgb
  lda #1
  sta uic1b
  sta uibgb
  sta uic2b
  jsr setbrush
  rts

bgbp:
  lda uimc
  beq bgbpmc
  lda #%01111111
  sta brushm
  sta tmp1
  lda #%00000000
  sta brushp
  sta tmp2
  beq bgbpmcpd
bgbpmc:
  lda #%00111111
  sta brushm
  sta tmp1
  lda #%00000000
  sta brushp
  sta tmp2
bgbpmcpd:
  lda #0
  sta uibgb
  lda #1
  sta uic1b
  sta uifgb
  sta uic2b
  jsr setbrush
  rts

c1bp:
  lda uimc
  bne c1bpd
  lda #%00111111
  sta brushm
  sta tmp1
  lda #%01000000
  sta brushp
  sta tmp2
  lda #0
  sta uic1b
  lda #1
  sta uifgb
  sta uibgb
  sta uic2b
  jsr setbrush
c1bpd:
  rts

c2bp:
  lda uimc
  bne c2bpd
  lda #%00111111
  sta brushm
  sta tmp1
  lda #%10000000
  sta brushp
  sta tmp2
  lda #0
  sta uic2b
  lda #1
  sta uifgb
  sta uibgb
  sta uic1b
  jsr setbrush
c2bpd:
  rts

fgcp:
  jsr incfgclr
  jsr settile
  jsr drawtile
  jsr lts
  rts

clp:
  ldx ctidx
  lda tsdata,X
  eor #%10000000
  sta tsdata,X
  jsr settile
  rts

crp:
  ldx ctidx
  lda tsdata,X
  eor #%01000000
  sta tsdata,X
  jsr settile
  rts

ctp:
  ldx ctidx
  lda tsdata,X
  eor #%00100000
  sta tsdata,X
  jsr settile
  rts

cbp:
  ldx ctidx
  lda tsdata,X
  eor #%00010000
  sta tsdata,X
  jsr settile
  rts

tssup:
  lda tsf
  beq tssupd
  sec
  sbc #8
  sta tsf
  jsr lts
tssupd:
  rts

tssdp:
  lda tsf
  cmp #224
  beq tssdpd
  clc
  adc #8
  sta tsf
  jsr lts
tssdpd:
  rts


maplp:
  jsr gettm
  lda time
  sta ptime
  lda time+1
  sta ptime+1
  lda time+2
  sta ptime+2

  jsr mvmr
  jsr gettm

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

maprp:
  jsr gettm
  lda time
  sta ptime
  lda time+1
  sta ptime+1
  lda time+2
  sta ptime+2

  jsr mvml
  jsr gettm

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
mapup:
  jsr mvmu
  jsr redraw
  rts
mapdp:
  jsr mvmd
  jsr redraw
  rts

delchrp:
  lda cursx
  cmp #29
  bcs delchrpd
  lda cursy
  cmp #2
  bcc delchrpd
  cmp #24
  bcs delchrpd

  lda #emptychr
  sta sbchr
  lda #1
  sta sbmd
  jsr psetchr
  jsr updscrn
  jsr redrawmap  
delchrpd:
  rts

newp:
  jsr clearinput
  YesNo(strsure,newpd)
  lda #3
  sta tmrow0
  lda #0
  sta tmcol0
  sta tmcol0+1

  ldx #0
  lda #1
newpl:
  sta tsdata,X
  inx
  bne newpl
  
  jsr initchrs
  jsr emptyscrn
  jsr redrawmap
  jsr lts
  jsr settile
  jsr drawtile
  jsr fgbp
  jsr setbrush
newpd:
  jsr clearinput
  jsr redrawinput
  rts

// in its own subroutine just
// so we can time it
redraw:
  jsr gettm
  lda time
  sta ptime
  lda time+1
  sta ptime+1
  lda time+2
  sta ptime+2

  jsr drawscrn
  jsr gettm

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

gettm:
  jsr $ffde
  sty time+2
  stx time+1
  sta time
  rts

// modifies zpb0,zpb1,zpb2,zpb3,A,Y,X
fnamein:
  lda #<strfname
  sta zpb0
  lda #>strfname
  sta zpb1
  ldy #0
fnsl:
  lda (zpb0),y
  beq fnsld
  sta $0400,y
  iny
  bne fnsl
fnsld:
  tya
  clc
  adc #1
  sta zpb2 // used to prevent too many del key presses

  // show the previous file name if set
  ldx #0
fnslprev:
  cpx fnamelen
  beq fnslprevd
  lda fname,x
  jsr petsciitosc
  sta $0400,y
  iny
  inx
  jmp fnslprev
fnslprevd:

  // read in file name
fnslin:
  lda #filledchr
  sta $0400,y

  sty fnametmp0
  stx fnametmp1
  jsr $ffe4 // modifies x,y
  ldy fnametmp0
  ldx fnametmp1
  cmp #3
  beq fnslincancel
  cmp #13
  beq fnslinret
  cmp #20
  beq fnsldel
  cmp #48
  bcc fnslin
  cmp #59
  bcc fnslvalid
  cmp #64
  bcc fnslin
  cmp #91
  bcc fnslvalid
  bcs fnslin
fnslvalid:
  sta fname,x
  inx
  jsr petsciitosc
  sta $0400,y
  iny
  jmp fnslin
fnsldel:
  cpy zpb2
  bcc fnslin
  lda #emptychr
  sta $0400,y
  dey
  dex
  jmp fnslin
fnslinret:
  cpx #0
  beq fnslincancel
  stx fnamelen
  lda #0
  sta fnameres
  jmp fnd
fnslincancel:
  ldx #0
  stx fnamelen
  lda #1
  sta fnameres
fnd:
  rts

loadp:
  jsr clearinput
  YesNo(strsure,loadpf)

  // todo use verify on LOAD to only
  // save files that changed
  jsr clearinput
  jsr fnamein
  lda fnameres
  beq loadpt
  jmp loadd

loadpf:
  jmp loadd
loadpt:
  // move the cursor to row 2, column 0
  ldx #2
  ldy #0
  clc
  jsr $fff0

  lda fnamelen
  pha

  ldx #9
  stx fdev

  // load main data
  lda #<(filedatas-2)
  sta zpb0
  lda #>(filedatas-2)
  sta zpb1 
  jsr fload
  lda fstatus
  bne loaderr


  // load the char map
  // set file name, append a "C" to the end of the name
  ldx fnamelen
  lda #67 // C
  sta fname,x

  inc fnamelen

  lda #<(chrtmdatas-2)
  sta zpb0
  lda #>(chrtmdatas-2)
  sta zpb1 
  jsr fload
  lda fstatus
  bne loaderr

  // load the metadata map
  dec fnamelen
  // set file name, append a "M" to the end of the name
  ldx fnamelen
  lda #77 // M
  sta fname,x

  inc fnamelen

  lda #<(mdtmdatas-2)
  sta zpb0
  lda #>(mdtmdatas-2)
  sta zpb1 
  jsr fload
  lda fstatus
  bne loaderr

  lda #25
  sta tmrowc
  lda #3
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
  jsr error
  jsr emptyscrn
loadd:
  pla
  sta fnamelen

  jsr updscrn
  jsr drawscrn
  jsr redrawui
  jsr settile
  jsr drawtile
  jsr fgbp
  jsr setbrush
  rts



savep:
  // todo use verify on LOAD to only
  // save files that changed
  jsr clearinput
  jsr fnamein
  lda fnameres
  beq savept
  jmp saved

savept:
  // move the cursor to row 2, column 0
  ldx #2
  ldy #0
  clc
  jsr $fff0

  // todo allow other devices
  // set device info
  lda #15
  ldx #9
  ldy #1
  jsr $ffba

  // save the main file with tileset data, tile info, run info, etc

  // set the file name
  lda fnamelen
  ldx #<fname
  ldy #>fname
  jsr $ffbd

  // set the start location of the save
  lda #<filedatas
  sta zpb0
  lda #>filedatas
  sta zpb1

  // set the end location of the save
  ldx #<(filedatae-1)
  ldy #>(filedatae-1)

  // save the file
  lda #zpb0
  jsr $ffd8

  // check for errors
  jsr $ffb7
  and #%10111111
  beq saveok
  jmp saveerr

saveok:
  // close the file
  lda #15
  jsr $ffc3

  // now save the char map
  // set file name, append a "C" to the end of the name
  ldx fnamelen
  lda #67 // C
  sta fname,x
  txa
  clc
  adc #1
  ldx #<fname
  ldy #>fname
  jsr $ffbd

  // set the start location of the save
  lda #<chrtmdatas
  sta zpb0
  lda #>chrtmdatas
  sta zpb1

  // set the end location of the save
  ldy #2
  lda chrtm,y // last run
  clc
  adc #1
  tax
  iny
  lda chrtm,y
  adc #0
  tay

  // save the file
  lda #zpb0
  jsr $ffd8

  // check for errors
  jsr $ffb7
  and #%10111111
  bne saveerr

  // close the file
  lda #15
  jsr $ffc3

  // now save the metadata map
  // set file name, append a "C" to the end of the name
  ldx fnamelen
  lda #77 // M
  sta fname,x
  txa
  clc
  adc #1
  ldx #<fname
  ldy #>fname
  jsr $ffbd

  // set the start location of the save
  lda #<mdtmdatas
  sta zpb0
  lda #>mdtmdatas
  sta zpb1

  // set the end location of the save
  ldy #2
  lda mdtm,y // last run
  clc
  adc #1
  tax
  iny
  lda mdtm,y
  adc #0
  tay

  // save the file
  lda #zpb0
  jsr $ffd8

  // check for errors
  jsr $ffb7
  and #%10111111
  bne saveerr

  // close the file
  lda #15
  jsr $ffc3
  jmp saved
saveerr:
  jsr error
  // close the file if it was open...
  lda #15
  jsr $ffc3
saved:
  jsr updscrn
  jsr drawscrn
  jsr redrawui
  rts

// inputs
//  zpb0 x location clicked
//  zpb1 y location clicked
//  eventi info about event
//    that triggered this
onclick:
  pha
  txa
  pha
  ldx #0
oncll:
  cpx #(uise-uiss)
  beq oncld
  lda #1
  sta $7900
  lda #%10000000
  bit eventi
  bpl onclnor

  lda #2
  sta $7901
  // repeat click
  lda uiss+4,X
  and #%10000000
  cmp #%10000000
  bne oncln
onclnor:
  lda #3
  sta $7902
  lda clickx
  cmp uiss,X
  bcc oncln //clickx <startx
  cmp uiss+2,X
  bcs oncln //clickx >=endx+1
  lda clicky
  cmp uiss+1,X
  bcc oncln //clicky <starty
  cmp uiss+3,X
  bcs oncln //clicky >=endy+1
onclh:
  lda #4
  sta $7903
  txa
  pha
  lda #>(onclr-1)
  pha
  lda #<(onclr-1)
  pha
  lda uiss+6,X
  pha
  lda uiss+5,X
  pha
  rts
onclr:
  pla
  tax
  jmp oncld
oncln:
  inx
  inx
  inx
  inx
  inx
  inx
  inx
  bne oncll
oncld:
  pla
  tax
  pla
  rts

initevents:
  lda #$ff
  ldx #0
iel:
  cpx #(ebse-ebss)
  beq ied
  sta ebss,X
  inx
  inx
  inx
  bne iel
ied:
  rts

events:
  ldx #0
evl:
  cpx #(ebse-ebss)
  beq evd
  // if pressed for 6 frames
  // or first press, accept
  lda ebss,X
  and #%00111111
  beq evhr
  and #%00000011
  cmp #%00000010
  beq evhf
  bne evn
evhr:
  lda #%10000000
  sta eventi
  bne evh
evhf:
  lda #%00000000
  sta eventi
evh:
  txa
  pha
  lda #>(evr-1)
  pha
  lda #<(evr-1)
  pha
  lda ebss+2,X
  pha
  lda ebss+1,X
  pha
  rts
evr:
  pla
  tax
evn:
  inx
  inx
  inx
  bne evl
evd:
  rts

inkb:
  jsr $ffe4
  //cmp #64 //@
  //beq ikbsave
  //cmp #42 //*
  //beq ikbload
  cmp #20 // delete
  beq ikbdel
  cmp #43 //+
  beq ikbpl
  cmp #45 //-
  beq ikbmi
  jmp inkbd
ikbdel:
  jsr delchrp
  jmp inkbd
ikbpl:
  jsr addcp
  jmp inkbd
ikbmi:
  jsr delcp
//ikbsave
//  //jsr settings
//  jmp inkbd
//ikbload
//  //jsr load
inkbd:
  rts

// read a joystick
// inputs
//   A - joystick port value
// outputs
//   X - direction x
//    $ff=left,$00=none,$01-right
//   Y - direction y
//    $ff=up,$00=none,$01=down
//   C - fire, $00 if firing
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
  rol ebc
  rts





// index (0-255) in char index of
// currently selected tileset tile
ctidx:  .byte 0

cursx:  .byte 0
cursy:  .byte 0

//brush pattern and mask
brushm: .byte 0
brushp: .byte 0

cursmvsprx:  .byte 0
cursmvx:     .byte 0
curstedmaxx: .byte 0

// amount to move left or right
// in tile mode movement based
// on multicolor mode being set
ctmvsprx: .byte 0 //sprite
ctmvx:    .byte 0 //selector

//tmp vars
tmp0:     .byte 0
tmp1:     .byte 0
tmp2:     .byte 0

ptime:    .byte 0,0,0
etime:    .byte 0,0,0
time:     .byte 0,0,0

//multicolor
uimc:     .byte 0
uifgclr:  .byte 0
// collide left,right,top,bottom
uicl:     .byte 0
uicr:     .byte 0
uict:     .byte 0
uicb:     .byte 0
//brushes
uifgb:    .byte 0
uibgb:    .byte 0
uic1b:    .byte 0
uic2b:    .byte 0

// set byte char and metadata
sbchr: .byte 0
sbmd:  .byte 0

//logy:      .byte 0
//logtmp0:   .byte 0
//logtmp1:   .byte 0
//logtmp2:   .byte 0
//logtmp3:   .byte 0


//click event format
// startx,starty,endx+1,endy+1
// click info
//   bit 7 - 1 if allow repeats
// addresses of handlers
uiss:
  .byte 4,1,5,2,0,<(bgclrp-1),>(bgclrp-1)
  .byte 10,1,11,2,0,<(bgclr1p-1),>(bgclr1p-1)
  .byte 16,1,17,2,0,<(bgclr2p-1),>(bgclr2p-1)
  .byte 30,15,31,16,0,<(mclrp-1),>(mclrp-1)
  .byte 31,18,32,19,0,<(fgbp-1),>(fgbp-1)
  .byte 35,18,36,19,0,<(bgbp-1),>(bgbp-1)
  .byte 31,19,32,20,0,<(c1bp-1),>(c1bp-1)
  .byte 35,19,36,20,0,<(c2bp-1),>(c2bp-1)
  .byte 30,16,31,17,0,<(fgcp-1),>(fgcp-1)
  .byte 31,21,32,22,0,<(clp-1),>(clp-1)
  .byte 33,21,34,22,0,<(crp-1),>(crp-1)
  .byte 35,21,36,22,0,<(ctp-1),>(ctp-1)
  .byte 37,21,38,22,0,<(cbp-1),>(cbp-1)
  .byte 39,1,40,2,128,<(tssup-1),>(tssup-1)
  .byte 39,4,40,5,128,<(tssdp-1),>(tssdp-1)
  .byte 0,2,29,24,128,<(mapp-1),>(mapp-1)
  .byte 29,2,30,3,128,<(mapup-1),>(mapup-1)
  .byte 29,23,30,24,128,<(mapdp-1),>(mapdp-1)
  .byte 0,24,1,25,128,<(maplp-1),>(maplp-1)
  .byte 28,24,29,25,128,<(maprp-1),>(maprp-1)
  .byte 31,1,39,5,0,<(tsp-1),>(tsp-1)
  .byte 31,7,39,16,0,<(tep-1),>(tep-1) 
  .byte 0,0,5,1,128,<(newp-1),>(newp-1)
  .byte 6,0,12,1,128,<(loadp-1),>(loadp-1)
  .byte 13,0,19,1,128,<(savep-1),>(savep-1)
uise:


// event buffers for joystick
// format:
//   byte 0 event buffer
//   handler addresses
ebss:
ebl: .byte 0,<(mvcl-1),>(mvcl-1)
ebr: .byte 0,<(mvcr-1),>(mvcr-1)
ebu: .byte 0,<(mvcu-1),>(mvcu-1)
ebd: .byte 0,<(mvcd-1),>(mvcd-1)
ebc: .byte 0,<(click-1),>(click-1)
ebse:

// coords of click event
// that triggered onclick
clickx:  .byte 0
clicky:  .byte 0
// info about current event
// being handled
// bit7 - 1=repeat,0=first 
eventi: .byte 0

// index of first tile to show in
// tileset tile selector
tsf:    .byte 0

cfg:    .byte 1,0,0,0,0,0,7,0,1,1,1,1,1,0,1,1
ch:     .byte 4,5,1,5,1,1,5,6,0,0,0,0,0,1,0,0

// fg, h color
fghclr: .byte 0,0

devnum:    .byte 9
fnameres:  .byte 0
fnametmp0: .byte 0
fnametmp1: .byte 0

// file name, ts.d
//fnts  .byte 84,83,46,68
//fntsd .byte 84,83,68,46,68
//fnchr .byte 67,72,82,46,68
//fnmd  .byte 77,68,46,68
//fnmde

