.var scrcol0   = 0
.var scrwidth  = 29
.var scrrow0   = 2
.var scrheight = 22

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


//////////////////////////////////////////////////////////////////////////////
// warning: these areas of memory are used for file loading and saving.
// Do not change the order or size of any of it.
//////////////////////////////////////////////////////////////////////////////
.var filedatas    = $2000
.var tiles        = $2000
.var tsdata       = $2800
.var chrtm        = $2900
.var chrtmrun0    = $2900
.var chrtmrunlast = $2902
.var chrtmcolc    = $2904
.var mdtm         = $2906
.var mdtmrun0     = $2906
.var mdtmrunlast  = $2908
.var mdtmcolc     = $290a
.var bgclr        = $290c
.var bgclr1       = $290d
.var bgclr2       = $290e
.var filedatae    = $290e

.var chrtmdatas   = $4000
.var chrtmdatae   = $5fff
.var mdtmdatas    = $6000
.var mdtmdatae    = $7fff
//////////////////////////////////////////////////////////////////////////////
// see warning above
//////////////////////////////////////////////////////////////////////////////

