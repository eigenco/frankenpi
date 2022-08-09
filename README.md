# frankenpi

This is an experimental project to connect Raspberry Pi with the help of cheap Cyclone IV board to 8-bit ISA bus to act as multiple different devices.

The only fully working HDD read and write routines (verilog and asm) are in the "hdd" directory now. Many things were rewritten, but spdif/adlib is now incomplete with this rewrite. The next version will stream the adlib data from Raspberry Pi to the FPGA which will output it along with the DMA sourced pcm to spdif.

Remember to set video BIOS shadow on in BIOS to gain a lot in hdd speed.

Currently RP can act as hard disk using an image and the PC can boot with the help of hacked VGABIOS that installs a custom int 13h. This way one doesn't need any other cards in the BUS except VGA adapter and the frankenpi.

Hard disk access is currently handled such that the image file is loaded to the memory and writes are only to the memory so changes won't be permanent if you cut power (this was intentional to protect my testing phase). However, it would be easy to modify the service to flush the changes back to the memory card either upon request or every time.

Adlib emulation is also working through the Pi.

Some preliminary work to support PCM through Sound Blaster/DMA and SPDIF has also been done, but these are somewhat buggy still.

Youtube link here: https://www.youtube.com/watch?v=1ej76w8sHxY
