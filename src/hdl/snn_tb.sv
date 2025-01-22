`timescale 1ns / 10ps
`include "snn/snn.sv"

module snn_tb;
    reg clk;
    reg rst;
    wire [2047:0] i_weight;
    wire [127:0] i_network_input;
    wire [127:0] i_mem_in;
    reg [15:0] i_spk_in;
    wire [15:0] o_spk_out;
    wire [127:0] o_mem_out;
    wire lif_has_out;

    reg signed [8-1:0] weight [16][16];
    reg signed [8-1:0] network_input [16];
    reg signed [8-1:0] mem_in [16];
    wire signed [8-1:0] mac_out [16];
    reg signed [8-1:0] mem_out [16];
    wire xbar_has_out;

    generate
        genvar i, j;
        for(i = 0; i < 16; i++) begin
            assign i_network_input[i*8 +: 8] = network_input[i];
            assign i_mem_in[i*8 +: 8] = mem_in[i];
            assign mem_out[i] = o_mem_out[i*8 +: 8];
            for(j = 0; j < 16; j++) begin
                assign i_weight[(16*i+j)*8 +: 8] = weight[i][j];
            end
        end
    endgenerate

    snn snn_0 (
        .clk(clk),
        .push_rst(rst),
        .i_weight(i_weight),
        .i_network_input(i_network_input),
        .i_mem_in(i_mem_in),
        .i_spk_in(i_spk_in),
        .o_spk_out(o_spk_out),
        .o_mem_out(o_mem_out),
        .lif_has_out(lif_has_out)
    );

    initial begin
        $dumpfile(".wave/snn_dump.vcd");
        $dumpvars(100, snn_tb);

        #0
        rst = 1;
        for(integer i = 0; i < 16; i++) begin
            for(integer j = 0; j < 16; j++) begin
                weight[i][j] = 0;
            end
            network_input[i] = 0;
            mem_in[i] = 0;
            i_spk_in[i] = 0;
        end
        weight[0][2] = 64;
        weight[0][3] = -64;
        weight[1][2] = -64;
        weight[1][3] = 64;
        weight[2][4] = 64;
        weight[3][4] = 64;

        network_input[0] = 64;
        i_spk_in[0] = 1;

        #100
        i_spk_in[2] = 1;

        #300 $finish;
    end

    initial begin
        #0
        clk = 0;
        forever #5 clk = ~clk;
    end
endmodule