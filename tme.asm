//tme.s

// tilemap edit routines
.var tmptr  = $59 // and $5a
.var pptr   = $5b // and $5c
.var nptr   = $5d // and $5e

// indirectly writes a value @P1 at the
// location of @P2 offset by @P3. A and 
// are modified.
.macro IndirectWrite(value,location,offset){
  lda value
  ldy #offset
  sta (location),Y
}

// reads a value into A at location @P1
// offset by @P2
.macro IndirectRead(location,offset){
  ldy #offset
  lda (location),Y
}

// adds a column and copies the char
// from the previous column
// inputs:
//   tmcol offset from 0,16bit
//     cols will be added after
//     this one. must be less than
//     the number of columns
addcol:
  pha
  tya
  pha
  lda zpb0
  pha
  lda zpb1
  pha

  IndirectRead(tmptr,0) //run0 lo
  sta tmrptr
  IndirectRead(tmptr,1) //run0 hi
  sta tmrptr+1

  lda tmcol
  sta offsetlo
  lda tmcol+1
  sta offsethi

  // todo modify this to use X instead of zpb0
  lda #25
  sta zpb0

  ReadRun(tmrptr)
acl:
  jsr seek2
  lda tmrb
  sta newb

  // can add to current
  lda tmrl
  cmp #$ff
  bcc acatcr

  jsr getinfo

  // can add to prev
  lda bi
  and #%01000000
  cmp #%01000000
  beq acatpr

  // can add to next
  lda bi
  and #%00000010
  cmp #%00000010
  beq acatnr

  // no room in this run and it either doesn't match the next one or there's no room in that one either
  jsr addrun
  // seek ahead 1 since we're adding a char
  lda #1
  sta offsetlo
  jsr seek2
  jmp acnl
acatcr:
  ldy #0
  lda (tmrptr),Y
  clc
  adc #1
  sta (tmrptr),Y
  inc tmrl
  jmp acnl
acatpr:
  ldy #0
  lda (pptr),Y
  clc
  adc #1
  sta (pptr),Y
  jmp acnl
acatnr:
  ldy #0
  lda (nptr),Y
  clc
  adc #1
  sta (nptr),Y
  // seek ahead 1 since we're adding a char
  lda #1
  sta offsetlo
  jsr seek2
acnl:
  ldy #4
  lda (tmptr),Y
  sta offsetlo
  iny
  lda (tmptr),Y
  sta offsethi

  lda zpb0
  sec
  sbc #1
  sta zpb0
  beq acld
  jmp acl  
acld:
  ldy #4
  lda (tmptr),Y
  clc
  adc #1
  sta (tmptr),Y
  iny
  lda (tmptr),Y
  adc #0
  sta (tmptr),Y

  jsr compress
  pla
  sta zpb1
  pla
  sta zpb0
  pla
  tay
  pla
  rts

// deletes a column
// inputs:
//   tmcol offset from 0,16bit
delcol:
  pha
  tya
  pha

  IndirectRead(tmptr,0) //run0 lo
  sta tmrptr
  IndirectRead(tmptr,1) //run0 hi
  sta tmrptr+1

  lda tmcol
  sta offsetlo
  lda tmcol+1
  sta offsethi

  ldx #25

  ReadRun(tmrptr)
dcl:
  jsr seek2
  ldy #0
  lda (tmrptr),Y
  sec
  sbc #1
  sta (tmrptr),Y
  //jsr decrun

  dex
  beq dcld

  ldy #4
  lda (tmptr),Y
  //sec
  //sbc #1
  sta offsetlo
  iny
  lda (tmptr),Y
  //sbc #0
  sta offsethi

  jmp dcl  
dcld:
  ldy #4
  lda (tmptr),Y
  sec
  sbc #1
  sta (tmptr),Y
  iny
  lda (tmptr),Y
  sbc #0
  sta (tmptr),Y

  jsr compress
  pla
  tay
  pla
  rts

getinfo:
  pha
  lda zpb0
  pha
  lda zpb1
  pha

  lda #%00000000
  sta bi

  lda tmbl
  bne gichkf

  // last byte in a run
  lda bi
  ora #%00000001
  sta bi
  // no branch here on purpose
gichkf:
  lda tmrl
  sec
  sbc tmbl
  cmp #1
  bne gichkprev

  // first byte in a run
  lda bi
  ora #%10000000
  sta bi
gichkprev:
  jsr peekprev
  bcs gichknext
  lda newb
  cmp prb
  bne gichknext
  lda prl
  cmp #$ff
  beq gichknext

  // matches prev byte and
  // there is room to add
  // this one
  lda bi
  ora #%01000000
  sta bi
gichknext:
  jsr peeknext
  bcs gichkrl1
  lda newb
  cmp nrb
  bne gichkrl1
  lda nrl
  cmp #$ff
  beq gichkrl1

  // matches next byte
  // and room for this one
  lda bi
  ora #%00000010
  sta bi
gichkrl1:
  lda tmrl
  cmp #1
  bne gichklr
  // run length 1
  lda bi
  ora #%00100000
  sta bi
gichklr:
  jsr peeknext
  bcc getinfod

  // last run
  lda bi
  ora #%00000100
  sta bi
getinfod:
  pla
  sta zpb1
  pla
  sta zpb0
  pla
  rts

// sets the byte at the given row
// and column to this byte
setbyte:
  pha
  tya
  pha

  IndirectRead(tmptr,0)
  sta tmrptr
  IndirectRead(tmptr,1)
  sta tmrptr+1

  ReadRun(tmrptr)
  jsr calcoffset
  jsr seek2
  //READB tmrptr,sb0
  
  lda newb
  cmp tmrb
  bne sbtests
  jmp setbyted
sbtests:
  jsr getinfo

  // single byte run,
  // doesn't match prev or next
  lda bi
  and #%01100010
  cmp #%00100000
  beq sbsb

  // last byte in run,
  // can add to next
  lda bi
  and #%00000011
  cmp #%00000011
  beq sblan

  // first byte in run,
  // can add to prev
  lda bi
  and #%11000000
  cmp #%11000000
  beq sbfap

  // first byte in run,
  // can't add to previous
  lda bi
  and #%11000000
  cmp #%10000000
  beq sbfnap

  // last byte in run,
  // end of all runs
  lda bi
  and #%00000101
  cmp #%00000101
  beq sbleor

  // last byte in run, no match
  lda bi
  and #%00000111
  cmp #%00000001
  beq sblnm

  jmp sbmnm
sbsb:
  ldy #1
  lda newb
  sta (tmrptr),Y
  jmp setbyted
sblan:
  inc nrl
  IndirectWrite(nrl,nptr,0)
  jsr decrun
  jmp setbyted
sbfap:
  inc prl
  IndirectWrite(prl,pptr,0)
  jsr decrun
  jmp setbyted
sbfnap:
  jsr decrun
  lda #1
  sta numb
  jsr insertrun
  jmp setbyted
sbleor:
  jsr decrun
  lda #1
  sta numb
  jsr appendrun
  jmp setbyted
sblnm:
  lda #1
  sta numb
  jsr addrun
  jsr decrun
  jmp setbyted
sbmnm:
  lda newb
  sta sb0
  lda tmrb
  sta sb1
  lda tmbl
  sta sb2
  lda tmrl
  sta sb3

  // post-char split
  ldy #0
  lda sb2
  sta (tmrptr),Y

  // new char
  lda #1
  sta numb
  lda sb0
  sta newb
  jsr insertrun
  
  // pre char split
  lda sb3
  sec
  sbc sb2
  sta numb
  lda tmrb
  sta newb
  jsr insertrun
  jsr decrun
setbyted:
  jsr compress
  pla
  tay
  pla

  rts

// there are some scenarios where we end up with a larger number of runs than there should be.
// example:
//   5,A,1,B,10,A
//   if we change the B to an A, it will merge with the first and will become:
//   6,A,10,A
//   instead it should be 16A
// this routine will clean this kind of thing up. 
compress:
  pha
  tya
  pha
  lda zpb0
  pha
  lda zpb1
  pha

  IndirectRead(tmptr,0)
  sta tmrptr
  IndirectRead(tmptr,1)
  sta tmrptr+1

cmprl:
  // todo this doesn't handle the case where the last run is zero length
  jsr peeknext
  bcs cmprd

  ldy #0
  lda (tmrptr),Y
  beq cmprldel
  cmp #255
  beq cmprln
  iny
  lda (tmrptr),Y
  cmp nrb
  bne cmprln

  // if here, the next runbyte  matches and we can copy some  of the run here
  ldy #0
  lda (tmrptr),Y
  clc
  adc nrl
  bcs cmprlw

  // no wrap, absorb next. next run will get deleted next loop
  sta (tmrptr),Y
  ldy #2
  lda #0
  sta (tmrptr),Y 
  beq cmprln
cmprlw:
  // wrapped portion (+1) is new length of next run. current run is 255.
  ldy #2
  adc #0 // add the carry 
  sta (tmrptr),Y
  ldy #0 
  lda #255
  sta (tmrptr),Y
  bne cmprln
cmprldel:
  // zero length run
  jsr deleterun
  jmp cmprl // don't inc
cmprln:
  lda tmrptr
  clc
  adc #2
  sta tmrptr
  lda tmrptr+1
  adc #0
  sta tmrptr+1
  jmp cmprl
cmprd:
  pla
  sta zpb1
  pla
  sta zpb0
  pla
  tay
  pla
  rts

// decrement curr run by one
// and delete if zero
decrun:
  pha
  tya
  pha

  ldy #0
  lda (tmrptr),Y
  sec
  sbc #1
  sta (tmrptr),Y
  bne decrund
  jsr deleterun   
decrund:
  pla
  tay
  pla
  rts

deleterun:
  pha
  tya
  pha
  lda zpb0
  pha
  lda zpb1
  pha

  IndirectRead(tmptr,2) //last run lo
  sta drlr
  IndirectRead(tmptr,3) //last run hi
  sta drlr+1

  lda tmrptr
  sta zpb0
  lda tmrptr+1
  sta zpb1
drl:
  lda zpb0
  cmp drlr
  bne drlc
  lda zpb1
  cmp drlr+1
  bne drlc
  jmp drd
drlc:
  ldy #2
  lda (zpb0),Y
  ldy #0
  sta (zpb0),Y
  
  ldy #3
  lda (zpb0),Y
  ldy #1
  sta (zpb0),Y

  lda zpb0
  clc
  adc #2
  sta zpb0
  lda zpb1
  adc #0
  sta zpb1

  jmp drl
drd:
  ldy #2 // last run lo
  lda (tmptr),Y
  sec
  sbc #2
  sta (tmptr),Y
  iny
  lda (tmptr),Y
  sbc #0
  sta (tmptr),Y

  // update pointers
  ReadRun(tmrptr)
  jsr peeknext
  jsr peekprev

  pla
  sta zpb1
  pla
  sta zpb0
  pla
  tay
  pla
  rts

// adds a run after the current with run length 1
// inputs
//   newb the run byte
addrun:
  pha
  tya
  pha
  lda zpb0
  pha
  lda zpb1
  pha

  IndirectRead(tmptr,2) //last run lo
  sta zpb0
  IndirectRead(tmptr,3) //last run hi
  sta zpb1

  jsr peeknext
arl:
  ldy #0
  lda (zpb0),Y
  ldy #2
  sta (zpb0),Y

  ldy #1
  lda (zpb0),Y
  ldy #3
  sta (zpb0),Y
 
  lda zpb0
  cmp nptr
  bne arln
  lda zpb1
  cmp nptr+1
  bne arln
  jmp arld
arln:
  lda zpb0
  sec
  sbc #2
  sta zpb0
  lda zpb1
  sbc #0
  sta zpb1
  jmp arl
arld:
  ldy #0
  lda #1
  sta (zpb0),Y
  iny
  lda newb
  sta (zpb0),Y

  ldy #2
  lda (tmptr),Y
  clc
  adc #2
  sta (tmptr),Y
  iny
  lda (tmptr),Y
  adc #0
  sta (tmptr),Y

  pla
  sta zpb1
  pla
  sta zpb0
  pla
  tay
  pla
  rts

// inserts a run at the current index
// inputs
//   newb the run byte
//   numb the run length
insertrun:
  pha
  tya
  pha
  lda zpb0
  pha
  lda zpb1
  pha

  IndirectRead(tmptr,2) //last run lo
  sta zpb0
  IndirectRead(tmptr,3) //last run hi
  sta zpb1
irl:
  ldy #0
  lda (zpb0),Y
  ldy #2
  sta (zpb0),Y

  ldy #1
  lda (zpb0),Y
  ldy #3
  sta (zpb0),Y
 
  lda zpb0
  cmp tmrptr
  bne irln
  lda zpb1
  cmp tmrptr+1
  bne irln
  jmp irld
irln:
  lda zpb0
  sec
  sbc #2
  sta zpb0
  lda zpb1
  sbc #0
  sta zpb1
  jmp irl
irld:
  ldy #0
  lda numb
  sta (tmrptr),Y
  iny
  lda newb
  sta (tmrptr),Y

  ldy #2
  lda (tmptr),Y
  clc
  adc #2
  sta (tmptr),Y
  iny
  lda (tmptr),Y
  adc #0
  sta (tmptr),Y

  pla
  sta zpb1
  pla
  sta zpb0
  pla
  tay
  pla
  rts

// inputs
//   newb the run byte
//   numb the number of bytes
appendrun:
  pha
  tya
  pha
  lda zpb0
  pha
  lda zpb1
  pha 
  
  ldy #2
  lda (tmptr),Y //last run
  clc
  adc #2
  sta (tmptr),Y
  sta zpb0
  iny
  lda (tmptr),Y
  adc #0
  sta (tmptr),Y
  sta zpb1

  ldy #0
  lda numb
  sta (zpb0),Y
  iny
  lda newb
  sta (zpb0),Y

  pla
  sta zpb1
  pla
  sta zpb0
  pla
  tay
  pla
  rts

// peeks at the previous run
// outputs
//   prunllo/hi is location of prev
//   prb the byte
//   C will be set if at start
peekprev:
  pha
  tya
  pha
  lda tmrptr
  sec
  sbc #2
  sta pptr
  lda tmrptr+1
  sbc #0
  sta pptr+1

  IndirectRead(tmptr,0) //first run lo
  sta pkrun
  IndirectRead(tmptr,1) //first run hi
  sta pkrun+1

  lda pptr+1
  cmp pkrun+1
  bcc peekprevw
  lda pptr
  cmp pkrun
  bcc peekprevw

  ldy #0
  lda (pptr),Y
  sta prl
  iny
  lda (pptr),Y
  sta prb
  clc
  jmp peekprevd
peekprevw:
  sec
peekprevd:
  pla
  tay
  pla
  rts

// peeks at the next run
// outputs
//   nrunlo/hi is location of next
//   nrb the byte
//   C will be set if at end of runs
peeknext:
  pha
  tya
  pha

  lda tmrptr
  clc
  adc #2
  sta nptr
  lda tmrptr+1
  adc #0
  sta nptr+1

  IndirectRead(tmptr,2) //last run lo
  sta pkrun
  IndirectRead(tmptr,3) //last run hi
  sta pkrun+1

  // no overflow if last run >= new
  lda pkrun+1
  cmp nptr+1
  bcc pknovft // <
  bne pknovff // >
  lda pkrun
  cmp nptr
  bcs pknovff
pknovft:
  // overflow true
  sec
  bcs peeknextd
pknovff:
  // overflow false
  ldy #0
  lda (nptr),Y
  sta nrl
  iny
  lda (nptr),Y
  sta nrb
  clc
peeknextd:
  pla
  tay
  pla
  rts

// API vars
tmcol:    .byte 0,0
tmrow:    .byte 0,0
numcols:  .byte 0,0   

// internal vars, do not reference
// directly
bi:       .byte 0
// prev byte
prb:      .byte 0
prl:      .byte 0
// next byte
nrb:      .byte 0
nrl:      .byte 0

// vars used to insert/append
newb:     .byte 0
numb:     .byte 0

// add column local vars
acoffset: .byte 0
// delete run temp vars
drlr:     .byte 0,0
// peek prev/next temp vars
pkrun:    .byte 0,0
sb0:      .byte 0
sb1:      .byte 0
sb2:      .byte 0
sb3:      .byte 0
ac0:      .byte 0
