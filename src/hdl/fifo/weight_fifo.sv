module weight_fifo #(
	parameter integer CROSSBAR_NEURONS,
	parameter integer BRAM_DATA_WIDTH,
	parameter integer NETWORK_WIDTH,
	parameter integer LENGTH
)(
	input wire clk,
	input wire en,

	input wire [BRAM_DATA_WIDTH-1:0] din,
	input wire push,
	input wire pop,

	output wire [NETWORK_WIDTH-1:0] weight [CROSSBAR_NEURONS][CROSSBAR_NEURONS],
	output wire full,
	output wire empty,

	output reg push_done,
	output reg pop_done
);
    localparam DIN_WIDTH = BRAM_DATA_WIDTH;
    localparam WIDTH = CROSSBAR_NEURONS*CROSSBAR_NEURONS*NETWORK_WIDTH;
    localparam DIN_PER_WIDTH = WIDTH / DIN_WIDTH;

    reg [7:0] read_ptr, write_ptr;
    reg [7:0] diff;
    assign full = (diff == LENGTH*DIN_PER_WIDTH);
    assign empty = (diff == 0);

    reg [BRAM_DATA_WIDTH-1:0] buffer [LENGTH * DIN_PER_WIDTH];

    generate
        genvar i, j;
        for(i = 0; i < CROSSBAR_NEURONS; i++) begin
            for(j = 0; j < CROSSBAR_NEURONS; j++) begin
                localparam k = (NETWORK_WIDTH * (i*CROSSBAR_NEURONS+j)) / BRAM_DATA_WIDTH;
                localparam l = (NETWORK_WIDTH * (i*CROSSBAR_NEURONS+j)) % BRAM_DATA_WIDTH;
                assign weight[i][j] = buffer[read_ptr + k][l + NETWORK_WIDTH-1 : l];
				wire [NETWORK_WIDTH-1:0] weight_debug;
				assign weight_debug = buffer[read_ptr + k][l + NETWORK_WIDTH-1 : l];
            end
        end
    endgenerate

    always_ff @(posedge clk) begin
		if(~en) begin
			pop_done <= 1;
			push_done <= 1;
            read_ptr <= 0;
            write_ptr <= 0;
            diff <= 0;
            for(integer i = 0; i < LENGTH*DIN_PER_WIDTH; i++)
                buffer[i] <= 0;
		end else begin
			if(pop && ~pop_done) begin
                if(~empty) begin
                    read_ptr <= (read_ptr + DIN_PER_WIDTH) % (LENGTH*DIN_PER_WIDTH);
                    diff <= diff - DIN_PER_WIDTH;
                end
				pop_done <= 1;
			end
			if(push && ~push_done) begin
				if(~full) begin
                    buffer[write_ptr] <= din;
                    write_ptr <= (write_ptr + 1) % (LENGTH*DIN_PER_WIDTH);
                    diff <= diff + 1;
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