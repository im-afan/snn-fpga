`include "fifo/spk_in_fifo.sv"
`include "fifo/tile_idx_fifo.sv"
`include "fifo/weight_fifo.sv"
`include "fifo/mac_out_fifo.sv"
`include "snn/lif_array.sv"
`include "snn/synapse_array.sv"
`include "bram/dual_port_bram.sv"
`include "bram/lif_bram.sv"
`include "bram/xbar_bram.sv"
`include "bram/input_bram.sv"
`include "bram/bram_switcher.sv"
`include "bram/buff_idx_controller.sv"
`include "scheduler/lif_scheduler.sv"
`include "scheduler/xbar_scheduler.sv"

module top (
    input wire clk,
    input wire [15:0] sw,
    output wire [15:0] led
    //input wire en
);
    localparam integer BRAM_ADDR_WIDTH = 16;
    localparam integer BRAM_DATA_WIDTH = 1024;
    localparam integer NETWORK_WIDTH = 8;
    localparam integer MAX_TILES = 128;
    localparam integer TILE_IDX_WIDTH = 16;
    localparam integer MAX_NEURONS = 1024;
    localparam integer CROSSBAR_NEURONS = 16;
    localparam integer FIFO_LENGTH = 3;
    localparam integer THRESH = 32;

    wire buff_idx; // switches between 0 and 1: which one you are currently WRITING TO
    //assign buff_idx = 1;

    wire en;
    assign en = sw[0];
    
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
    assign input_bram_clk = clk;
    wire [BRAM_ADDR_WIDTH-1:0] input_bram_addr;
    wire [BRAM_DATA_WIDTH-1:0] input_bram_dout;
    wire [BRAM_DATA_WIDTH-1:0] input_bram_din;
    wire input_bram_en;
    wire input_bram_rst;
    wire [BRAM_DATA_WIDTH/8-1:0] input_bram_we;
    wire input_bram_active;
    wire input_bram_want_active;

    wire xbar_bram_clk;
    assign xbar_bram_clk = clk;
    wire [BRAM_ADDR_WIDTH-1:0] xbar_bram_addr;
    wire [BRAM_DATA_WIDTH-1:0] xbar_bram_dout;
    wire [BRAM_DATA_WIDTH-1:0] xbar_bram_din;
    wire xbar_bram_en;
    wire xbar_bram_rst;
    wire [BRAM_DATA_WIDTH/8-1:0] xbar_bram_we;
    wire xbar_bram_active;
    wire xbar_bram_want_active;

    wire lif_bram_clk;
    assign lif_bram_clk = clk;
    wire [BRAM_ADDR_WIDTH-1:0] lif_bram_addr;
    wire [BRAM_DATA_WIDTH-1:0] lif_bram_dout;
    wire [BRAM_DATA_WIDTH-1:0] lif_bram_din;
    wire lif_bram_en;
    wire lif_bram_rst;
    wire [BRAM_DATA_WIDTH/8-1:0] lif_bram_we;
    wire lif_bram_active;
    wire lif_we;
    wire lif_bram_want_active;
    
    wire switcher_bram_clk[3:0];
    wire [BRAM_ADDR_WIDTH-1:0] switcher_bram_addr[3:0];
    wire [BRAM_DATA_WIDTH-1:0] switcher_bram_dout[3:0];
    wire [BRAM_DATA_WIDTH-1:0] switcher_bram_din[3:0];
    wire switcher_bram_en[3:0];
    wire switcher_bram_rst[3:0];
    wire [BRAM_DATA_WIDTH/8-1:0] switcher_bram_we[3:0];
    wire switcher_bram_active[3:0];
    wire switcher_bram_want_active[3:0];

    assign switcher_bram_clk[1] = lif_bram_clk;
    assign switcher_bram_addr[1] = lif_bram_addr;
    assign lif_bram_dout = switcher_bram_dout[1];
    assign switcher_bram_din[1] = lif_bram_din;
    assign switcher_bram_en[1] = lif_bram_en;
    assign switcher_bram_rst[1] = lif_bram_rst;
    assign switcher_bram_we[1] = lif_bram_we;
    assign lif_bram_active = switcher_bram_active[1];
    assign switcher_bram_want_active[1] = lif_bram_want_active;

    assign switcher_bram_clk[2] = xbar_bram_clk;
    assign switcher_bram_addr[2] = xbar_bram_addr;
    assign xbar_bram_dout = switcher_bram_dout[2];
    assign switcher_bram_din[2] = xbar_bram_din;
    assign switcher_bram_en[2] = xbar_bram_en;
    assign switcher_bram_rst[2] = xbar_bram_rst;
    assign switcher_bram_we[2] = xbar_bram_we;
    assign xbar_bram_active = switcher_bram_active[2];
    assign switcher_bram_want_active[2] = xbar_bram_want_active;

    assign switcher_bram_clk[0] = input_bram_clk;
    assign switcher_bram_addr[0] = input_bram_addr;
    assign input_bram_dout = switcher_bram_dout[0];
    assign switcher_bram_din[0] = input_bram_din;
    assign switcher_bram_en[0] = input_bram_en;
    assign switcher_bram_rst[0] = input_bram_rst;
    assign switcher_bram_we[0] = input_bram_we;
    assign input_bram_active = switcher_bram_active[0];
    assign switcher_bram_want_active[0] = input_bram_want_active;

    wire [TILE_IDX_WIDTH-1:0] tile_idx_x;
    wire [TILE_IDX_WIDTH-1:0] tile_idx_y;
    wire [NETWORK_WIDTH-1:0] mem_out [CROSSBAR_NEURONS];
    wire [CROSSBAR_NEURONS-1:0] spk_out;
    wire [NETWORK_WIDTH-1:0] mem_in [CROSSBAR_NEURONS];
    wire [NETWORK_WIDTH-1:0] mac_out [CROSSBAR_NEURONS];
    wire [CROSSBAR_NEURONS-1:0] spk_in;
    wire [NETWORK_WIDTH-1:0] weight [CROSSBAR_NEURONS][CROSSBAR_NEURONS];

    wire lif_bram_en_local;
    wire lif_bram_done;

    wire weight_fifo_full;
    wire weight_fifo_push_done;
    wire weight_fifo_pop_done;
    wire weight_fifo_push;
    wire weight_fifo_pop;
    wire weight_fifo_empty;
    wire [BRAM_DATA_WIDTH-1:0] weight_fifo_din;

    wire spk_in_fifo_full;
    wire spk_in_fifo_push_done;
    wire spk_in_fifo_pop_done;
    wire spk_in_fifo_push;
    wire spk_in_fifo_pop;
    wire spk_in_fifo_empty;
    wire [CROSSBAR_NEURONS-1:0] spk_in_fifo_din;

    wire tile_idx_fifo_full;
    wire tile_idx_fifo_push_done;
    wire tile_idx_fifo_push0;
    wire tile_idx_fifo_push1;
    wire tile_idx_fifo_pop;
    wire tile_idx_fifo_empty;
    wire [2*TILE_IDX_WIDTH-1:0] tile_idx_fifo_din0;
    wire [2*TILE_IDX_WIDTH-1:0] tile_idx_fifo_din1;

    wire mac_out_fifo_full;
    wire mac_out_fifo_push_done;
    wire mac_out_fifo_pop_done;
    wire mac_out_fifo_push0;
    wire mac_out_fifo_push1;
    wire mac_out_fifo_pop;
    wire mac_out_fifo_empty;
    wire [CROSSBAR_NEURONS*NETWORK_WIDTH-1:0] mac_out_fifo_din0;
    wire [CROSSBAR_NEURONS*NETWORK_WIDTH-1:0] mac_out_fifo_din1;

    wire lif_array_done;
    wire lif_array_en;
    wire [NETWORK_WIDTH-1:0] mem_out_lif [CROSSBAR_NEURONS];
    wire [NETWORK_WIDTH-1:0] mem_in_lif [CROSSBAR_NEURONS];
    wire [CROSSBAR_NEURONS-1:0] spk_out_lif;
    wire [CROSSBAR_NEURONS-1:0] spk_in_lif;

    assign led = spk_out_lif;

    wire synapse_array_done;
    wire synapse_array_en;
    wire spk_rst;

    dual_port_bram #(
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH)
    ) dual_port_bram_0 (
        .clka(clk),
        .addra(addra),
        .dina(dina),
        .douta(douta),
        .wea(wea),
        .ena(ena),

        .clkb(clk),
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
        .active(switcher_bram_active),
        .want_active(switcher_bram_want_active),

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
        .doutb(doutb)
    );

    buff_idx_controller buff_idx_controller_0 (
        .clk(clk),
        .en(en),
        .buff_idx(buff_idx)
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
        .enable(lif_bram_en_local),
        .buff_idx(buff_idx),
        .we(lif_we),
        .tile_idx_x(tile_idx_x),
        .tile_idx_y(tile_idx_y),
        .mem_out(mem_out_lif),
        .spk_out(spk_out_lif),
        .mem_in(mem_in_lif),
        .spk_in(spk_in_lif),
        .done(lif_bram_done),
        .addr(lif_bram_addr),
        .dout(lif_bram_dout),
        .din(lif_bram_din),
        .bram_en(lif_bram_en),
        .bram_rst(lif_bram_rst),
        .bram_we(lif_bram_we),
        .bram_want_active(lif_bram_want_active),
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
        .enable(en),

        .buff_idx(buff_idx),
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
        .tile_idx_fifo_push(tile_idx_fifo_push1),
        .tile_idx_fifo_din(tile_idx_fifo_din1),

        .addr(xbar_bram_addr),
        .dout(xbar_bram_dout),
        .din(xbar_bram_din),
        .bram_en(xbar_bram_en),
        .bram_rst(xbar_bram_rst),
        .bram_we(xbar_bram_we),
        .bram_want_active(xbar_bram_want_active),
        .bram_active(xbar_bram_active)
    );

    input_bram #(
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .MAX_TILES(MAX_TILES),
        .TILE_IDX_WIDTH(TILE_IDX_WIDTH),
        .MAX_NEURONS(MAX_NEURONS),
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS)
    ) input_bram_0 (
        .clk(clk),
        .enable(en),

        .buff_idx(buff_idx),
        .mac_out_fifo_full(mac_out_fifo_full),
        .mac_out_fifo_push(mac_out_fifo_push0),
        .mac_out_fifo_push_done(mac_out_fifo_push_done),
        .mac_out_fifo_din(mac_out_fifo_din0),

        .tile_idx_fifo_full(tile_idx_fifo_full),
        .tile_idx_fifo_push(tile_idx_fifo_push0),
        .tile_idx_fifo_push_done(tile_idx_fifo_push_done),
        .tile_idx_fifo_din(tile_idx_fifo_din0),

        .addr(input_bram_addr),
        .dout(input_bram_dout),
        .din(input_bram_din),
        .bram_en(input_bram_en),
        .bram_rst(input_bram_rst),
        .bram_we(input_bram_we),
        .bram_want_active(input_bram_want_active),
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
        .din0(tile_idx_fifo_din0),
        .din1(tile_idx_fifo_din1),
        .push0(tile_idx_fifo_push0),
        .push1(tile_idx_fifo_push1),
        .pop(tile_idx_fifo_pop),
        .tile_idx_x(tile_idx_x),
        .tile_idx_y(tile_idx_y),
        .full(tile_idx_fifo_full),
        .empty(tile_idx_fifo_empty),
        .push_done(tile_idx_fifo_push_done),
        .pop_done(tile_idx_fifo_pop_done)
    );

    /*tile_idx_fifo #( TODO maybe dont need this? maybe do.
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(FIFO_LENGTH),
        .TILE_IDX_WIDTH(TILE_IDX_WIDTH)
    ) tile_idx_fifo_out_0 ( // streams from xbar => lif 

    );*/

    spk_in_fifo #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(FIFO_LENGTH)       
    ) spk_in_fifo_0 (
        .clk(clk),
        .en(en),
        .din(spk_in_fifo_din),
        .push(spk_in_fifo_push),
        .pop(spk_in_fifo_pop),
        .spk_in(spk_in),
        .full(spk_in_fifo_full),
        .empty(spk_in_fifo_empty),
        .pop_done(spk_in_fifo_pop_done),
        .push_done(spk_in_fifo_push_done) 
    );

    mac_out_fifo #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(FIFO_LENGTH)       
    ) mac_out_fifo_0 (
        .clk(clk),
        .en(en),
        .din0(mac_out_fifo_din0),
        .push0(mac_out_fifo_push0),
        .din1(mac_out_fifo_din1),
        .push1(mac_out_fifo_push1),
        .pop(mac_out_fifo_pop),
        .mac_out(mac_out),
        .spk_rst(spk_rst),
        .full(mac_out_fifo_full),
        .empty(mac_out_fifo_empty),
        .pop_done(mac_out_fifo_pop_done),
        .push_done(mac_out_fifo_push_done) 
    );

    lif_scheduler lif_scheduler_0 (
        .clk(clk),
        .en(en),
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
        .en(en),
        .crossbar_done(synapse_array_done),

        .weight_fifo_empty(weight_fifo_empty),
        .weight_fifo_pop(weight_fifo_pop),
        .weight_fifo_pop_done(weight_fifo_pop_done),

        .spk_in_fifo_empty(spk_in_fifo_empty),
        .spk_in_fifo_pop(spk_in_fifo_pop),
        .spk_in_fifo_pop_done(spk_in_fifo_pop_done),

        .mac_out_fifo_full(mac_out_fifo_full),
        .mac_out_fifo_push(mac_out_fifo_push1),
        .mac_out_fifo_push_done(mac_out_fifo_push_done),

        .crossbar_en(synapse_array_en)
    );    

    lif_array #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .THRESH(THRESH),
        .NETWORK_WIDTH(NETWORK_WIDTH)
    ) lif_array_0 (
        .clk(clk),
        .enable(lif_array_en),
        .bram_done(lif_bram_done),
        .spk_rst(spk_rst),
        .spk_in(spk_in_lif),
        .u_mem_in(mem_in_lif),
        .u_mac_out(mac_out),
        .spk_out(spk_out_lif),
        .u_mem_out(mem_out_lif),
        .done(lif_array_done),
        .bram_we(lif_we),
        .bram_enable(lif_bram_en_local)
    );

    synapse_array #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .NETWORK_WIDTH(NETWORK_WIDTH)
    ) synapse_array_0 (
        .clk(clk),
        .enable(synapse_array_en),
        .u_weight(weight),
        .spk_in(spk_in),
        .u_mac_out(mac_out_fifo_din1),
        .done(synapse_array_done)
    );

endmodule