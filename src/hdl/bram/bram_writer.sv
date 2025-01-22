module bram_streamer (
    input wire clk,
    input wire enable,

    //input wire [127:0] mem_out,
    //input wire [15:0] spk_out,
    input wire [15:0] tile_idx_y,

    output reg mem_out_en,
    output reg spk_out_en,
    output reg [16:0] mem_out_addr,
    //output reg [127:0] mem_out_din,
    output reg [16:0] spk_out_addr,
    //output reg [15:0] spk_out_din
);
    
    assign mem_out_en = enable;
    assign spk_out_en = enable;
    assign mem_out_addr = tile_idx_y * 16;
    assign spk_out_addr = tile_idx_y * 2;
    //assign mem_out_din = mem_out;
    //assign spk_out_din = spk_out;
endmodule

