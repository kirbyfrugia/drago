Install vice via apt.

Download Vice source.

Copy ROMs like this:
sudo cp ~/Downloads/vice-3.8/data/C64/kernal-901227-03.bin /usr/share/vice/C64/kernal
sudo cp ~/Downloads/vice-3.8/data/C64/chargen-901225-01.bin /usr/share/vice/C64/chargen
sudo cp ~/Downloads/vice-3.8/data/C64/basic-901226-01.bin /usr/share/vice/C64/basic
sudo cp ~/Downloads/vice-3.8/data/DRIVES/dos1541-325302-01+901229-05.bin /usr/share/vice/DRIVES/dos1541

Running:
sudo x64sc

Open Settings -> Machine -> ROM
* Configure anything as needed.

Open Settings -> Peripheral devices -> Drive and set drive type for Drive 8 and Drive 9.


For Assembler stuff:
https://goatpower.org/projects-releases/sublime-package-kick-assembler-c64/kick-assembler-c64-installation-guide-for-linux/

https://goatpower.org/projects-releases/sublime-package-kick-assembler-c64/

Syntax highlighting for vim: https://github.com/gryf/kickass-syntax-vim