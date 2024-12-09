
/**
 * bram driver for network core to read/write parameters, inputs, and outputs
 **/

module network_bram_wrapper #(
	parameter integer BRAM_ADDR_WIDTH = 10,
	parameter integer BRAM_DATA_WIDTH = 32,
    parameter integer NEURONS_PER_CORE = 4,
    parameter integer MAX_NEURONS = 16,
    parameter integer MAX_DELAY = 8,
    parameter integer WIDTH = 8,
    parameter integer BYTES_PER_WIDTH = 4,
    parameter integer MAX_TILES = 16
)(
    input wire clk, 
    input wire [4:0] mode, //  0=read params 1=write queued_spikes 2=read spikes 3=write spikes
    input wire enable,
    
    output reg [BRAM_ADDR_WIDTH-1:0]  addr,
    input wire [BRAM_DATA_WIDTH-1:0] data_out,
    output reg [BRAM_DATA_WIDTH-1:0] data_in,
    output reg bram_en,
    output reg bram_rst,
    output reg [BYTES_PER_WIDTH-1:0] bram_we,

    input wire snn_done,
    input wire [BRAM_DATA_WIDTH-1:0] core_idx,
    input wire [NEURONS_PER_CORE-1:0] spk_out,
    input wire signed [WIDTH-1:0] mem_in [NEURONS_PER_CORE],
    input wire [BRAM_DATA_WIDTH-1:0] lif_tile_idx,

    output reg signed [WIDTH-1:0] weight [NEURONS_PER_CORE][NEURONS_PER_CORE],
    output reg signed [WIDTH-1:0] network_input [NEURONS_PER_CORE],
    output reg [MAX_NEURONS-1:0] leak,
    output reg snn_en, // should do timestep?
    output reg snn_rst, // should reset membrane potentials? 
    output reg [BRAM_DATA_WIDTH-1:0] core_idx_x,
    output reg [BRAM_DATA_WIDTH-1:0] core_idx_y,
    output reg signed [WIDTH-1:0] mem_out [NEURONS_PER_CORE],
    output reg [NEURONS_PER_CORE-1:0] spk_in_core,

    output reg done
);
    localparam integer DATA_STEP = 0;
    localparam integer INCREMENT_STEP = 2;
    localparam integer WAIT_STEP = 1;

    localparam integer CORE_READ_PARAMS = 0;
    localparam integer CORE_WRITE_PARAMS = 1;
    localparam integer LIF_READ_INPUT = 2;
    localparam integer LIF_WRITE_SPIKES = 3;

    localparam integer TILE_WIDTH = BYTES_PER_WIDTH + NEURONS_PER_CORE*NEURONS_PER_CORE;

    localparam integer WEIGHT_OFFSET = 0; // word 1: core index, word 2...NEURONS_PER_TILE: weights
    localparam integer NETWORK_INPUT_OFFSET = TILE_WIDTH * MAX_TILES;
    localparam integer SPK_OUT_OFFSET = NETWORK_INPUT_OFFSET + MAX_NEURONS;
    localparam integer FLAGS_OFFSET = SPK_OUT_OFFSET + MAX_NEURONS;
    localparam integer MEM_OFFSET = FLAGS_OFFSET + MAX_NEURONS;

    localparam integer EN = 0; // within word at FLAGS_OFFSET 
    localparam integer DONE = 1;
    localparam integer RESET = 2;
    /*localparam integer ENABLE_OFFSET = 3*MAX_NEURONS*MAX_NEURONS + 2*MAX_NEURONS;
    localparam integer DONE_OFFSET = 3*MAX_NEURONS*MAX_NEURONS + 2*MAX_NEURONS + 1;
    localparam integer SPK_RESET_OFFSET = 3*MAX_NEURONS*MAX_NEURONS + 2*MAX_NEURONS + 2;*/

    /*localparam integer WEIGHT_OFFSET_END = DELAY_OFFSET;
    localparam integer DELAY_OFFSET_END = QUEUED_SPIKES_OFFSET;
    localparam integer QUEUED_SPIKES_OFFSET_END = NETWORK_INPUT_OFFSET;
    localparam integer NETWORK_INPUT_OFFSET_END = SPK_OUT_OFFSET;
    localparam integer SPK_OUT_OFFSET_END = SPK_OUT_OFFSET + MAX_NEURONS;*/

    localparam LOG_MAX_NEURONS = $clog2(MAX_NEURONS);
    localparam LOG_NEURONS_PER_CORE = $clog2(NEURONS_PER_CORE);

    //localparam integer BYTES_PER_WIDTH = BRAM_DATA_WIDTH / WIDTH;

    //(* ram_style = "block" *) reg [BRAM_DATA_WIDTH-1:0] bram [1 << BRAM_ADDR_WIDTH];

    reg [BRAM_ADDR_WIDTH-1:0] x = 0;
    reg [BRAM_ADDR_WIDTH-1:0] y = 0;
    reg [BRAM_ADDR_WIDTH-1:0] z = 0;
    reg [3:0] step;
    reg bram_done = 0;
    integer val;
    reg [2:0] cnt;
    reg prev_enable = 0;

    reg [WIDTH-1:0] local_din[BYTES_PER_WIDTH];
    wire [WIDTH-1:0] local_dout[BYTES_PER_WIDTH];
    reg local_we;
    generate
        genvar i;
        for(i = 0; i < BYTES_PER_WIDTH; i++) begin
            assign data_in[WIDTH*(i+1)-1:WIDTH*i] = local_din[i];
            assign local_dout[i] = data_out[WIDTH*(i+1)-1:WIDTH*i];
            assign bram_we[i] = local_we;
        end
    endgenerate


    assign leak = 0;

    initial begin
        step = DATA_STEP;
        done = 0;
        bram_en = 0;
        x = 0;
        y = 0;
        z = 0;
        bram_done = 0;
    end

    reg [BRAM_ADDR_WIDTH-1:0] local_addr;
    assign addr = local_addr;// << 2; // byte addressing - todo take advantage of high bit width

    //assign addr = local_addr << 2; // byte addressing

    always @(posedge clk) begin
        if(~enable) begin
            bram_en <= 0;
            done <= 0;
            x <= 0;
            y <= 0;
            z <= 0;
            step <= DATA_STEP;
            bram_done <= 0;
            //prev_enable <= 0;
        end else begin
            if(~done) begin


                if(step == DATA_STEP) begin
                    cnt <= 0;
                    if(mode == CORE_READ_PARAMS) begin
                        //addr <= ((z << LOG_MAX_NEURONS) << LOG_MAX_NEURONS) + ((x + (core_idx_x << LOG_NEURONS_PER_CORE)) << LOG_MAX_NEURONS) + (y + (core_idx_y << LOG_NEURONS_PER_CORE));
                        if(z == 0) local_addr <= WEIGHT_OFFSET + TILE_WIDTH*core_idx;
                        if(z == 1) local_addr <= MEM_OFFSET + core_idx_y*NEURONS_PER_CORE + y;
                        if(z == 2) local_addr <= SPK_OUT_OFFSET + core_idx_x*NEURONS_PER_CORE + y;
                        if(z == 3) local_addr <= WEIGHT_OFFSET + TILE_WIDTH*core_idx + ((x << LOG_NEURONS_PER_CORE) + y) + BYTES_PER_WIDTH;
                        local_we <= 0;
                    end else if(mode == LIF_READ_INPUT) begin
                        //$display("LIF_READ_INPUT");
                        if(z == 0) local_addr <= NETWORK_INPUT_OFFSET + lif_tile_idx*NEURONS_PER_CORE + y;
                        if(z == 1) local_addr <= MEM_OFFSET + lif_tile_idx*NEURONS_PER_CORE + y;
                        if(z == 2) local_addr <= FLAGS_OFFSET;
                        //if(z == 1) local_addr <= ENABLE_OFFSET;
                        //if(z == 2) local_addr <= SPK_RESET_OFFSET;
                        local_we <= 0;
                    end else if(mode == LIF_WRITE_SPIKES) begin
                        //data_in <= spk_out[y];
                        if(z == 0) begin
                            for(integer i = 0; i < BYTES_PER_WIDTH; i++) begin
                                local_din[i] <= spk_out[y+i];
                            end
                            local_we <= 1;
                            local_addr <= SPK_OUT_OFFSET + lif_tile_idx*NEURONS_PER_CORE + y;
                        end else if(z == 1) begin
                            for(integer i = 0; i < BYTES_PER_WIDTH; i++) begin
                                local_din[i] <= mem_in[y+i];
                            end
                            local_we <= 1;
                            local_addr <= MEM_OFFSET + lif_tile_idx * NEURONS_PER_CORE + y;
                        end
                        //bram_we <= 'b1111;
                    end else if(mode == CORE_WRITE_PARAMS) begin
                        for(integer i = 0; i < BYTES_PER_WIDTH; i++) begin
                            local_din[i] <= mem_in[y+i];
                        end
                        local_addr <= MEM_OFFSET + lif_tile_idx*NEURONS_PER_CORE + y;
                        local_we <= 1;
                    end
                    bram_en <= 1;
                    bram_done <= 0;
                    step <= WAIT_STEP;


                end else if(step == WAIT_STEP) begin
                    if(bram_done) begin
                        //$display("wait bram_done");
                        if(mode == CORE_READ_PARAMS) begin
                            //if(z == 1) $display("%d %d %d = %d", z, x, y, data_out[WIDTH-1:0]);
                            if(z == 0) begin
                                core_idx_x <= local_dout[1];
                                core_idx_y <= local_dout[0];
                            end else if(z == 3) begin
                                for(integer i = 0; i < BYTES_PER_WIDTH; i++) begin
                                    //weight[x][y + i] <= data_out[WIDTH*(i+1)-1:WIDTH*i] ;
                                    weight[x][y + i] <= local_dout[i];
                                end
                            end else if(z == 1) begin
                                for(integer i = 0; i < BYTES_PER_WIDTH; i++) begin
                                    mem_out[y + i] <= local_dout[i];
                                end
                            end else if(z == 2) begin
                                for(integer i = 0; i < BYTES_PER_WIDTH; i++) begin
                                    spk_in_core[y+i] <= local_dout[i];
                                end
                            end
                        end else if(mode == LIF_READ_INPUT) begin
                            if(z == 0) begin
                                for(integer i = 0; i < BYTES_PER_WIDTH; i++) begin
                                    //network_input[y + i] <= data_out[WIDTH*(i+1)-1:WIDTH*i] ;
                                    network_input[y+i] <= local_dout[i];
                                end
                            end else if(z == 1) begin
                                for(integer i = 0; i < BYTES_PER_WIDTH; i++) begin
                                    mem_out[y+i] <= local_dout[i];
                                end
                            end else if(z == 2) begin
                                snn_en <= data_out[0] & ~prev_enable;
                                //snn_en <= 1;
                                snn_rst <= data_out[2];
                                prev_enable <= data_out[0];
                                //snn_done <= data_out[1];
                            end
                            //if(z == 2) snn_rst <= data_out[0];
                        end
                        bram_en <= 0;
                        step <= INCREMENT_STEP;
                    end else begin
                        if(cnt+1 > 1) begin
                            bram_done <= 1; //scuffed
                        end else begin
                            cnt <= cnt+1;
                        end
                    end


                end else if(step == INCREMENT_STEP) begin
                    if(mode == CORE_READ_PARAMS) begin
                        if(z == 0) begin
                            z <= z+1;
                            x <= 0;
                            y <= 0;
                            step <= DATA_STEP;
                        end else if(z == 3) begin
                            if(y+BYTES_PER_WIDTH >= NEURONS_PER_CORE) begin
                                if(x+1 >= NEURONS_PER_CORE) begin
                                    done <= 1; 
                                    z <= z+1;
                                    x <= 0;
                                    y <= 0;
                                end else begin
                                    if(~spk_in_core[x+1]) begin // save time by not loading weights if no spike
                                        for(integer i = 0; i < NEURONS_PER_CORE; i++) begin
                                           weight[x+1][i] <= 0;
                                        end
                                        step <= INCREMENT_STEP;
                                    end else begin
                                        step <= DATA_STEP;
                                        y <= 0;
                                    end
                                    x <= x+1;
                                end
                            end else begin
                                y <= y+BYTES_PER_WIDTH;
                                step <= DATA_STEP;
                            end
                        end else if(z == 1 || z == 2) begin
                            if(y + BYTES_PER_WIDTH >= NEURONS_PER_CORE) begin
                                x <= 0;
                                y <= 0; 
                                z <= z+1;
                            end else begin
                                y <= y+BYTES_PER_WIDTH;
                            end
                            step <= DATA_STEP;
                        end
                    end else if(mode == LIF_READ_INPUT) begin
                        if(z == 0 || z == 1) begin
                            if(y+BYTES_PER_WIDTH >= NEURONS_PER_CORE) begin
                                y <= 0;
                                z <= z+1;
                            end else begin
                                y <= y+BYTES_PER_WIDTH;
                            end
                        end else begin
                            //$display("READ RST AND ENABLE");
                            if(z == 3) begin
                                done <= 1;
                            end
                            z <= z+1;
                        end
                        //y <= y+1;
                        step <= DATA_STEP;
                    end else if(mode == LIF_WRITE_SPIKES) begin
                        if(y+BYTES_PER_WIDTH >= NEURONS_PER_CORE) begin
                            if(z == 1) begin
                                done <= 1;
                            end else begin
                                z <= z+1;
                                y <= 0;
                                step <= DATA_STEP;
                            end
                        end else begin
                            y <= y+BYTES_PER_WIDTH;
                            step <= DATA_STEP;
                        end
                    end else if(mode == CORE_WRITE_PARAMS) begin
                        if(y+BYTES_PER_WIDTH >= NEURONS_PER_CORE) begin
                            done <= 1;
                        end
                        y <= y+BYTES_PER_WIDTH;
                        step <= DATA_STEP;
                    end
                end
            end
        end
    end
endmodule
