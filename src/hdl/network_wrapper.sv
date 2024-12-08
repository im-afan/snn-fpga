`timescale 1ns / 1ps
`include "core.sv"
`include "lif.sv"
`include "network_bram_wrapper.sv"

/**
 * network wrapper 
 * takes in a neural network with weight and delay as well as inputs
 * and runs the neural network using the neuromorphic core by tiling the weight matrix 
 * supports integer weights only
 */

module network_wrapper#(
    parameter integer MAX_NEURONS = 32,
    parameter integer WIDTH = 8,
    parameter integer MAX_DELAY = 8,
    parameter integer N = 32,
    parameter integer NEURONS_PER_CORE = 8,
    parameter integer BRAM_ADDR_WIDTH = 10,
    parameter integer BRAM_DATA_WIDTH = 32,
    parameter integer BYTES_PER_WIDTH = 4,
    parameter integer MAX_TILES = 64,
    parameter integer THRESH = 32
)(
    input wire clk,
    input wire enable,
    //input wire signed [WIDTH-1:0] network_input [MAX_NEURONS],
    //input wire signed [WIDTH-1:0] weight_bram [MAX_NEURONS][MAX_NEURONS],
    //input wire signed [WIDTH-1:0] delay_bram [MAX_NEURONS][MAX_NEURONS],
    //input wire [MAX_NEURONS-1:0] leak,
    //output wire [MAX_NEURONS-1:0] led_out,

    output wire bram_clk,
   	output wire [BRAM_ADDR_WIDTH-1:0] bram_addr,
   	input wire [BRAM_DATA_WIDTH-1:0] bram_dout,
   	output wire [BRAM_DATA_WIDTH-1:0] bram_din,
   	output wire bram_en,
   	output wire bram_rst,
   	output wire [BYTES_PER_WIDTH-1:0] bram_we
);
	assign bram_clk = clk;

	// cycle steps
	localparam integer LIF_STEP_READ_INPUT = 8;
	localparam integer LIF_STEP_READ_INPUT_WAIT = 10;
	localparam integer LIF_STEP_WRITE_OUTPUT = 9;
	localparam integer LIF_STEP_WRITE_OUTPUT_WAIT = 11;
	localparam integer LIF_STEP_INTEGRATE = 0;
	localparam integer LIF_STEP_EN = 1;
	localparam integer LIF_STEP_WAIT = 2;
	localparam integer CORE_STEP_WAIT = 3;
	localparam integer CORE_STEP_WRITE_PARAMS = 4;
	localparam integer CORE_STEP_WRITE_PARAMS_WAIT = 5;
	localparam integer CORE_STEP_WRITE_OUTPUTS = 6;
	localparam integer CORE_STEP_WRITE_OUTPUTS_WAIT = 7;

    localparam integer CORE_READ_PARAMS = 0;
    localparam integer CORE_WRITE_PARAMS = 1;
    localparam integer LIF_READ_INPUT = 2;
    localparam integer LIF_WRITE_SPIKES = 3;

    //localparam integer TOTAL_CORES = 

    // crossbar
	wire signed [WIDTH-1:0] weight [NEURONS_PER_CORE][NEURONS_PER_CORE];
    wire signed [WIDTH-1:0] delay [NEURONS_PER_CORE][NEURONS_PER_CORE];
    wire signed [WIDTH-1:0] spk_buffer [NEURONS_PER_CORE];
    wire [NEURONS_PER_CORE-1:0] spk_in_core;
    wire signed [WIDTH-1:0] mem_in_core [NEURONS_PER_CORE];
    wire signed [WIDTH-1:0] mem_out_core [NEURONS_PER_CORE];

    //lif manager
	wire [NEURONS_PER_CORE-1:0] leak;
    reg signed [WIDTH-1:0] spk_in [NEURONS_PER_CORE]; // input to lif, =spk_buffer + network_input
    reg [NEURONS_PER_CORE-1:0] lif_done;
    reg all_lif_done;
    wire signed [WIDTH-1:0] network_input [NEURONS_PER_CORE];
    wire [NEURONS_PER_CORE-1:0] spk_out;
    reg signed [WIDTH-1:0] mem_in [NEURONS_PER_CORE];
    wire signed [WIDTH-1:0] mem_out [NEURONS_PER_CORE];

    //assign led_out = spk_out;

    // cycle manager
    localparam integer LOG_NEURONS_PER_CORE = $clog2(NEURONS_PER_CORE);
    reg enable_core = 1;
    reg core_done;
    reg signed [BRAM_DATA_WIDTH-1:0] lif_tile_idx = 0;
    reg signed [BRAM_DATA_WIDTH-1:0] core_idx = 0;
    wire signed [BRAM_DATA_WIDTH-1:0] core_idx_x;
    wire signed [BRAM_DATA_WIDTH-1:0] core_idx_y;
    reg want_lif_step = 0;
    reg [WIDTH-1:0] cur_step = LIF_STEP_READ_INPUT;
	reg debug = 0;
	wire snn_en;
	wire snn_rst;

   // global memory 
    //reg [MAX_DELAY-1:0] queued_spikes_bram [MAX_NEURONS][MAX_NEURONS];
	reg [4:0] bram_mode = 0;
	reg bram_wrapper_enable = 0;
	wire bram_done;
	reg signed [WIDTH-1:0] bram_mem_in [NEURONS_PER_CORE];
	reg signed [WIDTH-1:0] bram_mem_out [NEURONS_PER_CORE];

	assign mem_in_core = bram_mem_out;
	assign mem_in = bram_mem_out;

	network_bram_wrapper #(
		.NEURONS_PER_CORE(NEURONS_PER_CORE),
		.MAX_NEURONS(MAX_NEURONS),
		.MAX_DELAY(MAX_DELAY),
		.BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
		.BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
		.BYTES_PER_WIDTH(BYTES_PER_WIDTH),
		.MAX_TILES(MAX_TILES)
	) bram (
		.clk(bram_clk),
		.enable(bram_wrapper_enable),
		.mode(bram_mode),
		.addr(bram_addr),
		.data_out(bram_dout),
		.data_in(bram_din),
		.bram_en(bram_en),
		//.bram_rst(),
		.bram_we(bram_we),

		.lif_tile_idx(lif_tile_idx),
		.mem_in(bram_mem_in),
		.mem_out(bram_mem_out),
		.core_idx(core_idx),
		.core_idx_x(core_idx_x),
		.core_idx_y(core_idx_y),
		.spk_out(spk_out),
		.weight(weight),
		.network_input(network_input),
		.leak(leak),
		.snn_en(snn_en),
		.snn_rst(snn_rst),
		.spk_in_core(spk_in_core),

		.done(bram_done)
	);

	core #(
		.WIDTH(WIDTH),
		.MAX_NEURONS(NEURONS_PER_CORE),
		.MAX_DELAY  (MAX_DELAY),
		.THRESH(THRESH)
	) net (
		.clk(clk),
		.enable(enable_core),
		.debug(debug),
		.weight(weight), 
		//.spk_in(spk_in_core),
		.spk_in(spk_in_core),
		.mem_in(mem_in_core),

		//.spk_buffer(spk_buffer),
		.mem_out(mem_out_core),
		.done(core_done)
	);

    integer i;
    integer j;
    integer x;
    integer y;
    integer p;
    integer q;

	generate 
		genvar k;
		for(k = 0; k < NEURONS_PER_CORE; k++) begin
			lif #(
				.WIDTH(WIDTH),
				.THRESH(THRESH)
			) neuron (
				.clk(clk),
				.enable(want_lif_step),
				//.tick(),
				.mem_in(mem_in[k]),
				.rst(snn_rst),
				.spk_in(spk_in[k]),
				.network_input(network_input[k]),
				.leak(leak[k]),

				.spk_out(spk_out[k]),
				.done(lif_done[k]),
				.mem_out(mem_out[k])
			);
		end
	endgenerate

	initial begin
		for(integer i = 0; i < NEURONS_PER_CORE; i++) begin
			//for(integer j = 0; j < MAX_NEURONS; j++) begin
			//	queued_spikes_bram[i][j] <= 0;
			//end
			spk_in[i] = 0;
		end
	end

	always @(posedge clk) begin
		//$display("cur_sstep %d", cur_step);
		//$display("network-wrapper %d", bram_en);
		if(~enable) begin
		
		end else begin
			if(cur_step == LIF_STEP_READ_INPUT) begin // read network_input from ram
				bram_wrapper_enable <= 1;
				enable_core <= 0;
				bram_mode <= LIF_READ_INPUT;
				cur_step <= LIF_STEP_READ_INPUT_WAIT;

			end else if(cur_step == LIF_STEP_READ_INPUT_WAIT) begin
				if(bram_done) begin
					bram_wrapper_enable <= 0;
					cur_step <= LIF_STEP_INTEGRATE;
					/*for(i = 0; i < NEURONS_PER_CORE; i++) begin
						//$display("network_input[%d] = %d", i, network_input[i]);
						mem_in[i] <= bram_mem_out[i] + network_input[i];
					end*/
				end

			end else if(cur_step == LIF_STEP_INTEGRATE) begin // LIF integration step - integrate all input current
				enable_core <= 0;
				if(snn_en) begin	
					cur_step <= LIF_STEP_EN;
				end else begin
					cur_step <= LIF_STEP_READ_INPUT;
				end
			
			end else if(cur_step == LIF_STEP_EN) begin // enable LIF - wait for spikes to arive
				want_lif_step <= 1;
				cur_step <= LIF_STEP_WAIT;
			
			end else if(cur_step == LIF_STEP_WAIT) begin // wait for all LIF calculations to finish
				if(&lif_done) begin
					want_lif_step <= 0;
					core_idx <= 0;
					cur_step <= LIF_STEP_WRITE_OUTPUT;
					for(i = 0; i < NEURONS_PER_CORE; i++) begin
						bram_mem_in[i] <= mem_out[i];
					end
					/*$write("time: %t: ", $time);
					for(i = 0; i < MAX_NEURONS; i++) begin
						$write("%0d ", spk_out[i]);
						spk_in[i] <= 0;
					end
					$display("");*/
				end

			end else if(cur_step == LIF_STEP_WRITE_OUTPUT) begin
				bram_wrapper_enable <= 1;
				bram_mode <= LIF_WRITE_SPIKES;	
				cur_step <= LIF_STEP_WRITE_OUTPUT_WAIT;
			
			end else if(cur_step == LIF_STEP_WRITE_OUTPUT_WAIT) begin
				if(bram_done) begin
					bram_wrapper_enable <= 0;
					if(lif_tile_idx+1 >= MAX_NEURONS / NEURONS_PER_CORE) begin
						lif_tile_idx <= 0;
						cur_step <= CORE_STEP_WRITE_PARAMS;
					end else begin
						lif_tile_idx <= lif_tile_idx+1;
						cur_step <= LIF_STEP_READ_INPUT;	
					end
				end




			end else if(cur_step == CORE_STEP_WRITE_PARAMS) begin //setup next core operation using BRAM
				enable_core <= 0;	
				want_lif_step <= 0;
				if(core_idx >= MAX_TILES) begin// already finished tiles  
					lif_tile_idx <= 0;
					cur_step <= LIF_STEP_READ_INPUT;
				end else begin // keep doing tiles
					bram_mode <= CORE_READ_PARAMS;
					bram_wrapper_enable <= 1;
					cur_step <= CORE_STEP_WRITE_PARAMS_WAIT;
				end

			end else if(cur_step == CORE_STEP_WRITE_PARAMS_WAIT) begin
				want_lif_step <= 0;
				if(bram_done) begin
					bram_wrapper_enable <= 0;
					cur_step <= CORE_STEP_WAIT;
				end

			end else if(cur_step == CORE_STEP_WAIT) begin
				want_lif_step <= 0;
				if(~core_done) begin
					enable_core <= 1;
				end else begin
					enable_core <= 0;
					cur_step <= CORE_STEP_WRITE_OUTPUTS;
				end

			end else if(cur_step == CORE_STEP_WRITE_OUTPUTS) begin
				want_lif_step <= 0;
				for(q = 0; q < NEURONS_PER_CORE; q++) begin
					bram_mem_in[q] <= mem_out_core[q];
				end
				lif_tile_idx <= core_idx_y;
				bram_mode <= CORE_WRITE_PARAMS;
				bram_wrapper_enable <= 1;
				cur_step <= CORE_STEP_WRITE_OUTPUTS_WAIT;

			end else if(cur_step == CORE_STEP_WRITE_OUTPUTS_WAIT) begin
				if(bram_done) begin
					bram_wrapper_enable <= 0;
					cur_step <= CORE_STEP_WRITE_PARAMS;
					core_idx <= core_idx + 1;
				end
			end
		end
	end	
endmodule
