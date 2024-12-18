/* PASSED TESTS */

/*
 * Asynchronous streaming BRAM
 * Streams BRAM and pushes to FIFOs neccessary for spike accumulation
 * in synaptic array
 * reads: weight, spk_in, tile_idx
 */

module xbar_bram #(
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

    input wire buff_idx,

    input wire weight_fifo_full,
    input wire spk_in_fifo_full,
    input wire tile_idx_fifo_full,

    input wire weight_fifo_push_done,
    input wire spk_in_fifo_push_done,
    input wire tile_idx_fifo_push_done,

    output reg weight_fifo_push,
    output reg spk_in_fifo_push,
    output reg tile_idx_fifo_push,

    output reg [BRAM_DATA_WIDTH-1:0] weight_fifo_din,
    output reg [CROSSBAR_NEURONS-1:0] spk_in_fifo_din,
    output reg [2*TILE_IDX_WIDTH-1:0] tile_idx_fifo_din,
    
    output reg [BRAM_ADDR_WIDTH-1:0]  addr,
    input wire [BRAM_DATA_WIDTH-1:0] dout,
    output reg [BRAM_DATA_WIDTH-1:0] din,
    output reg bram_en,
    output reg bram_rst,
    output reg [BRAM_DATA_WIDTH/8-1:0] bram_we,
    output reg bram_want_active,
    input wire bram_active
);
    localparam integer SEND = 0; // send addr to bram
    localparam integer WAIT = 1; // wait for bram
    localparam integer INCREMENT = 2; // increment idx 

    localparam integer READ_IDX = 0;
    localparam integer READ_SPK = 1;
    localparam integer READ_WEIGHTS = 2;

    localparam integer TILE_IDX_BITS = ((2*TILE_IDX_WIDTH*MAX_TILES) / BRAM_DATA_WIDTH + 1) * BRAM_DATA_WIDTH;
    localparam integer WEIGHT_BITS = ((MAX_TILES*CROSSBAR_NEURONS*CROSSBAR_NEURONS*NETWORK_WIDTH) / BRAM_DATA_WIDTH + 1) * BRAM_DATA_WIDTH;
    localparam integer NETWORK_INPUT_BITS = ((MAX_NEURONS*NETWORK_WIDTH) / BRAM_DATA_WIDTH + 1) * BRAM_DATA_WIDTH;
    localparam integer SPK_OUT_BITS = 2 * ((MAX_NEURONS) / BRAM_DATA_WIDTH + 1) * BRAM_DATA_WIDTH;
    localparam integer FLAGS_BITS = 1024;
    
    localparam integer SPK_OUT_BITS_ONE = ((MAX_NEURONS) / BRAM_DATA_WIDTH + 1) * BRAM_DATA_WIDTH;

    localparam integer TILE_IDX_OFFSET = 0;
    localparam integer WEIGHT_OFFSET = TILE_IDX_OFFSET + TILE_IDX_BITS / 8;
    localparam integer NETWORK_INPUT_OFFSET = WEIGHT_OFFSET + WEIGHT_BITS / 8;
    localparam integer SPK_OUT_OFFSET = NETWORK_INPUT_OFFSET + NETWORK_INPUT_BITS / 8;
    localparam integer FLAGS_OFFSET = SPK_OUT_OFFSET + SPK_OUT_BITS / 8;
    localparam integer MEM_OFFSET = FLAGS_OFFSET + FLAGS_BITS / 8;

    assign din = 0;
    assign bram_rst = 0;

    reg [2:0] bram_done;
    reg [4:0] bram_step;
    reg [4:0] param_step;
    reg [15:0] tile_idx;
    reg [15:0] weight_idx; // takes multiple steps to read weight
    wire tiles_done;
    assign tiles_done = (tile_idx == MAX_TILES);
    assign bram_want_active = ~tiles_done;

    wire fifo_done;
    assign fifo_done = (weight_fifo_push_done || ~weight_fifo_push) && (spk_in_fifo_push_done || ~spk_in_fifo_push)
                     && (tile_idx_fifo_push_done || ~tile_idx_fifo_push);

    wire fifo_full;
    assign fifo_full = weight_fifo_full || spk_in_fifo_full || tile_idx_fifo_full;

    reg [TILE_IDX_WIDTH-1:0] tile_idx_x;
    reg [TILE_IDX_WIDTH-1:0] tile_idx_y;

    wire [10:0] tile_idx_base;
    assign tile_idx_base = (tile_idx) % (BRAM_DATA_WIDTH / (2*TILE_IDX_WIDTH));
    wire [10:0] spk_in_idx_base;
    assign spk_in_idx_base = (tile_idx_x % (BRAM_DATA_WIDTH / CROSSBAR_NEURONS));

    wire [2*TILE_IDX_WIDTH-1:0] tile_idx_slices [BRAM_DATA_WIDTH / (2*TILE_IDX_WIDTH)];
    wire [CROSSBAR_NEURONS-1:0] spk_in_slices [BRAM_DATA_WIDTH / CROSSBAR_NEURONS];


    wire [11:0] buff_offset_read;
    assign buff_offset_read = buff_idx ? SPK_OUT_BITS_ONE / 8 : 0;


    generate 
        genvar i;
        for(i = 0; i < BRAM_DATA_WIDTH / (2*TILE_IDX_WIDTH); i++) begin
            assign tile_idx_slices[i] = dout[(i+1)*2*TILE_IDX_WIDTH-1 : i*2*TILE_IDX_WIDTH];
        end
        for(i = 0; i < BRAM_DATA_WIDTH / CROSSBAR_NEURONS; i++) begin
            assign spk_in_slices[i] = dout[(i+1)*CROSSBAR_NEURONS-1 : i*CROSSBAR_NEURONS];
        end
    endgenerate

    always_ff @(posedge clk) begin
        if(~enable) begin
            bram_step <= SEND;
            param_step <= READ_IDX;
            tile_idx <= 0;
            weight_idx <= 0;
            bram_en <= 0;
            tile_idx_fifo_push <= 0;
            weight_fifo_push <= 0;
            spk_in_fifo_push <= 0;

        end else begin
            if(fifo_done && ~fifo_full && ~tiles_done) begin
                if(bram_step == SEND) begin
                    case(param_step)
                        READ_IDX: addr <= TILE_IDX_OFFSET + tile_idx * 2*TILE_IDX_WIDTH/8;
                        READ_WEIGHTS: addr <= WEIGHT_OFFSET + CROSSBAR_NEURONS*CROSSBAR_NEURONS*NETWORK_WIDTH/8*tile_idx + weight_idx;
                        READ_SPK: addr <= SPK_OUT_OFFSET + tile_idx_x + buff_offset_read;
                    endcase
                    bram_done <= 0;
                    bram_step <= WAIT;
                    bram_en <= 1;
                    bram_we <= 0;

                    tile_idx_fifo_push <= 0;
                    weight_fifo_push <= 0;
                    spk_in_fifo_push <= 0;
                end else if(bram_step == WAIT) begin
                    if(bram_done > 0) begin
                        case(param_step) 
                            READ_IDX: begin
                                tile_idx_fifo_din <= tile_idx_slices[tile_idx_base];
                                tile_idx_y <= tile_idx_slices[tile_idx_base][2*TILE_IDX_WIDTH-1 : TILE_IDX_WIDTH];
                                tile_idx_x <= tile_idx_slices[tile_idx_base][TILE_IDX_WIDTH:0];
                                //tile_idx_fifo_push <= 1;
                            end
                            READ_WEIGHTS: begin
                                weight_fifo_din <= dout;
                                weight_fifo_push <= 1;
                            end
                            READ_SPK: begin
                                if(|spk_in_slices[spk_in_idx_base]) begin
                                    spk_in_fifo_din <= spk_in_slices[spk_in_idx_base];
                                    //spk_in_fifo_push <= 1;
                                end else begin  // skip if there are no spikes
                                    bram_step <= SEND;
                                    tile_idx <= tile_idx+1;
                                    param_step <= READ_IDX;
                                    weight_idx <= 0;
                                end
                            end 
                        endcase
                        bram_step <= INCREMENT;
                        bram_en <= 0;
                    end else begin
                        bram_done <= bram_done + bram_active; // wait 1 clock cycle for bram to finish if it is active
                    end
                end else if(bram_step == INCREMENT) begin
                    case(param_step)
                        READ_IDX: param_step <= READ_SPK;
                        READ_WEIGHTS: begin
                            if(weight_idx + BRAM_DATA_WIDTH / NETWORK_WIDTH < CROSSBAR_NEURONS*CROSSBAR_NEURONS) begin
                                weight_idx <= weight_idx + BRAM_DATA_WIDTH / NETWORK_WIDTH;
                                param_step <= READ_WEIGHTS;
                            end
                            else begin
                                tile_idx <= tile_idx + 1;
                                //param_step <= READ_SPK;
                                param_step <= READ_IDX;
                                weight_idx <= 0;

                                tile_idx_fifo_push <= 1;
                                spk_in_fifo_push <= 1;
                            end
                        end
                        READ_SPK: begin
                            //tile_idx <= tile_idx + 1;
                            //param_step <= READ_IDX;
                            param_step <= READ_WEIGHTS;
                        end
                    endcase
                    bram_step <= SEND;
                end
            end
        end
    end

endmodule