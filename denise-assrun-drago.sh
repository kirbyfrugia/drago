#!/bin/sh
java -jar KickAss.jar drago.asm -log bin/drago_BuildLog.txt -o bin/drago.prg -vicesymbols -showmem -odir bin && denise -attach9 ./drago.d64 ./bin/drago.prg
