`timescale 1ns / 10ps
`include "top.sv"

module top_standalone(
    input wire clk,
    input wire [15:0] sw,
    output wire [15:0] led
);
    localparam BRAM_DATA_WIDTH = 1024;
    localparam BRAM_ADDR_WIDTH = 16;
    localparam NETWORK_WIDTH = 8;
    localparam MAX_TILES = 64;
    localparam TILE_IDX_WIDTH = 16;
    localparam MAX_NEURONS = 1024;
    localparam CROSSBAR_NEURONS = 16;
    localparam THRESH = 32;
    localparam FIFO_LENGTH = 2;

    localparam WEIGHT_BRAM_DATA_WIDTH = BRAM_DATA_WIDTH;
    localparam INPUT_BRAM_DATA_WIDTH = CROSSBAR_NEURONS*NETWORK_WIDTH;
    localparam SPK_IN_BRAM_DATA_WIDTH = CROSSBAR_NEURONS;
    localparam SPK_OUT_BRAM_DATA_WIDTH = CROSSBAR_NEURONS;
    localparam MEM_BRAM_DATA_WIDTH = CROSSBAR_NEURONS*NETWORK_WIDTH;
    localparam TILE_IDX_BRAM_DATA_WIDTH = 2*TILE_IDX_WIDTH;

    localparam CPU_BRAM_DATA_WIDTH = 32;

    wire [BRAM_ADDR_WIDTH-1:0] cpu_tile_idx_addr;
    wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_tile_idx_din;
    wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_tile_idx_dout;
    wire [CPU_BRAM_DATA_WIDTH/8-1:0] cpu_tile_idx_we;
    wire cpu_tile_idx_en;

    wire [BRAM_ADDR_WIDTH-1:0] cpu_weight_addr;
    wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_weight_din;
    wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_weight_dout;
    wire [CPU_BRAM_DATA_WIDTH/8-1:0] cpu_weight_we;
    wire cpu_weight_en;

    wire [BRAM_ADDR_WIDTH-1:0] cpu_spk_out_addr;
    wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_spk_out_din;
    wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_spk_out_dout;
    wire [CPU_BRAM_DATA_WIDTH/8-1:0] cpu_spk_out_we;
    wire cpu_spk_out_en;

    wire [BRAM_ADDR_WIDTH-1:0] cpu_input_addr;
    wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_input_din;
    wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_input_dout;
    wire [CPU_BRAM_DATA_WIDTH/8-1:0] cpu_input_we;
    wire cpu_input_en;
   
    wire snn_en;
    assign snn_en = sw[0];

    top top_0 (
        .clk(clk),
        .snn_en(snn_en),
        .snn_done(),
        .led(led),

        .cpu_tile_idx_addr(0),
        .cpu_tile_idx_din(0),
        .cpu_tile_idx_dout(),
        .cpu_tile_idx_en(0),
        .cpu_tile_idx_we(0),

        .cpu_weight_addr(0),
        .cpu_weight_din(0),
        .cpu_weight_dout(),
        .cpu_weight_en(0),
        .cpu_weight_we(0),

        .cpu_input_addr(0),
        .cpu_input_din(0),
        .cpu_input_dout(),
        .cpu_input_en(0),
        .cpu_input_we(0),

        .cpu_spk_out_addr(0),
        .cpu_spk_out_din(0),
        .cpu_spk_out_dout(),
        .cpu_spk_out_en(0),
        .cpu_spk_out_we(0)
    );
endmodule