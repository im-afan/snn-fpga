`include "top.sv"
`include "en_done_controller.sv"

module top_microblaze(
    input wire clk,
    input wire [15:0] sw,
    output wire [15:0] led,

    input wire usb_uart_rxd,
    output wire usb_uart_txd,

    input wire JA1, // UART rx 
    output wire JA2 // UART tx 
);
    localparam BRAM_DATA_WIDTH = 2048;
    localparam BRAM_ADDR_WIDTH = 17;
    localparam NETWORK_WIDTH = 8;
    localparam MAX_TILES = 512;
    localparam TILE_IDX_WIDTH = 16;
    localparam MAX_NEURONS = 1024;
    localparam CROSSBAR_NEURONS = 16;
    localparam THRESH = 64;
    localparam FIFO_LENGTH = 1;

    localparam WEIGHT_BRAM_DATA_WIDTH = BRAM_DATA_WIDTH;
    localparam INPUT_BRAM_DATA_WIDTH = CROSSBAR_NEURONS*NETWORK_WIDTH;
    localparam SPK_IN_BRAM_DATA_WIDTH = CROSSBAR_NEURONS;
    localparam SPK_OUT_BRAM_DATA_WIDTH = CROSSBAR_NEURONS;
    localparam MEM_BRAM_DATA_WIDTH = CROSSBAR_NEURONS*NETWORK_WIDTH;
    localparam TILE_IDX_BRAM_DATA_WIDTH = 2*TILE_IDX_WIDTH;

    localparam CPU_BRAM_DATA_WIDTH = 32;
    localparam CPU_BRAM_DATA_WIDTH_WEIGHT = 32;

    wire [BRAM_ADDR_WIDTH-1:0] cpu_tile_idx_addr;
    wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_tile_idx_din;
    wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_tile_idx_dout;
    wire [CPU_BRAM_DATA_WIDTH/8-1:0] cpu_tile_idx_we;
    wire cpu_tile_idx_en;

    wire [BRAM_ADDR_WIDTH-1:0] cpu_weight_addr;
    wire [CPU_BRAM_DATA_WIDTH_WEIGHT-1:0] cpu_weight_din;
    wire [CPU_BRAM_DATA_WIDTH_WEIGHT-1:0] cpu_weight_dout;
    wire [CPU_BRAM_DATA_WIDTH_WEIGHT/8-1:0] cpu_weight_we;
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

    wire snn_en_tri_o;
    wire snn_done_tri_i;
    wire snn_ready_tri_i;
    wire snn_done;
    wire snn_en;

    wire [1:0] snn_in_tri_i;
    assign snn_in_tri_i[0] = snn_done_tri_i;
    assign snn_in_tri_i[1] = snn_ready_tri_i;

    en_done_controller en_done_controller_0 (
        .clk(clk),
        .snn_en_tri_o(snn_en_tri_o),
        .snn_done(snn_done_tri_i),
        .snn_en(snn_en),
        .snn_ready(snn_ready_tri_i)
    );

    top top_0 (
        .clk(clk),
        .snn_en(snn_en_tri_o),
        .snn_done(snn_done_tri_i),
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
    );

    microblaze_wrapper microblaze (
        .clk(clk),
        .rst(1),
        .uart_rxd(usb_uart_rxd),
        .uart_txd(usb_uart_txd),

        .BRAM_TILE_IDX_addr(cpu_tile_idx_addr),
        .BRAM_TILE_IDX_din(cpu_tile_idx_din),
        .BRAM_TILE_IDX_dout(cpu_tile_idx_dout),
        .BRAM_TILE_IDX_en(cpu_tile_idx_en),
        .BRAM_TILE_IDX_we(cpu_tile_idx_we),

        .BRAM_WEIGHT_addr(cpu_weight_addr),
        .BRAM_WEIGHT_din(cpu_weight_din),
        .BRAM_WEIGHT_dout(cpu_weight_dout),
        .BRAM_WEIGHT_en(cpu_weight_en),
        .BRAM_WEIGHT_we(cpu_weight_we),

        .BRAM_INPUT_addr(cpu_input_addr),
        .BRAM_INPUT_din(cpu_input_din),
        .BRAM_INPUT_dout(cpu_input_dout),
        .BRAM_INPUT_en(cpu_input_en),
        .BRAM_INPUT_we(cpu_input_we),

        .BRAM_SPK_addr(cpu_spk_out_addr),
        .BRAM_SPK_din(cpu_spk_out_din),
        .BRAM_SPK_dout(cpu_spk_out_dout),
        .BRAM_SPK_en(cpu_spk_out_en),
        .BRAM_SPK_we(cpu_spk_out_we),   

        .snn_en_tri_o(snn_en_tri_o),
        .snn_in_tri_i(snn_in_tri_i),

        .uart_pmod_rxd(JA1),
        .uart_pmod_txd(JA2)
    );
endmodule