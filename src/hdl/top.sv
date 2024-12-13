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

    wire xbar_bram_clk;
    wire [BRAM_ADDR_WIDTH-1:0] xbar_bram_addr;
    wire [BRAM_DATA_WIDTH-1:0] xbar_bram_dout;
    wire [BRAM_DATA_WIDTH-1:0] xbar_bram_din;
    wire xbar_bram_en;
    wire xbar_bram_rst;
    wire xbar_bram_we;

    wire lif_bram_clk;
    wire [BRAM_ADDR_WIDTH-1:0] lif_bram_addr;
    wire [BRAM_DATA_WIDTH-1:0] lif_bram_dout;
    wire [BRAM_DATA_WIDTH-1:0] lif_bram_din;
    wire lif_bram_en;
    wire lif_bram_rst;
    wire lif_bram_we;
    
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

    assign switcher_bram_clk[1] = xbar_bram_clk;
    assign switcher_bram_addr[1] = xbar_bram_addr;
    assign switcher_bram_dout[1] = xbar_bram_dout;
    assign switcher_bram_din[1] = xbar_bram_din;
    assign switcher_bram_en[1] = xbar_bram_en;
    assign switcher_bram_rst[1] = xbar_bram_rst;
    assign switcher_bram_we[1] = xbar_bram_we;

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

    );

    weight_fifo #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(FIFO_LENGTH)
    ) weight_fifo_0 (

    );

    tile_idx_fifo #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(FIFO_LENGTH),
        .TILE_IDX_WIDTH(TILE_IDX_WIDTH)
    ) tile_idx_fifo_in_0 ( // streams from xbar_bram => xbar 

    );

    tile_idx_fifo #(
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS),
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .LENGTH(FIFO_LENGTH),
        .TILE_IDX_WIDTH(TILE_IDX_WIDTH)
    ) tile_idx_fifo_out_0 ( // streams from xbar => lif 

    );

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