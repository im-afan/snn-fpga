`include "top.sv"

module top_microblaze(
    input wire clk,
    input wire [15:0] sw,
    output wire [15:0] led,

    input wire uart_rxd,
    output wire uart_txd
);
    localparam BRAM_DATA_WIDTH = 1024;
    localparam BRAM_ADDR_WIDTH = 16;
    localparam NETWORK_WIDTH = 8;
    localparam MAX_TILES = 256;
    localparam TILE_IDX_WIDTH = 16;
    localparam MAX_NEURONS = 1024;
    localparam CROSSBAR_NEURONS = 16;
    localparam THRESH = 32;
    localparam FIFO_LENGTH = 1;

    localparam WEIGHT_BRAM_DATA_WIDTH = BRAM_DATA_WIDTH;
    localparam INPUT_BRAM_DATA_WIDTH = CROSSBAR_NEURONS*NETWORK_WIDTH;
    localparam SPK_IN_BRAM_DATA_WIDTH = CROSSBAR_NEURONS;
    localparam SPK_OUT_BRAM_DATA_WIDTH = CROSSBAR_NEURONS;
    localparam MEM_BRAM_DATA_WIDTH = CROSSBAR_NEURONS*NETWORK_WIDTH;
    localparam TILE_IDX_BRAM_DATA_WIDTH = 2*TILE_IDX_WIDTH;

    wire [BRAM_ADDR_WIDTH-1:0] cpu_tile_idx_addr;
    wire [TILE_IDX_BRAM_DATA_WIDTH-1:0] cpu_tile_idx_din;
    wire [TILE_IDX_BRAM_DATA_WIDTH-1:0] cpu_tile_idx_dout;
    wire [TILE_IDX_BRAM_DATA_WIDTH/8-1:0] cpu_tile_idx_we;
    wire cpu_tile_idx_en;

    wire [BRAM_ADDR_WIDTH-1:0] cpu_weight_addr;
    wire [WEIGHT_BRAM_DATA_WIDTH-1:0] cpu_weight_din;
    wire [WEIGHT_BRAM_DATA_WIDTH-1:0] cpu_weight_dout;
    wire [WEIGHT_BRAM_DATA_WIDTH/8-1:0] cpu_weight_we;
    wire cpu_weight_en;

    wire [BRAM_ADDR_WIDTH-1:0] cpu_spk_out_addr;
    wire [SPK_OUT_BRAM_DATA_WIDTH-1:0] cpu_spk_out_din;
    wire [SPK_OUT_BRAM_DATA_WIDTH-1:0] cpu_spk_out_dout;
    wire [SPK_OUT_BRAM_DATA_WIDTH/8-1:0] cpu_spk_out_we;
    wire cpu_spk_out_en;

    wire [BRAM_ADDR_WIDTH-1:0] cpu_input_addr;
    wire [INPUT_BRAM_DATA_WIDTH-1:0] cpu_input_din;
    wire [INPUT_BRAM_DATA_WIDTH-1:0] cpu_input_dout;
    wire [INPUT_BRAM_DATA_WIDTH/8-1:0] cpu_input_we;
    wire cpu_input_en;

    top top_0 (
        .clk(clk),
        .sw(sw),
        .led(led),

        .cpu_tile_idx_addr(cpu_tile_idx_addr),
        .cpu_tile_idx_din(cpu_tile_idx_din),
        .cpu_tile_idx_dout(cpu_tile_idx_dout),
        .cpu_tile_idx_en(cpu_tile_idx_en),
        .cpu_tile_idx_we(cpu_tile_idx_we),

        .cpu_weight_addr(cpu_weight_addr),
        .cpu_weight_din(cpu_weight_din),
        .cpu_weight_dout(cpu_weight_dout),
        .cpu_weight_en(cpu_weight_en),
        .cpu_weight_we(cpu_weight_we),

        .cpu_input_addr(cpu_input_addr),
        .cpu_input_din(cpu_input_din),
        .cpu_input_dout(cpu_input_dout),
        .cpu_input_en(cpu_input_en),
        .cpu_input_we(cpu_input_we),

        .cpu_spk_out_addr(cpu_spk_out_addr),
        .cpu_spk_out_din(cpu_spk_out_din),
        .cpu_spk_out_dout(cpu_spk_out_dout),
        .cpu_spk_out_en(cpu_spk_out_en),
        .cpu_spk_out_we(cpu_spk_out_we)
    ) 
endmodule