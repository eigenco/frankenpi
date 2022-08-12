# frankenpi

This is an experimental project to connect Raspberry Pi with the help of cheap Cyclone IV board to 8-bit ISA bus to act as multiple different devices.

Hdd works fully, including writing, adlib and pcm through SPDIF works now (wolf3d works fully). DMA and IRQ implemented. Some detection issues remain.

Remember to set video BIOS shadow on in BIOS to gain a lot in hdd speed.

Currently RP can act as hard disk using an image and the PC can boot with the help of hacked VGABIOS that installs a custom int 13h. This way one doesn't need any other cards in the BUS except VGA adapter and the frankenpi.

Hard disk access is currently handled such that the image file is loaded to the memory and writes are only to the memory so changes won't be permanent if you cut power (this was intentional to protect my testing phase). However, it would be easy to modify the service to flush the changes back to the memory card either upon request or every time.

Youtube link here: https://www.youtube.com/watch?v=1ej76w8sHxY
