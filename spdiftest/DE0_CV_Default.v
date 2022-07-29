module DE0_CV_Default(
	input             CLOCK2_50,
	input             CLOCK3_50,
	inout             CLOCK4_50,
	input             CLOCK_50,
	output     [12:0] DRAM_ADDR,
	output      [1:0] DRAM_BA,
	output            DRAM_CAS_N,
	output            DRAM_CKE,
	output            DRAM_CLK,
	output            DRAM_CS_N,
	inout      [15:0] DRAM_DQ,
	output            DRAM_LDQM,
	output            DRAM_RAS_N,
	output            DRAM_UDQM,
	output            DRAM_WE_N,
	inout  reg [35:0] GPIO_0,
	inout      [35:0] GPIO_1,
	output      [6:0] HEX0,
	output      [6:0] HEX1,
	output      [6:0] HEX2,
   output      [6:0] HEX3,
	output      [6:0] HEX4,
	output      [6:0] HEX5,
	input       [3:0] KEY,	
	output      [9:0] LEDR,	
	inout             PS2_CLK,
	inout             PS2_CLK2,
	inout             PS2_DAT,
	inout             PS2_DAT2,
	input             RESET_N,
	output            SD_CLK,
	inout             SD_CMD,
	inout       [3:0] SD_DATA,
	input       [9:0] SW,
	output      [3:0] VGA_B,
	output      [3:0] VGA_G,
	output            VGA_HS,
	output      [3:0] VGA_R,
	output            VGA_VS
);

/*** BEGIN Delta-Sigma-Modulator */
/*
reg signed [15:0] left;
reg signed [15:0] right;
reg signed [18:0] inta;
reg signed [18:0] outa;

always @(posedge CLOCK_50)
begin
	inta = inta + left - outa;
	if(inta>0)
	begin
		GPIO_1[0] = 1;
		GPIO_1[1] = 1;
		outa = 32767;
	end
	else
	begin
		GPIO_1[0] = 0;
		GPIO_1[1] = 0;
		outa = -32767;
	end
end
*/
/*** EOF Delta-Sigma-Modulator */

/*** BEGIN AudioFIFO ***/

reg  [31:0] acnt;
wire  [7:0] adata;
wire  [7:0] rdusedw;
reg   [7:0] au0;
reg         astate;

always@(posedge spdif_clk)
begin
	acnt <= acnt + 1;
end

always @(posedge acnt[5])
begin
	if(rdusedw<64) // if there is less than 64 bytes in the buffer, request more from the Raspberry Pi
		GPIO_0[35] <= 1;
	else
		GPIO_0[35] <= 0;
	if(astate==0) au0 <= adata;
	if(astate==1)
	begin
		left[7:0] <= 0;
		left[15:8] <= au0;
		left[23:16] <= adata;
		right[7:0] <= 0;
		right[15:8] <= au0;
		right[23:16] <= adata;
	end
	if(rdusedw>15)
		astate <= astate + 1;
end

audioFIFO af(
	.data({GPIO_0[23], GPIO_0[26], GPIO_0[31], GPIO_0[6], GPIO_0[4], GPIO_0[2], GPIO_0[25], GPIO_0[24]}),
	.rdclk(acnt[5]),
	.rdreq(rdusedw>15 ? 1 : 0), // play only if there is 16 or more bytes in the buffer
	.wrclk(GPIO_0[30]),
	.wrreq(GPIO_0[33]),
	.q(adata),
	.rdusedw(rdusedw));

/*** EOF AudioFIFO ***/

/*** BEGIN SPDIF ***/

reg  signed [23:0] left;
reg  signed [23:0] right;
wire               spdif_clk;

spdif_core spdif_core(
    .clk_i(spdif_clk),
    .rst_i(0),
	 .bit_out_en_i(1),
	 .spdif_o(GPIO_1[24]),
	 .sample_i({right, left})
);

PLL pll(
	.refclk(CLOCK_50),
	.rst(0),
	.outclk_0(spdif_clk), // 48000*32*2*2
	.locked());
	
/*** EOF SPDIF ***/

assign LEDR = rdusedw;
assign HEX0 = 7'b1111111;
assign HEX1 = 7'b1111111;
assign HEX2 = 7'b1111111;
assign HEX3 = 7'b1111111;
assign HEX4 = 7'b1111111;
assign HEX5 = 7'b1111111;

/*
SEG7_LUT U0(.oSEG(HEX0), .iDIG(0));
SEG7_LUT U1(.oSEG(HEX1), .iDIG(0));
SEG7_LUT U2(.oSEG(HEX2), .iDIG(0));
SEG7_LUT U3(.oSEG(HEX3), .iDIG(0));
SEG7_LUT U4(.oSEG(HEX4), .iDIG(0));
SEG7_LUT U5(.oSEG(HEX5), .iDIG(0));
*/

endmodule