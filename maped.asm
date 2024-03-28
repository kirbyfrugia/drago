//maped.s

  //*= $0801 "Basic Upstart"
  //BasicUpstart(init)

  *=$8000 "MapEd"

  jmp init

#import "const.asm"
#import "mapeddata.asm"
#import "utils.asm"
#import "mapui.asm"
#import "tm.asm"
#import "tme.asm"

init:

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
  jsr mvmd
  jsr redraw
  rts
mapdp:
  jsr mvmu
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



//////////////////////////////////////////////////////////////////////////////
// this chunk of memory is used for file loading and saving. Do not change
// the order or size of any of it and don't put anything after it!!!
//////////////////////////////////////////////////////////////////////////////
  *=$2000
filedatas:
tiles:
  *=$2800
tsdata:       .fill 256,0
chrtm:    
chrtmrun0:    .byte 0,0
chrtmrunlast: .byte 0,0
chrtmcolc:    .byte 0,0
mdtm:    
mdtmrun0:     .byte 0,0
mdtmrunlast:  .byte 0,0
mdtmcolc:     .byte 0,0
bgclr:        .byte 0
bgclr1:       .byte 0
bgclr2:       .byte 0
filedatae:

  *=$4000
chrtmdatas:
  *=$5fff
chrtmdatae:

  *=$6000
mdtmdatas:
  *=$7fff
mdtmdatae:
//////////////////////////////////////////////////////////////////////////////
// no touchie!!!
//////////////////////////////////////////////////////////////////////////////

