file = open("tvga9000i - D4.01E.bin", "rb")
binary = file.read(-1)
file.close()

file = open("tvexp.bin", "wb")
binar = bytearray([0]*32768)
for x in range(16384):
	binar[2*x] = binary[x]
	binar[2*x+1] = binary[x+16384]
file.write(binar)
file.close()