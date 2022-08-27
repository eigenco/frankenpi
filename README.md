# frankenpi

What currently works (to some degree), i.e. PC can access through ISA
- Mass storage from a file on the Raspberry Pi, both reading (from file) and writing (to memory)
- Adlib data and reverse audio data back from Raspberry Pi to optical SPDIF (adlib works pretty much perfectly)
- Sound Blaster 8-bit mono with DMA and IRQ, simultaneously to optical SPDIF (with limitations)
- Gravis Ultrasound forward fed wavetable functions and simultaneous feed back to optical SPDIF (rather limited compatibility, read below, no DMA/IRQ)

This is an experimental project to connect Raspberry Pi with the help of cheap Cyclone IV board to 8-bit ISA bus to act as multiple different devices.

Hdd works, including writing, adlib and pcm through SPDIF works. DMA and IRQ works. Some detection issues remain.

Cleaned up the verilogs (c4.v) a bit and the server code running on Raspberry Pi (pc.c) as well.

Forward feed of data to GUS works and audio data backwards to SPDIF, but GUS as it stands now isn't really detected by anything and there is no backwards flow of data which prevents some many things from working correctly. The 669 player with source here can demo. Sound quality is quite beautiful compared to SB with all the interpolation.

Remember to set video BIOS shadow on in BIOS to gain a lot in hdd speed.

Currently RP can act as hard disk using an image and the PC can boot with the help of hacked VGABIOS that installs a custom int 13h. This way one doesn't need any other cards in the BUS except VGA adapter and the frankenpi.

Hard disk access is currently handled such that the image file is loaded to the memory and writes are only to the memory so changes won't be permanent if you cut power (this was intentional to protect my testing phase). However, it would be easy to modify the service to flush the changes back to the memory card either upon request or every time.

Youtube link here: https://www.youtube.com/watch?v=1ej76w8sHxY

TESTED and working:
- Wolfenstein 3D (SB & Adlib)
- Scream Tracker 3.21 (SB1 only)
- Skyroads (SB & Adlib)
- Keen 4 (Adlib)
- Monkey Island (Adlib)
- Space Quest 3 (Adlib)
- Lotus 3 (Adlib)
- Lemmings (Adlib)
- 669 player (GUS)

Planned
- General MIDI
- Roland MT-32 support
- Sound Blaster AWE32 wavetable support
- Mouse support through Raspberry Pi USB
