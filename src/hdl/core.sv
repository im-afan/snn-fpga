`timescale 1ns / 1ps
`include "synapse.sv"

/**
 * neuromorphic core 
 * consists of a synaptic crossbar
 * crossbar intersections consist of event-triggered MAC blocks representing synapses
 * crossbar west-east input is spiking input, north-south is spike accumulation for next integration step
 * based on TrueNorth architecture https://open-neuromorphic.org/blog/truenorth-deep-dive-ibm-neuromorphic-chip-design/
 */

module core#(
    parameter integer MAX_NEURONS = 8,
    parameter integer WIDTH = 32,
    parameter integer MAX_DELAY = 8,
    parameter integer THRESH = 32
)(
    input wire clk,
    input wire enable,
    input wire debug,
    input wire signed [WIDTH-1:0] weight [MAX_NEURONS][MAX_NEURONS],
    input wire [MAX_NEURONS-1:0] spk_in,
    input wire signed [WIDTH-1:0] mem_in [MAX_NEURONS],
    output reg signed [WIDTH-1:0] spk_buffer [MAX_NEURONS],
    output reg signed [WIDTH-1:0] mem_out [MAX_NEURONS],
    output reg done // timestep done
);
    
    reg [MAX_NEURONS*MAX_NEURONS-1:0] synapse_done;
    reg all_done = 0;

    generate
        genvar i;
        genvar j;
    
        for(i=0; i<MAX_NEURONS; i++) begin // west to east
            wire signed [WIDTH-1:0] column [MAX_NEURONS];
            wire column_spike [MAX_NEURONS];
            //assign column[0] = 0;
            assign column[0] = mem_in[i];
            assign column_spike[0] = 1;
            for(j=0; j<MAX_NEURONS; j++) begin // north to south
                if(j < MAX_NEURONS-1) begin
                    synapse #(.WIDTH(WIDTH), .ROW(j), .COL(i), .MAX_DELAY(MAX_DELAY), .THRESH(THRESH)) syn(
                        .clk(clk),
                        .enable(enable),
                        .debug(debug),
                        .done(synapse_done[j*MAX_NEURONS+i]),
                        .mac_in(column[j]),
                        .spk_above(column_spike[j]),
                        .spk_in(spk_in[j]),
                        .weight(weight[j][i]),
                        .mac_out(column[j+1]),
                        .spk_below(column_spike[j+1])
                    );
                end else begin
                    synapse  #(.WIDTH(WIDTH), .ROW(j), .COL(i), .MAX_DELAY(MAX_DELAY), .THRESH(THRESH)) syn(
                        .clk(clk),
                        .enable(enable),
                        .debug(debug),
                        .done(synapse_done[j*MAX_NEURONS+i]),
                        .mac_in(column[j]),
                        .spk_above(column_spike[j]),
                        .spk_in(spk_in[j]),
                        .weight(weight[j][i]),
                        //.mac_out(spk_buffer[i])
                        .mac_out(mem_out[i])
                    );
                end
            end
        end
    endgenerate

    always @(posedge clk or negedge enable) begin 
        if(~enable) begin
            done <= 0; 
        end else begin
            done <= &synapse_done;
        end
    end
endmodule
