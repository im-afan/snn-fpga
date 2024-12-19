/**
 * fifo for tile idx 
 */

/* PASSED TESTS */

module tile_idx_fifo #(
	parameter integer CROSSBAR_NEURONS,
	parameter integer BRAM_DATA_WIDTH,
	parameter integer NETWORK_WIDTH,
	parameter integer LENGTH,
	parameter integer TILE_IDX_WIDTH
)(
	input wire clk,
	input wire en,

	input wire use_input_din,	
	input wire [2*TILE_IDX_WIDTH-1:0] din,
	input wire push,

	input wire pop,

	output wire [TILE_IDX_WIDTH-1:0] tile_idx_x,
	output wire [TILE_IDX_WIDTH-1:0] tile_idx_y,
	output wire use_input,
	output wire full,
	output wire empty,

	output reg push_done, // TODO maybe need 2 done signals? theoretically only 1 will have push on at a time though
	output reg pop_done
);
	localparam WIDTH = 2*TILE_IDX_WIDTH;

	reg [7:0] cnt = 0;
	reg [LENGTH*WIDTH-1:0] buffer;
	reg [LENGTH-1:0] use_input_buffer;
	generate
		assign tile_idx_x = buffer[TILE_IDX_WIDTH-1:0];
		assign tile_idx_y = buffer[TILE_IDX_WIDTH*2-1:TILE_IDX_WIDTH];
		assign use_input = use_input_buffer[0];
	endgenerate

	assign full = (cnt >= LENGTH);
	assign empty = (cnt == 0);

	always_ff @(posedge clk) begin
		if(~en) begin
			pop_done <= 1;
			push_done <= 1;
			buffer <= 0;
			cnt <= 0;
		end else begin
			if(pop && ~pop_done) begin
				buffer <= (buffer >> WIDTH);
				use_input_buffer <= (use_input_buffer >> 1);
				if(~empty) cnt <= cnt-1;
				pop_done <= 1;
			end	else if(push && ~push_done) begin
				if(~full) begin
					buffer <= (buffer | (din << (cnt*WIDTH)));
					use_input_buffer <= (use_input_buffer | (use_input_din << cnt));
					cnt <= cnt+1;	
				end
				push_done <= 1;
			end

			if(~pop) begin
				pop_done <= 0;
			end
			if(~push) begin
				push_done <= 0;
			end
		end
	end

endmodule