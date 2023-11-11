module top(
	input            CLK,
	input      [9:0] RPI_GPIO,

	input     [19:0] ISA_A,
	inout      [7:0] ISA_D,
	input            ISA_MEMW,
	input            ISA_MEMR,
	input            ISA_IOW,
	input            ISA_IOR,
	output           ISA_IRQ2,
	output           ISA_IRQ3,
	output           ISA_IRQ4,
	output           ISA_IRQ5,
	output           ISA_IRQ6,
	output           ISA_IRQ7,
	output           ISA_DRQ1,
	output           ISA_DRQ2, // nonstandard CPU board: INT
	output           ISA_DRQ3,
	input            ISA_DACK1,
	input            ISA_DACK2, // nonstandard CPU board: INTA
	input            ISA_DACK3,
	output           ISA_AEN,
	inout            ISA_READY,
	output           ISA_RESET,
	output           ISA_CLK
);

/** ISA BUS signals **/
reg  [1:0] IOW;
reg  [1:0] IOR;
reg  [1:0] MEMW;
reg  [1:0] MEMR;
reg  [7:0] dout;
reg        rw;

/** Raspberry Pi signals */
reg  [1:0] RPI_CLK8;
reg  [1:0] RPI_CLK9;
reg  [7:0] RPI_ADDR;

/** ROM related **/
reg  [7:0] rom_din;
reg        rom_write_en;
reg  [9:0] rom_waddr;
reg  [9:0] rom_raddr;
reg  [7:0] rom_dout;

/** CPU signals **/
reg        r_ISA_RESET;
reg        r_ISA_DRQ2;
reg  [1:0] DACK2;

/** CLOCKS **/
reg  [3:0] ISA_CLK_cnt;
reg        r_ISA_CLK;
reg  [5:0] PIT_CLK_cnt;
reg        r_PIT_CLK;

/** PIT and PIC signals **/
reg [16:0] PIT_value;
reg [16:0] PIT_status;
reg        PIT_state;
reg [16:0] PIT_cnt;
reg  [1:0] PIT_trig;
reg        PIT_trigger;
reg  [1:0] IRQ;

/** Keyboard signals **/
reg  [7:0] KBD_DATA;
reg        KBD_HAS_DATA;


/**** GENERATE CLOCKS ****/
/*
 *  1. Generate ISA CLK, typically around 8 MHz
 *  2. Generate PIT CLK, typically 315/88/3 ~ 1.19 MHz
 *
 */

always @(posedge CLK)
begin
	/* 3 = 12.5 MHz, 5 = 8.33 MHz, 100/(n+1)/2 */
	if(ISA_CLK_cnt<3)
		ISA_CLK_cnt <= ISA_CLK_cnt + 1;
	else
	begin
		ISA_CLK_cnt <= 0;
		r_ISA_CLK <= ~r_ISA_CLK;
	end

	/* 1.19 MHz */
	if(PIT_CLK_cnt<41)
		PIT_CLK_cnt <= PIT_CLK_cnt + 1;
	else
	begin
		PIT_CLK_cnt <= 0;
		r_PIT_CLK <= ~r_PIT_CLK;
	end
end


/**** PROGRAMMABLE INTERVAL TIMER (PIT) ****/

always @(posedge r_PIT_CLK)
begin
	if(PIT_status>0)
	begin
		PIT_trigger <= 0;
		PIT_status <= PIT_status - 1;
	end
	else
	begin
		PIT_trigger <= 1;
		PIT_status <= PIT_value;
	end
end


/**** ISA BUS / CPU CONTROL ****/

always @(posedge CLK)
begin
	DACK2 <= {DACK2[0], ISA_DACK2};
	IOW <= {IOW[0], ISA_IOW};
	IOR <= {IOR[0], ISA_IOR};
	MEMW <= {MEMW[0], ISA_MEMW};
	MEMR <= {MEMR[0], ISA_MEMR};

	/**** RECEIVE DATA FROM RASPBERRY PI ****/

	RPI_CLK8 <= {RPI_CLK8[0], RPI_GPIO[8]};
	RPI_CLK9 <= {RPI_CLK9[0], RPI_GPIO[9]};

	if(RPI_CLK8==2'b01)
		RPI_ADDR <= RPI_GPIO[7:0];
	if(RPI_CLK8==2'b01)
		case(RPI_GPIO[7:0])
			8'h0:
			begin
				rom_waddr <= 1023;
				r_ISA_RESET <= 1;
			end
		endcase
	if(RPI_CLK8==2'b10)
		case(RPI_GPIO[7:0])
			8'h0:
			begin
				r_ISA_RESET <= 0;
			end
		endcase
	if(RPI_CLK9==2'b01)
		case(RPI_ADDR)
			8'h0:
			begin
				rom_write_en <= 1;
				rom_waddr <= rom_waddr + 1;
				rom_din[7:0] <= RPI_GPIO[7:0];
			end
			8'h1:
			begin
				KBD_DATA <= RPI_GPIO[7:0];
				KBD_HAS_DATA <= 1;
				IRQ[1] <= 1;
			end
		endcase
	if(RPI_CLK9==2'b10)
		case(RPI_ADDR)
			8'h0:
			begin
				rom_write_en <= 0;
			end
		endcase

	/**** HANDLE INTERRUPTS ****/

	PIT_trig <= {PIT_trig[0], PIT_trigger};
	if(PIT_trig==2'b01) IRQ[0] <= 1;
	if(IRQ>0 && r_ISA_DRQ2==0)
		r_ISA_DRQ2 <= 1;
	else
	begin
		if(DACK2==2'b10)
		begin
			rw <= 1;
			if(IRQ[0]==1)
			begin
				dout <= 8;
				IRQ[0] <= 0;
			end
			else
			if(IRQ[1]==1)
			begin
				dout <= 9;
				IRQ[1] <= 0;
			end
			r_ISA_DRQ2 <= 0;
		end
	end

	/**** HANDLE ROM ****/

	if(MEMR==2'b10 && ISA_A>=20'hFFC00)
	begin
		rw <= 1;
		dout <= rom_dout;
	end
	
	/**** HANDLE IO ****/

	if(IOW==2'b01)
	case(ISA_A[9:0])
		10'h40:
		begin
			if(PIT_state==0) PIT_value[7:0] <= ISA_D;
			else
			begin
				if(PIT_value[7:0]==0 && ISA_D==0) PIT_value <= 65536;
				else PIT_value <= {1'b0, ISA_D, PIT_value[7:0]};
			end
			PIT_state <= ~PIT_state;
		end
		10'h43: PIT_state <= 0;
	endcase

	if(IOR==2'b10)
	case(ISA_A[9:0])
		10'h60:
		begin
			rw <= 1;
			dout <= KBD_DATA;
			KBD_HAS_DATA <= 0;
		end
		10'h64:
		begin
			dout <= KBD_HAS_DATA;
			rw <= 1;
		end
	endcase

	if(IOR==2'b01 || MEMR==2'b01 || DACK2==2'b01) rw <= 0;
end


/**** ROM MEMORY (1 KB) ****/

reg [7:0] mem[1023:0];

always @(posedge CLK)
	if(rom_write_en)
		mem[rom_waddr] <= rom_din;

always @(posedge CLK)
	rom_dout <= mem[ISA_A[9:0]];


/**** PIN ASSIGNMENTS ****/

assign ISA_D     = rw ? dout : 8'hZ;
assign ISA_IRQ4  = 0;
assign ISA_IRQ5  = 0;
assign ISA_IRQ7  = 0;
assign ISA_DRQ1  = 0;
assign ISA_DRQ2  = r_ISA_DRQ2;
assign ISA_DRQ3  = 0;
assign ISA_AEN   = 0;
assign ISA_READY = 1'bZ;
assign ISA_RESET = r_ISA_RESET;
assign ISA_CLK   = r_ISA_CLK;

endmodule
