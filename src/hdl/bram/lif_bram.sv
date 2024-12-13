module lif_bram #(
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

    input wire we,
    input wire [TILE_IDX_WIDTH-1:0] tile_idx_x,
    input wire [NETWORK_WIDTH-1:0] mem_out [CROSSBAR_NEURONS], 
    output reg [NETWORK_WIDTH-1:0] mem_in [CROSSBAR_NEURONS],

    output reg [BRAM_ADDR_WIDTH-1:0] addr,
    input wire [BRAM_DATA_WIDTH-1:0] dout,
    output reg [BRAM_DATA_WIDTH-1:0] din,
    output reg bram_en,
    output reg bram_rst,
    output wire [BRAM_DATA_WIDTH/8-1:0] bram_we
);
    localparam integer SEND = 0;
    localparam integer WAIT = 1;

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
    reg [BRAM_DATA_WIDTH / NETWORK_WIDTH / CROSSBAR_NEURONS-1 : 0] we_tile;
    reg [NETWORK_WIDTH*CROSSBAR_NEURONS-1:0] din_tile;
    wire [NETWORK_WIDTH-1:0] mem_in_tiles [BRAM_DATA_WIDTH / NETWORK_WIDTH / CROSSBAR_NEURONS][CROSSBAR_NEURONS];

    wire [11:0] tile_idx_base;
    assign tile_idx_base = tile_idx_x % (BRAM_DATA_WIDTH / CROSSBAR_NEURONS);

    generate
        genvar i, j, k;
        for(i = 0; i < BRAM_DATA_WIDTH / NETWORK_WIDTH / CROSSBAR_NEURONS; i++) begin
            for(j = 0; j < CROSSBAR_NEURONS; j++) begin
                assign bram_we[i*CROSSBAR_NEURONS + j : i*CROSSBAR_NEURONS] = we_tile[i];
            end
        end
        for(i = 0; i < CROSSBAR_NEURONS; i++) begin
            assign din_tile[NETWORK_WIDTH*(i+1)-1 : NETWORK_WIDTH*i] = mem_out[i];
        end
        for(i = 0; i < BRAM_DATA_WIDTH / NETWORK_WIDTH / CROSSBAR_NEURONS; i++) begin
            for(j = 0; j < CROSSBAR_NEURONS; j++) begin
                assign mem_in_tiles[i][j] = dout[i*CROSSBAR_NEURONS*NETWORK_WIDTH+j*NETWORK_WIDTH+NETWORK_WIDTH-1 : i*CROSSBAR_NEURONS*NETWORK_WIDTH+j*NETWORK_WIDTH];
            end
        end
    endgenerate

    always @(posedge clk) begin
        if(~enable) begin
            bram_step <= SEND;
            bram_en <= 0;
        end else begin
            if(bram_step == SEND) begin
                addr <= MEM_OFFSET + tile_idx_x * NETWORK_WIDTH * CROSSBAR_NEURONS / 8;
                if(we) begin
                    din <= (din_tile << tile_idx_base);
                    we_tile <= (1 << tile_idx_base);
                end else begin
                    we_tile <= 0;
                end
                bram_done <= 0;
                bram_step <= WAIT;
                bram_en <= 1;
            end else if(bram_step == WAIT) begin
                if(bram_done) begin
                    for(integer i = 0; i < CROSSBAR_NEURONS; i++) begin
                        mem_in[i] <= mem_in_tiles[tile_idx_base][i];
                    end
                    bram_en <= 0;
                    bram_step <= SEND;
                end else begin
                    bram_done <= 1;
                end
            end 
        end
    end
endmodule