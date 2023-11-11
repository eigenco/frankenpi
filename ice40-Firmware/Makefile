all:
	yosys -p "synth_ice40 -top top -blif top.blif -json top.json" top.v
	nextpnr-ice40 --pcf-allow-unconstrained --hx1k --json top.json --pcf pins.pcf --asc top.asc
	icepack top.asc top.bin
	rm top.asc
	rm top.blif
	rm top.json
clean:
	rm top.bin
	rm rom.bin
