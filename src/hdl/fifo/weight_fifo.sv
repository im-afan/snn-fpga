module weight_fifo (
	parameter integer CROSSBAR_NEURONS,
	parameter integer BRAM_DATA_WIDTH,
	parameter integer NETWORK_WIDTH,
	parameter integer LENGTH
)(
	input wire clk,
	input wire [BRAM_DATA_WIDTH-1:0] din,
	input wire push,
	input wire pop,

	output wire [NETWORK_WIDTH-1:0] weight [CROSSBAR_NEURONS][CROSSBAR_NEURONS],
	output wire full,
	output wire empty,

	output reg push_done,
	output reg pop_done
);
	localparam WIDTH = CROSSBAR_NEURONS*CROSSBAR_NEURONS*NETWORK_WIDTH;

	reg [7:0] cnt = 0;
	reg [LENGTH*WIDTH-1:0] buffer;
	generate
		genvar i, j;
		genvar prev_idx, cur_idx;
		prev_idx = 0;
		for(i = 0; i < CROSSBAR_NEURONS; i++) begin
			for(j = 0; j < CROSSBAR_NEURONS; j++) begin
				cur_idx = CROSSBAR_NEURONS*i+j;
				assign weight[i][j] = buffer[NETWORK_WIDTH*(cur_idx+1)-1 : NETWORK_WIDTH*cur_idx];
				//prev_idx = cur_idx;
			end
		end
	endgenerate

	assign full = (cnt >= LENGTH);
	assign empty = (cnt == 0);

	always (@posedge clk) begin
		if(pop && ~pop_done) begin
			buffer <= (buffer >> width);
			pop_done <= 1;
			if(~empty) cnt <= cnt-1;
		end	else (push && ~push_done) begin
			if(~full) begin
				buffer <= (buffer | (din << (cnt*width)));
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

endmodule