
/**
 * top level for SoC with microblaze softcore CPU and neuromorphic core
 * interfaces with microblaze_snn_wrapper block design through BRAM
 */

module microblaze_top #(

)(
	//input wire reset,
	input wire clk,
	//input wire reset,
	input wire usb_uart_rxd,
	output wire usb_uart_txd
	//output wire [15:0] led
);
	localparam BRAM_ADDR_WIDTH = 32;
	localparam BRAM_DATA_WIDTH = 128;
	localparam MAX_NEURONS = 1024;
	localparam NEURONS_PER_CORE = 16;
	localparam WIDTH = 8;
	localparam MAX_TILES = 32;
    localparam integer BYTES_PER_WIDTH = BRAM_DATA_WIDTH / WIDTH;
    localparam integer THRESH = 127;

	wire rst;
	//assign rst = ~reset;
	//assign rst = reset;
	assign rst = 1;

	/*wire [BRAM_ADDR_WIDTH-1:0] addra;
	wire clka;
	wire [BRAM_DATA_WIDTH-1:0] dina;
	wire [BRAM_DATA_WIDTH-1:0] douta;
	wire ena;
	wire rsta;
	//wire [3:0] wea;
	wire wea;
	wire rsta_busy;*/

	wire [BRAM_ADDR_WIDTH-1:0] addrb;
	wire clkb;
	wire [BRAM_DATA_WIDTH-1:0] dinb;
	wire [BRAM_DATA_WIDTH-1:0] doutb;
	wire enb;
	//wire rstb;
	//wire [3:0] web;
	wire [BYTES_PER_WIDTH-1:0] web;
	//wire rstb_busy;

	wire network_enable;
	assign network_enable = 1;

	//wire reset;
	//assign reset = 0;

	microblaze_snn_wrapper microblaze (
		.BRAM_PORTB_0_addr(addrb), 
		.BRAM_PORTB_0_clk(clkb),
		.BRAM_PORTB_0_din(dinb),
		.BRAM_PORTB_0_dout(doutb),
		.BRAM_PORTB_0_en(enb),
		//.BRAM_PORTB_0_rst(rstb),
		.BRAM_PORTB_0_we(web),
		.reset(rst),
		.sys_clock(clk),
		.usb_uart_rxd(usb_uart_rxd),
		.usb_uart_txd(usb_uart_txd)
	);

	network_wrapper #(
		.MAX_NEURONS(MAX_NEURONS),
		.WIDTH(WIDTH),
		.MAX_DELAY(8),
		.NEURONS_PER_CORE(NEURONS_PER_CORE),
		.BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
		.BRAM_DATA_WIDTH(BRAM_DATA_WIDTH),
		.BYTES_PER_WIDTH(BYTES_PER_WIDTH),
		.MAX_TILES(MAX_TILES),
		.THRESH(THRESH)
	) network (
		.clk(clk),
		.enable(network_enable),
		//.led_out(led),

		.bram_clk(clkb),
		.bram_addr(addrb),
		.bram_dout(doutb),
		.bram_din(dinb),
		.bram_en(enb),
		.bram_rst(rstb),
		.bram_we(web)
	);

endmodule
