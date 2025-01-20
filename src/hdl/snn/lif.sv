`timescale 1ns / 1ps

/** 
 * leaky-integrate fire neuron
 * supports only 0.5 or no leak using bitshift
 * to prevent using division
 */

module lif#(
    parameter integer THRESH,
    parameter integer NETWORK_WIDTH
)(
    input wire clk,
    input wire enable,

    input wire spk_rst, // want to reset spikes for next timestep? 
    input wire spk_in, // inhibit multiple spks in 1 timestep
    input wire signed [NETWORK_WIDTH-1:0] mac_out,
    input wire signed [NETWORK_WIDTH-1:0] mem_in,

    output reg spk_out,
    output reg done,
    output reg signed [NETWORK_WIDTH-1:0] mem_out
);
    /*localparam INT_MAX = (1 << NETWORK_WIDTH) - 1;

    reg local_done = 0;
    wire signed [NETWORK_WIDTH-1:0] sum;
    wire signed [NETWORK_WIDTH-1:0] sum_clamp;
    wire overflow;
    assign sum = mem_in+mac_out;
    assign overflow = (mem_in[NETWORK_WIDTH-1] == mac_out[NETWORK_WIDTH-1]) && (mem_in[NETWORK_WIDTH-1] != sum[NETWORK_WIDTH-1]);
    assign sum_clamp = overflow ? (mem_in[NETWORK_WIDTH-1] ? -INT_MAX : INT_MAX) : sum;*/
    reg local_done = 0;
    wire signed [NETWORK_WIDTH-1:0] sum_clamp;
    adder #(.WIDTH(NETWORK_WIDTH)) adder_0 (
        .in1(mac_out),
        .in2(mem_in),
        .out(sum_clamp)
    );

    always_ff @(posedge clk) begin
        if(~enable) begin
            done <= 0;
            local_done <= 0;
        end else begin
            if(~local_done) begin
                if(spk_rst && spk_in) begin
                    mem_out <= mac_out;
                    spk_out <= (mac_out >= THRESH);
                end else begin
                    if(sum_clamp >= THRESH) begin
                        spk_out <= 1;
                    end else begin
                        spk_out <= 0;
                    end
                    mem_out <= sum_clamp;
                end
                local_done <= 1;
            end else begin
                done <= 1; 
            end
        end
    end
endmodule
