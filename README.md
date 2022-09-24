# frankenpi

This is an experimental project to connect Raspberry Pi with the help of cheap Cyclone IV FPGA board to 8-bit ISA bus to act as multiple different devices.

What is currently implemented (to some degree), i.e. PC can access through ISA
- Mass storage access from a file on the Raspberry Pi (written sectors are flushed every 2 seconds by default)
- Adlib output to optical SPDIF
- Sound Blaster 8-bit mono with DMA and IRQ (basic functions only), output to optical SPDIF
- Gravis Ultrasound (basic wavetable only), output to optical SPDIF
- Roland MT-32 (UART only), output to optical SPDIF
- USB mouse plugged into the Raspberry Pi will appear as a kind of serial mouse in DOS, custom ctmouse driver is provided (start with /v)
- Boot from custom TVGA9000i VGABIOS, i.e. no other devices are required to be present in the ISA bus besides FrakenPi and VGA-adapter

Youtube links:

https://www.youtube.com/watch?v=1ej76w8sHxY

https://www.youtube.com/watch?v=CkwgHHmKaSI

TESTED and working:
- Wolfenstein 3D (SB & Adlib)
- Second Reality (GUS)
- Scream Tracker 3.21 (SB1 and GUS)
- Skyroads (SB & Adlib)
- Keen 4 (Adlib)
- Monkey Island (Adlib/MT32/Mouse)
- Space Quest 3 (Adlib/Mouse)
- Space Quest 4 (Adlib/MT32/Mouse)
- Lotus 3 (Adlib)
- Lemmings (Adlib/Mouse)
- Eye of the Beholder I & II (Adlib/Mouse)
- Indiana Jones and the Fate of Atlantis (Adlib/MT32/Mouse)

Planned
- General MIDI
- MPU-401 support
- Sound Blaster AWE32 wavetable support
- Standard ATA at ports 1f0h-1f7h
- Compatibility improvements
- Boot ROM in the FPGA so hacked VGABIOS isn't required

Used resources
- Harddisk: ports 170h-171h
- SoundBlaster: ports 22ah-22eh corresponding ot base address of 220h, IRQ 7 and DMA 1
- MT32: 330h-331h
- Gravis Ultrasound: ports 341h-347h corresponding to base address of 240h
- Adlib: ports 388h-389h (standard)
- Mouse: port 3f8h and IRQ 4 (COM1)
- Bootcode for custom int 13h resides in hacked VGABIOS at the end of C0000-C7FFF memory region

Further explanation
- Outgoing port operations are transferred from the FPGA to the Raspberry Pi GPIO using dedicated unidirectional 8-bit data bus
- Incoming data from the Raspberry Pi GPIO (PCM, harddisk, mouse) is transferred using dedicated unidirectional 8-bit data bus
- Raspberry Pi: CPU0 handles hdd flushing and mouse, CPU1 handles GPIO transfers, CPU2 handles Adlib, Gravis Ultrasound and MT32 (software selected)
- Raspberry Pi operates with CPU1-CPU3 in isolated mode, all CPUs run at constant 1 GHz and sched_rt_runtime_us is -1
- Raspberry Pi generates sound data 64 samples at a time (16-bit stereo corresponds to 256 bytes it must transfer every 1.45ms or so)
- SPDIF is running in 24-bit 44100 Hz Stereo
- Hardcoded harddisk type is CHS 256/16/63, i.e. approx. 126MiB
