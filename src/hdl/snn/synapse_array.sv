`timescale 1ns / 1ps
`include "synapse.sv"

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

    input wire signed [NETWORK_WIDTH-1:0] weight [CROSSBAR_NEURONS][CROSSBAR_NEURONS],
    input wire [CROSSBAR_NEURONS-1:0] spk_in,
    output reg signed [NETWORK_WIDTH-1:0] mac_out [CROSSBAR_NEURONS],
    output reg done
);
    
    reg [CROSSBAR_NEURONS*CROSSBAR_NEURONS-1:0] synapse_done;
    assign done = &synapse_done && enable;

    generate
        genvar i;
        genvar j;
    
        for(i=0; i<CROSSBAR_NEURONS; i++) begin // west to east
            wire signed [NETWORK_WIDTH-1:0] column [CROSSBAR_NEURONS];
            wire column_spike [CROSSBAR_NEURONS];
            assign column[0] = 0;
            assign column_spike[0] = 1;
            for(j=0; j<CROSSBAR_NEURONS; j++) begin // north to south
                if(j < CROSSBAR_NEURONS-1) begin
                    synapse #(.NETWORK_WIDTH(NETWORK_WIDTH)) syn(
                        .clk(clk),
                        .enable(enable),
                        .debug(debug),
                        .done(synapse_done[j*CROSSBAR_NEURONS+i]),
                        .mac_in(column[j]),
                        .spk_above(column_spike[j]),
                        .spk_in(spk_in[j]),
                        .weight(weight[j][i]),
                        .mac_out(column[j+1]),
                        .spk_below(column_spike[j+1])
                    );
                end else begin
                    synapse  #(.NETWORK_WIDTH(NETWORK_WIDTH)) syn(
                        .clk(clk),
                        .enable(enable),
                        .debug(debug),
                        .done(synapse_done[j*CROSSBAR_NEURONS+i]),
                        .mac_in(column[j]),
                        .spk_above(column_spike[j]),
                        .spk_in(spk_in[j]),
                        .weight(weight[j][i]),
                        .mac_out(mac_out[i])
                    );
                end
            end
        end
    endgenerate
endmodule
