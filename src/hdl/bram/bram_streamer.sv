module bram_streamer (
    input wire clk,
    input wire enable,

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

    assign weight = weight_dout;
    assign network_input = network_input_dout;
    assign mem_in = mem_in_dout; 
    assign spk_in = spk_in_dout;
    //assign tile_idx_y = y1;
    //assign push_rst = (tile_idx_y != y0);

    assign x0 = tile_idx_dout[15:0];
    assign y0 = tile_idx_dout[31:16];

    always @(posedge clk) begin
        if(~enable) begin
            idx0 <= 0;
            idx1 <= 0;
        end else begin
            weight_en <= 1;
            network_input_en <= 1;
            spk_in_en <= 1;
            mem_in_en <= 1;
            tile_idx_en <= 1;

            weight_addr <= 16*16*idx2;
            network_input_addr <= 16*x0; 
            mem_in_addr <= 16*y0; 
            spk_in_addr <= 2*y0; 
            tile_idx_addr <= 4*idx0;

            x1 <= x0;
            y1 <= y0;
            y2 <= y1;
            tile_idx_y <= y1;
            push_rst <= (y2 != y1);
            idx0 <= idx0+1;
            idx1 <= idx0;
            idx2 <= idx1;
        end
    end 
endmodule

