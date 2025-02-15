`include "snn/synapse_array_adder_tree.sv"
`include "snn/lif_array.sv"

module snn
(
    input wire clk,
    input wire en,
	
	input wire push,
    input wire push_rst,

    input wire [2047:0] i_weight,
    input wire [127:0] i_network_input,
    input wire [127:0] i_mem_in,
    input wire [15:0] i_spk_in,
    input wire [15:0] i_tile_idx_y,
    input wire [15:0] i_tile_idx_y_ext,

    output wire [15:0] o_spk_out,
    output wire [127:0] o_mem_out,
    output wire [15:0] o_tile_idx_y,
    input wire [15:0] o_tile_idx_y_ext,
    output wire lif_has_out,
    output wire busy
);
    wire [127:0] lif_network_input;
    wire [127:0] lif_mem_in;

    reg signed [8-1:0] weight [16][16];
    reg signed [8-1:0] network_input [16];
    reg signed [8-1:0] mem_in [16];
    wire signed [8-1:0] mac_out [16];
    wire signed [8-1:0] mem_out [16];
    wire xbar_has_out;
    wire want_rst;

    assign network_input_dout = i_network_input;
    assign mem_in_dout = i_mem_in;
    assign busy = xbar_has_out || lif_has_out;

    generate
        genvar i, j;
        for(i = 0; i < 16; i++) begin
            assign network_input[i] = lif_network_input[i*8 +: 8];
            assign mem_in[i] = lif_mem_in[i*8 +: 8];
            assign o_mem_out[i*8 +: 8] = mem_out[i];

            wire [7:0] mem_out_debug;
            assign mem_out_debug = mem_out[i];

            for(j = 0; j < 16; j++) begin
                assign weight[i][j] = i_weight[(16*i+j)*8 +: 8];
            end
        end
    endgenerate

    synapse_array_adder_tree #(
        .CROSSBAR_NEURONS(16),
        .NETWORK_WIDTH(8)
    ) synapse_array (
        .clk(clk),
        .enable(en),
        .push_rst(push_rst),
        .push(push),
        .weight(weight),
        .spk_in(i_spk_in),
        .mac_out(mac_out),
        .has_out(xbar_has_out),
        .want_rst(want_rst)
    );

    lif_array # (
        .CROSSBAR_NEURONS(16),
        .THRESH(64),
        .NETWORK_WIDTH(8)
    ) lif_array_0 (
        .clk(clk),
        .en(en),
        .rst(want_rst),
        .has_in(xbar_has_out),
        .mac_out(mac_out),
        .mem_in(mem_in),
        .network_input(network_input),
        .spk_out(o_spk_out),
        .mem_out(mem_out),
        .has_out(lif_has_out)
    );

    fifo # (
        .WIDTH(16),
        .LENGTH(8),
        .INIT_DIFF(7)
    ) fifo_tile_idx (
        .clk(clk),
        .rst(~en),
        .din(i_tile_idx_y),
        .push(push),
        .pop(push),
        .dout(o_tile_idx_y),
        .empty(),
        .full()
    );

    fifo # (
        .WIDTH(16),
        .LENGTH(8),
        .INIT_DIFF(7)
    ) fifo_tile_idx_ext (
        .clk(clk),
        .rst(~en),
        .din(i_tile_idx_y_ext),
        .push(push),
        .pop(push),
        .dout(o_tile_idx_y_ext),
        .empty(),
        .full()
    );
    
    fifo # (
        .WIDTH(128),
        .LENGTH(8),
        .INIT_DIFF(6)
    ) fifo_network_input (
        .clk(clk),
        .rst(~en),
        .din(i_network_input),
        .push(push),
        .pop(push),
        .dout(lif_network_input),
        .empty(),
        .full()
    );

    fifo # (
        .WIDTH(128),
        .LENGTH(8),
        .INIT_DIFF(6)
    ) fifo_mem_in (
        .clk(clk),
        .rst(~en),
        .din(i_mem_in),
        .push(push),
        .pop(push),
        .dout(lif_mem_in),
        .empty(),
        .full()
    );
endmodule
