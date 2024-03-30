
#!/bin/sh

java -jar KickAss.jar drago.asm -log bin/drago_BuildLog.txt -o bin/drago.prg -vicesymbols -showmem -odir bin && x64sc -logfile /home/kirby/src/drago/bin/drago_ViceLog.txt -moncommands /home/kirby/src/drago/bin/drago.vs -9 /home/kirby/src/drago/drago.d64 /home/kirby/src/drago/bin/drago.prg

