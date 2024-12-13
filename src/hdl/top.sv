`include "fifo/mem_in_fifo.sv"
`include "fifo/spk_in_fifo.sv"
`include "fifo/tile_idx_fifo.sv"
`include "fifo/weight_fifo.sv"
`include "fifo/mac_out_fifo.sv"
`include "snn/lif_array.sv"
`include "snn/synapse_array.sv"
`include "bram/dual_port_bram.sv"
`include "bram/lif_bram.sv"
`include "bram/xbar_bram.sv"
`include "bram/bram_switcher.sv"

module top (
    input wire clk,
    input wire rst
);
    localparam integer BRAM_ADDR_WIDTH = 12;
    localparam integer BRAM_DATA_WIDTH = 1024;
    localparam integer NETWORK_WIDTH = 8;
    localparam integer MAX_TILES = 64;
    localparam integer TILE_IDX_WIDTH = 16;
    localparam integer MAX_NEURONS = 1024;
    localparam integer CROSSBAR_NEURONS = 16;
    localparam integer FIFO_LENGTH = 2;
    localparam integer THRESH = 127;

    wire en;
    assign en = 1;
    
    wire clka; 
    wire [BRAM_ADDR_WIDTH-1:0] addra;
    wire [BRAM_DATA_WIDTH-1:0] dina;
    wire [BRAM_DATA_WIDTH-1:0] douta;
    wire [BRAM_DATA_WIDTH/8-1:0] wea;
    wire ena;

    wire clkb; 
    wire [BRAM_ADDR_WIDTH-1:0] addrb;
    wire [BRAM_DATA_WIDTH-1:0] dinb;
    wire [BRAM_DATA_WIDTH-1:0] doutb;
    wire [BRAM_DATA_WIDTH/8-1:0] web;
    wire enb;

    wire input_bram_clk;
    wire [BRAM_ADDR_WIDTH-1:0] input_bram_addr;
    wire [BRAM_DATA_WIDTH-1:0] input_bram_dout;
    wire [BRAM_DATA_WIDTH-1:0] input_bram_din;
    wire input_bram_en;
    wire input_bram_rst;
    wire input_bram_we;
    wire input_bram_active;

    wire xbar_bram_clk;
    wire [BRAM_ADDR_WIDTH-1:0] xbar_bram_addr;
    wire [BRAM_DATA_WIDTH-1:0] xbar_bram_dout;
    wire [BRAM_DATA_WIDTH-1:0] xbar_bram_din;
    wire xbar_bram_en;
    wire xbar_bram_rst;
    wire xbar_bram_we;
    wire xbar_bram_active;

    wire lif_bram_clk;
    wire [BRAM_ADDR_WIDTH-1:0] lif_bram_addr;
    wire [BRAM_DATA_WIDTH-1:0] lif_bram_dout;
    wire [BRAM_DATA_WIDTH-1:0] lif_bram_din;
    wire lif_bram_en;
    wire lif_bram_rst;
    wire lif_bram_we;
    wire lif_bram_active;
    
    wire switcher_bram_clk[2:0];
    wire [BRAM_ADDR_WIDTH-1:0] switcher_bram_addr[2:0];
    wire [BRAM_DATA_WIDTH-1:0] switcher_bram_dout[2:0];
    wire [BRAM_DATA_WIDTH-1:0] switcher_bram_din[2:0];
    wire switcher_bram_en[2:0];
    wire switcher_bram_rst[2:0];
    wire switcher_bram_we[2:0];

    assign switcher_bram_clk[0] = lif_bram_clk;
    assign switcher_bram_addr[0] = lif_bram_addr;
    assign switcher_bram_dout[0] = lif_bram_dout;
    assign switcher_bram_din[0] = lif_bram_din;
    assign switcher_bram_en[0] = lif_bram_en;
    assign switcher_bram_rst[0] = lif_bram_rst;
    assign switcher_bram_we[0] = lif_bram_we;
    assign switcher_bram_active[0] = lif_bram_active;

    assign switcher_bram_clk[1] = xbar_bram_clk;
    assign switcher_bram_addr[1] = xbar_bram_addr;
    assign switcher_bram_dout[1] = xbar_bram_dout;
    assign switcher_bram_din[1] = xbar_bram_din;
    assign switcher_bram_en[1] = xbar_bram_en;
    assign switcher_bram_rst[1] = xbar_bram_rst;
    assign switcher_bram_active[1] = xbar_bram_active;

    assign switcher_bram_clk[2] = input_bram_clk;
    assign switcher_bram_addr[2] = input_bram_addr;
    assign switcher_bram_dout[2] = input_bram_dout;
    assign switcher_bram_din[2] = input_bram_din;
    assign switcher_bram_en[2] = input_bram_en;
    assign switcher_bram_rst[2] = input_bram_rst;
    assign switcher_bram_active[2] = input_bram_active;

    wire [TILE_IDX_WIDTH-1:0] tile_idx_x;
    wire [TILE_IDX_WIDTH-1:0] tile_idx_y;
    wire [NETWORK_WIDTH-1:0] mem_out [CROSSBAR_NEURONS];
    wire [CROSSBAR_NEURONS-1:0] spk_out;
    wire [NETWORK_WIDTH-1:0] mem_in [CROSSBAR_NEURONS];
    wire [NETWORK_WIDTH-1:0] mac_in [CROSSBAR_NEURONS];
    wire [CROSSBAR_NEURONS-1:0] spk_in;
    wire [NETWORK_WIDTH-1:0] weight [CROSSBAR_NEURONS][CROSSBAR_NEURONS];

    wire lif_bram_done;

    wire weight_fifo_full;
    wire weight_fifo_push_done;
    wire weight_fifo_push;
    wire weight_fifo_pop;
    wire weight_fifo_empty;
    wire [BRAM_DATA_WIDTH-1:0] weight_fifo_din;

    wire spk_in_fifo_full;
    wire spk_in_fifo_push_done;
    wire spk_in_fifo_push;
    wire spk_in_fifo_pop;
    wire spk_in_fifo_empty;
    wire [CROSSBAR_NEURONS-1:0] spk_in_fifo_din;

    wire tile_idx_fifo_full;
    wire tile_idx_fifo_push_done;
    wire tile_idx_fifo_push;
    wire tile_idx_fifo_pop;
    wire tile_idx_fifo_empty;
    wire [2*TILE_IDX_WIDTH-1:0] tile_idx_fifo_din;

    wire mac_in_fifo_full;
    wire mac_in_fifo_push_done;
    wire mac_in_fifo_push;
    wire mac_in_fifo_pop;
    wire mac_in_fifo_empty;
    wire [CROSSBAR_NEURONS*NETWORK_WIDTH-1:0] mac_in_fifo_din;

    dual_port_bram #(
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH)
    ) dual_port_bram_0 (
        .clka(clka),
        .addra(addra),
        .dina(dina),
        .douta(douta),
        .wea(wea),
        .ena(ena),
        .clkb(clkb),
        .addrb(addrb),
        .dinb(dinb),
        .doutb(doutb),
        .web(web),
        .enb(enb) 
    );

    bram_switcher #(
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH)
    ) bram_switcher_0 (
        .clk(switcher_bram_clk),
        .en(switcher_bram_en),
        .addr(switcher_bram_addr),
        .we(switcher_bram_we),
        .din(switcher_bram_din),
        .dout(switcher_bram_dout),

        .clka(clka),
        .ena(ena),
        .addra(addra),
        .wea(wea),
        .dina(dina),
        .douta(douta),

        .clkb(clkb),
        .enb(enb),
        .addrb(addrb),
        .web(web),
        .dinb(dinb),
        .doutb(doutb),
    );

    lif_bram #(
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .MAX_TILES(MAX_TILES),
        .TILE_IDX_WIDTH(TILE_IDX_WIDTH),
        .MAX_NEURONS(MAX_NEURONS),
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS)
    ) lif_bram_0 (
        .clk(clk),
        .enable(lif_bram_en),
        .we(lif_bram_we),
        .tile_idx_x(tile_idx_x),
        .tile_idx_y(tile_idx_y),
        .mem_out(mem_out),
        .spk_out(spk_out),
        .mem_in(mem_in),
        .spk_in(spk_in),
        .done(lif_bram_done),
        .addr(lif_bram_addr),
        .dout(lif_bram_dout),
        .din(lif_bram_din),
        .bram_en(lif_bram_en),
        .bram_rst(lif_bram_rst),
        .bram_we(lif_bram_we),
        .bram_active(lif_bram_active)
    );

    xbar_bram #(
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .MAX_TILES(MAX_TILES),
        .TILE_IDX_WIDTH(TILE_IDX_WIDTH),
        .MAX_NEURONS(MAX_NEURONS),
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS)
    ) xbar_bram_0 (
        .clk(clk),
        .enable(xbar_bram_en),
        .we(xbar_bram_we),

        .weight_fifo_full(weight_fifo_full),
        .weight_fifo_push_done(weight_fifo_push_done),
        .weight_fifo_push(weight_fifo_push),
        .weight_fifo_din(weight_fifo_din),

        .spk_in_fifo_full(spk_in_fifo_full),
        .spk_in_fifo_push_done(spk_in_fifo_push_done),
        .spk_in_fifo_push(spk_in_fifo_push),
        .spk_in_fifo_din(spk_in_fifo_din),

        .tile_idx_fifo_full(tile_idx_fifo_full),
        .tile_idx_fifo_push_done(tile_idx_fifo_push_done),
        .tile_idx_fifo_push(tile_idx_fifo_push),
        .tile_idx_fifo_din(tile_idx_fifo_din),

        .addr(xbar_bram_addr),
        .dout(xbar_bram_dout),
        .din(xbar_bram_din),
        .bram_en(xbar_bram_en),
        .bram_rst(xbar_bram_rst),
        .bram_we(xbar_bram_we),
        .bram_active(xbar_bram_active)
    );

    input_bram #(
        .clk(clk),
        .enable(input_bram_en),

        .mac_out_fifo_full(mac_out_fifo_full),
        .mac_out_fifo_push(mac_out_fifo_push),
        .mac_out_fifo_push_done(mac_out_fifo_push_done),
        .mac_out_fifo_din(mac_out_fifo_din),

        .tile_idx_fifo_full(tile_idx_fifo_full),
        .tile_idx_fifo_push(tile_idx_fifo_push),
        .tile_idx_fifo_push_done(tile_idx_fifo_push_done),
        .tile_idx_fifo_din(tile_idx_fifo_din),

        .addr(input_bram_addr),
        .dout(input_bram_dout),
        .din(input_bram_din),
        .bram_en(input_bram_en),
        .bram_rst(input_bram_rst),
        .bram_we(input_bram_we),
        .bram_active(input_bram_active)
    );

    weight_fifo #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(FIFO_LENGTH)
    ) weight_fifo_0 (
        .clk(clk),
        .en(en),
        .din(weight_fifo_din),
        .push(weight_fifo_push),
        .pop(weight_fifo_pop),
        .weight(weight),
        .full(weight_fifo_full),
        .empty(weight_fifo_empty),
        .push_done(weight_fifo_push_done),
        .pop_done(weight_fifo_pop_done)
    );

    tile_idx_fifo #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(FIFO_LENGTH),
        .TILE_IDX_WIDTH(TILE_IDX_WIDTH)
    ) tile_idx_fifo_0 ( // streams from xbar_bram => xbar 
        .clk(clk),
        .en(en),
        .din(tile_idx_fifo_din),
    );

    /*tile_idx_fifo #( TODO maybe dont need this? maybe do.
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(FIFO_LENGTH),
        .TILE_IDX_WIDTH(TILE_IDX_WIDTH)
    ) tile_idx_fifo_out_0 ( // streams from xbar => lif 

    );*/

    mem_in_fifo #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(FIFO_LENGTH)       
    ) mem_in_fifo_0 (

    );

    spk_in_fifo #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(FIFO_LENGTH)       
    ) spk_in_fifo_0 (
        
    );

    mac_out_fifo #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(FIFO_LENGTH)       
    ) mac_out_fifo_0 (

    );

    lif_array #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .THRESH(THRESH),
        .NETWORK_WIDTH(NETWORK_WIDTH)
    ) lif_array_0 (

    );

    synapse_array #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .NETWORK_WIDTH(NETWORK_WIDTH)
    ) synapse_array_0 (

    );
endmodule