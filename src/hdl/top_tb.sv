`include "top.sv"

module top_tb;
    reg clk;
    reg rst;

    top top_0 (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        forever #5 clk = ~clk;
    end
    initial begin
        $dumpfile(".wave/top_dump.vcd");
        $dumpvars(100, top_tb);

        #0 rst = 0;
    end
endmodule