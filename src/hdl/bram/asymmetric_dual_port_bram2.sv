module asymmetric_dual_port_bram #(
	parameter DATA_WIDTH_B,
	parameter ADDR_WIDTH_B,
	parameter DATA_WIDTH_A,
	parameter ADDR_WIDTH_A,
	parameter MEM_PATH
) (clka, clkb, ena, wea, enb, web, addra, addrb, dina, douta, dinb, doutb);
	
	localparam SIZEA = 256;

    localparam BASE_PATH = "C:/Users/andre/Desktop/snn-fpga/src/hdl/bram/mem/";

	input clka;
	input clkb;
	input [DATA_WIDTH_A/8-1:0] wea;
	input [DATA_WIDTH_B/8-1:0] web;
	input ena, enb;

	input [ADDR_WIDTH_A-1:0] addra;
	input [ADDR_WIDTH_B-1:0] addrb;
	input [DATA_WIDTH_A-1:0] dina;
	input [DATA_WIDTH_B-1:0] dinb;

	output reg [DATA_WIDTH_A-1:0] douta;
	output reg [DATA_WIDTH_B-1:0] doutb;

	localparam LOGA = $clog2(DATA_WIDTH_A / 8);
	localparam LOGB = $clog2(DATA_WIDTH_B / 8);

	localparam RATIO = DATA_WIDTH_A / DATA_WIDTH_B;
	localparam LOG_RATIO = $clog2(RATIO);

	(* ram_style = "block" *) reg [DATA_WIDTH_B-1:0] mem [0:SIZEA*RATIO-1];

	initial begin
		integer i;
		for(i = 0; i < SIZEA*RATIO; i++) begin
			mem[i] = 0;
		end
        $readmemb({BASE_PATH, MEM_PATH}, mem);
	end

	always @(posedge clkb)
	begin
		integer i;
		if (enb) begin
			doutb <= mem[addrb >> LOGB];
			for(i = 0; i < DATA_WIDTH_B / 8; i++) begin
				if (web[i])
					mem[addrb >> LOGB][i*8 +: 8] <= dinb[i*8 +: 8];
			end
		end
	end

	generate
		if(RATIO > 1) begin
			always @(posedge clka)
			begin 
				integer i, j;
				reg [LOG_RATIO-1:0] lsbaddr;
				if (ena) begin
					for (i=0; i< RATIO; i= i+ 1) begin
						lsbaddr = i;
						douta[(i+1)*DATA_WIDTH_B-1 -: DATA_WIDTH_B] <= mem[{addra >> LOGA, lsbaddr}];
						//for(j = i * (DATA_WIDTH_A / RATIO / 8); j < (i+1) * (DATA_WIDTH_A / RATIO / 8); j++) begin
						//	if (wea[(i*DATA_WIDTH_B/8) + j])
						//		mem[{addra >> LOGA, lsbaddr}][(j - i*(DATA_WIDTH_A / RATIO / 8))*8 +: 8] <= dina[(i*DATA_WIDTH_B) + (j*8) +: 8];
						//end
					end
				end
			end

		end else begin
			always @(posedge clka)
			begin
				integer i;
				if (ena) begin
					douta <= mem[addra >> LOGB];
					for(i = 0; i < DATA_WIDTH_B / 8; i++) begin
						if (wea[i])
							mem[addra >> LOGB][i*8 +: 8] <= dina[i*8 +: 8];
					end
				end
			end
		end
	endgenerate
endmodule
