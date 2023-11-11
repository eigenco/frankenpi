import struct
import sys
import RPi.GPIO as GPIO
import fcntl
from time import sleep

sleep(0.3)
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
for channel in range(10):
        GPIO.setup(channel, GPIO.OUT)

kbd = open('/dev/input/event0', 'rb')
fcntl.ioctl(kbd, 1074021776, True)
evnt = kbd.read(24)

GPIO.output(0, 1)
GPIO.output(1, 0)
GPIO.output(2, 0)
GPIO.output(3, 0)
GPIO.output(4, 0)
GPIO.output(5, 0)
GPIO.output(6, 0)
GPIO.output(7, 0)
GPIO.output(8, 1)
GPIO.output(8, 0)

while evnt:
	(a, b, type, code, value) = struct.unpack('llHHI', evnt)
	if type==1 and value<2:
		if code==88: # F12
			fcntl.ioctl(kbd, 1074021776, False)
			sys.exit(0)
		if code==0x66: code = 0x47
		if code==0x67: code = 0x48
		if code==0x68: code = 0x49
		if code==0x69: code = 0x4b
		if code==0x6a: code = 0x4d
		if code==0x6b: code = 0x4f
		if code==0x6c: code = 0x50
		if code==0x6d: code = 0x51
		if code==0x6e: code = 0x52
		if code==0x6f: code = 0x53
		if value==0:
			GPIO.output(0, code & 1)
			GPIO.output(1, code & 2)
			GPIO.output(2, code & 4)
			GPIO.output(3, code & 8)
			GPIO.output(4, code & 16)
			GPIO.output(5, code & 32)
			GPIO.output(6, code & 64)
			GPIO.output(7, 1)
		else:
			GPIO.output(0, code & 1)
			GPIO.output(1, code & 2)
			GPIO.output(2, code & 4)
			GPIO.output(3, code & 8)
			GPIO.output(4, code & 16)
			GPIO.output(5, code & 32)
			GPIO.output(6, code & 64)
			GPIO.output(7, 0)
		GPIO.output(9, 1)
		GPIO.output(9, 0)
	evnt = kbd.read(24)
