`timescale 1ns / 10ps
`include "bram/bram_streamer.sv"
`include "bram/buff_idx_controller.sv"
`include "fifo/weight_fifo.sv"
`include "fifo/spk_in_fifo.sv"
`include "fifo/tile_idx_fifo.sv"
`include "fifo/mem_fifo.sv"
`include "scheduler/lif_scheduler.sv"
`include "scheduler/xbar_scheduler.sv"
`include "snn/synapse_array.sv"
`include "snn/lif_array.sv"
`include "led_controller.sv"

module top(
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
    localparam FIFO_LENGTH = 1;


    reg enable;
    assign enable = sw[0];

    wire weight_fifo_full;
    wire spk_in_fifo_full;
    wire tile_idx_fifo_full;
    wire input_fifo_full;
    wire mac_out_fifo_full;

    wire weight_fifo_push_done;
    wire spk_in_fifo_push_done;
    wire tile_idx_fifo_push_done;
    wire input_fifo_push_done;
    wire mac_out_fifo_push_done;

    wire weight_fifo_push;
    wire spk_in_fifo_push;
    wire tile_idx_fifo_push;
    wire input_fifo_push;
    wire mac_out_fifo_push;

    wire weight_fifo_pop;
    wire spk_in_fifo_pop;
    wire tile_idx_fifo_pop;
    wire input_fifo_pop;
    wire mac_out_fifo_pop;


    wire [BRAM_DATA_WIDTH-1:0] weight_fifo_din;
    wire [CROSSBAR_NEURONS-1:0] spk_in_fifo_din;
    wire [2*TILE_IDX_WIDTH-1:0] tile_idx_fifo_din;
    wire tile_use_input_fifo_din;
    wire [CROSSBAR_NEURONS*NETWORK_WIDTH-1:0] input_fifo_din;
    wire [CROSSBAR_NEURONS*NETWORK_WIDTH-1:0] mac_out_fifo_din;
    
    /*wire [BRAM_ADDR_WIDTH-1:0]  addr;
    wire [BRAM_DATA_WIDTH-1:0] dout;
    wire [BRAM_DATA_WIDTH-1:0] din;
    wire bram_en;
    wire bram_rst;
    wire [BRAM_DATA_WIDTH/8-1:0] bram_we;*/

    wire [NETWORK_WIDTH-1:0] network_input[CROSSBAR_NEURONS];
    wire [NETWORK_WIDTH-1:0] mac_out[CROSSBAR_NEURONS];
    wire [NETWORK_WIDTH-1:0] weight [CROSSBAR_NEURONS][CROSSBAR_NEURONS];
    wire [CROSSBAR_NEURONS-1:0] spk_in;
    wire [TILE_IDX_WIDTH-1:0] tile_idx_x;
    wire [TILE_IDX_WIDTH-1:0] tile_idx_y;

    wire buff_idx;

    wire synapse_array_done;

    wire [NETWORK_WIDTH-1:0] lif_mem_out [CROSSBAR_NEURONS];
    wire [CROSSBAR_NEURONS-1:0] lif_spk_out;
    wire [NETWORK_WIDTH-1:0] lif_mem_in [CROSSBAR_NEURONS];
    wire [CROSSBAR_NEURONS-1:0] lif_spk_in;
    wire lif_use_input;
    wire lif_bram_done;
    wire lif_bram_enable;
    wire lif_bram_we;

    //assign led = lif_spk_out;
    led_controller led_controller_0 (
        .clk(clk),
        .en(enable),
        .spk_out(lif_spk_out),
        .led(led)
    );

    buff_idx_controller buff_idx_controller_0 (
        .clk(clk),
        .en(enable),
        .buff_idx(buff_idx)
    );

    bram_streamer #(
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
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
        .tile_idx_fifo_din(tile_idx_fifo_din),
        .tile_use_input_fifo_din(tile_use_input_fifo_din),
        .lif_mem_out(lif_mem_out),
        .lif_spk_out(lif_spk_out),
        .lif_mem_in(lif_mem_in),
        .lif_spk_in(lif_spk_in),
        .lif_bram_done(lif_bram_done),
        .lif_bram_enable(lif_bram_enable),
        .lif_bram_we(lif_bram_we),
        .lif_tile_idx_x(tile_idx_x),
        .lif_tile_idx_y(tile_idx_y)
    );

    weight_fifo #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(FIFO_LENGTH)
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
        .LENGTH(FIFO_LENGTH)
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
        .LENGTH(FIFO_LENGTH)
    ) fifo_tile_idx (
        .clk(clk),
        .en(enable),
        .din(tile_idx_fifo_din),
        .use_input_din(tile_use_input_fifo_din),
        .push(tile_idx_fifo_push),
        .pop(tile_idx_fifo_pop),
        .tile_idx_x(tile_idx_x),
        .tile_idx_y(tile_idx_y),
        .use_input(lif_use_input),
        .full(tile_idx_fifo_full),
        .empty(tile_idx_fifo_empty),
        .push_done(tile_idx_fifo_push_done),
        .pop_done(tile_idx_fifo_pop_done)
    );

    mem_fifo #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(FIFO_LENGTH)
    ) fifo_input (
        .clk(clk),
        .en(enable),
        .din(input_fifo_din),
        .push(input_fifo_push),
        .pop(input_fifo_pop),
        .mem(network_input),
        .full(input_fifo_full),
        .empty(input_fifo_empty),
        .push_done(input_fifo_push_done),
        .pop_done(input_fifo_pop_done)
    );

    mem_fifo #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(FIFO_LENGTH)       
    ) fifo_mac_out (
        .clk(clk),
        .en(enable),
        .din(mac_out_fifo_din),
        .push(mac_out_fifo_push),
        .pop(mac_out_fifo_pop),
        .mem(mac_out),
        .full(mac_out_fifo_full),
        .empty(mac_out_fifo_empty),
        .pop_done(mac_out_fifo_pop_done),
        .push_done(mac_out_fifo_push_done) 
    );

    lif_scheduler lif_scheduler_0 (
        .clk(clk),
        .en(enable),
        .lif_done(lif_array_done),
        .mac_out_fifo_empty(mac_out_fifo_empty),
        .mac_out_fifo_pop(mac_out_fifo_pop),
        .mac_out_fifo_pop_done(mac_out_fifo_pop_done),
        .tile_idx_fifo_empty(tile_idx_fifo_empty),
        .tile_idx_fifo_pop(tile_idx_fifo_pop),
        .tile_idx_fifo_pop_done(tile_idx_fifo_pop_done),
        .lif_en(lif_array_en)
    );

    xbar_scheduler xbar_scheduler_0 (
        .clk(clk),
        .en(enable),
        .crossbar_done(synapse_array_done),

        .weight_fifo_empty(weight_fifo_empty),
        .weight_fifo_pop(weight_fifo_pop),
        .weight_fifo_pop_done(weight_fifo_pop_done),

        .spk_in_fifo_empty(spk_in_fifo_empty),
        .spk_in_fifo_pop(spk_in_fifo_pop),
        .spk_in_fifo_pop_done(spk_in_fifo_pop_done),

        .input_fifo_empty(input_fifo_empty),
        .input_fifo_pop(input_fifo_pop),
        .input_fifo_pop_done(input_fifo_pop_done),

        .mac_out_fifo_full(mac_out_fifo_full),
        .mac_out_fifo_push(mac_out_fifo_push),
        .mac_out_fifo_push_done(mac_out_fifo_push_done),

        .crossbar_en(synapse_array_en)
    );    

    synapse_array #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .NETWORK_WIDTH(NETWORK_WIDTH)
    ) synapse_array_0 (
        .clk(clk),
        .enable(synapse_array_en),
        .u_mac_in(network_input),
        .u_weight(weight),
        .spk_in(spk_in),
        .u_mac_out(mac_out_fifo_din),
        .done(synapse_array_done)
    );

    lif_array #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .THRESH(THRESH),
        .NETWORK_WIDTH(NETWORK_WIDTH)
    ) lif_array_0 (
        .clk(clk),
        .enable(lif_array_en),
        .bram_done(lif_bram_done),
        .spk_rst(lif_use_input),
        .spk_in(lif_spk_in),
        .u_mac_out(mac_out),
        .u_mem_in(lif_mem_in),
        .spk_out(lif_spk_out),
        .u_mem_out(lif_mem_out),
        .done(lif_array_done),
        .bram_we(lif_bram_we),
        .bram_enable(lif_bram_enable)
    );

endmodule