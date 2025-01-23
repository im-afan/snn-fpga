`include "snn/lif.sv"
//`include "lif.sv"

/* TODO UNTESTED */

module lif_array #(
    parameter integer CROSSBAR_NEURONS, 
    parameter integer THRESH,
    parameter integer NETWORK_WIDTH
) (
    input wire clk,
    input wire en,
    input wire rst,
    input wire has_in,

    input wire signed [NETWORK_WIDTH-1:0] network_input [CROSSBAR_NEURONS],
    input wire signed [NETWORK_WIDTH-1:0] mem_in [CROSSBAR_NEURONS],
    input wire signed [NETWORK_WIDTH-1:0] mac_out [CROSSBAR_NEURONS],

    output reg [CROSSBAR_NEURONS-1:0] spk_out,
    output reg signed [NETWORK_WIDTH-1:0] mem_out [CROSSBAR_NEURONS],

    output reg has_out
);

    wire [CROSSBAR_NEURONS-1:0] has_out_wire;
    wire [127:0] o_mem_out;
    generate
        genvar i;
        for(i = 0; i < CROSSBAR_NEURONS; i++) begin
            assign o_mem_out[i*8 +: 8] = mem_out[i];
            lif #(
                .THRESH(THRESH),
                .NETWORK_WIDTH(NETWORK_WIDTH)
            ) neuron (
                .clk(clk),
                .en(en),
                .rst(rst),
                .has_in(has_in),
                .mac_out(mac_out[i]),
                .mem_in(mem_in[i]),
                .network_input(network_input[i]),
                .spk_out(spk_out[i]),
                .mem_out(mem_out[i]),
                .has_out(has_out_wire[i])
            );
        end
    endgenerate

    assign has_out = &has_out_wire;

endmodule