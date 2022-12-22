import os

os.system('nasmw -fbin int13.asm -o int13.bin')

file = open("int13.bin", "rb")
binary = file.read(-1)
y = 0
for x in range(2047):
	y = (y + binary[x]) & 255
file.close()
print(y)

binary = list(binary)
binary[-1] = 256 - y

file = open("optROM.bin", "wb")
file.write(bytearray(binary))
file.close()

os.system('srec_cat.exe optROM.bin -binary -output optrom.hex -Intel')