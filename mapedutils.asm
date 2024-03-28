
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


