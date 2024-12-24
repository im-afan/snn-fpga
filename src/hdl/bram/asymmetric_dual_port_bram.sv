`include "bram/dual_port_bram.sv"

module asymmetric_dual_port_bram #(
	parameter ADDR_WIDTH_A, 
    parameter DATA_WIDTH_A, 
    parameter ADDR_WIDTH_B,
    parameter DATA_WIDTH_B,
    parameter MEM_PATH
) (
	input wire clka,               // Clock for port A
    input wire ena,
    input wire [DATA_WIDTH_A/8-1:0] wea, // Write mask enable for port A (1 bit per byte)
    input wire [ADDR_WIDTH_A-1:0] addra,  // Byte address for port A
    input wire [DATA_WIDTH_A-1:0] dina,   // Data input for port A
    output reg [DATA_WIDTH_A-1:0] douta,  // Data output for port A

    input wire clkb,               // Clock for port B
    input wire enb,
    input wire [DATA_WIDTH_B/8-1:0] web, // Write mask enable for port B (1 bit per byte)
    input wire [ADDR_WIDTH_B-1:0] addrb,  // Byte address for port B
    input wire [DATA_WIDTH_B-1:0] dinb,   // Data input for port B
    output reg [DATA_WIDTH_B-1:0] doutb   // Data output for port B
);
    localparam BASE_PATH = "C:/Users/andre/Desktop/snn-fpga/src/hdl/bram/mem/";
    localparam MEM_SIZE = DATA_WIDTH_A * 256;

    wire [15:0] offset;
    wire [DATA_WIDTH_A/8-1:0] web_local;
    wire [ADDR_WIDTH_A-1:0] addrb_local;
    wire [DATA_WIDTH_A-1:0] dinb_local;
   	wire [DATA_WIDTH_A-1:0] doutb_local; 

   	assign offset = (addrb % (DATA_WIDTH_A / 8)) / (DATA_WIDTH_B / 8) * (DATA_WIDTH_B / 8);
   	assign web_local = web << offset;
   	assign dinb_local = dinb << (offset*8);
   	//assign addrb_local = addrb / (DATA_WIDTH_A / DATA_WIDTH_B);
   	assign addrb_local = addrb;
   	assign doutb = doutb_local >> (offset*8);
   	/*
   	assign web_local = web;
   	assign addrb_local = addrb;
   	assign dinb_local = dinb;
   	assign dout = doutb_local;*/

	dual_port_bram #(
    	.ADDR_WIDTH_A(ADDR_WIDTH_A),
    	.ADDR_WIDTH_B(ADDR_WIDTH_A),
    	.DATA_WIDTH_A(DATA_WIDTH_A),
    	.DATA_WIDTH_B(DATA_WIDTH_A),
    	.MEM_PATH(MEM_PATH)
    ) mem (
    	.clka(clka),
    	.ena(ena),
    	.wea(wea),
    	.addra(addra),
    	.dina(dina),
    	.douta(douta),

    	.clkb(clkb),
    	.enb(enb),
    	.web(web_local),
    	.addrb(addrb_local),
    	.dinb(dinb_local),
    	.doutb(doutb_local)
    );
    /*xpm_memory_tdpram #(
    	.ADDR_WIDTH_A(ADDR_WIDTH_A),
    	.ADDR_WIDTH_B(ADDR_WIDTH_A),
    	.BYTE_WRITE_WIDTH_A(8),
    	.BYTE_WRITE_WIDTH_B(8),
    	.MEMORY_INIT_FILE({BASE_PATH, MEM_PATH}),
    	.MEMORY_SIZE(MEM_SIZE),
    	.READ_DATA_WIDTH_A(DATA_WIDTH_A),
    	.READ_DATA_WIDTH_B(DATA_WIDTH_A),
    	.WRITE_DATA_WIDTH_A(DATA_WIDTH_A),
    	.WRITE_DATA_WIDTH_B(DATA_WIDTH_A)
    ) mem (
    	.clka(clka),
    	.ena(ena),
    	.wea(wea),
    	.addra(addra),
    	.dina(dina),
    	.douta(douta),

    	.clkb(clkb),
    	.enb(enb),
    	.web(web_local),
    	.addrb(addrb_local),
    	.dinb(dinb_local),
    	.doutb(doutb_local)
    );*/
endmodule