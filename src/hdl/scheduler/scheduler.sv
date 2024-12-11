module scheduler(
    parameter integer MAX_NEURONS,
    parameter integer NETWORK_WIDTH,
    parameter integer NEURONS_PER_TILE,
    parameter integer BRAM_ADDR_WIDTH,
    parameter integer BRAM_DATA_WIDTH,
    parameter integer MAX_TILES,
    parameter integer TILE_IDX_WIDTH,

) (
	input wire clk,
	input wire en,

	input wire weight_fifo_empty,
	input wire mem_in_fifo_empty,
	input wire spk_in_fifo_empty,
	input wire tile_idx_fifo_empty,

	input wire weight_fifo_pop_done,
	input wire mem_in_fifo_pop_done,
	input wire spk_in_fifo_pop_done,
	input wire tile_idx_fifo_pop_done,

	input wire crossbar_done,

	input wire [NETWORK_WIDTH-1:0] weight [NEURONS_PER_TILE][NEURONS_PER_TILE],
	input wire [NETWORK_WIDTH-1:0] mem_in [NEURONS_PER_TILE],
	input wire [NEURONS_PER_TILE-1:0] spk_in,
	input wire [TILE_IDX_WIDTH-1:0] tile_idx_x_in,
	input wire [TILE_IDX_WIDTH-1:0] tile_idx_y_in,

	output reg weight_fifo_pop,
	output reg mem_in_fifo_pop,
	output reg spk_in_fifo_pop,
	output reg tile_idx_fifo_pop,

	output wire [NEURONS_PER_TILE-1:0] spk_out,
	output wire [NETWORK_WIDTH-1:0] mem_out [NEURONS_PER_TILE],
	output wire [TILE_IDX_WIDTH-1:0] tile_idx_x_out,
	output wire [TILE_IDX_WIDTH-1:0] tile_idx_y_out

	output wire crossbar_en,
);
	wire ready;
	wire pop_done;
	assign ready = ~(weight_fifo_empty || mem_in_fifo_empty || spk_in_fifo_empty || tile_idx_fifo_empty);
	assign pop_done = weight_fifo_pop_done && mem_in_fifo_pop_done && spk_in_fifo_pop_done && tile_idx_fifo_pop_done;

	always (@posedge clk) begin
		if(en) begin
			if(ready && pop_done) begin
				if(~crossbar_done) begin
					crossbar_en <= 1;	
				end else begin
					crossbar_en <= 0;
					weight_fifo_pop <= 1;
					mem_in_fifo_pop <= 1;
					spk_in_fifo_pop <= 1;
					tile_idx_fifo_pop <= 1;
				end
			end	else begin 
				crossbar_en <= 0;
			end
		end
	end
endmodule