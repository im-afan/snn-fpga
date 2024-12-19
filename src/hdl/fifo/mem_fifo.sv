/**
 * fifo for input/output spike accumulation 
 * todo naming????
 */

module mem_fifo #(
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

	output wire [NETWORK_WIDTH-1:0] mem [CROSSBAR_NEURONS],
	output wire full,
	output wire empty,

	output reg push_done,
	output reg pop_done
);
	localparam WIDTH = CROSSBAR_NEURONS*NETWORK_WIDTH;

    reg [7:0] write_ptr, read_ptr;
	reg [7:0] diff;

    assign empty = (diff == 0);
    assign full = (diff == LENGTH);

	reg [WIDTH-1:0] buffer [LENGTH];

	generate
		genvar i, j;
		for(i = 0; i < CROSSBAR_NEURONS; i++) begin
			assign mem[i] = buffer[read_ptr][NETWORK_WIDTH*(i+1)-1 : NETWORK_WIDTH*i];
		end
	endgenerate

	always_ff @(posedge clk) begin
		if(~en) begin
			pop_done <= 1;
			push_done <= 1;
            for(integer k = 0; k < LENGTH; k++) buffer[k] <= 0;
            read_ptr <= 0;
            write_ptr <= 0;
            diff <= 0;
		end else begin
			if(pop && ~pop_done) begin
				if(~empty) begin
                    read_ptr <= (read_ptr + 1) % LENGTH;
					diff <= diff-1;
				end
                pop_done <= 1;
			end	else if(push && ~push_done) begin
				if(~full) begin
                    buffer[write_ptr] <= din;
                    write_ptr <= (write_ptr + 1) % LENGTH;  // might be probematic race condition??? 
                    diff <= diff+1;
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