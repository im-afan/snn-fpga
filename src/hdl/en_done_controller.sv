module en_done_controller(
	input wire clk,
	input wire snn_en_tri_o,
	input wire snn_done,
	output reg snn_en,
	output reg snn_ready
);
	initial snn_en = 0;

	always @(*) begin
		if(snn_en_tri_o) snn_en = 1;
		if(~snn_en_tri_o && snn_done) snn_en = 0;
	end

	always @(posedge clk) begin
		if(~snn_en) begin
			snn_ready <= 1;
		end else begin
			snn_ready <= 0;
		end
	end
endmodule