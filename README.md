# frankenpi

This is an experimental project to connect Raspberry Pi with the help of cheap Cyclone IV FPGA board to 8-bit ISA bus to act as multiple different devices.

What is currently implemented (to some degree), i.e. PC can access through ISA
- Mass storage access from a file on the Raspberry Pi (flushed every 2 seconds by default)
- Adlib output to optical SPDIF
- Sound Blaster 8-bit mono with DMA and IRQ (basic functions only), output to optical SPDIF
- Gravis Ultrasound (basic wavetable only), output to optical SPDIF
- USB mouse plugged into the Raspberry Pi will appear as a kind of serial mouse in DOS, custom ctmouse driver is provided
- Boot from custom TVGA9000i VGABIOS, i.e. no other devices are required to be present in the ISA bus besides FrakenPi and VGA-adapter

Youtube link here: https://www.youtube.com/watch?v=1ej76w8sHxY

TESTED and working:
- Wolfenstein 3D (SB & Adlib)
- Second Reality (GUS)
- Scream Tracker 3.21 (SB1 and GUS)
- Skyroads (SB & Adlib)
- Keen 4 (Adlib)
- Monkey Island (Adlib/Mouse)
- Space Quest 3 (Adlib/Mouse)
- Space Quest 4 (Adlib/Mouse)
- Lotus 3 (Adlib)
- Lemmings (Adlib/Mouse)
- Eye of the Beholder I & II (Adlib/Mouse)
- Indiana Jones and the Fate of Atlantis (Adlib/Mouse)

Planned
- General MIDI
- Roland MT-32 support
- Sound Blaster AWE32 wavetable support
- Compatibility improvements
- Boot ROM in the FPGA so hacked VGABIOS isn't required
