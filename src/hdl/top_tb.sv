`timescale 1ns / 10ps
`include "top_standalone.sv"

module top_tb;
    reg clk;
    wire [15:0] led;
    reg [15:0] sw;

    top_standalone top_0 (
        .clk(clk),
        .led(led),
        .sw(sw)
    );

    initial begin
        forever #5 clk = ~clk;
    end

    initial begin
        forever #150000 sw = ~sw;
    end

    initial begin
        $dumpfile(".wave/top_dump.vcd");
        $dumpvars(100, top_tb);

        #0 
        clk = 0;
        sw = 0;
        #1000
        sw = 1;
        #1000000
        //#15000
        $writememb(".wave/spk_mem_dump.mem", top_0.bram_streamer_0.bram5.mem.mem);
        $finish;
    end
endmodule