/* PASSED TESTS */

/*
 * Asynchronous streaming BRAM
 * Streams BRAM and pushes to FIFOs neccessary for spike accumulation
 * in synaptic array
 * reads: network_input 
 */

 // NEED: BRAM_DATA_WIDTH = CROSSBAR_NEURONS * NETWORK_WIDTH

module input_bram #(
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

    input wire tile_use_input,
    input wire new_tile, 
    input wire [TILE_IDX_WIDTH-1:0] tile_idx,
    input wire [TILE_IDX_WIDTH-1:0] tile_idx_x,
    input wire [TILE_IDX_WIDTH-1:0] tile_idx_y,

    input wire input_fifo_full,
    input wire input_fifo_push_done,
    output reg input_fifo_push,
    output reg [CROSSBAR_NEURONS*NETWORK_WIDTH-1:0] input_fifo_din,

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

    localparam integer NETWORK_INPUT_OFFSET = 0; 

    assign din = 0;
    assign bram_rst = 0;

    reg [2:0] bram_done;
    reg [4:0] bram_step;

    wire fifo_done;
    assign fifo_done = (input_fifo_push_done || ~input_fifo_push);
    wire fifo_full;
    assign fifo_full = input_fifo_full;
    reg go;

    reg prev_new_tile;

    always_ff @(posedge clk) begin
        if(~enable) begin
            bram_step <= SEND;
            bram_en <= 0;
            input_fifo_push <= 0;
            tile_done <= 1;
            go <= 0;
        end else begin
            if(new_tile && ~prev_new_tile && ~go) begin
                go <= 1;
                bram_step <= SEND;
                bram_en <= 0;
                input_fifo_push <= 0;
            end
            else if(fifo_done && ~fifo_full && go) begin
                if(bram_step == SEND) begin
                    tile_done <= 0;
                    addr <= NETWORK_INPUT_OFFSET + tile_idx_y * CROSSBAR_NEURONS * NETWORK_WIDTH / 8;
                    bram_done <= 0;
                    bram_step <= WAIT;
                    bram_en <= 1;
                    bram_we <= 0;
                    input_fifo_push <= 0;
                end else if(bram_step == WAIT) begin
                    if(bram_done > 0) begin
                        if(tile_use_input) input_fifo_din <= dout;
                        else input_fifo_din <= 0;
                        input_fifo_push <= 1;
                        bram_step <= INCREMENT;
                        bram_en <= 0;
                    end else begin
                        bram_done <= bram_done + 1; // wait 1 clock cycle for bram to finish if it is active
                    end
                end else if(bram_step == INCREMENT) begin
                    tile_done <= 1;
                    go <= 0;
                end
            end
        end
        prev_new_tile <= new_tile;
    end

endmodule