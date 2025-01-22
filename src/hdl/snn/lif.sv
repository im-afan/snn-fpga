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
    input wire rst, // want to reset spikes for next timestep? 
    input wire has_in,

    input wire signed [NETWORK_WIDTH-1:0] mac_out,
    input wire signed [NETWORK_WIDTH-1:0] mem_in,
    input wire signed [NETWORK_WIDTH-1:0] network_input,

    output reg spk_out,
    output reg signed [NETWORK_WIDTH-1:0] mem_out,

    output reg has_out
);
    
    reg signed [NETWORK_WIDTH-1:0] mem;
    reg signed [NETWORK_WIDTH-1:0] base_mem;
    wire signed [NETWORK_WIDTH-1:0] sum_clamp;
    wire signed [NETWORK_WIDTH-1:0] sum_clamp1;

    adder #(.WIDTH(NETWORK_WIDTH)) adder_0 (
        .in1(mem_in),
        .in2(network_input),
        .out(base_mem)
    );

    adder #(.WIDTH(NETWORK_WIDTH)) adder_1 (
        .in1(mem),
        .in2(mac_out),
        .out(sum_clamp)
    );

    adder #(.WIDTH(NETWORK_WIDTH)) adder_2 (
        .in1(base_mem),
        .in2(mac_out),
        .out(sum_clamp1)
    );

    always_ff @(posedge clk) begin
        if(rst) begin
            spk_out <= (mem >= THRESH);
            mem_out <= (mem >= THRESH) ? 0 : mem;
            if(has_in) begin
                mem <= sum_clamp1;
            end else begin
                mem <= base_mem;
            end
            has_out <= 1;
        end else begin
            if(has_in) begin
                mem <= sum_clamp;
            end
        end
    end
endmodule
