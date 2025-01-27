`timescale 1ns / 100ps
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
        #0 sw = 0;
        #100000
        $writememb(".wave/spk_out_dump.mem", top_0.top_0.bram_spk_out.mem.mem);
        $writememb(".wave/spk_out_buffer_dump.mem", top_0.top_0.bram_spk_in.mem.mem);
        $writememb(".wave/mem_out_dump.mem", top_0.top_0.bram_mem_in.mem.mem);
        $writememb(".wave/weight_dump.mem", top_0.top_0.bram_weight.mem.mem);
        $finish;
    end

    initial begin
        forever begin
            #100 sw = 1;
            #10000 sw = 0;
        end
    end

    initial begin
        $dumpfile(".wave/top_dump.vcd");
        $dumpvars(100, top_0);
        clk = 0;
        forever #5 clk = ~clk;
    end
endmodule