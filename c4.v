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
	
	input       [9:0] A,           // ISA address
	inout  reg  [7:0] D,           // ISA data
	input             IOR,         // ISA IOR
	input             IOW,         // ISA IOW
	input             MEMR,        // ISA MEMR
	input             MEMW,        // ISA MEMW
	input             IRQ2,
	input             IRQ3,
	input             IRQ4,
	input             IRQ5,
	input             IRQ6,
	inout reg         IRQ7,        // ISA IRQ7
	inout reg         DRQ1,        // ISA DRQ1 (output reg)
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
	output            GPIO8,       // DO8 (address/data)

	// F <-- R data input
	input             GPIO9,       // DI0
	input             GPIO10,      // DI1
	input             GPIO11,      // DI2
	input             GPIO12,      // DI3
	input             GPIO13,      // DI4
	input             GPIO14,      // DI5
	input             GPIO15,      // DI6
	input             GPIO16,      // DI7

	output reg        FPGA_TX_REQ, // F --> R
	output reg        FPGA_RX_REQ, // F --> R
	input             CLOCK,       // F <-- R
	input             STATE0,      // F <-- R
	input             STATE1,      // F <-- R
	input             STATE2,      // F <-- R

	output            SPDIF,
	output            MIDI
);

/*
 PINOUT

 A0    7 10 GPIO21  | GND    GND GND GND
 A1   11 28 GPIO19  |         NC 137 GPIO20
 A2   30 31 GPIO18  | GPIO13 136 135 GPIO16
 A3   32 33 DRQ1    | GPIO12 133 132 GPIO06
 A4   34 38 DACK1   | GPIO00 129 128 GPIO05
 A5   39 42 CLK     | GPIO07 127 126 GPIO01
 A6   46 49 A9      | GPIO08 125 124 GPIO11
 A7   50 51 A8      |        121 120 GPIO09
 ------------------------------------------
 IRQ3 52 53 D7      | GPIO24 119 115 GPIO10
 IRQ4 54 55 D6      | GPIO23 114 111 GPIO22
 IRQ5 58 59 D5      | GPIO15 110 106 GPIO17
 IRQ6 60 64 D4      | GPIO14 105 104 GPIO04
 IRQ7 65 66 D3      | GPIO2  100  85 GPIO03
 IRQ2 67 68 D2      | SPDIF   84  83 (MIDI)
      69 70 D1      | IOR     80  77 IOW
  AEN 71 72 D0      | MEMR    76  75 MEMW
                    | GND            VCC
*/

reg  [31:0] cnt;
reg   [2:0] past_state;
reg         rd;
reg         wr;

reg   [1:0] IOWr;
reg   [1:0] IORr;
reg   [1:0] CLOCKr;

reg   [8:0] o_data;
reg  [12:0] o_wr_address;
reg  [12:0] o_rd_address;

wire  [7:0] i_data;
reg   [9:0] i_rd_address;
reg   [9:0] i_wr_address;

reg   [7:0] adlib_detect;
reg   [7:0] adlib_reg;

reg   [7:0] sb_DSP_reg;
reg   [7:0] sb_IRQ_count;
reg   [7:0] sb_C;
reg   [3:0] sb_TAU_state;
reg   [3:0] sb_DMA_state;
reg  [16:0] sb_DMA_length;
reg  [31:0] sb_DMA_count;
reg   [7:0] sb_pcm;
reg  [15:0] sb_DMA_wait;

reg   [7:0] gus_global;
reg  [19:0] gus_addr;
reg   [7:0] gus_ram[15:0];
reg   [7:0] gus_voice;

initial
begin
	DRQ1 = 1'bZ;
	IRQ7 = 1'bZ;
end

always @(posedge clk)
begin
	cnt <= cnt + 1;

	IOWr <= {IOWr[0], IOW};
	IORr <= {IORr[0], IOR};
	CLOCKr <= {CLOCKr[0], CLOCK};
		
	if(CLOCKr==2'b01)
	begin
		if({STATE2, STATE1, STATE0} == 0)
		begin
			if(o_rd_address==o_wr_address) FPGA_TX_REQ <= 0;
			else FPGA_TX_REQ <= 1;			
		end
		if({STATE2, STATE1, STATE0} == 1 && past_state == 0) o_rd_address <= o_rd_address + 1;
		if({STATE2, STATE1, STATE0} == 4) i_wr_address <= i_wr_address + 1;
		past_state <= {STATE2, STATE1, STATE0};
	end
	
	// BOF: sound blaster dma routines
	if(sb_DMA_length>0 && DRQ1==0)
	begin
		if(sb_DMA_count>sb_DMA_wait && DACK1==1)
		begin
			sb_DMA_count <= 0;
			DRQ1 <= 1;
		end
		else
			sb_DMA_count <= sb_DMA_count + 1;		
	end

	if(sb_IRQ_count>0) sb_IRQ_count <= sb_IRQ_count - 1;
	if(sb_IRQ_count==9) IRQ7 <= 1;
	if(sb_IRQ_count==0) IRQ7 <= 0;
	
	if(DACK1==0)
	begin
		if(IOWr==2'b01)
		begin
			DRQ1 <= 0;
			sb_pcm <= D;
			sb_DMA_length <= sb_DMA_length - 1;
			if(sb_DMA_length==1) sb_IRQ_count <= 9;
		end
	end
   // EOF: sound blaster dma routines
	
	// IO write
	if(IOWr==2'b10 && AEN==0)
	begin
		case(A)
		
			// mass storage
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

			// gravis ultrasound
			10'h340:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b1, A[7:0]};		
			end
			10'h341:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b1, A[7:0]};		
			end
			10'h342:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b1, A[7:0]};		
			end
			10'h343:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b1, A[7:0]};		
			end
			10'h344:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b1, A[7:0]};		
			end
			10'h345:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b1, A[7:0]};		
			end
			10'h346:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b1, A[7:0]};		
			end
			10'h347:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b1, A[7:0]};		
			end

			// adlib
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
	if(IOWr==2'b01 && AEN==0)
	begin
		case(A)
		
			// mass storage
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

			// sound blaster
			10'h22c:
			begin
				sb_DSP_reg <= D;
				if(D==8'hd0)
				begin
					sb_DMA_length <= 0;
					sb_IRQ_count <= 0;
					IRQ7 <= 0;
				end
				if(D==8'h40) sb_TAU_state <= 1;
				if(sb_TAU_state==1)
				begin
					sb_DMA_wait <= 50*(256-D);
					sb_TAU_state <= 0;
				end
				if(D==8'h14)
					sb_DMA_state <= 1;
				if(sb_DMA_state==1)
				begin
					sb_C <= D;
					sb_DMA_state <= 2;
				end
				if(sb_DMA_state==2)
				begin
					sb_DMA_length <= {D, sb_C} + 1;
					sb_DMA_state <= 0;
				end
			end

			// gravis ultrasound
			10'h340:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b0, D};
			end
			10'h341:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b0, D};
			end
			10'h342:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b0, D};
				gus_voice <= D & 31;
			end
			10'h343:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b0, D};
				gus_global <= D;
			end
			10'h344:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b0, D};
				if(gus_global == 8'h43) gus_addr <= (gus_addr & 20'hFFF00) | D;
			end
			10'h345:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b0, D};
			end
			10'h346:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b0, D};
			end
			10'h347:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b0, D};		
				gus_ram[gus_addr] <= D;
				gus_addr <= gus_addr & 20'hFFFFF;
			end
			
			// adlib
			10'h388:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b0, D};
				adlib_detect <= 0;
				adlib_reg <= D;
			end
			10'h389:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= {1'b0, D};
				if(adlib_reg==8'h60 && D==8'h04) adlib_detect <= 8'h00;
				if(adlib_reg==8'h04 && D==8'h21) adlib_detect <= 8'hC0;
			end

		endcase
	end

	// IO read
	if(IORr==2'b10 && AEN==0)
	begin
		case(A)
		
			// mass storage
			10'h170:
			begin
				if(rd) D <= (i_wr_address==512 ? 255 : {1'b0, i_wr_address[9:3]});
				if(wr) D <= (o_wr_address==o_rd_address);
			end
			10'h171:	D <= i_data;
			
			// sound blaster
			10'h22a:
			begin
				if(sb_DSP_reg==8'he1) D <= 1;
				else D <= 8'haa;
			end
			10'h22c: D <= 0;
			10'h22e: D <= 8'hff;
			
			// gravis ultrasound
			10'h342: D <= gus_voice;
			10'h343: D <= gus_global;
			10'h344: D <= 255;
			10'h345:
			begin
				case(gus_global)
					8'h00: D <= 255;
					8'h01: D <= 255;
					8'h02: D <= 255;
					8'h03: D <= 255;
					8'h04: D <= 255;
					8'h05: D <= 255;
					8'h06: D <= 255;
					8'h07: D <= 255;
					8'h08: D <= 255;
					8'h09: D <= 255;
					8'h0a: D <= 255;
					8'h0b: D <= 255;
					8'h0c: D <= 255;
					8'h0d: D <= 255;
					8'h0e: D <= 255;
					8'h0f: D <= 255;
					8'h49: D <= 0;
					default: D <= 255;
				endcase
			end
			10'h346: D <= 8'hFF;
			10'h347: D <= gus_ram[gus_addr];
			10'h349: D <= 0;
			
			// adlib
			10'h388: D <= adlib_detect;

		endcase
	end
	if(IORr==2'b01 && AEN==0)
	begin
		D <= 8'hZ;
		case(A)
			10'h171: i_rd_address <= i_rd_address + 1;
		endcase
	end

end

/******** ******** ******** ********/

oRAM oRAM (
	.data(o_data),
	.rdaddress(o_rd_address),
	.rdclock({STATE2, STATE1, STATE0} == 1 ? CLOCK : 0),
	.wraddress(o_wr_address),
	.wrclock(clk),
	.wren(1),
	.q({GPIO8, GPIO7, GPIO6, GPIO5, GPIO4, GPIO3, GPIO2, GPIO1, GPIO0}));

/******** ******** ******** ********/

iRAM iRAM(
	.data({GPIO16, GPIO15, GPIO14, GPIO13, GPIO12, GPIO11, GPIO10, GPIO9}),
	.rdaddress(i_rd_address),
	.rdclock(clk),
	.wraddress(i_wr_address),
	.wrclock({STATE2, STATE1, STATE0} == 4 ? CLOCK : 0),
	.wren(1),
	.q(i_data));

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

always @(posedge clk)
begin
	if(CLOCKr==2'b01 || CLOCKr==2'b10)
	begin		
		if({STATE2, STATE1, STATE0} == 3)
		begin
			if(audio_byte == 0) audio_a[23:16] <= {GPIO16, GPIO15, GPIO14, GPIO13, GPIO12, GPIO11, GPIO10, GPIO9};
			if(audio_byte == 1) audio_a[15: 0] <= {GPIO16, GPIO15, GPIO14, GPIO13, GPIO12, GPIO11, GPIO10, GPIO9, 8'b0};
			if(audio_byte == 2) audio_b[23:16] <= {GPIO16, GPIO15, GPIO14, GPIO13, GPIO12, GPIO11, GPIO10, GPIO9};
			if(audio_byte == 3) audio_b[15: 0] <= {GPIO16, GPIO15, GPIO14, GPIO13, GPIO12, GPIO11, GPIO10, GPIO9, 8'b0};
			if(audio_byte == 4) audio_wrclk <= 1;
			if(audio_byte == 5) audio_wrclk <= 0;
			audio_byte <= audio_byte + 1;
		end else
			audio_byte <= 0;
	end
	FPGA_RX_REQ <= (audio_buffer_state<64);
	leds <= audio_buffer_state;
end

spdif_core spdif_core(
    .clk_i(spdif_clk),
    .rst_i(0),
	 .bit_out_en_i(1),
	 .spdif_o(SPDIF),
	 .sample_r(audio_right + 32768*$signed(sb_pcm-128)),
	 .sample_l(audio_left + 32768*$signed(sb_pcm-128)),
	 .sample_req_o(sample_req_o)
);

PLL PLL(
	.inclk0(clk),
	.c0(spdif_clk));

endmodule