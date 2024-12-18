/* TODO TEST */

module xbar_scheduler (
	input wire clk,
	input wire en,

	input wire crossbar_done,

	input wire weight_fifo_empty,
	input wire spk_in_fifo_empty,
	input wire mac_out_fifo_full,

	input wire weight_fifo_pop_done,
	input wire spk_in_fifo_pop_done,
	input wire mac_out_fifo_push_done,

	output reg weight_fifo_pop,
	output reg spk_in_fifo_pop,
	output reg mac_out_fifo_push,

	output reg crossbar_en
);
	wire ready;
	wire pop_done;
	assign ready = ~(weight_fifo_empty || spk_in_fifo_empty) && ~mac_out_fifo_full;
	assign pop_done = (weight_fifo_pop_done && spk_in_fifo_pop_done && mac_out_fifo_push_done) 
					|| ~(weight_fifo_pop || spk_in_fifo_pop || mac_out_fifo_push);

	always_ff @(posedge clk) begin
		if(~en) begin
			crossbar_en <= 0;
			weight_fifo_pop <= 0;
			spk_in_fifo_pop <= 0;
			mac_out_fifo_push <= 0;
		end else begin
			if(ready && pop_done) begin
				if(~crossbar_done) begin
					crossbar_en <= 1;	
					weight_fifo_pop <= 0;
					spk_in_fifo_pop <= 0;
					mac_out_fifo_push <= 0;
				end else begin
					crossbar_en <= 0;
					weight_fifo_pop <= 1;
					spk_in_fifo_pop <= 1;
					mac_out_fifo_push <= 1;
				end
			end	else begin 
				crossbar_en <= 0;
			end
		end
	end
endmodule