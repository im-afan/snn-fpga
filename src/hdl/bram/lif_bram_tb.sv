`timescale 1ns / 10ps;
`include "lif_bram.sv"
`include "dual_port_bram.sv"

module lif_bram_tb;
    localparam BRAM_DATA_WIDTH = 1024;
    localparam BRAM_ADDR_WIDTH = 16;
    localparam NETWORK_WIDTH = 8;
    localparam MAX_TILES = 64;
    localparam TILE_IDX_WIDTH = 16;
    localparam MAX_NEURONS = 1024;
    localparam CROSSBAR_NEURONS = 16;

    reg clk;
    reg enable;
    
    reg we;
    reg [TILE_IDX_WIDTH-1:0] tile_idx_x;
    reg [NETWORK_WIDTH-1:0] mem_out [CROSSBAR_NEURONS];
    wire [NETWORK_WIDTH-1:0] mem_in [CROSSBAR_NEURONS];
    
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

    lif_bram #(
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
        .we(we),
        .tile_idx_x(tile_idx_x),
        .mem_out(mem_out),
        .mem_in(mem_in),
        .addr(addr),
        .dout(dout),
        .din(din),
        .bram_en(bram_en),
        .bram_rst(bram_rst),
        .bram_we(bram_we)
    );

    generate 
        genvar i;
        for(i = 0; i < CROSSBAR_NEURONS; i++) begin
            wire [NETWORK_WIDTH-1:0] mem_in_debug;
            wire [NETWORK_WIDTH-1:0] mem_out_debug;
            assign mem_in_debug = mem_in[i];
            assign mem_out_debug = mem_out[i];
        end
    endgenerate

    initial begin
        forever #5 clk = ~clk;
    end

    initial begin
        #0 clk = 0;
        #0 enable = 0;
        #0 tile_idx_x = 0;
        #0 we = 0;
        for(integer i = 0; i < CROSSBAR_NEURONS; i++) begin
            #0 mem_out[i] = 0;
        end

        #10 enable = 1;
        $dumpfile(".wave/dump.vcd");
        $dumpvars(100, lif_bram_tb);

        #10000 $finish;
    end

    initial begin
        #500 for(integer i = 0; i < CROSSBAR_NEURONS; i++) begin
            #0 mem_out[i] = i+5;
        end 
        #0 we = 1;
        #100 we = 0;
    end

endmodule