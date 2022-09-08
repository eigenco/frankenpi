module C4(
	input             clk,
	output reg  [7:0] leds,
	
	input       [9:0] A,           // ISA address
	inout reg   [7:0] D,           // ISA data
	input             IOR,         // ISA IOR
	input             IOW,         // ISA IOW
	input             MEMR,        // ISA MEMR
	input             MEMW,        // ISA MEMW
	input             IRQ2,
	input             IRQ3,
	input             IRQ4,
	inout reg         IRQ5,        // ISA IRQ5
	input             IRQ6,
	inout reg         IRQ7,        // ISA IRQ7
	inout reg         DRQ1,        // ISA DRQ1
	input             DACK1,       // ISA DACK1
	input             AEN,         // ISA AEN

	// F --> R data output
	output            GPIO0,       // DO0
	output            GPIO1,       // DO1
	output            GPIO2,       // DO2
	output            GPIO3,       // DO3
	output            GPIO4,       // DO4
	output            GPIO5,       // DO5
	output            GPIO6,       // DO6
	output            GPIO7,       // DO7
	
	// F <-- R data input
	input             GPIO8,       // DI0
	input             GPIO9,       // DI1
	input             GPIO10,      // DI2
	input             GPIO11,      // DI3
	input             GPIO12,      // DI4
	input             GPIO13,      // DI5
	input             GPIO14,      // DI6
	input             GPIO15,      // DI7

	input             CLOCK,       // GPIO16: F <-- R
	output reg        FPGA_TX_REQ, // GPIO17: F --> R
	output reg        FPGA_RX_REQ, // GPIO18: F --> R	
	input             STATE0,      // GPIO19: F <-- R
	input             STATE1,      // GPIO20: F <-- R
	output            GPIO21,      // GPIO21: AD

	output            SPDIF,
	inout reg         CHRDY
);

/*
 PINOUT

 A0    7 10 **GPIO21  | GND     GND GND GND
 A1   11 28 **GPIO19  |          NC 137 **GPIO20
 A2   30 31 **GPIO18  | *GPIO13 136 135 **GPIO16
 A3   32 33 DRQ1      | *GPIO12 133 132 *GPIO06
 A4   34 38 DACK1     | *GPIO00 129 128 *GPIO05
 A5   39 42 CLK       | *GPIO07 127 126 *GPIO01
 A6   46 49 A9        | *GPIO08 125 124 *GPIO11
 A7   50 51 A8        |         121 120 *GPIO09
 ------------------------------------------
 IRQ3 52 53 D7        | GPIO24  119 115 *GPIO10
 IRQ4 54 55 D6        | GPIO23  114 111 GPIO22
 IRQ5 58 59 D5        | *GPIO15 110 106 **GPIO17
 IRQ6 60 64 D4        | *GPIO14 105 104 *GPIO04
 IRQ7 65 66 D3        | *GPIO2  100  85 *GPIO03
 IRQ2 67 68 D2        | SPDIF    84  83 CHRDY
      69 70 D1        | IOR      80  77 IOW
  AEN 71 72 D0        | MEMR     76  75 MEMW
                      | GND             VCC
							 
 A0     7 10 **GPIO21 | GND     GND GND GND
 A1    11 28 **GPIO19 |          NC 137 **GPIO20
 A2    30 31 **GPIO18 | *GPIO13 136 135 **GPIO16
 A3    32 33 DRQ1     | *GPIO12 133 132 *GPIO06
 A4    34 38 DACK1    | *GPIO00 129 128 *GPIO05
 A5    39 42 (A10)    | *GPIO07 127 126 *GPIO01
 A6    46 49 A9       | *GPIO08 125 124 *GPIO11
 A7    50 51 A8       | (A11)   121 120 *GPIO09
 ------------------------------------------
 (A15) 52 53 D7       | (A12)   119 115 *GPIO10
 (A16) 54 55 D6       | (A13)   114 111 (A14)
 IRQ5  58 59 D5       | *GPIO15 110 106 **GPIO17
 (A17) 60 64 D4       | *GPIO14 105 104 *GPIO04
 IRQ7  65 66 D3       | *GPIO2  100  85 *GPIO03
 (A18) 67 68 D2       | SPDIF    84  83 CHRDY
 (A19) 69 70 D1       | IOR      80  77 IOW
  AEN  71 72 D0       | MEMR     76  75 MEMW
                      | GND             VCC
*/

reg [31:0] cnt;
reg [11:0] buff;
reg  [1:0] past_state;
reg  [1:0] IOWr;
reg  [1:0] IORr;

reg  [7:0] adlib_detect;
reg  [7:0] adlib_reg;

reg  [7:0] gus_global;
reg [19:0] gus_addr;
reg  [7:0] gus_ram[15:0];
reg  [7:0] gus_voice;
reg  [8:0] waitstate;

initial
begin
	IRQ5 = 1'bZ;
	IRQ7 = 1'bZ;
	DRQ1 = 1'bZ;
	CHRDY = 1'bZ;
end

always @(posedge CLOCK)
begin
	case({STATE1, STATE0})
		0:
		begin
			if(o_rd_address==o_wr_address) FPGA_TX_REQ <= 0;
			else FPGA_TX_REQ <= 1;
			audio_byte <= 0;
		end
		1:	if(past_state==0)	o_rd_address <= o_rd_address + 1;
		3:
		begin
			case(audio_byte)
				0: audio_a[23:16] <= {GPIO15, GPIO14, GPIO13, GPIO12, GPIO11, GPIO10, GPIO9, GPIO8};
				1: audio_a[15: 0] <= {GPIO15, GPIO14, GPIO13, GPIO12, GPIO11, GPIO10, GPIO9, GPIO8, 8'b0};
				2: audio_b[23:16] <= {GPIO15, GPIO14, GPIO13, GPIO12, GPIO11, GPIO10, GPIO9, GPIO8};
				3: audio_b[15: 0] <= {GPIO15, GPIO14, GPIO13, GPIO12, GPIO11, GPIO10, GPIO9, GPIO8, 8'b0};
				4: audio_wrclk <= 1;
				5: audio_wrclk <= 0;
			endcase
			audio_byte <= audio_byte + 1;
		end
	endcase
	past_state <= {STATE1, STATE0};
end

/******** ******** ******** ********/

always @(posedge clk)
begin
	cnt <= cnt + 1;

	FPGA_RX_REQ <= (audio_buffer_state<64);
	IOWr <= {IOWr[0], IOW};
	IORr <= {IORr[0], IOR};
	
	if(waitstate>0) waitstate <= waitstate - 1;	
	if(AEN==0 && waitstate==0)
	begin
		CHRDY <= 1'bZ;
		if(IOWr==2'b10)
		case(A)
			10'h341:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= A[7:0];
			end
			10'h342:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= A[7:0];
			end
			10'h343:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= A[7:0];
			end
			10'h344:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= A[7:0];
			end
			10'h345:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= A[7:0];
			end
			10'h346:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= A[7:0];
			end
			10'h347:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= A[7:0];
				waitstate <= 511;
				CHRDY <= 0;
			end
			10'h388:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= A[7:0];
			end
			10'h389:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= A[7:0];	
			end
		endcase
		if(IOWr==2'b01)
		case(A)
			10'h341:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;
			end
			10'h342:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;
				gus_voice <= D & 31;
			end
			10'h343:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;
				gus_global <= D;
			end
			10'h344:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;
				if(gus_global == 8'h43) gus_addr <= (gus_addr & 20'hFFF00) | D;
			end
			10'h345:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;
			end
			10'h346:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;
			end
			10'h347:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;	
				gus_ram[gus_addr] <= D;
				gus_addr <= gus_addr & 20'hFFFFF;
			end
			10'h388:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;
				adlib_detect <= 0;
				adlib_reg <= D;
			end
			10'h389:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;
				if(adlib_reg==8'h60 && D==8'h04) adlib_detect <= 8'h00;
				if(adlib_reg==8'h04 && D==8'h21) adlib_detect <= 8'hC0;
			end
		endcase
		if(IORr==2'b10)
		case(A)
			10'h342: D <= gus_voice;
			10'h343: D <= gus_global;
			10'h344: D <= 255;
			10'h345:	if(gus_global==8'h49) D <= 0;	else D <= 255;
			10'h346: D <= 8'hFF;
			10'h347: D <= gus_ram[gus_addr];
			10'h349: D <= 0;
			10'h388: D <= adlib_detect;
		endcase
		if(IORr==2'b01) D <= 8'hZ;
	end

	if(cnt[22:0]==0)
	begin
	/*
		if(buff>2047) leds <= 255; else
		if(buff>1023) leds <= 127;	else
		if(buff>511) leds <= 63; else
		if(buff>255) leds <= 31; else
		if(buff>127) leds <= 15; else		
		if(buff>63) leds <= 7; else
		if(buff>31) leds <= 3; else
		if(buff>15) leds <= 1; else
		leds <= 0;
		buff <= 0;
	*/
		if(buff<1) leds <= 0; else
		if(buff<2) leds <= 1; else
		if(buff<4) leds <= 3; else
		if(buff<8) leds <= 7; else
		if(buff<16) leds <= 15; else
		if(buff<32) leds <= 31; else
		if(buff<64) leds <= 63; else
		if(buff<128) leds <= 127; else
		leds <= 0;
		buff <= 4095;
	end
	
	if(audio_buffer_state<buff) buff <= audio_buffer_state;
	/*
	if(o_rd_address<=o_wr_address && (o_wr_address-o_rd_address)>buff) buff <= o_wr_address-o_rd_address;
	else if((4096-(o_rd_address-o_wr_address)) > buff) buff <= (4096-(o_rd_address-o_wr_address));
	*/
end

/******** ******** ******** ********/

reg  [7:0] o_data;
reg [11:0] o_rd_address;
reg [11:0] o_wr_address;

oRAM oRAM (
	.data(o_data),
	.rdaddress(o_rd_address),
	.rdclock(CLOCK),
	.wraddress(o_wr_address),
	.wrclock(clk),
	.wren(1),	
	.q({GPIO7, GPIO6, GPIO5, GPIO4, GPIO3, GPIO2, GPIO1, GPIO0}));	
	
/******** ******** ******** ********/

reg                audio_wrclk;
reg          [2:0] audio_byte;
reg  signed [23:0] audio_a;
reg  signed [23:0] audio_b;
wire signed [23:0] audio_right;
wire signed [23:0] audio_left;
wire         [7:0] audio_buffer_state;
wire               sample_req_o;

aFIFO audio_FIFO_right(
	.data(audio_a),
	.rdclk(sample_req_o),
	.rdreq(1),
	.wrclk(audio_wrclk),
	.wrreq(1),
	.q(audio_right),
	.rdusedw());

aFIFO audio_FIFO_left(
	.data(audio_b),
	.rdclk(sample_req_o),
	.rdreq(1),
	.wrclk(audio_wrclk),
	.wrreq(1),
	.q(audio_left),
	.rdusedw(audio_buffer_state));

spdif_core spdif_core(
    .clk_i(spdif_clk),
    .rst_i(0),
	 .bit_out_en_i(1),
	 .spdif_o(SPDIF),
	 .sample_r(audio_right),
	 .sample_l(audio_left),
	 .sample_req_o(sample_req_o)
);

PLL PLL(
	.inclk0(clk),
	.c0(spdif_clk));

endmodule