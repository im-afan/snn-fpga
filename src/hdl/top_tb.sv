`timescale 1ns / 10ps
`include "top.sv"

module top_tb;
    reg clk;
    wire [15:0] led;
    reg [15:0] sw;

    top top_0 (
        .clk(clk),
        .led(led),
        .sw(sw)
    );

    initial begin
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile(".wave/top_dump.vcd");
        $dumpvars(100, top_tb);

        #0 
        clk = 0;
        sw = 0;
        #100
        sw = 1;
        #100000
        $writememb(".wave/top_dump.mem", top_0.dual_port_bram_0.mem);
        $finish;
    end
endmodule