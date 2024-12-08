`timescale 1ns / 1ps

/**
 * SNN synapse
 * spk_in: spiking input, mac_in: multiply-accumulate input from above synapse
 * supports queuing spikes using a delay
 */

module synapse#(
    parameter integer MAX_DELAY = 8,
    parameter integer WIDTH = 32,
    parameter integer TICKS_BEFORE = 2,
    parameter integer ROW = -1,
    parameter integer COL = -1,
    parameter integer THRESH = 32
)(
    input wire clk,
    input wire enable,
    input wire debug,
    input wire signed [WIDTH-1:0] mac_in, // mac = vertical crossbars
    input wire spk_above,
    input wire spk_in, // spk = horizontal crossbars
    input wire signed [WIDTH-1:0] weight,
    output reg signed [WIDTH-1:0] mac_out,
    output reg spk_below,
    output reg done
);
    wire signed [WIDTH-1:0] sum;
    wire signed [WIDTH-1:0] sum_clamp;
    wire overflow;
    assign sum = weight+mac_in;
    assign overflow = (weight[WIDTH-1] == mac_in[WIDTH-1]) && (weight[WIDTH-1] != sum[WIDTH-1]);
    assign sum_clamp = overflow ? (weight[WIDTH-1] ? -THRESH : THRESH) : sum;

    always @(posedge clk or negedge enable) begin
        if(~enable) begin
            done <= 0;
			spk_below <= 0;
		end else begin
			if(spk_above) begin
				mac_out <= spk_in ? sum_clamp : mac_in;
			    done <= 1;
				spk_below <= 1;
			end
		end
    end
endmodule

