file = open("int13.bin", "rb")
binary = file.read(-1)
file.close()

file = open("int13i.bin", "wb")
binar = bytearray([0]*32768)
for x in range(16384):
	binar[x] = binary[2*x]
	binar[x+16384] = binary[2*x+1]
file.write(binar)
file.close()