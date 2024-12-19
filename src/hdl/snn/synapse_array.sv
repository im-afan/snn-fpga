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
        end
    endgenerate

    wire [CROSSBAR_NEURONS-1:0] col_done;
    assign done = &col_done && enable;

    generate
        for(i=0; i<CROSSBAR_NEURONS; i++) begin // west to east
            wire signed [NETWORK_WIDTH-1:0] column [CROSSBAR_NEURONS];
            wire column_spike [CROSSBAR_NEURONS];
            assign column[0] = mac_in[i];
            assign column_spike[0] = 1;
            for(j=0; j<CROSSBAR_NEURONS; j++) begin // north to south
                if(j < CROSSBAR_NEURONS-1) begin
                    synapse #(.NETWORK_WIDTH(NETWORK_WIDTH)) syn(
                        .clk(clk),
                        .enable(enable),
                        //.done(synapse_done[j*CROSSBAR_NEURONS+i]),
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
                        //.done(synapse_done[j*CROSSBAR_NEURONS+i]),
                        .mac_in(column[j]),
                        .spk_above(column_spike[j]),
                        .spk_in(spk_in[j]),
                        .weight(weight[j][i]),
                        .mac_out(mac_out[i]),
                        .spk_below(col_done[i])
                    );
                end
            end
        end
    endgenerate
endmodule
