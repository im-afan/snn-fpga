`timescale 1ns / 10ps
`include "bram/buff_idx_controller.sv"
`include "bram/asymmetric_dual_port_bram.sv"
`include "bram/asymmetric_dpbram_switched.sv"
`include "bram/bram_streamer.sv"
`include "bram/bram_writer.sv"
`include "snn/snn.sv"
`include "led_controller.sv"

module top(
    clk,
    //sw,
    snn_en,
    snn_done,
    led,
    cpu_tile_idx_addr, cpu_tile_idx_din, cpu_tile_idx_dout, cpu_tile_idx_en, cpu_tile_idx_we,
    cpu_weight_addr, cpu_weight_din, cpu_weight_dout, cpu_weight_en, cpu_weight_we,
    cpu_spk_out_addr, cpu_spk_out_din, cpu_spk_out_dout, cpu_spk_out_en, cpu_spk_out_we,
    cpu_spk_in_addr, cpu_spk_in_din, cpu_spk_in_dout, cpu_spk_in_en, cpu_spk_in_we,
    cpu_input_addr, cpu_input_din, cpu_input_dout, cpu_input_en, cpu_input_we
);
    //reg clk;
    localparam BRAM_DATA_WIDTH = 2048;
    localparam BRAM_ADDR_WIDTH = 17;
    localparam NETWORK_WIDTH = 8;
    localparam MAX_TILES = 512;
    localparam TILE_IDX_WIDTH = 16;
    localparam MAX_NEURONS = 1024;
    localparam CROSSBAR_NEURONS = 16;
    localparam THRESH = 64;
    localparam FIFO_LENGTH = 1;

    localparam CPU_BRAM_DATA_WIDTH = 32;
    localparam CPU_BRAM_DATA_WIDTH_WEIGHT = 32;

    input wire clk;
    //input wire [15:0] sw;
    input wire snn_en;
    output wire snn_done;
    output wire [15:0] led;

    input wire [BRAM_ADDR_WIDTH-1:0] cpu_tile_idx_addr;
    input wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_tile_idx_din;
    output wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_tile_idx_dout;
    input wire [CPU_BRAM_DATA_WIDTH/8-1:0] cpu_tile_idx_we;
    input wire cpu_tile_idx_en;

    input wire [BRAM_ADDR_WIDTH-1:0] cpu_weight_addr;
    input wire [CPU_BRAM_DATA_WIDTH_WEIGHT-1:0] cpu_weight_din;
    output wire [CPU_BRAM_DATA_WIDTH_WEIGHT-1:0] cpu_weight_dout;
    input wire [CPU_BRAM_DATA_WIDTH_WEIGHT/8-1:0] cpu_weight_we;
    input wire cpu_weight_en;

    input wire [BRAM_ADDR_WIDTH-1:0] cpu_spk_out_addr;
    input wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_spk_out_din;
    output wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_spk_out_dout;
    input wire [CPU_BRAM_DATA_WIDTH/8-1:0] cpu_spk_out_we;
    input wire cpu_spk_out_en;

    input wire [BRAM_ADDR_WIDTH-1:0] cpu_spk_in_addr;
    input wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_spk_in_din;
    output wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_spk_in_dout;
    input wire [CPU_BRAM_DATA_WIDTH/8-1:0] cpu_spk_in_we;
    input wire cpu_spk_in_en;

    input wire [BRAM_ADDR_WIDTH-1:0] cpu_input_addr;
    input wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_input_din;
    output wire [CPU_BRAM_DATA_WIDTH-1:0] cpu_input_dout;
    input wire [CPU_BRAM_DATA_WIDTH/8-1:0] cpu_input_we;
    input wire cpu_input_en;
    
    reg en;
    wire push_rst;
	wire push;

    assign en = snn_en;

    wire snn_busy;
    wire stream_done;
    
    assign snn_done = (stream_done);


    wire [2047:0] weight;
    wire [127:0] network_input;
    wire [127:0] mem_in;
    wire [15:0] spk_in;

    wire [2047:0] weight_dout;
    wire [127:0] network_input_dout;
    wire [127:0] mem_in_dout;
    wire [15:0] spk_in_dout;
    wire [63:0] tile_idx_dout;
    wire [15:0] spk_in_ext_dout;
    
    wire [15:0] tile_idx_y;
    wire [15:0] tile_idx_y_ext;
    wire [15:0] tile_idx_y_bram;
    wire [15:0] tile_idx_y_ext_bram;

    wire weight_en;
    wire [16:0] weight_addr;
    wire network_input_en;
    wire [16:0] network_input_addr;
    wire mem_in_en;
    wire [16:0] mem_in_addr;
    wire spk_in_en;
    wire [16:0] spk_in_addr;
    wire tile_idx_en;
    wire [16:0] tile_idx_addr;
    wire spk_in_ext_en;
    wire [16:0] spk_in_ext_addr;

    wire mem_out_en;
    wire [16:0] mem_out_addr;
    wire [127:0] mem_out_din;
    wire spk_out_en;
    wire [16:0] spk_out_addr;
    wire [15:0] spk_out_din;
    wire [16:0] timed_spk_out_addr;

    wire [15:0] timestep;

    wire buff_idx;

    /*buff_idx_controller buff_idx_controller_0 (
        .clk(clk),
        .en(en),
        .buff_idx(buff_idx)
    );*/
    assign buff_idx = timestep & 1;

    asymmetric_dpbram_switched #(
        .DATA_WIDTH_A(64),
        .ADDR_WIDTH_A(17),
        .DATA_WIDTH_B(CPU_BRAM_DATA_WIDTH),
        .ADDR_WIDTH_B(17),
        .DEPTH(MAX_TILES),
        .MEM_PATH("tile_idx_bram.mem")
    ) bram_tile_idx (
        .ena(en),
        .clka(clk),
        .addra(tile_idx_addr),
        .douta(tile_idx_dout),
        .dina(0),
        .wea(0),

        .enb(cpu_tile_idx_en),
        .clkb(clk),
        .addrb(cpu_tile_idx_addr),
        .doutb(cpu_tile_idx_dout),
        .dinb(cpu_tile_idx_din),
        .web(cpu_tile_idx_we)
    );

    /*asymmetric_dual_port_bram #(
        .DATA_WIDTH_A(CPU_BRAM_DATA_WIDTH),
        .ADDR_WIDTH_A(17),
        .DATA_WIDTH_B(16),
        .ADDR_WIDTH_B(17),
        .MEM_PATH("spk_in_bram.mem"),
        .DEPTH(0)
    ) bram_spk_in_ext (
        .clka(clk),
        .addra(cpu_spk_in_addr),
        .dina(cpu_spk_in_din),
        .douta(cpu_spk_in_dout),
        .wea(cpu_spk_in_we),
        .ena(en),

        .clkb(clk),
        .addrb(spk_in_ext_addr),
        .dinb(),
        .doutb(spk_in_ext_dout),
        .web(0),
        .enb(en)
    );*/

    asymmetric_dual_port_bram #(
        .DATA_WIDTH_A(16),
        .ADDR_WIDTH_A(17),
        .DATA_WIDTH_B(16),
        .ADDR_WIDTH_B(17),
        .MEM_PATH("spk_in_bram.mem"),
        .DEPTH(1024)
    ) bram_spk_in (
        .clka(clk),
        .addra(spk_in_addr),
        .dina(0),
        .douta(spk_in_dout),
        .wea(0),
        .ena(en),

        .clkb(clk),
        .addrb(spk_out_addr),
        .dinb(spk_out_din),
        .doutb(),
        .web(2'b11),
        .enb(spk_out_en)
    );


    wire [15:0] spk_out_addr_mod;
    assign spk_out_addr_mod = spk_out_addr % (2*256);
    
    asymmetric_dual_port_bram #(
        .DATA_WIDTH_B(16),
        .ADDR_WIDTH_B(17),
        .DATA_WIDTH_A(CPU_BRAM_DATA_WIDTH),
        .ADDR_WIDTH_A(17),
        .MEM_PATH("spk_in_bram.mem"),
        .DEPTH(512)
    ) bram_spk_out (
        .clkb(clk),
        .addrb(timed_spk_out_addr),
        .dinb(spk_out_din),
        .doutb(),
        .web(2'b11),
        .enb(spk_out_en),

        .clka(clk),
        .addra(cpu_spk_out_addr),
        .dina(cpu_spk_out_din),
        .douta(cpu_spk_out_dout),
        .wea(cpu_spk_out_we),
        .ena(cpu_spk_out_en)
    );
    //initial $monitor("%b", bram_spk_out.mem.mem[0]);

    //wire [WEIGHT_BRAM_DATA_WIDTH-1:0] doutb2;
    asymmetric_dpbram_switched #(
        .DATA_WIDTH_A(2048),
        .ADDR_WIDTH_A(17),
        .DATA_WIDTH_B(CPU_BRAM_DATA_WIDTH_WEIGHT),
        .ADDR_WIDTH_B(17),
        .DEPTH(512),
        .MEM_PATH("weight_bram.mem")
    ) bram_weight (
        .clka(clk),
        .addra(weight_addr),
        .dina(0),
        .douta(weight_dout),
        .wea(0),
        .ena(en),

        .clkb(clk),
        .addrb(cpu_weight_addr),
        .doutb(),
        .dinb(cpu_weight_din),
        .web(cpu_weight_we),
        .enb(cpu_weight_en)
    );

    //wire [INPUT_BRAM_DATA_WIDTH-1:0] doutb3;
    asymmetric_dpbram_switched #(
        .DATA_WIDTH_A(128),
        .ADDR_WIDTH_A(17),
        .DATA_WIDTH_B(CPU_BRAM_DATA_WIDTH),
        .ADDR_WIDTH_B(17),
        .DEPTH(512),
        .MEM_PATH("input_bram.mem")
    ) bram_input (
        .clka(clk),
        .addra(network_input_addr),
        .dina(0),
        .douta(network_input_dout),
        .wea(0),
        .ena(network_input_en),

        .clkb(clk),
        .addrb(cpu_input_addr),
        .doutb(),
        .dinb(cpu_input_din),
        .web(cpu_input_we),
        .enb(cpu_input_en)
    );

    //wire [INPUT_BRAM_DATA_WIDTH-1:0] doutb4;
    asymmetric_dual_port_bram #(
        .DATA_WIDTH_A(128),
        .ADDR_WIDTH_A(17),
        .DATA_WIDTH_B(128),
        .ADDR_WIDTH_B(17),
        .MEM_PATH("mem_bram.mem")
    ) bram_mem_in (
        .clka(clk),
        .addra(mem_in_addr),
        .dina(0),
        .douta(mem_in_dout),
        .wea(0),
        .ena(mem_in_en),

        .clkb(clk),
        .addrb(mem_out_addr),
        .dinb(mem_out_din),
        .doutb(),
        .web(16'b1111111111111111),
        .enb(mem_out_en)
    );


    bram_streamer bram_streamer_0 (
        .clk(clk),
        .enable(en),
        .done(stream_done),
        .buff_idx(buff_idx),
		.fifo_pop(lif_has_out),
        .timestep(timestep),

        .weight(weight),
        .network_input(network_input),
        .mem_in(mem_in),
        .spk_in(spk_in),
        .tile_idx_y(tile_idx_y),
        .tile_idx_y_ext(tile_idx_y_ext),

        .weight_dout(weight_dout),
        .network_input_dout(network_input_dout),
        .mem_in_dout(mem_in_dout),
        .spk_in_dout(spk_in_dout),
        .spk_in_ext_dout(spk_in_ext_dout),
        .tile_idx_dout(tile_idx_dout),

		
        .weight_en(weight_en),
        .weight_addr(weight_addr),
        .network_input_en(network_input_en),
        .network_input_addr(network_input_addr),
        .mem_in_en(mem_in_en),
        .mem_in_addr(mem_in_addr),
        .spk_in_en(spk_in_en),
        .spk_in_addr(spk_in_addr),
        .tile_idx_en(tile_idx_en),
        .tile_idx_addr(tile_idx_addr),
        .spk_in_ext_en(spk_in_ext_en),
        .spk_in_ext_addr(spk_in_ext_addr),

        .push_rst(push_rst),
		.push(push)
    );

    snn snn_0 (
        .clk(clk),
        .en(en),
		.push(push),
        .push_rst(push_rst),
        .i_weight(weight),
        .i_network_input(network_input),
        .i_mem_in(mem_in),
        .i_spk_in(spk_in),
        .i_tile_idx_y(tile_idx_y),
        .i_tile_idx_y_ext(tile_idx_y_ext),
        .o_spk_out(spk_out_din),
        .o_mem_out(mem_out_din),
        .o_tile_idx_y(tile_idx_y_bram),
        .o_tile_idx_y_ext(tile_idx_y_ext_bram),
        .lif_has_out(lif_has_out),
        .busy(snn_busy)
    );

    bram_writer bram_writer_0 (
        .clk(clk),
        .en(en),
        .timestep(timestep),
        .buff_idx(buff_idx),
        .has_out(lif_has_out),
        .tile_idx_y(tile_idx_y_bram),
        .tile_idx_y_ext(tile_idx_y_ext_bram),
        .mem_out_en(mem_out_en),
        .spk_out_en(spk_out_en),
        .mem_out_addr(mem_out_addr),
        .spk_out_addr(spk_out_addr),
        .timed_spk_out_addr(timed_spk_out_addr)
    );

    led_controller led_controller_0 (
        .clk(clk),
        .en(en),
        .spk_out(spk_out_din),
        .led(led)
    );


    always @(posedge clk) begin
        //if(spk_out_en && spk_out_addr_mod <= 128) begin
        if(spk_out_en) begin
            $display("%b", spk_out_din);
        end
    end
endmodule
