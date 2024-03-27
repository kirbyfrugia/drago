
// copy one region of memory to another, assumes num bytes > 0
// inputs
//   $fb src lo byte
//   $fc src hi byte
//   $fd dest lo byte
//   $fe dest hi byte
//   $bb num bytes lo byte
//   $bc num bytes hi byte
copy:
  pha
  tya
  pha

  ldy #0
copyl:
  lda ($fb),y
  sta ($fd),y

  lda $bb
  sec
  sbc #1
  sta $bb
  lda $bc
  sbc #0
  sta $bc
  bne copyln
  lda $bb
  bne copyln
  beq copyld
copyln:
  iny
  bne copyl
  inc $fc
  inc $fe
  jmp copyl
copyld:
  pla
  tay
  pla  
  rts

// copies address to loc in zpb
.macro ToZPB(lo,hi,zpblo) {
  lda #lo
  sta zpblo
  lda #hi
  sta zpblo+1
}

// ADD MACRO
//   lda @P1
//   clc
//   adc @P2
//   sta @P1
//   ENDM

// SUB MACRO
//   lda @P1
//   sec
//   sbc @P2
//   sta @P1
//   ENDM

// used to "debounce" events.
// triggers if the key or button 
// is held for 6 frames or it just
// got pressed.
// @P1 byte used for event buffer
// @P2 label to jsr to if triggered
.macro Debounce(ebbyte,jsrlabel) {
  // if pressed for six frames
  // or first press, accept//
  lda ebbyte
  and #%00111111
  beq dbh
  and #%00111111
  cmp #%00111110
  beq dbh
  bne dbno 
dbh:
  lda #%11111110
  sta ebbyte
  jsr jsrlabel
dbno:
}

// updates the address in zpb0
// to the next row
nscreenrow:
  pha
  lda zpb0
  clc
  adc #40
  sta zpb0
  bcc nscreenrowd
  inc zpb1  
nscreenrowd:
  pla
  rts

// @P1 key code
// @P2 event buffer byte
// @P3 label for line following this
.macro InKBD(keycode,ebbyte,jmplabel) {
  cmp #keycode
  bne koff
  clc
  rol ebbyte
  jmp jmplabel
koff:
  sec
  rol ebbyte
}

//logs a hexit value A to zpb0 offset
//by Y
//Y will be incremented 
loghexit:
  pha
  ror
  ror
  ror
  ror
  and #%00001111
  cmp #10
  bcc lhd1
  bcs lhcd1
lhd1:
  clc
  adc #48 //zero
  sta (zpb0),Y
  jmp loghexit2
lhcd1:
  clc
  adc #1 //A
  sec
  sbc #10
  sta (zpb0),Y
loghexit2:
  iny
  pla
  pha
  and #%00001111
  cmp #10
  bcc lhd2
  bcs lhcd2
lhd2:
  clc
  adc #48 //zero
  sta (zpb0),Y
  jmp loghexitd
lhcd2:
  clc
  adc #1 //A
  sec
  sbc #10
  sta (zpb0),Y
loghexitd:
  pla
  rts

// prints null terminated
// at zpb0 to location zpb2
ps:
  pha
  tya
  pha
  ldy #0
psl:
  lda (zpb0),Y
  beq psld
  sta (zpb2),Y
  iny
  bne psl
psld:
  pla
  tay
  pla
  rts

// colors null terminated string
// at zpb0 to location zpb2
// to color in X.
cs:
  pha
  tya
  pha
  ldy #0
csl:
  lda (zpb0),Y
  beq csld
  txa
  sta (zpb2),Y
  iny
  bne csl
csld:
  pla
  tay
  pla
  rts
 
