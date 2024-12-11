/**
 * fifo for core outputs spikes
 */

module spk_out_fifo (
	parameter integer CROSSBAR_NEURONS,
	parameter integer BRAM_DATA_WIDTH,
	parameter integer NETWORK_WIDTH,
	parameter integer LENGTH
)(
	input wire clk,
	input wire [CROSSBAR_NEURONS-1:0] din,
	input wire push,
	input wire pop,

	output wire [CROSSBAR_NEURONS-1:0] spk_out,
	output wire full,
	output wire empty

	output reg push_done,
	output reg pop_done
);
	localparam WIDTH = CROSSBAR_NEURONS;

	reg [7:0] cnt = 0;
	reg [LENGTH*WIDTH-1:0] buffer;
	generate
		genvar i, j;
		for(i = 0; i < CROSSBAR_NEURONS; i++) begin
			assign spk_out[i] = buffer[i];
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