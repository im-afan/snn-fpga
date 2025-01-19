`include "snn/adder_tree.sv"

module synapse_array_adder_tree #( // TODO streaming inputs
	parameter integer CROSSBAR_NEURONS,
	parameter integer NETWORK_WIDTH
) (
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

    reg adder_tree_en;
    reg adder_tree_push;
    reg adder_tree_has_in;
    wire [CROSSBAR_NEURONS-1:0] adder_tree_has_out;
    wire signed [NETWORK_WIDTH-1:0] adder_tree_out [CROSSBAR_NEURONS];

    generate
    	for(i = 0; i < CROSSBAR_NEURONS; i++) begin
    		wire signed [NETWORK_WIDTH-1:0] adder_tree_in [CROSSBAR_NEURONS];
    		adder_tree #(
    			.N(CROSSBAR_NEURONS),
    			.WIDTH(NETWORK_WIDTH)
    		) tree (
    			.clk(clk),
    			.en(adder_tree_en),
    			.push(adder_tree_push),
    			.has_in(adder_tree_has_in),
    			.in(adder_tree_in),
    			.out(adder_tree_out[i]),
    			.has_out(adder_tree_has_out[i])
    		);
    		assign mac_out[i] = adder_tree_out[i] + mac_in[i];
    		for(j = 0; j < CROSSBAR_NEURONS; j++) begin
    			assign adder_tree_in[j] = spk_in[j] ? weight[j][i] : 0;
    			wire [NETWORK_WIDTH-1:0] adder_tree_in_debug;
    			wire spk_in_debug;
    			wire [NETWORK_WIDTH-1:0] weight_debug;
    			assign adder_tree_in_debug = adder_tree_in[j];
    			assign spk_in_debug = spk_in[j];
    			assign weight_debug = weight[j][i];
    		end
    	end
    endgenerate

    always @(posedge clk) begin
    	if(~enable) begin
    		adder_tree_en <= 0;
    		adder_tree_push <= 0;
    		adder_tree_has_in <= 0;
    	end else begin
    		adder_tree_en <= 1;
    		adder_tree_push <= 1;	
    		adder_tree_has_in <= 1;
    	end
    end

    assign done = &adder_tree_has_out;
endmodule