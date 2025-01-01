/* PASSED TESTS */

/*
 * Asynchronous streaming BRAM
 * Streams BRAM and pushes to FIFOs neccessary for spike accumulation
 * in synaptic array
 * reads: weight
 */

module weight_bram #(
    parameter integer BRAM_ADDR_WIDTH,
    parameter integer BRAM_DATA_WIDTH,
    parameter integer NETWORK_WIDTH,
    parameter integer MAX_TILES,
    parameter integer TILE_IDX_WIDTH,
    parameter integer MAX_NEURONS,
    parameter integer CROSSBAR_NEURONS
) (
    input wire clk, 
    input wire enable,

    input wire new_tile,
    input wire [TILE_IDX_WIDTH-1:0] tile_idx,
    input wire [TILE_IDX_WIDTH-1:0] tile_idx_x,
    input wire [TILE_IDX_WIDTH-1:0] tile_idx_y,

    input wire weight_fifo_full,
    input wire weight_fifo_push_done,
    output reg weight_fifo_push,
    output reg [BRAM_DATA_WIDTH-1:0] weight_fifo_din,

    output reg tile_done,
    
    output reg [BRAM_ADDR_WIDTH-1:0]  addr,
    input wire [BRAM_DATA_WIDTH-1:0] dout,
    output reg [BRAM_DATA_WIDTH-1:0] din,
    output reg bram_en,
    output reg bram_rst,
    output reg [BRAM_DATA_WIDTH/8-1:0] bram_we
);
    localparam integer SEND = 0; // send addr to bram
    localparam integer WAIT = 1; // wait for bram
    localparam integer INCREMENT = 2; // increment idx 

    localparam integer WEIGHT_OFFSET = 0;

    assign din = 0;
    assign bram_rst = 0;

    reg [2:0] bram_done;
    reg [4:0] bram_step;

    reg [15:0] weight_idx; // takes multiple steps to read weight
    assign local_tile_done = (weight_idx == CROSSBAR_NEURONS*CROSSBAR_NEURONS) && weight_fifo_push_done;

    wire fifo_done;
    assign fifo_done = (weight_fifo_push_done || ~weight_fifo_push);
    wire fifo_full;
    assign fifo_full = weight_fifo_full;
    reg go;
    reg prev_new_tile;

    assign weight_fifo_din = dout;
 
    always_ff @(posedge clk) begin
        if(~enable) begin
            bram_step <= SEND;
            weight_idx <= 0;
            bram_en <= 0;
            weight_fifo_push <= 0;
            go <= 0;
            tile_done <= 0;
        end else begin
            if(local_tile_done) begin
                tile_done <= 1;
                go <= 0;
                weight_idx <= 0;
            end
            else if(new_tile && ~prev_new_tile && ~go) begin
                go <= 1;
                weight_idx <= 0;
                bram_step <= SEND;
                bram_en <= 0;
                weight_fifo_push <= 0;
            end
            else if(fifo_done && ~fifo_full && go) begin
                if(bram_step == SEND) begin
                    tile_done <= 0;
                    addr <= WEIGHT_OFFSET + CROSSBAR_NEURONS*CROSSBAR_NEURONS*NETWORK_WIDTH/8*tile_idx + weight_idx;
                    bram_done <= 0;
                    bram_step <= WAIT;
                    bram_en <= 1;
                    bram_we <= 0;
                    weight_fifo_push <= 0;
                end else if(bram_step == WAIT) begin
                    if(bram_done > 1) begin
                        //weight_fifo_din <= dout;
                        weight_fifo_push <= 1;
                        bram_step <= INCREMENT;
                        bram_en <= 0;
                    end else begin
                        bram_done <= bram_done + 1; // wait 1 clock cycle for bram to finish if it is active
                    end
                end else if(bram_step == INCREMENT) begin
                    weight_fifo_push <= 0;
                    weight_idx <= weight_idx + BRAM_DATA_WIDTH / NETWORK_WIDTH;
                    bram_step <= SEND;
                end
            end
        end
        prev_new_tile <= new_tile;
    end

endmodule