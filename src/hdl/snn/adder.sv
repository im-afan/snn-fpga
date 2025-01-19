module adder #(
	parameter integer WIDTH
)(
	input wire signed [WIDTH-1:0] in1,
	input wire signed [WIDTH-1:0] in2,
	output reg signed [WIDTH-1:0] out
);
	localparam INT_MAX = (1 << (WIDTH-1)) - 1;
	wire [WIDTH-1:0] sum, sum_clamp;
	wire overflow;
	assign sum = in1 + in2;
    assign overflow = (in1[WIDTH-1] == in2[WIDTH-1]) && (in1[WIDTH-1] != sum[WIDTH-1]);
    assign sum_clamp = overflow ? (in1[WIDTH-1] ? -INT_MAX : INT_MAX) : sum;

    assign out = sum_clamp;
endmodule