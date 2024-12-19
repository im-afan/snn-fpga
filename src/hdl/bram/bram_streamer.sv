`include "bram/dual_port_bram.sv"
`include "bram/spk_in_bram.sv"
`include "bram/tile_idx_bram.sv"
`include "bram/weight_bram.sv"
`include "bram/input_bram.sv"

module bram_streamer #(
    parameter MAX_BRAM_DATA_WIDTH = 1024,
    parameter integer NETWORK_WIDTH,
    parameter integer MAX_TILES,
    parameter integer TILE_IDX_WIDTH,
    parameter integer MAX_NEURONS,
    parameter integer CROSSBAR_NEURONS
) (
    input wire clk,
    input wire enable,

    input wire buff_idx,

    input wire weight_fifo_full,
    input wire weight_fifo_push_done,
    output reg weight_fifo_push,
    output reg [WEIGHT_BRAM_DATA_WIDTH-1:0] weight_fifo_din,

    input wire input_fifo_full,
    input wire input_fifo_push_done,
    output reg input_fifo_push,
    output reg [INPUT_BRAM_DATA_WIDTH-1:0] input_fifo_din,

    input wire spk_in_fifo_full,
    input wire spk_in_fifo_push_done,
    output reg spk_in_fifo_push,
    output reg [SPK_IN_BRAM_DATA_WIDTH-1:0] spk_in_fifo_din,

    input wire tile_idx_fifo_full,
    input wire tile_idx_fifo_push_done,
    output reg tile_idx_fifo_push,
    output reg [TILE_IDX_BRAM_DATA_WIDTH-1:0] tile_idx_fifo_din,
    output reg tile_use_input_fifo_din
);
    localparam BRAM_ADDR_WIDTH = 10;

    localparam WEIGHT_BRAM_DATA_WIDTH = MAX_BRAM_DATA_WIDTH;
    localparam INPUT_BRAM_DATA_WIDTH = CROSSBAR_NEURONS*NETWORK_WIDTH;
    localparam SPK_IN_BRAM_DATA_WIDTH = CROSSBAR_NEURONS;
    localparam MEM_BRAM_DATA_WIDTH = CROSSBAR_NEURONS*NETWORK_WIDTH;
    localparam TILE_IDX_BRAM_DATA_WIDTH = 2*TILE_IDX_WIDTH;

    wire [BRAM_ADDR_WIDTH-1:0]  addr_tile_idx;
    wire [TILE_IDX_BRAM_DATA_WIDTH-1:0] dout_tile_idx;
    wire [TILE_IDX_BRAM_DATA_WIDTH-1:0] din_tile_idx;
    wire bram_en_tile_idx;
    wire bram_rst_tile_idx;
    wire [TILE_IDX_BRAM_DATA_WIDTH/8-1:0] bram_we_tile_idx;

    wire [BRAM_ADDR_WIDTH-1:0]  addr_spk_in;
    wire [SPK_IN_BRAM_DATA_WIDTH-1:0] dout_spk_in;
    wire [SPK_IN_BRAM_DATA_WIDTH-1:0] din_spk_in;
    wire bram_en_spk_in;
    wire bram_rst_spk_in;
    wire [SPK_IN_BRAM_DATA_WIDTH/8-1:0] bram_we_spk_in;

    wire [BRAM_ADDR_WIDTH-1:0]  addr_weight;
    wire [WEIGHT_BRAM_DATA_WIDTH-1:0] dout_weight;
    wire [WEIGHT_BRAM_DATA_WIDTH-1:0] din_weight;
    wire bram_en_weight;
    wire bram_rst_weight;
    wire [WEIGHT_BRAM_DATA_WIDTH/8-1:0] bram_we_weight;

    wire [BRAM_ADDR_WIDTH-1:0]  addr_input;
    wire [INPUT_BRAM_DATA_WIDTH-1:0] dout_input;
    wire [INPUT_BRAM_DATA_WIDTH-1:0] din_input;
    wire bram_en_input;
    wire bram_rst_input;
    wire [INPUT_BRAM_DATA_WIDTH/8-1:0] bram_we_input;

    wire [TILE_IDX_WIDTH-1:0] tile_idx;
    wire [TILE_IDX_WIDTH-1:0] tile_idx_x;
    wire [TILE_IDX_WIDTH-1:0] tile_idx_y;

    wire next_ready;
    assign next_ready = weight_fifo_push_done && input_fifo_push_done
                    && spk_in_fifo_push_done && tile_idx_fifo_push_done;

    dual_port_bram #(
        .BRAM_DATA_WIDTH(TILE_IDX_BRAM_DATA_WIDTH),
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .MEM_PATH("bram/mem/tile_idx_bram.mem")
    ) bram0 (
        .clka(clk),
        .addra(addr_tile_idx),
        .dina(din_tile_idx),
        .douta(dout_tile_idx),
        .wea(bram_we_tile_idx),
        .ena(bram_en_tile_idx)
    );
    
    dual_port_bram #(
        .BRAM_DATA_WIDTH(SPK_IN_BRAM_DATA_WIDTH),
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .MEM_PATH("bram/mem/spk_in_bram.mem")
    ) bram1 (
        .clka(clk),
        .addra(addr_spk_in),
        .dina(din_spk_in),
        .douta(dout_spk_in),
        .wea(bram_we_spk_in),
        .ena(bram_en_spk_in)
    );

    dual_port_bram #(
        .BRAM_DATA_WIDTH(WEIGHT_BRAM_DATA_WIDTH),
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .MEM_PATH("bram/mem/weight_bram.mem")
    ) bram2 (
        .clka(clk),
        .addra(addr_weight),
        .dina(din_weight),
        .douta(dout_weight),
        .wea(bram_we_weight),
        .ena(bram_en_weight)
    );

    dual_port_bram #(
        .BRAM_DATA_WIDTH(INPUT_BRAM_DATA_WIDTH),
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .MEM_PATH("bram/mem/input_bram.mem")
    ) bram3 (
        .clka(clk),
        .addra(addr_input),
        .dina(din_input),
        .douta(dout_input),
        .wea(bram_we_input),
        .ena(bram_en_input)
    );

    tile_idx_bram #(
        .BRAM_DATA_WIDTH(TILE_IDX_BRAM_DATA_WIDTH),
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .MAX_TILES(MAX_TILES),
        .MAX_NEURONS(MAX_NEURONS),
        .TILE_IDX_WIDTH(TILE_IDX_WIDTH),
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS)
    ) tile_idx_bram_0 (
        .clk(clk),
        .enable(enable),
        .tile_idx_fifo_full(tile_idx_fifo_full),
        .tile_idx_fifo_push_done(next_ready),
        .tile_idx_fifo_push(tile_idx_fifo_push),
        .tile_use_input_fifo_din(tile_use_input_fifo_din),
        .tile_idx(tile_idx),
        .tile_idx_x(tile_idx_x),
        .tile_idx_y(tile_idx_y),
        .addr(addr_tile_idx),
        .dout(dout_tile_idx),
        .din(din_tile_idx),
        .bram_en(bram_en_tile_idx),
        .bram_rst(bram_rst_tile_idx),
        .bram_we(bram_we_tile_idx)
    );

    weight_bram #(
        .BRAM_DATA_WIDTH(WEIGHT_BRAM_DATA_WIDTH),
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .MAX_TILES(MAX_TILES),
        .MAX_NEURONS(MAX_NEURONS),
        .TILE_IDX_WIDTH(TILE_IDX_WIDTH),
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS)
    ) weight_bram_0 (
        .clk(clk),
        .enable(enable),
        .new_tile(tile_idx_fifo_push),
        .tile_idx(tile_idx),
        .tile_idx_x(tile_idx_x),
        .tile_idx_y(tile_idx_y),
        .weight_fifo_full(weight_fifo_full),
        .weight_fifo_push(weight_fifo_push),
        .weight_fifo_push_done(weight_fifo_push_done),
        .weight_fifo_din(weight_fifo_din),
        .addr(addr_weight),
        .dout(dout_weight),
        .din(din_weight),
        .bram_en(bram_en_weight),
        .bram_rst(bram_rst_weight),
        .bram_we(bram_we_weight)
    );

    spk_in_bram #(
        .BRAM_DATA_WIDTH(SPK_IN_BRAM_DATA_WIDTH),
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .MAX_TILES(MAX_TILES),
        .MAX_NEURONS(MAX_NEURONS),
        .TILE_IDX_WIDTH(TILE_IDX_WIDTH),
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS)
    ) spk_in_bram_0 (
        .clk(clk),
        .enable(enable),
        .buff_idx(buff_idx),
        .new_tile(tile_idx_fifo_push),
        .tile_idx(tile_idx),
        .tile_idx_x(tile_idx_x),
        .tile_idx_y(tile_idx_y),
        .spk_in_fifo_full(spk_in_fifo_full),
        .spk_in_fifo_push(spk_in_fifo_push),
        .spk_in_fifo_push_done(spk_in_fifo_push_done),
        .spk_in_fifo_din(spk_in_fifo_din),
        .addr(addr_spk_in),
        .dout(dout_spk_in),
        .din(din_spk_in),
        .bram_en(bram_en_spk_in),
        .bram_rst(bram_rst_spk_in),
        .bram_we(bram_we_spk_in)
    );

    input_bram #(
        .BRAM_DATA_WIDTH(INPUT_BRAM_DATA_WIDTH),
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .MAX_TILES(MAX_TILES),
        .MAX_NEURONS(MAX_NEURONS),
        .TILE_IDX_WIDTH(TILE_IDX_WIDTH),
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS)
    ) input_bram_0 (
        .clk(clk),
        .enable(enable),
        .new_tile(tile_idx_fifo_push),
        .tile_idx(tile_idx),
        .tile_idx_x(tile_idx_x),
        .tile_idx_y(tile_idx_y),
        .input_fifo_full(input_fifo_full),
        .input_fifo_push(input_fifo_push),
        .input_fifo_push_done(input_fifo_push_done),
        .input_fifo_din(input_fifo_din),
        .addr(addr_input),
        .dout(dout_input),
        .din(din_input),
        .bram_en(bram_en_input),
        .bram_rst(bram_rst_input),
        .bram_we(bram_we_input)
    );
endmodule