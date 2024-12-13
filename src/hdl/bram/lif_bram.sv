/* PASSED TESTS */

/*
 * Synchronous BRAM
 * Reads and writes neccessary values for LIF
 * writes: mem_out, spk_out, reads: mem_in, mem_out
 * tile_idx_x, tile_idx_y are FIFO inputs
*/

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
    input wire [TILE_IDX_WIDTH-1:0] tile_idx_y,

    input wire [NETWORK_WIDTH-1:0] mem_out [CROSSBAR_NEURONS], 
    input wire [CROSSBAR_NEURONS-1:0] spk_out,

    output reg [NETWORK_WIDTH-1:0] mem_in [CROSSBAR_NEURONS],
    output reg [CROSSBAR_NEURONS-1:0] spk_in, // to inhibit multiple spikes in one timestep

    output reg done,

    output reg [BRAM_ADDR_WIDTH-1:0] addr,
    input wire [BRAM_DATA_WIDTH-1:0] dout,
    output reg [BRAM_DATA_WIDTH-1:0] din,
    output reg bram_en,
    output reg bram_rst,
    output wire [BRAM_DATA_WIDTH/8-1:0] bram_we,
    input wire bram_active
);
    localparam integer SEND = 0;
    localparam integer WAIT = 1;
    localparam integer INCREMENT = 2;

    localparam integer MEM = 0;
    localparam integer SPK = 1;

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


    wire local_we;
    assign local_we = we;

    reg bram_done;
    reg [4:0] bram_step = SEND;
    reg [4:0] param_step = MEM;

    wire [11:0] mem_tile_idx_base;
    assign mem_tile_idx_base = tile_idx_x % (BRAM_DATA_WIDTH / CROSSBAR_NEURONS / NETWORK_WIDTH);
    wire [11:0] spk_tile_idx_base;
    assign spk_tile_idx_base = tile_idx_y % (BRAM_DATA_WIDTH / CROSSBAR_NEURONS); 

    reg [BRAM_DATA_WIDTH / NETWORK_WIDTH / CROSSBAR_NEURONS-1 : 0] we_tile;
    reg [BRAM_DATA_WIDTH / CROSSBAR_NEURONS-1 : 0] spk_we_tile;
    reg [NETWORK_WIDTH*CROSSBAR_NEURONS-1:0] din_tile;

    wire [NETWORK_WIDTH-1:0] mem_in_tiles [BRAM_DATA_WIDTH / NETWORK_WIDTH / CROSSBAR_NEURONS][CROSSBAR_NEURONS];
    wire [CROSSBAR_NEURONS] spk_tiles [BRAM_DATA_WIDTH / CROSSBAR_NEURONS];

    wire [BRAM_DATA_WIDTH/8-1:0] bram_we_mem;
    wire [BRAM_DATA_WIDTH/8-1:0] bram_we_spk;
    assign bram_we = we ? ((param_step == MEM) ? bram_we_mem : bram_we_spk) : 0;

    generate
        genvar i, j, k;
        for(i = 0; i < BRAM_DATA_WIDTH / NETWORK_WIDTH / CROSSBAR_NEURONS; i++) begin
            for(j = 0; j < CROSSBAR_NEURONS; j++) begin
                assign bram_we_mem[i*CROSSBAR_NEURONS + j] = we_tile[i];
            end
        end
        for(i = 0; i < BRAM_DATA_WIDTH / CROSSBAR_NEURONS; i++) begin
            for(j = 0; j < CROSSBAR_NEURONS/8; j++) begin
                assign bram_we_spk[i*CROSSBAR_NEURONS/8+j] = spk_we_tile[i];
            end
            //assign bram_we_spk[(i+1)*CROSSBAR_NEURONS/8-1 : i*CROSSBAR_NEURONS/8] = we_tile[i];
        end
        for(i = 0; i < CROSSBAR_NEURONS; i++) begin
            assign din_tile[NETWORK_WIDTH*(i+1)-1 : NETWORK_WIDTH*i] = mem_out[i];
        end
        for(i = 0; i < BRAM_DATA_WIDTH / NETWORK_WIDTH / CROSSBAR_NEURONS; i++) begin
            for(j = 0; j < CROSSBAR_NEURONS; j++) begin
                initial $display("%d %d = %d:%d", i, j, i*CROSSBAR_NEURONS*NETWORK_WIDTH+j*NETWORK_WIDTH+NETWORK_WIDTH-1 , i*CROSSBAR_NEURONS*NETWORK_WIDTH+j*NETWORK_WIDTH);
                assign mem_in_tiles[i][j] = dout[i*CROSSBAR_NEURONS*NETWORK_WIDTH+j*NETWORK_WIDTH+NETWORK_WIDTH-1 : i*CROSSBAR_NEURONS*NETWORK_WIDTH+j*NETWORK_WIDTH];
            end
        end
        for(i = 0; i < BRAM_DATA_WIDTH / CROSSBAR_NEURONS; i++) begin
            assign spk_tiles[i] = dout[(i+1)*CROSSBAR_NEURONS : i*CROSSBAR_NEURONS];
        end
    endgenerate

    always @(posedge clk) begin
        if(~enable) begin
            param_step <= MEM;
            bram_step <= SEND;
            bram_en <= 0;
            done <= 0;
        end else begin
            if(~done) begin
                if(local_we) begin
                    if(bram_step == SEND) begin
                        if(param_step == MEM) begin
                            addr <= MEM_OFFSET + tile_idx_x * NETWORK_WIDTH * CROSSBAR_NEURONS / 8;
                            din <= (din_tile << mem_tile_idx_base);
                            we_tile <= (1 << mem_tile_idx_base);
                        end else if(param_step == SPK) begin
                            addr <= SPK_OUT_OFFSET + tile_idx_y * CROSSBAR_NEURONS / 8;
                            din <= (spk_out << spk_tile_idx_base);
                            spk_we_tile <= (1 << spk_tile_idx_base); // TODO thsi is wrong lmao
                        end
                        bram_step <= WAIT;
                        bram_done <= 0;
                        bram_en <= 1;
                    end else if(bram_step == WAIT) begin
                        if(bram_done) begin
                            bram_en <= 0;
                            bram_step <= INCREMENT;
                        end
                        else bram_done <= 1;
                    end else if(bram_step == INCREMENT) begin
                        if(param_step == MEM) param_step <= SPK;
                        else if(param_step == SPK) done <= 1;
                        bram_step <= SEND;
                    end

                end else begin
                    if(bram_step == SEND) begin
                        if(param_step == MEM) addr <= MEM_OFFSET + tile_idx_x * NETWORK_WIDTH * CROSSBAR_NEURONS / 8;
                        else if(param_step == SPK) addr <= SPK_OUT_OFFSET + tile_idx_y * CROSSBAR_NEURONS / 8;
                        bram_step <= WAIT;
                        bram_done <= 0;
                        we_tile <= 0;
                        bram_en <= 1;
                    end else if(bram_step == WAIT) begin
                        if(bram_done) begin
                            if(param_step == MEM) begin
                                $display(mem_in_tiles[mem_tile_idx_base][0]);
                                for(integer i = 0; i < CROSSBAR_NEURONS; i++) mem_in[i] <= mem_in_tiles[mem_tile_idx_base][i];
                            end else if(param_step == SPK) begin
                                spk_in <= spk_tiles[spk_tile_idx_base];
                            end
                            bram_en <= 0;
                            bram_step <= INCREMENT;
                        end else begin
                            bram_done <= bram_active;
                        end
                    end else if(bram_step == INCREMENT) begin
                        if(param_step == MEM) param_step <= SPK;
                        else if(param_step == SPK) done <= 1;
                        bram_step <= SEND;
                    end
                end
            end else begin
                bram_step <= SEND;
                param_step <= MEM;
                //local_we <= we;
            end
        end
    end
endmodule