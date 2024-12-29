`include "snn/synapse.sv"
//`include "synapse.sv"

/**
 * neuromorphic core 
 * consists of a synaptic crossbar
 * crossbar intersections consist of event-triggered MAC blocks representing synapses
 * crossbar west-east input is spiking input, north-south is spike accumulation for next integration step
 * based on TrueNorth architecture https://open-neuromorphic.org/blog/truenorth-deep-dive-ibm-neuromorphic-chip-design/
 */

module synapse_array#(
    parameter integer CROSSBAR_NEURONS,
    parameter integer NETWORK_WIDTH
)(
    input wire clk,
    input wire enable,

    input wire [NETWORK_WIDTH-1:0] u_mac_in [CROSSBAR_NEURONS],
    input wire [NETWORK_WIDTH-1:0] u_weight [CROSSBAR_NEURONS][CROSSBAR_NEURONS],
    input wire [CROSSBAR_NEURONS-1:0] spk_in,
    //output reg [NETWORK_WIDTH-1:0] u_mac_out [CROSSBAR_NEURONS],
    output reg [CROSSBAR_NEURONS*NETWORK_WIDTH-1:0] u_mac_out,
    output reg done
);

    wire signed [NETWORK_WIDTH-1:0] weight[CROSSBAR_NEURONS][CROSSBAR_NEURONS];
    wire signed [NETWORK_WIDTH-1:0] mac_out[CROSSBAR_NEURONS];
    wire signed [NETWORK_WIDTH-1:0] mac_in[CROSSBAR_NEURONS];

    generate
        genvar i, j;
        for(i = 0; i < CROSSBAR_NEURONS; i++) begin
            for(j = 0; j < CROSSBAR_NEURONS; j++) begin
                assign weight[i][j] = u_weight[i][j];
            end
            assign u_mac_out[NETWORK_WIDTH*(i+1)-1 : NETWORK_WIDTH*i] = mac_out[i];
            assign mac_in[i] = u_mac_in[i];
            //wire [NETWORK_WIDTH-1:0] mac_in_debug;
            //assign mac_in_debug = mac_in[i];
        end
    endgenerate

    generate
    		
    endgenerate
endmodule
