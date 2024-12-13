`include "lif.sv"

module lif_array #(
    parameter integer CROSSBAR_NEURONS, 
    parameter integer THRESH,
    parameter integer NETWORK_WIDTH
) (
    input wire clk,
    input wire enable,

    input wire [CROSSBAR_NEURONS] spk_in,
    input wire [NETWORK_WIDTH-1:0] mem_in [CROSSBAR_NEURONS],
    input wire [NETWORK_WIDTH-1:0] mac_in [CROSSBAR_NEURONS],

    output reg [CROSSBAR_NEURONS-1:0] spk_out,
    output reg [NETWORK_WIDTH-1:0] mem_out [CROSSBAR_NEURONS]
    output wire done;
);
    wire [CROSSBAR_NEURONS-1:0] lif_done;
    assign done = &lif_done;

    generate
        genvar i;
        for(i = 0; i < CROSSBAR_NEURONS; i++) begin
            lif #(
                .THRESH(THRESH),
                .NETWORK_WIDTH(NETWORK_WIDTH)
            ) neuron (
                .clk(clk),
                .enable(enable),
                .spk_in(spk_in[i]),
                .mac_in(mac_in[i]),
                .mem_in(mem_in[i]),
                .spk_out(spk_out[i]),
                .mem_out(mem_out[i]),
                .done(lif_done[i])
            );
        end
    endgenerate
endmodule