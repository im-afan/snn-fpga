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

    output wire [2047:0] weight,
    output wire [127:0] network_input,
    output wire [127:0] mem_in,
    output wire [15:0] spk_in,
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
    reg [15:0] idx0;
    reg [15:0] idx1;
    reg [15:0] idx2;
    reg [15:0] x0;
    reg [15:0] y0;
    reg [15:0] x1;
    reg [15:0] y1;
    reg [15:0] y2;

    assign done = (idx0 == 512);

    assign weight = weight_dout;

    assign weight_addr = 16*16*idx2;
    assign network_input_addr = 16*y0; 
    assign mem_in_addr = 16*y0; 
    assign spk_in_addr = 2*x0 + 2*256*buff_idx; 
    assign tile_idx_addr = 4*idx0;

    always @(posedge clk) begin
        if(~enable) begin
            idx0 <= 0;
            idx1 <= 0;
			idx2 <= 0;
			x1 <= -1;
			y1 <= -1;
            y2 <= -1;
            push_rst <= 0;
        end else if(~done) begin
            weight_en <= 1;
            network_input_en <= 1;
            spk_in_en <= 1;
            mem_in_en <= 1;
            tile_idx_en <= 1;

            y0 <= tile_idx_dout[31:16];
            x0 <= tile_idx_dout[15:0];

            idx0 <= idx0+1;
            idx1 <= idx0;
            idx2 <= idx1;

			if(idx2 != idx1 && idx1 != idx0) begin
                x1 <= x0;
                y1 <= y0;
                y2 <= y1;
                push <= 1;
                push_rst <= (y1 != y0);
            end else begin
                y1 <= -1;
                push <= 0;
                push_rst <= 0;
            end
        end else begin
            push <= 0;
        end
    end 

	fifo #(.WIDTH(128), .LENGTH(16))
	fifo_network_input (
		.clk(clk),
		.rst(~enable),
		.din(network_input_dout),
		.push(push_rst),
		.pop(fifo_pop),
		.empty(),
		.full(),
		.dout(network_input)
	);

	fifo #(.WIDTH(128), .LENGTH(16))
	fifo_mem_in (
		.clk(clk),
		.rst(~enable),
		.din(mem_in_dout),
		.push(push_rst),
		.pop(fifo_pop),
		.empty(),
		.full(),
		.dout(mem_in)
	);

	fifo #(.WIDTH(16), .LENGTH(16))
	fifo_tile_idx (
		.clk(clk),
		.rst(~enable),
		.din(y2),
		.push(push_rst),
		.pop(fifo_pop),
		.empty(),
		.full(),
		.dout(tile_idx_y)
	);
endmodule
