`timescale 1ns / 10ps
`include "bram/asymmetric_dual_port_bram.sv"
`include "bram/bram_streamer.sv"
`include "bram/bram_writer.sv"
`include "snn/snn.sv"
`include "led_controller.sv"

module top(
    /*input wire clk,
    input wire [15:0] sw,
    input wire [15:0] led */
);
    reg clk;
    
    reg en;
    wire push_rst;
	wire push;

    wire [15:0] led;

    wire [2047:0] weight_dout;
    wire [127:0] network_input_dout;
    wire [127:0] mem_in_dout;
    wire [15:0] spk_in_dout;
    wire [31:0] tile_idx_dout;
    
    wire [15:0] tile_idx_y;

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

    wire mem_out_en;
    wire [16:0] mem_out_addr;
    wire [127:0] mem_out_din;
    wire spk_out_en;
    wire [16:0] spk_out_addr;
    wire [15:0] spk_out_din;

    asymmetric_dual_port_bram #(
        .DATA_WIDTH_B(32),
        .ADDR_WIDTH_B(16),
        .DATA_WIDTH_A(32),
        .ADDR_WIDTH_A(16),
        .MEM_PATH("tile_idx_bram.mem")
    ) bram_tile_idx (
        .clka(clk),
        .addra(tile_idx_addr),
        .douta(tile_idx_dout),
        .dina(0),
        .wea(0),
        .ena(en)
    );
    
    asymmetric_dual_port_bram #(
        .DATA_WIDTH_A(16),
        .ADDR_WIDTH_A(16),
        .DATA_WIDTH_B(16),
        .ADDR_WIDTH_B(16),
        .MEM_PATH("spk_in_bram.mem")
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
        .enb(mem_out_en)
    );

    //wire [WEIGHT_BRAM_DATA_WIDTH-1:0] doutb2;
    asymmetric_dual_port_bram #(
        .DATA_WIDTH_A(2048),
        .ADDR_WIDTH_A(17),
        .DATA_WIDTH_B(2048),
        .ADDR_WIDTH_B(17),
        .MEM_PATH("weight_bram.mem")
    ) bram_weight (
        .clka(clk),
        .addra(weight_addr),
        .dina(0),
        .douta(weight_dout),
        .wea(0),
        .ena(en)
    );

    //wire [INPUT_BRAM_DATA_WIDTH-1:0] doutb3;
    asymmetric_dual_port_bram #(
        .DATA_WIDTH_A(128),
        .ADDR_WIDTH_A(16),
        .DATA_WIDTH_B(128),
        .ADDR_WIDTH_B(16),
        .MEM_PATH("input_bram.mem")
    ) bram_input (
        .clka(clk),
        .addra(network_input_addr),
        .dina(0),
        .douta(network_input_dout),
        .wea(0),
        .ena(network_input_en)
    );

    //wire [INPUT_BRAM_DATA_WIDTH-1:0] doutb4;
    asymmetric_dual_port_bram #(
        .DATA_WIDTH_A(128),
        .ADDR_WIDTH_A(16),
        .DATA_WIDTH_B(128),
        .ADDR_WIDTH_B(16),
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
		.fifo_pop(lif_has_out),

        .weight_dout(weight_dout),
        .network_input_dout(network_input_dout),
        .mem_in_dout(mem_in_dout),
        .spk_in_dout(spk_in_dout),
        .tile_idx_dout(tile_idx_dout),

        .tile_idx_y(tile_idx_y),
		
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

        .push_rst(push_rst),
		.push(push)
    );

    snn snn_0 (
        .clk(clk),
        .en(en),
		.push(push),
        .push_rst(push_rst),
        .i_weight(weight_dout),
        .i_network_input(network_input_dout),
        .i_mem_in(mem_in_dout),
        .i_spk_in(spk_in_dout),
        .o_spk_out(spk_out_din),
        .o_mem_out(mem_out_din),
        .lif_has_out(lif_has_out)
    );

    bram_writer bram_writer_0 (
        .clk(clk),
        .en(en),
        .has_out(lif_has_out),
        .tile_idx_y(tile_idx_y),
        .mem_out_en(mem_out_en),
        .spk_out_en(spk_out_en),
        .mem_out_addr(mem_out_addr),
        .spk_out_addr(spk_out_addr)
    );

    led_controller led_controller_0 (
        .clk(clk),
        .en(en),
        .spk_out(spk_out_din),
        .led(led)
    );

    initial begin
        #0 en = 0;
        #100000
        $writememb(".wave/spk_out_dump.mem", bram_spk_in.mem.mem);
        $writememb(".wave/mem_out_dump.mem", bram_mem_in.mem.mem);
        $finish;
    end

    initial begin
        forever begin
            #100 en = 1;
            #10000 en = 0;
        end
    end

    initial begin
        $dumpfile(".wave/top_dump.vcd");
        $dumpvars(100, top);
        clk = 0;
        forever #5 clk = ~clk;
    end


endmodule
