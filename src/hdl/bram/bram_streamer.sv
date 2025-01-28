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
    input wire [31:0] tile_idx_dout,

    output reg [2047:0] weight,
    output reg [127:0] network_input,
    output reg [127:0] mem_in,
    output reg [15:0] spk_in,
    output reg [15:0] tile_idx_y,
	
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
    output reg [16:0] tile_idx_addr
); 
    reg [16:0] idx;

    assign weight_en = enable;
    assign network_input_en = enable;
    assign mem_in_en = enable;
    assign spk_in_en = enable;
    assign tile_idx_en = enable;

    assign weight_addr = idx * 16*16;
    assign spk_in_addr = idx * 2;
    assign tile_idx_addr = idx * 4;
    assign mem_in_addr = y * 16;
    assign network_input_addr = y*16;

    reg [2047:0] weight1;
    reg [15:0] spk1;
    reg [15:0] y;
    reg [15:0] y1;
    reg [15:0] y2;

    assign y = tile_idx_dout[31:16];

    always @(posedge clk) begin
        if(~enable) begin
            push <= 0; 
            idx <= 0;
        end else begin
            if(idx >= 0) begin
                push <= 1;
                weight1 <= weight_dout;
                spk1 <= spk_in_dout;

                weight <= weight1;
                spk_in <= spk1;
                tile_idx_y <= y1;
                mem_in <= mem_in_dout;
                network_input <= network_input_dout;
                y1 <= y;

                push_rst <= y != y1;
                
            end
            idx <= idx + 1;
        end
    end
endmodule