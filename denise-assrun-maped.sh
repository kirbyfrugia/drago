#!/bin/sh
java -jar KickAss.jar maped.asm -log bin/maped_BuildLog.txt -o bin/maped.prg -vicesymbols -showmem -odir bin && denise -attach9 ./drago.d64 ./bin/maped.prg
