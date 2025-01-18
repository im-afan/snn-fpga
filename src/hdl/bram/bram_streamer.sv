`include "bram/dual_port_bram.sv"
`include "bram/spk_in_bram.sv"
`include "bram/tile_idx_bram.sv"
`include "bram/weight_bram.sv"
`include "bram/input_bram.sv"
`include "bram/lif_bram.sv"
`include "bram/asymmetric_dual_port_bram.sv"

module bram_streamer #(
    parameter MAX_BRAM_DATA_WIDTH = 1024,
    parameter integer BRAM_ADDR_WIDTH,
    parameter integer NETWORK_WIDTH,
    parameter integer MAX_TILES,
    parameter integer TILE_IDX_WIDTH,
    parameter integer MAX_NEURONS,
    parameter integer CROSSBAR_NEURONS
) (
    clk,
    enable,
    is_last_tile,

    //buff_idx,

    weight_fifo_full,
    weight_fifo_push_done,
    weight_fifo_push,
    weight_fifo_din,

    input_fifo_full,
    input_fifo_push_done,
    input_fifo_push,
    input_fifo_din,

    spk_in_fifo_full,
    spk_in_fifo_push_done,
    spk_in_fifo_push,
    spk_in_fifo_din,

    tile_idx_fifo_full,
    tile_idx_fifo_push_done,
    tile_idx_fifo_push,
    tile_idx_fifo_din,
    tile_use_input_fifo_din,

    lif_mem_out, lif_spk_out,
    lif_mem_in, lif_spk_in,
    lif_bram_done, lif_bram_enable, lif_bram_we,
    lif_tile_idx_x, lif_tile_idx_y,

    cpu_tile_idx_addr, cpu_tile_idx_din, cpu_tile_idx_dout, cpu_tile_idx_en, cpu_tile_idx_we,
    cpu_weight_addr, cpu_weight_din, cpu_weight_dout, cpu_weight_en, cpu_weight_we,
    cpu_spk_out_addr, cpu_spk_out_din, cpu_spk_out_dout, cpu_spk_out_en, cpu_spk_out_we,
    cpu_input_addr, cpu_input_din, cpu_input_dout, cpu_input_en, cpu_input_we
);

    localparam WEIGHT_BRAM_DATA_WIDTH = MAX_BRAM_DATA_WIDTH;
    localparam INPUT_BRAM_DATA_WIDTH = CROSSBAR_NEURONS*NETWORK_WIDTH;
    localparam SPK_IN_BRAM_DATA_WIDTH = CROSSBAR_NEURONS;
    localparam SPK_OUT_BRAM_DATA_WIDTH = CROSSBAR_NEURONS;
    localparam MEM_BRAM_DATA_WIDTH = CROSSBAR_NEURONS*NETWORK_WIDTH;
    localparam TILE_IDX_BRAM_DATA_WIDTH = 2*TILE_IDX_WIDTH;

    input wire clk;
    input wire enable;
    output wire is_last_tile;

    //input wire buff_idx;

    input wire weight_fifo_full;
    input wire weight_fifo_push_done;
    output reg weight_fifo_push;
    output reg [WEIGHT_BRAM_DATA_WIDTH-1:0] weight_fifo_din;

    input wire input_fifo_full;
    input wire input_fifo_push_done;
    output reg input_fifo_push;
    output reg [INPUT_BRAM_DATA_WIDTH-1:0] input_fifo_din;

    input wire spk_in_fifo_full;
    input wire spk_in_fifo_push_done;
    output reg spk_in_fifo_push;
    output reg [SPK_IN_BRAM_DATA_WIDTH-1:0] spk_in_fifo_din;

    input wire tile_idx_fifo_full;
    input wire tile_idx_fifo_push_done;
    output reg tile_idx_fifo_push;
    output reg [TILE_IDX_BRAM_DATA_WIDTH-1:0] tile_idx_fifo_din;
    output reg tile_use_input_fifo_din;

    input wire [CROSSBAR_NEURONS-1:0] lif_spk_out;
    input wire [NETWORK_WIDTH-1:0] lif_mem_out [CROSSBAR_NEURONS];
    output wire [NETWORK_WIDTH-1:0] lif_mem_in [CROSSBAR_NEURONS];
    output wire [CROSSBAR_NEURONS-1:0] lif_spk_in;
    output wire lif_bram_done;
    output wire lif_bram_enable;
    output wire lif_bram_we;
    input wire [TILE_IDX_WIDTH-1:0] lif_tile_idx_x;
    input wire [TILE_IDX_WIDTH-1:0] lif_tile_idx_y;

    localparam integer CPU_BRAM_DATA_WIDTH = 32;
    localparam integer CPU_BRAM_DATA_WIDTH_WEIGHT = 128;

    input wire [BRAM_ADDR_WIDTH-1:0] cpu_tile_idx_addr;
    input wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_tile_idx_din;
    output wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_tile_idx_dout;
    input wire [CPU_BRAM_DATA_WIDTH/8-1:0] cpu_tile_idx_we;
    input wire cpu_tile_idx_en;

    input wire [BRAM_ADDR_WIDTH-1:0] cpu_weight_addr;
    input wire [CPU_BRAM_DATA_WIDTH_WEIGHT-1:0] cpu_weight_din;
    output wire [CPU_BRAM_DATA_WIDTH_WEIGHT-1:0] cpu_weight_dout;
    input wire [CPU_BRAM_DATA_WIDTH_WEIGHT/8-1:0] cpu_weight_we;
    input wire cpu_weight_en;

    input wire [BRAM_ADDR_WIDTH-1:0] cpu_spk_out_addr;
    input wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_spk_out_din;
    output wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_spk_out_dout;
    input wire [CPU_BRAM_DATA_WIDTH/8-1:0] cpu_spk_out_we;
    input wire cpu_spk_out_en;

    input wire [BRAM_ADDR_WIDTH-1:0] cpu_input_addr;
    input wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_input_din;
    output wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_input_dout;
    input wire [CPU_BRAM_DATA_WIDTH/8-1:0] cpu_input_we;
    input wire cpu_input_en;

    wire buff_idx;

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

    wire [BRAM_ADDR_WIDTH-1:0] mem_addr;
    wire [INPUT_BRAM_DATA_WIDTH-1:0] mem_dout;
    wire [INPUT_BRAM_DATA_WIDTH-1:0] mem_din;
    wire mem_bram_en;
    wire mem_bram_rst;
    wire [INPUT_BRAM_DATA_WIDTH/8-1:0] mem_bram_we;

    wire [BRAM_ADDR_WIDTH-1:0] lif_spk_out_addr;
    wire [CROSSBAR_NEURONS-1:0] lif_spk_out_dout;
    wire [CROSSBAR_NEURONS-1:0] lif_spk_out_din;
    wire lif_spk_out_bram_en;
    wire lif_spk_out_bram_rst;
    wire [CROSSBAR_NEURONS/8-1:0] lif_spk_out_bram_we;

    wire [BRAM_ADDR_WIDTH-1:0] lif_mem_addr;
    wire [MEM_BRAM_DATA_WIDTH-1:0] lif_mem_dout;
    wire [MEM_BRAM_DATA_WIDTH-1:0] lif_mem_din;
    wire lif_mem_bram_en;
    wire lif_mem_bram_rst;
    wire [MEM_BRAM_DATA_WIDTH/8-1:0] lif_mem_bram_we;

    wire [TILE_IDX_WIDTH-1:0] tile_idx;
    wire [TILE_IDX_WIDTH-1:0] tile_idx_x;
    wire [TILE_IDX_WIDTH-1:0] tile_idx_y;

    wire use_input;

    wire weight_bram_done;
    wire input_bram_done;
    wire spk_in_bram_done;

    wire next_ready;
    assign next_ready = weight_bram_done && input_bram_done 
                    && spk_in_bram_done && tile_idx_fifo_push_done;

    assign is_last_tile = (tile_idx == MAX_TILES);

    wire [MAX_NEURONS/CROSSBAR_NEURONS-1 : 0] has_spk;
    wire [MAX_NEURONS/CROSSBAR_NEURONS-1 : 0] has_spk_nxt;

    buff_idx_controller #(
        .MAX_NEURONS(MAX_NEURONS),
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS)   
    ) buff_idx_controller_0 (
        .clk(clk),
        .en(enable),
        .has_spk(has_spk),
        .buff_idx(buff_idx),
        .has_spk_nxt(has_spk_nxt)
    );

    asymmetric_dual_port_bram #(
        .DATA_WIDTH_B(TILE_IDX_BRAM_DATA_WIDTH),
        .ADDR_WIDTH_B(BRAM_ADDR_WIDTH),
        .DATA_WIDTH_A(CPU_BRAM_DATA_WIDTH),
        .ADDR_WIDTH_A(BRAM_ADDR_WIDTH),
        .MEM_PATH("tile_idx_bram.mem")
    ) bram0 (
        .clkb(clk),
        .addrb(addr_tile_idx),
        .dinb(din_tile_idx),
        .doutb(dout_tile_idx),
        .web(bram_we_tile_idx),
        .enb(bram_en_tile_idx),

        .clka(clk),
        .addra(cpu_tile_idx_addr),
        .douta(cpu_tile_idx_dout),
        .dina(cpu_tile_idx_din),
        .wea(cpu_tile_idx_we),
        .ena(cpu_tile_idx_en)
    );
    
    asymmetric_dual_port_bram #(
        .DATA_WIDTH_A(SPK_IN_BRAM_DATA_WIDTH),
        .ADDR_WIDTH_A(BRAM_ADDR_WIDTH),
        .DATA_WIDTH_B(SPK_IN_BRAM_DATA_WIDTH),
        .ADDR_WIDTH_B(BRAM_ADDR_WIDTH),
        .MEM_PATH("spk_in_bram.mem")
    ) bram1 (
        .clka(clk),
        .addra(addr_spk_in),
        .dina(din_spk_in),
        .douta(dout_spk_in),
        .wea(bram_we_spk_in),
        .ena(bram_en_spk_in),

        .clkb(clk),
        .addrb(lif_spk_out_addr),
        .dinb(lif_spk_out_din),
        .doutb(lif_spk_out_dout),
        .web(lif_spk_out_bram_we),
        .enb(lif_spk_out_bram_en)
    );

    //wire [WEIGHT_BRAM_DATA_WIDTH-1:0] doutb2;
    asymmetric_dual_port_bram #(
        .DATA_WIDTH_A(WEIGHT_BRAM_DATA_WIDTH),
        .ADDR_WIDTH_A(BRAM_ADDR_WIDTH),
        .DATA_WIDTH_B(CPU_BRAM_DATA_WIDTH_WEIGHT),
        .ADDR_WIDTH_B(BRAM_ADDR_WIDTH),
        .MEM_PATH("weight_bram.mem")
    ) bram2 (
        .clka(clk),
        .addra(addr_weight),
        .douta(dout_weight),
        .dina(din_weight),
        .wea(bram_we_weight),
        .ena(bram_en_weight),

        .clkb(clk),
        .addrb(cpu_weight_addr),
        .doutb(cpu_weight_dout),
        .dinb(cpu_weight_din),
        .web(cpu_weight_we),
        .enb(cpu_weight_en)
    );

    //wire [INPUT_BRAM_DATA_WIDTH-1:0] doutb3;
    asymmetric_dual_port_bram #(
        .DATA_WIDTH_A(INPUT_BRAM_DATA_WIDTH),
        .ADDR_WIDTH_A(BRAM_ADDR_WIDTH),
        .DATA_WIDTH_B(CPU_BRAM_DATA_WIDTH),
        .ADDR_WIDTH_B(BRAM_ADDR_WIDTH),
        .MEM_PATH("input_bram.mem")
    ) bram3 (
        .clka(clk),
        .addra(addr_input),
        .douta(dout_input),
        .dina(din_input),
        .wea(bram_we_input),
        .ena(bram_en_input),

        .clkb(clk),
        .addrb(cpu_input_addr),
        .doutb(cpu_input_dout),
        .dinb(cpu_input_din),
        .web(cpu_input_we),
        .enb(cpu_input_en)
    );

    //wire [INPUT_BRAM_DATA_WIDTH-1:0] doutb4;
    asymmetric_dual_port_bram #(
        .DATA_WIDTH_A(MEM_BRAM_DATA_WIDTH),
        .ADDR_WIDTH_A(BRAM_ADDR_WIDTH),
        .DATA_WIDTH_B(MEM_BRAM_DATA_WIDTH),
        .ADDR_WIDTH_B(BRAM_ADDR_WIDTH),
        .MEM_PATH("mem_bram.mem")
    ) bram4 (
        .clka(clk),
        .addra(lif_mem_addr),
        .dina(lif_mem_din),
        .douta(lif_mem_dout),
        .wea(lif_mem_bram_we),
        .ena(lif_mem_bram_en),
        .clkb(0),
        .addrb(0),
        .dinb(0),
        .doutb(),
        .web(0),
        .enb(0)
    );

    wire [SPK_IN_BRAM_DATA_WIDTH-1:0] lif_spk_out_addr_mod;
    assign lif_spk_out_addr_mod = lif_spk_out_addr[$clog2((MAX_TILES * CROSSBAR_NEURONS / 8))-1:0]; // get rid of buff_idx addressing
    asymmetric_dual_port_bram #(
        .DATA_WIDTH_B(SPK_IN_BRAM_DATA_WIDTH),
        .ADDR_WIDTH_B(BRAM_ADDR_WIDTH),
        .DATA_WIDTH_A(CPU_BRAM_DATA_WIDTH),
        .ADDR_WIDTH_A(BRAM_ADDR_WIDTH),
        .MEM_PATH("spk_in_bram.mem")
    ) bram5 (
        .clka(clk),
        .addra(cpu_spk_out_addr),
        .dina(cpu_spk_out_din),
        .douta(cpu_spk_out_dout),
        .wea(cpu_spk_out_we),
        .ena(cpu_spk_out_en),

        .clkb(clk),
        .addrb(lif_spk_out_addr_mod),
        //.doutb(lif_spk_out_dout),
        .doutb(),
        .dinb(lif_spk_out_din),
        .web(lif_spk_out_bram_we),
        .enb(lif_spk_out_bram_en)
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
        .buff_idx(buff_idx),
        .has_spk(has_spk),
        .tile_idx_fifo_full(tile_idx_fifo_full),
        .tile_idx_fifo_push_done(next_ready),
        .tile_idx_fifo_push(tile_idx_fifo_push),
        .tile_idx_fifo_din(tile_idx_fifo_din),
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
        .tile_done(weight_bram_done),
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
        .tile_done(spk_in_bram_done),
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
        .tile_use_input(tile_use_input_fifo_din),
        .tile_idx(tile_idx),
        .tile_idx_x(tile_idx_x),
        .tile_idx_y(tile_idx_y),
        .input_fifo_full(input_fifo_full),
        .input_fifo_push(input_fifo_push),
        .input_fifo_push_done(input_fifo_push_done),
        .input_fifo_din(input_fifo_din),
        .tile_done(input_bram_done),
        .addr(addr_input),
        .dout(dout_input),
        .din(din_input),
        .bram_en(bram_en_input),
        .bram_rst(bram_rst_input),
        .bram_we(bram_we_input)
    );

    lif_bram #(
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .MAX_TILES(MAX_TILES),
        .TILE_IDX_WIDTH(TILE_IDX_WIDTH),
        .MAX_NEURONS(MAX_NEURONS),
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS)
    ) lif_bram_0 (
        .clk(clk),
        .enable(lif_bram_enable),
        .has_spk_nxt(has_spk_nxt),
        .buff_idx(buff_idx),
        .we(lif_bram_we),
        .tile_idx_x(lif_tile_idx_x),
        .tile_idx_y(lif_tile_idx_y),
        .mem_out(lif_mem_out),
        .spk_out(lif_spk_out),
        .mem_in(lif_mem_in),
        .spk_in(lif_spk_in),
        .done(lif_bram_done),
        .mem_addr(lif_mem_addr),
        .mem_dout(lif_mem_dout),
        .mem_din(lif_mem_din),
        .mem_bram_en(lif_mem_bram_en),
        .mem_bram_rst(lif_mem_bram_rst),
        .mem_bram_we(lif_mem_bram_we),
        .spk_out_addr(lif_spk_out_addr),
        .spk_out_dout(lif_spk_out_dout),
        .spk_out_din(lif_spk_out_din),
        .spk_out_bram_en(lif_spk_out_bram_en),
        .spk_out_bram_rst(lif_spk_out_bram_rst),
        .spk_out_bram_we(lif_spk_out_bram_we),
        .is_last_tile(is_last_tile)
    );
endmodule