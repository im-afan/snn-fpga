`include "bram/fifo.sv"

module bram_streamer (
    input wire clk,

    input wire enable,
	input wire fifo_pop,
    input wire buff_idx,

    input wire [2047:0] weight_dout,
    input wire [127:0] network_input_dout,
    input wire [127:0] mem_in_dout,
    input wire [15:0] spk_in_dout,
    input wire [15:0] spk_in_ext_dout,
    input wire [63:0] tile_idx_dout,

    output reg [2047:0] weight,
    output reg [127:0] network_input,
    output reg [127:0] mem_in,
    output reg [15:0] spk_in,
    output reg [15:0] tile_idx_y,
    output reg [15:0] tile_idx_y_ext,
	
    output reg push_rst,
	output reg push,
    output reg done,

    output reg weight_en,
    output reg [16:0] weight_addr,
    output reg network_input_en,
    output reg [16:0] network_input_addr,
    output reg mem_in_en,
    output reg [16:0] mem_in_addr,
    output reg spk_in_en,
    output reg [16:0] spk_in_addr,
    output reg tile_idx_en,
    output reg [16:0] tile_idx_addr,
    output reg spk_in_ext_en,
    output reg [16:0] spk_in_ext_addr,


    output reg [15:0] timestep
);
    localparam integer MAX_TILES = 512;
    localparam integer MAX_TIMESTEPS = 128;

    initial timestep = 0;

    reg [16:0] idx;
    reg [16:0] idx1;

    assign weight_en = enable;
    assign network_input_en = enable;
    assign mem_in_en = enable;
    assign spk_in_en = enable;
    assign tile_idx_en = enable;

    assign weight_addr = idx1 * 16*16;
    assign spk_in_addr = (x < 1024) ? x * 2 + buff_idx*1024*2 : 1023;
    assign tile_idx_addr = idx * 8;
    assign mem_in_addr = (y < 1024) ? y * 16 : 1023;
    assign network_input_addr = (y < 512) ? y*16 : 1023;

    //reg [2047:0] weight1;
    //reg [15:0] spk1;
    reg [15:0] y;
    reg [15:0] x;
    reg [15:0] y_ext;
    reg [15:0] x_ext;
    reg [15:0] y1;
    reg [15:0] y_ext1;
    reg [15:0] y2;

    assign y_ext = tile_idx_dout[63:48];
    assign x_ext = tile_idx_dout[47:32];
    assign y = tile_idx_dout[31:16];
    assign x = tile_idx_dout[15:0];

    always @(posedge clk) begin
        if(~enable) begin
            push <= 0; 
            idx <= 0;
            idx1 <= 0;
            timestep <= 0;
            done <= 0;
        end else begin
            if(timestep < MAX_TIMESTEPS) begin
                if(idx <= MAX_TILES) begin 
                    if(idx >= 0) begin
                        weight <= weight_dout;
                        //spk_in <= spk_in_dout | spk_in_ext_dout;
                        spk_in <= spk_in_dout;
                        tile_idx_y <= y1;
                        tile_idx_y_ext <= y_ext1;
                        mem_in <= mem_in_dout;
                        network_input <= network_input_dout;
                        y1 <= y;
                        y2 <= y1;

                        y_ext1 <= y_ext;

                        push_rst <= y2 != y1;
                        push <= idx >= 2; 
                    end
                    idx <= idx + 1;
                    idx1 <= idx;
                    if(idx == 0) timestep <= timestep+1;
                end else begin
                    idx <= 0;
                end
            end else begin
                done <= 1; 
            end
        end
    end
endmodule