`timescale 1ns / 10ps
`include "bram/bram_streamer.sv"

`include "fifo/weight_fifo.sv"
`include "fifo/spk_in_fifo.sv"
`include "fifo/tile_idx_fifo.sv"
`include "fifo/mem_fifo.sv"

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
    wire weight_fifo_full;
    wire spk_in_fifo_full;
    wire tile_idx_fifo_full;
    wire input_fifo_full;

    wire weight_fifo_push_done;
    wire spk_in_fifo_push_done;
    wire tile_idx_fifo_push_done;
    wire input_fifo_push_done;

    wire weight_fifo_push;
    wire spk_in_fifo_push;
    wire tile_idx_fifo_push;
    wire input_fifo_push;

    reg weight_fifo_pop;
    reg spk_in_fifo_pop;
    reg tile_idx_fifo_pop;
    reg input_fifo_pop;

    wire [BRAM_DATA_WIDTH-1:0] weight_fifo_din;
    wire [CROSSBAR_NEURONS-1:0] spk_in_fifo_din;
    wire [2*TILE_IDX_WIDTH-1:0] tile_idx_fifo_din;
    wire [CROSSBAR_NEURONS*NETWORK_WIDTH-1:0] input_fifo_din;
    
    wire [BRAM_ADDR_WIDTH-1:0]  addr;
    wire [BRAM_DATA_WIDTH-1:0] dout;
    wire [BRAM_DATA_WIDTH-1:0] din;
    wire bram_en;
    wire bram_rst;
    wire [BRAM_DATA_WIDTH/8-1:0] bram_we;

    wire [NETWORK_WIDTH-1:0] mem[CROSSBAR_NEURONS];
    wire [NETWORK_WIDTH-1:0] weight [CROSSBAR_NEURONS][CROSSBAR_NEURONS];
    wire [CROSSBAR_NEURONS-1:0] spk_in;
    wire [TILE_IDX_WIDTH-1:0] tile_idx_x;
    wire [TILE_IDX_WIDTH-1:0] tile_idx_y;

    wire buff_idx;
    assign buff_idx = 0;

    bram_streamer #(
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .MAX_TILES(MAX_TILES),
        .TILE_IDX_WIDTH(TILE_IDX_WIDTH),
        .MAX_NEURONS(MAX_NEURONS),
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS)
    ) bram_streamer_0 (
        .clk(clk),
        .enable(enable),
        .buff_idx(buff_idx),
        .weight_fifo_full(weight_fifo_full),
        .weight_fifo_push_done(weight_fifo_push_done),
        .weight_fifo_push(weight_fifo_push),
        .weight_fifo_din(weight_fifo_din),
        .input_fifo_full(input_fifo_full),
        .input_fifo_push_done(input_fifo_push_done),
        .input_fifo_push(input_fifo_push),
        .input_fifo_din(input_fifo_din),
        .spk_in_fifo_full(spk_in_fifo_full),
        .spk_in_fifo_push_done(spk_in_fifo_push_done),
        .spk_in_fifo_push(spk_in_fifo_push),
        .spk_in_fifo_din(spk_in_fifo_din),
        .tile_idx_fifo_full(tile_idx_fifo_full),
        .tile_idx_fifo_push_done(tile_idx_fifo_push_done),
        .tile_idx_fifo_push(tile_idx_fifo_push),
        .tile_idx_fifo_din(tile_idx_fifo_din)
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

    mem_fifo #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(2)
    ) fifo_input (
        .clk(clk),
        .en(enable),
        .din(input_fifo_din),
        .push(input_fifo_push),
        .pop(input_fifo_pop),
        .mem(mem),
        .full(input_fifo_full),
        .empty(input_fifo_empty),
        .push_done(input_fifo_push_done),
        .pop_done(input_fifo_pop_done)
    );

    generate 
        genvar i, j;
        for(i = 0; i < CROSSBAR_NEURONS; i++) begin
            for(j = 0; j < CROSSBAR_NEURONS; j++) begin
                wire [NETWORK_WIDTH-1:0] weight_debug;
                assign weight_debug = weight[i][j];
            end
        end
    endgenerate

    initial begin
        forever #5 clk = ~clk;
    end

    initial begin
        #0 clk = 0;
        #0 enable = 0;
        #0 weight_fifo_pop = 0;
        #0 spk_in_fifo_pop = 0;
        #0 tile_idx_fifo_pop = 0;
        #0 input_fifo_pop = 0;

        #10 enable = 1;

        //#500 weight_fifo_pop = 1;
        //#500 spk_in_fifo_pop = 1;

        $dumpfile(".wave/top_dump.vcd");
        $dumpvars(100, xbar_bram_fifo_tb);

        #10000 $finish;
    end

    initial begin
        #500 weight_fifo_pop = 1;
        #0 spk_in_fifo_pop = 1;
        #1000 tile_idx_fifo_pop = 1;
    end
endmodule
