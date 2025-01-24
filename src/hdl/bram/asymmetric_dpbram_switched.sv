`include "bram/single_port_bram.sv"

module asymmetric_dpbram_switched #(
    parameter integer ADDR_WIDTH_A,
    parameter integer DATA_WIDTH_A,
    parameter integer ADDR_WIDTH_B,
    parameter integer DATA_WIDTH_B,
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
    localparam MEM_SIZE = DATA_WIDTH_A * 256;
	localparam offset_bits = $clog2(DATA_WIDTH_A / DATA_WIDTH_B);

    wire [15:0] offset;
    wire [15:0] offset1;
    wire [DATA_WIDTH_A/8-1:0] web_local;
    wire [ADDR_WIDTH_A-1:0] addrb_local;
    wire [DATA_WIDTH_A-1:0] dinb_local;
   	wire [DATA_WIDTH_A-1:0] doutb_local; 
	wire enb_local;
	
	reg [DATA_WIDTH_B-1:0] dinb_local_arr [DATA_WIDTH_A / DATA_WIDTH_B];
	reg [DATA_WIDTH_B-1:0] doutb_local_arr [DATA_WIDTH_A / DATA_WIDTH_B];

	generate
		genvar i;
		for(i = 0; i < DATA_WIDTH_A / DATA_WIDTH_B; i++) begin
			assign dinb_local[i*DATA_WIDTH_B +: DATA_WIDTH_B] = dinb_local_arr[i];
			assign doutb_local_arr[i] = doutb_local[i*DATA_WIDTH_B +: DATA_WIDTH_B];
			assign dinb_local_arr[i] = (offset == i) ? dinb : 0;
		end
	endgenerate
	assign enb_local = enb;

	assign doutb = doutb_local_arr[offset];
   	assign offset = (addrb % (DATA_WIDTH_A / 8)) / (DATA_WIDTH_B / 8);
	assign offset1 = (addrb % (DATA_WIDTH_A / 8)) / (DATA_WIDTH_B / 8) * (DATA_WIDTH_B / 8);
   	assign web_local = web << offset1;
   	assign addrb_local = addrb;

	reg [DATA_WIDTH_B-1:0] mux [2*DATA_WIDTH_A/DATA_WIDTH_B+1];
	reg [2*DATA_WIDTH_A/DATA_WIDTH_B:0] ready;

    reg en;
    reg [DATA_WIDTH_A/8-1:0] we;
    reg [ADDR_WIDTH_A-1:0] addr;
    reg [DATA_WIDTH_A-1:0] din;
    reg [DATA_WIDTH_A-1:0] dout;

    assign doutb_local = dout;
    assign douta = dout;

    always_comb begin
        if(ena) begin
            en = 1;
            we = wea;
            addr = addra;
            din = dina;
        end else if(enb) begin
            en = 1;
            we = web;
            addr = addrb;
            din = dinb;
        end else begin
            en = 0;
        end
    end
	
	single_port_bram #(
    	.BRAM_ADDR_WIDTH(ADDR_WIDTH_A),
    	.BRAM_DATA_WIDTH(DATA_WIDTH_A),
    	.MEM_PATH(MEM_PATH)
    ) mem (
    	.clk(clka),
    	.en(en),
    	.we(we),
    	.addr(addr),
    	.din(din),
    	.dout(dout)
    );
endmodule