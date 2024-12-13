`timescale 1ns / 1ps;
`include "mem_in_fifo.sv"

module fifo_tb;
	localparam integer CROSSBAR_NEURONS = 16;
	localparam integer BRAM_DATA_WIDTH = 1024;
	localparam integer NETWORK_WIDTH = 8;
	localparam integer LENGTH = 2;

	reg clk = 0;
	reg [CROSSBAR_NEURONS*NETWORK_WIDTH-1:0] din = 0;
	reg push = 0;
	reg pop = 0;

	wire [NETWORK_WIDTH-1:0] mem_in [CROSSBAR_NEURONS];
	wire full;
	wire empty;

	wire push_done;
	wire pop_done;


	mem_in_fifo #(
		.CROSSBAR_NEURONS(CROSSBAR_NEURONS),
		.BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
		.NETWORK_WIDTH(NETWORK_WIDTH),
		.LENGTH(LENGTH)
	) fifo (
		.clk(clk),
		.din(din),
		.push(push),
		.pop(pop),
		.mem_in(mem_in),
		.full(full),
		.empty(empty),
		.push_done(push_done),
		.pop_done(pop_done)
	);
	initial begin
		forever begin
			#5 clk = ~clk;
		end	
	end

	initial begin
		$dumpfile("fifo_tb.vcd");
		$dumpvars(100, fifo_tb);
		#100 din <= 5;
		#200 push <= 1;
		#300 push <= 0;
		#400 push <= 1;
		#500 push <= 0;
		#600 pop <= 1;
		#700 pop <= 0;
		#800 pop <= 1;
		#900 pop <= 0;
		#1000 $finish;
	end
endmodule