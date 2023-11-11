import os
import RPi.GPIO as GPIO
import spidev
from time import sleep

GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
for channel in [0,1,2,3,4,5,6,7,8,9,25,27]:
	GPIO.setup(channel, GPIO.OUT)
	GPIO.output(channel, 0)

# compile BIOS
os.system('nasm -O0 -fbin rom.asm -o rom.bin')
file = open("rom.bin", "rb")
data = file.read(-1)
data = bytearray(data)
file.close()

# write FPGA bitstream via SPI
GPIO.output(27, 1)
file = open("top.bin", "rb")
bitstream = file.read(-1)
file.close()
spi = spidev.SpiDev(0, 0)
spi.xfer3(bitstream)
spi.xfer3(bytearray([0,0,0,0,0,0,0]))
spi.close()

# set RESET
GPIO.output(8, 1)

# write BIOS ROM
for x in range(1024):
	GPIO.output(0, (data[x]>>0)&1)
	GPIO.output(1, (data[x]>>1)&1)
	GPIO.output(2, (data[x]>>2)&1)
	GPIO.output(3, (data[x]>>3)&1)
	GPIO.output(4, (data[x]>>4)&1)
	GPIO.output(5, (data[x]>>5)&1)
	GPIO.output(6, (data[x]>>6)&1)
	GPIO.output(7, (data[x]>>7)&1)
	GPIO.output(9, 1)
	GPIO.output(9, 0)

# clear RESET
GPIO.output(0, 0)
GPIO.output(1, 0)
GPIO.output(2, 0)
GPIO.output(3, 0)
GPIO.output(4, 0)
GPIO.output(5, 0)
GPIO.output(6, 0)
GPIO.output(7, 0)
GPIO.output(8, 0)
