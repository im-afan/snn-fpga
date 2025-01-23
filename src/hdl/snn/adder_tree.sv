`include "snn/adder.sv"

module adder_tree #( // can be treated as mac_out_fifo
	parameter integer N,
	parameter integer WIDTH
) (
	input wire clk,
	input wire push,
	input wire en,
	input wire has_in,
	input wire signed [WIDTH-1:0] in [N],
	output reg signed [WIDTH-1:0] out,
	output reg has_out 
);

	reg cnt = 0;
	reg [WIDTH-1:0] tree[2*N+1];
	reg [$clog2(N):0] mask;

	always @(posedge clk) begin
		if(~en) begin
			mask <= 0;	
		end else begin 
			if(push) mask <= (mask << 1) | (has_in);
		end
	end

	generate
		genvar i;
		for(i = 0; i < N; i++) begin
			always @(posedge clk) begin
				if(~en) begin
					tree[N+i] <= 0;
				end else begin
					if(push) begin
						if(has_in) begin
							cnt <= 0;
							tree[N+i] <= in[i];
						end
					end
				end
			end
		end
		for(i = 1; i < N; i++) begin
			wire [WIDTH-1:0] add_out;
			adder #(.WIDTH(WIDTH)) add (
				.in1(tree[i*2]),
				.in2(tree[i*2+1]),
				.out(add_out)
			);
			always @(posedge clk) begin
				if(~en) begin
					//tree[i] = 0;
				end
				else begin
					if(push) begin
						tree[i] <= add_out;
						cnt <= cnt-1;
					end
				end
			end	
		end

		for(i = 0; i < 2*N; i++) begin
			wire [WIDTH-1:0] tree_debug;
			assign tree_debug = tree[i];
		end
	endgenerate	

	assign has_out = mask[$clog2(N)];
	assign out = tree[1];
endmodule
