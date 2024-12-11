/**
 * fifo for core idx 
 */

module mem_in_fifo (
	parameter integer CROSSBAR_NEURONS,
	parameter integer BRAM_DATA_WIDTH,
	parameter integer NETWORK_WIDTH,
	parameter integer LENGTH,
	parameter integer TILE_IDX_WIDTH
)(
	input wire clk,
	input wire [2*TILE_IDX_WIDTH-1:0] din,
	input wire push,
	input wire pop,

	output wire [TILE_IDX_WIDTH-1:0] core_idx_x,
	output wire [TILE_IDX_WIDTH-1:0] core_idx_y,
	output wire full,
	output wire empty

	output reg push_done,
	output reg pop_done
);
	localparam WIDTH = 2*TILE_IDX_WIDTH;

	reg [7:0] cnt = 0;
	reg [LENGTH*WIDTH-1:0] buffer;
	generate
		assign core_idx_x = buffer[TILE_IDX_WIDTH-1:0];
		assign core_idx_y = buffer[TILE_IDX_WIDTH*2-1:TILE_IDX_WIDTH];
	endgenerate

	assign full = (cnt >= LENGTH);
	assign empty = (cnt == 0);

	always (@posedge clk) begin
		if(pop && ~pop_done) begin
			buffer <= (buffer >> width);
			if(~empty) cnt <= cnt-1;
			pop_done <= 1;
		end	else (push && ~push_done) begin
			if(~full) begin
				buffer <= (buffer | (din_local << (cnt*width)));
				cnt <= cnt+1;	
			end
			push_done <= 1
		end

		if(~pop) begin
			pop_done <= 0;
		end
		if(~push) begin
			push_done <= 0;
		end
	end

endmodule