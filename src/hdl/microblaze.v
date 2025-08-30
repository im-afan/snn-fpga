//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
//Date        : Sat Aug 30 00:19:17 2025
//Host        : DESKTOP-OVIC86T running 64-bit major release  (build 9200)
//Command     : generate_target microblaze_wrapper.bd
//Design      : microblaze_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module microblaze_wrapper
   (BRAM_INPUT_addr,
    BRAM_INPUT_clk,
    BRAM_INPUT_din,
    BRAM_INPUT_dout,
    BRAM_INPUT_en,
    BRAM_INPUT_rst,
    BRAM_INPUT_we,
    BRAM_SPK_addr,
    BRAM_SPK_clk,
    BRAM_SPK_din,
    BRAM_SPK_dout,
    BRAM_SPK_en,
    BRAM_SPK_rst,
    BRAM_SPK_we,
    BRAM_TILE_IDX_addr,
    BRAM_TILE_IDX_clk,
    BRAM_TILE_IDX_din,
    BRAM_TILE_IDX_dout,
    BRAM_TILE_IDX_en,
    BRAM_TILE_IDX_rst,
    BRAM_TILE_IDX_we,
    BRAM_WEIGHT_addr,
    BRAM_WEIGHT_clk,
    BRAM_WEIGHT_din,
    BRAM_WEIGHT_dout,
    BRAM_WEIGHT_en,
    BRAM_WEIGHT_rst,
    BRAM_WEIGHT_we,
    clk,
    rst,
    snn_en_tri_o,
    snn_in_tri_i,
    uart_pmod_rxd,
    uart_pmod_txd,
    uart_rxd,
    uart_txd);
  output [19:0]BRAM_INPUT_addr;
  output BRAM_INPUT_clk;
  output [31:0]BRAM_INPUT_din;
  input [31:0]BRAM_INPUT_dout;
  output BRAM_INPUT_en;
  output BRAM_INPUT_rst;
  output [3:0]BRAM_INPUT_we;
  output [19:0]BRAM_SPK_addr;
  output BRAM_SPK_clk;
  output [31:0]BRAM_SPK_din;
  input [31:0]BRAM_SPK_dout;
  output BRAM_SPK_en;
  output BRAM_SPK_rst;
  output [3:0]BRAM_SPK_we;
  output [19:0]BRAM_TILE_IDX_addr;
  output BRAM_TILE_IDX_clk;
  output [31:0]BRAM_TILE_IDX_din;
  input [31:0]BRAM_TILE_IDX_dout;
  output BRAM_TILE_IDX_en;
  output BRAM_TILE_IDX_rst;
  output [3:0]BRAM_TILE_IDX_we;
  output [19:0]BRAM_WEIGHT_addr;
  output BRAM_WEIGHT_clk;
  output [31:0]BRAM_WEIGHT_din;
  input [31:0]BRAM_WEIGHT_dout;
  output BRAM_WEIGHT_en;
  output BRAM_WEIGHT_rst;
  output [3:0]BRAM_WEIGHT_we;
  input clk;
  input rst;
  output [0:0]snn_en_tri_o;
  input [1:0]snn_in_tri_i;
  input uart_pmod_rxd;
  output uart_pmod_txd;
  input uart_rxd;
  output uart_txd;

  wire [19:0]BRAM_INPUT_addr;
  wire BRAM_INPUT_clk;
  wire [31:0]BRAM_INPUT_din;
  wire [31:0]BRAM_INPUT_dout;
  wire BRAM_INPUT_en;
  wire BRAM_INPUT_rst;
  wire [3:0]BRAM_INPUT_we;
  wire [19:0]BRAM_SPK_addr;
  wire BRAM_SPK_clk;
  wire [31:0]BRAM_SPK_din;
  wire [31:0]BRAM_SPK_dout;
  wire BRAM_SPK_en;
  wire BRAM_SPK_rst;
  wire [3:0]BRAM_SPK_we;
  wire [19:0]BRAM_TILE_IDX_addr;
  wire BRAM_TILE_IDX_clk;
  wire [31:0]BRAM_TILE_IDX_din;
  wire [31:0]BRAM_TILE_IDX_dout;
  wire BRAM_TILE_IDX_en;
  wire BRAM_TILE_IDX_rst;
  wire [3:0]BRAM_TILE_IDX_we;
  wire [19:0]BRAM_WEIGHT_addr;
  wire BRAM_WEIGHT_clk;
  wire [31:0]BRAM_WEIGHT_din;
  wire [31:0]BRAM_WEIGHT_dout;
  wire BRAM_WEIGHT_en;
  wire BRAM_WEIGHT_rst;
  wire [3:0]BRAM_WEIGHT_we;
  wire clk;
  wire rst;
  wire [0:0]snn_en_tri_o;
  wire [1:0]snn_in_tri_i;
  wire uart_pmod_rxd;
  wire uart_pmod_txd;
  wire uart_rxd;
  wire uart_txd;

  microblaze microblaze_i
       (.BRAM_INPUT_addr(BRAM_INPUT_addr),
        .BRAM_INPUT_clk(BRAM_INPUT_clk),
        .BRAM_INPUT_din(BRAM_INPUT_din),
        .BRAM_INPUT_dout(BRAM_INPUT_dout),
        .BRAM_INPUT_en(BRAM_INPUT_en),
        .BRAM_INPUT_rst(BRAM_INPUT_rst),
        .BRAM_INPUT_we(BRAM_INPUT_we),
        .BRAM_SPK_addr(BRAM_SPK_addr),
        .BRAM_SPK_clk(BRAM_SPK_clk),
        .BRAM_SPK_din(BRAM_SPK_din),
        .BRAM_SPK_dout(BRAM_SPK_dout),
        .BRAM_SPK_en(BRAM_SPK_en),
        .BRAM_SPK_rst(BRAM_SPK_rst),
        .BRAM_SPK_we(BRAM_SPK_we),
        .BRAM_TILE_IDX_addr(BRAM_TILE_IDX_addr),
        .BRAM_TILE_IDX_clk(BRAM_TILE_IDX_clk),
        .BRAM_TILE_IDX_din(BRAM_TILE_IDX_din),
        .BRAM_TILE_IDX_dout(BRAM_TILE_IDX_dout),
        .BRAM_TILE_IDX_en(BRAM_TILE_IDX_en),
        .BRAM_TILE_IDX_rst(BRAM_TILE_IDX_rst),
        .BRAM_TILE_IDX_we(BRAM_TILE_IDX_we),
        .BRAM_WEIGHT_addr(BRAM_WEIGHT_addr),
        .BRAM_WEIGHT_clk(BRAM_WEIGHT_clk),
        .BRAM_WEIGHT_din(BRAM_WEIGHT_din),
        .BRAM_WEIGHT_dout(BRAM_WEIGHT_dout),
        .BRAM_WEIGHT_en(BRAM_WEIGHT_en),
        .BRAM_WEIGHT_rst(BRAM_WEIGHT_rst),
        .BRAM_WEIGHT_we(BRAM_WEIGHT_we),
        .clk(clk),
        .rst(rst),
        .snn_en_tri_o(snn_en_tri_o),
        .snn_in_tri_i(snn_in_tri_i),
        .uart_pmod_rxd(uart_pmod_rxd),
        .uart_pmod_txd(uart_pmod_txd),
        .uart_rxd(uart_rxd),
        .uart_txd(uart_txd));
endmodule
