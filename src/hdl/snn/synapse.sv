`timescale 1ns / 1ps

/**
 * SNN synapse
 * spk_in: spiking input, mac_in: multiply-accumulate input from above synapse
 * supports queuing spikes using a delay
 */

module synapse#(
    parameter integer NETWORK_WIDTH = 32
)(
    input wire clk,
    input wire enable,
    input wire debug,
    input wire signed [NETWORK_WIDTH-1:0] mac_in, // mac = vertical crossbars
    input wire spk_above,
    input wire spk_in, // spk = horizontal crossbars
    input wire signed [NETWORK_WIDTH-1:0] weight,
    output reg signed [NETWORK_WIDTH-1:0] mac_out,
    output reg spk_below,
    output reg done
);
    localparam INT_MAX = (1 << NETWORK_WIDTH) - 1;

    wire signed [NETWORK_WIDTH-1:0] sum;
    wire signed [NETWORK_WIDTH-1:0] sum_clamp;
    wire overflow;
    assign sum = weight+mac_in;
    assign overflow = (weight[NETWORK_WIDTH-1] == mac_in[NETWORK_WIDTH-1]) && (weight[NETWORK_WIDTH-1] != sum[NETWORK_WIDTH-1]);
    assign sum_clamp = overflow ? (weight[NETWORK_WIDTH-1] ? -INT_MAX : INT_MAX) : sum;

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

