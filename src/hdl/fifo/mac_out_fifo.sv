/**
 * fifo for output spike accumulation 
 */

/* TODO UNTESTED */

module mac_out_fifo #(
	parameter integer CROSSBAR_NEURONS,
	parameter integer BRAM_DATA_WIDTH,
	parameter integer NETWORK_WIDTH,
	parameter integer LENGTH
)(
	input wire clk,
	input wire en,
	input wire [CROSSBAR_NEURONS*NETWORK_WIDTH-1:0] din,
	input wire push,
	input wire pop,

	output wire [NETWORK_WIDTH-1:0] mac_out [CROSSBAR_NEURONS],
	output wire full,
	output wire empty,

	output reg push_done,
	output reg pop_done
);
	localparam WIDTH = CROSSBAR_NEURONS*NETWORK_WIDTH;

	reg [7:0] cnt = 0;
	reg [LENGTH*WIDTH-1:0] buffer = 0;
	generate
		genvar i, j;
		for(i = 0; i < CROSSBAR_NEURONS; i++) begin
			assign mac_out[i] = buffer[NETWORK_WIDTH*(i+1)-1 : NETWORK_WIDTH*i];
		end
	endgenerate

	assign full = (cnt >= LENGTH);
	assign empty = (cnt == 0);

	always @(posedge clk) begin
		if(~en) begin
			pop_done <= 1;
			push_done <= 1;
			buffer <= 0;
			cnt <= 0;
		end else begin
			if(pop && ~pop_done) begin
				buffer <= (buffer >> WIDTH);
				pop_done <= 1;
				if(~empty) begin
					cnt <= cnt-1;
				end
			end	else if(push && ~push_done) begin
				if(~full) begin
					buffer <= (buffer | (din << (cnt*WIDTH)));
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