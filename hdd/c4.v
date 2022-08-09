/*
  IDE:          170h --> 70h
  IDE:          171h --> 71h
  SoundBlaster: 22ch --> 2ch 
  MIDI:         330h --> 30h
  GUS:   342h - 347h --> 42h - 47h
  OPL3:         388h --> 88h
  OPL3:         389h --> 89h
  OPL3:         38ah --> 8ah
  OPL3:         38bh --> 8bh
*/

module C4(
	input             clk,
	output reg  [7:0] leds,
	
	input       [9:0] A,          // ISA address
	inout  reg  [7:0] D,          // ISA data
	input             IOR,        // ISA IOR
	input             IOW,        // ISA IOW
	input             MEMR,       // ISA MEMR
	input             MEMW,       // ISA MEMW
	input             IRQ2,
	input             IRQ3,
	input             IRQ4,
	input             IRQ5,
	input             IRQ6,
	output reg        IRQ7,       // ISA IRQ7
	inout reg         DRQ1,       // ISA DRQ1
	input             DACK1,      // ISA DACK1
	input             AEN,        // ISA AEN

	// F --> R data output
	output            GPIO0,      // DO0
	output            GPIO1,      // DO1
	output            GPIO2,      // DO2
	output            GPIO3,      // DO3
	output            GPIO4,      // DO4
	output            GPIO5,      // DO5
	output            GPIO6,      // DO6
	output            GPIO7,      // DO7

   // F <-- R data input
	input             GPIO8,      // DI0
	input             GPIO9,      // DI1
	input             GPIO10,     // DI2
	input             GPIO11,     // DI3
	input             GPIO12,     // DI4
	input             GPIO13,     // DI5
	input             GPIO14,     // DI6
	input             GPIO15,     // DI7

	output            GPIO16,     // F --> R address/data indicator
	output reg        GPIO17,     // F --> R output FIFO has data
	input             GPIO18,     // F <-- R output FIFO read clock
	input             GPIO19,     // F <-- R output FIFO address increment
	input             GPIO20,     // F <-- R input FIFO write clock
	input             GPIO21,     // F <-- R input FIFO wren
	input             GPIO22,     // F <-- R audio FIFO write clock
	output reg        GPIO23,     // F --> R audio request
   output reg        GPIO24,     // F <-- R audio FIFO wren
   input             GPIO25,
   input             GPIO26,
   input             GPIO27,
   input             GPIO28,

	output            SPDIF,
	output            MIDI
);

/*
 PINOUT

 A0    7 10 GPIO21  | GND    GND GND GND
 A1   11 28 GPIO19  | (GP26)  NC 137 GPIO20
 A2   30 31 GPIO18  | GPIO13 136 135 GPIO16
 A3   32 33 DRQ1    | GPIO12 133 132 GPIO06
 A4   34 38 DACK1   | GPIO00 129 128 GPIO05
 A5   39 42 CLK     | GPIO07 127 126 GPIO01
 A6   46 49 A9      | GPIO08 125 124 GPIO11
 A7   50 51 A8      | (GP25) 121 120 GPIO09
 ------------------------------------------
 IRQ3 52 53 D7      | GPIO24 119 115 GPIO10
 IRQ4 54 55 D6      | GPIO23 114 111 GPIO22
 IRQ5 58 59 D5      | GPIO15 110 106 GPIO17
 IRQ6 60 64 D4      | GPIO14 105 104 GPIO04
 IRQ7 65 66 D3      | GPIO2  100  85 GPIO03
 IRQ2 67 68 D2      | SPDIF   84  83 (MIDI)
      69 70 D1      | IOR     80  77 IOW
 (AEN)71 72 D0      | MEMR    76  75 MEMW
                    | GND            VCC
*/

reg [31:0] cnt;

reg        rd;
reg        wr;

reg   [1:0] IOWr;
reg   [1:0] IORr;
reg   [1:0] GPIO20r;

reg   [8:0] o_data;
reg  [10:0] o_wr_address;
reg  [10:0] o_rd_address;

wire  [7:0] i_data;
reg   [9:0] i_rd_address;
reg   [9:0] i_wr_address;

reg   [7:0] adlib_detect;
reg   [7:0] adlib_reg;

initial
begin
	DRQ1 = 1'bZ;
end

always @(posedge clk)
begin
	cnt <= cnt + 1;

	IOWr <= {IOWr[0], IOW};
	IORr <= {IORr[0], IOR};
	GPIO20r <= {GPIO20r[0], GPIO20};
	
	if(GPIO20r==2'b01)
		i_wr_address <= i_wr_address + 1;
	
	// IO write
	if(IOWr==2'b10)
	begin
		case(A)
			10'h170:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b1, A[7:0]};
				i_rd_address <= 0;
				i_wr_address <= 0;
			end
			10'h171:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b1, A[7:0]};				
			end
			10'h388:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b1, A[7:0]};				
			end
			10'h389:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b1, A[7:0]};				
			end
		endcase
	end
	if(IOWr==2'b01)
	begin
		case(A)
			10'h170:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b0, D};
				if(D==0) wr <= 1;
				else wr <= 0;
				if(D==1) rd <= 1;
				else rd <= 0;
			end
			10'h171:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b0, D};
			end
			10'h388: // adlib register
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b0, D};
				adlib_detect <= 0;
				adlib_reg <= D;
			end
			10'h389: // adlib data
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b0, D};
				if(adlib_reg==8'h60 && D==8'h04) adlib_detect <= 8'h00;
				if(adlib_reg==8'h04 && D==8'h21) adlib_detect <= 8'hC0;
			end
		endcase
	end

	// IO read
	if(IORr==2'b10)
	begin
		case(A)
			10'h170:
			begin
				if(rd) D <= (i_wr_address==512 ? 255 : {1'b0, i_wr_address[9:3]});
				if(wr) D <= (o_wr_address==o_rd_address);
			end
			10'h171:	D <= i_data;
			10'h388: D <= adlib_detect;
		endcase
	end
	if(IORr==2'b01)
	begin
		D <= 8'hZ;
		case(A)
			10'h171: i_rd_address <= i_rd_address + 1;
		endcase
	end	
end

/******** ******** ******** ********/

always @(posedge GPIO18)
	if(o_rd_address==o_wr_address)
		GPIO17 <= 0;
	else
		GPIO17 <= 1;

always @(posedge GPIO19)
	o_rd_address <= o_rd_address + 1;

oRAM oRAM (
	.data(o_data),
	.rdaddress(o_rd_address),
	.rdclock(GPIO18),
	.wraddress(o_wr_address),
	.wrclock(clk),
	.wren(1),
	.q({GPIO16, GPIO7, GPIO6, GPIO5, GPIO4, GPIO3, GPIO2, GPIO1, GPIO0}));

/******** ******** ******** ********/

iRAM iRAM(
	.data({GPIO15, GPIO14, GPIO13, GPIO12, GPIO11, GPIO10, GPIO9, GPIO8}),
	.rdaddress(i_rd_address),
	.rdclock(clk),
	.wraddress(i_wr_address),
	.wrclock(GPIO20),
	.wren(1),
	.q(i_data));

/******** ******** ******** ********/

endmodule
