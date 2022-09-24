module C4(
	input             clk,
	output reg  [7:0] leds,
	
	input       [9:0] A,           // ISA address
	inout reg   [7:0] D,           // ISA data
	input             IOR,         // ISA IOR
	input             IOW,         // ISA IOW
	input             MEMR,        // ISA MEMR
	input             MEMW,        // ISA MEMW
	inout reg         IRQ2,        // ISA IRQ2
	inout reg         IRQ3,        // ISA IRQ3
	inout reg         IRQ4,        // ISA IRQ4
	inout reg         IRQ5,        // ISA IRQ5
	inout reg         IRQ6,        // ISA IRQ6
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
	input             GPIO21,      // GPIO21: AD

	output            SPDIF,
	inout reg         CHRDY,
	inout reg         RESET
);

/*
 PINOUT

 (7)    A0 ?     (10)          GND GND
(11)    A1 ?     (28)            x R18  (137)
(30)    A2 ?     (31)   (136)  R13 R16  (135)
(32)    A3 DRQ1  (33)   (133)  R12 R6   (132)
(34)    A4 DACK1 (38)   (129)   R0 R5   (128)
(39)    A5 CLK   (42)   (127)   R7 R1   (126)
(46)    A6 A9    (49)   (125)   R8 R11  (124)
(50)    A7 A8    (51)   (121)  R22 R9   (120)

(52)  IRQ3 D7    (53)   (119)  R21 R10  (115)
(54)  IRQ4 D6    (55)   (114)  R20 R19  (111)
(58)  IRQ5 D5    (59)   (110)  R15 R17  (106)
(60)  IRQ6 D4    (64)   (105)  R14 R4   (104)
(65)  IRQ7 D3    (66)   (100)   R2 R3    (85)
(67)  IRQ2 D2    (68)   (84) SPDIF RESET (83)
(69)   AEN D1    (70)   (80)   IOR IOW   (77)
(71) CHRDY D0    (72)   (76)  MEMR MEMW  (75)
                               GND VCC
*/

reg [31:0] cnt;
reg  [7:0] audio_buff_min;
reg [11:0] port_buff_max;
reg  [1:0] past_state;

reg  [1:0] IOWr;
reg  [1:0] IORr;
reg  [1:0] CLKr;

reg  [7:0] adlib_detect;
reg  [7:0] adlib_reg;

reg  [7:0] gus_global;
reg [19:0] gus_addr;
reg  [7:0] gus_ram[15:0];
reg [15:0] waitstate;

reg   [7:0] sb_DSP_reg;
reg   [7:0] sb_IRQ_count;
reg   [7:0] sb_C;
reg   [3:0] sb_TAU_state;
reg   [3:0] sb_DMA_state;
reg  [16:0] sb_DMA_length;
reg  [31:0] sb_DMA_count;
reg   [7:0] sb_pcm;
reg  [15:0] sb_DMA_wait;

initial
begin
	IRQ2 = 1'bZ;
	IRQ3 = 1'bZ;
	IRQ4 = 1'bZ;
	IRQ5 = 1'bZ;
	IRQ6 = 1'bZ;
	IRQ7 = 1'bZ;
	DRQ1 = 1'bZ;
	CHRDY = 1'bZ;
	RESET = 1'bZ;
end

always @(posedge CLOCK)
begin
	case({GPIO21, STATE1, STATE0})
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
	past_state <= {GPIO21, STATE1, STATE0};
end

/******** ******** ******** ********/

always @(posedge sclk)
begin
	cnt <= cnt + 1;

	FPGA_RX_REQ <= (audio_buffer_state<64);
	IOWr <= {IOWr[0], IOW};
	IORr <= {IORr[0], IOR};
	CLKr <= {CLKr[0], CLOCK};
	
	if(CLKr==2'b01 && {GPIO21, STATE1, STATE0}==2) i_wr_address <= i_wr_address + 1;
	if(CLKr==2'b01 && {GPIO21, STATE1, STATE0}==4) m_wr_address <= m_wr_address + 1;
	if(IRQ4==0 && m_wr_address!=m_rd_address)	IRQ4 <= 1;
	
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
	
	if(waitstate>0) waitstate <= waitstate - 1;
	if(AEN==0 && waitstate==0)
	begin
		CHRDY <= 1'bZ;
		if(IOWr==2'b10)
		case(A)
			10'h170:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= A[7:0];
				i_rd_address <= 0;
				i_wr_address <= 0;
			end
			10'h171:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= A[7:0];				
			end
			10'h330:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= A[7:0];
			end
			10'h332:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= A[7:0];
			end
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
				waitstate <= 1023;
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
			10'h170:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;
				if(D==0) wr <= 1;
				else wr <= 0;
				if(D==1) rd <= 1;
				else rd <= 0;
			end
			10'h171:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;
			end
			
			// sound blaster
			/*
			10'h220:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;
				adlib_detect <= 0;
				adlib_reg <= D;
			end
			10'h221:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;
				if(adlib_reg==8'h60 && D==8'h04) adlib_detect <= 8'h00;
				if(adlib_reg==8'h04 && D==8'h21) adlib_detect <= 8'hC0;
			end
			10'h228:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;
				adlib_detect <= 0;
				adlib_reg <= D;
			end
			10'h229:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;
				if(adlib_reg==8'h60 && D==8'h04) adlib_detect <= 8'h00;
				if(adlib_reg==8'h04 && D==8'h21) adlib_detect <= 8'hC0;
			end
			*/
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
					sb_DMA_wait <= 66*(256-D);
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
			
			10'h330:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;			
			end			
			10'h332:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;			
			end			
			10'h341:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;
			end
			10'h342:
			begin
				o_wr_address <= o_wr_address + 1;
				o_data <= D;
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
			10'h3f8:
			begin
				m_rd_address <= 0;
				m_wr_address <= 0;
				IRQ4 <= 0;
			end
		endcase
		if(IORr==2'b10)
		case(A)
			10'h170:
			begin
				if(rd) D <= (i_wr_address==512 ? 255 : {1'b0, i_wr_address[9:3]});
				if(wr) D <= (o_wr_address==o_rd_address);
			end
			10'h171:	D <= i_data;
			
			// sound blaster
			//10'h220: D <= adlib_detect;
			//10'h228: D <= adlib_detect;
			
			10'h22a:
			begin
				if(sb_DSP_reg==8'he1) D <= 1;
				else D <= 8'haa;
			end
			10'h22c: D <= 0;
			10'h22e: D <= 8'hff;
			
			10'h330: D <= 8'hfe;
			10'h331: D <= 8'hbf;
			
			10'h343: D <= gus_global;
			10'h347: D <= gus_ram[gus_addr];
			10'h388: D <= adlib_detect;
			10'h3f8: D <= m_data;
		endcase
		if(IORr==2'b01)
		begin
			D <= 8'hZ;
			case(A)
				10'h171: i_rd_address <= i_rd_address + 1;
				10'h3f8:
				begin
					IRQ4 <= 0;
					if(m_rd_address!=m_wr_address) m_rd_address <= m_rd_address + 1;
				end
			endcase
		end
	end

	if(cnt[24:0]==33554431)
	begin
		if(audio_buff_min<1) leds[3:0] <= 255;
		else leds[3:0] <= 0;
		if(port_buff_max>2000) leds[7:4] <= 255;
		else leds[7:4] <= 0;
		audio_buff_min <= 4095;
		port_buff_max <= 0;
	end else
	begin
		if(audio_buffer_state < audio_buff_min) audio_buff_min <= audio_buffer_state;
		if(o_rd_address<=o_wr_address && (o_wr_address-o_rd_address)>port_buff_max) port_buff_max <= o_wr_address-o_rd_address;
		else if((4096-(o_rd_address-o_wr_address)) > port_buff_max) port_buff_max <= (4096-(o_rd_address-o_wr_address));
	end
end

/******** ******** ******** ********/

wire  [7:0] m_data;
reg   [5:0] m_rd_address;
reg   [5:0] m_wr_address;

mRAM mRAM(
	.data({GPIO15, GPIO14, GPIO13, GPIO12, GPIO11, GPIO10, GPIO9, GPIO8}),
	.rdaddress(m_rd_address),
	.rdclock(sclk),
	.wraddress(m_wr_address),
	.wrclock({GPIO21, STATE1, STATE0} == 4 ? CLOCK : 0),
	.wren(1),
	.q(m_data));

/******** ******** ******** ********/

reg         rd;
reg         wr;
wire  [7:0] i_data;
reg   [9:0] i_rd_address;
reg   [9:0] i_wr_address;

iRAM iRAM(
	.data({GPIO15, GPIO14, GPIO13, GPIO12, GPIO11, GPIO10, GPIO9, GPIO8}),
	.rdaddress(i_rd_address),
	.rdclock(sclk),
	.wraddress(i_wr_address),
	.wrclock({GPIO21, STATE1, STATE0} == 2 ? CLOCK : 0),
	.wren(1),
	.q(i_data));
	
/******** ******** ******** ********/

reg  [7:0] o_data;
reg [12:0] o_rd_address;
reg [12:0] o_wr_address;

oRAM oRAM (
	.data(o_data),
	.rdaddress(o_rd_address),
	.rdclock(CLOCK),
	.wraddress(o_wr_address),
	.wrclock(sclk),
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
	 .sample_r(audio_right + 32768*$signed(sb_pcm-128)),
	 .sample_l(audio_left + 32768*$signed(sb_pcm-128)),
	 .sample_req_o(sample_req_o)
);

wire sclk;

PLL PLL(
	.inclk0(clk),
	.c0(spdif_clk),
	.c1(sclk));

endmodule