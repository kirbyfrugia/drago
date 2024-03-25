//mapeddata.asm

//plchr     = 243
//mchr      = 244
.var lchr      = 245
.var rchr      = 246
.var upchr     = 247
.var downchr   = 248
.var vbarchr   = 249
.var rboffchr  = 250
.var rbonchr   = 251
.var emptychr  = 252
.var filledchr = 253
.var bgclr1chr = 254
.var bgclr2chr = 255

sprbox8x8:
  .byte $ff,$00,$00
  .byte $81,$00,$00
  .byte $81,$00,$00
  .byte $81,$00,$00
  .byte $81,$00,$00
  .byte $81,$00,$00
  .byte $81,$00,$00
  .byte $ff,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00

sprbox16x8:
  .byte $ff,$ff,$00
  .byte $80,$01,$00
  .byte $80,$01,$00
  .byte $80,$01,$00
  .byte $80,$01,$00
  .byte $80,$01,$00
  .byte $80,$01,$00
  .byte $ff,$ff,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00,$00,$00
  .byte $00


//MAP ^ BG  ^ C1  ^ C2
strmapl:    .byte 13,1,16,32,247,32,2,7,32,32,247,254,3,49,32,32,247,255,3,50,0
//TILES
strtiles:   .byte 20,9,12,5,19,0
//EDIT TILE
strtile:    .byte 5,4,9,20,32,20,9,12,5,0
//oMULTICLR
strmc:      .byte 250,13,21,12,20,9,3,12,18,0
//BRUSH
strbrush:   .byte 2,18,21,19,8,0
//^FG<>
strfg:      .byte 247,6,7,253,0
// oFG oBG
strfgbg:    .byte 32,250,6,7,32,250,2,7,0
// oC1 oC2
strc1c2:    .byte 32,250,3,49,32,250,3,50,0
//COLLIDE
strcoll:    .byte 3,15,12,12,9,4,5,0
// oLoRoToB
strlrtb:    .byte 32,250,12,250,18,250,20,250,2,0
//FILE NAMES
strfn:      .byte 6,9,12,5,32,14,1,13,5,19,0
//TILESET:
strtsf:     .byte 20,9,12,5,19,5,20,58,32,0
//TILEINFO:
strtif:     .byte 20,9,12,5,9,14,6,15,58,32,0
//LEVEL:
strlvlf:    .byte 12,5,22,5,12,58,32,0
//[NEW]:
strnew:    .byte 27,14,5,23,29,0
//[SAVE]:
strsave:    .byte 27,19,1,22,5,29,0
//[LOAD]:
strload:    .byte 27,12,15,1,4,29,0
           
