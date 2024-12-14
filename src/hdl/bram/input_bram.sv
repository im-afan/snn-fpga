/* PASSED TESTS */

/*
 * Asynchronous input BRAM controller
 * reads network_input values from BRAM
 * and pushes them to mac_in and tile_idx
 */

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

    input wire mac_out_fifo_full,
    input wire tile_idx_fifo_full,
    
    input wire mac_out_fifo_push_done,
    input wire tile_idx_fifo_push_done,

    output reg [CROSSBAR_NEURONS*NETWORK_WIDTH-1:0] mac_out_fifo_din,
    output reg [2*TILE_IDX_WIDTH-1:0] tile_idx_fifo_din,

    output reg mac_out_fifo_push,
    output reg tile_idx_fifo_push,

    output reg [BRAM_ADDR_WIDTH-1:0] addr,
    input wire [BRAM_DATA_WIDTH-1:0] dout,
    output reg [BRAM_DATA_WIDTH-1:0] din,
    output reg bram_en,
    output reg bram_rst,
    output reg [BRAM_DATA_WIDTH/8-1:0] bram_we,
    output reg bram_want_active,
    input wire bram_active // if this port is active in switcher
);
    localparam integer SEND = 0;
    localparam integer WAIT = 1;
    localparam integer INCREMENT = 2;

    localparam integer TILE_IDX_BITS = ((2*TILE_IDX_WIDTH*MAX_TILES) / BRAM_DATA_WIDTH + 1) * BRAM_DATA_WIDTH;
    localparam integer WEIGHT_BITS = ((MAX_TILES*CROSSBAR_NEURONS*CROSSBAR_NEURONS*NETWORK_WIDTH) / BRAM_DATA_WIDTH + 1) * BRAM_DATA_WIDTH;
    localparam integer NETWORK_INPUT_BITS = ((MAX_NEURONS*NETWORK_WIDTH) / BRAM_DATA_WIDTH + 1) * BRAM_DATA_WIDTH;
    localparam integer SPK_OUT_BITS = ((MAX_NEURONS) / BRAM_DATA_WIDTH + 1) * BRAM_DATA_WIDTH;
    localparam integer FLAGS_BITS = 1024;

    localparam integer TILE_IDX_OFFSET = 0;
    localparam integer WEIGHT_OFFSET = TILE_IDX_OFFSET + TILE_IDX_BITS / 8;
    localparam integer NETWORK_INPUT_OFFSET = WEIGHT_OFFSET + WEIGHT_BITS / 8;
    localparam integer SPK_OUT_OFFSET = NETWORK_INPUT_OFFSET + NETWORK_INPUT_BITS / 8;
    localparam integer FLAGS_OFFSET = SPK_OUT_OFFSET + SPK_OUT_BITS / 8;
    localparam integer MEM_OFFSET = FLAGS_OFFSET + FLAGS_BITS / 8;

    reg bram_done;
    reg [4:0] bram_step = SEND;

    wire fifo_done;
    assign fifo_done = (tile_idx_fifo_push_done || ~tile_idx_fifo_push) 
                    && (mac_out_fifo_push_done || ~mac_out_fifo_push_done);

    wire fifo_full;
    assign fifo_full = tile_idx_fifo_full || mac_out_fifo_full;

    wire tiles_done;
    reg [TILE_IDX_WIDTH-1:0] tile_idx;
    assign tiles_done = (tile_idx == (MAX_NEURONS / CROSSBAR_NEURONS));
    assign bram_want_active = ~tiles_done;

    wire [11:0] tile_idx_base;
    assign tile_idx_base = tile_idx % (BRAM_DATA_WIDTH / CROSSBAR_NEURONS / NETWORK_WIDTH);
    wire [CROSSBAR_NEURONS*NETWORK_WIDTH-1:0] mac_out_slices[BRAM_DATA_WIDTH / CROSSBAR_NEURONS / NETWORK_WIDTH];
    
    generate
        genvar i, j;
        for(i = 0; i < BRAM_DATA_WIDTH / CROSSBAR_NEURONS / NETWORK_WIDTH; i++) begin
            for(j = 0; j < CROSSBAR_NEURONS; j++) begin
                assign mac_out_slices[i][j*NETWORK_WIDTH+NETWORK_WIDTH-1 : j*NETWORK_WIDTH] 
                    = dout[i*CROSSBAR_NEURONS*NETWORK_WIDTH+j*NETWORK_WIDTH+NETWORK_WIDTH-1 : i*CROSSBAR_NEURONS*NETWORK_WIDTH+j*NETWORK_WIDTH];
            end
        end
    endgenerate

    always @(posedge clk) begin
        if(~enable) begin
            bram_step <= SEND;
            tile_idx <= 0; 
            bram_en <= 0;
            bram_we <= 0;
            mac_out_fifo_push <= 0;
            tile_idx_fifo_push <= 0;
            bram_done <= 0;
        end else begin
            if(fifo_done && ~fifo_full && ~tiles_done) begin
                if(bram_step == SEND) begin
                    addr <= NETWORK_INPUT_OFFSET + tile_idx*CROSSBAR_NEURONS*NETWORK_WIDTH/8;
                    bram_we <= 0;
                    bram_en <= 1;
                    bram_done <= 0;
                    bram_step <= WAIT;
                    tile_idx_fifo_din <= (tile_idx << TILE_IDX_WIDTH) + tile_idx;
                end else if(bram_step == WAIT) begin
                    if(bram_done) begin
                        bram_en <= 0;
                        mac_out_fifo_din <= mac_out_slices[tile_idx_base];
                        mac_out_fifo_push <= 1;
                        tile_idx_fifo_push <= 1;
                        bram_step <= INCREMENT;
                    end
                    else bram_done <= bram_active;
                end else if(bram_step == INCREMENT) begin
                    tile_idx <= tile_idx+1;
                    bram_step <= SEND;
                    mac_out_fifo_push <= 0;
                    tile_idx_fifo_push <= 0;
                end
            end else begin
                tile_idx_fifo_push <= 0;
                mac_out_fifo_push <= 0;
                bram_en <= 0;
                bram_we <= 0; 
            end
        end
    end
endmodule