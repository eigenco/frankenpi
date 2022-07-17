file = open("int13.bin", "rb")
binary = file.read(-1)
y = 0
for x in range(32768):
	y = (y + binary[x]) & 255
file.close()
print(y)

# empty area begins at 7d68
# original jump was to 4F (EB4A 37 3430)