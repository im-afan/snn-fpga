`timescale 1ns / 10ps;
`include "xbar_bram.sv"
`include "dual_port_bram.sv"

module xbar_bram_tb;
    localparam BRAM_DATA_WIDTH = 1024;
    localparam BRAM_ADDR_WIDTH = 16;
    localparam NETWORK_WIDTH = 8;
    localparam MAX_TILES = 128;
    localparam TILE_IDX_WIDTH = 16;
    localparam MAX_NEURONS = 1024;
    localparam CROSSBAR_NEURONS = 16;

    reg clk;
    reg enable;
    reg weight_fifo_full;
    reg spk_in_fifo_full;
    reg tile_idx_fifo_full;

    reg weight_fifo_push_done;
    reg spk_in_fifo_push_done;
    reg tile_idx_fifo_push_done;

    wire weight_fifo_push;
    wire spk_in_push;
    wire tile_idx_push;

    wire [BRAM_DATA_WIDTH-1:0] weight_fifo_din;
    wire [CROSSBAR_NEURONS-1:0] spk_in_fifo_din;
    wire [2*TILE_IDX_WIDTH-1:0] tile_idx_fifo_din;
    
    wire [BRAM_ADDR_WIDTH-1:0]  addr;
    wire [BRAM_DATA_WIDTH-1:0] dout;
    wire [BRAM_DATA_WIDTH-1:0] din;
    wire bram_en;
    wire bram_rst;
    wire [BRAM_DATA_WIDTH/8-1:0] bram_we;

    dual_port_bram #(
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH) 
    ) ram (
        .clka(clk),
        .ena(bram_en),
        .wea(bram_we),
        .addra(addr),
        .dina(din),
        .douta(dout)
    );

    xbar_bram #(
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .MAX_TILES(MAX_TILES),
        .TILE_IDX_WIDTH(TILE_IDX_WIDTH),
        .MAX_NEURONS(MAX_NEURONS),
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS)
    ) xbar (
        .clk(clk),
        .enable(enable),
        .weight_fifo_full(weight_fifo_full),
        .spk_in_fifo_full(spk_in_fifo_full),
        .tile_idx_fifo_full(tile_idx_fifo_full),
        .weight_fifo_push_done(weight_fifo_push_done),
        .spk_in_fifo_push_done(spk_in_fifo_push_done),
        .tile_idx_fifo_push_done(tile_idx_fifo_push_done),
        .weight_fifo_push(weight_fifo_push),
        .spk_in_fifo_push(spk_in_fifo_push),
        .tile_idx_fifo_push(tile_idx_fifo_push),
        .weight_fifo_din(weight_fifo_din),
        .spk_in_fifo_din(spk_in_fifo_din),
        .tile_idx_fifo_din(tile_idx_fifo_din),
        .addr(addr),
        .dout(dout),
        .din(din),
        .bram_en(bram_en),
        .bram_rst(bram_rst),
        .bram_we(bram_we)
    );

    initial begin
        forever #5 clk = ~clk;
    end

    initial begin
        #0 clk = 0;
        #0 enable = 0;
        #0 weight_fifo_full = 0;
        #0 spk_in_fifo_full = 0;
        #0 tile_idx_fifo_full = 0;
        #0 weight_fifo_push_done = 1;
        #0 spk_in_fifo_push_done = 1;
        #0 tile_idx_fifo_push_done = 1;
        #10 enable = 1;

        $dumpvars(100, xbar_bram_tb);
        $dumpfile("xbar_bram_tb.vcd");

        #10000 $finish;
    end
endmodule