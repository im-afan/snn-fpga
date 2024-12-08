`timescale 1ns / 1ps

/** 
 * leaky-integrate fire neuron
 * supports only 0.5 or no leak using bitshift
 * to prevent using division
 */

module lif#(
    parameter integer THRESH = 32,
    parameter integer RESET_VAL = 0,
    parameter integer UPDATE_FREQ = 1,
    parameter integer SPK_CURRENT = 1,
    parameter integer WIDTH = 32
)(
    input wire clk,
    input wire enable,
    input wire signed [WIDTH-1:0] spk_in,
    input wire signed [WIDTH-1:0] network_input,
    input wire leak,
    input wire rst,
    input wire signed [WIDTH-1:0] mem_in,
    output reg spk_out,
    output reg done,
    output reg signed [WIDTH-1:0] mem_out
);
    //reg signed [WIDTH-1:0] mem = 0;
    reg local_done = 0;
    wire signed [WIDTH-1:0] sum;
    wire signed [WIDTH-1:0] sum_clamp;
    wire overflow;
    assign sum = mem_in+network_input;
    assign overflow = (mem_in[WIDTH-1] == network_input[WIDTH-1]) && (mem_in[WIDTH-1] != sum[WIDTH-1]);
    assign sum_clamp = overflow ? (mem_in[WIDTH-1] ? -THRESH : THRESH) : sum;

    always @(posedge clk or negedge enable) begin
        if(~enable) begin
            done <= 0;
            local_done <= 0;
        end else begin
            /*if(rst) begin
                mem <= RESET_VAL;
                spk_out <= 0;
            end*/

            if(~local_done) begin
				//$display("mem = %d, spk_in = %d", mem, spk_in);
                //if(mem_in + spk_in >= THRESH) begin
                if(sum_clamp >= THRESH) begin
                    spk_out <= SPK_CURRENT;
                    mem_out <= RESET_VAL;
                end else begin
                    spk_out <= 0;
                    //mem_out <= (sum_clamp >>> 1); // todo, no leak in bram yet
                    mem_out <= sum_clamp;
                end

                local_done <= 1;
            end else begin
                done <= 1; 
            end
        end
    end
endmodule
