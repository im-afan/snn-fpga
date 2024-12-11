/**
 * fifo for output mem potential 
 */

module mem_out_fifo (
	parameter integer CROSSBAR_NEURONS,
	parameter integer BRAM_DATA_WIDTH,
	parameter integer NETWORK_WIDTH,
	parameter integer LENGTH
)(
	input wire clk,
	input wire [NETWORK_WIDTH-1:0] din [CROSSBAR_NEURONS],
	input wire push,
	input wire pop,

	output wire signed [NETWORK_WIDTH-1:0] mem_out [CROSSBAR_NEURONS],
	output wire full,
	output wire empty,

	output reg push_done,
	output reg pop_done
);
	localparam WIDTH = CROSSBAR_NEURONS*NETWORK_WIDTH;

	reg [7:0] cnt = 0;
	reg [LENGTH*WIDTH-1:0] buffer;
	wire [WIDTH-1:0] din_local;
	generate
		genvar i, j;
		for(i = 0; i < CROSSBAR_NEURONS; i++) begin
			assign mem_out[i] = buffer[NETWORK_WIDTH*(i+1)-1 : NETWORK_WIDTH*i];
			assign din_local[NETWORK_WIDTH*(i+1)-1 : NETWORK_WIDTH*i] = din[i];
		end
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