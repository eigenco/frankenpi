import os

os.system('nasmw -fbin int13.asm -o int13.bin')

file = open("int13.bin", "rb")
binary = file.read(-1)
y = 0
for x in range(32767):
	y = (y + binary[x]) & 255
file.close()
print(y)

binary = list(binary)
binary[-1] = 256 - y

file = open("trident.bin", "wb")
file.write(bytearray(binary))
file.close()

file = open("vgabios.bin", "wb")
bin = bytearray([0]*32768)
for x in range(16384):
	bin[x] = binary[2*x]
	bin[x+16384] = binary[2*x+1]
file.write(bin)
file.close()

os.system('copy /b vgabios.bin+vgabios.bin vgabx2.bin')