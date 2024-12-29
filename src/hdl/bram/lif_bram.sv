/* PASSED TESTS */

/*
 * Synchronous BRAM
 * Reads and writes neccessary values for LIF
 * writes: mem_out, spk_out, reads: mem_in, spk_in 
 * tile_idx_x, tile_idx_y are FIFO inputs
*/

module lif_bram #(
    parameter integer BRAM_ADDR_WIDTH,
    parameter integer NETWORK_WIDTH,
    parameter integer MAX_TILES,
    parameter integer TILE_IDX_WIDTH,
    parameter integer MAX_NEURONS,
    parameter integer CROSSBAR_NEURONS
) (
    clk, enable, buff_idx, we,
    tile_idx_x, tile_idx_y,
    mem_out, spk_out,
    mem_in, spk_in,
    done,
    mem_addr, mem_dout, mem_din, mem_bram_en, mem_bram_rst, mem_bram_we,
    spk_out_addr, spk_out_dout, spk_out_din, spk_out_bram_en, spk_out_bram_rst, spk_out_bram_we,
    has_spk_nxt,
    is_last_tile
);
    localparam integer MEM_BRAM_DATA_WIDTH = CROSSBAR_NEURONS * NETWORK_WIDTH;
    localparam integer SPK_IN_BRAM_DATA_WIDTH = CROSSBAR_NEURONS;

    input wire clk; 
    input wire enable;

    input wire buff_idx;

    input wire we;

    input wire [TILE_IDX_WIDTH-1:0] tile_idx_x;
    input wire [TILE_IDX_WIDTH-1:0] tile_idx_y;

    input wire [NETWORK_WIDTH-1:0] mem_out [CROSSBAR_NEURONS]; 
    input wire [CROSSBAR_NEURONS-1:0] spk_out;

    output reg [NETWORK_WIDTH-1:0] mem_in [CROSSBAR_NEURONS];
    output reg [CROSSBAR_NEURONS-1:0] spk_in; // to inhibit multiple spikes in one timestep

    output reg done;

    output reg [BRAM_ADDR_WIDTH-1:0] mem_addr;
    input wire [MEM_BRAM_DATA_WIDTH-1:0] mem_dout;
    output reg [MEM_BRAM_DATA_WIDTH-1:0] mem_din;
    output reg mem_bram_en;
    output reg mem_bram_rst;
    output wire [MEM_BRAM_DATA_WIDTH/8-1:0] mem_bram_we;

    output reg [BRAM_ADDR_WIDTH-1:0] spk_out_addr;
    input wire [SPK_IN_BRAM_DATA_WIDTH-1:0] spk_out_dout;
    output reg [SPK_IN_BRAM_DATA_WIDTH-1:0] spk_out_din;
    output reg spk_out_bram_en;
    output reg spk_out_bram_rst;
    output wire [SPK_IN_BRAM_DATA_WIDTH/8-1:0] spk_out_bram_we;

    output reg [MAX_NEURONS / CROSSBAR_NEURONS - 1 : 0] has_spk_nxt;

    input wire is_last_tile;

    //initial has_spk_nxt = 0;

    localparam integer SEND = 0;
    localparam integer WAIT = 1;
    localparam integer INCREMENT = 2;

    localparam integer SPK_OUT_OFFSET = 0;
    localparam integer MEM_OFFSET = 0;

    wire [11:0] buff_offset_read;
    assign buff_offset_read = (!buff_idx) * MAX_TILES * CROSSBAR_NEURONS / 8;
    wire [11:0] buff_offset_write;
    assign buff_offset_write = (!buff_idx) * MAX_TILES * CROSSBAR_NEURONS / 8;

    reg [3:0] mem_bram_step;
    reg [3:0] spk_out_bram_step;

    reg mem_done;
    reg spk_out_done;
    assign done = spk_out_done && mem_done;

    reg [2:0] mem_bram_done;
    reg [2:0] spk_out_bram_done;

    reg mem_we_local;
    reg spk_out_bram_we_local;

    wire [CROSSBAR_NEURONS*NETWORK_WIDTH-1:0] mem_out_flattened;
    reg [CROSSBAR_NEURONS*NETWORK_WIDTH-1:0] mem_in_flattened;

    generate
        genvar i;
        for(i = 0; i < CROSSBAR_NEURONS/8; i++) begin
            assign spk_out_bram_we[i] = spk_out_bram_we_local;
        end
        for(i = 0; i < NETWORK_WIDTH * CROSSBAR_NEURONS / 8; i++) begin
            assign mem_bram_we[i] = mem_we_local;
        end

        for(i = 0; i < CROSSBAR_NEURONS; i++) begin
            assign mem_out_flattened[(i+1)*NETWORK_WIDTH-1 : i*NETWORK_WIDTH] = mem_out[i];
            assign mem_in[i] = mem_in_flattened[(i+1)*NETWORK_WIDTH-1 : i*NETWORK_WIDTH]; 
        end
    endgenerate

    // todo fix spaghetti code LOL

    // membrane potential
    always_ff @(posedge clk) begin
        if(~enable) begin
            mem_bram_step <= SEND;
            mem_bram_en <= 0;
            mem_done <= 0;
        end else begin
            if(~mem_done) begin
                if(we) begin
                    if(mem_bram_step == SEND) begin
                        mem_addr <= MEM_OFFSET + tile_idx_y * NETWORK_WIDTH * CROSSBAR_NEURONS / 8;
                        mem_din <= mem_out_flattened;
                        mem_we_local <= 1;
                        mem_bram_step <= WAIT;
                        mem_bram_done <= 0;
                        mem_bram_en <= 1;
                    end else if(mem_bram_step == WAIT) begin
                        if(mem_bram_done > 0) begin
                            mem_bram_en <= 0;
                            mem_bram_step <= INCREMENT;
                        end
                        else mem_bram_done <= mem_bram_done + 1;
                    end else if(mem_bram_step == INCREMENT) begin
                        mem_done <= 1;
                        mem_bram_step <= SEND;
                    end

                end else begin
                    if(mem_bram_step == SEND) begin
                        mem_addr <= MEM_OFFSET + tile_idx_y * NETWORK_WIDTH * CROSSBAR_NEURONS / 8;
                        mem_bram_step <= WAIT;
                        mem_bram_done <= 0;
                        mem_we_local <= 0;
                        mem_bram_en <= 1;
                    end else if(mem_bram_step == WAIT) begin
                        if(mem_bram_done > 0) begin
                            mem_in_flattened <= mem_dout;
                            mem_bram_en <= 0;
                            mem_bram_step <= INCREMENT;
                        end else begin
                            mem_bram_done <= mem_bram_done + 1;
                        end
                    end else if(mem_bram_step == INCREMENT) begin
                        mem_done <= 1;
                        mem_bram_step <= SEND;
                    end
                end
            end else begin
                mem_bram_step <= SEND;
            end
        end
    end


 
    // spk out
    always_ff @(posedge clk) begin
        if(~enable) begin
            spk_out_bram_step <= SEND;
            spk_out_bram_en <= 0;
            spk_out_done <= 0;
            spk_out_bram_we_local <= 0;
        end else begin
            if(~spk_out_done) begin
                if(we) begin
                    if(spk_out_bram_step == SEND) begin
                        spk_out_addr <= SPK_OUT_OFFSET + tile_idx_y * CROSSBAR_NEURONS / 8 + buff_offset_write;
                        spk_out_din <= spk_out;
                        spk_out_bram_we_local <= 1;
                        spk_out_bram_step <= WAIT;
                        spk_out_bram_done <= 0;
                        spk_out_bram_en <= 1;
                        has_spk_nxt[tile_idx_y] <= (|spk_out);
                    end else if(spk_out_bram_step == WAIT) begin
                        if(spk_out_bram_done > 0) begin
                            spk_out_bram_en <= 0;
                            spk_out_bram_step <= INCREMENT;
                        end
                        else spk_out_bram_done <= spk_out_bram_done + 1;
                    end else if(spk_out_bram_step == INCREMENT) begin
                        spk_out_done <= 1;
                        spk_out_bram_step <= SEND;
                    end
                end 

                else begin
                    if(spk_out_bram_step == SEND) begin
                        spk_out_addr <= SPK_OUT_OFFSET + tile_idx_y * CROSSBAR_NEURONS / 8 + buff_offset_write;
                        spk_out_bram_done <= 0;
                        spk_out_bram_we_local <= 0;
                        spk_out_bram_step <= WAIT;
                        spk_out_bram_en <= 1;
                    end else if(spk_out_bram_step == WAIT) begin
                        if(spk_out_bram_done > 0) begin
                            spk_in <= spk_out_dout;
                            spk_out_bram_en <= 0;
                            spk_out_bram_step <= INCREMENT;
                        end else begin
                            spk_out_bram_done <= spk_out_bram_done + 1;
                        end
                    end else if(spk_out_bram_step == INCREMENT) begin
                        spk_out_done <= 1;
                        spk_out_bram_step <= SEND;
                    end
                end
            end else begin
                spk_out_bram_step <= SEND;
                //local_we <= we;
            end
        end
    end

endmodule