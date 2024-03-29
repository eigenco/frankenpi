//-----------------------------------------------------------------
//                        SPDIF Transmitter
//                              V0.1
//                        Ultra-Embedded.com
//                          Copyright 2012
//
//                 Email: admin@ultra-embedded.com
//
//                         License: GPL
// If you would like a version with a more permissive license for
// use in closed source commercial applications please contact me
// for details.
//-----------------------------------------------------------------
//
// This file is open source HDL; you can redistribute it and/or 
// modify it under the terms of the GNU General Public License as 
// published by the Free Software Foundation; either version 2 of 
// the License, or (at your option) any later version.
//
// This file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public 
// License along with this file; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
// USA
//-----------------------------------------------------------------
module spdif_core
(
    input           clk_i,
    input           rst_i,
    // For 44.1 kHz, 44100x32x2x2 = 5,644,800 Hz
    // For 48 kHz,   48000x32x2x2 = 6,144,000 Hz
    // For 96 kHz,   96000x32x2x2 = 12,288,000 Hz
    input           bit_out_en_i,
    output          spdif_o,
    //input [47:0]    sample_i,
	 input [23:0]    sample_r,
	 input [23:0]    sample_l,
    output reg      sample_req_o
);

reg signed [23:0] audio_sample_q;
reg         [8:0] subframe_count_q;
reg               load_subframe_q;
reg         [7:0] preamble_q;
wire       [31:0] subframe_w;
reg         [5:0] bit_count_q;
reg               bit_toggle_q;
reg               spdif_out_q;
reg         [5:0] parity_count_q;

//-----------------------------------------------------------------
// Subframe Counter
//-----------------------------------------------------------------
always @(posedge rst_i or posedge clk_i )
begin
	if(rst_i == 1'b1)
		subframe_count_q <= 9'd0;
	else if(load_subframe_q)
	begin
		if(subframe_count_q == 9'd383)
			subframe_count_q <= 9'd0;
		else
			subframe_count_q <= subframe_count_q + 9'd1;
	end
end

//-----------------------------------------------------------------
// Sample capture
//-----------------------------------------------------------------
reg signed [23:0] sample_buf_q;

always @(posedge rst_i or posedge clk_i )
begin
	if(rst_i == 1'b1)
   begin
		audio_sample_q <= 0;
		sample_buf_q   <= 0;
		sample_req_o   <= 0;
   end
   else if(load_subframe_q)
   begin
		if(subframe_count_q[0] == 1'b0)
		begin
			audio_sample_q <= sample_l;
			sample_buf_q <= sample_r;
			//audio_sample_q <= sample_i[23:0];
			//sample_buf_q <= sample_i[47:24];
			sample_req_o <= 1'b1;
		end
		else
		begin
			audio_sample_q <= sample_buf_q;
			sample_req_o <= 1'b0;
		end
	end
	else
		sample_req_o <= 1'b0;
end

assign subframe_w[3:0] = 4'b0000;         // Preamble
assign subframe_w[27:4] = audio_sample_q; // Audio data
assign subframe_w[28] = 1'b0;             // Validity
assign subframe_w[29] = 1'b0;             // User bit
assign subframe_w[30] = 1'b0;             // Channel status bit
assign subframe_w[31] = 1'b0;             // Even parity bit

//-----------------------------------------------------------------
// Preamble
//-----------------------------------------------------------------
localparam PREAMBLE_Z = 8'b00010111;
localparam PREAMBLE_Y = 8'b00100111;
localparam PREAMBLE_X = 8'b01000111;

reg [7:0] preamble_r;

always @*
begin
	if(subframe_count_q == 9'd0)
		preamble_r = PREAMBLE_Z;
	else if(subframe_count_q[0] == 1'b1)
		preamble_r = PREAMBLE_Y;
	else
		preamble_r = PREAMBLE_X;
end

always @(posedge rst_i or posedge clk_i)
if(rst_i == 1'b1)
	preamble_q  <= 8'h00;
else if(load_subframe_q)
	preamble_q  <= preamble_r;

//-----------------------------------------------------------------
// Parity Counter
//-----------------------------------------------------------------
always @(posedge rst_i or posedge clk_i)
begin
	if(rst_i == 1'b1)
		parity_count_q  <= 6'd0;
   else if(bit_out_en_i)
   begin
		if(bit_count_q < 6'd8)
			parity_count_q  <= 6'd0;
		else if(bit_count_q < 6'd62)
			if(bit_count_q[0] == 0 && subframe_w[bit_count_q / 2] == 1'b1)
				parity_count_q <= parity_count_q + 6'd1;
   end
end

//-----------------------------------------------------------------
// Bit Counter
//-----------------------------------------------------------------
always @(posedge rst_i or posedge clk_i)
begin
	if(rst_i == 1'b1)
	begin
		bit_count_q     <= 6'b0;
		load_subframe_q <= 1'b1;
	end
	else if(bit_out_en_i)
	begin
		if(bit_count_q == 6'd63)
		begin
			bit_count_q     <= 6'd0;
			load_subframe_q <= 1'b1;
		end
		else
		begin
			bit_count_q     <= bit_count_q + 6'd1;
			load_subframe_q <= 1'b0;
		end
	end
	else
		load_subframe_q <= 1'b0;
end

//-----------------------------------------------------------------
// Bit half toggle
//-----------------------------------------------------------------
always @(posedge rst_i or posedge clk_i)
if(rst_i == 1'b1)
	bit_toggle_q <= 1'b0;
else if(bit_out_en_i)
	bit_toggle_q <= ~bit_toggle_q;

//-----------------------------------------------------------------
// Output bit (BMC encoded)
//-----------------------------------------------------------------
reg bit_r;

always @*
begin
	bit_r = spdif_out_q;
	if(bit_out_en_i)
	begin
		if(bit_count_q < 6'd8)
			bit_r = preamble_q[bit_count_q[2:0]];
		else if(bit_count_q < 6'd62)
		begin
			if(subframe_w[bit_count_q / 2] == 1'b0)
			begin
				if(bit_toggle_q == 1'b0)
					bit_r = ~spdif_out_q;
				else
					bit_r = spdif_out_q;
			end
			else
				bit_r = ~spdif_out_q;
		end
		else
		begin
			if(parity_count_q[0] == 1'b0)
			begin
				if(bit_toggle_q == 1'b0)
					bit_r = ~spdif_out_q;
				else
					bit_r = spdif_out_q;
			end
			else
				bit_r = ~spdif_out_q;
		end
	end
end

always @(posedge rst_i or posedge clk_i)
if(rst_i == 1'b1)
	spdif_out_q <= 1'b0;
else
	spdif_out_q <= bit_r;

assign spdif_o = spdif_out_q;

endmodule