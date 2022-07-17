EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
Text GLabel 7000 1600 2    50   BiDi ~ 0
D0
Text GLabel 7000 1500 2    50   BiDi ~ 0
D1
Text GLabel 7000 1400 2    50   BiDi ~ 0
D2
Text GLabel 7000 1300 2    50   BiDi ~ 0
D3
Text GLabel 7000 1200 2    50   BiDi ~ 0
D4
Text GLabel 7000 1100 2    50   BiDi ~ 0
D5
Text GLabel 7000 1000 2    50   BiDi ~ 0
D6
Text GLabel 7000 900  2    50   BiDi ~ 0
D7
Text GLabel 7000 3800 2    50   Output ~ 0
A0
Text GLabel 7000 3700 2    50   Output ~ 0
A1
Text GLabel 7000 3600 2    50   Output ~ 0
A2
Text GLabel 7000 3500 2    50   Output ~ 0
A3
Text GLabel 7000 3400 2    50   Output ~ 0
A4
Text GLabel 7000 3300 2    50   Output ~ 0
A5
Text GLabel 7000 3200 2    50   Output ~ 0
A6
Text GLabel 7000 3100 2    50   Output ~ 0
A7
Text GLabel 7000 3000 2    50   Output ~ 0
A8
Text GLabel 7000 2900 2    50   Output ~ 0
A9
Text GLabel 5600 3800 0    50   UnSpc ~ 0
GND
Text GLabel 5600 3600 0    50   UnSpc ~ 0
VCC
Text GLabel 5600 1000 0    50   UnSpc ~ 0
VCC
Text GLabel 5600 1700 0    50   UnSpc ~ 0
GND
Text GLabel 5600 800  0    50   UnSpc ~ 0
GND
Text GLabel 5600 2100 0    50   Output ~ 0
~IOR
Text GLabel 5600 2000 0    50   Output ~ 0
~IOW
$Comp
L Connector:Bus_ISA_8bit J5
U 1 1 60DD7EBA
P 6300 2300
F 0 "J5" H 6300 4067 50  0000 C CNN
F 1 "Bus_ISA_8bit" H 6300 3976 50  0000 C CNN
F 2 "adlib:BUS_PC" H 6300 2300 50  0001 C CNN
F 3 "https://en.wikipedia.org/wiki/Industry_Standard_Architecture" H 6300 2300 50  0001 C CNN
	1    6300 2300
	1    0    0    -1  
$EndComp
Text GLabel 5600 1800 0    50   Output ~ 0
~MEMW
Text GLabel 5600 1900 0    50   Output ~ 0
~MEMR
Text GLabel 3625 750  2    50   UnSpc ~ 0
GND
Text GLabel 3625 2575 2    50   UnSpc ~ 0
VCC
Text GLabel 7000 1800 2    50   UnSpc ~ 0
AEN
Text GLabel 1650 1775 2    50   BiDi ~ 0
D7
Text GLabel 1650 1875 2    50   BiDi ~ 0
D6
Text GLabel 1650 1975 2    50   BiDi ~ 0
D5
Text GLabel 1650 2075 2    50   BiDi ~ 0
D4
Text GLabel 1650 2175 2    50   BiDi ~ 0
D3
Text GLabel 1650 2275 2    50   BiDi ~ 0
D2
Text GLabel 1650 2375 2    50   BiDi ~ 0
D1
Text GLabel 1650 2475 2    50   BiDi ~ 0
D0
Text GLabel 1650 1350 2    50   Input ~ 0
A9
Text GLabel 1650 1450 2    50   Input ~ 0
A8
Text GLabel 1150 1450 0    50   Input ~ 0
A7
Text GLabel 1150 1350 0    50   Input ~ 0
A6
Text GLabel 1150 1250 0    50   Input ~ 0
A5
Text GLabel 1150 1150 0    50   Input ~ 0
A4
Text GLabel 1150 1050 0    50   Input ~ 0
A3
Text GLabel 1150 950  0    50   Input ~ 0
A2
Text GLabel 1150 850  0    50   Input ~ 0
A1
Text GLabel 1150 750  0    50   Input ~ 0
A0
Text GLabel 3125 2375 0    50   Input ~ 0
~IOR
Text GLabel 3625 2375 2    50   Input ~ 0
~IOW
Text GLabel 3125 2475 0    50   Input ~ 0
~MEMR
Text GLabel 3625 2475 2    50   Input ~ 0
~MEMW
Text GLabel 3125 2575 0    50   UnSpc ~ 0
GND
Text GLabel 3125 750  0    50   UnSpc ~ 0
GND
$Comp
L Connector_Generic:Conn_02x08_Odd_Even J1
U 1 1 61AB2F3E
P 1350 1050
F 0 "J1" H 1400 1567 50  0000 C CNN
F 1 "Conn_02x08_Odd_Even" H 1400 1476 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x08_P2.54mm_Vertical" H 1350 1050 50  0001 C CNN
F 3 "~" H 1350 1050 50  0001 C CNN
	1    1350 1050
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_02x08_Odd_Even J3
U 1 1 61AB48FD
P 1350 2075
F 0 "J3" H 1400 2592 50  0000 C CNN
F 1 "Conn_02x08_Odd_Even" H 1400 2501 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x08_P2.54mm_Vertical" H 1350 2075 50  0001 C CNN
F 3 "~" H 1350 2075 50  0001 C CNN
	1    1350 2075
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_02x08_Odd_Even J2
U 1 1 61AB892D
P 3325 1050
F 0 "J2" H 3375 1567 50  0000 C CNN
F 1 "Conn_02x08_Odd_Even" H 3375 1476 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x08_P2.54mm_Vertical" H 3325 1050 50  0001 C CNN
F 3 "~" H 3325 1050 50  0001 C CNN
	1    3325 1050
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_02x09_Odd_Even J4
U 1 1 61AB979A
P 3325 2175
F 0 "J4" H 3375 2792 50  0000 C CNN
F 1 "Conn_02x09_Odd_Even" H 3375 2701 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x09_P2.54mm_Vertical" H 3325 2175 50  0001 C CNN
F 3 "~" H 3325 2175 50  0001 C CNN
	1    3325 2175
	1    0    0    -1  
$EndComp
Text GLabel 1150 2475 0    50   UnSpc ~ 0
AEN
$Comp
L Connector:Raspberry_Pi_2_3 J6
U 1 1 61ACC25B
P 9275 2125
F 0 "J6" H 9275 3725 50  0000 C CNN
F 1 "Raspberry_Pi_2_3" H 9275 3650 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x20_P2.54mm_Vertical" H 9275 2125 50  0001 C CNN
F 3 "https://www.raspberrypi.org/documentation/hardware/raspberrypi/schematics/rpi_SCH_3bplus_1p0_reduced.pdf" H 9275 2125 50  0001 C CNN
	1    9275 2125
	1    0    0    -1  
$EndComp
Text GLabel 9075 825  1    50   UnSpc ~ 0
VCC
Text GLabel 9175 825  1    50   UnSpc ~ 0
VCC
Text GLabel 8875 3425 3    50   UnSpc ~ 0
GND
Text GLabel 8975 3425 3    50   UnSpc ~ 0
GND
Text GLabel 9075 3425 3    50   UnSpc ~ 0
GND
Text GLabel 9175 3425 3    50   UnSpc ~ 0
GND
Text GLabel 9275 3425 3    50   UnSpc ~ 0
GND
Text GLabel 9375 3425 3    50   UnSpc ~ 0
GND
Text GLabel 9475 3425 3    50   UnSpc ~ 0
GND
Text GLabel 9575 3425 3    50   UnSpc ~ 0
GND
Text GLabel 8475 1925 0    50   Output ~ 0
PCM_FS
Text GLabel 8475 2125 0    50   Output ~ 0
PCM_OUT
Text GLabel 8475 1725 0    50   Output ~ 0
PCM_CLK
Text GLabel 10075 1225 2    50   BiDi ~ 0
RP0
Text GLabel 10075 1325 2    50   BiDi ~ 0
RP1
Text GLabel 10075 1525 2    50   BiDi ~ 0
RP2
Text GLabel 10075 1625 2    50   BiDi ~ 0
RP3
Text GLabel 10075 1825 2    50   BiDi ~ 0
RP4
Text GLabel 10075 1925 2    50   BiDi ~ 0
RP5
Text GLabel 10075 2025 2    50   BiDi ~ 0
RP6
Text GLabel 10075 2225 2    50   BiDi ~ 0
RP7
Text GLabel 10075 2325 2    50   BiDi ~ 0
RP8
Text GLabel 10075 2425 2    50   BiDi ~ 0
RP9
Text GLabel 10075 2525 2    50   BiDi ~ 0
RP10
Text GLabel 10075 2625 2    50   BiDi ~ 0
RP11
Text GLabel 3125 2275 0    50   Output ~ 0
SPDIF_OUT
Text GLabel 5600 2800 0    50   Input ~ 0
IRQ7
Text GLabel 3125 1150 0    50   BiDi ~ 0
RP0
Text GLabel 3625 1250 2    50   BiDi ~ 0
RP1
Text GLabel 3125 2175 0    50   BiDi ~ 0
RP2
Text GLabel 3625 2175 2    50   BiDi ~ 0
RP3
Text GLabel 3625 2075 2    50   BiDi ~ 0
RP4
Text GLabel 3625 1150 2    50   BiDi ~ 0
RP5
Text GLabel 3625 1050 2    50   BiDi ~ 0
RP6
Text GLabel 3125 1250 0    50   BiDi ~ 0
RP7
Text GLabel 3125 1350 0    50   BiDi ~ 0
RP8
Text GLabel 3625 1450 2    50   BiDi ~ 0
RP9
Text GLabel 1650 950  2    50   Input ~ 0
PCM_CLK
Text GLabel 1650 850  2    50   Input ~ 0
PCM_FS
Text GLabel 1650 750  2    50   Input ~ 0
PCM_OUT
Text GLabel 5600 3000 0    50   Input ~ 0
IRQ5
Text GLabel 1150 1975 0    50   Output ~ 0
IRQ5
Text GLabel 1150 2175 0    50   Output ~ 0
IRQ7
Text Notes 7000 6725 0    50   ~ 0
* IRQ7, DACK1 and DRQ1 are used when acting as Sound Blaster (IRQ & DMA)\n* IRQ6 can be used by keyboard with our CPU-board
Text GLabel 5600 1100 0    50   Input ~ 0
IRQ2
Text GLabel 10075 2825 2    50   BiDi ~ 0
RP12
Text GLabel 10075 2925 2    50   BiDi ~ 0
RP13
Text GLabel 3125 1050 0    50   BiDi ~ 0
RP12
Text GLabel 3125 950  0    50   BiDi ~ 0
RP13
Text GLabel 3625 2275 2    50   Output ~ 0
MIDI_OUT
Text GLabel 8475 1225 0    50   BiDi ~ 0
RP14
Text GLabel 8475 1325 0    50   BiDi ~ 0
RP15
Text GLabel 8475 1525 0    50   BiDi ~ 0
RP16
Text GLabel 8475 1625 0    50   BiDi ~ 0
RP17
Text GLabel 8475 2025 0    50   BiDi ~ 0
RP18
Text GLabel 8475 2325 0    50   BiDi ~ 0
RP19
Text GLabel 5600 2700 0    50   Input ~ 0
CLK
Text GLabel 1650 1250 2    50   Input ~ 0
CLK
Text GLabel 3125 2075 0    50   BiDi ~ 0
RP14
Text GLabel 3125 1975 0    50   BiDi ~ 0
RP15
Text GLabel 3625 950  2    50   BiDi ~ 0
RP16
Text GLabel 3625 1975 2    50   BiDi ~ 0
RP17
Text GLabel 3625 850  2    50   BiDi ~ 0
RP18
Text GLabel 3625 1875 2    50   BiDi ~ 0
RP19
Text GLabel 5600 2400 0    50   Output ~ 0
~DACK1
Text GLabel 5600 2500 0    50   Input ~ 0
DRQ1
Text GLabel 1650 1150 2    50   Input ~ 0
~DACK1
Text GLabel 1650 1050 2    50   Output ~ 0
DRQ1
Text GLabel 3625 1350 2    50   BiDi ~ 0
RP11
Text GLabel 3625 1775 2    50   BiDi ~ 0
RP10
Text GLabel 5600 2900 0    50   Input ~ 0
IRQ6
Text GLabel 1150 2075 0    50   Output ~ 0
IRQ6
Text GLabel 1150 1875 0    50   Output ~ 0
IRQ4
Text GLabel 1150 1775 0    50   Output ~ 0
IRQ3
Text GLabel 1150 2275 0    50   Output ~ 0
IRQ2
Text GLabel 5600 3100 0    50   Input ~ 0
IRQ4
Text GLabel 5600 3200 0    50   Input ~ 0
IRQ3
Text GLabel 8475 2425 0    50   BiDi ~ 0
RP20
Text GLabel 3125 1875 0    50   BiDi ~ 0
RP20
Text GLabel 3125 1775 0    50   BiDi ~ 0
RP21
Text GLabel 8475 2525 0    50   BiDi ~ 0
RP21
Text GLabel 5600 2200 0    50   Output ~ 0
~DACK3
Text GLabel 5600 2300 0    50   Input ~ 0
DRQ2
Text GLabel 3125 1450 0    50   BiDi ~ 0
RP22
Text GLabel 3125 850  0    50   BiDi ~ 0
RP23
Text GLabel 8475 2625 0    50   BiDi ~ 0
RP22
Text GLabel 8475 2725 0    50   BiDi ~ 0
RP23
Text GLabel 9375 825  1    50   UnSpc ~ 0
V3
Text GLabel 9475 825  1    50   UnSpc ~ 0
V3
Text GLabel 3625 3100 2    50   Input ~ 0
SPDIF_OUT
Text GLabel 3625 3000 2    50   Input ~ 0
MIDI_OUT
Text GLabel 3125 2900 0    50   UnSpc ~ 0
GND
Text GLabel 3125 3000 0    50   UnSpc ~ 0
GND
$Comp
L Connector_Generic:Conn_02x03_Odd_Even J7
U 1 1 61B43CFC
P 3325 3000
F 0 "J7" H 3375 3317 50  0000 C CNN
F 1 "Conn_02x03_Odd_Even" H 3375 3226 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x03_P2.54mm_Vertical" H 3325 3000 50  0001 C CNN
F 3 "~" H 3325 3000 50  0001 C CNN
	1    3325 3000
	1    0    0    -1  
$EndComp
Text GLabel 3125 3100 0    50   UnSpc ~ 0
GND
Text GLabel 3625 2900 2    50   UnSpc ~ 0
V3
$EndSCHEMATC
