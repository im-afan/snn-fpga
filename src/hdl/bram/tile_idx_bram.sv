/* PASSED TESTS */

/*
 * Asynchronous streaming BRAM
 * Streams BRAM and pushes to FIFOs neccessary for spike accumulation
 * in synaptic array
 * reads: weight, spk_in, tile_idx
 */

 // NEED: BRAM_DATA_WIDTH = 2*TILE_IDX_WIDTH

module tile_idx_bram #(
    parameter integer BRAM_ADDR_WIDTH,
    parameter integer BRAM_DATA_WIDTH,
    parameter integer NETWORK_WIDTH,
    parameter integer MAX_TILES,
    parameter integer MAX_NEURONS,
    parameter integer TILE_IDX_WIDTH,
    parameter integer CROSSBAR_NEURONS
) (
    input wire clk, 
    input wire enable,

    input wire buff_idx,
    
    input wire [MAX_NEURONS / CROSSBAR_NEURONS - 1 : 0] has_spk, // for skipping nonspikes

    input wire tile_idx_fifo_full,
    input wire tile_idx_fifo_push_done,
    output reg tile_idx_fifo_push,
    output reg tile_use_input_fifo_din,
    output reg [2*TILE_IDX_WIDTH-1:0] tile_idx_fifo_din,
    output reg [TILE_IDX_WIDTH-1:0] tile_idx,
    output reg [TILE_IDX_WIDTH-1:0] tile_idx_x,
    output reg [TILE_IDX_WIDTH-1:0] tile_idx_y,
    
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

    localparam integer TILE_IDX_OFFSET = 0;

    assign din = 0;
    assign bram_rst = 0;

    reg [2:0] bram_done;
    reg [4:0] bram_step;
    wire tiles_done;
    assign tiles_done = (tile_idx == MAX_TILES);

    wire fifo_done;
    assign fifo_done = (tile_idx_fifo_push_done || ~tile_idx_fifo_push);
    wire fifo_full;
    assign fifo_full = tile_idx_fifo_full;

    wire [TILE_IDX_WIDTH-1:0] tile_idx_x_local;
    wire [TILE_IDX_WIDTH-1:0] tile_idx_y_local;
    assign tile_idx_x_local = dout[TILE_IDX_WIDTH-1:0];
    assign tile_idx_y_local = dout[2*TILE_IDX_WIDTH-1:TILE_IDX_WIDTH];
    //assign tile_idx_x = tile_idx_x_local;
    //assign tile_idx_y = tile_idx_y_local;
    //reg [MAX_NEURONS / CROSSBAR_NEURONS - 1 : 0] has_spk [2]; // for skipping nonspike tiles
    //assign has_spk[0] = ~0;
    //assign has_spk[1] = ~0;
    
    reg [MAX_NEURONS / CROSSBAR_NEURONS - 1 : 0] used_input;  // only use network input for the 1st cycle with that tile

    //assign tile_idx_fifo_din = dout;

    always_ff @(posedge clk) begin
        if(~enable) begin
            bram_step <= SEND;
            tile_idx <= 0;
            bram_en <= 0;
            tile_idx_fifo_push <= 0;
            used_input <= 0;
        end else begin
            if(fifo_done && ~fifo_full && ~tiles_done) begin
                if(bram_step == SEND) begin
                    addr <= TILE_IDX_OFFSET + tile_idx * 2 * TILE_IDX_WIDTH/8;
                    bram_done <= 0;
                    bram_step <= WAIT;
                    bram_en <= 1;
                    bram_we <= 0;
                    tile_idx_fifo_push <= 0;
                end else if(bram_step == WAIT) begin
                    if(bram_done > 3) begin
                        if(has_spk[tile_idx_x_local] || ~used_input[tile_idx_y_local]) begin
                        //if(1) begin
                            if(~used_input[tile_idx_y_local]) begin
                                used_input[tile_idx_y_local] <= 1;
                                tile_use_input_fifo_din <= 1;
                            end else begin
                                tile_use_input_fifo_din <= 0;
                            end
                            tile_idx_fifo_din <= dout; 
                            tile_idx_x <= tile_idx_x_local;
                            tile_idx_y <= tile_idx_y_local;
                            tile_idx_fifo_push <= 1; 
                        end else begin
                            tile_idx_fifo_push <= 0;
                        end
                        bram_step <= INCREMENT;
                        bram_en <= 0;
                    end else begin
                        bram_done <= bram_done + 1; // wait 1 clock cycle for bram to finish if it is active
                    end
                end else if(bram_step == INCREMENT) begin
                    tile_idx_fifo_push <= 0;
                    tile_idx <= tile_idx + 1;
                    bram_step <= SEND;
                end
            end
        end
    end

endmodule