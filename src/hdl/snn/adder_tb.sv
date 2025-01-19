`include "adder.sv"

module adder_tb;
    reg signed [7:0] a;
    reg signed [7:0] b;
    wire signed [7:0] c;

    adder #(8)
    adder_0 (
        a, b, c
    );

    initial begin
        #0
        a = 127;
        b = 127;
        #100
        $display("%d", c);
    end
endmodule