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

    always @(posedge clk) begin
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

/*
`timescale 1ns / 1ps

module synapse#(
    parameter integer NETWORK_WIDTH
)(
    input wire clk,
    input wire enable,
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

    //assign spk_below = spk_in ? done : spk_above;
    //assign mac_out = spk_in ? sum_clamp : mac_in;
    reg no_spk_done;
    reg [NETWORK_WIDTH-1:0] no_spk_mac_out;
    reg yes_spk_done;
    reg [NETWORK_WIDTH-1:0] yes_spk_mac_out;
    assign no_spk_mac_out = mac_in;
    assign yes_spk_mac_out = sum_clamp;
    
    assign spk_below = no_spk_done || yes_spk_done;
    assign done = enable && spk_below;
    assign mac_out = spk_in ? yes_spk_mac_out : no_spk_mac_out;

    reg spk_delay = 0;

    always_latch begin
        if(enable && ~spk_in) begin
            no_spk_done = 1;
            //no_spk_mac_out = mac_in;
        end
    end

    always_ff @(posedge clk) begin
        if(~enable) begin
            //done <= 0;
            spk_delay <= 0;
		end else begin
            spk_delay <= spk_in;
            if(spk_above) yes_spk_done <= 1;
		end
    end
endmodule

*/