`timescale 1ns / 10ps;
`include "bram/xbar_bram.sv"
`include "bram/dual_port_bram.sv"
`include "fifo/weight_fifo.sv"
`include "fifo/spk_in_fifo.sv"
`include "fifo/tile_idx_fifo.sv"

module xbar_bram_fifo_tb;
    localparam BRAM_DATA_WIDTH = 1024;
    localparam BRAM_ADDR_WIDTH = 16;
    localparam NETWORK_WIDTH = 8;
    localparam MAX_TILES = 64;
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
    wire spk_in_fifo_push;
    wire tile_idx_fifo_push;

    reg weight_fifo_pop;
    reg spk_in_fifo_pop;
    reg tile_idx_fifo_pop;

    wire [BRAM_DATA_WIDTH-1:0] weight_fifo_din;
    wire [CROSSBAR_NEURONS-1:0] spk_in_fifo_din;
    wire [2*TILE_IDX_WIDTH-1:0] tile_idx_fifo_din;
    
    wire [BRAM_ADDR_WIDTH-1:0]  addr;
    wire [BRAM_DATA_WIDTH-1:0] dout;
    wire [BRAM_DATA_WIDTH-1:0] din;
    wire bram_en;
    wire bram_rst;
    wire [BRAM_DATA_WIDTH/8-1:0] bram_we;

    wire [NETWORK_WIDTH-1:0] weight [CROSSBAR_NEURONS][CROSSBAR_NEURONS];
    wire [CROSSBAR_NEURONS-1:0] spk_in;
    wire [TILE_IDX_WIDTH-1:0] tile_idx_x;
    wire [TILE_IDX_WIDTH-1:0] tile_idx_y;

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

    weight_fifo #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(2)
    ) fifo_weight (
        .clk(clk),
        .en(enable),
        .din(weight_fifo_din),
        .push(weight_fifo_push),
        .pop(weight_fifo_pop),
        .weight(weight),
        .full(weight_fifo_full),
        .empty(weight_fifo_empty),
        .push_done(weight_fifo_push_done),
        .pop_done(weight_fifo_pop_done)
    );

    spk_in_fifo #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(2)
    ) fifo_spk_in (
        .clk(clk),
        .en(enable),
        .din(spk_in_fifo_din),
        .push(spk_in_fifo_push),
        .pop(spk_in_fifo_pop),
        .spk_in(spk_in),
        .full(spk_in_fifo_full),
        .empty(spk_in_fifo_empty),
        .push_done(spk_in_fifo_push_done),
        .pop_done(spk_in_fifo_pop_done)
    );

    tile_idx_fifo #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .TILE_IDX_WIDTH(TILE_IDX_WIDTH),
        .LENGTH(2)
    ) fifo_tile_idx (
        .clk(clk),
        .en(enable),
        .din(tile_idx_fifo_din),
        .push(tile_idx_fifo_push),
        .pop(tile_idx_fifo_pop),
        .tile_idx_x(tile_idx_x),
        .tile_idx_y(tile_idx_y),
        .full(tile_idx_fifo_full),
        .empty(tile_idx_fifo_empty),
        .push_done(tile_idx_fifo_push_done),
        .pop_done(tile_idx_fifo_pop_done)
    );

    initial begin
        forever #5 clk = ~clk;
    end

    initial begin
        #0 clk = 0;
        #0 enable = 0;
        #0 weight_fifo_pop = 0;
        #0 spk_in_fifo_pop = 0;
        #0 tile_idx_fifo_pop = 0;

        #10 enable = 1;

        //#500 weight_fifo_pop = 1;
        //#500 spk_in_fifo_pop = 1;

        $dumpvars(100, xbar_bram_fifo_tb);
        $dumpfile("xbar_bram_tb.vcd");

        #10000 $finish;
    end

    initial begin
        #500 weight_fifo_pop = 1;
        #0 spk_in_fifo_pop = 1;
        #1000 tile_idx_fifo_pop = 1;
    end
endmodule
