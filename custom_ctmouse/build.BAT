tasm /m @asmlib.cfg ctmouse.asm
tlink /t /x ctmouse.obj,ctmouse.exe
com2exe -s512 ctmouse.exe ctmouse.exe
