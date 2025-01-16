`timescale 1ns / 10ps

`include "bram/asymmetric_dual_port_bram.sv"

module asymmetric_bram_tb;

    localparam WEIGHT_BRAM_DATA_WIDTH = 32;
    localparam BRAM_ADDR_WIDTH = 16;
    localparam CPU_BRAM_DATA_WIDTH = 32;

    reg clk;

    reg [BRAM_ADDR_WIDTH-1:0] cpu_weight_addr;
    reg [CPU_BRAM_DATA_WIDTH-1:0] cpu_weight_din;
    wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_weight_dout;
    reg [CPU_BRAM_DATA_WIDTH/8-1:0] cpu_weight_we;
    reg cpu_weight_en;

    reg [BRAM_ADDR_WIDTH-1:0]  addr_weight;
    wire [WEIGHT_BRAM_DATA_WIDTH-1:0] dout_weight;
    reg [WEIGHT_BRAM_DATA_WIDTH-1:0] din_weight;
    reg bram_en_weight;
    reg bram_rst_weight;
    reg [WEIGHT_BRAM_DATA_WIDTH/8-1:0] bram_we_weight;

	asymmetric_dual_port_bram #(
        .DATA_WIDTH_A(WEIGHT_BRAM_DATA_WIDTH),
        .ADDR_WIDTH_A(BRAM_ADDR_WIDTH),
        .DATA_WIDTH_B(CPU_BRAM_DATA_WIDTH),
        .ADDR_WIDTH_B(BRAM_ADDR_WIDTH),
        .MEM_PATH("asdfasdf")
    ) bram2 (
        .clka(clk),
        .addra(addr_weight),
        .douta(dout_weight),
        .dina(din_weight),
        .wea(bram_we_weight),
        .ena(bram_en_weight),

        .clkb(clk),
        .addrb(cpu_weight_addr),
        .doutb(cpu_weight_dout),
        .dinb(cpu_weight_din),
        .web(cpu_weight_we),
        .enb(cpu_weight_en)
    );

    initial begin
    	forever #5 clk = ~clk;
    end

    initial begin
    	$dumpfile(".wave/top_dump.vcd");
        $dumpvars(100, asymmetric_bram_tb);

   		#0
   		clk = 0; 	
   		bram_en_weight = 0;
   		cpu_weight_en = 0;

   		#10000
   		cpu_weight_en = 1;
   		cpu_weight_addr = 180;
   		cpu_weight_din = 77;
   		cpu_weight_we = 16'b1111111111111111;

   		#100000 
        $writememb(".wave/weight_bram_dump.mem", bram2.mem.mem);
   		$finish;
    end
endmodule