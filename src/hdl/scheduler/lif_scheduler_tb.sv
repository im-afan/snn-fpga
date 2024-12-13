`timescale 1ns / 10ps

`include "lif_scheduler.sv"

module lif_scheduler_tb;
    reg clk;
    reg en;
    reg lif_done;
    reg mac_out_fifo_empty;
    reg mac_out_fifo_pop_done;
    wire mac_out_fifo_pop; 
    reg tile_idx_fifo_empty;
    reg tile_idx_fifo_pop_done;
    wire tile_idx_fifo_pop;
    wire lif_en;

    lif_scheduler lif_scheduler_0 (
        .clk(clk),
        .en(en),
        .lif_done(lif_done),
        .mac_out_fifo_empty(mac_out_fifo_empty),
        .mac_out_fifo_pop(mac_out_fifo_pop),
        .mac_out_fifo_pop_done(mac_out_fifo_pop_done),
        .tile_idx_fifo_empty(tile_idx_fifo_empty),
        .tile_idx_fifo_pop(tile_idx_fifo_pop),
        .tile_idx_fifo_pop_done(tile_idx_fifo_pop_done),
        .lif_en(lif_en)
    );

    initial begin
        forever #5 clk <= ~clk;
    end

    initial begin
        $dumpfile(".wave/lif_scheduler_tb.vcd");
        $dumpvars(100, lif_scheduler_tb);

        #0
        clk = 0;
        en = 0;
        lif_done = 0;
        mac_out_fifo_empty = 0;
        mac_out_fifo_pop_done = 0;
        tile_idx_fifo_empty = 0;
        tile_idx_fifo_pop_done = 0;

        #50
        en = 1;

        #50 lif_done = 1;

        #10
        mac_out_fifo_pop_done = 1;
        tile_idx_fifo_pop_done = 1;

        #10 lif_done = 0;

        #50
        mac_out_fifo_empty = 1;
        tile_idx_fifo_empty = 1;

        #100 $finish;
    end
endmodule