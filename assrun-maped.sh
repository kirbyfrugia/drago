
#!/bin/sh

java -jar KickAss.jar maped.asm -log bin/maped_BuildLog.txt -o bin/maped.prg -vicesymbols -showmem -odir bin && x64sc -logfile /home/kirby/src/drago/bin/maped_ViceLog.txt -moncommands /home/kirby/src/drago/bin/maped.vs  /home/kirby/src/drago/bin/maped.prg

