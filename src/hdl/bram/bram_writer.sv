module bram_writer # (
    parameter integer MAX_OUT_TILES = 8
)(
    input wire clk,
    input wire en,
    input wire buff_idx,
    input wire [15:0] timestep,  
    input wire has_out,
    input wire [15:0] tile_idx_y,
    input wire [15:0] tile_idx_y_ext,

    output reg mem_out_en,
    output reg spk_out_en,
    output reg [16:0] mem_out_addr,
    output reg [16:0] spk_out_addr,
    output reg [16:0] timed_spk_out_addr,

    output reg pop
);
    
    assign mem_out_en = has_out;
    assign spk_out_en = has_out;
    assign mem_out_addr = tile_idx_y * 16;
    assign spk_out_addr = buff_idx ? tile_idx_y*2 : tile_idx_y * 2 + 2*256;
    assign timed_spk_out_addr = 2 * (MAX_OUT_TILES * timestep + tile_idx_y_ext);
    assign pop = has_out;

endmodule

