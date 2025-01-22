`include "bram/bram_streamer.sv"
`include "bram/asymmetric_dual_port_bram.sv"

module bram_streamer_tb;

    reg clk;
    reg en;

    wire [2047:0] weight_dout;
    wire [127:0] network_input_dout;
    wire [127:0] mem_in_dout;
    wire [15:0] spk_in_dout;
    wire [31:0] tile_idx_dout;

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
        .ena(tile_idx_en)
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
        .ena(spk_in_en)
    );

    //wire [WEIGHT_BRAM_DATA_WIDTH-1:0] doutb2;
    asymmetric_dual_port_bram #(
        .DATA_WIDTH_A(2048),
        .ADDR_WIDTH_A(16),
        .DATA_WIDTH_B(2048),
        .ADDR_WIDTH_B(16),
        .MEM_PATH("weight_bram.mem")
    ) bram_weight (
        .clka(clk),
        .addra(weight_addr),
        .dina(0),
        .douta(weight_dout),
        .wea(0),
        .ena(weight_en)
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
        .ena(mem_in_en)
    );

    bram_streamer bram_streamer_0 (
        .clk(clk),
        .enable(en),
        .weight_dout(weight_dout),
        .network_input_dout(network_input_dout),
        .mem_in_dout(mem_in_dout),
        .spk_in_dout(spk_in_dout),
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
        .tile_idx_addr(tile_idx_addr)
    );

    initial begin
        #0 en = 0;
        #50 en = 1;
        #300 $finish;
    end

    initial begin
        $dumpfile(".wave/bram_dump.vcd");
        $dumpvars(100, bram_streamer_tb);
        clk = 0;
        forever #5 clk = ~clk;
    end

endmodule