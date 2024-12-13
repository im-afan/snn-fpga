`timescale 1ns / 10ps;
`include "input_bram.sv"
`include "dual_port_bram.sv"

module input_bram_tb;
    localparam BRAM_DATA_WIDTH = 1024;
    localparam BRAM_ADDR_WIDTH = 16;
    localparam NETWORK_WIDTH = 8;
    localparam MAX_TILES = 64;
    localparam TILE_IDX_WIDTH = 16;
    localparam MAX_NEURONS = 1024;
    localparam CROSSBAR_NEURONS = 16;

    reg clk; 
    reg enable;

    reg mac_out_fifo_full = 0;
    reg tile_idx_fifo_full = 0;

    reg mac_out_fifo_push_done = 1;
    reg tile_idx_fifo_push_done = 1;

    wire [CROSSBAR_NEURONS*NETWORK_WIDTH-1:0] mac_out_fifo_din;
    wire [2*TILE_IDX_WIDTH-1:0] tile_idx_fifo_din;

    wire mac_out_fifo_push;
    wire tile_idx_fifo_push;

    wire [BRAM_ADDR_WIDTH-1:0] addr;
    reg [BRAM_DATA_WIDTH-1:0] dout;
    wire [BRAM_DATA_WIDTH-1:0] din;
    wire bram_en;
    wire bram_rst;
    reg [BRAM_DATA_WIDTH/8-1:0] bram_we;
    reg bram_active; // if this port is active in switcher


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

    input_bram #(
        .BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
        .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
        .NETWORK_WIDTH(NETWORK_WIDTH),
        .MAX_TILES(MAX_TILES),
        .TILE_IDX_WIDTH(TILE_IDX_WIDTH),
        .MAX_NEURONS(MAX_NEURONS),
        .CROSSBAR_NEURONS(CROSSBAR_NEURONS)
    ) lif (
        .clk(clk),
        .enable(enable),
        .mac_out_fifo_full(mac_out_fifo_full),
        .tile_idx_fifo_full(tile_idx_fifo_full),
        .mac_out_fifo_push_done(mac_out_fifo_push_done),
        .tile_idx_fifo_push_done(tile_idx_fifo_push_done),
        .mac_out_fifo_din(mac_out_fifo_din),
        .tile_idx_fifo_din(tile_idx_fifo_din),

        .addr(addr),
        .dout(dout),
        .din(din),
        .bram_en(bram_en),
        .bram_rst(bram_rst),
        .bram_we(bram_we),
        .bram_active(bram_active)
    );

    initial begin
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile(".wave/dump.vcd");
        $dumpvars(100, input_bram_tb);
        
        #0 clk = 0;
        #0 enable = 0;
        #0 bram_active = 1;
        
        #100 enable = 1;
       
        #10000
        #0 $finish;
    end
endmodule