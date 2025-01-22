`include "snn/synapse_array_adder_tree.sv"
`include "snn/lif_array.sv"

module snn
(
    input wire clk,

    input wire push_rst,
    input wire [2047:0] i_weight,
    input wire [127:0] i_network_input,
    input wire [127:0] i_mem_in,
    input wire [15:0] i_spk_in,

    output wire [15:0] o_spk_out,
    output wire [127:0] o_mem_out,

    output wire lif_has_out
);
    reg signed [8-1:0] weight [16][16];
    reg signed [8-1:0] network_input [16];
    reg signed [8-1:0] mem_in [16];
    wire signed [8-1:0] mac_out [16];
    reg signed [8-1:0] mem_out [16];
    wire xbar_has_out;
    wire want_rst;

    generate
        genvar i, j;
        for(i = 0; i < 16; i++) begin
            assign network_input[i] = i_network_input[i*8 +: 8];
            assign mem_in[i] = i_mem_in[i*8 +: 8];
            assign o_mem_out[i*8 +: 8] = mem_out[i];
            for(j = 0; j < 16; j++) begin
                assign weight[i][j] = i_weight[(16*i+j)*8 +: 8];
            end
        end
    endgenerate

    synapse_array_adder_tree #(
        .CROSSBAR_NEURONS(16),
        .NETWORK_WIDTH(8)
    ) synapse_array (
        .clk(clk),
        .enable(1),
        .push_rst(push_rst),
        .weight(weight),
        .spk_in(i_spk_in),
        .mac_out(mac_out),
        .has_out(xbar_has_out),
        .want_rst(want_rst)
    );

    lif_array # (
        .CROSSBAR_NEURONS(16),
        .THRESH(64),
        .NETWORK_WIDTH(8)
    ) lif_array_0 (
        .clk(clk),
        .rst(want_rst),
        .has_in(xbar_has_out),
        .mac_out(mac_out),
        .mem_in(mem_in),
        .network_input(network_input),
        .spk_out(o_spk_out),
        .mem_out(mem_out),
        .has_out(lif_has_out)
    );
endmodule