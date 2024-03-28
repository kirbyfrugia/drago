//mapui.s

.var scrcol0   = 0
.var scrwidth  = 29
.var scrrow0   = 2
.var scrheight = 22

// displays a Yes/No question on the input line with the provided null terminated str, e.g.
// <str><cursor>
// branches to nohandler if the user doesn't answer "Y", otherwise will continue onto the line after the macro.
// modifies Y, zpb0,zpb1
.macro YesNo (str,nohandler) {
  lda #<str
  sta zpb0
  lda #>str
  sta zpb1
  ldy #0
yesnostr:
  lda (zpb0),y
  beq yesnostrd
  sta $0400,y
  iny
  bne yesnostr
yesnostrd:
  iny
yesnoin:
  // get input
  jsr $ffe4
  cmp #89 // Y
  beq yes
  cmp #78
  beq nohandler
  bne yesnoin
yes:
}

// displays an error based on error in A. Pressing return will continue.
// modifies A,zpb0-3
error:
  pha
  lda #<strerror
  sta zpb0
  lda #>strerror
  sta zpb1
  ldy #0
errstrl:
  lda (zpb0),Y
  beq errstrld
  sta $0400,Y
  iny
  bne errstrl
errstrld:

  lda #$00
  sta zpb0
  lda #$04
  sta zpb1
  pla
  jsr loghexit
  iny
  lda #emptychr
  sta $0400,y
  iny

  tya
  sta zpb2
  lda zpb1
  sta zpb3

  lda #<strcont
  sta zpb0
  lda #>strcont
  sta zpb1
  ldy #0
contstrl:
  lda (zpb0),Y
  beq contstrld
  sta (zpb2),Y
  iny
  bne contstrl
contstrld:
errorin:
  // get input
  jsr $ffe4
  cmp #13
  bne errorin
  rts

// converts a screen code to petscii, assuming it's @ : 0-9 A-Z
// inputs: A
sctopetscii:
  cmp #27
  bcs sctoptd

  clc
  adc #64
sctoptd:
  rts

// converts petscii to a screencode, assuming it's @ : 0-9 A-Z
// inputs: A
petsciitosc:
  cmp #59
  bcc ptoscd

  // alpha char or @
  sec
  sbc #64
ptoscd:
  rts

// modifies zpb0,zpb1,zpb2,zpb3,A,Y,X
filenamein:
  lda #<strfilen
  sta zpb0
  lda #>strfilen
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
  cpx filenlen
  beq fnslprevd
  lda filen,x
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

  sty filentmp0
  stx filentmp1
  jsr $ffe4 // modifies x,y
  ldy filentmp0
  ldx filentmp1
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
  sta filen,x
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
  stx filenlen
  lda #0
  sta filenres
  jmp fnd
fnslincancel:
  ldx #0
  stx filenlen
  lda #1
  sta filenres
fnd:
  rts

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

loadp:
  jsr clearinput
  YesNo(strsure,loadpf)

  // todo use verify on LOAD to only
  // save files that changed
  jsr clearinput
  jsr filenamein
  lda filenres
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

  // todo allow other devices
  // set device info
  lda #15
  ldx #9
  ldy #0
  jsr $ffba

  // load the main file with tileset data, tile info, run info, etc
  // set the file name
  lda filenlen
  ldx #<filen
  ldy #>filen
  jsr $ffbd

  // set the start location of the load
  ldx #<filedatas
  ldy #>filedatas

  // load the file
  lda #0
  jsr $ffd5

  // check for errors
  jsr $ffb7
  and #%10111111
  beq loadok
  jmp loaderr
loadok:
  // close the file
  lda #15
  jsr $ffc3


  // load the char map
  // set file name, append a "C" to the end of the name
  ldx filenlen
  lda #67 // C
  sta filen,x
  txa
  clc
  adc #1
  ldx #<filen
  ldy #>filen
  jsr $ffbd

  // set the location to load to (x,y)
  ldy #0
  lda chrtm,y
  tax
  iny
  lda chrtm,y
  tay

  // load the file
  lda #0
  jsr $ffd5

  // check for errors
  jsr $ffb7
  and #%10111111
  bne loaderr

  // close the file
  lda #15
  jsr $ffc3

  // load the metadata map
  // set file name, append a "C" to the end of the name
  ldx filenlen
  lda #77 // M
  sta filen,x
  txa
  clc
  adc #1
  ldx #<filen
  ldy #>filen
  jsr $ffbd

  // set the location to load to (x,y)
  ldy #0
  lda mdtm,y
  tax
  iny
  lda mdtm,y
  tay

  // load the file
  lda #0
  jsr $ffd5

  // check for errors
  jsr $ffb7
  and #%10111111
  bne loaderr

  // close the file
  lda #15
  jsr $ffc3

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
  // close the file if it was open...
  lda #15
  jsr $ffc3
  jsr emptyscrn
loadd:
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
  jsr filenamein
  lda filenres
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
  lda filenlen
  ldx #<filen
  ldy #>filen
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
  ldx filenlen
  lda #67 // C
  sta filen,x
  txa
  clc
  adc #1
  ldx #<filen
  ldy #>filen
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
  ldx filenlen
  lda #77 // M
  sta filen,x
  txa
  clc
  adc #1
  ldx #<filen
  ldy #>filen
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
filen:     .fill 17,0
filenres:  .byte 0
filenlen:  .byte 0
filentmp0: .byte 0
filentmp1: .byte 0

// file name, ts.d
//fnts  .byte 84,83,46,68
//fntsd .byte 84,83,68,46,68
//fnchr .byte 67,72,82,46,68
//fnmd  .byte 77,68,46,68
//fnmde
