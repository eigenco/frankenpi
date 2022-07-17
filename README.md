# frankenpi

This is an experimental project to connect Raspberry Pi with the help of cheap Cyclone IV board to 8-bit ISA bus to act as multiple different devices.

Currently RP can act as hard disk using an image and the PC can boot with the help of hacked VGABIOS that installs a custom int 13h. This way one doesn't need any other cards in the BUS except VGA adapter and the frankenpi.
Adlib emulation is also working through the Pi.
Some preliminary work to support PCB through Sound Blaster and optical SPDIF has also been done, but these are not yet working.

Ultimately I probably want to modify the arrangement so that the FPGA will serve BIOS extension instead of having to rely on hacked VGABIOS for booting.

Youtube link here: 
